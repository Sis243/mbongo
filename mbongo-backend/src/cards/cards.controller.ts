import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CardsService } from './cards.service';
import { CreateVirtualCardDto } from './dto/create-virtual-card.dto';
import { TopupVirtualCardDto } from './dto/topup-virtual-card.dto';

@Controller('cards')
@UseGuards(JwtAuthGuard)
export class CardsController {
  constructor(private readonly cardsService: CardsService) {}

  @Get('me')
  listMine(@CurrentUser() user: JwtRequestUser) {
    return this.cardsService.listForUser(user.userId);
  }

  @Get('user/:userId')
  listForUser(@Param('userId') _userId: string, @CurrentUser() user: JwtRequestUser) {
    return this.cardsService.listForUser(user.userId);
  }

  @Post()
  create(@Body() body: CreateVirtualCardDto, @CurrentUser() user: JwtRequestUser) {
    return this.cardsService.createVirtualCard({
      ...body,
      userId: user.userId,
    });
  }

  @Post(':cardId/topup')
  topup(
    @Param('cardId') cardId: string,
    @Body() body: TopupVirtualCardDto,
    @CurrentUser() user: JwtRequestUser,
  ) {
    return this.cardsService.topupVirtualCard(cardId, {
      ...body,
      userId: user.userId,
    });
  }

  @Patch(':cardId/toggle')
  toggleStatus(@Param('cardId') cardId: string, @CurrentUser() user: JwtRequestUser) {
    return this.cardsService.toggleStatus(cardId, user.userId);
  }
}
