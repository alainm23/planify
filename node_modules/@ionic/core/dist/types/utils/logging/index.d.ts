/**
 * Logs a warning to the console with an Ionic prefix
 * to indicate the library that is warning the developer.
 *
 * @param message - The string message to be logged to the console.
 */
export declare const printIonWarning: (message: string, ...params: any[]) => void;
export declare const printIonError: (message: string, ...params: any) => void;
/**
 * Prints an error informing developers that an implementation requires an element to be used
 * within a specific selector.
 *
 * @param el The web component element this is requiring the element.
 * @param targetSelectors The selector or selectors that were not found.
 */
export declare const printRequiredElementError: (el: HTMLElement, ...targetSelectors: string[]) => void;
