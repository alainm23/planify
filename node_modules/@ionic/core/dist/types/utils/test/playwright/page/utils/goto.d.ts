import type { Page, TestInfo } from '@playwright/test';
import type { E2EPageOptions } from "../../index";
/**
 * This is an extended version of Playwright's
 * page.goto method. In addition to performing
 * the normal page.goto work, this code also
 * automatically waits for the Stencil components
 * to be hydrated before proceeding with the test.
 */
export declare const goto: (page: Page, url: string, testInfo: TestInfo, originalFn: (url: string, options?: {
  referer?: string | undefined;
  timeout?: number | undefined;
  waitUntil?: "load" | "domcontentloaded" | "networkidle" | "commit" | undefined;
} | undefined) => Promise<import("playwright-core").Response | null>, options?: E2EPageOptions) => Promise<import("playwright-core").Response | null>;
