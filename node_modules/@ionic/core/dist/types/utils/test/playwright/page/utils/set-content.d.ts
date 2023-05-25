import type { Page, TestInfo } from '@playwright/test';
import type { E2EPageOptions } from "../../index";
/**
 * Overwrites the default Playwright page.setContent method.
 *
 * Navigates to a blank page, sets the content, and waits for the
 * Stencil components to be hydrated before proceeding with the test.
 *
 * @param page The Playwright page object.
 * @param html The HTML content to set on the page.
 * @param testInfo The TestInfo associated with the current test run. (DEPRECATED)
 * @param options The test config associated with the current test run.
 */
export declare const setContent: (page: Page, html: string, testInfo: TestInfo, options?: E2EPageOptions) => Promise<void>;
