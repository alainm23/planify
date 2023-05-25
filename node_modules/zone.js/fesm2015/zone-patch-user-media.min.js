"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("getUserMedia",((e,t,r)=>{let a=e.navigator;a&&a.getUserMedia&&(a.getUserMedia=function n(e,t){return function(){const a=Array.prototype.slice.call(arguments),n=r.bindArguments(a,t||e.name);return e.apply(this,n)}}(a.getUserMedia))}));