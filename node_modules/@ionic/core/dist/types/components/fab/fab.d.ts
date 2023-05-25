import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class Fab implements ComponentInterface {
  el: HTMLElement;
  /**
   * Where to align the fab horizontally in the viewport.
   */
  horizontal?: 'start' | 'end' | 'center';
  /**
   * Where to align the fab vertically in the viewport.
   */
  vertical?: 'top' | 'bottom' | 'center';
  /**
   * If `true`, the fab will display on the edge of the header if
   * `vertical` is `"top"`, and on the edge of the footer if
   * it is `"bottom"`. Should be used with a `fixed` slot.
   */
  edge: boolean;
  /**
   * If `true`, both the `ion-fab-button` and all `ion-fab-list` inside `ion-fab` will become active.
   * That means `ion-fab-button` will become a `close` icon and `ion-fab-list` will become visible.
   */
  activated: boolean;
  activatedChanged(): void;
  componentDidLoad(): void;
  /**
   * Close an active FAB list container.
   */
  close(): Promise<void>;
  private getFab;
  /**
   * Opens/Closes the FAB list container.
   * @internal
   */
  toggle(): Promise<void>;
  render(): any;
}
