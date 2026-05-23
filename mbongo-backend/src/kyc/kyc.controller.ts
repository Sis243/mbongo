import {
  Body,
  Controller,
  Get,
  Post,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { KycService } from './kyc.service';
import type { KycUploadedFile } from './kyc-file.types';

@Controller('kyc')
export class KycController {
  constructor(private readonly kycService: KycService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  getMine(@CurrentUser() user: JwtRequestUser) {
    return this.kycService.getLatestForUser(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('me/submit')
  submitMine(@CurrentUser() user: JwtRequestUser, @Body() body: SubmitKycDto) {
    return this.kycService.submit(user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('me/submit-upload')
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'front', maxCount: 1 },
        { name: 'back', maxCount: 1 },
        { name: 'selfie', maxCount: 1 },
      ],
      {
        limits: {
          fileSize: 5 * 1024 * 1024,
          files: 3,
        },
      },
    ),
  )
  submitMineUpload(
    @CurrentUser() user: JwtRequestUser,
    @Body('documentType') documentType: string,
    @UploadedFiles()
    files: {
      front?: KycUploadedFile[];
      back?: KycUploadedFile[];
      selfie?: KycUploadedFile[];
    },
  ) {
    return this.kycService.submitUpload(user.userId, documentType, {
      front: files.front?.[0],
      back: files.back?.[0],
      selfie: files.selfie?.[0],
    });
  }

}
