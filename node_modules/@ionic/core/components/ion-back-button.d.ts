import type { Components, JSX } from "../dist/types/components";

interface IonBackButton extends Components.IonBackButton, HTMLElement {}
export const IonBackButton: {
  prototype: IonBackButton;
  new (): IonBackButton;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
