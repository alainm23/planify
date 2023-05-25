export type Mode = 'ios' | 'md';
export type Direction = 'ltr' | 'rtl';
export type TitleFn = (title: string) => string;
export type ScreenshotFn = (fileName: string) => string;
export interface TestConfig {
  mode: Mode;
  direction: Direction;
}
interface TestUtilities {
  title: TitleFn;
  screenshot: ScreenshotFn;
  config: TestConfig;
}
interface TestConfigOption {
  modes?: Mode[];
  directions?: Direction[];
}
/**
 * Given a config generate an array of test variants.
 */
export declare const configs: (testConfig?: TestConfigOption) => TestUtilities[];
export {};
