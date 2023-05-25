import type { ParsedRoute, RouteChain, RouterDirection } from './interface';
/** Join the non empty segments with "/". */
export declare const generatePath: (segments: string[]) => string;
export declare const writeSegments: (history: History, root: string, useHash: boolean, segments: string[], direction: RouterDirection, state: number, queryString?: string) => void;
/**
 * Transforms a chain to a list of segments.
 *
 * Notes:
 * - parameter segments of the form :param are replaced with their value,
 * - null is returned when a value is missing for any parameter segment.
 */
export declare const chainToSegments: (chain: RouteChain) => string[] | null;
export declare const readSegments: (loc: Location, root: string, useHash: boolean) => string[] | null;
/**
 * Parses the path to:
 * - segments an array of '/' separated parts,
 * - queryString (undefined when no query string).
 */
export declare const parsePath: (path: string | undefined | null) => ParsedRoute;
