import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
export declare class InfiniteScroll implements ComponentInterface {
  private thrPx;
  private thrPc;
  private scrollEl?;
  private didFire;
  private isBusy;
  el: HTMLElement;
  isLoading: boolean;
  /**
   * The threshold distance from the bottom
   * of the content to call the `infinite` output event when scrolled.
   * The threshold value can be either a percent, or
   * in pixels. For example, use the value of `10%` for the `infinite`
   * output event to get called when the user has scrolled 10%
   * from the bottom of the page. Use the value `100px` when the
   * scroll is within 100 pixels from the bottom of the page.
   */
  threshold: string;
  protected thresholdChanged(): void;
  /**
   * If `true`, the infinite scroll will be hidden and scroll event listeners
   * will be removed.
   *
   * Set this to true to disable the infinite scroll from actively
   * trying to receive new data while scrolling. This is useful
   * when it is known that there is no more data that can be added, and
   * the infinite scroll is no longer needed.
   */
  disabled: boolean;
  protected disabledChanged(): void;
  /**
   * The position of the infinite scroll element.
   * The value can be either `top` or `bottom`.
   */
  position: 'top' | 'bottom';
  /**
   * Emitted when the scroll reaches
   * the threshold distance. From within your infinite handler,
   * you must call the infinite scroll's `complete()` method when
   * your async operation has completed.
   */
  ionInfinite: EventEmitter<void>;
  connectedCallback(): Promise<void>;
  disconnectedCallback(): void;
  private onScroll;
  /**
   * Call `complete()` within the `ionInfinite` output event handler when
   * your async operation has completed. For example, the `loading`
   * state is while the app is performing an asynchronous operation,
   * such as receiving more data from an AJAX request to add more items
   * to a data list. Once the data has been received and UI updated, you
   * then call this method to signify that the loading has completed.
   * This method will change the infinite scroll's state from `loading`
   * to `enabled`.
   */
  complete(): Promise<void>;
  private canStart;
  private enableScrollEvents;
  render(): any;
}
