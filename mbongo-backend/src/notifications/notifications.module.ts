import { Global, Module } from '@nestjs/common';
import { FcmService } from './fcm.service';
import { UserNotificationsController } from './user-notifications.controller';
import { UserNotificationsService } from './user-notifications.service';

@Global()
@Module({
  controllers: [UserNotificationsController],
  providers: [FcmService, UserNotificationsService],
  exports: [FcmService],
})
export class NotificationsModule {}
