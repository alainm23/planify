/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertDefined } from '../../util/assert';
import { global } from '../../util/global';
import { setProfiler } from '../profiler';
import { applyChanges } from './change_detection_utils';
import { getComponent, getContext, getDirectiveMetadata, getDirectives, getHostElement, getInjector, getListeners, getOwningComponent, getRootComponents } from './discovery_utils';
/**
 * This file introduces series of globally accessible debug tools
 * to allow for the Angular debugging story to function.
 *
 * To see this in action run the following command:
 *
 *   bazel run //packages/core/test/bundling/todo:devserver
 *
 *  Then load `localhost:5432` and start using the console tools.
 */
/**
 * This value reflects the property on the window where the dev
 * tools are patched (window.ng).
 * */
export const GLOBAL_PUBLISH_EXPANDO_KEY = 'ng';
let _published = false;
/**
 * Publishes a collection of default debug tools onto`window.ng`.
 *
 * These functions are available globally when Angular is in development
 * mode and are automatically stripped away from prod mode is on.
 */
export function publishDefaultGlobalUtils() {
    if (!_published) {
        _published = true;
        /**
         * Warning: this function is *INTERNAL* and should not be relied upon in application's code.
         * The contract of the function might be changed in any release and/or the function can be
         * removed completely.
         */
        publishGlobalUtil('ɵsetProfiler', setProfiler);
        publishGlobalUtil('getDirectiveMetadata', getDirectiveMetadata);
        publishGlobalUtil('getComponent', getComponent);
        publishGlobalUtil('getContext', getContext);
        publishGlobalUtil('getListeners', getListeners);
        publishGlobalUtil('getOwningComponent', getOwningComponent);
        publishGlobalUtil('getHostElement', getHostElement);
        publishGlobalUtil('getInjector', getInjector);
        publishGlobalUtil('getRootComponents', getRootComponents);
        publishGlobalUtil('getDirectives', getDirectives);
        publishGlobalUtil('applyChanges', applyChanges);
    }
}
/**
 * Publishes the given function to `window.ng` so that it can be
 * used from the browser console when an application is not in production.
 */
