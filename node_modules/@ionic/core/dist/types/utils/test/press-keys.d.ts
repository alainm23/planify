import type { Browser, BrowserContext, Page } from '@playwright/test';
/**
 * Source: https://github.com/WordPress/gutenberg/blob/f0d0d569a06c42833670c9b5285d04a63968a220/packages/e2e-test-utils-playwright/src/page-utils/press-keys.ts
 * Slimmed down version of WordPress' pressKeys utility.
 */
export declare class PageUtils {
  browser: Browser;
  page: Page;
  context: BrowserContext;
  constructor({ page }: {
    page: Page;
  });
  pressKeys: typeof pressKeys;
}
type Options = {
  /**
   * Number of times to press the key.
   */
  times?: number;
  /**
   * Delay between each key press in milliseconds.
   */
  delay?: number;
};
/**
 * Presses a key combination.
 * @param key - Key combination to press.
 * @param options - Options for the key press.
 * @example
 * ```ts
 * await pressKeys('a');
 * await pressKeys('a', { times: 2 });
 * await pressKeys('a', { delay: 100 });
 * await pressKeys('Shift+Tab');
 * ```
 */
export declare function pressKeys(this: PageUtils, key: string, { times, ...pressOptions }?: Options): Promise<void>;
export {};
