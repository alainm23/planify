import { ActivatedRouteSnapshot, DetachedRouteHandle, RouteReuseStrategy } from '@angular/router';
export declare class IonicRouteStrategy implements RouteReuseStrategy {
    shouldDetach(_route: ActivatedRouteSnapshot): boolean;
    shouldAttach(_route: ActivatedRouteSnapshot): boolean;
    store(_route: ActivatedRouteSnapshot, _detachedTree: DetachedRouteHandle): void;
    retrieve(_route: ActivatedRouteSnapshot): DetachedRouteHandle | null;
    shouldReuseRoute(future: ActivatedRouteSnapshot, curr: ActivatedRouteSnapshot): boolean;
}