export function publishGlobalUtil(name, fn) {
    if (typeof COMPILED === 'undefined' || !COMPILED) {
        // Note: we can't export `ng` when using closure enhanced optimization as:
        // - closure declares globals itself for minified names, which sometimes clobber our `ng` global
        // - we can't declare a closure extern as the namespace `ng` is already used within Google
        //   for typings for AngularJS (via `goog.provide('ng....')`).
        const w = global;
        ngDevMode && assertDefined(fn, 'function not defined');
        if (w) {
            let container = w[GLOBAL_PUBLISH_EXPANDO_KEY];
            if (!container) {
                container = w[GLOBAL_PUBLISH_EXPANDO_KEY] = {};
            }
            container[name] = fn;
        }
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZ2xvYmFsX3V0aWxzLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy91dGlsL2dsb2JhbF91dGlscy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFDSCxPQUFPLEVBQUMsYUFBYSxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDaEQsT0FBTyxFQUFDLE1BQU0sRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBQ3pDLE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSxhQUFhLENBQUM7QUFDeEMsT0FBTyxFQUFDLFlBQVksRUFBQyxNQUFNLDBCQUEwQixDQUFDO0FBQ3RELE9BQU8sRUFBQyxZQUFZLEVBQUUsVUFBVSxFQUFFLG9CQUFvQixFQUFFLGFBQWEsRUFBRSxjQUFjLEVBQUUsV0FBVyxFQUFFLFlBQVksRUFBRSxrQkFBa0IsRUFBRSxpQkFBaUIsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBSWxMOzs7Ozs7Ozs7R0FTRztBQUVIOzs7S0FHSztBQUNMLE1BQU0sQ0FBQyxNQUFNLDBCQUEwQixHQUFHLElBQUksQ0FBQztBQUUvQyxJQUFJLFVBQVUsR0FBRyxLQUFLLENBQUM7QUFDdkI7Ozs7O0dBS0c7QUFDSCxNQUFNLFVBQVUseUJBQXlCO0lBQ3ZDLElBQUksQ0FBQyxVQUFVLEVBQUU7UUFDZixVQUFVLEdBQUcsSUFBSSxDQUFDO1FBRWxCOzs7O1dBSUc7UUFDSCxpQkFBaUIsQ0FBQyxjQUFjLEVBQUUsV0FBVyxDQUFDLENBQUM7UUFDL0MsaUJBQWlCLENBQUMsc0JBQXNCLEVBQUUsb0JBQW9CLENBQUMsQ0FBQztRQUNoRSxpQkFBaUIsQ0FBQyxjQUFjLEVBQUUsWUFBWSxDQUFDLENBQUM7UUFDaEQsaUJBQWlCLENBQUMsWUFBWSxFQUFFLFVBQVUsQ0FBQyxDQUFDO1FBQzVDLGlCQUFpQixDQUFDLGNBQWMsRUFBRSxZQUFZLENBQUMsQ0FBQztRQUNoRCxpQkFBaUIsQ0FBQyxvQkFBb0IsRUFBRSxrQkFBa0IsQ0FBQyxDQUFDO1FBQzVELGlCQUFpQixDQUFDLGdCQUFnQixFQUFFLGNBQWMsQ0FBQyxDQUFDO1FBQ3BELGlCQUFpQixDQUFDLGFBQWEsRUFBRSxXQUFXLENBQUMsQ0FBQztRQUM5QyxpQkFBaUIsQ0FBQyxtQkFBbUIsRUFBRSxpQkFBaUIsQ0FBQyxDQUFDO1FBQzFELGlCQUFpQixDQUFDLGVBQWUsRUFBRSxhQUFhLENBQUMsQ0FBQztRQUNsRCxpQkFBaUIsQ0FBQyxjQUFjLEVBQUUsWUFBWSxDQUFDLENBQUM7S0FDakQ7QUFDSCxDQUFDO0FBTUQ7OztHQUdHO0FBQ0gsTUFBTSxVQUFVLGlCQUFpQixDQUFDLElBQVksRUFBRSxFQUFZO0lBQzFELElBQUksT0FBTyxRQUFRLEtBQUssV0FBVyxJQUFJLENBQUMsUUFBUSxFQUFFO1FBQ2hELDBFQUEwRTtRQUMxRSxnR0FBZ0c7UUFDaEcsMEZBQTBGO1FBQzFGLDhEQUE4RDtRQUM5RCxNQUFNLENBQUMsR0FBRyxNQUF1QyxDQUFDO1FBQ2xELFNBQVMsSUFBSSxhQUFhLENBQUMsRUFBRSxFQUFFLHNCQUFzQixDQUFDLENBQUM7UUFDdkQsSUFBSSxDQUFDLEVBQUU7WUFDTCxJQUFJLFNBQVMsR0FBRyxDQUFDLENBQUMsMEJBQTBCLENBQUMsQ0FBQztZQUM5QyxJQUFJLENBQUMsU0FBUyxFQUFFO2dCQUNkLFNBQVMsR0FBRyxDQUFDLENBQUMsMEJBQTBCLENBQUMsR0FBRyxFQUFFLENBQUM7YUFDaEQ7WUFDRCxTQUFTLENBQUMsSUFBSSxDQUFDLEdBQUcsRUFBRSxDQUFDO1NBQ3RCO0tBQ0Y7QUFDSCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5pbXBvcnQge2Fzc2VydERlZmluZWR9IGZyb20gJy4uLy4uL3V0aWwvYXNzZXJ0JztcbmltcG9ydCB7Z2xvYmFsfSBmcm9tICcuLi8uLi91dGlsL2dsb2JhbCc7XG5pbXBvcnQge3NldFByb2ZpbGVyfSBmcm9tICcuLi9wcm9maWxlcic7XG5pbXBvcnQge2FwcGx5Q2hhbmdlc30gZnJvbSAnLi9jaGFuZ2VfZGV0ZWN0aW9uX3V0aWxzJztcbmltcG9ydCB7Z2V0Q29tcG9uZW50LCBnZXRDb250ZXh0LCBnZXREaXJlY3RpdmVNZXRhZGF0YSwgZ2V0RGlyZWN0aXZlcywgZ2V0SG9zdEVsZW1lbnQsIGdldEluamVjdG9yLCBnZXRMaXN0ZW5lcnMsIGdldE93bmluZ0NvbXBvbmVudCwgZ2V0Um9vdENvbXBvbmVudHN9IGZyb20gJy4vZGlzY292ZXJ5X3V0aWxzJztcblxuXG5cbi8qKlxuICogVGhpcyBmaWxlIGludHJvZHVjZXMgc2VyaWVzIG9mIGdsb2JhbGx5IGFjY2Vzc2libGUgZGVidWcgdG9vbHNcbiAqIHRvIGFsbG93IGZvciB0aGUgQW5ndWxhciBkZWJ1Z2dpbmcgc3RvcnkgdG8gZnVuY3Rpb24uXG4gKlxuICogVG8gc2VlIHRoaXMgaW4gYWN0aW9uIHJ1biB0aGUgZm9sbG93aW5nIGNvbW1hbmQ6XG4gKlxuICogICBiYXplbCBydW4gLy9wYWNrYWdlcy9jb3JlL3Rlc3QvYnVuZGxpbmcvdG9kbzpkZXZzZXJ2ZXJcbiAqXG4gKiAgVGhlbiBsb2FkIGBsb2NhbGhvc3Q6NTQzMmAgYW5kIHN0YXJ0IHVzaW5nIHRoZSBjb25zb2xlIHRvb2xzLlxuICovXG5cbi8qKlxuICogVGhpcyB2YWx1ZSByZWZsZWN0cyB0aGUgcHJvcGVydHkgb24gdGhlIHdpbmRvdyB3aGVyZSB0aGUgZGV2XG4gKiB0b29scyBhcmUgcGF0Y2hlZCAod2luZG93Lm5nKS5cbiAqICovXG5leHBvcnQgY29uc3QgR0xPQkFMX1BVQkxJU0hfRVhQQU5ET19LRVkgPSAnbmcnO1xuXG5sZXQgX3B1Ymxpc2hlZCA9IGZhbHNlO1xuLyoqXG4gKiBQdWJsaXNoZXMgYSBjb2xsZWN0aW9uIG9mIGRlZmF1bHQgZGVidWcgdG9vbHMgb250b2B3aW5kb3cubmdgLlxuICpcbiAqIFRoZXNlIGZ1bmN0aW9ucyBhcmUgYXZhaWxhYmxlIGdsb2JhbGx5IHdoZW4gQW5ndWxhciBpcyBpbiBkZXZlbG9wbWVudFxuICogbW9kZSBhbmQgYXJlIGF1dG9tYXRpY2FsbHkgc3RyaXBwZWQgYXdheSBmcm9tIHByb2QgbW9kZSBpcyBvbi5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHB1Ymxpc2hEZWZhdWx0R2xvYmFsVXRpbHMoKSB7XG4gIGlmICghX3B1Ymxpc2hlZCkge1xuICAgIF9wdWJsaXNoZWQgPSB0cnVlO1xuXG4gICAgLyoqXG4gICAgICogV2FybmluZzogdGhpcyBmdW5jdGlvbiBpcyAqSU5URVJOQUwqIGFuZCBzaG91bGQgbm90IGJlIHJlbGllZCB1cG9uIGluIGFwcGxpY2F0aW9uJ3MgY29kZS5cbiAgICAgKiBUaGUgY29udHJhY3Qgb2YgdGhlIGZ1bmN0aW9uIG1pZ2h0IGJlIGNoYW5nZWQgaW4gYW55IHJlbGVhc2UgYW5kL29yIHRoZSBmdW5jdGlvbiBjYW4gYmVcbiAgICAgKiByZW1vdmVkIGNvbXBsZXRlbHkuXG4gICAgICovXG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ8m1c2V0UHJvZmlsZXInLCBzZXRQcm9maWxlcik7XG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ2dldERpcmVjdGl2ZU1ldGFkYXRhJywgZ2V0RGlyZWN0aXZlTWV0YWRhdGEpO1xuICAgIHB1Ymxpc2hHbG9iYWxVdGlsKCdnZXRDb21wb25lbnQnLCBnZXRDb21wb25lbnQpO1xuICAgIHB1Ymxpc2hHbG9iYWxVdGlsKCdnZXRDb250ZXh0JywgZ2V0Q29udGV4dCk7XG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ2dldExpc3RlbmVycycsIGdldExpc3RlbmVycyk7XG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ2dldE93bmluZ0NvbXBvbmVudCcsIGdldE93bmluZ0NvbXBvbmVudCk7XG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ2dldEhvc3RFbGVtZW50JywgZ2V0SG9zdEVsZW1lbnQpO1xuICAgIHB1Ymxpc2hHbG9iYWxVdGlsKCdnZXRJbmplY3RvcicsIGdldEluamVjdG9yKTtcbiAgICBwdWJsaXNoR2xvYmFsVXRpbCgnZ2V0Um9vdENvbXBvbmVudHMnLCBnZXRSb290Q29tcG9uZW50cyk7XG4gICAgcHVibGlzaEdsb2JhbFV0aWwoJ2dldERpcmVjdGl2ZXMnLCBnZXREaXJlY3RpdmVzKTtcbiAgICBwdWJsaXNoR2xvYmFsVXRpbCgnYXBwbHlDaGFuZ2VzJywgYXBwbHlDaGFuZ2VzKTtcbiAgfVxufVxuXG5leHBvcnQgZGVjbGFyZSB0eXBlIEdsb2JhbERldk1vZGVDb250YWluZXIgPSB7XG4gIFtHTE9CQUxfUFVCTElTSF9FWFBBTkRPX0tFWV06IHtbZm5OYW1lOiBzdHJpbmddOiBGdW5jdGlvbn07XG59O1xuXG4vKipcbiAqIFB1Ymxpc2hlcyB0aGUgZ2l2ZW4gZnVuY3Rpb24gdG8gYHdpbmRvdy5uZ2Agc28gdGhhdCBpdCBjYW4gYmVcbiAqIHVzZWQgZnJvbSB0aGUgYnJvd3NlciBjb25zb2xlIHdoZW4gYW4gYXBwbGljYXRpb24gaXMgbm90IGluIHByb2R1Y3Rpb24uXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBwdWJsaXNoR2xvYmFsVXRpbChuYW1lOiBzdHJpbmcsIGZuOiBGdW5jdGlvbik6IHZvaWQge1xuICBpZiAodHlwZW9mIENPTVBJTEVEID09PSAndW5kZWZpbmVkJyB8fCAhQ09NUElMRUQpIHtcbiAgICAvLyBOb3RlOiB3ZSBjYW4ndCBleHBvcnQgYG5nYCB3aGVuIHVzaW5nIGNsb3N1cmUgZW5oYW5jZWQgb3B0aW1pemF0aW9uIGFzOlxuICAgIC8vIC0gY2xvc3VyZSBkZWNsYXJlcyBnbG9iYWxzIGl0c2VsZiBmb3IgbWluaWZpZWQgbmFtZXMsIHdoaWNoIHNvbWV0aW1lcyBjbG9iYmVyIG91ciBgbmdgIGdsb2JhbFxuICAgIC8vIC0gd2UgY2FuJ3QgZGVjbGFyZSBhIGNsb3N1cmUgZXh0ZXJuIGFzIHRoZSBuYW1lc3BhY2UgYG5nYCBpcyBhbHJlYWR5IHVzZWQgd2l0aGluIEdvb2dsZVxuICAgIC8vICAgZm9yIHR5cGluZ3MgZm9yIEFuZ3VsYXJKUyAodmlhIGBnb29nLnByb3ZpZGUoJ25nLi4uLicpYCkuXG4gICAgY29uc3QgdyA9IGdsb2JhbCBhcyBhbnkgYXMgR2xvYmFsRGV2TW9kZUNvbnRhaW5lcjtcbiAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZChmbiwgJ2Z1bmN0aW9uIG5vdCBkZWZpbmVkJyk7XG4gICAgaWYgKHcpIHtcbiAgICAgIGxldCBjb250YWluZXIgPSB3W0dMT0JBTF9QVUJMSVNIX0VYUEFORE9fS0VZXTtcbiAgICAgIGlmICghY29udGFpbmVyKSB7XG4gICAgICAgIGNvbnRhaW5lciA9IHdbR0xPQkFMX1BVQkxJU0hfRVhQQU5ET19LRVldID0ge307XG4gICAgICB9XG4gICAgICBjb250YWluZXJbbmFtZV0gPSBmbjtcbiAgICB9XG4gIH1cbn1cbiJdfQ==