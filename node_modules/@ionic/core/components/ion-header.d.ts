import type { Components, JSX } from "../dist/types/components";

interface IonHeader extends Components.IonHeader, HTMLElement {}
export const IonHeader: {
  prototype: IonHeader;
  new (): IonHeader;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
