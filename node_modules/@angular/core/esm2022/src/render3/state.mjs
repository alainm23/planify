/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { InjectFlags } from '../di/interface/injector';
import { assertDefined, assertEqual, assertGreaterThanOrEqual, assertLessThan, assertNotEqual, throwError } from '../util/assert';
import { assertLViewOrUndefined, assertTNodeForLView, assertTNodeForTView } from './assert';
import { CONTEXT, DECLARATION_VIEW, HEADER_OFFSET, T_HOST, TVIEW } from './interfaces/view';
import { MATH_ML_NAMESPACE, SVG_NAMESPACE } from './namespaces';
import { getTNode } from './util/view_utils';
const instructionState = {
    lFrame: createLFrame(null),
    bindingsEnabled: true,
    skipHydrationRootTNode: null,
};
/**
 * In this mode, any changes in bindings will throw an ExpressionChangedAfterChecked error.
 *
 * Necessary to support ChangeDetectorRef.checkNoChanges().
 *
 * The `checkNoChanges` function is invoked only in ngDevMode=true and verifies that no unintended
 * changes exist in the change detector or its children.
 */
let _isInCheckNoChangesMode = false;
/**
 * Returns true if the instruction state stack is empty.
 *
 * Intended to be called from tests only (tree shaken otherwise).
 */
export function specOnlyIsInstructionStateEmpty() {
    return instructionState.lFrame.parent === null;
}
export function getElementDepthCount() {
    return instructionState.lFrame.elementDepthCount;
}
export function increaseElementDepthCount() {
    instructionState.lFrame.elementDepthCount++;
}
export function decreaseElementDepthCount() {
    instructionState.lFrame.elementDepthCount--;
}
export function getBindingsEnabled() {
    return instructionState.bindingsEnabled;
}
/**
 * Returns true if currently inside a skip hydration block.
 * @returns boolean
 */
export function isInSkipHydrationBlock() {
    return instructionState.skipHydrationRootTNode !== null;
}
/**
 * Returns true if this is the root TNode of the skip hydration block.
 * @param tNode the current TNode
 * @returns boolean
 */
export function isSkipHydrationRootTNode(tNode) {
    return instructionState.skipHydrationRootTNode === tNode;
}
/**
 * Enables directive matching on elements.
 *
 *  * Example:
 * ```
 * <my-comp my-directive>
 *   Should match component / directive.
 * </my-comp>
 * <div ngNonBindable>
 *   <!-- ɵɵdisableBindings() -->
 *   <my-comp my-directive>
 *     Should not match component / directive because we are in ngNonBindable.
 *   </my-comp>
 *   <!-- ɵɵenableBindings() -->
 * </div>
 * ```
 *
 * @codeGenApi
 */
export function ɵɵenableBindings() {
    instructionState.bindingsEnabled = true;
}
/**
 * Sets a flag to specify that the TNode is in a skip hydration block.
 * @param tNode the current TNode
 */
export function enterSkipHydrationBlock(tNode) {
    instructionState.skipHydrationRootTNode = tNode;
}
/**
 * Disables directive matching on element.
 *
 *  * Example:
 * ```
 * <my-comp my-directive>
 *   Should match component / directive.
 * </my-comp>
 * <div ngNonBindable>
 *   <!-- ɵɵdisableBindings() -->
 *   <my-comp my-directive>
 *     Should not match component / directive because we are in ngNonBindable.
 *   </my-comp>
 *   <!-- ɵɵenableBindings() -->
 * </div>
 * ```
 *
 * @codeGenApi
 */
export function ɵɵdisableBindings() {
    instructionState.bindingsEnabled = false;
}
/**
 * Clears the root skip hydration node when leaving a skip hydration block.
 */
export function leaveSkipHydrationBlock() {
    instructionState.skipHydrationRootTNode = null;
}
/**
 * Return the current `LView`.
 */
export function getLView() {
    return instructionState.lFrame.lView;
}
/**
 * Return the current `TView`.
 */
export function getTView() {
    return instructionState.lFrame.tView;
}
/**
 * Restores `contextViewData` to the given OpaqueViewState instance.
 *
 * Used in conjunction with the getCurrentView() instruction to save a snapshot
 * of the current view and restore it when listeners are invoked. This allows
 * walking the declaration view tree in listeners to get vars from parent views.
 *
 * @param viewToRestore The OpaqueViewState instance to restore.
 * @returns Context of the restored OpaqueViewState instance.
 *
 * @codeGenApi
 */
export function ɵɵrestoreView(viewToRestore) {
    instructionState.lFrame.contextLView = viewToRestore;
    return viewToRestore[CONTEXT];
}
/**
 * Clears the view set in `ɵɵrestoreView` from memory. Returns the passed in
 * value so that it can be used as a return value of an instruction.
 *
 * @codeGenApi
 */
export function ɵɵresetView(value) {
    instructionState.lFrame.contextLView = null;
    return value;
}
export function getCurrentTNode() {
    let currentTNode = getCurrentTNodePlaceholderOk();
    while (currentTNode !== null && currentTNode.type === 64 /* TNodeType.Placeholder */) {
        currentTNode = currentTNode.parent;
    }
    return currentTNode;
}
export function getCurrentTNodePlaceholderOk() {
    return instructionState.lFrame.currentTNode;
}
export function getCurrentParentTNode() {
    const lFrame = instructionState.lFrame;
    const currentTNode = lFrame.currentTNode;
    return lFrame.isParent ? currentTNode : currentTNode.parent;
}
export function setCurrentTNode(tNode, isParent) {
    ngDevMode && tNode && assertTNodeForTView(tNode, instructionState.lFrame.tView);
    const lFrame = instructionState.lFrame;
    lFrame.currentTNode = tNode;
    lFrame.isParent = isParent;
}
export function isCurrentTNodeParent() {
    return instructionState.lFrame.isParent;
}
export function setCurrentTNodeAsNotParent() {
    instructionState.lFrame.isParent = false;
}
export function getContextLView() {
    const contextLView = instructionState.lFrame.contextLView;
    ngDevMode && assertDefined(contextLView, 'contextLView must be defined.');
    return contextLView;
}
export function isInCheckNoChangesMode() {
    !ngDevMode && throwError('Must never be called in production mode');
    return _isInCheckNoChangesMode;
}
export function setIsInCheckNoChangesMode(mode) {
    !ngDevMode && throwError('Must never be called in production mode');
    _isInCheckNoChangesMode = mode;
}
// top level variables should not be exported for performance reasons (PERF_NOTES.md)
export function getBindingRoot() {
    const lFrame = instructionState.lFrame;
    let index = lFrame.bindingRootIndex;
    if (index === -1) {
        index = lFrame.bindingRootIndex = lFrame.tView.bindingStartIndex;
    }
    return index;
}
export function getBindingIndex() {
    return instructionState.lFrame.bindingIndex;
}
export function setBindingIndex(value) {
    return instructionState.lFrame.bindingIndex = value;
}
export function nextBindingIndex() {
    return instructionState.lFrame.bindingIndex++;
}
export function incrementBindingIndex(count) {
    const lFrame = instructionState.lFrame;
    const index = lFrame.bindingIndex;
    lFrame.bindingIndex = lFrame.bindingIndex + count;
    return index;
}
export function isInI18nBlock() {
    return instructionState.lFrame.inI18n;
}
export function setInI18nBlock(isInI18nBlock) {
    instructionState.lFrame.inI18n = isInI18nBlock;
}
/**
 * Set a new binding root index so that host template functions can execute.
 *
 * Bindings inside the host template are 0 index. But because we don't know ahead of time
 * how many host bindings we have we can't pre-compute them. For this reason they are all
 * 0 index and we just shift the root so that they match next available location in the LView.
 *
 * @param bindingRootIndex Root index for `hostBindings`
 * @param currentDirectiveIndex `TData[currentDirectiveIndex]` will point to the current directive
 *        whose `hostBindings` are being processed.
 */
export function setBindingRootForHostBindings(bindingRootIndex, currentDirectiveIndex) {
    const lFrame = instructionState.lFrame;
    lFrame.bindingIndex = lFrame.bindingRootIndex = bindingRootIndex;
    setCurrentDirectiveIndex(currentDirectiveIndex);
}
/**
 * When host binding is executing this points to the directive index.
 * `TView.data[getCurrentDirectiveIndex()]` is `DirectiveDef`
 * `LView[getCurrentDirectiveIndex()]` is directive instance.
 */
export function getCurrentDirectiveIndex() {
    return instructionState.lFrame.currentDirectiveIndex;
}
/**
 * Sets an index of a directive whose `hostBindings` are being processed.
 *
 * @param currentDirectiveIndex `TData` index where current directive instance can be found.
 */
export function setCurrentDirectiveIndex(currentDirectiveIndex) {
    instructionState.lFrame.currentDirectiveIndex = currentDirectiveIndex;
}
/**
 * Retrieve the current `DirectiveDef` which is active when `hostBindings` instruction is being
 * executed.
 *
 * @param tData Current `TData` where the `DirectiveDef` will be looked up at.
 */
export function getCurrentDirectiveDef(tData) {
    const currentDirectiveIndex = instructionState.lFrame.currentDirectiveIndex;
    return currentDirectiveIndex === -1 ? null : tData[currentDirectiveIndex];
}
export function getCurrentQueryIndex() {
    return instructionState.lFrame.currentQueryIndex;
}
export function setCurrentQueryIndex(value) {
    instructionState.lFrame.currentQueryIndex = value;
}
/**
 * Returns a `TNode` of the location where the current `LView` is declared at.
 *
 * @param lView an `LView` that we want to find parent `TNode` for.
 */
function getDeclarationTNode(lView) {
    const tView = lView[TVIEW];
    // Return the declaration parent for embedded views
    if (tView.type === 2 /* TViewType.Embedded */) {
        ngDevMode && assertDefined(tView.declTNode, 'Embedded TNodes should have declaration parents.');
        return tView.declTNode;
    }
    // Components don't have `TView.declTNode` because each instance of component could be
    // inserted in different location, hence `TView.declTNode` is meaningless.
    // Falling back to `T_HOST` in case we cross component boundary.
    if (tView.type === 1 /* TViewType.Component */) {
        return lView[T_HOST];
    }
    // Remaining TNode type is `TViewType.Root` which doesn't have a parent TNode.
    return null;
}
/**
 * This is a light weight version of the `enterView` which is needed by the DI system.
 *
 * @param lView `LView` location of the DI context.
 * @param tNode `TNode` for DI context
 * @param flags DI context flags. if `SkipSelf` flag is set than we walk up the declaration
 *     tree from `tNode`  until we find parent declared `TElementNode`.
 * @returns `true` if we have successfully entered DI associated with `tNode` (or with declared
 *     `TNode` if `flags` has  `SkipSelf`). Failing to enter DI implies that no associated
 *     `NodeInjector` can be found and we should instead use `ModuleInjector`.
 *     - If `true` than this call must be fallowed by `leaveDI`
 *     - If `false` than this call failed and we should NOT call `leaveDI`
 */
export function enterDI(lView, tNode, flags) {
    ngDevMode && assertLViewOrUndefined(lView);
    if (flags & InjectFlags.SkipSelf) {
        ngDevMode && assertTNodeForTView(tNode, lView[TVIEW]);
        let parentTNode = tNode;
        let parentLView = lView;
        while (true) {
            ngDevMode && assertDefined(parentTNode, 'Parent TNode should be defined');
            parentTNode = parentTNode.parent;
            if (parentTNode === null && !(flags & InjectFlags.Host)) {
                parentTNode = getDeclarationTNode(parentLView);
                if (parentTNode === null)
                    break;
                // In this case, a parent exists and is definitely an element. So it will definitely
                // have an existing lView as the declaration view, which is why we can assume it's defined.
                ngDevMode && assertDefined(parentLView, 'Parent LView should be defined');
                parentLView = parentLView[DECLARATION_VIEW];
                // In Ivy there are Comment nodes that correspond to ngIf and NgFor embedded directives
                // We want to skip those and look only at Elements and ElementContainers to ensure
                // we're looking at true parent nodes, and not content or other types.
                if (parentTNode.type & (2 /* TNodeType.Element */ | 8 /* TNodeType.ElementContainer */)) {
                    break;
                }
            }
            else {
                break;
            }
        }
        if (parentTNode === null) {
            // If we failed to find a parent TNode this means that we should use module injector.
            return false;
        }
        else {
            tNode = parentTNode;
            lView = parentLView;
        }
    }
    ngDevMode && assertTNodeForLView(tNode, lView);
    const lFrame = instructionState.lFrame = allocLFrame();
    lFrame.currentTNode = tNode;
    lFrame.lView = lView;
    return true;
}
/**
 * Swap the current lView with a new lView.
 *
 * For performance reasons we store the lView in the top level of the module.
 * This way we minimize the number of properties to read. Whenever a new view
 * is entered we have to store the lView for later, and when the view is
 * exited the state has to be restored
 *
 * @param newView New lView to become active
 * @returns the previously active lView;
 */
