import { Body, Controller, Get, Post } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHealth() {
    return this.appService.getHealth();
  }

  @Get('health')
  health() {
    return this.appService.getHealth();
  }

  @Get('version')
  version() {
    return this.appService.getVersion();
  }

  @Get('app/version')
  appVersion() {
    return this.appService.getVersion();
  }

  @Post('contact')
  submitContact(
    @Body() body: { name: string; email: string; phone?: string; subject: string; message?: string },
  ) {
    return this.appService.submitContactMessage(body);
  }

  @Post('newsletter/subscribe')
  subscribeNewsletter(@Body() body: { email: string; name?: string }) {
    return this.appService.subscribeNewsletter(body);
  }
}
