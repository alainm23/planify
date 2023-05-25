"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("electron",((e,r,t)=>{function l(e,r,l){return t.patchMethod(e,r,(e=>(r,c)=>e&&e.apply(r,t.bindArguments(c,l))))}let{desktopCapturer:c,shell:n,CallbacksRegistry:o,ipcRenderer:a}=require("electron");if(!o)try{o=require("@electron/remote/dist/src/renderer/callbacks-registry").CallbacksRegistry}catch(e){}c&&l(c,"getSources","electron.desktopCapturer.getSources"),n&&l(n,"openExternal","electron.shell.openExternal"),o?l(o.prototype,"add","CallbackRegistry.add"):a&&l(a,"on","ipcRenderer.on")}));