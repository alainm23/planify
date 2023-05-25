import type { Components, JSX } from "../dist/types/components";

interface IonReorderGroup extends Components.IonReorderGroup, HTMLElement {}
export const IonReorderGroup: {
  prototype: IonReorderGroup;
  new (): IonReorderGroup;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
