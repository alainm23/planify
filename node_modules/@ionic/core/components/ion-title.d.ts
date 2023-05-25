import type { Components, JSX } from "../dist/types/components";

interface IonTitle extends Components.IonTitle, HTMLElement {}
export const IonTitle: {
  prototype: IonTitle;
  new (): IonTitle;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
