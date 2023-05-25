import type { Components, JSX } from "../dist/types/components";

interface IonFabButton extends Components.IonFabButton, HTMLElement {}
export const IonFabButton: {
  prototype: IonFabButton;
  new (): IonFabButton;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
