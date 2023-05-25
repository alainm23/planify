import type { Components, JSX } from "../dist/types/components";

interface IonRouter extends Components.IonRouter, HTMLElement {}
export const IonRouter: {
  prototype: IonRouter;
  new (): IonRouter;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
