import { ArgumentsHost, ExceptionFilter } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
export declare class GlobalHttpExceptionFilter implements ExceptionFilter {
    private readonly prisma;
    constructor(prisma: PrismaService);
    catch(exception: unknown, host: ArgumentsHost): void;
}
