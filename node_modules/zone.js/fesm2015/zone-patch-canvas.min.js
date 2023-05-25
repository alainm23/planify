"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("canvas",((t,o,a)=>{const e=t.HTMLCanvasElement;void 0!==e&&e.prototype&&e.prototype.toBlob&&a.patchMacroTask(e.prototype,"toBlob",((t,o)=>({name:"HTMLCanvasElement.toBlob",target:t,cbIdx:0,args:o})))}));