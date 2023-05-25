/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { EnvironmentInjector } from '../di/r3_injector';
import { validateMatchingNode } from '../hydration/error_handling';
import { CONTAINERS } from '../hydration/interfaces';
import { isInSkipHydrationBlock } from '../hydration/skip_hydration';
import { getSegmentHead, isDisconnectedNode, markRNodeAsClaimedByHydration } from '../hydration/utils';
import { findMatchingDehydratedView, locateDehydratedViewsInContainer } from '../hydration/views';
import { isType } from '../interface/type';
import { assertNodeInjector } from '../render3/assert';
import { ComponentFactory as R3ComponentFactory } from '../render3/component_ref';
import { getComponentDef } from '../render3/definition';
import { getParentInjectorLocation, NodeInjector } from '../render3/di';
import { addToViewTree, createLContainer } from '../render3/instructions/shared';
import { CONTAINER_HEADER_OFFSET, DEHYDRATED_VIEWS, NATIVE, VIEW_REFS } from '../render3/interfaces/container';
import { isLContainer } from '../render3/interfaces/type_checks';
import { HEADER_OFFSET, HYDRATION, PARENT, RENDERER, T_HOST, TVIEW } from '../render3/interfaces/view';
import { assertTNodeType } from '../render3/node_assert';
import { addViewToContainer, destroyLView, detachView, getBeforeNodeForView, insertView, nativeInsertBefore, nativeNextSibling, nativeParentNode } from '../render3/node_manipulation';
import { getCurrentTNode, getLView } from '../render3/state';
import { getParentInjectorIndex, getParentInjectorView, hasParentInjector } from '../render3/util/injector_utils';
import { getNativeByTNode, unwrapRNode, viewAttachedToContainer } from '../render3/util/view_utils';
import { ViewRef as R3ViewRef } from '../render3/view_ref';
import { addToArray, removeFromArray } from '../util/array_utils';
import { assertDefined, assertEqual, assertGreaterThan, assertLessThan, throwError } from '../util/assert';
import { createElementRef } from './element_ref';
/**
 * Represents a container where one or more views can be attached to a component.
 *
 * Can contain *host views* (created by instantiating a
 * component with the `createComponent()` method), and *embedded views*
 * (created by instantiating a `TemplateRef` with the `createEmbeddedView()` method).
 *
 * A view container instance can contain other view containers,
 * creating a [view hierarchy](guide/glossary#view-hierarchy).
 *
 * @see `ComponentRef`
 * @see `EmbeddedViewRef`
 *
 * @publicApi
 */
class ViewContainerRef {
    /**
     * @internal
     * @nocollapse
     */
    static { this.__NG_ELEMENT_ID__ = injectViewContainerRef; }
}
export { ViewContainerRef };
/**
 * Creates a ViewContainerRef and stores it on the injector. Or, if the ViewContainerRef
 * already exists, retrieves the existing ViewContainerRef.
 *
 * @returns The ViewContainerRef instance to use
 */
export function injectViewContainerRef() {
    const previousTNode = getCurrentTNode();
    return createContainerRef(previousTNode, getLView());
}
const VE_ViewContainerRef = ViewContainerRef;
// TODO(alxhub): cleaning up this indirection triggers a subtle bug in Closure in g3. Once the fix
// for that lands, this can be cleaned up.
const R3ViewContainerRef = class ViewContainerRef extends VE_ViewContainerRef {
    constructor(_lContainer, _hostTNode, _hostLView) {
        super();
        this._lContainer = _lContainer;
        this._hostTNode = _hostTNode;
        this._hostLView = _hostLView;
    }
    get element() {
        return createElementRef(this._hostTNode, this._hostLView);
    }
    get injector() {
        return new NodeInjector(this._hostTNode, this._hostLView);
    }
    /** @deprecated No replacement */
    get parentInjector() {
        const parentLocation = getParentInjectorLocation(this._hostTNode, this._hostLView);
        if (hasParentInjector(parentLocation)) {
            const parentView = getParentInjectorView(parentLocation, this._hostLView);
            const injectorIndex = getParentInjectorIndex(parentLocation);
            ngDevMode && assertNodeInjector(parentView, injectorIndex);
            const parentTNode = parentView[TVIEW].data[injectorIndex + 8 /* NodeInjectorOffset.TNODE */];
            return new NodeInjector(parentTNode, parentView);
        }
        else {
            return new NodeInjector(null, this._hostLView);
        }
    }
    clear() {
        while (this.length > 0) {
            this.remove(this.length - 1);
        }
    }
    get(index) {
        const viewRefs = getViewRefs(this._lContainer);
        return viewRefs !== null && viewRefs[index] || null;
    }
    get length() {
        return this._lContainer.length - CONTAINER_HEADER_OFFSET;
    }
    createEmbeddedView(templateRef, context, indexOrOptions) {
        let index;
        let injector;
        if (typeof indexOrOptions === 'number') {
            index = indexOrOptions;
        }
        else if (indexOrOptions != null) {
            index = indexOrOptions.index;
            injector = indexOrOptions.injector;
        }
        const hydrationInfo = findMatchingDehydratedView(this._lContainer, templateRef.ssrId);
        const viewRef = templateRef.createEmbeddedViewImpl(context || {}, injector, hydrationInfo);
        this.insertImpl(viewRef, index, !!hydrationInfo);
        return viewRef;
    }
    createComponent(componentFactoryOrType, indexOrOptions, injector, projectableNodes, environmentInjector) {
        const isComponentFactory = componentFactoryOrType && !isType(componentFactoryOrType);
        let index;
        // This function supports 2 signatures and we need to handle options correctly for both:
        //   1. When first argument is a Component type. This signature also requires extra
        //      options to be provided as as object (more ergonomic option).
        //   2. First argument is a Component factory. In this case extra options are represented as
        //      positional arguments. This signature is less ergonomic and will be deprecated.
        if (isComponentFactory) {
            if (ngDevMode) {
                assertEqual(typeof indexOrOptions !== 'object', true, 'It looks like Component factory was provided as the first argument ' +
                    'and an options object as the second argument. This combination of arguments ' +
                    'is incompatible. You can either change the first argument to provide Component ' +
                    'type or change the second argument to be a number (representing an index at ' +
                    'which to insert the new component\'s host view into this container)');
            }
            index = indexOrOptions;
        }
        else {
            if (ngDevMode) {
                assertDefined(getComponentDef(componentFactoryOrType), `Provided Component class doesn't contain Component definition. ` +
                    `Please check whether provided class has @Component decorator.`);
                assertEqual(typeof indexOrOptions !== 'number', true, 'It looks like Component type was provided as the first argument ' +
                    'and a number (representing an index at which to insert the new component\'s ' +
                    'host view into this container as the second argument. This combination of arguments ' +
                    'is incompatible. Please use an object as the second argument instead.');
            }
            const options = (indexOrOptions || {});
            if (ngDevMode && options.environmentInjector && options.ngModuleRef) {
                throwError(`Cannot pass both environmentInjector and ngModuleRef options to createComponent().`);
            }
            index = options.index;
            injector = options.injector;
            projectableNodes = options.projectableNodes;
            environmentInjector = options.environmentInjector || options.ngModuleRef;
        }
        const componentFactory = isComponentFactory ?
            componentFactoryOrType :
            new R3ComponentFactory(getComponentDef(componentFactoryOrType));
        const contextInjector = injector || this.parentInjector;
        // If an `NgModuleRef` is not provided explicitly, try retrieving it from the DI tree.
        if (!environmentInjector && componentFactory.ngModule == null) {
            // For the `ComponentFactory` case, entering this logic is very unlikely, since we expect that
            // an instance of a `ComponentFactory`, resolved via `ComponentFactoryResolver` would have an
            // `ngModule` field. This is possible in some test scenarios and potentially in some JIT-based
            // use-cases. For the `ComponentFactory` case we preserve backwards-compatibility and try
            // using a provided injector first, then fall back to the parent injector of this
            // `ViewContainerRef` instance.
            //
            // For the factory-less case, it's critical to establish a connection with the module
            // injector tree (by retrieving an instance of an `NgModuleRef` and accessing its injector),
            // so that a component can use DI tokens provided in MgModules. For this reason, we can not
            // rely on the provided injector, since it might be detached from the DI tree (for example, if
            // it was created via `Injector.create` without specifying a parent injector, or if an
            // injector is retrieved from an `NgModuleRef` created via `createNgModule` using an
            // NgModule outside of a module tree). Instead, we always use `ViewContainerRef`'s parent
            // injector, which is normally connected to the DI tree, which includes module injector
            // subtree.
            const _injector = isComponentFactory ? contextInjector : this.parentInjector;
            // DO NOT REFACTOR. The code here used to have a `injector.get(NgModuleRef, null) ||
            // undefined` expression which seems to cause internal google apps to fail. This is documented
            // in the following internal bug issue: go/b/142967802
            const result = _injector.get(EnvironmentInjector, null);
            if (result) {
                environmentInjector = result;
            }
        }
        const componentDef = getComponentDef(componentFactory.componentType ?? {});
        const dehydratedView = findMatchingDehydratedView(this._lContainer, componentDef?.id ?? null);
        const rNode = dehydratedView?.firstChild ?? null;
        const componentRef = componentFactory.create(contextInjector, projectableNodes, rNode, environmentInjector);
        this.insertImpl(componentRef.hostView, index, !!dehydratedView);
        return componentRef;
    }
    insert(viewRef, index) {
        return this.insertImpl(viewRef, index, false);
    }
    insertImpl(viewRef, index, skipDomInsertion) {
        const lView = viewRef._lView;
        const tView = lView[TVIEW];
        if (ngDevMode && viewRef.destroyed) {
            throw new Error('Cannot insert a destroyed View in a ViewContainer!');
        }
        if (viewAttachedToContainer(lView)) {
            // If view is already attached, detach it first so we clean up references appropriately.
            const prevIdx = this.indexOf(viewRef);
            // A view might be attached either to this or a different container. The `prevIdx` for
            // those cases will be:
            // equal to -1 for views attached to this ViewContainerRef
            // >= 0 for views attached to a different ViewContainerRef
            if (prevIdx !== -1) {
                this.detach(prevIdx);
            }
            else {
                const prevLContainer = lView[PARENT];
                ngDevMode &&
                    assertEqual(isLContainer(prevLContainer), true, 'An attached view should have its PARENT point to a container.');
                // We need to re-create a R3ViewContainerRef instance since those are not stored on
                // LView (nor anywhere else).
                const prevVCRef = new R3ViewContainerRef(prevLContainer, prevLContainer[T_HOST], prevLContainer[PARENT]);
                prevVCRef.detach(prevVCRef.indexOf(viewRef));
            }
        }
        // Logical operation of adding `LView` to `LContainer`
        const adjustedIdx = this._adjustIndex(index);
        const lContainer = this._lContainer;
        insertView(tView, lView, lContainer, adjustedIdx);
        // Physical operation of adding the DOM nodes.
        if (!skipDomInsertion) {
            const beforeNode = getBeforeNodeForView(adjustedIdx, lContainer);
            const renderer = lView[RENDERER];
            const parentRNode = nativeParentNode(renderer, lContainer[NATIVE]);
            if (parentRNode !== null) {
                addViewToContainer(tView, lContainer[T_HOST], renderer, lView, parentRNode, beforeNode);
            }
        }
        viewRef.attachToViewContainerRef();
        addToArray(getOrCreateViewRefs(lContainer), adjustedIdx, viewRef);
        return viewRef;
    }
    move(viewRef, newIndex) {
        if (ngDevMode && viewRef.destroyed) {
            throw new Error('Cannot move a destroyed View in a ViewContainer!');
        }
        return this.insert(viewRef, newIndex);
    }
    indexOf(viewRef) {
        const viewRefsArr = getViewRefs(this._lContainer);
        return viewRefsArr !== null ? viewRefsArr.indexOf(viewRef) : -1;
    }
    remove(index) {
        const adjustedIdx = this._adjustIndex(index, -1);
        const detachedView = detachView(this._lContainer, adjustedIdx);
        if (detachedView) {
            // Before destroying the view, remove it from the container's array of `ViewRef`s.
            // This ensures the view container length is updated before calling
            // `destroyLView`, which could recursively call view container methods that
            // rely on an accurate container length.
            // (e.g. a method on this view container being called by a child directive's OnDestroy
            // lifecycle hook)
            removeFromArray(getOrCreateViewRefs(this._lContainer), adjustedIdx);
            destroyLView(detachedView[TVIEW], detachedView);
        }
    }
    detach(index) {
        const adjustedIdx = this._adjustIndex(index, -1);
        const view = detachView(this._lContainer, adjustedIdx);
        const wasDetached = view && removeFromArray(getOrCreateViewRefs(this._lContainer), adjustedIdx) != null;
        return wasDetached ? new R3ViewRef(view) : null;
    }
    _adjustIndex(index, shift = 0) {
        if (index == null) {
            return this.length + shift;
        }
        if (ngDevMode) {
            assertGreaterThan(index, -1, `ViewRef index must be positive, got ${index}`);
            // +1 because it's legal to insert at the end.
            assertLessThan(index, this.length + 1 + shift, 'index');
        }
        return index;
    }
};
function getViewRefs(lContainer) {
    return lContainer[VIEW_REFS];
}
function getOrCreateViewRefs(lContainer) {
    return (lContainer[VIEW_REFS] || (lContainer[VIEW_REFS] = []));
}
/**
 * Creates a ViewContainerRef and stores it on the injector.
 *
 * @param hostTNode The node that is requesting a ViewContainerRef
 * @param hostLView The view to which the node belongs
 * @returns The ViewContainerRef instance to use
 */
