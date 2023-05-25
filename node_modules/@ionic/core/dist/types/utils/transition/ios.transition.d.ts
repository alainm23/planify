import type { Animation } from '../../interface';
import type { TransitionOptions } from '../transition';
export declare const shadow: <T extends Element>(el: T) => ShadowRoot | T;
export declare const iosTransitionAnimation: (navEl: HTMLElement, opts: TransitionOptions) => Animation;
