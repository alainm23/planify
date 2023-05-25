import type { Components, JSX } from "../dist/types/components";

interface IonLoading extends Components.IonLoading, HTMLElement {}
export const IonLoading: {
  prototype: IonLoading;
  new (): IonLoading;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
