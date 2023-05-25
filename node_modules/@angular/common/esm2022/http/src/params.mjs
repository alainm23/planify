/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
/**
 * Provides encoding and decoding of URL parameter and query-string values.
 *
 * Serializes and parses URL parameter keys and values to encode and decode them.
 * If you pass URL query parameters without encoding,
 * the query parameters can be misinterpreted at the receiving end.
 *
 *
 * @publicApi
 */
export class HttpUrlEncodingCodec {
    /**
     * Encodes a key name for a URL parameter or query-string.
     * @param key The key name.
     * @returns The encoded key name.
     */
    encodeKey(key) {
        return standardEncoding(key);
    }
    /**
     * Encodes the value of a URL parameter or query-string.
     * @param value The value.
     * @returns The encoded value.
     */
    encodeValue(value) {
        return standardEncoding(value);
    }
    /**
     * Decodes an encoded URL parameter or query-string key.
     * @param key The encoded key name.
     * @returns The decoded key name.
     */
    decodeKey(key) {
        return decodeURIComponent(key);
    }
    /**
     * Decodes an encoded URL parameter or query-string value.
     * @param value The encoded value.
     * @returns The decoded value.
     */
    decodeValue(value) {
        return decodeURIComponent(value);
    }
}
function paramParser(rawParams, codec) {
    const map = new Map();
    if (rawParams.length > 0) {
        // The `window.location.search` can be used while creating an instance of the `HttpParams` class
        // (e.g. `new HttpParams({ fromString: window.location.search })`). The `window.location.search`
        // may start with the `?` char, so we strip it if it's present.
        const params = rawParams.replace(/^\?/, '').split('&');
        params.forEach((param) => {
            const eqIdx = param.indexOf('=');
            const [key, val] = eqIdx == -1 ?
                [codec.decodeKey(param), ''] :
                [codec.decodeKey(param.slice(0, eqIdx)), codec.decodeValue(param.slice(eqIdx + 1))];
            const list = map.get(key) || [];
            list.push(val);
            map.set(key, list);
        });
    }
    return map;
}
/**
 * Encode input string with standard encodeURIComponent and then un-encode specific characters.
 */
const STANDARD_ENCODING_REGEX = /%(\d[a-f0-9])/gi;
const STANDARD_ENCODING_REPLACEMENTS = {
    '40': '@',
    '3A': ':',
    '24': '$',
    '2C': ',',
    '3B': ';',
    '3D': '=',
    '3F': '?',
    '2F': '/',
};
function standardEncoding(v) {
    return encodeURIComponent(v).replace(STANDARD_ENCODING_REGEX, (s, t) => STANDARD_ENCODING_REPLACEMENTS[t] ?? s);
}
function valueToString(value) {
    return `${value}`;
}
/**
 * An HTTP request/response body that represents serialized parameters,
 * per the MIME type `application/x-www-form-urlencoded`.
 *
 * This class is immutable; all mutation operations return a new instance.
 *
 * @publicApi
 */
