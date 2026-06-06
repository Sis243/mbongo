import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { OtpService } from './otp.service';

@ApiTags('OTP')
@Controller('otp')
export class OtpController {
  constructor(private readonly otpService: OtpService) {}

  @Post('request')
  request(@Body() body: { phone: string; purpose?: 'register' | 'login' | 'reset' }) {
    return this.otpService.requestOtp(body.phone, body.purpose ?? 'register');
  }

  @Post('verify')
  verify(@Body() body: { phone: string; code: string; purpose?: 'register' | 'login' | 'reset' }) {
    return this.otpService.verifyOtp(body.phone, body.code, body.purpose ?? 'register');
  }
}

