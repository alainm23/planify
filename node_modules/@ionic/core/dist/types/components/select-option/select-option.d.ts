import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class SelectOption implements ComponentInterface {
  private inputId;
  el: HTMLElement;
  /**
   * If `true`, the user cannot interact with the select option. This property does not apply when `interface="action-sheet"` as `ion-action-sheet` does not allow for disabled buttons.
   */
  disabled: boolean;
  /**
   * The text value of the option.
   */
  value?: any | null;
  render(): any;
}
