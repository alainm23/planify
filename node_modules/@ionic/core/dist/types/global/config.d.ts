import type { IonicConfig } from '../interface';
export declare class Config {
  private m;
  reset(configObj: IonicConfig): void;
  get(key: keyof IonicConfig, fallback?: any): any;
  getBoolean(key: keyof IonicConfig, fallback?: boolean): boolean;
  getNumber(key: keyof IonicConfig, fallback?: number): number;
  set(key: keyof IonicConfig, value: any): void;
}
export declare const config: Config;
export declare const configFromSession: (win: Window) => any;
export declare const saveConfig: (win: Window, c: any) => void;
export declare const configFromURL: (win: Window) => any;
