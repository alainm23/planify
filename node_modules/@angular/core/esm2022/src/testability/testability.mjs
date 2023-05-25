/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { Inject, Injectable, InjectionToken } from '../di';
import { scheduleMicroTask } from '../util/microtask';
import { NgZone } from '../zone/ng_zone';
import * as i0 from "../r3_symbols";
import * as i1 from "../zone/ng_zone";
/**
 * Internal injection token that can used to access an instance of a Testability class.
 *
 * This token acts as a bridge between the core bootstrap code and the `Testability` class. This is
 * needed to ensure that there are no direct references to the `Testability` class, so it can be
 * tree-shaken away (if not referenced). For the environments/setups when the `Testability` class
 * should be available, this token is used to add a provider that references the `Testability`
 * class. Otherwise, only this token is retained in a bundle, but the `Testability` class is not.
 */
export const TESTABILITY = new InjectionToken('');
/**
 * Internal injection token to retrieve Testability getter class instance.
 */
export const TESTABILITY_GETTER = new InjectionToken('');
/**
 * The Testability service provides testing hooks that can be accessed from
 * the browser.
 *
 * Angular applications bootstrapped using an NgModule (via `@NgModule.bootstrap` field) will also
 * instantiate Testability by default (in both development and production modes).
 *
 * For applications bootstrapped using the `bootstrapApplication` function, Testability is not
 * included by default. You can include it into your applications by getting the list of necessary
 * providers using the `provideProtractorTestingSupport()` function and adding them into the
 * `options.providers` array. Example:
 *
 * ```typescript
 * import {provideProtractorTestingSupport} from '@angular/platform-browser';
 *
 * await bootstrapApplication(RootComponent, providers: [provideProtractorTestingSupport()]);
 * ```
 *
 * @publicApi
 */
class Testability {
    constructor(_ngZone, registry, testabilityGetter) {
        this._ngZone = _ngZone;
        this.registry = registry;
        this._pendingCount = 0;
        this._isZoneStable = true;
        /**
         * Whether any work was done since the last 'whenStable' callback. This is
         * useful to detect if this could have potentially destabilized another
         * component while it is stabilizing.
         * @internal
         */
        this._didWork = false;
        this._callbacks = [];
        this.taskTrackingZone = null;
        // If there was no Testability logic registered in the global scope
        // before, register the current testability getter as a global one.
        if (!_testabilityGetter) {
            setTestabilityGetter(testabilityGetter);
            testabilityGetter.addToWindow(registry);
        }
        this._watchAngularEvents();
        _ngZone.run(() => {
            this.taskTrackingZone =
                typeof Zone == 'undefined' ? null : Zone.current.get('TaskTrackingZone');
        });
    }
    _watchAngularEvents() {
        this._ngZone.onUnstable.subscribe({
            next: () => {
                this._didWork = true;
                this._isZoneStable = false;
            }
        });
        this._ngZone.runOutsideAngular(() => {
            this._ngZone.onStable.subscribe({
                next: () => {
                    NgZone.assertNotInAngularZone();
                    scheduleMicroTask(() => {
                        this._isZoneStable = true;
                        this._runCallbacksIfReady();
                    });
                }
            });
        });
    }
    /**
     * Increases the number of pending request
     * @deprecated pending requests are now tracked with zones.
     */
    increasePendingRequestCount() {
        this._pendingCount += 1;
        this._didWork = true;
        return this._pendingCount;
    }
    /**
     * Decreases the number of pending request
     * @deprecated pending requests are now tracked with zones
     */
    decreasePendingRequestCount() {
        this._pendingCount -= 1;
        if (this._pendingCount < 0) {
            throw new Error('pending async requests below zero');
        }
        this._runCallbacksIfReady();
        return this._pendingCount;
    }
    /**
     * Whether an associated application is stable
     */
    isStable() {
        return this._isZoneStable && this._pendingCount === 0 && !this._ngZone.hasPendingMacrotasks;
    }
    _runCallbacksIfReady() {
        if (this.isStable()) {
            // Schedules the call backs in a new frame so that it is always async.
            scheduleMicroTask(() => {
                while (this._callbacks.length !== 0) {
                    let cb = this._callbacks.pop();
                    clearTimeout(cb.timeoutId);
                    cb.doneCb(this._didWork);
                }
                this._didWork = false;
            });
        }
        else {
            // Still not stable, send updates.
            let pending = this.getPendingTasks();
            this._callbacks = this._callbacks.filter((cb) => {
                if (cb.updateCb && cb.updateCb(pending)) {
                    clearTimeout(cb.timeoutId);
                    return false;
                }
                return true;
            });
            this._didWork = true;
        }
    }
    getPendingTasks() {
        if (!this.taskTrackingZone) {
            return [];
        }
        // Copy the tasks data so that we don't leak tasks.
        return this.taskTrackingZone.macroTasks.map((t) => {
            return {
                source: t.source,
                // From TaskTrackingZone:
                // https://github.com/angular/zone.js/blob/master/lib/zone-spec/task-tracking.ts#L40
                creationLocation: t.creationLocation,
                data: t.data
            };
        });
    }
    addCallback(cb, timeout, updateCb) {
        let timeoutId = -1;
        if (timeout && timeout > 0) {
            timeoutId = setTimeout(() => {
                this._callbacks = this._callbacks.filter((cb) => cb.timeoutId !== timeoutId);
                cb(this._didWork, this.getPendingTasks());
            }, timeout);
        }
        this._callbacks.push({ doneCb: cb, timeoutId: timeoutId, updateCb: updateCb });
    }
    /**
     * Wait for the application to be stable with a timeout. If the timeout is reached before that
     * happens, the callback receives a list of the macro tasks that were pending, otherwise null.
     *
     * @param doneCb The callback to invoke when Angular is stable or the timeout expires
     *    whichever comes first.
     * @param timeout Optional. The maximum time to wait for Angular to become stable. If not
     *    specified, whenStable() will wait forever.
     * @param updateCb Optional. If specified, this callback will be invoked whenever the set of
     *    pending macrotasks changes. If this callback returns true doneCb will not be invoked
     *    and no further updates will be issued.
     */
    whenStable(doneCb, timeout, updateCb) {
        if (updateCb && !this.taskTrackingZone) {
            throw new Error('Task tracking zone is required when passing an update callback to ' +
                'whenStable(). Is "zone.js/plugins/task-tracking" loaded?');
        }
        // These arguments are 'Function' above to keep the public API simple.
        this.addCallback(doneCb, timeout, updateCb);
        this._runCallbacksIfReady();
    }
    /**
     * Get the number of pending requests
     * @deprecated pending requests are now tracked with zones
     */
    getPendingRequestCount() {
        return this._pendingCount;
    }
    /**
     * Registers an application with a testability hook so that it can be tracked.
     * @param token token of application, root element
     *
     * @internal
     */
    registerApplication(token) {
        this.registry.registerApplication(token, this);
    }
    /**
     * Unregisters an application.
     * @param token token of application, root element
     *
     * @internal
     */
    unregisterApplication(token) {
        this.registry.unregisterApplication(token);
    }
    /**
     * Find providers by name
     * @param using The root element to search from
     * @param provider The name of binding variable
     * @param exactMatch Whether using exactMatch
     */
    findProviders(using, provider, exactMatch) {
        // TODO(juliemr): implement.
        return [];
    }
    static { this.ɵfac = function Testability_Factory(t) { return new (t || Testability)(i0.ɵɵinject(i1.NgZone), i0.ɵɵinject(TestabilityRegistry), i0.ɵɵinject(TESTABILITY_GETTER)); }; }
    static { this.ɵprov = /*@__PURE__*/ i0.ɵɵdefineInjectable({ token: Testability, factory: Testability.ɵfac }); }
}
export { Testability };
(function () { (typeof ngDevMode === "undefined" || ngDevMode) && i0.setClassMetadata(Testability, [{
        type: Injectable
    }], function () { return [{ type: i1.NgZone }, { type: TestabilityRegistry }, { type: undefined, decorators: [{
                type: Inject,
                args: [TESTABILITY_GETTER]
            }] }]; }, null); })();
