import type { Components, JSX } from "../dist/types/components";

interface IonInput extends Components.IonInput, HTMLElement {}
export const IonInput: {
  prototype: IonInput;
  new (): IonInput;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
