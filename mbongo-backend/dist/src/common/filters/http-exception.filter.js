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
exports.GlobalHttpExceptionFilter = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let GlobalHttpExceptionFilter = class GlobalHttpExceptionFilter {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    catch(exception, host) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
        const status = exception instanceof common_1.HttpException
            ? exception.getStatus()
            : common_1.HttpStatus.INTERNAL_SERVER_ERROR;
        const message = exception instanceof common_1.HttpException
            ? exception.getResponse()
            : 'Erreur interne du serveur';
        const errorMessage = typeof message === 'string'
            ? message
            : message.message ?? 'Erreur';
        const stack = exception instanceof Error ? exception.stack : undefined;
        if (status >= 500) {
            this.prisma.errorLog
                .create({
                data: {
                    level: 'error',
                    message: errorMessage,
                    stack: stack ?? null,
                    path: request.path,
                    method: request.method,
                    context: 'HttpExceptionFilter',
                },
            })
                .catch(() => { });
        }
        response.status(status).json({
            statusCode: status,
            message: errorMessage,
            path: request.url,
            timestamp: new Date().toISOString(),
        });
    }
};
exports.GlobalHttpExceptionFilter = GlobalHttpExceptionFilter;
exports.GlobalHttpExceptionFilter = GlobalHttpExceptionFilter = __decorate([
    (0, common_1.Injectable)(),
    (0, common_1.Catch)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], GlobalHttpExceptionFilter);
//# sourceMappingURL=http-exception.filter.js.map