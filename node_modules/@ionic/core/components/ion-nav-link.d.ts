import type { Components, JSX } from "../dist/types/components";

interface IonNavLink extends Components.IonNavLink, HTMLElement {}
export const IonNavLink: {
  prototype: IonNavLink;
  new (): IonNavLink;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
