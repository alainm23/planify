import type { Components, JSX } from "../dist/types/components";

interface IonRoute extends Components.IonRoute, HTMLElement {}
export const IonRoute: {
  prototype: IonRoute;
  new (): IonRoute;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
