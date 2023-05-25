/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵwithHttpTransferCache as withHttpTransferCache } from '@angular/common/http';
import { ENVIRONMENT_INITIALIZER, inject, makeEnvironmentProviders, NgZone, ɵConsole as Console, ɵformatRuntimeError as formatRuntimeError, ɵwithDomHydration as withDomHydration } from '@angular/core';
/**
 * Helper function to create an object that represents a Hydration feature.
 */
function hydrationFeature(kind, providers = []) {
    return { ɵkind: kind, ɵproviders: providers };
}
/**
 * Disables DOM nodes reuse during hydration. Effectively makes
 * Angular re-render an application from scratch on the client.
 *
 * When this option is enabled, make sure that the initial navigation
 * option is configured for the Router as `enabledBlocking` by using the
 * `withEnabledBlockingInitialNavigation` in the `provideRouter` call:
 *
 * ```
 * bootstrapApplication(RootComponent, {
 *   providers: [
 *     provideRouter(
 *       // ... other features ...
 *       withEnabledBlockingInitialNavigation()
 *     ),
 *     provideClientHydration(withNoDomReuse())
 *   ]
 * });
 * ```
 *
 * This would ensure that the application is rerendered after all async
 * operations in the Router (such as lazy-loading of components,
 * waiting for async guards and resolvers) are completed to avoid
 * clearing the DOM on the client too soon, thus causing content flicker.
 *
 * @see `provideRouter`
 * @see `withEnabledBlockingInitialNavigation`
 *
 * @publicApi
 * @developerPreview
 */
export function withNoDomReuse() {
    // This feature has no providers and acts as a flag that turns off
    // non-destructive hydration (which otherwise is turned on by default).
    return hydrationFeature(0 /* HydrationFeatureKind.NoDomReuseFeature */);
}
/**
 * Disables HTTP transfer cache. Effectively causes HTTP requests to be performed twice: once on the
 * server and other one on the browser.
 *
 * @publicApi
 * @developerPreview
 */
export function withNoHttpTransferCache() {
    // This feature has no providers and acts as a flag that turns off
    // HTTP transfer cache (which otherwise is turned on by default).
    return hydrationFeature(1 /* HydrationFeatureKind.NoHttpTransferCache */);
}
/**
 * Returns an `ENVIRONMENT_INITIALIZER` token setup with a function
 * that verifies whether compatible ZoneJS was used in an application
 * and logs a warning in a console if it's not the case.
 */
function provideZoneJsCompatibilityDetector() {
    return [{
            provide: ENVIRONMENT_INITIALIZER,
            useValue: () => {
                const ngZone = inject(NgZone);
                // Checking `ngZone instanceof NgZone` would be insufficient here,
                // because custom implementations might use NgZone as a base class.
                if (ngZone.constructor !== NgZone) {
                    const console = inject(Console);
                    const message = formatRuntimeError(-5000 /* RuntimeErrorCode.UNSUPPORTED_ZONEJS_INSTANCE */, 'Angular detected that hydration was enabled for an application ' +
                        'that uses a custom or a noop Zone.js implementation. ' +
                        'This is not yet a fully supported configuration.');
                    // tslint:disable-next-line:no-console
                    console.warn(message);
                }
            },
            multi: true,
        }];
}
/**
 * Sets up providers necessary to enable hydration functionality for the application.
 * By default, the function enables the recommended set of features for the optimal
 * performance for most of the applications. You can enable/disable features by
 * passing special functions (from the `HydrationFeatures` set) as arguments to the
 * `provideClientHydration` function.
 *
 * @usageNotes
 *
 * Basic example of how you can enable hydration in your application when
 * `bootstrapApplication` function is used:
 * ```
 * bootstrapApplication(AppComponent, {
 *   providers: [provideClientHydration()]
 * });
 * ```
 *
 * Alternatively if you are using NgModules, you would add `provideClientHydration`
 * to your root app module's provider list.
 * ```
 * @NgModule({
 *   declarations: [RootCmp],
 *   bootstrap: [RootCmp],
 *   providers: [provideClientHydration()],
 * })
 * export class AppModule {}
 * ```
 *
 * @see `withNoDomReuse`
 * @see `withNoHttpTransferCache`
 *
 * @param features Optional features to configure additional router behaviors.
 * @returns A set of providers to enable hydration.
 *
 * @publicApi
 * @developerPreview
 */
