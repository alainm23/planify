import type { Components, JSX } from "../dist/types/components";

interface IonMenuButton extends Components.IonMenuButton, HTMLElement {}
export const IonMenuButton: {
  prototype: IonMenuButton;
  new (): IonMenuButton;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
