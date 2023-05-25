/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertParentView } from './assert';
import { icuContainerIterate } from './i18n/i18n_tree_shaking';
import { CONTAINER_HEADER_OFFSET, NATIVE } from './interfaces/container';
import { isLContainer } from './interfaces/type_checks';
import { DECLARATION_COMPONENT_VIEW, HOST, TVIEW } from './interfaces/view';
import { assertTNodeType } from './node_assert';
import { getProjectionNodes } from './node_manipulation';
import { getLViewParent } from './util/view_traversal_utils';
import { unwrapRNode } from './util/view_utils';
export function collectNativeNodes(tView, lView, tNode, result, isProjection = false) {
    while (tNode !== null) {
        ngDevMode &&
            assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */ | 12 /* TNodeType.AnyContainer */ | 16 /* TNodeType.Projection */ | 32 /* TNodeType.Icu */);
        const lNode = lView[tNode.index];
        if (lNode !== null) {
            result.push(unwrapRNode(lNode));
        }
        // A given lNode can represent either a native node or a LContainer (when it is a host of a
        // ViewContainerRef). When we find a LContainer we need to descend into it to collect root nodes
        // from the views in this container.
        if (isLContainer(lNode)) {
            for (let i = CONTAINER_HEADER_OFFSET; i < lNode.length; i++) {
                const lViewInAContainer = lNode[i];
                const lViewFirstChildTNode = lViewInAContainer[TVIEW].firstChild;
                if (lViewFirstChildTNode !== null) {
                    collectNativeNodes(lViewInAContainer[TVIEW], lViewInAContainer, lViewFirstChildTNode, result);
                }
            }
            // When an LContainer is created, the anchor (comment) node is:
            // - (1) either reused in case of an ElementContainer (<ng-container>)
            // - (2) or a new comment node is created
            // In the first case, the anchor comment node would be added to the final
            // list by the code above (`result.push(unwrapRNode(lNode))`), but the second
            // case requires extra handling: the anchor node needs to be added to the
            // final list manually. See additional information in the `createAnchorNode`
            // function in the `view_container_ref.ts`.
            //
            // In the first case, the same reference would be stored in the `NATIVE`
            // and `HOST` slots in an LContainer. Otherwise, this is the second case and
            // we should add an element to the final list.
            if (lNode[NATIVE] !== lNode[HOST]) {
                result.push(lNode[NATIVE]);
            }
        }
        const tNodeType = tNode.type;
        if (tNodeType & 8 /* TNodeType.ElementContainer */) {
            collectNativeNodes(tView, lView, tNode.child, result);
        }
        else if (tNodeType & 32 /* TNodeType.Icu */) {
            const nextRNode = icuContainerIterate(tNode, lView);
            let rNode;
            while (rNode = nextRNode()) {
                result.push(rNode);
            }
        }
        else if (tNodeType & 16 /* TNodeType.Projection */) {
            const nodesInSlot = getProjectionNodes(lView, tNode);
            if (Array.isArray(nodesInSlot)) {
                result.push(...nodesInSlot);
            }
            else {
                const parentView = getLViewParent(lView[DECLARATION_COMPONENT_VIEW]);
                ngDevMode && assertParentView(parentView);
                collectNativeNodes(parentView[TVIEW], parentView, nodesInSlot, result, true);
            }
        }
        tNode = isProjection ? tNode.projectionNext : tNode.next;
    }
    return result;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29sbGVjdF9uYXRpdmVfbm9kZXMuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL2NvbGxlY3RfbmF0aXZlX25vZGVzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxnQkFBZ0IsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUMxQyxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSwwQkFBMEIsQ0FBQztBQUM3RCxPQUFPLEVBQUMsdUJBQXVCLEVBQUUsTUFBTSxFQUFDLE1BQU0sd0JBQXdCLENBQUM7QUFHdkUsT0FBTyxFQUFDLFlBQVksRUFBQyxNQUFNLDBCQUEwQixDQUFDO0FBQ3RELE9BQU8sRUFBQywwQkFBMEIsRUFBRSxJQUFJLEVBQWlCLEtBQUssRUFBUSxNQUFNLG1CQUFtQixDQUFDO0FBQ2hHLE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFDOUMsT0FBTyxFQUFDLGtCQUFrQixFQUFDLE1BQU0scUJBQXFCLENBQUM7QUFDdkQsT0FBTyxFQUFDLGNBQWMsRUFBQyxNQUFNLDZCQUE2QixDQUFDO0FBQzNELE9BQU8sRUFBQyxXQUFXLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUk5QyxNQUFNLFVBQVUsa0JBQWtCLENBQzlCLEtBQVksRUFBRSxLQUFZLEVBQUUsS0FBaUIsRUFBRSxNQUFhLEVBQzVELGVBQXdCLEtBQUs7SUFDL0IsT0FBTyxLQUFLLEtBQUssSUFBSSxFQUFFO1FBQ3JCLFNBQVM7WUFDTCxlQUFlLENBQ1gsS0FBSyxFQUNMLDREQUEyQyxnQ0FBdUIseUJBQWdCLENBQUMsQ0FBQztRQUU1RixNQUFNLEtBQUssR0FBRyxLQUFLLENBQUMsS0FBSyxDQUFDLEtBQUssQ0FBQyxDQUFDO1FBQ2pDLElBQUksS0FBSyxLQUFLLElBQUksRUFBRTtZQUNsQixNQUFNLENBQUMsSUFBSSxDQUFDLFdBQVcsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDO1NBQ2pDO1FBRUQsMkZBQTJGO1FBQzNGLGdHQUFnRztRQUNoRyxvQ0FBb0M7UUFDcEMsSUFBSSxZQUFZLENBQUMsS0FBSyxDQUFDLEVBQUU7WUFDdkIsS0FBSyxJQUFJLENBQUMsR0FBRyx1QkFBdUIsRUFBRSxDQUFDLEdBQUcsS0FBSyxDQUFDLE1BQU0sRUFBRSxDQUFDLEVBQUUsRUFBRTtnQkFDM0QsTUFBTSxpQkFBaUIsR0FBRyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUM7Z0JBQ25DLE1BQU0sb0JBQW9CLEdBQUcsaUJBQWlCLENBQUMsS0FBSyxDQUFDLENBQUMsVUFBVSxDQUFDO2dCQUNqRSxJQUFJLG9CQUFvQixLQUFLLElBQUksRUFBRTtvQkFDakMsa0JBQWtCLENBQ2QsaUJBQWlCLENBQUMsS0FBSyxDQUFDLEVBQUUsaUJBQWlCLEVBQUUsb0JBQW9CLEVBQUUsTUFBTSxDQUFDLENBQUM7aUJBQ2hGO2FBQ0Y7WUFFRCwrREFBK0Q7WUFDL0Qsc0VBQXNFO1lBQ3RFLHlDQUF5QztZQUN6Qyx5RUFBeUU7WUFDekUsNkVBQTZFO1lBQzdFLHlFQUF5RTtZQUN6RSw0RUFBNEU7WUFDNUUsMkNBQTJDO1lBQzNDLEVBQUU7WUFDRix3RUFBd0U7WUFDeEUsNEVBQTRFO1lBQzVFLDhDQUE4QztZQUM5QyxJQUFJLEtBQUssQ0FBQyxNQUFNLENBQUMsS0FBSyxLQUFLLENBQUMsSUFBSSxDQUFDLEVBQUU7Z0JBQ2pDLE1BQU0sQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUM7YUFDNUI7U0FDRjtRQUVELE1BQU0sU0FBUyxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUM7UUFDN0IsSUFBSSxTQUFTLHFDQUE2QixFQUFFO1lBQzFDLGtCQUFrQixDQUFDLEtBQUssRUFBRSxLQUFLLEVBQUUsS0FBSyxDQUFDLEtBQUssRUFBRSxNQUFNLENBQUMsQ0FBQztTQUN2RDthQUFNLElBQUksU0FBUyx5QkFBZ0IsRUFBRTtZQUNwQyxNQUFNLFNBQVMsR0FBRyxtQkFBbUIsQ0FBQyxLQUEwQixFQUFFLEtBQUssQ0FBQyxDQUFDO1lBQ3pFLElBQUksS0FBaUIsQ0FBQztZQUN0QixPQUFPLEtBQUssR0FBRyxTQUFTLEVBQUUsRUFBRTtnQkFDMUIsTUFBTSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsQ0FBQzthQUNwQjtTQUNGO2FBQU0sSUFBSSxTQUFTLGdDQUF1QixFQUFFO1lBQzNDLE1BQU0sV0FBVyxHQUFHLGtCQUFrQixDQUFDLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztZQUNyRCxJQUFJLEtBQUssQ0FBQyxPQUFPLENBQUMsV0FBVyxDQUFDLEVBQUU7Z0JBQzlCLE1BQU0sQ0FBQyxJQUFJLENBQUMsR0FBRyxXQUFXLENBQUMsQ0FBQzthQUM3QjtpQkFBTTtnQkFDTCxNQUFNLFVBQVUsR0FBRyxjQUFjLENBQUMsS0FBSyxDQUFDLDBCQUEwQixDQUFDLENBQUUsQ0FBQztnQkFDdEUsU0FBUyxJQUFJLGdCQUFnQixDQUFDLFVBQVUsQ0FBQyxDQUFDO2dCQUMxQyxrQkFBa0IsQ0FBQyxVQUFVLENBQUMsS0FBSyxDQUFDLEVBQUUsVUFBVSxFQUFFLFdBQVcsRUFBRSxNQUFNLEVBQUUsSUFBSSxDQUFDLENBQUM7YUFDOUU7U0FDRjtRQUNELEtBQUssR0FBRyxZQUFZLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxjQUFjLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxJQUFJLENBQUM7S0FDMUQ7SUFFRCxPQUFPLE1BQU0sQ0FBQztBQUNoQixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7YXNzZXJ0UGFyZW50Vmlld30gZnJvbSAnLi9hc3NlcnQnO1xuaW1wb3J0IHtpY3VDb250YWluZXJJdGVyYXRlfSBmcm9tICcuL2kxOG4vaTE4bl90cmVlX3NoYWtpbmcnO1xuaW1wb3J0IHtDT05UQUlORVJfSEVBREVSX09GRlNFVCwgTkFUSVZFfSBmcm9tICcuL2ludGVyZmFjZXMvY29udGFpbmVyJztcbmltcG9ydCB7VEljdUNvbnRhaW5lck5vZGUsIFROb2RlLCBUTm9kZVR5cGV9IGZyb20gJy4vaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7Uk5vZGV9IGZyb20gJy4vaW50ZXJmYWNlcy9yZW5kZXJlcl9kb20nO1xuaW1wb3J0IHtpc0xDb250YWluZXJ9IGZyb20gJy4vaW50ZXJmYWNlcy90eXBlX2NoZWNrcyc7XG5pbXBvcnQge0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXLCBIT1NULCBMVmlldywgVF9IT1NULCBUVklFVywgVFZpZXd9IGZyb20gJy4vaW50ZXJmYWNlcy92aWV3JztcbmltcG9ydCB7YXNzZXJ0VE5vZGVUeXBlfSBmcm9tICcuL25vZGVfYXNzZXJ0JztcbmltcG9ydCB7Z2V0UHJvamVjdGlvbk5vZGVzfSBmcm9tICcuL25vZGVfbWFuaXB1bGF0aW9uJztcbmltcG9ydCB7Z2V0TFZpZXdQYXJlbnR9IGZyb20gJy4vdXRpbC92aWV3X3RyYXZlcnNhbF91dGlscyc7XG5pbXBvcnQge3Vud3JhcFJOb2RlfSBmcm9tICcuL3V0aWwvdmlld191dGlscyc7XG5cblxuXG5leHBvcnQgZnVuY3Rpb24gY29sbGVjdE5hdGl2ZU5vZGVzKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCB0Tm9kZTogVE5vZGV8bnVsbCwgcmVzdWx0OiBhbnlbXSxcbiAgICBpc1Byb2plY3Rpb246IGJvb2xlYW4gPSBmYWxzZSk6IGFueVtdIHtcbiAgd2hpbGUgKHROb2RlICE9PSBudWxsKSB7XG4gICAgbmdEZXZNb2RlICYmXG4gICAgICAgIGFzc2VydFROb2RlVHlwZShcbiAgICAgICAgICAgIHROb2RlLFxuICAgICAgICAgICAgVE5vZGVUeXBlLkFueVJOb2RlIHwgVE5vZGVUeXBlLkFueUNvbnRhaW5lciB8IFROb2RlVHlwZS5Qcm9qZWN0aW9uIHwgVE5vZGVUeXBlLkljdSk7XG5cbiAgICBjb25zdCBsTm9kZSA9IGxWaWV3W3ROb2RlLmluZGV4XTtcbiAgICBpZiAobE5vZGUgIT09IG51bGwpIHtcbiAgICAgIHJlc3VsdC5wdXNoKHVud3JhcFJOb2RlKGxOb2RlKSk7XG4gICAgfVxuXG4gICAgLy8gQSBnaXZlbiBsTm9kZSBjYW4gcmVwcmVzZW50IGVpdGhlciBhIG5hdGl2ZSBub2RlIG9yIGEgTENvbnRhaW5lciAod2hlbiBpdCBpcyBhIGhvc3Qgb2YgYVxuICAgIC8vIFZpZXdDb250YWluZXJSZWYpLiBXaGVuIHdlIGZpbmQgYSBMQ29udGFpbmVyIHdlIG5lZWQgdG8gZGVzY2VuZCBpbnRvIGl0IHRvIGNvbGxlY3Qgcm9vdCBub2Rlc1xuICAgIC8vIGZyb20gdGhlIHZpZXdzIGluIHRoaXMgY29udGFpbmVyLlxuICAgIGlmIChpc0xDb250YWluZXIobE5vZGUpKSB7XG4gICAgICBmb3IgKGxldCBpID0gQ09OVEFJTkVSX0hFQURFUl9PRkZTRVQ7IGkgPCBsTm9kZS5sZW5ndGg7IGkrKykge1xuICAgICAgICBjb25zdCBsVmlld0luQUNvbnRhaW5lciA9IGxOb2RlW2ldO1xuICAgICAgICBjb25zdCBsVmlld0ZpcnN0Q2hpbGRUTm9kZSA9IGxWaWV3SW5BQ29udGFpbmVyW1RWSUVXXS5maXJzdENoaWxkO1xuICAgICAgICBpZiAobFZpZXdGaXJzdENoaWxkVE5vZGUgIT09IG51bGwpIHtcbiAgICAgICAgICBjb2xsZWN0TmF0aXZlTm9kZXMoXG4gICAgICAgICAgICAgIGxWaWV3SW5BQ29udGFpbmVyW1RWSUVXXSwgbFZpZXdJbkFDb250YWluZXIsIGxWaWV3Rmlyc3RDaGlsZFROb2RlLCByZXN1bHQpO1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIFdoZW4gYW4gTENvbnRhaW5lciBpcyBjcmVhdGVkLCB0aGUgYW5jaG9yIChjb21tZW50KSBub2RlIGlzOlxuICAgICAgLy8gLSAoMSkgZWl0aGVyIHJldXNlZCBpbiBjYXNlIG9mIGFuIEVsZW1lbnRDb250YWluZXIgKDxuZy1jb250YWluZXI+KVxuICAgICAgLy8gLSAoMikgb3IgYSBuZXcgY29tbWVudCBub2RlIGlzIGNyZWF0ZWRcbiAgICAgIC8vIEluIHRoZSBmaXJzdCBjYXNlLCB0aGUgYW5jaG9yIGNvbW1lbnQgbm9kZSB3b3VsZCBiZSBhZGRlZCB0byB0aGUgZmluYWxcbiAgICAgIC8vIGxpc3QgYnkgdGhlIGNvZGUgYWJvdmUgKGByZXN1bHQucHVzaCh1bndyYXBSTm9kZShsTm9kZSkpYCksIGJ1dCB0aGUgc2Vjb25kXG4gICAgICAvLyBjYXNlIHJlcXVpcmVzIGV4dHJhIGhhbmRsaW5nOiB0aGUgYW5jaG9yIG5vZGUgbmVlZHMgdG8gYmUgYWRkZWQgdG8gdGhlXG4gICAgICAvLyBmaW5hbCBsaXN0IG1hbnVhbGx5LiBTZWUgYWRkaXRpb25hbCBpbmZvcm1hdGlvbiBpbiB0aGUgYGNyZWF0ZUFuY2hvck5vZGVgXG4gICAgICAvLyBmdW5jdGlvbiBpbiB0aGUgYHZpZXdfY29udGFpbmVyX3JlZi50c2AuXG4gICAgICAvL1xuICAgICAgLy8gSW4gdGhlIGZpcnN0IGNhc2UsIHRoZSBzYW1lIHJlZmVyZW5jZSB3b3VsZCBiZSBzdG9yZWQgaW4gdGhlIGBOQVRJVkVgXG4gICAgICAvLyBhbmQgYEhPU1RgIHNsb3RzIGluIGFuIExDb250YWluZXIuIE90aGVyd2lzZSwgdGhpcyBpcyB0aGUgc2Vjb25kIGNhc2UgYW5kXG4gICAgICAvLyB3ZSBzaG91bGQgYWRkIGFuIGVsZW1lbnQgdG8gdGhlIGZpbmFsIGxpc3QuXG4gICAgICBpZiAobE5vZGVbTkFUSVZFXSAhPT0gbE5vZGVbSE9TVF0pIHtcbiAgICAgICAgcmVzdWx0LnB1c2gobE5vZGVbTkFUSVZFXSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgY29uc3QgdE5vZGVUeXBlID0gdE5vZGUudHlwZTtcbiAgICBpZiAodE5vZGVUeXBlICYgVE5vZGVUeXBlLkVsZW1lbnRDb250YWluZXIpIHtcbiAgICAgIGNvbGxlY3ROYXRpdmVOb2Rlcyh0VmlldywgbFZpZXcsIHROb2RlLmNoaWxkLCByZXN1bHQpO1xuICAgIH0gZWxzZSBpZiAodE5vZGVUeXBlICYgVE5vZGVUeXBlLkljdSkge1xuICAgICAgY29uc3QgbmV4dFJOb2RlID0gaWN1Q29udGFpbmVySXRlcmF0ZSh0Tm9kZSBhcyBUSWN1Q29udGFpbmVyTm9kZSwgbFZpZXcpO1xuICAgICAgbGV0IHJOb2RlOiBSTm9kZXxudWxsO1xuICAgICAgd2hpbGUgKHJOb2RlID0gbmV4dFJOb2RlKCkpIHtcbiAgICAgICAgcmVzdWx0LnB1c2gock5vZGUpO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZiAodE5vZGVUeXBlICYgVE5vZGVUeXBlLlByb2plY3Rpb24pIHtcbiAgICAgIGNvbnN0IG5vZGVzSW5TbG90ID0gZ2V0UHJvamVjdGlvbk5vZGVzKGxWaWV3LCB0Tm9kZSk7XG4gICAgICBpZiAoQXJyYXkuaXNBcnJheShub2Rlc0luU2xvdCkpIHtcbiAgICAgICAgcmVzdWx0LnB1c2goLi4ubm9kZXNJblNsb3QpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY29uc3QgcGFyZW50VmlldyA9IGdldExWaWV3UGFyZW50KGxWaWV3W0RFQ0xBUkFUSU9OX0NPTVBPTkVOVF9WSUVXXSkhO1xuICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0UGFyZW50VmlldyhwYXJlbnRWaWV3KTtcbiAgICAgICAgY29sbGVjdE5hdGl2ZU5vZGVzKHBhcmVudFZpZXdbVFZJRVddLCBwYXJlbnRWaWV3LCBub2Rlc0luU2xvdCwgcmVzdWx0LCB0cnVlKTtcbiAgICAgIH1cbiAgICB9XG4gICAgdE5vZGUgPSBpc1Byb2plY3Rpb24gPyB0Tm9kZS5wcm9qZWN0aW9uTmV4dCA6IHROb2RlLm5leHQ7XG4gIH1cblxuICByZXR1cm4gcmVzdWx0O1xufVxuIl19