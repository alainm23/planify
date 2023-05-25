/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { HttpContext } from './context';
import { HttpHeaders } from './headers';
import { HttpParams } from './params';
/**
 * Determine whether the given HTTP method may include a body.
 */
function mightHaveBody(method) {
    switch (method) {
        case 'DELETE':
        case 'GET':
        case 'HEAD':
        case 'OPTIONS':
        case 'JSONP':
            return false;
        default:
            return true;
    }
}
/**
 * Safely assert whether the given value is an ArrayBuffer.
 *
 * In some execution environments ArrayBuffer is not defined.
 */
function isArrayBuffer(value) {
    return typeof ArrayBuffer !== 'undefined' && value instanceof ArrayBuffer;
}
/**
 * Safely assert whether the given value is a Blob.
 *
 * In some execution environments Blob is not defined.
 */
function isBlob(value) {
    return typeof Blob !== 'undefined' && value instanceof Blob;
}
/**
 * Safely assert whether the given value is a FormData instance.
 *
 * In some execution environments FormData is not defined.
 */
function isFormData(value) {
    return typeof FormData !== 'undefined' && value instanceof FormData;
}
/**
 * Safely assert whether the given value is a URLSearchParams instance.
 *
 * In some execution environments URLSearchParams is not defined.
 */
function isUrlSearchParams(value) {
    return typeof URLSearchParams !== 'undefined' && value instanceof URLSearchParams;
}
/**
 * An outgoing HTTP request with an optional typed body.
 *
 * `HttpRequest` represents an outgoing request, including URL, method,
 * headers, body, and other request configuration options. Instances should be
 * assumed to be immutable. To modify a `HttpRequest`, the `clone`
 * method should be used.
 *
 * @publicApi
 */
