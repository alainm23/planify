import type { Components, JSX } from "../dist/types/components";

interface IonRouteRedirect extends Components.IonRouteRedirect, HTMLElement {}
export const IonRouteRedirect: {
  prototype: IonRouteRedirect;
  new (): IonRouteRedirect;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
