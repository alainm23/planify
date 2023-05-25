/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
// Required as the signals library is in a separate package, so we need to explicitly ensure the
// global `ngDevMode` type is defined.
import '../../util/ng_dev_mode';
import { newWeakRef } from './weak_ref';
/**
 * Counter tracking the next `ProducerId` or `ConsumerId`.
 */
let _nextReactiveId = 0;
/**
 * Tracks the currently active reactive consumer (or `null` if there is no active
 * consumer).
 */
let activeConsumer = null;
/**
 * Whether the graph is currently propagating change notifications.
 */
let inNotificationPhase = false;
export function setActiveConsumer(consumer) {
    const prev = activeConsumer;
    activeConsumer = consumer;
    return prev;
}
/**
 * A node in the reactive graph.
 *
 * Nodes can be producers of reactive values, consumers of other reactive values, or both.
 *
 * Producers are nodes that produce values, and can be depended upon by consumer nodes.
 *
 * Producers expose a monotonic `valueVersion` counter, and are responsible for incrementing this
 * version when their value semantically changes. Some producers may produce their values lazily and
 * thus at times need to be polled for potential updates to their value (and by extension their
 * `valueVersion`). This is accomplished via the `onProducerUpdateValueVersion` method for
 * implemented by producers, which should perform whatever calculations are necessary to ensure
 * `valueVersion` is up to date.
 *
 * Consumers are nodes that depend on the values of producers and are notified when those values
 * might have changed.
 *
 * Consumers do not wrap the reads they consume themselves, but rather can be set as the active
 * reader via `setActiveConsumer`. Reads of producers that happen while a consumer is active will
 * result in those producers being added as dependencies of that consumer node.
 *
 * The set of dependencies of a consumer is dynamic. Implementers expose a monotonically increasing
 * `trackingVersion` counter, which increments whenever the consumer is about to re-run any reactive
 * reads it needs and establish a new set of dependencies as a result.
 *
 * Producers store the last `trackingVersion` they've seen from `Consumer`s which have read them.
 * This allows a producer to identify whether its record of the dependency is current or stale, by
 * comparing the consumer's `trackingVersion` to the version at which the dependency was
 * last observed.
 */
