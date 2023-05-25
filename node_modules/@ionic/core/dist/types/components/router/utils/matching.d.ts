import type { RouteChain, RouteID, RouteRedirect } from './interface';
/**
 * Returns whether the given redirect matches the given path segments.
 *
 * A redirect matches when the segments of the path and redirect.from are equal.
 * Note that segments are only checked until redirect.from contains a '*' which matches any path segment.
 * The path ['some', 'path', 'to', 'page'] matches both ['some', 'path', 'to', 'page'] and ['some', 'path', '*'].
 */
export declare const matchesRedirect: (segments: string[], redirect: RouteRedirect) => boolean;
/** Returns the first redirect matching the path segments or undefined when no match found. */
export declare const findRouteRedirect: (segments: string[], redirects: RouteRedirect[]) => RouteRedirect | undefined;
export declare const matchesIDs: (ids: Pick<RouteID, 'id' | 'params'>[], chain: RouteChain) => number;
/**
 * Matches the segments against the chain.
 *
 * Returns:
 * - null when there is no match,
 * - a chain with the params properties updated with the parameter segments on match.
 */
export declare const matchesSegments: (segments: string[], chain: RouteChain) => RouteChain | null;
/**
 * Merges the route parameter objects.
 * Returns undefined when both parameters are undefined.
 */
export declare const mergeParams: (a: {
  [key: string]: any;
} | undefined, b: {
  [key: string]: any;
} | undefined) => {
  [key: string]: any;
} | undefined;
/**
 * Finds the best match for the ids in the chains.
 *
 * Returns the best match or null when no match is found.
 * When a chain is returned the parameters are updated from the RouteIDs.
 * That is they contain both the componentProps of the <ion-route> and the parameter segment.
 */
export declare const findChainForIDs: (ids: RouteID[], chains: RouteChain[]) => RouteChain | null;
/**
 * Finds the best match for the segments in the chains.
 *
 * Returns the best match or null when no match is found.
 * When a chain is returned the parameters are updated from the segments.
 * That is they contain both the componentProps of the <ion-route> and the parameter segments.
 */
export declare const findChainForSegments: (segments: string[], chains: RouteChain[]) => RouteChain | null;
/**
 * Computes the priority of a chain.
 *
 * Parameter segments are given a lower priority over fixed segments.
 *
 * Considering the following 2 chains matching the path /path/to/page:
 * - /path/to/:where
 * - /path/to/page
 *
 * The second one will be given a higher priority because "page" is a fixed segment (vs ":where", a parameter segment).
 */
export declare const computePriority: (chain: RouteChain) => number;
export declare class RouterSegments {
  private segments;
  constructor(segments: string[]);
  next(): string;
}
