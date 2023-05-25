import type { Gesture } from './index';
export declare const createSwipeBackGesture: (el: HTMLElement, canStartHandler: () => boolean, onStartHandler: () => void, onMoveHandler: (step: number) => void, onEndHandler: (shouldComplete: boolean, step: number, dur: number) => void) => Gesture;
