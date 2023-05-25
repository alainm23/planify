/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
/**
 * Wraps a test function in an asynchronous test zone. The test will automatically
 * complete when all asynchronous calls within this zone are done. Can be used
 * to wrap an {@link inject} call.
 *
 * Example:
 *
 * ```
 * it('...', waitForAsync(inject([AClass], (object) => {
 *   object.doSomething.then(() => {
 *     expect(...);
 *   })
 * });
 * ```
 *
 * @publicApi
 */
export function waitForAsync(fn) {
    const _Zone = typeof Zone !== 'undefined' ? Zone : null;
    if (!_Zone) {
        return function () {
            return Promise.reject('Zone is needed for the waitForAsync() test helper but could not be found. ' +
                'Please make sure that your environment includes zone.js');
        };
    }
    const asyncTest = _Zone && _Zone[_Zone.__symbol__('asyncTest')];
    if (typeof asyncTest === 'function') {
        return asyncTest(fn);
    }
    return function () {
        return Promise.reject('zone-testing.js is needed for the async() test helper but could not be found. ' +
            'Please make sure that your environment includes zone.js/testing');
    };
}
/**
 * @deprecated use `waitForAsync()`, (expected removal in v12)
 * @see {@link waitForAsync}
 * @publicApi
 * */
export function async(fn) {
    return waitForAsync(fn);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYXN5bmMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3Rlc3Rpbmcvc3JjL2FzeW5jLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUNIOzs7Ozs7Ozs7Ozs7Ozs7O0dBZ0JHO0FBQ0gsTUFBTSxVQUFVLFlBQVksQ0FBQyxFQUFZO0lBQ3ZDLE1BQU0sS0FBSyxHQUFRLE9BQU8sSUFBSSxLQUFLLFdBQVcsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUM7SUFDN0QsSUFBSSxDQUFDLEtBQUssRUFBRTtRQUNWLE9BQU87WUFDTCxPQUFPLE9BQU8sQ0FBQyxNQUFNLENBQ2pCLDRFQUE0RTtnQkFDNUUseURBQXlELENBQUMsQ0FBQztRQUNqRSxDQUFDLENBQUM7S0FDSDtJQUNELE1BQU0sU0FBUyxHQUFHLEtBQUssSUFBSSxLQUFLLENBQUMsS0FBSyxDQUFDLFVBQVUsQ0FBQyxXQUFXLENBQUMsQ0FBQyxDQUFDO0lBQ2hFLElBQUksT0FBTyxTQUFTLEtBQUssVUFBVSxFQUFFO1FBQ25DLE9BQU8sU0FBUyxDQUFDLEVBQUUsQ0FBQyxDQUFDO0tBQ3RCO0lBQ0QsT0FBTztRQUNMLE9BQU8sT0FBTyxDQUFDLE1BQU0sQ0FDakIsZ0ZBQWdGO1lBQ2hGLGlFQUFpRSxDQUFDLENBQUM7SUFDekUsQ0FBQyxDQUFDO0FBQ0osQ0FBQztBQUVEOzs7O0tBSUs7QUFDTCxNQUFNLFVBQVUsS0FBSyxDQUFDLEVBQVk7SUFDaEMsT0FBTyxZQUFZLENBQUMsRUFBRSxDQUFDLENBQUM7QUFDMUIsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuLyoqXG4gKiBXcmFwcyBhIHRlc3QgZnVuY3Rpb24gaW4gYW4gYXN5bmNocm9ub3VzIHRlc3Qgem9uZS4gVGhlIHRlc3Qgd2lsbCBhdXRvbWF0aWNhbGx5XG4gKiBjb21wbGV0ZSB3aGVuIGFsbCBhc3luY2hyb25vdXMgY2FsbHMgd2l0aGluIHRoaXMgem9uZSBhcmUgZG9uZS4gQ2FuIGJlIHVzZWRcbiAqIHRvIHdyYXAgYW4ge0BsaW5rIGluamVjdH0gY2FsbC5cbiAqXG4gKiBFeGFtcGxlOlxuICpcbiAqIGBgYFxuICogaXQoJy4uLicsIHdhaXRGb3JBc3luYyhpbmplY3QoW0FDbGFzc10sIChvYmplY3QpID0+IHtcbiAqICAgb2JqZWN0LmRvU29tZXRoaW5nLnRoZW4oKCkgPT4ge1xuICogICAgIGV4cGVjdCguLi4pO1xuICogICB9KVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB3YWl0Rm9yQXN5bmMoZm46IEZ1bmN0aW9uKTogKGRvbmU6IGFueSkgPT4gYW55IHtcbiAgY29uc3QgX1pvbmU6IGFueSA9IHR5cGVvZiBab25lICE9PSAndW5kZWZpbmVkJyA/IFpvbmUgOiBudWxsO1xuICBpZiAoIV9ab25lKSB7XG4gICAgcmV0dXJuIGZ1bmN0aW9uKCkge1xuICAgICAgcmV0dXJuIFByb21pc2UucmVqZWN0KFxuICAgICAgICAgICdab25lIGlzIG5lZWRlZCBmb3IgdGhlIHdhaXRGb3JBc3luYygpIHRlc3QgaGVscGVyIGJ1dCBjb3VsZCBub3QgYmUgZm91bmQuICcgK1xuICAgICAgICAgICdQbGVhc2UgbWFrZSBzdXJlIHRoYXQgeW91ciBlbnZpcm9ubWVudCBpbmNsdWRlcyB6b25lLmpzJyk7XG4gICAgfTtcbiAgfVxuICBjb25zdCBhc3luY1Rlc3QgPSBfWm9uZSAmJiBfWm9uZVtfWm9uZS5fX3N5bWJvbF9fKCdhc3luY1Rlc3QnKV07XG4gIGlmICh0eXBlb2YgYXN5bmNUZXN0ID09PSAnZnVuY3Rpb24nKSB7XG4gICAgcmV0dXJuIGFzeW5jVGVzdChmbik7XG4gIH1cbiAgcmV0dXJuIGZ1bmN0aW9uKCkge1xuICAgIHJldHVybiBQcm9taXNlLnJlamVjdChcbiAgICAgICAgJ3pvbmUtdGVzdGluZy5qcyBpcyBuZWVkZWQgZm9yIHRoZSBhc3luYygpIHRlc3QgaGVscGVyIGJ1dCBjb3VsZCBub3QgYmUgZm91bmQuICcgK1xuICAgICAgICAnUGxlYXNlIG1ha2Ugc3VyZSB0aGF0IHlvdXIgZW52aXJvbm1lbnQgaW5jbHVkZXMgem9uZS5qcy90ZXN0aW5nJyk7XG4gIH07XG59XG5cbi8qKlxuICogQGRlcHJlY2F0ZWQgdXNlIGB3YWl0Rm9yQXN5bmMoKWAsIChleHBlY3RlZCByZW1vdmFsIGluIHYxMilcbiAqIEBzZWUge0BsaW5rIHdhaXRGb3JBc3luY31cbiAqIEBwdWJsaWNBcGlcbiAqICovXG5leHBvcnQgZnVuY3Rpb24gYXN5bmMoZm46IEZ1bmN0aW9uKTogKGRvbmU6IGFueSkgPT4gYW55IHtcbiAgcmV0dXJuIHdhaXRGb3JBc3luYyhmbik7XG59XG4iXX0=