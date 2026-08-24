import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { FaqService } from './faq.service';
import { FaqController } from './faq.controller';

@Module({
  imports: [PrismaModule],
  providers: [FaqService],
  controllers: [FaqController],
  exports: [FaqService],
})
export class FaqModule {}