export function createContainerRef(hostTNode, hostLView) {
    ngDevMode && assertTNodeType(hostTNode, 12 /* TNodeType.AnyContainer */ | 3 /* TNodeType.AnyRNode */);
    let lContainer;
    const slotValue = hostLView[hostTNode.index];
    if (isLContainer(slotValue)) {
        // If the host is a container, we don't need to create a new LContainer
        lContainer = slotValue;
    }
    else {
        // An LContainer anchor can not be `null`, but we set it here temporarily
        // and update to the actual value later in this function (see
        // `_locateOrCreateAnchorNode`).
        lContainer = createLContainer(slotValue, hostLView, null, hostTNode);
        hostLView[hostTNode.index] = lContainer;
        addToViewTree(hostLView, lContainer);
    }
    _locateOrCreateAnchorNode(lContainer, hostLView, hostTNode, slotValue);
    return new R3ViewContainerRef(lContainer, hostTNode, hostLView);
}
/**
 * Creates and inserts a comment node that acts as an anchor for a view container.
 *
 * If the host is a regular element, we have to insert a comment node manually which will
 * be used as an anchor when inserting elements. In this specific case we use low-level DOM
 * manipulation to insert it.
 */
function insertAnchorNode(hostLView, hostTNode) {
    const renderer = hostLView[RENDERER];
    ngDevMode && ngDevMode.rendererCreateComment++;
    const commentNode = renderer.createComment(ngDevMode ? 'container' : '');
    const hostNative = getNativeByTNode(hostTNode, hostLView);
    const parentOfHostNative = nativeParentNode(renderer, hostNative);
    nativeInsertBefore(renderer, parentOfHostNative, commentNode, nativeNextSibling(renderer, hostNative), false);
    return commentNode;
}
let _locateOrCreateAnchorNode = createAnchorNode;
/**
 * Regular creation mode: an anchor is created and
 * assigned to the `lContainer[NATIVE]` slot.
 */
function createAnchorNode(lContainer, hostLView, hostTNode, slotValue) {
    // We already have a native element (anchor) set, return.
    if (lContainer[NATIVE])
        return;
    let commentNode;
    // If the host is an element container, the native host element is guaranteed to be a
    // comment and we can reuse that comment as anchor element for the new LContainer.
    // The comment node in question is already part of the DOM structure so we don't need to append
    // it again.
    if (hostTNode.type & 8 /* TNodeType.ElementContainer */) {
        commentNode = unwrapRNode(slotValue);
    }
    else {
        commentNode = insertAnchorNode(hostLView, hostTNode);
    }
    lContainer[NATIVE] = commentNode;
}
/**
 * Hydration logic that looks up:
 *  - an anchor node in the DOM and stores the node in `lContainer[NATIVE]`
 *  - all dehydrated views in this container and puts them into `lContainer[DEHYDRATED_VIEWS]`
 */
