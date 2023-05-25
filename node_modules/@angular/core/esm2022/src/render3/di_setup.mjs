/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { resolveForwardRef } from '../di/forward_ref';
import { isClassProvider, isTypeProvider } from '../di/provider_collection';
import { providerToFactory } from '../di/r3_injector';
import { assertDefined } from '../util/assert';
import { diPublicInInjector, getNodeInjectable, getOrCreateNodeInjectorForNode } from './di';
import { ɵɵdirectiveInject } from './instructions/all';
import { NodeInjectorFactory } from './interfaces/injector';
import { isComponentDef } from './interfaces/type_checks';
import { TVIEW } from './interfaces/view';
import { getCurrentTNode, getLView, getTView } from './state';
/**
 * Resolves the providers which are defined in the DirectiveDef.
 *
 * When inserting the tokens and the factories in their respective arrays, we can assume that
 * this method is called first for the component (if any), and then for other directives on the same
 * node.
 * As a consequence,the providers are always processed in that order:
 * 1) The view providers of the component
 * 2) The providers of the component
 * 3) The providers of the other directives
 * This matches the structure of the injectables arrays of a view (for each node).
 * So the tokens and the factories can be pushed at the end of the arrays, except
 * in one case for multi providers.
 *
 * @param def the directive definition
 * @param providers: Array of `providers`.
 * @param viewProviders: Array of `viewProviders`.
 */
export function providersResolver(def, providers, viewProviders) {
    const tView = getTView();
    if (tView.firstCreatePass) {
        const isComponent = isComponentDef(def);
        // The list of view providers is processed first, and the flags are updated
        resolveProvider(viewProviders, tView.data, tView.blueprint, isComponent, true);
        // Then, the list of providers is processed, and the flags are updated
        resolveProvider(providers, tView.data, tView.blueprint, isComponent, false);
    }
}
/**
 * Resolves a provider and publishes it to the DI system.
 */
function resolveProvider(provider, tInjectables, lInjectablesBlueprint, isComponent, isViewProvider) {
    provider = resolveForwardRef(provider);
    if (Array.isArray(provider)) {
        // Recursively call `resolveProvider`
        // Recursion is OK in this case because this code will not be in hot-path once we implement
        // cloning of the initial state.
        for (let i = 0; i < provider.length; i++) {
            resolveProvider(provider[i], tInjectables, lInjectablesBlueprint, isComponent, isViewProvider);
        }
    }
    else {
        const tView = getTView();
        const lView = getLView();
        let token = isTypeProvider(provider) ? provider : resolveForwardRef(provider.provide);
        let providerFactory = providerToFactory(provider);
        const tNode = getCurrentTNode();
        const beginIndex = tNode.providerIndexes & 1048575 /* TNodeProviderIndexes.ProvidersStartIndexMask */;
        const endIndex = tNode.directiveStart;
        const cptViewProvidersCount = tNode.providerIndexes >> 20 /* TNodeProviderIndexes.CptViewProvidersCountShift */;
        if (isTypeProvider(provider) || !provider.multi) {
            // Single provider case: the factory is created and pushed immediately
            const factory = new NodeInjectorFactory(providerFactory, isViewProvider, ɵɵdirectiveInject);
            const existingFactoryIndex = indexOf(token, tInjectables, isViewProvider ? beginIndex : beginIndex + cptViewProvidersCount, endIndex);
            if (existingFactoryIndex === -1) {
                diPublicInInjector(getOrCreateNodeInjectorForNode(tNode, lView), tView, token);
                registerDestroyHooksIfSupported(tView, provider, tInjectables.length);
                tInjectables.push(token);
                tNode.directiveStart++;
                tNode.directiveEnd++;
                if (isViewProvider) {
                    tNode.providerIndexes += 1048576 /* TNodeProviderIndexes.CptViewProvidersCountShifter */;
                }
                lInjectablesBlueprint.push(factory);
                lView.push(factory);
            }
            else {
                lInjectablesBlueprint[existingFactoryIndex] = factory;
                lView[existingFactoryIndex] = factory;
            }
        }
        else {
            // Multi provider case:
            // We create a multi factory which is going to aggregate all the values.
            // Since the output of such a factory depends on content or view injection,
            // we create two of them, which are linked together.
            //
            // The first one (for view providers) is always in the first block of the injectables array,
            // and the second one (for providers) is always in the second block.
            // This is important because view providers have higher priority. When a multi token
            // is being looked up, the view providers should be found first.
            // Note that it is not possible to have a multi factory in the third block (directive block).
            //
            // The algorithm to process multi providers is as follows:
            // 1) If the multi provider comes from the `viewProviders` of the component:
            //   a) If the special view providers factory doesn't exist, it is created and pushed.
            //   b) Else, the multi provider is added to the existing multi factory.
            // 2) If the multi provider comes from the `providers` of the component or of another
            // directive:
            //   a) If the multi factory doesn't exist, it is created and provider pushed into it.
            //      It is also linked to the multi factory for view providers, if it exists.
            //   b) Else, the multi provider is added to the existing multi factory.
            const existingProvidersFactoryIndex = indexOf(token, tInjectables, beginIndex + cptViewProvidersCount, endIndex);
            const existingViewProvidersFactoryIndex = indexOf(token, tInjectables, beginIndex, beginIndex + cptViewProvidersCount);
            const doesProvidersFactoryExist = existingProvidersFactoryIndex >= 0 &&
                lInjectablesBlueprint[existingProvidersFactoryIndex];
            const doesViewProvidersFactoryExist = existingViewProvidersFactoryIndex >= 0 &&
                lInjectablesBlueprint[existingViewProvidersFactoryIndex];
            if (isViewProvider && !doesViewProvidersFactoryExist ||
                !isViewProvider && !doesProvidersFactoryExist) {
                // Cases 1.a and 2.a
                diPublicInInjector(getOrCreateNodeInjectorForNode(tNode, lView), tView, token);
                const factory = multiFactory(isViewProvider ? multiViewProvidersFactoryResolver : multiProvidersFactoryResolver, lInjectablesBlueprint.length, isViewProvider, isComponent, providerFactory);
                if (!isViewProvider && doesViewProvidersFactoryExist) {
                    lInjectablesBlueprint[existingViewProvidersFactoryIndex].providerFactory = factory;
                }
                registerDestroyHooksIfSupported(tView, provider, tInjectables.length, 0);
                tInjectables.push(token);
                tNode.directiveStart++;
                tNode.directiveEnd++;
                if (isViewProvider) {
                    tNode.providerIndexes += 1048576 /* TNodeProviderIndexes.CptViewProvidersCountShifter */;
                }
                lInjectablesBlueprint.push(factory);
                lView.push(factory);
            }
            else {
                // Cases 1.b and 2.b
                const indexInFactory = multiFactoryAdd(lInjectablesBlueprint[isViewProvider ? existingViewProvidersFactoryIndex :
                    existingProvidersFactoryIndex], providerFactory, !isViewProvider && isComponent);
                registerDestroyHooksIfSupported(tView, provider, existingProvidersFactoryIndex > -1 ? existingProvidersFactoryIndex :
                    existingViewProvidersFactoryIndex, indexInFactory);
            }
            if (!isViewProvider && isComponent && doesViewProvidersFactoryExist) {
                lInjectablesBlueprint[existingViewProvidersFactoryIndex].componentProviders++;
            }
        }
    }
}
/**
 * Registers the `ngOnDestroy` hook of a provider, if the provider supports destroy hooks.
 * @param tView `TView` in which to register the hook.
 * @param provider Provider whose hook should be registered.
 * @param contextIndex Index under which to find the context for the hook when it's being invoked.
 * @param indexInFactory Only required for `multi` providers. Index of the provider in the multi
 * provider factory.
 */
