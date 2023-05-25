import type { Components, JSX } from "../dist/types/components";

interface IonActionSheet extends Components.IonActionSheet, HTMLElement {}
export const IonActionSheet: {
  prototype: IonActionSheet;
  new (): IonActionSheet;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
