/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { RuntimeError } from '../../errors';
import { EMPTY_ARRAY, EMPTY_OBJ } from '../../util/empty';
import { fillProperties } from '../../util/property';
import { isComponentDef } from '../interfaces/type_checks';
import { mergeHostAttrs } from '../util/attrs_utils';
import { stringifyForError } from '../util/stringify_utils';
export function getSuperType(type) {
    return Object.getPrototypeOf(type.prototype).constructor;
}
/**
 * Merges the definition from a super class to a sub class.
 * @param definition The definition that is a SubClass of another directive of component
 *
 * @codeGenApi
 */
export function ɵɵInheritDefinitionFeature(definition) {
    let superType = getSuperType(definition.type);
    let shouldInheritFields = true;
    const inheritanceChain = [definition];
    while (superType) {
        let superDef = undefined;
        if (isComponentDef(definition)) {
            // Don't use getComponentDef/getDirectiveDef. This logic relies on inheritance.
            superDef = superType.ɵcmp || superType.ɵdir;
        }
        else {
            if (superType.ɵcmp) {
                throw new RuntimeError(903 /* RuntimeErrorCode.INVALID_INHERITANCE */, ngDevMode &&
                    `Directives cannot inherit Components. Directive ${stringifyForError(definition.type)} is attempting to extend component ${stringifyForError(superType)}`);
            }
            // Don't use getComponentDef/getDirectiveDef. This logic relies on inheritance.
            superDef = superType.ɵdir;
        }
        if (superDef) {
            if (shouldInheritFields) {
                inheritanceChain.push(superDef);
                // Some fields in the definition may be empty, if there were no values to put in them that
                // would've justified object creation. Unwrap them if necessary.
                const writeableDef = definition;
                writeableDef.inputs = maybeUnwrapEmpty(definition.inputs);
                writeableDef.declaredInputs = maybeUnwrapEmpty(definition.declaredInputs);
                writeableDef.outputs = maybeUnwrapEmpty(definition.outputs);
                // Merge hostBindings
                const superHostBindings = superDef.hostBindings;
                superHostBindings && inheritHostBindings(definition, superHostBindings);
                // Merge queries
                const superViewQuery = superDef.viewQuery;
                const superContentQueries = superDef.contentQueries;
                superViewQuery && inheritViewQuery(definition, superViewQuery);
                superContentQueries && inheritContentQueries(definition, superContentQueries);
                // Merge inputs and outputs
                fillProperties(definition.inputs, superDef.inputs);
                fillProperties(definition.declaredInputs, superDef.declaredInputs);
                fillProperties(definition.outputs, superDef.outputs);
                // Merge animations metadata.
                // If `superDef` is a Component, the `data` field is present (defaults to an empty object).
                if (isComponentDef(superDef) && superDef.data.animation) {
                    // If super def is a Component, the `definition` is also a Component, since Directives can
                    // not inherit Components (we throw an error above and cannot reach this code).
                    const defData = definition.data;
                    defData.animation = (defData.animation || []).concat(superDef.data.animation);
                }
            }
            // Run parent features
            const features = superDef.features;
            if (features) {
                for (let i = 0; i < features.length; i++) {
                    const feature = features[i];
                    if (feature && feature.ngInherit) {
                        feature(definition);
                    }
                    // If `InheritDefinitionFeature` is a part of the current `superDef`, it means that this
                    // def already has all the necessary information inherited from its super class(es), so we
                    // can stop merging fields from super classes. However we need to iterate through the
                    // prototype chain to look for classes that might contain other "features" (like
                    // NgOnChanges), which we should invoke for the original `definition`. We set the
                    // `shouldInheritFields` flag to indicate that, essentially skipping fields inheritance
                    // logic and only invoking functions from the "features" list.
                    if (feature === ɵɵInheritDefinitionFeature) {
                        shouldInheritFields = false;
                    }
                }
            }
        }
        superType = Object.getPrototypeOf(superType);
    }
    mergeHostAttrsAcrossInheritance(inheritanceChain);
}
/**
 * Merge the `hostAttrs` and `hostVars` from the inherited parent to the base class.
 *
 * @param inheritanceChain A list of `WritableDefs` starting at the top most type and listing
 * sub-types in order. For each type take the `hostAttrs` and `hostVars` and merge it with the child
 * type.
 */
