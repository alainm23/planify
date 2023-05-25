/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { DECLARATION_COMPONENT_VIEW, HEADER_OFFSET, HOST } from '../render3/interfaces/view';
import { getFirstNativeNode } from '../render3/node_manipulation';
import { ɵɵresolveBody } from '../render3/util/misc_utils';
import { renderStringify } from '../render3/util/stringify_utils';
import { getNativeByTNode, unwrapRNode } from '../render3/util/view_utils';
import { assertDefined } from '../util/assert';
import { compressNodeLocation, decompressNodeLocation } from './compression';
import { nodeNotFoundAtPathError, nodeNotFoundError, validateSiblingNodeExists } from './error_handling';
import { NodeNavigationStep, NODES, REFERENCE_NODE_BODY, REFERENCE_NODE_HOST } from './interfaces';
import { calcSerializedContainerSize, getSegmentHead } from './utils';
/** Whether current TNode is a first node in an <ng-container>. */
function isFirstElementInNgContainer(tNode) {
    return !tNode.prev && tNode.parent?.type === 8 /* TNodeType.ElementContainer */;
}
/** Returns an instruction index (subtracting HEADER_OFFSET). */
function getNoOffsetIndex(tNode) {
    return tNode.index - HEADER_OFFSET;
}
/**
 * Locate a node in DOM tree that corresponds to a given TNode.
 *
 * @param hydrationInfo The hydration annotation data
 * @param tView the current tView
 * @param lView the current lView
 * @param tNode the current tNode
 * @returns an RNode that represents a given tNode
 */
export function locateNextRNode(hydrationInfo, tView, lView, tNode) {
    let native = null;
    const noOffsetIndex = getNoOffsetIndex(tNode);
    const nodes = hydrationInfo.data[NODES];
    if (nodes?.[noOffsetIndex]) {
        // We know the exact location of the node.
        native = locateRNodeByPath(nodes[noOffsetIndex], lView);
    }
    else if (tView.firstChild === tNode) {
        // We create a first node in this view, so we use a reference
        // to the first child in this DOM segment.
        native = hydrationInfo.firstChild;
    }
    else {
        // Locate a node based on a previous sibling or a parent node.
        const previousTNodeParent = tNode.prev === null;
        const previousTNode = (tNode.prev ?? tNode.parent);
        ngDevMode &&
            assertDefined(previousTNode, 'Unexpected state: current TNode does not have a connection ' +
                'to the previous node or a parent node.');
        if (isFirstElementInNgContainer(tNode)) {
            const noOffsetParentIndex = getNoOffsetIndex(tNode.parent);
            native = getSegmentHead(hydrationInfo, noOffsetParentIndex);
        }
        else {
            let previousRElement = getNativeByTNode(previousTNode, lView);
            if (previousTNodeParent) {
                native = previousRElement.firstChild;
            }
            else {
                // If the previous node is an element, but it also has container info,
                // this means that we are processing a node like `<div #vcrTarget>`, which is
                // represented in the DOM as `<div></div>...<!--container-->`.
                // In this case, there are nodes *after* this element and we need to skip
                // all of them to reach an element that we are looking for.
                const noOffsetPrevSiblingIndex = getNoOffsetIndex(previousTNode);
                const segmentHead = getSegmentHead(hydrationInfo, noOffsetPrevSiblingIndex);
                if (previousTNode.type === 2 /* TNodeType.Element */ && segmentHead) {
                    const numRootNodesToSkip = calcSerializedContainerSize(hydrationInfo, noOffsetPrevSiblingIndex);
                    // `+1` stands for an anchor comment node after all the views in this container.
                    const nodesToSkip = numRootNodesToSkip + 1;
                    // First node after this segment.
                    native = siblingAfter(nodesToSkip, segmentHead);
                }
                else {
                    native = previousRElement.nextSibling;
                }
            }
        }
    }
    return native;
}
/**
 * Skips over a specified number of nodes and returns the next sibling node after that.
 */
export function siblingAfter(skip, from) {
    let currentNode = from;
    for (let i = 0; i < skip; i++) {
        ngDevMode && validateSiblingNodeExists(currentNode);
        currentNode = currentNode.nextSibling;
    }
    return currentNode;
}
/**
 * Helper function to produce a string representation of the navigation steps
 * (in terms of `nextSibling` and `firstChild` navigations). Used in error
 * messages in dev mode.
 */
function stringifyNavigationInstructions(instructions) {
    const container = [];
    for (let i = 0; i < instructions.length; i += 2) {
        const step = instructions[i];
        const repeat = instructions[i + 1];
        for (let r = 0; r < repeat; r++) {
            container.push(step === NodeNavigationStep.FirstChild ? 'firstChild' : 'nextSibling');
        }
    }
    return container.join('.');
}
/**
 * Helper function that navigates from a starting point node (the `from` node)
 * using provided set of navigation instructions (within `path` argument).
 */
function navigateToNode(from, instructions) {
    let node = from;
    for (let i = 0; i < instructions.length; i += 2) {
        const step = instructions[i];
        const repeat = instructions[i + 1];
        for (let r = 0; r < repeat; r++) {
            if (ngDevMode && !node) {
                throw nodeNotFoundAtPathError(from, stringifyNavigationInstructions(instructions));
            }
            switch (step) {
                case NodeNavigationStep.FirstChild:
                    node = node.firstChild;
                    break;
                case NodeNavigationStep.NextSibling:
                    node = node.nextSibling;
                    break;
            }
        }
    }
    if (ngDevMode && !node) {
        throw nodeNotFoundAtPathError(from, stringifyNavigationInstructions(instructions));
    }
    return node;
}
/**
 * Locates an RNode given a set of navigation instructions (which also contains
 * a starting point node info).
 */
function locateRNodeByPath(path, lView) {
    const [referenceNode, ...navigationInstructions] = decompressNodeLocation(path);
    let ref;
    if (referenceNode === REFERENCE_NODE_HOST) {
        ref = lView[DECLARATION_COMPONENT_VIEW][HOST];
    }
    else if (referenceNode === REFERENCE_NODE_BODY) {
        ref = ɵɵresolveBody(lView[DECLARATION_COMPONENT_VIEW][HOST]);
    }
    else {
        const parentElementId = Number(referenceNode);
        ref = unwrapRNode(lView[parentElementId + HEADER_OFFSET]);
    }
    return navigateToNode(ref, navigationInstructions);
}
/**
 * Generate a list of DOM navigation operations to get from node `start` to node `finish`.
 *
 * Note: assumes that node `start` occurs before node `finish` in an in-order traversal of the DOM
 * tree. That is, we should be able to get from `start` to `finish` purely by using `.firstChild`
 * and `.nextSibling` operations.
 */