export class ReactiveNode {
    constructor() {
        this.id = _nextReactiveId++;
        /**
         * A cached weak reference to this node, which will be used in `ReactiveEdge`s.
         */
        this.ref = newWeakRef(this);
        /**
         * Edges to producers on which this node depends (in its consumer capacity).
         */
        this.producers = new Map();
        /**
         * Edges to consumers on which this node depends (in its producer capacity).
         */
        this.consumers = new Map();
        /**
         * Monotonically increasing counter representing a version of this `Consumer`'s
         * dependencies.
         */
        this.trackingVersion = 0;
        /**
         * Monotonically increasing counter which increases when the value of this `Producer`
         * semantically changes.
         */
        this.valueVersion = 0;
    }
    /**
     * Polls dependencies of a consumer to determine if they have actually changed.
     *
     * If this returns `false`, then even though the consumer may have previously been notified of a
     * change, the values of its dependencies have not actually changed and the consumer should not
     * rerun any reactions.
     */
    consumerPollProducersForChange() {
        for (const [producerId, edge] of this.producers) {
            const producer = edge.producerNode.deref();
            if (producer === undefined || edge.atTrackingVersion !== this.trackingVersion) {
                // This dependency edge is stale, so remove it.
                this.producers.delete(producerId);
                producer?.consumers.delete(this.id);
                continue;
            }
            if (producer.producerPollStatus(edge.seenValueVersion)) {
                // One of the dependencies reports a real value change.
                return true;
            }
        }
        // No dependency reported a real value change, so the `Consumer` has also not been
        // impacted.
        return false;
    }
    /**
     * Notify all consumers of this producer that its value may have changed.
     */
    producerMayHaveChanged() {
        // Prevent signal reads when we're updating the graph
        const prev = inNotificationPhase;
        inNotificationPhase = true;
        try {
            for (const [consumerId, edge] of this.consumers) {
                const consumer = edge.consumerNode.deref();
                if (consumer === undefined || consumer.trackingVersion !== edge.atTrackingVersion) {
                    this.consumers.delete(consumerId);
                    consumer?.producers.delete(this.id);
                    continue;
                }
                consumer.onConsumerDependencyMayHaveChanged();
            }
        }
        finally {
            inNotificationPhase = prev;
        }
    }
    /**
     * Mark that this producer node has been accessed in the current reactive context.
     */
    producerAccessed() {
        if (inNotificationPhase) {
            throw new Error(typeof ngDevMode !== 'undefined' && ngDevMode ?
                `Assertion error: signal read during notification phase` :
                '');
        }
        if (activeConsumer === null) {
            return;
        }
        // Either create or update the dependency `Edge` in both directions.
        let edge = activeConsumer.producers.get(this.id);
        if (edge === undefined) {
            edge = {
                consumerNode: activeConsumer.ref,
                producerNode: this.ref,
                seenValueVersion: this.valueVersion,
                atTrackingVersion: activeConsumer.trackingVersion,
            };
            activeConsumer.producers.set(this.id, edge);
            this.consumers.set(activeConsumer.id, edge);
        }
        else {
            edge.seenValueVersion = this.valueVersion;
            edge.atTrackingVersion = activeConsumer.trackingVersion;
        }
    }
    /**
     * Whether this consumer currently has any producers registered.
     */
    get hasProducers() {
        return this.producers.size > 0;
    }
    /**
     * Whether this `ReactiveNode` in its producer capacity is currently allowed to initiate updates,
     * based on the current consumer context.
     */
    get producerUpdatesAllowed() {
        return activeConsumer?.consumerAllowSignalWrites !== false;
    }
    /**
     * Checks if a `Producer` has a current value which is different than the value
     * last seen at a specific version by a `Consumer` which recorded a dependency on
     * this `Producer`.
     */
    producerPollStatus(lastSeenValueVersion) {
        // `producer.valueVersion` may be stale, but a mismatch still means that the value
        // last seen by the `Consumer` is also stale.
        if (this.valueVersion !== lastSeenValueVersion) {
            return true;
        }
        // Trigger the `Producer` to update its `valueVersion` if necessary.
        this.onProducerUpdateValueVersion();
        // At this point, we can trust `producer.valueVersion`.
        return this.valueVersion !== lastSeenValueVersion;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZ3JhcGguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9zaWduYWxzL3NyYy9ncmFwaC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxnR0FBZ0c7QUFDaEcsc0NBQXNDO0FBQ3RDLE9BQU8sd0JBQXdCLENBQUM7QUFHaEMsT0FBTyxFQUFDLFVBQVUsRUFBVSxNQUFNLFlBQVksQ0FBQztBQUUvQzs7R0FFRztBQUNILElBQUksZUFBZSxHQUFXLENBQUMsQ0FBQztBQUVoQzs7O0dBR0c7QUFDSCxJQUFJLGNBQWMsR0FBc0IsSUFBSSxDQUFDO0FBRTdDOztHQUVHO0FBQ0gsSUFBSSxtQkFBbUIsR0FBRyxLQUFLLENBQUM7QUFFaEMsTUFBTSxVQUFVLGlCQUFpQixDQUFDLFFBQTJCO0lBQzNELE1BQU0sSUFBSSxHQUFHLGNBQWMsQ0FBQztJQUM1QixjQUFjLEdBQUcsUUFBUSxDQUFDO0lBQzFCLE9BQU8sSUFBSSxDQUFDO0FBQ2QsQ0FBQztBQTZCRDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7R0E2Qkc7QUFDSCxNQUFNLE9BQWdCLFlBQVk7SUFBbEM7UUFDbUIsT0FBRSxHQUFHLGVBQWUsRUFBRSxDQUFDO1FBRXhDOztXQUVHO1FBQ2MsUUFBRyxHQUFHLFVBQVUsQ0FBQyxJQUFJLENBQUMsQ0FBQztRQUV4Qzs7V0FFRztRQUNjLGNBQVMsR0FBRyxJQUFJLEdBQUcsRUFBd0IsQ0FBQztRQUU3RDs7V0FFRztRQUNjLGNBQVMsR0FBRyxJQUFJLEdBQUcsRUFBd0IsQ0FBQztRQUU3RDs7O1dBR0c7UUFDTyxvQkFBZSxHQUFHLENBQUMsQ0FBQztRQUU5Qjs7O1dBR0c7UUFDTyxpQkFBWSxHQUFHLENBQUMsQ0FBQztJQXdJN0IsQ0FBQztJQXJIQzs7Ozs7O09BTUc7SUFDTyw4QkFBOEI7UUFDdEMsS0FBSyxNQUFNLENBQUMsVUFBVSxFQUFFLElB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SUFBSSxHQUFHLENBQUMsQ0FBQztJQUNqQyxDQUFDO0lBRUQ7OztPQUdHO0lBQ0gsSUFBYyxzQkFBc0I7UUFDbEMsT0FBTyxjQUFjLEVBQUUseUJBQXlCLEtBQUssS0FBSyxDQUFDO0lBQzdELENBQUM7SUFFRDs7OztPQUlHO0lBQ0ssa0JBQWtCLENBQUMsb0JBQTRCO1FBQ3JELGtGQUFrRjtRQUNsRiw2Q0FBNkM7UUFDN0MsSUFBSSxJQUFJLENBQUMsWUFBWSxLQUFLLG9CQUFvQixFQUFFO1lBQzlDLE9BQU8sSUFBSSxDQUFDO1NBQ2I7UUFFRCxvRUFBb0U7UUFDcEUsSUFBSSxDQUFDLDRCQUE0QixFQUFFLENBQUM7UUFFcEMsdURBQXVEO1FBQ3ZELE9BQU8sSUFBSSxDQUFDLFlBQVksS0FBSyxvQkFBb0IsQ0FBQztJQUNwRCxDQUFDO0NBQ0YiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuLy8gUmVxdWlyZWQgYXMgdGhlIHNpZ25hbHMgbGlicmFyeSBpcyBpbiBhIHNlcGFyYXRlIHBhY2thZ2UsIHNvIHdlIG5lZWQgdG8gZXhwbGljaXRseSBlbnN1cmUgdGhlXG4vLyBnbG9iYWwgYG5nRGV2TW9kZWAgdHlwZSBpcyBkZWZpbmVkLlxuaW1wb3J0ICcuLi8uLi91dGlsL25nX2Rldl9tb2RlJztcblxuaW1wb3J0IHt0aHJvd0ludmFsaWRXcml0ZVRvU2lnbmFsRXJyb3J9IGZyb20gJy4vZXJyb3JzJztcbmltcG9ydCB7bmV3V2Vha1JlZiwgV2Vha1JlZn0gZnJvbSAnLi93ZWFrX3JlZic7XG5cbi8qKlxuICogQ291bnRlciB0cmFja2luZyB0aGUgbmV4dCBgUHJvZHVjZXJJZGAgb3IgYENvbnN1bWVySWRgLlxuICovXG5sZXQgX25leHRSZWFjdGl2ZUlkOiBudW1iZXIgPSAwO1xuXG4vKipcbiAqIFRyYWNrcyB0aGUgY3VycmVudGx5IGFjdGl2ZSByZWFjdGl2ZSBjb25zdW1lciAob3IgYG51bGxgIGlmIHRoZXJlIGlzIG5vIGFjdGl2ZVxuICogY29uc3VtZXIpLlxuICovXG5sZXQgYWN0aXZlQ29uc3VtZXI6IFJlYWN0aXZlTm9kZXxudWxsID0gbnVsbDtcblxuLyoqXG4gKiBXaGV0aGVyIHRoZSBncmFwaCBpcyBjdXJyZW50bHkgcHJvcGFnYXRpbmcgY2hhbmdlIG5vdGlmaWNhdGlvbnMuXG4gKi9cbmxldCBpbk5vdGlmaWNhdGlvblBoYXNlID0gZmFsc2U7XG5cbmV4cG9ydCBmdW5jdGlvbiBzZXRBY3RpdmVDb25zdW1lcihjb25zdW1lcjogUmVhY3RpdmVOb2RlfG51bGwpOiBSZWFjdGl2ZU5vZGV8bnVsbCB7XG4gIGNvbnN0IHByZXYgPSBhY3RpdmVDb25zdW1lcjtcbiAgYWN0aXZlQ29uc3VtZXIgPSBjb25zdW1lcjtcbiAgcmV0dXJuIHByZXY7XG59XG5cbi8qKlxuICogQSBiaWRpcmVjdGlvbmFsIGVkZ2UgaW4gdGhlIGRlcGVuZGVuY3kgZ3JhcGggb2YgYFJlYWN0aXZlTm9kZWBzLlxuICovXG5pbnRlcmZhY2UgUmVhY3RpdmVFZGdlIHtcbiAgLyoqXG4gICAqIFdlYWtseSBoZWxkIHJlZmVyZW5jZSB0byB0aGUgY29uc3VtZXIgc2lkZSBvZiB0aGlzIGVkZ2UuXG4gICAqL1xuICByZWFkb25seSBwcm9kdWNlck5vZGU6IFdlYWtSZWY8UmVhY3RpdmVOb2RlPjtcblxuICAvKipcbiAgICogV2Vha2x5IGhlbGQgcmVmZXJlbmNlIHRvIHRoZSBwcm9kdWNlciBzaWRlIG9mIHRoaXMgZWRnZS5cbiAgICovXG4gIHJlYWRvbmx5IGNvbnN1bWVyTm9kZTogV2Vha1JlZjxSZWFjdGl2ZU5vZGU+O1xuICAvKipcbiAgICogYHRyYWNraW5nVmVyc2lvbmAgb2YgdGhlIGNvbnN1bWVyIGF0IHdoaWNoIHRoaXMgZGVwZW5kZW5jeSBlZGdlIHdhcyBsYXN0IG9ic2VydmVkLlxuICAgKlxuICAgKiBJZiB0aGlzIGRvZXNuJ3QgbWF0Y2ggdGhlIGNvbnN1bWVyJ3MgY3VycmVudCBgdHJhY2tpbmdWZXJzaW9uYCwgdGhlbiB0aGlzIGRlcGVuZGVuY3kgcmVjb3JkXG4gICAqIGlzIHN0YWxlLCBhbmQgbmVlZHMgdG8gYmUgY2xlYW5lZCB1cC5cbiAgICovXG4gIGF0VHJhY2tpbmdWZXJzaW9uOiBudW1iZXI7XG5cbiAgLyoqXG4gICAqIGB2YWx1ZVZlcnNpb25gIG9mIHRoZSBwcm9kdWNlciBhdCB0aGUgdGltZSB0aGlzIGRlcGVuZGVuY3kgd2FzIGxhc3QgYWNjZXNzZWQuXG4gICAqL1xuICBzZWVuVmFsdWVWZXJzaW9uOiBudW1iZXI7XG59XG5cbi8qKlxuICogQSBub2RlIGluIHRoZSByZWFjdGl2ZSBncmFwaC5cbiAqXG4gKiBOb2RlcyBjYW4gYmUgcHJvZHVjZXJzIG9mIHJlYWN0aXZlIHZhbHVlcywgY29uc3VtZXJzIG9mIG90aGVyIHJlYWN0aXZlIHZhbHVlcywgb3IgYm90aC5cbiAqXG4gKiBQcm9kdWNlcnMgYXJlIG5vZGVzIHRoYXQgcHJvZHVjZSB2YWx1ZXMsIGFuZCBjYW4gYmUgZGVwZW5kZWQgdXBvbiBieSBjb25zdW1lciBub2Rlcy5cbiAqXG4gKiBQcm9kdWNlcnMgZXhwb3NlIGEgbW9ub3RvbmljIGB2YWx1ZVZlcnNpb25gIGNvdW50ZXIsIGFuZCBhcmUgcmVzcG9uc2libGUgZm9yIGluY3JlbWVudGluZyB0aGlzXG4gKiB2ZXJzaW9uIHdoZW4gdGhlaXIgdmFsdWUgc2VtYW50aWNhbGx5IGNoYW5nZXMuIFNvbWUgcHJvZHVjZXJzIG1heSBwcm9kdWNlIHRoZWlyIHZhbHVlcyBsYXppbHkgYW5kXG4gKiB0aHVzIGF0IHRpbWVzIG5lZWQgdG8gYmUgcG9sbGVkIGZvciBwb3RlbnRpYWwgdXBkYXRlcyB0byB0aGVpciB2YWx1ZSAoYW5kIGJ5IGV4dGVuc2lvbiB0aGVpclxuICogYHZhbHVlVmVyc2lvbmApLiBUaGlzIGlzIGFjY29tcGxpc2hlZCB2aWEgdGhlIGBvblByb2R1Y2VyVXBkYXRlVmFsdWVWZXJzaW9uYCBtZXRob2QgZm9yXG4gKiBpbXBsZW1lbnRlZCBieSBwcm9kdWNlcnMsIHdoaWNoIHNob3VsZCBwZXJmb3JtIHdoYXRldmVyIGNhbGN1bGF0aW9ucyBhcmUgbmVjZXNzYXJ5IHRvIGVuc3VyZVxuICogYHZhbHVlVmVyc2lvbmAgaXMgdXAgdG8gZGF0ZS5cbiAqXG4gKiBDb25zdW1lcnMgYXJlIG5vZGVzIHRoYXQgZGVwZW5kIG9uIHRoZSB2YWx1ZXMgb2YgcHJvZHVjZXJzIGFuZCBhcmUgbm90aWZpZWQgd2hlbiB0aG9zZSB2YWx1ZXNcbiAqIG1pZ2h0IGhhdmUgY2hhbmdlZC5cbiAqXG4gKiBDb25zdW1lcnMgZG8gbm90IHdyYXAgdGhlIHJlYWRzIHRoZXkgY29uc3VtZSB0aGVtc2VsdmVzLCBidXQgcmF0aGVyIGNhbiBiZSBzZXQgYXMgdGhlIGFjdGl2ZVxuICogcmVhZGVyIHZpYSBgc2V0QWN0aXZlQ29uc3VtZXJgLiBSZWFkcyBvZiBwcm9kdWNlcnMgdGhhdCBoYXBwZW4gd2hpbGUgYSBjb25zdW1lciBpcyBhY3RpdmUgd2lsbFxuICogcmVzdWx0IGluIHRob3NlIHByb2R1Y2VycyBiZWluZyBhZGRlZCBhcyBkZXBlbmRlbmNpZXMgb2YgdGhhdCBjb25zdW1lciBub2RlLlxuICpcbiAqIFRoZSBzZXQgb2YgZGVwZW5kZW5jaWVzIG9mIGEgY29uc3VtZXIgaXMgZHluYW1pYy4gSW1wbGVtZW50ZXJzIGV4cG9zZSBhIG1vbm90b25pY2FsbHkgaW5jcmVhc2luZ1xuICogYHRyYWNraW5nVmVyc2lvbmAgY291bnRlciwgd2hpY2ggaW5jcmVtZW50cyB3aGVuZXZlciB0aGUgY29uc3VtZXIgaXMgYWJvdXQgdG8gcmUtcnVuIGFueSByZWFjdGl2ZVxuICogcmVhZHMgaXQgbmVlZHMgYW5kIGVzdGFibGlzaCBhIG5ldyBzZXQgb2YgZGVwZW5kZW5jaWVzIGFzIGEgcmVzdWx0LlxuICpcbiAqIFByb2R1Y2VycyBzdG9yZSB0aGUgbGFzdCBgdHJhY2tpbmdWZXJzaW9uYCB0aGV5J3ZlIHNlZW4gZnJvbSBgQ29uc3VtZXJgcyB3aGljaCBoYXZlIHJlYWQgdGhlbS5cbiAqIFRoaXMgYWxsb3dzIGEgcHJvZHVjZXIgdG8gaWRlbnRpZnkgd2hldGhlciBpdHMgcmVjb3JkIG9mIHRoZSBkZXBlbmRlbmN5IGlzIGN1cnJlbnQgb3Igc3RhbGUsIGJ5XG4gKiBjb21wYXJpbmcgdGhlIGNvbnN1bWVyJ3MgYHRyYWNraW5nVmVyc2lvbmAgdG8gdGhlIHZlcnNpb24gYXQgd2hpY2ggdGhlIGRlcGVuZGVuY3kgd2FzXG4gKiBsYXN0IG9ic2VydmVkLlxuICovXG5leHBvcnQgYWJzdHJhY3QgY2xhc3MgUmVhY3RpdmVOb2RlIHtcbiAgcHJpdmF0ZSByZWFkb25seSBpZCA9IF9uZXh0UmVhY3RpdmVJZCsrO1xuXG4gIC8qKlxuICAgKiBBIGNhY2hlZCB3ZWFrIHJlZmVyZW5jZSB0byB0aGlzIG5vZGUsIHdoaWNoIHdpbGwgYmUgdXNlZCBpbiBgUmVhY3RpdmVFZGdlYHMuXG4gICAqL1xuICBwcml2YXRlIHJlYWRvbmx5IHJlZiA9IG5ld1dlYWtSZWYodGhpcyk7XG5cbiAgLyoqXG4gICAqIEVkZ2VzIHRvIHByb2R1Y2VycyBvbiB3aGljaCB0aGlzIG5vZGUgZGVwZW5kcyAoaW4gaXRzIGNvbnN1bWVyIGNhcGFjaXR5KS5cbiAgICovXG4gIHByaXZhdGUgcmVhZG9ubHkgcHJvZHVjZXJzID0gbmV3IE1hcDxudW1iZXIsIFJlYWN0aXZlRWRnZT4oKTtcblxuICAvKipcbiAgICogRWRnZXMgdG8gY29uc3VtZXJzIG9uIHdoaWNoIHRoaXMgbm9kZSBkZXBlbmRzIChpbiBpdHMgcHJvZHVjZXIgY2FwYWNpdHkpLlxuICAgKi9cbiAgcHJpdmF0ZSByZWFkb25seSBjb25zdW1lcnMgPSBuZXcgTWFwPG51bWJlciwgUmVhY3RpdmVFZGdlPigpO1xuXG4gIC8qKlxuICAgKiBNb25vdG9uaWNhbGx5IGluY3JlYXNpbmcgY291bnRlciByZXByZXNlbnRpbmcgYSB2ZXJzaW9uIG9mIHRoaXMgYENvbnN1bWVyYCdzXG4gICAqIGRlcGVuZGVuY2llcy5cbiAgICovXG4gIHByb3RlY3RlZCB0cmFja2luZ1ZlcnNpb24gPSAwO1xuXG4gIC8qKlxuICAgKiBNb25vdG9uaWNhbGx5IGluY3JlYXNpbmcgY291bnRlciB3aGljaCBpbmNyZWFzZXMgd2hlbiB0aGUgdmFsdWUgb2YgdGhpcyBgUHJvZHVjZXJgXG4gICAqIHNlbWFudGljYWxseSBjaGFuZ2VzLlxuICAgKi9cbiAgcHJvdGVjdGVkIHZhbHVlVmVyc2lvbiA9IDA7XG5cbiAgLyoqXG4gICAqIFdoZXRoZXIgc2lnbmFsIHdyaXRlcyBzaG91bGQgYmUgYWxsb3dlZCB3aGlsZSB0aGlzIGBSZWFjdGl2ZU5vZGVgIGlzIHRoZSBjdXJyZW50IGNvbnN1bWVyLlxuICAgKi9cbiAgcHJvdGVjdGVkIGFic3RyYWN0IHJlYWRvbmx5IGNvbnN1bWVyQWxsb3dTaWduYWxXcml0ZXM6IGJvb2xlYW47XG5cbiAgLyoqXG4gICAqIENhbGxlZCBmb3IgY29uc3VtZXJzIHdoZW5ldmVyIG9uZSBvZiB0aGVpciBkZXBlbmRlbmNpZXMgbm90aWZpZXMgdGhhdCBpdCBtaWdodCBoYXZlIGEgbmV3XG4gICAqIHZhbHVlLlxuICAgKi9cbiAgcHJvdGVjdGVkIGFic3RyYWN0IG9uQ29uc3VtZXJEZXBlbmRlbmN5TWF5SGF2ZUNoYW5nZWQoKTogdm9pZDtcblxuICAvKipcbiAgICogQ2FsbGVkIGZvciBwcm9kdWNlcnMgd2hlbiBhIGRlcGVuZGVudCBjb25zdW1lciBpcyBjaGVja2luZyBpZiB0aGUgcHJvZHVjZXIncyB2YWx1ZSBoYXMgYWN0dWFsbHlcbiAgICogY2hhbmdlZC5cbiAgICovXG4gIHByb3RlY3RlZCBhYnN0cmFjdCBvblByb2R1Y2VyVXBkYXRlVmFsdWVWZXJzaW9uKCk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFBvbGxzIGRlcGVuZGVuY2llcyBvZiBhIGNvbnN1bWVyIHRvIGRldGVybWluZSBpZiB0aGV5IGhhdmUgYWN0dWFsbHkgY2hhbmdlZC5cbiAgICpcbiAgICogSWYgdGhpcyByZXR1cm5zIGBmYWxzZWAsIHRoZW4gZXZlbiB0aG91Z2ggdGhlIGNvbnN1bWVyIG1heSBoYXZlIHByZXZpb3VzbHkgYmVlbiBub3RpZmllZCBvZiBhXG4gICAqIGNoYW5nZSwgdGhlIHZhbHVlcyBvZiBpdHMgZGVwZW5kZW5jaWVzIGhhdmUgbm90IGFjdHVhbGx5IGNoYW5nZWQgYW5kIHRoZSBjb25zdW1lciBzaG91bGQgbm90XG4gICAqIHJlcnVuIGFueSByZWFjdGlvbnMuXG4gICAqL1xuICBwcm90ZWN0ZWQgY29uc3VtZXJQb2xsUHJvZHVjZXJzRm9yQ2hhbmdlKCk6IGJvb2xlYW4ge1xuICAgIGZvciAoY29uc3QgW3Byb2R1Y2VySWQsIGVkZ2VdIG9mIHRoaXMucHJvZHVjZXJzKSB7XG4gICAgICBjb25zdCBwcm9kdWNlciA9IGVkZ2UucHJvZHVjZXJOb2RlLmRlcmVmKCk7XG5cbiAgICAgIGlmIChwcm9kdWNlciA9PT0gdW5kZWZpbmVkIHx8IGVkZ2UuYXRUcmFja2luZ1ZlcnNpb24gIT09IHRoaXMudHJhY2tpbmdWZXJzaW9uKSB7XG4gICAgICAgIC8vIFRoaXMgZGVwZW5kZW5jeSBlZGdlIGlzIHN0YWxlLCBzbyByZW1vdmUgaXQuXG4gICAgICAgIHRoaXMucHJvZHVjZXJzLmRlbGV0ZShwcm9kdWNlcklkKTtcbiAgICAgICAgcHJvZHVjZXI/LmNvbnN1bWVycy5kZWxldGUodGhpcy5pZCk7XG4gICAgICAgIGNvbnRpbnVlO1xuICAgICAgfVxuXG4gICAgICBpZiAocHJvZHVjZXIucHJvZHVjZXJQb2xsU3RhdHVzKGVkZ2Uuc2VlblZhbHVlVmVyc2lvbikpIHtcbiAgICAgICAgLy8gT25lIG9mIHRoZSBkZXBlbmRlbmNpZXMgcmVwb3J0cyBhIHJlYWwgdmFsdWUgY2hhbmdlLlxuICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBObyBkZXBlbmRlbmN5IHJlcG9ydGVkIGEgcmVhbCB2YWx1ZSBjaGFuZ2UsIHNvIHRoZSBgQ29uc3VtZXJgIGhhcyBhbHNvIG5vdCBiZWVuXG4gICAgLy8gaW1wYWN0ZWQuXG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG5cbiAgLyoqXG4gICAqIE5vdGlmeSBhbGwgY29uc3VtZXJzIG9mIHRoaXMgcHJvZHVjZXIgdGhhdCBpdHMgdmFsdWUgbWF5IGhhdmUgY2hhbmdlZC5cbiAgICovXG4gIHByb3RlY3RlZCBwcm9kdWNlck1heUhhdmVDaGFuZ2VkKCk6IHZvaWQge1xuICAgIC8vIFByZXZlbnQgc2lnbmFsIHJlYWRzIHdoZW4gd2UncmUgdXBkYXRpbmcgdGhlIGdyYXBoXG4gICAgY29uc3QgcHJldiA9IGluTm90aWZpY2F0aW9uUGhhc2U7XG4gICAgaW5Ob3RpZmljYXRpb25QaGFzZSA9IHRydWU7XG4gICAgdHJ5IHtcbiAgICAgIGZvciAoY29uc3QgW2NvbnN1bWVySWQsIGVkZ2VdIG9mIHRoaXMuY29uc3VtZXJzKSB7XG4gICAgICAgIGNvbnN0IGNvbnN1bWVyID0gZWRnZS5jb25zdW1lck5vZGUuZGVyZWYoKTtcbiAgICAgICAgaWYgKGNvbnN1bWVyID09PSB1bmRlZmluZWQgfHwgY29uc3VtZXIudHJhY2tpbmdWZXJzaW9uICE9PSBlZGdlLmF0VHJhY2tpbmdWZXJzaW9uKSB7XG4gICAgICAgICAgdGhpcy5jb25zdW1lcnMuZGVsZXRlKGNvbnN1bWVySWQpO1xuICAgICAgICAgIGNvbnN1bWVyPy5wcm9kdWNlcnMuZGVsZXRlKHRoaXMuaWQpO1xuICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICB9XG5cbiAgICAgICAgY29uc3VtZXIub25Db25zdW1lckRlcGVuZGVuY3lNYXlIYXZlQ2hhbmdlZCgpO1xuICAgICAgfVxuICAgIH0gZmluYWxseSB7XG4gICAgICBpbk5vdGlmaWNhdGlvblBoYXNlID0gcHJldjtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogTWFyayB0aGF0IHRoaXMgcHJvZHVjZXIgbm9kZSBoYXMgYmVlbiBhY2Nlc3NlZCBpbiB0aGUgY3VycmVudCByZWFjdGl2ZSBjb250ZXh0LlxuICAgKi9cbiAgcHJvdGVjdGVkIHByb2R1Y2VyQWNjZXNzZWQoKTogdm9pZCB7XG4gICAgaWYgKGluTm90aWZpY2F0aW9uUGhhc2UpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihcbiAgICAgICAgICB0eXBlb2YgbmdEZXZNb2RlICE9PSAndW5kZWZpbmVkJyAmJiBuZ0Rldk1vZGUgP1xuICAgICAgICAgICAgICBgQXNzZXJ0aW9uIGVycm9yOiBzaWduYWwgcmVhZCBkdXJpbmcgbm90aWZpY2F0aW9uIHBoYXNlYCA6XG4gICAgICAgICAgICAgICcnKTtcbiAgICB9XG5cbiAgICBpZiAoYWN0aXZlQ29uc3VtZXIgPT09IG51bGwpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyBFaXRoZXIgY3JlYXRlIG9yIHVwZGF0ZSB0aGUgZGVwZW5kZW5jeSBgRWRnZWAgaW4gYm90aCBkaXJlY3Rpb25zLlxuICAgIGxldCBlZGdlID0gYWN0aXZlQ29uc3VtZXIucHJvZHVjZXJzLmdldCh0aGlzLmlkKTtcbiAgICBpZiAoZWRnZSA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICBlZGdlID0ge1xuICAgICAgICBjb25zdW1lck5vZGU6IGFjdGl2ZUNvbnN1bWVyLnJlZixcbiAgICAgICAgcHJvZHVjZXJOb2RlOiB0aGlzLnJlZixcbiAgICAgICAgc2VlblZhbHVlVmVyc2lvbjogdGhpcy52YWx1ZVZlcnNpb24sXG4gICAgICAgIGF0VHJhY2tpbmdWZXJzaW9uOiBhY3RpdmVDb25zdW1lci50cmFja2luZ1ZlcnNpb24sXG4gICAgICB9O1xuICAgICAgYWN0aXZlQ29uc3VtZXIucHJvZHVjZXJzLnNldCh0aGlzLmlkLCBlZGdlKTtcbiAgICAgIHRoaXMuY29uc3VtZXJzLnNldChhY3RpdmVDb25zdW1lci5pZCwgZWRnZSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGVkZ2Uuc2VlblZhbHVlVmVyc2lvbiA9IHRoaXMudmFsdWVWZXJzaW9uO1xuICAgICAgZWRnZS5hdFRyYWNraW5nVmVyc2lvbiA9IGFjdGl2ZUNvbnN1bWVyLnRyYWNraW5nVmVyc2lvbjtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogV2hldGhlciB0aGlzIGNvbnN1bWVyIGN1cnJlbnRseSBoYXMgYW55IHByb2R1Y2VycyByZWdpc3RlcmVkLlxuICAgKi9cbiAgcHJvdGVjdGVkIGdldCBoYXNQcm9kdWNlcnMoKTogYm9vbGVhbiB7XG4gICAgcmV0dXJuIHRoaXMucHJvZHVjZXJzLnNpemUgPiAwO1xuICB9XG5cbiAgLyoqXG4gICAqIFdoZXRoZXIgdGhpcyBgUmVhY3RpdmVOb2RlYCBpbiBpdHMgcHJvZHVjZXIgY2FwYWNpdHkgaXMgY3VycmVudGx5IGFsbG93ZWQgdG8gaW5pdGlhdGUgdXBkYXRlcyxcbiAgICogYmFzZWQgb24gdGhlIGN1cnJlbnQgY29uc3VtZXIgY29udGV4dC5cbiAgICovXG4gIHByb3RlY3RlZCBnZXQgcHJvZHVjZXJVcGRhdGVzQWxsb3dlZCgpOiBib29sZWFuIHtcbiAgICByZXR1cm4gYWN0aXZlQ29uc3VtZXI/LmNvbnN1bWVyQWxsb3dTaWduYWxXcml0ZXMgIT09IGZhbHNlO1xuICB9XG5cbiAgLyoqXG4gICAqIENoZWNrcyBpZiBhIGBQcm9kdWNlcmAgaGFzIGEgY3VycmVudCB2YWx1ZSB3aGljaCBpcyBkaWZmZXJlbnQgdGhhbiB0aGUgdmFsdWVcbiAgICogbGFzdCBzZWVuIGF0IGEgc3BlY2lmaWMgdmVyc2lvbiBieSBhIGBDb25zdW1lcmAgd2hpY2ggcmVjb3JkZWQgYSBkZXBlbmRlbmN5IG9uXG4gICAqIHRoaXMgYFByb2R1Y2VyYC5cbiAgICovXG4gIHByaXZhdGUgcHJvZHVjZXJQb2xsU3RhdHVzKGxhc3RTZWVuVmFsdWVWZXJzaW9uOiBudW1iZXIpOiBib29sZWFuIHtcbiAgICAvLyBgcHJvZHVjZXIudmFsdWVWZXJzaW9uYCBtYXkgYmUgc3RhbGUsIGJ1dCBhIG1pc21hdGNoIHN0aWxsIG1lYW5zIHRoYXQgdGhlIHZhbHVlXG4gICAgLy8gbGFzdCBzZWVuIGJ5IHRoZSBgQ29uc3VtZXJgIGlzIGFsc28gc3RhbGUuXG4gICAgaWYgKHRoaXMudmFsdWVWZXJzaW9uICE9PSBsYXN0U2VlblZhbHVlVmVyc2lvbikge1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuXG4gICAgLy8gVHJpZ2dlciB0aGUgYFByb2R1Y2VyYCB0byB1cGRhdGUgaXRzIGB2YWx1ZVZlcnNpb25gIGlmIG5lY2Vzc2FyeS5cbiAgICB0aGlzLm9uUHJvZHVjZXJVcGRhdGVWYWx1ZVZlcnNpb24oKTtcblxuICAgIC8vIEF0IHRoaXMgcG9pbnQsIHdlIGNhbiB0cnVzdCBgcHJvZHVjZXIudmFsdWVWZXJzaW9uYC5cbiAgICByZXR1cm4gdGhpcy52YWx1ZVZlcnNpb24gIT09IGxhc3RTZWVuVmFsdWVWZXJzaW9uO1xuICB9XG59XG4iXX0=