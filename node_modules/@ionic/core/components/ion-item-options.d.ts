import type { Components, JSX } from "../dist/types/components";

interface IonItemOptions extends Components.IonItemOptions, HTMLElement {}
export const IonItemOptions: {
  prototype: IonItemOptions;
  new (): IonItemOptions;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
