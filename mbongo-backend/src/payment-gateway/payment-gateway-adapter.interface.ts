import type { InitiatePaymentDto } from './dto/initiate-payment.dto';

export interface PaymentGatewayAdapter {
  initiate(params: InitiatePaymentDto): Promise<{ referenceId: string; redirectUrl?: string }>;
  verify(referenceId: string): Promise<{ status: 'SUCCESS' | 'PENDING' | 'FAILED'; amount: number }>;
  refund(referenceId: string): Promise<void>;
}
