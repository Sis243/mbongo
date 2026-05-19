import { Test, TestingModule } from '@nestjs/testing';
import { CardsController } from './cards.controller';
import { CardsService } from './cards.service';

describe('CardsController', () => {
  let controller: CardsController;
  let service: {
    listForUser: jest.Mock;
    createVirtualCard: jest.Mock;
    topupVirtualCard: jest.Mock;
    toggleStatus: jest.Mock;
  };

  beforeEach(async () => {
    service = {
      listForUser: jest.fn(),
      createVirtualCard: jest.fn(),
      topupVirtualCard: jest.fn(),
      toggleStatus: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CardsController],
      providers: [
        {
          provide: CardsService,
          useValue: service,
        },
      ],
    }).compile();

    controller = module.get<CardsController>(CardsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('uses authenticated user for card creation', () => {
    controller.create(
      {
        userId: 'spoofed-user',
        holderName: 'Client',
        currency: 'USD',
        brand: 'VISA',
      },
      { userId: 'auth-user', phone: '+243000' },
    );

    expect(service.createVirtualCard).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'auth-user',
      }),
    );
  });

  it('uses authenticated user for card topup', () => {
    controller.topup(
      'card-1',
      {
        userId: 'spoofed-user',
        amount: 25,
      },
      { userId: 'auth-user', phone: '+243000' },
    );

    expect(service.topupVirtualCard).toHaveBeenCalledWith(
      'card-1',
      expect.objectContaining({
        userId: 'auth-user',
      }),
    );
  });

  it('uses authenticated user for card status toggle', () => {
    controller.toggleStatus('card-1', { userId: 'auth-user', phone: '+243000' });

    expect(service.toggleStatus).toHaveBeenCalledWith('card-1', 'auth-user');
  });
});
