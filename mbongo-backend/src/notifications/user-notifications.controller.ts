import { Controller, Get, UseGuards } from '@nestjs/common';
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
}
