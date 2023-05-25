/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
/**
 * A token used to manipulate and access values stored in `HttpContext`.
 *
 * @publicApi
 */
export class HttpContextToken {
    constructor(defaultValue) {
        this.defaultValue = defaultValue;
    }
}
/**
 * Http context stores arbitrary user defined values and ensures type safety without
 * actually knowing the types. It is backed by a `Map` and guarantees that keys do not clash.
 *
 * This context is mutable and is shared between cloned requests unless explicitly specified.
 *
 * @usageNotes
 *
 * ### Usage Example
 *
 * ```typescript
 * // inside cache.interceptors.ts
 * export const IS_CACHE_ENABLED = new HttpContextToken<boolean>(() => false);
 *
 * export class CacheInterceptor implements HttpInterceptor {
 *
 *   intercept(req: HttpRequest<any>, delegate: HttpHandler): Observable<HttpEvent<any>> {
 *     if (req.context.get(IS_CACHE_ENABLED) === true) {
 *       return ...;
 *     }
 *     return delegate.handle(req);
 *   }
 * }
 *
 * // inside a service
 *
 * this.httpClient.get('/api/weather', {
 *   context: new HttpContext().set(IS_CACHE_ENABLED, true)
 * }).subscribe(...);
 * ```
 *
 * @publicApi
 */
