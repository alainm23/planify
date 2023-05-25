import type { E2EPage } from '../../playwright-declarations';
import { EventSpy } from '../event-spy';
export declare const spyOnEvent: (page: E2EPage, eventName: string) => Promise<EventSpy>;
