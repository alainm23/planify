import type { ComponentInterface } from '../../stencil-public-runtime';
import type { AnimationBuilder, ComponentProps } from '../../interface';
import type { NavComponent } from '../nav/nav-interface';
import type { RouterDirection } from '../router/utils/interface';
export declare class NavLink implements ComponentInterface {
  el: HTMLElement;
  /**
   * Component to navigate to. Only used if the `routerDirection` is `"forward"` or `"root"`.
   */
  component?: NavComponent;
  /**
   * Data you want to pass to the component as props. Only used if the `"routerDirection"` is `"forward"` or `"root"`.
   */
  componentProps?: ComponentProps;
  /**
   * The transition direction when navigating to another page.
   */
  routerDirection: RouterDirection;
  /**
   * The transition animation when navigating to another page.
   */
  routerAnimation?: AnimationBuilder;
  private onClick;
  render(): any;
}
