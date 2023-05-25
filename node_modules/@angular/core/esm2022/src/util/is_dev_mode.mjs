/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { global } from './global';
/**
 * Returns whether Angular is in development mode.
 *
 * By default, this is true, unless `enableProdMode` is invoked prior to calling this method or the
 * application is built using the Angular CLI with the `optimization` option.
 * @see {@link cli/build ng build}
 *
 * @publicApi
 */
export function isDevMode() {
    return typeof ngDevMode === 'undefined' || !!ngDevMode;
}
/**
 * Disable Angular's development mode, which turns off assertions and other
 * checks within the framework.
 *
 * One important assertion this disables verifies that a change detection pass
 * does not result in additional changes to any bindings (also known as
 * unidirectional data flow).
 *
 * Using this method is discouraged as the Angular CLI will set production mode when using the
 * `optimization` option.
 * @see {@link cli/build ng build}
 *
 * @publicApi
 */
export function enableProdMode() {
    // The below check is there so when ngDevMode is set via terser
    // `global['ngDevMode'] = false;` is also dropped.
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        global['ngDevMode'] = false;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaXNfZGV2X21vZGUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy91dGlsL2lzX2Rldl9tb2RlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxNQUFNLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFFaEM7Ozs7Ozs7O0dBUUc7QUFDSCxNQUFNLFVBQVUsU0FBUztJQUN2QixPQUFPLE9BQU8sU0FBUyxLQUFLLFdBQVcsSUFBSSxDQUFDLENBQUMsU0FBUyxDQUFDO0FBQ3pELENBQUM7QUFFRDs7Ozs7Ozs7Ozs7OztHQWFHO0FBQ0gsTUFBTSxVQUFVLGNBQWM7SUFDNUIsK0RBQStEO0lBQy9ELGtEQUFrRDtJQUNsRCxJQUFJLE9BQU8sU0FBUyxLQUFLLFdBQVcsSUFBSSxTQUFTLEVBQUU7UUFDakQsTUFBTSxDQUFDLFdBQVcsQ0FBQyxHQUFHLEtBQUssQ0FBQztLQUM3QjtBQUNILENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtnbG9iYWx9IGZyb20gJy4vZ2xvYmFsJztcblxuLyoqXG4gKiBSZXR1cm5zIHdoZXRoZXIgQW5ndWxhciBpcyBpbiBkZXZlbG9wbWVudCBtb2RlLlxuICpcbiAqIEJ5IGRlZmF1bHQsIHRoaXMgaXMgdHJ1ZSwgdW5sZXNzIGBlbmFibGVQcm9kTW9kZWAgaXMgaW52b2tlZCBwcmlvciB0byBjYWxsaW5nIHRoaXMgbWV0aG9kIG9yIHRoZVxuICogYXBwbGljYXRpb24gaXMgYnVpbHQgdXNpbmcgdGhlIEFuZ3VsYXIgQ0xJIHdpdGggdGhlIGBvcHRpbWl6YXRpb25gIG9wdGlvbi5cbiAqIEBzZWUge0BsaW5rIGNsaS9idWlsZCBuZyBidWlsZH1cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpc0Rldk1vZGUoKTogYm9vbGVhbiB7XG4gIHJldHVybiB0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCAhIW5nRGV2TW9kZTtcbn1cblxuLyoqXG4gKiBEaXNhYmxlIEFuZ3VsYXIncyBkZXZlbG9wbWVudCBtb2RlLCB3aGljaCB0dXJucyBvZmYgYXNzZXJ0aW9ucyBhbmQgb3RoZXJcbiAqIGNoZWNrcyB3aXRoaW4gdGhlIGZyYW1ld29yay5cbiAqXG4gKiBPbmUgaW1wb3J0YW50IGFzc2VydGlvbiB0aGlzIGRpc2FibGVzIHZlcmlmaWVzIHRoYXQgYSBjaGFuZ2UgZGV0ZWN0aW9uIHBhc3NcbiAqIGRvZXMgbm90IHJlc3VsdCBpbiBhZGRpdGlvbmFsIGNoYW5nZXMgdG8gYW55IGJpbmRpbmdzIChhbHNvIGtub3duIGFzXG4gKiB1bmlkaXJlY3Rpb25hbCBkYXRhIGZsb3cpLlxuICpcbiAqIFVzaW5nIHRoaXMgbWV0aG9kIGlzIGRpc2NvdXJhZ2VkIGFzIHRoZSBBbmd1bGFyIENMSSB3aWxsIHNldCBwcm9kdWN0aW9uIG1vZGUgd2hlbiB1c2luZyB0aGVcbiAqIGBvcHRpbWl6YXRpb25gIG9wdGlvbi5cbiAqIEBzZWUge0BsaW5rIGNsaS9idWlsZCBuZyBidWlsZH1cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBlbmFibGVQcm9kTW9kZSgpOiB2b2lkIHtcbiAgLy8gVGhlIGJlbG93IGNoZWNrIGlzIHRoZXJlIHNvIHdoZW4gbmdEZXZNb2RlIGlzIHNldCB2aWEgdGVyc2VyXG4gIC8vIGBnbG9iYWxbJ25nRGV2TW9kZSddID0gZmFsc2U7YCBpcyBhbHNvIGRyb3BwZWQuXG4gIGlmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpIHtcbiAgICBnbG9iYWxbJ25nRGV2TW9kZSddID0gZmFsc2U7XG4gIH1cbn1cbiJdfQ==