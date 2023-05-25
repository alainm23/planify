import type { Page } from '@playwright/test';
import type { SetIonViewportOptions } from '../../playwright-declarations';
/**
 * Taking fullpage screenshots in Playwright
 * does not work with ion-content by default.
 * The reason is that full page screenshots do not
 * expand any scrollable container on the page. Instead,
 * they render the full scrollable content of the document itself.
 * To work around this, we increase the size of the document
 * so the full scrollable content inside of ion-content
 * can be captured in a screenshot.
 *
 */
export declare const setIonViewport: (page: Page, options?: SetIonViewportOptions) => Promise<void>;
