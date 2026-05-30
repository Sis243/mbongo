export interface BankAccountLookup {
  exists: boolean;
  accountHolder?: string;
  balance?: number;
  currency?: string;
  accountType?: string;
  bankName?: string;
}

export interface CoreBankingAdapter {
  lookupAccount(accountNumber: string): Promise<BankAccountLookup>;
}
