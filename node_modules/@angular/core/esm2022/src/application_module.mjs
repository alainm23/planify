/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ApplicationRef } from './application_ref';
import { NgModule } from './metadata';
import * as i0 from "./r3_symbols";
import * as i1 from "./application_ref";
/**
 * Re-exported by `BrowserModule`, which is included automatically in the root
 * `AppModule` when you create a new app with the CLI `new` command. Eagerly injects
 * `ApplicationRef` to instantiate it.
 *
 * @publicApi
 */
class ApplicationModule {
    // Inject ApplicationRef to make it eager...
    constructor(appRef) { }
    static { this.ɵfac = function ApplicationModule_Factory(t) { return new (t || ApplicationModule)(i0.ɵɵinject(i1.ApplicationRef)); }; }
    static { this.ɵmod = /*@__PURE__*/ i0.ɵɵdefineNgModule({ type: ApplicationModule }); }
    static { this.ɵinj = /*@__PURE__*/ i0.ɵɵdefineInjector({}); }
}
export { ApplicationModule };
(function () { (typeof ngDevMode === "undefined" || ngDevMode) && i0.setClassMetadata(ApplicationModule, [{
        type: NgModule
    }], function () { return [{ type: i1.ApplicationRef }]; }, null); })();
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYXBwbGljYXRpb25fbW9kdWxlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvYXBwbGljYXRpb25fbW9kdWxlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxjQUFjLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUNqRCxPQUFPLEVBQUMsUUFBUSxFQUFDLE1BQU0sWUFBWSxDQUFDOzs7QUFFcEM7Ozs7OztHQU1HO0FBQ0gsTUFDYSxpQkFBaUI7SUFDNUIsNENBQTRDO0lBQzVDLFlBQVksTUFBc0IsSUFBRyxDQUFDO2tGQUYzQixpQkFBaUI7bUVBQWpCLGlCQUFpQjs7O1NBQWpCLGlCQUFpQjtzRkFBakIsaUJBQWlCO2NBRDdCLFFBQVEiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtBcHBsaWNhdGlvblJlZn0gZnJvbSAnLi9hcHBsaWNhdGlvbl9yZWYnO1xuaW1wb3J0IHtOZ01vZHVsZX0gZnJvbSAnLi9tZXRhZGF0YSc7XG5cbi8qKlxuICogUmUtZXhwb3J0ZWQgYnkgYEJyb3dzZXJNb2R1bGVgLCB3aGljaCBpcyBpbmNsdWRlZCBhdXRvbWF0aWNhbGx5IGluIHRoZSByb290XG4gKiBgQXBwTW9kdWxlYCB3aGVuIHlvdSBjcmVhdGUgYSBuZXcgYXBwIHdpdGggdGhlIENMSSBgbmV3YCBjb21tYW5kLiBFYWdlcmx5IGluamVjdHNcbiAqIGBBcHBsaWNhdGlvblJlZmAgdG8gaW5zdGFudGlhdGUgaXQuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5ATmdNb2R1bGUoKVxuZXhwb3J0IGNsYXNzIEFwcGxpY2F0aW9uTW9kdWxlIHtcbiAgLy8gSW5qZWN0IEFwcGxpY2F0aW9uUmVmIHRvIG1ha2UgaXQgZWFnZXIuLi5cbiAgY29uc3RydWN0b3IoYXBwUmVmOiBBcHBsaWNhdGlvblJlZikge31cbn1cbiJdfQ==