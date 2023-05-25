import type { Components, JSX } from "../dist/types/components";

interface IonItemOption extends Components.IonItemOption, HTMLElement {}
export const IonItemOption: {
  prototype: IonItemOption;
  new (): IonItemOption;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
