import type { JwtRequestUser } from '../auth/auth.types';
import { CreateUserDto } from './dto/create-user.dto';
import { UsersService } from './users.service';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    create(body: CreateUserDto): Promise<Omit<{
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
    findMe(user: JwtRequestUser): Promise<Omit<{
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
    findAll(user: JwtRequestUser): Promise<Omit<{
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
    findOne(_id: string, user: JwtRequestUser): Promise<Omit<{
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
}
