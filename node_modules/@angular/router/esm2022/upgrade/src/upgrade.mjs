/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { Location } from '@angular/common';
import { APP_BOOTSTRAP_LISTENER } from '@angular/core';
import { Router } from '@angular/router';
import { UpgradeModule } from '@angular/upgrade/static';
/**
 * Creates an initializer that sets up `ngRoute` integration
 * along with setting up the Angular router.
 *
 * @usageNotes
 *
 * <code-example language="typescript">
 * @NgModule({
 *  imports: [
 *   RouterModule.forRoot(SOME_ROUTES),
 *   UpgradeModule
 * ],
 * providers: [
 *   RouterUpgradeInitializer
 * ]
 * })
 * export class AppModule {
 *   ngDoBootstrap() {}
 * }
 * </code-example>
 *
 * @publicApi
 */
export const RouterUpgradeInitializer = {
    provide: APP_BOOTSTRAP_LISTENER,
    multi: true,
    useFactory: locationSyncBootstrapListener,
    deps: [UpgradeModule]
};
/**
 * @internal
 */
export function locationSyncBootstrapListener(ngUpgrade) {
    return () => {
        setUpLocationSync(ngUpgrade);
    };
}
/**
 * Sets up a location change listener to trigger `history.pushState`.
 * Works around the problem that `onPopState` does not trigger `history.pushState`.
 * Must be called *after* calling `UpgradeModule.bootstrap`.
 *
 * @param ngUpgrade The upgrade NgModule.
 * @param urlType The location strategy.
 * @see `HashLocationStrategy`
 * @see `PathLocationStrategy`
 *
 * @publicApi
 */
export function setUpLocationSync(ngUpgrade, urlType = 'path') {
    if (!ngUpgrade.$injector) {
        throw new Error(`
        RouterUpgradeInitializer can be used only after UpgradeModule.bootstrap has been called.
        Remove RouterUpgradeInitializer and call setUpLocationSync after UpgradeModule.bootstrap.
      `);
    }
    const router = ngUpgrade.injector.get(Router);
    const location = ngUpgrade.injector.get(Location);
    ngUpgrade.$injector.get('$rootScope')
        .$on('$locationChangeStart', (event, newUrl, oldUrl, newState, oldState) => {
        // Navigations coming from Angular router have a navigationId state
        // property. Don't trigger Angular router navigation again if it is
        // caused by a URL change from the current Angular router
        // navigation.
        const currentNavigationId = router.getCurrentNavigation()?.id;
        const newStateNavigationId = newState?.navigationId;
        if (newStateNavigationId !== undefined &&
            newStateNavigationId === currentNavigationId) {
            return;
        }
        let url;
        if (urlType === 'path') {
            url = resolveUrl(newUrl);
        }
        else if (urlType === 'hash') {
            // Remove the first hash from the URL
            const hashIdx = newUrl.indexOf('#');
            url = resolveUrl(newUrl.substring(0, hashIdx) + newUrl.substring(hashIdx + 1));
        }
        else {
            throw 'Invalid URLType passed to setUpLocationSync: ' + urlType;
        }
        const path = location.normalize(url.pathname);
        router.navigateByUrl(path + url.search + url.hash);
    });
}
/**
 * Normalizes and parses a URL.
 *
 * - Normalizing means that a relative URL will be resolved into an absolute URL in the context of
 *   the application document.
 * - Parsing means that the anchor's `protocol`, `hostname`, `port`, `pathname` and related
 *   properties are all populated to reflect the normalized URL.
 *
 * While this approach has wide compatibility, it doesn't work as expected on IE. On IE, normalizing
 * happens similar to other browsers, but the parsed components will not be set. (E.g. if you assign
 * `a.href = 'foo'`, then `a.protocol`, `a.host`, etc. will not be correctly updated.)
 * We work around that by performing the parsing in a 2nd step by taking a previously normalized URL
 * and assigning it again. This correctly populates all properties.
 *
 * See
 * https://github.com/angular/angular.js/blob/2c7400e7d07b0f6cec1817dab40b9250ce8ebce6/src/ng/urlUtils.js#L26-L33
 * for more info.
 */
