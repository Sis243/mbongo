import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateUserDto } from './dto/create-user.dto';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly prisma: PrismaService,
  ) {}

  @Post()
  create(@Body() body: CreateUserDto) {
    return this.usersService.createUser(body);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  findMe(@CurrentUser() user: JwtRequestUser) {
    return this.usersService.getOne(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  findAll(@CurrentUser() user: JwtRequestUser) {
    return this.usersService.getOne(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('by-phone/:phone')
  async findByPhone(@Param('phone') phone: string) {
    const user = await this.usersService.getByPhone(phone);
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    return user;
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  findOne(@Param('id') _id: string, @CurrentUser() user: JwtRequestUser) {
    return this.usersService.getOne(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me/backup-phone')
  async updateBackupPhone(
    @CurrentUser() user: JwtRequestUser,
    @Body() body: { backupPhone: string },
  ) {
    const phone = body.backupPhone?.trim() ?? '';
    if (phone && phone.length < 8) {
      throw new BadRequestException('Numero de telephone invalide');
    }
    const updated = await this.prisma.user.update({
      where: { id: user.userId },
      data: { backupPhone: phone || null },
      select: { id: true, backupPhone: true },
    });
    return { success: true, backupPhone: updated.backupPhone };
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/backup-phone')
  async getBackupPhone(@CurrentUser() user: JwtRequestUser) {
    const u = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { backupPhone: true },
    });
    return { backupPhone: u?.backupPhone ?? null };
  }
}
