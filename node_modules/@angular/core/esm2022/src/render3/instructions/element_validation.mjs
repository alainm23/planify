/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { formatRuntimeError, RuntimeError } from '../../errors';
import { CUSTOM_ELEMENTS_SCHEMA, NO_ERRORS_SCHEMA } from '../../metadata/schema';
import { throwError } from '../../util/assert';
import { getComponentDef } from '../definition';
import { CONTEXT, DECLARATION_COMPONENT_VIEW } from '../interfaces/view';
import { isAnimationProp } from '../util/attrs_utils';
let shouldThrowErrorOnUnknownElement = false;
/**
 * Sets a strict mode for JIT-compiled components to throw an error on unknown elements,
 * instead of just logging the error.
 * (for AOT-compiled ones this check happens at build time).
 */
export function ɵsetUnknownElementStrictMode(shouldThrow) {
    shouldThrowErrorOnUnknownElement = shouldThrow;
}
/**
 * Gets the current value of the strict mode.
 */
export function ɵgetUnknownElementStrictMode() {
    return shouldThrowErrorOnUnknownElement;
}
let shouldThrowErrorOnUnknownProperty = false;
/**
 * Sets a strict mode for JIT-compiled components to throw an error on unknown properties,
 * instead of just logging the error.
 * (for AOT-compiled ones this check happens at build time).
 */
export function ɵsetUnknownPropertyStrictMode(shouldThrow) {
    shouldThrowErrorOnUnknownProperty = shouldThrow;
}
/**
 * Gets the current value of the strict mode.
 */
export function ɵgetUnknownPropertyStrictMode() {
    return shouldThrowErrorOnUnknownProperty;
}
/**
 * Validates that the element is known at runtime and produces
 * an error if it's not the case.
 * This check is relevant for JIT-compiled components (for AOT-compiled
 * ones this check happens at build time).
 *
 * The element is considered known if either:
 * - it's a known HTML element
 * - it's a known custom element
 * - the element matches any directive
 * - the element is allowed by one of the schemas
 *
 * @param element Element to validate
 * @param lView An `LView` that represents a current component that is being rendered
 * @param tagName Name of the tag to check
 * @param schemas Array of schemas
 * @param hasDirectives Boolean indicating that the element matches any directive
 */
export function validateElementIsKnown(element, lView, tagName, schemas, hasDirectives) {
    // If `schemas` is set to `null`, that's an indication that this Component was compiled in AOT
    // mode where this check happens at compile time. In JIT mode, `schemas` is always present and
    // defined as an array (as an empty array in case `schemas` field is not defined) and we should
    // execute the check below.
    if (schemas === null)
        return;
    // If the element matches any directive, it's considered as valid.
    if (!hasDirectives && tagName !== null) {
        // The element is unknown if it's an instance of HTMLUnknownElement, or it isn't registered
        // as a custom element. Note that unknown elements with a dash in their name won't be instances
        // of HTMLUnknownElement in browsers that support web components.
        const isUnknown = 
        // Note that we can't check for `typeof HTMLUnknownElement === 'function'` because
        // Domino doesn't expose HTMLUnknownElement globally.
        (typeof HTMLUnknownElement !== 'undefined' && HTMLUnknownElement &&
            element instanceof HTMLUnknownElement) ||
            (typeof customElements !== 'undefined' && tagName.indexOf('-') > -1 &&
                !customElements.get(tagName));
        if (isUnknown && !matchingSchemas(schemas, tagName)) {
            const isHostStandalone = isHostComponentStandalone(lView);
            const templateLocation = getTemplateLocationDetails(lView);
            const schemas = `'${isHostStandalone ? '@Component' : '@NgModule'}.schemas'`;
            let message = `'${tagName}' is not a known element${templateLocation}:\n`;
            message += `1. If '${tagName}' is an Angular component, then verify that it is ${isHostStandalone ? 'included in the \'@Component.imports\' of this component' :
                'a part of an @NgModule where this component is declared'}.\n`;
            if (tagName && tagName.indexOf('-') > -1) {
                message +=
                    `2. If '${tagName}' is a Web Component then add 'CUSTOM_ELEMENTS_SCHEMA' to the ${schemas} of this component to suppress this message.`;
            }
            else {
                message +=
                    `2. To allow any element add 'NO_ERRORS_SCHEMA' to the ${schemas} of this component.`;
            }
            if (shouldThrowErrorOnUnknownElement) {
                throw new RuntimeError(304 /* RuntimeErrorCode.UNKNOWN_ELEMENT */, message);
            }
            else {
                console.error(formatRuntimeError(304 /* RuntimeErrorCode.UNKNOWN_ELEMENT */, message));
            }
        }
    }
}
/**
 * Validates that the property of the element is known at runtime and returns
 * false if it's not the case.
 * This check is relevant for JIT-compiled components (for AOT-compiled
 * ones this check happens at build time).
 *
 * The property is considered known if either:
 * - it's a known property of the element
 * - the element is allowed by one of the schemas
 * - the property is used for animations
 *
 * @param element Element to validate
 * @param propName Name of the property to check
 * @param tagName Name of the tag hosting the property
 * @param schemas Array of schemas
 */
export function isPropertyValid(element, propName, tagName, schemas) {
    // If `schemas` is set to `null`, that's an indication that this Component was compiled in AOT
    // mode where this check happens at compile time. In JIT mode, `schemas` is always present and
    // defined as an array (as an empty array in case `schemas` field is not defined) and we should
    // execute the check below.
    if (schemas === null)
        return true;
    // The property is considered valid if the element matches the schema, it exists on the element,
    // or it is synthetic, and we are in a browser context (web worker nodes should be skipped).
    if (matchingSchemas(schemas, tagName) || propName in element || isAnimationProp(propName)) {
        return true;
    }
    // Note: `typeof Node` returns 'function' in most browsers, but is undefined with domino.
    return typeof Node === 'undefined' || Node === null || !(element instanceof Node);
}
/**
 * Logs or throws an error that a property is not supported on an element.
 *
 * @param propName Name of the invalid property
 * @param tagName Name of the tag hosting the property
 * @param nodeType Type of the node hosting the property
 * @param lView An `LView` that represents a current component
 */
