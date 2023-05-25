import type { Components, JSX } from "../dist/types/components";

interface IonPickerColumn extends Components.IonPickerColumn, HTMLElement {}
export const IonPickerColumn: {
  prototype: IonPickerColumn;
  new (): IonPickerColumn;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
