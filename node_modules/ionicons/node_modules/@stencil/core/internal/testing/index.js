function queryNonceMetaTagContent(e) {
 var t, a, o;
 return null !== (o = null === (a = null === (t = e.head) || void 0 === t ? void 0 : t.querySelector('meta[name="csp-nonce"]')) || void 0 === a ? void 0 : a.getAttribute("content")) && void 0 !== o ? o : void 0;
}

function writeTask(e) {
 queuedWriteTasks.push(e);
}

function readTask(e) {
 queuedReadTasks.push(e);
}

function flushQueue() {
 return new Promise(((e, t) => {
  process.nextTick((async function a() {
   try {
    if (queuedReadTasks.length > 0) {
     const e = queuedReadTasks.slice();
     let t;
     for (queuedReadTasks.length = 0; t = e.shift(); ) {
      const e = t(Date.now());
      null != e && "function" == typeof e.then && await e;
     }
    }
    if (queuedWriteTasks.length > 0) {
     const e = queuedWriteTasks.slice();
     let t;
     for (queuedWriteTasks.length = 0; t = e.shift(); ) {
      const e = t(Date.now());
      null != e && "function" == typeof e.then && await e;
     }
    }
    queuedReadTasks.length + queuedWriteTasks.length > 0 ? process.nextTick(a) : e();
   } catch (e) {
    t(`flushQueue: ${e}`);
   }
  }));
 }));
}

async function flushAll() {
 for (;queuedTicks.length + queuedLoadModules.length + queuedWriteTasks.length + queuedReadTasks.length > 0; ) await new Promise(((e, t) => {
  process.nextTick((function a() {
   try {
    if (queuedTicks.length > 0) {
     const e = queuedTicks.slice();
     let t;
     for (queuedTicks.length = 0; t = e.shift(); ) t(Date.now());
    }
    queuedTicks.length > 0 ? process.nextTick(a) : e();
   } catch (e) {
    t(`flushTicks: ${e}`);
   }
  }));
 })), await flushLoadModule(), await flushQueue();
 if (caughtErrors.length > 0) {
  const e = caughtErrors[0];
  if (null == e) throw new Error("Error!");
  if ("string" == typeof e) throw new Error(e);
  throw e;
 }
 return new Promise((e => process.nextTick(e)));
}

function loadModule(e, t, a) {
 return new Promise((t => {
  queuedLoadModules.push({
   bundleId: e.$lazyBundleId$,
   resolve: () => t(moduleLoaded.get(e.$lazyBundleId$))
  });
 }));
}

function flushLoadModule(e) {
 return new Promise(((t, a) => {
  try {
   process.nextTick((() => {
    if (null != e) for (let t = 0; t < queuedLoadModules.length; t++) queuedLoadModules[t].bundleId === e && (queuedLoadModules[t].resolve(), 
    queuedLoadModules.splice(t, 1), t--); else {
     let e;
     for (;e = queuedLoadModules.shift(); ) e.resolve();
    }
    t();
   }));
  } catch (e) {
   a(`flushLoadModule: ${e}`);
  }
 }));
}

function stopAutoApplyChanges() {
 isAutoApplyingChanges = !1, autoApplyTimer && (clearTimeout(autoApplyTimer), autoApplyTimer = void 0);
}

const mockDoc = require("@stencil/core/mock-doc"), appData = require("@stencil/core/internal/app-data"), styles = new Map, modeResolutionChain = [], cstrs = new Map, queuedTicks = [], queuedWriteTasks = [], queuedReadTasks = [], moduleLoaded = new Map, queuedLoadModules = [], caughtErrors = [], hostRefs = new Map, getAssetPath = e => {
 const t = new URL(e, plt.$resourcesUrl$);
 return t.origin !== win.location.origin ? t.href : t.pathname;
};

let i = 0;

