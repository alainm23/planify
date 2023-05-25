/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertTNodeForLView } from '../render3/assert';
import { getLContext } from '../render3/context_discovery';
import { CONTAINER_HEADER_OFFSET, NATIVE } from '../render3/interfaces/container';
import { isComponentHost, isLContainer } from '../render3/interfaces/type_checks';
import { DECLARATION_COMPONENT_VIEW, PARENT, T_HOST, TVIEW } from '../render3/interfaces/view';
import { getComponent, getContext, getInjectionTokens, getInjector, getListeners, getLocalRefs, getOwningComponent } from '../render3/util/discovery_utils';
import { INTERPOLATION_DELIMITER } from '../render3/util/misc_utils';
import { renderStringify } from '../render3/util/stringify_utils';
import { getComponentLViewByIndex, getNativeByTNodeOrNull } from '../render3/util/view_utils';
import { assertDomNode } from '../util/assert';
/**
 * @publicApi
 */
export class DebugEventListener {
    constructor(name, callback) {
        this.name = name;
        this.callback = callback;
    }
}
/**
 * @publicApi
 */
export function asNativeElements(debugEls) {
    return debugEls.map((el) => el.nativeElement);
}
/**
 * @publicApi
 */
export class DebugNode {
    constructor(nativeNode) {
        this.nativeNode = nativeNode;
    }
    /**
     * The `DebugElement` parent. Will be `null` if this is the root element.
     */
    get parent() {
        const parent = this.nativeNode.parentNode;
        return parent ? new DebugElement(parent) : null;
    }
    /**
     * The host dependency injector. For example, the root element's component instance injector.
     */
    get injector() {
        return getInjector(this.nativeNode);
    }
    /**
     * The element's own component instance, if it has one.
     */
    get componentInstance() {
        const nativeElement = this.nativeNode;
        return nativeElement &&
            (getComponent(nativeElement) || getOwningComponent(nativeElement));
    }
    /**
     * An object that provides parent context for this element. Often an ancestor component instance
     * that governs this element.
     *
     * When an element is repeated within *ngFor, the context is an `NgForOf` whose `$implicit`
     * property is the value of the row instance value. For example, the `hero` in `*ngFor="let hero
     * of heroes"`.
     */
    get context() {
        return getComponent(this.nativeNode) || getContext(this.nativeNode);
    }
    /**
     * The callbacks attached to the component's @Output properties and/or the element's event
     * properties.
     */
    get listeners() {
        return getListeners(this.nativeNode).filter(listener => listener.type === 'dom');
    }
    /**
     * Dictionary of objects associated with template local variables (e.g. #foo), keyed by the local
     * variable name.
     */
    get references() {
        return getLocalRefs(this.nativeNode);
    }
    /**
     * This component's injector lookup tokens. Includes the component itself plus the tokens that the
     * component lists in its providers metadata.
     */
    get providerTokens() {
        return getInjectionTokens(this.nativeNode);
    }
}
/**
 * @publicApi
 *
 * @see [Component testing scenarios](guide/testing-components-scenarios)
 * @see [Basics of testing components](guide/testing-components-basics)
 * @see [Testing utility APIs](guide/testing-utility-apis)
 */
export class DebugElement extends DebugNode {
    constructor(nativeNode) {
        ngDevMode && assertDomNode(nativeNode);
        super(nativeNode);
    }
    /**
     * The underlying DOM element at the root of the component.
     */
    get nativeElement() {
        return this.nativeNode.nodeType == Node.ELEMENT_NODE ? this.nativeNode : null;
    }
    /**
     * The element tag name, if it is an element.
     */
    get name() {
        const context = getLContext(this.nativeNode);
        const lView = context ? context.lView : null;
        if (lView !== null) {
            const tData = lView[TVIEW].data;
            const tNode = tData[context.nodeIndex];
            return tNode.value;
        }
        else {
            return this.nativeNode.nodeName;
        }
    }
    /**
     *  Gets a map of property names to property values for an element.
     *
     *  This map includes:
     *  - Regular property bindings (e.g. `[id]="id"`)
     *  - Host property bindings (e.g. `host: { '[id]': "id" }`)
     *  - Interpolated property bindings (e.g. `id="{{ value }}")
     *
     *  It does not include:
     *  - input property bindings (e.g. `[myCustomInput]="value"`)
     *  - attribute bindings (e.g. `[attr.role]="menu"`)
     */
    get properties() {
        const context = getLContext(this.nativeNode);
        const lView = context ? context.lView : null;
        if (lView === null) {
            return {};
        }
        const tData = lView[TVIEW].data;
        const tNode = tData[context.nodeIndex];
        const properties = {};
        // Collect properties from the DOM.
        copyDomProperties(this.nativeElement, properties);
        // Collect properties from the bindings. This is needed for animation renderer which has
        // synthetic properties which don't get reflected into the DOM.
        collectPropertyBindings(properties, tNode, lView, tData);
        return properties;
    }
    /**
     *  A map of attribute names to attribute values for an element.
     */
    get attributes() {
        const attributes = {};
        const element = this.nativeElement;
        if (!element) {
            return attributes;
        }
        const context = getLContext(element);
        const lView = context ? context.lView : null;
        if (lView === null) {
            return {};
        }
        const tNodeAttrs = lView[TVIEW].data[context.nodeIndex].attrs;
        const lowercaseTNodeAttrs = [];
        // For debug nodes we take the element's attribute directly from the DOM since it allows us
        // to account for ones that weren't set via bindings (e.g. ViewEngine keeps track of the ones
        // that are set through `Renderer2`). The problem is that the browser will lowercase all names,
        // however since we have the attributes already on the TNode, we can preserve the case by going
        // through them once, adding them to the `attributes` map and putting their lower-cased name
        // into an array. Afterwards when we're going through the native DOM attributes, we can check
        // whether we haven't run into an attribute already through the TNode.
        if (tNodeAttrs) {
            let i = 0;
            while (i < tNodeAttrs.length) {
                const attrName = tNodeAttrs[i];
                // Stop as soon as we hit a marker. We only care about the regular attributes. Everything
                // else will be handled below when we read the final attributes off the DOM.
                if (typeof attrName !== 'string')
                    break;
                const attrValue = tNodeAttrs[i + 1];
                attributes[attrName] = attrValue;
                lowercaseTNodeAttrs.push(attrName.toLowerCase());
                i += 2;
            }
        }
        for (const attr of element.attributes) {
            // Make sure that we don't assign the same attribute both in its
            // case-sensitive form and the lower-cased one from the browser.
            if (!lowercaseTNodeAttrs.includes(attr.name)) {
                attributes[attr.name] = attr.value;
            }
        }
        return attributes;
    }
    /**
     * The inline styles of the DOM element.
     *
     * Will be `null` if there is no `style` property on the underlying DOM element.
     *
     * @see [ElementCSSInlineStyle](https://developer.mozilla.org/en-US/docs/Web/API/ElementCSSInlineStyle/style)
     */
    get styles() {
        if (this.nativeElement && this.nativeElement.style) {
            return this.nativeElement.style;
        }
        return {};
    }
    /**
     * A map containing the class names on the element as keys.
     *
     * This map is derived from the `className` property of the DOM element.
     *
     * Note: The values of this object will always be `true`. The class key will not appear in the KV
     * object if it does not exist on the element.
     *
     * @see [Element.className](https://developer.mozilla.org/en-US/docs/Web/API/Element/className)
     */
    get classes() {
        const result = {};
        const element = this.nativeElement;
        // SVG elements return an `SVGAnimatedString` instead of a plain string for the `className`.
        const className = element.className;
        const classes = typeof className !== 'string' ? className.baseVal.split(' ') : className.split(' ');
        classes.forEach((value) => result[value] = true);
        return result;
    }
    /**
     * The `childNodes` of the DOM element as a `DebugNode` array.
     *
     * @see [Node.childNodes](https://developer.mozilla.org/en-US/docs/Web/API/Node/childNodes)
     */
    get childNodes() {
        const childNodes = this.nativeNode.childNodes;
        const children = [];
        for (let i = 0; i < childNodes.length; i++) {
            const element = childNodes[i];
            children.push(getDebugNode(element));
        }
        return children;
    }
    /**
     * The immediate `DebugElement` children. Walk the tree by descending through `children`.
     */
    get children() {
        const nativeElement = this.nativeElement;
        if (!nativeElement)
            return [];
        const childNodes = nativeElement.children;
        const children = [];
        for (let i = 0; i < childNodes.length; i++) {
            const element = childNodes[i];
            children.push(getDebugNode(element));
        }
        return children;
    }
    /**
     * @returns the first `DebugElement` that matches the predicate at any depth in the subtree.
     */
    query(predicate) {
        const results = this.queryAll(predicate);
        return results[0] || null;
    }
    /**
     * @returns All `DebugElement` matches for the predicate at any depth in the subtree.
     */
    queryAll(predicate) {
        const matches = [];
        _queryAll(this, predicate, matches, true);
        return matches;
    }
    /**
     * @returns All `DebugNode` matches for the predicate at any depth in the subtree.
     */
    queryAllNodes(predicate) {
        const matches = [];
        _queryAll(this, predicate, matches, false);
        return matches;
    }
    /**
     * Triggers the event by its name if there is a corresponding listener in the element's
     * `listeners` collection.
     *
     * If the event lacks a listener or there's some other problem, consider
     * calling `nativeElement.dispatchEvent(eventObject)`.
     *
     * @param eventName The name of the event to trigger
     * @param eventObj The _event object_ expected by the handler
     *
     * @see [Testing components scenarios](guide/testing-components-scenarios#trigger-event-handler)
     */
    triggerEventHandler(eventName, eventObj) {
        const node = this.nativeNode;
        const invokedListeners = [];
        this.listeners.forEach(listener => {
            if (listener.name === eventName) {
                const callback = listener.callback;
                callback.call(node, eventObj);
                invokedListeners.push(callback);
            }
        });
        // We need to check whether `eventListeners` exists, because it's something
        // that Zone.js only adds to `EventTarget` in browser environments.
        if (typeof node.eventListeners === 'function') {
            // Note that in Ivy we wrap event listeners with a call to `event.preventDefault` in some
            // cases. We use '__ngUnwrap__' as a special token that gives us access to the actual event
            // listener.
            node.eventListeners(eventName).forEach((listener) => {
                // In order to ensure that we can detect the special __ngUnwrap__ token described above, we
                // use `toString` on the listener and see if it contains the token. We use this approach to
                // ensure that it still worked with compiled code since it cannot remove or rename string
                // literals. We also considered using a special function name (i.e. if(listener.name ===
                // special)) but that was more cumbersome and we were also concerned the compiled code could
                // strip the name, turning the condition in to ("" === "") and always returning true.
                if (listener.toString().indexOf('__ngUnwrap__') !== -1) {
                    const unwrappedListener = listener('__ngUnwrap__');
                    return invokedListeners.indexOf(unwrappedListener) === -1 &&
                        unwrappedListener.call(node, eventObj);
                }
            });
        }
    }
}
function copyDomProperties(element, properties) {
    if (element) {
        // Skip own properties (as those are patched)
        let obj = Object.getPrototypeOf(element);
        const NodePrototype = Node.prototype;
        while (obj !== null && obj !== NodePrototype) {
            const descriptors = Object.getOwnPropertyDescriptors(obj);
            for (let key in descriptors) {
                if (!key.startsWith('__') && !key.startsWith('on')) {
                    // don't include properties starting with `__` and `on`.
                    // `__` are patched values which should not be included.
                    // `on` are listeners which also should not be included.
                    const value = element[key];
                    if (isPrimitiveValue(value)) {
                        properties[key] = value;
                    }
                }
            }
            obj = Object.getPrototypeOf(obj);
        }
    }
}
function isPrimitiveValue(value) {
    return typeof value === 'string' || typeof value === 'boolean' || typeof value === 'number' ||
        value === null;
}
function _queryAll(parentElement, predicate, matches, elementsOnly) {
    const context = getLContext(parentElement.nativeNode);
    const lView = context ? context.lView : null;
    if (lView !== null) {
        const parentTNode = lView[TVIEW].data[context.nodeIndex];
        _queryNodeChildren(parentTNode, lView, predicate, matches, elementsOnly, parentElement.nativeNode);
    }
    else {
        // If the context is null, then `parentElement` was either created with Renderer2 or native DOM
        // APIs.
        _queryNativeNodeDescendants(parentElement.nativeNode, predicate, matches, elementsOnly);
    }
}
/**
 * Recursively match the current TNode against the predicate, and goes on with the next ones.
 *
 * @param tNode the current TNode
 * @param lView the LView of this TNode
 * @param predicate the predicate to match
 * @param matches the list of positive matches
 * @param elementsOnly whether only elements should be searched
 * @param rootNativeNode the root native node on which predicate should not be matched
 */
