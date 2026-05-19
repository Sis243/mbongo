import { Body, Controller, Get, Headers, Ip, Post, UseGuards } from '@nestjs/common';
import { CurrentAdmin } from './decorators/current-admin.decorator';
import { AdminJwtGuard } from './guards/admin-jwt.guard';
import type { AdminJwtPayload } from './admin-auth.types';
import { AdminAuthService } from './admin-auth.service';
import { LoginAdminDto } from './dto/login-admin.dto';

@Controller('admin-auth')
export class AdminAuthController {
  constructor(private adminAuthService: AdminAuthService) {}

  @Post('login')
  async login(
    @Body() dto: LoginAdminDto,
    @Headers('user-agent') userAgent: string | undefined,
    @Ip() ipAddress: string,
  ) {
    return this.adminAuthService.login(dto.phone, dto.pin, { userAgent, ipAddress });
  }

  @UseGuards(AdminJwtGuard)
  @Get('me')
  me(@CurrentAdmin() admin: AdminJwtPayload) {
    return this.adminAuthService.getMe(admin.sub);
  }
}
