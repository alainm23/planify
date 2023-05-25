import type { Components, JSX } from "../dist/types/components";

interface IonAccordion extends Components.IonAccordion, HTMLElement {}
export const IonAccordion: {
  prototype: IonAccordion;
  new (): IonAccordion;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
