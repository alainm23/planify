/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵRuntimeError as RuntimeError } from '@angular/core';
import { from, of } from 'rxjs';
import { catchError, concatMap, defaultIfEmpty, first, last as rxjsLast, map, mergeMap, scan, switchMap, tap } from 'rxjs/operators';
import { absoluteRedirect, AbsoluteRedirect, ApplyRedirects, canLoadFails, noMatch, NoMatch } from './apply_redirects';
import { createUrlTreeFromSnapshot } from './create_url_tree';
import { runCanLoadGuards } from './operators/check_guards';
import { ActivatedRouteSnapshot, inheritedParamsDataResolve, RouterStateSnapshot } from './router_state';
import { PRIMARY_OUTLET } from './shared';
import { UrlSegmentGroup } from './url_tree';
import { last } from './utils/collection';
import { getOutlet, sortByMatchingOutlets } from './utils/config';
import { isImmediateMatch, match, matchWithChecks, noLeftoversInUrl, split } from './utils/config_matching';
import { TreeNode } from './utils/tree';
import { isEmptyError } from './utils/type_guards';
export function recognize(injector, configLoader, rootComponentType, config, urlTree, urlSerializer, paramsInheritanceStrategy = 'emptyOnly') {
    return new Recognizer(injector, configLoader, rootComponentType, config, urlTree, paramsInheritanceStrategy, urlSerializer)
        .recognize();
}
export class Recognizer {
    constructor(injector, configLoader, rootComponentType, config, urlTree, paramsInheritanceStrategy, urlSerializer) {
        this.injector = injector;
        this.configLoader = configLoader;
        this.rootComponentType = rootComponentType;
        this.config = config;
        this.urlTree = urlTree;
        this.paramsInheritanceStrategy = paramsInheritanceStrategy;
        this.urlSerializer = urlSerializer;
        this.allowRedirects = true;
        this.applyRedirects = new ApplyRedirects(this.urlSerializer, this.urlTree);
    }
    noMatchError(e) {
        return new RuntimeError(4002 /* RuntimeErrorCode.NO_MATCH */, (typeof ngDevMode === 'undefined' || ngDevMode) &&
            `Cannot match any routes. URL Segment: '${e.segmentGroup}'`);
    }
    recognize() {
        const rootSegmentGroup = split(this.urlTree.root, [], [], this.config).segmentGroup;
        return this.processSegmentGroup(this.injector, this.config, rootSegmentGroup, PRIMARY_OUTLET)
            .pipe(catchError((e) => {
            if (e instanceof AbsoluteRedirect) {
                // After an absolute redirect we do not apply any more redirects!
                // If this implementation changes, update the documentation note in `redirectTo`.
                this.allowRedirects = false;
                this.urlTree = e.urlTree;
                return this.match(e.urlTree);
            }
            if (e instanceof NoMatch) {
                throw this.noMatchError(e);
            }
            throw e;
        }), map(children => {
            // Use Object.freeze to prevent readers of the Router state from modifying it outside
            // of a navigation, resulting in the router being out of sync with the browser.
            const root = new ActivatedRouteSnapshot([], Object.freeze({}), Object.freeze({ ...this.urlTree.queryParams }), this.urlTree.fragment, {}, PRIMARY_OUTLET, this.rootComponentType, null, {});
            const rootNode = new TreeNode(root, children);
            const routeState = new RouterStateSnapshot('', rootNode);
            const tree = createUrlTreeFromSnapshot(root, [], this.urlTree.queryParams, this.urlTree.fragment);
            // https://github.com/angular/angular/issues/47307
            // Creating the tree stringifies the query params
            // We don't want to do this here so reassign them to the original.
            tree.queryParams = this.urlTree.queryParams;
            routeState.url = this.urlSerializer.serialize(tree);
            this.inheritParamsAndData(routeState._root);
            return { state: routeState, tree };
        }));
    }
    match(tree) {
        const expanded$ = this.processSegmentGroup(this.injector, this.config, tree.root, PRIMARY_OUTLET);
        return expanded$.pipe(catchError((e) => {
            if (e instanceof NoMatch) {
                throw this.noMatchError(e);
            }
            throw e;
        }));
    }
    inheritParamsAndData(routeNode) {
        const route = routeNode.value;
        const i = inheritedParamsDataResolve(route, this.paramsInheritanceStrategy);
        route.params = Object.freeze(i.params);
        route.data = Object.freeze(i.data);
        routeNode.children.forEach(n => this.inheritParamsAndData(n));
    }
    processSegmentGroup(injector, config, segmentGroup, outlet) {
        if (segmentGroup.segments.length === 0 && segmentGroup.hasChildren()) {
            return this.processChildren(injector, config, segmentGroup);
        }
        return this.processSegment(injector, config, segmentGroup, segmentGroup.segments, outlet, true);
    }
    /**
     * Matches every child outlet in the `segmentGroup` to a `Route` in the config. Returns `null` if
     * we cannot find a match for _any_ of the children.
     *
     * @param config - The `Routes` to match against
     * @param segmentGroup - The `UrlSegmentGroup` whose children need to be matched against the
     *     config.
     */
    processChildren(injector, config, segmentGroup) {
        // Expand outlets one at a time, starting with the primary outlet. We need to do it this way
        // because an absolute redirect from the primary outlet takes precedence.
        const childOutlets = [];
        for (const child of Object.keys(segmentGroup.children)) {
            if (child === 'primary') {
                childOutlets.unshift(child);
            }
            else {
                childOutlets.push(child);
            }
        }
        return from(childOutlets)
            .pipe(concatMap(childOutlet => {
            const child = segmentGroup.children[childOutlet];
            // Sort the config so that routes with outlets that match the one being activated
            // appear first, followed by routes for other outlets, which might match if they have
            // an empty path.
            const sortedConfig = sortByMatchingOutlets(config, childOutlet);
            return this.processSegmentGroup(injector, sortedConfig, child, childOutlet);
        }), scan((children, outletChildren) => {
            children.push(...outletChildren);
            return children;
        }), defaultIfEmpty(null), rxjsLast(), mergeMap(children => {
            if (children === null)
                return noMatch(segmentGroup);
            // Because we may have matched two outlets to the same empty path segment, we can have
            // multiple activated results for the same outlet. We should merge the children of
            // these results so the final return value is only one `TreeNode` per outlet.
            const mergedChildren = mergeEmptyPathMatches(children);
            if (typeof ngDevMode === 'undefined' || ngDevMode) {
                // This should really never happen - we are only taking the first match for each
                // outlet and merge the empty path matches.
                checkOutletNameUniqueness(mergedChildren);
            }
            sortActivatedRouteSnapshots(mergedChildren);
            return of(mergedChildren);
        }));
    }
    processSegment(injector, routes, segmentGroup, segments, outlet, allowRedirects) {
        return from(routes).pipe(concatMap(r => {
            return this
                .processSegmentAgainstRoute(r._injector ?? injector, routes, r, segmentGroup, segments, outlet, allowRedirects)
                .pipe(catchError((e) => {
                if (e instanceof NoMatch) {
                    return of(null);
                }
                throw e;
            }));
        }), first((x) => !!x), catchError(e => {
            if (isEmptyError(e)) {
                if (noLeftoversInUrl(segmentGroup, segments, outlet)) {
                    return of([]);
                }
                return noMatch(segmentGroup);
            }
            throw e;
        }));
    }
    processSegmentAgainstRoute(injector, routes, route, rawSegment, segments, outlet, allowRedirects) {
        if (!isImmediateMatch(route, rawSegment, segments, outlet))
            return noMatch(rawSegment);
        if (route.redirectTo === undefined) {
            return this.matchSegmentAgainstRoute(injector, rawSegment, route, segments, outlet, allowRedirects);
        }
        if (allowRedirects && this.allowRedirects) {
            return this.expandSegmentAgainstRouteUsingRedirect(injector, rawSegment, routes, route, segments, outlet);
        }
        return noMatch(rawSegment);
    }
    expandSegmentAgainstRouteUsingRedirect(injector, segmentGroup, routes, route, segments, outlet) {
        if (route.path === '**') {
            return this.expandWildCardWithParamsAgainstRouteUsingRedirect(injector, routes, route, outlet);
        }
        return this.expandRegularSegmentAgainstRouteUsingRedirect(injector, segmentGroup, routes, route, segments, outlet);
    }
    expandWildCardWithParamsAgainstRouteUsingRedirect(injector, routes, route, outlet) {
        const newTree = this.applyRedirects.applyRedirectCommands([], route.redirectTo, {});
        if (route.redirectTo.startsWith('/')) {
            return absoluteRedirect(newTree);
        }
        return this.applyRedirects.lineralizeSegments(route, newTree)
            .pipe(mergeMap((newSegments) => {
            const group = new UrlSegmentGroup(newSegments, {});
            return this.processSegment(injector, routes, group, newSegments, outlet, false);
        }));
    }
    expandRegularSegmentAgainstRouteUsingRedirect(injector, segmentGroup, routes, route, segments, outlet) {
        const { matched, consumedSegments, remainingSegments, positionalParamSegments } = match(segmentGroup, route, segments);
        if (!matched)
            return noMatch(segmentGroup);
        const newTree = this.applyRedirects.applyRedirectCommands(consumedSegments, route.redirectTo, positionalParamSegments);
        if (route.redirectTo.startsWith('/')) {
            return absoluteRedirect(newTree);
        }
        return this.applyRedirects.lineralizeSegments(route, newTree)
            .pipe(mergeMap((newSegments) => {
            return this.processSegment(injector, routes, segmentGroup, newSegments.concat(remainingSegments), outlet, false);
        }));
    }
    matchSegmentAgainstRoute(injector, rawSegment, route, segments, outlet, allowRedirects) {
        let matchResult;
        if (route.path === '**') {
            const params = segments.length > 0 ? last(segments).parameters : {};
            const snapshot = new ActivatedRouteSnapshot(segments, params, Object.freeze({ ...this.urlTree.queryParams }), this.urlTree.fragment, getData(route), getOutlet(route), route.component ?? route._loadedComponent ?? null, route, getResolve(route));
            matchResult = of({
                snapshot,
                consumedSegments: [],
                remainingSegments: [],
            });
            // Prior versions of the route matching algorithm would stop matching at the wildcard route.
            // We should investigate a better strategy for any existing children. Otherwise, these
            // child segments are silently dropped from the navigation.
            // https://github.com/angular/angular/issues/40089
            rawSegment.children = {};
        }
        else {
            matchResult =
                matchWithChecks(rawSegment, route, segments, injector, this.urlSerializer)
                    .pipe(map(({ matched, consumedSegments, remainingSegments, parameters }) => {
                    if (!matched) {
                        return null;
                    }
                    const snapshot = new ActivatedRouteSnapshot(consumedSegments, parameters, Object.freeze({ ...this.urlTree.queryParams }), this.urlTree.fragment, getData(route), getOutlet(route), route.component ?? route._loadedComponent ?? null, route, getResolve(route));
                    return { snapshot, consumedSegments, remainingSegments };
                }));
        }
        return matchResult.pipe(switchMap((result) => {
            if (result === null) {
                return noMatch(rawSegment);
            }
            // If the route has an injector created from providers, we should start using that.
            injector = route._injector ?? injector;
            return this.getChildConfig(injector, route, segments)
                .pipe(switchMap(({ routes: childConfig }) => {
                const childInjector = route._loadedInjector ?? injector;
                const { snapshot, consumedSegments, remainingSegments } = result;
                const { segmentGroup, slicedSegments } = split(rawSegment, consumedSegments, remainingSegments, childConfig);
                if (slicedSegments.length === 0 && segmentGroup.hasChildren()) {
                    return this.processChildren(childInjector, childConfig, segmentGroup)
                        .pipe(map(children => {
                        if (children === null) {
                            return null;
                        }
                        return [new TreeNode(snapshot, children)];
                    }));
                }
                if (childConfig.length === 0 && slicedSegments.length === 0) {
                    return of([new TreeNode(snapshot, [])]);
                }
                const matchedOnOutlet = getOutlet(route) === outlet;
                // If we matched a config due to empty path match on a different outlet, we need to
                // continue passing the current outlet for the segment rather than switch to PRIMARY.
                // Note that we switch to primary when we have a match because outlet configs look like
                // this: {path: 'a', outlet: 'a', children: [
                //  {path: 'b', component: B},
                //  {path: 'c', component: C},
                // ]}
                // Notice that the children of the named outlet are configured with the primary outlet
                return this
                    .processSegment(childInjector, childConfig, segmentGroup, slicedSegments, matchedOnOutlet ? PRIMARY_OUTLET : outlet, true)
                    .pipe(map(children => {
                    return [new TreeNode(snapshot, children)];
                }));
            }));
        }));
    }
    getChildConfig(injector, route, segments) {
        if (route.children) {
            // The children belong to the same module
            return of({ routes: route.children, injector });
        }
        if (route.loadChildren) {
            // lazy children belong to the loaded module
            if (route._loadedRoutes !== undefined) {
                return of({ routes: route._loadedRoutes, injector: route._loadedInjector });
            }
            return runCanLoadGuards(injector, route, segments, this.urlSerializer)
                .pipe(mergeMap((shouldLoadResult) => {
                if (shouldLoadResult) {
                    return this.configLoader.loadChildren(injector, route)
                        .pipe(tap((cfg) => {
                        route._loadedRoutes = cfg.routes;
                        route._loadedInjector = cfg.injector;
                    }));
                }
                return canLoadFails(route);
            }));
        }
        return of({ routes: [], injector });
    }
}
function sortActivatedRouteSnapshots(nodes) {
    nodes.sort((a, b) => {
        if (a.value.outlet === PRIMARY_OUTLET)
            return -1;
        if (b.value.outlet === PRIMARY_OUTLET)
            return 1;
        return a.value.outlet.localeCompare(b.value.outlet);
    });
}
function hasEmptyPathConfig(node) {
    const config = node.value.routeConfig;
    return config && config.path === '';
}
/**
 * Finds `TreeNode`s with matching empty path route configs and merges them into `TreeNode` with
 * the children from each duplicate. This is necessary because different outlets can match a
 * single empty path route config and the results need to then be merged.
 */
