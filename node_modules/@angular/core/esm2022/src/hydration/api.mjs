/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { first } from 'rxjs/operators';
import { APP_BOOTSTRAP_LISTENER, ApplicationRef } from '../application_ref';
import { ENABLED_SSR_FEATURES, PLATFORM_ID } from '../application_tokens';
import { Console } from '../console';
import { ENVIRONMENT_INITIALIZER, Injector, makeEnvironmentProviders } from '../di';
import { inject } from '../di/injector_compatibility';
import { formatRuntimeError } from '../errors';
import { InitialRenderPendingTasks } from '../initial_render_pending_tasks';
import { enableLocateOrCreateContainerRefImpl } from '../linker/view_container_ref';
import { enableLocateOrCreateElementNodeImpl } from '../render3/instructions/element';
import { enableLocateOrCreateElementContainerNodeImpl } from '../render3/instructions/element_container';
import { enableApplyRootElementTransformImpl } from '../render3/instructions/shared';
import { enableLocateOrCreateContainerAnchorImpl } from '../render3/instructions/template';
import { enableLocateOrCreateTextNodeImpl } from '../render3/instructions/text';
import { TransferState } from '../transfer_state';
import { cleanupDehydratedViews } from './cleanup';
import { IS_HYDRATION_DOM_REUSE_ENABLED, PRESERVE_HOST_CONTENT } from './tokens';
import { enableRetrieveHydrationInfoImpl, NGH_DATA_KEY } from './utils';
import { enableFindMatchingDehydratedViewImpl } from './views';
/**
 * Indicates whether the hydration-related code was added,
 * prevents adding it multiple times.
 */
let isHydrationSupportEnabled = false;
/**
 * Brings the necessary hydration code in tree-shakable manner.
 * The code is only present when the `provideClientHydration` is
 * invoked. Otherwise, this code is tree-shaken away during the
 * build optimization step.
 *
 * This technique allows us to swap implementations of methods so
 * tree shaking works appropriately when hydration is disabled or
 * enabled. It brings in the appropriate version of the method that
 * supports hydration only when enabled.
 */
function enableHydrationRuntimeSupport() {
    if (!isHydrationSupportEnabled) {
        isHydrationSupportEnabled = true;
        enableRetrieveHydrationInfoImpl();
        enableLocateOrCreateElementNodeImpl();
        enableLocateOrCreateTextNodeImpl();
        enableLocateOrCreateElementContainerNodeImpl();
        enableLocateOrCreateContainerAnchorImpl();
        enableLocateOrCreateContainerRefImpl();
        enableFindMatchingDehydratedViewImpl();
        enableApplyRootElementTransformImpl();
    }
}
/**
 * Detects whether the code is invoked in a browser.
 * Later on, this check should be replaced with a tree-shakable
 * flag (e.g. `!isServer`).
 */
function isBrowser() {
    return inject(PLATFORM_ID) === 'browser';
}
/**
 * Outputs a message with hydration stats into a console.
 */
function printHydrationStats(injector) {
    const console = injector.get(Console);
    const message = `Angular hydrated ${ngDevMode.hydratedComponents} component(s) ` +
        `and ${ngDevMode.hydratedNodes} node(s), ` +
        `${ngDevMode.componentsSkippedHydration} component(s) were skipped. ` +
        `Note: this feature is in Developer Preview mode. ` +
        `Learn more at https://next.angular.io/guide/hydration.`;
    // tslint:disable-next-line:no-console
    console.log(message);
}
/**
 * Returns a Promise that is resolved when an application becomes stable.
 */
function whenStable(appRef, pendingTasks) {
    const isStablePromise = appRef.isStable.pipe(first((isStable) => isStable)).toPromise();
    const pendingTasksPromise = pendingTasks.whenAllTasksComplete;
    return Promise.allSettled([isStablePromise, pendingTasksPromise]);
}
/**
 * Returns a set of providers required to setup hydration support
 * for an application that is server side rendered. This function is
 * included into the `provideClientHydration` public API function from
 * the `platform-browser` package.
 *
 * The function sets up an internal flag that would be recognized during
 * the server side rendering time as well, so there is no need to
 * configure or change anything in NgUniversal to enable the feature.
 */
