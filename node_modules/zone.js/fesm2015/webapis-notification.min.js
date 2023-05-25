"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("notification",((t,o,r)=>{const e=t.Notification;if(!e||!e.prototype)return;const n=Object.getOwnPropertyDescriptor(e.prototype,"onerror");n&&n.configurable&&r.patchOnProperties(e.prototype,null)}));