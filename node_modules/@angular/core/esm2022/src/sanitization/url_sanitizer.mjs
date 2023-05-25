/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { XSS_SECURITY_URL } from '../error_details_base_url';
/**
 * A pattern that recognizes URLs that are safe wrt. XSS in URL navigation
 * contexts.
 *
 * This regular expression matches a subset of URLs that will not cause script
 * execution if used in URL context within a HTML document. Specifically, this
 * regular expression matches if:
 * (1) Either a protocol that is not javascript:, and that has valid characters
 *     (alphanumeric or [+-.]).
 * (2) or no protocol.  A protocol must be followed by a colon. The below
 *     allows that by allowing colons only after one of the characters [/?#].
 *     A colon after a hash (#) must be in the fragment.
 *     Otherwise, a colon after a (?) must be in a query.
 *     Otherwise, a colon after a single solidus (/) must be in a path.
 *     Otherwise, a colon after a double solidus (//) must be in the authority
 *     (before port).
 *
 * The pattern disallows &, used in HTML entity declarations before
 * one of the characters in [/?#]. This disallows HTML entities used in the
 * protocol name, which should never happen, e.g. "h&#116;tp" for "http".
 * It also disallows HTML entities in the first path part of a relative path,
 * e.g. "foo&lt;bar/baz".  Our existing escaping functions should not produce
 * that. More importantly, it disallows masking of a colon,
 * e.g. "javascript&#58;...".
 *
 * This regular expression was taken from the Closure sanitization library.
 */
