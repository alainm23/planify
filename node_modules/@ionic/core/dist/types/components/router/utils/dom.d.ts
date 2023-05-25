import type { AnimationBuilder } from '../../../interface';
import type { NavOutletElement, RouteChain, RouteID, RouterDirection } from './interface';
/**
 * Activates the passed route chain.
 *
 * There must be exactly one outlet per route entry in the chain.
 *
 * The methods calls setRouteId on each of the outlet with the corresponding route entry in the chain.
 * setRouteId will create or select the view in the outlet.
 */
export declare const writeNavState: (root: HTMLElement | undefined, chain: RouteChain, direction: RouterDirection, index: number, changed?: boolean, animation?: AnimationBuilder) => Promise<boolean>;
/**
 * Recursively walks the outlet in the DOM.
 *
 * The function returns a list of RouteID corresponding to each of the outlet and the last outlet without a RouteID.
 */
export declare const readNavState: (root: HTMLElement | undefined) => Promise<{
  ids: RouteID[];
  outlet: NavOutletElement | undefined;
}>;
export declare const waitUntilNavNode: () => Promise<void>;
