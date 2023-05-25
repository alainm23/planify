import type { EventEmitter } from '../stencil-public-runtime';
import type { Side } from '../components/menu/menu-interface';
export declare const transitionEndAsync: (el: HTMLElement | null, expectedDuration?: number) => Promise<unknown>;
/**
 * Waits for a component to be ready for
 * both custom element and non-custom element builds.
 * If non-custom element build, el.componentOnReady
 * will be used.
 * For custom element builds, we wait a frame
 * so that the inner contents of the component
 * have a chance to render.
 *
 * Use this utility rather than calling
 * el.componentOnReady yourself.
 */
export declare const componentOnReady: (el: any, callback: any) => void;
/**
 * This functions checks if a Stencil component is using
 * the lazy loaded build of Stencil. Returns `true` if
 * the component is lazy loaded. Returns `false` otherwise.
 */
export declare const hasLazyBuild: (stencilEl: HTMLElement) => boolean;
export type Attributes = {
  [key: string]: any;
};
/**
 * Elements inside of web components sometimes need to inherit global attributes
 * set on the host. For example, the inner input in `ion-input` should inherit
 * the `title` attribute that developers set directly on `ion-input`. This
 * helper function should be called in componentWillLoad and assigned to a variable
 * that is later used in the render function.
 *
 * This does not need to be reactive as changing attributes on the host element
 * does not trigger a re-render.
 */
export declare const inheritAttributes: (el: HTMLElement, attributes?: string[]) => Attributes;
/**
 * Returns an array of aria attributes that should be copied from
 * the shadow host element to a target within the light DOM.
 * @param el The element that the attributes should be copied from.
 * @param ignoreList The list of aria-attributes to ignore reflecting and removing from the host.
 * Use this in instances where we manually specify aria attributes on the `<Host>` element.
 */
export declare const inheritAriaAttributes: (el: HTMLElement, ignoreList?: string[]) => Attributes;
export declare const addEventListener: (el: any, eventName: string, callback: any, opts?: any) => any;
export declare const removeEventListener: (el: any, eventName: string, callback: any, opts?: any) => any;
/**
 * Gets the root context of a shadow dom element
 * On newer browsers this will be the shadowRoot,
 * but for older browser this may just be the
 * element itself.
 *
 * Useful for whenever you need to explicitly
 * do "myElement.shadowRoot!.querySelector(...)".
 */
export declare const getElementRoot: (el: HTMLElement, fallback?: HTMLElement) => HTMLElement | ShadowRoot;
/**
 * Patched version of requestAnimationFrame that avoids ngzone
 * Use only when you know ngzone should not run
 */
export declare const raf: (h: any) => any;
export declare const hasShadowDom: (el: HTMLElement) => boolean;
export declare const findItemLabel: (componentEl: HTMLElement) => HTMLIonLabelElement | null;
export declare const focusElement: (el: HTMLElement) => void;
/**
 * This method is used for Ionic's input components that use Shadow DOM. In
 * order to properly label the inputs to work with screen readers, we need
 * to get the text content of the label outside of the shadow root and pass
 * it to the input inside of the shadow root.
 *
 * Referencing label elements by id from outside of the component is
 * impossible due to the shadow boundary, read more here:
 * https://developer.salesforce.com/blogs/2020/01/accessibility-for-web-components.html
 *
 * @param componentEl The shadow element that needs the aria label
 * @param inputId The unique identifier for the input
 */
export declare const getAriaLabel: (componentEl: HTMLElement, inputId: string) => {
  label: Element | null;
  labelId: string;
  labelText: string | null | undefined;
};
/**
 * This method is used to add a hidden input to a host element that contains
 * a Shadow DOM. It does not add the input inside of the Shadow root which
 * allows it to be picked up inside of forms. It should contain the same
 * values as the host element.
 *
 * @param always Add a hidden input even if the container does not use Shadow
 * @param container The element where the input will be added
 * @param name The name of the input
 * @param value The value of the input
 * @param disabled If true, the input is disabled
 */
export declare const renderHiddenInput: (always: boolean, container: HTMLElement, name: string, value: string | undefined | null, disabled: boolean) => void;
export declare const clamp: (min: number, n: number, max: number) => number;
export declare const assert: (actual: any, reason: string) => void;
export declare const now: (ev: UIEvent) => number;
export declare const pointerCoord: (ev: any) => {
  x: number;
  y: number;
};
/**
 * @hidden
 * Given a side, return if it should be on the end
 * based on the value of dir
 * @param side the side
 * @param isRTL whether the application dir is rtl
 */
export declare const isEndSide: (side: Side) => boolean;
export declare const deferEvent: (event: EventEmitter) => EventEmitter;
export declare const debounceEvent: (event: EventEmitter, wait: number) => EventEmitter;
export declare const debounce: (func: (...args: any[]) => void, wait?: number) => (...args: any[]) => any;
/**
 * Check whether the two string maps are shallow equal.
 *
 * undefined is treated as an empty map.
 *
 * @returns whether the keys are the same and the values are shallow equal.
 */
export declare const shallowEqualStringMap: (map1: {
  [k: string]: any;
} | undefined, map2: {
  [k: string]: any;
} | undefined) => boolean;
