export class CreateBillPaymentDto {
  userId?: string;
  methodId!: string;
  methodName!: string;
  reference!: string;
  amount!: number;
  idempotencyKey?: string;
}