function _queryNodeChildren(tNode, lView, predicate, matches, elementsOnly, rootNativeNode) {
    ngDevMode && assertTNodeForLView(tNode, lView);
    const nativeNode = getNativeByTNodeOrNull(tNode, lView);
    // For each type of TNode, specific logic is executed.
    if (tNode.type & (3 /* TNodeType.AnyRNode */ | 8 /* TNodeType.ElementContainer */)) {
        // Case 1: the TNode is an element
        // The native node has to be checked.
        _addQueryMatch(nativeNode, predicate, matches, elementsOnly, rootNativeNode);
        if (isComponentHost(tNode)) {
            // If the element is the host of a component, then all nodes in its view have to be processed.
            // Note: the component's content (tNode.child) will be processed from the insertion points.
            const componentView = getComponentLViewByIndex(tNode.index, lView);
            if (componentView && componentView[TVIEW].firstChild) {
                _queryNodeChildren(componentView[TVIEW].firstChild, componentView, predicate, matches, elementsOnly, rootNativeNode);
            }
        }
        else {
            if (tNode.child) {
                // Otherwise, its children have to be processed.
                _queryNodeChildren(tNode.child, lView, predicate, matches, elementsOnly, rootNativeNode);
            }
            // We also have to query the DOM directly in order to catch elements inserted through
            // Renderer2. Note that this is __not__ optimal, because we're walking similar trees multiple
            // times. ViewEngine could do it more efficiently, because all the insertions go through
            // Renderer2, however that's not the case in Ivy. This approach is being used because:
            // 1. Matching the ViewEngine behavior would mean potentially introducing a dependency
            //    from `Renderer2` to Ivy which could bring Ivy code into ViewEngine.
            // 2. It allows us to capture nodes that were inserted directly via the DOM.
            nativeNode && _queryNativeNodeDescendants(nativeNode, predicate, matches, elementsOnly);
        }
        // In all cases, if a dynamic container exists for this node, each view inside it has to be
        // processed.
        const nodeOrContainer = lView[tNode.index];
        if (isLContainer(nodeOrContainer)) {
            _queryNodeChildrenInContainer(nodeOrContainer, predicate, matches, elementsOnly, rootNativeNode);
        }
    }
    else if (tNode.type & 4 /* TNodeType.Container */) {
        // Case 2: the TNode is a container
        // The native node has to be checked.
        const lContainer = lView[tNode.index];
        _addQueryMatch(lContainer[NATIVE], predicate, matches, elementsOnly, rootNativeNode);
        // Each view inside the container has to be processed.
        _queryNodeChildrenInContainer(lContainer, predicate, matches, elementsOnly, rootNativeNode);
    }
    else if (tNode.type & 16 /* TNodeType.Projection */) {
        // Case 3: the TNode is a projection insertion point (i.e. a <ng-content>).
        // The nodes projected at this location all need to be processed.
        const componentView = lView[DECLARATION_COMPONENT_VIEW];
        const componentHost = componentView[T_HOST];
        const head = componentHost.projection[tNode.projection];
        if (Array.isArray(head)) {
            for (let nativeNode of head) {
                _addQueryMatch(nativeNode, predicate, matches, elementsOnly, rootNativeNode);
            }
        }
        else if (head) {
            const nextLView = componentView[PARENT];
            const nextTNode = nextLView[TVIEW].data[head.index];
            _queryNodeChildren(nextTNode, nextLView, predicate, matches, elementsOnly, rootNativeNode);
        }
    }
    else if (tNode.child) {
        // Case 4: the TNode is a view.
        _queryNodeChildren(tNode.child, lView, predicate, matches, elementsOnly, rootNativeNode);
    }
    // We don't want to go to the next sibling of the root node.
    if (rootNativeNode !== nativeNode) {
        // To determine the next node to be processed, we need to use the next or the projectionNext
        // link, depending on whether the current node has been projected.
        const nextTNode = (tNode.flags & 2 /* TNodeFlags.isProjected */) ? tNode.projectionNext : tNode.next;
        if (nextTNode) {
            _queryNodeChildren(nextTNode, lView, predicate, matches, elementsOnly, rootNativeNode);
        }
    }
}
/**
 * Process all TNodes in a given container.
 *
 * @param lContainer the container to be processed
 * @param predicate the predicate to match
 * @param matches the list of positive matches
 * @param elementsOnly whether only elements should be searched
 * @param rootNativeNode the root native node on which predicate should not be matched
 */
function _queryNodeChildrenInContainer(lContainer, predicate, matches, elementsOnly, rootNativeNode) {
    for (let i = CONTAINER_HEADER_OFFSET; i < lContainer.length; i++) {
        const childView = lContainer[i];
        const firstChild = childView[TVIEW].firstChild;
        if (firstChild) {
            _queryNodeChildren(firstChild, childView, predicate, matches, elementsOnly, rootNativeNode);
        }
    }
}
/**
 * Match the current native node against the predicate.
 *
 * @param nativeNode the current native node
 * @param predicate the predicate to match
 * @param matches the list of positive matches
 * @param elementsOnly whether only elements should be searched
 * @param rootNativeNode the root native node on which predicate should not be matched
 */
function _addQueryMatch(nativeNode, predicate, matches, elementsOnly, rootNativeNode) {
    if (rootNativeNode !== nativeNode) {
        const debugNode = getDebugNode(nativeNode);
        if (!debugNode) {
            return;
        }
        // Type of the "predicate and "matches" array are set based on the value of
        // the "elementsOnly" parameter. TypeScript is not able to properly infer these
        // types with generics, so we manually cast the parameters accordingly.
        if (elementsOnly && (debugNode instanceof DebugElement) && predicate(debugNode) &&
            matches.indexOf(debugNode) === -1) {
            matches.push(debugNode);
        }
        else if (!elementsOnly && predicate(debugNode) &&
            matches.indexOf(debugNode) === -1) {
            matches.push(debugNode);
        }
    }
}
/**
 * Match all the descendants of a DOM node against a predicate.
 *
 * @param nativeNode the current native node
 * @param predicate the predicate to match
 * @param matches the list where matches are stored
 * @param elementsOnly whether only elements should be searched
 */
function _queryNativeNodeDescendants(parentNode, predicate, matches, elementsOnly) {
    const nodes = parentNode.childNodes;
    const length = nodes.length;
    for (let i = 0; i < length; i++) {
        const node = nodes[i];
        const debugNode = getDebugNode(node);
        if (debugNode) {
            if (elementsOnly && (debugNode instanceof DebugElement) && predicate(debugNode) &&
                matches.indexOf(debugNode) === -1) {
                matches.push(debugNode);
            }
            else if (!elementsOnly && predicate(debugNode) &&
                matches.indexOf(debugNode) === -1) {
                matches.push(debugNode);
            }
            _queryNativeNodeDescendants(node, predicate, matches, elementsOnly);
        }
    }
}
/**
 * Iterates through the property bindings for a given node and generates
 * a map of property names to values. This map only contains property bindings
 * defined in templates, not in host bindings.
 */
function collectPropertyBindings(properties, tNode, lView, tData) {
    let bindingIndexes = tNode.propertyBindings;
    if (bindingIndexes !== null) {
        for (let i = 0; i < bindingIndexes.length; i++) {
            const bindingIndex = bindingIndexes[i];
            const propMetadata = tData[bindingIndex];
            const metadataParts = propMetadata.split(INTERPOLATION_DELIMITER);
            const propertyName = metadataParts[0];
            if (metadataParts.length > 1) {
                let value = metadataParts[1];
                for (let j = 1; j < metadataParts.length - 1; j++) {
                    value += renderStringify(lView[bindingIndex + j - 1]) + metadataParts[j + 1];
                }
                properties[propertyName] = value;
            }
            else {
                properties[propertyName] = lView[bindingIndex];
            }
        }
    }
}
// Need to keep the nodes in a global Map so that multiple angular apps are supported.
const _nativeNodeToDebugNode = new Map();
const NG_DEBUG_PROPERTY = '__ng_debug__';
/**
 * @publicApi
 */
