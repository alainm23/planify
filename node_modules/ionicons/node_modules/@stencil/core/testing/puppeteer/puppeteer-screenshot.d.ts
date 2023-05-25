import type { E2EProcessEnv, ScreenshotDiff, ScreenshotOptions } from '@stencil/core/internal';
import type * as pd from './puppeteer-declarations';
export declare function initPageScreenshot(page: pd.E2EPageInternal): void;
export declare function pageCompareScreenshot(page: pd.E2EPageInternal, env: E2EProcessEnv, desc: string, testPath: string, opts: ScreenshotOptions): Promise<ScreenshotDiff>;
