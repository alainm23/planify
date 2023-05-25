import type { Components, JSX } from "../dist/types/components";

interface IonGrid extends Components.IonGrid, HTMLElement {}
export const IonGrid: {
  prototype: IonGrid;
  new (): IonGrid;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
