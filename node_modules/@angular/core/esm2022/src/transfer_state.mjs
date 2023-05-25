/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { APP_ID } from './application_tokens';
import { inject } from './di/injector_compatibility';
import { ɵɵdefineInjectable } from './di/interface/defs';
import { getDocument } from './render3/interfaces/document';
export function escapeTransferStateContent(text) {
    const escapedText = {
        '&': '&a;',
        '"': '&q;',
        '\'': '&s;',
        '<': '&l;',
        '>': '&g;',
    };
    return text.replace(/[&"'<>]/g, s => escapedText[s]);
}
export function unescapeTransferStateContent(text) {
    const unescapedText = {
        '&a;': '&',
        '&q;': '"',
        '&s;': '\'',
        '&l;': '<',
        '&g;': '>',
    };
    return text.replace(/&[^;]+;/g, s => unescapedText[s]);
}
/**
 * Create a `StateKey<T>` that can be used to store value of type T with `TransferState`.
 *
 * Example:
 *
 * ```
 * const COUNTER_KEY = makeStateKey<number>('counter');
 * let value = 10;
 *
 * transferState.set(COUNTER_KEY, value);
 * ```
 *
 * @publicApi
 */
export function makeStateKey(key) {
    return key;
}
function initTransferState() {
    const transferState = new TransferState();
    transferState.store = retrieveTransferredState(getDocument(), inject(APP_ID));
    return transferState;
}
/**
 * A key value store that is transferred from the application on the server side to the application
 * on the client side.
 *
 * The `TransferState` is available as an injectable token.
 * On the client, just inject this token using DI and use it, it will be lazily initialized.
 * On the server it's already included if `renderApplication` function is used. Otherwise, import
 * the `ServerTransferStateModule` module to make the `TransferState` available.
 *
 * The values in the store are serialized/deserialized using JSON.stringify/JSON.parse. So only
 * boolean, number, string, null and non-class objects will be serialized and deserialized in a
 * non-lossy manner.
 *
 * @publicApi
 */
class TransferState {
    constructor() {
        /** @internal */
        this.store = {};
        this.onSerializeCallbacks = {};
    }
    /** @nocollapse */
    static { this.ɵprov = 
    /** @pureOrBreakMyCode */ ɵɵdefineInjectable({
        token: TransferState,
        providedIn: 'root',
        factory: initTransferState,
    }); }
    /**
     * Get the value corresponding to a key. Return `defaultValue` if key is not found.
     */
    get(key, defaultValue) {
        return this.store[key] !== undefined ? this.store[key] : defaultValue;
    }
    /**
     * Set the value corresponding to a key.
     */
    set(key, value) {
        this.store[key] = value;
    }
    /**
     * Remove a key from the store.
     */
    remove(key) {
        delete this.store[key];
    }
    /**
     * Test whether a key exists in the store.
     */
    hasKey(key) {
        return this.store.hasOwnProperty(key);
    }
    /**
     * Indicates whether the state is empty.
     */
    get isEmpty() {
        return Object.keys(this.store).length === 0;
    }
    /**
     * Register a callback to provide the value for a key when `toJson` is called.
     */
    onSerialize(key, callback) {
        this.onSerializeCallbacks[key] = callback;
    }
    /**
     * Serialize the current state of the store to JSON.
     */
    toJson() {
        // Call the onSerialize callbacks and put those values into the store.
        for (const key in this.onSerializeCallbacks) {
            if (this.onSerializeCallbacks.hasOwnProperty(key)) {
                try {
                    this.store[key] = this.onSerializeCallbacks[key]();
                }
                catch (e) {
                    console.warn('Exception in onSerialize callback: ', e);
                }
            }
        }
        return JSON.stringify(this.store);
    }
}
export { TransferState };
function retrieveTransferredState(doc, appId) {
    // Locate the script tag with the JSON data transferred from the server.
    // The id of the script tag is set to the Angular appId + 'state'.
    const script = doc.getElementById(appId + '-state');
    let initialState = {};
    if (script && script.textContent) {
        try {
            // Avoid using any here as it triggers lint errors in google3 (any is not allowed).
            initialState = JSON.parse(unescapeTransferStateContent(script.textContent));
        }
        catch (e) {
            console.warn('Exception while restoring TransferState for app ' + appId, e);
        }
    }
    return initialState;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidHJhbnNmZXJfc3RhdGUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy90cmFuc2Zlcl9zdGF0ZS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxPQUFPLEVBQUMsTUFBTSxFQUFDLE1BQU0sc0JBQXNCLENBQUM7QUFDNUMsT0FBTyxFQUFDLE1BQU0sRUFBQyxNQUFNLDZCQUE2QixDQUFDO0FBQ25ELE9BQU8sRUFBQyxrQkFBa0IsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBQ3ZELE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSwrQkFBK0IsQ0FBQztBQUUxRCxNQUFNLFVBQVUsMEJBQTBCLENBQUMsSUFBWTtJQUNyRCxNQUFNLFdBQVcsR0FBMEI7UUFDekMsR0FBRyxFQUFFLEtBQUs7UUFDVixHQUFHLEVBQUUsS0FBSztRQUNWLElBQUksRUFBRSxLQUFLO1FBQ1gsR0FBRyxFQUFFLEtBQUs7UUFDVixHQUFHLEVBQUUsS0FBSztLQUNYLENBQUM7SUFDRixPQUFPLElBQUksQ0FBQyxPQUFPLENBQUMsVUFBVSxFQUFFLENBQUMsQ0FBQyxFQUFFLENBQUMsV0FBVyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUM7QUFDdkQsQ0FBQztBQUVELE1BQU0sVUFBVSw0QkFBNEIsQ0FBQyxJQUFZO0lBQ3ZELE1BQU0sYUFBYSxHQUEwQjtRQUMzQyxLQUFLLEVBQUUsR0FBRztRQUNWLEtBQUssRUFBRSxHQUFHO1FBQ1YsS0FBSyxFQUFFLElBQUk7UUFDWCxLQUFLLEVBQUUsR0FBRztRQUNWLEtBQUssRUFBRSxHQUFHO0tBQ1gsQ0FBQztJQUNGLE9BQU8sSUFBSSxDQUFDLE9BQU8sQ0FBQyxVQUFVLEVBQUUsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxhQUFhLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQztBQUN6RCxDQUFDO0FBcUJEOzs7Ozs7Ozs7Ozs7O0dBYUc7QUFDSCxNQUFN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Q0YsbUZBQW1GO1lBQ25GLFlBQVksR0FBRyxJQUFJLENBQUMsS0FBSyxDQUFDLDRCQUE0QixDQUFDLE1BQU0sQ0FBQyxXQUFXLENBQUMsQ0FBTyxDQUFDO1NBQ25GO1FBQUMsT0FBTyxDQUFDLEVBQUU7WUFDVixPQUFPLENBQUMsSUFBSSxDQUFDLGtEQUFrRCxHQUFHLEtBQUssRUFBRSxDQUFDLENBQUMsQ0FBQztTQUM3RTtLQUNGO0lBQ0QsT0FBTyxZQUFZLENBQUM7QUFDdEIsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0FQUF9JRH0gZnJvbSAnLi9hcHBsaWNhdGlvbl90b2tlbnMnO1xuaW1wb3J0IHtpbmplY3R9IGZyb20gJy4vZGkvaW5qZWN0b3JfY29tcGF0aWJpbGl0eSc7XG5pbXBvcnQge8m1ybVkZWZpbmVJbmplY3RhYmxlfSBmcm9tICcuL2RpL2ludGVyZmFjZS9kZWZzJztcbmltcG9ydCB7Z2V0RG9jdW1lbnR9IGZyb20gJy4vcmVuZGVyMy9pbnRlcmZhY2VzL2RvY3VtZW50JztcblxuZXhwb3J0IGZ1bmN0aW9uIGVzY2FwZVRyYW5zZmVyU3RhdGVDb250ZW50KHRleHQ6IHN0cmluZyk6IHN0cmluZyB7XG4gIGNvbnN0IGVzY2FwZWRUZXh0OiB7W2s6IHN0cmluZ106IHN0cmluZ30gPSB7XG4gICAgJyYnOiAnJmE7JyxcbiAgICAnXCInOiAnJnE7JyxcbiAgICAnXFwnJzogJyZzOycsXG4gICAgJzwnOiAnJmw7JyxcbiAgICAnPic6ICcmZzsnLFxuICB9O1xuICByZXR1cm4gdGV4dC5yZXBsYWNlKC9bJlwiJzw+XS9nLCBzID0+IGVzY2FwZWRUZXh0W3NdKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHVuZXNjYXBlVHJhbnNmZXJTdGF0ZUNvbnRlbnQodGV4dDogc3RyaW5nKTogc3RyaW5nIHtcbiAgY29uc3QgdW5lc2NhcGVkVGV4dDoge1trOiBzdHJpbmddOiBzdHJpbmd9ID0ge1xuICAgICcmYTsnOiAnJicsXG4gICAgJyZxOyc6ICdcIicsXG4gICAgJyZzOyc6ICdcXCcnLFxuICAgICcmbDsnOiAnPCcsXG4gICAgJyZnOyc6ICc+JyxcbiAgfTtcbiAgcmV0dXJuIHRleHQucmVwbGFjZSgvJlteO10rOy9nLCBzID0+IHVuZXNjYXBlZFRleHRbc10pO1xufVxuXG4vKipcbiAqIEEgdHlwZS1zYWZlIGtleSB0byB1c2Ugd2l0aCBgVHJhbnNmZXJTdGF0ZWAuXG4gKlxuICogRXhhbXBsZTpcbiAqXG4gKiBgYGBcbiAqIGNvbnN0IENPVU5URVJfS0VZID0gbWFrZVN0YXRlS2V5PG51bWJlcj4oJ2NvdW50ZXInKTtcbiAqIGxldCB2YWx1ZSA9IDEwO1xuICpcbiAqIHRyYW5zZmVyU3RhdGUuc2V0KENPVU5URVJfS0VZLCB2YWx1ZSk7XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIFN0YXRlS2V5PFQ+ID0gc3RyaW5nJntcbiAgX19ub3RfYV9zdHJpbmc6IG5ldmVyLFxuICBfX3ZhbHVlX3R5cGU/OiBULFxufTtcblxuLyoqXG4gKiBDcmVhdGUgYSBgU3RhdGVLZXk8VD5gIHRoYXQgY2FuIGJlIHVzZWQgdG8gc3RvcmUgdmFsdWUgb2YgdHlwZSBUIHdpdGggYFRyYW5zZmVyU3RhdGVgLlxuICpcbiAqIEV4YW1wbGU6XG4gKlxuICogYGBgXG4gKiBjb25zdCBDT1VOVEVSX0tFWSA9IG1ha2VTdGF0ZUtleTxudW1iZXI+KCdjb3VudGVyJyk7XG4gKiBsZXQgdmFsdWUgPSAxMDtcbiAqXG4gKiB0cmFuc2ZlclN0YXRlLnNldChDT1VOVEVSX0tFWSwgdmFsdWUpO1xuICogYGBgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gbWFrZVN0YXRlS2V5PFQgPSB2b2lkPihrZXk6IHN0cmluZyk6IFN0YXRlS2V5PFQ+IHtcbiAgcmV0dXJuIGtleSBhcyBTdGF0ZUtleTxUPjtcbn1cblxuZnVuY3Rpb24gaW5pdFRyYW5zZmVyU3RhdGUoKSB7XG4gIGNvbnN0IHRyYW5zZmVyU3RhdGUgPSBuZXcgVHJhbnNmZXJTdGF0ZSgpO1xuICB0cmFuc2ZlclN0YXRlLnN0b3JlID0gcmV0cmlldmVUcmFuc2ZlcnJlZFN0YXRlKGdldERvY3VtZW50KCksIGluamVjdChBUFBfSUQpKTtcbiAgcmV0dXJuIHRyYW5zZmVyU3RhdGU7XG59XG5cbi8qKlxuICogQSBrZXkgdmFsdWUgc3RvcmUgdGhhdCBpcyB0cmFuc2ZlcnJlZCBmcm9tIHRoZSBhcHBsaWNhdGlvbiBvbiB0aGUgc2VydmVyIHNpZGUgdG8gdGhlIGFwcGxpY2F0aW9uXG4gKiBvbiB0aGUgY2xpZW50IHNpZGUuXG4gKlxuICogVGhlIGBUcmFuc2ZlclN0YXRlYCBpcyBhdmFpbGFibGUgYXMgYW4gaW5qZWN0YWJsZSB0b2tlbi5cbiAqIE9uIHRoZSBjbGllbnQsIGp1c3QgaW5qZWN0IHRoaXMgdG9rZW4gdXNpbmcgREkgYW5kIHVzZSBpdCwgaXQgd2lsbCBiZSBsYXppbHkgaW5pdGlhbGl6ZWQuXG4gKiBPbiB0aGUgc2VydmVyIGl0J3MgYWxyZWFkeSBpbmNsdWRlZCBpZiBgcmVuZGVyQXBwbGljYXRpb25gIGZ1bmN0aW9uIGlzIHVzZWQuIE90aGVyd2lzZSwgaW1wb3J0XG4gKiB0aGUgYFNlcnZlclRyYW5zZmVyU3RhdGVNb2R1bGVgIG1vZHVsZSB0byBtYWtlIHRoZSBgVHJhbnNmZXJTdGF0ZWAgYXZhaWxhYmxlLlxuICpcbiAqIFRoZSB2YWx1ZXMgaW4gdGhlIHN0b3JlIGFyZSBzZXJpYWxpemVkL2Rlc2VyaWFsaXplZCB1c2luZyBKU09OLnN0cmluZ2lmeS9KU09OLnBhcnNlLiBTbyBvbmx5XG4gKiBib29sZWFuLCBudW1iZXIsIHN0cmluZywgbnVsbCBhbmQgbm9uLWNsYXNzIG9iamVjdHMgd2lsbCBiZSBzZXJpYWxpemVkIGFuZCBkZXNlcmlhbGl6ZWQgaW4gYVxuICogbm9uLWxvc3N5IG1hbm5lci5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBUcmFuc2ZlclN0YXRlIHtcbiAgLyoqIEBub2NvbGxhcHNlICovXG4gIHN0YXRpYyDJtXByb3YgPVxuICAgICAgLyoqIEBwdXJlT3JCcmVha015Q29kZSAqLyDJtcm1ZGVmaW5lSW5qZWN0YWJsZSh7XG4gICAgICAgIHRva2VuOiBUcmFuc2ZlclN0YXRlLFxuICAgICAgICBwcm92aWRlZEluOiAncm9vdCcsXG4gICAgICAgIGZhY3Rvcnk6IGluaXRUcmFuc2ZlclN0YXRlLFxuICAgICAgfSk7XG5cbiAgLyoqIEBpbnRlcm5hbCAqL1xuICBzdG9yZToge1trOiBzdHJpbmddOiB1bmtub3dufHVuZGVmaW5lZH0gPSB7fTtcblxuICBwcml2YXRlIG9uU2VyaWFsaXplQ2FsbGJhY2tzOiB7W2s6IHN0cmluZ106ICgpID0+IHVua25vd24gfCB1bmRlZmluZWR9ID0ge307XG5cbiAgLyoqXG4gICAqIEdldCB0aGUgdmFsdWUgY29ycmVzcG9uZGluZyB0byBhIGtleS4gUmV0dXJuIGBkZWZhdWx0VmFsdWVgIGlmIGtleSBpcyBub3QgZm91bmQuXG4gICAqL1xuICBnZXQ8VD4oa2V5OiBTdGF0ZUtleTxUPiwgZGVmYXVsdFZhbHVlOiBUKTogVCB7XG4gICAgcmV0dXJuIHRoaXMuc3RvcmVba2V5XSAhPT0gdW5kZWZpbmVkID8gdGhpcy5zdG9yZVtrZXldIGFzIFQgOiBkZWZhdWx0VmFsdWU7XG4gIH1cblxuICAvKipcbiAgICogU2V0IHRoZSB2YWx1ZSBjb3JyZXNwb25kaW5nIHRvIGEga2V5LlxuICAgKi9cbiAgc2V0PFQ+KGtleTogU3RhdGVLZXk8VD4sIHZhbHVlOiBUKTogdm9pZCB7XG4gICAgdGhpcy5zdG9yZVtrZXldID0gdmFsdWU7XG4gIH1cblxuICAvKipcbiAgICogUmVtb3ZlIGEga2V5IGZyb20gdGhlIHN0b3JlLlxuICAgKi9cbiAgcmVtb3ZlPFQ+KGtleTogU3RhdGVLZXk8VD4pOiB2b2lkIHtcbiAgICBkZWxldGUgdGhpcy5zdG9yZVtrZXldO1xuICB9XG5cbiAgLyoqXG4gICAqIFRlc3Qgd2hldGhlciBhIGtleSBleGlzdHMgaW4gdGhlIHN0b3JlLlxuICAgKi9cbiAgaGFzS2V5PFQ+KGtleTogU3RhdGVLZXk8VD4pIHtcbiAgICByZXR1cm4gdGhpcy5zdG9yZS5oYXNPd25Qcm9wZXJ0eShrZXkpO1xuICB9XG5cbiAgLyoqXG4gICAqIEluZGljYXRlcyB3aGV0aGVyIHRoZSBzdGF0ZSBpcyBlbXB0eS5cbiAgICovXG4gIGdldCBpc0VtcHR5KCk6IGJvb2xlYW4ge1xuICAgIHJldHVybiBPYmplY3Qua2V5cyh0aGlzLnN0b3JlKS5sZW5ndGggPT09IDA7XG4gIH1cblxuICAvKipcbiAgICogUmVnaXN0ZXIgYSBjYWxsYmFjayB0byBwcm92aWRlIHRoZSB2YWx1ZSBmb3IgYSBrZXkgd2hlbiBgdG9Kc29uYCBpcyBjYWxsZWQuXG4gICAqL1xuICBvblNlcmlhbGl6ZTxUPihrZXk6IFN0YXRlS2V5PFQ+LCBjYWxsYmFjazogKCkgPT4gVCk6IHZvaWQge1xuICAgIHRoaXMub25TZXJpYWxpemVDYWxsYmFja3Nba2V5XSA9IGNhbGxiYWNrO1xuICB9XG5cbiAgLyoqXG4gICAqIFNlcmlhbGl6ZSB0aGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgc3RvcmUgdG8gSlNPTi5cbiAgICovXG4gIHRvSnNvbigpOiBzdHJpbmcge1xuICAgIC8vIENhbGwgdGhlIG9uU2VyaWFsaXplIGNhbGxiYWNrcyBhbmQgcHV0IHRob3NlIHZhbHVlcyBpbnRvIHRoZSBzdG9yZS5cbiAgICBmb3IgKGNvbnN0IGtleSBpbiB0aGlzLm9uU2VyaWFsaXplQ2FsbGJhY2tzKSB7XG4gICAgICBpZiAodGhpcy5vblNlcmlhbGl6ZUNhbGxiYWNrcy5oYXNPd25Qcm9wZXJ0eShrZXkpKSB7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgdGhpcy5zdG9yZVtrZXldID0gdGhpcy5vblNlcmlhbGl6ZUNhbGxiYWNrc1trZXldKCk7XG4gICAgICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgICBjb25zb2xlLndhcm4oJ0V4Y2VwdGlvbiBpbiBvblNlcmlhbGl6ZSBjYWxsYmFjazogJywgZSk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KHRoaXMuc3RvcmUpO1xuICB9XG59XG5cbmZ1bmN0aW9uIHJldHJpZXZlVHJhbnNmZXJyZWRTdGF0ZShkb2M6IERvY3VtZW50LCBhcHBJZDogc3RyaW5nKSB7XG4gIC8vIExvY2F0ZSB0aGUgc2NyaXB0IHRhZyB3aXRoIHRoZSBKU09OIGRhdGEgdHJhbnNmZXJyZWQgZnJvbSB0aGUgc2VydmVyLlxuICAvLyBUaGUgaWQgb2YgdGhlIHNjcmlwdCB0YWcgaXMgc2V0IHRvIHRoZSBBbmd1bGFyIGFwcElkICsgJ3N0YXRlJy5cbiAgY29uc3Qgc2NyaXB0ID0gZG9jLmdldEVsZW1lbnRCeUlkKGFwcElkICsgJy1zdGF0ZScpO1xuICBsZXQgaW5pdGlhbFN0YXRlID0ge307XG4gIGlmIChzY3JpcHQgJiYgc2NyaXB0LnRleHRDb250ZW50KSB7XG4gICAgdHJ5IHtcbiAgICAgIC8vIEF2b2lkIHVzaW5nIGFueSBoZXJlIGFzIGl0IHRyaWdnZXJzIGxpbnQgZXJyb3JzIGluIGdvb2dsZTMgKGFueSBpcyBub3QgYWxsb3dlZCkuXG4gICAgICBpbml0aWFsU3RhdGUgPSBKU09OLnBhcnNlKHVuZXNjYXBlVHJhbnNmZXJTdGF0ZUNvbnRlbnQoc2NyaXB0LnRleHRDb250ZW50KSkgYXMge307XG4gICAgfSBjYXRjaCAoZSkge1xuICAgICAgY29uc29sZS53YXJuKCdFeGNlcHRpb24gd2hpbGUgcmVzdG9yaW5nIFRyYW5zZmVyU3RhdGUgZm9yIGFwcCAnICsgYXBwSWQsIGUpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gaW5pdGlhbFN0YXRlO1xufVxuIl19