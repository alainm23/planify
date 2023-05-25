/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵɵinject as inject } from '../../di/injector_compatibility';
import { ɵɵdefineInjectable as defineInjectable } from '../../di/interface/defs';
import { internalImportProvidersFrom } from '../../di/provider_collection';
import { EnvironmentInjector } from '../../di/r3_injector';
import { createEnvironmentInjector } from '../ng_module_ref';
/**
 * A service used by the framework to create instances of standalone injectors. Those injectors are
 * created on demand in case of dynamic component instantiation and contain ambient providers
 * collected from the imports graph rooted at a given standalone component.
 */
class StandaloneService {
    constructor(_injector) {
        this._injector = _injector;
        this.cachedInjectors = new Map();
    }
    getOrCreateStandaloneInjector(componentDef) {
        if (!componentDef.standalone) {
            return null;
        }
        if (!this.cachedInjectors.has(componentDef.id)) {
            const providers = internalImportProvidersFrom(false, componentDef.type);
            const standaloneInjector = providers.length > 0 ?
                createEnvironmentInjector([providers], this._injector, `Standalone[${componentDef.type.name}]`) :
                null;
            this.cachedInjectors.set(componentDef.id, standaloneInjector);
        }
        return this.cachedInjectors.get(componentDef.id);
    }
    ngOnDestroy() {
        try {
            for (const injector of this.cachedInjectors.values()) {
                if (injector !== null) {
                    injector.destroy();
                }
            }
        }
        finally {
            this.cachedInjectors.clear();
        }
    }
    /** @nocollapse */
    static { this.ɵprov = defineInjectable({
        token: StandaloneService,
        providedIn: 'environment',
        factory: () => new StandaloneService(inject(EnvironmentInjector)),
    }); }
}
/**
 * A feature that acts as a setup code for the {@link StandaloneService}.
 *
 * The most important responsibility of this feature is to expose the "getStandaloneInjector"
 * function (an entry points to a standalone injector creation) on a component definition object. We
 * go through the features infrastructure to make sure that the standalone injector creation logic
 * is tree-shakable and not included in applications that don't use standalone components.
 *
 * @codeGenApi
 */
