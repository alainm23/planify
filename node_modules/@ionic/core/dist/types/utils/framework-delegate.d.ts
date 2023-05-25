import type { ComponentRef, FrameworkDelegate } from '../interface';
export declare const attachComponent: (delegate: FrameworkDelegate | undefined, container: Element, component?: ComponentRef, cssClasses?: string[], componentProps?: {
  [key: string]: any;
} | undefined, inline?: boolean) => Promise<HTMLElement>;
export declare const detachComponent: (delegate: FrameworkDelegate | undefined, element: HTMLElement | undefined) => Promise<void>;
export declare const CoreDelegate: () => {
  attachViewToDom: (parentElement: HTMLElement, userComponent: any, userComponentProps?: any, cssClasses?: string[]) => Promise<any>;
  removeViewFromDom: () => Promise<void>;
};
