import type { Components, JSX } from "../dist/types/components";

interface IonSelectOption extends Components.IonSelectOption, HTMLElement {}
export const IonSelectOption: {
  prototype: IonSelectOption;
  new (): IonSelectOption;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