export function ɵɵStandaloneFeature(definition) {
    definition.getStandaloneInjector = (parentInjector) => {
        return parentInjector.get(StandaloneService).getOrCreateStandaloneInjector(definition);
    };
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic3RhbmRhbG9uZV9mZWF0dXJlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9mZWF0dXJlcy9zdGFuZGFsb25lX2ZlYXR1cmUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBQ0gsT0FBTyxFQUFDLFFBQVEsSUFBSSxNQUFNLEVBQUMsTUFBTSxpQ0FBaUMsQ0FBQztBQUNuRSxPQUFPLEVBQUMsa0JBQWtCLElBQUksZ0JBQWdCLEVBQUMsTUFBTSx5QkFBeUIsQ0FBQztBQUMvRSxPQUFPLEVBQUMsMkJBQTJCLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUN6RSxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSxzQkFBc0IsQ0FBQztBQUd6RCxPQUFPLEVBQUMseUJBQXlCLEVBQUMsTUFBTSxrQkFBa0IsQ0FBQztBQUUzRDs7OztHQUlHO0FBQ0gsTUFBTSxpQkFBaUI7SUFHckIsWUFBb0IsU0FBOEI7UUFBOUIsY0FBUyxHQUFULFNBQVMsQ0FBcUI7UUFGbEQsb0JBQWUsR0FBRyxJQUFJLEdBQUcsRUFBb0MsQ0FBQztJQUVULENBQUM7SUFFdEQsNkJBQTZCLENBQUMsWUFBbUM7UUFDL0QsSUFBSSxDQUFDLFlBQVksQ0FBQyxVQUFVLEVBQUU7WUFDNUIsT0FBTyxJQUFJLENBQUM7U0FDYjtRQUVELElBQUksQ0FBQyxJQUFJLENBQUMsZUFBZSxDQUFDLEdBQUcsQ0FBQyxZQUFZLENBQUMsRUFBRSxDQUFDLEVBQUU7WUFDOUMsTUFBTSxTQUFTLEdBQUcsMkJBQTJCLENBQUMsS0FBSyxFQUFFLFlBQVksQ0FBQyxJQUFJLENBQUMsQ0FBQztZQUN4RSxNQUFNLGtCQUFrQixHQUFHLFNBQVMsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUM7Z0JBQzdDLHlCQUF5QixDQUNyQixDQUFDLFNBQVMsQ0FBQyxFQUFFLElBQUksQ0FBQyxTQUFTLEVBQUUsY0FBYyxZQUFZLENBQUMsSUFBSSxDQUFDLElBQUksR0FBRyxDQUFDLENBQUMsQ0FBQztnQkFDM0UsSUFBSSxDQUFDO1lBQ1QsSUFBSSxDQUFDLGVBQWUsQ0FBQyxHQUFHLENBQUMsWUFBWSxDQUFDLEVBQUUsRUFBRSxrQkFBa0IsQ0FBQyxDQUFDO1NBQy9EO1FBRUQsT0FBTyxJQUFJLENBQUMsZUFBZSxDQUFDLEdBQUcsQ0FBQyxZQUFZLENBQUMsRUFBRSxDQUFFLENBQUM7SUFDcEQsQ0FBQztJQUVELFdBQVc7UUFDVCxJQUFJO1lBQ0YsS0FBSyxNQUFNLFFBQVEsSUFBSSxJQUFJLENBQUMsZUFBZSxDQUFDLE1BQU0sRUFBRSxFQUFFO2dCQUNwRCxJQUFJLFFBQVEsS0FBSyxJQUFJLEVBQUU7b0JBQ3JCLFFBQVEsQ0FBQyxPQUFPLEVBQUUsQ0FBQztpQkFDcEI7YUFDRjtTQUNGO2dCQUFTO1lBQ1IsSUFBSSxDQUFDLGVBQWUsQ0FBQyxLQUFLLEVBQUUsQ0FBQztTQUM5QjtJQUNILENBQUM7SUFFRCxrQkFBa0I7YUFDWCxVQUFLLEdBQTZCLGdCQUFnQixDQUFDO1FBQ3hELEtBQUssRUFBRSxpQkFBaUI7UUFDeEIsVUFBVSxFQUFFLGFBQWE7UUFDekIsT0FBTyxFQUFFLEdBQUcsRUFBRSxDQUFDLElBQUksaUJBQWlCLENBQUMsTUFBTSxDQUFDLG1CQUFtQixDQUFDLENBQUM7S0FDbEUsQ0FBQyxBQUpVLENBSVQ7O0FBR0w7Ozs7Ozs7OztHQVNHO0FBQ0gsTUFBTSxVQUFVLG1CQUFtQixDQUFDLFVBQWlDO0lBQ25FLFVBQVUsQ0FBQyxxQkFBcUIsR0FBRyxDQUFDLGNBQW1DLEVBQUUsRUFBRTtRQUN6RSxPQUFPLGNBQWMsQ0FBQyxHQUFHLENBQUMsaUJBQWlCLENBQUMsQ0FBQyw2QkFBNkIsQ0FBQyxVQUFVLENBQUMsQ0FBQztJQUN6RixDQUFDLENBQUM7QUFDSixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5pbXBvcnQge8m1ybVpbmplY3QgYXMgaW5qZWN0fSBmcm9tICcuLi8uLi9kaS9pbmplY3Rvcl9jb21wYXRpYmlsaXR5JztcbmltcG9ydCB7ybXJtWRlZmluZUluamVjdGFibGUgYXMgZGVmaW5lSW5qZWN0YWJsZX0gZnJvbSAnLi4vLi4vZGkvaW50ZXJmYWNlL2RlZnMnO1xuaW1wb3J0IHtpbnRlcm5hbEltcG9ydFByb3ZpZGVyc0Zyb219IGZyb20gJy4uLy4uL2RpL3Byb3ZpZGVyX2NvbGxlY3Rpb24nO1xuaW1wb3J0IHtFbnZpcm9ubWVudEluamVjdG9yfSBmcm9tICcuLi8uLi9kaS9yM19pbmplY3Rvcic7XG5pbXBvcnQge09uRGVzdHJveX0gZnJvbSAnLi4vLi4vaW50ZXJmYWNlL2xpZmVjeWNsZV9ob29rcyc7XG5pbXBvcnQge0NvbXBvbmVudERlZn0gZnJvbSAnLi4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7Y3JlYXRlRW52aXJvbm1lbnRJbmplY3Rvcn0gZnJvbSAnLi4vbmdfbW9kdWxlX3JlZic7XG5cbi8qKlxuICogQSBzZXJ2aWNlIHVzZWQgYnkgdGhlIGZyYW1ld29yayB0byBjcmVhdGUgaW5zdGFuY2VzIG9mIHN0YW5kYWxvbmUgaW5qZWN0b3JzLiBUaG9zZSBpbmplY3RvcnMgYXJlXG4gKiBjcmVhdGVkIG9uIGRlbWFuZCBpbiBjYXNlIG9mIGR5bmFtaWMgY29tcG9uZW50IGluc3RhbnRpYXRpb24gYW5kIGNvbnRhaW4gYW1iaWVudCBwcm92aWRlcnNcbiAqIGNvbGxlY3RlZCBmcm9tIHRoZSBpbXBvcnRzIGdyYXBoIHJvb3RlZCBhdCBhIGdpdmVuIHN0YW5kYWxvbmUgY29tcG9uZW50LlxuICovXG5jbGFzcyBTdGFuZGFsb25lU2VydmljZSBpbXBsZW1lbnRzIE9uRGVzdHJveSB7XG4gIGNhY2hlZEluamVjdG9ycyA9IG5ldyBNYXA8c3RyaW5nLCBFbnZpcm9ubWVudEluamVjdG9yfG51bGw+KCk7XG5cbiAgY29uc3RydWN0b3IocHJpdmF0ZSBfaW5qZWN0b3I6IEVudmlyb25tZW50SW5qZWN0b3IpIHt9XG5cbiAgZ2V0T3JDcmVhdGVTdGFuZGFsb25lSW5qZWN0b3IoY29tcG9uZW50RGVmOiBDb21wb25lbnREZWY8dW5rbm93bj4pOiBFbnZpcm9ubWVudEluamVjdG9yfG51bGwge1xuICAgIGlmICghY29tcG9uZW50RGVmLnN0YW5kYWxvbmUpIHtcbiAgICAgIHJldHVybiBudWxsO1xuICAgIH1cblxuICAgIGlmICghdGhpcy5jYWNoZWRJbmplY3RvcnMuaGFzKGNvbXBvbmVudERlZi5pZCkpIHtcbiAgICAgIGNvbnN0IHByb3ZpZGVycyA9IGludGVybmFsSW1wb3J0UHJvdmlkZXJzRnJvbShmYWxzZSwgY29tcG9uZW50RGVmLnR5cGUpO1xuICAgICAgY29uc3Qgc3RhbmRhbG9uZUluamVjdG9yID0gcHJvdmlkZXJzLmxlbmd0aCA+IDAgP1xuICAgICAgICAgIGNyZWF0ZUVudmlyb25tZW50SW5qZWN0b3IoXG4gICAgICAgICAgICAgIFtwcm92aWRlcnNdLCB0aGlzLl9pbmplY3RvciwgYFN0YW5kYWxvbmVbJHtjb21wb25lbnREZWYudHlwZS5uYW1lfV1gKSA6XG4gICAgICAgICAgbnVsbDtcbiAgICAgIHRoaXMuY2FjaGVkSW5qZWN0b3JzLnNldChjb21wb25lbnREZWYuaWQsIHN0YW5kYWxvbmVJbmplY3Rvcik7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXMuY2FjaGVkSW5qZWN0b3JzLmdldChjb21wb25lbnREZWYuaWQpITtcbiAgfVxuXG4gIG5nT25EZXN0cm95KCkge1xuICAgIHRyeSB7XG4gICAgICBmb3IgKGNvbnN0IGluamVjdG9yIG9mIHRoaXMuY2FjaGVkSW5qZWN0b3JzLnZhbHVlcygpKSB7XG4gICAgICAgIGlmIChpbmplY3RvciAhPT0gbnVsbCkge1xuICAgICAgICAgIGluamVjdG9yLmRlc3Ryb3koKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZmluYWxseSB7XG4gICAgICB0aGlzLmNhY2hlZEluamVjdG9ycy5jbGVhcigpO1xuICAgIH1cbiAgfVxuXG4gIC8qKiBAbm9jb2xsYXBzZSAqL1xuICBzdGF0aWMgybVwcm92ID0gLyoqIEBwdXJlT3JCcmVha015Q29kZSAqLyBkZWZpbmVJbmplY3RhYmxlKHtcbiAgICB0b2tlbjogU3RhbmRhbG9uZVNlcnZpY2UsXG4gICAgcHJvdmlkZWRJbjogJ2Vudmlyb25tZW50JyxcbiAgICBmYWN0b3J5OiAoKSA9PiBuZXcgU3RhbmRhbG9uZVNlcnZpY2UoaW5qZWN0KEVudmlyb25tZW50SW5qZWN0b3IpKSxcbiAgfSk7XG59XG5cbi8qKlxuICogQSBmZWF0dXJlIHRoYXQgYWN0cyBhcyBhIHNldHVwIGNvZGUgZm9yIHRoZSB7QGxpbmsgU3RhbmRhbG9uZVNlcnZpY2V9LlxuICpcbiAqIFRoZSBtb3N0IGltcG9ydGFudCByZXNwb25zaWJpbGl0eSBvZiB0aGlzIGZlYXR1cmUgaXMgdG8gZXhwb3NlIHRoZSBcImdldFN0YW5kYWxvbmVJbmplY3RvclwiXG4gKiBmdW5jdGlvbiAoYW4gZW50cnkgcG9pbnRzIHRvIGEgc3RhbmRhbG9uZSBpbmplY3RvciBjcmVhdGlvbikgb24gYSBjb21wb25lbnQgZGVmaW5pdGlvbiBvYmplY3QuIFdlXG4gKiBnbyB0aHJvdWdoIHRoZSBmZWF0dXJlcyBpbmZyYXN0cnVjdHVyZSB0byBtYWtlIHN1cmUgdGhhdCB0aGUgc3RhbmRhbG9uZSBpbmplY3RvciBjcmVhdGlvbiBsb2dpY1xuICogaXMgdHJlZS1zaGFrYWJsZSBhbmQgbm90IGluY2x1ZGVkIGluIGFwcGxpY2F0aW9ucyB0aGF0IGRvbid0IHVzZSBzdGFuZGFsb25lIGNvbXBvbmVudHMuXG4gKlxuICogQGNvZGVHZW5BcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIMm1ybVTdGFuZGFsb25lRmVhdHVyZShkZWZpbml0aW9uOiBDb21wb25lbnREZWY8dW5rbm93bj4pIHtcbiAgZGVmaW5pdGlvbi5nZXRTdGFuZGFsb25lSW5qZWN0b3IgPSAocGFyZW50SW5qZWN0b3I6IEVudmlyb25tZW50SW5qZWN0b3IpID0+IHtcbiAgICByZXR1cm4gcGFyZW50SW5qZWN0b3IuZ2V0KFN0YW5kYWxvbmVTZXJ2aWNlKS5nZXRPckNyZWF0ZVN0YW5kYWxvbmVJbmplY3RvcihkZWZpbml0aW9uKTtcbiAgfTtcbn1cbiJdfQ==