function mergeEmptyPathMatches(nodes) {
    const result = [];
    // The set of nodes which contain children that were merged from two duplicate empty path nodes.
    const mergedNodes = new Set();
    for (const node of nodes) {
        if (!hasEmptyPathConfig(node)) {
            result.push(node);
            continue;
        }
        const duplicateEmptyPathNode = result.find(resultNode => node.value.routeConfig === resultNode.value.routeConfig);
        if (duplicateEmptyPathNode !== undefined) {
            duplicateEmptyPathNode.children.push(...node.children);
            mergedNodes.add(duplicateEmptyPathNode);
        }
        else {
            result.push(node);
        }
    }
    // For each node which has children from multiple sources, we need to recompute a new `TreeNode`
    // by also merging those children. This is necessary when there are multiple empty path configs
    // in a row. Put another way: whenever we combine children of two nodes, we need to also check
    // if any of those children can be combined into a single node as well.
    for (const mergedNode of mergedNodes) {
        const mergedChildren = mergeEmptyPathMatches(mergedNode.children);
        result.push(new TreeNode(mergedNode.value, mergedChildren));
    }
    return result.filter(n => !mergedNodes.has(n));
}
function checkOutletNameUniqueness(nodes) {
    const names = {};
    nodes.forEach(n => {
        const routeWithSameOutletName = names[n.value.outlet];
        if (routeWithSameOutletName) {
            const p = routeWithSameOutletName.url.map(s => s.toString()).join('/');
            const c = n.value.url.map(s => s.toString()).join('/');
            throw new RuntimeError(4006 /* RuntimeErrorCode.TWO_SEGMENTS_WITH_SAME_OUTLET */, (typeof ngDevMode === 'undefined' || ngDevMode) &&
                `Two segments cannot have the same outlet name: '${p}' and '${c}'.`);
        }
        names[n.value.outlet] = n.value;
    });
}
function getData(route) {
    return route.data || {};
}
function getResolve(route) {
    return route.resolve || {};
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicmVjb2duaXplLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvcm91dGVyL3NyYy9yZWNvZ25pemUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUE0QixhQUFhLElBQUksWUFBWSxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQ3ZGLE9BQU8sRUFBQyxJQUFJLEVBQWMsRUFBRSxFQUFDLE1BQU0sTUFBTSxDQUFDO0FBQzFDLE9BQU8sRUFBQyxVQUFVLEVBQUUsU0FBUyxFQUFFLGNBQWMsRUFBRSxLQUFLLEVBQUUsSUFBSSxJQUFJLFFBQVEsRUFBRSxHQUFHLEVBQUUsUUFBUSxFQUFFLElBQUksRUFBRSxTQUFTLEVBQUUsR0FBRyxFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFFbkksT0FBTyxFQUFDLGdCQUFnQixFQUFFLGdCQUFnQixFQUFFLGNBQWMsRUFBRSxZQUFZLEVBQUUsT0FBTyxFQUFFLE9BQU8sRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBQ3JILE9BQU8sRUFBQyx5QkFBeUIsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBRzVELE9BQU8sRUFBQyxnQkFBZ0IsRUFBQyxNQUFNLDBCQUEwQixDQUFDO0FBRTFELE9BQU8sRUFBQyxzQkFBc0IsRUFBRSwwQkFBMEIsRUFBNkIsbUJBQW1CLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUNsSSxPQUFPLEVBQUMsY0FBYyxFQUFDLE1BQU0sVUFBVSxDQUFDO0FBQ3hDLE9BQU8sRUFBYSxlQUFlLEVBQXlCLE1BQU0sWUFBWSxDQUFDO0FBQy9FLE9BQU8sRUFBQyxJQUFJLEVBQUMsTUFBTSxvQkFBb0IsQ0FBQztBQUN4QyxPQUFPLEVBQUMsU0FBUyxFQUFFLHFCQUFxQixFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFDaEUsT0FBTyxFQUFDLGdCQUFnQixFQUFFLEtBQUssRUFBRSxlQUFlLEVBQUUsZ0JBQWdCLEVBQUUsS0FB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TyxJQUFJLEVBQUUsQ0FBQztBQUM3QixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7RW52aXJvbm1lbnRJbmplY3RvciwgVHlwZSwgybVSdW50aW1lRXJyb3IgYXMgUnVudGltZUVycm9yfSBmcm9tICdAYW5ndWxhci9jb3JlJztcbmltcG9ydCB7ZnJvbSwgT2JzZXJ2YWJsZSwgb2Z9IGZyb20gJ3J4anMnO1xuaW1wb3J0IHtjYXRjaEVycm9yLCBjb25jYXRNYXAsIGRlZmF1bHRJZkVtcHR5LCBmaXJzdCwgbGFzdCBhcyByeGpzTGFzdCwgbWFwLCBtZXJnZU1hcCwgc2Nhbiwgc3dpdGNoTWFwLCB0YXB9IGZyb20gJ3J4anMvb3BlcmF0b3JzJztcblxuaW1wb3J0IHthYnNvbHV0ZVJlZGlyZWN0LCBBYnNvbHV0ZVJlZGlyZWN0LCBBcHBseVJlZGlyZWN0cywgY2FuTG9hZEZhaWxzLCBub01hdGNoLCBOb01hdGNofSBmcm9tICcuL2FwcGx5X3JlZGlyZWN0cyc7XG5pbXBvcnQge2NyZWF0ZVVybFRyZWVGcm9tU25hcHNob3R9IGZyb20gJy4vY3JlYXRlX3VybF90cmVlJztcbmltcG9ydCB7UnVudGltZUVycm9yQ29kZX0gZnJvbSAnLi9lcnJvcnMnO1xuaW1wb3J0IHtEYXRhLCBMb2FkZWRSb3V0ZXJDb25maWcsIFJlc29sdmVEYXRhLCBSb3V0ZSwgUm91dGVzfSBmcm9tICcuL21vZGVscyc7XG5pbXBvcnQge3J1bkNhbkxvYWRHdWFyZHN9IGZyb20gJy4vb3BlcmF0b3JzL2NoZWNrX2d1YXJkcyc7XG5pbXBvcnQge1JvdXRlckNvbmZpZ0xvYWRlcn0gZnJvbSAnLi9yb3V0ZXJfY29uZmlnX2xvYWRlcic7XG5pbXBvcnQge0FjdGl2YXRlZFJvdXRlU25hcHNob3QsIGluaGVyaXRlZFBhcmFtc0RhdGFSZXNvbHZlLCBQYXJhbXNJbmhlcml0YW5jZVN0cmF0ZWd5LCBSb3V0ZXJTdGF0ZVNuYXBzaG90fSBmcm9tICcuL3JvdXRlcl9zdGF0ZSc7XG5pbXBvcnQge1BSSU1BUllfT1VUTEVUfSBmcm9tICcuL3NoYXJlZCc7XG5pbXBvcnQge1VybFNlZ21lbnQsIFVybFNlZ21lbnRHcm91cCwgVXJsU2VyaWFsaXplciwgVXJsVHJlZX0gZnJvbSAnLi91cmxfdHJlZSc7XG5pbXBvcnQge2xhc3R9IGZyb20gJy4vdXRpbHMvY29sbGVjdGlvbic7XG5pbXBvcnQge2dldE91dGxldCwgc29ydEJ5TWF0Y2hpbmdPdXRsZXRzfSBmcm9tICcuL3V0aWxzL2NvbmZpZyc7XG5pbXBvcnQge2lzSW1tZWRpYXRlTWF0Y2gsIG1hdGNoLCBtYXRjaFdpdGhDaGVja3MsIG5vTGVmdG92ZXJzSW5VcmwsIHNwbGl0fSBmcm9tICcuL3V0aWxzL2NvbmZpZ19tYXRjaGluZyc7XG5pbXBvcnQge1RyZWVOb2RlfSBmcm9tICcuL3V0aWxzL3RyZWUnO1xuaW1wb3J0IHtpc0VtcHR5RXJyb3J9IGZyb20gJy4vdXRpbHMvdHlwZV9ndWFyZHMnO1xuXG5cbmV4cG9ydCBmdW5jdGlvbiByZWNvZ25pemUoXG4gICAgaW5qZWN0b3I6IEVudmlyb25tZW50SW5qZWN0b3IsIGNvbmZpZ0xvYWRlcjogUm91dGVyQ29uZmlnTG9hZGVyLFxuICAgIHJvb3RDb21wb25lbnRUeXBlOiBUeXBlPGFueT58bnVsbCwgY29uZmlnOiBSb3V0ZXMsIHVybFRyZWU6IFVybFRyZWUsXG4gICAgdXJsU2VyaWFsaXplcjogVXJsU2VyaWFsaXplcixcbiAgICBwYXJhbXNJbmhlcml0YW5jZVN0cmF0ZWd5OiBQYXJhbXNJbmhlcml0YW5jZVN0cmF0ZWd5ID1cbiAgICAgICAgJ2VtcHR5T25seScpOiBPYnNlcnZhYmxlPHtzdGF0ZTogUm91dGVyU3RhdGVTbmFwc2hvdCwgdHJlZTogVXJsVHJlZX0+IHtcbiAgcmV0dXJuIG5ldyBSZWNvZ25pemVyKFxuICAgICAgICAgICAgIGluamVjdG9yLCBjb25maWdMb2FkZXIsIHJvb3RDb21wb25lbnRUeXBlLCBjb25maWcsIHVybFRyZWUsIHBhcmFtc0luaGVyaXRhbmNlU3RyYXRlZ3ksXG4gICAgICAgICAgICAgdXJsU2VyaWFsaXplcilcbiAgICAgIC5yZWNvZ25pemUoKTtcbn1cblxuZXhwb3J0IGNsYXNzIFJlY29nbml6ZXIge1xuICBhbGxvd1JlZGlyZWN0cyA9IHRydWU7XG4gIHByaXZhdGUgYXBwbHlSZWRpcmVjdHMgPSBuZXcgQXBwbHlSZWRpcmVjdHModGhpcy51cmxTZXJpYWxpemVyLCB0aGlzLnVybFRyZWUpO1xuXG4gIGNvbnN0cnVjdG9yKFxuICAgICAgcHJpdmF0ZSBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3RvciwgcHJpdmF0ZSBjb25maWdMb2FkZXI6IFJvdXRlckNvbmZpZ0xvYWRlcixcbiAgICAgIHByaXZhdGUgcm9vdENvbXBvbmVudFR5cGU6IFR5cGU8YW55PnxudWxsLCBwcml2YXRlIGNvbmZpZzogUm91dGVzLCBwcml2YXRlIHVybFRyZWU6IFVybFRyZWUsXG4gICAgICBwcml2YXRlIHBhcmFtc0luaGVyaXRhbmNlU3RyYXRlZ3k6IFBhcmFtc0luaGVyaXRhbmNlU3RyYXRlZ3ksXG4gICAgICBwcml2YXRlIHJlYWRvbmx5IHVybFNlcmlhbGl6ZXI6IFVybFNlcmlhbGl6ZXIpIHt9XG5cbiAgcHJpdmF0ZSBub01hdGNoRXJyb3IoZTogTm9NYXRjaCk6IGFueSB7XG4gICAgcmV0dXJuIG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuTk9fTUFUQ0gsXG4gICAgICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpICYmXG4gICAgICAgICAgICBgQ2Fubm90IG1hdGNoIGFueSByb3V0ZXMuIFVSTCBTZWdtZW50OiAnJHtlLnNlZ21lbnRHcm91cH0nYCk7XG4gIH1cblxuICByZWNvZ25pemUoKTogT2JzZXJ2YWJsZTx7c3RhdGU6IFJvdXRlclN0YXRlU25hcHNob3QsIHRyZWU6IFVybFRyZWV9PiB7XG4gICAgY29uc3Qgcm9vdFNlZ21lbnRHcm91cCA9IHNwbGl0KHRoaXMudXJsVHJlZS5yb290LCBbXSwgW10sIHRoaXMuY29uZmlnKS5zZWdtZW50R3JvdXA7XG5cbiAgICByZXR1cm4gdGhpcy5wcm9jZXNzU2VnbWVudEdyb3VwKHRoaXMuaW5qZWN0b3IsIHRoaXMuY29uZmlnLCByb290U2VnbWVudEdyb3VwLCBQUklNQVJZX09VVExFVClcbiAgICAgICAgLnBpcGUoXG4gICAgICAgICAgICBjYXRjaEVycm9yKChlOiBhbnkpID0+IHtcbiAgICAgICAgICAgICAgaWYgKGUgaW5zdGFuY2VvZiBBYnNvbHV0ZVJlZGlyZWN0KSB7XG4gICAgICAgICAgICAgICAgLy8gQWZ0ZXIgYW4gYWJzb2x1dGUgcmVkaXJlY3Qgd2UgZG8gbm90IGFwcGx5IGFueSBtb3JlIHJlZGlyZWN0cyFcbiAgICAgICAgICAgICAgICAvLyBJZiB0aGlzIGltcGxlbWVudGF0aW9uIGNoYW5nZXMsIHVwZGF0ZSB0aGUgZG9jdW1lbnRhdGlvbiBub3RlIGluIGByZWRpcmVjdFRvYC5cbiAgICAgICAgICAgICAgICB0aGlzLmFsbG93UmVkaXJlY3RzID0gZmFsc2U7XG4gICAgICAgICAgICAgICAgdGhpcy51cmxUcmVlID0gZS51cmxUcmVlO1xuICAgICAgICAgICAgICAgIHJldHVybiB0aGlzLm1hdGNoKGUudXJsVHJlZSk7XG4gICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICBpZiAoZSBpbnN0YW5jZW9mIE5vTWF0Y2gpIHtcbiAgICAgICAgICAgICAgICB0aHJvdyB0aGlzLm5vTWF0Y2hFcnJvcihlKTtcbiAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgIHRocm93IGU7XG4gICAgICAgICAgICB9KSxcbiAgICAgICAgICAgIG1hcChjaGlsZHJlbiA9PiB7XG4gICAgICAgICAgICAgIC8vIFVzZSBPYmplY3QuZnJlZXplIHRvIHByZXZlbnQgcmVhZGVycyBvZiB0aGUgUm91dGVyIHN0YXRlIGZyb20gbW9kaWZ5aW5nIGl0IG91dHNpZGVcbiAgICAgICAgICAgICAgLy8gb2YgYSBuYXZpZ2F0aW9uLCByZXN1bHRpbmcgaW4gdGhlIHJvdXRlciBiZWluZyBvdXQgb2Ygc3luYyB3aXRoIHRoZSBicm93c2VyLlxuICAgICAgICAgICAgICBjb25zdCByb290ID0gbmV3IEFjdGl2YXRlZFJvdXRlU25hcHNob3QoXG4gICAgICAgICAgICAgICAgICBbXSwgT2JqZWN0LmZyZWV6ZSh7fSksIE9iamVjdC5mcmVlemUoey4uLnRoaXMudXJsVHJlZS5xdWVyeVBhcmFtc30pLFxuICAgICAgICAgICAgICAgICAgdGhpcy51cmxUcmVlLmZyYWdtZW50LCB7fSwgUFJJTUFSWV9PVVRMRVQsIHRoaXMucm9vdENvbXBvbmVudFR5cGUsIG51bGwsIHt9KTtcblxuICAgICAgICAgICAgICBjb25zdCByb290Tm9kZSA9IG5ldyBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90Pihyb290LCBjaGlsZHJlbik7XG4gICAgICAgICAgICAgIGNvbnN0IHJvdXRlU3RhdGUgPSBuZXcgUm91dGVyU3RhdGVTbmFwc2hvdCgnJywgcm9vdE5vZGUpO1xuICAgICAgICAgICAgICBjb25zdCB0cmVlID0gY3JlYXRlVXJsVHJlZUZyb21TbmFwc2hvdChcbiAgICAgICAgICAgICAgICAgIHJvb3QsIFtdLCB0aGlzLnVybFRyZWUucXVlcnlQYXJhbXMsIHRoaXMudXJsVHJlZS5mcmFnbWVudCk7XG4gICAgICAgICAgICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIvaXNzdWVzLzQ3MzA3XG4gICAgICAgICAgICAgIC8vIENyZWF0aW5nIHRoZSB0cmVlIHN0cmluZ2lmaWVzIHRoZSBxdWVyeSBwYXJhbXNcbiAgICAgICAgICAgICAgLy8gV2UgZG9uJ3Qgd2FudCB0byBkbyB0aGlzIGhlcmUgc28gcmVhc3NpZ24gdGhlbSB0byB0aGUgb3JpZ2luYWwuXG4gICAgICAgICAgICAgIHRyZWUucXVlcnlQYXJhbXMgPSB0aGlzLnVybFRyZWUucXVlcnlQYXJhbXM7XG4gICAgICAgICAgICAgIHJvdXRlU3RhdGUudXJsID0gdGhpcy51cmxTZXJpYWxpemVyLnNlcmlhbGl6ZSh0cmVlKTtcbiAgICAgICAgICAgICAgdGhpcy5pbmhlcml0UGFyYW1zQW5kRGF0YShyb3V0ZVN0YXRlLl9yb290KTtcbiAgICAgICAgICAgICAgcmV0dXJuIHtzdGF0ZTogcm91dGVTdGF0ZSwgdHJlZX07XG4gICAgICAgICAgICB9KSk7XG4gIH1cblxuXG4gIHByaXZhdGUgbWF0Y2godHJlZTogVXJsVHJlZSkge1xuICAgIGNvbnN0IGV4cGFuZGVkJCA9XG4gICAgICAgIHRoaXMucHJvY2Vzc1NlZ21lbnRHcm91cCh0aGlzLmluamVjdG9yLCB0aGlzLmNvbmZpZywgdHJlZS5yb290LCBQUklNQVJZX09VVExFVCk7XG4gICAgcmV0dXJuIGV4cGFuZGVkJC5waXBlKGNhdGNoRXJyb3IoKGU6IGFueSkgPT4ge1xuICAgICAgaWYgKGUgaW5zdGFuY2VvZiBOb01hdGNoKSB7XG4gICAgICAgIHRocm93IHRoaXMubm9NYXRjaEVycm9yKGUpO1xuICAgICAgfVxuXG4gICAgICB0aHJvdyBlO1xuICAgIH0pKTtcbiAgfVxuXG4gIGluaGVyaXRQYXJhbXNBbmREYXRhKHJvdXRlTm9kZTogVHJlZU5vZGU8QWN0aXZhdGVkUm91dGVTbmFwc2hvdD4pOiB2b2lkIHtcbiAgICBjb25zdCByb3V0ZSA9IHJvdXRlTm9kZS52YWx1ZTtcblxuICAgIGNvbnN0IGkgPSBpbmhlcml0ZWRQYXJhbXNEYXRhUmVzb2x2ZShyb3V0ZSwgdGhpcy5wYXJhbXNJbmhlcml0YW5jZVN0cmF0ZWd5KTtcbiAgICByb3V0ZS5wYXJhbXMgPSBPYmplY3QuZnJlZXplKGkucGFyYW1zKTtcbiAgICByb3V0ZS5kYXRhID0gT2JqZWN0LmZyZWV6ZShpLmRhdGEpO1xuXG4gICAgcm91dGVOb2RlLmNoaWxkcmVuLmZvckVhY2gobiA9PiB0aGlzLmluaGVyaXRQYXJhbXNBbmREYXRhKG4pKTtcbiAgfVxuXG4gIHByb2Nlc3NTZWdtZW50R3JvdXAoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3RvciwgY29uZmlnOiBSb3V0ZVtdLCBzZWdtZW50R3JvdXA6IFVybFNlZ21lbnRHcm91cCxcbiAgICAgIG91dGxldDogc3RyaW5nKTogT2JzZXJ2YWJsZTxUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdPiB7XG4gICAgaWYgKHNlZ21lbnRHcm91cC5zZWdtZW50cy5sZW5ndGggPT09IDAgJiYgc2VnbWVudEdyb3VwLmhhc0NoaWxkcmVuKCkpIHtcbiAgICAgIHJldHVybiB0aGlzLnByb2Nlc3NDaGlsZHJlbihpbmplY3RvciwgY29uZmlnLCBzZWdtZW50R3JvdXApO1xuICAgIH1cblxuICAgIHJldHVybiB0aGlzLnByb2Nlc3NTZWdtZW50KGluamVjdG9yLCBjb25maWcsIHNlZ21lbnRHcm91cCwgc2VnbWVudEdyb3VwLnNlZ21lbnRzLCBvdXRsZXQsIHRydWUpO1xuICB9XG5cbiAgLyoqXG4gICAqIE1hdGNoZXMgZXZlcnkgY2hpbGQgb3V0bGV0IGluIHRoZSBgc2VnbWVudEdyb3VwYCB0byBhIGBSb3V0ZWAgaW4gdGhlIGNvbmZpZy4gUmV0dXJucyBgbnVsbGAgaWZcbiAgICogd2UgY2Fubm90IGZpbmQgYSBtYXRjaCBmb3IgX2FueV8gb2YgdGhlIGNoaWxkcmVuLlxuICAgKlxuICAgKiBAcGFyYW0gY29uZmlnIC0gVGhlIGBSb3V0ZXNgIHRvIG1hdGNoIGFnYWluc3RcbiAgICogQHBhcmFtIHNlZ21lbnRHcm91cCAtIFRoZSBgVXJsU2VnbWVudEdyb3VwYCB3aG9zZSBjaGlsZHJlbiBuZWVkIHRvIGJlIG1hdGNoZWQgYWdhaW5zdCB0aGVcbiAgICogICAgIGNvbmZpZy5cbiAgICovXG4gIHByb2Nlc3NDaGlsZHJlbihpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3RvciwgY29uZmlnOiBSb3V0ZVtdLCBzZWdtZW50R3JvdXA6IFVybFNlZ21lbnRHcm91cCk6XG4gICAgICBPYnNlcnZhYmxlPFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+W10+IHtcbiAgICAvLyBFeHBhbmQgb3V0bGV0cyBvbmUgYXQgYSB0aW1lLCBzdGFydGluZyB3aXRoIHRoZSBwcmltYXJ5IG91dGxldC4gV2UgbmVlZCB0byBkbyBpdCB0aGlzIHdheVxuICAgIC8vIGJlY2F1c2UgYW4gYWJzb2x1dGUgcmVkaXJlY3QgZnJvbSB0aGUgcHJpbWFyeSBvdXRsZXQgdGFrZXMgcHJlY2VkZW5jZS5cbiAgICBjb25zdCBjaGlsZE91dGxldHM6IHN0cmluZ1tdID0gW107XG4gICAgZm9yIChjb25zdCBjaGlsZCBvZiBPYmplY3Qua2V5cyhzZWdtZW50R3JvdXAuY2hpbGRyZW4pKSB7XG4gICAgICBpZiAoY2hpbGQgPT09ICdwcmltYXJ5Jykge1xuICAgICAgICBjaGlsZE91dGxldHMudW5zaGlmdChjaGlsZCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBjaGlsZE91dGxldHMucHVzaChjaGlsZCk7XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBmcm9tKGNoaWxkT3V0bGV0cylcbiAgICAgICAgLnBpcGUoXG4gICAgICAgICAgICBjb25jYXRNYXAoY2hpbGRPdXRsZXQgPT4ge1xuICAgICAgICAgICAgICBjb25zdCBjaGlsZCA9IHNlZ21lbnRHcm91cC5jaGlsZHJlbltjaGlsZE91dGxldF07XG4gICAgICAgICAgICAgIC8vIFNvcnQgdGhlIGNvbmZpZyBzbyB0aGF0IHJvdXRlcyB3aXRoIG91dGxldHMgdGhhdCBtYXRjaCB0aGUgb25lIGJlaW5nIGFjdGl2YXRlZFxuICAgICAgICAgICAgICAvLyBhcHBlYXIgZmlyc3QsIGZvbGxvd2VkIGJ5IHJvdXRlcyBmb3Igb3RoZXIgb3V0bGV0cywgd2hpY2ggbWlnaHQgbWF0Y2ggaWYgdGhleSBoYXZlXG4gICAgICAgICAgICAgIC8vIGFuIGVtcHR5IHBhdGguXG4gICAgICAgICAgICAgIGNvbnN0IHNvcnRlZENvbmZpZyA9IHNvcnRCeU1hdGNoaW5nT3V0bGV0cyhjb25maWcsIGNoaWxkT3V0bGV0KTtcbiAgICAgICAgICAgICAgcmV0dXJuIHRoaXMucHJvY2Vzc1NlZ21lbnRHcm91cChpbmplY3Rvciwgc29ydGVkQ29uZmlnLCBjaGlsZCwgY2hpbGRPdXRsZXQpO1xuICAgICAgICAgICAgfSksXG4gICAgICAgICAgICBzY2FuKChjaGlsZHJlbiwgb3V0bGV0Q2hpbGRyZW4pID0+IHtcbiAgICAgICAgICAgICAgY2hpbGRyZW4ucHVzaCguLi5vdXRsZXRDaGlsZHJlbik7XG4gICAgICAgICAgICAgIHJldHVybiBjaGlsZHJlbjtcbiAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgZGVmYXVsdElmRW1wdHkobnVsbCBhcyBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdIHwgbnVsbCksXG4gICAgICAgICAgICByeGpzTGFzdCgpLFxuICAgICAgICAgICAgbWVyZ2VNYXAoY2hpbGRyZW4gPT4ge1xuICAgICAgICAgICAgICBpZiAoY2hpbGRyZW4gPT09IG51bGwpIHJldHVybiBub01hdGNoKHNlZ21lbnRHcm91cCk7XG4gICAgICAgICAgICAgIC8vIEJlY2F1c2Ugd2UgbWF5IGhhdmUgbWF0Y2hlZCB0d28gb3V0bGV0cyB0byB0aGUgc2FtZSBlbXB0eSBwYXRoIHNlZ21lbnQsIHdlIGNhbiBoYXZlXG4gICAgICAgICAgICAgIC8vIG11bHRpcGxlIGFjdGl2YXRlZCByZXN1bHRzIGZvciB0aGUgc2FtZSBvdXRsZXQuIFdlIHNob3VsZCBtZXJnZSB0aGUgY2hpbGRyZW4gb2ZcbiAgICAgICAgICAgICAgLy8gdGhlc2UgcmVzdWx0cyBzbyB0aGUgZmluYWwgcmV0dXJuIHZhbHVlIGlzIG9ubHkgb25lIGBUcmVlTm9kZWAgcGVyIG91dGxldC5cbiAgICAgICAgICAgICAgY29uc3QgbWVyZ2VkQ2hpbGRyZW4gPSBtZXJnZUVtcHR5UGF0aE1hdGNoZXMoY2hpbGRyZW4pO1xuICAgICAgICAgICAgICBpZiAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSB7XG4gICAgICAgICAgICAgICAgLy8gVGhpcyBzaG91bGQgcmVhbGx5IG5ldmVyIGhhcHBlbiAtIHdlIGFyZSBvbmx5IHRha2luZyB0aGUgZmlyc3QgbWF0Y2ggZm9yIGVhY2hcbiAgICAgICAgICAgICAgICAvLyBvdXRsZXQgYW5kIG1lcmdlIHRoZSBlbXB0eSBwYXRoIG1hdGNoZXMuXG4gICAgICAgICAgICAgICAgY2hlY2tPdXRsZXROYW1lVW5pcXVlbmVzcyhtZXJnZWRDaGlsZHJlbik7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgc29ydEFjdGl2YXRlZFJvdXRlU25hcHNob3RzKG1lcmdlZENoaWxkcmVuKTtcbiAgICAgICAgICAgICAgcmV0dXJuIG9mKG1lcmdlZENoaWxkcmVuKTtcbiAgICAgICAgICAgIH0pLFxuICAgICAgICApO1xuICB9XG5cbiAgcHJvY2Vzc1NlZ21lbnQoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3Rvciwgcm91dGVzOiBSb3V0ZVtdLCBzZWdtZW50R3JvdXA6IFVybFNlZ21lbnRHcm91cCxcbiAgICAgIHNlZ21lbnRzOiBVcmxTZWdtZW50W10sIG91dGxldDogc3RyaW5nLFxuICAgICAgYWxsb3dSZWRpcmVjdHM6IGJvb2xlYW4pOiBPYnNlcnZhYmxlPFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+W10+IHtcbiAgICByZXR1cm4gZnJvbShyb3V0ZXMpLnBpcGUoXG4gICAgICAgIGNvbmNhdE1hcChyID0+IHtcbiAgICAgICAgICByZXR1cm4gdGhpc1xuICAgICAgICAgICAgICAucHJvY2Vzc1NlZ21lbnRBZ2FpbnN0Um91dGUoXG4gICAgICAgICAgICAgICAgICByLl9pbmplY3RvciA/PyBpbmplY3Rvciwgcm91dGVzLCByLCBzZWdtZW50R3JvdXAsIHNlZ21lbnRzLCBvdXRsZXQsXG4gICAgICAgICAgICAgICAgICBhbGxvd1JlZGlyZWN0cylcbiAgICAgICAgICAgICAgLnBpcGUoY2F0Y2hFcnJvcigoZTogYW55KSA9PiB7XG4gICAgICAgICAgICAgICAgaWYgKGUgaW5zdGFuY2VvZiBOb01hdGNoKSB7XG4gICAgICAgICAgICAgICAgICByZXR1cm4gb2YobnVsbCk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHRocm93IGU7XG4gICAgICAgICAgICAgIH0pKTtcbiAgICAgICAgfSksXG4gICAgICAgIGZpcnN0KCh4KTogeCBpcyBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdID0+ICEheCksIGNhdGNoRXJyb3IoZSA9PiB7XG4gICAgICAgICAgaWYgKGlzRW1wdHlFcnJvcihlKSkge1xuICAgICAgICAgICAgaWYgKG5vTGVmdG92ZXJzSW5Vcmwoc2VnbWVudEdyb3VwLCBzZWdtZW50cywgb3V0bGV0KSkge1xuICAgICAgICAgICAgICByZXR1cm4gb2YoW10pO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIG5vTWF0Y2goc2VnbWVudEdyb3VwKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgdGhyb3cgZTtcbiAgICAgICAgfSkpO1xuICB9XG5cbiAgcHJvY2Vzc1NlZ21lbnRBZ2FpbnN0Um91dGUoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3Rvciwgcm91dGVzOiBSb3V0ZVtdLCByb3V0ZTogUm91dGUsIHJhd1NlZ21lbnQ6IFVybFNlZ21lbnRHcm91cCxcbiAgICAgIHNlZ21lbnRzOiBVcmxTZWdtZW50W10sIG91dGxldDogc3RyaW5nLFxuICAgICAgYWxsb3dSZWRpcmVjdHM6IGJvb2xlYW4pOiBPYnNlcnZhYmxlPFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+W10+IHtcbiAgICBpZiAoIWlzSW1tZWRpYXRlTWF0Y2gocm91dGUsIHJhd1NlZ21lbnQsIHNlZ21lbnRzLCBvdXRsZXQpKSByZXR1cm4gbm9NYXRjaChyYXdTZWdtZW50KTtcblxuICAgIGlmIChyb3V0ZS5yZWRpcmVjdFRvID09PSB1bmRlZmluZWQpIHtcbiAgICAgIHJldHVybiB0aGlzLm1hdGNoU2VnbWVudEFnYWluc3RSb3V0ZShcbiAgICAgICAgICBpbmplY3RvciwgcmF3U2VnbWVudCwgcm91dGUsIHNlZ21lbnRzLCBvdXRsZXQsIGFsbG93UmVkaXJlY3RzKTtcbiAgICB9XG5cbiAgICBpZiAoYWxsb3dSZWRpcmVjdHMgJiYgdGhpcy5hbGxvd1JlZGlyZWN0cykge1xuICAgICAgcmV0dXJuIHRoaXMuZXhwYW5kU2VnbWVudEFnYWluc3RSb3V0ZVVzaW5nUmVkaXJlY3QoXG4gICAgICAgICAgaW5qZWN0b3IsIHJhd1NlZ21lbnQsIHJvdXRlcywgcm91dGUsIHNlZ21lbnRzLCBvdXRsZXQpO1xuICAgIH1cblxuICAgIHJldHVybiBub01hdGNoKHJhd1NlZ21lbnQpO1xuICB9XG5cbiAgcHJpdmF0ZSBleHBhbmRTZWdtZW50QWdhaW5zdFJvdXRlVXNpbmdSZWRpcmVjdChcbiAgICAgIGluamVjdG9yOiBFbnZpcm9ubWVudEluamVjdG9yLCBzZWdtZW50R3JvdXA6IFVybFNlZ21lbnRHcm91cCwgcm91dGVzOiBSb3V0ZVtdLCByb3V0ZTogUm91dGUsXG4gICAgICBzZWdtZW50czogVXJsU2VnbWVudFtdLCBvdXRsZXQ6IHN0cmluZyk6IE9ic2VydmFibGU8VHJlZU5vZGU8QWN0aXZhdGVkUm91dGVTbmFwc2hvdD5bXT4ge1xuICAgIGlmIChyb3V0ZS5wYXRoID09PSAnKionKSB7XG4gICAgICByZXR1cm4gdGhpcy5leHBhbmRXaWxkQ2FyZFdpdGhQYXJhbXNBZ2FpbnN0Um91dGVVc2luZ1JlZGlyZWN0KFxuICAgICAgICAgIGluamVjdG9yLCByb3V0ZXMsIHJvdXRlLCBvdXRsZXQpO1xuICAgIH1cblxuICAgIHJldHVybiB0aGlzLmV4cGFuZFJlZ3VsYXJTZWdtZW50QWdhaW5zdFJvdXRlVXNpbmdSZWRpcmVjdChcbiAgICAgICAgaW5qZWN0b3IsIHNlZ21lbnRHcm91cCwgcm91dGVzLCByb3V0ZSwgc2VnbWVudHMsIG91dGxldCk7XG4gIH1cblxuICBwcml2YXRlIGV4cGFuZFdpbGRDYXJkV2l0aFBhcmFtc0FnYWluc3RSb3V0ZVVzaW5nUmVkaXJlY3QoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3Rvciwgcm91dGVzOiBSb3V0ZVtdLCByb3V0ZTogUm91dGUsXG4gICAgICBvdXRsZXQ6IHN0cmluZyk6IE9ic2VydmFibGU8VHJlZU5vZGU8QWN0aXZhdGVkUm91dGVTbmFwc2hvdD5bXT4ge1xuICAgIGNvbnN0IG5ld1RyZWUgPSB0aGlzLmFwcGx5UmVkaXJlY3RzLmFwcGx5UmVkaXJlY3RDb21tYW5kcyhbXSwgcm91dGUucmVkaXJlY3RUbyEsIHt9KTtcbiAgICBpZiAocm91dGUucmVkaXJlY3RUbyEuc3RhcnRzV2l0aCgnLycpKSB7XG4gICAgICByZXR1cm4gYWJzb2x1dGVSZWRpcmVjdChuZXdUcmVlKTtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcy5hcHBseVJlZGlyZWN0cy5saW5lcmFsaXplU2VnbWVudHMocm91dGUsIG5ld1RyZWUpXG4gICAgICAgIC5waXBlKG1lcmdlTWFwKChuZXdTZWdtZW50czogVXJsU2VnbWVudFtdKSA9PiB7XG4gICAgICAgICAgY29uc3QgZ3JvdXAgPSBuZXcgVXJsU2VnbWVudEdyb3VwKG5ld1NlZ21lbnRzLCB7fSk7XG4gICAgICAgICAgcmV0dXJuIHRoaXMucHJvY2Vzc1NlZ21lbnQoaW5qZWN0b3IsIHJvdXRlcywgZ3JvdXAsIG5ld1NlZ21lbnRzLCBvdXRsZXQsIGZhbHNlKTtcbiAgICAgICAgfSkpO1xuICB9XG5cbiAgcHJpdmF0ZSBleHBhbmRSZWd1bGFyU2VnbWVudEFnYWluc3RSb3V0ZVVzaW5nUmVkaXJlY3QoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3Rvciwgc2VnbWVudEdyb3VwOiBVcmxTZWdtZW50R3JvdXAsIHJvdXRlczogUm91dGVbXSwgcm91dGU6IFJvdXRlLFxuICAgICAgc2VnbWVudHM6IFVybFNlZ21lbnRbXSwgb3V0bGV0OiBzdHJpbmcpOiBPYnNlcnZhYmxlPFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+W10+IHtcbiAgICBjb25zdCB7bWF0Y2hlZCwgY29uc3VtZWRTZWdtZW50cywgcmVtYWluaW5nU2VnbWVudHMsIHBvc2l0aW9uYWxQYXJhbVNlZ21lbnRzfSA9XG4gICAgICAgIG1hdGNoKHNlZ21lbnRHcm91cCwgcm91dGUsIHNlZ21lbnRzKTtcbiAgICBpZiAoIW1hdGNoZWQpIHJldHVybiBub01hdGNoKHNlZ21lbnRHcm91cCk7XG5cbiAgICBjb25zdCBuZXdUcmVlID0gdGhpcy5hcHBseVJlZGlyZWN0cy5hcHBseVJlZGlyZWN0Q29tbWFuZHMoXG4gICAgICAgIGNvbnN1bWVkU2VnbWVudHMsIHJvdXRlLnJlZGlyZWN0VG8hLCBwb3NpdGlvbmFsUGFyYW1TZWdtZW50cyk7XG4gICAgaWYgKHJvdXRlLnJlZGlyZWN0VG8hLnN0YXJ0c1dpdGgoJy8nKSkge1xuICAgICAgcmV0dXJuIGFic29sdXRlUmVkaXJlY3QobmV3VHJlZSk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXMuYXBwbHlSZWRpcmVjdHMubGluZXJhbGl6ZVNlZ21lbnRzKHJvdXRlLCBuZXdUcmVlKVxuICAgICAgICAucGlwZShtZXJnZU1hcCgobmV3U2VnbWVudHM6IFVybFNlZ21lbnRbXSkgPT4ge1xuICAgICAgICAgIHJldHVybiB0aGlzLnByb2Nlc3NTZWdtZW50KFxuICAgICAgICAgICAgICBpbmplY3Rvciwgcm91dGVzLCBzZWdtZW50R3JvdXAsIG5ld1NlZ21lbnRzLmNvbmNhdChyZW1haW5pbmdTZWdtZW50cyksIG91dGxldCwgZmFsc2UpO1xuICAgICAgICB9KSk7XG4gIH1cblxuICBtYXRjaFNlZ21lbnRBZ2FpbnN0Um91dGUoXG4gICAgICBpbmplY3RvcjogRW52aXJvbm1lbnRJbmplY3RvciwgcmF3U2VnbWVudDogVXJsU2VnbWVudEdyb3VwLCByb3V0ZTogUm91dGUsXG4gICAgICBzZWdtZW50czogVXJsU2VnbWVudFtdLCBvdXRsZXQ6IHN0cmluZyxcbiAgICAgIGFsbG93UmVkaXJlY3RzOiBib29sZWFuKTogT2JzZXJ2YWJsZTxUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdPiB7XG4gICAgbGV0IG1hdGNoUmVzdWx0OiBPYnNlcnZhYmxlPHtcbiAgICAgIHNuYXBzaG90OiBBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90LFxuICAgICAgY29uc3VtZWRTZWdtZW50czogVXJsU2VnbWVudFtdLFxuICAgICAgcmVtYWluaW5nU2VnbWVudHM6IFVybFNlZ21lbnRbXSxcbiAgICB9fG51bGw+O1xuXG4gICAgaWYgKHJvdXRlLnBhdGggPT09ICcqKicpIHtcbiAgICAgIGNvbnN0IHBhcmFtcyA9IHNlZ21lbnRzLmxlbmd0aCA+IDAgPyBsYXN0KHNlZ21lbnRzKSEucGFyYW1ldGVycyA6IHt9O1xuICAgICAgY29uc3Qgc25hcHNob3QgPSBuZXcgQWN0aXZhdGVkUm91dGVTbmFwc2hvdChcbiAgICAgICAgICBzZWdtZW50cywgcGFyYW1zLCBPYmplY3QuZnJlZXplKHsuLi50aGlzLnVybFRyZWUucXVlcnlQYXJhbXN9KSwgdGhpcy51cmxUcmVlLmZyYWdtZW50LFxuICAgICAgICAgIGdldERhdGEocm91dGUpLCBnZXRPdXRsZXQocm91dGUpLCByb3V0ZS5jb21wb25lbnQgPz8gcm91dGUuX2xvYWRlZENvbXBvbmVudCA/PyBudWxsLFxuICAgICAgICAgIHJvdXRlLCBnZXRSZXNvbHZlKHJvdXRlKSk7XG4gICAgICBtYXRjaFJlc3VsdCA9IG9mKHtcbiAgICAgICAgc25hcHNob3QsXG4gICAgICAgIGNvbnN1bWVkU2VnbWVudHM6IFtdLFxuICAgICAgICByZW1haW5pbmdTZWdtZW50czogW10sXG4gICAgICB9KTtcbiAgICAgIC8vIFByaW9yIHZlcnNpb25zIG9mIHRoZSByb3V0ZSBtYXRjaGluZyBhbGdvcml0aG0gd291bGQgc3RvcCBtYXRjaGluZyBhdCB0aGUgd2lsZGNhcmQgcm91dGUuXG4gICAgICAvLyBXZSBzaG91bGQgaW52ZXN0aWdhdGUgYSBiZXR0ZXIgc3RyYXRlZ3kgZm9yIGFueSBleGlzdGluZyBjaGlsZHJlbi4gT3RoZXJ3aXNlLCB0aGVzZVxuICAgICAgLy8gY2hpbGQgc2VnbWVudHMgYXJlIHNpbGVudGx5IGRyb3BwZWQgZnJvbSB0aGUgbmF2aWdhdGlvbi5cbiAgICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIvaXNzdWVzLzQwMDg5XG4gICAgICByYXdTZWdtZW50LmNoaWxkcmVuID0ge307XG4gICAgfSBlbHNlIHtcbiAgICAgIG1hdGNoUmVzdWx0ID1cbiAgICAgICAgICBtYXRjaFdpdGhDaGVja3MocmF3U2VnbWVudCwgcm91dGUsIHNlZ21lbnRzLCBpbmplY3RvciwgdGhpcy51cmxTZXJpYWxpemVyKVxuICAgICAgICAgICAgICAucGlwZShtYXAoKHttYXRjaGVkLCBjb25zdW1lZFNlZ21lbnRzLCByZW1haW5pbmdTZWdtZW50cywgcGFyYW1ldGVyc30pID0+IHtcbiAgICAgICAgICAgICAgICBpZiAoIW1hdGNoZWQpIHtcbiAgICAgICAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIGNvbnN0IHNuYXBzaG90ID0gbmV3IEFjdGl2YXRlZFJvdXRlU25hcHNob3QoXG4gICAgICAgICAgICAgICAgICAgIGNvbnN1bWVkU2VnbWVudHMsIHBhcmFtZXRlcnMsIE9iamVjdC5mcmVlemUoey4uLnRoaXMudXJsVHJlZS5xdWVyeVBhcmFtc30pLFxuICAgICAgICAgICAgICAgICAgICB0aGlzLnVybFRyZWUuZnJhZ21lbnQsIGdldERhdGEocm91dGUpLCBnZXRPdXRsZXQocm91dGUpLFxuICAgICAgICAgICAgICAgICAgICByb3V0ZS5jb21wb25lbnQgPz8gcm91dGUuX2xvYWRlZENvbXBvbmVudCA/PyBudWxsLCByb3V0ZSwgZ2V0UmVzb2x2ZShyb3V0ZSkpO1xuICAgICAgICAgICAgICAgIHJldHVybiB7c25hcHNob3QsIGNvbnN1bWVkU2VnbWVudHMsIHJlbWFpbmluZ1NlZ21lbnRzfTtcbiAgICAgICAgICAgICAgfSkpO1xuICAgIH1cblxuICAgIHJldHVybiBtYXRjaFJlc3VsdC5waXBlKHN3aXRjaE1hcCgocmVzdWx0KSA9PiB7XG4gICAgICBpZiAocmVzdWx0ID09PSBudWxsKSB7XG4gICAgICAgIHJldHVybiBub01hdGNoKHJhd1NlZ21lbnQpO1xuICAgICAgfVxuXG4gICAgICAvLyBJZiB0aGUgcm91dGUgaGFzIGFuIGluamVjdG9yIGNyZWF0ZWQgZnJvbSBwcm92aWRlcnMsIHdlIHNob3VsZCBzdGFydCB1c2luZyB0aGF0LlxuICAgICAgaW5qZWN0b3IgPSByb3V0ZS5faW5qZWN0b3IgPz8gaW5qZWN0b3I7XG4gICAgICByZXR1cm4gdGhpcy5nZXRDaGlsZENvbmZpZyhpbmplY3Rvciwgcm91dGUsIHNlZ21lbnRzKVxuICAgICAgICAgIC5waXBlKHN3aXRjaE1hcCgoe3JvdXRlczogY2hpbGRDb25maWd9KSA9PiB7XG4gICAgICAgICAgICBjb25zdCBjaGlsZEluamVjdG9yID0gcm91dGUuX2xvYWRlZEluamVjdG9yID8/IGluamVjdG9yO1xuXG4gICAgICAgICAgICBjb25zdCB7c25hcHNob3QsIGNvbnN1bWVkU2VnbWVudHMsIHJlbWFpbmluZ1NlZ21lbnRzfSA9IHJlc3VsdDtcblxuICAgICAgICAgICAgY29uc3Qge3NlZ21lbnRHcm91cCwgc2xpY2VkU2VnbWVudHN9ID1cbiAgICAgICAgICAgICAgICBzcGxpdChyYXdTZWdtZW50LCBjb25zdW1lZFNlZ21lbnRzLCByZW1haW5pbmdTZWdtZW50cywgY2hpbGRDb25maWcpO1xuXG4gICAgICAgICAgICBpZiAoc2xpY2VkU2VnbWVudHMubGVuZ3RoID09PSAwICYmIHNlZ21lbnRHcm91cC5oYXNDaGlsZHJlbigpKSB7XG4gICAgICAgICAgICAgIHJldHVybiB0aGlzLnByb2Nlc3NDaGlsZHJlbihjaGlsZEluamVjdG9yLCBjaGlsZENvbmZpZywgc2VnbWVudEdyb3VwKVxuICAgICAgICAgICAgICAgICAgLnBpcGUobWFwKGNoaWxkcmVuID0+IHtcbiAgICAgICAgICAgICAgICAgICAgaWYgKGNoaWxkcmVuID09PSBudWxsKSB7XG4gICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIG51bGw7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFtuZXcgVHJlZU5vZGU8QWN0aXZhdGVkUm91dGVTbmFwc2hvdD4oc25hcHNob3QsIGNoaWxkcmVuKV07XG4gICAgICAgICAgICAgICAgICB9KSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGlmIChjaGlsZENvbmZpZy5sZW5ndGggPT09IDAgJiYgc2xpY2VkU2VnbWVudHMubGVuZ3RoID09PSAwKSB7XG4gICAgICAgICAgICAgIHJldHVybiBvZihbbmV3IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+KHNuYXBzaG90LCBbXSldKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgY29uc3QgbWF0Y2hlZE9uT3V0bGV0ID0gZ2V0T3V0bGV0KHJvdXRlKSA9PT0gb3V0bGV0O1xuICAgICAgICAgICAgLy8gSWYgd2UgbWF0Y2hlZCBhIGNvbmZpZyBkdWUgdG8gZW1wdHkgcGF0aCBtYXRjaCBvbiBhIGRpZmZlcmVudCBvdXRsZXQsIHdlIG5lZWQgdG9cbiAgICAgICAgICAgIC8vIGNvbnRpbnVlIHBhc3NpbmcgdGhlIGN1cnJlbnQgb3V0bGV0IGZvciB0aGUgc2VnbWVudCByYXRoZXIgdGhhbiBzd2l0Y2ggdG8gUFJJTUFSWS5cbiAgICAgICAgICAgIC8vIE5vdGUgdGhhdCB3ZSBzd2l0Y2ggdG8gcHJpbWFyeSB3aGVuIHdlIGhhdmUgYSBtYXRjaCBiZWNhdXNlIG91dGxldCBjb25maWdzIGxvb2sgbGlrZVxuICAgICAgICAgICAgLy8gdGhpczoge3BhdGg6ICdhJywgb3V0bGV0OiAnYScsIGNoaWxkcmVuOiBbXG4gICAgICAgICAgICAvLyAge3BhdGg6ICdiJywgY29tcG9uZW50OiBCfSxcbiAgICAgICAgICAgIC8vICB7cGF0aDogJ2MnLCBjb21wb25lbnQ6IEN9LFxuICAgICAgICAgICAgLy8gXX1cbiAgICAgICAgICAgIC8vIE5vdGljZSB0aGF0IHRoZSBjaGlsZHJlbiBvZiB0aGUgbmFtZWQgb3V0bGV0IGFyZSBjb25maWd1cmVkIHdpdGggdGhlIHByaW1hcnkgb3V0bGV0XG4gICAgICAgICAgICByZXR1cm4gdGhpc1xuICAgICAgICAgICAgICAgIC5wcm9jZXNzU2VnbWVudChcbiAgICAgICAgICAgICAgICAgICAgY2hpbGRJbmplY3RvciwgY2hpbGRDb25maWcsIHNlZ21lbnRHcm91cCwgc2xpY2VkU2VnbWVudHMsXG4gICAgICAgICAgICAgICAgICAgIG1hdGNoZWRPbk91dGxldCA/IFBSSU1BUllfT1VUTEVUIDogb3V0bGV0LCB0cnVlKVxuICAgICAgICAgICAgICAgIC5waXBlKG1hcChjaGlsZHJlbiA9PiB7XG4gICAgICAgICAgICAgICAgICByZXR1cm4gW25ldyBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PihzbmFwc2hvdCwgY2hpbGRyZW4pXTtcbiAgICAgICAgICAgICAgICB9KSk7XG4gICAgICAgICAgfSkpO1xuICAgIH0pKTtcbiAgfVxuICBwcml2YXRlIGdldENoaWxkQ29uZmlnKGluamVjdG9yOiBFbnZpcm9ubWVudEluamVjdG9yLCByb3V0ZTogUm91dGUsIHNlZ21lbnRzOiBVcmxTZWdtZW50W10pOlxuICAgICAgT2JzZXJ2YWJsZTxMb2FkZWRSb3V0ZXJDb25maWc+IHtcbiAgICBpZiAocm91dGUuY2hpbGRyZW4pIHtcbiAgICAgIC8vIFRoZSBjaGlsZHJlbiBiZWxvbmcgdG8gdGhlIHNhbWUgbW9kdWxlXG4gICAgICByZXR1cm4gb2Yoe3JvdXRlczogcm91dGUuY2hpbGRyZW4sIGluamVjdG9yfSk7XG4gICAgfVxuXG4gICAgaWYgKHJvdXRlLmxvYWRDaGlsZHJlbikge1xuICAgICAgLy8gbGF6eSBjaGlsZHJlbiBiZWxvbmcgdG8gdGhlIGxvYWRlZCBtb2R1bGVcbiAgICAgIGlmIChyb3V0ZS5fbG9hZGVkUm91dGVzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgcmV0dXJuIG9mKHtyb3V0ZXM6IHJvdXRlLl9sb2FkZWRSb3V0ZXMsIGluamVjdG9yOiByb3V0ZS5fbG9hZGVkSW5qZWN0b3J9KTtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHJ1bkNhbkxvYWRHdWFyZHMoaW5qZWN0b3IsIHJvdXRlLCBzZWdtZW50cywgdGhpcy51cmxTZXJpYWxpemVyKVxuICAgICAgICAgIC5waXBlKG1lcmdlTWFwKChzaG91bGRMb2FkUmVzdWx0OiBib29sZWFuKSA9PiB7XG4gICAgICAgICAgICBpZiAoc2hvdWxkTG9hZFJlc3VsdCkge1xuICAgICAgICAgICAgICByZXR1cm4gdGhpcy5jb25maWdMb2FkZXIubG9hZENoaWxkcmVuKGluamVjdG9yLCByb3V0ZSlcbiAgICAgICAgICAgICAgICAgIC5waXBlKHRhcCgoY2ZnOiBMb2FkZWRSb3V0ZXJDb25maWcpID0+IHtcbiAgICAgICAgICAgICAgICAgICAgcm91dGUuX2xvYWRlZFJvdXRlcyA9IGNmZy5yb3V0ZXM7XG4gICAgICAgICAgICAgICAgICAgIHJvdXRlLl9sb2FkZWRJbmplY3RvciA9IGNmZy5pbmplY3RvcjtcbiAgICAgICAgICAgICAgICAgIH0pKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiBjYW5Mb2FkRmFpbHMocm91dGUpO1xuICAgICAgICAgIH0pKTtcbiAgICB9XG5cbiAgICByZXR1cm4gb2Yoe3JvdXRlczogW10sIGluamVjdG9yfSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gc29ydEFjdGl2YXRlZFJvdXRlU25hcHNob3RzKG5vZGVzOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdKTogdm9pZCB7XG4gIG5vZGVzLnNvcnQoKGEsIGIpID0+IHtcbiAgICBpZiAoYS52YWx1ZS5vdXRsZXQgPT09IFBSSU1BUllfT1VUTEVUKSByZXR1cm4gLTE7XG4gICAgaWYgKGIudmFsdWUub3V0bGV0ID09PSBQUklNQVJZX09VVExFVCkgcmV0dXJuIDE7XG4gICAgcmV0dXJuIGEudmFsdWUub3V0bGV0LmxvY2FsZUNvbXBhcmUoYi52YWx1ZS5vdXRsZXQpO1xuICB9KTtcbn1cblxuZnVuY3Rpb24gaGFzRW1wdHlQYXRoQ29uZmlnKG5vZGU6IFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+KSB7XG4gIGNvbnN0IGNvbmZpZyA9IG5vZGUudmFsdWUucm91dGVDb25maWc7XG4gIHJldHVybiBjb25maWcgJiYgY29uZmlnLnBhdGggPT09ICcnO1xufVxuXG4vKipcbiAqIEZpbmRzIGBUcmVlTm9kZWBzIHdpdGggbWF0Y2hpbmcgZW1wdHkgcGF0aCByb3V0ZSBjb25maWdzIGFuZCBtZXJnZXMgdGhlbSBpbnRvIGBUcmVlTm9kZWAgd2l0aFxuICogdGhlIGNoaWxkcmVuIGZyb20gZWFjaCBkdXBsaWNhdGUuIFRoaXMgaXMgbmVjZXNzYXJ5IGJlY2F1c2UgZGlmZmVyZW50IG91dGxldHMgY2FuIG1hdGNoIGFcbiAqIHNpbmdsZSBlbXB0eSBwYXRoIHJvdXRlIGNvbmZpZyBhbmQgdGhlIHJlc3VsdHMgbmVlZCB0byB0aGVuIGJlIG1lcmdlZC5cbiAqL1xuZnVuY3Rpb24gbWVyZ2VFbXB0eVBhdGhNYXRjaGVzKG5vZGVzOiBBcnJheTxUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90Pj4pOlxuICAgIEFycmF5PFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+PiB7XG4gIGNvbnN0IHJlc3VsdDogQXJyYXk8VHJlZU5vZGU8QWN0aXZhdGVkUm91dGVTbmFwc2hvdD4+ID0gW107XG4gIC8vIFRoZSBzZXQgb2Ygbm9kZXMgd2hpY2ggY29udGFpbiBjaGlsZHJlbiB0aGF0IHdlcmUgbWVyZ2VkIGZyb20gdHdvIGR1cGxpY2F0ZSBlbXB0eSBwYXRoIG5vZGVzLlxuICBjb25zdCBtZXJnZWROb2RlczogU2V0PFRyZWVOb2RlPEFjdGl2YXRlZFJvdXRlU25hcHNob3Q+PiA9IG5ldyBTZXQoKTtcblxuICBmb3IgKGNvbnN0IG5vZGUgb2Ygbm9kZXMpIHtcbiAgICBpZiAoIWhhc0VtcHR5UGF0aENvbmZpZyhub2RlKSkge1xuICAgICAgcmVzdWx0LnB1c2gobm9kZSk7XG4gICAgICBjb250aW51ZTtcbiAgICB9XG5cbiAgICBjb25zdCBkdXBsaWNhdGVFbXB0eVBhdGhOb2RlID1cbiAgICAgICAgcmVzdWx0LmZpbmQocmVzdWx0Tm9kZSA9PiBub2RlLnZhbHVlLnJvdXRlQ29uZmlnID09PSByZXN1bHROb2RlLnZhbHVlLnJvdXRlQ29uZmlnKTtcbiAgICBpZiAoZHVwbGljYXRlRW1wdHlQYXRoTm9kZSAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICBkdXBsaWNhdGVFbXB0eVBhdGhOb2RlLmNoaWxkcmVuLnB1c2goLi4ubm9kZS5jaGlsZHJlbik7XG4gICAgICBtZXJnZWROb2Rlcy5hZGQoZHVwbGljYXRlRW1wdHlQYXRoTm9kZSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJlc3VsdC5wdXNoKG5vZGUpO1xuICAgIH1cbiAgfVxuICAvLyBGb3IgZWFjaCBub2RlIHdoaWNoIGhhcyBjaGlsZHJlbiBmcm9tIG11bHRpcGxlIHNvdXJjZXMsIHdlIG5lZWQgdG8gcmVjb21wdXRlIGEgbmV3IGBUcmVlTm9kZWBcbiAgLy8gYnkgYWxzbyBtZXJnaW5nIHRob3NlIGNoaWxkcmVuLiBUaGlzIGlzIG5lY2Vzc2FyeSB3aGVuIHRoZXJlIGFyZSBtdWx0aXBsZSBlbXB0eSBwYXRoIGNvbmZpZ3NcbiAgLy8gaW4gYSByb3cuIFB1dCBhbm90aGVyIHdheTogd2hlbmV2ZXIgd2UgY29tYmluZSBjaGlsZHJlbiBvZiB0d28gbm9kZXMsIHdlIG5lZWQgdG8gYWxzbyBjaGVja1xuICAvLyBpZiBhbnkgb2YgdGhvc2UgY2hpbGRyZW4gY2FuIGJlIGNvbWJpbmVkIGludG8gYSBzaW5nbGUgbm9kZSBhcyB3ZWxsLlxuICBmb3IgKGNvbnN0IG1lcmdlZE5vZGUgb2YgbWVyZ2VkTm9kZXMpIHtcbiAgICBjb25zdCBtZXJnZWRDaGlsZHJlbiA9IG1lcmdlRW1wdHlQYXRoTWF0Y2hlcyhtZXJnZWROb2RlLmNoaWxkcmVuKTtcbiAgICByZXN1bHQucHVzaChuZXcgVHJlZU5vZGUobWVyZ2VkTm9kZS52YWx1ZSwgbWVyZ2VkQ2hpbGRyZW4pKTtcbiAgfVxuICByZXR1cm4gcmVzdWx0LmZpbHRlcihuID0+ICFtZXJnZWROb2Rlcy5oYXMobikpO1xufVxuXG5mdW5jdGlvbiBjaGVja091dGxldE5hbWVVbmlxdWVuZXNzKG5vZGVzOiBUcmVlTm9kZTxBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90PltdKTogdm9pZCB7XG4gIGNvbnN0IG5hbWVzOiB7W2s6IHN0cmluZ106IEFjdGl2YXRlZFJvdXRlU25hcHNob3R9ID0ge307XG4gIG5vZGVzLmZvckVhY2gobiA9PiB7XG4gICAgY29uc3Qgcm91dGVXaXRoU2FtZU91dGxldE5hbWUgPSBuYW1lc1tuLnZhbHVlLm91dGxldF07XG4gICAgaWYgKHJvdXRlV2l0aFNhbWVPdXRsZXROYW1lKSB7XG4gICAgICBjb25zdCBwID0gcm91dGVXaXRoU2FtZU91dGxldE5hbWUudXJsLm1hcChzID0+IHMudG9TdHJpbmcoKSkuam9pbignLycpO1xuICAgICAgY29uc3QgYyA9IG4udmFsdWUudXJsLm1hcChzID0+IHMudG9TdHJpbmcoKSkuam9pbignLycpO1xuICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLlRXT19TRUdNRU5UU19XSVRIX1NBTUVfT1VUTEVULFxuICAgICAgICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpICYmXG4gICAgICAgICAgICAgIGBUd28gc2VnbWVudHMgY2Fubm90IGhhdmUgdGhlIHNhbWUgb3V0bGV0IG5hbWU6ICcke3B9JyBhbmQgJyR7Y30nLmApO1xuICAgIH1cbiAgICBuYW1lc1tuLnZhbHVlLm91dGxldF0gPSBuLnZhbHVlO1xuICB9KTtcbn1cblxuZnVuY3Rpb24gZ2V0RGF0YShyb3V0ZTogUm91dGUpOiBEYXRhIHtcbiAgcmV0dXJuIHJvdXRlLmRhdGEgfHwge307XG59XG5cbmZ1bmN0aW9uIGdldFJlc29sdmUocm91dGU6IFJvdXRlKTogUmVzb2x2ZURhdGEge1xuICByZXR1cm4gcm91dGUucmVzb2x2ZSB8fCB7fTtcbn1cbiJdfQ==