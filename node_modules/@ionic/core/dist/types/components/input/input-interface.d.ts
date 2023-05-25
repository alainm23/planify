/**
 * Values are converted to strings when emitted which is
 * why we do not have a `number` type here even though the
 * `value` prop accepts a `number` type.
 */
export interface InputChangeEventDetail {
  value?: string | null;
  event?: Event;
}
export interface InputInputEventDetail {
  value?: string | null;
  event?: Event;
}
export interface InputCustomEvent<T = InputChangeEventDetail> extends CustomEvent {
  detail: T;
  target: HTMLIonInputElement;
}
