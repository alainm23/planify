import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class ListHeader implements ComponentInterface {
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * How the bottom border should be displayed on the list header.
   */
  lines?: 'full' | 'inset' | 'none';
  render(): any;
}