const createTime = (e, t = "") => {
 if (appData.BUILD.profile && performance.mark) {
  const a = `st:${e}:${t}:${i++}`;
  return performance.mark(a), () => performance.measure(`[Stencil] ${e}() <${t}>`, a);
 }
 return () => {};
}, XLINK_NS = "http://www.w3.org/1999/xlink", EMPTY_OBJ = {}, isComplexType = e => "object" == (e = typeof e) || "function" === e, h = (e, t, ...a) => {
 let o = null, s = null, n = null, l = !1, r = !1;
 const p = [], i = t => {
  for (let a = 0; a < t.length; a++) o = t[a], Array.isArray(o) ? i(o) : null != o && "boolean" != typeof o && ((l = "function" != typeof e && !isComplexType(o)) ? o = String(o) : appData.BUILD.isDev && "function" != typeof e && void 0 === o.$flags$ && consoleDevError("vNode passed as children has unexpected type.\nMake sure it's using the correct h() function.\nEmpty objects can also be the cause, look for JSX comments that became objects."), 
  l && r ? p[p.length - 1].$text$ += o : p.push(l ? newVNode(null, o) : o), r = l);
 };
 if (i(a), t && (appData.BUILD.isDev && "input" === e && validateInputProperties(t), 
 appData.BUILD.vdomKey && t.key && (s = t.key), appData.BUILD.slotRelocation && t.name && (n = t.name), 
 appData.BUILD.vdomClass)) {
  const e = t.className || t.class;
  e && (t.class = "object" != typeof e ? e : Object.keys(e).filter((t => e[t])).join(" "));
 }
 if (appData.BUILD.isDev && p.some(isHost) && consoleDevError("The <Host> must be the single root component. Make sure:\n- You are NOT using hostData() and <Host> in the same component.\n- <Host> is used once, and it's the single root component of the render() function."), 
 appData.BUILD.vdomFunctional && "function" == typeof e) return e(null === t ? {} : t, p, vdomFnUtils);
 const d = newVNode(e, null);
 return d.$attrs$ = t, p.length > 0 && (d.$children$ = p), appData.BUILD.vdomKey && (d.$key$ = s), 
 appData.BUILD.slotRelocation && (d.$name$ = n), d;
}, newVNode = (e, t) => {
 const a = {
  $flags$: 0,
  $tag$: e,
  $text$: t,
  $elm$: null,
  $children$: null
 };
 return appData.BUILD.vdomAttribute && (a.$attrs$ = null), appData.BUILD.vdomKey && (a.$key$ = null), 
 appData.BUILD.slotRelocation && (a.$name$ = null), a;
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
 const t = Object.keys(e), a = t.indexOf("value");
 if (-1 === a) return;
 const o = t.indexOf("type"), s = t.indexOf("min"), n = t.indexOf("max"), l = t.indexOf("step");
 (a < o || a < s || a < n || a < l) && consoleDevWarn('The "value" prop of <input> should be set after "min", "max", "type" and "step"');
}, clientHydrate = (e, t, a, o, s, n, l) => {
 let r, p, i, d;
 if (1 === n.nodeType) {
  for (r = n.getAttribute("c-id"), r && (p = r.split("."), p[0] !== l && "0" !== p[0] || (i = {
   $flags$: 0,
   $hostId$: p[0],
   $nodeId$: p[1],
   $depth$: p[2],
   $index$: p[3],
   $tag$: n.tagName.toLowerCase(),
   $elm$: n,
   $attrs$: null,
   $children$: null,
   $key$: null,
   $name$: null,
   $text$: null
  }, t.push(i), n.removeAttribute("c-id"), e.$children$ || (e.$children$ = []), e.$children$[i.$index$] = i, 
  e = i, o && "0" === i.$depth$ && (o[i.$index$] = i.$elm$))), d = n.childNodes.length - 1; d >= 0; d--) clientHydrate(e, t, a, o, s, n.childNodes[d], l);
  if (n.shadowRoot) for (d = n.shadowRoot.childNodes.length - 1; d >= 0; d--) clientHydrate(e, t, a, o, s, n.shadowRoot.childNodes[d], l);
 } else if (8 === n.nodeType) p = n.nodeValue.split("."), p[1] !== l && "0" !== p[1] || (r = p[0], 
 i = {
  $flags$: 0,
  $hostId$: p[1],
  $nodeId$: p[2],
  $depth$: p[3],
  $index$: p[4],
  $elm$: n,
  $attrs$: null,
  $children$: null,
  $key$: null,
  $name$: null,
  $tag$: null,
  $text$: null
 }, "t" === r ? (i.$elm$ = n.nextSibling, i.$elm$ && 3 === i.$elm$.nodeType && (i.$text$ = i.$elm$.textContent, 
 t.push(i), n.remove(), e.$children$ || (e.$children$ = []), e.$children$[i.$index$] = i, 
 o && "0" === i.$depth$ && (o[i.$index$] = i.$elm$))) : i.$hostId$ === l && ("s" === r ? (i.$tag$ = "slot", 
 p[5] ? n["s-sn"] = i.$name$ = p[5] : n["s-sn"] = "", n["s-sr"] = !0, appData.BUILD.shadowDom && o && (i.$elm$ = doc.createElement(i.$tag$), 
 i.$name$ && i.$elm$.setAttribute("name", i.$name$), n.parentNode.insertBefore(i.$elm$, n), 
 n.remove(), "0" === i.$depth$ && (o[i.$index$] = i.$elm$)), a.push(i), e.$children$ || (e.$children$ = []), 
 e.$children$[i.$index$] = i) : "r" === r && (appData.BUILD.shadowDom && o ? n.remove() : appData.BUILD.slotRelocation && (s["s-cr"] = n, 
 n["s-cn"] = !0)))); else if (e && "style" === e.$tag$) {
  const t = newVNode(null, n.textContent);
  t.$elm$ = n, t.$index$ = "0", e.$children$ = [ t ];
 }
}, initializeDocumentHydrate = (e, t) => {
 if (1 === e.nodeType) {
  let a = 0;
  for (;a < e.childNodes.length; a++) initializeDocumentHydrate(e.childNodes[a], t);
  if (e.shadowRoot) for (a = 0; a < e.shadowRoot.childNodes.length; a++) initializeDocumentHydrate(e.shadowRoot.childNodes[a], t);
 } else if (8 === e.nodeType) {
  const a = e.nodeValue.split(".");
  "o" === a[0] && (t.set(a[1] + "." + a[2], e), e.nodeValue = "", e["s-en"] = a[3]);
 }
}, computeMode = e => modeResolutionChain.map((t => t(e))).find((e => !!e)), parsePropertyValue = (e, t) => null == e || isComplexType(e) ? e : appData.BUILD.propBoolean && 4 & t ? "false" !== e && ("" === e || !!e) : appData.BUILD.propNumber && 2 & t ? parseFloat(e) : appData.BUILD.propString && 1 & t ? String(e) : e, getElement = e => appData.BUILD.lazyLoad ? getHostRef(e).$hostElement$ : e, emitEvent = (e, t, a) => {
 const o = plt.ce(t, a);
 return e.dispatchEvent(o), o;
}, rootAppliedStyles = new WeakMap, registerStyle = (e, t, a) => {
 let o = styles.get(e);
 o = t, styles.set(e, o);
}, addStyle = (e, t, a, o) => {
 var s;
 let n = getScopeId(t, a);
 const l = styles.get(n);
 if (!appData.BUILD.attachStyles) return n;
 if (e = 11 === e.nodeType ? e : doc, l) if ("string" == typeof l) {
  e = e.head || e;
  let a, r = rootAppliedStyles.get(e);
  if (r || rootAppliedStyles.set(e, r = new Set), !r.has(n)) {
   if (appData.BUILD.hydrateClientSide && e.host && (a = e.querySelector(`[sty-id="${n}"]`))) a.innerHTML = l; else {
    if (appData.BUILD.cssVarShim && plt.$cssShim$) {
     a = plt.$cssShim$.createHostStyle(o, n, l, !!(10 & t.$flags$));
     const e = a["s-sc"];
     e && (n = e, r = null);
    } else a = doc.createElement("style"), a.innerHTML = l;
    const p = null !== (s = plt.$nonce$) && void 0 !== s ? s : queryNonceMetaTagContent(doc);
    null != p && a.setAttribute("nonce", p), (appData.BUILD.hydrateServerSide || appData.BUILD.hotModuleReplacement) && a.setAttribute("sty-id", n), 
    e.insertBefore(a, e.querySelector("link"));
   }
   r && r.add(n);
  }
 } else appData.BUILD.constructableCSS && !e.adoptedStyleSheets.includes(l) && (e.adoptedStyleSheets = [ ...e.adoptedStyleSheets, l ]);
 return n;
}, attachStyles = e => {
 const t = e.$cmpMeta$, a = e.$hostElement$, o = t.$flags$, s = createTime("attachStyles", t.$tagName$), n = addStyle(appData.BUILD.shadowDom && exports.supportsShadow && a.shadowRoot ? a.shadowRoot : a.getRootNode(), t, e.$modeName$, a);
 (appData.BUILD.shadowDom || appData.BUILD.scoped) && appData.BUILD.cssAnnotations && 10 & o && (a["s-sc"] = n, 
 a.classList.add(n + "-h"), appData.BUILD.scoped && 2 & o && a.classList.add(n + "-s")), 
 s();
}, getScopeId = (e, t) => "sc-" + (appData.BUILD.mode && t && 32 & e.$flags$ ? e.$tagName$ + "-" + t : e.$tagName$), setAccessor = (e, t, a, o, s, n) => {
 if (a !== o) {
  let l = isMemberInElement(e, t), r = t.toLowerCase();
  if (appData.BUILD.vdomClass && "class" === t) {
   const t = e.classList, s = parseClassList(a), n = parseClassList(o);
   t.remove(...s.filter((e => e && !n.includes(e)))), t.add(...n.filter((e => e && !s.includes(e))));
  } else if (appData.BUILD.vdomStyle && "style" === t) {
   if (appData.BUILD.updatable) for (const t in a) o && null != o[t] || (!appData.BUILD.hydrateServerSide && t.includes("-") ? e.style.removeProperty(t) : e.style[t] = "");
   for (const t in o) a && o[t] === a[t] || (!appData.BUILD.hydrateServerSide && t.includes("-") ? e.style.setProperty(t, o[t]) : e.style[t] = o[t]);
  } else if (appData.BUILD.vdomKey && "key" === t) ; else if (appData.BUILD.vdomRef && "ref" === t) o && o(e); else if (!appData.BUILD.vdomListener || (appData.BUILD.lazyLoad ? l : e.__lookupSetter__(t)) || "o" !== t[0] || "n" !== t[1]) {
   if (appData.BUILD.vdomPropOrAttr) {
    const p = isComplexType(o);
    if ((l || p && null !== o) && !s) try {
     if (e.tagName.includes("-")) e[t] = o; else {
      const s = null == o ? "" : o;
      "list" === t ? l = !1 : null != a && e[t] == s || (e[t] = s);
     }
    } catch (e) {}
    let i = !1;
    appData.BUILD.vdomXlink && r !== (r = r.replace(/^xlink\:?/, "")) && (t = r, i = !0), 
    null == o || !1 === o ? !1 === o && "" !== e.getAttribute(t) || (appData.BUILD.vdomXlink && i ? e.removeAttributeNS(XLINK_NS, t) : e.removeAttribute(t)) : (!l || 4 & n || s) && !p && (o = !0 === o ? "" : o, 
    appData.BUILD.vdomXlink && i ? e.setAttributeNS(XLINK_NS, t, o) : e.setAttribute(t, o));
   }
  } else t = "-" === t[2] ? t.slice(3) : isMemberInElement(win, r) ? r.slice(2) : r[2] + t.slice(3), 
  a && plt.rel(e, t, a, !1), o && plt.ael(e, t, o, !1);
 }
}, parseClassListRegex = /\s/, parseClassList = e => e ? e.split(parseClassListRegex) : [], updateElement = (e, t, a, o) => {
 const s = 11 === t.$elm$.nodeType && t.$elm$.host ? t.$elm$.host : t.$elm$, n = e && e.$attrs$ || EMPTY_OBJ, l = t.$attrs$ || EMPTY_OBJ;
 if (appData.BUILD.updatable) for (o in n) o in l || setAccessor(s, o, n[o], void 0, a, t.$flags$);
 for (o in l) setAccessor(s, o, n[o], l[o], a, t.$flags$);
};

let scopeId, contentRef, hostTagName, useNativeShadowDom = !1, checkSlotFallbackVisibility = !1, checkSlotRelocate = !1, isSvgMode = !1;

