import type { BillPayAdapter, BillPayResult } from './bill-pay-adapter.interface';

export class MockBillPayAdapter implements BillPayAdapter {
  async processPayment(params: {
    methodId: string;
    methodName: string;
    reference: string;
    amount: number;
    currency: string;
  }): Promise<BillPayResult> {
    // TODO: replace with real aggregator (CinetPay, Smobilpay, etc.)
    console.log(`[BILL-PAY MOCK] ${params.methodName} | ref=${params.reference} | ${params.amount} ${params.currency}`);
    return {
      success: true,
      providerReference: `MOCK-${Date.now()}`,
      message: 'Paiement simule avec succes',
    };
  }
}
