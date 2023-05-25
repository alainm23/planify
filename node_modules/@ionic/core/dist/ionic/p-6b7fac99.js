/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import{a as r}from"./p-e1bc9a81.js";const t=(t,e,n)=>{const c=null==t?0:t.toString().length,a=o(c,e);if(void 0===n)return a;try{return n(c,e)}catch(t){return r("Exception in provided `counterFormatter`.",t),a}},o=(r,t)=>`${r} / ${t}`;export{t as g}