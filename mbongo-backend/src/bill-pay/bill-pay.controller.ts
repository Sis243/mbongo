import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Controller('bill-pay')
export class BillPayController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('methods')
  async getMethods() {
    const methods = await this.prisma.billPayMethod.findMany({
      where: { isActive: true },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
    });

    const grouped: Record<string, typeof methods> = {};
    for (const m of methods) {
      if (!grouped[m.category]) grouped[m.category] = [];
      grouped[m.category].push(m);
    }

    return { methods, grouped };
  }
}
