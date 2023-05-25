export declare const createPointerEvents: (el: Node, pointerDown: any, pointerMove: any, pointerUp: any, options: {
  passive?: boolean;
  capture?: boolean;
}) => {
  enable: (isEnabled?: boolean) => void;
  stop: () => void;
  destroy: () => void;
};
export interface PointerEventsConfig {
  element?: HTMLElement;
  pointerDown: (ev: any) => boolean;
  pointerMove?: (ev: any) => void;
  pointerUp?: (ev: any) => void;
  zone?: boolean;
  capture?: boolean;
  passive?: boolean;
}
