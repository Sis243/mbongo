import { AppService } from './app.service';
export declare class AppController {
    private readonly appService;
    constructor(appService: AppService);
    getHealth(): {
        status: string;
        service: string;
        environment: string;
        uptime: number;
        timestamp: string;
    };
    health(): {
        status: string;
        service: string;
        environment: string;
        uptime: number;
        timestamp: string;
    };
    version(): {
        service: string;
        version: string;
        environment: string;
        node: string;
    };
    submitContact(body: {
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
