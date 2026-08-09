import { Body, Controller, Get, Headers, Ip, Post, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { IsString, Length, Matches, MinLength } from 'class-validator';
import { CurrentAdmin } from './decorators/current-admin.decorator';
import { AdminJwtGuard } from './guards/admin-jwt.guard';
import type { AdminJwtPayload } from './admin-auth.types';
import { AdminAuthService } from './admin-auth.service';
import { LoginAdminDto } from './dto/login-admin.dto';

class ForgotPinDto {
  @IsString()
  @Matches(/^\+?[0-9]{7,15}$/)
  phone!: string;
}

class ResetPinDto {
  @IsString()
  @MinLength(1)
  token!: string;

  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  newPin!: string;
}

class ConfirmTotpDto {
  @IsString()
  @Length(6, 6)
  @Matches(/^[0-9]+$/)
  token!: string;
}

class DisableTotpDto {
  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  pin!: string;
}

@ApiTags('Admin Auth')
@Controller('admin-auth')
export class AdminAuthController {
  constructor(private adminAuthService: AdminAuthService) {}

  @Post('login')
  async login(
    @Body() dto: LoginAdminDto,
    @Headers('user-agent') userAgent: string | undefined,
    @Ip() ipAddress: string,
  ) {
    return this.adminAuthService.login(dto.phone, dto.pin, { userAgent, ipAddress }, dto.totpCode);
  }

  @UseGuards(AdminJwtGuard)
  @Get('me')
  me(@CurrentAdmin() admin: AdminJwtPayload) {
    return this.adminAuthService.getMe(admin.sub);
  }

  @UseGuards(AdminJwtGuard)
  @Post('totp/setup')
  setupTotp(@CurrentAdmin() admin: AdminJwtPayload) {
    return this.adminAuthService.setupTotp(admin.sub);
  }

  @UseGuards(AdminJwtGuard)
  @Post('totp/confirm')
  confirmTotp(@CurrentAdmin() admin: AdminJwtPayload, @Body() dto: ConfirmTotpDto) {
    return this.adminAuthService.confirmTotp(admin.sub, dto.token);
  }

  @UseGuards(AdminJwtGuard)
  @Post('totp/disable')
  disableTotp(@CurrentAdmin() admin: AdminJwtPayload, @Body() dto: DisableTotpDto) {
    return this.adminAuthService.disableTotp(admin.sub, dto.pin);
  }

  @Post('forgot-pin')
  forgotPin(@Body() dto: ForgotPinDto) {
    return this.adminAuthService.forgotPin(dto.phone);
  }

  @Post('reset-pin')
  resetPin(@Body() dto: ResetPinDto) {
    return this.adminAuthService.resetPin(dto.token, dto.newPin);
  }
}

