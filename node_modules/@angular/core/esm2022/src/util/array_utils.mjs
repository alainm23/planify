/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertEqual, assertLessThanOrEqual } from './assert';
/**
 * Determines if the contents of two arrays is identical
 *
 * @param a first array
 * @param b second array
 * @param identityAccessor Optional function for extracting stable object identity from a value in
 *     the array.
 */
export function arrayEquals(a, b, identityAccessor) {
    if (a.length !== b.length)
        return false;
    for (let i = 0; i < a.length; i++) {
        let valueA = a[i];
        let valueB = b[i];
        if (identityAccessor) {
            valueA = identityAccessor(valueA);
            valueB = identityAccessor(valueB);
        }
        if (valueB !== valueA) {
            return false;
        }
    }
    return true;
}
/**
 * Flattens an array.
 */
export function flatten(list) {
    return list.flat(Number.POSITIVE_INFINITY);
}
export function deepForEach(input, fn) {
    input.forEach(value => Array.isArray(value) ? deepForEach(value, fn) : fn(value));
}
export function addToArray(arr, index, value) {
    // perf: array.push is faster than array.splice!
    if (index >= arr.length) {
        arr.push(value);
    }
    else {
        arr.splice(index, 0, value);
    }
}
export function removeFromArray(arr, index) {
    // perf: array.pop is faster than array.splice!
    if (index >= arr.length - 1) {
        return arr.pop();
    }
    else {
        return arr.splice(index, 1)[0];
    }
}
export function newArray(size, value) {
    const list = [];
    for (let i = 0; i < size; i++) {
        list.push(value);
    }
    return list;
}
/**
 * Remove item from array (Same as `Array.splice()` but faster.)
 *
 * `Array.splice()` is not as fast because it has to allocate an array for the elements which were
 * removed. This causes memory pressure and slows down code when most of the time we don't
 * care about the deleted items array.
 *
 * https://jsperf.com/fast-array-splice (About 20x faster)
 *
 * @param array Array to splice
 * @param index Index of element in array to remove.
 * @param count Number of items to remove.
 */
export function arraySplice(array, index, count) {
    const length = array.length - count;
    while (index < length) {
        array[index] = array[index + count];
        index++;
    }
    while (count--) {
        array.pop(); // shrink the array
    }
}
/**
 * Same as `Array.splice(index, 0, value)` but faster.
 *
 * `Array.splice()` is not fast because it has to allocate an array for the elements which were
 * removed. This causes memory pressure and slows down code when most of the time we don't
 * care about the deleted items array.
 *
 * @param array Array to splice.
 * @param index Index in array where the `value` should be added.
 * @param value Value to add to array.
 */
export function arrayInsert(array, index, value) {
    ngDevMode && assertLessThanOrEqual(index, array.length, 'Can\'t insert past array end.');
    let end = array.length;
    while (end > index) {
        const previousEnd = end - 1;
        array[end] = array[previousEnd];
        end = previousEnd;
    }
    array[index] = value;
}
/**
 * Same as `Array.splice2(index, 0, value1, value2)` but faster.
 *
 * `Array.splice()` is not fast because it has to allocate an array for the elements which were
 * removed. This causes memory pressure and slows down code when most of the time we don't
 * care about the deleted items array.
 *
 * @param array Array to splice.
 * @param index Index in array where the `value` should be added.
 * @param value1 Value to add to array.
 * @param value2 Value to add to array.
 */
export function arrayInsert2(array, index, value1, value2) {
    ngDevMode && assertLessThanOrEqual(index, array.length, 'Can\'t insert past array end.');
    let end = array.length;
    if (end == index) {
        // inserting at the end.
        array.push(value1, value2);
    }
    else if (end === 1) {
        // corner case when we have less items in array than we have items to insert.
        array.push(value2, array[0]);
        array[0] = value1;
    }
    else {
        end--;
        array.push(array[end - 1], array[end]);
        while (end > index) {
            const previousEnd = end - 2;
            array[end] = array[previousEnd];
            end--;
        }
        array[index] = value1;
        array[index + 1] = value2;
    }
}
/**
 * Get an index of an `value` in a sorted `array`.
 *
 * NOTE:
 * - This uses binary search algorithm for fast removals.
 *
 * @param array A sorted array to binary search.
 * @param value The value to look for.
 * @returns index of the value.
 *   - positive index if value found.
 *   - negative index if value not found. (`~index` to get the value where it should have been
 *     located)
 */
export function arrayIndexOfSorted(array, value) {
    return _arrayIndexOfSorted(array, value, 0);
}
/**
 * Set a `value` for a `key`.
 *
 * @param keyValueArray to modify.
 * @param key The key to locate or create.
 * @param value The value to set for a `key`.
 * @returns index (always even) of where the value vas set.
 */
export function keyValueArraySet(keyValueArray, key, value) {
    let index = keyValueArrayIndexOf(keyValueArray, key);
    if (index >= 0) {
        // if we found it set it.
        keyValueArray[index | 1] = value;
    }
    else {
        index = ~index;
        arrayInsert2(keyValueArray, index, key, value);
    }
    return index;
}
/**
 * Retrieve a `value` for a `key` (on `undefined` if not found.)
 *
 * @param keyValueArray to search.
 * @param key The key to locate.
 * @return The `value` stored at the `key` location or `undefined if not found.
 */
