export declare const ION_CONTENT_ELEMENT_SELECTOR = "ion-content";
export declare const ION_CONTENT_CLASS_SELECTOR = ".ion-content-scroll-host";
export declare const isIonContent: (el: Element) => boolean;
/**
 * Waits for the element host fully initialize before
 * returning the inner scroll element.
 *
 * For `ion-content` the scroll target will be the result
 * of the `getScrollElement` function.
 *
 * For custom implementations it will be the element host
 * or a selector within the host, if supplied through `scrollTarget`.
 */
export declare const getScrollElement: (el: Element) => Promise<HTMLElement>;
/**
 * Queries the element matching the selector for IonContent.
 * See ION_CONTENT_SELECTOR for the selector used.
 */
export declare const findIonContent: (el: Element) => HTMLElement | null;
/**
 * Queries the closest element matching the selector for IonContent.
 */
export declare const findClosestIonContent: (el: Element) => HTMLElement | null;
/**
 * Scrolls to the top of the element. If an `ion-content` is found, it will scroll
 * using the public API `scrollToTop` with a duration.
 */
export declare const scrollToTop: (el: HTMLElement, durationMs: number) => Promise<any>;
/**
 * Scrolls by a specified X/Y distance in the component. If an `ion-content` is found, it will scroll
 * using the public API `scrollByPoint` with a duration.
 */
export declare const scrollByPoint: (el: HTMLElement, x: number, y: number, durationMs: number) => Promise<void>;
/**
 * Prints an error informing developers that an implementation requires an element to be used
 * within either the `ion-content` selector or the `.ion-content-scroll-host` class.
 */
export declare const printIonContentErrorMsg: (el: HTMLElement) => void;
/**
 * Several components in Ionic need to prevent scrolling
 * during a gesture (card modal, range, item sliding, etc).
 * Use this utility to account for ion-content and custom content hosts.
 */
export declare const disableContentScrollY: (contentEl: HTMLElement) => boolean;
export declare const resetContentScrollY: (contentEl: HTMLElement, initialScrollY: boolean) => void;
