/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { DEHYDRATED_VIEWS } from '../render3/interfaces/container';
import { removeDehydratedViews } from './cleanup';
import { MULTIPLIER, NUM_ROOT_NODES, TEMPLATE_ID } from './interfaces';
import { siblingAfter } from './node_lookup_utils';
/**
 * Given a current DOM node and a serialized information about the views
 * in a container, walks over the DOM structure, collecting the list of
 * dehydrated views.
 */
export function locateDehydratedViewsInContainer(currentRNode, serializedViews) {
    const dehydratedViews = [];
    for (const serializedView of serializedViews) {
        // Repeats a view multiple times as needed, based on the serialized information
        // (for example, for *ngFor-produced views).
        for (let i = 0; i < (serializedView[MULTIPLIER] ?? 1); i++) {
            const view = {
                data: serializedView,
                firstChild: null,
            };
            if (serializedView[NUM_ROOT_NODES] > 0) {
                // Keep reference to the first node in this view,
                // so it can be accessed while invoking template instructions.
                view.firstChild = currentRNode;
                // Move over to the next node after this view, which can
                // either be a first node of the next view or an anchor comment
                // node after the last view in a container.
                currentRNode = siblingAfter(serializedView[NUM_ROOT_NODES], currentRNode);
            }
            dehydratedViews.push(view);
        }
    }
    return [currentRNode, dehydratedViews];
}
/**
 * Reference to a function that searches for a matching dehydrated views
 * stored on a given lContainer.
 * Returns `null` by default, when hydration is not enabled.
 */
let _findMatchingDehydratedViewImpl = (lContainer, template) => null;
/**
 * Retrieves the next dehydrated view from the LContainer and verifies that
 * it matches a given template id (from the TView that was used to create this
 * instance of a view). If the id doesn't match, that means that we are in an
 * unexpected state and can not complete the reconciliation process. Thus,
 * all dehydrated views from this LContainer are removed (including corresponding
 * DOM nodes) and the rendering is performed as if there were no dehydrated views
 * in this container.
 */
