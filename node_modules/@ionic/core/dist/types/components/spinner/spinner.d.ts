import type { ComponentInterface } from '../../stencil-public-runtime';
import type { Color } from '../../interface';
import type { SpinnerTypes } from './spinner-configs';
export declare class Spinner implements ComponentInterface {
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * Duration of the spinner animation in milliseconds. The default varies based on the spinner.
   */
  duration?: number;
  /**
   * The name of the SVG spinner to use. If a name is not provided, the platform's default
   * spinner will be used.
   */
  name?: SpinnerTypes;
  /**
   * If `true`, the spinner's animation will be paused.
   */
  paused: boolean;
  private getName;
  render(): any;
}
