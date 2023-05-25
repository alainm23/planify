/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { EventEmitter } from '../event_emitter';
import { arrayEquals, flatten } from '../util/array_utils';
function symbolIterator() {
    // @ts-expect-error accessing a private member
    return this._results[Symbol.iterator]();
}
/**
 * An unmodifiable list of items that Angular keeps up to date when the state
 * of the application changes.
 *
 * The type of object that {@link ViewChildren}, {@link ContentChildren}, and {@link QueryList}
 * provide.
 *
 * Implements an iterable interface, therefore it can be used in both ES6
 * javascript `for (var i of items)` loops as well as in Angular templates with
 * `*ngFor="let i of myList"`.
 *
 * Changes can be observed by subscribing to the changes `Observable`.
 *
 * NOTE: In the future this class will implement an `Observable` interface.
 *
 * @usageNotes
 * ### Example
 * ```typescript
 * @Component({...})
 * class Container {
 *   @ViewChildren(Item) items:QueryList<Item>;
 * }
 * ```
 *
 * @publicApi
 */
export class QueryList {
    static { Symbol.iterator; }
    /**
     * Returns `Observable` of `QueryList` notifying the subscriber of changes.
     */
    get changes() {
        return this._changes || (this._changes = new EventEmitter());
    }
    /**
     * @param emitDistinctChangesOnly Whether `QueryList.changes` should fire only when actual change
     *     has occurred. Or if it should fire when query is recomputed. (recomputing could resolve in
     *     the same result)
     */
    constructor(_emitDistinctChangesOnly = false) {
        this._emitDistinctChangesOnly = _emitDistinctChangesOnly;
        this.dirty = true;
        this._results = [];
        this._changesDetected = false;
        this._changes = null;
        this.length = 0;
        this.first = undefined;
        this.last = undefined;
        // This function should be declared on the prototype, but doing so there will cause the class
        // declaration to have side-effects and become not tree-shakable. For this reason we do it in
        // the constructor.
        // [Symbol.iterator](): Iterator<T> { ... }
        const proto = QueryList.prototype;
        if (!proto[Symbol.iterator])
            proto[Symbol.iterator] = symbolIterator;
    }
    /**
     * Returns the QueryList entry at `index`.
     */
    get(index) {
        return this._results[index];
    }
    /**
     * See
     * [Array.map](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map)
     */
    map(fn) {
        return this._results.map(fn);
    }
    filter(fn) {
        return this._results.filter(fn);
    }
    /**
     * See
     * [Array.find](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/find)
     */
    find(fn) {
        return this._results.find(fn);
    }
    /**
     * See
     * [Array.reduce](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)
     */
    reduce(fn, init) {
        return this._results.reduce(fn, init);
    }
    /**
     * See
     * [Array.forEach](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach)
     */
    forEach(fn) {
        this._results.forEach(fn);
    }
    /**
     * See
     * [Array.some](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/some)
     */
    some(fn) {
        return this._results.some(fn);
    }
    /**
     * Returns a copy of the internal results list as an Array.
     */
    toArray() {
        return this._results.slice();
    }
    toString() {
        return this._results.toString();
    }
    /**
     * Updates the stored data of the query list, and resets the `dirty` flag to `false`, so that
     * on change detection, it will not notify of changes to the queries, unless a new change
     * occurs.
     *
     * @param resultsTree The query results to store
     * @param identityAccessor Optional function for extracting stable object identity from a value
     *    in the array. This function is executed for each element of the query result list while
     *    comparing current query list with the new one (provided as a first argument of the `reset`
     *    function) to detect if the lists are different. If the function is not provided, elements
     *    are compared as is (without any pre-processing).
     */
    reset(resultsTree, identityAccessor) {
        // Cast to `QueryListInternal` so that we can mutate fields which are readonly for the usage of
        // QueryList (but not for QueryList itself.)
        const self = this;
        self.dirty = false;
        const newResultFlat = flatten(resultsTree);
        if (this._changesDetected = !arrayEquals(self._results, newResultFlat, identityAccessor)) {
            self._results = newResultFlat;
            self.length = newResultFlat.length;
            self.last = newResultFlat[this.length - 1];
            self.first = newResultFlat[0];
        }
    }
    /**
     * Triggers a change event by emitting on the `changes` {@link EventEmitter}.
     */
    notifyOnChanges() {
        if (this._changes && (this._changesDetected || !this._emitDistinctChangesOnly))
            this._changes.emit(this);
    }
    /** internal */
    setDirty() {
        this.dirty = true;
    }
    /** internal */
    destroy() {
        this.changes.complete();
        this.changes.unsubscribe();
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicXVlcnlfbGlzdC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2xpbmtlci9xdWVyeV9saXN0LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUlILE9BQU8sRUFBQyxZQUFZLEVBQUMsTUFBTSxrQkFBa0IsQ0FBQztBQUM5QyxPQUFPLEVBQUMsV0FBVyxFQUFFLE9BQU8sRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBRXpELFNBQVMsY0FBYztJQUNyQiw4Q0FBOEM7SUFDOUMsT0FBTyxJQUFJLENBQUMsUUFBUSxDQUFDLE1BQU0sQ0FBQyxRQUFRLENBQUMsRUFBRSxDQUFDO0FBQzFDLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQXlCRztBQUNILE1BQU0sT0FBTyxTQUFTO2FBcUpuQixNQUFNLENBQUMsUUFBUTtJQTNJaEI7O09BRUc7SUFDSCxJQUFJLE9BQU87UUFDVCxPQUFPLElBQUksQ0FBQyxRQUFRLElBQUksQ0FBQyxJQUFJLENBQUMsUUFBUSxHQUFHLElBQUksWUFBWSxFQUFFLENBQUMsQ0FBQztJQUMvRCxDQUFDO0lBRUQ7Ozs7T0FJRztJQUNILFlBQW9CLDJCQUFvQyxLQUFLO1FBQXpDLDZCQUF3QixHQUF4Qix3QkFBd0IsQ0FBaUI7UUFyQjdDLFVBQUssR0FBRyxJQUFJLENBQUM7UUFDckIsYUFBUSxHQUFhLEVBQUUsQ0FBQztRQUN4QixxQkFBZ0IsR0FBWSxLQUFLLENBQUM7UUFDbEMsYUFBUSxHQUFvQyxJQUFJLENBQUM7UUFFaEQsV0FBTSxHQUFXLENBQUMsQ0FBQztRQUNuQixVQUFLLEdBQU0sU0FBVSxDQUFDO1FBQ3RCLFNBQUksR0FBTSxTQUFVLENBQUM7UUFlNUIsNkZBQTZGO1FBQzdGLDZGQUE2RjtRQUM3RixtQkFBbUI7UUFDbkIsMkNBQTJDO1FBQzNDLE1BQU0sS0FBSyxHQUFHLFNBQVMsQ0FBQyxTQUFTLENB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Q0FRRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge09ic2VydmFibGV9IGZyb20gJ3J4anMnO1xuXG5pbXBvcnQge0V2ZW50RW1pdHRlcn0gZnJvbSAnLi4vZXZlbnRfZW1pdHRlcic7XG5pbXBvcnQge2FycmF5RXF1YWxzLCBmbGF0dGVufSBmcm9tICcuLi91dGlsL2FycmF5X3V0aWxzJztcblxuZnVuY3Rpb24gc3ltYm9sSXRlcmF0b3I8VD4odGhpczogUXVlcnlMaXN0PFQ+KTogSXRlcmF0b3I8VD4ge1xuICAvLyBAdHMtZXhwZWN0LWVycm9yIGFjY2Vzc2luZyBhIHByaXZhdGUgbWVtYmVyXG4gIHJldHVybiB0aGlzLl9yZXN1bHRzW1N5bWJvbC5pdGVyYXRvcl0oKTtcbn1cblxuLyoqXG4gKiBBbiB1bm1vZGlmaWFibGUgbGlzdCBvZiBpdGVtcyB0aGF0IEFuZ3VsYXIga2VlcHMgdXAgdG8gZGF0ZSB3aGVuIHRoZSBzdGF0ZVxuICogb2YgdGhlIGFwcGxpY2F0aW9uIGNoYW5nZXMuXG4gKlxuICogVGhlIHR5cGUgb2Ygb2JqZWN0IHRoYXQge0BsaW5rIFZpZXdDaGlsZHJlbn0sIHtAbGluayBDb250ZW50Q2hpbGRyZW59LCBhbmQge0BsaW5rIFF1ZXJ5TGlzdH1cbiAqIHByb3ZpZGUuXG4gKlxuICogSW1wbGVtZW50cyBhbiBpdGVyYWJsZSBpbnRlcmZhY2UsIHRoZXJlZm9yZSBpdCBjYW4gYmUgdXNlZCBpbiBib3RoIEVTNlxuICogamF2YXNjcmlwdCBgZm9yICh2YXIgaSBvZiBpdGVtcylgIGxvb3BzIGFzIHdlbGwgYXMgaW4gQW5ndWxhciB0ZW1wbGF0ZXMgd2l0aFxuICogYCpuZ0Zvcj1cImxldCBpIG9mIG15TGlzdFwiYC5cbiAqXG4gKiBDaGFuZ2VzIGNhbiBiZSBvYnNlcnZlZCBieSBzdWJzY3JpYmluZyB0byB0aGUgY2hhbmdlcyBgT2JzZXJ2YWJsZWAuXG4gKlxuICogTk9URTogSW4gdGhlIGZ1dHVyZSB0aGlzIGNsYXNzIHdpbGwgaW1wbGVtZW50IGFuIGBPYnNlcnZhYmxlYCBpbnRlcmZhY2UuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqICMjIyBFeGFtcGxlXG4gKiBgYGB0eXBlc2NyaXB0XG4gKiBAQ29tcG9uZW50KHsuLi59KVxuICogY2xhc3MgQ29udGFpbmVyIHtcbiAqICAgQFZpZXdDaGlsZHJlbihJdGVtKSBpdGVtczpRdWVyeUxpc3Q8SXRlbT47XG4gKiB9XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBRdWVyeUxpc3Q8VD4gaW1wbGVtZW50cyBJdGVyYWJsZTxUPiB7XG4gIHB1YmxpYyByZWFkb25seSBkaXJ0eSA9IHRydWU7XG4gIHByaXZhdGUgX3Jlc3VsdHM6IEFycmF5PFQ+ID0gW107XG4gIHByaXZhdGUgX2NoYW5nZXNEZXRlY3RlZDogYm9vbGVhbiA9IGZhbHNlO1xuICBwcml2YXRlIF9jaGFuZ2VzOiBFdmVudEVtaXR0ZXI8UXVlcnlMaXN0PFQ+PnxudWxsID0gbnVsbDtcblxuICByZWFkb25seSBsZW5ndGg6IG51bWJlciA9IDA7XG4gIHJlYWRvbmx5IGZpcnN0OiBUID0gdW5kZWZpbmVkITtcbiAgcmVhZG9ubHkgbGFzdDogVCA9IHVuZGVmaW5lZCE7XG5cbiAgLyoqXG4gICAqIFJldHVybnMgYE9ic2VydmFibGVgIG9mIGBRdWVyeUxpc3RgIG5vdGlmeWluZyB0aGUgc3Vic2NyaWJlciBvZiBjaGFuZ2VzLlxuICAgKi9cbiAgZ2V0IGNoYW5nZXMoKTogT2JzZXJ2YWJsZTxhbnk+IHtcbiAgICByZXR1cm4gdGhpcy5fY2hhbmdlcyB8fCAodGhpcy5fY2hhbmdlcyA9IG5ldyBFdmVudEVtaXR0ZXIoKSk7XG4gIH1cblxuICAvKipcbiAgICogQHBhcmFtIGVtaXREaXN0aW5jdENoYW5nZXNPbmx5IFdoZXRoZXIgYFF1ZXJ5TGlzdC5jaGFuZ2VzYCBzaG91bGQgZmlyZSBvbmx5IHdoZW4gYWN0dWFsIGNoYW5nZVxuICAgKiAgICAgaGFzIG9jY3VycmVkLiBPciBpZiBpdCBzaG91bGQgZmlyZSB3aGVuIHF1ZXJ5IGlzIHJlY29tcHV0ZWQuIChyZWNvbXB1dGluZyBjb3VsZCByZXNvbHZlIGluXG4gICAqICAgICB0aGUgc2FtZSByZXN1bHQpXG4gICAqL1xuICBjb25zdHJ1Y3Rvcihwcml2YXRlIF9lbWl0RGlzdGluY3RDaGFuZ2VzT25seTogYm9vbGVhbiA9IGZhbHNlKSB7XG4gICAgLy8gVGhpcyBmdW5jdGlvbiBzaG91bGQgYmUgZGVjbGFyZWQgb24gdGhlIHByb3RvdHlwZSwgYnV0IGRvaW5nIHNvIHRoZXJlIHdpbGwgY2F1c2UgdGhlIGNsYXNzXG4gICAgLy8gZGVjbGFyYXRpb24gdG8gaGF2ZSBzaWRlLWVmZmVjdHMgYW5kIGJlY29tZSBub3QgdHJlZS1zaGFrYWJsZS4gRm9yIHRoaXMgcmVhc29uIHdlIGRvIGl0IGluXG4gICAgLy8gdGhlIGNvbnN0cnVjdG9yLlxuICAgIC8vIFtTeW1ib2wuaXRlcmF0b3JdKCk6IEl0ZXJhdG9yPFQ+IHsgLi4uIH1cbiAgICBjb25zdCBwcm90byA9IFF1ZXJ5TGlzdC5wcm90b3R5cGU7XG4gICAgaWYgKCFwcm90b1tTeW1ib2wuaXRlcmF0b3JdKSBwcm90b1tTeW1ib2wuaXRlcmF0b3JdID0gc3ltYm9sSXRlcmF0b3I7XG4gIH1cblxuICAvKipcbiAgICogUmV0dXJucyB0aGUgUXVlcnlMaXN0IGVudHJ5IGF0IGBpbmRleGAuXG4gICAqL1xuICBnZXQoaW5kZXg6IG51bWJlcik6IFR8dW5kZWZpbmVkIHtcbiAgICByZXR1cm4gdGhpcy5fcmVzdWx0c1tpbmRleF07XG4gIH1cblxuICAvKipcbiAgICogU2VlXG4gICAqIFtBcnJheS5tYXBdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0phdmFTY3JpcHQvUmVmZXJlbmNlL0dsb2JhbF9PYmplY3RzL0FycmF5L21hcClcbiAgICovXG4gIG1hcDxVPihmbjogKGl0ZW06IFQsIGluZGV4OiBudW1iZXIsIGFycmF5OiBUW10pID0+IFUpOiBVW10ge1xuICAgIHJldHVybiB0aGlzLl9yZXN1bHRzLm1hcChmbik7XG4gIH1cblxuICAvKipcbiAgICogU2VlXG4gICAqIFtBcnJheS5maWx0ZXJdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0phdmFTY3JpcHQvUmVmZXJlbmNlL0dsb2JhbF9PYmplY3RzL0FycmF5L2ZpbHRlcilcbiAgICovXG4gIGZpbHRlcjxTIGV4dGVuZHMgVD4ocHJlZGljYXRlOiAodmFsdWU6IFQsIGluZGV4OiBudW1iZXIsIGFycmF5OiByZWFkb25seSBUW10pID0+IHZhbHVlIGlzIFMpOiBTW107XG4gIGZpbHRlcihwcmVkaWNhdGU6ICh2YWx1ZTogVCwgaW5kZXg6IG51bWJlciwgYXJyYXk6IHJlYWRvbmx5IFRbXSkgPT4gdW5rbm93bik6IFRbXTtcbiAgZmlsdGVyKGZuOiAoaXRlbTogVCwgaW5kZXg6IG51bWJlciwgYXJyYXk6IFRbXSkgPT4gYm9vbGVhbik6IFRbXSB7XG4gICAgcmV0dXJuIHRoaXMuX3Jlc3VsdHMuZmlsdGVyKGZuKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBTZWVcbiAgICogW0FycmF5LmZpbmRdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0phdmFTY3JpcHQvUmVmZXJlbmNlL0dsb2JhbF9PYmplY3RzL0FycmF5L2ZpbmQpXG4gICAqL1xuICBmaW5kKGZuOiAoaXRlbTogVCwgaW5kZXg6IG51bWJlciwgYXJyYXk6IFRbXSkgPT4gYm9vbGVhbik6IFR8dW5kZWZpbmVkIHtcbiAgICByZXR1cm4gdGhpcy5fcmVzdWx0cy5maW5kKGZuKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBTZWVcbiAgICogW0FycmF5LnJlZHVjZV0oaHR0cHM6Ly9kZXZlbG9wZXIubW96aWxsYS5vcmcvZW4tVVMvZG9jcy9XZWIvSmF2YVNjcmlwdC9SZWZlcmVuY2UvR2xvYmFsX09iamVjdHMvQXJyYXkvcmVkdWNlKVxuICAgKi9cbiAgcmVkdWNlPFU+KGZuOiAocHJldlZhbHVlOiBVLCBjdXJWYWx1ZTogVCwgY3VySW5kZXg6IG51bWJlciwgYXJyYXk6IFRbXSkgPT4gVSwgaW5pdDogVSk6IFUge1xuICAgIHJldHVybiB0aGlzLl9yZXN1bHRzLnJlZHVjZShmbiwgaW5pdCk7XG4gIH1cblxuICAvKipcbiAgICogU2VlXG4gICAqIFtBcnJheS5mb3JFYWNoXShodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9KYXZhU2NyaXB0L1JlZmVyZW5jZS9HbG9iYWxfT2JqZWN0cy9BcnJheS9mb3JFYWNoKVxuICAgKi9cbiAgZm9yRWFjaChmbjogKGl0ZW06IFQsIGluZGV4OiBudW1iZXIsIGFycmF5OiBUW10pID0+IHZvaWQpOiB2b2lkIHtcbiAgICB0aGlzLl9yZXN1bHRzLmZvckVhY2goZm4pO1xuICB9XG5cbiAgLyoqXG4gICAqIFNlZVxuICAgKiBbQXJyYXkuc29tZV0oaHR0cHM6Ly9kZXZlbG9wZXIubW96aWxsYS5vcmcvZW4tVVMvZG9jcy9XZWIvSmF2YVNjcmlwdC9SZWZlcmVuY2UvR2xvYmFsX09iamVjdHMvQXJyYXkvc29tZSlcbiAgICovXG4gIHNvbWUoZm46ICh2YWx1ZTogVCwgaW5kZXg6IG51bWJlciwgYXJyYXk6IFRbXSkgPT4gYm9vbGVhbik6IGJvb2xlYW4ge1xuICAgIHJldHVybiB0aGlzLl9yZXN1bHRzLnNvbWUoZm4pO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHVybnMgYSBjb3B5IG9mIHRoZSBpbnRlcm5hbCByZXN1bHRzIGxpc3QgYXMgYW4gQXJyYXkuXG4gICAqL1xuICB0b0FycmF5KCk6IFRbXSB7XG4gICAgcmV0dXJuIHRoaXMuX3Jlc3VsdHMuc2xpY2UoKTtcbiAgfVxuXG4gIHRvU3RyaW5nKCk6IHN0cmluZyB7XG4gICAgcmV0dXJuIHRoaXMuX3Jlc3VsdHMudG9TdHJpbmcoKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBVcGRhdGVzIHRoZSBzdG9yZWQgZGF0YSBvZiB0aGUgcXVlcnkgbGlzdCwgYW5kIHJlc2V0cyB0aGUgYGRpcnR5YCBmbGFnIHRvIGBmYWxzZWAsIHNvIHRoYXRcbiAgICogb24gY2hhbmdlIGRldGVjdGlvbiwgaXQgd2lsbCBub3Qgbm90aWZ5IG9mIGNoYW5nZXMgdG8gdGhlIHF1ZXJpZXMsIHVubGVzcyBhIG5ldyBjaGFuZ2VcbiAgICogb2NjdXJzLlxuICAgKlxuICAgKiBAcGFyYW0gcmVzdWx0c1RyZWUgVGhlIHF1ZXJ5IHJlc3VsdHMgdG8gc3RvcmVcbiAgICogQHBhcmFtIGlkZW50aXR5QWNjZXNzb3IgT3B0aW9uYWwgZnVuY3Rpb24gZm9yIGV4dHJhY3Rpbmcgc3RhYmxlIG9iamVjdCBpZGVudGl0eSBmcm9tIGEgdmFsdWVcbiAgICogICAgaW4gdGhlIGFycmF5LiBUaGlzIGZ1bmN0aW9uIGlzIGV4ZWN1dGVkIGZvciBlYWNoIGVsZW1lbnQgb2YgdGhlIHF1ZXJ5IHJlc3VsdCBsaXN0IHdoaWxlXG4gICAqICAgIGNvbXBhcmluZyBjdXJyZW50IHF1ZXJ5IGxpc3Qgd2l0aCB0aGUgbmV3IG9uZSAocHJvdmlkZWQgYXMgYSBmaXJzdCBhcmd1bWVudCBvZiB0aGUgYHJlc2V0YFxuICAgKiAgICBmdW5jdGlvbikgdG8gZGV0ZWN0IGlmIHRoZSBsaXN0cyBhcmUgZGlmZmVyZW50LiBJZiB0aGUgZnVuY3Rpb24gaXMgbm90IHByb3ZpZGVkLCBlbGVtZW50c1xuICAgKiAgICBhcmUgY29tcGFyZWQgYXMgaXMgKHdpdGhvdXQgYW55IHByZS1wcm9jZXNzaW5nKS5cbiAgICovXG4gIHJlc2V0KHJlc3VsdHNUcmVlOiBBcnJheTxUfGFueVtdPiwgaWRlbnRpdHlBY2Nlc3Nvcj86ICh2YWx1ZTogVCkgPT4gdW5rbm93bik6IHZvaWQge1xuICAgIC8vIENhc3QgdG8gYFF1ZXJ5TGlzdEludGVybmFsYCBzbyB0aGF0IHdlIGNhbiBtdXRhdGUgZmllbGRzIHdoaWNoIGFyZSByZWFkb25seSBmb3IgdGhlIHVzYWdlIG9mXG4gICAgLy8gUXVlcnlMaXN0IChidXQgbm90IGZvciBRdWVyeUxpc3QgaXRzZWxmLilcbiAgICBjb25zdCBzZWxmID0gdGhpcyBhcyBRdWVyeUxpc3RJbnRlcm5hbDxUPjtcbiAgICAoc2VsZiBhcyB7ZGlydHk6IGJvb2xlYW59KS5kaXJ0eSA9IGZhbHNlO1xuICAgIGNvbnN0IG5ld1Jlc3VsdEZsYXQgPSBmbGF0dGVuKHJlc3VsdHNUcmVlKTtcbiAgICBpZiAodGhpcy5fY2hhbmdlc0RldGVjdGVkID0gIWFycmF5RXF1YWxzKHNlbGYuX3Jlc3VsdHMsIG5ld1Jlc3VsdEZsYXQsIGlkZW50aXR5QWNjZXNzb3IpKSB7XG4gICAgICBzZWxmLl9yZXN1bHRzID0gbmV3UmVzdWx0RmxhdDtcbiAgICAgIHNlbGYubGVuZ3RoID0gbmV3UmVzdWx0RmxhdC5sZW5ndGg7XG4gICAgICBzZWxmLmxhc3QgPSBuZXdSZXN1bHRGbGF0W3RoaXMubGVuZ3RoIC0gMV07XG4gICAgICBzZWxmLmZpcnN0ID0gbmV3UmVzdWx0RmxhdFswXTtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogVHJpZ2dlcnMgYSBjaGFuZ2UgZXZlbnQgYnkgZW1pdHRpbmcgb24gdGhlIGBjaGFuZ2VzYCB7QGxpbmsgRXZlbnRFbWl0dGVyfS5cbiAgICovXG4gIG5vdGlmeU9uQ2hhbmdlcygpOiB2b2lkIHtcbiAgICBpZiAodGhpcy5fY2hhbmdlcyAmJiAodGhpcy5fY2hhbmdlc0RldGVjdGVkIHx8ICF0aGlzLl9lbWl0RGlzdGluY3RDaGFuZ2VzT25seSkpXG4gICAgICB0aGlzLl9jaGFuZ2VzLmVtaXQodGhpcyk7XG4gIH1cblxuICAvKiogaW50ZXJuYWwgKi9cbiAgc2V0RGlydHkoKSB7XG4gICAgKHRoaXMgYXMge2RpcnR5OiBib29sZWFufSkuZGlydHkgPSB0cnVlO1xuICB9XG5cbiAgLyoqIGludGVybmFsICovXG4gIGRlc3Ryb3koKTogdm9pZCB7XG4gICAgKHRoaXMuY2hhbmdlcyBhcyBFdmVudEVtaXR0ZXI8YW55PikuY29tcGxldGUoKTtcbiAgICAodGhpcy5jaGFuZ2VzIGFzIEV2ZW50RW1pdHRlcjxhbnk+KS51bnN1YnNjcmliZSgpO1xuICB9XG5cbiAgLy8gVGhlIGltcGxlbWVudGF0aW9uIG9mIGBTeW1ib2wuaXRlcmF0b3JgIHNob3VsZCBiZSBkZWNsYXJlZCBoZXJlLCBidXQgdGhpcyB3b3VsZCBjYXVzZVxuICAvLyB0cmVlLXNoYWtpbmcgaXNzdWVzIHdpdGggYFF1ZXJ5TGlzdC4gU28gaW5zdGVhZCwgaXQncyBhZGRlZCBpbiB0aGUgY29uc3RydWN0b3IgKHNlZSBjb21tZW50c1xuICAvLyB0aGVyZSkgYW5kIHRoaXMgZGVjbGFyYXRpb24gaXMgbGVmdCBoZXJlIHRvIGVuc3VyZSB0aGF0IFR5cGVTY3JpcHQgY29uc2lkZXJzIFF1ZXJ5TGlzdCB0b1xuICAvLyBpbXBsZW1lbnQgdGhlIEl0ZXJhYmxlIGludGVyZmFjZS4gVGhpcyBpcyByZXF1aXJlZCBmb3IgdGVtcGxhdGUgdHlwZS1jaGVja2luZyBvZiBOZ0ZvciBsb29wc1xuICAvLyBvdmVyIFF1ZXJ5TGlzdHMgdG8gd29yayBjb3JyZWN0bHksIHNpbmNlIFF1ZXJ5TGlzdCBtdXN0IGJlIGFzc2lnbmFibGUgdG8gTmdJdGVyYWJsZS5cbiAgW1N5bWJvbC5pdGVyYXRvcl0hOiAoKSA9PiBJdGVyYXRvcjxUPjtcbn1cblxuLyoqXG4gKiBJbnRlcm5hbCBzZXQgb2YgQVBJcyB1c2VkIGJ5IHRoZSBmcmFtZXdvcmsuIChub3QgdG8gYmUgbWFkZSBwdWJsaWMpXG4gKi9cbmludGVyZmFjZSBRdWVyeUxpc3RJbnRlcm5hbDxUPiBleHRlbmRzIFF1ZXJ5TGlzdDxUPiB7XG4gIHJlc2V0KGE6IGFueVtdKTogdm9pZDtcbiAgbm90aWZ5T25DaGFuZ2VzKCk6IHZvaWQ7XG4gIGxlbmd0aDogbnVtYmVyO1xuICBsYXN0OiBUO1xuICBmaXJzdDogVDtcbn1cbiJdfQ==