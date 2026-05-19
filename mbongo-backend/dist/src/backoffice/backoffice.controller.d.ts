import type { AdminJwtPayload } from '../admin-auth/admin-auth.types';
import { AssignMerchantRoleDto } from './dto/assign-merchant-role.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { CreateAdminUserDto } from './dto/create-admin-user.dto';
import { CreateAdminVirtualCardDto } from './dto/create-admin-virtual-card.dto';
import { OnboardTerminalDto } from './dto/onboard-terminal.dto';
import { type ReviewKycDto } from './dto/review-kyc.dto';
import { SettleCashAgentCommissionDto } from './dto/settle-cash-agent-commission.dto';
import { TopupAdminVirtualCardDto } from './dto/topup-admin-virtual-card.dto';
import { UpdateAdminRolesDto } from './dto/update-admin-roles.dto';
import { UpdateAdminStatusDto } from './dto/update-admin-status.dto';
import { UpdateCashAgentStatusDto } from './dto/update-cash-agent-status.dto';
import { UpdateChannelDto } from './dto/update-channel.dto';
import { UpdateDisputeDto } from './dto/update-dispute.dto';
import { UpdateTransactionStatusDto } from './dto/update-transaction-status.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpsertAdminRoleDto } from './dto/upsert-admin-role.dto';
import { UpsertCashAgentDto } from './dto/upsert-cash-agent.dto';
import { UpsertMerchantDto } from './dto/upsert-merchant.dto';
import { BackofficeService } from './backoffice.service';
export declare class BackofficeController {
    private readonly backofficeService;
    constructor(backofficeService: BackofficeService);
    getDashboard(): Promise<{
        metrics: {
            id: string;
            label: string;
            value: number;
            accent: string;
        }[];
        channels: {
            updatedAt: string;
            id: string;
            name: string;
            createdAt: Date;
            category: string;
            enabled: boolean;
            mode: import("@prisma/client").$Enums.ChannelMode;
            health: import("@prisma/client").$Enums.ChannelHealth;
            webhookUrl: string | null;
            successRate: number;
            pendingEvents: number;
            apiKeyPreview: string | null;
        }[];
        kycQueue: ({
            user: {
                id: string;
                name: string;
                phone: string;
            };
        } & {
            id: string;
            createdAt: Date;
            userId: string;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.KycStatus;
            rejectionReason: string | null;
            documentType: string | null;
            submittedAt: Date | null;
            reviewedAt: Date | null;
            reviewedBy: string | null;
        })[];
        integrators: {
            id: string;
            name: string;
            mode: import("@prisma/client").$Enums.ChannelMode;
            enabled: boolean;
            endpoint: string | null;
            apiKeyPreview: string | null;
        }[];
        summary: {
            totalUsers: number;
            totalBalance: number;
            cardsBalance: number;
            virtualCards: number;
            blockedCards: number;
            ledgerEntries: number;
            enabledChannels: number;
            liveChannels: number;
        };
        virtualCards: {
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
        }[];
        ledgerEntries: {
            id: string;
            entryType: string;
            direction: string;
            amount: number;
            balanceBefore: number;
            balanceAfter: number;
            description: string | null;
            metadata: string | null;
            createdAt: Date;
            transaction: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                status: import("@prisma/client").$Enums.TransactionStatus;
                amount: number;
                currency: string;
                type: string;
                reference: string | null;
                idempotencyKey: string | null;
                fee: number;
                senderId: string | null;
                receiverId: string | null;
                agentId: string | null;
                metadata: string | null;
            } | null;
            user: {
                id: string;
                name: string;
                phone: string;
            };
        }[];
        merchant: {
            merchants: {
                id: string;
                name: string;
                category: string | null;
                location: string | null;
                status: import("@prisma/client").$Enums.MerchantStatus;
                terminals: number;
                dailyVolume: number;
            }[];
            terminals: {
                id: string;
                merchantId: string;
                merchant: string;
                location: string | null;
                status: import("@prisma/client").$Enums.TerminalStatus;
                lastMethod: string | null;
                lastSeen: string | null;
                transactionsCount: number;
                health: import("@prisma/client").$Enums.ChannelHealth;
            }[];
            receipts: {
                id: string;
                merchantId: string;
                merchant: string;
                terminalId: string | null;
                method: string;
                amount: number;
                currency: string;
                status: import("@prisma/client").$Enums.ReceiptStatus;
                location: string | null;
                customerRef: string | null;
                createdAt: string;
                steps: string[];
            }[];
            roles: {
                id: string;
                merchantId: string;
                merchant: string;
                name: string;
                role: string;
                permissions: string[];
            }[];
            summary: {
                merchants: number;
                terminals: number;
                receipts: number;
                roles: number;
            };
        };
    }>;
    listChannels(): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        category: string;
        enabled: boolean;
        mode: import("@prisma/client").$Enums.ChannelMode;
        health: import("@prisma/client").$Enums.ChannelHealth;
        webhookUrl: string | null;
        successRate: number;
        pendingEvents: number;
        apiKeyPreview: string | null;
        updatedAt: Date;
    }[]>;
    listCurrencies(): Promise<{
        summary: {
            total: number;
            enabled: number;
            disabled: number;
            defaultCurrency: string;
        };
        currencies: {
            id: string;
            country: string;
            name: string;
            code: string;
            symbol: string;
            rateLabel: string;
            rate: number;
            enabled: boolean;
            isDefault: boolean;
            roles: string[];
        }[];
    }>;
    listUsers(): Promise<{
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
        kycSubmissions: {
            id: string;
            createdAt: Date;
            status: import("@prisma/client").$Enums.KycStatus;
            rejectionReason: string | null;
            documentType: string | null;
            submittedAt: Date | null;
            reviewedAt: Date | null;
        }[];
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }[]>;
    updateUserStatus(id: string, body: UpdateUserStatusDto, admin: AdminJwtPayload): Promise<{
        wallet: {
            id: string;
            userId: string;
            balance: number;
        } | null;
        kycSubmissions: {
            id: string;
            createdAt: Date;
            status: import("@prisma/client").$Enums.KycStatus;
            rejectionReason: string | null;
            documentType: string | null;
            submittedAt: Date | null;
            reviewedAt: Date | null;
        }[];
        id: string;
        name: string;
        createdAt: Date;
        phone: string;
        email: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
    }>;
    listKycSubmissions(page?: string, limit?: string): Promise<({
        user: {
            id: string;
            name: string;
            phone: string;
        };
        documents: {
            id: string;
            createdAt: Date;
            submissionId: string;
            side: import("@prisma/client").$Enums.KycDocumentSide;
            fileUrl: string;
            fileMimeType: string | null;
            providerRef: string | null;
            verificationData: string | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.KycStatus;
        rejectionReason: string | null;
        documentType: string | null;
        submittedAt: Date | null;
        reviewedAt: Date | null;
        reviewedBy: string | null;
    })[] | {
        data: ({
            user: {
                id: string;
                name: string;
                phone: string;
            };
            documents: {
                id: string;
                createdAt: Date;
                submissionId: string;
                side: import("@prisma/client").$Enums.KycDocumentSide;
                fileUrl: string;
                fileMimeType: string | null;
                providerRef: string | null;
                verificationData: string | null;
            }[];
        } & {
            id: string;
            createdAt: Date;
            userId: string;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.KycStatus;
            rejectionReason: string | null;
            documentType: string | null;
            submittedAt: Date | null;
            reviewedAt: Date | null;
            reviewedBy: string | null;
        })[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    }>;
    reviewKycSubmission(id: string, body: ReviewKycDto, admin: AdminJwtPayload): Promise<{
        user: {
            id: string;
            name: string;
            phone: string;
        };
        documents: {
            id: string;
            createdAt: Date;
            submissionId: string;
            side: import("@prisma/client").$Enums.KycDocumentSide;
            fileUrl: string;
            fileMimeType: string | null;
            providerRef: string | null;
            verificationData: string | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.KycStatus;
        rejectionReason: string | null;
        documentType: string | null;
        submittedAt: Date | null;
        reviewedAt: Date | null;
        reviewedBy: string | null;
    }>;
    listAuditLogs(page?: string, limit?: string): Promise<{
        metadata: Record<string, unknown>;
        actor: {
            type: string;
            id: string;
            name: string;
            phone: string;
        } | {
            type: string;
            id: {} | null;
            phone: {} | null;
            name?: undefined;
        };
    }[] | {
        data: {
            metadata: Record<string, unknown>;
            actor: {
                type: string;
                id: string;
                name: string;
                phone: string;
            } | {
                type: string;
                id: {} | null;
                phone: {} | null;
                name?: undefined;
            };
        }[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    }>;
    getAdminAccessSnapshot(): Promise<{
        admins: {
            roles: {
                id: string;
                name: string;
                description: string | null;
                permissions: string[];
            }[];
            id: string;
            createdAt: Date;
            phone: string;
            email: string | null;
            isActive: boolean;
        }[];
        roles: {
            id: string;
            name: string;
            description: string | null;
            createdAt: Date;
            usersCount: number;
            permissions: {
                id: string;
                name: string;
            }[];
        }[];
        permissions: {
            id: string;
            name: string;
            createdAt: Date;
        }[];
        summary: {
            admins: number;
            activeAdmins: number;
            roles: number;
            permissions: number;
        };
    }>;
    createAdminUser(body: CreateAdminUserDto, admin: AdminJwtPayload): Promise<{
        roles: ({
            role: {
                id: string;
                name: string;
                createdAt: Date;
                description: string | null;
            };
        } & {
            id: string;
            userId: string;
            roleId: string;
        })[];
        id: string;
        createdAt: Date;
        phone: string;
        email: string | null;
        isActive: boolean;
    }>;
    updateAdminStatus(id: string, body: UpdateAdminStatusDto, admin: AdminJwtPayload): Promise<{
        roles: ({
            role: {
                id: string;
                name: string;
                createdAt: Date;
                description: string | null;
            };
        } & {
            id: string;
            userId: string;
            roleId: string;
        })[];
        id: string;
        createdAt: Date;
        phone: string;
        email: string | null;
        isActive: boolean;
    }>;
    updateAdminRoles(id: string, body: UpdateAdminRolesDto, admin: AdminJwtPayload): Promise<{
        roles: ({
            role: {
                id: string;
                name: string;
                createdAt: Date;
                description: string | null;
            };
        } & {
            id: string;
            userId: string;
            roleId: string;
        })[];
        id: string;
        createdAt: Date;
        phone: string;
        email: string | null;
        isActive: boolean;
    }>;
    upsertAdminRole(body: UpsertAdminRoleDto, admin: AdminJwtPayload): Promise<{
        id: string;
        name: string;
        description: string | null;
        usersCount: number;
        permissions: {
            id: string;
            name: string;
        }[];
    }>;
    updateCurrency(id: string, body: {
        isEnabled?: boolean;
        rate?: number;
        rateLabel?: string;
    }): Promise<{
        id: string;
        name: string;
        symbol: string;
        rate: number;
        rateLabel: string;
        enabled: boolean;
        isDefault: boolean;
    }>;
    listFees(): Promise<{
        summary: {
            total: number;
            currency: string;
            maxDailyLimit: number;
            maxMonthlyLimit: number;
        };
        fees: {
            id: string;
            createdAt: Date;
            isActive: boolean;
            updatedAt: Date;
            currency: string;
            title: string;
            fixedFee: number;
            percentFee: number;
            minAmount: number;
            maxAmount: number;
            dailyLimit: number;
            monthlyLimit: number;
            agentFixedCommission: number;
            agentPercentCommission: number;
        }[];
    }>;
    listVirtualCards(): Promise<({
        user: {
            id: string;
            name: string;
            phone: string;
        };
        operations: {
            id: string;
            createdAt: Date;
            amount: number | null;
            type: string;
            metadata: string | null;
            cardId: string;
            balanceBefore: number | null;
            balanceAfter: number | null;
            statusBefore: string | null;
            statusAfter: string | null;
            actorType: string;
            actorId: string | null;
        }[];
    } & {
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
    })[]>;
    createVirtualCard(body: CreateAdminVirtualCardDto, admin: AdminJwtPayload): Promise<{
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
    topupVirtualCard(id: string, body: TopupAdminVirtualCardDto, admin: AdminJwtPayload): Promise<{
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
    toggleVirtualCard(id: string, admin: AdminJwtPayload): Promise<({
        user: {
            id: string;
            name: string;
            phone: string;
        };
        operations: {
            id: string;
            createdAt: Date;
            amount: number | null;
            type: string;
            metadata: string | null;
            cardId: string;
            balanceBefore: number | null;
            balanceAfter: number | null;
            statusBefore: string | null;
            statusAfter: string | null;
            actorType: string;
            actorId: string | null;
        }[];
    } & {
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
    }) | null>;
    listLedgerEntries(page?: string, limit?: string): Promise<({
        wallet: {
            user: {
                id: string;
                name: string;
                createdAt: Date;
                phone: string;
            };
        } & {
            id: string;
            userId: string;
            balance: number;
        };
        transaction: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.TransactionStatus;
            amount: number;
            currency: string;
            type: string;
            reference: string | null;
            idempotencyKey: string | null;
            fee: number;
            senderId: string | null;
            receiverId: string | null;
            agentId: string | null;
            metadata: string | null;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        description: string | null;
        amount: number;
        transactionId: string | null;
        metadata: string | null;
        balanceBefore: number;
        balanceAfter: number;
        entryType: string;
        direction: string;
        walletId: string;
    })[] | {
        data: ({
            wallet: {
                user: {
                    id: string;
                    name: string;
                    createdAt: Date;
                    phone: string;
                };
            } & {
                id: string;
                userId: string;
                balance: number;
            };
            transaction: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                status: import("@prisma/client").$Enums.TransactionStatus;
                amount: number;
                currency: string;
                type: string;
                reference: string | null;
                idempotencyKey: string | null;
                fee: number;
                senderId: string | null;
                receiverId: string | null;
                agentId: string | null;
                metadata: string | null;
            } | null;
        } & {
            id: string;
            createdAt: Date;
            description: string | null;
            amount: number;
            transactionId: string | null;
            metadata: string | null;
            balanceBefore: number;
            balanceAfter: number;
            entryType: string;
            direction: string;
            walletId: string;
        })[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    }>;
    listTransactions(page?: string, limit?: string): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string;
        updatedAt: string;
        ledgerEntries: {
            metadata: Record<string, unknown>;
            createdAt: string;
            id: string;
            walletId: string;
            entryType: string;
            direction: string;
            amount: number;
            balanceBefore: number;
            balanceAfter: number;
            description: string | null;
            wallet: {
                id: string;
                userId: string;
                balance: number;
                user?: {
                    id: string;
                    name: string;
                    phone: string;
                    status: string;
                };
            };
        }[];
        id: string;
        type: string;
        status: string;
        amount: number;
        senderId: string | null;
        receiverId: string | null;
        agentId?: string | null;
        reference: string | null;
        agent?: {
            id: string;
            code: string;
            name: string;
            location: string | null;
        } | null;
    }[] | {
        data: {
            metadata: Record<string, unknown>;
            createdAt: string;
            updatedAt: string;
            ledgerEntries: {
                metadata: Record<string, unknown>;
                createdAt: string;
                id: string;
                walletId: string;
                entryType: string;
                direction: string;
                amount: number;
                balanceBefore: number;
                balanceAfter: number;
                description: string | null;
                wallet: {
                    id: string;
                    userId: string;
                    balance: number;
                    user?: {
                        id: string;
                        name: string;
                        phone: string;
                        status: string;
                    };
                };
            }[];
            id: string;
            type: string;
            status: string;
            amount: number;
            senderId: string | null;
            receiverId: string | null;
            agentId?: string | null;
            reference: string | null;
            agent?: {
                id: string;
                code: string;
                name: string;
                location: string | null;
            } | null;
        }[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    }>;
    getAgentCashOperations(): Promise<{
        summary: {
            activeAgents: number;
            registeredAgents: number;
            operations: number;
            cashIn: number;
            cashOut: number;
            pending: number;
            commissionEarned: number;
            commissionBalance: number;
        };
        agents: {
            id: string | null;
            code: string | null;
            name: string;
            phone: string | null;
            location: string | null;
            status: string;
            dailyCashInLimit: number | null;
            dailyCashOutLimit: number | null;
            commissionBalance: number;
            commissionEarned: number;
            commissionPayouts: {
                id: string;
                amount: number;
                previousBalance: number;
                nextBalance: number;
                reference: string | null;
                note: string | null;
                paidByAdminId: string | null;
                createdAt: string;
            }[];
            operations: number;
            cashIn: number;
            cashOut: number;
            pending: number;
            failed: number;
            lastOperationAt: string | null;
        }[];
        operations: {
            id: string;
            reference: string | null;
            type: string;
            status: string;
            amount: number;
            agentCommission: number;
            agentId: string | null;
            agentName: string;
            channel: string;
            createdAt: string;
            user: {
                id: string | null;
                name: string;
                phone: string;
                status: string;
            };
            metadata: Record<string, unknown>;
        }[];
    }>;
    upsertCashAgent(body: UpsertCashAgentDto, admin: AdminJwtPayload): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        phone: string | null;
        updatedAt: Date;
        code: string;
        location: string | null;
        status: import("@prisma/client").$Enums.CashAgentStatus;
        dailyCashInLimit: number;
        dailyCashOutLimit: number;
        commissionBalance: number;
    }>;
    updateCashAgentStatus(id: string, body: UpdateCashAgentStatusDto, admin: AdminJwtPayload): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        phone: string | null;
        updatedAt: Date;
        code: string;
        location: string | null;
        status: import("@prisma/client").$Enums.CashAgentStatus;
        dailyCashInLimit: number;
        dailyCashOutLimit: number;
        commissionBalance: number;
    }>;
    settleCashAgentCommission(id: string, body: SettleCashAgentCommissionDto, admin: AdminJwtPayload): Promise<{
        agent: {
            id: string;
            name: string;
            createdAt: Date;
            phone: string | null;
            updatedAt: Date;
            code: string;
            location: string | null;
            status: import("@prisma/client").$Enums.CashAgentStatus;
            dailyCashInLimit: number;
            dailyCashOutLimit: number;
            commissionBalance: number;
        };
        payout: {
            id: string;
            createdAt: Date;
            amount: number;
            reference: string | null;
            note: string | null;
            agentId: string;
            previousBalance: number;
            nextBalance: number;
            paidByAdminId: string | null;
        };
    }>;
    getTransaction(id: string): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string;
        updatedAt: string;
        ledgerEntries: {
            metadata: Record<string, unknown>;
            createdAt: string;
            id: string;
            walletId: string;
            entryType: string;
            direction: string;
            amount: number;
            balanceBefore: number;
            balanceAfter: number;
            description: string | null;
            wallet: {
                id: string;
                userId: string;
                balance: number;
                user?: {
                    id: string;
                    name: string;
                    phone: string;
                    status: string;
                };
            };
        }[];
        id: string;
        type: string;
        status: string;
        amount: number;
        senderId: string | null;
        receiverId: string | null;
        agentId?: string | null;
        reference: string | null;
        agent?: {
            id: string;
            code: string;
            name: string;
            location: string | null;
        } | null;
    }>;
    listDisputes(): Promise<({
        user: {
            id: string;
            name: string;
            phone: string;
            status: import("@prisma/client").$Enums.UserStatus;
        } | null;
        transaction: {
            id: string;
            createdAt: Date;
            status: import("@prisma/client").$Enums.TransactionStatus;
            amount: number;
            type: string;
            reference: string | null;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        description: string;
        userId: string | null;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.DisputeStatus;
        subject: string;
        transactionId: string | null;
        priority: import("@prisma/client").$Enums.DisputePriority;
        resolution: string | null;
        assignedAdminId: string | null;
        resolvedAt: Date | null;
    })[]>;
    createDispute(body: CreateDisputeDto, admin: AdminJwtPayload): Promise<{
        user: {
            id: string;
            name: string;
            phone: string;
            status: import("@prisma/client").$Enums.UserStatus;
        } | null;
        transaction: {
            id: string;
            createdAt: Date;
            status: import("@prisma/client").$Enums.TransactionStatus;
            amount: number;
            type: string;
            reference: string | null;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        description: string;
        userId: string | null;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.DisputeStatus;
        subject: string;
        transactionId: string | null;
        priority: import("@prisma/client").$Enums.DisputePriority;
        resolution: string | null;
        assignedAdminId: string | null;
        resolvedAt: Date | null;
    }>;
    updateDispute(id: string, body: UpdateDisputeDto, admin: AdminJwtPayload): Promise<{
        user: {
            id: string;
            name: string;
            phone: string;
            status: import("@prisma/client").$Enums.UserStatus;
        } | null;
        transaction: {
            id: string;
            createdAt: Date;
            status: import("@prisma/client").$Enums.TransactionStatus;
            amount: number;
            type: string;
            reference: string | null;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        description: string;
        userId: string | null;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.DisputeStatus;
        subject: string;
        transactionId: string | null;
        priority: import("@prisma/client").$Enums.DisputePriority;
        resolution: string | null;
        assignedAdminId: string | null;
        resolvedAt: Date | null;
    }>;
    updateTransactionStatus(id: string, body: UpdateTransactionStatusDto, admin: AdminJwtPayload): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string;
        updatedAt: string;
        ledgerEntries: {
            metadata: Record<string, unknown>;
            createdAt: string;
            id: string;
            walletId: string;
            entryType: string;
            direction: string;
            amount: number;
            balanceBefore: number;
            balanceAfter: number;
            description: string | null;
            wallet: {
                id: string;
                userId: string;
                balance: number;
                user?: {
                    id: string;
                    name: string;
                    phone: string;
                    status: string;
                };
            };
        }[];
        id: string;
        type: string;
        status: string;
        amount: number;
        senderId: string | null;
        receiverId: string | null;
        agentId?: string | null;
        reference: string | null;
        agent?: {
            id: string;
            code: string;
            name: string;
            location: string | null;
        } | null;
    }>;
    getMerchantBackoffice(): Promise<{
        merchants: {
            id: string;
            name: string;
            category: string | null;
            location: string | null;
            status: import("@prisma/client").$Enums.MerchantStatus;
            terminals: number;
            dailyVolume: number;
        }[];
        terminals: {
            id: string;
            merchantId: string;
            merchant: string;
            location: string | null;
            status: import("@prisma/client").$Enums.TerminalStatus;
            lastMethod: string | null;
            lastSeen: string | null;
            transactionsCount: number;
            health: import("@prisma/client").$Enums.ChannelHealth;
        }[];
        receipts: {
            id: string;
            merchantId: string;
            merchant: string;
            terminalId: string | null;
            method: string;
            amount: number;
            currency: string;
            status: import("@prisma/client").$Enums.ReceiptStatus;
            location: string | null;
            customerRef: string | null;
            createdAt: string;
            steps: string[];
        }[];
        roles: {
            id: string;
            merchantId: string;
            merchant: string;
            name: string;
            role: string;
            permissions: string[];
        }[];
        summary: {
            merchants: number;
            terminals: number;
            receipts: number;
            roles: number;
        };
    }>;
    listMerchants(): Promise<{
        id: string;
        name: string;
        category: string | null;
        location: string | null;
        status: import("@prisma/client").$Enums.MerchantStatus;
        terminals: number;
        dailyVolume: number;
    }[]>;
    upsertMerchant(body: UpsertMerchantDto): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        category: string | null;
        updatedAt: Date;
        location: string | null;
        status: import("@prisma/client").$Enums.MerchantStatus;
        dailyVolume: number;
    }>;
    listTerminals(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        location: string | null;
        status: import("@prisma/client").$Enums.TerminalStatus;
        lastMethod: string | null;
        lastSeen: string | null;
        transactionsCount: number;
        health: import("@prisma/client").$Enums.ChannelHealth;
    }[]>;
    onboardTerminal(body: OnboardTerminalDto): Promise<{
        created: boolean;
        message: string;
        terminal?: undefined;
    } | {
        created: boolean;
        terminal: {
            id: string;
            createdAt: Date;
            health: import("@prisma/client").$Enums.ChannelHealth;
            updatedAt: Date;
            location: string | null;
            status: import("@prisma/client").$Enums.TerminalStatus;
            merchantId: string;
            lastMethod: string | null;
            lastSeen: Date | null;
            transactionsCount: number;
        };
        message?: undefined;
    }>;
    listReceipts(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        terminalId: string | null;
        method: string;
        amount: number;
        currency: string;
        status: import("@prisma/client").$Enums.ReceiptStatus;
        location: string | null;
        customerRef: string | null;
        createdAt: string;
        steps: string[];
    }[]>;
    getReceipt(id: string): Promise<{
        found: boolean;
        message: string;
        id?: undefined;
        merchantId?: undefined;
        merchant?: undefined;
        terminalId?: undefined;
        method?: undefined;
        amount?: undefined;
        currency?: undefined;
        status?: undefined;
        location?: undefined;
        customerRef?: undefined;
        createdAt?: undefined;
        steps?: undefined;
    } | {
        id: string;
        merchantId: string;
        merchant: string;
        terminalId: string | null;
        method: string;
        amount: number;
        currency: string;
        status: import("@prisma/client").$Enums.ReceiptStatus;
        location: string | null;
        customerRef: string | null;
        createdAt: string;
        steps: string[];
        found?: undefined;
        message?: undefined;
    }>;
    listRoles(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        name: string;
        role: string;
        permissions: string[];
    }[]>;
    assignRole(body: AssignMerchantRoleDto): Promise<{
        created: boolean;
        message: string;
        role?: undefined;
    } | {
        created: boolean;
        role: {
            id: string;
            name: string;
            createdAt: Date;
            permissions: string | null;
            role: string;
            merchantId: string;
        };
        message?: undefined;
    }>;
    updateChannel(id: string, body: UpdateChannelDto): Promise<{
        updated: boolean;
        message: string;
        channel?: undefined;
    } | {
        updated: boolean;
        channel: {
            id: string;
            name: string;
            createdAt: Date;
            category: string;
            enabled: boolean;
            mode: import("@prisma/client").$Enums.ChannelMode;
            health: import("@prisma/client").$Enums.ChannelHealth;
            webhookUrl: string | null;
            successRate: number;
            pendingEvents: number;
            apiKeyPreview: string | null;
            updatedAt: Date;
        };
        message?: undefined;
    }>;
    rotateKey(id: string): Promise<{
        updated: boolean;
        message: string;
        channel?: undefined;
    } | {
        updated: boolean;
        channel: {
            id: string;
            name: string;
            createdAt: Date;
            category: string;
            enabled: boolean;
            mode: import("@prisma/client").$Enums.ChannelMode;
            health: import("@prisma/client").$Enums.ChannelHealth;
            webhookUrl: string | null;
            successRate: number;
            pendingEvents: number;
            apiKeyPreview: string | null;
            updatedAt: Date;
        };
        message?: undefined;
    }>;
    listContactMessages(): Promise<{
        stats: {
            total: number;
            newCount: number;
            readCount: number;
            repliedCount: number;
        };
        messages: {
            id: string;
            name: string;
            createdAt: Date;
            phone: string | null;
            email: string;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.ContactMessageStatus;
            subject: string;
            message: string | null;
            readAt: Date | null;
            repliedAt: Date | null;
            replyNote: string | null;
        }[];
    }>;
    updateContactMessage(id: string, body: {
        status?: string;
        replyNote?: string;
    }): Promise<{
        updated: {
            id: string;
            name: string;
            createdAt: Date;
            phone: string | null;
            email: string;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.ContactMessageStatus;
            subject: string;
            message: string | null;
            readAt: Date | null;
            repliedAt: Date | null;
            replyNote: string | null;
        };
    }>;
    listNewsletterSubscribers(): Promise<{
        stats: {
            total: number;
            active: number;
            inactive: number;
        };
        subscribers: {
            id: string;
            name: string | null;
            email: string;
            isActive: boolean;
            subscribedAt: Date;
            unsubscribedAt: Date | null;
        }[];
    }>;
    deleteNewsletterSubscriber(id: string): Promise<{
        unsubscribed: boolean;
    }>;
    listErrorLogs(): Promise<{
        stats: {
            total: number;
            errors: number;
            warnings: number;
        };
        logs: {
            path: string | null;
            id: string;
            createdAt: Date;
            userId: string | null;
            method: string | null;
            message: string;
            level: string;
            stack: string | null;
            context: string | null;
        }[];
    }>;
    listPaymentLinks(): Promise<{
        stats: {
            total: number;
            active: number;
            paid: number;
            expired: number;
            volume: number;
        };
        links: {
            id: string;
            createdAt: Date;
            description: string | null;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.PaymentLinkStatus;
            amount: number;
            currency: string;
            title: string;
            expiresAt: Date | null;
            transactionId: string | null;
            metadata: string | null;
            createdByAdminId: string | null;
            paidAt: Date | null;
            paidByUserId: string | null;
        }[];
    }>;
    createPaymentLink(body: {
        title: string;
        amount: number;
        currency?: string;
        description?: string;
        expiresAt?: string;
    }, admin: AdminJwtPayload): Promise<{
        created: boolean;
        link: {
            id: string;
            createdAt: Date;
            description: string | null;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.PaymentLinkStatus;
            amount: number;
            currency: string;
            title: string;
            expiresAt: Date | null;
            transactionId: string | null;
            metadata: string | null;
            createdByAdminId: string | null;
            paidAt: Date | null;
            paidByUserId: string | null;
        };
    }>;
    updatePaymentLink(id: string, body: {
        status?: string;
    }): Promise<{
        updated: {
            id: string;
            createdAt: Date;
            description: string | null;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.PaymentLinkStatus;
            amount: number;
            currency: string;
            title: string;
            expiresAt: Date | null;
            transactionId: string | null;
            metadata: string | null;
            createdByAdminId: string | null;
            paidAt: Date | null;
            paidByUserId: string | null;
        };
    }>;
    getServerInfo(): Promise<{
        items: {
            key: string;
            label: string;
            value: string;
            tone: string;
        }[];
    }>;
    getCookieSettings(): Promise<{
        enabled: boolean;
        policyUrl: string;
        description: string;
    }>;
    updateCookieSettings(body: {
        enabled?: boolean;
        policyUrl?: string;
        description?: string;
    }): Promise<{
        enabled: boolean;
        policyUrl: string;
        description: string;
    }>;
    listNotifications(): Promise<{
        stats: {
            total: number;
            push: number;
            email: number;
            sms: number;
            inApp: number;
            sent: number;
            failed: number;
        };
        notifications: {
            id: string;
            createdAt: Date;
            userId: string | null;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.NotificationStatus;
            title: string;
            channel: import("@prisma/client").$Enums.NotificationChannel;
            createdByAdminId: string | null;
            body: string;
            audience: import("@prisma/client").$Enums.NotificationAudience;
            templateKey: string | null;
            failureReason: string | null;
            scheduledAt: Date | null;
            sentAt: Date | null;
        }[];
    }>;
    sendNotification(body: {
        title: string;
        message: string;
        channel: string;
        audience: string;
        userId?: string;
        scheduledAt?: string;
    }, admin: AdminJwtPayload): Promise<{
        sent: boolean;
        notification: {
            id: string;
            createdAt: Date;
            userId: string | null;
            updatedAt: Date;
            status: import("@prisma/client").$Enums.NotificationStatus;
            title: string;
            channel: import("@prisma/client").$Enums.NotificationChannel;
            createdByAdminId: string | null;
            body: string;
            audience: import("@prisma/client").$Enums.NotificationAudience;
            templateKey: string | null;
            failureReason: string | null;
            scheduledAt: Date | null;
            sentAt: Date | null;
        };
    }>;
}
