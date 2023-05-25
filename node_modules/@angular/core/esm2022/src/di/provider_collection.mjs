/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { RuntimeError } from '../errors';
import { getComponentDef } from '../render3/definition';
import { getFactoryDef } from '../render3/definition_factory';
import { throwCyclicDependencyError, throwInvalidProviderError } from '../render3/errors_di';
import { stringifyForError } from '../render3/util/stringify_utils';
import { deepForEach } from '../util/array_utils';
import { EMPTY_ARRAY } from '../util/empty';
import { getClosureSafeProperty } from '../util/property';
import { stringify } from '../util/stringify';
import { resolveForwardRef } from './forward_ref';
import { ENVIRONMENT_INITIALIZER } from './initializer_token';
import { ɵɵinject as inject } from './injector_compatibility';
import { getInjectorDef } from './interface/defs';
import { isEnvironmentProviders } from './interface/provider';
import { INJECTOR_DEF_TYPES } from './internal_tokens';
/**
 * Wrap an array of `Provider`s into `EnvironmentProviders`, preventing them from being accidentally
 * referenced in `@Component in a component injector.
 */
export function makeEnvironmentProviders(providers) {
    return {
        ɵproviders: providers,
    };
}
/**
 * Collects providers from all NgModules and standalone components, including transitively imported
 * ones.
 *
 * Providers extracted via `importProvidersFrom` are only usable in an application injector or
 * another environment injector (such as a route injector). They should not be used in component
 * providers.
 *
 * More information about standalone components can be found in [this
 * guide](guide/standalone-components).
 *
 * @usageNotes
 * The results of the `importProvidersFrom` call can be used in the `bootstrapApplication` call:
 *
 * ```typescript
 * await bootstrapApplication(RootComponent, {
 *   providers: [
 *     importProvidersFrom(NgModuleOne, NgModuleTwo)
 *   ]
 * });
 * ```
 *
 * You can also use the `importProvidersFrom` results in the `providers` field of a route, when a
 * standalone component is used:
 *
 * ```typescript
 * export const ROUTES: Route[] = [
 *   {
 *     path: 'foo',
 *     providers: [
 *       importProvidersFrom(NgModuleOne, NgModuleTwo)
 *     ],
 *     component: YourStandaloneComponent
 *   }
 * ];
 * ```
 *
 * @returns Collected providers from the specified list of types.
 * @publicApi
 */
export function importProvidersFrom(...sources) {
    return {
        ɵproviders: internalImportProvidersFrom(true, sources),
        ɵfromNgModule: true,
    };
}
export function internalImportProvidersFrom(checkForStandaloneCmp, ...sources) {
    const providersOut = [];
    const dedup = new Set(); // already seen types
    let injectorTypesWithProviders;
    deepForEach(sources, source => {
        if ((typeof ngDevMode === 'undefined' || ngDevMode) && checkForStandaloneCmp) {
            const cmpDef = getComponentDef(source);
            if (cmpDef?.standalone) {
                throw new RuntimeError(800 /* RuntimeErrorCode.IMPORT_PROVIDERS_FROM_STANDALONE */, `Importing providers supports NgModule or ModuleWithProviders but got a standalone component "${stringifyForError(source)}"`);
            }
        }
        // Narrow `source` to access the internal type analogue for `ModuleWithProviders`.
        const internalSource = source;
        if (walkProviderTree(internalSource, providersOut, [], dedup)) {
            injectorTypesWithProviders ||= [];
            injectorTypesWithProviders.push(internalSource);
        }
    });
    // Collect all providers from `ModuleWithProviders` types.
    if (injectorTypesWithProviders !== undefined) {
        processInjectorTypesWithProviders(injectorTypesWithProviders, providersOut);
    }
    return providersOut;
}
/**
 * Collects all providers from the list of `ModuleWithProviders` and appends them to the provided
 * array.
 */
function processInjectorTypesWithProviders(typesWithProviders, providersOut) {
    for (let i = 0; i < typesWithProviders.length; i++) {
        const { ngModule, providers } = typesWithProviders[i];
        deepForEachProvider(providers, provider => {
            ngDevMode && validateProvider(provider, providers || EMPTY_ARRAY, ngModule);
            providersOut.push(provider);
        });
    }
}
/**
 * The logic visits an `InjectorType`, an `InjectorTypeWithProviders`, or a standalone
 * `ComponentType`, and all of its transitive providers and collects providers.
 *
 * If an `InjectorTypeWithProviders` that declares providers besides the type is specified,
 * the function will return "true" to indicate that the providers of the type definition need
 * to be processed. This allows us to process providers of injector types after all imports of
 * an injector definition are processed. (following View Engine semantics: see FW-1349)
 */
