import type { RouteChain, RouteRedirect, RouteTree } from './interface';
/**
 * Extracts the redirects (that is <ion-route-redirect> elements inside the root).
 *
 * The redirects are returned as a list of RouteRedirect.
 */
export declare const readRedirects: (root: Element) => RouteRedirect[];
/**
 * Extracts all the routes (that is <ion-route> elements inside the root).
 *
 * The routes are returned as a list of chains - the flattened tree.
 */
export declare const readRoutes: (root: Element) => RouteChain[];
/**
 * Reads the route nodes as a tree modeled after the DOM tree of <ion-route> elements.
 *
 * Note: routes without a component are ignored together with their children.
 */
export declare const readRouteNodes: (node: Element) => RouteTree;
/**
 * Flattens a RouterTree in a list of chains.
 *
 * Each chain represents a path from the root node to a terminal node.
 */
export declare const flattenRouterTree: (nodes: RouteTree) => RouteChain[];
