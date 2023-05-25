import type { Components, JSX } from "../dist/types/components";

interface IonTabButton extends Components.IonTabButton, HTMLElement {}
export const IonTabButton: {
  prototype: IonTabButton;
  new (): IonTabButton;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
