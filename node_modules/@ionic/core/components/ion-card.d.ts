import type { Components, JSX } from "../dist/types/components";

interface IonCard extends Components.IonCard, HTMLElement {}
export const IonCard: {
  prototype: IonCard;
  new (): IonCard;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