const createElm = (e, t, a, o) => {
 const s = t.$children$[a];
 let n, l, r, p = 0;
 if (appData.BUILD.slotRelocation && !useNativeShadowDom && (checkSlotRelocate = !0, 
 "slot" === s.$tag$ && (scopeId && o.classList.add(scopeId + "-s"), s.$flags$ |= s.$children$ ? 2 : 1)), 
 appData.BUILD.isDev && s.$elm$ && consoleDevError(`The JSX ${null !== s.$text$ ? `"${s.$text$}" text` : `"${s.$tag$}" element`} node should not be shared within the same renderer. The renderer caches element lookups in order to improve performance. However, a side effect from this is that the exact same JSX node should not be reused. For more information please see https://stenciljs.com/docs/templating-jsx#avoid-shared-jsx-nodes`), 
 appData.BUILD.vdomText && null !== s.$text$) n = s.$elm$ = doc.createTextNode(s.$text$); else if (appData.BUILD.slotRelocation && 1 & s.$flags$) n = s.$elm$ = appData.BUILD.isDebug || appData.BUILD.hydrateServerSide ? slotReferenceDebugNode(s) : doc.createTextNode(""); else {
  if (appData.BUILD.svg && !isSvgMode && (isSvgMode = "svg" === s.$tag$), n = s.$elm$ = appData.BUILD.svg ? doc.createElementNS(isSvgMode ? "http://www.w3.org/2000/svg" : "http://www.w3.org/1999/xhtml", appData.BUILD.slotRelocation && 2 & s.$flags$ ? "slot-fb" : s.$tag$) : doc.createElement(appData.BUILD.slotRelocation && 2 & s.$flags$ ? "slot-fb" : s.$tag$), 
  appData.BUILD.svg && isSvgMode && "foreignObject" === s.$tag$ && (isSvgMode = !1), 
  appData.BUILD.vdomAttribute && updateElement(null, s, isSvgMode), (appData.BUILD.shadowDom || appData.BUILD.scoped) && null != scopeId && n["s-si"] !== scopeId && n.classList.add(n["s-si"] = scopeId), 
  s.$children$) for (p = 0; p < s.$children$.length; ++p) l = createElm(e, s, p, n), 
  l && n.appendChild(l);
  appData.BUILD.svg && ("svg" === s.$tag$ ? isSvgMode = !1 : "foreignObject" === n.tagName && (isSvgMode = !0));
 }
 return appData.BUILD.slotRelocation && (n["s-hn"] = hostTagName, 3 & s.$flags$ && (n["s-sr"] = !0, 
 n["s-cr"] = contentRef, n["s-sn"] = s.$name$ || "", r = e && e.$children$ && e.$children$[a], 
 r && r.$tag$ === s.$tag$ && e.$elm$ && putBackInOriginalLocation(e.$elm$, !1))), 
 n;
}, putBackInOriginalLocation = (e, t) => {
 plt.$flags$ |= 1;
 const a = e.childNodes;
 for (let e = a.length - 1; e >= 0; e--) {
  const o = a[e];
  o["s-hn"] !== hostTagName && o["s-ol"] && (parentReferenceNode(o).insertBefore(o, referenceNode(o)), 
  o["s-ol"].remove(), o["s-ol"] = void 0, checkSlotRelocate = !0), t && putBackInOriginalLocation(o, t);
 }
 plt.$flags$ &= -2;
}, addVnodes = (e, t, a, o, s, n) => {
 let l, r = appData.BUILD.slotRelocation && e["s-cr"] && e["s-cr"].parentNode || e;
 for (appData.BUILD.shadowDom && r.shadowRoot && r.tagName === hostTagName && (r = r.shadowRoot); s <= n; ++s) o[s] && (l = createElm(null, a, s, e), 
 l && (o[s].$elm$ = l, r.insertBefore(l, appData.BUILD.slotRelocation ? referenceNode(t) : t)));
}, removeVnodes = (e, t, a, o, s) => {
 for (;t <= a; ++t) (o = e[t]) && (s = o.$elm$, callNodeRefs(o), appData.BUILD.slotRelocation && (checkSlotFallbackVisibility = !0, 
 s["s-ol"] ? s["s-ol"].remove() : putBackInOriginalLocation(s, !0)), s.remove());
}, isSameVnode = (e, t) => e.$tag$ === t.$tag$ && (appData.BUILD.slotRelocation && "slot" === e.$tag$ ? e.$name$ === t.$name$ : !appData.BUILD.vdomKey || e.$key$ === t.$key$), referenceNode = e => e && e["s-ol"] || e, parentReferenceNode = e => (e["s-ol"] ? e["s-ol"] : e).parentNode, patch = (e, t) => {
 const a = t.$elm$ = e.$elm$, o = e.$children$, s = t.$children$, n = t.$tag$, l = t.$text$;
 let r;
 appData.BUILD.vdomText && null !== l ? appData.BUILD.vdomText && appData.BUILD.slotRelocation && (r = a["s-cr"]) ? r.parentNode.textContent = l : appData.BUILD.vdomText && e.$text$ !== l && (a.data = l) : (appData.BUILD.svg && (isSvgMode = "svg" === n || "foreignObject" !== n && isSvgMode), 
 (appData.BUILD.vdomAttribute || appData.BUILD.reflect) && (appData.BUILD.slot && "slot" === n || updateElement(e, t, isSvgMode)), 
 appData.BUILD.updatable && null !== o && null !== s ? ((e, t, a, o) => {
  let s, n, l = 0, r = 0, p = 0, i = 0, d = t.length - 1, c = t[0], $ = t[d], u = o.length - 1, m = o[0], h = o[u];
  for (;l <= d && r <= u; ) if (null == c) c = t[++l]; else if (null == $) $ = t[--d]; else if (null == m) m = o[++r]; else if (null == h) h = o[--u]; else if (isSameVnode(c, m)) patch(c, m), 
  c = t[++l], m = o[++r]; else if (isSameVnode($, h)) patch($, h), $ = t[--d], h = o[--u]; else if (isSameVnode(c, h)) !appData.BUILD.slotRelocation || "slot" !== c.$tag$ && "slot" !== h.$tag$ || putBackInOriginalLocation(c.$elm$.parentNode, !1), 
  patch(c, h), e.insertBefore(c.$elm$, $.$elm$.nextSibling), c = t[++l], h = o[--u]; else if (isSameVnode($, m)) !appData.BUILD.slotRelocation || "slot" !== c.$tag$ && "slot" !== h.$tag$ || putBackInOriginalLocation($.$elm$.parentNode, !1), 
  patch($, m), e.insertBefore($.$elm$, c.$elm$), $ = t[--d], m = o[++r]; else {
   if (p = -1, appData.BUILD.vdomKey) for (i = l; i <= d; ++i) if (t[i] && null !== t[i].$key$ && t[i].$key$ === m.$key$) {
    p = i;
    break;
   }
   appData.BUILD.vdomKey && p >= 0 ? (n = t[p], n.$tag$ !== m.$tag$ ? s = createElm(t && t[r], a, p, e) : (patch(n, m), 
   t[p] = void 0, s = n.$elm$), m = o[++r]) : (s = createElm(t && t[r], a, r, e), m = o[++r]), 
   s && (appData.BUILD.slotRelocation ? parentReferenceNode(c.$elm$).insertBefore(s, referenceNode(c.$elm$)) : c.$elm$.parentNode.insertBefore(s, c.$elm$));
  }
  l > d ? addVnodes(e, null == o[u + 1] ? null : o[u + 1].$elm$, a, o, r, u) : appData.BUILD.updatable && r > u && removeVnodes(t, l, d);
 })(a, o, t, s) : null !== s ? (appData.BUILD.updatable && appData.BUILD.vdomText && null !== e.$text$ && (a.textContent = ""), 
 addVnodes(a, null, t, s, 0, s.length - 1)) : appData.BUILD.updatable && null !== o && removeVnodes(o, 0, o.length - 1), 
 appData.BUILD.svg && isSvgMode && "svg" === n && (isSvgMode = !1));
}, updateFallbackSlotVisibility = e => {
 const t = e.childNodes;
 let a, o, s, n, l, r;
 for (o = 0, s = t.length; o < s; o++) if (a = t[o], 1 === a.nodeType) {
  if (a["s-sr"]) for (l = a["s-sn"], a.hidden = !1, n = 0; n < s; n++) if (r = t[n].nodeType, 
  t[n]["s-hn"] !== a["s-hn"] || "" !== l) {
   if (1 === r && l === t[n].getAttribute("slot")) {
    a.hidden = !0;
    break;
   }
  } else if (1 === r || 3 === r && "" !== t[n].textContent.trim()) {
   a.hidden = !0;
   break;
  }
  updateFallbackSlotVisibility(a);
 }
}, relocateNodes = [], relocateSlotContent = e => {
 let t, a, o, s, n, l, r = 0;
 const p = e.childNodes, i = p.length;
 for (;r < i; r++) {
  if (t = p[r], t["s-sr"] && (a = t["s-cr"]) && a.parentNode) for (o = a.parentNode.childNodes, 
  s = t["s-sn"], l = o.length - 1; l >= 0; l--) a = o[l], a["s-cn"] || a["s-nr"] || a["s-hn"] === t["s-hn"] || (isNodeLocatedInSlot(a, s) ? (n = relocateNodes.find((e => e.$nodeToRelocate$ === a)), 
  checkSlotFallbackVisibility = !0, a["s-sn"] = a["s-sn"] || s, n ? n.$slotRefNode$ = t : relocateNodes.push({
   $slotRefNode$: t,
   $nodeToRelocate$: a
  }), a["s-sr"] && relocateNodes.map((e => {
   isNodeLocatedInSlot(e.$nodeToRelocate$, a["s-sn"]) && (n = relocateNodes.find((e => e.$nodeToRelocate$ === a)), 
   n && !e.$slotRefNode$ && (e.$slotRefNode$ = n.$slotRefNode$));
  }))) : relocateNodes.some((e => e.$nodeToRelocate$ === a)) || relocateNodes.push({
   $nodeToRelocate$: a
  }));
  1 === t.nodeType && relocateSlotContent(t);
 }
}, isNodeLocatedInSlot = (e, t) => 1 === e.nodeType ? null === e.getAttribute("slot") && "" === t || e.getAttribute("slot") === t : e["s-sn"] === t || "" === t, callNodeRefs = e => {
 appData.BUILD.vdomRef && (e.$attrs$ && e.$attrs$.ref && e.$attrs$.ref(null), e.$children$ && e.$children$.map(callNodeRefs));
}, renderVdom = (e, t) => {
 const a = e.$hostElement$, o = e.$cmpMeta$, s = e.$vnode$ || newVNode(null, null), n = isHost(t) ? t : h(null, null, t);
 if (hostTagName = a.tagName, appData.BUILD.isDev && Array.isArray(t) && t.some(isHost)) throw new Error(`The <Host> must be the single root component.\nLooks like the render() function of "${hostTagName.toLowerCase()}" is returning an array that contains the <Host>.\n\nThe render() function should look like this instead:\n\nrender() {\n  // Do not return an array\n  return (\n    <Host>{content}</Host>\n  );\n}\n  `);
 if (appData.BUILD.reflect && o.$attrsToReflect$ && (n.$attrs$ = n.$attrs$ || {}, 
 o.$attrsToReflect$.map((([e, t]) => n.$attrs$[t] = a[e]))), n.$tag$ = null, n.$flags$ |= 4, 
 e.$vnode$ = n, n.$elm$ = s.$elm$ = appData.BUILD.shadowDom && a.shadowRoot || a, 
 (appData.BUILD.scoped || appData.BUILD.shadowDom) && (scopeId = a["s-sc"]), appData.BUILD.slotRelocation && (contentRef = a["s-cr"], 
 useNativeShadowDom = exports.supportsShadow && 0 != (1 & o.$flags$), checkSlotFallbackVisibility = !1), 
 patch(s, n), appData.BUILD.slotRelocation) {
  if (plt.$flags$ |= 1, checkSlotRelocate) {
   let e, t, a, o, s, l;
   relocateSlotContent(n.$elm$);
   let r = 0;
   for (;r < relocateNodes.length; r++) e = relocateNodes[r], t = e.$nodeToRelocate$, 
   t["s-ol"] || (a = appData.BUILD.isDebug || appData.BUILD.hydrateServerSide ? originalLocationDebugNode(t) : doc.createTextNode(""), 
   a["s-nr"] = t, t.parentNode.insertBefore(t["s-ol"] = a, t));
   for (r = 0; r < relocateNodes.length; r++) if (e = relocateNodes[r], t = e.$nodeToRelocate$, 
   e.$slotRefNode$) {
    for (o = e.$slotRefNode$.parentNode, s = e.$slotRefNode$.nextSibling, a = t["s-ol"]; a = a.previousSibling; ) if (l = a["s-nr"], 
    l && l["s-sn"] === t["s-sn"] && o === l.parentNode && (l = l.nextSibling, !l || !l["s-nr"])) {
     s = l;
     break;
    }
    (!s && o !== t.parentNode || t.nextSibling !== s) && t !== s && (!t["s-hn"] && t["s-ol"] && (t["s-hn"] = t["s-ol"].parentNode.nodeName), 
    o.insertBefore(t, s));
   } else 1 === t.nodeType && (t.hidden = !0);
  }
  checkSlotFallbackVisibility && updateFallbackSlotVisibility(n.$elm$), plt.$flags$ &= -2, 
  relocateNodes.length = 0;
 }
}, slotReferenceDebugNode = e => doc.createComment(`<slot${e.$name$ ? ' name="' + e.$name$ + '"' : ""}> (host=${hostTagName.toLowerCase()})`), originalLocationDebugNode = e => doc.createComment("org-location for " + (e.localName ? `<${e.localName}> (host=${e["s-hn"]})` : `[${e.textContent}]`)), attachToAncestor = (e, t) => {
 appData.BUILD.asyncLoading && t && !e.$onRenderResolve$ && t["s-p"] && t["s-p"].push(new Promise((t => e.$onRenderResolve$ = t)));
}, scheduleUpdate = (e, t) => {
 if (appData.BUILD.taskQueue && appData.BUILD.updatable && (e.$flags$ |= 16), appData.BUILD.asyncLoading && 4 & e.$flags$) return void (e.$flags$ |= 512);
 attachToAncestor(e, e.$ancestorComponent$);
 const a = () => dispatchHooks(e, t);
 return appData.BUILD.taskQueue ? writeTask(a) : a();
}, dispatchHooks = (e, t) => {
 const a = e.$hostElement$, o = createTime("scheduleUpdate", e.$cmpMeta$.$tagName$), s = appData.BUILD.lazyLoad ? e.$lazyInstance$ : a;
 let n;
 return t ? (appData.BUILD.lazyLoad && appData.BUILD.hostListener && (e.$flags$ |= 256, 
 e.$queuedListeners$ && (e.$queuedListeners$.map((([e, t]) => safeCall(s, e, t))), 
 e.$queuedListeners$ = null)), emitLifecycleEvent(a, "componentWillLoad"), appData.BUILD.cmpWillLoad && (n = safeCall(s, "componentWillLoad"))) : (emitLifecycleEvent(a, "componentWillUpdate"), 
 appData.BUILD.cmpWillUpdate && (n = safeCall(s, "componentWillUpdate"))), emitLifecycleEvent(a, "componentWillRender"), 
 appData.BUILD.cmpWillRender && (n = then(n, (() => safeCall(s, "componentWillRender")))), 
 o(), then(n, (() => updateComponent(e, s, t)));
}, updateComponent = async (e, t, a) => {
 const o = e.$hostElement$, s = createTime("update", e.$cmpMeta$.$tagName$), n = o["s-rc"];
 appData.BUILD.style && a && attachStyles(e);
 const l = createTime("render", e.$cmpMeta$.$tagName$);
 if (appData.BUILD.isDev && (e.$flags$ |= 1024), appData.BUILD.hydrateServerSide ? await callRender(e, t, o) : callRender(e, t, o), 
 appData.BUILD.cssVarShim && plt.$cssShim$ && plt.$cssShim$.updateHost(o), appData.BUILD.isDev && (e.$renderCount$++, 
 e.$flags$ &= -1025), appData.BUILD.hydrateServerSide) try {
  serverSideConnected(o), a && (1 & e.$cmpMeta$.$flags$ ? o["s-en"] = "" : 2 & e.$cmpMeta$.$flags$ && (o["s-en"] = "c"));
 } catch (e) {
  consoleError(e, o);
 }
 if (appData.BUILD.asyncLoading && n && (n.map((e => e())), o["s-rc"] = void 0), 
 l(), s(), appData.BUILD.asyncLoading) {
  const t = o["s-p"], a = () => postUpdateComponent(e);
  0 === t.length ? a() : (Promise.all(t).then(a), e.$flags$ |= 4, t.length = 0);
 } else postUpdateComponent(e);
};

