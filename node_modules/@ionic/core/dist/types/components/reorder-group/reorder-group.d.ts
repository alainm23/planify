import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { ItemReorderEventDetail } from './reorder-group-interface';
declare const enum ReorderGroupState {
  Idle = 0,
  Active = 1,
  Complete = 2
}
export declare class ReorderGroup implements ComponentInterface {
  private selectedItemEl?;
  private selectedItemHeight;
  private lastToIndex;
  private cachedHeights;
  private scrollEl?;
  private gesture?;
  private scrollElTop;
  private scrollElBottom;
  private scrollElInitial;
  private containerTop;
  private containerBottom;
  state: ReorderGroupState;
  el: HTMLElement;
  /**
   * If `true`, the reorder will be hidden.
   */
  disabled: boolean;
  disabledChanged(): void;
  /**
   * Event that needs to be listened to in order to complete the reorder action.
   * Once the event has been emitted, the `complete()` method then needs
   * to be called in order to finalize the reorder action.
   */
  ionItemReorder: EventEmitter<ItemReorderEventDetail>;
  connectedCallback(): Promise<void>;
  disconnectedCallback(): void;
  /**
   * Completes the reorder operation. Must be called by the `ionItemReorder` event.
   *
   * If a list of items is passed, the list will be reordered and returned in the
   * proper order.
   *
   * If no parameters are passed or if `true` is passed in, the reorder will complete
   * and the item will remain in the position it was dragged to. If `false` is passed,
   * the reorder will complete and the item will bounce back to its original position.
   *
   * @param listOrReorder A list of items to be sorted and returned in the new order or a
   * boolean of whether or not the reorder should reposition the item.
   */
  complete(listOrReorder?: boolean | any[]): Promise<any>;
  private canStart;
  private onStart;
  private onMove;
  private onEnd;
  private completeReorder;
  private itemIndexForTop;
  /********* DOM WRITE ********* */
  private reorderMove;
  private autoscroll;
  render(): any;
}
export {};
