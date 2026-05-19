"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateEnvironment = validateEnvironment;
const runtime_config_1 = require("./runtime-config");
const productionRequiredVariables = [
    'DATABASE_URL',
    'JWT_ACCESS_SECRET',
    'JWT_REFRESH_SECRET',
    'PUBLIC_API_URL',
    'KYC_UPLOAD_DIR',
];
function validateEnvironment(config) {
    const nodeEnv = String(config.NODE_ENV ?? process.env.NODE_ENV ?? 'development');
    if ((0, runtime_config_1.isProductionLike)(nodeEnv)) {
        const missing = productionRequiredVariables.filter((name) => !String(config[name] ?? '').trim());
        if (missing.length > 0) {
            throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
        }
    }
    return config;
}
//# sourceMappingURL=validate-env.js.map