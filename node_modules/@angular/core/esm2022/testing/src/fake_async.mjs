/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
const _Zone = typeof Zone !== 'undefined' ? Zone : null;
const fakeAsyncTestModule = _Zone && _Zone[_Zone.__symbol__('fakeAsyncTest')];
const fakeAsyncTestModuleNotLoadedErrorMessage = `zone-testing.js is needed for the fakeAsync() test helper but could not be found.
        Please make sure that your environment includes zone.js/testing`;
/**
 * Clears out the shared fake async zone for a test.
 * To be called in a global `beforeEach`.
 *
 * @publicApi
 */
export function resetFakeAsyncZone() {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.resetFakeAsyncZone();
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
/**
 * Wraps a function to be executed in the `fakeAsync` zone:
 * - Microtasks are manually executed by calling `flushMicrotasks()`.
 * - Timers are synchronous; `tick()` simulates the asynchronous passage of time.
 *
 * If there are any pending timers at the end of the function, an exception is thrown.
 *
 * Can be used to wrap `inject()` calls.
 *
 * @param fn The function that you want to wrap in the `fakeAsync` zone.
 *
 * @usageNotes
 * ### Example
 *
 * {@example core/testing/ts/fake_async.ts region='basic'}
 *
 *
 * @returns The function wrapped to be executed in the `fakeAsync` zone.
 * Any arguments passed when calling this returned function will be passed through to the `fn`
 * function in the parameters when it is called.
 *
 * @publicApi
 */
export function fakeAsync(fn) {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.fakeAsync(fn);
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
/**
 * Simulates the asynchronous passage of time for the timers in the `fakeAsync` zone.
 *
 * The microtasks queue is drained at the very start of this function and after any timer callback
 * has been executed.
 *
 * @param millis The number of milliseconds to advance the virtual timer.
 * @param tickOptions The options to pass to the `tick()` function.
 *
 * @usageNotes
 *
 * The `tick()` option is a flag called `processNewMacroTasksSynchronously`,
 * which determines whether or not to invoke new macroTasks.
 *
 * If you provide a `tickOptions` object, but do not specify a
 * `processNewMacroTasksSynchronously` property (`tick(100, {})`),
 * then `processNewMacroTasksSynchronously` defaults to true.
 *
 * If you omit the `tickOptions` parameter (`tick(100))`), then
 * `tickOptions` defaults to `{processNewMacroTasksSynchronously: true}`.
 *
 * ### Example
 *
 * {@example core/testing/ts/fake_async.ts region='basic'}
 *
 * The following example includes a nested timeout (new macroTask), and
 * the `tickOptions` parameter is allowed to default. In this case,
 * `processNewMacroTasksSynchronously` defaults to true, and the nested
 * function is executed on each tick.
 *
 * ```
 * it ('test with nested setTimeout', fakeAsync(() => {
 *   let nestedTimeoutInvoked = false;
 *   function funcWithNestedTimeout() {
 *     setTimeout(() => {
 *       nestedTimeoutInvoked = true;
 *     });
 *   };
 *   setTimeout(funcWithNestedTimeout);
 *   tick();
 *   expect(nestedTimeoutInvoked).toBe(true);
 * }));
 * ```
 *
 * In the following case, `processNewMacroTasksSynchronously` is explicitly
 * set to false, so the nested timeout function is not invoked.
 *
 * ```
 * it ('test with nested setTimeout', fakeAsync(() => {
 *   let nestedTimeoutInvoked = false;
 *   function funcWithNestedTimeout() {
 *     setTimeout(() => {
 *       nestedTimeoutInvoked = true;
 *     });
 *   };
 *   setTimeout(funcWithNestedTimeout);
 *   tick(0, {processNewMacroTasksSynchronously: false});
 *   expect(nestedTimeoutInvoked).toBe(false);
 * }));
 * ```
 *
 *
 * @publicApi
 */
export function tick(millis = 0, tickOptions = {
    processNewMacroTasksSynchronously: true
}) {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.tick(millis, tickOptions);
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
/**
 * Flushes any pending microtasks and simulates the asynchronous passage of time for the timers in
 * the `fakeAsync` zone by
 * draining the macrotask queue until it is empty.
 *
 * @param maxTurns The maximum number of times the scheduler attempts to clear its queue before
 *     throwing an error.
 * @returns The simulated time elapsed, in milliseconds.
 *
 * @publicApi
 */
export function flush(maxTurns) {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.flush(maxTurns);
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
/**
 * Discard all remaining periodic tasks.
 *
 * @publicApi
 */
export function discardPeriodicTasks() {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.discardPeriodicTasks();
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
/**
 * Flush any pending microtasks.
 *
 * @publicApi
 */
export function flushMicrotasks() {
    if (fakeAsyncTestModule) {
        return fakeAsyncTestModule.flushMicrotasks();
    }
    throw new Error(fakeAsyncTestModuleNotLoadedErrorMessage);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZmFrZV9hc3luYy5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvdGVzdGluZy9zcmMvZmFrZV9hc3luYy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFDSCxNQUFNLEtBQUssR0FBUSxPQUFPLElBQUksS0FBSyxXQUFXLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDO0FBQzdELE1BQU0sbUJBQW1CLEdBQUcsS0FBSyxJQUFJLEtBQUssQ0FBQyxLQUFLLENBQUMsVUFBVSxDQUFDLGVBQWUsQ0FBQyxDQUFDLENBQUM7QUFFOUUsTUFBTSx3Q0FBd0MsR0FDMUM7d0VBQ29FLENBQUM7QUFFekU7Ozs7O0dBS0c7QUFDSCxNQUFNLFVBQVUsa0JBQWtCO0lBQ2hDLElBQUksbUJBQW1CLEVBQUU7UUFDdkIsT0FBTyxtQkFBbUIsQ0FBQyxrQkFBa0IsRUFBRSxDQUFDO0tBQ2pEO0lBQ0QsTUFBTSxJQUFJLEtBQUssQ0FBQyx3Q0FBd0MsQ0FBQyxDQUFDO0FBQzVELENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQXNCRztBQUNILE1BQU0sVUFBVSxTQUFTLENBQUMsRUFBWTtJQUNwQyxJQUFJLG1CQUFtQixFQUFFO1FBQ3ZCLE9BQU8sbUJBQW1CLENBQUMsU0FBUyxDQUFDLEVBQUUsQ0FBQyxDQUFDO0tBQzFDO0lBQ0QsTUFBTSxJQUFJLEtBQUssQ0FBQyx3Q0FBd0MsQ0FBQyxDQUFDO0FBQzVELENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBK0RHO0FBQ0gsTUFBTSxVQUFVLElBQUksQ0FDaEIsU0FBaUIsQ0FBQyxFQUFFLGNBQTREO0lBQzlFLGlDQUFpQyxFQUFFLElBQUk7Q0FDeEM7SUFDSCxJQUFJLG1CQUFtQixFQUFFO1FBQ3ZCLE9BQU8sbUJBQW1CLENBQUMsSUFBSSxDQUFDLE1BQU0sRUFBRSxXQUFXLENBQUMsQ0FBQztLQUN0RDtJQUNELE1BQU0sSUFBSSxLQUFLLENBQUMsd0NBQXdDLENBQUMsQ0FBQztBQUM1RCxDQUFDO0FBRUQ7Ozs7Ozs7Ozs7R0FVRztBQUNILE1BQU0sVUFBVSxLQUFLLENBQUMsUUFBaUI7SUFDckMsSUFBSSxtQkFBbUIsRUFBRTtRQUN2QixPQUFPLG1CQUFtQixDQUFDLEtBQUssQ0FBQyxRQUFRLENBQUMsQ0FBQztLQUM1QztJQUNELE1BQU0sSUFBSSxLQUFLLENBQUMsd0NBQXdDLENBQUMsQ0FBQztBQUM1RCxDQUFDO0FBRUQ7Ozs7R0FJRztBQUNILE1BQU0sVUFBVSxvQkFBb0I7SUFDbEMsSUFBSSxtQkFBbUIsRUFBRTtRQUN2QixPQUFPLG1CQUFtQixDQUFDLG9CQUFvQixFQUFFLENBQUM7S0FDbkQ7SUFDRCxNQUFNLElBQUksS0FBSyxDQUFDLHdDQUF3QyxDQUFDLENBQUM7QUFDNUQsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsZUFBZTtJQUM3QixJQUFJLG1CQUFtQixFQUFFO1FBQ3ZCLE9BQU8sbUJBQW1CLENBQUMsZUFBZSxFQUFFLENBQUM7S0FDOUM7SUFDRCxNQUFNLElBQUksS0FBSyxDQUFDLHdDQUF3QyxDQUFDLENBQUM7QUFDNUQsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuY29uc3QgX1pvbmU6IGFueSA9IHR5cGVvZiBab25lICE9PSAndW5kZWZpbmVkJyA/IFpvbmUgOiBudWxsO1xuY29uc3QgZmFrZUFzeW5jVGVzdE1vZHVsZSA9IF9ab25lICYmIF9ab25lW19ab25lLl9fc3ltYm9sX18oJ2Zha2VBc3luY1Rlc3QnKV07XG5cbmNvbnN0IGZha2VBc3luY1Rlc3RNb2R1bGVOb3RMb2FkZWRFcnJvck1lc3NhZ2UgPVxuICAgIGB6b25lLXRlc3RpbmcuanMgaXMgbmVlZGVkIGZvciB0aGUgZmFrZUFzeW5jKCkgdGVzdCBoZWxwZXIgYnV0IGNvdWxkIG5vdCBiZSBmb3VuZC5cbiAgICAgICAgUGxlYXNlIG1ha2Ugc3VyZSB0aGF0IHlvdXIgZW52aXJvbm1lbnQgaW5jbHVkZXMgem9uZS5qcy90ZXN0aW5nYDtcblxuLyoqXG4gKiBDbGVhcnMgb3V0IHRoZSBzaGFyZWQgZmFrZSBhc3luYyB6b25lIGZvciBhIHRlc3QuXG4gKiBUbyBiZSBjYWxsZWQgaW4gYSBnbG9iYWwgYGJlZm9yZUVhY2hgLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlc2V0RmFrZUFzeW5jWm9uZSgpOiB2b2lkIHtcbiAgaWYgKGZha2VBc3luY1Rlc3RNb2R1bGUpIHtcbiAgICByZXR1cm4gZmFrZUFzeW5jVGVzdE1vZHVsZS5yZXNldEZha2VBc3luY1pvbmUoKTtcbiAgfVxuICB0aHJvdyBuZXcgRXJyb3IoZmFrZUFzeW5jVGVzdE1vZHVsZU5vdExvYWRlZEVycm9yTWVzc2FnZSk7XG59XG5cbi8qKlxuICogV3JhcHMgYSBmdW5jdGlvbiB0byBiZSBleGVjdXRlZCBpbiB0aGUgYGZha2VBc3luY2Agem9uZTpcbiAqIC0gTWljcm90YXNrcyBhcmUgbWFudWFsbHkgZXhlY3V0ZWQgYnkgY2FsbGluZyBgZmx1c2hNaWNyb3Rhc2tzKClgLlxuICogLSBUaW1lcnMgYXJlIHN5bmNocm9ub3VzOyBgdGljaygpYCBzaW11bGF0ZXMgdGhlIGFzeW5jaHJvbm91cyBwYXNzYWdlIG9mIHRpbWUuXG4gKlxuICogSWYgdGhlcmUgYXJlIGFueSBwZW5kaW5nIHRpbWVycyBhdCB0aGUgZW5kIG9mIHRoZSBmdW5jdGlvbiwgYW4gZXhjZXB0aW9uIGlzIHRocm93bi5cbiAqXG4gKiBDYW4gYmUgdXNlZCB0byB3cmFwIGBpbmplY3QoKWAgY2FsbHMuXG4gKlxuICogQHBhcmFtIGZuIFRoZSBmdW5jdGlvbiB0aGF0IHlvdSB3YW50IHRvIHdyYXAgaW4gdGhlIGBmYWtlQXN5bmNgIHpvbmUuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqICMjIyBFeGFtcGxlXG4gKlxuICoge0BleGFtcGxlIGNvcmUvdGVzdGluZy90cy9mYWtlX2FzeW5jLnRzIHJlZ2lvbj0nYmFzaWMnfVxuICpcbiAqXG4gKiBAcmV0dXJucyBUaGUgZnVuY3Rpb24gd3JhcHBlZCB0byBiZSBleGVjdXRlZCBpbiB0aGUgYGZha2VBc3luY2Agem9uZS5cbiAqIEFueSBhcmd1bWVudHMgcGFzc2VkIHdoZW4gY2FsbGluZyB0aGlzIHJldHVybmVkIGZ1bmN0aW9uIHdpbGwgYmUgcGFzc2VkIHRocm91Z2ggdG8gdGhlIGBmbmBcbiAqIGZ1bmN0aW9uIGluIHRoZSBwYXJhbWV0ZXJzIHdoZW4gaXQgaXMgY2FsbGVkLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGZha2VBc3luYyhmbjogRnVuY3Rpb24pOiAoLi4uYXJnczogYW55W10pID0+IGFueSB7XG4gIGlmIChmYWtlQXN5bmNUZXN0TW9kdWxlKSB7XG4gICAgcmV0dXJuIGZha2VBc3luY1Rlc3RNb2R1bGUuZmFrZUFzeW5jKGZuKTtcbiAgfVxuICB0aHJvdyBuZXcgRXJyb3IoZmFrZUFzeW5jVGVzdE1vZHVsZU5vdExvYWRlZEVycm9yTWVzc2FnZSk7XG59XG5cbi8qKlxuICogU2ltdWxhdGVzIHRoZSBhc3luY2hyb25vdXMgcGFzc2FnZSBvZiB0aW1lIGZvciB0aGUgdGltZXJzIGluIHRoZSBgZmFrZUFzeW5jYCB6b25lLlxuICpcbiAqIFRoZSBtaWNyb3Rhc2tzIHF1ZXVlIGlzIGRyYWluZWQgYXQgdGhlIHZlcnkgc3RhcnQgb2YgdGhpcyBmdW5jdGlvbiBhbmQgYWZ0ZXIgYW55IHRpbWVyIGNhbGxiYWNrXG4gKiBoYXMgYmVlbiBleGVjdXRlZC5cbiAqXG4gKiBAcGFyYW0gbWlsbGlzIFRoZSBudW1iZXIgb2YgbWlsbGlzZWNvbmRzIHRvIGFkdmFuY2UgdGhlIHZpcnR1YWwgdGltZXIuXG4gKiBAcGFyYW0gdGlja09wdGlvbnMgVGhlIG9wdGlvbnMgdG8gcGFzcyB0byB0aGUgYHRpY2soKWAgZnVuY3Rpb24uXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBUaGUgYHRpY2soKWAgb3B0aW9uIGlzIGEgZmxhZyBjYWxsZWQgYHByb2Nlc3NOZXdNYWNyb1Rhc2tzU3luY2hyb25vdXNseWAsXG4gKiB3aGljaCBkZXRlcm1pbmVzIHdoZXRoZXIgb3Igbm90IHRvIGludm9rZSBuZXcgbWFjcm9UYXNrcy5cbiAqXG4gKiBJZiB5b3UgcHJvdmlkZSBhIGB0aWNrT3B0aW9uc2Agb2JqZWN0LCBidXQgZG8gbm90IHNwZWNpZnkgYVxuICogYHByb2Nlc3NOZXdNYWNyb1Rhc2tzU3luY2hyb25vdXNseWAgcHJvcGVydHkgKGB0aWNrKDEwMCwge30pYCksXG4gKiB0aGVuIGBwcm9jZXNzTmV3TWFjcm9UYXNrc1N5bmNocm9ub3VzbHlgIGRlZmF1bHRzIHRvIHRydWUuXG4gKlxuICogSWYgeW91IG9taXQgdGhlIGB0aWNrT3B0aW9uc2AgcGFyYW1ldGVyIChgdGljaygxMDApKWApLCB0aGVuXG4gKiBgdGlja09wdGlvbnNgIGRlZmF1bHRzIHRvIGB7cHJvY2Vzc05ld01hY3JvVGFza3NTeW5jaHJvbm91c2x5OiB0cnVlfWAuXG4gKlxuICogIyMjIEV4YW1wbGVcbiAqXG4gKiB7QGV4YW1wbGUgY29yZS90ZXN0aW5nL3RzL2Zha2VfYXN5bmMudHMgcmVnaW9uPSdiYXNpYyd9XG4gKlxuICogVGhlIGZvbGxvd2luZyBleGFtcGxlIGluY2x1ZGVzIGEgbmVzdGVkIHRpbWVvdXQgKG5ldyBtYWNyb1Rhc2spLCBhbmRcbiAqIHRoZSBgdGlja09wdGlvbnNgIHBhcmFtZXRlciBpcyBhbGxvd2VkIHRvIGRlZmF1bHQuIEluIHRoaXMgY2FzZSxcbiAqIGBwcm9jZXNzTmV3TWFjcm9UYXNrc1N5bmNocm9ub3VzbHlgIGRlZmF1bHRzIHRvIHRydWUsIGFuZCB0aGUgbmVzdGVkXG4gKiBmdW5jdGlvbiBpcyBleGVjdXRlZCBvbiBlYWNoIHRpY2suXG4gKlxuICogYGBgXG4gKiBpdCAoJ3Rlc3Qgd2l0aCBuZXN0ZWQgc2V0VGltZW91dCcsIGZha2VBc3luYygoKSA9PiB7XG4gKiAgIGxldCBuZXN0ZWRUaW1lb3V0SW52b2tlZCA9IGZhbHNlO1xuICogICBmdW5jdGlvbiBmdW5jV2l0aE5lc3RlZFRpbWVvdXQoKSB7XG4gKiAgICAgc2V0VGltZW91dCgoKSA9PiB7XG4gKiAgICAgICBuZXN0ZWRUaW1lb3V0SW52b2tlZCA9IHRydWU7XG4gKiAgICAgfSk7XG4gKiAgIH07XG4gKiAgIHNldFRpbWVvdXQoZnVuY1dpdGhOZXN0ZWRUaW1lb3V0KTtcbiAqICAgdGljaygpO1xuICogICBleHBlY3QobmVzdGVkVGltZW91dEludm9rZWQpLnRvQmUodHJ1ZSk7XG4gKiB9KSk7XG4gKiBgYGBcbiAqXG4gKiBJbiB0aGUgZm9sbG93aW5nIGNhc2UsIGBwcm9jZXNzTmV3TWFjcm9UYXNrc1N5bmNocm9ub3VzbHlgIGlzIGV4cGxpY2l0bHlcbiAqIHNldCB0byBmYWxzZSwgc28gdGhlIG5lc3RlZCB0aW1lb3V0IGZ1bmN0aW9uIGlzIG5vdCBpbnZva2VkLlxuICpcbiAqIGBgYFxuICogaXQgKCd0ZXN0IHdpdGggbmVzdGVkIHNldFRpbWVvdXQnLCBmYWtlQXN5bmMoKCkgPT4ge1xuICogICBsZXQgbmVzdGVkVGltZW91dEludm9rZWQgPSBmYWxzZTtcbiAqICAgZnVuY3Rpb24gZnVuY1dpdGhOZXN0ZWRUaW1lb3V0KCkge1xuICogICAgIHNldFRpbWVvdXQoKCkgPT4ge1xuICogICAgICAgbmVzdGVkVGltZW91dEludm9rZWQgPSB0cnVlO1xuICogICAgIH0pO1xuICogICB9O1xuICogICBzZXRUaW1lb3V0KGZ1bmNXaXRoTmVzdGVkVGltZW91dCk7XG4gKiAgIHRpY2soMCwge3Byb2Nlc3NOZXdNYWNyb1Rhc2tzU3luY2hyb25vdXNseTogZmFsc2V9KTtcbiAqICAgZXhwZWN0KG5lc3RlZFRpbWVvdXRJbnZva2VkKS50b0JlKGZhbHNlKTtcbiAqIH0pKTtcbiAqIGBgYFxuICpcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB0aWNrKFxuICAgIG1pbGxpczogbnVtYmVyID0gMCwgdGlja09wdGlvbnM6IHtwcm9jZXNzTmV3TWFjcm9UYXNrc1N5bmNocm9ub3VzbHk6IGJvb2xlYW59ID0ge1xuICAgICAgcHJvY2Vzc05ld01hY3JvVGFza3NTeW5jaHJvbm91c2x5OiB0cnVlXG4gICAgfSk6IHZvaWQge1xuICBpZiAoZmFrZUFzeW5jVGVzdE1vZHVsZSkge1xuICAgIHJldHVybiBmYWtlQXN5bmNUZXN0TW9kdWxlLnRpY2sobWlsbGlzLCB0aWNrT3B0aW9ucyk7XG4gIH1cbiAgdGhyb3cgbmV3IEVycm9yKGZha2VBc3luY1Rlc3RNb2R1bGVOb3RMb2FkZWRFcnJvck1lc3NhZ2UpO1xufVxuXG4vKipcbiAqIEZsdXNoZXMgYW55IHBlbmRpbmcgbWljcm90YXNrcyBhbmQgc2ltdWxhdGVzIHRoZSBhc3luY2hyb25vdXMgcGFzc2FnZSBvZiB0aW1lIGZvciB0aGUgdGltZXJzIGluXG4gKiB0aGUgYGZha2VBc3luY2Agem9uZSBieVxuICogZHJhaW5pbmcgdGhlIG1hY3JvdGFzayBxdWV1ZSB1bnRpbCBpdCBpcyBlbXB0eS5cbiAqXG4gKiBAcGFyYW0gbWF4VHVybnMgVGhlIG1heGltdW0gbnVtYmVyIG9mIHRpbWVzIHRoZSBzY2hlZHVsZXIgYXR0ZW1wdHMgdG8gY2xlYXIgaXRzIHF1ZXVlIGJlZm9yZVxuICogICAgIHRocm93aW5nIGFuIGVycm9yLlxuICogQHJldHVybnMgVGhlIHNpbXVsYXRlZCB0aW1lIGVsYXBzZWQsIGluIG1pbGxpc2Vjb25kcy5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBmbHVzaChtYXhUdXJucz86IG51bWJlcik6IG51bWJlciB7XG4gIGlmIChmYWtlQXN5bmNUZXN0TW9kdWxlKSB7XG4gICAgcmV0dXJuIGZha2VBc3luY1Rlc3RNb2R1bGUuZmx1c2gobWF4VHVybnMpO1xuICB9XG4gIHRocm93IG5ldyBFcnJvcihmYWtlQXN5bmNUZXN0TW9kdWxlTm90TG9hZGVkRXJyb3JNZXNzYWdlKTtcbn1cblxuLyoqXG4gKiBEaXNjYXJkIGFsbCByZW1haW5pbmcgcGVyaW9kaWMgdGFza3MuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gZGlzY2FyZFBlcmlvZGljVGFza3MoKTogdm9pZCB7XG4gIGlmIChmYWtlQXN5bmNUZXN0TW9kdWxlKSB7XG4gICAgcmV0dXJuIGZha2VBc3luY1Rlc3RNb2R1bGUuZGlzY2FyZFBlcmlvZGljVGFza3MoKTtcbiAgfVxuICB0aHJvdyBuZXcgRXJyb3IoZmFrZUFzeW5jVGVzdE1vZHVsZU5vdExvYWRlZEVycm9yTWVzc2FnZSk7XG59XG5cbi8qKlxuICogRmx1c2ggYW55IHBlbmRpbmcgbWljcm90YXNrcy5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBmbHVzaE1pY3JvdGFza3MoKTogdm9pZCB7XG4gIGlmIChmYWtlQXN5bmNUZXN0TW9kdWxlKSB7XG4gICAgcmV0dXJuIGZha2VBc3luY1Rlc3RNb2R1bGUuZmx1c2hNaWNyb3Rhc2tzKCk7XG4gIH1cbiAgdGhyb3cgbmV3IEVycm9yKGZha2VBc3luY1Rlc3RNb2R1bGVOb3RMb2FkZWRFcnJvck1lc3NhZ2UpO1xufVxuIl19