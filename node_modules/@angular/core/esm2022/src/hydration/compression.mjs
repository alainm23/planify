/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { REFERENCE_NODE_BODY, REFERENCE_NODE_HOST } from './interfaces';
/**
 * Regexp that extracts a reference node information from the compressed node location.
 * The reference node is represented as either:
 *  - a number which points to an LView slot
 *  - the `b` char which indicates that the lookup should start from the `document.body`
 *  - the `h` char to start lookup from the component host node (`lView[HOST]`)
 */
const REF_EXTRACTOR_REGEXP = new RegExp(`^(\\d+)*(${REFERENCE_NODE_BODY}|${REFERENCE_NODE_HOST})*(.*)`);
/**
 * Helper function that takes a reference node location and a set of navigation steps
 * (from the reference node) to a target node and outputs a string that represents
 * a location.
 *
 * For example, given: referenceNode = 'b' (body) and path = ['firstChild', 'firstChild',
 * 'nextSibling'], the function returns: `bf2n`.
 */
export function compressNodeLocation(referenceNode, path) {
    const result = [referenceNode];
    for (const segment of path) {
        const lastIdx = result.length - 1;
        if (lastIdx > 0 && result[lastIdx - 1] === segment) {
            // An empty string in a count slot represents 1 occurrence of an instruction.
            const value = (result[lastIdx] || 1);
            result[lastIdx] = value + 1;
        }
        else {
            // Adding a new segment to the path.
            // Using an empty string in a counter field to avoid encoding `1`s
            // into the path, since they are implicit (e.g. `f1n1` vs `fn`), so
            // it's enough to have a single char in this case.
            result.push(segment, '');
        }
    }
    return result.join('');
}
/**
 * Helper function that reverts the `compressNodeLocation` and transforms a given
 * string into an array where at 0th position there is a reference node info and
 * after that it contains information (in pairs) about a navigation step and the
 * number of repetitions.
 *
 * For example, the path like 'bf2n' will be transformed to:
 * ['b', 'firstChild', 2, 'nextSibling', 1].
 *
 * This information is later consumed by the code that navigates the DOM to find
 * a given node by its location.
 */