export class HttpRequest {
    constructor(method, url, third, fourth) {
        this.url = url;
        /**
         * The request body, or `null` if one isn't set.
         *
         * Bodies are not enforced to be immutable, as they can include a reference to any
         * user-defined data type. However, interceptors should take care to preserve
         * idempotence by treating them as such.
         */
        this.body = null;
        /**
         * Whether this request should be made in a way that exposes progress events.
         *
         * Progress events are expensive (change detection runs on each event) and so
         * they should only be requested if the consumer intends to monitor them.
         */
        this.reportProgress = false;
        /**
         * Whether this request should be sent with outgoing credentials (cookies).
         */
        this.withCredentials = false;
        /**
         * The expected response type of the server.
         *
         * This is used to parse the response appropriately before returning it to
         * the requestee.
         */
        this.responseType = 'json';
        this.method = method.toUpperCase();
        // Next, need to figure out which argument holds the HttpRequestInit
        // options, if any.
        let options;
        // Check whether a body argument is expected. The only valid way to omit
        // the body argument is to use a known no-body method like GET.
        if (mightHaveBody(this.method) || !!fourth) {
            // Body is the third argument, options are the fourth.
            this.body = (third !== undefined) ? third : null;
            options = fourth;
        }
        else {
            // No body required, options are the third argument. The body stays null.
            options = third;
        }
        // If options have been passed, interpret them.
        if (options) {
            // Normalize reportProgress and withCredentials.
            this.reportProgress = !!options.reportProgress;
            this.withCredentials = !!options.withCredentials;
            // Override default response type of 'json' if one is provided.
            if (!!options.responseType) {
                this.responseType = options.responseType;
            }
            // Override headers if they're provided.
            if (!!options.headers) {
                this.headers = options.headers;
            }
            if (!!options.context) {
                this.context = options.context;
            }
            if (!!options.params) {
                this.params = options.params;
            }
        }
        // If no headers have been passed in, construct a new HttpHeaders instance.
        if (!this.headers) {
            this.headers = new HttpHeaders();
        }
        // If no context have been passed in, construct a new HttpContext instance.
        if (!this.context) {
            this.context = new HttpContext();
        }
        // If no parameters have been passed in, construct a new HttpUrlEncodedParams instance.
        if (!this.params) {
            this.params = new HttpParams();
            this.urlWithParams = url;
        }
        else {
            // Encode the parameters to a string in preparation for inclusion in the URL.
            const params = this.params.toString();
            if (params.length === 0) {
                // No parameters, the visible URL is just the URL given at creation time.
                this.urlWithParams = url;
            }
            else {
                // Does the URL already have query parameters? Look for '?'.
                const qIdx = url.indexOf('?');
                // There are 3 cases to handle:
                // 1) No existing parameters -> append '?' followed by params.
                // 2) '?' exists and is followed by existing query string ->
                //    append '&' followed by params.
                // 3) '?' exists at the end of the url -> append params directly.
                // This basically amounts to determining the character, if any, with
                // which to join the URL and parameters.
                const sep = qIdx === -1 ? '?' : (qIdx < url.length - 1 ? '&' : '');
                this.urlWithParams = url + sep + params;
            }
        }
    }
    /**
     * Transform the free-form body into a serialized format suitable for
     * transmission to the server.
     */
    serializeBody() {
        // If no body is present, no need to serialize it.
        if (this.body === null) {
            return null;
        }
        // Check whether the body is already in a serialized form. If so,
        // it can just be returned directly.
        if (isArrayBuffer(this.body) || isBlob(this.body) || isFormData(this.body) ||
            isUrlSearchParams(this.body) || typeof this.body === 'string') {
            return this.body;
        }
        // Check whether the body is an instance of HttpUrlEncodedParams.
        if (this.body instanceof HttpParams) {
            return this.body.toString();
        }
        // Check whether the body is an object or array, and serialize with JSON if so.
        if (typeof this.body === 'object' || typeof this.body === 'boolean' ||
            Array.isArray(this.body)) {
            return JSON.stringify(this.body);
        }
        // Fall back on toString() for everything else.
        return this.body.toString();
    }
    /**
     * Examine the body and attempt to infer an appropriate MIME type
     * for it.
     *
     * If no such type can be inferred, this method will return `null`.
     */
    detectContentTypeHeader() {
        // An empty body has no content type.
        if (this.body === null) {
            return null;
        }
        // FormData bodies rely on the browser's content type assignment.
        if (isFormData(this.body)) {
            return null;
        }
        // Blobs usually have their own content type. If it doesn't, then
        // no type can be inferred.
        if (isBlob(this.body)) {
            return this.body.type || null;
        }
        // Array buffers have unknown contents and thus no type can be inferred.
        if (isArrayBuffer(this.body)) {
            return null;
        }
        // Technically, strings could be a form of JSON data, but it's safe enough
        // to assume they're plain strings.
        if (typeof this.body === 'string') {
            return 'text/plain';
        }
        // `HttpUrlEncodedParams` has its own content-type.
        if (this.body instanceof HttpParams) {
            return 'application/x-www-form-urlencoded;charset=UTF-8';
        }
        // Arrays, objects, boolean and numbers will be encoded as JSON.
        if (typeof this.body === 'object' || typeof this.body === 'number' ||
            typeof this.body === 'boolean') {
            return 'application/json';
        }
        // No type could be inferred.
        return null;
    }
    clone(update = {}) {
        // For method, url, and responseType, take the current value unless
        // it is overridden in the update hash.
        const method = update.method || this.method;
        const url = update.url || this.url;
        const responseType = update.responseType || this.responseType;
        // The body is somewhat special - a `null` value in update.body means
        // whatever current body is present is being overridden with an empty
        // body, whereas an `undefined` value in update.body implies no
        // override.
        const body = (update.body !== undefined) ? update.body : this.body;
        // Carefully handle the boolean options to differentiate between
        // `false` and `undefined` in the update args.
        const withCredentials = (update.withCredentials !== undefined) ? update.withCredentials : this.withCredentials;
        const reportProgress = (update.reportProgress !== undefined) ? update.reportProgress : this.reportProgress;
        // Headers and params may be appended to if `setHeaders` or
        // `setParams` are used.
        let headers = update.headers || this.headers;
        let params = update.params || this.params;
        // Pass on context if needed
        const context = update.context ?? this.context;
        // Check whether the caller has asked to add headers.
        if (update.setHeaders !== undefined) {
            // Set every requested header.
            headers =
                Object.keys(update.setHeaders)
                    .reduce((headers, name) => headers.set(name, update.setHeaders[name]), headers);
        }
        // Check whether the caller has asked to set params.
        if (update.setParams) {
            // Set every requested param.
            params = Object.keys(update.setParams)
                .reduce((params, param) => params.set(param, update.setParams[param]), params);
        }
        // Finally, construct the new HttpRequest using the pieces from above.
        return new HttpRequest(method, url, body, {
            params,
            headers,
            context,
            reportProgress,
            responseType,
            withCredentials,
        });
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicmVxdWVzdC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvbW1vbi9odHRwL3NyYy9yZXF1ZXN0LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSxXQUFXLENBQUM7QUFDdEMsT0FBTyxFQUFDLFdBQVcsRUFBQyxNQUFNLFdBQVcsQ0FBQztBQUN0QyxPQUFPLEVBQUMsVUFBVSxFQUFDLE1BQU0sVUFBVSxDQUFDO0FBaUJwQzs7R0FFRztBQUNILFNBQVMsYUFBYSxDQUFDLE1BQWM7SUFDbkMsUUFBUSxNQUFNLEVBQUU7UUFDZCxLQUFLLFFBQVEsQ0FBQztRQUNkLEtBQUssS0FBSyxDQUFDO1FBQ1gsS0FBSyxNQUFNLENBQUM7UUFDWixLQUFLLFNBQVMsQ0FBQztRQUNmLEtBQUssT0FBTztZQUNWLE9BQU8sS0FBSyxDQUFDO1FBQ2Y7WUFDRSxPQUFPLElBQUksQ0FBQztLQUNmO0FBQ0gsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxTQUFTLGFBQWEsQ0FBQyxLQUFVO0lBQy9CLE9BQU8sT0FBTyxXQUFXLEtBQUssV0FBVyxJQUFJLEtBQUssWUFBWSxXQUFXLENBQUM7QUFDNUUsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxTQUFTLE1BQU0sQ0FBQyxLQUFVO0lBQ3hCLE9BQU8sT0FBTyxJQUFJLEtBQUssV0FBVyxJQUFJLEtBQUssWUFBWSxJQUFJLENBQUM7QUFDOUQsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxTQUFTLFVBQVUsQ0FBQyxLQUFVO0lBQzVCLE9BQU8sT0FBTyxRQUFRLEtBQUssV0FBVyxJQUFJLEtBQUssWUFBWSxRQUFRLENBQUM7QUFDdEUsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxTQUFTLGlCQUFpQixDQUFDLEtBQVU7SUFDbkMsT0FBTyxPQUFPLGVBQWUsS0FBSyxXQUFXLElBQUksS0FBSyxZQUFZLGVBQWUs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QkFBNEI7UUFDNUIsTUFBTSxPQUFPLEdBQUcsTUFBTSxDQUFDLE9BQU8sSUFBSSxJQUFJLENBQUMsT0FBTyxDQUFDO1FBRS9DLHFEQUFxRDtRQUNyRCxJQUFJLE1BQU0sQ0FBQyxVQUFVLEtBQUssU0FBUyxFQUFFO1lBQ25DLDhCQUE4QjtZQUM5QixPQUFPO2dCQUNILE1BQU0sQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLFVBQVUsQ0FBQztxQkFDekIsTUFBTSxDQUFDLENBQUMsT0FBTyxFQUFFLElBQUksRUFBRSxFQUFFLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxJQUFJLEVBQUUsTUFBTSxDQUFDLFVBQVcsQ0FBQyxJQUFJLENBQUMsQ0FBQyxFQUFFLE9BQU8sQ0FBQyxDQUFDO1NBQzFGO1FBRUQsb0RBQW9EO1FBQ3BELElBQUksTUFBTSxDQUFDLFNBQVMsRUFBRTtZQUNwQiw2QkFBNkI7WUFDN0IsTUFBTSxHQUFHLE1BQU0sQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLFNBQVMsQ0FBQztpQkFDeEIsTUFBTSxDQUFDLENBQUMsTUFBTSxFQUFFLEtBQUssRUFBRSxFQUFFLENBQUMsTUFBTSxDQUFDLEdBQUcsQ0FBQyxLQUFLLEVBQUUsTUFBTSxDQUFDLFNBQVUsQ0FBQyxLQUFLLENBQUMsQ0FBQyxFQUFFLE1BQU0sQ0FBQyxDQUFDO1NBQzlGO1FBRUQsc0VBQXNFO1FBQ3RFLE9BQU8sSUFBSSxXQUFXLENBQUMsTUFBTSxFQUFFLEdBQUcsRUFBRSxJQUFJLEVBQUU7WUFDeEMsTUFBTTtZQUNOLE9BQU87WUFDUCxPQUFPO1lBQ1AsY0FBYztZQUNkLFlBQVk7WUFDWixlQUFlO1NBQ2hCLENBQUMsQ0FBQztJQUNMLENBQUM7Q0FDRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0h0dHBDb250ZXh0fSBmcm9tICcuL2NvbnRleHQnO1xuaW1wb3J0IHtIdHRwSGVhZGVyc30gZnJvbSAnLi9oZWFkZXJzJztcbmltcG9ydCB7SHR0cFBhcmFtc30gZnJvbSAnLi9wYXJhbXMnO1xuXG5cbi8qKlxuICogQ29uc3RydWN0aW9uIGludGVyZmFjZSBmb3IgYEh0dHBSZXF1ZXN0YHMuXG4gKlxuICogQWxsIHZhbHVlcyBhcmUgb3B0aW9uYWwgYW5kIHdpbGwgb3ZlcnJpZGUgZGVmYXVsdCB2YWx1ZXMgaWYgcHJvdmlkZWQuXG4gKi9cbmludGVyZmFjZSBIdHRwUmVxdWVzdEluaXQge1xuICBoZWFkZXJzPzogSHR0cEhlYWRlcnM7XG4gIGNvbnRleHQ/OiBIdHRwQ29udGV4dDtcbiAgcmVwb3J0UHJvZ3Jlc3M/OiBib29sZWFuO1xuICBwYXJhbXM/OiBIdHRwUGFyYW1zO1xuICByZXNwb25zZVR5cGU/OiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnO1xuICB3aXRoQ3JlZGVudGlhbHM/OiBib29sZWFuO1xufVxuXG4vKipcbiAqIERldGVybWluZSB3aGV0aGVyIHRoZSBnaXZlbiBIVFRQIG1ldGhvZCBtYXkgaW5jbHVkZSBhIGJvZHkuXG4gKi9cbmZ1bmN0aW9uIG1pZ2h0SGF2ZUJvZHkobWV0aG9kOiBzdHJpbmcpOiBib29sZWFuIHtcbiAgc3dpdGNoIChtZXRob2QpIHtcbiAgICBjYXNlICdERUxFVEUnOlxuICAgIGNhc2UgJ0dFVCc6XG4gICAgY2FzZSAnSEVBRCc6XG4gICAgY2FzZSAnT1BUSU9OUyc6XG4gICAgY2FzZSAnSlNPTlAnOlxuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIGRlZmF1bHQ6XG4gICAgICByZXR1cm4gdHJ1ZTtcbiAgfVxufVxuXG4vKipcbiAqIFNhZmVseSBhc3NlcnQgd2hldGhlciB0aGUgZ2l2ZW4gdmFsdWUgaXMgYW4gQXJyYXlCdWZmZXIuXG4gKlxuICogSW4gc29tZSBleGVjdXRpb24gZW52aXJvbm1lbnRzIEFycmF5QnVmZmVyIGlzIG5vdCBkZWZpbmVkLlxuICovXG5mdW5jdGlvbiBpc0FycmF5QnVmZmVyKHZhbHVlOiBhbnkpOiB2YWx1ZSBpcyBBcnJheUJ1ZmZlciB7XG4gIHJldHVybiB0eXBlb2YgQXJyYXlCdWZmZXIgIT09ICd1bmRlZmluZWQnICYmIHZhbHVlIGluc3RhbmNlb2YgQXJyYXlCdWZmZXI7XG59XG5cbi8qKlxuICogU2FmZWx5IGFzc2VydCB3aGV0aGVyIHRoZSBnaXZlbiB2YWx1ZSBpcyBhIEJsb2IuXG4gKlxuICogSW4gc29tZSBleGVjdXRpb24gZW52aXJvbm1lbnRzIEJsb2IgaXMgbm90IGRlZmluZWQuXG4gKi9cbmZ1bmN0aW9uIGlzQmxvYih2YWx1ZTogYW55KTogdmFsdWUgaXMgQmxvYiB7XG4gIHJldHVybiB0eXBlb2YgQmxvYiAhPT0gJ3VuZGVmaW5lZCcgJiYgdmFsdWUgaW5zdGFuY2VvZiBCbG9iO1xufVxuXG4vKipcbiAqIFNhZmVseSBhc3NlcnQgd2hldGhlciB0aGUgZ2l2ZW4gdmFsdWUgaXMgYSBGb3JtRGF0YSBpbnN0YW5jZS5cbiAqXG4gKiBJbiBzb21lIGV4ZWN1dGlvbiBlbnZpcm9ubWVudHMgRm9ybURhdGEgaXMgbm90IGRlZmluZWQuXG4gKi9cbmZ1bmN0aW9uIGlzRm9ybURhdGEodmFsdWU6IGFueSk6IHZhbHVlIGlzIEZvcm1EYXRhIHtcbiAgcmV0dXJuIHR5cGVvZiBGb3JtRGF0YSAhPT0gJ3VuZGVmaW5lZCcgJiYgdmFsdWUgaW5zdGFuY2VvZiBGb3JtRGF0YTtcbn1cblxuLyoqXG4gKiBTYWZlbHkgYXNzZXJ0IHdoZXRoZXIgdGhlIGdpdmVuIHZhbHVlIGlzIGEgVVJMU2VhcmNoUGFyYW1zIGluc3RhbmNlLlxuICpcbiAqIEluIHNvbWUgZXhlY3V0aW9uIGVudmlyb25tZW50cyBVUkxTZWFyY2hQYXJhbXMgaXMgbm90IGRlZmluZWQuXG4gKi9cbmZ1bmN0aW9uIGlzVXJsU2VhcmNoUGFyYW1zKHZhbHVlOiBhbnkpOiB2YWx1ZSBpcyBVUkxTZWFyY2hQYXJhbXMge1xuICByZXR1cm4gdHlwZW9mIFVSTFNlYXJjaFBhcmFtcyAhPT0gJ3VuZGVmaW5lZCcgJiYgdmFsdWUgaW5zdGFuY2VvZiBVUkxTZWFyY2hQYXJhbXM7XG59XG5cbi8qKlxuICogQW4gb3V0Z29pbmcgSFRUUCByZXF1ZXN0IHdpdGggYW4gb3B0aW9uYWwgdHlwZWQgYm9keS5cbiAqXG4gKiBgSHR0cFJlcXVlc3RgIHJlcHJlc2VudHMgYW4gb3V0Z29pbmcgcmVxdWVzdCwgaW5jbHVkaW5nIFVSTCwgbWV0aG9kLFxuICogaGVhZGVycywgYm9keSwgYW5kIG90aGVyIHJlcXVlc3QgY29uZmlndXJhdGlvbiBvcHRpb25zLiBJbnN0YW5jZXMgc2hvdWxkIGJlXG4gKiBhc3N1bWVkIHRvIGJlIGltbXV0YWJsZS4gVG8gbW9kaWZ5IGEgYEh0dHBSZXF1ZXN0YCwgdGhlIGBjbG9uZWBcbiAqIG1ldGhvZCBzaG91bGQgYmUgdXNlZC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBIdHRwUmVxdWVzdDxUPiB7XG4gIC8qKlxuICAgKiBUaGUgcmVxdWVzdCBib2R5LCBvciBgbnVsbGAgaWYgb25lIGlzbid0IHNldC5cbiAgICpcbiAgICogQm9kaWVzIGFyZSBub3QgZW5mb3JjZWQgdG8gYmUgaW1tdXRhYmxlLCBhcyB0aGV5IGNhbiBpbmNsdWRlIGEgcmVmZXJlbmNlIHRvIGFueVxuICAgKiB1c2VyLWRlZmluZWQgZGF0YSB0eXBlLiBIb3dldmVyLCBpbnRlcmNlcHRvcnMgc2hvdWxkIHRha2UgY2FyZSB0byBwcmVzZXJ2ZVxuICAgKiBpZGVtcG90ZW5jZSBieSB0cmVhdGluZyB0aGVtIGFzIHN1Y2guXG4gICAqL1xuICByZWFkb25seSBib2R5OiBUfG51bGwgPSBudWxsO1xuXG4gIC8qKlxuICAgKiBPdXRnb2luZyBoZWFkZXJzIGZvciB0aGlzIHJlcXVlc3QuXG4gICAqL1xuICAvLyBUT0RPKGlzc3VlLzI0NTcxKTogcmVtb3ZlICchJy5cbiAgcmVhZG9ubHkgaGVhZGVycyE6IEh0dHBIZWFkZXJzO1xuXG4gIC8qKlxuICAgKiBTaGFyZWQgYW5kIG11dGFibGUgY29udGV4dCB0aGF0IGNhbiBiZSB1c2VkIGJ5IGludGVyY2VwdG9yc1xuICAgKi9cbiAgcmVhZG9ubHkgY29udGV4dCE6IEh0dHBDb250ZXh0O1xuXG4gIC8qKlxuICAgKiBXaGV0aGVyIHRoaXMgcmVxdWVzdCBzaG91bGQgYmUgbWFkZSBpbiBhIHdheSB0aGF0IGV4cG9zZXMgcHJvZ3Jlc3MgZXZlbnRzLlxuICAgKlxuICAgKiBQcm9ncmVzcyBldmVudHMgYXJlIGV4cGVuc2l2ZSAoY2hhbmdlIGRldGVjdGlvbiBydW5zIG9uIGVhY2ggZXZlbnQpIGFuZCBzb1xuICAgKiB0aGV5IHNob3VsZCBvbmx5IGJlIHJlcXVlc3RlZCBpZiB0aGUgY29uc3VtZXIgaW50ZW5kcyB0byBtb25pdG9yIHRoZW0uXG4gICAqL1xuICByZWFkb25seSByZXBvcnRQcm9ncmVzczogYm9vbGVhbiA9IGZhbHNlO1xuXG4gIC8qKlxuICAgKiBXaGV0aGVyIHRoaXMgcmVxdWVzdCBzaG91bGQgYmUgc2VudCB3aXRoIG91dGdvaW5nIGNyZWRlbnRpYWxzIChjb29raWVzKS5cbiAgICovXG4gIHJlYWRvbmx5IHdpdGhDcmVkZW50aWFsczogYm9vbGVhbiA9IGZhbHNlO1xuXG4gIC8qKlxuICAgKiBUaGUgZXhwZWN0ZWQgcmVzcG9uc2UgdHlwZSBvZiB0aGUgc2VydmVyLlxuICAgKlxuICAgKiBUaGlzIGlzIHVzZWQgdG8gcGFyc2UgdGhlIHJlc3BvbnNlIGFwcHJvcHJpYXRlbHkgYmVmb3JlIHJldHVybmluZyBpdCB0b1xuICAgKiB0aGUgcmVxdWVzdGVlLlxuICAgKi9cbiAgcmVhZG9ubHkgcmVzcG9uc2VUeXBlOiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnID0gJ2pzb24nO1xuXG4gIC8qKlxuICAgKiBUaGUgb3V0Z29pbmcgSFRUUCByZXF1ZXN0IG1ldGhvZC5cbiAgICovXG4gIHJlYWRvbmx5IG1ldGhvZDogc3RyaW5nO1xuXG4gIC8qKlxuICAgKiBPdXRnb2luZyBVUkwgcGFyYW1ldGVycy5cbiAgICpcbiAgICogVG8gcGFzcyBhIHN0cmluZyByZXByZXNlbnRhdGlvbiBvZiBIVFRQIHBhcmFtZXRlcnMgaW4gdGhlIFVSTC1xdWVyeS1zdHJpbmcgZm9ybWF0LFxuICAgKiB0aGUgYEh0dHBQYXJhbXNPcHRpb25zYCcgYGZyb21TdHJpbmdgIG1heSBiZSB1c2VkLiBGb3IgZXhhbXBsZTpcbiAgICpcbiAgICogYGBgXG4gICAqIG5ldyBIdHRwUGFyYW1zKHtmcm9tU3RyaW5nOiAnYW5ndWxhcj1hd2Vzb21lJ30pXG4gICAqIGBgYFxuICAgKi9cbiAgLy8gVE9ETyhpc3N1ZS8yNDU3MSk6IHJlbW92ZSAnIScuXG4gIHJlYWRvbmx5IHBhcmFtcyE6IEh0dHBQYXJhbXM7XG5cbiAgLyoqXG4gICAqIFRoZSBvdXRnb2luZyBVUkwgd2l0aCBhbGwgVVJMIHBhcmFtZXRlcnMgc2V0LlxuICAgKi9cbiAgcmVhZG9ubHkgdXJsV2l0aFBhcmFtczogc3RyaW5nO1xuXG4gIGNvbnN0cnVjdG9yKG1ldGhvZDogJ0RFTEVURSd8J0dFVCd8J0hFQUQnfCdKU09OUCd8J09QVElPTlMnLCB1cmw6IHN0cmluZywgaW5pdD86IHtcbiAgICBoZWFkZXJzPzogSHR0cEhlYWRlcnMsXG4gICAgY29udGV4dD86IEh0dHBDb250ZXh0LFxuICAgIHJlcG9ydFByb2dyZXNzPzogYm9vbGVhbixcbiAgICBwYXJhbXM/OiBIdHRwUGFyYW1zLFxuICAgIHJlc3BvbnNlVHlwZT86ICdhcnJheWJ1ZmZlcid8J2Jsb2InfCdqc29uJ3wndGV4dCcsXG4gICAgd2l0aENyZWRlbnRpYWxzPzogYm9vbGVhbixcbiAgfSk7XG4gIGNvbnN0cnVjdG9yKG1ldGhvZDogJ1BPU1QnfCdQVVQnfCdQQVRDSCcsIHVybDogc3RyaW5nLCBib2R5OiBUfG51bGwsIGluaXQ/OiB7XG4gICAgaGVhZGVycz86IEh0dHBIZWFkZXJzLFxuICAgIGNvbnRleHQ/OiBIdHRwQ29udGV4dCxcbiAgICByZXBvcnRQcm9ncmVzcz86IGJvb2xlYW4sXG4gICAgcGFyYW1zPzogSHR0cFBhcmFtcyxcbiAgICByZXNwb25zZVR5cGU/OiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnLFxuICAgIHdpdGhDcmVkZW50aWFscz86IGJvb2xlYW4sXG4gIH0pO1xuICBjb25zdHJ1Y3RvcihtZXRob2Q6IHN0cmluZywgdXJsOiBzdHJpbmcsIGJvZHk6IFR8bnVsbCwgaW5pdD86IHtcbiAgICBoZWFkZXJzPzogSHR0cEhlYWRlcnMsXG4gICAgY29udGV4dD86IEh0dHBDb250ZXh0LFxuICAgIHJlcG9ydFByb2dyZXNzPzogYm9vbGVhbixcbiAgICBwYXJhbXM/OiBIdHRwUGFyYW1zLFxuICAgIHJlc3BvbnNlVHlwZT86ICdhcnJheWJ1ZmZlcid8J2Jsb2InfCdqc29uJ3wndGV4dCcsXG4gICAgd2l0aENyZWRlbnRpYWxzPzogYm9vbGVhbixcbiAgfSk7XG4gIGNvbnN0cnVjdG9yKFxuICAgICAgbWV0aG9kOiBzdHJpbmcsIHJlYWRvbmx5IHVybDogc3RyaW5nLCB0aGlyZD86IFR8e1xuICAgICAgICBoZWFkZXJzPzogSHR0cEhlYWRlcnMsXG4gICAgICAgIGNvbnRleHQ/OiBIdHRwQ29udGV4dCxcbiAgICAgICAgcmVwb3J0UHJvZ3Jlc3M/OiBib29sZWFuLFxuICAgICAgICBwYXJhbXM/OiBIdHRwUGFyYW1zLFxuICAgICAgICByZXNwb25zZVR5cGU/OiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnLFxuICAgICAgICB3aXRoQ3JlZGVudGlhbHM/OiBib29sZWFuLFxuICAgICAgfXxudWxsLFxuICAgICAgZm91cnRoPzoge1xuICAgICAgICBoZWFkZXJzPzogSHR0cEhlYWRlcnMsXG4gICAgICAgIGNvbnRleHQ/OiBIdHRwQ29udGV4dCxcbiAgICAgICAgcmVwb3J0UHJvZ3Jlc3M/OiBib29sZWFuLFxuICAgICAgICBwYXJhbXM/OiBIdHRwUGFyYW1zLFxuICAgICAgICByZXNwb25zZVR5cGU/OiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnLFxuICAgICAgICB3aXRoQ3JlZGVudGlhbHM/OiBib29sZWFuLFxuICAgICAgfSkge1xuICAgIHRoaXMubWV0aG9kID0gbWV0aG9kLnRvVXBwZXJDYXNlKCk7XG4gICAgLy8gTmV4dCwgbmVlZCB0byBmaWd1cmUgb3V0IHdoaWNoIGFyZ3VtZW50IGhvbGRzIHRoZSBIdHRwUmVxdWVzdEluaXRcbiAgICAvLyBvcHRpb25zLCBpZiBhbnkuXG4gICAgbGV0IG9wdGlvbnM6IEh0dHBSZXF1ZXN0SW5pdHx1bmRlZmluZWQ7XG5cbiAgICAvLyBDaGVjayB3aGV0aGVyIGEgYm9keSBhcmd1bWVudCBpcyBleHBlY3RlZC4gVGhlIG9ubHkgdmFsaWQgd2F5IHRvIG9taXRcbiAgICAvLyB0aGUgYm9keSBhcmd1bWVudCBpcyB0byB1c2UgYSBrbm93biBuby1ib2R5IG1ldGhvZCBsaWtlIEdFVC5cbiAgICBpZiAobWlnaHRIYXZlQm9keSh0aGlzLm1ldGhvZCkgfHwgISFmb3VydGgpIHtcbiAgICAgIC8vIEJvZHkgaXMgdGhlIHRoaXJkIGFyZ3VtZW50LCBvcHRpb25zIGFyZSB0aGUgZm91cnRoLlxuICAgICAgdGhpcy5ib2R5ID0gKHRoaXJkICE9PSB1bmRlZmluZWQpID8gdGhpcmQgYXMgVCA6IG51bGw7XG4gICAgICBvcHRpb25zID0gZm91cnRoO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBObyBib2R5IHJlcXVpcmVkLCBvcHRpb25zIGFyZSB0aGUgdGhpcmQgYXJndW1lbnQuIFRoZSBib2R5IHN0YXlzIG51bGwuXG4gICAgICBvcHRpb25zID0gdGhpcmQgYXMgSHR0cFJlcXVlc3RJbml0O1xuICAgIH1cblxuICAgIC8vIElmIG9wdGlvbnMgaGF2ZSBiZWVuIHBhc3NlZCwgaW50ZXJwcmV0IHRoZW0uXG4gICAgaWYgKG9wdGlvbnMpIHtcbiAgICAgIC8vIE5vcm1hbGl6ZSByZXBvcnRQcm9ncmVzcyBhbmQgd2l0aENyZWRlbnRpYWxzLlxuICAgICAgdGhpcy5yZXBvcnRQcm9ncmVzcyA9ICEhb3B0aW9ucy5yZXBvcnRQcm9ncmVzcztcbiAgICAgIHRoaXMud2l0aENyZWRlbnRpYWxzID0gISFvcHRpb25zLndpdGhDcmVkZW50aWFscztcblxuICAgICAgLy8gT3ZlcnJpZGUgZGVmYXVsdCByZXNwb25zZSB0eXBlIG9mICdqc29uJyBpZiBvbmUgaXMgcHJvdmlkZWQuXG4gICAgICBpZiAoISFvcHRpb25zLnJlc3BvbnNlVHlwZSkge1xuICAgICAgICB0aGlzLnJlc3BvbnNlVHlwZSA9IG9wdGlvbnMucmVzcG9uc2VUeXBlO1xuICAgICAgfVxuXG4gICAgICAvLyBPdmVycmlkZSBoZWFkZXJzIGlmIHRoZXkncmUgcHJvdmlkZWQuXG4gICAgICBpZiAoISFvcHRpb25zLmhlYWRlcnMpIHtcbiAgICAgICAgdGhpcy5oZWFkZXJzID0gb3B0aW9ucy5oZWFkZXJzO1xuICAgICAgfVxuXG4gICAgICBpZiAoISFvcHRpb25zLmNvbnRleHQpIHtcbiAgICAgICAgdGhpcy5jb250ZXh0ID0gb3B0aW9ucy5jb250ZXh0O1xuICAgICAgfVxuXG4gICAgICBpZiAoISFvcHRpb25zLnBhcmFtcykge1xuICAgICAgICB0aGlzLnBhcmFtcyA9IG9wdGlvbnMucGFyYW1zO1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIElmIG5vIGhlYWRlcnMgaGF2ZSBiZWVuIHBhc3NlZCBpbiwgY29uc3RydWN0IGEgbmV3IEh0dHBIZWFkZXJzIGluc3RhbmNlLlxuICAgIGlmICghdGhpcy5oZWFkZXJzKSB7XG4gICAgICB0aGlzLmhlYWRlcnMgPSBuZXcgSHR0cEhlYWRlcnMoKTtcbiAgICB9XG5cbiAgICAvLyBJZiBubyBjb250ZXh0IGhhdmUgYmVlbiBwYXNzZWQgaW4sIGNvbnN0cnVjdCBhIG5ldyBIdHRwQ29udGV4dCBpbnN0YW5jZS5cbiAgICBpZiAoIXRoaXMuY29udGV4dCkge1xuICAgICAgdGhpcy5jb250ZXh0ID0gbmV3IEh0dHBDb250ZXh0KCk7XG4gICAgfVxuXG4gICAgLy8gSWYgbm8gcGFyYW1ldGVycyBoYXZlIGJlZW4gcGFzc2VkIGluLCBjb25zdHJ1Y3QgYSBuZXcgSHR0cFVybEVuY29kZWRQYXJhbXMgaW5zdGFuY2UuXG4gICAgaWYgKCF0aGlzLnBhcmFtcykge1xuICAgICAgdGhpcy5wYXJhbXMgPSBuZXcgSHR0cFBhcmFtcygpO1xuICAgICAgdGhpcy51cmxXaXRoUGFyYW1zID0gdXJsO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBFbmNvZGUgdGhlIHBhcmFtZXRlcnMgdG8gYSBzdHJpbmcgaW4gcHJlcGFyYXRpb24gZm9yIGluY2x1c2lvbiBpbiB0aGUgVVJMLlxuICAgICAgY29uc3QgcGFyYW1zID0gdGhpcy5wYXJhbXMudG9TdHJpbmcoKTtcbiAgICAgIGlmIChwYXJhbXMubGVuZ3RoID09PSAwKSB7XG4gICAgICAgIC8vIE5vIHBhcmFtZXRlcnMsIHRoZSB2aXNpYmxlIFVSTCBpcyBqdXN0IHRoZSBVUkwgZ2l2ZW4gYXQgY3JlYXRpb24gdGltZS5cbiAgICAgICAgdGhpcy51cmxXaXRoUGFyYW1zID0gdXJsO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgLy8gRG9lcyB0aGUgVVJMIGFscmVhZHkgaGF2ZSBxdWVyeSBwYXJhbWV0ZXJzPyBMb29rIGZvciAnPycuXG4gICAgICAgIGNvbnN0IHFJZHggPSB1cmwuaW5kZXhPZignPycpO1xuICAgICAgICAvLyBUaGVyZSBhcmUgMyBjYXNlcyB0byBoYW5kbGU6XG4gICAgICAgIC8vIDEpIE5vIGV4aXN0aW5nIHBhcmFtZXRlcnMgLT4gYXBwZW5kICc/JyBmb2xsb3dlZCBieSBwYXJhbXMuXG4gICAgICAgIC8vIDIpICc/JyBleGlzdHMgYW5kIGlzIGZvbGxvd2VkIGJ5IGV4aXN0aW5nIHF1ZXJ5IHN0cmluZyAtPlxuICAgICAgICAvLyAgICBhcHBlbmQgJyYnIGZvbGxvd2VkIGJ5IHBhcmFtcy5cbiAgICAgICAgLy8gMykgJz8nIGV4aXN0cyBhdCB0aGUgZW5kIG9mIHRoZSB1cmwgLT4gYXBwZW5kIHBhcmFtcyBkaXJlY3RseS5cbiAgICAgICAgLy8gVGhpcyBiYXNpY2FsbHkgYW1vdW50cyB0byBkZXRlcm1pbmluZyB0aGUgY2hhcmFjdGVyLCBpZiBhbnksIHdpdGhcbiAgICAgICAgLy8gd2hpY2ggdG8gam9pbiB0aGUgVVJMIGFuZCBwYXJhbWV0ZXJzLlxuICAgICAgICBjb25zdCBzZXA6IHN0cmluZyA9IHFJZHggPT09IC0xID8gJz8nIDogKHFJZHggPCB1cmwubGVuZ3RoIC0gMSA/ICcmJyA6ICcnKTtcbiAgICAgICAgdGhpcy51cmxXaXRoUGFyYW1zID0gdXJsICsgc2VwICsgcGFyYW1zO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBUcmFuc2Zvcm0gdGhlIGZyZWUtZm9ybSBib2R5IGludG8gYSBzZXJpYWxpemVkIGZvcm1hdCBzdWl0YWJsZSBmb3JcbiAgICogdHJhbnNtaXNzaW9uIHRvIHRoZSBzZXJ2ZXIuXG4gICAqL1xuICBzZXJpYWxpemVCb2R5KCk6IEFycmF5QnVmZmVyfEJsb2J8Rm9ybURhdGF8c3RyaW5nfG51bGwge1xuICAgIC8vIElmIG5vIGJvZHkgaXMgcHJlc2VudCwgbm8gbmVlZCB0byBzZXJpYWxpemUgaXQuXG4gICAgaWYgKHRoaXMuYm9keSA9PT0gbnVsbCkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIC8vIENoZWNrIHdoZXRoZXIgdGhlIGJvZHkgaXMgYWxyZWFkeSBpbiBhIHNlcmlhbGl6ZWQgZm9ybS4gSWYgc28sXG4gICAgLy8gaXQgY2FuIGp1c3QgYmUgcmV0dXJuZWQgZGlyZWN0bHkuXG4gICAgaWYgKGlzQXJyYXlCdWZmZXIodGhpcy5ib2R5KSB8fCBpc0Jsb2IodGhpcy5ib2R5KSB8fCBpc0Zvcm1EYXRhKHRoaXMuYm9keSkgfHxcbiAgICAgICAgaXNVcmxTZWFyY2hQYXJhbXModGhpcy5ib2R5KSB8fCB0eXBlb2YgdGhpcy5ib2R5ID09PSAnc3RyaW5nJykge1xuICAgICAgcmV0dXJuIHRoaXMuYm9keTtcbiAgICB9XG4gICAgLy8gQ2hlY2sgd2hldGhlciB0aGUgYm9keSBpcyBhbiBpbnN0YW5jZSBvZiBIdHRwVXJsRW5jb2RlZFBhcmFtcy5cbiAgICBpZiAodGhpcy5ib2R5IGluc3RhbmNlb2YgSHR0cFBhcmFtcykge1xuICAgICAgcmV0dXJuIHRoaXMuYm9keS50b1N0cmluZygpO1xuICAgIH1cbiAgICAvLyBDaGVjayB3aGV0aGVyIHRoZSBib2R5IGlzIGFuIG9iamVjdCBvciBhcnJheSwgYW5kIHNlcmlhbGl6ZSB3aXRoIEpTT04gaWYgc28uXG4gICAgaWYgKHR5cGVvZiB0aGlzLmJvZHkgPT09ICdvYmplY3QnIHx8IHR5cGVvZiB0aGlzLmJvZHkgPT09ICdib29sZWFuJyB8fFxuICAgICAgICBBcnJheS5pc0FycmF5KHRoaXMuYm9keSkpIHtcbiAgICAgIHJldHVybiBKU09OLnN0cmluZ2lmeSh0aGlzLmJvZHkpO1xuICAgIH1cbiAgICAvLyBGYWxsIGJhY2sgb24gdG9TdHJpbmcoKSBmb3IgZXZlcnl0aGluZyBlbHNlLlxuICAgIHJldHVybiAodGhpcy5ib2R5IGFzIGFueSkudG9TdHJpbmcoKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBFeGFtaW5lIHRoZSBib2R5IGFuZCBhdHRlbXB0IHRvIGluZmVyIGFuIGFwcHJvcHJpYXRlIE1JTUUgdHlwZVxuICAgKiBmb3IgaXQuXG4gICAqXG4gICAqIElmIG5vIHN1Y2ggdHlwZSBjYW4gYmUgaW5mZXJyZWQsIHRoaXMgbWV0aG9kIHdpbGwgcmV0dXJuIGBudWxsYC5cbiAgICovXG4gIGRldGVjdENvbnRlbnRUeXBlSGVhZGVyKCk6IHN0cmluZ3xudWxsIHtcbiAgICAvLyBBbiBlbXB0eSBib2R5IGhhcyBubyBjb250ZW50IHR5cGUuXG4gICAgaWYgKHRoaXMuYm9keSA9PT0gbnVsbCkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIC8vIEZvcm1EYXRhIGJvZGllcyByZWx5IG9uIHRoZSBicm93c2VyJ3MgY29udGVudCB0eXBlIGFzc2lnbm1lbnQuXG4gICAgaWYgKGlzRm9ybURhdGEodGhpcy5ib2R5KSkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIC8vIEJsb2JzIHVzdWFsbHkgaGF2ZSB0aGVpciBvd24gY29udGVudCB0eXBlLiBJZiBpdCBkb2Vzbid0LCB0aGVuXG4gICAgLy8gbm8gdHlwZSBjYW4gYmUgaW5mZXJyZWQuXG4gICAgaWYgKGlzQmxvYih0aGlzLmJvZHkpKSB7XG4gICAgICByZXR1cm4gdGhpcy5ib2R5LnR5cGUgfHwgbnVsbDtcbiAgICB9XG4gICAgLy8gQXJyYXkgYnVmZmVycyBoYXZlIHVua25vd24gY29udGVudHMgYW5kIHRodXMgbm8gdHlwZSBjYW4gYmUgaW5mZXJyZWQuXG4gICAgaWYgKGlzQXJyYXlCdWZmZXIodGhpcy5ib2R5KSkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIC8vIFRlY2huaWNhbGx5LCBzdHJpbmdzIGNvdWxkIGJlIGEgZm9ybSBvZiBKU09OIGRhdGEsIGJ1dCBpdCdzIHNhZmUgZW5vdWdoXG4gICAgLy8gdG8gYXNzdW1lIHRoZXkncmUgcGxhaW4gc3RyaW5ncy5cbiAgICBpZiAodHlwZW9mIHRoaXMuYm9keSA9PT0gJ3N0cmluZycpIHtcbiAgICAgIHJldHVybiAndGV4dC9wbGFpbic7XG4gICAgfVxuICAgIC8vIGBIdHRwVXJsRW5jb2RlZFBhcmFtc2AgaGFzIGl0cyBvd24gY29udGVudC10eXBlLlxuICAgIGlmICh0aGlzLmJvZHkgaW5zdGFuY2VvZiBIdHRwUGFyYW1zKSB7XG4gICAgICByZXR1cm4gJ2FwcGxpY2F0aW9uL3gtd3d3LWZvcm0tdXJsZW5jb2RlZDtjaGFyc2V0PVVURi04JztcbiAgICB9XG4gICAgLy8gQXJyYXlzLCBvYmplY3RzLCBib29sZWFuIGFuZCBudW1iZXJzIHdpbGwgYmUgZW5jb2RlZCBhcyBKU09OLlxuICAgIGlmICh0eXBlb2YgdGhpcy5ib2R5ID09PSAnb2JqZWN0JyB8fCB0eXBlb2YgdGhpcy5ib2R5ID09PSAnbnVtYmVyJyB8fFxuICAgICAgICB0eXBlb2YgdGhpcy5ib2R5ID09PSAnYm9vbGVhbicpIHtcbiAgICAgIHJldHVybiAnYXBwbGljYXRpb24vanNvbic7XG4gICAgfVxuICAgIC8vIE5vIHR5cGUgY291bGQgYmUgaW5mZXJyZWQuXG4gICAgcmV0dXJuIG51bGw7XG4gIH1cblxuICBjbG9uZSgpOiBIdHRwUmVxdWVzdDxUPjtcbiAgY2xvbmUodXBkYXRlOiB7XG4gICAgaGVhZGVycz86IEh0dHBIZWFkZXJzLFxuICAgIGNvbnRleHQ/OiBIdHRwQ29udGV4dCxcbiAgICByZXBvcnRQcm9ncmVzcz86IGJvb2xlYW4sXG4gICAgcGFyYW1zPzogSHR0cFBhcmFtcyxcbiAgICByZXNwb25zZVR5cGU/OiAnYXJyYXlidWZmZXInfCdibG9iJ3wnanNvbid8J3RleHQnLFxuICAgIHdpdGhDcmVkZW50aWFscz86IGJvb2xlYW4sXG4gICAgYm9keT86IFR8bnVsbCxcbiAgICBtZXRob2Q/OiBzdHJpbmcsXG4gICAgdXJsPzogc3RyaW5nLFxuICAgIHNldEhlYWRlcnM/OiB7W25hbWU6IHN0cmluZ106IHN0cmluZ3xzdHJpbmdbXX0sXG4gICAgc2V0UGFyYW1zPzoge1twYXJhbTogc3RyaW5nXTogc3RyaW5nfSxcbiAgfSk6IEh0dHBSZXF1ZXN0PFQ+O1xuICBjbG9uZTxWPih1cGRhdGU6IHtcbiAgICBoZWFkZXJzPzogSHR0cEhlYWRlcnMsXG4gICAgY29udGV4dD86IEh0dHBDb250ZXh0LFxuICAgIHJlcG9ydFByb2dyZXNzPzogYm9vbGVhbixcbiAgICBwYXJhbXM/OiBIdHRwUGFyYW1zLFxuICAgIHJlc3BvbnNlVHlwZT86ICdhcnJheWJ1ZmZlcid8J2Jsb2InfCdqc29uJ3wndGV4dCcsXG4gICAgd2l0aENyZWRlbnRpYWxzPzogYm9vbGVhbixcbiAgICBib2R5PzogVnxudWxsLFxuICAgIG1ldGhvZD86IHN0cmluZyxcbiAgICB1cmw/OiBzdHJpbmcsXG4gICAgc2V0SGVhZGVycz86IHtbbmFtZTogc3RyaW5nXTogc3RyaW5nfHN0cmluZ1tdfSxcbiAgICBzZXRQYXJhbXM/OiB7W3BhcmFtOiBzdHJpbmddOiBzdHJpbmd9LFxuICB9KTogSHR0cFJlcXVlc3Q8Vj47XG4gIGNsb25lKHVwZGF0ZToge1xuICAgIGhlYWRlcnM/OiBIdHRwSGVhZGVycyxcbiAgICBjb250ZXh0PzogSHR0cENvbnRleHQsXG4gICAgcmVwb3J0UHJvZ3Jlc3M/OiBib29sZWFuLFxuICAgIHBhcmFtcz86IEh0dHBQYXJhbXMsXG4gICAgcmVzcG9uc2VUeXBlPzogJ2FycmF5YnVmZmVyJ3wnYmxvYid8J2pzb24nfCd0ZXh0JyxcbiAgICB3aXRoQ3JlZGVudGlhbHM/OiBib29sZWFuLFxuICAgIGJvZHk/OiBhbnl8bnVsbCxcbiAgICBtZXRob2Q/OiBzdHJpbmcsXG4gICAgdXJsPzogc3RyaW5nLFxuICAgIHNldEhlYWRlcnM/OiB7W25hbWU6IHN0cmluZ106IHN0cmluZ3xzdHJpbmdbXX0sXG4gICAgc2V0UGFyYW1zPzoge1twYXJhbTogc3RyaW5nXTogc3RyaW5nfTtcbiAgfSA9IHt9KTogSHR0cFJlcXVlc3Q8YW55PiB7XG4gICAgLy8gRm9yIG1ldGhvZCwgdXJsLCBhbmQgcmVzcG9uc2VUeXBlLCB0YWtlIHRoZSBjdXJyZW50IHZhbHVlIHVubGVzc1xuICAgIC8vIGl0IGlzIG92ZXJyaWRkZW4gaW4gdGhlIHVwZGF0ZSBoYXNoLlxuICAgIGNvbnN0IG1ldGhvZCA9IHVwZGF0ZS5tZXRob2QgfHwgdGhpcy5tZXRob2Q7XG4gICAgY29uc3QgdXJsID0gdXBkYXRlLnVybCB8fCB0aGlzLnVybDtcbiAgICBjb25zdCByZXNwb25zZVR5cGUgPSB1cGRhdGUucmVzcG9uc2VUeXBlIHx8IHRoaXMucmVzcG9uc2VUeXBlO1xuXG4gICAgLy8gVGhlIGJvZHkgaXMgc29tZXdoYXQgc3BlY2lhbCAtIGEgYG51bGxgIHZhbHVlIGluIHVwZGF0ZS5ib2R5IG1lYW5zXG4gICAgLy8gd2hhdGV2ZXIgY3VycmVudCBib2R5IGlzIHByZXNlbnQgaXMgYmVpbmcgb3ZlcnJpZGRlbiB3aXRoIGFuIGVtcHR5XG4gICAgLy8gYm9keSwgd2hlcmVhcyBhbiBgdW5kZWZpbmVkYCB2YWx1ZSBpbiB1cGRhdGUuYm9keSBpbXBsaWVzIG5vXG4gICAgLy8gb3ZlcnJpZGUuXG4gICAgY29uc3QgYm9keSA9ICh1cGRhdGUuYm9keSAhPT0gdW5kZWZpbmVkKSA/IHVwZGF0ZS5ib2R5IDogdGhpcy5ib2R5O1xuXG4gICAgLy8gQ2FyZWZ1bGx5IGhhbmRsZSB0aGUgYm9vbGVhbiBvcHRpb25zIHRvIGRpZmZlcmVudGlhdGUgYmV0d2VlblxuICAgIC8vIGBmYWxzZWAgYW5kIGB1bmRlZmluZWRgIGluIHRoZSB1cGRhdGUgYXJncy5cbiAgICBjb25zdCB3aXRoQ3JlZGVudGlhbHMgPVxuICAgICAgICAodXBkYXRlLndpdGhDcmVkZW50aWFscyAhPT0gdW5kZWZpbmVkKSA/IHVwZGF0ZS53aXRoQ3JlZGVudGlhbHMgOiB0aGlzLndpdGhDcmVkZW50aWFscztcbiAgICBjb25zdCByZXBvcnRQcm9ncmVzcyA9XG4gICAgICAgICh1cGRhdGUucmVwb3J0UHJvZ3Jlc3MgIT09IHVuZGVmaW5lZCkgPyB1cGRhdGUucmVwb3J0UHJvZ3Jlc3MgOiB0aGlzLnJlcG9ydFByb2dyZXNzO1xuXG4gICAgLy8gSGVhZGVycyBhbmQgcGFyYW1zIG1heSBiZSBhcHBlbmRlZCB0byBpZiBgc2V0SGVhZGVyc2Agb3JcbiAgICAvLyBgc2V0UGFyYW1zYCBhcmUgdXNlZC5cbiAgICBsZXQgaGVhZGVycyA9IHVwZGF0ZS5oZWFkZXJzIHx8IHRoaXMuaGVhZGVycztcbiAgICBsZXQgcGFyYW1zID0gdXBkYXRlLnBhcmFtcyB8fCB0aGlzLnBhcmFtcztcblxuICAgIC8vIFBhc3Mgb24gY29udGV4dCBpZiBuZWVkZWRcbiAgICBjb25zdCBjb250ZXh0ID0gdXBkYXRlLmNvbnRleHQgPz8gdGhpcy5jb250ZXh0O1xuXG4gICAgLy8gQ2hlY2sgd2hldGhlciB0aGUgY2FsbGVyIGhhcyBhc2tlZCB0byBhZGQgaGVhZGVycy5cbiAgICBpZiAodXBkYXRlLnNldEhlYWRlcnMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgLy8gU2V0IGV2ZXJ5IHJlcXVlc3RlZCBoZWFkZXIuXG4gICAgICBoZWFkZXJzID1cbiAgICAgICAgICBPYmplY3Qua2V5cyh1cGRhdGUuc2V0SGVhZGVycylcbiAgICAgICAgICAgICAgLnJlZHVjZSgoaGVhZGVycywgbmFtZSkgPT4gaGVhZGVycy5zZXQobmFtZSwgdXBkYXRlLnNldEhlYWRlcnMhW25hbWVdKSwgaGVhZGVycyk7XG4gICAgfVxuXG4gICAgLy8gQ2hlY2sgd2hldGhlciB0aGUgY2FsbGVyIGhhcyBhc2tlZCB0byBzZXQgcGFyYW1zLlxuICAgIGlmICh1cGRhdGUuc2V0UGFyYW1zKSB7XG4gICAgICAvLyBTZXQgZXZlcnkgcmVxdWVzdGVkIHBhcmFtLlxuICAgICAgcGFyYW1zID0gT2JqZWN0LmtleXModXBkYXRlLnNldFBhcmFtcylcbiAgICAgICAgICAgICAgICAgICAucmVkdWNlKChwYXJhbXMsIHBhcmFtKSA9PiBwYXJhbXMuc2V0KHBhcmFtLCB1cGRhdGUuc2V0UGFyYW1zIVtwYXJhbV0pLCBwYXJhbXMpO1xuICAgIH1cblxuICAgIC8vIEZpbmFsbHksIGNvbnN0cnVjdCB0aGUgbmV3IEh0dHBSZXF1ZXN0IHVzaW5nIHRoZSBwaWVjZXMgZnJvbSBhYm92ZS5cbiAgICByZXR1cm4gbmV3IEh0dHBSZXF1ZXN0KG1ldGhvZCwgdXJsLCBib2R5LCB7XG4gICAgICBwYXJhbXMsXG4gICAgICBoZWFkZXJzLFxuICAgICAgY29udGV4dCxcbiAgICAgIHJlcG9ydFByb2dyZXNzLFxuICAgICAgcmVzcG9uc2VUeXBlLFxuICAgICAgd2l0aENyZWRlbnRpYWxzLFxuICAgIH0pO1xuICB9XG59XG4iXX0=