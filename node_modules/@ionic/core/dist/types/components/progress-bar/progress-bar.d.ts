import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @part progress - The progress bar that shows the current value when `type` is `"determinate"` and slides back and forth when `type` is `"indeterminate"`.
 * @part stream - The animated circles that appear while buffering. This only shows when `buffer` is set and `type` is `"determinate"`.
 * @part track - The track bar behind the progress bar. If the `buffer` property is set and `type` is `"determinate"` the track will be the
 * width of the `buffer` value.
 */
export declare class ProgressBar implements ComponentInterface {
  /**
   * The state of the progress bar, based on if the time the process takes is known or not.
   * Default options are: `"determinate"` (no animation), `"indeterminate"` (animate from left to right).
   */
  type: 'determinate' | 'indeterminate';
  /**
   * If true, reverse the progress bar direction.
   */
  reversed: boolean;
  /**
   * The value determines how much of the active bar should display when the
   * `type` is `"determinate"`.
   * The value should be between [0, 1].
   */
  value: number;
  /**
   * If the buffer and value are smaller than 1, the buffer circles will show.
   * The buffer should be between [0, 1].
   */
  buffer: number;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  render(): any;
}
