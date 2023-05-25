import type { EventSpy } from '../page/event-spy';
export declare function toHaveReceivedEventTimes(eventSpy: EventSpy, count: number): {
  message: () => string;
  pass: boolean;
};
