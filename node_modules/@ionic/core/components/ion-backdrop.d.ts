import type { Components, JSX } from "../dist/types/components";

interface IonBackdrop extends Components.IonBackdrop, HTMLElement {}
export const IonBackdrop: {
  prototype: IonBackdrop;
  new (): IonBackdrop;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
