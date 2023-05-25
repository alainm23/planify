import { NgZone } from '@angular/core';
import { Gesture, GestureConfig } from '@ionic/core';
import * as i0 from "@angular/core";
export declare class GestureController {
    private zone;
    constructor(zone: NgZone);
    /**
     * Create a new gesture
     */
    create(opts: GestureConfig, runInsideAngularZone?: boolean): Gesture;
    static ɵfac: i0.ɵɵFactoryDeclaration<GestureController, never>;
    static ɵprov: i0.ɵɵInjectableDeclaration<GestureController>;
}
