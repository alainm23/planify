/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import '../util/ng_dev_mode';
import { assertDefined, assertEqual, assertNotEqual } from '../util/assert';
import { classIndexOf } from './styling/class_differ';
import { isNameOnlyAttributeMarker } from './util/attrs_utils';
const NG_TEMPLATE_SELECTOR = 'ng-template';
/**
 * Search the `TAttributes` to see if it contains `cssClassToMatch` (case insensitive)
 *
 * @param attrs `TAttributes` to search through.
 * @param cssClassToMatch class to match (lowercase)
 * @param isProjectionMode Whether or not class matching should look into the attribute `class` in
 *    addition to the `AttributeMarker.Classes`.
 */
function isCssClassMatching(attrs, cssClassToMatch, isProjectionMode) {
    // TODO(misko): The fact that this function needs to know about `isProjectionMode` seems suspect.
    // It is strange to me that sometimes the class information comes in form of `class` attribute
    // and sometimes in form of `AttributeMarker.Classes`. Some investigation is needed to determine
    // if that is the right behavior.
    ngDevMode &&
        assertEqual(cssClassToMatch, cssClassToMatch.toLowerCase(), 'Class name expected to be lowercase.');
    let i = 0;
    // Indicates whether we are processing value from the implicit
    // attribute section (i.e. before the first marker in the array).
    let isImplicitAttrsSection = true;
    while (i < attrs.length) {
        let item = attrs[i++];
        if (typeof item === 'string' && isImplicitAttrsSection) {
            const value = attrs[i++];
            if (isProjectionMode && item === 'class') {
                // We found a `class` attribute in the implicit attribute section,
                // check if it matches the value of the `cssClassToMatch` argument.
                if (classIndexOf(value.toLowerCase(), cssClassToMatch, 0) !== -1) {
                    return true;
                }
            }
        }
        else if (item === 1 /* AttributeMarker.Classes */) {
            // We found the classes section. Start searching for the class.
            while (i < attrs.length && typeof (item = attrs[i++]) == 'string') {
                // while we have strings
                if (item.toLowerCase() === cssClassToMatch)
                    return true;
            }
            return false;
        }
        else if (typeof item === 'number') {
            // We've came across a first marker, which indicates
            // that the implicit attribute section is over.
            isImplicitAttrsSection = false;
        }
    }
    return false;
}
/**
 * Checks whether the `tNode` represents an inline template (e.g. `*ngFor`).
 *
 * @param tNode current TNode
 */
export function isInlineTemplate(tNode) {
    return tNode.type === 4 /* TNodeType.Container */ && tNode.value !== NG_TEMPLATE_SELECTOR;
}
/**
 * Function that checks whether a given tNode matches tag-based selector and has a valid type.
 *
 * Matching can be performed in 2 modes: projection mode (when we project nodes) and regular
 * directive matching mode:
 * - in the "directive matching" mode we do _not_ take TContainer's tagName into account if it is
 * different from NG_TEMPLATE_SELECTOR (value different from NG_TEMPLATE_SELECTOR indicates that a
 * tag name was extracted from * syntax so we would match the same directive twice);
 * - in the "projection" mode, we use a tag name potentially extracted from the * syntax processing
 * (applicable to TNodeType.Container only).
 */
function hasTagAndTypeMatch(tNode, currentSelector, isProjectionMode) {
    const tagNameToCompare = tNode.type === 4 /* TNodeType.Container */ && !isProjectionMode ? NG_TEMPLATE_SELECTOR : tNode.value;
    return currentSelector === tagNameToCompare;
}
/**
 * A utility function to match an Ivy node static data against a simple CSS selector
 *
 * @param node static data of the node to match
 * @param selector The selector to try matching against the node.
 * @param isProjectionMode if `true` we are matching for content projection, otherwise we are doing
 * directive matching.
 * @returns true if node matches the selector.
 */
export function isNodeMatchingSelector(tNode, selector, isProjectionMode) {
    ngDevMode && assertDefined(selector[0], 'Selector should have a tag name');
    let mode = 4 /* SelectorFlags.ELEMENT */;
    const nodeAttrs = tNode.attrs || [];
    // Find the index of first attribute that has no value, only a name.
    const nameOnlyMarkerIdx = getNameOnlyMarkerIndex(nodeAttrs);
    // When processing ":not" selectors, we skip to the next ":not" if the
    // current one doesn't match
    let skipToNextSelector = false;
    for (let i = 0; i < selector.length; i++) {
        const current = selector[i];
        if (typeof current === 'number') {
            // If we finish processing a :not selector and it hasn't failed, return false
            if (!skipToNextSelector && !isPositive(mode) && !isPositive(current)) {
                return false;
            }
            // If we are skipping to the next :not() and this mode flag is positive,
            // it's a part of the current :not() selector, and we should keep skipping
            if (skipToNextSelector && isPositive(current))
                continue;
            skipToNextSelector = false;
            mode = current | (mode & 1 /* SelectorFlags.NOT */);
            continue;
        }
        if (skipToNextSelector)
            continue;
        if (mode & 4 /* SelectorFlags.ELEMENT */) {
            mode = 2 /* SelectorFlags.ATTRIBUTE */ | mode & 1 /* SelectorFlags.NOT */;
            if (current !== '' && !hasTagAndTypeMatch(tNode, current, isProjectionMode) ||
                current === '' && selector.length === 1) {
                if (isPositive(mode))
                    return false;
                skipToNextSelector = true;
            }
        }
        else {
            const selectorAttrValue = mode & 8 /* SelectorFlags.CLASS */ ? current : selector[++i];
            // special case for matching against classes when a tNode has been instantiated with
            // class and style values as separate attribute values (e.g. ['title', CLASS, 'foo'])
            if ((mode & 8 /* SelectorFlags.CLASS */) && tNode.attrs !== null) {
                if (!isCssClassMatching(tNode.attrs, selectorAttrValue, isProjectionMode)) {
                    if (isPositive(mode))
                        return false;
                    skipToNextSelector = true;
                }
                continue;
            }
            const attrName = (mode & 8 /* SelectorFlags.CLASS */) ? 'class' : current;
            const attrIndexInNode = findAttrIndexInNode(attrName, nodeAttrs, isInlineTemplate(tNode), isProjectionMode);
            if (attrIndexInNode === -1) {
                if (isPositive(mode))
                    return false;
                skipToNextSelector = true;
                continue;
            }
            if (selectorAttrValue !== '') {
                let nodeAttrValue;
                if (attrIndexInNode > nameOnlyMarkerIdx) {
                    nodeAttrValue = '';
                }
                else {
                    ngDevMode &&
                        assertNotEqual(nodeAttrs[attrIndexInNode], 0 /* AttributeMarker.NamespaceURI */, 'We do not match directives on namespaced attributes');
                    // we lowercase the attribute value to be able to match
                    // selectors without case-sensitivity
                    // (selectors are already in lowercase when generated)
                    nodeAttrValue = nodeAttrs[attrIndexInNode + 1].toLowerCase();
                }
                const compareAgainstClassName = mode & 8 /* SelectorFlags.CLASS */ ? nodeAttrValue : null;
                if (compareAgainstClassName &&
                    classIndexOf(compareAgainstClassName, selectorAttrValue, 0) !== -1 ||
                    mode & 2 /* SelectorFlags.ATTRIBUTE */ && selectorAttrValue !== nodeAttrValue) {
                    if (isPositive(mode))
                        return false;
                    skipToNextSelector = true;
                }
            }
        }
    }
    return isPositive(mode) || skipToNextSelector;
}
function isPositive(mode) {
    return (mode & 1 /* SelectorFlags.NOT */) === 0;
}
/**
 * Examines the attribute's definition array for a node to find the index of the
 * attribute that matches the given `name`.
 *
 * NOTE: This will not match namespaced attributes.
 *
 * Attribute matching depends upon `isInlineTemplate` and `isProjectionMode`.
 * The following table summarizes which types of attributes we attempt to match:
 *
 * ===========================================================================================================
 * Modes                   | Normal Attributes | Bindings Attributes | Template Attributes | I18n
 * Attributes
 * ===========================================================================================================
 * Inline + Projection     | YES               | YES                 | NO                  | YES
 * -----------------------------------------------------------------------------------------------------------
 * Inline + Directive      | NO                | NO                  | YES                 | NO
 * -----------------------------------------------------------------------------------------------------------
 * Non-inline + Projection | YES               | YES                 | NO                  | YES
 * -----------------------------------------------------------------------------------------------------------
 * Non-inline + Directive  | YES               | YES                 | NO                  | YES
 * ===========================================================================================================
 *
 * @param name the name of the attribute to find
 * @param attrs the attribute array to examine
 * @param isInlineTemplate true if the node being matched is an inline template (e.g. `*ngFor`)
 * rather than a manually expanded template node (e.g `<ng-template>`).
 * @param isProjectionMode true if we are matching against content projection otherwise we are
 * matching against directives.
 */
