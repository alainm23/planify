import type { Components, JSX } from "../dist/types/components";

interface IonSplitPane extends Components.IonSplitPane, HTMLElement {}
export const IonSplitPane: {
  prototype: IonSplitPane;
  new (): IonSplitPane;
};
/**
 * Used to define this component and all nested components recursively.
 */
export const defineCustomElement: () => void;
