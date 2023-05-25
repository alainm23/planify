import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class App implements ComponentInterface {
  private focusVisible?;
  el: HTMLElement;
  componentDidLoad(): void;
  /**
   * @internal
   * Used to set focus on an element that uses `ion-focusable`.
   * Do not use this if focusing the element as a result of a keyboard
   * event as the focus utility should handle this for us. This method
   * should be used when we want to programmatically focus an element as
   * a result of another user action. (Ex: We focus the first element
   * inside of a popover when the user presents it, but the popover is not always
   * presented as a result of keyboard action.)
   */
  setFocus(elements: HTMLElement[]): Promise<void>;
  render(): any;
}
