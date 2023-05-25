import type { Components, JSX } from "../dist/types/components";

interface IonRouterLink extends Components.IonRouterLink, HTMLElement {}
export const IonRouterLink: {
  prototype: IonRouterLink;
  new (): IonRouterLink;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
