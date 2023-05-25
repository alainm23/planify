import type { Components, JSX } from "../dist/types/components";

interface IonButton extends Components.IonButton, HTMLElement {}
export const IonButton: {
  prototype: IonButton;
  new (): IonButton;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