export function handleUnknownPropertyError(propName, tagName, nodeType, lView) {
    // Special-case a situation when a structural directive is applied to
    // an `<ng-template>` element, for example: `<ng-template *ngIf="true">`.
    // In this case the compiler generates the `ɵɵtemplate` instruction with
    // the `null` as the tagName. The directive matching logic at runtime relies
    // on this effect (see `isInlineTemplate`), thus using the 'ng-template' as
    // a default value of the `tNode.value` is not feasible at this moment.
    if (!tagName && nodeType === 4 /* TNodeType.Container */) {
        tagName = 'ng-template';
    }
    const isHostStandalone = isHostComponentStandalone(lView);
    const templateLocation = getTemplateLocationDetails(lView);
    let message = `Can't bind to '${propName}' since it isn't a known property of '${tagName}'${templateLocation}.`;
    const schemas = `'${isHostStandalone ? '@Component' : '@NgModule'}.schemas'`;
    const importLocation = isHostStandalone ?
        'included in the \'@Component.imports\' of this component' :
        'a part of an @NgModule where this component is declared';
    if (KNOWN_CONTROL_FLOW_DIRECTIVES.has(propName)) {
        // Most likely this is a control flow directive (such as `*ngIf`) used in
        // a template, but the directive or the `CommonModule` is not imported.
        const correspondingImport = KNOWN_CONTROL_FLOW_DIRECTIVES.get(propName);
        message += `\nIf the '${propName}' is an Angular control flow directive, ` +
            `please make sure that either the '${correspondingImport}' directive or the 'CommonModule' is ${importLocation}.`;
    }
    else {
        // May be an Angular component, which is not imported/declared?
        message += `\n1. If '${tagName}' is an Angular component and it has the ` +
            `'${propName}' input, then verify that it is ${importLocation}.`;
        // May be a Web Component?
        if (tagName && tagName.indexOf('-') > -1) {
            message += `\n2. If '${tagName}' is a Web Component then add 'CUSTOM_ELEMENTS_SCHEMA' ` +
                `to the ${schemas} of this component to suppress this message.`;
            message += `\n3. To allow any property add 'NO_ERRORS_SCHEMA' to ` +
                `the ${schemas} of this component.`;
        }
        else {
            // If it's expected, the error can be suppressed by the `NO_ERRORS_SCHEMA` schema.
            message += `\n2. To allow any property add 'NO_ERRORS_SCHEMA' to ` +
                `the ${schemas} of this component.`;
        }
    }
    reportUnknownPropertyError(message);
}
export function reportUnknownPropertyError(message) {
    if (shouldThrowErrorOnUnknownProperty) {
        throw new RuntimeError(303 /* RuntimeErrorCode.UNKNOWN_BINDING */, message);
    }
    else {
        console.error(formatRuntimeError(303 /* RuntimeErrorCode.UNKNOWN_BINDING */, message));
    }
}
/**
 * WARNING: this is a **dev-mode only** function (thus should always be guarded by the `ngDevMode`)
 * and must **not** be used in production bundles. The function makes megamorphic reads, which might
 * be too slow for production mode and also it relies on the constructor function being available.
 *
 * Gets a reference to the host component def (where a current component is declared).
 *
 * @param lView An `LView` that represents a current component that is being rendered.
 */
export function getDeclarationComponentDef(lView) {
    !ngDevMode && throwError('Must never be called in production mode');
    const declarationLView = lView[DECLARATION_COMPONENT_VIEW];
    const context = declarationLView[CONTEXT];
    // Unable to obtain a context.
    if (!context)
        return null;
    return context.constructor ? getComponentDef(context.constructor) : null;
}
/**
 * WARNING: this is a **dev-mode only** function (thus should always be guarded by the `ngDevMode`)
 * and must **not** be used in production bundles. The function makes megamorphic reads, which might
 * be too slow for production mode.
 *
 * Checks if the current component is declared inside of a standalone component template.
 *
 * @param lView An `LView` that represents a current component that is being rendered.
 */
export function isHostComponentStandalone(lView) {
    !ngDevMode && throwError('Must never be called in production mode');
    const componentDef = getDeclarationComponentDef(lView);
    // Treat host component as non-standalone if we can't obtain the def.
    return !!componentDef?.standalone;
}
/**
 * WARNING: this is a **dev-mode only** function (thus should always be guarded by the `ngDevMode`)
 * and must **not** be used in production bundles. The function makes megamorphic reads, which might
 * be too slow for production mode.
 *
 * Constructs a string describing the location of the host component template. The function is used
 * in dev mode to produce error messages.
 *
 * @param lView An `LView` that represents a current component that is being rendered.
 */
export function getTemplateLocationDetails(lView) {
    !ngDevMode && throwError('Must never be called in production mode');
    const hostComponentDef = getDeclarationComponentDef(lView);
    const componentClassName = hostComponentDef?.type?.name;
    return componentClassName ? ` (used in the '${componentClassName}' component template)` : '';
}
/**
 * The set of known control flow directives and their corresponding imports.
 * We use this set to produce a more precises error message with a note
 * that the `CommonModule` should also be included.
 */
export const KNOWN_CONTROL_FLOW_DIRECTIVES = new Map([
    ['ngIf', 'NgIf'], ['ngFor', 'NgFor'], ['ngSwitchCase', 'NgSwitchCase'],
    ['ngSwitchDefault', 'NgSwitchDefault']
]);
/**
 * Returns true if the tag name is allowed by specified schemas.
 * @param schemas Array of schemas
 * @param tagName Name of the tag
 */
