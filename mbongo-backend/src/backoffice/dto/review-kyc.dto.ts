import { z } from 'zod';

export const reviewKycSchema = z.discriminatedUnion('status', [
  z
    .object({
      status: z.literal('APPROVED'),
      userType: z.enum(['CLIENT', 'AGENT', 'MERCHANT']).optional().default('CLIENT'),
    })
    .strict(),
  z
    .object({
      status: z.literal('REJECTED'),
      rejectionReason: z.string().trim().min(1).max(500),
    })
    .strict(),
]);

export type ReviewKycDto = z.infer<typeof reviewKycSchema>;


