import type { Components, JSX } from "../dist/types/components";

interface IonSkeletonText extends Components.IonSkeletonText, HTMLElement {}
export const IonSkeletonText: {
  prototype: IonSkeletonText;
  new (): IonSkeletonText;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
