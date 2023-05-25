/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { noSideEffects } from '../util/closure';
/**
 * Adds decorator, constructor, and property metadata to a given type via static metadata fields
 * on the type.
 *
 * These metadata fields can later be read with Angular's `ReflectionCapabilities` API.
 *
 * Calls to `setClassMetadata` can be guarded by ngDevMode, resulting in the metadata assignments
 * being tree-shaken away during production builds.
 */
export function setClassMetadata(type, decorators, ctorParameters, propDecorators) {
    return noSideEffects(() => {
        const clazz = type;
        if (decorators !== null) {
            if (clazz.hasOwnProperty('decorators') && clazz.decorators !== undefined) {
                clazz.decorators.push(...decorators);
            }
            else {
                clazz.decorators = decorators;
            }
        }
        if (ctorParameters !== null) {
            // Rather than merging, clobber the existing parameters. If other projects exist which
            // use tsickle-style annotations and reflect over them in the same way, this could
            // cause issues, but that is vanishingly unlikely.
            clazz.ctorParameters = ctorParameters;
        }
        if (propDecorators !== null) {
            // The property decorator objects are merged as it is possible different fields have
            // different decorator types. Decorators on individual fields are not merged, as it's
            // also incredibly unlikely that a field will be decorated both with an Angular
            // decorator and a non-Angular decorator that's also been downleveled.
            if (clazz.hasOwnProperty('propDecorators') && clazz.propDecorators !== undefined) {
                clazz.propDecorators = { ...clazz.propDecorators, ...propDecorators };
            }
            else {
                clazz.propDecorators = propDecorators;
            }
        }
    });
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWV0YWRhdGEuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL21ldGFkYXRhLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxpQkFBaUIsQ0FBQztBQVE5Qzs7Ozs7Ozs7R0FRRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FDNUIsSUFBZSxFQUFFLFVBQXNCLEVBQUUsY0FBa0MsRUFDM0UsY0FBMkM7SUFDN0MsT0FBTyxhQUFhLENBQUMsR0FBRyxFQUFFO1FBQ2pCLE1BQU0sS0FBSyxHQUFHLElBQXdCLENBQUM7UUFFdkMsSUFBSSxVQUFVLEtBQUssSUFBSSxFQUFFO1lBQ3ZCLElBQUksS0FBSyxDQUFDLGNBQWMsQ0FBQyxZQUFZLENBQUMsSUFBSSxLQUFLLENBQUMsVUFBVSxLQUFLLFNBQVMsRUFBRTtnQkFDeEUsS0FBSyxDQUFDLFVBQVUsQ0FBQyxJQUFJLENBQUMsR0FBRyxVQUFVLENBQUMsQ0FBQzthQUN0QztpQkFBTTtnQkFDTCxLQUFLLENBQUMsVUFBVSxHQUFHLFVBQVUsQ0FBQzthQUMvQjtTQUNGO1FBQ0QsSUFBSSxjQUFjLEtBQUssSUFBSSxFQUFFO1lBQzNCLHNGQUFzRjtZQUN0RixrRkFBa0Y7WUFDbEYsa0RBQWtEO1lBQ2xELEtBQUssQ0FBQyxjQUFjLEdBQUcsY0FBYyxDQUFDO1NBQ3ZDO1FBQ0QsSUFBSSxjQUFjLEtBQUssSUFBSSxFQUFFO1lBQzNCLG9GQUFvRjtZQUNwRixxRkFBcUY7WUFDckYsK0VBQStFO1lBQy9FLHNFQUFzRTtZQUN0RSxJQUFJLEtBQUssQ0FBQyxjQUFjLENBQUMsZ0JBQWdCLENBQUMsSUFBSSxLQUFLLENBQUMsY0FBYyxLQUFLLFNBQVMsRUFBRTtnQkFDaEYsS0FBSyxDQUFDLGNBQWMsR0FBRyxFQUFDLEdBQUcsS0FBSyxDQUFDLGNBQWMsRUFBRSxHQUFHLGNBQWMsRUFBQyxDQUFDO2FBQ3JFO2lCQUFNO2dCQUNMLEtBQUssQ0FBQyxjQUFjLEdBQUcsY0FBYyxDQUFDO2FBQ3ZDO1NBQ0Y7SUFDSCxDQUFDLENBQVUsQ0FBQztBQUNyQixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7VHlwZX0gZnJvbSAnLi4vaW50ZXJmYWNlL3R5cGUnO1xuaW1wb3J0IHtub1NpZGVFZmZlY3RzfSBmcm9tICcuLi91dGlsL2Nsb3N1cmUnO1xuXG5pbnRlcmZhY2UgVHlwZVdpdGhNZXRhZGF0YSBleHRlbmRzIFR5cGU8YW55PiB7XG4gIGRlY29yYXRvcnM/OiBhbnlbXTtcbiAgY3RvclBhcmFtZXRlcnM/OiAoKSA9PiBhbnlbXTtcbiAgcHJvcERlY29yYXRvcnM/OiB7W2ZpZWxkOiBzdHJpbmddOiBhbnl9O1xufVxuXG4vKipcbiAqIEFkZHMgZGVjb3JhdG9yLCBjb25zdHJ1Y3RvciwgYW5kIHByb3BlcnR5IG1ldGFkYXRhIHRvIGEgZ2l2ZW4gdHlwZSB2aWEgc3RhdGljIG1ldGFkYXRhIGZpZWxkc1xuICogb24gdGhlIHR5cGUuXG4gKlxuICogVGhlc2UgbWV0YWRhdGEgZmllbGRzIGNhbiBsYXRlciBiZSByZWFkIHdpdGggQW5ndWxhcidzIGBSZWZsZWN0aW9uQ2FwYWJpbGl0aWVzYCBBUEkuXG4gKlxuICogQ2FsbHMgdG8gYHNldENsYXNzTWV0YWRhdGFgIGNhbiBiZSBndWFyZGVkIGJ5IG5nRGV2TW9kZSwgcmVzdWx0aW5nIGluIHRoZSBtZXRhZGF0YSBhc3NpZ25tZW50c1xuICogYmVpbmcgdHJlZS1zaGFrZW4gYXdheSBkdXJpbmcgcHJvZHVjdGlvbiBidWlsZHMuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzZXRDbGFzc01ldGFkYXRhKFxuICAgIHR5cGU6IFR5cGU8YW55PiwgZGVjb3JhdG9yczogYW55W118bnVsbCwgY3RvclBhcmFtZXRlcnM6ICgoKSA9PiBhbnlbXSl8bnVsbCxcbiAgICBwcm9wRGVjb3JhdG9yczoge1tmaWVsZDogc3RyaW5nXTogYW55fXxudWxsKTogdm9pZCB7XG4gIHJldHVybiBub1NpZGVFZmZlY3RzKCgpID0+IHtcbiAgICAgICAgICAgY29uc3QgY2xhenogPSB0eXBlIGFzIFR5cGVXaXRoTWV0YWRhdGE7XG5cbiAgICAgICAgICAgaWYgKGRlY29yYXRvcnMgIT09IG51bGwpIHtcbiAgICAgICAgICAgICBpZiAoY2xhenouaGFzT3duUHJvcGVydHkoJ2RlY29yYXRvcnMnKSAmJiBjbGF6ei5kZWNvcmF0b3JzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgICAgICAgIGNsYXp6LmRlY29yYXRvcnMucHVzaCguLi5kZWNvcmF0b3JzKTtcbiAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgY2xhenouZGVjb3JhdG9ycyA9IGRlY29yYXRvcnM7XG4gICAgICAgICAgICAgfVxuICAgICAgICAgICB9XG4gICAgICAgICAgIGlmIChjdG9yUGFyYW1ldGVycyAhPT0gbnVsbCkge1xuICAgICAgICAgICAgIC8vIFJhdGhlciB0aGFuIG1lcmdpbmcsIGNsb2JiZXIgdGhlIGV4aXN0aW5nIHBhcmFtZXRlcnMuIElmIG90aGVyIHByb2plY3RzIGV4aXN0IHdoaWNoXG4gICAgICAgICAgICAgLy8gdXNlIHRzaWNrbGUtc3R5bGUgYW5ub3RhdGlvbnMgYW5kIHJlZmxlY3Qgb3ZlciB0aGVtIGluIHRoZSBzYW1lIHdheSwgdGhpcyBjb3VsZFxuICAgICAgICAgICAgIC8vIGNhdXNlIGlzc3VlcywgYnV0IHRoYXQgaXMgdmFuaXNoaW5nbHkgdW5saWtlbHkuXG4gICAgICAgICAgICAgY2xhenouY3RvclBhcmFtZXRlcnMgPSBjdG9yUGFyYW1ldGVycztcbiAgICAgICAgICAgfVxuICAgICAgICAgICBpZiAocHJvcERlY29yYXRvcnMgIT09IG51bGwpIHtcbiAgICAgICAgICAgICAvLyBUaGUgcHJvcGVydHkgZGVjb3JhdG9yIG9iamVjdHMgYXJlIG1lcmdlZCBhcyBpdCBpcyBwb3NzaWJsZSBkaWZmZXJlbnQgZmllbGRzIGhhdmVcbiAgICAgICAgICAgICAvLyBkaWZmZXJlbnQgZGVjb3JhdG9yIHR5cGVzLiBEZWNvcmF0b3JzIG9uIGluZGl2aWR1YWwgZmllbGRzIGFyZSBub3QgbWVyZ2VkLCBhcyBpdCdzXG4gICAgICAgICAgICAgLy8gYWxzbyBpbmNyZWRpYmx5IHVubGlrZWx5IHRoYXQgYSBmaWVsZCB3aWxsIGJlIGRlY29yYXRlZCBib3RoIHdpdGggYW4gQW5ndWxhclxuICAgICAgICAgICAgIC8vIGRlY29yYXRvciBhbmQgYSBub24tQW5ndWxhciBkZWNvcmF0b3IgdGhhdCdzIGFsc28gYmVlbiBkb3dubGV2ZWxlZC5cbiAgICAgICAgICAgICBpZiAoY2xhenouaGFzT3duUHJvcGVydHkoJ3Byb3BEZWNvcmF0b3JzJykgJiYgY2xhenoucHJvcERlY29yYXRvcnMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgICAgY2xhenoucHJvcERlY29yYXRvcnMgPSB7Li4uY2xhenoucHJvcERlY29yYXRvcnMsIC4uLnByb3BEZWNvcmF0b3JzfTtcbiAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgY2xhenoucHJvcERlY29yYXRvcnMgPSBwcm9wRGVjb3JhdG9ycztcbiAgICAgICAgICAgICB9XG4gICAgICAgICAgIH1cbiAgICAgICAgIH0pIGFzIG5ldmVyO1xufVxuIl19