function findMatchingDehydratedViewImpl(lContainer, template) {
    const views = lContainer[DEHYDRATED_VIEWS] ?? [];
    if (!template || views.length === 0) {
        return null;
    }
    const view = views[0];
    // Verify whether the first dehydrated view in the container matches
    // the template id passed to this function (that originated from a TView
    // that was used to create an instance of an embedded or component views.
    if (view.data[TEMPLATE_ID] === template) {
        // If the template id matches - extract the first view and return it.
        return views.shift();
    }
    else {
        // Otherwise, we are at the state when reconciliation can not be completed,
        // thus we remove all dehydrated views within this container (remove them
        // from internal data structures as well as delete associated elements from
        // the DOM tree).
        removeDehydratedViews(lContainer);
        return null;
    }
}
export function enableFindMatchingDehydratedViewImpl() {
    _findMatchingDehydratedViewImpl = findMatchingDehydratedViewImpl;
}
export function findMatchingDehydratedView(lContainer, template) {
    return _findMatchingDehydratedViewImpl(lContainer, template);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidmlld3MuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9oeWRyYXRpb24vdmlld3MudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLGdCQUFnQixFQUFhLE1BQU0saUNBQWlDLENBQUM7QUFHN0UsT0FBTyxFQUFDLHFCQUFxQixFQUFDLE1BQU0sV0FBVyxDQUFDO0FBQ2hELE9BQU8sRUFBMEIsVUFBVSxFQUFFLGNBQWMsRUFBMkIsV0FBVyxFQUFDLE1BQU0sY0FBYyxDQUFDO0FBQ3ZILE9BQU8sRUFBQyxZQUFZLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQUdqRDs7OztHQUlHO0FBQ0gsTUFBTSxVQUFVLGdDQUFnQyxDQUM1QyxZQUFtQixFQUNuQixlQUEwQztJQUM1QyxNQUFNLGVBQWUsR0FBOEIsRUFBRSxDQUFDO0lBQ3RELEtBQUssTUFBTSxjQUFjLElBQUksZUFBZSxFQUFFO1FBQzVDLCtFQUErRTtRQUMvRSw0Q0FBNEM7UUFDNUMsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsY0FBYyxDQUFDLFVBQVUsQ0FBQyxJQUFJLENBQUMsQ0FBQyxFQUFFLENBQUMsRUFBRSxFQUFFO1lBQzFELE1BQU0sSUFBSSxHQUE0QjtnQkFDcEMsSUFBSSxFQUFFLGNBQWM7Z0JBQ3BCLFVBQVUsRUFBRSxJQUFJO2FBQ2pCLENBQUM7WUFDRixJQUFJLGNBQWMsQ0FBQyxjQUFjLENBQUMsR0FBRyxDQUFDLEVBQUU7Z0JBQ3RDLGlEQUFpRDtnQkFDakQsOERBQThEO2dCQUM5RCxJQUFJLENBQUMsVUFBVSxHQUFHLFlBQTJCLENBQUM7Z0JBRTlDLHdEQUF3RDtnQkFDeEQsK0RBQStEO2dCQUMvRCwyQ0FBMkM7Z0JBQzNDLFlBQVksR0FBRyxZQUFZLENBQUMsY0FBYyxDQUFDLGNBQWMsQ0FBQyxFQUFFLFlBQVksQ0FBRSxDQUFDO2FBQzVFO1lBQ0QsZUFBZSxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBQztTQUM1QjtLQUNGO0lBRUQsT0FBTyxDQUFDLFlBQVksRUFBRSxlQUFlLENBQUMsQ0FBQztBQUN6QyxDQUFDO0FBRUQ7Ozs7R0FJRztBQUNILElBQUksK0JBQStCLEdBQy9CLENBQUMsVUFBc0IsRUFBRSxRQUFxQixFQUFFLEVBQUUsQ0FBQyxJQUFJLENBQUM7QUFFNUQ7Ozs7Ozs7O0dBUUc7QUFDSCxTQUFTLDhCQUE4QixDQUNuQyxVQUFzQixFQUFFLFFBQXFCO0lBQy9DLE1BQU0sS0FBSyxHQUFHLFVBQVUsQ0FBQyxnQkFBZ0IsQ0FBQyxJQUFJLEVBQUUsQ0FBQztJQUNqRCxJQUFJLENBQUMsUUFBUSxJQUFJLEtBQUssQ0FBQyxNQUFNLEtBQUssQ0FBQyxFQUFFO1FBQ25DLE9BQU8sSUFBSSxDQUFDO0tBQ2I7SUFDRCxNQUFNLElBQUksR0FBRyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUM7SUFDdEIsb0VBQW9FO0lBQ3BFLHdFQUF3RTtJQUN4RSx5RUFBeUU7SUFDekUsSUFBSSxJQUFJLENBQUMsSUFBSSxDQUFDLFdBQVcsQ0FBQyxLQUFLLFFBQVEsRUFBRTtRQUN2QyxxRUFBcUU7UUFDckUsT0FBTyxLQUFLLENBQUMsS0FBSyxFQUFHLENBQUM7S0FDdkI7U0FBTTtRQUNMLDJFQUEyRTtRQUMzRSx5RUFBeUU7UUFDekUsMkVBQTJFO1FBQzNFLGlCQUFpQjtRQUNqQixxQkFBcUIsQ0FBQyxVQUFVLENBQUMsQ0FBQztRQUNsQyxPQUFPLElBQUksQ0FBQztLQUNiO0FBQ0gsQ0FBQztBQUVELE1BQU0sVUFBVSxvQ0FBb0M7SUFDbEQsK0JBQStCLEdBQUcsOEJBQThCLENBQUM7QUFDbkUsQ0FBQztBQUVELE1BQU0sVUFBVSwwQkFBMEIsQ0FDdEMsVUFBc0IsRUFBRSxRQUFxQjtJQUMvQyxPQUFPLCtCQUErQixDQUFDLFVBQVUsRUFBRSxRQUFRLENBQUMsQ0FBQztBQUMvRCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7REVIWURSQVRFRF9WSUVXUywgTENvbnRhaW5lcn0gZnJvbSAnLi4vcmVuZGVyMy9pbnRlcmZhY2VzL2NvbnRhaW5lcic7XG5pbXBvcnQge1JOb2RlfSBmcm9tICcuLi9yZW5kZXIzL2ludGVyZmFjZXMvcmVuZGVyZXJfZG9tJztcblxuaW1wb3J0IHtyZW1vdmVEZWh5ZHJhdGVkVmlld3N9IGZyb20gJy4vY2xlYW51cCc7XG5pbXBvcnQge0RlaHlkcmF0ZWRDb250YWluZXJWaWV3LCBNVUxUSVBMSUVSLCBOVU1fUk9PVF9OT0RFUywgU2VyaWFsaXplZENvbnRhaW5lclZpZXcsIFRFTVBMQVRFX0lEfSBmcm9tICcuL2ludGVyZmFjZXMnO1xuaW1wb3J0IHtzaWJsaW5nQWZ0ZXJ9IGZyb20gJy4vbm9kZV9sb29rdXBfdXRpbHMnO1xuXG5cbi8qKlxuICogR2l2ZW4gYSBjdXJyZW50IERPTSBub2RlIGFuZCBhIHNlcmlhbGl6ZWQgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHZpZXdzXG4gKiBpbiBhIGNvbnRhaW5lciwgd2Fsa3Mgb3ZlciB0aGUgRE9NIHN0cnVjdHVyZSwgY29sbGVjdGluZyB0aGUgbGlzdCBvZlxuICogZGVoeWRyYXRlZCB2aWV3cy5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGxvY2F0ZURlaHlkcmF0ZWRWaWV3c0luQ29udGFpbmVyKFxuICAgIGN1cnJlbnRSTm9kZTogUk5vZGUsXG4gICAgc2VyaWFsaXplZFZpZXdzOiBTZXJpYWxpemVkQ29udGFpbmVyVmlld1tdKTogW1JOb2RlLCBEZWh5ZHJhdGVkQ29udGFpbmVyVmlld1tdXSB7XG4gIGNvbnN0IGRlaHlkcmF0ZWRWaWV3czogRGVoeWRyYXRlZENvbnRhaW5lclZpZXdbXSA9IFtdO1xuICBmb3IgKGNvbnN0IHNlcmlhbGl6ZWRWaWV3IG9mIHNlcmlhbGl6ZWRWaWV3cykge1xuICAgIC8vIFJlcGVhdHMgYSB2aWV3IG11bHRpcGxlIHRpbWVzIGFzIG5lZWRlZCwgYmFzZWQgb24gdGhlIHNlcmlhbGl6ZWQgaW5mb3JtYXRpb25cbiAgICAvLyAoZm9yIGV4YW1wbGUsIGZvciAqbmdGb3ItcHJvZHVjZWQgdmlld3MpLlxuICAgIGZvciAobGV0IGkgPSAwOyBpIDwgKHNlcmlhbGl6ZWRWaWV3W01VTFRJUExJRVJdID8/IDEpOyBpKyspIHtcbiAgICAgIGNvbnN0IHZpZXc6IERlaHlkcmF0ZWRDb250YWluZXJWaWV3ID0ge1xuICAgICAgICBkYXRhOiBzZXJpYWxpemVkVmlldyxcbiAgICAgICAgZmlyc3RDaGlsZDogbnVsbCxcbiAgICAgIH07XG4gICAgICBpZiAoc2VyaWFsaXplZFZpZXdbTlVNX1JPT1RfTk9ERVNdID4gMCkge1xuICAgICAgICAvLyBLZWVwIHJlZmVyZW5jZSB0byB0aGUgZmlyc3Qgbm9kZSBpbiB0aGlzIHZpZXcsXG4gICAgICAgIC8vIHNvIGl0IGNhbiBiZSBhY2Nlc3NlZCB3aGlsZSBpbnZva2luZyB0ZW1wbGF0ZSBpbnN0cnVjdGlvbnMuXG4gICAgICAgIHZpZXcuZmlyc3RDaGlsZCA9IGN1cnJlbnRSTm9kZSBhcyBIVE1MRWxlbWVudDtcblxuICAgICAgICAvLyBNb3ZlIG92ZXIgdG8gdGhlIG5leHQgbm9kZSBhZnRlciB0aGlzIHZpZXcsIHdoaWNoIGNhblxuICAgICAgICAvLyBlaXRoZXIgYmUgYSBmaXJzdCBub2RlIG9mIHRoZSBuZXh0IHZpZXcgb3IgYW4gYW5jaG9yIGNvbW1lbnRcbiAgICAgICAgLy8gbm9kZSBhZnRlciB0aGUgbGFzdCB2aWV3IGluIGEgY29udGFpbmVyLlxuICAgICAgICBjdXJyZW50Uk5vZGUgPSBzaWJsaW5nQWZ0ZXIoc2VyaWFsaXplZFZpZXdbTlVNX1JPT1RfTk9ERVNdLCBjdXJyZW50Uk5vZGUpITtcbiAgICAgIH1cbiAgICAgIGRlaHlkcmF0ZWRWaWV3cy5wdXNoKHZpZXcpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBbY3VycmVudFJOb2RlLCBkZWh5ZHJhdGVkVmlld3NdO1xufVxuXG4vKipcbiAqIFJlZmVyZW5jZSB0byBhIGZ1bmN0aW9uIHRoYXQgc2VhcmNoZXMgZm9yIGEgbWF0Y2hpbmcgZGVoeWRyYXRlZCB2aWV3c1xuICogc3RvcmVkIG9uIGEgZ2l2ZW4gbENvbnRhaW5lci5cbiAqIFJldHVybnMgYG51bGxgIGJ5IGRlZmF1bHQsIHdoZW4gaHlkcmF0aW9uIGlzIG5vdCBlbmFibGVkLlxuICovXG5sZXQgX2ZpbmRNYXRjaGluZ0RlaHlkcmF0ZWRWaWV3SW1wbDogdHlwZW9mIGZpbmRNYXRjaGluZ0RlaHlkcmF0ZWRWaWV3SW1wbCA9XG4gICAgKGxDb250YWluZXI6IExDb250YWluZXIsIHRlbXBsYXRlOiBzdHJpbmd8bnVsbCkgPT4gbnVsbDtcblxuLyoqXG4gKiBSZXRyaWV2ZXMgdGhlIG5leHQgZGVoeWRyYXRlZCB2aWV3IGZyb20gdGhlIExDb250YWluZXIgYW5kIHZlcmlmaWVzIHRoYXRcbiAqIGl0IG1hdGNoZXMgYSBnaXZlbiB0ZW1wbGF0ZSBpZCAoZnJvbSB0aGUgVFZpZXcgdGhhdCB3YXMgdXNlZCB0byBjcmVhdGUgdGhpc1xuICogaW5zdGFuY2Ugb2YgYSB2aWV3KS4gSWYgdGhlIGlkIGRvZXNuJ3QgbWF0Y2gsIHRoYXQgbWVhbnMgdGhhdCB3ZSBhcmUgaW4gYW5cbiAqIHVuZXhwZWN0ZWQgc3RhdGUgYW5kIGNhbiBub3QgY29tcGxldGUgdGhlIHJlY29uY2lsaWF0aW9uIHByb2Nlc3MuIFRodXMsXG4gKiBhbGwgZGVoeWRyYXRlZCB2aWV3cyBmcm9tIHRoaXMgTENvbnRhaW5lciBhcmUgcmVtb3ZlZCAoaW5jbHVkaW5nIGNvcnJlc3BvbmRpbmdcbiAqIERPTSBub2RlcykgYW5kIHRoZSByZW5kZXJpbmcgaXMgcGVyZm9ybWVkIGFzIGlmIHRoZXJlIHdlcmUgbm8gZGVoeWRyYXRlZCB2aWV3c1xuICogaW4gdGhpcyBjb250YWluZXIuXG4gKi9cbmZ1bmN0aW9uIGZpbmRNYXRjaGluZ0RlaHlkcmF0ZWRWaWV3SW1wbChcbiAgICBsQ29udGFpbmVyOiBMQ29udGFpbmVyLCB0ZW1wbGF0ZTogc3RyaW5nfG51bGwpOiBEZWh5ZHJhdGVkQ29udGFpbmVyVmlld3xudWxsIHtcbiAgY29uc3Qgdmlld3MgPSBsQ29udGFpbmVyW0RFSFlEUkFURURfVklFV1NdID8/IFtdO1xuICBpZiAoIXRlbXBsYXRlIHx8IHZpZXdzLmxlbmd0aCA9PT0gMCkge1xuICAgIHJldHVybiBudWxsO1xuICB9XG4gIGNvbnN0IHZpZXcgPSB2aWV3c1swXTtcbiAgLy8gVmVyaWZ5IHdoZXRoZXIgdGhlIGZpcnN0IGRlaHlkcmF0ZWQgdmlldyBpbiB0aGUgY29udGFpbmVyIG1hdGNoZXNcbiAgLy8gdGhlIHRlbXBsYXRlIGlkIHBhc3NlZCB0byB0aGlzIGZ1bmN0aW9uICh0aGF0IG9yaWdpbmF0ZWQgZnJvbSBhIFRWaWV3XG4gIC8vIHRoYXQgd2FzIHVzZWQgdG8gY3JlYXRlIGFuIGluc3RhbmNlIG9mIGFuIGVtYmVkZGVkIG9yIGNvbXBvbmVudCB2aWV3cy5cbiAgaWYgKHZpZXcuZGF0YVtURU1QTEFURV9JRF0gPT09IHRlbXBsYXRlKSB7XG4gICAgLy8gSWYgdGhlIHRlbXBsYXRlIGlkIG1hdGNoZXMgLSBleHRyYWN0IHRoZSBmaXJzdCB2aWV3IGFuZCByZXR1cm4gaXQuXG4gICAgcmV0dXJuIHZpZXdzLnNoaWZ0KCkhO1xuICB9IGVsc2Uge1xuICAgIC8vIE90aGVyd2lzZSwgd2UgYXJlIGF0IHRoZSBzdGF0ZSB3aGVuIHJlY29uY2lsaWF0aW9uIGNhbiBub3QgYmUgY29tcGxldGVkLFxuICAgIC8vIHRodXMgd2UgcmVtb3ZlIGFsbCBkZWh5ZHJhdGVkIHZpZXdzIHdpdGhpbiB0aGlzIGNvbnRhaW5lciAocmVtb3ZlIHRoZW1cbiAgICAvLyBmcm9tIGludGVybmFsIGRhdGEgc3RydWN0dXJlcyBhcyB3ZWxsIGFzIGRlbGV0ZSBhc3NvY2lhdGVkIGVsZW1lbnRzIGZyb21cbiAgICAvLyB0aGUgRE9NIHRyZWUpLlxuICAgIHJlbW92ZURlaHlkcmF0ZWRWaWV3cyhsQ29udGFpbmVyKTtcbiAgICByZXR1cm4gbnVsbDtcbiAgfVxufVxuXG5leHBvcnQgZnVuY3Rpb24gZW5hYmxlRmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXdJbXBsKCkge1xuICBfZmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXdJbXBsID0gZmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXdJbXBsO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gZmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXcoXG4gICAgbENvbnRhaW5lcjogTENvbnRhaW5lciwgdGVtcGxhdGU6IHN0cmluZ3xudWxsKTogRGVoeWRyYXRlZENvbnRhaW5lclZpZXd8bnVsbCB7XG4gIHJldHVybiBfZmluZE1hdGNoaW5nRGVoeWRyYXRlZFZpZXdJbXBsKGxDb250YWluZXIsIHRlbXBsYXRlKTtcbn1cbiJdfQ==