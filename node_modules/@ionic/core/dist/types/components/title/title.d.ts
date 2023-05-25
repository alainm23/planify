import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Color, StyleEventDetail } from '../../interface';
export declare class ToolbarTitle implements ComponentInterface {
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The size of the toolbar title.
   */
  size?: 'large' | 'small';
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  protected sizeChanged(): void;
  connectedCallback(): void;
  private emitStyle;
  private getSize;
  render(): any;
}
