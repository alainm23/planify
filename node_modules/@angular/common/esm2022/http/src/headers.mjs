/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
/**
 * Represents the header configuration options for an HTTP request.
 * Instances are immutable. Modifying methods return a cloned
 * instance with the change. The original object is never changed.
 *
 * @publicApi
 */
export class HttpHeaders {
    /**  Constructs a new HTTP header object with the given values.*/
    constructor(headers) {
        /**
         * Internal map of lowercased header names to the normalized
         * form of the name (the form seen first).
         */
        this.normalizedNames = new Map();
        /**
         * Queued updates to be materialized the next initialization.
         */
        this.lazyUpdate = null;
        if (!headers) {
            this.headers = new Map();
        }
        else if (typeof headers === 'string') {
            this.lazyInit = () => {
                this.headers = new Map();
                headers.split('\n').forEach(line => {
                    const index = line.indexOf(':');
                    if (index > 0) {
                        const name = line.slice(0, index);
                        const key = name.toLowerCase();
                        const value = line.slice(index + 1).trim();
                        this.maybeSetNormalizedName(name, key);
                        if (this.headers.has(key)) {
                            this.headers.get(key).push(value);
                        }
                        else {
                            this.headers.set(key, [value]);
                        }
                    }
                });
            };
        }
        else {
            this.lazyInit = () => {
                if (typeof ngDevMode === 'undefined' || ngDevMode) {
                    assertValidHeaders(headers);
                }
                this.headers = new Map();
                Object.entries(headers).forEach(([name, values]) => {
                    let headerValues;
                    if (typeof values === 'string') {
                        headerValues = [values];
                    }
                    else if (typeof values === 'number') {
                        headerValues = [values.toString()];
                    }
                    else {
                        headerValues = values.map((value) => value.toString());
                    }
                    if (headerValues.length > 0) {
                        const key = name.toLowerCase();
                        this.headers.set(key, headerValues);
                        this.maybeSetNormalizedName(name, key);
                    }
                });
            };
        }
    }
    /**
     * Checks for existence of a given header.
     *
     * @param name The header name to check for existence.
     *
     * @returns True if the header exists, false otherwise.
     */
    has(name) {
        this.init();
        return this.headers.has(name.toLowerCase());
    }
    /**
     * Retrieves the first value of a given header.
     *
     * @param name The header name.
     *
     * @returns The value string if the header exists, null otherwise
     */
    get(name) {
        this.init();
        const values = this.headers.get(name.toLowerCase());
        return values && values.length > 0 ? values[0] : null;
    }
    /**
     * Retrieves the names of the headers.
     *
     * @returns A list of header names.
     */
    keys() {
        this.init();
        return Array.from(this.normalizedNames.values());
    }
    /**
     * Retrieves a list of values for a given header.
     *
     * @param name The header name from which to retrieve values.
     *
     * @returns A string of values if the header exists, null otherwise.
     */
    getAll(name) {
        this.init();
        return this.headers.get(name.toLowerCase()) || null;
    }
    /**
     * Appends a new value to the existing set of values for a header
     * and returns them in a clone of the original instance.
     *
     * @param name The header name for which to append the values.
     * @param value The value to append.
     *
     * @returns A clone of the HTTP headers object with the value appended to the given header.
     */
    append(name, value) {
        return this.clone({ name, value, op: 'a' });
    }
    /**
     * Sets or modifies a value for a given header in a clone of the original instance.
     * If the header already exists, its value is replaced with the given value
     * in the returned object.
     *
     * @param name The header name.
     * @param value The value or values to set or override for the given header.
     *
     * @returns A clone of the HTTP headers object with the newly set header value.
     */
    set(name, value) {
        return this.clone({ name, value, op: 's' });
    }
    /**
     * Deletes values for a given header in a clone of the original instance.
     *
     * @param name The header name.
     * @param value The value or values to delete for the given header.
     *
     * @returns A clone of the HTTP headers object with the given value deleted.
     */
    delete(name, value) {
        return this.clone({ name, value, op: 'd' });
    }
    maybeSetNormalizedName(name, lcName) {
        if (!this.normalizedNames.has(lcName)) {
            this.normalizedNames.set(lcName, name);
        }
    }
    init() {
        if (!!this.lazyInit) {
            if (this.lazyInit instanceof HttpHeaders) {
                this.copyFrom(this.lazyInit);
            }
            else {
                this.lazyInit();
            }
            this.lazyInit = null;
            if (!!this.lazyUpdate) {
                this.lazyUpdate.forEach(update => this.applyUpdate(update));
                this.lazyUpdate = null;
            }
        }
    }
    copyFrom(other) {
        other.init();
        Array.from(other.headers.keys()).forEach(key => {
            this.headers.set(key, other.headers.get(key));
            this.normalizedNames.set(key, other.normalizedNames.get(key));
        });
    }
    clone(update) {
        const clone = new HttpHeaders();
        clone.lazyInit =
            (!!this.lazyInit && this.lazyInit instanceof HttpHeaders) ? this.lazyInit : this;
        clone.lazyUpdate = (this.lazyUpdate || []).concat([update]);
        return clone;
    }
    applyUpdate(update) {
        const key = update.name.toLowerCase();
        switch (update.op) {
            case 'a':
            case 's':
                let value = update.value;
                if (typeof value === 'string') {
                    value = [value];
                }
                if (value.length === 0) {
                    return;
                }
                this.maybeSetNormalizedName(update.name, key);
                const base = (update.op === 'a' ? this.headers.get(key) : undefined) || [];
                base.push(...value);
                this.headers.set(key, base);
                break;
            case 'd':
                const toDelete = update.value;
                if (!toDelete) {
                    this.headers.delete(key);
                    this.normalizedNames.delete(key);
                }
                else {
                    let existing = this.headers.get(key);
                    if (!existing) {
                        return;
                    }
                    existing = existing.filter(value => toDelete.indexOf(value) === -1);
                    if (existing.length === 0) {
                        this.headers.delete(key);
                        this.normalizedNames.delete(key);
                    }
                    else {
                        this.headers.set(key, existing);
                    }
                }
                break;
        }
    }
    /**
     * @internal
     */
    forEach(fn) {
        this.init();
        Array.from(this.normalizedNames.keys())
            .forEach(key => fn(this.normalizedNames.get(key), this.headers.get(key)));
    }
}
/**
 * Verifies that the headers object has the right shape: the values
 * must be either strings, numbers or arrays. Throws an error if an invalid
 * header value is present.
 */
