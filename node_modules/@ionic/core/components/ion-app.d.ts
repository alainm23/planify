import type { Components, JSX } from "../dist/types/components";

interface IonApp extends Components.IonApp, HTMLElement {}
export const IonApp: {
  prototype: IonApp;
  new (): IonApp;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
