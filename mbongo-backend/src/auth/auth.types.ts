export interface AuthenticatedUser {
  id: string;
  name: string;
  phone: string;
  createdAt: Date;
  wallet: {
    id: string;
    balance: number;
    userId: string;
  } | null;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface JwtRequestUser {
  userId: string;
  phone: string;
}

export interface AuthRequestMetadata {
  userAgent?: string;
  ipAddress?: string;
}
