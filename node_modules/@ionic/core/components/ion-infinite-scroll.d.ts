import type { Components, JSX } from "../dist/types/components";

interface IonInfiniteScroll extends Components.IonInfiniteScroll, HTMLElement {}
export const IonInfiniteScroll: {
  prototype: IonInfiniteScroll;
  new (): IonInfiniteScroll;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
