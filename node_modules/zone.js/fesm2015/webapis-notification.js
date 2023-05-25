'use strict';
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */
Zone.__load_patch('notification', (global, Zone, api) => {
    const Notification = global['Notification'];
    if (!Notification || !Notification.prototype) {
        return;
    }
    const desc = Object.getOwnPropertyDescriptor(Notification.prototype, 'onerror');
    if (!desc || !desc.configurable) {
        return;
    }
    api.patchOnProperties(Notification.prototype, null);
});
