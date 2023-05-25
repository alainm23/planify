import type { Components, JSX } from "../dist/types/components";

interface IonProgressBar extends Components.IonProgressBar, HTMLElement {}
export const IonProgressBar: {
  prototype: IonProgressBar;
  new (): IonProgressBar;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
