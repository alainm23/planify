import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class FabList implements ComponentInterface {
  el: HTMLIonFabElement;
  /**
   * If `true`, the fab list will show all fab buttons in the list.
   */
  activated: boolean;
  protected activatedChanged(activated: boolean): void;
  /**
   * The side the fab list will show on relative to the main fab button.
   */
  side: 'start' | 'end' | 'top' | 'bottom';
  render(): any;
}
