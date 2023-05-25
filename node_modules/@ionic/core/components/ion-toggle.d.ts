import type { Components, JSX } from "../dist/types/components";

interface IonToggle extends Components.IonToggle, HTMLElement {}
export const IonToggle: {
  prototype: IonToggle;
  new (): IonToggle;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