export function navigateBetween(start, finish) {
    if (start === finish) {
        return [];
    }
    else if (start.parentElement == null || finish.parentElement == null) {
        return null;
    }
    else if (start.parentElement === finish.parentElement) {
        return navigateBetweenSiblings(start, finish);
    }
    else {
        // `finish` is a child of its parent, so the parent will always have a child.
        const parent = finish.parentElement;
        const parentPath = navigateBetween(start, parent);
        const childPath = navigateBetween(parent.firstChild, finish);
        if (!parentPath || !childPath)
            return null;
        return [
            // First navigate to `finish`'s parent
            ...parentPath,
            // Then to its first child.
            NodeNavigationStep.FirstChild,
            // And finally from that node to `finish` (maybe a no-op if we're already there).
            ...childPath,
        ];
    }
}
/**
 * Calculates a path between 2 sibling nodes (generates a number of `NextSibling` navigations).
 * Returns `null` if no such path exists between the given nodes.
 */
function navigateBetweenSiblings(start, finish) {
    const nav = [];
    let node = null;
    for (node = start; node != null && node !== finish; node = node.nextSibling) {
        nav.push(NodeNavigationStep.NextSibling);
    }
    // If the `node` becomes `null` or `undefined` at the end, that means that we
    // didn't find the `end` node, thus return `null` (which would trigger serialization
    // error to be produced).
    return node == null ? null : nav;
}
/**
 * Calculates a path between 2 nodes in terms of `nextSibling` and `firstChild`
 * navigations:
 * - the `from` node is a known node, used as an starting point for the lookup
 *   (the `fromNodeName` argument is a string representation of the node).
 * - the `to` node is a node that the runtime logic would be looking up,
 *   using the path generated by this function.
 */
export function calcPathBetween(from, to, fromNodeName) {
    const path = navigateBetween(from, to);
    return path === null ? null : compressNodeLocation(fromNodeName, path);
}
/**
 * Invoked at serialization time (on the server) when a set of navigation
 * instructions needs to be generated for a TNode.
 */
