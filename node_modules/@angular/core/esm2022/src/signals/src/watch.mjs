/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ReactiveNode, setActiveConsumer } from './graph';
const NOOP_CLEANUP_FN = () => { };
/**
 * Watches a reactive expression and allows it to be scheduled to re-run
 * when any dependencies notify of a change.
 *
 * `Watch` doesn't run reactive expressions itself, but relies on a consumer-
 * provided scheduling operation to coordinate calling `Watch.run()`.
 */
export class Watch extends ReactiveNode {
    constructor(watch, schedule, allowSignalWrites) {
        super();
        this.watch = watch;
        this.schedule = schedule;
        this.dirty = false;
        this.cleanupFn = NOOP_CLEANUP_FN;
        this.registerOnCleanup = (cleanupFn) => {
            this.cleanupFn = cleanupFn;
        };
        this.consumerAllowSignalWrites = allowSignalWrites;
    }
    notify() {
        if (!this.dirty) {
            this.schedule(this);
        }
        this.dirty = true;
    }
    onConsumerDependencyMayHaveChanged() {
        this.notify();
    }
    onProducerUpdateValueVersion() {
        // Watches are not producers.
    }
    /**
     * Execute the reactive expression in the context of this `Watch` consumer.
     *
     * Should be called by the user scheduling algorithm when the provided
     * `schedule` hook is called by `Watch`.
     */
    run() {
        this.dirty = false;
        if (this.trackingVersion !== 0 && !this.consumerPollProducersForChange()) {
            return;
        }
        const prevConsumer = setActiveConsumer(this);
        this.trackingVersion++;
        try {
            this.cleanupFn();
            this.cleanupFn = NOOP_CLEANUP_FN;
            this.watch(this.registerOnCleanup);
        }
        finally {
            setActiveConsumer(prevConsumer);
        }
    }
    cleanup() {
        this.cleanupFn();
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoid2F0Y2guanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9zaWduYWxzL3NyYy93YXRjaC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxPQUFPLEVBQUMsWUFBWSxFQUFFLGlCQUFpQixFQUFDLE1BQU0sU0FBUyxDQUFDO0FBYXhELE1BQU0sZUFBZSxHQUFtQixHQUFHLEVBQUUsR0FBRSxDQUFDLENBQUM7QUFFakQ7Ozs7OztHQU1HO0FBQ0gsTUFBTSxPQUFPLEtBQU0sU0FBUSxZQUFZO0lBU3JDLFlBQ1ksS0FBa0QsRUFDbEQsUUFBZ0MsRUFBRSxpQkFBMEI7UUFDdEUsS0FBSyxFQUFFLENBQUM7UUFGRSxVQUFLLEdBQUwsS0FBSyxDQUE2QztRQUNsRCxhQUFRLEdBQVIsUUFBUSxDQUF3QjtRQVRwQyxVQUFLLEdBQUcsS0FBSyxDQUFDO1FBQ2QsY0FBUyxHQUFHLGVBQWUsQ0FBQztRQUM1QixzQkFBaUIsR0FDckIsQ0FBQyxTQUF5QixFQUFFLEVBQUU7WUFDNUIsSUFBSSxDQUFDLFNBQVMsR0FBRyxTQUFTLENBQUM7UUFDN0IsQ0FBQyxDQUFBO1FBTUgsSUFBSSxDQUFDLHlCQUF5QixHQUFHLGlCQUFpQixDQUFDO0lBQ3JELENBQUM7SUFFRCxNQUFNO1FBQ0osSUFBSSxDQUFDLElBQUksQ0FBQyxLQUFLLEVBQUU7WUFDZixJQUFJLENBQUMsUUFBUSxDQUFDLElBQUksQ0FBQyxDQUFDO1NBQ3JCO1FBQ0QsSUFBSSxDQUFDLEtBQUssR0FBRyxJQUFJLENBQUM7SUFDcEIsQ0FBQztJQUVrQixrQ0FBa0M7UUFDbkQsSUFBSSxDQUFDLE1BQU0sRUFBRSxDQUFDO0lBQ2hCLENBQUM7SUFFa0IsNEJBQTRCO1FBQzdDLDZCQUE2QjtJQUMvQixDQUFDO0lBRUQ7Ozs7O09BS0c7SUFDSCxHQUFHO1FBQ0QsSUFBSSxDQUFDLEtBQUssR0FBRyxLQUFLLENBQUM7UUFDbkIsSUFBSSxJQUFJLENBQUMsZUFBZSxLQUFLLENBQUMsSUFBSSxDQUFDLElBQUksQ0FBQyw4QkFBOEIsRUFBRSxFQUFFO1lBQ3hFLE9BQU87U0FDUjtRQUVELE1BQU0sWUFBWSxHQUFHLGlCQUFpQixDQUFDLElBQUksQ0FBQyxDQUFDO1FBQzdDLElBQUksQ0FBQyxlQUFlLEVBQUUsQ0FBQztRQUN2QixJQUFJO1lBQ0YsSUFBSSxDQUFDLFNBQVMsRUFBRSxDQUFDO1lBQ2pCLElBQUksQ0FBQyxTQUFTLEdBQUcsZUFBZSxDQUFDO1lBQ2pDLElBQUksQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLGlCQUFpQixDQUFDLENBQUM7U0FDcEM7Z0JBQVM7WUFDUixpQkFBaUIsQ0FBQyxZQUFZLENBQUMsQ0FBQztTQUNqQztJQUNILENBQUM7SUFFRCxPQUFPO1FBQ0wsSUFBSSxDQUFDLFNBQVMsRUFBRSxDQUFDO0lBQ25CLENBQUM7Q0FDRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge1JlYWN0aXZlTm9kZSwgc2V0QWN0aXZlQ29uc3VtZXJ9IGZyb20gJy4vZ3JhcGgnO1xuXG4vKipcbiAqIEEgY2xlYW51cCBmdW5jdGlvbiB0aGF0IGNhbiBiZSBvcHRpb25hbGx5IHJlZ2lzdGVyZWQgZnJvbSB0aGUgd2F0Y2ggbG9naWMuIElmIHJlZ2lzdGVyZWQsIHRoZVxuICogY2xlYW51cCBsb2dpYyBydW5zIGJlZm9yZSB0aGUgbmV4dCB3YXRjaCBleGVjdXRpb24uXG4gKi9cbmV4cG9ydCB0eXBlIFdhdGNoQ2xlYW51cEZuID0gKCkgPT4gdm9pZDtcblxuLyoqXG4gKiBBIGNhbGxiYWNrIHBhc3NlZCB0byB0aGUgd2F0Y2ggZnVuY3Rpb24gdGhhdCBtYWtlcyBpdCBwb3NzaWJsZSB0byByZWdpc3RlciBjbGVhbnVwIGxvZ2ljLlxuICovXG5leHBvcnQgdHlwZSBXYXRjaENsZWFudXBSZWdpc3RlckZuID0gKGNsZWFudXBGbjogV2F0Y2hDbGVhbnVwRm4pID0+IHZvaWQ7XG5cbmNvbnN0IE5PT1BfQ0xFQU5VUF9GTjogV2F0Y2hDbGVhbnVwRm4gPSAoKSA9PiB7fTtcblxuLyoqXG4gKiBXYXRjaGVzIGEgcmVhY3RpdmUgZXhwcmVzc2lvbiBhbmQgYWxsb3dzIGl0IHRvIGJlIHNjaGVkdWxlZCB0byByZS1ydW5cbiAqIHdoZW4gYW55IGRlcGVuZGVuY2llcyBub3RpZnkgb2YgYSBjaGFuZ2UuXG4gKlxuICogYFdhdGNoYCBkb2Vzbid0IHJ1biByZWFjdGl2ZSBleHByZXNzaW9ucyBpdHNlbGYsIGJ1dCByZWxpZXMgb24gYSBjb25zdW1lci1cbiAqIHByb3ZpZGVkIHNjaGVkdWxpbmcgb3BlcmF0aW9uIHRvIGNvb3JkaW5hdGUgY2FsbGluZyBgV2F0Y2gucnVuKClgLlxuICovXG5leHBvcnQgY2xhc3MgV2F0Y2ggZXh0ZW5kcyBSZWFjdGl2ZU5vZGUge1xuICBwcm90ZWN0ZWQgb3ZlcnJpZGUgcmVhZG9ubHkgY29uc3VtZXJBbGxvd1NpZ25hbFdyaXRlczogYm9vbGVhbjtcbiAgcHJpdmF0ZSBkaXJ0eSA9IGZhbHNlO1xuICBwcml2YXRlIGNsZWFudXBGbiA9IE5PT1BfQ0xFQU5VUF9GTjtcbiAgcHJpdmF0ZSByZWdpc3Rlck9uQ2xlYW51cCA9XG4gICAgICAoY2xlYW51cEZuOiBXYXRjaENsZWFudXBGbikgPT4ge1xuICAgICAgICB0aGlzLmNsZWFudXBGbiA9IGNsZWFudXBGbjtcbiAgICAgIH1cblxuICBjb25zdHJ1Y3RvcihcbiAgICAgIHByaXZhdGUgd2F0Y2g6IChvbkNsZWFudXA6IFdhdGNoQ2xlYW51cFJlZ2lzdGVyRm4pID0+IHZvaWQsXG4gICAgICBwcml2YXRlIHNjaGVkdWxlOiAod2F0Y2g6IFdhdGNoKSA9PiB2b2lkLCBhbGxvd1NpZ25hbFdyaXRlczogYm9vbGVhbikge1xuICAgIHN1cGVyKCk7XG4gICAgdGhpcy5jb25zdW1lckFsbG93U2lnbmFsV3JpdGVzID0gYWxsb3dTaWduYWxXcml0ZXM7XG4gIH1cblxuICBub3RpZnkoKTogdm9pZCB7XG4gICAgaWYgKCF0aGlzLmRpcnR5KSB7XG4gICAgICB0aGlzLnNjaGVkdWxlKHRoaXMpO1xuICAgIH1cbiAgICB0aGlzLmRpcnR5ID0gdHJ1ZTtcbiAgfVxuXG4gIHByb3RlY3RlZCBvdmVycmlkZSBvbkNvbnN1bWVyRGVwZW5kZW5jeU1heUhhdmVDaGFuZ2VkKCk6IHZvaWQge1xuICAgIHRoaXMubm90aWZ5KCk7XG4gIH1cblxuICBwcm90ZWN0ZWQgb3ZlcnJpZGUgb25Qcm9kdWNlclVwZGF0ZVZhbHVlVmVyc2lvbigpOiB2b2lkIHtcbiAgICAvLyBXYXRjaGVzIGFyZSBub3QgcHJvZHVjZXJzLlxuICB9XG5cbiAgLyoqXG4gICAqIEV4ZWN1dGUgdGhlIHJlYWN0aXZlIGV4cHJlc3Npb24gaW4gdGhlIGNvbnRleHQgb2YgdGhpcyBgV2F0Y2hgIGNvbnN1bWVyLlxuICAgKlxuICAgKiBTaG91bGQgYmUgY2FsbGVkIGJ5IHRoZSB1c2VyIHNjaGVkdWxpbmcgYWxnb3JpdGhtIHdoZW4gdGhlIHByb3ZpZGVkXG4gICAqIGBzY2hlZHVsZWAgaG9vayBpcyBjYWxsZWQgYnkgYFdhdGNoYC5cbiAgICovXG4gIHJ1bigpOiB2b2lkIHtcbiAgICB0aGlzLmRpcnR5ID0gZmFsc2U7XG4gICAgaWYgKHRoaXMudHJhY2tpbmdWZXJzaW9uICE9PSAwICYmICF0aGlzLmNvbnN1bWVyUG9sbFByb2R1Y2Vyc0ZvckNoYW5nZSgpKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgY29uc3QgcHJldkNvbnN1bWVyID0gc2V0QWN0aXZlQ29uc3VtZXIodGhpcyk7XG4gICAgdGhpcy50cmFja2luZ1ZlcnNpb24rKztcbiAgICB0cnkge1xuICAgICAgdGhpcy5jbGVhbnVwRm4oKTtcbiAgICAgIHRoaXMuY2xlYW51cEZuID0gTk9PUF9DTEVBTlVQX0ZOO1xuICAgICAgdGhpcy53YXRjaCh0aGlzLnJlZ2lzdGVyT25DbGVhbnVwKTtcbiAgICB9IGZpbmFsbHkge1xuICAgICAgc2V0QWN0aXZlQ29uc3VtZXIocHJldkNvbnN1bWVyKTtcbiAgICB9XG4gIH1cblxuICBjbGVhbnVwKCkge1xuICAgIHRoaXMuY2xlYW51cEZuKCk7XG4gIH1cbn1cbiJdfQ==