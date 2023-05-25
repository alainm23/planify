import type { Components, JSX } from "../dist/types/components";

interface IonModal extends Components.IonModal, HTMLElement {}
export const IonModal: {
  prototype: IonModal;
  new (): IonModal;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