function mergeHostAttrsAcrossInheritance(inheritanceChain) {
    let hostVars = 0;
    let hostAttrs = null;
    // We process the inheritance order from the base to the leaves here.
    for (let i = inheritanceChain.length - 1; i >= 0; i--) {
        const def = inheritanceChain[i];
        // For each `hostVars`, we need to add the superclass amount.
        def.hostVars = (hostVars += def.hostVars);
        // for each `hostAttrs` we need to merge it with superclass.
        def.hostAttrs =
            mergeHostAttrs(def.hostAttrs, hostAttrs = mergeHostAttrs(hostAttrs, def.hostAttrs));
    }
}
function maybeUnwrapEmpty(value) {
    if (value === EMPTY_OBJ) {
        return {};
    }
    else if (value === EMPTY_ARRAY) {
        return [];
    }
    else {
        return value;
    }
}
function inheritViewQuery(definition, superViewQuery) {
    const prevViewQuery = definition.viewQuery;
    if (prevViewQuery) {
        definition.viewQuery = (rf, ctx) => {
            superViewQuery(rf, ctx);
            prevViewQuery(rf, ctx);
        };
    }
    else {
        definition.viewQuery = superViewQuery;
    }
}
function inheritContentQueries(definition, superContentQueries) {
    const prevContentQueries = definition.contentQueries;
    if (prevContentQueries) {
        definition.contentQueries = (rf, ctx, directiveIndex) => {
            superContentQueries(rf, ctx, directiveIndex);
            prevContentQueries(rf, ctx, directiveIndex);
        };
    }
    else {
        definition.contentQueries = superContentQueries;
    }
}
function inheritHostBindings(definition, superHostBindings) {
    const prevHostBindings = definition.hostBindings;
    if (prevHostBindings) {
        definition.hostBindings = (rf, ctx) => {
            superHostBindings(rf, ctx);
            prevHostBindings(rf, ctx);
        };
    }
    else {
        definition.hostBindings = superHostBindings;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5oZXJpdF9kZWZpbml0aW9uX2ZlYXR1cmUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL2ZlYXR1cmVzL2luaGVyaXRfZGVmaW5pdGlvbl9mZWF0dXJlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxZQUFZLEVBQW1CLE1BQU0sY0FBYyxDQUFDO0FBRTVELE9BQU8sRUFBQyxXQUFXLEVBQUUsU0FBUyxFQUFDLE1BQU0sa0JBQWtCLENBQUM7QUFDeEQsT0FBTyxFQUFDLGNBQWMsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBR25ELE9BQU8sRUFBQyxjQUFjLEVBQUMsTUFBTSwyQkFBMkIsQ0FBQztBQUN6RCxPQUFPLEVBQUMsY0FBYyxFQUFDLE1BQU0scUJBQXFCLENBQUM7QUFDbkQsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0seUJBQXlCLENBQUM7QUFFMUQsTUFBTSxVQUFVLFlBQVksQ0FBQyxJQUFlO0lBRTFDLE9BQU8sTUFBTSxDQUFDLGNBQWMsQ0FBQyxJQUFJLENBQUMsU0FBUyxDQUFDLENBQUMsV0FBVyxDQUFDO0FBQzNELENBQUM7QUFJRDs7Ozs7R0FLRztBQUNILE1BQU0sVUFBVSwwQkFBMEIsQ0FBQyxVQUErQztJQUN4RixJQUFJLFNBQVMsR0FBRyxZQUFZLENBQUMsVUFBVSxDQUFDLElBQUksQ0FBQyxDQUFDO0lBQzlDLElBQUksbUJBQW1CLEdBQUcsSUFBSSxDQUFDO0lBQy9CLE1BQU0sZ0JBQWdCLEdBQWtCLENBQUMsVUFBVSxDQUFDLENBQUM7SUFFckQsT0FBTyxTQUFTLEVBQUU7UUFDaEIsSUFBSSxRQUFRLEdBQWtELFNBQVMsQ0FBQztRQUN4RSxJQUFJLGNBQWMsQ0FBQyxVQUFVLENBQUMsRUFBRTtZQUM5QiwrRUFBK0U7WUFDL0UsUUFBUSxHQUFHLFNBQVMsQ0FBQyxJQUFJLElB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WUFBWSxHQUFHLGlCQUFpQixDQUFDO0tBQzdDO0FBQ0gsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge1J1bnRpbWVFcnJvciwgUnVudGltZUVycm9yQ29kZX0gZnJvbSAnLi4vLi4vZXJyb3JzJztcbmltcG9ydCB7VHlwZSwgV3JpdGFibGV9IGZyb20gJy4uLy4uL2ludGVyZmFjZS90eXBlJztcbmltcG9ydCB7RU1QVFlfQVJSQVksIEVNUFRZX09CSn0gZnJvbSAnLi4vLi4vdXRpbC9lbXB0eSc7XG5pbXBvcnQge2ZpbGxQcm9wZXJ0aWVzfSBmcm9tICcuLi8uLi91dGlsL3Byb3BlcnR5JztcbmltcG9ydCB7Q29tcG9uZW50RGVmLCBDb250ZW50UXVlcmllc0Z1bmN0aW9uLCBEaXJlY3RpdmVEZWYsIERpcmVjdGl2ZURlZkZlYXR1cmUsIEhvc3RCaW5kaW5nc0Z1bmN0aW9uLCBSZW5kZXJGbGFncywgVmlld1F1ZXJpZXNGdW5jdGlvbn0gZnJvbSAnLi4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7VEF0dHJpYnV0ZXN9IGZyb20gJy4uL2ludGVyZmFjZXMvbm9kZSc7XG5pbXBvcnQge2lzQ29tcG9uZW50RGVmfSBmcm9tICcuLi9pbnRlcmZhY2VzL3R5cGVfY2hlY2tzJztcbmltcG9ydCB7bWVyZ2VIb3N0QXR0cnN9IGZyb20gJy4uL3V0aWwvYXR0cnNfdXRpbHMnO1xuaW1wb3J0IHtzdHJpbmdpZnlGb3JFcnJvcn0gZnJvbSAnLi4vdXRpbC9zdHJpbmdpZnlfdXRpbHMnO1xuXG5leHBvcnQgZnVuY3Rpb24gZ2V0U3VwZXJUeXBlKHR5cGU6IFR5cGU8YW55Pik6IFR5cGU8YW55PiZcbiAgICB7ybVjbXA/OiBDb21wb25lbnREZWY8YW55PiwgybVkaXI/OiBEaXJlY3RpdmVEZWY8YW55Pn0ge1xuICByZXR1cm4gT2JqZWN0LmdldFByb3RvdHlwZU9mKHR5cGUucHJvdG90eXBlKS5jb25zdHJ1Y3Rvcjtcbn1cblxudHlwZSBXcml0YWJsZURlZiA9IFdyaXRhYmxlPERpcmVjdGl2ZURlZjxhbnk+fENvbXBvbmVudERlZjxhbnk+PjtcblxuLyoqXG4gKiBNZXJnZXMgdGhlIGRlZmluaXRpb24gZnJvbSBhIHN1cGVyIGNsYXNzIHRvIGEgc3ViIGNsYXNzLlxuICogQHBhcmFtIGRlZmluaXRpb24gVGhlIGRlZmluaXRpb24gdGhhdCBpcyBhIFN1YkNsYXNzIG9mIGFub3RoZXIgZGlyZWN0aXZlIG9mIGNvbXBvbmVudFxuICpcbiAqIEBjb2RlR2VuQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtcm1SW5oZXJpdERlZmluaXRpb25GZWF0dXJlKGRlZmluaXRpb246IERpcmVjdGl2ZURlZjxhbnk+fENvbXBvbmVudERlZjxhbnk+KTogdm9pZCB7XG4gIGxldCBzdXBlclR5cGUgPSBnZXRTdXBlclR5cGUoZGVmaW5pdGlvbi50eXBlKTtcbiAgbGV0IHNob3VsZEluaGVyaXRGaWVsZHMgPSB0cnVlO1xuICBjb25zdCBpbmhlcml0YW5jZUNoYWluOiBXcml0YWJsZURlZltdID0gW2RlZmluaXRpb25dO1xuXG4gIHdoaWxlIChzdXBlclR5cGUpIHtcbiAgICBsZXQgc3VwZXJEZWY6IERpcmVjdGl2ZURlZjxhbnk+fENvbXBvbmVudERlZjxhbnk+fHVuZGVmaW5lZCA9IHVuZGVmaW5lZDtcbiAgICBpZiAoaXNDb21wb25lbnREZWYoZGVmaW5pdGlvbikpIHtcbiAgICAgIC8vIERvbid0IHVzZSBnZXRDb21wb25lbnREZWYvZ2V0RGlyZWN0aXZlRGVmLiBUaGlzIGxvZ2ljIHJlbGllcyBvbiBpbmhlcml0YW5jZS5cbiAgICAgIHN1cGVyRGVmID0gc3VwZXJUeXBlLsm1Y21wIHx8IHN1cGVyVHlwZS7JtWRpcjtcbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKHN1cGVyVHlwZS7JtWNtcCkge1xuICAgICAgICB0aHJvdyBuZXcgUnVudGltZUVycm9yKFxuICAgICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX0lOSEVSSVRBTkNFLFxuICAgICAgICAgICAgbmdEZXZNb2RlICYmXG4gICAgICAgICAgICAgICAgYERpcmVjdGl2ZXMgY2Fubm90IGluaGVyaXQgQ29tcG9uZW50cy4gRGlyZWN0aXZlICR7XG4gICAgICAgICAgICAgICAgICAgIHN0cmluZ2lmeUZvckVycm9yKGRlZmluaXRpb24udHlwZSl9IGlzIGF0dGVtcHRpbmcgdG8gZXh0ZW5kIGNvbXBvbmVudCAke1xuICAgICAgICAgICAgICAgICAgICBzdHJpbmdpZnlGb3JFcnJvcihzdXBlclR5cGUpfWApO1xuICAgICAgfVxuICAgICAgLy8gRG9uJ3QgdXNlIGdldENvbXBvbmVudERlZi9nZXREaXJlY3RpdmVEZWYuIFRoaXMgbG9naWMgcmVsaWVzIG9uIGluaGVyaXRhbmNlLlxuICAgICAgc3VwZXJEZWYgPSBzdXBlclR5cGUuybVkaXI7XG4gICAgfVxuXG4gICAgaWYgKHN1cGVyRGVmKSB7XG4gICAgICBpZiAoc2hvdWxkSW5oZXJpdEZpZWxkcykge1xuICAgICAgICBpbmhlcml0YW5jZUNoYWluLnB1c2goc3VwZXJEZWYpO1xuICAgICAgICAvLyBTb21lIGZpZWxkcyBpbiB0aGUgZGVmaW5pdGlvbiBtYXkgYmUgZW1wdHksIGlmIHRoZXJlIHdlcmUgbm8gdmFsdWVzIHRvIHB1dCBpbiB0aGVtIHRoYXRcbiAgICAgICAgLy8gd291bGQndmUganVzdGlmaWVkIG9iamVjdCBjcmVhdGlvbi4gVW53cmFwIHRoZW0gaWYgbmVjZXNzYXJ5LlxuICAgICAgICBjb25zdCB3cml0ZWFibGVEZWYgPSBkZWZpbml0aW9uIGFzIFdyaXRhYmxlRGVmO1xuICAgICAgICB3cml0ZWFibGVEZWYuaW5wdXRzID0gbWF5YmVVbndyYXBFbXB0eShkZWZpbml0aW9uLmlucHV0cyk7XG4gICAgICAgIHdyaXRlYWJsZURlZi5kZWNsYXJlZElucHV0cyA9IG1heWJlVW53cmFwRW1wdHkoZGVmaW5pdGlvbi5kZWNsYXJlZElucHV0cyk7XG4gICAgICAgIHdyaXRlYWJsZURlZi5vdXRwdXRzID0gbWF5YmVVbndyYXBFbXB0eShkZWZpbml0aW9uLm91dHB1dHMpO1xuXG4gICAgICAgIC8vIE1lcmdlIGhvc3RCaW5kaW5nc1xuICAgICAgICBjb25zdCBzdXBlckhvc3RCaW5kaW5ncyA9IHN1cGVyRGVmLmhvc3RCaW5kaW5ncztcbiAgICAgICAgc3VwZXJIb3N0QmluZGluZ3MgJiYgaW5oZXJpdEhvc3RCaW5kaW5ncyhkZWZpbml0aW9uLCBzdXBlckhvc3RCaW5kaW5ncyk7XG5cbiAgICAgICAgLy8gTWVyZ2UgcXVlcmllc1xuICAgICAgICBjb25zdCBzdXBlclZpZXdRdWVyeSA9IHN1cGVyRGVmLnZpZXdRdWVyeTtcbiAgICAgICAgY29uc3Qgc3VwZXJDb250ZW50UXVlcmllcyA9IHN1cGVyRGVmLmNvbnRlbnRRdWVyaWVzO1xuICAgICAgICBzdXBlclZpZXdRdWVyeSAmJiBpbmhlcml0Vmlld1F1ZXJ5KGRlZmluaXRpb24sIHN1cGVyVmlld1F1ZXJ5KTtcbiAgICAgICAgc3VwZXJDb250ZW50UXVlcmllcyAmJiBpbmhlcml0Q29udGVudFF1ZXJpZXMoZGVmaW5pdGlvbiwgc3VwZXJDb250ZW50UXVlcmllcyk7XG5cbiAgICAgICAgLy8gTWVyZ2UgaW5wdXRzIGFuZCBvdXRwdXRzXG4gICAgICAgIGZpbGxQcm9wZXJ0aWVzKGRlZmluaXRpb24uaW5wdXRzLCBzdXBlckRlZi5pbnB1dHMpO1xuICAgICAgICBmaWxsUHJvcGVydGllcyhkZWZpbml0aW9uLmRlY2xhcmVkSW5wdXRzLCBzdXBlckRlZi5kZWNsYXJlZElucHV0cyk7XG4gICAgICAgIGZpbGxQcm9wZXJ0aWVzKGRlZmluaXRpb24ub3V0cHV0cywgc3VwZXJEZWYub3V0cHV0cyk7XG5cbiAgICAgICAgLy8gTWVyZ2UgYW5pbWF0aW9ucyBtZXRhZGF0YS5cbiAgICAgICAgLy8gSWYgYHN1cGVyRGVmYCBpcyBhIENvbXBvbmVudCwgdGhlIGBkYXRhYCBmaWVsZCBpcyBwcmVzZW50IChkZWZhdWx0cyB0byBhbiBlbXB0eSBvYmplY3QpLlxuICAgICAgICBpZiAoaXNDb21wb25lbnREZWYoc3VwZXJEZWYpICYmIHN1cGVyRGVmLmRhdGEuYW5pbWF0aW9uKSB7XG4gICAgICAgICAgLy8gSWYgc3VwZXIgZGVmIGlzIGEgQ29tcG9uZW50LCB0aGUgYGRlZmluaXRpb25gIGlzIGFsc28gYSBDb21wb25lbnQsIHNpbmNlIERpcmVjdGl2ZXMgY2FuXG4gICAgICAgICAgLy8gbm90IGluaGVyaXQgQ29tcG9uZW50cyAod2UgdGhyb3cgYW4gZXJyb3IgYWJvdmUgYW5kIGNhbm5vdCByZWFjaCB0aGlzIGNvZGUpLlxuICAgICAgICAgIGNvbnN0IGRlZkRhdGEgPSAoZGVmaW5pdGlvbiBhcyBDb21wb25lbnREZWY8YW55PikuZGF0YTtcbiAgICAgICAgICBkZWZEYXRhLmFuaW1hdGlvbiA9IChkZWZEYXRhLmFuaW1hdGlvbiB8fCBbXSkuY29uY2F0KHN1cGVyRGVmLmRhdGEuYW5pbWF0aW9uKTtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICAvLyBSdW4gcGFyZW50IGZlYXR1cmVzXG4gICAgICBjb25zdCBmZWF0dXJlcyA9IHN1cGVyRGVmLmZlYXR1cmVzO1xuICAgICAgaWYgKGZlYXR1cmVzKSB7XG4gICAgICAgIGZvciAobGV0IGkgPSAwOyBpIDwgZmVhdHVyZXMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICBjb25zdCBmZWF0dXJlID0gZmVhdHVyZXNbaV07XG4gICAgICAgICAgaWYgKGZlYXR1cmUgJiYgZmVhdHVyZS5uZ0luaGVyaXQpIHtcbiAgICAgICAgICAgIChmZWF0dXJlIGFzIERpcmVjdGl2ZURlZkZlYXR1cmUpKGRlZmluaXRpb24pO1xuICAgICAgICAgIH1cbiAgICAgICAgICAvLyBJZiBgSW5oZXJpdERlZmluaXRpb25GZWF0dXJlYCBpcyBhIHBhcnQgb2YgdGhlIGN1cnJlbnQgYHN1cGVyRGVmYCwgaXQgbWVhbnMgdGhhdCB0aGlzXG4gICAgICAgICAgLy8gZGVmIGFscmVhZHkgaGFzIGFsbCB0aGUgbmVjZXNzYXJ5IGluZm9ybWF0aW9uIGluaGVyaXRlZCBmcm9tIGl0cyBzdXBlciBjbGFzcyhlcyksIHNvIHdlXG4gICAgICAgICAgLy8gY2FuIHN0b3AgbWVyZ2luZyBmaWVsZHMgZnJvbSBzdXBlciBjbGFzc2VzLiBIb3dldmVyIHdlIG5lZWQgdG8gaXRlcmF0ZSB0aHJvdWdoIHRoZVxuICAgICAgICAgIC8vIHByb3RvdHlwZSBjaGFpbiB0byBsb29rIGZvciBjbGFzc2VzIHRoYXQgbWlnaHQgY29udGFpbiBvdGhlciBcImZlYXR1cmVzXCIgKGxpa2VcbiAgICAgICAgICAvLyBOZ09uQ2hhbmdlcyksIHdoaWNoIHdlIHNob3VsZCBpbnZva2UgZm9yIHRoZSBvcmlnaW5hbCBgZGVmaW5pdGlvbmAuIFdlIHNldCB0aGVcbiAgICAgICAgICAvLyBgc2hvdWxkSW5oZXJpdEZpZWxkc2AgZmxhZyB0byBpbmRpY2F0ZSB0aGF0LCBlc3NlbnRpYWxseSBza2lwcGluZyBmaWVsZHMgaW5oZXJpdGFuY2VcbiAgICAgICAgICAvLyBsb2dpYyBhbmQgb25seSBpbnZva2luZyBmdW5jdGlvbnMgZnJvbSB0aGUgXCJmZWF0dXJlc1wiIGxpc3QuXG4gICAgICAgICAgaWYgKGZlYXR1cmUgPT09IMm1ybVJbmhlcml0RGVmaW5pdGlvbkZlYXR1cmUpIHtcbiAgICAgICAgICAgIHNob3VsZEluaGVyaXRGaWVsZHMgPSBmYWxzZTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICBzdXBlclR5cGUgPSBPYmplY3QuZ2V0UHJvdG90eXBlT2Yoc3VwZXJUeXBlKTtcbiAgfVxuICBtZXJnZUhvc3RBdHRyc0Fjcm9zc0luaGVyaXRhbmNlKGluaGVyaXRhbmNlQ2hhaW4pO1xufVxuXG4vKipcbiAqIE1lcmdlIHRoZSBgaG9zdEF0dHJzYCBhbmQgYGhvc3RWYXJzYCBmcm9tIHRoZSBpbmhlcml0ZWQgcGFyZW50IHRvIHRoZSBiYXNlIGNsYXNzLlxuICpcbiAqIEBwYXJhbSBpbmhlcml0YW5jZUNoYWluIEEgbGlzdCBvZiBgV3JpdGFibGVEZWZzYCBzdGFydGluZyBhdCB0aGUgdG9wIG1vc3QgdHlwZSBhbmQgbGlzdGluZ1xuICogc3ViLXR5cGVzIGluIG9yZGVyLiBGb3IgZWFjaCB0eXBlIHRha2UgdGhlIGBob3N0QXR0cnNgIGFuZCBgaG9zdFZhcnNgIGFuZCBtZXJnZSBpdCB3aXRoIHRoZSBjaGlsZFxuICogdHlwZS5cbiAqL1xuZnVuY3Rpb24gbWVyZ2VIb3N0QXR0cnNBY3Jvc3NJbmhlcml0YW5jZShpbmhlcml0YW5jZUNoYWluOiBXcml0YWJsZURlZltdKSB7XG4gIGxldCBob3N0VmFyczogbnVtYmVyID0gMDtcbiAgbGV0IGhvc3RBdHRyczogVEF0dHJpYnV0ZXN8bnVsbCA9IG51bGw7XG4gIC8vIFdlIHByb2Nlc3MgdGhlIGluaGVyaXRhbmNlIG9yZGVyIGZyb20gdGhlIGJhc2UgdG8gdGhlIGxlYXZlcyBoZXJlLlxuICBmb3IgKGxldCBpID0gaW5oZXJpdGFuY2VDaGFpbi5sZW5ndGggLSAxOyBpID49IDA7IGktLSkge1xuICAgIGNvbnN0IGRlZiA9IGluaGVyaXRhbmNlQ2hhaW5baV07XG4gICAgLy8gRm9yIGVhY2ggYGhvc3RWYXJzYCwgd2UgbmVlZCB0byBhZGQgdGhlIHN1cGVyY2xhc3MgYW1vdW50LlxuICAgIGRlZi5ob3N0VmFycyA9IChob3N0VmFycyArPSBkZWYuaG9zdFZhcnMpO1xuICAgIC8vIGZvciBlYWNoIGBob3N0QXR0cnNgIHdlIG5lZWQgdG8gbWVyZ2UgaXQgd2l0aCBzdXBlcmNsYXNzLlxuICAgIGRlZi5ob3N0QXR0cnMgPVxuICAgICAgICBtZXJnZUhvc3RBdHRycyhkZWYuaG9zdEF0dHJzLCBob3N0QXR0cnMgPSBtZXJnZUhvc3RBdHRycyhob3N0QXR0cnMsIGRlZi5ob3N0QXR0cnMpKTtcbiAgfVxufVxuXG5mdW5jdGlvbiBtYXliZVVud3JhcEVtcHR5PFQ+KHZhbHVlOiBUW10pOiBUW107XG5mdW5jdGlvbiBtYXliZVVud3JhcEVtcHR5PFQ+KHZhbHVlOiBUKTogVDtcbmZ1bmN0aW9uIG1heWJlVW53cmFwRW1wdHkodmFsdWU6IGFueSk6IGFueSB7XG4gIGlmICh2YWx1ZSA9PT0gRU1QVFlfT0JKKSB7XG4gICAgcmV0dXJuIHt9O1xuICB9IGVsc2UgaWYgKHZhbHVlID09PSBFTVBUWV9BUlJBWSkge1xuICAgIHJldHVybiBbXTtcbiAgfSBlbHNlIHtcbiAgICByZXR1cm4gdmFsdWU7XG4gIH1cbn1cblxuZnVuY3Rpb24gaW5oZXJpdFZpZXdRdWVyeShkZWZpbml0aW9uOiBXcml0YWJsZURlZiwgc3VwZXJWaWV3UXVlcnk6IFZpZXdRdWVyaWVzRnVuY3Rpb248YW55Pikge1xuICBjb25zdCBwcmV2Vmlld1F1ZXJ5ID0gZGVmaW5pdGlvbi52aWV3UXVlcnk7XG4gIGlmIChwcmV2Vmlld1F1ZXJ5KSB7XG4gICAgZGVmaW5pdGlvbi52aWV3UXVlcnkgPSAocmYsIGN0eCkgPT4ge1xuICAgICAgc3VwZXJWaWV3UXVlcnkocmYsIGN0eCk7XG4gICAgICBwcmV2Vmlld1F1ZXJ5KHJmLCBjdHgpO1xuICAgIH07XG4gIH0gZWxzZSB7XG4gICAgZGVmaW5pdGlvbi52aWV3UXVlcnkgPSBzdXBlclZpZXdRdWVyeTtcbiAgfVxufVxuXG5mdW5jdGlvbiBpbmhlcml0Q29udGVudFF1ZXJpZXMoXG4gICAgZGVmaW5pdGlvbjogV3JpdGFibGVEZWYsIHN1cGVyQ29udGVudFF1ZXJpZXM6IENvbnRlbnRRdWVyaWVzRnVuY3Rpb248YW55Pikge1xuICBjb25zdCBwcmV2Q29udGVudFF1ZXJpZXMgPSBkZWZpbml0aW9uLmNvbnRlbnRRdWVyaWVzO1xuICBpZiAocHJldkNvbnRlbnRRdWVyaWVzKSB7XG4gICAgZGVmaW5pdGlvbi5jb250ZW50UXVlcmllcyA9IChyZiwgY3R4LCBkaXJlY3RpdmVJbmRleCkgPT4ge1xuICAgICAgc3VwZXJDb250ZW50UXVlcmllcyhyZiwgY3R4LCBkaXJlY3RpdmVJbmRleCk7XG4gICAgICBwcmV2Q29udGVudFF1ZXJpZXMocmYsIGN0eCwgZGlyZWN0aXZlSW5kZXgpO1xuICAgIH07XG4gIH0gZWxzZSB7XG4gICAgZGVmaW5pdGlvbi5jb250ZW50UXVlcmllcyA9IHN1cGVyQ29udGVudFF1ZXJpZXM7XG4gIH1cbn1cblxuZnVuY3Rpb24gaW5oZXJpdEhvc3RCaW5kaW5ncyhcbiAgICBkZWZpbml0aW9uOiBXcml0YWJsZURlZiwgc3VwZXJIb3N0QmluZGluZ3M6IEhvc3RCaW5kaW5nc0Z1bmN0aW9uPGFueT4pIHtcbiAgY29uc3QgcHJldkhvc3RCaW5kaW5ncyA9IGRlZmluaXRpb24uaG9zdEJpbmRpbmdzO1xuICBpZiAocHJldkhvc3RCaW5kaW5ncykge1xuICAgIGRlZmluaXRpb24uaG9zdEJpbmRpbmdzID0gKHJmOiBSZW5kZXJGbGFncywgY3R4OiBhbnkpID0+IHtcbiAgICAgIHN1cGVySG9zdEJpbmRpbmdzKHJmLCBjdHgpO1xuICAgICAgcHJldkhvc3RCaW5kaW5ncyhyZiwgY3R4KTtcbiAgICB9O1xuICB9IGVsc2Uge1xuICAgIGRlZmluaXRpb24uaG9zdEJpbmRpbmdzID0gc3VwZXJIb3N0QmluZGluZ3M7XG4gIH1cbn1cbiJdfQ==