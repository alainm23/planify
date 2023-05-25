import type { ComponentInterface } from '../../stencil-public-runtime';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Footer implements ComponentInterface {
  private scrollEl?;
  private contentScrollCallback?;
  private keyboardCtrl;
  private keyboardVisible;
  el: HTMLIonFooterElement;
  /**
   * Describes the scroll effect that will be applied to the footer.
   * Only applies in iOS mode.
   */
  collapse?: 'fade';
  /**
   * If `true`, the footer will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   *
   * Note: In order to scroll content behind the footer, the `fullscreen`
   * attribute needs to be set on the content.
   */
  translucent: boolean;
  componentDidLoad(): void;
  componentDidUpdate(): void;
  connectedCallback(): void;
  disconnectedCallback(): void;
  private checkCollapsibleFooter;
  private setupFadeFooter;
  private destroyCollapsibleFooter;
  render(): any;
}
