/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { createSignalFromFunction, defaultEquals } from './api';
import { ReactiveNode, setActiveConsumer } from './graph';
/**
 * Create a computed `Signal` which derives a reactive value from an expression.
 *
 * @developerPreview
 */
export function computed(computation, options) {
    const node = new ComputedImpl(computation, options?.equal ?? defaultEquals);
    // Casting here is required for g3, as TS inference behavior is slightly different between our
    // version/options and g3's.
    return createSignalFromFunction(node, node.signal.bind(node));
}
/**
 * A dedicated symbol used before a computed value has been calculated for the first time.
 * Explicitly typed as `any` so we can use it as signal's value.
 */
const UNSET = Symbol('UNSET');
/**
 * A dedicated symbol used in place of a computed signal value to indicate that a given computation
 * is in progress. Used to detect cycles in computation chains.
 * Explicitly typed as `any` so we can use it as signal's value.
 */
const COMPUTING = Symbol('COMPUTING');
/**
 * A dedicated symbol used in place of a computed signal value to indicate that a given computation
 * failed. The thrown error is cached until the computation gets dirty again.
 * Explicitly typed as `any` so we can use it as signal's value.
 */
const ERRORED = Symbol('ERRORED');
/**
 * A computation, which derives a value from a declarative reactive expression.
 *
 * `Computed`s are both producers and consumers of reactivity.
 */