export function calcPathForNode(tNode, lView) {
    const parentTNode = tNode.parent;
    let parentIndex;
    let parentRNode;
    let referenceNodeName;
    if (parentTNode === null || !(parentTNode.type & 3 /* TNodeType.AnyRNode */)) {
        // If there is no parent TNode or a parent TNode does not represent an RNode
        // (i.e. not a DOM node), use component host element as a reference node.
        parentIndex = referenceNodeName = REFERENCE_NODE_HOST;
        parentRNode = lView[DECLARATION_COMPONENT_VIEW][HOST];
    }
    else {
        // Use parent TNode as a reference node.
        parentIndex = parentTNode.index;
        parentRNode = unwrapRNode(lView[parentIndex]);
        referenceNodeName = renderStringify(parentIndex - HEADER_OFFSET);
    }
    let rNode = unwrapRNode(lView[tNode.index]);
    if (tNode.type & 12 /* TNodeType.AnyContainer */) {
        // For <ng-container> nodes, instead of serializing a reference
        // to the anchor comment node, serialize a location of the first
        // DOM element. Paired with the container size (serialized as a part
        // of `ngh.containers`), it should give enough information for runtime
        // to hydrate nodes in this container.
        const firstRNode = getFirstNativeNode(lView, tNode);
        // If container is not empty, use a reference to the first element,
        // otherwise, rNode would point to an anchor comment node.
        if (firstRNode) {
            rNode = firstRNode;
        }
    }
    let path = calcPathBetween(parentRNode, rNode, referenceNodeName);
    if (path === null && parentRNode !== rNode) {
        // Searching for a path between elements within a host node failed.
        // Trying to find a path to an element starting from the `document.body` instead.
        //
        // Important note: this type of reference is relatively unstable, since Angular
        // may not be able to control parts of the page that the runtime logic navigates
        // through. This is mostly needed to cover "portals" use-case (like menus, dialog boxes,
        // etc), where nodes are content-projected (including direct DOM manipulations) outside
        // of the host node. The better solution is to provide APIs to work with "portals",
        // at which point this code path would not be needed.
        const body = parentRNode.ownerDocument.body;
        path = calcPathBetween(body, rNode, REFERENCE_NODE_BODY);
        if (path === null) {
            // If the path is still empty, it's likely that this node is detached and
            // won't be found during hydration.
            throw nodeNotFoundError(lView, tNode);
        }
    }
    return path;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibm9kZV9sb29rdXBfdXRpbHMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9oeWRyYXRpb24vbm9kZV9sb29rdXBfdXRpbHMudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBSUgsT0FBTyxFQUFDLDBCQUEwQixFQUFFLGFBQWEsRUFBRSxJQUFJLEVBQWUsTUFBTSw0QkFBNEIsQ0FBQztBQUN6RyxPQUFPLEVBQUMsa0JBQWtCLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUNoRSxPQUFPLEVBQUMsYUFBYSxFQUFDLE1BQU0sNEJBQTRCLENBQUM7QUFDekQsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQ2hFLE9BQU8sRUFBQyxnQkFBZ0IsRUFBRSxXQUFXLEVBQUMsTUFBTSw0QkFBNEIsQ0FBQztBQUN6RSxPQUFPLEVBQUMsYUFBYSxFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFFN0MsT0FBTyxFQUFDLG9CQUFvQixFQUFFLHNCQUFzQixFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQzNFLE9BQU8sRUFBQyx1QkFBdUIsRUFBRSxpQkFBaUIsRUFBRSx5QkFBeUIsRUFBQyxNQUFNLGtCQUFrQixDQUFDO0FBQ3ZHLE9BQU8sRUFBaUIsa0JBQWtCLEVBQUUsS0FBSyxFQUFFLG1CQUFtQixFQUFFLG1CQUFtQixFQUFDLE1BQU0sY0FBYyxDQUFDO0FBQ2pILE9BQU8sRUFBQywyQkFBMkIsRUFBRSxjQUFjLEVBQUMsTUFBTSxTQUFTLENBQUM7QUFHcEUsa0VBQWtFO0FBQ2xFLFNBQVMsMkJBQTJCLENBQUMsS0FBWTtJQUMvQyxPQUFPLENBQUMsS0FBSyxDQUFDLElBQUksSUFBSSxLQUFLLENBQUMsTUFBTSxFQUFFLElBQUksdUNBQStCLENBQUM7QUFDMUUsQ0FBQztBQUVELGdFQUFnRTtBQUNoRSxTQUFTLGdCQUFnQixDQUFDLEtBQVk7SUFDcEMs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IEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge1ROb2RlLCBUTm9kZVR5cGV9IGZyb20gJy4uL3JlbmRlcjMvaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7UkVsZW1lbnQsIFJOb2RlfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvcmVuZGVyZXJfZG9tJztcbmltcG9ydCB7REVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVcsIEhFQURFUl9PRkZTRVQsIEhPU1QsIExWaWV3LCBUVmlld30gZnJvbSAnLi4vcmVuZGVyMy9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtnZXRGaXJzdE5hdGl2ZU5vZGV9IGZyb20gJy4uL3JlbmRlcjMvbm9kZV9tYW5pcHVsYXRpb24nO1xuaW1wb3J0IHvJtcm1cmVzb2x2ZUJvZHl9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC9taXNjX3V0aWxzJztcbmltcG9ydCB7cmVuZGVyU3RyaW5naWZ5fSBmcm9tICcuLi9yZW5kZXIzL3V0aWwvc3RyaW5naWZ5X3V0aWxzJztcbmltcG9ydCB7Z2V0TmF0aXZlQnlUTm9kZSwgdW53cmFwUk5vZGV9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC92aWV3X3V0aWxzJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZH0gZnJvbSAnLi4vdXRpbC9hc3NlcnQnO1xuXG5pbXBvcnQge2NvbXByZXNzTm9kZUxvY2F0aW9uLCBkZWNvbXByZXNzTm9kZUxvY2F0aW9ufSBmcm9tICcuL2NvbXByZXNzaW9uJztcbmltcG9ydCB7bm9kZU5vdEZvdW5kQXRQYXRoRXJyb3IsIG5vZGVOb3RGb3VuZEVycm9yLCB2YWxpZGF0ZVNpYmxpbmdOb2RlRXhpc3RzfSBmcm9tICcuL2Vycm9yX2hhbmRsaW5nJztcbmltcG9ydCB7RGVoeWRyYXRlZFZpZXcsIE5vZGVOYXZpZ2F0aW9uU3RlcCwgTk9ERVMsIFJFRkVSRU5DRV9OT0RFX0JPRFksIFJFRkVSRU5DRV9OT0RFX0hPU1R9IGZyb20gJy4vaW50ZXJmYWNlcyc7XG5pbXBvcnQge2NhbGNTZXJpYWxpemVkQ29udGFpbmVyU2l6ZSwgZ2V0U2VnbWVudEhlYWR9IGZyb20gJy4vdXRpbHMnO1xuXG5cbi8qKiBXaGV0aGVyIGN1cnJlbnQgVE5vZGUgaXMgYSBmaXJzdCBub2RlIGluIGFuIDxuZy1jb250YWluZXI+LiAqL1xuZnVuY3Rpb24gaXNGaXJzdEVsZW1lbnRJbk5nQ29udGFpbmVyKHROb2RlOiBUTm9kZSk6IGJvb2xlYW4ge1xuICByZXR1cm4gIXROb2RlLnByZXYgJiYgdE5vZGUucGFyZW50Py50eXBlID09PSBUTm9kZVR5cGUuRWxlbWVudENvbnRhaW5lcjtcbn1cblxuLyoqIFJldHVybnMgYW4gaW5zdHJ1Y3Rpb24gaW5kZXggKHN1YnRyYWN0aW5nIEhFQURFUl9PRkZTRVQpLiAqL1xuZnVuY3Rpb24gZ2V0Tm9PZmZzZXRJbmRleCh0Tm9kZTogVE5vZGUpOiBudW1iZXIge1xuICByZXR1cm4gdE5vZGUuaW5kZXggLSBIRUFERVJfT0ZGU0VUO1xufVxuXG4vKipcbiAqIExvY2F0ZSBhIG5vZGUgaW4gRE9NIHRyZWUgdGhhdCBjb3JyZXNwb25kcyB0byBhIGdpdmVuIFROb2RlLlxuICpcbiAqIEBwYXJhbSBoeWRyYXRpb25JbmZvIFRoZSBoeWRyYXRpb24gYW5ub3RhdGlvbiBkYXRhXG4gKiBAcGFyYW0gdFZpZXcgdGhlIGN1cnJlbnQgdFZpZXdcbiAqIEBwYXJhbSBsVmlldyB0aGUgY3VycmVudCBsVmlld1xuICogQHBhcmFtIHROb2RlIHRoZSBjdXJyZW50IHROb2RlXG4gKiBAcmV0dXJucyBhbiBSTm9kZSB0aGF0IHJlcHJlc2VudHMgYSBnaXZlbiB0Tm9kZVxuICovXG5leHBvcnQgZnVuY3Rpb24gbG9jYXRlTmV4dFJOb2RlPFQgZXh0ZW5kcyBSTm9kZT4oXG4gICAgaHlkcmF0aW9uSW5mbzogRGVoeWRyYXRlZFZpZXcsIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3PHVua25vd24+LCB0Tm9kZTogVE5vZGUpOiBUfG51bGwge1xuICBsZXQgbmF0aXZlOiBSTm9kZXxudWxsID0gbnVsbDtcbiAgY29uc3Qgbm9PZmZzZXRJbmRleCA9IGdldE5vT2Zmc2V0SW5kZXgodE5vZGUpO1xuICBjb25zdCBub2RlcyA9IGh5ZHJhdGlvbkluZm8uZGF0YVtOT0RFU107XG4gIGlmIChub2Rlcz8uW25vT2Zmc2V0SW5kZXhdKSB7XG4gICAgLy8gV2Uga25vdyB0aGUgZXhhY3QgbG9jYXRpb24gb2YgdGhlIG5vZGUuXG4gICAgbmF0aXZlID0gbG9jYXRlUk5vZGVCeVBhdGgobm9kZXNbbm9PZmZzZXRJbmRleF0sIGxWaWV3KTtcbiAgfSBlbHNlIGlmICh0Vmlldy5maXJzdENoaWxkID09PSB0Tm9kZSkge1xuICAgIC8vIFdlIGNyZWF0ZSBhIGZpcnN0IG5vZGUgaW4gdGhpcyB2aWV3LCBzbyB3ZSB1c2UgYSByZWZlcmVuY2VcbiAgICAvLyB0byB0aGUgZmlyc3QgY2hpbGQgaW4gdGhpcyBET00gc2VnbWVudC5cbiAgICBuYXRpdmUgPSBoeWRyYXRpb25JbmZvLmZpcnN0Q2hpbGQ7XG4gIH0gZWxzZSB7XG4gICAgLy8gTG9jYXRlIGEgbm9kZSBiYXNlZCBvbiBhIHByZXZpb3VzIHNpYmxpbmcgb3IgYSBwYXJlbnQgbm9kZS5cbiAgICBjb25zdCBwcmV2aW91c1ROb2RlUGFyZW50ID0gdE5vZGUucHJldiA9PT0gbnVsbDtcbiAgICBjb25zdCBwcmV2aW91c1ROb2RlID0gKHROb2RlLnByZXYgPz8gdE5vZGUucGFyZW50KSE7XG4gICAgbmdEZXZNb2RlICYmXG4gICAgICAgIGFzc2VydERlZmluZWQoXG4gICAgICAgICAgICBwcmV2aW91c1ROb2RlLFxuICAgICAgICAgICAgJ1VuZXhwZWN0ZWQgc3RhdGU6IGN1cnJlbnQgVE5vZGUgZG9lcyBub3QgaGF2ZSBhIGNvbm5lY3Rpb24gJyArXG4gICAgICAgICAgICAgICAgJ3RvIHRoZSBwcmV2aW91cyBub2RlIG9yIGEgcGFyZW50IG5vZGUuJyk7XG4gICAgaWYgKGlzRmlyc3RFbGVtZW50SW5OZ0NvbnRhaW5lcih0Tm9kZSkpIHtcbiAgICAgIGNvbnN0IG5vT2Zmc2V0UGFyZW50SW5kZXggPSBnZXROb09mZnNldEluZGV4KHROb2RlLnBhcmVudCEpO1xuICAgICAgbmF0aXZlID0gZ2V0U2VnbWVudEhlYWQoaHlkcmF0aW9uSW5mbywgbm9PZmZzZXRQYXJlbnRJbmRleCk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGxldCBwcmV2aW91c1JFbGVtZW50ID0gZ2V0TmF0aXZlQnlUTm9kZShwcmV2aW91c1ROb2RlLCBsVmlldyk7XG4gICAgICBpZiAocHJldmlvdXNUTm9kZVBhcmVudCkge1xuICAgICAgICBuYXRpdmUgPSAocHJldmlvdXNSRWxlbWVudCBhcyBSRWxlbWVudCkuZmlyc3RDaGlsZDtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIElmIHRoZSBwcmV2aW91cyBub2RlIGlzIGFuIGVsZW1lbnQsIGJ1dCBpdCBhbHNvIGhhcyBjb250YWluZXIgaW5mbyxcbiAgICAgICAgLy8gdGhpcyBtZWFucyB0aGF0IHdlIGFyZSBwcm9jZXNzaW5nIGEgbm9kZSBsaWtlIGA8ZGl2ICN2Y3JUYXJnZXQ+YCwgd2hpY2ggaXNcbiAgICAgICAgLy8gcmVwcmVzZW50ZWQgaW4gdGhlIERPTSBhcyBgPGRpdj48L2Rpdj4uLi48IS0tY29udGFpbmVyLS0+YC5cbiAgICAgICAgLy8gSW4gdGhpcyBjYXNlLCB0aGVyZSBhcmUgbm9kZXMgKmFmdGVyKiB0aGlzIGVsZW1lbnQgYW5kIHdlIG5lZWQgdG8gc2tpcFxuICAgICAgICAvLyBhbGwgb2YgdGhlbSB0byByZWFjaCBhbiBlbGVtZW50IHRoYXQgd2UgYXJlIGxvb2tpbmcgZm9yLlxuICAgICAgICBjb25zdCBub09mZnNldFByZXZTaWJsaW5nSW5kZXggPSBnZXROb09mZnNldEluZGV4KHByZXZpb3VzVE5vZGUpO1xuICAgICAgICBjb25zdCBzZWdtZW50SGVhZCA9IGdldFNlZ21lbnRIZWFkKGh5ZHJhdGlvbkluZm8sIG5vT2Zmc2V0UHJldlNpYmxpbmdJbmRleCk7XG4gICAgICAgIGlmIChwcmV2aW91c1ROb2RlLnR5cGUgPT09IFROb2RlVHlwZS5FbGVtZW50ICYmIHNlZ21lbnRIZWFkKSB7XG4gICAgICAgICAgY29uc3QgbnVtUm9vdE5vZGVzVG9Ta2lwID1cbiAgICAgICAgICAgICAgY2FsY1NlcmlhbGl6ZWRDb250YWluZXJTaXplKGh5ZHJhdGlvbkluZm8sIG5vT2Zmc2V0UHJldlNpYmxpbmdJbmRleCk7XG4gICAgICAgICAgLy8gYCsxYCBzdGFuZHMgZm9yIGFuIGFuY2hvciBjb21tZW50IG5vZGUgYWZ0ZXIgYWxsIHRoZSB2aWV3cyBpbiB0aGlzIGNvbnRhaW5lci5cbiAgICAgICAgICBjb25zdCBub2Rlc1RvU2tpcCA9IG51bVJvb3ROb2Rlc1RvU2tpcCArIDE7XG4gICAgICAgICAgLy8gRmlyc3Qgbm9kZSBhZnRlciB0aGlzIHNlZ21lbnQuXG4gICAgICAgICAgbmF0aXZlID0gc2libGluZ0FmdGVyKG5vZGVzVG9Ta2lwLCBzZWdtZW50SGVhZCk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgbmF0aXZlID0gcHJldmlvdXNSRWxlbWVudC5uZXh0U2libGluZztcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgfVxuICByZXR1cm4gbmF0aXZlIGFzIFQ7XG59XG5cbi8qKlxuICogU2tpcHMgb3ZlciBhIHNwZWNpZmllZCBudW1iZXIgb2Ygbm9kZXMgYW5kIHJldHVybnMgdGhlIG5leHQgc2libGluZyBub2RlIGFmdGVyIHRoYXQuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzaWJsaW5nQWZ0ZXI8VCBleHRlbmRzIFJOb2RlPihza2lwOiBudW1iZXIsIGZyb206IFJOb2RlKTogVHxudWxsIHtcbiAgbGV0IGN1cnJlbnROb2RlID0gZnJvbTtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBza2lwOyBpKyspIHtcbiAgICBuZ0Rldk1vZGUgJiYgdmFsaWRhdGVTaWJsaW5nTm9kZUV4aXN0cyhjdXJyZW50Tm9kZSk7XG4gICAgY3VycmVudE5vZGUgPSBjdXJyZW50Tm9kZS5uZXh0U2libGluZyE7XG4gIH1cbiAgcmV0dXJuIGN1cnJlbnROb2RlIGFzIFQ7XG59XG5cbi8qKlxuICogSGVscGVyIGZ1bmN0aW9uIHRvIHByb2R1Y2UgYSBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2YgdGhlIG5hdmlnYXRpb24gc3RlcHNcbiAqIChpbiB0ZXJtcyBvZiBgbmV4dFNpYmxpbmdgIGFuZCBgZmlyc3RDaGlsZGAgbmF2aWdhdGlvbnMpLiBVc2VkIGluIGVycm9yXG4gKiBtZXNzYWdlcyBpbiBkZXYgbW9kZS5cbiAqL1xuZnVuY3Rpb24gc3RyaW5naWZ5TmF2aWdhdGlvbkluc3RydWN0aW9ucyhpbnN0cnVjdGlvbnM6IChudW1iZXJ8Tm9kZU5hdmlnYXRpb25TdGVwKVtdKTogc3RyaW5nIHtcbiAgY29uc3QgY29udGFpbmVyID0gW107XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgaW5zdHJ1Y3Rpb25zLmxlbmd0aDsgaSArPSAyKSB7XG4gICAgY29uc3Qgc3RlcCA9IGluc3RydWN0aW9uc1tpXTtcbiAgICBjb25zdCByZXBlYXQgPSBpbnN0cnVjdGlvbnNbaSArIDFdIGFzIG51bWJlcjtcbiAgICBmb3IgKGxldCByID0gMDsgciA8IHJlcGVhdDsgcisrKSB7XG4gICAgICBjb250YWluZXIucHVzaChzdGVwID09PSBOb2RlTmF2aWdhdGlvblN0ZXAuRmlyc3RDaGlsZCA/ICdmaXJzdENoaWxkJyA6ICduZXh0U2libGluZycpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gY29udGFpbmVyLmpvaW4oJy4nKTtcbn1cblxuLyoqXG4gKiBIZWxwZXIgZnVuY3Rpb24gdGhhdCBuYXZpZ2F0ZXMgZnJvbSBhIHN0YXJ0aW5nIHBvaW50IG5vZGUgKHRoZSBgZnJvbWAgbm9kZSlcbiAqIHVzaW5nIHByb3ZpZGVkIHNldCBvZiBuYXZpZ2F0aW9uIGluc3RydWN0aW9ucyAod2l0aGluIGBwYXRoYCBhcmd1bWVudCkuXG4gKi9cbmZ1bmN0aW9uIG5hdmlnYXRlVG9Ob2RlKGZyb206IE5vZGUsIGluc3RydWN0aW9uczogKG51bWJlcnxOb2RlTmF2aWdhdGlvblN0ZXApW10pOiBSTm9kZSB7XG4gIGxldCBub2RlID0gZnJvbTtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBpbnN0cnVjdGlvbnMubGVuZ3RoOyBpICs9IDIpIHtcbiAgICBjb25zdCBzdGVwID0gaW5zdHJ1Y3Rpb25zW2ldO1xuICAgIGNvbnN0IHJlcGVhdCA9IGluc3RydWN0aW9uc1tpICsgMV0gYXMgbnVtYmVyO1xuICAgIGZvciAobGV0IHIgPSAwOyByIDwgcmVwZWF0OyByKyspIHtcbiAgICAgIGlmIChuZ0Rldk1vZGUgJiYgIW5vZGUpIHtcbiAgICAgICAgdGhyb3cgbm9kZU5vdEZvdW5kQXRQYXRoRXJyb3IoZnJvbSwgc3RyaW5naWZ5TmF2aWdhdGlvbkluc3RydWN0aW9ucyhpbnN0cnVjdGlvbnMpKTtcbiAgICAgIH1cbiAgICAgIHN3aXRjaCAoc3RlcCkge1xuICAgICAgICBjYXNlIE5vZGVOYXZpZ2F0aW9uU3RlcC5GaXJzdENoaWxkOlxuICAgICAgICAgIG5vZGUgPSBub2RlLmZpcnN0Q2hpbGQhO1xuICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIE5vZGVOYXZpZ2F0aW9uU3RlcC5OZXh0U2libGluZzpcbiAgICAgICAgICBub2RlID0gbm9kZS5uZXh0U2libGluZyE7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICB9XG4gICAgfVxuICB9XG4gIGlmIChuZ0Rldk1vZGUgJiYgIW5vZGUpIHtcbiAgICB0aHJvdyBub2RlTm90Rm91bmRBdFBhdGhFcnJvcihmcm9tLCBzdHJpbmdpZnlOYXZpZ2F0aW9uSW5zdHJ1Y3Rpb25zKGluc3RydWN0aW9ucykpO1xuICB9XG4gIHJldHVybiBub2RlIGFzIFJOb2RlO1xufVxuXG4vKipcbiAqIExvY2F0ZXMgYW4gUk5vZGUgZ2l2ZW4gYSBzZXQgb2YgbmF2aWdhdGlvbiBpbnN0cnVjdGlvbnMgKHdoaWNoIGFsc28gY29udGFpbnNcbiAqIGEgc3RhcnRpbmcgcG9pbnQgbm9kZSBpbmZvKS5cbiAqL1xuZnVuY3Rpb24gbG9jYXRlUk5vZGVCeVBhdGgocGF0aDogc3RyaW5nLCBsVmlldzogTFZpZXcpOiBSTm9kZSB7XG4gIGNvbnN0IFtyZWZlcmVuY2VOb2RlLCAuLi5uYXZpZ2F0aW9uSW5zdHJ1Y3Rpb25zXSA9IGRlY29tcHJlc3NOb2RlTG9jYXRpb24ocGF0aCk7XG4gIGxldCByZWY6IEVsZW1lbnQ7XG4gIGlmIChyZWZlcmVuY2VOb2RlID09PSBSRUZFUkVOQ0VfTk9ERV9IT1NUKSB7XG4gICAgcmVmID0gbFZpZXdbREVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVddW0hPU1RdIGFzIHVua25vd24gYXMgRWxlbWVudDtcbiAgfSBlbHNlIGlmIChyZWZlcmVuY2VOb2RlID09PSBSRUZFUkVOQ0VfTk9ERV9CT0RZKSB7XG4gICAgcmVmID0gybXJtXJlc29sdmVCb2R5KFxuICAgICAgICBsVmlld1tERUNMQVJBVElPTl9DT01QT05FTlRfVklFV11bSE9TVF0gYXMgUkVsZW1lbnQgJiB7b3duZXJEb2N1bWVudDogRG9jdW1lbnR9KTtcbiAgfSBlbHNlIHtcbiAgICBjb25zdCBwYXJlbnRFbGVtZW50SWQgPSBOdW1iZXIocmVmZXJlbmNlTm9kZSk7XG4gICAgcmVmID0gdW53cmFwUk5vZGUoKGxWaWV3IGFzIGFueSlbcGFyZW50RWxlbWVudElkICsgSEVBREVSX09GRlNFVF0pIGFzIEVsZW1lbnQ7XG4gIH1cbiAgcmV0dXJuIG5hdmlnYXRlVG9Ob2RlKHJlZiwgbmF2aWdhdGlvbkluc3RydWN0aW9ucyk7XG59XG5cbi8qKlxuICogR2VuZXJhdGUgYSBsaXN0IG9mIERPTSBuYXZpZ2F0aW9uIG9wZXJhdGlvbnMgdG8gZ2V0IGZyb20gbm9kZSBgc3RhcnRgIHRvIG5vZGUgYGZpbmlzaGAuXG4gKlxuICogTm90ZTogYXNzdW1lcyB0aGF0IG5vZGUgYHN0YXJ0YCBvY2N1cnMgYmVmb3JlIG5vZGUgYGZpbmlzaGAgaW4gYW4gaW4tb3JkZXIgdHJhdmVyc2FsIG9mIHRoZSBET01cbiAqIHRyZWUuIFRoYXQgaXMsIHdlIHNob3VsZCBiZSBhYmxlIHRvIGdldCBmcm9tIGBzdGFydGAgdG8gYGZpbmlzaGAgcHVyZWx5IGJ5IHVzaW5nIGAuZmlyc3RDaGlsZGBcbiAqIGFuZCBgLm5leHRTaWJsaW5nYCBvcGVyYXRpb25zLlxuICovXG5leHBvcnQgZnVuY3Rpb24gbmF2aWdhdGVCZXR3ZWVuKHN0YXJ0OiBOb2RlLCBmaW5pc2g6IE5vZGUpOiBOb2RlTmF2aWdhdGlvblN0ZXBbXXxudWxsIHtcbiAgaWYgKHN0YXJ0ID09PSBmaW5pc2gpIHtcbiAgICByZXR1cm4gW107XG4gIH0gZWxzZSBpZiAoc3RhcnQucGFyZW50RWxlbWVudCA9PSBudWxsIHx8IGZpbmlzaC5wYXJlbnRFbGVtZW50ID09IG51bGwpIHtcbiAgICByZXR1cm4gbnVsbDtcbiAgfSBlbHNlIGlmIChzdGFydC5wYXJlbnRFbGVtZW50ID09PSBmaW5pc2gucGFyZW50RWxlbWVudCkge1xuICAgIHJldHVybiBuYXZpZ2F0ZUJldHdlZW5TaWJsaW5ncyhzdGFydCwgZmluaXNoKTtcbiAgfSBlbHNlIHtcbiAgICAvLyBgZmluaXNoYCBpcyBhIGNoaWxkIG9mIGl0cyBwYXJlbnQsIHNvIHRoZSBwYXJlbnQgd2lsbCBhbHdheXMgaGF2ZSBhIGNoaWxkLlxuICAgIGNvbnN0IHBhcmVudCA9IGZpbmlzaC5wYXJlbnRFbGVtZW50ITtcblxuICAgIGNvbnN0IHBhcmVudFBhdGggPSBuYXZpZ2F0ZUJldHdlZW4oc3RhcnQsIHBhcmVudCk7XG4gICAgY29uc3QgY2hpbGRQYXRoID0gbmF2aWdhdGVCZXR3ZWVuKHBhcmVudC5maXJzdENoaWxkISwgZmluaXNoKTtcbiAgICBpZiAoIXBhcmVudFBhdGggfHwgIWNoaWxkUGF0aCkgcmV0dXJuIG51bGw7XG5cbiAgICByZXR1cm4gW1xuICAgICAgLy8gRmlyc3QgbmF2aWdhdGUgdG8gYGZpbmlzaGAncyBwYXJlbnRcbiAgICAgIC4uLnBhcmVudFBhdGgsXG4gICAgICAvLyBUaGVuIHRvIGl0cyBmaXJzdCBjaGlsZC5cbiAgICAgIE5vZGVOYXZpZ2F0aW9uU3RlcC5GaXJzdENoaWxkLFxuICAgICAgLy8gQW5kIGZpbmFsbHkgZnJvbSB0aGF0IG5vZGUgdG8gYGZpbmlzaGAgKG1heWJlIGEgbm8tb3AgaWYgd2UncmUgYWxyZWFkeSB0aGVyZSkuXG4gICAgICAuLi5jaGlsZFBhdGgsXG4gICAgXTtcbiAgfVxufVxuXG4vKipcbiAqIENhbGN1bGF0ZXMgYSBwYXRoIGJldHdlZW4gMiBzaWJsaW5nIG5vZGVzIChnZW5lcmF0ZXMgYSBudW1iZXIgb2YgYE5leHRTaWJsaW5nYCBuYXZpZ2F0aW9ucykuXG4gKiBSZXR1cm5zIGBudWxsYCBpZiBubyBzdWNoIHBhdGggZXhpc3RzIGJldHdlZW4gdGhlIGdpdmVuIG5vZGVzLlxuICovXG5mdW5jdGlvbiBuYXZpZ2F0ZUJldHdlZW5TaWJsaW5ncyhzdGFydDogTm9kZSwgZmluaXNoOiBOb2RlKTogTm9kZU5hdmlnYXRpb25TdGVwW118bnVsbCB7XG4gIGNvbnN0IG5hdjogTm9kZU5hdmlnYXRpb25TdGVwW10gPSBbXTtcbiAgbGV0IG5vZGU6IE5vZGV8bnVsbCA9IG51bGw7XG4gIGZvciAobm9kZSA9IHN0YXJ0OyBub2RlICE9IG51bGwgJiYgbm9kZSAhPT0gZmluaXNoOyBub2RlID0gbm9kZS5uZXh0U2libGluZykge1xuICAgIG5hdi5wdXNoKE5vZGVOYXZpZ2F0aW9uU3RlcC5OZXh0U2libGluZyk7XG4gIH1cbiAgLy8gSWYgdGhlIGBub2RlYCBiZWNvbWVzIGBudWxsYCBvciBgdW5kZWZpbmVkYCBhdCB0aGUgZW5kLCB0aGF0IG1lYW5zIHRoYXQgd2VcbiAgLy8gZGlkbid0IGZpbmQgdGhlIGBlbmRgIG5vZGUsIHRodXMgcmV0dXJuIGBudWxsYCAod2hpY2ggd291bGQgdHJpZ2dlciBzZXJpYWxpemF0aW9uXG4gIC8vIGVycm9yIHRvIGJlIHByb2R1Y2VkKS5cbiAgcmV0dXJuIG5vZGUgPT0gbnVsbCA/IG51bGwgOiBuYXY7XG59XG5cbi8qKlxuICogQ2FsY3VsYXRlcyBhIHBhdGggYmV0d2VlbiAyIG5vZGVzIGluIHRlcm1zIG9mIGBuZXh0U2libGluZ2AgYW5kIGBmaXJzdENoaWxkYFxuICogbmF2aWdhdGlvbnM6XG4gKiAtIHRoZSBgZnJvbWAgbm9kZSBpcyBhIGtub3duIG5vZGUsIHVzZWQgYXMgYW4gc3RhcnRpbmcgcG9pbnQgZm9yIHRoZSBsb29rdXBcbiAqICAgKHRoZSBgZnJvbU5vZGVOYW1lYCBhcmd1bWVudCBpcyBhIHN0cmluZyByZXByZXNlbnRhdGlvbiBvZiB0aGUgbm9kZSkuXG4gKiAtIHRoZSBgdG9gIG5vZGUgaXMgYSBub2RlIHRoYXQgdGhlIHJ1bnRpbWUgbG9naWMgd291bGQgYmUgbG9va2luZyB1cCxcbiAqICAgdXNpbmcgdGhlIHBhdGggZ2VuZXJhdGVkIGJ5IHRoaXMgZnVuY3Rpb24uXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjYWxjUGF0aEJldHdlZW4oZnJvbTogTm9kZSwgdG86IE5vZGUsIGZyb21Ob2RlTmFtZTogc3RyaW5nKTogc3RyaW5nfG51bGwge1xuICBjb25zdCBwYXRoID0gbmF2aWdhdGVCZXR3ZWVuKGZyb20sIHRvKTtcbiAgcmV0dXJuIHBhdGggPT09IG51bGwgPyBudWxsIDogY29tcHJlc3NOb2RlTG9jYXRpb24oZnJvbU5vZGVOYW1lLCBwYXRoKTtcbn1cblxuLyoqXG4gKiBJbnZva2VkIGF0IHNlcmlhbGl6YXRpb24gdGltZSAob24gdGhlIHNlcnZlcikgd2hlbiBhIHNldCBvZiBuYXZpZ2F0aW9uXG4gKiBpbnN0cnVjdGlvbnMgbmVlZHMgdG8gYmUgZ2VuZXJhdGVkIGZvciBhIFROb2RlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gY2FsY1BhdGhGb3JOb2RlKHROb2RlOiBUTm9kZSwgbFZpZXc6IExWaWV3KTogc3RyaW5nIHtcbiAgY29uc3QgcGFyZW50VE5vZGUgPSB0Tm9kZS5wYXJlbnQ7XG4gIGxldCBwYXJlbnRJbmRleDogbnVtYmVyfHN0cmluZztcbiAgbGV0IHBhcmVudFJOb2RlOiBSTm9kZTtcbiAgbGV0IHJlZmVyZW5jZU5vZGVOYW1lOiBzdHJpbmc7XG4gIGlmIChwYXJlbnRUTm9kZSA9PT0gbnVsbCB8fCAhKHBhcmVudFROb2RlLnR5cGUgJiBUTm9kZVR5cGUuQW55Uk5vZGUpKSB7XG4gICAgLy8gSWYgdGhlcmUgaXMgbm8gcGFyZW50IFROb2RlIG9yIGEgcGFyZW50IFROb2RlIGRvZXMgbm90IHJlcHJlc2VudCBhbiBSTm9kZVxuICAgIC8vIChpLmUuIG5vdCBhIERPTSBub2RlKSwgdXNlIGNvbXBvbmVudCBob3N0IGVsZW1lbnQgYXMgYSByZWZlcmVuY2Ugbm9kZS5cbiAgICBwYXJlbnRJbmRleCA9IHJlZmVyZW5jZU5vZGVOYW1lID0gUkVGRVJFTkNFX05PREVfSE9TVDtcbiAgICBwYXJlbnRSTm9kZSA9IGxWaWV3W0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXXVtIT1NUXSE7XG4gIH0gZWxzZSB7XG4gICAgLy8gVXNlIHBhcmVudCBUTm9kZSBhcyBhIHJlZmVyZW5jZSBub2RlLlxuICAgIHBhcmVudEluZGV4ID0gcGFyZW50VE5vZGUuaW5kZXg7XG4gICAgcGFyZW50Uk5vZGUgPSB1bndyYXBSTm9kZShsVmlld1twYXJlbnRJbmRleF0pO1xuICAgIHJlZmVyZW5jZU5vZGVOYW1lID0gcmVuZGVyU3RyaW5naWZ5KHBhcmVudEluZGV4IC0gSEVBREVSX09GRlNFVCk7XG4gIH1cbiAgbGV0IHJOb2RlID0gdW53cmFwUk5vZGUobFZpZXdbdE5vZGUuaW5kZXhdKTtcbiAgaWYgKHROb2RlLnR5cGUgJiBUTm9kZVR5cGUuQW55Q29udGFpbmVyKSB7XG4gICAgLy8gRm9yIDxuZy1jb250YWluZXI+IG5vZGVzLCBpbnN0ZWFkIG9mIHNlcmlhbGl6aW5nIGEgcmVmZXJlbmNlXG4gICAgLy8gdG8gdGhlIGFuY2hvciBjb21tZW50IG5vZGUsIHNlcmlhbGl6ZSBhIGxvY2F0aW9uIG9mIHRoZSBmaXJzdFxuICAgIC8vIERPTSBlbGVtZW50LiBQYWlyZWQgd2l0aCB0aGUgY29udGFpbmVyIHNpemUgKHNlcmlhbGl6ZWQgYXMgYSBwYXJ0XG4gICAgLy8gb2YgYG5naC5jb250YWluZXJzYCksIGl0IHNob3VsZCBnaXZlIGVub3VnaCBpbmZvcm1hdGlvbiBmb3IgcnVudGltZVxuICAgIC8vIHRvIGh5ZHJhdGUgbm9kZXMgaW4gdGhpcyBjb250YWluZXIuXG4gICAgY29uc3QgZmlyc3RSTm9kZSA9IGdldEZpcnN0TmF0aXZlTm9kZShsVmlldywgdE5vZGUpO1xuXG4gICAgLy8gSWYgY29udGFpbmVyIGlzIG5vdCBlbXB0eSwgdXNlIGEgcmVmZXJlbmNlIHRvIHRoZSBmaXJzdCBlbGVtZW50LFxuICAgIC8vIG90aGVyd2lzZSwgck5vZGUgd291bGQgcG9pbnQgdG8gYW4gYW5jaG9yIGNvbW1lbnQgbm9kZS5cbiAgICBpZiAoZmlyc3RSTm9kZSkge1xuICAgICAgck5vZGUgPSBmaXJzdFJOb2RlO1xuICAgIH1cbiAgfVxuICBsZXQgcGF0aDogc3RyaW5nfG51bGwgPSBjYWxjUGF0aEJldHdlZW4ocGFyZW50Uk5vZGUgYXMgTm9kZSwgck5vZGUgYXMgTm9kZSwgcmVmZXJlbmNlTm9kZU5hbWUpO1xuICBpZiAocGF0aCA9PT0gbnVsbCAmJiBwYXJlbnRSTm9kZSAhPT0gck5vZGUpIHtcbiAgICAvLyBTZWFyY2hpbmcgZm9yIGEgcGF0aCBiZXR3ZWVuIGVsZW1lbnRzIHdpdGhpbiBhIGhvc3Qgbm9kZSBmYWlsZWQuXG4gICAgLy8gVHJ5aW5nIHRvIGZpbmQgYSBwYXRoIHRvIGFuIGVsZW1lbnQgc3RhcnRpbmcgZnJvbSB0aGUgYGRvY3VtZW50LmJvZHlgIGluc3RlYWQuXG4gICAgLy9cbiAgICAvLyBJbXBvcnRhbnQgbm90ZTogdGhpcyB0eXBlIG9mIHJlZmVyZW5jZSBpcyByZWxhdGl2ZWx5IHVuc3RhYmxlLCBzaW5jZSBBbmd1bGFyXG4gICAgLy8gbWF5IG5vdCBiZSBhYmxlIHRvIGNvbnRyb2wgcGFydHMgb2YgdGhlIHBhZ2UgdGhhdCB0aGUgcnVudGltZSBsb2dpYyBuYXZpZ2F0ZXNcbiAgICAvLyB0aHJvdWdoLiBUaGlzIGlzIG1vc3RseSBuZWVkZWQgdG8gY292ZXIgXCJwb3J0YWxzXCIgdXNlLWNhc2UgKGxpa2UgbWVudXMsIGRpYWxvZyBib3hlcyxcbiAgICAvLyBldGMpLCB3aGVyZSBub2RlcyBhcmUgY29udGVudC1wcm9qZWN0ZWQgKGluY2x1ZGluZyBkaXJlY3QgRE9NIG1hbmlwdWxhdGlvbnMpIG91dHNpZGVcbiAgICAvLyBvZiB0aGUgaG9zdCBub2RlLiBUaGUgYmV0dGVyIHNvbHV0aW9uIGlzIHRvIHByb3ZpZGUgQVBJcyB0byB3b3JrIHdpdGggXCJwb3J0YWxzXCIsXG4gICAgLy8gYXQgd2hpY2ggcG9pbnQgdGhpcyBjb2RlIHBhdGggd291bGQgbm90IGJlIG5lZWRlZC5cbiAgICBjb25zdCBib2R5ID0gKHBhcmVudFJOb2RlIGFzIE5vZGUpLm93bmVyRG9jdW1lbnQhLmJvZHkgYXMgTm9kZTtcbiAgICBwYXRoID0gY2FsY1BhdGhCZXR3ZWVuKGJvZHksIHJOb2RlIGFzIE5vZGUsIFJFRkVSRU5DRV9OT0RFX0JPRFkpO1xuXG4gICAgaWYgKHBhdGggPT09IG51bGwpIHtcbiAgICAgIC8vIElmIHRoZSBwYXRoIGlzIHN0aWxsIGVtcHR5LCBpdCdzIGxpa2VseSB0aGF0IHRoaXMgbm9kZSBpcyBkZXRhY2hlZCBhbmRcbiAgICAgIC8vIHdvbid0IGJlIGZvdW5kIGR1cmluZyBoeWRyYXRpb24uXG4gICAgICB0aHJvdyBub2RlTm90Rm91bmRFcnJvcihsVmlldywgdE5vZGUpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gcGF0aCE7XG59XG4iXX0=