function locateOrCreateAnchorNode(lContainer, hostLView, hostTNode, slotValue) {
    // We already have a native element (anchor) set and the process
    // of finding dehydrated views happened (so the `lContainer[DEHYDRATED_VIEWS]`
    // is not null), exit early.
    if (lContainer[NATIVE] && lContainer[DEHYDRATED_VIEWS])
        return;
    const hydrationInfo = hostLView[HYDRATION];
    const noOffsetIndex = hostTNode.index - HEADER_OFFSET;
    const isNodeCreationMode = !hydrationInfo || isInSkipHydrationBlock(hostTNode) ||
        isDisconnectedNode(hydrationInfo, noOffsetIndex);
    // Regular creation mode.
    if (isNodeCreationMode) {
        return createAnchorNode(lContainer, hostLView, hostTNode, slotValue);
    }
    // Hydration mode, looking up an anchor node and dehydrated views in DOM.
    const currentRNode = getSegmentHead(hydrationInfo, noOffsetIndex);
    const serializedViews = hydrationInfo.data[CONTAINERS]?.[noOffsetIndex];
    ngDevMode &&
        assertDefined(serializedViews, 'Unexpected state: no hydration info available for a given TNode, ' +
            'which represents a view container.');
    const [commentNode, dehydratedViews] = locateDehydratedViewsInContainer(currentRNode, serializedViews);
    if (ngDevMode) {
        validateMatchingNode(commentNode, Node.COMMENT_NODE, null, hostLView, hostTNode, true);
        // Do not throw in case this node is already claimed (thus `false` as a second
        // argument). If this container is created based on an `<ng-template>`, the comment
        // node would be already claimed from the `template` instruction. If an element acts
        // as an anchor (e.g. <div #vcRef>), a separate comment node would be created/located,
        // so we need to claim it here.
        markRNodeAsClaimedByHydration(commentNode, false);
    }
    lContainer[NATIVE] = commentNode;
    lContainer[DEHYDRATED_VIEWS] = dehydratedViews;
}
export function enableLocateOrCreateContainerRefImpl() {
    _locateOrCreateAnchorNode = locateOrCreateAnchorNode;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidmlld19jb250YWluZXJfcmVmLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvbGlua2VyL3ZpZXdfY29udGFpbmVyX3JlZi50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFHSCxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUN0RCxPQUFPLEVBQUMsb0JBQW9CLEVBQUMsTUFBTSw2QkFBNkIsQ0FBQztBQUNqRSxPQUFPLEVBQUMsVUFBVSxFQUFDLE1BQU0seUJBQXlCLENBQUM7QUFDbkQsT0FBTyxFQUFDLHNCQUFzQixFQUFDLE1BQU0sNkJBQTZCLENBQUM7QUFDbkUsT0FBTyxFQUFDLGNBQWMsRUFBRSxrQkFBa0IsRUFBRSw2QkFBNkIsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBQ3JHLE9BQU8sRUFBQywwQkFBMEIsRUFBRSxnQ0FBZ0MsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBQ2hHLE9BQU8sRUFBQyxNQUFNLEVBQU8sTUFBTSxtQkFBbUIsQ0FBQztBQUMvQyxPQUFPLEVBQUMsa0JBQWtCLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUNyRCxPQUFPLEVBQUMsZ0JBQWdCLElBQUksa0JBQWtCLEVBQUMsTUFBTSwwQkFBMEIsQ0FBQztBQUNoRixPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0sdUJBQXVCLENBQUM7QUFDdEQsT0FBTyxFQUFDLHlCQUF5QixFQUFFLFlBQVksRUFBQyxNQUFNLGVBQWUsQ0FBQztBQUN0RSxPQUFPLEVBQUMsYUFBYSxFQUFFLGdCQUFnQixFQUFDLE1BQU0sZ0NBQWdDLENBQUM7QUFDL0UsT0FBTyxFQUFDLHVCQUF1QixFQUFFLGdCQUFnQixFQUFjLE1BQU0sRUFBRSxTQUFTLEVBQUMsTUFBTSxpQ0FBaUMsQ0FBQztBQUl6SCxPQUFPLEVBQUMsWUFBWSxFQUFDLE1BQU0sbUNBQW1DLENBQUM7QUFD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LHlCQUF5QixHQUFHLHdCQUF3QixDQUFDO0FBQ3ZELENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtJbmplY3Rvcn0gZnJvbSAnLi4vZGkvaW5qZWN0b3InO1xuaW1wb3J0IHtFbnZpcm9ubWVudEluamVjdG9yfSBmcm9tICcuLi9kaS9yM19pbmplY3Rvcic7XG5pbXBvcnQge3ZhbGlkYXRlTWF0Y2hpbmdOb2RlfSBmcm9tICcuLi9oeWRyYXRpb24vZXJyb3JfaGFuZGxpbmcnO1xuaW1wb3J0IHtDT05UQUlORVJTfSBmcm9tICcuLi9oeWRyYXRpb24vaW50ZXJmYWNlcyc7XG5pbXBvcnQge2lzSW5Ta2lwSHlkcmF0aW9uQmxvY2t9IGZyb20gJy4uL2h5ZHJhdGlvbi9za2lwX2h5ZHJhdGlvbic7XG5pbXBvcnQge2dldFNlZ21lbnRIZWFkLCBpc0Rpc2Nvbm5lY3RlZE5vZGUsIG1hcmtSTm9kZUFzQ2xhaW1lZEJ5SHlkcmF0aW9ufSBmcm9tICcuLi9oeWRyYXRpb24vdXRpbHMnO1xuaW1wb3J0IHtmaW5kTWF0Y2hpbmdEZWh5ZHJhdGVkVmlldywgbG9jYXRlRGVoeWRyYXRlZFZpZXdzSW5Db250YWluZXJ9IGZyb20gJy4uL2h5ZHJhdGlvbi92aWV3cyc7XG5pbXBvcnQge2lzVHlwZSwgVHlwZX0gZnJvbSAnLi4vaW50ZXJmYWNlL3R5cGUnO1xuaW1wb3J0IHthc3NlcnROb2RlSW5qZWN0b3J9IGZyb20gJy4uL3JlbmRlcjMvYXNzZXJ0JztcbmltcG9ydCB7Q29tcG9uZW50RmFjdG9yeSBhcyBSM0NvbXBvbmVudEZhY3Rvcnl9IGZyb20gJy4uL3JlbmRlcjMvY29tcG9uZW50X3JlZic7XG5pbXBvcnQge2dldENvbXBvbmVudERlZn0gZnJvbSAnLi4vcmVuZGVyMy9kZWZpbml0aW9uJztcbmltcG9ydCB7Z2V0UGFyZW50SW5qZWN0b3JMb2NhdGlvbiwgTm9kZUluamVjdG9yfSBmcm9tICcuLi9yZW5kZXIzL2RpJztcbmltcG9ydCB7YWRkVG9WaWV3VHJlZSwgY3JlYXRlTENvbnRhaW5lcn0gZnJvbSAnLi4vcmVuZGVyMy9pbnN0cnVjdGlvbnMvc2hhcmVkJztcbmltcG9ydCB7Q09OVEFJTkVSX0hFQURFUl9PRkZTRVQsIERFSFlEUkFURURfVklFV1MsIExDb250YWluZXIsIE5BVElWRSwgVklFV19SRUZTfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvY29udGFpbmVyJztcbmltcG9ydCB7Tm9kZUluamVjdG9yT2Zmc2V0fSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvaW5qZWN0b3InO1xuaW1wb3J0IHtUQ29udGFpbmVyTm9kZSwgVERpcmVjdGl2ZUhvc3ROb2RlLCBURWxlbWVudENvbnRhaW5lck5vZGUsIFRFbGVtZW50Tm9kZSwgVE5vZGUsIFROb2RlVHlwZX0gZnJvbSAnLi4vcmVuZGVyMy9pbnRlcmZhY2VzL25vZGUnO1xuaW1wb3J0IHtSQ29tbWVudCwgUkVsZW1lbnQsIFJOb2RlfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvcmVuZGVyZXJfZG9tJztcbmltcG9ydCB7aXNMQ29udGFpbmVyfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvdHlwZV9jaGVja3MnO1xuaW1wb3J0IHtIRUFERVJfT0ZGU0VULCBIWURSQVRJT04sIExWaWV3LCBQQVJFTlQsIFJFTkRFUkVSLCBUX0hPU1QsIFRWSUVXfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvdmlldyc7XG5pbXBvcnQge2Fzc2VydFROb2RlVHlwZX0gZnJvbSAnLi4vcmVuZGVyMy9ub2RlX2Fzc2VydCc7XG5pbXBvcnQge2FkZFZpZXdUb0NvbnRhaW5lciwgZGVzdHJveUxWaWV3LCBkZXRhY2hWaWV3LCBnZXRCZWZvcmVOb2RlRm9yVmlldywgaW5zZXJ0VmlldywgbmF0aXZlSW5zZXJ0QmVmb3JlLCBuYXRpdmVOZXh0U2libGluZywgbmF0aXZlUGFyZW50Tm9kZX0gZnJvbSAnLi4vcmVuZGVyMy9ub2RlX21hbmlwdWxhdGlvbic7XG5pbXBvcnQge2dldEN1cnJlbnRUTm9kZSwgZ2V0TFZpZXd9IGZyb20gJy4uL3JlbmRlcjMvc3RhdGUnO1xuaW1wb3J0IHtnZXRQYXJlbnRJbmplY3RvckluZGV4LCBnZXRQYXJlbnRJbmplY3RvclZpZXcsIGhhc1BhcmVudEluamVjdG9yfSBmcm9tICcuLi9yZW5kZXIzL3V0aWwvaW5qZWN0b3JfdXRpbHMnO1xuaW1wb3J0IHtnZXROYXRpdmVCeVROb2RlLCB1bndyYXBSTm9kZSwgdmlld0F0dGFjaGVkVG9Db250YWluZXJ9IGZyb20gJy4uL3JlbmRlcjMvdXRpbC92aWV3X3V0aWxzJztcbmltcG9ydCB7Vmlld1JlZiBhcyBSM1ZpZXdSZWZ9IGZyb20gJy4uL3JlbmRlcjMvdmlld19yZWYnO1xuaW1wb3J0IHthZGRUb0FycmF5LCByZW1vdmVGcm9tQXJyYXl9IGZyb20gJy4uL3V0aWwvYXJyYXlfdXRpbHMnO1xuaW1wb3J0IHthc3NlcnREZWZpbmVkLCBhc3NlcnRFcXVhbCwgYXNzZXJ0R3JlYXRlclRoYW4sIGFzc2VydExlc3NUaGFuLCB0aHJvd0Vycm9yfSBmcm9tICcuLi91dGlsL2Fzc2VydCc7XG5cbmltcG9ydCB7Q29tcG9uZW50RmFjdG9yeSwgQ29tcG9uZW50UmVmfSBmcm9tICcuL2NvbXBvbmVudF9mYWN0b3J5JztcbmltcG9ydCB7Y3JlYXRlRWxlbWVudFJlZiwgRWxlbWVudFJlZn0gZnJvbSAnLi9lbGVtZW50X3JlZic7XG5pbXBvcnQge05nTW9kdWxlUmVmfSBmcm9tICcuL25nX21vZHVsZV9mYWN0b3J5JztcbmltcG9ydCB7VGVtcGxhdGVSZWZ9IGZyb20gJy4vdGVtcGxhdGVfcmVmJztcbmltcG9ydCB7RW1iZWRkZWRWaWV3UmVmLCBWaWV3UmVmfSBmcm9tICcuL3ZpZXdfcmVmJztcblxuLyoqXG4gKiBSZXByZXNlbnRzIGEgY29udGFpbmVyIHdoZXJlIG9uZSBvciBtb3JlIHZpZXdzIGNhbiBiZSBhdHRhY2hlZCB0byBhIGNvbXBvbmVudC5cbiAqXG4gKiBDYW4gY29udGFpbiAqaG9zdCB2aWV3cyogKGNyZWF0ZWQgYnkgaW5zdGFudGlhdGluZyBhXG4gKiBjb21wb25lbnQgd2l0aCB0aGUgYGNyZWF0ZUNvbXBvbmVudCgpYCBtZXRob2QpLCBhbmQgKmVtYmVkZGVkIHZpZXdzKlxuICogKGNyZWF0ZWQgYnkgaW5zdGFudGlhdGluZyBhIGBUZW1wbGF0ZVJlZmAgd2l0aCB0aGUgYGNyZWF0ZUVtYmVkZGVkVmlldygpYCBtZXRob2QpLlxuICpcbiAqIEEgdmlldyBjb250YWluZXIgaW5zdGFuY2UgY2FuIGNvbnRhaW4gb3RoZXIgdmlldyBjb250YWluZXJzLFxuICogY3JlYXRpbmcgYSBbdmlldyBoaWVyYXJjaHldKGd1aWRlL2dsb3NzYXJ5I3ZpZXctaGllcmFyY2h5KS5cbiAqXG4gKiBAc2VlIGBDb21wb25lbnRSZWZgXG4gKiBAc2VlIGBFbWJlZGRlZFZpZXdSZWZgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgYWJzdHJhY3QgY2xhc3MgVmlld0NvbnRhaW5lclJlZiB7XG4gIC8qKlxuICAgKiBBbmNob3IgZWxlbWVudCB0aGF0IHNwZWNpZmllcyB0aGUgbG9jYXRpb24gb2YgdGhpcyBjb250YWluZXIgaW4gdGhlIGNvbnRhaW5pbmcgdmlldy5cbiAgICogRWFjaCB2aWV3IGNvbnRhaW5lciBjYW4gaGF2ZSBvbmx5IG9uZSBhbmNob3IgZWxlbWVudCwgYW5kIGVhY2ggYW5jaG9yIGVsZW1lbnRcbiAgICogY2FuIGhhdmUgb25seSBhIHNpbmdsZSB2aWV3IGNvbnRhaW5lci5cbiAgICpcbiAgICogUm9vdCBlbGVtZW50cyBvZiB2aWV3cyBhdHRhY2hlZCB0byB0aGlzIGNvbnRhaW5lciBiZWNvbWUgc2libGluZ3Mgb2YgdGhlIGFuY2hvciBlbGVtZW50IGluXG4gICAqIHRoZSByZW5kZXJlZCB2aWV3LlxuICAgKlxuICAgKiBBY2Nlc3MgdGhlIGBWaWV3Q29udGFpbmVyUmVmYCBvZiBhbiBlbGVtZW50IGJ5IHBsYWNpbmcgYSBgRGlyZWN0aXZlYCBpbmplY3RlZFxuICAgKiB3aXRoIGBWaWV3Q29udGFpbmVyUmVmYCBvbiB0aGUgZWxlbWVudCwgb3IgdXNlIGEgYFZpZXdDaGlsZGAgcXVlcnkuXG4gICAqXG4gICAqIDwhLS0gVE9ETzogcmVuYW1lIHRvIGFuY2hvckVsZW1lbnQgLS0+XG4gICAqL1xuICBhYnN0cmFjdCBnZXQgZWxlbWVudCgpOiBFbGVtZW50UmVmO1xuXG4gIC8qKlxuICAgKiBUaGUgW2RlcGVuZGVuY3kgaW5qZWN0b3JdKGd1aWRlL2dsb3NzYXJ5I2luamVjdG9yKSBmb3IgdGhpcyB2aWV3IGNvbnRhaW5lci5cbiAgICovXG4gIGFic3RyYWN0IGdldCBpbmplY3RvcigpOiBJbmplY3RvcjtcblxuICAvKiogQGRlcHJlY2F0ZWQgTm8gcmVwbGFjZW1lbnQgKi9cbiAgYWJzdHJhY3QgZ2V0IHBhcmVudEluamVjdG9yKCk6IEluamVjdG9yO1xuXG4gIC8qKlxuICAgKiBEZXN0cm95cyBhbGwgdmlld3MgaW4gdGhpcyBjb250YWluZXIuXG4gICAqL1xuICBhYnN0cmFjdCBjbGVhcigpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZXMgYSB2aWV3IGZyb20gdGhpcyBjb250YWluZXIuXG4gICAqIEBwYXJhbSBpbmRleCBUaGUgMC1iYXNlZCBpbmRleCBvZiB0aGUgdmlldyB0byByZXRyaWV2ZS5cbiAgICogQHJldHVybnMgVGhlIGBWaWV3UmVmYCBpbnN0YW5jZSwgb3IgbnVsbCBpZiB0aGUgaW5kZXggaXMgb3V0IG9mIHJhbmdlLlxuICAgKi9cbiAgYWJzdHJhY3QgZ2V0KGluZGV4OiBudW1iZXIpOiBWaWV3UmVmfG51bGw7XG5cbiAgLyoqXG4gICAqIFJlcG9ydHMgaG93IG1hbnkgdmlld3MgYXJlIGN1cnJlbnRseSBhdHRhY2hlZCB0byB0aGlzIGNvbnRhaW5lci5cbiAgICogQHJldHVybnMgVGhlIG51bWJlciBvZiB2aWV3cy5cbiAgICovXG4gIGFic3RyYWN0IGdldCBsZW5ndGgoKTogbnVtYmVyO1xuXG4gIC8qKlxuICAgKiBJbnN0YW50aWF0ZXMgYW4gZW1iZWRkZWQgdmlldyBhbmQgaW5zZXJ0cyBpdFxuICAgKiBpbnRvIHRoaXMgY29udGFpbmVyLlxuICAgKiBAcGFyYW0gdGVtcGxhdGVSZWYgVGhlIEhUTUwgdGVtcGxhdGUgdGhhdCBkZWZpbmVzIHRoZSB2aWV3LlxuICAgKiBAcGFyYW0gY29udGV4dCBUaGUgZGF0YS1iaW5kaW5nIGNvbnRleHQgb2YgdGhlIGVtYmVkZGVkIHZpZXcsIGFzIGRlY2xhcmVkXG4gICAqIGluIHRoZSBgPG5nLXRlbXBsYXRlPmAgdXNhZ2UuXG4gICAqIEBwYXJhbSBvcHRpb25zIEV4dHJhIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSBjcmVhdGVkIHZpZXcuIEluY2x1ZGVzOlxuICAgKiAgKiBpbmRleDogVGhlIDAtYmFzZWQgaW5kZXggYXQgd2hpY2ggdG8gaW5zZXJ0IHRoZSBuZXcgdmlldyBpbnRvIHRoaXMgY29udGFpbmVyLlxuICAgKiAgICAgICAgICAgSWYgbm90IHNwZWNpZmllZCwgYXBwZW5kcyB0aGUgbmV3IHZpZXcgYXMgdGhlIGxhc3QgZW50cnkuXG4gICAqICAqIGluamVjdG9yOiBJbmplY3RvciB0byBiZSB1c2VkIHdpdGhpbiB0aGUgZW1iZWRkZWQgdmlldy5cbiAgICpcbiAgICogQHJldHVybnMgVGhlIGBWaWV3UmVmYCBpbnN0YW5jZSBmb3IgdGhlIG5ld2x5IGNyZWF0ZWQgdmlldy5cbiAgICovXG4gIGFic3RyYWN0IGNyZWF0ZUVtYmVkZGVkVmlldzxDPih0ZW1wbGF0ZVJlZjogVGVtcGxhdGVSZWY8Qz4sIGNvbnRleHQ/OiBDLCBvcHRpb25zPzoge1xuICAgIGluZGV4PzogbnVtYmVyLFxuICAgIGluamVjdG9yPzogSW5qZWN0b3JcbiAgfSk6IEVtYmVkZGVkVmlld1JlZjxDPjtcblxuICAvKipcbiAgICogSW5zdGFudGlhdGVzIGFuIGVtYmVkZGVkIHZpZXcgYW5kIGluc2VydHMgaXRcbiAgICogaW50byB0aGlzIGNvbnRhaW5lci5cbiAgICogQHBhcmFtIHRlbXBsYXRlUmVmIFRoZSBIVE1MIHRlbXBsYXRlIHRoYXQgZGVmaW5lcyB0aGUgdmlldy5cbiAgICogQHBhcmFtIGNvbnRleHQgVGhlIGRhdGEtYmluZGluZyBjb250ZXh0IG9mIHRoZSBlbWJlZGRlZCB2aWV3LCBhcyBkZWNsYXJlZFxuICAgKiBpbiB0aGUgYDxuZy10ZW1wbGF0ZT5gIHVzYWdlLlxuICAgKiBAcGFyYW0gaW5kZXggVGhlIDAtYmFzZWQgaW5kZXggYXQgd2hpY2ggdG8gaW5zZXJ0IHRoZSBuZXcgdmlldyBpbnRvIHRoaXMgY29udGFpbmVyLlxuICAgKiBJZiBub3Qgc3BlY2lmaWVkLCBhcHBlbmRzIHRoZSBuZXcgdmlldyBhcyB0aGUgbGFzdCBlbnRyeS5cbiAgICpcbiAgICogQHJldHVybnMgVGhlIGBWaWV3UmVmYCBpbnN0YW5jZSBmb3IgdGhlIG5ld2x5IGNyZWF0ZWQgdmlldy5cbiAgICovXG4gIGFic3RyYWN0IGNyZWF0ZUVtYmVkZGVkVmlldzxDPih0ZW1wbGF0ZVJlZjogVGVtcGxhdGVSZWY8Qz4sIGNvbnRleHQ/OiBDLCBpbmRleD86IG51bWJlcik6XG4gICAgICBFbWJlZGRlZFZpZXdSZWY8Qz47XG5cbiAgLyoqXG4gICAqIEluc3RhbnRpYXRlcyBhIHNpbmdsZSBjb21wb25lbnQgYW5kIGluc2VydHMgaXRzIGhvc3QgdmlldyBpbnRvIHRoaXMgY29udGFpbmVyLlxuICAgKlxuICAgKiBAcGFyYW0gY29tcG9uZW50VHlwZSBDb21wb25lbnQgVHlwZSB0byB1c2UuXG4gICAqIEBwYXJhbSBvcHRpb25zIEFuIG9iamVjdCB0aGF0IGNvbnRhaW5zIGV4dHJhIHBhcmFtZXRlcnM6XG4gICAqICAqIGluZGV4OiB0aGUgaW5kZXggYXQgd2hpY2ggdG8gaW5zZXJ0IHRoZSBuZXcgY29tcG9uZW50J3MgaG9zdCB2aWV3IGludG8gdGhpcyBjb250YWluZXIuXG4gICAqICAgICAgICAgICBJZiBub3Qgc3BlY2lmaWVkLCBhcHBlbmRzIHRoZSBuZXcgdmlldyBhcyB0aGUgbGFzdCBlbnRyeS5cbiAgICogICogaW5qZWN0b3I6IHRoZSBpbmplY3RvciB0byB1c2UgYXMgdGhlIHBhcmVudCBmb3IgdGhlIG5ldyBjb21wb25lbnQuXG4gICAqICAqIG5nTW9kdWxlUmVmOiBhbiBOZ01vZHVsZVJlZiBvZiB0aGUgY29tcG9uZW50J3MgTmdNb2R1bGUsIHlvdSBzaG91bGQgYWxtb3N0IGFsd2F5cyBwcm92aWRlXG4gICAqICAgICAgICAgICAgICAgICB0aGlzIHRvIGVuc3VyZSB0aGF0IGFsbCBleHBlY3RlZCBwcm92aWRlcnMgYXJlIGF2YWlsYWJsZSBmb3IgdGhlIGNvbXBvbmVudFxuICAgKiAgICAgICAgICAgICAgICAgaW5zdGFudGlhdGlvbi5cbiAgICogICogZW52aXJvbm1lbnRJbmplY3RvcjogYW4gRW52aXJvbm1lbnRJbmplY3RvciB3aGljaCB3aWxsIHByb3ZpZGUgdGhlIGNvbXBvbmVudCdzIGVudmlyb25tZW50LlxuICAgKiAgICAgICAgICAgICAgICAgeW91IHNob3VsZCBhbG1vc3QgYWx3YXlzIHByb3ZpZGUgdGhpcyB0byBlbnN1cmUgdGhhdCBhbGwgZXhwZWN0ZWQgcHJvdmlkZXJzXG4gICAqICAgICAgICAgICAgICAgICBhcmUgYXZhaWxhYmxlIGZvciB0aGUgY29tcG9uZW50IGluc3RhbnRpYXRpb24uIFRoaXMgb3B0aW9uIGlzIGludGVuZGVkIHRvXG4gICAqICAgICAgICAgICAgICAgICByZXBsYWNlIHRoZSBgbmdNb2R1bGVSZWZgIHBhcmFtZXRlci5cbiAgICogICogcHJvamVjdGFibGVOb2RlczogbGlzdCBvZiBET00gbm9kZXMgdGhhdCBzaG91bGQgYmUgcHJvamVjdGVkIHRocm91Z2hcbiAgICogICAgICAgICAgICAgICAgICAgICAgW2A8bmctY29udGVudD5gXShhcGkvY29yZS9uZy1jb250ZW50KSBvZiB0aGUgbmV3IGNvbXBvbmVudCBpbnN0YW5jZS5cbiAgICpcbiAgICogQHJldHVybnMgVGhlIG5ldyBgQ29tcG9uZW50UmVmYCB3aGljaCBjb250YWlucyB0aGUgY29tcG9uZW50IGluc3RhbmNlIGFuZCB0aGUgaG9zdCB2aWV3LlxuICAgKi9cbiAgYWJzdHJhY3QgY3JlYXRlQ29tcG9uZW50PEM+KGNvbXBvbmVudFR5cGU6IFR5cGU8Qz4sIG9wdGlvbnM/OiB7XG4gICAgaW5kZXg/OiBudW1iZXIsXG4gICAgaW5qZWN0b3I/OiBJbmplY3RvcixcbiAgICBuZ01vZHVsZVJlZj86IE5nTW9kdWxlUmVmPHVua25vd24+LFxuICAgIGVudmlyb25tZW50SW5qZWN0b3I/OiBFbnZpcm9ubWVudEluamVjdG9yfE5nTW9kdWxlUmVmPHVua25vd24+LFxuICAgIHByb2plY3RhYmxlTm9kZXM/OiBOb2RlW11bXSxcbiAgfSk6IENvbXBvbmVudFJlZjxDPjtcblxuICAvKipcbiAgICogSW5zdGFudGlhdGVzIGEgc2luZ2xlIGNvbXBvbmVudCBhbmQgaW5zZXJ0cyBpdHMgaG9zdCB2aWV3IGludG8gdGhpcyBjb250YWluZXIuXG4gICAqXG4gICAqIEBwYXJhbSBjb21wb25lbnRGYWN0b3J5IENvbXBvbmVudCBmYWN0b3J5IHRvIHVzZS5cbiAgICogQHBhcmFtIGluZGV4IFRoZSBpbmRleCBhdCB3aGljaCB0byBpbnNlcnQgdGhlIG5ldyBjb21wb25lbnQncyBob3N0IHZpZXcgaW50byB0aGlzIGNvbnRhaW5lci5cbiAgICogSWYgbm90IHNwZWNpZmllZCwgYXBwZW5kcyB0aGUgbmV3IHZpZXcgYXMgdGhlIGxhc3QgZW50cnkuXG4gICAqIEBwYXJhbSBpbmplY3RvciBUaGUgaW5qZWN0b3IgdG8gdXNlIGFzIHRoZSBwYXJlbnQgZm9yIHRoZSBuZXcgY29tcG9uZW50LlxuICAgKiBAcGFyYW0gcHJvamVjdGFibGVOb2RlcyBMaXN0IG9mIERPTSBub2RlcyB0aGF0IHNob3VsZCBiZSBwcm9qZWN0ZWQgdGhyb3VnaFxuICAgKiAgICAgW2A8bmctY29udGVudD5gXShhcGkvY29yZS9uZy1jb250ZW50KSBvZiB0aGUgbmV3IGNvbXBvbmVudCBpbnN0YW5jZS5cbiAgICogQHBhcmFtIG5nTW9kdWxlUmVmIEFuIGluc3RhbmNlIG9mIHRoZSBOZ01vZHVsZVJlZiB0aGF0IHJlcHJlc2VudCBhbiBOZ01vZHVsZS5cbiAgICogVGhpcyBpbmZvcm1hdGlvbiBpcyB1c2VkIHRvIHJldHJpZXZlIGNvcnJlc3BvbmRpbmcgTmdNb2R1bGUgaW5qZWN0b3IuXG4gICAqXG4gICAqIEByZXR1cm5zIFRoZSBuZXcgYENvbXBvbmVudFJlZmAgd2hpY2ggY29udGFpbnMgdGhlIGNvbXBvbmVudCBpbnN0YW5jZSBhbmQgdGhlIGhvc3Qgdmlldy5cbiAgICpcbiAgICogQGRlcHJlY2F0ZWQgQW5ndWxhciBubyBsb25nZXIgcmVxdWlyZXMgY29tcG9uZW50IGZhY3RvcmllcyB0byBkeW5hbWljYWxseSBjcmVhdGUgY29tcG9uZW50cy5cbiAgICogICAgIFVzZSBkaWZmZXJlbnQgc2lnbmF0dXJlIG9mIHRoZSBgY3JlYXRlQ29tcG9uZW50YCBtZXRob2QsIHdoaWNoIGFsbG93cyBwYXNzaW5nXG4gICAqICAgICBDb21wb25lbnQgY2xhc3MgZGlyZWN0bHkuXG4gICAqL1xuICBhYnN0cmFjdCBjcmVhdGVDb21wb25lbnQ8Qz4oXG4gICAgICBjb21wb25lbnRGYWN0b3J5OiBDb21wb25lbnRGYWN0b3J5PEM+LCBpbmRleD86IG51bWJlciwgaW5qZWN0b3I/OiBJbmplY3RvcixcbiAgICAgIHByb2plY3RhYmxlTm9kZXM/OiBhbnlbXVtdLFxuICAgICAgZW52aXJvbm1lbnRJbmplY3Rvcj86IEVudmlyb25tZW50SW5qZWN0b3J8TmdNb2R1bGVSZWY8YW55Pik6IENvbXBvbmVudFJlZjxDPjtcblxuICAvKipcbiAgICogSW5zZXJ0cyBhIHZpZXcgaW50byB0aGlzIGNvbnRhaW5lci5cbiAgICogQHBhcmFtIHZpZXdSZWYgVGhlIHZpZXcgdG8gaW5zZXJ0LlxuICAgKiBAcGFyYW0gaW5kZXggVGhlIDAtYmFzZWQgaW5kZXggYXQgd2hpY2ggdG8gaW5zZXJ0IHRoZSB2aWV3LlxuICAgKiBJZiBub3Qgc3BlY2lmaWVkLCBhcHBlbmRzIHRoZSBuZXcgdmlldyBhcyB0aGUgbGFzdCBlbnRyeS5cbiAgICogQHJldHVybnMgVGhlIGluc2VydGVkIGBWaWV3UmVmYCBpbnN0YW5jZS5cbiAgICpcbiAgICovXG4gIGFic3RyYWN0IGluc2VydCh2aWV3UmVmOiBWaWV3UmVmLCBpbmRleD86IG51bWJlcik6IFZpZXdSZWY7XG5cbiAgLyoqXG4gICAqIE1vdmVzIGEgdmlldyB0byBhIG5ldyBsb2NhdGlvbiBpbiB0aGlzIGNvbnRhaW5lci5cbiAgICogQHBhcmFtIHZpZXdSZWYgVGhlIHZpZXcgdG8gbW92ZS5cbiAgICogQHBhcmFtIGluZGV4IFRoZSAwLWJhc2VkIGluZGV4IG9mIHRoZSBuZXcgbG9jYXRpb24uXG4gICAqIEByZXR1cm5zIFRoZSBtb3ZlZCBgVmlld1JlZmAgaW5zdGFuY2UuXG4gICAqL1xuICBhYnN0cmFjdCBtb3ZlKHZpZXdSZWY6IFZpZXdSZWYsIGN1cnJlbnRJbmRleDogbnVtYmVyKTogVmlld1JlZjtcblxuICAvKipcbiAgICogUmV0dXJucyB0aGUgaW5kZXggb2YgYSB2aWV3IHdpdGhpbiB0aGUgY3VycmVudCBjb250YWluZXIuXG4gICAqIEBwYXJhbSB2aWV3UmVmIFRoZSB2aWV3IHRvIHF1ZXJ5LlxuICAgKiBAcmV0dXJucyBUaGUgMC1iYXNlZCBpbmRleCBvZiB0aGUgdmlldydzIHBvc2l0aW9uIGluIHRoaXMgY29udGFpbmVyLFxuICAgKiBvciBgLTFgIGlmIHRoaXMgY29udGFpbmVyIGRvZXNuJ3QgY29udGFpbiB0aGUgdmlldy5cbiAgICovXG4gIGFic3RyYWN0IGluZGV4T2Yodmlld1JlZjogVmlld1JlZik6IG51bWJlcjtcblxuICAvKipcbiAgICogRGVzdHJveXMgYSB2aWV3IGF0dGFjaGVkIHRvIHRoaXMgY29udGFpbmVyXG4gICAqIEBwYXJhbSBpbmRleCBUaGUgMC1iYXNlZCBpbmRleCBvZiB0aGUgdmlldyB0byBkZXN0cm95LlxuICAgKiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgbGFzdCB2aWV3IGluIHRoZSBjb250YWluZXIgaXMgcmVtb3ZlZC5cbiAgICovXG4gIGFic3RyYWN0IHJlbW92ZShpbmRleD86IG51bWJlcik6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIERldGFjaGVzIGEgdmlldyBmcm9tIHRoaXMgY29udGFpbmVyIHdpdGhvdXQgZGVzdHJveWluZyBpdC5cbiAgICogVXNlIGFsb25nIHdpdGggYGluc2VydCgpYCB0byBtb3ZlIGEgdmlldyB3aXRoaW4gdGhlIGN1cnJlbnQgY29udGFpbmVyLlxuICAgKiBAcGFyYW0gaW5kZXggVGhlIDAtYmFzZWQgaW5kZXggb2YgdGhlIHZpZXcgdG8gZGV0YWNoLlxuICAgKiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgbGFzdCB2aWV3IGluIHRoZSBjb250YWluZXIgaXMgZGV0YWNoZWQuXG4gICAqL1xuICBhYnN0cmFjdCBkZXRhY2goaW5kZXg/OiBudW1iZXIpOiBWaWV3UmVmfG51bGw7XG5cbiAgLyoqXG4gICAqIEBpbnRlcm5hbFxuICAgKiBAbm9jb2xsYXBzZVxuICAgKi9cbiAgc3RhdGljIF9fTkdfRUxFTUVOVF9JRF9fOiAoKSA9PiBWaWV3Q29udGFpbmVyUmVmID0gaW5qZWN0Vmlld0NvbnRhaW5lclJlZjtcbn1cblxuLyoqXG4gKiBDcmVhdGVzIGEgVmlld0NvbnRhaW5lclJlZiBhbmQgc3RvcmVzIGl0IG9uIHRoZSBpbmplY3Rvci4gT3IsIGlmIHRoZSBWaWV3Q29udGFpbmVyUmVmXG4gKiBhbHJlYWR5IGV4aXN0cywgcmV0cmlldmVzIHRoZSBleGlzdGluZyBWaWV3Q29udGFpbmVyUmVmLlxuICpcbiAqIEByZXR1cm5zIFRoZSBWaWV3Q29udGFpbmVyUmVmIGluc3RhbmNlIHRvIHVzZVxuICovXG5leHBvcnQgZnVuY3Rpb24gaW5qZWN0Vmlld0NvbnRhaW5lclJlZigpOiBWaWV3Q29udGFpbmVyUmVmIHtcbiAgY29uc3QgcHJldmlvdXNUTm9kZSA9IGdldEN1cnJlbnRUTm9kZSgpIGFzIFRFbGVtZW50Tm9kZSB8IFRFbGVtZW50Q29udGFpbmVyTm9kZSB8IFRDb250YWluZXJOb2RlO1xuICByZXR1cm4gY3JlYXRlQ29udGFpbmVyUmVmKHByZXZpb3VzVE5vZGUsIGdldExWaWV3KCkpO1xufVxuXG5jb25zdCBWRV9WaWV3Q29udGFpbmVyUmVmID0gVmlld0NvbnRhaW5lclJlZjtcblxuLy8gVE9ETyhhbHhodWIpOiBjbGVhbmluZyB1cCB0aGlzIGluZGlyZWN0aW9uIHRyaWdnZXJzIGEgc3VidGxlIGJ1ZyBpbiBDbG9zdXJlIGluIGczLiBPbmNlIHRoZSBmaXhcbi8vIGZvciB0aGF0IGxhbmRzLCB0aGlzIGNhbiBiZSBjbGVhbmVkIHVwLlxuY29uc3QgUjNWaWV3Q29udGFpbmVyUmVmID0gY2xhc3MgVmlld0NvbnRhaW5lclJlZiBleHRlbmRzIFZFX1ZpZXdDb250YWluZXJSZWYge1xuICBjb25zdHJ1Y3RvcihcbiAgICAgIHByaXZhdGUgX2xDb250YWluZXI6IExDb250YWluZXIsXG4gICAgICBwcml2YXRlIF9ob3N0VE5vZGU6IFRFbGVtZW50Tm9kZXxUQ29udGFpbmVyTm9kZXxURWxlbWVudENvbnRhaW5lck5vZGUsXG4gICAgICBwcml2YXRlIF9ob3N0TFZpZXc6IExWaWV3KSB7XG4gICAgc3VwZXIoKTtcbiAgfVxuXG4gIG92ZXJyaWRlIGdldCBlbGVtZW50KCk6IEVsZW1lbnRSZWYge1xuICAgIHJldHVybiBjcmVhdGVFbGVtZW50UmVmKHRoaXMuX2hvc3RUTm9kZSwgdGhpcy5faG9zdExWaWV3KTtcbiAgfVxuXG4gIG92ZXJyaWRlIGdldCBpbmplY3RvcigpOiBJbmplY3RvciB7XG4gICAgcmV0dXJuIG5ldyBOb2RlSW5qZWN0b3IodGhpcy5faG9zdFROb2RlLCB0aGlzLl9ob3N0TFZpZXcpO1xuICB9XG5cbiAgLyoqIEBkZXByZWNhdGVkIE5vIHJlcGxhY2VtZW50ICovXG4gIG92ZXJyaWRlIGdldCBwYXJlbnRJbmplY3RvcigpOiBJbmplY3RvciB7XG4gICAgY29uc3QgcGFyZW50TG9jYXRpb24gPSBnZXRQYXJlbnRJbmplY3RvckxvY2F0aW9uKHRoaXMuX2hvc3RUTm9kZSwgdGhpcy5faG9zdExWaWV3KTtcbiAgICBpZiAoaGFzUGFyZW50SW5qZWN0b3IocGFyZW50TG9jYXRpb24pKSB7XG4gICAgICBjb25zdCBwYXJlbnRWaWV3ID0gZ2V0UGFyZW50SW5qZWN0b3JWaWV3KHBhcmVudExvY2F0aW9uLCB0aGlzLl9ob3N0TFZpZXcpO1xuICAgICAgY29uc3QgaW5qZWN0b3JJbmRleCA9IGdldFBhcmVudEluamVjdG9ySW5kZXgocGFyZW50TG9jYXRpb24pO1xuICAgICAgbmdEZXZNb2RlICYmIGFzc2VydE5vZGVJbmplY3RvcihwYXJlbnRWaWV3LCBpbmplY3RvckluZGV4KTtcbiAgICAgIGNvbnN0IHBhcmVudFROb2RlID1cbiAgICAgICAgICBwYXJlbnRWaWV3W1RWSUVXXS5kYXRhW2luamVjdG9ySW5kZXggKyBOb2RlSW5qZWN0b3JPZmZzZXQuVE5PREVdIGFzIFRFbGVtZW50Tm9kZTtcbiAgICAgIHJldHVybiBuZXcgTm9kZUluamVjdG9yKHBhcmVudFROb2RlLCBwYXJlbnRWaWV3KTtcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIG5ldyBOb2RlSW5qZWN0b3IobnVsbCwgdGhpcy5faG9zdExWaWV3KTtcbiAgICB9XG4gIH1cblxuICBvdmVycmlkZSBjbGVhcigpOiB2b2lkIHtcbiAgICB3aGlsZSAodGhpcy5sZW5ndGggPiAwKSB7XG4gICAgICB0aGlzLnJlbW92ZSh0aGlzLmxlbmd0aCAtIDEpO1xuICAgIH1cbiAgfVxuXG4gIG92ZXJyaWRlIGdldChpbmRleDogbnVtYmVyKTogVmlld1JlZnxudWxsIHtcbiAgICBjb25zdCB2aWV3UmVmcyA9IGdldFZpZXdSZWZzKHRoaXMuX2xDb250YWluZXIpO1xuICAgIHJldHVybiB2aWV3UmVmcyAhPT0gbnVsbCAmJiB2aWV3UmVmc1tpbmRleF0gfHwgbnVsbDtcbiAgfVxuXG4gIG92ZXJyaWRlIGdldCBsZW5ndGgoKTogbnVtYmVyIHtcbiAgICByZXR1cm4gdGhpcy5fbENvbnRhaW5lci5sZW5ndGggLSBDT05UQUlORVJfSEVBREVSX09GRlNFVDtcbiAgfVxuXG4gIG92ZXJyaWRlIGNyZWF0ZUVtYmVkZGVkVmlldzxDPih0ZW1wbGF0ZVJlZjogVGVtcGxhdGVSZWY8Qz4sIGNvbnRleHQ/OiBDLCBvcHRpb25zPzoge1xuICAgIGluZGV4PzogbnVtYmVyLFxuICAgIGluamVjdG9yPzogSW5qZWN0b3JcbiAgfSk6IEVtYmVkZGVkVmlld1JlZjxDPjtcbiAgb3ZlcnJpZGUgY3JlYXRlRW1iZWRkZWRWaWV3PEM+KHRlbXBsYXRlUmVmOiBUZW1wbGF0ZVJlZjxDPiwgY29udGV4dD86IEMsIGluZGV4PzogbnVtYmVyKTpcbiAgICAgIEVtYmVkZGVkVmlld1JlZjxDPjtcbiAgb3ZlcnJpZGUgY3JlYXRlRW1iZWRkZWRWaWV3PEM+KHRlbXBsYXRlUmVmOiBUZW1wbGF0ZVJlZjxDPiwgY29udGV4dD86IEMsIGluZGV4T3JPcHRpb25zPzogbnVtYmVyfHtcbiAgICBpbmRleD86IG51bWJlcixcbiAgICBpbmplY3Rvcj86IEluamVjdG9yXG4gIH0pOiBFbWJlZGRlZFZpZXdSZWY8Qz4ge1xuICAgIGxldCBpbmRleDogbnVtYmVyfHVuZGVmaW5lZDtcbiAgICBsZXQgaW5qZWN0b3I6IEluamVjdG9yfHVuZGVmaW5lZDtcblxuICAgIGlmICh0eXBlb2YgaW5kZXhPck9wdGlvbnMgPT09ICdudW1iZXInKSB7XG4gICAgICBpbmRleCA9IGluZGV4T3JPcHRpb25zO1xuICAgIH0gZWxzZSBpZiAoaW5kZXhPck9wdGlvbnMgIT0gbnVsbCkge1xuICAgICAgaW5kZXggPSBpbmRleE9yT3B0aW9ucy5pbmRleDtcbiAgICAgIGluamVjdG9yID0gaW5kZXhPck9wdGlvbnMuaW5qZWN0b3I7XG4gICAgfVxuXG4gICAgY29uc3QgaHlkcmF0aW9uSW5mbyA9IGZpbmRNYXRjaGluZ0RlaHlkcmF0ZWRWaWV3KHRoaXMuX2xDb250YWluZXIsIHRlbXBsYXRlUmVmLnNzcklkKTtcbiAgICBjb25zdCB2aWV3UmVmID0gdGVtcGxhdGVSZWYuY3JlYXRlRW1iZWRkZWRWaWV3SW1wbChjb250ZXh0IHx8IDxhbnk+e30sIGluamVjdG9yLCBoeWRyYXRpb25JbmZvKTtcbiAgICB0aGlzLmluc2VydEltcGwodmlld1JlZiwgaW5kZXgsICEhaHlkcmF0aW9uSW5mbyk7XG4gICAgcmV0dXJuIHZpZXdSZWY7XG4gIH1cblxuICBvdmVycmlkZSBjcmVhdGVDb21wb25lbnQ8Qz4oY29tcG9uZW50VHlwZTogVHlwZTxDPiwgb3B0aW9ucz86IHtcbiAgICBpbmRleD86IG51bWJlcixcbiAgICBpbmplY3Rvcj86IEluamVjdG9yLFxuICAgIHByb2plY3RhYmxlTm9kZXM/OiBOb2RlW11bXSxcbiAgICBuZ01vZHVsZVJlZj86IE5nTW9kdWxlUmVmPHVua25vd24+LFxuICB9KTogQ29tcG9uZW50UmVmPEM+O1xuICAvKipcbiAgICogQGRlcHJlY2F0ZWQgQW5ndWxhciBubyBsb25nZXIgcmVxdWlyZXMgY29tcG9uZW50IGZhY3RvcmllcyB0byBkeW5hbWljYWxseSBjcmVhdGUgY29tcG9uZW50cy5cbiAgICogICAgIFVzZSBkaWZmZXJlbnQgc2lnbmF0dXJlIG9mIHRoZSBgY3JlYXRlQ29tcG9uZW50YCBtZXRob2QsIHdoaWNoIGFsbG93cyBwYXNzaW5nXG4gICAqICAgICBDb21wb25lbnQgY2xhc3MgZGlyZWN0bHkuXG4gICAqL1xuICBvdmVycmlkZSBjcmVhdGVDb21wb25lbnQ8Qz4oXG4gICAgICBjb21wb25lbnRGYWN0b3J5OiBDb21wb25lbnRGYWN0b3J5PEM+LCBpbmRleD86IG51bWJlcnx1bmRlZmluZWQsXG4gICAgICBpbmplY3Rvcj86IEluamVjdG9yfHVuZGVmaW5lZCwgcHJvamVjdGFibGVOb2Rlcz86IGFueVtdW118dW5kZWZpbmVkLFxuICAgICAgZW52aXJvbm1lbnRJbmplY3Rvcj86IEVudmlyb25tZW50SW5qZWN0b3J8TmdNb2R1bGVSZWY8YW55Pnx1bmRlZmluZWQpOiBDb21wb25lbnRSZWY8Qz47XG4gIG92ZXJyaWRlIGNyZWF0ZUNvbXBvbmVudDxDPihcbiAgICAgIGNvbXBvbmVudEZhY3RvcnlPclR5cGU6IENvbXBvbmVudEZhY3Rvcnk8Qz58VHlwZTxDPiwgaW5kZXhPck9wdGlvbnM/OiBudW1iZXJ8dW5kZWZpbmVkfHtcbiAgICAgICAgaW5kZXg/OiBudW1iZXIsXG4gICAgICAgIGluamVjdG9yPzogSW5qZWN0b3IsXG4gICAgICAgIG5nTW9kdWxlUmVmPzogTmdNb2R1bGVSZWY8dW5rbm93bj4sXG4gICAgICAgIGVudmlyb25tZW50SW5qZWN0b3I/OiBFbnZpcm9ubWVudEluamVjdG9yfE5nTW9kdWxlUmVmPHVua25vd24+LFxuICAgICAgICBwcm9qZWN0YWJsZU5vZGVzPzogTm9kZVtdW10sXG4gICAgICB9LFxuICAgICAgaW5qZWN0b3I/OiBJbmplY3Rvcnx1bmRlZmluZWQsIHByb2plY3RhYmxlTm9kZXM/OiBhbnlbXVtdfHVuZGVmaW5lZCxcbiAgICAgIGVudmlyb25tZW50SW5qZWN0b3I/OiBFbnZpcm9ubWVudEluamVjdG9yfE5nTW9kdWxlUmVmPGFueT58dW5kZWZpbmVkKTogQ29tcG9uZW50UmVmPEM+IHtcbiAgICBjb25zdCBpc0NvbXBvbmVudEZhY3RvcnkgPSBjb21wb25lbnRGYWN0b3J5T3JUeXBlICYmICFpc1R5cGUoY29tcG9uZW50RmFjdG9yeU9yVHlwZSk7XG4gICAgbGV0IGluZGV4OiBudW1iZXJ8dW5kZWZpbmVkO1xuXG4gICAgLy8gVGhpcyBmdW5jdGlvbiBzdXBwb3J0cyAyIHNpZ25hdHVyZXMgYW5kIHdlIG5lZWQgdG8gaGFuZGxlIG9wdGlvbnMgY29ycmVjdGx5IGZvciBib3RoOlxuICAgIC8vICAgMS4gV2hlbiBmaXJzdCBhcmd1bWVudCBpcyBhIENvbXBvbmVudCB0eXBlLiBUaGlzIHNpZ25hdHVyZSBhbHNvIHJlcXVpcmVzIGV4dHJhXG4gICAgLy8gICAgICBvcHRpb25zIHRvIGJlIHByb3ZpZGVkIGFzIGFzIG9iamVjdCAobW9yZSBlcmdvbm9taWMgb3B0aW9uKS5cbiAgICAvLyAgIDIuIEZpcnN0IGFyZ3VtZW50IGlzIGEgQ29tcG9uZW50IGZhY3RvcnkuIEluIHRoaXMgY2FzZSBleHRyYSBvcHRpb25zIGFyZSByZXByZXNlbnRlZCBhc1xuICAgIC8vICAgICAgcG9zaXRpb25hbCBhcmd1bWVudHMuIFRoaXMgc2lnbmF0dXJlIGlzIGxlc3MgZXJnb25vbWljIGFuZCB3aWxsIGJlIGRlcHJlY2F0ZWQuXG4gICAgaWYgKGlzQ29tcG9uZW50RmFjdG9yeSkge1xuICAgICAgaWYgKG5nRGV2TW9kZSkge1xuICAgICAgICBhc3NlcnRFcXVhbChcbiAgICAgICAgICAgIHR5cGVvZiBpbmRleE9yT3B0aW9ucyAhPT0gJ29iamVjdCcsIHRydWUsXG4gICAgICAgICAgICAnSXQgbG9va3MgbGlrZSBDb21wb25lbnQgZmFjdG9yeSB3YXMgcHJvdmlkZWQgYXMgdGhlIGZpcnN0IGFyZ3VtZW50ICcgK1xuICAgICAgICAgICAgICAgICdhbmQgYW4gb3B0aW9ucyBvYmplY3QgYXMgdGhlIHNlY29uZCBhcmd1bWVudC4gVGhpcyBjb21iaW5hdGlvbiBvZiBhcmd1bWVudHMgJyArXG4gICAgICAgICAgICAgICAgJ2lzIGluY29tcGF0aWJsZS4gWW91IGNhbiBlaXRoZXIgY2hhbmdlIHRoZSBmaXJzdCBhcmd1bWVudCB0byBwcm92aWRlIENvbXBvbmVudCAnICtcbiAgICAgICAgICAgICAgICAndHlwZSBvciBjaGFuZ2UgdGhlIHNlY29uZCBhcmd1bWVudCB0byBiZSBhIG51bWJlciAocmVwcmVzZW50aW5nIGFuIGluZGV4IGF0ICcgK1xuICAgICAgICAgICAgICAgICd3aGljaCB0byBpbnNlcnQgdGhlIG5ldyBjb21wb25lbnRcXCdzIGhvc3QgdmlldyBpbnRvIHRoaXMgY29udGFpbmVyKScpO1xuICAgICAgfVxuICAgICAgaW5kZXggPSBpbmRleE9yT3B0aW9ucyBhcyBudW1iZXIgfCB1bmRlZmluZWQ7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAgICAgYXNzZXJ0RGVmaW5lZChcbiAgICAgICAgICAgIGdldENvbXBvbmVudERlZihjb21wb25lbnRGYWN0b3J5T3JUeXBlKSxcbiAgICAgICAgICAgIGBQcm92aWRlZCBDb21wb25lbnQgY2xhc3MgZG9lc24ndCBjb250YWluIENvbXBvbmVudCBkZWZpbml0aW9uLiBgICtcbiAgICAgICAgICAgICAgICBgUGxlYXNlIGNoZWNrIHdoZXRoZXIgcHJvdmlkZWQgY2xhc3MgaGFzIEBDb21wb25lbnQgZGVjb3JhdG9yLmApO1xuICAgICAgICBhc3NlcnRFcXVhbChcbiAgICAgICAgICAgIHR5cGVvZiBpbmRleE9yT3B0aW9ucyAhPT0gJ251bWJlcicsIHRydWUsXG4gICAgICAgICAgICAnSXQgbG9va3MgbGlrZSBDb21wb25lbnQgdHlwZSB3YXMgcHJvdmlkZWQgYXMgdGhlIGZpcnN0IGFyZ3VtZW50ICcgK1xuICAgICAgICAgICAgICAgICdhbmQgYSBudW1iZXIgKHJlcHJlc2VudGluZyBhbiBpbmRleCBhdCB3aGljaCB0byBpbnNlcnQgdGhlIG5ldyBjb21wb25lbnRcXCdzICcgK1xuICAgICAgICAgICAgICAgICdob3N0IHZpZXcgaW50byB0aGlzIGNvbnRhaW5lciBhcyB0aGUgc2Vjb25kIGFyZ3VtZW50LiBUaGlzIGNvbWJpbmF0aW9uIG9mIGFyZ3VtZW50cyAnICtcbiAgICAgICAgICAgICAgICAnaXMgaW5jb21wYXRpYmxlLiBQbGVhc2UgdXNlIGFuIG9iamVjdCBhcyB0aGUgc2Vjb25kIGFyZ3VtZW50IGluc3RlYWQuJyk7XG4gICAgICB9XG4gICAgICBjb25zdCBvcHRpb25zID0gKGluZGV4T3JPcHRpb25zIHx8IHt9KSBhcyB7XG4gICAgICAgIGluZGV4PzogbnVtYmVyLFxuICAgICAgICBpbmplY3Rvcj86IEluamVjdG9yLFxuICAgICAgICBuZ01vZHVsZVJlZj86IE5nTW9kdWxlUmVmPHVua25vd24+LFxuICAgICAgICBlbnZpcm9ubWVudEluamVjdG9yPzogRW52aXJvbm1lbnRJbmplY3RvciB8IE5nTW9kdWxlUmVmPHVua25vd24+LFxuICAgICAgICBwcm9qZWN0YWJsZU5vZGVzPzogTm9kZVtdW10sXG4gICAgICB9O1xuICAgICAgaWYgKG5nRGV2TW9kZSAmJiBvcHRpb25zLmVudmlyb25tZW50SW5qZWN0b3IgJiYgb3B0aW9ucy5uZ01vZHVsZVJlZikge1xuICAgICAgICB0aHJvd0Vycm9yKFxuICAgICAgICAgICAgYENhbm5vdCBwYXNzIGJvdGggZW52aXJvbm1lbnRJbmplY3RvciBhbmQgbmdNb2R1bGVSZWYgb3B0aW9ucyB0byBjcmVhdGVDb21wb25lbnQoKS5gKTtcbiAgICAgIH1cbiAgICAgIGluZGV4ID0gb3B0aW9ucy5pbmRleDtcbiAgICAgIGluamVjdG9yID0gb3B0aW9ucy5pbmplY3RvcjtcbiAgICAgIHByb2plY3RhYmxlTm9kZXMgPSBvcHRpb25zLnByb2plY3RhYmxlTm9kZXM7XG4gICAgICBlbnZpcm9ubWVudEluamVjdG9yID0gb3B0aW9ucy5lbnZpcm9ubWVudEluamVjdG9yIHx8IG9wdGlvbnMubmdNb2R1bGVSZWY7XG4gICAgfVxuXG4gICAgY29uc3QgY29tcG9uZW50RmFjdG9yeTogQ29tcG9uZW50RmFjdG9yeTxDPiA9IGlzQ29tcG9uZW50RmFjdG9yeSA/XG4gICAgICAgIGNvbXBvbmVudEZhY3RvcnlPclR5cGUgYXMgQ29tcG9uZW50RmFjdG9yeTxDPjpcbiAgICAgICAgbmV3IFIzQ29tcG9uZW50RmFjdG9yeShnZXRDb21wb25lbnREZWYoY29tcG9uZW50RmFjdG9yeU9yVHlwZSkhKTtcbiAgICBjb25zdCBjb250ZXh0SW5qZWN0b3IgPSBpbmplY3RvciB8fCB0aGlzLnBhcmVudEluamVjdG9yO1xuXG4gICAgLy8gSWYgYW4gYE5nTW9kdWxlUmVmYCBpcyBub3QgcHJvdmlkZWQgZXhwbGljaXRseSwgdHJ5IHJldHJpZXZpbmcgaXQgZnJvbSB0aGUgREkgdHJlZS5cbiAgICBpZiAoIWVudmlyb25tZW50SW5qZWN0b3IgJiYgKGNvbXBvbmVudEZhY3RvcnkgYXMgYW55KS5uZ01vZHVsZSA9PSBudWxsKSB7XG4gICAgICAvLyBGb3IgdGhlIGBDb21wb25lbnRGYWN0b3J5YCBjYXNlLCBlbnRlcmluZyB0aGlzIGxvZ2ljIGlzIHZlcnkgdW5saWtlbHksIHNpbmNlIHdlIGV4cGVjdCB0aGF0XG4gICAgICAvLyBhbiBpbnN0YW5jZSBvZiBhIGBDb21wb25lbnRGYWN0b3J5YCwgcmVzb2x2ZWQgdmlhIGBDb21wb25lbnRGYWN0b3J5UmVzb2x2ZXJgIHdvdWxkIGhhdmUgYW5cbiAgICAgIC8vIGBuZ01vZHVsZWAgZmllbGQuIFRoaXMgaXMgcG9zc2libGUgaW4gc29tZSB0ZXN0IHNjZW5hcmlvcyBhbmQgcG90ZW50aWFsbHkgaW4gc29tZSBKSVQtYmFzZWRcbiAgICAgIC8vIHVzZS1jYXNlcy4gRm9yIHRoZSBgQ29tcG9uZW50RmFjdG9yeWAgY2FzZSB3ZSBwcmVzZXJ2ZSBiYWNrd2FyZHMtY29tcGF0aWJpbGl0eSBhbmQgdHJ5XG4gICAgICAvLyB1c2luZyBhIHByb3ZpZGVkIGluamVjdG9yIGZpcnN0LCB0aGVuIGZhbGwgYmFjayB0byB0aGUgcGFyZW50IGluamVjdG9yIG9mIHRoaXNcbiAgICAgIC8vIGBWaWV3Q29udGFpbmVyUmVmYCBpbnN0YW5jZS5cbiAgICAgIC8vXG4gICAgICAvLyBGb3IgdGhlIGZhY3RvcnktbGVzcyBjYXNlLCBpdCdzIGNyaXRpY2FsIHRvIGVzdGFibGlzaCBhIGNvbm5lY3Rpb24gd2l0aCB0aGUgbW9kdWxlXG4gICAgICAvLyBpbmplY3RvciB0cmVlIChieSByZXRyaWV2aW5nIGFuIGluc3RhbmNlIG9mIGFuIGBOZ01vZHVsZVJlZmAgYW5kIGFjY2Vzc2luZyBpdHMgaW5qZWN0b3IpLFxuICAgICAgLy8gc28gdGhhdCBhIGNvbXBvbmVudCBjYW4gdXNlIERJIHRva2VucyBwcm92aWRlZCBpbiBNZ01vZHVsZXMuIEZvciB0aGlzIHJlYXNvbiwgd2UgY2FuIG5vdFxuICAgICAgLy8gcmVseSBvbiB0aGUgcHJvdmlkZWQgaW5qZWN0b3IsIHNpbmNlIGl0IG1pZ2h0IGJlIGRldGFjaGVkIGZyb20gdGhlIERJIHRyZWUgKGZvciBleGFtcGxlLCBpZlxuICAgICAgLy8gaXQgd2FzIGNyZWF0ZWQgdmlhIGBJbmplY3Rvci5jcmVhdGVgIHdpdGhvdXQgc3BlY2lmeWluZyBhIHBhcmVudCBpbmplY3Rvciwgb3IgaWYgYW5cbiAgICAgIC8vIGluamVjdG9yIGlzIHJldHJpZXZlZCBmcm9tIGFuIGBOZ01vZHVsZVJlZmAgY3JlYXRlZCB2aWEgYGNyZWF0ZU5nTW9kdWxlYCB1c2luZyBhblxuICAgICAgLy8gTmdNb2R1bGUgb3V0c2lkZSBvZiBhIG1vZHVsZSB0cmVlKS4gSW5zdGVhZCwgd2UgYWx3YXlzIHVzZSBgVmlld0NvbnRhaW5lclJlZmAncyBwYXJlbnRcbiAgICAgIC8vIGluamVjdG9yLCB3aGljaCBpcyBub3JtYWxseSBjb25uZWN0ZWQgdG8gdGhlIERJIHRyZWUsIHdoaWNoIGluY2x1ZGVzIG1vZHVsZSBpbmplY3RvclxuICAgICAgLy8gc3VidHJlZS5cbiAgICAgIGNvbnN0IF9pbmplY3RvciA9IGlzQ29tcG9uZW50RmFjdG9yeSA/IGNvbnRleHRJbmplY3RvciA6IHRoaXMucGFyZW50SW5qZWN0b3I7XG5cbiAgICAgIC8vIERPIE5PVCBSRUZBQ1RPUi4gVGhlIGNvZGUgaGVyZSB1c2VkIHRvIGhhdmUgYSBgaW5qZWN0b3IuZ2V0KE5nTW9kdWxlUmVmLCBudWxsKSB8fFxuICAgICAgLy8gdW5kZWZpbmVkYCBleHByZXNzaW9uIHdoaWNoIHNlZW1zIHRvIGNhdXNlIGludGVybmFsIGdvb2dsZSBhcHBzIHRvIGZhaWwuIFRoaXMgaXMgZG9jdW1lbnRlZFxuICAgICAgLy8gaW4gdGhlIGZvbGxvd2luZyBpbnRlcm5hbCBidWcgaXNzdWU6IGdvL2IvMTQyOTY3ODAyXG4gICAgICBjb25zdCByZXN1bHQgPSBfaW5qZWN0b3IuZ2V0KEVudmlyb25tZW50SW5qZWN0b3IsIG51bGwpO1xuICAgICAgaWYgKHJlc3VsdCkge1xuICAgICAgICBlbnZpcm9ubWVudEluamVjdG9yID0gcmVzdWx0O1xuICAgICAgfVxuICAgIH1cblxuICAgIGNvbnN0IGNvbXBvbmVudERlZiA9IGdldENvbXBvbmVudERlZihjb21wb25lbnRGYWN0b3J5LmNvbXBvbmVudFR5cGUgPz8ge30pO1xuICAgIGNvbnN0IGRlaHlkcmF0ZWRWaWV3ID0gZmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXcodGhpcy5fbENvbnRhaW5lciwgY29tcG9uZW50RGVmPy5pZCA/PyBudWxsKTtcbiAgICBjb25zdCByTm9kZSA9IGRlaHlkcmF0ZWRWaWV3Py5maXJzdENoaWxkID8/IG51bGw7XG4gICAgY29uc3QgY29tcG9uZW50UmVmID1cbiAgICAgICAgY29tcG9uZW50RmFjdG9yeS5jcmVhdGUoY29udGV4dEluamVjdG9yLCBwcm9qZWN0YWJsZU5vZGVzLCByTm9kZSwgZW52aXJvbm1lbnRJbmplY3Rvcik7XG4gICAgdGhpcy5pbnNlcnRJbXBsKGNvbXBvbmVudFJlZi5ob3N0VmlldywgaW5kZXgsICEhZGVoeWRyYXRlZFZpZXcpO1xuICAgIHJldHVybiBjb21wb25lbnRSZWY7XG4gIH1cblxuICBvdmVycmlkZSBpbnNlcnQodmlld1JlZjogVmlld1JlZiwgaW5kZXg/OiBudW1iZXIpOiBWaWV3UmVmIHtcbiAgICByZXR1cm4gdGhpcy5pbnNlcnRJbXBsKHZpZXdSZWYsIGluZGV4LCBmYWxzZSk7XG4gIH1cblxuICBwcml2YXRlIGluc2VydEltcGwodmlld1JlZjogVmlld1JlZiwgaW5kZXg/OiBudW1iZXIsIHNraXBEb21JbnNlcnRpb24/OiBib29sZWFuKTogVmlld1JlZiB7XG4gICAgY29uc3QgbFZpZXcgPSAodmlld1JlZiBhcyBSM1ZpZXdSZWY8YW55PikuX2xWaWV3ITtcbiAgICBjb25zdCB0VmlldyA9IGxWaWV3W1RWSUVXXTtcblxuICAgIGlmIChuZ0Rldk1vZGUgJiYgdmlld1JlZi5kZXN0cm95ZWQpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcignQ2Fubm90IGluc2VydCBhIGRlc3Ryb3llZCBWaWV3IGluIGEgVmlld0NvbnRhaW5lciEnKTtcbiAgICB9XG5cbiAgICBpZiAodmlld0F0dGFjaGVkVG9Db250YWluZXIobFZpZXcpKSB7XG4gICAgICAvLyBJZiB2aWV3IGlzIGFscmVhZHkgYXR0YWNoZWQsIGRldGFjaCBpdCBmaXJzdCBzbyB3ZSBjbGVhbiB1cCByZWZlcmVuY2VzIGFwcHJvcHJpYXRlbHkuXG5cbiAgICAgIGNvbnN0IHByZXZJZHggPSB0aGlzLmluZGV4T2Yodmlld1JlZik7XG5cbiAgICAgIC8vIEEgdmlldyBtaWdodCBiZSBhdHRhY2hlZCBlaXRoZXIgdG8gdGhpcyBvciBhIGRpZmZlcmVudCBjb250YWluZXIuIFRoZSBgcHJldklkeGAgZm9yXG4gICAgICAvLyB0aG9zZSBjYXNlcyB3aWxsIGJlOlxuICAgICAgLy8gZXF1YWwgdG8gLTEgZm9yIHZpZXdzIGF0dGFjaGVkIHRvIHRoaXMgVmlld0NvbnRhaW5lclJlZlxuICAgICAgLy8gPj0gMCBmb3Igdmlld3MgYXR0YWNoZWQgdG8gYSBkaWZmZXJlbnQgVmlld0NvbnRhaW5lclJlZlxuICAgICAgaWYgKHByZXZJZHggIT09IC0xKSB7XG4gICAgICAgIHRoaXMuZGV0YWNoKHByZXZJZHgpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY29uc3QgcHJldkxDb250YWluZXIgPSBsVmlld1tQQVJFTlRdIGFzIExDb250YWluZXI7XG4gICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgYXNzZXJ0RXF1YWwoXG4gICAgICAgICAgICAgICAgaXNMQ29udGFpbmVyKHByZXZMQ29udGFpbmVyKSwgdHJ1ZSxcbiAgICAgICAgICAgICAgICAnQW4gYXR0YWNoZWQgdmlldyBzaG91bGQgaGF2ZSBpdHMgUEFSRU5UIHBvaW50IHRvIGEgY29udGFpbmVyLicpO1xuXG5cbiAgICAgICAgLy8gV2UgbmVlZCB0byByZS1jcmVhdGUgYSBSM1ZpZXdDb250YWluZXJSZWYgaW5zdGFuY2Ugc2luY2UgdGhvc2UgYXJlIG5vdCBzdG9yZWQgb25cbiAgICAgICAgLy8gTFZpZXcgKG5vciBhbnl3aGVyZSBlbHNlKS5cbiAgICAgICAgY29uc3QgcHJldlZDUmVmID0gbmV3IFIzVmlld0NvbnRhaW5lclJlZihcbiAgICAgICAgICAgIHByZXZMQ29udGFpbmVyLCBwcmV2TENvbnRhaW5lcltUX0hPU1RdIGFzIFREaXJlY3RpdmVIb3N0Tm9kZSwgcHJldkxDb250YWluZXJbUEFSRU5UXSk7XG5cbiAgICAgICAgcHJldlZDUmVmLmRldGFjaChwcmV2VkNSZWYuaW5kZXhPZih2aWV3UmVmKSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgLy8gTG9naWNhbCBvcGVyYXRpb24gb2YgYWRkaW5nIGBMVmlld2AgdG8gYExDb250YWluZXJgXG4gICAgY29uc3QgYWRqdXN0ZWRJZHggPSB0aGlzLl9hZGp1c3RJbmRleChpbmRleCk7XG4gICAgY29uc3QgbENvbnRhaW5lciA9IHRoaXMuX2xDb250YWluZXI7XG4gICAgaW5zZXJ0Vmlldyh0VmlldywgbFZpZXcsIGxDb250YWluZXIsIGFkanVzdGVkSWR4KTtcblxuICAgIC8vIFBoeXNpY2FsIG9wZXJhdGlvbiBvZiBhZGRpbmcgdGhlIERPTSBub2Rlcy5cbiAgICBpZiAoIXNraXBEb21JbnNlcnRpb24pIHtcbiAgICAgIGNvbnN0IGJlZm9yZU5vZGUgPSBnZXRCZWZvcmVOb2RlRm9yVmlldyhhZGp1c3RlZElkeCwgbENvbnRhaW5lcik7XG4gICAgICBjb25zdCByZW5kZXJlciA9IGxWaWV3W1JFTkRFUkVSXTtcbiAgICAgIGNvbnN0IHBhcmVudFJOb2RlID0gbmF0aXZlUGFyZW50Tm9kZShyZW5kZXJlciwgbENvbnRhaW5lcltOQVRJVkVdIGFzIFJFbGVtZW50IHwgUkNvbW1lbnQpO1xuICAgICAgaWYgKHBhcmVudFJOb2RlICE9PSBudWxsKSB7XG4gICAgICAgIGFkZFZpZXdUb0NvbnRhaW5lcih0VmlldywgbENvbnRhaW5lcltUX0hPU1RdLCByZW5kZXJlciwgbFZpZXcsIHBhcmVudFJOb2RlLCBiZWZvcmVOb2RlKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAodmlld1JlZiBhcyBSM1ZpZXdSZWY8YW55PikuYXR0YWNoVG9WaWV3Q29udGFpbmVyUmVmKCk7XG4gICAgYWRkVG9BcnJheShnZXRPckNyZWF0ZVZpZXdSZWZzKGxDb250YWluZXIpLCBhZGp1c3RlZElkeCwgdmlld1JlZik7XG5cbiAgICByZXR1cm4gdmlld1JlZjtcbiAgfVxuXG4gIG92ZXJyaWRlIG1vdmUodmlld1JlZjogVmlld1JlZiwgbmV3SW5kZXg6IG51bWJlcik6IFZpZXdSZWYge1xuICAgIGlmIChuZ0Rldk1vZGUgJiYgdmlld1JlZi5kZXN0cm95ZWQpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcignQ2Fubm90IG1vdmUgYSBkZXN0cm95ZWQgVmlldyBpbiBhIFZpZXdDb250YWluZXIhJyk7XG4gICAgfVxuICAgIHJldHVybiB0aGlzLmluc2VydCh2aWV3UmVmLCBuZXdJbmRleCk7XG4gIH1cblxuICBvdmVycmlkZSBpbmRleE9mKHZpZXdSZWY6IFZpZXdSZWYpOiBudW1iZXIge1xuICAgIGNvbnN0IHZpZXdSZWZzQXJyID0gZ2V0Vmlld1JlZnModGhpcy5fbENvbnRhaW5lcik7XG4gICAgcmV0dXJuIHZpZXdSZWZzQXJyICE9PSBudWxsID8gdmlld1JlZnNBcnIuaW5kZXhPZih2aWV3UmVmKSA6IC0xO1xuICB9XG5cbiAgb3ZlcnJpZGUgcmVtb3ZlKGluZGV4PzogbnVtYmVyKTogdm9pZCB7XG4gICAgY29uc3QgYWRqdXN0ZWRJZHggPSB0aGlzLl9hZGp1c3RJbmRleChpbmRleCwgLTEpO1xuICAgIGNvbnN0IGRldGFjaGVkVmlldyA9IGRldGFjaFZpZXcodGhpcy5fbENvbnRhaW5lciwgYWRqdXN0ZWRJZHgpO1xuXG4gICAgaWYgKGRldGFjaGVkVmlldykge1xuICAgICAgLy8gQmVmb3JlIGRlc3Ryb3lpbmcgdGhlIHZpZXcsIHJlbW92ZSBpdCBmcm9tIHRoZSBjb250YWluZXIncyBhcnJheSBvZiBgVmlld1JlZmBzLlxuICAgICAgLy8gVGhpcyBlbnN1cmVzIHRoZSB2aWV3IGNvbnRhaW5lciBsZW5ndGggaXMgdXBkYXRlZCBiZWZvcmUgY2FsbGluZ1xuICAgICAgLy8gYGRlc3Ryb3lMVmlld2AsIHdoaWNoIGNvdWxkIHJlY3Vyc2l2ZWx5IGNhbGwgdmlldyBjb250YWluZXIgbWV0aG9kcyB0aGF0XG4gICAgICAvLyByZWx5IG9uIGFuIGFjY3VyYXRlIGNvbnRhaW5lciBsZW5ndGguXG4gICAgICAvLyAoZS5nLiBhIG1ldGhvZCBvbiB0aGlzIHZpZXcgY29udGFpbmVyIGJlaW5nIGNhbGxlZCBieSBhIGNoaWxkIGRpcmVjdGl2ZSdzIE9uRGVzdHJveVxuICAgICAgLy8gbGlmZWN5Y2xlIGhvb2spXG4gICAgICByZW1vdmVGcm9tQXJyYXkoZ2V0T3JDcmVhdGVWaWV3UmVmcyh0aGlzLl9sQ29udGFpbmVyKSwgYWRqdXN0ZWRJZHgpO1xuICAgICAgZGVzdHJveUxWaWV3KGRldGFjaGVkVmlld1tUVklFV10sIGRldGFjaGVkVmlldyk7XG4gICAgfVxuICB9XG5cbiAgb3ZlcnJpZGUgZGV0YWNoKGluZGV4PzogbnVtYmVyKTogVmlld1JlZnxudWxsIHtcbiAgICBjb25zdCBhZGp1c3RlZElkeCA9IHRoaXMuX2FkanVzdEluZGV4KGluZGV4LCAtMSk7XG4gICAgY29uc3QgdmlldyA9IGRldGFjaFZpZXcodGhpcy5fbENvbnRhaW5lciwgYWRqdXN0ZWRJZHgpO1xuXG4gICAgY29uc3Qgd2FzRGV0YWNoZWQgPVxuICAgICAgICB2aWV3ICYmIHJlbW92ZUZyb21BcnJheShnZXRPckNyZWF0ZVZpZXdSZWZzKHRoaXMuX2xDb250YWluZXIpLCBhZGp1c3RlZElkeCkgIT0gbnVsbDtcbiAgICByZXR1cm4gd2FzRGV0YWNoZWQgPyBuZXcgUjNWaWV3UmVmKHZpZXchKSA6IG51bGw7XG4gIH1cblxuICBwcml2YXRlIF9hZGp1c3RJbmRleChpbmRleD86IG51bWJlciwgc2hpZnQ6IG51bWJlciA9IDApIHtcbiAgICBpZiAoaW5kZXggPT0gbnVsbCkge1xuICAgICAgcmV0dXJuIHRoaXMubGVuZ3RoICsgc2hpZnQ7XG4gICAgfVxuICAgIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAgIGFzc2VydEdyZWF0ZXJUaGFuKGluZGV4LCAtMSwgYFZpZXdSZWYgaW5kZXggbXVzdCBiZSBwb3NpdGl2ZSwgZ290ICR7aW5kZXh9YCk7XG4gICAgICAvLyArMSBiZWNhdXNlIGl0J3MgbGVnYWwgdG8gaW5zZXJ0IGF0IHRoZSBlbmQuXG4gICAgICBhc3NlcnRMZXNzVGhhbihpbmRleCwgdGhpcy5sZW5ndGggKyAxICsgc2hpZnQsICdpbmRleCcpO1xuICAgIH1cbiAgICByZXR1cm4gaW5kZXg7XG4gIH1cbn07XG5cbmZ1bmN0aW9uIGdldFZpZXdSZWZzKGxDb250YWluZXI6IExDb250YWluZXIpOiBWaWV3UmVmW118bnVsbCB7XG4gIHJldHVybiBsQ29udGFpbmVyW1ZJRVdfUkVGU10gYXMgVmlld1JlZltdO1xufVxuXG5mdW5jdGlvbiBnZXRPckNyZWF0ZVZpZXdSZWZzKGxDb250YWluZXI6IExDb250YWluZXIpOiBWaWV3UmVmW10ge1xuICByZXR1cm4gKGxDb250YWluZXJbVklFV19SRUZTXSB8fCAobENvbnRhaW5lcltWSUVXX1JFRlNdID0gW10pKSBhcyBWaWV3UmVmW107XG59XG5cbi8qKlxuICogQ3JlYXRlcyBhIFZpZXdDb250YWluZXJSZWYgYW5kIHN0b3JlcyBpdCBvbiB0aGUgaW5qZWN0b3IuXG4gKlxuICogQHBhcmFtIGhvc3RUTm9kZSBUaGUgbm9kZSB0aGF0IGlzIHJlcXVlc3RpbmcgYSBWaWV3Q29udGFpbmVyUmVmXG4gKiBAcGFyYW0gaG9zdExWaWV3IFRoZSB2aWV3IHRvIHdoaWNoIHRoZSBub2RlIGJlbG9uZ3NcbiAqIEByZXR1cm5zIFRoZSBWaWV3Q29udGFpbmVyUmVmIGluc3RhbmNlIHRvIHVzZVxuICovXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlQ29udGFpbmVyUmVmKFxuICAgIGhvc3RUTm9kZTogVEVsZW1lbnROb2RlfFRDb250YWluZXJOb2RlfFRFbGVtZW50Q29udGFpbmVyTm9kZSxcbiAgICBob3N0TFZpZXc6IExWaWV3KTogVmlld0NvbnRhaW5lclJlZiB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRUTm9kZVR5cGUoaG9zdFROb2RlLCBUTm9kZVR5cGUuQW55Q29udGFpbmVyIHwgVE5vZGVUeXBlLkFueVJOb2RlKTtcblxuICBsZXQgbENvbnRhaW5lcjogTENvbnRhaW5lcjtcbiAgY29uc3Qgc2xvdFZhbHVlID0gaG9zdExWaWV3W2hvc3RUTm9kZS5pbmRleF07XG4gIGlmIChpc0xDb250YWluZXIoc2xvdFZhbHVlKSkge1xuICAgIC8vIElmIHRoZSBob3N0IGlzIGEgY29udGFpbmVyLCB3ZSBkb24ndCBuZWVkIHRvIGNyZWF0ZSBhIG5ldyBMQ29udGFpbmVyXG4gICAgbENvbnRhaW5lciA9IHNsb3RWYWx1ZTtcbiAgfSBlbHNlIHtcbiAgICAvLyBBbiBMQ29udGFpbmVyIGFuY2hvciBjYW4gbm90IGJlIGBudWxsYCwgYnV0IHdlIHNldCBpdCBoZXJlIHRlbXBvcmFyaWx5XG4gICAgLy8gYW5kIHVwZGF0ZSB0byB0aGUgYWN0dWFsIHZhbHVlIGxhdGVyIGluIHRoaXMgZnVuY3Rpb24gKHNlZVxuICAgIC8vIGBfbG9jYXRlT3JDcmVhdGVBbmNob3JOb2RlYCkuXG4gICAgbENvbnRhaW5lciA9IGNyZWF0ZUxDb250YWluZXIoc2xvdFZhbHVlLCBob3N0TFZpZXcsIG51bGwhLCBob3N0VE5vZGUpO1xuICAgIGhvc3RMVmlld1tob3N0VE5vZGUuaW5kZXhdID0gbENvbnRhaW5lcjtcbiAgICBhZGRUb1ZpZXdUcmVlKGhvc3RMVmlldywgbENvbnRhaW5lcik7XG4gIH1cbiAgX2xvY2F0ZU9yQ3JlYXRlQW5jaG9yTm9kZShsQ29udGFpbmVyLCBob3N0TFZpZXcsIGhvc3RUTm9kZSwgc2xvdFZhbHVlKTtcblxuICByZXR1cm4gbmV3IFIzVmlld0NvbnRhaW5lclJlZihsQ29udGFpbmVyLCBob3N0VE5vZGUsIGhvc3RMVmlldyk7XG59XG5cbi8qKlxuICogQ3JlYXRlcyBhbmQgaW5zZXJ0cyBhIGNvbW1lbnQgbm9kZSB0aGF0IGFjdHMgYXMgYW4gYW5jaG9yIGZvciBhIHZpZXcgY29udGFpbmVyLlxuICpcbiAqIElmIHRoZSBob3N0IGlzIGEgcmVndWxhciBlbGVtZW50LCB3ZSBoYXZlIHRvIGluc2VydCBhIGNvbW1lbnQgbm9kZSBtYW51YWxseSB3aGljaCB3aWxsXG4gKiBiZSB1c2VkIGFzIGFuIGFuY2hvciB3aGVuIGluc2VydGluZyBlbGVtZW50cy4gSW4gdGhpcyBzcGVjaWZpYyBjYXNlIHdlIHVzZSBsb3ctbGV2ZWwgRE9NXG4gKiBtYW5pcHVsYXRpb24gdG8gaW5zZXJ0IGl0LlxuICovXG5mdW5jdGlvbiBpbnNlcnRBbmNob3JOb2RlKGhvc3RMVmlldzogTFZpZXcsIGhvc3RUTm9kZTogVE5vZGUpOiBSQ29tbWVudCB7XG4gIGNvbnN0IHJlbmRlcmVyID0gaG9zdExWaWV3W1JFTkRFUkVSXTtcbiAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlckNyZWF0ZUNvbW1lbnQrKztcbiAgY29uc3QgY29tbWVudE5vZGUgPSByZW5kZXJlci5jcmVhdGVDb21tZW50KG5nRGV2TW9kZSA/ICdjb250YWluZXInIDogJycpO1xuXG4gIGNvbnN0IGhvc3ROYXRpdmUgPSBnZXROYXRpdmVCeVROb2RlKGhvc3RUTm9kZSwgaG9zdExWaWV3KSE7XG4gIGNvbnN0IHBhcmVudE9mSG9zdE5hdGl2ZSA9IG5hdGl2ZVBhcmVudE5vZGUocmVuZGVyZXIsIGhvc3ROYXRpdmUpO1xuICBuYXRpdmVJbnNlcnRCZWZvcmUoXG4gICAgICByZW5kZXJlciwgcGFyZW50T2ZIb3N0TmF0aXZlISwgY29tbWVudE5vZGUsIG5hdGl2ZU5leHRTaWJsaW5nKHJlbmRlcmVyLCBob3N0TmF0aXZlKSwgZmFsc2UpO1xuICByZXR1cm4gY29tbWVudE5vZGU7XG59XG5cbmxldCBfbG9jYXRlT3JDcmVhdGVBbmNob3JOb2RlID0gY3JlYXRlQW5jaG9yTm9kZTtcblxuLyoqXG4gKiBSZWd1bGFyIGNyZWF0aW9uIG1vZGU6IGFuIGFuY2hvciBpcyBjcmVhdGVkIGFuZFxuICogYXNzaWduZWQgdG8gdGhlIGBsQ29udGFpbmVyW05BVElWRV1gIHNsb3QuXG4gKi9cbmZ1bmN0aW9uIGNyZWF0ZUFuY2hvck5vZGUoXG4gICAgbENvbnRhaW5lcjogTENvbnRhaW5lciwgaG9zdExWaWV3OiBMVmlldywgaG9zdFROb2RlOiBUTm9kZSwgc2xvdFZhbHVlOiBhbnkpIHtcbiAgLy8gV2UgYWxyZWFkeSBoYXZlIGEgbmF0aXZlIGVsZW1lbnQgKGFuY2hvcikgc2V0LCByZXR1cm4uXG4gIGlmIChsQ29udGFpbmVyW05BVElWRV0pIHJldHVybjtcblxuICBsZXQgY29tbWVudE5vZGU6IFJDb21tZW50O1xuICAvLyBJZiB0aGUgaG9zdCBpcyBhbiBlbGVtZW50IGNvbnRhaW5lciwgdGhlIG5hdGl2ZSBob3N0IGVsZW1lbnQgaXMgZ3VhcmFudGVlZCB0byBiZSBhXG4gIC8vIGNvbW1lbnQgYW5kIHdlIGNhbiByZXVzZSB0aGF0IGNvbW1lbnQgYXMgYW5jaG9yIGVsZW1lbnQgZm9yIHRoZSBuZXcgTENvbnRhaW5lci5cbiAgLy8gVGhlIGNvbW1lbnQgbm9kZSBpbiBxdWVzdGlvbiBpcyBhbHJlYWR5IHBhcnQgb2YgdGhlIERPTSBzdHJ1Y3R1cmUgc28gd2UgZG9uJ3QgbmVlZCB0byBhcHBlbmRcbiAgLy8gaXQgYWdhaW4uXG4gIGlmIChob3N0VE5vZGUudHlwZSAmIFROb2RlVHlwZS5FbGVtZW50Q29udGFpbmVyKSB7XG4gICAgY29tbWVudE5vZGUgPSB1bndyYXBSTm9kZShzbG90VmFsdWUpIGFzIFJDb21tZW50O1xuICB9IGVsc2Uge1xuICAgIGNvbW1lbnROb2RlID0gaW5zZXJ0QW5jaG9yTm9kZShob3N0TFZpZXcsIGhvc3RUTm9kZSk7XG4gIH1cbiAgbENvbnRhaW5lcltOQVRJVkVdID0gY29tbWVudE5vZGU7XG59XG5cbi8qKlxuICogSHlkcmF0aW9uIGxvZ2ljIHRoYXQgbG9va3MgdXA6XG4gKiAgLSBhbiBhbmNob3Igbm9kZSBpbiB0aGUgRE9NIGFuZCBzdG9yZXMgdGhlIG5vZGUgaW4gYGxDb250YWluZXJbTkFUSVZFXWBcbiAqICAtIGFsbCBkZWh5ZHJhdGVkIHZpZXdzIGluIHRoaXMgY29udGFpbmVyIGFuZCBwdXRzIHRoZW0gaW50byBgbENvbnRhaW5lcltERUhZRFJBVEVEX1ZJRVdTXWBcbiAqL1xuZnVuY3Rpb24gbG9jYXRlT3JDcmVhdGVBbmNob3JOb2RlKFxuICAgIGxDb250YWluZXI6IExDb250YWluZXIsIGhvc3RMVmlldzogTFZpZXcsIGhvc3RUTm9kZTogVE5vZGUsIHNsb3RWYWx1ZTogYW55KSB7XG4gIC8vIFdlIGFscmVhZHkgaGF2ZSBhIG5hdGl2ZSBlbGVtZW50IChhbmNob3IpIHNldCBhbmQgdGhlIHByb2Nlc3NcbiAgLy8gb2YgZmluZGluZyBkZWh5ZHJhdGVkIHZpZXdzIGhhcHBlbmVkIChzbyB0aGUgYGxDb250YWluZXJbREVIWURSQVRFRF9WSUVXU11gXG4gIC8vIGlzIG5vdCBudWxsKSwgZXhpdCBlYXJseS5cbiAgaWYgKGxDb250YWluZXJbTkFUSVZFXSAmJiBsQ29udGFpbmVyW0RFSFlEUkFURURfVklFV1NdKSByZXR1cm47XG5cbiAgY29uc3QgaHlkcmF0aW9uSW5mbyA9IGhvc3RMVmlld1tIWURSQVRJT05dO1xuICBjb25zdCBub09mZnNldEluZGV4ID0gaG9zdFROb2RlLmluZGV4IC0gSEVBREVSX09GRlNFVDtcbiAgY29uc3QgaXNOb2RlQ3JlYXRpb25Nb2RlID0gIWh5ZHJhdGlvbkluZm8gfHwgaXNJblNraXBIeWRyYXRpb25CbG9jayhob3N0VE5vZGUpIHx8XG4gICAgICBpc0Rpc2Nvbm5lY3RlZE5vZGUoaHlkcmF0aW9uSW5mbywgbm9PZmZzZXRJbmRleCk7XG5cbiAgLy8gUmVndWxhciBjcmVhdGlvbiBtb2RlLlxuICBpZiAoaXNOb2RlQ3JlYXRpb25Nb2RlKSB7XG4gICAgcmV0dXJuIGNyZWF0ZUFuY2hvck5vZGUobENvbnRhaW5lciwgaG9zdExWaWV3LCBob3N0VE5vZGUsIHNsb3RWYWx1ZSk7XG4gIH1cblxuICAvLyBIeWRyYXRpb24gbW9kZSwgbG9va2luZyB1cCBhbiBhbmNob3Igbm9kZSBhbmQgZGVoeWRyYXRlZCB2aWV3cyBpbiBET00uXG4gIGNvbnN0IGN1cnJlbnRSTm9kZTogUk5vZGV8bnVsbCA9IGdldFNlZ21lbnRIZWFkKGh5ZHJhdGlvbkluZm8sIG5vT2Zmc2V0SW5kZXgpO1xuXG4gIGNvbnN0IHNlcmlhbGl6ZWRWaWV3cyA9IGh5ZHJhdGlvbkluZm8uZGF0YVtDT05UQUlORVJTXT8uW25vT2Zmc2V0SW5kZXhdO1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydERlZmluZWQoXG4gICAgICAgICAgc2VyaWFsaXplZFZpZXdzLFxuICAgICAgICAgICdVbmV4cGVjdGVkIHN0YXRlOiBubyBoeWRyYXRpb24gaW5mbyBhdmFpbGFibGUgZm9yIGEgZ2l2ZW4gVE5vZGUsICcgK1xuICAgICAgICAgICAgICAnd2hpY2ggcmVwcmVzZW50cyBhIHZpZXcgY29udGFpbmVyLicpO1xuXG4gIGNvbnN0IFtjb21tZW50Tm9kZSwgZGVoeWRyYXRlZFZpZXdzXSA9XG4gICAgICBsb2NhdGVEZWh5ZHJhdGVkVmlld3NJbkNvbnRhaW5lcihjdXJyZW50Uk5vZGUhLCBzZXJpYWxpemVkVmlld3MhKTtcblxuICBpZiAobmdEZXZNb2RlKSB7XG4gICAgdmFsaWRhdGVNYXRjaGluZ05vZGUoY29tbWVudE5vZGUsIE5vZGUuQ09NTUVOVF9OT0RFLCBudWxsLCBob3N0TFZpZXcsIGhvc3RUTm9kZSwgdHJ1ZSk7XG4gICAgLy8gRG8gbm90IHRocm93IGluIGNhc2UgdGhpcyBub2RlIGlzIGFscmVhZHkgY2xhaW1lZCAodGh1cyBgZmFsc2VgIGFzIGEgc2Vjb25kXG4gICAgLy8gYXJndW1lbnQpLiBJZiB0aGlzIGNvbnRhaW5lciBpcyBjcmVhdGVkIGJhc2VkIG9uIGFuIGA8bmctdGVtcGxhdGU+YCwgdGhlIGNvbW1lbnRcbiAgICAvLyBub2RlIHdvdWxkIGJlIGFscmVhZHkgY2xhaW1lZCBmcm9tIHRoZSBgdGVtcGxhdGVgIGluc3RydWN0aW9uLiBJZiBhbiBlbGVtZW50IGFjdHNcbiAgICAvLyBhcyBhbiBhbmNob3IgKGUuZy4gPGRpdiAjdmNSZWY+KSwgYSBzZXBhcmF0ZSBjb21tZW50IG5vZGUgd291bGQgYmUgY3JlYXRlZC9sb2NhdGVkLFxuICAgIC8vIHNvIHdlIG5lZWQgdG8gY2xhaW0gaXQgaGVyZS5cbiAgICBtYXJrUk5vZGVBc0NsYWltZWRCeUh5ZHJhdGlvbihjb21tZW50Tm9kZSwgZmFsc2UpO1xuICB9XG5cbiAgbENvbnRhaW5lcltOQVRJVkVdID0gY29tbWVudE5vZGUgYXMgUkNvbW1lbnQ7XG4gIGxDb250YWluZXJbREVIWURSQVRFRF9WSUVXU10gPSBkZWh5ZHJhdGVkVmlld3M7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBlbmFibGVMb2NhdGVPckNyZWF0ZUNvbnRhaW5lclJlZkltcGwoKSB7XG4gIF9sb2NhdGVPckNyZWF0ZUFuY2hvck5vZGUgPSBsb2NhdGVPckNyZWF0ZUFuY2hvck5vZGU7XG59XG4iXX0=