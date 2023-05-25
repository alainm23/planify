import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AnimationBuilder, Color } from '../../interface';
import type { RouterDirection } from '../router/utils/interface';
import type { BreadcrumbCollapsedClickEventDetail } from './breadcrumb-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part native - The native HTML anchor or div element that wraps all child elements.
 * @part separator - The separator element between each breadcrumb.
 * @part collapsed-indicator - The indicator element that shows the breadcrumbs are collapsed.
 */
export declare class Breadcrumb implements ComponentInterface {
  private inheritedAttributes;
  private collapsedRef?;
  /** @internal */
  collapsed: boolean;
  /** @internal */
  last: boolean;
  /** @internal */
  showCollapsedIndicator: boolean;
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * If `true`, the breadcrumb will take on a different look to show that
   * it is the currently active breadcrumb. Defaults to `true` for the
   * last breadcrumb if it is not set on any.
   */
  active: boolean;
  /**
   * If `true`, the user cannot interact with the breadcrumb.
   */
  disabled: boolean;
  /**
   * This attribute instructs browsers to download a URL instead of navigating to
   * it, so the user will be prompted to save it as a local file. If the attribute
   * has a value, it is used as the pre-filled file name in the Save prompt
   * (the user can still change the file name if they want).
   */
  download: string | undefined;
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
   * If true, show a separator between this breadcrumb and the next.
   * Defaults to `true` for all breadcrumbs except the last.
   */
  separator?: boolean | undefined;
  /**
   * Specifies where to display the linked URL.
   * Only applies when an `href` is provided.
   * Special keywords: `"_blank"`, `"_self"`, `"_parent"`, `"_top"`.
   */
  target: string | undefined;
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
   * Emitted when the breadcrumb has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the breadcrumb loses focus.
   */
  ionBlur: EventEmitter<void>;
  /**
   * Emitted when the collapsed indicator is clicked on.
   * `ion-breadcrumbs` will listen for this and emit ionCollapsedClick.
   * Normally we could just emit this as `ionCollapsedClick`
   * and let the event bubble to `ion-breadcrumbs`,
   * but if the event custom event is not set on `ion-breadcrumbs`,
   * TypeScript will throw an error in user applications.
   * @internal
   */
  collapsedClick: EventEmitter<BreadcrumbCollapsedClickEventDetail>;
  componentWillLoad(): void;
  private isClickable;
  private onFocus;
  private onBlur;
  private collapsedIndicatorClick;
  render(): any;
}
