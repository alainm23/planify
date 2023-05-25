/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertEqual, throwError } from '../../util/assert';
// Global state of the parser. (This makes parser non-reentrant, but that is not an issue)
const parserState = {
    textEnd: 0,
    key: 0,
    keyEnd: 0,
    value: 0,
    valueEnd: 0,
};
/**
 * Retrieves the last parsed `key` of style.
 * @param text the text to substring the key from.
 */
export function getLastParsedKey(text) {
    return text.substring(parserState.key, parserState.keyEnd);
}
/**
 * Retrieves the last parsed `value` of style.
 * @param text the text to substring the key from.
 */
export function getLastParsedValue(text) {
    return text.substring(parserState.value, parserState.valueEnd);
}
/**
 * Initializes `className` string for parsing and parses the first token.
 *
 * This function is intended to be used in this format:
 * ```
 * for (let i = parseClassName(text); i >= 0; i = parseClassNameNext(text, i)) {
 *   const key = getLastParsedKey();
 *   ...
 * }
 * ```
 * @param text `className` to parse
 * @returns index where the next invocation of `parseClassNameNext` should resume.
 */
export function parseClassName(text) {
    resetParserState(text);
    return parseClassNameNext(text, consumeWhitespace(text, 0, parserState.textEnd));
}
/**
 * Parses next `className` token.
 *
 * This function is intended to be used in this format:
 * ```
 * for (let i = parseClassName(text); i >= 0; i = parseClassNameNext(text, i)) {
 *   const key = getLastParsedKey();
 *   ...
 * }
 * ```
 *
 * @param text `className` to parse
 * @param index where the parsing should resume.
 * @returns index where the next invocation of `parseClassNameNext` should resume.
 */
export function parseClassNameNext(text, index) {
    const end = parserState.textEnd;
    if (end === index) {
        return -1;
    }
    index = parserState.keyEnd = consumeClassToken(text, parserState.key = index, end);
    return consumeWhitespace(text, index, end);
}
/**
 * Initializes `cssText` string for parsing and parses the first key/values.
 *
 * This function is intended to be used in this format:
 * ```
 * for (let i = parseStyle(text); i >= 0; i = parseStyleNext(text, i))) {
 *   const key = getLastParsedKey();
 *   const value = getLastParsedValue();
 *   ...
 * }
 * ```
 * @param text `cssText` to parse
 * @returns index where the next invocation of `parseStyleNext` should resume.
 */
export function parseStyle(text) {
    resetParserState(text);
    return parseStyleNext(text, consumeWhitespace(text, 0, parserState.textEnd));
}
/**
 * Parses the next `cssText` key/values.
 *
 * This function is intended to be used in this format:
 * ```
 * for (let i = parseStyle(text); i >= 0; i = parseStyleNext(text, i))) {
 *   const key = getLastParsedKey();
 *   const value = getLastParsedValue();
 *   ...
 * }
 *
 * @param text `cssText` to parse
 * @param index where the parsing should resume.
 * @returns index where the next invocation of `parseStyleNext` should resume.
 */
export function parseStyleNext(text, startIndex) {
    const end = parserState.textEnd;
    let index = parserState.key = consumeWhitespace(text, startIndex, end);
    if (end === index) {
        // we reached an end so just quit
        return -1;
    }
    index = parserState.keyEnd = consumeStyleKey(text, index, end);
    index = consumeSeparator(text, index, end, 58 /* CharCode.COLON */);
    index = parserState.value = consumeWhitespace(text, index, end);
    index = parserState.valueEnd = consumeStyleValue(text, index, end);
    return consumeSeparator(text, index, end, 59 /* CharCode.SEMI_COLON */);
}
/**
 * Reset the global state of the styling parser.
 * @param text The styling text to parse.
 */
export function resetParserState(text) {
    parserState.key = 0;
    parserState.keyEnd = 0;
    parserState.value = 0;
    parserState.valueEnd = 0;
    parserState.textEnd = text.length;
}
/**
 * Returns index of next non-whitespace character.
 *
 * @param text Text to scan
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index of next non-whitespace character (May be the same as `start` if no whitespace at
 *          that location.)
 */
export function consumeWhitespace(text, startIndex, endIndex) {
    while (startIndex < endIndex && text.charCodeAt(startIndex) <= 32 /* CharCode.SPACE */) {
        startIndex++;
    }
    return startIndex;
}
/**
 * Returns index of last char in class token.
 *
 * @param text Text to scan
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index after last char in class token.
 */
export function consumeClassToken(text, startIndex, endIndex) {
    while (startIndex < endIndex && text.charCodeAt(startIndex) > 32 /* CharCode.SPACE */) {
        startIndex++;
    }
    return startIndex;
}
/**
 * Consumes all of the characters belonging to style key and token.
 *
 * @param text Text to scan
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index after last style key character.
 */
export function consumeStyleKey(text, startIndex, endIndex) {
    let ch;
    while (startIndex < endIndex &&
        ((ch = text.charCodeAt(startIndex)) === 45 /* CharCode.DASH */ || ch === 95 /* CharCode.UNDERSCORE */ ||
            ((ch & -33 /* CharCode.UPPER_CASE */) >= 65 /* CharCode.A */ && (ch & -33 /* CharCode.UPPER_CASE */) <= 90 /* CharCode.Z */) ||
            (ch >= 48 /* CharCode.ZERO */ && ch <= 57 /* CharCode.NINE */))) {
        startIndex++;
    }
    return startIndex;
}
/**
 * Consumes all whitespace and the separator `:` after the style key.
 *
 * @param text Text to scan
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index after separator and surrounding whitespace.
 */