function findAttrIndexInNode(name, attrs, isInlineTemplate, isProjectionMode) {
    if (attrs === null)
        return -1;
    let i = 0;
    if (isProjectionMode || !isInlineTemplate) {
        let bindingsMode = false;
        while (i < attrs.length) {
            const maybeAttrName = attrs[i];
            if (maybeAttrName === name) {
                return i;
            }
            else if (maybeAttrName === 3 /* AttributeMarker.Bindings */ || maybeAttrName === 6 /* AttributeMarker.I18n */) {
                bindingsMode = true;
            }
            else if (maybeAttrName === 1 /* AttributeMarker.Classes */ || maybeAttrName === 2 /* AttributeMarker.Styles */) {
                let value = attrs[++i];
                // We should skip classes here because we have a separate mechanism for
                // matching classes in projection mode.
                while (typeof value === 'string') {
                    value = attrs[++i];
                }
                continue;
            }
            else if (maybeAttrName === 4 /* AttributeMarker.Template */) {
                // We do not care about Template attributes in this scenario.
                break;
            }
            else if (maybeAttrName === 0 /* AttributeMarker.NamespaceURI */) {
                // Skip the whole namespaced attribute and value. This is by design.
                i += 4;
                continue;
            }
            // In binding mode there are only names, rather than name-value pairs.
            i += bindingsMode ? 1 : 2;
        }
        // We did not match the attribute
        return -1;
    }
    else {
        return matchTemplateAttribute(attrs, name);
    }
}
export function isNodeMatchingSelectorList(tNode, selector, isProjectionMode = false) {
    for (let i = 0; i < selector.length; i++) {
        if (isNodeMatchingSelector(tNode, selector[i], isProjectionMode)) {
            return true;
        }
    }
    return false;
}
export function getProjectAsAttrValue(tNode) {
    const nodeAttrs = tNode.attrs;
    if (nodeAttrs != null) {
        const ngProjectAsAttrIdx = nodeAttrs.indexOf(5 /* AttributeMarker.ProjectAs */);
        // only check for ngProjectAs in attribute names, don't accidentally match attribute's value
        // (attribute names are stored at even indexes)
        if ((ngProjectAsAttrIdx & 1) === 0) {
            return nodeAttrs[ngProjectAsAttrIdx + 1];
        }
    }
    return null;
}
function getNameOnlyMarkerIndex(nodeAttrs) {
    for (let i = 0; i < nodeAttrs.length; i++) {
        const nodeAttr = nodeAttrs[i];
        if (isNameOnlyAttributeMarker(nodeAttr)) {
            return i;
        }
    }
    return nodeAttrs.length;
}
function matchTemplateAttribute(attrs, name) {
    let i = attrs.indexOf(4 /* AttributeMarker.Template */);
    if (i > -1) {
        i++;
        while (i < attrs.length) {
            const attr = attrs[i];
            // Return in case we checked all template attrs and are switching to the next section in the
            // attrs array (that starts with a number that represents an attribute marker).
            if (typeof attr === 'number')
                return -1;
            if (attr === name)
                return i;
            i++;
        }
    }
    return -1;
}
/**
 * Checks whether a selector is inside a CssSelectorList
 * @param selector Selector to be checked.
 * @param list List in which to look for the selector.
 */
export function isSelectorInSelectorList(selector, list) {
    selectorListLoop: for (let i = 0; i < list.length; i++) {
        const currentSelectorInList = list[i];
        if (selector.length !== currentSelectorInList.length) {
            continue;
        }
        for (let j = 0; j < selector.length; j++) {
            if (selector[j] !== currentSelectorInList[j]) {
                continue selectorListLoop;
            }
        }
        return true;
    }
    return false;
}
function maybeWrapInNotSelector(isNegativeMode, chunk) {
    return isNegativeMode ? ':not(' + chunk.trim() + ')' : chunk;
}
function stringifyCSSSelector(selector) {
    let result = selector[0];
    let i = 1;
    let mode = 2 /* SelectorFlags.ATTRIBUTE */;
    let currentChunk = '';
    let isNegativeMode = false;
    while (i < selector.length) {
        let valueOrMarker = selector[i];
        if (typeof valueOrMarker === 'string') {
            if (mode & 2 /* SelectorFlags.ATTRIBUTE */) {
                const attrValue = selector[++i];
                currentChunk +=
                    '[' + valueOrMarker + (attrValue.length > 0 ? '="' + attrValue + '"' : '') + ']';
            }
            else if (mode & 8 /* SelectorFlags.CLASS */) {
                currentChunk += '.' + valueOrMarker;
            }
            else if (mode & 4 /* SelectorFlags.ELEMENT */) {
                currentChunk += ' ' + valueOrMarker;
            }
        }
        else {
            //
            // Append current chunk to the final result in case we come across SelectorFlag, which
            // indicates that the previous section of a selector is over. We need to accumulate content
            // between flags to make sure we wrap the chunk later in :not() selector if needed, e.g.
            // ```
            //  ['', Flags.CLASS, '.classA', Flags.CLASS | Flags.NOT, '.classB', '.classC']
            // ```
            // should be transformed to `.classA :not(.classB .classC)`.
            //
            // Note: for negative selector part, we accumulate content between flags until we find the
            // next negative flag. This is needed to support a case where `:not()` rule contains more than
            // one chunk, e.g. the following selector:
            // ```
            //  ['', Flags.ELEMENT | Flags.NOT, 'p', Flags.CLASS, 'foo', Flags.CLASS | Flags.NOT, 'bar']
            // ```
            // should be stringified to `:not(p.foo) :not(.bar)`
            //
            if (currentChunk !== '' && !isPositive(valueOrMarker)) {
                result += maybeWrapInNotSelector(isNegativeMode, currentChunk);
                currentChunk = '';
            }
            mode = valueOrMarker;
            // According to CssSelector spec, once we come across `SelectorFlags.NOT` flag, the negative
            // mode is maintained for remaining chunks of a selector.
            isNegativeMode = isNegativeMode || !isPositive(mode);
        }
        i++;
    }
    if (currentChunk !== '') {
        result += maybeWrapInNotSelector(isNegativeMode, currentChunk);
    }
    return result;
}
/**
 * Generates string representation of CSS selector in parsed form.
 *
 * ComponentDef and DirectiveDef are generated with the selector in parsed form to avoid doing
 * additional parsing at runtime (for example, for directive matching). However in some cases (for
 * example, while bootstrapping a component), a string version of the selector is required to query
 * for the host element on the page. This function takes the parsed form of a selector and returns
 * its string representation.
 *
 * @param selectorList selector in parsed form
 * @returns string representation of a given selector
 */
export function stringifyCSSSelectorList(selectorList) {
    return selectorList.map(stringifyCSSSelector).join(',');
}
/**
 * Extracts attributes and classes information from a given CSS selector.
 *
 * This function is used while creating a component dynamically. In this case, the host element
 * (that is created dynamically) should contain attributes and classes specified in component's CSS
 * selector.
 *
 * @param selector CSS selector in parsed form (in a form of array)
 * @returns object with `attrs` and `classes` fields that contain extracted information
 */
