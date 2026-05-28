export interface SmsAdapter {
  send(to: string, message: string): Promise<void>;
}
