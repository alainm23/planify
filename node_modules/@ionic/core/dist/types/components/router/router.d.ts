import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AnimationBuilder, BackButtonEvent } from '../../interface';
import type { RouterDirection, RouterEventDetail } from './utils/interface';
export declare class Router implements ComponentInterface {
  private previousPath;
  private busy;
  private state;
  private lastState;
  private waitPromise?;
  el: HTMLElement;
  /**
   * The root path to use when matching URLs. By default, this is set to "/", but you can specify
   * an alternate prefix for all URL paths.
   */
  root: string;
  /**
   * The router can work in two "modes":
   * - With hash: `/index.html#/path/to/page`
   * - Without hash: `/path/to/page`
   *
   * Using one or another might depend in the requirements of your app and/or where it's deployed.
   *
   * Usually "hash-less" navigation works better for SEO and it's more user friendly too, but it might
   * requires additional server-side configuration in order to properly work.
   *
   * On the other side hash-navigation is much easier to deploy, it even works over the file protocol.
   *
   * By default, this property is `true`, change to `false` to allow hash-less URLs.
   */
  useHash: boolean;
  /**
   * Event emitted when the route is about to change
   */
  ionRouteWillChange: EventEmitter<RouterEventDetail>;
  /**
   * Emitted when the route had changed
   */
  ionRouteDidChange: EventEmitter<RouterEventDetail>;
  componentWillLoad(): Promise<void>;
  componentDidLoad(): void;
  protected onPopState(): Promise<boolean>;
  protected onBackButton(ev: BackButtonEvent): void;
  /** @internal */
  canTransition(): Promise<string | boolean>;
  /**
   * Navigate to the specified path.
   *
   * @param path The path to navigate to.
   * @param direction The direction of the animation. Defaults to `"forward"`.
   */
  push(path: string, direction?: RouterDirection, animation?: AnimationBuilder): Promise<boolean>;
  /** Go back to previous page in the window.history. */
  back(): Promise<void>;
  /** @internal */
  printDebug(): Promise<void>;
  /** @internal */
  navChanged(direction: RouterDirection): Promise<boolean>;
  /** This handler gets called when a `ion-route-redirect` component is added to the DOM or if the from or to property of such node changes. */
  private onRedirectChanged;
  /** This handler gets called when a `ion-route` component is added to the DOM or if the from or to property of such node changes. */
  private onRoutesChanged;
  private historyDirection;
  private writeNavStateRoot;
  private safeWriteNavState;
  private lock;
  /**
   * Executes the beforeLeave hook of the source route and the beforeEnter hook of the target route if they exist.
   *
   * When the beforeLeave hook does not return true (to allow navigating) then that value is returned early and the beforeEnter is executed.
   * Otherwise the beforeEnterHook hook of the target route is executed.
   */
  private runGuards;
  private writeNavState;
  private setSegments;
  private getSegments;
  private routeChangeEvent;
}