function registerDestroyHooksIfSupported(tView, provider, contextIndex, indexInFactory) {
    const providerIsTypeProvider = isTypeProvider(provider);
    const providerIsClassProvider = isClassProvider(provider);
    if (providerIsTypeProvider || providerIsClassProvider) {
        // Resolve forward references as `useClass` can hold a forward reference.
        const classToken = providerIsClassProvider ? resolveForwardRef(provider.useClass) : provider;
        const prototype = classToken.prototype;
        const ngOnDestroy = prototype.ngOnDestroy;
        if (ngOnDestroy) {
            const hooks = tView.destroyHooks || (tView.destroyHooks = []);
            if (!providerIsTypeProvider && provider.multi) {
                ngDevMode &&
                    assertDefined(indexInFactory, 'indexInFactory when registering multi factory destroy hook');
                const existingCallbacksIndex = hooks.indexOf(contextIndex);
                if (existingCallbacksIndex === -1) {
                    hooks.push(contextIndex, [indexInFactory, ngOnDestroy]);
                }
                else {
                    hooks[existingCallbacksIndex + 1].push(indexInFactory, ngOnDestroy);
                }
            }
            else {
                hooks.push(contextIndex, ngOnDestroy);
            }
        }
    }
}
/**
 * Add a factory in a multi factory.
 * @returns Index at which the factory was inserted.
 */
function multiFactoryAdd(multiFactory, factory, isComponentProvider) {
    if (isComponentProvider) {
        multiFactory.componentProviders++;
    }
    return multiFactory.multi.push(factory) - 1;
}
/**
 * Returns the index of item in the array, but only in the begin to end range.
 */
function indexOf(item, arr, begin, end) {
    for (let i = begin; i < end; i++) {
        if (arr[i] === item)
            return i;
    }
    return -1;
}
/**
 * Use this with `multi` `providers`.
 */
function multiProvidersFactoryResolver(_, tData, lData, tNode) {
    return multiResolve(this.multi, []);
}
/**
 * Use this with `multi` `viewProviders`.
 *
 * This factory knows how to concatenate itself with the existing `multi` `providers`.
 */
function multiViewProvidersFactoryResolver(_, tData, lView, tNode) {
    const factories = this.multi;
    let result;
    if (this.providerFactory) {
        const componentCount = this.providerFactory.componentProviders;
        const multiProviders = getNodeInjectable(lView, lView[TVIEW], this.providerFactory.index, tNode);
        // Copy the section of the array which contains `multi` `providers` from the component
        result = multiProviders.slice(0, componentCount);
        // Insert the `viewProvider` instances.
        multiResolve(factories, result);
        // Copy the section of the array which contains `multi` `providers` from other directives
        for (let i = componentCount; i < multiProviders.length; i++) {
            result.push(multiProviders[i]);
        }
    }
    else {
        result = [];
        // Insert the `viewProvider` instances.
        multiResolve(factories, result);
    }
    return result;
}
/**
 * Maps an array of factories into an array of values.
 */
function multiResolve(factories, result) {
    for (let i = 0; i < factories.length; i++) {
        const factory = factories[i];
        result.push(factory());
    }
    return result;
}
/**
 * Creates a multi factory.
 */