export function enterView(newView) {
    ngDevMode && assertNotEqual(newView[0], newView[1], '????');
    ngDevMode && assertLViewOrUndefined(newView);
    const newLFrame = allocLFrame();
    if (ngDevMode) {
        assertEqual(newLFrame.isParent, true, 'Expected clean LFrame');
        assertEqual(newLFrame.lView, null, 'Expected clean LFrame');
        assertEqual(newLFrame.tView, null, 'Expected clean LFrame');
        assertEqual(newLFrame.selectedIndex, -1, 'Expected clean LFrame');
        assertEqual(newLFrame.elementDepthCount, 0, 'Expected clean LFrame');
        assertEqual(newLFrame.currentDirectiveIndex, -1, 'Expected clean LFrame');
        assertEqual(newLFrame.currentNamespace, null, 'Expected clean LFrame');
        assertEqual(newLFrame.bindingRootIndex, -1, 'Expected clean LFrame');
        assertEqual(newLFrame.currentQueryIndex, 0, 'Expected clean LFrame');
    }
    const tView = newView[TVIEW];
    instructionState.lFrame = newLFrame;
    ngDevMode && tView.firstChild && assertTNodeForTView(tView.firstChild, tView);
    newLFrame.currentTNode = tView.firstChild;
    newLFrame.lView = newView;
    newLFrame.tView = tView;
    newLFrame.contextLView = newView;
    newLFrame.bindingIndex = tView.bindingStartIndex;
    newLFrame.inI18n = false;
}
/**
 * Allocates next free LFrame. This function tries to reuse the `LFrame`s to lower memory pressure.
 */
function allocLFrame() {
    const currentLFrame = instructionState.lFrame;
    const childLFrame = currentLFrame === null ? null : currentLFrame.child;
    const newLFrame = childLFrame === null ? createLFrame(currentLFrame) : childLFrame;
    return newLFrame;
}
function createLFrame(parent) {
    const lFrame = {
        currentTNode: null,
        isParent: true,
        lView: null,
        tView: null,
        selectedIndex: -1,
        contextLView: null,
        elementDepthCount: 0,
        currentNamespace: null,
        currentDirectiveIndex: -1,
        bindingRootIndex: -1,
        bindingIndex: -1,
        currentQueryIndex: 0,
        parent: parent,
        child: null,
        inI18n: false,
    };
    parent !== null && (parent.child = lFrame); // link the new LFrame for reuse.
    return lFrame;
}
/**
 * A lightweight version of leave which is used with DI.
 *
 * This function only resets `currentTNode` and `LView` as those are the only properties
 * used with DI (`enterDI()`).
 *
 * NOTE: This function is reexported as `leaveDI`. However `leaveDI` has return type of `void` where
 * as `leaveViewLight` has `LFrame`. This is so that `leaveViewLight` can be used in `leaveView`.
 */
function leaveViewLight() {
    const oldLFrame = instructionState.lFrame;
    instructionState.lFrame = oldLFrame.parent;
    oldLFrame.currentTNode = null;
    oldLFrame.lView = null;
    return oldLFrame;
}
/**
 * This is a lightweight version of the `leaveView` which is needed by the DI system.
 *
 * NOTE: this function is an alias so that we can change the type of the function to have `void`
 * return type.
 */
export const leaveDI = leaveViewLight;
/**
 * Leave the current `LView`
 *
 * This pops the `LFrame` with the associated `LView` from the stack.
 *
 * IMPORTANT: We must zero out the `LFrame` values here otherwise they will be retained. This is
 * because for performance reasons we don't release `LFrame` but rather keep it for next use.
 */
export function leaveView() {
    const oldLFrame = leaveViewLight();
    oldLFrame.isParent = true;
    oldLFrame.tView = null;
    oldLFrame.selectedIndex = -1;
    oldLFrame.contextLView = null;
    oldLFrame.elementDepthCount = 0;
    oldLFrame.currentDirectiveIndex = -1;
    oldLFrame.currentNamespace = null;
    oldLFrame.bindingRootIndex = -1;
    oldLFrame.bindingIndex = -1;
    oldLFrame.currentQueryIndex = 0;
}
export function nextContextImpl(level) {
    const contextLView = instructionState.lFrame.contextLView =
        walkUpViews(level, instructionState.lFrame.contextLView);
    return contextLView[CONTEXT];
}
function walkUpViews(nestingLevel, currentView) {
    while (nestingLevel > 0) {
        ngDevMode &&
            assertDefined(currentView[DECLARATION_VIEW], 'Declaration view should be defined if nesting level is greater than 0.');
        currentView = currentView[DECLARATION_VIEW];
        nestingLevel--;
    }
    return currentView;
}
/**
 * Gets the currently selected element index.
 *
 * Used with {@link property} instruction (and more in the future) to identify the index in the
 * current `LView` to act on.
 */
export function getSelectedIndex() {
    return instructionState.lFrame.selectedIndex;
}
/**
 * Sets the most recent index passed to {@link select}
 *
 * Used with {@link property} instruction (and more in the future) to identify the index in the
 * current `LView` to act on.
 *
 * (Note that if an "exit function" was set earlier (via `setElementExitFn()`) then that will be
 * run if and when the provided `index` value is different from the current selected index value.)
 */
export function setSelectedIndex(index) {
    ngDevMode && index !== -1 &&
        assertGreaterThanOrEqual(index, HEADER_OFFSET, 'Index must be past HEADER_OFFSET (or -1).');
    ngDevMode &&
        assertLessThan(index, instructionState.lFrame.lView.length, 'Can\'t set index passed end of LView');
    instructionState.lFrame.selectedIndex = index;
}
/**
 * Gets the `tNode` that represents currently selected element.
 */
export function getSelectedTNode() {
    const lFrame = instructionState.lFrame;
    return getTNode(lFrame.tView, lFrame.selectedIndex);
}
/**
 * Sets the namespace used to create elements to `'http://www.w3.org/2000/svg'` in global state.
 *
 * @codeGenApi
 */
export function ɵɵnamespaceSVG() {
    instructionState.lFrame.currentNamespace = SVG_NAMESPACE;
}
/**
 * Sets the namespace used to create elements to `'http://www.w3.org/1998/MathML/'` in global state.
 *
 * @codeGenApi
 */
export function ɵɵnamespaceMathML() {
    instructionState.lFrame.currentNamespace = MATH_ML_NAMESPACE;
}
/**
 * Sets the namespace used to create elements to `null`, which forces element creation to use
 * `createElement` rather than `createElementNS`.
 *
 * @codeGenApi
 */
export function ɵɵnamespaceHTML() {
    namespaceHTMLInternal();
}
/**
 * Sets the namespace used to create elements to `null`, which forces element creation to use
 * `createElement` rather than `createElementNS`.
 */
export function namespaceHTMLInternal() {
    instructionState.lFrame.currentNamespace = null;
}
export function getNamespace() {
    return instructionState.lFrame.currentNamespace;
}
let _wasLastNodeCreated = true;
/**
 * Retrieves a global flag that indicates whether the most recent DOM node
 * was created or hydrated.
 */
export function wasLastNodeCreated() {
    return _wasLastNodeCreated;
}
/**
 * Sets a global flag to indicate whether the most recent DOM node
 * was created or hydrated.
 */
