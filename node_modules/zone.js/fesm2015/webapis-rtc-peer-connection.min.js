"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("RTCPeerConnection",((e,t,o)=>{const n=e.RTCPeerConnection;if(!n)return;const r=o.symbol("addEventListener"),p=o.symbol("removeEventListener");n.prototype.addEventListener=n.prototype[r],n.prototype.removeEventListener=n.prototype[p],n.prototype[r]=null,n.prototype[p]=null,o.patchEventTarget(e,o,[n.prototype],{useG:!1})}));