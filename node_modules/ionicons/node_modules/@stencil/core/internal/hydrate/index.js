function queryNonceMetaTagContent(e) {
 var t, o, n;
 return null !== (n = null === (o = null === (t = e.head) || void 0 === t ? void 0 : t.querySelector('meta[name="csp-nonce"]')) || void 0 === o ? void 0 : o.getAttribute("content")) && void 0 !== n ? n : void 0;
}

function componentOnReady() {
 return getHostRef(this).$onReadyPromise$;
}

function forceUpdate() {}

function hydrateApp(e, t, o, n, s) {
 function l() {
  if (global.clearTimeout(p), i.clear(), r.clear(), !h) {
   h = !0;
   try {
    t.clientHydrateAnnotations && insertVdomAnnotations(e.document, t.staticComponents), 
    e.dispatchEvent(new e.Event("DOMContentLoaded")), e.document.createElement = c, 
    e.document.createElementNS = $;
   } catch (e) {
    renderCatchError(t, o, e);
   }
  }
  n(e, t, o, s);
 }
 function a(e) {
  renderCatchError(t, o, e), l();
 }
 const r = new Set, i = new Set, d = new Set, c = e.document.createElement, $ = e.document.createElementNS, m = Promise.resolve();
 let p, h = !1;
 try {
  function u() {
   return g(this);
  }
  function f(e) {
   if (isValidComponent(e, t) && !getHostRef(e)) {
    const t = loadModule({
     $tagName$: e.nodeName.toLowerCase(),
     $flags$: null
    }, null);
    null != t && null != t.cmpMeta && (i.add(e), e.connectedCallback = u, registerHost(e, t.cmpMeta), 
    function o(e, t) {
     if ("function" != typeof e.componentOnReady && (e.componentOnReady = componentOnReady), 
     "function" != typeof e.forceUpdate && (e.forceUpdate = forceUpdate), 1 & t.$flags$ && (e.shadowRoot = e), 
     null != t.$members$) {
      const o = getHostRef(e);
      Object.entries(t.$members$).forEach((([n, s]) => {
       const l = s[0];
       if (31 & l) {
        const a = s[1] || n, r = e.getAttribute(a);
        if (null != r) {
         const e = parsePropertyValue(r, l);
         o.$instanceValues$.set(n, e);
        }
        const i = e[n];
        void 0 !== i && (o.$instanceValues$.set(n, i), delete e[n]), Object.defineProperty(e, n, {
         get() {
          return getValue(this, n);
         },
         set(e) {
          setValue(this, n, e, t);
         },
         configurable: !0,
         enumerable: !0
        });
       } else 64 & l && Object.defineProperty(e, n, {
        value(...e) {
         const t = getHostRef(this);
         return t.$onInstancePromise$.then((() => t.$lazyInstance$[n](...e))).catch(consoleError);
        }
       });
      }));
     }
    }(e, t.cmpMeta));
   }
  }
  function g(n) {
   return i.delete(n), isValidComponent(n, t) && o.hydratedCount < t.maxHydrateCount && !r.has(n) && shouldHydrate(n) ? (r.add(n), 
   async function s(e, t, o, n, l) {
    o = o.toLowerCase();
    const a = loadModule({
     $tagName$: o,
     $flags$: null
    });
    if (null != a && null != a.cmpMeta) {
     l.add(n);
     try {
      connectedCallback(n), await n.componentOnReady(), t.hydratedCount++;
      const e = getHostRef(n), s = e.$modeName$ ? e.$modeName$ : "$";
      t.components.some((e => e.tag === o && e.mode === s)) || t.components.push({
       tag: o,
       mode: s,
       count: 0,
       depth: -1
      });
     } catch (t) {
      e.console.error(t);
     }
     l.delete(n);
    }
   }(e, o, n.nodeName, n, d)) : m;
  }
  e.document.createElement = function t(o) {
   const n = c.call(e.document, o);
   return f(n), n;
  }, e.document.createElementNS = function t(o, n) {
   const s = $.call(e.document, o, n);
   return f(s), s;
  }, p = global.setTimeout((function L() {
   a(`Hydrate exceeded timeout${function e(t) {
    return Array.from(t).map(waitingOnElementMsg);
   }(d)}`);
  }), t.timeout), plt.$resourcesUrl$ = new URL(t.resourcesUrl || "./", doc.baseURI).href, 
  globalScripts(), function e(t) {
   if (null != t && 1 === t.nodeType) {
    f(t);
    const o = t.children;
    for (let t = 0, n = o.length; t < n; t++) e(o[t]);
   }
  }(e.document.body), function e() {
   const t = Array.from(i).filter((e => e.parentElement));
   return t.length > 0 ? Promise.all(t.map(g)).then(e) : m;
  }().then(l).catch(a);
 } catch (y) {
  a(y);
 }
}

function isValidComponent(e, t) {
 if (null != e && 1 === e.nodeType) {
  const o = e.nodeName;
  if ("string" == typeof o && o.includes("-")) return !t.excludeComponents.includes(o.toLowerCase());
 }
 return !1;
}

function shouldHydrate(e) {
 if (9 === e.nodeType) return !0;
 if (NO_HYDRATE_TAGS.has(e.nodeName)) return !1;
 if (e.hasAttribute("no-prerender")) return !1;
 const t = e.parentNode;
 return null == t || shouldHydrate(t);
}

function renderCatchError(e, t, o) {
 const n = {
  level: "error",
  type: "build",
  header: "Hydrate Error",
  messageText: "",
  relFilePath: null,
  absFilePath: null,
  lines: []
 };
 if (e.url) try {
  const t = new URL(e.url);
  "/" !== t.pathname && (n.header += ": " + t.pathname);
 } catch (e) {}
 null != o && (null != o.stack ? n.messageText = o.stack.toString() : null != o.message ? n.messageText = o.message.toString() : n.messageText = o.toString()), 
 t.diagnostics.push(n);
}

function printTag(e) {
 let t = `<${e.nodeName.toLowerCase()}`;
 if (Array.isArray(e.attributes)) for (let o = 0; o < e.attributes.length; o++) {
  const n = e.attributes[o];
  t += ` ${n.name}`, "" !== n.value && (t += `="${n.value}"`);
 }
 return t += ">", t;
}

function waitingOnElementMsg(e) {
 let t = "";
 if (e) {
  const o = [];
  t = " - waiting on:";
  let n = e;
  for (;n && 9 !== n.nodeType && "BODY" !== n.nodeName; ) o.unshift(printTag(n)), 
  n = n.parentElement;
  let s = "";
  for (const e of o) s += "  ", t += `\n${s}${e}`;
 }
 return t;
}

import { BUILD, NAMESPACE } from "@stencil/core/internal/app-data";

export { BUILD, Env, NAMESPACE } from "@stencil/core/internal/app-data";

import { globalScripts } from "@stencil/core/internal/app-globals";

const getAssetPath = e => {
 const t = new URL(e, plt.$resourcesUrl$);
 return t.origin !== win.location.origin ? t.href : t.pathname;
}, setAssetPath = e => plt.$resourcesUrl$ = e;

let i = 0;

