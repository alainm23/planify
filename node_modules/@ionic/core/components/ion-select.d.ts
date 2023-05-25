import type { Components, JSX } from "../dist/types/components";

interface IonSelect extends Components.IonSelect, HTMLElement {}
export const IonSelect: {
  prototype: IonSelect;
  new (): IonSelect;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
