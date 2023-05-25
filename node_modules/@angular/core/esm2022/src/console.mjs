/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { Injectable } from './di';
import * as i0 from "./r3_symbols";
class Console {
    log(message) {
        // tslint:disable-next-line:no-console
        console.log(message);
    }
    // Note: for reporting errors use `DOM.logError()` as it is platform specific
    warn(message) {
        // tslint:disable-next-line:no-console
        console.warn(message);
    }
    static { this.ɵfac = function Console_Factory(t) { return new (t || Console)(); }; }
    static { this.ɵprov = /*@__PURE__*/ i0.ɵɵdefineInjectable({ token: Console, factory: Console.ɵfac, providedIn: 'platform' }); }
}
export { Console };
(function () { (typeof ngDevMode === "undefined" || ngDevMode) && i0.setClassMetadata(Console, [{
        type: Injectable,
        args: [{ providedIn: 'platform' }]
    }], null, null); })();
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29uc29sZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2NvbnNvbGUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLFVBQVUsRUFBQyxNQUFNLE1BQU0sQ0FBQzs7QUFFaEMsTUFDYSxPQUFPO0lBQ2xCLEdBQUcsQ0FBQyxPQUFlO1FBQ2pCLHNDQUFzQztRQUN0QyxPQUFPLENBQUMsR0FBRyxDQUFDLE9BQU8sQ0FBQyxDQUFDO0lBQ3ZCLENBQUM7SUFDRCw2RUFBNkU7SUFDN0UsSUFBSSxDQUFDLE9BQWU7UUFDbEIsc0NBQXNDO1FBQ3RDLE9BQU8sQ0FBQyxJQUFJLENBQUMsT0FBTyxDQUFDLENBQUM7SUFDeEIsQ0FBQzt3RUFUVSxPQUFPO3VFQUFQLE9BQU8sV0FBUCxPQUFPLG1CQURLLFVBQVU7O1NBQ3RCLE9BQU87c0ZBQVAsT0FBTztjQURuQixVQUFVO2VBQUMsRUFBQyxVQUFVLEVBQUUsVUFBVSxFQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7SW5qZWN0YWJsZX0gZnJvbSAnLi9kaSc7XG5cbkBJbmplY3RhYmxlKHtwcm92aWRlZEluOiAncGxhdGZvcm0nfSlcbmV4cG9ydCBjbGFzcyBDb25zb2xlIHtcbiAgbG9nKG1lc3NhZ2U6IHN0cmluZyk6IHZvaWQge1xuICAgIC8vIHRzbGludDpkaXNhYmxlLW5leHQtbGluZTpuby1jb25zb2xlXG4gICAgY29uc29sZS5sb2cobWVzc2FnZSk7XG4gIH1cbiAgLy8gTm90ZTogZm9yIHJlcG9ydGluZyBlcnJvcnMgdXNlIGBET00ubG9nRXJyb3IoKWAgYXMgaXQgaXMgcGxhdGZvcm0gc3BlY2lmaWNcbiAgd2FybihtZXNzYWdlOiBzdHJpbmcpOiB2b2lkIHtcbiAgICAvLyB0c2xpbnQ6ZGlzYWJsZS1uZXh0LWxpbmU6bm8tY29uc29sZVxuICAgIGNvbnNvbGUud2FybihtZXNzYWdlKTtcbiAgfVxufVxuIl19