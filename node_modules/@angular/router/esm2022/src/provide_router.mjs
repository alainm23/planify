/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { HashLocationStrategy, LOCATION_INITIALIZED, LocationStrategy, ViewportScroller } from '@angular/common';
import { APP_BOOTSTRAP_LISTENER, APP_INITIALIZER, ApplicationRef, ENVIRONMENT_INITIALIZER, EnvironmentInjector, inject, InjectFlags, InjectionToken, Injector, makeEnvironmentProviders, NgZone } from '@angular/core';
import { of, Subject } from 'rxjs';
import { INPUT_BINDER, RoutedComponentInputBinder } from './directives/router_outlet';
import { NavigationError, stringifyEvent } from './events';
import { NavigationTransitions } from './navigation_transition';
import { Router } from './router';
import { ROUTER_CONFIGURATION } from './router_config';
import { ROUTES } from './router_config_loader';
import { PreloadingStrategy, RouterPreloader } from './router_preloader';
import { ROUTER_SCROLLER, RouterScroller } from './router_scroller';
import { ActivatedRoute } from './router_state';
import { UrlSerializer } from './url_tree';
import { afterNextNavigation } from './utils/navigations';
/**
 * Sets up providers necessary to enable `Router` functionality for the application.
 * Allows to configure a set of routes as well as extra features that should be enabled.
 *
 * @usageNotes
 *
 * Basic example of how you can add a Router to your application:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent, {
 *   providers: [provideRouter(appRoutes)]
 * });
 * ```
 *
 * You can also enable optional features in the Router by adding functions from the `RouterFeatures`
 * type:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes,
 *         withDebugTracing(),
 *         withRouterConfig({paramsInheritanceStrategy: 'always'}))
 *     ]
 *   }
 * );
 * ```
 *
 * @see `RouterFeatures`
 *
 * @publicApi
 * @param routes A set of `Route`s to use for the application routing table.
 * @param features Optional features to configure additional router behaviors.
 * @returns A set of providers to setup a Router.
 */
export function provideRouter(routes, ...features) {
    return makeEnvironmentProviders([
        { provide: ROUTES, multi: true, useValue: routes },
        (typeof ngDevMode === 'undefined' || ngDevMode) ?
            { provide: ROUTER_IS_PROVIDED, useValue: true } :
            [],
        { provide: ActivatedRoute, useFactory: rootRoute, deps: [Router] },
        { provide: APP_BOOTSTRAP_LISTENER, multi: true, useFactory: getBootstrapListener },
        features.map(feature => feature.ɵproviders),
    ]);
}
export function rootRoute(router) {
    return router.routerState.root;
}
/**
 * Helper function to create an object that represents a Router feature.
 */
function routerFeature(kind, providers) {
    return { ɵkind: kind, ɵproviders: providers };
}
/**
 * An Injection token used to indicate whether `provideRouter` or `RouterModule.forRoot` was ever
 * called.
 */
export const ROUTER_IS_PROVIDED = new InjectionToken('', { providedIn: 'root', factory: () => false });
const routerIsProvidedDevModeCheck = {
    provide: ENVIRONMENT_INITIALIZER,
    multi: true,
    useFactory() {
        return () => {
            if (!inject(ROUTER_IS_PROVIDED)) {
                console.warn('`provideRoutes` was called without `provideRouter` or `RouterModule.forRoot`. ' +
                    'This is likely a mistake.');
            }
        };
    }
};
/**
 * Registers a [DI provider](guide/glossary#provider) for a set of routes.
 * @param routes The route configuration to provide.
 *
 * @usageNotes
 *
 * ```
 * @NgModule({
 *   providers: [provideRoutes(ROUTES)]
 * })
 * class LazyLoadedChildModule {}
 * ```
 *
 * @deprecated If necessary, provide routes using the `ROUTES` `InjectionToken`.
 * @see `ROUTES`
 * @publicApi
 */
export function provideRoutes(routes) {
    return [
        { provide: ROUTES, multi: true, useValue: routes },
        (typeof ngDevMode === 'undefined' || ngDevMode) ? routerIsProvidedDevModeCheck : [],
    ];
}
/**
 * Enables customizable scrolling behavior for router navigations.
 *
 * @usageNotes
 *
 * Basic example of how you can enable scrolling feature:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withInMemoryScrolling())
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 * @see `ViewportScroller`
 *
 * @publicApi
 * @param options Set of configuration parameters to customize scrolling behavior, see
 *     `InMemoryScrollingOptions` for additional information.
 * @returns A set of providers for use with `provideRouter`.
 */
export function withInMemoryScrolling(options = {}) {
    const providers = [{
            provide: ROUTER_SCROLLER,
            useFactory: () => {
                const viewportScroller = inject(ViewportScroller);
                const zone = inject(NgZone);
                const transitions = inject(NavigationTransitions);
                const urlSerializer = inject(UrlSerializer);
                return new RouterScroller(urlSerializer, transitions, viewportScroller, zone, options);
            },
        }];
    return routerFeature(4 /* RouterFeatureKind.InMemoryScrollingFeature */, providers);
}
export function getBootstrapListener() {
    const injector = inject(Injector);
    return (bootstrappedComponentRef) => {
        const ref = injector.get(ApplicationRef);
        if (bootstrappedComponentRef !== ref.components[0]) {
            return;
        }
        const router = injector.get(Router);
        const bootstrapDone = injector.get(BOOTSTRAP_DONE);
        if (injector.get(INITIAL_NAVIGATION) === 1 /* InitialNavigation.EnabledNonBlocking */) {
            router.initialNavigation();
        }
        injector.get(ROUTER_PRELOADER, null, InjectFlags.Optional)?.setUpPreloading();
        injector.get(ROUTER_SCROLLER, null, InjectFlags.Optional)?.init();
        router.resetRootComponentType(ref.componentTypes[0]);
        if (!bootstrapDone.closed) {
            bootstrapDone.next();
            bootstrapDone.complete();
            bootstrapDone.unsubscribe();
        }
    };
}
/**
 * A subject used to indicate that the bootstrapping phase is done. When initial navigation is
 * `enabledBlocking`, the first navigation waits until bootstrapping is finished before continuing
 * to the activation phase.
 */
const BOOTSTRAP_DONE = new InjectionToken((typeof ngDevMode === 'undefined' || ngDevMode) ? 'bootstrap done indicator' : '', {
    factory: () => {
        return new Subject();
    }
});
const INITIAL_NAVIGATION = new InjectionToken((typeof ngDevMode === 'undefined' || ngDevMode) ? 'initial navigation' : '', { providedIn: 'root', factory: () => 1 /* InitialNavigation.EnabledNonBlocking */ });
/**
 * Configures initial navigation to start before the root component is created.
 *
 * The bootstrap is blocked until the initial navigation is complete. This value is required for
 * [server-side rendering](guide/universal) to work.
 *
 * @usageNotes
 *
 * Basic example of how you can enable this navigation behavior:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withEnabledBlockingInitialNavigation())
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 *
 * @publicApi
 * @returns A set of providers for use with `provideRouter`.
 */
