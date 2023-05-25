import type { Components, JSX } from "../dist/types/components";

interface IonImg extends Components.IonImg, HTMLElement {}
export const IonImg: {
  prototype: IonImg;
  new (): IonImg;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