export function matchingSchemas(schemas, tagName) {
    if (schemas !== null) {
        for (let i = 0; i < schemas.length; i++) {
            const schema = schemas[i];
            if (schema === NO_ERRORS_SCHEMA ||
                schema === CUSTOM_ELEMENTS_SCHEMA && tagName && tagName.indexOf('-') > -1) {
                return true;
            }
        }
    }
    return false;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZWxlbWVudF92YWxpZGF0aW9uLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9pbnN0cnVjdGlvbnMvZWxlbWVudF92YWxpZGF0aW9uLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxrQkFBa0IsRUFBRSxZQUFZLEVBQW1CLE1BQU0sY0FBYyxDQUFDO0FBRWhGLE9BQU8sRUFBQyxzQkFBc0IsRUFBRSxnQkFBZ0IsRUFBaUIsTUFBTSx1QkFBdUIsQ0FBQztBQUMvRixPQUFPLEVBQUMsVUFBVSxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDN0MsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLGVBQWUsQ0FBQztBQUk5QyxPQUFPLEVBQUMsT0FBTyxFQUFFLDBCQUEwQixFQUFRLE1BQU0sb0JBQW9CLENBQUM7QUFDOUUsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBRXBELElBQUksZ0NBQWdDLEdBQUcsS0FBSyxDQUFDO0FBRTdDOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsNEJBQTRCLENBQUMsV0FBb0I7SUFDL0QsZ0NBQWdDLEdBQUcsV0FBVyxDQUFDO0FBQ2pELENBQUM7QUFFRDs7R0FFRztBQUNILE1BQU0sVUFBVSw0QkFBNEI7SUFDMUMsT0FBTyxnQ0FBZ0MsQ0FBQztBQUMxQyxDQUFDO0FBRUQsSUFBSSxpQ0FBaUMsR0FBRyxLQUFLLENBQUM7QUFFOUM7Ozs7R0FJRztBQUNILE1BQU0sVUFBVSw2QkFBNkIsQ0FBQyxXQUFvQjtJQUNoRSxpQ0FBaUMsR0FBRyxXQUFXLENBQUM7QUFDbEQsQ0FBQztBQUVEOztHQUVHO0FBQ0gsTUFBTSxVQUFVLDZCQUE2QjtJQUMzQyxPQUFPLGlDQUFpQyxDQUFDO0FBQzNDLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7Ozs7R0FpQkc7QUFDSCxNQUFNLFVB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S0FBSyxDQUFDO0FBQ2YsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge2Zvcm1hdFJ1bnRpbWVFcnJvciwgUnVudGltZUVycm9yLCBSdW50aW1lRXJyb3JDb2RlfSBmcm9tICcuLi8uLi9lcnJvcnMnO1xuaW1wb3J0IHtUeXBlfSBmcm9tICcuLi8uLi9pbnRlcmZhY2UvdHlwZSc7XG5pbXBvcnQge0NVU1RPTV9FTEVNRU5UU19TQ0hFTUEsIE5PX0VSUk9SU19TQ0hFTUEsIFNjaGVtYU1ldGFkYXRhfSBmcm9tICcuLi8uLi9tZXRhZGF0YS9zY2hlbWEnO1xuaW1wb3J0IHt0aHJvd0Vycm9yfSBmcm9tICcuLi8uLi91dGlsL2Fzc2VydCc7XG5pbXBvcnQge2dldENvbXBvbmVudERlZn0gZnJvbSAnLi4vZGVmaW5pdGlvbic7XG5pbXBvcnQge0NvbXBvbmVudERlZn0gZnJvbSAnLi4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7VE5vZGVUeXBlfSBmcm9tICcuLi9pbnRlcmZhY2VzL25vZGUnO1xuaW1wb3J0IHtSQ29tbWVudCwgUkVsZW1lbnR9IGZyb20gJy4uL2ludGVyZmFjZXMvcmVuZGVyZXJfZG9tJztcbmltcG9ydCB7Q09OVEVYVCwgREVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVcsIExWaWV3fSBmcm9tICcuLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtpc0FuaW1hdGlvblByb3B9IGZyb20gJy4uL3V0aWwvYXR0cnNfdXRpbHMnO1xuXG5sZXQgc2hvdWxkVGhyb3dFcnJvck9uVW5rbm93bkVsZW1lbnQgPSBmYWxzZTtcblxuLyoqXG4gKiBTZXRzIGEgc3RyaWN0IG1vZGUgZm9yIEpJVC1jb21waWxlZCBjb21wb25lbnRzIHRvIHRocm93IGFuIGVycm9yIG9uIHVua25vd24gZWxlbWVudHMsXG4gKiBpbnN0ZWFkIG9mIGp1c3QgbG9nZ2luZyB0aGUgZXJyb3IuXG4gKiAoZm9yIEFPVC1jb21waWxlZCBvbmVzIHRoaXMgY2hlY2sgaGFwcGVucyBhdCBidWlsZCB0aW1lKS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1c2V0VW5rbm93bkVsZW1lbnRTdHJpY3RNb2RlKHNob3VsZFRocm93OiBib29sZWFuKSB7XG4gIHNob3VsZFRocm93RXJyb3JPblVua25vd25FbGVtZW50ID0gc2hvdWxkVGhyb3c7XG59XG5cbi8qKlxuICogR2V0cyB0aGUgY3VycmVudCB2YWx1ZSBvZiB0aGUgc3RyaWN0IG1vZGUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtWdldFVua25vd25FbGVtZW50U3RyaWN0TW9kZSgpIHtcbiAgcmV0dXJuIHNob3VsZFRocm93RXJyb3JPblVua25vd25FbGVtZW50O1xufVxuXG5sZXQgc2hvdWxkVGhyb3dFcnJvck9uVW5rbm93blByb3BlcnR5ID0gZmFsc2U7XG5cbi8qKlxuICogU2V0cyBhIHN0cmljdCBtb2RlIGZvciBKSVQtY29tcGlsZWQgY29tcG9uZW50cyB0byB0aHJvdyBhbiBlcnJvciBvbiB1bmtub3duIHByb3BlcnRpZXMsXG4gKiBpbnN0ZWFkIG9mIGp1c3QgbG9nZ2luZyB0aGUgZXJyb3IuXG4gKiAoZm9yIEFPVC1jb21waWxlZCBvbmVzIHRoaXMgY2hlY2sgaGFwcGVucyBhdCBidWlsZCB0aW1lKS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1c2V0VW5rbm93blByb3BlcnR5U3RyaWN0TW9kZShzaG91bGRUaHJvdzogYm9vbGVhbikge1xuICBzaG91bGRUaHJvd0Vycm9yT25Vbmtub3duUHJvcGVydHkgPSBzaG91bGRUaHJvdztcbn1cblxuLyoqXG4gKiBHZXRzIHRoZSBjdXJyZW50IHZhbHVlIG9mIHRoZSBzdHJpY3QgbW9kZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1Z2V0VW5rbm93blByb3BlcnR5U3RyaWN0TW9kZSgpIHtcbiAgcmV0dXJuIHNob3VsZFRocm93RXJyb3JPblVua25vd25Qcm9wZXJ0eTtcbn1cblxuLyoqXG4gKiBWYWxpZGF0ZXMgdGhhdCB0aGUgZWxlbWVudCBpcyBrbm93biBhdCBydW50aW1lIGFuZCBwcm9kdWNlc1xuICogYW4gZXJyb3IgaWYgaXQncyBub3QgdGhlIGNhc2UuXG4gKiBUaGlzIGNoZWNrIGlzIHJlbGV2YW50IGZvciBKSVQtY29tcGlsZWQgY29tcG9uZW50cyAoZm9yIEFPVC1jb21waWxlZFxuICogb25lcyB0aGlzIGNoZWNrIGhhcHBlbnMgYXQgYnVpbGQgdGltZSkuXG4gKlxuICogVGhlIGVsZW1lbnQgaXMgY29uc2lkZXJlZCBrbm93biBpZiBlaXRoZXI6XG4gKiAtIGl0J3MgYSBrbm93biBIVE1MIGVsZW1lbnRcbiAqIC0gaXQncyBhIGtub3duIGN1c3RvbSBlbGVtZW50XG4gKiAtIHRoZSBlbGVtZW50IG1hdGNoZXMgYW55IGRpcmVjdGl2ZVxuICogLSB0aGUgZWxlbWVudCBpcyBhbGxvd2VkIGJ5IG9uZSBvZiB0aGUgc2NoZW1hc1xuICpcbiAqIEBwYXJhbSBlbGVtZW50IEVsZW1lbnQgdG8gdmFsaWRhdGVcbiAqIEBwYXJhbSBsVmlldyBBbiBgTFZpZXdgIHRoYXQgcmVwcmVzZW50cyBhIGN1cnJlbnQgY29tcG9uZW50IHRoYXQgaXMgYmVpbmcgcmVuZGVyZWRcbiAqIEBwYXJhbSB0YWdOYW1lIE5hbWUgb2YgdGhlIHRhZyB0byBjaGVja1xuICogQHBhcmFtIHNjaGVtYXMgQXJyYXkgb2Ygc2NoZW1hc1xuICogQHBhcmFtIGhhc0RpcmVjdGl2ZXMgQm9vbGVhbiBpbmRpY2F0aW5nIHRoYXQgdGhlIGVsZW1lbnQgbWF0Y2hlcyBhbnkgZGlyZWN0aXZlXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB2YWxpZGF0ZUVsZW1lbnRJc0tub3duKFxuICAgIGVsZW1lbnQ6IFJFbGVtZW50LCBsVmlldzogTFZpZXcsIHRhZ05hbWU6IHN0cmluZ3xudWxsLCBzY2hlbWFzOiBTY2hlbWFNZXRhZGF0YVtdfG51bGwsXG4gICAgaGFzRGlyZWN0aXZlczogYm9vbGVhbik6IHZvaWQge1xuICAvLyBJZiBgc2NoZW1hc2AgaXMgc2V0IHRvIGBudWxsYCwgdGhhdCdzIGFuIGluZGljYXRpb24gdGhhdCB0aGlzIENvbXBvbmVudCB3YXMgY29tcGlsZWQgaW4gQU9UXG4gIC8vIG1vZGUgd2hlcmUgdGhpcyBjaGVjayBoYXBwZW5zIGF0IGNvbXBpbGUgdGltZS4gSW4gSklUIG1vZGUsIGBzY2hlbWFzYCBpcyBhbHdheXMgcHJlc2VudCBhbmRcbiAgLy8gZGVmaW5lZCBhcyBhbiBhcnJheSAoYXMgYW4gZW1wdHkgYXJyYXkgaW4gY2FzZSBgc2NoZW1hc2AgZmllbGQgaXMgbm90IGRlZmluZWQpIGFuZCB3ZSBzaG91bGRcbiAgLy8gZXhlY3V0ZSB0aGUgY2hlY2sgYmVsb3cuXG4gIGlmIChzY2hlbWFzID09PSBudWxsKSByZXR1cm47XG5cbiAgLy8gSWYgdGhlIGVsZW1lbnQgbWF0Y2hlcyBhbnkgZGlyZWN0aXZlLCBpdCdzIGNvbnNpZGVyZWQgYXMgdmFsaWQuXG4gIGlmICghaGFzRGlyZWN0aXZlcyAmJiB0YWdOYW1lICE9PSBudWxsKSB7XG4gICAgLy8gVGhlIGVsZW1lbnQgaXMgdW5rbm93biBpZiBpdCdzIGFuIGluc3RhbmNlIG9mIEhUTUxVbmtub3duRWxlbWVudCwgb3IgaXQgaXNuJ3QgcmVnaXN0ZXJlZFxuICAgIC8vIGFzIGEgY3VzdG9tIGVsZW1lbnQuIE5vdGUgdGhhdCB1bmtub3duIGVsZW1lbnRzIHdpdGggYSBkYXNoIGluIHRoZWlyIG5hbWUgd29uJ3QgYmUgaW5zdGFuY2VzXG4gICAgLy8gb2YgSFRNTFVua25vd25FbGVtZW50IGluIGJyb3dzZXJzIHRoYXQgc3VwcG9ydCB3ZWIgY29tcG9uZW50cy5cbiAgICBjb25zdCBpc1Vua25vd24gPVxuICAgICAgICAvLyBOb3RlIHRoYXQgd2UgY2FuJ3QgY2hlY2sgZm9yIGB0eXBlb2YgSFRNTFVua25vd25FbGVtZW50ID09PSAnZnVuY3Rpb24nYCBiZWNhdXNlXG4gICAgICAgIC8vIERvbWlubyBkb2Vzbid0IGV4cG9zZSBIVE1MVW5rbm93bkVsZW1lbnQgZ2xvYmFsbHkuXG4gICAgICAgICh0eXBlb2YgSFRNTFVua25vd25FbGVtZW50ICE9PSAndW5kZWZpbmVkJyAmJiBIVE1MVW5rbm93bkVsZW1lbnQgJiZcbiAgICAgICAgIGVsZW1lbnQgaW5zdGFuY2VvZiBIVE1MVW5rbm93bkVsZW1lbnQpIHx8XG4gICAgICAgICh0eXBlb2YgY3VzdG9tRWxlbWVudHMgIT09ICd1bmRlZmluZWQnICYmIHRhZ05hbWUuaW5kZXhPZignLScpID4gLTEgJiZcbiAgICAgICAgICFjdXN0b21FbGVtZW50cy5nZXQodGFnTmFtZSkpO1xuXG4gICAgaWYgKGlzVW5rbm93biAmJiAhbWF0Y2hpbmdTY2hlbWFzKHNjaGVtYXMsIHRhZ05hbWUpKSB7XG4gICAgICBjb25zdCBpc0hvc3RTdGFuZGFsb25lID0gaXNIb3N0Q29tcG9uZW50U3RhbmRhbG9uZShsVmlldyk7XG4gICAgICBjb25zdCB0ZW1wbGF0ZUxvY2F0aW9uID0gZ2V0VGVtcGxhdGVMb2NhdGlvbkRldGFpbHMobFZpZXcpO1xuICAgICAgY29uc3Qgc2NoZW1hcyA9IGAnJHtpc0hvc3RTdGFuZGFsb25lID8gJ0BDb21wb25lbnQnIDogJ0BOZ01vZHVsZSd9LnNjaGVtYXMnYDtcblxuICAgICAgbGV0IG1lc3NhZ2UgPSBgJyR7dGFnTmFtZX0nIGlzIG5vdCBhIGtub3duIGVsZW1lbnQke3RlbXBsYXRlTG9jYXRpb259OlxcbmA7XG4gICAgICBtZXNzYWdlICs9IGAxLiBJZiAnJHt0YWdOYW1lfScgaXMgYW4gQW5ndWxhciBjb21wb25lbnQsIHRoZW4gdmVyaWZ5IHRoYXQgaXQgaXMgJHtcbiAgICAgICAgICBpc0hvc3RTdGFuZGFsb25lID8gJ2luY2x1ZGVkIGluIHRoZSBcXCdAQ29tcG9uZW50LmltcG9ydHNcXCcgb2YgdGhpcyBjb21wb25lbnQnIDpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2EgcGFydCBvZiBhbiBATmdNb2R1bGUgd2hlcmUgdGhpcyBjb21wb25lbnQgaXMgZGVjbGFyZWQnfS5cXG5gO1xuICAgICAgaWYgKHRhZ05hbWUgJiYgdGFnTmFtZS5pbmRleE9mKCctJykgPiAtMSkge1xuICAgICAgICBtZXNzYWdlICs9XG4gICAgICAgICAgICBgMi4gSWYgJyR7dGFnTmFtZX0nIGlzIGEgV2ViIENvbXBvbmVudCB0aGVuIGFkZCAnQ1VTVE9NX0VMRU1FTlRTX1NDSEVNQScgdG8gdGhlICR7XG4gICAgICAgICAgICAgICAgc2NoZW1hc30gb2YgdGhpcyBjb21wb25lbnQgdG8gc3VwcHJlc3MgdGhpcyBtZXNzYWdlLmA7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBtZXNzYWdlICs9XG4gICAgICAgICAgICBgMi4gVG8gYWxsb3cgYW55IGVsZW1lbnQgYWRkICdOT19FUlJPUlNfU0NIRU1BJyB0byB0aGUgJHtzY2hlbWFzfSBvZiB0aGlzIGNvbXBvbmVudC5gO1xuICAgICAgfVxuICAgICAgaWYgKHNob3VsZFRocm93RXJyb3JPblVua25vd25FbGVtZW50KSB7XG4gICAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoUnVudGltZUVycm9yQ29kZS5VTktOT1dOX0VMRU1FTlQsIG1lc3NhZ2UpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY29uc29sZS5lcnJvcihmb3JtYXRSdW50aW1lRXJyb3IoUnVudGltZUVycm9yQ29kZS5VTktOT1dOX0VMRU1FTlQsIG1lc3NhZ2UpKTtcbiAgICAgIH1cbiAgICB9XG4gIH1cbn1cblxuLyoqXG4gKiBWYWxpZGF0ZXMgdGhhdCB0aGUgcHJvcGVydHkgb2YgdGhlIGVsZW1lbnQgaXMga25vd24gYXQgcnVudGltZSBhbmQgcmV0dXJuc1xuICogZmFsc2UgaWYgaXQncyBub3QgdGhlIGNhc2UuXG4gKiBUaGlzIGNoZWNrIGlzIHJlbGV2YW50IGZvciBKSVQtY29tcGlsZWQgY29tcG9uZW50cyAoZm9yIEFPVC1jb21waWxlZFxuICogb25lcyB0aGlzIGNoZWNrIGhhcHBlbnMgYXQgYnVpbGQgdGltZSkuXG4gKlxuICogVGhlIHByb3BlcnR5IGlzIGNvbnNpZGVyZWQga25vd24gaWYgZWl0aGVyOlxuICogLSBpdCdzIGEga25vd24gcHJvcGVydHkgb2YgdGhlIGVsZW1lbnRcbiAqIC0gdGhlIGVsZW1lbnQgaXMgYWxsb3dlZCBieSBvbmUgb2YgdGhlIHNjaGVtYXNcbiAqIC0gdGhlIHByb3BlcnR5IGlzIHVzZWQgZm9yIGFuaW1hdGlvbnNcbiAqXG4gKiBAcGFyYW0gZWxlbWVudCBFbGVtZW50IHRvIHZhbGlkYXRlXG4gKiBAcGFyYW0gcHJvcE5hbWUgTmFtZSBvZiB0aGUgcHJvcGVydHkgdG8gY2hlY2tcbiAqIEBwYXJhbSB0YWdOYW1lIE5hbWUgb2YgdGhlIHRhZyBob3N0aW5nIHRoZSBwcm9wZXJ0eVxuICogQHBhcmFtIHNjaGVtYXMgQXJyYXkgb2Ygc2NoZW1hc1xuICovXG5leHBvcnQgZnVuY3Rpb24gaXNQcm9wZXJ0eVZhbGlkKFxuICAgIGVsZW1lbnQ6IFJFbGVtZW50fFJDb21tZW50LCBwcm9wTmFtZTogc3RyaW5nLCB0YWdOYW1lOiBzdHJpbmd8bnVsbCxcbiAgICBzY2hlbWFzOiBTY2hlbWFNZXRhZGF0YVtdfG51bGwpOiBib29sZWFuIHtcbiAgLy8gSWYgYHNjaGVtYXNgIGlzIHNldCB0byBgbnVsbGAsIHRoYXQncyBhbiBpbmRpY2F0aW9uIHRoYXQgdGhpcyBDb21wb25lbnQgd2FzIGNvbXBpbGVkIGluIEFPVFxuICAvLyBtb2RlIHdoZXJlIHRoaXMgY2hlY2sgaGFwcGVucyBhdCBjb21waWxlIHRpbWUuIEluIEpJVCBtb2RlLCBgc2NoZW1hc2AgaXMgYWx3YXlzIHByZXNlbnQgYW5kXG4gIC8vIGRlZmluZWQgYXMgYW4gYXJyYXkgKGFzIGFuIGVtcHR5IGFycmF5IGluIGNhc2UgYHNjaGVtYXNgIGZpZWxkIGlzIG5vdCBkZWZpbmVkKSBhbmQgd2Ugc2hvdWxkXG4gIC8vIGV4ZWN1dGUgdGhlIGNoZWNrIGJlbG93LlxuICBpZiAoc2NoZW1hcyA9PT0gbnVsbCkgcmV0dXJuIHRydWU7XG5cbiAgLy8gVGhlIHByb3BlcnR5IGlzIGNvbnNpZGVyZWQgdmFsaWQgaWYgdGhlIGVsZW1lbnQgbWF0Y2hlcyB0aGUgc2NoZW1hLCBpdCBleGlzdHMgb24gdGhlIGVsZW1lbnQsXG4gIC8vIG9yIGl0IGlzIHN5bnRoZXRpYywgYW5kIHdlIGFyZSBpbiBhIGJyb3dzZXIgY29udGV4dCAod2ViIHdvcmtlciBub2RlcyBzaG91bGQgYmUgc2tpcHBlZCkuXG4gIGlmIChtYXRjaGluZ1NjaGVtYXMoc2NoZW1hcywgdGFnTmFtZSkgfHwgcHJvcE5hbWUgaW4gZWxlbWVudCB8fCBpc0FuaW1hdGlvblByb3AocHJvcE5hbWUpKSB7XG4gICAgcmV0dXJuIHRydWU7XG4gIH1cblxuICAvLyBOb3RlOiBgdHlwZW9mIE5vZGVgIHJldHVybnMgJ2Z1bmN0aW9uJyBpbiBtb3N0IGJyb3dzZXJzLCBidXQgaXMgdW5kZWZpbmVkIHdpdGggZG9taW5vLlxuICByZXR1cm4gdHlwZW9mIE5vZGUgPT09ICd1bmRlZmluZWQnIHx8IE5vZGUgPT09IG51bGwgfHwgIShlbGVtZW50IGluc3RhbmNlb2YgTm9kZSk7XG59XG5cbi8qKlxuICogTG9ncyBvciB0aHJvd3MgYW4gZXJyb3IgdGhhdCBhIHByb3BlcnR5IGlzIG5vdCBzdXBwb3J0ZWQgb24gYW4gZWxlbWVudC5cbiAqXG4gKiBAcGFyYW0gcHJvcE5hbWUgTmFtZSBvZiB0aGUgaW52YWxpZCBwcm9wZXJ0eVxuICogQHBhcmFtIHRhZ05hbWUgTmFtZSBvZiB0aGUgdGFnIGhvc3RpbmcgdGhlIHByb3BlcnR5XG4gKiBAcGFyYW0gbm9kZVR5cGUgVHlwZSBvZiB0aGUgbm9kZSBob3N0aW5nIHRoZSBwcm9wZXJ0eVxuICogQHBhcmFtIGxWaWV3IEFuIGBMVmlld2AgdGhhdCByZXByZXNlbnRzIGEgY3VycmVudCBjb21wb25lbnRcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGhhbmRsZVVua25vd25Qcm9wZXJ0eUVycm9yKFxuICAgIHByb3BOYW1lOiBzdHJpbmcsIHRhZ05hbWU6IHN0cmluZ3xudWxsLCBub2RlVHlwZTogVE5vZGVUeXBlLCBsVmlldzogTFZpZXcpOiB2b2lkIHtcbiAgLy8gU3BlY2lhbC1jYXNlIGEgc2l0dWF0aW9uIHdoZW4gYSBzdHJ1Y3R1cmFsIGRpcmVjdGl2ZSBpcyBhcHBsaWVkIHRvXG4gIC8vIGFuIGA8bmctdGVtcGxhdGU+YCBlbGVtZW50LCBmb3IgZXhhbXBsZTogYDxuZy10ZW1wbGF0ZSAqbmdJZj1cInRydWVcIj5gLlxuICAvLyBJbiB0aGlzIGNhc2UgdGhlIGNvbXBpbGVyIGdlbmVyYXRlcyB0aGUgYMm1ybV0ZW1wbGF0ZWAgaW5zdHJ1Y3Rpb24gd2l0aFxuICAvLyB0aGUgYG51bGxgIGFzIHRoZSB0YWdOYW1lLiBUaGUgZGlyZWN0aXZlIG1hdGNoaW5nIGxvZ2ljIGF0IHJ1bnRpbWUgcmVsaWVzXG4gIC8vIG9uIHRoaXMgZWZmZWN0IChzZWUgYGlzSW5saW5lVGVtcGxhdGVgKSwgdGh1cyB1c2luZyB0aGUgJ25nLXRlbXBsYXRlJyBhc1xuICAvLyBhIGRlZmF1bHQgdmFsdWUgb2YgdGhlIGB0Tm9kZS52YWx1ZWAgaXMgbm90IGZlYXNpYmxlIGF0IHRoaXMgbW9tZW50LlxuICBpZiAoIXRhZ05hbWUgJiYgbm9kZVR5cGUgPT09IFROb2RlVHlwZS5Db250YWluZXIpIHtcbiAgICB0YWdOYW1lID0gJ25nLXRlbXBsYXRlJztcbiAgfVxuXG4gIGNvbnN0IGlzSG9zdFN0YW5kYWxvbmUgPSBpc0hvc3RDb21wb25lbnRTdGFuZGFsb25lKGxWaWV3KTtcbiAgY29uc3QgdGVtcGxhdGVMb2NhdGlvbiA9IGdldFRlbXBsYXRlTG9jYXRpb25EZXRhaWxzKGxWaWV3KTtcblxuICBsZXQgbWVzc2FnZSA9IGBDYW4ndCBiaW5kIHRvICcke3Byb3BOYW1lfScgc2luY2UgaXQgaXNuJ3QgYSBrbm93biBwcm9wZXJ0eSBvZiAnJHt0YWdOYW1lfScke1xuICAgICAgdGVtcGxhdGVMb2NhdGlvbn0uYDtcblxuICBjb25zdCBzY2hlbWFzID0gYCcke2lzSG9zdFN0YW5kYWxvbmUgPyAnQENvbXBvbmVudCcgOiAnQE5nTW9kdWxlJ30uc2NoZW1hcydgO1xuICBjb25zdCBpbXBvcnRMb2NhdGlvbiA9IGlzSG9zdFN0YW5kYWxvbmUgP1xuICAgICAgJ2luY2x1ZGVkIGluIHRoZSBcXCdAQ29tcG9uZW50LmltcG9ydHNcXCcgb2YgdGhpcyBjb21wb25lbnQnIDpcbiAgICAgICdhIHBhcnQgb2YgYW4gQE5nTW9kdWxlIHdoZXJlIHRoaXMgY29tcG9uZW50IGlzIGRlY2xhcmVkJztcbiAgaWYgKEtOT1dOX0NPTlRST0xfRkxPV19ESVJFQ1RJVkVTLmhhcyhwcm9wTmFtZSkpIHtcbiAgICAvLyBNb3N0IGxpa2VseSB0aGlzIGlzIGEgY29udHJvbCBmbG93IGRpcmVjdGl2ZSAoc3VjaCBhcyBgKm5nSWZgKSB1c2VkIGluXG4gICAgLy8gYSB0ZW1wbGF0ZSwgYnV0IHRoZSBkaXJlY3RpdmUgb3IgdGhlIGBDb21tb25Nb2R1bGVgIGlzIG5vdCBpbXBvcnRlZC5cbiAgICBjb25zdCBjb3JyZXNwb25kaW5nSW1wb3J0ID0gS05PV05fQ09OVFJPTF9GTE9XX0RJUkVDVElWRVMuZ2V0KHByb3BOYW1lKTtcbiAgICBtZXNzYWdlICs9IGBcXG5JZiB0aGUgJyR7cHJvcE5hbWV9JyBpcyBhbiBBbmd1bGFyIGNvbnRyb2wgZmxvdyBkaXJlY3RpdmUsIGAgK1xuICAgICAgICBgcGxlYXNlIG1ha2Ugc3VyZSB0aGF0IGVpdGhlciB0aGUgJyR7XG4gICAgICAgICAgICAgICAgICAgY29ycmVzcG9uZGluZ0ltcG9ydH0nIGRpcmVjdGl2ZSBvciB0aGUgJ0NvbW1vbk1vZHVsZScgaXMgJHtpbXBvcnRMb2NhdGlvbn0uYDtcbiAgfSBlbHNlIHtcbiAgICAvLyBNYXkgYmUgYW4gQW5ndWxhciBjb21wb25lbnQsIHdoaWNoIGlzIG5vdCBpbXBvcnRlZC9kZWNsYXJlZD9cbiAgICBtZXNzYWdlICs9IGBcXG4xLiBJZiAnJHt0YWdOYW1lfScgaXMgYW4gQW5ndWxhciBjb21wb25lbnQgYW5kIGl0IGhhcyB0aGUgYCArXG4gICAgICAgIGAnJHtwcm9wTmFtZX0nIGlucHV0LCB0aGVuIHZlcmlmeSB0aGF0IGl0IGlzICR7aW1wb3J0TG9jYXRpb259LmA7XG4gICAgLy8gTWF5IGJlIGEgV2ViIENvbXBvbmVudD9cbiAgICBpZiAodGFnTmFtZSAmJiB0YWdOYW1lLmluZGV4T2YoJy0nKSA+IC0xKSB7XG4gICAgICBtZXNzYWdlICs9IGBcXG4yLiBJZiAnJHt0YWdOYW1lfScgaXMgYSBXZWIgQ29tcG9uZW50IHRoZW4gYWRkICdDVVNUT01fRUxFTUVOVFNfU0NIRU1BJyBgICtcbiAgICAgICAgICBgdG8gdGhlICR7c2NoZW1hc30gb2YgdGhpcyBjb21wb25lbnQgdG8gc3VwcHJlc3MgdGhpcyBtZXNzYWdlLmA7XG4gICAgICBtZXNzYWdlICs9IGBcXG4zLiBUbyBhbGxvdyBhbnkgcHJvcGVydHkgYWRkICdOT19FUlJPUlNfU0NIRU1BJyB0byBgICtcbiAgICAgICAgICBgdGhlICR7c2NoZW1hc30gb2YgdGhpcyBjb21wb25lbnQuYDtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gSWYgaXQncyBleHBlY3RlZCwgdGhlIGVycm9yIGNhbiBiZSBzdXBwcmVzc2VkIGJ5IHRoZSBgTk9fRVJST1JTX1NDSEVNQWAgc2NoZW1hLlxuICAgICAgbWVzc2FnZSArPSBgXFxuMi4gVG8gYWxsb3cgYW55IHByb3BlcnR5IGFkZCAnTk9fRVJST1JTX1NDSEVNQScgdG8gYCArXG4gICAgICAgICAgYHRoZSAke3NjaGVtYXN9IG9mIHRoaXMgY29tcG9uZW50LmA7XG4gICAgfVxuICB9XG5cbiAgcmVwb3J0VW5rbm93blByb3BlcnR5RXJyb3IobWVzc2FnZSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiByZXBvcnRVbmtub3duUHJvcGVydHlFcnJvcihtZXNzYWdlOiBzdHJpbmcpIHtcbiAgaWYgKHNob3VsZFRocm93RXJyb3JPblVua25vd25Qcm9wZXJ0eSkge1xuICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoUnVudGltZUVycm9yQ29kZS5VTktOT1dOX0JJTkRJTkcsIG1lc3NhZ2UpO1xuICB9IGVsc2Uge1xuICAgIGNvbnNvbGUuZXJyb3IoZm9ybWF0UnVudGltZUVycm9yKFJ1bnRpbWVFcnJvckNvZGUuVU5LTk9XTl9CSU5ESU5HLCBtZXNzYWdlKSk7XG4gIH1cbn1cblxuLyoqXG4gKiBXQVJOSU5HOiB0aGlzIGlzIGEgKipkZXYtbW9kZSBvbmx5KiogZnVuY3Rpb24gKHRodXMgc2hvdWxkIGFsd2F5cyBiZSBndWFyZGVkIGJ5IHRoZSBgbmdEZXZNb2RlYClcbiAqIGFuZCBtdXN0ICoqbm90KiogYmUgdXNlZCBpbiBwcm9kdWN0aW9uIGJ1bmRsZXMuIFRoZSBmdW5jdGlvbiBtYWtlcyBtZWdhbW9ycGhpYyByZWFkcywgd2hpY2ggbWlnaHRcbiAqIGJlIHRvbyBzbG93IGZvciBwcm9kdWN0aW9uIG1vZGUgYW5kIGFsc28gaXQgcmVsaWVzIG9uIHRoZSBjb25zdHJ1Y3RvciBmdW5jdGlvbiBiZWluZyBhdmFpbGFibGUuXG4gKlxuICogR2V0cyBhIHJlZmVyZW5jZSB0byB0aGUgaG9zdCBjb21wb25lbnQgZGVmICh3aGVyZSBhIGN1cnJlbnQgY29tcG9uZW50IGlzIGRlY2xhcmVkKS5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgQW4gYExWaWV3YCB0aGF0IHJlcHJlc2VudHMgYSBjdXJyZW50IGNvbXBvbmVudCB0aGF0IGlzIGJlaW5nIHJlbmRlcmVkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0RGVjbGFyYXRpb25Db21wb25lbnREZWYobFZpZXc6IExWaWV3KTogQ29tcG9uZW50RGVmPHVua25vd24+fG51bGwge1xuICAhbmdEZXZNb2RlICYmIHRocm93RXJyb3IoJ011c3QgbmV2ZXIgYmUgY2FsbGVkIGluIHByb2R1Y3Rpb24gbW9kZScpO1xuXG4gIGNvbnN0IGRlY2xhcmF0aW9uTFZpZXcgPSBsVmlld1tERUNMQVJBVElPTl9DT01QT05FTlRfVklFV10gYXMgTFZpZXc8VHlwZTx1bmtub3duPj47XG4gIGNvbnN0IGNvbnRleHQgPSBkZWNsYXJhdGlvbkxWaWV3W0NPTlRFWFRdO1xuXG4gIC8vIFVuYWJsZSB0byBvYnRhaW4gYSBjb250ZXh0LlxuICBpZiAoIWNvbnRleHQpIHJldHVybiBudWxsO1xuXG4gIHJldHVybiBjb250ZXh0LmNvbnN0cnVjdG9yID8gZ2V0Q29tcG9uZW50RGVmKGNvbnRleHQuY29uc3RydWN0b3IpIDogbnVsbDtcbn1cblxuLyoqXG4gKiBXQVJOSU5HOiB0aGlzIGlzIGEgKipkZXYtbW9kZSBvbmx5KiogZnVuY3Rpb24gKHRodXMgc2hvdWxkIGFsd2F5cyBiZSBndWFyZGVkIGJ5IHRoZSBgbmdEZXZNb2RlYClcbiAqIGFuZCBtdXN0ICoqbm90KiogYmUgdXNlZCBpbiBwcm9kdWN0aW9uIGJ1bmRsZXMuIFRoZSBmdW5jdGlvbiBtYWtlcyBtZWdhbW9ycGhpYyByZWFkcywgd2hpY2ggbWlnaHRcbiAqIGJlIHRvbyBzbG93IGZvciBwcm9kdWN0aW9uIG1vZGUuXG4gKlxuICogQ2hlY2tzIGlmIHRoZSBjdXJyZW50IGNvbXBvbmVudCBpcyBkZWNsYXJlZCBpbnNpZGUgb2YgYSBzdGFuZGFsb25lIGNvbXBvbmVudCB0ZW1wbGF0ZS5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgQW4gYExWaWV3YCB0aGF0IHJlcHJlc2VudHMgYSBjdXJyZW50IGNvbXBvbmVudCB0aGF0IGlzIGJlaW5nIHJlbmRlcmVkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gaXNIb3N0Q29tcG9uZW50U3RhbmRhbG9uZShsVmlldzogTFZpZXcpOiBib29sZWFuIHtcbiAgIW5nRGV2TW9kZSAmJiB0aHJvd0Vycm9yKCdNdXN0IG5ldmVyIGJlIGNhbGxlZCBpbiBwcm9kdWN0aW9uIG1vZGUnKTtcblxuICBjb25zdCBjb21wb25lbnREZWYgPSBnZXREZWNsYXJhdGlvbkNvbXBvbmVudERlZihsVmlldyk7XG4gIC8vIFRyZWF0IGhvc3QgY29tcG9uZW50IGFzIG5vbi1zdGFuZGFsb25lIGlmIHdlIGNhbid0IG9idGFpbiB0aGUgZGVmLlxuICByZXR1cm4gISFjb21wb25lbnREZWY/LnN0YW5kYWxvbmU7XG59XG5cbi8qKlxuICogV0FSTklORzogdGhpcyBpcyBhICoqZGV2LW1vZGUgb25seSoqIGZ1bmN0aW9uICh0aHVzIHNob3VsZCBhbHdheXMgYmUgZ3VhcmRlZCBieSB0aGUgYG5nRGV2TW9kZWApXG4gKiBhbmQgbXVzdCAqKm5vdCoqIGJlIHVzZWQgaW4gcHJvZHVjdGlvbiBidW5kbGVzLiBUaGUgZnVuY3Rpb24gbWFrZXMgbWVnYW1vcnBoaWMgcmVhZHMsIHdoaWNoIG1pZ2h0XG4gKiBiZSB0b28gc2xvdyBmb3IgcHJvZHVjdGlvbiBtb2RlLlxuICpcbiAqIENvbnN0cnVjdHMgYSBzdHJpbmcgZGVzY3JpYmluZyB0aGUgbG9jYXRpb24gb2YgdGhlIGhvc3QgY29tcG9uZW50IHRlbXBsYXRlLiBUaGUgZnVuY3Rpb24gaXMgdXNlZFxuICogaW4gZGV2IG1vZGUgdG8gcHJvZHVjZSBlcnJvciBtZXNzYWdlcy5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgQW4gYExWaWV3YCB0aGF0IHJlcHJlc2VudHMgYSBjdXJyZW50IGNvbXBvbmVudCB0aGF0IGlzIGJlaW5nIHJlbmRlcmVkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0VGVtcGxhdGVMb2NhdGlvbkRldGFpbHMobFZpZXc6IExWaWV3KTogc3RyaW5nIHtcbiAgIW5nRGV2TW9kZSAmJiB0aHJvd0Vycm9yKCdNdXN0IG5ldmVyIGJlIGNhbGxlZCBpbiBwcm9kdWN0aW9uIG1vZGUnKTtcblxuICBjb25zdCBob3N0Q29tcG9uZW50RGVmID0gZ2V0RGVjbGFyYXRpb25Db21wb25lbnREZWYobFZpZXcpO1xuICBjb25zdCBjb21wb25lbnRDbGFzc05hbWUgPSBob3N0Q29tcG9uZW50RGVmPy50eXBlPy5uYW1lO1xuICByZXR1cm4gY29tcG9uZW50Q2xhc3NOYW1lID8gYCAodXNlZCBpbiB0aGUgJyR7Y29tcG9uZW50Q2xhc3NOYW1lfScgY29tcG9uZW50IHRlbXBsYXRlKWAgOiAnJztcbn1cblxuLyoqXG4gKiBUaGUgc2V0IG9mIGtub3duIGNvbnRyb2wgZmxvdyBkaXJlY3RpdmVzIGFuZCB0aGVpciBjb3JyZXNwb25kaW5nIGltcG9ydHMuXG4gKiBXZSB1c2UgdGhpcyBzZXQgdG8gcHJvZHVjZSBhIG1vcmUgcHJlY2lzZXMgZXJyb3IgbWVzc2FnZSB3aXRoIGEgbm90ZVxuICogdGhhdCB0aGUgYENvbW1vbk1vZHVsZWAgc2hvdWxkIGFsc28gYmUgaW5jbHVkZWQuXG4gKi9cbmV4cG9ydCBjb25zdCBLTk9XTl9DT05UUk9MX0ZMT1dfRElSRUNUSVZFUyA9IG5ldyBNYXAoW1xuICBbJ25nSWYnLCAnTmdJZiddLCBbJ25nRm9yJywgJ05nRm9yJ10sIFsnbmdTd2l0Y2hDYXNlJywgJ05nU3dpdGNoQ2FzZSddLFxuICBbJ25nU3dpdGNoRGVmYXVsdCcsICdOZ1N3aXRjaERlZmF1bHQnXVxuXSk7XG4vKipcbiAqIFJldHVybnMgdHJ1ZSBpZiB0aGUgdGFnIG5hbWUgaXMgYWxsb3dlZCBieSBzcGVjaWZpZWQgc2NoZW1hcy5cbiAqIEBwYXJhbSBzY2hlbWFzIEFycmF5IG9mIHNjaGVtYXNcbiAqIEBwYXJhbSB0YWdOYW1lIE5hbWUgb2YgdGhlIHRhZ1xuICovXG5leHBvcnQgZnVuY3Rpb24gbWF0Y2hpbmdTY2hlbWFzKHNjaGVtYXM6IFNjaGVtYU1ldGFkYXRhW118bnVsbCwgdGFnTmFtZTogc3RyaW5nfG51bGwpOiBib29sZWFuIHtcbiAgaWYgKHNjaGVtYXMgIT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IHNjaGVtYXMubGVuZ3RoOyBpKyspIHtcbiAgICAgIGNvbnN0IHNjaGVtYSA9IHNjaGVtYXNbaV07XG4gICAgICBpZiAoc2NoZW1hID09PSBOT19FUlJPUlNfU0NIRU1BIHx8XG4gICAgICAgICAgc2NoZW1hID09PSBDVVNUT01fRUxFTUVOVFNfU0NIRU1BICYmIHRhZ05hbWUgJiYgdGFnTmFtZS5pbmRleE9mKCctJykgPiAtMSkge1xuICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICByZXR1cm4gZmFsc2U7XG59XG4iXX0=