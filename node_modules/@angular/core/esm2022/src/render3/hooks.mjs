/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { setActiveConsumer } from '../signals';
import { assertDefined, assertEqual, assertNotEqual } from '../util/assert';
import { assertFirstCreatePass } from './assert';
import { NgOnChangesFeatureImpl } from './features/ng_onchanges_feature';
import { FLAGS, PREORDER_HOOK_FLAGS } from './interfaces/view';
import { profiler } from './profiler';
import { isInCheckNoChangesMode } from './state';
/**
 * Adds all directive lifecycle hooks from the given `DirectiveDef` to the given `TView`.
 *
 * Must be run *only* on the first template pass.
 *
 * Sets up the pre-order hooks on the provided `tView`,
 * see {@link HookData} for details about the data structure.
 *
 * @param directiveIndex The index of the directive in LView
 * @param directiveDef The definition containing the hooks to setup in tView
 * @param tView The current TView
 */
export function registerPreOrderHooks(directiveIndex, directiveDef, tView) {
    ngDevMode && assertFirstCreatePass(tView);
    const { ngOnChanges, ngOnInit, ngDoCheck } = directiveDef.type.prototype;
    if (ngOnChanges) {
        const wrappedOnChanges = NgOnChangesFeatureImpl(directiveDef);
        (tView.preOrderHooks ??= []).push(directiveIndex, wrappedOnChanges);
        (tView.preOrderCheckHooks ??= []).push(directiveIndex, wrappedOnChanges);
    }
    if (ngOnInit) {
        (tView.preOrderHooks ??= []).push(0 - directiveIndex, ngOnInit);
    }
    if (ngDoCheck) {
        (tView.preOrderHooks ??= []).push(directiveIndex, ngDoCheck);
        (tView.preOrderCheckHooks ??= []).push(directiveIndex, ngDoCheck);
    }
}
/**
 *
 * Loops through the directives on the provided `tNode` and queues hooks to be
 * run that are not initialization hooks.
 *
 * Should be executed during `elementEnd()` and similar to
 * preserve hook execution order. Content, view, and destroy hooks for projected
 * components and directives must be called *before* their hosts.
 *
 * Sets up the content, view, and destroy hooks on the provided `tView`,
 * see {@link HookData} for details about the data structure.
 *
 * NOTE: This does not set up `onChanges`, `onInit` or `doCheck`, those are set up
 * separately at `elementStart`.
 *
 * @param tView The current TView
 * @param tNode The TNode whose directives are to be searched for hooks to queue
 */
export function registerPostOrderHooks(tView, tNode) {
    ngDevMode && assertFirstCreatePass(tView);
    // It's necessary to loop through the directives at elementEnd() (rather than processing in
    // directiveCreate) so we can preserve the current hook order. Content, view, and destroy
    // hooks for projected components and directives must be called *before* their hosts.
    for (let i = tNode.directiveStart, end = tNode.directiveEnd; i < end; i++) {
        const directiveDef = tView.data[i];
        ngDevMode && assertDefined(directiveDef, 'Expecting DirectiveDef');
        const lifecycleHooks = directiveDef.type.prototype;
        const { ngAfterContentInit, ngAfterContentChecked, ngAfterViewInit, ngAfterViewChecked, ngOnDestroy } = lifecycleHooks;
        if (ngAfterContentInit) {
            (tView.contentHooks ??= []).push(-i, ngAfterContentInit);
        }
        if (ngAfterContentChecked) {
            (tView.contentHooks ??= []).push(i, ngAfterContentChecked);
            (tView.contentCheckHooks ??= []).push(i, ngAfterContentChecked);
        }
        if (ngAfterViewInit) {
            (tView.viewHooks ??= []).push(-i, ngAfterViewInit);
        }
        if (ngAfterViewChecked) {
            (tView.viewHooks ??= []).push(i, ngAfterViewChecked);
            (tView.viewCheckHooks ??= []).push(i, ngAfterViewChecked);
        }
        if (ngOnDestroy != null) {
            (tView.destroyHooks ??= []).push(i, ngOnDestroy);
        }
    }
}
/**
 * Executing hooks requires complex logic as we need to deal with 2 constraints.
 *
 * 1. Init hooks (ngOnInit, ngAfterContentInit, ngAfterViewInit) must all be executed once and only
 * once, across many change detection cycles. This must be true even if some hooks throw, or if
 * some recursively trigger a change detection cycle.
 * To solve that, it is required to track the state of the execution of these init hooks.
 * This is done by storing and maintaining flags in the view: the {@link InitPhaseState},
 * and the index within that phase. They can be seen as a cursor in the following structure:
 * [[onInit1, onInit2], [afterContentInit1], [afterViewInit1, afterViewInit2, afterViewInit3]]
 * They are are stored as flags in LView[FLAGS].
 *
 * 2. Pre-order hooks can be executed in batches, because of the select instruction.
 * To be able to pause and resume their execution, we also need some state about the hook's array
 * that is being processed:
 * - the index of the next hook to be executed
 * - the number of init hooks already found in the processed part of the  array
 * They are are stored as flags in LView[PREORDER_HOOK_FLAGS].
 */
/**
 * Executes pre-order check hooks ( OnChanges, DoChanges) given a view where all the init hooks were
 * executed once. This is a light version of executeInitAndCheckPreOrderHooks where we can skip read
 * / write of the init-hooks related flags.
 * @param lView The LView where hooks are defined
 * @param hooks Hooks to be run
 * @param nodeIndex 3 cases depending on the value:
 * - undefined: all hooks from the array should be executed (post-order case)
 * - null: execute hooks only from the saved index until the end of the array (pre-order case, when
 * flushing the remaining hooks)
 * - number: execute hooks only from the saved index until that node index exclusive (pre-order
 * case, when executing select(number))
 */
export function executeCheckHooks(lView, hooks, nodeIndex) {
    callHooks(lView, hooks, 3 /* InitPhaseState.InitPhaseCompleted */, nodeIndex);
}
/**
 * Executes post-order init and check hooks (one of AfterContentInit, AfterContentChecked,
 * AfterViewInit, AfterViewChecked) given a view where there are pending init hooks to be executed.
 * @param lView The LView where hooks are defined
 * @param hooks Hooks to be run
 * @param initPhase A phase for which hooks should be run
 * @param nodeIndex 3 cases depending on the value:
 * - undefined: all hooks from the array should be executed (post-order case)
 * - null: execute hooks only from the saved index until the end of the array (pre-order case, when
 * flushing the remaining hooks)
 * - number: execute hooks only from the saved index until that node index exclusive (pre-order
 * case, when executing select(number))
 */
