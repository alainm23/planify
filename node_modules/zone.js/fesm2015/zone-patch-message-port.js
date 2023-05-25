'use strict';
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */
/**
 * Monkey patch `MessagePort.prototype.onmessage` and `MessagePort.prototype.onmessageerror`
 * properties to make the callback in the zone when the value are set.
 */
Zone.__load_patch('MessagePort', (global, Zone, api) => {
    const MessagePort = global['MessagePort'];
    if (typeof MessagePort !== 'undefined' && MessagePort.prototype) {
        api.patchOnProperties(MessagePort.prototype, ['message', 'messageerror']);
    }
});
