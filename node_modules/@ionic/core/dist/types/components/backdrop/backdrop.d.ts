import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
export declare class Backdrop implements ComponentInterface {
  private blocker;
  /**
   * If `true`, the backdrop will be visible.
   */
  visible: boolean;
  /**
   * If `true`, the backdrop will can be clicked and will emit the `ionBackdropTap` event.
   */
  tappable: boolean;
  /**
   * If `true`, the backdrop will stop propagation on tap.
   */
  stopPropagation: boolean;
  /**
   * Emitted when the backdrop is tapped.
   */
  ionBackdropTap: EventEmitter<void>;
  connectedCallback(): void;
  disconnectedCallback(): void;
  protected onMouseDown(ev: TouchEvent): void;
  private emitTap;
  render(): any;
}
