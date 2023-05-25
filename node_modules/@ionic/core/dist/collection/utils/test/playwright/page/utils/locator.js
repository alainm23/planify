/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { EventSpy, addE2EListener } from '../event-spy';
export const locator = (page, originalFn, selector, options) => {
  const locator = originalFn(selector, options);
  locator.spyOnEvent = async (eventName) => {
    const spy = new EventSpy(eventName);
    const handle = await locator.evaluateHandle((node) => node);
    await addE2EListener(page, handle, eventName, (ev) => spy.push(ev));
    return spy;
  };
  return locator;
};
