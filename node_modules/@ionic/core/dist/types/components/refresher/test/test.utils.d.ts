import type { E2EPage } from "../../../utils/test/playwright/index";
/**
 * Emulates a pull-to-refresh drag gesture (pulls down and releases).
 *
 * You will need to manually dispatch an event called `ionRefreshComplete`
 * in your `complete()` handler for the refresh event. Otherwise the `waitForEvent`
 * will complete when the timeout completes (5000ms).
 *
 * @param page The E2E Page object.
 * @param selector The element selector to center the drag gesture on. Defaults to `body`.
 */
declare const pullToRefresh: (page: E2EPage, selector?: string) => Promise<void>;
export { pullToRefresh };
