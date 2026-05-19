import type { JwtRequestUser } from '../auth/auth.types';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { KycService } from './kyc.service';
import type { KycUploadedFile } from './kyc-file.types';
import type { Response } from 'express';
export declare class KycController {
    private readonly kycService;
    constructor(kycService: KycService);
    getMine(user: JwtRequestUser): import("@prisma/client").Prisma.Prisma__KycSubmissionClient<({
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
    submitMine(user: JwtRequestUser, body: SubmitKycDto): Promise<{
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
    submitMineUpload(user: JwtRequestUser, documentType: string, files: {
        front?: KycUploadedFile[];
        back?: KycUploadedFile[];
        selfie?: KycUploadedFile[];
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
    getKycFile(fileName: string, response: Response): Response<any, Record<string, any>>;
    private contentTypeFor;
}
