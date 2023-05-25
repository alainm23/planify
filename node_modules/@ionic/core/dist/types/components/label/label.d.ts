import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Color, StyleEventDetail } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Label implements ComponentInterface {
  private inRange;
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The position determines where and how the label behaves inside an item.
   */
  position?: 'fixed' | 'stacked' | 'floating';
  /**
   * Emitted when the color changes.
   * @internal
   */
  ionColor: EventEmitter<StyleEventDetail>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  noAnimate: boolean;
  componentWillLoad(): void;
  componentDidLoad(): void;
  colorChanged(): void;
  positionChanged(): void;
  private emitColor;
  private emitStyle;
  render(): any;
}
