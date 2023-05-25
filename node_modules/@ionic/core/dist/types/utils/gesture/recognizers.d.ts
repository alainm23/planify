export interface PanRecognizer {
  start(x: number, y: number): void;
  detect(x: number, y: number): boolean;
  isGesture(): boolean;
  getDirection(): number;
}
export declare const createPanRecognizer: (direction: string, thresh: number, maxAngle: number) => PanRecognizer;
