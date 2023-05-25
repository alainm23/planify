/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { parsePath } from './path';
const readProp = (el, prop) => {
  if (prop in el) {
    return el[prop];
  }
  if (el.hasAttribute(prop)) {
    return el.getAttribute(prop);
  }
  return null;
};
/**
 * Extracts the redirects (that is <ion-route-redirect> elements inside the root).
 *
 * The redirects are returned as a list of RouteRedirect.
 */
export const readRedirects = (root) => {
  return Array.from(root.children)
    .filter((el) => el.tagName === 'ION-ROUTE-REDIRECT')
    .map((el) => {
    const to = readProp(el, 'to');
    return {
      from: parsePath(readProp(el, 'from')).segments,
      to: to == null ? undefined : parsePath(to),
    };
  });
};
/**
 * Extracts all the routes (that is <ion-route> elements inside the root).
 *
 * The routes are returned as a list of chains - the flattened tree.
 */
export const readRoutes = (root) => {
  return flattenRouterTree(readRouteNodes(root));
};
/**
 * Reads the route nodes as a tree modeled after the DOM tree of <ion-route> elements.
 *
 * Note: routes without a component are ignored together with their children.
 */
export const readRouteNodes = (node) => {
  return Array.from(node.children)
    .filter((el) => el.tagName === 'ION-ROUTE' && el.component)
    .map((el) => {
    const component = readProp(el, 'component');
    return {
      segments: parsePath(readProp(el, 'url')).segments,
      id: component.toLowerCase(),
      params: el.componentProps,
      beforeLeave: el.beforeLeave,
      beforeEnter: el.beforeEnter,
      children: readRouteNodes(el),
    };
  });
};
/**
 * Flattens a RouterTree in a list of chains.
 *
 * Each chain represents a path from the root node to a terminal node.
 */
export const flattenRouterTree = (nodes) => {
  const chains = [];
  for (const node of nodes) {
    flattenNode([], chains, node);
  }
  return chains;
};
/** Flattens a route node recursively and push each branch to the chains list. */
const flattenNode = (chain, chains, node) => {
  chain = [
    ...chain,
    {
      id: node.id,
      segments: node.segments,
      params: node.params,
      beforeLeave: node.beforeLeave,
      beforeEnter: node.beforeEnter,
    },
  ];
  if (node.children.length === 0) {
    chains.push(chain);
    return;
  }
  for (const child of node.children) {
    flattenNode(chain, chains, child);
  }
};