/**
 * A global registry of {@link Testability} instances for specific elements.
 * @publicApi
 */
class TestabilityRegistry {
    constructor() {
        /** @internal */
        this._applications = new Map();
    }
    /**
     * Registers an application with a testability hook so that it can be tracked
     * @param token token of application, root element
     * @param testability Testability hook
     */
    registerApplication(token, testability) {
        this._applications.set(token, testability);
    }
    /**
     * Unregisters an application.
     * @param token token of application, root element
     */
    unregisterApplication(token) {
        this._applications.delete(token);
    }
    /**
     * Unregisters all applications
     */
    unregisterAllApplications() {
        this._applications.clear();
    }
    /**
     * Get a testability hook associated with the application
     * @param elem root element
     */
    getTestability(elem) {
        return this._applications.get(elem) || null;
    }
    /**
     * Get all registered testabilities
     */
    getAllTestabilities() {
        return Array.from(this._applications.values());
    }
    /**
     * Get all registered applications(root elements)
     */
    getAllRootElements() {
        return Array.from(this._applications.keys());
    }
    /**
     * Find testability of a node in the Tree
     * @param elem node
     * @param findInAncestors whether finding testability in ancestors if testability was not found in
     * current node
     */
    findTestabilityInTree(elem, findInAncestors = true) {
        return _testabilityGetter?.findTestabilityInTree(this, elem, findInAncestors) ?? null;
    }
    static { this.ɵfac = function TestabilityRegistry_Factory(t) { return new (t || TestabilityRegistry)(); }; }
    static { this.ɵprov = /*@__PURE__*/ i0.ɵɵdefineInjectable({ token: TestabilityRegistry, factory: TestabilityRegistry.ɵfac, providedIn: 'platform' }); }
}
export { TestabilityRegistry };
(function () { (typeof ngDevMode === "undefined" || ngDevMode) && i0.setClassMetadata(TestabilityRegistry, [{
        type: Injectable,
        args: [{ providedIn: 'platform' }]
    }], null, null); })();
/**
 * Set the {@link GetTestability} implementation used by the Angular testing framework.
 * @publicApi
 */
