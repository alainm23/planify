import type { ComponentInterface } from '../../stencil-public-runtime';
export declare class RippleEffect implements ComponentInterface {
  el: HTMLElement;
  /**
   * Sets the type of ripple-effect:
   *
   * - `bounded`: the ripple effect expands from the user's click position
   * - `unbounded`: the ripple effect expands from the center of the button and overflows the container.
   *
   * NOTE: Surfaces for bounded ripples should have the overflow property set to hidden,
   * while surfaces for unbounded ripples should have it set to visible.
   */
  type: 'bounded' | 'unbounded';
  /**
   * Adds the ripple effect to the parent element.
   *
   * @param x The horizontal coordinate of where the ripple should start.
   * @param y The vertical coordinate of where the ripple should start.
   */
  addRipple(x: number, y: number): Promise<() => void>;
  private get unbounded();
  render(): any;
}