const SAFE_URL_PATTERN = /^(?!javascript:)(?:[a-z0-9+.-]+:|[^&:\/?#]*(?:[\/?#]|$))/i;
export function _sanitizeUrl(url) {
    url = String(url);
    if (url.match(SAFE_URL_PATTERN))
        return url;
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        console.warn(`WARNING: sanitizing unsafe URL value ${url} (see ${XSS_SECURITY_URL})`);
    }
    return 'unsafe:' + url;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidXJsX3Nhbml0aXplci5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3Nhbml0aXphdGlvbi91cmxfc2FuaXRpemVyLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxnQkFBZ0IsRUFBQyxNQUFNLDJCQUEyQixDQUFDO0FBRTNEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQTBCRztBQUNILE1BQU0sZ0JBQWdCLEdBQUcsMkRBQTJELENBQUM7QUFDckYsTUFBTSxVQUFVLFlBQVksQ0FBQyxHQUFXO0lBQ3RDLEdBQUcsR0FBRyxNQUFNLENBQUMsR0FBRyxDQUFDLENBQUM7SUFDbEIsSUFBSSxHQUFHLENBQUMsS0FBSyxDQUFDLGdCQUFnQixDQUFDO1FBQUUsT0FBTyxHQUFHLENBQUM7SUFFNUMsSUFBSSxPQUFPLFNBQVMsS0FBSyxXQUFXLElBQUksU0FBUyxFQUFFO1FBQ2pELE9BQU8sQ0FBQyxJQUFJLENBQUMsd0NBQXdDLEdBQUcsU0FBUyxnQkFBZ0IsR0FBRyxDQUFDLENBQUM7S0FDdkY7SUFFRCxPQUFPLFNBQVMsR0FBRyxHQUFHLENBQUM7QUFDekIsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge1hTU19TRUNVUklUWV9VUkx9IGZyb20gJy4uL2Vycm9yX2RldGFpbHNfYmFzZV91cmwnO1xuXG4vKipcbiAqIEEgcGF0dGVybiB0aGF0IHJlY29nbml6ZXMgVVJMcyB0aGF0IGFyZSBzYWZlIHdydC4gWFNTIGluIFVSTCBuYXZpZ2F0aW9uXG4gKiBjb250ZXh0cy5cbiAqXG4gKiBUaGlzIHJlZ3VsYXIgZXhwcmVzc2lvbiBtYXRjaGVzIGEgc3Vic2V0IG9mIFVSTHMgdGhhdCB3aWxsIG5vdCBjYXVzZSBzY3JpcHRcbiAqIGV4ZWN1dGlvbiBpZiB1c2VkIGluIFVSTCBjb250ZXh0IHdpdGhpbiBhIEhUTUwgZG9jdW1lbnQuIFNwZWNpZmljYWxseSwgdGhpc1xuICogcmVndWxhciBleHByZXNzaW9uIG1hdGNoZXMgaWY6XG4gKiAoMSkgRWl0aGVyIGEgcHJvdG9jb2wgdGhhdCBpcyBub3QgamF2YXNjcmlwdDosIGFuZCB0aGF0IGhhcyB2YWxpZCBjaGFyYWN0ZXJzXG4gKiAgICAgKGFscGhhbnVtZXJpYyBvciBbKy0uXSkuXG4gKiAoMikgb3Igbm8gcHJvdG9jb2wuICBBIHByb3RvY29sIG11c3QgYmUgZm9sbG93ZWQgYnkgYSBjb2xvbi4gVGhlIGJlbG93XG4gKiAgICAgYWxsb3dzIHRoYXQgYnkgYWxsb3dpbmcgY29sb25zIG9ubHkgYWZ0ZXIgb25lIG9mIHRoZSBjaGFyYWN0ZXJzIFsvPyNdLlxuICogICAgIEEgY29sb24gYWZ0ZXIgYSBoYXNoICgjKSBtdXN0IGJlIGluIHRoZSBmcmFnbWVudC5cbiAqICAgICBPdGhlcndpc2UsIGEgY29sb24gYWZ0ZXIgYSAoPykgbXVzdCBiZSBpbiBhIHF1ZXJ5LlxuICogICAgIE90aGVyd2lzZSwgYSBjb2xvbiBhZnRlciBhIHNpbmdsZSBzb2xpZHVzICgvKSBtdXN0IGJlIGluIGEgcGF0aC5cbiAqICAgICBPdGhlcndpc2UsIGEgY29sb24gYWZ0ZXIgYSBkb3VibGUgc29saWR1cyAoLy8pIG11c3QgYmUgaW4gdGhlIGF1dGhvcml0eVxuICogICAgIChiZWZvcmUgcG9ydCkuXG4gKlxuICogVGhlIHBhdHRlcm4gZGlzYWxsb3dzICYsIHVzZWQgaW4gSFRNTCBlbnRpdHkgZGVjbGFyYXRpb25zIGJlZm9yZVxuICogb25lIG9mIHRoZSBjaGFyYWN0ZXJzIGluIFsvPyNdLiBUaGlzIGRpc2FsbG93cyBIVE1MIGVudGl0aWVzIHVzZWQgaW4gdGhlXG4gKiBwcm90b2NvbCBuYW1lLCB3aGljaCBzaG91bGQgbmV2ZXIgaGFwcGVuLCBlLmcuIFwiaCYjMTE2O3RwXCIgZm9yIFwiaHR0cFwiLlxuICogSXQgYWxzbyBkaXNhbGxvd3MgSFRNTCBlbnRpdGllcyBpbiB0aGUgZmlyc3QgcGF0aCBwYXJ0IG9mIGEgcmVsYXRpdmUgcGF0aCxcbiAqIGUuZy4gXCJmb28mbHQ7YmFyL2JhelwiLiAgT3VyIGV4aXN0aW5nIGVzY2FwaW5nIGZ1bmN0aW9ucyBzaG91bGQgbm90IHByb2R1Y2VcbiAqIHRoYXQuIE1vcmUgaW1wb3J0YW50bHksIGl0IGRpc2FsbG93cyBtYXNraW5nIG9mIGEgY29sb24sXG4gKiBlLmcuIFwiamF2YXNjcmlwdCYjNTg7Li4uXCIuXG4gKlxuICogVGhpcyByZWd1bGFyIGV4cHJlc3Npb24gd2FzIHRha2VuIGZyb20gdGhlIENsb3N1cmUgc2FuaXRpemF0aW9uIGxpYnJhcnkuXG4gKi9cbmNvbnN0IFNBRkVfVVJMX1BBVFRFUk4gPSAvXig/IWphdmFzY3JpcHQ6KSg/OlthLXowLTkrLi1dKzp8W14mOlxcLz8jXSooPzpbXFwvPyNdfCQpKS9pO1xuZXhwb3J0IGZ1bmN0aW9uIF9zYW5pdGl6ZVVybCh1cmw6IHN0cmluZyk6IHN0cmluZyB7XG4gIHVybCA9IFN0cmluZyh1cmwpO1xuICBpZiAodXJsLm1hdGNoKFNBRkVfVVJMX1BBVFRFUk4pKSByZXR1cm4gdXJsO1xuXG4gIGlmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpIHtcbiAgICBjb25zb2xlLndhcm4oYFdBUk5JTkc6IHNhbml0aXppbmcgdW5zYWZlIFVSTCB2YWx1ZSAke3VybH0gKHNlZSAke1hTU19TRUNVUklUWV9VUkx9KWApO1xuICB9XG5cbiAgcmV0dXJuICd1bnNhZmU6JyArIHVybDtcbn1cbiJdfQ==