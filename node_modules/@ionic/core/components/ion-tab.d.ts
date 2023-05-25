import type { Components, JSX } from "../dist/types/components";

interface IonTab extends Components.IonTab, HTMLElement {}
export const IonTab: {
  prototype: IonTab;
  new (): IonTab;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
