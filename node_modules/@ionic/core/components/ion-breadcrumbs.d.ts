import type { Components, JSX } from "../dist/types/components";

interface IonBreadcrumbs extends Components.IonBreadcrumbs, HTMLElement {}
export const IonBreadcrumbs: {
  prototype: IonBreadcrumbs;
  new (): IonBreadcrumbs;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
