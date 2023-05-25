/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵRuntimeError as RuntimeError } from '@angular/core';
import { PRIMARY_OUTLET } from './shared';
import { createRoot, squashSegmentGroup, UrlSegment, UrlSegmentGroup, UrlTree } from './url_tree';
import { last, shallowEqual } from './utils/collection';
/**
 * Creates a `UrlTree` relative to an `ActivatedRouteSnapshot`.
 *
 * @publicApi
 *
 *
 * @param relativeTo The `ActivatedRouteSnapshot` to apply the commands to
 * @param commands An array of URL fragments with which to construct the new URL tree.
 * If the path is static, can be the literal URL string. For a dynamic path, pass an array of path
 * segments, followed by the parameters for each segment.
 * The fragments are applied to the one provided in the `relativeTo` parameter.
 * @param queryParams The query parameters for the `UrlTree`. `null` if the `UrlTree` does not have
 *     any query parameters.
 * @param fragment The fragment for the `UrlTree`. `null` if the `UrlTree` does not have a fragment.
 *
 * @usageNotes
 *
 * ```
 * // create /team/33/user/11
 * createUrlTreeFromSnapshot(snapshot, ['/team', 33, 'user', 11]);
 *
 * // create /team/33;expand=true/user/11
 * createUrlTreeFromSnapshot(snapshot, ['/team', 33, {expand: true}, 'user', 11]);
 *
 * // you can collapse static segments like this (this works only with the first passed-in value):
 * createUrlTreeFromSnapshot(snapshot, ['/team/33/user', userId]);
 *
 * // If the first segment can contain slashes, and you do not want the router to split it,
 * // you can do the following:
 * createUrlTreeFromSnapshot(snapshot, [{segmentPath: '/one/two'}]);
 *
 * // create /team/33/(user/11//right:chat)
 * createUrlTreeFromSnapshot(snapshot, ['/team', 33, {outlets: {primary: 'user/11', right:
 * 'chat'}}], null, null);
 *
 * // remove the right secondary node
 * createUrlTreeFromSnapshot(snapshot, ['/team', 33, {outlets: {primary: 'user/11', right: null}}]);
 *
 * // For the examples below, assume the current URL is for the `/team/33/user/11` and the
 * `ActivatedRouteSnapshot` points to `user/11`:
 *
 * // navigate to /team/33/user/11/details
 * createUrlTreeFromSnapshot(snapshot, ['details']);
 *
 * // navigate to /team/33/user/22
 * createUrlTreeFromSnapshot(snapshot, ['../22']);
 *
 * // navigate to /team/44/user/22
 * createUrlTreeFromSnapshot(snapshot, ['../../team/44/user/22']);
 * ```
 */
export function createUrlTreeFromSnapshot(relativeTo, commands, queryParams = null, fragment = null) {
    const relativeToUrlSegmentGroup = createSegmentGroupFromRoute(relativeTo);
    return createUrlTreeFromSegmentGroup(relativeToUrlSegmentGroup, commands, queryParams, fragment);
}
export function createSegmentGroupFromRoute(route) {
    let targetGroup;
    function createSegmentGroupFromRouteRecursive(currentRoute) {
        const childOutlets = {};
        for (const childSnapshot of currentRoute.children) {
            const root = createSegmentGroupFromRouteRecursive(childSnapshot);
            childOutlets[childSnapshot.outlet] = root;
        }
        const segmentGroup = new UrlSegmentGroup(currentRoute.url, childOutlets);
        if (currentRoute === route) {
            targetGroup = segmentGroup;
        }
        return segmentGroup;
    }
    const rootCandidate = createSegmentGroupFromRouteRecursive(route.root);
    const rootSegmentGroup = createRoot(rootCandidate);
    return targetGroup ?? rootSegmentGroup;
}
export function createUrlTreeFromSegmentGroup(relativeTo, commands, queryParams, fragment) {
    let root = relativeTo;
    while (root.parent) {
        root = root.parent;
    }
    // There are no commands so the `UrlTree` goes to the same path as the one created from the
    // `UrlSegmentGroup`. All we need to do is update the `queryParams` and `fragment` without
    // applying any other logic.
    if (commands.length === 0) {
        return tree(root, root, root, queryParams, fragment);
    }
    const nav = computeNavigation(commands);
    if (nav.toRoot()) {
        return tree(root, root, new UrlSegmentGroup([], {}), queryParams, fragment);
    }
    const position = findStartingPositionForTargetGroup(nav, root, relativeTo);
    const newSegmentGroup = position.processChildren ?
        updateSegmentGroupChildren(position.segmentGroup, position.index, nav.commands) :
        updateSegmentGroup(position.segmentGroup, position.index, nav.commands);
    return tree(root, position.segmentGroup, newSegmentGroup, queryParams, fragment);
}
function isMatrixParams(command) {
    return typeof command === 'object' && command != null && !command.outlets && !command.segmentPath;
}
/**
 * Determines if a given command has an `outlets` map. When we encounter a command
 * with an outlets k/v map, we need to apply each outlet individually to the existing segment.
 */
function isCommandWithOutlets(command) {
    return typeof command === 'object' && command != null && command.outlets;
}
function tree(oldRoot, oldSegmentGroup, newSegmentGroup, queryParams, fragment) {
    let qp = {};
    if (queryParams) {
        Object.entries(queryParams).forEach(([name, value]) => {
            qp[name] = Array.isArray(value) ? value.map((v) => `${v}`) : `${value}`;
        });
    }
    let rootCandidate;
    if (oldRoot === oldSegmentGroup) {
        rootCandidate = newSegmentGroup;
    }
    else {
        rootCandidate = replaceSegment(oldRoot, oldSegmentGroup, newSegmentGroup);
    }
    const newRoot = createRoot(squashSegmentGroup(rootCandidate));
    return new UrlTree(newRoot, qp, fragment);
}
/**
 * Replaces the `oldSegment` which is located in some child of the `current` with the `newSegment`.
 * This also has the effect of creating new `UrlSegmentGroup` copies to update references. This
 * shouldn't be necessary but the fallback logic for an invalid ActivatedRoute in the creation uses
 * the Router's current url tree. If we don't create new segment groups, we end up modifying that
 * value.
 */
