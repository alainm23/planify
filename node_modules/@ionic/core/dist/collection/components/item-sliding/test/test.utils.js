/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { expect } from '@playwright/test';
export const testSlidingItem = async (page, item, screenshotNameSuffix, openStart = false) => {
  // passing a param into the eval callback is tricky due to execution context
  // so just do the check outside the callback instead to make things easy
  if (openStart) {
    await item.evaluate(async (el) => {
      await el.open('start');
    });
  }
  else {
    await item.evaluate(async (el) => {
      await el.open('end');
    });
  }
  // opening animation takes longer than waitForChanges accounts for
  await page.waitForTimeout(500);
  await expect(item).toHaveScreenshot(`item-sliding-${screenshotNameSuffix}-${page.getSnapshotSettings()}.png`);
  await item.evaluate(async (el) => {
    await el.close();
  });
};