export function executeInitAndCheckHooks(lView, hooks, initPhase, nodeIndex) {
    ngDevMode &&
        assertNotEqual(initPhase, 3 /* InitPhaseState.InitPhaseCompleted */, 'Init pre-order hooks should not be called more than once');
    if ((lView[FLAGS] & 3 /* LViewFlags.InitPhaseStateMask */) === initPhase) {
        callHooks(lView, hooks, initPhase, nodeIndex);
    }
}
export function incrementInitPhaseFlags(lView, initPhase) {
    ngDevMode &&
        assertNotEqual(initPhase, 3 /* InitPhaseState.InitPhaseCompleted */, 'Init hooks phase should not be incremented after all init hooks have been run.');
    let flags = lView[FLAGS];
    if ((flags & 3 /* LViewFlags.InitPhaseStateMask */) === initPhase) {
        flags &= 4095 /* LViewFlags.IndexWithinInitPhaseReset */;
        flags += 1 /* LViewFlags.InitPhaseStateIncrementer */;
        lView[FLAGS] = flags;
    }
}
/**
 * Calls lifecycle hooks with their contexts, skipping init hooks if it's not
 * the first LView pass
 *
 * @param currentView The current view
 * @param arr The array in which the hooks are found
 * @param initPhaseState the current state of the init phase
 * @param currentNodeIndex 3 cases depending on the value:
 * - undefined: all hooks from the array should be executed (post-order case)
 * - null: execute hooks only from the saved index until the end of the array (pre-order case, when
 * flushing the remaining hooks)
 * - number: execute hooks only from the saved index until that node index exclusive (pre-order
 * case, when executing select(number))
 */
function callHooks(currentView, arr, initPhase, currentNodeIndex) {
    ngDevMode &&
        assertEqual(isInCheckNoChangesMode(), false, 'Hooks should never be run when in check no changes mode.');
    const startIndex = currentNodeIndex !== undefined ?
        (currentView[PREORDER_HOOK_FLAGS] & 65535 /* PreOrderHookFlags.IndexOfTheNextPreOrderHookMaskMask */) :
        0;
    const nodeIndexLimit = currentNodeIndex != null ? currentNodeIndex : -1;
    const max = arr.length - 1; // Stop the loop at length - 1, because we look for the hook at i + 1
    let lastNodeIndexFound = 0;
    for (let i = startIndex; i < max; i++) {
        const hook = arr[i + 1];
        if (typeof hook === 'number') {
            lastNodeIndexFound = arr[i];
            if (currentNodeIndex != null && lastNodeIndexFound >= currentNodeIndex) {
                break;
            }
        }
        else {
            const isInitHook = arr[i] < 0;
            if (isInitHook) {
                currentView[PREORDER_HOOK_FLAGS] += 65536 /* PreOrderHookFlags.NumberOfInitHooksCalledIncrementer */;
            }
            if (lastNodeIndexFound < nodeIndexLimit || nodeIndexLimit == -1) {
                callHook(currentView, initPhase, arr, i);
                currentView[PREORDER_HOOK_FLAGS] =
                    (currentView[PREORDER_HOOK_FLAGS] & 4294901760 /* PreOrderHookFlags.NumberOfInitHooksCalledMask */) + i +
                        2;
            }
            i++;
        }
    }
}
/**
 * Executes a single lifecycle hook, making sure that:
 * - it is called in the non-reactive context;
 * - profiling data are registered.
 */
function callHookInternal(directive, hook) {
    profiler(4 /* ProfilerEvent.LifecycleHookStart */, directive, hook);
    const prevConsumer = setActiveConsumer(null);
    try {
        hook.call(directive);
    }
    finally {
        setActiveConsumer(prevConsumer);
        profiler(5 /* ProfilerEvent.LifecycleHookEnd */, directive, hook);
    }
}
/**
 * Execute one hook against the current `LView`.
 *
 * @param currentView The current view
 * @param initPhaseState the current state of the init phase
 * @param arr The array in which the hooks are found
 * @param i The current index within the hook data array
 */
