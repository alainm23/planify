import { InjectionToken } from '@angular/core';
import { IonicConfig } from '@ionic/core';
import * as i0 from "@angular/core";
export declare class Config {
    get(key: keyof IonicConfig, fallback?: any): any;
    getBoolean(key: keyof IonicConfig, fallback?: boolean): boolean;
    getNumber(key: keyof IonicConfig, fallback?: number): number;
    static ɵfac: i0.ɵɵFactoryDeclaration<Config, never>;
    static ɵprov: i0.ɵɵInjectableDeclaration<Config>;
}
export declare const ConfigToken: InjectionToken<any>;
