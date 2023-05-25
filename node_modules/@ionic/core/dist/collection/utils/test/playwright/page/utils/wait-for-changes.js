/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
/**
 * Waits for a combined threshold of a Stencil web component to be re-hydrated in the next repaint + 100ms.
 * Used for testing changes to a web component that does not modify CSS classes or introduce new DOM nodes.
 *
 * Original source: https://github.com/ionic-team/stencil/blob/main/src/testing/puppeteer/puppeteer-page.ts#L298-L363
 */
export const waitForChanges = async (page, timeoutMs = 100) => {
  try {
    if (page.isClosed()) {
      /**
       * If the page is already closed, we can skip the long execution of this method
       * and return early.
       */
      return;
    }
    await page.evaluate(() => {
      // BROWSER CONTEXT
      return new Promise((resolve) => {
        // Wait for the next repaint to happen
        requestAnimationFrame(() => {
          const promiseChain = [];
          const waitComponentOnReady = (elm, promises) => {
            if ('shadowRoot' in elm && elm.shadowRoot instanceof ShadowRoot) {
              waitComponentOnReady(elm.shadowRoot, promises);
            }
            const children = elm.children;
            const len = children.length;
            for (let i = 0; i < len; i++) {
              const childElm = children[i];
              const childStencilElm = childElm;
              if (childElm.tagName.includes('-') && typeof childStencilElm.componentOnReady === 'function') {
                /**
                 * We are only using the lazy loaded bundle
                 * here so we can safely use the
                 * componentOnReady method.
                 */
                // eslint-disable-next-line custom-rules/no-component-on-ready-method
                promises.push(childStencilElm.componentOnReady());
              }
              waitComponentOnReady(childElm, promises);
            }
          };
          waitComponentOnReady(document.documentElement, promiseChain);
          Promise.all(promiseChain)
            .then(() => resolve())
            .catch(() => resolve());
        });
      });
    });
    if (page.isClosed()) {
      return;
    }
    await page.waitForTimeout(timeoutMs);
  }
  catch (e) {
    console.error(e);
  }
};