function replaceSegment(current, oldSegment, newSegment) {
    const children = {};
    Object.entries(current.children).forEach(([outletName, c]) => {
        if (c === oldSegment) {
            children[outletName] = newSegment;
        }
        else {
            children[outletName] = replaceSegment(c, oldSegment, newSegment);
        }
    });
    return new UrlSegmentGroup(current.segments, children);
}
class Navigation {
    constructor(isAbsolute, numberOfDoubleDots, commands) {
        this.isAbsolute = isAbsolute;
        this.numberOfDoubleDots = numberOfDoubleDots;
        this.commands = commands;
        if (isAbsolute && commands.length > 0 && isMatrixParams(commands[0])) {
            throw new RuntimeError(4003 /* RuntimeErrorCode.ROOT_SEGMENT_MATRIX_PARAMS */, (typeof ngDevMode === 'undefined' || ngDevMode) &&
                'Root segment cannot have matrix parameters');
        }
        const cmdWithOutlet = commands.find(isCommandWithOutlets);
        if (cmdWithOutlet && cmdWithOutlet !== last(commands)) {
            throw new RuntimeError(4004 /* RuntimeErrorCode.MISPLACED_OUTLETS_COMMAND */, (typeof ngDevMode === 'undefined' || ngDevMode) &&
                '{outlets:{}} has to be the last command');
        }
    }
    toRoot() {
        return this.isAbsolute && this.commands.length === 1 && this.commands[0] == '/';
    }
}
/** Transforms commands to a normalized `Navigation` */
function computeNavigation(commands) {
    if ((typeof commands[0] === 'string') && commands.length === 1 && commands[0] === '/') {
        return new Navigation(true, 0, commands);
    }
    let numberOfDoubleDots = 0;
    let isAbsolute = false;
    const res = commands.reduce((res, cmd, cmdIdx) => {
        if (typeof cmd === 'object' && cmd != null) {
            if (cmd.outlets) {
                const outlets = {};
                Object.entries(cmd.outlets).forEach(([name, commands]) => {
                    outlets[name] = typeof commands === 'string' ? commands.split('/') : commands;
                });
                return [...res, { outlets }];
            }
            if (cmd.segmentPath) {
                return [...res, cmd.segmentPath];
            }
        }
        if (!(typeof cmd === 'string')) {
            return [...res, cmd];
        }
        if (cmdIdx === 0) {
            cmd.split('/').forEach((urlPart, partIndex) => {
                if (partIndex == 0 && urlPart === '.') {
                    // skip './a'
                }
                else if (partIndex == 0 && urlPart === '') { //  '/a'
                    isAbsolute = true;
                }
                else if (urlPart === '..') { //  '../a'
                    numberOfDoubleDots++;
                }
                else if (urlPart != '') {
                    res.push(urlPart);
                }
            });
            return res;
        }
        return [...res, cmd];
    }, []);
    return new Navigation(isAbsolute, numberOfDoubleDots, res);
}
class Position {
    constructor(segmentGroup, processChildren, index) {
        this.segmentGroup = segmentGroup;
        this.processChildren = processChildren;
        this.index = index;
    }
}
function findStartingPositionForTargetGroup(nav, root, target) {
    if (nav.isAbsolute) {
        return new Position(root, true, 0);
    }
    if (!target) {
        // `NaN` is used only to maintain backwards compatibility with incorrectly mocked
        // `ActivatedRouteSnapshot` in tests. In prior versions of this code, the position here was
        // determined based on an internal property that was rarely mocked, resulting in `NaN`. In
        // reality, this code path should _never_ be touched since `target` is not allowed to be falsey.
        return new Position(root, false, NaN);
    }
    if (target.parent === null) {
        return new Position(target, true, 0);
    }
    const modifier = isMatrixParams(nav.commands[0]) ? 0 : 1;
    const index = target.segments.length - 1 + modifier;
    return createPositionApplyingDoubleDots(target, index, nav.numberOfDoubleDots);
}
function createPositionApplyingDoubleDots(group, index, numberOfDoubleDots) {
    let g = group;
    let ci = index;
    let dd = numberOfDoubleDots;
    while (dd > ci) {
        dd -= ci;
        g = g.parent;
        if (!g) {
            throw new RuntimeError(4005 /* RuntimeErrorCode.INVALID_DOUBLE_DOTS */, (typeof ngDevMode === 'undefined' || ngDevMode) && 'Invalid number of \'../\'');
        }
        ci = g.segments.length;
    }
    return new Position(g, false, ci - dd);
}
function getOutlets(commands) {
    if (isCommandWithOutlets(commands[0])) {
        return commands[0].outlets;
    }
    return { [PRIMARY_OUTLET]: commands };
}
function updateSegmentGroup(segmentGroup, startIndex, commands) {
    if (!segmentGroup) {
        segmentGroup = new UrlSegmentGroup([], {});
    }
    if (segmentGroup.segments.length === 0 && segmentGroup.hasChildren()) {
        return updateSegmentGroupChildren(segmentGroup, startIndex, commands);
    }
    const m = prefixedWith(segmentGroup, startIndex, commands);
    const slicedCommands = commands.slice(m.commandIndex);
    if (m.match && m.pathIndex < segmentGroup.segments.length) {
        const g = new UrlSegmentGroup(segmentGroup.segments.slice(0, m.pathIndex), {});
        g.children[PRIMARY_OUTLET] =
            new UrlSegmentGroup(segmentGroup.segments.slice(m.pathIndex), segmentGroup.children);
        return updateSegmentGroupChildren(g, 0, slicedCommands);
    }
    else if (m.match && slicedCommands.length === 0) {
        return new UrlSegmentGroup(segmentGroup.segments, {});
    }
    else if (m.match && !segmentGroup.hasChildren()) {
        return createNewSegmentGroup(segmentGroup, startIndex, commands);
    }
    else if (m.match) {
        return updateSegmentGroupChildren(segmentGroup, 0, slicedCommands);
    }
    else {
        return createNewSegmentGroup(segmentGroup, startIndex, commands);
    }
}
function updateSegmentGroupChildren(segmentGroup, startIndex, commands) {
    if (commands.length === 0) {
        return new UrlSegmentGroup(segmentGroup.segments, {});
    }
    else {
        const outlets = getOutlets(commands);
        const children = {};
        // If the set of commands does not apply anything to the primary outlet and the child segment is
        // an empty path primary segment on its own, we want to apply the commands to the empty child
        // path rather than here. The outcome is that the empty primary child is effectively removed
        // from the final output UrlTree. Imagine the following config:
        //
        // {path: '', children: [{path: '**', outlet: 'popup'}]}.
        //
        // Navigation to /(popup:a) will activate the child outlet correctly Given a follow-up
        // navigation with commands
        // ['/', {outlets: {'popup': 'b'}}], we _would not_ want to apply the outlet commands to the
        // root segment because that would result in
        // //(popup:a)(popup:b) since the outlet command got applied one level above where it appears in
        // the `ActivatedRoute` rather than updating the existing one.
        //
        // Because empty paths do not appear in the URL segments and the fact that the segments used in
        // the output `UrlTree` are squashed to eliminate these empty paths where possible
        // https://github.com/angular/angular/blob/13f10de40e25c6900ca55bd83b36bd533dacfa9e/packages/router/src/url_tree.ts#L755
        // it can be hard to determine what is the right thing to do when applying commands to a
        // `UrlSegmentGroup` that is created from an "unsquashed"/expanded `ActivatedRoute` tree.
        // This code effectively "squashes" empty path primary routes when they have no siblings on
        // the same level of the tree.
        if (!outlets[PRIMARY_OUTLET] && segmentGroup.children[PRIMARY_OUTLET] &&
            segmentGroup.numberOfChildren === 1 &&
            segmentGroup.children[PRIMARY_OUTLET].segments.length === 0) {
            const childrenOfEmptyChild = updateSegmentGroupChildren(segmentGroup.children[PRIMARY_OUTLET], startIndex, commands);
            return new UrlSegmentGroup(segmentGroup.segments, childrenOfEmptyChild.children);
        }
        Object.entries(outlets).forEach(([outlet, commands]) => {
            if (typeof commands === 'string') {
                commands = [commands];
            }
            if (commands !== null) {
                children[outlet] = updateSegmentGroup(segmentGroup.children[outlet], startIndex, commands);
            }
        });
        Object.entries(segmentGroup.children).forEach(([childOutlet, child]) => {
            if (outlets[childOutlet] === undefined) {
                children[childOutlet] = child;
            }
        });
        return new UrlSegmentGroup(segmentGroup.segments, children);
    }
}
function prefixedWith(segmentGroup, startIndex, commands) {
    let currentCommandIndex = 0;
    let currentPathIndex = startIndex;
    const noMatch = { match: false, pathIndex: 0, commandIndex: 0 };
    while (currentPathIndex < segmentGroup.segments.length) {
        if (currentCommandIndex >= commands.length)
            return noMatch;
        const path = segmentGroup.segments[currentPathIndex];
        const command = commands[currentCommandIndex];
        // Do not try to consume command as part of the prefixing if it has outlets because it can
        // contain outlets other than the one being processed. Consuming the outlets command would
        // result in other outlets being ignored.
        if (isCommandWithOutlets(command)) {
            break;
        }
        const curr = `${command}`;
        const next = currentCommandIndex < commands.length - 1 ? commands[currentCommandIndex + 1] : null;
        if (currentPathIndex > 0 && curr === undefined)
            break;
        if (curr && next && (typeof next === 'object') && next.outlets === undefined) {
            if (!compare(curr, next, path))
                return noMatch;
            currentCommandIndex += 2;
        }
        else {
            if (!compare(curr, {}, path))
                return noMatch;
            currentCommandIndex++;
        }
        currentPathIndex++;
    }
    return { match: true, pathIndex: currentPathIndex, commandIndex: currentCommandIndex };
}
function createNewSegmentGroup(segmentGroup, startIndex, commands) {
    const paths = segmentGroup.segments.slice(0, startIndex);
    let i = 0;
    while (i < commands.length) {
        const command = commands[i];
        if (isCommandWithOutlets(command)) {
            const children = createNewSegmentChildren(command.outlets);
            return new UrlSegmentGroup(paths, children);
        }
        // if we start with an object literal, we need to reuse the path part from the segment
        if (i === 0 && isMatrixParams(commands[0])) {
            const p = segmentGroup.segments[startIndex];
            paths.push(new UrlSegment(p.path, stringify(commands[0])));
            i++;
            continue;
        }
        const curr = isCommandWithOutlets(command) ? command.outlets[PRIMARY_OUTLET] : `${command}`;
        const next = (i < commands.length - 1) ? commands[i + 1] : null;
        if (curr && next && isMatrixParams(next)) {
            paths.push(new UrlSegment(curr, stringify(next)));
            i += 2;
        }
        else {
            paths.push(new UrlSegment(curr, {}));
            i++;
        }
    }
    return new UrlSegmentGroup(paths, {});
}
function createNewSegmentChildren(outlets) {
    const children = {};
    Object.entries(outlets).forEach(([outlet, commands]) => {
        if (typeof commands === 'string') {
            commands = [commands];
        }
        if (commands !== null) {
            children[outlet] = createNewSegmentGroup(new UrlSegmentGroup([], {}), 0, commands);
        }
    });
    return children;
}
function stringify(params) {
    const res = {};
    Object.entries(params).forEach(([k, v]) => res[k] = `${v}`);
    return res;
}
function compare(path, params, segment) {
    return path == segment.path && shallowEqual(params, segment.parameters);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY3JlYXRlX3VybF90cmVlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvcm91dGVyL3NyYy9jcmVhdGVfdXJsX3RyZWUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLGFBQWEsSUFBSSxZQUFZLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFJNUQsT0FBTyxFQUFTLGNBQWMsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUNoRCxPQUFPLEVBQUMsVUFBVSxFQUFFLGtCQUFrQixFQUFFLFVBQVUsRUFBRSxlQUFlLEVBQUUsT0FBTyxFQUFDLE1BQU0sWUFBWSxDQUFDO0FBQ2hHLE9BQU8sRUFBQyxJQUFJLEVBQUUsWUFBWSxFQUFDLE1BQU0sb0JBQW9CLENBQUM7QUFHdEQ7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBa0RHO0FBQ0gsTUFBTSxVQUFVLHlCQUF5QixDQUNyQyxVQUFrQyxFQUFFLFFBQWUsRUFBRSxjQUEyQixJQUFJLEVBQ3BGLFdBQXdCLElBQUk7SUFDOUIsTUFBTSx5QkFBeUIsR0FBRywyQkFBMkIsQ0FBQyxVQUFVLENBQUMsQ0FBQztJQUMxRSxPQUFPLDZCQUE2QixDQUFDLHlCQUF5QixFQUFFLFFBQVEsRUFBRSxXQUFXLEVBQUUsUUFBUSxDQUFDLENBQUM7QUFDbkcsQ0FBQztBQUVELE1BQU0sVUFBVSwyQkFBMkIsQ0FBQyxLQUE2QjtJQUN2RSxJQUFJLFdBQXNDLENBQUM7SUFFM0MsU0FBUyxvQ0FBb0MsQ0FBQyxZQUFvQztRQUVoRixNQUFNLFlBQVksR0FBd0MsRUFBRSxDQUFDO1FBQzdELEtBQUssTUFBTSxhQUFhLElBQUksWUFBWSxDQUFDLFFBQVEsRUFBRTtZQUNqRCxNQUFNLElBQUksR0FBRyxvQ0FBb0MsQ0FBQyxhQUFhLENBQUMsQ0FBQztZQUNqRSxZQUFZLENBQUMsYUFBYSxDQUFDLE1B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RCxNQUFNLENBQUMsT0FBTyxDQUFDLE9BQU8sQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsTUFBTSxFQUFFLFFBQVEsQ0FBQyxFQUFFLEVBQUU7UUFDckQsSUFBSSxPQUFPLFFBQVEsS0FBSyxRQUFRLEVBQUU7WUFDaEMsUUFBUSxHQUFHLENBQUMsUUFBUSxDQUFDLENBQUM7U0FDdkI7UUFDRCxJQUFJLFFBQVEsS0FBSyxJQUFJLEVBQUU7WUFDckIsUUFBUSxDQUFDLE1BQU0sQ0FBQyxHQUFHLHFCQUFxQixDQUFDLElBQUksZUFBZSxDQUFDLEVBQUUsRUFBRSxFQUFFLENBQUMsRUFBRSxDQUFDLEVBQUUsUUFBUSxDQUFDLENBQUM7U0FDcEY7SUFDSCxDQUFDLENBQUMsQ0FBQztJQUNILE9BQU8sUUFBUSxDQUFDO0FBQ2xCLENBQUM7QUFFRCxTQUFTLFNBQVMsQ0FBQyxNQUE0QjtJQUM3QyxNQUFNLEdBQUcsR0FBNEIsRUFBRSxDQUFDO0lBQ3hDLE1BQU0sQ0FBQyxPQUFPLENBQUMsTUFBTSxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxHQUFHLENBQUMsRUFBRSxDQUFDLENBQUM7SUFDNUQsT0FBTyxHQUFHLENBQUM7QUFDYixDQUFDO0FBRUQsU0FBUyxPQUFPLENBQUMsSUFBWSxFQUFFLE1BQTRCLEVBQUUsT0FBbUI7SUFDOUUsT0FBTyxJQUFJLElBQUksT0FBTyxDQUFDLElBQUksSUFBSSxZQUFZLENBQUMsTUFBTSxFQUFFLE9BQU8sQ0FBQyxVQUFVLENBQUMsQ0FBQztBQUMxRSxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7ybVSdW50aW1lRXJyb3IgYXMgUnVudGltZUVycm9yfSBmcm9tICdAYW5ndWxhci9jb3JlJztcblxuaW1wb3J0IHtSdW50aW1lRXJyb3JDb2RlfSBmcm9tICcuL2Vycm9ycyc7XG5pbXBvcnQge0FjdGl2YXRlZFJvdXRlU25hcHNob3R9IGZyb20gJy4vcm91dGVyX3N0YXRlJztcbmltcG9ydCB7UGFyYW1zLCBQUklNQVJZX09VVExFVH0gZnJvbSAnLi9zaGFyZWQnO1xuaW1wb3J0IHtjcmVhdGVSb290LCBzcXVhc2hTZWdtZW50R3JvdXAsIFVybFNlZ21lbnQsIFVybFNlZ21lbnRHcm91cCwgVXJsVHJlZX0gZnJvbSAnLi91cmxfdHJlZSc7XG5pbXBvcnQge2xhc3QsIHNoYWxsb3dFcXVhbH0gZnJvbSAnLi91dGlscy9jb2xsZWN0aW9uJztcblxuXG4vKipcbiAqIENyZWF0ZXMgYSBgVXJsVHJlZWAgcmVsYXRpdmUgdG8gYW4gYEFjdGl2YXRlZFJvdXRlU25hcHNob3RgLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqXG4gKlxuICogQHBhcmFtIHJlbGF0aXZlVG8gVGhlIGBBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90YCB0byBhcHBseSB0aGUgY29tbWFuZHMgdG9cbiAqIEBwYXJhbSBjb21tYW5kcyBBbiBhcnJheSBvZiBVUkwgZnJhZ21lbnRzIHdpdGggd2hpY2ggdG8gY29uc3RydWN0IHRoZSBuZXcgVVJMIHRyZWUuXG4gKiBJZiB0aGUgcGF0aCBpcyBzdGF0aWMsIGNhbiBiZSB0aGUgbGl0ZXJhbCBVUkwgc3RyaW5nLiBGb3IgYSBkeW5hbWljIHBhdGgsIHBhc3MgYW4gYXJyYXkgb2YgcGF0aFxuICogc2VnbWVudHMsIGZvbGxvd2VkIGJ5IHRoZSBwYXJhbWV0ZXJzIGZvciBlYWNoIHNlZ21lbnQuXG4gKiBUaGUgZnJhZ21lbnRzIGFyZSBhcHBsaWVkIHRvIHRoZSBvbmUgcHJvdmlkZWQgaW4gdGhlIGByZWxhdGl2ZVRvYCBwYXJhbWV0ZXIuXG4gKiBAcGFyYW0gcXVlcnlQYXJhbXMgVGhlIHF1ZXJ5IHBhcmFtZXRlcnMgZm9yIHRoZSBgVXJsVHJlZWAuIGBudWxsYCBpZiB0aGUgYFVybFRyZWVgIGRvZXMgbm90IGhhdmVcbiAqICAgICBhbnkgcXVlcnkgcGFyYW1ldGVycy5cbiAqIEBwYXJhbSBmcmFnbWVudCBUaGUgZnJhZ21lbnQgZm9yIHRoZSBgVXJsVHJlZWAuIGBudWxsYCBpZiB0aGUgYFVybFRyZWVgIGRvZXMgbm90IGhhdmUgYSBmcmFnbWVudC5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICpcbiAqIGBgYFxuICogLy8gY3JlYXRlIC90ZWFtLzMzL3VzZXIvMTFcbiAqIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3Qoc25hcHNob3QsIFsnL3RlYW0nLCAzMywgJ3VzZXInLCAxMV0pO1xuICpcbiAqIC8vIGNyZWF0ZSAvdGVhbS8zMztleHBhbmQ9dHJ1ZS91c2VyLzExXG4gKiBjcmVhdGVVcmxUcmVlRnJvbVNuYXBzaG90KHNuYXBzaG90LCBbJy90ZWFtJywgMzMsIHtleHBhbmQ6IHRydWV9LCAndXNlcicsIDExXSk7XG4gKlxuICogLy8geW91IGNhbiBjb2xsYXBzZSBzdGF0aWMgc2VnbWVudHMgbGlrZSB0aGlzICh0aGlzIHdvcmtzIG9ubHkgd2l0aCB0aGUgZmlyc3QgcGFzc2VkLWluIHZhbHVlKTpcbiAqIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3Qoc25hcHNob3QsIFsnL3RlYW0vMzMvdXNlcicsIHVzZXJJZF0pO1xuICpcbiAqIC8vIElmIHRoZSBmaXJzdCBzZWdtZW50IGNhbiBjb250YWluIHNsYXNoZXMsIGFuZCB5b3UgZG8gbm90IHdhbnQgdGhlIHJvdXRlciB0byBzcGxpdCBpdCxcbiAqIC8vIHlvdSBjYW4gZG8gdGhlIGZvbGxvd2luZzpcbiAqIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3Qoc25hcHNob3QsIFt7c2VnbWVudFBhdGg6ICcvb25lL3R3byd9XSk7XG4gKlxuICogLy8gY3JlYXRlIC90ZWFtLzMzLyh1c2VyLzExLy9yaWdodDpjaGF0KVxuICogY3JlYXRlVXJsVHJlZUZyb21TbmFwc2hvdChzbmFwc2hvdCwgWycvdGVhbScsIDMzLCB7b3V0bGV0czoge3ByaW1hcnk6ICd1c2VyLzExJywgcmlnaHQ6XG4gKiAnY2hhdCd9fV0sIG51bGwsIG51bGwpO1xuICpcbiAqIC8vIHJlbW92ZSB0aGUgcmlnaHQgc2Vjb25kYXJ5IG5vZGVcbiAqIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3Qoc25hcHNob3QsIFsnL3RlYW0nLCAzMywge291dGxldHM6IHtwcmltYXJ5OiAndXNlci8xMScsIHJpZ2h0OiBudWxsfX1dKTtcbiAqXG4gKiAvLyBGb3IgdGhlIGV4YW1wbGVzIGJlbG93LCBhc3N1bWUgdGhlIGN1cnJlbnQgVVJMIGlzIGZvciB0aGUgYC90ZWFtLzMzL3VzZXIvMTFgIGFuZCB0aGVcbiAqIGBBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90YCBwb2ludHMgdG8gYHVzZXIvMTFgOlxuICpcbiAqIC8vIG5hdmlnYXRlIHRvIC90ZWFtLzMzL3VzZXIvMTEvZGV0YWlsc1xuICogY3JlYXRlVXJsVHJlZUZyb21TbmFwc2hvdChzbmFwc2hvdCwgWydkZXRhaWxzJ10pO1xuICpcbiAqIC8vIG5hdmlnYXRlIHRvIC90ZWFtLzMzL3VzZXIvMjJcbiAqIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3Qoc25hcHNob3QsIFsnLi4vMjInXSk7XG4gKlxuICogLy8gbmF2aWdhdGUgdG8gL3RlYW0vNDQvdXNlci8yMlxuICogY3JlYXRlVXJsVHJlZUZyb21TbmFwc2hvdChzbmFwc2hvdCwgWycuLi8uLi90ZWFtLzQ0L3VzZXIvMjInXSk7XG4gKiBgYGBcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVVybFRyZWVGcm9tU25hcHNob3QoXG4gICAgcmVsYXRpdmVUbzogQWN0aXZhdGVkUm91dGVTbmFwc2hvdCwgY29tbWFuZHM6IGFueVtdLCBxdWVyeVBhcmFtczogUGFyYW1zfG51bGwgPSBudWxsLFxuICAgIGZyYWdtZW50OiBzdHJpbmd8bnVsbCA9IG51bGwpOiBVcmxUcmVlIHtcbiAgY29uc3QgcmVsYXRpdmVUb1VybFNlZ21lbnRHcm91cCA9IGNyZWF0ZVNlZ21lbnRHcm91cEZyb21Sb3V0ZShyZWxhdGl2ZVRvKTtcbiAgcmV0dXJuIGNyZWF0ZVVybFRyZWVGcm9tU2VnbWVudEdyb3VwKHJlbGF0aXZlVG9VcmxTZWdtZW50R3JvdXAsIGNvbW1hbmRzLCBxdWVyeVBhcmFtcywgZnJhZ21lbnQpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlU2VnbWVudEdyb3VwRnJvbVJvdXRlKHJvdXRlOiBBY3RpdmF0ZWRSb3V0ZVNuYXBzaG90KTogVXJsU2VnbWVudEdyb3VwIHtcbiAgbGV0IHRhcmdldEdyb3VwOiBVcmxTZWdtZW50R3JvdXB8dW5kZWZpbmVkO1xuXG4gIGZ1bmN0aW9uIGNyZWF0ZVNlZ21lbnRHcm91cEZyb21Sb3V0ZVJlY3Vyc2l2ZShjdXJyZW50Um91dGU6IEFjdGl2YXRlZFJvdXRlU25hcHNob3QpOlxuICAgICAgVXJsU2VnbWVudEdyb3VwIHtcbiAgICBjb25zdCBjaGlsZE91dGxldHM6IHtbb3V0bGV0OiBzdHJpbmddOiBVcmxTZWdtZW50R3JvdXB9ID0ge307XG4gICAgZm9yIChjb25zdCBjaGlsZFNuYXBzaG90IG9mIGN1cnJlbnRSb3V0ZS5jaGlsZHJlbikge1xuICAgICAgY29uc3Qgcm9vdCA9IGNyZWF0ZVNlZ21lbnRHcm91cEZyb21Sb3V0ZVJlY3Vyc2l2ZShjaGlsZFNuYXBzaG90KTtcbiAgICAgIGNoaWxkT3V0bGV0c1tjaGlsZFNuYXBzaG90Lm91dGxldF0gPSByb290O1xuICAgIH1cbiAgICBjb25zdCBzZWdtZW50R3JvdXAgPSBuZXcgVXJsU2VnbWVudEdyb3VwKGN1cnJlbnRSb3V0ZS51cmwsIGNoaWxkT3V0bGV0cyk7XG4gICAgaWYgKGN1cnJlbnRSb3V0ZSA9PT0gcm91dGUpIHtcbiAgICAgIHRhcmdldEdyb3VwID0gc2VnbWVudEdyb3VwO1xuICAgIH1cbiAgICByZXR1cm4gc2VnbWVudEdyb3VwO1xuICB9XG4gIGNvbnN0IHJvb3RDYW5kaWRhdGUgPSBjcmVhdGVTZWdtZW50R3JvdXBGcm9tUm91dGVSZWN1cnNpdmUocm91dGUucm9vdCk7XG4gIGNvbnN0IHJvb3RTZWdtZW50R3JvdXAgPSBjcmVhdGVSb290KHJvb3RDYW5kaWRhdGUpO1xuXG4gIHJldHVybiB0YXJnZXRHcm91cCA/PyByb290U2VnbWVudEdyb3VwO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVXJsVHJlZUZyb21TZWdtZW50R3JvdXAoXG4gICAgcmVsYXRpdmVUbzogVXJsU2VnbWVudEdyb3VwLCBjb21tYW5kczogYW55W10sIHF1ZXJ5UGFyYW1zOiBQYXJhbXN8bnVsbCxcbiAgICBmcmFnbWVudDogc3RyaW5nfG51bGwpOiBVcmxUcmVlIHtcbiAgbGV0IHJvb3QgPSByZWxhdGl2ZVRvO1xuICB3aGlsZSAocm9vdC5wYXJlbnQpIHtcbiAgICByb290ID0gcm9vdC5wYXJlbnQ7XG4gIH1cbiAgLy8gVGhlcmUgYXJlIG5vIGNvbW1hbmRzIHNvIHRoZSBgVXJsVHJlZWAgZ29lcyB0byB0aGUgc2FtZSBwYXRoIGFzIHRoZSBvbmUgY3JlYXRlZCBmcm9tIHRoZVxuICAvLyBgVXJsU2VnbWVudEdyb3VwYC4gQWxsIHdlIG5lZWQgdG8gZG8gaXMgdXBkYXRlIHRoZSBgcXVlcnlQYXJhbXNgIGFuZCBgZnJhZ21lbnRgIHdpdGhvdXRcbiAgLy8gYXBwbHlpbmcgYW55IG90aGVyIGxvZ2ljLlxuICBpZiAoY29tbWFuZHMubGVuZ3RoID09PSAwKSB7XG4gICAgcmV0dXJuIHRyZWUocm9vdCwgcm9vdCwgcm9vdCwgcXVlcnlQYXJhbXMsIGZyYWdtZW50KTtcbiAgfVxuXG4gIGNvbnN0IG5hdiA9IGNvbXB1dGVOYXZpZ2F0aW9uKGNvbW1hbmRzKTtcblxuICBpZiAobmF2LnRvUm9vdCgpKSB7XG4gICAgcmV0dXJuIHRyZWUocm9vdCwgcm9vdCwgbmV3IFVybFNlZ21lbnRHcm91cChbXSwge30pLCBxdWVyeVBhcmFtcywgZnJhZ21lbnQpO1xuICB9XG5cbiAgY29uc3QgcG9zaXRpb24gPSBmaW5kU3RhcnRpbmdQb3NpdGlvbkZvclRhcmdldEdyb3VwKG5hdiwgcm9vdCwgcmVsYXRpdmVUbyk7XG4gIGNvbnN0IG5ld1NlZ21lbnRHcm91cCA9IHBvc2l0aW9uLnByb2Nlc3NDaGlsZHJlbiA/XG4gICAgICB1cGRhdGVTZWdtZW50R3JvdXBDaGlsZHJlbihwb3NpdGlvbi5zZWdtZW50R3JvdXAsIHBvc2l0aW9uLmluZGV4LCBuYXYuY29tbWFuZHMpIDpcbiAgICAgIHVwZGF0ZVNlZ21lbnRHcm91cChwb3NpdGlvbi5zZWdtZW50R3JvdXAsIHBvc2l0aW9uLmluZGV4LCBuYXYuY29tbWFuZHMpO1xuICByZXR1cm4gdHJlZShyb290LCBwb3NpdGlvbi5zZWdtZW50R3JvdXAsIG5ld1NlZ21lbnRHcm91cCwgcXVlcnlQYXJhbXMsIGZyYWdtZW50KTtcbn1cblxuZnVuY3Rpb24gaXNNYXRyaXhQYXJhbXMoY29tbWFuZDogYW55KTogYm9vbGVhbiB7XG4gIHJldHVybiB0eXBlb2YgY29tbWFuZCA9PT0gJ29iamVjdCcgJiYgY29tbWFuZCAhPSBudWxsICYmICFjb21tYW5kLm91dGxldHMgJiYgIWNvbW1hbmQuc2VnbWVudFBhdGg7XG59XG5cbi8qKlxuICogRGV0ZXJtaW5lcyBpZiBhIGdpdmVuIGNvbW1hbmQgaGFzIGFuIGBvdXRsZXRzYCBtYXAuIFdoZW4gd2UgZW5jb3VudGVyIGEgY29tbWFuZFxuICogd2l0aCBhbiBvdXRsZXRzIGsvdiBtYXAsIHdlIG5lZWQgdG8gYXBwbHkgZWFjaCBvdXRsZXQgaW5kaXZpZHVhbGx5IHRvIHRoZSBleGlzdGluZyBzZWdtZW50LlxuICovXG5mdW5jdGlvbiBpc0NvbW1hbmRXaXRoT3V0bGV0cyhjb21tYW5kOiBhbnkpOiBjb21tYW5kIGlzIHtvdXRsZXRzOiB7W2tleTogc3RyaW5nXTogYW55fX0ge1xuICByZXR1cm4gdHlwZW9mIGNvbW1hbmQgPT09ICdvYmplY3QnICYmIGNvbW1hbmQgIT0gbnVsbCAmJiBjb21tYW5kLm91dGxldHM7XG59XG5cbmZ1bmN0aW9uIHRyZWUoXG4gICAgb2xkUm9vdDogVXJsU2VnbWVudEdyb3VwLCBvbGRTZWdtZW50R3JvdXA6IFVybFNlZ21lbnRHcm91cCwgbmV3U2VnbWVudEdyb3VwOiBVcmxTZWdtZW50R3JvdXAsXG4gICAgcXVlcnlQYXJhbXM6IFBhcmFtc3xudWxsLCBmcmFnbWVudDogc3RyaW5nfG51bGwpOiBVcmxUcmVlIHtcbiAgbGV0IHFwOiBhbnkgPSB7fTtcbiAgaWYgKHF1ZXJ5UGFyYW1zKSB7XG4gICAgT2JqZWN0LmVudHJpZXMocXVlcnlQYXJhbXMpLmZvckVhY2goKFtuYW1lLCB2YWx1ZV0pID0+IHtcbiAgICAgIHFwW25hbWVdID0gQXJyYXkuaXNBcnJheSh2YWx1ZSkgPyB2YWx1ZS5tYXAoKHY6IGFueSkgPT4gYCR7dn1gKSA6IGAke3ZhbHVlfWA7XG4gICAgfSk7XG4gIH1cblxuICBsZXQgcm9vdENhbmRpZGF0ZTogVXJsU2VnbWVudEdyb3VwO1xuICBpZiAob2xkUm9vdCA9PT0gb2xkU2VnbWVudEdyb3VwKSB7XG4gICAgcm9vdENhbmRpZGF0ZSA9IG5ld1NlZ21lbnRHcm91cDtcbiAgfSBlbHNlIHtcbiAgICByb290Q2FuZGlkYXRlID0gcmVwbGFjZVNlZ21lbnQob2xkUm9vdCwgb2xkU2VnbWVudEdyb3VwLCBuZXdTZWdtZW50R3JvdXApO1xuICB9XG5cbiAgY29uc3QgbmV3Um9vdCA9IGNyZWF0ZVJvb3Qoc3F1YXNoU2VnbWVudEdyb3VwKHJvb3RDYW5kaWRhdGUpKTtcbiAgcmV0dXJuIG5ldyBVcmxUcmVlKG5ld1Jvb3QsIHFwLCBmcmFnbWVudCk7XG59XG5cbi8qKlxuICogUmVwbGFjZXMgdGhlIGBvbGRTZWdtZW50YCB3aGljaCBpcyBsb2NhdGVkIGluIHNvbWUgY2hpbGQgb2YgdGhlIGBjdXJyZW50YCB3aXRoIHRoZSBgbmV3U2VnbWVudGAuXG4gKiBUaGlzIGFsc28gaGFzIHRoZSBlZmZlY3Qgb2YgY3JlYXRpbmcgbmV3IGBVcmxTZWdtZW50R3JvdXBgIGNvcGllcyB0byB1cGRhdGUgcmVmZXJlbmNlcy4gVGhpc1xuICogc2hvdWxkbid0IGJlIG5lY2Vzc2FyeSBidXQgdGhlIGZhbGxiYWNrIGxvZ2ljIGZvciBhbiBpbnZhbGlkIEFjdGl2YXRlZFJvdXRlIGluIHRoZSBjcmVhdGlvbiB1c2VzXG4gKiB0aGUgUm91dGVyJ3MgY3VycmVudCB1cmwgdHJlZS4gSWYgd2UgZG9uJ3QgY3JlYXRlIG5ldyBzZWdtZW50IGdyb3Vwcywgd2UgZW5kIHVwIG1vZGlmeWluZyB0aGF0XG4gKiB2YWx1ZS5cbiAqL1xuZnVuY3Rpb24gcmVwbGFjZVNlZ21lbnQoXG4gICAgY3VycmVudDogVXJsU2VnbWVudEdyb3VwLCBvbGRTZWdtZW50OiBVcmxTZWdtZW50R3JvdXAsXG4gICAgbmV3U2VnbWVudDogVXJsU2VnbWVudEdyb3VwKTogVXJsU2VnbWVudEdyb3VwIHtcbiAgY29uc3QgY2hpbGRyZW46IHtba2V5OiBzdHJpbmddOiBVcmxTZWdtZW50R3JvdXB9ID0ge307XG4gIE9iamVjdC5lbnRyaWVzKGN1cnJlbnQuY2hpbGRyZW4pLmZvckVhY2goKFtvdXRsZXROYW1lLCBjXSkgPT4ge1xuICAgIGlmIChjID09PSBvbGRTZWdtZW50KSB7XG4gICAgICBjaGlsZHJlbltvdXRsZXROYW1lXSA9IG5ld1NlZ21lbnQ7XG4gICAgfSBlbHNlIHtcbiAgICAgIGNoaWxkcmVuW291dGxldE5hbWVdID0gcmVwbGFjZVNlZ21lbnQoYywgb2xkU2VnbWVudCwgbmV3U2VnbWVudCk7XG4gICAgfVxuICB9KTtcbiAgcmV0dXJuIG5ldyBVcmxTZWdtZW50R3JvdXAoY3VycmVudC5zZWdtZW50cywgY2hpbGRyZW4pO1xufVxuXG5jbGFzcyBOYXZpZ2F0aW9uIHtcbiAgY29uc3RydWN0b3IoXG4gICAgICBwdWJsaWMgaXNBYnNvbHV0ZTogYm9vbGVhbiwgcHVibGljIG51bWJlck9mRG91YmxlRG90czogbnVtYmVyLCBwdWJsaWMgY29tbWFuZHM6IGFueVtdKSB7XG4gICAgaWYgKGlzQWJzb2x1dGUgJiYgY29tbWFuZHMubGVuZ3RoID4gMCAmJiBpc01hdHJpeFBhcmFtcyhjb21tYW5kc1swXSkpIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5ST09UX1NFR01FTlRfTUFUUklYX1BBUkFNUyxcbiAgICAgICAgICAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSAmJlxuICAgICAgICAgICAgICAnUm9vdCBzZWdtZW50IGNhbm5vdCBoYXZlIG1hdHJpeCBwYXJhbWV0ZXJzJyk7XG4gICAgfVxuXG4gICAgY29uc3QgY21kV2l0aE91dGxldCA9IGNvbW1hbmRzLmZpbmQoaXNDb21tYW5kV2l0aE91dGxldHMpO1xuICAgIGlmIChjbWRXaXRoT3V0bGV0ICYmIGNtZFdpdGhPdXRsZXQgIT09IGxhc3QoY29tbWFuZHMpKSB7XG4gICAgICB0aHJvdyBuZXcgUnVudGltZUVycm9yKFxuICAgICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuTUlTUExBQ0VEX09VVExFVFNfQ09NTUFORCxcbiAgICAgICAgICAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSAmJlxuICAgICAgICAgICAgICAne291dGxldHM6e319IGhhcyB0byBiZSB0aGUgbGFzdCBjb21tYW5kJyk7XG4gICAgfVxuICB9XG5cbiAgcHVibGljIHRvUm9vdCgpOiBib29sZWFuIHtcbiAgICByZXR1cm4gdGhpcy5pc0Fic29sdXRlICYmIHRoaXMuY29tbWFuZHMubGVuZ3RoID09PSAxICYmIHRoaXMuY29tbWFuZHNbMF0gPT0gJy8nO1xuICB9XG59XG5cbi8qKiBUcmFuc2Zvcm1zIGNvbW1hbmRzIHRvIGEgbm9ybWFsaXplZCBgTmF2aWdhdGlvbmAgKi9cbmZ1bmN0aW9uIGNvbXB1dGVOYXZpZ2F0aW9uKGNvbW1hbmRzOiBhbnlbXSk6IE5hdmlnYXRpb24ge1xuICBpZiAoKHR5cGVvZiBjb21tYW5kc1swXSA9PT0gJ3N0cmluZycpICYmIGNvbW1hbmRzLmxlbmd0aCA9PT0gMSAmJiBjb21tYW5kc1swXSA9PT0gJy8nKSB7XG4gICAgcmV0dXJuIG5ldyBOYXZpZ2F0aW9uKHRydWUsIDAsIGNvbW1hbmRzKTtcbiAgfVxuXG4gIGxldCBudW1iZXJPZkRvdWJsZURvdHMgPSAwO1xuICBsZXQgaXNBYnNvbHV0ZSA9IGZhbHNlO1xuXG4gIGNvbnN0IHJlczogYW55W10gPSBjb21tYW5kcy5yZWR1Y2UoKHJlcywgY21kLCBjbWRJZHgpID0+IHtcbiAgICBpZiAodHlwZW9mIGNtZCA9PT0gJ29iamVjdCcgJiYgY21kICE9IG51bGwpIHtcbiAgICAgIGlmIChjbWQub3V0bGV0cykge1xuICAgICAgICBjb25zdCBvdXRsZXRzOiB7W2s6IHN0cmluZ106IGFueX0gPSB7fTtcbiAgICAgICAgT2JqZWN0LmVudHJpZXMoY21kLm91dGxldHMpLmZvckVhY2goKFtuYW1lLCBjb21tYW5kc10pID0+IHtcbiAgICAgICAgICBvdXRsZXRzW25hbWVdID0gdHlwZW9mIGNvbW1hbmRzID09PSAnc3RyaW5nJyA/IGNvbW1hbmRzLnNwbGl0KCcvJykgOiBjb21tYW5kcztcbiAgICAgICAgfSk7XG4gICAgICAgIHJldHVybiBbLi4ucmVzLCB7b3V0bGV0c31dO1xuICAgICAgfVxuXG4gICAgICBpZiAoY21kLnNlZ21lbnRQYXRoKSB7XG4gICAgICAgIHJldHVybiBbLi4ucmVzLCBjbWQuc2VnbWVudFBhdGhdO1xuICAgICAgfVxuICAgIH1cblxuICAgIGlmICghKHR5cGVvZiBjbWQgPT09ICdzdHJpbmcnKSkge1xuICAgICAgcmV0dXJuIFsuLi5yZXMsIGNtZF07XG4gICAgfVxuXG4gICAgaWYgKGNtZElkeCA9PT0gMCkge1xuICAgICAgY21kLnNwbGl0KCcvJykuZm9yRWFjaCgodXJsUGFydCwgcGFydEluZGV4KSA9PiB7XG4gICAgICAgIGlmIChwYXJ0SW5kZXggPT0gMCAmJiB1cmxQYXJ0ID09PSAnLicpIHtcbiAgICAgICAgICAvLyBza2lwICcuL2EnXG4gICAgICAgIH0gZWxzZSBpZiAocGFydEluZGV4ID09IDAgJiYgdXJsUGFydCA9PT0gJycpIHsgIC8vICAnL2EnXG4gICAgICAgICAgaXNBYnNvbHV0ZSA9IHRydWU7XG4gICAgICAgIH0gZWxzZSBpZiAodXJsUGFydCA9PT0gJy4uJykgeyAgLy8gICcuLi9hJ1xuICAgICAgICAgIG51bWJlck9mRG91YmxlRG90cysrO1xuICAgICAgICB9IGVsc2UgaWYgKHVybFBhcnQgIT0gJycpIHtcbiAgICAgICAgICByZXMucHVzaCh1cmxQYXJ0KTtcbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIHJldHVybiByZXM7XG4gICAgfVxuXG4gICAgcmV0dXJuIFsuLi5yZXMsIGNtZF07XG4gIH0sIFtdKTtcblxuICByZXR1cm4gbmV3IE5hdmlnYXRpb24oaXNBYnNvbHV0ZSwgbnVtYmVyT2ZEb3VibGVEb3RzLCByZXMpO1xufVxuXG5jbGFzcyBQb3NpdGlvbiB7XG4gIGNvbnN0cnVjdG9yKFxuICAgICAgcHVibGljIHNlZ21lbnRHcm91cDogVXJsU2VnbWVudEdyb3VwLCBwdWJsaWMgcHJvY2Vzc0NoaWxkcmVuOiBib29sZWFuLCBwdWJsaWMgaW5kZXg6IG51bWJlcikge1xuICB9XG59XG5cbmZ1bmN0aW9uIGZpbmRTdGFydGluZ1Bvc2l0aW9uRm9yVGFyZ2V0R3JvdXAoXG4gICAgbmF2OiBOYXZpZ2F0aW9uLCByb290OiBVcmxTZWdtZW50R3JvdXAsIHRhcmdldDogVXJsU2VnbWVudEdyb3VwKTogUG9zaXRpb24ge1xuICBpZiAobmF2LmlzQWJzb2x1dGUpIHtcbiAgICByZXR1cm4gbmV3IFBvc2l0aW9uKHJvb3QsIHRydWUsIDApO1xuICB9XG5cbiAgaWYgKCF0YXJnZXQpIHtcbiAgICAvLyBgTmFOYCBpcyB1c2VkIG9ubHkgdG8gbWFpbnRhaW4gYmFja3dhcmRzIGNvbXBhdGliaWxpdHkgd2l0aCBpbmNvcnJlY3RseSBtb2NrZWRcbiAgICAvLyBgQWN0aXZhdGVkUm91dGVTbmFwc2hvdGAgaW4gdGVzdHMuIEluIHByaW9yIHZlcnNpb25zIG9mIHRoaXMgY29kZSwgdGhlIHBvc2l0aW9uIGhlcmUgd2FzXG4gICAgLy8gZGV0ZXJtaW5lZCBiYXNlZCBvbiBhbiBpbnRlcm5hbCBwcm9wZXJ0eSB0aGF0IHdhcyByYXJlbHkgbW9ja2VkLCByZXN1bHRpbmcgaW4gYE5hTmAuIEluXG4gICAgLy8gcmVhbGl0eSwgdGhpcyBjb2RlIHBhdGggc2hvdWxkIF9uZXZlcl8gYmUgdG91Y2hlZCBzaW5jZSBgdGFyZ2V0YCBpcyBub3QgYWxsb3dlZCB0byBiZSBmYWxzZXkuXG4gICAgcmV0dXJuIG5ldyBQb3NpdGlvbihyb290LCBmYWxzZSwgTmFOKTtcbiAgfVxuICBpZiAodGFyZ2V0LnBhcmVudCA9PT0gbnVsbCkge1xuICAgIHJldHVybiBuZXcgUG9zaXRpb24odGFyZ2V0LCB0cnVlLCAwKTtcbiAgfVxuXG4gIGNvbnN0IG1vZGlmaWVyID0gaXNNYXRyaXhQYXJhbXMobmF2LmNvbW1hbmRzWzBdKSA/IDAgOiAxO1xuICBjb25zdCBpbmRleCA9IHRhcmdldC5zZWdtZW50cy5sZW5ndGggLSAxICsgbW9kaWZpZXI7XG4gIHJldHVybiBjcmVhdGVQb3NpdGlvbkFwcGx5aW5nRG91YmxlRG90cyh0YXJnZXQsIGluZGV4LCBuYXYubnVtYmVyT2ZEb3VibGVEb3RzKTtcbn1cblxuZnVuY3Rpb24gY3JlYXRlUG9zaXRpb25BcHBseWluZ0RvdWJsZURvdHMoXG4gICAgZ3JvdXA6IFVybFNlZ21lbnRHcm91cCwgaW5kZXg6IG51bWJlciwgbnVtYmVyT2ZEb3VibGVEb3RzOiBudW1iZXIpOiBQb3NpdGlvbiB7XG4gIGxldCBnID0gZ3JvdXA7XG4gIGxldCBjaSA9IGluZGV4O1xuICBsZXQgZGQgPSBudW1iZXJPZkRvdWJsZURvdHM7XG4gIHdoaWxlIChkZCA+IGNpKSB7XG4gICAgZGQgLT0gY2k7XG4gICAgZyA9IGcucGFyZW50ITtcbiAgICBpZiAoIWcpIHtcbiAgICAgIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICAgICAgUnVudGltZUVycm9yQ29kZS5JTlZBTElEX0RPVUJMRV9ET1RTLFxuICAgICAgICAgICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpICYmICdJbnZhbGlkIG51bWJlciBvZiBcXCcuLi9cXCcnKTtcbiAgICB9XG4gICAgY2kgPSBnLnNlZ21lbnRzLmxlbmd0aDtcbiAgfVxuICByZXR1cm4gbmV3IFBvc2l0aW9uKGcsIGZhbHNlLCBjaSAtIGRkKTtcbn1cblxuZnVuY3Rpb24gZ2V0T3V0bGV0cyhjb21tYW5kczogdW5rbm93bltdKToge1trOiBzdHJpbmddOiB1bmtub3duW118c3RyaW5nfSB7XG4gIGlmIChpc0NvbW1hbmRXaXRoT3V0bGV0cyhjb21tYW5kc1swXSkpIHtcbiAgICByZXR1cm4gY29tbWFuZHNbMF0ub3V0bGV0cztcbiAgfVxuXG4gIHJldHVybiB7W1BSSU1BUllfT1VUTEVUXTogY29tbWFuZHN9O1xufVxuXG5mdW5jdGlvbiB1cGRhdGVTZWdtZW50R3JvdXAoXG4gICAgc2VnbWVudEdyb3VwOiBVcmxTZWdtZW50R3JvdXAsIHN0YXJ0SW5kZXg6IG51bWJlciwgY29tbWFuZHM6IGFueVtdKTogVXJsU2VnbWVudEdyb3VwIHtcbiAgaWYgKCFzZWdtZW50R3JvdXApIHtcbiAgICBzZWdtZW50R3JvdXAgPSBuZXcgVXJsU2VnbWVudEdyb3VwKFtdLCB7fSk7XG4gIH1cbiAgaWYgKHNlZ21lbnRHcm91cC5zZWdtZW50cy5sZW5ndGggPT09IDAgJiYgc2VnbWVudEdyb3VwLmhhc0NoaWxkcmVuKCkpIHtcbiAgICByZXR1cm4gdXBkYXRlU2VnbWVudEdyb3VwQ2hpbGRyZW4oc2VnbWVudEdyb3VwLCBzdGFydEluZGV4LCBjb21tYW5kcyk7XG4gIH1cblxuICBjb25zdCBtID0gcHJlZml4ZWRXaXRoKHNlZ21lbnRHcm91cCwgc3RhcnRJbmRleCwgY29tbWFuZHMpO1xuICBjb25zdCBzbGljZWRDb21tYW5kcyA9IGNvbW1hbmRzLnNsaWNlKG0uY29tbWFuZEluZGV4KTtcbiAgaWYgKG0ubWF0Y2ggJiYgbS5wYXRoSW5kZXggPCBzZWdtZW50R3JvdXAuc2VnbWVudHMubGVuZ3RoKSB7XG4gICAgY29uc3QgZyA9IG5ldyBVcmxTZWdtZW50R3JvdXAoc2VnbWVudEdyb3VwLnNlZ21lbnRzLnNsaWNlKDAsIG0ucGF0aEluZGV4KSwge30pO1xuICAgIGcuY2hpbGRyZW5bUFJJTUFSWV9PVVRMRVRdID1cbiAgICAgICAgbmV3IFVybFNlZ21lbnRHcm91cChzZWdtZW50R3JvdXAuc2VnbWVudHMuc2xpY2UobS5wYXRoSW5kZXgpLCBzZWdtZW50R3JvdXAuY2hpbGRyZW4pO1xuICAgIHJldHVybiB1cGRhdGVTZWdtZW50R3JvdXBDaGlsZHJlbihnLCAwLCBzbGljZWRDb21tYW5kcyk7XG4gIH0gZWxzZSBpZiAobS5tYXRjaCAmJiBzbGljZWRDb21tYW5kcy5sZW5ndGggPT09IDApIHtcbiAgICByZXR1cm4gbmV3IFVybFNlZ21lbnRHcm91cChzZWdtZW50R3JvdXAuc2VnbWVudHMsIHt9KTtcbiAgfSBlbHNlIGlmIChtLm1hdGNoICYmICFzZWdtZW50R3JvdXAuaGFzQ2hpbGRyZW4oKSkge1xuICAgIHJldHVybiBjcmVhdGVOZXdTZWdtZW50R3JvdXAoc2VnbWVudEdyb3VwLCBzdGFydEluZGV4LCBjb21tYW5kcyk7XG4gIH0gZWxzZSBpZiAobS5tYXRjaCkge1xuICAgIHJldHVybiB1cGRhdGVTZWdtZW50R3JvdXBDaGlsZHJlbihzZWdtZW50R3JvdXAsIDAsIHNsaWNlZENvbW1hbmRzKTtcbiAgfSBlbHNlIHtcbiAgICByZXR1cm4gY3JlYXRlTmV3U2VnbWVudEdyb3VwKHNlZ21lbnRHcm91cCwgc3RhcnRJbmRleCwgY29tbWFuZHMpO1xuICB9XG59XG5cbmZ1bmN0aW9uIHVwZGF0ZVNlZ21lbnRHcm91cENoaWxkcmVuKFxuICAgIHNlZ21lbnRHcm91cDogVXJsU2VnbWVudEdyb3VwLCBzdGFydEluZGV4OiBudW1iZXIsIGNvbW1hbmRzOiBhbnlbXSk6IFVybFNlZ21lbnRHcm91cCB7XG4gIGlmIChjb21tYW5kcy5sZW5ndGggPT09IDApIHtcbiAgICByZXR1cm4gbmV3IFVybFNlZ21lbnRHcm91cChzZWdtZW50R3JvdXAuc2VnbWVudHMsIHt9KTtcbiAgfSBlbHNlIHtcbiAgICBjb25zdCBvdXRsZXRzID0gZ2V0T3V0bGV0cyhjb21tYW5kcyk7XG4gICAgY29uc3QgY2hpbGRyZW46IHtba2V5OiBzdHJpbmddOiBVcmxTZWdtZW50R3JvdXB9ID0ge307XG4gICAgLy8gSWYgdGhlIHNldCBvZiBjb21tYW5kcyBkb2VzIG5vdCBhcHBseSBhbnl0aGluZyB0byB0aGUgcHJpbWFyeSBvdXRsZXQgYW5kIHRoZSBjaGlsZCBzZWdtZW50IGlzXG4gICAgLy8gYW4gZW1wdHkgcGF0aCBwcmltYXJ5IHNlZ21lbnQgb24gaXRzIG93biwgd2Ugd2FudCB0byBhcHBseSB0aGUgY29tbWFuZHMgdG8gdGhlIGVtcHR5IGNoaWxkXG4gICAgLy8gcGF0aCByYXRoZXIgdGhhbiBoZXJlLiBUaGUgb3V0Y29tZSBpcyB0aGF0IHRoZSBlbXB0eSBwcmltYXJ5IGNoaWxkIGlzIGVmZmVjdGl2ZWx5IHJlbW92ZWRcbiAgICAvLyBmcm9tIHRoZSBmaW5hbCBvdXRwdXQgVXJsVHJlZS4gSW1hZ2luZSB0aGUgZm9sbG93aW5nIGNvbmZpZzpcbiAgICAvL1xuICAgIC8vIHtwYXRoOiAnJywgY2hpbGRyZW46IFt7cGF0aDogJyoqJywgb3V0bGV0OiAncG9wdXAnfV19LlxuICAgIC8vXG4gICAgLy8gTmF2aWdhdGlvbiB0byAvKHBvcHVwOmEpIHdpbGwgYWN0aXZhdGUgdGhlIGNoaWxkIG91dGxldCBjb3JyZWN0bHkgR2l2ZW4gYSBmb2xsb3ctdXBcbiAgICAvLyBuYXZpZ2F0aW9uIHdpdGggY29tbWFuZHNcbiAgICAvLyBbJy8nLCB7b3V0bGV0czogeydwb3B1cCc6ICdiJ319XSwgd2UgX3dvdWxkIG5vdF8gd2FudCB0byBhcHBseSB0aGUgb3V0bGV0IGNvbW1hbmRzIHRvIHRoZVxuICAgIC8vIHJvb3Qgc2VnbWVudCBiZWNhdXNlIHRoYXQgd291bGQgcmVzdWx0IGluXG4gICAgLy8gLy8ocG9wdXA6YSkocG9wdXA6Yikgc2luY2UgdGhlIG91dGxldCBjb21tYW5kIGdvdCBhcHBsaWVkIG9uZSBsZXZlbCBhYm92ZSB3aGVyZSBpdCBhcHBlYXJzIGluXG4gICAgLy8gdGhlIGBBY3RpdmF0ZWRSb3V0ZWAgcmF0aGVyIHRoYW4gdXBkYXRpbmcgdGhlIGV4aXN0aW5nIG9uZS5cbiAgICAvL1xuICAgIC8vIEJlY2F1c2UgZW1wdHkgcGF0aHMgZG8gbm90IGFwcGVhciBpbiB0aGUgVVJMIHNlZ21lbnRzIGFuZCB0aGUgZmFjdCB0aGF0IHRoZSBzZWdtZW50cyB1c2VkIGluXG4gICAgLy8gdGhlIG91dHB1dCBgVXJsVHJlZWAgYXJlIHNxdWFzaGVkIHRvIGVsaW1pbmF0ZSB0aGVzZSBlbXB0eSBwYXRocyB3aGVyZSBwb3NzaWJsZVxuICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIvYmxvYi8xM2YxMGRlNDBlMjVjNjkwMGNhNTViZDgzYjM2YmQ1MzNkYWNmYTllL3BhY2thZ2VzL3JvdXRlci9zcmMvdXJsX3RyZWUudHMjTDc1NVxuICAgIC8vIGl0IGNhbiBiZSBoYXJkIHRvIGRldGVybWluZSB3aGF0IGlzIHRoZSByaWdodCB0aGluZyB0byBkbyB3aGVuIGFwcGx5aW5nIGNvbW1hbmRzIHRvIGFcbiAgICAvLyBgVXJsU2VnbWVudEdyb3VwYCB0aGF0IGlzIGNyZWF0ZWQgZnJvbSBhbiBcInVuc3F1YXNoZWRcIi9leHBhbmRlZCBgQWN0aXZhdGVkUm91dGVgIHRyZWUuXG4gICAgLy8gVGhpcyBjb2RlIGVmZmVjdGl2ZWx5IFwic3F1YXNoZXNcIiBlbXB0eSBwYXRoIHByaW1hcnkgcm91dGVzIHdoZW4gdGhleSBoYXZlIG5vIHNpYmxpbmdzIG9uXG4gICAgLy8gdGhlIHNhbWUgbGV2ZWwgb2YgdGhlIHRyZWUuXG4gICAgaWYgKCFvdXRsZXRzW1BSSU1BUllfT1VUTEVUXSAmJiBzZWdtZW50R3JvdXAuY2hpbGRyZW5bUFJJTUFSWV9PVVRMRVRdICYmXG4gICAgICAgIHNlZ21lbnRHcm91cC5udW1iZXJPZkNoaWxkcmVuID09PSAxICYmXG4gICAgICAgIHNlZ21lbnRHcm91cC5jaGlsZHJlbltQUklNQVJZX09VVExFVF0uc2VnbWVudHMubGVuZ3RoID09PSAwKSB7XG4gICAgICBjb25zdCBjaGlsZHJlbk9mRW1wdHlDaGlsZCA9XG4gICAgICAgICAgdXBkYXRlU2VnbWVudEdyb3VwQ2hpbGRyZW4oc2VnbWVudEdyb3VwLmNoaWxkcmVuW1BSSU1BUllfT1VUTEVUXSwgc3RhcnRJbmRleCwgY29tbWFuZHMpO1xuICAgICAgcmV0dXJuIG5ldyBVcmxTZWdtZW50R3JvdXAoc2VnbWVudEdyb3VwLnNlZ21lbnRzLCBjaGlsZHJlbk9mRW1wdHlDaGlsZC5jaGlsZHJlbik7XG4gICAgfVxuXG4gICAgT2JqZWN0LmVudHJpZXMob3V0bGV0cykuZm9yRWFjaCgoW291dGxldCwgY29tbWFuZHNdKSA9PiB7XG4gICAgICBpZiAodHlwZW9mIGNvbW1hbmRzID09PSAnc3RyaW5nJykge1xuICAgICAgICBjb21tYW5kcyA9IFtjb21tYW5kc107XG4gICAgICB9XG4gICAgICBpZiAoY29tbWFuZHMgIT09IG51bGwpIHtcbiAgICAgICAgY2hpbGRyZW5bb3V0bGV0XSA9IHVwZGF0ZVNlZ21lbnRHcm91cChzZWdtZW50R3JvdXAuY2hpbGRyZW5bb3V0bGV0XSwgc3RhcnRJbmRleCwgY29tbWFuZHMpO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgT2JqZWN0LmVudHJpZXMoc2VnbWVudEdyb3VwLmNoaWxkcmVuKS5mb3JFYWNoKChbY2hpbGRPdXRsZXQsIGNoaWxkXSkgPT4ge1xuICAgICAgaWYgKG91dGxldHNbY2hpbGRPdXRsZXRdID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgY2hpbGRyZW5bY2hpbGRPdXRsZXRdID0gY2hpbGQ7XG4gICAgICB9XG4gICAgfSk7XG4gICAgcmV0dXJuIG5ldyBVcmxTZWdtZW50R3JvdXAoc2VnbWVudEdyb3VwLnNlZ21lbnRzLCBjaGlsZHJlbik7XG4gIH1cbn1cblxuZnVuY3Rpb24gcHJlZml4ZWRXaXRoKHNlZ21lbnRHcm91cDogVXJsU2VnbWVudEdyb3VwLCBzdGFydEluZGV4OiBudW1iZXIsIGNvbW1hbmRzOiBhbnlbXSkge1xuICBsZXQgY3VycmVudENvbW1hbmRJbmRleCA9IDA7XG4gIGxldCBjdXJyZW50UGF0aEluZGV4ID0gc3RhcnRJbmRleDtcblxuICBjb25zdCBub01hdGNoID0ge21hdGNoOiBmYWxzZSwgcGF0aEluZGV4OiAwLCBjb21tYW5kSW5kZXg6IDB9O1xuICB3aGlsZSAoY3VycmVudFBhdGhJbmRleCA8IHNlZ21lbnRHcm91cC5zZWdtZW50cy5sZW5ndGgpIHtcbiAgICBpZiAoY3VycmVudENvbW1hbmRJbmRleCA+PSBjb21tYW5kcy5sZW5ndGgpIHJldHVybiBub01hdGNoO1xuICAgIGNvbnN0IHBhdGggPSBzZWdtZW50R3JvdXAuc2VnbWVudHNbY3VycmVudFBhdGhJbmRleF07XG4gICAgY29uc3QgY29tbWFuZCA9IGNvbW1hbmRzW2N1cnJlbnRDb21tYW5kSW5kZXhdO1xuICAgIC8vIERvIG5vdCB0cnkgdG8gY29uc3VtZSBjb21tYW5kIGFzIHBhcnQgb2YgdGhlIHByZWZpeGluZyBpZiBpdCBoYXMgb3V0bGV0cyBiZWNhdXNlIGl0IGNhblxuICAgIC8vIGNvbnRhaW4gb3V0bGV0cyBvdGhlciB0aGFuIHRoZSBvbmUgYmVpbmcgcHJvY2Vzc2VkLiBDb25zdW1pbmcgdGhlIG91dGxldHMgY29tbWFuZCB3b3VsZFxuICAgIC8vIHJlc3VsdCBpbiBvdGhlciBvdXRsZXRzIGJlaW5nIGlnbm9yZWQuXG4gICAgaWYgKGlzQ29tbWFuZFdpdGhPdXRsZXRzKGNvbW1hbmQpKSB7XG4gICAgICBicmVhaztcbiAgICB9XG4gICAgY29uc3QgY3VyciA9IGAke2NvbW1hbmR9YDtcbiAgICBjb25zdCBuZXh0ID1cbiAgICAgICAgY3VycmVudENvbW1hbmRJbmRleCA8IGNvbW1hbmRzLmxlbmd0aCAtIDEgPyBjb21tYW5kc1tjdXJyZW50Q29tbWFuZEluZGV4ICsgMV0gOiBudWxsO1xuXG4gICAgaWYgKGN1cnJlbnRQYXRoSW5kZXggPiAwICYmIGN1cnIgPT09IHVuZGVmaW5lZCkgYnJlYWs7XG5cbiAgICBpZiAoY3VyciAmJiBuZXh0ICYmICh0eXBlb2YgbmV4dCA9PT0gJ29iamVjdCcpICYmIG5leHQub3V0bGV0cyA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICBpZiAoIWNvbXBhcmUoY3VyciwgbmV4dCwgcGF0aCkpIHJldHVybiBub01hdGNoO1xuICAgICAgY3VycmVudENvbW1hbmRJbmRleCArPSAyO1xuICAgIH0gZWxzZSB7XG4gICAgICBpZiAoIWNvbXBhcmUoY3Vyciwge30sIHBhdGgpKSByZXR1cm4gbm9NYXRjaDtcbiAgICAgIGN1cnJlbnRDb21tYW5kSW5kZXgrKztcbiAgICB9XG4gICAgY3VycmVudFBhdGhJbmRleCsrO1xuICB9XG5cbiAgcmV0dXJuIHttYXRjaDogdHJ1ZSwgcGF0aEluZGV4OiBjdXJyZW50UGF0aEluZGV4LCBjb21tYW5kSW5kZXg6IGN1cnJlbnRDb21tYW5kSW5kZXh9O1xufVxuXG5mdW5jdGlvbiBjcmVhdGVOZXdTZWdtZW50R3JvdXAoXG4gICAgc2VnbWVudEdyb3VwOiBVcmxTZWdtZW50R3JvdXAsIHN0YXJ0SW5kZXg6IG51bWJlciwgY29tbWFuZHM6IGFueVtdKTogVXJsU2VnbWVudEdyb3VwIHtcbiAgY29uc3QgcGF0aHMgPSBzZWdtZW50R3JvdXAuc2VnbWVudHMuc2xpY2UoMCwgc3RhcnRJbmRleCk7XG5cbiAgbGV0IGkgPSAwO1xuICB3aGlsZSAoaSA8IGNvbW1hbmRzLmxlbmd0aCkge1xuICAgIGNvbnN0IGNvbW1hbmQgPSBjb21tYW5kc1tpXTtcbiAgICBpZiAoaXNDb21tYW5kV2l0aE91dGxldHMoY29tbWFuZCkpIHtcbiAgICAgIGNvbnN0IGNoaWxkcmVuID0gY3JlYXRlTmV3U2VnbWVudENoaWxkcmVuKGNvbW1hbmQub3V0bGV0cyk7XG4gICAgICByZXR1cm4gbmV3IFVybFNlZ21lbnRHcm91cChwYXRocywgY2hpbGRyZW4pO1xuICAgIH1cblxuICAgIC8vIGlmIHdlIHN0YXJ0IHdpdGggYW4gb2JqZWN0IGxpdGVyYWwsIHdlIG5lZWQgdG8gcmV1c2UgdGhlIHBhdGggcGFydCBmcm9tIHRoZSBzZWdtZW50XG4gICAgaWYgKGkgPT09IDAgJiYgaXNNYXRyaXhQYXJhbXMoY29tbWFuZHNbMF0pKSB7XG4gICAgICBjb25zdCBwID0gc2VnbWVudEdyb3VwLnNlZ21lbnRzW3N0YXJ0SW5kZXhdO1xuICAgICAgcGF0aHMucHVzaChuZXcgVXJsU2VnbWVudChwLnBhdGgsIHN0cmluZ2lmeShjb21tYW5kc1swXSkpKTtcbiAgICAgIGkrKztcbiAgICAgIGNvbnRpbnVlO1xuICAgIH1cblxuICAgIGNvbnN0IGN1cnIgPSBpc0NvbW1hbmRXaXRoT3V0bGV0cyhjb21tYW5kKSA/IGNvbW1hbmQub3V0bGV0c1tQUklNQVJZX09VVExFVF0gOiBgJHtjb21tYW5kfWA7XG4gICAgY29uc3QgbmV4dCA9IChpIDwgY29tbWFuZHMubGVuZ3RoIC0gMSkgPyBjb21tYW5kc1tpICsgMV0gOiBudWxsO1xuICAgIGlmIChjdXJyICYmIG5leHQgJiYgaXNNYXRyaXhQYXJhbXMobmV4dCkpIHtcbiAgICAgIHBhdGhzLnB1c2gobmV3IFVybFNlZ21lbnQoY3Vyciwgc3RyaW5naWZ5KG5leHQpKSk7XG4gICAgICBpICs9IDI7XG4gICAgfSBlbHNlIHtcbiAgICAgIHBhdGhzLnB1c2gobmV3IFVybFNlZ21lbnQoY3Vyciwge30pKTtcbiAgICAgIGkrKztcbiAgICB9XG4gIH1cbiAgcmV0dXJuIG5ldyBVcmxTZWdtZW50R3JvdXAocGF0aHMsIHt9KTtcbn1cblxuZnVuY3Rpb24gY3JlYXRlTmV3U2VnbWVudENoaWxkcmVuKG91dGxldHM6IHtbbmFtZTogc3RyaW5nXTogdW5rbm93bltdfHN0cmluZ30pOlxuICAgIHtbb3V0bGV0OiBzdHJpbmddOiBVcmxTZWdtZW50R3JvdXB9IHtcbiAgY29uc3QgY2hpbGRyZW46IHtbb3V0bGV0OiBzdHJpbmddOiBVcmxTZWdtZW50R3JvdXB9ID0ge307XG4gIE9iamVjdC5lbnRyaWVzKG91dGxldHMpLmZvckVhY2goKFtvdXRsZXQsIGNvbW1hbmRzXSkgPT4ge1xuICAgIGlmICh0eXBlb2YgY29tbWFuZHMgPT09ICdzdHJpbmcnKSB7XG4gICAgICBjb21tYW5kcyA9IFtjb21tYW5kc107XG4gICAgfVxuICAgIGlmIChjb21tYW5kcyAhPT0gbnVsbCkge1xuICAgICAgY2hpbGRyZW5bb3V0bGV0XSA9IGNyZWF0ZU5ld1NlZ21lbnRHcm91cChuZXcgVXJsU2VnbWVudEdyb3VwKFtdLCB7fSksIDAsIGNvbW1hbmRzKTtcbiAgICB9XG4gIH0pO1xuICByZXR1cm4gY2hpbGRyZW47XG59XG5cbmZ1bmN0aW9uIHN0cmluZ2lmeShwYXJhbXM6IHtba2V5OiBzdHJpbmddOiBhbnl9KToge1trZXk6IHN0cmluZ106IHN0cmluZ30ge1xuICBjb25zdCByZXM6IHtba2V5OiBzdHJpbmddOiBzdHJpbmd9ID0ge307XG4gIE9iamVjdC5lbnRyaWVzKHBhcmFtcykuZm9yRWFjaCgoW2ssIHZdKSA9PiByZXNba10gPSBgJHt2fWApO1xuICByZXR1cm4gcmVzO1xufVxuXG5mdW5jdGlvbiBjb21wYXJlKHBhdGg6IHN0cmluZywgcGFyYW1zOiB7W2tleTogc3RyaW5nXTogYW55fSwgc2VnbWVudDogVXJsU2VnbWVudCk6IGJvb2xlYW4ge1xuICByZXR1cm4gcGF0aCA9PSBzZWdtZW50LnBhdGggJiYgc2hhbGxvd0VxdWFsKHBhcmFtcywgc2VnbWVudC5wYXJhbWV0ZXJzKTtcbn1cbiJdfQ==