export function setTestabilityGetter(getter) {
    _testabilityGetter = getter;
}
let _testabilityGetter;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidGVzdGFiaWxpdHkuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy90ZXN0YWJpbGl0eS90ZXN0YWJpbGl0eS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxPQUFPLEVBQUMsTUFBTSxFQUFFLFVBQVUsRUFBRSxjQUFjLEVBQUMsTUFBTSxPQUFPLENBQUM7QUFDekQsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDcEQsT0FBTyxFQUFDLE1BQU0sRUFBQyxNQUFNLGlCQUFpQixDQUFDOzs7QUF3Q3ZDOzs7Ozs7OztHQVFHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sV0FBVyxHQUFHLElBQUksY0FBYyxDQUFjLEVBQUUsQ0FBQyxDQUFDO0FBRS9EOztHQUVHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sa0JBQWtCLEdBQUcsSUFBSSxjQUFjLENBQWlCLEVBQUUsQ0FBQyxDQUFDO0FBRXpFOzs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBbUJHO0FBQ0gsTUFDYSxXQUFXO0lBY3RCLFlBQ1ksT0FBZSxFQUFVLFFBQTZCLEVBQ2xDLGlCQUFpQztRQURyRCxZQUFPLEdBQVAsT0FBTyxDQUFRO1FBQVUsYUFBUSxHQUFSLFFBQVEsQ0FBcUI7UUFkMUQsa0JBQWEsR0FBVyxDQUFDLENBQUM7UUFDMUIsa0JBQWEsR0FBWSxJQUFJLENBQUM7UUFDdEM7Ozs7O1dBS0c7UUFDSyxhQUFRLEdBQVksS0FBSyxDQUFDO1FBQzFCLGVBQVUsR0FBbUIsRUFBRSxDQUFDO1FBRWhDLHFCQUFnQixHQUE4QixJQUFJLENBQUM7UUFLekQsbUVBQW1FO1FBQ25FLG1FQUFtRTtRQUNuRSxJQUFJLENBQUMsa0JBQWtCLEVBQUU7WUFDdkIsb0JBQW9CLENBQUMsaUJBQWlCLENBQUMsQ0FBQztZQUN4QyxpQkFBaUIsQ0FBQyxXQUFXLENBQUMsUUFBUSxDQUFDLENBQUM7U0FDekM7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bUI7Y0FEL0IsVUFBVTtlQUFDLEVBQUMsVUFBVSxFQUFFLFVBQVUsRUFBQzs7QUEwRXBDOzs7R0FHRztBQUNILE1BQU0sVUFBVSxvQkFBb0IsQ0FBQyxNQUFzQjtJQUN6RCxrQkFBa0IsR0FBRyxNQUFNLENBQUM7QUFDOUIsQ0FBQztBQUVELElBQUksa0JBQTRDLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtJbmplY3QsIEluamVjdGFibGUsIEluamVjdGlvblRva2VufSBmcm9tICcuLi9kaSc7XG5pbXBvcnQge3NjaGVkdWxlTWljcm9UYXNrfSBmcm9tICcuLi91dGlsL21pY3JvdGFzayc7XG5pbXBvcnQge05nWm9uZX0gZnJvbSAnLi4vem9uZS9uZ196b25lJztcblxuLyoqXG4gKiBUZXN0YWJpbGl0eSBBUEkuXG4gKiBgZGVjbGFyZWAga2V5d29yZCBjYXVzZXMgdHNpY2tsZSB0byBnZW5lcmF0ZSBleHRlcm5zLCBzbyB0aGVzZSBtZXRob2RzIGFyZVxuICogbm90IHJlbmFtZWQgYnkgQ2xvc3VyZSBDb21waWxlci5cbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGRlY2xhcmUgaW50ZXJmYWNlIFB1YmxpY1Rlc3RhYmlsaXR5IHtcbiAgaXNTdGFibGUoKTogYm9vbGVhbjtcbiAgd2hlblN0YWJsZShjYWxsYmFjazogRnVuY3Rpb24sIHRpbWVvdXQ/OiBudW1iZXIsIHVwZGF0ZUNhbGxiYWNrPzogRnVuY3Rpb24pOiB2b2lkO1xuICBmaW5kUHJvdmlkZXJzKHVzaW5nOiBhbnksIHByb3ZpZGVyOiBzdHJpbmcsIGV4YWN0TWF0Y2g6IGJvb2xlYW4pOiBhbnlbXTtcbn1cblxuLy8gQW5ndWxhciBpbnRlcm5hbCwgbm90IGludGVuZGVkIGZvciBwdWJsaWMgQVBJLlxuZXhwb3J0IGludGVyZmFjZSBQZW5kaW5nTWFjcm90YXNrIHtcbiAgc291cmNlOiBzdHJpbmc7XG4gIGNyZWF0aW9uTG9jYXRpb246IEVycm9yO1xuICBydW5Db3VudD86IG51bWJlcjtcbiAgZGF0YT86IFRhc2tEYXRhO1xufVxuXG5leHBvcnQgaW50ZXJmYWNlIFRhc2tEYXRhIHtcbiAgdGFyZ2V0PzogWE1MSHR0cFJlcXVlc3Q7XG4gIGRlbGF5PzogbnVtYmVyO1xuICBpc1BlcmlvZGljPzogYm9vbGVhbjtcbn1cblxuLy8gQW5ndWxhciBpbnRlcm5hbCwgbm90IGludGVuZGVkIGZvciBwdWJsaWMgQVBJLlxuZXhwb3J0IHR5cGUgRG9uZUNhbGxiYWNrID0gKGRpZFdvcms6IGJvb2xlYW4sIHRhc2tzPzogUGVuZGluZ01hY3JvdGFza1tdKSA9PiB2b2lkO1xuZXhwb3J0IHR5cGUgVXBkYXRlQ2FsbGJhY2sgPSAodGFza3M6IFBlbmRpbmdNYWNyb3Rhc2tbXSkgPT4gYm9vbGVhbjtcblxuaW50ZXJmYWNlIFdhaXRDYWxsYmFjayB7XG4gIC8vIE5lZWRzIHRvIGJlICdhbnknIC0gc2V0VGltZW91dCByZXR1cm5zIGEgbnVtYmVyIGFjY29yZGluZyB0byBFUzYsIGJ1dFxuICAvLyBvbiBOb2RlSlMgaXQgcmV0dXJucyBhIFRpbWVyLlxuICB0aW1lb3V0SWQ6IGFueTtcbiAgZG9uZUNiOiBEb25lQ2FsbGJhY2s7XG4gIHVwZGF0ZUNiPzogVXBkYXRlQ2FsbGJhY2s7XG59XG5cbi8qKlxuICogSW50ZXJuYWwgaW5qZWN0aW9uIHRva2VuIHRoYXQgY2FuIHVzZWQgdG8gYWNjZXNzIGFuIGluc3RhbmNlIG9mIGEgVGVzdGFiaWxpdHkgY2xhc3MuXG4gKlxuICogVGhpcyB0b2tlbiBhY3RzIGFzIGEgYnJpZGdlIGJldHdlZW4gdGhlIGNvcmUgYm9vdHN0cmFwIGNvZGUgYW5kIHRoZSBgVGVzdGFiaWxpdHlgIGNsYXNzLiBUaGlzIGlzXG4gKiBuZWVkZWQgdG8gZW5zdXJlIHRoYXQgdGhlcmUgYXJlIG5vIGRpcmVjdCByZWZlcmVuY2VzIHRvIHRoZSBgVGVzdGFiaWxpdHlgIGNsYXNzLCBzbyBpdCBjYW4gYmVcbiAqIHRyZWUtc2hha2VuIGF3YXkgKGlmIG5vdCByZWZlcmVuY2VkKS4gRm9yIHRoZSBlbnZpcm9ubWVudHMvc2V0dXBzIHdoZW4gdGhlIGBUZXN0YWJpbGl0eWAgY2xhc3NcbiAqIHNob3VsZCBiZSBhdmFpbGFibGUsIHRoaXMgdG9rZW4gaXMgdXNlZCB0byBhZGQgYSBwcm92aWRlciB0aGF0IHJlZmVyZW5jZXMgdGhlIGBUZXN0YWJpbGl0eWBcbiAqIGNsYXNzLiBPdGhlcndpc2UsIG9ubHkgdGhpcyB0b2tlbiBpcyByZXRhaW5lZCBpbiBhIGJ1bmRsZSwgYnV0IHRoZSBgVGVzdGFiaWxpdHlgIGNsYXNzIGlzIG5vdC5cbiAqL1xuZXhwb3J0IGNvbnN0IFRFU1RBQklMSVRZID0gbmV3IEluamVjdGlvblRva2VuPFRlc3RhYmlsaXR5PignJyk7XG5cbi8qKlxuICogSW50ZXJuYWwgaW5qZWN0aW9uIHRva2VuIHRvIHJldHJpZXZlIFRlc3RhYmlsaXR5IGdldHRlciBjbGFzcyBpbnN0YW5jZS5cbiAqL1xuZXhwb3J0IGNvbnN0IFRFU1RBQklMSVRZX0dFVFRFUiA9IG5ldyBJbmplY3Rpb25Ub2tlbjxHZXRUZXN0YWJpbGl0eT4oJycpO1xuXG4vKipcbiAqIFRoZSBUZXN0YWJpbGl0eSBzZXJ2aWNlIHByb3ZpZGVzIHRlc3RpbmcgaG9va3MgdGhhdCBjYW4gYmUgYWNjZXNzZWQgZnJvbVxuICogdGhlIGJyb3dzZXIuXG4gKlxuICogQW5ndWxhciBhcHBsaWNhdGlvbnMgYm9vdHN0cmFwcGVkIHVzaW5nIGFuIE5nTW9kdWxlICh2aWEgYEBOZ01vZHVsZS5ib290c3RyYXBgIGZpZWxkKSB3aWxsIGFsc29cbiAqIGluc3RhbnRpYXRlIFRlc3RhYmlsaXR5IGJ5IGRlZmF1bHQgKGluIGJvdGggZGV2ZWxvcG1lbnQgYW5kIHByb2R1Y3Rpb24gbW9kZXMpLlxuICpcbiAqIEZvciBhcHBsaWNhdGlvbnMgYm9vdHN0cmFwcGVkIHVzaW5nIHRoZSBgYm9vdHN0cmFwQXBwbGljYXRpb25gIGZ1bmN0aW9uLCBUZXN0YWJpbGl0eSBpcyBub3RcbiAqIGluY2x1ZGVkIGJ5IGRlZmF1bHQuIFlvdSBjYW4gaW5jbHVkZSBpdCBpbnRvIHlvdXIgYXBwbGljYXRpb25zIGJ5IGdldHRpbmcgdGhlIGxpc3Qgb2YgbmVjZXNzYXJ5XG4gKiBwcm92aWRlcnMgdXNpbmcgdGhlIGBwcm92aWRlUHJvdHJhY3RvclRlc3RpbmdTdXBwb3J0KClgIGZ1bmN0aW9uIGFuZCBhZGRpbmcgdGhlbSBpbnRvIHRoZVxuICogYG9wdGlvbnMucHJvdmlkZXJzYCBhcnJheS4gRXhhbXBsZTpcbiAqXG4gKiBgYGB0eXBlc2NyaXB0XG4gKiBpbXBvcnQge3Byb3ZpZGVQcm90cmFjdG9yVGVzdGluZ1N1cHBvcnR9IGZyb20gJ0Bhbmd1bGFyL3BsYXRmb3JtLWJyb3dzZXInO1xuICpcbiAqIGF3YWl0IGJvb3RzdHJhcEFwcGxpY2F0aW9uKFJvb3RDb21wb25lbnQsIHByb3ZpZGVyczogW3Byb3ZpZGVQcm90cmFjdG9yVGVzdGluZ1N1cHBvcnQoKV0pO1xuICogYGBgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5ASW5qZWN0YWJsZSgpXG5leHBvcnQgY2xhc3MgVGVzdGFiaWxpdHkgaW1wbGVtZW50cyBQdWJsaWNUZXN0YWJpbGl0eSB7XG4gIHByaXZhdGUgX3BlbmRpbmdDb3VudDogbnVtYmVyID0gMDtcbiAgcHJpdmF0ZSBfaXNab25lU3RhYmxlOiBib29sZWFuID0gdHJ1ZTtcbiAgLyoqXG4gICAqIFdoZXRoZXIgYW55IHdvcmsgd2FzIGRvbmUgc2luY2UgdGhlIGxhc3QgJ3doZW5TdGFibGUnIGNhbGxiYWNrLiBUaGlzIGlzXG4gICAqIHVzZWZ1bCB0byBkZXRlY3QgaWYgdGhpcyBjb3VsZCBoYXZlIHBvdGVudGlhbGx5IGRlc3RhYmlsaXplZCBhbm90aGVyXG4gICAqIGNvbXBvbmVudCB3aGlsZSBpdCBpcyBzdGFiaWxpemluZy5cbiAgICogQGludGVybmFsXG4gICAqL1xuICBwcml2YXRlIF9kaWRXb3JrOiBib29sZWFuID0gZmFsc2U7XG4gIHByaXZhdGUgX2NhbGxiYWNrczogV2FpdENhbGxiYWNrW10gPSBbXTtcblxuICBwcml2YXRlIHRhc2tUcmFja2luZ1pvbmU6IHttYWNyb1Rhc2tzOiBUYXNrW119fG51bGwgPSBudWxsO1xuXG4gIGNvbnN0cnVjdG9yKFxuICAgICAgcHJpdmF0ZSBfbmdab25lOiBOZ1pvbmUsIHByaXZhdGUgcmVnaXN0cnk6IFRlc3RhYmlsaXR5UmVnaXN0cnksXG4gICAgICBASW5qZWN0KFRFU1RBQklMSVRZX0dFVFRFUikgdGVzdGFiaWxpdHlHZXR0ZXI6IEdldFRlc3RhYmlsaXR5KSB7XG4gICAgLy8gSWYgdGhlcmUgd2FzIG5vIFRlc3RhYmlsaXR5IGxvZ2ljIHJlZ2lzdGVyZWQgaW4gdGhlIGdsb2JhbCBzY29wZVxuICAgIC8vIGJlZm9yZSwgcmVnaXN0ZXIgdGhlIGN1cnJlbnQgdGVzdGFiaWxpdHkgZ2V0dGVyIGFzIGEgZ2xvYmFsIG9uZS5cbiAgICBpZiAoIV90ZXN0YWJpbGl0eUdldHRlcikge1xuICAgICAgc2V0VGVzdGFiaWxpdHlHZXR0ZXIodGVzdGFiaWxpdHlHZXR0ZXIpO1xuICAgICAgdGVzdGFiaWxpdHlHZXR0ZXIuYWRkVG9XaW5kb3cocmVnaXN0cnkpO1xuICAgIH1cbiAgICB0aGlzLl93YXRjaEFuZ3VsYXJFdmVudHMoKTtcbiAgICBfbmdab25lLnJ1bigoKSA9PiB7XG4gICAgICB0aGlzLnRhc2tUcmFja2luZ1pvbmUgPVxuICAgICAgICAgIHR5cGVvZiBab25lID09ICd1bmRlZmluZWQnID8gbnVsbCA6IFpvbmUuY3VycmVudC5nZXQoJ1Rhc2tUcmFja2luZ1pvbmUnKTtcbiAgICB9KTtcbiAgfVxuXG4gIHByaXZhdGUgX3dhdGNoQW5ndWxhckV2ZW50cygpOiB2b2lkIHtcbiAgICB0aGlzLl9uZ1pvbmUub25VbnN0YWJsZS5zdWJzY3JpYmUoe1xuICAgICAgbmV4dDogKCkgPT4ge1xuICAgICAgICB0aGlzLl9kaWRXb3JrID0gdHJ1ZTtcbiAgICAgICAgdGhpcy5faXNab25lU3RhYmxlID0gZmFsc2U7XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICB0aGlzLl9uZ1pvbmUucnVuT3V0c2lkZUFuZ3VsYXIoKCkgPT4ge1xuICAgICAgdGhpcy5fbmdab25lLm9uU3RhYmxlLnN1YnNjcmliZSh7XG4gICAgICAgIG5leHQ6ICgpID0+IHtcbiAgICAgICAgICBOZ1pvbmUuYXNzZXJ0Tm90SW5Bbmd1bGFyWm9uZSgpO1xuICAgICAgICAgIHNjaGVkdWxlTWljcm9UYXNrKCgpID0+IHtcbiAgICAgICAgICAgIHRoaXMuX2lzWm9uZVN0YWJsZSA9IHRydWU7XG4gICAgICAgICAgICB0aGlzLl9ydW5DYWxsYmFja3NJZlJlYWR5KCk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgLyoqXG4gICAqIEluY3JlYXNlcyB0aGUgbnVtYmVyIG9mIHBlbmRpbmcgcmVxdWVzdFxuICAgKiBAZGVwcmVjYXRlZCBwZW5kaW5nIHJlcXVlc3RzIGFyZSBub3cgdHJhY2tlZCB3aXRoIHpvbmVzLlxuICAgKi9cbiAgaW5jcmVhc2VQZW5kaW5nUmVxdWVzdENvdW50KCk6IG51bWJlciB7XG4gICAgdGhpcy5fcGVuZGluZ0NvdW50ICs9IDE7XG4gICAgdGhpcy5fZGlkV29yayA9IHRydWU7XG4gICAgcmV0dXJuIHRoaXMuX3BlbmRpbmdDb3VudDtcbiAgfVxuXG4gIC8qKlxuICAgKiBEZWNyZWFzZXMgdGhlIG51bWJlciBvZiBwZW5kaW5nIHJlcXVlc3RcbiAgICogQGRlcHJlY2F0ZWQgcGVuZGluZyByZXF1ZXN0cyBhcmUgbm93IHRyYWNrZWQgd2l0aCB6b25lc1xuICAgKi9cbiAgZGVjcmVhc2VQZW5kaW5nUmVxdWVzdENvdW50KCk6IG51bWJlciB7XG4gICAgdGhpcy5fcGVuZGluZ0NvdW50IC09IDE7XG4gICAgaWYgKHRoaXMuX3BlbmRpbmdDb3VudCA8IDApIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcigncGVuZGluZyBhc3luYyByZXF1ZXN0cyBiZWxvdyB6ZXJvJyk7XG4gICAgfVxuICAgIHRoaXMuX3J1bkNhbGxiYWNrc0lmUmVhZHkoKTtcbiAgICByZXR1cm4gdGhpcy5fcGVuZGluZ0NvdW50O1xuICB9XG5cbiAgLyoqXG4gICAqIFdoZXRoZXIgYW4gYXNzb2NpYXRlZCBhcHBsaWNhdGlvbiBpcyBzdGFibGVcbiAgICovXG4gIGlzU3RhYmxlKCk6IGJvb2xlYW4ge1xuICAgIHJldHVybiB0aGlzLl9pc1pvbmVTdGFibGUgJiYgdGhpcy5fcGVuZGluZ0NvdW50ID09PSAwICYmICF0aGlzLl9uZ1pvbmUuaGFzUGVuZGluZ01hY3JvdGFza3M7XG4gIH1cblxuICBwcml2YXRlIF9ydW5DYWxsYmFja3NJZlJlYWR5KCk6IHZvaWQge1xuICAgIGlmICh0aGlzLmlzU3RhYmxlKCkpIHtcbiAgICAgIC8vIFNjaGVkdWxlcyB0aGUgY2FsbCBiYWNrcyBpbiBhIG5ldyBmcmFtZSBzbyB0aGF0IGl0IGlzIGFsd2F5cyBhc3luYy5cbiAgICAgIHNjaGVkdWxlTWljcm9UYXNrKCgpID0+IHtcbiAgICAgICAgd2hpbGUgKHRoaXMuX2NhbGxiYWNrcy5sZW5ndGggIT09IDApIHtcbiAgICAgICAgICBsZXQgY2IgPSB0aGlzLl9jYWxsYmFja3MucG9wKCkhO1xuICAgICAgICAgIGNsZWFyVGltZW91dChjYi50aW1lb3V0SWQpO1xuICAgICAgICAgIGNiLmRvbmVDYih0aGlzLl9kaWRXb3JrKTtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLl9kaWRXb3JrID0gZmFsc2U7XG4gICAgICB9KTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gU3RpbGwgbm90IHN0YWJsZSwgc2VuZCB1cGRhdGVzLlxuICAgICAgbGV0IHBlbmRpbmcgPSB0aGlzLmdldFBlbmRpbmdUYXNrcygpO1xuICAgICAgdGhpcy5fY2FsbGJhY2tzID0gdGhpcy5fY2FsbGJhY2tzLmZpbHRlcigoY2IpID0+IHtcbiAgICAgICAgaWYgKGNiLnVwZGF0ZUNiICYmIGNiLnVwZGF0ZUNiKHBlbmRpbmcpKSB7XG4gICAgICAgICAgY2xlYXJUaW1lb3V0KGNiLnRpbWVvdXRJZCk7XG4gICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICB9KTtcblxuICAgICAgdGhpcy5fZGlkV29yayA9IHRydWU7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBnZXRQZW5kaW5nVGFza3MoKTogUGVuZGluZ01hY3JvdGFza1tdIHtcbiAgICBpZiAoIXRoaXMudGFza1RyYWNraW5nWm9uZSkge1xuICAgICAgcmV0dXJuIFtdO1xuICAgIH1cblxuICAgIC8vIENvcHkgdGhlIHRhc2tzIGRhdGEgc28gdGhhdCB3ZSBkb24ndCBsZWFrIHRhc2tzLlxuICAgIHJldHVybiB0aGlzLnRhc2tUcmFja2luZ1pvbmUubWFjcm9UYXNrcy5tYXAoKHQ6IFRhc2spID0+IHtcbiAgICAgIHJldHVybiB7XG4gICAgICAgIHNvdXJjZTogdC5zb3VyY2UsXG4gICAgICAgIC8vIEZyb20gVGFza1RyYWNraW5nWm9uZTpcbiAgICAgICAgLy8gaHR0cHM6Ly9naXRodWIuY29tL2FuZ3VsYXIvem9uZS5qcy9ibG9iL21hc3Rlci9saWIvem9uZS1zcGVjL3Rhc2stdHJhY2tpbmcudHMjTDQwXG4gICAgICAgIGNyZWF0aW9uTG9jYXRpb246ICh0IGFzIGFueSkuY3JlYXRpb25Mb2NhdGlvbiBhcyBFcnJvcixcbiAgICAgICAgZGF0YTogdC5kYXRhXG4gICAgICB9O1xuICAgIH0pO1xuICB9XG5cbiAgcHJpdmF0ZSBhZGRDYWxsYmFjayhjYjogRG9uZUNhbGxiYWNrLCB0aW1lb3V0PzogbnVtYmVyLCB1cGRhdGVDYj86IFVwZGF0ZUNhbGxiYWNrKSB7XG4gICAgbGV0IHRpbWVvdXRJZDogYW55ID0gLTE7XG4gICAgaWYgKHRpbWVvdXQgJiYgdGltZW91dCA+IDApIHtcbiAgICAgIHRpbWVvdXRJZCA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgICB0aGlzLl9jYWxsYmFja3MgPSB0aGlzLl9jYWxsYmFja3MuZmlsdGVyKChjYikgPT4gY2IudGltZW91dElkICE9PSB0aW1lb3V0SWQpO1xuICAgICAgICBjYih0aGlzLl9kaWRXb3JrLCB0aGlzLmdldFBlbmRpbmdUYXNrcygpKTtcbiAgICAgIH0sIHRpbWVvdXQpO1xuICAgIH1cbiAgICB0aGlzLl9jYWxsYmFja3MucHVzaCg8V2FpdENhbGxiYWNrPntkb25lQ2I6IGNiLCB0aW1lb3V0SWQ6IHRpbWVvdXRJZCwgdXBkYXRlQ2I6IHVwZGF0ZUNifSk7XG4gIH1cblxuICAvKipcbiAgICogV2FpdCBmb3IgdGhlIGFwcGxpY2F0aW9uIHRvIGJlIHN0YWJsZSB3aXRoIGEgdGltZW91dC4gSWYgdGhlIHRpbWVvdXQgaXMgcmVhY2hlZCBiZWZvcmUgdGhhdFxuICAgKiBoYXBwZW5zLCB0aGUgY2FsbGJhY2sgcmVjZWl2ZXMgYSBsaXN0IG9mIHRoZSBtYWNybyB0YXNrcyB0aGF0IHdlcmUgcGVuZGluZywgb3RoZXJ3aXNlIG51bGwuXG4gICAqXG4gICAqIEBwYXJhbSBkb25lQ2IgVGhlIGNhbGxiYWNrIHRvIGludm9rZSB3aGVuIEFuZ3VsYXIgaXMgc3RhYmxlIG9yIHRoZSB0aW1lb3V0IGV4cGlyZXNcbiAgICogICAgd2hpY2hldmVyIGNvbWVzIGZpcnN0LlxuICAgKiBAcGFyYW0gdGltZW91dCBPcHRpb25hbC4gVGhlIG1heGltdW0gdGltZSB0byB3YWl0IGZvciBBbmd1bGFyIHRvIGJlY29tZSBzdGFibGUuIElmIG5vdFxuICAgKiAgICBzcGVjaWZpZWQsIHdoZW5TdGFibGUoKSB3aWxsIHdhaXQgZm9yZXZlci5cbiAgICogQHBhcmFtIHVwZGF0ZUNiIE9wdGlvbmFsLiBJZiBzcGVjaWZpZWQsIHRoaXMgY2FsbGJhY2sgd2lsbCBiZSBpbnZva2VkIHdoZW5ldmVyIHRoZSBzZXQgb2ZcbiAgICogICAgcGVuZGluZyBtYWNyb3Rhc2tzIGNoYW5nZXMuIElmIHRoaXMgY2FsbGJhY2sgcmV0dXJucyB0cnVlIGRvbmVDYiB3aWxsIG5vdCBiZSBpbnZva2VkXG4gICAqICAgIGFuZCBubyBmdXJ0aGVyIHVwZGF0ZXMgd2lsbCBiZSBpc3N1ZWQuXG4gICAqL1xuICB3aGVuU3RhYmxlKGRvbmVDYjogRnVuY3Rpb24sIHRpbWVvdXQ/OiBudW1iZXIsIHVwZGF0ZUNiPzogRnVuY3Rpb24pOiB2b2lkIHtcbiAgICBpZiAodXBkYXRlQ2IgJiYgIXRoaXMudGFza1RyYWNraW5nWm9uZSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFxuICAgICAgICAgICdUYXNrIHRyYWNraW5nIHpvbmUgaXMgcmVxdWlyZWQgd2hlbiBwYXNzaW5nIGFuIHVwZGF0ZSBjYWxsYmFjayB0byAnICtcbiAgICAgICAgICAnd2hlblN0YWJsZSgpLiBJcyBcInpvbmUuanMvcGx1Z2lucy90YXNrLXRyYWNraW5nXCIgbG9hZGVkPycpO1xuICAgIH1cbiAgICAvLyBUaGVzZSBhcmd1bWVudHMgYXJlICdGdW5jdGlvbicgYWJvdmUgdG8ga2VlcCB0aGUgcHVibGljIEFQSSBzaW1wbGUuXG4gICAgdGhpcy5hZGRDYWxsYmFjayhkb25lQ2IgYXMgRG9uZUNhbGxiYWNrLCB0aW1lb3V0LCB1cGRhdGVDYiBhcyBVcGRhdGVDYWxsYmFjayk7XG4gICAgdGhpcy5fcnVuQ2FsbGJhY2tzSWZSZWFkeSgpO1xuICB9XG5cbiAgLyoqXG4gICAqIEdldCB0aGUgbnVtYmVyIG9mIHBlbmRpbmcgcmVxdWVzdHNcbiAgICogQGRlcHJlY2F0ZWQgcGVuZGluZyByZXF1ZXN0cyBhcmUgbm93IHRyYWNrZWQgd2l0aCB6b25lc1xuICAgKi9cbiAgZ2V0UGVuZGluZ1JlcXVlc3RDb3VudCgpOiBudW1iZXIge1xuICAgIHJldHVybiB0aGlzLl9wZW5kaW5nQ291bnQ7XG4gIH1cbiAgLyoqXG4gICAqIFJlZ2lzdGVycyBhbiBhcHBsaWNhdGlvbiB3aXRoIGEgdGVzdGFiaWxpdHkgaG9vayBzbyB0aGF0IGl0IGNhbiBiZSB0cmFja2VkLlxuICAgKiBAcGFyYW0gdG9rZW4gdG9rZW4gb2YgYXBwbGljYXRpb24sIHJvb3QgZWxlbWVudFxuICAgKlxuICAgKiBAaW50ZXJuYWxcbiAgICovXG4gIHJlZ2lzdGVyQXBwbGljYXRpb24odG9rZW46IGFueSkge1xuICAgIHRoaXMucmVnaXN0cnkucmVnaXN0ZXJBcHBsaWNhdGlvbih0b2tlbiwgdGhpcyk7XG4gIH1cblxuICAvKipcbiAgICogVW5yZWdpc3RlcnMgYW4gYXBwbGljYXRpb24uXG4gICAqIEBwYXJhbSB0b2tlbiB0b2tlbiBvZiBhcHBsaWNhdGlvbiwgcm9vdCBlbGVtZW50XG4gICAqXG4gICAqIEBpbnRlcm5hbFxuICAgKi9cbiAgdW5yZWdpc3RlckFwcGxpY2F0aW9uKHRva2VuOiBhbnkpIHtcbiAgICB0aGlzLnJlZ2lzdHJ5LnVucmVnaXN0ZXJBcHBsaWNhdGlvbih0b2tlbik7XG4gIH1cblxuICAvKipcbiAgICogRmluZCBwcm92aWRlcnMgYnkgbmFtZVxuICAgKiBAcGFyYW0gdXNpbmcgVGhlIHJvb3QgZWxlbWVudCB0byBzZWFyY2ggZnJvbVxuICAgKiBAcGFyYW0gcHJvdmlkZXIgVGhlIG5hbWUgb2YgYmluZGluZyB2YXJpYWJsZVxuICAgKiBAcGFyYW0gZXhhY3RNYXRjaCBXaGV0aGVyIHVzaW5nIGV4YWN0TWF0Y2hcbiAgICovXG4gIGZpbmRQcm92aWRlcnModXNpbmc6IGFueSwgcHJvdmlkZXI6IHN0cmluZywgZXhhY3RNYXRjaDogYm9vbGVhbik6IGFueVtdIHtcbiAgICAvLyBUT0RPKGp1bGllbXIpOiBpbXBsZW1lbnQuXG4gICAgcmV0dXJuIFtdO1xuICB9XG59XG5cbi8qKlxuICogQSBnbG9iYWwgcmVnaXN0cnkgb2Yge0BsaW5rIFRlc3RhYmlsaXR5fSBpbnN0YW5jZXMgZm9yIHNwZWNpZmljIGVsZW1lbnRzLlxuICogQHB1YmxpY0FwaVxuICovXG5ASW5qZWN0YWJsZSh7cHJvdmlkZWRJbjogJ3BsYXRmb3JtJ30pXG5leHBvcnQgY2xhc3MgVGVzdGFiaWxpdHlSZWdpc3RyeSB7XG4gIC8qKiBAaW50ZXJuYWwgKi9cbiAgX2FwcGxpY2F0aW9ucyA9IG5ldyBNYXA8YW55LCBUZXN0YWJpbGl0eT4oKTtcblxuICAvKipcbiAgICogUmVnaXN0ZXJzIGFuIGFwcGxpY2F0aW9uIHdpdGggYSB0ZXN0YWJpbGl0eSBob29rIHNvIHRoYXQgaXQgY2FuIGJlIHRyYWNrZWRcbiAgICogQHBhcmFtIHRva2VuIHRva2VuIG9mIGFwcGxpY2F0aW9uLCByb290IGVsZW1lbnRcbiAgICogQHBhcmFtIHRlc3RhYmlsaXR5IFRlc3RhYmlsaXR5IGhvb2tcbiAgICovXG4gIHJlZ2lzdGVyQXBwbGljYXRpb24odG9rZW46IGFueSwgdGVzdGFiaWxpdHk6IFRlc3RhYmlsaXR5KSB7XG4gICAgdGhpcy5fYXBwbGljYXRpb25zLnNldCh0b2tlbiwgdGVzdGFiaWxpdHkpO1xuICB9XG5cbiAgLyoqXG4gICAqIFVucmVnaXN0ZXJzIGFuIGFwcGxpY2F0aW9uLlxuICAgKiBAcGFyYW0gdG9rZW4gdG9rZW4gb2YgYXBwbGljYXRpb24sIHJvb3QgZWxlbWVudFxuICAgKi9cbiAgdW5yZWdpc3RlckFwcGxpY2F0aW9uKHRva2VuOiBhbnkpIHtcbiAgICB0aGlzLl9hcHBsaWNhdGlvbnMuZGVsZXRlKHRva2VuKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBVbnJlZ2lzdGVycyBhbGwgYXBwbGljYXRpb25zXG4gICAqL1xuICB1bnJlZ2lzdGVyQWxsQXBwbGljYXRpb25zKCkge1xuICAgIHRoaXMuX2FwcGxpY2F0aW9ucy5jbGVhcigpO1xuICB9XG5cbiAgLyoqXG4gICAqIEdldCBhIHRlc3RhYmlsaXR5IGhvb2sgYXNzb2NpYXRlZCB3aXRoIHRoZSBhcHBsaWNhdGlvblxuICAgKiBAcGFyYW0gZWxlbSByb290IGVsZW1lbnRcbiAgICovXG4gIGdldFRlc3RhYmlsaXR5KGVsZW06IGFueSk6IFRlc3RhYmlsaXR5fG51bGwge1xuICAgIHJldHVybiB0aGlzLl9hcHBsaWNhdGlvbnMuZ2V0KGVsZW0pIHx8IG51bGw7XG4gIH1cblxuICAvKipcbiAgICogR2V0IGFsbCByZWdpc3RlcmVkIHRlc3RhYmlsaXRpZXNcbiAgICovXG4gIGdldEFsbFRlc3RhYmlsaXRpZXMoKTogVGVzdGFiaWxpdHlbXSB7XG4gICAgcmV0dXJuIEFycmF5LmZyb20odGhpcy5fYXBwbGljYXRpb25zLnZhbHVlcygpKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBHZXQgYWxsIHJlZ2lzdGVyZWQgYXBwbGljYXRpb25zKHJvb3QgZWxlbWVudHMpXG4gICAqL1xuICBnZXRBbGxSb290RWxlbWVudHMoKTogYW55W10ge1xuICAgIHJldHVybiBBcnJheS5mcm9tKHRoaXMuX2FwcGxpY2F0aW9ucy5rZXlzKCkpO1xuICB9XG5cbiAgLyoqXG4gICAqIEZpbmQgdGVzdGFiaWxpdHkgb2YgYSBub2RlIGluIHRoZSBUcmVlXG4gICAqIEBwYXJhbSBlbGVtIG5vZGVcbiAgICogQHBhcmFtIGZpbmRJbkFuY2VzdG9ycyB3aGV0aGVyIGZpbmRpbmcgdGVzdGFiaWxpdHkgaW4gYW5jZXN0b3JzIGlmIHRlc3RhYmlsaXR5IHdhcyBub3QgZm91bmQgaW5cbiAgICogY3VycmVudCBub2RlXG4gICAqL1xuICBmaW5kVGVzdGFiaWxpdHlJblRyZWUoZWxlbTogTm9kZSwgZmluZEluQW5jZXN0b3JzOiBib29sZWFuID0gdHJ1ZSk6IFRlc3RhYmlsaXR5fG51bGwge1xuICAgIHJldHVybiBfdGVzdGFiaWxpdHlHZXR0ZXI/LmZpbmRUZXN0YWJpbGl0eUluVHJlZSh0aGlzLCBlbGVtLCBmaW5kSW5BbmNlc3RvcnMpID8/IG51bGw7XG4gIH1cbn1cblxuLyoqXG4gKiBBZGFwdGVyIGludGVyZmFjZSBmb3IgcmV0cmlldmluZyB0aGUgYFRlc3RhYmlsaXR5YCBzZXJ2aWNlIGFzc29jaWF0ZWQgZm9yIGFcbiAqIHBhcnRpY3VsYXIgY29udGV4dC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgR2V0VGVzdGFiaWxpdHkge1xuICBhZGRUb1dpbmRvdyhyZWdpc3RyeTogVGVzdGFiaWxpdHlSZWdpc3RyeSk6IHZvaWQ7XG4gIGZpbmRUZXN0YWJpbGl0eUluVHJlZShyZWdpc3RyeTogVGVzdGFiaWxpdHlSZWdpc3RyeSwgZWxlbTogYW55LCBmaW5kSW5BbmNlc3RvcnM6IGJvb2xlYW4pOlxuICAgICAgVGVzdGFiaWxpdHl8bnVsbDtcbn1cblxuLyoqXG4gKiBTZXQgdGhlIHtAbGluayBHZXRUZXN0YWJpbGl0eX0gaW1wbGVtZW50YXRpb24gdXNlZCBieSB0aGUgQW5ndWxhciB0ZXN0aW5nIGZyYW1ld29yay5cbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldFRlc3RhYmlsaXR5R2V0dGVyKGdldHRlcjogR2V0VGVzdGFiaWxpdHkpOiB2b2lkIHtcbiAgX3Rlc3RhYmlsaXR5R2V0dGVyID0gZ2V0dGVyO1xufVxuXG5sZXQgX3Rlc3RhYmlsaXR5R2V0dGVyOiBHZXRUZXN0YWJpbGl0eXx1bmRlZmluZWQ7XG4iXX0=