import type { CoreBankingAdapter, BankAccountLookup } from './core-banking-adapter.interface';

const MOCK_ACCOUNTS: Record<string, BankAccountLookup> = {
  '0000000001': { exists: true, accountHolder: 'Jean Mbongo', balance: 450000, currency: 'CDF', accountType: 'Compte Courant', bankName: 'Rawbank' },
  '0000000002': { exists: true, accountHolder: 'Marie Lukusa', balance: 1200, currency: 'USD', accountType: 'Compte Épargne', bankName: 'Equity Bank' },
  '0000000003': { exists: true, accountHolder: 'Paul Kalala', balance: 980000, currency: 'CDF', accountType: 'Compte Entreprise', bankName: 'TMB' },
};

export class MockCoreBankingAdapter implements CoreBankingAdapter {
  async lookupAccount(accountNumber: string): Promise<BankAccountLookup> {
    const account = MOCK_ACCOUNTS[accountNumber];
    if (account) return account;
    // Any other 10+ digit number returns a generic demo account
    if (/^\d{10,}$/.test(accountNumber)) {
      return {
        exists: true,
        accountHolder: 'Titulaire Demo',
        balance: 250000,
        currency: 'CDF',
        accountType: 'Compte Courant',
        bankName: 'Banque Partenaire',
      };
    }
    return { exists: false };
  }
}
