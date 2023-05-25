import type { Components, JSX } from "../dist/types/components";

interface IonSearchbar extends Components.IonSearchbar, HTMLElement {}
export const IonSearchbar: {
  prototype: IonSearchbar;
  new (): IonSearchbar;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
