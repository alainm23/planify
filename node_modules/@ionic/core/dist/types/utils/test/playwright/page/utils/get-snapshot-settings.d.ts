import type { Page, TestInfo } from '@playwright/test';
/**
 * This provides metadata that can be used to
 * create a unique screenshot URL.
 * For example, we need to be able to differentiate
 * between iOS in LTR mode and iOS in RTL mode.
 */
export declare const getSnapshotSettings: (page: Page, testInfo: TestInfo) => string;
