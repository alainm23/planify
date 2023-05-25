import type { ComponentInterface } from '../../stencil-public-runtime';
import type { AnimationBuilder, Color } from '../../interface';
import type { RouterDirection } from '../router/utils/interface';
export declare class RouterLink implements ComponentInterface {
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * Contains a URL or a URL fragment that the hyperlink points to.
   * If this property is set, an anchor tag will be rendered.
   */
  href: string | undefined;
  /**
   * Specifies the relationship of the target object to the link object.
   * The value is a space-separated list of [link types](https://developer.mozilla.org/en-US/docs/Web/HTML/Link_types).
   */
  rel: string | undefined;
  /**
   * When using a router, it specifies the transition direction when navigating to
   * another page using `href`.
   */
  routerDirection: RouterDirection;
  /**
   * When using a router, it specifies the transition animation when navigating to
   * another page using `href`.
   */
  routerAnimation: AnimationBuilder | undefined;
  /**
   * Specifies where to display the linked URL.
   * Only applies when an `href` is provided.
   * Special keywords: `"_blank"`, `"_self"`, `"_parent"`, `"_top"`.
   */
  target: string | undefined;
  private onClick;
  render(): any;
}
