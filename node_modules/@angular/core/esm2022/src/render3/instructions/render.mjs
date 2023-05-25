/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { retrieveHydrationInfo } from '../../hydration/utils';
import { assertEqual } from '../../util/assert';
import { CONTEXT, FLAGS, HOST, HYDRATION, INJECTOR, TVIEW } from '../interfaces/view';
import { enterView, leaveView } from '../state';
import { getComponentLViewByIndex, isCreationMode } from '../util/view_utils';
import { executeTemplate, executeViewQueryFn, refreshContentQueries } from './shared';
export function renderComponent(hostLView, componentHostIdx) {
    ngDevMode && assertEqual(isCreationMode(hostLView), true, 'Should be run in creation mode');
    const componentView = getComponentLViewByIndex(componentHostIdx, hostLView);
    const componentTView = componentView[TVIEW];
    syncViewWithBlueprint(componentTView, componentView);
    const hostRNode = componentView[HOST];
    // Populate an LView with hydration info retrieved from the DOM via TransferState.
    if (hostRNode !== null && componentView[HYDRATION] === null) {
        componentView[HYDRATION] = retrieveHydrationInfo(hostRNode, componentView[INJECTOR]);
    }
    renderView(componentTView, componentView, componentView[CONTEXT]);
}
/**
 * Syncs an LView instance with its blueprint if they have gotten out of sync.
 *
 * Typically, blueprints and their view instances should always be in sync, so the loop here
 * will be skipped. However, consider this case of two components side-by-side:
 *
 * App template:
 * ```
 * <comp></comp>
 * <comp></comp>
 * ```
 *
 * The following will happen:
 * 1. App template begins processing.
 * 2. First <comp> is matched as a component and its LView is created.
 * 3. Second <comp> is matched as a component and its LView is created.
 * 4. App template completes processing, so it's time to check child templates.
 * 5. First <comp> template is checked. It has a directive, so its def is pushed to blueprint.
 * 6. Second <comp> template is checked. Its blueprint has been updated by the first
 * <comp> template, but its LView was created before this update, so it is out of sync.
 *
 * Note that embedded views inside ngFor loops will never be out of sync because these views
 * are processed as soon as they are created.
 *
 * @param tView The `TView` that contains the blueprint for syncing
 * @param lView The view to sync
 */
export function syncViewWithBlueprint(tView, lView) {
    for (let i = lView.length; i < tView.blueprint.length; i++) {
        lView.push(tView.blueprint[i]);
    }
}
/**
 * Processes a view in the creation mode. This includes a number of steps in a specific order:
 * - creating view query functions (if any);
 * - executing a template function in the creation mode;
 * - updating static queries (if any);
 * - creating child components defined in a given view.
 */
