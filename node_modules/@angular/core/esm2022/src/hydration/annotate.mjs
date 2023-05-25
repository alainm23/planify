/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ViewEncapsulation } from '../metadata';
import { collectNativeNodes } from '../render3/collect_native_nodes';
import { getComponentDef } from '../render3/definition';
import { CONTAINER_HEADER_OFFSET } from '../render3/interfaces/container';
import { isComponentHost, isLContainer, isProjectionTNode, isRootView } from '../render3/interfaces/type_checks';
import { CONTEXT, FLAGS, HEADER_OFFSET, HOST, RENDERER, TVIEW } from '../render3/interfaces/view';
import { unwrapRNode } from '../render3/util/view_utils';
import { TransferState } from '../transfer_state';
import { unsupportedProjectionOfDomNodes } from './error_handling';
import { CONTAINERS, DISCONNECTED_NODES, ELEMENT_CONTAINERS, MULTIPLIER, NODES, NUM_ROOT_NODES, TEMPLATE_ID, TEMPLATES } from './interfaces';
import { calcPathForNode } from './node_lookup_utils';
import { isInSkipHydrationBlock, SKIP_HYDRATION_ATTR_NAME } from './skip_hydration';
import { getComponentLViewForHydration, NGH_ATTR_NAME, NGH_DATA_KEY } from './utils';
/**
 * A collection that tracks all serialized views (`ngh` DOM annotations)
 * to avoid duplication. An attempt to add a duplicate view results in the
 * collection returning the index of the previously collected serialized view.
 * This reduces the number of annotations needed for a given page.
 */
class SerializedViewCollection {
    constructor() {
        this.views = [];
        this.indexByContent = new Map();
    }
    add(serializedView) {
        const viewAsString = JSON.stringify(serializedView);
        if (!this.indexByContent.has(viewAsString)) {
            const index = this.views.length;
            this.views.push(serializedView);
            this.indexByContent.set(viewAsString, index);
            return index;
        }
        return this.indexByContent.get(viewAsString);
    }
    getAll() {
        return this.views;
    }
}
/**
 * Global counter that is used to generate a unique id for TViews
 * during the serialization process.
 */
let tViewSsrId = 0;
/**
 * Generates a unique id for a given TView and returns this id.
 * The id is also stored on this instance of a TView and reused in
 * subsequent calls.
 *
 * This id is needed to uniquely identify and pick up dehydrated views
 * at runtime.
 */
function getSsrId(tView) {
    if (!tView.ssrId) {
        tView.ssrId = `t${tViewSsrId++}`;
    }
    return tView.ssrId;
}
/**
 * Computes the number of root nodes in a given view
 * (or child nodes in a given container if a tNode is provided).
 */
function calcNumRootNodes(tView, lView, tNode) {
    const rootNodes = [];
    collectNativeNodes(tView, lView, tNode, rootNodes);
    return rootNodes.length;
}
/**
 * Annotates all components bootstrapped in a given ApplicationRef
 * with info needed for hydration.
 *
 * @param appRef An instance of an ApplicationRef.
 * @param doc A reference to the current Document instance.
 */
export function annotateForHydration(appRef, doc) {
    const serializedViewCollection = new SerializedViewCollection();
    const corruptedTextNodes = new Map();
    const viewRefs = appRef._views;
    for (const viewRef of viewRefs) {
        const lView = getComponentLViewForHydration(viewRef);
        // An `lView` might be `null` if a `ViewRef` represents
        // an embedded view (not a component view).
        if (lView !== null) {
            const hostElement = lView[HOST];
            // Root elements might also be annotated with the `ngSkipHydration` attribute,
            // check if it's present before starting the serialization process.
            if (hostElement && !hostElement.hasAttribute(SKIP_HYDRATION_ATTR_NAME)) {
                const context = {
                    serializedViewCollection,
                    corruptedTextNodes,
                };
                annotateHostElementForHydration(hostElement, lView, context);
                insertCorruptedTextNodeMarkers(corruptedTextNodes, doc);
            }
        }
    }
    // Note: we *always* include hydration info key and a corresponding value
    // into the TransferState, even if the list of serialized views is empty.
    // This is needed as a signal to the client that the server part of the
    // hydration logic was setup and enabled correctly. Otherwise, if a client
    // hydration doesn't find a key in the transfer state - an error is produced.
    const serializedViews = serializedViewCollection.getAll();
    const transferState = appRef.injector.get(TransferState);
    transferState.set(NGH_DATA_KEY, serializedViews);
}
/**
 * Serializes the lContainer data into a list of SerializedView objects,
 * that represent views within this lContainer.
 *
 * @param lContainer the lContainer we are serializing
 * @param context the hydration context
 * @returns an array of the `SerializedView` objects
 */
function serializeLContainer(lContainer, context) {
    const views = [];
    let lastViewAsString = '';
    for (let i = CONTAINER_HEADER_OFFSET; i < lContainer.length; i++) {
        let childLView = lContainer[i];
        // If this is a root view, get an LView for the underlying component,
        // because it contains information about the view to serialize.
        if (isRootView(childLView)) {
            childLView = childLView[HEADER_OFFSET];
        }
        const childTView = childLView[TVIEW];
        let template;
        let numRootNodes = 0;
        if (childTView.type === 1 /* TViewType.Component */) {
            template = childTView.ssrId;
            // This is a component view, thus it has only 1 root node: the component
            // host node itself (other nodes would be inside that host node).
            numRootNodes = 1;
        }
        else {
            template = getSsrId(childTView);
            numRootNodes = calcNumRootNodes(childTView, childLView, childTView.firstChild);
        }
        const view = {
            [TEMPLATE_ID]: template,
            [NUM_ROOT_NODES]: numRootNodes,
            ...serializeLView(lContainer[i], context),
        };
        // Check if the previous view has the same shape (for example, it was
        // produced by the *ngFor), in which case bump the counter on the previous
        // view instead of including the same information again.
        const currentViewAsString = JSON.stringify(view);
        if (views.length > 0 && currentViewAsString === lastViewAsString) {
            const previousView = views[views.length - 1];
            previousView[MULTIPLIER] ??= 1;
            previousView[MULTIPLIER]++;
        }
        else {
            // Record this view as most recently added.
            lastViewAsString = currentViewAsString;
            views.push(view);
        }
    }
    return views;
}
/**
 * Helper function to produce a node path (which navigation steps runtime logic
 * needs to take to locate a node) and stores it in the `NODES` section of the
 * current serialized view.
 */
function appendSerializedNodePath(ngh, tNode, lView) {
    const noOffsetIndex = tNode.index - HEADER_OFFSET;
    ngh[NODES] ??= {};
    ngh[NODES][noOffsetIndex] = calcPathForNode(tNode, lView);
}
/**
 * Helper function to append information about a disconnected node.
 * This info is needed at runtime to avoid DOM lookups for this element
 * and instead, the element would be created from scratch.
 */
function appendDisconnectedNodeIndex(ngh, tNode) {
    const noOffsetIndex = tNode.index - HEADER_OFFSET;
    ngh[DISCONNECTED_NODES] ??= [];
    if (!ngh[DISCONNECTED_NODES].includes(noOffsetIndex)) {
        ngh[DISCONNECTED_NODES].push(noOffsetIndex);
    }
}
/**
 * Serializes the lView data into a SerializedView object that will later be added
 * to the TransferState storage and referenced using the `ngh` attribute on a host
 * element.
 *
 * @param lView the lView we are serializing
 * @param context the hydration context
 * @returns the `SerializedView` object containing the data to be added to the host node
 */