export function consumeSeparator(text, startIndex, endIndex, separator) {
    startIndex = consumeWhitespace(text, startIndex, endIndex);
    if (startIndex < endIndex) {
        if (ngDevMode && text.charCodeAt(startIndex) !== separator) {
            malformedStyleError(text, String.fromCharCode(separator), startIndex);
        }
        startIndex++;
    }
    return startIndex;
}
/**
 * Consumes style value honoring `url()` and `""` text.
 *
 * @param text Text to scan
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index after last style value character.
 */
export function consumeStyleValue(text, startIndex, endIndex) {
    let ch1 = -1; // 1st previous character
    let ch2 = -1; // 2nd previous character
    let ch3 = -1; // 3rd previous character
    let i = startIndex;
    let lastChIndex = i;
    while (i < endIndex) {
        const ch = text.charCodeAt(i++);
        if (ch === 59 /* CharCode.SEMI_COLON */) {
            return lastChIndex;
        }
        else if (ch === 34 /* CharCode.DOUBLE_QUOTE */ || ch === 39 /* CharCode.SINGLE_QUOTE */) {
            lastChIndex = i = consumeQuotedText(text, ch, i, endIndex);
        }
        else if (startIndex ===
            i - 4 && // We have seen only 4 characters so far "URL(" (Ignore "foo_URL()")
            ch3 === 85 /* CharCode.U */ &&
            ch2 === 82 /* CharCode.R */ && ch1 === 76 /* CharCode.L */ && ch === 40 /* CharCode.OPEN_PAREN */) {
            lastChIndex = i = consumeQuotedText(text, 41 /* CharCode.CLOSE_PAREN */, i, endIndex);
        }
        else if (ch > 32 /* CharCode.SPACE */) {
            // if we have a non-whitespace character then capture its location
            lastChIndex = i;
        }
        ch3 = ch2;
        ch2 = ch1;
        ch1 = ch & -33 /* CharCode.UPPER_CASE */;
    }
    return lastChIndex;
}
/**
 * Consumes all of the quoted characters.
 *
 * @param text Text to scan
 * @param quoteCharCode CharCode of either `"` or `'` quote or `)` for `url(...)`.
 * @param startIndex Starting index of character where the scan should start.
 * @param endIndex Ending index of character where the scan should end.
 * @returns Index after quoted characters.
 */
