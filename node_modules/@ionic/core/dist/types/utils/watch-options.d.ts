export declare const watchForOptions: <T extends HTMLElement>(containerEl: HTMLElement, tagName: string, onChange: (el: T | undefined) => void) => MutationObserver | undefined;
export declare const findCheckedOption: (el: any, tagName: string) => HTMLElement | undefined;
