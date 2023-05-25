/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { InjectionToken } from './di/injection_token';
import { getDocument } from './render3/interfaces/document';
/**
 * A [DI token](guide/glossary#di-token "DI token definition") representing a string ID, used
 * primarily for prefixing application attributes and CSS styles when
 * {@link ViewEncapsulation#Emulated ViewEncapsulation.Emulated} is being used.
 *
 * The token is needed in cases when multiple applications are bootstrapped on a page
 * (for example, using `bootstrapApplication` calls). In this case, ensure that those applications
 * have different `APP_ID` value setup. For example:
 *
 * ```
 * bootstrapApplication(ComponentA, {
 *   providers: [
 *     { provide: APP_ID, useValue: 'app-a' },
 *     // ... other providers ...
 *   ]
 * });
 *
 * bootstrapApplication(ComponentB, {
 *   providers: [
 *     { provide: APP_ID, useValue: 'app-b' },
 *     // ... other providers ...
 *   ]
 * });
 * ```
 *
 * By default, when there is only one application bootstrapped, you don't need to provide the
 * `APP_ID` token (the `ng` will be used as an app ID).
 *
 * @publicApi
 */
export const APP_ID = new InjectionToken('AppId', {
    providedIn: 'root',
    factory: () => DEFAULT_APP_ID,
});
/** Default value of the `APP_ID` token. */
const DEFAULT_APP_ID = 'ng';
/**
 * A function that is executed when a platform is initialized.
 * @publicApi
 */
export const PLATFORM_INITIALIZER = new InjectionToken('Platform Initializer');
/**
 * A token that indicates an opaque platform ID.
 * @publicApi
 */
export const PLATFORM_ID = new InjectionToken('Platform ID', {
    providedIn: 'platform',
    factory: () => 'unknown', // set a default platform name, when none set explicitly
});
/**
 * A [DI token](guide/glossary#di-token "DI token definition") that indicates the root directory of
 * the application
 * @publicApi
 */
export const PACKAGE_ROOT_URL = new InjectionToken('Application Packages Root URL');
// We keep this token here, rather than the animations package, so that modules that only care
// about which animations module is loaded (e.g. the CDK) can retrieve it without having to
// include extra dependencies. See #44970 for more context.
/**
 * A [DI token](guide/glossary#di-token "DI token definition") that indicates which animations
 * module has been loaded.
 * @publicApi
 */
export const ANIMATION_MODULE_TYPE = new InjectionToken('AnimationModuleType');
// TODO(crisbeto): link to CSP guide here.
/**
 * Token used to configure the [Content Security Policy](https://web.dev/strict-csp/) nonce that
 * Angular will apply when inserting inline styles. If not provided, Angular will look up its value
 * from the `ngCspNonce` attribute of the application root node.
 *
 * @publicApi
 */
export const CSP_NONCE = new InjectionToken('CSP nonce', {
    providedIn: 'root',
    factory: () => {
        // Ideally we wouldn't have to use `querySelector` here since we know that the nonce will be on
        // the root node, but because the token value is used in renderers, it has to be available
        // *very* early in the bootstrapping process. This should be a fairly shallow search, because
        // the app won't have been added to the DOM yet. Some approaches that were considered:
        // 1. Find the root node through `ApplicationRef.components[i].location` - normally this would
        // be enough for our purposes, but the token is injected very early so the `components` array
        // isn't populated yet.
        // 2. Find the root `LView` through the current `LView` - renderers are a prerequisite to
        // creating the `LView`. This means that no `LView` will have been entered when this factory is
        // invoked for the root component.
        // 3. Have the token factory return `() => string` which is invoked when a nonce is requested -
        // the slightly later execution does allow us to get an `LView` reference, but the fact that
        // it is a function means that it could be executed at *any* time (including immediately) which
        // may lead to weird bugs.
        // 4. Have the `ComponentFactory` read the attribute and provide it to the injector under the
        // hood - has the same problem as #1 and #2 in that the renderer is used to query for the root
        // node and the nonce value needs to be available when the renderer is created.
        return getDocument().body?.querySelector('[ngCspNonce]')?.getAttribute('ngCspNonce') || null;
    },
});
/**
 * Internal token to collect all SSR-related features enabled for this application.
 *
 * Note: the token is in `core` to let other packages register features (the `core`
 * package is imported in other packages).
 */
