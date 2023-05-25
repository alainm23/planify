import type { Components, JSX } from "../dist/types/components";

interface IonCardHeader extends Components.IonCardHeader, HTMLElement {}
export const IonCardHeader: {
  prototype: IonCardHeader;
  new (): IonCardHeader;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
