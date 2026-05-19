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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KycController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const current_user_decorator_1 = require("../auth/current-user.decorator");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const submit_kyc_dto_1 = require("./dto/submit-kyc.dto");
const kyc_service_1 = require("./kyc.service");
const fs_1 = require("fs");
const path_1 = require("path");
let KycController = class KycController {
    kycService;
    constructor(kycService) {
        this.kycService = kycService;
    }
    getMine(user) {
        return this.kycService.getLatestForUser(user.userId);
    }
    submitMine(user, body) {
        return this.kycService.submit(user.userId, body);
    }
    submitMineUpload(user, documentType, files) {
        return this.kycService.submitUpload(user.userId, documentType, {
            front: files.front?.[0],
            back: files.back?.[0],
            selfie: files.selfie?.[0],
        });
    }
    getKycFile(fileName, response) {
        if (fileName.includes('/') || fileName.includes('\\')) {
            throw new common_1.NotFoundException('Fichier KYC introuvable');
        }
        const uploadRoot = process.env.KYC_UPLOAD_DIR || (0, path_1.join)(process.cwd(), 'uploads', 'kyc');
        const filePath = (0, path_1.normalize)((0, path_1.join)(uploadRoot, fileName));
        if (!filePath.startsWith((0, path_1.normalize)(uploadRoot)) || !(0, fs_1.existsSync)(filePath)) {
            throw new common_1.NotFoundException('Fichier KYC introuvable');
        }
        response.setHeader('Cache-Control', 'private, max-age=300');
        response.setHeader('Content-Type', this.contentTypeFor(fileName));
        return (0, fs_1.createReadStream)(filePath).pipe(response);
    }
    contentTypeFor(fileName) {
        const extension = (0, path_1.extname)(fileName).toLowerCase();
        if (extension === '.png')
            return 'image/png';
        if (extension === '.webp')
            return 'image/webp';
        if (extension === '.pdf')
            return 'application/pdf';
        return 'image/jpeg';
    }
};
exports.KycController = KycController;
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('me'),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], KycController.prototype, "getMine", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('me/submit'),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, submit_kyc_dto_1.SubmitKycDto]),
    __metadata("design:returntype", void 0)
], KycController.prototype, "submitMine", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('me/submit-upload'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileFieldsInterceptor)([
        { name: 'front', maxCount: 1 },
        { name: 'back', maxCount: 1 },
        { name: 'selfie', maxCount: 1 },
    ], {
        limits: {
            fileSize: 5 * 1024 * 1024,
            files: 3,
        },
    })),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)('documentType')),
    __param(2, (0, common_1.UploadedFiles)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], KycController.prototype, "submitMineUpload", null);
__decorate([
    (0, common_1.Get)('files/:fileName'),
    __param(0, (0, common_1.Param)('fileName')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], KycController.prototype, "getKycFile", null);
exports.KycController = KycController = __decorate([
    (0, common_1.Controller)('kyc'),
    __metadata("design:paramtypes", [kyc_service_1.KycService])
], KycController);
//# sourceMappingURL=kyc.controller.js.map