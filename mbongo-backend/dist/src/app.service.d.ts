import { PrismaService } from './prisma/prisma.service';
export declare class AppService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getHealth(): {
        status: string;
        service: string;
        environment: string;
        uptime: number;
        timestamp: string;
    };
    getVersion(): {
        service: string;
        version: string;
        environment: string;
        node: string;
    };
    submitContactMessage(body: {
        name: string;
        email: string;
        phone?: string;
        subject: string;
        message?: string;
    }): Promise<{
        received: boolean;
        id: string;
    }>;
    subscribeNewsletter(body: {
        email: string;
        name?: string;
    }): Promise<{
        subscribed: boolean;
        reactivated: boolean;
        alreadySubscribed?: undefined;
    } | {
        subscribed: boolean;
        alreadySubscribed: boolean;
        reactivated?: undefined;
    } | {
        subscribed: boolean;
        reactivated?: undefined;
        alreadySubscribed?: undefined;
    }>;
}
