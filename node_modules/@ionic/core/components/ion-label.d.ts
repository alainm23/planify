import type { Components, JSX } from "../dist/types/components";

interface IonLabel extends Components.IonLabel, HTMLElement {}
export const IonLabel: {
  prototype: IonLabel;
  new (): IonLabel;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
