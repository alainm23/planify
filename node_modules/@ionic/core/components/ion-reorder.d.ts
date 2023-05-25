import type { Components, JSX } from "../dist/types/components";

interface IonReorder extends Components.IonReorder, HTMLElement {}
export const IonReorder: {
  prototype: IonReorder;
  new (): IonReorder;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
