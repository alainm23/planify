/**
 * When hardwareBackButton: false in config,
 * we need to make sure we also block the default
 * webview behavior. If we don't then it will be
 * possible for users to navigate backward while
 * an overlay is still open. Additionally, it will
 * give the appearance that the hardwareBackButton
 * config is not working as the page transition
 * will still happen.
 */
export declare const blockHardwareBackButton: () => void;
export declare const startHardwareBackButton: () => void;
export declare const OVERLAY_BACK_BUTTON_PRIORITY = 100;
export declare const MENU_BACK_BUTTON_PRIORITY = 99;
