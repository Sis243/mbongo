"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reviewKycSchema = void 0;
const zod_1 = require("zod");
exports.reviewKycSchema = zod_1.z.discriminatedUnion('status', [
    zod_1.z
        .object({
        status: zod_1.z.literal('APPROVED'),
    })
        .strict(),
    zod_1.z
        .object({
        status: zod_1.z.literal('REJECTED'),
        rejectionReason: zod_1.z.string().trim().min(1).max(500),
    })
        .strict(),
]);
//# sourceMappingURL=review-kyc.dto.js.map