/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { addE2EListener, EventSpy } from '../event-spy';
export const spyOnEvent = async (page, eventName) => {
  const spy = new EventSpy(eventName);
  const handle = await page.evaluateHandle(() => window);
  await addE2EListener(page, handle, eventName, (ev) => spy.push(ev));
  return spy;
};