export function keyValueArrayGet(keyValueArray, key) {
    const index = keyValueArrayIndexOf(keyValueArray, key);
    if (index >= 0) {
        // if we found it retrieve it.
        return keyValueArray[index | 1];
    }
    return undefined;
}
/**
 * Retrieve a `key` index value in the array or `-1` if not found.
 *
 * @param keyValueArray to search.
 * @param key The key to locate.
 * @returns index of where the key is (or should have been.)
 *   - positive (even) index if key found.
 *   - negative index if key not found. (`~index` (even) to get the index where it should have
 *     been inserted.)
 */
export function keyValueArrayIndexOf(keyValueArray, key) {
    return _arrayIndexOfSorted(keyValueArray, key, 1);
}
/**
 * Delete a `key` (and `value`) from the `KeyValueArray`.
 *
 * @param keyValueArray to modify.
 * @param key The key to locate or delete (if exist).
 * @returns index of where the key was (or should have been.)
 *   - positive (even) index if key found and deleted.
 *   - negative index if key not found. (`~index` (even) to get the index where it should have
 *     been.)
 */
export function keyValueArrayDelete(keyValueArray, key) {
    const index = keyValueArrayIndexOf(keyValueArray, key);
    if (index >= 0) {
        // if we found it remove it.
        arraySplice(keyValueArray, index, 2);
    }
    return index;
}
/**
 * INTERNAL: Get an index of an `value` in a sorted `array` by grouping search by `shift`.
 *
 * NOTE:
 * - This uses binary search algorithm for fast removals.
 *
 * @param array A sorted array to binary search.
 * @param value The value to look for.
 * @param shift grouping shift.
 *   - `0` means look at every location
 *   - `1` means only look at every other (even) location (the odd locations are to be ignored as
 *         they are values.)
 * @returns index of the value.
 *   - positive index if value found.
 *   - negative index if value not found. (`~index` to get the value where it should have been
 * inserted)
 */
