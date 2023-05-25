import type { Components, JSX } from "../dist/types/components";

interface IonToolbar extends Components.IonToolbar, HTMLElement {}
export const IonToolbar: {
  prototype: IonToolbar;
  new (): IonToolbar;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
