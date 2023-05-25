/**
 * Scroll padding adds additional padding to the bottom
 * of ion-content so that there is enough scroll space
 * for an input to be scrolled above the keyboard. This
 * is needed in environments where the webview does not
 * resize when the keyboard opens.
 *
 * Example: If an input at the bottom of ion-content is
 * focused, there is no additional scrolling space below
 * it, so the input cannot be scrolled above the keyboard.
 * Scroll padding fixes this by adding padding equal to the
 * height of the keyboard to the bottom of the content.
 *
 * Common environments where this is needed:
 * - Mobile Safari: The keyboard overlays the content
 * - Capacitor/Cordova on iOS: The keyboard overlays the content
 * when the KeyboardResize mode is set to 'none'.
 */
export declare const setScrollPadding: (contentEl: HTMLElement, paddingAmount: number, clearCallback?: () => void) => void;
/**
 * When an input is about to be focused,
 * set a timeout to clear any scroll padding
 * on the content. Note: The clearing
 * is done on a timeout so that if users
 * are moving focus from one input to the next
 * then re-adding scroll padding to the new
 * input with cancel the timeout to clear the
 * scroll padding.
 */
export declare const setClearScrollPaddingListener: (inputEl: HTMLInputElement | HTMLTextAreaElement, contentEl: HTMLElement | null, doneCallback: () => void) => void;
