import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AccordionGroupChangeEventDetail } from './accordion-group-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class AccordionGroup implements ComponentInterface {
  el: HTMLIonAccordionGroupElement;
  /**
   * If `true`, all accordions inside of the
   * accordion group will animate when expanding
   * or collapsing.
   */
  animated: boolean;
  /**
   * If `true`, the accordion group can have multiple
   * accordion components expanded at the same time.
   */
  multiple?: boolean;
  /**
   * The value of the accordion group. This controls which
   * accordions are expanded.
   * This should be an array of strings only when `multiple="true"`
   */
  value?: string | string[] | null;
  /**
   * If `true`, the accordion group cannot be interacted with.
   */
  disabled: boolean;
  /**
   * If `true`, the accordion group cannot be interacted with,
   * but does not alter the opacity.
   */
  readonly: boolean;
  /**
   * Describes the expansion behavior for each accordion.
   * Possible values are `"compact"` and `"inset"`.
   * Defaults to `"compact"`.
   */
  expand: 'compact' | 'inset';
  /**
   * Emitted when the value property has changed
   * as a result of a user action such as a click.
   * This event will not emit when programmatically setting
   * the value property.
   */
  ionChange: EventEmitter<AccordionGroupChangeEventDetail>;
  /**
   * Emitted when the value property has changed.
   * This is used to ensure that ion-accordion can respond
   * to any value property changes.
   * @internal
   */
  ionValueChange: EventEmitter<AccordionGroupChangeEventDetail>;
  valueChanged(): void;
  disabledChanged(): Promise<void>;
  readonlyChanged(): Promise<void>;
  onKeydown(ev: KeyboardEvent): Promise<void>;
  componentDidLoad(): Promise<void>;
  /**
   * Sets the value property and emits ionChange.
   * This should only be called when the user interacts
   * with the accordion and not for any update
   * to the value property. The exception is when
   * the app sets the value of a single-select
   * accordion group to an array.
   */
  private setValue;
  /**
   * This method is used to ensure that the value
   * of ion-accordion-group is being set in a valid
   * way. This method should only be called in
   * response to a user generated action.
   * @internal
   */
  requestAccordionToggle(accordionValue: string | undefined, accordionExpand: boolean): Promise<void>;
  private findNextAccordion;
  private findPreviousAccordion;
  /**
   * @internal
   */
  getAccordions(): Promise<HTMLIonAccordionElement[]>;
  render(): any;
}
