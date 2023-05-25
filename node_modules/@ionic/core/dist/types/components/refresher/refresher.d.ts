import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { RefresherEventDetail } from './refresher-interface';
export declare class Refresher implements ComponentInterface {
  private appliedStyles;
  private didStart;
  private progress;
  private scrollEl?;
  private backgroundContentEl?;
  private scrollListenerCallback?;
  private gesture?;
  private overflowStyles?;
  private pointerDown;
  private needsCompletion;
  private didRefresh;
  private lastVelocityY;
  private elementToTransform?;
  private animations;
  private nativeRefresher;
  el: HTMLIonRefresherElement;
  /**
   * The current state which the refresher is in. The refresher's states include:
   *
   * - `inactive` - The refresher is not being pulled down or refreshing and is currently hidden.
   * - `pulling` - The user is actively pulling down the refresher, but has not reached the point yet that if the user lets go, it'll refresh.
   * - `cancelling` - The user pulled down the refresher and let go, but did not pull down far enough to kick off the `refreshing` state. After letting go, the refresher is in the `cancelling` state while it is closing, and will go back to the `inactive` state once closed.
   * - `ready` - The user has pulled down the refresher far enough that if they let go, it'll begin the `refreshing` state.
   * - `refreshing` - The refresher is actively waiting on the async operation to end. Once the refresh handler calls `complete()` it will begin the `completing` state.
   * - `completing` - The `refreshing` state has finished and the refresher is in the way of closing itself. Once closed, the refresher will go back to the `inactive` state.
   */
  private state;
  /**
   * The minimum distance the user must pull down until the
   * refresher will go into the `refreshing` state.
   * Does not apply when the refresher content uses a spinner,
   * enabling the native refresher.
   */
  pullMin: number;
  /**
   * The maximum distance of the pull until the refresher
   * will automatically go into the `refreshing` state.
   * Defaults to the result of `pullMin + 60`.
   * Does not apply when  the refresher content uses a spinner,
   * enabling the native refresher.
   */
  pullMax: number;
  /**
   * Time it takes to close the refresher.
   * Does not apply when the refresher content uses a spinner,
   * enabling the native refresher.
   */
  closeDuration: string;
  /**
   * Time it takes the refresher to snap back to the `refreshing` state.
   * Does not apply when the refresher content uses a spinner,
   * enabling the native refresher.
   */
  snapbackDuration: string;
  /**
   * How much to multiply the pull speed by. To slow the pull animation down,
   * pass a number less than `1`. To speed up the pull, pass a number greater
   * than `1`. The default value is `1` which is equal to the speed of the cursor.
   * If a negative value is passed in, the factor will be `1` instead.
   *
   * For example: If the value passed is `1.2` and the content is dragged by
   * `10` pixels, instead of `10` pixels the content will be pulled by `12` pixels
   * (an increase of 20 percent). If the value passed is `0.8`, the dragged amount
   * will be `8` pixels, less than the amount the cursor has moved.
   *
   * Does not apply when the refresher content uses a spinner,
   * enabling the native refresher.
   */
  pullFactor: number;
  /**
   * If `true`, the refresher will be hidden.
   */
  disabled: boolean;
  disabledChanged(): void;
  /**
   * Emitted when the user lets go of the content and has pulled down
   * further than the `pullMin` or pulls the content down and exceeds the pullMax.
   * Updates the refresher state to `refreshing`. The `complete()` method should be
   * called when the async operation has completed.
   */
  ionRefresh: EventEmitter<RefresherEventDetail>;
  /**
   * Emitted while the user is pulling down the content and exposing the refresher.
   */
  ionPull: EventEmitter<void>;
  /**
   * Emitted when the user begins to start pulling down.
   */
  ionStart: EventEmitter<void>;
  private checkNativeRefresher;
  private destroyNativeRefresher;
  private resetNativeRefresher;
  private setupiOSNativeRefresher;
  private setupMDNativeRefresher;
  private setupNativeRefresher;
  componentDidUpdate(): void;
  connectedCallback(): Promise<void>;
  disconnectedCallback(): void;
  /**
   * Call `complete()` when your async operation has completed.
   * For example, the `refreshing` state is while the app is performing
   * an asynchronous operation, such as receiving more data from an
   * AJAX request. Once the data has been received, you then call this
   * method to signify that the refreshing has completed and to close
   * the refresher. This method also changes the refresher's state from
   * `refreshing` to `completing`.
   */
  complete(): Promise<void>;
  /**
   * Changes the refresher's state from `refreshing` to `cancelling`.
   */
  cancel(): Promise<void>;
  /**
   * A number representing how far down the user has pulled.
   * The number `0` represents the user hasn't pulled down at all. The
   * number `1`, and anything greater than `1`, represents that the user
   * has pulled far enough down that when they let go then the refresh will
   * happen. If they let go and the number is less than `1`, then the
   * refresh will not happen, and the content will return to it's original
   * position.
   */
  getProgress(): Promise<number>;
  private canStart;
  private onStart;
  private onMove;
  private onEnd;
  private beginRefresh;
  private close;
  private setCss;
  private memoizeOverflowStyle;
  private restoreOverflowStyle;
  render(): any;
}
