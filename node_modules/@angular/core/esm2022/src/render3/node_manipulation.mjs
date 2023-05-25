/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ViewEncapsulation } from '../metadata/view';
import { RendererStyleFlags2 } from '../render/api_flags';
import { addToArray, removeFromArray } from '../util/array_utils';
import { assertDefined, assertEqual, assertFunction, assertNumber, assertString } from '../util/assert';
import { escapeCommentText } from '../util/dom';
import { assertLContainer, assertLView, assertParentView, assertProjectionSlots, assertTNodeForLView } from './assert';
import { attachPatchData } from './context_discovery';
import { icuContainerIterate } from './i18n/i18n_tree_shaking';
import { CONTAINER_HEADER_OFFSET, HAS_TRANSPLANTED_VIEWS, MOVED_VIEWS, NATIVE } from './interfaces/container';
import { NodeInjectorFactory } from './interfaces/injector';
import { unregisterLView } from './interfaces/lview_tracking';
import { isLContainer, isLView } from './interfaces/type_checks';
import { CHILD_HEAD, CLEANUP, DECLARATION_COMPONENT_VIEW, DECLARATION_LCONTAINER, FLAGS, HOST, NEXT, ON_DESTROY_HOOKS, PARENT, QUERIES, REACTIVE_HOST_BINDING_CONSUMER, REACTIVE_TEMPLATE_CONSUMER, RENDERER, T_HOST, TVIEW } from './interfaces/view';
import { assertTNodeType } from './node_assert';
import { profiler } from './profiler';
import { setUpAttributes } from './util/attrs_utils';
import { getLViewParent } from './util/view_traversal_utils';
import { clearViewRefreshFlag, getNativeByTNode, unwrapRNode } from './util/view_utils';
/**
 * NOTE: for performance reasons, the possible actions are inlined within the function instead of
 * being passed as an argument.
 */
function applyToElementOrContainer(action, renderer, parent, lNodeToHandle, beforeNode) {
    // If this slot was allocated for a text node dynamically created by i18n, the text node itself
    // won't be created until i18nApply() in the update block, so this node should be skipped.
    // For more info, see "ICU expressions should work inside an ngTemplateOutlet inside an ngFor"
    // in `i18n_spec.ts`.
    if (lNodeToHandle != null) {
        let lContainer;
        let isComponent = false;
        // We are expecting an RNode, but in the case of a component or LContainer the `RNode` is
        // wrapped in an array which needs to be unwrapped. We need to know if it is a component and if
        // it has LContainer so that we can process all of those cases appropriately.
        if (isLContainer(lNodeToHandle)) {
            lContainer = lNodeToHandle;
        }
        else if (isLView(lNodeToHandle)) {
            isComponent = true;
            ngDevMode && assertDefined(lNodeToHandle[HOST], 'HOST must be defined for a component LView');
            lNodeToHandle = lNodeToHandle[HOST];
        }
        const rNode = unwrapRNode(lNodeToHandle);
        if (action === 0 /* WalkTNodeTreeAction.Create */ && parent !== null) {
            if (beforeNode == null) {
                nativeAppendChild(renderer, parent, rNode);
            }
            else {
                nativeInsertBefore(renderer, parent, rNode, beforeNode || null, true);
            }
        }
        else if (action === 1 /* WalkTNodeTreeAction.Insert */ && parent !== null) {
            nativeInsertBefore(renderer, parent, rNode, beforeNode || null, true);
        }
        else if (action === 2 /* WalkTNodeTreeAction.Detach */) {
            nativeRemoveNode(renderer, rNode, isComponent);
        }
        else if (action === 3 /* WalkTNodeTreeAction.Destroy */) {
            ngDevMode && ngDevMode.rendererDestroyNode++;
            renderer.destroyNode(rNode);
        }
        if (lContainer != null) {
            applyContainer(renderer, action, lContainer, parent, beforeNode);
        }
    }
}
export function createTextNode(renderer, value) {
    ngDevMode && ngDevMode.rendererCreateTextNode++;
    ngDevMode && ngDevMode.rendererSetText++;
    return renderer.createText(value);
}
export function updateTextNode(renderer, rNode, value) {
    ngDevMode && ngDevMode.rendererSetText++;
    renderer.setValue(rNode, value);
}
export function createCommentNode(renderer, value) {
    ngDevMode && ngDevMode.rendererCreateComment++;
    return renderer.createComment(escapeCommentText(value));
}
/**
 * Creates a native element from a tag name, using a renderer.
 * @param renderer A renderer to use
 * @param name the tag name
 * @param namespace Optional namespace for element.
 * @returns the element created
 */
export function createElementNode(renderer, name, namespace) {
    ngDevMode && ngDevMode.rendererCreateElement++;
    return renderer.createElement(name, namespace);
}
/**
 * Removes all DOM elements associated with a view.
 *
 * Because some root nodes of the view may be containers, we sometimes need
 * to propagate deeply into the nested containers to remove all elements in the
 * views beneath it.
 *
 * @param tView The `TView' of the `LView` from which elements should be added or removed
 * @param lView The view from which elements should be added or removed
 */
export function removeViewFromContainer(tView, lView) {
    const renderer = lView[RENDERER];
    applyView(tView, lView, renderer, 2 /* WalkTNodeTreeAction.Detach */, null, null);
    lView[HOST] = null;
    lView[T_HOST] = null;
}
/**
 * Adds all DOM elements associated with a view.
 *
 * Because some root nodes of the view may be containers, we sometimes need
 * to propagate deeply into the nested containers to add all elements in the
 * views beneath it.
 *
 * @param tView The `TView' of the `LView` from which elements should be added or removed
 * @param parentTNode The `TNode` where the `LView` should be attached to.
 * @param renderer Current renderer to use for DOM manipulations.
 * @param lView The view from which elements should be added or removed
 * @param parentNativeNode The parent `RElement` where it should be inserted into.
 * @param beforeNode The node before which elements should be added, if insert mode
 */
export function addViewToContainer(tView, parentTNode, renderer, lView, parentNativeNode, beforeNode) {
    lView[HOST] = parentNativeNode;
    lView[T_HOST] = parentTNode;
    applyView(tView, lView, renderer, 1 /* WalkTNodeTreeAction.Insert */, parentNativeNode, beforeNode);
}
/**
 * Detach a `LView` from the DOM by detaching its nodes.
 *
 * @param tView The `TView' of the `LView` to be detached
 * @param lView the `LView` to be detached.
 */
export function renderDetachView(tView, lView) {
    applyView(tView, lView, lView[RENDERER], 2 /* WalkTNodeTreeAction.Detach */, null, null);
}
/**
 * Traverses down and up the tree of views and containers to remove listeners and
 * call onDestroy callbacks.
 *
 * Notes:
 *  - Because it's used for onDestroy calls, it needs to be bottom-up.
 *  - Must process containers instead of their views to avoid splicing
 *  when views are destroyed and re-added.
 *  - Using a while loop because it's faster than recursion
 *  - Destroy only called on movement to sibling or movement to parent (laterally or up)
 *
 *  @param rootView The view to destroy
 */
export function destroyViewTree(rootView) {
    // If the view has no children, we can clean it up and return early.
    let lViewOrLContainer = rootView[CHILD_HEAD];
    if (!lViewOrLContainer) {
        return cleanUpView(rootView[TVIEW], rootView);
    }
    while (lViewOrLContainer) {
        let next = null;
        if (isLView(lViewOrLContainer)) {
            // If LView, traverse down to child.
            next = lViewOrLContainer[CHILD_HEAD];
        }
        else {
            ngDevMode && assertLContainer(lViewOrLContainer);
            // If container, traverse down to its first LView.
            const firstView = lViewOrLContainer[CONTAINER_HEADER_OFFSET];
            if (firstView)
                next = firstView;
        }
        if (!next) {
            // Only clean up view when moving to the side or up, as destroy hooks
            // should be called in order from the bottom up.
            while (lViewOrLContainer && !lViewOrLContainer[NEXT] && lViewOrLContainer !== rootView) {
                if (isLView(lViewOrLContainer)) {
                    cleanUpView(lViewOrLContainer[TVIEW], lViewOrLContainer);
                }
                lViewOrLContainer = lViewOrLContainer[PARENT];
            }
            if (lViewOrLContainer === null)
                lViewOrLContainer = rootView;
            if (isLView(lViewOrLContainer)) {
                cleanUpView(lViewOrLContainer[TVIEW], lViewOrLContainer);
            }
            next = lViewOrLContainer && lViewOrLContainer[NEXT];
        }
        lViewOrLContainer = next;
    }
}
/**
 * Inserts a view into a container.
 *
 * This adds the view to the container's array of active views in the correct
 * position. It also adds the view's elements to the DOM if the container isn't a
 * root node of another view (in that case, the view's elements will be added when
 * the container's parent view is added later).
 *
 * @param tView The `TView' of the `LView` to insert
 * @param lView The view to insert
 * @param lContainer The container into which the view should be inserted
 * @param index Which index in the container to insert the child view into
 */
export function insertView(tView, lView, lContainer, index) {
    ngDevMode && assertLView(lView);
    ngDevMode && assertLContainer(lContainer);
    const indexInContainer = CONTAINER_HEADER_OFFSET + index;
    const containerLength = lContainer.length;
    if (index > 0) {
        // This is a new view, we need to add it to the children.
        lContainer[indexInContainer - 1][NEXT] = lView;
    }
    if (index < containerLength - CONTAINER_HEADER_OFFSET) {
        lView[NEXT] = lContainer[indexInContainer];
        addToArray(lContainer, CONTAINER_HEADER_OFFSET + index, lView);
    }
    else {
        lContainer.push(lView);
        lView[NEXT] = null;
    }
    lView[PARENT] = lContainer;
    // track views where declaration and insertion points are different
    const declarationLContainer = lView[DECLARATION_LCONTAINER];
    if (declarationLContainer !== null && lContainer !== declarationLContainer) {
        trackMovedView(declarationLContainer, lView);
    }
    // notify query that a new view has been added
    const lQueries = lView[QUERIES];
    if (lQueries !== null) {
        lQueries.insertView(tView);
    }
    // Sets the attached flag
    lView[FLAGS] |= 128 /* LViewFlags.Attached */;
}
/**
 * Track views created from the declaration container (TemplateRef) and inserted into a
 * different LContainer.
 */
function trackMovedView(declarationContainer, lView) {
    ngDevMode && assertDefined(lView, 'LView required');
    ngDevMode && assertLContainer(declarationContainer);
    const movedViews = declarationContainer[MOVED_VIEWS];
    const insertedLContainer = lView[PARENT];
    ngDevMode && assertLContainer(insertedLContainer);
    const insertedComponentLView = insertedLContainer[PARENT][DECLARATION_COMPONENT_VIEW];
    ngDevMode && assertDefined(insertedComponentLView, 'Missing insertedComponentLView');
    const declaredComponentLView = lView[DECLARATION_COMPONENT_VIEW];
    ngDevMode && assertDefined(declaredComponentLView, 'Missing declaredComponentLView');
    if (declaredComponentLView !== insertedComponentLView) {
        // At this point the declaration-component is not same as insertion-component; this means that
        // this is a transplanted view. Mark the declared lView as having transplanted views so that
        // those views can participate in CD.
        declarationContainer[HAS_TRANSPLANTED_VIEWS] = true;
    }
    if (movedViews === null) {
        declarationContainer[MOVED_VIEWS] = [lView];
    }
    else {
        movedViews.push(lView);
    }
}
function detachMovedView(declarationContainer, lView) {
    ngDevMode && assertLContainer(declarationContainer);
    ngDevMode &&
        assertDefined(declarationContainer[MOVED_VIEWS], 'A projected view should belong to a non-empty projected views collection');
    const movedViews = declarationContainer[MOVED_VIEWS];
    const declarationViewIndex = movedViews.indexOf(lView);
    const insertionLContainer = lView[PARENT];
    ngDevMode && assertLContainer(insertionLContainer);
    // If the view was marked for refresh but then detached before it was checked (where the flag
    // would be cleared and the counter decremented), we need to update the status here.
    clearViewRefreshFlag(lView);
    movedViews.splice(declarationViewIndex, 1);
}
/**
 * Detaches a view from a container.
 *
 * This method removes the view from the container's array of active views. It also
 * removes the view's elements from the DOM.
 *
 * @param lContainer The container from which to detach a view
 * @param removeIndex The index of the view to detach
 * @returns Detached LView instance.
 */
export function detachView(lContainer, removeIndex) {
    if (lContainer.length <= CONTAINER_HEADER_OFFSET)
        return;
    const indexInContainer = CONTAINER_HEADER_OFFSET + removeIndex;
    const viewToDetach = lContainer[indexInContainer];
    if (viewToDetach) {
        const declarationLContainer = viewToDetach[DECLARATION_LCONTAINER];
        if (declarationLContainer !== null && declarationLContainer !== lContainer) {
            detachMovedView(declarationLContainer, viewToDetach);
        }
        if (removeIndex > 0) {
            lContainer[indexInContainer - 1][NEXT] = viewToDetach[NEXT];
        }
        const removedLView = removeFromArray(lContainer, CONTAINER_HEADER_OFFSET + removeIndex);
        removeViewFromContainer(viewToDetach[TVIEW], viewToDetach);
        // notify query that a view has been removed
        const lQueries = removedLView[QUERIES];
        if (lQueries !== null) {
            lQueries.detachView(removedLView[TVIEW]);
        }
        viewToDetach[PARENT] = null;
        viewToDetach[NEXT] = null;
        // Unsets the attached flag
        viewToDetach[FLAGS] &= ~128 /* LViewFlags.Attached */;
    }
    return viewToDetach;
}
/**
 * A standalone function which destroys an LView,
 * conducting clean up (e.g. removing listeners, calling onDestroys).
 *
 * @param tView The `TView' of the `LView` to be destroyed
 * @param lView The view to be destroyed.
 */
export function destroyLView(tView, lView) {
    if (!(lView[FLAGS] & 256 /* LViewFlags.Destroyed */)) {
        const renderer = lView[RENDERER];
        lView[REACTIVE_TEMPLATE_CONSUMER]?.destroy();
        lView[REACTIVE_HOST_BINDING_CONSUMER]?.destroy();
        if (renderer.destroyNode) {
            applyView(tView, lView, renderer, 3 /* WalkTNodeTreeAction.Destroy */, null, null);
        }
        destroyViewTree(lView);
    }
}
/**
 * Calls onDestroys hooks for all directives and pipes in a given view and then removes all
 * listeners. Listeners are removed as the last step so events delivered in the onDestroys hooks
 * can be propagated to @Output listeners.
 *
 * @param tView `TView` for the `LView` to clean up.
 * @param lView The LView to clean up
 */
function cleanUpView(tView, lView) {
    if (!(lView[FLAGS] & 256 /* LViewFlags.Destroyed */)) {
        // Usually the Attached flag is removed when the view is detached from its parent, however
        // if it's a root view, the flag won't be unset hence why we're also removing on destroy.
        lView[FLAGS] &= ~128 /* LViewFlags.Attached */;
        // Mark the LView as destroyed *before* executing the onDestroy hooks. An onDestroy hook
        // runs arbitrary user code, which could include its own `viewRef.destroy()` (or similar). If
        // We don't flag the view as destroyed before the hooks, this could lead to an infinite loop.
        // This also aligns with the ViewEngine behavior. It also means that the onDestroy hook is
        // really more of an "afterDestroy" hook if you think about it.
        lView[FLAGS] |= 256 /* LViewFlags.Destroyed */;
        executeOnDestroys(tView, lView);
        processCleanups(tView, lView);
        // For component views only, the local renderer is destroyed at clean up time.
        if (lView[TVIEW].type === 1 /* TViewType.Component */) {
            ngDevMode && ngDevMode.rendererDestroy++;
            lView[RENDERER].destroy();
        }
        const declarationContainer = lView[DECLARATION_LCONTAINER];
        // we are dealing with an embedded view that is still inserted into a container
        if (declarationContainer !== null && isLContainer(lView[PARENT])) {
            // and this is a projected view
            if (declarationContainer !== lView[PARENT]) {
                detachMovedView(declarationContainer, lView);
            }
            // For embedded views still attached to a container: remove query result from this view.
            const lQueries = lView[QUERIES];
            if (lQueries !== null) {
                lQueries.detachView(tView);
            }
        }
        // Unregister the view once everything else has been cleaned up.
        unregisterLView(lView);
    }
}
/** Removes listeners and unsubscribes from output subscriptions */
function processCleanups(tView, lView) {
    const tCleanup = tView.cleanup;
    const lCleanup = lView[CLEANUP];
    if (tCleanup !== null) {
        for (let i = 0; i < tCleanup.length - 1; i += 2) {
            if (typeof tCleanup[i] === 'string') {
                // This is a native DOM listener. It will occupy 4 entries in the TCleanup array (hence i +=
                // 2 at the end of this block).
                const targetIdx = tCleanup[i + 3];
                ngDevMode && assertNumber(targetIdx, 'cleanup target must be a number');
                if (targetIdx >= 0) {
                    // unregister
                    lCleanup[targetIdx]();
                }
                else {
                    // Subscription
                    lCleanup[-targetIdx].unsubscribe();
                }
                i += 2;
            }
            else {
                // This is a cleanup function that is grouped with the index of its context
                const context = lCleanup[tCleanup[i + 1]];
                tCleanup[i].call(context);
            }
        }
    }
    if (lCleanup !== null) {
        lView[CLEANUP] = null;
    }
    const destroyHooks = lView[ON_DESTROY_HOOKS];
    if (destroyHooks !== null) {
        for (let i = 0; i < destroyHooks.length; i++) {
            const destroyHooksFn = destroyHooks[i];
            ngDevMode && assertFunction(destroyHooksFn, 'Expecting destroy hook to be a function.');
            destroyHooksFn();
        }
        lView[ON_DESTROY_HOOKS] = null;
    }
}
/** Calls onDestroy hooks for this view */
function executeOnDestroys(tView, lView) {
    let destroyHooks;
    if (tView != null && (destroyHooks = tView.destroyHooks) != null) {
        for (let i = 0; i < destroyHooks.length; i += 2) {
            const context = lView[destroyHooks[i]];
            // Only call the destroy hook if the context has been requested.
            if (!(context instanceof NodeInjectorFactory)) {
                const toCall = destroyHooks[i + 1];
                if (Array.isArray(toCall)) {
                    for (let j = 0; j < toCall.length; j += 2) {
                        const callContext = context[toCall[j]];
                        const hook = toCall[j + 1];
                        profiler(4 /* ProfilerEvent.LifecycleHookStart */, callContext, hook);
                        try {
                            hook.call(callContext);
                        }
                        finally {
                            profiler(5 /* ProfilerEvent.LifecycleHookEnd */, callContext, hook);
                        }
                    }
                }
                else {
                    profiler(4 /* ProfilerEvent.LifecycleHookStart */, context, toCall);
                    try {
                        toCall.call(context);
                    }
                    finally {
                        profiler(5 /* ProfilerEvent.LifecycleHookEnd */, context, toCall);
                    }
                }
            }
        }
    }
}
/**
 * Returns a native element if a node can be inserted into the given parent.
 *
 * There are two reasons why we may not be able to insert a element immediately.
 * - Projection: When creating a child content element of a component, we have to skip the
 *   insertion because the content of a component will be projected.
 *   `<component><content>delayed due to projection</content></component>`
 * - Parent container is disconnected: This can happen when we are inserting a view into
 *   parent container, which itself is disconnected. For example the parent container is part
 *   of a View which has not be inserted or is made for projection but has not been inserted
 *   into destination.
 *
 * @param tView: Current `TView`.
 * @param tNode: `TNode` for which we wish to retrieve render parent.
 * @param lView: Current `LView`.
 */
export function getParentRElement(tView, tNode, lView) {
    return getClosestRElement(tView, tNode.parent, lView);
}
/**
 * Get closest `RElement` or `null` if it can't be found.
 *
 * If `TNode` is `TNodeType.Element` => return `RElement` at `LView[tNode.index]` location.
 * If `TNode` is `TNodeType.ElementContainer|IcuContain` => return the parent (recursively).
 * If `TNode` is `null` then return host `RElement`:
 *   - return `null` if projection
 *   - return `null` if parent container is disconnected (we have no parent.)
 *
 * @param tView: Current `TView`.
 * @param tNode: `TNode` for which we wish to retrieve `RElement` (or `null` if host element is
 *     needed).
 * @param lView: Current `LView`.
 * @returns `null` if the `RElement` can't be determined at this time (no parent / projection)
 */
export function getClosestRElement(tView, tNode, lView) {
    let parentTNode = tNode;
    // Skip over element and ICU containers as those are represented by a comment node and
    // can't be used as a render parent.
    while (parentTNode !== null &&
        (parentTNode.type & (8 /* TNodeType.ElementContainer */ | 32 /* TNodeType.Icu */))) {
        tNode = parentTNode;
        parentTNode = tNode.parent;
    }
    // If the parent tNode is null, then we are inserting across views: either into an embedded view
    // or a component view.
    if (parentTNode === null) {
        // We are inserting a root element of the component view into the component host element and
        // it should always be eager.
        return lView[HOST];
    }
    else {
        ngDevMode && assertTNodeType(parentTNode, 3 /* TNodeType.AnyRNode */ | 4 /* TNodeType.Container */);
        const { componentOffset } = parentTNode;
        if (componentOffset > -1) {
            ngDevMode && assertTNodeForLView(parentTNode, lView);
            const { encapsulation } = tView.data[parentTNode.directiveStart + componentOffset];
            // We've got a parent which is an element in the current view. We just need to verify if the
            // parent element is not a component. Component's content nodes are not inserted immediately
            // because they will be projected, and so doing insert at this point would be wasteful.
            // Since the projection would then move it to its final destination. Note that we can't
            // make this assumption when using the Shadow DOM, because the native projection placeholders
            // (<content> or <slot>) have to be in place as elements are being inserted.
            if (encapsulation === ViewEncapsulation.None ||
                encapsulation === ViewEncapsulation.Emulated) {
                return null;
            }
        }
        return getNativeByTNode(parentTNode, lView);
    }
}
/**
 * Inserts a native node before another native node for a given parent.
 * This is a utility function that can be used when native nodes were determined.
 */
export function nativeInsertBefore(renderer, parent, child, beforeNode, isMove) {
    ngDevMode && ngDevMode.rendererInsertBefore++;
    renderer.insertBefore(parent, child, beforeNode, isMove);
}
function nativeAppendChild(renderer, parent, child) {
    ngDevMode && ngDevMode.rendererAppendChild++;
    ngDevMode && assertDefined(parent, 'parent node must be defined');
    renderer.appendChild(parent, child);
}
function nativeAppendOrInsertBefore(renderer, parent, child, beforeNode, isMove) {
    if (beforeNode !== null) {
        nativeInsertBefore(renderer, parent, child, beforeNode, isMove);
    }
    else {
        nativeAppendChild(renderer, parent, child);
    }
}
/** Removes a node from the DOM given its native parent. */
function nativeRemoveChild(renderer, parent, child, isHostElement) {
    renderer.removeChild(parent, child, isHostElement);
}
/** Checks if an element is a `<template>` node. */
function isTemplateNode(node) {
    return node.tagName === 'TEMPLATE' && node.content !== undefined;
}
/**
 * Returns a native parent of a given native node.
 */
export function nativeParentNode(renderer, node) {
    return renderer.parentNode(node);
}
/**
 * Returns a native sibling of a given native node.
 */
export function nativeNextSibling(renderer, node) {
    return renderer.nextSibling(node);
}
/**
 * Find a node in front of which `currentTNode` should be inserted.
 *
 * This method determines the `RNode` in front of which we should insert the `currentRNode`. This
 * takes `TNode.insertBeforeIndex` into account if i18n code has been invoked.
 *
 * @param parentTNode parent `TNode`
 * @param currentTNode current `TNode` (The node which we would like to insert into the DOM)
 * @param lView current `LView`
 */
function getInsertInFrontOfRNode(parentTNode, currentTNode, lView) {
    return _getInsertInFrontOfRNodeWithI18n(parentTNode, currentTNode, lView);
}
/**
 * Find a node in front of which `currentTNode` should be inserted. (Does not take i18n into
 * account)
 *
 * This method determines the `RNode` in front of which we should insert the `currentRNode`. This
 * does not take `TNode.insertBeforeIndex` into account.
 *
 * @param parentTNode parent `TNode`
 * @param currentTNode current `TNode` (The node which we would like to insert into the DOM)
 * @param lView current `LView`
 */
export function getInsertInFrontOfRNodeWithNoI18n(parentTNode, currentTNode, lView) {
    if (parentTNode.type & (8 /* TNodeType.ElementContainer */ | 32 /* TNodeType.Icu */)) {
        return getNativeByTNode(parentTNode, lView);
    }
    return null;
}
/**
 * Tree shakable boundary for `getInsertInFrontOfRNodeWithI18n` function.
 *
 * This function will only be set if i18n code runs.
 */
let _getInsertInFrontOfRNodeWithI18n = getInsertInFrontOfRNodeWithNoI18n;
/**
 * Tree shakable boundary for `processI18nInsertBefore` function.
 *
 * This function will only be set if i18n code runs.
 */
let _processI18nInsertBefore;
export function setI18nHandling(getInsertInFrontOfRNodeWithI18n, processI18nInsertBefore) {
    _getInsertInFrontOfRNodeWithI18n = getInsertInFrontOfRNodeWithI18n;
    _processI18nInsertBefore = processI18nInsertBefore;
}
/**
 * Appends the `child` native node (or a collection of nodes) to the `parent`.
 *
 * @param tView The `TView' to be appended
 * @param lView The current LView
 * @param childRNode The native child (or children) that should be appended
 * @param childTNode The TNode of the child element
 */
export function appendChild(tView, lView, childRNode, childTNode) {
    const parentRNode = getParentRElement(tView, childTNode, lView);
    const renderer = lView[RENDERER];
    const parentTNode = childTNode.parent || lView[T_HOST];
    const anchorNode = getInsertInFrontOfRNode(parentTNode, childTNode, lView);
    if (parentRNode != null) {
        if (Array.isArray(childRNode)) {
            for (let i = 0; i < childRNode.length; i++) {
                nativeAppendOrInsertBefore(renderer, parentRNode, childRNode[i], anchorNode, false);
            }
        }
        else {
            nativeAppendOrInsertBefore(renderer, parentRNode, childRNode, anchorNode, false);
        }
    }
    _processI18nInsertBefore !== undefined &&
        _processI18nInsertBefore(renderer, childTNode, lView, childRNode, parentRNode);
}
/**
 * Returns the first native node for a given LView, starting from the provided TNode.
 *
 * Native nodes are returned in the order in which those appear in the native tree (DOM).
 */
export function getFirstNativeNode(lView, tNode) {
    if (tNode !== null) {
        ngDevMode &&
            assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */ | 12 /* TNodeType.AnyContainer */ | 32 /* TNodeType.Icu */ | 16 /* TNodeType.Projection */);
        const tNodeType = tNode.type;
        if (tNodeType & 3 /* TNodeType.AnyRNode */) {
            return getNativeByTNode(tNode, lView);
        }
        else if (tNodeType & 4 /* TNodeType.Container */) {
            return getBeforeNodeForView(-1, lView[tNode.index]);
        }
        else if (tNodeType & 8 /* TNodeType.ElementContainer */) {
            const elIcuContainerChild = tNode.child;
            if (elIcuContainerChild !== null) {
                return getFirstNativeNode(lView, elIcuContainerChild);
            }
            else {
                const rNodeOrLContainer = lView[tNode.index];
                if (isLContainer(rNodeOrLContainer)) {
                    return getBeforeNodeForView(-1, rNodeOrLContainer);
                }
                else {
                    return unwrapRNode(rNodeOrLContainer);
                }
            }
        }
        else if (tNodeType & 32 /* TNodeType.Icu */) {
            let nextRNode = icuContainerIterate(tNode, lView);
            let rNode = nextRNode();
            // If the ICU container has no nodes, than we use the ICU anchor as the node.
            return rNode || unwrapRNode(lView[tNode.index]);
        }
        else {
            const projectionNodes = getProjectionNodes(lView, tNode);
            if (projectionNodes !== null) {
                if (Array.isArray(projectionNodes)) {
                    return projectionNodes[0];
                }
                const parentView = getLViewParent(lView[DECLARATION_COMPONENT_VIEW]);
                ngDevMode && assertParentView(parentView);
                return getFirstNativeNode(parentView, projectionNodes);
            }
            else {
                return getFirstNativeNode(lView, tNode.next);
            }
        }
    }
    return null;
}
export function getProjectionNodes(lView, tNode) {
    if (tNode !== null) {
        const componentView = lView[DECLARATION_COMPONENT_VIEW];
        const componentHost = componentView[T_HOST];
        const slotIdx = tNode.projection;
        ngDevMode && assertProjectionSlots(lView);
        return componentHost.projection[slotIdx];
    }
    return null;
}
export function getBeforeNodeForView(viewIndexInContainer, lContainer) {
    const nextViewIndex = CONTAINER_HEADER_OFFSET + viewIndexInContainer + 1;
    if (nextViewIndex < lContainer.length) {
        const lView = lContainer[nextViewIndex];
        const firstTNodeOfView = lView[TVIEW].firstChild;
        if (firstTNodeOfView !== null) {
            return getFirstNativeNode(lView, firstTNodeOfView);
        }
    }
    return lContainer[NATIVE];
}
/**
 * Removes a native node itself using a given renderer. To remove the node we are looking up its
 * parent from the native tree as not all platforms / browsers support the equivalent of
 * node.remove().
 *
 * @param renderer A renderer to be used
 * @param rNode The native node that should be removed
 * @param isHostElement A flag indicating if a node to be removed is a host of a component.
 */
export function nativeRemoveNode(renderer, rNode, isHostElement) {
    ngDevMode && ngDevMode.rendererRemoveNode++;
    const nativeParent = nativeParentNode(renderer, rNode);
    if (nativeParent) {
        nativeRemoveChild(renderer, nativeParent, rNode, isHostElement);
    }
}
/**
 * Clears the contents of a given RElement.
 *
 * @param rElement the native RElement to be cleared
 */
