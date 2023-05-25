import type { Components, JSX } from "../dist/types/components";

interface IonFab extends Components.IonFab, HTMLElement {}
export const IonFab: {
  prototype: IonFab;
  new (): IonFab;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