export function renderView(tView, lView, context) {
    ngDevMode && assertEqual(isCreationMode(lView), true, 'Should be run in creation mode');
    enterView(lView);
    try {
        const viewQuery = tView.viewQuery;
        if (viewQuery !== null) {
            executeViewQueryFn(1 /* RenderFlags.Create */, viewQuery, context);
        }
        // Execute a template associated with this view, if it exists. A template function might not be
        // defined for the root component views.
        const templateFn = tView.template;
        if (templateFn !== null) {
            executeTemplate(tView, lView, templateFn, 1 /* RenderFlags.Create */, context);
        }
        // This needs to be set before children are processed to support recursive components.
        // This must be set to false immediately after the first creation run because in an
        // ngFor loop, all the views will be created together before update mode runs and turns
        // off firstCreatePass. If we don't set it here, instances will perform directive
        // matching, etc again and again.
        if (tView.firstCreatePass) {
            tView.firstCreatePass = false;
        }
        // We resolve content queries specifically marked as `static` in creation mode. Dynamic
        // content queries are resolved during change detection (i.e. update mode), after embedded
        // views are refreshed (see block above).
        if (tView.staticContentQueries) {
            refreshContentQueries(tView, lView);
        }
        // We must materialize query results before child components are processed
        // in case a child component has projected a container. The LContainer needs
        // to exist so the embedded views are properly attached by the container.
        if (tView.staticViewQueries) {
            executeViewQueryFn(2 /* RenderFlags.Update */, tView.viewQuery, context);
        }
        // Render child component views.
        const components = tView.components;
        if (components !== null) {
            renderChildComponents(lView, components);
        }
    }
    catch (error) {
        // If we didn't manage to get past the first template pass due to
        // an error, mark the view as corrupted so we can try to recover.
        if (tView.firstCreatePass) {
            tView.incompleteFirstPass = true;
            tView.firstCreatePass = false;
        }
        throw error;
    }
    finally {
        lView[FLAGS] &= ~4 /* LViewFlags.CreationMode */;
        leaveView();
    }
}
/** Renders child components in the current view (creation mode). */
function renderChildComponents(hostLView, components) {
    for (let i = 0; i < components.length; i++) {
        renderComponent(hostLView, components[i]);
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicmVuZGVyLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9pbnN0cnVjdGlvbnMvcmVuZGVyLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxxQkFBcUIsRUFBQyxNQUFNLHVCQUF1QixDQUFDO0FBQzVELE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUU5QyxPQUFPLEVBQUMsT0FBTyxFQUFFLEtBQUssRUFBRSxJQUFJLEVBQUUsU0FBUyxFQUFFLFFBQVEsRUFBcUIsS0FBSyxFQUFRLE1BQU0sb0JBQW9CLENBQUM7QUFDOUcsT0FBTyxFQUFDLFNBQVMsRUFBRSxTQUFTLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFDOUMsT0FBTyxFQUFDLHdCQUF3QixFQUFFLGNBQWMsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBRTVFLE9BQU8sRUFBQyxlQUFlLEVBQUUsa0JBQWtCLEVBQUUscUJBQXFCLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFFcEYsTUFBTSxVQUFVLGVBQWUsQ0FBQyxTQUFnQixFQUFFLGdCQUF3QjtJQUN4RSxTQUFTLElBQUksV0FBVyxDQUFDLGNBQWMsQ0FBQyxTQUFTLENBQUMsRUFBRSxJQUFJLEVBQUUsZ0NBQWdDLENBQUMsQ0FBQztJQUM1RixNQUFNLGFBQWEsR0FBRyx3QkFBd0IsQ0FBQyxnQkFBZ0IsRUFBRSxTQUFTLENBQUMsQ0FBQztJQUM1RSxNQUFNLGNBQWMsR0FBRyxhQUFhLENBQUMsS0FBSyxDQUFDLENBQUM7SUFDNUMscUJBQXFCLENBQUMsY0FBYyxFQUFFLGFBQWEsQ0FBQyxDQUFDO0lBRXJELE1BQU0sU0FBUyxHQUFHLGFBQWEsQ0FBQyxJQUFJLENBQUMsQ0FBQztJQUN0QyxrRkFBa0Y7SUFDbEYsSUFBSSxTQUFTLEtBQUssSUFBSSxJQUFJLGFBQWEsQ0FBQyxTQUFT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QUFDLEdBQUcsVUFBVSxDQUFDLE1BQU0sRUFBRSxDQUFDLEVBQUUsRUFBRTtRQUMxQyxlQUFlLENBQUMsU0FBUyxFQUFFLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDO0tBQzNDO0FBQ0gsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge3JldHJpZXZlSHlkcmF0aW9uSW5mb30gZnJvbSAnLi4vLi4vaHlkcmF0aW9uL3V0aWxzJztcbmltcG9ydCB7YXNzZXJ0RXF1YWx9IGZyb20gJy4uLy4uL3V0aWwvYXNzZXJ0JztcbmltcG9ydCB7UmVuZGVyRmxhZ3N9IGZyb20gJy4uL2ludGVyZmFjZXMvZGVmaW5pdGlvbic7XG5pbXBvcnQge0NPTlRFWFQsIEZMQUdTLCBIT1NULCBIWURSQVRJT04sIElOSkVDVE9SLCBMVmlldywgTFZpZXdGbGFncywgVFZJRVcsIFRWaWV3fSBmcm9tICcuLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtlbnRlclZpZXcsIGxlYXZlVmlld30gZnJvbSAnLi4vc3RhdGUnO1xuaW1wb3J0IHtnZXRDb21wb25lbnRMVmlld0J5SW5kZXgsIGlzQ3JlYXRpb25Nb2RlfSBmcm9tICcuLi91dGlsL3ZpZXdfdXRpbHMnO1xuXG5pbXBvcnQge2V4ZWN1dGVUZW1wbGF0ZSwgZXhlY3V0ZVZpZXdRdWVyeUZuLCByZWZyZXNoQ29udGVudFF1ZXJpZXN9IGZyb20gJy4vc2hhcmVkJztcblxuZXhwb3J0IGZ1bmN0aW9uIHJlbmRlckNvbXBvbmVudChob3N0TFZpZXc6IExWaWV3LCBjb21wb25lbnRIb3N0SWR4OiBudW1iZXIpIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEVxdWFsKGlzQ3JlYXRpb25Nb2RlKGhvc3RMVmlldyksIHRydWUsICdTaG91bGQgYmUgcnVuIGluIGNyZWF0aW9uIG1vZGUnKTtcbiAgY29uc3QgY29tcG9uZW50VmlldyA9IGdldENvbXBvbmVudExWaWV3QnlJbmRleChjb21wb25lbnRIb3N0SWR4LCBob3N0TFZpZXcpO1xuICBjb25zdCBjb21wb25lbnRUVmlldyA9IGNvbXBvbmVudFZpZXdbVFZJRVddO1xuICBzeW5jVmlld1dpdGhCbHVlcHJpbnQoY29tcG9uZW50VFZpZXcsIGNvbXBvbmVudFZpZXcpO1xuXG4gIGNvbnN0IGhvc3RSTm9kZSA9IGNvbXBvbmVudFZpZXdbSE9TVF07XG4gIC8vIFBvcHVsYXRlIGFuIExWaWV3IHdpdGggaHlkcmF0aW9uIGluZm8gcmV0cmlldmVkIGZyb20gdGhlIERPTSB2aWEgVHJhbnNmZXJTdGF0ZS5cbiAgaWYgKGhvc3RSTm9kZSAhPT0gbnVsbCAmJiBjb21wb25lbnRWaWV3W0hZRFJBVElPTl0gPT09IG51bGwpIHtcbiAgICBjb21wb25lbnRWaWV3W0hZRFJBVElPTl0gPSByZXRyaWV2ZUh5ZHJhdGlvbkluZm8oaG9zdFJOb2RlLCBjb21wb25lbnRWaWV3W0lOSkVDVE9SXSEpO1xuICB9XG5cbiAgcmVuZGVyVmlldyhjb21wb25lbnRUVmlldywgY29tcG9uZW50VmlldywgY29tcG9uZW50Vmlld1tDT05URVhUXSk7XG59XG5cbi8qKlxuICogU3luY3MgYW4gTFZpZXcgaW5zdGFuY2Ugd2l0aCBpdHMgYmx1ZXByaW50IGlmIHRoZXkgaGF2ZSBnb3R0ZW4gb3V0IG9mIHN5bmMuXG4gKlxuICogVHlwaWNhbGx5LCBibHVlcHJpbnRzIGFuZCB0aGVpciB2aWV3IGluc3RhbmNlcyBzaG91bGQgYWx3YXlzIGJlIGluIHN5bmMsIHNvIHRoZSBsb29wIGhlcmVcbiAqIHdpbGwgYmUgc2tpcHBlZC4gSG93ZXZlciwgY29uc2lkZXIgdGhpcyBjYXNlIG9mIHR3byBjb21wb25lbnRzIHNpZGUtYnktc2lkZTpcbiAqXG4gKiBBcHAgdGVtcGxhdGU6XG4gKiBgYGBcbiAqIDxjb21wPjwvY29tcD5cbiAqIDxjb21wPjwvY29tcD5cbiAqIGBgYFxuICpcbiAqIFRoZSBmb2xsb3dpbmcgd2lsbCBoYXBwZW46XG4gKiAxLiBBcHAgdGVtcGxhdGUgYmVnaW5zIHByb2Nlc3NpbmcuXG4gKiAyLiBGaXJzdCA8Y29tcD4gaXMgbWF0Y2hlZCBhcyBhIGNvbXBvbmVudCBhbmQgaXRzIExWaWV3IGlzIGNyZWF0ZWQuXG4gKiAzLiBTZWNvbmQgPGNvbXA+IGlzIG1hdGNoZWQgYXMgYSBjb21wb25lbnQgYW5kIGl0cyBMVmlldyBpcyBjcmVhdGVkLlxuICogNC4gQXBwIHRlbXBsYXRlIGNvbXBsZXRlcyBwcm9jZXNzaW5nLCBzbyBpdCdzIHRpbWUgdG8gY2hlY2sgY2hpbGQgdGVtcGxhdGVzLlxuICogNS4gRmlyc3QgPGNvbXA+IHRlbXBsYXRlIGlzIGNoZWNrZWQuIEl0IGhhcyBhIGRpcmVjdGl2ZSwgc28gaXRzIGRlZiBpcyBwdXNoZWQgdG8gYmx1ZXByaW50LlxuICogNi4gU2Vjb25kIDxjb21wPiB0ZW1wbGF0ZSBpcyBjaGVja2VkLiBJdHMgYmx1ZXByaW50IGhhcyBiZWVuIHVwZGF0ZWQgYnkgdGhlIGZpcnN0XG4gKiA8Y29tcD4gdGVtcGxhdGUsIGJ1dCBpdHMgTFZpZXcgd2FzIGNyZWF0ZWQgYmVmb3JlIHRoaXMgdXBkYXRlLCBzbyBpdCBpcyBvdXQgb2Ygc3luYy5cbiAqXG4gKiBOb3RlIHRoYXQgZW1iZWRkZWQgdmlld3MgaW5zaWRlIG5nRm9yIGxvb3BzIHdpbGwgbmV2ZXIgYmUgb3V0IG9mIHN5bmMgYmVjYXVzZSB0aGVzZSB2aWV3c1xuICogYXJlIHByb2Nlc3NlZCBhcyBzb29uIGFzIHRoZXkgYXJlIGNyZWF0ZWQuXG4gKlxuICogQHBhcmFtIHRWaWV3IFRoZSBgVFZpZXdgIHRoYXQgY29udGFpbnMgdGhlIGJsdWVwcmludCBmb3Igc3luY2luZ1xuICogQHBhcmFtIGxWaWV3IFRoZSB2aWV3IHRvIHN5bmNcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHN5bmNWaWV3V2l0aEJsdWVwcmludCh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldykge1xuICBmb3IgKGxldCBpID0gbFZpZXcubGVuZ3RoOyBpIDwgdFZpZXcuYmx1ZXByaW50Lmxlbmd0aDsgaSsrKSB7XG4gICAgbFZpZXcucHVzaCh0Vmlldy5ibHVlcHJpbnRbaV0pO1xuICB9XG59XG5cbi8qKlxuICogUHJvY2Vzc2VzIGEgdmlldyBpbiB0aGUgY3JlYXRpb24gbW9kZS4gVGhpcyBpbmNsdWRlcyBhIG51bWJlciBvZiBzdGVwcyBpbiBhIHNwZWNpZmljIG9yZGVyOlxuICogLSBjcmVhdGluZyB2aWV3IHF1ZXJ5IGZ1bmN0aW9ucyAoaWYgYW55KTtcbiAqIC0gZXhlY3V0aW5nIGEgdGVtcGxhdGUgZnVuY3Rpb24gaW4gdGhlIGNyZWF0aW9uIG1vZGU7XG4gKiAtIHVwZGF0aW5nIHN0YXRpYyBxdWVyaWVzIChpZiBhbnkpO1xuICogLSBjcmVhdGluZyBjaGlsZCBjb21wb25lbnRzIGRlZmluZWQgaW4gYSBnaXZlbiB2aWV3LlxuICovXG5leHBvcnQgZnVuY3Rpb24gcmVuZGVyVmlldzxUPih0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldzxUPiwgY29udGV4dDogVCk6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RXF1YWwoaXNDcmVhdGlvbk1vZGUobFZpZXcpLCB0cnVlLCAnU2hvdWxkIGJlIHJ1biBpbiBjcmVhdGlvbiBtb2RlJyk7XG4gIGVudGVyVmlldyhsVmlldyk7XG4gIHRyeSB7XG4gICAgY29uc3Qgdmlld1F1ZXJ5ID0gdFZpZXcudmlld1F1ZXJ5O1xuICAgIGlmICh2aWV3UXVlcnkgIT09IG51bGwpIHtcbiAgICAgIGV4ZWN1dGVWaWV3UXVlcnlGbjxUPihSZW5kZXJGbGFncy5DcmVhdGUsIHZpZXdRdWVyeSwgY29udGV4dCk7XG4gICAgfVxuXG4gICAgLy8gRXhlY3V0ZSBhIHRlbXBsYXRlIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHZpZXcsIGlmIGl0IGV4aXN0cy4gQSB0ZW1wbGF0ZSBmdW5jdGlvbiBtaWdodCBub3QgYmVcbiAgICAvLyBkZWZpbmVkIGZvciB0aGUgcm9vdCBjb21wb25lbnQgdmlld3MuXG4gICAgY29uc3QgdGVtcGxhdGVGbiA9IHRWaWV3LnRlbXBsYXRlO1xuICAgIGlmICh0ZW1wbGF0ZUZuICE9PSBudWxsKSB7XG4gICAgICBleGVjdXRlVGVtcGxhdGU8VD4odFZpZXcsIGxWaWV3LCB0ZW1wbGF0ZUZuLCBSZW5kZXJGbGFncy5DcmVhdGUsIGNvbnRleHQpO1xuICAgIH1cblxuICAgIC8vIFRoaXMgbmVlZHMgdG8gYmUgc2V0IGJlZm9yZSBjaGlsZHJlbiBhcmUgcHJvY2Vzc2VkIHRvIHN1cHBvcnQgcmVjdXJzaXZlIGNvbXBvbmVudHMuXG4gICAgLy8gVGhpcyBtdXN0IGJlIHNldCB0byBmYWxzZSBpbW1lZGlhdGVseSBhZnRlciB0aGUgZmlyc3QgY3JlYXRpb24gcnVuIGJlY2F1c2UgaW4gYW5cbiAgICAvLyBuZ0ZvciBsb29wLCBhbGwgdGhlIHZpZXdzIHdpbGwgYmUgY3JlYXRlZCB0b2dldGhlciBiZWZvcmUgdXBkYXRlIG1vZGUgcnVucyBhbmQgdHVybnNcbiAgICAvLyBvZmYgZmlyc3RDcmVhdGVQYXNzLiBJZiB3ZSBkb24ndCBzZXQgaXQgaGVyZSwgaW5zdGFuY2VzIHdpbGwgcGVyZm9ybSBkaXJlY3RpdmVcbiAgICAvLyBtYXRjaGluZywgZXRjIGFnYWluIGFuZCBhZ2Fpbi5cbiAgICBpZiAodFZpZXcuZmlyc3RDcmVhdGVQYXNzKSB7XG4gICAgICB0Vmlldy5maXJzdENyZWF0ZVBhc3MgPSBmYWxzZTtcbiAgICB9XG5cbiAgICAvLyBXZSByZXNvbHZlIGNvbnRlbnQgcXVlcmllcyBzcGVjaWZpY2FsbHkgbWFya2VkIGFzIGBzdGF0aWNgIGluIGNyZWF0aW9uIG1vZGUuIER5bmFtaWNcbiAgICAvLyBjb250ZW50IHF1ZXJpZXMgYXJlIHJlc29sdmVkIGR1cmluZyBjaGFuZ2UgZGV0ZWN0aW9uIChpLmUuIHVwZGF0ZSBtb2RlKSwgYWZ0ZXIgZW1iZWRkZWRcbiAgICAvLyB2aWV3cyBhcmUgcmVmcmVzaGVkIChzZWUgYmxvY2sgYWJvdmUpLlxuICAgIGlmICh0Vmlldy5zdGF0aWNDb250ZW50UXVlcmllcykge1xuICAgICAgcmVmcmVzaENvbnRlbnRRdWVyaWVzKHRWaWV3LCBsVmlldyk7XG4gICAgfVxuXG4gICAgLy8gV2UgbXVzdCBtYXRlcmlhbGl6ZSBxdWVyeSByZXN1bHRzIGJlZm9yZSBjaGlsZCBjb21wb25lbnRzIGFyZSBwcm9jZXNzZWRcbiAgICAvLyBpbiBjYXNlIGEgY2hpbGQgY29tcG9uZW50IGhhcyBwcm9qZWN0ZWQgYSBjb250YWluZXIuIFRoZSBMQ29udGFpbmVyIG5lZWRzXG4gICAgLy8gdG8gZXhpc3Qgc28gdGhlIGVtYmVkZGVkIHZpZXdzIGFyZSBwcm9wZXJseSBhdHRhY2hlZCBieSB0aGUgY29udGFpbmVyLlxuICAgIGlmICh0Vmlldy5zdGF0aWNWaWV3UXVlcmllcykge1xuICAgICAgZXhlY3V0ZVZpZXdRdWVyeUZuPFQ+KFJlbmRlckZsYWdzLlVwZGF0ZSwgdFZpZXcudmlld1F1ZXJ5ISwgY29udGV4dCk7XG4gICAgfVxuXG4gICAgLy8gUmVuZGVyIGNoaWxkIGNvbXBvbmVudCB2aWV3cy5cbiAgICBjb25zdCBjb21wb25lbnRzID0gdFZpZXcuY29tcG9uZW50cztcbiAgICBpZiAoY29tcG9uZW50cyAhPT0gbnVsbCkge1xuICAgICAgcmVuZGVyQ2hpbGRDb21wb25lbnRzKGxWaWV3LCBjb21wb25lbnRzKTtcbiAgICB9XG5cbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAvLyBJZiB3ZSBkaWRuJ3QgbWFuYWdlIHRvIGdldCBwYXN0IHRoZSBmaXJzdCB0ZW1wbGF0ZSBwYXNzIGR1ZSB0b1xuICAgIC8vIGFuIGVycm9yLCBtYXJrIHRoZSB2aWV3IGFzIGNvcnJ1cHRlZCBzbyB3ZSBjYW4gdHJ5IHRvIHJlY292ZXIuXG4gICAgaWYgKHRWaWV3LmZpcnN0Q3JlYXRlUGFzcykge1xuICAgICAgdFZpZXcuaW5jb21wbGV0ZUZpcnN0UGFzcyA9IHRydWU7XG4gICAgICB0Vmlldy5maXJzdENyZWF0ZVBhc3MgPSBmYWxzZTtcbiAgICB9XG5cbiAgICB0aHJvdyBlcnJvcjtcbiAgfSBmaW5hbGx5IHtcbiAgICBsVmlld1tGTEFHU10gJj0gfkxWaWV3RmxhZ3MuQ3JlYXRpb25Nb2RlO1xuICAgIGxlYXZlVmlldygpO1xuICB9XG59XG5cbi8qKiBSZW5kZXJzIGNoaWxkIGNvbXBvbmVudHMgaW4gdGhlIGN1cnJlbnQgdmlldyAoY3JlYXRpb24gbW9kZSkuICovXG5mdW5jdGlvbiByZW5kZXJDaGlsZENvbXBvbmVudHMoaG9zdExWaWV3OiBMVmlldywgY29tcG9uZW50czogbnVtYmVyW10pOiB2b2lkIHtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBjb21wb25lbnRzLmxlbmd0aDsgaSsrKSB7XG4gICAgcmVuZGVyQ29tcG9uZW50KGhvc3RMVmlldywgY29tcG9uZW50c1tpXSk7XG4gIH1cbn1cbiJdfQ==