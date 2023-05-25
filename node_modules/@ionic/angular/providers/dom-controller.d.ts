import * as i0 from "@angular/core";
export declare class DomController {
    /**
     * Schedules a task to run during the READ phase of the next frame.
     * This task should only read the DOM, but never modify it.
     */
    read(cb: RafCallback): void;
    /**
     * Schedules a task to run during the WRITE phase of the next frame.
     * This task should write the DOM, but never READ it.
     */
    write(cb: RafCallback): void;
    static ɵfac: i0.ɵɵFactoryDeclaration<DomController, never>;
    static ɵprov: i0.ɵɵInjectableDeclaration<DomController>;
}
export declare type RafCallback = (timeStamp?: number) => void;