export function decompressNodeLocation(path) {
    const matches = path.match(REF_EXTRACTOR_REGEXP);
    const [_, refNodeId, refNodeName, rest] = matches;
    // If a reference node is represented by an index, transform it to a number.
    const ref = refNodeId ? parseInt(refNodeId, 10) : refNodeName;
    const steps = [];
    // Match all segments in a path.
    for (const [_, step, count] of rest.matchAll(/(f|n)(\d*)/g)) {
        const repeat = parseInt(count, 10) || 1;
        steps.push(step, repeat);
    }
    return [ref, ...steps];
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29tcHJlc3Npb24uanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9oeWRyYXRpb24vY29tcHJlc3Npb24udHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFxQixtQkFBbUIsRUFBRSxtQkFBbUIsRUFBQyxNQUFNLGNBQWMsQ0FBQztBQUUxRjs7Ozs7O0dBTUc7QUFDSCxNQUFNLG9CQUFvQixHQUN0QixJQUFJLE1BQU0sQ0FBQyxZQUFZLG1CQUFtQixJQUFJLG1CQUFtQixRQUFRLENBQUMsQ0FBQztBQUUvRTs7Ozs7OztHQU9HO0FBQ0gsTUFBTSxVQUFVLG9CQUFvQixDQUFDLGFBQXFCLEVBQUUsSUFBMEI7SUFDcEYsTUFBTSxNQUFNLEdBQXlCLENBQUMsYUFBYSxDQUFDLENBQUM7SUFDckQsS0FBSyxNQUFNLE9BQU8sSUFBSSxJQUFJLEVBQUU7UUFDMUIsTUFBTSxPQUFPLEdBQUcsTUFBTSxDQUFDLE1BQU0sR0FBRyxDQUFDLENBQUM7UUFDbEMsSUFBSSxPQUFPLEdBQUcsQ0FBQyxJQUFJLE1BQU0sQ0FBQyxPQUFPLEdBQUcsQ0FBQyxDQUFDLEtBQUssT0FBTyxFQUFFO1lBQ2xELDZFQUE2RTtZQUM3RSxNQUFNLEtBQUssR0FBRyxDQUFDLE1BQU0sQ0FBQyxPQUFPLENBQUMsSUFBSSxDQUFDLENBQVcsQ0FBQztZQUMvQyxNQUFNLENBQUMsT0FBTyxDQUFDLEdBQUcsS0FBSyxHQUFHLENBQUMsQ0FBQztTQUM3QjthQUFNO1lBQ0wsb0NBQW9DO1lBQ3BDLGtFQUFrRTtZQUNsRSxtRUFBbUU7WUFDbkUsa0RBQWtEO1lBQ2xELE1BQU0sQ0FBQyxJQUFJLENBQUMsT0FBTyxFQUFFLEVBQUUsQ0FBQyxDQUFDO1NBQzFCO0tBQ0Y7SUFDRCxPQUFPLE1BQU0sQ0FBQyxJQUFJLENBQUMsRUFBRSxDQUFDLENBQUM7QUFDekIsQ0FBQztBQUVEOzs7Ozs7Ozs7OztHQVdHO0FBQ0gsTUFBTSxVQUFVLHNCQUFzQixDQUFDLElBQVk7SUFFakQsTUFBTSxPQUFPLEdBQUcsSUFBSSxDQUFDLEtBQUssQ0FBQyxvQkFBb0IsQ0FBRSxDQUFDO0lBQ2xELE1BQU0sQ0FBQyxDQUFDLEVBQUUsU0FBUyxFQUFFLFdBQVcsRUFBRSxJQUFJLENBQUMsR0FBRyxPQUFPLENBQUM7SUFDbEQsNEVBQTRFO0lBQzVFLE1BQU0sR0FBRyxHQUFHLFNBQVMsQ0FBQyxDQUFDLENBQUMsUUFBUSxDQUFDLFNBQVMsRUFBRSxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsV0FBVyxDQUFDO0lBQzlELE1BQU0sS0FBSyxHQUFrQyxFQUFFLENBQUM7SUFDaEQsZ0NBQWdDO0lBQ2hDLEtBQUssTUFBTSxDQUFDLENBQUMsRUFBRSxJQUFJLEVBQUUsS0FBSyxDQUFDLElBQUksSUFBSSxDQUFDLFFBQVEsQ0FBQyxhQUFhLENBQUMsRUFBRTtRQUMzRCxNQUFNLE1BQU0sR0FBRyxRQUFRLENBQUMsS0FBSyxFQUFFLEVBQUUsQ0FBQyxJQUFJLENBQUMsQ0FBQztRQUN4QyxLQUFLLENBQUMsSUFBSSxDQUFDLElBQTBCLEVBQUUsTUFBTSxDQUFDLENBQUM7S0FDaEQ7SUFDRCxPQUFPLENBQUMsR0FBRyxFQUFFLEdBQUcsS0FBSyxDQUFDLENBQUM7QUFDekIsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge05vZGVOYXZpZ2F0aW9uU3RlcCwgUkVGRVJFTkNFX05PREVfQk9EWSwgUkVGRVJFTkNFX05PREVfSE9TVH0gZnJvbSAnLi9pbnRlcmZhY2VzJztcblxuLyoqXG4gKiBSZWdleHAgdGhhdCBleHRyYWN0cyBhIHJlZmVyZW5jZSBub2RlIGluZm9ybWF0aW9uIGZyb20gdGhlIGNvbXByZXNzZWQgbm9kZSBsb2NhdGlvbi5cbiAqIFRoZSByZWZlcmVuY2Ugbm9kZSBpcyByZXByZXNlbnRlZCBhcyBlaXRoZXI6XG4gKiAgLSBhIG51bWJlciB3aGljaCBwb2ludHMgdG8gYW4gTFZpZXcgc2xvdFxuICogIC0gdGhlIGBiYCBjaGFyIHdoaWNoIGluZGljYXRlcyB0aGF0IHRoZSBsb29rdXAgc2hvdWxkIHN0YXJ0IGZyb20gdGhlIGBkb2N1bWVudC5ib2R5YFxuICogIC0gdGhlIGBoYCBjaGFyIHRvIHN0YXJ0IGxvb2t1cCBmcm9tIHRoZSBjb21wb25lbnQgaG9zdCBub2RlIChgbFZpZXdbSE9TVF1gKVxuICovXG5jb25zdCBSRUZfRVhUUkFDVE9SX1JFR0VYUCA9XG4gICAgbmV3IFJlZ0V4cChgXihcXFxcZCspKigke1JFRkVSRU5DRV9OT0RFX0JPRFl9fCR7UkVGRVJFTkNFX05PREVfSE9TVH0pKiguKilgKTtcblxuLyoqXG4gKiBIZWxwZXIgZnVuY3Rpb24gdGhhdCB0YWtlcyBhIHJlZmVyZW5jZSBub2RlIGxvY2F0aW9uIGFuZCBhIHNldCBvZiBuYXZpZ2F0aW9uIHN0ZXBzXG4gKiAoZnJvbSB0aGUgcmVmZXJlbmNlIG5vZGUpIHRvIGEgdGFyZ2V0IG5vZGUgYW5kIG91dHB1dHMgYSBzdHJpbmcgdGhhdCByZXByZXNlbnRzXG4gKiBhIGxvY2F0aW9uLlxuICpcbiAqIEZvciBleGFtcGxlLCBnaXZlbjogcmVmZXJlbmNlTm9kZSA9ICdiJyAoYm9keSkgYW5kIHBhdGggPSBbJ2ZpcnN0Q2hpbGQnLCAnZmlyc3RDaGlsZCcsXG4gKiAnbmV4dFNpYmxpbmcnXSwgdGhlIGZ1bmN0aW9uIHJldHVybnM6IGBiZjJuYC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNvbXByZXNzTm9kZUxvY2F0aW9uKHJlZmVyZW5jZU5vZGU6IHN0cmluZywgcGF0aDogTm9kZU5hdmlnYXRpb25TdGVwW10pOiBzdHJpbmcge1xuICBjb25zdCByZXN1bHQ6IEFycmF5PHN0cmluZ3xudW1iZXI+ID0gW3JlZmVyZW5jZU5vZGVdO1xuICBmb3IgKGNvbnN0IHNlZ21lbnQgb2YgcGF0aCkge1xuICAgIGNvbnN0IGxhc3RJZHggPSByZXN1bHQubGVuZ3RoIC0gMTtcbiAgICBpZiAobGFzdElkeCA+IDAgJiYgcmVzdWx0W2xhc3RJZHggLSAxXSA9PT0gc2VnbWVudCkge1xuICAgICAgLy8gQW4gZW1wdHkgc3RyaW5nIGluIGEgY291bnQgc2xvdCByZXByZXNlbnRzIDEgb2NjdXJyZW5jZSBvZiBhbiBpbnN0cnVjdGlvbi5cbiAgICAgIGNvbnN0IHZhbHVlID0gKHJlc3VsdFtsYXN0SWR4XSB8fCAxKSBhcyBudW1iZXI7XG4gICAgICByZXN1bHRbbGFzdElkeF0gPSB2YWx1ZSArIDE7XG4gICAgfSBlbHNlIHtcbiAgICAgIC8vIEFkZGluZyBhIG5ldyBzZWdtZW50IHRvIHRoZSBwYXRoLlxuICAgICAgLy8gVXNpbmcgYW4gZW1wdHkgc3RyaW5nIGluIGEgY291bnRlciBmaWVsZCB0byBhdm9pZCBlbmNvZGluZyBgMWBzXG4gICAgICAvLyBpbnRvIHRoZSBwYXRoLCBzaW5jZSB0aGV5IGFyZSBpbXBsaWNpdCAoZS5nLiBgZjFuMWAgdnMgYGZuYCksIHNvXG4gICAgICAvLyBpdCdzIGVub3VnaCB0byBoYXZlIGEgc2luZ2xlIGNoYXIgaW4gdGhpcyBjYXNlLlxuICAgICAgcmVzdWx0LnB1c2goc2VnbWVudCwgJycpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gcmVzdWx0LmpvaW4oJycpO1xufVxuXG4vKipcbiAqIEhlbHBlciBmdW5jdGlvbiB0aGF0IHJldmVydHMgdGhlIGBjb21wcmVzc05vZGVMb2NhdGlvbmAgYW5kIHRyYW5zZm9ybXMgYSBnaXZlblxuICogc3RyaW5nIGludG8gYW4gYXJyYXkgd2hlcmUgYXQgMHRoIHBvc2l0aW9uIHRoZXJlIGlzIGEgcmVmZXJlbmNlIG5vZGUgaW5mbyBhbmRcbiAqIGFmdGVyIHRoYXQgaXQgY29udGFpbnMgaW5mb3JtYXRpb24gKGluIHBhaXJzKSBhYm91dCBhIG5hdmlnYXRpb24gc3RlcCBhbmQgdGhlXG4gKiBudW1iZXIgb2YgcmVwZXRpdGlvbnMuXG4gKlxuICogRm9yIGV4YW1wbGUsIHRoZSBwYXRoIGxpa2UgJ2JmMm4nIHdpbGwgYmUgdHJhbnNmb3JtZWQgdG86XG4gKiBbJ2InLCAnZmlyc3RDaGlsZCcsIDIsICduZXh0U2libGluZycsIDFdLlxuICpcbiAqIFRoaXMgaW5mb3JtYXRpb24gaXMgbGF0ZXIgY29uc3VtZWQgYnkgdGhlIGNvZGUgdGhhdCBuYXZpZ2F0ZXMgdGhlIERPTSB0byBmaW5kXG4gKiBhIGdpdmVuIG5vZGUgYnkgaXRzIGxvY2F0aW9uLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZGVjb21wcmVzc05vZGVMb2NhdGlvbihwYXRoOiBzdHJpbmcpOlxuICAgIFtzdHJpbmd8bnVtYmVyLCAuLi4obnVtYmVyIHwgTm9kZU5hdmlnYXRpb25TdGVwKVtdXSB7XG4gIGNvbnN0IG1hdGNoZXMgPSBwYXRoLm1hdGNoKFJFRl9FWFRSQUNUT1JfUkVHRVhQKSE7XG4gIGNvbnN0IFtfLCByZWZOb2RlSWQsIHJlZk5vZGVOYW1lLCByZXN0XSA9IG1hdGNoZXM7XG4gIC8vIElmIGEgcmVmZXJlbmNlIG5vZGUgaXMgcmVwcmVzZW50ZWQgYnkgYW4gaW5kZXgsIHRyYW5zZm9ybSBpdCB0byBhIG51bWJlci5cbiAgY29uc3QgcmVmID0gcmVmTm9kZUlkID8gcGFyc2VJbnQocmVmTm9kZUlkLCAxMCkgOiByZWZOb2RlTmFtZTtcbiAgY29uc3Qgc3RlcHM6IChudW1iZXJ8Tm9kZU5hdmlnYXRpb25TdGVwKVtdID0gW107XG4gIC8vIE1hdGNoIGFsbCBzZWdtZW50cyBpbiBhIHBhdGguXG4gIGZvciAoY29uc3QgW18sIHN0ZXAsIGNvdW50XSBvZiByZXN0Lm1hdGNoQWxsKC8oZnxuKShcXGQqKS9nKSkge1xuICAgIGNvbnN0IHJlcGVhdCA9IHBhcnNlSW50KGNvdW50LCAxMCkgfHwgMTtcbiAgICBzdGVwcy5wdXNoKHN0ZXAgYXMgTm9kZU5hdmlnYXRpb25TdGVwLCByZXBlYXQpO1xuICB9XG4gIHJldHVybiBbcmVmLCAuLi5zdGVwc107XG59XG4iXX0=