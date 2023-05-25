import type { Components, JSX } from "../dist/types/components";

interface IonTabBar extends Components.IonTabBar, HTMLElement {}
export const IonTabBar: {
  prototype: IonTabBar;
  new (): IonTabBar;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