const createTime = (e, t = "") => {
 if (BUILD.profile && performance.mark) {
  const o = `st:${e}:${t}:${i++}`;
  return performance.mark(o), () => performance.measure(`[Stencil] ${e}() <${t}>`, o);
 }
 return () => {};
}, XLINK_NS = "http://www.w3.org/1999/xlink", EMPTY_OBJ = {}, isComplexType = e => "object" == (e = typeof e) || "function" === e, isPromise = e => !!e && ("object" == typeof e || "function" == typeof e) && "function" == typeof e.then, h = (e, t, ...o) => {
 let n = null, s = null, l = null, a = !1, r = !1;
 const i = [], d = t => {
  for (let o = 0; o < t.length; o++) n = t[o], Array.isArray(n) ? d(n) : null != n && "boolean" != typeof n && ((a = "function" != typeof e && !isComplexType(n)) ? n = String(n) : BUILD.isDev && "function" != typeof e && n.$flags$, 
  a && r ? i[i.length - 1].$text$ += n : i.push(a ? newVNode(null, n) : n), r = a);
 };
 if (d(o), t && (BUILD.isDev && "input" === e && validateInputProperties(t), BUILD.vdomKey && t.key && (s = t.key), 
 BUILD.slotRelocation && t.name && (l = t.name), BUILD.vdomClass)) {
  const e = t.className || t.class;
  e && (t.class = "object" != typeof e ? e : Object.keys(e).filter((t => e[t])).join(" "));
 }
 if (BUILD.isDev && i.some(isHost), BUILD.vdomFunctional && "function" == typeof e) return e(null === t ? {} : t, i, vdomFnUtils);
 const c = newVNode(e, null);
 return c.$attrs$ = t, i.length > 0 && (c.$children$ = i), BUILD.vdomKey && (c.$key$ = s), 
 BUILD.slotRelocation && (c.$name$ = l), c;
}, newVNode = (e, t) => {
 const o = {
  $flags$: 0,
  $tag$: e,
  $text$: t,
  $elm$: null,
  $children$: null
 };
 return BUILD.vdomAttribute && (o.$attrs$ = null), BUILD.vdomKey && (o.$key$ = null), 
 BUILD.slotRelocation && (o.$name$ = null), o;
}, Host = {}, isHost = e => e && e.$tag$ === Host, vdomFnUtils = {
 forEach: (e, t) => e.map(convertToPublic).forEach(t),
 map: (e, t) => e.map(convertToPublic).map(t).map(convertToPrivate)
}, convertToPublic = e => ({
 vattrs: e.$attrs$,
 vchildren: e.$children$,
 vkey: e.$key$,
 vname: e.$name$,
 vtag: e.$tag$,
 vtext: e.$text$
}), convertToPrivate = e => {
 if ("function" == typeof e.vtag) {
  const t = {
   ...e.vattrs
  };
  return e.vkey && (t.key = e.vkey), e.vname && (t.name = e.vname), h(e.vtag, t, ...e.vchildren || []);
 }
 const t = newVNode(e.vtag, e.vtext);
 return t.$attrs$ = e.vattrs, t.$children$ = e.vchildren, t.$key$ = e.vkey, t.$name$ = e.vname, 
 t;
}, validateInputProperties = e => {
 const t = Object.keys(e);
 -1 !== t.indexOf("value") && (t.indexOf("type"), t.indexOf("min"), t.indexOf("max"), 
 t.indexOf("step"));
}, clientHydrate = (e, t, o, n, s, l, a) => {
 let r, i, d, c;
 if (1 === l.nodeType) {
  for (r = l.getAttribute("c-id"), r && (i = r.split("."), i[0] !== a && "0" !== i[0] || (d = {
   $flags$: 0,
   $hostId$: i[0],
   $nodeId$: i[1],
   $depth$: i[2],
   $index$: i[3],
   $tag$: l.tagName.toLowerCase(),
   $elm$: l,
   $attrs$: null,
   $children$: null,
   $key$: null,
   $name$: null,
   $text$: null
  }, t.push(d), l.removeAttribute("c-id"), e.$children$ || (e.$children$ = []), e.$children$[d.$index$] = d, 
  e = d, n && "0" === d.$depth$ && (n[d.$index$] = d.$elm$))), c = l.childNodes.length - 1; c >= 0; c--) clientHydrate(e, t, o, n, s, l.childNodes[c], a);
  if (l.shadowRoot) for (c = l.shadowRoot.childNodes.length - 1; c >= 0; c--) clientHydrate(e, t, o, n, s, l.shadowRoot.childNodes[c], a);
 } else if (8 === l.nodeType) i = l.nodeValue.split("."), i[1] !== a && "0" !== i[1] || (r = i[0], 
 d = {
  $flags$: 0,
  $hostId$: i[1],
  $nodeId$: i[2],
  $depth$: i[3],
  $index$: i[4],
  $elm$: l,
  $attrs$: null,
  $children$: null,
  $key$: null,
  $name$: null,
  $tag$: null,
  $text$: null
 }, "t" === r ? (d.$elm$ = l.nextSibling, d.$elm$ && 3 === d.$elm$.nodeType && (d.$text$ = d.$elm$.textContent, 
 t.push(d), l.remove(), e.$children$ || (e.$children$ = []), e.$children$[d.$index$] = d, 
 n && "0" === d.$depth$ && (n[d.$index$] = d.$elm$))) : d.$hostId$ === a && ("s" === r ? (d.$tag$ = "slot", 
 i[5] ? l["s-sn"] = d.$name$ = i[5] : l["s-sn"] = "", l["s-sr"] = !0, BUILD.shadowDom && n && (d.$elm$ = doc.createElement(d.$tag$), 
 d.$name$ && d.$elm$.setAttribute("name", d.$name$), l.parentNode.insertBefore(d.$elm$, l), 
 l.remove(), "0" === d.$depth$ && (n[d.$index$] = d.$elm$)), o.push(d), e.$children$ || (e.$children$ = []), 
 e.$children$[d.$index$] = d) : "r" === r && (BUILD.shadowDom && n ? l.remove() : BUILD.slotRelocation && (s["s-cr"] = l, 
 l["s-cn"] = !0)))); else if (e && "style" === e.$tag$) {
  const t = newVNode(null, l.textContent);
  t.$elm$ = l, t.$index$ = "0", e.$children$ = [ t ];
 }
}, initializeDocumentHydrate = (e, t) => {
 if (1 === e.nodeType) {
  let o = 0;
  for (;o < e.childNodes.length; o++) initializeDocumentHydrate(e.childNodes[o], t);
  if (e.shadowRoot) for (o = 0; o < e.shadowRoot.childNodes.length; o++) initializeDocumentHydrate(e.shadowRoot.childNodes[o], t);
 } else if (8 === e.nodeType) {
  const o = e.nodeValue.split(".");
  "o" === o[0] && (t.set(o[1] + "." + o[2], e), e.nodeValue = "", e["s-en"] = o[3]);
 }
}, computeMode = e => modeResolutionChain.map((t => t(e))).find((e => !!e)), setMode = e => modeResolutionChain.push(e), getMode = e => getHostRef(e).$modeName$, parsePropertyValue = (e, t) => null == e || isComplexType(e) ? e : BUILD.propBoolean && 4 & t ? "false" !== e && ("" === e || !!e) : BUILD.propNumber && 2 & t ? parseFloat(e) : BUILD.propString && 1 & t ? String(e) : e, getElement = e => BUILD.lazyLoad ? getHostRef(e).$hostElement$ : e, createEvent = (e, t, o) => {
 const n = getElement(e);
 return {
  emit: e => (BUILD.isDev && n.isConnected, emitEvent(n, t, {
   bubbles: !!(4 & o),
   composed: !!(2 & o),
   cancelable: !!(1 & o),
   detail: e
  }))
 };
}, emitEvent = (e, t, o) => {
 const n = plt.ce(t, o);
 return e.dispatchEvent(n), n;
}, rootAppliedStyles = new WeakMap, registerStyle = (e, t, o) => {
 let n = styles.get(e);
 n = t, styles.set(e, n);
}, addStyle = (e, t, o, n) => {
 var s;
 let l = getScopeId(t, o);
 const a = styles.get(l);
 if (!BUILD.attachStyles) return l;
 if (e = 11 === e.nodeType ? e : doc, a) if ("string" == typeof a) {
  e = e.head || e;
  let o, r = rootAppliedStyles.get(e);
  if (r || rootAppliedStyles.set(e, r = new Set), !r.has(l)) {
   if (BUILD.hydrateClientSide && e.host && (o = e.querySelector(`[sty-id="${l}"]`))) o.innerHTML = a; else {
    if (BUILD.cssVarShim && plt.$cssShim$) {
     o = plt.$cssShim$.createHostStyle(n, l, a, !!(10 & t.$flags$));
     const e = o["s-sc"];
     e && (l = e, r = null);
    } else o = doc.createElement("style"), o.innerHTML = a;
    const i = null !== (s = plt.$nonce$) && void 0 !== s ? s : queryNonceMetaTagContent(doc);
    null != i && o.setAttribute("nonce", i), (BUILD.hydrateServerSide || BUILD.hotModuleReplacement) && o.setAttribute("sty-id", l), 
    e.insertBefore(o, e.querySelector("link"));
   }
   r && r.add(l);
  }
 } else BUILD.constructableCSS && !e.adoptedStyleSheets.includes(a) && (e.adoptedStyleSheets = [ ...e.adoptedStyleSheets, a ]);
 return l;
}, attachStyles = e => {
 const t = e.$cmpMeta$, o = e.$hostElement$, n = t.$flags$, s = createTime("attachStyles", t.$tagName$), l = addStyle(BUILD.shadowDom && supportsShadow && o.shadowRoot ? o.shadowRoot : o.getRootNode(), t, e.$modeName$, o);
 (BUILD.shadowDom || BUILD.scoped) && BUILD.cssAnnotations && 10 & n && (o["s-sc"] = l, 
 o.classList.add(l + "-h"), BUILD.scoped && 2 & n && o.classList.add(l + "-s")), 
 s();
}, getScopeId = (e, t) => "sc-" + (BUILD.mode && t && 32 & e.$flags$ ? e.$tagName$ + "-" + t : e.$tagName$), setAccessor = (e, t, o, n, s, l) => {
 if (o !== n) {
  let a = isMemberInElement(e, t), r = t.toLowerCase();
  if (BUILD.vdomClass && "class" === t) {
   const t = e.classList, s = parseClassList(o), l = parseClassList(n);
   t.remove(...s.filter((e => e && !l.includes(e)))), t.add(...l.filter((e => e && !s.includes(e))));
  } else if (BUILD.vdomStyle && "style" === t) {
   if (BUILD.updatable) for (const t in o) n && null != n[t] || (!BUILD.hydrateServerSide && t.includes("-") ? e.style.removeProperty(t) : e.style[t] = "");
   for (const t in n) o && n[t] === o[t] || (!BUILD.hydrateServerSide && t.includes("-") ? e.style.setProperty(t, n[t]) : e.style[t] = n[t]);
  } else if (BUILD.vdomKey && "key" === t) ; else if (BUILD.vdomRef && "ref" === t) n && n(e); else if (!BUILD.vdomListener || (BUILD.lazyLoad ? a : e.__lookupSetter__(t)) || "o" !== t[0] || "n" !== t[1]) {
   if (BUILD.vdomPropOrAttr) {
    const i = isComplexType(n);
    if ((a || i && null !== n) && !s) try {
     if (e.tagName.includes("-")) e[t] = n; else {
      const s = null == n ? "" : n;
      "list" === t ? a = !1 : null != o && e[t] == s || (e[t] = s);
     }
    } catch (e) {}
    let d = !1;
    BUILD.vdomXlink && r !== (r = r.replace(/^xlink\:?/, "")) && (t = r, d = !0), null == n || !1 === n ? !1 === n && "" !== e.getAttribute(t) || (BUILD.vdomXlink && d ? e.removeAttributeNS(XLINK_NS, t) : e.removeAttribute(t)) : (!a || 4 & l || s) && !i && (n = !0 === n ? "" : n, 
    BUILD.vdomXlink && d ? e.setAttributeNS(XLINK_NS, t, n) : e.setAttribute(t, n));
   }
  } else t = "-" === t[2] ? t.slice(3) : isMemberInElement(win, r) ? r.slice(2) : r[2] + t.slice(3), 
  o && plt.rel(e, t, o, !1), n && plt.ael(e, t, n, !1);
 }
}, parseClassListRegex = /\s/, parseClassList = e => e ? e.split(parseClassListRegex) : [], updateElement = (e, t, o, n) => {
 const s = 11 === t.$elm$.nodeType && t.$elm$.host ? t.$elm$.host : t.$elm$, l = e && e.$attrs$ || EMPTY_OBJ, a = t.$attrs$ || EMPTY_OBJ;
 if (BUILD.updatable) for (n in l) n in a || setAccessor(s, n, l[n], void 0, o, t.$flags$);
 for (n in a) setAccessor(s, n, l[n], a[n], o, t.$flags$);
};

