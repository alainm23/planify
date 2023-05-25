/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { getOriginalError } from './util/errors';
/**
 * Provides a hook for centralized exception handling.
 *
 * The default implementation of `ErrorHandler` prints error messages to the `console`. To
 * intercept error handling, write a custom exception handler that replaces this default as
 * appropriate for your app.
 *
 * @usageNotes
 * ### Example
 *
 * ```
 * class MyErrorHandler implements ErrorHandler {
 *   handleError(error) {
 *     // do something with the exception
 *   }
 * }
 *
 * @NgModule({
 *   providers: [{provide: ErrorHandler, useClass: MyErrorHandler}]
 * })
 * class MyModule {}
 * ```
 *
 * @publicApi
 */
export class ErrorHandler {
    constructor() {
        /**
         * @internal
         */
        this._console = console;
    }
    handleError(error) {
        const originalError = this._findOriginalError(error);
        this._console.error('ERROR', error);
        if (originalError) {
            this._console.error('ORIGINAL ERROR', originalError);
        }
    }
    /** @internal */
    _findOriginalError(error) {
        let e = error && getOriginalError(error);
        while (e && getOriginalError(e)) {
            e = getOriginalError(e);
        }
        return e || null;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZXJyb3JfaGFuZGxlci5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2Vycm9yX2hhbmRsZXIudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLGdCQUFnQixFQUFDLE1BQU0sZUFBZSxDQUFDO0FBRS9DOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7R0F3Qkc7QUFDSCxNQUFNLE9BQU8sWUFBWTtJQUF6QjtRQUNFOztXQUVHO1FBQ0gsYUFBUSxHQUFZLE9BQU8sQ0FBQztJQW9COUIsQ0FBQztJQWxCQyxXQUFXLENBQUMsS0FBVTtRQUNwQixNQUFNLGFBQWEsR0FBRyxJQUFJLENBQUMsa0JBQWtCLENBQUMsS0FBSyxDQUFDLENBQUM7UUFFckQsSUFBSSxDQUFDLFFBQVEsQ0FBQyxLQUFLLENBQUMsT0FBTyxFQUFFLEtBQUssQ0FBQyxDQUFDO1FBQ3BDLElBQUksYUFBYSxFQUFFO1lBQ2pCLElBQUksQ0FBQyxRQUFRLENBQUMsS0FBSyxDQUFDLGdCQUFnQixFQUFFLGFBQWEsQ0FBQyxDQUFDO1NBQ3REO0lBQ0gsQ0FBQztJQUVELGdCQUFnQjtJQUNoQixrQkFBa0IsQ0FBQyxLQUFVO1FBQzNCLElBQUksQ0FBQyxHQUFHLEtBQUssSUFBSSxnQkFBZ0IsQ0FBQyxLQUFLLENBQUMsQ0FBQztRQUN6QyxPQUFPLENBQUMsSUFBSSxnQkFBZ0IsQ0FBQyxDQUFDLENBQUMsRUFBRTtZQUMvQixDQUFDLEdBQUcsZ0JBQWdCLENBQUMsQ0FBQyxDQUFDLENBQUM7U0FDekI7UUFFRCxPQUFPLENBQUMsSUFBSSxJQUFJLENBQUM7SUFDbkIsQ0FBQztDQUNGIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Z2V0T3JpZ2luYWxFcnJvcn0gZnJvbSAnLi91dGlsL2Vycm9ycyc7XG5cbi8qKlxuICogUHJvdmlkZXMgYSBob29rIGZvciBjZW50cmFsaXplZCBleGNlcHRpb24gaGFuZGxpbmcuXG4gKlxuICogVGhlIGRlZmF1bHQgaW1wbGVtZW50YXRpb24gb2YgYEVycm9ySGFuZGxlcmAgcHJpbnRzIGVycm9yIG1lc3NhZ2VzIHRvIHRoZSBgY29uc29sZWAuIFRvXG4gKiBpbnRlcmNlcHQgZXJyb3IgaGFuZGxpbmcsIHdyaXRlIGEgY3VzdG9tIGV4Y2VwdGlvbiBoYW5kbGVyIHRoYXQgcmVwbGFjZXMgdGhpcyBkZWZhdWx0IGFzXG4gKiBhcHByb3ByaWF0ZSBmb3IgeW91ciBhcHAuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqICMjIyBFeGFtcGxlXG4gKlxuICogYGBgXG4gKiBjbGFzcyBNeUVycm9ySGFuZGxlciBpbXBsZW1lbnRzIEVycm9ySGFuZGxlciB7XG4gKiAgIGhhbmRsZUVycm9yKGVycm9yKSB7XG4gKiAgICAgLy8gZG8gc29tZXRoaW5nIHdpdGggdGhlIGV4Y2VwdGlvblxuICogICB9XG4gKiB9XG4gKlxuICogQE5nTW9kdWxlKHtcbiAqICAgcHJvdmlkZXJzOiBbe3Byb3ZpZGU6IEVycm9ySGFuZGxlciwgdXNlQ2xhc3M6IE15RXJyb3JIYW5kbGVyfV1cbiAqIH0pXG4gKiBjbGFzcyBNeU1vZHVsZSB7fVxuICogYGBgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgY2xhc3MgRXJyb3JIYW5kbGVyIHtcbiAgLyoqXG4gICAqIEBpbnRlcm5hbFxuICAgKi9cbiAgX2NvbnNvbGU6IENvbnNvbGUgPSBjb25zb2xlO1xuXG4gIGhhbmRsZUVycm9yKGVycm9yOiBhbnkpOiB2b2lkIHtcbiAgICBjb25zdCBvcmlnaW5hbEVycm9yID0gdGhpcy5fZmluZE9yaWdpbmFsRXJyb3IoZXJyb3IpO1xuXG4gICAgdGhpcy5fY29uc29sZS5lcnJvcignRVJST1InLCBlcnJvcik7XG4gICAgaWYgKG9yaWdpbmFsRXJyb3IpIHtcbiAgICAgIHRoaXMuX2NvbnNvbGUuZXJyb3IoJ09SSUdJTkFMIEVSUk9SJywgb3JpZ2luYWxFcnJvcik7XG4gICAgfVxuICB9XG5cbiAgLyoqIEBpbnRlcm5hbCAqL1xuICBfZmluZE9yaWdpbmFsRXJyb3IoZXJyb3I6IGFueSk6IEVycm9yfG51bGwge1xuICAgIGxldCBlID0gZXJyb3IgJiYgZ2V0T3JpZ2luYWxFcnJvcihlcnJvcik7XG4gICAgd2hpbGUgKGUgJiYgZ2V0T3JpZ2luYWxFcnJvcihlKSkge1xuICAgICAgZSA9IGdldE9yaWdpbmFsRXJyb3IoZSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIGUgfHwgbnVsbDtcbiAgfVxufVxuIl19