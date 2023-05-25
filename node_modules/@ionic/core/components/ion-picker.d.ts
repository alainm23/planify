import type { Components, JSX } from "../dist/types/components";

interface IonPicker extends Components.IonPicker, HTMLElement {}
export const IonPicker: {
  prototype: IonPicker;
  new (): IonPicker;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
