import type { Components, JSX } from "../dist/types/components";

interface IonList extends Components.IonList, HTMLElement {}
export const IonList: {
  prototype: IonList;
  new (): IonList;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
