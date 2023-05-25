import type { ComponentInterface } from '../../stencil-public-runtime';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Header implements ComponentInterface {
  private scrollEl?;
  private contentScrollCallback?;
  private intersectionObserver?;
  private collapsibleMainHeader?;
  private inheritedAttributes;
  el: HTMLElement;
  /**
   * Describes the scroll effect that will be applied to the header.
   * Only applies in iOS mode.
   *
   * Typically used for [Collapsible Large Titles](https://ionicframework.com/docs/api/title#collapsible-large-titles)
   */
  collapse?: 'condense' | 'fade';
  /**
   * If `true`, the header will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   *
   * Note: In order to scroll content behind the header, the `fullscreen`
   * attribute needs to be set on the content.
   */
  translucent: boolean;
  componentWillLoad(): void;
  componentDidLoad(): void;
  componentDidUpdate(): void;
  disconnectedCallback(): void;
  private checkCollapsibleHeader;
  private setupFadeHeader;
  private destroyCollapsibleHeader;
  private setupCondenseHeader;
  render(): any;
}