let anchor;
function resolveUrl(url) {
    if (!anchor) {
        anchor = document.createElement('a');
    }
    anchor.setAttribute('href', url);
    anchor.setAttribute('href', anchor.href);
    return {
        // IE does not start `pathname` with `/` like other browsers.
        pathname: `/${anchor.pathname.replace(/^\//, '')}`,
        search: anchor.search,
        hash: anchor.hash
    };
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidXBncmFkZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL3JvdXRlci91cGdyYWRlL3NyYy91cGdyYWRlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxRQUFRLEVBQUMsTUFBTSxpQkFBaUIsQ0FBQztBQUN6QyxPQUFPLEVBQUMsc0JBQXNCLEVBQStCLE1BQU0sZUFBZSxDQUFDO0FBQ25GLE9BQU8sRUFBQyxNQUFNLEVBQWtDLE1BQU0saUJBQWlCLENBQUM7QUFDeEUsT0FBTyxFQUFDLGFBQWEsRUFBQyxNQUFNLHlCQUF5QixDQUFDO0FBRXREOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBc0JHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sd0JBQXdCLEdBQUc7SUFDdEMsT0FBTyxFQUFFLHNCQUFzQjtJQUMvQixLQUFLLEVBQUUsSUFBSTtJQUNYLFVBQVUsRUFBRSw2QkFBeUU7SUFDckYsSUFBSSxFQUFFLENBQUMsYUFBYSxDQUFDO0NBQ3RCLENBQUM7QUFFRjs7R0FFRztBQUNILE1BQU0sVUFBVSw2QkFBNkIsQ0FBQyxTQUF3QjtJQUNwRSxPQUFPLEdBQUcsRUFBRTtRQUNWLGlCQUFpQixDQUFDLFNBQVMsQ0FBQyxDQUFDO0lBQy9CLENBQUMsQ0FBQztBQUNKLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7R0FXRztBQUNILE1BQU0sVUFBVSxpQkFBaUIsQ0FBQyxTQUF3QixFQUFFLFVBQXlCLE1BQU07SUFDekYsSUFBSSxDQUFDLFNBQVMsQ0FBQyxTQUFTLEVBQUU7UUFDeEIsTUFBTSxJQUFJLEtBQUssQ0FBQzs7O09BR2IsQ0FBQyxDQUFDO0tBQ047SUFFRCxNQUFNLE1BQU0sR0FBVyxTQUFTLENBQUMsUUFBUSxDQUFDLEdBQUcsQ0FBQyxNQUFNLENBQUMsQ0FBQztJQUN0RCxNQUFNLFFBQVEsR0FBYSxTQUFTLENBQUMsUUFBUSxDQUFDLEdBQUcsQ0FBQyxRQUFRLENBQUMsQ0FBQztJQUU1RCxTQUFTLENBQUMsU0FBUyxDQUFDLEdBQUcsQ0FBQyxZQUFZLENBQUM7U0FDaEMsR0FBRyxDQUNBLHNCQUFzQixFQUN0QixDQUFDLEtBQVUsRUFBRSxNQUFjLEVBQUUsTUFBYyxFQUMxQyxRQUErQyxFQUMvQyxRQUErQyxFQUFFLEVBQUU7UUFDbEQsbUVBQW1FO1FBQ25FLG1FQUFtRTtRQUNuRSx5REFBeUQ7UUFDekQsY0FBYztRQUNkLE1BQU0sbUJBQW1CLEdBQUcsTUFBTSxDQUFDLG9CQUFvQixFQUFFLEVBQUUsRUFBRSxDQUFDO1FBQzlELE1BQU0sb0JBQW9CLEdBQUcsUUFBUSxFQUFFLFlBQVksQ0FBQztRQUNwRCxJQUFJLG9CQUFvQixLQUFLLFNBQVM7WUFDbEMsb0JBQW9CLEtBQUssbUJBQW1CLEVBQUU7WUFDaEQsT0FBTztTQUNSO1FBRUQsSUFBSSxHQUFHLENBQUM7UUFDUixJQUFJLE9BQU8sS0FBSyxNQUFNLEVBQUU7WUFDdEIsR0FBRyxHQUFHLFVBQVUsQ0FBQyxNQUFNLENBQUMsQ0FBQztTQUMxQjthQUFNLElBQUksT0FBTyxLQUFLLE1BQU0sRUFBRTtZQUM3QixxQ0FBcUM7WUFDckMsTUFBTSxPQUFPLEdBQUcsTUFBTSxDQUFDLE9BQU8sQ0FBQyxHQUFHLENBQUMsQ0FBQztZQUNwQyxHQUFHLEdBQUcsVUFBVSxDQUFDLE1BQU0sQ0FBQyxTQUFTLENBQUMsQ0FBQyxFQUFFLE9BQU8sQ0FBQyxHQUFHLE1BQU0sQ0FBQyxTQUFTLENBQUMsT0FBTyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUM7U0FDaEY7YUFBTTtZQUNMLE1BQU0sK0NBQStDLEdBQUcsT0FBTyxDQUFDO1NBQ2pFO1FBQ0QsTUFBTSxJQUFJLEdBQUcsUUFBUSxDQUFDLFNBQVMsQ0FBQyxHQUFHLENBQUMsUUFBUSxDQUFDLENBQUM7UUFDOUMsTUFBTSxDQUFDLGFBQWEsQ0FBQyxJQUFJLEdBQUcsR0FBRyxDQUFDLE1BQU0sR0FBRyxHQUFHLENBQUMsSUFBSSxDQUFDLENBQUM7SUFDckQsQ0FBQyxDQUFDLENBQUM7QUFDYixDQUFDO0FBRUQ7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBaUJHO0FBQ0gsSUFBSSxNQUFtQyxDQUFDO0FBQ3hDLFNBQVMsVUFBVSxDQUFDLEdBQVc7SUFDN0IsSUFBSSxDQUFDLE1BQU0sRUFBRTtRQUNYLE1BQU0sR0FBRyxRQUFRLENBQUMsYUFBYSxDQUFDLEdBQUcsQ0FBQyxDQUFDO0tBQ3RDO0lBRUQsTUFBTSxDQUFDLFlBQVksQ0FBQyxNQUFNLEVBQUUsR0FBRyxDQUFDLENBQUM7SUFDakMsTUFBTSxDQUFDLFlBQVksQ0FBQyxNQUFNLEVBQUUsTUFBTSxDQUFDLElBQUksQ0FBQyxDQUFDO0lBRXpDLE9BQU87UUFDTCw2REFBNkQ7UUFDN0QsUUFBUSxFQUFFLElBQUksTUFBTSxDQUFDLFFBQVEsQ0FBQyxPQUFPLENBQUMsS0FBSyxFQUFFLEVBQUUsQ0FBQyxFQUFFO1FBQ2xELE1BQU0sRUFBRSxNQUFNLENBQUMsTUFBTTtRQUNyQixJQUFJLEVBQUUsTUFBTSxDQUFDLElBQUk7S0FDbEIsQ0FBQztBQUNKLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtMb2NhdGlvbn0gZnJvbSAnQGFuZ3VsYXIvY29tbW9uJztcbmltcG9ydCB7QVBQX0JPT1RTVFJBUF9MSVNURU5FUiwgQ29tcG9uZW50UmVmLCBJbmplY3Rpb25Ub2tlbn0gZnJvbSAnQGFuZ3VsYXIvY29yZSc7XG5pbXBvcnQge1JvdXRlciwgybVSZXN0b3JlZFN0YXRlIGFzIFJlc3RvcmVkU3RhdGV9IGZyb20gJ0Bhbmd1bGFyL3JvdXRlcic7XG5pbXBvcnQge1VwZ3JhZGVNb2R1bGV9IGZyb20gJ0Bhbmd1bGFyL3VwZ3JhZGUvc3RhdGljJztcblxuLyoqXG4gKiBDcmVhdGVzIGFuIGluaXRpYWxpemVyIHRoYXQgc2V0cyB1cCBgbmdSb3V0ZWAgaW50ZWdyYXRpb25cbiAqIGFsb25nIHdpdGggc2V0dGluZyB1cCB0aGUgQW5ndWxhciByb3V0ZXIuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiA8Y29kZS1leGFtcGxlIGxhbmd1YWdlPVwidHlwZXNjcmlwdFwiPlxuICogQE5nTW9kdWxlKHtcbiAqICBpbXBvcnRzOiBbXG4gKiAgIFJvdXRlck1vZHVsZS5mb3JSb290KFNPTUVfUk9VVEVTKSxcbiAqICAgVXBncmFkZU1vZHVsZVxuICogXSxcbiAqIHByb3ZpZGVyczogW1xuICogICBSb3V0ZXJVcGdyYWRlSW5pdGlhbGl6ZXJcbiAqIF1cbiAqIH0pXG4gKiBleHBvcnQgY2xhc3MgQXBwTW9kdWxlIHtcbiAqICAgbmdEb0Jvb3RzdHJhcCgpIHt9XG4gKiB9XG4gKiA8L2NvZGUtZXhhbXBsZT5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBSb3V0ZXJVcGdyYWRlSW5pdGlhbGl6ZXIgPSB7XG4gIHByb3ZpZGU6IEFQUF9CT09UU1RSQVBfTElTVEVORVIsXG4gIG11bHRpOiB0cnVlLFxuICB1c2VGYWN0b3J5OiBsb2NhdGlvblN5bmNCb290c3RyYXBMaXN0ZW5lciBhcyAobmdVcGdyYWRlOiBVcGdyYWRlTW9kdWxlKSA9PiAoKSA9PiB2b2lkLFxuICBkZXBzOiBbVXBncmFkZU1vZHVsZV1cbn07XG5cbi8qKlxuICogQGludGVybmFsXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBsb2NhdGlvblN5bmNCb290c3RyYXBMaXN0ZW5lcihuZ1VwZ3JhZGU6IFVwZ3JhZGVNb2R1bGUpIHtcbiAgcmV0dXJuICgpID0+IHtcbiAgICBzZXRVcExvY2F0aW9uU3luYyhuZ1VwZ3JhZGUpO1xuICB9O1xufVxuXG4vKipcbiAqIFNldHMgdXAgYSBsb2NhdGlvbiBjaGFuZ2UgbGlzdGVuZXIgdG8gdHJpZ2dlciBgaGlzdG9yeS5wdXNoU3RhdGVgLlxuICogV29ya3MgYXJvdW5kIHRoZSBwcm9ibGVtIHRoYXQgYG9uUG9wU3RhdGVgIGRvZXMgbm90IHRyaWdnZXIgYGhpc3RvcnkucHVzaFN0YXRlYC5cbiAqIE11c3QgYmUgY2FsbGVkICphZnRlciogY2FsbGluZyBgVXBncmFkZU1vZHVsZS5ib290c3RyYXBgLlxuICpcbiAqIEBwYXJhbSBuZ1VwZ3JhZGUgVGhlIHVwZ3JhZGUgTmdNb2R1bGUuXG4gKiBAcGFyYW0gdXJsVHlwZSBUaGUgbG9jYXRpb24gc3RyYXRlZ3kuXG4gKiBAc2VlIGBIYXNoTG9jYXRpb25TdHJhdGVneWBcbiAqIEBzZWUgYFBhdGhMb2NhdGlvblN0cmF0ZWd5YFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldFVwTG9jYXRpb25TeW5jKG5nVXBncmFkZTogVXBncmFkZU1vZHVsZSwgdXJsVHlwZTogJ3BhdGgnfCdoYXNoJyA9ICdwYXRoJykge1xuICBpZiAoIW5nVXBncmFkZS4kaW5qZWN0b3IpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFxuICAgICAgICBSb3V0ZXJVcGdyYWRlSW5pdGlhbGl6ZXIgY2FuIGJlIHVzZWQgb25seSBhZnRlciBVcGdyYWRlTW9kdWxlLmJvb3RzdHJhcCBoYXMgYmVlbiBjYWxsZWQuXG4gICAgICAgIFJlbW92ZSBSb3V0ZXJVcGdyYWRlSW5pdGlhbGl6ZXIgYW5kIGNhbGwgc2V0VXBMb2NhdGlvblN5bmMgYWZ0ZXIgVXBncmFkZU1vZHVsZS5ib290c3RyYXAuXG4gICAgICBgKTtcbiAgfVxuXG4gIGNvbnN0IHJvdXRlcjogUm91dGVyID0gbmdVcGdyYWRlLmluamVjdG9yLmdldChSb3V0ZXIpO1xuICBjb25zdCBsb2NhdGlvbjogTG9jYXRpb24gPSBuZ1VwZ3JhZGUuaW5qZWN0b3IuZ2V0KExvY2F0aW9uKTtcblxuICBuZ1VwZ3JhZGUuJGluamVjdG9yLmdldCgnJHJvb3RTY29wZScpXG4gICAgICAuJG9uKFxuICAgICAgICAgICckbG9jYXRpb25DaGFuZ2VTdGFydCcsXG4gICAgICAgICAgKGV2ZW50OiBhbnksIG5ld1VybDogc3RyaW5nLCBvbGRVcmw6IHN0cmluZyxcbiAgICAgICAgICAgbmV3U3RhdGU/OiB7W2s6IHN0cmluZ106IHVua25vd259fFJlc3RvcmVkU3RhdGUsXG4gICAgICAgICAgIG9sZFN0YXRlPzoge1trOiBzdHJpbmddOiB1bmtub3dufXxSZXN0b3JlZFN0YXRlKSA9PiB7XG4gICAgICAgICAgICAvLyBOYXZpZ2F0aW9ucyBjb21pbmcgZnJvbSBBbmd1bGFyIHJvdXRlciBoYXZlIGEgbmF2aWdhdGlvbklkIHN0YXRlXG4gICAgICAgICAgICAvLyBwcm9wZXJ0eS4gRG9uJ3QgdHJpZ2dlciBBbmd1bGFyIHJvdXRlciBuYXZpZ2F0aW9uIGFnYWluIGlmIGl0IGlzXG4gICAgICAgICAgICAvLyBjYXVzZWQgYnkgYSBVUkwgY2hhbmdlIGZyb20gdGhlIGN1cnJlbnQgQW5ndWxhciByb3V0ZXJcbiAgICAgICAgICAgIC8vIG5hdmlnYXRpb24uXG4gICAgICAgICAgICBjb25zdCBjdXJyZW50TmF2aWdhdGlvbklkID0gcm91dGVyLmdldEN1cnJlbnROYXZpZ2F0aW9uKCk/LmlkO1xuICAgICAgICAgICAgY29uc3QgbmV3U3RhdGVOYXZpZ2F0aW9uSWQgPSBuZXdTdGF0ZT8ubmF2aWdhdGlvbklkO1xuICAgICAgICAgICAgaWYgKG5ld1N0YXRlTmF2aWdhdGlvbklkICE9PSB1bmRlZmluZWQgJiZcbiAgICAgICAgICAgICAgICBuZXdTdGF0ZU5hdmlnYXRpb25JZCA9PT0gY3VycmVudE5hdmlnYXRpb25JZCkge1xuICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGxldCB1cmw7XG4gICAgICAgICAgICBpZiAodXJsVHlwZSA9PT0gJ3BhdGgnKSB7XG4gICAgICAgICAgICAgIHVybCA9IHJlc29sdmVVcmwobmV3VXJsKTtcbiAgICAgICAgICAgIH0gZWxzZSBpZiAodXJsVHlwZSA9PT0gJ2hhc2gnKSB7XG4gICAgICAgICAgICAgIC8vIFJlbW92ZSB0aGUgZmlyc3QgaGFzaCBmcm9tIHRoZSBVUkxcbiAgICAgICAgICAgICAgY29uc3QgaGFzaElkeCA9IG5ld1VybC5pbmRleE9mKCcjJyk7XG4gICAgICAgICAgICAgIHVybCA9IHJlc29sdmVVcmwobmV3VXJsLnN1YnN0cmluZygwLCBoYXNoSWR4KSArIG5ld1VybC5zdWJzdHJpbmcoaGFzaElkeCArIDEpKTtcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIHRocm93ICdJbnZhbGlkIFVSTFR5cGUgcGFzc2VkIHRvIHNldFVwTG9jYXRpb25TeW5jOiAnICsgdXJsVHlwZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGNvbnN0IHBhdGggPSBsb2NhdGlvbi5ub3JtYWxpemUodXJsLnBhdGhuYW1lKTtcbiAgICAgICAgICAgIHJvdXRlci5uYXZpZ2F0ZUJ5VXJsKHBhdGggKyB1cmwuc2VhcmNoICsgdXJsLmhhc2gpO1xuICAgICAgICAgIH0pO1xufVxuXG4vKipcbiAqIE5vcm1hbGl6ZXMgYW5kIHBhcnNlcyBhIFVSTC5cbiAqXG4gKiAtIE5vcm1hbGl6aW5nIG1lYW5zIHRoYXQgYSByZWxhdGl2ZSBVUkwgd2lsbCBiZSByZXNvbHZlZCBpbnRvIGFuIGFic29sdXRlIFVSTCBpbiB0aGUgY29udGV4dCBvZlxuICogICB0aGUgYXBwbGljYXRpb24gZG9jdW1lbnQuXG4gKiAtIFBhcnNpbmcgbWVhbnMgdGhhdCB0aGUgYW5jaG9yJ3MgYHByb3RvY29sYCwgYGhvc3RuYW1lYCwgYHBvcnRgLCBgcGF0aG5hbWVgIGFuZCByZWxhdGVkXG4gKiAgIHByb3BlcnRpZXMgYXJlIGFsbCBwb3B1bGF0ZWQgdG8gcmVmbGVjdCB0aGUgbm9ybWFsaXplZCBVUkwuXG4gKlxuICogV2hpbGUgdGhpcyBhcHByb2FjaCBoYXMgd2lkZSBjb21wYXRpYmlsaXR5LCBpdCBkb2Vzbid0IHdvcmsgYXMgZXhwZWN0ZWQgb24gSUUuIE9uIElFLCBub3JtYWxpemluZ1xuICogaGFwcGVucyBzaW1pbGFyIHRvIG90aGVyIGJyb3dzZXJzLCBidXQgdGhlIHBhcnNlZCBjb21wb25lbnRzIHdpbGwgbm90IGJlIHNldC4gKEUuZy4gaWYgeW91IGFzc2lnblxuICogYGEuaHJlZiA9ICdmb28nYCwgdGhlbiBgYS5wcm90b2NvbGAsIGBhLmhvc3RgLCBldGMuIHdpbGwgbm90IGJlIGNvcnJlY3RseSB1cGRhdGVkLilcbiAqIFdlIHdvcmsgYXJvdW5kIHRoYXQgYnkgcGVyZm9ybWluZyB0aGUgcGFyc2luZyBpbiBhIDJuZCBzdGVwIGJ5IHRha2luZyBhIHByZXZpb3VzbHkgbm9ybWFsaXplZCBVUkxcbiAqIGFuZCBhc3NpZ25pbmcgaXQgYWdhaW4uIFRoaXMgY29ycmVjdGx5IHBvcHVsYXRlcyBhbGwgcHJvcGVydGllcy5cbiAqXG4gKiBTZWVcbiAqIGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIuanMvYmxvYi8yYzc0MDBlN2QwN2IwZjZjZWMxODE3ZGFiNDBiOTI1MGNlOGViY2U2L3NyYy9uZy91cmxVdGlscy5qcyNMMjYtTDMzXG4gKiBmb3IgbW9yZSBpbmZvLlxuICovXG5sZXQgYW5jaG9yOiBIVE1MQW5jaG9yRWxlbWVudHx1bmRlZmluZWQ7XG5mdW5jdGlvbiByZXNvbHZlVXJsKHVybDogc3RyaW5nKToge3BhdGhuYW1lOiBzdHJpbmcsIHNlYXJjaDogc3RyaW5nLCBoYXNoOiBzdHJpbmd9IHtcbiAgaWYgKCFhbmNob3IpIHtcbiAgICBhbmNob3IgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdhJyk7XG4gIH1cblxuICBhbmNob3Iuc2V0QXR0cmlidXRlKCdocmVmJywgdXJsKTtcbiAgYW5jaG9yLnNldEF0dHJpYnV0ZSgnaHJlZicsIGFuY2hvci5ocmVmKTtcblxuICByZXR1cm4ge1xuICAgIC8vIElFIGRvZXMgbm90IHN0YXJ0IGBwYXRobmFtZWAgd2l0aCBgL2AgbGlrZSBvdGhlciBicm93c2Vycy5cbiAgICBwYXRobmFtZTogYC8ke2FuY2hvci5wYXRobmFtZS5yZXBsYWNlKC9eXFwvLywgJycpfWAsXG4gICAgc2VhcmNoOiBhbmNob3Iuc2VhcmNoLFxuICAgIGhhc2g6IGFuY2hvci5oYXNoXG4gIH07XG59XG4iXX0=