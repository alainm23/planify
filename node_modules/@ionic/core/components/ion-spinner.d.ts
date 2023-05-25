import type { Components, JSX } from "../dist/types/components";

interface IonSpinner extends Components.IonSpinner, HTMLElement {}
export const IonSpinner: {
  prototype: IonSpinner;
  new (): IonSpinner;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
