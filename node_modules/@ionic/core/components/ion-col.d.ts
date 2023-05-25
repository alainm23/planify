import type { Components, JSX } from "../dist/types/components";

interface IonCol extends Components.IonCol, HTMLElement {}
export const IonCol: {
  prototype: IonCol;
  new (): IonCol;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
