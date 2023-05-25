import type { AnimationBuilder, ComponentProps, FrameworkDelegate, NavComponentWithProps } from '../../interface';
export declare const VIEW_STATE_NEW = 1;
export declare const VIEW_STATE_ATTACHED = 2;
export declare const VIEW_STATE_DESTROYED = 3;
export declare class ViewController {
  component: any;
  params: ComponentProps | undefined;
  state: number;
  nav?: any;
  element?: HTMLElement;
  delegate?: FrameworkDelegate;
  animationBuilder?: AnimationBuilder;
  constructor(component: any, params: ComponentProps | undefined);
  init(container: HTMLElement): Promise<void>;
  /**
   * DOM WRITE
   */
  _destroy(): void;
}
export declare const matches: (view: ViewController | undefined, id: string, params: ComponentProps | undefined) => view is ViewController;
export declare const convertToView: (page: any, params: ComponentProps | undefined) => ViewController | null;
export declare const convertToViews: (pages: NavComponentWithProps[]) => ViewController[];
