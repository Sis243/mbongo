import type { CoreBankingAdapter, BankAccountLookup } from './core-banking-adapter.interface';

// Comptes demo — renvoient les vraies données du compte lié
const KNOWN_ACCOUNTS: Record<string, BankAccountLookup> = {
  '00032-001-01587435-25': { exists: true, accountHolder: 'FLORY BOKAKO',    balance: 10000000000, currency: 'CDF', accountType: 'Compte Courant',    bankName: 'CADECO' },
  '00032-001-01587436-62': { exists: true, accountHolder: 'FLORY BOKAKO',    balance: 500000,      currency: 'USD', accountType: 'Compte Devises',     bankName: 'CADECO' },
  '00032-002-02946511-18': { exists: true, accountHolder: 'ROSSY MUNDYO',    balance: 3500000,     currency: 'CDF', accountType: 'Compte Agent',       bankName: 'CADECO' },
  '00032-003-05839174-42': { exists: true, accountHolder: 'SHOP MBONGO SARL', balance: 8000000,    currency: 'CDF', accountType: 'Compte Commercial',  bankName: 'CADECO' },
};

// Prénoms et noms DRC pour simulation réaliste
const PRENOMS = ['Jean', 'Marie', 'Paul', 'Grace', 'David', 'Esther', 'Emmanuel', 'Rebecca',
  'Patrick', 'Joëlle', 'Christian', 'Sandra', 'Richard', 'Nadège', 'Olivier', 'Prisca',
  'François', 'Béatrice', 'Serge', 'Angélique', 'Dieudonné', 'Clarisse', 'Honoré', 'Laetitia'];
const NOMS = ['Mbongo', 'Kasongo', 'Lukusa', 'Kalala', 'Mbuyi', 'Nzinga', 'Mutombo', 'Nkosi',
  'Lumba', 'Bisimwa', 'Kasereka', 'Kambale', 'Masudi', 'Nsimba', 'Lutete', 'Banza',
  'Kabongo', 'Tshiela', 'Mulongo', 'Ngandu', 'Ilunga', 'Mwamba', 'Kabila', 'Dunia'];
const TYPES_COMPTE = ['Compte Courant', 'Compte Épargne', 'Compte Salaire', 'Compte Commercial'];

// Pseudo-aléatoire déterministe basé sur le numéro de compte
function seed(accountNumber: string, offset = 0): number {
  const n = accountNumber.replace(/\D/g, '');
  let h = offset * 2654435761;
  for (let i = 0; i < n.length; i++) h = Math.imul(h ^ n.charCodeAt(i), 2246822519);
  h = Math.imul(h ^ (h >>> 16), 2246822519);
  return (h >>> 0) / 4294967296;
}

function pick<T>(arr: T[], s: number): T {
  return arr[Math.floor(s * arr.length)];
}

function simulateCadeco(accountNumber: string): BankAccountLookup {
  const isCDF = seed(accountNumber, 4) > 0.25; // 75% CDF, 25% USD
  const balance = isCDF
    ? Math.round(seed(accountNumber, 1) * 48_000_000 + 250_000) // 250k–48M CDF
    : Math.round(seed(accountNumber, 2) * 19_500 + 500);         // 500–20k USD

  return {
    exists: true,
    accountHolder: `${pick(PRENOMS, seed(accountNumber, 5))} ${pick(NOMS, seed(accountNumber, 6))}`.toUpperCase(),
    balance,
    currency: isCDF ? 'CDF' : 'USD',
    accountType: pick(TYPES_COMPTE, seed(accountNumber, 7)),
    bankName: 'CADECO',
  };
}

// Format CADECO valide: 00032-XXX-XXXXXXXX-XX (avec ou sans tirets)
function isCadecoNumber(accountNumber: string): boolean {
  const clean = accountNumber.replace(/[\s-]/g, '');
  return /^00032\d{11,}$/.test(clean) || /^00032-\d{3}-\d{8}-\d{2}$/.test(accountNumber.trim());
}

export class MockCoreBankingAdapter implements CoreBankingAdapter {
  async lookupAccount(accountNumber: string): Promise<BankAccountLookup> {
    const normalized = accountNumber.trim();

    // 1. Comptes demo connus
    if (KNOWN_ACCOUNTS[normalized]) return KNOWN_ACCOUNTS[normalized];

    // 2. Tout numéro CADECO (00032) → simulation réaliste
    if (isCadecoNumber(normalized)) return simulateCadeco(normalized);

    // 3. Autres formats → introuvable
    return { exists: false };
  }
}
