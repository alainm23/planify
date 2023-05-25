import type { Components, JSX } from "../dist/types/components";

interface IonSegment extends Components.IonSegment, HTMLElement {}
export const IonSegment: {
  prototype: IonSegment;
  new (): IonSegment;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
