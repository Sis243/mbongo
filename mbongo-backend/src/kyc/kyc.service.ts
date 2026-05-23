import { BadRequestException, Injectable } from '@nestjs/common';
import { KycDocumentSide } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import type { KycUploadedFile } from './kyc-file.types';

@Injectable()
export class KycService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly maxFileSize = 5 * 1024 * 1024;
  private readonly allowedMimeTypes = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  ]);

  getLatestForUser(userId: string) {
    return this.prisma.kycSubmission.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { documents: true },
    });
  }

  async submit(userId: string, body: SubmitKycDto) {
    await this.assertCanSubmit(userId);

    const documents = [
      this.documentInput(KycDocumentSide.FRONT, body.frontUrl),
      this.documentInput(KycDocumentSide.BACK, body.backUrl),
      this.documentInput(KycDocumentSide.SELFIE, body.selfieUrl),
    ].filter((item): item is { side: KycDocumentSide; fileUrl: string } => item !== null);

    if (documents.length === 0) {
      throw new BadRequestException('Au moins un document KYC est obligatoire');
    }

    return this.prisma.$transaction(async (tx) => {
      const submission = await tx.kycSubmission.create({
        data: {
          userId,
          status: 'SUBMITTED',
          documentType: body.documentType.trim(),
          submittedAt: new Date(),
          documents: {
            create: documents,
          },
        },
        include: {
          documents: true,
        },
      });

      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'KYC_SUBMITTED',
          entityType: 'KycSubmission',
          entityId: submission.id,
          metadata: JSON.stringify({
            documentType: submission.documentType,
            documentCount: submission.documents.length,
          }),
        },
      });

      return submission;
    });
  }

  async submitUpload(
    userId: string,
    documentType: string,
    files: {
      front?: KycUploadedFile;
      back?: KycUploadedFile;
      selfie?: KycUploadedFile;
    },
  ) {
    await this.assertCanSubmit(userId);

    const cleanDocumentType = documentType?.trim();

    if (!cleanDocumentType) {
      throw new BadRequestException('Type de document obligatoire');
    }

    const documents = await Promise.all([
      this.persistUploadedDocument(userId, KycDocumentSide.FRONT, files.front),
      this.persistUploadedDocument(userId, KycDocumentSide.BACK, files.back),
      this.persistUploadedDocument(userId, KycDocumentSide.SELFIE, files.selfie),
    ]);

    const validDocuments = documents.filter(
      (item): item is { side: KycDocumentSide; fileUrl: string; fileMimeType: string } =>
        item !== null,
    );

    if (validDocuments.length === 0) {
      throw new BadRequestException('Au moins un fichier KYC est obligatoire');
    }

    return this.prisma.$transaction(async (tx) => {
      const submission = await tx.kycSubmission.create({
        data: {
          userId,
          status: 'SUBMITTED',
          documentType: cleanDocumentType,
          submittedAt: new Date(),
          documents: {
            create: validDocuments,
          },
        },
        include: {
          documents: true,
        },
      });

      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'KYC_SUBMITTED_UPLOAD',
          entityType: 'KycSubmission',
          entityId: submission.id,
          metadata: JSON.stringify({
            documentType: submission.documentType,
            documentCount: submission.documents.length,
            storage: 'local',
          }),
        },
      });

      return submission;
    });
  }

  private documentInput(side: KycDocumentSide, fileUrl?: string) {
    const cleanUrl = fileUrl?.trim();
    if (!cleanUrl) {
      return null;
    }

    return {
      side,
      fileUrl: cleanUrl,
    };
  }

  private async assertCanSubmit(userId: string) {
    const latestSubmission = await this.prisma.kycSubmission.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        status: true,
      },
    });

    if (latestSubmission?.status === 'SUBMITTED') {
      throw new BadRequestException('Un dossier KYC est deja en attente de revue');
    }

    if (latestSubmission?.status === 'APPROVED') {
      throw new BadRequestException('Votre verification KYC est deja validee');
    }
  }

  private async persistUploadedDocument(
    _userId: string,
    side: KycDocumentSide,
    file?: KycUploadedFile,
  ) {
    if (!file) {
      return null;
    }

    if (file.size > this.maxFileSize) {
      throw new BadRequestException('Fichier KYC trop volumineux');
    }

    if (!this.allowedMimeTypes.has(file.mimetype)) {
      throw new BadRequestException('Type de fichier KYC non autorise');
    }

    // Stockage en base64 — compatible Vercel serverless (pas de filesystem)
    const base64 = file.buffer.toString('base64');
    const dataUrl = `data:${file.mimetype};base64,${base64}`;

    return {
      side,
      fileUrl: dataUrl,
      fileMimeType: file.mimetype,
    };
  }
}
