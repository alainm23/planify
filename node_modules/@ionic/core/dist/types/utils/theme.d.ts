import type { RouterDirection } from '../components/router/utils/interface';
import type { AnimationBuilder, Color, CssClassMap } from '../interface';
export declare const hostContext: (selector: string, el: HTMLElement) => boolean;
/**
 * Create the mode and color classes for the component based on the classes passed in
 */
export declare const createColorClasses: (color: Color | undefined | null, cssClassMap: CssClassMap) => CssClassMap;
export declare const getClassList: (classes: string | (string | null | undefined)[] | undefined) => string[];
export declare const getClassMap: (classes: string | string[] | undefined) => CssClassMap;
export declare const openURL: (url: string | undefined | null, ev: Event | undefined | null, direction: RouterDirection, animation?: AnimationBuilder) => Promise<boolean>;
