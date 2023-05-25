import type { SpinnerConfigs } from './spinner-interface';
declare const spinners: {
  bubbles: {
    dur: number;
    circles: number;
    fn: (dur: number, index: number, total: number) => {
      r: number;
      style: {
        top: string;
        left: string;
        'animation-delay': string;
      };
    };
  };
  circles: {
    dur: number;
    circles: number;
    fn: (dur: number, index: number, total: number) => {
      r: number;
      style: {
        top: string;
        left: string;
        'animation-delay': string;
      };
    };
  };
  circular: {
    dur: number;
    elmDuration: boolean;
    circles: number;
    fn: () => {
      r: number;
      cx: number;
      cy: number;
      fill: string;
      viewBox: string;
      transform: string;
      style: {};
    };
  };
  crescent: {
    dur: number;
    circles: number;
    fn: () => {
      r: number;
      style: {};
    };
  };
  dots: {
    dur: number;
    circles: number;
    fn: (_: number, index: number) => {
      r: number;
      style: {
        left: string;
        'animation-delay': string;
      };
    };
  };
  lines: {
    dur: number;
    lines: number;
    fn: (dur: number, index: number, total: number) => {
      y1: number;
      y2: number;
      style: {
        transform: string;
        'animation-delay': string;
      };
    };
  };
  'lines-small': {
    dur: number;
    lines: number;
    fn: (dur: number, index: number, total: number) => {
      y1: number;
      y2: number;
      style: {
        transform: string;
        'animation-delay': string;
      };
    };
  };
  'lines-sharp': {
    dur: number;
    lines: number;
    fn: (dur: number, index: number, total: number) => {
      y1: number;
      y2: number;
      style: {
        transform: string;
        'animation-delay': string;
      };
    };
  };
  'lines-sharp-small': {
    dur: number;
    lines: number;
    fn: (dur: number, index: number, total: number) => {
      y1: number;
      y2: number;
      style: {
        transform: string;
        'animation-delay': string;
      };
    };
  };
};
export declare const SPINNERS: SpinnerConfigs;
export type SpinnerTypes = keyof typeof spinners;
export {};
