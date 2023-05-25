import type { Components, JSX } from "../dist/types/components";

interface IonRange extends Components.IonRange, HTMLElement {}
export const IonRange: {
  prototype: IonRange;
  new (): IonRange;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
