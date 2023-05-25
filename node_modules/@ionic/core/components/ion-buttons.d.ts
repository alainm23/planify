import type { Components, JSX } from "../dist/types/components";

interface IonButtons extends Components.IonButtons, HTMLElement {}
export const IonButtons: {
  prototype: IonButtons;
  new (): IonButtons;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
