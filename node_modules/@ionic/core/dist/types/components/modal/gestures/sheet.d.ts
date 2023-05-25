import type { Animation } from '../../../interface';
export interface MoveSheetToBreakpointOptions {
  /**
   * The breakpoint value to move the sheet to.
   */
  breakpoint: number;
  /**
   * The offset value between the current breakpoint and the new breakpoint.
   *
   * For breakpoint changes as a result of a touch gesture, this value
   * will be calculated internally.
   *
   * For breakpoint changes as a result of dynamically setting the value,
   * this value should be the difference between the new and old breakpoint.
   * For example:
   * - breakpoints: [0, 0.25, 0.5, 0.75, 1]
   * - Current breakpoint value is 1.
   * - Setting the breakpoint to 0.25.
   * - The offset value should be 0.75 (1 - 0.25).
   */
  breakpointOffset: number;
  /**
   * `true` if the sheet can be transitioned and dismissed off the view.
   */
  canDismiss?: boolean;
}
export declare const createSheetGesture: (baseEl: HTMLIonModalElement, backdropEl: HTMLIonBackdropElement, wrapperEl: HTMLElement, initialBreakpoint: number, backdropBreakpoint: number, animation: Animation, breakpoints: number[] | undefined, getCurrentBreakpoint: () => number, onDismiss: () => void, onBreakpointChange: (breakpoint: number) => void) => {
  gesture: import("../../../interface").Gesture;
  moveSheetToBreakpoint: (options: MoveSheetToBreakpointOptions) => Promise<void>;
};
