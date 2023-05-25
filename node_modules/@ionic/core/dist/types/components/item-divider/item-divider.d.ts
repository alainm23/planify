import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @slot - Content is placed between the named slots if provided without a slot.
 * @slot start - Content is placed to the left of the divider text in LTR, and to the right in RTL.
 * @slot end - Content is placed to the right of the divider text in LTR, and to the left in RTL.
 */
export declare class ItemDivider implements ComponentInterface {
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * When it's set to `true`, the item-divider will stay visible when it reaches the top
   * of the viewport until the next `ion-item-divider` replaces it.
   *
   * This feature relies in `position:sticky`:
   * https://caniuse.com/#feat=css-sticky
   */
  sticky: boolean;
  render(): any;
}
