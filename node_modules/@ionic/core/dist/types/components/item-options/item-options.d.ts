import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Side } from '../menu/menu-interface';
export declare class ItemOptions implements ComponentInterface {
  el: HTMLElement;
  /**
   * The side the option button should be on. Possible values: `"start"` and `"end"`. If you have multiple `ion-item-options`, a side must be provided for each.
   *
   */
  side: Side;
  /**
   * Emitted when the item has been fully swiped.
   */
  ionSwipe: EventEmitter<any>;
  /** @internal */
  fireSwipeEvent(): Promise<void>;
  render(): any;
}
