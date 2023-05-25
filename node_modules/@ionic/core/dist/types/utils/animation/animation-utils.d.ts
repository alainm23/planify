import type { AnimationKeyFrames } from './animation-interface';
/**
 * Web Animations requires hyphenated CSS properties
 * to be written in camelCase when animating
 */
export declare const processKeyframes: (keyframes: AnimationKeyFrames) => AnimationKeyFrames;
export declare const getAnimationPrefix: (el: HTMLElement) => string;
export declare const setStyleProperty: (element: HTMLElement, propertyName: string, value: string | null) => void;
export declare const removeStyleProperty: (element: HTMLElement, propertyName: string) => void;
export declare const animationEnd: (el: HTMLElement | null, callback: (ev?: TransitionEvent) => void) => () => void;
export declare const generateKeyframeRules: (keyframes?: any[]) => string;
export declare const generateKeyframeName: (keyframeRules: string) => string;
export declare const getStyleContainer: (element: HTMLElement) => any;
export declare const createKeyframeStylesheet: (keyframeName: string, keyframeRules: string, element: HTMLElement) => HTMLElement;
export declare const addClassToArray: (classes: string[] | undefined, className: string | string[] | undefined) => string[];
