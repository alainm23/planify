import type { Components, JSX } from "../dist/types/components";

interface IonIcon extends Components.IonIcon, HTMLElement {}
export const IonIcon: {
  prototype: IonIcon;
  new (): IonIcon;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
