import type { JSHandle } from '@playwright/test';
import type { E2EPage } from '../playwright-declarations';
/**
 * The EventSpy class allows
 * developers to listen for
 * a particular event emission and
 * pass/fail the test based on whether
 * or not the event was emitted.
 * Based off https://github.com/ionic-team/stencil/blob/16b8ea4dabb22024872a38bc58ba1dcf1c7cc25b/src/testing/puppeteer/puppeteer-events.ts#L64
 */
export declare class EventSpy {
  eventName: string;
  /**
   * Keeping track of a cursor
   * ensures that no two spy.next()
   * calls point to the same event.
   */
  private cursor;
  private queuedHandler;
  events: CustomEvent[];
  constructor(eventName: string);
  get length(): number;
  get firstEvent(): CustomEvent<any>;
  get lastEvent(): CustomEvent<any>;
  next(): Promise<CustomEvent<any>>;
  push(ev: CustomEvent): void;
}
/**
 * Initializes information required to
 * spy on events.
 * The ionicOnEvent function is called in the
 * context of the current page. This lets us
 * respond to an event listener created within
 * the page itself.
 */
export declare const initPageEvents: (page: E2EPage) => Promise<void>;
/**
 * Adds a new event listener in the current
 * page context to updates the _e2eEvents map
 * when an event is fired.
 */
export declare const addE2EListener: (page: E2EPage, elmHandle: JSHandle, eventName: string, callback: (ev: any) => void) => Promise<void>;