export function withDomHydration() {
    return makeEnvironmentProviders([
        {
            provide: IS_HYDRATION_DOM_REUSE_ENABLED,
            useFactory: () => {
                let isEnabled = true;
                if (isBrowser()) {
                    // On the client, verify that the server response contains
                    // hydration annotations. Otherwise, keep hydration disabled.
                    const transferState = inject(TransferState, { optional: true });
                    isEnabled = !!transferState?.get(NGH_DATA_KEY, null);
                    if (!isEnabled && (typeof ngDevMode !== 'undefined' && ngDevMode)) {
                        const console = inject(Console);
                        const message = formatRuntimeError(-505 /* RuntimeErrorCode.MISSING_HYDRATION_ANNOTATIONS */, 'Angular hydration was requested on the client, but there was no ' +
                            'serialized information present in the server response, ' +
                            'thus hydration was not enabled. ' +
                            'Make sure the `provideClientHydration()` is included into the list ' +
                            'of providers in the server part of the application configuration.');
                        // tslint:disable-next-line:no-console
                        console.warn(message);
                    }
                }
                if (isEnabled) {
                    inject(ENABLED_SSR_FEATURES).add('hydration');
                }
                return isEnabled;
            },
        },
        {
            provide: ENVIRONMENT_INITIALIZER,
            useValue: () => {
                // Since this function is used across both server and client,
                // make sure that the runtime code is only added when invoked
                // on the client. Moving forward, the `isBrowser` check should
                // be replaced with a tree-shakable alternative (e.g. `isServer`
                // flag).
                if (isBrowser() && inject(IS_HYDRATION_DOM_REUSE_ENABLED)) {
                    enableHydrationRuntimeSupport();
                }
            },
            multi: true,
        },
        {
            provide: PRESERVE_HOST_CONTENT,
            useFactory: () => {
                // Preserve host element content only in a browser
                // environment and when hydration is configured properly.
                // On a server, an application is rendered from scratch,
                // so the host content needs to be empty.
                return isBrowser() && inject(IS_HYDRATION_DOM_REUSE_ENABLED);
            }
        },
        {
            provide: APP_BOOTSTRAP_LISTENER,
            useFactory: () => {
                if (isBrowser() && inject(IS_HYDRATION_DOM_REUSE_ENABLED)) {
                    const appRef = inject(ApplicationRef);
                    const pendingTasks = inject(InitialRenderPendingTasks);
                    const injector = inject(Injector);
                    return () => {
                        whenStable(appRef, pendingTasks).then(() => {
                            // Wait until an app becomes stable and cleanup all views that
                            // were not claimed during the application bootstrap process.
                            // The timing is similar to when we start the serialization process
                            // on the server.
                            cleanupDehydratedViews(appRef);
                            if (typeof ngDevMode !== 'undefined' && ngDevMode) {
                                printHydrationStats(injector);
                            }
                        });
                    };
                }
                return () => { }; // noop
            },
            multi: true,
        }
    ]);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYXBpLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvaHlkcmF0aW9uL2FwaS50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFFSCxPQUFPLEVBQUMsS0FBSyxFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFFckMsT0FBTyxFQUFDLHNCQUFzQixFQUFFLGNBQWMsRUFBQyxNQUFNLG9CQUFvQixDQUFDO0FBQzFFLE9BQU8sRUFBQyxvQkFBb0IsRUFBRSxXQUFXLEVBQUMsTUFBTSx1QkFBdUIsQ0FBQztBQUN4RSxPQUFPLEVBQUMsT0FBTyxFQUFDLE1BQU0sWUFBWSxDQUFDO0FBQ25DLE9BQU8sRUFBQyx1QkFBdUIsRUFBd0IsUUFBUSxFQUFFLHdCQUF3QixFQUFDLE1BQU0sT0FBTyxDQUFDO0FBQ3hHLE9BQU8sRUFBQyxNQUFNLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUNwRCxPQUFPLEVBQUMsa0JBQWtCLEVBQW1CLE1BQU0sV0FBVyxDQUFDO0FBQy9ELE9BQU8sRUFBQyx5QkFBeUIsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQzFFLE9BQU8sRUFBQyxvQ0FBb0MsRUFBQyxNQUFNLDhCQUE4QixDQUFDO0FBQ2xGLE9BQU8sRUFBQyxtQ0FBbUMsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQ3BGLE9BQU8sRUFBQyw0Q0FBNEMsRUFBQyxNQUFNLDJDQUEyQyxDQUFDO0FBQ3ZHLE9BQU8sRUFBQyxtQ0FBbUMsRUFBQyxNQUFNLGdDQUFnQyxDQUFDO0FBQ25GLE9BQU8sRUFBQyx1Q0FBdUMsRUFBQyxNQUFNLGtDQUFrQyxDQUFDO0FBQ3pGLE9BQU8sRUFBQyxnQ0FBZ0MsRUFBQyxNQUFNLDhCQUE4QixDQUFDO0FBQzlFLE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUVoRCxPQUFPLEVBQUMsc0JBQXNCLEVBQUMsTUFBTSxXQUFXLENBQUM7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Q3pDLDhEQUE4RDs0QkFDOUQsNkRBQTZEOzRCQUM3RCxtRUFBbUU7NEJBQ25FLGlCQUFpQjs0QkFDakIsc0JBQXNCLENBQUMsTUFBTSxDQUFDLENBQUM7NEJBRS9CLElBQUksT0FBTyxTQUFTLEtBQUssV0FBVyxJQUFJLFNBQVMsRUFBRTtnQ0FDakQsbUJBQW1CLENBQUMsUUFBUSxDQUFDLENBQUM7NkJBQy9CO3dCQUNILENBQUMsQ0FBQyxDQUFDO29CQUNMLENBQUMsQ0FBQztpQkFDSDtnQkFDRCxPQUFPLEdBQUcsRUFBRSxHQUFFLENBQUMsQ0FBQyxDQUFFLE9BQU87WUFDM0IsQ0FBQztZQUNELEtBQUssRUFBRSxJQUFJO1NBQ1o7S0FDRixDQUFDLENBQUM7QUFDTCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Zmlyc3R9IGZyb20gJ3J4anMvb3BlcmF0b3JzJztcblxuaW1wb3J0IHtBUFBfQk9PVFNUUkFQX0xJU1RFTkVSLCBBcHBsaWNhdGlvblJlZn0gZnJvbSAnLi4vYXBwbGljYXRpb25fcmVmJztcbmltcG9ydCB7RU5BQkxFRF9TU1JfRkVBVFVSRVMsIFBMQVRGT1JNX0lEfSBmcm9tICcuLi9hcHBsaWNhdGlvbl90b2tlbnMnO1xuaW1wb3J0IHtDb25zb2xlfSBmcm9tICcuLi9jb25zb2xlJztcbmltcG9ydCB7RU5WSVJPTk1FTlRfSU5JVElBTElaRVIsIEVudmlyb25tZW50UHJvdmlkZXJzLCBJbmplY3RvciwgbWFrZUVudmlyb25tZW50UHJvdmlkZXJzfSBmcm9tICcuLi9kaSc7XG5pbXBvcnQge2luamVjdH0gZnJvbSAnLi4vZGkvaW5qZWN0b3JfY29tcGF0aWJpbGl0eSc7XG5pbXBvcnQge2Zvcm1hdFJ1bnRpbWVFcnJvciwgUnVudGltZUVycm9yQ29kZX0gZnJvbSAnLi4vZXJyb3JzJztcbmltcG9ydCB7SW5pdGlhbFJlbmRlclBlbmRpbmdUYXNrc30gZnJvbSAnLi4vaW5pdGlhbF9yZW5kZXJfcGVuZGluZ190YXNrcyc7XG5pbXBvcnQge2VuYWJsZUxvY2F0ZU9yQ3JlYXRlQ29udGFpbmVyUmVmSW1wbH0gZnJvbSAnLi4vbGlua2VyL3ZpZXdfY29udGFpbmVyX3JlZic7XG5pbXBvcnQge2VuYWJsZUxvY2F0ZU9yQ3JlYXRlRWxlbWVudE5vZGVJbXBsfSBmcm9tICcuLi9yZW5kZXIzL2luc3RydWN0aW9ucy9lbGVtZW50JztcbmltcG9ydCB7ZW5hYmxlTG9jYXRlT3JDcmVhdGVFbGVtZW50Q29udGFpbmVyTm9kZUltcGx9IGZyb20gJy4uL3JlbmRlcjMvaW5zdHJ1Y3Rpb25zL2VsZW1lbnRfY29udGFpbmVyJztcbmltcG9ydCB7ZW5hYmxlQXBwbHlSb290RWxlbWVudFRyYW5zZm9ybUltcGx9IGZyb20gJy4uL3JlbmRlcjMvaW5zdHJ1Y3Rpb25zL3NoYXJlZCc7XG5pbXBvcnQge2VuYWJsZUxvY2F0ZU9yQ3JlYXRlQ29udGFpbmVyQW5jaG9ySW1wbH0gZnJvbSAnLi4vcmVuZGVyMy9pbnN0cnVjdGlvbnMvdGVtcGxhdGUnO1xuaW1wb3J0IHtlbmFibGVMb2NhdGVPckNyZWF0ZVRleHROb2RlSW1wbH0gZnJvbSAnLi4vcmVuZGVyMy9pbnN0cnVjdGlvbnMvdGV4dCc7XG5pbXBvcnQge1RyYW5zZmVyU3RhdGV9IGZyb20gJy4uL3RyYW5zZmVyX3N0YXRlJztcblxuaW1wb3J0IHtjbGVhbnVwRGVoeWRyYXRlZFZpZXdzfSBmcm9tICcuL2NsZWFudXAnO1xuaW1wb3J0IHtJU19IWURSQVRJT05fRE9NX1JFVVNFX0VOQUJMRUQsIFBSRVNFUlZFX0hPU1RfQ09OVEVOVH0gZnJvbSAnLi90b2tlbnMnO1xuaW1wb3J0IHtlbmFibGVSZXRyaWV2ZUh5ZHJhdGlvbkluZm9JbXBsLCBOR0hfREFUQV9LRVl9IGZyb20gJy4vdXRpbHMnO1xuaW1wb3J0IHtlbmFibGVGaW5kTWF0Y2hpbmdEZWh5ZHJhdGVkVmlld0ltcGx9IGZyb20gJy4vdmlld3MnO1xuXG5cbi8qKlxuICogSW5kaWNhdGVzIHdoZXRoZXIgdGhlIGh5ZHJhdGlvbi1yZWxhdGVkIGNvZGUgd2FzIGFkZGVkLFxuICogcHJldmVudHMgYWRkaW5nIGl0IG11bHRpcGxlIHRpbWVzLlxuICovXG5sZXQgaXNIeWRyYXRpb25TdXBwb3J0RW5hYmxlZCA9IGZhbHNlO1xuXG4vKipcbiAqIEJyaW5ncyB0aGUgbmVjZXNzYXJ5IGh5ZHJhdGlvbiBjb2RlIGluIHRyZWUtc2hha2FibGUgbWFubmVyLlxuICogVGhlIGNvZGUgaXMgb25seSBwcmVzZW50IHdoZW4gdGhlIGBwcm92aWRlQ2xpZW50SHlkcmF0aW9uYCBpc1xuICogaW52b2tlZC4gT3RoZXJ3aXNlLCB0aGlzIGNvZGUgaXMgdHJlZS1zaGFrZW4gYXdheSBkdXJpbmcgdGhlXG4gKiBidWlsZCBvcHRpbWl6YXRpb24gc3RlcC5cbiAqXG4gKiBUaGlzIHRlY2huaXF1ZSBhbGxvd3MgdXMgdG8gc3dhcCBpbXBsZW1lbnRhdGlvbnMgb2YgbWV0aG9kcyBzb1xuICogdHJlZSBzaGFraW5nIHdvcmtzIGFwcHJvcHJpYXRlbHkgd2hlbiBoeWRyYXRpb24gaXMgZGlzYWJsZWQgb3JcbiAqIGVuYWJsZWQuIEl0IGJyaW5ncyBpbiB0aGUgYXBwcm9wcmlhdGUgdmVyc2lvbiBvZiB0aGUgbWV0aG9kIHRoYXRcbiAqIHN1cHBvcnRzIGh5ZHJhdGlvbiBvbmx5IHdoZW4gZW5hYmxlZC5cbiAqL1xuZnVuY3Rpb24gZW5hYmxlSHlkcmF0aW9uUnVudGltZVN1cHBvcnQoKSB7XG4gIGlmICghaXNIeWRyYXRpb25TdXBwb3J0RW5hYmxlZCkge1xuICAgIGlzSHlkcmF0aW9uU3VwcG9ydEVuYWJsZWQgPSB0cnVlO1xuICAgIGVuYWJsZVJldHJpZXZlSHlkcmF0aW9uSW5mb0ltcGwoKTtcbiAgICBlbmFibGVMb2NhdGVPckNyZWF0ZUVsZW1lbnROb2RlSW1wbCgpO1xuICAgIGVuYWJsZUxvY2F0ZU9yQ3JlYXRlVGV4dE5vZGVJbXBsKCk7XG4gICAgZW5hYmxlTG9jYXRlT3JDcmVhdGVFbGVtZW50Q29udGFpbmVyTm9kZUltcGwoKTtcbiAgICBlbmFibGVMb2NhdGVPckNyZWF0ZUNvbnRhaW5lckFuY2hvckltcGwoKTtcbiAgICBlbmFibGVMb2NhdGVPckNyZWF0ZUNvbnRhaW5lclJlZkltcGwoKTtcbiAgICBlbmFibGVGaW5kTWF0Y2hpbmdEZWh5ZHJhdGVkVmlld0ltcGwoKTtcbiAgICBlbmFibGVBcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtSW1wbCgpO1xuICB9XG59XG5cbi8qKlxuICogRGV0ZWN0cyB3aGV0aGVyIHRoZSBjb2RlIGlzIGludm9rZWQgaW4gYSBicm93c2VyLlxuICogTGF0ZXIgb24sIHRoaXMgY2hlY2sgc2hvdWxkIGJlIHJlcGxhY2VkIHdpdGggYSB0cmVlLXNoYWthYmxlXG4gKiBmbGFnIChlLmcuIGAhaXNTZXJ2ZXJgKS5cbiAqL1xuZnVuY3Rpb24gaXNCcm93c2VyKCk6IGJvb2xlYW4ge1xuICByZXR1cm4gaW5qZWN0KFBMQVRGT1JNX0lEKSA9PT0gJ2Jyb3dzZXInO1xufVxuXG4vKipcbiAqIE91dHB1dHMgYSBtZXNzYWdlIHdpdGggaHlkcmF0aW9uIHN0YXRzIGludG8gYSBjb25zb2xlLlxuICovXG5mdW5jdGlvbiBwcmludEh5ZHJhdGlvblN0YXRzKGluamVjdG9yOiBJbmplY3Rvcikge1xuICBjb25zdCBjb25zb2xlID0gaW5qZWN0b3IuZ2V0KENvbnNvbGUpO1xuICBjb25zdCBtZXNzYWdlID0gYEFuZ3VsYXIgaHlkcmF0ZWQgJHtuZ0Rldk1vZGUhLmh5ZHJhdGVkQ29tcG9uZW50c30gY29tcG9uZW50KHMpIGAgK1xuICAgICAgYGFuZCAke25nRGV2TW9kZSEuaHlkcmF0ZWROb2Rlc30gbm9kZShzKSwgYCArXG4gICAgICBgJHtuZ0Rldk1vZGUhLmNvbXBvbmVudHNTa2lwcGVkSHlkcmF0aW9ufSBjb21wb25lbnQocykgd2VyZSBza2lwcGVkLiBgICtcbiAgICAgIGBOb3RlOiB0aGlzIGZlYXR1cmUgaXMgaW4gRGV2ZWxvcGVyIFByZXZpZXcgbW9kZS4gYCArXG4gICAgICBgTGVhcm4gbW9yZSBhdCBodHRwczovL25leHQuYW5ndWxhci5pby9ndWlkZS9oeWRyYXRpb24uYDtcbiAgLy8gdHNsaW50OmRpc2FibGUtbmV4dC1saW5lOm5vLWNvbnNvbGVcbiAgY29uc29sZS5sb2cobWVzc2FnZSk7XG59XG5cblxuLyoqXG4gKiBSZXR1cm5zIGEgUHJvbWlzZSB0aGF0IGlzIHJlc29sdmVkIHdoZW4gYW4gYXBwbGljYXRpb24gYmVjb21lcyBzdGFibGUuXG4gKi9cbmZ1bmN0aW9uIHdoZW5TdGFibGUoXG4gICAgYXBwUmVmOiBBcHBsaWNhdGlvblJlZiwgcGVuZGluZ1Rhc2tzOiBJbml0aWFsUmVuZGVyUGVuZGluZ1Rhc2tzKTogUHJvbWlzZTx1bmtub3duPiB7XG4gIGNvbnN0IGlzU3RhYmxlUHJvbWlzZSA9IGFwcFJlZi5pc1N0YWJsZS5waXBlKGZpcnN0KChpc1N0YWJsZTogYm9vbGVhbikgPT4gaXNTdGFibGUpKS50b1Byb21pc2UoKTtcbiAgY29uc3QgcGVuZGluZ1Rhc2tzUHJvbWlzZSA9IHBlbmRpbmdUYXNrcy53aGVuQWxsVGFza3NDb21wbGV0ZTtcbiAgcmV0dXJuIFByb21pc2UuYWxsU2V0dGxlZChbaXNTdGFibGVQcm9taXNlLCBwZW5kaW5nVGFza3NQcm9taXNlXSk7XG59XG5cbi8qKlxuICogUmV0dXJucyBhIHNldCBvZiBwcm92aWRlcnMgcmVxdWlyZWQgdG8gc2V0dXAgaHlkcmF0aW9uIHN1cHBvcnRcbiAqIGZvciBhbiBhcHBsaWNhdGlvbiB0aGF0IGlzIHNlcnZlciBzaWRlIHJlbmRlcmVkLiBUaGlzIGZ1bmN0aW9uIGlzXG4gKiBpbmNsdWRlZCBpbnRvIHRoZSBgcHJvdmlkZUNsaWVudEh5ZHJhdGlvbmAgcHVibGljIEFQSSBmdW5jdGlvbiBmcm9tXG4gKiB0aGUgYHBsYXRmb3JtLWJyb3dzZXJgIHBhY2thZ2UuXG4gKlxuICogVGhlIGZ1bmN0aW9uIHNldHMgdXAgYW4gaW50ZXJuYWwgZmxhZyB0aGF0IHdvdWxkIGJlIHJlY29nbml6ZWQgZHVyaW5nXG4gKiB0aGUgc2VydmVyIHNpZGUgcmVuZGVyaW5nIHRpbWUgYXMgd2VsbCwgc28gdGhlcmUgaXMgbm8gbmVlZCB0b1xuICogY29uZmlndXJlIG9yIGNoYW5nZSBhbnl0aGluZyBpbiBOZ1VuaXZlcnNhbCB0byBlbmFibGUgdGhlIGZlYXR1cmUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiB3aXRoRG9tSHlkcmF0aW9uKCk6IEVudmlyb25tZW50UHJvdmlkZXJzIHtcbiAgcmV0dXJuIG1ha2VFbnZpcm9ubWVudFByb3ZpZGVycyhbXG4gICAge1xuICAgICAgcHJvdmlkZTogSVNfSFlEUkFUSU9OX0RPTV9SRVVTRV9FTkFCTEVELFxuICAgICAgdXNlRmFjdG9yeTogKCkgPT4ge1xuICAgICAgICBsZXQgaXNFbmFibGVkID0gdHJ1ZTtcbiAgICAgICAgaWYgKGlzQnJvd3NlcigpKSB7XG4gICAgICAgICAgLy8gT24gdGhlIGNsaWVudCwgdmVyaWZ5IHRoYXQgdGhlIHNlcnZlciByZXNwb25zZSBjb250YWluc1xuICAgICAgICAgIC8vIGh5ZHJhdGlvbiBhbm5vdGF0aW9ucy4gT3RoZXJ3aXNlLCBrZWVwIGh5ZHJhdGlvbiBkaXNhYmxlZC5cbiAgICAgICAgICBjb25zdCB0cmFuc2ZlclN0YXRlID0gaW5qZWN0KFRyYW5zZmVyU3RhdGUsIHtvcHRpb25hbDogdHJ1ZX0pO1xuICAgICAgICAgIGlzRW5hYmxlZCA9ICEhdHJhbnNmZXJTdGF0ZT8uZ2V0KE5HSF9EQVRBX0tFWSwgbnVsbCk7XG4gICAgICAgICAgaWYgKCFpc0VuYWJsZWQgJiYgKHR5cGVvZiBuZ0Rldk1vZGUgIT09ICd1bmRlZmluZWQnICYmIG5nRGV2TW9kZSkpIHtcbiAgICAgICAgICAgIGNvbnN0IGNvbnNvbGUgPSBpbmplY3QoQ29uc29sZSk7XG4gICAgICAgICAgICBjb25zdCBtZXNzYWdlID0gZm9ybWF0UnVudGltZUVycm9yKFxuICAgICAgICAgICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuTUlTU0lOR19IWURSQVRJT05fQU5OT1RBVElPTlMsXG4gICAgICAgICAgICAgICAgJ0FuZ3VsYXIgaHlkcmF0aW9uIHdhcyByZXF1ZXN0ZWQgb24gdGhlIGNsaWVudCwgYnV0IHRoZXJlIHdhcyBubyAnICtcbiAgICAgICAgICAgICAgICAgICAgJ3NlcmlhbGl6ZWQgaW5mb3JtYXRpb24gcHJlc2VudCBpbiB0aGUgc2VydmVyIHJlc3BvbnNlLCAnICtcbiAgICAgICAgICAgICAgICAgICAgJ3RodXMgaHlkcmF0aW9uIHdhcyBub3QgZW5hYmxlZC4gJyArXG4gICAgICAgICAgICAgICAgICAgICdNYWtlIHN1cmUgdGhlIGBwcm92aWRlQ2xpZW50SHlkcmF0aW9uKClgIGlzIGluY2x1ZGVkIGludG8gdGhlIGxpc3QgJyArXG4gICAgICAgICAgICAgICAgICAgICdvZiBwcm92aWRlcnMgaW4gdGhlIHNlcnZlciBwYXJ0IG9mIHRoZSBhcHBsaWNhdGlvbiBjb25maWd1cmF0aW9uLicpO1xuICAgICAgICAgICAgLy8gdHNsaW50OmRpc2FibGUtbmV4dC1saW5lOm5vLWNvbnNvbGVcbiAgICAgICAgICAgIGNvbnNvbGUud2FybihtZXNzYWdlKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgaWYgKGlzRW5hYmxlZCkge1xuICAgICAgICAgIGluamVjdChFTkFCTEVEX1NTUl9GRUFUVVJFUykuYWRkKCdoeWRyYXRpb24nKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gaXNFbmFibGVkO1xuICAgICAgfSxcbiAgICB9LFxuICAgIHtcbiAgICAgIHByb3ZpZGU6IEVOVklST05NRU5UX0lOSVRJQUxJWkVSLFxuICAgICAgdXNlVmFsdWU6ICgpID0+IHtcbiAgICAgICAgLy8gU2luY2UgdGhpcyBmdW5jdGlvbiBpcyB1c2VkIGFjcm9zcyBib3RoIHNlcnZlciBhbmQgY2xpZW50LFxuICAgICAgICAvLyBtYWtlIHN1cmUgdGhhdCB0aGUgcnVudGltZSBjb2RlIGlzIG9ubHkgYWRkZWQgd2hlbiBpbnZva2VkXG4gICAgICAgIC8vIG9uIHRoZSBjbGllbnQuIE1vdmluZyBmb3J3YXJkLCB0aGUgYGlzQnJvd3NlcmAgY2hlY2sgc2hvdWxkXG4gICAgICAgIC8vIGJlIHJlcGxhY2VkIHdpdGggYSB0cmVlLXNoYWthYmxlIGFsdGVybmF0aXZlIChlLmcuIGBpc1NlcnZlcmBcbiAgICAgICAgLy8gZmxhZykuXG4gICAgICAgIGlmIChpc0Jyb3dzZXIoKSAmJiBpbmplY3QoSVNfSFlEUkFUSU9OX0RPTV9SRVVTRV9FTkFCTEVEKSkge1xuICAgICAgICAgIGVuYWJsZUh5ZHJhdGlvblJ1bnRpbWVTdXBwb3J0KCk7XG4gICAgICAgIH1cbiAgICAgIH0sXG4gICAgICBtdWx0aTogdHJ1ZSxcbiAgICB9LFxuICAgIHtcbiAgICAgIHByb3ZpZGU6IFBSRVNFUlZFX0hPU1RfQ09OVEVOVCxcbiAgICAgIHVzZUZhY3Rvcnk6ICgpID0+IHtcbiAgICAgICAgLy8gUHJlc2VydmUgaG9zdCBlbGVtZW50IGNvbnRlbnQgb25seSBpbiBhIGJyb3dzZXJcbiAgICAgICAgLy8gZW52aXJvbm1lbnQgYW5kIHdoZW4gaHlkcmF0aW9uIGlzIGNvbmZpZ3VyZWQgcHJvcGVybHkuXG4gICAgICAgIC8vIE9uIGEgc2VydmVyLCBhbiBhcHBsaWNhdGlvbiBpcyByZW5kZXJlZCBmcm9tIHNjcmF0Y2gsXG4gICAgICAgIC8vIHNvIHRoZSBob3N0IGNvbnRlbnQgbmVlZHMgdG8gYmUgZW1wdHkuXG4gICAgICAgIHJldHVybiBpc0Jyb3dzZXIoKSAmJiBpbmplY3QoSVNfSFlEUkFUSU9OX0RPTV9SRVVTRV9FTkFCTEVEKTtcbiAgICAgIH1cbiAgICB9LFxuICAgIHtcbiAgICAgIHByb3ZpZGU6IEFQUF9CT09UU1RSQVBfTElTVEVORVIsXG4gICAgICB1c2VGYWN0b3J5OiAoKSA9PiB7XG4gICAgICAgIGlmIChpc0Jyb3dzZXIoKSAmJiBpbmplY3QoSVNfSFlEUkFUSU9OX0RPTV9SRVVTRV9FTkFCTEVEKSkge1xuICAgICAgICAgIGNvbnN0IGFwcFJlZiA9IGluamVjdChBcHBsaWNhdGlvblJlZik7XG4gICAgICAgICAgY29uc3QgcGVuZGluZ1Rhc2tzID0gaW5qZWN0KEluaXRpYWxSZW5kZXJQZW5kaW5nVGFza3MpO1xuICAgICAgICAgIGNvbnN0IGluamVjdG9yID0gaW5qZWN0KEluamVjdG9yKTtcbiAgICAgICAgICByZXR1cm4gKCkgPT4ge1xuICAgICAgICAgICAgd2hlblN0YWJsZShhcHBSZWYsIHBlbmRpbmdUYXNrcykudGhlbigoKSA9PiB7XG4gICAgICAgICAgICAgIC8vIFdhaXQgdW50aWwgYW4gYXBwIGJlY29tZXMgc3RhYmxlIGFuZCBjbGVhbnVwIGFsbCB2aWV3cyB0aGF0XG4gICAgICAgICAgICAgIC8vIHdlcmUgbm90IGNsYWltZWQgZHVyaW5nIHRoZSBhcHBsaWNhdGlvbiBib290c3RyYXAgcHJvY2Vzcy5cbiAgICAgICAgICAgICAgLy8gVGhlIHRpbWluZyBpcyBzaW1pbGFyIHRvIHdoZW4gd2Ugc3RhcnQgdGhlIHNlcmlhbGl6YXRpb24gcHJvY2Vzc1xuICAgICAgICAgICAgICAvLyBvbiB0aGUgc2VydmVyLlxuICAgICAgICAgICAgICBjbGVhbnVwRGVoeWRyYXRlZFZpZXdzKGFwcFJlZik7XG5cbiAgICAgICAgICAgICAgaWYgKHR5cGVvZiBuZ0Rldk1vZGUgIT09ICd1bmRlZmluZWQnICYmIG5nRGV2TW9kZSkge1xuICAgICAgICAgICAgICAgIHByaW50SHlkcmF0aW9uU3RhdHMoaW5qZWN0b3IpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9O1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiAoKSA9PiB7fTsgIC8vIG5vb3BcbiAgICAgIH0sXG4gICAgICBtdWx0aTogdHJ1ZSxcbiAgICB9XG4gIF0pO1xufVxuIl19