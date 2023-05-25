import { GESTURE_CONTROLLER } from './gesture-controller';
export declare const createGesture: (config: GestureConfig) => Gesture;
export interface GestureDetail {
  type: string;
  startX: number;
  startY: number;
  startTime: number;
  currentX: number;
  currentY: number;
  velocityX: number;
  velocityY: number;
  deltaX: number;
  deltaY: number;
  currentTime: number;
  event: UIEvent;
  data?: any;
}
export type GestureCallback = (detail: GestureDetail) => boolean | void;
export interface Gesture {
  enable(enable?: boolean): void;
  destroy(): void;
}
export interface GestureConfig {
  [index: string]: any;
  el: Node;
  disableScroll?: boolean;
  direction?: 'x' | 'y';
  gestureName: string;
  gesturePriority?: number;
  passive?: boolean;
  maxAngle?: number;
  threshold?: number;
  blurOnStart?: boolean;
  canStart?: GestureCallback;
  onWillStart?: (_: GestureDetail) => Promise<void>;
  onStart?: GestureCallback;
  onMove?: GestureCallback;
  onEnd?: GestureCallback;
  notCaptured?: GestureCallback;
}
export { GESTURE_CONTROLLER };
