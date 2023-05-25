import type { Components, JSX } from "../dist/types/components";

interface IonRouterOutlet extends Components.IonRouterOutlet, HTMLElement {}
export const IonRouterOutlet: {
  prototype: IonRouterOutlet;
  new (): IonRouterOutlet;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
