/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
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
export const setIonViewport = async (page, options) => {
  var _a, _b;
  const currentViewport = page.viewportSize();
  const ionContent = await page.$('ion-content');
  if (ionContent) {
    await ionContent.waitForElementState('stable');
  }
  const [x, y] = await page.evaluate(async () => {
    const content = document.querySelector('ion-content');
    if (content) {
      const innerScroll = content.shadowRoot.querySelector('.inner-scroll');
      return [innerScroll.scrollWidth - content.clientWidth, innerScroll.scrollHeight - content.clientHeight];
    }
    return [0, 0];
  });
  const width = ((_a = currentViewport === null || currentViewport === void 0 ? void 0 : currentViewport.width) !== null && _a !== void 0 ? _a : 640) + ((options === null || options === void 0 ? void 0 : options.resizeViewportWidth) ? x : 0);
  const height = ((_b = currentViewport === null || currentViewport === void 0 ? void 0 : currentViewport.height) !== null && _b !== void 0 ? _b : 480) + y;
  await page.setViewportSize({
    width,
    height,
  });
};
