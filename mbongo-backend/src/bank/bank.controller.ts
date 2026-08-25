import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { BankService } from './bank.service';

@ApiTags('Bank')
@ApiBearerAuth('access-token')
@Controller('bank')
@UseGuards(JwtAuthGuard)
export class BankController {
  constructor(private readonly service: BankService) {}

  @Get('linked')
  getLinked(@CurrentUser() user: JwtRequestUser) {
    return this.service.getLinked(user.userId);
  }

  @Post('link')
  link(
    @CurrentUser() user: JwtRequestUser,
    @Body() body: { accountNumber: string; bankName?: string; accountHolder: string; currency?: string; accountType?: string },
  ) {
    return this.service.link(user.userId, body);
  }

  @Delete('linked/:id')
  unlink(@CurrentUser() user: JwtRequestUser, @Param('id') id: string) {
    return this.service.unlink(user.userId, id);
  }
}
