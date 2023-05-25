import type { Components, JSX } from "../dist/types/components";

interface IonAlert extends Components.IonAlert, HTMLElement {}
export const IonAlert: {
  prototype: IonAlert;
  new (): IonAlert;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