class ComputedImpl extends ReactiveNode {
    constructor(computation, equal) {
        super();
        this.computation = computation;
        this.equal = equal;
        /**
         * Current value of the computation.
         *
         * This can also be one of the special values `UNSET`, `COMPUTING`, or `ERRORED`.
         */
        this.value = UNSET;
        /**
         * If `value` is `ERRORED`, the error caught from the last computation attempt which will
         * be re-thrown.
         */
        this.error = null;
        /**
         * Flag indicating that the computation is currently stale, meaning that one of the
         * dependencies has notified of a potential change.
         *
         * It's possible that no dependency has _actually_ changed, in which case the `stale`
         * state can be resolved without recomputing the value.
         */
        this.stale = true;
        this.consumerAllowSignalWrites = false;
    }
    onConsumerDependencyMayHaveChanged() {
        if (this.stale) {
            // We've already notified consumers that this value has potentially changed.
            return;
        }
        // Record that the currently cached value may be stale.
        this.stale = true;
        // Notify any consumers about the potential change.
        this.producerMayHaveChanged();
    }
    onProducerUpdateValueVersion() {
        if (!this.stale) {
            // The current value and its version are already up to date.
            return;
        }
        // The current value is stale. Check whether we need to produce a new one.
        if (this.value !== UNSET && this.value !== COMPUTING &&
            !this.consumerPollProducersForChange()) {
            // Even though we were previously notified of a potential dependency update, all of
            // our dependencies report that they have not actually changed in value, so we can
            // resolve the stale state without needing to recompute the current value.
            this.stale = false;
            return;
        }
        // The current value is stale, and needs to be recomputed. It still may not change -
        // that depends on whether the newly computed value is equal to the old.
        this.recomputeValue();
    }
    recomputeValue() {
        if (this.value === COMPUTING) {
            // Our computation somehow led to a cyclic read of itself.
            throw new Error('Detected cycle in computations.');
        }
        const oldValue = this.value;
        this.value = COMPUTING;
        // As we're re-running the computation, update our dependent tracking version number.
        this.trackingVersion++;
        const prevConsumer = setActiveConsumer(this);
        let newValue;
        try {
            newValue = this.computation();
        }
        catch (err) {
            newValue = ERRORED;
            this.error = err;
        }
        finally {
            setActiveConsumer(prevConsumer);
        }
        this.stale = false;
        if (oldValue !== UNSET && oldValue !== ERRORED && newValue !== ERRORED &&
            this.equal(oldValue, newValue)) {
            // No change to `valueVersion` - old and new values are
            // semantically equivalent.
            this.value = oldValue;
            return;
        }
        this.value = newValue;
        this.valueVersion++;
    }
    signal() {
        // Check if the value needs updating before returning it.
        this.onProducerUpdateValueVersion();
        // Record that someone looked at this signal.
        this.producerAccessed();
        if (this.value === ERRORED) {
            throw this.error;
        }
        return this.value;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29tcHV0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9zaWduYWxzL3NyYy9jb21wdXRlZC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxPQUFPLEVBQUMsd0JBQXdCLEVBQUUsYUFBYSxFQUEwQixNQUFNLE9BQU8sQ0FBQztBQUN2RixPQUFPLEVBQUMsWUFBWSxFQUFFLGlCQUFpQixFQUFDLE1BQU0sU0FBUyxDQUFDO0FBZXhEOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsUUFBUSxDQUFJLFdBQW9CLEVBQUUsT0FBa0M7SUFDbEYsTUFBTSxJQUFJLEdBQUcsSUFBSSxZQUFZLENBQUMsV0FBVyxFQUFFLE9BQU8sRUFBRSxLQUFLLElBQUksYUFBYSxDQUFDLENBQUM7SUFFNUUsOEZBQThGO0lBQzlGLDRCQUE0QjtJQUM1QixPQUFPLHdCQUF3QixDQUFDLElBQUksRUFBRSxJQUFJLENBQUMsTUFBTSxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBeUIsQ0FBQztBQUN4RixDQUFDO0FBRUQ7OztHQUdHO0FBQ0gsTUFBTSxLQUFLLEdBQVEsTUFBTSxDQUFDLE9BQU8sQ0FBQyxDQUFDO0FBRW5DOzs7O0dBSUc7QUFDSCxNQUFNLFNBQVMsR0FBUSxNQUFNLENBQUMsV0FBVyxDQUFDLENBQUM7QUFFM0M7Ozs7R0FJRztBQUNILE1BQU0sT0FBTyxHQUFRLE1BQU0sQ0FBQyxTQUFTLENBQUMsQ0FBQztBQUV2Qzs7OztHQUlHO0FBQ0gsTUFBTSxZQUFnQixTQUFRLFlBQVk7SUFDeEMsWUFBb0IsV0FBb0IsRUFBVSxLQUE0QztRQUM1RixLQUFLLEVBQUUsQ0FBQztRQURVLGdCQUFXLEdBQVgsV0FBVyxDQUFTO1FBQVUsVUFBSyxHQUFMLEtBQUssQ0FBdUM7UUFHOUY7Ozs7V0FJRztRQUNLLFVBQUssR0FBTSxLQUFLLENBQUM7UUFFekI7OztXQUdHO1FBQ0ssVUFBSyxHQUFZLElBQUksQ0FBQztRQUU5Qjs7Ozs7O1dBTUc7UUFDSyxVQUFLLEdBQUcsSUFBSSxDQUFDO1FBRU8sOEJBQXlCLEdBQUcsS0FBSyxDQUFDO0lBdkI5RCxDQUFDO0lBeUJrQixrQ0FBa0M7UUFDbkQsSUFBSSxJQUFJLENBQUMsS0FBSyxFQUFFO1lBQ2QsNEVBQTRFO1lBQzVFLE9BQU87U0FDUjtRQUVELHVEQUF1RDtRQUN2RCxJQUFJLENBQUMsS0FBSyxHQUFHLElBQUksQ0FBQztRQUVsQixtREFBbUQ7UUFDbkQsSUFBSSxDQUFDLHNCQUFzQixFQUFFLENBQUM7SUFDaEMsQ0FBQztJQUVrQiw0QkFBNEI7UUFDN0MsSUFBSSxDQUFDLElBQUksQ0FBQyxLQUFLLEVBQUU7WUFDZiw0REFBNEQ7WUFDNUQsT0FBTztTQUNSO1FBRUQsMEVBQTBFO1FBRTFFLElBQUksSUFBSSxDQUFDLEtBQUssS0FBSyxLQUFLLElBQUksSUFBSSxDQUFDLEtBQUssS0FBSyxTQUFTO1lBQ2hELENBQUMsSUFBSSxDQUFDLDhCQUE4QixFQUFFLEVBQUU7WUFDMUMsbUZBQW1GO1lBQ25GLGtGQUFrRjtZQUNsRiwwRUFBMEU7WUFDMUUsSUFBSSxDQUFDLEtBQUssR0FBRyxLQUFLLENBQUM7WUFDbkIsT0FBTztTQUNSO1FBRUQsb0ZBQW9GO1FBQ3BGLHdFQUF3RTtRQUN4RSxJQUFJLENBQUMsY0FBYyxFQUFFLENBQUM7SUFDeEIsQ0FBQztJQUVPLGNBQWM7UUFDcEIsSUFBSSxJQUFJLENBQUMsS0FBSyxLQUFLLFNBQVMsRUFBRTtZQUM1QiwwREFBMEQ7WUFDMUQsTUFBTSxJQUFJLEtBQUssQ0FBQyxpQ0FBaUMsQ0FBQyxDQUFDO1NBQ3BEO1FBRUQsTUFBTSxRQUFRLEdBQUcsSUFBSSxDQUFDLEtBQUssQ0FBQztRQUM1QixJQUFJLENBQUMsS0FBSyxHQUFHLFNBQVMsQ0FBQztRQUV2QixxRkFBcUY7UUFDckYsSUFBSSxDQUFDLGVBQWUsRUFBRSxDQUFDO1FBQ3ZCLE1BQU0sWUFBWSxHQUFHLGlCQUFpQixDQUFDLElBQUksQ0FBQyxDQUFDO1FBQzdDLElBQUksUUFBVyxDQUFDO1FBQ2hCLElBQUk7WUFDRixRQUFRLEdBQUcsSUFBSSxDQUFDLFdBQVcsRUFBRSxDQUFDO1NBQy9CO1FBQUMsT0FBTyxHQUFHLEVBQUU7WUFDWixRQUFRLEdBQUcsT0FBTyxDQUFDO1lBQ25CLElBQUksQ0FBQyxLQUFLLEdBQUcsR0FBRyxDQUFDO1NBQ2xCO2dCQUFTO1lBQ1IsaUJBQWlCLENBQUMsWUFBWSxDQUFDLENBQUM7U0FDakM7UUFFRCxJQUFJLENBQUMsS0FBSyxHQUFHLEtBQUssQ0FBQztRQUVuQixJQUFJLFFBQVEsS0FBSyxLQUFLLElBQUksUUFBUSxLQUFLLE9BQU8sSUFBSSxRQUFRLEtBQUssT0FBTztZQUNsRSxJQUFJLENBQUMsS0FBSyxDQUFDLFFBQVEsRUFBRSxRQUFRLENBQUMsRUFBRTtZQUNsQyx1REFBdUQ7WUFDdkQsMkJBQTJCO1lBQzNCLElBQUksQ0FBQyxLQUFLLEdBQUcsUUFBUSxDQUFDO1lBQ3RCLE9BQU87U0FDUjtRQUVELElBQUksQ0FBQyxLQUFLLEdBQUcsUUFBUSxDQUFDO1FBQ3RCLElBQUksQ0FBQyxZQUFZLEVBQUUsQ0FBQztJQUN0QixDQUFDO0lBRUQsTUFBTTtRQUNKLHlEQUF5RDtRQUN6RCxJQUFJLENBQUMsNEJBQTRCLEVBQUUsQ0FBQztRQUVwQyw2Q0FBNkM7UUFDN0MsSUFBSSxDQUFDLGdCQUFnQixFQUFFLENBQUM7UUFFeEIsSUFBSSxJQUFJLENBQUMsS0FBSyxLQUFLLE9BQU8sRUFBRTtZQUMxQixNQUFNLElBQUksQ0FBQyxLQUFLLENBQUM7U0FDbEI7UUFFRCxPQUFPLElBQUksQ0FBQyxLQUFLLENBQUM7SUFDcEIsQ0FBQztDQUNGIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Y3JlYXRlU2lnbmFsRnJvbUZ1bmN0aW9uLCBkZWZhdWx0RXF1YWxzLCBTaWduYWwsIFZhbHVlRXF1YWxpdHlGbn0gZnJvbSAnLi9hcGknO1xuaW1wb3J0IHtSZWFjdGl2ZU5vZGUsIHNldEFjdGl2ZUNvbnN1bWVyfSBmcm9tICcuL2dyYXBoJztcblxuLyoqXG4gKiBPcHRpb25zIHBhc3NlZCB0byB0aGUgYGNvbXB1dGVkYCBjcmVhdGlvbiBmdW5jdGlvbi5cbiAqXG4gKiBAZGV2ZWxvcGVyUHJldmlld1xuICovXG5leHBvcnQgaW50ZXJmYWNlIENyZWF0ZUNvbXB1dGVkT3B0aW9uczxUPiB7XG4gIC8qKlxuICAgKiBBIGNvbXBhcmlzb24gZnVuY3Rpb24gd2hpY2ggZGVmaW5lcyBlcXVhbGl0eSBmb3IgY29tcHV0ZWQgdmFsdWVzLlxuICAgKi9cbiAgZXF1YWw/OiBWYWx1ZUVxdWFsaXR5Rm48VD47XG59XG5cblxuLyoqXG4gKiBDcmVhdGUgYSBjb21wdXRlZCBgU2lnbmFsYCB3aGljaCBkZXJpdmVzIGEgcmVhY3RpdmUgdmFsdWUgZnJvbSBhbiBleHByZXNzaW9uLlxuICpcbiAqIEBkZXZlbG9wZXJQcmV2aWV3XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjb21wdXRlZDxUPihjb21wdXRhdGlvbjogKCkgPT4gVCwgb3B0aW9ucz86IENyZWF0ZUNvbXB1dGVkT3B0aW9uczxUPik6IFNpZ25hbDxUPiB7XG4gIGNvbnN0IG5vZGUgPSBuZXcgQ29tcHV0ZWRJbXBsKGNvbXB1dGF0aW9uLCBvcHRpb25zPy5lcXVhbCA/PyBkZWZhdWx0RXF1YWxzKTtcblxuICAvLyBDYXN0aW5nIGhlcmUgaXMgcmVxdWlyZWQgZm9yIGczLCBhcyBUUyBpbmZlcmVuY2UgYmVoYXZpb3IgaXMgc2xpZ2h0bHkgZGlmZmVyZW50IGJldHdlZW4gb3VyXG4gIC8vIHZlcnNpb24vb3B0aW9ucyBhbmQgZzMncy5cbiAgcmV0dXJuIGNyZWF0ZVNpZ25hbEZyb21GdW5jdGlvbihub2RlLCBub2RlLnNpZ25hbC5iaW5kKG5vZGUpKSBhcyB1bmtub3duIGFzIFNpZ25hbDxUPjtcbn1cblxuLyoqXG4gKiBBIGRlZGljYXRlZCBzeW1ib2wgdXNlZCBiZWZvcmUgYSBjb21wdXRlZCB2YWx1ZSBoYXMgYmVlbiBjYWxjdWxhdGVkIGZvciB0aGUgZmlyc3QgdGltZS5cbiAqIEV4cGxpY2l0bHkgdHlwZWQgYXMgYGFueWAgc28gd2UgY2FuIHVzZSBpdCBhcyBzaWduYWwncyB2YWx1ZS5cbiAqL1xuY29uc3QgVU5TRVQ6IGFueSA9IFN5bWJvbCgnVU5TRVQnKTtcblxuLyoqXG4gKiBBIGRlZGljYXRlZCBzeW1ib2wgdXNlZCBpbiBwbGFjZSBvZiBhIGNvbXB1dGVkIHNpZ25hbCB2YWx1ZSB0byBpbmRpY2F0ZSB0aGF0IGEgZ2l2ZW4gY29tcHV0YXRpb25cbiAqIGlzIGluIHByb2dyZXNzLiBVc2VkIHRvIGRldGVjdCBjeWNsZXMgaW4gY29tcHV0YXRpb24gY2hhaW5zLlxuICogRXhwbGljaXRseSB0eXBlZCBhcyBgYW55YCBzbyB3ZSBjYW4gdXNlIGl0IGFzIHNpZ25hbCdzIHZhbHVlLlxuICovXG5jb25zdCBDT01QVVRJTkc6IGFueSA9IFN5bWJvbCgnQ09NUFVUSU5HJyk7XG5cbi8qKlxuICogQSBkZWRpY2F0ZWQgc3ltYm9sIHVzZWQgaW4gcGxhY2Ugb2YgYSBjb21wdXRlZCBzaWduYWwgdmFsdWUgdG8gaW5kaWNhdGUgdGhhdCBhIGdpdmVuIGNvbXB1dGF0aW9uXG4gKiBmYWlsZWQuIFRoZSB0aHJvd24gZXJyb3IgaXMgY2FjaGVkIHVudGlsIHRoZSBjb21wdXRhdGlvbiBnZXRzIGRpcnR5IGFnYWluLlxuICogRXhwbGljaXRseSB0eXBlZCBhcyBgYW55YCBzbyB3ZSBjYW4gdXNlIGl0IGFzIHNpZ25hbCdzIHZhbHVlLlxuICovXG5jb25zdCBFUlJPUkVEOiBhbnkgPSBTeW1ib2woJ0VSUk9SRUQnKTtcblxuLyoqXG4gKiBBIGNvbXB1dGF0aW9uLCB3aGljaCBkZXJpdmVzIGEgdmFsdWUgZnJvbSBhIGRlY2xhcmF0aXZlIHJlYWN0aXZlIGV4cHJlc3Npb24uXG4gKlxuICogYENvbXB1dGVkYHMgYXJlIGJvdGggcHJvZHVjZXJzIGFuZCBjb25zdW1lcnMgb2YgcmVhY3Rpdml0eS5cbiAqL1xuY2xhc3MgQ29tcHV0ZWRJbXBsPFQ+IGV4dGVuZHMgUmVhY3RpdmVOb2RlIHtcbiAgY29uc3RydWN0b3IocHJpdmF0ZSBjb21wdXRhdGlvbjogKCkgPT4gVCwgcHJpdmF0ZSBlcXVhbDogKG9sZFZhbHVlOiBULCBuZXdWYWx1ZTogVCkgPT4gYm9vbGVhbikge1xuICAgIHN1cGVyKCk7XG4gIH1cbiAgLyoqXG4gICAqIEN1cnJlbnQgdmFsdWUgb2YgdGhlIGNvbXB1dGF0aW9uLlxuICAgKlxuICAgKiBUaGlzIGNhbiBhbHNvIGJlIG9uZSBvZiB0aGUgc3BlY2lhbCB2YWx1ZXMgYFVOU0VUYCwgYENPTVBVVElOR2AsIG9yIGBFUlJPUkVEYC5cbiAgICovXG4gIHByaXZhdGUgdmFsdWU6IFQgPSBVTlNFVDtcblxuICAvKipcbiAgICogSWYgYHZhbHVlYCBpcyBgRVJST1JFRGAsIHRoZSBlcnJvciBjYXVnaHQgZnJvbSB0aGUgbGFzdCBjb21wdXRhdGlvbiBhdHRlbXB0IHdoaWNoIHdpbGxcbiAgICogYmUgcmUtdGhyb3duLlxuICAgKi9cbiAgcHJpdmF0ZSBlcnJvcjogdW5rbm93biA9IG51bGw7XG5cbiAgLyoqXG4gICAqIEZsYWcgaW5kaWNhdGluZyB0aGF0IHRoZSBjb21wdXRhdGlvbiBpcyBjdXJyZW50bHkgc3RhbGUsIG1lYW5pbmcgdGhhdCBvbmUgb2YgdGhlXG4gICAqIGRlcGVuZGVuY2llcyBoYXMgbm90aWZpZWQgb2YgYSBwb3RlbnRpYWwgY2hhbmdlLlxuICAgKlxuICAgKiBJdCdzIHBvc3NpYmxlIHRoYXQgbm8gZGVwZW5kZW5jeSBoYXMgX2FjdHVhbGx5XyBjaGFuZ2VkLCBpbiB3aGljaCBjYXNlIHRoZSBgc3RhbGVgXG4gICAqIHN0YXRlIGNhbiBiZSByZXNvbHZlZCB3aXRob3V0IHJlY29tcHV0aW5nIHRoZSB2YWx1ZS5cbiAgICovXG4gIHByaXZhdGUgc3RhbGUgPSB0cnVlO1xuXG4gIHByb3RlY3RlZCBvdmVycmlkZSByZWFkb25seSBjb25zdW1lckFsbG93U2lnbmFsV3JpdGVzID0gZmFsc2U7XG5cbiAgcHJvdGVjdGVkIG92ZXJyaWRlIG9uQ29uc3VtZXJEZXBlbmRlbmN5TWF5SGF2ZUNoYW5nZWQoKTogdm9pZCB7XG4gICAgaWYgKHRoaXMuc3RhbGUpIHtcbiAgICAgIC8vIFdlJ3ZlIGFscmVhZHkgbm90aWZpZWQgY29uc3VtZXJzIHRoYXQgdGhpcyB2YWx1ZSBoYXMgcG90ZW50aWFsbHkgY2hhbmdlZC5cbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyBSZWNvcmQgdGhhdCB0aGUgY3VycmVudGx5IGNhY2hlZCB2YWx1ZSBtYXkgYmUgc3RhbGUuXG4gICAgdGhpcy5zdGFsZSA9IHRydWU7XG5cbiAgICAvLyBOb3RpZnkgYW55IGNvbnN1bWVycyBhYm91dCB0aGUgcG90ZW50aWFsIGNoYW5nZS5cbiAgICB0aGlzLnByb2R1Y2VyTWF5SGF2ZUNoYW5nZWQoKTtcbiAgfVxuXG4gIHByb3RlY3RlZCBvdmVycmlkZSBvblByb2R1Y2VyVXBkYXRlVmFsdWVWZXJzaW9uKCk6IHZvaWQge1xuICAgIGlmICghdGhpcy5zdGFsZSkge1xuICAgICAgLy8gVGhlIGN1cnJlbnQgdmFsdWUgYW5kIGl0cyB2ZXJzaW9uIGFyZSBhbHJlYWR5IHVwIHRvIGRhdGUuXG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gVGhlIGN1cnJlbnQgdmFsdWUgaXMgc3RhbGUuIENoZWNrIHdoZXRoZXIgd2UgbmVlZCB0byBwcm9kdWNlIGEgbmV3IG9uZS5cblxuICAgIGlmICh0aGlzLnZhbHVlICE9PSBVTlNFVCAmJiB0aGlzLnZhbHVlICE9PSBDT01QVVRJTkcgJiZcbiAgICAgICAgIXRoaXMuY29uc3VtZXJQb2xsUHJvZHVjZXJzRm9yQ2hhbmdlKCkpIHtcbiAgICAgIC8vIEV2ZW4gdGhvdWdoIHdlIHdlcmUgcHJldmlvdXNseSBub3RpZmllZCBvZiBhIHBvdGVudGlhbCBkZXBlbmRlbmN5IHVwZGF0ZSwgYWxsIG9mXG4gICAgICAvLyBvdXIgZGVwZW5kZW5jaWVzIHJlcG9ydCB0aGF0IHRoZXkgaGF2ZSBub3QgYWN0dWFsbHkgY2hhbmdlZCBpbiB2YWx1ZSwgc28gd2UgY2FuXG4gICAgICAvLyByZXNvbHZlIHRoZSBzdGFsZSBzdGF0ZSB3aXRob3V0IG5lZWRpbmcgdG8gcmVjb21wdXRlIHRoZSBjdXJyZW50IHZhbHVlLlxuICAgICAgdGhpcy5zdGFsZSA9IGZhbHNlO1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIC8vIFRoZSBjdXJyZW50IHZhbHVlIGlzIHN0YWxlLCBhbmQgbmVlZHMgdG8gYmUgcmVjb21wdXRlZC4gSXQgc3RpbGwgbWF5IG5vdCBjaGFuZ2UgLVxuICAgIC8vIHRoYXQgZGVwZW5kcyBvbiB3aGV0aGVyIHRoZSBuZXdseSBjb21wdXRlZCB2YWx1ZSBpcyBlcXVhbCB0byB0aGUgb2xkLlxuICAgIHRoaXMucmVjb21wdXRlVmFsdWUoKTtcbiAgfVxuXG4gIHByaXZhdGUgcmVjb21wdXRlVmFsdWUoKTogdm9pZCB7XG4gICAgaWYgKHRoaXMudmFsdWUgPT09IENPTVBVVElORykge1xuICAgICAgLy8gT3VyIGNvbXB1dGF0aW9uIHNvbWVob3cgbGVkIHRvIGEgY3ljbGljIHJlYWQgb2YgaXRzZWxmLlxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdEZXRlY3RlZCBjeWNsZSBpbiBjb21wdXRhdGlvbnMuJyk7XG4gICAgfVxuXG4gICAgY29uc3Qgb2xkVmFsdWUgPSB0aGlzLnZhbHVlO1xuICAgIHRoaXMudmFsdWUgPSBDT01QVVRJTkc7XG5cbiAgICAvLyBBcyB3ZSdyZSByZS1ydW5uaW5nIHRoZSBjb21wdXRhdGlvbiwgdXBkYXRlIG91ciBkZXBlbmRlbnQgdHJhY2tpbmcgdmVyc2lvbiBudW1iZXIuXG4gICAgdGhpcy50cmFja2luZ1ZlcnNpb24rKztcbiAgICBjb25zdCBwcmV2Q29uc3VtZXIgPSBzZXRBY3RpdmVDb25zdW1lcih0aGlzKTtcbiAgICBsZXQgbmV3VmFsdWU6IFQ7XG4gICAgdHJ5IHtcbiAgICAgIG5ld1ZhbHVlID0gdGhpcy5jb21wdXRhdGlvbigpO1xuICAgIH0gY2F0Y2ggKGVycikge1xuICAgICAgbmV3VmFsdWUgPSBFUlJPUkVEO1xuICAgICAgdGhpcy5lcnJvciA9IGVycjtcbiAgICB9IGZpbmFsbHkge1xuICAgICAgc2V0QWN0aXZlQ29uc3VtZXIocHJldkNvbnN1bWVyKTtcbiAgICB9XG5cbiAgICB0aGlzLnN0YWxlID0gZmFsc2U7XG5cbiAgICBpZiAob2xkVmFsdWUgIT09IFVOU0VUICYmIG9sZFZhbHVlICE9PSBFUlJPUkVEICYmIG5ld1ZhbHVlICE9PSBFUlJPUkVEICYmXG4gICAgICAgIHRoaXMuZXF1YWwob2xkVmFsdWUsIG5ld1ZhbHVlKSkge1xuICAgICAgLy8gTm8gY2hhbmdlIHRvIGB2YWx1ZVZlcnNpb25gIC0gb2xkIGFuZCBuZXcgdmFsdWVzIGFyZVxuICAgICAgLy8gc2VtYW50aWNhbGx5IGVxdWl2YWxlbnQuXG4gICAgICB0aGlzLnZhbHVlID0gb2xkVmFsdWU7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgdGhpcy52YWx1ZSA9IG5ld1ZhbHVlO1xuICAgIHRoaXMudmFsdWVWZXJzaW9uKys7XG4gIH1cblxuICBzaWduYWwoKTogVCB7XG4gICAgLy8gQ2hlY2sgaWYgdGhlIHZhbHVlIG5lZWRzIHVwZGF0aW5nIGJlZm9yZSByZXR1cm5pbmcgaXQuXG4gICAgdGhpcy5vblByb2R1Y2VyVXBkYXRlVmFsdWVWZXJzaW9uKCk7XG5cbiAgICAvLyBSZWNvcmQgdGhhdCBzb21lb25lIGxvb2tlZCBhdCB0aGlzIHNpZ25hbC5cbiAgICB0aGlzLnByb2R1Y2VyQWNjZXNzZWQoKTtcblxuICAgIGlmICh0aGlzLnZhbHVlID09PSBFUlJPUkVEKSB7XG4gICAgICB0aHJvdyB0aGlzLmVycm9yO1xuICAgIH1cblxuICAgIHJldHVybiB0aGlzLnZhbHVlO1xuICB9XG59XG4iXX0=