let renderingRef = null;

const callRender = (e, t, a) => {
 const o = !!appData.BUILD.allRenderFn, s = !!appData.BUILD.lazyLoad, n = !!appData.BUILD.taskQueue, l = !!appData.BUILD.updatable;
 try {
  if (renderingRef = t, t = (o || t.render) && t.render(), l && n && (e.$flags$ &= -17), 
  (l || s) && (e.$flags$ |= 2), appData.BUILD.hasRenderFn || appData.BUILD.reflect) if (appData.BUILD.vdomRender || appData.BUILD.reflect) {
   if (appData.BUILD.hydrateServerSide) return Promise.resolve(t).then((t => renderVdom(e, t)));
   renderVdom(e, t);
  } else a.textContent = t;
 } catch (t) {
  consoleError(t, e.$hostElement$);
 }
 return renderingRef = null, null;
}, postUpdateComponent = e => {
 const t = e.$cmpMeta$.$tagName$, a = e.$hostElement$, o = createTime("postUpdate", t), s = appData.BUILD.lazyLoad ? e.$lazyInstance$ : a, n = e.$ancestorComponent$;
 appData.BUILD.cmpDidRender && (appData.BUILD.isDev && (e.$flags$ |= 1024), safeCall(s, "componentDidRender"), 
 appData.BUILD.isDev && (e.$flags$ &= -1025)), emitLifecycleEvent(a, "componentDidRender"), 
 64 & e.$flags$ ? (appData.BUILD.cmpDidUpdate && (appData.BUILD.isDev && (e.$flags$ |= 1024), 
 safeCall(s, "componentDidUpdate"), appData.BUILD.isDev && (e.$flags$ &= -1025)), 
 emitLifecycleEvent(a, "componentDidUpdate"), o()) : (e.$flags$ |= 64, appData.BUILD.asyncLoading && appData.BUILD.cssAnnotations && addHydratedFlag(a), 
 appData.BUILD.cmpDidLoad && (appData.BUILD.isDev && (e.$flags$ |= 2048), safeCall(s, "componentDidLoad"), 
 appData.BUILD.isDev && (e.$flags$ &= -2049)), emitLifecycleEvent(a, "componentDidLoad"), 
 o(), appData.BUILD.asyncLoading && (e.$onReadyResolve$(a), n || appDidLoad(t))), 
 appData.BUILD.hotModuleReplacement && a["s-hmr-load"] && a["s-hmr-load"](), appData.BUILD.method && appData.BUILD.lazyLoad && e.$onInstanceResolve$(a), 
 appData.BUILD.asyncLoading && (e.$onRenderResolve$ && (e.$onRenderResolve$(), e.$onRenderResolve$ = void 0), 
 512 & e.$flags$ && nextTick((() => scheduleUpdate(e, !1))), e.$flags$ &= -517);
}, forceUpdate = e => {
 if (appData.BUILD.updatable) {
  const t = getHostRef(e), a = t.$hostElement$.isConnected;
  return a && 2 == (18 & t.$flags$) && scheduleUpdate(t, !1), a;
 }
 return !1;
}, appDidLoad = e => {
 appData.BUILD.cssAnnotations && addHydratedFlag(doc.documentElement), appData.BUILD.asyncQueue && (plt.$flags$ |= 2), 
 nextTick((() => emitEvent(win, "appload", {
  detail: {
   namespace: appData.NAMESPACE
  }
 }))), appData.BUILD.profile && performance.measure && performance.measure(`[Stencil] ${appData.NAMESPACE} initial load (by ${e})`, "st:app:start");
}, safeCall = (e, t, a) => {
 if (e && e[t]) try {
  return e[t](a);
 } catch (e) {
  consoleError(e);
 }
}, then = (e, t) => e && e.then ? e.then(t) : t(), emitLifecycleEvent = (e, t) => {
 appData.BUILD.lifecycleDOMEvents && emitEvent(e, "stencil_" + t, {
  bubbles: !0,
  composed: !0,
  detail: {
   namespace: appData.NAMESPACE
  }
 });
}, addHydratedFlag = e => appData.BUILD.hydratedClass ? e.classList.add("hydrated") : appData.BUILD.hydratedAttribute ? e.setAttribute("hydrated", "") : void 0, serverSideConnected = e => {
 const t = e.children;
 if (null != t) for (let e = 0, a = t.length; e < a; e++) {
  const a = t[e];
  "function" == typeof a.connectedCallback && a.connectedCallback(), serverSideConnected(a);
 }
}, getValue = (e, t) => getHostRef(e).$instanceValues$.get(t), setValue = (e, t, a, o) => {
 const s = getHostRef(e), n = appData.BUILD.lazyLoad ? s.$hostElement$ : e, l = s.$instanceValues$.get(t), r = s.$flags$, p = appData.BUILD.lazyLoad ? s.$lazyInstance$ : n;
 a = parsePropertyValue(a, o.$members$[t][0]);
 const i = Number.isNaN(l) && Number.isNaN(a), d = a !== l && !i;
 if ((!appData.BUILD.lazyLoad || !(8 & r) || void 0 === l) && d && (s.$instanceValues$.set(t, a), 
 appData.BUILD.isDev && (1024 & s.$flags$ ? consoleDevWarn(`The state/prop "${t}" changed during rendering. This can potentially lead to infinite-loops and other bugs.`, "\nElement", n, "\nNew value", a, "\nOld value", l) : 2048 & s.$flags$ && consoleDevWarn(`The state/prop "${t}" changed during "componentDidLoad()", this triggers extra re-renders, try to setup on "componentWillLoad()"`, "\nElement", n, "\nNew value", a, "\nOld value", l)), 
 !appData.BUILD.lazyLoad || p)) {
  if (appData.BUILD.watchCallback && o.$watchers$ && 128 & r) {
   const e = o.$watchers$[t];
   e && e.map((e => {
    try {
     p[e](a, l, t);
    } catch (e) {
     consoleError(e, n);
    }
   }));
  }
  if (appData.BUILD.updatable && 2 == (18 & r)) {
   if (appData.BUILD.cmpShouldUpdate && p.componentShouldUpdate && !1 === p.componentShouldUpdate(a, l, t)) return;
   scheduleUpdate(s, !1);
  }
 }
}, proxyComponent = (e, t, a) => {
 if (appData.BUILD.member && t.$members$) {
  appData.BUILD.watchCallback && e.watchers && (t.$watchers$ = e.watchers);
  const o = Object.entries(t.$members$), s = e.prototype;
  if (o.map((([e, [o]]) => {
   (appData.BUILD.prop || appData.BUILD.state) && (31 & o || (!appData.BUILD.lazyLoad || 2 & a) && 32 & o) ? Object.defineProperty(s, e, {
    get() {
     return getValue(this, e);
    },
    set(s) {
     if (appData.BUILD.isDev) {
      const s = getHostRef(this);
      0 == (1 & a) && 0 == (8 & s.$flags$) && 0 != (31 & o) && 0 == (1024 & o) && consoleDevWarn(`@Prop() "${e}" on <${t.$tagName$}> is immutable but was modified from within the component.\nMore information: https://stenciljs.com/docs/properties#prop-mutability`);
     }
     setValue(this, e, s, t);
    },
    configurable: !0,
    enumerable: !0
   }) : appData.BUILD.lazyLoad && appData.BUILD.method && 1 & a && 64 & o && Object.defineProperty(s, e, {
    value(...t) {
     const a = getHostRef(this);
     return a.$onInstancePromise$.then((() => a.$lazyInstance$[e](...t)));
    }
   });
  })), appData.BUILD.observeAttribute && (!appData.BUILD.lazyLoad || 1 & a)) {
   const a = new Map;
   s.attributeChangedCallback = function(e, t, o) {
    plt.jmp((() => {
     const t = a.get(e);
     if (this.hasOwnProperty(t)) o = this[t], delete this[t]; else if (s.hasOwnProperty(t) && "number" == typeof this[t] && this[t] == o) return;
     this[t] = (null !== o || "boolean" != typeof this[t]) && o;
    }));
   }, e.observedAttributes = o.filter((([e, t]) => 15 & t[0])).map((([e, o]) => {
    const s = o[1] || e;
    return a.set(s, e), appData.BUILD.reflect && 512 & o[0] && t.$attrsToReflect$.push([ e, s ]), 
    s;
   }));
  }
 }
 return e;
}, initializeComponent = async (e, t, a, o, s) => {
 if ((appData.BUILD.lazyLoad || appData.BUILD.hydrateServerSide || appData.BUILD.style) && 0 == (32 & t.$flags$)) {
  if (appData.BUILD.lazyLoad || appData.BUILD.hydrateClientSide) {
   if (t.$flags$ |= 32, (s = loadModule(a)).then) {
    const e = (n = `st:load:${a.$tagName$}:${t.$modeName$}`, l = `[Stencil] Load module for <${a.$tagName$}>`, 
    appData.BUILD.profile && performance.mark ? (0 === performance.getEntriesByName(n, "mark").length && performance.mark(n), 
    () => {
     0 === performance.getEntriesByName(l, "measure").length && performance.measure(l, n);
    }) : () => {});
    s = await s, e();
   }
   if ((appData.BUILD.isDev || appData.BUILD.isDebug) && !s) throw new Error(`Constructor for "${a.$tagName$}#${t.$modeName$}" was not found`);
   appData.BUILD.member && !s.isProxied && (appData.BUILD.watchCallback && (a.$watchers$ = s.watchers), 
   proxyComponent(s, a, 2), s.isProxied = !0);
   const e = createTime("createInstance", a.$tagName$);
   appData.BUILD.member && (t.$flags$ |= 8);
   try {
    new s(t);
   } catch (e) {
    consoleError(e);
   }
   appData.BUILD.member && (t.$flags$ &= -9), appData.BUILD.watchCallback && (t.$flags$ |= 128), 
   e(), fireConnectedCallback(t.$lazyInstance$);
  } else s = e.constructor, t.$flags$ |= 32, customElements.whenDefined(a.$tagName$).then((() => t.$flags$ |= 128));
  if (appData.BUILD.style && s.style) {
   let o = s.style;
   appData.BUILD.mode && "string" != typeof o && (o = o[t.$modeName$ = computeMode(e)], 
   appData.BUILD.hydrateServerSide && t.$modeName$ && e.setAttribute("s-mode", t.$modeName$));
   const n = getScopeId(a, t.$modeName$);
   if (!styles.has(n)) {
    const e = createTime("registerStyles", a.$tagName$);
    !appData.BUILD.hydrateServerSide && appData.BUILD.shadowDom && appData.BUILD.shadowDomShim && 8 & a.$flags$ && (o = await Promise.resolve().then((function() {
     return require("./shadow-css.js");
    })).then((e => e.scopeCss(o, n, !1)))), registerStyle(n, o, a.$flags$), e();
   }
  }
 }
 var n, l;
 const r = t.$ancestorComponent$, p = () => scheduleUpdate(t, !0);
 appData.BUILD.asyncLoading && r && r["s-rc"] ? r["s-rc"].push(p) : p();
}, fireConnectedCallback = e => {
 appData.BUILD.lazyLoad && appData.BUILD.connectedCallback && safeCall(e, "connectedCallback");
}, connectedCallback = e => {
 if (0 == (1 & plt.$flags$)) {
  const t = getHostRef(e), a = t.$cmpMeta$, o = createTime("connectedCallback", a.$tagName$);
  if (appData.BUILD.hostListenerTargetParent && addHostEventListeners(e, t, a.$listeners$, !0), 
  1 & t.$flags$) addHostEventListeners(e, t, a.$listeners$, !1), fireConnectedCallback(t.$lazyInstance$); else {
   let o;
   if (t.$flags$ |= 1, appData.BUILD.hydrateClientSide && (o = e.getAttribute("s-id"), 
   o)) {
    if (appData.BUILD.shadowDom && exports.supportsShadow && 1 & a.$flags$) {
     const t = appData.BUILD.mode ? addStyle(e.shadowRoot, a, e.getAttribute("s-mode")) : addStyle(e.shadowRoot, a);
     e.classList.remove(t + "-h", t + "-s");
    }
    ((e, t, a, o) => {
     const s = createTime("hydrateClient", t), n = e.shadowRoot, l = [], r = appData.BUILD.shadowDom && n ? [] : null, p = o.$vnode$ = newVNode(t, null);
     plt.$orgLocNodes$ || initializeDocumentHydrate(doc.body, plt.$orgLocNodes$ = new Map), 
     e["s-id"] = a, e.removeAttribute("s-id"), clientHydrate(p, l, [], r, e, e, a), l.map((e => {
      const a = e.$hostId$ + "." + e.$nodeId$, o = plt.$orgLocNodes$.get(a), s = e.$elm$;
      o && exports.supportsShadow && "" === o["s-en"] && o.parentNode.insertBefore(s, o.nextSibling), 
      n || (s["s-hn"] = t, o && (s["s-ol"] = o, s["s-ol"]["s-nr"] = s)), plt.$orgLocNodes$.delete(a);
     })), appData.BUILD.shadowDom && n && r.map((e => {
      e && n.appendChild(e);
     })), s();
    })(e, a.$tagName$, o, t);
   }
   if (appData.BUILD.slotRelocation && !o && (appData.BUILD.hydrateServerSide || (appData.BUILD.slot || appData.BUILD.shadowDom) && 12 & a.$flags$) && setContentReference(e), 
   appData.BUILD.asyncLoading) {
    let a = e;
    for (;a = a.parentNode || a.host; ) if (appData.BUILD.hydrateClientSide && 1 === a.nodeType && a.hasAttribute("s-id") && a["s-p"] || a["s-p"]) {
     attachToAncestor(t, t.$ancestorComponent$ = a);
     break;
    }
   }
   appData.BUILD.prop && !appData.BUILD.hydrateServerSide && a.$members$ && Object.entries(a.$members$).map((([t, [a]]) => {
    if (31 & a && e.hasOwnProperty(t)) {
     const a = e[t];
     delete e[t], e[t] = a;
    }
   })), appData.BUILD.initializeNextTick ? nextTick((() => initializeComponent(e, t, a))) : initializeComponent(e, t, a);
  }
  o();
 }
}, setContentReference = e => {
 const t = e["s-cr"] = doc.createComment(appData.BUILD.isDebug ? `content-ref (host=${e.localName})` : "");
 t["s-cn"] = !0, e.insertBefore(t, e.firstChild);
}, disconnectedCallback = e => {
 if (0 == (1 & plt.$flags$)) {
  const t = getHostRef(e), a = appData.BUILD.lazyLoad ? t.$lazyInstance$ : e;
  appData.BUILD.hostListener && t.$rmListeners$ && (t.$rmListeners$.map((e => e())), 
  t.$rmListeners$ = void 0), appData.BUILD.cssVarShim && plt.$cssShim$ && plt.$cssShim$.removeHost(e), 
  appData.BUILD.lazyLoad && appData.BUILD.disconnectedCallback && safeCall(a, "disconnectedCallback"), 
  appData.BUILD.cmpDidUnload && safeCall(a, "componentDidUnload");
 }
}, proxyCustomElement = (e, t) => {
 const a = {
  $flags$: t[0],
  $tagName$: t[1]
 };
 appData.BUILD.member && (a.$members$ = t[2]), appData.BUILD.hostListener && (a.$listeners$ = t[3]), 
 appData.BUILD.watchCallback && (a.$watchers$ = e.$watchers$), appData.BUILD.reflect && (a.$attrsToReflect$ = []), 
 appData.BUILD.shadowDom && !exports.supportsShadow && 1 & a.$flags$ && (a.$flags$ |= 8);
 const o = e.prototype.connectedCallback, s = e.prototype.disconnectedCallback;
 return Object.assign(e.prototype, {
  __registerHost() {
   registerHost(this, a);
  },
  connectedCallback() {
   connectedCallback(this), appData.BUILD.connectedCallback && o && o.call(this);
  },
  disconnectedCallback() {
   disconnectedCallback(this), appData.BUILD.disconnectedCallback && s && s.call(this);
  },
  __attachShadow() {
   exports.supportsShadow ? appData.BUILD.shadowDelegatesFocus ? this.attachShadow({
    mode: "open",
    delegatesFocus: !!(16 & a.$flags$)
   }) : this.attachShadow({
    mode: "open"
   }) : this.shadowRoot = this;
  }
 }), e.is = a.$tagName$, proxyComponent(e, a, 3);
}, patchCloneNode = e => {
 const t = e.cloneNode;
 e.cloneNode = function(e) {
  const a = this, o = !!appData.BUILD.shadowDom && a.shadowRoot && exports.supportsShadow, s = t.call(a, !!o && e);
  if (appData.BUILD.slot && !o && e) {
   let e, t, o = 0;
   const n = [ "s-id", "s-cr", "s-lr", "s-rc", "s-sc", "s-p", "s-cn", "s-sr", "s-sn", "s-hn", "s-ol", "s-nr", "s-si" ];
   for (;o < a.childNodes.length; o++) e = a.childNodes[o]["s-nr"], t = n.every((e => !a.childNodes[o][e])), 
   e && (appData.BUILD.appendChildSlotFix && s.__appendChild ? s.__appendChild(e.cloneNode(!0)) : s.appendChild(e.cloneNode(!0))), 
   t && s.appendChild(a.childNodes[o].cloneNode(!0));
  }
  return s;
 };
}, patchSlotAppendChild = e => {
 e.__appendChild = e.appendChild, e.appendChild = function(e) {
  const t = e["s-sn"] = getSlotName(e), a = getHostSlotNode(this.childNodes, t);
  if (a) {
   const o = getHostSlotChildNodes(a, t), s = o[o.length - 1];
   return s.parentNode.insertBefore(e, s.nextSibling);
  }
  return this.__appendChild(e);
 };
}, patchTextContent = (e, t) => {
 if (appData.BUILD.scoped && 2 & t.$flags$) {
  const t = Object.getOwnPropertyDescriptor(Node.prototype, "textContent");
  Object.defineProperty(e, "__textContent", t), Object.defineProperty(e, "textContent", {
   get() {
    var e;
    const t = getHostSlotNode(this.childNodes, "");
    return 3 === (null === (e = null == t ? void 0 : t.nextSibling) || void 0 === e ? void 0 : e.nodeType) ? t.nextSibling.textContent : t ? t.textContent : this.__textContent;
   },
   set(e) {
    var t;
    const a = getHostSlotNode(this.childNodes, "");
    if (3 === (null === (t = null == a ? void 0 : a.nextSibling) || void 0 === t ? void 0 : t.nodeType)) a.nextSibling.textContent = e; else if (a) a.textContent = e; else {
     this.__textContent = e;
     const t = this["s-cr"];
     t && this.insertBefore(t, this.firstChild);
    }
   }
  });
 }
}, patchChildSlotNodes = (e, t) => {
 class a extends Array {
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
     const t = new a;
     for (let a = 0; a < e.length; a++) {
      const o = e[a]["s-nr"];
      o && t.push(o);
     }
     return t;
    }
    return a.from(e);
   }
  });
 }
}, getSlotName = e => e["s-sn"] || 1 === e.nodeType && e.getAttribute("slot") || "", getHostSlotNode = (e, t) => {
 let a, o = 0;
 for (;o < e.length; o++) {
  if (a = e[o], a["s-sr"] && a["s-sn"] === t) return a;
  if (a = getHostSlotNode(a.childNodes, t), a) return a;
 }
 return null;
}, getHostSlotChildNodes = (e, t) => {
 const a = [ e ];
 for (;(e = e.nextSibling) && e["s-sn"] === t; ) a.push(e);
 return a;
}, addHostEventListeners = (e, t, a, o) => {
 appData.BUILD.hostListener && a && (appData.BUILD.hostListenerTargetParent && (a = o ? a.filter((([e]) => 32 & e)) : a.filter((([e]) => !(32 & e)))), 
 a.map((([a, o, s]) => {
  const n = appData.BUILD.hostListenerTarget ? getHostListenerTarget(e, a) : e, l = hostListenerProxy(t, s), r = hostListenerOpts(a);
  plt.ael(n, o, l, r), (t.$rmListeners$ = t.$rmListeners$ || []).push((() => plt.rel(n, o, l, r)));
 })));
}, hostListenerProxy = (e, t) => a => {
 try {
  appData.BUILD.lazyLoad ? 256 & e.$flags$ ? e.$lazyInstance$[t](a) : (e.$queuedListeners$ = e.$queuedListeners$ || []).push([ t, a ]) : e.$hostElement$[t](a);
 } catch (e) {
  consoleError(e);
 }
}, getHostListenerTarget = (e, t) => appData.BUILD.hostListenerTargetDocument && 4 & t ? doc : appData.BUILD.hostListenerTargetWindow && 8 & t ? win : appData.BUILD.hostListenerTargetBody && 16 & t ? doc.body : appData.BUILD.hostListenerTargetParent && 32 & t ? e.parentElement : e, hostListenerOpts = e => ({
 passive: 0 != (1 & e),
 capture: 0 != (2 & e)
}), parseVNodeAnnotations = (e, t, a, o) => {
 null != t && (null != t["s-nr"] && o.push(t), 1 === t.nodeType && t.childNodes.forEach((t => {
  const s = getHostRef(t);
  if (null != s && !a.staticComponents.has(t.nodeName.toLowerCase())) {
   const o = {
    nodeIds: 0
   };
   insertVNodeAnnotations(e, t, s.$vnode$, a, o);
  }
  parseVNodeAnnotations(e, t, a, o);
 })));
}, insertVNodeAnnotations = (e, t, a, o, s) => {
 if (null != a) {
  const n = ++o.hostIds;
  if (t.setAttribute("s-id", n), null != t["s-cr"] && (t["s-cr"].nodeValue = `r.${n}`), 
  null != a.$children$) {
   const t = 0;
   a.$children$.forEach(((a, o) => {
    insertChildVNodeAnnotations(e, a, s, n, t, o);
   }));
  }
  if (t && a && a.$elm$ && !t.hasAttribute("c-id")) {
   const e = t.parentElement;
   if (e && e.childNodes) {
    const o = Array.from(e.childNodes), s = o.find((e => 8 === e.nodeType && e["s-sr"]));
    if (s) {
     const e = o.indexOf(t) - 1;
     a.$elm$.setAttribute("c-id", `${s["s-host-id"]}.${s["s-node-id"]}.0.${e}`);
    }
   }
  }
 }
}, insertChildVNodeAnnotations = (e, t, a, o, s, n) => {
 const l = t.$elm$;
 if (null == l) return;
 const r = a.nodeIds++, p = `${o}.${r}.${s}.${n}`;
 if (l["s-host-id"] = o, l["s-node-id"] = r, 1 === l.nodeType) l.setAttribute("c-id", p); else if (3 === l.nodeType) {
  const t = l.parentNode, a = t.nodeName;
  if ("STYLE" !== a && "SCRIPT" !== a) {
   const a = `t.${p}`, o = e.createComment(a);
   t.insertBefore(o, l);
  }
 } else if (8 === l.nodeType && l["s-sr"]) {
  const e = `s.${p}.${l["s-sn"] || ""}`;
  l.nodeValue = e;
 }
 if (null != t.$children$) {
  const n = s + 1;
  t.$children$.forEach(((t, s) => {
   insertChildVNodeAnnotations(e, t, a, o, n, s);
  }));
 }
}, getHostRef = e => hostRefs.get(e), registerHost = (e, t) => {
 const a = {
  $flags$: 0,
  $hostElement$: e,
  $cmpMeta$: t,
  $instanceValues$: new Map,
  $renderCount$: 0
 };
 a.$onInstancePromise$ = new Promise((e => a.$onInstanceResolve$ = e)), a.$onReadyPromise$ = new Promise((e => a.$onReadyResolve$ = e)), 
 e["s-p"] = [], e["s-rc"] = [], addHostEventListeners(e, a, t.$listeners$, !1), hostRefs.set(e, a);
};

