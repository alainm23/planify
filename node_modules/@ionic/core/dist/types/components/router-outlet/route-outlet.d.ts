import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AnimationBuilder, ComponentProps, FrameworkDelegate } from '../../interface';
import type { RouterOutletOptions, SwipeGestureHandler } from '../nav/nav-interface';
import type { RouteID, RouterDirection, RouteWrite, NavOutlet } from '../router/utils/interface';
export declare class RouterOutlet implements ComponentInterface, NavOutlet {
  private activeEl;
  private activeComponent;
  private activeParams;
  private waitPromise?;
  private gesture?;
  private ani?;
  private gestureOrAnimationInProgress;
  el: HTMLElement;
  /**
   * The mode determines which platform styles to use.
   */
  mode: import("../../interface").Mode;
  /** @internal */
  delegate?: FrameworkDelegate;
  /**
   * If `true`, the router-outlet should animate the transition of components.
   */
  animated: boolean;
  /** This property allows to create custom transition using AnimationBuilder functions. */
  animation?: AnimationBuilder;
  /** @internal */
  swipeHandler?: SwipeGestureHandler;
  swipeHandlerChanged(): void;
  /** @internal */
  ionNavWillLoad: EventEmitter<void>;
  /** @internal */
  ionNavWillChange: EventEmitter<void>;
  /** @internal */
  ionNavDidChange: EventEmitter<void>;
  connectedCallback(): Promise<void>;
  componentWillLoad(): void;
  disconnectedCallback(): void;
  /** @internal */
  commit(enteringEl: HTMLElement, leavingEl: HTMLElement | undefined, opts?: RouterOutletOptions): Promise<boolean>;
  /** @internal */
  setRouteId(id: string, params: ComponentProps | undefined, direction: RouterDirection, animation?: AnimationBuilder): Promise<RouteWrite>;
  /** @internal */
  getRouteId(): Promise<RouteID | undefined>;
  private setRoot;
  private transition;
  private lock;
  render(): any;
}
