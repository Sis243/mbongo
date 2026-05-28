import { Injectable } from '@nestjs/common';
import type { PaymentGatewayAdapter } from './payment-gateway-adapter.interface';
import type { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { randomUUID } from 'crypto';

/**
 * TODO (intégrateur): Remplacer par un vrai adapter (MtnMomoAdapter, FlutterwaveAdapter, etc.)
 * Changer le binding dans PaymentGatewayModule: { provide: 'PAYMENT_GATEWAY', useClass: RealAdapter }
 */
@Injectable()
export class MockGatewayAdapter implements PaymentGatewayAdapter {
  async initiate(_params: InitiatePaymentDto): Promise<{ referenceId: string; redirectUrl?: string }> {
    return { referenceId: randomUUID() };
  }

  async verify(referenceId: string): Promise<{ status: 'SUCCESS' | 'PENDING' | 'FAILED'; amount: number }> {
    return { status: 'SUCCESS', amount: 0 };
  }

  async refund(_referenceId: string): Promise<void> {
    // no-op in mock
  }
}
