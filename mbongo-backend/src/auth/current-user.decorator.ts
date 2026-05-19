import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtRequestUser } from './auth.types';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtRequestUser => {
    const request = ctx.switchToHttp().getRequest<{ user: JwtRequestUser }>();
    return request.user;
  },
);