let customError;

const defaultConsoleError = e => {
 caughtErrors.push(e);
}, consoleError = (e, t) => (customError || defaultConsoleError)(e, t), consoleDevError = (...e) => {
 caughtErrors.push(new Error(e.join(", ")));
}, consoleDevWarn = (...e) => {
 const t = e.filter((e => "string" == typeof e || "number" == typeof e || "boolean" == typeof e));
 console.warn(...t);
}, nextTick = e => {
 queuedTicks.push(e);
}, win = mockDoc.setupGlobal(global), doc = win.document;

exports.supportsShadow = !0;

const plt = {
 $flags$: 0,
 $resourcesUrl$: "",
 jmp: e => e(),
 raf: e => requestAnimationFrame(e),
 ael: (e, t, a, o) => e.addEventListener(t, a, o),
 rel: (e, t, a, o) => e.removeEventListener(t, a, o),
 ce: (e, t) => new win.CustomEvent(e, t)
}, Context = {};

let autoApplyTimer, isAutoApplyingChanges = !1;

const isMemberInElement = (e, t) => {
 if (null != e) {
  if (t in e) return !0;
  const a = e.nodeName;
  if (a) {
   const e = cstrs.get(a.toLowerCase());
   if (null != e && null != e.COMPILER_META && null != e.COMPILER_META.properties) return e.COMPILER_META.properties.some((e => e.name === t));
  }
 }
 return !1;
};

