import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
import type { ButtonInterface } from '../../utils/element-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part native - The native HTML button element that wraps all child elements.
 * @part icon - The menu button icon (uses ion-icon).
 */
export declare class MenuButton implements ComponentInterface, ButtonInterface {
  private inheritedAttributes;
  el: HTMLIonSegmentElement;
  visible: boolean;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * If `true`, the user cannot interact with the menu button.
   */
  disabled: boolean;
  /**
   * Optional property that maps to a Menu's `menuId` prop. Can also be `start` or `end` for the menu side. This is used to find the correct menu to toggle
   */
  menu?: string;
  /**
   * Automatically hides the menu button when the corresponding menu is not active
   */
  autoHide: boolean;
  /**
   * The type of the button.
   */
  type: 'submit' | 'reset' | 'button';
  componentWillLoad(): void;
  componentDidLoad(): void;
  visibilityChanged(): Promise<void>;
  private onClick;
  render(): any;
}