function multiFactory(factoryFn, index, isViewProvider, isComponent, f) {
    const factory = new NodeInjectorFactory(factoryFn, isViewProvider, ɵɵdirectiveInject);
    factory.multi = [];
    factory.index = index;
    factory.componentProviders = 0;
    multiFactoryAdd(factory, f, isComponent && !isViewProvider);
    return factory;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZGlfc2V0dXAuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9yZW5kZXIzL2RpX3NldHVwLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxpQkFBaUIsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBRXBELE9BQU8sRUFBQyxlQUFlLEVBQUUsY0FBYyxFQUFDLE1BQU0sMkJBQTJCLENBQUM7QUFDMUUsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDcEQsT0FBTyxFQUFDLGFBQWEsRUFBQyxNQUFNLGdCQUFnQixDQUFDO0FBRTdDLE9BQU8sRUFBQyxrQkFBa0IsRUFBRSxpQkFBaUIsRUFBRSw4QkFBOEIsRUFBQyxNQUFNLE1BQU0sQ0FBQztBQUMzRixPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSxvQkFBb0IsQ0FBQztBQUVyRCxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSx1QkFBdUIsQ0FBQztBQUUxRCxPQUFPLEVBQUMsY0FBYyxFQUFDLE1BQU0sMEJBQTBCLENBQUM7QUFDeEQsT0FBTyxFQUFnQyxLQUFLLEVBQVEsTUFBTSxtQkFBbUIsQ0FBQztBQUM5RSxPQUFPLEVBQUMsZUFBZSxFQUFFLFFBQVEsRUFBRSxRQUFRLEVBQUMsTUFBTSxTQUFTLENBQUM7QUFJNUQ7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBaUJHO0FBQ0gsTUFBTSxVQUFVLGlCQUFpQixDQUM3QixHQUFvQixFQUFFLFNBQXFCLEVBQUUsYUFBeUI7SUFDeEUsTUFBTSxLQUFLLEdBQUcsUUFBUSxFQUFFLENBQUM7SUFDekIsSUFBSSxLQUFLLENBQUMsZUFBZSxFQUFFO1FBQ3pCLE1BQU0sV0FBVyxHQUFHLGNBQWMsQ0FBQyxHQUFHLENBQUMsQ0FBQztRQUV4QywyRUFBMkU7UUFDM0UsZUFBZSxDQUFDLGFBQWEsRUFBRSxLQUFLLENBQUMsSUFB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RUFBRSxDQUFDO0lBQ25CLE9BQU8sQ0FBQyxLQUFLLEdBQUcsS0FBSyxDQUFDO0lBQ3RCLE9BQU8sQ0FBQyxrQkFBa0IsR0FBRyxDQUFDLENBQUM7SUFDL0IsZUFBZSxDQUFDLE9BQU8sRUFBRSxDQUFDLEVBQUUsV0FBVyxJQUFJLENBQUMsY0FBYyxDQUFDLENBQUM7SUFDNUQsT0FBTyxPQUFPLENBQUM7QUFDakIsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5cbmltcG9ydCB7cmVzb2x2ZUZvcndhcmRSZWZ9IGZyb20gJy4uL2RpL2ZvcndhcmRfcmVmJztcbmltcG9ydCB7Q2xhc3NQcm92aWRlciwgUHJvdmlkZXJ9IGZyb20gJy4uL2RpL2ludGVyZmFjZS9wcm92aWRlcic7XG5pbXBvcnQge2lzQ2xhc3NQcm92aWRlciwgaXNUeXBlUHJvdmlkZXJ9IGZyb20gJy4uL2RpL3Byb3ZpZGVyX2NvbGxlY3Rpb24nO1xuaW1wb3J0IHtwcm92aWRlclRvRmFjdG9yeX0gZnJvbSAnLi4vZGkvcjNfaW5qZWN0b3InO1xuaW1wb3J0IHthc3NlcnREZWZpbmVkfSBmcm9tICcuLi91dGlsL2Fzc2VydCc7XG5cbmltcG9ydCB7ZGlQdWJsaWNJbkluamVjdG9yLCBnZXROb2RlSW5qZWN0YWJsZSwgZ2V0T3JDcmVhdGVOb2RlSW5qZWN0b3JGb3JOb2RlfSBmcm9tICcuL2RpJztcbmltcG9ydCB7ybXJtWRpcmVjdGl2ZUluamVjdH0gZnJvbSAnLi9pbnN0cnVjdGlvbnMvYWxsJztcbmltcG9ydCB7RGlyZWN0aXZlRGVmfSBmcm9tICcuL2ludGVyZmFjZXMvZGVmaW5pdGlvbic7XG5pbXBvcnQge05vZGVJbmplY3RvckZhY3Rvcnl9IGZyb20gJy4vaW50ZXJmYWNlcy9pbmplY3Rvcic7XG5pbXBvcnQge1RDb250YWluZXJOb2RlLCBURGlyZWN0aXZlSG9zdE5vZGUsIFRFbGVtZW50Q29udGFpbmVyTm9kZSwgVEVsZW1lbnROb2RlLCBUTm9kZVByb3ZpZGVySW5kZXhlc30gZnJvbSAnLi9pbnRlcmZhY2VzL25vZGUnO1xuaW1wb3J0IHtpc0NvbXBvbmVudERlZn0gZnJvbSAnLi9pbnRlcmZhY2VzL3R5cGVfY2hlY2tzJztcbmltcG9ydCB7RGVzdHJveUhvb2tEYXRhLCBMVmlldywgVERhdGEsIFRWSUVXLCBUVmlld30gZnJvbSAnLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtnZXRDdXJyZW50VE5vZGUsIGdldExWaWV3LCBnZXRUVmlld30gZnJvbSAnLi9zdGF0ZSc7XG5cblxuXG4vKipcbiAqIFJlc29sdmVzIHRoZSBwcm92aWRlcnMgd2hpY2ggYXJlIGRlZmluZWQgaW4gdGhlIERpcmVjdGl2ZURlZi5cbiAqXG4gKiBXaGVuIGluc2VydGluZyB0aGUgdG9rZW5zIGFuZCB0aGUgZmFjdG9yaWVzIGluIHRoZWlyIHJlc3BlY3RpdmUgYXJyYXlzLCB3ZSBjYW4gYXNzdW1lIHRoYXRcbiAqIHRoaXMgbWV0aG9kIGlzIGNhbGxlZCBmaXJzdCBmb3IgdGhlIGNvbXBvbmVudCAoaWYgYW55KSwgYW5kIHRoZW4gZm9yIG90aGVyIGRpcmVjdGl2ZXMgb24gdGhlIHNhbWVcbiAqIG5vZGUuXG4gKiBBcyBhIGNvbnNlcXVlbmNlLHRoZSBwcm92aWRlcnMgYXJlIGFsd2F5cyBwcm9jZXNzZWQgaW4gdGhhdCBvcmRlcjpcbiAqIDEpIFRoZSB2aWV3IHByb3ZpZGVycyBvZiB0aGUgY29tcG9uZW50XG4gKiAyKSBUaGUgcHJvdmlkZXJzIG9mIHRoZSBjb21wb25lbnRcbiAqIDMpIFRoZSBwcm92aWRlcnMgb2YgdGhlIG90aGVyIGRpcmVjdGl2ZXNcbiAqIFRoaXMgbWF0Y2hlcyB0aGUgc3RydWN0dXJlIG9mIHRoZSBpbmplY3RhYmxlcyBhcnJheXMgb2YgYSB2aWV3IChmb3IgZWFjaCBub2RlKS5cbiAqIFNvIHRoZSB0b2tlbnMgYW5kIHRoZSBmYWN0b3JpZXMgY2FuIGJlIHB1c2hlZCBhdCB0aGUgZW5kIG9mIHRoZSBhcnJheXMsIGV4Y2VwdFxuICogaW4gb25lIGNhc2UgZm9yIG11bHRpIHByb3ZpZGVycy5cbiAqXG4gKiBAcGFyYW0gZGVmIHRoZSBkaXJlY3RpdmUgZGVmaW5pdGlvblxuICogQHBhcmFtIHByb3ZpZGVyczogQXJyYXkgb2YgYHByb3ZpZGVyc2AuXG4gKiBAcGFyYW0gdmlld1Byb3ZpZGVyczogQXJyYXkgb2YgYHZpZXdQcm92aWRlcnNgLlxuICovXG5leHBvcnQgZnVuY3Rpb24gcHJvdmlkZXJzUmVzb2x2ZXI8VD4oXG4gICAgZGVmOiBEaXJlY3RpdmVEZWY8VD4sIHByb3ZpZGVyczogUHJvdmlkZXJbXSwgdmlld1Byb3ZpZGVyczogUHJvdmlkZXJbXSk6IHZvaWQge1xuICBjb25zdCB0VmlldyA9IGdldFRWaWV3KCk7XG4gIGlmICh0Vmlldy5maXJzdENyZWF0ZVBhc3MpIHtcbiAgICBjb25zdCBpc0NvbXBvbmVudCA9IGlzQ29tcG9uZW50RGVmKGRlZik7XG5cbiAgICAvLyBUaGUgbGlzdCBvZiB2aWV3IHByb3ZpZGVycyBpcyBwcm9jZXNzZWQgZmlyc3QsIGFuZCB0aGUgZmxhZ3MgYXJlIHVwZGF0ZWRcbiAgICByZXNvbHZlUHJvdmlkZXIodmlld1Byb3ZpZGVycywgdFZpZXcuZGF0YSwgdFZpZXcuYmx1ZXByaW50LCBpc0NvbXBvbmVudCwgdHJ1ZSk7XG5cbiAgICAvLyBUaGVuLCB0aGUgbGlzdCBvZiBwcm92aWRlcnMgaXMgcHJvY2Vzc2VkLCBhbmQgdGhlIGZsYWdzIGFyZSB1cGRhdGVkXG4gICAgcmVzb2x2ZVByb3ZpZGVyKHByb3ZpZGVycywgdFZpZXcuZGF0YSwgdFZpZXcuYmx1ZXByaW50LCBpc0NvbXBvbmVudCwgZmFsc2UpO1xuICB9XG59XG5cbi8qKlxuICogUmVzb2x2ZXMgYSBwcm92aWRlciBhbmQgcHVibGlzaGVzIGl0IHRvIHRoZSBESSBzeXN0ZW0uXG4gKi9cbmZ1bmN0aW9uIHJlc29sdmVQcm92aWRlcihcbiAgICBwcm92aWRlcjogUHJvdmlkZXIsIHRJbmplY3RhYmxlczogVERhdGEsIGxJbmplY3RhYmxlc0JsdWVwcmludDogTm9kZUluamVjdG9yRmFjdG9yeVtdLFxuICAgIGlzQ29tcG9uZW50OiBib29sZWFuLCBpc1ZpZXdQcm92aWRlcjogYm9vbGVhbik6IHZvaWQge1xuICBwcm92aWRlciA9IHJlc29sdmVGb3J3YXJkUmVmKHByb3ZpZGVyKTtcbiAgaWYgKEFycmF5LmlzQXJyYXkocHJvdmlkZXIpKSB7XG4gICAgLy8gUmVjdXJzaXZlbHkgY2FsbCBgcmVzb2x2ZVByb3ZpZGVyYFxuICAgIC8vIFJlY3Vyc2lvbiBpcyBPSyBpbiB0aGlzIGNhc2UgYmVjYXVzZSB0aGlzIGNvZGUgd2lsbCBub3QgYmUgaW4gaG90LXBhdGggb25jZSB3ZSBpbXBsZW1lbnRcbiAgICAvLyBjbG9uaW5nIG9mIHRoZSBpbml0aWFsIHN0YXRlLlxuICAgIGZvciAobGV0IGkgPSAwOyBpIDwgcHJvdmlkZXIubGVuZ3RoOyBpKyspIHtcbiAgICAgIHJlc29sdmVQcm92aWRlcihcbiAgICAgICAgICBwcm92aWRlcltpXSwgdEluamVjdGFibGVzLCBsSW5qZWN0YWJsZXNCbHVlcHJpbnQsIGlzQ29tcG9uZW50LCBpc1ZpZXdQcm92aWRlcik7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIGNvbnN0IHRWaWV3ID0gZ2V0VFZpZXcoKTtcbiAgICBjb25zdCBsVmlldyA9IGdldExWaWV3KCk7XG4gICAgbGV0IHRva2VuOiBhbnkgPSBpc1R5cGVQcm92aWRlcihwcm92aWRlcikgPyBwcm92aWRlciA6IHJlc29sdmVGb3J3YXJkUmVmKHByb3ZpZGVyLnByb3ZpZGUpO1xuICAgIGxldCBwcm92aWRlckZhY3Rvcnk6ICgpID0+IGFueSA9IHByb3ZpZGVyVG9GYWN0b3J5KHByb3ZpZGVyKTtcblxuICAgIGNvbnN0IHROb2RlID0gZ2V0Q3VycmVudFROb2RlKCkhO1xuICAgIGNvbnN0IGJlZ2luSW5kZXggPSB0Tm9kZS5wcm92aWRlckluZGV4ZXMgJiBUTm9kZVByb3ZpZGVySW5kZXhlcy5Qcm92aWRlcnNTdGFydEluZGV4TWFzaztcbiAgICBjb25zdCBlbmRJbmRleCA9IHROb2RlLmRpcmVjdGl2ZVN0YXJ0O1xuICAgIGNvbnN0IGNwdFZpZXdQcm92aWRlcnNDb3VudCA9XG4gICAgICAgIHROb2RlLnByb3ZpZGVySW5kZXhlcyA+PiBUTm9kZVByb3ZpZGVySW5kZXhlcy5DcHRWaWV3UHJvdmlkZXJzQ291bnRTaGlmdDtcblxuICAgIGlmIChpc1R5cGVQcm92aWRlcihwcm92aWRlcikgfHwgIXByb3ZpZGVyLm11bHRpKSB7XG4gICAgICAvLyBTaW5nbGUgcHJvdmlkZXIgY2FzZTogdGhlIGZhY3RvcnkgaXMgY3JlYXRlZCBhbmQgcHVzaGVkIGltbWVkaWF0ZWx5XG4gICAgICBjb25zdCBmYWN0b3J5ID0gbmV3IE5vZGVJbmplY3RvckZhY3RvcnkocHJvdmlkZXJGYWN0b3J5LCBpc1ZpZXdQcm92aWRlciwgybXJtWRpcmVjdGl2ZUluamVjdCk7XG4gICAgICBjb25zdCBleGlzdGluZ0ZhY3RvcnlJbmRleCA9IGluZGV4T2YoXG4gICAgICAgICAgdG9rZW4sIHRJbmplY3RhYmxlcywgaXNWaWV3UHJvdmlkZXIgPyBiZWdpbkluZGV4IDogYmVnaW5JbmRleCArIGNwdFZpZXdQcm92aWRlcnNDb3VudCxcbiAgICAgICAgICBlbmRJbmRleCk7XG4gICAgICBpZiAoZXhpc3RpbmdGYWN0b3J5SW5kZXggPT09IC0xKSB7XG4gICAgICAgIGRpUHVibGljSW5JbmplY3RvcihcbiAgICAgICAgICAgIGdldE9yQ3JlYXRlTm9kZUluamVjdG9yRm9yTm9kZShcbiAgICAgICAgICAgICAgICB0Tm9kZSBhcyBURWxlbWVudE5vZGUgfCBUQ29udGFpbmVyTm9kZSB8IFRFbGVtZW50Q29udGFpbmVyTm9kZSwgbFZpZXcpLFxuICAgICAgICAgICAgdFZpZXcsIHRva2VuKTtcbiAgICAgICAgcmVnaXN0ZXJEZXN0cm95SG9va3NJZlN1cHBvcnRlZCh0VmlldywgcHJvdmlkZXIsIHRJbmplY3RhYmxlcy5sZW5ndGgpO1xuICAgICAgICB0SW5qZWN0YWJsZXMucHVzaCh0b2tlbik7XG4gICAgICAgIHROb2RlLmRpcmVjdGl2ZVN0YXJ0Kys7XG4gICAgICAgIHROb2RlLmRpcmVjdGl2ZUVuZCsrO1xuICAgICAgICBpZiAoaXNWaWV3UHJvdmlkZXIpIHtcbiAgICAgICAgICB0Tm9kZS5wcm92aWRlckluZGV4ZXMgKz0gVE5vZGVQcm92aWRlckluZGV4ZXMuQ3B0Vmlld1Byb3ZpZGVyc0NvdW50U2hpZnRlcjtcbiAgICAgICAgfVxuICAgICAgICBsSW5qZWN0YWJsZXNCbHVlcHJpbnQucHVzaChmYWN0b3J5KTtcbiAgICAgICAgbFZpZXcucHVzaChmYWN0b3J5KTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGxJbmplY3RhYmxlc0JsdWVwcmludFtleGlzdGluZ0ZhY3RvcnlJbmRleF0gPSBmYWN0b3J5O1xuICAgICAgICBsVmlld1tleGlzdGluZ0ZhY3RvcnlJbmRleF0gPSBmYWN0b3J5O1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAvLyBNdWx0aSBwcm92aWRlciBjYXNlOlxuICAgICAgLy8gV2UgY3JlYXRlIGEgbXVsdGkgZmFjdG9yeSB3aGljaCBpcyBnb2luZyB0byBhZ2dyZWdhdGUgYWxsIHRoZSB2YWx1ZXMuXG4gICAgICAvLyBTaW5jZSB0aGUgb3V0cHV0IG9mIHN1Y2ggYSBmYWN0b3J5IGRlcGVuZHMgb24gY29udGVudCBvciB2aWV3IGluamVjdGlvbixcbiAgICAgIC8vIHdlIGNyZWF0ZSB0d28gb2YgdGhlbSwgd2hpY2ggYXJlIGxpbmtlZCB0b2dldGhlci5cbiAgICAgIC8vXG4gICAgICAvLyBUaGUgZmlyc3Qgb25lIChmb3IgdmlldyBwcm92aWRlcnMpIGlzIGFsd2F5cyBpbiB0aGUgZmlyc3QgYmxvY2sgb2YgdGhlIGluamVjdGFibGVzIGFycmF5LFxuICAgICAgLy8gYW5kIHRoZSBzZWNvbmQgb25lIChmb3IgcHJvdmlkZXJzKSBpcyBhbHdheXMgaW4gdGhlIHNlY29uZCBibG9jay5cbiAgICAgIC8vIFRoaXMgaXMgaW1wb3J0YW50IGJlY2F1c2UgdmlldyBwcm92aWRlcnMgaGF2ZSBoaWdoZXIgcHJpb3JpdHkuIFdoZW4gYSBtdWx0aSB0b2tlblxuICAgICAgLy8gaXMgYmVpbmcgbG9va2VkIHVwLCB0aGUgdmlldyBwcm92aWRlcnMgc2hvdWxkIGJlIGZvdW5kIGZpcnN0LlxuICAgICAgLy8gTm90ZSB0aGF0IGl0IGlzIG5vdCBwb3NzaWJsZSB0byBoYXZlIGEgbXVsdGkgZmFjdG9yeSBpbiB0aGUgdGhpcmQgYmxvY2sgKGRpcmVjdGl2ZSBibG9jaykuXG4gICAgICAvL1xuICAgICAgLy8gVGhlIGFsZ29yaXRobSB0byBwcm9jZXNzIG11bHRpIHByb3ZpZGVycyBpcyBhcyBmb2xsb3dzOlxuICAgICAgLy8gMSkgSWYgdGhlIG11bHRpIHByb3ZpZGVyIGNvbWVzIGZyb20gdGhlIGB2aWV3UHJvdmlkZXJzYCBvZiB0aGUgY29tcG9uZW50OlxuICAgICAgLy8gICBhKSBJZiB0aGUgc3BlY2lhbCB2aWV3IHByb3ZpZGVycyBmYWN0b3J5IGRvZXNuJ3QgZXhpc3QsIGl0IGlzIGNyZWF0ZWQgYW5kIHB1c2hlZC5cbiAgICAgIC8vICAgYikgRWxzZSwgdGhlIG11bHRpIHByb3ZpZGVyIGlzIGFkZGVkIHRvIHRoZSBleGlzdGluZyBtdWx0aSBmYWN0b3J5LlxuICAgICAgLy8gMikgSWYgdGhlIG11bHRpIHByb3ZpZGVyIGNvbWVzIGZyb20gdGhlIGBwcm92aWRlcnNgIG9mIHRoZSBjb21wb25lbnQgb3Igb2YgYW5vdGhlclxuICAgICAgLy8gZGlyZWN0aXZlOlxuICAgICAgLy8gICBhKSBJZiB0aGUgbXVsdGkgZmFjdG9yeSBkb2Vzbid0IGV4aXN0LCBpdCBpcyBjcmVhdGVkIGFuZCBwcm92aWRlciBwdXNoZWQgaW50byBpdC5cbiAgICAgIC8vICAgICAgSXQgaXMgYWxzbyBsaW5rZWQgdG8gdGhlIG11bHRpIGZhY3RvcnkgZm9yIHZpZXcgcHJvdmlkZXJzLCBpZiBpdCBleGlzdHMuXG4gICAgICAvLyAgIGIpIEVsc2UsIHRoZSBtdWx0aSBwcm92aWRlciBpcyBhZGRlZCB0byB0aGUgZXhpc3RpbmcgbXVsdGkgZmFjdG9yeS5cblxuICAgICAgY29uc3QgZXhpc3RpbmdQcm92aWRlcnNGYWN0b3J5SW5kZXggPVxuICAgICAgICAgIGluZGV4T2YodG9rZW4sIHRJbmplY3RhYmxlcywgYmVnaW5JbmRleCArIGNwdFZpZXdQcm92aWRlcnNDb3VudCwgZW5kSW5kZXgpO1xuICAgICAgY29uc3QgZXhpc3RpbmdWaWV3UHJvdmlkZXJzRmFjdG9yeUluZGV4ID1cbiAgICAgICAgICBpbmRleE9mKHRva2VuLCB0SW5qZWN0YWJsZXMsIGJlZ2luSW5kZXgsIGJlZ2luSW5kZXggKyBjcHRWaWV3UHJvdmlkZXJzQ291bnQpO1xuICAgICAgY29uc3QgZG9lc1Byb3ZpZGVyc0ZhY3RvcnlFeGlzdCA9IGV4aXN0aW5nUHJvdmlkZXJzRmFjdG9yeUluZGV4ID49IDAgJiZcbiAgICAgICAgICBsSW5qZWN0YWJsZXNCbHVlcHJpbnRbZXhpc3RpbmdQcm92aWRlcnNGYWN0b3J5SW5kZXhdO1xuICAgICAgY29uc3QgZG9lc1ZpZXdQcm92aWRlcnNGYWN0b3J5RXhpc3QgPSBleGlzdGluZ1ZpZXdQcm92aWRlcnNGYWN0b3J5SW5kZXggPj0gMCAmJlxuICAgICAgICAgIGxJbmplY3RhYmxlc0JsdWVwcmludFtleGlzdGluZ1ZpZXdQcm92aWRlcnNGYWN0b3J5SW5kZXhdO1xuXG4gICAgICBpZiAoaXNWaWV3UHJvdmlkZXIgJiYgIWRvZXNWaWV3UHJvdmlkZXJzRmFjdG9yeUV4aXN0IHx8XG4gICAgICAgICAgIWlzVmlld1Byb3ZpZGVyICYmICFkb2VzUHJvdmlkZXJzRmFjdG9yeUV4aXN0KSB7XG4gICAgICAgIC8vIENhc2VzIDEuYSBhbmQgMi5hXG4gICAgICAgIGRpUHVibGljSW5JbmplY3RvcihcbiAgICAgICAgICAgIGdldE9yQ3JlYXRlTm9kZUluamVjdG9yRm9yTm9kZShcbiAgICAgICAgICAgICAgICB0Tm9kZSBhcyBURWxlbWVudE5vZGUgfCBUQ29udGFpbmVyTm9kZSB8IFRFbGVtZW50Q29udGFpbmVyTm9kZSwgbFZpZXcpLFxuICAgICAgICAgICAgdFZpZXcsIHRva2VuKTtcbiAgICAgICAgY29uc3QgZmFjdG9yeSA9IG11bHRpRmFjdG9yeShcbiAgICAgICAgICAgIGlzVmlld1Byb3ZpZGVyID8gbXVsdGlWaWV3UHJvdmlkZXJzRmFjdG9yeVJlc29sdmVyIDogbXVsdGlQcm92aWRlcnNGYWN0b3J5UmVzb2x2ZXIsXG4gICAgICAgICAgICBsSW5qZWN0YWJsZXNCbHVlcHJpbnQubGVuZ3RoLCBpc1ZpZXdQcm92aWRlciwgaXNDb21wb25lbnQsIHByb3ZpZGVyRmFjdG9yeSk7XG4gICAgICAgIGlmICghaXNWaWV3UHJvdmlkZXIgJiYgZG9lc1ZpZXdQcm92aWRlcnNGYWN0b3J5RXhpc3QpIHtcbiAgICAgICAgICBsSW5qZWN0YWJsZXNCbHVlcHJpbnRbZXhpc3RpbmdWaWV3UHJvdmlkZXJzRmFjdG9yeUluZGV4XS5wcm92aWRlckZhY3RvcnkgPSBmYWN0b3J5O1xuICAgICAgICB9XG4gICAgICAgIHJlZ2lzdGVyRGVzdHJveUhvb2tzSWZTdXBwb3J0ZWQodFZpZXcsIHByb3ZpZGVyLCB0SW5qZWN0YWJsZXMubGVuZ3RoLCAwKTtcbiAgICAgICAgdEluamVjdGFibGVzLnB1c2godG9rZW4pO1xuICAgICAgICB0Tm9kZS5kaXJlY3RpdmVTdGFydCsrO1xuICAgICAgICB0Tm9kZS5kaXJlY3RpdmVFbmQrKztcbiAgICAgICAgaWYgKGlzVmlld1Byb3ZpZGVyKSB7XG4gICAgICAgICAgdE5vZGUucHJvdmlkZXJJbmRleGVzICs9IFROb2RlUHJvdmlkZXJJbmRleGVzLkNwdFZpZXdQcm92aWRlcnNDb3VudFNoaWZ0ZXI7XG4gICAgICAgIH1cbiAgICAgICAgbEluamVjdGFibGVzQmx1ZXByaW50LnB1c2goZmFjdG9yeSk7XG4gICAgICAgIGxWaWV3LnB1c2goZmFjdG9yeSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICAvLyBDYXNlcyAxLmIgYW5kIDIuYlxuICAgICAgICBjb25zdCBpbmRleEluRmFjdG9yeSA9IG11bHRpRmFjdG9yeUFkZChcbiAgICAgICAgICAgIGxJbmplY3RhYmxlc0JsdWVwcmludCFcbiAgICAgICAgICAgICAgICBbaXNWaWV3UHJvdmlkZXIgPyBleGlzdGluZ1ZpZXdQcm92aWRlcnNGYWN0b3J5SW5kZXggOlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGV4aXN0aW5nUHJvdmlkZXJzRmFjdG9yeUluZGV4XSxcbiAgICAgICAgICAgIHByb3ZpZGVyRmFjdG9yeSwgIWlzVmlld1Byb3ZpZGVyICYmIGlzQ29tcG9uZW50KTtcbiAgICAgICAgcmVnaXN0ZXJEZXN0cm95SG9va3NJZlN1cHBvcnRlZChcbiAgICAgICAgICAgIHRWaWV3LCBwcm92aWRlcixcbiAgICAgICAgICAgIGV4aXN0aW5nUHJvdmlkZXJzRmFjdG9yeUluZGV4ID4gLTEgPyBleGlzdGluZ1Byb3ZpZGVyc0ZhY3RvcnlJbmRleCA6XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZXhpc3RpbmdWaWV3UHJvdmlkZXJzRmFjdG9yeUluZGV4LFxuICAgICAgICAgICAgaW5kZXhJbkZhY3RvcnkpO1xuICAgICAgfVxuICAgICAgaWYgKCFpc1ZpZXdQcm92aWRlciAmJiBpc0NvbXBvbmVudCAmJiBkb2VzVmlld1Byb3ZpZGVyc0ZhY3RvcnlFeGlzdCkge1xuICAgICAgICBsSW5qZWN0YWJsZXNCbHVlcHJpbnRbZXhpc3RpbmdWaWV3UHJvdmlkZXJzRmFjdG9yeUluZGV4XS5jb21wb25lbnRQcm92aWRlcnMhKys7XG4gICAgICB9XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogUmVnaXN0ZXJzIHRoZSBgbmdPbkRlc3Ryb3lgIGhvb2sgb2YgYSBwcm92aWRlciwgaWYgdGhlIHByb3ZpZGVyIHN1cHBvcnRzIGRlc3Ryb3kgaG9va3MuXG4gKiBAcGFyYW0gdFZpZXcgYFRWaWV3YCBpbiB3aGljaCB0byByZWdpc3RlciB0aGUgaG9vay5cbiAqIEBwYXJhbSBwcm92aWRlciBQcm92aWRlciB3aG9zZSBob29rIHNob3VsZCBiZSByZWdpc3RlcmVkLlxuICogQHBhcmFtIGNvbnRleHRJbmRleCBJbmRleCB1bmRlciB3aGljaCB0byBmaW5kIHRoZSBjb250ZXh0IGZvciB0aGUgaG9vayB3aGVuIGl0J3MgYmVpbmcgaW52b2tlZC5cbiAqIEBwYXJhbSBpbmRleEluRmFjdG9yeSBPbmx5IHJlcXVpcmVkIGZvciBgbXVsdGlgIHByb3ZpZGVycy4gSW5kZXggb2YgdGhlIHByb3ZpZGVyIGluIHRoZSBtdWx0aVxuICogcHJvdmlkZXIgZmFjdG9yeS5cbiAqL1xuZnVuY3Rpb24gcmVnaXN0ZXJEZXN0cm95SG9va3NJZlN1cHBvcnRlZChcbiAgICB0VmlldzogVFZpZXcsIHByb3ZpZGVyOiBFeGNsdWRlPFByb3ZpZGVyLCBhbnlbXT4sIGNvbnRleHRJbmRleDogbnVtYmVyLFxuICAgIGluZGV4SW5GYWN0b3J5PzogbnVtYmVyKSB7XG4gIGNvbnN0IHByb3ZpZGVySXNUeXBlUHJvdmlkZXIgPSBpc1R5cGVQcm92aWRlcihwcm92aWRlcik7XG4gIGNvbnN0IHByb3ZpZGVySXNDbGFzc1Byb3ZpZGVyID0gaXNDbGFzc1Byb3ZpZGVyKHByb3ZpZGVyKTtcblxuICBpZiAocHJvdmlkZXJJc1R5cGVQcm92aWRlciB8fCBwcm92aWRlcklzQ2xhc3NQcm92aWRlcikge1xuICAgIC8vIFJlc29sdmUgZm9yd2FyZCByZWZlcmVuY2VzIGFzIGB1c2VDbGFzc2AgY2FuIGhvbGQgYSBmb3J3YXJkIHJlZmVyZW5jZS5cbiAgICBjb25zdCBjbGFzc1Rva2VuID0gcHJvdmlkZXJJc0NsYXNzUHJvdmlkZXIgPyByZXNvbHZlRm9yd2FyZFJlZihwcm92aWRlci51c2VDbGFzcykgOiBwcm92aWRlcjtcbiAgICBjb25zdCBwcm90b3R5cGUgPSBjbGFzc1Rva2VuLnByb3RvdHlwZTtcbiAgICBjb25zdCBuZ09uRGVzdHJveSA9IHByb3RvdHlwZS5uZ09uRGVzdHJveTtcblxuICAgIGlmIChuZ09uRGVzdHJveSkge1xuICAgICAgY29uc3QgaG9va3MgPSB0Vmlldy5kZXN0cm95SG9va3MgfHwgKHRWaWV3LmRlc3Ryb3lIb29rcyA9IFtdKTtcblxuICAgICAgaWYgKCFwcm92aWRlcklzVHlwZVByb3ZpZGVyICYmICgocHJvdmlkZXIgYXMgQ2xhc3NQcm92aWRlcikpLm11bHRpKSB7XG4gICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgYXNzZXJ0RGVmaW5lZChcbiAgICAgICAgICAgICAgICBpbmRleEluRmFjdG9yeSwgJ2luZGV4SW5GYWN0b3J5IHdoZW4gcmVnaXN0ZXJpbmcgbXVsdGkgZmFjdG9yeSBkZXN0cm95IGhvb2snKTtcbiAgICAgICAgY29uc3QgZXhpc3RpbmdDYWxsYmFja3NJbmRleCA9IGhvb2tzLmluZGV4T2YoY29udGV4dEluZGV4KTtcblxuICAgICAgICBpZiAoZXhpc3RpbmdDYWxsYmFja3NJbmRleCA9PT0gLTEpIHtcbiAgICAgICAgICBob29rcy5wdXNoKGNvbnRleHRJbmRleCwgW2luZGV4SW5GYWN0b3J5LCBuZ09uRGVzdHJveV0pO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIChob29rc1tleGlzdGluZ0NhbGxiYWNrc0luZGV4ICsgMV0gYXMgRGVzdHJveUhvb2tEYXRhKS5wdXNoKGluZGV4SW5GYWN0b3J5ISwgbmdPbkRlc3Ryb3kpO1xuICAgICAgICB9XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBob29rcy5wdXNoKGNvbnRleHRJbmRleCwgbmdPbkRlc3Ryb3kpO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEFkZCBhIGZhY3RvcnkgaW4gYSBtdWx0aSBmYWN0b3J5LlxuICogQHJldHVybnMgSW5kZXggYXQgd2hpY2ggdGhlIGZhY3Rvcnkgd2FzIGluc2VydGVkLlxuICovXG5mdW5jdGlvbiBtdWx0aUZhY3RvcnlBZGQoXG4gICAgbXVsdGlGYWN0b3J5OiBOb2RlSW5qZWN0b3JGYWN0b3J5LCBmYWN0b3J5OiAoKSA9PiBhbnksIGlzQ29tcG9uZW50UHJvdmlkZXI6IGJvb2xlYW4pOiBudW1iZXIge1xuICBpZiAoaXNDb21wb25lbnRQcm92aWRlcikge1xuICAgIG11bHRpRmFjdG9yeS5jb21wb25lbnRQcm92aWRlcnMhKys7XG4gIH1cbiAgcmV0dXJuIG11bHRpRmFjdG9yeS5tdWx0aSEucHVzaChmYWN0b3J5KSAtIDE7XG59XG5cbi8qKlxuICogUmV0dXJucyB0aGUgaW5kZXggb2YgaXRlbSBpbiB0aGUgYXJyYXksIGJ1dCBvbmx5IGluIHRoZSBiZWdpbiB0byBlbmQgcmFuZ2UuXG4gKi9cbmZ1bmN0aW9uIGluZGV4T2YoaXRlbTogYW55LCBhcnI6IGFueVtdLCBiZWdpbjogbnVtYmVyLCBlbmQ6IG51bWJlcikge1xuICBmb3IgKGxldCBpID0gYmVnaW47IGkgPCBlbmQ7IGkrKykge1xuICAgIGlmIChhcnJbaV0gPT09IGl0ZW0pIHJldHVybiBpO1xuICB9XG4gIHJldHVybiAtMTtcbn1cblxuLyoqXG4gKiBVc2UgdGhpcyB3aXRoIGBtdWx0aWAgYHByb3ZpZGVyc2AuXG4gKi9cbmZ1bmN0aW9uIG11bHRpUHJvdmlkZXJzRmFjdG9yeVJlc29sdmVyKFxuICAgIHRoaXM6IE5vZGVJbmplY3RvckZhY3RvcnksIF86IHVuZGVmaW5lZCwgdERhdGE6IFREYXRhLCBsRGF0YTogTFZpZXcsXG4gICAgdE5vZGU6IFREaXJlY3RpdmVIb3N0Tm9kZSk6IGFueVtdIHtcbiAgcmV0dXJuIG11bHRpUmVzb2x2ZSh0aGlzLm11bHRpISwgW10pO1xufVxuXG4vKipcbiAqIFVzZSB0aGlzIHdpdGggYG11bHRpYCBgdmlld1Byb3ZpZGVyc2AuXG4gKlxuICogVGhpcyBmYWN0b3J5IGtub3dzIGhvdyB0byBjb25jYXRlbmF0ZSBpdHNlbGYgd2l0aCB0aGUgZXhpc3RpbmcgYG11bHRpYCBgcHJvdmlkZXJzYC5cbiAqL1xuZnVuY3Rpb24gbXVsdGlWaWV3UHJvdmlkZXJzRmFjdG9yeVJlc29sdmVyKFxuICAgIHRoaXM6IE5vZGVJbmplY3RvckZhY3RvcnksIF86IHVuZGVmaW5lZCwgdERhdGE6IFREYXRhLCBsVmlldzogTFZpZXcsXG4gICAgdE5vZGU6IFREaXJlY3RpdmVIb3N0Tm9kZSk6IGFueVtdIHtcbiAgY29uc3QgZmFjdG9yaWVzID0gdGhpcy5tdWx0aSE7XG4gIGxldCByZXN1bHQ6IGFueVtdO1xuICBpZiAodGhpcy5wcm92aWRlckZhY3RvcnkpIHtcbiAgICBjb25zdCBjb21wb25lbnRDb3VudCA9IHRoaXMucHJvdmlkZXJGYWN0b3J5LmNvbXBvbmVudFByb3ZpZGVycyE7XG4gICAgY29uc3QgbXVsdGlQcm92aWRlcnMgPVxuICAgICAgICBnZXROb2RlSW5qZWN0YWJsZShsVmlldywgbFZpZXdbVFZJRVddLCB0aGlzLnByb3ZpZGVyRmFjdG9yeSEuaW5kZXghLCB0Tm9kZSk7XG4gICAgLy8gQ29weSB0aGUgc2VjdGlvbiBvZiB0aGUgYXJyYXkgd2hpY2ggY29udGFpbnMgYG11bHRpYCBgcHJvdmlkZXJzYCBmcm9tIHRoZSBjb21wb25lbnRcbiAgICByZXN1bHQgPSBtdWx0aVByb3ZpZGVycy5zbGljZSgwLCBjb21wb25lbnRDb3VudCk7XG4gICAgLy8gSW5zZXJ0IHRoZSBgdmlld1Byb3ZpZGVyYCBpbnN0YW5jZXMuXG4gICAgbXVsdGlSZXNvbHZlKGZhY3RvcmllcywgcmVzdWx0KTtcbiAgICAvLyBDb3B5IHRoZSBzZWN0aW9uIG9mIHRoZSBhcnJheSB3aGljaCBjb250YWlucyBgbXVsdGlgIGBwcm92aWRlcnNgIGZyb20gb3RoZXIgZGlyZWN0aXZlc1xuICAgIGZvciAobGV0IGkgPSBjb21wb25lbnRDb3VudDsgaSA8IG11bHRpUHJvdmlkZXJzLmxlbmd0aDsgaSsrKSB7XG4gICAgICByZXN1bHQucHVzaChtdWx0aVByb3ZpZGVyc1tpXSk7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIHJlc3VsdCA9IFtdO1xuICAgIC8vIEluc2VydCB0aGUgYHZpZXdQcm92aWRlcmAgaW5zdGFuY2VzLlxuICAgIG11bHRpUmVzb2x2ZShmYWN0b3JpZXMsIHJlc3VsdCk7XG4gIH1cbiAgcmV0dXJuIHJlc3VsdDtcbn1cblxuLyoqXG4gKiBNYXBzIGFuIGFycmF5IG9mIGZhY3RvcmllcyBpbnRvIGFuIGFycmF5IG9mIHZhbHVlcy5cbiAqL1xuZnVuY3Rpb24gbXVsdGlSZXNvbHZlKGZhY3RvcmllczogQXJyYXk8KCkgPT4gYW55PiwgcmVzdWx0OiBhbnlbXSk6IGFueVtdIHtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBmYWN0b3JpZXMubGVuZ3RoOyBpKyspIHtcbiAgICBjb25zdCBmYWN0b3J5ID0gZmFjdG9yaWVzW2ldISBhcyAoKSA9PiBudWxsO1xuICAgIHJlc3VsdC5wdXNoKGZhY3RvcnkoKSk7XG4gIH1cbiAgcmV0dXJuIHJlc3VsdDtcbn1cblxuLyoqXG4gKiBDcmVhdGVzIGEgbXVsdGkgZmFjdG9yeS5cbiAqL1xuZnVuY3Rpb24gbXVsdGlGYWN0b3J5KFxuICAgIGZhY3RvcnlGbjogKFxuICAgICAgICB0aGlzOiBOb2RlSW5qZWN0b3JGYWN0b3J5LCBfOiB1bmRlZmluZWQsIHREYXRhOiBURGF0YSwgbERhdGE6IExWaWV3LFxuICAgICAgICB0Tm9kZTogVERpcmVjdGl2ZUhvc3ROb2RlKSA9PiBhbnksXG4gICAgaW5kZXg6IG51bWJlciwgaXNWaWV3UHJvdmlkZXI6IGJvb2xlYW4sIGlzQ29tcG9uZW50OiBib29sZWFuLFxuICAgIGY6ICgpID0+IGFueSk6IE5vZGVJbmplY3RvckZhY3Rvcnkge1xuICBjb25zdCBmYWN0b3J5ID0gbmV3IE5vZGVJbmplY3RvckZhY3RvcnkoZmFjdG9yeUZuLCBpc1ZpZXdQcm92aWRlciwgybXJtWRpcmVjdGl2ZUluamVjdCk7XG4gIGZhY3RvcnkubXVsdGkgPSBbXTtcbiAgZmFjdG9yeS5pbmRleCA9IGluZGV4O1xuICBmYWN0b3J5LmNvbXBvbmVudFByb3ZpZGVycyA9IDA7XG4gIG11bHRpRmFjdG9yeUFkZChmYWN0b3J5LCBmLCBpc0NvbXBvbmVudCAmJiAhaXNWaWV3UHJvdmlkZXIpO1xuICByZXR1cm4gZmFjdG9yeTtcbn1cbiJdfQ==