Object.defineProperty(exports, "Env", {
 enumerable: !0,
 get: function() {
  return appData.Env;
 }
}), exports.Build = {
 isDev: !0,
 isBrowser: !1,
 isServer: !0,
 isTesting: !0
}, exports.Context = Context, exports.Fragment = (e, t) => t, exports.Host = Host, 
exports.addHostEventListeners = addHostEventListeners, exports.bootstrapLazy = (e, t = {}) => {
 var a;
 appData.BUILD.profile && performance.mark && performance.mark("st:app:start"), (() => {
  if (appData.BUILD.devTools) {
   const e = win.stencil = win.stencil || {}, t = e.inspect;
   e.inspect = e => {
    let a = (e => {
     const t = getHostRef(e);
     if (!t) return;
     const a = t.$flags$, o = t.$hostElement$;
     return {
      renderCount: t.$renderCount$,
      flags: {
       hasRendered: !!(2 & a),
       hasConnected: !!(1 & a),
       isWaitingForChildren: !!(4 & a),
       isConstructingInstance: !!(8 & a),
       isQueuedForUpdate: !!(16 & a),
       hasInitializedComponent: !!(32 & a),
       hasLoadedComponent: !!(64 & a),
       isWatchReady: !!(128 & a),
       isListenReady: !!(256 & a),
       needsRerender: !!(512 & a)
      },
      instanceValues: t.$instanceValues$,
      ancestorComponent: t.$ancestorComponent$,
      hostElement: o,
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
      "s-id": o["s-id"],
      "s-cr": o["s-cr"],
      "s-lr": o["s-lr"],
      "s-p": o["s-p"],
      "s-rc": o["s-rc"],
      "s-sc": o["s-sc"]
     };
    })(e);
    return a || "function" != typeof t || (a = t(e)), a;
   };
  }
 })();
 const o = createTime("bootstrapLazy"), s = [], n = t.exclude || [], l = win.customElements, r = doc.head, p = r.querySelector("meta[charset]"), i = doc.createElement("style"), d = [], c = doc.querySelectorAll("[sty-id]");
 let $, u = !0, m = 0;
 if (Object.assign(plt, t), plt.$resourcesUrl$ = new URL(t.resourcesUrl || "./", doc.baseURI).href, 
 appData.BUILD.asyncQueue && t.syncQueue && (plt.$flags$ |= 4), appData.BUILD.hydrateClientSide && (plt.$flags$ |= 2), 
 appData.BUILD.hydrateClientSide && appData.BUILD.shadowDom) for (;m < c.length; m++) registerStyle(c[m].getAttribute("sty-id"), c[m].innerHTML.replace(/\/\*!@([^\/]+)\*\/[^\{]+\{/g, "$1{"));
 if (e.map((e => {
  e[1].map((a => {
   const o = {
    $flags$: a[0],
    $tagName$: a[1],
    $members$: a[2],
    $listeners$: a[3]
   };
   appData.BUILD.member && (o.$members$ = a[2]), appData.BUILD.hostListener && (o.$listeners$ = a[3]), 
   appData.BUILD.reflect && (o.$attrsToReflect$ = []), appData.BUILD.watchCallback && (o.$watchers$ = {}), 
   appData.BUILD.shadowDom && !exports.supportsShadow && 1 & o.$flags$ && (o.$flags$ |= 8);
   const r = appData.BUILD.transformTagName && t.transformTagName ? t.transformTagName(o.$tagName$) : o.$tagName$, p = class extends HTMLElement {
    constructor(e) {
     super(e), registerHost(e = this, o), appData.BUILD.shadowDom && 1 & o.$flags$ && (exports.supportsShadow ? appData.BUILD.shadowDelegatesFocus ? e.attachShadow({
      mode: "open",
      delegatesFocus: !!(16 & o.$flags$)
     }) : e.attachShadow({
      mode: "open"
     }) : appData.BUILD.hydrateServerSide || "shadowRoot" in e || (e.shadowRoot = e)), 
     appData.BUILD.slotChildNodesFix && patchChildSlotNodes(e, o);
    }
    connectedCallback() {
     $ && (clearTimeout($), $ = null), u ? d.push(this) : plt.jmp((() => connectedCallback(this)));
    }
    disconnectedCallback() {
     plt.jmp((() => disconnectedCallback(this)));
    }
    componentOnReady() {
     return getHostRef(this).$onReadyPromise$;
    }
   };
   appData.BUILD.cloneNodeFix && patchCloneNode(p.prototype), appData.BUILD.appendChildSlotFix && patchSlotAppendChild(p.prototype), 
   appData.BUILD.hotModuleReplacement && (p.prototype["s-hmr"] = function(e) {
    ((e, t, a) => {
     const o = getHostRef(e);
     o.$flags$ = 1, e["s-hmr-load"] = () => {
      delete e["s-hmr-load"];
     }, initializeComponent(e, o, t);
    })(this, o);
   }), appData.BUILD.scopedSlotTextContentFix && patchTextContent(p.prototype, o), 
   o.$lazyBundleId$ = e[0], n.includes(r) || l.get(r) || (s.push(r), l.define(r, proxyComponent(p, o, 1)));
  }));
 })), appData.BUILD.invisiblePrehydration && (appData.BUILD.hydratedClass || appData.BUILD.hydratedAttribute)) {
  i.innerHTML = s + "{visibility:hidden}.hydrated{visibility:inherit}", i.setAttribute("data-styles", "");
  const e = null !== (a = plt.$nonce$) && void 0 !== a ? a : queryNonceMetaTagContent(doc);
  null != e && i.setAttribute("nonce", e), r.insertBefore(i, p ? p.nextSibling : r.firstChild);
 }
 u = !1, d.length ? d.map((e => e.connectedCallback())) : appData.BUILD.profile ? plt.jmp((() => $ = setTimeout(appDidLoad, 30, "timeout"))) : plt.jmp((() => $ = setTimeout(appDidLoad, 30))), 
 o();
}, exports.connectedCallback = connectedCallback, exports.consoleDevError = consoleDevError, 
exports.consoleDevInfo = (...e) => {}, exports.consoleDevWarn = consoleDevWarn, 
exports.consoleError = consoleError, exports.createEvent = (e, t, a) => {
 const o = getElement(e);
 return {
  emit: e => (appData.BUILD.isDev && !o.isConnected && consoleDevWarn(`The "${t}" event was emitted, but the dispatcher node is no longer connected to the dom.`), 
  emitEvent(o, t, {
   bubbles: !!(4 & a),
   composed: !!(2 & a),
   cancelable: !!(1 & a),
   detail: e
  }))
 };
}, exports.defineCustomElement = (e, t) => {
 customElements.define(t[1], proxyCustomElement(e, t));
}, exports.disconnectedCallback = disconnectedCallback, exports.doc = doc, exports.flushAll = flushAll, 
exports.flushLoadModule = flushLoadModule, exports.flushQueue = flushQueue, exports.forceModeUpdate = e => {
 if (appData.BUILD.style && appData.BUILD.mode && !appData.BUILD.lazyLoad) {
  const t = computeMode(e), a = getHostRef(e);
  if (a.$modeName$ !== t) {
   const o = a.$cmpMeta$, s = e["s-sc"], n = getScopeId(o, t), l = e.constructor.style[t];
   o.$flags$, l && (styles.has(n) || registerStyle(n, l), a.$modeName$ = t, e.classList.remove(s + "-h", s + "-s"), 
   attachStyles(a), forceUpdate(e));
  }
 }
}, exports.forceUpdate = forceUpdate, exports.getAssetPath = getAssetPath, exports.getConnect = (e, t) => {
 const a = () => {
  let e = doc.querySelector(t);
  return e || (e = doc.createElement(t), doc.body.appendChild(e)), "function" == typeof e.componentOnReady ? e.componentOnReady() : Promise.resolve(e);
 };
 return {
  create: (...e) => a().then((t => t.create(...e))),
  componentOnReady: a
 };
}, exports.getContext = (e, t) => t in Context ? Context[t] : "window" === t ? win : "document" === t ? doc : "isServer" === t || "isPrerender" === t ? !!appData.BUILD.hydrateServerSide : "isClient" === t ? !appData.BUILD.hydrateServerSide : "resourcesUrl" === t || "publicPath" === t ? getAssetPath(".") : "queue" === t ? {
 write: writeTask,
 read: readTask,
 tick: {
  then: e => nextTick(e)
 }
} : void 0, exports.getElement = getElement, exports.getHostRef = getHostRef, exports.getMode = e => getHostRef(e).$modeName$, 
exports.getRenderingRef = () => renderingRef, exports.getValue = getValue, exports.h = h, 
exports.insertVdomAnnotations = (e, t) => {
 if (null != e) {
  const a = {
   hostIds: 0,
   rootLevelIds: 0,
   staticComponents: new Set(t)
  }, o = [];
  parseVNodeAnnotations(e, e.body, a, o), o.forEach((t => {
   if (null != t) {
    const o = t["s-nr"];
    let s = o["s-host-id"], n = o["s-node-id"], l = `${s}.${n}`;
    if (null == s) if (s = 0, a.rootLevelIds++, n = a.rootLevelIds, l = `${s}.${n}`, 
    1 === o.nodeType) o.setAttribute("c-id", l); else if (3 === o.nodeType) {
     if (0 === s && "" === o.nodeValue.trim()) return void t.remove();
     const a = e.createComment(l);
     a.nodeValue = `t.${l}`, o.parentNode.insertBefore(a, o);
    }
    let r = `o.${l}`;
    const p = t.parentElement;
    p && ("" === p["s-en"] ? r += "." : "c" === p["s-en"] && (r += ".c")), t.nodeValue = r;
   }
  }));
 }
}, exports.isMemberInElement = isMemberInElement, exports.loadModule = loadModule, 
exports.modeResolutionChain = modeResolutionChain, exports.nextTick = nextTick, 
exports.parsePropertyValue = parsePropertyValue, exports.plt = plt, exports.postUpdateComponent = postUpdateComponent, 
exports.proxyComponent = proxyComponent, exports.proxyCustomElement = proxyCustomElement, 
exports.readTask = readTask, exports.registerComponents = e => {
 e.forEach((e => {
  cstrs.set(e.COMPILER_META.tagName, e);
 }));
}, exports.registerContext = function registerContext(e) {
 e && Object.assign(Context, e);
}, exports.registerHost = registerHost, exports.registerInstance = (e, t) => {
 if (null == e || null == e.constructor) throw new Error("Invalid component constructor");
 if (null == t) {
  const a = e.constructor, o = a.COMPILER_META && a.COMPILER_META.tagName ? a.COMPILER_META.tagName : "div", s = document.createElement(o);
  registerHost(s, {
   $flags$: 0,
   $tagName$: o
  }), t = getHostRef(s);
 }
 return t.$lazyInstance$ = e, hostRefs.set(e, t);
}, exports.registerModule = function registerModule(e, t) {
 moduleLoaded.set(e, t);
}, exports.renderVdom = renderVdom, exports.resetPlatform = function resetPlatform(e = {}) {
 win && "function" == typeof win.close && win.close(), hostRefs.clear(), styles.clear(), 
 plt.$flags$ = 0, Object.keys(Context).forEach((e => delete Context[e])), Object.assign(plt, e), 
 null != plt.$orgLocNodes$ && (plt.$orgLocNodes$.clear(), plt.$orgLocNodes$ = void 0), 
 win.location.href = plt.$resourcesUrl$ = "http://testing.stenciljs.com/", function t() {
  queuedTicks.length = 0, queuedWriteTasks.length = 0, queuedReadTasks.length = 0, 
  moduleLoaded.clear(), queuedLoadModules.length = 0, caughtErrors.length = 0;
 }(), stopAutoApplyChanges(), cstrs.clear();
}, exports.setAssetPath = e => plt.$resourcesUrl$ = e, exports.setErrorHandler = e => customError = e, 
exports.setMode = e => modeResolutionChain.push(e), exports.setNonce = e => plt.$nonce$ = e, 
exports.setPlatformHelpers = e => {
 Object.assign(plt, e);
}, exports.setPlatformOptions = e => Object.assign(plt, e), exports.setSupportsShadowDom = e => {
 exports.supportsShadow = e;
}, exports.setValue = setValue, exports.startAutoApplyChanges = async function e() {
 isAutoApplyingChanges = !0, flushAll().then((() => {
  isAutoApplyingChanges && (autoApplyTimer = setTimeout((() => {
   e();
  }), 100));
 }));
}, exports.stopAutoApplyChanges = stopAutoApplyChanges, exports.styles = styles, 
exports.supportsConstructableStylesheets = !1, exports.supportsListenerOptions = !0, 
exports.win = win, exports.writeTask = writeTask;