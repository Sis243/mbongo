import { IsBoolean, IsIn, IsOptional, IsUrl } from 'class-validator';

type ChannelMode = 'sandbox' | 'live';

export class UpdateChannelDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsIn(['sandbox', 'live'])
  mode?: ChannelMode;

  @IsOptional()
  @IsUrl({ require_tld: false })
  webhookUrl?: string;
}
