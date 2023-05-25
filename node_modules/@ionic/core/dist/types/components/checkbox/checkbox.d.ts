import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { Color, StyleEventDetail } from '../../interface';
import type { CheckboxChangeEventDetail } from './checkbox-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 *
 * @slot - The label text to associate with the checkbox. Use the "labelPlacement" property to control where the label is placed relative to the checkbox.
 *
 * @part container - The container for the checkbox mark.
 * @part mark - The checkmark used to indicate the checked state.
 */
export declare class Checkbox implements ComponentInterface {
  private inputId;
  private focusEl?;
  private legacyFormController;
  private inheritedAttributes;
  private hasLoggedDeprecationWarning;
  el: HTMLIonCheckboxElement;
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
   * If `true`, the checkbox is selected.
   */
  checked: boolean;
  /**
   * If `true`, the checkbox will visually appear as indeterminate.
   */
  indeterminate: boolean;
  /**
   * If `true`, the user cannot interact with the checkbox.
   */
  disabled: boolean;
  /**
   * The value of the checkbox does not mean if it's checked or not, use the `checked`
   * property for that.
   *
   * The value of a checkbox is analogous to the value of an `<input type="checkbox">`,
   * it's only used when the checkbox participates in a native `<form>`.
   */
  value: any | null;
  /**
   * Where to place the label relative to the checkbox.
   * `"start"`: The label will appear to the left of the checkbox in LTR and to the right in RTL.
   * `"end"`: The label will appear to the right of the checkbox in LTR and to the left in RTL.
   * `"fixed"`: The label has the same behavior as `"start"` except it also has a fixed width. Long text will be truncated with ellipses ("...").
   */
  labelPlacement: 'start' | 'end' | 'fixed';
  /**
   * How to pack the label and checkbox within a line.
   * `"start"`: The label and checkbox will appear on the left in LTR and
   * on the right in RTL.
   * `"end"`: The label and checkbox will appear on the right in LTR and
   * on the left in RTL.
   * `"space-between"`: The label and checkbox will appear on opposite
   * ends of the line with space between the two elements.
   */
  justify: 'start' | 'end' | 'space-between';
  /**
   * Set the `legacy` property to `true` to forcibly use the legacy form control markup.
   * Ionic will only opt checkboxes in to the modern form markup when they are
   * using either the `aria-label` attribute or have text in the default slot. As a result,
   * the `legacy` property should only be used as an escape hatch when you want to
   * avoid this automatic opt-in behavior.
   *
   * Note that this property will be removed in an upcoming major release
   * of Ionic, and all form components will be opted-in to using the modern form markup.
   */
  legacy?: boolean;
  /**
   * Emitted when the checked property has changed
   * as a result of a user action such as a click.
   * This event will not emit when programmatically
   * setting the checked property.
   */
  ionChange: EventEmitter<CheckboxChangeEventDetail>;
  /**
   * Emitted when the checkbox has focus.
   */
  ionFocus: EventEmitter<void>;
  /**
   * Emitted when the checkbox loses focus.
   */
  ionBlur: EventEmitter<void>;
  /**
   * Emitted when the styles change.
   * @internal
   */
  ionStyle: EventEmitter<StyleEventDetail>;
  connectedCallback(): void;
  componentWillLoad(): void;
  protected styleChanged(): void;
  private emitStyle;
  private setFocus;
  /**
   * Sets the checked property and emits
   * the ionChange event. Use this to update the
   * checked state in response to user-generated
   * actions such as a click.
   */
  private setChecked;
  private toggleChecked;
  private onFocus;
  private onBlur;
  render(): any;
  private renderCheckbox;
  private renderLegacyCheckbox;
  private getSVGPath;
}
