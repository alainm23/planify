import type { Components, JSX } from "../dist/types/components";

interface IonCheckbox extends Components.IonCheckbox, HTMLElement {}
export const IonCheckbox: {
  prototype: IonCheckbox;
  new (): IonCheckbox;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