export function withEnabledBlockingInitialNavigation() {
    const providers = [
        { provide: INITIAL_NAVIGATION, useValue: 0 /* InitialNavigation.EnabledBlocking */ },
        {
            provide: APP_INITIALIZER,
            multi: true,
            deps: [Injector],
            useFactory: (injector) => {
                const locationInitialized = injector.get(LOCATION_INITIALIZED, Promise.resolve());
                return () => {
                    return locationInitialized.then(() => {
                        return new Promise(resolve => {
                            const router = injector.get(Router);
                            const bootstrapDone = injector.get(BOOTSTRAP_DONE);
                            afterNextNavigation(router, () => {
                                // Unblock APP_INITIALIZER in case the initial navigation was canceled or errored
                                // without a redirect.
                                resolve(true);
                            });
                            injector.get(NavigationTransitions).afterPreactivation = () => {
                                // Unblock APP_INITIALIZER once we get to `afterPreactivation`. At this point, we
                                // assume activation will complete successfully (even though this is not
                                // guaranteed).
                                resolve(true);
                                return bootstrapDone.closed ? of(void 0) : bootstrapDone;
                            };
                            router.initialNavigation();
                        });
                    });
                };
            }
        },
    ];
    return routerFeature(2 /* RouterFeatureKind.EnabledBlockingInitialNavigationFeature */, providers);
}
/**
 * Disables initial navigation.
 *
 * Use if there is a reason to have more control over when the router starts its initial navigation
 * due to some complex initialization logic.
 *
 * @usageNotes
 *
 * Basic example of how you can disable initial navigation:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withDisabledInitialNavigation())
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 *
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withDisabledInitialNavigation() {
    const providers = [
        {
            provide: APP_INITIALIZER,
            multi: true,
            useFactory: () => {
                const router = inject(Router);
                return () => {
                    router.setUpLocationChangeListener();
                };
            }
        },
        { provide: INITIAL_NAVIGATION, useValue: 2 /* InitialNavigation.Disabled */ }
    ];
    return routerFeature(3 /* RouterFeatureKind.DisabledInitialNavigationFeature */, providers);
}
/**
 * Enables logging of all internal navigation events to the console.
 * Extra logging might be useful for debugging purposes to inspect Router event sequence.
 *
 * @usageNotes
 *
 * Basic example of how you can enable debug tracing:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withDebugTracing())
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 *
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withDebugTracing() {
    let providers = [];
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        providers = [{
                provide: ENVIRONMENT_INITIALIZER,
                multi: true,
                useFactory: () => {
                    const router = inject(Router);
                    return () => router.events.subscribe((e) => {
                        // tslint:disable:no-console
                        console.group?.(`Router Event: ${e.constructor.name}`);
                        console.log(stringifyEvent(e));
                        console.log(e);
                        console.groupEnd?.();
                        // tslint:enable:no-console
                    });
                }
            }];
    }
    else {
        providers = [];
    }
    return routerFeature(1 /* RouterFeatureKind.DebugTracingFeature */, providers);
}
const ROUTER_PRELOADER = new InjectionToken((typeof ngDevMode === 'undefined' || ngDevMode) ? 'router preloader' : '');
/**
 * Allows to configure a preloading strategy to use. The strategy is configured by providing a
 * reference to a class that implements a `PreloadingStrategy`.
 *
 * @usageNotes
 *
 * Basic example of how you can configure preloading:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withPreloading(PreloadAllModules))
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 *
 * @param preloadingStrategy A reference to a class that implements a `PreloadingStrategy` that
 *     should be used.
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withPreloading(preloadingStrategy) {
    const providers = [
        { provide: ROUTER_PRELOADER, useExisting: RouterPreloader },
        { provide: PreloadingStrategy, useExisting: preloadingStrategy },
    ];
    return routerFeature(0 /* RouterFeatureKind.PreloadingFeature */, providers);
}
/**
 * Allows to provide extra parameters to configure Router.
 *
 * @usageNotes
 *
 * Basic example of how you can provide extra configuration options:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withRouterConfig({
 *          onSameUrlNavigation: 'reload'
 *       }))
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 *
 * @param options A set of parameters to configure Router, see `RouterConfigOptions` for
 *     additional information.
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withRouterConfig(options) {
    const providers = [
        { provide: ROUTER_CONFIGURATION, useValue: options },
    ];
    return routerFeature(5 /* RouterFeatureKind.RouterConfigurationFeature */, providers);
}
/**
 * Provides the location strategy that uses the URL fragment instead of the history API.
 *
 * @usageNotes
 *
 * Basic example of how you can use the hash location option:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withHashLocation())
 *     ]
 *   }
 * );
 * ```
 *
 * @see `provideRouter`
 * @see `HashLocationStrategy`
 *
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withHashLocation() {
    const providers = [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
    ];
    return routerFeature(5 /* RouterFeatureKind.RouterConfigurationFeature */, providers);
}
/**
 * Subscribes to the Router's navigation events and calls the given function when a
 * `NavigationError` happens.
 *
 * This function is run inside application's injection context so you can use the `inject` function.
 *
 * @usageNotes
 *
 * Basic example of how you can use the error handler option:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withNavigationErrorHandler((e: NavigationError) =>
 * inject(MyErrorTracker).trackError(e)))
 *     ]
 *   }
 * );
 * ```
 *
 * @see `NavigationError`
 * @see `inject`
 * @see `EnvironmentInjector#runInContext`
 *
 * @returns A set of providers for use with `provideRouter`.
 *
 * @publicApi
 */
export function withNavigationErrorHandler(fn) {
    const providers = [{
            provide: ENVIRONMENT_INITIALIZER,
            multi: true,
            useValue: () => {
                const injector = inject(EnvironmentInjector);
                inject(Router).events.subscribe((e) => {
                    if (e instanceof NavigationError) {
                        injector.runInContext(() => fn(e));
                    }
                });
            }
        }];
    return routerFeature(7 /* RouterFeatureKind.NavigationErrorHandlerFeature */, providers);
}
/**
 * Enables binding information from the `Router` state directly to the inputs of the component in
 * `Route` configurations.
 *
 * @usageNotes
 *
 * Basic example of how you can enable the feature:
 * ```
 * const appRoutes: Routes = [];
 * bootstrapApplication(AppComponent,
 *   {
 *     providers: [
 *       provideRouter(appRoutes, withComponentInputBinding())
 *     ]
 *   }
 * );
 * ```
 *
 * @returns A set of providers for use with `provideRouter`.
 */
