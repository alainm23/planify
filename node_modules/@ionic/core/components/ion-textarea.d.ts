import type { Components, JSX } from "../dist/types/components";

interface IonTextarea extends Components.IonTextarea, HTMLElement {}
export const IonTextarea: {
  prototype: IonTextarea;
  new (): IonTextarea;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
