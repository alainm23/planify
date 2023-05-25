import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
import type { BreadcrumbCollapsedClickEventDetail } from '../breadcrumb/breadcrumb-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 */
export declare class Breadcrumbs implements ComponentInterface {
  collapsed: boolean;
  activeChanged: boolean;
  el: HTMLElement;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The maximum number of breadcrumbs to show before collapsing.
   */
  maxItems?: number;
  /**
   * The number of breadcrumbs to show before the collapsed indicator.
   * If `itemsBeforeCollapse` + `itemsAfterCollapse` is greater than `maxItems`,
   * the breadcrumbs will not be collapsed.
   */
  itemsBeforeCollapse: number;
  /**
   * The number of breadcrumbs to show after the collapsed indicator.
   * If `itemsBeforeCollapse` + `itemsAfterCollapse` is greater than `maxItems`,
   * the breadcrumbs will not be collapsed.
   */
  itemsAfterCollapse: number;
  /**
   * Emitted when the collapsed indicator is clicked on.
   */
  ionCollapsedClick: EventEmitter<BreadcrumbCollapsedClickEventDetail>;
  onCollapsedClick(ev: CustomEvent): void;
  maxItemsChanged(): void;
  componentWillLoad(): void;
  private breadcrumbsInit;
  private resetActiveBreadcrumb;
  private setMaxItems;
  private setBreadcrumbSeparator;
  private getBreadcrumbs;
  private slotChanged;
  render(): any;
}
