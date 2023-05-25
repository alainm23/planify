import type { Components, JSX } from "../dist/types/components";

interface IonFooter extends Components.IonFooter, HTMLElement {}
export const IonFooter: {
  prototype: IonFooter;
  new (): IonFooter;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
