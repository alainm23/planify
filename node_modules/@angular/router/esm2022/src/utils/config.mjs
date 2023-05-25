/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { createEnvironmentInjector, isStandalone, ɵisNgModule as isNgModule, ɵRuntimeError as RuntimeError } from '@angular/core';
import { EmptyOutletComponent } from '../components/empty_outlet';
import { PRIMARY_OUTLET } from '../shared';
/**
 * Creates an `EnvironmentInjector` if the `Route` has providers and one does not already exist
 * and returns the injector. Otherwise, if the `Route` does not have `providers`, returns the
 * `currentInjector`.
 *
 * @param route The route that might have providers
 * @param currentInjector The parent injector of the `Route`
 */
export function getOrCreateRouteInjectorIfNeeded(route, currentInjector) {
    if (route.providers && !route._injector) {
        route._injector =
            createEnvironmentInjector(route.providers, currentInjector, `Route: ${route.path}`);
    }
    return route._injector ?? currentInjector;
}
export function getLoadedRoutes(route) {
    return route._loadedRoutes;
}
export function getLoadedInjector(route) {
    return route._loadedInjector;
}
export function getLoadedComponent(route) {
    return route._loadedComponent;
}
export function getProvidersInjector(route) {
    return route._injector;
}
export function validateConfig(config, parentPath = '', requireStandaloneComponents = false) {
    // forEach doesn't iterate undefined values
    for (let i = 0; i < config.length; i++) {
        const route = config[i];
        const fullPath = getFullPath(parentPath, route);
        validateNode(route, fullPath, requireStandaloneComponents);
    }
}
export function assertStandalone(fullPath, component) {
    if (component && isNgModule(component)) {
        throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}'. You are using 'loadComponent' with a module, ` +
            `but it must be used with standalone components. Use 'loadChildren' instead.`);
    }
    else if (component && !isStandalone(component)) {
        throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}'. The component must be standalone.`);
    }
}
function validateNode(route, fullPath, requireStandaloneComponents) {
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        if (!route) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `
      Invalid configuration of route '${fullPath}': Encountered undefined route.
      The reason might be an extra comma.

      Example:
      const routes: Routes = [
        { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
        { path: 'dashboard',  component: DashboardComponent },, << two commas
        { path: 'detail/:id', component: HeroDetailComponent }
      ];
    `);
        }
        if (Array.isArray(route)) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': Array cannot be specified`);
        }
        if (!route.redirectTo && !route.component && !route.loadComponent && !route.children &&
            !route.loadChildren && (route.outlet && route.outlet !== PRIMARY_OUTLET)) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': a componentless route without children or loadChildren cannot have a named outlet set`);
        }
        if (route.redirectTo && route.children) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': redirectTo and children cannot be used together`);
        }
        if (route.redirectTo && route.loadChildren) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': redirectTo and loadChildren cannot be used together`);
        }
        if (route.children && route.loadChildren) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': children and loadChildren cannot be used together`);
        }
        if (route.redirectTo && (route.component || route.loadComponent)) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': redirectTo and component/loadComponent cannot be used together`);
        }
        if (route.component && route.loadComponent) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': component and loadComponent cannot be used together`);
        }
        if (route.redirectTo && route.canActivate) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': redirectTo and canActivate cannot be used together. Redirects happen before activation ` +
                `so canActivate will never be executed.`);
        }
        if (route.path && route.matcher) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': path and matcher cannot be used together`);
        }
        if (route.redirectTo === void 0 && !route.component && !route.loadComponent &&
            !route.children && !route.loadChildren) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}'. One of the following must be provided: component, loadComponent, redirectTo, children or loadChildren`);
        }
        if (route.path === void 0 && route.matcher === void 0) {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': routes must have either a path or a matcher specified`);
        }
        if (typeof route.path === 'string' && route.path.charAt(0) === '/') {
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '${fullPath}': path cannot start with a slash`);
        }
        if (route.path === '' && route.redirectTo !== void 0 && route.pathMatch === void 0) {
            const exp = `The default value of 'pathMatch' is 'prefix', but often the intent is to use 'full'.`;
            throw new RuntimeError(4014 /* RuntimeErrorCode.INVALID_ROUTE_CONFIG */, `Invalid configuration of route '{path: "${fullPath}", redirectTo: "${route.redirectTo}"}': please provide 'pathMatch'. ${exp}`);
        }
        if (requireStandaloneComponents) {
            assertStandalone(fullPath, route.component);
        }
    }
    if (route.children) {
        validateConfig(route.children, fullPath, requireStandaloneComponents);
    }
}
function getFullPath(parentPath, currentRoute) {
    if (!currentRoute) {
        return parentPath;
    }
    if (!parentPath && !currentRoute.path) {
        return '';
    }
    else if (parentPath && !currentRoute.path) {
        return `${parentPath}/`;
    }
    else if (!parentPath && currentRoute.path) {
        return currentRoute.path;
    }
    else {
        return `${parentPath}/${currentRoute.path}`;
    }
}
/**
 * Makes a copy of the config and adds any default required properties.
 */
export function standardizeConfig(r) {
    const children = r.children && r.children.map(standardizeConfig);
    const c = children ? { ...r, children } : { ...r };
    if ((!c.component && !c.loadComponent) && (children || c.loadChildren) &&
        (c.outlet && c.outlet !== PRIMARY_OUTLET)) {
        c.component = EmptyOutletComponent;
    }
    return c;
}
/** Returns the `route.outlet` or PRIMARY_OUTLET if none exists. */
export function getOutlet(route) {
    return route.outlet || PRIMARY_OUTLET;
}
/**
 * Sorts the `routes` such that the ones with an outlet matching `outletName` come first.
 * The order of the configs is otherwise preserved.
 */
export function sortByMatchingOutlets(routes, outletName) {
    const sortedConfig = routes.filter(r => getOutlet(r) === outletName);
    sortedConfig.push(...routes.filter(r => getOutlet(r) !== outletName));
    return sortedConfig;
}
/**
 * Gets the first injector in the snapshot's parent tree.
 *
 * If the `Route` has a static list of providers, the returned injector will be the one created from
 * those. If it does not exist, the returned injector may come from the parents, which may be from a
 * loaded config or their static providers.
 *
 * Returns `null` if there is neither this nor any parents have a stored injector.
 *
 * Generally used for retrieving the injector to use for getting tokens for guards/resolvers and
 * also used for getting the correct injector to use for creating components.
 */
export function getClosestRouteInjector(snapshot) {
    if (!snapshot)
        return null;
    // If the current route has its own injector, which is created from the static providers on the
    // route itself, we should use that. Otherwise, we start at the parent since we do not want to
    // include the lazy loaded injector from this route.
    if (snapshot.routeConfig?._injector) {
        return snapshot.routeConfig._injector;
    }
    for (let s = snapshot.parent; s; s = s.parent) {
        const route = s.routeConfig;
        // Note that the order here is important. `_loadedInjector` stored on the route with
        // `loadChildren: () => NgModule` so it applies to child routes with priority. The `_injector`
        // is created from the static providers on that parent route, so it applies to the children as
        // well, but only if there is no lazy loaded NgModuleRef injector.
        if (route?._loadedInjector)
            return route._loadedInjector;
        if (route?._injector)
            return route._injector;
    }
    return null;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29uZmlnLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvcm91dGVyL3NyYy91dGlscy9jb25maWcudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLHlCQUF5QixFQUF1QixZQUFZLEVBQVEsV0FBVyxJQUFJLFVBQVUsRUFBRSxhQUFhLElBQUksWUFBWSxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBRTNKLE9BQU8sRUFBQyxvQkFBb0IsRUFBQyxNQUFNLDRCQUE0QixDQUFDO0FBSWhFLE9BQU8sRUFBQyxjQUFjLEVBQUMsTUFBTSxXQUFXLENBQUM7QUFFekM7Ozs7Ozs7R0FPRztBQUNILE1BQU0sVUFBVSxnQ0FBZ0MsQ0FDNUMsS0FBWSxFQUFFLGVBQW9DO0lBQ3BELElBQUksS0FBSyxDQUFDLFNBQVMsSUFBSSxDQUFDLEtBQUssQ0FBQyxTQUFTLEVBQUU7UUFDdkMsS0FBSyxDQUFDLFNBQVM7WUFDWCx5QkFBeUIsQ0FBQyxLQUFLLENBQUMsU0FBUyxFQUFFLGVBQWUsRUFBRSxVQUFVLEtBQUssQ0FBQyxJQUFJLEVBQUUsQ0FBQyxDQUFDO0tBQ3pGO0lBQ0QsT0FBTyxLQUFLLENBQUMsU0FBUyxJQUFJLGVBQWUsQ0FBQztBQUM1QyxDQUFDO0FBRUQsTUFBTSxVQUFVLGVBQWUsQ0FBQyxLQUFZO0lBQzFDLE9BQU8sS0FBSyxDQUFDLGFBQWEsQ0FBQztBQUM3QixDQUFDO0FBRUQsTUFBTSxVQUFVLGlCQUFpQixDQUFDLEtBQVk7SUFDNUMsT0FBTyxLQUFLLENBQUMsZUFBZSxDQUFDO0FBQy9CLENBQUM7QUFDRCxNQUFNLFVBQVUsa0JBQWtCLENBQUMsS0FBWTtJQUM3QyxPQUFPLEtBQUssQ0FBQyxnQkFBZ0IsQ0FBQztBQUNoQyxDQUFDO0FBRUQsTUFBTSxVQUFVLG9CQUFvQixDQUFDLEtBQVk7SUFDL0MsT0FBTyxLQUFLLENBQUMsU0FBUyxDQUFDO0FBQ3pCLENBQUM7QUFFRCxNQUFNLFVBQVUsY0FBYyxDQUMxQixNQUFjLEVBQUUsYUFBcUIsRUFBRSxFQUFFLDJCQUEyQixHQUFHLEtBQUs7SUFDOUUsMkNBQTJDO0lBQzNDLEtBQUssSUFBSSxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxNQUFNLENBQUMsTUFBTSxFQUFFLENBQUMsRUFBRSxFQUFFO1FBQ3RDLE1BQU0sS0FBSyxHQUFVLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQztRQUMvQixNQUFNLFFBQVEsR0FBVyxXQUFXLENBQUMsVUFBVSxFQUFFLEtBQUssQ0FBQyxDQUFDO1FBQ3hELFlBQVksQ0FBQyxLQUFLLEVBQUUsUUFBUSxFQUFFLDJCQUEyQixDQUFDLENBQUM7S0FDNUQ7QUFDSCxDQUFDO0FBRUQsTUFBTSxVQUFVLGdCQUFnQixDQUFDLFFBQWdCLEVBQUUsU0FBa0M7SUFDbkYsSUFBSSxTQUFTLElBQUksVUFBVSxDQUFDLFNBQVMsQ0FBQyxFQUFFO1FBQ3RDLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FDSSxRQUFRLGtEQUFrRDtZQUMxRCw2RUFBNkUsQ0FBQyxDQUFDO0tBQ3hGO1NBQU0sSUFBSSxTQUFTLElBQUksQ0FBQyxZQUFZLENBQUMsU0FBUyxDQUFDLEVBQUU7UUFDaEQsTUFBTSxJQUFJLFlBQVksbURBRWxCLG1DQUFtQyxRQUFRLHNDQUFzQyxDQUFDLENBQUM7S0FDeEY7QUFDSCxDQUFDO0FBRUQsU0FBUyxZQUFZLENBQUMsS0FBWSxFQUFFLFFBQWdCLEVBQUUsMkJBQW9DO0lBQ3hGLElBQUksT0FBTyxTQUFTLEtBQUssV0FBVyxJQUFJLFNBQVMsRUFBRTtRQUNqRCxJQUFJLENBQUMsS0FBSyxFQUFFO1lBQ1YsTUFBTSxJQUFJLFlBQVksbURBQXdDO3dDQUM1QixRQUFROzs7Ozs7Ozs7S0FTM0MsQ0FBQyxDQUFDO1NBQ0Y7UUFDRCxJQUFJLEtBQUssQ0FBQyxPQUFPLENBQUMsS0FBSyxDQUFDLEVBQUU7WUFDeEIsTUFBTSxJQUFJLFlBQVksbURBRWxCLG1DQUFtQyxRQUFRLDhCQUE4QixDQUFDLENBQUM7U0FDaEY7UUFDRCxJQUFJLENBQUMsS0FBSyxDQUFDLFVBQVUsSUFBSSxDQUFDLEtBQUssQ0FBQyxTQUFTLElBQUksQ0FBQyxLQUFLLENBQUMsYUFBYSxJQUFJLENBQUMsS0FBSyxDQUFDLFFBQVE7WUFDaEYsQ0FBQyxLQUFLLENBQUMsWUFBWSxJQUFJLENBQUMsS0FBSyxDQUFDLE1BQU0sSUFBSSxLQUFLLENBQUMsTUFBTSxLQUFLLGNBQWMsQ0FBQyxFQUFFO1lBQzVFLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FDSSxRQUFRLDBGQUEwRixDQUFDLENBQUM7U0FDN0c7UUFDRCxJQUFJLEtBQUssQ0FBQyxVQUFVLElBQUksS0FBSyxDQUFDLFFBQVEsRUFBRTtZQUN0QyxNQUFNLElBQUksWUFBWSxtREFFbEIsbUNBQ0ksUUFBUSxvREFBb0QsQ0FBQyxDQUFDO1NBQ3ZFO1FBQ0QsSUFBSSxLQUFLLENBQUMsVUFBVSxJQUFJLEtBQUssQ0FBQyxZQUFZLEVBQUU7WUFDMUMsTUFBTSxJQUFJLFlBQVksbURBRWxCLG1DQUNJLFFBQVEsd0RBQXdELENBQUMsQ0FBQztTQUMzRTtRQUNELElBQUksS0FBSyxDQUFDLFFBQVEsSUFBSSxLQUFLLENBQUMsWUFBWSxFQUFFO1lBQ3hDLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FDSSxRQUFRLHNEQUFzRCxDQUFDLENBQUM7U0FDekU7UUFDRCxJQUFJLEtBQUssQ0FBQyxVQUFVLElBQUksQ0FBQyxLQUFLLENBQUMsU0FBUyxJQUFJLEtBQUssQ0FBQyxhQUFhLENBQUMsRUFBRTtZQUNoRSxNQUFNLElBQUksWUFBWSxtREFFbEIsbUNBQ0ksUUFBUSxtRUFBbUUsQ0FBQyxDQUFDO1NBQ3RGO1FBQ0QsSUFBSSxLQUFLLENBQUMsU0FBUyxJQUFJLEtBQUssQ0FBQyxhQUFhLEVBQUU7WUFDMUMsTUFBTSxJQUFJLFlBQVksbURBRWxCLG1DQUNJLFFBQVEsd0RBQXdELENBQUMsQ0FBQztTQUMzRTtRQUNELElBQUksS0FBSyxDQUFDLFVBQVUsSUFBSSxLQUFLLENBQUMsV0FBVyxFQUFFO1lBQ3pDLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FDSSxRQUFRLDRGQUE0RjtnQkFDcEcsd0NBQXdDLENBQUMsQ0FBQztTQUNuRDtRQUNELElBQUksS0FBSyxDQUFDLElBQUksSUFBSSxLQUFLLENBQUMsT0FBTyxFQUFFO1lBQy9CLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FBbUMsUUFBUSw2Q0FBNkMsQ0FBQyxDQUFDO1NBQy9GO1FBQ0QsSUFBSSxLQUFLLENBQUMsVUFBVSxLQUFLLEtBQUssQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLFNBQVMsSUFBSSxDQUFDLEtBQUssQ0FBQyxhQUFhO1lBQ3ZFLENBQUMsS0FBSyxDQUFDLFFBQVEsSUFBSSxDQUFDLEtBQUssQ0FBQyxZQUFZLEVBQUU7WUFDMUMsTUFBTSxJQUFJLFlBQVksbURBRWxCLG1DQUNJLFFBQVEsMEdBQTBHLENBQUMsQ0FBQztTQUM3SDtRQUNELElBQUksS0FBSyxDQUFDLElBQUksS0FBSyxLQUFLLENBQUMsSUFBSSxLQUFLLENBQUMsT0FBTyxLQUFLLEtBQUssQ0FBQyxFQUFFO1lBQ3JELE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FDSSxRQUFRLDBEQUEwRCxDQUFDLENBQUM7U0FDN0U7UUFDRCxJQUFJLE9BQU8sS0FBSyxDQUFDLElBQUksS0FBSyxRQUFRLElBQUksS0FBSyxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLEtBQUssR0FBRyxFQUFFO1lBQ2xFLE1BQU0sSUFBSSxZQUFZLG1EQUVsQixtQ0FBbUMsUUFBUSxtQ0FBbUMsQ0FBQyxDQUFDO1NBQ3JGO1FBQ0QsSUFBSSxLQUFLLENBQUMsSUFBSSxLQUFLLEVBQUUsSUFBSSxLQUFLLENBQUMsVUFBVSxLQUFLLEtBQUssQ0FBQyxJQUFJLEtBQUssQ0FBQyxTQUFTLEtBQUssS0FBSyxDQUFDLEVBQUU7WUFDbEYsTUFBTSxHQUFHLEdBQ0wsc0ZBQXNGLENBQUM7WUFDM0YsTUFBTSxJQUFJLFlBQVksbURBRWxCLDJDQUEyQyxRQUFRLG1CQUMvQyxLQUFLLENBQUMsVUFBVSxvQ0FBb0MsR0FBRyxFQUFFLENBQUMsQ0FBQztTQUNwRTtRQUNELElBQUksMkJBQTJCLEVBQUU7WUFDL0IsZ0JBQWdCLENBQUMsUUFBUSxFQUFFLEtBQUssQ0FBQyxTQUFTLENBQUMsQ0FBQztTQUM3QztLQUNGO0lBQ0QsSUFBSSxLQUFLLENBQUMsUUFBUSxFQUFFO1FBQ2xCLGNBQWMsQ0FBQyxLQUFLLENBQUMsUUFBUSxFQUFFLFFBQVEsRUFBRSwyQkFBMkIsQ0FBQyxDQUFDO0tBQ3ZFO0FBQ0gsQ0FBQztBQUVELFNBQVMsV0FBVyxDQUFDLFVBQWtCLEVBQUUsWUFBbUI7SUFDMUQsSUFBSSxDQUFDLFlBQVksRUFBRTtRQUNqQixPQUFPLFVBQVUsQ0FBQztLQUNuQjtJQUNELElBQUksQ0FBQyxVQUFVLElBQUksQ0FBQyxZQUFZLENBQUMsSUFBSSxFQUFFO1FBQ3JDLE9BQU8sRUFBRSxDQUFDO0tBQ1g7U0FBTSxJQUFJLFVBQVUsSUFBSSxDQUFDLFlBQVksQ0FBQyxJQUFJLEVBQUU7UUFDM0MsT0FBTyxHQUFHLFVBQVUsR0FBRyxDQUFDO0tBQ3pCO1NBQU0sSUFBSSxDQUFDLFVBQVUsSUFBSSxZQUFZLENBQUMsSUFBSSxFQUFFO1FBQzNDLE9BQU8sWUFBWSxDQUFDLElBQUksQ0FBQztLQUMxQjtTQUFNO1FBQ0wsT0FBTyxHQUFHLFVBQVUsSUFBSSxZQUFZLENBQUMsSUFBSSxFQUFFLENBQUM7S0FDN0M7QUFDSCxDQUFDO0FBRUQ7O0dBRUc7QUFDSCxNQUFNLFVBQVUsaUJBQWlCLENBQUMsQ0FBUTtJQUN4QyxNQUFNLFFBQVEsR0FBRyxDQUFDLENBQUMsUUFBUSxJQUFJLENBQUMsQ0FBQyxRQUFRLENBQUMsR0FBRyxDQUFDLGlCQUFpQixDQUFDLENBQUM7SUFDakUsTUFBTSxDQUFDLEdBQUcsUUFBUSxDQUFDLENBQUMsQ0FBQyxFQUFDLEdBQUcsQ0FBQyxFQUFFLFFBQVEsRUFBQyxDQUFDLENBQUMsQ0FBQyxFQUFDLEdBQUcsQ0FBQyxFQUFDLENBQUM7SUFDL0MsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsSUFBSSxDQUFDLENBQUMsQ0FBQyxhQUFhLENBQUMsSUFBSSxDQUFDLFFBQVEsSUFBSSxDQUFDLENBQUMsWUFBWSxDQUFDO1FBQ2xFLENBQUMsQ0FBQyxDQUFDLE1BQU0sSUFBSSxDQUFDLENBQUMsTUFBTSxLQUFLLGNBQWMsQ0FBQyxFQUFFO1FBQzdDLENBQUMsQ0FBQyxTQUFTLEdBQUcsb0JBQW9CLENBQUM7S0FDcEM7SUFDRCxPQUFPLENBQUMsQ0FBQztBQUNYLENBQUM7QUFFRCxtRUFBbUU7QUFDbkUsTUFBTSxVQUFVLFNBQVMsQ0FBQyxLQUFZO0lBQ3BDLE9BQU8sS0FBSyxDQUFDLE1BQU0sSUFBSSxjQUFjLENBQUM7QUFDeEMsQ0FBQztBQUVEOzs7R0FHRztBQUNILE1BQU0sVUFBVSxxQkFBcUIsQ0FBQyxNQUFjLEVBQUUsVUFBa0I7SUFDdEUsTUFBTSxZQUFZLEdBQUcsTUFBTSxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsS0FBSyxVQUFVLENBQUMsQ0FBQztJQUNyRSxZQUFZLENBQUMsSUFBSSxDQUFDLEdBQUcsTUFBTSxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsS0FBSyxVQUFVLENBQUMsQ0FBQyxDQUFDO0lBQ3RFLE9BQU8sWUFBWSxDQUFDO0FBQ3RCLENBQUM7QUFFRDs7Ozs7Ozs7Ozs7R0FXRztBQUNILE1BQU0sVUFBVSx1QkFBdUIsQ0FBQyxRQUFnQztJQUV0RSxJQUFJLENBQUMsUUFBUTtRQUFFLE9BQU8sSUFBSSxDQUFDO0lBRTNCLCtGQUErRjtJQUMvRiw4RkFBOEY7SUFDOUYsb0RBQW9EO0lBQ3BELElBQUksUUFBUSxDQUFDLFdBQVcsRUFBRSxTQUFTLEVBQUU7UUFDbkMsT0FBTyxRQUFRLENBQUMsV0FBVyxDQUFDLFNBQVMsQ0FBQztLQUN2QztJQUVELEtBQUssSUFBSSxDQUFDLEdBQUcsUUFBUSxDQUFDLE1BQU0sRUFBRSxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLEVBQUU7UUFDN0MsTUFBTSxLQUFLLEdBQUcsQ0FBQyxDQUFDLFdBQVcsQ0FBQztRQUM1QixvRkFBb0Y7UUFDcEYsOEZBQThGO1FBQzlGLDhGQUE4RjtRQUM5RixrRUFBa0U7UUFDbEUsSUFBSSxLQUFLLEVBQUUsZUFBZTtZQUFFLE9BQU8sS0FBSyxDQUFDLGVBQWUsQ0FBQztRQUN6RCxJQUFJLEtBQUssRUFBRSxTQUFTO1lBQUUsT0FBTyxLQUFLLENBQUMsU0FBUyxDQUFDO0tBQzlDO0lBRUQsT0FBTyxJQUFJLENBQUM7QUFDZCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Y3JlYXRlRW52aXJvbm1lbnRJbmplY3RvciwgRW52aXJvbm1lbnRJbmplY3RvciwgaXNTdGFuZGFsb25lLCBUeXBlLCDJtWlzTmdNb2R1bGUgYXMgaXNOZ01vZHVsZSwgybVSdW50aW1lRXJyb3IgYXMgUnVudGltZUVycm9yfSBmcm9tICdAYW5ndWxhci9jb3JlJztcblxuaW1wb3J0IHtFbXB0eU91dGxldENvbXBvbmVudH0gZnJvbSAnLi4vY29tcG9uZW50cy9lbXB0eV9vdXRsZXQnO1xuaW1wb3J0IHtSdW50aW1lRXJyb3JDb2RlfSBmcm9tICcuLi9lcnJvcnMnO1xuaW1wb3J0IHtSb3V0ZSwgUm91dGVzfSBmcm9tICcuLi9tb2RlbHMnO1xuaW1wb3J0IHtBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90fSBmcm9tICcuLi9yb3V0ZXJfc3RhdGUnO1xuaW1wb3J0IHtQUklNQVJZX09VVExFVH0gZnJvbSAnLi4vc2hhcmVkJztcblxuLyoqXG4gKiBDcmVhdGVzIGFuIGBFbnZpcm9ubWVudEluamVjdG9yYCBpZiB0aGUgYFJvdXRlYCBoYXMgcHJvdmlkZXJzIGFuZCBvbmUgZG9lcyBub3QgYWxyZWFkeSBleGlzdFxuICogYW5kIHJldHVybnMgdGhlIGluamVjdG9yLiBPdGhlcndpc2UsIGlmIHRoZSBgUm91dGVgIGRvZXMgbm90IGhhdmUgYHByb3ZpZGVyc2AsIHJldHVybnMgdGhlXG4gKiBgY3VycmVudEluamVjdG9yYC5cbiAqXG4gKiBAcGFyYW0gcm91dGUgVGhlIHJvdXRlIHRoYXQgbWlnaHQgaGF2ZSBwcm92aWRlcnNcbiAqIEBwYXJhbSBjdXJyZW50SW5qZWN0b3IgVGhlIHBhcmVudCBpbmplY3RvciBvZiB0aGUgYFJvdXRlYFxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVSb3V0ZUluamVjdG9ySWZOZWVkZWQoXG4gICAgcm91dGU6IFJvdXRlLCBjdXJyZW50SW5qZWN0b3I6IEVudmlyb25tZW50SW5qZWN0b3IpIHtcbiAgaWYgKHJvdXRlLnByb3ZpZGVycyAmJiAhcm91dGUuX2luamVjdG9yKSB7XG4gICAgcm91dGUuX2luamVjdG9yID1cbiAgICAgICAgY3JlYXRlRW52aXJvbm1lbnRJbmplY3Rvcihyb3V0ZS5wcm92aWRlcnMsIGN1cnJlbnRJbmplY3RvciwgYFJvdXRlOiAke3JvdXRlLnBhdGh9YCk7XG4gIH1cbiAgcmV0dXJuIHJvdXRlLl9pbmplY3RvciA/PyBjdXJyZW50SW5qZWN0b3I7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRMb2FkZWRSb3V0ZXMocm91dGU6IFJvdXRlKTogUm91dGVbXXx1bmRlZmluZWQge1xuICByZXR1cm4gcm91dGUuX2xvYWRlZFJvdXRlcztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldExvYWRlZEluamVjdG9yKHJvdXRlOiBSb3V0ZSk6IEVudmlyb25tZW50SW5qZWN0b3J8dW5kZWZpbmVkIHtcbiAgcmV0dXJuIHJvdXRlLl9sb2FkZWRJbmplY3Rvcjtcbn1cbmV4cG9ydCBmdW5jdGlvbiBnZXRMb2FkZWRDb21wb25lbnQocm91dGU6IFJvdXRlKTogVHlwZTx1bmtub3duPnx1bmRlZmluZWQge1xuICByZXR1cm4gcm91dGUuX2xvYWRlZENvbXBvbmVudDtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldFByb3ZpZGVyc0luamVjdG9yKHJvdXRlOiBSb3V0ZSk6IEVudmlyb25tZW50SW5qZWN0b3J8dW5kZWZpbmVkIHtcbiAgcmV0dXJuIHJvdXRlLl9pbmplY3Rvcjtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHZhbGlkYXRlQ29uZmlnKFxuICAgIGNvbmZpZzogUm91dGVzLCBwYXJlbnRQYXRoOiBzdHJpbmcgPSAnJywgcmVxdWlyZVN0YW5kYWxvbmVDb21wb25lbnRzID0gZmFsc2UpOiB2b2lkIHtcbiAgLy8gZm9yRWFjaCBkb2Vzbid0IGl0ZXJhdGUgdW5kZWZpbmVkIHZhbHVlc1xuICBmb3IgKGxldCBpID0gMDsgaSA8IGNvbmZpZy5sZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IHJvdXRlOiBSb3V0ZSA9IGNvbmZpZ1tpXTtcbiAgICBjb25zdCBmdWxsUGF0aDogc3RyaW5nID0gZ2V0RnVsbFBhdGgocGFyZW50UGF0aCwgcm91dGUpO1xuICAgIHZhbGlkYXRlTm9kZShyb3V0ZSwgZnVsbFBhdGgsIHJlcXVpcmVTdGFuZGFsb25lQ29tcG9uZW50cyk7XG4gIH1cbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGFzc2VydFN0YW5kYWxvbmUoZnVsbFBhdGg6IHN0cmluZywgY29tcG9uZW50OiBUeXBlPHVua25vd24+fHVuZGVmaW5lZCkge1xuICBpZiAoY29tcG9uZW50ICYmIGlzTmdNb2R1bGUoY29tcG9uZW50KSkge1xuICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuSU5WQUxJRF9ST1VURV9DT05GSUcsXG4gICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICBmdWxsUGF0aH0nLiBZb3UgYXJlIHVzaW5nICdsb2FkQ29tcG9uZW50JyB3aXRoIGEgbW9kdWxlLCBgICtcbiAgICAgICAgICAgIGBidXQgaXQgbXVzdCBiZSB1c2VkIHdpdGggc3RhbmRhbG9uZSBjb21wb25lbnRzLiBVc2UgJ2xvYWRDaGlsZHJlbicgaW5zdGVhZC5gKTtcbiAgfSBlbHNlIGlmIChjb21wb25lbnQgJiYgIWlzU3RhbmRhbG9uZShjb21wb25lbnQpKSB7XG4gICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRyxcbiAgICAgICAgYEludmFsaWQgY29uZmlndXJhdGlvbiBvZiByb3V0ZSAnJHtmdWxsUGF0aH0nLiBUaGUgY29tcG9uZW50IG11c3QgYmUgc3RhbmRhbG9uZS5gKTtcbiAgfVxufVxuXG5mdW5jdGlvbiB2YWxpZGF0ZU5vZGUocm91dGU6IFJvdXRlLCBmdWxsUGF0aDogc3RyaW5nLCByZXF1aXJlU3RhbmRhbG9uZUNvbXBvbmVudHM6IGJvb2xlYW4pOiB2b2lkIHtcbiAgaWYgKHR5cGVvZiBuZ0Rldk1vZGUgPT09ICd1bmRlZmluZWQnIHx8IG5nRGV2TW9kZSkge1xuICAgIGlmICghcm91dGUpIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRywgYFxuICAgICAgSW52YWxpZCBjb25maWd1cmF0aW9uIG9mIHJvdXRlICcke2Z1bGxQYXRofSc6IEVuY291bnRlcmVkIHVuZGVmaW5lZCByb3V0ZS5cbiAgICAgIFRoZSByZWFzb24gbWlnaHQgYmUgYW4gZXh0cmEgY29tbWEuXG5cbiAgICAgIEV4YW1wbGU6XG4gICAgICBjb25zdCByb3V0ZXM6IFJvdXRlcyA9IFtcbiAgICAgICAgeyBwYXRoOiAnJywgcmVkaXJlY3RUbzogJy9kYXNoYm9hcmQnLCBwYXRoTWF0Y2g6ICdmdWxsJyB9LFxuICAgICAgICB7IHBhdGg6ICdkYXNoYm9hcmQnLCAgY29tcG9uZW50OiBEYXNoYm9hcmRDb21wb25lbnQgfSwsIDw8IHR3byBjb21tYXNcbiAgICAgICAgeyBwYXRoOiAnZGV0YWlsLzppZCcsIGNvbXBvbmVudDogSGVyb0RldGFpbENvbXBvbmVudCB9XG4gICAgICBdO1xuICAgIGApO1xuICAgIH1cbiAgICBpZiAoQXJyYXkuaXNBcnJheShyb3V0ZSkpIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRyxcbiAgICAgICAgICBgSW52YWxpZCBjb25maWd1cmF0aW9uIG9mIHJvdXRlICcke2Z1bGxQYXRofSc6IEFycmF5IGNhbm5vdCBiZSBzcGVjaWZpZWRgKTtcbiAgICB9XG4gICAgaWYgKCFyb3V0ZS5yZWRpcmVjdFRvICYmICFyb3V0ZS5jb21wb25lbnQgJiYgIXJvdXRlLmxvYWRDb21wb25lbnQgJiYgIXJvdXRlLmNoaWxkcmVuICYmXG4gICAgICAgICFyb3V0ZS5sb2FkQ2hpbGRyZW4gJiYgKHJvdXRlLm91dGxldCAmJiByb3V0ZS5vdXRsZXQgIT09IFBSSU1BUllfT1VUTEVUKSkge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IGEgY29tcG9uZW50bGVzcyByb3V0ZSB3aXRob3V0IGNoaWxkcmVuIG9yIGxvYWRDaGlsZHJlbiBjYW5ub3QgaGF2ZSBhIG5hbWVkIG91dGxldCBzZXRgKTtcbiAgICB9XG4gICAgaWYgKHJvdXRlLnJlZGlyZWN0VG8gJiYgcm91dGUuY2hpbGRyZW4pIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRyxcbiAgICAgICAgICBgSW52YWxpZCBjb25maWd1cmF0aW9uIG9mIHJvdXRlICcke1xuICAgICAgICAgICAgICBmdWxsUGF0aH0nOiByZWRpcmVjdFRvIGFuZCBjaGlsZHJlbiBjYW5ub3QgYmUgdXNlZCB0b2dldGhlcmApO1xuICAgIH1cbiAgICBpZiAocm91dGUucmVkaXJlY3RUbyAmJiByb3V0ZS5sb2FkQ2hpbGRyZW4pIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRyxcbiAgICAgICAgICBgSW52YWxpZCBjb25maWd1cmF0aW9uIG9mIHJvdXRlICcke1xuICAgICAgICAgICAgICBmdWxsUGF0aH0nOiByZWRpcmVjdFRvIGFuZCBsb2FkQ2hpbGRyZW4gY2Fubm90IGJlIHVzZWQgdG9nZXRoZXJgKTtcbiAgICB9XG4gICAgaWYgKHJvdXRlLmNoaWxkcmVuICYmIHJvdXRlLmxvYWRDaGlsZHJlbikge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IGNoaWxkcmVuIGFuZCBsb2FkQ2hpbGRyZW4gY2Fubm90IGJlIHVzZWQgdG9nZXRoZXJgKTtcbiAgICB9XG4gICAgaWYgKHJvdXRlLnJlZGlyZWN0VG8gJiYgKHJvdXRlLmNvbXBvbmVudCB8fCByb3V0ZS5sb2FkQ29tcG9uZW50KSkge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IHJlZGlyZWN0VG8gYW5kIGNvbXBvbmVudC9sb2FkQ29tcG9uZW50IGNhbm5vdCBiZSB1c2VkIHRvZ2V0aGVyYCk7XG4gICAgfVxuICAgIGlmIChyb3V0ZS5jb21wb25lbnQgJiYgcm91dGUubG9hZENvbXBvbmVudCkge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IGNvbXBvbmVudCBhbmQgbG9hZENvbXBvbmVudCBjYW5ub3QgYmUgdXNlZCB0b2dldGhlcmApO1xuICAgIH1cbiAgICBpZiAocm91dGUucmVkaXJlY3RUbyAmJiByb3V0ZS5jYW5BY3RpdmF0ZSkge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IHJlZGlyZWN0VG8gYW5kIGNhbkFjdGl2YXRlIGNhbm5vdCBiZSB1c2VkIHRvZ2V0aGVyLiBSZWRpcmVjdHMgaGFwcGVuIGJlZm9yZSBhY3RpdmF0aW9uIGAgK1xuICAgICAgICAgICAgICBgc28gY2FuQWN0aXZhdGUgd2lsbCBuZXZlciBiZSBleGVjdXRlZC5gKTtcbiAgICB9XG4gICAgaWYgKHJvdXRlLnBhdGggJiYgcm91dGUubWF0Y2hlcikge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7ZnVsbFBhdGh9JzogcGF0aCBhbmQgbWF0Y2hlciBjYW5ub3QgYmUgdXNlZCB0b2dldGhlcmApO1xuICAgIH1cbiAgICBpZiAocm91dGUucmVkaXJlY3RUbyA9PT0gdm9pZCAwICYmICFyb3V0ZS5jb21wb25lbnQgJiYgIXJvdXRlLmxvYWRDb21wb25lbnQgJiZcbiAgICAgICAgIXJvdXRlLmNoaWxkcmVuICYmICFyb3V0ZS5sb2FkQ2hpbGRyZW4pIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX1JPVVRFX0NPTkZJRyxcbiAgICAgICAgICBgSW52YWxpZCBjb25maWd1cmF0aW9uIG9mIHJvdXRlICcke1xuICAgICAgICAgICAgICBmdWxsUGF0aH0nLiBPbmUgb2YgdGhlIGZvbGxvd2luZyBtdXN0IGJlIHByb3ZpZGVkOiBjb21wb25lbnQsIGxvYWRDb21wb25lbnQsIHJlZGlyZWN0VG8sIGNoaWxkcmVuIG9yIGxvYWRDaGlsZHJlbmApO1xuICAgIH1cbiAgICBpZiAocm91dGUucGF0aCA9PT0gdm9pZCAwICYmIHJvdXRlLm1hdGNoZXIgPT09IHZvaWQgMCkge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7XG4gICAgICAgICAgICAgIGZ1bGxQYXRofSc6IHJvdXRlcyBtdXN0IGhhdmUgZWl0aGVyIGEgcGF0aCBvciBhIG1hdGNoZXIgc3BlY2lmaWVkYCk7XG4gICAgfVxuICAgIGlmICh0eXBlb2Ygcm91dGUucGF0aCA9PT0gJ3N0cmluZycgJiYgcm91dGUucGF0aC5jaGFyQXQoMCkgPT09ICcvJykge1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfUk9VVEVfQ09ORklHLFxuICAgICAgICAgIGBJbnZhbGlkIGNvbmZpZ3VyYXRpb24gb2Ygcm91dGUgJyR7ZnVsbFBhdGh9JzogcGF0aCBjYW5ub3Qgc3RhcnQgd2l0aCBhIHNsYXNoYCk7XG4gICAgfVxuICAgIGlmIChyb3V0ZS5wYXRoID09PSAnJyAmJiByb3V0ZS5yZWRpcmVjdFRvICE9PSB2b2lkIDAgJiYgcm91dGUucGF0aE1hdGNoID09PSB2b2lkIDApIHtcbiAgICAgIGNvbnN0IGV4cCA9XG4gICAgICAgICAgYFRoZSBkZWZhdWx0IHZhbHVlIG9mICdwYXRoTWF0Y2gnIGlzICdwcmVmaXgnLCBidXQgb2Z0ZW4gdGhlIGludGVudCBpcyB0byB1c2UgJ2Z1bGwnLmA7XG4gICAgICB0aHJvdyBuZXcgUnVudGltZUVycm9yKFxuICAgICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuSU5WQUxJRF9ST1VURV9DT05GSUcsXG4gICAgICAgICAgYEludmFsaWQgY29uZmlndXJhdGlvbiBvZiByb3V0ZSAne3BhdGg6IFwiJHtmdWxsUGF0aH1cIiwgcmVkaXJlY3RUbzogXCIke1xuICAgICAgICAgICAgICByb3V0ZS5yZWRpcmVjdFRvfVwifSc6IHBsZWFzZSBwcm92aWRlICdwYXRoTWF0Y2gnLiAke2V4cH1gKTtcbiAgICB9XG4gICAgaWYgKHJlcXVpcmVTdGFuZGFsb25lQ29tcG9uZW50cykge1xuICAgICAgYXNzZXJ0U3RhbmRhbG9uZShmdWxsUGF0aCwgcm91dGUuY29tcG9uZW50KTtcbiAgICB9XG4gIH1cbiAgaWYgKHJvdXRlLmNoaWxkcmVuKSB7XG4gICAgdmFsaWRhdGVDb25maWcocm91dGUuY2hpbGRyZW4sIGZ1bGxQYXRoLCByZXF1aXJlU3RhbmRhbG9uZUNvbXBvbmVudHMpO1xuICB9XG59XG5cbmZ1bmN0aW9uIGdldEZ1bGxQYXRoKHBhcmVudFBhdGg6IHN0cmluZywgY3VycmVudFJvdXRlOiBSb3V0ZSk6IHN0cmluZyB7XG4gIGlmICghY3VycmVudFJvdXRlKSB7XG4gICAgcmV0dXJuIHBhcmVudFBhdGg7XG4gIH1cbiAgaWYgKCFwYXJlbnRQYXRoICYmICFjdXJyZW50Um91dGUucGF0aCkge1xuICAgIHJldHVybiAnJztcbiAgfSBlbHNlIGlmIChwYXJlbnRQYXRoICYmICFjdXJyZW50Um91dGUucGF0aCkge1xuICAgIHJldHVybiBgJHtwYXJlbnRQYXRofS9gO1xuICB9IGVsc2UgaWYgKCFwYXJlbnRQYXRoICYmIGN1cnJlbnRSb3V0ZS5wYXRoKSB7XG4gICAgcmV0dXJuIGN1cnJlbnRSb3V0ZS5wYXRoO1xuICB9IGVsc2Uge1xuICAgIHJldHVybiBgJHtwYXJlbnRQYXRofS8ke2N1cnJlbnRSb3V0ZS5wYXRofWA7XG4gIH1cbn1cblxuLyoqXG4gKiBNYWtlcyBhIGNvcHkgb2YgdGhlIGNvbmZpZyBhbmQgYWRkcyBhbnkgZGVmYXVsdCByZXF1aXJlZCBwcm9wZXJ0aWVzLlxuICovXG5leHBvcnQgZnVuY3Rpb24gc3RhbmRhcmRpemVDb25maWcocjogUm91dGUpOiBSb3V0ZSB7XG4gIGNvbnN0IGNoaWxkcmVuID0gci5jaGlsZHJlbiAmJiByLmNoaWxkcmVuLm1hcChzdGFuZGFyZGl6ZUNvbmZpZyk7XG4gIGNvbnN0IGMgPSBjaGlsZHJlbiA/IHsuLi5yLCBjaGlsZHJlbn0gOiB7Li4ucn07XG4gIGlmICgoIWMuY29tcG9uZW50ICYmICFjLmxvYWRDb21wb25lbnQpICYmIChjaGlsZHJlbiB8fCBjLmxvYWRDaGlsZHJlbikgJiZcbiAgICAgIChjLm91dGxldCAmJiBjLm91dGxldCAhPT0gUFJJTUFSWV9PVVRMRVQpKSB7XG4gICAgYy5jb21wb25lbnQgPSBFbXB0eU91dGxldENvbXBvbmVudDtcbiAgfVxuICByZXR1cm4gYztcbn1cblxuLyoqIFJldHVybnMgdGhlIGByb3V0ZS5vdXRsZXRgIG9yIFBSSU1BUllfT1VUTEVUIGlmIG5vbmUgZXhpc3RzLiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldE91dGxldChyb3V0ZTogUm91dGUpOiBzdHJpbmcge1xuICByZXR1cm4gcm91dGUub3V0bGV0IHx8IFBSSU1BUllfT1VUTEVUO1xufVxuXG4vKipcbiAqIFNvcnRzIHRoZSBgcm91dGVzYCBzdWNoIHRoYXQgdGhlIG9uZXMgd2l0aCBhbiBvdXRsZXQgbWF0Y2hpbmcgYG91dGxldE5hbWVgIGNvbWUgZmlyc3QuXG4gKiBUaGUgb3JkZXIgb2YgdGhlIGNvbmZpZ3MgaXMgb3RoZXJ3aXNlIHByZXNlcnZlZC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNvcnRCeU1hdGNoaW5nT3V0bGV0cyhyb3V0ZXM6IFJvdXRlcywgb3V0bGV0TmFtZTogc3RyaW5nKTogUm91dGVzIHtcbiAgY29uc3Qgc29ydGVkQ29uZmlnID0gcm91dGVzLmZpbHRlcihyID0+IGdldE91dGxldChyKSA9PT0gb3V0bGV0TmFtZSk7XG4gIHNvcnRlZENvbmZpZy5wdXNoKC4uLnJvdXRlcy5maWx0ZXIociA9PiBnZXRPdXRsZXQocikgIT09IG91dGxldE5hbWUpKTtcbiAgcmV0dXJuIHNvcnRlZENvbmZpZztcbn1cblxuLyoqXG4gKiBHZXRzIHRoZSBmaXJzdCBpbmplY3RvciBpbiB0aGUgc25hcHNob3QncyBwYXJlbnQgdHJlZS5cbiAqXG4gKiBJZiB0aGUgYFJvdXRlYCBoYXMgYSBzdGF0aWMgbGlzdCBvZiBwcm92aWRlcnMsIHRoZSByZXR1cm5lZCBpbmplY3RvciB3aWxsIGJlIHRoZSBvbmUgY3JlYXRlZCBmcm9tXG4gKiB0aG9zZS4gSWYgaXQgZG9lcyBub3QgZXhpc3QsIHRoZSByZXR1cm5lZCBpbmplY3RvciBtYXkgY29tZSBmcm9tIHRoZSBwYXJlbnRzLCB3aGljaCBtYXkgYmUgZnJvbSBhXG4gKiBsb2FkZWQgY29uZmlnIG9yIHRoZWlyIHN0YXRpYyBwcm92aWRlcnMuXG4gKlxuICogUmV0dXJucyBgbnVsbGAgaWYgdGhlcmUgaXMgbmVpdGhlciB0aGlzIG5vciBhbnkgcGFyZW50cyBoYXZlIGEgc3RvcmVkIGluamVjdG9yLlxuICpcbiAqIEdlbmVyYWxseSB1c2VkIGZvciByZXRyaWV2aW5nIHRoZSBpbmplY3RvciB0byB1c2UgZm9yIGdldHRpbmcgdG9rZW5zIGZvciBndWFyZHMvcmVzb2x2ZXJzIGFuZFxuICogYWxzbyB1c2VkIGZvciBnZXR0aW5nIHRoZSBjb3JyZWN0IGluamVjdG9yIHRvIHVzZSBmb3IgY3JlYXRpbmcgY29tcG9uZW50cy5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldENsb3Nlc3RSb3V0ZUluamVjdG9yKHNuYXBzaG90OiBBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90KTogRW52aXJvbm1lbnRJbmplY3RvcnxcbiAgICBudWxsIHtcbiAgaWYgKCFzbmFwc2hvdCkgcmV0dXJuIG51bGw7XG5cbiAgLy8gSWYgdGhlIGN1cnJlbnQgcm91dGUgaGFzIGl0cyBvd24gaW5qZWN0b3IsIHdoaWNoIGlzIGNyZWF0ZWQgZnJvbSB0aGUgc3RhdGljIHByb3ZpZGVycyBvbiB0aGVcbiAgLy8gcm91dGUgaXRzZWxmLCB3ZSBzaG91bGQgdXNlIHRoYXQuIE90aGVyd2lzZSwgd2Ugc3RhcnQgYXQgdGhlIHBhcmVudCBzaW5jZSB3ZSBkbyBub3Qgd2FudCB0b1xuICAvLyBpbmNsdWRlIHRoZSBsYXp5IGxvYWRlZCBpbmplY3RvciBmcm9tIHRoaXMgcm91dGUuXG4gIGlmIChzbmFwc2hvdC5yb3V0ZUNvbmZpZz8uX2luamVjdG9yKSB7XG4gICAgcmV0dXJuIHNuYXBzaG90LnJvdXRlQ29uZmlnLl9pbmplY3RvcjtcbiAgfVxuXG4gIGZvciAobGV0IHMgPSBzbmFwc2hvdC5wYXJlbnQ7IHM7IHMgPSBzLnBhcmVudCkge1xuICAgIGNvbnN0IHJvdXRlID0gcy5yb3V0ZUNvbmZpZztcbiAgICAvLyBOb3RlIHRoYXQgdGhlIG9yZGVyIGhlcmUgaXMgaW1wb3J0YW50LiBgX2xvYWRlZEluamVjdG9yYCBzdG9yZWQgb24gdGhlIHJvdXRlIHdpdGhcbiAgICAvLyBgbG9hZENoaWxkcmVuOiAoKSA9PiBOZ01vZHVsZWAgc28gaXQgYXBwbGllcyB0byBjaGlsZCByb3V0ZXMgd2l0aCBwcmlvcml0eS4gVGhlIGBfaW5qZWN0b3JgXG4gICAgLy8gaXMgY3JlYXRlZCBmcm9tIHRoZSBzdGF0aWMgcHJvdmlkZXJzIG9uIHRoYXQgcGFyZW50IHJvdXRlLCBzbyBpdCBhcHBsaWVzIHRvIHRoZSBjaGlsZHJlbiBhc1xuICAgIC8vIHdlbGwsIGJ1dCBvbmx5IGlmIHRoZXJlIGlzIG5vIGxhenkgbG9hZGVkIE5nTW9kdWxlUmVmIGluamVjdG9yLlxuICAgIGlmIChyb3V0ZT8uX2xvYWRlZEluamVjdG9yKSByZXR1cm4gcm91dGUuX2xvYWRlZEluamVjdG9yO1xuICAgIGlmIChyb3V0ZT8uX2luamVjdG9yKSByZXR1cm4gcm91dGUuX2luamVjdG9yO1xuICB9XG5cbiAgcmV0dXJuIG51bGw7XG59XG4iXX0=