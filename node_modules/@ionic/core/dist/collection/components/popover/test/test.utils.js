/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { expect } from '@playwright/test';
export const openPopover = async (page, buttonID, useEvalClick = false) => {
  const ionPopoverDidPresent = await page.spyOnEvent('ionPopoverDidPresent');
  const trigger = page.locator(`#${buttonID}`);
  await trigger.evaluate((el) => el.scrollIntoView({ block: 'center' }));
  /**
   * Some tests aim to have many popovers open at once. When clicking a locator, Playwright
   * will simply click on that coordinate, which may instead trigger the backdrop for the
   * previous popover. Rather than set backdropDismiss=false on all popovers, we can call
   * the click method on the button directly to avoid this behavior.
   */
  if (useEvalClick) {
    await trigger.evaluate((el) => el.click());
  }
  else {
    await trigger.click();
  }
  await ionPopoverDidPresent.next();
};
export const closePopover = async (page, popover) => {
  const ionPopoverDidDismiss = await page.spyOnEvent('ionPopoverDidDismiss');
  popover = popover || page.locator('ion-popover');
  await popover.evaluate((el) => el.dismiss());
  await ionPopoverDidDismiss.next();
};
export const screenshotPopover = async (page, buttonID, testName) => {
  await page.goto(`src/components/popover/test/${testName}`);
  await page.setIonViewport();
  await openPopover(page, buttonID);
  await expect(page).toHaveScreenshot(`popover-${testName}-${buttonID}-${page.getSnapshotSettings()}.png`);
};
