import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { NavigationHookCallback } from './route-interface';
export declare class Route implements ComponentInterface {
  /**
   * Relative path that needs to match in order for this route to apply.
   *
   * Accepts paths similar to expressjs so that you can define parameters
   * in the url /foo/:bar where bar would be available in incoming props.
   */
  url: string;
  /**
   * Name of the component to load/select in the navigation outlet (`ion-tabs`, `ion-nav`)
   * when the route matches.
   *
   * The value of this property is not always the tagname of the component to load,
   * in `ion-tabs` it actually refers to the name of the `ion-tab` to select.
   */
  component: string;
  /**
   * A key value `{ 'red': true, 'blue': 'white'}` containing props that should be passed
   * to the defined component when rendered.
   */
  componentProps?: {
    [key: string]: any;
  };
  /**
   * A navigation hook that is fired when the route tries to leave.
   * Returning `true` allows the navigation to proceed, while returning
   * `false` causes it to be cancelled. Returning a `NavigationHookOptions`
   * object causes the router to redirect to the path specified.
   */
  beforeLeave?: NavigationHookCallback;
  /**
   * A navigation hook that is fired when the route tries to enter.
   * Returning `true` allows the navigation to proceed, while returning
   * `false` causes it to be cancelled. Returning a `NavigationHookOptions`
   * object causes the router to redirect to the path specified.
   */
  beforeEnter?: NavigationHookCallback;
  /**
   * Used internally by `ion-router` to know when this route did change.
   */
  ionRouteDataChanged: EventEmitter<any>;
  onUpdate(newValue: any): void;
  onComponentProps(newValue: any, oldValue: any): void;
  connectedCallback(): void;
}