export class HttpParams {
    constructor(options = {}) {
        this.updates = null;
        this.cloneFrom = null;
        this.encoder = options.encoder || new HttpUrlEncodingCodec();
        if (!!options.fromString) {
            if (!!options.fromObject) {
                throw new Error(`Cannot specify both fromString and fromObject.`);
            }
            this.map = paramParser(options.fromString, this.encoder);
        }
        else if (!!options.fromObject) {
            this.map = new Map();
            Object.keys(options.fromObject).forEach(key => {
                const value = options.fromObject[key];
                // convert the values to strings
                const values = Array.isArray(value) ? value.map(valueToString) : [valueToString(value)];
                this.map.set(key, values);
            });
        }
        else {
            this.map = null;
        }
    }
    /**
     * Reports whether the body includes one or more values for a given parameter.
     * @param param The parameter name.
     * @returns True if the parameter has one or more values,
     * false if it has no value or is not present.
     */
    has(param) {
        this.init();
        return this.map.has(param);
    }
    /**
     * Retrieves the first value for a parameter.
     * @param param The parameter name.
     * @returns The first value of the given parameter,
     * or `null` if the parameter is not present.
     */
    get(param) {
        this.init();
        const res = this.map.get(param);
        return !!res ? res[0] : null;
    }
    /**
     * Retrieves all values for a  parameter.
     * @param param The parameter name.
     * @returns All values in a string array,
     * or `null` if the parameter not present.
     */
    getAll(param) {
        this.init();
        return this.map.get(param) || null;
    }
    /**
     * Retrieves all the parameters for this body.
     * @returns The parameter names in a string array.
     */
    keys() {
        this.init();
        return Array.from(this.map.keys());
    }
    /**
     * Appends a new value to existing values for a parameter.
     * @param param The parameter name.
     * @param value The new value to add.
     * @return A new body with the appended value.
     */
    append(param, value) {
        return this.clone({ param, value, op: 'a' });
    }
    /**
     * Constructs a new body with appended values for the given parameter name.
     * @param params parameters and values
     * @return A new body with the new value.
     */
    appendAll(params) {
        const updates = [];
        Object.keys(params).forEach(param => {
            const value = params[param];
            if (Array.isArray(value)) {
                value.forEach(_value => {
                    updates.push({ param, value: _value, op: 'a' });
                });
            }
            else {
                updates.push({ param, value: value, op: 'a' });
            }
        });
        return this.clone(updates);
    }
    /**
     * Replaces the value for a parameter.
     * @param param The parameter name.
     * @param value The new value.
     * @return A new body with the new value.
     */
    set(param, value) {
        return this.clone({ param, value, op: 's' });
    }
    /**
     * Removes a given value or all values from a parameter.
     * @param param The parameter name.
     * @param value The value to remove, if provided.
     * @return A new body with the given value removed, or with all values
     * removed if no value is specified.
     */
    delete(param, value) {
        return this.clone({ param, value, op: 'd' });
    }
    /**
     * Serializes the body to an encoded string, where key-value pairs (separated by `=`) are
     * separated by `&`s.
     */
    toString() {
        this.init();
        return this.keys()
            .map(key => {
            const eKey = this.encoder.encodeKey(key);
            // `a: ['1']` produces `'a=1'`
            // `b: []` produces `''`
            // `c: ['1', '2']` produces `'c=1&c=2'`
            return this.map.get(key).map(value => eKey + '=' + this.encoder.encodeValue(value))
                .join('&');
        })
            // filter out empty values because `b: []` produces `''`
            // which results in `a=1&&c=1&c=2` instead of `a=1&c=1&c=2` if we don't
            .filter(param => param !== '')
            .join('&');
    }
    clone(update) {
        const clone = new HttpParams({ encoder: this.encoder });
        clone.cloneFrom = this.cloneFrom || this;
        clone.updates = (this.updates || []).concat(update);
        return clone;
    }
    init() {
        if (this.map === null) {
            this.map = new Map();
        }
        if (this.cloneFrom !== null) {
            this.cloneFrom.init();
            this.cloneFrom.keys().forEach(key => this.map.set(key, this.cloneFrom.map.get(key)));
            this.updates.forEach(update => {
                switch (update.op) {
                    case 'a':
                    case 's':
                        const base = (update.op === 'a' ? this.map.get(update.param) : undefined) || [];
                        base.push(valueToString(update.value));
                        this.map.set(update.param, base);
                        break;
                    case 'd':
                        if (update.value !== undefined) {
                            let base = this.map.get(update.param) || [];
                            const idx = base.indexOf(valueToString(update.value));
                            if (idx !== -1) {
                                base.splice(idx, 1);
                            }
                            if (base.length > 0) {
                                this.map.set(update.param, base);
                            }
                            else {
                                this.map.delete(update.param);
                            }
                        }
                        else {
                            this.map.delete(update.param);
                            break;
                        }
                }
            });
            this.cloneFrom = this.updates = null;
        }
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicGFyYW1zLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29tbW9uL2h0dHAvc3JjL3BhcmFtcy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFpQkg7Ozs7Ozs7OztHQVNHO0FBQ0gsTUFBTSxPQUFPLG9CQUFvQjtJQUMvQjs7OztPQUlHO0lBQ0gsU0FBUyxDQUFDLEdBQVc7UUFDbkIsT0FBTyxnQkFBZ0IsQ0FBQyxHQUFHLENBQUMsQ0FBQztJQUMvQixDQUFDO0lBRUQ7Ozs7T0FJRztJQUNILFdBQVcsQ0FBQyxLQUFhO1FBQ3ZCLE9BQU8sZ0JBQWdCLENBQUMsS0FBSyxDQUFDLENBQUM7SUFDakMsQ0FBQztJQUVEOzs7O09BSUc7SUFDSCxTQUFTLENBQUMsR0FBVztRQUNuQixPQUFPLGtCQUFrQixDQUFDLEdBQUcsQ0FBQyxDQUFDO0lBQ2pDLENBQUM7SUFFRDs7OztPQUlHO0lBQ0gsV0FBVyxDQUFDLEtBQWE7UUFDdkIsT0FBTyxrQkFBa0IsQ0FBQyxLQUFLLENBQUMsQ0FBQztJQUNuQyxDQUFDO0NBQ0Y7QUFHRCxTQUFTLFdBQVcsQ0FBQyxTQUFpQixFQUFFLEtBQXlCO0lBQy9ELE1BQU0sR0FBRyxHQUFHLElBQUksR0FBRyxFQUFvQixDQUFDO0lBQ3hDLElBQUksU0FBUyxDQUFDLE1BQU0sR0FBRyxDQUFDLEVBQUU7UUFDeEIsZ0dBQWdHO1FBQ2hHLGdHQUFnRztRQUNoRywrREFBK0Q7UUFDL0QsTUFBTSxNQUFNLEdBQWEsU0FBUyxDQUFDLE9BQU8sQ0FBQyxLQUFLLEVBQUUsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLEdBQUcsQ0FBQyxDQUFDO1FBQ2pFLE1BQU0sQ0FBQyxPQUFPLENBQUMsQ0FBQyxLQUFhLEVBQUUsRUFBRTtZQUMvQixNQUFNLEtBQUssR0FBRyxLQUFLLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxDQUFDO1lBQ2pDLE1BQU0sQ0FBQyxH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QUksQ0FBQyxNQUFNLENBQUMsR0FBRyxFQUFFLENBQUMsQ0FBQyxDQUFDOzZCQUNyQjs0QkFDRCxJQUFJLElBQUksQ0FBQyxNQUFNLEdBQUcsQ0FBQyxFQUFFO2dDQUNuQixJQUFJLENBQUMsR0FBSSxDQUFDLEdBQUcsQ0FBQyxNQUFNLENBQUMsS0FBSyxFQUFFLElBQUksQ0FBQyxDQUFDOzZCQUNuQztpQ0FBTTtnQ0FDTCxJQUFJLENBQUMsR0FBSSxDQUFDLE1BQU0sQ0FBQyxNQUFNLENBQUMsS0FBSyxDQUFDLENBQUM7NkJBQ2hDO3lCQUNGOzZCQUFNOzRCQUNMLElBQUksQ0FBQyxHQUFJLENBQUMsTUFBTSxDQUFDLE1BQU0sQ0FBQyxLQUFLLENBQUMsQ0FBQzs0QkFDL0IsTUFBTTt5QkFDUDtpQkFDSjtZQUNILENBQUMsQ0FBQyxDQUFDO1lBQ0gsSUFBSSxDQUFDLFNBQVMsR0FBRyxJQUFJLENBQUMsT0FBTyxHQUFHLElBQUksQ0FBQztTQUN0QztJQUNILENBQUM7Q0FDRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG4vKipcbiAqIEEgY29kZWMgZm9yIGVuY29kaW5nIGFuZCBkZWNvZGluZyBwYXJhbWV0ZXJzIGluIFVSTHMuXG4gKlxuICogVXNlZCBieSBgSHR0cFBhcmFtc2AuXG4gKlxuICogQHB1YmxpY0FwaVxuICoqL1xuZXhwb3J0IGludGVyZmFjZSBIdHRwUGFyYW1ldGVyQ29kZWMge1xuICBlbmNvZGVLZXkoa2V5OiBzdHJpbmcpOiBzdHJpbmc7XG4gIGVuY29kZVZhbHVlKHZhbHVlOiBzdHJpbmcpOiBzdHJpbmc7XG5cbiAgZGVjb2RlS2V5KGtleTogc3RyaW5nKTogc3RyaW5nO1xuICBkZWNvZGVWYWx1ZSh2YWx1ZTogc3RyaW5nKTogc3RyaW5nO1xufVxuXG4vKipcbiAqIFByb3ZpZGVzIGVuY29kaW5nIGFuZCBkZWNvZGluZyBvZiBVUkwgcGFyYW1ldGVyIGFuZCBxdWVyeS1zdHJpbmcgdmFsdWVzLlxuICpcbiAqIFNlcmlhbGl6ZXMgYW5kIHBhcnNlcyBVUkwgcGFyYW1ldGVyIGtleXMgYW5kIHZhbHVlcyB0byBlbmNvZGUgYW5kIGRlY29kZSB0aGVtLlxuICogSWYgeW91IHBhc3MgVVJMIHF1ZXJ5IHBhcmFtZXRlcnMgd2l0aG91dCBlbmNvZGluZyxcbiAqIHRoZSBxdWVyeSBwYXJhbWV0ZXJzIGNhbiBiZSBtaXNpbnRlcnByZXRlZCBhdCB0aGUgcmVjZWl2aW5nIGVuZC5cbiAqXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgY2xhc3MgSHR0cFVybEVuY29kaW5nQ29kZWMgaW1wbGVtZW50cyBIdHRwUGFyYW1ldGVyQ29kZWMge1xuICAvKipcbiAgICogRW5jb2RlcyBhIGtleSBuYW1lIGZvciBhIFVSTCBwYXJhbWV0ZXIgb3IgcXVlcnktc3RyaW5nLlxuICAgKiBAcGFyYW0ga2V5IFRoZSBrZXkgbmFtZS5cbiAgICogQHJldHVybnMgVGhlIGVuY29kZWQga2V5IG5hbWUuXG4gICAqL1xuICBlbmNvZGVLZXkoa2V5OiBzdHJpbmcpOiBzdHJpbmcge1xuICAgIHJldHVybiBzdGFuZGFyZEVuY29kaW5nKGtleSk7XG4gIH1cblxuICAvKipcbiAgICogRW5jb2RlcyB0aGUgdmFsdWUgb2YgYSBVUkwgcGFyYW1ldGVyIG9yIHF1ZXJ5LXN0cmluZy5cbiAgICogQHBhcmFtIHZhbHVlIFRoZSB2YWx1ZS5cbiAgICogQHJldHVybnMgVGhlIGVuY29kZWQgdmFsdWUuXG4gICAqL1xuICBlbmNvZGVWYWx1ZSh2YWx1ZTogc3RyaW5nKTogc3RyaW5nIHtcbiAgICByZXR1cm4gc3RhbmRhcmRFbmNvZGluZyh2YWx1ZSk7XG4gIH1cblxuICAvKipcbiAgICogRGVjb2RlcyBhbiBlbmNvZGVkIFVSTCBwYXJhbWV0ZXIgb3IgcXVlcnktc3RyaW5nIGtleS5cbiAgICogQHBhcmFtIGtleSBUaGUgZW5jb2RlZCBrZXkgbmFtZS5cbiAgICogQHJldHVybnMgVGhlIGRlY29kZWQga2V5IG5hbWUuXG4gICAqL1xuICBkZWNvZGVLZXkoa2V5OiBzdHJpbmcpOiBzdHJpbmcge1xuICAgIHJldHVybiBkZWNvZGVVUklDb21wb25lbnQoa2V5KTtcbiAgfVxuXG4gIC8qKlxuICAgKiBEZWNvZGVzIGFuIGVuY29kZWQgVVJMIHBhcmFtZXRlciBvciBxdWVyeS1zdHJpbmcgdmFsdWUuXG4gICAqIEBwYXJhbSB2YWx1ZSBUaGUgZW5jb2RlZCB2YWx1ZS5cbiAgICogQHJldHVybnMgVGhlIGRlY29kZWQgdmFsdWUuXG4gICAqL1xuICBkZWNvZGVWYWx1ZSh2YWx1ZTogc3RyaW5nKSB7XG4gICAgcmV0dXJuIGRlY29kZVVSSUNvbXBvbmVudCh2YWx1ZSk7XG4gIH1cbn1cblxuXG5mdW5jdGlvbiBwYXJhbVBhcnNlcihyYXdQYXJhbXM6IHN0cmluZywgY29kZWM6IEh0dHBQYXJhbWV0ZXJDb2RlYyk6IE1hcDxzdHJpbmcsIHN0cmluZ1tdPiB7XG4gIGNvbnN0IG1hcCA9IG5ldyBNYXA8c3RyaW5nLCBzdHJpbmdbXT4oKTtcbiAgaWYgKHJhd1BhcmFtcy5sZW5ndGggPiAwKSB7XG4gICAgLy8gVGhlIGB3aW5kb3cubG9jYXRpb24uc2VhcmNoYCBjYW4gYmUgdXNlZCB3aGlsZSBjcmVhdGluZyBhbiBpbnN0YW5jZSBvZiB0aGUgYEh0dHBQYXJhbXNgIGNsYXNzXG4gICAgLy8gKGUuZy4gYG5ldyBIdHRwUGFyYW1zKHsgZnJvbVN0cmluZzogd2luZG93LmxvY2F0aW9uLnNlYXJjaCB9KWApLiBUaGUgYHdpbmRvdy5sb2NhdGlvbi5zZWFyY2hgXG4gICAgLy8gbWF5IHN0YXJ0IHdpdGggdGhlIGA/YCBjaGFyLCBzbyB3ZSBzdHJpcCBpdCBpZiBpdCdzIHByZXNlbnQuXG4gICAgY29uc3QgcGFyYW1zOiBzdHJpbmdbXSA9IHJhd1BhcmFtcy5yZXBsYWNlKC9eXFw/LywgJycpLnNwbGl0KCcmJyk7XG4gICAgcGFyYW1zLmZvckVhY2goKHBhcmFtOiBzdHJpbmcpID0+IHtcbiAgICAgIGNvbnN0IGVxSWR4ID0gcGFyYW0uaW5kZXhPZignPScpO1xuICAgICAgY29uc3QgW2tleSwgdmFsXTogc3RyaW5nW10gPSBlcUlkeCA9PSAtMSA/XG4gICAgICAgICAgW2NvZGVjLmRlY29kZUtleShwYXJhbSksICcnXSA6XG4gICAgICAgICAgW2NvZGVjLmRlY29kZUtleShwYXJhbS5zbGljZSgwLCBlcUlkeCkpLCBjb2RlYy5kZWNvZGVWYWx1ZShwYXJhbS5zbGljZShlcUlkeCArIDEpKV07XG4gICAgICBjb25zdCBsaXN0ID0gbWFwLmdldChrZXkpIHx8IFtdO1xuICAgICAgbGlzdC5wdXNoKHZhbCk7XG4gICAgICBtYXAuc2V0KGtleSwgbGlzdCk7XG4gICAgfSk7XG4gIH1cbiAgcmV0dXJuIG1hcDtcbn1cblxuLyoqXG4gKiBFbmNvZGUgaW5wdXQgc3RyaW5nIHdpdGggc3RhbmRhcmQgZW5jb2RlVVJJQ29tcG9uZW50IGFuZCB0aGVuIHVuLWVuY29kZSBzcGVjaWZpYyBjaGFyYWN0ZXJzLlxuICovXG5jb25zdCBTVEFOREFSRF9FTkNPRElOR19SRUdFWCA9IC8lKFxcZFthLWYwLTldKS9naTtcbmNvbnN0IFNUQU5EQVJEX0VOQ09ESU5HX1JFUExBQ0VNRU5UUzoge1t4OiBzdHJpbmddOiBzdHJpbmd9ID0ge1xuICAnNDAnOiAnQCcsXG4gICczQSc6ICc6JyxcbiAgJzI0JzogJyQnLFxuICAnMkMnOiAnLCcsXG4gICczQic6ICc7JyxcbiAgJzNEJzogJz0nLFxuICAnM0YnOiAnPycsXG4gICcyRic6ICcvJyxcbn07XG5cbmZ1bmN0aW9uIHN0YW5kYXJkRW5jb2Rpbmcodjogc3RyaW5nKTogc3RyaW5nIHtcbiAgcmV0dXJuIGVuY29kZVVSSUNvbXBvbmVudCh2KS5yZXBsYWNlKFxuICAgICAgU1RBTkRBUkRfRU5DT0RJTkdfUkVHRVgsIChzLCB0KSA9PiBTVEFOREFSRF9FTkNPRElOR19SRVBMQUNFTUVOVFNbdF0gPz8gcyk7XG59XG5cbmZ1bmN0aW9uIHZhbHVlVG9TdHJpbmcodmFsdWU6IHN0cmluZ3xudW1iZXJ8Ym9vbGVhbik6IHN0cmluZyB7XG4gIHJldHVybiBgJHt2YWx1ZX1gO1xufVxuXG5pbnRlcmZhY2UgVXBkYXRlIHtcbiAgcGFyYW06IHN0cmluZztcbiAgdmFsdWU/OiBzdHJpbmd8bnVtYmVyfGJvb2xlYW47XG4gIG9wOiAnYSd8J2QnfCdzJztcbn1cblxuLyoqXG4gKiBPcHRpb25zIHVzZWQgdG8gY29uc3RydWN0IGFuIGBIdHRwUGFyYW1zYCBpbnN0YW5jZS5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgSHR0cFBhcmFtc09wdGlvbnMge1xuICAvKipcbiAgICogU3RyaW5nIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBIVFRQIHBhcmFtZXRlcnMgaW4gVVJMLXF1ZXJ5LXN0cmluZyBmb3JtYXQuXG4gICAqIE11dHVhbGx5IGV4Y2x1c2l2ZSB3aXRoIGBmcm9tT2JqZWN0YC5cbiAgICovXG4gIGZyb21TdHJpbmc/OiBzdHJpbmc7XG5cbiAgLyoqIE9iamVjdCBtYXAgb2YgdGhlIEhUVFAgcGFyYW1ldGVycy4gTXV0dWFsbHkgZXhjbHVzaXZlIHdpdGggYGZyb21TdHJpbmdgLiAqL1xuICBmcm9tT2JqZWN0Pzoge1twYXJhbTogc3RyaW5nXTogc3RyaW5nfG51bWJlcnxib29sZWFufFJlYWRvbmx5QXJyYXk8c3RyaW5nfG51bWJlcnxib29sZWFuPn07XG5cbiAgLyoqIEVuY29kaW5nIGNvZGVjIHVzZWQgdG8gcGFyc2UgYW5kIHNlcmlhbGl6ZSB0aGUgcGFyYW1ldGVycy4gKi9cbiAgZW5jb2Rlcj86IEh0dHBQYXJhbWV0ZXJDb2RlYztcbn1cblxuLyoqXG4gKiBBbiBIVFRQIHJlcXVlc3QvcmVzcG9uc2UgYm9keSB0aGF0IHJlcHJlc2VudHMgc2VyaWFsaXplZCBwYXJhbWV0ZXJzLFxuICogcGVyIHRoZSBNSU1FIHR5cGUgYGFwcGxpY2F0aW9uL3gtd3d3LWZvcm0tdXJsZW5jb2RlZGAuXG4gKlxuICogVGhpcyBjbGFzcyBpcyBpbW11dGFibGU7IGFsbCBtdXRhdGlvbiBvcGVyYXRpb25zIHJldHVybiBhIG5ldyBpbnN0YW5jZS5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBIdHRwUGFyYW1zIHtcbiAgcHJpdmF0ZSBtYXA6IE1hcDxzdHJpbmcsIHN0cmluZ1tdPnxudWxsO1xuICBwcml2YXRlIGVuY29kZXI6IEh0dHBQYXJhbWV0ZXJDb2RlYztcbiAgcHJpdmF0ZSB1cGRhdGVzOiBVcGRhdGVbXXxudWxsID0gbnVsbDtcbiAgcHJpdmF0ZSBjbG9uZUZyb206IEh0dHBQYXJhbXN8bnVsbCA9IG51bGw7XG5cbiAgY29uc3RydWN0b3Iob3B0aW9uczogSHR0cFBhcmFtc09wdGlvbnMgPSB7fSBhcyBIdHRwUGFyYW1zT3B0aW9ucykge1xuICAgIHRoaXMuZW5jb2RlciA9IG9wdGlvbnMuZW5jb2RlciB8fCBuZXcgSHR0cFVybEVuY29kaW5nQ29kZWMoKTtcbiAgICBpZiAoISFvcHRpb25zLmZyb21TdHJpbmcpIHtcbiAgICAgIGlmICghIW9wdGlvbnMuZnJvbU9iamVjdCkge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYENhbm5vdCBzcGVjaWZ5IGJvdGggZnJvbVN0cmluZyBhbmQgZnJvbU9iamVjdC5gKTtcbiAgICAgIH1cbiAgICAgIHRoaXMubWFwID0gcGFyYW1QYXJzZXIob3B0aW9ucy5mcm9tU3RyaW5nLCB0aGlzLmVuY29kZXIpO1xuICAgIH0gZWxzZSBpZiAoISFvcHRpb25zLmZyb21PYmplY3QpIHtcbiAgICAgIHRoaXMubWFwID0gbmV3IE1hcDxzdHJpbmcsIHN0cmluZ1tdPigpO1xuICAgICAgT2JqZWN0LmtleXMob3B0aW9ucy5mcm9tT2JqZWN0KS5mb3JFYWNoKGtleSA9PiB7XG4gICAgICAgIGNvbnN0IHZhbHVlID0gKG9wdGlvbnMuZnJvbU9iamVjdCBhcyBhbnkpW2tleV07XG4gICAgICAgIC8vIGNvbnZlcnQgdGhlIHZhbHVlcyB0byBzdHJpbmdzXG4gICAgICAgIGNvbnN0IHZhbHVlcyA9IEFycmF5LmlzQXJyYXkodmFsdWUpID8gdmFsdWUubWFwKHZhbHVlVG9TdHJpbmcpIDogW3ZhbHVlVG9TdHJpbmcodmFsdWUpXTtcbiAgICAgICAgdGhpcy5tYXAhLnNldChrZXksIHZhbHVlcyk7XG4gICAgICB9KTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5tYXAgPSBudWxsO1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBSZXBvcnRzIHdoZXRoZXIgdGhlIGJvZHkgaW5jbHVkZXMgb25lIG9yIG1vcmUgdmFsdWVzIGZvciBhIGdpdmVuIHBhcmFtZXRlci5cbiAgICogQHBhcmFtIHBhcmFtIFRoZSBwYXJhbWV0ZXIgbmFtZS5cbiAgICogQHJldHVybnMgVHJ1ZSBpZiB0aGUgcGFyYW1ldGVyIGhhcyBvbmUgb3IgbW9yZSB2YWx1ZXMsXG4gICAqIGZhbHNlIGlmIGl0IGhhcyBubyB2YWx1ZSBvciBpcyBub3QgcHJlc2VudC5cbiAgICovXG4gIGhhcyhwYXJhbTogc3RyaW5nKTogYm9vbGVhbiB7XG4gICAgdGhpcy5pbml0KCk7XG4gICAgcmV0dXJuIHRoaXMubWFwIS5oYXMocGFyYW0pO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyB0aGUgZmlyc3QgdmFsdWUgZm9yIGEgcGFyYW1ldGVyLlxuICAgKiBAcGFyYW0gcGFyYW0gVGhlIHBhcmFtZXRlciBuYW1lLlxuICAgKiBAcmV0dXJucyBUaGUgZmlyc3QgdmFsdWUgb2YgdGhlIGdpdmVuIHBhcmFtZXRlcixcbiAgICogb3IgYG51bGxgIGlmIHRoZSBwYXJhbWV0ZXIgaXMgbm90IHByZXNlbnQuXG4gICAqL1xuICBnZXQocGFyYW06IHN0cmluZyk6IHN0cmluZ3xudWxsIHtcbiAgICB0aGlzLmluaXQoKTtcbiAgICBjb25zdCByZXMgPSB0aGlzLm1hcCEuZ2V0KHBhcmFtKTtcbiAgICByZXR1cm4gISFyZXMgPyByZXNbMF0gOiBudWxsO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyBhbGwgdmFsdWVzIGZvciBhICBwYXJhbWV0ZXIuXG4gICAqIEBwYXJhbSBwYXJhbSBUaGUgcGFyYW1ldGVyIG5hbWUuXG4gICAqIEByZXR1cm5zIEFsbCB2YWx1ZXMgaW4gYSBzdHJpbmcgYXJyYXksXG4gICAqIG9yIGBudWxsYCBpZiB0aGUgcGFyYW1ldGVyIG5vdCBwcmVzZW50LlxuICAgKi9cbiAgZ2V0QWxsKHBhcmFtOiBzdHJpbmcpOiBzdHJpbmdbXXxudWxsIHtcbiAgICB0aGlzLmluaXQoKTtcbiAgICByZXR1cm4gdGhpcy5tYXAhLmdldChwYXJhbSkgfHwgbnVsbDtcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZXMgYWxsIHRoZSBwYXJhbWV0ZXJzIGZvciB0aGlzIGJvZHkuXG4gICAqIEByZXR1cm5zIFRoZSBwYXJhbWV0ZXIgbmFtZXMgaW4gYSBzdHJpbmcgYXJyYXkuXG4gICAqL1xuICBrZXlzKCk6IHN0cmluZ1tdIHtcbiAgICB0aGlzLmluaXQoKTtcbiAgICByZXR1cm4gQXJyYXkuZnJvbSh0aGlzLm1hcCEua2V5cygpKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBBcHBlbmRzIGEgbmV3IHZhbHVlIHRvIGV4aXN0aW5nIHZhbHVlcyBmb3IgYSBwYXJhbWV0ZXIuXG4gICAqIEBwYXJhbSBwYXJhbSBUaGUgcGFyYW1ldGVyIG5hbWUuXG4gICAqIEBwYXJhbSB2YWx1ZSBUaGUgbmV3IHZhbHVlIHRvIGFkZC5cbiAgICogQHJldHVybiBBIG5ldyBib2R5IHdpdGggdGhlIGFwcGVuZGVkIHZhbHVlLlxuICAgKi9cbiAgYXBwZW5kKHBhcmFtOiBzdHJpbmcsIHZhbHVlOiBzdHJpbmd8bnVtYmVyfGJvb2xlYW4pOiBIdHRwUGFyYW1zIHtcbiAgICByZXR1cm4gdGhpcy5jbG9uZSh7cGFyYW0sIHZhbHVlLCBvcDogJ2EnfSk7XG4gIH1cblxuICAvKipcbiAgICogQ29uc3RydWN0cyBhIG5ldyBib2R5IHdpdGggYXBwZW5kZWQgdmFsdWVzIGZvciB0aGUgZ2l2ZW4gcGFyYW1ldGVyIG5hbWUuXG4gICAqIEBwYXJhbSBwYXJhbXMgcGFyYW1ldGVycyBhbmQgdmFsdWVzXG4gICAqIEByZXR1cm4gQSBuZXcgYm9keSB3aXRoIHRoZSBuZXcgdmFsdWUuXG4gICAqL1xuICBhcHBlbmRBbGwocGFyYW1zOiB7W3BhcmFtOiBzdHJpbmddOiBzdHJpbmd8bnVtYmVyfGJvb2xlYW58UmVhZG9ubHlBcnJheTxzdHJpbmd8bnVtYmVyfGJvb2xlYW4+fSk6XG4gICAgICBIdHRwUGFyYW1zIHtcbiAgICBjb25zdCB1cGRhdGVzOiBVcGRhdGVbXSA9IFtdO1xuICAgIE9iamVjdC5rZXlzKHBhcmFtcykuZm9yRWFjaChwYXJhbSA9PiB7XG4gICAgICBjb25zdCB2YWx1ZSA9IHBhcmFtc1twYXJhbV07XG4gICAgICBpZiAoQXJyYXkuaXNBcnJheSh2YWx1ZSkpIHtcbiAgICAgICAgdmFsdWUuZm9yRWFjaChfdmFsdWUgPT4ge1xuICAgICAgICAgIHVwZGF0ZXMucHVzaCh7cGFyYW0sIHZhbHVlOiBfdmFsdWUsIG9wOiAnYSd9KTtcbiAgICAgICAgfSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB1cGRhdGVzLnB1c2goe3BhcmFtLCB2YWx1ZTogdmFsdWUgYXMgKHN0cmluZyB8IG51bWJlciB8IGJvb2xlYW4pLCBvcDogJ2EnfSk7XG4gICAgICB9XG4gICAgfSk7XG4gICAgcmV0dXJuIHRoaXMuY2xvbmUodXBkYXRlcyk7XG4gIH1cblxuICAvKipcbiAgICogUmVwbGFjZXMgdGhlIHZhbHVlIGZvciBhIHBhcmFtZXRlci5cbiAgICogQHBhcmFtIHBhcmFtIFRoZSBwYXJhbWV0ZXIgbmFtZS5cbiAgICogQHBhcmFtIHZhbHVlIFRoZSBuZXcgdmFsdWUuXG4gICAqIEByZXR1cm4gQSBuZXcgYm9keSB3aXRoIHRoZSBuZXcgdmFsdWUuXG4gICAqL1xuICBzZXQocGFyYW06IHN0cmluZywgdmFsdWU6IHN0cmluZ3xudW1iZXJ8Ym9vbGVhbik6IEh0dHBQYXJhbXMge1xuICAgIHJldHVybiB0aGlzLmNsb25lKHtwYXJhbSwgdmFsdWUsIG9wOiAncyd9KTtcbiAgfVxuXG4gIC8qKlxuICAgKiBSZW1vdmVzIGEgZ2l2ZW4gdmFsdWUgb3IgYWxsIHZhbHVlcyBmcm9tIGEgcGFyYW1ldGVyLlxuICAgKiBAcGFyYW0gcGFyYW0gVGhlIHBhcmFtZXRlciBuYW1lLlxuICAgKiBAcGFyYW0gdmFsdWUgVGhlIHZhbHVlIHRvIHJlbW92ZSwgaWYgcHJvdmlkZWQuXG4gICAqIEByZXR1cm4gQSBuZXcgYm9keSB3aXRoIHRoZSBnaXZlbiB2YWx1ZSByZW1vdmVkLCBvciB3aXRoIGFsbCB2YWx1ZXNcbiAgICogcmVtb3ZlZCBpZiBubyB2YWx1ZSBpcyBzcGVjaWZpZWQuXG4gICAqL1xuICBkZWxldGUocGFyYW06IHN0cmluZywgdmFsdWU/OiBzdHJpbmd8bnVtYmVyfGJvb2xlYW4pOiBIdHRwUGFyYW1zIHtcbiAgICByZXR1cm4gdGhpcy5jbG9uZSh7cGFyYW0sIHZhbHVlLCBvcDogJ2QnfSk7XG4gIH1cblxuICAvKipcbiAgICogU2VyaWFsaXplcyB0aGUgYm9keSB0byBhbiBlbmNvZGVkIHN0cmluZywgd2hlcmUga2V5LXZhbHVlIHBhaXJzIChzZXBhcmF0ZWQgYnkgYD1gKSBhcmVcbiAgICogc2VwYXJhdGVkIGJ5IGAmYHMuXG4gICAqL1xuICB0b1N0cmluZygpOiBzdHJpbmcge1xuICAgIHRoaXMuaW5pdCgpO1xuICAgIHJldHVybiB0aGlzLmtleXMoKVxuICAgICAgICAubWFwKGtleSA9PiB7XG4gICAgICAgICAgY29uc3QgZUtleSA9IHRoaXMuZW5jb2Rlci5lbmNvZGVLZXkoa2V5KTtcbiAgICAgICAgICAvLyBgYTogWycxJ11gIHByb2R1Y2VzIGAnYT0xJ2BcbiAgICAgICAgICAvLyBgYjogW11gIHByb2R1Y2VzIGAnJ2BcbiAgICAgICAgICAvLyBgYzogWycxJywgJzInXWAgcHJvZHVjZXMgYCdjPTEmYz0yJ2BcbiAgICAgICAgICByZXR1cm4gdGhpcy5tYXAhLmdldChrZXkpIS5tYXAodmFsdWUgPT4gZUtleSArICc9JyArIHRoaXMuZW5jb2Rlci5lbmNvZGVWYWx1ZSh2YWx1ZSkpXG4gICAgICAgICAgICAgIC5qb2luKCcmJyk7XG4gICAgICAgIH0pXG4gICAgICAgIC8vIGZpbHRlciBvdXQgZW1wdHkgdmFsdWVzIGJlY2F1c2UgYGI6IFtdYCBwcm9kdWNlcyBgJydgXG4gICAgICAgIC8vIHdoaWNoIHJlc3VsdHMgaW4gYGE9MSYmYz0xJmM9MmAgaW5zdGVhZCBvZiBgYT0xJmM9MSZjPTJgIGlmIHdlIGRvbid0XG4gICAgICAgIC5maWx0ZXIocGFyYW0gPT4gcGFyYW0gIT09ICcnKVxuICAgICAgICAuam9pbignJicpO1xuICB9XG5cbiAgcHJpdmF0ZSBjbG9uZSh1cGRhdGU6IFVwZGF0ZXxVcGRhdGVbXSk6IEh0dHBQYXJhbXMge1xuICAgIGNvbnN0IGNsb25lID0gbmV3IEh0dHBQYXJhbXMoe2VuY29kZXI6IHRoaXMuZW5jb2Rlcn0gYXMgSHR0cFBhcmFtc09wdGlvbnMpO1xuICAgIGNsb25lLmNsb25lRnJvbSA9IHRoaXMuY2xvbmVGcm9tIHx8IHRoaXM7XG4gICAgY2xvbmUudXBkYXRlcyA9ICh0aGlzLnVwZGF0ZXMgfHwgW10pLmNvbmNhdCh1cGRhdGUpO1xuICAgIHJldHVybiBjbG9uZTtcbiAgfVxuXG4gIHByaXZhdGUgaW5pdCgpIHtcbiAgICBpZiAodGhpcy5tYXAgPT09IG51bGwpIHtcbiAgICAgIHRoaXMubWFwID0gbmV3IE1hcDxzdHJpbmcsIHN0cmluZ1tdPigpO1xuICAgIH1cbiAgICBpZiAodGhpcy5jbG9uZUZyb20gIT09IG51bGwpIHtcbiAgICAgIHRoaXMuY2xvbmVGcm9tLmluaXQoKTtcbiAgICAgIHRoaXMuY2xvbmVGcm9tLmtleXMoKS5mb3JFYWNoKGtleSA9PiB0aGlzLm1hcCEuc2V0KGtleSwgdGhpcy5jbG9uZUZyb20hLm1hcCEuZ2V0KGtleSkhKSk7XG4gICAgICB0aGlzLnVwZGF0ZXMhLmZvckVhY2godXBkYXRlID0+IHtcbiAgICAgICAgc3dpdGNoICh1cGRhdGUub3ApIHtcbiAgICAgICAgICBjYXNlICdhJzpcbiAgICAgICAgICBjYXNlICdzJzpcbiAgICAgICAgICAgIGNvbnN0IGJhc2UgPSAodXBkYXRlLm9wID09PSAnYScgPyB0aGlzLm1hcCEuZ2V0KHVwZGF0ZS5wYXJhbSkgOiB1bmRlZmluZWQpIHx8IFtdO1xuICAgICAgICAgICAgYmFzZS5wdXNoKHZhbHVlVG9TdHJpbmcodXBkYXRlLnZhbHVlISkpO1xuICAgICAgICAgICAgdGhpcy5tYXAhLnNldCh1cGRhdGUucGFyYW0sIGJhc2UpO1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgY2FzZSAnZCc6XG4gICAgICAgICAgICBpZiAodXBkYXRlLnZhbHVlICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgICAgICAgbGV0IGJhc2UgPSB0aGlzLm1hcCEuZ2V0KHVwZGF0ZS5wYXJhbSkgfHwgW107XG4gICAgICAgICAgICAgIGNvbnN0IGlkeCA9IGJhc2UuaW5kZXhPZih2YWx1ZVRvU3RyaW5nKHVwZGF0ZS52YWx1ZSkpO1xuICAgICAgICAgICAgICBpZiAoaWR4ICE9PSAtMSkge1xuICAgICAgICAgICAgICAgIGJhc2Uuc3BsaWNlKGlkeCwgMSk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgaWYgKGJhc2UubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgIHRoaXMubWFwIS5zZXQodXBkYXRlLnBhcmFtLCBiYXNlKTtcbiAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICB0aGlzLm1hcCEuZGVsZXRlKHVwZGF0ZS5wYXJhbSk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIHRoaXMubWFwIS5kZWxldGUodXBkYXRlLnBhcmFtKTtcbiAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgICAgdGhpcy5jbG9uZUZyb20gPSB0aGlzLnVwZGF0ZXMgPSBudWxsO1xuICAgIH1cbiAgfVxufVxuIl19