export function provideClientHydration(...features) {
    const providers = [];
    const featuresKind = new Set();
    for (const { ɵproviders, ɵkind } of features) {
        featuresKind.add(ɵkind);
        if (ɵproviders.length) {
            providers.push(ɵproviders);
        }
    }
    return makeEnvironmentProviders([
        (typeof ngDevMode !== 'undefined' && ngDevMode) ? provideZoneJsCompatibilityDetector() : [],
        (featuresKind.has(0 /* HydrationFeatureKind.NoDomReuseFeature */) ? [] : withDomHydration()),
        (featuresKind.has(1 /* HydrationFeatureKind.NoHttpTransferCache */) ? [] : withHttpTransferCache()),
        providers,
    ]);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaHlkcmF0aW9uLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvcGxhdGZvcm0tYnJvd3Nlci9zcmMvaHlkcmF0aW9uLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxzQkFBc0IsSUFBSSxxQkFBcUIsRUFBQyxNQUFNLHNCQUFzQixDQUFDO0FBQ3JGLE9BQU8sRUFBQyx1QkFBdUIsRUFBd0IsTUFBTSxFQUFFLHdCQUF3QixFQUFFLE1BQU0sRUFBWSxRQUFRLElBQUksT0FBTyxFQUFFLG1CQUFtQixJQUFJLGtCQUFrQixFQUFFLGlCQUFpQixJQUFJLGdCQUFnQixFQUFDLE1BQU0sZUFBZSxDQUFDO0FBMkJ2Tzs7R0FFRztBQUNILFNBQVMsZ0JBQWdCLENBQ3JCLElBQWlCLEVBQUUsWUFBd0IsRUFBRTtJQUMvQyxPQUFPLEVBQUMsS0FBSyxFQUFFLElBQUksRUFBRSxVQUFVLEVBQUUsU0FBUyxFQUFDLENBQUM7QUFDOUMsQ0FBQztBQUVEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7R0E4Qkc7QUFDSCxNQUFNLFVBQVUsY0FBYztJQUM1QixrRUFBa0U7SUFDbEUsdUVBQXVFO0lBQ3ZFLE9BQU8sZ0JBQWdCLGdEQUF3QyxDQUFDO0FBQ2xFLENBQUM7QUFFRDs7Ozs7O0dBTUc7QUFDSCxNQUFNLFVBQVUsdUJBQXVCO0lBRXJDLGtFQUFrRTtJQUNsRSxpRUFBaUU7SUFDakUsT0FBTyxnQkFBZ0Isa0RBQTBDLENBQUM7QUFDcEUsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxTQUFTLGtDQUFrQztJQUN6QyxPQUFPLENBQUM7WUFDTixPQUFPLEVBQUUsdUJBQXVCO1lBQ2hDLFFBQVEsRUFBRSxHQUFHLEVBQUU7Z0JBQ2IsTUFBTSxNQUFNLEdBQUcsTUFBTSxDQUFDLE1BQU0sQ0FBQyxDQUFDO2dCQUM5QixrRUFBa0U7Z0JBQ2xFLG1FQUFtRTtnQkFDbkUsSUFBSSxNQUFNLENBQUMsV0FBVyxLQUFLLE1BQU0sRUFBRTtvQkFDakMsTUFBTSxPQUFPLEdBQUcsTUFBTSxDQUFDLE9BQU8sQ0FBQyxDQUFDO29CQUNoQyxNQUFNLE9BQU8sR0FBRyxrQkFBa0IsMkRBRTlCLGlFQUFpRTt3QkFDN0QsdURBQXVEO3dCQUN2RCxrREFBa0QsQ0FBQyxDQUFDO29CQUM1RCxzQ0FBc0M7b0JBQ3RDLE9BQU8sQ0FBQyxJQUFJLENBQUMsT0FBTyxDQUFDLENBQUM7aUJBQ3ZCO1lBQ0gsQ0FBQztZQUNELEtBQUssRUFBRSxJQUFJO1NBQ1osQ0FBQyxDQUFDO0FBQ0wsQ0FBQztBQUVEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7R0FvQ0c7QUFDSCxNQUFNLFVBQVUsc0JBQXNCLENBQUMsR0FBRyxRQUFrRDtJQUUxRixNQUFNLFNBQVMsR0FBZSxFQUFFLENBQUM7SUFDakMsTUFBTSxZQUFZLEdBQUcsSUFBSSxHQUFHLEVBQXdCLENBQUM7SUFFckQsS0FBSyxNQUFNLEVBQUMsVUFBVSxFQUFFLEtBQUssRUFBQyxJQUFJLFFBQVEsRUFBRTtRQUMxQyxZQUFZLENBQUMsR0FBRyxDQUFDLEtBQUssQ0FBQyxDQUFDO1FBRXhCLElBQUksVUFBVSxDQUFDLE1BQU0sRUFBRTtZQUNyQixTQUFTLENBQUMsSUFBSSxDQUFDLFVBQVUsQ0FBQyxDQUFDO1NBQzVCO0tBQ0Y7SUFFRCxPQUFPLHdCQUF3QixDQUFDO1FBQzlCLENBQUMsT0FBTyxTQUFTLEtBQUssV0FBVyxJQUFJLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxrQ0FBa0MsRUFBRSxDQUFDLENBQUMsQ0FBQyxFQUFFO1FBQzNGLENBQUMsWUFBWSxDQUFDLEdBQUcsZ0RBQXdDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsZ0JBQWdCLEVBQUUsQ0FBQztRQUNwRixDQUFDLFlBQVksQ0FBQyxHQUFHLGtEQUEwQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLHFCQUFxQixFQUFFLENBQUM7UUFDM0YsU0FBUztLQUNWLENBQUMsQ0FBQztBQUNMLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHvJtXdpdGhIdHRwVHJhbnNmZXJDYWNoZSBhcyB3aXRoSHR0cFRyYW5zZmVyQ2FjaGV9IGZyb20gJ0Bhbmd1bGFyL2NvbW1vbi9odHRwJztcbmltcG9ydCB7RU5WSVJPTk1FTlRfSU5JVElBTElaRVIsIEVudmlyb25tZW50UHJvdmlkZXJzLCBpbmplY3QsIG1ha2VFbnZpcm9ubWVudFByb3ZpZGVycywgTmdab25lLCBQcm92aWRlciwgybVDb25zb2xlIGFzIENvbnNvbGUsIMm1Zm9ybWF0UnVudGltZUVycm9yIGFzIGZvcm1hdFJ1bnRpbWVFcnJvciwgybV3aXRoRG9tSHlkcmF0aW9uIGFzIHdpdGhEb21IeWRyYXRpb259IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuXG5pbXBvcnQge1J1bnRpbWVFcnJvckNvZGV9IGZyb20gJy4vZXJyb3JzJztcblxuLyoqXG4gKiBUaGUgbGlzdCBvZiBmZWF0dXJlcyBhcyBhbiBlbnVtIHRvIHVuaXF1ZWx5IHR5cGUgZWFjaCBgSHlkcmF0aW9uRmVhdHVyZWAuXG4gKiBAc2VlIEh5ZHJhdGlvbkZlYXR1cmVcbiAqXG4gKiBAcHVibGljQXBpXG4gKiBAZGV2ZWxvcGVyUHJldmlld1xuICovXG5leHBvcnQgY29uc3QgZW51bSBIeWRyYXRpb25GZWF0dXJlS2luZCB7XG4gIE5vRG9tUmV1c2VGZWF0dXJlLFxuICBOb0h0dHBUcmFuc2ZlckNhY2hlXG59XG5cbi8qKlxuICogSGVscGVyIHR5cGUgdG8gcmVwcmVzZW50IGEgSHlkcmF0aW9uIGZlYXR1cmUuXG4gKlxuICogQHB1YmxpY0FwaVxuICogQGRldmVsb3BlclByZXZpZXdcbiAqL1xuZXhwb3J0IGludGVyZmFjZSBIeWRyYXRpb25GZWF0dXJlPEZlYXR1cmVLaW5kIGV4dGVuZHMgSHlkcmF0aW9uRmVhdHVyZUtpbmQ+IHtcbiAgybVraW5kOiBGZWF0dXJlS2luZDtcbiAgybVwcm92aWRlcnM6IFByb3ZpZGVyW107XG59XG5cbi8qKlxuICogSGVscGVyIGZ1bmN0aW9uIHRvIGNyZWF0ZSBhbiBvYmplY3QgdGhhdCByZXByZXNlbnRzIGEgSHlkcmF0aW9uIGZlYXR1cmUuXG4gKi9cbmZ1bmN0aW9uIGh5ZHJhdGlvbkZlYXR1cmU8RmVhdHVyZUtpbmQgZXh0ZW5kcyBIeWRyYXRpb25GZWF0dXJlS2luZD4oXG4gICAga2luZDogRmVhdHVyZUtpbmQsIHByb3ZpZGVyczogUHJvdmlkZXJbXSA9IFtdKTogSHlkcmF0aW9uRmVhdHVyZTxGZWF0dXJlS2luZD4ge1xuICByZXR1cm4ge8m1a2luZDoga2luZCwgybVwcm92aWRlcnM6IHByb3ZpZGVyc307XG59XG5cbi8qKlxuICogRGlzYWJsZXMgRE9NIG5vZGVzIHJldXNlIGR1cmluZyBoeWRyYXRpb24uIEVmZmVjdGl2ZWx5IG1ha2VzXG4gKiBBbmd1bGFyIHJlLXJlbmRlciBhbiBhcHBsaWNhdGlvbiBmcm9tIHNjcmF0Y2ggb24gdGhlIGNsaWVudC5cbiAqXG4gKiBXaGVuIHRoaXMgb3B0aW9uIGlzIGVuYWJsZWQsIG1ha2Ugc3VyZSB0aGF0IHRoZSBpbml0aWFsIG5hdmlnYXRpb25cbiAqIG9wdGlvbiBpcyBjb25maWd1cmVkIGZvciB0aGUgUm91dGVyIGFzIGBlbmFibGVkQmxvY2tpbmdgIGJ5IHVzaW5nIHRoZVxuICogYHdpdGhFbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbmAgaW4gdGhlIGBwcm92aWRlUm91dGVyYCBjYWxsOlxuICpcbiAqIGBgYFxuICogYm9vdHN0cmFwQXBwbGljYXRpb24oUm9vdENvbXBvbmVudCwge1xuICogICBwcm92aWRlcnM6IFtcbiAqICAgICBwcm92aWRlUm91dGVyKFxuICogICAgICAgLy8gLi4uIG90aGVyIGZlYXR1cmVzIC4uLlxuICogICAgICAgd2l0aEVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uKClcbiAqICAgICApLFxuICogICAgIHByb3ZpZGVDbGllbnRIeWRyYXRpb24od2l0aE5vRG9tUmV1c2UoKSlcbiAqICAgXVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBUaGlzIHdvdWxkIGVuc3VyZSB0aGF0IHRoZSBhcHBsaWNhdGlvbiBpcyByZXJlbmRlcmVkIGFmdGVyIGFsbCBhc3luY1xuICogb3BlcmF0aW9ucyBpbiB0aGUgUm91dGVyIChzdWNoIGFzIGxhenktbG9hZGluZyBvZiBjb21wb25lbnRzLFxuICogd2FpdGluZyBmb3IgYXN5bmMgZ3VhcmRzIGFuZCByZXNvbHZlcnMpIGFyZSBjb21wbGV0ZWQgdG8gYXZvaWRcbiAqIGNsZWFyaW5nIHRoZSBET00gb24gdGhlIGNsaWVudCB0b28gc29vbiwgdGh1cyBjYXVzaW5nIGNvbnRlbnQgZmxpY2tlci5cbiAqXG4gKiBAc2VlIGBwcm92aWRlUm91dGVyYFxuICogQHNlZSBgd2l0aEVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uYFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqIEBkZXZlbG9wZXJQcmV2aWV3XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB3aXRoTm9Eb21SZXVzZSgpOiBIeWRyYXRpb25GZWF0dXJlPEh5ZHJhdGlvbkZlYXR1cmVLaW5kLk5vRG9tUmV1c2VGZWF0dXJlPiB7XG4gIC8vIFRoaXMgZmVhdHVyZSBoYXMgbm8gcHJvdmlkZXJzIGFuZCBhY3RzIGFzIGEgZmxhZyB0aGF0IHR1cm5zIG9mZlxuICAvLyBub24tZGVzdHJ1Y3RpdmUgaHlkcmF0aW9uICh3aGljaCBvdGhlcndpc2UgaXMgdHVybmVkIG9uIGJ5IGRlZmF1bHQpLlxuICByZXR1cm4gaHlkcmF0aW9uRmVhdHVyZShIeWRyYXRpb25GZWF0dXJlS2luZC5Ob0RvbVJldXNlRmVhdHVyZSk7XG59XG5cbi8qKlxuICogRGlzYWJsZXMgSFRUUCB0cmFuc2ZlciBjYWNoZS4gRWZmZWN0aXZlbHkgY2F1c2VzIEhUVFAgcmVxdWVzdHMgdG8gYmUgcGVyZm9ybWVkIHR3aWNlOiBvbmNlIG9uIHRoZVxuICogc2VydmVyIGFuZCBvdGhlciBvbmUgb24gdGhlIGJyb3dzZXIuXG4gKlxuICogQHB1YmxpY0FwaVxuICogQGRldmVsb3BlclByZXZpZXdcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdpdGhOb0h0dHBUcmFuc2ZlckNhY2hlKCk6XG4gICAgSHlkcmF0aW9uRmVhdHVyZTxIeWRyYXRpb25GZWF0dXJlS2luZC5Ob0h0dHBUcmFuc2ZlckNhY2hlPiB7XG4gIC8vIFRoaXMgZmVhdHVyZSBoYXMgbm8gcHJvdmlkZXJzIGFuZCBhY3RzIGFzIGEgZmxhZyB0aGF0IHR1cm5zIG9mZlxuICAvLyBIVFRQIHRyYW5zZmVyIGNhY2hlICh3aGljaCBvdGhlcndpc2UgaXMgdHVybmVkIG9uIGJ5IGRlZmF1bHQpLlxuICByZXR1cm4gaHlkcmF0aW9uRmVhdHVyZShIeWRyYXRpb25GZWF0dXJlS2luZC5Ob0h0dHBUcmFuc2ZlckNhY2hlKTtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIGFuIGBFTlZJUk9OTUVOVF9JTklUSUFMSVpFUmAgdG9rZW4gc2V0dXAgd2l0aCBhIGZ1bmN0aW9uXG4gKiB0aGF0IHZlcmlmaWVzIHdoZXRoZXIgY29tcGF0aWJsZSBab25lSlMgd2FzIHVzZWQgaW4gYW4gYXBwbGljYXRpb25cbiAqIGFuZCBsb2dzIGEgd2FybmluZyBpbiBhIGNvbnNvbGUgaWYgaXQncyBub3QgdGhlIGNhc2UuXG4gKi9cbmZ1bmN0aW9uIHByb3ZpZGVab25lSnNDb21wYXRpYmlsaXR5RGV0ZWN0b3IoKTogUHJvdmlkZXJbXSB7XG4gIHJldHVybiBbe1xuICAgIHByb3ZpZGU6IEVOVklST05NRU5UX0lOSVRJQUxJWkVSLFxuICAgIHVzZVZhbHVlOiAoKSA9PiB7XG4gICAgICBjb25zdCBuZ1pvbmUgPSBpbmplY3QoTmdab25lKTtcbiAgICAgIC8vIENoZWNraW5nIGBuZ1pvbmUgaW5zdGFuY2VvZiBOZ1pvbmVgIHdvdWxkIGJlIGluc3VmZmljaWVudCBoZXJlLFxuICAgICAgLy8gYmVjYXVzZSBjdXN0b20gaW1wbGVtZW50YXRpb25zIG1pZ2h0IHVzZSBOZ1pvbmUgYXMgYSBiYXNlIGNsYXNzLlxuICAgICAgaWYgKG5nWm9uZS5jb25zdHJ1Y3RvciAhPT0gTmdab25lKSB7XG4gICAgICAgIGNvbnN0IGNvbnNvbGUgPSBpbmplY3QoQ29uc29sZSk7XG4gICAgICAgIGNvbnN0IG1lc3NhZ2UgPSBmb3JtYXRSdW50aW1lRXJyb3IoXG4gICAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLlVOU1VQUE9SVEVEX1pPTkVKU19JTlNUQU5DRSxcbiAgICAgICAgICAgICdBbmd1bGFyIGRldGVjdGVkIHRoYXQgaHlkcmF0aW9uIHdhcyBlbmFibGVkIGZvciBhbiBhcHBsaWNhdGlvbiAnICtcbiAgICAgICAgICAgICAgICAndGhhdCB1c2VzIGEgY3VzdG9tIG9yIGEgbm9vcCBab25lLmpzIGltcGxlbWVudGF0aW9uLiAnICtcbiAgICAgICAgICAgICAgICAnVGhpcyBpcyBub3QgeWV0IGEgZnVsbHkgc3VwcG9ydGVkIGNvbmZpZ3VyYXRpb24uJyk7XG4gICAgICAgIC8vIHRzbGludDpkaXNhYmxlLW5leHQtbGluZTpuby1jb25zb2xlXG4gICAgICAgIGNvbnNvbGUud2FybihtZXNzYWdlKTtcbiAgICAgIH1cbiAgICB9LFxuICAgIG11bHRpOiB0cnVlLFxuICB9XTtcbn1cblxuLyoqXG4gKiBTZXRzIHVwIHByb3ZpZGVycyBuZWNlc3NhcnkgdG8gZW5hYmxlIGh5ZHJhdGlvbiBmdW5jdGlvbmFsaXR5IGZvciB0aGUgYXBwbGljYXRpb24uXG4gKiBCeSBkZWZhdWx0LCB0aGUgZnVuY3Rpb24gZW5hYmxlcyB0aGUgcmVjb21tZW5kZWQgc2V0IG9mIGZlYXR1cmVzIGZvciB0aGUgb3B0aW1hbFxuICogcGVyZm9ybWFuY2UgZm9yIG1vc3Qgb2YgdGhlIGFwcGxpY2F0aW9ucy4gWW91IGNhbiBlbmFibGUvZGlzYWJsZSBmZWF0dXJlcyBieVxuICogcGFzc2luZyBzcGVjaWFsIGZ1bmN0aW9ucyAoZnJvbSB0aGUgYEh5ZHJhdGlvbkZlYXR1cmVzYCBzZXQpIGFzIGFyZ3VtZW50cyB0byB0aGVcbiAqIGBwcm92aWRlQ2xpZW50SHlkcmF0aW9uYCBmdW5jdGlvbi5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIEJhc2ljIGV4YW1wbGUgb2YgaG93IHlvdSBjYW4gZW5hYmxlIGh5ZHJhdGlvbiBpbiB5b3VyIGFwcGxpY2F0aW9uIHdoZW5cbiAqIGBib290c3RyYXBBcHBsaWNhdGlvbmAgZnVuY3Rpb24gaXMgdXNlZDpcbiAqIGBgYFxuICogYm9vdHN0cmFwQXBwbGljYXRpb24oQXBwQ29tcG9uZW50LCB7XG4gKiAgIHByb3ZpZGVyczogW3Byb3ZpZGVDbGllbnRIeWRyYXRpb24oKV1cbiAqIH0pO1xuICogYGBgXG4gKlxuICogQWx0ZXJuYXRpdmVseSBpZiB5b3UgYXJlIHVzaW5nIE5nTW9kdWxlcywgeW91IHdvdWxkIGFkZCBgcHJvdmlkZUNsaWVudEh5ZHJhdGlvbmBcbiAqIHRvIHlvdXIgcm9vdCBhcHAgbW9kdWxlJ3MgcHJvdmlkZXIgbGlzdC5cbiAqIGBgYFxuICogQE5nTW9kdWxlKHtcbiAqICAgZGVjbGFyYXRpb25zOiBbUm9vdENtcF0sXG4gKiAgIGJvb3RzdHJhcDogW1Jvb3RDbXBdLFxuICogICBwcm92aWRlcnM6IFtwcm92aWRlQ2xpZW50SHlkcmF0aW9uKCldLFxuICogfSlcbiAqIGV4cG9ydCBjbGFzcyBBcHBNb2R1bGUge31cbiAqIGBgYFxuICpcbiAqIEBzZWUgYHdpdGhOb0RvbVJldXNlYFxuICogQHNlZSBgd2l0aE5vSHR0cFRyYW5zZmVyQ2FjaGVgXG4gKlxuICogQHBhcmFtIGZlYXR1cmVzIE9wdGlvbmFsIGZlYXR1cmVzIHRvIGNvbmZpZ3VyZSBhZGRpdGlvbmFsIHJvdXRlciBiZWhhdmlvcnMuXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgdG8gZW5hYmxlIGh5ZHJhdGlvbi5cbiAqXG4gKiBAcHVibGljQXBpXG4gKiBAZGV2ZWxvcGVyUHJldmlld1xuICovXG5leHBvcnQgZnVuY3Rpb24gcHJvdmlkZUNsaWVudEh5ZHJhdGlvbiguLi5mZWF0dXJlczogSHlkcmF0aW9uRmVhdHVyZTxIeWRyYXRpb25GZWF0dXJlS2luZD5bXSk6XG4gICAgRW52aXJvbm1lbnRQcm92aWRlcnMge1xuICBjb25zdCBwcm92aWRlcnM6IFByb3ZpZGVyW10gPSBbXTtcbiAgY29uc3QgZmVhdHVyZXNLaW5kID0gbmV3IFNldDxIeWRyYXRpb25GZWF0dXJlS2luZD4oKTtcblxuICBmb3IgKGNvbnN0IHvJtXByb3ZpZGVycywgybVraW5kfSBvZiBmZWF0dXJlcykge1xuICAgIGZlYXR1cmVzS2luZC5hZGQoybVraW5kKTtcblxuICAgIGlmICjJtXByb3ZpZGVycy5sZW5ndGgpIHtcbiAgICAgIHByb3ZpZGVycy5wdXNoKMm1cHJvdmlkZXJzKTtcbiAgICB9XG4gIH1cblxuICByZXR1cm4gbWFrZUVudmlyb25tZW50UHJvdmlkZXJzKFtcbiAgICAodHlwZW9mIG5nRGV2TW9kZSAhPT0gJ3VuZGVmaW5lZCcgJiYgbmdEZXZNb2RlKSA/IHByb3ZpZGVab25lSnNDb21wYXRpYmlsaXR5RGV0ZWN0b3IoKSA6IFtdLFxuICAgIChmZWF0dXJlc0tpbmQuaGFzKEh5ZHJhdGlvbkZlYXR1cmVLaW5kLk5vRG9tUmV1c2VGZWF0dXJlKSA/IFtdIDogd2l0aERvbUh5ZHJhdGlvbigpKSxcbiAgICAoZmVhdHVyZXNLaW5kLmhhcyhIeWRyYXRpb25GZWF0dXJlS2luZC5Ob0h0dHBUcmFuc2ZlckNhY2hlKSA/IFtdIDogd2l0aEh0dHBUcmFuc2ZlckNhY2hlKCkpLFxuICAgIHByb3ZpZGVycyxcbiAgXSk7XG59XG4iXX0=