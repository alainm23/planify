import type { Components, JSX } from "../dist/types/components";

interface IonTabs extends Components.IonTabs, HTMLElement {}
export const IonTabs: {
  prototype: IonTabs;
  new (): IonTabs;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
