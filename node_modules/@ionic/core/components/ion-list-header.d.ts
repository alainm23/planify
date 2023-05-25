import type { Components, JSX } from "../dist/types/components";

interface IonListHeader extends Components.IonListHeader, HTMLElement {}
export const IonListHeader: {
  prototype: IonListHeader;
  new (): IonListHeader;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
