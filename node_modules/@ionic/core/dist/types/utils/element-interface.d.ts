export interface AnchorInterface {
  href: string | undefined;
  target: string | undefined;
  rel: string | undefined;
  download: string | undefined;
}
export interface ButtonInterface {
  type: 'submit' | 'reset' | 'button';
  disabled: boolean;
}
