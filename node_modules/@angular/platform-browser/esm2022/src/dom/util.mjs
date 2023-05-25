/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵglobal as global } from '@angular/core';
/**
 * Exports the value under a given `name` in the global property `ng`. For example `ng.probe` if
 * `name` is `'probe'`.
 * @param name Name under which it will be exported. Keep in mind this will be a property of the
 * global `ng` object.
 * @param value The value to export.
 */
export function exportNgVar(name, value) {
    if (typeof COMPILED === 'undefined' || !COMPILED) {
        // Note: we can't export `ng` when using closure enhanced optimization as:
        // - closure declares globals itself for minified names, which sometimes clobber our `ng` global
        // - we can't declare a closure extern as the namespace `ng` is already used within Google
        //   for typings for angularJS (via `goog.provide('ng....')`).
        const ng = global['ng'] = global['ng'] || {};
        ng[name] = value;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidXRpbC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL3BsYXRmb3JtLWJyb3dzZXIvc3JjL2RvbS91dGlsLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxPQUFPLElBQUksTUFBTSxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBRWhEOzs7Ozs7R0FNRztBQUNILE1BQU0sVUFBVSxXQUFXLENBQUMsSUFBWSxFQUFFLEtBQVU7SUFDbEQsSUFBSSxPQUFPLFFBQVEsS0FBSyxXQUFXLElBQUksQ0FBQyxRQUFRLEVBQUU7UUFDaEQsMEVBQTBFO1FBQzFFLGdHQUFnRztRQUNoRywwRkFBMEY7UUFDMUYsOERBQThEO1FBQzlELE1BQU0sRUFBRSxHQUFHLE1BQU0sQ0FBQyxJQUFJLENBQUMsR0FBSSxNQUFNLENBQUMsSUFBSSxDQUFzQyxJQUFJLEVBQUUsQ0FBQztRQUNuRixFQUFFLENBQUMsSUFBSSxDQUFDLEdBQUcsS0FBSyxDQUFDO0tBQ2xCO0FBQ0gsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge8m1Z2xvYmFsIGFzIGdsb2JhbH0gZnJvbSAnQGFuZ3VsYXIvY29yZSc7XG5cbi8qKlxuICogRXhwb3J0cyB0aGUgdmFsdWUgdW5kZXIgYSBnaXZlbiBgbmFtZWAgaW4gdGhlIGdsb2JhbCBwcm9wZXJ0eSBgbmdgLiBGb3IgZXhhbXBsZSBgbmcucHJvYmVgIGlmXG4gKiBgbmFtZWAgaXMgYCdwcm9iZSdgLlxuICogQHBhcmFtIG5hbWUgTmFtZSB1bmRlciB3aGljaCBpdCB3aWxsIGJlIGV4cG9ydGVkLiBLZWVwIGluIG1pbmQgdGhpcyB3aWxsIGJlIGEgcHJvcGVydHkgb2YgdGhlXG4gKiBnbG9iYWwgYG5nYCBvYmplY3QuXG4gKiBAcGFyYW0gdmFsdWUgVGhlIHZhbHVlIHRvIGV4cG9ydC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGV4cG9ydE5nVmFyKG5hbWU6IHN0cmluZywgdmFsdWU6IGFueSk6IHZvaWQge1xuICBpZiAodHlwZW9mIENPTVBJTEVEID09PSAndW5kZWZpbmVkJyB8fCAhQ09NUElMRUQpIHtcbiAgICAvLyBOb3RlOiB3ZSBjYW4ndCBleHBvcnQgYG5nYCB3aGVuIHVzaW5nIGNsb3N1cmUgZW5oYW5jZWQgb3B0aW1pemF0aW9uIGFzOlxuICAgIC8vIC0gY2xvc3VyZSBkZWNsYXJlcyBnbG9iYWxzIGl0c2VsZiBmb3IgbWluaWZpZWQgbmFtZXMsIHdoaWNoIHNvbWV0aW1lcyBjbG9iYmVyIG91ciBgbmdgIGdsb2JhbFxuICAgIC8vIC0gd2UgY2FuJ3QgZGVjbGFyZSBhIGNsb3N1cmUgZXh0ZXJuIGFzIHRoZSBuYW1lc3BhY2UgYG5nYCBpcyBhbHJlYWR5IHVzZWQgd2l0aGluIEdvb2dsZVxuICAgIC8vICAgZm9yIHR5cGluZ3MgZm9yIGFuZ3VsYXJKUyAodmlhIGBnb29nLnByb3ZpZGUoJ25nLi4uLicpYCkuXG4gICAgY29uc3QgbmcgPSBnbG9iYWxbJ25nJ10gPSAoZ2xvYmFsWyduZyddIGFzIHtba2V5OiBzdHJpbmddOiBhbnl9IHwgdW5kZWZpbmVkKSB8fCB7fTtcbiAgICBuZ1tuYW1lXSA9IHZhbHVlO1xuICB9XG59XG4iXX0=