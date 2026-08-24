import { Controller, Get, Patch, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { InboxService } from './inbox.service';

@ApiTags('Inbox')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard)
@Controller('inbox')
export class InboxController {
  constructor(private readonly inbox: InboxService) {}

  @Get()
  list(@CurrentUser() user: JwtRequestUser, @Query('page') page = '1') {
    return this.inbox.list(user.userId, Math.max(1, +page || 1));
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() user: JwtRequestUser) {
    return this.inbox.unreadCount(user.userId);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser() user: JwtRequestUser) {
    return this.inbox.markAllRead(user.userId);
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string, @CurrentUser() user: JwtRequestUser) {
    return this.inbox.markRead(user.userId, id);
  }
}