export function withComponentInputBinding() {
    const providers = [
        RoutedComponentInputBinder,
        { provide: INPUT_BINDER, useExisting: RoutedComponentInputBinder },
    ];
    return routerFeature(8 /* RouterFeatureKind.ComponentInputBindingFeature */, providers);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicHJvdmlkZV9yb3V0ZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9yb3V0ZXIvc3JjL3Byb3ZpZGVfcm91dGVyLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxvQkFBb0IsRUFBRSxvQkFBb0IsRUFBRSxnQkFBZ0IsRUFBRSxnQkFBZ0IsRUFBQyxNQUFNLGlCQUFpQixDQUFDO0FBQy9HLE9BQU8sRUFBQyxzQkFBc0IsRUFBRSxlQUFlLEVBQUUsY0FBYyxFQUEyQix1QkFBdUIsRUFBRSxtQkFBbUIsRUFBd0IsTUFBTSxFQUFFLFdBQVcsRUFBRSxjQUFjLEVBQUUsUUFBUSxFQUFFLHdCQUF3QixFQUFFLE1BQU0sRUFBaUIsTUFBTSxlQUFlLENBQUM7QUFDcFIsT0FBTyxFQUFDLEVBQUUsRUFBRSxPQUFPLEVBQUMsTUFBTSxNQUFNLENBQUM7QUFFakMsT0FBTyxFQUFDLFlBQVksRUFBRSwwQkFBMEIsRUFBQyxNQUFNLDRCQUE0QixDQUFDO0FBQ3BGLE9BQU8sRUFBUSxlQUFlLEVBQUUsY0FBYyxFQUFDLE1BQU0sVUFBVSxDQUFDO0FBRWhFLE9BQU8sRUFBQyxxQkFBcUIsRUFBQyxNQUFNLHlCQUF5QixDQUFDO0FBQzlELE9BQU8sRUFBQyxNQUFNLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFDaEMsT0FBTyxFQUEyQixvQkFBb0IsRUFBc0IsTUFBTSxpQkFBaUIsQ0FBQztBQUNwRyxPQUFPLEVBQUMsTUFBTSxFQUFDLE1BQU0sd0JBQXdCLENBQUM7QUFDOUMsT0FBTyxFQUFDLGtCQUFrQixFQUFFLGVBQWUsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBQ3ZFLE9BQU8sRUFBQyxlQUFlLEVBQUUsY0FBYyxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDbEUsT0FBTyxFQUFDLGNBQWMsRUFBQyxNQUFNLGdCQUFnQixDQUFDO0FBQzlDLE9BQU8sRUFBQyxhQUFh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aEMsS0FBSyxFQUFFLElBQUk7WUFDWCxRQUFRLEVBQUUsR0FBRyxFQUFFO2dCQUNiLE1BQU0sUUFBUSxHQUFHLE1BQU0sQ0FBQyxtQkFBbUIsQ0FBQyxDQUFDO2dCQUM3QyxNQUFNLENBQUMsTUFBTSxDQUFDLENBQUMsTUFBTSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsRUFBRSxFQUFFO29CQUNwQyxJQUFJLENBQUMsWUFBWSxlQUFlLEVBQUU7d0JBQ2hDLFFBQVEsQ0FBQyxZQUFZLENBQUMsR0FBRyxFQUFFLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUM7cUJBQ3BDO2dCQUNILENBQUMsQ0FBQyxDQUFDO1lBQ0wsQ0FBQztTQUNGLENBQUMsQ0FBQztJQUNILE9BQU8sYUFBYSwwREFBa0QsU0FBUyxDQUFDLENBQUM7QUFDbkYsQ0FBQztBQWFEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBbUJHO0FBQ0gsTUFBTSxVQUFVLHlCQUF5QjtJQUN2QyxNQUFNLFNBQVMsR0FBRztRQUNoQiwwQkFBMEI7UUFDMUIsRUFBQyxPQUFPLEVBQUUsWUFBWSxFQUFFLFdBQVcsRUFBRSwwQkFBMEIsRUFBQztLQUNqRSxDQUFDO0lBRUYsT0FBTyxhQUFhLHlEQUFpRCxTQUFTLENBQUMsQ0FBQztBQUNsRixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7SGFzaExvY2F0aW9uU3RyYXRlZ3ksIExPQ0FUSU9OX0lOSVRJQUxJWkVELCBMb2NhdGlvblN0cmF0ZWd5LCBWaWV3cG9ydFNjcm9sbGVyfSBmcm9tICdAYW5ndWxhci9jb21tb24nO1xuaW1wb3J0IHtBUFBfQk9PVFNUUkFQX0xJU1RFTkVSLCBBUFBfSU5JVElBTElaRVIsIEFwcGxpY2F0aW9uUmVmLCBDb21wb25lbnQsIENvbXBvbmVudFJlZiwgRU5WSVJPTk1FTlRfSU5JVElBTElaRVIsIEVudmlyb25tZW50SW5qZWN0b3IsIEVudmlyb25tZW50UHJvdmlkZXJzLCBpbmplY3QsIEluamVjdEZsYWdzLCBJbmplY3Rpb25Ub2tlbiwgSW5qZWN0b3IsIG1ha2VFbnZpcm9ubWVudFByb3ZpZGVycywgTmdab25lLCBQcm92aWRlciwgVHlwZX0gZnJvbSAnQGFuZ3VsYXIvY29yZSc7XG5pbXBvcnQge29mLCBTdWJqZWN0fSBmcm9tICdyeGpzJztcblxuaW1wb3J0IHtJTlBVVF9CSU5ERVIsIFJvdXRlZENvbXBvbmVudElucHV0QmluZGVyfSBmcm9tICcuL2RpcmVjdGl2ZXMvcm91dGVyX291dGxldCc7XG5pbXBvcnQge0V2ZW50LCBOYXZpZ2F0aW9uRXJyb3IsIHN0cmluZ2lmeUV2ZW50fSBmcm9tICcuL2V2ZW50cyc7XG5pbXBvcnQge1JvdXRlc30gZnJvbSAnLi9tb2RlbHMnO1xuaW1wb3J0IHtOYXZpZ2F0aW9uVHJhbnNpdGlvbnN9IGZyb20gJy4vbmF2aWdhdGlvbl90cmFuc2l0aW9uJztcbmltcG9ydCB7Um91dGVyfSBmcm9tICcuL3JvdXRlcic7XG5pbXBvcnQge0luTWVtb3J5U2Nyb2xsaW5nT3B0aW9ucywgUk9VVEVSX0NPTkZJR1VSQVRJT04sIFJvdXRlckNvbmZpZ09wdGlvbnN9IGZyb20gJy4vcm91dGVyX2NvbmZpZyc7XG5pbXBvcnQge1JPVVRFU30gZnJvbSAnLi9yb3V0ZXJfY29uZmlnX2xvYWRlcic7XG5pbXBvcnQge1ByZWxvYWRpbmdTdHJhdGVneSwgUm91dGVyUHJlbG9hZGVyfSBmcm9tICcuL3JvdXRlcl9wcmVsb2FkZXInO1xuaW1wb3J0IHtST1VURVJfU0NST0xMRVIsIFJvdXRlclNjcm9sbGVyfSBmcm9tICcuL3JvdXRlcl9zY3JvbGxlcic7XG5pbXBvcnQge0FjdGl2YXRlZFJvdXRlfSBmcm9tICcuL3JvdXRlcl9zdGF0ZSc7XG5pbXBvcnQge1VybFNlcmlhbGl6ZXJ9IGZyb20gJy4vdXJsX3RyZWUnO1xuaW1wb3J0IHthZnRlck5leHROYXZpZ2F0aW9ufSBmcm9tICcuL3V0aWxzL25hdmlnYXRpb25zJztcblxuXG4vKipcbiAqIFNldHMgdXAgcHJvdmlkZXJzIG5lY2Vzc2FyeSB0byBlbmFibGUgYFJvdXRlcmAgZnVuY3Rpb25hbGl0eSBmb3IgdGhlIGFwcGxpY2F0aW9uLlxuICogQWxsb3dzIHRvIGNvbmZpZ3VyZSBhIHNldCBvZiByb3V0ZXMgYXMgd2VsbCBhcyBleHRyYSBmZWF0dXJlcyB0aGF0IHNob3VsZCBiZSBlbmFibGVkLlxuICpcbiAqIEB1c2FnZU5vdGVzXG4gKlxuICogQmFzaWMgZXhhbXBsZSBvZiBob3cgeW91IGNhbiBhZGQgYSBSb3V0ZXIgdG8geW91ciBhcHBsaWNhdGlvbjpcbiAqIGBgYFxuICogY29uc3QgYXBwUm91dGVzOiBSb3V0ZXMgPSBbXTtcbiAqIGJvb3RzdHJhcEFwcGxpY2F0aW9uKEFwcENvbXBvbmVudCwge1xuICogICBwcm92aWRlcnM6IFtwcm92aWRlUm91dGVyKGFwcFJvdXRlcyldXG4gKiB9KTtcbiAqIGBgYFxuICpcbiAqIFlvdSBjYW4gYWxzbyBlbmFibGUgb3B0aW9uYWwgZmVhdHVyZXMgaW4gdGhlIFJvdXRlciBieSBhZGRpbmcgZnVuY3Rpb25zIGZyb20gdGhlIGBSb3V0ZXJGZWF0dXJlc2BcbiAqIHR5cGU6XG4gKiBgYGBcbiAqIGNvbnN0IGFwcFJvdXRlczogUm91dGVzID0gW107XG4gKiBib290c3RyYXBBcHBsaWNhdGlvbihBcHBDb21wb25lbnQsXG4gKiAgIHtcbiAqICAgICBwcm92aWRlcnM6IFtcbiAqICAgICAgIHByb3ZpZGVSb3V0ZXIoYXBwUm91dGVzLFxuICogICAgICAgICB3aXRoRGVidWdUcmFjaW5nKCksXG4gKiAgICAgICAgIHdpdGhSb3V0ZXJDb25maWcoe3BhcmFtc0luaGVyaXRhbmNlU3RyYXRlZ3k6ICdhbHdheXMnfSkpXG4gKiAgICAgXVxuICogICB9XG4gKiApO1xuICogYGBgXG4gKlxuICogQHNlZSBgUm91dGVyRmVhdHVyZXNgXG4gKlxuICogQHB1YmxpY0FwaVxuICogQHBhcmFtIHJvdXRlcyBBIHNldCBvZiBgUm91dGVgcyB0byB1c2UgZm9yIHRoZSBhcHBsaWNhdGlvbiByb3V0aW5nIHRhYmxlLlxuICogQHBhcmFtIGZlYXR1cmVzIE9wdGlvbmFsIGZlYXR1cmVzIHRvIGNvbmZpZ3VyZSBhZGRpdGlvbmFsIHJvdXRlciBiZWhhdmlvcnMuXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgdG8gc2V0dXAgYSBSb3V0ZXIuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBwcm92aWRlUm91dGVyKHJvdXRlczogUm91dGVzLCAuLi5mZWF0dXJlczogUm91dGVyRmVhdHVyZXNbXSk6IEVudmlyb25tZW50UHJvdmlkZXJzIHtcbiAgcmV0dXJuIG1ha2VFbnZpcm9ubWVudFByb3ZpZGVycyhbXG4gICAge3Byb3ZpZGU6IFJPVVRFUywgbXVsdGk6IHRydWUsIHVzZVZhbHVlOiByb3V0ZXN9LFxuICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpID9cbiAgICAgICAge3Byb3ZpZGU6IFJPVVRFUl9JU19QUk9WSURFRCwgdXNlVmFsdWU6IHRydWV9IDpcbiAgICAgICAgW10sXG4gICAge3Byb3ZpZGU6IEFjdGl2YXRlZFJvdXRlLCB1c2VGYWN0b3J5OiByb290Um91dGUsIGRlcHM6IFtSb3V0ZXJdfSxcbiAgICB7cHJvdmlkZTogQVBQX0JPT1RTVFJBUF9MSVNURU5FUiwgbXVsdGk6IHRydWUsIHVzZUZhY3Rvcnk6IGdldEJvb3RzdHJhcExpc3RlbmVyfSxcbiAgICBmZWF0dXJlcy5tYXAoZmVhdHVyZSA9PiBmZWF0dXJlLsm1cHJvdmlkZXJzKSxcbiAgXSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiByb290Um91dGUocm91dGVyOiBSb3V0ZXIpOiBBY3RpdmF0ZWRSb3V0ZSB7XG4gIHJldHVybiByb3V0ZXIucm91dGVyU3RhdGUucm9vdDtcbn1cblxuLyoqXG4gKiBIZWxwZXIgdHlwZSB0byByZXByZXNlbnQgYSBSb3V0ZXIgZmVhdHVyZS5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgUm91dGVyRmVhdHVyZTxGZWF0dXJlS2luZCBleHRlbmRzIFJvdXRlckZlYXR1cmVLaW5kPiB7XG4gIMm1a2luZDogRmVhdHVyZUtpbmQ7XG4gIMm1cHJvdmlkZXJzOiBQcm92aWRlcltdO1xufVxuXG4vKipcbiAqIEhlbHBlciBmdW5jdGlvbiB0byBjcmVhdGUgYW4gb2JqZWN0IHRoYXQgcmVwcmVzZW50cyBhIFJvdXRlciBmZWF0dXJlLlxuICovXG5mdW5jdGlvbiByb3V0ZXJGZWF0dXJlPEZlYXR1cmVLaW5kIGV4dGVuZHMgUm91dGVyRmVhdHVyZUtpbmQ+KFxuICAgIGtpbmQ6IEZlYXR1cmVLaW5kLCBwcm92aWRlcnM6IFByb3ZpZGVyW10pOiBSb3V0ZXJGZWF0dXJlPEZlYXR1cmVLaW5kPiB7XG4gIHJldHVybiB7ybVraW5kOiBraW5kLCDJtXByb3ZpZGVyczogcHJvdmlkZXJzfTtcbn1cblxuXG4vKipcbiAqIEFuIEluamVjdGlvbiB0b2tlbiB1c2VkIHRvIGluZGljYXRlIHdoZXRoZXIgYHByb3ZpZGVSb3V0ZXJgIG9yIGBSb3V0ZXJNb2R1bGUuZm9yUm9vdGAgd2FzIGV2ZXJcbiAqIGNhbGxlZC5cbiAqL1xuZXhwb3J0IGNvbnN0IFJPVVRFUl9JU19QUk9WSURFRCA9XG4gICAgbmV3IEluamVjdGlvblRva2VuPGJvb2xlYW4+KCcnLCB7cHJvdmlkZWRJbjogJ3Jvb3QnLCBmYWN0b3J5OiAoKSA9PiBmYWxzZX0pO1xuXG5jb25zdCByb3V0ZXJJc1Byb3ZpZGVkRGV2TW9kZUNoZWNrID0ge1xuICBwcm92aWRlOiBFTlZJUk9OTUVOVF9JTklUSUFMSVpFUixcbiAgbXVsdGk6IHRydWUsXG4gIHVzZUZhY3RvcnkoKSB7XG4gICAgcmV0dXJuICgpID0+IHtcbiAgICAgIGlmICghaW5qZWN0KFJPVVRFUl9JU19QUk9WSURFRCkpIHtcbiAgICAgICAgY29uc29sZS53YXJuKFxuICAgICAgICAgICAgJ2Bwcm92aWRlUm91dGVzYCB3YXMgY2FsbGVkIHdpdGhvdXQgYHByb3ZpZGVSb3V0ZXJgIG9yIGBSb3V0ZXJNb2R1bGUuZm9yUm9vdGAuICcgK1xuICAgICAgICAgICAgJ1RoaXMgaXMgbGlrZWx5IGEgbWlzdGFrZS4nKTtcbiAgICAgIH1cbiAgICB9O1xuICB9XG59O1xuXG4vKipcbiAqIFJlZ2lzdGVycyBhIFtESSBwcm92aWRlcl0oZ3VpZGUvZ2xvc3NhcnkjcHJvdmlkZXIpIGZvciBhIHNldCBvZiByb3V0ZXMuXG4gKiBAcGFyYW0gcm91dGVzIFRoZSByb3V0ZSBjb25maWd1cmF0aW9uIHRvIHByb3ZpZGUuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBgYGBcbiAqIEBOZ01vZHVsZSh7XG4gKiAgIHByb3ZpZGVyczogW3Byb3ZpZGVSb3V0ZXMoUk9VVEVTKV1cbiAqIH0pXG4gKiBjbGFzcyBMYXp5TG9hZGVkQ2hpbGRNb2R1bGUge31cbiAqIGBgYFxuICpcbiAqIEBkZXByZWNhdGVkIElmIG5lY2Vzc2FyeSwgcHJvdmlkZSByb3V0ZXMgdXNpbmcgdGhlIGBST1VURVNgIGBJbmplY3Rpb25Ub2tlbmAuXG4gKiBAc2VlIGBST1VURVNgXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBwcm92aWRlUm91dGVzKHJvdXRlczogUm91dGVzKTogUHJvdmlkZXJbXSB7XG4gIHJldHVybiBbXG4gICAge3Byb3ZpZGU6IFJPVVRFUywgbXVsdGk6IHRydWUsIHVzZVZhbHVlOiByb3V0ZXN9LFxuICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpID8gcm91dGVySXNQcm92aWRlZERldk1vZGVDaGVjayA6IFtdLFxuICBdO1xufVxuXG4vKipcbiAqIEEgdHlwZSBhbGlhcyBmb3IgcHJvdmlkZXJzIHJldHVybmVkIGJ5IGB3aXRoSW5NZW1vcnlTY3JvbGxpbmdgIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHNlZSBgd2l0aEluTWVtb3J5U2Nyb2xsaW5nYFxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIEluTWVtb3J5U2Nyb2xsaW5nRmVhdHVyZSA9IFJvdXRlckZlYXR1cmU8Um91dGVyRmVhdHVyZUtpbmQuSW5NZW1vcnlTY3JvbGxpbmdGZWF0dXJlPjtcblxuLyoqXG4gKiBFbmFibGVzIGN1c3RvbWl6YWJsZSBzY3JvbGxpbmcgYmVoYXZpb3IgZm9yIHJvdXRlciBuYXZpZ2F0aW9ucy5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIEJhc2ljIGV4YW1wbGUgb2YgaG93IHlvdSBjYW4gZW5hYmxlIHNjcm9sbGluZyBmZWF0dXJlOlxuICogYGBgXG4gKiBjb25zdCBhcHBSb3V0ZXM6IFJvdXRlcyA9IFtdO1xuICogYm9vdHN0cmFwQXBwbGljYXRpb24oQXBwQ29tcG9uZW50LFxuICogICB7XG4gKiAgICAgcHJvdmlkZXJzOiBbXG4gKiAgICAgICBwcm92aWRlUm91dGVyKGFwcFJvdXRlcywgd2l0aEluTWVtb3J5U2Nyb2xsaW5nKCkpXG4gKiAgICAgXVxuICogICB9XG4gKiApO1xuICogYGBgXG4gKlxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqIEBzZWUgYFZpZXdwb3J0U2Nyb2xsZXJgXG4gKlxuICogQHB1YmxpY0FwaVxuICogQHBhcmFtIG9wdGlvbnMgU2V0IG9mIGNvbmZpZ3VyYXRpb24gcGFyYW1ldGVycyB0byBjdXN0b21pemUgc2Nyb2xsaW5nIGJlaGF2aW9yLCBzZWVcbiAqICAgICBgSW5NZW1vcnlTY3JvbGxpbmdPcHRpb25zYCBmb3IgYWRkaXRpb25hbCBpbmZvcm1hdGlvbi5cbiAqIEByZXR1cm5zIEEgc2V0IG9mIHByb3ZpZGVycyBmb3IgdXNlIHdpdGggYHByb3ZpZGVSb3V0ZXJgLlxuICovXG5leHBvcnQgZnVuY3Rpb24gd2l0aEluTWVtb3J5U2Nyb2xsaW5nKG9wdGlvbnM6IEluTWVtb3J5U2Nyb2xsaW5nT3B0aW9ucyA9IHt9KTpcbiAgICBJbk1lbW9yeVNjcm9sbGluZ0ZlYXR1cmUge1xuICBjb25zdCBwcm92aWRlcnMgPSBbe1xuICAgIHByb3ZpZGU6IFJPVVRFUl9TQ1JPTExFUixcbiAgICB1c2VGYWN0b3J5OiAoKSA9PiB7XG4gICAgICBjb25zdCB2aWV3cG9ydFNjcm9sbGVyID0gaW5qZWN0KFZpZXdwb3J0U2Nyb2xsZXIpO1xuICAgICAgY29uc3Qgem9uZSA9IGluamVjdChOZ1pvbmUpO1xuICAgICAgY29uc3QgdHJhbnNpdGlvbnMgPSBpbmplY3QoTmF2aWdhdGlvblRyYW5zaXRpb25zKTtcbiAgICAgIGNvbnN0IHVybFNlcmlhbGl6ZXIgPSBpbmplY3QoVXJsU2VyaWFsaXplcik7XG4gICAgICByZXR1cm4gbmV3IFJvdXRlclNjcm9sbGVyKHVybFNlcmlhbGl6ZXIsIHRyYW5zaXRpb25zLCB2aWV3cG9ydFNjcm9sbGVyLCB6b25lLCBvcHRpb25zKTtcbiAgICB9LFxuICB9XTtcbiAgcmV0dXJuIHJvdXRlckZlYXR1cmUoUm91dGVyRmVhdHVyZUtpbmQuSW5NZW1vcnlTY3JvbGxpbmdGZWF0dXJlLCBwcm92aWRlcnMpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gZ2V0Qm9vdHN0cmFwTGlzdGVuZXIoKSB7XG4gIGNvbnN0IGluamVjdG9yID0gaW5qZWN0KEluamVjdG9yKTtcbiAgcmV0dXJuIChib290c3RyYXBwZWRDb21wb25lbnRSZWY6IENvbXBvbmVudFJlZjx1bmtub3duPikgPT4ge1xuICAgIGNvbnN0IHJlZiA9IGluamVjdG9yLmdldChBcHBsaWNhdGlvblJlZik7XG5cbiAgICBpZiAoYm9vdHN0cmFwcGVkQ29tcG9uZW50UmVmICE9PSByZWYuY29tcG9uZW50c1swXSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGNvbnN0IHJvdXRlciA9IGluamVjdG9yLmdldChSb3V0ZXIpO1xuICAgIGNvbnN0IGJvb3RzdHJhcERvbmUgPSBpbmplY3Rvci5nZXQoQk9PVFNUUkFQX0RPTkUpO1xuXG4gICAgaWYgKGluamVjdG9yLmdldChJTklUSUFMX05BVklHQVRJT04pID09PSBJbml0aWFsTmF2aWdhdGlvbi5FbmFibGVkTm9uQmxvY2tpbmcpIHtcbiAgICAgIHJvdXRlci5pbml0aWFsTmF2aWdhdGlvbigpO1xuICAgIH1cblxuICAgIGluamVjdG9yLmdldChST1VURVJfUFJFTE9BREVSLCBudWxsLCBJbmplY3RGbGFncy5PcHRpb25hbCk/LnNldFVwUHJlbG9hZGluZygpO1xuICAgIGluamVjdG9yLmdldChST1VURVJfU0NST0xMRVIsIG51bGwsIEluamVjdEZsYWdzLk9wdGlvbmFsKT8uaW5pdCgpO1xuICAgIHJvdXRlci5yZXNldFJvb3RDb21wb25lbnRUeXBlKHJlZi5jb21wb25lbnRUeXBlc1swXSk7XG4gICAgaWYgKCFib290c3RyYXBEb25lLmNsb3NlZCkge1xuICAgICAgYm9vdHN0cmFwRG9uZS5uZXh0KCk7XG4gICAgICBib290c3RyYXBEb25lLmNvbXBsZXRlKCk7XG4gICAgICBib290c3RyYXBEb25lLnVuc3Vic2NyaWJlKCk7XG4gICAgfVxuICB9O1xufVxuXG4vKipcbiAqIEEgc3ViamVjdCB1c2VkIHRvIGluZGljYXRlIHRoYXQgdGhlIGJvb3RzdHJhcHBpbmcgcGhhc2UgaXMgZG9uZS4gV2hlbiBpbml0aWFsIG5hdmlnYXRpb24gaXNcbiAqIGBlbmFibGVkQmxvY2tpbmdgLCB0aGUgZmlyc3QgbmF2aWdhdGlvbiB3YWl0cyB1bnRpbCBib290c3RyYXBwaW5nIGlzIGZpbmlzaGVkIGJlZm9yZSBjb250aW51aW5nXG4gKiB0byB0aGUgYWN0aXZhdGlvbiBwaGFzZS5cbiAqL1xuY29uc3QgQk9PVFNUUkFQX0RPTkUgPSBuZXcgSW5qZWN0aW9uVG9rZW48U3ViamVjdDx2b2lkPj4oXG4gICAgKHR5cGVvZiBuZ0Rldk1vZGUgPT09ICd1bmRlZmluZWQnIHx8IG5nRGV2TW9kZSkgPyAnYm9vdHN0cmFwIGRvbmUgaW5kaWNhdG9yJyA6ICcnLCB7XG4gICAgICBmYWN0b3J5OiAoKSA9PiB7XG4gICAgICAgIHJldHVybiBuZXcgU3ViamVjdDx2b2lkPigpO1xuICAgICAgfVxuICAgIH0pO1xuXG4vKipcbiAqIFRoaXMgYW5kIHRoZSBJTklUSUFMX05BVklHQVRJT04gdG9rZW4gYXJlIHVzZWQgaW50ZXJuYWxseSBvbmx5LiBUaGUgcHVibGljIEFQSSBzaWRlIG9mIHRoaXMgaXNcbiAqIGNvbmZpZ3VyZWQgdGhyb3VnaCB0aGUgYEV4dHJhT3B0aW9uc2AuXG4gKlxuICogV2hlbiBzZXQgdG8gYEVuYWJsZWRCbG9ja2luZ2AsIHRoZSBpbml0aWFsIG5hdmlnYXRpb24gc3RhcnRzIGJlZm9yZSB0aGUgcm9vdFxuICogY29tcG9uZW50IGlzIGNyZWF0ZWQuIFRoZSBib290c3RyYXAgaXMgYmxvY2tlZCB1bnRpbCB0aGUgaW5pdGlhbCBuYXZpZ2F0aW9uIGlzIGNvbXBsZXRlLiBUaGlzXG4gKiB2YWx1ZSBpcyByZXF1aXJlZCBmb3IgW3NlcnZlci1zaWRlIHJlbmRlcmluZ10oZ3VpZGUvdW5pdmVyc2FsKSB0byB3b3JrLlxuICpcbiAqIFdoZW4gc2V0IHRvIGBFbmFibGVkTm9uQmxvY2tpbmdgLCB0aGUgaW5pdGlhbCBuYXZpZ2F0aW9uIHN0YXJ0cyBhZnRlciB0aGUgcm9vdCBjb21wb25lbnQgaGFzIGJlZW5cbiAqIGNyZWF0ZWQuIFRoZSBib290c3RyYXAgaXMgbm90IGJsb2NrZWQgb24gdGhlIGNvbXBsZXRpb24gb2YgdGhlIGluaXRpYWwgbmF2aWdhdGlvbi5cbiAqXG4gKiBXaGVuIHNldCB0byBgRGlzYWJsZWRgLCB0aGUgaW5pdGlhbCBuYXZpZ2F0aW9uIGlzIG5vdCBwZXJmb3JtZWQuIFRoZSBsb2NhdGlvbiBsaXN0ZW5lciBpcyBzZXQgdXBcbiAqIGJlZm9yZSB0aGUgcm9vdCBjb21wb25lbnQgZ2V0cyBjcmVhdGVkLiBVc2UgaWYgdGhlcmUgaXMgYSByZWFzb24gdG8gaGF2ZSBtb3JlIGNvbnRyb2wgb3ZlciB3aGVuXG4gKiB0aGUgcm91dGVyIHN0YXJ0cyBpdHMgaW5pdGlhbCBuYXZpZ2F0aW9uIGR1ZSB0byBzb21lIGNvbXBsZXggaW5pdGlhbGl6YXRpb24gbG9naWMuXG4gKlxuICogQHNlZSBgRXh0cmFPcHRpb25zYFxuICovXG5jb25zdCBlbnVtIEluaXRpYWxOYXZpZ2F0aW9uIHtcbiAgRW5hYmxlZEJsb2NraW5nLFxuICBFbmFibGVkTm9uQmxvY2tpbmcsXG4gIERpc2FibGVkLFxufVxuXG5jb25zdCBJTklUSUFMX05BVklHQVRJT04gPSBuZXcgSW5qZWN0aW9uVG9rZW48SW5pdGlhbE5hdmlnYXRpb24+KFxuICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpID8gJ2luaXRpYWwgbmF2aWdhdGlvbicgOiAnJyxcbiAgICB7cHJvdmlkZWRJbjogJ3Jvb3QnLCBmYWN0b3J5OiAoKSA9PiBJbml0aWFsTmF2aWdhdGlvbi5FbmFibGVkTm9uQmxvY2tpbmd9KTtcblxuLyoqXG4gKiBBIHR5cGUgYWxpYXMgZm9yIHByb3ZpZGVycyByZXR1cm5lZCBieSBgd2l0aEVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uYCBmb3IgdXNlIHdpdGhcbiAqIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAc2VlIGB3aXRoRW5hYmxlZEJsb2NraW5nSW5pdGlhbE5hdmlnYXRpb25gXG4gKiBAc2VlIGBwcm92aWRlUm91dGVyYFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IHR5cGUgRW5hYmxlZEJsb2NraW5nSW5pdGlhbE5hdmlnYXRpb25GZWF0dXJlID1cbiAgICBSb3V0ZXJGZWF0dXJlPFJvdXRlckZlYXR1cmVLaW5kLkVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uRmVhdHVyZT47XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIGZvciBwcm92aWRlcnMgcmV0dXJuZWQgYnkgYHdpdGhFbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbmAgb3JcbiAqIGB3aXRoRGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbmAgZnVuY3Rpb25zIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHNlZSBgd2l0aEVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uYFxuICogQHNlZSBgd2l0aERpc2FibGVkSW5pdGlhbE5hdmlnYXRpb25gXG4gKiBAc2VlIGBwcm92aWRlUm91dGVyYFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IHR5cGUgSW5pdGlhbE5hdmlnYXRpb25GZWF0dXJlID1cbiAgICBFbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmV8RGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmU7XG5cbi8qKlxuICogQ29uZmlndXJlcyBpbml0aWFsIG5hdmlnYXRpb24gdG8gc3RhcnQgYmVmb3JlIHRoZSByb290IGNvbXBvbmVudCBpcyBjcmVhdGVkLlxuICpcbiAqIFRoZSBib290c3RyYXAgaXMgYmxvY2tlZCB1bnRpbCB0aGUgaW5pdGlhbCBuYXZpZ2F0aW9uIGlzIGNvbXBsZXRlLiBUaGlzIHZhbHVlIGlzIHJlcXVpcmVkIGZvclxuICogW3NlcnZlci1zaWRlIHJlbmRlcmluZ10oZ3VpZGUvdW5pdmVyc2FsKSB0byB3b3JrLlxuICpcbiAqIEB1c2FnZU5vdGVzXG4gKlxuICogQmFzaWMgZXhhbXBsZSBvZiBob3cgeW91IGNhbiBlbmFibGUgdGhpcyBuYXZpZ2F0aW9uIGJlaGF2aW9yOlxuICogYGBgXG4gKiBjb25zdCBhcHBSb3V0ZXM6IFJvdXRlcyA9IFtdO1xuICogYm9vdHN0cmFwQXBwbGljYXRpb24oQXBwQ29tcG9uZW50LFxuICogICB7XG4gKiAgICAgcHJvdmlkZXJzOiBbXG4gKiAgICAgICBwcm92aWRlUm91dGVyKGFwcFJvdXRlcywgd2l0aEVuYWJsZWRCbG9ja2luZ0luaXRpYWxOYXZpZ2F0aW9uKCkpXG4gKiAgICAgXVxuICogICB9XG4gKiApO1xuICogYGBgXG4gKlxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdpdGhFbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbigpOiBFbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmUge1xuICBjb25zdCBwcm92aWRlcnMgPSBbXG4gICAge3Byb3ZpZGU6IElOSVRJQUxfTkFWSUdBVElPTiwgdXNlVmFsdWU6IEluaXRpYWxOYXZpZ2F0aW9uLkVuYWJsZWRCbG9ja2luZ30sXG4gICAge1xuICAgICAgcHJvdmlkZTogQVBQX0lOSVRJQUxJWkVSLFxuICAgICAgbXVsdGk6IHRydWUsXG4gICAgICBkZXBzOiBbSW5qZWN0b3JdLFxuICAgICAgdXNlRmFjdG9yeTogKGluamVjdG9yOiBJbmplY3RvcikgPT4ge1xuICAgICAgICBjb25zdCBsb2NhdGlvbkluaXRpYWxpemVkOiBQcm9taXNlPGFueT4gPVxuICAgICAgICAgICAgaW5qZWN0b3IuZ2V0KExPQ0FUSU9OX0lOSVRJQUxJWkVELCBQcm9taXNlLnJlc29sdmUoKSk7XG5cbiAgICAgICAgcmV0dXJuICgpID0+IHtcbiAgICAgICAgICByZXR1cm4gbG9jYXRpb25Jbml0aWFsaXplZC50aGVuKCgpID0+IHtcbiAgICAgICAgICAgIHJldHVybiBuZXcgUHJvbWlzZShyZXNvbHZlID0+IHtcbiAgICAgICAgICAgICAgY29uc3Qgcm91dGVyID0gaW5qZWN0b3IuZ2V0KFJvdXRlcik7XG4gICAgICAgICAgICAgIGNvbnN0IGJvb3RzdHJhcERvbmUgPSBpbmplY3Rvci5nZXQoQk9PVFNUUkFQX0RPTkUpO1xuICAgICAgICAgICAgICBhZnRlck5leHROYXZpZ2F0aW9uKHJvdXRlciwgKCkgPT4ge1xuICAgICAgICAgICAgICAgIC8vIFVuYmxvY2sgQVBQX0lOSVRJQUxJWkVSIGluIGNhc2UgdGhlIGluaXRpYWwgbmF2aWdhdGlvbiB3YXMgY2FuY2VsZWQgb3IgZXJyb3JlZFxuICAgICAgICAgICAgICAgIC8vIHdpdGhvdXQgYSByZWRpcmVjdC5cbiAgICAgICAgICAgICAgICByZXNvbHZlKHRydWUpO1xuICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICBpbmplY3Rvci5nZXQoTmF2aWdhdGlvblRyYW5zaXRpb25zKS5hZnRlclByZWFjdGl2YXRpb24gPSAoKSA9PiB7XG4gICAgICAgICAgICAgICAgLy8gVW5ibG9jayBBUFBfSU5JVElBTElaRVIgb25jZSB3ZSBnZXQgdG8gYGFmdGVyUHJlYWN0aXZhdGlvbmAuIEF0IHRoaXMgcG9pbnQsIHdlXG4gICAgICAgICAgICAgICAgLy8gYXNzdW1lIGFjdGl2YXRpb24gd2lsbCBjb21wbGV0ZSBzdWNjZXNzZnVsbHkgKGV2ZW4gdGhvdWdoIHRoaXMgaXMgbm90XG4gICAgICAgICAgICAgICAgLy8gZ3VhcmFudGVlZCkuXG4gICAgICAgICAgICAgICAgcmVzb2x2ZSh0cnVlKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gYm9vdHN0cmFwRG9uZS5jbG9zZWQgPyBvZih2b2lkIDApIDogYm9vdHN0cmFwRG9uZTtcbiAgICAgICAgICAgICAgfTtcbiAgICAgICAgICAgICAgcm91dGVyLmluaXRpYWxOYXZpZ2F0aW9uKCk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfTtcbiAgICAgIH1cbiAgICB9LFxuICBdO1xuICByZXR1cm4gcm91dGVyRmVhdHVyZShSb3V0ZXJGZWF0dXJlS2luZC5FbmFibGVkQmxvY2tpbmdJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIGZvciBwcm92aWRlcnMgcmV0dXJuZWQgYnkgYHdpdGhEaXNhYmxlZEluaXRpYWxOYXZpZ2F0aW9uYCBmb3IgdXNlIHdpdGhcbiAqIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAc2VlIGB3aXRoRGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbmBcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgdHlwZSBEaXNhYmxlZEluaXRpYWxOYXZpZ2F0aW9uRmVhdHVyZSA9XG4gICAgUm91dGVyRmVhdHVyZTxSb3V0ZXJGZWF0dXJlS2luZC5EaXNhYmxlZEluaXRpYWxOYXZpZ2F0aW9uRmVhdHVyZT47XG5cbi8qKlxuICogRGlzYWJsZXMgaW5pdGlhbCBuYXZpZ2F0aW9uLlxuICpcbiAqIFVzZSBpZiB0aGVyZSBpcyBhIHJlYXNvbiB0byBoYXZlIG1vcmUgY29udHJvbCBvdmVyIHdoZW4gdGhlIHJvdXRlciBzdGFydHMgaXRzIGluaXRpYWwgbmF2aWdhdGlvblxuICogZHVlIHRvIHNvbWUgY29tcGxleCBpbml0aWFsaXphdGlvbiBsb2dpYy5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIEJhc2ljIGV4YW1wbGUgb2YgaG93IHlvdSBjYW4gZGlzYWJsZSBpbml0aWFsIG5hdmlnYXRpb246XG4gKiBgYGBcbiAqIGNvbnN0IGFwcFJvdXRlczogUm91dGVzID0gW107XG4gKiBib290c3RyYXBBcHBsaWNhdGlvbihBcHBDb21wb25lbnQsXG4gKiAgIHtcbiAqICAgICBwcm92aWRlcnM6IFtcbiAqICAgICAgIHByb3ZpZGVSb3V0ZXIoYXBwUm91dGVzLCB3aXRoRGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbigpKVxuICogICAgIF1cbiAqICAgfVxuICogKTtcbiAqIGBgYFxuICpcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHJldHVybnMgQSBzZXQgb2YgcHJvdmlkZXJzIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gd2l0aERpc2FibGVkSW5pdGlhbE5hdmlnYXRpb24oKTogRGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmUge1xuICBjb25zdCBwcm92aWRlcnMgPSBbXG4gICAge1xuICAgICAgcHJvdmlkZTogQVBQX0lOSVRJQUxJWkVSLFxuICAgICAgbXVsdGk6IHRydWUsXG4gICAgICB1c2VGYWN0b3J5OiAoKSA9PiB7XG4gICAgICAgIGNvbnN0IHJvdXRlciA9IGluamVjdChSb3V0ZXIpO1xuICAgICAgICByZXR1cm4gKCkgPT4ge1xuICAgICAgICAgIHJvdXRlci5zZXRVcExvY2F0aW9uQ2hhbmdlTGlzdGVuZXIoKTtcbiAgICAgICAgfTtcbiAgICAgIH1cbiAgICB9LFxuICAgIHtwcm92aWRlOiBJTklUSUFMX05BVklHQVRJT04sIHVzZVZhbHVlOiBJbml0aWFsTmF2aWdhdGlvbi5EaXNhYmxlZH1cbiAgXTtcbiAgcmV0dXJuIHJvdXRlckZlYXR1cmUoUm91dGVyRmVhdHVyZUtpbmQuRGlzYWJsZWRJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIGZvciBwcm92aWRlcnMgcmV0dXJuZWQgYnkgYHdpdGhEZWJ1Z1RyYWNpbmdgIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHNlZSBgd2l0aERlYnVnVHJhY2luZ2BcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgdHlwZSBEZWJ1Z1RyYWNpbmdGZWF0dXJlID0gUm91dGVyRmVhdHVyZTxSb3V0ZXJGZWF0dXJlS2luZC5EZWJ1Z1RyYWNpbmdGZWF0dXJlPjtcblxuLyoqXG4gKiBFbmFibGVzIGxvZ2dpbmcgb2YgYWxsIGludGVybmFsIG5hdmlnYXRpb24gZXZlbnRzIHRvIHRoZSBjb25zb2xlLlxuICogRXh0cmEgbG9nZ2luZyBtaWdodCBiZSB1c2VmdWwgZm9yIGRlYnVnZ2luZyBwdXJwb3NlcyB0byBpbnNwZWN0IFJvdXRlciBldmVudCBzZXF1ZW5jZS5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIEJhc2ljIGV4YW1wbGUgb2YgaG93IHlvdSBjYW4gZW5hYmxlIGRlYnVnIHRyYWNpbmc6XG4gKiBgYGBcbiAqIGNvbnN0IGFwcFJvdXRlczogUm91dGVzID0gW107XG4gKiBib290c3RyYXBBcHBsaWNhdGlvbihBcHBDb21wb25lbnQsXG4gKiAgIHtcbiAqICAgICBwcm92aWRlcnM6IFtcbiAqICAgICAgIHByb3ZpZGVSb3V0ZXIoYXBwUm91dGVzLCB3aXRoRGVidWdUcmFjaW5nKCkpXG4gKiAgICAgXVxuICogICB9XG4gKiApO1xuICogYGBgXG4gKlxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB3aXRoRGVidWdUcmFjaW5nKCk6IERlYnVnVHJhY2luZ0ZlYXR1cmUge1xuICBsZXQgcHJvdmlkZXJzOiBQcm92aWRlcltdID0gW107XG4gIGlmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpIHtcbiAgICBwcm92aWRlcnMgPSBbe1xuICAgICAgcHJvdmlkZTogRU5WSVJPTk1FTlRfSU5JVElBTElaRVIsXG4gICAgICBtdWx0aTogdHJ1ZSxcbiAgICAgIHVzZUZhY3Rvcnk6ICgpID0+IHtcbiAgICAgICAgY29uc3Qgcm91dGVyID0gaW5qZWN0KFJvdXRlcik7XG4gICAgICAgIHJldHVybiAoKSA9PiByb3V0ZXIuZXZlbnRzLnN1YnNjcmliZSgoZTogRXZlbnQpID0+IHtcbiAgICAgICAgICAvLyB0c2xpbnQ6ZGlzYWJsZTpuby1jb25zb2xlXG4gICAgICAgICAgY29uc29sZS5ncm91cD8uKGBSb3V0ZXIgRXZlbnQ6ICR7KDxhbnk+ZS5jb25zdHJ1Y3RvcikubmFtZX1gKTtcbiAgICAgICAgICBjb25zb2xlLmxvZyhzdHJpbmdpZnlFdmVudChlKSk7XG4gICAgICAgICAgY29uc29sZS5sb2coZSk7XG4gICAgICAgICAgY29uc29sZS5ncm91cEVuZD8uKCk7XG4gICAgICAgICAgLy8gdHNsaW50OmVuYWJsZTpuby1jb25zb2xlXG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH1dO1xuICB9IGVsc2Uge1xuICAgIHByb3ZpZGVycyA9IFtdO1xuICB9XG4gIHJldHVybiByb3V0ZXJGZWF0dXJlKFJvdXRlckZlYXR1cmVLaW5kLkRlYnVnVHJhY2luZ0ZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbmNvbnN0IFJPVVRFUl9QUkVMT0FERVIgPSBuZXcgSW5qZWN0aW9uVG9rZW48Um91dGVyUHJlbG9hZGVyPihcbiAgICAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSA/ICdyb3V0ZXIgcHJlbG9hZGVyJyA6ICcnKTtcblxuLyoqXG4gKiBBIHR5cGUgYWxpYXMgdGhhdCByZXByZXNlbnRzIGEgZmVhdHVyZSB3aGljaCBlbmFibGVzIHByZWxvYWRpbmcgaW4gUm91dGVyLlxuICogVGhlIHR5cGUgaXMgdXNlZCB0byBkZXNjcmliZSB0aGUgcmV0dXJuIHZhbHVlIG9mIHRoZSBgd2l0aFByZWxvYWRpbmdgIGZ1bmN0aW9uLlxuICpcbiAqIEBzZWUgYHdpdGhQcmVsb2FkaW5nYFxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIFByZWxvYWRpbmdGZWF0dXJlID0gUm91dGVyRmVhdHVyZTxSb3V0ZXJGZWF0dXJlS2luZC5QcmVsb2FkaW5nRmVhdHVyZT47XG5cbi8qKlxuICogQWxsb3dzIHRvIGNvbmZpZ3VyZSBhIHByZWxvYWRpbmcgc3RyYXRlZ3kgdG8gdXNlLiBUaGUgc3RyYXRlZ3kgaXMgY29uZmlndXJlZCBieSBwcm92aWRpbmcgYVxuICogcmVmZXJlbmNlIHRvIGEgY2xhc3MgdGhhdCBpbXBsZW1lbnRzIGEgYFByZWxvYWRpbmdTdHJhdGVneWAuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBCYXNpYyBleGFtcGxlIG9mIGhvdyB5b3UgY2FuIGNvbmZpZ3VyZSBwcmVsb2FkaW5nOlxuICogYGBgXG4gKiBjb25zdCBhcHBSb3V0ZXM6IFJvdXRlcyA9IFtdO1xuICogYm9vdHN0cmFwQXBwbGljYXRpb24oQXBwQ29tcG9uZW50LFxuICogICB7XG4gKiAgICAgcHJvdmlkZXJzOiBbXG4gKiAgICAgICBwcm92aWRlUm91dGVyKGFwcFJvdXRlcywgd2l0aFByZWxvYWRpbmcoUHJlbG9hZEFsbE1vZHVsZXMpKVxuICogICAgIF1cbiAqICAgfVxuICogKTtcbiAqIGBgYFxuICpcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHBhcmFtIHByZWxvYWRpbmdTdHJhdGVneSBBIHJlZmVyZW5jZSB0byBhIGNsYXNzIHRoYXQgaW1wbGVtZW50cyBhIGBQcmVsb2FkaW5nU3RyYXRlZ3lgIHRoYXRcbiAqICAgICBzaG91bGQgYmUgdXNlZC5cbiAqIEByZXR1cm5zIEEgc2V0IG9mIHByb3ZpZGVycyBmb3IgdXNlIHdpdGggYHByb3ZpZGVSb3V0ZXJgLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdpdGhQcmVsb2FkaW5nKHByZWxvYWRpbmdTdHJhdGVneTogVHlwZTxQcmVsb2FkaW5nU3RyYXRlZ3k+KTogUHJlbG9hZGluZ0ZlYXR1cmUge1xuICBjb25zdCBwcm92aWRlcnMgPSBbXG4gICAge3Byb3ZpZGU6IFJPVVRFUl9QUkVMT0FERVIsIHVzZUV4aXN0aW5nOiBSb3V0ZXJQcmVsb2FkZXJ9LFxuICAgIHtwcm92aWRlOiBQcmVsb2FkaW5nU3RyYXRlZ3ksIHVzZUV4aXN0aW5nOiBwcmVsb2FkaW5nU3RyYXRlZ3l9LFxuICBdO1xuICByZXR1cm4gcm91dGVyRmVhdHVyZShSb3V0ZXJGZWF0dXJlS2luZC5QcmVsb2FkaW5nRmVhdHVyZSwgcHJvdmlkZXJzKTtcbn1cblxuLyoqXG4gKiBBIHR5cGUgYWxpYXMgZm9yIHByb3ZpZGVycyByZXR1cm5lZCBieSBgd2l0aFJvdXRlckNvbmZpZ2AgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAc2VlIGB3aXRoUm91dGVyQ29uZmlnYFxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIFJvdXRlckNvbmZpZ3VyYXRpb25GZWF0dXJlID1cbiAgICBSb3V0ZXJGZWF0dXJlPFJvdXRlckZlYXR1cmVLaW5kLlJvdXRlckNvbmZpZ3VyYXRpb25GZWF0dXJlPjtcblxuLyoqXG4gKiBBbGxvd3MgdG8gcHJvdmlkZSBleHRyYSBwYXJhbWV0ZXJzIHRvIGNvbmZpZ3VyZSBSb3V0ZXIuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBCYXNpYyBleGFtcGxlIG9mIGhvdyB5b3UgY2FuIHByb3ZpZGUgZXh0cmEgY29uZmlndXJhdGlvbiBvcHRpb25zOlxuICogYGBgXG4gKiBjb25zdCBhcHBSb3V0ZXM6IFJvdXRlcyA9IFtdO1xuICogYm9vdHN0cmFwQXBwbGljYXRpb24oQXBwQ29tcG9uZW50LFxuICogICB7XG4gKiAgICAgcHJvdmlkZXJzOiBbXG4gKiAgICAgICBwcm92aWRlUm91dGVyKGFwcFJvdXRlcywgd2l0aFJvdXRlckNvbmZpZyh7XG4gKiAgICAgICAgICBvblNhbWVVcmxOYXZpZ2F0aW9uOiAncmVsb2FkJ1xuICogICAgICAgfSkpXG4gKiAgICAgXVxuICogICB9XG4gKiApO1xuICogYGBgXG4gKlxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcGFyYW0gb3B0aW9ucyBBIHNldCBvZiBwYXJhbWV0ZXJzIHRvIGNvbmZpZ3VyZSBSb3V0ZXIsIHNlZSBgUm91dGVyQ29uZmlnT3B0aW9uc2AgZm9yXG4gKiAgICAgYWRkaXRpb25hbCBpbmZvcm1hdGlvbi5cbiAqIEByZXR1cm5zIEEgc2V0IG9mIHByb3ZpZGVycyBmb3IgdXNlIHdpdGggYHByb3ZpZGVSb3V0ZXJgLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdpdGhSb3V0ZXJDb25maWcob3B0aW9uczogUm91dGVyQ29uZmlnT3B0aW9ucyk6IFJvdXRlckNvbmZpZ3VyYXRpb25GZWF0dXJlIHtcbiAgY29uc3QgcHJvdmlkZXJzID0gW1xuICAgIHtwcm92aWRlOiBST1VURVJfQ09ORklHVVJBVElPTiwgdXNlVmFsdWU6IG9wdGlvbnN9LFxuICBdO1xuICByZXR1cm4gcm91dGVyRmVhdHVyZShSb3V0ZXJGZWF0dXJlS2luZC5Sb3V0ZXJDb25maWd1cmF0aW9uRmVhdHVyZSwgcHJvdmlkZXJzKTtcbn1cblxuLyoqXG4gKiBBIHR5cGUgYWxpYXMgZm9yIHByb3ZpZGVycyByZXR1cm5lZCBieSBgd2l0aEhhc2hMb2NhdGlvbmAgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAc2VlIGB3aXRoSGFzaExvY2F0aW9uYFxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIFJvdXRlckhhc2hMb2NhdGlvbkZlYXR1cmUgPSBSb3V0ZXJGZWF0dXJlPFJvdXRlckZlYXR1cmVLaW5kLlJvdXRlckhhc2hMb2NhdGlvbkZlYXR1cmU+O1xuXG4vKipcbiAqIFByb3ZpZGVzIHRoZSBsb2NhdGlvbiBzdHJhdGVneSB0aGF0IHVzZXMgdGhlIFVSTCBmcmFnbWVudCBpbnN0ZWFkIG9mIHRoZSBoaXN0b3J5IEFQSS5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIEJhc2ljIGV4YW1wbGUgb2YgaG93IHlvdSBjYW4gdXNlIHRoZSBoYXNoIGxvY2F0aW9uIG9wdGlvbjpcbiAqIGBgYFxuICogY29uc3QgYXBwUm91dGVzOiBSb3V0ZXMgPSBbXTtcbiAqIGJvb3RzdHJhcEFwcGxpY2F0aW9uKEFwcENvbXBvbmVudCxcbiAqICAge1xuICogICAgIHByb3ZpZGVyczogW1xuICogICAgICAgcHJvdmlkZVJvdXRlcihhcHBSb3V0ZXMsIHdpdGhIYXNoTG9jYXRpb24oKSlcbiAqICAgICBdXG4gKiAgIH1cbiAqICk7XG4gKiBgYGBcbiAqXG4gKiBAc2VlIGBwcm92aWRlUm91dGVyYFxuICogQHNlZSBgSGFzaExvY2F0aW9uU3RyYXRlZ3lgXG4gKlxuICogQHJldHVybnMgQSBzZXQgb2YgcHJvdmlkZXJzIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gd2l0aEhhc2hMb2NhdGlvbigpOiBSb3V0ZXJDb25maWd1cmF0aW9uRmVhdHVyZSB7XG4gIGNvbnN0IHByb3ZpZGVycyA9IFtcbiAgICB7cHJvdmlkZTogTG9jYXRpb25TdHJhdGVneSwgdXNlQ2xhc3M6IEhhc2hMb2NhdGlvblN0cmF0ZWd5fSxcbiAgXTtcbiAgcmV0dXJuIHJvdXRlckZlYXR1cmUoUm91dGVyRmVhdHVyZUtpbmQuUm91dGVyQ29uZmlndXJhdGlvbkZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIGZvciBwcm92aWRlcnMgcmV0dXJuZWQgYnkgYHdpdGhOYXZpZ2F0aW9uRXJyb3JIYW5kbGVyYCBmb3IgdXNlIHdpdGggYHByb3ZpZGVSb3V0ZXJgLlxuICpcbiAqIEBzZWUgYHdpdGhOYXZpZ2F0aW9uRXJyb3JIYW5kbGVyYFxuICogQHNlZSBgcHJvdmlkZVJvdXRlcmBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCB0eXBlIE5hdmlnYXRpb25FcnJvckhhbmRsZXJGZWF0dXJlID1cbiAgICBSb3V0ZXJGZWF0dXJlPFJvdXRlckZlYXR1cmVLaW5kLk5hdmlnYXRpb25FcnJvckhhbmRsZXJGZWF0dXJlPjtcblxuLyoqXG4gKiBTdWJzY3JpYmVzIHRvIHRoZSBSb3V0ZXIncyBuYXZpZ2F0aW9uIGV2ZW50cyBhbmQgY2FsbHMgdGhlIGdpdmVuIGZ1bmN0aW9uIHdoZW4gYVxuICogYE5hdmlnYXRpb25FcnJvcmAgaGFwcGVucy5cbiAqXG4gKiBUaGlzIGZ1bmN0aW9uIGlzIHJ1biBpbnNpZGUgYXBwbGljYXRpb24ncyBpbmplY3Rpb24gY29udGV4dCBzbyB5b3UgY2FuIHVzZSB0aGUgYGluamVjdGAgZnVuY3Rpb24uXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBCYXNpYyBleGFtcGxlIG9mIGhvdyB5b3UgY2FuIHVzZSB0aGUgZXJyb3IgaGFuZGxlciBvcHRpb246XG4gKiBgYGBcbiAqIGNvbnN0IGFwcFJvdXRlczogUm91dGVzID0gW107XG4gKiBib290c3RyYXBBcHBsaWNhdGlvbihBcHBDb21wb25lbnQsXG4gKiAgIHtcbiAqICAgICBwcm92aWRlcnM6IFtcbiAqICAgICAgIHByb3ZpZGVSb3V0ZXIoYXBwUm91dGVzLCB3aXRoTmF2aWdhdGlvbkVycm9ySGFuZGxlcigoZTogTmF2aWdhdGlvbkVycm9yKSA9PlxuICogaW5qZWN0KE15RXJyb3JUcmFja2VyKS50cmFja0Vycm9yKGUpKSlcbiAqICAgICBdXG4gKiAgIH1cbiAqICk7XG4gKiBgYGBcbiAqXG4gKiBAc2VlIGBOYXZpZ2F0aW9uRXJyb3JgXG4gKiBAc2VlIGBpbmplY3RgXG4gKiBAc2VlIGBFbnZpcm9ubWVudEluamVjdG9yI3J1bkluQ29udGV4dGBcbiAqXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB3aXRoTmF2aWdhdGlvbkVycm9ySGFuZGxlcihmbjogKGVycm9yOiBOYXZpZ2F0aW9uRXJyb3IpID0+IHZvaWQpOlxuICAgIE5hdmlnYXRpb25FcnJvckhhbmRsZXJGZWF0dXJlIHtcbiAgY29uc3QgcHJvdmlkZXJzID0gW3tcbiAgICBwcm92aWRlOiBFTlZJUk9OTUVOVF9JTklUSUFMSVpFUixcbiAgICBtdWx0aTogdHJ1ZSxcbiAgICB1c2VWYWx1ZTogKCkgPT4ge1xuICAgICAgY29uc3QgaW5qZWN0b3IgPSBpbmplY3QoRW52aXJvbm1lbnRJbmplY3Rvcik7XG4gICAgICBpbmplY3QoUm91dGVyKS5ldmVudHMuc3Vic2NyaWJlKChlKSA9PiB7XG4gICAgICAgIGlmIChlIGluc3RhbmNlb2YgTmF2aWdhdGlvbkVycm9yKSB7XG4gICAgICAgICAgaW5qZWN0b3IucnVuSW5Db250ZXh0KCgpID0+IGZuKGUpKTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfVxuICB9XTtcbiAgcmV0dXJuIHJvdXRlckZlYXR1cmUoUm91dGVyRmVhdHVyZUtpbmQuTmF2aWdhdGlvbkVycm9ySGFuZGxlckZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIGZvciBwcm92aWRlcnMgcmV0dXJuZWQgYnkgYHdpdGhDb21wb25lbnRJbnB1dEJpbmRpbmdgIGZvciB1c2Ugd2l0aCBgcHJvdmlkZVJvdXRlcmAuXG4gKlxuICogQHNlZSBgd2l0aENvbXBvbmVudElucHV0QmluZGluZ2BcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgdHlwZSBDb21wb25lbnRJbnB1dEJpbmRpbmdGZWF0dXJlID1cbiAgICBSb3V0ZXJGZWF0dXJlPFJvdXRlckZlYXR1cmVLaW5kLkNvbXBvbmVudElucHV0QmluZGluZ0ZlYXR1cmU+O1xuXG4vKipcbiAqIEVuYWJsZXMgYmluZGluZyBpbmZvcm1hdGlvbiBmcm9tIHRoZSBgUm91dGVyYCBzdGF0ZSBkaXJlY3RseSB0byB0aGUgaW5wdXRzIG9mIHRoZSBjb21wb25lbnQgaW5cbiAqIGBSb3V0ZWAgY29uZmlndXJhdGlvbnMuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBCYXNpYyBleGFtcGxlIG9mIGhvdyB5b3UgY2FuIGVuYWJsZSB0aGUgZmVhdHVyZTpcbiAqIGBgYFxuICogY29uc3QgYXBwUm91dGVzOiBSb3V0ZXMgPSBbXTtcbiAqIGJvb3RzdHJhcEFwcGxpY2F0aW9uKEFwcENvbXBvbmVudCxcbiAqICAge1xuICogICAgIHByb3ZpZGVyczogW1xuICogICAgICAgcHJvdmlkZVJvdXRlcihhcHBSb3V0ZXMsIHdpdGhDb21wb25lbnRJbnB1dEJpbmRpbmcoKSlcbiAqICAgICBdXG4gKiAgIH1cbiAqICk7XG4gKiBgYGBcbiAqXG4gKiBAcmV0dXJucyBBIHNldCBvZiBwcm92aWRlcnMgZm9yIHVzZSB3aXRoIGBwcm92aWRlUm91dGVyYC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHdpdGhDb21wb25lbnRJbnB1dEJpbmRpbmcoKTogQ29tcG9uZW50SW5wdXRCaW5kaW5nRmVhdHVyZSB7XG4gIGNvbnN0IHByb3ZpZGVycyA9IFtcbiAgICBSb3V0ZWRDb21wb25lbnRJbnB1dEJpbmRlcixcbiAgICB7cHJvdmlkZTogSU5QVVRfQklOREVSLCB1c2VFeGlzdGluZzogUm91dGVkQ29tcG9uZW50SW5wdXRCaW5kZXJ9LFxuICBdO1xuXG4gIHJldHVybiByb3V0ZXJGZWF0dXJlKFJvdXRlckZlYXR1cmVLaW5kLkNvbXBvbmVudElucHV0QmluZGluZ0ZlYXR1cmUsIHByb3ZpZGVycyk7XG59XG5cbi8qKlxuICogQSB0eXBlIGFsaWFzIHRoYXQgcmVwcmVzZW50cyBhbGwgUm91dGVyIGZlYXR1cmVzIGF2YWlsYWJsZSBmb3IgdXNlIHdpdGggYHByb3ZpZGVSb3V0ZXJgLlxuICogRmVhdHVyZXMgY2FuIGJlIGVuYWJsZWQgYnkgYWRkaW5nIHNwZWNpYWwgZnVuY3Rpb25zIHRvIHRoZSBgcHJvdmlkZVJvdXRlcmAgY2FsbC5cbiAqIFNlZSBkb2N1bWVudGF0aW9uIGZvciBlYWNoIHN5bWJvbCB0byBmaW5kIGNvcnJlc3BvbmRpbmcgZnVuY3Rpb24gbmFtZS4gU2VlIGFsc28gYHByb3ZpZGVSb3V0ZXJgXG4gKiBkb2N1bWVudGF0aW9uIG9uIGhvdyB0byB1c2UgdGhvc2UgZnVuY3Rpb25zLlxuICpcbiAqIEBzZWUgYHByb3ZpZGVSb3V0ZXJgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgdHlwZSBSb3V0ZXJGZWF0dXJlcyA9XG4gICAgUHJlbG9hZGluZ0ZlYXR1cmV8RGVidWdUcmFjaW5nRmVhdHVyZXxJbml0aWFsTmF2aWdhdGlvbkZlYXR1cmV8SW5NZW1vcnlTY3JvbGxpbmdGZWF0dXJlfFxuICAgIFJvdXRlckNvbmZpZ3VyYXRpb25GZWF0dXJlfE5hdmlnYXRpb25FcnJvckhhbmRsZXJGZWF0dXJlfENvbXBvbmVudElucHV0QmluZGluZ0ZlYXR1cmU7XG5cbi8qKlxuICogVGhlIGxpc3Qgb2YgZmVhdHVyZXMgYXMgYW4gZW51bSB0byB1bmlxdWVseSB0eXBlIGVhY2ggZmVhdHVyZS5cbiAqL1xuZXhwb3J0IGNvbnN0IGVudW0gUm91dGVyRmVhdHVyZUtpbmQge1xuICBQcmVsb2FkaW5nRmVhdHVyZSxcbiAgRGVidWdUcmFjaW5nRmVhdHVyZSxcbiAgRW5hYmxlZEJsb2NraW5nSW5pdGlhbE5hdmlnYXRpb25GZWF0dXJlLFxuICBEaXNhYmxlZEluaXRpYWxOYXZpZ2F0aW9uRmVhdHVyZSxcbiAgSW5NZW1vcnlTY3JvbGxpbmdGZWF0dXJlLFxuICBSb3V0ZXJDb25maWd1cmF0aW9uRmVhdHVyZSxcbiAgUm91dGVySGFzaExvY2F0aW9uRmVhdHVyZSxcbiAgTmF2aWdhdGlvbkVycm9ySGFuZGxlckZlYXR1cmUsXG4gIENvbXBvbmVudElucHV0QmluZGluZ0ZlYXR1cmUsXG59XG4iXX0=