import type { Components, JSX } from "../dist/types/components";

interface IonPopover extends Components.IonPopover, HTMLElement {}
export const IonPopover: {
  prototype: IonPopover;
  new (): IonPopover;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