export function consumeQuotedText(text, quoteCharCode, startIndex, endIndex) {
    let ch1 = -1; // 1st previous character
    let index = startIndex;
    while (index < endIndex) {
        const ch = text.charCodeAt(index++);
        if (ch == quoteCharCode && ch1 !== 92 /* CharCode.BACK_SLASH */) {
            return index;
        }
        if (ch == 92 /* CharCode.BACK_SLASH */ && ch1 === 92 /* CharCode.BACK_SLASH */) {
            // two back slashes cancel each other out. For example `"\\"` should properly end the
            // quotation. (It should not assume that the last `"` is escaped.)
            ch1 = 0;
        }
        else {
            ch1 = ch;
        }
    }
    throw ngDevMode ? malformedStyleError(text, String.fromCharCode(quoteCharCode), endIndex) :
        new Error();
}
function malformedStyleError(text, expecting, index) {
    ngDevMode && assertEqual(typeof text === 'string', true, 'String expected here');
    throw throwError(`Malformed style at location ${index} in string '` + text.substring(0, index) + '[>>' +
        text.substring(index, index + 1) + '<<]' + text.slice(index + 1) +
        `'. Expecting '${expecting}'.`);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic3R5bGluZ19wYXJzZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL3N0eWxpbmcvc3R5bGluZ19wYXJzZXIudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLFdBQVcsRUFBRSxVQUFVLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQWtDMUQsMEZBQTBGO0FBQzFGLE1BQU0sV0FBVyxHQUFnQjtJQUMvQixPQUFPLEVBQUUsQ0FBQztJQUNWLEdBQUcsRUFBRSxDQUFDO0lBQ04sTUFBTSxFQUFFLENBQUM7SUFDVCxLQUFLLEVBQUUsQ0FBQztJQUNSLFFBQVEsRUFBRSxDQUFDO0NBQ1osQ0FBQztBQUVGOzs7R0FHRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FBQyxJQUFZO0lBQzNDLE9BQU8sSUFBSSxDQUFDLFNBQVMsQ0FBQyxXQUFXLENBQUMsR0FBRyxFQUFFLFdBQVcsQ0FBQyxNQUFNLENBQUMsQ0FBQztBQUM3RCxDQUFDO0FBRUQ7OztHQUdHO0FBQ0gsTUFBTSxVQUFVLGtCQUFrQixDQUFDLElBQVk7SUFDN0MsT0FBTyxJQUFJLENBQUMsU0FBUyxDQUFDLFdBQVcsQ0FBQyxLQUFLLEVBQUUsV0FBVyxDQUFDLFFBQVEsQ0FBQyxDQUFDO0FBQ2pFLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7O0dBWUc7QUFDSCxNQUFNLFVBQVUsY0FBYyxDQUFDLElBQVk7SUFDekMsZ0JBQWdCLENBQUMsSUFBSSxDQUFDLENBQUM7SUFDdkIsT0FBTyxrQkFBa0IsQ0FBQyxJQUFJLEVBQUUsaUJBQWlCLENBQUMsSUFBSSxFQUFFLENBQUMsRUFBRSxXQUFXLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQztBQUNuRixDQUFDO0FBRUQ7Ozs7Ozs7Ozs7Ozs7O0dBY0c7QUFDSCxNQUFNLFVBQVUsa0JBQWtCLENBQUMsSUFBWSxFQUFFLEtBQWE7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biAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge2Fzc2VydEVxdWFsLCB0aHJvd0Vycm9yfSBmcm9tICcuLi8uLi91dGlsL2Fzc2VydCc7XG5pbXBvcnQge0NoYXJDb2RlfSBmcm9tICcuLi8uLi91dGlsL2NoYXJfY29kZSc7XG5cbi8qKlxuICogU3RvcmVzIHRoZSBsb2NhdGlvbnMgb2Yga2V5L3ZhbHVlIGluZGV4ZXMgd2hpbGUgcGFyc2luZyBzdHlsaW5nLlxuICpcbiAqIEluIGNhc2Ugb2YgYGNzc1RleHRgIHBhcnNpbmcgdGhlIGluZGV4ZXMgYXJlIGxpa2Ugc286XG4gKiBgYGBcbiAqICAgXCJrZXkxOiB2YWx1ZTE7IGtleTI6IHZhbHVlMjsga2V5MzogdmFsdWUzXCJcbiAqICAgICAgICAgICAgICAgICAgXiAgIF4gXiAgICAgXiAgICAgICAgICAgICBeXG4gKiAgICAgICAgICAgICAgICAgIHwgICB8IHwgICAgIHwgICAgICAgICAgICAgKy0tIHRleHRFbmRcbiAqICAgICAgICAgICAgICAgICAgfCAgIHwgfCAgICAgKy0tLS0tLS0tLS0tLS0tLS0gdmFsdWVFbmRcbiAqICAgICAgICAgICAgICAgICAgfCAgIHwgKy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gdmFsdWVcbiAqICAgICAgICAgICAgICAgICAgfCAgICstLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0ga2V5RW5kXG4gKiAgICAgICAgICAgICAgICAgICstLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGtleVxuICogYGBgXG4gKlxuICogSW4gY2FzZSBvZiBgY2xhc3NOYW1lYCBwYXJzaW5nIHRoZSBpbmRleGVzIGFyZSBsaWtlIHNvOlxuICogYGBgXG4gKiAgIFwia2V5MSBrZXkyIGtleTNcIlxuICogICAgICAgICBeICAgXiAgICBeXG4gKiAgICAgICAgIHwgICB8ICAgICstLSB0ZXh0RW5kXG4gKiAgICAgICAgIHwgICArLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGtleUVuZFxuICogICAgICAgICArLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBrZXlcbiAqIGBgYFxuICogTk9URTogYHZhbHVlYCBhbmQgYHZhbHVlRW5kYCBhcmUgdXNlZCBvbmx5IGZvciBzdHlsZXMsIG5vdCBjbGFzc2VzLlxuICovXG5pbnRlcmZhY2UgUGFyc2VyU3RhdGUge1xuICB0ZXh0RW5kOiBudW1iZXI7XG4gIGtleTogbnVtYmVyO1xuICBrZXlFbmQ6IG51bWJlcjtcbiAgdmFsdWU6IG51bWJlcjtcbiAgdmFsdWVFbmQ6IG51bWJlcjtcbn1cbi8vIEdsb2JhbCBzdGF0ZSBvZiB0aGUgcGFyc2VyLiAoVGhpcyBtYWtlcyBwYXJzZXIgbm9uLXJlZW50cmFudCwgYnV0IHRoYXQgaXMgbm90IGFuIGlzc3VlKVxuY29uc3QgcGFyc2VyU3RhdGU6IFBhcnNlclN0YXRlID0ge1xuICB0ZXh0RW5kOiAwLFxuICBrZXk6IDAsXG4gIGtleUVuZDogMCxcbiAgdmFsdWU6IDAsXG4gIHZhbHVlRW5kOiAwLFxufTtcblxuLyoqXG4gKiBSZXRyaWV2ZXMgdGhlIGxhc3QgcGFyc2VkIGBrZXlgIG9mIHN0eWxlLlxuICogQHBhcmFtIHRleHQgdGhlIHRleHQgdG8gc3Vic3RyaW5nIHRoZSBrZXkgZnJvbS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldExhc3RQYXJzZWRLZXkodGV4dDogc3RyaW5nKTogc3RyaW5nIHtcbiAgcmV0dXJuIHRleHQuc3Vic3RyaW5nKHBhcnNlclN0YXRlLmtleSwgcGFyc2VyU3RhdGUua2V5RW5kKTtcbn1cblxuLyoqXG4gKiBSZXRyaWV2ZXMgdGhlIGxhc3QgcGFyc2VkIGB2YWx1ZWAgb2Ygc3R5bGUuXG4gKiBAcGFyYW0gdGV4dCB0aGUgdGV4dCB0byBzdWJzdHJpbmcgdGhlIGtleSBmcm9tLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0TGFzdFBhcnNlZFZhbHVlKHRleHQ6IHN0cmluZyk6IHN0cmluZyB7XG4gIHJldHVybiB0ZXh0LnN1YnN0cmluZyhwYXJzZXJTdGF0ZS52YWx1ZSwgcGFyc2VyU3RhdGUudmFsdWVFbmQpO1xufVxuXG4vKipcbiAqIEluaXRpYWxpemVzIGBjbGFzc05hbWVgIHN0cmluZyBmb3IgcGFyc2luZyBhbmQgcGFyc2VzIHRoZSBmaXJzdCB0b2tlbi5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGlzIGludGVuZGVkIHRvIGJlIHVzZWQgaW4gdGhpcyBmb3JtYXQ6XG4gKiBgYGBcbiAqIGZvciAobGV0IGkgPSBwYXJzZUNsYXNzTmFtZSh0ZXh0KTsgaSA+PSAwOyBpID0gcGFyc2VDbGFzc05hbWVOZXh0KHRleHQsIGkpKSB7XG4gKiAgIGNvbnN0IGtleSA9IGdldExhc3RQYXJzZWRLZXkoKTtcbiAqICAgLi4uXG4gKiB9XG4gKiBgYGBcbiAqIEBwYXJhbSB0ZXh0IGBjbGFzc05hbWVgIHRvIHBhcnNlXG4gKiBAcmV0dXJucyBpbmRleCB3aGVyZSB0aGUgbmV4dCBpbnZvY2F0aW9uIG9mIGBwYXJzZUNsYXNzTmFtZU5leHRgIHNob3VsZCByZXN1bWUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBwYXJzZUNsYXNzTmFtZSh0ZXh0OiBzdHJpbmcpOiBudW1iZXIge1xuICByZXNldFBhcnNlclN0YXRlKHRleHQpO1xuICByZXR1cm4gcGFyc2VDbGFzc05hbWVOZXh0KHRleHQsIGNvbnN1bWVXaGl0ZXNwYWNlKHRleHQsIDAsIHBhcnNlclN0YXRlLnRleHRFbmQpKTtcbn1cblxuLyoqXG4gKiBQYXJzZXMgbmV4dCBgY2xhc3NOYW1lYCB0b2tlbi5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGlzIGludGVuZGVkIHRvIGJlIHVzZWQgaW4gdGhpcyBmb3JtYXQ6XG4gKiBgYGBcbiAqIGZvciAobGV0IGkgPSBwYXJzZUNsYXNzTmFtZSh0ZXh0KTsgaSA+PSAwOyBpID0gcGFyc2VDbGFzc05hbWVOZXh0KHRleHQsIGkpKSB7XG4gKiAgIGNvbnN0IGtleSA9IGdldExhc3RQYXJzZWRLZXkoKTtcbiAqICAgLi4uXG4gKiB9XG4gKiBgYGBcbiAqXG4gKiBAcGFyYW0gdGV4dCBgY2xhc3NOYW1lYCB0byBwYXJzZVxuICogQHBhcmFtIGluZGV4IHdoZXJlIHRoZSBwYXJzaW5nIHNob3VsZCByZXN1bWUuXG4gKiBAcmV0dXJucyBpbmRleCB3aGVyZSB0aGUgbmV4dCBpbnZvY2F0aW9uIG9mIGBwYXJzZUNsYXNzTmFtZU5leHRgIHNob3VsZCByZXN1bWUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBwYXJzZUNsYXNzTmFtZU5leHQodGV4dDogc3RyaW5nLCBpbmRleDogbnVtYmVyKTogbnVtYmVyIHtcbiAgY29uc3QgZW5kID0gcGFyc2VyU3RhdGUudGV4dEVuZDtcbiAgaWYgKGVuZCA9PT0gaW5kZXgpIHtcbiAgICByZXR1cm4gLTE7XG4gIH1cbiAgaW5kZXggPSBwYXJzZXJTdGF0ZS5rZXlFbmQgPSBjb25zdW1lQ2xhc3NUb2tlbih0ZXh0LCBwYXJzZXJTdGF0ZS5rZXkgPSBpbmRleCwgZW5kKTtcbiAgcmV0dXJuIGNvbnN1bWVXaGl0ZXNwYWNlKHRleHQsIGluZGV4LCBlbmQpO1xufVxuXG4vKipcbiAqIEluaXRpYWxpemVzIGBjc3NUZXh0YCBzdHJpbmcgZm9yIHBhcnNpbmcgYW5kIHBhcnNlcyB0aGUgZmlyc3Qga2V5L3ZhbHVlcy5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGlzIGludGVuZGVkIHRvIGJlIHVzZWQgaW4gdGhpcyBmb3JtYXQ6XG4gKiBgYGBcbiAqIGZvciAobGV0IGkgPSBwYXJzZVN0eWxlKHRleHQpOyBpID49IDA7IGkgPSBwYXJzZVN0eWxlTmV4dCh0ZXh0LCBpKSkpIHtcbiAqICAgY29uc3Qga2V5ID0gZ2V0TGFzdFBhcnNlZEtleSgpO1xuICogICBjb25zdCB2YWx1ZSA9IGdldExhc3RQYXJzZWRWYWx1ZSgpO1xuICogICAuLi5cbiAqIH1cbiAqIGBgYFxuICogQHBhcmFtIHRleHQgYGNzc1RleHRgIHRvIHBhcnNlXG4gKiBAcmV0dXJucyBpbmRleCB3aGVyZSB0aGUgbmV4dCBpbnZvY2F0aW9uIG9mIGBwYXJzZVN0eWxlTmV4dGAgc2hvdWxkIHJlc3VtZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHBhcnNlU3R5bGUodGV4dDogc3RyaW5nKTogbnVtYmVyIHtcbiAgcmVzZXRQYXJzZXJTdGF0ZSh0ZXh0KTtcbiAgcmV0dXJuIHBhcnNlU3R5bGVOZXh0KHRleHQsIGNvbnN1bWVXaGl0ZXNwYWNlKHRleHQsIDAsIHBhcnNlclN0YXRlLnRleHRFbmQpKTtcbn1cblxuLyoqXG4gKiBQYXJzZXMgdGhlIG5leHQgYGNzc1RleHRgIGtleS92YWx1ZXMuXG4gKlxuICogVGhpcyBmdW5jdGlvbiBpcyBpbnRlbmRlZCB0byBiZSB1c2VkIGluIHRoaXMgZm9ybWF0OlxuICogYGBgXG4gKiBmb3IgKGxldCBpID0gcGFyc2VTdHlsZSh0ZXh0KTsgaSA+PSAwOyBpID0gcGFyc2VTdHlsZU5leHQodGV4dCwgaSkpKSB7XG4gKiAgIGNvbnN0IGtleSA9IGdldExhc3RQYXJzZWRLZXkoKTtcbiAqICAgY29uc3QgdmFsdWUgPSBnZXRMYXN0UGFyc2VkVmFsdWUoKTtcbiAqICAgLi4uXG4gKiB9XG4gKlxuICogQHBhcmFtIHRleHQgYGNzc1RleHRgIHRvIHBhcnNlXG4gKiBAcGFyYW0gaW5kZXggd2hlcmUgdGhlIHBhcnNpbmcgc2hvdWxkIHJlc3VtZS5cbiAqIEByZXR1cm5zIGluZGV4IHdoZXJlIHRoZSBuZXh0IGludm9jYXRpb24gb2YgYHBhcnNlU3R5bGVOZXh0YCBzaG91bGQgcmVzdW1lLlxuICovXG5leHBvcnQgZnVuY3Rpb24gcGFyc2VTdHlsZU5leHQodGV4dDogc3RyaW5nLCBzdGFydEluZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICBjb25zdCBlbmQgPSBwYXJzZXJTdGF0ZS50ZXh0RW5kO1xuICBsZXQgaW5kZXggPSBwYXJzZXJTdGF0ZS5rZXkgPSBjb25zdW1lV2hpdGVzcGFjZSh0ZXh0LCBzdGFydEluZGV4LCBlbmQpO1xuICBpZiAoZW5kID09PSBpbmRleCkge1xuICAgIC8vIHdlIHJlYWNoZWQgYW4gZW5kIHNvIGp1c3QgcXVpdFxuICAgIHJldHVybiAtMTtcbiAgfVxuICBpbmRleCA9IHBhcnNlclN0YXRlLmtleUVuZCA9IGNvbnN1bWVTdHlsZUtleSh0ZXh0LCBpbmRleCwgZW5kKTtcbiAgaW5kZXggPSBjb25zdW1lU2VwYXJhdG9yKHRleHQsIGluZGV4LCBlbmQsIENoYXJDb2RlLkNPTE9OKTtcbiAgaW5kZXggPSBwYXJzZXJTdGF0ZS52YWx1ZSA9IGNvbnN1bWVXaGl0ZXNwYWNlKHRleHQsIGluZGV4LCBlbmQpO1xuICBpbmRleCA9IHBhcnNlclN0YXRlLnZhbHVlRW5kID0gY29uc3VtZVN0eWxlVmFsdWUodGV4dCwgaW5kZXgsIGVuZCk7XG4gIHJldHVybiBjb25zdW1lU2VwYXJhdG9yKHRleHQsIGluZGV4LCBlbmQsIENoYXJDb2RlLlNFTUlfQ09MT04pO1xufVxuXG4vKipcbiAqIFJlc2V0IHRoZSBnbG9iYWwgc3RhdGUgb2YgdGhlIHN0eWxpbmcgcGFyc2VyLlxuICogQHBhcmFtIHRleHQgVGhlIHN0eWxpbmcgdGV4dCB0byBwYXJzZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlc2V0UGFyc2VyU3RhdGUodGV4dDogc3RyaW5nKTogdm9pZCB7XG4gIHBhcnNlclN0YXRlLmtleSA9IDA7XG4gIHBhcnNlclN0YXRlLmtleUVuZCA9IDA7XG4gIHBhcnNlclN0YXRlLnZhbHVlID0gMDtcbiAgcGFyc2VyU3RhdGUudmFsdWVFbmQgPSAwO1xuICBwYXJzZXJTdGF0ZS50ZXh0RW5kID0gdGV4dC5sZW5ndGg7XG59XG5cbi8qKlxuICogUmV0dXJucyBpbmRleCBvZiBuZXh0IG5vbi13aGl0ZXNwYWNlIGNoYXJhY3Rlci5cbiAqXG4gKiBAcGFyYW0gdGV4dCBUZXh0IHRvIHNjYW5cbiAqIEBwYXJhbSBzdGFydEluZGV4IFN0YXJ0aW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgc3RhcnQuXG4gKiBAcGFyYW0gZW5kSW5kZXggRW5kaW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgZW5kLlxuICogQHJldHVybnMgSW5kZXggb2YgbmV4dCBub24td2hpdGVzcGFjZSBjaGFyYWN0ZXIgKE1heSBiZSB0aGUgc2FtZSBhcyBgc3RhcnRgIGlmIG5vIHdoaXRlc3BhY2UgYXRcbiAqICAgICAgICAgIHRoYXQgbG9jYXRpb24uKVxuICovXG5leHBvcnQgZnVuY3Rpb24gY29uc3VtZVdoaXRlc3BhY2UodGV4dDogc3RyaW5nLCBzdGFydEluZGV4OiBudW1iZXIsIGVuZEluZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICB3aGlsZSAoc3RhcnRJbmRleCA8IGVuZEluZGV4ICYmIHRleHQuY2hhckNvZGVBdChzdGFydEluZGV4KSA8PSBDaGFyQ29kZS5TUEFDRSkge1xuICAgIHN0YXJ0SW5kZXgrKztcbiAgfVxuICByZXR1cm4gc3RhcnRJbmRleDtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIGluZGV4IG9mIGxhc3QgY2hhciBpbiBjbGFzcyB0b2tlbi5cbiAqXG4gKiBAcGFyYW0gdGV4dCBUZXh0IHRvIHNjYW5cbiAqIEBwYXJhbSBzdGFydEluZGV4IFN0YXJ0aW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgc3RhcnQuXG4gKiBAcGFyYW0gZW5kSW5kZXggRW5kaW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgZW5kLlxuICogQHJldHVybnMgSW5kZXggYWZ0ZXIgbGFzdCBjaGFyIGluIGNsYXNzIHRva2VuLlxuICovXG5leHBvcnQgZnVuY3Rpb24gY29uc3VtZUNsYXNzVG9rZW4odGV4dDogc3RyaW5nLCBzdGFydEluZGV4OiBudW1iZXIsIGVuZEluZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICB3aGlsZSAoc3RhcnRJbmRleCA8IGVuZEluZGV4ICYmIHRleHQuY2hhckNvZGVBdChzdGFydEluZGV4KSA+IENoYXJDb2RlLlNQQUNFKSB7XG4gICAgc3RhcnRJbmRleCsrO1xuICB9XG4gIHJldHVybiBzdGFydEluZGV4O1xufVxuXG4vKipcbiAqIENvbnN1bWVzIGFsbCBvZiB0aGUgY2hhcmFjdGVycyBiZWxvbmdpbmcgdG8gc3R5bGUga2V5IGFuZCB0b2tlbi5cbiAqXG4gKiBAcGFyYW0gdGV4dCBUZXh0IHRvIHNjYW5cbiAqIEBwYXJhbSBzdGFydEluZGV4IFN0YXJ0aW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgc3RhcnQuXG4gKiBAcGFyYW0gZW5kSW5kZXggRW5kaW5nIGluZGV4IG9mIGNoYXJhY3RlciB3aGVyZSB0aGUgc2NhbiBzaG91bGQgZW5kLlxuICogQHJldHVybnMgSW5kZXggYWZ0ZXIgbGFzdCBzdHlsZSBrZXkgY2hhcmFjdGVyLlxuICovXG5leHBvcnQgZnVuY3Rpb24gY29uc3VtZVN0eWxlS2V5KHRleHQ6IHN0cmluZywgc3RhcnRJbmRleDogbnVtYmVyLCBlbmRJbmRleDogbnVtYmVyKTogbnVtYmVyIHtcbiAgbGV0IGNoOiBudW1iZXI7XG4gIHdoaWxlIChzdGFydEluZGV4IDwgZW5kSW5kZXggJiZcbiAgICAgICAgICgoY2ggPSB0ZXh0LmNoYXJDb2RlQXQoc3RhcnRJbmRleCkpID09PSBDaGFyQ29kZS5EQVNIIHx8IGNoID09PSBDaGFyQ29kZS5VTkRFUlNDT1JFIHx8XG4gICAgICAgICAgKChjaCAmIENoYXJDb2RlLlVQUEVSX0NBU0UpID49IENoYXJDb2RlLkEgJiYgKGNoICYgQ2hhckNvZGUuVVBQRVJfQ0FTRSkgPD0gQ2hhckNvZGUuWikgfHxcbiAgICAgICAgICAoY2ggPj0gQ2hhckNvZGUuWkVSTyAmJiBjaCA8PSBDaGFyQ29kZS5OSU5FKSkpIHtcbiAgICBzdGFydEluZGV4Kys7XG4gIH1cbiAgcmV0dXJuIHN0YXJ0SW5kZXg7XG59XG5cbi8qKlxuICogQ29uc3VtZXMgYWxsIHdoaXRlc3BhY2UgYW5kIHRoZSBzZXBhcmF0b3IgYDpgIGFmdGVyIHRoZSBzdHlsZSBrZXkuXG4gKlxuICogQHBhcmFtIHRleHQgVGV4dCB0byBzY2FuXG4gKiBAcGFyYW0gc3RhcnRJbmRleCBTdGFydGluZyBpbmRleCBvZiBjaGFyYWN0ZXIgd2hlcmUgdGhlIHNjYW4gc2hvdWxkIHN0YXJ0LlxuICogQHBhcmFtIGVuZEluZGV4IEVuZGluZyBpbmRleCBvZiBjaGFyYWN0ZXIgd2hlcmUgdGhlIHNjYW4gc2hvdWxkIGVuZC5cbiAqIEByZXR1cm5zIEluZGV4IGFmdGVyIHNlcGFyYXRvciBhbmQgc3Vycm91bmRpbmcgd2hpdGVzcGFjZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNvbnN1bWVTZXBhcmF0b3IoXG4gICAgdGV4dDogc3RyaW5nLCBzdGFydEluZGV4OiBudW1iZXIsIGVuZEluZGV4OiBudW1iZXIsIHNlcGFyYXRvcjogbnVtYmVyKTogbnVtYmVyIHtcbiAgc3RhcnRJbmRleCA9IGNvbnN1bWVXaGl0ZXNwYWNlKHRleHQsIHN0YXJ0SW5kZXgsIGVuZEluZGV4KTtcbiAgaWYgKHN0YXJ0SW5kZXggPCBlbmRJbmRleCkge1xuICAgIGlmIChuZ0Rldk1vZGUgJiYgdGV4dC5jaGFyQ29kZUF0KHN0YXJ0SW5kZXgpICE9PSBzZXBhcmF0b3IpIHtcbiAgICAgIG1hbGZvcm1lZFN0eWxlRXJyb3IodGV4dCwgU3RyaW5nLmZyb21DaGFyQ29kZShzZXBhcmF0b3IpLCBzdGFydEluZGV4KTtcbiAgICB9XG4gICAgc3RhcnRJbmRleCsrO1xuICB9XG4gIHJldHVybiBzdGFydEluZGV4O1xufVxuXG5cbi8qKlxuICogQ29uc3VtZXMgc3R5bGUgdmFsdWUgaG9ub3JpbmcgYHVybCgpYCBhbmQgYFwiXCJgIHRleHQuXG4gKlxuICogQHBhcmFtIHRleHQgVGV4dCB0byBzY2FuXG4gKiBAcGFyYW0gc3RhcnRJbmRleCBTdGFydGluZyBpbmRleCBvZiBjaGFyYWN0ZXIgd2hlcmUgdGhlIHNjYW4gc2hvdWxkIHN0YXJ0LlxuICogQHBhcmFtIGVuZEluZGV4IEVuZGluZyBpbmRleCBvZiBjaGFyYWN0ZXIgd2hlcmUgdGhlIHNjYW4gc2hvdWxkIGVuZC5cbiAqIEByZXR1cm5zIEluZGV4IGFmdGVyIGxhc3Qgc3R5bGUgdmFsdWUgY2hhcmFjdGVyLlxuICovXG5leHBvcnQgZnVuY3Rpb24gY29uc3VtZVN0eWxlVmFsdWUodGV4dDogc3RyaW5nLCBzdGFydEluZGV4OiBudW1iZXIsIGVuZEluZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICBsZXQgY2gxID0gLTE7ICAvLyAxc3QgcHJldmlvdXMgY2hhcmFjdGVyXG4gIGxldCBjaDIgPSAtMTsgIC8vIDJuZCBwcmV2aW91cyBjaGFyYWN0ZXJcbiAgbGV0IGNoMyA9IC0xOyAgLy8gM3JkIHByZXZpb3VzIGNoYXJhY3RlclxuICBsZXQgaSA9IHN0YXJ0SW5kZXg7XG4gIGxldCBsYXN0Q2hJbmRleCA9IGk7XG4gIHdoaWxlIChpIDwgZW5kSW5kZXgpIHtcbiAgICBjb25zdCBjaDogbnVtYmVyID0gdGV4dC5jaGFyQ29kZUF0KGkrKyk7XG4gICAgaWYgKGNoID09PSBDaGFyQ29kZS5TRU1JX0NPTE9OKSB7XG4gICAgICByZXR1cm4gbGFzdENoSW5kZXg7XG4gICAgfSBlbHNlIGlmIChjaCA9PT0gQ2hhckNvZGUuRE9VQkxFX1FVT1RFIHx8IGNoID09PSBDaGFyQ29kZS5TSU5HTEVfUVVPVEUpIHtcbiAgICAgIGxhc3RDaEluZGV4ID0gaSA9IGNvbnN1bWVRdW90ZWRUZXh0KHRleHQsIGNoLCBpLCBlbmRJbmRleCk7XG4gICAgfSBlbHNlIGlmIChcbiAgICAgICAgc3RhcnRJbmRleCA9PT1cbiAgICAgICAgICAgIGkgLSA0ICYmICAvLyBXZSBoYXZlIHNlZW4gb25seSA0IGNoYXJhY3RlcnMgc28gZmFyIFwiVVJMKFwiIChJZ25vcmUgXCJmb29fVVJMKClcIilcbiAgICAgICAgY2gzID09PSBDaGFyQ29kZS5VICYmXG4gICAgICAgIGNoMiA9PT0gQ2hhckNvZGUuUiAmJiBjaDEgPT09IENoYXJDb2RlLkwgJiYgY2ggPT09IENoYXJDb2RlLk9QRU5fUEFSRU4pIHtcbiAgICAgIGxhc3RDaEluZGV4ID0gaSA9IGNvbnN1bWVRdW90ZWRUZXh0KHRleHQsIENoYXJDb2RlLkNMT1NFX1BBUkVOLCBpLCBlbmRJbmRleCk7XG4gICAgfSBlbHNlIGlmIChjaCA+IENoYXJDb2RlLlNQQUNFKSB7XG4gICAgICAvLyBpZiB3ZSBoYXZlIGEgbm9uLXdoaXRlc3BhY2UgY2hhcmFjdGVyIHRoZW4gY2FwdHVyZSBpdHMgbG9jYXRpb25cbiAgICAgIGxhc3RDaEluZGV4ID0gaTtcbiAgICB9XG4gICAgY2gzID0gY2gyO1xuICAgIGNoMiA9IGNoMTtcbiAgICBjaDEgPSBjaCAmIENoYXJDb2RlLlVQUEVSX0NBU0U7XG4gIH1cbiAgcmV0dXJuIGxhc3RDaEluZGV4O1xufVxuXG4vKipcbiAqIENvbnN1bWVzIGFsbCBvZiB0aGUgcXVvdGVkIGNoYXJhY3RlcnMuXG4gKlxuICogQHBhcmFtIHRleHQgVGV4dCB0byBzY2FuXG4gKiBAcGFyYW0gcXVvdGVDaGFyQ29kZSBDaGFyQ29kZSBvZiBlaXRoZXIgYFwiYCBvciBgJ2AgcXVvdGUgb3IgYClgIGZvciBgdXJsKC4uLilgLlxuICogQHBhcmFtIHN0YXJ0SW5kZXggU3RhcnRpbmcgaW5kZXggb2YgY2hhcmFjdGVyIHdoZXJlIHRoZSBzY2FuIHNob3VsZCBzdGFydC5cbiAqIEBwYXJhbSBlbmRJbmRleCBFbmRpbmcgaW5kZXggb2YgY2hhcmFjdGVyIHdoZXJlIHRoZSBzY2FuIHNob3VsZCBlbmQuXG4gKiBAcmV0dXJucyBJbmRleCBhZnRlciBxdW90ZWQgY2hhcmFjdGVycy5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNvbnN1bWVRdW90ZWRUZXh0KFxuICAgIHRleHQ6IHN0cmluZywgcXVvdGVDaGFyQ29kZTogbnVtYmVyLCBzdGFydEluZGV4OiBudW1iZXIsIGVuZEluZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICBsZXQgY2gxID0gLTE7ICAvLyAxc3QgcHJldmlvdXMgY2hhcmFjdGVyXG4gIGxldCBpbmRleCA9IHN0YXJ0SW5kZXg7XG4gIHdoaWxlIChpbmRleCA8IGVuZEluZGV4KSB7XG4gICAgY29uc3QgY2ggPSB0ZXh0LmNoYXJDb2RlQXQoaW5kZXgrKyk7XG4gICAgaWYgKGNoID09IHF1b3RlQ2hhckNvZGUgJiYgY2gxICE9PSBDaGFyQ29kZS5CQUNLX1NMQVNIKSB7XG4gICAgICByZXR1cm4gaW5kZXg7XG4gICAgfVxuICAgIGlmIChjaCA9PSBDaGFyQ29kZS5CQUNLX1NMQVNIICYmIGNoMSA9PT0gQ2hhckNvZGUuQkFDS19TTEFTSCkge1xuICAgICAgLy8gdHdvIGJhY2sgc2xhc2hlcyBjYW5jZWwgZWFjaCBvdGhlciBvdXQuIEZvciBleGFtcGxlIGBcIlxcXFxcImAgc2hvdWxkIHByb3Blcmx5IGVuZCB0aGVcbiAgICAgIC8vIHF1b3RhdGlvbi4gKEl0IHNob3VsZCBub3QgYXNzdW1lIHRoYXQgdGhlIGxhc3QgYFwiYCBpcyBlc2NhcGVkLilcbiAgICAgIGNoMSA9IDA7XG4gICAgfSBlbHNlIHtcbiAgICAgIGNoMSA9IGNoO1xuICAgIH1cbiAgfVxuICB0aHJvdyBuZ0Rldk1vZGUgPyBtYWxmb3JtZWRTdHlsZUVycm9yKHRleHQsIFN0cmluZy5mcm9tQ2hhckNvZGUocXVvdGVDaGFyQ29kZSksIGVuZEluZGV4KSA6XG4gICAgICAgICAgICAgICAgICAgIG5ldyBFcnJvcigpO1xufVxuXG5mdW5jdGlvbiBtYWxmb3JtZWRTdHlsZUVycm9yKHRleHQ6IHN0cmluZywgZXhwZWN0aW5nOiBzdHJpbmcsIGluZGV4OiBudW1iZXIpOiBuZXZlciB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRFcXVhbCh0eXBlb2YgdGV4dCA9PT0gJ3N0cmluZycsIHRydWUsICdTdHJpbmcgZXhwZWN0ZWQgaGVyZScpO1xuICB0aHJvdyB0aHJvd0Vycm9yKFxuICAgICAgYE1hbGZvcm1lZCBzdHlsZSBhdCBsb2NhdGlvbiAke2luZGV4fSBpbiBzdHJpbmcgJ2AgKyB0ZXh0LnN1YnN0cmluZygwLCBpbmRleCkgKyAnWz4+JyArXG4gICAgICB0ZXh0LnN1YnN0cmluZyhpbmRleCwgaW5kZXggKyAxKSArICc8PF0nICsgdGV4dC5zbGljZShpbmRleCArIDEpICtcbiAgICAgIGAnLiBFeHBlY3RpbmcgJyR7ZXhwZWN0aW5nfScuYCk7XG59XG4iXX0=