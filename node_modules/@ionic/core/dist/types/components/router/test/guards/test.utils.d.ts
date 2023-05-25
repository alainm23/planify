import type { Page } from '@playwright/test';
/**
 * Selects a radio button from the radio group for configuring the
 * beforeEnter hook of the router.
 */
export declare const setBeforeEnterHook: (page: Page, type: string) => Promise<void>;
/**
 * Selects a radio button from the radio group for configuring the
 * beforeLeave hook of the router.
 */
export declare const setBeforeLeaveHook: (page: Page, type: string) => Promise<void>;
