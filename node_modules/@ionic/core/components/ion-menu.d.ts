import type { Components, JSX } from "../dist/types/components";

interface IonMenu extends Components.IonMenu, HTMLElement {}
export const IonMenu: {
  prototype: IonMenu;
  new (): IonMenu;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