export function getDebugNode(nativeNode) {
    if (nativeNode instanceof Node) {
        if (!(nativeNode.hasOwnProperty(NG_DEBUG_PROPERTY))) {
            nativeNode[NG_DEBUG_PROPERTY] = nativeNode.nodeType == Node.ELEMENT_NODE ?
                new DebugElement(nativeNode) :
                new DebugNode(nativeNode);
        }
        return nativeNode[NG_DEBUG_PROPERTY];
    }
    return null;
}
export function getAllDebugNodes() {
    return Array.from(_nativeNodeToDebugNode.values());
}
export function indexDebugNode(node) {
    _nativeNodeToDebugNode.set(node.nativeNode, node);
}
export function removeDebugNodeFromIndex(node) {
    _nativeNodeToDebugNode.delete(node.nativeNode);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZGVidWdfbm9kZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2RlYnVnL2RlYnVnX25vZGUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBR0gsT0FBTyxFQUFDLG1CQUFtQixFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDdEQsT0FBTyxFQUFDLFdBQVcsRUFBQyxNQUFNLDhCQUE4QixDQUFDO0FBQ3pELE9BQU8sRUFBQyx1QkFBdUIsRUFBYyxNQUFNLEVBQUMsTUFBTSxpQ0FBaUMsQ0FBQztBQUU1RixPQUFPLEVBQUMsZUFBZSxFQUFFLFlBQVksRUFBQyxNQUFNLG1DQUFtQyxDQUFDO0FBQ2hGLE9BQU8sRUFBQywwQkFBMEIsRUFBUyxNQUFNLEVBQUUsTUFBTSxFQUFTLEtBQUssRUFBQyxNQUFNLDRCQUE0QixDQUFDO0FBQzNHLE9BQU8sRUFBQyxZQUFZLEVBQUUsVUFBVSxFQUFFLGtCQUFrQixFQUFFLFdBQVcsRUFBRSxZQUFZLEVBQUUsWUFBWSxFQUFFLGtCQUFrQixFQUFDLE1BQU0saUNBQWlDLENBQUM7QUFDMUosT0FBTyxFQUFDLHVCQUF1QixFQUFDLE1BQU0sNEJBQTRCLENBQUM7QUFDbkUsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQ2hFLE9BQU8sRUFBQyx3QkFBd0IsRUFBRSxzQkFBc0IsRUFBQyxNQUFNLDRCQUE0QixDQUFDO0FBQzVGLE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUU3Qzs7R0FFRztBQUNILE1BQU0sT0FBTyxrQkFBa0I7SUFDN0IsWUFBbUIsSUFBWSxFQUFTLFFBQWtCO1FBQXZDLFNBQUksR0FBSixJQUFJLENBQVE7UUFBUyxhQUFRLEdBQVIsUUFBUSxDQUFVO0lBQUcsQ0FBQztDQUMvRDtBQUVEOztHQUVHO0FBQ0gsTUFBTSxVQUFVLGdCQUFnQixDQUFDLFFBQXdC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c0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7SW5qZWN0b3J9IGZyb20gJy4uL2RpL2luamVjdG9yJztcbmltcG9ydCB7YXNzZXJ0VE5vZGVGb3JMVmlld30gZnJvbSAnLi4vcmVuZGVyMy9hc3NlcnQnO1xuaW1wb3J0IHtnZXRMQ29udGV4dH0gZnJvbSAnLi4vcmVuZGVyMy9jb250ZXh0X2Rpc2NvdmVyeSc7XG5pbXBvcnQge0NPTlRBSU5FUl9IRUFERVJfT0ZGU0VULCBMQ29udGFpbmVyLCBOQVRJVkV9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy9jb250YWluZXInO1xuaW1wb3J0IHtURWxlbWVudE5vZGUsIFROb2RlLCBUTm9kZUZsYWdzLCBUTm9kZVR5cGV9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7aXNDb21wb25lbnRIb3N0LCBpc0xDb250YWluZXJ9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy90eXBlX2NoZWNrcyc7XG5pbXBvcnQge0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXLCBMVmlldywgUEFSRU5ULCBUX0hPU1QsIFREYXRhLCBUVklFV30gZnJvbSAnLi4vcmVuZGVyMy9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtnZXRDb21wb25lbnQsIGdldENvbnRleHQsIGdldEluamVjdGlvblRva2VucywgZ2V0SW5qZWN0b3IsIGdldExpc3RlbmVycywgZ2V0TG9jYWxSZWZzLCBnZXRPd25pbmdDb21wb25lbnR9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC9kaXNjb3ZlcnlfdXRpbHMnO1xuaW1wb3J0IHtJTlRFUlBPTEFUSU9OX0RFTElNSVRFUn0gZnJvbSAnLi4vcmVuZGVyMy91dGlsL21pc2NfdXRpbHMnO1xuaW1wb3J0IHtyZW5kZXJTdHJpbmdpZnl9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC9zdHJpbmdpZnlfdXRpbHMnO1xuaW1wb3J0IHtnZXRDb21wb25lbnRMVmlld0J5SW5kZXgsIGdldE5hdGl2ZUJ5VE5vZGVPck51bGx9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC92aWV3X3V0aWxzJztcbmltcG9ydCB7YXNzZXJ0RG9tTm9kZX0gZnJvbSAnLi4vdXRpbC9hc3NlcnQnO1xuXG4vKipcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGNsYXNzIERlYnVnRXZlbnRMaXN0ZW5lciB7XG4gIGNvbnN0cnVjdG9yKHB1YmxpYyBuYW1lOiBzdHJpbmcsIHB1YmxpYyBjYWxsYmFjazogRnVuY3Rpb24pIHt9XG59XG5cbi8qKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gYXNOYXRpdmVFbGVtZW50cyhkZWJ1Z0VsczogRGVidWdFbGVtZW50W10pOiBhbnkge1xuICByZXR1cm4gZGVidWdFbHMubWFwKChlbCkgPT4gZWwubmF0aXZlRWxlbWVudCk7XG59XG5cbi8qKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgY2xhc3MgRGVidWdOb2RlIHtcbiAgLyoqXG4gICAqIFRoZSB1bmRlcmx5aW5nIERPTSBub2RlLlxuICAgKi9cbiAgcmVhZG9ubHkgbmF0aXZlTm9kZTogYW55O1xuXG4gIGNvbnN0cnVjdG9yKG5hdGl2ZU5vZGU6IE5vZGUpIHtcbiAgICB0aGlzLm5hdGl2ZU5vZGUgPSBuYXRpdmVOb2RlO1xuICB9XG5cbiAgLyoqXG4gICAqIFRoZSBgRGVidWdFbGVtZW50YCBwYXJlbnQuIFdpbGwgYmUgYG51bGxgIGlmIHRoaXMgaXMgdGhlIHJvb3QgZWxlbWVudC5cbiAgICovXG4gIGdldCBwYXJlbnQoKTogRGVidWdFbGVtZW50fG51bGwge1xuICAgIGNvbnN0IHBhcmVudCA9IHRoaXMubmF0aXZlTm9kZS5wYXJlbnROb2RlIGFzIEVsZW1lbnQ7XG4gICAgcmV0dXJuIHBhcmVudCA/IG5ldyBEZWJ1Z0VsZW1lbnQocGFyZW50KSA6IG51bGw7XG4gIH1cblxuICAvKipcbiAgICogVGhlIGhvc3QgZGVwZW5kZW5jeSBpbmplY3Rvci4gRm9yIGV4YW1wbGUsIHRoZSByb290IGVsZW1lbnQncyBjb21wb25lbnQgaW5zdGFuY2UgaW5qZWN0b3IuXG4gICAqL1xuICBnZXQgaW5qZWN0b3IoKTogSW5qZWN0b3Ige1xuICAgIHJldHVybiBnZXRJbmplY3Rvcih0aGlzLm5hdGl2ZU5vZGUpO1xuICB9XG5cbiAgLyoqXG4gICAqIFRoZSBlbGVtZW50J3Mgb3duIGNvbXBvbmVudCBpbnN0YW5jZSwgaWYgaXQgaGFzIG9uZS5cbiAgICovXG4gIGdldCBjb21wb25lbnRJbnN0YW5jZSgpOiBhbnkge1xuICAgIGNvbnN0IG5hdGl2ZUVsZW1lbnQgPSB0aGlzLm5hdGl2ZU5vZGU7XG4gICAgcmV0dXJuIG5hdGl2ZUVsZW1lbnQgJiZcbiAgICAgICAgKGdldENvbXBvbmVudChuYXRpdmVFbGVtZW50IGFzIEVsZW1lbnQpIHx8IGdldE93bmluZ0NvbXBvbmVudChuYXRpdmVFbGVtZW50KSk7XG4gIH1cblxuICAvKipcbiAgICogQW4gb2JqZWN0IHRoYXQgcHJvdmlkZXMgcGFyZW50IGNvbnRleHQgZm9yIHRoaXMgZWxlbWVudC4gT2Z0ZW4gYW4gYW5jZXN0b3IgY29tcG9uZW50IGluc3RhbmNlXG4gICAqIHRoYXQgZ292ZXJucyB0aGlzIGVsZW1lbnQuXG4gICAqXG4gICAqIFdoZW4gYW4gZWxlbWVudCBpcyByZXBlYXRlZCB3aXRoaW4gKm5nRm9yLCB0aGUgY29udGV4dCBpcyBhbiBgTmdGb3JPZmAgd2hvc2UgYCRpbXBsaWNpdGBcbiAgICogcHJvcGVydHkgaXMgdGhlIHZhbHVlIG9mIHRoZSByb3cgaW5zdGFuY2UgdmFsdWUuIEZvciBleGFtcGxlLCB0aGUgYGhlcm9gIGluIGAqbmdGb3I9XCJsZXQgaGVyb1xuICAgKiBvZiBoZXJvZXNcImAuXG4gICAqL1xuICBnZXQgY29udGV4dCgpOiBhbnkge1xuICAgIHJldHVybiBnZXRDb21wb25lbnQodGhpcy5uYXRpdmVOb2RlIGFzIEVsZW1lbnQpIHx8IGdldENvbnRleHQodGhpcy5uYXRpdmVOb2RlIGFzIEVsZW1lbnQpO1xuICB9XG5cbiAgLyoqXG4gICAqIFRoZSBjYWxsYmFja3MgYXR0YWNoZWQgdG8gdGhlIGNvbXBvbmVudCdzIEBPdXRwdXQgcHJvcGVydGllcyBhbmQvb3IgdGhlIGVsZW1lbnQncyBldmVudFxuICAgKiBwcm9wZXJ0aWVzLlxuICAgKi9cbiAgZ2V0IGxpc3RlbmVycygpOiBEZWJ1Z0V2ZW50TGlzdGVuZXJbXSB7XG4gICAgcmV0dXJuIGdldExpc3RlbmVycyh0aGlzLm5hdGl2ZU5vZGUgYXMgRWxlbWVudCkuZmlsdGVyKGxpc3RlbmVyID0+IGxpc3RlbmVyLnR5cGUgPT09ICdkb20nKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBEaWN0aW9uYXJ5IG9mIG9iamVjdHMgYXNzb2NpYXRlZCB3aXRoIHRlbXBsYXRlIGxvY2FsIHZhcmlhYmxlcyAoZS5nLiAjZm9vKSwga2V5ZWQgYnkgdGhlIGxvY2FsXG4gICAqIHZhcmlhYmxlIG5hbWUuXG4gICAqL1xuICBnZXQgcmVmZXJlbmNlcygpOiB7W2tleTogc3RyaW5nXTogYW55fSB7XG4gICAgcmV0dXJuIGdldExvY2FsUmVmcyh0aGlzLm5hdGl2ZU5vZGUpO1xuICB9XG5cbiAgLyoqXG4gICAqIFRoaXMgY29tcG9uZW50J3MgaW5qZWN0b3IgbG9va3VwIHRva2Vucy4gSW5jbHVkZXMgdGhlIGNvbXBvbmVudCBpdHNlbGYgcGx1cyB0aGUgdG9rZW5zIHRoYXQgdGhlXG4gICAqIGNvbXBvbmVudCBsaXN0cyBpbiBpdHMgcHJvdmlkZXJzIG1ldGFkYXRhLlxuICAgKi9cbiAgZ2V0IHByb3ZpZGVyVG9rZW5zKCk6IGFueVtdIHtcbiAgICByZXR1cm4gZ2V0SW5qZWN0aW9uVG9rZW5zKHRoaXMubmF0aXZlTm9kZSBhcyBFbGVtZW50KTtcbiAgfVxufVxuXG4vKipcbiAqIEBwdWJsaWNBcGlcbiAqXG4gKiBAc2VlIFtDb21wb25lbnQgdGVzdGluZyBzY2VuYXJpb3NdKGd1aWRlL3Rlc3RpbmctY29tcG9uZW50cy1zY2VuYXJpb3MpXG4gKiBAc2VlIFtCYXNpY3Mgb2YgdGVzdGluZyBjb21wb25lbnRzXShndWlkZS90ZXN0aW5nLWNvbXBvbmVudHMtYmFzaWNzKVxuICogQHNlZSBbVGVzdGluZyB1dGlsaXR5IEFQSXNdKGd1aWRlL3Rlc3RpbmctdXRpbGl0eS1hcGlzKVxuICovXG5leHBvcnQgY2xhc3MgRGVidWdFbGVtZW50IGV4dGVuZHMgRGVidWdOb2RlIHtcbiAgY29uc3RydWN0b3IobmF0aXZlTm9kZTogRWxlbWVudCkge1xuICAgIG5nRGV2TW9kZSAmJiBhc3NlcnREb21Ob2RlKG5hdGl2ZU5vZGUpO1xuICAgIHN1cGVyKG5hdGl2ZU5vZGUpO1xuICB9XG5cbiAgLyoqXG4gICAqIFRoZSB1bmRlcmx5aW5nIERPTSBlbGVtZW50IGF0IHRoZSByb290IG9mIHRoZSBjb21wb25lbnQuXG4gICAqL1xuICBnZXQgbmF0aXZlRWxlbWVudCgpOiBhbnkge1xuICAgIHJldHVybiB0aGlzLm5hdGl2ZU5vZGUubm9kZVR5cGUgPT0gTm9kZS5FTEVNRU5UX05PREUgPyB0aGlzLm5hdGl2ZU5vZGUgYXMgRWxlbWVudCA6IG51bGw7XG4gIH1cblxuICAvKipcbiAgICogVGhlIGVsZW1lbnQgdGFnIG5hbWUsIGlmIGl0IGlzIGFuIGVsZW1lbnQuXG4gICAqL1xuICBnZXQgbmFtZSgpOiBzdHJpbmcge1xuICAgIGNvbnN0IGNvbnRleHQgPSBnZXRMQ29udGV4dCh0aGlzLm5hdGl2ZU5vZGUpITtcbiAgICBjb25zdCBsVmlldyA9IGNvbnRleHQgPyBjb250ZXh0LmxWaWV3IDogbnVsbDtcblxuICAgIGlmIChsVmlldyAhPT0gbnVsbCkge1xuICAgICAgY29uc3QgdERhdGEgPSBsVmlld1tUVklFV10uZGF0YTtcbiAgICAgIGNvbnN0IHROb2RlID0gdERhdGFbY29udGV4dC5ub2RlSW5kZXhdIGFzIFROb2RlO1xuICAgICAgcmV0dXJuIHROb2RlLnZhbHVlITtcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIHRoaXMubmF0aXZlTm9kZS5ub2RlTmFtZTtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogIEdldHMgYSBtYXAgb2YgcHJvcGVydHkgbmFtZXMgdG8gcHJvcGVydHkgdmFsdWVzIGZvciBhbiBlbGVtZW50LlxuICAgKlxuICAgKiAgVGhpcyBtYXAgaW5jbHVkZXM6XG4gICAqICAtIFJlZ3VsYXIgcHJvcGVydHkgYmluZGluZ3MgKGUuZy4gYFtpZF09XCJpZFwiYClcbiAgICogIC0gSG9zdCBwcm9wZXJ0eSBiaW5kaW5ncyAoZS5nLiBgaG9zdDogeyAnW2lkXSc6IFwiaWRcIiB9YClcbiAgICogIC0gSW50ZXJwb2xhdGVkIHByb3BlcnR5IGJpbmRpbmdzIChlLmcuIGBpZD1cInt7IHZhbHVlIH19XCIpXG4gICAqXG4gICAqICBJdCBkb2VzIG5vdCBpbmNsdWRlOlxuICAgKiAgLSBpbnB1dCBwcm9wZXJ0eSBiaW5kaW5ncyAoZS5nLiBgW215Q3VzdG9tSW5wdXRdPVwidmFsdWVcImApXG4gICAqICAtIGF0dHJpYnV0ZSBiaW5kaW5ncyAoZS5nLiBgW2F0dHIucm9sZV09XCJtZW51XCJgKVxuICAgKi9cbiAgZ2V0IHByb3BlcnRpZXMoKToge1trZXk6IHN0cmluZ106IGFueTt9IHtcbiAgICBjb25zdCBjb250ZXh0ID0gZ2V0TENvbnRleHQodGhpcy5uYXRpdmVOb2RlKSE7XG4gICAgY29uc3QgbFZpZXcgPSBjb250ZXh0ID8gY29udGV4dC5sVmlldyA6IG51bGw7XG5cbiAgICBpZiAobFZpZXcgPT09IG51bGwpIHtcbiAgICAgIHJldHVybiB7fTtcbiAgICB9XG5cbiAgICBjb25zdCB0RGF0YSA9IGxWaWV3W1RWSUVXXS5kYXRhO1xuICAgIGNvbnN0IHROb2RlID0gdERhdGFbY29udGV4dC5ub2RlSW5kZXhdIGFzIFROb2RlO1xuXG4gICAgY29uc3QgcHJvcGVydGllczoge1trZXk6IHN0cmluZ106IHN0cmluZ30gPSB7fTtcbiAgICAvLyBDb2xsZWN0IHByb3BlcnRpZXMgZnJvbSB0aGUgRE9NLlxuICAgIGNvcHlEb21Qcm9wZXJ0aWVzKHRoaXMubmF0aXZlRWxlbWVudCwgcHJvcGVydGllcyk7XG4gICAgLy8gQ29sbGVjdCBwcm9wZXJ0aWVzIGZyb20gdGhlIGJpbmRpbmdzLiBUaGlzIGlzIG5lZWRlZCBmb3IgYW5pbWF0aW9uIHJlbmRlcmVyIHdoaWNoIGhhc1xuICAgIC8vIHN5bnRoZXRpYyBwcm9wZXJ0aWVzIHdoaWNoIGRvbid0IGdldCByZWZsZWN0ZWQgaW50byB0aGUgRE9NLlxuICAgIGNvbGxlY3RQcm9wZXJ0eUJpbmRpbmdzKHByb3BlcnRpZXMsIHROb2RlLCBsVmlldywgdERhdGEpO1xuICAgIHJldHVybiBwcm9wZXJ0aWVzO1xuICB9XG5cbiAgLyoqXG4gICAqICBBIG1hcCBvZiBhdHRyaWJ1dGUgbmFtZXMgdG8gYXR0cmlidXRlIHZhbHVlcyBmb3IgYW4gZWxlbWVudC5cbiAgICovXG4gIGdldCBhdHRyaWJ1dGVzKCk6IHtba2V5OiBzdHJpbmddOiBzdHJpbmd8bnVsbH0ge1xuICAgIGNvbnN0IGF0dHJpYnV0ZXM6IHtba2V5OiBzdHJpbmddOiBzdHJpbmd8bnVsbH0gPSB7fTtcbiAgICBjb25zdCBlbGVtZW50ID0gdGhpcy5uYXRpdmVFbGVtZW50O1xuXG4gICAgaWYgKCFlbGVtZW50KSB7XG4gICAgICByZXR1cm4gYXR0cmlidXRlcztcbiAgICB9XG5cbiAgICBjb25zdCBjb250ZXh0ID0gZ2V0TENvbnRleHQoZWxlbWVudCkhO1xuICAgIGNvbnN0IGxWaWV3ID0gY29udGV4dCA/IGNvbnRleHQubFZpZXcgOiBudWxsO1xuXG4gICAgaWYgKGxWaWV3ID09PSBudWxsKSB7XG4gICAgICByZXR1cm4ge307XG4gICAgfVxuXG4gICAgY29uc3QgdE5vZGVBdHRycyA9IChsVmlld1tUVklFV10uZGF0YVtjb250ZXh0Lm5vZGVJbmRleF0gYXMgVE5vZGUpLmF0dHJzO1xuICAgIGNvbnN0IGxvd2VyY2FzZVROb2RlQXR0cnM6IHN0cmluZ1tdID0gW107XG5cbiAgICAvLyBGb3IgZGVidWcgbm9kZXMgd2UgdGFrZSB0aGUgZWxlbWVudCdzIGF0dHJpYnV0ZSBkaXJlY3RseSBmcm9tIHRoZSBET00gc2luY2UgaXQgYWxsb3dzIHVzXG4gICAgLy8gdG8gYWNjb3VudCBmb3Igb25lcyB0aGF0IHdlcmVuJ3Qgc2V0IHZpYSBiaW5kaW5ncyAoZS5nLiBWaWV3RW5naW5lIGtlZXBzIHRyYWNrIG9mIHRoZSBvbmVzXG4gICAgLy8gdGhhdCBhcmUgc2V0IHRocm91Z2ggYFJlbmRlcmVyMmApLiBUaGUgcHJvYmxlbSBpcyB0aGF0IHRoZSBicm93c2VyIHdpbGwgbG93ZXJjYXNlIGFsbCBuYW1lcyxcbiAgICAvLyBob3dldmVyIHNpbmNlIHdlIGhhdmUgdGhlIGF0dHJpYnV0ZXMgYWxyZWFkeSBvbiB0aGUgVE5vZGUsIHdlIGNhbiBwcmVzZXJ2ZSB0aGUgY2FzZSBieSBnb2luZ1xuICAgIC8vIHRocm91Z2ggdGhlbSBvbmNlLCBhZGRpbmcgdGhlbSB0byB0aGUgYGF0dHJpYnV0ZXNgIG1hcCBhbmQgcHV0dGluZyB0aGVpciBsb3dlci1jYXNlZCBuYW1lXG4gICAgLy8gaW50byBhbiBhcnJheS4gQWZ0ZXJ3YXJkcyB3aGVuIHdlJ3JlIGdvaW5nIHRocm91Z2ggdGhlIG5hdGl2ZSBET00gYXR0cmlidXRlcywgd2UgY2FuIGNoZWNrXG4gICAgLy8gd2hldGhlciB3ZSBoYXZlbid0IHJ1biBpbnRvIGFuIGF0dHJpYnV0ZSBhbHJlYWR5IHRocm91Z2ggdGhlIFROb2RlLlxuICAgIGlmICh0Tm9kZUF0dHJzKSB7XG4gICAgICBsZXQgaSA9IDA7XG4gICAgICB3aGlsZSAoaSA8IHROb2RlQXR0cnMubGVuZ3RoKSB7XG4gICAgICAgIGNvbnN0IGF0dHJOYW1lID0gdE5vZGVBdHRyc1tpXTtcblxuICAgICAgICAvLyBTdG9wIGFzIHNvb24gYXMgd2UgaGl0IGEgbWFya2VyLiBXZSBvbmx5IGNhcmUgYWJvdXQgdGhlIHJlZ3VsYXIgYXR0cmlidXRlcy4gRXZlcnl0aGluZ1xuICAgICAgICAvLyBlbHNlIHdpbGwgYmUgaGFuZGxlZCBiZWxvdyB3aGVuIHdlIHJlYWQgdGhlIGZpbmFsIGF0dHJpYnV0ZXMgb2ZmIHRoZSBET00uXG4gICAgICAgIGlmICh0eXBlb2YgYXR0ck5hbWUgIT09ICdzdHJpbmcnKSBicmVhaztcblxuICAgICAgICBjb25zdCBhdHRyVmFsdWUgPSB0Tm9kZUF0dHJzW2kgKyAxXTtcbiAgICAgICAgYXR0cmlidXRlc1thdHRyTmFtZV0gPSBhdHRyVmFsdWUgYXMgc3RyaW5nO1xuICAgICAgICBsb3dlcmNhc2VUTm9kZUF0dHJzLnB1c2goYXR0ck5hbWUudG9Mb3dlckNhc2UoKSk7XG5cbiAgICAgICAgaSArPSAyO1xuICAgICAgfVxuICAgIH1cblxuICAgIGZvciAoY29uc3QgYXR0ciBvZiBlbGVtZW50LmF0dHJpYnV0ZXMpIHtcbiAgICAgIC8vIE1ha2Ugc3VyZSB0aGF0IHdlIGRvbid0IGFzc2lnbiB0aGUgc2FtZSBhdHRyaWJ1dGUgYm90aCBpbiBpdHNcbiAgICAgIC8vIGNhc2Utc2Vuc2l0aXZlIGZvcm0gYW5kIHRoZSBsb3dlci1jYXNlZCBvbmUgZnJvbSB0aGUgYnJvd3Nlci5cbiAgICAgIGlmICghbG93ZXJjYXNlVE5vZGVBdHRycy5pbmNsdWRlcyhhdHRyLm5hbWUpKSB7XG4gICAgICAgIGF0dHJpYnV0ZXNbYXR0ci5uYW1lXSA9IGF0dHIudmFsdWU7XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIGF0dHJpYnV0ZXM7XG4gIH1cblxuICAvKipcbiAgICogVGhlIGlubGluZSBzdHlsZXMgb2YgdGhlIERPTSBlbGVtZW50LlxuICAgKlxuICAgKiBXaWxsIGJlIGBudWxsYCBpZiB0aGVyZSBpcyBubyBgc3R5bGVgIHByb3BlcnR5IG9uIHRoZSB1bmRlcmx5aW5nIERPTSBlbGVtZW50LlxuICAgKlxuICAgKiBAc2VlIFtFbGVtZW50Q1NTSW5saW5lU3R5bGVdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0FQSS9FbGVtZW50Q1NTSW5saW5lU3R5bGUvc3R5bGUpXG4gICAqL1xuICBnZXQgc3R5bGVzKCk6IHtba2V5OiBzdHJpbmddOiBzdHJpbmd8bnVsbH0ge1xuICAgIGlmICh0aGlzLm5hdGl2ZUVsZW1lbnQgJiYgKHRoaXMubmF0aXZlRWxlbWVudCBhcyBIVE1MRWxlbWVudCkuc3R5bGUpIHtcbiAgICAgIHJldHVybiAodGhpcy5uYXRpdmVFbGVtZW50IGFzIEhUTUxFbGVtZW50KS5zdHlsZSBhcyB7W2tleTogc3RyaW5nXTogYW55fTtcbiAgICB9XG4gICAgcmV0dXJuIHt9O1xuICB9XG5cbiAgLyoqXG4gICAqIEEgbWFwIGNvbnRhaW5pbmcgdGhlIGNsYXNzIG5hbWVzIG9uIHRoZSBlbGVtZW50IGFzIGtleXMuXG4gICAqXG4gICAqIFRoaXMgbWFwIGlzIGRlcml2ZWQgZnJvbSB0aGUgYGNsYXNzTmFtZWAgcHJvcGVydHkgb2YgdGhlIERPTSBlbGVtZW50LlxuICAgKlxuICAgKiBOb3RlOiBUaGUgdmFsdWVzIG9mIHRoaXMgb2JqZWN0IHdpbGwgYWx3YXlzIGJlIGB0cnVlYC4gVGhlIGNsYXNzIGtleSB3aWxsIG5vdCBhcHBlYXIgaW4gdGhlIEtWXG4gICAqIG9iamVjdCBpZiBpdCBkb2VzIG5vdCBleGlzdCBvbiB0aGUgZWxlbWVudC5cbiAgICpcbiAgICogQHNlZSBbRWxlbWVudC5jbGFzc05hbWVdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0FQSS9FbGVtZW50L2NsYXNzTmFtZSlcbiAgICovXG4gIGdldCBjbGFzc2VzKCk6IHtba2V5OiBzdHJpbmddOiBib29sZWFufSB7XG4gICAgY29uc3QgcmVzdWx0OiB7W2tleTogc3RyaW5nXTogYm9vbGVhbn0gPSB7fTtcbiAgICBjb25zdCBlbGVtZW50ID0gdGhpcy5uYXRpdmVFbGVtZW50IGFzIEhUTUxFbGVtZW50IHwgU1ZHRWxlbWVudDtcblxuICAgIC8vIFNWRyBlbGVtZW50cyByZXR1cm4gYW4gYFNWR0FuaW1hdGVkU3RyaW5nYCBpbnN0ZWFkIG9mIGEgcGxhaW4gc3RyaW5nIGZvciB0aGUgYGNsYXNzTmFtZWAuXG4gICAgY29uc3QgY2xhc3NOYW1lID0gZWxlbWVudC5jbGFzc05hbWUgYXMgc3RyaW5nIHwgU1ZHQW5pbWF0ZWRTdHJpbmc7XG4gICAgY29uc3QgY2xhc3NlcyA9XG4gICAgICAgIHR5cGVvZiBjbGFzc05hbWUgIT09ICdzdHJpbmcnID8gY2xhc3NOYW1lLmJhc2VWYWwuc3BsaXQoJyAnKSA6IGNsYXNzTmFtZS5zcGxpdCgnICcpO1xuXG4gICAgY2xhc3Nlcy5mb3JFYWNoKCh2YWx1ZTogc3RyaW5nKSA9PiByZXN1bHRbdmFsdWVdID0gdHJ1ZSk7XG5cbiAgICByZXR1cm4gcmVzdWx0O1xuICB9XG5cbiAgLyoqXG4gICAqIFRoZSBgY2hpbGROb2Rlc2Agb2YgdGhlIERPTSBlbGVtZW50IGFzIGEgYERlYnVnTm9kZWAgYXJyYXkuXG4gICAqXG4gICAqIEBzZWUgW05vZGUuY2hpbGROb2Rlc10oaHR0cHM6Ly9kZXZlbG9wZXIubW96aWxsYS5vcmcvZW4tVVMvZG9jcy9XZWIvQVBJL05vZGUvY2hpbGROb2RlcylcbiAgICovXG4gIGdldCBjaGlsZE5vZGVzKCk6IERlYnVnTm9kZVtdIHtcbiAgICBjb25zdCBjaGlsZE5vZGVzID0gdGhpcy5uYXRpdmVOb2RlLmNoaWxkTm9kZXM7XG4gICAgY29uc3QgY2hpbGRyZW46IERlYnVnTm9kZVtdID0gW107XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBjaGlsZE5vZGVzLmxlbmd0aDsgaSsrKSB7XG4gICAgICBjb25zdCBlbGVtZW50ID0gY2hpbGROb2Rlc1tpXTtcbiAgICAgIGNoaWxkcmVuLnB1c2goZ2V0RGVidWdOb2RlKGVsZW1lbnQpISk7XG4gICAgfVxuICAgIHJldHVybiBjaGlsZHJlbjtcbiAgfVxuXG4gIC8qKlxuICAgKiBUaGUgaW1tZWRpYXRlIGBEZWJ1Z0VsZW1lbnRgIGNoaWxkcmVuLiBXYWxrIHRoZSB0cmVlIGJ5IGRlc2NlbmRpbmcgdGhyb3VnaCBgY2hpbGRyZW5gLlxuICAgKi9cbiAgZ2V0IGNoaWxkcmVuKCk6IERlYnVnRWxlbWVudFtdIHtcbiAgICBjb25zdCBuYXRpdmVFbGVtZW50ID0gdGhpcy5uYXRpdmVFbGVtZW50O1xuICAgIGlmICghbmF0aXZlRWxlbWVudCkgcmV0dXJuIFtdO1xuICAgIGNvbnN0IGNoaWxkTm9kZXMgPSBuYXRpdmVFbGVtZW50LmNoaWxkcmVuO1xuICAgIGNvbnN0IGNoaWxkcmVuOiBEZWJ1Z0VsZW1lbnRbXSA9IFtdO1xuICAgIGZvciAobGV0IGkgPSAwOyBpIDwgY2hpbGROb2Rlcy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3QgZWxlbWVudCA9IGNoaWxkTm9kZXNbaV07XG4gICAgICBjaGlsZHJlbi5wdXNoKGdldERlYnVnTm9kZShlbGVtZW50KSBhcyBEZWJ1Z0VsZW1lbnQpO1xuICAgIH1cbiAgICByZXR1cm4gY2hpbGRyZW47XG4gIH1cblxuICAvKipcbiAgICogQHJldHVybnMgdGhlIGZpcnN0IGBEZWJ1Z0VsZW1lbnRgIHRoYXQgbWF0Y2hlcyB0aGUgcHJlZGljYXRlIGF0IGFueSBkZXB0aCBpbiB0aGUgc3VidHJlZS5cbiAgICovXG4gIHF1ZXJ5KHByZWRpY2F0ZTogUHJlZGljYXRlPERlYnVnRWxlbWVudD4pOiBEZWJ1Z0VsZW1lbnQge1xuICAgIGNvbnN0IHJlc3VsdHMgPSB0aGlzLnF1ZXJ5QWxsKHByZWRpY2F0ZSk7XG4gICAgcmV0dXJuIHJlc3VsdHNbMF0gfHwgbnVsbDtcbiAgfVxuXG4gIC8qKlxuICAgKiBAcmV0dXJucyBBbGwgYERlYnVnRWxlbWVudGAgbWF0Y2hlcyBmb3IgdGhlIHByZWRpY2F0ZSBhdCBhbnkgZGVwdGggaW4gdGhlIHN1YnRyZWUuXG4gICAqL1xuICBxdWVyeUFsbChwcmVkaWNhdGU6IFByZWRpY2F0ZTxEZWJ1Z0VsZW1lbnQ+KTogRGVidWdFbGVtZW50W10ge1xuICAgIGNvbnN0IG1hdGNoZXM6IERlYnVnRWxlbWVudFtdID0gW107XG4gICAgX3F1ZXJ5QWxsKHRoaXMsIHByZWRpY2F0ZSwgbWF0Y2hlcywgdHJ1ZSk7XG4gICAgcmV0dXJuIG1hdGNoZXM7XG4gIH1cblxuICAvKipcbiAgICogQHJldHVybnMgQWxsIGBEZWJ1Z05vZGVgIG1hdGNoZXMgZm9yIHRoZSBwcmVkaWNhdGUgYXQgYW55IGRlcHRoIGluIHRoZSBzdWJ0cmVlLlxuICAgKi9cbiAgcXVlcnlBbGxOb2RlcyhwcmVkaWNhdGU6IFByZWRpY2F0ZTxEZWJ1Z05vZGU+KTogRGVidWdOb2RlW10ge1xuICAgIGNvbnN0IG1hdGNoZXM6IERlYnVnTm9kZVtdID0gW107XG4gICAgX3F1ZXJ5QWxsKHRoaXMsIHByZWRpY2F0ZSwgbWF0Y2hlcywgZmFsc2UpO1xuICAgIHJldHVybiBtYXRjaGVzO1xuICB9XG5cbiAgLyoqXG4gICAqIFRyaWdnZXJzIHRoZSBldmVudCBieSBpdHMgbmFtZSBpZiB0aGVyZSBpcyBhIGNvcnJlc3BvbmRpbmcgbGlzdGVuZXIgaW4gdGhlIGVsZW1lbnQnc1xuICAgKiBgbGlzdGVuZXJzYCBjb2xsZWN0aW9uLlxuICAgKlxuICAgKiBJZiB0aGUgZXZlbnQgbGFja3MgYSBsaXN0ZW5lciBvciB0aGVyZSdzIHNvbWUgb3RoZXIgcHJvYmxlbSwgY29uc2lkZXJcbiAgICogY2FsbGluZyBgbmF0aXZlRWxlbWVudC5kaXNwYXRjaEV2ZW50KGV2ZW50T2JqZWN0KWAuXG4gICAqXG4gICAqIEBwYXJhbSBldmVudE5hbWUgVGhlIG5hbWUgb2YgdGhlIGV2ZW50IHRvIHRyaWdnZXJcbiAgICogQHBhcmFtIGV2ZW50T2JqIFRoZSBfZXZlbnQgb2JqZWN0XyBleHBlY3RlZCBieSB0aGUgaGFuZGxlclxuICAgKlxuICAgKiBAc2VlIFtUZXN0aW5nIGNvbXBvbmVudHMgc2NlbmFyaW9zXShndWlkZS90ZXN0aW5nLWNvbXBvbmVudHMtc2NlbmFyaW9zI3RyaWdnZXItZXZlbnQtaGFuZGxlcilcbiAgICovXG4gIHRyaWdnZXJFdmVudEhhbmRsZXIoZXZlbnROYW1lOiBzdHJpbmcsIGV2ZW50T2JqPzogYW55KTogdm9pZCB7XG4gICAgY29uc3Qgbm9kZSA9IHRoaXMubmF0aXZlTm9kZSBhcyBhbnk7XG4gICAgY29uc3QgaW52b2tlZExpc3RlbmVyczogRnVuY3Rpb25bXSA9IFtdO1xuXG4gICAgdGhpcy5saXN0ZW5lcnMuZm9yRWFjaChsaXN0ZW5lciA9PiB7XG4gICAgICBpZiAobGlzdGVuZXIubmFtZSA9PT0gZXZlbnROYW1lKSB7XG4gICAgICAgIGNvbnN0IGNhbGxiYWNrID0gbGlzdGVuZXIuY2FsbGJhY2s7XG4gICAgICAgIGNhbGxiYWNrLmNhbGwobm9kZSwgZXZlbnRPYmopO1xuICAgICAgICBpbnZva2VkTGlzdGVuZXJzLnB1c2goY2FsbGJhY2spO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgLy8gV2UgbmVlZCB0byBjaGVjayB3aGV0aGVyIGBldmVudExpc3RlbmVyc2AgZXhpc3RzLCBiZWNhdXNlIGl0J3Mgc29tZXRoaW5nXG4gICAgLy8gdGhhdCBab25lLmpzIG9ubHkgYWRkcyB0byBgRXZlbnRUYXJnZXRgIGluIGJyb3dzZXIgZW52aXJvbm1lbnRzLlxuICAgIGlmICh0eXBlb2Ygbm9kZS5ldmVudExpc3RlbmVycyA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgLy8gTm90ZSB0aGF0IGluIEl2eSB3ZSB3cmFwIGV2ZW50IGxpc3RlbmVycyB3aXRoIGEgY2FsbCB0byBgZXZlbnQucHJldmVudERlZmF1bHRgIGluIHNvbWVcbiAgICAgIC8vIGNhc2VzLiBXZSB1c2UgJ19fbmdVbndyYXBfXycgYXMgYSBzcGVjaWFsIHRva2VuIHRoYXQgZ2l2ZXMgdXMgYWNjZXNzIHRvIHRoZSBhY3R1YWwgZXZlbnRcbiAgICAgIC8vIGxpc3RlbmVyLlxuICAgICAgbm9kZS5ldmVudExpc3RlbmVycyhldmVudE5hbWUpLmZvckVhY2goKGxpc3RlbmVyOiBGdW5jdGlvbikgPT4ge1xuICAgICAgICAvLyBJbiBvcmRlciB0byBlbnN1cmUgdGhhdCB3ZSBjYW4gZGV0ZWN0IHRoZSBzcGVjaWFsIF9fbmdVbndyYXBfXyB0b2tlbiBkZXNjcmliZWQgYWJvdmUsIHdlXG4gICAgICAgIC8vIHVzZSBgdG9TdHJpbmdgIG9uIHRoZSBsaXN0ZW5lciBhbmQgc2VlIGlmIGl0IGNvbnRhaW5zIHRoZSB0b2tlbi4gV2UgdXNlIHRoaXMgYXBwcm9hY2ggdG9cbiAgICAgICAgLy8gZW5zdXJlIHRoYXQgaXQgc3RpbGwgd29ya2VkIHdpdGggY29tcGlsZWQgY29kZSBzaW5jZSBpdCBjYW5ub3QgcmVtb3ZlIG9yIHJlbmFtZSBzdHJpbmdcbiAgICAgICAgLy8gbGl0ZXJhbHMuIFdlIGFsc28gY29uc2lkZXJlZCB1c2luZyBhIHNwZWNpYWwgZnVuY3Rpb24gbmFtZSAoaS5lLiBpZihsaXN0ZW5lci5uYW1lID09PVxuICAgICAgICAvLyBzcGVjaWFsKSkgYnV0IHRoYXQgd2FzIG1vcmUgY3VtYmVyc29tZSBhbmQgd2Ugd2VyZSBhbHNvIGNvbmNlcm5lZCB0aGUgY29tcGlsZWQgY29kZSBjb3VsZFxuICAgICAgICAvLyBzdHJpcCB0aGUgbmFtZSwgdHVybmluZyB0aGUgY29uZGl0aW9uIGluIHRvIChcIlwiID09PSBcIlwiKSBhbmQgYWx3YXlzIHJldHVybmluZyB0cnVlLlxuICAgICAgICBpZiAobGlzdGVuZXIudG9TdHJpbmcoKS5pbmRleE9mKCdfX25nVW53cmFwX18nKSAhPT0gLTEpIHtcbiAgICAgICAgICBjb25zdCB1bndyYXBwZWRMaXN0ZW5lciA9IGxpc3RlbmVyKCdfX25nVW53cmFwX18nKTtcbiAgICAgICAgICByZXR1cm4gaW52b2tlZExpc3RlbmVycy5pbmRleE9mKHVud3JhcHBlZExpc3RlbmVyKSA9PT0gLTEgJiZcbiAgICAgICAgICAgICAgdW53cmFwcGVkTGlzdGVuZXIuY2FsbChub2RlLCBldmVudE9iaik7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxufVxuXG5mdW5jdGlvbiBjb3B5RG9tUHJvcGVydGllcyhlbGVtZW50OiBFbGVtZW50fG51bGwsIHByb3BlcnRpZXM6IHtbbmFtZTogc3RyaW5nXTogc3RyaW5nfSk6IHZvaWQge1xuICBpZiAoZWxlbWVudCkge1xuICAgIC8vIFNraXAgb3duIHByb3BlcnRpZXMgKGFzIHRob3NlIGFyZSBwYXRjaGVkKVxuICAgIGxldCBvYmogPSBPYmplY3QuZ2V0UHJvdG90eXBlT2YoZWxlbWVudCk7XG4gICAgY29uc3QgTm9kZVByb3RvdHlwZTogYW55ID0gTm9kZS5wcm90b3R5cGU7XG4gICAgd2hpbGUgKG9iaiAhPT0gbnVsbCAmJiBvYmogIT09IE5vZGVQcm90b3R5cGUpIHtcbiAgICAgIGNvbnN0IGRlc2NyaXB0b3JzID0gT2JqZWN0LmdldE93blByb3BlcnR5RGVzY3JpcHRvcnMob2JqKTtcbiAgICAgIGZvciAobGV0IGtleSBpbiBkZXNjcmlwdG9ycykge1xuICAgICAgICBpZiAoIWtleS5zdGFydHNXaXRoKCdfXycpICYmICFrZXkuc3RhcnRzV2l0aCgnb24nKSkge1xuICAgICAgICAgIC8vIGRvbid0IGluY2x1ZGUgcHJvcGVydGllcyBzdGFydGluZyB3aXRoIGBfX2AgYW5kIGBvbmAuXG4gICAgICAgICAgLy8gYF9fYCBhcmUgcGF0Y2hlZCB2YWx1ZXMgd2hpY2ggc2hvdWxkIG5vdCBiZSBpbmNsdWRlZC5cbiAgICAgICAgICAvLyBgb25gIGFyZSBsaXN0ZW5lcnMgd2hpY2ggYWxzbyBzaG91bGQgbm90IGJlIGluY2x1ZGVkLlxuICAgICAgICAgIGNvbnN0IHZhbHVlID0gKGVsZW1lbnQgYXMgYW55KVtrZXldO1xuICAgICAgICAgIGlmIChpc1ByaW1pdGl2ZVZhbHVlKHZhbHVlKSkge1xuICAgICAgICAgICAgcHJvcGVydGllc1trZXldID0gdmFsdWU7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgICBvYmogPSBPYmplY3QuZ2V0UHJvdG90eXBlT2Yob2JqKTtcbiAgICB9XG4gIH1cbn1cblxuZnVuY3Rpb24gaXNQcmltaXRpdmVWYWx1ZSh2YWx1ZTogYW55KTogYm9vbGVhbiB7XG4gIHJldHVybiB0eXBlb2YgdmFsdWUgPT09ICdzdHJpbmcnIHx8IHR5cGVvZiB2YWx1ZSA9PT0gJ2Jvb2xlYW4nIHx8IHR5cGVvZiB2YWx1ZSA9PT0gJ251bWJlcicgfHxcbiAgICAgIHZhbHVlID09PSBudWxsO1xufVxuXG4vKipcbiAqIFdhbGsgdGhlIFROb2RlIHRyZWUgdG8gZmluZCBtYXRjaGVzIGZvciB0aGUgcHJlZGljYXRlLlxuICpcbiAqIEBwYXJhbSBwYXJlbnRFbGVtZW50IHRoZSBlbGVtZW50IGZyb20gd2hpY2ggdGhlIHdhbGsgaXMgc3RhcnRlZFxuICogQHBhcmFtIHByZWRpY2F0ZSB0aGUgcHJlZGljYXRlIHRvIG1hdGNoXG4gKiBAcGFyYW0gbWF0Y2hlcyB0aGUgbGlzdCBvZiBwb3NpdGl2ZSBtYXRjaGVzXG4gKiBAcGFyYW0gZWxlbWVudHNPbmx5IHdoZXRoZXIgb25seSBlbGVtZW50cyBzaG91bGQgYmUgc2VhcmNoZWRcbiAqL1xuZnVuY3Rpb24gX3F1ZXJ5QWxsKFxuICAgIHBhcmVudEVsZW1lbnQ6IERlYnVnRWxlbWVudCwgcHJlZGljYXRlOiBQcmVkaWNhdGU8RGVidWdFbGVtZW50PiwgbWF0Y2hlczogRGVidWdFbGVtZW50W10sXG4gICAgZWxlbWVudHNPbmx5OiB0cnVlKTogdm9pZDtcbmZ1bmN0aW9uIF9xdWVyeUFsbChcbiAgICBwYXJlbnRFbGVtZW50OiBEZWJ1Z0VsZW1lbnQsIHByZWRpY2F0ZTogUHJlZGljYXRlPERlYnVnTm9kZT4sIG1hdGNoZXM6IERlYnVnTm9kZVtdLFxuICAgIGVsZW1lbnRzT25seTogZmFsc2UpOiB2b2lkO1xuZnVuY3Rpb24gX3F1ZXJ5QWxsKFxuICAgIHBhcmVudEVsZW1lbnQ6IERlYnVnRWxlbWVudCwgcHJlZGljYXRlOiBQcmVkaWNhdGU8RGVidWdFbGVtZW50PnxQcmVkaWNhdGU8RGVidWdOb2RlPixcbiAgICBtYXRjaGVzOiBEZWJ1Z0VsZW1lbnRbXXxEZWJ1Z05vZGVbXSwgZWxlbWVudHNPbmx5OiBib29sZWFuKSB7XG4gIGNvbnN0IGNvbnRleHQgPSBnZXRMQ29udGV4dChwYXJlbnRFbGVtZW50Lm5hdGl2ZU5vZGUpITtcbiAgY29uc3QgbFZpZXcgPSBjb250ZXh0ID8gY29udGV4dC5sVmlldyA6IG51bGw7XG4gIGlmIChsVmlldyAhPT0gbnVsbCkge1xuICAgIGNvbnN0IHBhcmVudFROb2RlID0gbFZpZXdbVFZJRVddLmRhdGFbY29udGV4dC5ub2RlSW5kZXhdIGFzIFROb2RlO1xuICAgIF9xdWVyeU5vZGVDaGlsZHJlbihcbiAgICAgICAgcGFyZW50VE5vZGUsIGxWaWV3LCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcGFyZW50RWxlbWVudC5uYXRpdmVOb2RlKTtcbiAgfSBlbHNlIHtcbiAgICAvLyBJZiB0aGUgY29udGV4dCBpcyBudWxsLCB0aGVuIGBwYXJlbnRFbGVtZW50YCB3YXMgZWl0aGVyIGNyZWF0ZWQgd2l0aCBSZW5kZXJlcjIgb3IgbmF0aXZlIERPTVxuICAgIC8vIEFQSXMuXG4gICAgX3F1ZXJ5TmF0aXZlTm9kZURlc2NlbmRhbnRzKHBhcmVudEVsZW1lbnQubmF0aXZlTm9kZSwgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHkpO1xuICB9XG59XG5cbi8qKlxuICogUmVjdXJzaXZlbHkgbWF0Y2ggdGhlIGN1cnJlbnQgVE5vZGUgYWdhaW5zdCB0aGUgcHJlZGljYXRlLCBhbmQgZ29lcyBvbiB3aXRoIHRoZSBuZXh0IG9uZXMuXG4gKlxuICogQHBhcmFtIHROb2RlIHRoZSBjdXJyZW50IFROb2RlXG4gKiBAcGFyYW0gbFZpZXcgdGhlIExWaWV3IG9mIHRoaXMgVE5vZGVcbiAqIEBwYXJhbSBwcmVkaWNhdGUgdGhlIHByZWRpY2F0ZSB0byBtYXRjaFxuICogQHBhcmFtIG1hdGNoZXMgdGhlIGxpc3Qgb2YgcG9zaXRpdmUgbWF0Y2hlc1xuICogQHBhcmFtIGVsZW1lbnRzT25seSB3aGV0aGVyIG9ubHkgZWxlbWVudHMgc2hvdWxkIGJlIHNlYXJjaGVkXG4gKiBAcGFyYW0gcm9vdE5hdGl2ZU5vZGUgdGhlIHJvb3QgbmF0aXZlIG5vZGUgb24gd2hpY2ggcHJlZGljYXRlIHNob3VsZCBub3QgYmUgbWF0Y2hlZFxuICovXG5mdW5jdGlvbiBfcXVlcnlOb2RlQ2hpbGRyZW4oXG4gICAgdE5vZGU6IFROb2RlLCBsVmlldzogTFZpZXcsIHByZWRpY2F0ZTogUHJlZGljYXRlPERlYnVnRWxlbWVudD58UHJlZGljYXRlPERlYnVnTm9kZT4sXG4gICAgbWF0Y2hlczogRGVidWdFbGVtZW50W118RGVidWdOb2RlW10sIGVsZW1lbnRzT25seTogYm9vbGVhbiwgcm9vdE5hdGl2ZU5vZGU6IGFueSkge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0VE5vZGVGb3JMVmlldyh0Tm9kZSwgbFZpZXcpO1xuICBjb25zdCBuYXRpdmVOb2RlID0gZ2V0TmF0aXZlQnlUTm9kZU9yTnVsbCh0Tm9kZSwgbFZpZXcpO1xuICAvLyBGb3IgZWFjaCB0eXBlIG9mIFROb2RlLCBzcGVjaWZpYyBsb2dpYyBpcyBleGVjdXRlZC5cbiAgaWYgKHROb2RlLnR5cGUgJiAoVE5vZGVUeXBlLkFueVJOb2RlIHwgVE5vZGVUeXBlLkVsZW1lbnRDb250YWluZXIpKSB7XG4gICAgLy8gQ2FzZSAxOiB0aGUgVE5vZGUgaXMgYW4gZWxlbWVudFxuICAgIC8vIFRoZSBuYXRpdmUgbm9kZSBoYXMgdG8gYmUgY2hlY2tlZC5cbiAgICBfYWRkUXVlcnlNYXRjaChuYXRpdmVOb2RlLCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICAgIGlmIChpc0NvbXBvbmVudEhvc3QodE5vZGUpKSB7XG4gICAgICAvLyBJZiB0aGUgZWxlbWVudCBpcyB0aGUgaG9zdCBvZiBhIGNvbXBvbmVudCwgdGhlbiBhbGwgbm9kZXMgaW4gaXRzIHZpZXcgaGF2ZSB0byBiZSBwcm9jZXNzZWQuXG4gICAgICAvLyBOb3RlOiB0aGUgY29tcG9uZW50J3MgY29udGVudCAodE5vZGUuY2hpbGQpIHdpbGwgYmUgcHJvY2Vzc2VkIGZyb20gdGhlIGluc2VydGlvbiBwb2ludHMuXG4gICAgICBjb25zdCBjb21wb25lbnRWaWV3ID0gZ2V0Q29tcG9uZW50TFZpZXdCeUluZGV4KHROb2RlLmluZGV4LCBsVmlldyk7XG4gICAgICBpZiAoY29tcG9uZW50VmlldyAmJiBjb21wb25lbnRWaWV3W1RWSUVXXS5maXJzdENoaWxkKSB7XG4gICAgICAgIF9xdWVyeU5vZGVDaGlsZHJlbihcbiAgICAgICAgICAgIGNvbXBvbmVudFZpZXdbVFZJRVddLmZpcnN0Q2hpbGQhLCBjb21wb25lbnRWaWV3LCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSxcbiAgICAgICAgICAgIHJvb3ROYXRpdmVOb2RlKTtcbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKHROb2RlLmNoaWxkKSB7XG4gICAgICAgIC8vIE90aGVyd2lzZSwgaXRzIGNoaWxkcmVuIGhhdmUgdG8gYmUgcHJvY2Vzc2VkLlxuICAgICAgICBfcXVlcnlOb2RlQ2hpbGRyZW4odE5vZGUuY2hpbGQsIGxWaWV3LCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICAgICAgfVxuXG4gICAgICAvLyBXZSBhbHNvIGhhdmUgdG8gcXVlcnkgdGhlIERPTSBkaXJlY3RseSBpbiBvcmRlciB0byBjYXRjaCBlbGVtZW50cyBpbnNlcnRlZCB0aHJvdWdoXG4gICAgICAvLyBSZW5kZXJlcjIuIE5vdGUgdGhhdCB0aGlzIGlzIF9fbm90X18gb3B0aW1hbCwgYmVjYXVzZSB3ZSdyZSB3YWxraW5nIHNpbWlsYXIgdHJlZXMgbXVsdGlwbGVcbiAgICAgIC8vIHRpbWVzLiBWaWV3RW5naW5lIGNvdWxkIGRvIGl0IG1vcmUgZWZmaWNpZW50bHksIGJlY2F1c2UgYWxsIHRoZSBpbnNlcnRpb25zIGdvIHRocm91Z2hcbiAgICAgIC8vIFJlbmRlcmVyMiwgaG93ZXZlciB0aGF0J3Mgbm90IHRoZSBjYXNlIGluIEl2eS4gVGhpcyBhcHByb2FjaCBpcyBiZWluZyB1c2VkIGJlY2F1c2U6XG4gICAgICAvLyAxLiBNYXRjaGluZyB0aGUgVmlld0VuZ2luZSBiZWhhdmlvciB3b3VsZCBtZWFuIHBvdGVudGlhbGx5IGludHJvZHVjaW5nIGEgZGVwZW5kZW5jeVxuICAgICAgLy8gICAgZnJvbSBgUmVuZGVyZXIyYCB0byBJdnkgd2hpY2ggY291bGQgYnJpbmcgSXZ5IGNvZGUgaW50byBWaWV3RW5naW5lLlxuICAgICAgLy8gMi4gSXQgYWxsb3dzIHVzIHRvIGNhcHR1cmUgbm9kZXMgdGhhdCB3ZXJlIGluc2VydGVkIGRpcmVjdGx5IHZpYSB0aGUgRE9NLlxuICAgICAgbmF0aXZlTm9kZSAmJiBfcXVlcnlOYXRpdmVOb2RlRGVzY2VuZGFudHMobmF0aXZlTm9kZSwgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHkpO1xuICAgIH1cbiAgICAvLyBJbiBhbGwgY2FzZXMsIGlmIGEgZHluYW1pYyBjb250YWluZXIgZXhpc3RzIGZvciB0aGlzIG5vZGUsIGVhY2ggdmlldyBpbnNpZGUgaXQgaGFzIHRvIGJlXG4gICAgLy8gcHJvY2Vzc2VkLlxuICAgIGNvbnN0IG5vZGVPckNvbnRhaW5lciA9IGxWaWV3W3ROb2RlLmluZGV4XTtcbiAgICBpZiAoaXNMQ29udGFpbmVyKG5vZGVPckNvbnRhaW5lcikpIHtcbiAgICAgIF9xdWVyeU5vZGVDaGlsZHJlbkluQ29udGFpbmVyKFxuICAgICAgICAgIG5vZGVPckNvbnRhaW5lciwgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHksIHJvb3ROYXRpdmVOb2RlKTtcbiAgICB9XG4gIH0gZWxzZSBpZiAodE5vZGUudHlwZSAmIFROb2RlVHlwZS5Db250YWluZXIpIHtcbiAgICAvLyBDYXNlIDI6IHRoZSBUTm9kZSBpcyBhIGNvbnRhaW5lclxuICAgIC8vIFRoZSBuYXRpdmUgbm9kZSBoYXMgdG8gYmUgY2hlY2tlZC5cbiAgICBjb25zdCBsQ29udGFpbmVyID0gbFZpZXdbdE5vZGUuaW5kZXhdO1xuICAgIF9hZGRRdWVyeU1hdGNoKGxDb250YWluZXJbTkFUSVZFXSwgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHksIHJvb3ROYXRpdmVOb2RlKTtcbiAgICAvLyBFYWNoIHZpZXcgaW5zaWRlIHRoZSBjb250YWluZXIgaGFzIHRvIGJlIHByb2Nlc3NlZC5cbiAgICBfcXVlcnlOb2RlQ2hpbGRyZW5JbkNvbnRhaW5lcihsQ29udGFpbmVyLCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICB9IGVsc2UgaWYgKHROb2RlLnR5cGUgJiBUTm9kZVR5cGUuUHJvamVjdGlvbikge1xuICAgIC8vIENhc2UgMzogdGhlIFROb2RlIGlzIGEgcHJvamVjdGlvbiBpbnNlcnRpb24gcG9pbnQgKGkuZS4gYSA8bmctY29udGVudD4pLlxuICAgIC8vIFRoZSBub2RlcyBwcm9qZWN0ZWQgYXQgdGhpcyBsb2NhdGlvbiBhbGwgbmVlZCB0byBiZSBwcm9jZXNzZWQuXG4gICAgY29uc3QgY29tcG9uZW50VmlldyA9IGxWaWV3IVtERUNMQVJBVElPTl9DT01QT05FTlRfVklFV107XG4gICAgY29uc3QgY29tcG9uZW50SG9zdCA9IGNvbXBvbmVudFZpZXdbVF9IT1NUXSBhcyBURWxlbWVudE5vZGU7XG4gICAgY29uc3QgaGVhZDogVE5vZGV8bnVsbCA9XG4gICAgICAgIChjb21wb25lbnRIb3N0LnByb2plY3Rpb24gYXMgKFROb2RlIHwgbnVsbClbXSlbdE5vZGUucHJvamVjdGlvbiBhcyBudW1iZXJdO1xuXG4gICAgaWYgKEFycmF5LmlzQXJyYXkoaGVhZCkpIHtcbiAgICAgIGZvciAobGV0IG5hdGl2ZU5vZGUgb2YgaGVhZCkge1xuICAgICAgICBfYWRkUXVlcnlNYXRjaChuYXRpdmVOb2RlLCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZiAoaGVhZCkge1xuICAgICAgY29uc3QgbmV4dExWaWV3ID0gY29tcG9uZW50Vmlld1tQQVJFTlRdISBhcyBMVmlldztcbiAgICAgIGNvbnN0IG5leHRUTm9kZSA9IG5leHRMVmlld1tUVklFV10uZGF0YVtoZWFkLmluZGV4XSBhcyBUTm9kZTtcbiAgICAgIF9xdWVyeU5vZGVDaGlsZHJlbihuZXh0VE5vZGUsIG5leHRMVmlldywgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHksIHJvb3ROYXRpdmVOb2RlKTtcbiAgICB9XG4gIH0gZWxzZSBpZiAodE5vZGUuY2hpbGQpIHtcbiAgICAvLyBDYXNlIDQ6IHRoZSBUTm9kZSBpcyBhIHZpZXcuXG4gICAgX3F1ZXJ5Tm9kZUNoaWxkcmVuKHROb2RlLmNoaWxkLCBsVmlldywgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHksIHJvb3ROYXRpdmVOb2RlKTtcbiAgfVxuXG4gIC8vIFdlIGRvbid0IHdhbnQgdG8gZ28gdG8gdGhlIG5leHQgc2libGluZyBvZiB0aGUgcm9vdCBub2RlLlxuICBpZiAocm9vdE5hdGl2ZU5vZGUgIT09IG5hdGl2ZU5vZGUpIHtcbiAgICAvLyBUbyBkZXRlcm1pbmUgdGhlIG5leHQgbm9kZSB0byBiZSBwcm9jZXNzZWQsIHdlIG5lZWQgdG8gdXNlIHRoZSBuZXh0IG9yIHRoZSBwcm9qZWN0aW9uTmV4dFxuICAgIC8vIGxpbmssIGRlcGVuZGluZyBvbiB3aGV0aGVyIHRoZSBjdXJyZW50IG5vZGUgaGFzIGJlZW4gcHJvamVjdGVkLlxuICAgIGNvbnN0IG5leHRUTm9kZSA9ICh0Tm9kZS5mbGFncyAmIFROb2RlRmxhZ3MuaXNQcm9qZWN0ZWQpID8gdE5vZGUucHJvamVjdGlvbk5leHQgOiB0Tm9kZS5uZXh0O1xuICAgIGlmIChuZXh0VE5vZGUpIHtcbiAgICAgIF9xdWVyeU5vZGVDaGlsZHJlbihuZXh0VE5vZGUsIGxWaWV3LCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIFByb2Nlc3MgYWxsIFROb2RlcyBpbiBhIGdpdmVuIGNvbnRhaW5lci5cbiAqXG4gKiBAcGFyYW0gbENvbnRhaW5lciB0aGUgY29udGFpbmVyIHRvIGJlIHByb2Nlc3NlZFxuICogQHBhcmFtIHByZWRpY2F0ZSB0aGUgcHJlZGljYXRlIHRvIG1hdGNoXG4gKiBAcGFyYW0gbWF0Y2hlcyB0aGUgbGlzdCBvZiBwb3NpdGl2ZSBtYXRjaGVzXG4gKiBAcGFyYW0gZWxlbWVudHNPbmx5IHdoZXRoZXIgb25seSBlbGVtZW50cyBzaG91bGQgYmUgc2VhcmNoZWRcbiAqIEBwYXJhbSByb290TmF0aXZlTm9kZSB0aGUgcm9vdCBuYXRpdmUgbm9kZSBvbiB3aGljaCBwcmVkaWNhdGUgc2hvdWxkIG5vdCBiZSBtYXRjaGVkXG4gKi9cbmZ1bmN0aW9uIF9xdWVyeU5vZGVDaGlsZHJlbkluQ29udGFpbmVyKFxuICAgIGxDb250YWluZXI6IExDb250YWluZXIsIHByZWRpY2F0ZTogUHJlZGljYXRlPERlYnVnRWxlbWVudD58UHJlZGljYXRlPERlYnVnTm9kZT4sXG4gICAgbWF0Y2hlczogRGVidWdFbGVtZW50W118RGVidWdOb2RlW10sIGVsZW1lbnRzT25seTogYm9vbGVhbiwgcm9vdE5hdGl2ZU5vZGU6IGFueSkge1xuICBmb3IgKGxldCBpID0gQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQ7IGkgPCBsQ29udGFpbmVyLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgY2hpbGRWaWV3ID0gbENvbnRhaW5lcltpXSBhcyBMVmlldztcbiAgICBjb25zdCBmaXJzdENoaWxkID0gY2hpbGRWaWV3W1RWSUVXXS5maXJzdENoaWxkO1xuICAgIGlmIChmaXJzdENoaWxkKSB7XG4gICAgICBfcXVlcnlOb2RlQ2hpbGRyZW4oZmlyc3RDaGlsZCwgY2hpbGRWaWV3LCBwcmVkaWNhdGUsIG1hdGNoZXMsIGVsZW1lbnRzT25seSwgcm9vdE5hdGl2ZU5vZGUpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIE1hdGNoIHRoZSBjdXJyZW50IG5hdGl2ZSBub2RlIGFnYWluc3QgdGhlIHByZWRpY2F0ZS5cbiAqXG4gKiBAcGFyYW0gbmF0aXZlTm9kZSB0aGUgY3VycmVudCBuYXRpdmUgbm9kZVxuICogQHBhcmFtIHByZWRpY2F0ZSB0aGUgcHJlZGljYXRlIHRvIG1hdGNoXG4gKiBAcGFyYW0gbWF0Y2hlcyB0aGUgbGlzdCBvZiBwb3NpdGl2ZSBtYXRjaGVzXG4gKiBAcGFyYW0gZWxlbWVudHNPbmx5IHdoZXRoZXIgb25seSBlbGVtZW50cyBzaG91bGQgYmUgc2VhcmNoZWRcbiAqIEBwYXJhbSByb290TmF0aXZlTm9kZSB0aGUgcm9vdCBuYXRpdmUgbm9kZSBvbiB3aGljaCBwcmVkaWNhdGUgc2hvdWxkIG5vdCBiZSBtYXRjaGVkXG4gKi9cbmZ1bmN0aW9uIF9hZGRRdWVyeU1hdGNoKFxuICAgIG5hdGl2ZU5vZGU6IGFueSwgcHJlZGljYXRlOiBQcmVkaWNhdGU8RGVidWdFbGVtZW50PnxQcmVkaWNhdGU8RGVidWdOb2RlPixcbiAgICBtYXRjaGVzOiBEZWJ1Z0VsZW1lbnRbXXxEZWJ1Z05vZGVbXSwgZWxlbWVudHNPbmx5OiBib29sZWFuLCByb290TmF0aXZlTm9kZTogYW55KSB7XG4gIGlmIChyb290TmF0aXZlTm9kZSAhPT0gbmF0aXZlTm9kZSkge1xuICAgIGNvbnN0IGRlYnVnTm9kZSA9IGdldERlYnVnTm9kZShuYXRpdmVOb2RlKTtcbiAgICBpZiAoIWRlYnVnTm9kZSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICAvLyBUeXBlIG9mIHRoZSBcInByZWRpY2F0ZSBhbmQgXCJtYXRjaGVzXCIgYXJyYXkgYXJlIHNldCBiYXNlZCBvbiB0aGUgdmFsdWUgb2ZcbiAgICAvLyB0aGUgXCJlbGVtZW50c09ubHlcIiBwYXJhbWV0ZXIuIFR5cGVTY3JpcHQgaXMgbm90IGFibGUgdG8gcHJvcGVybHkgaW5mZXIgdGhlc2VcbiAgICAvLyB0eXBlcyB3aXRoIGdlbmVyaWNzLCBzbyB3ZSBtYW51YWxseSBjYXN0IHRoZSBwYXJhbWV0ZXJzIGFjY29yZGluZ2x5LlxuICAgIGlmIChlbGVtZW50c09ubHkgJiYgKGRlYnVnTm9kZSBpbnN0YW5jZW9mIERlYnVnRWxlbWVudCkgJiYgcHJlZGljYXRlKGRlYnVnTm9kZSkgJiZcbiAgICAgICAgbWF0Y2hlcy5pbmRleE9mKGRlYnVnTm9kZSkgPT09IC0xKSB7XG4gICAgICBtYXRjaGVzLnB1c2goZGVidWdOb2RlKTtcbiAgICB9IGVsc2UgaWYgKFxuICAgICAgICAhZWxlbWVudHNPbmx5ICYmIChwcmVkaWNhdGUgYXMgUHJlZGljYXRlPERlYnVnTm9kZT4pKGRlYnVnTm9kZSkgJiZcbiAgICAgICAgKG1hdGNoZXMgYXMgRGVidWdOb2RlW10pLmluZGV4T2YoZGVidWdOb2RlKSA9PT0gLTEpIHtcbiAgICAgIChtYXRjaGVzIGFzIERlYnVnTm9kZVtdKS5wdXNoKGRlYnVnTm9kZSk7XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogTWF0Y2ggYWxsIHRoZSBkZXNjZW5kYW50cyBvZiBhIERPTSBub2RlIGFnYWluc3QgYSBwcmVkaWNhdGUuXG4gKlxuICogQHBhcmFtIG5hdGl2ZU5vZGUgdGhlIGN1cnJlbnQgbmF0aXZlIG5vZGVcbiAqIEBwYXJhbSBwcmVkaWNhdGUgdGhlIHByZWRpY2F0ZSB0byBtYXRjaFxuICogQHBhcmFtIG1hdGNoZXMgdGhlIGxpc3Qgd2hlcmUgbWF0Y2hlcyBhcmUgc3RvcmVkXG4gKiBAcGFyYW0gZWxlbWVudHNPbmx5IHdoZXRoZXIgb25seSBlbGVtZW50cyBzaG91bGQgYmUgc2VhcmNoZWRcbiAqL1xuZnVuY3Rpb24gX3F1ZXJ5TmF0aXZlTm9kZURlc2NlbmRhbnRzKFxuICAgIHBhcmVudE5vZGU6IGFueSwgcHJlZGljYXRlOiBQcmVkaWNhdGU8RGVidWdFbGVtZW50PnxQcmVkaWNhdGU8RGVidWdOb2RlPixcbiAgICBtYXRjaGVzOiBEZWJ1Z0VsZW1lbnRbXXxEZWJ1Z05vZGVbXSwgZWxlbWVudHNPbmx5OiBib29sZWFuKSB7XG4gIGNvbnN0IG5vZGVzID0gcGFyZW50Tm9kZS5jaGlsZE5vZGVzO1xuICBjb25zdCBsZW5ndGggPSBub2Rlcy5sZW5ndGg7XG5cbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBsZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IG5vZGUgPSBub2Rlc1tpXTtcbiAgICBjb25zdCBkZWJ1Z05vZGUgPSBnZXREZWJ1Z05vZGUobm9kZSk7XG5cbiAgICBpZiAoZGVidWdOb2RlKSB7XG4gICAgICBpZiAoZWxlbWVudHNPbmx5ICYmIChkZWJ1Z05vZGUgaW5zdGFuY2VvZiBEZWJ1Z0VsZW1lbnQpICYmIHByZWRpY2F0ZShkZWJ1Z05vZGUpICYmXG4gICAgICAgICAgbWF0Y2hlcy5pbmRleE9mKGRlYnVnTm9kZSkgPT09IC0xKSB7XG4gICAgICAgIG1hdGNoZXMucHVzaChkZWJ1Z05vZGUpO1xuICAgICAgfSBlbHNlIGlmIChcbiAgICAgICAgICAhZWxlbWVudHNPbmx5ICYmIChwcmVkaWNhdGUgYXMgUHJlZGljYXRlPERlYnVnTm9kZT4pKGRlYnVnTm9kZSkgJiZcbiAgICAgICAgICAobWF0Y2hlcyBhcyBEZWJ1Z05vZGVbXSkuaW5kZXhPZihkZWJ1Z05vZGUpID09PSAtMSkge1xuICAgICAgICAobWF0Y2hlcyBhcyBEZWJ1Z05vZGVbXSkucHVzaChkZWJ1Z05vZGUpO1xuICAgICAgfVxuXG4gICAgICBfcXVlcnlOYXRpdmVOb2RlRGVzY2VuZGFudHMobm9kZSwgcHJlZGljYXRlLCBtYXRjaGVzLCBlbGVtZW50c09ubHkpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEl0ZXJhdGVzIHRocm91Z2ggdGhlIHByb3BlcnR5IGJpbmRpbmdzIGZvciBhIGdpdmVuIG5vZGUgYW5kIGdlbmVyYXRlc1xuICogYSBtYXAgb2YgcHJvcGVydHkgbmFtZXMgdG8gdmFsdWVzLiBUaGlzIG1hcCBvbmx5IGNvbnRhaW5zIHByb3BlcnR5IGJpbmRpbmdzXG4gKiBkZWZpbmVkIGluIHRlbXBsYXRlcywgbm90IGluIGhvc3QgYmluZGluZ3MuXG4gKi9cbmZ1bmN0aW9uIGNvbGxlY3RQcm9wZXJ0eUJpbmRpbmdzKFxuICAgIHByb3BlcnRpZXM6IHtba2V5OiBzdHJpbmddOiBzdHJpbmd9LCB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldywgdERhdGE6IFREYXRhKTogdm9pZCB7XG4gIGxldCBiaW5kaW5nSW5kZXhlcyA9IHROb2RlLnByb3BlcnR5QmluZGluZ3M7XG5cbiAgaWYgKGJpbmRpbmdJbmRleGVzICE9PSBudWxsKSB7XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBiaW5kaW5nSW5kZXhlcy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3QgYmluZGluZ0luZGV4ID0gYmluZGluZ0luZGV4ZXNbaV07XG4gICAgICBjb25zdCBwcm9wTWV0YWRhdGEgPSB0RGF0YVtiaW5kaW5nSW5kZXhdIGFzIHN0cmluZztcbiAgICAgIGNvbnN0IG1ldGFkYXRhUGFydHMgPSBwcm9wTWV0YWRhdGEuc3BsaXQoSU5URVJQT0xBVElPTl9ERUxJTUlURVIpO1xuICAgICAgY29uc3QgcHJvcGVydHlOYW1lID0gbWV0YWRhdGFQYXJ0c1swXTtcbiAgICAgIGlmIChtZXRhZGF0YVBhcnRzLmxlbmd0aCA+IDEpIHtcbiAgICAgICAgbGV0IHZhbHVlID0gbWV0YWRhdGFQYXJ0c1sxXTtcbiAgICAgICAgZm9yIChsZXQgaiA9IDE7IGogPCBtZXRhZGF0YVBhcnRzLmxlbmd0aCAtIDE7IGorKykge1xuICAgICAgICAgIHZhbHVlICs9IHJlbmRlclN0cmluZ2lmeShsVmlld1tiaW5kaW5nSW5kZXggKyBqIC0gMV0pICsgbWV0YWRhdGFQYXJ0c1tqICsgMV07XG4gICAgICAgIH1cbiAgICAgICAgcHJvcGVydGllc1twcm9wZXJ0eU5hbWVdID0gdmFsdWU7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBwcm9wZXJ0aWVzW3Byb3BlcnR5TmFtZV0gPSBsVmlld1tiaW5kaW5nSW5kZXhdO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG5cbi8vIE5lZWQgdG8ga2VlcCB0aGUgbm9kZXMgaW4gYSBnbG9iYWwgTWFwIHNvIHRoYXQgbXVsdGlwbGUgYW5ndWxhciBhcHBzIGFyZSBzdXBwb3J0ZWQuXG5jb25zdCBfbmF0aXZlTm9kZVRvRGVidWdOb2RlID0gbmV3IE1hcDxhbnksIERlYnVnTm9kZT4oKTtcblxuY29uc3QgTkdfREVCVUdfUFJPUEVSVFkgPSAnX19uZ19kZWJ1Z19fJztcblxuLyoqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBnZXREZWJ1Z05vZGUobmF0aXZlTm9kZTogYW55KTogRGVidWdOb2RlfG51bGwge1xuICBpZiAobmF0aXZlTm9kZSBpbnN0YW5jZW9mIE5vZGUpIHtcbiAgICBpZiAoIShuYXRpdmVOb2RlLmhhc093blByb3BlcnR5KE5HX0RFQlVHX1BST1BFUlRZKSkpIHtcbiAgICAgIChuYXRpdmVOb2RlIGFzIGFueSlbTkdfREVCVUdfUFJPUEVSVFldID0gbmF0aXZlTm9kZS5ub2RlVHlwZSA9PSBOb2RlLkVMRU1FTlRfTk9ERSA/XG4gICAgICAgICAgbmV3IERlYnVnRWxlbWVudChuYXRpdmVOb2RlIGFzIEVsZW1lbnQpIDpcbiAgICAgICAgICBuZXcgRGVidWdOb2RlKG5hdGl2ZU5vZGUpO1xuICAgIH1cbiAgICByZXR1cm4gKG5hdGl2ZU5vZGUgYXMgYW55KVtOR19ERUJVR19QUk9QRVJUWV07XG4gIH1cbiAgcmV0dXJuIG51bGw7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRBbGxEZWJ1Z05vZGVzKCk6IERlYnVnTm9kZVtdIHtcbiAgcmV0dXJuIEFycmF5LmZyb20oX25hdGl2ZU5vZGVUb0RlYnVnTm9kZS52YWx1ZXMoKSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpbmRleERlYnVnTm9kZShub2RlOiBEZWJ1Z05vZGUpIHtcbiAgX25hdGl2ZU5vZGVUb0RlYnVnTm9kZS5zZXQobm9kZS5uYXRpdmVOb2RlLCBub2RlKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHJlbW92ZURlYnVnTm9kZUZyb21JbmRleChub2RlOiBEZWJ1Z05vZGUpIHtcbiAgX25hdGl2ZU5vZGVUb0RlYnVnTm9kZS5kZWxldGUobm9kZS5uYXRpdmVOb2RlKTtcbn1cblxuLyoqXG4gKiBBIGJvb2xlYW4tdmFsdWVkIGZ1bmN0aW9uIG92ZXIgYSB2YWx1ZSwgcG9zc2libHkgaW5jbHVkaW5nIGNvbnRleHQgaW5mb3JtYXRpb25cbiAqIHJlZ2FyZGluZyB0aGF0IHZhbHVlJ3MgcG9zaXRpb24gaW4gYW4gYXJyYXkuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgaW50ZXJmYWNlIFByZWRpY2F0ZTxUPiB7XG4gICh2YWx1ZTogVCk6IGJvb2xlYW47XG59XG4iXX0=