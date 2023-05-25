import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Color, StyleEventDetail } from '../../interface';
import type { ToggleChangeEventDetail } from './toggle-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @slot - The label text to associate with the toggle. Use the "labelPlacement" property to control where the label is placed relative to the toggle.
 *
 * @part track - The background track of the toggle.
 * @part handle - The toggle handle, or knob, used to change the checked state.
 */
export declare class Toggle implements ComponentInterface {
  private inputId;
  private gesture?;
  private focusEl?;
  private lastDrag;
  private legacyFormController;
  private inheritedAttributes;
  private toggleTrack?;
  private didLoad;
  private hasLoggedDeprecationWarning;
  el: HTMLIonToggleElement;
  activated: boolean;
  /**
   * The color to use from your application's color palette.
   * Default options are: `"primary"`, `"secondary"`, `"tertiary"`, `"success"`, `"warning"`, `"danger"`, `"light"`, `"medium"`, and `"dark"`.
   * For more information on colors, see [theming](/docs/theming/basics).
   */
  color?: Color;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * If `true`, the toggle is selected.
   */
  checked: boolean;
  /**
   * If `true`, the user cannot interact with the toggle.
   */
  disabled: boolean;
  /**
   * The value of the toggle does not mean if it's checked or not, use the `checked`
   * property for that.
   *
   * The value of a toggle is analogous to the value of a `<input type="checkbox">`,
   * it's only used when the toggle participates in a native `<form>`.
   */
  value?: string | null;
  /**
   * Enables the on/off accessibility switch labels within the toggle.
   */
  enableOnOffLabels: boolean | undefined;
  /**
   * Where to place the label relative to the input.
   * `"start"`: The label will appear to the left of the toggle in LTR and to the right in RTL.
   * `"end"`: The label will appear to the right of the toggle in LTR and to the left in RTL.
   * `"fixed"`: The label has the same behavior as `"start"` except it also has a fixed width. Long text will be truncated with ellipses ("...").
   */
  labelPlacement: 'start' | 'end' | 'fixed';
  /**
   * Set the `legacy` property to `true` to forcibly use the legacy form control markup.
   * Ionic will only opt components in to the modern form markup when they are
   * using either the `aria-label` attribute or the default slot that contains
   * the label text. As a result, the `legacy` property should only be used as
   * an escape hatch when you want to avoid this automatic opt-in behavior.
   * Note that this property will be removed in an upcoming major release
   * of Ionic, and all form components will be opted-in to using the modern form markup.
   */
  legacy?: boolean;
  /**
   * How to pack the label and toggle within a line.
   * `"start"`: The label and toggle will appear on the left in LTR and
   * on the right in RTL.
   * `"end"`: The label and toggle will appear on the right in LTR and
   * on the left in RTL.
   * `"space-between"`: The label and toggle will appear on opposite
   * ends of the line with space between the two elements.
   */
  justify: 'start' | 'end' | 'space-between';
  /**
   * Emitted when the user switches the toggle on or off. Does not emit
   * when programmatically changing the value of the `checked` property.
   */
  ionChange: EventEmitter<ToggleChangeEventDetail>;
  /**
   * Emitted when the toggle has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the toggle loses focus.
   */
  ionBlur: EventEmitter<void>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  disabledChanged(): void;
  private toggleChecked;
  connectedCallback(): Promise<void>;
  componentDidLoad(): void;
  private setupGesture;
  disconnectedCallback(): void;
  componentWillLoad(): void;
  private emitStyle;
  private onStart;
  private onMove;
  private onEnd;
  private getValue;
  private setFocus;
  private onClick;
  private onFocus;
  private onBlur;
  private getSwitchLabelIcon;
  private renderOnOffSwitchLabels;
  private renderToggleControl;
  private get hasLabel();
  render(): any;
  private renderToggle;
  private renderLegacyToggle;
}
