const _parenSuffix = ")(?:\\(((?:\\([^)(]*\\)|[^)(]*)+?)\\))?([^,{]*)", _cssColonHostRe = new RegExp("(-shadowcsshost" + _parenSuffix, "gim"), _cssColonHostContextRe = new RegExp("(-shadowcsscontext" + _parenSuffix, "gim"), _cssColonSlottedRe = new RegExp("(-shadowcssslotted" + _parenSuffix, "gim"), _polyfillHostNoCombinatorRe = /-shadowcsshost-no-combinator([^\s]*)/, _shadowDOMSelectorsRe = [ /::shadow/g, /::content/g ], _polyfillHostRe = /-shadowcsshost/gim, _colonHostRe = /:host/gim, _colonSlottedRe = /::slotted/gim, _colonHostContextRe = /:host-context/gim, _commentRe = /\/\*\s*[\s\S]*?\*\//g, _commentWithHashRe = /\/\*\s*#\s*source(Mapping)?URL=[\s\S]+?\*\//g, _ruleRe = /(\s*)([^;\{\}]+?)(\s*)((?:{%BLOCK%}?\s*;?)|(?:\s*;))/g, _curlyRe = /([{}])/g, _selectorPartsRe = /(^.*?[^\\])??((:+)(.*)|$)/, processRules = (e, t) => {
 const o = escapeBlocks(e);
 let s = 0;
 return o.escapedString.replace(_ruleRe, ((...e) => {
  const c = e[2];
  let r = "", n = e[4], l = "";
  n && n.startsWith("{%BLOCK%") && (r = o.blocks[s++], n = n.substring("%BLOCK%".length + 1), 
  l = "{");
  const a = t({
   selector: c,
   content: r
  });
  return `${e[1]}${a.selector}${e[3]}${l}${a.content}${n}`;
 }));
}, escapeBlocks = e => {
 const t = e.split(_curlyRe), o = [], s = [];
 let c = 0, r = [];
 for (let e = 0; e < t.length; e++) {
  const n = t[e];
  "}" === n && c--, c > 0 ? r.push(n) : (r.length > 0 && (s.push(r.join("")), o.push("%BLOCK%"), 
  r = []), o.push(n)), "{" === n && c++;
 }
 return r.length > 0 && (s.push(r.join("")), o.push("%BLOCK%")), {
  escapedString: o.join(""),
  blocks: s
 };
}, convertColonRule = (e, t, o) => e.replace(t, ((...e) => {
 if (e[2]) {
  const t = e[2].split(","), s = [];
  for (let c = 0; c < t.length; c++) {
   const r = t[c].trim();
   if (!r) break;
   s.push(o("-shadowcsshost-no-combinator", r, e[3]));
  }
  return s.join(",");
 }
 return "-shadowcsshost-no-combinator" + e[3];
})), colonHostPartReplacer = (e, t, o) => e + t.replace("-shadowcsshost", "") + o, colonHostContextPartReplacer = (e, t, o) => t.indexOf("-shadowcsshost") > -1 ? colonHostPartReplacer(e, t, o) : e + t + o + ", " + t + " " + e + o, injectScopingSelector = (e, t) => e.replace(_selectorPartsRe, ((e, o = "", s, c = "", r = "") => o + t + c + r)), scopeSelectors = (e, t, o, s, c) => processRules(e, (e => {
 let c = e.selector, r = e.content;
 return "@" !== e.selector[0] ? c = ((e, t, o, s) => e.split(",").map((e => s && e.indexOf("." + s) > -1 ? e.trim() : ((e, t) => !(e => (e = e.replace(/\[/g, "\\[").replace(/\]/g, "\\]"), 
 new RegExp("^(" + e + ")([>\\s~+[.,{:][\\s\\S]*)?$", "m")))(t).test(e))(e, t) ? ((e, t, o) => {
  const s = "." + (t = t.replace(/\[is=([^\]]*)\]/g, ((e, ...t) => t[0]))), c = e => {
   let c = e.trim();
   if (!c) return "";
   if (e.indexOf("-shadowcsshost-no-combinator") > -1) c = ((e, t, o) => {
    if (_polyfillHostRe.lastIndex = 0, _polyfillHostRe.test(e)) {
     const t = `.${o}`;
     return e.replace(_polyfillHostNoCombinatorRe, ((e, o) => injectScopingSelector(o, t))).replace(_polyfillHostRe, t + " ");
    }
    return t + " " + e;
   })(e, t, o); else {
    const t = e.replace(_polyfillHostRe, "");
    t.length > 0 && (c = injectScopingSelector(t, s));
   }
   return c;
  }, r = (e => {
   const t = [];
   let o = 0;
   return {
    content: (e = e.replace(/(\[[^\]]*\])/g, ((e, s) => {
     const c = `__ph-${o}__`;
     return t.push(s), o++, c;
    }))).replace(/(:nth-[-\w]+)(\([^)]+\))/g, ((e, s, c) => {
     const r = `__ph-${o}__`;
     return t.push(c), o++, s + r;
    })),
    placeholders: t
   };
  })(e);
  let n, l = "", a = 0;
  const i = /( |>|\+|~(?!=))\s*/g;
  let p = !((e = r.content).indexOf("-shadowcsshost-no-combinator") > -1);
  for (;null !== (n = i.exec(e)); ) {
   const t = n[1], o = e.slice(a, n.index).trim();
   p = p || o.indexOf("-shadowcsshost-no-combinator") > -1, l += `${p ? c(o) : o} ${t} `, 
   a = i.lastIndex;
  }
  const h = e.substring(a);
  return p = p || h.indexOf("-shadowcsshost-no-combinator") > -1, l += p ? c(h) : h, 
  u = r.placeholders, l.replace(/__ph-(\d+)__/g, ((e, t) => u[+t]));
  var u;
 })(e, t, o).trim() : e.trim())).join(", "))(e.selector, t, o, s) : (e.selector.startsWith("@media") || e.selector.startsWith("@supports") || e.selector.startsWith("@page") || e.selector.startsWith("@document")) && (r = scopeSelectors(e.content, t, o, s)), 
 {
  selector: c.replace(/\s{2,}/g, " ").trim(),
  content: r
 };
})), scopeCss = (e, t, o) => {
 const s = t + "-h", c = t + "-s", r = e.match(_commentWithHashRe) || [];
 e = e.replace(_commentRe, "");
 const n = [];
 if (o) {
  const t = e => {
   const t = `/*!@___${n.length}___*/`, o = `/*!@${e.selector}*/`;
   return n.push({
    placeholder: t,
    comment: o
   }), e.selector = t + e.selector, e;
  };
  e = processRules(e, (e => "@" !== e.selector[0] ? t(e) : e.selector.startsWith("@media") || e.selector.startsWith("@supports") || e.selector.startsWith("@page") || e.selector.startsWith("@document") ? (e.content = processRules(e.content, t), 
  e) : e));
 }
 const l = ((e, t, o, s, c) => {
  const r = ((e, t) => {
   const o = "." + t + " > ", s = [];
   return e = e.replace(_cssColonSlottedRe, ((...e) => {
    if (e[2]) {
     const t = e[2].trim(), c = e[3], r = o + t + c;
     let n = "";
     for (let t = e[4] - 1; t >= 0; t--) {
      const o = e[5][t];
      if ("}" === o || "," === o) break;
      n = o + n;
     }
     const l = n + r, a = `${n.trimRight()}${r.trim()}`;
     if (l.trim() !== a.trim()) {
      const e = `${a}, ${l}`;
      s.push({
       orgSelector: l,
       updatedSelector: e
      });
     }
     return r;
    }
    return "-shadowcsshost-no-combinator" + e[3];
   })), {
    selectors: s,
    cssText: e
   };
  })(e = (e => convertColonRule(e, _cssColonHostContextRe, colonHostContextPartReplacer))(e = (e => convertColonRule(e, _cssColonHostRe, colonHostPartReplacer))(e = e.replace(_colonHostContextRe, "-shadowcsscontext").replace(_colonHostRe, "-shadowcsshost").replace(_colonSlottedRe, "-shadowcssslotted"))), s);
  return e = (e => _shadowDOMSelectorsRe.reduce(((e, t) => e.replace(t, " ")), e))(e = r.cssText), 
  t && (e = scopeSelectors(e, t, o, s)), {
   cssText: (e = (e = e.replace(/-shadowcsshost-no-combinator/g, `.${o}`)).replace(/>\s*\*\s+([^{, ]+)/gm, " $1 ")).trim(),
   slottedSelectors: r.selectors
  };
 })(e, t, s, c);
 return e = [ l.cssText, ...r ].join("\n"), o && n.forEach((({placeholder: t, comment: o}) => {
  e = e.replace(t, o);
 })), l.slottedSelectors.forEach((t => {
  e = e.replace(t.orgSelector, t.updatedSelector);
 })), e;
};

export { scopeCss };