function serializeLView(lView, context) {
    const ngh = {};
    const tView = lView[TVIEW];
    // Iterate over DOM element references in an LView.
    for (let i = HEADER_OFFSET; i < tView.bindingStartIndex; i++) {
        const tNode = tView.data[i];
        const noOffsetIndex = i - HEADER_OFFSET;
        // Local refs (e.g. <div #localRef>) take up an extra slot in LViews
        // to store the same element. In this case, there is no information in
        // a corresponding slot in TNode data structure. If that's the case, just
        // skip this slot and move to the next one.
        if (!tNode) {
            continue;
        }
        // Check if a native node that represents a given TNode is disconnected from the DOM tree.
        // Such nodes must be excluded from the hydration (since the hydration won't be able to
        // find them), so the TNode ids are collected and used at runtime to skip the hydration.
        //
        // This situation may happen during the content projection, when some nodes don't make it
        // into one of the content projection slots (for example, when there is no default
        // <ng-content /> slot in projector component's template).
        if (isDisconnectedNode(tNode, lView) && isContentProjectedNode(tNode)) {
            appendDisconnectedNodeIndex(ngh, tNode);
            continue;
        }
        if (Array.isArray(tNode.projection)) {
            for (const projectionHeadTNode of tNode.projection) {
                // We may have `null`s in slots with no projected content.
                if (!projectionHeadTNode)
                    continue;
                if (!Array.isArray(projectionHeadTNode)) {
                    // If we process re-projected content (i.e. `<ng-content>`
                    // appears at projection location), skip annotations for this content
                    // since all DOM nodes in this projection were handled while processing
                    // a parent lView, which contains those nodes.
                    if (!isProjectionTNode(projectionHeadTNode) &&
                        !isInSkipHydrationBlock(projectionHeadTNode)) {
                        if (isDisconnectedNode(projectionHeadTNode, lView)) {
                            // Check whether this node is connected, since we may have a TNode
                            // in the data structure as a projection segment head, but the
                            // content projection slot might be disabled (e.g.
                            // <ng-content *ngIf="false" />).
                            appendDisconnectedNodeIndex(ngh, projectionHeadTNode);
                        }
                        else {
                            appendSerializedNodePath(ngh, projectionHeadTNode, lView);
                        }
                    }
                }
                else {
                    // If a value is an array, it means that we are processing a projection
                    // where projectable nodes were passed in as DOM nodes (for example, when
                    // calling `ViewContainerRef.createComponent(CmpA, {projectableNodes: [...]})`).
                    //
                    // In this scenario, nodes can come from anywhere (either created manually,
                    // accessed via `document.querySelector`, etc) and may be in any state
                    // (attached or detached from the DOM tree). As a result, we can not reliably
                    // restore the state for such cases during hydration.
                    throw unsupportedProjectionOfDomNodes(unwrapRNode(lView[i]));
                }
            }
        }
        if (isLContainer(lView[i])) {
            // Serialize information about a template.
            const embeddedTView = tNode.tView;
            if (embeddedTView !== null) {
                ngh[TEMPLATES] ??= {};
                ngh[TEMPLATES][noOffsetIndex] = getSsrId(embeddedTView);
            }
            // Serialize views within this LContainer.
            const hostNode = lView[i][HOST]; // host node of this container
            // LView[i][HOST] can be of 2 different types:
            // - either a DOM node
            // - or an array that represents an LView of a component
            if (Array.isArray(hostNode)) {
                // This is a component, serialize info about it.
                const targetNode = unwrapRNode(hostNode);
                if (!targetNode.hasAttribute(SKIP_HYDRATION_ATTR_NAME)) {
                    annotateHostElementForHydration(targetNode, hostNode, context);
                }
            }
            ngh[CONTAINERS] ??= {};
            ngh[CONTAINERS][noOffsetIndex] = serializeLContainer(lView[i], context);
        }
        else if (Array.isArray(lView[i])) {
            // This is a component, annotate the host node with an `ngh` attribute.
            const targetNode = unwrapRNode(lView[i][HOST]);
            if (!targetNode.hasAttribute(SKIP_HYDRATION_ATTR_NAME)) {
                annotateHostElementForHydration(targetNode, lView[i], context);
            }
        }
        else {
            // <ng-container> case
            if (tNode.type & 8 /* TNodeType.ElementContainer */) {
                // An <ng-container> is represented by the number of
                // top-level nodes. This information is needed to skip over
                // those nodes to reach a corresponding anchor node (comment node).
                ngh[ELEMENT_CONTAINERS] ??= {};
                ngh[ELEMENT_CONTAINERS][noOffsetIndex] = calcNumRootNodes(tView, lView, tNode.child);
            }
            else if (tNode.type & 16 /* TNodeType.Projection */) {
                // Current TNode represents an `<ng-content>` slot, thus it has no
                // DOM elements associated with it, so the **next sibling** node would
                // not be able to find an anchor. In this case, use full path instead.
                let nextTNode = tNode.next;
                // Skip over all `<ng-content>` slots in a row.
                while (nextTNode !== null && (nextTNode.type & 16 /* TNodeType.Projection */)) {
                    nextTNode = nextTNode.next;
                }
                if (nextTNode && !isInSkipHydrationBlock(nextTNode)) {
                    // Handle a tNode after the `<ng-content>` slot.
                    appendSerializedNodePath(ngh, nextTNode, lView);
                }
            }
            else {
                // Handle cases where text nodes can be lost after DOM serialization:
                //  1. When there is an *empty text node* in DOM: in this case, this
                //     node would not make it into the serialized string and as a result,
                //     this node wouldn't be created in a browser. This would result in
                //     a mismatch during the hydration, where the runtime logic would expect
                //     a text node to be present in live DOM, but no text node would exist.
                //     Example: `<span>{{ name }}</span>` when the `name` is an empty string.
                //     This would result in `<span></span>` string after serialization and
                //     in a browser only the `span` element would be created. To resolve that,
                //     an extra comment node is appended in place of an empty text node and
                //     that special comment node is replaced with an empty text node *before*
                //     hydration.
                //  2. When there are 2 consecutive text nodes present in the DOM.
                //     Example: `<div>Hello <ng-container *ngIf="true">world</ng-container></div>`.
                //     In this scenario, the live DOM would look like this:
                //       <div>#text('Hello ') #text('world') #comment('container')</div>
                //     Serialized string would look like this: `<div>Hello world<!--container--></div>`.
                //     The live DOM in a browser after that would be:
                //       <div>#text('Hello world') #comment('container')</div>
                //     Notice how 2 text nodes are now "merged" into one. This would cause hydration
                //     logic to fail, since it'd expect 2 text nodes being present, not one.
                //     To fix this, we insert a special comment node in between those text nodes, so
                //     serialized representation is: `<div>Hello <!--ngtns-->world<!--container--></div>`.
                //     This forces browser to create 2 text nodes separated by a comment node.
                //     Before running a hydration process, this special comment node is removed, so the
                //     live DOM has exactly the same state as it was before serialization.
                if (tNode.type & 1 /* TNodeType.Text */) {
                    const rNode = unwrapRNode(lView[i]);
                    // Collect this node as required special annotation only when its
                    // contents is empty. Otherwise, such text node would be present on
                    // the client after server-side rendering and no special handling needed.
                    if (rNode.textContent === '') {
                        context.corruptedTextNodes.set(rNode, "ngetn" /* TextNodeMarker.EmptyNode */);
                    }
                    else if (rNode.nextSibling?.nodeType === Node.TEXT_NODE) {
                        context.corruptedTextNodes.set(rNode, "ngtns" /* TextNodeMarker.Separator */);
                    }
                }
                if (tNode.projectionNext && tNode.projectionNext !== tNode.next &&
                    !isInSkipHydrationBlock(tNode.projectionNext)) {
                    // Check if projection next is not the same as next, in which case
                    // the node would not be found at creation time at runtime and we
                    // need to provide a location for that node.
                    appendSerializedNodePath(ngh, tNode.projectionNext, lView);
                }
            }
        }
    }
    return ngh;
}
/**
 * Determines whether a component instance that is represented
 * by a given LView uses `ViewEncapsulation.ShadowDom`.
 */
function componentUsesShadowDomEncapsulation(lView) {
    const instance = lView[CONTEXT];
    return instance?.constructor ?
        getComponentDef(instance.constructor)?.encapsulation === ViewEncapsulation.ShadowDom :
        false;
}
/**
 * Annotates component host element for hydration:
 * - by either adding the `ngh` attribute and collecting hydration-related info
 *   for the serialization and transferring to the client
 * - or by adding the `ngSkipHydration` attribute in case Angular detects that
 *   component contents is not compatible with hydration.
 *
 * @param element The Host element to be annotated
 * @param lView The associated LView
 * @param context The hydration context
 */
function annotateHostElementForHydration(element, lView, context) {
    const renderer = lView[RENDERER];
    if ((lView[FLAGS] & 32 /* LViewFlags.HasI18n */) === 32 /* LViewFlags.HasI18n */ ||
        componentUsesShadowDomEncapsulation(lView)) {
        // Attach the skip hydration attribute if this component:
        // - either has i18n blocks, since hydrating such blocks is not yet supported
        // - or uses ShadowDom view encapsulation, since Domino doesn't support
        //   shadow DOM, so we can not guarantee that client and server representations
        //   would exactly match
        renderer.setAttribute(element, SKIP_HYDRATION_ATTR_NAME, '');
    }
    else {
        const ngh = serializeLView(lView, context);
        const index = context.serializedViewCollection.add(ngh);
        renderer.setAttribute(element, NGH_ATTR_NAME, index.toString());
    }
}
/**
 * Physically inserts the comment nodes to ensure empty text nodes and adjacent
 * text node separators are preserved after server serialization of the DOM.
 * These get swapped back for empty text nodes or separators once hydration happens
 * on the client.
 *
 * @param corruptedTextNodes The Map of text nodes to be replaced with comments
 * @param doc The document
 */
function insertCorruptedTextNodeMarkers(corruptedTextNodes, doc) {
    for (const [textNode, marker] of corruptedTextNodes) {
        textNode.after(doc.createComment(marker));
    }
}
/**
 * Detects whether a given TNode represents a node that
 * is being content projected.
 */
function isContentProjectedNode(tNode) {
    let currentTNode = tNode;
    while (currentTNode != null) {
        // If we come across a component host node in parent nodes -
        // this TNode is in the content projection section.
        if (isComponentHost(currentTNode)) {
            return true;
        }
        currentTNode = currentTNode.parent;
    }
    return false;
}
/**
 * Check whether a given node exists, but is disconnected from the DOM.
 *
 * Note: we leverage the fact that we have this information available in the DOM emulation
 * layer (in Domino) for now. Longer-term solution should not rely on the DOM emulation and
 * only use internal data structures and state to compute this information.
 */
