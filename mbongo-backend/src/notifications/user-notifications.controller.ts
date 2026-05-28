import { Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserNotificationsService } from './user-notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class UserNotificationsController {
  constructor(private readonly service: UserNotificationsService) {}

  @Get('me')
  getMyNotifications(@CurrentUser() user: JwtRequestUser) {
    return this.service.listForUser(user.userId);
  }

  @Get('unread-count')
  async getUnreadCount(@CurrentUser() user: JwtRequestUser) {
    const count = await this.service.countUnread(user.userId);
    return { count };
  }

  @Patch(':id/read')
  async markAsRead(@Param('id') id: string, @CurrentUser() user: JwtRequestUser) {
    await this.service.markAsRead(id, user.userId);
    return { success: true };
  }

  @Post('read-all')
  async markAllRead(@CurrentUser() user: JwtRequestUser) {
    await this.service.markAllRead(user.userId);
    return { success: true };
  }
}
