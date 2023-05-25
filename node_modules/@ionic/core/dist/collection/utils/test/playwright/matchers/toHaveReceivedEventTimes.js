/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
export function toHaveReceivedEventTimes(eventSpy, count) {
  // eslint-disable-next-line @typescript-eslint/strict-boolean-expressions
  if (!eventSpy) {
    return {
      message: () => `toHaveReceivedEventTimes event spy is null`,
      pass: false,
    };
  }
  if (typeof eventSpy.then === 'function') {
    return {
      message: () => `expected spy to have received event, but it was not resolved (did you forget an await operator?).`,
      pass: false,
    };
  }
  if (!eventSpy.eventName) {
    return {
      message: () => `toHaveReceivedEventTimes did not receive an event spy`,
      pass: false,
    };
  }
  const pass = eventSpy.length === count;
  return {
    message: () => `expected event "${eventSpy.eventName}" to have been called ${count} times, but it was called ${eventSpy.events.length} times`,
    pass: pass,
  };
}