export function clearElementContents(rElement) {
    rElement.textContent = '';
}
/**
 * Performs the operation of `action` on the node. Typically this involves inserting or removing
 * nodes on the LView or projection boundary.
 */
function applyNodes(renderer, action, tNode, lView, parentRElement, beforeNode, isProjection) {
    while (tNode != null) {
        ngDevMode && assertTNodeForLView(tNode, lView);
        ngDevMode &&
            assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */ | 12 /* TNodeType.AnyContainer */ | 16 /* TNodeType.Projection */ | 32 /* TNodeType.Icu */);
        const rawSlotValue = lView[tNode.index];
        const tNodeType = tNode.type;
        if (isProjection) {
            if (action === 0 /* WalkTNodeTreeAction.Create */) {
                rawSlotValue && attachPatchData(unwrapRNode(rawSlotValue), lView);
                tNode.flags |= 2 /* TNodeFlags.isProjected */;
            }
        }
        if ((tNode.flags & 32 /* TNodeFlags.isDetached */) !== 32 /* TNodeFlags.isDetached */) {
            if (tNodeType & 8 /* TNodeType.ElementContainer */) {
                applyNodes(renderer, action, tNode.child, lView, parentRElement, beforeNode, false);
                applyToElementOrContainer(action, renderer, parentRElement, rawSlotValue, beforeNode);
            }
            else if (tNodeType & 32 /* TNodeType.Icu */) {
                const nextRNode = icuContainerIterate(tNode, lView);
                let rNode;
                while (rNode = nextRNode()) {
                    applyToElementOrContainer(action, renderer, parentRElement, rNode, beforeNode);
                }
                applyToElementOrContainer(action, renderer, parentRElement, rawSlotValue, beforeNode);
            }
            else if (tNodeType & 16 /* TNodeType.Projection */) {
                applyProjectionRecursive(renderer, action, lView, tNode, parentRElement, beforeNode);
            }
            else {
                ngDevMode && assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */ | 4 /* TNodeType.Container */);
                applyToElementOrContainer(action, renderer, parentRElement, rawSlotValue, beforeNode);
            }
        }
        tNode = isProjection ? tNode.projectionNext : tNode.next;
    }
}
function applyView(tView, lView, renderer, action, parentRElement, beforeNode) {
    applyNodes(renderer, action, tView.firstChild, lView, parentRElement, beforeNode, false);
}
/**
 * `applyProjection` performs operation on the projection.
 *
 * Inserting a projection requires us to locate the projected nodes from the parent component. The
 * complication is that those nodes themselves could be re-projected from their parent component.
 *
 * @param tView The `TView` of `LView` which needs to be inserted, detached, destroyed
 * @param lView The `LView` which needs to be inserted, detached, destroyed.
 * @param tProjectionNode node to project
 */
export function applyProjection(tView, lView, tProjectionNode) {
    const renderer = lView[RENDERER];
    const parentRNode = getParentRElement(tView, tProjectionNode, lView);
    const parentTNode = tProjectionNode.parent || lView[T_HOST];
    let beforeNode = getInsertInFrontOfRNode(parentTNode, tProjectionNode, lView);
    applyProjectionRecursive(renderer, 0 /* WalkTNodeTreeAction.Create */, lView, tProjectionNode, parentRNode, beforeNode);
}
/**
 * `applyProjectionRecursive` performs operation on the projection specified by `action` (insert,
 * detach, destroy)
 *
 * Inserting a projection requires us to locate the projected nodes from the parent component. The
 * complication is that those nodes themselves could be re-projected from their parent component.
 *
 * @param renderer Render to use
 * @param action action to perform (insert, detach, destroy)
 * @param lView The LView which needs to be inserted, detached, destroyed.
 * @param tProjectionNode node to project
 * @param parentRElement parent DOM element for insertion/removal.
 * @param beforeNode Before which node the insertions should happen.
 */
function applyProjectionRecursive(renderer, action, lView, tProjectionNode, parentRElement, beforeNode) {
    const componentLView = lView[DECLARATION_COMPONENT_VIEW];
    const componentNode = componentLView[T_HOST];
    ngDevMode &&
        assertEqual(typeof tProjectionNode.projection, 'number', 'expecting projection index');
    const nodeToProjectOrRNodes = componentNode.projection[tProjectionNode.projection];
    if (Array.isArray(nodeToProjectOrRNodes)) {
        // This should not exist, it is a bit of a hack. When we bootstrap a top level node and we
        // need to support passing projectable nodes, so we cheat and put them in the TNode
        // of the Host TView. (Yes we put instance info at the T Level). We can get away with it
        // because we know that that TView is not shared and therefore it will not be a problem.
        // This should be refactored and cleaned up.
        for (let i = 0; i < nodeToProjectOrRNodes.length; i++) {
            const rNode = nodeToProjectOrRNodes[i];
            applyToElementOrContainer(action, renderer, parentRElement, rNode, beforeNode);
        }
    }
    else {
        let nodeToProject = nodeToProjectOrRNodes;
        const projectedComponentLView = componentLView[PARENT];
        applyNodes(renderer, action, nodeToProject, projectedComponentLView, parentRElement, beforeNode, true);
    }
}
/**
 * `applyContainer` performs an operation on the container and its views as specified by
 * `action` (insert, detach, destroy)
 *
 * Inserting a Container is complicated by the fact that the container may have Views which
 * themselves have containers or projections.
 *
 * @param renderer Renderer to use
 * @param action action to perform (insert, detach, destroy)
 * @param lContainer The LContainer which needs to be inserted, detached, destroyed.
 * @param parentRElement parent DOM element for insertion/removal.
 * @param beforeNode Before which node the insertions should happen.
 */
function applyContainer(renderer, action, lContainer, parentRElement, beforeNode) {
    ngDevMode && assertLContainer(lContainer);
    const anchor = lContainer[NATIVE]; // LContainer has its own before node.
    const native = unwrapRNode(lContainer);
    // An LContainer can be created dynamically on any node by injecting ViewContainerRef.
    // Asking for a ViewContainerRef on an element will result in a creation of a separate anchor
    // node (comment in the DOM) that will be different from the LContainer's host node. In this
    // particular case we need to execute action on 2 nodes:
    // - container's host node (this is done in the executeActionOnElementOrContainer)
    // - container's host node (this is done here)
    if (anchor !== native) {
        // This is very strange to me (Misko). I would expect that the native is same as anchor. I
        // don't see a reason why they should be different, but they are.
        //
        // If they are we need to process the second anchor as well.
        applyToElementOrContainer(action, renderer, parentRElement, anchor, beforeNode);
    }
    for (let i = CONTAINER_HEADER_OFFSET; i < lContainer.length; i++) {
        const lView = lContainer[i];
        applyView(lView[TVIEW], lView, renderer, action, parentRElement, anchor);
    }
}
/**
 * Writes class/style to element.
 *
 * @param renderer Renderer to use.
 * @param isClassBased `true` if it should be written to `class` (`false` to write to `style`)
 * @param rNode The Node to write to.
 * @param prop Property to write to. This would be the class/style name.
 * @param value Value to write. If `null`/`undefined`/`false` this is considered a remove (set/add
 *        otherwise).
 */
export function applyStyling(renderer, isClassBased, rNode, prop, value) {
    if (isClassBased) {
        // We actually want JS true/false here because any truthy value should add the class
        if (!value) {
            ngDevMode && ngDevMode.rendererRemoveClass++;
            renderer.removeClass(rNode, prop);
        }
        else {
            ngDevMode && ngDevMode.rendererAddClass++;
            renderer.addClass(rNode, prop);
        }
    }
    else {
        let flags = prop.indexOf('-') === -1 ? undefined : RendererStyleFlags2.DashCase;
        if (value == null /** || value === undefined */) {
            ngDevMode && ngDevMode.rendererRemoveStyle++;
            renderer.removeStyle(rNode, prop, flags);
        }
        else {
            // A value is important if it ends with `!important`. The style
            // parser strips any semicolons at the end of the value.
            const isImportant = typeof value === 'string' ? value.endsWith('!important') : false;
            if (isImportant) {
                // !important has to be stripped from the value for it to be valid.
                value = value.slice(0, -10);
                flags |= RendererStyleFlags2.Important;
            }
            ngDevMode && ngDevMode.rendererSetStyle++;
            renderer.setStyle(rNode, prop, value, flags);
        }
    }
}
/**
 * Write `cssText` to `RElement`.
 *
 * This function does direct write without any reconciliation. Used for writing initial values, so
 * that static styling values do not pull in the style parser.
 *
 * @param renderer Renderer to use
 * @param element The element which needs to be updated.
 * @param newValue The new class list to write.
 */
export function writeDirectStyle(renderer, element, newValue) {
    ngDevMode && assertString(newValue, '\'newValue\' should be a string');
    renderer.setAttribute(element, 'style', newValue);
    ngDevMode && ngDevMode.rendererSetStyle++;
}
/**
 * Write `className` to `RElement`.
 *
 * This function does direct write without any reconciliation. Used for writing initial values, so
 * that static styling values do not pull in the style parser.
 *
 * @param renderer Renderer to use
 * @param element The element which needs to be updated.
 * @param newValue The new class list to write.
 */