function assertValidHeaders(headers) {
    for (const [key, value] of Object.entries(headers)) {
        if (!(typeof value === 'string' || typeof value === 'number') && !Array.isArray(value)) {
            throw new Error(`Unexpected value of the \`${key}\` header provided. ` +
                `Expecting either a string, a number or an array, but got: \`${value}\`.`);
        }
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaGVhZGVycy5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvbW1vbi9odHRwL3NyYy9oZWFkZXJzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQVFIOzs7Ozs7R0FNRztBQUNILE1BQU0sT0FBTyxXQUFXO0lBd0J0QixpRUFBaUU7SUFFakUsWUFBWSxPQUF3RTtRQWxCcEY7OztXQUdHO1FBQ0ssb0JBQWUsR0FBd0IsSUFBSSxHQUFHLEVBQUUsQ0FBQztRQU96RDs7V0FFRztRQUNLLGVBQVUsR0FBa0IsSUFBSSxDQUFDO1FBS3ZDLElBQUksQ0FBQyxPQUFPLEVBQUU7WUFDWixJQUFJLENBQUMsT0FBTyxHQUFHLElBQUksR0FBRyxFQUFvQixDQUFDO1NBQzVDO2FBQU0sSUFBSSxPQUFPLE9BQU8sS0FBSyxRQUFRLEVBQUU7WUFDdEMsSUFBSSxDQUFDLFFBQVEsR0FBRyxHQUFHLEVBQUU7Z0JBQ25CLElBQUksQ0FBQyxPQUFPLEdBQUcsSUFBSSxHQUFHLEVBQW9CLENBQUM7Z0JBQzNDLE9BQU8sQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLENBQUMsT0FBTyxDQUFDLElBQUksQ0FBQyxFQUFFO29CQUNqQyxNQUFNLEtBQUssR0FBRyxJQUFJLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxDQUFDO29CQUNoQyxJQUFJLEtBQUssR0FBRyxDQUFDLEVBQUU7d0JBQ2IsTUFBTSxJQUFJLEdBQUcsSUFBSSxDQUFDLEtBQUssQ0FBQyxDQUFDLEVBQUUsS0FBSyxDQUFDLENBQUM7d0JBQ2xDLE1BQU0sR0FBRyxHQUFHLElBQUksQ0FBQyxXQUFXLEVBQUUsQ0FBQzt3QkFDL0IsTUFBTSxLQUFLLEdBQUcsSUFBSSxDQUFDLEtBQUssQ0FBQyxLQUFLLEdBQUcsQ0FBQyxDQUFDLENBQUMsSUFBSSxFQUFFLENBQUM7d0JBQzNDLElBQUksQ0FBQyxzQkFBc0IsQ0FBQyxJQUFJLEVBQUUs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QUMsRUFBRTtZQUN0RixNQUFNLElBQUksS0FBSyxDQUNYLDZCQUE2QixHQUFHLHNCQUFzQjtnQkFDdEQsK0RBQStELEtBQUssS0FBSyxDQUFDLENBQUM7U0FDaEY7S0FDRjtBQUNILENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW50ZXJmYWNlIFVwZGF0ZSB7XG4gIG5hbWU6IHN0cmluZztcbiAgdmFsdWU/OiBzdHJpbmd8c3RyaW5nW107XG4gIG9wOiAnYSd8J3MnfCdkJztcbn1cblxuLyoqXG4gKiBSZXByZXNlbnRzIHRoZSBoZWFkZXIgY29uZmlndXJhdGlvbiBvcHRpb25zIGZvciBhbiBIVFRQIHJlcXVlc3QuXG4gKiBJbnN0YW5jZXMgYXJlIGltbXV0YWJsZS4gTW9kaWZ5aW5nIG1ldGhvZHMgcmV0dXJuIGEgY2xvbmVkXG4gKiBpbnN0YW5jZSB3aXRoIHRoZSBjaGFuZ2UuIFRoZSBvcmlnaW5hbCBvYmplY3QgaXMgbmV2ZXIgY2hhbmdlZC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBIdHRwSGVhZGVycyB7XG4gIC8qKlxuICAgKiBJbnRlcm5hbCBtYXAgb2YgbG93ZXJjYXNlIGhlYWRlciBuYW1lcyB0byB2YWx1ZXMuXG4gICAqL1xuICAvLyBUT0RPKGlzc3VlLzI0NTcxKTogcmVtb3ZlICchJy5cbiAgcHJpdmF0ZSBoZWFkZXJzITogTWFwPHN0cmluZywgc3RyaW5nW10+O1xuXG5cbiAgLyoqXG4gICAqIEludGVybmFsIG1hcCBvZiBsb3dlcmNhc2VkIGhlYWRlciBuYW1lcyB0byB0aGUgbm9ybWFsaXplZFxuICAgKiBmb3JtIG9mIHRoZSBuYW1lICh0aGUgZm9ybSBzZWVuIGZpcnN0KS5cbiAgICovXG4gIHByaXZhdGUgbm9ybWFsaXplZE5hbWVzOiBNYXA8c3RyaW5nLCBzdHJpbmc+ID0gbmV3IE1hcCgpO1xuXG4gIC8qKlxuICAgKiBDb21wbGV0ZSB0aGUgbGF6eSBpbml0aWFsaXphdGlvbiBvZiB0aGlzIG9iamVjdCAobmVlZGVkIGJlZm9yZSByZWFkaW5nKS5cbiAgICovXG4gIHByaXZhdGUgbGF6eUluaXQhOiBIdHRwSGVhZGVyc3xGdW5jdGlvbnxudWxsO1xuXG4gIC8qKlxuICAgKiBRdWV1ZWQgdXBkYXRlcyB0byBiZSBtYXRlcmlhbGl6ZWQgdGhlIG5leHQgaW5pdGlhbGl6YXRpb24uXG4gICAqL1xuICBwcml2YXRlIGxhenlVcGRhdGU6IFVwZGF0ZVtdfG51bGwgPSBudWxsO1xuXG4gIC8qKiAgQ29uc3RydWN0cyBhIG5ldyBIVFRQIGhlYWRlciBvYmplY3Qgd2l0aCB0aGUgZ2l2ZW4gdmFsdWVzLiovXG5cbiAgY29uc3RydWN0b3IoaGVhZGVycz86IHN0cmluZ3x7W25hbWU6IHN0cmluZ106IHN0cmluZyB8IG51bWJlciB8IChzdHJpbmcgfCBudW1iZXIpW119KSB7XG4gICAgaWYgKCFoZWFkZXJzKSB7XG4gICAgICB0aGlzLmhlYWRlcnMgPSBuZXcgTWFwPHN0cmluZywgc3RyaW5nW10+KCk7XG4gICAgfSBlbHNlIGlmICh0eXBlb2YgaGVhZGVycyA9PT0gJ3N0cmluZycpIHtcbiAgICAgIHRoaXMubGF6eUluaXQgPSAoKSA9PiB7XG4gICAgICAgIHRoaXMuaGVhZGVycyA9IG5ldyBNYXA8c3RyaW5nLCBzdHJpbmdbXT4oKTtcbiAgICAgICAgaGVhZGVycy5zcGxpdCgnXFxuJykuZm9yRWFjaChsaW5lID0+IHtcbiAgICAgICAgICBjb25zdCBpbmRleCA9IGxpbmUuaW5kZXhPZignOicpO1xuICAgICAgICAgIGlmIChpbmRleCA+IDApIHtcbiAgICAgICAgICAgIGNvbnN0IG5hbWUgPSBsaW5lLnNsaWNlKDAsIGluZGV4KTtcbiAgICAgICAgICAgIGNvbnN0IGtleSA9IG5hbWUudG9Mb3dlckNhc2UoKTtcbiAgICAgICAgICAgIGNvbnN0IHZhbHVlID0gbGluZS5zbGljZShpbmRleCArIDEpLnRyaW0oKTtcbiAgICAgICAgICAgIHRoaXMubWF5YmVTZXROb3JtYWxpemVkTmFtZShuYW1lLCBrZXkpO1xuICAgICAgICAgICAgaWYgKHRoaXMuaGVhZGVycy5oYXMoa2V5KSkge1xuICAgICAgICAgICAgICB0aGlzLmhlYWRlcnMuZ2V0KGtleSkhLnB1c2godmFsdWUpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgdGhpcy5oZWFkZXJzLnNldChrZXksIFt2YWx1ZV0pO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9O1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLmxhenlJbml0ID0gKCkgPT4ge1xuICAgICAgICBpZiAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSB7XG4gICAgICAgICAgYXNzZXJ0VmFsaWRIZWFkZXJzKGhlYWRlcnMpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuaGVhZGVycyA9IG5ldyBNYXA8c3RyaW5nLCBzdHJpbmdbXT4oKTtcbiAgICAgICAgT2JqZWN0LmVudHJpZXMoaGVhZGVycykuZm9yRWFjaCgoW25hbWUsIHZhbHVlc10pID0+IHtcbiAgICAgICAgICBsZXQgaGVhZGVyVmFsdWVzOiBzdHJpbmdbXTtcblxuICAgICAgICAgIGlmICh0eXBlb2YgdmFsdWVzID09PSAnc3RyaW5nJykge1xuICAgICAgICAgICAgaGVhZGVyVmFsdWVzID0gW3ZhbHVlc107XG4gICAgICAgICAgfSBlbHNlIGlmICh0eXBlb2YgdmFsdWVzID09PSAnbnVtYmVyJykge1xuICAgICAgICAgICAgaGVhZGVyVmFsdWVzID0gW3ZhbHVlcy50b1N0cmluZygpXTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgaGVhZGVyVmFsdWVzID0gdmFsdWVzLm1hcCgodmFsdWUpID0+IHZhbHVlLnRvU3RyaW5nKCkpO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmIChoZWFkZXJWYWx1ZXMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgY29uc3Qga2V5ID0gbmFtZS50b0xvd2VyQ2FzZSgpO1xuICAgICAgICAgICAgdGhpcy5oZWFkZXJzLnNldChrZXksIGhlYWRlclZhbHVlcyk7XG4gICAgICAgICAgICB0aGlzLm1heWJlU2V0Tm9ybWFsaXplZE5hbWUobmFtZSwga2V5KTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfTtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogQ2hlY2tzIGZvciBleGlzdGVuY2Ugb2YgYSBnaXZlbiBoZWFkZXIuXG4gICAqXG4gICAqIEBwYXJhbSBuYW1lIFRoZSBoZWFkZXIgbmFtZSB0byBjaGVjayBmb3IgZXhpc3RlbmNlLlxuICAgKlxuICAgKiBAcmV0dXJucyBUcnVlIGlmIHRoZSBoZWFkZXIgZXhpc3RzLCBmYWxzZSBvdGhlcndpc2UuXG4gICAqL1xuICBoYXMobmFtZTogc3RyaW5nKTogYm9vbGVhbiB7XG4gICAgdGhpcy5pbml0KCk7XG5cbiAgICByZXR1cm4gdGhpcy5oZWFkZXJzLmhhcyhuYW1lLnRvTG93ZXJDYXNlKCkpO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyB0aGUgZmlyc3QgdmFsdWUgb2YgYSBnaXZlbiBoZWFkZXIuXG4gICAqXG4gICAqIEBwYXJhbSBuYW1lIFRoZSBoZWFkZXIgbmFtZS5cbiAgICpcbiAgICogQHJldHVybnMgVGhlIHZhbHVlIHN0cmluZyBpZiB0aGUgaGVhZGVyIGV4aXN0cywgbnVsbCBvdGhlcndpc2VcbiAgICovXG4gIGdldChuYW1lOiBzdHJpbmcpOiBzdHJpbmd8bnVsbCB7XG4gICAgdGhpcy5pbml0KCk7XG5cbiAgICBjb25zdCB2YWx1ZXMgPSB0aGlzLmhlYWRlcnMuZ2V0KG5hbWUudG9Mb3dlckNhc2UoKSk7XG4gICAgcmV0dXJuIHZhbHVlcyAmJiB2YWx1ZXMubGVuZ3RoID4gMCA/IHZhbHVlc1swXSA6IG51bGw7XG4gIH1cblxuICAvKipcbiAgICogUmV0cmlldmVzIHRoZSBuYW1lcyBvZiB0aGUgaGVhZGVycy5cbiAgICpcbiAgICogQHJldHVybnMgQSBsaXN0IG9mIGhlYWRlciBuYW1lcy5cbiAgICovXG4gIGtleXMoKTogc3RyaW5nW10ge1xuICAgIHRoaXMuaW5pdCgpO1xuXG4gICAgcmV0dXJuIEFycmF5LmZyb20odGhpcy5ub3JtYWxpemVkTmFtZXMudmFsdWVzKCkpO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyBhIGxpc3Qgb2YgdmFsdWVzIGZvciBhIGdpdmVuIGhlYWRlci5cbiAgICpcbiAgICogQHBhcmFtIG5hbWUgVGhlIGhlYWRlciBuYW1lIGZyb20gd2hpY2ggdG8gcmV0cmlldmUgdmFsdWVzLlxuICAgKlxuICAgKiBAcmV0dXJucyBBIHN0cmluZyBvZiB2YWx1ZXMgaWYgdGhlIGhlYWRlciBleGlzdHMsIG51bGwgb3RoZXJ3aXNlLlxuICAgKi9cbiAgZ2V0QWxsKG5hbWU6IHN0cmluZyk6IHN0cmluZ1tdfG51bGwge1xuICAgIHRoaXMuaW5pdCgpO1xuXG4gICAgcmV0dXJuIHRoaXMuaGVhZGVycy5nZXQobmFtZS50b0xvd2VyQ2FzZSgpKSB8fCBudWxsO1xuICB9XG5cbiAgLyoqXG4gICAqIEFwcGVuZHMgYSBuZXcgdmFsdWUgdG8gdGhlIGV4aXN0aW5nIHNldCBvZiB2YWx1ZXMgZm9yIGEgaGVhZGVyXG4gICAqIGFuZCByZXR1cm5zIHRoZW0gaW4gYSBjbG9uZSBvZiB0aGUgb3JpZ2luYWwgaW5zdGFuY2UuXG4gICAqXG4gICAqIEBwYXJhbSBuYW1lIFRoZSBoZWFkZXIgbmFtZSBmb3Igd2hpY2ggdG8gYXBwZW5kIHRoZSB2YWx1ZXMuXG4gICAqIEBwYXJhbSB2YWx1ZSBUaGUgdmFsdWUgdG8gYXBwZW5kLlxuICAgKlxuICAgKiBAcmV0dXJucyBBIGNsb25lIG9mIHRoZSBIVFRQIGhlYWRlcnMgb2JqZWN0IHdpdGggdGhlIHZhbHVlIGFwcGVuZGVkIHRvIHRoZSBnaXZlbiBoZWFkZXIuXG4gICAqL1xuXG4gIGFwcGVuZChuYW1lOiBzdHJpbmcsIHZhbHVlOiBzdHJpbmd8c3RyaW5nW10pOiBIdHRwSGVhZGVycyB7XG4gICAgcmV0dXJuIHRoaXMuY2xvbmUoe25hbWUsIHZhbHVlLCBvcDogJ2EnfSk7XG4gIH1cbiAgLyoqXG4gICAqIFNldHMgb3IgbW9kaWZpZXMgYSB2YWx1ZSBmb3IgYSBnaXZlbiBoZWFkZXIgaW4gYSBjbG9uZSBvZiB0aGUgb3JpZ2luYWwgaW5zdGFuY2UuXG4gICAqIElmIHRoZSBoZWFkZXIgYWxyZWFkeSBleGlzdHMsIGl0cyB2YWx1ZSBpcyByZXBsYWNlZCB3aXRoIHRoZSBnaXZlbiB2YWx1ZVxuICAgKiBpbiB0aGUgcmV0dXJuZWQgb2JqZWN0LlxuICAgKlxuICAgKiBAcGFyYW0gbmFtZSBUaGUgaGVhZGVyIG5hbWUuXG4gICAqIEBwYXJhbSB2YWx1ZSBUaGUgdmFsdWUgb3IgdmFsdWVzIHRvIHNldCBvciBvdmVycmlkZSBmb3IgdGhlIGdpdmVuIGhlYWRlci5cbiAgICpcbiAgICogQHJldHVybnMgQSBjbG9uZSBvZiB0aGUgSFRUUCBoZWFkZXJzIG9iamVjdCB3aXRoIHRoZSBuZXdseSBzZXQgaGVhZGVyIHZhbHVlLlxuICAgKi9cbiAgc2V0KG5hbWU6IHN0cmluZywgdmFsdWU6IHN0cmluZ3xzdHJpbmdbXSk6IEh0dHBIZWFkZXJzIHtcbiAgICByZXR1cm4gdGhpcy5jbG9uZSh7bmFtZSwgdmFsdWUsIG9wOiAncyd9KTtcbiAgfVxuICAvKipcbiAgICogRGVsZXRlcyB2YWx1ZXMgZm9yIGEgZ2l2ZW4gaGVhZGVyIGluIGEgY2xvbmUgb2YgdGhlIG9yaWdpbmFsIGluc3RhbmNlLlxuICAgKlxuICAgKiBAcGFyYW0gbmFtZSBUaGUgaGVhZGVyIG5hbWUuXG4gICAqIEBwYXJhbSB2YWx1ZSBUaGUgdmFsdWUgb3IgdmFsdWVzIHRvIGRlbGV0ZSBmb3IgdGhlIGdpdmVuIGhlYWRlci5cbiAgICpcbiAgICogQHJldHVybnMgQSBjbG9uZSBvZiB0aGUgSFRUUCBoZWFkZXJzIG9iamVjdCB3aXRoIHRoZSBnaXZlbiB2YWx1ZSBkZWxldGVkLlxuICAgKi9cbiAgZGVsZXRlKG5hbWU6IHN0cmluZywgdmFsdWU/OiBzdHJpbmd8c3RyaW5nW10pOiBIdHRwSGVhZGVycyB7XG4gICAgcmV0dXJuIHRoaXMuY2xvbmUoe25hbWUsIHZhbHVlLCBvcDogJ2QnfSk7XG4gIH1cblxuICBwcml2YXRlIG1heWJlU2V0Tm9ybWFsaXplZE5hbWUobmFtZTogc3RyaW5nLCBsY05hbWU6IHN0cmluZyk6IHZvaWQge1xuICAgIGlmICghdGhpcy5ub3JtYWxpemVkTmFtZXMuaGFzKGxjTmFtZSkpIHtcbiAgICAgIHRoaXMubm9ybWFsaXplZE5hbWVzLnNldChsY05hbWUsIG5hbWUpO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgaW5pdCgpOiB2b2lkIHtcbiAgICBpZiAoISF0aGlzLmxhenlJbml0KSB7XG4gICAgICBpZiAodGhpcy5sYXp5SW5pdCBpbnN0YW5jZW9mIEh0dHBIZWFkZXJzKSB7XG4gICAgICAgIHRoaXMuY29weUZyb20odGhpcy5sYXp5SW5pdCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB0aGlzLmxhenlJbml0KCk7XG4gICAgICB9XG4gICAgICB0aGlzLmxhenlJbml0ID0gbnVsbDtcbiAgICAgIGlmICghIXRoaXMubGF6eVVwZGF0ZSkge1xuICAgICAgICB0aGlzLmxhenlVcGRhdGUuZm9yRWFjaCh1cGRhdGUgPT4gdGhpcy5hcHBseVVwZGF0ZSh1cGRhdGUpKTtcbiAgICAgICAgdGhpcy5sYXp5VXBkYXRlID0gbnVsbDtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGNvcHlGcm9tKG90aGVyOiBIdHRwSGVhZGVycykge1xuICAgIG90aGVyLmluaXQoKTtcbiAgICBBcnJheS5mcm9tKG90aGVyLmhlYWRlcnMua2V5cygpKS5mb3JFYWNoKGtleSA9PiB7XG4gICAgICB0aGlzLmhlYWRlcnMuc2V0KGtleSwgb3RoZXIuaGVhZGVycy5nZXQoa2V5KSEpO1xuICAgICAgdGhpcy5ub3JtYWxpemVkTmFtZXMuc2V0KGtleSwgb3RoZXIubm9ybWFsaXplZE5hbWVzLmdldChrZXkpISk7XG4gICAgfSk7XG4gIH1cblxuICBwcml2YXRlIGNsb25lKHVwZGF0ZTogVXBkYXRlKTogSHR0cEhlYWRlcnMge1xuICAgIGNvbnN0IGNsb25lID0gbmV3IEh0dHBIZWFkZXJzKCk7XG4gICAgY2xvbmUubGF6eUluaXQgPVxuICAgICAgICAoISF0aGlzLmxhenlJbml0ICYmIHRoaXMubGF6eUluaXQgaW5zdGFuY2VvZiBIdHRwSGVhZGVycykgPyB0aGlzLmxhenlJbml0IDogdGhpcztcbiAgICBjbG9uZS5sYXp5VXBkYXRlID0gKHRoaXMubGF6eVVwZGF0ZSB8fCBbXSkuY29uY2F0KFt1cGRhdGVdKTtcbiAgICByZXR1cm4gY2xvbmU7XG4gIH1cblxuICBwcml2YXRlIGFwcGx5VXBkYXRlKHVwZGF0ZTogVXBkYXRlKTogdm9pZCB7XG4gICAgY29uc3Qga2V5ID0gdXBkYXRlLm5hbWUudG9Mb3dlckNhc2UoKTtcbiAgICBzd2l0Y2ggKHVwZGF0ZS5vcCkge1xuICAgICAgY2FzZSAnYSc6XG4gICAgICBjYXNlICdzJzpcbiAgICAgICAgbGV0IHZhbHVlID0gdXBkYXRlLnZhbHVlITtcbiAgICAgICAgaWYgKHR5cGVvZiB2YWx1ZSA9PT0gJ3N0cmluZycpIHtcbiAgICAgICAgICB2YWx1ZSA9IFt2YWx1ZV07XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHZhbHVlLmxlbmd0aCA9PT0gMCkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLm1heWJlU2V0Tm9ybWFsaXplZE5hbWUodXBkYXRlLm5hbWUsIGtleSk7XG4gICAgICAgIGNvbnN0IGJhc2UgPSAodXBkYXRlLm9wID09PSAnYScgPyB0aGlzLmhlYWRlcnMuZ2V0KGtleSkgOiB1bmRlZmluZWQpIHx8IFtdO1xuICAgICAgICBiYXNlLnB1c2goLi4udmFsdWUpO1xuICAgICAgICB0aGlzLmhlYWRlcnMuc2V0KGtleSwgYmFzZSk7XG4gICAgICAgIGJyZWFrO1xuICAgICAgY2FzZSAnZCc6XG4gICAgICAgIGNvbnN0IHRvRGVsZXRlID0gdXBkYXRlLnZhbHVlIGFzIHN0cmluZyB8IHVuZGVmaW5lZDtcbiAgICAgICAgaWYgKCF0b0RlbGV0ZSkge1xuICAgICAgICAgIHRoaXMuaGVhZGVycy5kZWxldGUoa2V5KTtcbiAgICAgICAgICB0aGlzLm5vcm1hbGl6ZWROYW1lcy5kZWxldGUoa2V5KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBsZXQgZXhpc3RpbmcgPSB0aGlzLmhlYWRlcnMuZ2V0KGtleSk7XG4gICAgICAgICAgaWYgKCFleGlzdGluZykge1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgIH1cbiAgICAgICAgICBleGlzdGluZyA9IGV4aXN0aW5nLmZpbHRlcih2YWx1ZSA9PiB0b0RlbGV0ZS5pbmRleE9mKHZhbHVlKSA9PT0gLTEpO1xuICAgICAgICAgIGlmIChleGlzdGluZy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgICAgIHRoaXMuaGVhZGVycy5kZWxldGUoa2V5KTtcbiAgICAgICAgICAgIHRoaXMubm9ybWFsaXplZE5hbWVzLmRlbGV0ZShrZXkpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB0aGlzLmhlYWRlcnMuc2V0KGtleSwgZXhpc3RpbmcpO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBicmVhaztcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogQGludGVybmFsXG4gICAqL1xuICBmb3JFYWNoKGZuOiAobmFtZTogc3RyaW5nLCB2YWx1ZXM6IHN0cmluZ1tdKSA9PiB2b2lkKSB7XG4gICAgdGhpcy5pbml0KCk7XG4gICAgQXJyYXkuZnJvbSh0aGlzLm5vcm1hbGl6ZWROYW1lcy5rZXlzKCkpXG4gICAgICAgIC5mb3JFYWNoKGtleSA9PiBmbih0aGlzLm5vcm1hbGl6ZWROYW1lcy5nZXQoa2V5KSEsIHRoaXMuaGVhZGVycy5nZXQoa2V5KSEpKTtcbiAgfVxufVxuXG4vKipcbiAqIFZlcmlmaWVzIHRoYXQgdGhlIGhlYWRlcnMgb2JqZWN0IGhhcyB0aGUgcmlnaHQgc2hhcGU6IHRoZSB2YWx1ZXNcbiAqIG11c3QgYmUgZWl0aGVyIHN0cmluZ3MsIG51bWJlcnMgb3IgYXJyYXlzLiBUaHJvd3MgYW4gZXJyb3IgaWYgYW4gaW52YWxpZFxuICogaGVhZGVyIHZhbHVlIGlzIHByZXNlbnQuXG4gKi9cbmZ1bmN0aW9uIGFzc2VydFZhbGlkSGVhZGVycyhoZWFkZXJzOiBSZWNvcmQ8c3RyaW5nLCB1bmtub3duPik6XG4gICAgYXNzZXJ0cyBoZWFkZXJzIGlzIFJlY29yZDxzdHJpbmcsIHN0cmluZ3xzdHJpbmdbXXxudW1iZXJ8bnVtYmVyW10+IHtcbiAgZm9yIChjb25zdCBba2V5LCB2YWx1ZV0gb2YgT2JqZWN0LmVudHJpZXMoaGVhZGVycykpIHtcbiAgICBpZiAoISh0eXBlb2YgdmFsdWUgPT09ICdzdHJpbmcnIHx8IHR5cGVvZiB2YWx1ZSA9PT0gJ251bWJlcicpICYmICFBcnJheS5pc0FycmF5KHZhbHVlKSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFxuICAgICAgICAgIGBVbmV4cGVjdGVkIHZhbHVlIG9mIHRoZSBcXGAke2tleX1cXGAgaGVhZGVyIHByb3ZpZGVkLiBgICtcbiAgICAgICAgICBgRXhwZWN0aW5nIGVpdGhlciBhIHN0cmluZywgYSBudW1iZXIgb3IgYW4gYXJyYXksIGJ1dCBnb3Q6IFxcYCR7dmFsdWV9XFxgLmApO1xuICAgIH1cbiAgfVxufVxuIl19