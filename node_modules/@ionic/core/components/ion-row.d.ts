import type { Components, JSX } from "../dist/types/components";

interface IonRow extends Components.IonRow, HTMLElement {}
export const IonRow: {
  prototype: IonRow;
  new (): IonRow;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
