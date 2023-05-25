/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { map } from 'rxjs/operators';
import { ActivationEnd, ChildActivationEnd } from '../events';
import { advanceActivatedRoute } from '../router_state';
import { getClosestRouteInjector } from '../utils/config';
import { nodeChildrenAsMap } from '../utils/tree';
let warnedAboutUnsupportedInputBinding = false;
export const activateRoutes = (rootContexts, routeReuseStrategy, forwardEvent, inputBindingEnabled) => map(t => {
    new ActivateRoutes(routeReuseStrategy, t.targetRouterState, t.currentRouterState, forwardEvent, inputBindingEnabled)
        .activate(rootContexts);
    return t;
});
export class ActivateRoutes {
    constructor(routeReuseStrategy, futureState, currState, forwardEvent, inputBindingEnabled) {
        this.routeReuseStrategy = routeReuseStrategy;
        this.futureState = futureState;
        this.currState = currState;
        this.forwardEvent = forwardEvent;
        this.inputBindingEnabled = inputBindingEnabled;
    }
    activate(parentContexts) {
        const futureRoot = this.futureState._root;
        const currRoot = this.currState ? this.currState._root : null;
        this.deactivateChildRoutes(futureRoot, currRoot, parentContexts);
        advanceActivatedRoute(this.futureState.root);
        this.activateChildRoutes(futureRoot, currRoot, parentContexts);
    }
    // De-activate the child route that are not re-used for the future state
    deactivateChildRoutes(futureNode, currNode, contexts) {
        const children = nodeChildrenAsMap(currNode);
        // Recurse on the routes active in the future state to de-activate deeper children
        futureNode.children.forEach(futureChild => {
            const childOutletName = futureChild.value.outlet;
            this.deactivateRoutes(futureChild, children[childOutletName], contexts);
            delete children[childOutletName];
        });
        // De-activate the routes that will not be re-used
        Object.values(children).forEach((v) => {
            this.deactivateRouteAndItsChildren(v, contexts);
        });
    }
    deactivateRoutes(futureNode, currNode, parentContext) {
        const future = futureNode.value;
        const curr = currNode ? currNode.value : null;
        if (future === curr) {
            // Reusing the node, check to see if the children need to be de-activated
            if (future.component) {
                // If we have a normal route, we need to go through an outlet.
                const context = parentContext.getContext(future.outlet);
                if (context) {
                    this.deactivateChildRoutes(futureNode, currNode, context.children);
                }
            }
            else {
                // if we have a componentless route, we recurse but keep the same outlet map.
                this.deactivateChildRoutes(futureNode, currNode, parentContext);
            }
        }
        else {
            if (curr) {
                // Deactivate the current route which will not be re-used
                this.deactivateRouteAndItsChildren(currNode, parentContext);
            }
        }
    }
    deactivateRouteAndItsChildren(route, parentContexts) {
        // If there is no component, the Route is never attached to an outlet (because there is no
        // component to attach).
        if (route.value.component && this.routeReuseStrategy.shouldDetach(route.value.snapshot)) {
            this.detachAndStoreRouteSubtree(route, parentContexts);
        }
        else {
            this.deactivateRouteAndOutlet(route, parentContexts);
        }
    }
    detachAndStoreRouteSubtree(route, parentContexts) {
        const context = parentContexts.getContext(route.value.outlet);
        const contexts = context && route.value.component ? context.children : parentContexts;
        const children = nodeChildrenAsMap(route);
        for (const childOutlet of Object.keys(children)) {
            this.deactivateRouteAndItsChildren(children[childOutlet], contexts);
        }
        if (context && context.outlet) {
            const componentRef = context.outlet.detach();
            const contexts = context.children.onOutletDeactivated();
            this.routeReuseStrategy.store(route.value.snapshot, { componentRef, route, contexts });
        }
    }
    deactivateRouteAndOutlet(route, parentContexts) {
        const context = parentContexts.getContext(route.value.outlet);
        // The context could be `null` if we are on a componentless route but there may still be
        // children that need deactivating.
        const contexts = context && route.value.component ? context.children : parentContexts;
        const children = nodeChildrenAsMap(route);
        for (const childOutlet of Object.keys(children)) {
            this.deactivateRouteAndItsChildren(children[childOutlet], contexts);
        }
        if (context) {
            if (context.outlet) {
                // Destroy the component
                context.outlet.deactivate();
                // Destroy the contexts for all the outlets that were in the component
                context.children.onOutletDeactivated();
            }
            // Clear the information about the attached component on the context but keep the reference to
            // the outlet. Clear even if outlet was not yet activated to avoid activating later with old
            // info
            context.attachRef = null;
            context.route = null;
        }
    }
    activateChildRoutes(futureNode, currNode, contexts) {
        const children = nodeChildrenAsMap(currNode);
        futureNode.children.forEach(c => {
            this.activateRoutes(c, children[c.value.outlet], contexts);
            this.forwardEvent(new ActivationEnd(c.value.snapshot));
        });
        if (futureNode.children.length) {
            this.forwardEvent(new ChildActivationEnd(futureNode.value.snapshot));
        }
    }
    activateRoutes(futureNode, currNode, parentContexts) {
        const future = futureNode.value;
        const curr = currNode ? currNode.value : null;
        advanceActivatedRoute(future);
        // reusing the node
        if (future === curr) {
            if (future.component) {
                // If we have a normal route, we need to go through an outlet.
                const context = parentContexts.getOrCreateContext(future.outlet);
                this.activateChildRoutes(futureNode, currNode, context.children);
            }
            else {
                // if we have a componentless route, we recurse but keep the same outlet map.
                this.activateChildRoutes(futureNode, currNode, parentContexts);
            }
        }
        else {
            if (future.component) {
                // if we have a normal route, we need to place the component into the outlet and recurse.
                const context = parentContexts.getOrCreateContext(future.outlet);
                if (this.routeReuseStrategy.shouldAttach(future.snapshot)) {
                    const stored = this.routeReuseStrategy.retrieve(future.snapshot);
                    this.routeReuseStrategy.store(future.snapshot, null);
                    context.children.onOutletReAttached(stored.contexts);
                    context.attachRef = stored.componentRef;
                    context.route = stored.route.value;
                    if (context.outlet) {
                        // Attach right away when the outlet has already been instantiated
                        // Otherwise attach from `RouterOutlet.ngOnInit` when it is instantiated
                        context.outlet.attach(stored.componentRef, stored.route.value);
                    }
                    advanceActivatedRoute(stored.route.value);
                    this.activateChildRoutes(futureNode, null, context.children);
                }
                else {
                    const injector = getClosestRouteInjector(future.snapshot);
                    context.attachRef = null;
                    context.route = future;
                    context.injector = injector;
                    if (context.outlet) {
                        // Activate the outlet when it has already been instantiated
                        // Otherwise it will get activated from its `ngOnInit` when instantiated
                        context.outlet.activateWith(future, context.injector);
                    }
                    this.activateChildRoutes(futureNode, null, context.children);
                }
            }
            else {
                // if we have a componentless route, we recurse but keep the same outlet map.
                this.activateChildRoutes(futureNode, null, parentContexts);
            }
        }
        if ((typeof ngDevMode === 'undefined' || ngDevMode)) {
            const context = parentContexts.getOrCreateContext(future.outlet);
            const outlet = context.outlet;
            if (outlet && this.inputBindingEnabled && !outlet.supportsBindingToComponentInputs &&
                !warnedAboutUnsupportedInputBinding) {
                console.warn(`'withComponentInputBinding' feature is enabled but ` +
                    `this application is using an outlet that may not support binding to component inputs.`);
                warnedAboutUnsupportedInputBinding = true;
            }
        }
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYWN0aXZhdGVfcm91dGVzLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvcm91dGVyL3NyYy9vcGVyYXRvcnMvYWN0aXZhdGVfcm91dGVzLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxHQUFHLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUVuQyxPQUFPLEVBQUMsYUFBYSxFQUFFLGtCQUFrQixFQUFRLE1BQU0sV0FBVyxDQUFDO0FBSW5FLE9BQU8sRUFBaUIscUJBQXFCLEVBQWMsTUFBTSxpQkFBaUIsQ0FBQztBQUNuRixPQUFPLEVBQUMsdUJBQXVCLEVBQUMsTUFBTSxpQkFBaUIsQ0FBQztBQUN4RCxPQUFPLEVBQUMsaUJBQWlCLEVBQVcsTUFBTSxlQUFlLENBQUM7QUFFMUQsSUFBSSxrQ0FBa0MsR0FBRyxLQUFLLENBQUM7QUFFL0MsTUFBTSxDQUFDLE1BQU0sY0FBYyxHQUN2QixDQUFDLFlBQW9DLEVBQUUsa0JBQXNDLEVBQzVFLFlBQWtDLEVBQ2xDLG1CQUE0QixFQUFrRCxFQUFFLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxFQUFFO0lBQ3hGLElBQUksY0FBYyxDQUNkLGtCQUFrQixFQUFFLENBQUMsQ0FBQyxpQkFBa0IsRUFBRSxDQUFDLENBQUMsa0JBQWtCLEVBQUUsWUFBWSxFQUM1RSxtQkFBbUIsQ0FBQztTQUNuQixRQUFRLENBQUMsWUFBWSxDQUFDLENBQUM7SUFDNUIsT0FBTyxDQUFDLENBQUM7QUFDWCxDQUFDLENBQUMsQ0FBQztBQUVQLE1BQU0sT0FBTyxjQUFjO0lBQ3pCLFlBQ1ksa0JBQXNDLEVBQVUsV0FBd0IsRUFDeEUsU0FBc0IsRUFBVSxZQUFrQyxFQUNsRSxtQkFBNEI7UUFGNUIsdUJBQWtCLEdBQWxCLGtCQUFrQixDQUFvQjtRQUFVLGdCQUFXLEdBQVgsV0FBVyxDQUFhO1FBQ3hFLGNBQVMsR0FBVCxTQUFTLENB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LENBQUMsTUFBTSxFQUFFLE9BQU8sQ0FBQyxRQUFRLENBQUMsQ0FBQztxQkFDdkQ7b0JBRUQsSUFBSSxDQUFDLG1CQUFtQixDQUFDLFVBQVUsRUFBRSxJQUFJLEVBQUUsT0FBTyxDQUFDLFFBQVEsQ0FBQyxDQUFDO2lCQUM5RDthQUNGO2lCQUFNO2dCQUNMLDZFQUE2RTtnQkFDN0UsSUFBSSxDQUFDLG1CQUFtQixDQUFDLFVBQVUsRUFBRSxJQUFJLEVBQUUsY0FBYyxDQUFDLENBQUM7YUFDNUQ7U0FDRjtRQUNELElBQUksQ0FBQyxPQUFPLFNBQVMsS0FBSyxXQUFXLElBQUksU0FBUyxDQUFDLEVBQUU7WUFDbkQsTUFBTSxPQUFPLEdBQUcsY0FBYyxDQUFDLGtCQUFrQixDQUFDLE1BQU0sQ0FBQyxNQUFNLENBQUMsQ0FBQztZQUNqRSxNQUFNLE1BQU0sR0FBRyxPQUFPLENBQUMsTUFBTSxDQUFDO1lBQzlCLElBQUksTUFBTSxJQUFJLElBQUksQ0FBQyxtQkFBbUIsSUFBSSxDQUFDLE1BQU0sQ0FBQyxnQ0FBZ0M7Z0JBQzlFLENBQUMsa0NBQWtDLEVBQUU7Z0JBQ3ZDLE9BQU8sQ0FBQyxJQUFJLENBQ1IscURBQXFEO29CQUNyRCx1RkFBdUYsQ0FBQyxDQUFDO2dCQUM3RixrQ0FBa0MsR0FBRyxJQUFJLENBQUM7YUFDM0M7U0FDRjtJQUNILENBQUM7Q0FDRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge01vbm9UeXBlT3BlcmF0b3JGdW5jdGlvbn0gZnJvbSAncnhqcyc7XG5pbXBvcnQge21hcH0gZnJvbSAncnhqcy9vcGVyYXRvcnMnO1xuXG5pbXBvcnQge0FjdGl2YXRpb25FbmQsIENoaWxkQWN0aXZhdGlvbkVuZCwgRXZlbnR9IGZyb20gJy4uL2V2ZW50cyc7XG5pbXBvcnQge05hdmlnYXRpb25UcmFuc2l0aW9ufSBmcm9tICcuLi9uYXZpZ2F0aW9uX3RyYW5zaXRpb24nO1xuaW1wb3J0IHtEZXRhY2hlZFJvdXRlSGFuZGxlSW50ZXJuYWwsIFJvdXRlUmV1c2VTdHJhdGVneX0gZnJvbSAnLi4vcm91dGVfcmV1c2Vfc3RyYXRlZ3knO1xuaW1wb3J0IHtDaGlsZHJlbk91dGxldENvbnRleHRzfSBmcm9tICcuLi9yb3V0ZXJfb3V0bGV0X2NvbnRleHQnO1xuaW1wb3J0IHtBY3RpdmF0ZWRSb3V0ZSwgYWR2YW5jZUFjdGl2YXRlZFJvdXRlLCBSb3V0ZXJTdGF0ZX0gZnJvbSAnLi4vcm91dGVyX3N0YXRlJztcbmltcG9ydCB7Z2V0Q2xvc2VzdFJvdXRlSW5qZWN0b3J9IGZyb20gJy4uL3V0aWxzL2NvbmZpZyc7XG5pbXBvcnQge25vZGVDaGlsZHJlbkFzTWFwLCBUcmVlTm9kZX0gZnJvbSAnLi4vdXRpbHMvdHJlZSc7XG5cbmxldCB3YXJuZWRBYm91dFVuc3VwcG9ydGVkSW5wdXRCaW5kaW5nID0gZmFsc2U7XG5cbmV4cG9ydCBjb25zdCBhY3RpdmF0ZVJvdXRlcyA9XG4gICAgKHJvb3RDb250ZXh0czogQ2hpbGRyZW5PdXRsZXRDb250ZXh0cywgcm91dGVSZXVzZVN0cmF0ZWd5OiBSb3V0ZVJldXNlU3RyYXRlZ3ksXG4gICAgIGZvcndhcmRFdmVudDogKGV2dDogRXZlbnQpID0+IHZvaWQsXG4gICAgIGlucHV0QmluZGluZ0VuYWJsZWQ6IGJvb2xlYW4pOiBNb25vVHlwZU9wZXJhdG9yRnVuY3Rpb248TmF2aWdhdGlvblRyYW5zaXRpb24+ID0+IG1hcCh0ID0+IHtcbiAgICAgIG5ldyBBY3RpdmF0ZVJvdXRlcyhcbiAgICAgICAgICByb3V0ZVJldXNlU3RyYXRlZ3ksIHQudGFyZ2V0Um91dGVyU3RhdGUhLCB0LmN1cnJlbnRSb3V0ZXJTdGF0ZSwgZm9yd2FyZEV2ZW50LFxuICAgICAgICAgIGlucHV0QmluZGluZ0VuYWJsZWQpXG4gICAgICAgICAgLmFjdGl2YXRlKHJvb3RDb250ZXh0cyk7XG4gICAgICByZXR1cm4gdDtcbiAgICB9KTtcblxuZXhwb3J0IGNsYXNzIEFjdGl2YXRlUm91dGVzIHtcbiAgY29uc3RydWN0b3IoXG4gICAgICBwcml2YXRlIHJvdXRlUmV1c2VTdHJhdGVneTogUm91dGVSZXVzZVN0cmF0ZWd5LCBwcml2YXRlIGZ1dHVyZVN0YXRlOiBSb3V0ZXJTdGF0ZSxcbiAgICAgIHByaXZhdGUgY3VyclN0YXRlOiBSb3V0ZXJTdGF0ZSwgcHJpdmF0ZSBmb3J3YXJkRXZlbnQ6IChldnQ6IEV2ZW50KSA9PiB2b2lkLFxuICAgICAgcHJpdmF0ZSBpbnB1dEJpbmRpbmdFbmFibGVkOiBib29sZWFuKSB7fVxuXG4gIGFjdGl2YXRlKHBhcmVudENvbnRleHRzOiBDaGlsZHJlbk91dGxldENvbnRleHRzKTogdm9pZCB7XG4gICAgY29uc3QgZnV0dXJlUm9vdCA9IHRoaXMuZnV0dXJlU3RhdGUuX3Jvb3Q7XG4gICAgY29uc3QgY3VyclJvb3QgPSB0aGlzLmN1cnJTdGF0ZSA/IHRoaXMuY3VyclN0YXRlLl9yb290IDogbnVsbDtcblxuICAgIHRoaXMuZGVhY3RpdmF0ZUNoaWxkUm91dGVzKGZ1dHVyZVJvb3QsIGN1cnJSb290LCBwYXJlbnRDb250ZXh0cyk7XG4gICAgYWR2YW5jZUFjdGl2YXRlZFJvdXRlKHRoaXMuZnV0dXJlU3RhdGUucm9vdCk7XG4gICAgdGhpcy5hY3RpdmF0ZUNoaWxkUm91dGVzKGZ1dHVyZVJvb3QsIGN1cnJSb290LCBwYXJlbnRDb250ZXh0cyk7XG4gIH1cblxuICAvLyBEZS1hY3RpdmF0ZSB0aGUgY2hpbGQgcm91dGUgdGhhdCBhcmUgbm90IHJlLXVzZWQgZm9yIHRoZSBmdXR1cmUgc3RhdGVcbiAgcHJpdmF0ZSBkZWFjdGl2YXRlQ2hpbGRSb3V0ZXMoXG4gICAgICBmdXR1cmVOb2RlOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZT4sIGN1cnJOb2RlOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZT58bnVsbCxcbiAgICAgIGNvbnRleHRzOiBDaGlsZHJlbk91dGxldENvbnRleHRzKTogdm9pZCB7XG4gICAgY29uc3QgY2hpbGRyZW46IHtbb3V0bGV0TmFtZTogc3RyaW5nXTogVHJlZU5vZGU8QWN0aXZhdGVkUm91dGU+fSA9IG5vZGVDaGlsZHJlbkFzTWFwKGN1cnJOb2RlKTtcblxuICAgIC8vIFJlY3Vyc2Ugb24gdGhlIHJvdXRlcyBhY3RpdmUgaW4gdGhlIGZ1dHVyZSBzdGF0ZSB0byBkZS1hY3RpdmF0ZSBkZWVwZXIgY2hpbGRyZW5cbiAgICBmdXR1cmVOb2RlLmNoaWxkcmVuLmZvckVhY2goZnV0dXJlQ2hpbGQgPT4ge1xuICAgICAgY29uc3QgY2hpbGRPdXRsZXROYW1lID0gZnV0dXJlQ2hpbGQudmFsdWUub3V0bGV0O1xuICAgICAgdGhpcy5kZWFjdGl2YXRlUm91dGVzKGZ1dHVyZUNoaWxkLCBjaGlsZHJlbltjaGlsZE91dGxldE5hbWVdLCBjb250ZXh0cyk7XG4gICAgICBkZWxldGUgY2hpbGRyZW5bY2hpbGRPdXRsZXROYW1lXTtcbiAgICB9KTtcblxuICAgIC8vIERlLWFjdGl2YXRlIHRoZSByb3V0ZXMgdGhhdCB3aWxsIG5vdCBiZSByZS11c2VkXG4gICAgT2JqZWN0LnZhbHVlcyhjaGlsZHJlbikuZm9yRWFjaCgodjogVHJlZU5vZGU8QWN0aXZhdGVkUm91dGU+KSA9PiB7XG4gICAgICB0aGlzLmRlYWN0aXZhdGVSb3V0ZUFuZEl0c0NoaWxkcmVuKHYsIGNvbnRleHRzKTtcbiAgICB9KTtcbiAgfVxuXG4gIHByaXZhdGUgZGVhY3RpdmF0ZVJvdXRlcyhcbiAgICAgIGZ1dHVyZU5vZGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPiwgY3Vyck5vZGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPixcbiAgICAgIHBhcmVudENvbnRleHQ6IENoaWxkcmVuT3V0bGV0Q29udGV4dHMpOiB2b2lkIHtcbiAgICBjb25zdCBmdXR1cmUgPSBmdXR1cmVOb2RlLnZhbHVlO1xuICAgIGNvbnN0IGN1cnIgPSBjdXJyTm9kZSA/IGN1cnJOb2RlLnZhbHVlIDogbnVsbDtcblxuICAgIGlmIChmdXR1cmUgPT09IGN1cnIpIHtcbiAgICAgIC8vIFJldXNpbmcgdGhlIG5vZGUsIGNoZWNrIHRvIHNlZSBpZiB0aGUgY2hpbGRyZW4gbmVlZCB0byBiZSBkZS1hY3RpdmF0ZWRcbiAgICAgIGlmIChmdXR1cmUuY29tcG9uZW50KSB7XG4gICAgICAgIC8vIElmIHdlIGhhdmUgYSBub3JtYWwgcm91dGUsIHdlIG5lZWQgdG8gZ28gdGhyb3VnaCBhbiBvdXRsZXQuXG4gICAgICAgIGNvbnN0IGNvbnRleHQgPSBwYXJlbnRDb250ZXh0LmdldENvbnRleHQoZnV0dXJlLm91dGxldCk7XG4gICAgICAgIGlmIChjb250ZXh0KSB7XG4gICAgICAgICAgdGhpcy5kZWFjdGl2YXRlQ2hpbGRSb3V0ZXMoZnV0dXJlTm9kZSwgY3Vyck5vZGUsIGNvbnRleHQuY2hpbGRyZW4pO1xuICAgICAgICB9XG4gICAgICB9IGVsc2Uge1xuICAgICAgICAvLyBpZiB3ZSBoYXZlIGEgY29tcG9uZW50bGVzcyByb3V0ZSwgd2UgcmVjdXJzZSBidXQga2VlcCB0aGUgc2FtZSBvdXRsZXQgbWFwLlxuICAgICAgICB0aGlzLmRlYWN0aXZhdGVDaGlsZFJvdXRlcyhmdXR1cmVOb2RlLCBjdXJyTm9kZSwgcGFyZW50Q29udGV4dCk7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChjdXJyKSB7XG4gICAgICAgIC8vIERlYWN0aXZhdGUgdGhlIGN1cnJlbnQgcm91dGUgd2hpY2ggd2lsbCBub3QgYmUgcmUtdXNlZFxuICAgICAgICB0aGlzLmRlYWN0aXZhdGVSb3V0ZUFuZEl0c0NoaWxkcmVuKGN1cnJOb2RlLCBwYXJlbnRDb250ZXh0KTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGRlYWN0aXZhdGVSb3V0ZUFuZEl0c0NoaWxkcmVuKFxuICAgICAgcm91dGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPiwgcGFyZW50Q29udGV4dHM6IENoaWxkcmVuT3V0bGV0Q29udGV4dHMpOiB2b2lkIHtcbiAgICAvLyBJZiB0aGVyZSBpcyBubyBjb21wb25lbnQsIHRoZSBSb3V0ZSBpcyBuZXZlciBhdHRhY2hlZCB0byBhbiBvdXRsZXQgKGJlY2F1c2UgdGhlcmUgaXMgbm9cbiAgICAvLyBjb21wb25lbnQgdG8gYXR0YWNoKS5cbiAgICBpZiAocm91dGUudmFsdWUuY29tcG9uZW50ICYmIHRoaXMucm91dGVSZXVzZVN0cmF0ZWd5LnNob3VsZERldGFjaChyb3V0ZS52YWx1ZS5zbmFwc2hvdCkpIHtcbiAgICAgIHRoaXMuZGV0YWNoQW5kU3RvcmVSb3V0ZVN1YnRyZWUocm91dGUsIHBhcmVudENvbnRleHRzKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5kZWFjdGl2YXRlUm91dGVBbmRPdXRsZXQocm91dGUsIHBhcmVudENvbnRleHRzKTtcbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGRldGFjaEFuZFN0b3JlUm91dGVTdWJ0cmVlKFxuICAgICAgcm91dGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPiwgcGFyZW50Q29udGV4dHM6IENoaWxkcmVuT3V0bGV0Q29udGV4dHMpOiB2b2lkIHtcbiAgICBjb25zdCBjb250ZXh0ID0gcGFyZW50Q29udGV4dHMuZ2V0Q29udGV4dChyb3V0ZS52YWx1ZS5vdXRsZXQpO1xuICAgIGNvbnN0IGNvbnRleHRzID0gY29udGV4dCAmJiByb3V0ZS52YWx1ZS5jb21wb25lbnQgPyBjb250ZXh0LmNoaWxkcmVuIDogcGFyZW50Q29udGV4dHM7XG4gICAgY29uc3QgY2hpbGRyZW46IHtbb3V0bGV0TmFtZTogc3RyaW5nXTogVHJlZU5vZGU8QWN0aXZhdGVkUm91dGU+fSA9IG5vZGVDaGlsZHJlbkFzTWFwKHJvdXRlKTtcblxuICAgIGZvciAoY29uc3QgY2hpbGRPdXRsZXQgb2YgT2JqZWN0LmtleXMoY2hpbGRyZW4pKSB7XG4gICAgICB0aGlzLmRlYWN0aXZhdGVSb3V0ZUFuZEl0c0NoaWxkcmVuKGNoaWxkcmVuW2NoaWxkT3V0bGV0XSwgY29udGV4dHMpO1xuICAgIH1cblxuICAgIGlmIChjb250ZXh0ICYmIGNvbnRleHQub3V0bGV0KSB7XG4gICAgICBjb25zdCBjb21wb25lbnRSZWYgPSBjb250ZXh0Lm91dGxldC5kZXRhY2goKTtcbiAgICAgIGNvbnN0IGNvbnRleHRzID0gY29udGV4dC5jaGlsZHJlbi5vbk91dGxldERlYWN0aXZhdGVkKCk7XG4gICAgICB0aGlzLnJvdXRlUmV1c2VTdHJhdGVneS5zdG9yZShyb3V0ZS52YWx1ZS5zbmFwc2hvdCwge2NvbXBvbmVudFJlZiwgcm91dGUsIGNvbnRleHRzfSk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBkZWFjdGl2YXRlUm91dGVBbmRPdXRsZXQoXG4gICAgICByb3V0ZTogVHJlZU5vZGU8QWN0aXZhdGVkUm91dGU+LCBwYXJlbnRDb250ZXh0czogQ2hpbGRyZW5PdXRsZXRDb250ZXh0cyk6IHZvaWQge1xuICAgIGNvbnN0IGNvbnRleHQgPSBwYXJlbnRDb250ZXh0cy5nZXRDb250ZXh0KHJvdXRlLnZhbHVlLm91dGxldCk7XG4gICAgLy8gVGhlIGNvbnRleHQgY291bGQgYmUgYG51bGxgIGlmIHdlIGFyZSBvbiBhIGNvbXBvbmVudGxlc3Mgcm91dGUgYnV0IHRoZXJlIG1heSBzdGlsbCBiZVxuICAgIC8vIGNoaWxkcmVuIHRoYXQgbmVlZCBkZWFjdGl2YXRpbmcuXG4gICAgY29uc3QgY29udGV4dHMgPSBjb250ZXh0ICYmIHJvdXRlLnZhbHVlLmNvbXBvbmVudCA/IGNvbnRleHQuY2hpbGRyZW4gOiBwYXJlbnRDb250ZXh0cztcbiAgICBjb25zdCBjaGlsZHJlbjoge1tvdXRsZXROYW1lOiBzdHJpbmddOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZT59ID0gbm9kZUNoaWxkcmVuQXNNYXAocm91dGUpO1xuXG4gICAgZm9yIChjb25zdCBjaGlsZE91dGxldCBvZiBPYmplY3Qua2V5cyhjaGlsZHJlbikpIHtcbiAgICAgIHRoaXMuZGVhY3RpdmF0ZVJvdXRlQW5kSXRzQ2hpbGRyZW4oY2hpbGRyZW5bY2hpbGRPdXRsZXRdLCBjb250ZXh0cyk7XG4gICAgfVxuXG4gICAgaWYgKGNvbnRleHQpIHtcbiAgICAgIGlmIChjb250ZXh0Lm91dGxldCkge1xuICAgICAgICAvLyBEZXN0cm95IHRoZSBjb21wb25lbnRcbiAgICAgICAgY29udGV4dC5vdXRsZXQuZGVhY3RpdmF0ZSgpO1xuICAgICAgICAvLyBEZXN0cm95IHRoZSBjb250ZXh0cyBmb3IgYWxsIHRoZSBvdXRsZXRzIHRoYXQgd2VyZSBpbiB0aGUgY29tcG9uZW50XG4gICAgICAgIGNvbnRleHQuY2hpbGRyZW4ub25PdXRsZXREZWFjdGl2YXRlZCgpO1xuICAgICAgfVxuICAgICAgLy8gQ2xlYXIgdGhlIGluZm9ybWF0aW9uIGFib3V0IHRoZSBhdHRhY2hlZCBjb21wb25lbnQgb24gdGhlIGNvbnRleHQgYnV0IGtlZXAgdGhlIHJlZmVyZW5jZSB0b1xuICAgICAgLy8gdGhlIG91dGxldC4gQ2xlYXIgZXZlbiBpZiBvdXRsZXQgd2FzIG5vdCB5ZXQgYWN0aXZhdGVkIHRvIGF2b2lkIGFjdGl2YXRpbmcgbGF0ZXIgd2l0aCBvbGRcbiAgICAgIC8vIGluZm9cbiAgICAgIGNvbnRleHQuYXR0YWNoUmVmID0gbnVsbDtcbiAgICAgIGNvbnRleHQucm91dGUgPSBudWxsO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgYWN0aXZhdGVDaGlsZFJvdXRlcyhcbiAgICAgIGZ1dHVyZU5vZGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPiwgY3Vyck5vZGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPnxudWxsLFxuICAgICAgY29udGV4dHM6IENoaWxkcmVuT3V0bGV0Q29udGV4dHMpOiB2b2lkIHtcbiAgICBjb25zdCBjaGlsZHJlbjoge1tvdXRsZXQ6IHN0cmluZ106IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlPn0gPSBub2RlQ2hpbGRyZW5Bc01hcChjdXJyTm9kZSk7XG4gICAgZnV0dXJlTm9kZS5jaGlsZHJlbi5mb3JFYWNoKGMgPT4ge1xuICAgICAgdGhpcy5hY3RpdmF0ZVJvdXRlcyhjLCBjaGlsZHJlbltjLnZhbHVlLm91dGxldF0sIGNvbnRleHRzKTtcbiAgICAgIHRoaXMuZm9yd2FyZEV2ZW50KG5ldyBBY3RpdmF0aW9uRW5kKGMudmFsdWUuc25hcHNob3QpKTtcbiAgICB9KTtcbiAgICBpZiAoZnV0dXJlTm9kZS5jaGlsZHJlbi5sZW5ndGgpIHtcbiAgICAgIHRoaXMuZm9yd2FyZEV2ZW50KG5ldyBDaGlsZEFjdGl2YXRpb25FbmQoZnV0dXJlTm9kZS52YWx1ZS5zbmFwc2hvdCkpO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgYWN0aXZhdGVSb3V0ZXMoXG4gICAgICBmdXR1cmVOb2RlOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZT4sIGN1cnJOb2RlOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZT4sXG4gICAgICBwYXJlbnRDb250ZXh0czogQ2hpbGRyZW5PdXRsZXRDb250ZXh0cyk6IHZvaWQge1xuICAgIGNvbnN0IGZ1dHVyZSA9IGZ1dHVyZU5vZGUudmFsdWU7XG4gICAgY29uc3QgY3VyciA9IGN1cnJOb2RlID8gY3Vyck5vZGUudmFsdWUgOiBudWxsO1xuXG4gICAgYWR2YW5jZUFjdGl2YXRlZFJvdXRlKGZ1dHVyZSk7XG5cbiAgICAvLyByZXVzaW5nIHRoZSBub2RlXG4gICAgaWYgKGZ1dHVyZSA9PT0gY3Vycikge1xuICAgICAgaWYgKGZ1dHVyZS5jb21wb25lbnQpIHtcbiAgICAgICAgLy8gSWYgd2UgaGF2ZSBhIG5vcm1hbCByb3V0ZSwgd2UgbmVlZCB0byBnbyB0aHJvdWdoIGFuIG91dGxldC5cbiAgICAgICAgY29uc3QgY29udGV4dCA9IHBhcmVudENvbnRleHRzLmdldE9yQ3JlYXRlQ29udGV4dChmdXR1cmUub3V0bGV0KTtcbiAgICAgICAgdGhpcy5hY3RpdmF0ZUNoaWxkUm91dGVzKGZ1dHVyZU5vZGUsIGN1cnJOb2RlLCBjb250ZXh0LmNoaWxkcmVuKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIGlmIHdlIGhhdmUgYSBjb21wb25lbnRsZXNzIHJvdXRlLCB3ZSByZWN1cnNlIGJ1dCBrZWVwIHRoZSBzYW1lIG91dGxldCBtYXAuXG4gICAgICAgIHRoaXMuYWN0aXZhdGVDaGlsZFJvdXRlcyhmdXR1cmVOb2RlLCBjdXJyTm9kZSwgcGFyZW50Q29udGV4dHMpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBpZiAoZnV0dXJlLmNvbXBvbmVudCkge1xuICAgICAgICAvLyBpZiB3ZSBoYXZlIGEgbm9ybWFsIHJvdXRlLCB3ZSBuZWVkIHRvIHBsYWNlIHRoZSBjb21wb25lbnQgaW50byB0aGUgb3V0bGV0IGFuZCByZWN1cnNlLlxuICAgICAgICBjb25zdCBjb250ZXh0ID0gcGFyZW50Q29udGV4dHMuZ2V0T3JDcmVhdGVDb250ZXh0KGZ1dHVyZS5vdXRsZXQpO1xuXG4gICAgICAgIGlmICh0aGlzLnJvdXRlUmV1c2VTdHJhdGVneS5zaG91bGRBdHRhY2goZnV0dXJlLnNuYXBzaG90KSkge1xuICAgICAgICAgIGNvbnN0IHN0b3JlZCA9XG4gICAgICAgICAgICAgICg8RGV0YWNoZWRSb3V0ZUhhbmRsZUludGVybmFsPnRoaXMucm91dGVSZXVzZVN0cmF0ZWd5LnJldHJpZXZlKGZ1dHVyZS5zbmFwc2hvdCkpO1xuICAgICAgICAgIHRoaXMucm91dGVSZXVzZVN0cmF0ZWd5LnN0b3JlKGZ1dHVyZS5zbmFwc2hvdCwgbnVsbCk7XG4gICAgICAgICAgY29udGV4dC5jaGlsZHJlbi5vbk91dGxldFJlQXR0YWNoZWQoc3RvcmVkLmNvbnRleHRzKTtcbiAgICAgICAgICBjb250ZXh0LmF0dGFjaFJlZiA9IHN0b3JlZC5jb21wb25lbnRSZWY7XG4gICAgICAgICAgY29udGV4dC5yb3V0ZSA9IHN0b3JlZC5yb3V0ZS52YWx1ZTtcbiAgICAgICAgICBpZiAoY29udGV4dC5vdXRsZXQpIHtcbiAgICAgICAgICAgIC8vIEF0dGFjaCByaWdodCBhd2F5IHdoZW4gdGhlIG91dGxldCBoYXMgYWxyZWFkeSBiZWVuIGluc3RhbnRpYXRlZFxuICAgICAgICAgICAgLy8gT3RoZXJ3aXNlIGF0dGFjaCBmcm9tIGBSb3V0ZXJPdXRsZXQubmdPbkluaXRgIHdoZW4gaXQgaXMgaW5zdGFudGlhdGVkXG4gICAgICAgICAgICBjb250ZXh0Lm91dGxldC5hdHRhY2goc3RvcmVkLmNvbXBvbmVudFJlZiwgc3RvcmVkLnJvdXRlLnZhbHVlKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBhZHZhbmNlQWN0aXZhdGVkUm91dGUoc3RvcmVkLnJvdXRlLnZhbHVlKTtcbiAgICAgICAgICB0aGlzLmFjdGl2YXRlQ2hpbGRSb3V0ZXMoZnV0dXJlTm9kZSwgbnVsbCwgY29udGV4dC5jaGlsZHJlbik7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgY29uc3QgaW5qZWN0b3IgPSBnZXRDbG9zZXN0Um91dGVJbmplY3RvcihmdXR1cmUuc25hcHNob3QpO1xuICAgICAgICAgIGNvbnRleHQuYXR0YWNoUmVmID0gbnVsbDtcbiAgICAgICAgICBjb250ZXh0LnJvdXRlID0gZnV0dXJlO1xuICAgICAgICAgIGNvbnRleHQuaW5qZWN0b3IgPSBpbmplY3RvcjtcbiAgICAgICAgICBpZiAoY29udGV4dC5vdXRsZXQpIHtcbiAgICAgICAgICAgIC8vIEFjdGl2YXRlIHRoZSBvdXRsZXQgd2hlbiBpdCBoYXMgYWxyZWFkeSBiZWVuIGluc3RhbnRpYXRlZFxuICAgICAgICAgICAgLy8gT3RoZXJ3aXNlIGl0IHdpbGwgZ2V0IGFjdGl2YXRlZCBmcm9tIGl0cyBgbmdPbkluaXRgIHdoZW4gaW5zdGFudGlhdGVkXG4gICAgICAgICAgICBjb250ZXh0Lm91dGxldC5hY3RpdmF0ZVdpdGgoZnV0dXJlLCBjb250ZXh0LmluamVjdG9yKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICB0aGlzLmFjdGl2YXRlQ2hpbGRSb3V0ZXMoZnV0dXJlTm9kZSwgbnVsbCwgY29udGV4dC5jaGlsZHJlbik7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIGlmIHdlIGhhdmUgYSBjb21wb25lbnRsZXNzIHJvdXRlLCB3ZSByZWN1cnNlIGJ1dCBrZWVwIHRoZSBzYW1lIG91dGxldCBtYXAuXG4gICAgICAgIHRoaXMuYWN0aXZhdGVDaGlsZFJvdXRlcyhmdXR1cmVOb2RlLCBudWxsLCBwYXJlbnRDb250ZXh0cyk7XG4gICAgICB9XG4gICAgfVxuICAgIGlmICgodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSkge1xuICAgICAgY29uc3QgY29udGV4dCA9IHBhcmVudENvbnRleHRzLmdldE9yQ3JlYXRlQ29udGV4dChmdXR1cmUub3V0bGV0KTtcbiAgICAgIGNvbnN0IG91dGxldCA9IGNvbnRleHQub3V0bGV0O1xuICAgICAgaWYgKG91dGxldCAmJiB0aGlzLmlucHV0QmluZGluZ0VuYWJsZWQgJiYgIW91dGxldC5zdXBwb3J0c0JpbmRpbmdUb0NvbXBvbmVudElucHV0cyAmJlxuICAgICAgICAgICF3YXJuZWRBYm91dFVuc3VwcG9ydGVkSW5wdXRCaW5kaW5nKSB7XG4gICAgICAgIGNvbnNvbGUud2FybihcbiAgICAgICAgICAgIGAnd2l0aENvbXBvbmVudElucHV0QmluZGluZycgZmVhdHVyZSBpcyBlbmFibGVkIGJ1dCBgICtcbiAgICAgICAgICAgIGB0aGlzIGFwcGxpY2F0aW9uIGlzIHVzaW5nIGFuIG91dGxldCB0aGF0IG1heSBub3Qgc3VwcG9ydCBiaW5kaW5nIHRvIGNvbXBvbmVudCBpbnB1dHMuYCk7XG4gICAgICAgIHdhcm5lZEFib3V0VW5zdXBwb3J0ZWRJbnB1dEJpbmRpbmcgPSB0cnVlO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuIl19