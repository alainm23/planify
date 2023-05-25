import type { EventSpy } from '../page/event-spy';
export declare function toHaveReceivedEventDetail(eventSpy: EventSpy, eventDetail: any): {
  message: () => string;
  pass: boolean;
};
