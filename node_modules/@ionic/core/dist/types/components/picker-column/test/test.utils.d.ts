import type { E2EPage, ScreenshotFn } from "../../../utils/test/playwright/index";
/**
 * Visual regression tests for picker-column.
 * @param page - The page to run the tests on.
 * @param screenshot - The screenshot function to generate unique screenshot names
 * @param buttonSelector - The selector for the button that opens the picker.
 * @param description - The description to amend to the screenshot names (typically 'single' or 'multiple').
 */
export declare function testPickerColumn(page: E2EPage, screenshot: ScreenshotFn, buttonSelector: string, description: string): Promise<void>;
