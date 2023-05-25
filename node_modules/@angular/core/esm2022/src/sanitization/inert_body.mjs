/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { trustedHTMLFromString } from '../util/security/trusted_types';
/**
 * This helper is used to get hold of an inert tree of DOM elements containing dirty HTML
 * that needs sanitizing.
 * Depending upon browser support we use one of two strategies for doing this.
 * Default: DOMParser strategy
 * Fallback: InertDocument strategy
 */
export function getInertBodyHelper(defaultDoc) {
    const inertDocumentHelper = new InertDocumentHelper(defaultDoc);
    return isDOMParserAvailable() ? new DOMParserHelper(inertDocumentHelper) : inertDocumentHelper;
}
/**
 * Uses DOMParser to create and fill an inert body element.
 * This is the default strategy used in browsers that support it.
 */
class DOMParserHelper {
    constructor(inertDocumentHelper) {
        this.inertDocumentHelper = inertDocumentHelper;
    }
    getInertBodyElement(html) {
        // We add these extra elements to ensure that the rest of the content is parsed as expected
        // e.g. leading whitespace is maintained and tags like `<meta>` do not get hoisted to the
        // `<head>` tag. Note that the `<body>` tag is closed implicitly to prevent unclosed tags
        // in `html` from consuming the otherwise explicit `</body>` tag.
        html = '<body><remove></remove>' + html;
        try {
            const body = new window.DOMParser()
                .parseFromString(trustedHTMLFromString(html), 'text/html')
                .body;
            if (body === null) {
                // In some browsers (e.g. Mozilla/5.0 iPad AppleWebKit Mobile) the `body` property only
                // becomes available in the following tick of the JS engine. In that case we fall back to
                // the `inertDocumentHelper` instead.
                return this.inertDocumentHelper.getInertBodyElement(html);
            }
            body.removeChild(body.firstChild);
            return body;
        }
        catch {
            return null;
        }
    }
}
/**
 * Use an HTML5 `template` element to create and fill an inert DOM element.
 * This is the fallback strategy if the browser does not support DOMParser.
 */
class InertDocumentHelper {
    constructor(defaultDoc) {
        this.defaultDoc = defaultDoc;
        this.inertDocument = this.defaultDoc.implementation.createHTMLDocument('sanitization-inert');
    }
    getInertBodyElement(html) {
        const templateEl = this.inertDocument.createElement('template');
        templateEl.innerHTML = trustedHTMLFromString(html);
        return templateEl;
    }
}
/**
 * We need to determine whether the DOMParser exists in the global context and
 * supports parsing HTML; HTML parsing support is not as wide as other formats, see
 * https://developer.mozilla.org/en-US/docs/Web/API/DOMParser#Browser_compatibility.
 *
 * @suppress {uselessCode}
 */
