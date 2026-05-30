export interface BillPayResult {
  success: boolean;
  providerReference: string;
  message?: string;
}

export interface BillPayAdapter {
  processPayment(params: {
    methodId: string;
    methodName: string;
    reference: string;
    amount: number;
    currency: string;
  }): Promise<BillPayResult>;
}