function _arrayIndexOfSorted(array, value, shift) {
    ngDevMode && assertEqual(Array.isArray(array), true, 'Expecting an array');
    let start = 0;
    let end = array.length >> shift;
    while (end !== start) {
        const middle = start + ((end - start) >> 1); // find the middle.
        const current = array[middle << shift];
        if (value === current) {
            return (middle << shift);
        }
        else if (current > value) {
            end = middle;
        }
        else {
            start = middle + 1; // We already searched middle so make it non-inclusive by adding 1
        }
    }
    return ~(end << shift);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYXJyYXlfdXRpbHMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy91dGlsL2FycmF5X3V0aWxzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxXQUFXLEVBQUUscUJBQXFCLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFFNUQ7Ozs7Ozs7R0FPRztBQUNILE1BQU0sVUFBVSxXQUFXLENBQUksQ0FBTSxFQUFFLENBQU0sRUFBRSxnQkFBd0M7SUFDckYsSUFBSSxDQUFDLENBQUMsTUFBTSxLQUFLLENBQUMsQ0FBQyxNQUFNO1FBQUUsT0FBTyxLQUFLLENBQUM7SUFDeEMsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7UUFDakMsSUFBSSxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDO1FBQ2xCLElBQUksTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQztRQUNsQixJQUFJLGdCQUFnQixFQUFFO1lBQ3BCLE1BQU0sR0FBRyxnQkFBZ0IsQ0FBQyxNQUFNLENBQVEsQ0FBQztZQUN6QyxNQUFNLEdBQUcsZ0JBQWdCLENBQUMsTUFBTSxDQUFRLENBQUM7U0FDMUM7UUFDRCxJQUFJLE1BQU0sS0FBSyxNQUFNLEVBQUU7WUFDckIsT0FBTyxLQUFLLENBQUM7U0FDZDtLQUNGO0lBQ0QsT0FBTyxJQUFJLENBQUM7QUFDZCxDQUFDO0FBRUQ7O0dBRUc7QUFDSCxNQUFNLFVBQVUsT0FBTyxDQUFDLElBQVc7SUFDakMsT0FBTyxJQUFJLENBQUMsSUFBSSxDQUFDLE1BQU0sQ0FBQyxpQkFBaUIsQ0FBQyxDQUFDO0FBQzdDLENBQUM7QUFFRCxNQUFNLFVBQVUsV0FBVyxDQUFJLEtBQWtCLEVBQUUsRUFBc0I7SUFDdkUsS0FBSyxDQUFDLE9B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QUksV0FBVyxDQUFDLEtBQUssQ0FBQyxPQUFPLENBQUMsS0FBSyxDQUFDLEVBQUUsSUFBSSxFQUFFLG9CQUFvQixDQUFDLENBQUM7SUFDM0UsSUFBSSxLQUFLLEdBQUcsQ0FBQyxDQUFDO0lBQ2QsSUFBSSxHQUFHLEdBQUcsS0FBSyxDQUFDLE1BQU0sSUFBSSxLQUFLLENBQUM7SUFDaEMsT0FBTyxHQUFHLEtBQUssS0FBSyxFQUFFO1FBQ3BCLE1BQU0sTUFBTSxHQUFHLEtBQUssR0FBRyxDQUFDLENBQUMsR0FBRyxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUUsbUJBQW1CO1FBQ2pFLE1BQU0sT0FBTyxHQUFHLEtBQUssQ0FBQyxNQUFNLElBQUksS0FBSyxDQUFDLENBQUM7UUFDdkMsSUFBSSxLQUFLLEtBQUssT0FBTyxFQUFFO1lBQ3JCLE9BQU8sQ0FBQyxNQUFNLElBQUksS0FBSyxDQUFDLENBQUM7U0FDMUI7YUFBTSxJQUFJLE9BQU8sR0FBRyxLQUFLLEVBQUU7WUFDMUIsR0FBRyxHQUFHLE1BQU0sQ0FBQztTQUNkO2FBQU07WUFDTCxLQUFLLEdBQUcsTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFFLGtFQUFrRTtTQUN4RjtLQUNGO0lBQ0QsT0FBTyxDQUFDLENBQUMsR0FBRyxJQUFJLEtBQUssQ0FBQyxDQUFDO0FBQ3pCLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHthc3NlcnRFcXVhbCwgYXNzZXJ0TGVzc1RoYW5PckVxdWFsfSBmcm9tICcuL2Fzc2VydCc7XG5cbi8qKlxuICogRGV0ZXJtaW5lcyBpZiB0aGUgY29udGVudHMgb2YgdHdvIGFycmF5cyBpcyBpZGVudGljYWxcbiAqXG4gKiBAcGFyYW0gYSBmaXJzdCBhcnJheVxuICogQHBhcmFtIGIgc2Vjb25kIGFycmF5XG4gKiBAcGFyYW0gaWRlbnRpdHlBY2Nlc3NvciBPcHRpb25hbCBmdW5jdGlvbiBmb3IgZXh0cmFjdGluZyBzdGFibGUgb2JqZWN0IGlkZW50aXR5IGZyb20gYSB2YWx1ZSBpblxuICogICAgIHRoZSBhcnJheS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGFycmF5RXF1YWxzPFQ+KGE6IFRbXSwgYjogVFtdLCBpZGVudGl0eUFjY2Vzc29yPzogKHZhbHVlOiBUKSA9PiB1bmtub3duKTogYm9vbGVhbiB7XG4gIGlmIChhLmxlbmd0aCAhPT0gYi5sZW5ndGgpIHJldHVybiBmYWxzZTtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBhLmxlbmd0aDsgaSsrKSB7XG4gICAgbGV0IHZhbHVlQSA9IGFbaV07XG4gICAgbGV0IHZhbHVlQiA9IGJbaV07XG4gICAgaWYgKGlkZW50aXR5QWNjZXNzb3IpIHtcbiAgICAgIHZhbHVlQSA9IGlkZW50aXR5QWNjZXNzb3IodmFsdWVBKSBhcyBhbnk7XG4gICAgICB2YWx1ZUIgPSBpZGVudGl0eUFjY2Vzc29yKHZhbHVlQikgYXMgYW55O1xuICAgIH1cbiAgICBpZiAodmFsdWVCICE9PSB2YWx1ZUEpIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gIH1cbiAgcmV0dXJuIHRydWU7XG59XG5cbi8qKlxuICogRmxhdHRlbnMgYW4gYXJyYXkuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBmbGF0dGVuKGxpc3Q6IGFueVtdKTogYW55W10ge1xuICByZXR1cm4gbGlzdC5mbGF0KE51bWJlci5QT1NJVElWRV9JTkZJTklUWSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBkZWVwRm9yRWFjaDxUPihpbnB1dDogKFR8YW55W10pW10sIGZuOiAodmFsdWU6IFQpID0+IHZvaWQpOiB2b2lkIHtcbiAgaW5wdXQuZm9yRWFjaCh2YWx1ZSA9PiBBcnJheS5pc0FycmF5KHZhbHVlKSA/IGRlZXBGb3JFYWNoKHZhbHVlLCBmbikgOiBmbih2YWx1ZSkpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gYWRkVG9BcnJheShhcnI6IGFueVtdLCBpbmRleDogbnVtYmVyLCB2YWx1ZTogYW55KTogdm9pZCB7XG4gIC8vIHBlcmY6IGFycmF5LnB1c2ggaXMgZmFzdGVyIHRoYW4gYXJyYXkuc3BsaWNlIVxuICBpZiAoaW5kZXggPj0gYXJyLmxlbmd0aCkge1xuICAgIGFyci5wdXNoKHZhbHVlKTtcbiAgfSBlbHNlIHtcbiAgICBhcnIuc3BsaWNlKGluZGV4LCAwLCB2YWx1ZSk7XG4gIH1cbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHJlbW92ZUZyb21BcnJheShhcnI6IGFueVtdLCBpbmRleDogbnVtYmVyKTogYW55IHtcbiAgLy8gcGVyZjogYXJyYXkucG9wIGlzIGZhc3RlciB0aGFuIGFycmF5LnNwbGljZSFcbiAgaWYgKGluZGV4ID49IGFyci5sZW5ndGggLSAxKSB7XG4gICAgcmV0dXJuIGFyci5wb3AoKTtcbiAgfSBlbHNlIHtcbiAgICByZXR1cm4gYXJyLnNwbGljZShpbmRleCwgMSlbMF07XG4gIH1cbn1cblxuZXhwb3J0IGZ1bmN0aW9uIG5ld0FycmF5PFQgPSBhbnk+KHNpemU6IG51bWJlcik6IFRbXTtcbmV4cG9ydCBmdW5jdGlvbiBuZXdBcnJheTxUPihzaXplOiBudW1iZXIsIHZhbHVlOiBUKTogVFtdO1xuZXhwb3J0IGZ1bmN0aW9uIG5ld0FycmF5PFQ+KHNpemU6IG51bWJlciwgdmFsdWU/OiBUKTogVFtdIHtcbiAgY29uc3QgbGlzdDogVFtdID0gW107XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgc2l6ZTsgaSsrKSB7XG4gICAgbGlzdC5wdXNoKHZhbHVlISk7XG4gIH1cbiAgcmV0dXJuIGxpc3Q7XG59XG5cbi8qKlxuICogUmVtb3ZlIGl0ZW0gZnJvbSBhcnJheSAoU2FtZSBhcyBgQXJyYXkuc3BsaWNlKClgIGJ1dCBmYXN0ZXIuKVxuICpcbiAqIGBBcnJheS5zcGxpY2UoKWAgaXMgbm90IGFzIGZhc3QgYmVjYXVzZSBpdCBoYXMgdG8gYWxsb2NhdGUgYW4gYXJyYXkgZm9yIHRoZSBlbGVtZW50cyB3aGljaCB3ZXJlXG4gKiByZW1vdmVkLiBUaGlzIGNhdXNlcyBtZW1vcnkgcHJlc3N1cmUgYW5kIHNsb3dzIGRvd24gY29kZSB3aGVuIG1vc3Qgb2YgdGhlIHRpbWUgd2UgZG9uJ3RcbiAqIGNhcmUgYWJvdXQgdGhlIGRlbGV0ZWQgaXRlbXMgYXJyYXkuXG4gKlxuICogaHR0cHM6Ly9qc3BlcmYuY29tL2Zhc3QtYXJyYXktc3BsaWNlIChBYm91dCAyMHggZmFzdGVyKVxuICpcbiAqIEBwYXJhbSBhcnJheSBBcnJheSB0byBzcGxpY2VcbiAqIEBwYXJhbSBpbmRleCBJbmRleCBvZiBlbGVtZW50IGluIGFycmF5IHRvIHJlbW92ZS5cbiAqIEBwYXJhbSBjb3VudCBOdW1iZXIgb2YgaXRlbXMgdG8gcmVtb3ZlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gYXJyYXlTcGxpY2UoYXJyYXk6IGFueVtdLCBpbmRleDogbnVtYmVyLCBjb3VudDogbnVtYmVyKTogdm9pZCB7XG4gIGNvbnN0IGxlbmd0aCA9IGFycmF5Lmxlbmd0aCAtIGNvdW50O1xuICB3aGlsZSAoaW5kZXggPCBsZW5ndGgpIHtcbiAgICBhcnJheVtpbmRleF0gPSBhcnJheVtpbmRleCArIGNvdW50XTtcbiAgICBpbmRleCsrO1xuICB9XG4gIHdoaWxlIChjb3VudC0tKSB7XG4gICAgYXJyYXkucG9wKCk7ICAvLyBzaHJpbmsgdGhlIGFycmF5XG4gIH1cbn1cblxuLyoqXG4gKiBTYW1lIGFzIGBBcnJheS5zcGxpY2UoaW5kZXgsIDAsIHZhbHVlKWAgYnV0IGZhc3Rlci5cbiAqXG4gKiBgQXJyYXkuc3BsaWNlKClgIGlzIG5vdCBmYXN0IGJlY2F1c2UgaXQgaGFzIHRvIGFsbG9jYXRlIGFuIGFycmF5IGZvciB0aGUgZWxlbWVudHMgd2hpY2ggd2VyZVxuICogcmVtb3ZlZC4gVGhpcyBjYXVzZXMgbWVtb3J5IHByZXNzdXJlIGFuZCBzbG93cyBkb3duIGNvZGUgd2hlbiBtb3N0IG9mIHRoZSB0aW1lIHdlIGRvbid0XG4gKiBjYXJlIGFib3V0IHRoZSBkZWxldGVkIGl0ZW1zIGFycmF5LlxuICpcbiAqIEBwYXJhbSBhcnJheSBBcnJheSB0byBzcGxpY2UuXG4gKiBAcGFyYW0gaW5kZXggSW5kZXggaW4gYXJyYXkgd2hlcmUgdGhlIGB2YWx1ZWAgc2hvdWxkIGJlIGFkZGVkLlxuICogQHBhcmFtIHZhbHVlIFZhbHVlIHRvIGFkZCB0byBhcnJheS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGFycmF5SW5zZXJ0KGFycmF5OiBhbnlbXSwgaW5kZXg6IG51bWJlciwgdmFsdWU6IGFueSk6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TGVzc1RoYW5PckVxdWFsKGluZGV4LCBhcnJheS5sZW5ndGgsICdDYW5cXCd0IGluc2VydCBwYXN0IGFycmF5IGVuZC4nKTtcbiAgbGV0IGVuZCA9IGFycmF5Lmxlbmd0aDtcbiAgd2hpbGUgKGVuZCA+IGluZGV4KSB7XG4gICAgY29uc3QgcHJldmlvdXNFbmQgPSBlbmQgLSAxO1xuICAgIGFycmF5W2VuZF0gPSBhcnJheVtwcmV2aW91c0VuZF07XG4gICAgZW5kID0gcHJldmlvdXNFbmQ7XG4gIH1cbiAgYXJyYXlbaW5kZXhdID0gdmFsdWU7XG59XG5cbi8qKlxuICogU2FtZSBhcyBgQXJyYXkuc3BsaWNlMihpbmRleCwgMCwgdmFsdWUxLCB2YWx1ZTIpYCBidXQgZmFzdGVyLlxuICpcbiAqIGBBcnJheS5zcGxpY2UoKWAgaXMgbm90IGZhc3QgYmVjYXVzZSBpdCBoYXMgdG8gYWxsb2NhdGUgYW4gYXJyYXkgZm9yIHRoZSBlbGVtZW50cyB3aGljaCB3ZXJlXG4gKiByZW1vdmVkLiBUaGlzIGNhdXNlcyBtZW1vcnkgcHJlc3N1cmUgYW5kIHNsb3dzIGRvd24gY29kZSB3aGVuIG1vc3Qgb2YgdGhlIHRpbWUgd2UgZG9uJ3RcbiAqIGNhcmUgYWJvdXQgdGhlIGRlbGV0ZWQgaXRlbXMgYXJyYXkuXG4gKlxuICogQHBhcmFtIGFycmF5IEFycmF5IHRvIHNwbGljZS5cbiAqIEBwYXJhbSBpbmRleCBJbmRleCBpbiBhcnJheSB3aGVyZSB0aGUgYHZhbHVlYCBzaG91bGQgYmUgYWRkZWQuXG4gKiBAcGFyYW0gdmFsdWUxIFZhbHVlIHRvIGFkZCB0byBhcnJheS5cbiAqIEBwYXJhbSB2YWx1ZTIgVmFsdWUgdG8gYWRkIHRvIGFycmF5LlxuICovXG5leHBvcnQgZnVuY3Rpb24gYXJyYXlJbnNlcnQyKGFycmF5OiBhbnlbXSwgaW5kZXg6IG51bWJlciwgdmFsdWUxOiBhbnksIHZhbHVlMjogYW55KTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRMZXNzVGhhbk9yRXF1YWwoaW5kZXgsIGFycmF5Lmxlbmd0aCwgJ0NhblxcJ3QgaW5zZXJ0IHBhc3QgYXJyYXkgZW5kLicpO1xuICBsZXQgZW5kID0gYXJyYXkubGVuZ3RoO1xuICBpZiAoZW5kID09IGluZGV4KSB7XG4gICAgLy8gaW5zZXJ0aW5nIGF0IHRoZSBlbmQuXG4gICAgYXJyYXkucHVzaCh2YWx1ZTEsIHZhbHVlMik7XG4gIH0gZWxzZSBpZiAoZW5kID09PSAxKSB7XG4gICAgLy8gY29ybmVyIGNhc2Ugd2hlbiB3ZSBoYXZlIGxlc3MgaXRlbXMgaW4gYXJyYXkgdGhhbiB3ZSBoYXZlIGl0ZW1zIHRvIGluc2VydC5cbiAgICBhcnJheS5wdXNoKHZhbHVlMiwgYXJyYXlbMF0pO1xuICAgIGFycmF5WzBdID0gdmFsdWUxO1xuICB9IGVsc2Uge1xuICAgIGVuZC0tO1xuICAgIGFycmF5LnB1c2goYXJyYXlbZW5kIC0gMV0sIGFycmF5W2VuZF0pO1xuICAgIHdoaWxlIChlbmQgPiBpbmRleCkge1xuICAgICAgY29uc3QgcHJldmlvdXNFbmQgPSBlbmQgLSAyO1xuICAgICAgYXJyYXlbZW5kXSA9IGFycmF5W3ByZXZpb3VzRW5kXTtcbiAgICAgIGVuZC0tO1xuICAgIH1cbiAgICBhcnJheVtpbmRleF0gPSB2YWx1ZTE7XG4gICAgYXJyYXlbaW5kZXggKyAxXSA9IHZhbHVlMjtcbiAgfVxufVxuXG5cbi8qKlxuICogR2V0IGFuIGluZGV4IG9mIGFuIGB2YWx1ZWAgaW4gYSBzb3J0ZWQgYGFycmF5YC5cbiAqXG4gKiBOT1RFOlxuICogLSBUaGlzIHVzZXMgYmluYXJ5IHNlYXJjaCBhbGdvcml0aG0gZm9yIGZhc3QgcmVtb3ZhbHMuXG4gKlxuICogQHBhcmFtIGFycmF5IEEgc29ydGVkIGFycmF5IHRvIGJpbmFyeSBzZWFyY2guXG4gKiBAcGFyYW0gdmFsdWUgVGhlIHZhbHVlIHRvIGxvb2sgZm9yLlxuICogQHJldHVybnMgaW5kZXggb2YgdGhlIHZhbHVlLlxuICogICAtIHBvc2l0aXZlIGluZGV4IGlmIHZhbHVlIGZvdW5kLlxuICogICAtIG5lZ2F0aXZlIGluZGV4IGlmIHZhbHVlIG5vdCBmb3VuZC4gKGB+aW5kZXhgIHRvIGdldCB0aGUgdmFsdWUgd2hlcmUgaXQgc2hvdWxkIGhhdmUgYmVlblxuICogICAgIGxvY2F0ZWQpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhcnJheUluZGV4T2ZTb3J0ZWQoYXJyYXk6IHN0cmluZ1tdLCB2YWx1ZTogc3RyaW5nKTogbnVtYmVyIHtcbiAgcmV0dXJuIF9hcnJheUluZGV4T2ZTb3J0ZWQoYXJyYXksIHZhbHVlLCAwKTtcbn1cblxuXG4vKipcbiAqIGBLZXlWYWx1ZUFycmF5YCBpcyBhbiBhcnJheSB3aGVyZSBldmVuIHBvc2l0aW9ucyBjb250YWluIGtleXMgYW5kIG9kZCBwb3NpdGlvbnMgY29udGFpbiB2YWx1ZXMuXG4gKlxuICogYEtleVZhbHVlQXJyYXlgIHByb3ZpZGVzIGEgdmVyeSBlZmZpY2llbnQgd2F5IG9mIGl0ZXJhdGluZyBvdmVyIGl0cyBjb250ZW50cy4gRm9yIHNtYWxsXG4gKiBzZXRzICh+MTApIHRoZSBjb3N0IG9mIGJpbmFyeSBzZWFyY2hpbmcgYW4gYEtleVZhbHVlQXJyYXlgIGhhcyBhYm91dCB0aGUgc2FtZSBwZXJmb3JtYW5jZVxuICogY2hhcmFjdGVyaXN0aWNzIHRoYXQgb2YgYSBgTWFwYCB3aXRoIHNpZ25pZmljYW50bHkgYmV0dGVyIG1lbW9yeSBmb290cHJpbnQuXG4gKlxuICogSWYgdXNlZCBhcyBhIGBNYXBgIHRoZSBrZXlzIGFyZSBzdG9yZWQgaW4gYWxwaGFiZXRpY2FsIG9yZGVyIHNvIHRoYXQgdGhleSBjYW4gYmUgYmluYXJ5IHNlYXJjaGVkXG4gKiBmb3IgcmV0cmlldmFsLlxuICpcbiAqIFNlZTogYGtleVZhbHVlQXJyYXlTZXRgLCBga2V5VmFsdWVBcnJheUdldGAsIGBrZXlWYWx1ZUFycmF5SW5kZXhPZmAsIGBrZXlWYWx1ZUFycmF5RGVsZXRlYC5cbiAqL1xuZXhwb3J0IGludGVyZmFjZSBLZXlWYWx1ZUFycmF5PFZBTFVFPiBleHRlbmRzIEFycmF5PFZBTFVFfHN0cmluZz4ge1xuICBfX2JyYW5kX186ICdhcnJheS1tYXAnO1xufVxuXG4vKipcbiAqIFNldCBhIGB2YWx1ZWAgZm9yIGEgYGtleWAuXG4gKlxuICogQHBhcmFtIGtleVZhbHVlQXJyYXkgdG8gbW9kaWZ5LlxuICogQHBhcmFtIGtleSBUaGUga2V5IHRvIGxvY2F0ZSBvciBjcmVhdGUuXG4gKiBAcGFyYW0gdmFsdWUgVGhlIHZhbHVlIHRvIHNldCBmb3IgYSBga2V5YC5cbiAqIEByZXR1cm5zIGluZGV4IChhbHdheXMgZXZlbikgb2Ygd2hlcmUgdGhlIHZhbHVlIHZhcyBzZXQuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBrZXlWYWx1ZUFycmF5U2V0PFY+KFxuICAgIGtleVZhbHVlQXJyYXk6IEtleVZhbHVlQXJyYXk8Vj4sIGtleTogc3RyaW5nLCB2YWx1ZTogVik6IG51bWJlciB7XG4gIGxldCBpbmRleCA9IGtleVZhbHVlQXJyYXlJbmRleE9mKGtleVZhbHVlQXJyYXksIGtleSk7XG4gIGlmIChpbmRleCA+PSAwKSB7XG4gICAgLy8gaWYgd2UgZm91bmQgaXQgc2V0IGl0LlxuICAgIGtleVZhbHVlQXJyYXlbaW5kZXggfCAxXSA9IHZhbHVlO1xuICB9IGVsc2Uge1xuICAgIGluZGV4ID0gfmluZGV4O1xuICAgIGFycmF5SW5zZXJ0MihrZXlWYWx1ZUFycmF5LCBpbmRleCwga2V5LCB2YWx1ZSk7XG4gIH1cbiAgcmV0dXJuIGluZGV4O1xufVxuXG4vKipcbiAqIFJldHJpZXZlIGEgYHZhbHVlYCBmb3IgYSBga2V5YCAob24gYHVuZGVmaW5lZGAgaWYgbm90IGZvdW5kLilcbiAqXG4gKiBAcGFyYW0ga2V5VmFsdWVBcnJheSB0byBzZWFyY2guXG4gKiBAcGFyYW0ga2V5IFRoZSBrZXkgdG8gbG9jYXRlLlxuICogQHJldHVybiBUaGUgYHZhbHVlYCBzdG9yZWQgYXQgdGhlIGBrZXlgIGxvY2F0aW9uIG9yIGB1bmRlZmluZWQgaWYgbm90IGZvdW5kLlxuICovXG5leHBvcnQgZnVuY3Rpb24ga2V5VmFsdWVBcnJheUdldDxWPihrZXlWYWx1ZUFycmF5OiBLZXlWYWx1ZUFycmF5PFY+LCBrZXk6IHN0cmluZyk6IFZ8dW5kZWZpbmVkIHtcbiAgY29uc3QgaW5kZXggPSBrZXlWYWx1ZUFycmF5SW5kZXhPZihrZXlWYWx1ZUFycmF5LCBrZXkpO1xuICBpZiAoaW5kZXggPj0gMCkge1xuICAgIC8vIGlmIHdlIGZvdW5kIGl0IHJldHJpZXZlIGl0LlxuICAgIHJldHVybiBrZXlWYWx1ZUFycmF5W2luZGV4IHwgMV0gYXMgVjtcbiAgfVxuICByZXR1cm4gdW5kZWZpbmVkO1xufVxuXG4vKipcbiAqIFJldHJpZXZlIGEgYGtleWAgaW5kZXggdmFsdWUgaW4gdGhlIGFycmF5IG9yIGAtMWAgaWYgbm90IGZvdW5kLlxuICpcbiAqIEBwYXJhbSBrZXlWYWx1ZUFycmF5IHRvIHNlYXJjaC5cbiAqIEBwYXJhbSBrZXkgVGhlIGtleSB0byBsb2NhdGUuXG4gKiBAcmV0dXJucyBpbmRleCBvZiB3aGVyZSB0aGUga2V5IGlzIChvciBzaG91bGQgaGF2ZSBiZWVuLilcbiAqICAgLSBwb3NpdGl2ZSAoZXZlbikgaW5kZXggaWYga2V5IGZvdW5kLlxuICogICAtIG5lZ2F0aXZlIGluZGV4IGlmIGtleSBub3QgZm91bmQuIChgfmluZGV4YCAoZXZlbikgdG8gZ2V0IHRoZSBpbmRleCB3aGVyZSBpdCBzaG91bGQgaGF2ZVxuICogICAgIGJlZW4gaW5zZXJ0ZWQuKVxuICovXG5leHBvcnQgZnVuY3Rpb24ga2V5VmFsdWVBcnJheUluZGV4T2Y8Vj4oa2V5VmFsdWVBcnJheTogS2V5VmFsdWVBcnJheTxWPiwga2V5OiBzdHJpbmcpOiBudW1iZXIge1xuICByZXR1cm4gX2FycmF5SW5kZXhPZlNvcnRlZChrZXlWYWx1ZUFycmF5IGFzIHN0cmluZ1tdLCBrZXksIDEpO1xufVxuXG4vKipcbiAqIERlbGV0ZSBhIGBrZXlgIChhbmQgYHZhbHVlYCkgZnJvbSB0aGUgYEtleVZhbHVlQXJyYXlgLlxuICpcbiAqIEBwYXJhbSBrZXlWYWx1ZUFycmF5IHRvIG1vZGlmeS5cbiAqIEBwYXJhbSBrZXkgVGhlIGtleSB0byBsb2NhdGUgb3IgZGVsZXRlIChpZiBleGlzdCkuXG4gKiBAcmV0dXJucyBpbmRleCBvZiB3aGVyZSB0aGUga2V5IHdhcyAob3Igc2hvdWxkIGhhdmUgYmVlbi4pXG4gKiAgIC0gcG9zaXRpdmUgKGV2ZW4pIGluZGV4IGlmIGtleSBmb3VuZCBhbmQgZGVsZXRlZC5cbiAqICAgLSBuZWdhdGl2ZSBpbmRleCBpZiBrZXkgbm90IGZvdW5kLiAoYH5pbmRleGAgKGV2ZW4pIHRvIGdldCB0aGUgaW5kZXggd2hlcmUgaXQgc2hvdWxkIGhhdmVcbiAqICAgICBiZWVuLilcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGtleVZhbHVlQXJyYXlEZWxldGU8Vj4oa2V5VmFsdWVBcnJheTogS2V5VmFsdWVBcnJheTxWPiwga2V5OiBzdHJpbmcpOiBudW1iZXIge1xuICBjb25zdCBpbmRleCA9IGtleVZhbHVlQXJyYXlJbmRleE9mKGtleVZhbHVlQXJyYXksIGtleSk7XG4gIGlmIChpbmRleCA+PSAwKSB7XG4gICAgLy8gaWYgd2UgZm91bmQgaXQgcmVtb3ZlIGl0LlxuICAgIGFycmF5U3BsaWNlKGtleVZhbHVlQXJyYXksIGluZGV4LCAyKTtcbiAgfVxuICByZXR1cm4gaW5kZXg7XG59XG5cblxuLyoqXG4gKiBJTlRFUk5BTDogR2V0IGFuIGluZGV4IG9mIGFuIGB2YWx1ZWAgaW4gYSBzb3J0ZWQgYGFycmF5YCBieSBncm91cGluZyBzZWFyY2ggYnkgYHNoaWZ0YC5cbiAqXG4gKiBOT1RFOlxuICogLSBUaGlzIHVzZXMgYmluYXJ5IHNlYXJjaCBhbGdvcml0aG0gZm9yIGZhc3QgcmVtb3ZhbHMuXG4gKlxuICogQHBhcmFtIGFycmF5IEEgc29ydGVkIGFycmF5IHRvIGJpbmFyeSBzZWFyY2guXG4gKiBAcGFyYW0gdmFsdWUgVGhlIHZhbHVlIHRvIGxvb2sgZm9yLlxuICogQHBhcmFtIHNoaWZ0IGdyb3VwaW5nIHNoaWZ0LlxuICogICAtIGAwYCBtZWFucyBsb29rIGF0IGV2ZXJ5IGxvY2F0aW9uXG4gKiAgIC0gYDFgIG1lYW5zIG9ubHkgbG9vayBhdCBldmVyeSBvdGhlciAoZXZlbikgbG9jYXRpb24gKHRoZSBvZGQgbG9jYXRpb25zIGFyZSB0byBiZSBpZ25vcmVkIGFzXG4gKiAgICAgICAgIHRoZXkgYXJlIHZhbHVlcy4pXG4gKiBAcmV0dXJucyBpbmRleCBvZiB0aGUgdmFsdWUuXG4gKiAgIC0gcG9zaXRpdmUgaW5kZXggaWYgdmFsdWUgZm91bmQuXG4gKiAgIC0gbmVnYXRpdmUgaW5kZXggaWYgdmFsdWUgbm90IGZvdW5kLiAoYH5pbmRleGAgdG8gZ2V0IHRoZSB2YWx1ZSB3aGVyZSBpdCBzaG91bGQgaGF2ZSBiZWVuXG4gKiBpbnNlcnRlZClcbiAqL1xuZnVuY3Rpb24gX2FycmF5SW5kZXhPZlNvcnRlZChhcnJheTogc3RyaW5nW10sIHZhbHVlOiBzdHJpbmcsIHNoaWZ0OiBudW1iZXIpOiBudW1iZXIge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RXF1YWwoQXJyYXkuaXNBcnJheShhcnJheSksIHRydWUsICdFeHBlY3RpbmcgYW4gYXJyYXknKTtcbiAgbGV0IHN0YXJ0ID0gMDtcbiAgbGV0IGVuZCA9IGFycmF5Lmxlbmd0aCA+PiBzaGlmdDtcbiAgd2hpbGUgKGVuZCAhPT0gc3RhcnQpIHtcbiAgICBjb25zdCBtaWRkbGUgPSBzdGFydCArICgoZW5kIC0gc3RhcnQpID4+IDEpOyAgLy8gZmluZCB0aGUgbWlkZGxlLlxuICAgIGNvbnN0IGN1cnJlbnQgPSBhcnJheVttaWRkbGUgPDwgc2hpZnRdO1xuICAgIGlmICh2YWx1ZSA9PT0gY3VycmVudCkge1xuICAgICAgcmV0dXJuIChtaWRkbGUgPDwgc2hpZnQpO1xuICAgIH0gZWxzZSBpZiAoY3VycmVudCA+IHZhbHVlKSB7XG4gICAgICBlbmQgPSBtaWRkbGU7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0YXJ0ID0gbWlkZGxlICsgMTsgIC8vIFdlIGFscmVhZHkgc2VhcmNoZWQgbWlkZGxlIHNvIG1ha2UgaXQgbm9uLWluY2x1c2l2ZSBieSBhZGRpbmcgMVxuICAgIH1cbiAgfVxuICByZXR1cm4gfihlbmQgPDwgc2hpZnQpO1xufVxuIl19