export function lastNodeWasCreated(flag) {
    _wasLastNodeCreated = flag;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic3RhdGUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL3N0YXRlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSwwQkFBMEIsQ0FBQztBQUNyRCxPQUFPLEVBQUMsYUFBYSxFQUFFLFdBQVcsRUFBRSx3QkFBd0IsRUFBRSxjQUFjLEVBQUUsY0FBYyxFQUFFLFVBQVUsRUFBQyxNQUFNLGdCQUFnQixDQUFDO0FBRWhJLE9BQU8sRUFBQyxzQkFBc0IsRUFBRSxtQkFBbUIsRUFBRSxtQkFBbUIsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUcxRixPQUFPLEVBQUMsT0FBTyxFQUFFLGdCQUFnQixFQUFFLGFBQWEsRUFBMEIsTUFBTSxFQUFTLEtBQUssRUFBbUIsTUFBTSxtQkFBbUIsQ0FBQztBQUMzSSxPQUFPLEVBQUMsaUJBQWlCLEVBQUUsYUFBYSxFQUFDLE1BQU0sY0FBYyxDQUFDO0FBQzlELE9BQU8sRUFBQyxRQUFRLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQTRLM0MsTUFBTSxnQkFBZ0IsR0FBcUI7SUFDekMsTUFBTSxFQUFFLFlBQVksQ0FBQyxJQUFJLENBQUM7SUFDMUIsZUFBZSxFQUFFLElBQUk7SUFDckIsc0JBQXNCLEVBQUUsSUFBSTtDQUM3QixDQUFDO0FBRUY7Ozs7Ozs7R0FPRztBQUNILElBQUksdUJBQXVCLEdBQUcsS0FBSyxDQUFDO0FBRXBDOzs7O0dBSUc7QUFDSCxNQUFNLFVBQVUsK0JBQStCO0lBQzdDLE9BQU8sZ0JBQWdCLENBQUMsTUFBTSxDQUFDLE1BQU0sS0FBSyxJQUFJLENBQUM7QUFDakQsQ0FBQztBQUdELE1BQU0sVUFBVSxvQkFBb0I7SUFDbEMsT0FBTyxnQkFBZ0IsQ0FBQyxNQUFNLENBQUMsaUJBQWlCLENBQUM7QUFDbkQsQ0FBQztBQUVELE1BQU0sVUFBVSx5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LENBQUM7QUFDbEQsQ0FBQztBQUVELElBQUksbUJBQW1CLEdBQUcsSUFBSSxDQUFDO0FBRS9COzs7R0FHRztBQUNILE1BQU0sVUFBVSxrQkFBa0I7SUFDaEMsT0FBTyxtQkFBbUIsQ0FBQztBQUM3QixDQUFDO0FBRUQ7OztHQUdHO0FBQ0gsTUFBTSxVQUFVLGtCQUFrQixDQUFDLElBQWE7SUFDOUMsbUJBQW1CLEdBQUcsSUFBSSxDQUFDO0FBQzdCLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtJbmplY3RGbGFnc30gZnJvbSAnLi4vZGkvaW50ZXJmYWNlL2luamVjdG9yJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZCwgYXNzZXJ0RXF1YWwsIGFzc2VydEdyZWF0ZXJUaGFuT3JFcXVhbCwgYXNzZXJ0TGVzc1RoYW4sIGFzc2VydE5vdEVxdWFsLCB0aHJvd0Vycm9yfSBmcm9tICcuLi91dGlsL2Fzc2VydCc7XG5cbmltcG9ydCB7YXNzZXJ0TFZpZXdPclVuZGVmaW5lZCwgYXNzZXJ0VE5vZGVGb3JMVmlldywgYXNzZXJ0VE5vZGVGb3JUVmlld30gZnJvbSAnLi9hc3NlcnQnO1xuaW1wb3J0IHtEaXJlY3RpdmVEZWZ9IGZyb20gJy4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7VE5vZGUsIFROb2RlVHlwZX0gZnJvbSAnLi9pbnRlcmZhY2VzL25vZGUnO1xuaW1wb3J0IHtDT05URVhULCBERUNMQVJBVElPTl9WSUVXLCBIRUFERVJfT0ZGU0VULCBMVmlldywgT3BhcXVlVmlld1N0YXRlLCBUX0hPU1QsIFREYXRhLCBUVklFVywgVFZpZXcsIFRWaWV3VHlwZX0gZnJvbSAnLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtNQVRIX01MX05BTUVTUEFDRSwgU1ZHX05BTUVTUEFDRX0gZnJvbSAnLi9uYW1lc3BhY2VzJztcbmltcG9ydCB7Z2V0VE5vZGV9IGZyb20gJy4vdXRpbC92aWV3X3V0aWxzJztcblxuXG4vKipcbiAqXG4gKi9cbmludGVyZmFjZSBMRnJhbWUge1xuICAvKipcbiAgICogUGFyZW50IExGcmFtZS5cbiAgICpcbiAgICogVGhpcyBpcyBuZWVkZWQgd2hlbiBgbGVhdmVWaWV3YCBpcyBjYWxsZWQgdG8gcmVzdG9yZSB0aGUgcHJldmlvdXMgc3RhdGUuXG4gICAqL1xuICBwYXJlbnQ6IExGcmFtZTtcblxuICAvKipcbiAgICogQ2hpbGQgTEZyYW1lLlxuICAgKlxuICAgKiBUaGlzIGlzIHVzZWQgdG8gY2FjaGUgZXhpc3RpbmcgTEZyYW1lcyB0byByZWxpZXZlIHRoZSBtZW1vcnkgcHJlc3N1cmUuXG4gICAqL1xuICBjaGlsZDogTEZyYW1lfG51bGw7XG5cbiAgLyoqXG4gICAqIFN0YXRlIG9mIHRoZSBjdXJyZW50IHZpZXcgYmVpbmcgcHJvY2Vzc2VkLlxuICAgKlxuICAgKiBBbiBhcnJheSBvZiBub2RlcyAodGV4dCwgZWxlbWVudCwgY29udGFpbmVyLCBldGMpLCBwaXBlcywgdGhlaXIgYmluZGluZ3MsIGFuZFxuICAgKiBhbnkgbG9jYWwgdmFyaWFibGVzIHRoYXQgbmVlZCB0byBiZSBzdG9yZWQgYmV0d2VlbiBpbnZvY2F0aW9ucy5cbiAgICovXG4gIGxWaWV3OiBMVmlldztcblxuICAvKipcbiAgICogQ3VycmVudCBgVFZpZXdgIGFzc29jaWF0ZWQgd2l0aCB0aGUgYExGcmFtZS5sVmlld2AuXG4gICAqXG4gICAqIE9uZSBjYW4gZ2V0IGBUVmlld2AgZnJvbSBgbEZyYW1lW1RWSUVXXWAgaG93ZXZlciBiZWNhdXNlIGl0IGlzIHNvIGNvbW1vbiBpdCBtYWtlcyBzZW5zZSB0b1xuICAgKiBzdG9yZSBpdCBpbiBgTEZyYW1lYCBmb3IgcGVyZiByZWFzb25zLlxuICAgKi9cbiAgdFZpZXc6IFRWaWV3O1xuXG4gIC8qKlxuICAgKiBVc2VkIHRvIHNldCB0aGUgcGFyZW50IHByb3BlcnR5IHdoZW4gbm9kZXMgYXJlIGNyZWF0ZWQgYW5kIHRyYWNrIHF1ZXJ5IHJlc3VsdHMuXG4gICAqXG4gICAqIFRoaXMgaXMgdXNlZCBpbiBjb25qdW5jdGlvbiB3aXRoIGBpc1BhcmVudGAuXG4gICAqL1xuICBjdXJyZW50VE5vZGU6IFROb2RlfG51bGw7XG5cbiAgLyoqXG4gICAqIElmIGBpc1BhcmVudGAgaXM6XG4gICAqICAtIGB0cnVlYDogdGhlbiBgY3VycmVudFROb2RlYCBwb2ludHMgdG8gYSBwYXJlbnQgbm9kZS5cbiAgICogIC0gYGZhbHNlYDogdGhlbiBgY3VycmVudFROb2RlYCBwb2ludHMgdG8gcHJldmlvdXMgbm9kZSAoc2libGluZykuXG4gICAqL1xuICBpc1BhcmVudDogYm9vbGVhbjtcblxuICAvKipcbiAgICogSW5kZXggb2YgY3VycmVudGx5IHNlbGVjdGVkIGVsZW1lbnQgaW4gTFZpZXcuXG4gICAqXG4gICAqIFVzZWQgYnkgYmluZGluZyBpbnN0cnVjdGlvbnMuIFVwZGF0ZWQgYXMgcGFydCBvZiBhZHZhbmNlIGluc3RydWN0aW9uLlxuICAgKi9cbiAgc2VsZWN0ZWRJbmRleDogbnVtYmVyO1xuXG4gIC8qKlxuICAgKiBDdXJyZW50IHBvaW50ZXIgdG8gdGhlIGJpbmRpbmcgaW5kZXguXG4gICAqL1xuICBiaW5kaW5nSW5kZXg6IG51bWJlcjtcblxuICAvKipcbiAgICogVGhlIGxhc3Qgdmlld0RhdGEgcmV0cmlldmVkIGJ5IG5leHRDb250ZXh0KCkuXG4gICAqIEFsbG93cyBidWlsZGluZyBuZXh0Q29udGV4dCgpIGFuZCByZWZlcmVuY2UoKSBjYWxscy5cbiAgICpcbiAgICogZS5nLiBjb25zdCBpbm5lciA9IHgoKS4kaW1wbGljaXQ7IGNvbnN0IG91dGVyID0geCgpLiRpbXBsaWNpdDtcbiAgICovXG4gIGNvbnRleHRMVmlldzogTFZpZXd8bnVsbDtcblxuICAvKipcbiAgICogU3RvcmUgdGhlIGVsZW1lbnQgZGVwdGggY291bnQuIFRoaXMgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgcm9vdCBlbGVtZW50cyBvZiB0aGUgdGVtcGxhdGVcbiAgICogc28gdGhhdCB3ZSBjYW4gdGhlbiBhdHRhY2ggcGF0Y2ggZGF0YSBgTFZpZXdgIHRvIG9ubHkgdGhvc2UgZWxlbWVudHMuIFdlIGtub3cgdGhhdCB0aG9zZVxuICAgKiBhcmUgdGhlIG9ubHkgcGxhY2VzIHdoZXJlIHRoZSBwYXRjaCBkYXRhIGNvdWxkIGNoYW5nZSwgdGhpcyB3YXkgd2Ugd2lsbCBzYXZlIG9uIG51bWJlclxuICAgKiBvZiBwbGFjZXMgd2hlcmUgdGhhIHBhdGNoaW5nIG9jY3Vycy5cbiAgICovXG4gIGVsZW1lbnREZXB0aENvdW50OiBudW1iZXI7XG5cbiAgLyoqXG4gICAqIEN1cnJlbnQgbmFtZXNwYWNlIHRvIGJlIHVzZWQgd2hlbiBjcmVhdGluZyBlbGVtZW50c1xuICAgKi9cbiAgY3VycmVudE5hbWVzcGFjZTogc3RyaW5nfG51bGw7XG5cblxuICAvKipcbiAgICogVGhlIHJvb3QgaW5kZXggZnJvbSB3aGljaCBwdXJlIGZ1bmN0aW9uIGluc3RydWN0aW9ucyBzaG91bGQgY2FsY3VsYXRlIHRoZWlyIGJpbmRpbmdcbiAgICogaW5kaWNlcy4gSW4gY29tcG9uZW50IHZpZXdzLCB0aGlzIGlzIFRWaWV3LmJpbmRpbmdTdGFydEluZGV4LiBJbiBhIGhvc3QgYmluZGluZ1xuICAgKiBjb250ZXh0LCB0aGlzIGlzIHRoZSBUVmlldy5leHBhbmRvU3RhcnRJbmRleCArIGFueSBkaXJzL2hvc3RWYXJzIGJlZm9yZSB0aGUgZ2l2ZW4gZGlyLlxuICAgKi9cbiAgYmluZGluZ1Jvb3RJbmRleDogbnVtYmVyO1xuXG4gIC8qKlxuICAgKiBDdXJyZW50IGluZGV4IG9mIGEgVmlldyBvciBDb250ZW50IFF1ZXJ5IHdoaWNoIG5lZWRzIHRvIGJlIHByb2Nlc3NlZCBuZXh0LlxuICAgKiBXZSBpdGVyYXRlIG92ZXIgdGhlIGxpc3Qgb2YgUXVlcmllcyBhbmQgaW5jcmVtZW50IGN1cnJlbnQgcXVlcnkgaW5kZXggYXQgZXZlcnkgc3RlcC5cbiAgICovXG4gIGN1cnJlbnRRdWVyeUluZGV4OiBudW1iZXI7XG5cbiAgLyoqXG4gICAqIFdoZW4gaG9zdCBiaW5kaW5nIGlzIGV4ZWN1dGluZyB0aGlzIHBvaW50cyB0byB0aGUgZGlyZWN0aXZlIGluZGV4LlxuICAgKiBgVFZpZXcuZGF0YVtjdXJyZW50RGlyZWN0aXZlSW5kZXhdYCBpcyBgRGlyZWN0aXZlRGVmYFxuICAgKiBgTFZpZXdbY3VycmVudERpcmVjdGl2ZUluZGV4XWAgaXMgZGlyZWN0aXZlIGluc3RhbmNlLlxuICAgKi9cbiAgY3VycmVudERpcmVjdGl2ZUluZGV4OiBudW1iZXI7XG5cbiAgLyoqXG4gICAqIEFyZSB3ZSBjdXJyZW50bHkgaW4gaTE4biBibG9jayBhcyBkZW5vdGVkIGJ5IGDJtcm1ZWxlbWVudFN0YXJ0YCBhbmQgYMm1ybVlbGVtZW50RW5kYC5cbiAgICpcbiAgICogVGhpcyBpbmZvcm1hdGlvbiBpcyBuZWVkZWQgYmVjYXVzZSB3aGlsZSB3ZSBhcmUgaW4gaTE4biBibG9jayBhbGwgZWxlbWVudHMgbXVzdCBiZSBwcmUtZGVjbGFyZWRcbiAgICogaW4gdGhlIHRyYW5zbGF0aW9uLiAoaS5lLiBgSGVsbG8g77+9IzLvv71Xb3JsZO+/vS8jMu+/vSFgIHByZS1kZWNsYXJlcyBlbGVtZW50IGF0IGDvv70jMu+/vWAgbG9jYXRpb24uKVxuICAgKiBUaGlzIGFsbG9jYXRlcyBgVE5vZGVUeXBlLlBsYWNlaG9sZGVyYCBlbGVtZW50IGF0IGxvY2F0aW9uIGAyYC4gSWYgdHJhbnNsYXRvciByZW1vdmVzIGDvv70jMu+/vWBcbiAgICogZnJvbSB0cmFuc2xhdGlvbiB0aGFuIHRoZSBydW50aW1lIG11c3QgYWxzbyBlbnN1cmUgdGhhIGVsZW1lbnQgYXQgYDJgIGRvZXMgbm90IGdldCBpbnNlcnRlZFxuICAgKiBpbnRvIHRoZSBET00uIFRoZSB0cmFuc2xhdGlvbiBkb2VzIG5vdCBjYXJyeSBpbmZvcm1hdGlvbiBhYm91dCBkZWxldGVkIGVsZW1lbnRzLiBUaGVyZWZvciB0aGVcbiAgICogb25seSB3YXkgdG8ga25vdyB0aGF0IGFuIGVsZW1lbnQgaXMgZGVsZXRlZCBpcyB0aGF0IGl0IHdhcyBub3QgcHJlLWRlY2xhcmVkIGluIHRoZSB0cmFuc2xhdGlvbi5cbiAgICpcbiAgICogVGhpcyBmbGFnIHdvcmtzIGJ5IGVuc3VyaW5nIHRoYXQgZWxlbWVudHMgd2hpY2ggYXJlIGNyZWF0ZWQgd2l0aG91dCBwcmUtZGVjbGFyYXRpb25cbiAgICogKGBUTm9kZVR5cGUuUGxhY2Vob2xkZXJgKSBhcmUgbm90IGluc2VydGVkIGludG8gdGhlIERPTSByZW5kZXIgdHJlZS4gKEl0IGRvZXMgbWVhbiB0aGF0IHRoZVxuICAgKiBlbGVtZW50IHN0aWxsIGdldHMgaW5zdGFudGlhdGVkIGFsb25nIHdpdGggYWxsIG9mIGl0cyBiZWhhdmlvciBbZGlyZWN0aXZlc10pXG4gICAqL1xuICBpbkkxOG46IGJvb2xlYW47XG59XG5cbi8qKlxuICogQWxsIGltcGxpY2l0IGluc3RydWN0aW9uIHN0YXRlIGlzIHN0b3JlZCBoZXJlLlxuICpcbiAqIEl0IGlzIHVzZWZ1bCB0byBoYXZlIGEgc2luZ2xlIG9iamVjdCB3aGVyZSBhbGwgb2YgdGhlIHN0YXRlIGlzIHN0b3JlZCBhcyBhIG1lbnRhbCBtb2RlbFxuICogKHJhdGhlciBpdCBiZWluZyBzcHJlYWQgYWNyb3NzIG1hbnkgZGlmZmVyZW50IHZhcmlhYmxlcy4pXG4gKlxuICogUEVSRiBOT1RFOiBUdXJucyBvdXQgdGhhdCB3cml0aW5nIHRvIGEgdHJ1ZSBnbG9iYWwgdmFyaWFibGUgaXMgc2xvd2VyIHRoYW5cbiAqIGhhdmluZyBhbiBpbnRlcm1lZGlhdGUgb2JqZWN0IHdpdGggcHJvcGVydGllcy5cbiAqL1xuaW50ZXJmYWNlIEluc3RydWN0aW9uU3RhdGUge1xuICAvKipcbiAgICogQ3VycmVudCBgTEZyYW1lYFxuICAgKlxuICAgKiBgbnVsbGAgaWYgd2UgaGF2ZSBub3QgY2FsbGVkIGBlbnRlclZpZXdgXG4gICAqL1xuICBsRnJhbWU6IExGcmFtZTtcblxuICAvKipcbiAgICogU3RvcmVzIHdoZXRoZXIgZGlyZWN0aXZlcyBzaG91bGQgYmUgbWF0Y2hlZCB0byBlbGVtZW50cy5cbiAgICpcbiAgICogV2hlbiB0ZW1wbGF0ZSBjb250YWlucyBgbmdOb25CaW5kYWJsZWAgdGhlbiB3ZSBuZWVkIHRvIHByZXZlbnQgdGhlIHJ1bnRpbWUgZnJvbSBtYXRjaGluZ1xuICAgKiBkaXJlY3RpdmVzIG9uIGNoaWxkcmVuIG9mIHRoYXQgZWxlbWVudC5cbiAgICpcbiAgICogRXhhbXBsZTpcbiAgICogYGBgXG4gICAqIDxteS1jb21wIG15LWRpcmVjdGl2ZT5cbiAgICogICBTaG91bGQgbWF0Y2ggY29tcG9uZW50IC8gZGlyZWN0aXZlLlxuICAgKiA8L215LWNvbXA+XG4gICAqIDxkaXYgbmdOb25CaW5kYWJsZT5cbiAgICogICA8bXktY29tcCBteS1kaXJlY3RpdmU+XG4gICAqICAgICBTaG91bGQgbm90IG1hdGNoIGNvbXBvbmVudCAvIGRpcmVjdGl2ZSBiZWNhdXNlIHdlIGFyZSBpbiBuZ05vbkJpbmRhYmxlLlxuICAgKiAgIDwvbXktY29tcD5cbiAgICogPC9kaXY+XG4gICAqIGBgYFxuICAgKi9cbiAgYmluZGluZ3NFbmFibGVkOiBib29sZWFuO1xuXG4gIC8qKlxuICAgKiBTdG9yZXMgdGhlIHJvb3QgVE5vZGUgdGhhdCBoYXMgdGhlICduZ1NraXBIeWRyYXRpb24nIGF0dHJpYnV0ZSBvbiBpdCBmb3IgbGF0ZXIgcmVmZXJlbmNlLlxuICAgKlxuICAgKiBFeGFtcGxlOlxuICAgKiBgYGBcbiAgICogPG15LWNvbXAgbmdTa2lwSHlkcmF0aW9uPlxuICAgKiAgIFNob3VsZCByZWZlcmVuY2UgdGhpcyByb290IG5vZGVcbiAgICogPC9teS1jb21wPlxuICAgKiBgYGBcbiAgICovXG4gIHNraXBIeWRyYXRpb25Sb290VE5vZGU6IFROb2RlfG51bGw7XG59XG5cbmNvbnN0IGluc3RydWN0aW9uU3RhdGU6IEluc3RydWN0aW9uU3RhdGUgPSB7XG4gIGxGcmFtZTogY3JlYXRlTEZyYW1lKG51bGwpLFxuICBiaW5kaW5nc0VuYWJsZWQ6IHRydWUsXG4gIHNraXBIeWRyYXRpb25Sb290VE5vZGU6IG51bGwsXG59O1xuXG4vKipcbiAqIEluIHRoaXMgbW9kZSwgYW55IGNoYW5nZXMgaW4gYmluZGluZ3Mgd2lsbCB0aHJvdyBhbiBFeHByZXNzaW9uQ2hhbmdlZEFmdGVyQ2hlY2tlZCBlcnJvci5cbiAqXG4gKiBOZWNlc3NhcnkgdG8gc3VwcG9ydCBDaGFuZ2VEZXRlY3RvclJlZi5jaGVja05vQ2hhbmdlcygpLlxuICpcbiAqIFRoZSBgY2hlY2tOb0NoYW5nZXNgIGZ1bmN0aW9uIGlzIGludm9rZWQgb25seSBpbiBuZ0Rldk1vZGU9dHJ1ZSBhbmQgdmVyaWZpZXMgdGhhdCBubyB1bmludGVuZGVkXG4gKiBjaGFuZ2VzIGV4aXN0IGluIHRoZSBjaGFuZ2UgZGV0ZWN0b3Igb3IgaXRzIGNoaWxkcmVuLlxuICovXG5sZXQgX2lzSW5DaGVja05vQ2hhbmdlc01vZGUgPSBmYWxzZTtcblxuLyoqXG4gKiBSZXR1cm5zIHRydWUgaWYgdGhlIGluc3RydWN0aW9uIHN0YXRlIHN0YWNrIGlzIGVtcHR5LlxuICpcbiAqIEludGVuZGVkIHRvIGJlIGNhbGxlZCBmcm9tIHRlc3RzIG9ubHkgKHRyZWUgc2hha2VuIG90aGVyd2lzZSkuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzcGVjT25seUlzSW5zdHJ1Y3Rpb25TdGF0ZUVtcHR5KCk6IGJvb2xlYW4ge1xuICByZXR1cm4gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUucGFyZW50ID09PSBudWxsO1xufVxuXG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRFbGVtZW50RGVwdGhDb3VudCgpIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmVsZW1lbnREZXB0aENvdW50O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gaW5jcmVhc2VFbGVtZW50RGVwdGhDb3VudCgpIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuZWxlbWVudERlcHRoQ291bnQrKztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGRlY3JlYXNlRWxlbWVudERlcHRoQ291bnQoKSB7XG4gIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmVsZW1lbnREZXB0aENvdW50LS07XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRCaW5kaW5nc0VuYWJsZWQoKTogYm9vbGVhbiB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmJpbmRpbmdzRW5hYmxlZDtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIHRydWUgaWYgY3VycmVudGx5IGluc2lkZSBhIHNraXAgaHlkcmF0aW9uIGJsb2NrLlxuICogQHJldHVybnMgYm9vbGVhblxuICovXG5leHBvcnQgZnVuY3Rpb24gaXNJblNraXBIeWRyYXRpb25CbG9jaygpOiBib29sZWFuIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUuc2tpcEh5ZHJhdGlvblJvb3RUTm9kZSAhPT0gbnVsbDtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIHRydWUgaWYgdGhpcyBpcyB0aGUgcm9vdCBUTm9kZSBvZiB0aGUgc2tpcCBoeWRyYXRpb24gYmxvY2suXG4gKiBAcGFyYW0gdE5vZGUgdGhlIGN1cnJlbnQgVE5vZGVcbiAqIEByZXR1cm5zIGJvb2xlYW5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGlzU2tpcEh5ZHJhdGlvblJvb3RUTm9kZSh0Tm9kZTogVE5vZGUpOiBib29sZWFuIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUuc2tpcEh5ZHJhdGlvblJvb3RUTm9kZSA9PT0gdE5vZGU7XG59XG5cbi8qKlxuICogRW5hYmxlcyBkaXJlY3RpdmUgbWF0Y2hpbmcgb24gZWxlbWVudHMuXG4gKlxuICogICogRXhhbXBsZTpcbiAqIGBgYFxuICogPG15LWNvbXAgbXktZGlyZWN0aXZlPlxuICogICBTaG91bGQgbWF0Y2ggY29tcG9uZW50IC8gZGlyZWN0aXZlLlxuICogPC9teS1jb21wPlxuICogPGRpdiBuZ05vbkJpbmRhYmxlPlxuICogICA8IS0tIMm1ybVkaXNhYmxlQmluZGluZ3MoKSAtLT5cbiAqICAgPG15LWNvbXAgbXktZGlyZWN0aXZlPlxuICogICAgIFNob3VsZCBub3QgbWF0Y2ggY29tcG9uZW50IC8gZGlyZWN0aXZlIGJlY2F1c2Ugd2UgYXJlIGluIG5nTm9uQmluZGFibGUuXG4gKiAgIDwvbXktY29tcD5cbiAqICAgPCEtLSDJtcm1ZW5hYmxlQmluZGluZ3MoKSAtLT5cbiAqIDwvZGl2PlxuICogYGBgXG4gKlxuICogQGNvZGVHZW5BcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1ybVlbmFibGVCaW5kaW5ncygpOiB2b2lkIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5iaW5kaW5nc0VuYWJsZWQgPSB0cnVlO1xufVxuXG4vKipcbiAqIFNldHMgYSBmbGFnIHRvIHNwZWNpZnkgdGhhdCB0aGUgVE5vZGUgaXMgaW4gYSBza2lwIGh5ZHJhdGlvbiBibG9jay5cbiAqIEBwYXJhbSB0Tm9kZSB0aGUgY3VycmVudCBUTm9kZVxuICovXG5leHBvcnQgZnVuY3Rpb24gZW50ZXJTa2lwSHlkcmF0aW9uQmxvY2sodE5vZGU6IFROb2RlKTogdm9pZCB7XG4gIGluc3RydWN0aW9uU3RhdGUuc2tpcEh5ZHJhdGlvblJvb3RUTm9kZSA9IHROb2RlO1xufVxuXG4vKipcbiAqIERpc2FibGVzIGRpcmVjdGl2ZSBtYXRjaGluZyBvbiBlbGVtZW50LlxuICpcbiAqICAqIEV4YW1wbGU6XG4gKiBgYGBcbiAqIDxteS1jb21wIG15LWRpcmVjdGl2ZT5cbiAqICAgU2hvdWxkIG1hdGNoIGNvbXBvbmVudCAvIGRpcmVjdGl2ZS5cbiAqIDwvbXktY29tcD5cbiAqIDxkaXYgbmdOb25CaW5kYWJsZT5cbiAqICAgPCEtLSDJtcm1ZGlzYWJsZUJpbmRpbmdzKCkgLS0+XG4gKiAgIDxteS1jb21wIG15LWRpcmVjdGl2ZT5cbiAqICAgICBTaG91bGQgbm90IG1hdGNoIGNvbXBvbmVudCAvIGRpcmVjdGl2ZSBiZWNhdXNlIHdlIGFyZSBpbiBuZ05vbkJpbmRhYmxlLlxuICogICA8L215LWNvbXA+XG4gKiAgIDwhLS0gybXJtWVuYWJsZUJpbmRpbmdzKCkgLS0+XG4gKiA8L2Rpdj5cbiAqIGBgYFxuICpcbiAqIEBjb2RlR2VuQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtcm1ZGlzYWJsZUJpbmRpbmdzKCk6IHZvaWQge1xuICBpbnN0cnVjdGlvblN0YXRlLmJpbmRpbmdzRW5hYmxlZCA9IGZhbHNlO1xufVxuXG4vKipcbiAqIENsZWFycyB0aGUgcm9vdCBza2lwIGh5ZHJhdGlvbiBub2RlIHdoZW4gbGVhdmluZyBhIHNraXAgaHlkcmF0aW9uIGJsb2NrLlxuICovXG5leHBvcnQgZnVuY3Rpb24gbGVhdmVTa2lwSHlkcmF0aW9uQmxvY2soKTogdm9pZCB7XG4gIGluc3RydWN0aW9uU3RhdGUuc2tpcEh5ZHJhdGlvblJvb3RUTm9kZSA9IG51bGw7XG59XG5cbi8qKlxuICogUmV0dXJuIHRoZSBjdXJyZW50IGBMVmlld2AuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBnZXRMVmlldzxUPigpOiBMVmlldzxUPiB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5sVmlldyBhcyBMVmlldzxUPjtcbn1cblxuLyoqXG4gKiBSZXR1cm4gdGhlIGN1cnJlbnQgYFRWaWV3YC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldFRWaWV3KCk6IFRWaWV3IHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLnRWaWV3O1xufVxuXG4vKipcbiAqIFJlc3RvcmVzIGBjb250ZXh0Vmlld0RhdGFgIHRvIHRoZSBnaXZlbiBPcGFxdWVWaWV3U3RhdGUgaW5zdGFuY2UuXG4gKlxuICogVXNlZCBpbiBjb25qdW5jdGlvbiB3aXRoIHRoZSBnZXRDdXJyZW50VmlldygpIGluc3RydWN0aW9uIHRvIHNhdmUgYSBzbmFwc2hvdFxuICogb2YgdGhlIGN1cnJlbnQgdmlldyBhbmQgcmVzdG9yZSBpdCB3aGVuIGxpc3RlbmVycyBhcmUgaW52b2tlZC4gVGhpcyBhbGxvd3NcbiAqIHdhbGtpbmcgdGhlIGRlY2xhcmF0aW9uIHZpZXcgdHJlZSBpbiBsaXN0ZW5lcnMgdG8gZ2V0IHZhcnMgZnJvbSBwYXJlbnQgdmlld3MuXG4gKlxuICogQHBhcmFtIHZpZXdUb1Jlc3RvcmUgVGhlIE9wYXF1ZVZpZXdTdGF0ZSBpbnN0YW5jZSB0byByZXN0b3JlLlxuICogQHJldHVybnMgQ29udGV4dCBvZiB0aGUgcmVzdG9yZWQgT3BhcXVlVmlld1N0YXRlIGluc3RhbmNlLlxuICpcbiAqIEBjb2RlR2VuQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtcm1cmVzdG9yZVZpZXc8VCA9IGFueT4odmlld1RvUmVzdG9yZTogT3BhcXVlVmlld1N0YXRlKTogVCB7XG4gIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmNvbnRleHRMVmlldyA9IHZpZXdUb1Jlc3RvcmUgYXMgYW55IGFzIExWaWV3O1xuICByZXR1cm4gKHZpZXdUb1Jlc3RvcmUgYXMgYW55IGFzIExWaWV3KVtDT05URVhUXSBhcyB1bmtub3duIGFzIFQ7XG59XG5cblxuLyoqXG4gKiBDbGVhcnMgdGhlIHZpZXcgc2V0IGluIGDJtcm1cmVzdG9yZVZpZXdgIGZyb20gbWVtb3J5LiBSZXR1cm5zIHRoZSBwYXNzZWQgaW5cbiAqIHZhbHVlIHNvIHRoYXQgaXQgY2FuIGJlIHVzZWQgYXMgYSByZXR1cm4gdmFsdWUgb2YgYW4gaW5zdHJ1Y3Rpb24uXG4gKlxuICogQGNvZGVHZW5BcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1ybVyZXNldFZpZXc8VD4odmFsdWU/OiBUKTogVHx1bmRlZmluZWQge1xuICBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5jb250ZXh0TFZpZXcgPSBudWxsO1xuICByZXR1cm4gdmFsdWU7XG59XG5cblxuZXhwb3J0IGZ1bmN0aW9uIGdldEN1cnJlbnRUTm9kZSgpOiBUTm9kZXxudWxsIHtcbiAgbGV0IGN1cnJlbnRUTm9kZSA9IGdldEN1cnJlbnRUTm9kZVBsYWNlaG9sZGVyT2soKTtcbiAgd2hpbGUgKGN1cnJlbnRUTm9kZSAhPT0gbnVsbCAmJiBjdXJyZW50VE5vZGUudHlwZSA9PT0gVE5vZGVUeXBlLlBsYWNlaG9sZGVyKSB7XG4gICAgY3VycmVudFROb2RlID0gY3VycmVudFROb2RlLnBhcmVudDtcbiAgfVxuICByZXR1cm4gY3VycmVudFROb2RlO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gZ2V0Q3VycmVudFROb2RlUGxhY2Vob2xkZXJPaygpOiBUTm9kZXxudWxsIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmN1cnJlbnRUTm9kZTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldEN1cnJlbnRQYXJlbnRUTm9kZSgpOiBUTm9kZXxudWxsIHtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIGNvbnN0IGN1cnJlbnRUTm9kZSA9IGxGcmFtZS5jdXJyZW50VE5vZGU7XG4gIHJldHVybiBsRnJhbWUuaXNQYXJlbnQgPyBjdXJyZW50VE5vZGUgOiBjdXJyZW50VE5vZGUhLnBhcmVudDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHNldEN1cnJlbnRUTm9kZSh0Tm9kZTogVE5vZGV8bnVsbCwgaXNQYXJlbnQ6IGJvb2xlYW4pIHtcbiAgbmdEZXZNb2RlICYmIHROb2RlICYmIGFzc2VydFROb2RlRm9yVFZpZXcodE5vZGUsIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLnRWaWV3KTtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIGxGcmFtZS5jdXJyZW50VE5vZGUgPSB0Tm9kZTtcbiAgbEZyYW1lLmlzUGFyZW50ID0gaXNQYXJlbnQ7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc0N1cnJlbnRUTm9kZVBhcmVudCgpOiBib29sZWFuIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmlzUGFyZW50O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gc2V0Q3VycmVudFROb2RlQXNOb3RQYXJlbnQoKTogdm9pZCB7XG4gIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmlzUGFyZW50ID0gZmFsc2U7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRDb250ZXh0TFZpZXcoKTogTFZpZXcge1xuICBjb25zdCBjb250ZXh0TFZpZXcgPSBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5jb250ZXh0TFZpZXc7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGNvbnRleHRMVmlldywgJ2NvbnRleHRMVmlldyBtdXN0IGJlIGRlZmluZWQuJyk7XG4gIHJldHVybiBjb250ZXh0TFZpZXchO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gaXNJbkNoZWNrTm9DaGFuZ2VzTW9kZSgpOiBib29sZWFuIHtcbiAgIW5nRGV2TW9kZSAmJiB0aHJvd0Vycm9yKCdNdXN0IG5ldmVyIGJlIGNhbGxlZCBpbiBwcm9kdWN0aW9uIG1vZGUnKTtcbiAgcmV0dXJuIF9pc0luQ2hlY2tOb0NoYW5nZXNNb2RlO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gc2V0SXNJbkNoZWNrTm9DaGFuZ2VzTW9kZShtb2RlOiBib29sZWFuKTogdm9pZCB7XG4gICFuZ0Rldk1vZGUgJiYgdGhyb3dFcnJvcignTXVzdCBuZXZlciBiZSBjYWxsZWQgaW4gcHJvZHVjdGlvbiBtb2RlJyk7XG4gIF9pc0luQ2hlY2tOb0NoYW5nZXNNb2RlID0gbW9kZTtcbn1cblxuLy8gdG9wIGxldmVsIHZhcmlhYmxlcyBzaG91bGQgbm90IGJlIGV4cG9ydGVkIGZvciBwZXJmb3JtYW5jZSByZWFzb25zIChQRVJGX05PVEVTLm1kKVxuZXhwb3J0IGZ1bmN0aW9uIGdldEJpbmRpbmdSb290KCkge1xuICBjb25zdCBsRnJhbWUgPSBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZTtcbiAgbGV0IGluZGV4ID0gbEZyYW1lLmJpbmRpbmdSb290SW5kZXg7XG4gIGlmIChpbmRleCA9PT0gLTEpIHtcbiAgICBpbmRleCA9IGxGcmFtZS5iaW5kaW5nUm9vdEluZGV4ID0gbEZyYW1lLnRWaWV3LmJpbmRpbmdTdGFydEluZGV4O1xuICB9XG4gIHJldHVybiBpbmRleDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldEJpbmRpbmdJbmRleCgpOiBudW1iZXIge1xuICByZXR1cm4gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuYmluZGluZ0luZGV4O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gc2V0QmluZGluZ0luZGV4KHZhbHVlOiBudW1iZXIpOiBudW1iZXIge1xuICByZXR1cm4gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuYmluZGluZ0luZGV4ID0gdmFsdWU7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBuZXh0QmluZGluZ0luZGV4KCk6IG51bWJlciB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5iaW5kaW5nSW5kZXgrKztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGluY3JlbWVudEJpbmRpbmdJbmRleChjb3VudDogbnVtYmVyKTogbnVtYmVyIHtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIGNvbnN0IGluZGV4ID0gbEZyYW1lLmJpbmRpbmdJbmRleDtcbiAgbEZyYW1lLmJpbmRpbmdJbmRleCA9IGxGcmFtZS5iaW5kaW5nSW5kZXggKyBjb3VudDtcbiAgcmV0dXJuIGluZGV4O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gaXNJbkkxOG5CbG9jaygpIHtcbiAgcmV0dXJuIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmluSTE4bjtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHNldEluSTE4bkJsb2NrKGlzSW5JMThuQmxvY2s6IGJvb2xlYW4pOiB2b2lkIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuaW5JMThuID0gaXNJbkkxOG5CbG9jaztcbn1cblxuLyoqXG4gKiBTZXQgYSBuZXcgYmluZGluZyByb290IGluZGV4IHNvIHRoYXQgaG9zdCB0ZW1wbGF0ZSBmdW5jdGlvbnMgY2FuIGV4ZWN1dGUuXG4gKlxuICogQmluZGluZ3MgaW5zaWRlIHRoZSBob3N0IHRlbXBsYXRlIGFyZSAwIGluZGV4LiBCdXQgYmVjYXVzZSB3ZSBkb24ndCBrbm93IGFoZWFkIG9mIHRpbWVcbiAqIGhvdyBtYW55IGhvc3QgYmluZGluZ3Mgd2UgaGF2ZSB3ZSBjYW4ndCBwcmUtY29tcHV0ZSB0aGVtLiBGb3IgdGhpcyByZWFzb24gdGhleSBhcmUgYWxsXG4gKiAwIGluZGV4IGFuZCB3ZSBqdXN0IHNoaWZ0IHRoZSByb290IHNvIHRoYXQgdGhleSBtYXRjaCBuZXh0IGF2YWlsYWJsZSBsb2NhdGlvbiBpbiB0aGUgTFZpZXcuXG4gKlxuICogQHBhcmFtIGJpbmRpbmdSb290SW5kZXggUm9vdCBpbmRleCBmb3IgYGhvc3RCaW5kaW5nc2BcbiAqIEBwYXJhbSBjdXJyZW50RGlyZWN0aXZlSW5kZXggYFREYXRhW2N1cnJlbnREaXJlY3RpdmVJbmRleF1gIHdpbGwgcG9pbnQgdG8gdGhlIGN1cnJlbnQgZGlyZWN0aXZlXG4gKiAgICAgICAgd2hvc2UgYGhvc3RCaW5kaW5nc2AgYXJlIGJlaW5nIHByb2Nlc3NlZC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldEJpbmRpbmdSb290Rm9ySG9zdEJpbmRpbmdzKFxuICAgIGJpbmRpbmdSb290SW5kZXg6IG51bWJlciwgY3VycmVudERpcmVjdGl2ZUluZGV4OiBudW1iZXIpIHtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIGxGcmFtZS5iaW5kaW5nSW5kZXggPSBsRnJhbWUuYmluZGluZ1Jvb3RJbmRleCA9IGJpbmRpbmdSb290SW5kZXg7XG4gIHNldEN1cnJlbnREaXJlY3RpdmVJbmRleChjdXJyZW50RGlyZWN0aXZlSW5kZXgpO1xufVxuXG4vKipcbiAqIFdoZW4gaG9zdCBiaW5kaW5nIGlzIGV4ZWN1dGluZyB0aGlzIHBvaW50cyB0byB0aGUgZGlyZWN0aXZlIGluZGV4LlxuICogYFRWaWV3LmRhdGFbZ2V0Q3VycmVudERpcmVjdGl2ZUluZGV4KCldYCBpcyBgRGlyZWN0aXZlRGVmYFxuICogYExWaWV3W2dldEN1cnJlbnREaXJlY3RpdmVJbmRleCgpXWAgaXMgZGlyZWN0aXZlIGluc3RhbmNlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0Q3VycmVudERpcmVjdGl2ZUluZGV4KCk6IG51bWJlciB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5jdXJyZW50RGlyZWN0aXZlSW5kZXg7XG59XG5cbi8qKlxuICogU2V0cyBhbiBpbmRleCBvZiBhIGRpcmVjdGl2ZSB3aG9zZSBgaG9zdEJpbmRpbmdzYCBhcmUgYmVpbmcgcHJvY2Vzc2VkLlxuICpcbiAqIEBwYXJhbSBjdXJyZW50RGlyZWN0aXZlSW5kZXggYFREYXRhYCBpbmRleCB3aGVyZSBjdXJyZW50IGRpcmVjdGl2ZSBpbnN0YW5jZSBjYW4gYmUgZm91bmQuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzZXRDdXJyZW50RGlyZWN0aXZlSW5kZXgoY3VycmVudERpcmVjdGl2ZUluZGV4OiBudW1iZXIpOiB2b2lkIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY3VycmVudERpcmVjdGl2ZUluZGV4ID0gY3VycmVudERpcmVjdGl2ZUluZGV4O1xufVxuXG4vKipcbiAqIFJldHJpZXZlIHRoZSBjdXJyZW50IGBEaXJlY3RpdmVEZWZgIHdoaWNoIGlzIGFjdGl2ZSB3aGVuIGBob3N0QmluZGluZ3NgIGluc3RydWN0aW9uIGlzIGJlaW5nXG4gKiBleGVjdXRlZC5cbiAqXG4gKiBAcGFyYW0gdERhdGEgQ3VycmVudCBgVERhdGFgIHdoZXJlIHRoZSBgRGlyZWN0aXZlRGVmYCB3aWxsIGJlIGxvb2tlZCB1cCBhdC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldEN1cnJlbnREaXJlY3RpdmVEZWYodERhdGE6IFREYXRhKTogRGlyZWN0aXZlRGVmPGFueT58bnVsbCB7XG4gIGNvbnN0IGN1cnJlbnREaXJlY3RpdmVJbmRleCA9IGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmN1cnJlbnREaXJlY3RpdmVJbmRleDtcbiAgcmV0dXJuIGN1cnJlbnREaXJlY3RpdmVJbmRleCA9PT0gLTEgPyBudWxsIDogdERhdGFbY3VycmVudERpcmVjdGl2ZUluZGV4XSBhcyBEaXJlY3RpdmVEZWY8YW55Pjtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldEN1cnJlbnRRdWVyeUluZGV4KCk6IG51bWJlciB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5jdXJyZW50UXVlcnlJbmRleDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHNldEN1cnJlbnRRdWVyeUluZGV4KHZhbHVlOiBudW1iZXIpOiB2b2lkIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY3VycmVudFF1ZXJ5SW5kZXggPSB2YWx1ZTtcbn1cblxuLyoqXG4gKiBSZXR1cm5zIGEgYFROb2RlYCBvZiB0aGUgbG9jYXRpb24gd2hlcmUgdGhlIGN1cnJlbnQgYExWaWV3YCBpcyBkZWNsYXJlZCBhdC5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgYW4gYExWaWV3YCB0aGF0IHdlIHdhbnQgdG8gZmluZCBwYXJlbnQgYFROb2RlYCBmb3IuXG4gKi9cbmZ1bmN0aW9uIGdldERlY2xhcmF0aW9uVE5vZGUobFZpZXc6IExWaWV3KTogVE5vZGV8bnVsbCB7XG4gIGNvbnN0IHRWaWV3ID0gbFZpZXdbVFZJRVddO1xuXG4gIC8vIFJldHVybiB0aGUgZGVjbGFyYXRpb24gcGFyZW50IGZvciBlbWJlZGRlZCB2aWV3c1xuICBpZiAodFZpZXcudHlwZSA9PT0gVFZpZXdUeXBlLkVtYmVkZGVkKSB7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQodFZpZXcuZGVjbFROb2RlLCAnRW1iZWRkZWQgVE5vZGVzIHNob3VsZCBoYXZlIGRlY2xhcmF0aW9uIHBhcmVudHMuJyk7XG4gICAgcmV0dXJuIHRWaWV3LmRlY2xUTm9kZTtcbiAgfVxuXG4gIC8vIENvbXBvbmVudHMgZG9uJ3QgaGF2ZSBgVFZpZXcuZGVjbFROb2RlYCBiZWNhdXNlIGVhY2ggaW5zdGFuY2Ugb2YgY29tcG9uZW50IGNvdWxkIGJlXG4gIC8vIGluc2VydGVkIGluIGRpZmZlcmVudCBsb2NhdGlvbiwgaGVuY2UgYFRWaWV3LmRlY2xUTm9kZWAgaXMgbWVhbmluZ2xlc3MuXG4gIC8vIEZhbGxpbmcgYmFjayB0byBgVF9IT1NUYCBpbiBjYXNlIHdlIGNyb3NzIGNvbXBvbmVudCBib3VuZGFyeS5cbiAgaWYgKHRWaWV3LnR5cGUgPT09IFRWaWV3VHlwZS5Db21wb25lbnQpIHtcbiAgICByZXR1cm4gbFZpZXdbVF9IT1NUXTtcbiAgfVxuXG4gIC8vIFJlbWFpbmluZyBUTm9kZSB0eXBlIGlzIGBUVmlld1R5cGUuUm9vdGAgd2hpY2ggZG9lc24ndCBoYXZlIGEgcGFyZW50IFROb2RlLlxuICByZXR1cm4gbnVsbDtcbn1cblxuLyoqXG4gKiBUaGlzIGlzIGEgbGlnaHQgd2VpZ2h0IHZlcnNpb24gb2YgdGhlIGBlbnRlclZpZXdgIHdoaWNoIGlzIG5lZWRlZCBieSB0aGUgREkgc3lzdGVtLlxuICpcbiAqIEBwYXJhbSBsVmlldyBgTFZpZXdgIGxvY2F0aW9uIG9mIHRoZSBESSBjb250ZXh0LlxuICogQHBhcmFtIHROb2RlIGBUTm9kZWAgZm9yIERJIGNvbnRleHRcbiAqIEBwYXJhbSBmbGFncyBESSBjb250ZXh0IGZsYWdzLiBpZiBgU2tpcFNlbGZgIGZsYWcgaXMgc2V0IHRoYW4gd2Ugd2FsayB1cCB0aGUgZGVjbGFyYXRpb25cbiAqICAgICB0cmVlIGZyb20gYHROb2RlYCAgdW50aWwgd2UgZmluZCBwYXJlbnQgZGVjbGFyZWQgYFRFbGVtZW50Tm9kZWAuXG4gKiBAcmV0dXJucyBgdHJ1ZWAgaWYgd2UgaGF2ZSBzdWNjZXNzZnVsbHkgZW50ZXJlZCBESSBhc3NvY2lhdGVkIHdpdGggYHROb2RlYCAob3Igd2l0aCBkZWNsYXJlZFxuICogICAgIGBUTm9kZWAgaWYgYGZsYWdzYCBoYXMgIGBTa2lwU2VsZmApLiBGYWlsaW5nIHRvIGVudGVyIERJIGltcGxpZXMgdGhhdCBubyBhc3NvY2lhdGVkXG4gKiAgICAgYE5vZGVJbmplY3RvcmAgY2FuIGJlIGZvdW5kIGFuZCB3ZSBzaG91bGQgaW5zdGVhZCB1c2UgYE1vZHVsZUluamVjdG9yYC5cbiAqICAgICAtIElmIGB0cnVlYCB0aGFuIHRoaXMgY2FsbCBtdXN0IGJlIGZhbGxvd2VkIGJ5IGBsZWF2ZURJYFxuICogICAgIC0gSWYgYGZhbHNlYCB0aGFuIHRoaXMgY2FsbCBmYWlsZWQgYW5kIHdlIHNob3VsZCBOT1QgY2FsbCBgbGVhdmVESWBcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGVudGVyREkobFZpZXc6IExWaWV3LCB0Tm9kZTogVE5vZGUsIGZsYWdzOiBJbmplY3RGbGFncykge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TFZpZXdPclVuZGVmaW5lZChsVmlldyk7XG5cbiAgaWYgKGZsYWdzICYgSW5qZWN0RmxhZ3MuU2tpcFNlbGYpIHtcbiAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0VE5vZGVGb3JUVmlldyh0Tm9kZSwgbFZpZXdbVFZJRVddKTtcblxuICAgIGxldCBwYXJlbnRUTm9kZSA9IHROb2RlIGFzIFROb2RlIHwgbnVsbDtcbiAgICBsZXQgcGFyZW50TFZpZXcgPSBsVmlldztcblxuICAgIHdoaWxlICh0cnVlKSB7XG4gICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZChwYXJlbnRUTm9kZSwgJ1BhcmVudCBUTm9kZSBzaG91bGQgYmUgZGVmaW5lZCcpO1xuICAgICAgcGFyZW50VE5vZGUgPSBwYXJlbnRUTm9kZSEucGFyZW50IGFzIFROb2RlIHwgbnVsbDtcbiAgICAgIGlmIChwYXJlbnRUTm9kZSA9PT0gbnVsbCAmJiAhKGZsYWdzICYgSW5qZWN0RmxhZ3MuSG9zdCkpIHtcbiAgICAgICAgcGFyZW50VE5vZGUgPSBnZXREZWNsYXJhdGlvblROb2RlKHBhcmVudExWaWV3KTtcbiAgICAgICAgaWYgKHBhcmVudFROb2RlID09PSBudWxsKSBicmVhaztcblxuICAgICAgICAvLyBJbiB0aGlzIGNhc2UsIGEgcGFyZW50IGV4aXN0cyBhbmQgaXMgZGVmaW5pdGVseSBhbiBlbGVtZW50LiBTbyBpdCB3aWxsIGRlZmluaXRlbHlcbiAgICAgICAgLy8gaGF2ZSBhbiBleGlzdGluZyBsVmlldyBhcyB0aGUgZGVjbGFyYXRpb24gdmlldywgd2hpY2ggaXMgd2h5IHdlIGNhbiBhc3N1bWUgaXQncyBkZWZpbmVkLlxuICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZChwYXJlbnRMVmlldywgJ1BhcmVudCBMVmlldyBzaG91bGQgYmUgZGVmaW5lZCcpO1xuICAgICAgICBwYXJlbnRMVmlldyA9IHBhcmVudExWaWV3W0RFQ0xBUkFUSU9OX1ZJRVddITtcblxuICAgICAgICAvLyBJbiBJdnkgdGhlcmUgYXJlIENvbW1lbnQgbm9kZXMgdGhhdCBjb3JyZXNwb25kIHRvIG5nSWYgYW5kIE5nRm9yIGVtYmVkZGVkIGRpcmVjdGl2ZXNcbiAgICAgICAgLy8gV2Ugd2FudCB0byBza2lwIHRob3NlIGFuZCBsb29rIG9ubHkgYXQgRWxlbWVudHMgYW5kIEVsZW1lbnRDb250YWluZXJzIHRvIGVuc3VyZVxuICAgICAgICAvLyB3ZSdyZSBsb29raW5nIGF0IHRydWUgcGFyZW50IG5vZGVzLCBhbmQgbm90IGNvbnRlbnQgb3Igb3RoZXIgdHlwZXMuXG4gICAgICAgIGlmIChwYXJlbnRUTm9kZS50eXBlICYgKFROb2RlVHlwZS5FbGVtZW50IHwgVE5vZGVUeXBlLkVsZW1lbnRDb250YWluZXIpKSB7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGJyZWFrO1xuICAgICAgfVxuICAgIH1cbiAgICBpZiAocGFyZW50VE5vZGUgPT09IG51bGwpIHtcbiAgICAgIC8vIElmIHdlIGZhaWxlZCB0byBmaW5kIGEgcGFyZW50IFROb2RlIHRoaXMgbWVhbnMgdGhhdCB3ZSBzaG91bGQgdXNlIG1vZHVsZSBpbmplY3Rvci5cbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9IGVsc2Uge1xuICAgICAgdE5vZGUgPSBwYXJlbnRUTm9kZTtcbiAgICAgIGxWaWV3ID0gcGFyZW50TFZpZXc7XG4gICAgfVxuICB9XG5cbiAgbmdEZXZNb2RlICYmIGFzc2VydFROb2RlRm9yTFZpZXcodE5vZGUsIGxWaWV3KTtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUgPSBhbGxvY0xGcmFtZSgpO1xuICBsRnJhbWUuY3VycmVudFROb2RlID0gdE5vZGU7XG4gIGxGcmFtZS5sVmlldyA9IGxWaWV3O1xuXG4gIHJldHVybiB0cnVlO1xufVxuXG4vKipcbiAqIFN3YXAgdGhlIGN1cnJlbnQgbFZpZXcgd2l0aCBhIG5ldyBsVmlldy5cbiAqXG4gKiBGb3IgcGVyZm9ybWFuY2UgcmVhc29ucyB3ZSBzdG9yZSB0aGUgbFZpZXcgaW4gdGhlIHRvcCBsZXZlbCBvZiB0aGUgbW9kdWxlLlxuICogVGhpcyB3YXkgd2UgbWluaW1pemUgdGhlIG51bWJlciBvZiBwcm9wZXJ0aWVzIHRvIHJlYWQuIFdoZW5ldmVyIGEgbmV3IHZpZXdcbiAqIGlzIGVudGVyZWQgd2UgaGF2ZSB0byBzdG9yZSB0aGUgbFZpZXcgZm9yIGxhdGVyLCBhbmQgd2hlbiB0aGUgdmlldyBpc1xuICogZXhpdGVkIHRoZSBzdGF0ZSBoYXMgdG8gYmUgcmVzdG9yZWRcbiAqXG4gKiBAcGFyYW0gbmV3VmlldyBOZXcgbFZpZXcgdG8gYmVjb21lIGFjdGl2ZVxuICogQHJldHVybnMgdGhlIHByZXZpb3VzbHkgYWN0aXZlIGxWaWV3O1xuICovXG5leHBvcnQgZnVuY3Rpb24gZW50ZXJWaWV3KG5ld1ZpZXc6IExWaWV3KTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnROb3RFcXVhbChuZXdWaWV3WzBdLCBuZXdWaWV3WzFdIGFzIGFueSwgJz8/Pz8nKTtcbiAgbmdEZXZNb2RlICYmIGFzc2VydExWaWV3T3JVbmRlZmluZWQobmV3Vmlldyk7XG4gIGNvbnN0IG5ld0xGcmFtZSA9IGFsbG9jTEZyYW1lKCk7XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUuaXNQYXJlbnQsIHRydWUsICdFeHBlY3RlZCBjbGVhbiBMRnJhbWUnKTtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUubFZpZXcsIG51bGwsICdFeHBlY3RlZCBjbGVhbiBMRnJhbWUnKTtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUudFZpZXcsIG51bGwsICdFeHBlY3RlZCBjbGVhbiBMRnJhbWUnKTtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUuc2VsZWN0ZWRJbmRleCwgLTEsICdFeHBlY3RlZCBjbGVhbiBMRnJhbWUnKTtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUuZWxlbWVudERlcHRoQ291bnQsIDAsICdFeHBlY3RlZCBjbGVhbiBMRnJhbWUnKTtcbiAgICBhc3NlcnRFcXVhbChuZXdMRnJhbWUuY3VycmVudERpcmVjdGl2ZUluZGV4LCAtMSwgJ0V4cGVjdGVkIGNsZWFuIExGcmFtZScpO1xuICAgIGFzc2VydEVxdWFsKG5ld0xGcmFtZS5jdXJyZW50TmFtZXNwYWNlLCBudWxsLCAnRXhwZWN0ZWQgY2xlYW4gTEZyYW1lJyk7XG4gICAgYXNzZXJ0RXF1YWwobmV3TEZyYW1lLmJpbmRpbmdSb290SW5kZXgsIC0xLCAnRXhwZWN0ZWQgY2xlYW4gTEZyYW1lJyk7XG4gICAgYXNzZXJ0RXF1YWwobmV3TEZyYW1lLmN1cnJlbnRRdWVyeUluZGV4LCAwLCAnRXhwZWN0ZWQgY2xlYW4gTEZyYW1lJyk7XG4gIH1cbiAgY29uc3QgdFZpZXcgPSBuZXdWaWV3W1RWSUVXXTtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUgPSBuZXdMRnJhbWU7XG4gIG5nRGV2TW9kZSAmJiB0Vmlldy5maXJzdENoaWxkICYmIGFzc2VydFROb2RlRm9yVFZpZXcodFZpZXcuZmlyc3RDaGlsZCwgdFZpZXcpO1xuICBuZXdMRnJhbWUuY3VycmVudFROb2RlID0gdFZpZXcuZmlyc3RDaGlsZCE7XG4gIG5ld0xGcmFtZS5sVmlldyA9IG5ld1ZpZXc7XG4gIG5ld0xGcmFtZS50VmlldyA9IHRWaWV3O1xuICBuZXdMRnJhbWUuY29udGV4dExWaWV3ID0gbmV3VmlldztcbiAgbmV3TEZyYW1lLmJpbmRpbmdJbmRleCA9IHRWaWV3LmJpbmRpbmdTdGFydEluZGV4O1xuICBuZXdMRnJhbWUuaW5JMThuID0gZmFsc2U7XG59XG5cbi8qKlxuICogQWxsb2NhdGVzIG5leHQgZnJlZSBMRnJhbWUuIFRoaXMgZnVuY3Rpb24gdHJpZXMgdG8gcmV1c2UgdGhlIGBMRnJhbWVgcyB0byBsb3dlciBtZW1vcnkgcHJlc3N1cmUuXG4gKi9cbmZ1bmN0aW9uIGFsbG9jTEZyYW1lKCkge1xuICBjb25zdCBjdXJyZW50TEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIGNvbnN0IGNoaWxkTEZyYW1lID0gY3VycmVudExGcmFtZSA9PT0gbnVsbCA/IG51bGwgOiBjdXJyZW50TEZyYW1lLmNoaWxkO1xuICBjb25zdCBuZXdMRnJhbWUgPSBjaGlsZExGcmFtZSA9PT0gbnVsbCA/IGNyZWF0ZUxGcmFtZShjdXJyZW50TEZyYW1lKSA6IGNoaWxkTEZyYW1lO1xuICByZXR1cm4gbmV3TEZyYW1lO1xufVxuXG5mdW5jdGlvbiBjcmVhdGVMRnJhbWUocGFyZW50OiBMRnJhbWV8bnVsbCk6IExGcmFtZSB7XG4gIGNvbnN0IGxGcmFtZTogTEZyYW1lID0ge1xuICAgIGN1cnJlbnRUTm9kZTogbnVsbCxcbiAgICBpc1BhcmVudDogdHJ1ZSxcbiAgICBsVmlldzogbnVsbCEsXG4gICAgdFZpZXc6IG51bGwhLFxuICAgIHNlbGVjdGVkSW5kZXg6IC0xLFxuICAgIGNvbnRleHRMVmlldzogbnVsbCxcbiAgICBlbGVtZW50RGVwdGhDb3VudDogMCxcbiAgICBjdXJyZW50TmFtZXNwYWNlOiBudWxsLFxuICAgIGN1cnJlbnREaXJlY3RpdmVJbmRleDogLTEsXG4gICAgYmluZGluZ1Jvb3RJbmRleDogLTEsXG4gICAgYmluZGluZ0luZGV4OiAtMSxcbiAgICBjdXJyZW50UXVlcnlJbmRleDogMCxcbiAgICBwYXJlbnQ6IHBhcmVudCEsXG4gICAgY2hpbGQ6IG51bGwsXG4gICAgaW5JMThuOiBmYWxzZSxcbiAgfTtcbiAgcGFyZW50ICE9PSBudWxsICYmIChwYXJlbnQuY2hpbGQgPSBsRnJhbWUpOyAgLy8gbGluayB0aGUgbmV3IExGcmFtZSBmb3IgcmV1c2UuXG4gIHJldHVybiBsRnJhbWU7XG59XG5cbi8qKlxuICogQSBsaWdodHdlaWdodCB2ZXJzaW9uIG9mIGxlYXZlIHdoaWNoIGlzIHVzZWQgd2l0aCBESS5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIG9ubHkgcmVzZXRzIGBjdXJyZW50VE5vZGVgIGFuZCBgTFZpZXdgIGFzIHRob3NlIGFyZSB0aGUgb25seSBwcm9wZXJ0aWVzXG4gKiB1c2VkIHdpdGggREkgKGBlbnRlckRJKClgKS5cbiAqXG4gKiBOT1RFOiBUaGlzIGZ1bmN0aW9uIGlzIHJlZXhwb3J0ZWQgYXMgYGxlYXZlRElgLiBIb3dldmVyIGBsZWF2ZURJYCBoYXMgcmV0dXJuIHR5cGUgb2YgYHZvaWRgIHdoZXJlXG4gKiBhcyBgbGVhdmVWaWV3TGlnaHRgIGhhcyBgTEZyYW1lYC4gVGhpcyBpcyBzbyB0aGF0IGBsZWF2ZVZpZXdMaWdodGAgY2FuIGJlIHVzZWQgaW4gYGxlYXZlVmlld2AuXG4gKi9cbmZ1bmN0aW9uIGxlYXZlVmlld0xpZ2h0KCk6IExGcmFtZSB7XG4gIGNvbnN0IG9sZExGcmFtZSA9IGluc3RydWN0aW9uU3RhdGUubEZyYW1lO1xuICBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZSA9IG9sZExGcmFtZS5wYXJlbnQ7XG4gIG9sZExGcmFtZS5jdXJyZW50VE5vZGUgPSBudWxsITtcbiAgb2xkTEZyYW1lLmxWaWV3ID0gbnVsbCE7XG4gIHJldHVybiBvbGRMRnJhbWU7XG59XG5cbi8qKlxuICogVGhpcyBpcyBhIGxpZ2h0d2VpZ2h0IHZlcnNpb24gb2YgdGhlIGBsZWF2ZVZpZXdgIHdoaWNoIGlzIG5lZWRlZCBieSB0aGUgREkgc3lzdGVtLlxuICpcbiAqIE5PVEU6IHRoaXMgZnVuY3Rpb24gaXMgYW4gYWxpYXMgc28gdGhhdCB3ZSBjYW4gY2hhbmdlIHRoZSB0eXBlIG9mIHRoZSBmdW5jdGlvbiB0byBoYXZlIGB2b2lkYFxuICogcmV0dXJuIHR5cGUuXG4gKi9cbmV4cG9ydCBjb25zdCBsZWF2ZURJOiAoKSA9PiB2b2lkID0gbGVhdmVWaWV3TGlnaHQ7XG5cbi8qKlxuICogTGVhdmUgdGhlIGN1cnJlbnQgYExWaWV3YFxuICpcbiAqIFRoaXMgcG9wcyB0aGUgYExGcmFtZWAgd2l0aCB0aGUgYXNzb2NpYXRlZCBgTFZpZXdgIGZyb20gdGhlIHN0YWNrLlxuICpcbiAqIElNUE9SVEFOVDogV2UgbXVzdCB6ZXJvIG91dCB0aGUgYExGcmFtZWAgdmFsdWVzIGhlcmUgb3RoZXJ3aXNlIHRoZXkgd2lsbCBiZSByZXRhaW5lZC4gVGhpcyBpc1xuICogYmVjYXVzZSBmb3IgcGVyZm9ybWFuY2UgcmVhc29ucyB3ZSBkb24ndCByZWxlYXNlIGBMRnJhbWVgIGJ1dCByYXRoZXIga2VlcCBpdCBmb3IgbmV4dCB1c2UuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBsZWF2ZVZpZXcoKSB7XG4gIGNvbnN0IG9sZExGcmFtZSA9IGxlYXZlVmlld0xpZ2h0KCk7XG4gIG9sZExGcmFtZS5pc1BhcmVudCA9IHRydWU7XG4gIG9sZExGcmFtZS50VmlldyA9IG51bGwhO1xuICBvbGRMRnJhbWUuc2VsZWN0ZWRJbmRleCA9IC0xO1xuICBvbGRMRnJhbWUuY29udGV4dExWaWV3ID0gbnVsbDtcbiAgb2xkTEZyYW1lLmVsZW1lbnREZXB0aENvdW50ID0gMDtcbiAgb2xkTEZyYW1lLmN1cnJlbnREaXJlY3RpdmVJbmRleCA9IC0xO1xuICBvbGRMRnJhbWUuY3VycmVudE5hbWVzcGFjZSA9IG51bGw7XG4gIG9sZExGcmFtZS5iaW5kaW5nUm9vdEluZGV4ID0gLTE7XG4gIG9sZExGcmFtZS5iaW5kaW5nSW5kZXggPSAtMTtcbiAgb2xkTEZyYW1lLmN1cnJlbnRRdWVyeUluZGV4ID0gMDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIG5leHRDb250ZXh0SW1wbDxUID0gYW55PihsZXZlbDogbnVtYmVyKTogVCB7XG4gIGNvbnN0IGNvbnRleHRMVmlldyA9IGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmNvbnRleHRMVmlldyA9XG4gICAgICB3YWxrVXBWaWV3cyhsZXZlbCwgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY29udGV4dExWaWV3ISk7XG4gIHJldHVybiBjb250ZXh0TFZpZXdbQ09OVEVYVF0gYXMgdW5rbm93biBhcyBUO1xufVxuXG5mdW5jdGlvbiB3YWxrVXBWaWV3cyhuZXN0aW5nTGV2ZWw6IG51bWJlciwgY3VycmVudFZpZXc6IExWaWV3KTogTFZpZXcge1xuICB3aGlsZSAobmVzdGluZ0xldmVsID4gMCkge1xuICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICBhc3NlcnREZWZpbmVkKFxuICAgICAgICAgICAgY3VycmVudFZpZXdbREVDTEFSQVRJT05fVklFV10sXG4gICAgICAgICAgICAnRGVjbGFyYXRpb24gdmlldyBzaG91bGQgYmUgZGVmaW5lZCBpZiBuZXN0aW5nIGxldmVsIGlzIGdyZWF0ZXIgdGhhbiAwLicpO1xuICAgIGN1cnJlbnRWaWV3ID0gY3VycmVudFZpZXdbREVDTEFSQVRJT05fVklFV10hO1xuICAgIG5lc3RpbmdMZXZlbC0tO1xuICB9XG4gIHJldHVybiBjdXJyZW50Vmlldztcbn1cblxuLyoqXG4gKiBHZXRzIHRoZSBjdXJyZW50bHkgc2VsZWN0ZWQgZWxlbWVudCBpbmRleC5cbiAqXG4gKiBVc2VkIHdpdGgge0BsaW5rIHByb3BlcnR5fSBpbnN0cnVjdGlvbiAoYW5kIG1vcmUgaW4gdGhlIGZ1dHVyZSkgdG8gaWRlbnRpZnkgdGhlIGluZGV4IGluIHRoZVxuICogY3VycmVudCBgTFZpZXdgIHRvIGFjdCBvbi5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldFNlbGVjdGVkSW5kZXgoKSB7XG4gIHJldHVybiBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5zZWxlY3RlZEluZGV4O1xufVxuXG4vKipcbiAqIFNldHMgdGhlIG1vc3QgcmVjZW50IGluZGV4IHBhc3NlZCB0byB7QGxpbmsgc2VsZWN0fVxuICpcbiAqIFVzZWQgd2l0aCB7QGxpbmsgcHJvcGVydHl9IGluc3RydWN0aW9uIChhbmQgbW9yZSBpbiB0aGUgZnV0dXJlKSB0byBpZGVudGlmeSB0aGUgaW5kZXggaW4gdGhlXG4gKiBjdXJyZW50IGBMVmlld2AgdG8gYWN0IG9uLlxuICpcbiAqIChOb3RlIHRoYXQgaWYgYW4gXCJleGl0IGZ1bmN0aW9uXCIgd2FzIHNldCBlYXJsaWVyICh2aWEgYHNldEVsZW1lbnRFeGl0Rm4oKWApIHRoZW4gdGhhdCB3aWxsIGJlXG4gKiBydW4gaWYgYW5kIHdoZW4gdGhlIHByb3ZpZGVkIGBpbmRleGAgdmFsdWUgaXMgZGlmZmVyZW50IGZyb20gdGhlIGN1cnJlbnQgc2VsZWN0ZWQgaW5kZXggdmFsdWUuKVxuICovXG5leHBvcnQgZnVuY3Rpb24gc2V0U2VsZWN0ZWRJbmRleChpbmRleDogbnVtYmVyKSB7XG4gIG5nRGV2TW9kZSAmJiBpbmRleCAhPT0gLTEgJiZcbiAgICAgIGFzc2VydEdyZWF0ZXJUaGFuT3JFcXVhbChpbmRleCwgSEVBREVSX09GRlNFVCwgJ0luZGV4IG11c3QgYmUgcGFzdCBIRUFERVJfT0ZGU0VUIChvciAtMSkuJyk7XG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0TGVzc1RoYW4oXG4gICAgICAgICAgaW5kZXgsIGluc3RydWN0aW9uU3RhdGUubEZyYW1lLmxWaWV3Lmxlbmd0aCwgJ0NhblxcJ3Qgc2V0IGluZGV4IHBhc3NlZCBlbmQgb2YgTFZpZXcnKTtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuc2VsZWN0ZWRJbmRleCA9IGluZGV4O1xufVxuXG4vKipcbiAqIEdldHMgdGhlIGB0Tm9kZWAgdGhhdCByZXByZXNlbnRzIGN1cnJlbnRseSBzZWxlY3RlZCBlbGVtZW50LlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0U2VsZWN0ZWRUTm9kZSgpIHtcbiAgY29uc3QgbEZyYW1lID0gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWU7XG4gIHJldHVybiBnZXRUTm9kZShsRnJhbWUudFZpZXcsIGxGcmFtZS5zZWxlY3RlZEluZGV4KTtcbn1cblxuLyoqXG4gKiBTZXRzIHRoZSBuYW1lc3BhY2UgdXNlZCB0byBjcmVhdGUgZWxlbWVudHMgdG8gYCdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZydgIGluIGdsb2JhbCBzdGF0ZS5cbiAqXG4gKiBAY29kZUdlbkFwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gybXJtW5hbWVzcGFjZVNWRygpIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY3VycmVudE5hbWVzcGFjZSA9IFNWR19OQU1FU1BBQ0U7XG59XG5cbi8qKlxuICogU2V0cyB0aGUgbmFtZXNwYWNlIHVzZWQgdG8gY3JlYXRlIGVsZW1lbnRzIHRvIGAnaHR0cDovL3d3dy53My5vcmcvMTk5OC9NYXRoTUwvJ2AgaW4gZ2xvYmFsIHN0YXRlLlxuICpcbiAqIEBjb2RlR2VuQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtcm1bmFtZXNwYWNlTWF0aE1MKCkge1xuICBpbnN0cnVjdGlvblN0YXRlLmxGcmFtZS5jdXJyZW50TmFtZXNwYWNlID0gTUFUSF9NTF9OQU1FU1BBQ0U7XG59XG5cbi8qKlxuICogU2V0cyB0aGUgbmFtZXNwYWNlIHVzZWQgdG8gY3JlYXRlIGVsZW1lbnRzIHRvIGBudWxsYCwgd2hpY2ggZm9yY2VzIGVsZW1lbnQgY3JlYXRpb24gdG8gdXNlXG4gKiBgY3JlYXRlRWxlbWVudGAgcmF0aGVyIHRoYW4gYGNyZWF0ZUVsZW1lbnROU2AuXG4gKlxuICogQGNvZGVHZW5BcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1ybVuYW1lc3BhY2VIVE1MKCkge1xuICBuYW1lc3BhY2VIVE1MSW50ZXJuYWwoKTtcbn1cblxuLyoqXG4gKiBTZXRzIHRoZSBuYW1lc3BhY2UgdXNlZCB0byBjcmVhdGUgZWxlbWVudHMgdG8gYG51bGxgLCB3aGljaCBmb3JjZXMgZWxlbWVudCBjcmVhdGlvbiB0byB1c2VcbiAqIGBjcmVhdGVFbGVtZW50YCByYXRoZXIgdGhhbiBgY3JlYXRlRWxlbWVudE5TYC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIG5hbWVzcGFjZUhUTUxJbnRlcm5hbCgpIHtcbiAgaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY3VycmVudE5hbWVzcGFjZSA9IG51bGw7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXROYW1lc3BhY2UoKTogc3RyaW5nfG51bGwge1xuICByZXR1cm4gaW5zdHJ1Y3Rpb25TdGF0ZS5sRnJhbWUuY3VycmVudE5hbWVzcGFjZTtcbn1cblxubGV0IF93YXNMYXN0Tm9kZUNyZWF0ZWQgPSB0cnVlO1xuXG4vKipcbiAqIFJldHJpZXZlcyBhIGdsb2JhbCBmbGFnIHRoYXQgaW5kaWNhdGVzIHdoZXRoZXIgdGhlIG1vc3QgcmVjZW50IERPTSBub2RlXG4gKiB3YXMgY3JlYXRlZCBvciBoeWRyYXRlZC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdhc0xhc3ROb2RlQ3JlYXRlZCgpOiBib29sZWFuIHtcbiAgcmV0dXJuIF93YXNMYXN0Tm9kZUNyZWF0ZWQ7XG59XG5cbi8qKlxuICogU2V0cyBhIGdsb2JhbCBmbGFnIHRvIGluZGljYXRlIHdoZXRoZXIgdGhlIG1vc3QgcmVjZW50IERPTSBub2RlXG4gKiB3YXMgY3JlYXRlZCBvciBoeWRyYXRlZC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGxhc3ROb2RlV2FzQ3JlYXRlZChmbGFnOiBib29sZWFuKTogdm9pZCB7XG4gIF93YXNMYXN0Tm9kZUNyZWF0ZWQgPSBmbGFnO1xufVxuIl19