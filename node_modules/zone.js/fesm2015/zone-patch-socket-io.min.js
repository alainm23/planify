"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("socketio",((e,t,o)=>{t[t.__symbol__("socketio")]=function t(p){o.patchEventTarget(e,o,[p.Socket.prototype],{useG:!1,chkDup:!1,rt:!0,diff:(e,t)=>e.callback===t}),p.Socket.prototype.on=p.Socket.prototype.addEventListener,p.Socket.prototype.off=p.Socket.prototype.removeListener=p.Socket.prototype.removeAllListeners=p.Socket.prototype.removeEventListener}}));