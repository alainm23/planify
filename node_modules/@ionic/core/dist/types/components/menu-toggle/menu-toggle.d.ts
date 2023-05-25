import type { ComponentInterface } from '../../stencil-public-runtime';
/**
 * @slot - Content is placed inside the toggle to act as the click target.
 */
export declare class MenuToggle implements ComponentInterface {
  visible: boolean;
  /**
   * Optional property that maps to a Menu's `menuId` prop.
   * Can also be `start` or `end` for the menu side.
   * This is used to find the correct menu to toggle.
   *
   * If this property is not used, `ion-menu-toggle` will toggle the
   * first menu that is active.
   */
  menu?: string;
  /**
   * Automatically hides the content when the corresponding menu is not active.
   *
   * By default, it's `true`. Change it to `false` in order to
   * keep `ion-menu-toggle` always visible regardless the state of the menu.
   */
  autoHide: boolean;
  connectedCallback(): void;
  visibilityChanged(): Promise<void>;
  private onClick;
  render(): any;
}
