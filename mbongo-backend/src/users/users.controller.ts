import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateUserDto } from './dto/create-user.dto';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('Users')
@ApiBearerAuth('access-token')
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
  @Get('me/referrals')
  getMyReferrals(@CurrentUser() user: JwtRequestUser) {
    return this.usersService.getMyReferrals(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  findAll(@CurrentUser() user: JwtRequestUser) {
    return this.usersService.getOne(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('search')
  async search(@Query('q') q: string, @CurrentUser() user: JwtRequestUser) {
    if (!q?.trim() || q.trim().length < 2) return { users: [] };
    const query = q.trim();
    const users = await this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        id: { not: user.userId },
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { phone: { contains: query } },
        ],
      },
      select: { id: true, name: true, phone: true },
      take: 10,
      orderBy: { name: 'asc' },
    });
    return {
      users: users.map((u) => ({
        id: u.id,
        name: u.name,
        phone: u.phone,
        initials: u.name.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase(),
      })),
    };
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
  @Patch('me')
  async updateMe(
    @CurrentUser() user: JwtRequestUser,
    @Body() body: { name?: string; email?: string },
  ) {
    const update: { name?: string; email?: string | null } = {};

    if (body.name !== undefined) {
      const name = body.name?.trim() ?? '';
      if (!name || name.length < 2) throw new BadRequestException('Nom invalide (minimum 2 caracteres)');
      if (name.length > 100) throw new BadRequestException('Nom trop long (maximum 100 caracteres)');
      update.name = name;
    }

    if (body.email !== undefined) {
      const email = body.email?.trim() ?? '';
      if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new BadRequestException('Adresse email invalide');
      }
      update.email = email || null;
    }

    return this.usersService.updateProfile(user.userId, update);
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

