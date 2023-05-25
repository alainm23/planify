import type { Components, JSX } from "../dist/types/components";

interface IonContent extends Components.IonContent, HTMLElement {}
export const IonContent: {
  prototype: IonContent;
  new (): IonContent;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
