import type { JwtRequestUser } from '../auth/auth.types';
import { CardsService } from './cards.service';
import { CreateVirtualCardDto } from './dto/create-virtual-card.dto';
import { TopupVirtualCardDto } from './dto/topup-virtual-card.dto';
export declare class CardsController {
    private readonly cardsService;
    constructor(cardsService: CardsService);
    listMine(user: JwtRequestUser): import("@prisma/client").Prisma.PrismaPromise<{
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: string;
        currency: string;
        balance: number;
        holderName: string;
        brand: string;
        maskedPan: string;
        last4: string;
        expiry: string;
    }[]>;
    listForUser(_userId: string, user: JwtRequestUser): import("@prisma/client").Prisma.PrismaPromise<{
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: string;
        currency: string;
        balance: number;
        holderName: string;
        brand: string;
        maskedPan: string;
        last4: string;
        expiry: string;
    }[]>;
    create(body: CreateVirtualCardDto, user: JwtRequestUser): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: string;
        currency: string;
        balance: number;
        holderName: string;
        brand: string;
        maskedPan: string;
        last4: string;
        expiry: string;
    }>;
    topup(cardId: string, body: TopupVirtualCardDto, user: JwtRequestUser): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: string;
        currency: string;
        balance: number;
        holderName: string;
        brand: string;
        maskedPan: string;
        last4: string;
        expiry: string;
    }>;
    toggleStatus(cardId: string, user: JwtRequestUser): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: string;
        currency: string;
        balance: number;
        holderName: string;
        brand: string;
        maskedPan: string;
        last4: string;
        expiry: string;
    }>;
}
