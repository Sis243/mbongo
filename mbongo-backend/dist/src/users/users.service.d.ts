import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
export declare class UsersService {
    private prisma;
    constructor(prisma: PrismaService);
    createUser(data: CreateUserDto): Promise<Omit<{
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
    } & {
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        pinHash: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }, "pinHash">>;
    findAll(): Promise<Omit<{
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
    } & {
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        pinHash: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }, "pinHash">[]>;
    validateCredentials(phone: string, pin: string): Promise<({
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
    } & {
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        pinHash: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }) | null>;
    getOne(id: string): Promise<Omit<{
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
    } & {
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        pinHash: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }, "pinHash"> | null>;
    toPublicUser<T extends {
        pinHash?: string;
    }>(user: T): Omit<T, "pinHash">;
}
