import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
import type { DatetimePresentation } from '../datetime/datetime-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @slot date-target - Content displayed inside of the date button.
 * @slot time-target - Content displayed inside of the time button.
 *
 * @part native - The native HTML button that wraps the slotted text.
 */
export declare class DatetimeButton implements ComponentInterface {
  private datetimeEl;
  private overlayEl;
  private dateTargetEl;
  private timeTargetEl;
  el: HTMLIonDatetimeButtonElement;
  datetimePresentation?: DatetimePresentation;
  dateText?: string;
  timeText?: string;
  datetimeActive: boolean;
  selectedButton?: 'date' | 'time';
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * If `true`, the user cannot interact with the button.
   */
  disabled: boolean;
  /**
   * The ID of the `ion-datetime` instance
   * associated with the datetime button.
   */
  datetime?: string;
  componentWillLoad(): Promise<void>;
  /**
   * Accepts one or more string values and converts
   * them to DatetimeParts. This is done so datetime-button
   * can work with an array internally and not need
   * to keep checking if the datetime value is `string` or `string[]`.
   */
  private getParsedDateValues;
  /**
   * Check the value property on the linked
   * ion-datetime and then format it according
   * to the locale specified on ion-datetime.
   */
  private setDateTimeText;
  /**
   * Waits for the ion-datetime to re-render.
   * This is needed in order to correctly position
   * a popover relative to the trigger element.
   */
  private waitForDatetimeChanges;
  private handleDateClick;
  private handleTimeClick;
  /**
   * If the datetime is presented in an
   * overlay, the datetime and overlay
   * should be appropriately sized.
   * These classes provide default sizing values
   * that developers can customize.
   * The goal is to provide an overlay that is
   * reasonably sized with a datetime that
   * fills the entire container.
   */
  private presentOverlay;
  render(): any;
}