export const ENABLED_SSR_FEATURES = new InjectionToken((typeof ngDevMode === 'undefined' || ngDevMode) ? 'ENABLED_SSR_FEATURES' : '', {
    providedIn: 'root',
    factory: () => new Set(),
});
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYXBwbGljYXRpb25fdG9rZW5zLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvYXBwbGljYXRpb25fdG9rZW5zLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxjQUFjLEVBQUMsTUFBTSxzQkFBc0IsQ0FBQztBQUNwRCxPQUFPLEVBQUMsV0FBVyxFQUFDLE1BQU0sK0JBQStCLENBQUM7QUFFMUQ7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBNkJHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sTUFBTSxHQUFHLElBQUksY0FBYyxDQUFTLE9BQU8sRUFBRTtJQUN4RCxVQUFVLEVBQUUsTUFBTTtJQUNsQixPQUFPLEVBQUUsR0FBRyxFQUFFLENBQUMsY0FBYztDQUM5QixDQUFDLENBQUM7QUFFSCwyQ0FBMkM7QUFDM0MsTUFBTSxjQUFjLEdBQUcsSUFBSSxDQUFDO0FBRTVCOzs7R0FHRztBQUNILE1BQU0sQ0FBQyxNQUFNLG9CQUFvQixHQUFHLElBQUksY0FBYyxDQUFvQixzQkFBc0IsQ0FBQyxDQUFDO0FBRWxHOzs7R0FHRztBQUNILE1BQU0sQ0FBQyxNQUFNLFdBQVcsR0FBRyxJQUFJLGNBQWMsQ0FBUyxhQUFhLEVBQUU7SUFDbkUsVUFBVSxFQUFFLFVBQVU7SUFDdEIsT0FBTyxFQUFFLEdBQUcsRUFBRSxDQUFDLFNBQVMsRUFBRyx3REFBd0Q7Q0FDcEYsQ0FBQyxDQUFDO0FBRUg7Ozs7R0FJRztBQUNILE1BQU0sQ0FBQyxNQUFNLGdCQUFnQixHQUFHLElBQUksY0FBYyxDQUFTLCtCQUErQixDQUFDLENBQUM7QUFFNUYsOEZBQThGO0FBQzlGLDJGQUEyRjtBQUMzRiwyREFBMkQ7QUFFM0Q7Ozs7R0FJRztBQUNILE1BQU0sQ0FBQyxNQUFNLHFCQUFxQixHQUM5QixJQUFJLGNBQWMsQ0FBdUMscUJBQXFCLENBQUMsQ0FBQztBQUVwRiwwQ0FBMEM7QUFDMUM7Ozs7OztHQU1HO0FBQ0gsTUFBTSxDQUFDLE1BQU0sU0FBUyxHQUFHLElBQUksY0FBYyxDQUFjLFdBQVcsRUFBRTtJQUNwRSxVQUFVLEVBQUUsTUFBTTtJQUNsQixPQUFPLEVBQUUsR0FBRyxFQUFFO1FBQ1osK0ZBQStGO1FBQy9GLDBGQUEwRjtRQUMxRiw2RkFBNkY7UUFDN0Ysc0ZBQXNGO1FBQ3RGLDhGQUE4RjtRQUM5Riw2RkFBNkY7UUFDN0YsdUJBQXVCO1FBQ3ZCLHlGQUF5RjtRQUN6RiwrRkFBK0Y7UUFDL0Ysa0NBQWtDO1FBQ2xDLCtGQUErRjtRQUMvRiw0RkFBNEY7UUFDNUYsK0ZBQStGO1FBQy9GLDBCQUEwQjtRQUMxQiw2RkFBNkY7UUFDN0YsOEZBQThGO1FBQzlGLCtFQUErRTtRQUMvRSxPQUFPLFdBQVcsRUFBRSxDQUFDLElBQUksRUFBRSxhQUFhLENBQUMsY0FBYyxDQUFDLEVBQUUsWUFBWSxDQUFDLFlBQVksQ0FBQyxJQUFJLElBQUksQ0FBQztJQUMvRixDQUFDO0NBQ0YsQ0FBQyxDQUFDO0FBRUg7Ozs7O0dBS0c7QUFDSCxNQUFNLENBQUMsTUFBTSxvQkFBb0IsR0FBRyxJQUFJLGNBQWMsQ0FDbEQsQ0FBQyxPQUFPLFNBQVMsS0FBSyxXQUFXLElBQUksU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLHNCQUFzQixDQUFDLENBQUMsQ0FBQyxFQUFFLEVBQUU7SUFDN0UsVUFBVSxFQUFFLE1BQU07SUFDbEIsT0FBTyxFQUFFLEdBQUcsRUFBRSxDQUFDLElBQUksR0FBRyxFQUFFO0NBQ3pCLENBQUMsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0luamVjdGlvblRva2VufSBmcm9tICcuL2RpL2luamVjdGlvbl90b2tlbic7XG5pbXBvcnQge2dldERvY3VtZW50fSBmcm9tICcuL3JlbmRlcjMvaW50ZXJmYWNlcy9kb2N1bWVudCc7XG5cbi8qKlxuICogQSBbREkgdG9rZW5dKGd1aWRlL2dsb3NzYXJ5I2RpLXRva2VuIFwiREkgdG9rZW4gZGVmaW5pdGlvblwiKSByZXByZXNlbnRpbmcgYSBzdHJpbmcgSUQsIHVzZWRcbiAqIHByaW1hcmlseSBmb3IgcHJlZml4aW5nIGFwcGxpY2F0aW9uIGF0dHJpYnV0ZXMgYW5kIENTUyBzdHlsZXMgd2hlblxuICoge0BsaW5rIFZpZXdFbmNhcHN1bGF0aW9uI0VtdWxhdGVkIFZpZXdFbmNhcHN1bGF0aW9uLkVtdWxhdGVkfSBpcyBiZWluZyB1c2VkLlxuICpcbiAqIFRoZSB0b2tlbiBpcyBuZWVkZWQgaW4gY2FzZXMgd2hlbiBtdWx0aXBsZSBhcHBsaWNhdGlvbnMgYXJlIGJvb3RzdHJhcHBlZCBvbiBhIHBhZ2VcbiAqIChmb3IgZXhhbXBsZSwgdXNpbmcgYGJvb3RzdHJhcEFwcGxpY2F0aW9uYCBjYWxscykuIEluIHRoaXMgY2FzZSwgZW5zdXJlIHRoYXQgdGhvc2UgYXBwbGljYXRpb25zXG4gKiBoYXZlIGRpZmZlcmVudCBgQVBQX0lEYCB2YWx1ZSBzZXR1cC4gRm9yIGV4YW1wbGU6XG4gKlxuICogYGBgXG4gKiBib290c3RyYXBBcHBsaWNhdGlvbihDb21wb25lbnRBLCB7XG4gKiAgIHByb3ZpZGVyczogW1xuICogICAgIHsgcHJvdmlkZTogQVBQX0lELCB1c2VWYWx1ZTogJ2FwcC1hJyB9LFxuICogICAgIC8vIC4uLiBvdGhlciBwcm92aWRlcnMgLi4uXG4gKiAgIF1cbiAqIH0pO1xuICpcbiAqIGJvb3RzdHJhcEFwcGxpY2F0aW9uKENvbXBvbmVudEIsIHtcbiAqICAgcHJvdmlkZXJzOiBbXG4gKiAgICAgeyBwcm92aWRlOiBBUFBfSUQsIHVzZVZhbHVlOiAnYXBwLWInIH0sXG4gKiAgICAgLy8gLi4uIG90aGVyIHByb3ZpZGVycyAuLi5cbiAqICAgXVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBCeSBkZWZhdWx0LCB3aGVuIHRoZXJlIGlzIG9ubHkgb25lIGFwcGxpY2F0aW9uIGJvb3RzdHJhcHBlZCwgeW91IGRvbid0IG5lZWQgdG8gcHJvdmlkZSB0aGVcbiAqIGBBUFBfSURgIHRva2VuICh0aGUgYG5nYCB3aWxsIGJlIHVzZWQgYXMgYW4gYXBwIElEKS5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBBUFBfSUQgPSBuZXcgSW5qZWN0aW9uVG9rZW48c3RyaW5nPignQXBwSWQnLCB7XG4gIHByb3ZpZGVkSW46ICdyb290JyxcbiAgZmFjdG9yeTogKCkgPT4gREVGQVVMVF9BUFBfSUQsXG59KTtcblxuLyoqIERlZmF1bHQgdmFsdWUgb2YgdGhlIGBBUFBfSURgIHRva2VuLiAqL1xuY29uc3QgREVGQVVMVF9BUFBfSUQgPSAnbmcnO1xuXG4vKipcbiAqIEEgZnVuY3Rpb24gdGhhdCBpcyBleGVjdXRlZCB3aGVuIGEgcGxhdGZvcm0gaXMgaW5pdGlhbGl6ZWQuXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBQTEFURk9STV9JTklUSUFMSVpFUiA9IG5ldyBJbmplY3Rpb25Ub2tlbjxBcnJheTwoKSA9PiB2b2lkPj4oJ1BsYXRmb3JtIEluaXRpYWxpemVyJyk7XG5cbi8qKlxuICogQSB0b2tlbiB0aGF0IGluZGljYXRlcyBhbiBvcGFxdWUgcGxhdGZvcm0gSUQuXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBQTEFURk9STV9JRCA9IG5ldyBJbmplY3Rpb25Ub2tlbjxPYmplY3Q+KCdQbGF0Zm9ybSBJRCcsIHtcbiAgcHJvdmlkZWRJbjogJ3BsYXRmb3JtJyxcbiAgZmFjdG9yeTogKCkgPT4gJ3Vua25vd24nLCAgLy8gc2V0IGEgZGVmYXVsdCBwbGF0Zm9ybSBuYW1lLCB3aGVuIG5vbmUgc2V0IGV4cGxpY2l0bHlcbn0pO1xuXG4vKipcbiAqIEEgW0RJIHRva2VuXShndWlkZS9nbG9zc2FyeSNkaS10b2tlbiBcIkRJIHRva2VuIGRlZmluaXRpb25cIikgdGhhdCBpbmRpY2F0ZXMgdGhlIHJvb3QgZGlyZWN0b3J5IG9mXG4gKiB0aGUgYXBwbGljYXRpb25cbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGNvbnN0IFBBQ0tBR0VfUk9PVF9VUkwgPSBuZXcgSW5qZWN0aW9uVG9rZW48c3RyaW5nPignQXBwbGljYXRpb24gUGFja2FnZXMgUm9vdCBVUkwnKTtcblxuLy8gV2Uga2VlcCB0aGlzIHRva2VuIGhlcmUsIHJhdGhlciB0aGFuIHRoZSBhbmltYXRpb25zIHBhY2thZ2UsIHNvIHRoYXQgbW9kdWxlcyB0aGF0IG9ubHkgY2FyZVxuLy8gYWJvdXQgd2hpY2ggYW5pbWF0aW9ucyBtb2R1bGUgaXMgbG9hZGVkIChlLmcuIHRoZSBDREspIGNhbiByZXRyaWV2ZSBpdCB3aXRob3V0IGhhdmluZyB0b1xuLy8gaW5jbHVkZSBleHRyYSBkZXBlbmRlbmNpZXMuIFNlZSAjNDQ5NzAgZm9yIG1vcmUgY29udGV4dC5cblxuLyoqXG4gKiBBIFtESSB0b2tlbl0oZ3VpZGUvZ2xvc3NhcnkjZGktdG9rZW4gXCJESSB0b2tlbiBkZWZpbml0aW9uXCIpIHRoYXQgaW5kaWNhdGVzIHdoaWNoIGFuaW1hdGlvbnNcbiAqIG1vZHVsZSBoYXMgYmVlbiBsb2FkZWQuXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBBTklNQVRJT05fTU9EVUxFX1RZUEUgPVxuICAgIG5ldyBJbmplY3Rpb25Ub2tlbjwnTm9vcEFuaW1hdGlvbnMnfCdCcm93c2VyQW5pbWF0aW9ucyc+KCdBbmltYXRpb25Nb2R1bGVUeXBlJyk7XG5cbi8vIFRPRE8oY3Jpc2JldG8pOiBsaW5rIHRvIENTUCBndWlkZSBoZXJlLlxuLyoqXG4gKiBUb2tlbiB1c2VkIHRvIGNvbmZpZ3VyZSB0aGUgW0NvbnRlbnQgU2VjdXJpdHkgUG9saWN5XShodHRwczovL3dlYi5kZXYvc3RyaWN0LWNzcC8pIG5vbmNlIHRoYXRcbiAqIEFuZ3VsYXIgd2lsbCBhcHBseSB3aGVuIGluc2VydGluZyBpbmxpbmUgc3R5bGVzLiBJZiBub3QgcHJvdmlkZWQsIEFuZ3VsYXIgd2lsbCBsb29rIHVwIGl0cyB2YWx1ZVxuICogZnJvbSB0aGUgYG5nQ3NwTm9uY2VgIGF0dHJpYnV0ZSBvZiB0aGUgYXBwbGljYXRpb24gcm9vdCBub2RlLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGNvbnN0IENTUF9OT05DRSA9IG5ldyBJbmplY3Rpb25Ub2tlbjxzdHJpbmd8bnVsbD4oJ0NTUCBub25jZScsIHtcbiAgcHJvdmlkZWRJbjogJ3Jvb3QnLFxuICBmYWN0b3J5OiAoKSA9PiB7XG4gICAgLy8gSWRlYWxseSB3ZSB3b3VsZG4ndCBoYXZlIHRvIHVzZSBgcXVlcnlTZWxlY3RvcmAgaGVyZSBzaW5jZSB3ZSBrbm93IHRoYXQgdGhlIG5vbmNlIHdpbGwgYmUgb25cbiAgICAvLyB0aGUgcm9vdCBub2RlLCBidXQgYmVjYXVzZSB0aGUgdG9rZW4gdmFsdWUgaXMgdXNlZCBpbiByZW5kZXJlcnMsIGl0IGhhcyB0byBiZSBhdmFpbGFibGVcbiAgICAvLyAqdmVyeSogZWFybHkgaW4gdGhlIGJvb3RzdHJhcHBpbmcgcHJvY2Vzcy4gVGhpcyBzaG91bGQgYmUgYSBmYWlybHkgc2hhbGxvdyBzZWFyY2gsIGJlY2F1c2VcbiAgICAvLyB0aGUgYXBwIHdvbid0IGhhdmUgYmVlbiBhZGRlZCB0byB0aGUgRE9NIHlldC4gU29tZSBhcHByb2FjaGVzIHRoYXQgd2VyZSBjb25zaWRlcmVkOlxuICAgIC8vIDEuIEZpbmQgdGhlIHJvb3Qgbm9kZSB0aHJvdWdoIGBBcHBsaWNhdGlvblJlZi5jb21wb25lbnRzW2ldLmxvY2F0aW9uYCAtIG5vcm1hbGx5IHRoaXMgd291bGRcbiAgICAvLyBiZSBlbm91Z2ggZm9yIG91ciBwdXJwb3NlcywgYnV0IHRoZSB0b2tlbiBpcyBpbmplY3RlZCB2ZXJ5IGVhcmx5IHNvIHRoZSBgY29tcG9uZW50c2AgYXJyYXlcbiAgICAvLyBpc24ndCBwb3B1bGF0ZWQgeWV0LlxuICAgIC8vIDIuIEZpbmQgdGhlIHJvb3QgYExWaWV3YCB0aHJvdWdoIHRoZSBjdXJyZW50IGBMVmlld2AgLSByZW5kZXJlcnMgYXJlIGEgcHJlcmVxdWlzaXRlIHRvXG4gICAgLy8gY3JlYXRpbmcgdGhlIGBMVmlld2AuIFRoaXMgbWVhbnMgdGhhdCBubyBgTFZpZXdgIHdpbGwgaGF2ZSBiZWVuIGVudGVyZWQgd2hlbiB0aGlzIGZhY3RvcnkgaXNcbiAgICAvLyBpbnZva2VkIGZvciB0aGUgcm9vdCBjb21wb25lbnQuXG4gICAgLy8gMy4gSGF2ZSB0aGUgdG9rZW4gZmFjdG9yeSByZXR1cm4gYCgpID0+IHN0cmluZ2Agd2hpY2ggaXMgaW52b2tlZCB3aGVuIGEgbm9uY2UgaXMgcmVxdWVzdGVkIC1cbiAgICAvLyB0aGUgc2xpZ2h0bHkgbGF0ZXIgZXhlY3V0aW9uIGRvZXMgYWxsb3cgdXMgdG8gZ2V0IGFuIGBMVmlld2AgcmVmZXJlbmNlLCBidXQgdGhlIGZhY3QgdGhhdFxuICAgIC8vIGl0IGlzIGEgZnVuY3Rpb24gbWVhbnMgdGhhdCBpdCBjb3VsZCBiZSBleGVjdXRlZCBhdCAqYW55KiB0aW1lIChpbmNsdWRpbmcgaW1tZWRpYXRlbHkpIHdoaWNoXG4gICAgLy8gbWF5IGxlYWQgdG8gd2VpcmQgYnVncy5cbiAgICAvLyA0LiBIYXZlIHRoZSBgQ29tcG9uZW50RmFjdG9yeWAgcmVhZCB0aGUgYXR0cmlidXRlIGFuZCBwcm92aWRlIGl0IHRvIHRoZSBpbmplY3RvciB1bmRlciB0aGVcbiAgICAvLyBob29kIC0gaGFzIHRoZSBzYW1lIHByb2JsZW0gYXMgIzEgYW5kICMyIGluIHRoYXQgdGhlIHJlbmRlcmVyIGlzIHVzZWQgdG8gcXVlcnkgZm9yIHRoZSByb290XG4gICAgLy8gbm9kZSBhbmQgdGhlIG5vbmNlIHZhbHVlIG5lZWRzIHRvIGJlIGF2YWlsYWJsZSB3aGVuIHRoZSByZW5kZXJlciBpcyBjcmVhdGVkLlxuICAgIHJldHVybiBnZXREb2N1bWVudCgpLmJvZHk/LnF1ZXJ5U2VsZWN0b3IoJ1tuZ0NzcE5vbmNlXScpPy5nZXRBdHRyaWJ1dGUoJ25nQ3NwTm9uY2UnKSB8fCBudWxsO1xuICB9LFxufSk7XG5cbi8qKlxuICogSW50ZXJuYWwgdG9rZW4gdG8gY29sbGVjdCBhbGwgU1NSLXJlbGF0ZWQgZmVhdHVyZXMgZW5hYmxlZCBmb3IgdGhpcyBhcHBsaWNhdGlvbi5cbiAqXG4gKiBOb3RlOiB0aGUgdG9rZW4gaXMgaW4gYGNvcmVgIHRvIGxldCBvdGhlciBwYWNrYWdlcyByZWdpc3RlciBmZWF0dXJlcyAodGhlIGBjb3JlYFxuICogcGFja2FnZSBpcyBpbXBvcnRlZCBpbiBvdGhlciBwYWNrYWdlcykuXG4gKi9cbmV4cG9ydCBjb25zdCBFTkFCTEVEX1NTUl9GRUFUVVJFUyA9IG5ldyBJbmplY3Rpb25Ub2tlbjxTZXQ8c3RyaW5nPj4oXG4gICAgKHR5cGVvZiBuZ0Rldk1vZGUgPT09ICd1bmRlZmluZWQnIHx8IG5nRGV2TW9kZSkgPyAnRU5BQkxFRF9TU1JfRkVBVFVSRVMnIDogJycsIHtcbiAgICAgIHByb3ZpZGVkSW46ICdyb290JyxcbiAgICAgIGZhY3Rvcnk6ICgpID0+IG5ldyBTZXQoKSxcbiAgICB9KTtcbiJdfQ==