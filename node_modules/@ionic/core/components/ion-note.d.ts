import type { Components, JSX } from "../dist/types/components";

interface IonNote extends Components.IonNote, HTMLElement {}
export const IonNote: {
  prototype: IonNote;
  new (): IonNote;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
