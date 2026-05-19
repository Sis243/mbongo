import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
@Catch()
export class GlobalHttpExceptionFilter implements ExceptionFilter {
  constructor(private readonly prisma: PrismaService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? (exception.getResponse() as { message?: string } | string)
        : 'Erreur interne du serveur';

    const errorMessage =
      typeof message === 'string'
        ? message
        : (message as { message?: string }).message ?? 'Erreur';

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
        .catch(() => {});
    }

    response.status(status).json({
      statusCode: status,
      message: errorMessage,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
