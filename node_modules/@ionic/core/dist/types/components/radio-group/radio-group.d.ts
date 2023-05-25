import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { RadioGroupChangeEventDetail } from './radio-group-interface';
export declare class RadioGroup implements ComponentInterface {
  private inputId;
  private labelId;
  private label?;
  el: HTMLElement;
  /**
   * If `true`, the radios can be deselected.
   */
  allowEmptySelection: boolean;
  /**
   * The name of the control, which is submitted with the form data.
   */
  name: string;
  /**
   * the value of the radio group.
   */
  value?: any | null;
  valueChanged(value: any | undefined): void;
  /**
   * Emitted when the value has changed.
   */
  ionChange: EventEmitter<RadioGroupChangeEventDetail>;
  /**
   * Emitted when the `value` property has changed.
   * This is used to ensure that `ion-radio` can respond
   * to any value property changes from the group.
   *
   * @internal
   */
  ionValueChange: EventEmitter<RadioGroupChangeEventDetail>;
  componentDidLoad(): void;
  private setRadioTabindex;
  connectedCallback(): Promise<void>;
  private getRadios;
  /**
   * Emits an `ionChange` event.
   *
   * This API should be called for user committed changes.
   * This API should not be used for external value changes.
   */
  private emitValueChange;
  private onClick;
  onKeydown(ev: KeyboardEvent): void;
  render(): any;
}
