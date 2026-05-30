import { reviewKycSchema } from './review-kyc.dto';

describe('ReviewKycDto', () => {
  it('accepts approval without rejection reason', () => {
    const result = reviewKycSchema.safeParse({ status: 'APPROVED' });

    expect(result.success).toBe(true);
  });

  it('requires a rejection reason when rejecting', () => {
    const result = reviewKycSchema.safeParse({ status: 'REJECTED' });

    expect(result.success).toBe(false);
  });

  it('trims and validates the rejection reason', () => {
    const result = reviewKycSchema.safeParse({
      status: 'REJECTED',
      rejectionReason: '  Document illisible  ',
    });

    expect(result.success).toBe(true);

    if (result.success && result.data.status === 'REJECTED') {
      expect(result.data.rejectionReason).toBe('Document illisible');
    }
  });
});
