import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class Buttons implements ComponentInterface {
  /**
   * If true, buttons will disappear when its
   * parent toolbar has fully collapsed if the toolbar
   * is not the first toolbar. If the toolbar is the
   * first toolbar, the buttons will be hidden and will
   * only be shown once all toolbars have fully collapsed.
   *
   * Only applies in `ios` mode with `collapse` set to
   * `true` on `ion-header`.
   *
   * Typically used for [Collapsible Large Titles](https://ionicframework.com/docs/api/title#collapsible-large-titles)
   */
  collapse: boolean;
  render(): any;
}
