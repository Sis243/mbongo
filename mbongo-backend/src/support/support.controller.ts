import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { SupportService } from './support.service';

@ApiTags('Support')
@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('tickets')
  async create(
    @CurrentUser() user: JwtRequestUser,
    @Body() body: { subject: string; message: string },
  ) {
    if (!body.subject?.trim()) throw new BadRequestException('Objet requis');
    if (!body.message?.trim()) throw new BadRequestException('Message requis');
    return this.supportService.createTicket(user.userId, body.subject, body.message);
  }

  @Get('tickets')
  list(@CurrentUser() user: JwtRequestUser, @Query('page') page?: string) {
    return this.supportService.listMyTickets(user.userId, Number(page) || 1);
  }

  @Get('tickets/:id')
  getOne(@CurrentUser() user: JwtRequestUser, @Param('id') id: string) {
    return this.supportService.getMyTicket(user.userId, id);
  }

  @Post('tickets/:id/messages')
  addMessage(
    @CurrentUser() user: JwtRequestUser,
    @Param('id') id: string,
    @Body() body: { content: string },
  ) {
    if (!body.content?.trim()) throw new BadRequestException('Message requis');
    return this.supportService.addUserMessage(user.userId, id, body.content);
  }

  @Patch('tickets/:id/close')
  close(@CurrentUser() user: JwtRequestUser, @Param('id') id: string) {
    return this.supportService.closeMyTicket(user.userId, id);
  }
}
