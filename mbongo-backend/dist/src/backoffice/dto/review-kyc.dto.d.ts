import { z } from 'zod';
export declare const reviewKycSchema: z.ZodDiscriminatedUnion<[z.ZodObject<{
    status: z.ZodLiteral<"APPROVED">;
}, z.core.$strict>, z.ZodObject<{
    status: z.ZodLiteral<"REJECTED">;
    rejectionReason: z.ZodString;
}, z.core.$strict>], "status">;
export type ReviewKycDto = z.infer<typeof reviewKycSchema>;
