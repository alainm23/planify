type HTMLLegacyFormControlElement = HTMLElement & {
  label?: string;
  legacy?: boolean;
};
/**
 * Creates a controller that tracks whether a form control is using the legacy or modern syntax. This should be removed when the legacy form control syntax is removed.
 *
 * @internal
 * @prop el: The Ionic form component to reference
 */
export declare const createLegacyFormController: (el: HTMLLegacyFormControlElement) => LegacyFormController;
export type LegacyFormController = {
  hasLegacyControl: () => boolean;
};
export {};