function callHook(currentView, initPhase, arr, i) {
    const isInitHook = arr[i] < 0;
    const hook = arr[i + 1];
    const directiveIndex = isInitHook ? -arr[i] : arr[i];
    const directive = currentView[directiveIndex];
    if (isInitHook) {
        const indexWithintInitPhase = currentView[FLAGS] >> 12 /* LViewFlags.IndexWithinInitPhaseShift */;
        // The init phase state must be always checked here as it may have been recursively updated.
        if (indexWithintInitPhase <
            (currentView[PREORDER_HOOK_FLAGS] >> 16 /* PreOrderHookFlags.NumberOfInitHooksCalledShift */) &&
            (currentView[FLAGS] & 3 /* LViewFlags.InitPhaseStateMask */) === initPhase) {
            currentView[FLAGS] += 4096 /* LViewFlags.IndexWithinInitPhaseIncrementer */;
            callHookInternal(directive, hook);
        }
    }
    else {
        callHookInternal(directive, hook);
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaG9va3MuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL2hvb2tzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxpQkFBaUIsRUFBQyxNQUFNLFlBQVksQ0FBQztBQUM3QyxPQUFPLEVBQUMsYUFBYSxFQUFFLFdBQVcsRUFBRSxjQUFjLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUUxRSxPQUFPLEVBQUMscUJBQXFCLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFDL0MsT0FBTyxFQUFDLHNCQUFzQixFQUFDLE1BQU0saUNBQWlDLENBQUM7QUFHdkUsT0FBTyxFQUFDLEtBQUssRUFBK0MsbUJBQW1CLEVBQTJCLE1BQU0sbUJBQW1CLENBQUM7QUFDcEksT0FBTyxFQUFDLFFBQVEsRUFBZ0IsTUFBTSxZQUFZLENBQUM7QUFDbkQsT0FBTyxFQUFDLHNCQUFzQixFQUFDLE1BQU0sU0FBUyxDQUFDO0FBSS9DOzs7Ozs7Ozs7OztHQVdHO0FBQ0gsTUFBTSxVQUFVLHFCQUFxQixDQUNqQyxjQUFzQixFQUFFLFlBQStCLEVBQUUsS0FBWTtJQUN2RSxTQUFTLElBQUkscUJBQXFCLENBQUMsS0FBSyxDQUFDLENBQUM7SUFDMUMsTUFBTSxFQUFDLFdBQVcsRUFBRSxRQUFRLEVBQUUsU0FBUyxFQUFDLEdBQ3BDLFlBQVksQ0FBQyxJQUFJLENBQUMsU0FBeUMsQ0FBQztJQUVoRSxJQUFJLFdBQW1DLEVBQUU7UUFDdkMsTUFBTSxnQkFBZ0IsR0FBRyxzQkFBc0IsQ0FBQyxZQUFZLENBQUMsQ0FBQztRQUM5RCxDQUFDLEtBQUssQ0FBQyxhQUFhLEtBQUssRUFBRSxDQUFDLENBQUMsSUFBSSxDQUFDLGNBQWMsRUFBRSxnQkFBZ0IsQ0FBQyxDQUFDO1FBQ3BFLENBQUMsS0FBSyxDQUFDLGtCQUFrQixLQUFLLEVBQUUsQ0FBQyxDQUFDLElBQUks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bnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7QWZ0ZXJDb250ZW50Q2hlY2tlZCwgQWZ0ZXJDb250ZW50SW5pdCwgQWZ0ZXJWaWV3Q2hlY2tlZCwgQWZ0ZXJWaWV3SW5pdCwgRG9DaGVjaywgT25DaGFuZ2VzLCBPbkRlc3Ryb3ksIE9uSW5pdH0gZnJvbSAnLi4vaW50ZXJmYWNlL2xpZmVjeWNsZV9ob29rcyc7XG5pbXBvcnQge3NldEFjdGl2ZUNvbnN1bWVyfSBmcm9tICcuLi9zaWduYWxzJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZCwgYXNzZXJ0RXF1YWwsIGFzc2VydE5vdEVxdWFsfSBmcm9tICcuLi91dGlsL2Fzc2VydCc7XG5cbmltcG9ydCB7YXNzZXJ0Rmlyc3RDcmVhdGVQYXNzfSBmcm9tICcuL2Fzc2VydCc7XG5pbXBvcnQge05nT25DaGFuZ2VzRmVhdHVyZUltcGx9IGZyb20gJy4vZmVhdHVyZXMvbmdfb25jaGFuZ2VzX2ZlYXR1cmUnO1xuaW1wb3J0IHtEaXJlY3RpdmVEZWZ9IGZyb20gJy4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7VE5vZGV9IGZyb20gJy4vaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7RkxBR1MsIEhvb2tEYXRhLCBJbml0UGhhc2VTdGF0ZSwgTFZpZXcsIExWaWV3RmxhZ3MsIFBSRU9SREVSX0hPT0tfRkxBR1MsIFByZU9yZGVySG9va0ZsYWdzLCBUVmlld30gZnJvbSAnLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtwcm9maWxlciwgUHJvZmlsZXJFdmVudH0gZnJvbSAnLi9wcm9maWxlcic7XG5pbXBvcnQge2lzSW5DaGVja05vQ2hhbmdlc01vZGV9IGZyb20gJy4vc3RhdGUnO1xuXG5cblxuLyoqXG4gKiBBZGRzIGFsbCBkaXJlY3RpdmUgbGlmZWN5Y2xlIGhvb2tzIGZyb20gdGhlIGdpdmVuIGBEaXJlY3RpdmVEZWZgIHRvIHRoZSBnaXZlbiBgVFZpZXdgLlxuICpcbiAqIE11c3QgYmUgcnVuICpvbmx5KiBvbiB0aGUgZmlyc3QgdGVtcGxhdGUgcGFzcy5cbiAqXG4gKiBTZXRzIHVwIHRoZSBwcmUtb3JkZXIgaG9va3Mgb24gdGhlIHByb3ZpZGVkIGB0Vmlld2AsXG4gKiBzZWUge0BsaW5rIEhvb2tEYXRhfSBmb3IgZGV0YWlscyBhYm91dCB0aGUgZGF0YSBzdHJ1Y3R1cmUuXG4gKlxuICogQHBhcmFtIGRpcmVjdGl2ZUluZGV4IFRoZSBpbmRleCBvZiB0aGUgZGlyZWN0aXZlIGluIExWaWV3XG4gKiBAcGFyYW0gZGlyZWN0aXZlRGVmIFRoZSBkZWZpbml0aW9uIGNvbnRhaW5pbmcgdGhlIGhvb2tzIHRvIHNldHVwIGluIHRWaWV3XG4gKiBAcGFyYW0gdFZpZXcgVGhlIGN1cnJlbnQgVFZpZXdcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlZ2lzdGVyUHJlT3JkZXJIb29rcyhcbiAgICBkaXJlY3RpdmVJbmRleDogbnVtYmVyLCBkaXJlY3RpdmVEZWY6IERpcmVjdGl2ZURlZjxhbnk+LCB0VmlldzogVFZpZXcpOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEZpcnN0Q3JlYXRlUGFzcyh0Vmlldyk7XG4gIGNvbnN0IHtuZ09uQ2hhbmdlcywgbmdPbkluaXQsIG5nRG9DaGVja30gPVxuICAgICAgZGlyZWN0aXZlRGVmLnR5cGUucHJvdG90eXBlIGFzIE9uQ2hhbmdlcyAmIE9uSW5pdCAmIERvQ2hlY2s7XG5cbiAgaWYgKG5nT25DaGFuZ2VzIGFzIEZ1bmN0aW9uIHwgdW5kZWZpbmVkKSB7XG4gICAgY29uc3Qgd3JhcHBlZE9uQ2hhbmdlcyA9IE5nT25DaGFuZ2VzRmVhdHVyZUltcGwoZGlyZWN0aXZlRGVmKTtcbiAgICAodFZpZXcucHJlT3JkZXJIb29rcyA/Pz0gW10pLnB1c2goZGlyZWN0aXZlSW5kZXgsIHdyYXBwZWRPbkNoYW5nZXMpO1xuICAgICh0Vmlldy5wcmVPcmRlckNoZWNrSG9va3MgPz89IFtdKS5wdXNoKGRpcmVjdGl2ZUluZGV4LCB3cmFwcGVkT25DaGFuZ2VzKTtcbiAgfVxuXG4gIGlmIChuZ09uSW5pdCkge1xuICAgICh0Vmlldy5wcmVPcmRlckhvb2tzID8/PSBbXSkucHVzaCgwIC0gZGlyZWN0aXZlSW5kZXgsIG5nT25Jbml0KTtcbiAgfVxuXG4gIGlmIChuZ0RvQ2hlY2spIHtcbiAgICAodFZpZXcucHJlT3JkZXJIb29rcyA/Pz0gW10pLnB1c2goZGlyZWN0aXZlSW5kZXgsIG5nRG9DaGVjayk7XG4gICAgKHRWaWV3LnByZU9yZGVyQ2hlY2tIb29rcyA/Pz0gW10pLnB1c2goZGlyZWN0aXZlSW5kZXgsIG5nRG9DaGVjayk7XG4gIH1cbn1cblxuLyoqXG4gKlxuICogTG9vcHMgdGhyb3VnaCB0aGUgZGlyZWN0aXZlcyBvbiB0aGUgcHJvdmlkZWQgYHROb2RlYCBhbmQgcXVldWVzIGhvb2tzIHRvIGJlXG4gKiBydW4gdGhhdCBhcmUgbm90IGluaXRpYWxpemF0aW9uIGhvb2tzLlxuICpcbiAqIFNob3VsZCBiZSBleGVjdXRlZCBkdXJpbmcgYGVsZW1lbnRFbmQoKWAgYW5kIHNpbWlsYXIgdG9cbiAqIHByZXNlcnZlIGhvb2sgZXhlY3V0aW9uIG9yZGVyLiBDb250ZW50LCB2aWV3LCBhbmQgZGVzdHJveSBob29rcyBmb3IgcHJvamVjdGVkXG4gKiBjb21wb25lbnRzIGFuZCBkaXJlY3RpdmVzIG11c3QgYmUgY2FsbGVkICpiZWZvcmUqIHRoZWlyIGhvc3RzLlxuICpcbiAqIFNldHMgdXAgdGhlIGNvbnRlbnQsIHZpZXcsIGFuZCBkZXN0cm95IGhvb2tzIG9uIHRoZSBwcm92aWRlZCBgdFZpZXdgLFxuICogc2VlIHtAbGluayBIb29rRGF0YX0gZm9yIGRldGFpbHMgYWJvdXQgdGhlIGRhdGEgc3RydWN0dXJlLlxuICpcbiAqIE5PVEU6IFRoaXMgZG9lcyBub3Qgc2V0IHVwIGBvbkNoYW5nZXNgLCBgb25Jbml0YCBvciBgZG9DaGVja2AsIHRob3NlIGFyZSBzZXQgdXBcbiAqIHNlcGFyYXRlbHkgYXQgYGVsZW1lbnRTdGFydGAuXG4gKlxuICogQHBhcmFtIHRWaWV3IFRoZSBjdXJyZW50IFRWaWV3XG4gKiBAcGFyYW0gdE5vZGUgVGhlIFROb2RlIHdob3NlIGRpcmVjdGl2ZXMgYXJlIHRvIGJlIHNlYXJjaGVkIGZvciBob29rcyB0byBxdWV1ZVxuICovXG5leHBvcnQgZnVuY3Rpb24gcmVnaXN0ZXJQb3N0T3JkZXJIb29rcyh0VmlldzogVFZpZXcsIHROb2RlOiBUTm9kZSk6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0Rmlyc3RDcmVhdGVQYXNzKHRWaWV3KTtcbiAgLy8gSXQncyBuZWNlc3NhcnkgdG8gbG9vcCB0aHJvdWdoIHRoZSBkaXJlY3RpdmVzIGF0IGVsZW1lbnRFbmQoKSAocmF0aGVyIHRoYW4gcHJvY2Vzc2luZyBpblxuICAvLyBkaXJlY3RpdmVDcmVhdGUpIHNvIHdlIGNhbiBwcmVzZXJ2ZSB0aGUgY3VycmVudCBob29rIG9yZGVyLiBDb250ZW50LCB2aWV3LCBhbmQgZGVzdHJveVxuICAvLyBob29rcyBmb3IgcHJvamVjdGVkIGNvbXBvbmVudHMgYW5kIGRpcmVjdGl2ZXMgbXVzdCBiZSBjYWxsZWQgKmJlZm9yZSogdGhlaXIgaG9zdHMuXG4gIGZvciAobGV0IGkgPSB0Tm9kZS5kaXJlY3RpdmVTdGFydCwgZW5kID0gdE5vZGUuZGlyZWN0aXZlRW5kOyBpIDwgZW5kOyBpKyspIHtcbiAgICBjb25zdCBkaXJlY3RpdmVEZWYgPSB0Vmlldy5kYXRhW2ldIGFzIERpcmVjdGl2ZURlZjxhbnk+O1xuICAgIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGRpcmVjdGl2ZURlZiwgJ0V4cGVjdGluZyBEaXJlY3RpdmVEZWYnKTtcbiAgICBjb25zdCBsaWZlY3ljbGVIb29rczogQWZ0ZXJDb250ZW50SW5pdCZBZnRlckNvbnRlbnRDaGVja2VkJkFmdGVyVmlld0luaXQmQWZ0ZXJWaWV3Q2hlY2tlZCZcbiAgICAgICAgT25EZXN0cm95ID0gZGlyZWN0aXZlRGVmLnR5cGUucHJvdG90eXBlO1xuICAgIGNvbnN0IHtcbiAgICAgIG5nQWZ0ZXJDb250ZW50SW5pdCxcbiAgICAgIG5nQWZ0ZXJDb250ZW50Q2hlY2tlZCxcbiAgICAgIG5nQWZ0ZXJWaWV3SW5pdCxcbiAgICAgIG5nQWZ0ZXJWaWV3Q2hlY2tlZCxcbiAgICAgIG5nT25EZXN0cm95XG4gICAgfSA9IGxpZmVjeWNsZUhvb2tzO1xuXG4gICAgaWYgKG5nQWZ0ZXJDb250ZW50SW5pdCkge1xuICAgICAgKHRWaWV3LmNvbnRlbnRIb29rcyA/Pz0gW10pLnB1c2goLWksIG5nQWZ0ZXJDb250ZW50SW5pdCk7XG4gICAgfVxuXG4gICAgaWYgKG5nQWZ0ZXJDb250ZW50Q2hlY2tlZCkge1xuICAgICAgKHRWaWV3LmNvbnRlbnRIb29rcyA/Pz0gW10pLnB1c2goaSwgbmdBZnRlckNvbnRlbnRDaGVja2VkKTtcbiAgICAgICh0Vmlldy5jb250ZW50Q2hlY2tIb29rcyA/Pz0gW10pLnB1c2goaSwgbmdBZnRlckNvbnRlbnRDaGVja2VkKTtcbiAgICB9XG5cbiAgICBpZiAobmdBZnRlclZpZXdJbml0KSB7XG4gICAgICAodFZpZXcudmlld0hvb2tzID8/PSBbXSkucHVzaCgtaSwgbmdBZnRlclZpZXdJbml0KTtcbiAgICB9XG5cbiAgICBpZiAobmdBZnRlclZpZXdDaGVja2VkKSB7XG4gICAgICAodFZpZXcudmlld0hvb2tzID8/PSBbXSkucHVzaChpLCBuZ0FmdGVyVmlld0NoZWNrZWQpO1xuICAgICAgKHRWaWV3LnZpZXdDaGVja0hvb2tzID8/PSBbXSkucHVzaChpLCBuZ0FmdGVyVmlld0NoZWNrZWQpO1xuICAgIH1cblxuICAgIGlmIChuZ09uRGVzdHJveSAhPSBudWxsKSB7XG4gICAgICAodFZpZXcuZGVzdHJveUhvb2tzID8/PSBbXSkucHVzaChpLCBuZ09uRGVzdHJveSk7XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogRXhlY3V0aW5nIGhvb2tzIHJlcXVpcmVzIGNvbXBsZXggbG9naWMgYXMgd2UgbmVlZCB0byBkZWFsIHdpdGggMiBjb25zdHJhaW50cy5cbiAqXG4gKiAxLiBJbml0IGhvb2tzIChuZ09uSW5pdCwgbmdBZnRlckNvbnRlbnRJbml0LCBuZ0FmdGVyVmlld0luaXQpIG11c3QgYWxsIGJlIGV4ZWN1dGVkIG9uY2UgYW5kIG9ubHlcbiAqIG9uY2UsIGFjcm9zcyBtYW55IGNoYW5nZSBkZXRlY3Rpb24gY3ljbGVzLiBUaGlzIG11c3QgYmUgdHJ1ZSBldmVuIGlmIHNvbWUgaG9va3MgdGhyb3csIG9yIGlmXG4gKiBzb21lIHJlY3Vyc2l2ZWx5IHRyaWdnZXIgYSBjaGFuZ2UgZGV0ZWN0aW9uIGN5Y2xlLlxuICogVG8gc29sdmUgdGhhdCwgaXQgaXMgcmVxdWlyZWQgdG8gdHJhY2sgdGhlIHN0YXRlIG9mIHRoZSBleGVjdXRpb24gb2YgdGhlc2UgaW5pdCBob29rcy5cbiAqIFRoaXMgaXMgZG9uZSBieSBzdG9yaW5nIGFuZCBtYWludGFpbmluZyBmbGFncyBpbiB0aGUgdmlldzogdGhlIHtAbGluayBJbml0UGhhc2VTdGF0ZX0sXG4gKiBhbmQgdGhlIGluZGV4IHdpdGhpbiB0aGF0IHBoYXNlLiBUaGV5IGNhbiBiZSBzZWVuIGFzIGEgY3Vyc29yIGluIHRoZSBmb2xsb3dpbmcgc3RydWN0dXJlOlxuICogW1tvbkluaXQxLCBvbkluaXQyXSwgW2FmdGVyQ29udGVudEluaXQxXSwgW2FmdGVyVmlld0luaXQxLCBhZnRlclZpZXdJbml0MiwgYWZ0ZXJWaWV3SW5pdDNdXVxuICogVGhleSBhcmUgYXJlIHN0b3JlZCBhcyBmbGFncyBpbiBMVmlld1tGTEFHU10uXG4gKlxuICogMi4gUHJlLW9yZGVyIGhvb2tzIGNhbiBiZSBleGVjdXRlZCBpbiBiYXRjaGVzLCBiZWNhdXNlIG9mIHRoZSBzZWxlY3QgaW5zdHJ1Y3Rpb24uXG4gKiBUbyBiZSBhYmxlIHRvIHBhdXNlIGFuZCByZXN1bWUgdGhlaXIgZXhlY3V0aW9uLCB3ZSBhbHNvIG5lZWQgc29tZSBzdGF0ZSBhYm91dCB0aGUgaG9vaydzIGFycmF5XG4gKiB0aGF0IGlzIGJlaW5nIHByb2Nlc3NlZDpcbiAqIC0gdGhlIGluZGV4IG9mIHRoZSBuZXh0IGhvb2sgdG8gYmUgZXhlY3V0ZWRcbiAqIC0gdGhlIG51bWJlciBvZiBpbml0IGhvb2tzIGFscmVhZHkgZm91bmQgaW4gdGhlIHByb2Nlc3NlZCBwYXJ0IG9mIHRoZSAgYXJyYXlcbiAqIFRoZXkgYXJlIGFyZSBzdG9yZWQgYXMgZmxhZ3MgaW4gTFZpZXdbUFJFT1JERVJfSE9PS19GTEFHU10uXG4gKi9cblxuXG4vKipcbiAqIEV4ZWN1dGVzIHByZS1vcmRlciBjaGVjayBob29rcyAoIE9uQ2hhbmdlcywgRG9DaGFuZ2VzKSBnaXZlbiBhIHZpZXcgd2hlcmUgYWxsIHRoZSBpbml0IGhvb2tzIHdlcmVcbiAqIGV4ZWN1dGVkIG9uY2UuIFRoaXMgaXMgYSBsaWdodCB2ZXJzaW9uIG9mIGV4ZWN1dGVJbml0QW5kQ2hlY2tQcmVPcmRlckhvb2tzIHdoZXJlIHdlIGNhbiBza2lwIHJlYWRcbiAqIC8gd3JpdGUgb2YgdGhlIGluaXQtaG9va3MgcmVsYXRlZCBmbGFncy5cbiAqIEBwYXJhbSBsVmlldyBUaGUgTFZpZXcgd2hlcmUgaG9va3MgYXJlIGRlZmluZWRcbiAqIEBwYXJhbSBob29rcyBIb29rcyB0byBiZSBydW5cbiAqIEBwYXJhbSBub2RlSW5kZXggMyBjYXNlcyBkZXBlbmRpbmcgb24gdGhlIHZhbHVlOlxuICogLSB1bmRlZmluZWQ6IGFsbCBob29rcyBmcm9tIHRoZSBhcnJheSBzaG91bGQgYmUgZXhlY3V0ZWQgKHBvc3Qtb3JkZXIgY2FzZSlcbiAqIC0gbnVsbDogZXhlY3V0ZSBob29rcyBvbmx5IGZyb20gdGhlIHNhdmVkIGluZGV4IHVudGlsIHRoZSBlbmQgb2YgdGhlIGFycmF5IChwcmUtb3JkZXIgY2FzZSwgd2hlblxuICogZmx1c2hpbmcgdGhlIHJlbWFpbmluZyBob29rcylcbiAqIC0gbnVtYmVyOiBleGVjdXRlIGhvb2tzIG9ubHkgZnJvbSB0aGUgc2F2ZWQgaW5kZXggdW50aWwgdGhhdCBub2RlIGluZGV4IGV4Y2x1c2l2ZSAocHJlLW9yZGVyXG4gKiBjYXNlLCB3aGVuIGV4ZWN1dGluZyBzZWxlY3QobnVtYmVyKSlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGV4ZWN1dGVDaGVja0hvb2tzKGxWaWV3OiBMVmlldywgaG9va3M6IEhvb2tEYXRhLCBub2RlSW5kZXg/OiBudW1iZXJ8bnVsbCkge1xuICBjYWxsSG9va3MobFZpZXcsIGhvb2tzLCBJbml0UGhhc2VTdGF0ZS5Jbml0UGhhc2VDb21wbGV0ZWQsIG5vZGVJbmRleCk7XG59XG5cbi8qKlxuICogRXhlY3V0ZXMgcG9zdC1vcmRlciBpbml0IGFuZCBjaGVjayBob29rcyAob25lIG9mIEFmdGVyQ29udGVudEluaXQsIEFmdGVyQ29udGVudENoZWNrZWQsXG4gKiBBZnRlclZpZXdJbml0LCBBZnRlclZpZXdDaGVja2VkKSBnaXZlbiBhIHZpZXcgd2hlcmUgdGhlcmUgYXJlIHBlbmRpbmcgaW5pdCBob29rcyB0byBiZSBleGVjdXRlZC5cbiAqIEBwYXJhbSBsVmlldyBUaGUgTFZpZXcgd2hlcmUgaG9va3MgYXJlIGRlZmluZWRcbiAqIEBwYXJhbSBob29rcyBIb29rcyB0byBiZSBydW5cbiAqIEBwYXJhbSBpbml0UGhhc2UgQSBwaGFzZSBmb3Igd2hpY2ggaG9va3Mgc2hvdWxkIGJlIHJ1blxuICogQHBhcmFtIG5vZGVJbmRleCAzIGNhc2VzIGRlcGVuZGluZyBvbiB0aGUgdmFsdWU6XG4gKiAtIHVuZGVmaW5lZDogYWxsIGhvb2tzIGZyb20gdGhlIGFycmF5IHNob3VsZCBiZSBleGVjdXRlZCAocG9zdC1vcmRlciBjYXNlKVxuICogLSBudWxsOiBleGVjdXRlIGhvb2tzIG9ubHkgZnJvbSB0aGUgc2F2ZWQgaW5kZXggdW50aWwgdGhlIGVuZCBvZiB0aGUgYXJyYXkgKHByZS1vcmRlciBjYXNlLCB3aGVuXG4gKiBmbHVzaGluZyB0aGUgcmVtYWluaW5nIGhvb2tzKVxuICogLSBudW1iZXI6IGV4ZWN1dGUgaG9va3Mgb25seSBmcm9tIHRoZSBzYXZlZCBpbmRleCB1bnRpbCB0aGF0IG5vZGUgaW5kZXggZXhjbHVzaXZlIChwcmUtb3JkZXJcbiAqIGNhc2UsIHdoZW4gZXhlY3V0aW5nIHNlbGVjdChudW1iZXIpKVxuICovXG5leHBvcnQgZnVuY3Rpb24gZXhlY3V0ZUluaXRBbmRDaGVja0hvb2tzKFxuICAgIGxWaWV3OiBMVmlldywgaG9va3M6IEhvb2tEYXRhLCBpbml0UGhhc2U6IEluaXRQaGFzZVN0YXRlLCBub2RlSW5kZXg/OiBudW1iZXJ8bnVsbCkge1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydE5vdEVxdWFsKFxuICAgICAgICAgIGluaXRQaGFzZSwgSW5pdFBoYXNlU3RhdGUuSW5pdFBoYXNlQ29tcGxldGVkLFxuICAgICAgICAgICdJbml0IHByZS1vcmRlciBob29rcyBzaG91bGQgbm90IGJlIGNhbGxlZCBtb3JlIHRoYW4gb25jZScpO1xuICBpZiAoKGxWaWV3W0ZMQUdTXSAmIExWaWV3RmxhZ3MuSW5pdFBoYXNlU3RhdGVNYXNrKSA9PT0gaW5pdFBoYXNlKSB7XG4gICAgY2FsbEhvb2tzKGxWaWV3LCBob29rcywgaW5pdFBoYXNlLCBub2RlSW5kZXgpO1xuICB9XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpbmNyZW1lbnRJbml0UGhhc2VGbGFncyhsVmlldzogTFZpZXcsIGluaXRQaGFzZTogSW5pdFBoYXNlU3RhdGUpOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmXG4gICAgICBhc3NlcnROb3RFcXVhbChcbiAgICAgICAgICBpbml0UGhhc2UsIEluaXRQaGFzZVN0YXRlLkluaXRQaGFzZUNvbXBsZXRlZCxcbiAgICAgICAgICAnSW5pdCBob29rcyBwaGFzZSBzaG91bGQgbm90IGJlIGluY3JlbWVudGVkIGFmdGVyIGFsbCBpbml0IGhvb2tzIGhhdmUgYmVlbiBydW4uJyk7XG4gIGxldCBmbGFncyA9IGxWaWV3W0ZMQUdTXTtcbiAgaWYgKChmbGFncyAmIExWaWV3RmxhZ3MuSW5pdFBoYXNlU3RhdGVNYXNrKSA9PT0gaW5pdFBoYXNlKSB7XG4gICAgZmxhZ3MgJj0gTFZpZXdGbGFncy5JbmRleFdpdGhpbkluaXRQaGFzZVJlc2V0O1xuICAgIGZsYWdzICs9IExWaWV3RmxhZ3MuSW5pdFBoYXNlU3RhdGVJbmNyZW1lbnRlcjtcbiAgICBsVmlld1tGTEFHU10gPSBmbGFncztcbiAgfVxufVxuXG4vKipcbiAqIENhbGxzIGxpZmVjeWNsZSBob29rcyB3aXRoIHRoZWlyIGNvbnRleHRzLCBza2lwcGluZyBpbml0IGhvb2tzIGlmIGl0J3Mgbm90XG4gKiB0aGUgZmlyc3QgTFZpZXcgcGFzc1xuICpcbiAqIEBwYXJhbSBjdXJyZW50VmlldyBUaGUgY3VycmVudCB2aWV3XG4gKiBAcGFyYW0gYXJyIFRoZSBhcnJheSBpbiB3aGljaCB0aGUgaG9va3MgYXJlIGZvdW5kXG4gKiBAcGFyYW0gaW5pdFBoYXNlU3RhdGUgdGhlIGN1cnJlbnQgc3RhdGUgb2YgdGhlIGluaXQgcGhhc2VcbiAqIEBwYXJhbSBjdXJyZW50Tm9kZUluZGV4IDMgY2FzZXMgZGVwZW5kaW5nIG9uIHRoZSB2YWx1ZTpcbiAqIC0gdW5kZWZpbmVkOiBhbGwgaG9va3MgZnJvbSB0aGUgYXJyYXkgc2hvdWxkIGJlIGV4ZWN1dGVkIChwb3N0LW9yZGVyIGNhc2UpXG4gKiAtIG51bGw6IGV4ZWN1dGUgaG9va3Mgb25seSBmcm9tIHRoZSBzYXZlZCBpbmRleCB1bnRpbCB0aGUgZW5kIG9mIHRoZSBhcnJheSAocHJlLW9yZGVyIGNhc2UsIHdoZW5cbiAqIGZsdXNoaW5nIHRoZSByZW1haW5pbmcgaG9va3MpXG4gKiAtIG51bWJlcjogZXhlY3V0ZSBob29rcyBvbmx5IGZyb20gdGhlIHNhdmVkIGluZGV4IHVudGlsIHRoYXQgbm9kZSBpbmRleCBleGNsdXNpdmUgKHByZS1vcmRlclxuICogY2FzZSwgd2hlbiBleGVjdXRpbmcgc2VsZWN0KG51bWJlcikpXG4gKi9cbmZ1bmN0aW9uIGNhbGxIb29rcyhcbiAgICBjdXJyZW50VmlldzogTFZpZXcsIGFycjogSG9va0RhdGEsIGluaXRQaGFzZTogSW5pdFBoYXNlU3RhdGUsXG4gICAgY3VycmVudE5vZGVJbmRleDogbnVtYmVyfG51bGx8dW5kZWZpbmVkKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0RXF1YWwoXG4gICAgICAgICAgaXNJbkNoZWNrTm9DaGFuZ2VzTW9kZSgpLCBmYWxzZSxcbiAgICAgICAgICAnSG9va3Mgc2hvdWxkIG5ldmVyIGJlIHJ1biB3aGVuIGluIGNoZWNrIG5vIGNoYW5nZXMgbW9kZS4nKTtcbiAgY29uc3Qgc3RhcnRJbmRleCA9IGN1cnJlbnROb2RlSW5kZXggIT09IHVuZGVmaW5lZCA/XG4gICAgICAoY3VycmVudFZpZXdbUFJFT1JERVJfSE9PS19GTEFHU10gJiBQcmVPcmRlckhvb2tGbGFncy5JbmRleE9mVGhlTmV4dFByZU9yZGVySG9va01hc2tNYXNrKSA6XG4gICAgICAwO1xuICBjb25zdCBub2RlSW5kZXhMaW1pdCA9IGN1cnJlbnROb2RlSW5kZXggIT0gbnVsbCA/IGN1cnJlbnROb2RlSW5kZXggOiAtMTtcbiAgY29uc3QgbWF4ID0gYXJyLmxlbmd0aCAtIDE7ICAvLyBTdG9wIHRoZSBsb29wIGF0IGxlbmd0aCAtIDEsIGJlY2F1c2Ugd2UgbG9vayBmb3IgdGhlIGhvb2sgYXQgaSArIDFcbiAgbGV0IGxhc3ROb2RlSW5kZXhGb3VuZCA9IDA7XG4gIGZvciAobGV0IGkgPSBzdGFydEluZGV4OyBpIDwgbWF4OyBpKyspIHtcbiAgICBjb25zdCBob29rID0gYXJyW2kgKyAxXSBhcyBudW1iZXIgfCAoKCkgPT4gdm9pZCk7XG4gICAgaWYgKHR5cGVvZiBob29rID09PSAnbnVtYmVyJykge1xuICAgICAgbGFzdE5vZGVJbmRleEZvdW5kID0gYXJyW2ldIGFzIG51bWJlcjtcbiAgICAgIGlmIChjdXJyZW50Tm9kZUluZGV4ICE9IG51bGwgJiYgbGFzdE5vZGVJbmRleEZvdW5kID49IGN1cnJlbnROb2RlSW5kZXgpIHtcbiAgICAgICAgYnJlYWs7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIGNvbnN0IGlzSW5pdEhvb2sgPSAoYXJyW2ldIGFzIG51bWJlcikgPCAwO1xuICAgICAgaWYgKGlzSW5pdEhvb2spIHtcbiAgICAgICAgY3VycmVudFZpZXdbUFJFT1JERVJfSE9PS19GTEFHU10gKz0gUHJlT3JkZXJIb29rRmxhZ3MuTnVtYmVyT2ZJbml0SG9va3NDYWxsZWRJbmNyZW1lbnRlcjtcbiAgICAgIH1cbiAgICAgIGlmIChsYXN0Tm9kZUluZGV4Rm91bmQgPCBub2RlSW5kZXhMaW1pdCB8fCBub2RlSW5kZXhMaW1pdCA9PSAtMSkge1xuICAgICAgICBjYWxsSG9vayhjdXJyZW50VmlldywgaW5pdFBoYXNlLCBhcnIsIGkpO1xuICAgICAgICBjdXJyZW50Vmlld1tQUkVPUkRFUl9IT09LX0ZMQUdTXSA9XG4gICAgICAgICAgICAoY3VycmVudFZpZXdbUFJFT1JERVJfSE9PS19GTEFHU10gJiBQcmVPcmRlckhvb2tGbGFncy5OdW1iZXJPZkluaXRIb29rc0NhbGxlZE1hc2spICsgaSArXG4gICAgICAgICAgICAyO1xuICAgICAgfVxuICAgICAgaSsrO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEV4ZWN1dGVzIGEgc2luZ2xlIGxpZmVjeWNsZSBob29rLCBtYWtpbmcgc3VyZSB0aGF0OlxuICogLSBpdCBpcyBjYWxsZWQgaW4gdGhlIG5vbi1yZWFjdGl2ZSBjb250ZXh0O1xuICogLSBwcm9maWxpbmcgZGF0YSBhcmUgcmVnaXN0ZXJlZC5cbiAqL1xuZnVuY3Rpb24gY2FsbEhvb2tJbnRlcm5hbChkaXJlY3RpdmU6IGFueSwgaG9vazogKCkgPT4gdm9pZCkge1xuICBwcm9maWxlcihQcm9maWxlckV2ZW50LkxpZmVjeWNsZUhvb2tTdGFydCwgZGlyZWN0aXZlLCBob29rKTtcbiAgY29uc3QgcHJldkNvbnN1bWVyID0gc2V0QWN0aXZlQ29uc3VtZXIobnVsbCk7XG4gIHRyeSB7XG4gICAgaG9vay5jYWxsKGRpcmVjdGl2ZSk7XG4gIH0gZmluYWxseSB7XG4gICAgc2V0QWN0aXZlQ29uc3VtZXIocHJldkNvbnN1bWVyKTtcbiAgICBwcm9maWxlcihQcm9maWxlckV2ZW50LkxpZmVjeWNsZUhvb2tFbmQsIGRpcmVjdGl2ZSwgaG9vayk7XG4gIH1cbn1cblxuLyoqXG4gKiBFeGVjdXRlIG9uZSBob29rIGFnYWluc3QgdGhlIGN1cnJlbnQgYExWaWV3YC5cbiAqXG4gKiBAcGFyYW0gY3VycmVudFZpZXcgVGhlIGN1cnJlbnQgdmlld1xuICogQHBhcmFtIGluaXRQaGFzZVN0YXRlIHRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBpbml0IHBoYXNlXG4gKiBAcGFyYW0gYXJyIFRoZSBhcnJheSBpbiB3aGljaCB0aGUgaG9va3MgYXJlIGZvdW5kXG4gKiBAcGFyYW0gaSBUaGUgY3VycmVudCBpbmRleCB3aXRoaW4gdGhlIGhvb2sgZGF0YSBhcnJheVxuICovXG5mdW5jdGlvbiBjYWxsSG9vayhjdXJyZW50VmlldzogTFZpZXcsIGluaXRQaGFzZTogSW5pdFBoYXNlU3RhdGUsIGFycjogSG9va0RhdGEsIGk6IG51bWJlcikge1xuICBjb25zdCBpc0luaXRIb29rID0gKGFycltpXSBhcyBudW1iZXIpIDwgMDtcbiAgY29uc3QgaG9vayA9IGFycltpICsgMV0gYXMgKCkgPT4gdm9pZDtcbiAgY29uc3QgZGlyZWN0aXZlSW5kZXggPSBpc0luaXRIb29rID8gLWFycltpXSA6IGFycltpXSBhcyBudW1iZXI7XG4gIGNvbnN0IGRpcmVjdGl2ZSA9IGN1cnJlbnRWaWV3W2RpcmVjdGl2ZUluZGV4XTtcbiAgaWYgKGlzSW5pdEhvb2spIHtcbiAgICBjb25zdCBpbmRleFdpdGhpbnRJbml0UGhhc2UgPSBjdXJyZW50Vmlld1tGTEFHU10gPj4gTFZpZXdGbGFncy5JbmRleFdpdGhpbkluaXRQaGFzZVNoaWZ0O1xuICAgIC8vIFRoZSBpbml0IHBoYXNlIHN0YXRlIG11c3QgYmUgYWx3YXlzIGNoZWNrZWQgaGVyZSBhcyBpdCBtYXkgaGF2ZSBiZWVuIHJlY3Vyc2l2ZWx5IHVwZGF0ZWQuXG4gICAgaWYgKGluZGV4V2l0aGludEluaXRQaGFzZSA8XG4gICAgICAgICAgICAoY3VycmVudFZpZXdbUFJFT1JERVJfSE9PS19GTEFHU10gPj4gUHJlT3JkZXJIb29rRmxhZ3MuTnVtYmVyT2ZJbml0SG9va3NDYWxsZWRTaGlmdCkgJiZcbiAgICAgICAgKGN1cnJlbnRWaWV3W0ZMQUdTXSAmIExWaWV3RmxhZ3MuSW5pdFBoYXNlU3RhdGVNYXNrKSA9PT0gaW5pdFBoYXNlKSB7XG4gICAgICBjdXJyZW50Vmlld1tGTEFHU10gKz0gTFZpZXdGbGFncy5JbmRleFdpdGhpbkluaXRQaGFzZUluY3JlbWVudGVyO1xuICAgICAgY2FsbEhvb2tJbnRlcm5hbChkaXJlY3RpdmUsIGhvb2spO1xuICAgIH1cbiAgfSBlbHNlIHtcbiAgICBjYWxsSG9va0ludGVybmFsKGRpcmVjdGl2ZSwgaG9vayk7XG4gIH1cbn1cbiJdfQ==