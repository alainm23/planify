import type { Components, JSX } from "../dist/types/components";

interface IonText extends Components.IonText, HTMLElement {}
export const IonText: {
  prototype: IonText;
  new (): IonText;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
