export declare const KEYBOARD_DID_OPEN = "ionKeyboardDidShow";
export declare const KEYBOARD_DID_CLOSE = "ionKeyboardDidHide";
/**
 * This is only used for tests
 */
export declare const resetKeyboardAssist: () => void;
export declare const startKeyboardAssist: (win: Window) => void;
export declare const setKeyboardOpen: (win: Window, ev?: any) => void;
export declare const setKeyboardClose: (win: Window) => void;
/**
 * Returns `true` if the `keyboardOpen` flag is not
 * set, the previous visual viewport width equal the current
 * visual viewport width, and if the scaled difference
 * of the previous visual viewport height minus the current
 * visual viewport height is greater than KEYBOARD_THRESHOLD
 *
 * We need to be able to accommodate users who have zooming
 * enabled in their browser (or have zoomed in manually) which
 * is why we take into account the current visual viewport's
 * scale value.
 */
export declare const keyboardDidOpen: () => boolean;
/**
 * Returns `true` if the keyboard is open,
 * but the keyboard did not close
 */
export declare const keyboardDidResize: (win: Window) => boolean;
/**
 * Determine if the keyboard was closed
 * Returns `true` if the `keyboardOpen` flag is set and
 * the current visual viewport height equals the
 * layout viewport height.
 */
export declare const keyboardDidClose: (win: Window) => boolean;
/**
 * Given a window object, create a copy of
 * the current visual and layout viewport states
 * while also preserving the previous visual and
 * layout viewport states
 */
export declare const trackViewportChanges: (win: Window) => void;
/**
 * Creates a deep copy of the visual viewport
 * at a given state
 */
export declare const copyVisualViewport: (visualViewport: any) => any;
