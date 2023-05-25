import type { Components, JSX } from "../dist/types/components";

interface IonBadge extends Components.IonBadge, HTMLElement {}
export const IonBadge: {
  prototype: IonBadge;
  new (): IonBadge;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
