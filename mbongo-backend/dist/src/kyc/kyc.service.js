"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KycService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const crypto_1 = require("crypto");
const path_1 = require("path");
const promises_1 = require("fs/promises");
const prisma_service_1 = require("../prisma/prisma.service");
let KycService = class KycService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    maxFileSize = 5 * 1024 * 1024;
    allowedMimeTypes = new Set([
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
    ]);
    getLatestForUser(userId) {
        return this.prisma.kycSubmission.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            include: { documents: true },
        });
    }
    async submit(userId, body) {
        await this.assertCanSubmit(userId);
        const documents = [
            this.documentInput(client_1.KycDocumentSide.FRONT, body.frontUrl),
            this.documentInput(client_1.KycDocumentSide.BACK, body.backUrl),
            this.documentInput(client_1.KycDocumentSide.SELFIE, body.selfieUrl),
        ].filter((item) => item !== null);
        if (documents.length === 0) {
            throw new common_1.BadRequestException('Au moins un document KYC est obligatoire');
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
    async submitUpload(userId, documentType, files) {
        await this.assertCanSubmit(userId);
        const cleanDocumentType = documentType?.trim();
        if (!cleanDocumentType) {
            throw new common_1.BadRequestException('Type de document obligatoire');
        }
        const documents = await Promise.all([
            this.persistUploadedDocument(userId, client_1.KycDocumentSide.FRONT, files.front),
            this.persistUploadedDocument(userId, client_1.KycDocumentSide.BACK, files.back),
            this.persistUploadedDocument(userId, client_1.KycDocumentSide.SELFIE, files.selfie),
        ]);
        const validDocuments = documents.filter((item) => item !== null);
        if (validDocuments.length === 0) {
            throw new common_1.BadRequestException('Au moins un fichier KYC est obligatoire');
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
    documentInput(side, fileUrl) {
        const cleanUrl = fileUrl?.trim();
        if (!cleanUrl) {
            return null;
        }
        return {
            side,
            fileUrl: cleanUrl,
        };
    }
    async assertCanSubmit(userId) {
        const latestSubmission = await this.prisma.kycSubmission.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            select: {
                status: true,
            },
        });
        if (latestSubmission?.status === 'SUBMITTED') {
            throw new common_1.BadRequestException('Un dossier KYC est deja en attente de revue');
        }
        if (latestSubmission?.status === 'APPROVED') {
            throw new common_1.BadRequestException('Votre verification KYC est deja validee');
        }
    }
    async persistUploadedDocument(userId, side, file) {
        if (!file) {
            return null;
        }
        if (file.size > this.maxFileSize) {
            throw new common_1.BadRequestException('Fichier KYC trop volumineux');
        }
        if (!this.allowedMimeTypes.has(file.mimetype)) {
            throw new common_1.BadRequestException('Type de fichier KYC non autorise');
        }
        const uploadRoot = process.env.KYC_UPLOAD_DIR || (0, path_1.join)(process.cwd(), 'uploads', 'kyc');
        await (0, promises_1.mkdir)(uploadRoot, { recursive: true });
        const extension = this.extensionFor(file);
        const fileName = `${userId}-${side.toLowerCase()}-${(0, crypto_1.randomUUID)()}${extension}`;
        const filePath = (0, path_1.join)(uploadRoot, fileName);
        await (0, promises_1.writeFile)(filePath, file.buffer);
        return {
            side,
            fileUrl: `${this.publicApiBaseUrl()}/kyc/files/${fileName}`,
            fileMimeType: file.mimetype,
        };
    }
    extensionFor(file) {
        const originalExtension = (0, path_1.extname)(file.originalname).toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.webp', '.pdf'].includes(originalExtension)) {
            return originalExtension;
        }
        if (file.mimetype === 'image/jpeg')
            return '.jpg';
        if (file.mimetype === 'image/png')
            return '.png';
        if (file.mimetype === 'image/webp')
            return '.webp';
        return '.pdf';
    }
    publicApiBaseUrl() {
        return (process.env.PUBLIC_API_URL ||
            process.env.API_URL ||
            `http://localhost:${process.env.PORT ?? 3000}`).replace(/\/$/, '');
    }
};
exports.KycService = KycService;
exports.KycService = KycService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], KycService);
//# sourceMappingURL=kyc.service.js.map