export class HttpContext {
    constructor() {
        this.map = new Map();
    }
    /**
     * Store a value in the context. If a value is already present it will be overwritten.
     *
     * @param token The reference to an instance of `HttpContextToken`.
     * @param value The value to store.
     *
     * @returns A reference to itself for easy chaining.
     */
    set(token, value) {
        this.map.set(token, value);
        return this;
    }
    /**
     * Retrieve the value associated with the given token.
     *
     * @param token The reference to an instance of `HttpContextToken`.
     *
     * @returns The stored value or default if one is defined.
     */
    get(token) {
        if (!this.map.has(token)) {
            this.map.set(token, token.defaultValue());
        }
        return this.map.get(token);
    }
    /**
     * Delete the value associated with the given token.
     *
     * @param token The reference to an instance of `HttpContextToken`.
     *
     * @returns A reference to itself for easy chaining.
     */
    delete(token) {
        this.map.delete(token);
        return this;
    }
    /**
     * Checks for existence of a given token.
     *
     * @param token The reference to an instance of `HttpContextToken`.
     *
     * @returns True if the token exists, false otherwise.
     */
    has(token) {
        return this.map.has(token);
    }
    /**
     * @returns a list of tokens currently stored in the context.
     */
    keys() {
        return this.map.keys();
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29udGV4dC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvbW1vbi9odHRwL3NyYy9jb250ZXh0LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVIOzs7O0dBSUc7QUFDSCxNQUFNLE9BQU8sZ0JBQWdCO0lBQzNCLFlBQTRCLFlBQXFCO1FBQXJCLGlCQUFZLEdBQVosWUFBWSxDQUFTO0lBQUcsQ0FBQztDQUN0RDtBQUVEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQWdDRztBQUNILE1BQU0sT0FBTyxXQUFXO0lBQXhCO1FBQ21CLFFBQUcsR0FBRyxJQUFJLEdBQUcsRUFBc0MsQ0FBQztJQTBEdkUsQ0FBQztJQXhEQzs7Ozs7OztPQU9HO0lBQ0gsR0FBRyxDQUFJLEtBQTBCLEVBQUUsS0FBUTtRQUN6QyxJQUFJLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLENBQUM7UUFDM0IsT0FBTyxJQUFJLENBQUM7SUFDZCxDQUFDO0lBRUQ7Ozs7OztPQU1HO0lBQ0gsR0FBRyxDQUFJLEtBQTBCO1FBQy9CLElBQUksQ0FBQyxJQUFJLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsRUFBRTtZQUN4QixJQUFJLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLFlBQVksRUFBRSxDQUFDLENBQUM7U0FDM0M7UUFDRCxPQUFPLElBQUksQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLEtBQUssQ0FBTSxDQUFDO0lBQ2xDLENBQUM7SUFFRDs7Ozs7O09BTUc7SUFDSCxNQUFNLENBQUMsS0FBZ0M7UUFDckMsSUFBSSxDQUFDLEdBQUcsQ0FBQyxNQUFNLENBQUMsS0FBSyxDQUFDLENBQUM7UUFDdkIsT0FBTyxJQUFJLENBQUM7SUFDZCxDQUFDO0lBRUQ7Ozs7OztPQU1HO0lBQ0gsR0FBRyxDQUFDLEtBQWdDO1FBQ2xDLE9BQU8sSUFBSSxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsS0FBSyxDQUFDLENBQUM7SUFDN0IsQ0FBQztJQUVEOztPQUVHO0lBQ0gsSUFBSTtRQUNGLE9BQU8sSUFBSSxDQUFDLEdBQUcsQ0FBQyxJQUFJLEVBQUUsQ0FBQztJQUN6QixDQUFDO0NBQ0YiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuLyoqXG4gKiBBIHRva2VuIHVzZWQgdG8gbWFuaXB1bGF0ZSBhbmQgYWNjZXNzIHZhbHVlcyBzdG9yZWQgaW4gYEh0dHBDb250ZXh0YC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBIdHRwQ29udGV4dFRva2VuPFQ+IHtcbiAgY29uc3RydWN0b3IocHVibGljIHJlYWRvbmx5IGRlZmF1bHRWYWx1ZTogKCkgPT4gVCkge31cbn1cblxuLyoqXG4gKiBIdHRwIGNvbnRleHQgc3RvcmVzIGFyYml0cmFyeSB1c2VyIGRlZmluZWQgdmFsdWVzIGFuZCBlbnN1cmVzIHR5cGUgc2FmZXR5IHdpdGhvdXRcbiAqIGFjdHVhbGx5IGtub3dpbmcgdGhlIHR5cGVzLiBJdCBpcyBiYWNrZWQgYnkgYSBgTWFwYCBhbmQgZ3VhcmFudGVlcyB0aGF0IGtleXMgZG8gbm90IGNsYXNoLlxuICpcbiAqIFRoaXMgY29udGV4dCBpcyBtdXRhYmxlIGFuZCBpcyBzaGFyZWQgYmV0d2VlbiBjbG9uZWQgcmVxdWVzdHMgdW5sZXNzIGV4cGxpY2l0bHkgc3BlY2lmaWVkLlxuICpcbiAqIEB1c2FnZU5vdGVzXG4gKlxuICogIyMjIFVzYWdlIEV4YW1wbGVcbiAqXG4gKiBgYGB0eXBlc2NyaXB0XG4gKiAvLyBpbnNpZGUgY2FjaGUuaW50ZXJjZXB0b3JzLnRzXG4gKiBleHBvcnQgY29uc3QgSVNfQ0FDSEVfRU5BQkxFRCA9IG5ldyBIdHRwQ29udGV4dFRva2VuPGJvb2xlYW4+KCgpID0+IGZhbHNlKTtcbiAqXG4gKiBleHBvcnQgY2xhc3MgQ2FjaGVJbnRlcmNlcHRvciBpbXBsZW1lbnRzIEh0dHBJbnRlcmNlcHRvciB7XG4gKlxuICogICBpbnRlcmNlcHQocmVxOiBIdHRwUmVxdWVzdDxhbnk+LCBkZWxlZ2F0ZTogSHR0cEhhbmRsZXIpOiBPYnNlcnZhYmxlPEh0dHBFdmVudDxhbnk+PiB7XG4gKiAgICAgaWYgKHJlcS5jb250ZXh0LmdldChJU19DQUNIRV9FTkFCTEVEKSA9PT0gdHJ1ZSkge1xuICogICAgICAgcmV0dXJuIC4uLjtcbiAqICAgICB9XG4gKiAgICAgcmV0dXJuIGRlbGVnYXRlLmhhbmRsZShyZXEpO1xuICogICB9XG4gKiB9XG4gKlxuICogLy8gaW5zaWRlIGEgc2VydmljZVxuICpcbiAqIHRoaXMuaHR0cENsaWVudC5nZXQoJy9hcGkvd2VhdGhlcicsIHtcbiAqICAgY29udGV4dDogbmV3IEh0dHBDb250ZXh0KCkuc2V0KElTX0NBQ0hFX0VOQUJMRUQsIHRydWUpXG4gKiB9KS5zdWJzY3JpYmUoLi4uKTtcbiAqIGBgYFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGNsYXNzIEh0dHBDb250ZXh0IHtcbiAgcHJpdmF0ZSByZWFkb25seSBtYXAgPSBuZXcgTWFwPEh0dHBDb250ZXh0VG9rZW48dW5rbm93bj4sIHVua25vd24+KCk7XG5cbiAgLyoqXG4gICAqIFN0b3JlIGEgdmFsdWUgaW4gdGhlIGNvbnRleHQuIElmIGEgdmFsdWUgaXMgYWxyZWFkeSBwcmVzZW50IGl0IHdpbGwgYmUgb3ZlcndyaXR0ZW4uXG4gICAqXG4gICAqIEBwYXJhbSB0b2tlbiBUaGUgcmVmZXJlbmNlIHRvIGFuIGluc3RhbmNlIG9mIGBIdHRwQ29udGV4dFRva2VuYC5cbiAgICogQHBhcmFtIHZhbHVlIFRoZSB2YWx1ZSB0byBzdG9yZS5cbiAgICpcbiAgICogQHJldHVybnMgQSByZWZlcmVuY2UgdG8gaXRzZWxmIGZvciBlYXN5IGNoYWluaW5nLlxuICAgKi9cbiAgc2V0PFQ+KHRva2VuOiBIdHRwQ29udGV4dFRva2VuPFQ+LCB2YWx1ZTogVCk6IEh0dHBDb250ZXh0IHtcbiAgICB0aGlzLm1hcC5zZXQodG9rZW4sIHZhbHVlKTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZSB0aGUgdmFsdWUgYXNzb2NpYXRlZCB3aXRoIHRoZSBnaXZlbiB0b2tlbi5cbiAgICpcbiAgICogQHBhcmFtIHRva2VuIFRoZSByZWZlcmVuY2UgdG8gYW4gaW5zdGFuY2Ugb2YgYEh0dHBDb250ZXh0VG9rZW5gLlxuICAgKlxuICAgKiBAcmV0dXJucyBUaGUgc3RvcmVkIHZhbHVlIG9yIGRlZmF1bHQgaWYgb25lIGlzIGRlZmluZWQuXG4gICAqL1xuICBnZXQ8VD4odG9rZW46IEh0dHBDb250ZXh0VG9rZW48VD4pOiBUIHtcbiAgICBpZiAoIXRoaXMubWFwLmhhcyh0b2tlbikpIHtcbiAgICAgIHRoaXMubWFwLnNldCh0b2tlbiwgdG9rZW4uZGVmYXVsdFZhbHVlKCkpO1xuICAgIH1cbiAgICByZXR1cm4gdGhpcy5tYXAuZ2V0KHRva2VuKSBhcyBUO1xuICB9XG5cbiAgLyoqXG4gICAqIERlbGV0ZSB0aGUgdmFsdWUgYXNzb2NpYXRlZCB3aXRoIHRoZSBnaXZlbiB0b2tlbi5cbiAgICpcbiAgICogQHBhcmFtIHRva2VuIFRoZSByZWZlcmVuY2UgdG8gYW4gaW5zdGFuY2Ugb2YgYEh0dHBDb250ZXh0VG9rZW5gLlxuICAgKlxuICAgKiBAcmV0dXJucyBBIHJlZmVyZW5jZSB0byBpdHNlbGYgZm9yIGVhc3kgY2hhaW5pbmcuXG4gICAqL1xuICBkZWxldGUodG9rZW46IEh0dHBDb250ZXh0VG9rZW48dW5rbm93bj4pOiBIdHRwQ29udGV4dCB7XG4gICAgdGhpcy5tYXAuZGVsZXRlKHRva2VuKTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIC8qKlxuICAgKiBDaGVja3MgZm9yIGV4aXN0ZW5jZSBvZiBhIGdpdmVuIHRva2VuLlxuICAgKlxuICAgKiBAcGFyYW0gdG9rZW4gVGhlIHJlZmVyZW5jZSB0byBhbiBpbnN0YW5jZSBvZiBgSHR0cENvbnRleHRUb2tlbmAuXG4gICAqXG4gICAqIEByZXR1cm5zIFRydWUgaWYgdGhlIHRva2VuIGV4aXN0cywgZmFsc2Ugb3RoZXJ3aXNlLlxuICAgKi9cbiAgaGFzKHRva2VuOiBIdHRwQ29udGV4dFRva2VuPHVua25vd24+KTogYm9vbGVhbiB7XG4gICAgcmV0dXJuIHRoaXMubWFwLmhhcyh0b2tlbik7XG4gIH1cblxuICAvKipcbiAgICogQHJldHVybnMgYSBsaXN0IG9mIHRva2VucyBjdXJyZW50bHkgc3RvcmVkIGluIHRoZSBjb250ZXh0LlxuICAgKi9cbiAga2V5cygpOiBJdGVyYWJsZUl0ZXJhdG9yPEh0dHBDb250ZXh0VG9rZW48dW5rbm93bj4+IHtcbiAgICByZXR1cm4gdGhpcy5tYXAua2V5cygpO1xuICB9XG59XG4iXX0=