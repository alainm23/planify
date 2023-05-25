import type { Components, JSX } from "../dist/types/components";

interface IonItemDivider extends Components.IonItemDivider, HTMLElement {}
export const IonItemDivider: {
  prototype: IonItemDivider;
  new (): IonItemDivider;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
