"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */Zone.__load_patch("jsonp",((n,s,o)=>{s[s.__symbol__("jsonp")]=function c(a){if(!a||!a.jsonp||!a.sendFuncName)return;const e=function(){};[a.successFuncName,a.failedFuncName].forEach((s=>{s&&(n[s]?o.patchMethod(n,s,(s=>(c,a)=>{const e=n[o.symbol("jsonTask")];return e?(e.callback=s,e.invoke.apply(c,a)):s.apply(c,a)})):Object.defineProperty(n,s,{configurable:!0,enumerable:!0,get:function(){return function(){const c=n[o.symbol("jsonpTask")],a=n[o.symbol(`jsonp${s}callback`)];return c?(a&&(c.callback=a),n[o.symbol("jsonpTask")]=void 0,c.invoke.apply(this,arguments)):a?a.apply(this,arguments):null}},set:function(n){this[o.symbol(`jsonp${s}callback`)]=n}}))})),o.patchMethod(a.jsonp,a.sendFuncName,(c=>(a,l)=>{n[o.symbol("jsonpTask")]=s.current.scheduleMacroTask("jsonp",e,{},(n=>c.apply(a,l)),e)}))}}));