export function writeDirectClass(renderer, element, newValue) {
    ngDevMode && assertString(newValue, '\'newValue\' should be a string');
    if (newValue === '') {
        // There are tests in `google3` which expect `element.getAttribute('class')` to be `null`.
        renderer.removeAttribute(element, 'class');
    }
    else {
        renderer.setAttribute(element, 'class', newValue);
    }
    ngDevMode && ngDevMode.rendererSetClassName++;
}
/** Sets up the static DOM attributes on an `RNode`. */
export function setupStaticAttributes(renderer, element, tNode) {
    const { mergedAttrs, classes, styles } = tNode;
    if (mergedAttrs !== null) {
        setUpAttributes(renderer, element, mergedAttrs);
    }
    if (classes !== null) {
        writeDirectClass(renderer, element, classes);
    }
    if (styles !== null) {
        writeDirectStyle(renderer, element, styles);
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibm9kZV9tYW5pcHVsYXRpb24uanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL25vZGVfbWFuaXB1bGF0aW9uLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxpQkFBaUIsRUFBQyxNQUFNLGtCQUFrQixDQUFDO0FBQ25ELE9BQU8sRUFBQyxtQkFBbUIsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBQ3hELE9BQU8sRUFBQyxVQUFVLEVBQUUsZUFBZSxFQUFDLE1BQU0scUJBQXFCLENBQUM7QUFDaEUsT0FBTyxFQUFDLGFBQWEsRUFBRSxXQUFXLEVBQUUsY0FBYyxFQUFFLFlBQVksRUFBRSxZQUFZLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUN0RyxPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSxhQUFhLENBQUM7QUFFOUMsT0FBTyxFQUFDLGdCQUFnQixFQUFFLFdBQVcsRUFBRSxnQkFBZ0IsRUFBRSxxQkFBcUIsRUFBRSxtQkFBbUIsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUNySCxPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0scUJBQXFCLENBQUM7QUFDcEQsT0FBTyxFQUFDLG1CQUFtQixFQUFDLE1BQU0sMEJBQTBCLENBQUM7QUFDN0QsT0FBTyxFQUFDLHVCQUF1QixFQUFFLHNCQUFzQixFQUFjLFdBQVcsRUFBRSxNQUFNLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUV4SCxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSx1QkFBdUIsQ0FBQztBQUMxRCxPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0sNkJBQTZCLENBQUM7QUFJNUQsT0FBTyxFQUFDLFlBQVksRUFBRSxPQUFPLEVBQUMsTUFBTSwwQkFBMEIsQ0FBQztBQUMvRCxPQUFPLEVBQUMsVUFBVSxFQUFFLE9BQU8sRUFBRSwwQkFBMEIsRUFBRSxzQkFBc0IsRUFBbUIsS0FBSyxFQUFvQixJQUFJLEVBQXFCLElBQUksRUFBRSxnQkFBZ0IsRUFBRSxNQUFNLEVBQUUsT0FBTyxFQUFFLDhCQUE4QixFQUFFLDBCQUEwQixFQUFFLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxFQUFtQixNQUFNLG1CQUFtQixDQUFDO0FBQzdULE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFDOUMsT0FBTyxFQUFDLFFBQVEsRUFBZ0IsTUFBTSxZQUFZLENBQUM7QUFDbkQsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBQ25ELE9BQU8sRUFBQyxjQUFjLEVBQUMsTUFBTSw2QkFBNkIsQ0FBQztBQUMzRCxPQUFPLEVBQUMsb0JBQW9CLEVBQUUsZ0JBQWdCLEVBQUUsV0FBVyxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFxQnRGOzs7R0FHRztBQUNILFNBQVMseUJBQXlCLENBQzlCLE1BQTJCLEVBQUUsUUFBa0IsRUFBRSxNQUFxQixFQUN0RSxhQUFxQyxFQUFFLFVBQXVCO0lBQ2hFLCtGQUErRjtJQUMvRiwwRkFBMEY7SUFDMUYsOEZBQThGO0lBQzlGLHFCQUFxQjtJQUNyQixJQUFJLGFBQWEsSUFBSSxJQUFJLEVBQUU7UUFDekIsSUFBSSxVQUFnQyxDQUFDO1FBQ3JDLElBQUksV0FBVyxHQUFHLEtBQUssQ0FBQztRQUN4Qix5RkFBeUY7UUFDekYsK0ZBQStGO1FBQy9GLDZFQUE2RTtRQUM3RSxJQUFJLFlBQVksQ0FBQyxhQUFhLENBQUMsRUFBRTtZQUMvQixVQUFVLEdBQUcsYUFBYSxDQUFDO1NBQzVCO2FBQU0sSUFBSSxPQUFPLENBQUMsYUFBYSxDQUFDLEVBQUU7WUFDakMsV0FBVyxHQUFHLElBQUksQ0FBQztZQUNuQixTQUFTLElBQUksYUFBYSxDQUFDLGFBQWEsQ0FBQyxJQUFJLENBQUMsRUFBRSw0Q0FBNEMsQ0FBQyxDQUFDO1lBQzlGLGFBQWEsR0FBRyxhQUFhLENBQUMsSUFBSSxDQUFFLENBQUM7U0FDdEM7UUFDRCxNQUFNLEtBQUssR0FBVSxXQUFXLENBQUMsYUFBYSxDQUFDLENBQUM7UUFFaEQsSUFBSSxNQUFNLHVDQUErQixJQUFJLE1BQU0sS0FBSyxJQUFJLEVBQUU7WUFDNUQsSUFBSSxVQUFVLElBQUksSUFBSSxFQUFFO2dCQUN0QixpQkFBaUIsQ0FBQyxRQUFRLEVBQUUsTUFBTSxFQUFFLEtBQUssQ0FBQyxDQUFDO2FBQzVDO2lCQUFNO2dCQUNMLGtCQUFrQixDQUFDLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxFQUFFLFVBQVUsSUFBSSxJQUFJLEVBQUUsSUFBSSxDQUFDLENBQUM7YUFDdkU7U0FDRjthQUFNLElBQUksTUFBTSx1Q0FBK0IsSUFBSSxNQUFNLEtBQUssSUFBSSxFQUFFO1lBQ25FLGtCQUFrQixDQUFDLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxFQUFFLFVBQVUsSUFBSSxJQUFJLEVBQUUsSUFBSSxDQUFDLENBQUM7U0FDdkU7YUFBTSxJQUFJLE1BQU0sdUNBQStCLEVBQUU7WUFDaEQsZ0JBQWdCLENBQUMsUUFBUSxFQUFFLEtBQUssRUFBRSxXQUFXLENBQUMsQ0FBQztTQUNoRDthQUFNLElBQUksTUFBTSx3Q0FBZ0MsRUFBRTtZQUNqRCxTQUFTLElBQUksU0FBUyxDQUFDLG1CQUFtQixFQUFFLENBQUM7WUFDN0MsUUFBUSxDQUFDLFdBQVksQ0FBQyxLQUFLLENBQUMsQ0FBQztTQUM5QjtRQUNELElBQUksVUFBVSxJQUFJLElBQUksRUFBRTtZQUN0QixjQUFjLENBQUMsUUFBUSxFQUFFLE1BQU0sRUFBRSxVQUFVLEVBQUUsTUFBTSxFQUFFLFVBQVUsQ0FBQyxDQUFDO1NBQ2xFO0tBQ0Y7QUFDSCxDQUFDO0FBRUQsTUFBTSxVQUFVLGNBQWMsQ0FBQyxRQUFrQixFQUFFLEtBQWE7SUFDOUQsU0FBUyxJQUFJLFNBQVMsQ0FBQyxzQkFBc0IsRUFBRSxDQUFDO0lBQ2hELFNBQVMsSUFBSSxTQUFTLENBQUMsZUFBZSxFQUFFLENBQUM7SUFDekMsT0FBTyxRQUFRLENBQUMsVUFBVSxDQUFDLEtBQUssQ0FBQyxDQUFDO0FBQ3BDLENBQUM7QUFFRCxNQUFNLFVBQVUsY0FBYyxDQUFDLFFBQWtCLEVBQUUsS0FBWSxFQUFFLEtBQWE7SUFDNUUsU0FBUyxJQUFJLFNBQVMsQ0FBQyxlQUFlLEVBQUUsQ0FBQztJQUN6QyxRQUFRLENBQUMsUUFBUSxDQUFDLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztBQUNsQyxDQUFDO0FBRUQsTUFBTSxVQUFVLGlCQUFpQixDQUFDLFFBQWtCLEVBQUUsS0FBYTtJQUNqRSxTQUFTLElBQUksU0FBUyxDQUFDLHFCQUFxQixFQUFFLENBQUM7SUFDL0MsT0FBTyxRQUFRLENBQUMsYUFBYSxDQUFDLGlCQUFpQixDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUM7QUFDMUQsQ0FBQztBQUVEOzs7Ozs7R0FNRztBQUNILE1BQU0sVUFBVSxpQkFBaUIsQ0FDN0IsUUFBa0IsRUFBRSxJQUFZLEVBQUUsU0FBc0I7SUFDMUQsU0FBUyxJQUFJLFNBQVMsQ0FBQyxxQkFBcUIsRUFBRSxDQUFDO0lBQy9DLE9BQU8sUUFBUSxDQUFDLGFBQWEsQ0FBQyxJQUFJLEVBQUUsU0FBUyxDQUFDLENBQUM7QUFDakQsQ0FBQztBQUdEOzs7Ozs7Ozs7R0FTRztBQUNILE1BQU0sVUFBVSx1QkFBdUIsQ0FBQyxLQUFZLEVBQUUsS0FBWTtJQUNoRSxNQUFNLFFBQVEsR0FBRyxLQUFLLENBQUMsUUFBUSxDQUFDLENBQUM7SUFDakMsU0FBUyxDQUFDLEtBQUssRUFBRSxLQUFLLEVBQUUsUUFBUSxzQ0FBOEIsSUFBSSxFQUFFLElBQUksQ0FBQyxDQUFDO0lBQzFFLEtBQUssQ0FBQyxJQUFJLENBQUMsR0FBRyxJQUFJLENBQUM7SUFDbkIsS0FBSyxDQUFDLE1BQU0sQ0FBQyxHQUFHLElBQUksQ0FBQztBQUN2QixDQUFDO0FBRUQ7Ozs7Ozs7Ozs7Ozs7R0FhRztBQUNILE1BQU0sVUFBVSxrQkFBa0IsQ0FDOUIsS0FBWSxFQUFFLFdBQWtCLEVBQUUsUUFBa0IsRUFBRSxLQUFZLEVBQUUsZ0JBQTBCLEVBQzlGLFVBQXNCO0lBQ3hCLEtBQUssQ0FBQyxJQUFJLENBQUMsR0FBRyxnQkFBZ0IsQ0FBQztJQUMvQixLQUFLLENBQUMsTUFBTSxDQUFDLEdBQUcsV0FBVyxDQUFDO0lBQzVCLFNBQVMsQ0FBQyxLQUFLLEVBQUUsS0FBSyxFQUFFLFFBQVEsc0NBQThCLGdCQUFnQixFQUFFLFVBQVUsQ0FBQyxDQUFDO0FBQzlGLENBQUM7QUFHRDs7Ozs7R0FLRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FBQyxLQUFZLEVBQUUsS0FBWTtJQUN6RCxTQUFTLENBQUMsS0FBSyxFQUFFLEtBQUssRUFBRSxLQUFLLENBQUMsUUFBUSxDQUFDLHNDQUE4QixJQUFJLEVBQUUsSUFBSSxDQUFDLENBQUM7QUFDbkYsQ0FBQztBQUVEOzs7Ozs7Ozs7Ozs7R0FZRztBQUNILE1BQU0sVUFBVSxlQUFlLENBQUMsUUFBZTtJQUM3QyxvRUFBb0U7SUFDcEUsSUFBSSxpQkFBaUIsR0FBRyxRQUFRLENBQUMsVUFBVSxDQUFDLENBQUM7SUFDN0MsSUFBSSxDQUFDLGlCQUFpQixFQUFFO1FBQ3RCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxLQUFLLENBQUMsRUFBRSxRQUFRLENBQUMsQ0FBQztLQUMvQztJQUVELE9BQU8saUJBQWlCLEVBQUU7UUFDeEIsSUFBSSxJQUFJLEdBQTBCLElBQUksQ0FBQztRQUV2QyxJQUFJLE9BQU8sQ0FBQyxpQkFBaUIsQ0FBQyxFQUFFO1lBQzlCLG9DQUFvQztZQUNwQyxJQUFJLEdBQUcsaUJBQWlCLENBQUMsVUFBVSxDQUFDLENBQUM7U0FDdEM7YUFBTTtZQUNMLFNBQVMsSUFBSSxnQkFBZ0IsQ0FBQyxpQkFBaUIsQ0FBQyxDQUFDO1lBQ2pELGtEQUFrRDtZQUNsRCxNQUFNLFNBQVMsR0FBb0IsaUJBQWlCLENBQUMsdUJBQXVCLENBQUMsQ0FBQztZQUM5RSxJQUFJLFNBQVM7Z0JBQUUsSUFBSSxHQUFHLFNBQVMsQ0FBQztTQUNqQztRQUVELElBQUksQ0FBQyxJQUFJLEVBQUU7WUFDVCxxRUFBcUU7WUFDckUsZ0RBQWdEO1lBQ2hELE9BQU8saUJBQWlCLElBQUksQ0FBQyxpQkFBa0IsQ0FBQyxJQUFJLENBQUMsSUFBSSxpQkFBaUIsS0FBSyxRQUFRLEVBQUU7Z0JBQ3ZGLElBQUksT0FBTyxDQUFDLGlCQUFpQixDQUFDLEVBQUU7b0JBQzlCLFdBQVcsQ0FBQyxpQkFBaUIsQ0FBQyxLQUFLLENBQUMsRUFBRSxpQkFBaUIsQ0FBQyxDQUFDO2lCQUMxRDtnQkFDRCxpQkFBaUIsR0FBRyxpQkFBaUIsQ0FBQyxNQUFNLENBQUMsQ0FBQzthQUMvQztZQUNELElBQUksaUJBQWlCLEtBQUssSUFBSTtnQkFBRSxpQkFBaUIsR0FBRyxRQUFRLENBQUM7WUFDN0QsSUFBSSxPQUFPLENBQUMsaUJBQWlCLENBQUMsRUFBRTtnQkFDOUIsV0FBVyxDQUFDLGlCQUFpQixDQUFDLEtBQUssQ0FBQyxFQUFFLGlCQUFpQixDQUFDLENBQUM7YUFDMUQ7WUFDRCxJQUFJLEdBQUcsaUJBQWlCLElBQUksaUJBQWtCLENBQUMsSUFBSSxDQUFDLENBQUM7U0FDdEQ7UUFDRCxpQkFBaUIsR0FBRyxJQUFJLENBQUM7S0FDMUI7QUFDSCxDQUFDO0FBRUQ7Ozs7Ozs7Ozs7OztHQVlHO0FBQ0gsTUFBTSxVQUFVLFVBQVUsQ0FBQyxLQUFZLEVBQUUsS0FBWSxFQUFFLFVBQXNCLEVBQUUsS0FBYTtJQUMxRixTQUFTLElBQUksV0FBVyxDQUFDLEtBQUssQ0FBQyxDQUFDO0lBQ2hDLFNBQVMsSUFBSSxnQkFBZ0IsQ0FBQyxVQUFVLENBQUMsQ0FBQztJQUMxQyxNQUFNLGdCQUFnQixHQUFHLHVCQUF1QixHQUFHLEtBQUssQ0FBQztJQUN6RCxNQUFNLGVBQWUsR0FBRyxVQUFVLENBQUMsTUFBTSxDQUFDO0lBRTFDLElBQUksS0FBSyxHQUFHLENBQUMsRUFBRTtRQUNiLHlEQUF5RDtRQUN6RCxVQUFVLENBQUMsZ0JBQWdCLEdBQUcsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLEdBQUcsS0FBSyxDQUFDO0tBQ2hEO0lBQ0QsSUFBSSxLQUFLLEdBQUcsZUFBZSxHQUFHLHVCQUF1QixFQUFFO1FBQ3JELEtBQUssQ0FBQyxJQUFJLENBQUMsR0FBRyxVQUFVLENBQUMsZ0JBQWdCLENBQUMsQ0FBQztRQUMzQyxVQUFVLENBQUMsVUFBVSxFQUFFLHVCQUF1QixHQUFHLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztLQUNoRTtTQUFNO1FBQ0wsVUFBVSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsQ0FBQztRQUN2QixLQUFLLENBQUMsSUFBSSxDQUFDLEdBQUcsSUFBSSxDQUFDO0tBQ3BCO0lBRUQsS0FBSyxDQUFDLE1BQU0sQ0FBQyxHQUFHLFVBQVUsQ0FBQztJQUUzQixtRUFBbUU7SUFDbkUsTUFBTSxxQkFBcUIsR0FBRyxLQUFLLENBQUMsc0JBQXNCLENBQUMsQ0FBQztJQUM1RCxJQUFJLHFCQUFxQixLQUFLLElBQUksSUFBSSxVQUFVLEtBQUsscUJBQXFCLEVBQUU7UUFDMUUsY0FBYyxDQUFDLHFCQUFxQixFQUFFLEtBQUssQ0FBQyxDQUFDO0tBQzlDO0lBRUQsOENBQThDO0lBQzlDLE1BQU0sUUFBUSxHQUFHLEtBQUssQ0FBQyxPQUFPLENBQUMsQ0FBQztJQUNoQyxJQUFJLFFBQVEsS0FBSyxJQUFJLEVBQUU7UUFDckIsUUFBUSxDQUFDLFVBQVUsQ0FBQyxLQUFLLENBQUMsQ0FBQztLQUM1QjtJQUVELHlCQUF5QjtJQUN6QixLQUFLLENBQUMsS0FBSyxDQUFDLGlDQUF1QixDQUFDO0FBQ3RDLENBQUM7QUFFRDs7O0dBR0c7QUFDSCxTQUFTLGNBQWMsQ0FBQyxvQkFBZ0MsRUFBRSxLQUFZO0lBQ3BFLFNBQVMsSUFBSSxhQUFhLENBQUMsS0FBSyxFQUFFLGdCQUFnQixDQUFDLENBQUM7SUFDcEQsU0FBUyxJQUFJLGdCQUFnQixDQUFDLG9CQUFvQixDQUFDLENBQUM7SUFDcEQsTUFBTSxVQUFVLEdBQUcsb0JBQW9CLENBQUMsV0FBVyxDQUFDLENBQUM7SUFDckQsTUFBTSxrQkFBa0IsR0FBRyxLQUFLLENBQUMsTUFBTSxDQUFlLENBQUM7SUFDdkQsU0FBUyxJQUFJLGdCQUFnQixDQUFDLGtCQUFrQixDQUFDLENBQUM7SUFDbEQsTUFBTSxzQkFBc0IsR0FBRyxrQkFBa0IsQ0FBQyxNQUFNLENBQUUsQ0FBQywwQkFBMEIsQ0FBQyxDQUFDO0lBQ3ZGLFNBQVMsSUFBSSxhQUFhLENBQUMsc0JBQXNCLEVBQUUsZ0NBQWdDLENBQUMsQ0FBQztJQUNyRixNQUFNLHNCQUFzQixHQUFHLEtBQUssQ0FBQywwQkFBMEIsQ0FBQyxDQUFDO0lBQ2pFLFNBQVMsSUFBSSxhQUFhLENBQUMsc0JBQXNCLEVBQUUsZ0NBQWdDLENBQUMsQ0FBQztJQUNyRixJQUFJLHNCQUFzQixLQUFLLHNCQUFzQixFQUFFO1FBQ3JELDhGQUE4RjtRQUM5Riw0RkFBNEY7UUFDNUYscUNBQXFDO1FBQ3JDLG9CQUFvQixDQUFDLHNCQUFzQixDQUFDLEdBQUcsSUFBSSxDQUFDO0tBQ3JEO0lBQ0QsSUFBSSxVQUFVLEtBQUssSUFBSSxFQUFFO1FBQ3ZCLG9CQUFvQixDQUFDLFdBQVcsQ0FBQyxHQUFHLENBQUMsS0FBSyxDQUFDLENBQUM7S0FDN0M7U0FBTTtRQUNMLFVBQVUsQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLENBQUM7S0FDeEI7QUFDSCxDQUFDO0FBRUQsU0FBUyxlQUFlLENBQUMsb0JBQWdDLEVBQUUsS0FBWTtJQUNyRSxTQUFTLElBQUksZ0JBQWdCLENBQUMsb0JBQW9CLENBQUMsQ0FBQztJQUNwRCxTQUFTO1FBQ0wsYUFBYSxDQUNULG9CQUFvQixDQUFDLFdBQVcsQ0FBQyxFQUNqQywwRUFBMEUsQ0FBQyxDQUFDO0lBQ3BGLE1BQU0sVUFBVSxHQUFHLG9CQUFvQixDQUFDLFdBQVcsQ0FBRSxDQUFDO0lBQ3RELE1BQU0sb0JBQW9CLEdBQUcsVUFBVSxDQUFDLE9BQU8sQ0FBQyxLQUFLLENBQUMsQ0FBQztJQUN2RCxNQUFNLG1CQUFtQixHQUFHLEtBQUssQ0FBQyxNQUFNLENBQWUsQ0FBQztJQUN4RCxTQUFTLElBQUksZ0JBQWdCLENBQUMsbUJBQW1CLENBQUMsQ0FBQztJQUVuRCw2RkFBNkY7SUFDN0Ysb0ZBQW9GO0lBQ3BGLG9CQUFvQixDQUFDLEtBQUssQ0FBQyxDQUFDO0lBRTVCLFVBQVUsQ0FBQyxNQUFNLENBQUMsb0JBQW9CLEVBQUUsQ0FBQyxDQUFDLENBQUM7QUFDN0MsQ0FBQztBQUVEOzs7Ozs7Ozs7R0FTRztBQUNILE1BQU0sVUFBVSxVQUFVLENBQUMsVUFBc0IsRUFBRSxXQUFtQjtJQUNwRSxJQUFJLFVBQVUsQ0FBQyxNQUFNLElBQUksdUJBQXVCO1FBQUUsT0FBTztJQUV6RCxNQUFNLGdCQUFnQixHQUFHLHVCQUF1QixHQUFHLFdBQVcsQ0FBQztJQUMvRCxNQUFNLFlBQVksR0FBRyxVQUFVLENBQUMsZ0JBQWdCLENBQUMsQ0FBQztJQUVsRCxJQUFJLFlBQVksRUFBRTtRQUNoQixNQUFNLHFCQUFxQixHQUFHLFlBQVksQ0FBQyxzQkFBc0IsQ0FBQyxDQUFDO1FBQ25FLElBQUkscUJBQXFCLEtBQUssSUFBSSxJQUFJLHFCQUFxQixLQUFLLFVBQVUsRUFBRTtZQUMxRSxlQUFlLENBQUMscUJBQXFCLEVBQUUsWUFBWSxDQUFDLENBQUM7U0FDdEQ7UUFHRCxJQUFJLFdBQVcsR0FBRyxDQUFDLEVBQUU7WUFDbkIsVUFBVSxDQUFDLGdCQUFnQixHQUFHLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxHQUFHLFlBQVksQ0FBQyxJQUFJLENBQVUsQ0FBQztTQUN0RTtRQUNELE1BQU0sWUFBWSxHQUFHLGVBQWUsQ0FBQyxVQUFVLEVBQUUsdUJBQXVCLEdBQUcsV0FBVyxDQUFDLENBQUM7UUFDeEYsdUJBQXVCLENBQUMsWUFBWSxDQUFDLEtBQUssQ0FBQyxFQUFFLFlBQVksQ0FBQyxDQUFDO1FBRTNELDRDQUE0QztRQUM1QyxNQUFNLFFBQVEsR0FBRyxZQUFZLENBQUMsT0FBTyxDQUFDLENBQUM7UUFDdkMsSUFBSSxRQUFRLEtBQUssSUFBSSxFQUFFO1lBQ3JCLFFBQVEsQ0FBQyxVQUFVLENBQUMsWUFBWSxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUM7U0FDMUM7UUFFRCxZQUFZLENBQUMsTUFBTSxDQUFDLEdBQUcsSUFBSSxDQUFDO1FBQzVCLFlBQVksQ0FBQyxJQUFJLENBQUMsR0FBRyxJQUFJLENBQUM7UUFDMUIsMkJBQTJCO1FBQzNCLFlBQVksQ0FBQyxLQUFLLENBQUMsSUFBSSw4QkFBb0IsQ0FBQztLQUM3QztJQUNELE9BQU8sWUFBWSxDQUFDO0FBQ3RCLENBQUM7QUFFRDs7Ozs7O0dBTUc7QUFDSCxNQUFNLFVBQVUsWUFBWSxDQUFDLEtBQVksRUFBRSxLQUFZO0lBQ3JELElBQUksQ0FBQyxDQUFDLEtBQUssQ0FBQyxLQUFLLENBQUMsaUNBQXVCLENBQUMsRUFBRTtRQUMxQyxNQUFNLFFBQVEsR0FBRyxLQUFLLENBQUMsUUFBUSxDQUFDLENBQUM7UUFFakMsS0FBSyxDQUFDLDBCQUEwQixDQUFDLEVBQUUsT0FBTyxFQUFFLENBQUM7UUFDN0MsS0FBSyxDQUFDLDhCQUE4QixDQUFDLEVBQUUsT0FBTyxFQUFFLENBQUM7UUFFakQsSUFBSSxRQUFRLENBQUMsV0FBVyxFQUFFO1lBQ3hCLFNBQVMsQ0FBQyxLQUFLLEVBQUUsS0FBSyxFQUFFLFFBQVEsdUNBQStCLElBQUksRUFBRSxJQUFJLENBQUMsQ0FBQztTQUM1RTtRQUVELGVBQWUsQ0FBQyxLQUFLLENBQUMsQ0FBQztLQUN4QjtBQUNILENBQUM7QUFFRDs7Ozs7OztHQU9HO0FBQ0gsU0FBUyxXQUFXLENBQUMsS0FBWSxFQUFFLEtBQVk7SUFDN0MsSUFBSSxDQUFDLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQyxpQ0FBdUIsQ0FBQyxFQUFFO1FBQzFDLDBGQUEwRjtRQUMxRix5RkFBeUY7UUFDekYsS0FBSyxDQUFDLEtBQUssQ0FBQyxJQUFJLDhCQUFvQixDQUFDO1FBRXJDLHdGQUF3RjtRQUN4Riw2RkFBNkY7UUFDN0YsNkZBQTZGO1FBQzdGLDBGQUEwRjtRQUMxRiwrREFBK0Q7UUFDL0QsS0FBSyxDQUFDLEtBQUssQ0FBQyxrQ0FBd0IsQ0FBQztRQUVyQyxpQkFBaUIsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLENBQUM7UUFDaEMsZUFBZSxDQUFDLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztRQUM5Qiw4RUFBOEU7UUFDOUUsSUFBSSxLQUFLLENBQUMsS0FBSyxDQUFDLENBQUMsSUFBSSxnQ0FBd0IsRUFBRTtZQUM3QyxTQUFTLElBQUksU0FBUyxDQUFDLGVBQWUsRUFBRSxDQUFDO1lBQ3pDLEtBQUssQ0FBQyxRQUFRLENBQUMsQ0FBQyxPQUFPLEVBQUUsQ0FBQztTQUMzQjtRQUVELE1BQU0sb0JBQW9CLEdBQUcsS0FBSyxDQUFDLHNCQUFzQixDQUFDLENBQUM7UUFDM0QsK0VBQStFO1FBQy9FLElBQUksb0JBQW9CLEtBQUssSUFBSSxJQUFJLFlBQVksQ0FBQyxLQUFLLENBQUMsTUFBTSxDQUFDLENBQUMsRUFBRTtZQUNoRSwrQkFBK0I7WUFDL0IsSUFBSSxvQkFBb0IsS0FBSyxLQUFLLENBQUMsTUFBTSxDQUFDLEVBQUU7Z0JBQzFDLGVBQWUsQ0FBQyxvQkFBb0IsRUFBRSxLQUFLLENBQUMsQ0FBQzthQUM5QztZQUVELHdGQUF3RjtZQUN4RixNQUFNLFFBQVEsR0FBRyxLQUFLLENBQUMsT0FBTyxDQUFDLENBQUM7WUFDaEMsSUFBSSxRQUFRLEtBQUssSUFBSSxFQUFFO2dCQUNyQixRQUFRLENBQUMsVUFBVSxDQUFDLEtBQUssQ0FBQyxDQUFDO2FBQzVCO1NBQ0Y7UUFFRCxnRUFBZ0U7UUFDaEUsZUFBZSxDQUFDLEtBQUssQ0FBQyxDQUFDO0tBQ3hCO0FBQ0gsQ0FBQztBQUVELG1FQUFtRTtBQUNuRSxTQUFTLGVBQWUsQ0FBQyxLQUFZLEVBQUUsS0FBWTtJQUNqRCxNQUFNLFFBQVEsR0FBRyxLQUFLLENBQUMsT0FBTyxDQUFDO0lBQy9CLE1BQU0sUUFBUSxHQUFHLEtBQUssQ0FBQyxPQUFPLENBQUUsQ0FBQztJQUNqQyxJQUFJLFFBQVEsS0FBSyxJQUFJLEVBQUU7UUFDckIsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLFFBQVEsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxFQUFFLENBQUMsSUFBSSxDQUFDLEVBQUU7WUFDL0MsSUFBSSxPQUFPLFFBQVEsQ0FBQyxDQUFDLENBQUMsS0FBSyxRQUFRLEVBQUU7Z0JBQ25DLDRGQUE0RjtnQkFDNUYsK0JBQStCO2dCQUMvQixNQUFNLFNBQVMsR0FBRyxRQUFRLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDO2dCQUNsQyxTQUFTLElBQUksWUFBWSxDQUFDLFNBQVMsRUFBRSxpQ0FBaUMsQ0FBQyxDQUFDO2dCQUN4RSxJQUFJLFNBQVMsSUFBSSxDQUFDLEVBQUU7b0JBQ2xCLGFBQWE7b0JBQ2IsUUFBUSxDQUFDLFNBQVMsQ0FBQyxFQUFFLENBQUM7aUJBQ3ZCO3FCQUFNO29CQUNMLGVBQWU7b0JBQ2YsUUFBUSxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsV0FBVyxFQUFFLENBQUM7aUJBQ3BDO2dCQUNELENBQUMsSUFBSSxDQUFDLENBQUM7YUFDUjtpQkFBTTtnQkFDTCwyRUFBMkU7Z0JBQzNFLE1BQU0sT0FBTyxHQUFHLFFBQVEsQ0FBQyxRQUFRLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUM7Z0JBQzFDLFFBQVEsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsT0FBTyxDQUFDLENBQUM7YUFDM0I7U0FDRjtLQUNGO0lBQ0QsSUFBSSxRQUFRLEtBQUssSUFBSSxFQUFFO1FBQ3JCLEtBQUssQ0FBQyxPQUFPLENBQUMsR0FBRyxJQUFJLENBQUM7S0FDdkI7SUFDRCxNQUFNLFlBQVksR0FBRyxLQUFLLENBQUMsZ0JBQWdCLENBQUMsQ0FBQztJQUM3QyxJQUFJLFlBQVksS0FBSyxJQUFJLEVBQUU7UUFDekIsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLFlBQVksQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7WUFDNUMsTUFBTSxjQUFjLEdBQUcsWUFBWSxDQUFDLENBQUMsQ0FBQyxDQUFDO1lBQ3ZDLFNBQVMsSUFBSSxjQUFjLENBQUMsY0FBYyxFQUFFLDBDQUEwQyxDQUFDLENBQUM7WUFDeEYsY0FBYyxFQUFFLENBQUM7U0FDbEI7UUFDRCxLQUFLLENBQUMsZ0JBQWdCLENBQUMsR0FBRyxJQUFJLENBQUM7S0FDaEM7QUFDSCxDQUFDO0FBRUQsMENBQTBDO0FBQzFDLFNBQVMsaUJBQWlCLENBQUMsS0FBWSxFQUFFLEtBQVk7SUFDbkQsSUFBSSxZQUFrQyxDQUFDO0lBRXZDLElBQUksS0FBSyxJQUFJLElBQUksSUFBSSxDQUFDLFlBQVksR0FBRyxLQUFLLENBQUMsWUFBWSxDQUFDLElBQUksSUFBSSxFQUFFO1FBQ2hFLEtBQUssSUFBSSxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxZQUFZLENBQUMsTUFBTSxFQUFFLENBQUMsSUFBSSxDQUFDLEVBQUU7WUFDL0MsTUFBTSxPQUFPLEdBQUcsS0FBSyxDQUFDLFlBQVksQ0FBQyxDQUFDLENBQVcsQ0FBQyxDQUFDO1lBRWpELGdFQUFnRTtZQUNoRSxJQUFJLENBQUMsQ0FBQyxPQUFPLFlBQVksbUJBQW1CLENBQUMsRUFBRTtnQkFDN0MsTUFBTSxNQUFNLEdBQUcsWUFBWSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQXNCLENBQUM7Z0JBRXhELElBQUksS0FBSyxDQUFDLE9BQU8sQ0FBQyxNQUFNLENBQUMsRUFBRTtvQkFDekIsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLE1BQU0sQ0FBQyxNQUFNLEVBQUUsQ0FBQyxJQUFJLENBQUMsRUFBRTt3QkFDekMsTUFBTSxXQUFXLEdBQUcsT0FBTyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQVcsQ0FBQyxDQUFDO3dCQUNqRCxNQUFNLElBQUksR0FBRyxNQUFNLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBVyxDQUFDO3dCQUNyQyxRQUFRLDJDQUFtQyxXQUFXLEVBQUUsSUFBSSxDQUFDLENBQUM7d0JBQzlELElBQUk7NEJBQ0YsSUFBSSxDQUFDLElBQUksQ0FBQyxXQUFXLENBQUMsQ0FBQzt5QkFDeEI7Z0NBQVM7NEJBQ1IsUUFBUSx5Q0FBaUMsV0FBVyxFQUFFLElBQUksQ0FBQyxDQUFDO3lCQUM3RDtxQkFDRjtpQkFDRjtxQkFBTTtvQkFDTCxRQUFRLDJDQUFtQyxPQUFPLEVBQUUsTUFBTSxDQUFDLENBQUM7b0JBQzVELElBQUk7d0JBQ0YsTUFBTSxDQUFDLElBQUksQ0FBQyxPQUFPLENBQUMsQ0FBQztxQkFDdEI7NEJBQVM7d0JBQ1IsUUFBUSx5Q0FBaUMsT0FBTyxFQUFFLE1BQU0sQ0FBQyxDQUFDO3FCQUMzRDtpQkFDRjthQUNGO1NBQ0Y7S0FDRjtBQUNILENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7O0dBZUc7QUFDSCxNQUFNLFVBQVUsaUJBQWlCLENBQUMsS0FBWSxFQUFFLEtBQVksRUFBRSxLQUFZO0lBQ3hFLE9BQU8sa0JBQWtCLENBQUMsS0FBSyxFQUFFLEtBQUssQ0FBQyxNQUFNLEVBQUUsS0FBSyxDQUFDLENBQUM7QUFDeEQsQ0FBQztBQUVEOzs7Ozs7Ozs7Ozs7OztHQWNHO0FBQ0gsTUFBTSxVQUFVLGtCQUFrQixDQUFDLEtBQVksRUFBRSxLQUFpQixFQUFFLEtBQVk7SUFDOUUsSUFBSSxXQUFXLEdBQWUsS0FBSyxDQUFDO0lBQ3BDLHNGQUFzRjtJQUN0RixvQ0FBb0M7SUFDcEMsT0FBTyxXQUFXLEtBQUssSUFBSTtRQUNwQixDQUFDLFdBQVcsQ0FBQyxJQUFJLEdBQUcsQ0FBQywyREFBMEMsQ0FBQyxDQUFDLEVBQUU7UUFDeEUsS0FBSyxHQUFHLFdBQVcsQ0FBQztRQUNwQixXQUFXLEdBQUcsS0FBSyxDQUFDLE1BQU0sQ0FBQztLQUM1QjtJQUVELGdHQUFnRztJQUNoRyx1QkFBdUI7SUFDdkIsSUFBSSxXQUFXLEtBQUssSUFBSSxFQUFFO1FBQ3hCLDRGQUE0RjtRQUM1Riw2QkFBNkI7UUFDN0IsT0FBTyxLQUFLLENBQUMsSUFBSSxDQUFDLENBQUM7S0FDcEI7U0FBTTtRQUNMLFNBQVMsSUFBSSxlQUFlLENBQUMsV0FBVyxFQUFFLHdEQUF3QyxDQUFDLENBQUM7UUFDcEYsTUFBTSxFQUFDLGVBQWUsRUFBQyxHQUFHLFdBQVcsQ0FBQztRQUN0QyxJQUFJLGVBQWUsR0FBRyxDQUFDLENBQUMsRUFBRTtZQUN4QixTQUFTLElBQUksbUJBQW1CLENBQUMsV0FBVyxFQUFFLEtBQUssQ0FBQyxDQUFDO1lBQ3JELE1BQU0sRUFBQyxhQUFhLEVBQUMsR0FDaEIsS0FBSyxDQUFDLElBQUksQ0FBQyxXQUFXLENBQUMsY0FBYyxHQUFHLGVBQWUsQ0FBMkIsQ0FBQztZQUN4Riw0RkFBNEY7WUFDNUYsNEZBQTRGO1lBQzVGLHVGQUF1RjtZQUN2Rix1RkFBdUY7WUFDdkYsNkZBQTZGO1lBQzdGLDRFQUE0RTtZQUM1RSxJQUFJLGFBQWEsS0FBSyxpQkFBaUIsQ0FBQyxJQUFJO2dCQUN4QyxhQUFhLEtBQUssaUJBQWlCLENBQUMsUUFBUSxFQUFFO2dCQUNoRCxPQUFPLElBQUksQ0FBQzthQUNiO1NBQ0Y7UUFFRCxPQUFPLGdCQUFnQixDQUFDLFdBQVcsRUFBRSxLQUFLLENBQWEsQ0FBQztLQUN6RDtBQUNILENBQUM7QUFFRDs7O0dBR0c7QUFDSCxNQUFNLFVBQVUsa0JBQWtCLENBQzlCLFFBQWtCLEVBQUUsTUFBZ0IsRUFBRSxLQUFZLEVBQUUsVUFBc0IsRUFDMUUsTUFBZTtJQUNqQixTQUFTLElBQUksU0FBUyxDQUFDLG9CQUFvQixFQUFFLENBQUM7SUFDOUMsUUFBUSxDQUFDLFlBQVksQ0FBQyxNQUFNLEVBQUUsS0FBSyxFQUFFLFVBQVUsRUFBRSxNQUFNLENBQUMsQ0FBQztBQUMzRCxDQUFDO0FBRUQsU0FBUyxpQkFBaUIsQ0FBQyxRQUFrQixFQUFFLE1BQWdCLEVBQUUsS0FBWTtJQUMzRSxTQUFTLElBQUksU0FBUyxDQUFDLG1CQUFtQixFQUFFLENBQUM7SUFDN0MsU0FBUyxJQUFJLGFBQWEsQ0FBQyxNQUFNLEVBQUUsNkJBQTZCLENBQUMsQ0FBQztJQUNsRSxRQUFRLENBQUMsV0FBVyxDQUFDLE1BQU0sRUFBRSxLQUFLLENBQUMsQ0FBQztBQUN0QyxDQUFDO0FBRUQsU0FBUywwQkFBMEIsQ0FDL0IsUUFBa0IsRUFBRSxNQUFnQixFQUFFLEtBQVksRUFBRSxVQUFzQixFQUFFLE1BQWU7SUFDN0YsSUFBSSxVQUFVLEtBQUssSUFBSSxFQUFFO1FBQ3ZCLGtCQUFrQixDQUFDLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxFQUFFLFVBQVUsRUFBRSxNQUFNLENBQUMsQ0FBQztLQUNqRTtTQUFNO1FBQ0wsaUJBQWlCLENBQUMsUUFBUSxFQUFFLE1BQU0sRUFBRSxLQUFLLENBQUMsQ0FBQztLQUM1QztBQUNILENBQUM7QUFFRCwyREFBMkQ7QUFDM0QsU0FBUyxpQkFBaUIsQ0FDdEIsUUFBa0IsRUFBRSxNQUFnQixFQUFFLEtBQVksRUFBRSxhQUF1QjtJQUM3RSxRQUFRLENBQUMsV0FBVyxDQUFDLE1BQU0sRUFBRSxLQUFLLEVBQUUsYUFBYSxDQUFDLENBQUM7QUFDckQsQ0FBQztBQUVELG1EQUFtRDtBQUNuRCxTQUFTLGNBQWMsQ0FBQyxJQUFjO0lBQ3BDLE9BQU8sSUFBSSxDQUFDLE9BQU8sS0FBSyxVQUFVLElBQUssSUFBa0IsQ0FBQyxPQUFPLEtBQUssU0FBUyxDQUFDO0FBQ2xGLENBQUM7QUFFRDs7R0FFRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FBQyxRQUFrQixFQUFFLElBQVc7SUFDOUQsT0FBTyxRQUFRLENBQUMsVUFBVSxDQUFDLElBQUksQ0FBQyxDQUFDO0FBQ25DLENBQUM7QUFFRDs7R0FFRztBQUNILE1BQU0sVUFBVSxpQkFBaUIsQ0FBQyxRQUFrQixFQUFFLElBQVc7SUFDL0QsT0FBTyxRQUFRLENBQUMsV0FBVyxDQUFDLElBQUksQ0FBQyxDQUFDO0FBQ3BDLENBQUM7QUFFRDs7Ozs7Ozs7O0dBU0c7QUFDSCxTQUFTLHVCQUF1QixDQUFDLFdBQWtCLEVBQUUsWUFBbUIsRUFBRSxLQUFZO0lBRXBGLE9BQU8sZ0NBQWdDLENBQUMsV0FBVyxFQUFFLFlBQVksRUFBRSxLQUFLLENBQUMsQ0FBQztBQUM1RSxDQUFDO0FBR0Q7Ozs7Ozs7Ozs7R0FVRztBQUNILE1BQU0sVUFBVSxpQ0FBaUMsQ0FDN0MsV0FBa0IsRUFBRSxZQUFtQixFQUFFLEtBQVk7SUFDdkQsSUFBSSxXQUFXLENBQUMsSUFBSSxHQUFHLENBQUMsMkRBQTBDLENBQUMsRUFBRTtRQUNuRSxPQUFPLGdCQUFnQixDQUFDLFdBQVcsRUFBRSxLQUFLLENBQUMsQ0FBQztLQUM3QztJQUNELE9BQU8sSUFBSSxDQUFDO0FBQ2QsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxJQUFJLGdDQUFnQyxHQUNqQixpQ0FBaUMsQ0FBQztBQUVyRDs7OztHQUlHO0FBQ0gsSUFBSSx3QkFFc0MsQ0FBQztBQUUzQyxNQUFNLFVBQVUsZUFBZSxDQUMzQiwrQkFDZ0IsRUFDaEIsdUJBRTBDO0lBQzVDLGdDQUFnQyxHQUFHLCtCQUErQixDQUFDO0lBQ25FLHdCQUF3QixHQUFHLHVCQUF1QixDQUFDO0FBQ3JELENBQUM7QUFFRDs7Ozs7OztHQU9HO0FBQ0gsTUFBTSxVQUFVLFdBQVcsQ0FDdkIsS0FBWSxFQUFFLEtBQVksRUFBRSxVQUF5QixFQUFFLFVBQWlCO0lBQzFFLE1BQU0sV0FBVyxHQUFHLGlCQUFpQixDQUFDLEtBQUssRUFBRSxVQUFVLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDaEUsTUFBTSxRQUFRLEdBQUcsS0FBSyxDQUFDLFFBQVEsQ0FBQyxDQUFDO0lBQ2pDLE1BQU0sV0FBVyxHQUFVLFVBQVUsQ0FBQyxNQUFNLElBQUksS0FBSyxDQUFDLE1BQU0sQ0FBRSxDQUFDO0lBQy9ELE1BQU0sVUFBVSxHQUFHLHVCQUF1QixDQUFDLFdBQVcsRUFBRSxVQUFVLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDM0UsSUFBSSxXQUFXLElBQUksSUFBSSxFQUFFO1FBQ3ZCLElBQUksS0FBSyxDQUFDLE9BQU8sQ0FBQyxVQUFVLENBQUMsRUFBRTtZQUM3QixLQUFLLElBQUksQ0FBQyxHQUFHLENBQUMsRUFBRSxDQUFDLEdBQUcsVUFBVSxDQUFDLE1BQU0sRUFBRSxDQUFDLEVBQUUsRUFBRTtnQkFDMUMsMEJBQTBCLENBQUMsUUFBUSxFQUFFLFdBQVcsRUFBRSxVQUFVLENBQUMsQ0FBQyxDQUFDLEVBQUUsVUFBVSxFQUFFLEtBQUssQ0FBQyxDQUFDO2FBQ3JGO1NBQ0Y7YUFBTTtZQUNMLDBCQUEwQixDQUFDLFFBQVEsRUFBRSxXQUFXLEVBQUUsVUFBVSxFQUFFLFVBQVUsRUFBRSxLQUFLLENBQUMsQ0FBQztTQUNsRjtLQUNGO0lBRUQsd0JBQXdCLEtBQUssU0FBUztRQUNsQyx3QkFBd0IsQ0FBQyxRQUFRLEVBQUUsVUFBVSxFQUFFLEtBQUssRUFBRSxVQUFVLEVBQUUsV0FBVyxDQUFDLENBQUM7QUFDckYsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsa0JBQWtCLENBQUMsS0FBWSxFQUFFLEtBQWlCO0lBQ2hFLElBQUksS0FBSyxLQUFLLElBQUksRUFBRTtRQUNsQixTQUFTO1lBQ0wsZUFBZSxDQUNYLEtBQUssRUFDTCw0REFBMkMseUJBQWdCLGdDQUF1QixDQUFDLENBQUM7UUFFNUYsTUFBTSxTQUFTLEdBQUcsS0FBSyxDQUFDLElBQUksQ0FBQztRQUM3QixJQUFJLFNBQVMsNkJBQXFCLEVBQUU7WUFDbEMsT0FBTyxnQkFBZ0IsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLENBQUM7U0FDdkM7YUFBTSxJQUFJLFNBQVMsOEJBQXNCLEVBQUU7WUFDMUMsT0FBTyxvQkFBb0IsQ0FBQyxDQUFDLENBQUMsRUFBRSxLQUFLLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUM7U0FDckQ7YUFBTSxJQUFJLFNBQVMscUNBQTZCLEVBQUU7WUFDakQsTUFBTSxtQkFBbUIsR0FBRyxLQUFLLENBQUMsS0FBSyxDQUFDO1lBQ3hDLElBQUksbUJBQW1CLEtBQUssSUFBSSxFQUFFO2dCQUNoQyxPQUFPLGtCQUFrQixDQUFDLEtBQUssRUFBRSxtQkFBbUIsQ0FBQyxDQUFDO2FBQ3ZEO2lCQUFNO2dCQUNMLE1BQU0saUJBQWlCLEdBQUcsS0FBSyxDQUFDLEtBQUssQ0FBQyxLQUFLLENBQUMsQ0FBQztnQkFDN0MsSUFBSSxZQUFZLENBQUMsaUJBQWlCLENBQUMsRUFBRTtvQkFDbkMsT0FBTyxvQkFBb0IsQ0FBQyxDQUFDLENBQUMsRUFBRSxpQkFBaUIsQ0FBQyxDQUFDO2lCQUNwRDtxQkFBTTtvQkFDTCxPQUFPLFdBQVcsQ0FBQyxpQkFBaUIsQ0FBQyxDQUFDO2lCQUN2QzthQUNGO1NBQ0Y7YUFBTSxJQUFJLFNBQVMseUJBQWdCLEVBQUU7WUFDcEMsSUFBSSxTQUFTLEdBQUcsbUJBQW1CLENBQUMsS0FBMEIsRUFBRSxLQUFLLENBQUMsQ0FBQztZQUN2RSxJQUFJLEtBQUssR0FBZSxTQUFTLEVBQUUsQ0FBQztZQUNwQyw2RUFBNkU7WUFDN0UsT0FBTyxLQUFLLElBQUksV0FBVyxDQUFDLEtBQUssQ0FBQyxLQUFLLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQztTQUNqRDthQUFNO1lBQ0wsTUFBTSxlQUFlLEdBQUcsa0JBQWtCLENBQUMsS0FBSyxFQUFFLEtBQUssQ0FBQyxDQUFDO1lBQ3pELElBQUksZUFBZSxLQUFLLElBQUksRUFBRTtnQkFDNUIsSUFBSSxLQUFLLENBQUMsT0FBTyxDQUFDLGVBQWUsQ0FBQyxFQUFFO29CQUNsQyxPQUFPLGVBQWUsQ0FBQyxDQUFDLENBQUMsQ0FBQztpQkFDM0I7Z0JBQ0QsTUFBTSxVQUFVLEdBQUcsY0FBYyxDQUFDLEtBQUssQ0FBQywwQkFBMEIsQ0FBQyxDQUFDLENBQUM7Z0JBQ3JFLFNBQVMsSUFBSSxnQkFBZ0IsQ0FBQyxVQUFVLENBQUMsQ0FBQztnQkFDMUMsT0FBTyxrQkFBa0IsQ0FBQyxVQUFXLEVBQUUsZUFBZSxDQUFDLENBQUM7YUFDekQ7aUJBQU07Z0JBQ0wsT0FBTyxrQkFBa0IsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLElBQUksQ0FBQyxDQUFDO2FBQzlDO1NBQ0Y7S0FDRjtJQUVELE9BQU8sSUFBSSxDQUFDO0FBQ2QsQ0FBQztBQUVELE1BQU0sVUFBVSxrQkFBa0IsQ0FBQyxLQUFZLEVBQUUsS0FBaUI7SUFDaEUsSUFBSSxLQUFLLEtBQUssSUFBSSxFQUFFO1FBQ2xCLE1BQU0sYUFBYSxHQUFHLEtBQUssQ0FBQywwQkFBMEIsQ0FBQyxDQUFDO1FBQ3hELE1BQU0sYUFBYSxHQUFHLGFBQWEsQ0FBQyxNQUFNLENBQWlCLENBQUM7UUFDNUQsTUFBTSxPQUFPLEdBQUcsS0FBSyxDQUFDLFVBQW9CLENBQUM7UUFDM0MsU0FBUyxJQUFJLHFCQUFxQixDQUFDLEtBQUssQ0FBQyxDQUFDO1FBQzFDLE9BQU8sYUFBYSxDQUFDLFVBQVcsQ0FBQyxPQUFPLENBQUMsQ0FBQztLQUMzQztJQUNELE9BQU8sSUFBSSxDQUFDO0FBQ2QsQ0FBQztBQUVELE1BQU0sVUFBVSxvQkFBb0IsQ0FBQyxvQkFBNEIsRUFBRSxVQUFzQjtJQUV2RixNQUFNLGFBQWEsR0FBRyx1QkFBdUIsR0FBRyxvQkFBb0IsR0FBRyxDQUFDLENBQUM7SUFDekUsSUFBSSxhQUFhLEdBQUcsVUFBVSxDQUFDLE1BQU0sRUFBRTtRQUNyQyxNQUFNLEtBQUssR0FBRyxVQUFVLENBQUMsYUFBYSxDQUFVLENBQUM7UUFDakQsTUFBTSxnQkFBZ0IsR0FBRyxLQUFLLENBQUMsS0FBSyxDQUFDLENBQUMsVUFBVSxDQUFDO1FBQ2pELElBQUksZ0JBQWdCLEtBQUssSUFBSSxFQUFFO1lBQzdCLE9BQU8sa0JBQWtCLENBQUMsS0FBSyxFQUFFLGdCQUFnQixDQUFDLENBQUM7U0FDcEQ7S0FDRjtJQUVELE9BQU8sVUFBVSxDQUFDLE1BQU0sQ0FBQyxDQUFDO0FBQzVCLENBQUM7QUFFRDs7Ozs7Ozs7R0FRRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FBQyxRQUFrQixFQUFFLEtBQVksRUFBRSxhQUF1QjtJQUN4RixTQUFTLElBQUksU0FBUyxDQUFDLGtCQUFrQixFQUFFLENBQUM7SUFDNUMsTUFBTSxZQUFZLEdBQUcsZ0JBQWdCLENBQUMsUUFBUSxFQUFFLEtBQUssQ0FBQyxDQUFDO0lBQ3ZELElBQUksWUFBWSxFQUFFO1FBQ2hCLGlCQUFpQixDQUFDLFFBQVEsRUFBRSxZQUFZLEVBQUUsS0FBSyxFQUFFLGFBQWEsQ0FBQyxDQUFDO0tBQ2pFO0FBQ0gsQ0FBQztBQUVEOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsb0JBQW9CLENBQUMsUUFBa0I7SUFDckQsUUFBUSxDQUFDLFdBQVcsR0FBRyxFQUFFLENBQUM7QUFDNUIsQ0FBQztBQUdEOzs7R0FHRztBQUNILFNBQVMsVUFBVSxDQUNmLFFBQWtCLEVBQUUsTUFBMkIsRUFBRSxLQUFpQixFQUFFLEtBQVksRUFDaEYsY0FBNkIsRUFBRSxVQUFzQixFQUFFLFlBQXFCO0lBQzlFLE9BQU8sS0FBSyxJQUFJLElBQUksRUFBRTtRQUNwQixTQUFTLElBQUksbUJBQW1CLENBQUMsS0FBSyxFQUFFLEtBQUssQ0FBQyxDQUFDO1FBQy9DLFNBQVM7WUFDTCxlQUFlLENBQ1gsS0FBSyxFQUNMLDREQUEyQyxnQ0FBdUIseUJBQWdCLENBQUMsQ0FBQztRQUM1RixNQUFNLFlBQVksR0FBRyxLQUFLLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQyxDQUFDO1FBQ3hDLE1BQU0sU0FBUyxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUM7UUFDN0IsSUFBSSxZQUFZLEVBQUU7WUFDaEIsSUFBSSxNQUFNLHVDQUErQixFQUFFO2dCQUN6QyxZQUFZLElBQUksZUFBZSxDQUFDLFdBQVcsQ0FBQyxZQUFZLENBQUMsRUFBRSxLQUFLLENBQUMsQ0FBQztnQkFDbEUsS0FBSyxDQUFDLEtBQUssa0NBQTBCLENBQUM7YUFDdkM7U0FDRjtRQUNELElBQUksQ0FBQyxLQUFLLENBQUMsS0FBSyxpQ0FBd0IsQ0FBQyxtQ0FBMEIsRUFBRTtZQUNuRSxJQUFJLFNBQVMscUNBQTZCLEVBQUU7Z0JBQzFDLFVBQVUsQ0FBQyxRQUFRLEVBQUUsTUFBTSxFQUFFLEtBQUssQ0FBQyxLQUFLLEVBQUUsS0FBSyxFQUFFLGNBQWMsRUFBRSxVQUFVLEVBQUUsS0FBSyxDQUFDLENBQUM7Z0JBQ3BGLHlCQUF5QixDQUFDLE1BQU0sRUFBRSxRQUFRLEVBQUUsY0FBYyxFQUFFLFlBQVksRUFBRSxVQUFVLENBQUMsQ0FBQzthQUN2RjtpQkFBTSxJQUFJLFNBQVMseUJBQWdCLEVBQUU7Z0JBQ3BDLE1BQU0sU0FBUyxHQUFHLG1CQUFtQixDQUFDLEtBQTBCLEVBQUUsS0FBSyxDQUFDLENBQUM7Z0JBQ3pFLElBQUksS0FBaUIsQ0FBQztnQkFDdEIsT0FBTyxLQUFLLEdBQUcsU0FBUyxFQUFFLEVBQUU7b0JBQzFCLHlCQUF5QixDQUFDLE1BQU0sRUFBRSxRQUFRLEVBQUUsY0FBYyxFQUFFLEtBQUssRUFBRSxVQUFVLENBQUMsQ0FBQztpQkFDaEY7Z0JBQ0QseUJBQXlCLENBQUMsTUFBTSxFQUFFLFFBQVEsRUFBRSxjQUFjLEVBQUUsWUFBWSxFQUFFLFVBQVUsQ0FBQyxDQUFDO2FBQ3ZGO2lCQUFNLElBQUksU0FBUyxnQ0FBdUIsRUFBRTtnQkFDM0Msd0JBQXdCLENBQ3BCLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxFQUFFLEtBQXdCLEVBQUUsY0FBYyxFQUFFLFVBQVUsQ0FBQyxDQUFDO2FBQ3BGO2lCQUFNO2dCQUNMLFNBQVMsSUFBSSxlQUFlLENBQUMsS0FBSyxFQUFFLHdEQUF3QyxDQUFDLENBQUM7Z0JBQzlFLHlCQUF5QixDQUFDLE1BQU0sRUFBRSxRQUFRLEVBQUUsY0FBYyxFQUFFLFlBQVksRUFBRSxVQUFVLENBQUMsQ0FBQzthQUN2RjtTQUNGO1FBQ0QsS0FBSyxHQUFHLFlBQVksQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLGNBQWMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLElBQUksQ0FBQztLQUMxRDtBQUNILENBQUM7QUFnQ0QsU0FBUyxTQUFTLENBQ2QsS0FBWSxFQUFFLEtBQVksRUFBRSxRQUFrQixFQUFFLE1BQTJCLEVBQzNFLGNBQTZCLEVBQUUsVUFBc0I7SUFDdkQsVUFBVSxDQUFDLFFBQVEsRUFBRSxNQUFNLEVBQUUsS0FBSyxDQUFDLFVBQVUsRUFBRSxLQUFLLEVBQUUsY0FBYyxFQUFFLFVBQVUsRUFBRSxLQUFLLENBQUMsQ0FBQztBQUMzRixDQUFDO0FBRUQ7Ozs7Ozs7OztHQVNHO0FBQ0gsTUFBTSxVQUFVLGVBQWUsQ0FBQyxLQUFZLEVBQUUsS0FBWSxFQUFFLGVBQWdDO0lBQzFGLE1BQU0sUUFBUSxHQUFHLEtBQUssQ0FBQyxRQUFRLENBQUMsQ0FBQztJQUNqQyxNQUFNLFdBQVcsR0FBRyxpQkFBaUIsQ0FBQyxLQUFLLEVBQUUsZUFBZSxFQUFFLEtBQUssQ0FBQyxDQUFDO0lBQ3JFLE1BQU0sV0FBVyxHQUFHLGVBQWUsQ0FBQyxNQUFNLElBQUksS0FBSyxDQUFDLE1BQU0sQ0FBRSxDQUFDO0lBQzdELElBQUksVUFBVSxHQUFHLHVCQUF1QixDQUFDLFdBQVcsRUFBRSxlQUFlLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDOUUsd0JBQXdCLENBQ3BCLFFBQVEsc0NBQThCLEtBQUssRUFBRSxlQUFlLEVBQUUsV0FBVyxFQUFFLFVBQVUsQ0FBQyxDQUFDO0FBQzdGLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7OztHQWFHO0FBQ0gsU0FBUyx3QkFBd0IsQ0FDN0IsUUFBa0IsRUFBRSxNQUEyQixFQUFFLEtBQVksRUFBRSxlQUFnQyxFQUMvRixjQUE2QixFQUFFLFVBQXNCO0lBQ3ZELE1BQU0sY0FBYyxHQUFHLEtBQUssQ0FBQywwQkFBMEIsQ0FBQyxDQUFDO0lBQ3pELE1BQU0sYUFBYSxHQUFHLGNBQWMsQ0FBQyxNQUFNLENBQWlCLENBQUM7SUFDN0QsU0FBUztRQUNMLFdBQVcsQ0FBQyxPQUFPLGVBQWUsQ0FBQyxVQUFVLEVBQUUsUUFBUSxFQUFFLDRCQUE0QixDQUFDLENBQUM7SUFDM0YsTUFBTSxxQkFBcUIsR0FBRyxhQUFhLENBQUMsVUFBVyxDQUFDLGVBQWUsQ0FBQyxVQUFVLENBQUUsQ0FBQztJQUNyRixJQUFJLEtBQUssQ0FBQyxPQUFPLENBQUMscUJBQXFCLENBQUMsRUFBRTtRQUN4QywwRkFBMEY7UUFDMUYsbUZBQW1GO1FBQ25GLHdGQUF3RjtRQUN4Rix3RkFBd0Y7UUFDeEYsNENBQTRDO1FBQzVDLEtBQUssSUFBSSxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxxQkFBcUIsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7WUFDckQsTUFBTSxLQUFLLEdBQUcscUJBQXFCLENBQUMsQ0FBQyxDQUFDLENBQUM7WUFDdkMseUJBQXlCLENBQUMsTUFBTSxFQUFFLFFBQVEsRUFBRSxjQUFjLEVBQUUsS0FBSyxFQUFFLFVBQVUsQ0FBQyxDQUFDO1NBQ2hGO0tBQ0Y7U0FBTTtRQUNMLElBQUksYUFBYSxHQUFlLHFCQUFxQixDQUFDO1FBQ3RELE1BQU0sdUJBQXVCLEdBQUcsY0FBYyxDQUFDLE1BQU0sQ0FBVSxDQUFDO1FBQ2hFLFVBQVUsQ0FDTixRQUFRLEVBQUUsTUFBTSxFQUFFLGFBQWEsRUFBRSx1QkFBdUIsRUFBRSxjQUFjLEVBQUUsVUFBVSxFQUFFLElBQUksQ0FBQyxDQUFDO0tBQ2pHO0FBQ0gsQ0FBQztBQUdEOzs7Ozs7Ozs7Ozs7R0FZRztBQUNILFNBQVMsY0FBYyxDQUNuQixRQUFrQixFQUFFLE1BQTJCLEVBQUUsVUFBc0IsRUFDdkUsY0FBNkIsRUFBRSxVQUFnQztJQUNqRSxTQUFTLElBQUksZ0JBQWdCLENBQUMsVUFBVSxDQUFDLENBQUM7SUFDMUMsTUFBTSxNQUFNLEdBQUcsVUFBVSxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUUsc0NBQXNDO0lBQzFFLE1BQU0sTUFBTSxHQUFHLFdBQVcsQ0FBQyxVQUFVLENBQUMsQ0FBQztJQUN2QyxzRkFBc0Y7SUFDdEYsNkZBQTZGO0lBQzdGLDRGQUE0RjtJQUM1Rix3REFBd0Q7SUFDeEQsa0ZBQWtGO0lBQ2xGLDhDQUE4QztJQUM5QyxJQUFJLE1BQU0sS0FBSyxNQUFNLEVBQUU7UUFDckIsMEZBQTBGO1FBQzFGLGlFQUFpRTtRQUNqRSxFQUFFO1FBQ0YsNERBQTREO1FBQzVELHlCQUF5QixDQUFDLE1BQU0sRUFBRSxRQUFRLEVBQUUsY0FBYyxFQUFFLE1BQU0sRUFBRSxVQUFVLENBQUMsQ0FBQztLQUNqRjtJQUNELEtBQUssSUFBSSxDQUFDLEdBQUcsdUJBQXVCLEVBQUUsQ0FBQyxHQUFHLFVBQVUsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7UUFDaEUsTUFBTSxLQUFLLEdBQUcsVUFBVSxDQUFDLENBQUMsQ0FBVSxDQUFDO1FBQ3JDLFNBQVMsQ0FBQyxLQUFLLENBQUMsS0FBSyxDQUFDLEVBQUUsS0FBSyxFQUFFLFFBQVEsRUFBRSxNQUFNLEVBQUUsY0FBYyxFQUFFLE1BQU0sQ0FBQyxDQUFDO0tBQzFFO0FBQ0gsQ0FBQztBQUVEOzs7Ozs7Ozs7R0FTRztBQUNILE1BQU0sVUFBVSxZQUFZLENBQ3hCLFFBQWtCLEVBQUUsWUFBcUIsRUFBRSxLQUFlLEVBQUUsSUFBWSxFQUFFLEtBQVU7SUFDdEYsSUFBSSxZQUFZLEVBQUU7UUFDaEIsb0ZBQW9GO1FBQ3BGLElBQUksQ0FBQyxLQUFLLEVBQUU7WUFDVixTQUFTLElBQUksU0FBUyxDQUFDLG1CQUFtQixFQUFFLENBQUM7WUFDN0MsUUFBUSxDQUFDLFdBQVcsQ0FBQyxLQUFLLEVBQUUsSUFBSSxDQUFDLENBQUM7U0FDbkM7YUFBTTtZQUNMLFNBQVMsSUFBSSxTQUFTLENBQUMsZ0JBQWdCLEVBQUUsQ0FBQztZQUMxQyxRQUFRLENBQUMsUUFBUSxDQUFDLEtBQUssRUFBRSxJQUFJLENBQUMsQ0FBQztTQUNoQztLQUNGO1NBQU07UUFDTCxJQUFJLEtBQUssR0FBRyxJQUFJLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLG1CQUFtQixDQUFDLFFBQWtCLENBQUM7UUFDMUYsSUFBSSxLQUFLLElBQUksSUFBSSxDQUFDLDZCQUE2QixFQUFFO1lBQy9DLFNBQVMsSUFBSSxTQUFTLENBQUMsbUJBQW1CLEVBQUUsQ0FBQztZQUM3QyxRQUFRLENBQUMsV0FBVyxDQUFDLEtBQUssRUFBRSxJQUFJLEVBQUUsS0FBSyxDQUFDLENBQUM7U0FDMUM7YUFBTTtZQUNMLCtEQUErRDtZQUMvRCx3REFBd0Q7WUFDeEQsTUFBTSxXQUFXLEdBQUcsT0FBTyxLQUFLLEtBQUssUUFBUSxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsUUFBUSxDQUFDLFlBQVksQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUM7WUFFckYsSUFBSSxXQUFXLEVBQUU7Z0JBQ2YsbUVBQW1FO2dCQUNuRSxLQUFLLEdBQUcsS0FBSyxDQUFDLEtBQUssQ0FBQyxDQUFDLEVBQUUsQ0FBQyxFQUFFLENBQUMsQ0FBQztnQkFDNUIsS0FBTSxJQUFJLG1CQUFtQixDQUFDLFNBQVMsQ0FBQzthQUN6QztZQUVELFNBQVMsSUFBSSxTQUFTLENBQUMsZ0JBQWdCLEVBQUUsQ0FBQztZQUMxQyxRQUFRLENBQUMsUUFBUSxDQUFDLEtBQUssRUFBRSxJQUFJLEVBQUUsS0FBSyxFQUFFLEtBQUssQ0FBQyxDQUFDO1NBQzlDO0tBQ0Y7QUFDSCxDQUFDO0FBR0Q7Ozs7Ozs7OztHQVNHO0FBQ0gsTUFBTSxVQUFVLGdCQUFnQixDQUFDLFFBQWtCLEVBQUUsT0FBaUIsRUFBRSxRQUFnQjtJQUN0RixTQUFTLElBQUksWUFBWSxDQUFDLFFBQVEsRUFBRSxpQ0FBaUMsQ0FBQyxDQUFDO0lBQ3ZFLFFBQVEsQ0FBQyxZQUFZLENBQUMsT0FBTyxFQUFFLE9BQU8sRUFBRSxRQUFRLENBQUMsQ0FBQztJQUNsRCxTQUFTLElBQUksU0FBUyxDQUFDLGdCQUFnQixFQUFFLENBQUM7QUFDNUMsQ0FBQztBQUVEOzs7Ozs7Ozs7R0FTRztBQUNILE1BQU0sVUFBVSxnQkFBZ0IsQ0FBQyxRQUFrQixFQUFFLE9BQWlCLEVBQUUsUUFBZ0I7SUFDdEYsU0FBUyxJQUFJLFlBQVksQ0FBQyxRQUFRLEVBQUUsaUNBQWlDLENBQUMsQ0FBQztJQUN2RSxJQUFJLFFBQVEsS0FBSyxFQUFFLEVBQUU7UUFDbkIsMEZBQTBGO1FBQzFGLFFBQVEsQ0FBQyxlQUFlLENBQUMsT0FBTyxFQUFFLE9BQU8sQ0FBQyxDQUFDO0tBQzVDO1NBQU07UUFDTCxRQUFRLENBQUMsWUFBWSxDQUFDLE9BQU8sRUFBRSxPQUFPLEVBQUUsUUFBUSxDQUFDLENBQUM7S0FDbkQ7SUFDRCxTQUFTLElBQUksU0FBUyxDQUFDLG9CQUFvQixFQUFFLENBQUM7QUFDaEQsQ0FBQztBQUVELHVEQUF1RDtBQUN2RCxNQUFNLFVBQVUscUJBQXFCLENBQUMsUUFBa0IsRUFBRSxPQUFpQixFQUFFLEtBQVk7SUFDdkYsTUFBTSxFQUFDLFdBQVcsRUFBRSxPQUFPLEVBQUUsTUFBTSxFQUFDLEdBQUcsS0FBSyxDQUFDO0lBRTdDLElBQUksV0FBVyxLQUFLLElBQUksRUFBRTtRQUN4QixlQUFlLENBQUMsUUFBUSxFQUFFLE9BQU8sRUFBRSxXQUFXLENBQUMsQ0FBQztLQUNqRDtJQUVELElBQUksT0FBTyxLQUFLLElBQUksRUFBRTtRQUNwQixnQkFBZ0IsQ0FBQyxRQUFRLEVBQUUsT0FBTyxFQUFFLE9BQU8sQ0FBQyxDQUFDO0tBQzlDO0lBRUQsSUFBSSxNQUFNLEtBQUssSUFBSSxFQUFFO1FBQ25CLGdCQUFnQixDQUFDLFFBQVEsRUFBRSxPQUFPLEVBQUUsTUFBTSxDQUFDLENBQUM7S0FDN0M7QUFDSCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Vmlld0VuY2Fwc3VsYXRpb259IGZyb20gJy4uL21ldGFkYXRhL3ZpZXcnO1xuaW1wb3J0IHtSZW5kZXJlclN0eWxlRmxhZ3MyfSBmcm9tICcuLi9yZW5kZXIvYXBpX2ZsYWdzJztcbmltcG9ydCB7YWRkVG9BcnJheSwgcmVtb3ZlRnJvbUFycmF5fSBmcm9tICcuLi91dGlsL2FycmF5X3V0aWxzJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZCwgYXNzZXJ0RXF1YWwsIGFzc2VydEZ1bmN0aW9uLCBhc3NlcnROdW1iZXIsIGFzc2VydFN0cmluZ30gZnJvbSAnLi4vdXRpbC9hc3NlcnQnO1xuaW1wb3J0IHtlc2NhcGVDb21tZW50VGV4dH0gZnJvbSAnLi4vdXRpbC9kb20nO1xuXG5pbXBvcnQge2Fzc2VydExDb250YWluZXIsIGFzc2VydExWaWV3LCBhc3NlcnRQYXJlbnRWaWV3LCBhc3NlcnRQcm9qZWN0aW9uU2xvdHMsIGFzc2VydFROb2RlRm9yTFZpZXd9IGZyb20gJy4vYXNzZXJ0JztcbmltcG9ydCB7YXR0YWNoUGF0Y2hEYXRhfSBmcm9tICcuL2NvbnRleHRfZGlzY292ZXJ5JztcbmltcG9ydCB7aWN1Q29udGFpbmVySXRlcmF0ZX0gZnJvbSAnLi9pMThuL2kxOG5fdHJlZV9zaGFraW5nJztcbmltcG9ydCB7Q09OVEFJTkVSX0hFQURFUl9PRkZTRVQsIEhBU19UUkFOU1BMQU5URURfVklFV1MsIExDb250YWluZXIsIE1PVkVEX1ZJRVdTLCBOQVRJVkV9IGZyb20gJy4vaW50ZXJmYWNlcy9jb250YWluZXInO1xuaW1wb3J0IHtDb21wb25lbnREZWZ9IGZyb20gJy4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7Tm9kZUluamVjdG9yRmFjdG9yeX0gZnJvbSAnLi9pbnRlcmZhY2VzL2luamVjdG9yJztcbmltcG9ydCB7dW5yZWdpc3RlckxWaWV3fSBmcm9tICcuL2ludGVyZmFjZXMvbHZpZXdfdHJhY2tpbmcnO1xuaW1wb3J0IHtURWxlbWVudE5vZGUsIFRJY3VDb250YWluZXJOb2RlLCBUTm9kZSwgVE5vZGVGbGFncywgVE5vZGVUeXBlLCBUUHJvamVjdGlvbk5vZGV9IGZyb20gJy4vaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7UmVuZGVyZXJ9IGZyb20gJy4vaW50ZXJmYWNlcy9yZW5kZXJlcic7XG5pbXBvcnQge1JDb21tZW50LCBSRWxlbWVudCwgUk5vZGUsIFJUZW1wbGF0ZSwgUlRleHR9IGZyb20gJy4vaW50ZXJmYWNlcy9yZW5kZXJlcl9kb20nO1xuaW1wb3J0IHtpc0xDb250YWluZXIsIGlzTFZpZXd9IGZyb20gJy4vaW50ZXJmYWNlcy90eXBlX2NoZWNrcyc7XG5pbXBvcnQge0NISUxEX0hFQUQsIENMRUFOVVAsIERFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXLCBERUNMQVJBVElPTl9MQ09OVEFJTkVSLCBEZXN0cm95SG9va0RhdGEsIEZMQUdTLCBIb29rRGF0YSwgSG9va0ZuLCBIT1NULCBMVmlldywgTFZpZXdGbGFncywgTkVYVCwgT05fREVTVFJPWV9IT09LUywgUEFSRU5ULCBRVUVSSUVTLCBSRUFDVElWRV9IT1NUX0JJTkRJTkdfQ09OU1VNRVIsIFJFQUNUSVZFX1RFTVBMQVRFX0NPTlNVTUVSLCBSRU5ERVJFUiwgVF9IT1NULCBUVklFVywgVFZpZXcsIFRWaWV3VHlwZX0gZnJvbSAnLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHthc3NlcnRUTm9kZVR5cGV9IGZyb20gJy4vbm9kZV9hc3NlcnQnO1xuaW1wb3J0IHtwcm9maWxlciwgUHJvZmlsZXJFdmVudH0gZnJvbSAnLi9wcm9maWxlcic7XG5pbXBvcnQge3NldFVwQXR0cmlidXRlc30gZnJvbSAnLi91dGlsL2F0dHJzX3V0aWxzJztcbmltcG9ydCB7Z2V0TFZpZXdQYXJlbnR9IGZyb20gJy4vdXRpbC92aWV3X3RyYXZlcnNhbF91dGlscyc7XG5pbXBvcnQge2NsZWFyVmlld1JlZnJlc2hGbGFnLCBnZXROYXRpdmVCeVROb2RlLCB1bndyYXBSTm9kZX0gZnJvbSAnLi91dGlsL3ZpZXdfdXRpbHMnO1xuXG5jb25zdCBlbnVtIFdhbGtUTm9kZVRyZWVBY3Rpb24ge1xuICAvKiogbm9kZSBjcmVhdGUgaW4gdGhlIG5hdGl2ZSBlbnZpcm9ubWVudC4gUnVuIG9uIGluaXRpYWwgY3JlYXRpb24uICovXG4gIENyZWF0ZSA9IDAsXG5cbiAgLyoqXG4gICAqIG5vZGUgaW5zZXJ0IGluIHRoZSBuYXRpdmUgZW52aXJvbm1lbnQuXG4gICAqIFJ1biB3aGVuIGV4aXN0aW5nIG5vZGUgaGFzIGJlZW4gZGV0YWNoZWQgYW5kIG5lZWRzIHRvIGJlIHJlLWF0dGFjaGVkLlxuICAgKi9cbiAgSW5zZXJ0ID0gMSxcblxuICAvKiogbm9kZSBkZXRhY2ggZnJvbSB0aGUgbmF0aXZlIGVudmlyb25tZW50ICovXG4gIERldGFjaCA9IDIsXG5cbiAgLyoqIG5vZGUgZGVzdHJ1Y3Rpb24gdXNpbmcgdGhlIHJlbmRlcmVyJ3MgQVBJICovXG4gIERlc3Ryb3kgPSAzLFxufVxuXG5cblxuLyoqXG4gKiBOT1RFOiBmb3IgcGVyZm9ybWFuY2UgcmVhc29ucywgdGhlIHBvc3NpYmxlIGFjdGlvbnMgYXJlIGlubGluZWQgd2l0aGluIHRoZSBmdW5jdGlvbiBpbnN0ZWFkIG9mXG4gKiBiZWluZyBwYXNzZWQgYXMgYW4gYXJndW1lbnQuXG4gKi9cbmZ1bmN0aW9uIGFwcGx5VG9FbGVtZW50T3JDb250YWluZXIoXG4gICAgYWN0aW9uOiBXYWxrVE5vZGVUcmVlQWN0aW9uLCByZW5kZXJlcjogUmVuZGVyZXIsIHBhcmVudDogUkVsZW1lbnR8bnVsbCxcbiAgICBsTm9kZVRvSGFuZGxlOiBSTm9kZXxMQ29udGFpbmVyfExWaWV3LCBiZWZvcmVOb2RlPzogUk5vZGV8bnVsbCkge1xuICAvLyBJZiB0aGlzIHNsb3Qgd2FzIGFsbG9jYXRlZCBmb3IgYSB0ZXh0IG5vZGUgZHluYW1pY2FsbHkgY3JlYXRlZCBieSBpMThuLCB0aGUgdGV4dCBub2RlIGl0c2VsZlxuICAvLyB3b24ndCBiZSBjcmVhdGVkIHVudGlsIGkxOG5BcHBseSgpIGluIHRoZSB1cGRhdGUgYmxvY2ssIHNvIHRoaXMgbm9kZSBzaG91bGQgYmUgc2tpcHBlZC5cbiAgLy8gRm9yIG1vcmUgaW5mbywgc2VlIFwiSUNVIGV4cHJlc3Npb25zIHNob3VsZCB3b3JrIGluc2lkZSBhbiBuZ1RlbXBsYXRlT3V0bGV0IGluc2lkZSBhbiBuZ0ZvclwiXG4gIC8vIGluIGBpMThuX3NwZWMudHNgLlxuICBpZiAobE5vZGVUb0hhbmRsZSAhPSBudWxsKSB7XG4gICAgbGV0IGxDb250YWluZXI6IExDb250YWluZXJ8dW5kZWZpbmVkO1xuICAgIGxldCBpc0NvbXBvbmVudCA9IGZhbHNlO1xuICAgIC8vIFdlIGFyZSBleHBlY3RpbmcgYW4gUk5vZGUsIGJ1dCBpbiB0aGUgY2FzZSBvZiBhIGNvbXBvbmVudCBvciBMQ29udGFpbmVyIHRoZSBgUk5vZGVgIGlzXG4gICAgLy8gd3JhcHBlZCBpbiBhbiBhcnJheSB3aGljaCBuZWVkcyB0byBiZSB1bndyYXBwZWQuIFdlIG5lZWQgdG8ga25vdyBpZiBpdCBpcyBhIGNvbXBvbmVudCBhbmQgaWZcbiAgICAvLyBpdCBoYXMgTENvbnRhaW5lciBzbyB0aGF0IHdlIGNhbiBwcm9jZXNzIGFsbCBvZiB0aG9zZSBjYXNlcyBhcHByb3ByaWF0ZWx5LlxuICAgIGlmIChpc0xDb250YWluZXIobE5vZGVUb0hhbmRsZSkpIHtcbiAgICAgIGxDb250YWluZXIgPSBsTm9kZVRvSGFuZGxlO1xuICAgIH0gZWxzZSBpZiAoaXNMVmlldyhsTm9kZVRvSGFuZGxlKSkge1xuICAgICAgaXNDb21wb25lbnQgPSB0cnVlO1xuICAgICAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQobE5vZGVUb0hhbmRsZVtIT1NUXSwgJ0hPU1QgbXVzdCBiZSBkZWZpbmVkIGZvciBhIGNvbXBvbmVudCBMVmlldycpO1xuICAgICAgbE5vZGVUb0hhbmRsZSA9IGxOb2RlVG9IYW5kbGVbSE9TVF0hO1xuICAgIH1cbiAgICBjb25zdCByTm9kZTogUk5vZGUgPSB1bndyYXBSTm9kZShsTm9kZVRvSGFuZGxlKTtcblxuICAgIGlmIChhY3Rpb24gPT09IFdhbGtUTm9kZVRyZWVBY3Rpb24uQ3JlYXRlICYmIHBhcmVudCAhPT0gbnVsbCkge1xuICAgICAgaWYgKGJlZm9yZU5vZGUgPT0gbnVsbCkge1xuICAgICAgICBuYXRpdmVBcHBlbmRDaGlsZChyZW5kZXJlciwgcGFyZW50LCByTm9kZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBuYXRpdmVJbnNlcnRCZWZvcmUocmVuZGVyZXIsIHBhcmVudCwgck5vZGUsIGJlZm9yZU5vZGUgfHwgbnVsbCwgdHJ1ZSk7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmIChhY3Rpb24gPT09IFdhbGtUTm9kZVRyZWVBY3Rpb24uSW5zZXJ0ICYmIHBhcmVudCAhPT0gbnVsbCkge1xuICAgICAgbmF0aXZlSW5zZXJ0QmVmb3JlKHJlbmRlcmVyLCBwYXJlbnQsIHJOb2RlLCBiZWZvcmVOb2RlIHx8IG51bGwsIHRydWUpO1xuICAgIH0gZWxzZSBpZiAoYWN0aW9uID09PSBXYWxrVE5vZGVUcmVlQWN0aW9uLkRldGFjaCkge1xuICAgICAgbmF0aXZlUmVtb3ZlTm9kZShyZW5kZXJlciwgck5vZGUsIGlzQ29tcG9uZW50KTtcbiAgICB9IGVsc2UgaWYgKGFjdGlvbiA9PT0gV2Fsa1ROb2RlVHJlZUFjdGlvbi5EZXN0cm95KSB7XG4gICAgICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyRGVzdHJveU5vZGUrKztcbiAgICAgIHJlbmRlcmVyLmRlc3Ryb3lOb2RlIShyTm9kZSk7XG4gICAgfVxuICAgIGlmIChsQ29udGFpbmVyICE9IG51bGwpIHtcbiAgICAgIGFwcGx5Q29udGFpbmVyKHJlbmRlcmVyLCBhY3Rpb24sIGxDb250YWluZXIsIHBhcmVudCwgYmVmb3JlTm9kZSk7XG4gICAgfVxuICB9XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUZXh0Tm9kZShyZW5kZXJlcjogUmVuZGVyZXIsIHZhbHVlOiBzdHJpbmcpOiBSVGV4dCB7XG4gIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJDcmVhdGVUZXh0Tm9kZSsrO1xuICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyU2V0VGV4dCsrO1xuICByZXR1cm4gcmVuZGVyZXIuY3JlYXRlVGV4dCh2YWx1ZSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiB1cGRhdGVUZXh0Tm9kZShyZW5kZXJlcjogUmVuZGVyZXIsIHJOb2RlOiBSVGV4dCwgdmFsdWU6IHN0cmluZyk6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyU2V0VGV4dCsrO1xuICByZW5kZXJlci5zZXRWYWx1ZShyTm9kZSwgdmFsdWUpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlQ29tbWVudE5vZGUocmVuZGVyZXI6IFJlbmRlcmVyLCB2YWx1ZTogc3RyaW5nKTogUkNvbW1lbnQge1xuICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyQ3JlYXRlQ29tbWVudCsrO1xuICByZXR1cm4gcmVuZGVyZXIuY3JlYXRlQ29tbWVudChlc2NhcGVDb21tZW50VGV4dCh2YWx1ZSkpO1xufVxuXG4vKipcbiAqIENyZWF0ZXMgYSBuYXRpdmUgZWxlbWVudCBmcm9tIGEgdGFnIG5hbWUsIHVzaW5nIGEgcmVuZGVyZXIuXG4gKiBAcGFyYW0gcmVuZGVyZXIgQSByZW5kZXJlciB0byB1c2VcbiAqIEBwYXJhbSBuYW1lIHRoZSB0YWcgbmFtZVxuICogQHBhcmFtIG5hbWVzcGFjZSBPcHRpb25hbCBuYW1lc3BhY2UgZm9yIGVsZW1lbnQuXG4gKiBAcmV0dXJucyB0aGUgZWxlbWVudCBjcmVhdGVkXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVFbGVtZW50Tm9kZShcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIG5hbWU6IHN0cmluZywgbmFtZXNwYWNlOiBzdHJpbmd8bnVsbCk6IFJFbGVtZW50IHtcbiAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlckNyZWF0ZUVsZW1lbnQrKztcbiAgcmV0dXJuIHJlbmRlcmVyLmNyZWF0ZUVsZW1lbnQobmFtZSwgbmFtZXNwYWNlKTtcbn1cblxuXG4vKipcbiAqIFJlbW92ZXMgYWxsIERPTSBlbGVtZW50cyBhc3NvY2lhdGVkIHdpdGggYSB2aWV3LlxuICpcbiAqIEJlY2F1c2Ugc29tZSByb290IG5vZGVzIG9mIHRoZSB2aWV3IG1heSBiZSBjb250YWluZXJzLCB3ZSBzb21ldGltZXMgbmVlZFxuICogdG8gcHJvcGFnYXRlIGRlZXBseSBpbnRvIHRoZSBuZXN0ZWQgY29udGFpbmVycyB0byByZW1vdmUgYWxsIGVsZW1lbnRzIGluIHRoZVxuICogdmlld3MgYmVuZWF0aCBpdC5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgVGhlIGBUVmlldycgb2YgdGhlIGBMVmlld2AgZnJvbSB3aGljaCBlbGVtZW50cyBzaG91bGQgYmUgYWRkZWQgb3IgcmVtb3ZlZFxuICogQHBhcmFtIGxWaWV3IFRoZSB2aWV3IGZyb20gd2hpY2ggZWxlbWVudHMgc2hvdWxkIGJlIGFkZGVkIG9yIHJlbW92ZWRcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlbW92ZVZpZXdGcm9tQ29udGFpbmVyKHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3KTogdm9pZCB7XG4gIGNvbnN0IHJlbmRlcmVyID0gbFZpZXdbUkVOREVSRVJdO1xuICBhcHBseVZpZXcodFZpZXcsIGxWaWV3LCByZW5kZXJlciwgV2Fsa1ROb2RlVHJlZUFjdGlvbi5EZXRhY2gsIG51bGwsIG51bGwpO1xuICBsVmlld1tIT1NUXSA9IG51bGw7XG4gIGxWaWV3W1RfSE9TVF0gPSBudWxsO1xufVxuXG4vKipcbiAqIEFkZHMgYWxsIERPTSBlbGVtZW50cyBhc3NvY2lhdGVkIHdpdGggYSB2aWV3LlxuICpcbiAqIEJlY2F1c2Ugc29tZSByb290IG5vZGVzIG9mIHRoZSB2aWV3IG1heSBiZSBjb250YWluZXJzLCB3ZSBzb21ldGltZXMgbmVlZFxuICogdG8gcHJvcGFnYXRlIGRlZXBseSBpbnRvIHRoZSBuZXN0ZWQgY29udGFpbmVycyB0byBhZGQgYWxsIGVsZW1lbnRzIGluIHRoZVxuICogdmlld3MgYmVuZWF0aCBpdC5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgVGhlIGBUVmlldycgb2YgdGhlIGBMVmlld2AgZnJvbSB3aGljaCBlbGVtZW50cyBzaG91bGQgYmUgYWRkZWQgb3IgcmVtb3ZlZFxuICogQHBhcmFtIHBhcmVudFROb2RlIFRoZSBgVE5vZGVgIHdoZXJlIHRoZSBgTFZpZXdgIHNob3VsZCBiZSBhdHRhY2hlZCB0by5cbiAqIEBwYXJhbSByZW5kZXJlciBDdXJyZW50IHJlbmRlcmVyIHRvIHVzZSBmb3IgRE9NIG1hbmlwdWxhdGlvbnMuXG4gKiBAcGFyYW0gbFZpZXcgVGhlIHZpZXcgZnJvbSB3aGljaCBlbGVtZW50cyBzaG91bGQgYmUgYWRkZWQgb3IgcmVtb3ZlZFxuICogQHBhcmFtIHBhcmVudE5hdGl2ZU5vZGUgVGhlIHBhcmVudCBgUkVsZW1lbnRgIHdoZXJlIGl0IHNob3VsZCBiZSBpbnNlcnRlZCBpbnRvLlxuICogQHBhcmFtIGJlZm9yZU5vZGUgVGhlIG5vZGUgYmVmb3JlIHdoaWNoIGVsZW1lbnRzIHNob3VsZCBiZSBhZGRlZCwgaWYgaW5zZXJ0IG1vZGVcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGFkZFZpZXdUb0NvbnRhaW5lcihcbiAgICB0VmlldzogVFZpZXcsIHBhcmVudFROb2RlOiBUTm9kZSwgcmVuZGVyZXI6IFJlbmRlcmVyLCBsVmlldzogTFZpZXcsIHBhcmVudE5hdGl2ZU5vZGU6IFJFbGVtZW50LFxuICAgIGJlZm9yZU5vZGU6IFJOb2RlfG51bGwpOiB2b2lkIHtcbiAgbFZpZXdbSE9TVF0gPSBwYXJlbnROYXRpdmVOb2RlO1xuICBsVmlld1tUX0hPU1RdID0gcGFyZW50VE5vZGU7XG4gIGFwcGx5Vmlldyh0VmlldywgbFZpZXcsIHJlbmRlcmVyLCBXYWxrVE5vZGVUcmVlQWN0aW9uLkluc2VydCwgcGFyZW50TmF0aXZlTm9kZSwgYmVmb3JlTm9kZSk7XG59XG5cblxuLyoqXG4gKiBEZXRhY2ggYSBgTFZpZXdgIGZyb20gdGhlIERPTSBieSBkZXRhY2hpbmcgaXRzIG5vZGVzLlxuICpcbiAqIEBwYXJhbSB0VmlldyBUaGUgYFRWaWV3JyBvZiB0aGUgYExWaWV3YCB0byBiZSBkZXRhY2hlZFxuICogQHBhcmFtIGxWaWV3IHRoZSBgTFZpZXdgIHRvIGJlIGRldGFjaGVkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gcmVuZGVyRGV0YWNoVmlldyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldykge1xuICBhcHBseVZpZXcodFZpZXcsIGxWaWV3LCBsVmlld1tSRU5ERVJFUl0sIFdhbGtUTm9kZVRyZWVBY3Rpb24uRGV0YWNoLCBudWxsLCBudWxsKTtcbn1cblxuLyoqXG4gKiBUcmF2ZXJzZXMgZG93biBhbmQgdXAgdGhlIHRyZWUgb2Ygdmlld3MgYW5kIGNvbnRhaW5lcnMgdG8gcmVtb3ZlIGxpc3RlbmVycyBhbmRcbiAqIGNhbGwgb25EZXN0cm95IGNhbGxiYWNrcy5cbiAqXG4gKiBOb3RlczpcbiAqICAtIEJlY2F1c2UgaXQncyB1c2VkIGZvciBvbkRlc3Ryb3kgY2FsbHMsIGl0IG5lZWRzIHRvIGJlIGJvdHRvbS11cC5cbiAqICAtIE11c3QgcHJvY2VzcyBjb250YWluZXJzIGluc3RlYWQgb2YgdGhlaXIgdmlld3MgdG8gYXZvaWQgc3BsaWNpbmdcbiAqICB3aGVuIHZpZXdzIGFyZSBkZXN0cm95ZWQgYW5kIHJlLWFkZGVkLlxuICogIC0gVXNpbmcgYSB3aGlsZSBsb29wIGJlY2F1c2UgaXQncyBmYXN0ZXIgdGhhbiByZWN1cnNpb25cbiAqICAtIERlc3Ryb3kgb25seSBjYWxsZWQgb24gbW92ZW1lbnQgdG8gc2libGluZyBvciBtb3ZlbWVudCB0byBwYXJlbnQgKGxhdGVyYWxseSBvciB1cClcbiAqXG4gKiAgQHBhcmFtIHJvb3RWaWV3IFRoZSB2aWV3IHRvIGRlc3Ryb3lcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGRlc3Ryb3lWaWV3VHJlZShyb290VmlldzogTFZpZXcpOiB2b2lkIHtcbiAgLy8gSWYgdGhlIHZpZXcgaGFzIG5vIGNoaWxkcmVuLCB3ZSBjYW4gY2xlYW4gaXQgdXAgYW5kIHJldHVybiBlYXJseS5cbiAgbGV0IGxWaWV3T3JMQ29udGFpbmVyID0gcm9vdFZpZXdbQ0hJTERfSEVBRF07XG4gIGlmICghbFZpZXdPckxDb250YWluZXIpIHtcbiAgICByZXR1cm4gY2xlYW5VcFZpZXcocm9vdFZpZXdbVFZJRVddLCByb290Vmlldyk7XG4gIH1cblxuICB3aGlsZSAobFZpZXdPckxDb250YWluZXIpIHtcbiAgICBsZXQgbmV4dDogTFZpZXd8TENvbnRhaW5lcnxudWxsID0gbnVsbDtcblxuICAgIGlmIChpc0xWaWV3KGxWaWV3T3JMQ29udGFpbmVyKSkge1xuICAgICAgLy8gSWYgTFZpZXcsIHRyYXZlcnNlIGRvd24gdG8gY2hpbGQuXG4gICAgICBuZXh0ID0gbFZpZXdPckxDb250YWluZXJbQ0hJTERfSEVBRF07XG4gICAgfSBlbHNlIHtcbiAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRMQ29udGFpbmVyKGxWaWV3T3JMQ29udGFpbmVyKTtcbiAgICAgIC8vIElmIGNvbnRhaW5lciwgdHJhdmVyc2UgZG93biB0byBpdHMgZmlyc3QgTFZpZXcuXG4gICAgICBjb25zdCBmaXJzdFZpZXc6IExWaWV3fHVuZGVmaW5lZCA9IGxWaWV3T3JMQ29udGFpbmVyW0NPTlRBSU5FUl9IRUFERVJfT0ZGU0VUXTtcbiAgICAgIGlmIChmaXJzdFZpZXcpIG5leHQgPSBmaXJzdFZpZXc7XG4gICAgfVxuXG4gICAgaWYgKCFuZXh0KSB7XG4gICAgICAvLyBPbmx5IGNsZWFuIHVwIHZpZXcgd2hlbiBtb3ZpbmcgdG8gdGhlIHNpZGUgb3IgdXAsIGFzIGRlc3Ryb3kgaG9va3NcbiAgICAgIC8vIHNob3VsZCBiZSBjYWxsZWQgaW4gb3JkZXIgZnJvbSB0aGUgYm90dG9tIHVwLlxuICAgICAgd2hpbGUgKGxWaWV3T3JMQ29udGFpbmVyICYmICFsVmlld09yTENvbnRhaW5lciFbTkVYVF0gJiYgbFZpZXdPckxDb250YWluZXIgIT09IHJvb3RWaWV3KSB7XG4gICAgICAgIGlmIChpc0xWaWV3KGxWaWV3T3JMQ29udGFpbmVyKSkge1xuICAgICAgICAgIGNsZWFuVXBWaWV3KGxWaWV3T3JMQ29udGFpbmVyW1RWSUVXXSwgbFZpZXdPckxDb250YWluZXIpO1xuICAgICAgICB9XG4gICAgICAgIGxWaWV3T3JMQ29udGFpbmVyID0gbFZpZXdPckxDb250YWluZXJbUEFSRU5UXTtcbiAgICAgIH1cbiAgICAgIGlmIChsVmlld09yTENvbnRhaW5lciA9PT0gbnVsbCkgbFZpZXdPckxDb250YWluZXIgPSByb290VmlldztcbiAgICAgIGlmIChpc0xWaWV3KGxWaWV3T3JMQ29udGFpbmVyKSkge1xuICAgICAgICBjbGVhblVwVmlldyhsVmlld09yTENvbnRhaW5lcltUVklFV10sIGxWaWV3T3JMQ29udGFpbmVyKTtcbiAgICAgIH1cbiAgICAgIG5leHQgPSBsVmlld09yTENvbnRhaW5lciAmJiBsVmlld09yTENvbnRhaW5lciFbTkVYVF07XG4gICAgfVxuICAgIGxWaWV3T3JMQ29udGFpbmVyID0gbmV4dDtcbiAgfVxufVxuXG4vKipcbiAqIEluc2VydHMgYSB2aWV3IGludG8gYSBjb250YWluZXIuXG4gKlxuICogVGhpcyBhZGRzIHRoZSB2aWV3IHRvIHRoZSBjb250YWluZXIncyBhcnJheSBvZiBhY3RpdmUgdmlld3MgaW4gdGhlIGNvcnJlY3RcbiAqIHBvc2l0aW9uLiBJdCBhbHNvIGFkZHMgdGhlIHZpZXcncyBlbGVtZW50cyB0byB0aGUgRE9NIGlmIHRoZSBjb250YWluZXIgaXNuJ3QgYVxuICogcm9vdCBub2RlIG9mIGFub3RoZXIgdmlldyAoaW4gdGhhdCBjYXNlLCB0aGUgdmlldydzIGVsZW1lbnRzIHdpbGwgYmUgYWRkZWQgd2hlblxuICogdGhlIGNvbnRhaW5lcidzIHBhcmVudCB2aWV3IGlzIGFkZGVkIGxhdGVyKS5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgVGhlIGBUVmlldycgb2YgdGhlIGBMVmlld2AgdG8gaW5zZXJ0XG4gKiBAcGFyYW0gbFZpZXcgVGhlIHZpZXcgdG8gaW5zZXJ0XG4gKiBAcGFyYW0gbENvbnRhaW5lciBUaGUgY29udGFpbmVyIGludG8gd2hpY2ggdGhlIHZpZXcgc2hvdWxkIGJlIGluc2VydGVkXG4gKiBAcGFyYW0gaW5kZXggV2hpY2ggaW5kZXggaW4gdGhlIGNvbnRhaW5lciB0byBpbnNlcnQgdGhlIGNoaWxkIHZpZXcgaW50b1xuICovXG5leHBvcnQgZnVuY3Rpb24gaW5zZXJ0Vmlldyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgbENvbnRhaW5lcjogTENvbnRhaW5lciwgaW5kZXg6IG51bWJlcikge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TFZpZXcobFZpZXcpO1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TENvbnRhaW5lcihsQ29udGFpbmVyKTtcbiAgY29uc3QgaW5kZXhJbkNvbnRhaW5lciA9IENPTlRBSU5FUl9IRUFERVJfT0ZGU0VUICsgaW5kZXg7XG4gIGNvbnN0IGNvbnRhaW5lckxlbmd0aCA9IGxDb250YWluZXIubGVuZ3RoO1xuXG4gIGlmIChpbmRleCA+IDApIHtcbiAgICAvLyBUaGlzIGlzIGEgbmV3IHZpZXcsIHdlIG5lZWQgdG8gYWRkIGl0IHRvIHRoZSBjaGlsZHJlbi5cbiAgICBsQ29udGFpbmVyW2luZGV4SW5Db250YWluZXIgLSAxXVtORVhUXSA9IGxWaWV3O1xuICB9XG4gIGlmIChpbmRleCA8IGNvbnRhaW5lckxlbmd0aCAtIENPTlRBSU5FUl9IRUFERVJfT0ZGU0VUKSB7XG4gICAgbFZpZXdbTkVYVF0gPSBsQ29udGFpbmVyW2luZGV4SW5Db250YWluZXJdO1xuICAgIGFkZFRvQXJyYXkobENvbnRhaW5lciwgQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQgKyBpbmRleCwgbFZpZXcpO1xuICB9IGVsc2Uge1xuICAgIGxDb250YWluZXIucHVzaChsVmlldyk7XG4gICAgbFZpZXdbTkVYVF0gPSBudWxsO1xuICB9XG5cbiAgbFZpZXdbUEFSRU5UXSA9IGxDb250YWluZXI7XG5cbiAgLy8gdHJhY2sgdmlld3Mgd2hlcmUgZGVjbGFyYXRpb24gYW5kIGluc2VydGlvbiBwb2ludHMgYXJlIGRpZmZlcmVudFxuICBjb25zdCBkZWNsYXJhdGlvbkxDb250YWluZXIgPSBsVmlld1tERUNMQVJBVElPTl9MQ09OVEFJTkVSXTtcbiAgaWYgKGRlY2xhcmF0aW9uTENvbnRhaW5lciAhPT0gbnVsbCAmJiBsQ29udGFpbmVyICE9PSBkZWNsYXJhdGlvbkxDb250YWluZXIpIHtcbiAgICB0cmFja01vdmVkVmlldyhkZWNsYXJhdGlvbkxDb250YWluZXIsIGxWaWV3KTtcbiAgfVxuXG4gIC8vIG5vdGlmeSBxdWVyeSB0aGF0IGEgbmV3IHZpZXcgaGFzIGJlZW4gYWRkZWRcbiAgY29uc3QgbFF1ZXJpZXMgPSBsVmlld1tRVUVSSUVTXTtcbiAgaWYgKGxRdWVyaWVzICE9PSBudWxsKSB7XG4gICAgbFF1ZXJpZXMuaW5zZXJ0Vmlldyh0Vmlldyk7XG4gIH1cblxuICAvLyBTZXRzIHRoZSBhdHRhY2hlZCBmbGFnXG4gIGxWaWV3W0ZMQUdTXSB8PSBMVmlld0ZsYWdzLkF0dGFjaGVkO1xufVxuXG4vKipcbiAqIFRyYWNrIHZpZXdzIGNyZWF0ZWQgZnJvbSB0aGUgZGVjbGFyYXRpb24gY29udGFpbmVyIChUZW1wbGF0ZVJlZikgYW5kIGluc2VydGVkIGludG8gYVxuICogZGlmZmVyZW50IExDb250YWluZXIuXG4gKi9cbmZ1bmN0aW9uIHRyYWNrTW92ZWRWaWV3KGRlY2xhcmF0aW9uQ29udGFpbmVyOiBMQ29udGFpbmVyLCBsVmlldzogTFZpZXcpIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQobFZpZXcsICdMVmlldyByZXF1aXJlZCcpO1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TENvbnRhaW5lcihkZWNsYXJhdGlvbkNvbnRhaW5lcik7XG4gIGNvbnN0IG1vdmVkVmlld3MgPSBkZWNsYXJhdGlvbkNvbnRhaW5lcltNT1ZFRF9WSUVXU107XG4gIGNvbnN0IGluc2VydGVkTENvbnRhaW5lciA9IGxWaWV3W1BBUkVOVF0gYXMgTENvbnRhaW5lcjtcbiAgbmdEZXZNb2RlICYmIGFzc2VydExDb250YWluZXIoaW5zZXJ0ZWRMQ29udGFpbmVyKTtcbiAgY29uc3QgaW5zZXJ0ZWRDb21wb25lbnRMVmlldyA9IGluc2VydGVkTENvbnRhaW5lcltQQVJFTlRdIVtERUNMQVJBVElPTl9DT01QT05FTlRfVklFV107XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGluc2VydGVkQ29tcG9uZW50TFZpZXcsICdNaXNzaW5nIGluc2VydGVkQ29tcG9uZW50TFZpZXcnKTtcbiAgY29uc3QgZGVjbGFyZWRDb21wb25lbnRMVmlldyA9IGxWaWV3W0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXXTtcbiAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQoZGVjbGFyZWRDb21wb25lbnRMVmlldywgJ01pc3NpbmcgZGVjbGFyZWRDb21wb25lbnRMVmlldycpO1xuICBpZiAoZGVjbGFyZWRDb21wb25lbnRMVmlldyAhPT0gaW5zZXJ0ZWRDb21wb25lbnRMVmlldykge1xuICAgIC8vIEF0IHRoaXMgcG9pbnQgdGhlIGRlY2xhcmF0aW9uLWNvbXBvbmVudCBpcyBub3Qgc2FtZSBhcyBpbnNlcnRpb24tY29tcG9uZW50OyB0aGlzIG1lYW5zIHRoYXRcbiAgICAvLyB0aGlzIGlzIGEgdHJhbnNwbGFudGVkIHZpZXcuIE1hcmsgdGhlIGRlY2xhcmVkIGxWaWV3IGFzIGhhdmluZyB0cmFuc3BsYW50ZWQgdmlld3Mgc28gdGhhdFxuICAgIC8vIHRob3NlIHZpZXdzIGNhbiBwYXJ0aWNpcGF0ZSBpbiBDRC5cbiAgICBkZWNsYXJhdGlvbkNvbnRhaW5lcltIQVNfVFJBTlNQTEFOVEVEX1ZJRVdTXSA9IHRydWU7XG4gIH1cbiAgaWYgKG1vdmVkVmlld3MgPT09IG51bGwpIHtcbiAgICBkZWNsYXJhdGlvbkNvbnRhaW5lcltNT1ZFRF9WSUVXU10gPSBbbFZpZXddO1xuICB9IGVsc2Uge1xuICAgIG1vdmVkVmlld3MucHVzaChsVmlldyk7XG4gIH1cbn1cblxuZnVuY3Rpb24gZGV0YWNoTW92ZWRWaWV3KGRlY2xhcmF0aW9uQ29udGFpbmVyOiBMQ29udGFpbmVyLCBsVmlldzogTFZpZXcpIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydExDb250YWluZXIoZGVjbGFyYXRpb25Db250YWluZXIpO1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydERlZmluZWQoXG4gICAgICAgICAgZGVjbGFyYXRpb25Db250YWluZXJbTU9WRURfVklFV1NdLFxuICAgICAgICAgICdBIHByb2plY3RlZCB2aWV3IHNob3VsZCBiZWxvbmcgdG8gYSBub24tZW1wdHkgcHJvamVjdGVkIHZpZXdzIGNvbGxlY3Rpb24nKTtcbiAgY29uc3QgbW92ZWRWaWV3cyA9IGRlY2xhcmF0aW9uQ29udGFpbmVyW01PVkVEX1ZJRVdTXSE7XG4gIGNvbnN0IGRlY2xhcmF0aW9uVmlld0luZGV4ID0gbW92ZWRWaWV3cy5pbmRleE9mKGxWaWV3KTtcbiAgY29uc3QgaW5zZXJ0aW9uTENvbnRhaW5lciA9IGxWaWV3W1BBUkVOVF0gYXMgTENvbnRhaW5lcjtcbiAgbmdEZXZNb2RlICYmIGFzc2VydExDb250YWluZXIoaW5zZXJ0aW9uTENvbnRhaW5lcik7XG5cbiAgLy8gSWYgdGhlIHZpZXcgd2FzIG1hcmtlZCBmb3IgcmVmcmVzaCBidXQgdGhlbiBkZXRhY2hlZCBiZWZvcmUgaXQgd2FzIGNoZWNrZWQgKHdoZXJlIHRoZSBmbGFnXG4gIC8vIHdvdWxkIGJlIGNsZWFyZWQgYW5kIHRoZSBjb3VudGVyIGRlY3JlbWVudGVkKSwgd2UgbmVlZCB0byB1cGRhdGUgdGhlIHN0YXR1cyBoZXJlLlxuICBjbGVhclZpZXdSZWZyZXNoRmxhZyhsVmlldyk7XG5cbiAgbW92ZWRWaWV3cy5zcGxpY2UoZGVjbGFyYXRpb25WaWV3SW5kZXgsIDEpO1xufVxuXG4vKipcbiAqIERldGFjaGVzIGEgdmlldyBmcm9tIGEgY29udGFpbmVyLlxuICpcbiAqIFRoaXMgbWV0aG9kIHJlbW92ZXMgdGhlIHZpZXcgZnJvbSB0aGUgY29udGFpbmVyJ3MgYXJyYXkgb2YgYWN0aXZlIHZpZXdzLiBJdCBhbHNvXG4gKiByZW1vdmVzIHRoZSB2aWV3J3MgZWxlbWVudHMgZnJvbSB0aGUgRE9NLlxuICpcbiAqIEBwYXJhbSBsQ29udGFpbmVyIFRoZSBjb250YWluZXIgZnJvbSB3aGljaCB0byBkZXRhY2ggYSB2aWV3XG4gKiBAcGFyYW0gcmVtb3ZlSW5kZXggVGhlIGluZGV4IG9mIHRoZSB2aWV3IHRvIGRldGFjaFxuICogQHJldHVybnMgRGV0YWNoZWQgTFZpZXcgaW5zdGFuY2UuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBkZXRhY2hWaWV3KGxDb250YWluZXI6IExDb250YWluZXIsIHJlbW92ZUluZGV4OiBudW1iZXIpOiBMVmlld3x1bmRlZmluZWQge1xuICBpZiAobENvbnRhaW5lci5sZW5ndGggPD0gQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQpIHJldHVybjtcblxuICBjb25zdCBpbmRleEluQ29udGFpbmVyID0gQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQgKyByZW1vdmVJbmRleDtcbiAgY29uc3Qgdmlld1RvRGV0YWNoID0gbENvbnRhaW5lcltpbmRleEluQ29udGFpbmVyXTtcblxuICBpZiAodmlld1RvRGV0YWNoKSB7XG4gICAgY29uc3QgZGVjbGFyYXRpb25MQ29udGFpbmVyID0gdmlld1RvRGV0YWNoW0RFQ0xBUkFUSU9OX0xDT05UQUlORVJdO1xuICAgIGlmIChkZWNsYXJhdGlvbkxDb250YWluZXIgIT09IG51bGwgJiYgZGVjbGFyYXRpb25MQ29udGFpbmVyICE9PSBsQ29udGFpbmVyKSB7XG4gICAgICBkZXRhY2hNb3ZlZFZpZXcoZGVjbGFyYXRpb25MQ29udGFpbmVyLCB2aWV3VG9EZXRhY2gpO1xuICAgIH1cblxuXG4gICAgaWYgKHJlbW92ZUluZGV4ID4gMCkge1xuICAgICAgbENvbnRhaW5lcltpbmRleEluQ29udGFpbmVyIC0gMV1bTkVYVF0gPSB2aWV3VG9EZXRhY2hbTkVYVF0gYXMgTFZpZXc7XG4gICAgfVxuICAgIGNvbnN0IHJlbW92ZWRMVmlldyA9IHJlbW92ZUZyb21BcnJheShsQ29udGFpbmVyLCBDT05UQUlORVJfSEVBREVSX09GRlNFVCArIHJlbW92ZUluZGV4KTtcbiAgICByZW1vdmVWaWV3RnJvbUNvbnRhaW5lcih2aWV3VG9EZXRhY2hbVFZJRVddLCB2aWV3VG9EZXRhY2gpO1xuXG4gICAgLy8gbm90aWZ5IHF1ZXJ5IHRoYXQgYSB2aWV3IGhhcyBiZWVuIHJlbW92ZWRcbiAgICBjb25zdCBsUXVlcmllcyA9IHJlbW92ZWRMVmlld1tRVUVSSUVTXTtcbiAgICBpZiAobFF1ZXJpZXMgIT09IG51bGwpIHtcbiAgICAgIGxRdWVyaWVzLmRldGFjaFZpZXcocmVtb3ZlZExWaWV3W1RWSUVXXSk7XG4gICAgfVxuXG4gICAgdmlld1RvRGV0YWNoW1BBUkVOVF0gPSBudWxsO1xuICAgIHZpZXdUb0RldGFjaFtORVhUXSA9IG51bGw7XG4gICAgLy8gVW5zZXRzIHRoZSBhdHRhY2hlZCBmbGFnXG4gICAgdmlld1RvRGV0YWNoW0ZMQUdTXSAmPSB+TFZpZXdGbGFncy5BdHRhY2hlZDtcbiAgfVxuICByZXR1cm4gdmlld1RvRGV0YWNoO1xufVxuXG4vKipcbiAqIEEgc3RhbmRhbG9uZSBmdW5jdGlvbiB3aGljaCBkZXN0cm95cyBhbiBMVmlldyxcbiAqIGNvbmR1Y3RpbmcgY2xlYW4gdXAgKGUuZy4gcmVtb3ZpbmcgbGlzdGVuZXJzLCBjYWxsaW5nIG9uRGVzdHJveXMpLlxuICpcbiAqIEBwYXJhbSB0VmlldyBUaGUgYFRWaWV3JyBvZiB0aGUgYExWaWV3YCB0byBiZSBkZXN0cm95ZWRcbiAqIEBwYXJhbSBsVmlldyBUaGUgdmlldyB0byBiZSBkZXN0cm95ZWQuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBkZXN0cm95TFZpZXcodFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcpIHtcbiAgaWYgKCEobFZpZXdbRkxBR1NdICYgTFZpZXdGbGFncy5EZXN0cm95ZWQpKSB7XG4gICAgY29uc3QgcmVuZGVyZXIgPSBsVmlld1tSRU5ERVJFUl07XG5cbiAgICBsVmlld1tSRUFDVElWRV9URU1QTEFURV9DT05TVU1FUl0/LmRlc3Ryb3koKTtcbiAgICBsVmlld1tSRUFDVElWRV9IT1NUX0JJTkRJTkdfQ09OU1VNRVJdPy5kZXN0cm95KCk7XG5cbiAgICBpZiAocmVuZGVyZXIuZGVzdHJveU5vZGUpIHtcbiAgICAgIGFwcGx5Vmlldyh0VmlldywgbFZpZXcsIHJlbmRlcmVyLCBXYWxrVE5vZGVUcmVlQWN0aW9uLkRlc3Ryb3ksIG51bGwsIG51bGwpO1xuICAgIH1cblxuICAgIGRlc3Ryb3lWaWV3VHJlZShsVmlldyk7XG4gIH1cbn1cblxuLyoqXG4gKiBDYWxscyBvbkRlc3Ryb3lzIGhvb2tzIGZvciBhbGwgZGlyZWN0aXZlcyBhbmQgcGlwZXMgaW4gYSBnaXZlbiB2aWV3IGFuZCB0aGVuIHJlbW92ZXMgYWxsXG4gKiBsaXN0ZW5lcnMuIExpc3RlbmVycyBhcmUgcmVtb3ZlZCBhcyB0aGUgbGFzdCBzdGVwIHNvIGV2ZW50cyBkZWxpdmVyZWQgaW4gdGhlIG9uRGVzdHJveXMgaG9va3NcbiAqIGNhbiBiZSBwcm9wYWdhdGVkIHRvIEBPdXRwdXQgbGlzdGVuZXJzLlxuICpcbiAqIEBwYXJhbSB0VmlldyBgVFZpZXdgIGZvciB0aGUgYExWaWV3YCB0byBjbGVhbiB1cC5cbiAqIEBwYXJhbSBsVmlldyBUaGUgTFZpZXcgdG8gY2xlYW4gdXBcbiAqL1xuZnVuY3Rpb24gY2xlYW5VcFZpZXcodFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcpOiB2b2lkIHtcbiAgaWYgKCEobFZpZXdbRkxBR1NdICYgTFZpZXdGbGFncy5EZXN0cm95ZWQpKSB7XG4gICAgLy8gVXN1YWxseSB0aGUgQXR0YWNoZWQgZmxhZyBpcyByZW1vdmVkIHdoZW4gdGhlIHZpZXcgaXMgZGV0YWNoZWQgZnJvbSBpdHMgcGFyZW50LCBob3dldmVyXG4gICAgLy8gaWYgaXQncyBhIHJvb3QgdmlldywgdGhlIGZsYWcgd29uJ3QgYmUgdW5zZXQgaGVuY2Ugd2h5IHdlJ3JlIGFsc28gcmVtb3Zpbmcgb24gZGVzdHJveS5cbiAgICBsVmlld1tGTEFHU10gJj0gfkxWaWV3RmxhZ3MuQXR0YWNoZWQ7XG5cbiAgICAvLyBNYXJrIHRoZSBMVmlldyBhcyBkZXN0cm95ZWQgKmJlZm9yZSogZXhlY3V0aW5nIHRoZSBvbkRlc3Ryb3kgaG9va3MuIEFuIG9uRGVzdHJveSBob29rXG4gICAgLy8gcnVucyBhcmJpdHJhcnkgdXNlciBjb2RlLCB3aGljaCBjb3VsZCBpbmNsdWRlIGl0cyBvd24gYHZpZXdSZWYuZGVzdHJveSgpYCAob3Igc2ltaWxhcikuIElmXG4gICAgLy8gV2UgZG9uJ3QgZmxhZyB0aGUgdmlldyBhcyBkZXN0cm95ZWQgYmVmb3JlIHRoZSBob29rcywgdGhpcyBjb3VsZCBsZWFkIHRvIGFuIGluZmluaXRlIGxvb3AuXG4gICAgLy8gVGhpcyBhbHNvIGFsaWducyB3aXRoIHRoZSBWaWV3RW5naW5lIGJlaGF2aW9yLiBJdCBhbHNvIG1lYW5zIHRoYXQgdGhlIG9uRGVzdHJveSBob29rIGlzXG4gICAgLy8gcmVhbGx5IG1vcmUgb2YgYW4gXCJhZnRlckRlc3Ryb3lcIiBob29rIGlmIHlvdSB0aGluayBhYm91dCBpdC5cbiAgICBsVmlld1tGTEFHU10gfD0gTFZpZXdGbGFncy5EZXN0cm95ZWQ7XG5cbiAgICBleGVjdXRlT25EZXN0cm95cyh0VmlldywgbFZpZXcpO1xuICAgIHByb2Nlc3NDbGVhbnVwcyh0VmlldywgbFZpZXcpO1xuICAgIC8vIEZvciBjb21wb25lbnQgdmlld3Mgb25seSwgdGhlIGxvY2FsIHJlbmRlcmVyIGlzIGRlc3Ryb3llZCBhdCBjbGVhbiB1cCB0aW1lLlxuICAgIGlmIChsVmlld1tUVklFV10udHlwZSA9PT0gVFZpZXdUeXBlLkNvbXBvbmVudCkge1xuICAgICAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlckRlc3Ryb3krKztcbiAgICAgIGxWaWV3W1JFTkRFUkVSXS5kZXN0cm95KCk7XG4gICAgfVxuXG4gICAgY29uc3QgZGVjbGFyYXRpb25Db250YWluZXIgPSBsVmlld1tERUNMQVJBVElPTl9MQ09OVEFJTkVSXTtcbiAgICAvLyB3ZSBhcmUgZGVhbGluZyB3aXRoIGFuIGVtYmVkZGVkIHZpZXcgdGhhdCBpcyBzdGlsbCBpbnNlcnRlZCBpbnRvIGEgY29udGFpbmVyXG4gICAgaWYgKGRlY2xhcmF0aW9uQ29udGFpbmVyICE9PSBudWxsICYmIGlzTENvbnRhaW5lcihsVmlld1tQQVJFTlRdKSkge1xuICAgICAgLy8gYW5kIHRoaXMgaXMgYSBwcm9qZWN0ZWQgdmlld1xuICAgICAgaWYgKGRlY2xhcmF0aW9uQ29udGFpbmVyICE9PSBsVmlld1tQQVJFTlRdKSB7XG4gICAgICAgIGRldGFjaE1vdmVkVmlldyhkZWNsYXJhdGlvbkNvbnRhaW5lciwgbFZpZXcpO1xuICAgICAgfVxuXG4gICAgICAvLyBGb3IgZW1iZWRkZWQgdmlld3Mgc3RpbGwgYXR0YWNoZWQgdG8gYSBjb250YWluZXI6IHJlbW92ZSBxdWVyeSByZXN1bHQgZnJvbSB0aGlzIHZpZXcuXG4gICAgICBjb25zdCBsUXVlcmllcyA9IGxWaWV3W1FVRVJJRVNdO1xuICAgICAgaWYgKGxRdWVyaWVzICE9PSBudWxsKSB7XG4gICAgICAgIGxRdWVyaWVzLmRldGFjaFZpZXcodFZpZXcpO1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIFVucmVnaXN0ZXIgdGhlIHZpZXcgb25jZSBldmVyeXRoaW5nIGVsc2UgaGFzIGJlZW4gY2xlYW5lZCB1cC5cbiAgICB1bnJlZ2lzdGVyTFZpZXcobFZpZXcpO1xuICB9XG59XG5cbi8qKiBSZW1vdmVzIGxpc3RlbmVycyBhbmQgdW5zdWJzY3JpYmVzIGZyb20gb3V0cHV0IHN1YnNjcmlwdGlvbnMgKi9cbmZ1bmN0aW9uIHByb2Nlc3NDbGVhbnVwcyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldyk6IHZvaWQge1xuICBjb25zdCB0Q2xlYW51cCA9IHRWaWV3LmNsZWFudXA7XG4gIGNvbnN0IGxDbGVhbnVwID0gbFZpZXdbQ0xFQU5VUF0hO1xuICBpZiAodENsZWFudXAgIT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IHRDbGVhbnVwLmxlbmd0aCAtIDE7IGkgKz0gMikge1xuICAgICAgaWYgKHR5cGVvZiB0Q2xlYW51cFtpXSA9PT0gJ3N0cmluZycpIHtcbiAgICAgICAgLy8gVGhpcyBpcyBhIG5hdGl2ZSBET00gbGlzdGVuZXIuIEl0IHdpbGwgb2NjdXB5IDQgZW50cmllcyBpbiB0aGUgVENsZWFudXAgYXJyYXkgKGhlbmNlIGkgKz1cbiAgICAgICAgLy8gMiBhdCB0aGUgZW5kIG9mIHRoaXMgYmxvY2spLlxuICAgICAgICBjb25zdCB0YXJnZXRJZHggPSB0Q2xlYW51cFtpICsgM107XG4gICAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnROdW1iZXIodGFyZ2V0SWR4LCAnY2xlYW51cCB0YXJnZXQgbXVzdCBiZSBhIG51bWJlcicpO1xuICAgICAgICBpZiAodGFyZ2V0SWR4ID49IDApIHtcbiAgICAgICAgICAvLyB1bnJlZ2lzdGVyXG4gICAgICAgICAgbENsZWFudXBbdGFyZ2V0SWR4XSgpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIC8vIFN1YnNjcmlwdGlvblxuICAgICAgICAgIGxDbGVhbnVwWy10YXJnZXRJZHhdLnVuc3Vic2NyaWJlKCk7XG4gICAgICAgIH1cbiAgICAgICAgaSArPSAyO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgLy8gVGhpcyBpcyBhIGNsZWFudXAgZnVuY3Rpb24gdGhhdCBpcyBncm91cGVkIHdpdGggdGhlIGluZGV4IG9mIGl0cyBjb250ZXh0XG4gICAgICAgIGNvbnN0IGNvbnRleHQgPSBsQ2xlYW51cFt0Q2xlYW51cFtpICsgMV1dO1xuICAgICAgICB0Q2xlYW51cFtpXS5jYWxsKGNvbnRleHQpO1xuICAgICAgfVxuICAgIH1cbiAgfVxuICBpZiAobENsZWFudXAgIT09IG51bGwpIHtcbiAgICBsVmlld1tDTEVBTlVQXSA9IG51bGw7XG4gIH1cbiAgY29uc3QgZGVzdHJveUhvb2tzID0gbFZpZXdbT05fREVTVFJPWV9IT09LU107XG4gIGlmIChkZXN0cm95SG9va3MgIT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGRlc3Ryb3lIb29rcy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3QgZGVzdHJveUhvb2tzRm4gPSBkZXN0cm95SG9va3NbaV07XG4gICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RnVuY3Rpb24oZGVzdHJveUhvb2tzRm4sICdFeHBlY3RpbmcgZGVzdHJveSBob29rIHRvIGJlIGEgZnVuY3Rpb24uJyk7XG4gICAgICBkZXN0cm95SG9va3NGbigpO1xuICAgIH1cbiAgICBsVmlld1tPTl9ERVNUUk9ZX0hPT0tTXSA9IG51bGw7XG4gIH1cbn1cblxuLyoqIENhbGxzIG9uRGVzdHJveSBob29rcyBmb3IgdGhpcyB2aWV3ICovXG5mdW5jdGlvbiBleGVjdXRlT25EZXN0cm95cyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldyk6IHZvaWQge1xuICBsZXQgZGVzdHJveUhvb2tzOiBEZXN0cm95SG9va0RhdGF8bnVsbDtcblxuICBpZiAodFZpZXcgIT0gbnVsbCAmJiAoZGVzdHJveUhvb2tzID0gdFZpZXcuZGVzdHJveUhvb2tzKSAhPSBudWxsKSB7XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBkZXN0cm95SG9va3MubGVuZ3RoOyBpICs9IDIpIHtcbiAgICAgIGNvbnN0IGNvbnRleHQgPSBsVmlld1tkZXN0cm95SG9va3NbaV0gYXMgbnVtYmVyXTtcblxuICAgICAgLy8gT25seSBjYWxsIHRoZSBkZXN0cm95IGhvb2sgaWYgdGhlIGNvbnRleHQgaGFzIGJlZW4gcmVxdWVzdGVkLlxuICAgICAgaWYgKCEoY29udGV4dCBpbnN0YW5jZW9mIE5vZGVJbmplY3RvckZhY3RvcnkpKSB7XG4gICAgICAgIGNvbnN0IHRvQ2FsbCA9IGRlc3Ryb3lIb29rc1tpICsgMV0gYXMgSG9va0ZuIHwgSG9va0RhdGE7XG5cbiAgICAgICAgaWYgKEFycmF5LmlzQXJyYXkodG9DYWxsKSkge1xuICAgICAgICAgIGZvciAobGV0IGogPSAwOyBqIDwgdG9DYWxsLmxlbmd0aDsgaiArPSAyKSB7XG4gICAgICAgICAgICBjb25zdCBjYWxsQ29udGV4dCA9IGNvbnRleHRbdG9DYWxsW2pdIGFzIG51bWJlcl07XG4gICAgICAgICAgICBjb25zdCBob29rID0gdG9DYWxsW2ogKyAxXSBhcyBIb29rRm47XG4gICAgICAgICAgICBwcm9maWxlcihQcm9maWxlckV2ZW50LkxpZmVjeWNsZUhvb2tTdGFydCwgY2FsbENvbnRleHQsIGhvb2spO1xuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgaG9vay5jYWxsKGNhbGxDb250ZXh0KTtcbiAgICAgICAgICAgIH0gZmluYWxseSB7XG4gICAgICAgICAgICAgIHByb2ZpbGVyKFByb2ZpbGVyRXZlbnQuTGlmZWN5Y2xlSG9va0VuZCwgY2FsbENvbnRleHQsIGhvb2spO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBwcm9maWxlcihQcm9maWxlckV2ZW50LkxpZmVjeWNsZUhvb2tTdGFydCwgY29udGV4dCwgdG9DYWxsKTtcbiAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgdG9DYWxsLmNhbGwoY29udGV4dCk7XG4gICAgICAgICAgfSBmaW5hbGx5IHtcbiAgICAgICAgICAgIHByb2ZpbGVyKFByb2ZpbGVyRXZlbnQuTGlmZWN5Y2xlSG9va0VuZCwgY29udGV4dCwgdG9DYWxsKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gIH1cbn1cblxuLyoqXG4gKiBSZXR1cm5zIGEgbmF0aXZlIGVsZW1lbnQgaWYgYSBub2RlIGNhbiBiZSBpbnNlcnRlZCBpbnRvIHRoZSBnaXZlbiBwYXJlbnQuXG4gKlxuICogVGhlcmUgYXJlIHR3byByZWFzb25zIHdoeSB3ZSBtYXkgbm90IGJlIGFibGUgdG8gaW5zZXJ0IGEgZWxlbWVudCBpbW1lZGlhdGVseS5cbiAqIC0gUHJvamVjdGlvbjogV2hlbiBjcmVhdGluZyBhIGNoaWxkIGNvbnRlbnQgZWxlbWVudCBvZiBhIGNvbXBvbmVudCwgd2UgaGF2ZSB0byBza2lwIHRoZVxuICogICBpbnNlcnRpb24gYmVjYXVzZSB0aGUgY29udGVudCBvZiBhIGNvbXBvbmVudCB3aWxsIGJlIHByb2plY3RlZC5cbiAqICAgYDxjb21wb25lbnQ+PGNvbnRlbnQ+ZGVsYXllZCBkdWUgdG8gcHJvamVjdGlvbjwvY29udGVudD48L2NvbXBvbmVudD5gXG4gKiAtIFBhcmVudCBjb250YWluZXIgaXMgZGlzY29ubmVjdGVkOiBUaGlzIGNhbiBoYXBwZW4gd2hlbiB3ZSBhcmUgaW5zZXJ0aW5nIGEgdmlldyBpbnRvXG4gKiAgIHBhcmVudCBjb250YWluZXIsIHdoaWNoIGl0c2VsZiBpcyBkaXNjb25uZWN0ZWQuIEZvciBleGFtcGxlIHRoZSBwYXJlbnQgY29udGFpbmVyIGlzIHBhcnRcbiAqICAgb2YgYSBWaWV3IHdoaWNoIGhhcyBub3QgYmUgaW5zZXJ0ZWQgb3IgaXMgbWFkZSBmb3IgcHJvamVjdGlvbiBidXQgaGFzIG5vdCBiZWVuIGluc2VydGVkXG4gKiAgIGludG8gZGVzdGluYXRpb24uXG4gKlxuICogQHBhcmFtIHRWaWV3OiBDdXJyZW50IGBUVmlld2AuXG4gKiBAcGFyYW0gdE5vZGU6IGBUTm9kZWAgZm9yIHdoaWNoIHdlIHdpc2ggdG8gcmV0cmlldmUgcmVuZGVyIHBhcmVudC5cbiAqIEBwYXJhbSBsVmlldzogQ3VycmVudCBgTFZpZXdgLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0UGFyZW50UkVsZW1lbnQodFZpZXc6IFRWaWV3LCB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldyk6IFJFbGVtZW50fG51bGwge1xuICByZXR1cm4gZ2V0Q2xvc2VzdFJFbGVtZW50KHRWaWV3LCB0Tm9kZS5wYXJlbnQsIGxWaWV3KTtcbn1cblxuLyoqXG4gKiBHZXQgY2xvc2VzdCBgUkVsZW1lbnRgIG9yIGBudWxsYCBpZiBpdCBjYW4ndCBiZSBmb3VuZC5cbiAqXG4gKiBJZiBgVE5vZGVgIGlzIGBUTm9kZVR5cGUuRWxlbWVudGAgPT4gcmV0dXJuIGBSRWxlbWVudGAgYXQgYExWaWV3W3ROb2RlLmluZGV4XWAgbG9jYXRpb24uXG4gKiBJZiBgVE5vZGVgIGlzIGBUTm9kZVR5cGUuRWxlbWVudENvbnRhaW5lcnxJY3VDb250YWluYCA9PiByZXR1cm4gdGhlIHBhcmVudCAocmVjdXJzaXZlbHkpLlxuICogSWYgYFROb2RlYCBpcyBgbnVsbGAgdGhlbiByZXR1cm4gaG9zdCBgUkVsZW1lbnRgOlxuICogICAtIHJldHVybiBgbnVsbGAgaWYgcHJvamVjdGlvblxuICogICAtIHJldHVybiBgbnVsbGAgaWYgcGFyZW50IGNvbnRhaW5lciBpcyBkaXNjb25uZWN0ZWQgKHdlIGhhdmUgbm8gcGFyZW50LilcbiAqXG4gKiBAcGFyYW0gdFZpZXc6IEN1cnJlbnQgYFRWaWV3YC5cbiAqIEBwYXJhbSB0Tm9kZTogYFROb2RlYCBmb3Igd2hpY2ggd2Ugd2lzaCB0byByZXRyaWV2ZSBgUkVsZW1lbnRgIChvciBgbnVsbGAgaWYgaG9zdCBlbGVtZW50IGlzXG4gKiAgICAgbmVlZGVkKS5cbiAqIEBwYXJhbSBsVmlldzogQ3VycmVudCBgTFZpZXdgLlxuICogQHJldHVybnMgYG51bGxgIGlmIHRoZSBgUkVsZW1lbnRgIGNhbid0IGJlIGRldGVybWluZWQgYXQgdGhpcyB0aW1lIChubyBwYXJlbnQgLyBwcm9qZWN0aW9uKVxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0Q2xvc2VzdFJFbGVtZW50KHRWaWV3OiBUVmlldywgdE5vZGU6IFROb2RlfG51bGwsIGxWaWV3OiBMVmlldyk6IFJFbGVtZW50fG51bGwge1xuICBsZXQgcGFyZW50VE5vZGU6IFROb2RlfG51bGwgPSB0Tm9kZTtcbiAgLy8gU2tpcCBvdmVyIGVsZW1lbnQgYW5kIElDVSBjb250YWluZXJzIGFzIHRob3NlIGFyZSByZXByZXNlbnRlZCBieSBhIGNvbW1lbnQgbm9kZSBhbmRcbiAgLy8gY2FuJ3QgYmUgdXNlZCBhcyBhIHJlbmRlciBwYXJlbnQuXG4gIHdoaWxlIChwYXJlbnRUTm9kZSAhPT0gbnVsbCAmJlxuICAgICAgICAgKHBhcmVudFROb2RlLnR5cGUgJiAoVE5vZGVUeXBlLkVsZW1lbnRDb250YWluZXIgfCBUTm9kZVR5cGUuSWN1KSkpIHtcbiAgICB0Tm9kZSA9IHBhcmVudFROb2RlO1xuICAgIHBhcmVudFROb2RlID0gdE5vZGUucGFyZW50O1xuICB9XG5cbiAgLy8gSWYgdGhlIHBhcmVudCB0Tm9kZSBpcyBudWxsLCB0aGVuIHdlIGFyZSBpbnNlcnRpbmcgYWNyb3NzIHZpZXdzOiBlaXRoZXIgaW50byBhbiBlbWJlZGRlZCB2aWV3XG4gIC8vIG9yIGEgY29tcG9uZW50IHZpZXcuXG4gIGlmIChwYXJlbnRUTm9kZSA9PT0gbnVsbCkge1xuICAgIC8vIFdlIGFyZSBpbnNlcnRpbmcgYSByb290IGVsZW1lbnQgb2YgdGhlIGNvbXBvbmVudCB2aWV3IGludG8gdGhlIGNvbXBvbmVudCBob3N0IGVsZW1lbnQgYW5kXG4gICAgLy8gaXQgc2hvdWxkIGFsd2F5cyBiZSBlYWdlci5cbiAgICByZXR1cm4gbFZpZXdbSE9TVF07XG4gIH0gZWxzZSB7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydFROb2RlVHlwZShwYXJlbnRUTm9kZSwgVE5vZGVUeXBlLkFueVJOb2RlIHwgVE5vZGVUeXBlLkNvbnRhaW5lcik7XG4gICAgY29uc3Qge2NvbXBvbmVudE9mZnNldH0gPSBwYXJlbnRUTm9kZTtcbiAgICBpZiAoY29tcG9uZW50T2Zmc2V0ID4gLTEpIHtcbiAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRUTm9kZUZvckxWaWV3KHBhcmVudFROb2RlLCBsVmlldyk7XG4gICAgICBjb25zdCB7ZW5jYXBzdWxhdGlvbn0gPVxuICAgICAgICAgICh0Vmlldy5kYXRhW3BhcmVudFROb2RlLmRpcmVjdGl2ZVN0YXJ0ICsgY29tcG9uZW50T2Zmc2V0XSBhcyBDb21wb25lbnREZWY8dW5rbm93bj4pO1xuICAgICAgLy8gV2UndmUgZ290IGEgcGFyZW50IHdoaWNoIGlzIGFuIGVsZW1lbnQgaW4gdGhlIGN1cnJlbnQgdmlldy4gV2UganVzdCBuZWVkIHRvIHZlcmlmeSBpZiB0aGVcbiAgICAgIC8vIHBhcmVudCBlbGVtZW50IGlzIG5vdCBhIGNvbXBvbmVudC4gQ29tcG9uZW50J3MgY29udGVudCBub2RlcyBhcmUgbm90IGluc2VydGVkIGltbWVkaWF0ZWx5XG4gICAgICAvLyBiZWNhdXNlIHRoZXkgd2lsbCBiZSBwcm9qZWN0ZWQsIGFuZCBzbyBkb2luZyBpbnNlcnQgYXQgdGhpcyBwb2ludCB3b3VsZCBiZSB3YXN0ZWZ1bC5cbiAgICAgIC8vIFNpbmNlIHRoZSBwcm9qZWN0aW9uIHdvdWxkIHRoZW4gbW92ZSBpdCB0byBpdHMgZmluYWwgZGVzdGluYXRpb24uIE5vdGUgdGhhdCB3ZSBjYW4ndFxuICAgICAgLy8gbWFrZSB0aGlzIGFzc3VtcHRpb24gd2hlbiB1c2luZyB0aGUgU2hhZG93IERPTSwgYmVjYXVzZSB0aGUgbmF0aXZlIHByb2plY3Rpb24gcGxhY2Vob2xkZXJzXG4gICAgICAvLyAoPGNvbnRlbnQ+IG9yIDxzbG90PikgaGF2ZSB0byBiZSBpbiBwbGFjZSBhcyBlbGVtZW50cyBhcmUgYmVpbmcgaW5zZXJ0ZWQuXG4gICAgICBpZiAoZW5jYXBzdWxhdGlvbiA9PT0gVmlld0VuY2Fwc3VsYXRpb24uTm9uZSB8fFxuICAgICAgICAgIGVuY2Fwc3VsYXRpb24gPT09IFZpZXdFbmNhcHN1bGF0aW9uLkVtdWxhdGVkKSB7XG4gICAgICAgIHJldHVybiBudWxsO1xuICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiBnZXROYXRpdmVCeVROb2RlKHBhcmVudFROb2RlLCBsVmlldykgYXMgUkVsZW1lbnQ7XG4gIH1cbn1cblxuLyoqXG4gKiBJbnNlcnRzIGEgbmF0aXZlIG5vZGUgYmVmb3JlIGFub3RoZXIgbmF0aXZlIG5vZGUgZm9yIGEgZ2l2ZW4gcGFyZW50LlxuICogVGhpcyBpcyBhIHV0aWxpdHkgZnVuY3Rpb24gdGhhdCBjYW4gYmUgdXNlZCB3aGVuIG5hdGl2ZSBub2RlcyB3ZXJlIGRldGVybWluZWQuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBuYXRpdmVJbnNlcnRCZWZvcmUoXG4gICAgcmVuZGVyZXI6IFJlbmRlcmVyLCBwYXJlbnQ6IFJFbGVtZW50LCBjaGlsZDogUk5vZGUsIGJlZm9yZU5vZGU6IFJOb2RlfG51bGwsXG4gICAgaXNNb3ZlOiBib29sZWFuKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJJbnNlcnRCZWZvcmUrKztcbiAgcmVuZGVyZXIuaW5zZXJ0QmVmb3JlKHBhcmVudCwgY2hpbGQsIGJlZm9yZU5vZGUsIGlzTW92ZSk7XG59XG5cbmZ1bmN0aW9uIG5hdGl2ZUFwcGVuZENoaWxkKHJlbmRlcmVyOiBSZW5kZXJlciwgcGFyZW50OiBSRWxlbWVudCwgY2hpbGQ6IFJOb2RlKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJBcHBlbmRDaGlsZCsrO1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZChwYXJlbnQsICdwYXJlbnQgbm9kZSBtdXN0IGJlIGRlZmluZWQnKTtcbiAgcmVuZGVyZXIuYXBwZW5kQ2hpbGQocGFyZW50LCBjaGlsZCk7XG59XG5cbmZ1bmN0aW9uIG5hdGl2ZUFwcGVuZE9ySW5zZXJ0QmVmb3JlKFxuICAgIHJlbmRlcmVyOiBSZW5kZXJlciwgcGFyZW50OiBSRWxlbWVudCwgY2hpbGQ6IFJOb2RlLCBiZWZvcmVOb2RlOiBSTm9kZXxudWxsLCBpc01vdmU6IGJvb2xlYW4pIHtcbiAgaWYgKGJlZm9yZU5vZGUgIT09IG51bGwpIHtcbiAgICBuYXRpdmVJbnNlcnRCZWZvcmUocmVuZGVyZXIsIHBhcmVudCwgY2hpbGQsIGJlZm9yZU5vZGUsIGlzTW92ZSk7XG4gIH0gZWxzZSB7XG4gICAgbmF0aXZlQXBwZW5kQ2hpbGQocmVuZGVyZXIsIHBhcmVudCwgY2hpbGQpO1xuICB9XG59XG5cbi8qKiBSZW1vdmVzIGEgbm9kZSBmcm9tIHRoZSBET00gZ2l2ZW4gaXRzIG5hdGl2ZSBwYXJlbnQuICovXG5mdW5jdGlvbiBuYXRpdmVSZW1vdmVDaGlsZChcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIHBhcmVudDogUkVsZW1lbnQsIGNoaWxkOiBSTm9kZSwgaXNIb3N0RWxlbWVudD86IGJvb2xlYW4pOiB2b2lkIHtcbiAgcmVuZGVyZXIucmVtb3ZlQ2hpbGQocGFyZW50LCBjaGlsZCwgaXNIb3N0RWxlbWVudCk7XG59XG5cbi8qKiBDaGVja3MgaWYgYW4gZWxlbWVudCBpcyBhIGA8dGVtcGxhdGU+YCBub2RlLiAqL1xuZnVuY3Rpb24gaXNUZW1wbGF0ZU5vZGUobm9kZTogUkVsZW1lbnQpOiBub2RlIGlzIFJUZW1wbGF0ZSB7XG4gIHJldHVybiBub2RlLnRhZ05hbWUgPT09ICdURU1QTEFURScgJiYgKG5vZGUgYXMgUlRlbXBsYXRlKS5jb250ZW50ICE9PSB1bmRlZmluZWQ7XG59XG5cbi8qKlxuICogUmV0dXJucyBhIG5hdGl2ZSBwYXJlbnQgb2YgYSBnaXZlbiBuYXRpdmUgbm9kZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIG5hdGl2ZVBhcmVudE5vZGUocmVuZGVyZXI6IFJlbmRlcmVyLCBub2RlOiBSTm9kZSk6IFJFbGVtZW50fG51bGwge1xuICByZXR1cm4gcmVuZGVyZXIucGFyZW50Tm9kZShub2RlKTtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIGEgbmF0aXZlIHNpYmxpbmcgb2YgYSBnaXZlbiBuYXRpdmUgbm9kZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIG5hdGl2ZU5leHRTaWJsaW5nKHJlbmRlcmVyOiBSZW5kZXJlciwgbm9kZTogUk5vZGUpOiBSTm9kZXxudWxsIHtcbiAgcmV0dXJuIHJlbmRlcmVyLm5leHRTaWJsaW5nKG5vZGUpO1xufVxuXG4vKipcbiAqIEZpbmQgYSBub2RlIGluIGZyb250IG9mIHdoaWNoIGBjdXJyZW50VE5vZGVgIHNob3VsZCBiZSBpbnNlcnRlZC5cbiAqXG4gKiBUaGlzIG1ldGhvZCBkZXRlcm1pbmVzIHRoZSBgUk5vZGVgIGluIGZyb250IG9mIHdoaWNoIHdlIHNob3VsZCBpbnNlcnQgdGhlIGBjdXJyZW50Uk5vZGVgLiBUaGlzXG4gKiB0YWtlcyBgVE5vZGUuaW5zZXJ0QmVmb3JlSW5kZXhgIGludG8gYWNjb3VudCBpZiBpMThuIGNvZGUgaGFzIGJlZW4gaW52b2tlZC5cbiAqXG4gKiBAcGFyYW0gcGFyZW50VE5vZGUgcGFyZW50IGBUTm9kZWBcbiAqIEBwYXJhbSBjdXJyZW50VE5vZGUgY3VycmVudCBgVE5vZGVgIChUaGUgbm9kZSB3aGljaCB3ZSB3b3VsZCBsaWtlIHRvIGluc2VydCBpbnRvIHRoZSBET00pXG4gKiBAcGFyYW0gbFZpZXcgY3VycmVudCBgTFZpZXdgXG4gKi9cbmZ1bmN0aW9uIGdldEluc2VydEluRnJvbnRPZlJOb2RlKHBhcmVudFROb2RlOiBUTm9kZSwgY3VycmVudFROb2RlOiBUTm9kZSwgbFZpZXc6IExWaWV3KTogUk5vZGV8XG4gICAgbnVsbCB7XG4gIHJldHVybiBfZ2V0SW5zZXJ0SW5Gcm9udE9mUk5vZGVXaXRoSTE4bihwYXJlbnRUTm9kZSwgY3VycmVudFROb2RlLCBsVmlldyk7XG59XG5cblxuLyoqXG4gKiBGaW5kIGEgbm9kZSBpbiBmcm9udCBvZiB3aGljaCBgY3VycmVudFROb2RlYCBzaG91bGQgYmUgaW5zZXJ0ZWQuIChEb2VzIG5vdCB0YWtlIGkxOG4gaW50b1xuICogYWNjb3VudClcbiAqXG4gKiBUaGlzIG1ldGhvZCBkZXRlcm1pbmVzIHRoZSBgUk5vZGVgIGluIGZyb250IG9mIHdoaWNoIHdlIHNob3VsZCBpbnNlcnQgdGhlIGBjdXJyZW50Uk5vZGVgLiBUaGlzXG4gKiBkb2VzIG5vdCB0YWtlIGBUTm9kZS5pbnNlcnRCZWZvcmVJbmRleGAgaW50byBhY2NvdW50LlxuICpcbiAqIEBwYXJhbSBwYXJlbnRUTm9kZSBwYXJlbnQgYFROb2RlYFxuICogQHBhcmFtIGN1cnJlbnRUTm9kZSBjdXJyZW50IGBUTm9kZWAgKFRoZSBub2RlIHdoaWNoIHdlIHdvdWxkIGxpa2UgdG8gaW5zZXJ0IGludG8gdGhlIERPTSlcbiAqIEBwYXJhbSBsVmlldyBjdXJyZW50IGBMVmlld2BcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldEluc2VydEluRnJvbnRPZlJOb2RlV2l0aE5vSTE4bihcbiAgICBwYXJlbnRUTm9kZTogVE5vZGUsIGN1cnJlbnRUTm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldyk6IFJOb2RlfG51bGwge1xuICBpZiAocGFyZW50VE5vZGUudHlwZSAmIChUTm9kZVR5cGUuRWxlbWVudENvbnRhaW5lciB8IFROb2RlVHlwZS5JY3UpKSB7XG4gICAgcmV0dXJuIGdldE5hdGl2ZUJ5VE5vZGUocGFyZW50VE5vZGUsIGxWaWV3KTtcbiAgfVxuICByZXR1cm4gbnVsbDtcbn1cblxuLyoqXG4gKiBUcmVlIHNoYWthYmxlIGJvdW5kYXJ5IGZvciBgZ2V0SW5zZXJ0SW5Gcm9udE9mUk5vZGVXaXRoSTE4bmAgZnVuY3Rpb24uXG4gKlxuICogVGhpcyBmdW5jdGlvbiB3aWxsIG9ubHkgYmUgc2V0IGlmIGkxOG4gY29kZSBydW5zLlxuICovXG5sZXQgX2dldEluc2VydEluRnJvbnRPZlJOb2RlV2l0aEkxOG46IChwYXJlbnRUTm9kZTogVE5vZGUsIGN1cnJlbnRUTm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldykgPT5cbiAgICBSTm9kZSB8IG51bGwgPSBnZXRJbnNlcnRJbkZyb250T2ZSTm9kZVdpdGhOb0kxOG47XG5cbi8qKlxuICogVHJlZSBzaGFrYWJsZSBib3VuZGFyeSBmb3IgYHByb2Nlc3NJMThuSW5zZXJ0QmVmb3JlYCBmdW5jdGlvbi5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIHdpbGwgb25seSBiZSBzZXQgaWYgaTE4biBjb2RlIHJ1bnMuXG4gKi9cbmxldCBfcHJvY2Vzc0kxOG5JbnNlcnRCZWZvcmU6IChcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIGNoaWxkVE5vZGU6IFROb2RlLCBsVmlldzogTFZpZXcsIGNoaWxkUk5vZGU6IFJOb2RlfFJOb2RlW10sXG4gICAgcGFyZW50UkVsZW1lbnQ6IFJFbGVtZW50fG51bGwpID0+IHZvaWQ7XG5cbmV4cG9ydCBmdW5jdGlvbiBzZXRJMThuSGFuZGxpbmcoXG4gICAgZ2V0SW5zZXJ0SW5Gcm9udE9mUk5vZGVXaXRoSTE4bjogKHBhcmVudFROb2RlOiBUTm9kZSwgY3VycmVudFROb2RlOiBUTm9kZSwgbFZpZXc6IExWaWV3KSA9PlxuICAgICAgICBSTm9kZSB8IG51bGwsXG4gICAgcHJvY2Vzc0kxOG5JbnNlcnRCZWZvcmU6IChcbiAgICAgICAgcmVuZGVyZXI6IFJlbmRlcmVyLCBjaGlsZFROb2RlOiBUTm9kZSwgbFZpZXc6IExWaWV3LCBjaGlsZFJOb2RlOiBSTm9kZXxSTm9kZVtdLFxuICAgICAgICBwYXJlbnRSRWxlbWVudDogUkVsZW1lbnR8bnVsbCkgPT4gdm9pZCkge1xuICBfZ2V0SW5zZXJ0SW5Gcm9udE9mUk5vZGVXaXRoSTE4biA9IGdldEluc2VydEluRnJvbnRPZlJOb2RlV2l0aEkxOG47XG4gIF9wcm9jZXNzSTE4bkluc2VydEJlZm9yZSA9IHByb2Nlc3NJMThuSW5zZXJ0QmVmb3JlO1xufVxuXG4vKipcbiAqIEFwcGVuZHMgdGhlIGBjaGlsZGAgbmF0aXZlIG5vZGUgKG9yIGEgY29sbGVjdGlvbiBvZiBub2RlcykgdG8gdGhlIGBwYXJlbnRgLlxuICpcbiAqIEBwYXJhbSB0VmlldyBUaGUgYFRWaWV3JyB0byBiZSBhcHBlbmRlZFxuICogQHBhcmFtIGxWaWV3IFRoZSBjdXJyZW50IExWaWV3XG4gKiBAcGFyYW0gY2hpbGRSTm9kZSBUaGUgbmF0aXZlIGNoaWxkIChvciBjaGlsZHJlbikgdGhhdCBzaG91bGQgYmUgYXBwZW5kZWRcbiAqIEBwYXJhbSBjaGlsZFROb2RlIFRoZSBUTm9kZSBvZiB0aGUgY2hpbGQgZWxlbWVudFxuICovXG5leHBvcnQgZnVuY3Rpb24gYXBwZW5kQ2hpbGQoXG4gICAgdFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcsIGNoaWxkUk5vZGU6IFJOb2RlfFJOb2RlW10sIGNoaWxkVE5vZGU6IFROb2RlKTogdm9pZCB7XG4gIGNvbnN0IHBhcmVudFJOb2RlID0gZ2V0UGFyZW50UkVsZW1lbnQodFZpZXcsIGNoaWxkVE5vZGUsIGxWaWV3KTtcbiAgY29uc3QgcmVuZGVyZXIgPSBsVmlld1tSRU5ERVJFUl07XG4gIGNvbnN0IHBhcmVudFROb2RlOiBUTm9kZSA9IGNoaWxkVE5vZGUucGFyZW50IHx8IGxWaWV3W1RfSE9TVF0hO1xuICBjb25zdCBhbmNob3JOb2RlID0gZ2V0SW5zZXJ0SW5Gcm9udE9mUk5vZGUocGFyZW50VE5vZGUsIGNoaWxkVE5vZGUsIGxWaWV3KTtcbiAgaWYgKHBhcmVudFJOb2RlICE9IG51bGwpIHtcbiAgICBpZiAoQXJyYXkuaXNBcnJheShjaGlsZFJOb2RlKSkge1xuICAgICAgZm9yIChsZXQgaSA9IDA7IGkgPCBjaGlsZFJOb2RlLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgIG5hdGl2ZUFwcGVuZE9ySW5zZXJ0QmVmb3JlKHJlbmRlcmVyLCBwYXJlbnRSTm9kZSwgY2hpbGRSTm9kZVtpXSwgYW5jaG9yTm9kZSwgZmFsc2UpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBuYXRpdmVBcHBlbmRPckluc2VydEJlZm9yZShyZW5kZXJlciwgcGFyZW50Uk5vZGUsIGNoaWxkUk5vZGUsIGFuY2hvck5vZGUsIGZhbHNlKTtcbiAgICB9XG4gIH1cblxuICBfcHJvY2Vzc0kxOG5JbnNlcnRCZWZvcmUgIT09IHVuZGVmaW5lZCAmJlxuICAgICAgX3Byb2Nlc3NJMThuSW5zZXJ0QmVmb3JlKHJlbmRlcmVyLCBjaGlsZFROb2RlLCBsVmlldywgY2hpbGRSTm9kZSwgcGFyZW50Uk5vZGUpO1xufVxuXG4vKipcbiAqIFJldHVybnMgdGhlIGZpcnN0IG5hdGl2ZSBub2RlIGZvciBhIGdpdmVuIExWaWV3LCBzdGFydGluZyBmcm9tIHRoZSBwcm92aWRlZCBUTm9kZS5cbiAqXG4gKiBOYXRpdmUgbm9kZXMgYXJlIHJldHVybmVkIGluIHRoZSBvcmRlciBpbiB3aGljaCB0aG9zZSBhcHBlYXIgaW4gdGhlIG5hdGl2ZSB0cmVlIChET00pLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0Rmlyc3ROYXRpdmVOb2RlKGxWaWV3OiBMVmlldywgdE5vZGU6IFROb2RlfG51bGwpOiBSTm9kZXxudWxsIHtcbiAgaWYgKHROb2RlICE9PSBudWxsKSB7XG4gICAgbmdEZXZNb2RlICYmXG4gICAgICAgIGFzc2VydFROb2RlVHlwZShcbiAgICAgICAgICAgIHROb2RlLFxuICAgICAgICAgICAgVE5vZGVUeXBlLkFueVJOb2RlIHwgVE5vZGVUeXBlLkFueUNvbnRhaW5lciB8IFROb2RlVHlwZS5JY3UgfCBUTm9kZVR5cGUuUHJvamVjdGlvbik7XG5cbiAgICBjb25zdCB0Tm9kZVR5cGUgPSB0Tm9kZS50eXBlO1xuICAgIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuQW55Uk5vZGUpIHtcbiAgICAgIHJldHVybiBnZXROYXRpdmVCeVROb2RlKHROb2RlLCBsVmlldyk7XG4gICAgfSBlbHNlIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuQ29udGFpbmVyKSB7XG4gICAgICByZXR1cm4gZ2V0QmVmb3JlTm9kZUZvclZpZXcoLTEsIGxWaWV3W3ROb2RlLmluZGV4XSk7XG4gICAgfSBlbHNlIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuRWxlbWVudENvbnRhaW5lcikge1xuICAgICAgY29uc3QgZWxJY3VDb250YWluZXJDaGlsZCA9IHROb2RlLmNoaWxkO1xuICAgICAgaWYgKGVsSWN1Q29udGFpbmVyQ2hpbGQgIT09IG51bGwpIHtcbiAgICAgICAgcmV0dXJuIGdldEZpcnN0TmF0aXZlTm9kZShsVmlldywgZWxJY3VDb250YWluZXJDaGlsZCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBjb25zdCByTm9kZU9yTENvbnRhaW5lciA9IGxWaWV3W3ROb2RlLmluZGV4XTtcbiAgICAgICAgaWYgKGlzTENvbnRhaW5lcihyTm9kZU9yTENvbnRhaW5lcikpIHtcbiAgICAgICAgICByZXR1cm4gZ2V0QmVmb3JlTm9kZUZvclZpZXcoLTEsIHJOb2RlT3JMQ29udGFpbmVyKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICByZXR1cm4gdW53cmFwUk5vZGUock5vZGVPckxDb250YWluZXIpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSBlbHNlIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuSWN1KSB7XG4gICAgICBsZXQgbmV4dFJOb2RlID0gaWN1Q29udGFpbmVySXRlcmF0ZSh0Tm9kZSBhcyBUSWN1Q29udGFpbmVyTm9kZSwgbFZpZXcpO1xuICAgICAgbGV0IHJOb2RlOiBSTm9kZXxudWxsID0gbmV4dFJOb2RlKCk7XG4gICAgICAvLyBJZiB0aGUgSUNVIGNvbnRhaW5lciBoYXMgbm8gbm9kZXMsIHRoYW4gd2UgdXNlIHRoZSBJQ1UgYW5jaG9yIGFzIHRoZSBub2RlLlxuICAgICAgcmV0dXJuIHJOb2RlIHx8IHVud3JhcFJOb2RlKGxWaWV3W3ROb2RlLmluZGV4XSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGNvbnN0IHByb2plY3Rpb25Ob2RlcyA9IGdldFByb2plY3Rpb25Ob2RlcyhsVmlldywgdE5vZGUpO1xuICAgICAgaWYgKHByb2plY3Rpb25Ob2RlcyAhPT0gbnVsbCkge1xuICAgICAgICBpZiAoQXJyYXkuaXNBcnJheShwcm9qZWN0aW9uTm9kZXMpKSB7XG4gICAgICAgICAgcmV0dXJuIHByb2plY3Rpb25Ob2Rlc1swXTtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBwYXJlbnRWaWV3ID0gZ2V0TFZpZXdQYXJlbnQobFZpZXdbREVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVddKTtcbiAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydFBhcmVudFZpZXcocGFyZW50Vmlldyk7XG4gICAgICAgIHJldHVybiBnZXRGaXJzdE5hdGl2ZU5vZGUocGFyZW50VmlldyEsIHByb2plY3Rpb25Ob2Rlcyk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByZXR1cm4gZ2V0Rmlyc3ROYXRpdmVOb2RlKGxWaWV3LCB0Tm9kZS5uZXh0KTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICByZXR1cm4gbnVsbDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldFByb2plY3Rpb25Ob2RlcyhsVmlldzogTFZpZXcsIHROb2RlOiBUTm9kZXxudWxsKTogVE5vZGV8Uk5vZGVbXXxudWxsIHtcbiAgaWYgKHROb2RlICE9PSBudWxsKSB7XG4gICAgY29uc3QgY29tcG9uZW50VmlldyA9IGxWaWV3W0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXXTtcbiAgICBjb25zdCBjb21wb25lbnRIb3N0ID0gY29tcG9uZW50Vmlld1tUX0hPU1RdIGFzIFRFbGVtZW50Tm9kZTtcbiAgICBjb25zdCBzbG90SWR4ID0gdE5vZGUucHJvamVjdGlvbiBhcyBudW1iZXI7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydFByb2plY3Rpb25TbG90cyhsVmlldyk7XG4gICAgcmV0dXJuIGNvbXBvbmVudEhvc3QucHJvamVjdGlvbiFbc2xvdElkeF07XG4gIH1cbiAgcmV0dXJuIG51bGw7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRCZWZvcmVOb2RlRm9yVmlldyh2aWV3SW5kZXhJbkNvbnRhaW5lcjogbnVtYmVyLCBsQ29udGFpbmVyOiBMQ29udGFpbmVyKTogUk5vZGV8XG4gICAgbnVsbCB7XG4gIGNvbnN0IG5leHRWaWV3SW5kZXggPSBDT05UQUlORVJfSEVBREVSX09GRlNFVCArIHZpZXdJbmRleEluQ29udGFpbmVyICsgMTtcbiAgaWYgKG5leHRWaWV3SW5kZXggPCBsQ29udGFpbmVyLmxlbmd0aCkge1xuICAgIGNvbnN0IGxWaWV3ID0gbENvbnRhaW5lcltuZXh0Vmlld0luZGV4XSBhcyBMVmlldztcbiAgICBjb25zdCBmaXJzdFROb2RlT2ZWaWV3ID0gbFZpZXdbVFZJRVddLmZpcnN0Q2hpbGQ7XG4gICAgaWYgKGZpcnN0VE5vZGVPZlZpZXcgIT09IG51bGwpIHtcbiAgICAgIHJldHVybiBnZXRGaXJzdE5hdGl2ZU5vZGUobFZpZXcsIGZpcnN0VE5vZGVPZlZpZXcpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBsQ29udGFpbmVyW05BVElWRV07XG59XG5cbi8qKlxuICogUmVtb3ZlcyBhIG5hdGl2ZSBub2RlIGl0c2VsZiB1c2luZyBhIGdpdmVuIHJlbmRlcmVyLiBUbyByZW1vdmUgdGhlIG5vZGUgd2UgYXJlIGxvb2tpbmcgdXAgaXRzXG4gKiBwYXJlbnQgZnJvbSB0aGUgbmF0aXZlIHRyZWUgYXMgbm90IGFsbCBwbGF0Zm9ybXMgLyBicm93c2VycyBzdXBwb3J0IHRoZSBlcXVpdmFsZW50IG9mXG4gKiBub2RlLnJlbW92ZSgpLlxuICpcbiAqIEBwYXJhbSByZW5kZXJlciBBIHJlbmRlcmVyIHRvIGJlIHVzZWRcbiAqIEBwYXJhbSByTm9kZSBUaGUgbmF0aXZlIG5vZGUgdGhhdCBzaG91bGQgYmUgcmVtb3ZlZFxuICogQHBhcmFtIGlzSG9zdEVsZW1lbnQgQSBmbGFnIGluZGljYXRpbmcgaWYgYSBub2RlIHRvIGJlIHJlbW92ZWQgaXMgYSBob3N0IG9mIGEgY29tcG9uZW50LlxuICovXG5leHBvcnQgZnVuY3Rpb24gbmF0aXZlUmVtb3ZlTm9kZShyZW5kZXJlcjogUmVuZGVyZXIsIHJOb2RlOiBSTm9kZSwgaXNIb3N0RWxlbWVudD86IGJvb2xlYW4pOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlclJlbW92ZU5vZGUrKztcbiAgY29uc3QgbmF0aXZlUGFyZW50ID0gbmF0aXZlUGFyZW50Tm9kZShyZW5kZXJlciwgck5vZGUpO1xuICBpZiAobmF0aXZlUGFyZW50KSB7XG4gICAgbmF0aXZlUmVtb3ZlQ2hpbGQocmVuZGVyZXIsIG5hdGl2ZVBhcmVudCwgck5vZGUsIGlzSG9zdEVsZW1lbnQpO1xuICB9XG59XG5cbi8qKlxuICogQ2xlYXJzIHRoZSBjb250ZW50cyBvZiBhIGdpdmVuIFJFbGVtZW50LlxuICpcbiAqIEBwYXJhbSByRWxlbWVudCB0aGUgbmF0aXZlIFJFbGVtZW50IHRvIGJlIGNsZWFyZWRcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNsZWFyRWxlbWVudENvbnRlbnRzKHJFbGVtZW50OiBSRWxlbWVudCk6IHZvaWQge1xuICByRWxlbWVudC50ZXh0Q29udGVudCA9ICcnO1xufVxuXG5cbi8qKlxuICogUGVyZm9ybXMgdGhlIG9wZXJhdGlvbiBvZiBgYWN0aW9uYCBvbiB0aGUgbm9kZS4gVHlwaWNhbGx5IHRoaXMgaW52b2x2ZXMgaW5zZXJ0aW5nIG9yIHJlbW92aW5nXG4gKiBub2RlcyBvbiB0aGUgTFZpZXcgb3IgcHJvamVjdGlvbiBib3VuZGFyeS5cbiAqL1xuZnVuY3Rpb24gYXBwbHlOb2RlcyhcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIGFjdGlvbjogV2Fsa1ROb2RlVHJlZUFjdGlvbiwgdE5vZGU6IFROb2RlfG51bGwsIGxWaWV3OiBMVmlldyxcbiAgICBwYXJlbnRSRWxlbWVudDogUkVsZW1lbnR8bnVsbCwgYmVmb3JlTm9kZTogUk5vZGV8bnVsbCwgaXNQcm9qZWN0aW9uOiBib29sZWFuKSB7XG4gIHdoaWxlICh0Tm9kZSAhPSBudWxsKSB7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydFROb2RlRm9yTFZpZXcodE5vZGUsIGxWaWV3KTtcbiAgICBuZ0Rldk1vZGUgJiZcbiAgICAgICAgYXNzZXJ0VE5vZGVUeXBlKFxuICAgICAgICAgICAgdE5vZGUsXG4gICAgICAgICAgICBUTm9kZVR5cGUuQW55Uk5vZGUgfCBUTm9kZVR5cGUuQW55Q29udGFpbmVyIHwgVE5vZGVUeXBlLlByb2plY3Rpb24gfCBUTm9kZVR5cGUuSWN1KTtcbiAgICBjb25zdCByYXdTbG90VmFsdWUgPSBsVmlld1t0Tm9kZS5pbmRleF07XG4gICAgY29uc3QgdE5vZGVUeXBlID0gdE5vZGUudHlwZTtcbiAgICBpZiAoaXNQcm9qZWN0aW9uKSB7XG4gICAgICBpZiAoYWN0aW9uID09PSBXYWxrVE5vZGVUcmVlQWN0aW9uLkNyZWF0ZSkge1xuICAgICAgICByYXdTbG90VmFsdWUgJiYgYXR0YWNoUGF0Y2hEYXRhKHVud3JhcFJOb2RlKHJhd1Nsb3RWYWx1ZSksIGxWaWV3KTtcbiAgICAgICAgdE5vZGUuZmxhZ3MgfD0gVE5vZGVGbGFncy5pc1Byb2plY3RlZDtcbiAgICAgIH1cbiAgICB9XG4gICAgaWYgKCh0Tm9kZS5mbGFncyAmIFROb2RlRmxhZ3MuaXNEZXRhY2hlZCkgIT09IFROb2RlRmxhZ3MuaXNEZXRhY2hlZCkge1xuICAgICAgaWYgKHROb2RlVHlwZSAmIFROb2RlVHlwZS5FbGVtZW50Q29udGFpbmVyKSB7XG4gICAgICAgIGFwcGx5Tm9kZXMocmVuZGVyZXIsIGFjdGlvbiwgdE5vZGUuY2hpbGQsIGxWaWV3LCBwYXJlbnRSRWxlbWVudCwgYmVmb3JlTm9kZSwgZmFsc2UpO1xuICAgICAgICBhcHBseVRvRWxlbWVudE9yQ29udGFpbmVyKGFjdGlvbiwgcmVuZGVyZXIsIHBhcmVudFJFbGVtZW50LCByYXdTbG90VmFsdWUsIGJlZm9yZU5vZGUpO1xuICAgICAgfSBlbHNlIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuSWN1KSB7XG4gICAgICAgIGNvbnN0IG5leHRSTm9kZSA9IGljdUNvbnRhaW5lckl0ZXJhdGUodE5vZGUgYXMgVEljdUNvbnRhaW5lck5vZGUsIGxWaWV3KTtcbiAgICAgICAgbGV0IHJOb2RlOiBSTm9kZXxudWxsO1xuICAgICAgICB3aGlsZSAock5vZGUgPSBuZXh0Uk5vZGUoKSkge1xuICAgICAgICAgIGFwcGx5VG9FbGVtZW50T3JDb250YWluZXIoYWN0aW9uLCByZW5kZXJlciwgcGFyZW50UkVsZW1lbnQsIHJOb2RlLCBiZWZvcmVOb2RlKTtcbiAgICAgICAgfVxuICAgICAgICBhcHBseVRvRWxlbWVudE9yQ29udGFpbmVyKGFjdGlvbiwgcmVuZGVyZXIsIHBhcmVudFJFbGVtZW50LCByYXdTbG90VmFsdWUsIGJlZm9yZU5vZGUpO1xuICAgICAgfSBlbHNlIGlmICh0Tm9kZVR5cGUgJiBUTm9kZVR5cGUuUHJvamVjdGlvbikge1xuICAgICAgICBhcHBseVByb2plY3Rpb25SZWN1cnNpdmUoXG4gICAgICAgICAgICByZW5kZXJlciwgYWN0aW9uLCBsVmlldywgdE5vZGUgYXMgVFByb2plY3Rpb25Ob2RlLCBwYXJlbnRSRWxlbWVudCwgYmVmb3JlTm9kZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0VE5vZGVUeXBlKHROb2RlLCBUTm9kZVR5cGUuQW55Uk5vZGUgfCBUTm9kZVR5cGUuQ29udGFpbmVyKTtcbiAgICAgICAgYXBwbHlUb0VsZW1lbnRPckNvbnRhaW5lcihhY3Rpb24sIHJlbmRlcmVyLCBwYXJlbnRSRWxlbWVudCwgcmF3U2xvdFZhbHVlLCBiZWZvcmVOb2RlKTtcbiAgICAgIH1cbiAgICB9XG4gICAgdE5vZGUgPSBpc1Byb2plY3Rpb24gPyB0Tm9kZS5wcm9qZWN0aW9uTmV4dCA6IHROb2RlLm5leHQ7XG4gIH1cbn1cblxuXG4vKipcbiAqIGBhcHBseVZpZXdgIHBlcmZvcm1zIG9wZXJhdGlvbiBvbiB0aGUgdmlldyBhcyBzcGVjaWZpZWQgaW4gYGFjdGlvbmAgKGluc2VydCwgZGV0YWNoLCBkZXN0cm95KVxuICpcbiAqIEluc2VydGluZyBhIHZpZXcgd2l0aG91dCBwcm9qZWN0aW9uIG9yIGNvbnRhaW5lcnMgYXQgdG9wIGxldmVsIGlzIHNpbXBsZS4gSnVzdCBpdGVyYXRlIG92ZXIgdGhlXG4gKiByb290IG5vZGVzIG9mIHRoZSBWaWV3LCBhbmQgZm9yIGVhY2ggbm9kZSBwZXJmb3JtIHRoZSBgYWN0aW9uYC5cbiAqXG4gKiBUaGluZ3MgZ2V0IG1vcmUgY29tcGxpY2F0ZWQgd2l0aCBjb250YWluZXJzIGFuZCBwcm9qZWN0aW9ucy4gVGhhdCBpcyBiZWNhdXNlIGNvbWluZyBhY3Jvc3M6XG4gKiAtIENvbnRhaW5lcjogaW1wbGllcyB0aGF0IHdlIGhhdmUgdG8gaW5zZXJ0L3JlbW92ZS9kZXN0cm95IHRoZSB2aWV3cyBvZiB0aGF0IGNvbnRhaW5lciBhcyB3ZWxsXG4gKiAgICAgICAgICAgICAgd2hpY2ggaW4gdHVybiBjYW4gaGF2ZSB0aGVpciBvd24gQ29udGFpbmVycyBhdCB0aGUgVmlldyByb290cy5cbiAqIC0gUHJvamVjdGlvbjogaW1wbGllcyB0aGF0IHdlIGhhdmUgdG8gaW5zZXJ0L3JlbW92ZS9kZXN0cm95IHRoZSBub2RlcyBvZiB0aGUgcHJvamVjdGlvbi4gVGhlXG4gKiAgICAgICAgICAgICAgIGNvbXBsaWNhdGlvbiBpcyB0aGF0IHRoZSBub2RlcyB3ZSBhcmUgcHJvamVjdGluZyBjYW4gdGhlbXNlbHZlcyBoYXZlIENvbnRhaW5lcnNcbiAqICAgICAgICAgICAgICAgb3Igb3RoZXIgUHJvamVjdGlvbnMuXG4gKlxuICogQXMgeW91IGNhbiBzZWUgdGhpcyBpcyBhIHZlcnkgcmVjdXJzaXZlIHByb2JsZW0uIFllcyByZWN1cnNpb24gaXMgbm90IG1vc3QgZWZmaWNpZW50IGJ1dCB0aGVcbiAqIGNvZGUgaXMgY29tcGxpY2F0ZWQgZW5vdWdoIHRoYXQgdHJ5aW5nIHRvIGltcGxlbWVudGVkIHdpdGggcmVjdXJzaW9uIGJlY29tZXMgdW5tYWludGFpbmFibGUuXG4gKlxuICogQHBhcmFtIHRWaWV3IFRoZSBgVFZpZXcnIHdoaWNoIG5lZWRzIHRvIGJlIGluc2VydGVkLCBkZXRhY2hlZCwgZGVzdHJveWVkXG4gKiBAcGFyYW0gbFZpZXcgVGhlIExWaWV3IHdoaWNoIG5lZWRzIHRvIGJlIGluc2VydGVkLCBkZXRhY2hlZCwgZGVzdHJveWVkLlxuICogQHBhcmFtIHJlbmRlcmVyIFJlbmRlcmVyIHRvIHVzZVxuICogQHBhcmFtIGFjdGlvbiBhY3Rpb24gdG8gcGVyZm9ybSAoaW5zZXJ0LCBkZXRhY2gsIGRlc3Ryb3kpXG4gKiBAcGFyYW0gcGFyZW50UkVsZW1lbnQgcGFyZW50IERPTSBlbGVtZW50IGZvciBpbnNlcnRpb24gKFJlbW92YWwgZG9lcyBub3QgbmVlZCBpdCkuXG4gKiBAcGFyYW0gYmVmb3JlTm9kZSBCZWZvcmUgd2hpY2ggbm9kZSB0aGUgaW5zZXJ0aW9ucyBzaG91bGQgaGFwcGVuLlxuICovXG5mdW5jdGlvbiBhcHBseVZpZXcoXG4gICAgdFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcsIHJlbmRlcmVyOiBSZW5kZXJlciwgYWN0aW9uOiBXYWxrVE5vZGVUcmVlQWN0aW9uLkRlc3Ryb3ksXG4gICAgcGFyZW50UkVsZW1lbnQ6IG51bGwsIGJlZm9yZU5vZGU6IG51bGwpOiB2b2lkO1xuZnVuY3Rpb24gYXBwbHlWaWV3KFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCByZW5kZXJlcjogUmVuZGVyZXIsIGFjdGlvbjogV2Fsa1ROb2RlVHJlZUFjdGlvbixcbiAgICBwYXJlbnRSRWxlbWVudDogUkVsZW1lbnR8bnVsbCwgYmVmb3JlTm9kZTogUk5vZGV8bnVsbCk6IHZvaWQ7XG5mdW5jdGlvbiBhcHBseVZpZXcoXG4gICAgdFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcsIHJlbmRlcmVyOiBSZW5kZXJlciwgYWN0aW9uOiBXYWxrVE5vZGVUcmVlQWN0aW9uLFxuICAgIHBhcmVudFJFbGVtZW50OiBSRWxlbWVudHxudWxsLCBiZWZvcmVOb2RlOiBSTm9kZXxudWxsKTogdm9pZCB7XG4gIGFwcGx5Tm9kZXMocmVuZGVyZXIsIGFjdGlvbiwgdFZpZXcuZmlyc3RDaGlsZCwgbFZpZXcsIHBhcmVudFJFbGVtZW50LCBiZWZvcmVOb2RlLCBmYWxzZSk7XG59XG5cbi8qKlxuICogYGFwcGx5UHJvamVjdGlvbmAgcGVyZm9ybXMgb3BlcmF0aW9uIG9uIHRoZSBwcm9qZWN0aW9uLlxuICpcbiAqIEluc2VydGluZyBhIHByb2plY3Rpb24gcmVxdWlyZXMgdXMgdG8gbG9jYXRlIHRoZSBwcm9qZWN0ZWQgbm9kZXMgZnJvbSB0aGUgcGFyZW50IGNvbXBvbmVudC4gVGhlXG4gKiBjb21wbGljYXRpb24gaXMgdGhhdCB0aG9zZSBub2RlcyB0aGVtc2VsdmVzIGNvdWxkIGJlIHJlLXByb2plY3RlZCBmcm9tIHRoZWlyIHBhcmVudCBjb21wb25lbnQuXG4gKlxuICogQHBhcmFtIHRWaWV3IFRoZSBgVFZpZXdgIG9mIGBMVmlld2Agd2hpY2ggbmVlZHMgdG8gYmUgaW5zZXJ0ZWQsIGRldGFjaGVkLCBkZXN0cm95ZWRcbiAqIEBwYXJhbSBsVmlldyBUaGUgYExWaWV3YCB3aGljaCBuZWVkcyB0byBiZSBpbnNlcnRlZCwgZGV0YWNoZWQsIGRlc3Ryb3llZC5cbiAqIEBwYXJhbSB0UHJvamVjdGlvbk5vZGUgbm9kZSB0byBwcm9qZWN0XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhcHBseVByb2plY3Rpb24odFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcsIHRQcm9qZWN0aW9uTm9kZTogVFByb2plY3Rpb25Ob2RlKSB7XG4gIGNvbnN0IHJlbmRlcmVyID0gbFZpZXdbUkVOREVSRVJdO1xuICBjb25zdCBwYXJlbnRSTm9kZSA9IGdldFBhcmVudFJFbGVtZW50KHRWaWV3LCB0UHJvamVjdGlvbk5vZGUsIGxWaWV3KTtcbiAgY29uc3QgcGFyZW50VE5vZGUgPSB0UHJvamVjdGlvbk5vZGUucGFyZW50IHx8IGxWaWV3W1RfSE9TVF0hO1xuICBsZXQgYmVmb3JlTm9kZSA9IGdldEluc2VydEluRnJvbnRPZlJOb2RlKHBhcmVudFROb2RlLCB0UHJvamVjdGlvbk5vZGUsIGxWaWV3KTtcbiAgYXBwbHlQcm9qZWN0aW9uUmVjdXJzaXZlKFxuICAgICAgcmVuZGVyZXIsIFdhbGtUTm9kZVRyZWVBY3Rpb24uQ3JlYXRlLCBsVmlldywgdFByb2plY3Rpb25Ob2RlLCBwYXJlbnRSTm9kZSwgYmVmb3JlTm9kZSk7XG59XG5cbi8qKlxuICogYGFwcGx5UHJvamVjdGlvblJlY3Vyc2l2ZWAgcGVyZm9ybXMgb3BlcmF0aW9uIG9uIHRoZSBwcm9qZWN0aW9uIHNwZWNpZmllZCBieSBgYWN0aW9uYCAoaW5zZXJ0LFxuICogZGV0YWNoLCBkZXN0cm95KVxuICpcbiAqIEluc2VydGluZyBhIHByb2plY3Rpb24gcmVxdWlyZXMgdXMgdG8gbG9jYXRlIHRoZSBwcm9qZWN0ZWQgbm9kZXMgZnJvbSB0aGUgcGFyZW50IGNvbXBvbmVudC4gVGhlXG4gKiBjb21wbGljYXRpb24gaXMgdGhhdCB0aG9zZSBub2RlcyB0aGVtc2VsdmVzIGNvdWxkIGJlIHJlLXByb2plY3RlZCBmcm9tIHRoZWlyIHBhcmVudCBjb21wb25lbnQuXG4gKlxuICogQHBhcmFtIHJlbmRlcmVyIFJlbmRlciB0byB1c2VcbiAqIEBwYXJhbSBhY3Rpb24gYWN0aW9uIHRvIHBlcmZvcm0gKGluc2VydCwgZGV0YWNoLCBkZXN0cm95KVxuICogQHBhcmFtIGxWaWV3IFRoZSBMVmlldyB3aGljaCBuZWVkcyB0byBiZSBpbnNlcnRlZCwgZGV0YWNoZWQsIGRlc3Ryb3llZC5cbiAqIEBwYXJhbSB0UHJvamVjdGlvbk5vZGUgbm9kZSB0byBwcm9qZWN0XG4gKiBAcGFyYW0gcGFyZW50UkVsZW1lbnQgcGFyZW50IERPTSBlbGVtZW50IGZvciBpbnNlcnRpb24vcmVtb3ZhbC5cbiAqIEBwYXJhbSBiZWZvcmVOb2RlIEJlZm9yZSB3aGljaCBub2RlIHRoZSBpbnNlcnRpb25zIHNob3VsZCBoYXBwZW4uXG4gKi9cbmZ1bmN0aW9uIGFwcGx5UHJvamVjdGlvblJlY3Vyc2l2ZShcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIGFjdGlvbjogV2Fsa1ROb2RlVHJlZUFjdGlvbiwgbFZpZXc6IExWaWV3LCB0UHJvamVjdGlvbk5vZGU6IFRQcm9qZWN0aW9uTm9kZSxcbiAgICBwYXJlbnRSRWxlbWVudDogUkVsZW1lbnR8bnVsbCwgYmVmb3JlTm9kZTogUk5vZGV8bnVsbCkge1xuICBjb25zdCBjb21wb25lbnRMVmlldyA9IGxWaWV3W0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXXTtcbiAgY29uc3QgY29tcG9uZW50Tm9kZSA9IGNvbXBvbmVudExWaWV3W1RfSE9TVF0gYXMgVEVsZW1lbnROb2RlO1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydEVxdWFsKHR5cGVvZiB0UHJvamVjdGlvbk5vZGUucHJvamVjdGlvbiwgJ251bWJlcicsICdleHBlY3RpbmcgcHJvamVjdGlvbiBpbmRleCcpO1xuICBjb25zdCBub2RlVG9Qcm9qZWN0T3JSTm9kZXMgPSBjb21wb25lbnROb2RlLnByb2plY3Rpb24hW3RQcm9qZWN0aW9uTm9kZS5wcm9qZWN0aW9uXSE7XG4gIGlmIChBcnJheS5pc0FycmF5KG5vZGVUb1Byb2plY3RPclJOb2RlcykpIHtcbiAgICAvLyBUaGlzIHNob3VsZCBub3QgZXhpc3QsIGl0IGlzIGEgYml0IG9mIGEgaGFjay4gV2hlbiB3ZSBib290c3RyYXAgYSB0b3AgbGV2ZWwgbm9kZSBhbmQgd2VcbiAgICAvLyBuZWVkIHRvIHN1cHBvcnQgcGFzc2luZyBwcm9qZWN0YWJsZSBub2Rlcywgc28gd2UgY2hlYXQgYW5kIHB1dCB0aGVtIGluIHRoZSBUTm9kZVxuICAgIC8vIG9mIHRoZSBIb3N0IFRWaWV3LiAoWWVzIHdlIHB1dCBpbnN0YW5jZSBpbmZvIGF0IHRoZSBUIExldmVsKS4gV2UgY2FuIGdldCBhd2F5IHdpdGggaXRcbiAgICAvLyBiZWNhdXNlIHdlIGtub3cgdGhhdCB0aGF0IFRWaWV3IGlzIG5vdCBzaGFyZWQgYW5kIHRoZXJlZm9yZSBpdCB3aWxsIG5vdCBiZSBhIHByb2JsZW0uXG4gICAgLy8gVGhpcyBzaG91bGQgYmUgcmVmYWN0b3JlZCBhbmQgY2xlYW5lZCB1cC5cbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IG5vZGVUb1Byb2plY3RPclJOb2Rlcy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3Qgck5vZGUgPSBub2RlVG9Qcm9qZWN0T3JSTm9kZXNbaV07XG4gICAgICBhcHBseVRvRWxlbWVudE9yQ29udGFpbmVyKGFjdGlvbiwgcmVuZGVyZXIsIHBhcmVudFJFbGVtZW50LCByTm9kZSwgYmVmb3JlTm9kZSk7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIGxldCBub2RlVG9Qcm9qZWN0OiBUTm9kZXxudWxsID0gbm9kZVRvUHJvamVjdE9yUk5vZGVzO1xuICAgIGNvbnN0IHByb2plY3RlZENvbXBvbmVudExWaWV3ID0gY29tcG9uZW50TFZpZXdbUEFSRU5UXSBhcyBMVmlldztcbiAgICBhcHBseU5vZGVzKFxuICAgICAgICByZW5kZXJlciwgYWN0aW9uLCBub2RlVG9Qcm9qZWN0LCBwcm9qZWN0ZWRDb21wb25lbnRMVmlldywgcGFyZW50UkVsZW1lbnQsIGJlZm9yZU5vZGUsIHRydWUpO1xuICB9XG59XG5cblxuLyoqXG4gKiBgYXBwbHlDb250YWluZXJgIHBlcmZvcm1zIGFuIG9wZXJhdGlvbiBvbiB0aGUgY29udGFpbmVyIGFuZCBpdHMgdmlld3MgYXMgc3BlY2lmaWVkIGJ5XG4gKiBgYWN0aW9uYCAoaW5zZXJ0LCBkZXRhY2gsIGRlc3Ryb3kpXG4gKlxuICogSW5zZXJ0aW5nIGEgQ29udGFpbmVyIGlzIGNvbXBsaWNhdGVkIGJ5IHRoZSBmYWN0IHRoYXQgdGhlIGNvbnRhaW5lciBtYXkgaGF2ZSBWaWV3cyB3aGljaFxuICogdGhlbXNlbHZlcyBoYXZlIGNvbnRhaW5lcnMgb3IgcHJvamVjdGlvbnMuXG4gKlxuICogQHBhcmFtIHJlbmRlcmVyIFJlbmRlcmVyIHRvIHVzZVxuICogQHBhcmFtIGFjdGlvbiBhY3Rpb24gdG8gcGVyZm9ybSAoaW5zZXJ0LCBkZXRhY2gsIGRlc3Ryb3kpXG4gKiBAcGFyYW0gbENvbnRhaW5lciBUaGUgTENvbnRhaW5lciB3aGljaCBuZWVkcyB0byBiZSBpbnNlcnRlZCwgZGV0YWNoZWQsIGRlc3Ryb3llZC5cbiAqIEBwYXJhbSBwYXJlbnRSRWxlbWVudCBwYXJlbnQgRE9NIGVsZW1lbnQgZm9yIGluc2VydGlvbi9yZW1vdmFsLlxuICogQHBhcmFtIGJlZm9yZU5vZGUgQmVmb3JlIHdoaWNoIG5vZGUgdGhlIGluc2VydGlvbnMgc2hvdWxkIGhhcHBlbi5cbiAqL1xuZnVuY3Rpb24gYXBwbHlDb250YWluZXIoXG4gICAgcmVuZGVyZXI6IFJlbmRlcmVyLCBhY3Rpb246IFdhbGtUTm9kZVRyZWVBY3Rpb24sIGxDb250YWluZXI6IExDb250YWluZXIsXG4gICAgcGFyZW50UkVsZW1lbnQ6IFJFbGVtZW50fG51bGwsIGJlZm9yZU5vZGU6IFJOb2RlfG51bGx8dW5kZWZpbmVkKSB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRMQ29udGFpbmVyKGxDb250YWluZXIpO1xuICBjb25zdCBhbmNob3IgPSBsQ29udGFpbmVyW05BVElWRV07ICAvLyBMQ29udGFpbmVyIGhhcyBpdHMgb3duIGJlZm9yZSBub2RlLlxuICBjb25zdCBuYXRpdmUgPSB1bndyYXBSTm9kZShsQ29udGFpbmVyKTtcbiAgLy8gQW4gTENvbnRhaW5lciBjYW4gYmUgY3JlYXRlZCBkeW5hbWljYWxseSBvbiBhbnkgbm9kZSBieSBpbmplY3RpbmcgVmlld0NvbnRhaW5lclJlZi5cbiAgLy8gQXNraW5nIGZvciBhIFZpZXdDb250YWluZXJSZWYgb24gYW4gZWxlbWVudCB3aWxsIHJlc3VsdCBpbiBhIGNyZWF0aW9uIG9mIGEgc2VwYXJhdGUgYW5jaG9yXG4gIC8vIG5vZGUgKGNvbW1lbnQgaW4gdGhlIERPTSkgdGhhdCB3aWxsIGJlIGRpZmZlcmVudCBmcm9tIHRoZSBMQ29udGFpbmVyJ3MgaG9zdCBub2RlLiBJbiB0aGlzXG4gIC8vIHBhcnRpY3VsYXIgY2FzZSB3ZSBuZWVkIHRvIGV4ZWN1dGUgYWN0aW9uIG9uIDIgbm9kZXM6XG4gIC8vIC0gY29udGFpbmVyJ3MgaG9zdCBub2RlICh0aGlzIGlzIGRvbmUgaW4gdGhlIGV4ZWN1dGVBY3Rpb25PbkVsZW1lbnRPckNvbnRhaW5lcilcbiAgLy8gLSBjb250YWluZXIncyBob3N0IG5vZGUgKHRoaXMgaXMgZG9uZSBoZXJlKVxuICBpZiAoYW5jaG9yICE9PSBuYXRpdmUpIHtcbiAgICAvLyBUaGlzIGlzIHZlcnkgc3RyYW5nZSB0byBtZSAoTWlza28pLiBJIHdvdWxkIGV4cGVjdCB0aGF0IHRoZSBuYXRpdmUgaXMgc2FtZSBhcyBhbmNob3IuIElcbiAgICAvLyBkb24ndCBzZWUgYSByZWFzb24gd2h5IHRoZXkgc2hvdWxkIGJlIGRpZmZlcmVudCwgYnV0IHRoZXkgYXJlLlxuICAgIC8vXG4gICAgLy8gSWYgdGhleSBhcmUgd2UgbmVlZCB0byBwcm9jZXNzIHRoZSBzZWNvbmQgYW5jaG9yIGFzIHdlbGwuXG4gICAgYXBwbHlUb0VsZW1lbnRPckNvbnRhaW5lcihhY3Rpb24sIHJlbmRlcmVyLCBwYXJlbnRSRWxlbWVudCwgYW5jaG9yLCBiZWZvcmVOb2RlKTtcbiAgfVxuICBmb3IgKGxldCBpID0gQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQ7IGkgPCBsQ29udGFpbmVyLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgbFZpZXcgPSBsQ29udGFpbmVyW2ldIGFzIExWaWV3O1xuICAgIGFwcGx5VmlldyhsVmlld1tUVklFV10sIGxWaWV3LCByZW5kZXJlciwgYWN0aW9uLCBwYXJlbnRSRWxlbWVudCwgYW5jaG9yKTtcbiAgfVxufVxuXG4vKipcbiAqIFdyaXRlcyBjbGFzcy9zdHlsZSB0byBlbGVtZW50LlxuICpcbiAqIEBwYXJhbSByZW5kZXJlciBSZW5kZXJlciB0byB1c2UuXG4gKiBAcGFyYW0gaXNDbGFzc0Jhc2VkIGB0cnVlYCBpZiBpdCBzaG91bGQgYmUgd3JpdHRlbiB0byBgY2xhc3NgIChgZmFsc2VgIHRvIHdyaXRlIHRvIGBzdHlsZWApXG4gKiBAcGFyYW0gck5vZGUgVGhlIE5vZGUgdG8gd3JpdGUgdG8uXG4gKiBAcGFyYW0gcHJvcCBQcm9wZXJ0eSB0byB3cml0ZSB0by4gVGhpcyB3b3VsZCBiZSB0aGUgY2xhc3Mvc3R5bGUgbmFtZS5cbiAqIEBwYXJhbSB2YWx1ZSBWYWx1ZSB0byB3cml0ZS4gSWYgYG51bGxgL2B1bmRlZmluZWRgL2BmYWxzZWAgdGhpcyBpcyBjb25zaWRlcmVkIGEgcmVtb3ZlIChzZXQvYWRkXG4gKiAgICAgICAgb3RoZXJ3aXNlKS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGFwcGx5U3R5bGluZyhcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIGlzQ2xhc3NCYXNlZDogYm9vbGVhbiwgck5vZGU6IFJFbGVtZW50LCBwcm9wOiBzdHJpbmcsIHZhbHVlOiBhbnkpIHtcbiAgaWYgKGlzQ2xhc3NCYXNlZCkge1xuICAgIC8vIFdlIGFjdHVhbGx5IHdhbnQgSlMgdHJ1ZS9mYWxzZSBoZXJlIGJlY2F1c2UgYW55IHRydXRoeSB2YWx1ZSBzaG91bGQgYWRkIHRoZSBjbGFzc1xuICAgIGlmICghdmFsdWUpIHtcbiAgICAgIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJSZW1vdmVDbGFzcysrO1xuICAgICAgcmVuZGVyZXIucmVtb3ZlQ2xhc3Mock5vZGUsIHByb3ApO1xuICAgIH0gZWxzZSB7XG4gICAgICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyQWRkQ2xhc3MrKztcbiAgICAgIHJlbmRlcmVyLmFkZENsYXNzKHJOb2RlLCBwcm9wKTtcbiAgICB9XG4gIH0gZWxzZSB7XG4gICAgbGV0IGZsYWdzID0gcHJvcC5pbmRleE9mKCctJykgPT09IC0xID8gdW5kZWZpbmVkIDogUmVuZGVyZXJTdHlsZUZsYWdzMi5EYXNoQ2FzZSBhcyBudW1iZXI7XG4gICAgaWYgKHZhbHVlID09IG51bGwgLyoqIHx8IHZhbHVlID09PSB1bmRlZmluZWQgKi8pIHtcbiAgICAgIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJSZW1vdmVTdHlsZSsrO1xuICAgICAgcmVuZGVyZXIucmVtb3ZlU3R5bGUock5vZGUsIHByb3AsIGZsYWdzKTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gQSB2YWx1ZSBpcyBpbXBvcnRhbnQgaWYgaXQgZW5kcyB3aXRoIGAhaW1wb3J0YW50YC4gVGhlIHN0eWxlXG4gICAgICAvLyBwYXJzZXIgc3RyaXBzIGFueSBzZW1pY29sb25zIGF0IHRoZSBlbmQgb2YgdGhlIHZhbHVlLlxuICAgICAgY29uc3QgaXNJbXBvcnRhbnQgPSB0eXBlb2YgdmFsdWUgPT09ICdzdHJpbmcnID8gdmFsdWUuZW5kc1dpdGgoJyFpbXBvcnRhbnQnKSA6IGZhbHNlO1xuXG4gICAgICBpZiAoaXNJbXBvcnRhbnQpIHtcbiAgICAgICAgLy8gIWltcG9ydGFudCBoYXMgdG8gYmUgc3RyaXBwZWQgZnJvbSB0aGUgdmFsdWUgZm9yIGl0IHRvIGJlIHZhbGlkLlxuICAgICAgICB2YWx1ZSA9IHZhbHVlLnNsaWNlKDAsIC0xMCk7XG4gICAgICAgIGZsYWdzISB8PSBSZW5kZXJlclN0eWxlRmxhZ3MyLkltcG9ydGFudDtcbiAgICAgIH1cblxuICAgICAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlclNldFN0eWxlKys7XG4gICAgICByZW5kZXJlci5zZXRTdHlsZShyTm9kZSwgcHJvcCwgdmFsdWUsIGZsYWdzKTtcbiAgICB9XG4gIH1cbn1cblxuXG4vKipcbiAqIFdyaXRlIGBjc3NUZXh0YCB0byBgUkVsZW1lbnRgLlxuICpcbiAqIFRoaXMgZnVuY3Rpb24gZG9lcyBkaXJlY3Qgd3JpdGUgd2l0aG91dCBhbnkgcmVjb25jaWxpYXRpb24uIFVzZWQgZm9yIHdyaXRpbmcgaW5pdGlhbCB2YWx1ZXMsIHNvXG4gKiB0aGF0IHN0YXRpYyBzdHlsaW5nIHZhbHVlcyBkbyBub3QgcHVsbCBpbiB0aGUgc3R5bGUgcGFyc2VyLlxuICpcbiAqIEBwYXJhbSByZW5kZXJlciBSZW5kZXJlciB0byB1c2VcbiAqIEBwYXJhbSBlbGVtZW50IFRoZSBlbGVtZW50IHdoaWNoIG5lZWRzIHRvIGJlIHVwZGF0ZWQuXG4gKiBAcGFyYW0gbmV3VmFsdWUgVGhlIG5ldyBjbGFzcyBsaXN0IHRvIHdyaXRlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gd3JpdGVEaXJlY3RTdHlsZShyZW5kZXJlcjogUmVuZGVyZXIsIGVsZW1lbnQ6IFJFbGVtZW50LCBuZXdWYWx1ZTogc3RyaW5nKSB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRTdHJpbmcobmV3VmFsdWUsICdcXCduZXdWYWx1ZVxcJyBzaG91bGQgYmUgYSBzdHJpbmcnKTtcbiAgcmVuZGVyZXIuc2V0QXR0cmlidXRlKGVsZW1lbnQsICdzdHlsZScsIG5ld1ZhbHVlKTtcbiAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlclNldFN0eWxlKys7XG59XG5cbi8qKlxuICogV3JpdGUgYGNsYXNzTmFtZWAgdG8gYFJFbGVtZW50YC5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGRvZXMgZGlyZWN0IHdyaXRlIHdpdGhvdXQgYW55IHJlY29uY2lsaWF0aW9uLiBVc2VkIGZvciB3cml0aW5nIGluaXRpYWwgdmFsdWVzLCBzb1xuICogdGhhdCBzdGF0aWMgc3R5bGluZyB2YWx1ZXMgZG8gbm90IHB1bGwgaW4gdGhlIHN0eWxlIHBhcnNlci5cbiAqXG4gKiBAcGFyYW0gcmVuZGVyZXIgUmVuZGVyZXIgdG8gdXNlXG4gKiBAcGFyYW0gZWxlbWVudCBUaGUgZWxlbWVudCB3aGljaCBuZWVkcyB0byBiZSB1cGRhdGVkLlxuICogQHBhcmFtIG5ld1ZhbHVlIFRoZSBuZXcgY2xhc3MgbGlzdCB0byB3cml0ZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdyaXRlRGlyZWN0Q2xhc3MocmVuZGVyZXI6IFJlbmRlcmVyLCBlbGVtZW50OiBSRWxlbWVudCwgbmV3VmFsdWU6IHN0cmluZykge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0U3RyaW5nKG5ld1ZhbHVlLCAnXFwnbmV3VmFsdWVcXCcgc2hvdWxkIGJlIGEgc3RyaW5nJyk7XG4gIGlmIChuZXdWYWx1ZSA9PT0gJycpIHtcbiAgICAvLyBUaGVyZSBhcmUgdGVzdHMgaW4gYGdvb2dsZTNgIHdoaWNoIGV4cGVjdCBgZWxlbWVudC5nZXRBdHRyaWJ1dGUoJ2NsYXNzJylgIHRvIGJlIGBudWxsYC5cbiAgICByZW5kZXJlci5yZW1vdmVBdHRyaWJ1dGUoZWxlbWVudCwgJ2NsYXNzJyk7XG4gIH0gZWxzZSB7XG4gICAgcmVuZGVyZXIuc2V0QXR0cmlidXRlKGVsZW1lbnQsICdjbGFzcycsIG5ld1ZhbHVlKTtcbiAgfVxuICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyU2V0Q2xhc3NOYW1lKys7XG59XG5cbi8qKiBTZXRzIHVwIHRoZSBzdGF0aWMgRE9NIGF0dHJpYnV0ZXMgb24gYW4gYFJOb2RlYC4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzZXR1cFN0YXRpY0F0dHJpYnV0ZXMocmVuZGVyZXI6IFJlbmRlcmVyLCBlbGVtZW50OiBSRWxlbWVudCwgdE5vZGU6IFROb2RlKSB7XG4gIGNvbnN0IHttZXJnZWRBdHRycywgY2xhc3Nlcywgc3R5bGVzfSA9IHROb2RlO1xuXG4gIGlmIChtZXJnZWRBdHRycyAhPT0gbnVsbCkge1xuICAgIHNldFVwQXR0cmlidXRlcyhyZW5kZXJlciwgZWxlbWVudCwgbWVyZ2VkQXR0cnMpO1xuICB9XG5cbiAgaWYgKGNsYXNzZXMgIT09IG51bGwpIHtcbiAgICB3cml0ZURpcmVjdENsYXNzKHJlbmRlcmVyLCBlbGVtZW50LCBjbGFzc2VzKTtcbiAgfVxuXG4gIGlmIChzdHlsZXMgIT09IG51bGwpIHtcbiAgICB3cml0ZURpcmVjdFN0eWxlKHJlbmRlcmVyLCBlbGVtZW50LCBzdHlsZXMpO1xuICB9XG59XG4iXX0=