import type { EventSpy } from '../page/event-spy';
export declare function toHaveReceivedEvent(eventSpy: EventSpy): {
  message: () => string;
  pass: boolean;
};