let scopeId, contentRef, hostTagName, useNativeShadowDom = !1, checkSlotFallbackVisibility = !1, checkSlotRelocate = !1, isSvgMode = !1;

const createElm = (e, t, o, n) => {
 const s = t.$children$[o];
 let l, a, r, i = 0;
 if (BUILD.slotRelocation && !useNativeShadowDom && (checkSlotRelocate = !0, "slot" === s.$tag$ && (scopeId && n.classList.add(scopeId + "-s"), 
 s.$flags$ |= s.$children$ ? 2 : 1)), BUILD.isDev && s.$elm$ && consoleDevError(`The JSX ${null !== s.$text$ ? `"${s.$text$}" text` : `"${s.$tag$}" element`} node should not be shared within the same renderer. The renderer caches element lookups in order to improve performance. However, a side effect from this is that the exact same JSX node should not be reused. For more information please see https://stenciljs.com/docs/templating-jsx#avoid-shared-jsx-nodes`), 
 BUILD.vdomText && null !== s.$text$) l = s.$elm$ = doc.createTextNode(s.$text$); else if (BUILD.slotRelocation && 1 & s.$flags$) l = s.$elm$ = BUILD.isDebug || BUILD.hydrateServerSide ? slotReferenceDebugNode(s) : doc.createTextNode(""); else {
  if (BUILD.svg && !isSvgMode && (isSvgMode = "svg" === s.$tag$), l = s.$elm$ = BUILD.svg ? doc.createElementNS(isSvgMode ? "http://www.w3.org/2000/svg" : "http://www.w3.org/1999/xhtml", BUILD.slotRelocation && 2 & s.$flags$ ? "slot-fb" : s.$tag$) : doc.createElement(BUILD.slotRelocation && 2 & s.$flags$ ? "slot-fb" : s.$tag$), 
  BUILD.svg && isSvgMode && "foreignObject" === s.$tag$ && (isSvgMode = !1), BUILD.vdomAttribute && updateElement(null, s, isSvgMode), 
  (BUILD.shadowDom || BUILD.scoped) && null != scopeId && l["s-si"] !== scopeId && l.classList.add(l["s-si"] = scopeId), 
  s.$children$) for (i = 0; i < s.$children$.length; ++i) a = createElm(e, s, i, l), 
  a && l.appendChild(a);
  BUILD.svg && ("svg" === s.$tag$ ? isSvgMode = !1 : "foreignObject" === l.tagName && (isSvgMode = !0));
 }
 return BUILD.slotRelocation && (l["s-hn"] = hostTagName, 3 & s.$flags$ && (l["s-sr"] = !0, 
 l["s-cr"] = contentRef, l["s-sn"] = s.$name$ || "", r = e && e.$children$ && e.$children$[o], 
 r && r.$tag$ === s.$tag$ && e.$elm$ && putBackInOriginalLocation(e.$elm$, !1))), 
 l;
}, putBackInOriginalLocation = (e, t) => {
 plt.$flags$ |= 1;
 const o = e.childNodes;
 for (let e = o.length - 1; e >= 0; e--) {
  const n = o[e];
  n["s-hn"] !== hostTagName && n["s-ol"] && (parentReferenceNode(n).insertBefore(n, referenceNode(n)), 
  n["s-ol"].remove(), n["s-ol"] = void 0, checkSlotRelocate = !0), t && putBackInOriginalLocation(n, t);
 }
 plt.$flags$ &= -2;
}, addVnodes = (e, t, o, n, s, l) => {
 let a, r = BUILD.slotRelocation && e["s-cr"] && e["s-cr"].parentNode || e;
 for (BUILD.shadowDom && r.shadowRoot && r.tagName === hostTagName && (r = r.shadowRoot); s <= l; ++s) n[s] && (a = createElm(null, o, s, e), 
 a && (n[s].$elm$ = a, r.insertBefore(a, BUILD.slotRelocation ? referenceNode(t) : t)));
}, removeVnodes = (e, t, o, n, s) => {
 for (;t <= o; ++t) (n = e[t]) && (s = n.$elm$, callNodeRefs(n), BUILD.slotRelocation && (checkSlotFallbackVisibility = !0, 
 s["s-ol"] ? s["s-ol"].remove() : putBackInOriginalLocation(s, !0)), s.remove());
}, isSameVnode = (e, t) => e.$tag$ === t.$tag$ && (BUILD.slotRelocation && "slot" === e.$tag$ ? e.$name$ === t.$name$ : !BUILD.vdomKey || e.$key$ === t.$key$), referenceNode = e => e && e["s-ol"] || e, parentReferenceNode = e => (e["s-ol"] ? e["s-ol"] : e).parentNode, patch = (e, t) => {
 const o = t.$elm$ = e.$elm$, n = e.$children$, s = t.$children$, l = t.$tag$, a = t.$text$;
 let r;
 BUILD.vdomText && null !== a ? BUILD.vdomText && BUILD.slotRelocation && (r = o["s-cr"]) ? r.parentNode.textContent = a : BUILD.vdomText && e.$text$ !== a && (o.data = a) : (BUILD.svg && (isSvgMode = "svg" === l || "foreignObject" !== l && isSvgMode), 
 (BUILD.vdomAttribute || BUILD.reflect) && (BUILD.slot && "slot" === l || updateElement(e, t, isSvgMode)), 
 BUILD.updatable && null !== n && null !== s ? ((e, t, o, n) => {
  let s, l, a = 0, r = 0, i = 0, d = 0, c = t.length - 1, $ = t[0], m = t[c], p = n.length - 1, h = n[0], u = n[p];
  for (;a <= c && r <= p; ) if (null == $) $ = t[++a]; else if (null == m) m = t[--c]; else if (null == h) h = n[++r]; else if (null == u) u = n[--p]; else if (isSameVnode($, h)) patch($, h), 
  $ = t[++a], h = n[++r]; else if (isSameVnode(m, u)) patch(m, u), m = t[--c], u = n[--p]; else if (isSameVnode($, u)) !BUILD.slotRelocation || "slot" !== $.$tag$ && "slot" !== u.$tag$ || putBackInOriginalLocation($.$elm$.parentNode, !1), 
  patch($, u), e.insertBefore($.$elm$, m.$elm$.nextSibling), $ = t[++a], u = n[--p]; else if (isSameVnode(m, h)) !BUILD.slotRelocation || "slot" !== $.$tag$ && "slot" !== u.$tag$ || putBackInOriginalLocation(m.$elm$.parentNode, !1), 
  patch(m, h), e.insertBefore(m.$elm$, $.$elm$), m = t[--c], h = n[++r]; else {
   if (i = -1, BUILD.vdomKey) for (d = a; d <= c; ++d) if (t[d] && null !== t[d].$key$ && t[d].$key$ === h.$key$) {
    i = d;
    break;
   }
   BUILD.vdomKey && i >= 0 ? (l = t[i], l.$tag$ !== h.$tag$ ? s = createElm(t && t[r], o, i, e) : (patch(l, h), 
   t[i] = void 0, s = l.$elm$), h = n[++r]) : (s = createElm(t && t[r], o, r, e), h = n[++r]), 
   s && (BUILD.slotRelocation ? parentReferenceNode($.$elm$).insertBefore(s, referenceNode($.$elm$)) : $.$elm$.parentNode.insertBefore(s, $.$elm$));
  }
  a > c ? addVnodes(e, null == n[p + 1] ? null : n[p + 1].$elm$, o, n, r, p) : BUILD.updatable && r > p && removeVnodes(t, a, c);
 })(o, n, t, s) : null !== s ? (BUILD.updatable && BUILD.vdomText && null !== e.$text$ && (o.textContent = ""), 
 addVnodes(o, null, t, s, 0, s.length - 1)) : BUILD.updatable && null !== n && removeVnodes(n, 0, n.length - 1), 
 BUILD.svg && isSvgMode && "svg" === l && (isSvgMode = !1));
}, updateFallbackSlotVisibility = e => {
 const t = e.childNodes;
 let o, n, s, l, a, r;
 for (n = 0, s = t.length; n < s; n++) if (o = t[n], 1 === o.nodeType) {
  if (o["s-sr"]) for (a = o["s-sn"], o.hidden = !1, l = 0; l < s; l++) if (r = t[l].nodeType, 
  t[l]["s-hn"] !== o["s-hn"] || "" !== a) {
   if (1 === r && a === t[l].getAttribute("slot")) {
    o.hidden = !0;
    break;
   }
  } else if (1 === r || 3 === r && "" !== t[l].textContent.trim()) {
   o.hidden = !0;
   break;
  }
  updateFallbackSlotVisibility(o);
 }
}, relocateNodes = [], relocateSlotContent = e => {
 let t, o, n, s, l, a, r = 0;
 const i = e.childNodes, d = i.length;
 for (;r < d; r++) {
  if (t = i[r], t["s-sr"] && (o = t["s-cr"]) && o.parentNode) for (n = o.parentNode.childNodes, 
  s = t["s-sn"], a = n.length - 1; a >= 0; a--) o = n[a], o["s-cn"] || o["s-nr"] || o["s-hn"] === t["s-hn"] || (isNodeLocatedInSlot(o, s) ? (l = relocateNodes.find((e => e.$nodeToRelocate$ === o)), 
  checkSlotFallbackVisibility = !0, o["s-sn"] = o["s-sn"] || s, l ? l.$slotRefNode$ = t : relocateNodes.push({
   $slotRefNode$: t,
   $nodeToRelocate$: o
  }), o["s-sr"] && relocateNodes.map((e => {
   isNodeLocatedInSlot(e.$nodeToRelocate$, o["s-sn"]) && (l = relocateNodes.find((e => e.$nodeToRelocate$ === o)), 
   l && !e.$slotRefNode$ && (e.$slotRefNode$ = l.$slotRefNode$));
  }))) : relocateNodes.some((e => e.$nodeToRelocate$ === o)) || relocateNodes.push({
   $nodeToRelocate$: o
  }));
  1 === t.nodeType && relocateSlotContent(t);
 }
}, isNodeLocatedInSlot = (e, t) => 1 === e.nodeType ? null === e.getAttribute("slot") && "" === t || e.getAttribute("slot") === t : e["s-sn"] === t || "" === t, callNodeRefs = e => {
 BUILD.vdomRef && (e.$attrs$ && e.$attrs$.ref && e.$attrs$.ref(null), e.$children$ && e.$children$.map(callNodeRefs));
}, renderVdom = (e, t) => {
 const o = e.$hostElement$, n = e.$cmpMeta$, s = e.$vnode$ || newVNode(null, null), l = isHost(t) ? t : h(null, null, t);
 if (hostTagName = o.tagName, BUILD.isDev && Array.isArray(t) && t.some(isHost)) throw new Error(`The <Host> must be the single root component.\nLooks like the render() function of "${hostTagName.toLowerCase()}" is returning an array that contains the <Host>.\n\nThe render() function should look like this instead:\n\nrender() {\n  // Do not return an array\n  return (\n    <Host>{content}</Host>\n  );\n}\n  `);
 if (BUILD.reflect && n.$attrsToReflect$ && (l.$attrs$ = l.$attrs$ || {}, n.$attrsToReflect$.map((([e, t]) => l.$attrs$[t] = o[e]))), 
 l.$tag$ = null, l.$flags$ |= 4, e.$vnode$ = l, l.$elm$ = s.$elm$ = BUILD.shadowDom && o.shadowRoot || o, 
 (BUILD.scoped || BUILD.shadowDom) && (scopeId = o["s-sc"]), BUILD.slotRelocation && (contentRef = o["s-cr"], 
 useNativeShadowDom = supportsShadow, checkSlotFallbackVisibility = !1), patch(s, l), 
 BUILD.slotRelocation) {
  if (plt.$flags$ |= 1, checkSlotRelocate) {
   let e, t, o, n, s, a;
   relocateSlotContent(l.$elm$);
   let r = 0;
   for (;r < relocateNodes.length; r++) e = relocateNodes[r], t = e.$nodeToRelocate$, 
   t["s-ol"] || (o = BUILD.isDebug || BUILD.hydrateServerSide ? originalLocationDebugNode(t) : doc.createTextNode(""), 
   o["s-nr"] = t, t.parentNode.insertBefore(t["s-ol"] = o, t));
   for (r = 0; r < relocateNodes.length; r++) if (e = relocateNodes[r], t = e.$nodeToRelocate$, 
   e.$slotRefNode$) {
    for (n = e.$slotRefNode$.parentNode, s = e.$slotRefNode$.nextSibling, o = t["s-ol"]; o = o.previousSibling; ) if (a = o["s-nr"], 
    a && a["s-sn"] === t["s-sn"] && n === a.parentNode && (a = a.nextSibling, !a || !a["s-nr"])) {
     s = a;
     break;
    }
    (!s && n !== t.parentNode || t.nextSibling !== s) && t !== s && (!t["s-hn"] && t["s-ol"] && (t["s-hn"] = t["s-ol"].parentNode.nodeName), 
    n.insertBefore(t, s));
   } else 1 === t.nodeType && (t.hidden = !0);
  }
  checkSlotFallbackVisibility && updateFallbackSlotVisibility(l.$elm$), plt.$flags$ &= -2, 
  relocateNodes.length = 0;
 }
}, slotReferenceDebugNode = e => doc.createComment(`<slot${e.$name$ ? ' name="' + e.$name$ + '"' : ""}> (host=${hostTagName.toLowerCase()})`), originalLocationDebugNode = e => doc.createComment("org-location for " + (e.localName ? `<${e.localName}> (host=${e["s-hn"]})` : `[${e.textContent}]`)), attachToAncestor = (e, t) => {
 BUILD.asyncLoading && t && !e.$onRenderResolve$ && t["s-p"] && t["s-p"].push(new Promise((t => e.$onRenderResolve$ = t)));
}, scheduleUpdate = (e, t) => {
 if (BUILD.taskQueue && BUILD.updatable && (e.$flags$ |= 16), BUILD.asyncLoading && 4 & e.$flags$) return void (e.$flags$ |= 512);
 attachToAncestor(e, e.$ancestorComponent$);
 const o = () => dispatchHooks(e, t);
 return BUILD.taskQueue ? writeTask(o) : o();
}, dispatchHooks = (e, t) => {
 const o = e.$hostElement$, n = createTime("scheduleUpdate", e.$cmpMeta$.$tagName$), s = BUILD.lazyLoad ? e.$lazyInstance$ : o;
 let l;
 return t ? (BUILD.lazyLoad && BUILD.hostListener && (e.$flags$ |= 256, e.$queuedListeners$ && (e.$queuedListeners$.map((([e, t]) => safeCall(s, e, t))), 
 e.$queuedListeners$ = null)), emitLifecycleEvent(o, "componentWillLoad"), BUILD.cmpWillLoad && (l = safeCall(s, "componentWillLoad"))) : (emitLifecycleEvent(o, "componentWillUpdate"), 
 BUILD.cmpWillUpdate && (l = safeCall(s, "componentWillUpdate"))), emitLifecycleEvent(o, "componentWillRender"), 
 BUILD.cmpWillRender && (l = then(l, (() => safeCall(s, "componentWillRender")))), 
 n(), then(l, (() => updateComponent(e, s, t)));
}, updateComponent = async (e, t, o) => {
 const n = e.$hostElement$, s = createTime("update", e.$cmpMeta$.$tagName$), l = n["s-rc"];
 BUILD.style && o && attachStyles(e);
 const a = createTime("render", e.$cmpMeta$.$tagName$);
 if (BUILD.isDev && (e.$flags$ |= 1024), BUILD.hydrateServerSide ? await callRender(e, t, n) : callRender(e, t, n), 
 BUILD.cssVarShim && plt.$cssShim$ && plt.$cssShim$.updateHost(n), BUILD.isDev && (e.$renderCount$++, 
 e.$flags$ &= -1025), BUILD.hydrateServerSide) try {
  serverSideConnected(n), o && (1 & e.$cmpMeta$.$flags$ ? n["s-en"] = "" : 2 & e.$cmpMeta$.$flags$ && (n["s-en"] = "c"));
 } catch (e) {
  consoleError(e, n);
 }
 if (BUILD.asyncLoading && l && (l.map((e => e())), n["s-rc"] = void 0), a(), s(), 
 BUILD.asyncLoading) {
  const t = n["s-p"], o = () => postUpdateComponent(e);
  0 === t.length ? o() : (Promise.all(t).then(o), e.$flags$ |= 4, t.length = 0);
 } else postUpdateComponent(e);
};