export function walkProviderTree(container, providersOut, parents, dedup) {
    container = resolveForwardRef(container);
    if (!container)
        return false;
    // The actual type which had the definition. Usually `container`, but may be an unwrapped type
    // from `InjectorTypeWithProviders`.
    let defType = null;
    let injDef = getInjectorDef(container);
    const cmpDef = !injDef && getComponentDef(container);
    if (!injDef && !cmpDef) {
        // `container` is not an injector type or a component type. It might be:
        //  * An `InjectorTypeWithProviders` that wraps an injector type.
        //  * A standalone directive or pipe that got pulled in from a standalone component's
        //    dependencies.
        // Try to unwrap it as an `InjectorTypeWithProviders` first.
        const ngModule = container.ngModule;
        injDef = getInjectorDef(ngModule);
        if (injDef) {
            defType = ngModule;
        }
        else {
            // Not a component or injector type, so ignore it.
            return false;
        }
    }
    else if (cmpDef && !cmpDef.standalone) {
        return false;
    }
    else {
        defType = container;
    }
    // Check for circular dependencies.
    if (ngDevMode && parents.indexOf(defType) !== -1) {
        const defName = stringify(defType);
        const path = parents.map(stringify);
        throwCyclicDependencyError(defName, path);
    }
    // Check for multiple imports of the same module
    const isDuplicate = dedup.has(defType);
    if (cmpDef) {
        if (isDuplicate) {
            // This component definition has already been processed.
            return false;
        }
        dedup.add(defType);
        if (cmpDef.dependencies) {
            const deps = typeof cmpDef.dependencies === 'function' ? cmpDef.dependencies() : cmpDef.dependencies;
            for (const dep of deps) {
                walkProviderTree(dep, providersOut, parents, dedup);
            }
        }
    }
    else if (injDef) {
        // First, include providers from any imports.
        if (injDef.imports != null && !isDuplicate) {
            // Before processing defType's imports, add it to the set of parents. This way, if it ends
            // up deeply importing itself, this can be detected.
            ngDevMode && parents.push(defType);
            // Add it to the set of dedups. This way we can detect multiple imports of the same module
            dedup.add(defType);
            let importTypesWithProviders;
            try {
                deepForEach(injDef.imports, imported => {
                    if (walkProviderTree(imported, providersOut, parents, dedup)) {
                        importTypesWithProviders ||= [];
                        // If the processed import is an injector type with providers, we store it in the
                        // list of import types with providers, so that we can process those afterwards.
                        importTypesWithProviders.push(imported);
                    }
                });
            }
            finally {
                // Remove it from the parents set when finished.
                ngDevMode && parents.pop();
            }
            // Imports which are declared with providers (TypeWithProviders) need to be processed
            // after all imported modules are processed. This is similar to how View Engine
            // processes/merges module imports in the metadata resolver. See: FW-1349.
            if (importTypesWithProviders !== undefined) {
                processInjectorTypesWithProviders(importTypesWithProviders, providersOut);
            }
        }
        if (!isDuplicate) {
            // Track the InjectorType and add a provider for it.
            // It's important that this is done after the def's imports.
            const factory = getFactoryDef(defType) || (() => new defType());
            // Append extra providers to make more info available for consumers (to retrieve an injector
            // type), as well as internally (to calculate an injection scope correctly and eagerly
            // instantiate a `defType` when an injector is created).
            providersOut.push(
            // Provider to create `defType` using its factory.
            { provide: defType, useFactory: factory, deps: EMPTY_ARRAY }, 
            // Make this `defType` available to an internal logic that calculates injector scope.
            { provide: INJECTOR_DEF_TYPES, useValue: defType, multi: true }, 
            // Provider to eagerly instantiate `defType` via `ENVIRONMENT_INITIALIZER`.
            { provide: ENVIRONMENT_INITIALIZER, useValue: () => inject(defType), multi: true } //
            );
        }
        // Next, include providers listed on the definition itself.
        const defProviders = injDef.providers;
        if (defProviders != null && !isDuplicate) {
            const injectorType = container;
            deepForEachProvider(defProviders, provider => {
                ngDevMode && validateProvider(provider, defProviders, injectorType);
                providersOut.push(provider);
            });
        }
    }
    else {
        // Should not happen, but just in case.
        return false;
    }
    return (defType !== container &&
        container.providers !== undefined);
}
function validateProvider(provider, providers, containerType) {
    if (isTypeProvider(provider) || isValueProvider(provider) || isFactoryProvider(provider) ||
        isExistingProvider(provider)) {
        return;
    }
    // Here we expect the provider to be a `useClass` provider (by elimination).
    const classRef = resolveForwardRef(provider && (provider.useClass || provider.provide));
    if (!classRef) {
        throwInvalidProviderError(containerType, providers, provider);
    }
}
function deepForEachProvider(providers, fn) {
    for (let provider of providers) {
        if (isEnvironmentProviders(provider)) {
            provider = provider.ɵproviders;
        }
        if (Array.isArray(provider)) {
            deepForEachProvider(provider, fn);
        }
        else {
            fn(provider);
        }
    }
}
export const USE_VALUE = getClosureSafeProperty({ provide: String, useValue: getClosureSafeProperty });
export function isValueProvider(value) {
    return value !== null && typeof value == 'object' && USE_VALUE in value;
}
export function isExistingProvider(value) {
    return !!(value && value.useExisting);
}
export function isFactoryProvider(value) {
    return !!(value && value.useFactory);
}
export function isTypeProvider(value) {
    return typeof value === 'function';
}
export function isClassProvider(value) {
    return !!value.useClass;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicHJvdmlkZXJfY29sbGVjdGlvbi5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2RpL3Byb3ZpZGVyX2NvbGxlY3Rpb24udHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLFlBQVksRUFBbUIsTUFBTSxXQUFXLENBQUM7QUFFekQsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLHVCQUF1QixDQUFDO0FBQ3RELE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSwrQkFBK0IsQ0FBQztBQUM1RCxPQUFPLEVBQUMsMEJBQTBCLEVBQUUseUJBQXlCLEVBQUMsTUFBTSxzQkFBc0IsQ0FBQztBQUMzRixPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSxpQ0FBaUMsQ0FBQztBQUNsRSxPQUFPLEVBQUMsV0FBVyxFQUFDLE1BQU0scUJBQXFCLENBQUM7QUFDaEQsT0FBTyxFQUFDLFdBQVcsRUFBQyxNQUFNLGVBQWUsQ0FBQztBQUMxQyxPQUFPLEVBQUMsc0JBQXNCLEVBQUMsTUFBTSxrQkFBa0IsQ0FBQztBQUN4RCxPQUFPLEVBQUMsU0FBUyxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFFNUMsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQ2hELE9BQU8sRUFBQyx1QkFBdUIsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBQzVELE9BQU8sRUFBQyxRQUFRLElBQUksTUFBTSxFQUFDLE1BQU0sMEJBQTBCLENBQUM7QUFDNUQsT0FBTyxFQUFDLGNBQWMsRUFBMEMsTUFBTSxrQkFBa0IsQ0FBQztBQUN6RixPQUFPLEVBQXVKLHNCQUFzQixFQUFrRixNQUFNLHNCQUFzQixDQUFDO0FBQ25TLE9BQU8sRUFBQyxrQkFBa0IsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBRXJEOzs7R0FHRztBQUNILE1BQU0sVUFBVSx3QkFBd0IsQ0FBQyxTQUE0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RUQsTUFBTSxVQUFVLGtCQUFrQixDQUFDLEtBQXFCO0lBQ3RELE9BQU8sQ0FBQyxDQUFDLENBQUMsS0FBSyxJQUFLLEtBQTBCLENBQUMsV0FBVyxDQUFDLENBQUM7QUFDOUQsQ0FBQztBQUVELE1BQU0sVUFBVSxpQkFBaUIsQ0FBQyxLQUFxQjtJQUNyRCxPQUFPLENBQUMsQ0FBQyxDQUFDLEtBQUssSUFBSyxLQUF5QixDQUFDLFVBQVUsQ0FBQyxDQUFDO0FBQzVELENBQUM7QUFFRCxNQUFNLFVBQVUsY0FBYyxDQUFDLEtBQXFCO0lBQ2xELE9BQU8sT0FBTyxLQUFLLEtBQUssVUFBVSxDQUFDO0FBQ3JDLENBQUM7QUFFRCxNQUFNLFVBQVUsZUFBZSxDQUFDLEtBQXFCO0lBQ25ELE9BQU8sQ0FBQyxDQUFFLEtBQTZDLENBQUMsUUFBUSxDQUFDO0FBQ25FLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtSdW50aW1lRXJyb3IsIFJ1bnRpbWVFcnJvckNvZGV9IGZyb20gJy4uL2Vycm9ycyc7XG5pbXBvcnQge1R5cGV9IGZyb20gJy4uL2ludGVyZmFjZS90eXBlJztcbmltcG9ydCB7Z2V0Q29tcG9uZW50RGVmfSBmcm9tICcuLi9yZW5kZXIzL2RlZmluaXRpb24nO1xuaW1wb3J0IHtnZXRGYWN0b3J5RGVmfSBmcm9tICcuLi9yZW5kZXIzL2RlZmluaXRpb25fZmFjdG9yeSc7XG5pbXBvcnQge3Rocm93Q3ljbGljRGVwZW5kZW5jeUVycm9yLCB0aHJvd0ludmFsaWRQcm92aWRlckVycm9yfSBmcm9tICcuLi9yZW5kZXIzL2Vycm9yc19kaSc7XG5pbXBvcnQge3N0cmluZ2lmeUZvckVycm9yfSBmcm9tICcuLi9yZW5kZXIzL3V0aWwvc3RyaW5naWZ5X3V0aWxzJztcbmltcG9ydCB7ZGVlcEZvckVhY2h9IGZyb20gJy4uL3V0aWwvYXJyYXlfdXRpbHMnO1xuaW1wb3J0IHtFTVBUWV9BUlJBWX0gZnJvbSAnLi4vdXRpbC9lbXB0eSc7XG5pbXBvcnQge2dldENsb3N1cmVTYWZlUHJvcGVydHl9IGZyb20gJy4uL3V0aWwvcHJvcGVydHknO1xuaW1wb3J0IHtzdHJpbmdpZnl9IGZyb20gJy4uL3V0aWwvc3RyaW5naWZ5JztcblxuaW1wb3J0IHtyZXNvbHZlRm9yd2FyZFJlZn0gZnJvbSAnLi9mb3J3YXJkX3JlZic7XG5pbXBvcnQge0VOVklST05NRU5UX0lOSVRJQUxJWkVSfSBmcm9tICcuL2luaXRpYWxpemVyX3Rva2VuJztcbmltcG9ydCB7ybXJtWluamVjdCBhcyBpbmplY3R9IGZyb20gJy4vaW5qZWN0b3JfY29tcGF0aWJpbGl0eSc7XG5pbXBvcnQge2dldEluamVjdG9yRGVmLCBJbmplY3RvclR5cGUsIEluamVjdG9yVHlwZVdpdGhQcm92aWRlcnN9IGZyb20gJy4vaW50ZXJmYWNlL2RlZnMnO1xuaW1wb3J0IHtDbGFzc1Byb3ZpZGVyLCBDb25zdHJ1Y3RvclByb3ZpZGVyLCBFbnZpcm9ubWVudFByb3ZpZGVycywgRXhpc3RpbmdQcm92aWRlciwgRmFjdG9yeVByb3ZpZGVyLCBJbXBvcnRlZE5nTW9kdWxlUHJvdmlkZXJzLCBJbnRlcm5hbEVudmlyb25tZW50UHJvdmlkZXJzLCBpc0Vudmlyb25tZW50UHJvdmlkZXJzLCBNb2R1bGVXaXRoUHJvdmlkZXJzLCBQcm92aWRlciwgU3RhdGljQ2xhc3NQcm92aWRlciwgVHlwZVByb3ZpZGVyLCBWYWx1ZVByb3ZpZGVyfSBmcm9tICcuL2ludGVyZmFjZS9wcm92aWRlcic7XG5pbXBvcnQge0lOSkVDVE9SX0RFRl9UWVBFU30gZnJvbSAnLi9pbnRlcm5hbF90b2tlbnMnO1xuXG4vKipcbiAqIFdyYXAgYW4gYXJyYXkgb2YgYFByb3ZpZGVyYHMgaW50byBgRW52aXJvbm1lbnRQcm92aWRlcnNgLCBwcmV2ZW50aW5nIHRoZW0gZnJvbSBiZWluZyBhY2NpZGVudGFsbHlcbiAqIHJlZmVyZW5jZWQgaW4gYEBDb21wb25lbnQgaW4gYSBjb21wb25lbnQgaW5qZWN0b3IuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBtYWtlRW52aXJvbm1lbnRQcm92aWRlcnMocHJvdmlkZXJzOiAoUHJvdmlkZXJ8RW52aXJvbm1lbnRQcm92aWRlcnMpW10pOlxuICAgIEVudmlyb25tZW50UHJvdmlkZXJzIHtcbiAgcmV0dXJuIHtcbiAgICDJtXByb3ZpZGVyczogcHJvdmlkZXJzLFxuICB9IGFzIHVua25vd24gYXMgRW52aXJvbm1lbnRQcm92aWRlcnM7XG59XG5cbi8qKlxuICogQSBzb3VyY2Ugb2YgcHJvdmlkZXJzIGZvciB0aGUgYGltcG9ydFByb3ZpZGVyc0Zyb21gIGZ1bmN0aW9uLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IHR5cGUgSW1wb3J0UHJvdmlkZXJzU291cmNlID1cbiAgICBUeXBlPHVua25vd24+fE1vZHVsZVdpdGhQcm92aWRlcnM8dW5rbm93bj58QXJyYXk8SW1wb3J0UHJvdmlkZXJzU291cmNlPjtcblxuLyoqXG4gKiBDb2xsZWN0cyBwcm92aWRlcnMgZnJvbSBhbGwgTmdNb2R1bGVzIGFuZCBzdGFuZGFsb25lIGNvbXBvbmVudHMsIGluY2x1ZGluZyB0cmFuc2l0aXZlbHkgaW1wb3J0ZWRcbiAqIG9uZXMuXG4gKlxuICogUHJvdmlkZXJzIGV4dHJhY3RlZCB2aWEgYGltcG9ydFByb3ZpZGVyc0Zyb21gIGFyZSBvbmx5IHVzYWJsZSBpbiBhbiBhcHBsaWNhdGlvbiBpbmplY3RvciBvclxuICogYW5vdGhlciBlbnZpcm9ubWVudCBpbmplY3RvciAoc3VjaCBhcyBhIHJvdXRlIGluamVjdG9yKS4gVGhleSBzaG91bGQgbm90IGJlIHVzZWQgaW4gY29tcG9uZW50XG4gKiBwcm92aWRlcnMuXG4gKlxuICogTW9yZSBpbmZvcm1hdGlvbiBhYm91dCBzdGFuZGFsb25lIGNvbXBvbmVudHMgY2FuIGJlIGZvdW5kIGluIFt0aGlzXG4gKiBndWlkZV0oZ3VpZGUvc3RhbmRhbG9uZS1jb21wb25lbnRzKS5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICogVGhlIHJlc3VsdHMgb2YgdGhlIGBpbXBvcnRQcm92aWRlcnNGcm9tYCBjYWxsIGNhbiBiZSB1c2VkIGluIHRoZSBgYm9vdHN0cmFwQXBwbGljYXRpb25gIGNhbGw6XG4gKlxuICogYGBgdHlwZXNjcmlwdFxuICogYXdhaXQgYm9vdHN0cmFwQXBwbGljYXRpb24oUm9vdENvbXBvbmVudCwge1xuICogICBwcm92aWRlcnM6IFtcbiAqICAgICBpbXBvcnRQcm92aWRlcnNGcm9tKE5nTW9kdWxlT25lLCBOZ01vZHVsZVR3bylcbiAqICAgXVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBZb3UgY2FuIGFsc28gdXNlIHRoZSBgaW1wb3J0UHJvdmlkZXJzRnJvbWAgcmVzdWx0cyBpbiB0aGUgYHByb3ZpZGVyc2AgZmllbGQgb2YgYSByb3V0ZSwgd2hlbiBhXG4gKiBzdGFuZGFsb25lIGNvbXBvbmVudCBpcyB1c2VkOlxuICpcbiAqIGBgYHR5cGVzY3JpcHRcbiAqIGV4cG9ydCBjb25zdCBST1VURVM6IFJvdXRlW10gPSBbXG4gKiAgIHtcbiAqICAgICBwYXRoOiAnZm9vJyxcbiAqICAgICBwcm92aWRlcnM6IFtcbiAqICAgICAgIGltcG9ydFByb3ZpZGVyc0Zyb20oTmdNb2R1bGVPbmUsIE5nTW9kdWxlVHdvKVxuICogICAgIF0sXG4gKiAgICAgY29tcG9uZW50OiBZb3VyU3RhbmRhbG9uZUNvbXBvbmVudFxuICogICB9XG4gKiBdO1xuICogYGBgXG4gKlxuICogQHJldHVybnMgQ29sbGVjdGVkIHByb3ZpZGVycyBmcm9tIHRoZSBzcGVjaWZpZWQgbGlzdCBvZiB0eXBlcy5cbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGltcG9ydFByb3ZpZGVyc0Zyb20oLi4uc291cmNlczogSW1wb3J0UHJvdmlkZXJzU291cmNlW10pOiBFbnZpcm9ubWVudFByb3ZpZGVycyB7XG4gIHJldHVybiB7XG4gICAgybVwcm92aWRlcnM6IGludGVybmFsSW1wb3J0UHJvdmlkZXJzRnJvbSh0cnVlLCBzb3VyY2VzKSxcbiAgICDJtWZyb21OZ01vZHVsZTogdHJ1ZSxcbiAgfSBhcyBJbnRlcm5hbEVudmlyb25tZW50UHJvdmlkZXJzO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gaW50ZXJuYWxJbXBvcnRQcm92aWRlcnNGcm9tKFxuICAgIGNoZWNrRm9yU3RhbmRhbG9uZUNtcDogYm9vbGVhbiwgLi4uc291cmNlczogSW1wb3J0UHJvdmlkZXJzU291cmNlW10pOiBQcm92aWRlcltdIHtcbiAgY29uc3QgcHJvdmlkZXJzT3V0OiBTaW5nbGVQcm92aWRlcltdID0gW107XG4gIGNvbnN0IGRlZHVwID0gbmV3IFNldDxUeXBlPHVua25vd24+PigpOyAgLy8gYWxyZWFkeSBzZWVuIHR5cGVzXG4gIGxldCBpbmplY3RvclR5cGVzV2l0aFByb3ZpZGVyczogSW5qZWN0b3JUeXBlV2l0aFByb3ZpZGVyczx1bmtub3duPltdfHVuZGVmaW5lZDtcbiAgZGVlcEZvckVhY2goc291cmNlcywgc291cmNlID0+IHtcbiAgICBpZiAoKHR5cGVvZiBuZ0Rldk1vZGUgPT09ICd1bmRlZmluZWQnIHx8IG5nRGV2TW9kZSkgJiYgY2hlY2tGb3JTdGFuZGFsb25lQ21wKSB7XG4gICAgICBjb25zdCBjbXBEZWYgPSBnZXRDb21wb25lbnREZWYoc291cmNlKTtcbiAgICAgIGlmIChjbXBEZWY/LnN0YW5kYWxvbmUpIHtcbiAgICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuSU1QT1JUX1BST1ZJREVSU19GUk9NX1NUQU5EQUxPTkUsXG4gICAgICAgICAgICBgSW1wb3J0aW5nIHByb3ZpZGVycyBzdXBwb3J0cyBOZ01vZHVsZSBvciBNb2R1bGVXaXRoUHJvdmlkZXJzIGJ1dCBnb3QgYSBzdGFuZGFsb25lIGNvbXBvbmVudCBcIiR7XG4gICAgICAgICAgICAgICAgc3RyaW5naWZ5Rm9yRXJyb3Ioc291cmNlKX1cImApO1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIE5hcnJvdyBgc291cmNlYCB0byBhY2Nlc3MgdGhlIGludGVybmFsIHR5cGUgYW5hbG9ndWUgZm9yIGBNb2R1bGVXaXRoUHJvdmlkZXJzYC5cbiAgICBjb25zdCBpbnRlcm5hbFNvdXJjZSA9IHNvdXJjZSBhcyBUeXBlPHVua25vd24+fCBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzPHVua25vd24+O1xuICAgIGlmICh3YWxrUHJvdmlkZXJUcmVlKGludGVybmFsU291cmNlLCBwcm92aWRlcnNPdXQsIFtdLCBkZWR1cCkpIHtcbiAgICAgIGluamVjdG9yVHlwZXNXaXRoUHJvdmlkZXJzIHx8PSBbXTtcbiAgICAgIGluamVjdG9yVHlwZXNXaXRoUHJvdmlkZXJzLnB1c2goaW50ZXJuYWxTb3VyY2UpO1xuICAgIH1cbiAgfSk7XG4gIC8vIENvbGxlY3QgYWxsIHByb3ZpZGVycyBmcm9tIGBNb2R1bGVXaXRoUHJvdmlkZXJzYCB0eXBlcy5cbiAgaWYgKGluamVjdG9yVHlwZXNXaXRoUHJvdmlkZXJzICE9PSB1bmRlZmluZWQpIHtcbiAgICBwcm9jZXNzSW5qZWN0b3JUeXBlc1dpdGhQcm92aWRlcnMoaW5qZWN0b3JUeXBlc1dpdGhQcm92aWRlcnMsIHByb3ZpZGVyc091dCk7XG4gIH1cblxuICByZXR1cm4gcHJvdmlkZXJzT3V0O1xufVxuXG4vKipcbiAqIENvbGxlY3RzIGFsbCBwcm92aWRlcnMgZnJvbSB0aGUgbGlzdCBvZiBgTW9kdWxlV2l0aFByb3ZpZGVyc2AgYW5kIGFwcGVuZHMgdGhlbSB0byB0aGUgcHJvdmlkZWRcbiAqIGFycmF5LlxuICovXG5mdW5jdGlvbiBwcm9jZXNzSW5qZWN0b3JUeXBlc1dpdGhQcm92aWRlcnMoXG4gICAgdHlwZXNXaXRoUHJvdmlkZXJzOiBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzPHVua25vd24+W10sIHByb3ZpZGVyc091dDogUHJvdmlkZXJbXSk6IHZvaWQge1xuICBmb3IgKGxldCBpID0gMDsgaSA8IHR5cGVzV2l0aFByb3ZpZGVycy5sZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IHtuZ01vZHVsZSwgcHJvdmlkZXJzfSA9IHR5cGVzV2l0aFByb3ZpZGVyc1tpXTtcbiAgICBkZWVwRm9yRWFjaFByb3ZpZGVyKHByb3ZpZGVycyEgYXMgQXJyYXk8UHJvdmlkZXJ8SW50ZXJuYWxFbnZpcm9ubWVudFByb3ZpZGVycz4sIHByb3ZpZGVyID0+IHtcbiAgICAgIG5nRGV2TW9kZSAmJiB2YWxpZGF0ZVByb3ZpZGVyKHByb3ZpZGVyLCBwcm92aWRlcnMgfHwgRU1QVFlfQVJSQVksIG5nTW9kdWxlKTtcbiAgICAgIHByb3ZpZGVyc091dC5wdXNoKHByb3ZpZGVyKTtcbiAgICB9KTtcbiAgfVxufVxuXG4vKipcbiAqIEludGVybmFsIHR5cGUgZm9yIGEgc2luZ2xlIHByb3ZpZGVyIGluIGEgZGVlcCBwcm92aWRlciBhcnJheS5cbiAqL1xuZXhwb3J0IHR5cGUgU2luZ2xlUHJvdmlkZXIgPSBUeXBlUHJvdmlkZXJ8VmFsdWVQcm92aWRlcnxDbGFzc1Byb3ZpZGVyfENvbnN0cnVjdG9yUHJvdmlkZXJ8XG4gICAgRXhpc3RpbmdQcm92aWRlcnxGYWN0b3J5UHJvdmlkZXJ8U3RhdGljQ2xhc3NQcm92aWRlcjtcblxuLyoqXG4gKiBUaGUgbG9naWMgdmlzaXRzIGFuIGBJbmplY3RvclR5cGVgLCBhbiBgSW5qZWN0b3JUeXBlV2l0aFByb3ZpZGVyc2AsIG9yIGEgc3RhbmRhbG9uZVxuICogYENvbXBvbmVudFR5cGVgLCBhbmQgYWxsIG9mIGl0cyB0cmFuc2l0aXZlIHByb3ZpZGVycyBhbmQgY29sbGVjdHMgcHJvdmlkZXJzLlxuICpcbiAqIElmIGFuIGBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzYCB0aGF0IGRlY2xhcmVzIHByb3ZpZGVycyBiZXNpZGVzIHRoZSB0eXBlIGlzIHNwZWNpZmllZCxcbiAqIHRoZSBmdW5jdGlvbiB3aWxsIHJldHVybiBcInRydWVcIiB0byBpbmRpY2F0ZSB0aGF0IHRoZSBwcm92aWRlcnMgb2YgdGhlIHR5cGUgZGVmaW5pdGlvbiBuZWVkXG4gKiB0byBiZSBwcm9jZXNzZWQuIFRoaXMgYWxsb3dzIHVzIHRvIHByb2Nlc3MgcHJvdmlkZXJzIG9mIGluamVjdG9yIHR5cGVzIGFmdGVyIGFsbCBpbXBvcnRzIG9mXG4gKiBhbiBpbmplY3RvciBkZWZpbml0aW9uIGFyZSBwcm9jZXNzZWQuIChmb2xsb3dpbmcgVmlldyBFbmdpbmUgc2VtYW50aWNzOiBzZWUgRlctMTM0OSlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdhbGtQcm92aWRlclRyZWUoXG4gICAgY29udGFpbmVyOiBUeXBlPHVua25vd24+fEluamVjdG9yVHlwZVdpdGhQcm92aWRlcnM8dW5rbm93bj4sIHByb3ZpZGVyc091dDogU2luZ2xlUHJvdmlkZXJbXSxcbiAgICBwYXJlbnRzOiBUeXBlPHVua25vd24+W10sXG4gICAgZGVkdXA6IFNldDxUeXBlPHVua25vd24+Pik6IGNvbnRhaW5lciBpcyBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzPHVua25vd24+IHtcbiAgY29udGFpbmVyID0gcmVzb2x2ZUZvcndhcmRSZWYoY29udGFpbmVyKTtcbiAgaWYgKCFjb250YWluZXIpIHJldHVybiBmYWxzZTtcblxuICAvLyBUaGUgYWN0dWFsIHR5cGUgd2hpY2ggaGFkIHRoZSBkZWZpbml0aW9uLiBVc3VhbGx5IGBjb250YWluZXJgLCBidXQgbWF5IGJlIGFuIHVud3JhcHBlZCB0eXBlXG4gIC8vIGZyb20gYEluamVjdG9yVHlwZVdpdGhQcm92aWRlcnNgLlxuICBsZXQgZGVmVHlwZTogVHlwZTx1bmtub3duPnxudWxsID0gbnVsbDtcblxuICBsZXQgaW5qRGVmID0gZ2V0SW5qZWN0b3JEZWYoY29udGFpbmVyKTtcbiAgY29uc3QgY21wRGVmID0gIWluakRlZiAmJiBnZXRDb21wb25lbnREZWYoY29udGFpbmVyKTtcbiAgaWYgKCFpbmpEZWYgJiYgIWNtcERlZikge1xuICAgIC8vIGBjb250YWluZXJgIGlzIG5vdCBhbiBpbmplY3RvciB0eXBlIG9yIGEgY29tcG9uZW50IHR5cGUuIEl0IG1pZ2h0IGJlOlxuICAgIC8vICAqIEFuIGBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzYCB0aGF0IHdyYXBzIGFuIGluamVjdG9yIHR5cGUuXG4gICAgLy8gICogQSBzdGFuZGFsb25lIGRpcmVjdGl2ZSBvciBwaXBlIHRoYXQgZ290IHB1bGxlZCBpbiBmcm9tIGEgc3RhbmRhbG9uZSBjb21wb25lbnQnc1xuICAgIC8vICAgIGRlcGVuZGVuY2llcy5cbiAgICAvLyBUcnkgdG8gdW53cmFwIGl0IGFzIGFuIGBJbmplY3RvclR5cGVXaXRoUHJvdmlkZXJzYCBmaXJzdC5cbiAgICBjb25zdCBuZ01vZHVsZTogVHlwZTx1bmtub3duPnx1bmRlZmluZWQgPVxuICAgICAgICAoY29udGFpbmVyIGFzIEluamVjdG9yVHlwZVdpdGhQcm92aWRlcnM8YW55PikubmdNb2R1bGUgYXMgVHlwZTx1bmtub3duPnwgdW5kZWZpbmVkO1xuICAgIGluakRlZiA9IGdldEluamVjdG9yRGVmKG5nTW9kdWxlKTtcbiAgICBpZiAoaW5qRGVmKSB7XG4gICAgICBkZWZUeXBlID0gbmdNb2R1bGUhO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBOb3QgYSBjb21wb25lbnQgb3IgaW5qZWN0b3IgdHlwZSwgc28gaWdub3JlIGl0LlxuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbiAgfSBlbHNlIGlmIChjbXBEZWYgJiYgIWNtcERlZi5zdGFuZGFsb25lKSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9IGVsc2Uge1xuICAgIGRlZlR5cGUgPSBjb250YWluZXIgYXMgVHlwZTx1bmtub3duPjtcbiAgfVxuXG4gIC8vIENoZWNrIGZvciBjaXJjdWxhciBkZXBlbmRlbmNpZXMuXG4gIGlmIChuZ0Rldk1vZGUgJiYgcGFyZW50cy5pbmRleE9mKGRlZlR5cGUpICE9PSAtMSkge1xuICAgIGNvbnN0IGRlZk5hbWUgPSBzdHJpbmdpZnkoZGVmVHlwZSk7XG4gICAgY29uc3QgcGF0aCA9IHBhcmVudHMubWFwKHN0cmluZ2lmeSk7XG4gICAgdGhyb3dDeWNsaWNEZXBlbmRlbmN5RXJyb3IoZGVmTmFtZSwgcGF0aCk7XG4gIH1cblxuICAvLyBDaGVjayBmb3IgbXVsdGlwbGUgaW1wb3J0cyBvZiB0aGUgc2FtZSBtb2R1bGVcbiAgY29uc3QgaXNEdXBsaWNhdGUgPSBkZWR1cC5oYXMoZGVmVHlwZSk7XG5cbiAgaWYgKGNtcERlZikge1xuICAgIGlmIChpc0R1cGxpY2F0ZSkge1xuICAgICAgLy8gVGhpcyBjb21wb25lbnQgZGVmaW5pdGlvbiBoYXMgYWxyZWFkeSBiZWVuIHByb2Nlc3NlZC5cbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gICAgZGVkdXAuYWRkKGRlZlR5cGUpO1xuXG4gICAgaWYgKGNtcERlZi5kZXBlbmRlbmNpZXMpIHtcbiAgICAgIGNvbnN0IGRlcHMgPVxuICAgICAgICAgIHR5cGVvZiBjbXBEZWYuZGVwZW5kZW5jaWVzID09PSAnZnVuY3Rpb24nID8gY21wRGVmLmRlcGVuZGVuY2llcygpIDogY21wRGVmLmRlcGVuZGVuY2llcztcbiAgICAgIGZvciAoY29uc3QgZGVwIG9mIGRlcHMpIHtcbiAgICAgICAgd2Fsa1Byb3ZpZGVyVHJlZShkZXAsIHByb3ZpZGVyc091dCwgcGFyZW50cywgZGVkdXApO1xuICAgICAgfVxuICAgIH1cbiAgfSBlbHNlIGlmIChpbmpEZWYpIHtcbiAgICAvLyBGaXJzdCwgaW5jbHVkZSBwcm92aWRlcnMgZnJvbSBhbnkgaW1wb3J0cy5cbiAgICBpZiAoaW5qRGVmLmltcG9ydHMgIT0gbnVsbCAmJiAhaXNEdXBsaWNhdGUpIHtcbiAgICAgIC8vIEJlZm9yZSBwcm9jZXNzaW5nIGRlZlR5cGUncyBpbXBvcnRzLCBhZGQgaXQgdG8gdGhlIHNldCBvZiBwYXJlbnRzLiBUaGlzIHdheSwgaWYgaXQgZW5kc1xuICAgICAgLy8gdXAgZGVlcGx5IGltcG9ydGluZyBpdHNlbGYsIHRoaXMgY2FuIGJlIGRldGVjdGVkLlxuICAgICAgbmdEZXZNb2RlICYmIHBhcmVudHMucHVzaChkZWZUeXBlKTtcbiAgICAgIC8vIEFkZCBpdCB0byB0aGUgc2V0IG9mIGRlZHVwcy4gVGhpcyB3YXkgd2UgY2FuIGRldGVjdCBtdWx0aXBsZSBpbXBvcnRzIG9mIHRoZSBzYW1lIG1vZHVsZVxuICAgICAgZGVkdXAuYWRkKGRlZlR5cGUpO1xuXG4gICAgICBsZXQgaW1wb3J0VHlwZXNXaXRoUHJvdmlkZXJzOiAoSW5qZWN0b3JUeXBlV2l0aFByb3ZpZGVyczxhbnk+W10pfHVuZGVmaW5lZDtcbiAgICAgIHRyeSB7XG4gICAgICAgIGRlZXBGb3JFYWNoKGluakRlZi5pbXBvcnRzLCBpbXBvcnRlZCA9PiB7XG4gICAgICAgICAgaWYgKHdhbGtQcm92aWRlclRyZWUoaW1wb3J0ZWQsIHByb3ZpZGVyc091dCwgcGFyZW50cywgZGVkdXApKSB7XG4gICAgICAgICAgICBpbXBvcnRUeXBlc1dpdGhQcm92aWRlcnMgfHw9IFtdO1xuICAgICAgICAgICAgLy8gSWYgdGhlIHByb2Nlc3NlZCBpbXBvcnQgaXMgYW4gaW5qZWN0b3IgdHlwZSB3aXRoIHByb3ZpZGVycywgd2Ugc3RvcmUgaXQgaW4gdGhlXG4gICAgICAgICAgICAvLyBsaXN0IG9mIGltcG9ydCB0eXBlcyB3aXRoIHByb3ZpZGVycywgc28gdGhhdCB3ZSBjYW4gcHJvY2VzcyB0aG9zZSBhZnRlcndhcmRzLlxuICAgICAgICAgICAgaW1wb3J0VHlwZXNXaXRoUHJvdmlkZXJzLnB1c2goaW1wb3J0ZWQpO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9IGZpbmFsbHkge1xuICAgICAgICAvLyBSZW1vdmUgaXQgZnJvbSB0aGUgcGFyZW50cyBzZXQgd2hlbiBmaW5pc2hlZC5cbiAgICAgICAgbmdEZXZNb2RlICYmIHBhcmVudHMucG9wKCk7XG4gICAgICB9XG5cbiAgICAgIC8vIEltcG9ydHMgd2hpY2ggYXJlIGRlY2xhcmVkIHdpdGggcHJvdmlkZXJzIChUeXBlV2l0aFByb3ZpZGVycykgbmVlZCB0byBiZSBwcm9jZXNzZWRcbiAgICAgIC8vIGFmdGVyIGFsbCBpbXBvcnRlZCBtb2R1bGVzIGFyZSBwcm9jZXNzZWQuIFRoaXMgaXMgc2ltaWxhciB0byBob3cgVmlldyBFbmdpbmVcbiAgICAgIC8vIHByb2Nlc3Nlcy9tZXJnZXMgbW9kdWxlIGltcG9ydHMgaW4gdGhlIG1ldGFkYXRhIHJlc29sdmVyLiBTZWU6IEZXLTEzNDkuXG4gICAgICBpZiAoaW1wb3J0VHlwZXNXaXRoUHJvdmlkZXJzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgcHJvY2Vzc0luamVjdG9yVHlwZXNXaXRoUHJvdmlkZXJzKGltcG9ydFR5cGVzV2l0aFByb3ZpZGVycywgcHJvdmlkZXJzT3V0KTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAoIWlzRHVwbGljYXRlKSB7XG4gICAgICAvLyBUcmFjayB0aGUgSW5qZWN0b3JUeXBlIGFuZCBhZGQgYSBwcm92aWRlciBmb3IgaXQuXG4gICAgICAvLyBJdCdzIGltcG9ydGFudCB0aGF0IHRoaXMgaXMgZG9uZSBhZnRlciB0aGUgZGVmJ3MgaW1wb3J0cy5cbiAgICAgIGNvbnN0IGZhY3RvcnkgPSBnZXRGYWN0b3J5RGVmKGRlZlR5cGUpIHx8ICgoKSA9PiBuZXcgZGVmVHlwZSEoKSk7XG5cbiAgICAgIC8vIEFwcGVuZCBleHRyYSBwcm92aWRlcnMgdG8gbWFrZSBtb3JlIGluZm8gYXZhaWxhYmxlIGZvciBjb25zdW1lcnMgKHRvIHJldHJpZXZlIGFuIGluamVjdG9yXG4gICAgICAvLyB0eXBlKSwgYXMgd2VsbCBhcyBpbnRlcm5hbGx5ICh0byBjYWxjdWxhdGUgYW4gaW5qZWN0aW9uIHNjb3BlIGNvcnJlY3RseSBhbmQgZWFnZXJseVxuICAgICAgLy8gaW5zdGFudGlhdGUgYSBgZGVmVHlwZWAgd2hlbiBhbiBpbmplY3RvciBpcyBjcmVhdGVkKS5cbiAgICAgIHByb3ZpZGVyc091dC5wdXNoKFxuICAgICAgICAgIC8vIFByb3ZpZGVyIHRvIGNyZWF0ZSBgZGVmVHlwZWAgdXNpbmcgaXRzIGZhY3RvcnkuXG4gICAgICAgICAge3Byb3ZpZGU6IGRlZlR5cGUsIHVzZUZhY3Rvcnk6IGZhY3RvcnksIGRlcHM6IEVNUFRZX0FSUkFZfSxcblxuICAgICAgICAgIC8vIE1ha2UgdGhpcyBgZGVmVHlwZWAgYXZhaWxhYmxlIHRvIGFuIGludGVybmFsIGxvZ2ljIHRoYXQgY2FsY3VsYXRlcyBpbmplY3RvciBzY29wZS5cbiAgICAgICAgICB7cHJvdmlkZTogSU5KRUNUT1JfREVGX1RZUEVTLCB1c2VWYWx1ZTogZGVmVHlwZSwgbXVsdGk6IHRydWV9LFxuXG4gICAgICAgICAgLy8gUHJvdmlkZXIgdG8gZWFnZXJseSBpbnN0YW50aWF0ZSBgZGVmVHlwZWAgdmlhIGBFTlZJUk9OTUVOVF9JTklUSUFMSVpFUmAuXG4gICAgICAgICAge3Byb3ZpZGU6IEVOVklST05NRU5UX0lOSVRJQUxJWkVSLCB1c2VWYWx1ZTogKCkgPT4gaW5qZWN0KGRlZlR5cGUhKSwgbXVsdGk6IHRydWV9ICAvL1xuICAgICAgKTtcbiAgICB9XG5cbiAgICAvLyBOZXh0LCBpbmNsdWRlIHByb3ZpZGVycyBsaXN0ZWQgb24gdGhlIGRlZmluaXRpb24gaXRzZWxmLlxuICAgIGNvbnN0IGRlZlByb3ZpZGVycyA9IGluakRlZi5wcm92aWRlcnMgYXMgQXJyYXk8U2luZ2xlUHJvdmlkZXJ8SW50ZXJuYWxFbnZpcm9ubWVudFByb3ZpZGVycz47XG4gICAgaWYgKGRlZlByb3ZpZGVycyAhPSBudWxsICYmICFpc0R1cGxpY2F0ZSkge1xuICAgICAgY29uc3QgaW5qZWN0b3JUeXBlID0gY29udGFpbmVyIGFzIEluamVjdG9yVHlwZTxhbnk+O1xuICAgICAgZGVlcEZvckVhY2hQcm92aWRlcihkZWZQcm92aWRlcnMsIHByb3ZpZGVyID0+IHtcbiAgICAgICAgbmdEZXZNb2RlICYmIHZhbGlkYXRlUHJvdmlkZXIocHJvdmlkZXIgYXMgU2luZ2xlUHJvdmlkZXIsIGRlZlByb3ZpZGVycywgaW5qZWN0b3JUeXBlKTtcbiAgICAgICAgcHJvdmlkZXJzT3V0LnB1c2gocHJvdmlkZXIgYXMgU2luZ2xlUHJvdmlkZXIpO1xuICAgICAgfSk7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIC8vIFNob3VsZCBub3QgaGFwcGVuLCBidXQganVzdCBpbiBjYXNlLlxuICAgIHJldHVybiBmYWxzZTtcbiAgfVxuXG4gIHJldHVybiAoXG4gICAgICBkZWZUeXBlICE9PSBjb250YWluZXIgJiZcbiAgICAgIChjb250YWluZXIgYXMgSW5qZWN0b3JUeXBlV2l0aFByb3ZpZGVyczxhbnk+KS5wcm92aWRlcnMgIT09IHVuZGVmaW5lZCk7XG59XG5cbmZ1bmN0aW9uIHZhbGlkYXRlUHJvdmlkZXIoXG4gICAgcHJvdmlkZXI6IFNpbmdsZVByb3ZpZGVyLCBwcm92aWRlcnM6IEFycmF5PFNpbmdsZVByb3ZpZGVyfEludGVybmFsRW52aXJvbm1lbnRQcm92aWRlcnM+LFxuICAgIGNvbnRhaW5lclR5cGU6IFR5cGU8dW5rbm93bj4pOiB2b2lkIHtcbiAgaWYgKGlzVHlwZVByb3ZpZGVyKHByb3ZpZGVyKSB8fCBpc1ZhbHVlUHJvdmlkZXIocHJvdmlkZXIpIHx8IGlzRmFjdG9yeVByb3ZpZGVyKHByb3ZpZGVyKSB8fFxuICAgICAgaXNFeGlzdGluZ1Byb3ZpZGVyKHByb3ZpZGVyKSkge1xuICAgIHJldHVybjtcbiAgfVxuXG4gIC8vIEhlcmUgd2UgZXhwZWN0IHRoZSBwcm92aWRlciB0byBiZSBhIGB1c2VDbGFzc2AgcHJvdmlkZXIgKGJ5IGVsaW1pbmF0aW9uKS5cbiAgY29uc3QgY2xhc3NSZWYgPSByZXNvbHZlRm9yd2FyZFJlZihcbiAgICAgIHByb3ZpZGVyICYmICgocHJvdmlkZXIgYXMgU3RhdGljQ2xhc3NQcm92aWRlciB8IENsYXNzUHJvdmlkZXIpLnVzZUNsYXNzIHx8IHByb3ZpZGVyLnByb3ZpZGUpKTtcbiAgaWYgKCFjbGFzc1JlZikge1xuICAgIHRocm93SW52YWxpZFByb3ZpZGVyRXJyb3IoY29udGFpbmVyVHlwZSwgcHJvdmlkZXJzLCBwcm92aWRlcik7XG4gIH1cbn1cblxuZnVuY3Rpb24gZGVlcEZvckVhY2hQcm92aWRlcihcbiAgICBwcm92aWRlcnM6IEFycmF5PFByb3ZpZGVyfEludGVybmFsRW52aXJvbm1lbnRQcm92aWRlcnM+LFxuICAgIGZuOiAocHJvdmlkZXI6IFNpbmdsZVByb3ZpZGVyKSA9PiB2b2lkKTogdm9pZCB7XG4gIGZvciAobGV0IHByb3ZpZGVyIG9mIHByb3ZpZGVycykge1xuICAgIGlmIChpc0Vudmlyb25tZW50UHJvdmlkZXJzKHByb3ZpZGVyKSkge1xuICAgICAgcHJvdmlkZXIgPSBwcm92aWRlci7JtXByb3ZpZGVycztcbiAgICB9XG4gICAgaWYgKEFycmF5LmlzQXJyYXkocHJvdmlkZXIpKSB7XG4gICAgICBkZWVwRm9yRWFjaFByb3ZpZGVyKHByb3ZpZGVyLCBmbik7XG4gICAgfSBlbHNlIHtcbiAgICAgIGZuKHByb3ZpZGVyKTtcbiAgICB9XG4gIH1cbn1cblxuZXhwb3J0IGNvbnN0IFVTRV9WQUxVRSA9XG4gICAgZ2V0Q2xvc3VyZVNhZmVQcm9wZXJ0eTxWYWx1ZVByb3ZpZGVyPih7cHJvdmlkZTogU3RyaW5nLCB1c2VWYWx1ZTogZ2V0Q2xvc3VyZVNhZmVQcm9wZXJ0eX0pO1xuXG5leHBvcnQgZnVuY3Rpb24gaXNWYWx1ZVByb3ZpZGVyKHZhbHVlOiBTaW5nbGVQcm92aWRlcik6IHZhbHVlIGlzIFZhbHVlUHJvdmlkZXIge1xuICByZXR1cm4gdmFsdWUgIT09IG51bGwgJiYgdHlwZW9mIHZhbHVlID09ICdvYmplY3QnICYmIFVTRV9WQUxVRSBpbiB2YWx1ZTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGlzRXhpc3RpbmdQcm92aWRlcih2YWx1ZTogU2luZ2xlUHJvdmlkZXIpOiB2YWx1ZSBpcyBFeGlzdGluZ1Byb3ZpZGVyIHtcbiAgcmV0dXJuICEhKHZhbHVlICYmICh2YWx1ZSBhcyBFeGlzdGluZ1Byb3ZpZGVyKS51c2VFeGlzdGluZyk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc0ZhY3RvcnlQcm92aWRlcih2YWx1ZTogU2luZ2xlUHJvdmlkZXIpOiB2YWx1ZSBpcyBGYWN0b3J5UHJvdmlkZXIge1xuICByZXR1cm4gISEodmFsdWUgJiYgKHZhbHVlIGFzIEZhY3RvcnlQcm92aWRlcikudXNlRmFjdG9yeSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc1R5cGVQcm92aWRlcih2YWx1ZTogU2luZ2xlUHJvdmlkZXIpOiB2YWx1ZSBpcyBUeXBlUHJvdmlkZXIge1xuICByZXR1cm4gdHlwZW9mIHZhbHVlID09PSAnZnVuY3Rpb24nO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gaXNDbGFzc1Byb3ZpZGVyKHZhbHVlOiBTaW5nbGVQcm92aWRlcik6IHZhbHVlIGlzIENsYXNzUHJvdmlkZXIge1xuICByZXR1cm4gISEodmFsdWUgYXMgU3RhdGljQ2xhc3NQcm92aWRlciB8IENsYXNzUHJvdmlkZXIpLnVzZUNsYXNzO1xufVxuIl19