export function extractAttrsAndClassesFromSelector(selector) {
    const attrs = [];
    const classes = [];
    let i = 1;
    let mode = 2 /* SelectorFlags.ATTRIBUTE */;
    while (i < selector.length) {
        let valueOrMarker = selector[i];
        if (typeof valueOrMarker === 'string') {
            if (mode === 2 /* SelectorFlags.ATTRIBUTE */) {
                if (valueOrMarker !== '') {
                    attrs.push(valueOrMarker, selector[++i]);
                }
            }
            else if (mode === 8 /* SelectorFlags.CLASS */) {
                classes.push(valueOrMarker);
            }
        }
        else {
            // According to CssSelector spec, once we come across `SelectorFlags.NOT` flag, the negative
            // mode is maintained for remaining chunks of a selector. Since attributes and classes are
            // extracted only for "positive" part of the selector, we can stop here.
            if (!isPositive(mode))
                break;
            mode = valueOrMarker;
        }
        i++;
    }
    return { attrs, classes };
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibm9kZV9zZWxlY3Rvcl9tYXRjaGVyLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9ub2RlX3NlbGVjdG9yX21hdGNoZXIudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxxQkFBcUIsQ0FBQztBQUU3QixPQUFPLEVBQUMsYUFBYSxFQUFFLFdBQVcsRUFBRSxjQUFjLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUkxRSxPQUFPLEVBQUMsWUFBWSxFQUFDLE1BQU0sd0JBQXdCLENBQUM7QUFDcEQsT0FBTyxFQUFDLHlCQUF5QixFQUFDLE1BQU0sb0JBQW9CLENBQUM7QUFFN0QsTUFBTSxvQkFBb0IsR0FBRyxhQUFhLENBQUM7QUFFM0M7Ozs7Ozs7R0FPRztBQUNILFNBQVMsa0JBQWtCLENBQ3ZCLEtBQWtCLEVBQUUsZUFBdUIsRUFBRSxnQkFBeUI7SUFDeEUsaUdBQWlHO0lBQ2pHLDhGQUE4RjtJQUM5RixnR0FBZ0c7SUFDaEcsaUNBQWlDO0lBQ2pDLFNBQVM7UUFDTCxXQUFXLENBQ1AsZUFBZSxFQUFFLGVBQWUsQ0FBQyxXQUFXLEVBQUUsRUFBRSxzQ0FBc0MsQ0FBQyxDQUFDO0lBQ2hHLElBQUksQ0FBQyxHQUFHLENBQUMsQ0FBQztJQUNWLDhEQUE4RDtJQUM5RCxpRUFBaUU7SUFDakUsSUFBSSxzQkFBc0IsR0FBRyxJQUFJLENBQUM7SUFDbEMsT0FBTyxDQUFDLEdBQUcsS0FBSyxDQUFDLE1BQU0sRUFBRTtRQUN2QixJQUFJLElBQUksR0FBRyxLQUFLLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQztRQUN0QixJQUFJLE9BQU8sSUFBSSxLQUFLLFFBQVEsSUFBSSxzQkFBc0IsRUFBRTtZQUN0RCxNQUFNLEtBQUssR0FBRyxLQUFLLENBQUMsQ0FBQyxFQUFFLENBQVcsQ0FBQztZQUNuQyxJQUFJLGdCQUFnQixJQUFJLElBQUks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QUFJLElBQUksa0NBQTBCLENBQUM7SUFDbkMsT0FBTyxDQUFDLEdBQUcsUUFBUSxDQUFDLE1BQU0sRUFBRTtRQUMxQixJQUFJLGFBQWEsR0FBRyxRQUFRLENBQUMsQ0FBQyxDQUFDLENBQUM7UUFDaEMsSUFBSSxPQUFPLGFBQWEsS0FBSyxRQUFRLEVBQUU7WUFDckMsSUFBSSxJQUFJLG9DQUE0QixFQUFFO2dCQUNwQyxJQUFJLGFBQWEsS0FBSyxFQUFFLEVBQUU7b0JBQ3hCLEtBQUssQ0FBQyxJQUFJLENBQUMsYUFBYSxFQUFFLFFBQVEsQ0FBQyxFQUFFLENBQUMsQ0FBVyxDQUFDLENBQUM7aUJBQ3BEO2FBQ0Y7aUJBQU0sSUFBSSxJQUFJLGdDQUF3QixFQUFFO2dCQUN2QyxPQUFPLENBQUMsSUFBSSxDQUFDLGFBQWEsQ0FBQyxDQUFDO2FBQzdCO1NBQ0Y7YUFBTTtZQUNMLDRGQUE0RjtZQUM1RiwwRkFBMEY7WUFDMUYsd0VBQXdFO1lBQ3hFLElBQUksQ0FBQyxVQUFVLENBQUMsSUFBSSxDQUFDO2dCQUFFLE1BQU07WUFDN0IsSUFBSSxHQUFHLGFBQWEsQ0FBQztTQUN0QjtRQUNELENBQUMsRUFBRSxDQUFDO0tBQ0w7SUFDRCxPQUFPLEVBQUMsS0FBSyxFQUFFLE9BQU8sRUFBQyxDQUFDO0FBQzFCLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0ICcuLi91dGlsL25nX2Rldl9tb2RlJztcblxuaW1wb3J0IHthc3NlcnREZWZpbmVkLCBhc3NlcnRFcXVhbCwgYXNzZXJ0Tm90RXF1YWx9IGZyb20gJy4uL3V0aWwvYXNzZXJ0JztcblxuaW1wb3J0IHtBdHRyaWJ1dGVNYXJrZXIsIFRBdHRyaWJ1dGVzLCBUTm9kZSwgVE5vZGVUeXBlfSBmcm9tICcuL2ludGVyZmFjZXMvbm9kZSc7XG5pbXBvcnQge0Nzc1NlbGVjdG9yLCBDc3NTZWxlY3Rvckxpc3QsIFNlbGVjdG9yRmxhZ3N9IGZyb20gJy4vaW50ZXJmYWNlcy9wcm9qZWN0aW9uJztcbmltcG9ydCB7Y2xhc3NJbmRleE9mfSBmcm9tICcuL3N0eWxpbmcvY2xhc3NfZGlmZmVyJztcbmltcG9ydCB7aXNOYW1lT25seUF0dHJpYnV0ZU1hcmtlcn0gZnJvbSAnLi91dGlsL2F0dHJzX3V0aWxzJztcblxuY29uc3QgTkdfVEVNUExBVEVfU0VMRUNUT1IgPSAnbmctdGVtcGxhdGUnO1xuXG4vKipcbiAqIFNlYXJjaCB0aGUgYFRBdHRyaWJ1dGVzYCB0byBzZWUgaWYgaXQgY29udGFpbnMgYGNzc0NsYXNzVG9NYXRjaGAgKGNhc2UgaW5zZW5zaXRpdmUpXG4gKlxuICogQHBhcmFtIGF0dHJzIGBUQXR0cmlidXRlc2AgdG8gc2VhcmNoIHRocm91Z2guXG4gKiBAcGFyYW0gY3NzQ2xhc3NUb01hdGNoIGNsYXNzIHRvIG1hdGNoIChsb3dlcmNhc2UpXG4gKiBAcGFyYW0gaXNQcm9qZWN0aW9uTW9kZSBXaGV0aGVyIG9yIG5vdCBjbGFzcyBtYXRjaGluZyBzaG91bGQgbG9vayBpbnRvIHRoZSBhdHRyaWJ1dGUgYGNsYXNzYCBpblxuICogICAgYWRkaXRpb24gdG8gdGhlIGBBdHRyaWJ1dGVNYXJrZXIuQ2xhc3Nlc2AuXG4gKi9cbmZ1bmN0aW9uIGlzQ3NzQ2xhc3NNYXRjaGluZyhcbiAgICBhdHRyczogVEF0dHJpYnV0ZXMsIGNzc0NsYXNzVG9NYXRjaDogc3RyaW5nLCBpc1Byb2plY3Rpb25Nb2RlOiBib29sZWFuKTogYm9vbGVhbiB7XG4gIC8vIFRPRE8obWlza28pOiBUaGUgZmFjdCB0aGF0IHRoaXMgZnVuY3Rpb24gbmVlZHMgdG8ga25vdyBhYm91dCBgaXNQcm9qZWN0aW9uTW9kZWAgc2VlbXMgc3VzcGVjdC5cbiAgLy8gSXQgaXMgc3RyYW5nZSB0byBtZSB0aGF0IHNvbWV0aW1lcyB0aGUgY2xhc3MgaW5mb3JtYXRpb24gY29tZXMgaW4gZm9ybSBvZiBgY2xhc3NgIGF0dHJpYnV0ZVxuICAvLyBhbmQgc29tZXRpbWVzIGluIGZvcm0gb2YgYEF0dHJpYnV0ZU1hcmtlci5DbGFzc2VzYC4gU29tZSBpbnZlc3RpZ2F0aW9uIGlzIG5lZWRlZCB0byBkZXRlcm1pbmVcbiAgLy8gaWYgdGhhdCBpcyB0aGUgcmlnaHQgYmVoYXZpb3IuXG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0RXF1YWwoXG4gICAgICAgICAgY3NzQ2xhc3NUb01hdGNoLCBjc3NDbGFzc1RvTWF0Y2gudG9Mb3dlckNhc2UoKSwgJ0NsYXNzIG5hbWUgZXhwZWN0ZWQgdG8gYmUgbG93ZXJjYXNlLicpO1xuICBsZXQgaSA9IDA7XG4gIC8vIEluZGljYXRlcyB3aGV0aGVyIHdlIGFyZSBwcm9jZXNzaW5nIHZhbHVlIGZyb20gdGhlIGltcGxpY2l0XG4gIC8vIGF0dHJpYnV0ZSBzZWN0aW9uIChpLmUuIGJlZm9yZSB0aGUgZmlyc3QgbWFya2VyIGluIHRoZSBhcnJheSkuXG4gIGxldCBpc0ltcGxpY2l0QXR0cnNTZWN0aW9uID0gdHJ1ZTtcbiAgd2hpbGUgKGkgPCBhdHRycy5sZW5ndGgpIHtcbiAgICBsZXQgaXRlbSA9IGF0dHJzW2krK107XG4gICAgaWYgKHR5cGVvZiBpdGVtID09PSAnc3RyaW5nJyAmJiBpc0ltcGxpY2l0QXR0cnNTZWN0aW9uKSB7XG4gICAgICBjb25zdCB2YWx1ZSA9IGF0dHJzW2krK10gYXMgc3RyaW5nO1xuICAgICAgaWYgKGlzUHJvamVjdGlvbk1vZGUgJiYgaXRlbSA9PT0gJ2NsYXNzJykge1xuICAgICAgICAvLyBXZSBmb3VuZCBhIGBjbGFzc2AgYXR0cmlidXRlIGluIHRoZSBpbXBsaWNpdCBhdHRyaWJ1dGUgc2VjdGlvbixcbiAgICAgICAgLy8gY2hlY2sgaWYgaXQgbWF0Y2hlcyB0aGUgdmFsdWUgb2YgdGhlIGBjc3NDbGFzc1RvTWF0Y2hgIGFyZ3VtZW50LlxuICAgICAgICBpZiAoY2xhc3NJbmRleE9mKHZhbHVlLnRvTG93ZXJDYXNlKCksIGNzc0NsYXNzVG9NYXRjaCwgMCkgIT09IC0xKSB7XG4gICAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGVsc2UgaWYgKGl0ZW0gPT09IEF0dHJpYnV0ZU1hcmtlci5DbGFzc2VzKSB7XG4gICAgICAvLyBXZSBmb3VuZCB0aGUgY2xhc3NlcyBzZWN0aW9uLiBTdGFydCBzZWFyY2hpbmcgZm9yIHRoZSBjbGFzcy5cbiAgICAgIHdoaWxlIChpIDwgYXR0cnMubGVuZ3RoICYmIHR5cGVvZiAoaXRlbSA9IGF0dHJzW2krK10pID09ICdzdHJpbmcnKSB7XG4gICAgICAgIC8vIHdoaWxlIHdlIGhhdmUgc3RyaW5nc1xuICAgICAgICBpZiAoaXRlbS50b0xvd2VyQ2FzZSgpID09PSBjc3NDbGFzc1RvTWF0Y2gpIHJldHVybiB0cnVlO1xuICAgICAgfVxuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH0gZWxzZSBpZiAodHlwZW9mIGl0ZW0gPT09ICdudW1iZXInKSB7XG4gICAgICAvLyBXZSd2ZSBjYW1lIGFjcm9zcyBhIGZpcnN0IG1hcmtlciwgd2hpY2ggaW5kaWNhdGVzXG4gICAgICAvLyB0aGF0IHRoZSBpbXBsaWNpdCBhdHRyaWJ1dGUgc2VjdGlvbiBpcyBvdmVyLlxuICAgICAgaXNJbXBsaWNpdEF0dHJzU2VjdGlvbiA9IGZhbHNlO1xuICAgIH1cbiAgfVxuICByZXR1cm4gZmFsc2U7XG59XG5cbi8qKlxuICogQ2hlY2tzIHdoZXRoZXIgdGhlIGB0Tm9kZWAgcmVwcmVzZW50cyBhbiBpbmxpbmUgdGVtcGxhdGUgKGUuZy4gYCpuZ0ZvcmApLlxuICpcbiAqIEBwYXJhbSB0Tm9kZSBjdXJyZW50IFROb2RlXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpc0lubGluZVRlbXBsYXRlKHROb2RlOiBUTm9kZSk6IGJvb2xlYW4ge1xuICByZXR1cm4gdE5vZGUudHlwZSA9PT0gVE5vZGVUeXBlLkNvbnRhaW5lciAmJiB0Tm9kZS52YWx1ZSAhPT0gTkdfVEVNUExBVEVfU0VMRUNUT1I7XG59XG5cbi8qKlxuICogRnVuY3Rpb24gdGhhdCBjaGVja3Mgd2hldGhlciBhIGdpdmVuIHROb2RlIG1hdGNoZXMgdGFnLWJhc2VkIHNlbGVjdG9yIGFuZCBoYXMgYSB2YWxpZCB0eXBlLlxuICpcbiAqIE1hdGNoaW5nIGNhbiBiZSBwZXJmb3JtZWQgaW4gMiBtb2RlczogcHJvamVjdGlvbiBtb2RlICh3aGVuIHdlIHByb2plY3Qgbm9kZXMpIGFuZCByZWd1bGFyXG4gKiBkaXJlY3RpdmUgbWF0Y2hpbmcgbW9kZTpcbiAqIC0gaW4gdGhlIFwiZGlyZWN0aXZlIG1hdGNoaW5nXCIgbW9kZSB3ZSBkbyBfbm90XyB0YWtlIFRDb250YWluZXIncyB0YWdOYW1lIGludG8gYWNjb3VudCBpZiBpdCBpc1xuICogZGlmZmVyZW50IGZyb20gTkdfVEVNUExBVEVfU0VMRUNUT1IgKHZhbHVlIGRpZmZlcmVudCBmcm9tIE5HX1RFTVBMQVRFX1NFTEVDVE9SIGluZGljYXRlcyB0aGF0IGFcbiAqIHRhZyBuYW1lIHdhcyBleHRyYWN0ZWQgZnJvbSAqIHN5bnRheCBzbyB3ZSB3b3VsZCBtYXRjaCB0aGUgc2FtZSBkaXJlY3RpdmUgdHdpY2UpO1xuICogLSBpbiB0aGUgXCJwcm9qZWN0aW9uXCIgbW9kZSwgd2UgdXNlIGEgdGFnIG5hbWUgcG90ZW50aWFsbHkgZXh0cmFjdGVkIGZyb20gdGhlICogc3ludGF4IHByb2Nlc3NpbmdcbiAqIChhcHBsaWNhYmxlIHRvIFROb2RlVHlwZS5Db250YWluZXIgb25seSkuXG4gKi9cbmZ1bmN0aW9uIGhhc1RhZ0FuZFR5cGVNYXRjaChcbiAgICB0Tm9kZTogVE5vZGUsIGN1cnJlbnRTZWxlY3Rvcjogc3RyaW5nLCBpc1Byb2plY3Rpb25Nb2RlOiBib29sZWFuKTogYm9vbGVhbiB7XG4gIGNvbnN0IHRhZ05hbWVUb0NvbXBhcmUgPVxuICAgICAgdE5vZGUudHlwZSA9PT0gVE5vZGVUeXBlLkNvbnRhaW5lciAmJiAhaXNQcm9qZWN0aW9uTW9kZSA/IE5HX1RFTVBMQVRFX1NFTEVDVE9SIDogdE5vZGUudmFsdWU7XG4gIHJldHVybiBjdXJyZW50U2VsZWN0b3IgPT09IHRhZ05hbWVUb0NvbXBhcmU7XG59XG5cbi8qKlxuICogQSB1dGlsaXR5IGZ1bmN0aW9uIHRvIG1hdGNoIGFuIEl2eSBub2RlIHN0YXRpYyBkYXRhIGFnYWluc3QgYSBzaW1wbGUgQ1NTIHNlbGVjdG9yXG4gKlxuICogQHBhcmFtIG5vZGUgc3RhdGljIGRhdGEgb2YgdGhlIG5vZGUgdG8gbWF0Y2hcbiAqIEBwYXJhbSBzZWxlY3RvciBUaGUgc2VsZWN0b3IgdG8gdHJ5IG1hdGNoaW5nIGFnYWluc3QgdGhlIG5vZGUuXG4gKiBAcGFyYW0gaXNQcm9qZWN0aW9uTW9kZSBpZiBgdHJ1ZWAgd2UgYXJlIG1hdGNoaW5nIGZvciBjb250ZW50IHByb2plY3Rpb24sIG90aGVyd2lzZSB3ZSBhcmUgZG9pbmdcbiAqIGRpcmVjdGl2ZSBtYXRjaGluZy5cbiAqIEByZXR1cm5zIHRydWUgaWYgbm9kZSBtYXRjaGVzIHRoZSBzZWxlY3Rvci5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGlzTm9kZU1hdGNoaW5nU2VsZWN0b3IoXG4gICAgdE5vZGU6IFROb2RlLCBzZWxlY3RvcjogQ3NzU2VsZWN0b3IsIGlzUHJvamVjdGlvbk1vZGU6IGJvb2xlYW4pOiBib29sZWFuIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQoc2VsZWN0b3JbMF0sICdTZWxlY3RvciBzaG91bGQgaGF2ZSBhIHRhZyBuYW1lJyk7XG4gIGxldCBtb2RlOiBTZWxlY3RvckZsYWdzID0gU2VsZWN0b3JGbGFncy5FTEVNRU5UO1xuICBjb25zdCBub2RlQXR0cnMgPSB0Tm9kZS5hdHRycyB8fCBbXTtcblxuICAvLyBGaW5kIHRoZSBpbmRleCBvZiBmaXJzdCBhdHRyaWJ1dGUgdGhhdCBoYXMgbm8gdmFsdWUsIG9ubHkgYSBuYW1lLlxuICBjb25zdCBuYW1lT25seU1hcmtlcklkeCA9IGdldE5hbWVPbmx5TWFya2VySW5kZXgobm9kZUF0dHJzKTtcblxuICAvLyBXaGVuIHByb2Nlc3NpbmcgXCI6bm90XCIgc2VsZWN0b3JzLCB3ZSBza2lwIHRvIHRoZSBuZXh0IFwiOm5vdFwiIGlmIHRoZVxuICAvLyBjdXJyZW50IG9uZSBkb2Vzbid0IG1hdGNoXG4gIGxldCBza2lwVG9OZXh0U2VsZWN0b3IgPSBmYWxzZTtcblxuICBmb3IgKGxldCBpID0gMDsgaSA8IHNlbGVjdG9yLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgY3VycmVudCA9IHNlbGVjdG9yW2ldO1xuICAgIGlmICh0eXBlb2YgY3VycmVudCA9PT0gJ251bWJlcicpIHtcbiAgICAgIC8vIElmIHdlIGZpbmlzaCBwcm9jZXNzaW5nIGEgOm5vdCBzZWxlY3RvciBhbmQgaXQgaGFzbid0IGZhaWxlZCwgcmV0dXJuIGZhbHNlXG4gICAgICBpZiAoIXNraXBUb05leHRTZWxlY3RvciAmJiAhaXNQb3NpdGl2ZShtb2RlKSAmJiAhaXNQb3NpdGl2ZShjdXJyZW50KSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgICAvLyBJZiB3ZSBhcmUgc2tpcHBpbmcgdG8gdGhlIG5leHQgOm5vdCgpIGFuZCB0aGlzIG1vZGUgZmxhZyBpcyBwb3NpdGl2ZSxcbiAgICAgIC8vIGl0J3MgYSBwYXJ0IG9mIHRoZSBjdXJyZW50IDpub3QoKSBzZWxlY3RvciwgYW5kIHdlIHNob3VsZCBrZWVwIHNraXBwaW5nXG4gICAgICBpZiAoc2tpcFRvTmV4dFNlbGVjdG9yICYmIGlzUG9zaXRpdmUoY3VycmVudCkpIGNvbnRpbnVlO1xuICAgICAgc2tpcFRvTmV4dFNlbGVjdG9yID0gZmFsc2U7XG4gICAgICBtb2RlID0gKGN1cnJlbnQgYXMgbnVtYmVyKSB8IChtb2RlICYgU2VsZWN0b3JGbGFncy5OT1QpO1xuICAgICAgY29udGludWU7XG4gICAgfVxuXG4gICAgaWYgKHNraXBUb05leHRTZWxlY3RvcikgY29udGludWU7XG5cbiAgICBpZiAobW9kZSAmIFNlbGVjdG9yRmxhZ3MuRUxFTUVOVCkge1xuICAgICAgbW9kZSA9IFNlbGVjdG9yRmxhZ3MuQVRUUklCVVRFIHwgbW9kZSAmIFNlbGVjdG9yRmxhZ3MuTk9UO1xuICAgICAgaWYgKGN1cnJlbnQgIT09ICcnICYmICFoYXNUYWdBbmRUeXBlTWF0Y2godE5vZGUsIGN1cnJlbnQsIGlzUHJvamVjdGlvbk1vZGUpIHx8XG4gICAgICAgICAgY3VycmVudCA9PT0gJycgJiYgc2VsZWN0b3IubGVuZ3RoID09PSAxKSB7XG4gICAgICAgIGlmIChpc1Bvc2l0aXZlKG1vZGUpKSByZXR1cm4gZmFsc2U7XG4gICAgICAgIHNraXBUb05leHRTZWxlY3RvciA9IHRydWU7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIGNvbnN0IHNlbGVjdG9yQXR0clZhbHVlID0gbW9kZSAmIFNlbGVjdG9yRmxhZ3MuQ0xBU1MgPyBjdXJyZW50IDogc2VsZWN0b3JbKytpXTtcblxuICAgICAgLy8gc3BlY2lhbCBjYXNlIGZvciBtYXRjaGluZyBhZ2FpbnN0IGNsYXNzZXMgd2hlbiBhIHROb2RlIGhhcyBiZWVuIGluc3RhbnRpYXRlZCB3aXRoXG4gICAgICAvLyBjbGFzcyBhbmQgc3R5bGUgdmFsdWVzIGFzIHNlcGFyYXRlIGF0dHJpYnV0ZSB2YWx1ZXMgKGUuZy4gWyd0aXRsZScsIENMQVNTLCAnZm9vJ10pXG4gICAgICBpZiAoKG1vZGUgJiBTZWxlY3RvckZsYWdzLkNMQVNTKSAmJiB0Tm9kZS5hdHRycyAhPT0gbnVsbCkge1xuICAgICAgICBpZiAoIWlzQ3NzQ2xhc3NNYXRjaGluZyh0Tm9kZS5hdHRycywgc2VsZWN0b3JBdHRyVmFsdWUgYXMgc3RyaW5nLCBpc1Byb2plY3Rpb25Nb2RlKSkge1xuICAgICAgICAgIGlmIChpc1Bvc2l0aXZlKG1vZGUpKSByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgc2tpcFRvTmV4dFNlbGVjdG9yID0gdHJ1ZTtcbiAgICAgICAgfVxuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cblxuICAgICAgY29uc3QgYXR0ck5hbWUgPSAobW9kZSAmIFNlbGVjdG9yRmxhZ3MuQ0xBU1MpID8gJ2NsYXNzJyA6IGN1cnJlbnQ7XG4gICAgICBjb25zdCBhdHRySW5kZXhJbk5vZGUgPVxuICAgICAgICAgIGZpbmRBdHRySW5kZXhJbk5vZGUoYXR0ck5hbWUsIG5vZGVBdHRycywgaXNJbmxpbmVUZW1wbGF0ZSh0Tm9kZSksIGlzUHJvamVjdGlvbk1vZGUpO1xuXG4gICAgICBpZiAoYXR0ckluZGV4SW5Ob2RlID09PSAtMSkge1xuICAgICAgICBpZiAoaXNQb3NpdGl2ZShtb2RlKSkgcmV0dXJuIGZhbHNlO1xuICAgICAgICBza2lwVG9OZXh0U2VsZWN0b3IgPSB0cnVlO1xuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cblxuICAgICAgaWYgKHNlbGVjdG9yQXR0clZhbHVlICE9PSAnJykge1xuICAgICAgICBsZXQgbm9kZUF0dHJWYWx1ZTogc3RyaW5nO1xuICAgICAgICBpZiAoYXR0ckluZGV4SW5Ob2RlID4gbmFtZU9ubHlNYXJrZXJJZHgpIHtcbiAgICAgICAgICBub2RlQXR0clZhbHVlID0gJyc7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgbmdEZXZNb2RlICYmXG4gICAgICAgICAgICAgIGFzc2VydE5vdEVxdWFsKFxuICAgICAgICAgICAgICAgICAgbm9kZUF0dHJzW2F0dHJJbmRleEluTm9kZV0sIEF0dHJpYnV0ZU1hcmtlci5OYW1lc3BhY2VVUkksXG4gICAgICAgICAgICAgICAgICAnV2UgZG8gbm90IG1hdGNoIGRpcmVjdGl2ZXMgb24gbmFtZXNwYWNlZCBhdHRyaWJ1dGVzJyk7XG4gICAgICAgICAgLy8gd2UgbG93ZXJjYXNlIHRoZSBhdHRyaWJ1dGUgdmFsdWUgdG8gYmUgYWJsZSB0byBtYXRjaFxuICAgICAgICAgIC8vIHNlbGVjdG9ycyB3aXRob3V0IGNhc2Utc2Vuc2l0aXZpdHlcbiAgICAgICAgICAvLyAoc2VsZWN0b3JzIGFyZSBhbHJlYWR5IGluIGxvd2VyY2FzZSB3aGVuIGdlbmVyYXRlZClcbiAgICAgICAgICBub2RlQXR0clZhbHVlID0gKG5vZGVBdHRyc1thdHRySW5kZXhJbk5vZGUgKyAxXSBhcyBzdHJpbmcpLnRvTG93ZXJDYXNlKCk7XG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCBjb21wYXJlQWdhaW5zdENsYXNzTmFtZSA9IG1vZGUgJiBTZWxlY3RvckZsYWdzLkNMQVNTID8gbm9kZUF0dHJWYWx1ZSA6IG51bGw7XG4gICAgICAgIGlmIChjb21wYXJlQWdhaW5zdENsYXNzTmFtZSAmJlxuICAgICAgICAgICAgICAgIGNsYXNzSW5kZXhPZihjb21wYXJlQWdhaW5zdENsYXNzTmFtZSwgc2VsZWN0b3JBdHRyVmFsdWUgYXMgc3RyaW5nLCAwKSAhPT0gLTEgfHxcbiAgICAgICAgICAgIG1vZGUgJiBTZWxlY3RvckZsYWdzLkFUVFJJQlVURSAmJiBzZWxlY3RvckF0dHJWYWx1ZSAhPT0gbm9kZUF0dHJWYWx1ZSkge1xuICAgICAgICAgIGlmIChpc1Bvc2l0aXZlKG1vZGUpKSByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgc2tpcFRvTmV4dFNlbGVjdG9yID0gdHJ1ZTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIHJldHVybiBpc1Bvc2l0aXZlKG1vZGUpIHx8IHNraXBUb05leHRTZWxlY3Rvcjtcbn1cblxuZnVuY3Rpb24gaXNQb3NpdGl2ZShtb2RlOiBTZWxlY3RvckZsYWdzKTogYm9vbGVhbiB7XG4gIHJldHVybiAobW9kZSAmIFNlbGVjdG9yRmxhZ3MuTk9UKSA9PT0gMDtcbn1cblxuLyoqXG4gKiBFeGFtaW5lcyB0aGUgYXR0cmlidXRlJ3MgZGVmaW5pdGlvbiBhcnJheSBmb3IgYSBub2RlIHRvIGZpbmQgdGhlIGluZGV4IG9mIHRoZVxuICogYXR0cmlidXRlIHRoYXQgbWF0Y2hlcyB0aGUgZ2l2ZW4gYG5hbWVgLlxuICpcbiAqIE5PVEU6IFRoaXMgd2lsbCBub3QgbWF0Y2ggbmFtZXNwYWNlZCBhdHRyaWJ1dGVzLlxuICpcbiAqIEF0dHJpYnV0ZSBtYXRjaGluZyBkZXBlbmRzIHVwb24gYGlzSW5saW5lVGVtcGxhdGVgIGFuZCBgaXNQcm9qZWN0aW9uTW9kZWAuXG4gKiBUaGUgZm9sbG93aW5nIHRhYmxlIHN1bW1hcml6ZXMgd2hpY2ggdHlwZXMgb2YgYXR0cmlidXRlcyB3ZSBhdHRlbXB0IHRvIG1hdGNoOlxuICpcbiAqID09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09XG4gKiBNb2RlcyAgICAgICAgICAgICAgICAgICB8IE5vcm1hbCBBdHRyaWJ1dGVzIHwgQmluZGluZ3MgQXR0cmlidXRlcyB8IFRlbXBsYXRlIEF0dHJpYnV0ZXMgfCBJMThuXG4gKiBBdHRyaWJ1dGVzXG4gKiA9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PVxuICogSW5saW5lICsgUHJvamVjdGlvbiAgICAgfCBZRVMgICAgICAgICAgICAgICB8IFlFUyAgICAgICAgICAgICAgICAgfCBOTyAgICAgICAgICAgICAgICAgIHwgWUVTXG4gKiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuICogSW5saW5lICsgRGlyZWN0aXZlICAgICAgfCBOTyAgICAgICAgICAgICAgICB8IE5PICAgICAgICAgICAgICAgICAgfCBZRVMgICAgICAgICAgICAgICAgIHwgTk9cbiAqIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tXG4gKiBOb24taW5saW5lICsgUHJvamVjdGlvbiB8IFlFUyAgICAgICAgICAgICAgIHwgWUVTICAgICAgICAgICAgICAgICB8IE5PICAgICAgICAgICAgICAgICAgfCBZRVNcbiAqIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tXG4gKiBOb24taW5saW5lICsgRGlyZWN0aXZlICB8IFlFUyAgICAgICAgICAgICAgIHwgWUVTICAgICAgICAgICAgICAgICB8IE5PICAgICAgICAgICAgICAgICAgfCBZRVNcbiAqID09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09XG4gKlxuICogQHBhcmFtIG5hbWUgdGhlIG5hbWUgb2YgdGhlIGF0dHJpYnV0ZSB0byBmaW5kXG4gKiBAcGFyYW0gYXR0cnMgdGhlIGF0dHJpYnV0ZSBhcnJheSB0byBleGFtaW5lXG4gKiBAcGFyYW0gaXNJbmxpbmVUZW1wbGF0ZSB0cnVlIGlmIHRoZSBub2RlIGJlaW5nIG1hdGNoZWQgaXMgYW4gaW5saW5lIHRlbXBsYXRlIChlLmcuIGAqbmdGb3JgKVxuICogcmF0aGVyIHRoYW4gYSBtYW51YWxseSBleHBhbmRlZCB0ZW1wbGF0ZSBub2RlIChlLmcgYDxuZy10ZW1wbGF0ZT5gKS5cbiAqIEBwYXJhbSBpc1Byb2plY3Rpb25Nb2RlIHRydWUgaWYgd2UgYXJlIG1hdGNoaW5nIGFnYWluc3QgY29udGVudCBwcm9qZWN0aW9uIG90aGVyd2lzZSB3ZSBhcmVcbiAqIG1hdGNoaW5nIGFnYWluc3QgZGlyZWN0aXZlcy5cbiAqL1xuZnVuY3Rpb24gZmluZEF0dHJJbmRleEluTm9kZShcbiAgICBuYW1lOiBzdHJpbmcsIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsLCBpc0lubGluZVRlbXBsYXRlOiBib29sZWFuLFxuICAgIGlzUHJvamVjdGlvbk1vZGU6IGJvb2xlYW4pOiBudW1iZXIge1xuICBpZiAoYXR0cnMgPT09IG51bGwpIHJldHVybiAtMTtcblxuICBsZXQgaSA9IDA7XG5cbiAgaWYgKGlzUHJvamVjdGlvbk1vZGUgfHwgIWlzSW5saW5lVGVtcGxhdGUpIHtcbiAgICBsZXQgYmluZGluZ3NNb2RlID0gZmFsc2U7XG4gICAgd2hpbGUgKGkgPCBhdHRycy5sZW5ndGgpIHtcbiAgICAgIGNvbnN0IG1heWJlQXR0ck5hbWUgPSBhdHRyc1tpXTtcbiAgICAgIGlmIChtYXliZUF0dHJOYW1lID09PSBuYW1lKSB7XG4gICAgICAgIHJldHVybiBpO1xuICAgICAgfSBlbHNlIGlmIChcbiAgICAgICAgICBtYXliZUF0dHJOYW1lID09PSBBdHRyaWJ1dGVNYXJrZXIuQmluZGluZ3MgfHwgbWF5YmVBdHRyTmFtZSA9PT0gQXR0cmlidXRlTWFya2VyLkkxOG4pIHtcbiAgICAgICAgYmluZGluZ3NNb2RlID0gdHJ1ZTtcbiAgICAgIH0gZWxzZSBpZiAoXG4gICAgICAgICAgbWF5YmVBdHRyTmFtZSA9PT0gQXR0cmlidXRlTWFya2VyLkNsYXNzZXMgfHwgbWF5YmVBdHRyTmFtZSA9PT0gQXR0cmlidXRlTWFya2VyLlN0eWxlcykge1xuICAgICAgICBsZXQgdmFsdWUgPSBhdHRyc1srK2ldO1xuICAgICAgICAvLyBXZSBzaG91bGQgc2tpcCBjbGFzc2VzIGhlcmUgYmVjYXVzZSB3ZSBoYXZlIGEgc2VwYXJhdGUgbWVjaGFuaXNtIGZvclxuICAgICAgICAvLyBtYXRjaGluZyBjbGFzc2VzIGluIHByb2plY3Rpb24gbW9kZS5cbiAgICAgICAgd2hpbGUgKHR5cGVvZiB2YWx1ZSA9PT0gJ3N0cmluZycpIHtcbiAgICAgICAgICB2YWx1ZSA9IGF0dHJzWysraV07XG4gICAgICAgIH1cbiAgICAgICAgY29udGludWU7XG4gICAgICB9IGVsc2UgaWYgKG1heWJlQXR0ck5hbWUgPT09IEF0dHJpYnV0ZU1hcmtlci5UZW1wbGF0ZSkge1xuICAgICAgICAvLyBXZSBkbyBub3QgY2FyZSBhYm91dCBUZW1wbGF0ZSBhdHRyaWJ1dGVzIGluIHRoaXMgc2NlbmFyaW8uXG4gICAgICAgIGJyZWFrO1xuICAgICAgfSBlbHNlIGlmIChtYXliZUF0dHJOYW1lID09PSBBdHRyaWJ1dGVNYXJrZXIuTmFtZXNwYWNlVVJJKSB7XG4gICAgICAgIC8vIFNraXAgdGhlIHdob2xlIG5hbWVzcGFjZWQgYXR0cmlidXRlIGFuZCB2YWx1ZS4gVGhpcyBpcyBieSBkZXNpZ24uXG4gICAgICAgIGkgKz0gNDtcbiAgICAgICAgY29udGludWU7XG4gICAgICB9XG4gICAgICAvLyBJbiBiaW5kaW5nIG1vZGUgdGhlcmUgYXJlIG9ubHkgbmFtZXMsIHJhdGhlciB0aGFuIG5hbWUtdmFsdWUgcGFpcnMuXG4gICAgICBpICs9IGJpbmRpbmdzTW9kZSA/IDEgOiAyO1xuICAgIH1cbiAgICAvLyBXZSBkaWQgbm90IG1hdGNoIHRoZSBhdHRyaWJ1dGVcbiAgICByZXR1cm4gLTE7XG4gIH0gZWxzZSB7XG4gICAgcmV0dXJuIG1hdGNoVGVtcGxhdGVBdHRyaWJ1dGUoYXR0cnMsIG5hbWUpO1xuICB9XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc05vZGVNYXRjaGluZ1NlbGVjdG9yTGlzdChcbiAgICB0Tm9kZTogVE5vZGUsIHNlbGVjdG9yOiBDc3NTZWxlY3Rvckxpc3QsIGlzUHJvamVjdGlvbk1vZGU6IGJvb2xlYW4gPSBmYWxzZSk6IGJvb2xlYW4ge1xuICBmb3IgKGxldCBpID0gMDsgaSA8IHNlbGVjdG9yLmxlbmd0aDsgaSsrKSB7XG4gICAgaWYgKGlzTm9kZU1hdGNoaW5nU2VsZWN0b3IodE5vZGUsIHNlbGVjdG9yW2ldLCBpc1Byb2plY3Rpb25Nb2RlKSkge1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIGZhbHNlO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gZ2V0UHJvamVjdEFzQXR0clZhbHVlKHROb2RlOiBUTm9kZSk6IENzc1NlbGVjdG9yfG51bGwge1xuICBjb25zdCBub2RlQXR0cnMgPSB0Tm9kZS5hdHRycztcbiAgaWYgKG5vZGVBdHRycyAhPSBudWxsKSB7XG4gICAgY29uc3QgbmdQcm9qZWN0QXNBdHRySWR4ID0gbm9kZUF0dHJzLmluZGV4T2YoQXR0cmlidXRlTWFya2VyLlByb2plY3RBcyk7XG4gICAgLy8gb25seSBjaGVjayBmb3IgbmdQcm9qZWN0QXMgaW4gYXR0cmlidXRlIG5hbWVzLCBkb24ndCBhY2NpZGVudGFsbHkgbWF0Y2ggYXR0cmlidXRlJ3MgdmFsdWVcbiAgICAvLyAoYXR0cmlidXRlIG5hbWVzIGFyZSBzdG9yZWQgYXQgZXZlbiBpbmRleGVzKVxuICAgIGlmICgobmdQcm9qZWN0QXNBdHRySWR4ICYgMSkgPT09IDApIHtcbiAgICAgIHJldHVybiBub2RlQXR0cnNbbmdQcm9qZWN0QXNBdHRySWR4ICsgMV0gYXMgQ3NzU2VsZWN0b3I7XG4gICAgfVxuICB9XG4gIHJldHVybiBudWxsO1xufVxuXG5mdW5jdGlvbiBnZXROYW1lT25seU1hcmtlckluZGV4KG5vZGVBdHRyczogVEF0dHJpYnV0ZXMpIHtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBub2RlQXR0cnMubGVuZ3RoOyBpKyspIHtcbiAgICBjb25zdCBub2RlQXR0ciA9IG5vZGVBdHRyc1tpXTtcbiAgICBpZiAoaXNOYW1lT25seUF0dHJpYnV0ZU1hcmtlcihub2RlQXR0cikpIHtcbiAgICAgIHJldHVybiBpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gbm9kZUF0dHJzLmxlbmd0aDtcbn1cblxuZnVuY3Rpb24gbWF0Y2hUZW1wbGF0ZUF0dHJpYnV0ZShhdHRyczogVEF0dHJpYnV0ZXMsIG5hbWU6IHN0cmluZyk6IG51bWJlciB7XG4gIGxldCBpID0gYXR0cnMuaW5kZXhPZihBdHRyaWJ1dGVNYXJrZXIuVGVtcGxhdGUpO1xuICBpZiAoaSA+IC0xKSB7XG4gICAgaSsrO1xuICAgIHdoaWxlIChpIDwgYXR0cnMubGVuZ3RoKSB7XG4gICAgICBjb25zdCBhdHRyID0gYXR0cnNbaV07XG4gICAgICAvLyBSZXR1cm4gaW4gY2FzZSB3ZSBjaGVja2VkIGFsbCB0ZW1wbGF0ZSBhdHRycyBhbmQgYXJlIHN3aXRjaGluZyB0byB0aGUgbmV4dCBzZWN0aW9uIGluIHRoZVxuICAgICAgLy8gYXR0cnMgYXJyYXkgKHRoYXQgc3RhcnRzIHdpdGggYSBudW1iZXIgdGhhdCByZXByZXNlbnRzIGFuIGF0dHJpYnV0ZSBtYXJrZXIpLlxuICAgICAgaWYgKHR5cGVvZiBhdHRyID09PSAnbnVtYmVyJykgcmV0dXJuIC0xO1xuICAgICAgaWYgKGF0dHIgPT09IG5hbWUpIHJldHVybiBpO1xuICAgICAgaSsrO1xuICAgIH1cbiAgfVxuICByZXR1cm4gLTE7XG59XG5cbi8qKlxuICogQ2hlY2tzIHdoZXRoZXIgYSBzZWxlY3RvciBpcyBpbnNpZGUgYSBDc3NTZWxlY3Rvckxpc3RcbiAqIEBwYXJhbSBzZWxlY3RvciBTZWxlY3RvciB0byBiZSBjaGVja2VkLlxuICogQHBhcmFtIGxpc3QgTGlzdCBpbiB3aGljaCB0byBsb29rIGZvciB0aGUgc2VsZWN0b3IuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpc1NlbGVjdG9ySW5TZWxlY3Rvckxpc3Qoc2VsZWN0b3I6IENzc1NlbGVjdG9yLCBsaXN0OiBDc3NTZWxlY3Rvckxpc3QpOiBib29sZWFuIHtcbiAgc2VsZWN0b3JMaXN0TG9vcDogZm9yIChsZXQgaSA9IDA7IGkgPCBsaXN0Lmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgY3VycmVudFNlbGVjdG9ySW5MaXN0ID0gbGlzdFtpXTtcbiAgICBpZiAoc2VsZWN0b3IubGVuZ3RoICE9PSBjdXJyZW50U2VsZWN0b3JJbkxpc3QubGVuZ3RoKSB7XG4gICAgICBjb250aW51ZTtcbiAgICB9XG4gICAgZm9yIChsZXQgaiA9IDA7IGogPCBzZWxlY3Rvci5sZW5ndGg7IGorKykge1xuICAgICAgaWYgKHNlbGVjdG9yW2pdICE9PSBjdXJyZW50U2VsZWN0b3JJbkxpc3Rbal0pIHtcbiAgICAgICAgY29udGludWUgc2VsZWN0b3JMaXN0TG9vcDtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHRydWU7XG4gIH1cbiAgcmV0dXJuIGZhbHNlO1xufVxuXG5mdW5jdGlvbiBtYXliZVdyYXBJbk5vdFNlbGVjdG9yKGlzTmVnYXRpdmVNb2RlOiBib29sZWFuLCBjaHVuazogc3RyaW5nKTogc3RyaW5nIHtcbiAgcmV0dXJuIGlzTmVnYXRpdmVNb2RlID8gJzpub3QoJyArIGNodW5rLnRyaW0oKSArICcpJyA6IGNodW5rO1xufVxuXG5mdW5jdGlvbiBzdHJpbmdpZnlDU1NTZWxlY3RvcihzZWxlY3RvcjogQ3NzU2VsZWN0b3IpOiBzdHJpbmcge1xuICBsZXQgcmVzdWx0ID0gc2VsZWN0b3JbMF0gYXMgc3RyaW5nO1xuICBsZXQgaSA9IDE7XG4gIGxldCBtb2RlID0gU2VsZWN0b3JGbGFncy5BVFRSSUJVVEU7XG4gIGxldCBjdXJyZW50Q2h1bmsgPSAnJztcbiAgbGV0IGlzTmVnYXRpdmVNb2RlID0gZmFsc2U7XG4gIHdoaWxlIChpIDwgc2VsZWN0b3IubGVuZ3RoKSB7XG4gICAgbGV0IHZhbHVlT3JNYXJrZXIgPSBzZWxlY3RvcltpXTtcbiAgICBpZiAodHlwZW9mIHZhbHVlT3JNYXJrZXIgPT09ICdzdHJpbmcnKSB7XG4gICAgICBpZiAobW9kZSAmIFNlbGVjdG9yRmxhZ3MuQVRUUklCVVRFKSB7XG4gICAgICAgIGNvbnN0IGF0dHJWYWx1ZSA9IHNlbGVjdG9yWysraV0gYXMgc3RyaW5nO1xuICAgICAgICBjdXJyZW50Q2h1bmsgKz1cbiAgICAgICAgICAgICdbJyArIHZhbHVlT3JNYXJrZXIgKyAoYXR0clZhbHVlLmxlbmd0aCA+IDAgPyAnPVwiJyArIGF0dHJWYWx1ZSArICdcIicgOiAnJykgKyAnXSc7XG4gICAgICB9IGVsc2UgaWYgKG1vZGUgJiBTZWxlY3RvckZsYWdzLkNMQVNTKSB7XG4gICAgICAgIGN1cnJlbnRDaHVuayArPSAnLicgKyB2YWx1ZU9yTWFya2VyO1xuICAgICAgfSBlbHNlIGlmIChtb2RlICYgU2VsZWN0b3JGbGFncy5FTEVNRU5UKSB7XG4gICAgICAgIGN1cnJlbnRDaHVuayArPSAnICcgKyB2YWx1ZU9yTWFya2VyO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAvL1xuICAgICAgLy8gQXBwZW5kIGN1cnJlbnQgY2h1bmsgdG8gdGhlIGZpbmFsIHJlc3VsdCBpbiBjYXNlIHdlIGNvbWUgYWNyb3NzIFNlbGVjdG9yRmxhZywgd2hpY2hcbiAgICAgIC8vIGluZGljYXRlcyB0aGF0IHRoZSBwcmV2aW91cyBzZWN0aW9uIG9mIGEgc2VsZWN0b3IgaXMgb3Zlci4gV2UgbmVlZCB0byBhY2N1bXVsYXRlIGNvbnRlbnRcbiAgICAgIC8vIGJldHdlZW4gZmxhZ3MgdG8gbWFrZSBzdXJlIHdlIHdyYXAgdGhlIGNodW5rIGxhdGVyIGluIDpub3QoKSBzZWxlY3RvciBpZiBuZWVkZWQsIGUuZy5cbiAgICAgIC8vIGBgYFxuICAgICAgLy8gIFsnJywgRmxhZ3MuQ0xBU1MsICcuY2xhc3NBJywgRmxhZ3MuQ0xBU1MgfCBGbGFncy5OT1QsICcuY2xhc3NCJywgJy5jbGFzc0MnXVxuICAgICAgLy8gYGBgXG4gICAgICAvLyBzaG91bGQgYmUgdHJhbnNmb3JtZWQgdG8gYC5jbGFzc0EgOm5vdCguY2xhc3NCIC5jbGFzc0MpYC5cbiAgICAgIC8vXG4gICAgICAvLyBOb3RlOiBmb3IgbmVnYXRpdmUgc2VsZWN0b3IgcGFydCwgd2UgYWNjdW11bGF0ZSBjb250ZW50IGJldHdlZW4gZmxhZ3MgdW50aWwgd2UgZmluZCB0aGVcbiAgICAgIC8vIG5leHQgbmVnYXRpdmUgZmxhZy4gVGhpcyBpcyBuZWVkZWQgdG8gc3VwcG9ydCBhIGNhc2Ugd2hlcmUgYDpub3QoKWAgcnVsZSBjb250YWlucyBtb3JlIHRoYW5cbiAgICAgIC8vIG9uZSBjaHVuaywgZS5nLiB0aGUgZm9sbG93aW5nIHNlbGVjdG9yOlxuICAgICAgLy8gYGBgXG4gICAgICAvLyAgWycnLCBGbGFncy5FTEVNRU5UIHwgRmxhZ3MuTk9ULCAncCcsIEZsYWdzLkNMQVNTLCAnZm9vJywgRmxhZ3MuQ0xBU1MgfCBGbGFncy5OT1QsICdiYXInXVxuICAgICAgLy8gYGBgXG4gICAgICAvLyBzaG91bGQgYmUgc3RyaW5naWZpZWQgdG8gYDpub3QocC5mb28pIDpub3QoLmJhcilgXG4gICAgICAvL1xuICAgICAgaWYgKGN1cnJlbnRDaHVuayAhPT0gJycgJiYgIWlzUG9zaXRpdmUodmFsdWVPck1hcmtlcikpIHtcbiAgICAgICAgcmVzdWx0ICs9IG1heWJlV3JhcEluTm90U2VsZWN0b3IoaXNOZWdhdGl2ZU1vZGUsIGN1cnJlbnRDaHVuayk7XG4gICAgICAgIGN1cnJlbnRDaHVuayA9ICcnO1xuICAgICAgfVxuICAgICAgbW9kZSA9IHZhbHVlT3JNYXJrZXI7XG4gICAgICAvLyBBY2NvcmRpbmcgdG8gQ3NzU2VsZWN0b3Igc3BlYywgb25jZSB3ZSBjb21lIGFjcm9zcyBgU2VsZWN0b3JGbGFncy5OT1RgIGZsYWcsIHRoZSBuZWdhdGl2ZVxuICAgICAgLy8gbW9kZSBpcyBtYWludGFpbmVkIGZvciByZW1haW5pbmcgY2h1bmtzIG9mIGEgc2VsZWN0b3IuXG4gICAgICBpc05lZ2F0aXZlTW9kZSA9IGlzTmVnYXRpdmVNb2RlIHx8ICFpc1Bvc2l0aXZlKG1vZGUpO1xuICAgIH1cbiAgICBpKys7XG4gIH1cbiAgaWYgKGN1cnJlbnRDaHVuayAhPT0gJycpIHtcbiAgICByZXN1bHQgKz0gbWF5YmVXcmFwSW5Ob3RTZWxlY3Rvcihpc05lZ2F0aXZlTW9kZSwgY3VycmVudENodW5rKTtcbiAgfVxuICByZXR1cm4gcmVzdWx0O1xufVxuXG4vKipcbiAqIEdlbmVyYXRlcyBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2YgQ1NTIHNlbGVjdG9yIGluIHBhcnNlZCBmb3JtLlxuICpcbiAqIENvbXBvbmVudERlZiBhbmQgRGlyZWN0aXZlRGVmIGFyZSBnZW5lcmF0ZWQgd2l0aCB0aGUgc2VsZWN0b3IgaW4gcGFyc2VkIGZvcm0gdG8gYXZvaWQgZG9pbmdcbiAqIGFkZGl0aW9uYWwgcGFyc2luZyBhdCBydW50aW1lIChmb3IgZXhhbXBsZSwgZm9yIGRpcmVjdGl2ZSBtYXRjaGluZykuIEhvd2V2ZXIgaW4gc29tZSBjYXNlcyAoZm9yXG4gKiBleGFtcGxlLCB3aGlsZSBib290c3RyYXBwaW5nIGEgY29tcG9uZW50KSwgYSBzdHJpbmcgdmVyc2lvbiBvZiB0aGUgc2VsZWN0b3IgaXMgcmVxdWlyZWQgdG8gcXVlcnlcbiAqIGZvciB0aGUgaG9zdCBlbGVtZW50IG9uIHRoZSBwYWdlLiBUaGlzIGZ1bmN0aW9uIHRha2VzIHRoZSBwYXJzZWQgZm9ybSBvZiBhIHNlbGVjdG9yIGFuZCByZXR1cm5zXG4gKiBpdHMgc3RyaW5nIHJlcHJlc2VudGF0aW9uLlxuICpcbiAqIEBwYXJhbSBzZWxlY3Rvckxpc3Qgc2VsZWN0b3IgaW4gcGFyc2VkIGZvcm1cbiAqIEByZXR1cm5zIHN0cmluZyByZXByZXNlbnRhdGlvbiBvZiBhIGdpdmVuIHNlbGVjdG9yXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzdHJpbmdpZnlDU1NTZWxlY3Rvckxpc3Qoc2VsZWN0b3JMaXN0OiBDc3NTZWxlY3Rvckxpc3QpOiBzdHJpbmcge1xuICByZXR1cm4gc2VsZWN0b3JMaXN0Lm1hcChzdHJpbmdpZnlDU1NTZWxlY3Rvcikuam9pbignLCcpO1xufVxuXG4vKipcbiAqIEV4dHJhY3RzIGF0dHJpYnV0ZXMgYW5kIGNsYXNzZXMgaW5mb3JtYXRpb24gZnJvbSBhIGdpdmVuIENTUyBzZWxlY3Rvci5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGlzIHVzZWQgd2hpbGUgY3JlYXRpbmcgYSBjb21wb25lbnQgZHluYW1pY2FsbHkuIEluIHRoaXMgY2FzZSwgdGhlIGhvc3QgZWxlbWVudFxuICogKHRoYXQgaXMgY3JlYXRlZCBkeW5hbWljYWxseSkgc2hvdWxkIGNvbnRhaW4gYXR0cmlidXRlcyBhbmQgY2xhc3NlcyBzcGVjaWZpZWQgaW4gY29tcG9uZW50J3MgQ1NTXG4gKiBzZWxlY3Rvci5cbiAqXG4gKiBAcGFyYW0gc2VsZWN0b3IgQ1NTIHNlbGVjdG9yIGluIHBhcnNlZCBmb3JtIChpbiBhIGZvcm0gb2YgYXJyYXkpXG4gKiBAcmV0dXJucyBvYmplY3Qgd2l0aCBgYXR0cnNgIGFuZCBgY2xhc3Nlc2AgZmllbGRzIHRoYXQgY29udGFpbiBleHRyYWN0ZWQgaW5mb3JtYXRpb25cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGV4dHJhY3RBdHRyc0FuZENsYXNzZXNGcm9tU2VsZWN0b3Ioc2VsZWN0b3I6IENzc1NlbGVjdG9yKTpcbiAgICB7YXR0cnM6IHN0cmluZ1tdLCBjbGFzc2VzOiBzdHJpbmdbXX0ge1xuICBjb25zdCBhdHRyczogc3RyaW5nW10gPSBbXTtcbiAgY29uc3QgY2xhc3Nlczogc3RyaW5nW10gPSBbXTtcbiAgbGV0IGkgPSAxO1xuICBsZXQgbW9kZSA9IFNlbGVjdG9yRmxhZ3MuQVRUUklCVVRFO1xuICB3aGlsZSAoaSA8IHNlbGVjdG9yLmxlbmd0aCkge1xuICAgIGxldCB2YWx1ZU9yTWFya2VyID0gc2VsZWN0b3JbaV07XG4gICAgaWYgKHR5cGVvZiB2YWx1ZU9yTWFya2VyID09PSAnc3RyaW5nJykge1xuICAgICAgaWYgKG1vZGUgPT09IFNlbGVjdG9yRmxhZ3MuQVRUUklCVVRFKSB7XG4gICAgICAgIGlmICh2YWx1ZU9yTWFya2VyICE9PSAnJykge1xuICAgICAgICAgIGF0dHJzLnB1c2godmFsdWVPck1hcmtlciwgc2VsZWN0b3JbKytpXSBhcyBzdHJpbmcpO1xuICAgICAgICB9XG4gICAgICB9IGVsc2UgaWYgKG1vZGUgPT09IFNlbGVjdG9yRmxhZ3MuQ0xBU1MpIHtcbiAgICAgICAgY2xhc3Nlcy5wdXNoKHZhbHVlT3JNYXJrZXIpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAvLyBBY2NvcmRpbmcgdG8gQ3NzU2VsZWN0b3Igc3BlYywgb25jZSB3ZSBjb21lIGFjcm9zcyBgU2VsZWN0b3JGbGFncy5OT1RgIGZsYWcsIHRoZSBuZWdhdGl2ZVxuICAgICAgLy8gbW9kZSBpcyBtYWludGFpbmVkIGZvciByZW1haW5pbmcgY2h1bmtzIG9mIGEgc2VsZWN0b3IuIFNpbmNlIGF0dHJpYnV0ZXMgYW5kIGNsYXNzZXMgYXJlXG4gICAgICAvLyBleHRyYWN0ZWQgb25seSBmb3IgXCJwb3NpdGl2ZVwiIHBhcnQgb2YgdGhlIHNlbGVjdG9yLCB3ZSBjYW4gc3RvcCBoZXJlLlxuICAgICAgaWYgKCFpc1Bvc2l0aXZlKG1vZGUpKSBicmVhaztcbiAgICAgIG1vZGUgPSB2YWx1ZU9yTWFya2VyO1xuICAgIH1cbiAgICBpKys7XG4gIH1cbiAgcmV0dXJuIHthdHRycywgY2xhc3Nlc307XG59XG4iXX0=