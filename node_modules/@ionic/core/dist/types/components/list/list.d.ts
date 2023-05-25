import type { ComponentInterface } from '../../stencil-public-runtime';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class List implements ComponentInterface {
  el: HTMLElement;
  /**
   * How the bottom border should be displayed on all items.
   */
  lines?: 'full' | 'inset' | 'none';
  /**
   * If `true`, the list will have margin around it and rounded corners.
   */
  inset: boolean;
  /**
   * If `ion-item-sliding` are used inside the list, this method closes
   * any open sliding item.
   *
   * Returns `true` if an actual `ion-item-sliding` is closed.
   */
  closeSlidingItems(): Promise<boolean>;
  render(): any;
}
