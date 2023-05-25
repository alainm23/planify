import type { Components, JSX } from "../dist/types/components";

interface IonPickerInternal extends Components.IonPickerInternal, HTMLElement {}
export const IonPickerInternal: {
  prototype: IonPickerInternal;
  new (): IonPickerInternal;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
