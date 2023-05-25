import type { Components, JSX } from "../dist/types/components";

interface IonItem extends Components.IonItem, HTMLElement {}
export const IonItem: {
  prototype: IonItem;
  new (): IonItem;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
