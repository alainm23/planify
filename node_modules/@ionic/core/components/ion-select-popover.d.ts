import type { Components, JSX } from "../dist/types/components";

interface IonSelectPopover extends Components.IonSelectPopover, HTMLElement {}
export const IonSelectPopover: {
  prototype: IonSelectPopover;
  new (): IonSelectPopover;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
