import { Body, Controller, Headers, Ip, Post } from '@nestjs/common';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(
    @Body() body: CreateUserDto,
    @Headers('user-agent') userAgent: string | undefined,
    @Ip() ipAddress: string,
  ) {
    return this.authService.register(body, { userAgent, ipAddress });
  }

  @Post('login')
  login(
    @Body() body: LoginDto,
    @Headers('user-agent') userAgent: string | undefined,
    @Ip() ipAddress: string,
  ) {
    return this.authService.login(body, { userAgent, ipAddress });
  }

  @Post('refresh')
  refresh(
    @Body() body: RefreshTokenDto,
    @Headers('user-agent') userAgent: string | undefined,
    @Ip() ipAddress: string,
  ) {
    return this.authService.refresh(body, { userAgent, ipAddress });
  }

  @Post('logout')
  logout(@Body() body: RefreshTokenDto) {
    return this.authService.logout(body);
  }

  @Post('reset-pin')
  resetPin(@Body() body: { phone: string; code: string; newPin: string }) {
    return this.authService.resetPin(body);
  }
}
