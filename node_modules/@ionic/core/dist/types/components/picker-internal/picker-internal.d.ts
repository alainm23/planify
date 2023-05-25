import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { PickerInternalChangeEventDetail } from './picker-internal-interfaces';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 * @internal
 */
export declare class PickerInternal implements ComponentInterface {
  private inputEl?;
  private useInputMode;
  private inputModeColumn?;
  private highlightEl?;
  private actionOnClick?;
  private destroyKeypressListener?;
  private singleColumnSearchTimeout?;
  el: HTMLIonPickerInternalElement;
  ionInputModeChange: EventEmitter<PickerInternalChangeEventDetail>;
  /**
   * When the picker is interacted with
   * we need to prevent touchstart so other
   * gestures do not fire. For example,
   * scrolling on the wheel picker
   * in ion-datetime should not cause
   * a card modal to swipe to close.
   */
  preventTouchStartPropagation(ev: TouchEvent): void;
  componentWillLoad(): void;
  private isInHighlightBounds;
  /**
   * If we are no longer focused
   * on a picker column, then we should
   * exit input mode. An exception is made
   * for the input in the picker since having
   * that focused means we are still in input mode.
   */
  private onFocusOut;
  /**
   * When picker columns receive focus
   * the parent picker needs to determine
   * whether to enter/exit input mode.
   */
  private onFocusIn;
  /**
   * On click we need to run an actionOnClick
   * function that has been set in onPointerDown
   * so that we enter/exit input mode correctly.
   */
  private onClick;
  /**
   * Clicking a column also focuses the column on
   * certain browsers, so we use onPointerDown
   * to tell the onFocusIn function that users
   * are trying to click the column rather than
   * focus the column using the keyboard. When the
   * user completes the click, the onClick function
   * runs and runs the actionOnClick callback.
   */
  private onPointerDown;
  /**
   * Enters input mode to allow
   * for text entry of numeric values.
   * If on mobile, we focus a hidden input
   * field so that the on screen keyboard
   * is brought up. When tabbing using a
   * keyboard, picker columns receive an outline
   * to indicate they are focused. As a result,
   * we should not focus the hidden input as it
   * would cause the outline to go away, preventing
   * users from having any visual indication of which
   * column is focused.
   */
  private enterInputMode;
  /**
   * @internal
   * Exits text entry mode for the picker
   * This method blurs the hidden input
   * and cause the keyboard to dismiss.
   */
  exitInputMode(): Promise<void>;
  private onKeyPress;
  private selectSingleColumn;
  /**
   * Searches a list of column items for a particular
   * value. This is currently used for numeric values.
   * The zeroBehavior can be set to account for leading
   * or trailing zeros when looking at the item text.
   */
  private searchColumn;
  private selectMultiColumn;
  /**
   * Searches the value of the active column
   * to determine which value users are trying
   * to select
   */
  private onInputChange;
  /**
   * Emit ionInputModeChange. Picker columns
   * listen for this event to determine whether
   * or not their column is "active" for text input.
   */
  private emitInputModeChange;
  render(): any;
}
