/// <reference types="node" />
import type * as d from '@stencil/core/internal';
export declare function compareScreenshot(emulateConfig: d.EmulateConfig, screenshotBuildData: d.ScreenshotBuildData, currentScreenshotBuf: Buffer, desc: string, width: number, height: number, testPath: string, pixelmatchThreshold: number): Promise<d.ScreenshotDiff>;
