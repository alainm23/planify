import type { Locator } from '@playwright/test';
import type { E2EPage } from '../../playwright-declarations';
import { EventSpy } from '../event-spy';
export type LocatorOptions = {
  hasText?: string | RegExp;
  has?: Locator;
};
export interface E2ELocator extends Locator {
  /**
   * Creates a new EventSpy and listens
   * on the element for an event.
   * The test will timeout if the event
   * never fires.
   *
   * Usage:
   * const input = page.locator('ion-input');
   * const ionChange = await locator.spyOnEvent('ionChange');
   * ...
   * await ionChange.next();
   */
  spyOnEvent: (eventName: string) => Promise<EventSpy>;
}
export declare const locator: (page: E2EPage, originalFn: (selector: string, options?: LocatorOptions | undefined) => E2ELocator, selector: string, options?: LocatorOptions) => E2ELocator;
