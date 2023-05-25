import type { Components, JSX } from "../dist/types/components";

interface IonThumbnail extends Components.IonThumbnail, HTMLElement {}
export const IonThumbnail: {
  prototype: IonThumbnail;
  new (): IonThumbnail;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