let renderingRef = null;

const callRender = (e, t, o) => {
 const n = !!BUILD.allRenderFn, s = !!BUILD.lazyLoad, l = !!BUILD.taskQueue, a = !!BUILD.updatable;
 try {
  if (renderingRef = t, t = (n || t.render) && t.render(), a && l && (e.$flags$ &= -17), 
  (a || s) && (e.$flags$ |= 2), BUILD.hasRenderFn || BUILD.reflect) if (BUILD.vdomRender || BUILD.reflect) {
   if (BUILD.hydrateServerSide) return Promise.resolve(t).then((t => renderVdom(e, t)));
   renderVdom(e, t);
  } else o.textContent = t;
 } catch (t) {
  consoleError(t, e.$hostElement$);
 }
 return renderingRef = null, null;
}, getRenderingRef = () => renderingRef, postUpdateComponent = e => {
 const t = e.$cmpMeta$.$tagName$, o = e.$hostElement$, n = createTime("postUpdate", t), s = BUILD.lazyLoad ? e.$lazyInstance$ : o, l = e.$ancestorComponent$;
 BUILD.cmpDidRender && (BUILD.isDev && (e.$flags$ |= 1024), safeCall(s, "componentDidRender"), 
 BUILD.isDev && (e.$flags$ &= -1025)), emitLifecycleEvent(o, "componentDidRender"), 
 64 & e.$flags$ ? (BUILD.cmpDidUpdate && (BUILD.isDev && (e.$flags$ |= 1024), safeCall(s, "componentDidUpdate"), 
 BUILD.isDev && (e.$flags$ &= -1025)), emitLifecycleEvent(o, "componentDidUpdate"), 
 n()) : (e.$flags$ |= 64, BUILD.asyncLoading && BUILD.cssAnnotations && addHydratedFlag(o), 
 BUILD.cmpDidLoad && (BUILD.isDev && (e.$flags$ |= 2048), safeCall(s, "componentDidLoad"), 
 BUILD.isDev && (e.$flags$ &= -2049)), emitLifecycleEvent(o, "componentDidLoad"), 
 n(), BUILD.asyncLoading && (e.$onReadyResolve$(o), l || appDidLoad(t))), BUILD.hotModuleReplacement && o["s-hmr-load"] && o["s-hmr-load"](), 
 BUILD.method && BUILD.lazyLoad && e.$onInstanceResolve$(o), BUILD.asyncLoading && (e.$onRenderResolve$ && (e.$onRenderResolve$(), 
 e.$onRenderResolve$ = void 0), 512 & e.$flags$ && nextTick((() => scheduleUpdate(e, !1))), 
 e.$flags$ &= -517);
}, forceUpdate$1 = e => {
 if (BUILD.updatable) {
  const t = getHostRef(e), o = t.$hostElement$.isConnected;
  return o && 2 == (18 & t.$flags$) && scheduleUpdate(t, !1), o;
 }
 return !1;
}, appDidLoad = e => {
 BUILD.cssAnnotations && addHydratedFlag(doc.documentElement), BUILD.asyncQueue && (plt.$flags$ |= 2), 
 nextTick((() => emitEvent(win, "appload", {
  detail: {
   namespace: NAMESPACE
  }
 }))), BUILD.profile && performance.measure && performance.measure(`[Stencil] ${NAMESPACE} initial load (by ${e})`, "st:app:start");
}, safeCall = (e, t, o) => {
 if (e && e[t]) try {
  return e[t](o);
 } catch (e) {
  consoleError(e);
 }
}, then = (e, t) => e && e.then ? e.then(t) : t(), emitLifecycleEvent = (e, t) => {
 BUILD.lifecycleDOMEvents && emitEvent(e, "stencil_" + t, {
  bubbles: !0,
  composed: !0,
  detail: {
   namespace: NAMESPACE
  }
 });
}, addHydratedFlag = e => BUILD.hydratedClass ? e.classList.add("hydrated") : BUILD.hydratedAttribute ? e.setAttribute("hydrated", "") : void 0, serverSideConnected = e => {
 const t = e.children;
 if (null != t) for (let e = 0, o = t.length; e < o; e++) {
  const o = t[e];
  "function" == typeof o.connectedCallback && o.connectedCallback(), serverSideConnected(o);
 }
}, getValue = (e, t) => getHostRef(e).$instanceValues$.get(t), setValue = (e, t, o, n) => {
 const s = getHostRef(e), l = BUILD.lazyLoad ? s.$hostElement$ : e, a = s.$instanceValues$.get(t), r = s.$flags$, i = BUILD.lazyLoad ? s.$lazyInstance$ : l;
 o = parsePropertyValue(o, n.$members$[t][0]);
 const d = Number.isNaN(a) && Number.isNaN(o), c = o !== a && !d;
 if ((!BUILD.lazyLoad || !(8 & r) || void 0 === a) && c && (s.$instanceValues$.set(t, o), 
 BUILD.isDev && (1024 & s.$flags$ || s.$flags$), !BUILD.lazyLoad || i)) {
  if (BUILD.watchCallback && n.$watchers$ && 128 & r) {
   const e = n.$watchers$[t];
   e && e.map((e => {
    try {
     i[e](o, a, t);
    } catch (e) {
     consoleError(e, l);
    }
   }));
  }
  if (BUILD.updatable && 2 == (18 & r)) {
   if (BUILD.cmpShouldUpdate && i.componentShouldUpdate && !1 === i.componentShouldUpdate(o, a, t)) return;
   scheduleUpdate(s, !1);
  }
 }
}, proxyComponent = (e, t, o) => {
 if (BUILD.member && t.$members$) {
  BUILD.watchCallback && e.watchers && (t.$watchers$ = e.watchers);
  const n = Object.entries(t.$members$), s = e.prototype;
  if (n.map((([e, [n]]) => {
   (BUILD.prop || BUILD.state) && (31 & n || (!BUILD.lazyLoad || 2 & o) && 32 & n) ? Object.defineProperty(s, e, {
    get() {
     return getValue(this, e);
    },
    set(s) {
     if (BUILD.isDev) {
      const s = getHostRef(this);
      0 == (1 & o) && 0 == (8 & s.$flags$) && 0 != (31 & n) && 0 == (1024 & n) && consoleDevWarn(`@Prop() "${e}" on <${t.$tagName$}> is immutable but was modified from within the component.\nMore information: https://stenciljs.com/docs/properties#prop-mutability`);
     }
     setValue(this, e, s, t);
    },
    configurable: !0,
    enumerable: !0
   }) : BUILD.lazyLoad && BUILD.method && 1 & o && 64 & n && Object.defineProperty(s, e, {
    value(...t) {
     const o = getHostRef(this);
     return o.$onInstancePromise$.then((() => o.$lazyInstance$[e](...t)));
    }
   });
  })), BUILD.observeAttribute && (!BUILD.lazyLoad || 1 & o)) {
   const o = new Map;
   s.attributeChangedCallback = function(e, t, n) {
    plt.jmp((() => {
     const t = o.get(e);
     if (this.hasOwnProperty(t)) n = this[t], delete this[t]; else if (s.hasOwnProperty(t) && "number" == typeof this[t] && this[t] == n) return;
     this[t] = (null !== n || "boolean" != typeof this[t]) && n;
    }));
   }, e.observedAttributes = n.filter((([e, t]) => 15 & t[0])).map((([e, n]) => {
    const s = n[1] || e;
    return o.set(s, e), BUILD.reflect && 512 & n[0] && t.$attrsToReflect$.push([ e, s ]), 
    s;
   }));
  }
 }
 return e;
}, initializeComponent = async (e, t, o, n, s) => {
 if ((BUILD.lazyLoad || BUILD.hydrateServerSide || BUILD.style) && 0 == (32 & t.$flags$)) {
  if (BUILD.lazyLoad || BUILD.hydrateClientSide) {
   if (t.$flags$ |= 32, (s = loadModule(o)).then) {
    const e = (l = `st:load:${o.$tagName$}:${t.$modeName$}`, a = `[Stencil] Load module for <${o.$tagName$}>`, 
    BUILD.profile && performance.mark ? (0 === performance.getEntriesByName(l, "mark").length && performance.mark(l), 
    () => {
     0 === performance.getEntriesByName(a, "measure").length && performance.measure(a, l);
    }) : () => {});
    s = await s, e();
   }
   if ((BUILD.isDev || BUILD.isDebug) && !s) throw new Error(`Constructor for "${o.$tagName$}#${t.$modeName$}" was not found`);
   BUILD.member && !s.isProxied && (BUILD.watchCallback && (o.$watchers$ = s.watchers), 
   proxyComponent(s, o, 2), s.isProxied = !0);
   const e = createTime("createInstance", o.$tagName$);
   BUILD.member && (t.$flags$ |= 8);
   try {
    new s(t);
   } catch (e) {
    consoleError(e);
   }
   BUILD.member && (t.$flags$ &= -9), BUILD.watchCallback && (t.$flags$ |= 128), e(), 
   fireConnectedCallback(t.$lazyInstance$);
  } else s = e.constructor, t.$flags$ |= 32, customElements.whenDefined(o.$tagName$).then((() => t.$flags$ |= 128));
  if (BUILD.style && s.style) {
   let n = s.style;
   BUILD.mode && "string" != typeof n && (n = n[t.$modeName$ = computeMode(e)], BUILD.hydrateServerSide && t.$modeName$ && e.setAttribute("s-mode", t.$modeName$));
   const l = getScopeId(o, t.$modeName$);
   if (!styles.has(l)) {
    const e = createTime("registerStyles", o.$tagName$);
    !BUILD.hydrateServerSide && BUILD.shadowDom && BUILD.shadowDomShim && 8 & o.$flags$ && (n = await import("./shadow-css.js").then((e => e.scopeCss(n, l, !1)))), 
    registerStyle(l, n, o.$flags$), e();
   }
  }
 }
 var l, a;
 const r = t.$ancestorComponent$, i = () => scheduleUpdate(t, !0);
 BUILD.asyncLoading && r && r["s-rc"] ? r["s-rc"].push(i) : i();
}, fireConnectedCallback = e => {
 BUILD.lazyLoad && BUILD.connectedCallback && safeCall(e, "connectedCallback");
}, connectedCallback = e => {
 if (0 == (1 & plt.$flags$)) {
  const t = getHostRef(e), o = t.$cmpMeta$, n = createTime("connectedCallback", o.$tagName$);
  if (BUILD.hostListenerTargetParent && addHostEventListeners(e, t, o.$listeners$, !0), 
  1 & t.$flags$) addHostEventListeners(e, t, o.$listeners$, !1), fireConnectedCallback(t.$lazyInstance$); else {
   let n;
   if (t.$flags$ |= 1, BUILD.hydrateClientSide && (n = e.getAttribute("s-id"), n)) {
    if (BUILD.shadowDom && supportsShadow && 1 & o.$flags$) {
     const t = BUILD.mode ? addStyle(e.shadowRoot, o, e.getAttribute("s-mode")) : addStyle(e.shadowRoot, o);
     e.classList.remove(t + "-h", t + "-s");
    }
    ((e, t, o, n) => {
     const s = createTime("hydrateClient", t), l = e.shadowRoot, a = [], r = BUILD.shadowDom && l ? [] : null, i = n.$vnode$ = newVNode(t, null);
     plt.$orgLocNodes$ || initializeDocumentHydrate(doc.body, plt.$orgLocNodes$ = new Map), 
     e["s-id"] = o, e.removeAttribute("s-id"), clientHydrate(i, a, [], r, e, e, o), a.map((e => {
      const o = e.$hostId$ + "." + e.$nodeId$, n = plt.$orgLocNodes$.get(o), s = e.$elm$;
      n && supportsShadow && "" === n["s-en"] && n.parentNode.insertBefore(s, n.nextSibling), 
      l || (s["s-hn"] = t, n && (s["s-ol"] = n, s["s-ol"]["s-nr"] = s)), plt.$orgLocNodes$.delete(o);
     })), BUILD.shadowDom && l && r.map((e => {
      e && l.appendChild(e);
     })), s();
    })(e, o.$tagName$, n, t);
   }
   if (BUILD.slotRelocation && !n && (BUILD.hydrateServerSide || (BUILD.slot || BUILD.shadowDom) && 12 & o.$flags$) && setContentReference(e), 
   BUILD.asyncLoading) {
    let o = e;
    for (;o = o.parentNode || o.host; ) if (BUILD.hydrateClientSide && 1 === o.nodeType && o.hasAttribute("s-id") && o["s-p"] || o["s-p"]) {
     attachToAncestor(t, t.$ancestorComponent$ = o);
     break;
    }
   }
   BUILD.prop && !BUILD.hydrateServerSide && o.$members$ && Object.entries(o.$members$).map((([t, [o]]) => {
    if (31 & o && e.hasOwnProperty(t)) {
     const o = e[t];
     delete e[t], e[t] = o;
    }
   })), BUILD.initializeNextTick ? nextTick((() => initializeComponent(e, t, o))) : initializeComponent(e, t, o);
  }
  n();
 }
}, setContentReference = e => {
 const t = e["s-cr"] = doc.createComment(BUILD.isDebug ? `content-ref (host=${e.localName})` : "");
 t["s-cn"] = !0, e.insertBefore(t, e.firstChild);
}, disconnectedCallback = e => {
 if (0 == (1 & plt.$flags$)) {
  const t = getHostRef(e), o = BUILD.lazyLoad ? t.$lazyInstance$ : e;
  BUILD.hostListener && t.$rmListeners$ && (t.$rmListeners$.map((e => e())), t.$rmListeners$ = void 0), 
  BUILD.cssVarShim && plt.$cssShim$ && plt.$cssShim$.removeHost(e), BUILD.lazyLoad && BUILD.disconnectedCallback && safeCall(o, "disconnectedCallback"), 
  BUILD.cmpDidUnload && safeCall(o, "componentDidUnload");
 }
}, defineCustomElement = (e, t) => {
 customElements.define(t[1], proxyCustomElement(e, t));
}, proxyCustomElement = (e, t) => {
 const o = {
  $flags$: t[0],
  $tagName$: t[1]
 };
 BUILD.member && (o.$members$ = t[2]), BUILD.hostListener && (o.$listeners$ = t[3]), 
 BUILD.watchCallback && (o.$watchers$ = e.$watchers$), BUILD.reflect && (o.$attrsToReflect$ = []), 
 BUILD.shadowDom && !supportsShadow && 1 & o.$flags$ && (o.$flags$ |= 8);
 const n = e.prototype.connectedCallback, s = e.prototype.disconnectedCallback;
 return Object.assign(e.prototype, {
  __registerHost() {
   registerHost(this, o);
  },
  connectedCallback() {
   connectedCallback(this), BUILD.connectedCallback && n && n.call(this);
  },
  disconnectedCallback() {
   disconnectedCallback(this), BUILD.disconnectedCallback && s && s.call(this);
  },
  __attachShadow() {
   this.shadowRoot = this;
  }
 }), e.is = o.$tagName$, proxyComponent(e, o, 3);
}, forceModeUpdate = e => {
 if (BUILD.style && BUILD.mode && !BUILD.lazyLoad) {
  const t = computeMode(e), o = getHostRef(e);
  if (o.$modeName$ !== t) {
   const n = o.$cmpMeta$, s = e["s-sc"], l = getScopeId(n, t), a = e.constructor.style[t];
   n.$flags$, a && (styles.has(l) || registerStyle(l, a), o.$modeName$ = t, e.classList.remove(s + "-h", s + "-s"), 
   attachStyles(o), forceUpdate$1(e));
  }
 }
}, patchCloneNode = e => {
 const t = e.cloneNode;
 e.cloneNode = function(e) {
  const o = this, n = !!BUILD.shadowDom && o.shadowRoot && supportsShadow, s = t.call(o, !!n && e);
  if (BUILD.slot && !n && e) {
   let e, t, n = 0;
   const l = [ "s-id", "s-cr", "s-lr", "s-rc", "s-sc", "s-p", "s-cn", "s-sr", "s-sn", "s-hn", "s-ol", "s-nr", "s-si" ];
   for (;n < o.childNodes.length; n++) e = o.childNodes[n]["s-nr"], t = l.every((e => !o.childNodes[n][e])), 
   e && (BUILD.appendChildSlotFix && s.__appendChild ? s.__appendChild(e.cloneNode(!0)) : s.appendChild(e.cloneNode(!0))), 
   t && s.appendChild(o.childNodes[n].cloneNode(!0));
  }
  return s;
 };
}, patchSlotAppendChild = e => {
 e.__appendChild = e.appendChild, e.appendChild = function(e) {
  const t = e["s-sn"] = getSlotName(e), o = getHostSlotNode(this.childNodes, t);
  if (o) {
   const n = getHostSlotChildNodes(o, t), s = n[n.length - 1];
   return s.parentNode.insertBefore(e, s.nextSibling);
  }
  return this.__appendChild(e);
 };
}, patchTextContent = (e, t) => {
 if (BUILD.scoped && 2 & t.$flags$) {
  const t = Object.getOwnPropertyDescriptor(Node.prototype, "textContent");
  Object.defineProperty(e, "__textContent", t), Object.defineProperty(e, "textContent", {
   get() {
    var e;
    const t = getHostSlotNode(this.childNodes, "");
    return 3 === (null === (e = null == t ? void 0 : t.nextSibling) || void 0 === e ? void 0 : e.nodeType) ? t.nextSibling.textContent : t ? t.textContent : this.__textContent;
   },
   set(e) {
    var t;
    const o = getHostSlotNode(this.childNodes, "");
    if (3 === (null === (t = null == o ? void 0 : o.nextSibling) || void 0 === t ? void 0 : t.nodeType)) o.nextSibling.textContent = e; else if (o) o.textContent = e; else {
     this.__textContent = e;
     const t = this["s-cr"];
     t && this.insertBefore(t, this.firstChild);
    }
   }
  });
 }
}, patchChildSlotNodes = (e, t) => {
 class o extends Array {
  item(e) {
   return this[e];
  }
 }
 if (8 & t.$flags$) {
  const t = e.__lookupGetter__("childNodes");
  Object.defineProperty(e, "children", {
   get() {
    return this.childNodes.map((e => 1 === e.nodeType));
   }
  }), Object.defineProperty(e, "childElementCount", {
   get: () => e.children.length
  }), Object.defineProperty(e, "childNodes", {
   get() {
    const e = t.call(this);
    if (0 == (1 & plt.$flags$) && 2 & getHostRef(this).$flags$) {
     const t = new o;
     for (let o = 0; o < e.length; o++) {
      const n = e[o]["s-nr"];
      n && t.push(n);
     }
     return t;
    }
    return o.from(e);
   }
  });
 }
}, getSlotName = e => e["s-sn"] || 1 === e.nodeType && e.getAttribute("slot") || "", getHostSlotNode = (e, t) => {
 let o, n = 0;
 for (;n < e.length; n++) {
  if (o = e[n], o["s-sr"] && o["s-sn"] === t) return o;
  if (o = getHostSlotNode(o.childNodes, t), o) return o;
 }
 return null;
}, getHostSlotChildNodes = (e, t) => {
 const o = [ e ];
 for (;(e = e.nextSibling) && e["s-sn"] === t; ) o.push(e);
 return o;
}, bootstrapLazy = (e, t = {}) => {
 var o;
 BUILD.profile && performance.mark && performance.mark("st:app:start"), (() => {
  if (BUILD.devTools) {
   const e = win.stencil = win.stencil || {}, t = e.inspect;
   e.inspect = e => {
    let o = (e => {
     const t = getHostRef(e);
     if (!t) return;
     const o = t.$flags$, n = t.$hostElement$;
     return {
      renderCount: t.$renderCount$,
      flags: {
       hasRendered: !!(2 & o),
       hasConnected: !!(1 & o),
       isWaitingForChildren: !!(4 & o),
       isConstructingInstance: !!(8 & o),
       isQueuedForUpdate: !!(16 & o),
       hasInitializedComponent: !!(32 & o),
       hasLoadedComponent: !!(64 & o),
       isWatchReady: !!(128 & o),
       isListenReady: !!(256 & o),
       needsRerender: !!(512 & o)
      },
      instanceValues: t.$instanceValues$,
      ancestorComponent: t.$ancestorComponent$,
      hostElement: n,
      lazyInstance: t.$lazyInstance$,
      vnode: t.$vnode$,
      modeName: t.$modeName$,
      onReadyPromise: t.$onReadyPromise$,
      onReadyResolve: t.$onReadyResolve$,
      onInstancePromise: t.$onInstancePromise$,
      onInstanceResolve: t.$onInstanceResolve$,
      onRenderResolve: t.$onRenderResolve$,
      queuedListeners: t.$queuedListeners$,
      rmListeners: t.$rmListeners$,
      "s-id": n["s-id"],
      "s-cr": n["s-cr"],
      "s-lr": n["s-lr"],
      "s-p": n["s-p"],
      "s-rc": n["s-rc"],
      "s-sc": n["s-sc"]
     };
    })(e);
    return o || "function" != typeof t || (o = t(e)), o;
   };
  }
 })();
 const n = createTime("bootstrapLazy"), s = [], l = t.exclude || [], a = win.customElements, r = doc.head, i = r.querySelector("meta[charset]"), d = doc.createElement("style"), c = [], $ = doc.querySelectorAll("[sty-id]");
 let m, p = !0, h = 0;
 if (Object.assign(plt, t), plt.$resourcesUrl$ = new URL(t.resourcesUrl || "./", doc.baseURI).href, 
 BUILD.asyncQueue && t.syncQueue && (plt.$flags$ |= 4), BUILD.hydrateClientSide && (plt.$flags$ |= 2), 
 BUILD.hydrateClientSide && BUILD.shadowDom) for (;h < $.length; h++) registerStyle($[h].getAttribute("sty-id"), $[h].innerHTML.replace(/\/\*!@([^\/]+)\*\/[^\{]+\{/g, "$1{"));
 if (e.map((e => {
  e[1].map((o => {
   const n = {
    $flags$: o[0],
    $tagName$: o[1],
    $members$: o[2],
    $listeners$: o[3]
   };
   BUILD.member && (n.$members$ = o[2]), BUILD.hostListener && (n.$listeners$ = o[3]), 
   BUILD.reflect && (n.$attrsToReflect$ = []), BUILD.watchCallback && (n.$watchers$ = {}), 
   BUILD.shadowDom && !supportsShadow && 1 & n.$flags$ && (n.$flags$ |= 8);
   const r = BUILD.transformTagName && t.transformTagName ? t.transformTagName(n.$tagName$) : n.$tagName$, i = class extends HTMLElement {
    constructor(e) {
     super(e), registerHost(e = this, n), BUILD.shadowDom && 1 & n.$flags$ && (BUILD.hydrateServerSide || "shadowRoot" in e || (e.shadowRoot = e)), 
     BUILD.slotChildNodesFix && patchChildSlotNodes(e, n);
    }
    connectedCallback() {
     m && (clearTimeout(m), m = null), p ? c.push(this) : plt.jmp((() => connectedCallback(this)));
    }
    disconnectedCallback() {
     plt.jmp((() => disconnectedCallback(this)));
    }
    componentOnReady() {
     return getHostRef(this).$onReadyPromise$;
    }
   };
   BUILD.cloneNodeFix && patchCloneNode(i.prototype), BUILD.appendChildSlotFix && patchSlotAppendChild(i.prototype), 
   BUILD.hotModuleReplacement && (i.prototype["s-hmr"] = function(e) {
    ((e, t, o) => {
     const n = getHostRef(e);
     n.$flags$ = 1, e["s-hmr-load"] = () => {
      delete e["s-hmr-load"];
     }, initializeComponent(e, n, t);
    })(this, n);
   }), BUILD.scopedSlotTextContentFix && patchTextContent(i.prototype, n), n.$lazyBundleId$ = e[0], 
   l.includes(r) || a.get(r) || (s.push(r), a.define(r, proxyComponent(i, n, 1)));
  }));
 })), BUILD.invisiblePrehydration && (BUILD.hydratedClass || BUILD.hydratedAttribute)) {
  d.innerHTML = s + "{visibility:hidden}.hydrated{visibility:inherit}", d.setAttribute("data-styles", "");
  const e = null !== (o = plt.$nonce$) && void 0 !== o ? o : queryNonceMetaTagContent(doc);
  null != e && d.setAttribute("nonce", e), r.insertBefore(d, i ? i.nextSibling : r.firstChild);
 }
 p = !1, c.length ? c.map((e => e.connectedCallback())) : BUILD.profile ? plt.jmp((() => m = setTimeout(appDidLoad, 30, "timeout"))) : plt.jmp((() => m = setTimeout(appDidLoad, 30))), 
 n();
}, getConnect = (e, t) => {
 const o = () => {
  let e = doc.querySelector(t);
  return e || (e = doc.createElement(t), doc.body.appendChild(e)), "function" == typeof e.componentOnReady ? e.componentOnReady() : Promise.resolve(e);
 };
 return {
  create: (...e) => o().then((t => t.create(...e))),
  componentOnReady: o
 };
}, getContext = (e, t) => t in Context ? Context[t] : "window" === t ? win : "document" === t ? doc : "isServer" === t || "isPrerender" === t ? !!BUILD.hydrateServerSide : "isClient" === t ? !BUILD.hydrateServerSide : "resourcesUrl" === t || "publicPath" === t ? getAssetPath(".") : "queue" === t ? {
 write: writeTask,
 read: readTask,
 tick: {
  then: e => nextTick(e)
 }
} : void 0, Fragment = (e, t) => t, addHostEventListeners = (e, t, o, n) => {
 BUILD.hostListener && o && (BUILD.hostListenerTargetParent && (o = n ? o.filter((([e]) => 32 & e)) : o.filter((([e]) => !(32 & e)))), 
 o.map((([o, n, s]) => {
  const l = BUILD.hostListenerTarget ? getHostListenerTarget(e, o) : e, a = hostListenerProxy(t, s), r = hostListenerOpts(o);
  plt.ael(l, n, a, r), (t.$rmListeners$ = t.$rmListeners$ || []).push((() => plt.rel(l, n, a, r)));
 })));
}, hostListenerProxy = (e, t) => o => {
 try {
  BUILD.lazyLoad ? 256 & e.$flags$ ? e.$lazyInstance$[t](o) : (e.$queuedListeners$ = e.$queuedListeners$ || []).push([ t, o ]) : e.$hostElement$[t](o);
 } catch (e) {
  consoleError(e);
 }
}, getHostListenerTarget = (e, t) => BUILD.hostListenerTargetDocument && 4 & t ? doc : BUILD.hostListenerTargetWindow && 8 & t ? win : BUILD.hostListenerTargetBody && 16 & t ? doc.body : BUILD.hostListenerTargetParent && 32 & t ? e.parentElement : e, hostListenerOpts = e => 0 != (2 & e), setNonce = e => plt.$nonce$ = e, insertVdomAnnotations = (e, t) => {
 if (null != e) {
  const o = {
   hostIds: 0,
   rootLevelIds: 0,
   staticComponents: new Set(t)
  }, n = [];
  parseVNodeAnnotations(e, e.body, o, n), n.forEach((t => {
   if (null != t) {
    const n = t["s-nr"];
    let s = n["s-host-id"], l = n["s-node-id"], a = `${s}.${l}`;
    if (null == s) if (s = 0, o.rootLevelIds++, l = o.rootLevelIds, a = `${s}.${l}`, 
    1 === n.nodeType) n.setAttribute("c-id", a); else if (3 === n.nodeType) {
     if (0 === s && "" === n.nodeValue.trim()) return void t.remove();
     const o = e.createComment(a);
     o.nodeValue = `t.${a}`, n.parentNode.insertBefore(o, n);
    }
    let r = `o.${a}`;
    const i = t.parentElement;
    i && ("" === i["s-en"] ? r += "." : "c" === i["s-en"] && (r += ".c")), t.nodeValue = r;
   }
  }));
 }
}, parseVNodeAnnotations = (e, t, o, n) => {
 null != t && (null != t["s-nr"] && n.push(t), 1 === t.nodeType && t.childNodes.forEach((t => {
  const s = getHostRef(t);
  if (null != s && !o.staticComponents.has(t.nodeName.toLowerCase())) {
   const n = {
    nodeIds: 0
   };
   insertVNodeAnnotations(e, t, s.$vnode$, o, n);
  }
  parseVNodeAnnotations(e, t, o, n);
 })));
}, insertVNodeAnnotations = (e, t, o, n, s) => {
 if (null != o) {
  const l = ++n.hostIds;
  if (t.setAttribute("s-id", l), null != t["s-cr"] && (t["s-cr"].nodeValue = `r.${l}`), 
  null != o.$children$) {
   const t = 0;
   o.$children$.forEach(((o, n) => {
    insertChildVNodeAnnotations(e, o, s, l, t, n);
   }));
  }
  if (t && o && o.$elm$ && !t.hasAttribute("c-id")) {
   const e = t.parentElement;
   if (e && e.childNodes) {
    const n = Array.from(e.childNodes), s = n.find((e => 8 === e.nodeType && e["s-sr"]));
    if (s) {
     const e = n.indexOf(t) - 1;
     o.$elm$.setAttribute("c-id", `${s["s-host-id"]}.${s["s-node-id"]}.0.${e}`);
    }
   }
  }
 }
}, insertChildVNodeAnnotations = (e, t, o, n, s, l) => {
 const a = t.$elm$;
 if (null == a) return;
 const r = o.nodeIds++, i = `${n}.${r}.${s}.${l}`;
 if (a["s-host-id"] = n, a["s-node-id"] = r, 1 === a.nodeType) a.setAttribute("c-id", i); else if (3 === a.nodeType) {
  const t = a.parentNode, o = t.nodeName;
  if ("STYLE" !== o && "SCRIPT" !== o) {
   const o = `t.${i}`, n = e.createComment(o);
   t.insertBefore(n, a);
  }
 } else if (8 === a.nodeType && a["s-sr"]) {
  const e = `s.${i}.${a["s-sn"] || ""}`;
  a.nodeValue = e;
 }
 if (null != t.$children$) {
  const l = s + 1;
  t.$children$.forEach(((t, s) => {
   insertChildVNodeAnnotations(e, t, o, n, l, s);
  }));
 }
}, hAsync = (e, t, ...o) => {
 if (Array.isArray(o) && o.length > 0) {
  const n = o.flat(1 / 0);
  return n.some(isPromise) ? Promise.all(n).then((o => h(e, t, ...o))).catch((o => h(e, t))) : h(e, t, ...o);
 }
 return h(e, t);
}, NO_HYDRATE_TAGS = new Set([ "CODE", "HEAD", "IFRAME", "INPUT", "OBJECT", "OUTPUT", "NOSCRIPT", "PRE", "SCRIPT", "SELECT", "STYLE", "TEMPLATE", "TEXTAREA" ]);

let customError;

const cmpModules = new Map, getModule = e => {
 if ("string" == typeof e) {
  e = e.toLowerCase();
  const t = cmpModules.get(e);
  if (null != t) return t[e];
 }
 return null;
}, loadModule = (e, t, o) => getModule(e.$tagName$), isMemberInElement = (e, t) => {
 if (null != e) {
  if (t in e) return !0;
  const o = getModule(e.nodeName);
  if (null != o) {
   const e = o;
   if (null != e && null != e.cmpMeta && null != e.cmpMeta.$members$) return t in e.cmpMeta.$members$;
  }
 }
 return !1;
}, registerComponents = e => {
 for (const t of e) {
  const e = t.cmpMeta.$tagName$;
  cmpModules.set(e, {
   [e]: t
  });
 }
}, win = window, doc = win.document, readTask = e => {
 process.nextTick((() => {
  try {
   e();
  } catch (e) {
   consoleError(e);
  }
 }));
}, writeTask = e => {
 process.nextTick((() => {
  try {
   e();
  } catch (e) {
   consoleError(e);
  }
 }));
}, resolved = Promise.resolve(), nextTick = e => resolved.then(e), defaultConsoleError = e => {
 null != e && console.error(e.stack || e.message || e);
}, consoleError = (e, t) => (customError || defaultConsoleError)(e, t), consoleDevError = (...e) => {}, consoleDevWarn = (...e) => {}, consoleDevInfo = (...e) => {}, setErrorHandler = e => customError = e, Context = {}, plt = {
 $flags$: 0,
 $resourcesUrl$: "",
 jmp: e => e(),
 raf: e => requestAnimationFrame(e),
 ael: (e, t, o, n) => e.addEventListener(t, o, n),
 rel: (e, t, o, n) => e.removeEventListener(t, o, n),
 ce: (e, t) => new win.CustomEvent(e, t)
}, setPlatformHelpers = e => {
 Object.assign(plt, e);
}, supportsShadow = !1, supportsListenerOptions = !1, supportsConstructableStylesheets = !1, hostRefs = new WeakMap, getHostRef = e => hostRefs.get(e), registerInstance = (e, t) => hostRefs.set(t.$lazyInstance$ = e, t), registerHost = (e, t) => {
 const o = {
  $flags$: 0,
  $cmpMeta$: t,
  $hostElement$: e,
  $instanceValues$: new Map,
  $renderCount$: 0
 };
 return o.$onInstancePromise$ = new Promise((e => o.$onInstanceResolve$ = e)), o.$onReadyPromise$ = new Promise((e => o.$onReadyResolve$ = e)), 
 e["s-p"] = [], e["s-rc"] = [], addHostEventListeners(e, o, t.$listeners$, !1), hostRefs.set(e, o);
}, Build = {
 isDev: !1,
 isBrowser: !1,
 isServer: !0,
 isTesting: !1
}, styles = new Map, modeResolutionChain = [];

export { Build, Context, Fragment, Host, addHostEventListeners, bootstrapLazy, cmpModules, connectedCallback, consoleDevError, consoleDevInfo, consoleDevWarn, consoleError, createEvent, defineCustomElement, disconnectedCallback, doc, forceModeUpdate, forceUpdate$1 as forceUpdate, getAssetPath, getConnect, getContext, getElement, getHostRef, getMode, getRenderingRef, getValue, hAsync as h, hydrateApp, insertVdomAnnotations, isMemberInElement, loadModule, modeResolutionChain, nextTick, parsePropertyValue, plt, postUpdateComponent, proxyComponent, proxyCustomElement, readTask, registerComponents, registerHost, registerInstance, renderVdom, setAssetPath, setErrorHandler, setMode, setNonce, setPlatformHelpers, setValue, styles, supportsConstructableStylesheets, supportsListenerOptions, supportsShadow, win, writeTask };