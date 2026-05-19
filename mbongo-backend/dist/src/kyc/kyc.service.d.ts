import { PrismaService } from '../prisma/prisma.service';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import type { KycUploadedFile } from './kyc-file.types';
export declare class KycService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    private readonly maxFileSize;
    private readonly allowedMimeTypes;
    getLatestForUser(userId: string): import("@prisma/client").Prisma.Prisma__KycSubmissionClient<({
        documents: {
            id: string;
            createdAt: Date;
            submissionId: string;
            side: import("@prisma/client").$Enums.KycDocumentSide;
            fileUrl: string;
            fileMimeType: string | null;
            providerRef: string | null;
            verificationData: string | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.KycStatus;
        rejectionReason: string | null;
        documentType: string | null;
        submittedAt: Date | null;
        reviewedAt: Date | null;
        reviewedBy: string | null;
    }) | null, null, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    submit(userId: string, body: SubmitKycDto): Promise<{
        documents: {
            id: string;
            createdAt: Date;
            submissionId: string;
            side: import("@prisma/client").$Enums.KycDocumentSide;
            fileUrl: string;
            fileMimeType: string | null;
            providerRef: string | null;
            verificationData: string | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.KycStatus;
        rejectionReason: string | null;
        documentType: string | null;
        submittedAt: Date | null;
        reviewedAt: Date | null;
        reviewedBy: string | null;
    }>;
    submitUpload(userId: string, documentType: string, files: {
        front?: KycUploadedFile;
        back?: KycUploadedFile;
        selfie?: KycUploadedFile;
    }): Promise<{
        documents: {
            id: string;
            createdAt: Date;
            submissionId: string;
            side: import("@prisma/client").$Enums.KycDocumentSide;
            fileUrl: string;
            fileMimeType: string | null;
            providerRef: string | null;
            verificationData: string | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.KycStatus;
        rejectionReason: string | null;
        documentType: string | null;
        submittedAt: Date | null;
        reviewedAt: Date | null;
        reviewedBy: string | null;
    }>;
    private documentInput;
    private assertCanSubmit;
    private persistUploadedDocument;
    private extensionFor;
    private publicApiBaseUrl;
}
