import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsController } from './transactions.controller';
import { TransactionsService } from './transactions.service';

describe('TransactionsController', () => {
  let controller: TransactionsController;
  let service: {
    listForUser: jest.Mock;
    listActiveCashAgents: jest.Mock;
    createTransfer: jest.Mock;
    createDeposit: jest.Mock;
    createWithdrawal: jest.Mock;
    createAirtimePurchase: jest.Mock;
    createTvPayment: jest.Mock;
    createMerchantPayment: jest.Mock;
  };

  beforeEach(async () => {
    service = {
      listForUser: jest.fn(),
      listActiveCashAgents: jest.fn(),
      createTransfer: jest.fn(),
      createDeposit: jest.fn(),
      createWithdrawal: jest.fn(),
      createAirtimePurchase: jest.fn(),
      createTvPayment: jest.fn(),
      createMerchantPayment: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [TransactionsController],
      providers: [
        {
          provide: TransactionsService,
          useValue: service,
        },
      ],
    }).compile();

    controller = module.get<TransactionsController>(TransactionsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('uses authenticated user as transfer sender', () => {
    controller.createTransfer(
      {
        senderId: 'spoofed-user',
        receiverId: 'receiver-1',
        amount: 100,
      },
      { userId: 'auth-user', phone: '+243000' },
    );

    expect(service.createTransfer).toHaveBeenCalledWith(
      expect.objectContaining({
        senderId: 'auth-user',
        receiverId: 'receiver-1',
      }),
    );
  });

  it('lists active cash agents for authenticated users', () => {
    service.listActiveCashAgents.mockReturnValue([{ id: 'agent-1' }]);

    expect(controller.listCashAgents()).toEqual([{ id: 'agent-1' }]);
    expect(service.listActiveCashAgents).toHaveBeenCalled();
  });

  it('uses authenticated user for withdrawals', () => {
    controller.createWithdrawal(
      {
        userId: 'spoofed-user',
        amount: 50,
        channel: 'CASH',
        reference: 'AGENT-1',
      },
      { userId: 'auth-user', phone: '+243000' },
    );

    expect(service.createWithdrawal).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'auth-user',
      }),
    );
  });
});
