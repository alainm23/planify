import type { Page } from '@playwright/test';
/**
 * Waits for a combined threshold of a Stencil web component to be re-hydrated in the next repaint + 100ms.
 * Used for testing changes to a web component that does not modify CSS classes or introduce new DOM nodes.
 *
 * Original source: https://github.com/ionic-team/stencil/blob/main/src/testing/puppeteer/puppeteer-page.ts#L298-L363
 */
export declare const waitForChanges: (page: Page, timeoutMs?: number) => Promise<void>;