export function isDOMParserAvailable() {
    try {
        return !!new window.DOMParser().parseFromString(trustedHTMLFromString(''), 'text/html');
    }
    catch {
        return false;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5lcnRfYm9keS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3Nhbml0aXphdGlvbi9pbmVydF9ib2R5LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxxQkFBcUIsRUFBQyxNQUFNLGdDQUFnQyxDQUFDO0FBRXJFOzs7Ozs7R0FNRztBQUNILE1BQU0sVUFBVSxrQkFBa0IsQ0FBQyxVQUFvQjtJQUNyRCxNQUFNLG1CQUFtQixHQUFHLElBQUksbUJBQW1CLENBQUMsVUFBVSxDQUFDLENBQUM7SUFDaEUsT0FBTyxvQkFBb0IsRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLGVBQWUsQ0FBQyxtQkFBbUIsQ0FBQyxDQUFDLENBQUMsQ0FBQyxtQkFBbUIsQ0FBQztBQUNqRyxDQUFDO0FBU0Q7OztHQUdHO0FBQ0gsTUFBTSxlQUFlO0lBQ25CLFlBQW9CLG1CQUFvQztRQUFwQyx3QkFBbUIsR0FBbkIsbUJBQW1CLENBQWlCO0lBQUcsQ0FBQztJQUU1RCxtQkFBbUIsQ0FBQyxJQUFZO1FBQzlCLDJGQUEyRjtRQUMzRix5RkFBeUY7UUFDekYseUZBQXlGO1FBQ3pGLGlFQUFpRTtRQUNqRSxJQUFJLEdBQUcseUJBQXlCLEdBQUcsSUFBSSxDQUFDO1FBQ3hDLElBQUk7WUFDRixNQUFNLElBQUksR0FBRyxJQUFJLE1BQU0sQ0FBQyxTQUFTLEVBQUU7aUJBQ2pCLGVBQWUsQ0FBQyxxQkFBcUIsQ0FBQyxJQUFJLENBQVcsRUFBRSxXQUFXLENBQUM7aUJBQ25FLElBQXVCLENBQUM7WUFDMUMsSUFBSSxJQUFJLEtBQUssSUFBSSxFQUFFO2dCQUNqQix1RkFBdUY7Z0JBQ3ZGLHlGQUF5RjtnQkFDekYscUNBQXFDO2dCQUNyQyxPQUFPLElBQUksQ0FBQyxtQkFBbUIsQ0FBQyxtQkFBbUIsQ0FBQyxJQUFJLENBQUMsQ0FBQzthQUMzRDtZQUNELElBQUksQ0FBQyxXQUFXLENBQUMsSUFBSSxDQUFDLFVBQVcsQ0FBQyxDQUFDO1lBQ25DLE9BQU8sSUFBSSxDQUFDO1NBQ2I7UUFBQyxNQUFNO1lBQ04sT0FBTyxJQUFJLENBQUM7U0FDYjtJQUNILENBQUM7Q0FDRjtBQUVEOzs7R0FHRztBQUNILE1BQU0sbUJBQW1CO0lBR3ZCLFlBQW9CLFVBQW9CO1FBQXBCLGVBQVUsR0FBVixVQUFVLENBQVU7UUFDdEMsSUFBSSxDQUFDLGFBQWEsR0FBRyxJQUFJLENBQUMsVUFBVSxDQUFDLGNBQWMsQ0FBQyxrQkFBa0IsQ0FBQyxvQkFBb0IsQ0FBQyxDQUFDO0lBQy9GLENBQUM7SUFFRCxtQkFBbUIsQ0FBQyxJQUFZO1FBQzlCLE1BQU0sVUFBVSxHQUFHLElBQUksQ0FBQyxhQUFhLENBQUMsYUFBYSxDQUFDLFVBQVUsQ0FBQyxDQUFDO1FBQ2hFLFVBQVUsQ0FBQyxTQUFTLEdBQUcscUJBQXFCLENBQUMsSUFBSSxDQUFXLENBQUM7UUFDN0QsT0FBTyxVQUFVLENBQUM7SUFDcEIsQ0FBQztDQUNGO0FBRUQ7Ozs7OztHQU1HO0FBQ0gsTUFBTSxVQUFVLG9CQUFvQjtJQUNsQyxJQUFJO1FBQ0YsT0FBTyxDQUFDLENBQUMsSUFBSSxNQUFNLENBQUMsU0FBUyxFQUFFLENBQUMsZUFBZSxDQUMzQyxxQkFBcUIsQ0FBQyxFQUFFLENBQVcsRUFBRSxXQUFXLENBQUMsQ0FBQztLQUN2RDtJQUFDLE1BQU07UUFDTixPQUFPLEtBQUssQ0FBQztLQUNkO0FBQ0gsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge3RydXN0ZWRIVE1MRnJvbVN0cmluZ30gZnJvbSAnLi4vdXRpbC9zZWN1cml0eS90cnVzdGVkX3R5cGVzJztcblxuLyoqXG4gKiBUaGlzIGhlbHBlciBpcyB1c2VkIHRvIGdldCBob2xkIG9mIGFuIGluZXJ0IHRyZWUgb2YgRE9NIGVsZW1lbnRzIGNvbnRhaW5pbmcgZGlydHkgSFRNTFxuICogdGhhdCBuZWVkcyBzYW5pdGl6aW5nLlxuICogRGVwZW5kaW5nIHVwb24gYnJvd3NlciBzdXBwb3J0IHdlIHVzZSBvbmUgb2YgdHdvIHN0cmF0ZWdpZXMgZm9yIGRvaW5nIHRoaXMuXG4gKiBEZWZhdWx0OiBET01QYXJzZXIgc3RyYXRlZ3lcbiAqIEZhbGxiYWNrOiBJbmVydERvY3VtZW50IHN0cmF0ZWd5XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBnZXRJbmVydEJvZHlIZWxwZXIoZGVmYXVsdERvYzogRG9jdW1lbnQpOiBJbmVydEJvZHlIZWxwZXIge1xuICBjb25zdCBpbmVydERvY3VtZW50SGVscGVyID0gbmV3IEluZXJ0RG9jdW1lbnRIZWxwZXIoZGVmYXVsdERvYyk7XG4gIHJldHVybiBpc0RPTVBhcnNlckF2YWlsYWJsZSgpID8gbmV3IERPTVBhcnNlckhlbHBlcihpbmVydERvY3VtZW50SGVscGVyKSA6IGluZXJ0RG9jdW1lbnRIZWxwZXI7XG59XG5cbmV4cG9ydCBpbnRlcmZhY2UgSW5lcnRCb2R5SGVscGVyIHtcbiAgLyoqXG4gICAqIEdldCBhbiBpbmVydCBET00gZWxlbWVudCBjb250YWluaW5nIERPTSBjcmVhdGVkIGZyb20gdGhlIGRpcnR5IEhUTUwgc3RyaW5nIHByb3ZpZGVkLlxuICAgKi9cbiAgZ2V0SW5lcnRCb2R5RWxlbWVudDogKGh0bWw6IHN0cmluZykgPT4gSFRNTEVsZW1lbnQgfCBudWxsO1xufVxuXG4vKipcbiAqIFVzZXMgRE9NUGFyc2VyIHRvIGNyZWF0ZSBhbmQgZmlsbCBhbiBpbmVydCBib2R5IGVsZW1lbnQuXG4gKiBUaGlzIGlzIHRoZSBkZWZhdWx0IHN0cmF0ZWd5IHVzZWQgaW4gYnJvd3NlcnMgdGhhdCBzdXBwb3J0IGl0LlxuICovXG5jbGFzcyBET01QYXJzZXJIZWxwZXIgaW1wbGVtZW50cyBJbmVydEJvZHlIZWxwZXIge1xuICBjb25zdHJ1Y3Rvcihwcml2YXRlIGluZXJ0RG9jdW1lbnRIZWxwZXI6IEluZXJ0Qm9keUhlbHBlcikge31cblxuICBnZXRJbmVydEJvZHlFbGVtZW50KGh0bWw6IHN0cmluZyk6IEhUTUxFbGVtZW50fG51bGwge1xuICAgIC8vIFdlIGFkZCB0aGVzZSBleHRyYSBlbGVtZW50cyB0byBlbnN1cmUgdGhhdCB0aGUgcmVzdCBvZiB0aGUgY29udGVudCBpcyBwYXJzZWQgYXMgZXhwZWN0ZWRcbiAgICAvLyBlLmcuIGxlYWRpbmcgd2hpdGVzcGFjZSBpcyBtYWludGFpbmVkIGFuZCB0YWdzIGxpa2UgYDxtZXRhPmAgZG8gbm90IGdldCBob2lzdGVkIHRvIHRoZVxuICAgIC8vIGA8aGVhZD5gIHRhZy4gTm90ZSB0aGF0IHRoZSBgPGJvZHk+YCB0YWcgaXMgY2xvc2VkIGltcGxpY2l0bHkgdG8gcHJldmVudCB1bmNsb3NlZCB0YWdzXG4gICAgLy8gaW4gYGh0bWxgIGZyb20gY29uc3VtaW5nIHRoZSBvdGhlcndpc2UgZXhwbGljaXQgYDwvYm9keT5gIHRhZy5cbiAgICBodG1sID0gJzxib2R5PjxyZW1vdmU+PC9yZW1vdmU+JyArIGh0bWw7XG4gICAgdHJ5IHtcbiAgICAgIGNvbnN0IGJvZHkgPSBuZXcgd2luZG93LkRPTVBhcnNlcigpXG4gICAgICAgICAgICAgICAgICAgICAgIC5wYXJzZUZyb21TdHJpbmcodHJ1c3RlZEhUTUxGcm9tU3RyaW5nKGh0bWwpIGFzIHN0cmluZywgJ3RleHQvaHRtbCcpXG4gICAgICAgICAgICAgICAgICAgICAgIC5ib2R5IGFzIEhUTUxCb2R5RWxlbWVudDtcbiAgICAgIGlmIChib2R5ID09PSBudWxsKSB7XG4gICAgICAgIC8vIEluIHNvbWUgYnJvd3NlcnMgKGUuZy4gTW96aWxsYS81LjAgaVBhZCBBcHBsZVdlYktpdCBNb2JpbGUpIHRoZSBgYm9keWAgcHJvcGVydHkgb25seVxuICAgICAgICAvLyBiZWNvbWVzIGF2YWlsYWJsZSBpbiB0aGUgZm9sbG93aW5nIHRpY2sgb2YgdGhlIEpTIGVuZ2luZS4gSW4gdGhhdCBjYXNlIHdlIGZhbGwgYmFjayB0b1xuICAgICAgICAvLyB0aGUgYGluZXJ0RG9jdW1lbnRIZWxwZXJgIGluc3RlYWQuXG4gICAgICAgIHJldHVybiB0aGlzLmluZXJ0RG9jdW1lbnRIZWxwZXIuZ2V0SW5lcnRCb2R5RWxlbWVudChodG1sKTtcbiAgICAgIH1cbiAgICAgIGJvZHkucmVtb3ZlQ2hpbGQoYm9keS5maXJzdENoaWxkISk7XG4gICAgICByZXR1cm4gYm9keTtcbiAgICB9IGNhdGNoIHtcbiAgICAgIHJldHVybiBudWxsO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIFVzZSBhbiBIVE1MNSBgdGVtcGxhdGVgIGVsZW1lbnQgdG8gY3JlYXRlIGFuZCBmaWxsIGFuIGluZXJ0IERPTSBlbGVtZW50LlxuICogVGhpcyBpcyB0aGUgZmFsbGJhY2sgc3RyYXRlZ3kgaWYgdGhlIGJyb3dzZXIgZG9lcyBub3Qgc3VwcG9ydCBET01QYXJzZXIuXG4gKi9cbmNsYXNzIEluZXJ0RG9jdW1lbnRIZWxwZXIgaW1wbGVtZW50cyBJbmVydEJvZHlIZWxwZXIge1xuICBwcml2YXRlIGluZXJ0RG9jdW1lbnQ6IERvY3VtZW50O1xuXG4gIGNvbnN0cnVjdG9yKHByaXZhdGUgZGVmYXVsdERvYzogRG9jdW1lbnQpIHtcbiAgICB0aGlzLmluZXJ0RG9jdW1lbnQgPSB0aGlzLmRlZmF1bHREb2MuaW1wbGVtZW50YXRpb24uY3JlYXRlSFRNTERvY3VtZW50KCdzYW5pdGl6YXRpb24taW5lcnQnKTtcbiAgfVxuXG4gIGdldEluZXJ0Qm9keUVsZW1lbnQoaHRtbDogc3RyaW5nKTogSFRNTEVsZW1lbnR8bnVsbCB7XG4gICAgY29uc3QgdGVtcGxhdGVFbCA9IHRoaXMuaW5lcnREb2N1bWVudC5jcmVhdGVFbGVtZW50KCd0ZW1wbGF0ZScpO1xuICAgIHRlbXBsYXRlRWwuaW5uZXJIVE1MID0gdHJ1c3RlZEhUTUxGcm9tU3RyaW5nKGh0bWwpIGFzIHN0cmluZztcbiAgICByZXR1cm4gdGVtcGxhdGVFbDtcbiAgfVxufVxuXG4vKipcbiAqIFdlIG5lZWQgdG8gZGV0ZXJtaW5lIHdoZXRoZXIgdGhlIERPTVBhcnNlciBleGlzdHMgaW4gdGhlIGdsb2JhbCBjb250ZXh0IGFuZFxuICogc3VwcG9ydHMgcGFyc2luZyBIVE1MOyBIVE1MIHBhcnNpbmcgc3VwcG9ydCBpcyBub3QgYXMgd2lkZSBhcyBvdGhlciBmb3JtYXRzLCBzZWVcbiAqIGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0FQSS9ET01QYXJzZXIjQnJvd3Nlcl9jb21wYXRpYmlsaXR5LlxuICpcbiAqIEBzdXBwcmVzcyB7dXNlbGVzc0NvZGV9XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpc0RPTVBhcnNlckF2YWlsYWJsZSgpIHtcbiAgdHJ5IHtcbiAgICByZXR1cm4gISFuZXcgd2luZG93LkRPTVBhcnNlcigpLnBhcnNlRnJvbVN0cmluZyhcbiAgICAgICAgdHJ1c3RlZEhUTUxGcm9tU3RyaW5nKCcnKSBhcyBzdHJpbmcsICd0ZXh0L2h0bWwnKTtcbiAgfSBjYXRjaCB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG59XG4iXX0=