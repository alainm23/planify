import type { Components, JSX } from "../dist/types/components";

interface IonAccordionGroup extends Components.IonAccordionGroup, HTMLElement {}
export const IonAccordionGroup: {
  prototype: IonAccordionGroup;
  new (): IonAccordionGroup;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
