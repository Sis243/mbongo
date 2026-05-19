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
exports.AdminPermissionGuard = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const require_admin_permissions_decorator_1 = require("../decorators/require-admin-permissions.decorator");
let AdminPermissionGuard = class AdminPermissionGuard {
    reflector;
    constructor(reflector) {
        this.reflector = reflector;
    }
    canActivate(context) {
        const requiredPermissions = this.reflector.getAllAndOverride(require_admin_permissions_decorator_1.ADMIN_PERMISSIONS_KEY, [
            context.getHandler(),
            context.getClass(),
        ]) ?? [];
        if (requiredPermissions.length === 0) {
            return true;
        }
        const request = context.switchToHttp().getRequest();
        const adminPermissions = request.admin?.permissions ?? [];
        const allowed = requiredPermissions.every((permission) => adminPermissions.includes(permission));
        if (!allowed) {
            throw new common_1.ForbiddenException('Permission admin insuffisante');
        }
        return true;
    }
};
exports.AdminPermissionGuard = AdminPermissionGuard;
exports.AdminPermissionGuard = AdminPermissionGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [core_1.Reflector])
], AdminPermissionGuard);
//# sourceMappingURL=admin-permission.guard.js.map