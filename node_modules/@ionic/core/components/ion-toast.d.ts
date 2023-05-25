import type { Components, JSX } from "../dist/types/components";

interface IonToast extends Components.IonToast, HTMLElement {}
export const IonToast: {
  prototype: IonToast;
  new (): IonToast;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
