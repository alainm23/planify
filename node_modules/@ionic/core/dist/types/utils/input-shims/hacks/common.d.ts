export declare const relocateInput: (componentEl: HTMLElement, inputEl: HTMLInputElement | HTMLTextAreaElement, shouldRelocate: boolean, inputRelativeY?: number, disabledClonedInput?: boolean) => void;
export declare const isFocused: (input: HTMLInputElement | HTMLTextAreaElement) => boolean;
/**
 * Factoring in 50px gives us some room
 * in case the keyboard shows password/autofill bars
 * asynchronously.
 */
export declare const SCROLL_AMOUNT_PADDING = 50;
