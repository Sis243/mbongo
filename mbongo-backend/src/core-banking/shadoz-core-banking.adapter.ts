import type { CoreBankingAdapter, BankAccountLookup } from './core-banking-adapter.interface';

interface ShadozAccountResponse {
  firstName?: string;
  lastName?: string;
  fullName?: string;
  accountName?: string;
  currency?: string;
  status?: 'active' | 'dormant' | 'blocked' | 'closed' | 'pending_opening' | 'inactive' | 'unclaimed';
}

interface ShadozEnvelope {
  status?: { code?: string; message?: string };
  response?: ShadozAccountResponse;
}

const ACCOUNT_TYPE: Record<string, string> = {
  active:          'Compte Actif',
  dormant:         'Compte Dormant',
  blocked:         'Compte Bloqué',
  closed:          'Compte Clôturé',
  pending_opening: 'Ouverture en cours',
  inactive:        'Compte Inactif',
  unclaimed:       'Compte Non réclamé',
};

export class ShadozCoreBankingAdapter implements CoreBankingAdapter {
  private readonly baseUrl: string;
  private readonly apiKey: string | undefined;
  private readonly bankName: string;

  constructor() {
    this.baseUrl = (process.env.SHADOZ_BASE_URL ?? 'http://57.129.133.60:8091').replace(/\/$/, '');
    this.apiKey  = process.env.SHADOZ_API_KEY;
    this.bankName = process.env.SHADOZ_BANK_NAME ?? 'Shadoz Bank';
  }

  private headers(): Record<string, string> {
    const h: Record<string, string> = { Accept: 'application/json' };
    if (this.apiKey) h['Authorization'] = `Bearer ${this.apiKey}`;
    return h;
  }

  async lookupAccount(accountNumber: string): Promise<BankAccountLookup> {
    try {
      const encoded = encodeURIComponent(accountNumber.trim());
      const res = await fetch(
        `${this.baseUrl}/api/v1/bank-operation/account-status/${encoded}`,
        { method: 'GET', headers: this.headers(), signal: AbortSignal.timeout(10_000) },
      );

      if (res.status === 404) return { exists: false };
      if (!res.ok)            return { exists: false };

      const body = (await res.json()) as ShadozEnvelope;
      const acct = body?.response;

      if (!acct) return { exists: false };

      // Closed / blocked accounts are unusable for linking
      if (acct.status === 'closed' || acct.status === 'blocked') {
        return { exists: false };
      }

      const holder = acct.fullName
        ?? [acct.firstName, acct.lastName].filter(Boolean).join(' ')
        ?? acct.accountName;

      return {
        exists:        true,
        accountHolder: holder?.toUpperCase() || undefined,
        currency:      acct.currency ?? 'CDF',
        bankName:      this.bankName,
        accountType:   acct.status ? (ACCOUNT_TYPE[acct.status] ?? acct.status) : 'Compte',
        // balance: non disponible dans l'API externe Shadoz — à demander à l'équipe Shadoz
      };
    } catch {
      return { exists: false };
    }
  }
}
