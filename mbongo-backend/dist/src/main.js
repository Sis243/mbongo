"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const security_middleware_1 = require("./security/security.middleware");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.use(security_middleware_1.securityHeaders);
    app.use(security_middleware_1.requestLogger);
    app.use(security_middleware_1.authRateLimit);
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    app.enableCors({
        origin: true,
        credentials: true,
    });
    const port = Number(process.env.PORT ?? 3000);
    await app.listen(port);
    console.log(`MBONGO API running on http://localhost:${port}`);
}
bootstrap();
//# sourceMappingURL=main.js.map