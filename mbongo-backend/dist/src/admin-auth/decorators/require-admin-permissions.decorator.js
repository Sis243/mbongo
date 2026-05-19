"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RequireAdminPermissions = exports.ADMIN_PERMISSIONS_KEY = void 0;
const common_1 = require("@nestjs/common");
exports.ADMIN_PERMISSIONS_KEY = 'adminPermissions';
const RequireAdminPermissions = (...permissions) => (0, common_1.SetMetadata)(exports.ADMIN_PERMISSIONS_KEY, permissions);
exports.RequireAdminPermissions = RequireAdminPermissions;
//# sourceMappingURL=require-admin-permissions.decorator.js.map