function isDisconnectedNode(tNode, lView) {
    return !(tNode.type & 16 /* TNodeType.Projection */) && !!lView[tNode.index] &&
        !unwrapRNode(lView[tNode.index]).isConnected;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYW5ub3RhdGUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9oeWRyYXRpb24vYW5ub3RhdGUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBR0gsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sYUFBYSxDQUFDO0FBQzlDLE9BQU8sRUFBQyxrQkFBa0IsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQ25FLE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSx1QkFBdUIsQ0FBQztBQUN0RCxPQUFPLEVBQUMsdUJBQXVCLEVBQWEsTUFBTSxpQ0FBaUMsQ0FBQztBQUdwRixPQUFPLEVBQUMsZUFBZSxFQUFFLFlBQVksRUFBRSxpQkFBaUIsRUFBRSxVQUFVLEVBQUMsTUFBTSxtQ0FBbUMsQ0FBQztBQUMvRyxPQUFPLEVBQUMsT0FBTyxFQUFFLEtBQUssRUFBRSxhQUFhLEVBQUUsSUFBSSxFQUFxQixRQUFRLEVBQVMsS0FBSyxFQUFZLE1BQU0sNEJBQTRCLENBQUM7QUFDckksT0FBTyxFQUFDLFdBQVcsRUFBQyxNQUFNLDRCQUE0QixDQUFDO0FBQ3ZELE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUVoRCxPQUFPLEVBQUMsK0JBQStCLEVBQUMsTUFBTSxrQkFBa0IsQ0FBQztBQUNqRSxPQUFPLEVBQUMsVUFBVSxFQUFFLGtCQUFrQixFQUFFLGtCQUFrQixFQUFFLFVBQVUsRUFBRSxLQUFLLEVBQUUsY0FBYyxFQUEyQyxXQUFXLEVBQUUsU0FBUyxFQUFDLE1BQU0sY0FBYyxDQUFDO0FBQ3BMLE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQUNwRCxPQUFPLEVBQUMsc0JBQXNCLEVBQUUsd0JBQXdCLEVBQUMsTUFBTSxrQkFBa0IsQ0FBQztBQUNsRixPQUFPLEVBQUMsNkJBQTZCLEVBQUUsYUFBYSxFQUFFLFlBQVksRUFB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LFlBQVksR0FBRyxZQUFZLENBQUMsTUFBZSxDQUFDO0tBQzdDO0lBQ0QsT0FBTyxLQUFLLENBQUM7QUFDZixDQUFDO0FBRUQ7Ozs7OztHQU1HO0FBQ0gsU0FBUyxrQkFBa0IsQ0FBQyxLQUFZLEVBQUUsS0FBWTtJQUNwRCxPQUFPLENBQUMsQ0FBQyxLQUFLLENBQUMsSUFBSSxnQ0FBdUIsQ0FBQyxJQUFJLENBQUMsQ0FBQyxLQUFLLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQztRQUMvRCxDQUFFLFdBQVcsQ0FBQyxLQUFLLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQyxDQUFVLENBQUMsV0FBVyxDQUFDO0FBQzdELENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtBcHBsaWNhdGlvblJlZn0gZnJvbSAnLi4vYXBwbGljYXRpb25fcmVmJztcbmltcG9ydCB7Vmlld0VuY2Fwc3VsYXRpb259IGZyb20gJy4uL21ldGFkYXRhJztcbmltcG9ydCB7Y29sbGVjdE5hdGl2ZU5vZGVzfSBmcm9tICcuLi9yZW5kZXIzL2NvbGxlY3RfbmF0aXZlX25vZGVzJztcbmltcG9ydCB7Z2V0Q29tcG9uZW50RGVmfSBmcm9tICcuLi9yZW5kZXIzL2RlZmluaXRpb24nO1xuaW1wb3J0IHtDT05UQUlORVJfSEVBREVSX09GRlNFVCwgTENvbnRhaW5lcn0gZnJvbSAnLi4vcmVuZGVyMy9pbnRlcmZhY2VzL2NvbnRhaW5lcic7XG5pbXBvcnQge1ROb2RlLCBUTm9kZVR5cGV9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7UkVsZW1lbnR9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy9yZW5kZXJlcl9kb20nO1xuaW1wb3J0IHtpc0NvbXBvbmVudEhvc3QsIGlzTENvbnRhaW5lciwgaXNQcm9qZWN0aW9uVE5vZGUsIGlzUm9vdFZpZXd9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy90eXBlX2NoZWNrcyc7XG5pbXBvcnQge0NPTlRFWFQsIEZMQUdTLCBIRUFERVJfT0ZGU0VULCBIT1NULCBMVmlldywgTFZpZXdGbGFncywgUkVOREVSRVIsIFRWaWV3LCBUVklFVywgVFZpZXdUeXBlfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvdmlldyc7XG5pbXBvcnQge3Vud3JhcFJOb2RlfSBmcm9tICcuLi9yZW5kZXIzL3V0aWwvdmlld191dGlscyc7XG5pbXBvcnQge1RyYW5zZmVyU3RhdGV9IGZyb20gJy4uL3RyYW5zZmVyX3N0YXRlJztcblxuaW1wb3J0IHt1bnN1cHBvcnRlZFByb2plY3Rpb25PZkRvbU5vZGVzfSBmcm9tICcuL2Vycm9yX2hhbmRsaW5nJztcbmltcG9ydCB7Q09OVEFJTkVSUywgRElTQ09OTkVDVEVEX05PREVTLCBFTEVNRU5UX0NPTlRBSU5FUlMsIE1VTFRJUExJRVIsIE5PREVTLCBOVU1fUk9PVF9OT0RFUywgU2VyaWFsaXplZENvbnRhaW5lclZpZXcsIFNlcmlhbGl6ZWRWaWV3LCBURU1QTEFURV9JRCwgVEVNUExBVEVTfSBmcm9tICcuL2ludGVyZmFjZXMnO1xuaW1wb3J0IHtjYWxjUGF0aEZvck5vZGV9IGZyb20gJy4vbm9kZV9sb29rdXBfdXRpbHMnO1xuaW1wb3J0IHtpc0luU2tpcEh5ZHJhdGlvbkJsb2NrLCBTS0lQX0hZRFJBVElPTl9BVFRSX05BTUV9IGZyb20gJy4vc2tpcF9oeWRyYXRpb24nO1xuaW1wb3J0IHtnZXRDb21wb25lbnRMVmlld0Zvckh5ZHJhdGlvbiwgTkdIX0FUVFJfTkFNRSwgTkdIX0RBVEFfS0VZLCBUZXh0Tm9kZU1hcmtlcn0gZnJvbSAnLi91dGlscyc7XG5cbi8qKlxuICogQSBjb2xsZWN0aW9uIHRoYXQgdHJhY2tzIGFsbCBzZXJpYWxpemVkIHZpZXdzIChgbmdoYCBET00gYW5ub3RhdGlvbnMpXG4gKiB0byBhdm9pZCBkdXBsaWNhdGlvbi4gQW4gYXR0ZW1wdCB0byBhZGQgYSBkdXBsaWNhdGUgdmlldyByZXN1bHRzIGluIHRoZVxuICogY29sbGVjdGlvbiByZXR1cm5pbmcgdGhlIGluZGV4IG9mIHRoZSBwcmV2aW91c2x5IGNvbGxlY3RlZCBzZXJpYWxpemVkIHZpZXcuXG4gKiBUaGlzIHJlZHVjZXMgdGhlIG51bWJlciBvZiBhbm5vdGF0aW9ucyBuZWVkZWQgZm9yIGEgZ2l2ZW4gcGFnZS5cbiAqL1xuY2xhc3MgU2VyaWFsaXplZFZpZXdDb2xsZWN0aW9uIHtcbiAgcHJpdmF0ZSB2aWV3czogU2VyaWFsaXplZFZpZXdbXSA9IFtdO1xuICBwcml2YXRlIGluZGV4QnlDb250ZW50ID0gbmV3IE1hcDxzdHJpbmcsIG51bWJlcj4oKTtcblxuICBhZGQoc2VyaWFsaXplZFZpZXc6IFNlcmlhbGl6ZWRWaWV3KTogbnVtYmVyIHtcbiAgICBjb25zdCB2aWV3QXNTdHJpbmcgPSBKU09OLnN0cmluZ2lmeShzZXJpYWxpemVkVmlldyk7XG4gICAgaWYgKCF0aGlzLmluZGV4QnlDb250ZW50Lmhhcyh2aWV3QXNTdHJpbmcpKSB7XG4gICAgICBjb25zdCBpbmRleCA9IHRoaXMudmlld3MubGVuZ3RoO1xuICAgICAgdGhpcy52aWV3cy5wdXNoKHNlcmlhbGl6ZWRWaWV3KTtcbiAgICAgIHRoaXMuaW5kZXhCeUNvbnRlbnQuc2V0KHZpZXdBc1N0cmluZywgaW5kZXgpO1xuICAgICAgcmV0dXJuIGluZGV4O1xuICAgIH1cbiAgICByZXR1cm4gdGhpcy5pbmRleEJ5Q29udGVudC5nZXQodmlld0FzU3RyaW5nKSE7XG4gIH1cblxuICBnZXRBbGwoKTogU2VyaWFsaXplZFZpZXdbXSB7XG4gICAgcmV0dXJuIHRoaXMudmlld3M7XG4gIH1cbn1cblxuLyoqXG4gKiBHbG9iYWwgY291bnRlciB0aGF0IGlzIHVzZWQgdG8gZ2VuZXJhdGUgYSB1bmlxdWUgaWQgZm9yIFRWaWV3c1xuICogZHVyaW5nIHRoZSBzZXJpYWxpemF0aW9uIHByb2Nlc3MuXG4gKi9cbmxldCB0Vmlld1NzcklkID0gMDtcblxuLyoqXG4gKiBHZW5lcmF0ZXMgYSB1bmlxdWUgaWQgZm9yIGEgZ2l2ZW4gVFZpZXcgYW5kIHJldHVybnMgdGhpcyBpZC5cbiAqIFRoZSBpZCBpcyBhbHNvIHN0b3JlZCBvbiB0aGlzIGluc3RhbmNlIG9mIGEgVFZpZXcgYW5kIHJldXNlZCBpblxuICogc3Vic2VxdWVudCBjYWxscy5cbiAqXG4gKiBUaGlzIGlkIGlzIG5lZWRlZCB0byB1bmlxdWVseSBpZGVudGlmeSBhbmQgcGljayB1cCBkZWh5ZHJhdGVkIHZpZXdzXG4gKiBhdCBydW50aW1lLlxuICovXG5mdW5jdGlvbiBnZXRTc3JJZCh0VmlldzogVFZpZXcpOiBzdHJpbmcge1xuICBpZiAoIXRWaWV3LnNzcklkKSB7XG4gICAgdFZpZXcuc3NySWQgPSBgdCR7dFZpZXdTc3JJZCsrfWA7XG4gIH1cbiAgcmV0dXJuIHRWaWV3LnNzcklkO1xufVxuXG4vKipcbiAqIERlc2NyaWJlcyBhIGNvbnRleHQgYXZhaWxhYmxlIGR1cmluZyB0aGUgc2VyaWFsaXphdGlvblxuICogcHJvY2Vzcy4gVGhlIGNvbnRleHQgaXMgdXNlZCB0byBzaGFyZSBhbmQgY29sbGVjdCBpbmZvcm1hdGlvblxuICogZHVyaW5nIHRoZSBzZXJpYWxpemF0aW9uLlxuICovXG5pbnRlcmZhY2UgSHlkcmF0aW9uQ29udGV4dCB7XG4gIHNlcmlhbGl6ZWRWaWV3Q29sbGVjdGlvbjogU2VyaWFsaXplZFZpZXdDb2xsZWN0aW9uO1xuICBjb3JydXB0ZWRUZXh0Tm9kZXM6IE1hcDxIVE1MRWxlbWVudCwgVGV4dE5vZGVNYXJrZXI+O1xufVxuXG4vKipcbiAqIENvbXB1dGVzIHRoZSBudW1iZXIgb2Ygcm9vdCBub2RlcyBpbiBhIGdpdmVuIHZpZXdcbiAqIChvciBjaGlsZCBub2RlcyBpbiBhIGdpdmVuIGNvbnRhaW5lciBpZiBhIHROb2RlIGlzIHByb3ZpZGVkKS5cbiAqL1xuZnVuY3Rpb24gY2FsY051bVJvb3ROb2Rlcyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgdE5vZGU6IFROb2RlfG51bGwpOiBudW1iZXIge1xuICBjb25zdCByb290Tm9kZXM6IHVua25vd25bXSA9IFtdO1xuICBjb2xsZWN0TmF0aXZlTm9kZXModFZpZXcsIGxWaWV3LCB0Tm9kZSwgcm9vdE5vZGVzKTtcbiAgcmV0dXJuIHJvb3ROb2Rlcy5sZW5ndGg7XG59XG5cbi8qKlxuICogQW5ub3RhdGVzIGFsbCBjb21wb25lbnRzIGJvb3RzdHJhcHBlZCBpbiBhIGdpdmVuIEFwcGxpY2F0aW9uUmVmXG4gKiB3aXRoIGluZm8gbmVlZGVkIGZvciBoeWRyYXRpb24uXG4gKlxuICogQHBhcmFtIGFwcFJlZiBBbiBpbnN0YW5jZSBvZiBhbiBBcHBsaWNhdGlvblJlZi5cbiAqIEBwYXJhbSBkb2MgQSByZWZlcmVuY2UgdG8gdGhlIGN1cnJlbnQgRG9jdW1lbnQgaW5zdGFuY2UuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhbm5vdGF0ZUZvckh5ZHJhdGlvbihhcHBSZWY6IEFwcGxpY2F0aW9uUmVmLCBkb2M6IERvY3VtZW50KSB7XG4gIGNvbnN0IHNlcmlhbGl6ZWRWaWV3Q29sbGVjdGlvbiA9IG5ldyBTZXJpYWxpemVkVmlld0NvbGxlY3Rpb24oKTtcbiAgY29uc3QgY29ycnVwdGVkVGV4dE5vZGVzID0gbmV3IE1hcDxIVE1MRWxlbWVudCwgVGV4dE5vZGVNYXJrZXI+KCk7XG4gIGNvbnN0IHZpZXdSZWZzID0gYXBwUmVmLl92aWV3cztcbiAgZm9yIChjb25zdCB2aWV3UmVmIG9mIHZpZXdSZWZzKSB7XG4gICAgY29uc3QgbFZpZXcgPSBnZXRDb21wb25lbnRMVmlld0Zvckh5ZHJhdGlvbih2aWV3UmVmKTtcbiAgICAvLyBBbiBgbFZpZXdgIG1pZ2h0IGJlIGBudWxsYCBpZiBhIGBWaWV3UmVmYCByZXByZXNlbnRzXG4gICAgLy8gYW4gZW1iZWRkZWQgdmlldyAobm90IGEgY29tcG9uZW50IHZpZXcpLlxuICAgIGlmIChsVmlldyAhPT0gbnVsbCkge1xuICAgICAgY29uc3QgaG9zdEVsZW1lbnQgPSBsVmlld1tIT1NUXTtcbiAgICAgIC8vIFJvb3QgZWxlbWVudHMgbWlnaHQgYWxzbyBiZSBhbm5vdGF0ZWQgd2l0aCB0aGUgYG5nU2tpcEh5ZHJhdGlvbmAgYXR0cmlidXRlLFxuICAgICAgLy8gY2hlY2sgaWYgaXQncyBwcmVzZW50IGJlZm9yZSBzdGFydGluZyB0aGUgc2VyaWFsaXphdGlvbiBwcm9jZXNzLlxuICAgICAgaWYgKGhvc3RFbGVtZW50ICYmICEoaG9zdEVsZW1lbnQgYXMgSFRNTEVsZW1lbnQpLmhhc0F0dHJpYnV0ZShTS0lQX0hZRFJBVElPTl9BVFRSX05BTUUpKSB7XG4gICAgICAgIGNvbnN0IGNvbnRleHQ6IEh5ZHJhdGlvbkNvbnRleHQgPSB7XG4gICAgICAgICAgc2VyaWFsaXplZFZpZXdDb2xsZWN0aW9uLFxuICAgICAgICAgIGNvcnJ1cHRlZFRleHROb2RlcyxcbiAgICAgICAgfTtcbiAgICAgICAgYW5ub3RhdGVIb3N0RWxlbWVudEZvckh5ZHJhdGlvbihob3N0RWxlbWVudCBhcyBIVE1MRWxlbWVudCwgbFZpZXcsIGNvbnRleHQpO1xuICAgICAgICBpbnNlcnRDb3JydXB0ZWRUZXh0Tm9kZU1hcmtlcnMoY29ycnVwdGVkVGV4dE5vZGVzLCBkb2MpO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIC8vIE5vdGU6IHdlICphbHdheXMqIGluY2x1ZGUgaHlkcmF0aW9uIGluZm8ga2V5IGFuZCBhIGNvcnJlc3BvbmRpbmcgdmFsdWVcbiAgLy8gaW50byB0aGUgVHJhbnNmZXJTdGF0ZSwgZXZlbiBpZiB0aGUgbGlzdCBvZiBzZXJpYWxpemVkIHZpZXdzIGlzIGVtcHR5LlxuICAvLyBUaGlzIGlzIG5lZWRlZCBhcyBhIHNpZ25hbCB0byB0aGUgY2xpZW50IHRoYXQgdGhlIHNlcnZlciBwYXJ0IG9mIHRoZVxuICAvLyBoeWRyYXRpb24gbG9naWMgd2FzIHNldHVwIGFuZCBlbmFibGVkIGNvcnJlY3RseS4gT3RoZXJ3aXNlLCBpZiBhIGNsaWVudFxuICAvLyBoeWRyYXRpb24gZG9lc24ndCBmaW5kIGEga2V5IGluIHRoZSB0cmFuc2ZlciBzdGF0ZSAtIGFuIGVycm9yIGlzIHByb2R1Y2VkLlxuICBjb25zdCBzZXJpYWxpemVkVmlld3MgPSBzZXJpYWxpemVkVmlld0NvbGxlY3Rpb24uZ2V0QWxsKCk7XG4gIGNvbnN0IHRyYW5zZmVyU3RhdGUgPSBhcHBSZWYuaW5qZWN0b3IuZ2V0KFRyYW5zZmVyU3RhdGUpO1xuICB0cmFuc2ZlclN0YXRlLnNldChOR0hfREFUQV9LRVksIHNlcmlhbGl6ZWRWaWV3cyk7XG59XG5cbi8qKlxuICogU2VyaWFsaXplcyB0aGUgbENvbnRhaW5lciBkYXRhIGludG8gYSBsaXN0IG9mIFNlcmlhbGl6ZWRWaWV3IG9iamVjdHMsXG4gKiB0aGF0IHJlcHJlc2VudCB2aWV3cyB3aXRoaW4gdGhpcyBsQ29udGFpbmVyLlxuICpcbiAqIEBwYXJhbSBsQ29udGFpbmVyIHRoZSBsQ29udGFpbmVyIHdlIGFyZSBzZXJpYWxpemluZ1xuICogQHBhcmFtIGNvbnRleHQgdGhlIGh5ZHJhdGlvbiBjb250ZXh0XG4gKiBAcmV0dXJucyBhbiBhcnJheSBvZiB0aGUgYFNlcmlhbGl6ZWRWaWV3YCBvYmplY3RzXG4gKi9cbmZ1bmN0aW9uIHNlcmlhbGl6ZUxDb250YWluZXIoXG4gICAgbENvbnRhaW5lcjogTENvbnRhaW5lciwgY29udGV4dDogSHlkcmF0aW9uQ29udGV4dCk6IFNlcmlhbGl6ZWRDb250YWluZXJWaWV3W10ge1xuICBjb25zdCB2aWV3czogU2VyaWFsaXplZENvbnRhaW5lclZpZXdbXSA9IFtdO1xuICBsZXQgbGFzdFZpZXdBc1N0cmluZzogc3RyaW5nID0gJyc7XG5cbiAgZm9yIChsZXQgaSA9IENPTlRBSU5FUl9IRUFERVJfT0ZGU0VUOyBpIDwgbENvbnRhaW5lci5sZW5ndGg7IGkrKykge1xuICAgIGxldCBjaGlsZExWaWV3ID0gbENvbnRhaW5lcltpXSBhcyBMVmlldztcblxuICAgIC8vIElmIHRoaXMgaXMgYSByb290IHZpZXcsIGdldCBhbiBMVmlldyBmb3IgdGhlIHVuZGVybHlpbmcgY29tcG9uZW50LFxuICAgIC8vIGJlY2F1c2UgaXQgY29udGFpbnMgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHZpZXcgdG8gc2VyaWFsaXplLlxuICAgIGlmIChpc1Jvb3RWaWV3KGNoaWxkTFZpZXcpKSB7XG4gICAgICBjaGlsZExWaWV3ID0gY2hpbGRMVmlld1tIRUFERVJfT0ZGU0VUXTtcbiAgICB9XG4gICAgY29uc3QgY2hpbGRUVmlldyA9IGNoaWxkTFZpZXdbVFZJRVddO1xuXG4gICAgbGV0IHRlbXBsYXRlOiBzdHJpbmc7XG4gICAgbGV0IG51bVJvb3ROb2RlcyA9IDA7XG4gICAgaWYgKGNoaWxkVFZpZXcudHlwZSA9PT0gVFZpZXdUeXBlLkNvbXBvbmVudCkge1xuICAgICAgdGVtcGxhdGUgPSBjaGlsZFRWaWV3LnNzcklkITtcblxuICAgICAgLy8gVGhpcyBpcyBhIGNvbXBvbmVudCB2aWV3LCB0aHVzIGl0IGhhcyBvbmx5IDEgcm9vdCBub2RlOiB0aGUgY29tcG9uZW50XG4gICAgICAvLyBob3N0IG5vZGUgaXRzZWxmIChvdGhlciBub2RlcyB3b3VsZCBiZSBpbnNpZGUgdGhhdCBob3N0IG5vZGUpLlxuICAgICAgbnVtUm9vdE5vZGVzID0gMTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGVtcGxhdGUgPSBnZXRTc3JJZChjaGlsZFRWaWV3KTtcbiAgICAgIG51bVJvb3ROb2RlcyA9IGNhbGNOdW1Sb290Tm9kZXMoY2hpbGRUVmlldywgY2hpbGRMVmlldywgY2hpbGRUVmlldy5maXJzdENoaWxkKTtcbiAgICB9XG5cbiAgICBjb25zdCB2aWV3OiBTZXJpYWxpemVkQ29udGFpbmVyVmlldyA9IHtcbiAgICAgIFtURU1QTEFURV9JRF06IHRlbXBsYXRlLFxuICAgICAgW05VTV9ST09UX05PREVTXTogbnVtUm9vdE5vZGVzLFxuICAgICAgLi4uc2VyaWFsaXplTFZpZXcobENvbnRhaW5lcltpXSBhcyBMVmlldywgY29udGV4dCksXG4gICAgfTtcblxuICAgIC8vIENoZWNrIGlmIHRoZSBwcmV2aW91cyB2aWV3IGhhcyB0aGUgc2FtZSBzaGFwZSAoZm9yIGV4YW1wbGUsIGl0IHdhc1xuICAgIC8vIHByb2R1Y2VkIGJ5IHRoZSAqbmdGb3IpLCBpbiB3aGljaCBjYXNlIGJ1bXAgdGhlIGNvdW50ZXIgb24gdGhlIHByZXZpb3VzXG4gICAgLy8gdmlldyBpbnN0ZWFkIG9mIGluY2x1ZGluZyB0aGUgc2FtZSBpbmZvcm1hdGlvbiBhZ2Fpbi5cbiAgICBjb25zdCBjdXJyZW50Vmlld0FzU3RyaW5nID0gSlNPTi5zdHJpbmdpZnkodmlldyk7XG4gICAgaWYgKHZpZXdzLmxlbmd0aCA+IDAgJiYgY3VycmVudFZpZXdBc1N0cmluZyA9PT0gbGFzdFZpZXdBc1N0cmluZykge1xuICAgICAgY29uc3QgcHJldmlvdXNWaWV3ID0gdmlld3Nbdmlld3MubGVuZ3RoIC0gMV07XG4gICAgICBwcmV2aW91c1ZpZXdbTVVMVElQTElFUl0gPz89IDE7XG4gICAgICBwcmV2aW91c1ZpZXdbTVVMVElQTElFUl0rKztcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gUmVjb3JkIHRoaXMgdmlldyBhcyBtb3N0IHJlY2VudGx5IGFkZGVkLlxuICAgICAgbGFzdFZpZXdBc1N0cmluZyA9IGN1cnJlbnRWaWV3QXNTdHJpbmc7XG4gICAgICB2aWV3cy5wdXNoKHZpZXcpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gdmlld3M7XG59XG5cbi8qKlxuICogSGVscGVyIGZ1bmN0aW9uIHRvIHByb2R1Y2UgYSBub2RlIHBhdGggKHdoaWNoIG5hdmlnYXRpb24gc3RlcHMgcnVudGltZSBsb2dpY1xuICogbmVlZHMgdG8gdGFrZSB0byBsb2NhdGUgYSBub2RlKSBhbmQgc3RvcmVzIGl0IGluIHRoZSBgTk9ERVNgIHNlY3Rpb24gb2YgdGhlXG4gKiBjdXJyZW50IHNlcmlhbGl6ZWQgdmlldy5cbiAqL1xuZnVuY3Rpb24gYXBwZW5kU2VyaWFsaXplZE5vZGVQYXRoKG5naDogU2VyaWFsaXplZFZpZXcsIHROb2RlOiBUTm9kZSwgbFZpZXc6IExWaWV3KSB7XG4gIGNvbnN0IG5vT2Zmc2V0SW5kZXggPSB0Tm9kZS5pbmRleCAtIEhFQURFUl9PRkZTRVQ7XG4gIG5naFtOT0RFU10gPz89IHt9O1xuICBuZ2hbTk9ERVNdW25vT2Zmc2V0SW5kZXhdID0gY2FsY1BhdGhGb3JOb2RlKHROb2RlLCBsVmlldyk7XG59XG5cbi8qKlxuICogSGVscGVyIGZ1bmN0aW9uIHRvIGFwcGVuZCBpbmZvcm1hdGlvbiBhYm91dCBhIGRpc2Nvbm5lY3RlZCBub2RlLlxuICogVGhpcyBpbmZvIGlzIG5lZWRlZCBhdCBydW50aW1lIHRvIGF2b2lkIERPTSBsb29rdXBzIGZvciB0aGlzIGVsZW1lbnRcbiAqIGFuZCBpbnN0ZWFkLCB0aGUgZWxlbWVudCB3b3VsZCBiZSBjcmVhdGVkIGZyb20gc2NyYXRjaC5cbiAqL1xuZnVuY3Rpb24gYXBwZW5kRGlzY29ubmVjdGVkTm9kZUluZGV4KG5naDogU2VyaWFsaXplZFZpZXcsIHROb2RlOiBUTm9kZSkge1xuICBjb25zdCBub09mZnNldEluZGV4ID0gdE5vZGUuaW5kZXggLSBIRUFERVJfT0ZGU0VUO1xuICBuZ2hbRElTQ09OTkVDVEVEX05PREVTXSA/Pz0gW107XG4gIGlmICghbmdoW0RJU0NPTk5FQ1RFRF9OT0RFU10uaW5jbHVkZXMobm9PZmZzZXRJbmRleCkpIHtcbiAgICBuZ2hbRElTQ09OTkVDVEVEX05PREVTXS5wdXNoKG5vT2Zmc2V0SW5kZXgpO1xuICB9XG59XG5cbi8qKlxuICogU2VyaWFsaXplcyB0aGUgbFZpZXcgZGF0YSBpbnRvIGEgU2VyaWFsaXplZFZpZXcgb2JqZWN0IHRoYXQgd2lsbCBsYXRlciBiZSBhZGRlZFxuICogdG8gdGhlIFRyYW5zZmVyU3RhdGUgc3RvcmFnZSBhbmQgcmVmZXJlbmNlZCB1c2luZyB0aGUgYG5naGAgYXR0cmlidXRlIG9uIGEgaG9zdFxuICogZWxlbWVudC5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgdGhlIGxWaWV3IHdlIGFyZSBzZXJpYWxpemluZ1xuICogQHBhcmFtIGNvbnRleHQgdGhlIGh5ZHJhdGlvbiBjb250ZXh0XG4gKiBAcmV0dXJucyB0aGUgYFNlcmlhbGl6ZWRWaWV3YCBvYmplY3QgY29udGFpbmluZyB0aGUgZGF0YSB0byBiZSBhZGRlZCB0byB0aGUgaG9zdCBub2RlXG4gKi9cbmZ1bmN0aW9uIHNlcmlhbGl6ZUxWaWV3KGxWaWV3OiBMVmlldywgY29udGV4dDogSHlkcmF0aW9uQ29udGV4dCk6IFNlcmlhbGl6ZWRWaWV3IHtcbiAgY29uc3QgbmdoOiBTZXJpYWxpemVkVmlldyA9IHt9O1xuICBjb25zdCB0VmlldyA9IGxWaWV3W1RWSUVXXTtcbiAgLy8gSXRlcmF0ZSBvdmVyIERPTSBlbGVtZW50IHJlZmVyZW5jZXMgaW4gYW4gTFZpZXcuXG4gIGZvciAobGV0IGkgPSBIRUFERVJfT0ZGU0VUOyBpIDwgdFZpZXcuYmluZGluZ1N0YXJ0SW5kZXg7IGkrKykge1xuICAgIGNvbnN0IHROb2RlID0gdFZpZXcuZGF0YVtpXSBhcyBUTm9kZTtcbiAgICBjb25zdCBub09mZnNldEluZGV4ID0gaSAtIEhFQURFUl9PRkZTRVQ7XG4gICAgLy8gTG9jYWwgcmVmcyAoZS5nLiA8ZGl2ICNsb2NhbFJlZj4pIHRha2UgdXAgYW4gZXh0cmEgc2xvdCBpbiBMVmlld3NcbiAgICAvLyB0byBzdG9yZSB0aGUgc2FtZSBlbGVtZW50LiBJbiB0aGlzIGNhc2UsIHRoZXJlIGlzIG5vIGluZm9ybWF0aW9uIGluXG4gICAgLy8gYSBjb3JyZXNwb25kaW5nIHNsb3QgaW4gVE5vZGUgZGF0YSBzdHJ1Y3R1cmUuIElmIHRoYXQncyB0aGUgY2FzZSwganVzdFxuICAgIC8vIHNraXAgdGhpcyBzbG90IGFuZCBtb3ZlIHRvIHRoZSBuZXh0IG9uZS5cbiAgICBpZiAoIXROb2RlKSB7XG4gICAgICBjb250aW51ZTtcbiAgICB9XG5cbiAgICAvLyBDaGVjayBpZiBhIG5hdGl2ZSBub2RlIHRoYXQgcmVwcmVzZW50cyBhIGdpdmVuIFROb2RlIGlzIGRpc2Nvbm5lY3RlZCBmcm9tIHRoZSBET00gdHJlZS5cbiAgICAvLyBTdWNoIG5vZGVzIG11c3QgYmUgZXhjbHVkZWQgZnJvbSB0aGUgaHlkcmF0aW9uIChzaW5jZSB0aGUgaHlkcmF0aW9uIHdvbid0IGJlIGFibGUgdG9cbiAgICAvLyBmaW5kIHRoZW0pLCBzbyB0aGUgVE5vZGUgaWRzIGFyZSBjb2xsZWN0ZWQgYW5kIHVzZWQgYXQgcnVudGltZSB0byBza2lwIHRoZSBoeWRyYXRpb24uXG4gICAgLy9cbiAgICAvLyBUaGlzIHNpdHVhdGlvbiBtYXkgaGFwcGVuIGR1cmluZyB0aGUgY29udGVudCBwcm9qZWN0aW9uLCB3aGVuIHNvbWUgbm9kZXMgZG9uJ3QgbWFrZSBpdFxuICAgIC8vIGludG8gb25lIG9mIHRoZSBjb250ZW50IHByb2plY3Rpb24gc2xvdHMgKGZvciBleGFtcGxlLCB3aGVuIHRoZXJlIGlzIG5vIGRlZmF1bHRcbiAgICAvLyA8bmctY29udGVudCAvPiBzbG90IGluIHByb2plY3RvciBjb21wb25lbnQncyB0ZW1wbGF0ZSkuXG4gICAgaWYgKGlzRGlzY29ubmVjdGVkTm9kZSh0Tm9kZSwgbFZpZXcpICYmIGlzQ29udGVudFByb2plY3RlZE5vZGUodE5vZGUpKSB7XG4gICAgICBhcHBlbmREaXNjb25uZWN0ZWROb2RlSW5kZXgobmdoLCB0Tm9kZSk7XG4gICAgICBjb250aW51ZTtcbiAgICB9XG4gICAgaWYgKEFycmF5LmlzQXJyYXkodE5vZGUucHJvamVjdGlvbikpIHtcbiAgICAgIGZvciAoY29uc3QgcHJvamVjdGlvbkhlYWRUTm9kZSBvZiB0Tm9kZS5wcm9qZWN0aW9uKSB7XG4gICAgICAgIC8vIFdlIG1heSBoYXZlIGBudWxsYHMgaW4gc2xvdHMgd2l0aCBubyBwcm9qZWN0ZWQgY29udGVudC5cbiAgICAgICAgaWYgKCFwcm9qZWN0aW9uSGVhZFROb2RlKSBjb250aW51ZTtcblxuICAgICAgICBpZiAoIUFycmF5LmlzQXJyYXkocHJvamVjdGlvbkhlYWRUTm9kZSkpIHtcbiAgICAgICAgICAvLyBJZiB3ZSBwcm9jZXNzIHJlLXByb2plY3RlZCBjb250ZW50IChpLmUuIGA8bmctY29udGVudD5gXG4gICAgICAgICAgLy8gYXBwZWFycyBhdCBwcm9qZWN0aW9uIGxvY2F0aW9uKSwgc2tpcCBhbm5vdGF0aW9ucyBmb3IgdGhpcyBjb250ZW50XG4gICAgICAgICAgLy8gc2luY2UgYWxsIERPTSBub2RlcyBpbiB0aGlzIHByb2plY3Rpb24gd2VyZSBoYW5kbGVkIHdoaWxlIHByb2Nlc3NpbmdcbiAgICAgICAgICAvLyBhIHBhcmVudCBsVmlldywgd2hpY2ggY29udGFpbnMgdGhvc2Ugbm9kZXMuXG4gICAgICAgICAgaWYgKCFpc1Byb2plY3Rpb25UTm9kZShwcm9qZWN0aW9uSGVhZFROb2RlKSAmJlxuICAgICAgICAgICAgICAhaXNJblNraXBIeWRyYXRpb25CbG9jayhwcm9qZWN0aW9uSGVhZFROb2RlKSkge1xuICAgICAgICAgICAgaWYgKGlzRGlzY29ubmVjdGVkTm9kZShwcm9qZWN0aW9uSGVhZFROb2RlLCBsVmlldykpIHtcbiAgICAgICAgICAgICAgLy8gQ2hlY2sgd2hldGhlciB0aGlzIG5vZGUgaXMgY29ubmVjdGVkLCBzaW5jZSB3ZSBtYXkgaGF2ZSBhIFROb2RlXG4gICAgICAgICAgICAgIC8vIGluIHRoZSBkYXRhIHN0cnVjdHVyZSBhcyBhIHByb2plY3Rpb24gc2VnbWVudCBoZWFkLCBidXQgdGhlXG4gICAgICAgICAgICAgIC8vIGNvbnRlbnQgcHJvamVjdGlvbiBzbG90IG1pZ2h0IGJlIGRpc2FibGVkIChlLmcuXG4gICAgICAgICAgICAgIC8vIDxuZy1jb250ZW50ICpuZ0lmPVwiZmFsc2VcIiAvPikuXG4gICAgICAgICAgICAgIGFwcGVuZERpc2Nvbm5lY3RlZE5vZGVJbmRleChuZ2gsIHByb2plY3Rpb25IZWFkVE5vZGUpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgYXBwZW5kU2VyaWFsaXplZE5vZGVQYXRoKG5naCwgcHJvamVjdGlvbkhlYWRUTm9kZSwgbFZpZXcpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAvLyBJZiBhIHZhbHVlIGlzIGFuIGFycmF5LCBpdCBtZWFucyB0aGF0IHdlIGFyZSBwcm9jZXNzaW5nIGEgcHJvamVjdGlvblxuICAgICAgICAgIC8vIHdoZXJlIHByb2plY3RhYmxlIG5vZGVzIHdlcmUgcGFzc2VkIGluIGFzIERPTSBub2RlcyAoZm9yIGV4YW1wbGUsIHdoZW5cbiAgICAgICAgICAvLyBjYWxsaW5nIGBWaWV3Q29udGFpbmVyUmVmLmNyZWF0ZUNvbXBvbmVudChDbXBBLCB7cHJvamVjdGFibGVOb2RlczogWy4uLl19KWApLlxuICAgICAgICAgIC8vXG4gICAgICAgICAgLy8gSW4gdGhpcyBzY2VuYXJpbywgbm9kZXMgY2FuIGNvbWUgZnJvbSBhbnl3aGVyZSAoZWl0aGVyIGNyZWF0ZWQgbWFudWFsbHksXG4gICAgICAgICAgLy8gYWNjZXNzZWQgdmlhIGBkb2N1bWVudC5xdWVyeVNlbGVjdG9yYCwgZXRjKSBhbmQgbWF5IGJlIGluIGFueSBzdGF0ZVxuICAgICAgICAgIC8vIChhdHRhY2hlZCBvciBkZXRhY2hlZCBmcm9tIHRoZSBET00gdHJlZSkuIEFzIGEgcmVzdWx0LCB3ZSBjYW4gbm90IHJlbGlhYmx5XG4gICAgICAgICAgLy8gcmVzdG9yZSB0aGUgc3RhdGUgZm9yIHN1Y2ggY2FzZXMgZHVyaW5nIGh5ZHJhdGlvbi5cblxuICAgICAgICAgIHRocm93IHVuc3VwcG9ydGVkUHJvamVjdGlvbk9mRG9tTm9kZXModW53cmFwUk5vZGUobFZpZXdbaV0pKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICBpZiAoaXNMQ29udGFpbmVyKGxWaWV3W2ldKSkge1xuICAgICAgLy8gU2VyaWFsaXplIGluZm9ybWF0aW9uIGFib3V0IGEgdGVtcGxhdGUuXG4gICAgICBjb25zdCBlbWJlZGRlZFRWaWV3ID0gdE5vZGUudFZpZXc7XG4gICAgICBpZiAoZW1iZWRkZWRUVmlldyAhPT0gbnVsbCkge1xuICAgICAgICBuZ2hbVEVNUExBVEVTXSA/Pz0ge307XG4gICAgICAgIG5naFtURU1QTEFURVNdW25vT2Zmc2V0SW5kZXhdID0gZ2V0U3NySWQoZW1iZWRkZWRUVmlldyk7XG4gICAgICB9XG5cbiAgICAgIC8vIFNlcmlhbGl6ZSB2aWV3cyB3aXRoaW4gdGhpcyBMQ29udGFpbmVyLlxuICAgICAgY29uc3QgaG9zdE5vZGUgPSBsVmlld1tpXVtIT1NUXSE7ICAvLyBob3N0IG5vZGUgb2YgdGhpcyBjb250YWluZXJcblxuICAgICAgLy8gTFZpZXdbaV1bSE9TVF0gY2FuIGJlIG9mIDIgZGlmZmVyZW50IHR5cGVzOlxuICAgICAgLy8gLSBlaXRoZXIgYSBET00gbm9kZVxuICAgICAgLy8gLSBvciBhbiBhcnJheSB0aGF0IHJlcHJlc2VudHMgYW4gTFZpZXcgb2YgYSBjb21wb25lbnRcbiAgICAgIGlmIChBcnJheS5pc0FycmF5KGhvc3ROb2RlKSkge1xuICAgICAgICAvLyBUaGlzIGlzIGEgY29tcG9uZW50LCBzZXJpYWxpemUgaW5mbyBhYm91dCBpdC5cbiAgICAgICAgY29uc3QgdGFyZ2V0Tm9kZSA9IHVud3JhcFJOb2RlKGhvc3ROb2RlIGFzIExWaWV3KSBhcyBSRWxlbWVudDtcbiAgICAgICAgaWYgKCEodGFyZ2V0Tm9kZSBhcyBIVE1MRWxlbWVudCkuaGFzQXR0cmlidXRlKFNLSVBfSFlEUkFUSU9OX0FUVFJfTkFNRSkpIHtcbiAgICAgICAgICBhbm5vdGF0ZUhvc3RFbGVtZW50Rm9ySHlkcmF0aW9uKHRhcmdldE5vZGUsIGhvc3ROb2RlIGFzIExWaWV3LCBjb250ZXh0KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgbmdoW0NPTlRBSU5FUlNdID8/PSB7fTtcbiAgICAgIG5naFtDT05UQUlORVJTXVtub09mZnNldEluZGV4XSA9IHNlcmlhbGl6ZUxDb250YWluZXIobFZpZXdbaV0sIGNvbnRleHQpO1xuICAgIH0gZWxzZSBpZiAoQXJyYXkuaXNBcnJheShsVmlld1tpXSkpIHtcbiAgICAgIC8vIFRoaXMgaXMgYSBjb21wb25lbnQsIGFubm90YXRlIHRoZSBob3N0IG5vZGUgd2l0aCBhbiBgbmdoYCBhdHRyaWJ1dGUuXG4gICAgICBjb25zdCB0YXJnZXROb2RlID0gdW53cmFwUk5vZGUobFZpZXdbaV1bSE9TVF0hKTtcbiAgICAgIGlmICghKHRhcmdldE5vZGUgYXMgSFRNTEVsZW1lbnQpLmhhc0F0dHJpYnV0ZShTS0lQX0hZRFJBVElPTl9BVFRSX05BTUUpKSB7XG4gICAgICAgIGFubm90YXRlSG9zdEVsZW1lbnRGb3JIeWRyYXRpb24odGFyZ2V0Tm9kZSBhcyBSRWxlbWVudCwgbFZpZXdbaV0sIGNvbnRleHQpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAvLyA8bmctY29udGFpbmVyPiBjYXNlXG4gICAgICBpZiAodE5vZGUudHlwZSAmIFROb2RlVHlwZS5FbGVtZW50Q29udGFpbmVyKSB7XG4gICAgICAgIC8vIEFuIDxuZy1jb250YWluZXI+IGlzIHJlcHJlc2VudGVkIGJ5IHRoZSBudW1iZXIgb2ZcbiAgICAgICAgLy8gdG9wLWxldmVsIG5vZGVzLiBUaGlzIGluZm9ybWF0aW9uIGlzIG5lZWRlZCB0byBza2lwIG92ZXJcbiAgICAgICAgLy8gdGhvc2Ugbm9kZXMgdG8gcmVhY2ggYSBjb3JyZXNwb25kaW5nIGFuY2hvciBub2RlIChjb21tZW50IG5vZGUpLlxuICAgICAgICBuZ2hbRUxFTUVOVF9DT05UQUlORVJTXSA/Pz0ge307XG4gICAgICAgIG5naFtFTEVNRU5UX0NPTlRBSU5FUlNdW25vT2Zmc2V0SW5kZXhdID0gY2FsY051bVJvb3ROb2Rlcyh0VmlldywgbFZpZXcsIHROb2RlLmNoaWxkKTtcbiAgICAgIH0gZWxzZSBpZiAodE5vZGUudHlwZSAmIFROb2RlVHlwZS5Qcm9qZWN0aW9uKSB7XG4gICAgICAgIC8vIEN1cnJlbnQgVE5vZGUgcmVwcmVzZW50cyBhbiBgPG5nLWNvbnRlbnQ+YCBzbG90LCB0aHVzIGl0IGhhcyBub1xuICAgICAgICAvLyBET00gZWxlbWVudHMgYXNzb2NpYXRlZCB3aXRoIGl0LCBzbyB0aGUgKipuZXh0IHNpYmxpbmcqKiBub2RlIHdvdWxkXG4gICAgICAgIC8vIG5vdCBiZSBhYmxlIHRvIGZpbmQgYW4gYW5jaG9yLiBJbiB0aGlzIGNhc2UsIHVzZSBmdWxsIHBhdGggaW5zdGVhZC5cbiAgICAgICAgbGV0IG5leHRUTm9kZSA9IHROb2RlLm5leHQ7XG4gICAgICAgIC8vIFNraXAgb3ZlciBhbGwgYDxuZy1jb250ZW50PmAgc2xvdHMgaW4gYSByb3cuXG4gICAgICAgIHdoaWxlIChuZXh0VE5vZGUgIT09IG51bGwgJiYgKG5leHRUTm9kZS50eXBlICYgVE5vZGVUeXBlLlByb2plY3Rpb24pKSB7XG4gICAgICAgICAgbmV4dFROb2RlID0gbmV4dFROb2RlLm5leHQ7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKG5leHRUTm9kZSAmJiAhaXNJblNraXBIeWRyYXRpb25CbG9jayhuZXh0VE5vZGUpKSB7XG4gICAgICAgICAgLy8gSGFuZGxlIGEgdE5vZGUgYWZ0ZXIgdGhlIGA8bmctY29udGVudD5gIHNsb3QuXG4gICAgICAgICAgYXBwZW5kU2VyaWFsaXplZE5vZGVQYXRoKG5naCwgbmV4dFROb2RlLCBsVmlldyk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIEhhbmRsZSBjYXNlcyB3aGVyZSB0ZXh0IG5vZGVzIGNhbiBiZSBsb3N0IGFmdGVyIERPTSBzZXJpYWxpemF0aW9uOlxuICAgICAgICAvLyAgMS4gV2hlbiB0aGVyZSBpcyBhbiAqZW1wdHkgdGV4dCBub2RlKiBpbiBET006IGluIHRoaXMgY2FzZSwgdGhpc1xuICAgICAgICAvLyAgICAgbm9kZSB3b3VsZCBub3QgbWFrZSBpdCBpbnRvIHRoZSBzZXJpYWxpemVkIHN0cmluZyBhbmQgYXMgYSByZXN1bHQsXG4gICAgICAgIC8vICAgICB0aGlzIG5vZGUgd291bGRuJ3QgYmUgY3JlYXRlZCBpbiBhIGJyb3dzZXIuIFRoaXMgd291bGQgcmVzdWx0IGluXG4gICAgICAgIC8vICAgICBhIG1pc21hdGNoIGR1cmluZyB0aGUgaHlkcmF0aW9uLCB3aGVyZSB0aGUgcnVudGltZSBsb2dpYyB3b3VsZCBleHBlY3RcbiAgICAgICAgLy8gICAgIGEgdGV4dCBub2RlIHRvIGJlIHByZXNlbnQgaW4gbGl2ZSBET00sIGJ1dCBubyB0ZXh0IG5vZGUgd291bGQgZXhpc3QuXG4gICAgICAgIC8vICAgICBFeGFtcGxlOiBgPHNwYW4+e3sgbmFtZSB9fTwvc3Bhbj5gIHdoZW4gdGhlIGBuYW1lYCBpcyBhbiBlbXB0eSBzdHJpbmcuXG4gICAgICAgIC8vICAgICBUaGlzIHdvdWxkIHJlc3VsdCBpbiBgPHNwYW4+PC9zcGFuPmAgc3RyaW5nIGFmdGVyIHNlcmlhbGl6YXRpb24gYW5kXG4gICAgICAgIC8vICAgICBpbiBhIGJyb3dzZXIgb25seSB0aGUgYHNwYW5gIGVsZW1lbnQgd291bGQgYmUgY3JlYXRlZC4gVG8gcmVzb2x2ZSB0aGF0LFxuICAgICAgICAvLyAgICAgYW4gZXh0cmEgY29tbWVudCBub2RlIGlzIGFwcGVuZGVkIGluIHBsYWNlIG9mIGFuIGVtcHR5IHRleHQgbm9kZSBhbmRcbiAgICAgICAgLy8gICAgIHRoYXQgc3BlY2lhbCBjb21tZW50IG5vZGUgaXMgcmVwbGFjZWQgd2l0aCBhbiBlbXB0eSB0ZXh0IG5vZGUgKmJlZm9yZSpcbiAgICAgICAgLy8gICAgIGh5ZHJhdGlvbi5cbiAgICAgICAgLy8gIDIuIFdoZW4gdGhlcmUgYXJlIDIgY29uc2VjdXRpdmUgdGV4dCBub2RlcyBwcmVzZW50IGluIHRoZSBET00uXG4gICAgICAgIC8vICAgICBFeGFtcGxlOiBgPGRpdj5IZWxsbyA8bmctY29udGFpbmVyICpuZ0lmPVwidHJ1ZVwiPndvcmxkPC9uZy1jb250YWluZXI+PC9kaXY+YC5cbiAgICAgICAgLy8gICAgIEluIHRoaXMgc2NlbmFyaW8sIHRoZSBsaXZlIERPTSB3b3VsZCBsb29rIGxpa2UgdGhpczpcbiAgICAgICAgLy8gICAgICAgPGRpdj4jdGV4dCgnSGVsbG8gJykgI3RleHQoJ3dvcmxkJykgI2NvbW1lbnQoJ2NvbnRhaW5lcicpPC9kaXY+XG4gICAgICAgIC8vICAgICBTZXJpYWxpemVkIHN0cmluZyB3b3VsZCBsb29rIGxpa2UgdGhpczogYDxkaXY+SGVsbG8gd29ybGQ8IS0tY29udGFpbmVyLS0+PC9kaXY+YC5cbiAgICAgICAgLy8gICAgIFRoZSBsaXZlIERPTSBpbiBhIGJyb3dzZXIgYWZ0ZXIgdGhhdCB3b3VsZCBiZTpcbiAgICAgICAgLy8gICAgICAgPGRpdj4jdGV4dCgnSGVsbG8gd29ybGQnKSAjY29tbWVudCgnY29udGFpbmVyJyk8L2Rpdj5cbiAgICAgICAgLy8gICAgIE5vdGljZSBob3cgMiB0ZXh0IG5vZGVzIGFyZSBub3cgXCJtZXJnZWRcIiBpbnRvIG9uZS4gVGhpcyB3b3VsZCBjYXVzZSBoeWRyYXRpb25cbiAgICAgICAgLy8gICAgIGxvZ2ljIHRvIGZhaWwsIHNpbmNlIGl0J2QgZXhwZWN0IDIgdGV4dCBub2RlcyBiZWluZyBwcmVzZW50LCBub3Qgb25lLlxuICAgICAgICAvLyAgICAgVG8gZml4IHRoaXMsIHdlIGluc2VydCBhIHNwZWNpYWwgY29tbWVudCBub2RlIGluIGJldHdlZW4gdGhvc2UgdGV4dCBub2Rlcywgc29cbiAgICAgICAgLy8gICAgIHNlcmlhbGl6ZWQgcmVwcmVzZW50YXRpb24gaXM6IGA8ZGl2PkhlbGxvIDwhLS1uZ3Rucy0tPndvcmxkPCEtLWNvbnRhaW5lci0tPjwvZGl2PmAuXG4gICAgICAgIC8vICAgICBUaGlzIGZvcmNlcyBicm93c2VyIHRvIGNyZWF0ZSAyIHRleHQgbm9kZXMgc2VwYXJhdGVkIGJ5IGEgY29tbWVudCBub2RlLlxuICAgICAgICAvLyAgICAgQmVmb3JlIHJ1bm5pbmcgYSBoeWRyYXRpb24gcHJvY2VzcywgdGhpcyBzcGVjaWFsIGNvbW1lbnQgbm9kZSBpcyByZW1vdmVkLCBzbyB0aGVcbiAgICAgICAgLy8gICAgIGxpdmUgRE9NIGhhcyBleGFjdGx5IHRoZSBzYW1lIHN0YXRlIGFzIGl0IHdhcyBiZWZvcmUgc2VyaWFsaXphdGlvbi5cbiAgICAgICAgaWYgKHROb2RlLnR5cGUgJiBUTm9kZVR5cGUuVGV4dCkge1xuICAgICAgICAgIGNvbnN0IHJOb2RlID0gdW53cmFwUk5vZGUobFZpZXdbaV0pIGFzIEhUTUxFbGVtZW50O1xuICAgICAgICAgIC8vIENvbGxlY3QgdGhpcyBub2RlIGFzIHJlcXVpcmVkIHNwZWNpYWwgYW5ub3RhdGlvbiBvbmx5IHdoZW4gaXRzXG4gICAgICAgICAgLy8gY29udGVudHMgaXMgZW1wdHkuIE90aGVyd2lzZSwgc3VjaCB0ZXh0IG5vZGUgd291bGQgYmUgcHJlc2VudCBvblxuICAgICAgICAgIC8vIHRoZSBjbGllbnQgYWZ0ZXIgc2VydmVyLXNpZGUgcmVuZGVyaW5nIGFuZCBubyBzcGVjaWFsIGhhbmRsaW5nIG5lZWRlZC5cbiAgICAgICAgICBpZiAock5vZGUudGV4dENvbnRlbnQgPT09ICcnKSB7XG4gICAgICAgICAgICBjb250ZXh0LmNvcnJ1cHRlZFRleHROb2Rlcy5zZXQock5vZGUsIFRleHROb2RlTWFya2VyLkVtcHR5Tm9kZSk7XG4gICAgICAgICAgfSBlbHNlIGlmIChyTm9kZS5uZXh0U2libGluZz8ubm9kZVR5cGUgPT09IE5vZGUuVEVYVF9OT0RFKSB7XG4gICAgICAgICAgICBjb250ZXh0LmNvcnJ1cHRlZFRleHROb2Rlcy5zZXQock5vZGUsIFRleHROb2RlTWFya2VyLlNlcGFyYXRvcik7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgaWYgKHROb2RlLnByb2plY3Rpb25OZXh0ICYmIHROb2RlLnByb2plY3Rpb25OZXh0ICE9PSB0Tm9kZS5uZXh0ICYmXG4gICAgICAgICAgICAhaXNJblNraXBIeWRyYXRpb25CbG9jayh0Tm9kZS5wcm9qZWN0aW9uTmV4dCkpIHtcbiAgICAgICAgICAvLyBDaGVjayBpZiBwcm9qZWN0aW9uIG5leHQgaXMgbm90IHRoZSBzYW1lIGFzIG5leHQsIGluIHdoaWNoIGNhc2VcbiAgICAgICAgICAvLyB0aGUgbm9kZSB3b3VsZCBub3QgYmUgZm91bmQgYXQgY3JlYXRpb24gdGltZSBhdCBydW50aW1lIGFuZCB3ZVxuICAgICAgICAgIC8vIG5lZWQgdG8gcHJvdmlkZSBhIGxvY2F0aW9uIGZvciB0aGF0IG5vZGUuXG4gICAgICAgICAgYXBwZW5kU2VyaWFsaXplZE5vZGVQYXRoKG5naCwgdE5vZGUucHJvamVjdGlvbk5leHQsIGxWaWV3KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgfVxuICByZXR1cm4gbmdoO1xufVxuXG4vKipcbiAqIERldGVybWluZXMgd2hldGhlciBhIGNvbXBvbmVudCBpbnN0YW5jZSB0aGF0IGlzIHJlcHJlc2VudGVkXG4gKiBieSBhIGdpdmVuIExWaWV3IHVzZXMgYFZpZXdFbmNhcHN1bGF0aW9uLlNoYWRvd0RvbWAuXG4gKi9cbmZ1bmN0aW9uIGNvbXBvbmVudFVzZXNTaGFkb3dEb21FbmNhcHN1bGF0aW9uKGxWaWV3OiBMVmlldyk6IGJvb2xlYW4ge1xuICBjb25zdCBpbnN0YW5jZSA9IGxWaWV3W0NPTlRFWFRdO1xuICByZXR1cm4gaW5zdGFuY2U/LmNvbnN0cnVjdG9yID9cbiAgICAgIGdldENvbXBvbmVudERlZihpbnN0YW5jZS5jb25zdHJ1Y3Rvcik/LmVuY2Fwc3VsYXRpb24gPT09IFZpZXdFbmNhcHN1bGF0aW9uLlNoYWRvd0RvbSA6XG4gICAgICBmYWxzZTtcbn1cblxuLyoqXG4gKiBBbm5vdGF0ZXMgY29tcG9uZW50IGhvc3QgZWxlbWVudCBmb3IgaHlkcmF0aW9uOlxuICogLSBieSBlaXRoZXIgYWRkaW5nIHRoZSBgbmdoYCBhdHRyaWJ1dGUgYW5kIGNvbGxlY3RpbmcgaHlkcmF0aW9uLXJlbGF0ZWQgaW5mb1xuICogICBmb3IgdGhlIHNlcmlhbGl6YXRpb24gYW5kIHRyYW5zZmVycmluZyB0byB0aGUgY2xpZW50XG4gKiAtIG9yIGJ5IGFkZGluZyB0aGUgYG5nU2tpcEh5ZHJhdGlvbmAgYXR0cmlidXRlIGluIGNhc2UgQW5ndWxhciBkZXRlY3RzIHRoYXRcbiAqICAgY29tcG9uZW50IGNvbnRlbnRzIGlzIG5vdCBjb21wYXRpYmxlIHdpdGggaHlkcmF0aW9uLlxuICpcbiAqIEBwYXJhbSBlbGVtZW50IFRoZSBIb3N0IGVsZW1lbnQgdG8gYmUgYW5ub3RhdGVkXG4gKiBAcGFyYW0gbFZpZXcgVGhlIGFzc29jaWF0ZWQgTFZpZXdcbiAqIEBwYXJhbSBjb250ZXh0IFRoZSBoeWRyYXRpb24gY29udGV4dFxuICovXG5mdW5jdGlvbiBhbm5vdGF0ZUhvc3RFbGVtZW50Rm9ySHlkcmF0aW9uKFxuICAgIGVsZW1lbnQ6IFJFbGVtZW50LCBsVmlldzogTFZpZXcsIGNvbnRleHQ6IEh5ZHJhdGlvbkNvbnRleHQpOiB2b2lkIHtcbiAgY29uc3QgcmVuZGVyZXIgPSBsVmlld1tSRU5ERVJFUl07XG4gIGlmICgobFZpZXdbRkxBR1NdICYgTFZpZXdGbGFncy5IYXNJMThuKSA9PT0gTFZpZXdGbGFncy5IYXNJMThuIHx8XG4gICAgICBjb21wb25lbnRVc2VzU2hhZG93RG9tRW5jYXBzdWxhdGlvbihsVmlldykpIHtcbiAgICAvLyBBdHRhY2ggdGhlIHNraXAgaHlkcmF0aW9uIGF0dHJpYnV0ZSBpZiB0aGlzIGNvbXBvbmVudDpcbiAgICAvLyAtIGVpdGhlciBoYXMgaTE4biBibG9ja3MsIHNpbmNlIGh5ZHJhdGluZyBzdWNoIGJsb2NrcyBpcyBub3QgeWV0IHN1cHBvcnRlZFxuICAgIC8vIC0gb3IgdXNlcyBTaGFkb3dEb20gdmlldyBlbmNhcHN1bGF0aW9uLCBzaW5jZSBEb21pbm8gZG9lc24ndCBzdXBwb3J0XG4gICAgLy8gICBzaGFkb3cgRE9NLCBzbyB3ZSBjYW4gbm90IGd1YXJhbnRlZSB0aGF0IGNsaWVudCBhbmQgc2VydmVyIHJlcHJlc2VudGF0aW9uc1xuICAgIC8vICAgd291bGQgZXhhY3RseSBtYXRjaFxuICAgIHJlbmRlcmVyLnNldEF0dHJpYnV0ZShlbGVtZW50LCBTS0lQX0hZRFJBVElPTl9BVFRSX05BTUUsICcnKTtcbiAgfSBlbHNlIHtcbiAgICBjb25zdCBuZ2ggPSBzZXJpYWxpemVMVmlldyhsVmlldywgY29udGV4dCk7XG4gICAgY29uc3QgaW5kZXggPSBjb250ZXh0LnNlcmlhbGl6ZWRWaWV3Q29sbGVjdGlvbi5hZGQobmdoKTtcbiAgICByZW5kZXJlci5zZXRBdHRyaWJ1dGUoZWxlbWVudCwgTkdIX0FUVFJfTkFNRSwgaW5kZXgudG9TdHJpbmcoKSk7XG4gIH1cbn1cblxuLyoqXG4gKiBQaHlzaWNhbGx5IGluc2VydHMgdGhlIGNvbW1lbnQgbm9kZXMgdG8gZW5zdXJlIGVtcHR5IHRleHQgbm9kZXMgYW5kIGFkamFjZW50XG4gKiB0ZXh0IG5vZGUgc2VwYXJhdG9ycyBhcmUgcHJlc2VydmVkIGFmdGVyIHNlcnZlciBzZXJpYWxpemF0aW9uIG9mIHRoZSBET00uXG4gKiBUaGVzZSBnZXQgc3dhcHBlZCBiYWNrIGZvciBlbXB0eSB0ZXh0IG5vZGVzIG9yIHNlcGFyYXRvcnMgb25jZSBoeWRyYXRpb24gaGFwcGVuc1xuICogb24gdGhlIGNsaWVudC5cbiAqXG4gKiBAcGFyYW0gY29ycnVwdGVkVGV4dE5vZGVzIFRoZSBNYXAgb2YgdGV4dCBub2RlcyB0byBiZSByZXBsYWNlZCB3aXRoIGNvbW1lbnRzXG4gKiBAcGFyYW0gZG9jIFRoZSBkb2N1bWVudFxuICovXG5mdW5jdGlvbiBpbnNlcnRDb3JydXB0ZWRUZXh0Tm9kZU1hcmtlcnMoXG4gICAgY29ycnVwdGVkVGV4dE5vZGVzOiBNYXA8SFRNTEVsZW1lbnQsIHN0cmluZz4sIGRvYzogRG9jdW1lbnQpIHtcbiAgZm9yIChjb25zdCBbdGV4dE5vZGUsIG1hcmtlcl0gb2YgY29ycnVwdGVkVGV4dE5vZGVzKSB7XG4gICAgdGV4dE5vZGUuYWZ0ZXIoZG9jLmNyZWF0ZUNvbW1lbnQobWFya2VyKSk7XG4gIH1cbn1cblxuLyoqXG4gKiBEZXRlY3RzIHdoZXRoZXIgYSBnaXZlbiBUTm9kZSByZXByZXNlbnRzIGEgbm9kZSB0aGF0XG4gKiBpcyBiZWluZyBjb250ZW50IHByb2plY3RlZC5cbiAqL1xuZnVuY3Rpb24gaXNDb250ZW50UHJvamVjdGVkTm9kZSh0Tm9kZTogVE5vZGUpOiBib29sZWFuIHtcbiAgbGV0IGN1cnJlbnRUTm9kZSA9IHROb2RlO1xuICB3aGlsZSAoY3VycmVudFROb2RlICE9IG51bGwpIHtcbiAgICAvLyBJZiB3ZSBjb21lIGFjcm9zcyBhIGNvbXBvbmVudCBob3N0IG5vZGUgaW4gcGFyZW50IG5vZGVzIC1cbiAgICAvLyB0aGlzIFROb2RlIGlzIGluIHRoZSBjb250ZW50IHByb2plY3Rpb24gc2VjdGlvbi5cbiAgICBpZiAoaXNDb21wb25lbnRIb3N0KGN1cnJlbnRUTm9kZSkpIHtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgICBjdXJyZW50VE5vZGUgPSBjdXJyZW50VE5vZGUucGFyZW50IGFzIFROb2RlO1xuICB9XG4gIHJldHVybiBmYWxzZTtcbn1cblxuLyoqXG4gKiBDaGVjayB3aGV0aGVyIGEgZ2l2ZW4gbm9kZSBleGlzdHMsIGJ1dCBpcyBkaXNjb25uZWN0ZWQgZnJvbSB0aGUgRE9NLlxuICpcbiAqIE5vdGU6IHdlIGxldmVyYWdlIHRoZSBmYWN0IHRoYXQgd2UgaGF2ZSB0aGlzIGluZm9ybWF0aW9uIGF2YWlsYWJsZSBpbiB0aGUgRE9NIGVtdWxhdGlvblxuICogbGF5ZXIgKGluIERvbWlubykgZm9yIG5vdy4gTG9uZ2VyLXRlcm0gc29sdXRpb24gc2hvdWxkIG5vdCByZWx5IG9uIHRoZSBET00gZW11bGF0aW9uIGFuZFxuICogb25seSB1c2UgaW50ZXJuYWwgZGF0YSBzdHJ1Y3R1cmVzIGFuZCBzdGF0ZSB0byBjb21wdXRlIHRoaXMgaW5mb3JtYXRpb24uXG4gKi9cbmZ1bmN0aW9uIGlzRGlzY29ubmVjdGVkTm9kZSh0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldykge1xuICByZXR1cm4gISh0Tm9kZS50eXBlICYgVE5vZGVUeXBlLlByb2plY3Rpb24pICYmICEhbFZpZXdbdE5vZGUuaW5kZXhdICYmXG4gICAgICAhKHVud3JhcFJOb2RlKGxWaWV3W3ROb2RlLmluZGV4XSkgYXMgTm9kZSkuaXNDb25uZWN0ZWQ7XG59XG4iXX0=