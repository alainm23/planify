import type { Components, JSX } from "../dist/types/components";

interface IonCardContent extends Components.IonCardContent, HTMLElement {}
export const IonCardContent: {
  prototype: IonCardContent;
  new (): IonCardContent;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
