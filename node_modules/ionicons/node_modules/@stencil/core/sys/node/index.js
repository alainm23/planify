/*!
 Stencil Node System v2.22.3 | MIT Licensed | https://stenciljs.com
 */
function _interopDefaultLegacy(e) {
 return e && "object" == typeof e && "default" in e ? e : {
  default: e
 };
}

function _interopNamespace(e) {
 if (e && e.__esModule) return e;
 var t = Object.create(null);
 return e && Object.keys(e).forEach((function(r) {
  if ("default" !== r) {
   var n = Object.getOwnPropertyDescriptor(e, r);
   Object.defineProperty(t, r, n.get ? n : {
    enumerable: !0,
    get: function() {
     return e[r];
    }
   });
  }
 })), t.default = e, t;
}

function createCommonjsModule(e, t, r) {
 return e(r = {
  path: t,
  exports: {},
  require: function(e, t) {
   return function r() {
    throw new Error("Dynamic requires are not currently supported by @rollup/plugin-commonjs");
   }();
  }
 }, r.exports), r.exports;
}

async function nodeCopyTasks(e, t) {
 const r = {
  diagnostics: [],
  dirPaths: [],
  filePaths: []
 };
 try {
  i = await Promise.all(e.map((e => async function r(e, t) {
   return (e => {
    const t = {
     "{": "}",
     "(": ")",
     "[": "]"
    }, r = /\\(.)|(^!|\*|[\].+)]\?|\[[^\\\]]+\]|\{[^\\}]+\}|\(\?[:!=][^\\)]+\)|\([^|]+\|[^\\)]+\))/;
    if ("" === e) return !1;
    let n;
    for (;n = r.exec(e); ) {
     if (n[2]) return !0;
     let r = n.index + n[0].length;
     const i = n[1], s = i ? t[i] : null;
     if (i && s) {
      const t = e.indexOf(s, r);
      -1 !== t && (r = t + 1);
     }
     e = e.slice(r);
    }
    return !1;
   })(e.src) ? await async function r(e, t) {
    return (await asyncGlob(e.src, {
     cwd: t,
     nodir: !0
    })).map((r => function n(e, t, r) {
     const n = path__default.default.join(e.dest, e.keepDirStructure ? r : path__default.default.basename(r));
     return {
      src: path__default.default.join(t, r),
      dest: n,
      warn: e.warn,
      keepDirStructure: e.keepDirStructure
     };
    }(e, t, r)));
   }(e, t) : [ {
    src: getSrcAbsPath(t, e.src),
    dest: e.keepDirStructure ? path__default.default.join(e.dest, e.src) : e.dest,
    warn: e.warn,
    keepDirStructure: e.keepDirStructure
   } ];
  }(e, t)))), e = i.flat ? i.flat(1) : i.reduce(((e, t) => (e.push(...t), e)), []);
  const n = [];
  for (;e.length > 0; ) {
   const t = e.splice(0, 100);
   await Promise.all(t.map((e => processCopyTask(r, n, e))));
  }
  const s = function n(e) {
   const t = [];
   return e.forEach((e => {
    !function r(e, t) {
     (t = normalizePath(t)) !== ROOT_DIR && t + "/" !== ROOT_DIR && "" !== t && (e.includes(t) || e.push(t));
    }(t, path__default.default.dirname(e.dest));
   })), t.sort(((e, t) => {
    const r = e.split("/").length, n = t.split("/").length;
    return r < n ? -1 : r > n ? 1 : e < t ? -1 : e > t ? 1 : 0;
   })), t;
  }(n);
  try {
   await Promise.all(s.map((e => mkdir(e, {
    recursive: !0
   }))));
  } catch (e) {}
  for (;n.length > 0; ) {
   const e = n.splice(0, 100);
   await Promise.all(e.map((e => copyFile(e.src, e.dest))));
  }
 } catch (e) {
  catchError(r.diagnostics, e);
 }
 var i;
 return r;
}

function getSrcAbsPath(e, t) {
 return path__default.default.isAbsolute(t) ? t : path__default.default.join(e, t);
}

async function processCopyTask(e, t, r) {
 try {
  r.src = normalizePath(r.src), r.dest = normalizePath(r.dest), (await stat(r.src)).isDirectory() ? (e.dirPaths.includes(r.dest) || e.dirPaths.push(r.dest), 
  await async function n(e, t, r) {
   try {
    const n = await readdir(r.src);
    await Promise.all(n.map((async n => {
     const i = {
      src: path__default.default.join(r.src, n),
      dest: path__default.default.join(r.dest, n),
      warn: r.warn
     };
     await processCopyTask(e, t, i);
    })));
   } catch (t) {
    catchError(e.diagnostics, t);
   }
  }(e, t, r)) : function i(e) {
   return e = e.trim().toLowerCase(), IGNORE.some((t => e.endsWith(t)));
  }(r.src) || (e.filePaths.includes(r.dest) || e.filePaths.push(r.dest), t.push(r));
 } catch (t) {
  if (!1 !== r.warn) {
   const r = buildError(e.diagnostics);
   t instanceof Error && (r.messageText = t.message);
  }
 }
}

function asyncGlob(e, t) {
 return new Promise(((r, n) => {
  (0, glob__default.default.glob)(e, t, ((e, t) => {
   e ? n(e) : r(t);
  }));
 }));
}

function Yallist(e) {
 var t, r, n = this;
 if (n instanceof Yallist || (n = new Yallist), n.tail = null, n.head = null, n.length = 0, 
 e && "function" == typeof e.forEach) e.forEach((function(e) {
  n.push(e);
 })); else if (arguments.length > 0) for (t = 0, r = arguments.length; t < r; t++) n.push(arguments[t]);
 return n;
}

function insert(e, t, r) {
 var n = t === e.head ? new Node(r, null, t, e) : new Node(r, t, t.next, e);
 return null === n.next && (e.tail = n), null === n.prev && (e.head = n), e.length++, 
 n;
}

function push(e, t) {
 e.tail = new Node(t, e.tail, null, e), e.head || (e.head = e.tail), e.length++;
}

function unshift(e, t) {
 e.head = new Node(t, null, e.head, e), e.tail || (e.tail = e.head), e.length++;
}

function Node(e, t, r, n) {
 if (!(this instanceof Node)) return new Node(e, t, r, n);
 this.list = n, this.value = e, t ? (t.next = this, this.prev = t) : this.prev = null, 
 r ? (r.prev = this, this.next = r) : this.next = null;
}

async function checkVersion(e, t) {
 try {
  const r = await async function r(e) {
   try {
    const e = await function t() {
     return new Promise((e => {
      fs__default.default.readFile(getLastCheckStoragePath(), "utf8", ((t, r) => {
       if (!t && isString(r)) try {
        e(JSON.parse(r));
       } catch (e) {}
       e(null);
      }));
     }));
    }();
    if (null == e) return setLastCheck(), null;
    if (!function r(e, t, n) {
     return t + n < e;
    }(Date.now(), e, 6048e5)) return null;
    const t = setLastCheck(), r = await async function n(e) {
     const t = await Promise.resolve().then((function() {
      return _interopNamespace(require("https"));
     }));
     return new Promise(((r, n) => {
      const i = t.request(e, (t => {
       if (t.statusCode > 299) return void n(`url: ${e}, staus: ${t.statusCode}`);
       t.once("error", n);
       const i = [];
       t.once("end", (() => {
        r(i.join(""));
       })), t.on("data", (e => {
        i.push(e);
       }));
      }));
      i.once("error", n), i.end();
     }));
    }(REGISTRY_URL), n = JSON.parse(r);
    return await t, n["dist-tags"].latest;
   } catch (t) {
    e.debug(`getLatestCompilerVersion error: ${t}`);
   }
   return null;
  }(e);
  if (null != r) return () => {
   lt_1(t, r) ? function n(e, t, r) {
    const n = "npm install @stencil/core", i = [ `Update available: ${t} ${ARROW} ${r}`, "To get the latest, please run:", n, CHANGELOG ], s = i.reduce(((e, t) => t.length > e ? t.length : e), 0), o = [];
    let a = BOX_TOP_LEFT;
    for (;a.length <= s + 2 * PADDING; ) a += BOX_HORIZONTAL;
    a += BOX_TOP_RIGHT, o.push(a), i.forEach((e => {
     let t = BOX_VERTICAL;
     for (let e = 0; e < PADDING; e++) t += " ";
     for (t += e; t.length <= s + 2 * PADDING; ) t += " ";
     t += BOX_VERTICAL, o.push(t);
    }));
    let l = BOX_BOTTOM_LEFT;
    for (;l.length <= s + 2 * PADDING; ) l += BOX_HORIZONTAL;
    l += BOX_BOTTOM_RIGHT, o.push(l);
    let c = `${INDENT}${o.join(`\n${INDENT}`)}\n`;
    c = c.replace(t, e.red(t)), c = c.replace(r, e.green(r)), c = c.replace(n, e.cyan(n)), 
    c = c.replace(CHANGELOG, e.dim(CHANGELOG)), console.log(c);
   }(e, t, r) : console.debug(`${e.cyan("@stencil/core")} version ${e.green(t)} is the latest version`);
  };
 } catch (t) {
  e.debug(`unable to load latest compiler version: ${t}`);
 }
 return noop;
}

function setLastCheck() {
 return new Promise((e => {
  const t = JSON.stringify(Date.now());
  fs__default.default.writeFile(getLastCheckStoragePath(), t, (() => {
   e();
  }));
 }));
}

function getLastCheckStoragePath() {
 return path__default.default.join(require$$6.tmpdir(), "stencil_last_version_node.json");
}

function getNextWorker(e) {
 const t = e.filter((e => !e.stopped));
 return 0 === t.length ? null : t.sort(((e, t) => e.tasks.size < t.tasks.size ? -1 : e.tasks.size > t.tasks.size ? 1 : e.totalTasksAssigned < t.totalTasksAssigned ? -1 : e.totalTasksAssigned > t.totalTasksAssigned ? 1 : 0))[0];
}

var symbols, ansiColors, create_1, lockfile, exit, debug_1, constants, re_1, parseOptions_1, identifiers, semver, compare_1, lte_1, major_1, iterator, yallist, lruCache, eq_1, neq_1, gt_1, gte_1, lt_1, cmp_1, comparator, range, satisfies_1;

Object.defineProperty(exports, "__esModule", {
 value: !0
});

const fs = require("./graceful-fs.js"), path = require("path"), require$$1 = require("util"), require$$2 = require("fs"), require$$3 = require("crypto"), require$$4 = require("stream"), require$$5 = require("assert"), require$$6 = require("os"), require$$7 = require("events"), require$$8 = require("buffer"), require$$9 = require("tty"), glob = require("./glob.js"), cp = require("child_process"), fs__default = _interopDefaultLegacy(fs), path__default = _interopDefaultLegacy(path), require$$1__default = _interopDefaultLegacy(require$$1), require$$2__default = _interopDefaultLegacy(require$$2), require$$3__default = _interopDefaultLegacy(require$$3), require$$4__default = _interopDefaultLegacy(require$$4), require$$5__default = _interopDefaultLegacy(require$$5), require$$6__default = _interopDefaultLegacy(require$$6), require$$6__namespace = _interopNamespace(require$$6), require$$7__default = _interopDefaultLegacy(require$$7), require$$8__default = _interopDefaultLegacy(require$$8), require$$9__default = _interopDefaultLegacy(require$$9), glob__default = _interopDefaultLegacy(glob), cp__namespace = _interopNamespace(cp);

symbols = createCommonjsModule((function(e) {
 const t = "undefined" != typeof process && "Hyper" === process.env.TERM_PROGRAM, r = "undefined" != typeof process && "win32" === process.platform, n = "undefined" != typeof process && "linux" === process.platform, i = {
  ballotDisabled: "☒",
  ballotOff: "☐",
  ballotOn: "☑",
  bullet: "•",
  bulletWhite: "◦",
  fullBlock: "█",
  heart: "❤",
  identicalTo: "≡",
  line: "─",
  mark: "※",
  middot: "·",
  minus: "－",
  multiplication: "×",
  obelus: "÷",
  pencilDownRight: "✎",
  pencilRight: "✏",
  pencilUpRight: "✐",
  percent: "%",
  pilcrow2: "❡",
  pilcrow: "¶",
  plusMinus: "±",
  question: "?",
  section: "§",
  starsOff: "☆",
  starsOn: "★",
  upDownArrow: "↕"
 }, s = Object.assign({}, i, {
  check: "√",
  cross: "×",
  ellipsisLarge: "...",
  ellipsis: "...",
  info: "i",
  questionSmall: "?",
  pointer: ">",
  pointerSmall: "»",
  radioOff: "( )",
  radioOn: "(*)",
  warning: "‼"
 }), o = Object.assign({}, i, {
  ballotCross: "✘",
  check: "✔",
  cross: "✖",
  ellipsisLarge: "⋯",
  ellipsis: "…",
  info: "ℹ",
  questionFull: "？",
  questionSmall: "﹖",
  pointer: n ? "▸" : "❯",
  pointerSmall: n ? "‣" : "›",
  radioOff: "◯",
  radioOn: "◉",
  warning: "⚠"
 });
 e.exports = r && !t ? s : o, Reflect.defineProperty(e.exports, "common", {
  enumerable: !1,
  value: i
 }), Reflect.defineProperty(e.exports, "windows", {
  enumerable: !1,
  value: s
 }), Reflect.defineProperty(e.exports, "other", {
  enumerable: !1,
  value: o
 });
}));

const ANSI_REGEX = /[\u001b\u009b][[\]#;?()]*(?:(?:(?:[^\W_]*;?[^\W_]*)\u0007)|(?:(?:[0-9]{1,4}(;[0-9]{0,4})*)?[~0-9=<>cf-nqrtyA-PRZ]))/g, create = () => {
 const e = {
  enabled: "undefined" != typeof process && "0" !== process.env.FORCE_COLOR,
  visible: !0,
  styles: {},
  keys: {}
 }, t = (e, t, r) => "function" == typeof e ? e(t) : e.wrap(t, r), r = (r, n) => {
  if ("" === r || null == r) return "";
  if (!1 === e.enabled) return r;
  if (!1 === e.visible) return "";
  let i = "" + r, s = i.includes("\n"), o = n.length;
  for (o > 0 && n.includes("unstyle") && (n = [ ...new Set([ "unstyle", ...n ]) ].reverse()); o-- > 0; ) i = t(e.styles[n[o]], i, s);
  return i;
 }, n = (t, n, i) => {
  e.styles[t] = (e => {
   let t = e.open = `[${e.codes[0]}m`, r = e.close = `[${e.codes[1]}m`, n = e.regex = new RegExp(`\\u001b\\[${e.codes[1]}m`, "g");
   return e.wrap = (e, i) => {
    e.includes(r) && (e = e.replace(n, r + t));
    let s = t + e + r;
    return i ? s.replace(/\r*\n/g, `${r}$&${t}`) : s;
   }, e;
  })({
   name: t,
   codes: n
  }), (e.keys[i] || (e.keys[i] = [])).push(t), Reflect.defineProperty(e, t, {
   configurable: !0,
   enumerable: !0,
   set(r) {
    e.alias(t, r);
   },
   get() {
    let n = e => r(e, n.stack);
    return Reflect.setPrototypeOf(n, e), n.stack = this.stack ? this.stack.concat(t) : [ t ], 
    n;
   }
  });
 };
 return n("reset", [ 0, 0 ], "modifier"), n("bold", [ 1, 22 ], "modifier"), n("dim", [ 2, 22 ], "modifier"), 
 n("italic", [ 3, 23 ], "modifier"), n("underline", [ 4, 24 ], "modifier"), n("inverse", [ 7, 27 ], "modifier"), 
 n("hidden", [ 8, 28 ], "modifier"), n("strikethrough", [ 9, 29 ], "modifier"), n("black", [ 30, 39 ], "color"), 
 n("red", [ 31, 39 ], "color"), n("green", [ 32, 39 ], "color"), n("yellow", [ 33, 39 ], "color"), 
 n("blue", [ 34, 39 ], "color"), n("magenta", [ 35, 39 ], "color"), n("cyan", [ 36, 39 ], "color"), 
 n("white", [ 37, 39 ], "color"), n("gray", [ 90, 39 ], "color"), n("grey", [ 90, 39 ], "color"), 
 n("bgBlack", [ 40, 49 ], "bg"), n("bgRed", [ 41, 49 ], "bg"), n("bgGreen", [ 42, 49 ], "bg"), 
 n("bgYellow", [ 43, 49 ], "bg"), n("bgBlue", [ 44, 49 ], "bg"), n("bgMagenta", [ 45, 49 ], "bg"), 
 n("bgCyan", [ 46, 49 ], "bg"), n("bgWhite", [ 47, 49 ], "bg"), n("blackBright", [ 90, 39 ], "bright"), 
 n("redBright", [ 91, 39 ], "bright"), n("greenBright", [ 92, 39 ], "bright"), n("yellowBright", [ 93, 39 ], "bright"), 
 n("blueBright", [ 94, 39 ], "bright"), n("magentaBright", [ 95, 39 ], "bright"), 
 n("cyanBright", [ 96, 39 ], "bright"), n("whiteBright", [ 97, 39 ], "bright"), n("bgBlackBright", [ 100, 49 ], "bgBright"), 
 n("bgRedBright", [ 101, 49 ], "bgBright"), n("bgGreenBright", [ 102, 49 ], "bgBright"), 
 n("bgYellowBright", [ 103, 49 ], "bgBright"), n("bgBlueBright", [ 104, 49 ], "bgBright"), 
 n("bgMagentaBright", [ 105, 49 ], "bgBright"), n("bgCyanBright", [ 106, 49 ], "bgBright"), 
 n("bgWhiteBright", [ 107, 49 ], "bgBright"), e.ansiRegex = ANSI_REGEX, e.hasColor = e.hasAnsi = t => (e.ansiRegex.lastIndex = 0, 
 "string" == typeof t && "" !== t && e.ansiRegex.test(t)), e.alias = (t, n) => {
  let i = "string" == typeof n ? e[n] : n;
  if ("function" != typeof i) throw new TypeError("Expected alias to be the name of an existing color (string) or a function");
  i.stack || (Reflect.defineProperty(i, "name", {
   value: t
  }), e.styles[t] = i, i.stack = [ t ]), Reflect.defineProperty(e, t, {
   configurable: !0,
   enumerable: !0,
   set(r) {
    e.alias(t, r);
   },
   get() {
    let t = e => r(e, t.stack);
    return Reflect.setPrototypeOf(t, e), t.stack = this.stack ? this.stack.concat(i.stack) : i.stack, 
    t;
   }
  });
 }, e.theme = t => {
  if (null === (r = t) || "object" != typeof r || Array.isArray(r)) throw new TypeError("Expected theme to be an object");
  var r;
  for (let r of Object.keys(t)) e.alias(r, t[r]);
  return e;
 }, e.alias("unstyle", (t => "string" == typeof t && "" !== t ? (e.ansiRegex.lastIndex = 0, 
 t.replace(e.ansiRegex, "")) : "")), e.alias("noop", (e => e)), e.none = e.clear = e.noop, 
 e.stripColor = e.unstyle, e.symbols = symbols, e.define = n, e;
};

ansiColors = create(), create_1 = create, ansiColors.create = create_1;

const LOG_LEVELS = [ "debug", "info", "warn", "error" ], createTerminalLogger = e => {
 let t = "info", r = null;
 const n = [], i = e => {
  if (e.length > 0) {
   const t = formatPrefixTimestamp();
   e[0] = ansiColors.dim(t) + e[0].slice(t.length);
  }
 }, s = e => {
  if (e.length) {
   const t = "[ WARN  ]";
   e[0] = ansiColors.bold(ansiColors.yellow(t)) + e[0].slice(t.length);
  }
 }, o = e => {
  if (e.length) {
   const t = "[ ERROR ]";
   e[0] = ansiColors.bold(ansiColors.red(t)) + e[0].slice(t.length);
  }
 }, a = e => {
  if (e.length) {
   const t = formatPrefixTimestamp();
   e[0] = ansiColors.cyan(t) + e[0].slice(t.length);
  }
 }, l = t => {
  const r = e.memoryUsage();
  r > 0 && t.push(ansiColors.dim(` MEM: ${(r / 1e6).toFixed(1)}MB`));
 }, c = (t, i) => {
  if (r) {
   const r = new Date, s = ("0" + r.getHours()).slice(-2) + ":" + ("0" + r.getMinutes()).slice(-2) + ":" + ("0" + r.getSeconds()).slice(-2) + ".0" + Math.floor(r.getMilliseconds() / 1e3 * 10) + "  " + ("000" + (e.memoryUsage() / 1e6).toFixed(1)).slice(-6) + "MB  " + t + "  " + i.join(", ");
   n.push(s);
  }
 }, u = (t, r, n) => {
  let i = t.length - r + n - 1;
  for (;t.length + INDENT$1.length > e.getColumns(); ) if (r > t.length - r + n && r > 5) t = t.slice(1), 
  r--; else {
   if (!(i > 1)) break;
   t = t.slice(0, -1), i--;
  }
  const s = [], o = Math.max(t.length, r + n);
  for (let e = 0; e < o; e++) {
   let i = t.charAt(e);
   e >= r && e < r + n && (i = ansiColors.bgRed("" === i ? " " : i)), s.push(i);
  }
  return s.join("");
 }, f = e => e.trim().startsWith("//") ? ansiColors.dim(e) : e.split(" ").map((e => JS_KEYWORDS.indexOf(e) > -1 ? ansiColors.cyan(e) : e)).join(" "), h = e => {
  let t = !0;
  const r = [];
  for (let n = 0; n < e.length; n++) {
   const i = e.charAt(n);
   ";" === i || "{" === i ? t = !0 : ".#,:}@$[]/*".indexOf(i) > -1 && (t = !1), t && "abcdefghijklmnopqrstuvwxyz-_".indexOf(i.toLowerCase()) > -1 ? r.push(ansiColors.cyan(i)) : r.push(i);
  }
  return r.join("");
 }, p = {
  createLineUpdater: e.createLineUpdater,
  createTimeSpan: (r, n = !1, s) => {
   const o = Date.now(), u = () => Date.now() - o, f = {
    duration: u,
    finish: (r, o, f, h) => {
     const p = u();
     let d;
     return d = p > 1e3 ? "in " + (p / 1e3).toFixed(2) + " s" : parseFloat(p.toFixed(3)) > 0 ? "in " + p + " ms" : "in less than 1 ms", 
     ((r, n, s, o, u, f, h) => {
      let p = r;
      if (s && (p = ansiColors[s](r)), o && (p = ansiColors.bold(p)), p += " " + ansiColors.dim(n), 
      f) {
       if (shouldLog(t, "debug")) {
        const t = [ p ];
        l(t);
        const r = wordWrap(t, e.getColumns());
        a(r), console.log(r.join("\n"));
       }
       c("D", [ `${r} ${n}` ]);
      } else {
       const t = wordWrap([ p ], e.getColumns());
       i(t), console.log(t.join("\n")), c("I", [ `${r} ${n}` ]), h && h.push(`${r} ${n}`);
      }
      u && console.log("");
     })(r, d, o, f, h, n, s), p;
    }
   };
   return ((r, n, s) => {
    const o = [ `${r} ${ansiColors.dim("...")}` ];
    if (n) {
     if (shouldLog(t, "debug")) {
      l(o);
      const t = wordWrap(o, e.getColumns());
      a(t), console.log(t.join("\n")), c("D", [ `${r} ...` ]);
     }
    } else {
     const t = wordWrap(o, e.getColumns());
     i(t), console.log(t.join("\n")), c("I", [ `${r} ...` ]), s && s.push(`${r} ...`);
    }
   })(r, n, s), f;
  },
  debug: (...r) => {
   if (shouldLog(t, "debug")) {
    l(r);
    const t = wordWrap(r, e.getColumns());
    a(t), console.log(t.join("\n"));
   }
   c("D", r);
  },
  emoji: e.emoji,
  enableColors: e => {
   ansiColors.enabled = e;
  },
  error: (...r) => {
   for (let e = 0; e < r.length; e++) if (r[e] instanceof Error) {
    const t = r[e];
    r[e] = t.message, t.stack && (r[e] += "\n" + t.stack);
   }
   if (shouldLog(t, "error")) {
    const t = wordWrap(r, e.getColumns());
    o(t), console.error("\n" + t.join("\n") + "\n");
   }
   c("E", r);
  },
  getLevel: () => t,
  info: (...r) => {
   if (shouldLog(t, "info")) {
    const t = wordWrap(r, e.getColumns());
    i(t), console.log(t.join("\n"));
   }
   c("I", r);
  },
  printDiagnostics: (r, n) => {
   if (!r || 0 === r.length) return;
   let l = [ "" ];
   r.forEach((r => {
    l = l.concat(((r, n) => {
     const l = wordWrap([ r.messageText ], e.getColumns());
     let c = "";
     r.header && "Build Error" !== r.header && (c += r.header), "string" == typeof r.absFilePath && "string" != typeof r.relFilePath && ("string" != typeof n && (n = e.cwd()), 
     r.relFilePath = e.relativePath(n, r.absFilePath), r.relFilePath.includes("/") || (r.relFilePath = "./" + r.relFilePath));
     let p = r.relFilePath;
     return "string" != typeof p && (p = r.absFilePath), "string" == typeof p && (c.length > 0 && (c += ": "), 
     c += ansiColors.cyan(p), "number" == typeof r.lineNumber && r.lineNumber > -1 && (c += ansiColors.dim(":"), 
     c += ansiColors.yellow(`${r.lineNumber}`), "number" == typeof r.columnNumber && r.columnNumber > -1 && (c += ansiColors.dim(":"), 
     c += ansiColors.yellow(`${r.columnNumber}`)))), c.length > 0 && l.unshift(INDENT$1 + c), 
     l.push(""), r.lines && r.lines.length && (removeLeadingWhitespace(r.lines).forEach((e => {
      if (!isMeaningfulLine(e.text)) return;
      let t = "";
      for (e.lineNumber > -1 && (t = `L${e.lineNumber}:  `); t.length < INDENT$1.length; ) t = " " + t;
      let n = e.text;
      e.errorCharStart > -1 && (n = u(n, e.errorCharStart, e.errorLength)), t = ansiColors.dim(t), 
      "typescript" === r.language || "javascript" === r.language ? t += f(n) : "scss" === r.language || "css" === r.language ? t += h(n) : t += n, 
      l.push(t);
     })), l.push("")), "error" === r.level ? o(l) : "warn" === r.level ? s(l) : "debug" === r.level ? a(l) : i(l), 
     null != r.debugText && "debug" === t && (l.push(r.debugText), a(wordWrap([ r.debugText ], e.getColumns()))), 
     l;
    })(r, n));
   })), console.log(l.join("\n"));
  },
  setLevel: e => t = e,
  setLogFilePath: e => r = e,
  warn: (...r) => {
   if (shouldLog(t, "warn")) {
    const t = wordWrap(r, e.getColumns());
    s(t), console.warn("\n" + t.join("\n") + "\n");
   }
   c("W", r);
  },
  writeLogs: t => {
   if (r) try {
    c("F", [ "--------------------------------------" ]), e.writeLogs(r, n.join("\n"), t);
   } catch (e) {}
   n.length = 0;
  },
  bgRed: ansiColors.bgRed,
  blue: ansiColors.blue,
  bold: ansiColors.bold,
  cyan: ansiColors.cyan,
  dim: ansiColors.dim,
  gray: ansiColors.gray,
  green: ansiColors.green,
  magenta: ansiColors.magenta,
  red: ansiColors.red,
  yellow: ansiColors.yellow
 };
 return p;
}, shouldLog = (e, t) => LOG_LEVELS.indexOf(t) >= LOG_LEVELS.indexOf(e), formatPrefixTimestamp = () => {
 const e = new Date;
 return `[${clampTwoDigits(e.getMinutes())}:${clampTwoDigits(e.getSeconds())}.${Math.floor(e.getMilliseconds() / 1e3 * 10)}]`;
}, clampTwoDigits = e => ("0" + e.toString()).slice(-2), wordWrap = (e, t) => {
 const r = [], n = [];
 e.forEach((e => {
  null === e ? n.push("null") : void 0 === e ? n.push("undefined") : "string" == typeof e ? e.replace(/\s/gm, " ").split(" ").forEach((e => {
   e.trim().length && n.push(e.trim());
  })) : "number" == typeof e || "boolean" == typeof e || "function" == typeof e ? n.push(e.toString()) : Array.isArray(e) || Object(e) === e ? n.push((() => e.toString())) : n.push(e.toString());
 }));
 let i = INDENT$1;
 return n.forEach((e => {
  r.length > 25 || ("function" == typeof e ? (i.trim().length && r.push(i), r.push(e()), 
  i = INDENT$1) : INDENT$1.length + e.length > t - 1 ? (i.trim().length && r.push(i), 
  r.push(INDENT$1 + e), i = INDENT$1) : e.length + i.length > t - 1 ? (r.push(i), 
  i = INDENT$1 + e + " ") : i += e + " ");
 })), i.trim().length && r.push(i), r.map((e => e.trimRight()));
}, removeLeadingWhitespace = e => {
 const t = JSON.parse(JSON.stringify(e));
 for (let e = 0; e < 100; e++) {
  if (!eachLineHasLeadingWhitespace(t)) return t;
  for (let e = 0; e < t.length; e++) if (t[e].text = t[e].text.slice(1), t[e].errorCharStart--, 
  !t[e].text.length) return t;
 }
 return t;
}, eachLineHasLeadingWhitespace = e => {
 if (!e.length) return !1;
 for (let t = 0; t < e.length; t++) {
  if (!e[t].text || e[t].text.length < 1) return !1;
  const r = e[t].text.charAt(0);
  if (" " !== r && "\t" !== r) return !1;
 }
 return !0;
}, isMeaningfulLine = e => !!e && (e = e.trim()).length > 0, JS_KEYWORDS = [ "abstract", "any", "as", "break", "boolean", "case", "catch", "class", "console", "const", "continue", "debugger", "declare", "default", "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for", "from", "function", "get", "if", "import", "in", "implements", "Infinity", "instanceof", "let", "module", "namespace", "NaN", "new", "number", "null", "public", "private", "protected", "require", "return", "static", "set", "string", "super", "switch", "this", "throw", "try", "true", "type", "typeof", "undefined", "var", "void", "with", "while", "yield" ], INDENT$1 = "           ", noop = () => {}, isString = e => "string" == typeof e, buildError = e => {
 const t = {
  level: "error",
  type: "build",
  header: "Build Error",
  messageText: "build error",
  relFilePath: null,
  absFilePath: null,
  lines: []
 };
 return e && e.push(t), t;
}, catchError = (e, t, r) => {
 const n = {
  level: "error",
  type: "build",
  header: "Build Error",
  messageText: "build error",
  relFilePath: null,
  absFilePath: null,
  lines: []
 };
 return isString(r) ? n.messageText = r.length ? r : "UNKNOWN ERROR" : null != t && (null != t.stack ? n.messageText = t.stack.toString() : null != t.message ? n.messageText = t.message.length ? t.message : "UNKNOWN ERROR" : n.messageText = t.toString()), 
 null == e || shouldIgnoreError(n.messageText) || e.push(n), n;
}, shouldIgnoreError = e => e === TASK_CANCELED_MSG, TASK_CANCELED_MSG = "task canceled", normalizePath = e => {
 if ("string" != typeof e) throw new Error("invalid path to normalize");
 e = normalizeSlashes(e.trim());
 const t = pathComponents(e, getRootLength(e)), r = reducePathComponents(t), n = r[0], i = r[1], s = n + r.slice(1).join("/");
 return "" === s ? "." : "" === n && i && e.includes("/") && !i.startsWith(".") && !i.startsWith("@") ? "./" + s : s;
}, normalizeSlashes = e => e.replace(backslashRegExp, "/"), backslashRegExp = /\\/g, reducePathComponents = e => {
 if (!Array.isArray(e) || 0 === e.length) return [];
 const t = [ e[0] ];
 for (let r = 1; r < e.length; r++) {
  const n = e[r];
  if (n && "." !== n) {
   if (".." === n) if (t.length > 1) {
    if (".." !== t[t.length - 1]) {
     t.pop();
     continue;
    }
   } else if (t[0]) continue;
   t.push(n);
  }
 }
 return t;
}, getRootLength = e => {
 const t = getEncodedRootLength(e);
 return t < 0 ? ~t : t;
}, getEncodedRootLength = e => {
 if (!e) return 0;
 const t = e.charCodeAt(0);
 if (47 === t || 92 === t) {
  if (e.charCodeAt(1) !== t) return 1;
  const r = e.indexOf(47 === t ? "/" : "\\", 2);
  return r < 0 ? e.length : r + 1;
 }
 if (isVolumeCharacter(t) && 58 === e.charCodeAt(1)) {
  const t = e.charCodeAt(2);
  if (47 === t || 92 === t) return 3;
  if (2 === e.length) return 2;
 }
 const r = e.indexOf("://");
 if (-1 !== r) {
  const t = r + "://".length, n = e.indexOf("/", t);
  if (-1 !== n) {
   const i = e.slice(0, r), s = e.slice(t, n);
   if ("file" === i && ("" === s || "localhost" === s) && isVolumeCharacter(e.charCodeAt(n + 1))) {
    const t = getFileUrlVolumeSeparatorEnd(e, n + 2);
    if (-1 !== t) {
     if (47 === e.charCodeAt(t)) return ~(t + 1);
     if (t === e.length) return ~t;
    }
   }
   return ~(n + 1);
  }
  return ~e.length;
 }
 return 0;
}, isVolumeCharacter = e => e >= 97 && e <= 122 || e >= 65 && e <= 90, getFileUrlVolumeSeparatorEnd = (e, t) => {
 const r = e.charCodeAt(t);
 if (58 === r) return t + 1;
 if (37 === r && 51 === e.charCodeAt(t + 1)) {
  const r = e.charCodeAt(t + 2);
  if (97 === r || 65 === r) return t + 3;
 }
 return -1;
}, pathComponents = (e, t) => {
 const r = e.substring(0, t), n = e.substring(t).split("/"), i = n.length;
 return i > 0 && !n[i - 1] && n.pop(), [ r, ...n ];
};

lockfile = createCommonjsModule((function(e) {
 e.exports = function(e) {
  function t(n) {
   if (r[n]) return r[n].exports;
   var i = r[n] = {
    i: n,
    l: !1,
    exports: {}
   };
   return e[n].call(i.exports, i, i.exports, t), i.l = !0, i.exports;
  }
  var r = {};
  return t.m = e, t.c = r, t.i = function(e) {
   return e;
  }, t.d = function(e, r, n) {
   t.o(e, r) || Object.defineProperty(e, r, {
    configurable: !1,
    enumerable: !0,
    get: n
   });
  }, t.n = function(e) {
   var r = e && e.__esModule ? function t() {
    return e.default;
   } : function t() {
    return e;
   };
   return t.d(r, "a", r), r;
  }, t.o = function(e, t) {
   return Object.prototype.hasOwnProperty.call(e, t);
  }, t.p = "", t(t.s = 14);
 }([ function(e, t) {
  e.exports = path__default.default;
 }, function(e, t, r) {
  var n, i;
  t.__esModule = !0, n = r(173), i = function s(e) {
   return e && e.__esModule ? e : {
    default: e
   };
  }(n), t.default = function(e) {
   return function() {
    var t = e.apply(this, arguments);
    return new i.default((function(e, r) {
     return function n(s, o) {
      var a, l;
      try {
       l = (a = t[s](o)).value;
      } catch (e) {
       return void r(e);
      }
      if (!a.done) return i.default.resolve(l).then((function(e) {
       n("next", e);
      }), (function(e) {
       n("throw", e);
      }));
      e(l);
     }("next");
    }));
   };
  };
 }, function(e, t) {
  e.exports = require$$1__default.default;
 }, function(e, t) {
  e.exports = require$$2__default.default;
 }, function(e, t, r) {
  Object.defineProperty(t, "__esModule", {
   value: !0
  });
  class n extends Error {
   constructor(e, t) {
    super(e), this.code = t;
   }
  }
  t.MessageError = n, t.ProcessSpawnError = class i extends n {
   constructor(e, t, r) {
    super(e, t), this.process = r;
   }
  }, t.SecurityError = class s extends n {}, t.ProcessTermError = class o extends n {};
  class a extends Error {
   constructor(e, t) {
    super(e), this.responseCode = t;
   }
  }
  t.ResponseError = a;
 }, function(e, t, r) {
  function n() {
   return d = u(r(1));
  }
  function i() {
   return m = u(r(3));
  }
  function s() {
   return y = u(r(36));
  }
  function o() {
   return v = u(r(0));
  }
  function a() {
   return b = function e(t) {
    var r, n;
    if (t && t.__esModule) return t;
    if (r = {}, null != t) for (n in t) Object.prototype.hasOwnProperty.call(t, n) && (r[n] = t[n]);
    return r.default = t, r;
   }(r(40));
  }
  function l() {
   return _ = r(40);
  }
  function c() {
   return S = r(164);
  }
  function u(e) {
   return e && e.__esModule ? e : {
    default: e
   };
  }
  function f(e, t) {
   return new Promise(((r, n) => {
    (m || i()).default.readFile(e, t, (function(e, t) {
     e ? n(e) : r(t);
    }));
   }));
  }
  function h(e) {
   return f(e, "utf8").then(p);
  }
  function p(e) {
   return e.replace(/\r\n/g, "\n");
  }
  var d, m, g, y, v, E, b, _, w, S, k, O, A, C, T, L, $, x, R, N, I, P, j, D, F, M, G;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.getFirstSuitableFolder = t.readFirstAvailableStream = t.makeTempDir = t.hardlinksWork = t.writeFilePreservingEol = t.getFileSizeOnDisk = t.walk = t.symlink = t.find = t.readJsonAndFile = t.readJson = t.readFileAny = t.hardlinkBulk = t.copyBulk = t.unlink = t.glob = t.link = t.chmod = t.lstat = t.exists = t.mkdirp = t.stat = t.access = t.rename = t.readdir = t.realpath = t.readlink = t.writeFile = t.open = t.readFileBuffer = t.lockQueue = t.constants = void 0;
  let q = (k = (0, (d || n()).default)((function*(e, t, r, i) {
   var s, a, l, u, f, h, p, m, g, y, E, b, _;
   let w = (_ = (0, (d || n()).default)((function*(n) {
    var s, a, l, u, f, h, p, d, m, g, y, E;
    const b = n.src, _ = n.dest, w = n.type, C = n.onFresh || de, T = n.onDone || de;
    if (O.has(_.toLowerCase()) ? i.verbose(`The case-insensitive file ${_} shouldn't be copied twice in one bulk copy`) : O.add(_.toLowerCase()), 
    "symlink" === w) return yield se((v || o()).default.dirname(_)), C(), A.symlink.push({
     dest: _,
     linkname: b
    }), void T();
    if (t.ignoreBasenames.indexOf((v || o()).default.basename(b)) >= 0) return;
    const L = yield ae(b);
    let $, x;
    L.isDirectory() && ($ = yield ne(b));
    try {
     x = yield ae(_);
    } catch (e) {
     if ("ENOENT" !== e.code) throw e;
    }
    if (x) {
     const e = L.isSymbolicLink() && x.isSymbolicLink(), t = L.isDirectory() && x.isDirectory(), n = L.isFile() && x.isFile();
     if (n && k.has(_)) return T(), void i.verbose(i.lang("verboseFileSkipArtifact", b));
     if (n && L.size === x.size && (0, (S || c()).fileDatesEqual)(L.mtime, x.mtime)) return T(), 
     void i.verbose(i.lang("verboseFileSkip", b, _, L.size, +L.mtime));
     if (e) {
      const e = yield te(b);
      if (e === (yield te(_))) return T(), void i.verbose(i.lang("verboseFileSkipSymlink", b, _, e));
     }
     if (t) {
      const e = yield ne(_);
      for (he($, "src files not initialised"), s = e, l = 0, s = (a = Array.isArray(s)) ? s : s[Symbol.iterator](); ;) {
       if (a) {
        if (l >= s.length) break;
        u = s[l++];
       } else {
        if ((l = s.next()).done) break;
        u = l.value;
       }
       const e = u;
       if ($.indexOf(e) < 0) {
        const t = (v || o()).default.join(_, e);
        if (r.add(t), (yield ae(t)).isDirectory()) for (f = yield ne(t), p = 0, f = (h = Array.isArray(f)) ? f : f[Symbol.iterator](); ;) {
         if (h) {
          if (p >= f.length) break;
          d = f[p++];
         } else {
          if ((p = f.next()).done) break;
          d = p.value;
         }
         const e = d;
         r.add((v || o()).default.join(t, e));
        }
       }
      }
     }
    }
    if (x && x.isSymbolicLink() && (yield (0, (S || c()).unlink)(_), x = null), L.isSymbolicLink()) {
     C();
     const e = yield te(b);
     A.symlink.push({
      dest: _,
      linkname: e
     }), T();
    } else if (L.isDirectory()) {
     x || (i.verbose(i.lang("verboseFileFolder", _)), yield se(_));
     const t = _.split((v || o()).default.sep);
     for (;t.length; ) O.add(t.join((v || o()).default.sep).toLowerCase()), t.pop();
     he($, "src files not initialised");
     let r = $.length;
     for (r || T(), m = $, y = 0, m = (g = Array.isArray(m)) ? m : m[Symbol.iterator](); ;) {
      if (g) {
       if (y >= m.length) break;
       E = m[y++];
      } else {
       if ((y = m.next()).done) break;
       E = y.value;
      }
      const t = E;
      e.push({
       dest: (v || o()).default.join(_, t),
       onFresh: C,
       onDone: function(e) {
        function t() {
         return e.apply(this, arguments);
        }
        return t.toString = function() {
         return e.toString();
        }, t;
       }((function() {
        0 == --r && T();
       })),
       src: (v || o()).default.join(b, t)
      });
     }
    } else {
     if (!L.isFile()) throw new Error(`unsure how to copy this: ${b}`);
     C(), A.file.push({
      src: b,
      dest: _,
      atime: L.atime,
      mtime: L.mtime,
      mode: L.mode
     }), T();
    }
   })), function e(t) {
    return _.apply(this, arguments);
   });
   const k = new Set(t.artifactFiles || []), O = new Set;
   for (s = e, l = 0, s = (a = Array.isArray(s)) ? s : s[Symbol.iterator](); ;) {
    if (a) {
     if (l >= s.length) break;
     u = s[l++];
    } else {
     if ((l = s.next()).done) break;
     u = l.value;
    }
    const e = u, r = e.onDone;
    e.onDone = function() {
     t.onProgress(e.dest), r && r();
    };
   }
   t.onStart(e.length);
   const A = {
    file: [],
    symlink: [],
    link: []
   };
   for (;e.length; ) {
    const t = e.splice(0, ue);
    yield Promise.all(t.map(w));
   }
   for (f = k, p = 0, f = (h = Array.isArray(f)) ? f : f[Symbol.iterator](); ;) {
    if (h) {
     if (p >= f.length) break;
     m = f[p++];
    } else {
     if ((p = f.next()).done) break;
     m = p.value;
    }
    const e = m;
    r.has(e) && (i.verbose(i.lang("verboseFilePhantomExtraneous", e)), r.delete(e));
   }
   for (g = r, E = 0, g = (y = Array.isArray(g)) ? g : g[Symbol.iterator](); ;) {
    if (y) {
     if (E >= g.length) break;
     b = g[E++];
    } else {
     if ((E = g.next()).done) break;
     b = E.value;
    }
    const e = b;
    O.has(e.toLowerCase()) && r.delete(e);
   }
   return A;
  })), function e(t, r, n, i) {
   return k.apply(this, arguments);
  }), U = (O = (0, (d || n()).default)((function*(e, t, r, i) {
   var s, a, l, c, u, f, h, p, m, g, y, E, b;
   let _ = (b = (0, (d || n()).default)((function*(n) {
    var s, a, l, c, u, f, h, p, d, m, g, y;
    const E = n.src, b = n.dest, _ = n.onFresh || de, O = n.onDone || de;
    if (S.has(b.toLowerCase())) return void O();
    if (S.add(b.toLowerCase()), t.ignoreBasenames.indexOf((v || o()).default.basename(E)) >= 0) return;
    const A = yield ae(E);
    let C;
    A.isDirectory() && (C = yield ne(E));
    const T = yield oe(b);
    if (T) {
     const e = yield ae(b), t = A.isSymbolicLink() && e.isSymbolicLink(), n = A.isDirectory() && e.isDirectory(), d = A.isFile() && e.isFile();
     if (A.mode !== e.mode) try {
      yield ie(b, A.mode);
     } catch (e) {
      i.verbose(e);
     }
     if (d && w.has(b)) return O(), void i.verbose(i.lang("verboseFileSkipArtifact", E));
     if (d && null !== A.ino && A.ino === e.ino) return O(), void i.verbose(i.lang("verboseFileSkip", E, b, A.ino));
     if (t) {
      const e = yield te(E);
      if (e === (yield te(b))) return O(), void i.verbose(i.lang("verboseFileSkipSymlink", E, b, e));
     }
     if (n) {
      const e = yield ne(b);
      for (he(C, "src files not initialised"), s = e, l = 0, s = (a = Array.isArray(s)) ? s : s[Symbol.iterator](); ;) {
       if (a) {
        if (l >= s.length) break;
        c = s[l++];
       } else {
        if ((l = s.next()).done) break;
        c = l.value;
       }
       const e = c;
       if (C.indexOf(e) < 0) {
        const t = (v || o()).default.join(b, e);
        if (r.add(t), (yield ae(t)).isDirectory()) for (u = yield ne(t), h = 0, u = (f = Array.isArray(u)) ? u : u[Symbol.iterator](); ;) {
         if (f) {
          if (h >= u.length) break;
          p = u[h++];
         } else {
          if ((h = u.next()).done) break;
          p = h.value;
         }
         const e = p;
         r.add((v || o()).default.join(t, e));
        }
       }
      }
     }
    }
    if (A.isSymbolicLink()) {
     _();
     const e = yield te(E);
     k.symlink.push({
      dest: b,
      linkname: e
     }), O();
    } else if (A.isDirectory()) {
     i.verbose(i.lang("verboseFileFolder", b)), yield se(b);
     const t = b.split((v || o()).default.sep);
     for (;t.length; ) S.add(t.join((v || o()).default.sep).toLowerCase()), t.pop();
     he(C, "src files not initialised");
     let r = C.length;
     for (r || O(), d = C, g = 0, d = (m = Array.isArray(d)) ? d : d[Symbol.iterator](); ;) {
      if (m) {
       if (g >= d.length) break;
       y = d[g++];
      } else {
       if ((g = d.next()).done) break;
       y = g.value;
      }
      const t = y;
      e.push({
       onFresh: _,
       src: (v || o()).default.join(E, t),
       dest: (v || o()).default.join(b, t),
       onDone: function(e) {
        function t() {
         return e.apply(this, arguments);
        }
        return t.toString = function() {
         return e.toString();
        }, t;
       }((function() {
        0 == --r && O();
       }))
      });
     }
    } else {
     if (!A.isFile()) throw new Error(`unsure how to copy this: ${E}`);
     _(), k.link.push({
      src: E,
      dest: b,
      removeDest: T
     }), O();
    }
   })), function e(t) {
    return b.apply(this, arguments);
   });
   const w = new Set(t.artifactFiles || []), S = new Set;
   for (s = e, l = 0, s = (a = Array.isArray(s)) ? s : s[Symbol.iterator](); ;) {
    if (a) {
     if (l >= s.length) break;
     c = s[l++];
    } else {
     if ((l = s.next()).done) break;
     c = l.value;
    }
    const e = c, r = e.onDone || de;
    e.onDone = function() {
     t.onProgress(e.dest), r();
    };
   }
   t.onStart(e.length);
   const k = {
    file: [],
    symlink: [],
    link: []
   };
   for (;e.length; ) {
    const t = e.splice(0, ue);
    yield Promise.all(t.map(_));
   }
   for (u = w, h = 0, u = (f = Array.isArray(u)) ? u : u[Symbol.iterator](); ;) {
    if (f) {
     if (h >= u.length) break;
     p = u[h++];
    } else {
     if ((h = u.next()).done) break;
     p = h.value;
    }
    const e = p;
    r.has(e) && (i.verbose(i.lang("verboseFilePhantomExtraneous", e)), r.delete(e));
   }
   for (m = r, y = 0, m = (g = Array.isArray(m)) ? m : m[Symbol.iterator](); ;) {
    if (g) {
     if (y >= m.length) break;
     E = m[y++];
    } else {
     if ((y = m.next()).done) break;
     E = y.value;
    }
    const e = E;
    S.has(e.toLowerCase()) && r.delete(e);
   }
   return k;
  })), function e(t, r, n, i) {
   return O.apply(this, arguments);
  }), B = t.copyBulk = (A = (0, (d || n()).default)((function*(e, t, r) {
   const i = {
    onStart: r && r.onStart || de,
    onProgress: r && r.onProgress || de,
    possibleExtraneous: r ? r.possibleExtraneous : new Set,
    ignoreBasenames: r && r.ignoreBasenames || [],
    artifactFiles: r && r.artifactFiles || []
   }, s = yield q(e, i, i.possibleExtraneous, t);
   i.onStart(s.file.length + s.symlink.length + s.link.length);
   const l = s.file, u = new Map;
   var f;
   yield (b || a()).queue(l, (f = (0, (d || n()).default)((function*(e) {
    let r;
    for (;r = u.get(e.dest); ) yield r;
    t.verbose(t.lang("verboseFileCopy", e.src, e.dest));
    const n = (0, (S || c()).copyFile)(e, (function() {
     return u.delete(e.dest);
    }));
    return u.set(e.dest, n), i.onProgress(e.dest), n;
   })), function(e) {
    return f.apply(this, arguments);
   }), ue);
   const h = s.symlink;
   yield (b || a()).queue(h, (function(e) {
    const r = (v || o()).default.resolve((v || o()).default.dirname(e.dest), e.linkname);
    return t.verbose(t.lang("verboseFileSymlink", e.dest, r)), H(r, e.dest);
   }));
  })), function e(t, r, n) {
   return A.apply(this, arguments);
  });
  t.hardlinkBulk = (C = (0, (d || n()).default)((function*(e, t, r) {
   const i = {
    onStart: r && r.onStart || de,
    onProgress: r && r.onProgress || de,
    possibleExtraneous: r ? r.possibleExtraneous : new Set,
    artifactFiles: r && r.artifactFiles || [],
    ignoreBasenames: []
   }, s = yield U(e, i, i.possibleExtraneous, t);
   i.onStart(s.file.length + s.symlink.length + s.link.length);
   const l = s.link;
   var u;
   yield (b || a()).queue(l, (u = (0, (d || n()).default)((function*(e) {
    t.verbose(t.lang("verboseFileLink", e.src, e.dest)), e.removeDest && (yield (0, 
    (S || c()).unlink)(e.dest)), yield le(e.src, e.dest);
   })), function(e) {
    return u.apply(this, arguments);
   }), ue);
   const f = s.symlink;
   yield (b || a()).queue(f, (function(e) {
    const r = (v || o()).default.resolve((v || o()).default.dirname(e.dest), e.linkname);
    return t.verbose(t.lang("verboseFileSymlink", e.dest, r)), H(r, e.dest);
   }));
  })), function e(t, r, n) {
   return C.apply(this, arguments);
  }), t.readFileAny = (T = (0, (d || n()).default)((function*(e) {
   var t, r, n, i;
   for (t = e, n = 0, t = (r = Array.isArray(t)) ? t : t[Symbol.iterator](); ;) {
    if (r) {
     if (n >= t.length) break;
     i = t[n++];
    } else {
     if ((n = t.next()).done) break;
     i = n.value;
    }
    const e = i;
    if (yield oe(e)) return h(e);
   }
   return null;
  })), function e(t) {
   return T.apply(this, arguments);
  }), t.readJson = (L = (0, (d || n()).default)((function*(e) {
   return (yield X(e)).object;
  })), function e(t) {
   return L.apply(this, arguments);
  });
  let X = t.readJsonAndFile = ($ = (0, (d || n()).default)((function*(e) {
   const t = yield h(e);
   try {
    return {
     object: (0, (w || (w = u(r(20)))).default)(JSON.parse(pe(t))),
     content: t
    };
   } catch (t) {
    throw t.message = `${e}: ${t.message}`, t;
   }
  })), function e(t) {
   return $.apply(this, arguments);
  });
  t.find = (x = (0, (d || n()).default)((function*(e, t) {
   const r = t.split((v || o()).default.sep);
   for (;r.length; ) {
    const t = r.concat(e).join((v || o()).default.sep);
    if (yield oe(t)) return t;
    r.pop();
   }
   return !1;
  })), function e(t, r) {
   return x.apply(this, arguments);
  });
  let H = t.symlink = (R = (0, (d || n()).default)((function*(e, t) {
   try {
    if ((yield ae(t)).isSymbolicLink() && (yield re(t)) === e) return;
   } catch (e) {
    if ("ENOENT" !== e.code) throw e;
   }
   if (yield (0, (S || c()).unlink)(t), "win32" === process.platform) yield fe(e, t, "junction"); else {
    let r;
    try {
     r = (v || o()).default.relative((m || i()).default.realpathSync((v || o()).default.dirname(t)), (m || i()).default.realpathSync(e));
    } catch (n) {
     if ("ENOENT" !== n.code) throw n;
     r = (v || o()).default.relative((v || o()).default.dirname(t), e);
    }
    yield fe(r || ".", t);
   }
  })), function e(t, r) {
   return R.apply(this, arguments);
  }), W = t.walk = (N = (0, (d || n()).default)((function*(e, t, r = new Set) {
   var n, i, s, a;
   let l = [], c = yield ne(e);
   for (r.size && (c = c.filter((function(e) {
    return !r.has(e);
   }))), n = c, s = 0, n = (i = Array.isArray(n)) ? n : n[Symbol.iterator](); ;) {
    if (i) {
     if (s >= n.length) break;
     a = n[s++];
    } else {
     if ((s = n.next()).done) break;
     a = s.value;
    }
    const c = a, u = t ? (v || o()).default.join(t, c) : c, f = (v || o()).default.join(e, c), h = yield ae(f);
    l.push({
     relative: u,
     basename: c,
     absolute: f,
     mtime: +h.mtime
    }), h.isDirectory() && (l = l.concat(yield W(f, u, r)));
   }
   return l;
  })), function e(t, r) {
   return N.apply(this, arguments);
  });
  t.getFileSizeOnDisk = (I = (0, (d || n()).default)((function*(e) {
   const t = yield ae(e), r = t.size, n = t.blksize;
   return Math.ceil(r / n) * n;
  })), function e(t) {
   return I.apply(this, arguments);
  });
  let z = (P = (0, (d || n()).default)((function*(e) {
   if (!(yield oe(e))) return;
   const t = yield J(e);
   for (let e = 0; e < t.length; ++e) {
    if (t[e] === me) return "\r\n";
    if (t[e] === ge) return "\n";
   }
  })), function e(t) {
   return P.apply(this, arguments);
  });
  t.writeFilePreservingEol = (j = (0, (d || n()).default)((function*(e, t) {
   const r = (yield z(e)) || (y || s()).default.EOL;
   "\n" !== r && (t = t.replace(/\n/g, r)), yield ee(e, t);
  })), function e(t, r) {
   return j.apply(this, arguments);
  }), t.hardlinksWork = (D = (0, (d || n()).default)((function*(e) {
   const t = "test-file" + Math.random(), r = (v || o()).default.join(e, t), n = (v || o()).default.join(e, t + "-link");
   try {
    yield ee(r, "test"), yield le(r, n);
   } catch (e) {
    return !1;
   } finally {
    yield (0, (S || c()).unlink)(r), yield (0, (S || c()).unlink)(n);
   }
   return !0;
  })), function e(t) {
   return D.apply(this, arguments);
  }), t.makeTempDir = (F = (0, (d || n()).default)((function*(e) {
   const t = (v || o()).default.join((y || s()).default.tmpdir(), `yarn-${e || ""}-${Date.now()}-${Math.random()}`);
   return yield (0, (S || c()).unlink)(t), yield se(t), t;
  })), function e(t) {
   return F.apply(this, arguments);
  }), t.readFirstAvailableStream = (M = (0, (d || n()).default)((function*(e) {
   var t, r, n, s;
   for (t = e, n = 0, t = (r = Array.isArray(t)) ? t : t[Symbol.iterator](); ;) {
    if (r) {
     if (n >= t.length) break;
     s = t[n++];
    } else {
     if ((n = t.next()).done) break;
     s = n.value;
    }
    const e = s;
    try {
     const t = yield Z(e, "r");
     return (m || i()).default.createReadStream(e, {
      fd: t
     });
    } catch (e) {}
   }
   return null;
  })), function e(t) {
   return M.apply(this, arguments);
  }), t.getFirstSuitableFolder = (G = (0, (d || n()).default)((function*(e, t = K.W_OK | K.X_OK) {
   var r, n, i, s;
   const o = {
    skipped: [],
    folder: null
   };
   for (r = e, i = 0, r = (n = Array.isArray(r)) ? r : r[Symbol.iterator](); ;) {
    if (n) {
     if (i >= r.length) break;
     s = r[i++];
    } else {
     if ((i = r.next()).done) break;
     s = i.value;
    }
    const e = s;
    try {
     return yield se(e), yield ie(e, t), o.folder = e, o;
    } catch (t) {
     o.skipped.push({
      error: t,
      folder: e
     });
    }
   }
   return o;
  })), function e(t) {
   return G.apply(this, arguments);
  }), t.copy = function Y(e, t, r) {
   return B([ {
    src: e,
    dest: t
   } ], r);
  }, t.readFile = h, t.readFileRaw = function V(e) {
   return f(e, "binary");
  }, t.normalizeOS = p;
  const K = t.constants = void 0 !== (m || i()).default.constants ? (m || i()).default.constants : {
   R_OK: (m || i()).default.R_OK,
   W_OK: (m || i()).default.W_OK,
   X_OK: (m || i()).default.X_OK
  };
  t.lockQueue = new ((E || function Q() {
   return E = u(r(84));
  }()).default)("fs lock");
  const J = t.readFileBuffer = (0, (_ || l()).promisify)((m || i()).default.readFile), Z = t.open = (0, 
  (_ || l()).promisify)((m || i()).default.open), ee = t.writeFile = (0, (_ || l()).promisify)((m || i()).default.writeFile), te = t.readlink = (0, 
  (_ || l()).promisify)((m || i()).default.readlink), re = t.realpath = (0, (_ || l()).promisify)((m || i()).default.realpath), ne = t.readdir = (0, 
  (_ || l()).promisify)((m || i()).default.readdir);
  t.rename = (0, (_ || l()).promisify)((m || i()).default.rename);
  const ie = t.access = (0, (_ || l()).promisify)((m || i()).default.access);
  t.stat = (0, (_ || l()).promisify)((m || i()).default.stat);
  const se = t.mkdirp = (0, (_ || l()).promisify)(r(116)), oe = t.exists = (0, (_ || l()).promisify)((m || i()).default.exists, !0), ae = t.lstat = (0, 
  (_ || l()).promisify)((m || i()).default.lstat);
  t.chmod = (0, (_ || l()).promisify)((m || i()).default.chmod);
  const le = t.link = (0, (_ || l()).promisify)((m || i()).default.link);
  t.glob = (0, (_ || l()).promisify)((g || function ce() {
   return g = u(r(75));
  }()).default), t.unlink = (S || c()).unlink;
  const ue = (m || i()).default.copyFile ? 128 : 4, fe = (0, (_ || l()).promisify)((m || i()).default.symlink), he = r(7), pe = r(122), de = () => {}, me = "\r".charCodeAt(0), ge = "\n".charCodeAt(0);
 }, function(e, t, r) {
  function n(e, t) {
   let r = "PATH";
   if ("win32" === e) {
    r = "Path";
    for (const e in t) "path" === e.toLowerCase() && (r = e);
   }
   return r;
  }
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.getPathKey = n;
  const i = r(36), s = r(0), o = r(45).default;
  var a = r(171);
  const l = a.getCacheDir, c = a.getConfigDir, u = a.getDataDir, f = r(227), h = t.DEPENDENCY_TYPES = [ "devDependencies", "dependencies", "optionalDependencies", "peerDependencies" ], p = t.RESOLUTIONS = "resolutions";
  t.MANIFEST_FIELDS = [ p, ...h ], t.SUPPORTED_NODE_VERSIONS = "^4.8.0 || ^5.7.0 || ^6.2.2 || >=8.0.0", 
  t.YARN_REGISTRY = "https://registry.yarnpkg.com", t.YARN_DOCS = "https://yarnpkg.com/en/docs/cli/", 
  t.YARN_INSTALLER_SH = "https://yarnpkg.com/install.sh", t.YARN_INSTALLER_MSI = "https://yarnpkg.com/latest.msi", 
  t.SELF_UPDATE_VERSION_URL = "https://yarnpkg.com/latest-version", t.CACHE_VERSION = 2, 
  t.LOCKFILE_VERSION = 1, t.NETWORK_CONCURRENCY = 8, t.NETWORK_TIMEOUT = 3e4, t.CHILD_CONCURRENCY = 5, 
  t.REQUIRED_PACKAGE_KEYS = [ "name", "version", "_uid" ], t.PREFERRED_MODULE_CACHE_DIRECTORIES = function d() {
   const e = [ l() ];
   return process.getuid && e.push(s.join(i.tmpdir(), `.yarn-cache-${process.getuid()}`)), 
   e.push(s.join(i.tmpdir(), ".yarn-cache")), e;
  }(), t.CONFIG_DIRECTORY = c();
  const m = t.DATA_DIRECTORY = u();
  t.LINK_REGISTRY_DIRECTORY = s.join(m, "link"), t.GLOBAL_MODULE_DIRECTORY = s.join(m, "global"), 
  t.NODE_BIN_PATH = process.execPath, t.YARN_BIN_PATH = function g() {
   return f ? __filename : s.join(__dirname, "..", "bin", "yarn.js");
  }(), t.NODE_MODULES_FOLDER = "node_modules", t.NODE_PACKAGE_JSON = "package.json", 
  t.POSIX_GLOBAL_PREFIX = `${process.env.DESTDIR || ""}/usr/local`, t.FALLBACK_GLOBAL_PREFIX = s.join(o, ".yarn"), 
  t.META_FOLDER = ".yarn-meta", t.INTEGRITY_FILENAME = ".yarn-integrity", t.LOCKFILE_FILENAME = "yarn.lock", 
  t.METADATA_FILENAME = ".yarn-metadata.json", t.TARBALL_FILENAME = ".yarn-tarball.tgz", 
  t.CLEAN_FILENAME = ".yarnclean", t.NPM_LOCK_FILENAME = "package-lock.json", t.NPM_SHRINKWRAP_FILENAME = "npm-shrinkwrap.json", 
  t.DEFAULT_INDENT = "  ", t.SINGLE_INSTANCE_PORT = 31997, t.SINGLE_INSTANCE_FILENAME = ".yarn-single-instance", 
  t.ENV_PATH_KEY = n(process.platform, process.env), t.VERSION_COLOR_SCHEME = {
   major: "red",
   premajor: "red",
   minor: "yellow",
   preminor: "yellow",
   patch: "green",
   prepatch: "green",
   prerelease: "red",
   unchanged: "white",
   unknown: "red"
  };
 }, function(e, t, r) {
  var n = process.env.NODE_ENV;
  e.exports = function(e, t, r, i, s, o, a, l) {
   var c, u, f;
   if ("production" !== n && void 0 === t) throw new Error("invariant requires an error message argument");
   if (!e) throw void 0 === t ? c = new Error("Minified exception occurred; use the non-minified dev environment for the full error message and additional helpful warnings.") : (u = [ r, i, s, o, a, l ], 
   f = 0, (c = new Error(t.replace(/%s/g, (function() {
    return u[f++];
   })))).name = "Invariant Violation"), c.framesToPop = 1, c;
  };
 }, , function(e, t) {
  e.exports = require$$3__default.default;
 }, , function(e, t) {
  var r = e.exports = "undefined" != typeof window && window.Math == Math ? window : "undefined" != typeof self && self.Math == Math ? self : Function("return this")();
  "number" == typeof __g && (__g = r);
 }, function(e, t, r) {
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.sortAlpha = function n(e, t) {
   const r = Math.min(e.length, t.length);
   for (let n = 0; n < r; n++) {
    const r = e.charCodeAt(n), i = t.charCodeAt(n);
    if (r !== i) return r - i;
   }
   return e.length - t.length;
  }, t.entries = function i(e) {
   const t = [];
   if (e) for (const r in e) t.push([ r, e[r] ]);
   return t;
  }, t.removePrefix = function s(e, t) {
   return e.startsWith(t) && (e = e.slice(t.length)), e;
  }, t.removeSuffix = function o(e, t) {
   return e.endsWith(t) ? e.slice(0, -t.length) : e;
  }, t.addSuffix = function a(e, t) {
   return e.endsWith(t) ? e : e + t;
  }, t.hyphenate = function l(e) {
   return e.replace(/[A-Z]/g, (e => "-" + e.charAt(0).toLowerCase()));
  }, t.camelCase = function c(e) {
   return /[A-Z]/.test(e) ? null : h(e);
  }, t.compareSortedArrays = function u(e, t) {
   if (e.length !== t.length) return !1;
   for (let r = 0, n = e.length; r < n; r++) if (e[r] !== t[r]) return !1;
   return !0;
  }, t.sleep = function f(e) {
   return new Promise((t => {
    setTimeout(t, e);
   }));
  };
  const h = r(176);
 }, function(e, t, r) {
  var n = r(107)("wks"), i = r(111), s = r(11).Symbol, o = "function" == typeof s;
  (e.exports = function(e) {
   return n[e] || (n[e] = o && s[e] || (o ? s : i)("Symbol." + e));
  }).store = n;
 }, function(e, t, r) {
  function n() {
   return y = function e(t) {
    var r, n;
    if (t && t.__esModule) return t;
    if (r = {}, null != t) for (n in t) Object.prototype.hasOwnProperty.call(t, n) && (r[n] = t[n]);
    return r.default = t, r;
   }(r(5));
  }
  function i(e) {
   return e && e.__esModule ? e : {
    default: e
   };
  }
  function s(e) {
   return (0, (d || function t() {
    return d = r(29);
   }()).normalizePattern)(e).name;
  }
  function o(e) {
   return e && Object.keys(e).length ? e : void 0;
  }
  function a(e) {
   return e.resolved || (e.reference && e.hash ? `${e.reference}#${e.hash}` : null);
  }
  function l(e, t) {
   const r = s(e), n = t.integrity ? function i(e) {
    return e.toString().split(" ").sort().join(" ");
   }(t.integrity) : "", a = {
    name: r === t.name ? void 0 : t.name,
    version: t.version,
    uid: t.uid === t.version ? void 0 : t.uid,
    resolved: t.resolved,
    registry: "npm" === t.registry ? void 0 : t.registry,
    dependencies: o(t.dependencies),
    optionalDependencies: o(t.optionalDependencies),
    permissions: o(t.permissions),
    prebuiltVariants: o(t.prebuiltVariants)
   };
   return n && (a.integrity = n), a;
  }
  function c(e, t) {
   t.optionalDependencies = t.optionalDependencies || {}, t.dependencies = t.dependencies || {}, 
   t.uid = t.uid || t.version, t.permissions = t.permissions || {}, t.registry = t.registry || "npm", 
   t.name = t.name || s(e);
   const r = t.integrity;
   return r && r.isIntegrity && (t.integrity = b.parse(r)), t;
  }
  var u, f, h, p, d, m, g, y;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.stringify = t.parse = void 0, Object.defineProperty(t, "parse", {
   enumerable: !0,
   get: function e() {
    return i(f || function t() {
     return f = r(81);
    }()).default;
   }
  }), Object.defineProperty(t, "stringify", {
   enumerable: !0,
   get: function e() {
    return i(h || function t() {
     return h = r(150);
    }()).default;
   }
  }), t.implodeEntry = l, t.explodeEntry = c;
  const v = r(7), E = r(0), b = r(55);
  class _ {
   constructor({cache: e, source: t, parseResultType: r} = {}) {
    this.source = t || "", this.cache = e, this.parseResultType = r;
   }
   hasEntriesExistWithoutIntegrity() {
    if (!this.cache) return !1;
    for (const e in this.cache) if (!/^.*@(file:|http)/.test(e) && this.cache[e] && !this.cache[e].integrity) return !0;
    return !1;
   }
   static fromDirectory(e, t) {
    return (0, (u || function s() {
     return u = i(r(1));
    }()).default)((function*() {
     const s = E.join(e, (g || function o() {
      return g = r(6);
     }()).LOCKFILE_FILENAME);
     let a, l, c = "";
     return (yield (y || n()).exists(s)) ? (c = yield (y || n()).readFile(s), l = (0, 
     (m || function u() {
      return m = i(r(81));
     }()).default)(c, s), t && ("merge" === l.type ? t.info(t.lang("lockfileMerged")) : "conflict" === l.type && t.warn(t.lang("lockfileConflict"))), 
     a = l.object) : t && t.info(t.lang("noLockfileFound")), new _({
      cache: a,
      source: c,
      parseResultType: l && l.type
     });
    }))();
   }
   getLocked(e) {
    const t = this.cache;
    if (!t) return;
    const r = e in t && t[e];
    return "string" == typeof r ? this.getLocked(r) : r ? (c(e, r), r) : void 0;
   }
   removePattern(e) {
    const t = this.cache;
    t && delete t[e];
   }
   getLockfile(e) {
    var t, n, i, o;
    const c = {}, u = new Map;
    for (t = Object.keys(e).sort((p || function f() {
     return p = r(12);
    }()).sortAlpha), i = 0, t = (n = Array.isArray(t)) ? t : t[Symbol.iterator](); ;) {
     if (n) {
      if (i >= t.length) break;
      o = t[i++];
     } else {
      if ((i = t.next()).done) break;
      o = i.value;
     }
     const r = o, f = e[r], h = f._remote, p = f._reference;
     v(p, "Package is missing a reference"), v(h, "Package is missing a remote");
     const d = a(h), m = d && u.get(d);
     if (m) {
      c[r] = m, m.name || s(r) === f.name || (m.name = f.name);
      continue;
     }
     const g = l(r, {
      name: f.name,
      version: f.version,
      uid: f._uid,
      resolved: h.resolved,
      integrity: h.integrity,
      registry: h.registry,
      dependencies: f.dependencies,
      peerDependencies: f.peerDependencies,
      optionalDependencies: f.optionalDependencies,
      permissions: p.permissions,
      prebuiltVariants: f.prebuiltVariants
     });
     c[r] = g, d && u.set(d, g);
    }
    return c;
   }
  }
  t.default = _;
 }, , , function(e, t) {
  e.exports = require$$4__default.default;
 }, , , function(e, t, r) {
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.default = function e(t = {}) {
   var r, n, i, s;
   if (Array.isArray(t)) for (r = t, i = 0, r = (n = Array.isArray(r)) ? r : r[Symbol.iterator](); ;) {
    if (n) {
     if (i >= r.length) break;
     s = r[i++];
    } else {
     if ((i = r.next()).done) break;
     s = i.value;
    }
    e(s);
   } else if ((null !== t && "object" == typeof t || "function" == typeof t) && (Object.setPrototypeOf(t, null), 
   "object" == typeof t)) for (const r in t) e(t[r]);
   return t;
  };
 }, , function(e, t) {
  e.exports = require$$5__default.default;
 }, function(e, t) {
  var r = e.exports = {
   version: "2.5.7"
  };
  "number" == typeof __e && (__e = r);
 }, , , , function(e, t, r) {
  var n = r(34);
  e.exports = function(e) {
   if (!n(e)) throw TypeError(e + " is not an object!");
   return e;
  };
 }, , function(e, t, r) {
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.normalizePattern = function n(e) {
   let t = !1, r = "latest", n = e, i = !1;
   "@" === n[0] && (i = !0, n = n.slice(1));
   const s = n.split("@");
   return s.length > 1 && (n = s.shift(), r = s.join("@"), r ? t = !0 : r = "*"), i && (n = `@${n}`), 
   {
    name: n,
    range: r,
    hasVersion: t
   };
  };
 }, , function(e, t, r) {
  var n = r(50), i = r(106);
  e.exports = r(33) ? function(e, t, r) {
   return n.f(e, t, i(1, r));
  } : function(e, t, r) {
   return e[t] = r, e;
  };
 }, function(e, t, r) {
  function n(e, t) {
   for (var r in e) t[r] = e[r];
  }
  function i(e, t, r) {
   return o(e, t, r);
  }
  var s = r(63), o = s.Buffer;
  o.from && o.alloc && o.allocUnsafe && o.allocUnsafeSlow ? e.exports = s : (n(s, t), 
  t.Buffer = i), n(o, i), i.from = function(e, t, r) {
   if ("number" == typeof e) throw new TypeError("Argument must not be a number");
   return o(e, t, r);
  }, i.alloc = function(e, t, r) {
   if ("number" != typeof e) throw new TypeError("Argument must be a number");
   var n = o(e);
   return void 0 !== t ? "string" == typeof r ? n.fill(t, r) : n.fill(t) : n.fill(0), 
   n;
  }, i.allocUnsafe = function(e) {
   if ("number" != typeof e) throw new TypeError("Argument must be a number");
   return o(e);
  }, i.allocUnsafeSlow = function(e) {
   if ("number" != typeof e) throw new TypeError("Argument must be a number");
   return s.SlowBuffer(e);
  };
 }, function(e, t, r) {
  e.exports = !r(85)((function() {
   return 7 != Object.defineProperty({}, "a", {
    get: function() {
     return 7;
    }
   }).a;
  }));
 }, function(e, t) {
  e.exports = function(e) {
   return "object" == typeof e ? null !== e : "function" == typeof e;
  };
 }, function(e, t) {
  e.exports = {};
 }, function(e, t) {
  e.exports = require$$6__default.default;
 }, , , , function(e, t, r) {
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.wait = function n(e) {
   return new Promise((t => {
    setTimeout(t, e);
   }));
  }, t.promisify = function i(e, t) {
   return function(...r) {
    return new Promise((function(n, i) {
     r.push((function(e, ...r) {
      let s = r;
      r.length <= 1 && (s = r[0]), t && (s = e, e = null), e ? i(e) : n(s);
     })), e.apply(null, r);
    }));
   };
  }, t.queue = function s(e, t, r = 1 / 0) {
   r = Math.min(r, e.length), e = e.slice();
   const n = [];
   let i = e.length;
   return i ? new Promise(((s, o) => {
    function a() {
     const r = e.shift();
     t(r).then((function(t) {
      n.push(t), i--, 0 === i ? s(n) : e.length && a();
     }), o);
    }
    for (let e = 0; e < r; e++) a();
   })) : Promise.resolve(n);
  };
 }, function(e, t, r) {
  var n = r(11), i = r(23), s = r(48), o = r(31), a = r(49), l = "prototype", c = function(e, t, r) {
   var u, f, h, p = e & c.F, d = e & c.G, m = e & c.S, g = e & c.P, y = e & c.B, v = e & c.W, E = d ? i : i[t] || (i[t] = {}), b = E[l], _ = d ? n : m ? n[t] : (n[t] || {})[l];
   for (u in d && (r = t), r) (f = !p && _ && void 0 !== _[u]) && a(E, u) || (h = f ? _[u] : r[u], 
   E[u] = d && "function" != typeof _[u] ? r[u] : y && f ? s(h, n) : v && _[u] == h ? function(e) {
    var t = function(t, r, n) {
     if (this instanceof e) {
      switch (arguments.length) {
      case 0:
       return new e;

      case 1:
       return new e(t);

      case 2:
       return new e(t, r);
      }
      return new e(t, r, n);
     }
     return e.apply(this, arguments);
    };
    return t[l] = e[l], t;
   }(h) : g && "function" == typeof h ? s(Function.call, h) : h, g && ((E.virtual || (E.virtual = {}))[u] = h, 
   e & c.R && b && !b[u] && o(b, u, h)));
  };
  c.F = 1, c.G = 2, c.S = 4, c.P = 8, c.B = 16, c.W = 32, c.U = 64, c.R = 128, e.exports = c;
 }, function(e, t, r) {
  try {
   var n = r(2);
   if ("function" != typeof n.inherits) throw "";
   e.exports = n.inherits;
  } catch (t) {
   e.exports = r(224);
  }
 }, , , function(e, t, r) {
  var n;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.home = void 0;
  const i = r(0), s = t.home = r(36).homedir(), o = (n || function a() {
   return n = function e(t) {
    return t && t.__esModule ? t : {
     default: t
    };
   }(r(169));
  }()).default ? i.resolve("/usr/local/share") : s;
  t.default = o;
 }, function(e, t) {
  e.exports = function(e) {
   if ("function" != typeof e) throw TypeError(e + " is not a function!");
   return e;
  };
 }, function(e, t) {
  var r = {}.toString;
  e.exports = function(e) {
   return r.call(e).slice(8, -1);
  };
 }, function(e, t, r) {
  var n = r(46);
  e.exports = function(e, t, r) {
   if (n(e), void 0 === t) return e;
   switch (r) {
   case 1:
    return function(r) {
     return e.call(t, r);
    };

   case 2:
    return function(r, n) {
     return e.call(t, r, n);
    };

   case 3:
    return function(r, n, i) {
     return e.call(t, r, n, i);
    };
   }
   return function() {
    return e.apply(t, arguments);
   };
  };
 }, function(e, t) {
  var r = {}.hasOwnProperty;
  e.exports = function(e, t) {
   return r.call(e, t);
  };
 }, function(e, t, r) {
  var n = r(27), i = r(184), s = r(201), o = Object.defineProperty;
  t.f = r(33) ? Object.defineProperty : function e(t, r, a) {
   if (n(t), r = s(r, !0), n(a), i) try {
    return o(t, r, a);
   } catch (e) {}
   if ("get" in a || "set" in a) throw TypeError("Accessors not supported!");
   return "value" in a && (t[r] = a.value), t;
  };
 }, , , , function(e, t) {
  e.exports = require$$7__default.default;
 }, function(e, t, r) {
  function n(e, t) {
   if (t = t || {}, "string" == typeof e) return i(e, t);
   if (e.algorithm && e.digest) {
    const r = new y;
    return r[e.algorithm] = [ e ], i(s(r, t), t);
   }
   return i(s(e, t), t);
  }
  function i(e, t) {
   return t.single ? new g(e, t) : e.trim().split(/\s+/).reduce(((e, r) => {
    const n = new g(r, t);
    if (n.algorithm && n.digest) {
     const t = n.algorithm;
     e[t] || (e[t] = []), e[t].push(n);
    }
    return e;
   }), new y);
  }
  function s(e, t) {
   return e.algorithm && e.digest ? g.prototype.toString.call(e, t) : "string" == typeof e ? s(n(e, t), t) : y.prototype.toString.call(e, t);
  }
  function o(e) {
   const t = (e = e || {}).integrity && n(e.integrity, e), r = t && Object.keys(t).length, i = r && t.pickAlgorithm(e), s = r && t[i], o = Array.from(new Set((e.algorithms || [ "sha512" ]).concat(i ? [ i ] : []))), a = o.map(c.createHash);
   let l = 0;
   const f = new u({
    transform(e, t, r) {
     l += e.length, a.forEach((r => r.update(e, t))), r(null, e, t);
    }
   }).on("end", (() => {
    const c = e.options && e.options.length ? `?${e.options.join("?")}` : "", u = n(a.map(((e, t) => `${o[t]}-${e.digest("base64")}${c}`)).join(" "), e), h = r && u.match(t, e);
    if ("number" == typeof e.size && l !== e.size) {
     const r = new Error(`stream size mismatch when checking ${t}.\n  Wanted: ${e.size}\n  Found: ${l}`);
     r.code = "EBADSIZE", r.found = l, r.expected = e.size, r.sri = t, f.emit("error", r);
    } else if (e.integrity && !h) {
     const e = new Error(`${t} integrity checksum failed when using ${i}: wanted ${s} but got ${u}. (${l} bytes)`);
     e.code = "EINTEGRITY", e.found = u, e.expected = s, e.algorithm = i, e.sri = t, 
     f.emit("error", e);
    } else f.emit("size", l), f.emit("integrity", u), h && f.emit("verified", h);
   }));
   return f;
  }
  function a(e, t) {
   return O.indexOf(e.toLowerCase()) >= O.indexOf(t.toLowerCase()) ? e : t;
  }
  const l = r(32).Buffer, c = r(9), u = r(17).Transform, f = [ "sha256", "sha384", "sha512" ], h = /^[a-z0-9+/]+(?:=?=?)$/i, p = /^([^-]+)-([^?]+)([?\S*]*)$/, d = /^([^-]+)-([A-Za-z0-9+/=]{44,88})(\?[\x21-\x7E]*)*$/, m = /^[\x21-\x7E]+$/;
  class g {
   get isHash() {
    return !0;
   }
   constructor(e, t) {
    const r = !(!t || !t.strict);
    this.source = e.trim();
    const n = this.source.match(r ? d : p);
    if (!n) return;
    if (r && !f.some((e => e === n[1]))) return;
    this.algorithm = n[1], this.digest = n[2];
    const i = n[3];
    this.options = i ? i.slice(1).split("?") : [];
   }
   hexDigest() {
    return this.digest && l.from(this.digest, "base64").toString("hex");
   }
   toJSON() {
    return this.toString();
   }
   toString(e) {
    if (e && e.strict && !(f.some((e => e === this.algorithm)) && this.digest.match(h) && (this.options || []).every((e => e.match(m))))) return "";
    const t = this.options && this.options.length ? `?${this.options.join("?")}` : "";
    return `${this.algorithm}-${this.digest}${t}`;
   }
  }
  class y {
   get isIntegrity() {
    return !0;
   }
   toJSON() {
    return this.toString();
   }
   toString(e) {
    let t = (e = e || {}).sep || " ";
    return e.strict && (t = t.replace(/\S+/g, " ")), Object.keys(this).map((r => this[r].map((t => g.prototype.toString.call(t, e))).filter((e => e.length)).join(t))).filter((e => e.length)).join(t);
   }
   concat(e, t) {
    const r = "string" == typeof e ? e : s(e, t);
    return n(`${this.toString(t)} ${r}`, t);
   }
   hexDigest() {
    return n(this, {
     single: !0
    }).hexDigest();
   }
   match(e, t) {
    const r = n(e, t), i = r.pickAlgorithm(t);
    return this[i] && r[i] && this[i].find((e => r[i].find((t => e.digest === t.digest)))) || !1;
   }
   pickAlgorithm(e) {
    const t = e && e.pickAlgorithm || a, r = Object.keys(this);
    if (!r.length) throw new Error(`No algorithms available for ${JSON.stringify(this.toString())}`);
    return r.reduce(((e, r) => t(e, r) || e));
   }
  }
  e.exports.parse = n, e.exports.stringify = s, e.exports.fromHex = function v(e, t, r) {
   const i = r && r.options && r.options.length ? `?${r.options.join("?")}` : "";
   return n(`${t}-${l.from(e, "hex").toString("base64")}${i}`, r);
  }, e.exports.fromData = function E(e, t) {
   const r = (t = t || {}).algorithms || [ "sha512" ], n = t.options && t.options.length ? `?${t.options.join("?")}` : "";
   return r.reduce(((r, i) => {
    const s = c.createHash(i).update(e).digest("base64"), o = new g(`${i}-${s}${n}`, t);
    if (o.algorithm && o.digest) {
     const e = o.algorithm;
     r[e] || (r[e] = []), r[e].push(o);
    }
    return r;
   }), new y);
  }, e.exports.fromStream = function b(e, t) {
   const r = (t = t || {}).Promise || Promise, n = o(t);
   return new r(((t, r) => {
    let i;
    e.pipe(n), e.on("error", r), n.on("error", r), n.on("integrity", (e => {
     i = e;
    })), n.on("end", (() => t(i))), n.on("data", (() => {}));
   }));
  }, e.exports.checkData = function _(e, t, r) {
   if (t = n(t, r = r || {}), !Object.keys(t).length) {
    if (r.error) throw Object.assign(new Error("No valid integrity hashes to check against"), {
     code: "EINTEGRITY"
    });
    return !1;
   }
   const i = t.pickAlgorithm(r), s = n({
    algorithm: i,
    digest: c.createHash(i).update(e).digest("base64")
   }), o = s.match(t, r);
   if (o || !r.error) return o;
   if ("number" == typeof r.size && e.length !== r.size) {
    const n = new Error(`data size mismatch when checking ${t}.\n  Wanted: ${r.size}\n  Found: ${e.length}`);
    throw n.code = "EBADSIZE", n.found = e.length, n.expected = r.size, n.sri = t, n;
   }
   {
    const r = new Error(`Integrity checksum failed when using ${i}: Wanted ${t}, but got ${s}. (${e.length} bytes)`);
    throw r.code = "EINTEGRITY", r.found = s, r.expected = t, r.algorithm = i, r.sri = t, 
    r;
   }
  }, e.exports.checkStream = function w(e, t, r) {
   const n = (r = r || {}).Promise || Promise, i = o(Object.assign({}, r, {
    integrity: t
   }));
   return new n(((t, r) => {
    let n;
    e.pipe(i), e.on("error", r), i.on("error", r), i.on("verified", (e => {
     n = e;
    })), i.on("end", (() => t(n))), i.on("data", (() => {}));
   }));
  }, e.exports.integrityStream = o, e.exports.create = function S(e) {
   const t = (e = e || {}).algorithms || [ "sha512" ], r = e.options && e.options.length ? `?${e.options.join("?")}` : "", n = t.map(c.createHash);
   return {
    update: function(e, t) {
     return n.forEach((r => r.update(e, t))), this;
    },
    digest: function(i) {
     return t.reduce(((t, i) => {
      const s = n.shift().digest("base64"), o = new g(`${i}-${s}${r}`, e);
      if (o.algorithm && o.digest) {
       const e = o.algorithm;
       t[e] || (t[e] = []), t[e].push(o);
      }
      return t;
     }), new y);
    }
   };
  };
  const k = new Set(c.getHashes()), O = [ "md5", "whirlpool", "sha1", "sha224", "sha256", "sha384", "sha512", "sha3", "sha3-256", "sha3-384", "sha3-512", "sha3_256", "sha3_384", "sha3_512" ].filter((e => k.has(e)));
 }, , , , , function(e, t, r) {
  function n(e, t) {
   e = e || {}, t = t || {};
   var r = {};
   return Object.keys(t).forEach((function(e) {
    r[e] = t[e];
   })), Object.keys(e).forEach((function(t) {
    r[t] = e[t];
   })), r;
  }
  function i(e, t, r) {
   if ("string" != typeof t) throw new TypeError("glob pattern string required");
   return r || (r = {}), !(!r.nocomment && "#" === t.charAt(0)) && ("" === t.trim() ? "" === e : new s(t, r).match(e));
  }
  function s(e, t) {
   if (!(this instanceof s)) return new s(e, t);
   if ("string" != typeof e) throw new TypeError("glob pattern string required");
   t || (t = {}), e = e.trim(), "/" !== a.sep && (e = e.split(a.sep).join("/")), this.options = t, 
   this.set = [], this.pattern = e, this.regexp = null, this.negate = !1, this.comment = !1, 
   this.empty = !1, this.make();
  }
  function o(e, t) {
   if (t || (t = this instanceof s ? this.options : {}), void 0 === (e = void 0 === e ? this.pattern : e)) throw new TypeError("undefined pattern");
   return t.nobrace || !e.match(/\{.*\}/) ? [ e ] : c(e);
  }
  var a, l, c, u, f, h, p, d, m;
  e.exports = i, i.Minimatch = s, a = {
   sep: "/"
  };
  try {
   a = r(0);
  } catch (e) {}
  l = i.GLOBSTAR = s.GLOBSTAR = {}, c = r(175), u = {
   "!": {
    open: "(?:(?!(?:",
    close: "))[^/]*?)"
   },
   "?": {
    open: "(?:",
    close: ")?"
   },
   "+": {
    open: "(?:",
    close: ")+"
   },
   "*": {
    open: "(?:",
    close: ")*"
   },
   "@": {
    open: "(?:",
    close: ")"
   }
  }, h = (f = "[^/]") + "*?", p = function g(e) {
   return e.split("").reduce((function(e, t) {
    return e[t] = !0, e;
   }), {});
  }("().*{}+?[]^$\\!"), d = /\/+/, i.filter = function y(e, t) {
   return t = t || {}, function(r, n, s) {
    return i(r, e, t);
   };
  }, i.defaults = function(e) {
   var t, r;
   return e && Object.keys(e).length ? (t = i, (r = function r(i, s, o) {
    return t.minimatch(i, s, n(e, o));
   }).Minimatch = function r(i, s) {
    return new t.Minimatch(i, n(e, s));
   }, r) : i;
  }, s.defaults = function(e) {
   return e && Object.keys(e).length ? i.defaults(e).Minimatch : s;
  }, s.prototype.debug = function() {}, s.prototype.make = function v() {
   var e, t, r;
   this._made || (e = this.pattern, (t = this.options).nocomment || "#" !== e.charAt(0) ? e ? (this.parseNegate(), 
   r = this.globSet = this.braceExpand(), t.debug && (this.debug = console.error), 
   this.debug(this.pattern, r), r = this.globParts = r.map((function(e) {
    return e.split(d);
   })), this.debug(this.pattern, r), r = r.map((function(e, t, r) {
    return e.map(this.parse, this);
   }), this), this.debug(this.pattern, r), r = r.filter((function(e) {
    return -1 === e.indexOf(!1);
   })), this.debug(this.pattern, r), this.set = r) : this.empty = !0 : this.comment = !0);
  }, s.prototype.parseNegate = function E() {
   var e, t, r = this.pattern, n = !1, i = 0;
   if (!this.options.nonegate) {
    for (e = 0, t = r.length; e < t && "!" === r.charAt(e); e++) n = !n, i++;
    i && (this.pattern = r.substr(i)), this.negate = n;
   }
  }, i.braceExpand = function(e, t) {
   return o(e, t);
  }, s.prototype.braceExpand = o, s.prototype.parse = function b(e, t) {
   function r() {
    if (d) {
     switch (d) {
     case "*":
      i += h, s = !0;
      break;

     case "?":
      i += f, s = !0;
      break;

     default:
      i += "\\" + d;
     }
     b.debug("clearStateChar %j %j", d, i), d = !1;
    }
   }
   var n, i, s, o, a, c, d, g, y, v, E, b, _, w, S, k, O, A, C, T, L, $, x, R, N, I, P, j, D, F, M, G;
   if (e.length > 65536) throw new TypeError("pattern is too long");
   if (!(n = this.options).noglobstar && "**" === e) return l;
   if ("" === e) return "";
   for (i = "", s = !!n.nocase, o = !1, a = [], c = [], g = !1, y = -1, v = -1, E = "." === e.charAt(0) ? "" : n.dot ? "(?!(?:^|\\/)\\.{1,2}(?:$|\\/))" : "(?!\\.)", 
   b = this, _ = 0, w = e.length; _ < w && (S = e.charAt(_)); _++) if (this.debug("%s\t%s %s %j", e, _, i, S), 
   o && p[S]) i += "\\" + S, o = !1; else switch (S) {
   case "/":
    return !1;

   case "\\":
    r(), o = !0;
    continue;

   case "?":
   case "*":
   case "+":
   case "@":
   case "!":
    if (this.debug("%s\t%s %s %j <-- stateChar", e, _, i, S), g) {
     this.debug("  in class"), "!" === S && _ === v + 1 && (S = "^"), i += S;
     continue;
    }
    b.debug("call clearStateChar %j", d), r(), d = S, n.noext && r();
    continue;

   case "(":
    if (g) {
     i += "(";
     continue;
    }
    if (!d) {
     i += "\\(";
     continue;
    }
    a.push({
     type: d,
     start: _ - 1,
     reStart: i.length,
     open: u[d].open,
     close: u[d].close
    }), i += "!" === d ? "(?:(?!(?:" : "(?:", this.debug("plType %j %j", d, i), d = !1;
    continue;

   case ")":
    if (g || !a.length) {
     i += "\\)";
     continue;
    }
    r(), s = !0, k = a.pop(), i += k.close, "!" === k.type && c.push(k), k.reEnd = i.length;
    continue;

   case "|":
    if (g || !a.length || o) {
     i += "\\|", o = !1;
     continue;
    }
    r(), i += "|";
    continue;

   case "[":
    if (r(), g) {
     i += "\\" + S;
     continue;
    }
    g = !0, v = _, y = i.length, i += S;
    continue;

   case "]":
    if (_ === v + 1 || !g) {
     i += "\\" + S, o = !1;
     continue;
    }
    if (g) {
     O = e.substring(v + 1, _);
     try {
      RegExp("[" + O + "]");
     } catch (e) {
      A = this.parse(O, m), i = i.substr(0, y) + "\\[" + A[0] + "\\]", s = s || A[1], 
      g = !1;
      continue;
     }
    }
    s = !0, g = !1, i += S;
    continue;

   default:
    r(), o ? o = !1 : !p[S] || "^" === S && g || (i += "\\"), i += S;
   }
   for (g && (O = e.substr(v + 1), A = this.parse(O, m), i = i.substr(0, y) + "\\[" + A[0], 
   s = s || A[1]), k = a.pop(); k; k = a.pop()) C = i.slice(k.reStart + k.open.length), 
   this.debug("setting tail", i, k), C = C.replace(/((?:\\{2}){0,64})(\\?)\|/g, (function(e, t, r) {
    return r || (r = "\\"), t + t + r + "|";
   })), this.debug("tail=%j\n   %s", C, C, k, i), T = "*" === k.type ? h : "?" === k.type ? f : "\\" + k.type, 
   s = !0, i = i.slice(0, k.reStart) + T + "\\(" + C;
   switch (r(), o && (i += "\\\\"), L = !1, i.charAt(0)) {
   case ".":
   case "[":
   case "(":
    L = !0;
   }
   for ($ = c.length - 1; $ > -1; $--) {
    for (x = c[$], R = i.slice(0, x.reStart), N = i.slice(x.reStart, x.reEnd - 8), I = i.slice(x.reEnd - 8, x.reEnd), 
    I += P = i.slice(x.reEnd), j = R.split("(").length - 1, D = P, _ = 0; _ < j; _++) D = D.replace(/\)[+*?]?/, "");
    F = "", "" === (P = D) && t !== m && (F = "$"), i = R + N + P + F + I;
   }
   if ("" !== i && s && (i = "(?=.)" + i), L && (i = E + i), t === m) return [ i, s ];
   if (!s) return function q(e) {
    return e.replace(/\\(.)/g, "$1");
   }(e);
   M = n.nocase ? "i" : "";
   try {
    G = new RegExp("^" + i + "$", M);
   } catch (e) {
    return new RegExp("$.");
   }
   return G._glob = e, G._src = i, G;
  }, m = {}, i.makeRe = function(e, t) {
   return new s(e, t || {}).makeRe();
  }, s.prototype.makeRe = function _() {
   var e, t, r, n, i;
   if (this.regexp || !1 === this.regexp) return this.regexp;
   if (!(e = this.set).length) return this.regexp = !1, this.regexp;
   t = this.options, r = t.noglobstar ? h : t.dot ? "(?:(?!(?:\\/|^)(?:\\.{1,2})($|\\/)).)*?" : "(?:(?!(?:\\/|^)\\.).)*?", 
   n = t.nocase ? "i" : "", i = "^(?:" + (i = e.map((function(e) {
    return e.map((function(e) {
     return e === l ? r : "string" == typeof e ? function t(e) {
      return e.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
     }(e) : e._src;
    })).join("\\/");
   })).join("|")) + ")$", this.negate && (i = "^(?!" + i + ").*$");
   try {
    this.regexp = new RegExp(i, n);
   } catch (e) {
    this.regexp = !1;
   }
   return this.regexp;
  }, i.match = function(e, t, r) {
   var n = new s(t, r = r || {});
   return e = e.filter((function(e) {
    return n.match(e);
   })), n.options.nonull && !e.length && e.push(t), e;
  }, s.prototype.match = function w(e, t) {
   var r, n, i, s, o, l;
   if (this.debug("match", e, this.pattern), this.comment) return !1;
   if (this.empty) return "" === e;
   if ("/" === e && t) return !0;
   for (r = this.options, "/" !== a.sep && (e = e.split(a.sep).join("/")), e = e.split(d), 
   this.debug(this.pattern, "split", e), n = this.set, this.debug(this.pattern, "set", n), 
   s = e.length - 1; s >= 0 && !(i = e[s]); s--) ;
   for (s = 0; s < n.length; s++) if (o = n[s], l = e, r.matchBase && 1 === o.length && (l = [ i ]), 
   this.matchOne(l, o, t)) return !!r.flipNegate || !this.negate;
   return !r.flipNegate && this.negate;
  }, s.prototype.matchOne = function(e, t, r) {
   var n, i, s, o, a, c, u, f, h, p, d = this.options;
   for (this.debug("matchOne", {
    this: this,
    file: e,
    pattern: t
   }), this.debug("matchOne", e.length, t.length), n = 0, i = 0, s = e.length, o = t.length; n < s && i < o; n++, 
   i++) {
    if (this.debug("matchOne loop"), a = t[i], c = e[n], this.debug(t, a, c), !1 === a) return !1;
    if (a === l) {
     if (this.debug("GLOBSTAR", [ t, a, c ]), u = n, (f = i + 1) === o) {
      for (this.debug("** at the end"); n < s; n++) if ("." === e[n] || ".." === e[n] || !d.dot && "." === e[n].charAt(0)) return !1;
      return !0;
     }
     for (;u < s; ) {
      if (h = e[u], this.debug("\nglobstar while", e, u, t, f, h), this.matchOne(e.slice(u), t.slice(f), r)) return this.debug("globstar found match!", u, s, h), 
      !0;
      if ("." === h || ".." === h || !d.dot && "." === h.charAt(0)) {
       this.debug("dot detected!", e, u, t, f);
       break;
      }
      this.debug("globstar swallow a segment, and continue"), u++;
     }
     return !(!r || (this.debug("\n>>> no match, partial?", e, u, t, f), u !== s));
    }
    if ("string" == typeof a ? (p = d.nocase ? c.toLowerCase() === a.toLowerCase() : c === a, 
    this.debug("string match", a, c, p)) : (p = c.match(a), this.debug("pattern match", a, c, p)), 
    !p) return !1;
   }
   if (n === s && i === o) return !0;
   if (n === s) return r;
   if (i === o) return n === s - 1 && "" === e[n];
   throw new Error("wtf?");
  };
 }, function(e, t, r) {
  function n(e) {
   var t = function() {
    return t.called ? t.value : (t.called = !0, t.value = e.apply(this, arguments));
   };
   return t.called = !1, t;
  }
  function i(e) {
   var t = function() {
    if (t.called) throw new Error(t.onceError);
    return t.called = !0, t.value = e.apply(this, arguments);
   }, r = e.name || "Function wrapped with `once`";
   return t.onceError = r + " shouldn't be called more than once", t.called = !1, t;
  }
  var s = r(123);
  e.exports = s(n), e.exports.strict = s(i), n.proto = n((function() {
   Object.defineProperty(Function.prototype, "once", {
    value: function() {
     return n(this);
    },
    configurable: !0
   }), Object.defineProperty(Function.prototype, "onceStrict", {
    value: function() {
     return i(this);
    },
    configurable: !0
   });
  }));
 }, , function(e, t) {
  e.exports = require$$8__default.default;
 }, , , , function(e, t) {
  e.exports = function(e) {
   if (null == e) throw TypeError("Can't call method on  " + e);
   return e;
  };
 }, function(e, t, r) {
  var n = r(34), i = r(11).document, s = n(i) && n(i.createElement);
  e.exports = function(e) {
   return s ? i.createElement(e) : {};
  };
 }, function(e, t) {
  e.exports = !0;
 }, function(e, t, r) {
  function n(e) {
   var t, r;
   this.promise = new e((function(e, n) {
    if (void 0 !== t || void 0 !== r) throw TypeError("Bad Promise constructor");
    t = e, r = n;
   })), this.resolve = i(t), this.reject = i(r);
  }
  var i = r(46);
  e.exports.f = function(e) {
   return new n(e);
  };
 }, function(e, t, r) {
  var n = r(50).f, i = r(49), s = r(13)("toStringTag");
  e.exports = function(e, t, r) {
   e && !i(e = r ? e : e.prototype, s) && n(e, s, {
    configurable: !0,
    value: t
   });
  };
 }, function(e, t, r) {
  var n = r(107)("keys"), i = r(111);
  e.exports = function(e) {
   return n[e] || (n[e] = i(e));
  };
 }, function(e, t) {
  var r = Math.ceil, n = Math.floor;
  e.exports = function(e) {
   return isNaN(e = +e) ? 0 : (e > 0 ? n : r)(e);
  };
 }, function(e, t, r) {
  var n = r(131), i = r(67);
  e.exports = function(e) {
   return n(i(e));
  };
 }, function(e, t, r) {
  function n(e, t, r) {
   if ("function" == typeof t && (r = t, t = {}), t || (t = {}), t.sync) {
    if (r) throw new TypeError("callback provided to sync glob");
    return p(e, t);
   }
   return new i(e, t, r);
  }
  function i(e, t, r) {
   function n() {
    --o._processing, o._processing <= 0 && (a ? process.nextTick((function() {
     o._finish();
    })) : o._finish());
   }
   var s, o, a, l;
   if ("function" == typeof t && (r = t, t = null), t && t.sync) {
    if (r) throw new TypeError("callback provided to sync glob");
    return new _(e, t);
   }
   if (!(this instanceof i)) return new i(e, t, r);
   if (m(this, e, t), this._didRealPath = !1, s = this.minimatch.set.length, this.matches = new Array(s), 
   "function" == typeof r && (r = b(r), this.on("error", r), this.on("end", (function(e) {
    r(null, e);
   }))), o = this, this._processing = 0, this._emitQueue = [], this._processQueue = [], 
   this.paused = !1, this.noprocess) return this;
   if (0 === s) return n();
   for (a = !0, l = 0; l < s; l++) this._process(this.minimatch.set[l], l, !1, n);
   a = !1;
  }
  var s, o, a, l, c, u, f, h, p, d, m, g, y, v, E, b, _;
  e.exports = n, s = r(3), o = r(114), a = r(60), l = r(42), c = r(54).EventEmitter, 
  u = r(0), f = r(22), h = r(76), p = r(218), d = r(115), m = d.setopts, g = d.ownProp, 
  y = r(223), r(2), v = d.childrenIgnored, E = d.isIgnored, b = r(61), n.sync = p, 
  _ = n.GlobSync = p.GlobSync, n.glob = n, n.hasMagic = function(e, t) {
   var r, n, s = function o(e, t) {
    var r, n;
    if (null === t || "object" != typeof t) return e;
    for (n = (r = Object.keys(t)).length; n--; ) e[r[n]] = t[r[n]];
    return e;
   }({}, t);
   if (s.noprocess = !0, r = new i(e, s).minimatch.set, !e) return !1;
   if (r.length > 1) return !0;
   for (n = 0; n < r[0].length; n++) if ("string" != typeof r[0][n]) return !0;
   return !1;
  }, n.Glob = i, l(i, c), i.prototype._finish = function() {
   if (f(this instanceof i), !this.aborted) {
    if (this.realpath && !this._didRealpath) return this._realpath();
    d.finish(this), this.emit("end", this.found);
   }
  }, i.prototype._realpath = function() {
   function e() {
    0 == --t && r._finish();
   }
   var t, r, n;
   if (!this._didRealpath) {
    if (this._didRealpath = !0, 0 === (t = this.matches.length)) return this._finish();
    for (r = this, n = 0; n < this.matches.length; n++) this._realpathSet(n, e);
   }
  }, i.prototype._realpathSet = function(e, t) {
   var r, n, i, s, a = this.matches[e];
   return a ? (r = Object.keys(a), n = this, 0 === (i = r.length) ? t() : (s = this.matches[e] = Object.create(null), 
   void r.forEach((function(r, a) {
    r = n._makeAbs(r), o.realpath(r, n.realpathCache, (function(o, a) {
     o ? "stat" === o.syscall ? s[r] = !0 : n.emit("error", o) : s[a] = !0, 0 == --i && (n.matches[e] = s, 
     t());
    }));
   })))) : t();
  }, i.prototype._mark = function(e) {
   return d.mark(this, e);
  }, i.prototype._makeAbs = function(e) {
   return d.makeAbs(this, e);
  }, i.prototype.abort = function() {
   this.aborted = !0, this.emit("abort");
  }, i.prototype.pause = function() {
   this.paused || (this.paused = !0, this.emit("pause"));
  }, i.prototype.resume = function() {
   var e, t, r, n, i;
   if (this.paused) {
    if (this.emit("resume"), this.paused = !1, this._emitQueue.length) for (e = this._emitQueue.slice(0), 
    this._emitQueue.length = 0, t = 0; t < e.length; t++) r = e[t], this._emitMatch(r[0], r[1]);
    if (this._processQueue.length) for (n = this._processQueue.slice(0), this._processQueue.length = 0, 
    t = 0; t < n.length; t++) i = n[t], this._processing--, this._process(i[0], i[1], i[2], i[3]);
   }
  }, i.prototype._process = function(e, t, r, n) {
   var s, o, l, c, u;
   if (f(this instanceof i), f("function" == typeof n), !this.aborted) if (this._processing++, 
   this.paused) this._processQueue.push([ e, t, r, n ]); else {
    for (s = 0; "string" == typeof e[s]; ) s++;
    switch (s) {
    case e.length:
     return void this._processSimple(e.join("/"), t, n);

    case 0:
     o = null;
     break;

    default:
     o = e.slice(0, s).join("/");
    }
    if (l = e.slice(s), null === o ? c = "." : h(o) || h(e.join("/")) ? (o && h(o) || (o = "/" + o), 
    c = o) : c = o, u = this._makeAbs(c), v(this, c)) return n();
    l[0] === a.GLOBSTAR ? this._processGlobStar(o, c, u, l, t, r, n) : this._processReaddir(o, c, u, l, t, r, n);
   }
  }, i.prototype._processReaddir = function(e, t, r, n, i, s, o) {
   var a = this;
   this._readdir(r, s, (function(l, c) {
    return a._processReaddir2(e, t, r, n, i, s, c, o);
   }));
  }, i.prototype._processReaddir2 = function(e, t, r, n, i, s, o, a) {
   var l, c, f, h, p, d, m, g;
   if (!o) return a();
   for (l = n[0], c = !!this.minimatch.negate, f = l._glob, h = this.dot || "." === f.charAt(0), 
   p = [], d = 0; d < o.length; d++) ("." !== (m = o[d]).charAt(0) || h) && (c && !e ? !m.match(l) : m.match(l)) && p.push(m);
   if (0 === (g = p.length)) return a();
   if (1 === n.length && !this.mark && !this.stat) {
    for (this.matches[i] || (this.matches[i] = Object.create(null)), d = 0; d < g; d++) m = p[d], 
    e && (m = "/" !== e ? e + "/" + m : e + m), "/" !== m.charAt(0) || this.nomount || (m = u.join(this.root, m)), 
    this._emitMatch(i, m);
    return a();
   }
   for (n.shift(), d = 0; d < g; d++) m = p[d], e && (m = "/" !== e ? e + "/" + m : e + m), 
   this._process([ m ].concat(n), i, s, a);
   a();
  }, i.prototype._emitMatch = function(e, t) {
   var r, n, i;
   this.aborted || E(this, t) || (this.paused ? this._emitQueue.push([ e, t ]) : (r = h(t) ? t : this._makeAbs(t), 
   this.mark && (t = this._mark(t)), this.absolute && (t = r), this.matches[e][t] || this.nodir && ("DIR" === (n = this.cache[r]) || Array.isArray(n)) || (this.matches[e][t] = !0, 
   (i = this.statCache[r]) && this.emit("stat", t, i), this.emit("match", t))));
  }, i.prototype._readdirInGlobStar = function(e, t) {
   var r, n;
   if (!this.aborted) {
    if (this.follow) return this._readdir(e, !1, t);
    r = this, (n = y("lstat\0" + e, (function i(n, s) {
     if (n && "ENOENT" === n.code) return t();
     var o = s && s.isSymbolicLink();
     r.symlinks[e] = o, o || !s || s.isDirectory() ? r._readdir(e, !1, t) : (r.cache[e] = "FILE", 
     t());
    }))) && s.lstat(e, n);
   }
  }, i.prototype._readdir = function(e, t, r) {
   if (!this.aborted && (r = y("readdir\0" + e + "\0" + t, r))) {
    if (t && !g(this.symlinks, e)) return this._readdirInGlobStar(e, r);
    if (g(this.cache, e)) {
     var n = this.cache[e];
     if (!n || "FILE" === n) return r();
     if (Array.isArray(n)) return r(null, n);
    }
    s.readdir(e, function i(e, t, r) {
     return function(n, i) {
      n ? e._readdirError(t, n, r) : e._readdirEntries(t, i, r);
     };
    }(this, e, r));
   }
  }, i.prototype._readdirEntries = function(e, t, r) {
   var n, i;
   if (!this.aborted) {
    if (!this.mark && !this.stat) for (n = 0; n < t.length; n++) i = t[n], i = "/" === e ? e + i : e + "/" + i, 
    this.cache[i] = !0;
    return this.cache[e] = t, r(null, t);
   }
  }, i.prototype._readdirError = function(e, t, r) {
   var n, i;
   if (!this.aborted) {
    switch (t.code) {
    case "ENOTSUP":
    case "ENOTDIR":
     n = this._makeAbs(e), this.cache[n] = "FILE", n === this.cwdAbs && ((i = new Error(t.code + " invalid cwd " + this.cwd)).path = this.cwd, 
     i.code = t.code, this.emit("error", i), this.abort());
     break;

    case "ENOENT":
    case "ELOOP":
    case "ENAMETOOLONG":
    case "UNKNOWN":
     this.cache[this._makeAbs(e)] = !1;
     break;

    default:
     this.cache[this._makeAbs(e)] = !1, this.strict && (this.emit("error", t), this.abort()), 
     this.silent || console.error("glob error", t);
    }
    return r();
   }
  }, i.prototype._processGlobStar = function(e, t, r, n, i, s, o) {
   var a = this;
   this._readdir(r, s, (function(l, c) {
    a._processGlobStar2(e, t, r, n, i, s, c, o);
   }));
  }, i.prototype._processGlobStar2 = function(e, t, r, n, i, s, o, a) {
   var l, c, u, f, h, p, d, m;
   if (!o) return a();
   if (l = n.slice(1), u = (c = e ? [ e ] : []).concat(l), this._process(u, i, !1, a), 
   f = this.symlinks[r], h = o.length, f && s) return a();
   for (p = 0; p < h; p++) ("." !== o[p].charAt(0) || this.dot) && (d = c.concat(o[p], l), 
   this._process(d, i, !0, a), m = c.concat(o[p], n), this._process(m, i, !0, a));
   a();
  }, i.prototype._processSimple = function(e, t, r) {
   var n = this;
   this._stat(e, (function(i, s) {
    n._processSimple2(e, t, i, s, r);
   }));
  }, i.prototype._processSimple2 = function(e, t, r, n, i) {
   if (this.matches[t] || (this.matches[t] = Object.create(null)), !n) return i();
   if (e && h(e) && !this.nomount) {
    var s = /[\/\\]$/.test(e);
    "/" === e.charAt(0) ? e = u.join(this.root, e) : (e = u.resolve(this.root, e), s && (e += "/"));
   }
   "win32" === process.platform && (e = e.replace(/\\/g, "/")), this._emitMatch(t, e), 
   i();
  }, i.prototype._stat = function(e, t) {
   var r, n, i, o, a, l = this._makeAbs(e), c = "/" === e.slice(-1);
   if (e.length > this.maxLength) return t();
   if (!this.stat && g(this.cache, l)) {
    if (r = this.cache[l], Array.isArray(r) && (r = "DIR"), !c || "DIR" === r) return t(null, r);
    if (c && "FILE" === r) return t();
   }
   if (void 0 !== (n = this.statCache[l])) return !1 === n ? t(null, n) : (i = n.isDirectory() ? "DIR" : "FILE", 
   c && "FILE" === i ? t() : t(null, i, n));
   o = this, a = y("stat\0" + l, (function u(r, n) {
    if (n && n.isSymbolicLink()) return s.stat(l, (function(r, i) {
     r ? o._stat2(e, l, null, n, t) : o._stat2(e, l, r, i, t);
    }));
    o._stat2(e, l, r, n, t);
   })), a && s.lstat(l, a);
  }, i.prototype._stat2 = function(e, t, r, n, i) {
   var s, o;
   return !r || "ENOENT" !== r.code && "ENOTDIR" !== r.code ? (s = "/" === e.slice(-1), 
   this.statCache[t] = n, "/" === t.slice(-1) && n && !n.isDirectory() ? i(null, !1, n) : (o = !0, 
   n && (o = n.isDirectory() ? "DIR" : "FILE"), this.cache[t] = this.cache[t] || o, 
   s && "FILE" === o ? i() : i(null, o, n))) : (this.statCache[t] = !1, i());
  };
 }, function(e, t, r) {
  function n(e) {
   return "/" === e.charAt(0);
  }
  function i(e) {
   var t = /^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/.exec(e), r = t[1] || "", n = Boolean(r && ":" !== r.charAt(1));
   return Boolean(t[2] || n);
  }
  e.exports = "win32" === process.platform ? i : n, e.exports.posix = n, e.exports.win32 = i;
 }, , , function(e, t) {
  e.exports = require$$9__default.default;
 }, , function(e, t, r) {
  function n() {
   return l = s(r(7));
  }
  function i() {
   return u = r(6);
  }
  function s(e) {
   return e && e.__esModule ? e : {
    default: e
   };
  }
  function o(e, t) {
   const r = new k(e, t);
   return r.next(), r.parse();
  }
  var a, l, c, u, f, h;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.default = function(e, t = "lockfile") {
   return function i(e) {
    return e.includes(C) && e.includes(A) && e.includes(O);
   }(e = (0, (c || function n() {
    return c = s(r(122));
   }()).default)(e)) ? function a(e, t) {
    const r = function n(e) {
     const t = [ [], [] ], r = e.split(/\r?\n/g);
     let n = !1;
     for (;r.length; ) {
      const e = r.shift();
      if (e.startsWith(C)) {
       for (;r.length; ) {
        const e = r.shift();
        if (e === A) {
         n = !1;
         break;
        }
        n || e.startsWith("|||||||") ? n = !0 : t[0].push(e);
       }
       for (;r.length; ) {
        const e = r.shift();
        if (e.startsWith(O)) break;
        t[1].push(e);
       }
      } else t[0].push(e), t[1].push(e);
     }
     return [ t[0].join("\n"), t[1].join("\n") ];
    }(e);
    try {
     return {
      type: "merge",
      object: Object.assign({}, o(r[0], t), o(r[1], t))
     };
    } catch (e) {
     if (e instanceof SyntaxError) return {
      type: "conflict",
      object: {}
     };
     throw e;
    }
   }(e, t) : {
    type: "success",
    object: o(e, t)
   };
  };
  const p = /^yarn lockfile v(\d+)$/, d = "BOOLEAN", m = "STRING", g = "COLON", y = "NEWLINE", v = "COMMENT", E = "INDENT", b = "INVALID", _ = "NUMBER", w = "COMMA", S = [ d, m, _ ];
  class k {
   constructor(e, t = "lockfile") {
    this.comments = [], this.tokens = function* r(e) {
     function t(e, t) {
      return {
       line: n,
       col: i,
       type: e,
       value: t
      };
     }
     let r = !1, n = 1, i = 0;
     for (;e.length; ) {
      let s = 0;
      if ("\n" === e[0] || "\r" === e[0]) s++, "\n" === e[1] && s++, n++, i = 0, yield t(y); else if ("#" === e[0]) {
       s++;
       let r = "";
       for (;"\n" !== e[s]; ) r += e[s], s++;
       yield t(v, r);
      } else if (" " === e[0]) if (r) {
       let r = "";
       for (let t = 0; " " === e[t]; t++) r += e[t];
       if (r.length % 2) throw new TypeError("Invalid number of spaces");
       s = r.length, yield t(E, r.length / 2);
      } else s++; else if ('"' === e[0]) {
       let r = "";
       for (let t = 0; ;t++) {
        const n = e[t];
        if (r += n, t > 0 && '"' === n && ("\\" !== e[t - 1] || "\\" === e[t - 2])) break;
       }
       s = r.length;
       try {
        yield t(m, JSON.parse(r));
       } catch (e) {
        if (!(e instanceof SyntaxError)) throw e;
        yield t(b);
       }
      } else if (/^[0-9]/.test(e)) {
       let r = "";
       for (let t = 0; /^[0-9]$/.test(e[t]); t++) r += e[t];
       s = r.length, yield t(_, +r);
      } else if (/^true/.test(e)) yield t(d, !0), s = 4; else if (/^false/.test(e)) yield t(d, !1), 
      s = 5; else if (":" === e[0]) yield t(g), s++; else if ("," === e[0]) yield t(w), 
      s++; else if (/^[a-zA-Z\/-]/g.test(e)) {
       let r = "";
       for (let t = 0; t < e.length; t++) {
        const n = e[t];
        if (":" === n || " " === n || "\n" === n || "\r" === n || "," === n) break;
        r += n;
       }
       s = r.length, yield t(m, r);
      } else yield t(b);
      s || (yield t(b)), i += s, r = "\n" === e[0] || "\r" === e[0] && "\n" === e[1], 
      e = e.slice(s);
     }
     yield t("EOF");
    }(e), this.fileLoc = t;
   }
   onComment(e) {
    const t = e.value;
    (0, (l || n()).default)("string" == typeof t, "expected token value to be a string");
    const s = t.trim(), o = s.match(p);
    if (o) {
     const e = +o[1];
     if (e > (u || i()).LOCKFILE_VERSION) throw new ((f || function t() {
      return f = r(4);
     }()).MessageError)(`Can't install from a lockfile of version ${e} as you're on an old yarn version that only supports versions up to ${(u || i()).LOCKFILE_VERSION}. Run \`$ yarn self-update\` to upgrade to the latest version.`);
    }
    this.comments.push(s);
   }
   next() {
    const e = this.tokens.next();
    (0, (l || n()).default)(e, "expected a token");
    const t = e.done, r = e.value;
    if (t || !r) throw new Error("No more tokens");
    return r.type === v ? (this.onComment(r), this.next()) : this.token = r;
   }
   unexpected(e = "Unexpected token") {
    throw new SyntaxError(`${e} ${this.token.line}:${this.token.col} in ${this.fileLoc}`);
   }
   expect(e) {
    this.token.type === e ? this.next() : this.unexpected();
   }
   eat(e) {
    return this.token.type === e && (this.next(), !0);
   }
   parse(e = 0) {
    var t, i, o, c, u, f, p, d, v;
    const b = (0, (h || function _() {
     return h = s(r(20));
    }()).default)();
    for (;;) {
     const h = this.token;
     if (h.type === y) {
      const t = this.next();
      if (!e) continue;
      if (t.type !== E) break;
      if (t.value !== e) break;
      this.next();
     } else if (h.type === E) {
      if (h.value !== e) break;
      this.next();
     } else {
      if ("EOF" === h.type) break;
      if (h.type === m) {
       const r = h.value;
       (0, (l || n()).default)(r, "Expected a key");
       const s = [ r ];
       for (this.next(); this.token.type === w; ) {
        this.next();
        const e = this.token;
        e.type !== m && this.unexpected("Expected string");
        const t = e.value;
        (0, (l || n()).default)(t, "Expected a key"), s.push(t), this.next();
       }
       const a = this.token;
       if (a.type === g) {
        this.next();
        const r = this.parse(e + 1);
        for (t = s, o = 0, t = (i = Array.isArray(t)) ? t : t[Symbol.iterator](); ;) {
         if (i) {
          if (o >= t.length) break;
          c = t[o++];
         } else {
          if ((o = t.next()).done) break;
          c = o.value;
         }
         b[c] = r;
        }
        if (e && this.token.type !== E) break;
       } else if (v = a, S.indexOf(v.type) >= 0) {
        for (u = s, p = 0, u = (f = Array.isArray(u)) ? u : u[Symbol.iterator](); ;) {
         if (f) {
          if (p >= u.length) break;
          d = u[p++];
         } else {
          if ((p = u.next()).done) break;
          d = p.value;
         }
         b[d] = a.value;
        }
        this.next();
       } else this.unexpected("Invalid value type");
      } else this.unexpected(`Unknown token: ${(a || (a = s(r(2)))).default.inspect(h)}`);
     }
    }
    return b;
   }
  }
  const O = ">>>>>>>", A = "=======", C = "<<<<<<<";
 }, , , function(e, t, r) {
  function n() {
   return i = function e(t) {
    return t && t.__esModule ? t : {
     default: t
    };
   }(r(20));
  }
  var i;
  Object.defineProperty(t, "__esModule", {
   value: !0
  });
  const s = r(212)("yarn");
  t.default = class o {
   constructor(e, t = 1 / 0) {
    this.concurrencyQueue = [], this.maxConcurrency = t, this.runningCount = 0, this.warnedStuck = !1, 
    this.alias = e, this.first = !0, this.running = (0, (i || n()).default)(), this.queue = (0, 
    (i || n()).default)(), this.stuckTick = this.stuckTick.bind(this);
   }
   stillActive() {
    this.stuckTimer && clearTimeout(this.stuckTimer), this.stuckTimer = setTimeout(this.stuckTick, 5e3), 
    this.stuckTimer.unref && this.stuckTimer.unref();
   }
   stuckTick() {
    1 === this.runningCount && (this.warnedStuck = !0, s(`The ${JSON.stringify(this.alias)} blocking queue may be stuck. 5 seconds without any activity with 1 worker: ${Object.keys(this.running)[0]}`));
   }
   push(e, t) {
    return this.first ? this.first = !1 : this.stillActive(), new Promise(((r, n) => {
     (this.queue[e] = this.queue[e] || []).push({
      factory: t,
      resolve: r,
      reject: n
     }), this.running[e] || this.shift(e);
    }));
   }
   shift(e) {
    this.running[e] && (delete this.running[e], this.runningCount--, this.stuckTimer && (clearTimeout(this.stuckTimer), 
    this.stuckTimer = null), this.warnedStuck && (this.warnedStuck = !1, s(`${JSON.stringify(this.alias)} blocking queue finally resolved. Nothing to worry about.`)));
    const t = this.queue[e];
    if (!t) return;
    var r = t.shift();
    const n = r.resolve, i = r.reject, o = r.factory;
    t.length || delete this.queue[e];
    const a = () => {
     this.shift(e), this.shiftConcurrencyQueue();
    };
    this.maybePushConcurrencyQueue((() => {
     this.running[e] = !0, this.runningCount++, o().then((function(e) {
      return n(e), a(), null;
     })).catch((function(e) {
      i(e), a();
     }));
    }));
   }
   maybePushConcurrencyQueue(e) {
    this.runningCount < this.maxConcurrency ? e() : this.concurrencyQueue.push(e);
   }
   shiftConcurrencyQueue() {
    if (this.runningCount < this.maxConcurrency) {
     const e = this.concurrencyQueue.shift();
     e && e();
    }
   }
  };
 }, function(e, t) {
  e.exports = function(e) {
   try {
    return !!e();
   } catch (e) {
    return !0;
   }
  };
 }, , , , , , , , , , , , , , , function(e, t, r) {
  var n = r(47), i = r(13)("toStringTag"), s = "Arguments" == n(function() {
   return arguments;
  }());
  e.exports = function(e) {
   var t, r, o;
   return void 0 === e ? "Undefined" : null === e ? "Null" : "string" == typeof (r = function(e, t) {
    try {
     return e[t];
    } catch (e) {}
   }(t = Object(e), i)) ? r : s ? n(t) : "Object" == (o = n(t)) && "function" == typeof t.callee ? "Arguments" : o;
  };
 }, function(e, t) {
  e.exports = "constructor,hasOwnProperty,isPrototypeOf,propertyIsEnumerable,toLocaleString,toString,valueOf".split(",");
 }, function(e, t, r) {
  var n = r(11).document;
  e.exports = n && n.documentElement;
 }, function(e, t, r) {
  var n = r(69), i = r(41), s = r(197), o = r(31), a = r(35), l = r(188), c = r(71), u = r(194), f = r(13)("iterator"), h = !([].keys && "next" in [].keys()), p = "keys", d = "values", m = function() {
   return this;
  };
  e.exports = function(e, t, r, g, y, v, E) {
   var b, _, w, S, k, O, A, C, T, L, $, x;
   if (l(r, t, g), b = function(e) {
    if (!h && e in k) return k[e];
    switch (e) {
    case p:
     return function t() {
      return new r(this, e);
     };

    case d:
     return function t() {
      return new r(this, e);
     };
    }
    return function t() {
     return new r(this, e);
    };
   }, _ = t + " Iterator", w = y == d, S = !1, k = e.prototype, A = (O = k[f] || k["@@iterator"] || y && k[y]) || b(y), 
   C = y ? w ? b("entries") : A : void 0, (T = "Array" == t && k.entries || O) && (x = u(T.call(new e))) !== Object.prototype && x.next && (c(x, _, !0), 
   n || "function" == typeof x[f] || o(x, f, m)), w && O && O.name !== d && (S = !0, 
   A = function e() {
    return O.call(this);
   }), n && !E || !h && !S && k[f] || o(k, f, A), a[t] = A, a[_] = m, y) if (L = {
    values: w ? A : b(d),
    keys: v ? A : b(p),
    entries: C
   }, E) for ($ in L) $ in k || s(k, $, L[$]); else i(i.P + i.F * (h || S), t, L);
   return L;
  };
 }, function(e, t) {
  e.exports = function(e) {
   try {
    return {
     e: !1,
     v: e()
    };
   } catch (e) {
    return {
     e: !0,
     v: e
    };
   }
  };
 }, function(e, t, r) {
  var n = r(27), i = r(34), s = r(70);
  e.exports = function(e, t) {
   var r;
   return n(e), i(t) && t.constructor === e ? t : ((0, (r = s.f(e)).resolve)(t), r.promise);
  };
 }, function(e, t) {
  e.exports = function(e, t) {
   return {
    enumerable: !(1 & e),
    configurable: !(2 & e),
    writable: !(4 & e),
    value: t
   };
  };
 }, function(e, t, r) {
  var n = r(23), i = r(11), s = "__core-js_shared__", o = i[s] || (i[s] = {});
  (e.exports = function(e, t) {
   return o[e] || (o[e] = void 0 !== t ? t : {});
  })("versions", []).push({
   version: n.version,
   mode: r(69) ? "pure" : "global",
   copyright: "© 2018 Denis Pushkarev (zloirock.ru)"
  });
 }, function(e, t, r) {
  var n = r(27), i = r(46), s = r(13)("species");
  e.exports = function(e, t) {
   var r, o = n(e).constructor;
   return void 0 === o || null == (r = n(o)[s]) ? t : i(r);
  };
 }, function(e, t, r) {
  var n, i, s, o = r(48), a = r(185), l = r(102), c = r(68), u = r(11), f = u.process, h = u.setImmediate, p = u.clearImmediate, d = u.MessageChannel, m = u.Dispatch, g = 0, y = {}, v = "onreadystatechange", E = function() {
   var e, t = +this;
   y.hasOwnProperty(t) && (e = y[t], delete y[t], e());
  }, b = function(e) {
   E.call(e.data);
  };
  h && p || (h = function e(t) {
   for (var r = [], i = 1; arguments.length > i; ) r.push(arguments[i++]);
   return y[++g] = function() {
    a("function" == typeof t ? t : Function(t), r);
   }, n(g), g;
  }, p = function e(t) {
   delete y[t];
  }, "process" == r(47)(f) ? n = function(e) {
   f.nextTick(o(E, e, 1));
  } : m && m.now ? n = function(e) {
   m.now(o(E, e, 1));
  } : d ? (s = (i = new d).port2, i.port1.onmessage = b, n = o(s.postMessage, s, 1)) : u.addEventListener && "function" == typeof postMessage && !u.importScripts ? (n = function(e) {
   u.postMessage(e + "", "*");
  }, u.addEventListener("message", b, !1)) : n = v in c("script") ? function(e) {
   l.appendChild(c("script"))[v] = function() {
    l.removeChild(this), E.call(e);
   };
  } : function(e) {
   setTimeout(o(E, e, 1), 0);
  }), e.exports = {
   set: h,
   clear: p
  };
 }, function(e, t, r) {
  var n = r(73), i = Math.min;
  e.exports = function(e) {
   return e > 0 ? i(n(e), 9007199254740991) : 0;
  };
 }, function(e, t) {
  var r = 0, n = Math.random();
  e.exports = function(e) {
   return "Symbol(".concat(void 0 === e ? "" : e, ")_", (++r + n).toString(36));
  };
 }, function(e, t, r) {
  function n(e) {
   function r() {
    var e, i, s, o, a, l;
    if (r.enabled) {
     for (e = r, s = (i = +new Date) - (n || i), e.diff = s, e.prev = n, e.curr = i, 
     n = i, o = new Array(arguments.length), a = 0; a < o.length; a++) o[a] = arguments[a];
     o[0] = t.coerce(o[0]), "string" != typeof o[0] && o.unshift("%O"), l = 0, o[0] = o[0].replace(/%([a-zA-Z%])/g, (function(r, n) {
      var i, s;
      return "%%" === r || (l++, "function" == typeof (i = t.formatters[n]) && (s = o[l], 
      r = i.call(e, s), o.splice(l, 1), l--)), r;
     })), t.formatArgs.call(e, o), (r.log || t.log || console.log.bind(console)).apply(e, o);
    }
   }
   var n;
   return r.namespace = e, r.enabled = t.enabled(e), r.useColors = t.useColors(), r.color = function s(e) {
    var r, n = 0;
    for (r in e) n = (n << 5) - n + e.charCodeAt(r), n |= 0;
    return t.colors[Math.abs(n) % t.colors.length];
   }(e), r.destroy = i, "function" == typeof t.init && t.init(r), t.instances.push(r), 
   r;
  }
  function i() {
   var e = t.instances.indexOf(this);
   return -1 !== e && (t.instances.splice(e, 1), !0);
  }
  (t = e.exports = n.debug = n.default = n).coerce = function s(e) {
   return e instanceof Error ? e.stack || e.message : e;
  }, t.disable = function o() {
   t.enable("");
  }, t.enable = function a(e) {
   var r, n, i, s;
   for (t.save(e), t.names = [], t.skips = [], i = (n = ("string" == typeof e ? e : "").split(/[\s,]+/)).length, 
   r = 0; r < i; r++) n[r] && ("-" === (e = n[r].replace(/\*/g, ".*?"))[0] ? t.skips.push(new RegExp("^" + e.substr(1) + "$")) : t.names.push(new RegExp("^" + e + "$")));
   for (r = 0; r < t.instances.length; r++) (s = t.instances[r]).enabled = t.enabled(s.namespace);
  }, t.enabled = function l(e) {
   if ("*" === e[e.length - 1]) return !0;
   var r, n;
   for (r = 0, n = t.skips.length; r < n; r++) if (t.skips[r].test(e)) return !1;
   for (r = 0, n = t.names.length; r < n; r++) if (t.names[r].test(e)) return !0;
   return !1;
  }, t.humanize = r(229), t.instances = [], t.names = [], t.skips = [], t.formatters = {};
 }, , function(e, t, r) {
  function n(e) {
   return e && "realpath" === e.syscall && ("ELOOP" === e.code || "ENOMEM" === e.code || "ENAMETOOLONG" === e.code);
  }
  function i(e, t, r) {
   if (u) return a(e, t, r);
   "function" == typeof t && (r = t, t = null), a(e, t, (function(i, s) {
    n(i) ? f.realpath(e, t, r) : r(i, s);
   }));
  }
  function s(e, t) {
   if (u) return l(e, t);
   try {
    return l(e, t);
   } catch (r) {
    if (n(r)) return f.realpathSync(e, t);
    throw r;
   }
  }
  var o, a, l, c, u, f;
  e.exports = i, i.realpath = i, i.sync = s, i.realpathSync = s, i.monkeypatch = function h() {
   o.realpath = i, o.realpathSync = s;
  }, i.unmonkeypatch = function p() {
   o.realpath = a, o.realpathSync = l;
  }, o = r(3), a = o.realpath, l = o.realpathSync, c = process.version, u = /^v[0-5]\./.test(c), 
  f = r(217);
 }, function(e, t, r) {
  function n(e, t) {
   return Object.prototype.hasOwnProperty.call(e, t);
  }
  function i(e, t) {
   return e.toLowerCase().localeCompare(t.toLowerCase());
  }
  function s(e, t) {
   return e.localeCompare(t);
  }
  function o(e) {
   var t, r = null;
   return "/**" === e.slice(-3) && (t = e.replace(/(\/\*\*)+$/, ""), r = new h(t, {
    dot: !0
   })), {
    matcher: new h(e, {
     dot: !0
    }),
    gmatcher: r
   };
  }
  function a(e, t) {
   var r = t;
   return r = "/" === t.charAt(0) ? c.join(e.root, t) : f(t) || "" === t ? t : e.changedCwd ? c.resolve(e.cwd, t) : c.resolve(t), 
   "win32" === process.platform && (r = r.replace(/\\/g, "/")), r;
  }
  function l(e, t) {
   return !!e.ignore.length && e.ignore.some((function(e) {
    return e.matcher.match(t) || !(!e.gmatcher || !e.gmatcher.match(t));
   }));
  }
  var c, u, f, h;
  t.alphasort = s, t.alphasorti = i, t.setopts = function p(e, t, r) {
   if (r || (r = {}), r.matchBase && -1 === t.indexOf("/")) {
    if (r.noglobstar) throw new Error("base matching requires globstar");
    t = "**/" + t;
   }
   e.silent = !!r.silent, e.pattern = t, e.strict = !1 !== r.strict, e.realpath = !!r.realpath, 
   e.realpathCache = r.realpathCache || Object.create(null), e.follow = !!r.follow, 
   e.dot = !!r.dot, e.mark = !!r.mark, e.nodir = !!r.nodir, e.nodir && (e.mark = !0), 
   e.sync = !!r.sync, e.nounique = !!r.nounique, e.nonull = !!r.nonull, e.nosort = !!r.nosort, 
   e.nocase = !!r.nocase, e.stat = !!r.stat, e.noprocess = !!r.noprocess, e.absolute = !!r.absolute, 
   e.maxLength = r.maxLength || 1 / 0, e.cache = r.cache || Object.create(null), e.statCache = r.statCache || Object.create(null), 
   e.symlinks = r.symlinks || Object.create(null), function i(e, t) {
    e.ignore = t.ignore || [], Array.isArray(e.ignore) || (e.ignore = [ e.ignore ]), 
    e.ignore.length && (e.ignore = e.ignore.map(o));
   }(e, r), e.changedCwd = !1;
   var s = process.cwd();
   n(r, "cwd") ? (e.cwd = c.resolve(r.cwd), e.changedCwd = e.cwd !== s) : e.cwd = s, 
   e.root = r.root || c.resolve(e.cwd, "/"), e.root = c.resolve(e.root), "win32" === process.platform && (e.root = e.root.replace(/\\/g, "/")), 
   e.cwdAbs = f(e.cwd) ? e.cwd : a(e, e.cwd), "win32" === process.platform && (e.cwdAbs = e.cwdAbs.replace(/\\/g, "/")), 
   e.nomount = !!r.nomount, r.nonegate = !0, r.nocomment = !0, e.minimatch = new h(t, r), 
   e.options = e.minimatch.options;
  }, t.ownProp = n, t.makeAbs = a, t.finish = function d(e) {
   var t, r, n, o, c, u = e.nounique, f = u ? [] : Object.create(null);
   for (t = 0, r = e.matches.length; t < r; t++) (n = e.matches[t]) && 0 !== Object.keys(n).length ? (c = Object.keys(n), 
   u ? f.push.apply(f, c) : c.forEach((function(e) {
    f[e] = !0;
   }))) : e.nonull && (o = e.minimatch.globSet[t], u ? f.push(o) : f[o] = !0);
   if (u || (f = Object.keys(f)), e.nosort || (f = f.sort(e.nocase ? i : s)), e.mark) {
    for (t = 0; t < f.length; t++) f[t] = e._mark(f[t]);
    e.nodir && (f = f.filter((function(t) {
     var r = !/\/$/.test(t), n = e.cache[t] || e.cache[a(e, t)];
     return r && n && (r = "DIR" !== n && !Array.isArray(n)), r;
    })));
   }
   e.ignore.length && (f = f.filter((function(t) {
    return !l(e, t);
   }))), e.found = f;
  }, t.mark = function m(e, t) {
   var r, n, i, s = a(e, t), o = e.cache[s], l = t;
   return o && (r = "DIR" === o || Array.isArray(o), n = "/" === t.slice(-1), r && !n ? l += "/" : !r && n && (l = l.slice(0, -1)), 
   l !== t && (i = a(e, l), e.statCache[i] = e.statCache[s], e.cache[i] = e.cache[s])), 
   l;
  }, t.isIgnored = l, t.childrenIgnored = function g(e, t) {
   return !!e.ignore.length && e.ignore.some((function(e) {
    return !(!e.gmatcher || !e.gmatcher.match(t));
   }));
  }, c = r(0), u = r(60), f = r(76), h = u.Minimatch;
 }, function(e, t, r) {
  function n(e, t, r, a) {
   var l, c, u;
   "function" == typeof t ? (r = t, t = {}) : t && "object" == typeof t || (t = {
    mode: t
   }), l = t.mode, c = t.fs || s, void 0 === l && (l = o & ~process.umask()), a || (a = null), 
   u = r || function() {}, e = i.resolve(e), c.mkdir(e, l, (function(r) {
    if (!r) return u(null, a = a || e);
    "ENOENT" === r.code ? n(i.dirname(e), t, (function(r, i) {
     r ? u(r, i) : n(e, t, u, i);
    })) : c.stat(e, (function(e, t) {
     e || !t.isDirectory() ? u(r, a) : u(null, a);
    }));
   }));
  }
  var i = r(0), s = r(3), o = parseInt("0777", 8);
  e.exports = n.mkdirp = n.mkdirP = n, n.sync = function e(t, r, n) {
   var a, l, c;
   r && "object" == typeof r || (r = {
    mode: r
   }), a = r.mode, l = r.fs || s, void 0 === a && (a = o & ~process.umask()), n || (n = null), 
   t = i.resolve(t);
   try {
    l.mkdirSync(t, a), n = n || t;
   } catch (s) {
    if ("ENOENT" === s.code) n = e(i.dirname(t), r, n), e(t, r, n); else {
     try {
      c = l.statSync(t);
     } catch (e) {
      throw s;
     }
     if (!c.isDirectory()) throw s;
    }
   }
   return n;
  };
 }, , , , , , function(e, t, r) {
  e.exports = e => {
   if ("string" != typeof e) throw new TypeError("Expected a string, got " + typeof e);
   return 65279 === e.charCodeAt(0) ? e.slice(1) : e;
  };
 }, function(e, t) {
  e.exports = function e(t, r) {
   function n() {
    var e, r, n, i = new Array(arguments.length);
    for (e = 0; e < i.length; e++) i[e] = arguments[e];
    return r = t.apply(this, i), n = i[i.length - 1], "function" == typeof r && r !== n && Object.keys(n).forEach((function(e) {
     r[e] = n[e];
    })), r;
   }
   if (t && r) return e(t)(r);
   if ("function" != typeof t) throw new TypeError("need wrapper function");
   return Object.keys(t).forEach((function(e) {
    n[e] = t[e];
   })), n;
  };
 }, , , , , , , , function(e, t, r) {
  var n = r(47);
  e.exports = Object("z").propertyIsEnumerable(0) ? Object : function(e) {
   return "String" == n(e) ? e.split("") : Object(e);
  };
 }, function(e, t, r) {
  var n = r(195), i = r(101);
  e.exports = Object.keys || function e(t) {
   return n(t, i);
  };
 }, function(e, t, r) {
  var n = r(67);
  e.exports = function(e) {
   return Object(n(e));
  };
 }, , , , , , , , , , , , function(e, t) {
  e.exports = {
   name: "yarn",
   installationMethod: "unknown",
   version: "1.10.0-0",
   license: "BSD-2-Clause",
   preferGlobal: !0,
   description: "📦🐈 Fast, reliable, and secure dependency management.",
   dependencies: {
    "@zkochan/cmd-shim": "^2.2.4",
    "babel-runtime": "^6.26.0",
    bytes: "^3.0.0",
    camelcase: "^4.0.0",
    chalk: "^2.1.0",
    commander: "^2.9.0",
    death: "^1.0.0",
    debug: "^3.0.0",
    "deep-equal": "^1.0.1",
    "detect-indent": "^5.0.0",
    dnscache: "^1.0.1",
    glob: "^7.1.1",
    "gunzip-maybe": "^1.4.0",
    "hash-for-dep": "^1.2.3",
    "imports-loader": "^0.8.0",
    ini: "^1.3.4",
    inquirer: "^3.0.1",
    invariant: "^2.2.0",
    "is-builtin-module": "^2.0.0",
    "is-ci": "^1.0.10",
    "is-webpack-bundle": "^1.0.0",
    leven: "^2.0.0",
    "loud-rejection": "^1.2.0",
    micromatch: "^2.3.11",
    mkdirp: "^0.5.1",
    "node-emoji": "^1.6.1",
    "normalize-url": "^2.0.0",
    "npm-logical-tree": "^1.2.1",
    "object-path": "^0.11.2",
    "proper-lockfile": "^2.0.0",
    puka: "^1.0.0",
    read: "^1.0.7",
    request: "^2.87.0",
    "request-capture-har": "^1.2.2",
    rimraf: "^2.5.0",
    semver: "^5.1.0",
    ssri: "^5.3.0",
    "strip-ansi": "^4.0.0",
    "strip-bom": "^3.0.0",
    "tar-fs": "^1.16.0",
    "tar-stream": "^1.6.1",
    uuid: "^3.0.1",
    "v8-compile-cache": "^2.0.0",
    "validate-npm-package-license": "^3.0.3",
    yn: "^2.0.0"
   },
   devDependencies: {
    "babel-core": "^6.26.0",
    "babel-eslint": "^7.2.3",
    "babel-loader": "^6.2.5",
    "babel-plugin-array-includes": "^2.0.3",
    "babel-plugin-transform-builtin-extend": "^1.1.2",
    "babel-plugin-transform-inline-imports-commonjs": "^1.0.0",
    "babel-plugin-transform-runtime": "^6.4.3",
    "babel-preset-env": "^1.6.0",
    "babel-preset-flow": "^6.23.0",
    "babel-preset-stage-0": "^6.0.0",
    babylon: "^6.5.0",
    commitizen: "^2.9.6",
    "cz-conventional-changelog": "^2.0.0",
    eslint: "^4.3.0",
    "eslint-config-fb-strict": "^22.0.0",
    "eslint-plugin-babel": "^5.0.0",
    "eslint-plugin-flowtype": "^2.35.0",
    "eslint-plugin-jasmine": "^2.6.2",
    "eslint-plugin-jest": "^21.0.0",
    "eslint-plugin-jsx-a11y": "^6.0.2",
    "eslint-plugin-prefer-object-spread": "^1.2.1",
    "eslint-plugin-prettier": "^2.1.2",
    "eslint-plugin-react": "^7.1.0",
    "eslint-plugin-relay": "^0.0.24",
    "eslint-plugin-yarn-internal": "file:scripts/eslint-rules",
    execa: "^0.10.0",
    "flow-bin": "^0.66.0",
    "git-release-notes": "^3.0.0",
    gulp: "^3.9.0",
    "gulp-babel": "^7.0.0",
    "gulp-if": "^2.0.1",
    "gulp-newer": "^1.0.0",
    "gulp-plumber": "^1.0.1",
    "gulp-sourcemaps": "^2.2.0",
    "gulp-util": "^3.0.7",
    "gulp-watch": "^5.0.0",
    jest: "^22.4.4",
    jsinspect: "^0.12.6",
    minimatch: "^3.0.4",
    "mock-stdin": "^0.3.0",
    prettier: "^1.5.2",
    temp: "^0.8.3",
    webpack: "^2.1.0-beta.25",
    yargs: "^6.3.0"
   },
   resolutions: {
    sshpk: "^1.14.2"
   },
   engines: {
    node: ">=4.0.0"
   },
   repository: "yarnpkg/yarn",
   bin: {
    yarn: "./bin/yarn.js",
    yarnpkg: "./bin/yarn.js"
   },
   scripts: {
    build: "gulp build",
    "build-bundle": "node ./scripts/build-webpack.js",
    "build-chocolatey": "powershell ./scripts/build-chocolatey.ps1",
    "build-deb": "./scripts/build-deb.sh",
    "build-dist": "bash ./scripts/build-dist.sh",
    "build-win-installer": "scripts\\build-windows-installer.bat",
    changelog: "git-release-notes $(git describe --tags --abbrev=0 $(git describe --tags --abbrev=0)^)..$(git describe --tags --abbrev=0) scripts/changelog.md",
    "dupe-check": "yarn jsinspect ./src",
    lint: "eslint . && flow check",
    "pkg-tests": "yarn --cwd packages/pkg-tests jest yarn.test.js",
    prettier: "eslint src __tests__ --fix",
    "release-branch": "./scripts/release-branch.sh",
    test: "yarn lint && yarn test-only",
    "test-only": "node --max_old_space_size=4096 node_modules/jest/bin/jest.js --verbose",
    "test-only-debug": "node --inspect-brk --max_old_space_size=4096 node_modules/jest/bin/jest.js --runInBand --verbose",
    "test-coverage": "node --max_old_space_size=4096 node_modules/jest/bin/jest.js --coverage --verbose",
    watch: "gulp watch",
    commit: "git-cz"
   },
   jest: {
    collectCoverageFrom: [ "src/**/*.js" ],
    testEnvironment: "node",
    modulePathIgnorePatterns: [ "__tests__/fixtures/", "packages/pkg-tests/pkg-tests-fixtures", "dist/" ],
    testPathIgnorePatterns: [ "__tests__/(fixtures|__mocks__)/", "updates/", "_(temp|mock|install|init|helpers).js$", "packages/pkg-tests" ]
   },
   config: {
    commitizen: {
     path: "./node_modules/cz-conventional-changelog"
    }
   }
  };
 }, , , , , function(e, t, r) {
  function n() {
   return a = r(12);
  }
  function i(e) {
   return "boolean" == typeof e || "number" == typeof e || function t(e) {
    return 0 === e.indexOf("true") || 0 === e.indexOf("false") || /[:\s\n\\",\[\]]/g.test(e) || /^[0-9]/g.test(e) || !/^[a-zA-Z]/g.test(e);
   }(e) ? JSON.stringify(e) : e;
  }
  function s(e, t) {
   return h[e] || h[t] ? (h[e] || 100) > (h[t] || 100) ? 1 : -1 : (0, (a || n()).sortAlpha)(e, t);
  }
  function o(e, t) {
   if ("object" != typeof e) throw new TypeError;
   const r = t.indent, l = [], c = Object.keys(e).sort(s);
   let u = [];
   for (let s = 0; s < c.length; s++) {
    const f = c[s], h = e[f];
    if (null == h || u.indexOf(f) >= 0) continue;
    const p = [ f ];
    if ("object" == typeof h) for (let t = s + 1; t < c.length; t++) {
     const r = c[t];
     h === e[r] && p.push(r);
    }
    const d = p.sort((a || n()).sortAlpha).map(i).join(", ");
    if ("string" == typeof h || "boolean" == typeof h || "number" == typeof h) l.push(`${d} ${i(h)}`); else {
     if ("object" != typeof h) throw new TypeError;
     l.push(`${d}:\n${o(h, {
      indent: r + "  "
     })}` + (t.topLevel ? "\n" : ""));
    }
    u = u.concat(p);
   }
   return r + l.join(`\n${r}`);
  }
  var a, l, c;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.default = function u(e, t, n) {
   const i = o(e, {
    indent: "",
    topLevel: !0
   });
   if (t) return i;
   const s = [];
   return s.push("# THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY."), 
   s.push(`# yarn lockfile v${(l || function a() {
    return l = r(6);
   }()).LOCKFILE_VERSION}`), n && (s.push(`# yarn v${(c || function u() {
    return c = r(145);
   }()).version}`), s.push(`# node ${f}`)), s.push("\n"), s.push(i), s.join("\n");
  };
  const f = process.version, h = {
   name: 1,
   version: 2,
   uid: 3,
   resolved: 4,
   integrity: 5,
   registry: 6,
   dependencies: 7
  };
 }, , , , , , , , , , , , , , function(e, t, r) {
  function n() {
   return a = o(r(1));
  }
  function i() {
   return l = o(r(3));
  }
  function s() {
   return c = r(40);
  }
  function o(e) {
   return e && e.__esModule ? e : {
    default: e
   };
  }
  var a, l, c, u, f, h;
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.fileDatesEqual = t.copyFile = t.unlink = void 0;
  let p, d = (u = (0, (a || n()).default)((function*(e, t, r) {
   const n = void 0 === e;
   let i = e || -1;
   if (void 0 === p) {
    const e = yield y(t);
    p = k(e.mtime, r.mtime);
   }
   if (!p) {
    if (n) try {
     i = yield v(t, "a", r.mode);
    } catch (e) {
     try {
      i = yield v(t, "r", r.mode);
     } catch (e) {
      return;
     }
    }
    try {
     i && (yield E(i, r.atime, r.mtime));
    } catch (e) {} finally {
     n && i && (yield g(i));
    }
   }
  })), function e(t, r, n) {
   return u.apply(this, arguments);
  });
  const m = (0, (c || s()).promisify)((l || i()).default.readFile), g = (0, (c || s()).promisify)((l || i()).default.close), y = (0, 
  (c || s()).promisify)((l || i()).default.lstat), v = (0, (c || s()).promisify)((l || i()).default.open), E = (0, 
  (c || s()).promisify)((l || i()).default.futimes), b = (0, (c || s()).promisify)((l || i()).default.write), _ = t.unlink = (0, 
  (c || s()).promisify)(r(233));
  t.copyFile = (f = (0, (a || n()).default)((function*(e, t) {
   try {
    yield _(e.dest), yield w(e.src, e.dest, 0, e);
   } finally {
    t && t();
   }
  })), function e(t, r) {
   return f.apply(this, arguments);
  });
  const w = (e, t, r, n) => (l || i()).default.copyFile ? new Promise(((s, o) => (l || i()).default.copyFile(e, t, r, (e => {
   e ? o(e) : d(void 0, t, n).then((() => s())).catch((e => o(e)));
  })))) : S(e, t, r, n), S = (h = (0, (a || n()).default)((function*(e, t, r, n) {
   const i = yield v(t, "w", n.mode);
   try {
    const r = yield m(e);
    yield b(i, r, 0, r.length), yield d(i, t, n);
   } finally {
    yield g(i);
   }
  })), function e(t, r, n, i) {
   return h.apply(this, arguments);
  }), k = t.fileDatesEqual = (e, t) => {
   const r = e.getTime(), n = t.getTime();
   if ("win32" !== process.platform) return r === n;
   if (Math.abs(r - n) <= 1) return !0;
   const i = Math.floor(r / 1e3), s = Math.floor(n / 1e3);
   return r - 1e3 * i == 0 || n - 1e3 * s == 0 ? i === s : r === n;
  };
 }, , , , , function(e, t, r) {
  function n() {
   return Boolean(process.env.FAKEROOTKEY);
  }
  function i(e) {
   return 0 === e;
  }
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.isFakeRoot = n, t.isRootUser = i, t.default = i(function s() {
   return "win32" !== process.platform && process.getuid ? process.getuid() : null;
  }()) && !n();
 }, , function(e, t, r) {
  function n() {
   return process.env.LOCALAPPDATA ? a.join(process.env.LOCALAPPDATA, "Yarn") : null;
  }
  Object.defineProperty(t, "__esModule", {
   value: !0
  }), t.getDataDir = function i() {
   if ("win32" === process.platform) {
    const e = n();
    return null == e ? c : a.join(e, "Data");
   }
   return process.env.XDG_DATA_HOME ? a.join(process.env.XDG_DATA_HOME, "yarn") : c;
  }, t.getCacheDir = function s() {
   return "win32" === process.platform ? a.join(n() || a.join(l, "AppData", "Local", "Yarn"), "Cache") : process.env.XDG_CACHE_HOME ? a.join(process.env.XDG_CACHE_HOME, "yarn") : "darwin" === process.platform ? a.join(l, "Library", "Caches", "Yarn") : u;
  }, t.getConfigDir = function o() {
   if ("win32" === process.platform) {
    const e = n();
    return null == e ? c : a.join(e, "Config");
   }
   return process.env.XDG_CONFIG_HOME ? a.join(process.env.XDG_CONFIG_HOME, "yarn") : c;
  };
  const a = r(0), l = r(45).default, c = a.join(l, ".config", "yarn"), u = a.join(l, ".cache", "yarn");
 }, , function(e, t, r) {
  e.exports = {
   default: r(179),
   __esModule: !0
  };
 }, function(e, t, r) {
  function n(e, t, r) {
   e instanceof RegExp && (e = i(e, r)), t instanceof RegExp && (t = i(t, r));
   var n = s(e, t, r);
   return n && {
    start: n[0],
    end: n[1],
    pre: r.slice(0, n[0]),
    body: r.slice(n[0] + e.length, n[1]),
    post: r.slice(n[1] + t.length)
   };
  }
  function i(e, t) {
   var r = t.match(e);
   return r ? r[0] : null;
  }
  function s(e, t, r) {
   var n, i, s, o, a, l = r.indexOf(e), c = r.indexOf(t, l + 1), u = l;
   if (l >= 0 && c > 0) {
    for (n = [], s = r.length; u >= 0 && !a; ) u == l ? (n.push(u), l = r.indexOf(e, u + 1)) : 1 == n.length ? a = [ n.pop(), c ] : ((i = n.pop()) < s && (s = i, 
    o = c), c = r.indexOf(t, u + 1)), u = l < c && l >= 0 ? l : c;
    n.length && (a = [ s, o ]);
   }
   return a;
  }
  e.exports = n, n.range = s;
 }, function(e, t, r) {
  function n(e) {
   return parseInt(e, 10) == e ? parseInt(e, 10) : e.charCodeAt(0);
  }
  function i(e) {
   return e.split(f).join("\\").split(h).join("{").split(p).join("}").split(d).join(",").split(m).join(".");
  }
  function s(e) {
   var t, r, n, i, o, a, l;
   return e ? (t = [], (r = y("{", "}", e)) ? (n = r.pre, i = r.body, o = r.post, (a = n.split(","))[a.length - 1] += "{" + i + "}", 
   l = s(o), o.length && (a[a.length - 1] += l.shift(), a.push.apply(a, l)), t.push.apply(t, a), 
   t) : e.split(",")) : [ "" ];
  }
  function o(e) {
   return "{" + e + "}";
  }
  function a(e) {
   return /^-?0\d/.test(e);
  }
  function l(e, t) {
   return e <= t;
  }
  function c(e, t) {
   return e >= t;
  }
  function u(e, t) {
   var r, i, f, h, d, m, v, E, b, _, w, S, k, O, A, C, T, L, $, x, R, N = [], I = y("{", "}", e);
   if (!I || /\$$/.test(I.pre)) return [ e ];
   if (r = /^-?\d+\.\.-?\d+(?:\.\.-?\d+)?$/.test(I.body), i = /^[a-zA-Z]\.\.[a-zA-Z](?:\.\.-?\d+)?$/.test(I.body), 
   f = r || i, h = I.body.indexOf(",") >= 0, !f && !h) return I.post.match(/,.*\}/) ? u(e = I.pre + "{" + I.body + p + I.post) : [ e ];
   if (f) d = I.body.split(/\.\./); else if (1 === (d = s(I.body)).length && 1 === (d = u(d[0], !1).map(o)).length) return (m = I.post.length ? u(I.post, !1) : [ "" ]).map((function(e) {
    return I.pre + d[0] + e;
   }));
   if (v = I.pre, m = I.post.length ? u(I.post, !1) : [ "" ], f) for (b = n(d[0]), 
   _ = n(d[1]), w = Math.max(d[0].length, d[1].length), S = 3 == d.length ? Math.abs(n(d[2])) : 1, 
   k = l, _ < b && (S *= -1, k = c), O = d.some(a), E = [], A = b; k(A, _); A += S) i ? "\\" === (C = String.fromCharCode(A)) && (C = "") : (C = String(A), 
   O && (T = w - C.length) > 0 && (L = new Array(T + 1).join("0"), C = A < 0 ? "-" + L + C.slice(1) : L + C)), 
   E.push(C); else E = g(d, (function(e) {
    return u(e, !1);
   }));
   for ($ = 0; $ < E.length; $++) for (x = 0; x < m.length; x++) R = v + E[$] + m[x], 
   (!t || f || R) && N.push(R);
   return N;
  }
  var f, h, p, d, m, g = r(178), y = r(174);
  e.exports = function v(e) {
   return e ? ("{}" === e.substr(0, 2) && (e = "\\{\\}" + e.substr(2)), u(function t(e) {
    return e.split("\\\\").join(f).split("\\{").join(h).split("\\}").join(p).split("\\,").join(d).split("\\.").join(m);
   }(e), !0).map(i)) : [];
  }, f = "\0SLASH" + Math.random() + "\0", h = "\0OPEN" + Math.random() + "\0", p = "\0CLOSE" + Math.random() + "\0", 
  d = "\0COMMA" + Math.random() + "\0", m = "\0PERIOD" + Math.random() + "\0";
 }, function(e, t, r) {
  function n(e) {
   let t = !1, r = !1, n = !1;
   for (let i = 0; i < e.length; i++) {
    const s = e[i];
    t && /[a-zA-Z]/.test(s) && s.toUpperCase() === s ? (e = e.substr(0, i) + "-" + e.substr(i), 
    t = !1, n = r, r = !0, i++) : r && n && /[a-zA-Z]/.test(s) && s.toLowerCase() === s ? (e = e.substr(0, i - 1) + "-" + e.substr(i - 1), 
    n = r, r = !1, t = !0) : (t = s.toLowerCase() === s, n = r, r = s.toUpperCase() === s);
   }
   return e;
  }
  e.exports = function(e) {
   if (0 === (e = arguments.length > 1 ? Array.from(arguments).map((e => e.trim())).filter((e => e.length)).join("-") : e.trim()).length) return "";
   if (1 === e.length) return e.toLowerCase();
   if (/^[a-z0-9]+$/.test(e)) return e;
   const t = e !== e.toLowerCase();
   return t && (e = n(e)), e.replace(/^[_.\- ]+/, "").toLowerCase().replace(/[_.\- ]+(\w|$)/g, ((e, t) => t.toUpperCase()));
  };
 }, , function(e, t) {
  e.exports = function(e, t) {
   var n, i, s = [];
   for (n = 0; n < e.length; n++) i = t(e[n], n), r(i) ? s.push.apply(s, i) : s.push(i);
   return s;
  };
  var r = Array.isArray || function(e) {
   return "[object Array]" === Object.prototype.toString.call(e);
  };
 }, function(e, t, r) {
  r(205), r(207), r(210), r(206), r(208), r(209), e.exports = r(23).Promise;
 }, function(e, t) {
  e.exports = function() {};
 }, function(e, t) {
  e.exports = function(e, t, r, n) {
   if (!(e instanceof t) || void 0 !== n && n in e) throw TypeError(r + ": incorrect invocation!");
   return e;
  };
 }, function(e, t, r) {
  var n = r(74), i = r(110), s = r(200);
  e.exports = function(e) {
   return function(t, r, o) {
    var a, l = n(t), c = i(l.length), u = s(o, c);
    if (e && r != r) {
     for (;c > u; ) if ((a = l[u++]) != a) return !0;
    } else for (;c > u; u++) if ((e || u in l) && l[u] === r) return e || u || 0;
    return !e && -1;
   };
  };
 }, function(e, t, r) {
  var n = r(48), i = r(187), s = r(186), o = r(27), a = r(110), l = r(203), c = {}, u = {};
  t = e.exports = function(e, t, r, f, h) {
   var p, d, m, g, y = h ? function() {
    return e;
   } : l(e), v = n(r, f, t ? 2 : 1), E = 0;
   if ("function" != typeof y) throw TypeError(e + " is not iterable!");
   if (s(y)) {
    for (p = a(e.length); p > E; E++) if ((g = t ? v(o(d = e[E])[0], d[1]) : v(e[E])) === c || g === u) return g;
   } else for (m = y.call(e); !(d = m.next()).done; ) if ((g = i(m, v, d.value, t)) === c || g === u) return g;
  }, t.BREAK = c, t.RETURN = u;
 }, function(e, t, r) {
  e.exports = !r(33) && !r(85)((function() {
   return 7 != Object.defineProperty(r(68)("div"), "a", {
    get: function() {
     return 7;
    }
   }).a;
  }));
 }, function(e, t) {
  e.exports = function(e, t, r) {
   var n = void 0 === r;
   switch (t.length) {
   case 0:
    return n ? e() : e.call(r);

   case 1:
    return n ? e(t[0]) : e.call(r, t[0]);

   case 2:
    return n ? e(t[0], t[1]) : e.call(r, t[0], t[1]);

   case 3:
    return n ? e(t[0], t[1], t[2]) : e.call(r, t[0], t[1], t[2]);

   case 4:
    return n ? e(t[0], t[1], t[2], t[3]) : e.call(r, t[0], t[1], t[2], t[3]);
   }
   return e.apply(r, t);
  };
 }, function(e, t, r) {
  var n = r(35), i = r(13)("iterator"), s = Array.prototype;
  e.exports = function(e) {
   return void 0 !== e && (n.Array === e || s[i] === e);
  };
 }, function(e, t, r) {
  var n = r(27);
  e.exports = function(e, t, r, i) {
   try {
    return i ? t(n(r)[0], r[1]) : t(r);
   } catch (t) {
    var s = e.return;
    throw void 0 !== s && n(s.call(e)), t;
   }
  };
 }, function(e, t, r) {
  var n = r(192), i = r(106), s = r(71), o = {};
  r(31)(o, r(13)("iterator"), (function() {
   return this;
  })), e.exports = function(e, t, r) {
   e.prototype = n(o, {
    next: i(1, r)
   }), s(e, t + " Iterator");
  };
 }, function(e, t, r) {
  var n, i = r(13)("iterator"), s = !1;
  try {
   (n = [ 7 ][i]()).return = function() {
    s = !0;
   }, Array.from(n, (function() {
    throw 2;
   }));
  } catch (e) {}
  e.exports = function(e, t) {
   var r, n, o;
   if (!t && !s) return !1;
   r = !1;
   try {
    (o = (n = [ 7 ])[i]()).next = function() {
     return {
      done: r = !0
     };
    }, n[i] = function() {
     return o;
    }, e(n);
   } catch (e) {}
   return r;
  };
 }, function(e, t) {
  e.exports = function(e, t) {
   return {
    value: t,
    done: !!e
   };
  };
 }, function(e, t, r) {
  var n = r(11), i = r(109).set, s = n.MutationObserver || n.WebKitMutationObserver, o = n.process, a = n.Promise, l = "process" == r(47)(o);
  e.exports = function() {
   var e, t, r, c, u, f, h = function() {
    var n, i;
    for (l && (n = o.domain) && n.exit(); e; ) {
     i = e.fn, e = e.next;
     try {
      i();
     } catch (n) {
      throw e ? r() : t = void 0, n;
     }
    }
    t = void 0, n && n.enter();
   };
   return l ? r = function() {
    o.nextTick(h);
   } : !s || n.navigator && n.navigator.standalone ? a && a.resolve ? (f = a.resolve(void 0), 
   r = function() {
    f.then(h);
   }) : r = function() {
    i.call(n, h);
   } : (c = !0, u = document.createTextNode(""), new s(h).observe(u, {
    characterData: !0
   }), r = function() {
    u.data = c = !c;
   }), function(n) {
    var i = {
     fn: n,
     next: void 0
    };
    t && (t.next = i), e || (e = i, r()), t = i;
   };
  };
 }, function(e, t, r) {
  var n = r(27), i = r(193), s = r(101), o = r(72)("IE_PROTO"), a = function() {}, l = "prototype", c = function() {
   var e, t = r(68)("iframe"), n = s.length;
   for (t.style.display = "none", r(102).appendChild(t), t.src = "javascript:", (e = t.contentWindow.document).open(), 
   e.write("<script>document.F=Object<\/script>"), e.close(), c = e.F; n--; ) delete c[l][s[n]];
   return c();
  };
  e.exports = Object.create || function e(t, r) {
   var s;
   return null !== t ? (a[l] = n(t), s = new a, a[l] = null, s[o] = t) : s = c(), void 0 === r ? s : i(s, r);
  };
 }, function(e, t, r) {
  var n = r(50), i = r(27), s = r(132);
  e.exports = r(33) ? Object.defineProperties : function e(t, r) {
   var o, a, l, c;
   for (i(t), a = (o = s(r)).length, l = 0; a > l; ) n.f(t, c = o[l++], r[c]);
   return t;
  };
 }, function(e, t, r) {
  var n = r(49), i = r(133), s = r(72)("IE_PROTO"), o = Object.prototype;
  e.exports = Object.getPrototypeOf || function(e) {
   return e = i(e), n(e, s) ? e[s] : "function" == typeof e.constructor && e instanceof e.constructor ? e.constructor.prototype : e instanceof Object ? o : null;
  };
 }, function(e, t, r) {
  var n = r(49), i = r(74), s = r(182)(!1), o = r(72)("IE_PROTO");
  e.exports = function(e, t) {
   var r, a = i(e), l = 0, c = [];
   for (r in a) r != o && n(a, r) && c.push(r);
   for (;t.length > l; ) n(a, r = t[l++]) && (~s(c, r) || c.push(r));
   return c;
  };
 }, function(e, t, r) {
  var n = r(31);
  e.exports = function(e, t, r) {
   for (var i in t) r && e[i] ? e[i] = t[i] : n(e, i, t[i]);
   return e;
  };
 }, function(e, t, r) {
  e.exports = r(31);
 }, function(e, t, r) {
  var n = r(11), i = r(23), s = r(50), o = r(33), a = r(13)("species");
  e.exports = function(e) {
   var t = "function" == typeof i[e] ? i[e] : n[e];
   o && t && !t[a] && s.f(t, a, {
    configurable: !0,
    get: function() {
     return this;
    }
   });
  };
 }, function(e, t, r) {
  var n = r(73), i = r(67);
  e.exports = function(e) {
   return function(t, r) {
    var s, o, a = String(i(t)), l = n(r), c = a.length;
    return l < 0 || l >= c ? e ? "" : void 0 : (s = a.charCodeAt(l)) < 55296 || s > 56319 || l + 1 === c || (o = a.charCodeAt(l + 1)) < 56320 || o > 57343 ? e ? a.charAt(l) : s : e ? a.slice(l, l + 2) : o - 56320 + (s - 55296 << 10) + 65536;
   };
  };
 }, function(e, t, r) {
  var n = r(73), i = Math.max, s = Math.min;
  e.exports = function(e, t) {
   return (e = n(e)) < 0 ? i(e + t, 0) : s(e, t);
  };
 }, function(e, t, r) {
  var n = r(34);
  e.exports = function(e, t) {
   if (!n(e)) return e;
   var r, i;
   if (t && "function" == typeof (r = e.toString) && !n(i = r.call(e))) return i;
   if ("function" == typeof (r = e.valueOf) && !n(i = r.call(e))) return i;
   if (!t && "function" == typeof (r = e.toString) && !n(i = r.call(e))) return i;
   throw TypeError("Can't convert object to primitive value");
  };
 }, function(e, t, r) {
  var n = r(11).navigator;
  e.exports = n && n.userAgent || "";
 }, function(e, t, r) {
  var n = r(100), i = r(13)("iterator"), s = r(35);
  e.exports = r(23).getIteratorMethod = function(e) {
   if (null != e) return e[i] || e["@@iterator"] || s[n(e)];
  };
 }, function(e, t, r) {
  var n = r(180), i = r(190), s = r(35), o = r(74);
  e.exports = r(103)(Array, "Array", (function(e, t) {
   this._t = o(e), this._i = 0, this._k = t;
  }), (function() {
   var e = this._t, t = this._k, r = this._i++;
   return !e || r >= e.length ? (this._t = void 0, i(1)) : i(0, "keys" == t ? r : "values" == t ? e[r] : [ r, e[r] ]);
  }), "values"), s.Arguments = s.Array, n("keys"), n("values"), n("entries");
 }, function(e, t) {}, function(e, t, r) {
  var n, i, s, o, a = r(69), l = r(11), c = r(48), u = r(100), f = r(41), h = r(34), p = r(46), d = r(181), m = r(183), g = r(108), y = r(109).set, v = r(191)(), E = r(70), b = r(104), _ = r(202), w = r(105), S = "Promise", k = l.TypeError, O = l.process, A = O && O.versions, C = A && A.v8 || "", T = l[S], L = "process" == u(O), $ = function() {}, x = i = E.f, R = !!function() {
   var e, t;
   try {
    return t = ((e = T.resolve(1)).constructor = {})[r(13)("species")] = function(e) {
     e($, $);
    }, (L || "function" == typeof PromiseRejectionEvent) && e.then($) instanceof t && 0 !== C.indexOf("6.6") && -1 === _.indexOf("Chrome/66");
   } catch (e) {}
  }(), N = function(e) {
   var t;
   return !(!h(e) || "function" != typeof (t = e.then)) && t;
  }, I = function(e, t) {
   if (!e._n) {
    e._n = !0;
    var r = e._c;
    v((function() {
     for (var n = e._v, i = 1 == e._s, s = 0, o = function(t) {
      var r, s, o, a = i ? t.ok : t.fail, l = t.resolve, c = t.reject, u = t.domain;
      try {
       a ? (i || (2 == e._h && D(e), e._h = 1), !0 === a ? r = n : (u && u.enter(), r = a(n), 
       u && (u.exit(), o = !0)), r === t.promise ? c(k("Promise-chain cycle")) : (s = N(r)) ? s.call(r, l, c) : l(r)) : c(n);
      } catch (e) {
       u && !o && u.exit(), c(e);
      }
     }; r.length > s; ) o(r[s++]);
     e._c = [], e._n = !1, t && !e._h && P(e);
    }));
   }
  }, P = function(e) {
   y.call(l, (function() {
    var t, r, n, i = e._v, s = j(e);
    if (s && (t = b((function() {
     L ? O.emit("unhandledRejection", i, e) : (r = l.onunhandledrejection) ? r({
      promise: e,
      reason: i
     }) : (n = l.console) && n.error && n.error("Unhandled promise rejection", i);
    })), e._h = L || j(e) ? 2 : 1), e._a = void 0, s && t.e) throw t.v;
   }));
  }, j = function(e) {
   return 1 !== e._h && 0 === (e._a || e._c).length;
  }, D = function(e) {
   y.call(l, (function() {
    var t;
    L ? O.emit("rejectionHandled", e) : (t = l.onrejectionhandled) && t({
     promise: e,
     reason: e._v
    });
   }));
  }, F = function(e) {
   var t = this;
   t._d || (t._d = !0, (t = t._w || t)._v = e, t._s = 2, t._a || (t._a = t._c.slice()), 
   I(t, !0));
  }, M = function(e) {
   var t, r = this;
   if (!r._d) {
    r._d = !0, r = r._w || r;
    try {
     if (r === e) throw k("Promise can't be resolved itself");
     (t = N(e)) ? v((function() {
      var n = {
       _w: r,
       _d: !1
      };
      try {
       t.call(e, c(M, n, 1), c(F, n, 1));
      } catch (e) {
       F.call(n, e);
      }
     })) : (r._v = e, r._s = 1, I(r, !1));
    } catch (e) {
     F.call({
      _w: r,
      _d: !1
     }, e);
    }
   }
  };
  R || (T = function e(t) {
   d(this, T, S, "_h"), p(t), n.call(this);
   try {
    t(c(M, this, 1), c(F, this, 1));
   } catch (e) {
    F.call(this, e);
   }
  }, (n = function e(t) {
   this._c = [], this._a = void 0, this._s = 0, this._d = !1, this._v = void 0, this._h = 0, 
   this._n = !1;
  }).prototype = r(196)(T.prototype, {
   then: function e(t, r) {
    var n = x(g(this, T));
    return n.ok = "function" != typeof t || t, n.fail = "function" == typeof r && r, 
    n.domain = L ? O.domain : void 0, this._c.push(n), this._a && this._a.push(n), this._s && I(this, !1), 
    n.promise;
   },
   catch: function(e) {
    return this.then(void 0, e);
   }
  }), s = function() {
   var e = new n;
   this.promise = e, this.resolve = c(M, e, 1), this.reject = c(F, e, 1);
  }, E.f = x = function(e) {
   return e === T || e === o ? new s(e) : i(e);
  }), f(f.G + f.W + f.F * !R, {
   Promise: T
  }), r(71)(T, S), r(198)(S), o = r(23)[S], f(f.S + f.F * !R, S, {
   reject: function e(t) {
    var r = x(this);
    return (0, r.reject)(t), r.promise;
   }
  }), f(f.S + f.F * (a || !R), S, {
   resolve: function e(t) {
    return w(a && this === o ? T : this, t);
   }
  }), f(f.S + f.F * !(R && r(189)((function(e) {
   T.all(e).catch($);
  }))), S, {
   all: function e(t) {
    var r = this, n = x(r), i = n.resolve, s = n.reject, o = b((function() {
     var e = [], n = 0, o = 1;
     m(t, !1, (function(t) {
      var a = n++, l = !1;
      e.push(void 0), o++, r.resolve(t).then((function(t) {
       l || (l = !0, e[a] = t, --o || i(e));
      }), s);
     })), --o || i(e);
    }));
    return o.e && s(o.v), n.promise;
   },
   race: function e(t) {
    var r = this, n = x(r), i = n.reject, s = b((function() {
     m(t, !1, (function(e) {
      r.resolve(e).then(n.resolve, i);
     }));
    }));
    return s.e && i(s.v), n.promise;
   }
  });
 }, function(e, t, r) {
  var n = r(199)(!0);
  r(103)(String, "String", (function(e) {
   this._t = String(e), this._i = 0;
  }), (function() {
   var e, t = this._t, r = this._i;
   return r >= t.length ? {
    value: void 0,
    done: !0
   } : (e = n(t, r), this._i += e.length, {
    value: e,
    done: !1
   });
  }));
 }, function(e, t, r) {
  var n = r(41), i = r(23), s = r(11), o = r(108), a = r(105);
  n(n.P + n.R, "Promise", {
   finally: function(e) {
    var t = o(this, i.Promise || s.Promise), r = "function" == typeof e;
    return this.then(r ? function(r) {
     return a(t, e()).then((function() {
      return r;
     }));
    } : e, r ? function(r) {
     return a(t, e()).then((function() {
      throw r;
     }));
    } : e);
   }
  });
 }, function(e, t, r) {
  var n = r(41), i = r(70), s = r(104);
  n(n.S, "Promise", {
   try: function(e) {
    var t = i.f(this), r = s(e);
    return (r.e ? t.reject : t.resolve)(r.v), t.promise;
   }
  });
 }, function(e, t, r) {
  var n, i, s, o, a, l, c, u, f;
  for (r(204), n = r(11), i = r(31), s = r(35), o = r(13)("toStringTag"), a = "CSSRuleList,CSSStyleDeclaration,CSSValueList,ClientRectList,DOMRectList,DOMStringList,DOMTokenList,DataTransferItemList,FileList,HTMLAllCollection,HTMLCollection,HTMLFormElement,HTMLSelectElement,MediaList,MimeTypeArray,NamedNodeMap,NodeList,PaintRequestList,Plugin,PluginArray,SVGLengthList,SVGNumberList,SVGPathSegList,SVGPointList,SVGStringList,SVGTransformList,SourceBufferList,StyleSheetList,TextTrackCueList,TextTrackList,TouchList".split(","), 
  l = 0; l < a.length; l++) (f = (u = n[c = a[l]]) && u.prototype) && !f[o] && i(f, o, c), 
  s[c] = s.Array;
 }, function(e, t, r) {
  function n() {
   var e;
   try {
    e = t.storage.debug;
   } catch (e) {}
   return !e && "undefined" != typeof process && "env" in process && (e = process.env.DEBUG), 
   e;
  }
  (t = e.exports = r(112)).log = function i() {
   return "object" == typeof console && console.log && Function.prototype.apply.call(console.log, console, arguments);
  }, t.formatArgs = function s(e) {
   var r, n, i, s = this.useColors;
   e[0] = (s ? "%c" : "") + this.namespace + (s ? " %c" : " ") + e[0] + (s ? "%c " : " ") + "+" + t.humanize(this.diff), 
   s && (r = "color: " + this.color, e.splice(1, 0, r, "color: inherit"), n = 0, i = 0, 
   e[0].replace(/%[a-zA-Z%]/g, (function(e) {
    "%%" !== e && (n++, "%c" === e && (i = n));
   })), e.splice(i, 0, r));
  }, t.save = function o(e) {
   try {
    null == e ? t.storage.removeItem("debug") : t.storage.debug = e;
   } catch (e) {}
  }, t.load = n, t.useColors = function a() {
   return !("undefined" == typeof window || !window.process || "renderer" !== window.process.type) || ("undefined" == typeof navigator || !navigator.userAgent || !navigator.userAgent.toLowerCase().match(/(edge|trident)\/(\d+)/)) && ("undefined" != typeof document && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance || "undefined" != typeof window && window.console && (window.console.firebug || window.console.exception && window.console.table) || "undefined" != typeof navigator && navigator.userAgent && navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/) && parseInt(RegExp.$1, 10) >= 31 || "undefined" != typeof navigator && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/));
  }, t.storage = "undefined" != typeof chrome && void 0 !== chrome.storage ? chrome.storage.local : function l() {
   try {
    return window.localStorage;
   } catch (e) {}
  }(), t.colors = [ "#0000CC", "#0000FF", "#0033CC", "#0033FF", "#0066CC", "#0066FF", "#0099CC", "#0099FF", "#00CC00", "#00CC33", "#00CC66", "#00CC99", "#00CCCC", "#00CCFF", "#3300CC", "#3300FF", "#3333CC", "#3333FF", "#3366CC", "#3366FF", "#3399CC", "#3399FF", "#33CC00", "#33CC33", "#33CC66", "#33CC99", "#33CCCC", "#33CCFF", "#6600CC", "#6600FF", "#6633CC", "#6633FF", "#66CC00", "#66CC33", "#9900CC", "#9900FF", "#9933CC", "#9933FF", "#99CC00", "#99CC33", "#CC0000", "#CC0033", "#CC0066", "#CC0099", "#CC00CC", "#CC00FF", "#CC3300", "#CC3333", "#CC3366", "#CC3399", "#CC33CC", "#CC33FF", "#CC6600", "#CC6633", "#CC9900", "#CC9933", "#CCCC00", "#CCCC33", "#FF0000", "#FF0033", "#FF0066", "#FF0099", "#FF00CC", "#FF00FF", "#FF3300", "#FF3333", "#FF3366", "#FF3399", "#FF33CC", "#FF33FF", "#FF6600", "#FF6633", "#FF9900", "#FF9933", "#FFCC00", "#FFCC33" ], 
  t.formatters.j = function(e) {
   try {
    return JSON.stringify(e);
   } catch (e) {
    return "[UnexpectedJSONParseError]: " + e.message;
   }
  }, t.enable(n());
 }, function(e, t, r) {
  "undefined" == typeof process || "renderer" === process.type ? e.exports = r(211) : e.exports = r(213);
 }, function(e, t, r) {
  function n() {
   return process.env.DEBUG;
  }
  var i, s = r(79), o = r(2);
  (t = e.exports = r(112)).init = function a(e) {
   var r, n;
   for (e.inspectOpts = {}, r = Object.keys(t.inspectOpts), n = 0; n < r.length; n++) e.inspectOpts[r[n]] = t.inspectOpts[r[n]];
  }, t.log = function l() {
   return process.stderr.write(o.format.apply(o, arguments) + "\n");
  }, t.formatArgs = function c(e) {
   var r, n, i, s = this.namespace;
   this.useColors ? (i = "  " + (n = "[3" + ((r = this.color) < 8 ? r : "8;5;" + r)) + ";1m" + s + " [0m", 
   e[0] = i + e[0].split("\n").join("\n" + i), e.push(n + "m+" + t.humanize(this.diff) + "[0m")) : e[0] = function o() {
    return t.inspectOpts.hideDate ? "" : (new Date).toISOString() + " ";
   }() + s + " " + e[0];
  }, t.save = function u(e) {
   null == e ? delete process.env.DEBUG : process.env.DEBUG = e;
  }, t.load = n, t.useColors = function f() {
   return "colors" in t.inspectOpts ? Boolean(t.inspectOpts.colors) : s.isatty(process.stderr.fd);
  }, t.colors = [ 6, 2, 3, 4, 5, 1 ];
  try {
   (i = r(239)) && i.level >= 2 && (t.colors = [ 20, 21, 26, 27, 32, 33, 38, 39, 40, 41, 42, 43, 44, 45, 56, 57, 62, 63, 68, 69, 74, 75, 76, 77, 78, 79, 80, 81, 92, 93, 98, 99, 112, 113, 128, 129, 134, 135, 148, 149, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 178, 179, 184, 185, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 214, 215, 220, 221 ]);
  } catch (e) {}
  t.inspectOpts = Object.keys(process.env).filter((function(e) {
   return /^debug_/i.test(e);
  })).reduce((function(e, t) {
   var r = t.substring(6).toLowerCase().replace(/_([a-z])/g, (function(e, t) {
    return t.toUpperCase();
   })), n = process.env[t];
   return n = !!/^(yes|on|true|enabled)$/i.test(n) || !/^(no|off|false|disabled)$/i.test(n) && ("null" === n ? null : Number(n)), 
   e[r] = n, e;
  }), {}), t.formatters.o = function(e) {
   return this.inspectOpts.colors = this.useColors, o.inspect(e, this.inspectOpts).split("\n").map((function(e) {
    return e.trim();
   })).join(" ");
  }, t.formatters.O = function(e) {
   return this.inspectOpts.colors = this.useColors, o.inspect(e, this.inspectOpts);
  }, t.enable(n());
 }, , , , function(e, t, r) {
  var n, i, s = r(0), o = "win32" === process.platform, a = r(3), l = process.env.NODE_DEBUG && /fs/.test(process.env.NODE_DEBUG);
  n = o ? /(.*?)(?:[\/\\]+|$)/g : /(.*?)(?:[\/]+|$)/g, i = o ? /^(?:[a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/][^\\\/]+)?[\\\/]*/ : /^[\/]*/, 
  t.realpathSync = function e(t, r) {
   function l() {
    var e = i.exec(t);
    h = e[0].length, p = e[0], d = e[0], m = "", o && !f[d] && (a.lstatSync(d), f[d] = !0);
   }
   var c, u, f, h, p, d, m, g, y, v, E, b;
   if (t = s.resolve(t), r && Object.prototype.hasOwnProperty.call(r, t)) return r[t];
   for (c = t, u = {}, f = {}, l(); h < t.length; ) if (n.lastIndex = h, g = n.exec(t), 
   m = p, p += g[0], d = m + g[1], h = n.lastIndex, !(f[d] || r && r[d] === d)) {
    if (r && Object.prototype.hasOwnProperty.call(r, d)) y = r[d]; else {
     if (!(v = a.lstatSync(d)).isSymbolicLink()) {
      f[d] = !0, r && (r[d] = d);
      continue;
     }
     E = null, o || (b = v.dev.toString(32) + ":" + v.ino.toString(32), u.hasOwnProperty(b) && (E = u[b])), 
     null === E && (a.statSync(d), E = a.readlinkSync(d)), y = s.resolve(m, E), r && (r[d] = y), 
     o || (u[b] = E);
    }
    t = s.resolve(y, t.slice(h)), l();
   }
   return r && (r[c] = t), t;
  }, t.realpath = function e(t, r, c) {
   function u() {
    var e = i.exec(t);
    v = e[0].length, E = e[0], b = e[0], _ = "", o && !y[b] ? a.lstat(b, (function(e) {
     if (e) return c(e);
     y[b] = !0, f();
    })) : process.nextTick(f);
   }
   function f() {
    if (v >= t.length) return r && (r[m] = t), c(null, t);
    n.lastIndex = v;
    var e = n.exec(t);
    return _ = E, E += e[0], b = _ + e[1], v = n.lastIndex, y[b] || r && r[b] === b ? process.nextTick(f) : r && Object.prototype.hasOwnProperty.call(r, b) ? d(r[b]) : a.lstat(b, h);
   }
   function h(e, t) {
    if (e) return c(e);
    if (!t.isSymbolicLink()) return y[b] = !0, r && (r[b] = b), process.nextTick(f);
    if (!o) {
     var n = t.dev.toString(32) + ":" + t.ino.toString(32);
     if (g.hasOwnProperty(n)) return p(null, g[n], b);
    }
    a.stat(b, (function(e) {
     if (e) return c(e);
     a.readlink(b, (function(e, t) {
      o || (g[n] = t), p(e, t);
     }));
    }));
   }
   function p(e, t, n) {
    if (e) return c(e);
    var i = s.resolve(_, t);
    r && (r[n] = i), d(i);
   }
   function d(e) {
    t = s.resolve(e, t.slice(v)), u();
   }
   var m, g, y, v, E, b, _;
   if ("function" != typeof c && (c = function w(e) {
    return "function" == typeof e ? e : function t() {
     function e(e) {
      if (e) {
       if (process.throwDeprecation) throw e;
       if (!process.noDeprecation) {
        var t = "fs: missing callback " + (e.stack || e.message);
        process.traceDeprecation ? console.trace(t) : console.error(t);
       }
      }
     }
     var t, r;
     return l ? (r = new Error, t = function n(t) {
      t && (r.message = t.message, e(t = r));
     }) : t = e, t;
    }();
   }(r), r = null), t = s.resolve(t), r && Object.prototype.hasOwnProperty.call(r, t)) return process.nextTick(c.bind(null, null, r[t]));
   m = t, g = {}, y = {}, u();
  };
 }, function(e, t, r) {
  function n(e, t) {
   if ("function" == typeof t || 3 === arguments.length) throw new TypeError("callback provided to sync glob\nSee: https://github.com/isaacs/node-glob/issues/167");
   return new i(e, t).found;
  }
  function i(e, t) {
   var r, n;
   if (!e) throw new Error("must provide pattern");
   if ("function" == typeof t || 3 === arguments.length) throw new TypeError("callback provided to sync glob\nSee: https://github.com/isaacs/node-glob/issues/167");
   if (!(this instanceof i)) return new i(e, t);
   if (h(this, e, t), this.noprocess) return this;
   for (r = this.minimatch.set.length, this.matches = new Array(r), n = 0; n < r; n++) this._process(this.minimatch.set[n], n, !1);
   this._finish();
  }
  var s, o, a, l, c, u, f, h, p, d, m;
  e.exports = n, n.GlobSync = i, s = r(3), o = r(114), a = r(60), r(75).Glob, r(2), 
  l = r(0), c = r(22), u = r(76), f = r(115), h = f.setopts, p = f.ownProp, d = f.childrenIgnored, 
  m = f.isIgnored, i.prototype._finish = function() {
   if (c(this instanceof i), this.realpath) {
    var e = this;
    this.matches.forEach((function(t, r) {
     var n, i = e.matches[r] = Object.create(null);
     for (n in t) try {
      n = e._makeAbs(n), i[o.realpathSync(n, e.realpathCache)] = !0;
     } catch (t) {
      if ("stat" !== t.syscall) throw t;
      i[e._makeAbs(n)] = !0;
     }
    }));
   }
   f.finish(this);
  }, i.prototype._process = function(e, t, r) {
   var n, s, o, l, f;
   for (c(this instanceof i), n = 0; "string" == typeof e[n]; ) n++;
   switch (n) {
   case e.length:
    return void this._processSimple(e.join("/"), t);

   case 0:
    s = null;
    break;

   default:
    s = e.slice(0, n).join("/");
   }
   o = e.slice(n), null === s ? l = "." : u(s) || u(e.join("/")) ? (s && u(s) || (s = "/" + s), 
   l = s) : l = s, f = this._makeAbs(l), d(this, l) || (o[0] === a.GLOBSTAR ? this._processGlobStar(s, l, f, o, t, r) : this._processReaddir(s, l, f, o, t, r));
  }, i.prototype._processReaddir = function(e, t, r, n, i, s) {
   var o, a, c, u, f, h, p, d, m, g = this._readdir(r, s);
   if (g) {
    for (o = n[0], a = !!this.minimatch.negate, c = o._glob, u = this.dot || "." === c.charAt(0), 
    f = [], h = 0; h < g.length; h++) ("." !== (p = g[h]).charAt(0) || u) && (a && !e ? !p.match(o) : p.match(o)) && f.push(p);
    if (0 !== (d = f.length)) if (1 !== n.length || this.mark || this.stat) for (n.shift(), 
    h = 0; h < d; h++) p = f[h], m = e ? [ e, p ] : [ p ], this._process(m.concat(n), i, s); else for (this.matches[i] || (this.matches[i] = Object.create(null)), 
    h = 0; h < d; h++) p = f[h], e && (p = "/" !== e.slice(-1) ? e + "/" + p : e + p), 
    "/" !== p.charAt(0) || this.nomount || (p = l.join(this.root, p)), this._emitMatch(i, p);
   }
  }, i.prototype._emitMatch = function(e, t) {
   var r, n;
   m(this, t) || (r = this._makeAbs(t), this.mark && (t = this._mark(t)), this.absolute && (t = r), 
   this.matches[e][t] || this.nodir && ("DIR" === (n = this.cache[r]) || Array.isArray(n)) || (this.matches[e][t] = !0, 
   this.stat && this._stat(t)));
  }, i.prototype._readdirInGlobStar = function(e) {
   var t, r, n;
   if (this.follow) return this._readdir(e, !1);
   try {
    r = s.lstatSync(e);
   } catch (e) {
    if ("ENOENT" === e.code) return null;
   }
   return n = r && r.isSymbolicLink(), this.symlinks[e] = n, n || !r || r.isDirectory() ? t = this._readdir(e, !1) : this.cache[e] = "FILE", 
   t;
  }, i.prototype._readdir = function(e, t) {
   if (t && !p(this.symlinks, e)) return this._readdirInGlobStar(e);
   if (p(this.cache, e)) {
    var r = this.cache[e];
    if (!r || "FILE" === r) return null;
    if (Array.isArray(r)) return r;
   }
   try {
    return this._readdirEntries(e, s.readdirSync(e));
   } catch (t) {
    return this._readdirError(e, t), null;
   }
  }, i.prototype._readdirEntries = function(e, t) {
   var r, n;
   if (!this.mark && !this.stat) for (r = 0; r < t.length; r++) n = t[r], n = "/" === e ? e + n : e + "/" + n, 
   this.cache[n] = !0;
   return this.cache[e] = t, t;
  }, i.prototype._readdirError = function(e, t) {
   var r, n;
   switch (t.code) {
   case "ENOTSUP":
   case "ENOTDIR":
    if (r = this._makeAbs(e), this.cache[r] = "FILE", r === this.cwdAbs) throw (n = new Error(t.code + " invalid cwd " + this.cwd)).path = this.cwd, 
    n.code = t.code, n;
    break;

   case "ENOENT":
   case "ELOOP":
   case "ENAMETOOLONG":
   case "UNKNOWN":
    this.cache[this._makeAbs(e)] = !1;
    break;

   default:
    if (this.cache[this._makeAbs(e)] = !1, this.strict) throw t;
    this.silent || console.error("glob error", t);
   }
  }, i.prototype._processGlobStar = function(e, t, r, n, i, s) {
   var o, a, l, c, u, f, h, p = this._readdir(r, s);
   if (p && (o = n.slice(1), l = (a = e ? [ e ] : []).concat(o), this._process(l, i, !1), 
   c = p.length, !this.symlinks[r] || !s)) for (u = 0; u < c; u++) ("." !== p[u].charAt(0) || this.dot) && (f = a.concat(p[u], o), 
   this._process(f, i, !0), h = a.concat(p[u], n), this._process(h, i, !0));
  }, i.prototype._processSimple = function(e, t) {
   var r, n = this._stat(e);
   this.matches[t] || (this.matches[t] = Object.create(null)), n && (e && u(e) && !this.nomount && (r = /[\/\\]$/.test(e), 
   "/" === e.charAt(0) ? e = l.join(this.root, e) : (e = l.resolve(this.root, e), r && (e += "/"))), 
   "win32" === process.platform && (e = e.replace(/\\/g, "/")), this._emitMatch(t, e));
  }, i.prototype._stat = function(e) {
   var t, r, n, i = this._makeAbs(e), o = "/" === e.slice(-1);
   if (e.length > this.maxLength) return !1;
   if (!this.stat && p(this.cache, i)) {
    if (t = this.cache[i], Array.isArray(t) && (t = "DIR"), !o || "DIR" === t) return t;
    if (o && "FILE" === t) return !1;
   }
   if (!(r = this.statCache[i])) {
    try {
     n = s.lstatSync(i);
    } catch (e) {
     if (e && ("ENOENT" === e.code || "ENOTDIR" === e.code)) return this.statCache[i] = !1, 
     !1;
    }
    if (n && n.isSymbolicLink()) try {
     r = s.statSync(i);
    } catch (e) {
     r = n;
    } else r = n;
   }
   return this.statCache[i] = r, t = !0, r && (t = r.isDirectory() ? "DIR" : "FILE"), 
   this.cache[i] = this.cache[i] || t, (!o || "FILE" !== t) && t;
  }, i.prototype._mark = function(e) {
   return f.mark(this, e);
  }, i.prototype._makeAbs = function(e) {
   return f.makeAbs(this, e);
  };
 }, , , function(e, t, r) {
  e.exports = function(e, t) {
   var r, n, i;
   return r = (t = t || process.argv).indexOf("--"), n = /^--/.test(e) ? "" : "--", 
   -1 !== (i = t.indexOf(n + e)) && (-1 === r || i < r);
  };
 }, , function(e, t, r) {
  function n(e) {
   var t, r = e.length, n = [];
   for (t = 0; t < r; t++) n[t] = e[t];
   return n;
  }
  var i = r(123), s = Object.create(null), o = r(61);
  e.exports = i((function a(e, t) {
   return s[e] ? (s[e].push(t), null) : (s[e] = [ t ], function r(e) {
    return o((function t() {
     var r, i = s[e], o = i.length, a = n(arguments);
     try {
      for (r = 0; r < o; r++) i[r].apply(null, a);
     } finally {
      i.length > o ? (i.splice(0, o), process.nextTick((function() {
       t.apply(null, a);
      }))) : delete s[e];
     }
    }));
   }(e));
  }));
 }, function(e, t) {
  "function" == typeof Object.create ? e.exports = function e(t, r) {
   t.super_ = r, t.prototype = Object.create(r.prototype, {
    constructor: {
     value: t,
     enumerable: !1,
     writable: !0,
     configurable: !0
    }
   });
  } : e.exports = function e(t, r) {
   t.super_ = r;
   var n = function() {};
   n.prototype = r.prototype, t.prototype = new n, t.prototype.constructor = t;
  };
 }, , , function(e, t, r) {
  e.exports = void 0 !== r;
 }, , function(e, t) {
  function r(e, t, r) {
   if (!(e < t)) return e < 1.5 * t ? Math.floor(e / t) + " " + r : Math.ceil(e / t) + " " + r + "s";
  }
  var n = 1e3, i = 60 * n, s = 60 * i, o = 24 * s;
  e.exports = function(e, t) {
   t = t || {};
   var a = typeof e;
   if ("string" === a && e.length > 0) return function l(e) {
    var t, r;
    if (!((e = String(e)).length > 100) && (t = /^((?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|years?|yrs?|y)?$/i.exec(e))) switch (r = parseFloat(t[1]), 
    (t[2] || "ms").toLowerCase()) {
    case "years":
    case "year":
    case "yrs":
    case "yr":
    case "y":
     return 315576e5 * r;

    case "days":
    case "day":
    case "d":
     return r * o;

    case "hours":
    case "hour":
    case "hrs":
    case "hr":
    case "h":
     return r * s;

    case "minutes":
    case "minute":
    case "mins":
    case "min":
    case "m":
     return r * i;

    case "seconds":
    case "second":
    case "secs":
    case "sec":
    case "s":
     return r * n;

    case "milliseconds":
    case "millisecond":
    case "msecs":
    case "msec":
    case "ms":
     return r;

    default:
     return;
    }
   }(e);
   if ("number" === a && !1 === isNaN(e)) return t.long ? function c(e) {
    return r(e, o, "day") || r(e, s, "hour") || r(e, i, "minute") || r(e, n, "second") || e + " ms";
   }(e) : function u(e) {
    return e >= o ? Math.round(e / o) + "d" : e >= s ? Math.round(e / s) + "h" : e >= i ? Math.round(e / i) + "m" : e >= n ? Math.round(e / n) + "s" : e + "ms";
   }(e);
   throw new Error("val is not a non-empty string or a valid number. val=" + JSON.stringify(e));
  };
 }, , , , function(e, t, r) {
  function n(e) {
   [ "unlink", "chmod", "stat", "lstat", "rmdir", "readdir" ].forEach((function(t) {
    e[t] = e[t] || p[t], e[t += "Sync"] = e[t] || p[t];
   })), e.maxBusyTries = e.maxBusyTries || 3, e.emfileWait = e.emfileWait || 1e3, !1 === e.glob && (e.disableGlob = !0), 
   e.disableGlob = e.disableGlob || !1, e.glob = e.glob || g;
  }
  function i(e, t, r) {
   function i(e, n) {
    return e ? r(e) : 0 === (l = n.length) ? r() : void n.forEach((function(e) {
     s(e, t, (function n(i) {
      if (i) {
       if (("EBUSY" === i.code || "ENOTEMPTY" === i.code || "EPERM" === i.code) && o < t.maxBusyTries) return o++, 
       setTimeout((function() {
        s(e, t, n);
       }), 100 * o);
       if ("EMFILE" === i.code && y < t.emfileWait) return setTimeout((function() {
        s(e, t, n);
       }), y++);
       "ENOENT" === i.code && (i = null);
      }
      y = 0, function c(e) {
       a = a || e, 0 == --l && r(a);
      }(i);
     }));
    }));
   }
   var o, a, l;
   if ("function" == typeof t && (r = t, t = {}), f(e, "rimraf: missing path"), f.equal(typeof e, "string", "rimraf: path should be a string"), 
   f.equal(typeof r, "function", "rimraf: callback function required"), f(t, "rimraf: invalid options argument provided"), 
   f.equal(typeof t, "object", "rimraf: options should be object"), n(t), o = 0, a = null, 
   l = 0, t.disableGlob || !d.hasMagic(e)) return i(null, [ e ]);
   t.lstat(e, (function(r, n) {
    if (!r) return i(null, [ e ]);
    d(e, t.glob, i);
   }));
  }
  function s(e, t, r) {
   f(e), f(t), f("function" == typeof r), t.lstat(e, (function(n, i) {
    return n && "ENOENT" === n.code ? r(null) : (n && "EPERM" === n.code && v && o(e, t, n, r), 
    i && i.isDirectory() ? l(e, t, n, r) : void t.unlink(e, (function(n) {
     if (n) {
      if ("ENOENT" === n.code) return r(null);
      if ("EPERM" === n.code) return v ? o(e, t, n, r) : l(e, t, n, r);
      if ("EISDIR" === n.code) return l(e, t, n, r);
     }
     return r(n);
    })));
   }));
  }
  function o(e, t, r, n) {
   f(e), f(t), f("function" == typeof n), r && f(r instanceof Error), t.chmod(e, m, (function(i) {
    i ? n("ENOENT" === i.code ? null : r) : t.stat(e, (function(i, s) {
     i ? n("ENOENT" === i.code ? null : r) : s.isDirectory() ? l(e, t, r, n) : t.unlink(e, n);
    }));
   }));
  }
  function a(e, t, r) {
   f(e), f(t), r && f(r instanceof Error);
   try {
    t.chmodSync(e, m);
   } catch (e) {
    if ("ENOENT" === e.code) return;
    throw r;
   }
   try {
    var n = t.statSync(e);
   } catch (e) {
    if ("ENOENT" === e.code) return;
    throw r;
   }
   n.isDirectory() ? u(e, t, r) : t.unlinkSync(e);
  }
  function l(e, t, r, n) {
   f(e), f(t), r && f(r instanceof Error), f("function" == typeof n), t.rmdir(e, (function(s) {
    !s || "ENOTEMPTY" !== s.code && "EEXIST" !== s.code && "EPERM" !== s.code ? s && "ENOTDIR" === s.code ? n(r) : n(s) : function o(e, t, r) {
     f(e), f(t), f("function" == typeof r), t.readdir(e, (function(n, s) {
      var o, a;
      return n ? r(n) : 0 === (o = s.length) ? t.rmdir(e, r) : void s.forEach((function(n) {
       i(h.join(e, n), t, (function(n) {
        if (!a) return n ? r(a = n) : void (0 == --o && t.rmdir(e, r));
       }));
      }));
     }));
    }(e, t, n);
   }));
  }
  function c(e, t) {
   var r, i, s;
   if (n(t = t || {}), f(e, "rimraf: missing path"), f.equal(typeof e, "string", "rimraf: path should be a string"), 
   f(t, "rimraf: missing options"), f.equal(typeof t, "object", "rimraf: options should be object"), 
   t.disableGlob || !d.hasMagic(e)) r = [ e ]; else try {
    t.lstatSync(e), r = [ e ];
   } catch (n) {
    r = d.sync(e, t.glob);
   }
   if (r.length) for (i = 0; i < r.length; i++) {
    e = r[i];
    try {
     s = t.lstatSync(e);
    } catch (r) {
     if ("ENOENT" === r.code) return;
     "EPERM" === r.code && v && a(e, t, r);
    }
    try {
     s && s.isDirectory() ? u(e, t, null) : t.unlinkSync(e);
    } catch (r) {
     if ("ENOENT" === r.code) return;
     if ("EPERM" === r.code) return v ? a(e, t, r) : u(e, t, r);
     if ("EISDIR" !== r.code) throw r;
     u(e, t, r);
    }
   }
  }
  function u(e, t, r) {
   f(e), f(t), r && f(r instanceof Error);
   try {
    t.rmdirSync(e);
   } catch (n) {
    if ("ENOENT" === n.code) return;
    if ("ENOTDIR" === n.code) throw r;
    "ENOTEMPTY" !== n.code && "EEXIST" !== n.code && "EPERM" !== n.code || function n(e, t) {
     var r, n, i, s;
     for (f(e), f(t), t.readdirSync(e).forEach((function(r) {
      c(h.join(e, r), t);
     })), r = v ? 100 : 1, n = 0; ;) {
      i = !0;
      try {
       return s = t.rmdirSync(e, t), i = !1, s;
      } finally {
       if (++n < r && i) continue;
      }
     }
    }(e, t);
   }
  }
  var f, h, p, d, m, g, y, v;
  e.exports = i, i.sync = c, f = r(22), h = r(0), p = r(3), d = r(75), m = parseInt("666", 8), 
  g = {
   nosort: !0,
   silent: !0
  }, y = 0, v = "win32" === process.platform;
 }, , , , , , function(e, t, r) {
  var n, i = r(221), s = i("no-color") || i("no-colors") || i("color=false") ? 0 : i("color=16m") || i("color=full") || i("color=truecolor") ? 3 : i("color=256") ? 2 : i("color") || i("colors") || i("color=true") || i("color=always") ? 1 : process.stdout && !process.stdout.isTTY ? 0 : "win32" === process.platform ? 1 : "CI" in process.env ? "TRAVIS" in process.env || "Travis" === process.env.CI ? 1 : 0 : "TEAMCITY_VERSION" in process.env ? null === process.env.TEAMCITY_VERSION.match(/^(9\.(0*[1-9]\d*)\.|\d{2,}\.)/) ? 0 : 1 : /^(screen|xterm)-256(?:color)?/.test(process.env.TERM) ? 2 : /^screen|^xterm|^vt100|color|ansi|cygwin|linux/i.test(process.env.TERM) || "COLORTERM" in process.env ? 1 : (process.env.TERM, 
  0);
  0 === s && "FORCE_COLOR" in process.env && (s = 1), e.exports = process && (0 !== (n = s) && {
   level: n,
   hasBasic: !0,
   has256: n >= 2,
   has16m: n >= 3
  });
 } ]);
})), exit = function e(t, r) {
 function n() {
  i === r.length && process.exit(t);
 }
 r || (r = [ process.stdout, process.stderr ]);
 var i = 0;
 r.forEach((function(e) {
  0 === e.bufferSize ? i++ : e.write("", "utf-8", (function() {
   i++, n();
  })), e.write = function() {};
 })), n(), process.on("exit", (function() {
  process.exit(t);
 }));
};

const copyFile = require$$1.promisify(fs__default.default.copyFile), mkdir = require$$1.promisify(fs__default.default.mkdir), readdir = require$$1.promisify(fs__default.default.readdir);

require$$1.promisify(fs__default.default.readFile);

const stat = require$$1.promisify(fs__default.default.stat), ROOT_DIR = normalizePath(path__default.default.resolve("/")), IGNORE = [ ".ds_store", ".gitignore", "desktop.ini", "thumbs.db" ], debug = "object" == typeof process && process.env && process.env.NODE_DEBUG && /\bsemver\b/i.test(process.env.NODE_DEBUG) ? (...e) => console.error("SEMVER", ...e) : () => {};

debug_1 = debug;

const MAX_SAFE_INTEGER$1 = Number.MAX_SAFE_INTEGER || 9007199254740991;

constants = {
 SEMVER_SPEC_VERSION: "2.0.0",
 MAX_LENGTH: 256,
 MAX_SAFE_INTEGER: MAX_SAFE_INTEGER$1,
 MAX_SAFE_COMPONENT_LENGTH: 16
}, re_1 = createCommonjsModule((function(e, t) {
 const {MAX_SAFE_COMPONENT_LENGTH: r} = constants, n = (t = e.exports = {}).re = [], i = t.src = [], s = t.t = {};
 let o = 0;
 const a = (e, t, r) => {
  const a = o++;
  debug_1(e, a, t), s[e] = a, i[a] = t, n[a] = new RegExp(t, r ? "g" : void 0);
 };
 a("NUMERICIDENTIFIER", "0|[1-9]\\d*"), a("NUMERICIDENTIFIERLOOSE", "[0-9]+"), a("NONNUMERICIDENTIFIER", "\\d*[a-zA-Z-][a-zA-Z0-9-]*"), 
 a("MAINVERSION", `(${i[s.NUMERICIDENTIFIER]})\\.(${i[s.NUMERICIDENTIFIER]})\\.(${i[s.NUMERICIDENTIFIER]})`), 
 a("MAINVERSIONLOOSE", `(${i[s.NUMERICIDENTIFIERLOOSE]})\\.(${i[s.NUMERICIDENTIFIERLOOSE]})\\.(${i[s.NUMERICIDENTIFIERLOOSE]})`), 
 a("PRERELEASEIDENTIFIER", `(?:${i[s.NUMERICIDENTIFIER]}|${i[s.NONNUMERICIDENTIFIER]})`), 
 a("PRERELEASEIDENTIFIERLOOSE", `(?:${i[s.NUMERICIDENTIFIERLOOSE]}|${i[s.NONNUMERICIDENTIFIER]})`), 
 a("PRERELEASE", `(?:-(${i[s.PRERELEASEIDENTIFIER]}(?:\\.${i[s.PRERELEASEIDENTIFIER]})*))`), 
 a("PRERELEASELOOSE", `(?:-?(${i[s.PRERELEASEIDENTIFIERLOOSE]}(?:\\.${i[s.PRERELEASEIDENTIFIERLOOSE]})*))`), 
 a("BUILDIDENTIFIER", "[0-9A-Za-z-]+"), a("BUILD", `(?:\\+(${i[s.BUILDIDENTIFIER]}(?:\\.${i[s.BUILDIDENTIFIER]})*))`), 
 a("FULLPLAIN", `v?${i[s.MAINVERSION]}${i[s.PRERELEASE]}?${i[s.BUILD]}?`), a("FULL", `^${i[s.FULLPLAIN]}$`), 
 a("LOOSEPLAIN", `[v=\\s]*${i[s.MAINVERSIONLOOSE]}${i[s.PRERELEASELOOSE]}?${i[s.BUILD]}?`), 
 a("LOOSE", `^${i[s.LOOSEPLAIN]}$`), a("GTLT", "((?:<|>)?=?)"), a("XRANGEIDENTIFIERLOOSE", `${i[s.NUMERICIDENTIFIERLOOSE]}|x|X|\\*`), 
 a("XRANGEIDENTIFIER", `${i[s.NUMERICIDENTIFIER]}|x|X|\\*`), a("XRANGEPLAIN", `[v=\\s]*(${i[s.XRANGEIDENTIFIER]})(?:\\.(${i[s.XRANGEIDENTIFIER]})(?:\\.(${i[s.XRANGEIDENTIFIER]})(?:${i[s.PRERELEASE]})?${i[s.BUILD]}?)?)?`), 
 a("XRANGEPLAINLOOSE", `[v=\\s]*(${i[s.XRANGEIDENTIFIERLOOSE]})(?:\\.(${i[s.XRANGEIDENTIFIERLOOSE]})(?:\\.(${i[s.XRANGEIDENTIFIERLOOSE]})(?:${i[s.PRERELEASELOOSE]})?${i[s.BUILD]}?)?)?`), 
 a("XRANGE", `^${i[s.GTLT]}\\s*${i[s.XRANGEPLAIN]}$`), a("XRANGELOOSE", `^${i[s.GTLT]}\\s*${i[s.XRANGEPLAINLOOSE]}$`), 
 a("COERCE", `(^|[^\\d])(\\d{1,${r}})(?:\\.(\\d{1,${r}}))?(?:\\.(\\d{1,${r}}))?(?:$|[^\\d])`), 
 a("COERCERTL", i[s.COERCE], !0), a("LONETILDE", "(?:~>?)"), a("TILDETRIM", `(\\s*)${i[s.LONETILDE]}\\s+`, !0), 
 t.tildeTrimReplace = "$1~", a("TILDE", `^${i[s.LONETILDE]}${i[s.XRANGEPLAIN]}$`), 
 a("TILDELOOSE", `^${i[s.LONETILDE]}${i[s.XRANGEPLAINLOOSE]}$`), a("LONECARET", "(?:\\^)"), 
 a("CARETTRIM", `(\\s*)${i[s.LONECARET]}\\s+`, !0), t.caretTrimReplace = "$1^", a("CARET", `^${i[s.LONECARET]}${i[s.XRANGEPLAIN]}$`), 
 a("CARETLOOSE", `^${i[s.LONECARET]}${i[s.XRANGEPLAINLOOSE]}$`), a("COMPARATORLOOSE", `^${i[s.GTLT]}\\s*(${i[s.LOOSEPLAIN]})$|^$`), 
 a("COMPARATOR", `^${i[s.GTLT]}\\s*(${i[s.FULLPLAIN]})$|^$`), a("COMPARATORTRIM", `(\\s*)${i[s.GTLT]}\\s*(${i[s.LOOSEPLAIN]}|${i[s.XRANGEPLAIN]})`, !0), 
 t.comparatorTrimReplace = "$1$2$3", a("HYPHENRANGE", `^\\s*(${i[s.XRANGEPLAIN]})\\s+-\\s+(${i[s.XRANGEPLAIN]})\\s*$`), 
 a("HYPHENRANGELOOSE", `^\\s*(${i[s.XRANGEPLAINLOOSE]})\\s+-\\s+(${i[s.XRANGEPLAINLOOSE]})\\s*$`), 
 a("STAR", "(<|>)?=?\\s*\\*"), a("GTE0", "^\\s*>=\\s*0\\.0\\.0\\s*$"), a("GTE0PRE", "^\\s*>=\\s*0\\.0\\.0-0\\s*$");
}));

const opts = [ "includePrerelease", "loose", "rtl" ];

parseOptions_1 = e => e ? "object" != typeof e ? {
 loose: !0
} : opts.filter((t => e[t])).reduce(((e, t) => (e[t] = !0, e)), {}) : {};

const numeric = /^[0-9]+$/, compareIdentifiers$1 = (e, t) => {
 const r = numeric.test(e), n = numeric.test(t);
 return r && n && (e = +e, t = +t), e === t ? 0 : r && !n ? -1 : n && !r ? 1 : e < t ? -1 : 1;
};

identifiers = {
 compareIdentifiers: compareIdentifiers$1,
 rcompareIdentifiers: (e, t) => compareIdentifiers$1(t, e)
};

const {MAX_LENGTH, MAX_SAFE_INTEGER} = constants, {re: re$2, t: t$2} = re_1, {compareIdentifiers} = identifiers;

class SemVer {
 constructor(e, t) {
  if (t = parseOptions_1(t), e instanceof SemVer) {
   if (e.loose === !!t.loose && e.includePrerelease === !!t.includePrerelease) return e;
   e = e.version;
  } else if ("string" != typeof e) throw new TypeError(`Invalid Version: ${e}`);
  if (e.length > MAX_LENGTH) throw new TypeError(`version is longer than ${MAX_LENGTH} characters`);
  debug_1("SemVer", e, t), this.options = t, this.loose = !!t.loose, this.includePrerelease = !!t.includePrerelease;
  const r = e.trim().match(t.loose ? re$2[t$2.LOOSE] : re$2[t$2.FULL]);
  if (!r) throw new TypeError(`Invalid Version: ${e}`);
  if (this.raw = e, this.major = +r[1], this.minor = +r[2], this.patch = +r[3], this.major > MAX_SAFE_INTEGER || this.major < 0) throw new TypeError("Invalid major version");
  if (this.minor > MAX_SAFE_INTEGER || this.minor < 0) throw new TypeError("Invalid minor version");
  if (this.patch > MAX_SAFE_INTEGER || this.patch < 0) throw new TypeError("Invalid patch version");
  r[4] ? this.prerelease = r[4].split(".").map((e => {
   if (/^[0-9]+$/.test(e)) {
    const t = +e;
    if (t >= 0 && t < MAX_SAFE_INTEGER) return t;
   }
   return e;
  })) : this.prerelease = [], this.build = r[5] ? r[5].split(".") : [], this.format();
 }
 format() {
  return this.version = `${this.major}.${this.minor}.${this.patch}`, this.prerelease.length && (this.version += `-${this.prerelease.join(".")}`), 
  this.version;
 }
 toString() {
  return this.version;
 }
 compare(e) {
  if (debug_1("SemVer.compare", this.version, this.options, e), !(e instanceof SemVer)) {
   if ("string" == typeof e && e === this.version) return 0;
   e = new SemVer(e, this.options);
  }
  return e.version === this.version ? 0 : this.compareMain(e) || this.comparePre(e);
 }
 compareMain(e) {
  return e instanceof SemVer || (e = new SemVer(e, this.options)), compareIdentifiers(this.major, e.major) || compareIdentifiers(this.minor, e.minor) || compareIdentifiers(this.patch, e.patch);
 }
 comparePre(e) {
  if (e instanceof SemVer || (e = new SemVer(e, this.options)), this.prerelease.length && !e.prerelease.length) return -1;
  if (!this.prerelease.length && e.prerelease.length) return 1;
  if (!this.prerelease.length && !e.prerelease.length) return 0;
  let t = 0;
  do {
   const r = this.prerelease[t], n = e.prerelease[t];
   if (debug_1("prerelease compare", t, r, n), void 0 === r && void 0 === n) return 0;
   if (void 0 === n) return 1;
   if (void 0 === r) return -1;
   if (r !== n) return compareIdentifiers(r, n);
  } while (++t);
 }
 compareBuild(e) {
  e instanceof SemVer || (e = new SemVer(e, this.options));
  let t = 0;
  do {
   const r = this.build[t], n = e.build[t];
   if (debug_1("prerelease compare", t, r, n), void 0 === r && void 0 === n) return 0;
   if (void 0 === n) return 1;
   if (void 0 === r) return -1;
   if (r !== n) return compareIdentifiers(r, n);
  } while (++t);
 }
 inc(e, t) {
  switch (e) {
  case "premajor":
   this.prerelease.length = 0, this.patch = 0, this.minor = 0, this.major++, this.inc("pre", t);
   break;

  case "preminor":
   this.prerelease.length = 0, this.patch = 0, this.minor++, this.inc("pre", t);
   break;

  case "prepatch":
   this.prerelease.length = 0, this.inc("patch", t), this.inc("pre", t);
   break;

  case "prerelease":
   0 === this.prerelease.length && this.inc("patch", t), this.inc("pre", t);
   break;

  case "major":
   0 === this.minor && 0 === this.patch && 0 !== this.prerelease.length || this.major++, 
   this.minor = 0, this.patch = 0, this.prerelease = [];
   break;

  case "minor":
   0 === this.patch && 0 !== this.prerelease.length || this.minor++, this.patch = 0, 
   this.prerelease = [];
   break;

  case "patch":
   0 === this.prerelease.length && this.patch++, this.prerelease = [];
   break;

  case "pre":
   if (0 === this.prerelease.length) this.prerelease = [ 0 ]; else {
    let e = this.prerelease.length;
    for (;--e >= 0; ) "number" == typeof this.prerelease[e] && (this.prerelease[e]++, 
    e = -2);
    -1 === e && this.prerelease.push(0);
   }
   t && (0 === compareIdentifiers(this.prerelease[0], t) ? isNaN(this.prerelease[1]) && (this.prerelease = [ t, 0 ]) : this.prerelease = [ t, 0 ]);
   break;

  default:
   throw new Error(`invalid increment argument: ${e}`);
  }
  return this.format(), this.raw = this.version, this;
 }
}

semver = SemVer, compare_1 = (e, t, r) => new semver(e, r).compare(new semver(t, r)), 
lte_1 = (e, t, r) => compare_1(e, t, r) <= 0, major_1 = (e, t) => new semver(e, t).major, 
iterator = function(e) {
 e.prototype[Symbol.iterator] = function*() {
  for (let e = this.head; e; e = e.next) yield e.value;
 };
}, yallist = Yallist, Yallist.Node = Node, Yallist.create = Yallist, Yallist.prototype.removeNode = function(e) {
 var t, r;
 if (e.list !== this) throw new Error("removing node which does not belong to this list");
 return t = e.next, r = e.prev, t && (t.prev = r), r && (r.next = t), e === this.head && (this.head = t), 
 e === this.tail && (this.tail = r), e.list.length--, e.next = null, e.prev = null, 
 e.list = null, t;
}, Yallist.prototype.unshiftNode = function(e) {
 if (e !== this.head) {
  e.list && e.list.removeNode(e);
  var t = this.head;
  e.list = this, e.next = t, t && (t.prev = e), this.head = e, this.tail || (this.tail = e), 
  this.length++;
 }
}, Yallist.prototype.pushNode = function(e) {
 if (e !== this.tail) {
  e.list && e.list.removeNode(e);
  var t = this.tail;
  e.list = this, e.prev = t, t && (t.next = e), this.tail = e, this.head || (this.head = e), 
  this.length++;
 }
}, Yallist.prototype.push = function() {
 for (var e = 0, t = arguments.length; e < t; e++) push(this, arguments[e]);
 return this.length;
}, Yallist.prototype.unshift = function() {
 for (var e = 0, t = arguments.length; e < t; e++) unshift(this, arguments[e]);
 return this.length;
}, Yallist.prototype.pop = function() {
 if (this.tail) {
  var e = this.tail.value;
  return this.tail = this.tail.prev, this.tail ? this.tail.next = null : this.head = null, 
  this.length--, e;
 }
}, Yallist.prototype.shift = function() {
 if (this.head) {
  var e = this.head.value;
  return this.head = this.head.next, this.head ? this.head.prev = null : this.tail = null, 
  this.length--, e;
 }
}, Yallist.prototype.forEach = function(e, t) {
 t = t || this;
 for (var r = this.head, n = 0; null !== r; n++) e.call(t, r.value, n, this), r = r.next;
}, Yallist.prototype.forEachReverse = function(e, t) {
 t = t || this;
 for (var r = this.tail, n = this.length - 1; null !== r; n--) e.call(t, r.value, n, this), 
 r = r.prev;
}, Yallist.prototype.get = function(e) {
 for (var t = 0, r = this.head; null !== r && t < e; t++) r = r.next;
 if (t === e && null !== r) return r.value;
}, Yallist.prototype.getReverse = function(e) {
 for (var t = 0, r = this.tail; null !== r && t < e; t++) r = r.prev;
 if (t === e && null !== r) return r.value;
}, Yallist.prototype.map = function(e, t) {
 var r, n;
 for (t = t || this, r = new Yallist, n = this.head; null !== n; ) r.push(e.call(t, n.value, this)), 
 n = n.next;
 return r;
}, Yallist.prototype.mapReverse = function(e, t) {
 var r, n;
 for (t = t || this, r = new Yallist, n = this.tail; null !== n; ) r.push(e.call(t, n.value, this)), 
 n = n.prev;
 return r;
}, Yallist.prototype.reduce = function(e, t) {
 var r, n, i = this.head;
 if (arguments.length > 1) r = t; else {
  if (!this.head) throw new TypeError("Reduce of empty list with no initial value");
  i = this.head.next, r = this.head.value;
 }
 for (n = 0; null !== i; n++) r = e(r, i.value, n), i = i.next;
 return r;
}, Yallist.prototype.reduceReverse = function(e, t) {
 var r, n, i = this.tail;
 if (arguments.length > 1) r = t; else {
  if (!this.tail) throw new TypeError("Reduce of empty list with no initial value");
  i = this.tail.prev, r = this.tail.value;
 }
 for (n = this.length - 1; null !== i; n--) r = e(r, i.value, n), i = i.prev;
 return r;
}, Yallist.prototype.toArray = function() {
 var e, t, r = new Array(this.length);
 for (e = 0, t = this.head; null !== t; e++) r[e] = t.value, t = t.next;
 return r;
}, Yallist.prototype.toArrayReverse = function() {
 var e, t, r = new Array(this.length);
 for (e = 0, t = this.tail; null !== t; e++) r[e] = t.value, t = t.prev;
 return r;
}, Yallist.prototype.slice = function(e, t) {
 var r, n, i;
 if ((t = t || this.length) < 0 && (t += this.length), (e = e || 0) < 0 && (e += this.length), 
 r = new Yallist, t < e || t < 0) return r;
 for (e < 0 && (e = 0), t > this.length && (t = this.length), n = 0, i = this.head; null !== i && n < e; n++) i = i.next;
 for (;null !== i && n < t; n++, i = i.next) r.push(i.value);
 return r;
}, Yallist.prototype.sliceReverse = function(e, t) {
 var r, n, i;
 if ((t = t || this.length) < 0 && (t += this.length), (e = e || 0) < 0 && (e += this.length), 
 r = new Yallist, t < e || t < 0) return r;
 for (e < 0 && (e = 0), t > this.length && (t = this.length), n = this.length, i = this.tail; null !== i && n > t; n--) i = i.prev;
 for (;null !== i && n > e; n--, i = i.prev) r.push(i.value);
 return r;
}, Yallist.prototype.splice = function(e, t, ...r) {
 var n, i, s;
 for (e > this.length && (e = this.length - 1), e < 0 && (e = this.length + e), n = 0, 
 i = this.head; null !== i && n < e; n++) i = i.next;
 for (s = [], n = 0; i && n < t; n++) s.push(i.value), i = this.removeNode(i);
 for (null === i && (i = this.tail), i !== this.head && i !== this.tail && (i = i.prev), 
 n = 0; n < r.length; n++) i = insert(this, i, r[n]);
 return s;
}, Yallist.prototype.reverse = function() {
 var e, t, r = this.head, n = this.tail;
 for (e = r; null !== e; e = e.prev) t = e.prev, e.prev = e.next, e.next = t;
 return this.head = n, this.tail = r, this;
};

try {
 iterator(Yallist);
} catch (e) {}

const MAX = Symbol("max"), LENGTH = Symbol("length"), LENGTH_CALCULATOR = Symbol("lengthCalculator"), ALLOW_STALE = Symbol("allowStale"), MAX_AGE = Symbol("maxAge"), DISPOSE = Symbol("dispose"), NO_DISPOSE_ON_SET = Symbol("noDisposeOnSet"), LRU_LIST = Symbol("lruList"), CACHE = Symbol("cache"), UPDATE_AGE_ON_GET = Symbol("updateAgeOnGet"), naiveLength = () => 1, get = (e, t, r) => {
 const n = e[CACHE].get(t);
 if (n) {
  const t = n.value;
  if (isStale(e, t)) {
   if (del(e, n), !e[ALLOW_STALE]) return;
  } else r && (e[UPDATE_AGE_ON_GET] && (n.value.now = Date.now()), e[LRU_LIST].unshiftNode(n));
  return t.value;
 }
}, isStale = (e, t) => {
 if (!t || !t.maxAge && !e[MAX_AGE]) return !1;
 const r = Date.now() - t.now;
 return t.maxAge ? r > t.maxAge : e[MAX_AGE] && r > e[MAX_AGE];
}, trim = e => {
 if (e[LENGTH] > e[MAX]) for (let t = e[LRU_LIST].tail; e[LENGTH] > e[MAX] && null !== t; ) {
  const r = t.prev;
  del(e, t), t = r;
 }
}, del = (e, t) => {
 if (t) {
  const r = t.value;
  e[DISPOSE] && e[DISPOSE](r.key, r.value), e[LENGTH] -= r.length, e[CACHE].delete(r.key), 
  e[LRU_LIST].removeNode(t);
 }
};

class Entry {
 constructor(e, t, r, n, i) {
  this.key = e, this.value = t, this.length = r, this.now = n, this.maxAge = i || 0;
 }
}

const forEachStep = (e, t, r, n) => {
 let i = r.value;
 isStale(e, i) && (del(e, r), e[ALLOW_STALE] || (i = void 0)), i && t.call(n, i.value, i.key, e);
};

lruCache = class LRUCache {
 constructor(e) {
  if ("number" == typeof e && (e = {
   max: e
  }), e || (e = {}), e.max && ("number" != typeof e.max || e.max < 0)) throw new TypeError("max must be a non-negative number");
  this[MAX] = e.max || 1 / 0;
  const t = e.length || naiveLength;
  if (this[LENGTH_CALCULATOR] = "function" != typeof t ? naiveLength : t, this[ALLOW_STALE] = e.stale || !1, 
  e.maxAge && "number" != typeof e.maxAge) throw new TypeError("maxAge must be a number");
  this[MAX_AGE] = e.maxAge || 0, this[DISPOSE] = e.dispose, this[NO_DISPOSE_ON_SET] = e.noDisposeOnSet || !1, 
  this[UPDATE_AGE_ON_GET] = e.updateAgeOnGet || !1, this.reset();
 }
 set max(e) {
  if ("number" != typeof e || e < 0) throw new TypeError("max must be a non-negative number");
  this[MAX] = e || 1 / 0, trim(this);
 }
 get max() {
  return this[MAX];
 }
 set allowStale(e) {
  this[ALLOW_STALE] = !!e;
 }
 get allowStale() {
  return this[ALLOW_STALE];
 }
 set maxAge(e) {
  if ("number" != typeof e) throw new TypeError("maxAge must be a non-negative number");
  this[MAX_AGE] = e, trim(this);
 }
 get maxAge() {
  return this[MAX_AGE];
 }
 set lengthCalculator(e) {
  "function" != typeof e && (e = naiveLength), e !== this[LENGTH_CALCULATOR] && (this[LENGTH_CALCULATOR] = e, 
  this[LENGTH] = 0, this[LRU_LIST].forEach((e => {
   e.length = this[LENGTH_CALCULATOR](e.value, e.key), this[LENGTH] += e.length;
  }))), trim(this);
 }
 get lengthCalculator() {
  return this[LENGTH_CALCULATOR];
 }
 get length() {
  return this[LENGTH];
 }
 get itemCount() {
  return this[LRU_LIST].length;
 }
 rforEach(e, t) {
  t = t || this;
  for (let r = this[LRU_LIST].tail; null !== r; ) {
   const n = r.prev;
   forEachStep(this, e, r, t), r = n;
  }
 }
 forEach(e, t) {
  t = t || this;
  for (let r = this[LRU_LIST].head; null !== r; ) {
   const n = r.next;
   forEachStep(this, e, r, t), r = n;
  }
 }
 keys() {
  return this[LRU_LIST].toArray().map((e => e.key));
 }
 values() {
  return this[LRU_LIST].toArray().map((e => e.value));
 }
 reset() {
  this[DISPOSE] && this[LRU_LIST] && this[LRU_LIST].length && this[LRU_LIST].forEach((e => this[DISPOSE](e.key, e.value))), 
  this[CACHE] = new Map, this[LRU_LIST] = new yallist, this[LENGTH] = 0;
 }
 dump() {
  return this[LRU_LIST].map((e => !isStale(this, e) && {
   k: e.key,
   v: e.value,
   e: e.now + (e.maxAge || 0)
  })).toArray().filter((e => e));
 }
 dumpLru() {
  return this[LRU_LIST];
 }
 set(e, t, r) {
  if ((r = r || this[MAX_AGE]) && "number" != typeof r) throw new TypeError("maxAge must be a number");
  const n = r ? Date.now() : 0, i = this[LENGTH_CALCULATOR](t, e);
  if (this[CACHE].has(e)) {
   if (i > this[MAX]) return del(this, this[CACHE].get(e)), !1;
   const s = this[CACHE].get(e).value;
   return this[DISPOSE] && (this[NO_DISPOSE_ON_SET] || this[DISPOSE](e, s.value)), 
   s.now = n, s.maxAge = r, s.value = t, this[LENGTH] += i - s.length, s.length = i, 
   this.get(e), trim(this), !0;
  }
  const s = new Entry(e, t, i, n, r);
  return s.length > this[MAX] ? (this[DISPOSE] && this[DISPOSE](e, t), !1) : (this[LENGTH] += s.length, 
  this[LRU_LIST].unshift(s), this[CACHE].set(e, this[LRU_LIST].head), trim(this), 
  !0);
 }
 has(e) {
  if (!this[CACHE].has(e)) return !1;
  const t = this[CACHE].get(e).value;
  return !isStale(this, t);
 }
 get(e) {
  return get(this, e, !0);
 }
 peek(e) {
  return get(this, e, !1);
 }
 pop() {
  const e = this[LRU_LIST].tail;
  return e ? (del(this, e), e.value) : null;
 }
 del(e) {
  del(this, this[CACHE].get(e));
 }
 load(e) {
  this.reset();
  const t = Date.now();
  for (let r = e.length - 1; r >= 0; r--) {
   const n = e[r], i = n.e || 0;
   if (0 === i) this.set(n.k, n.v); else {
    const e = i - t;
    e > 0 && this.set(n.k, n.v, e);
   }
  }
 }
 prune() {
  this[CACHE].forEach(((e, t) => get(this, t, !1)));
 }
}, eq_1 = (e, t, r) => 0 === compare_1(e, t, r), neq_1 = (e, t, r) => 0 !== compare_1(e, t, r), 
gt_1 = (e, t, r) => compare_1(e, t, r) > 0, gte_1 = (e, t, r) => compare_1(e, t, r) >= 0, 
lt_1 = (e, t, r) => compare_1(e, t, r) < 0, cmp_1 = (e, t, r, n) => {
 switch (t) {
 case "===":
  return "object" == typeof e && (e = e.version), "object" == typeof r && (r = r.version), 
  e === r;

 case "!==":
  return "object" == typeof e && (e = e.version), "object" == typeof r && (r = r.version), 
  e !== r;

 case "":
 case "=":
 case "==":
  return eq_1(e, r, n);

 case "!=":
  return neq_1(e, r, n);

 case ">":
  return gt_1(e, r, n);

 case ">=":
  return gte_1(e, r, n);

 case "<":
  return lt_1(e, r, n);

 case "<=":
  return lte_1(e, r, n);

 default:
  throw new TypeError(`Invalid operator: ${t}`);
 }
};

const ANY = Symbol("SemVer ANY");

class Comparator {
 static get ANY() {
  return ANY;
 }
 constructor(e, t) {
  if (t = parseOptions_1(t), e instanceof Comparator) {
   if (e.loose === !!t.loose) return e;
   e = e.value;
  }
  debug_1("comparator", e, t), this.options = t, this.loose = !!t.loose, this.parse(e), 
  this.semver === ANY ? this.value = "" : this.value = this.operator + this.semver.version, 
  debug_1("comp", this);
 }
 parse(e) {
  const t = this.options.loose ? re$1[t$1.COMPARATORLOOSE] : re$1[t$1.COMPARATOR], r = e.match(t);
  if (!r) throw new TypeError(`Invalid comparator: ${e}`);
  this.operator = void 0 !== r[1] ? r[1] : "", "=" === this.operator && (this.operator = ""), 
  r[2] ? this.semver = new semver(r[2], this.options.loose) : this.semver = ANY;
 }
 toString() {
  return this.value;
 }
 test(e) {
  if (debug_1("Comparator.test", e, this.options.loose), this.semver === ANY || e === ANY) return !0;
  if ("string" == typeof e) try {
   e = new semver(e, this.options);
  } catch (e) {
   return !1;
  }
  return cmp_1(e, this.operator, this.semver, this.options);
 }
 intersects(e, t) {
  if (!(e instanceof Comparator)) throw new TypeError("a Comparator is required");
  if (t && "object" == typeof t || (t = {
   loose: !!t,
   includePrerelease: !1
  }), "" === this.operator) return "" === this.value || new range(e.value, t).test(this.value);
  if ("" === e.operator) return "" === e.value || new range(this.value, t).test(e.semver);
  const r = !(">=" !== this.operator && ">" !== this.operator || ">=" !== e.operator && ">" !== e.operator), n = !("<=" !== this.operator && "<" !== this.operator || "<=" !== e.operator && "<" !== e.operator), i = this.semver.version === e.semver.version, s = !(">=" !== this.operator && "<=" !== this.operator || ">=" !== e.operator && "<=" !== e.operator), o = cmp_1(this.semver, "<", e.semver, t) && (">=" === this.operator || ">" === this.operator) && ("<=" === e.operator || "<" === e.operator), a = cmp_1(this.semver, ">", e.semver, t) && ("<=" === this.operator || "<" === this.operator) && (">=" === e.operator || ">" === e.operator);
  return r || n || i && s || o || a;
 }
}

comparator = Comparator;

const {re: re$1, t: t$1} = re_1;

class Range {
 constructor(e, t) {
  if (t = parseOptions_1(t), e instanceof Range) return e.loose === !!t.loose && e.includePrerelease === !!t.includePrerelease ? e : new Range(e.raw, t);
  if (e instanceof comparator) return this.raw = e.value, this.set = [ [ e ] ], this.format(), 
  this;
  if (this.options = t, this.loose = !!t.loose, this.includePrerelease = !!t.includePrerelease, 
  this.raw = e, this.set = e.split("||").map((e => this.parseRange(e.trim()))).filter((e => e.length)), 
  !this.set.length) throw new TypeError(`Invalid SemVer Range: ${e}`);
  if (this.set.length > 1) {
   const e = this.set[0];
   if (this.set = this.set.filter((e => !isNullSet(e[0]))), 0 === this.set.length) this.set = [ e ]; else if (this.set.length > 1) for (const e of this.set) if (1 === e.length && isAny(e[0])) {
    this.set = [ e ];
    break;
   }
  }
  this.format();
 }
 format() {
  return this.range = this.set.map((e => e.join(" ").trim())).join("||").trim(), this.range;
 }
 toString() {
  return this.range;
 }
 parseRange(e) {
  e = e.trim();
  const r = `parseRange:${Object.keys(this.options).join(",")}:${e}`, n = cache.get(r);
  if (n) return n;
  const i = this.options.loose, s = i ? re[t.HYPHENRANGELOOSE] : re[t.HYPHENRANGE];
  e = e.replace(s, hyphenReplace(this.options.includePrerelease)), debug_1("hyphen replace", e), 
  e = e.replace(re[t.COMPARATORTRIM], comparatorTrimReplace), debug_1("comparator trim", e);
  let o = (e = (e = (e = e.replace(re[t.TILDETRIM], tildeTrimReplace)).replace(re[t.CARETTRIM], caretTrimReplace)).split(/\s+/).join(" ")).split(" ").map((e => parseComparator(e, this.options))).join(" ").split(/\s+/).map((e => replaceGTE0(e, this.options)));
  i && (o = o.filter((e => (debug_1("loose invalid filter", e, this.options), !!e.match(re[t.COMPARATORLOOSE]))))), 
  debug_1("range list", o);
  const a = new Map, l = o.map((e => new comparator(e, this.options)));
  for (const e of l) {
   if (isNullSet(e)) return [ e ];
   a.set(e.value, e);
  }
  a.size > 1 && a.has("") && a.delete("");
  const c = [ ...a.values() ];
  return cache.set(r, c), c;
 }
 intersects(e, t) {
  if (!(e instanceof Range)) throw new TypeError("a Range is required");
  return this.set.some((r => isSatisfiable(r, t) && e.set.some((e => isSatisfiable(e, t) && r.every((r => e.every((e => r.intersects(e, t)))))))));
 }
 test(e) {
  if (!e) return !1;
  if ("string" == typeof e) try {
   e = new semver(e, this.options);
  } catch (e) {
   return !1;
  }
  for (let t = 0; t < this.set.length; t++) if (testSet(this.set[t], e, this.options)) return !0;
  return !1;
 }
}

range = Range;

const cache = new lruCache({
 max: 1e3
}), {re, t, comparatorTrimReplace, tildeTrimReplace, caretTrimReplace} = re_1, isNullSet = e => "<0.0.0-0" === e.value, isAny = e => "" === e.value, isSatisfiable = (e, t) => {
 let r = !0;
 const n = e.slice();
 let i = n.pop();
 for (;r && n.length; ) r = n.every((e => i.intersects(e, t))), i = n.pop();
 return r;
}, parseComparator = (e, t) => (debug_1("comp", e, t), e = replaceCarets(e, t), 
debug_1("caret", e), e = replaceTildes(e, t), debug_1("tildes", e), e = replaceXRanges(e, t), 
debug_1("xrange", e), e = replaceStars(e, t), debug_1("stars", e), e), isX = e => !e || "x" === e.toLowerCase() || "*" === e, replaceTildes = (e, t) => e.trim().split(/\s+/).map((e => replaceTilde(e, t))).join(" "), replaceTilde = (e, r) => {
 const n = r.loose ? re[t.TILDELOOSE] : re[t.TILDE];
 return e.replace(n, ((t, r, n, i, s) => {
  let o;
  return debug_1("tilde", e, t, r, n, i, s), isX(r) ? o = "" : isX(n) ? o = `>=${r}.0.0 <${+r + 1}.0.0-0` : isX(i) ? o = `>=${r}.${n}.0 <${r}.${+n + 1}.0-0` : s ? (debug_1("replaceTilde pr", s), 
  o = `>=${r}.${n}.${i}-${s} <${r}.${+n + 1}.0-0`) : o = `>=${r}.${n}.${i} <${r}.${+n + 1}.0-0`, 
  debug_1("tilde return", o), o;
 }));
}, replaceCarets = (e, t) => e.trim().split(/\s+/).map((e => replaceCaret(e, t))).join(" "), replaceCaret = (e, r) => {
 debug_1("caret", e, r);
 const n = r.loose ? re[t.CARETLOOSE] : re[t.CARET], i = r.includePrerelease ? "-0" : "";
 return e.replace(n, ((t, r, n, s, o) => {
  let a;
  return debug_1("caret", e, t, r, n, s, o), isX(r) ? a = "" : isX(n) ? a = `>=${r}.0.0${i} <${+r + 1}.0.0-0` : isX(s) ? a = "0" === r ? `>=${r}.${n}.0${i} <${r}.${+n + 1}.0-0` : `>=${r}.${n}.0${i} <${+r + 1}.0.0-0` : o ? (debug_1("replaceCaret pr", o), 
  a = "0" === r ? "0" === n ? `>=${r}.${n}.${s}-${o} <${r}.${n}.${+s + 1}-0` : `>=${r}.${n}.${s}-${o} <${r}.${+n + 1}.0-0` : `>=${r}.${n}.${s}-${o} <${+r + 1}.0.0-0`) : (debug_1("no pr"), 
  a = "0" === r ? "0" === n ? `>=${r}.${n}.${s}${i} <${r}.${n}.${+s + 1}-0` : `>=${r}.${n}.${s}${i} <${r}.${+n + 1}.0-0` : `>=${r}.${n}.${s} <${+r + 1}.0.0-0`), 
  debug_1("caret return", a), a;
 }));
}, replaceXRanges = (e, t) => (debug_1("replaceXRanges", e, t), e.split(/\s+/).map((e => replaceXRange(e, t))).join(" ")), replaceXRange = (e, r) => {
 e = e.trim();
 const n = r.loose ? re[t.XRANGELOOSE] : re[t.XRANGE];
 return e.replace(n, ((t, n, i, s, o, a) => {
  debug_1("xRange", e, t, n, i, s, o, a);
  const l = isX(i), c = l || isX(s), u = c || isX(o), f = u;
  return "=" === n && f && (n = ""), a = r.includePrerelease ? "-0" : "", l ? t = ">" === n || "<" === n ? "<0.0.0-0" : "*" : n && f ? (c && (s = 0), 
  o = 0, ">" === n ? (n = ">=", c ? (i = +i + 1, s = 0, o = 0) : (s = +s + 1, o = 0)) : "<=" === n && (n = "<", 
  c ? i = +i + 1 : s = +s + 1), "<" === n && (a = "-0"), t = `${n + i}.${s}.${o}${a}`) : c ? t = `>=${i}.0.0${a} <${+i + 1}.0.0-0` : u && (t = `>=${i}.${s}.0${a} <${i}.${+s + 1}.0-0`), 
  debug_1("xRange return", t), t;
 }));
}, replaceStars = (e, r) => (debug_1("replaceStars", e, r), e.trim().replace(re[t.STAR], "")), replaceGTE0 = (e, r) => (debug_1("replaceGTE0", e, r), 
e.trim().replace(re[r.includePrerelease ? t.GTE0PRE : t.GTE0], "")), hyphenReplace = e => (t, r, n, i, s, o, a, l, c, u, f, h, p) => `${r = isX(n) ? "" : isX(i) ? `>=${n}.0.0${e ? "-0" : ""}` : isX(s) ? `>=${n}.${i}.0${e ? "-0" : ""}` : o ? `>=${r}` : `>=${r}${e ? "-0" : ""}`} ${l = isX(c) ? "" : isX(u) ? `<${+c + 1}.0.0-0` : isX(f) ? `<${c}.${+u + 1}.0-0` : h ? `<=${c}.${u}.${f}-${h}` : e ? `<${c}.${u}.${+f + 1}-0` : `<=${l}`}`.trim(), testSet = (e, t, r) => {
 for (let r = 0; r < e.length; r++) if (!e[r].test(t)) return !1;
 if (t.prerelease.length && !r.includePrerelease) {
  for (let r = 0; r < e.length; r++) if (debug_1(e[r].semver), e[r].semver !== comparator.ANY && e[r].semver.prerelease.length > 0) {
   const n = e[r].semver;
   if (n.major === t.major && n.minor === t.minor && n.patch === t.patch) return !0;
  }
  return !1;
 }
 return !0;
};

satisfies_1 = (e, t, r) => {
 try {
  t = new range(t, r);
 } catch (e) {
  return !1;
 }
 return t.test(e);
};

class NodeLazyRequire {
 constructor(e, t) {
  this.nodeResolveModule = e, this.lazyDependencies = t, this.ensured = new Set;
 }
 async ensure(e, t) {
  const r = [], n = [];
  if (t.forEach((t => {
   if (!this.ensured.has(t)) {
    const {minVersion: r, recommendedVersion: i, maxVersion: s} = this.lazyDependencies[t];
    try {
     const n = this.nodeResolveModule.resolveModule(e, t), i = JSON.parse(fs__default.default.readFileSync(n, "utf8"));
     if (s ? satisfies_1(i.version, `${r} - ${major_1(s)}.x`) : lte_1(r, i.version)) return void this.ensured.add(t);
    } catch (e) {}
    n.push(`${t}@${i}`);
   }
  })), n.length > 0) {
   const e = buildError(r);
   e.header = "Please install supported versions of dev dependencies with either npm or yarn.", 
   e.messageText = `npm install --save-dev ${n.join(" ")}`;
  }
  return r;
 }
 require(e, t) {
  const r = this.getModulePath(e, t);
  return require(r);
 }
 getModulePath(e, t) {
  const r = this.nodeResolveModule.resolveModule(e, t);
  return path__default.default.dirname(r);
 }
}

class NodeResolveModule {
 constructor() {
  this.resolveModuleCache = new Map;
 }
 resolveModule(e, t, r) {
  const n = `${e}:${t}`, i = this.resolveModuleCache.get(n);
  if (i) return i;
  if (r && r.manuallyResolve) return this.resolveModuleManually(e, t, n);
  if (t.startsWith("@types/")) return this.resolveTypesModule(e, t, n);
  const s = require("module");
  e = path__default.default.resolve(e);
  const o = path__default.default.join(e, "noop.js");
  let a = normalizePath(s._resolveFilename(t, {
   id: o,
   filename: o,
   paths: s._nodeModulePaths(e)
  }));
  const l = normalizePath(path__default.default.parse(e).root);
  let c;
  for (;a !== l; ) if (a = normalizePath(path__default.default.dirname(a)), c = path__default.default.join(a, "package.json"), 
  fs__default.default.existsSync(c)) return this.resolveModuleCache.set(n, c), c;
  throw new Error(`error loading "${t}" from "${e}"`);
 }
 resolveTypesModule(e, t, r) {
  const n = t.split("/"), i = normalizePath(path__default.default.parse(e).root);
  let s, o = normalizePath(path__default.default.join(e, "noop.js"));
  for (;o !== i; ) if (o = normalizePath(path__default.default.dirname(o)), s = path__default.default.join(o, "node_modules", n[0], n[1], "package.json"), 
  fs__default.default.existsSync(s)) return this.resolveModuleCache.set(r, s), s;
  throw new Error(`error loading "${t}" from "${e}"`);
 }
 resolveModuleManually(e, t, r) {
  const n = normalizePath(path__default.default.parse(e).root);
  let i, s = normalizePath(path__default.default.join(e, "noop.js"));
  for (;s !== n; ) if (s = normalizePath(path__default.default.dirname(s)), i = path__default.default.join(s, "node_modules", t, "package.json"), 
  fs__default.default.existsSync(i)) return this.resolveModuleCache.set(r, i), i;
  throw new Error(`error loading "${t}" from "${e}"`);
 }
}

const REGISTRY_URL = "https://registry.npmjs.org/@stencil/core", CHANGELOG = "https://github.com/ionic-team/stencil/blob/main/CHANGELOG.md", ARROW = "→", BOX_TOP_LEFT = "╭", BOX_TOP_RIGHT = "╮", BOX_BOTTOM_LEFT = "╰", BOX_BOTTOM_RIGHT = "╯", BOX_VERTICAL = "│", BOX_HORIZONTAL = "─", PADDING = 2, INDENT = "   ";

class NodeWorkerMain extends require$$7.EventEmitter {
 constructor(e, t) {
  super(), this.id = e, this.tasks = new Map, this.exitCode = null, this.processQueue = !0, 
  this.sendQueue = [], this.stopped = !1, this.successfulMessage = !1, this.totalTasksAssigned = 0, 
  this.fork(t);
 }
 fork(e) {
  const t = {
   execArgv: process.execArgv.filter((e => !/^--(debug|inspect)/.test(e))),
   env: process.env,
   cwd: process.cwd(),
   silent: !0
  };
  this.childProcess = cp__namespace.fork(e, [], t), this.childProcess.stdout.setEncoding("utf8"), 
  this.childProcess.stdout.on("data", (e => {
   console.log(e);
  })), this.childProcess.stderr.setEncoding("utf8"), this.childProcess.stderr.on("data", (e => {
   console.log(e);
  })), this.childProcess.on("message", this.receiveFromWorker.bind(this)), this.childProcess.on("error", (e => {
   this.emit("error", e);
  })), this.childProcess.once("exit", (e => {
   this.exitCode = e, this.emit("exit", e);
  }));
 }
 run(e) {
  this.totalTasksAssigned++, this.tasks.set(e.stencilId, e), this.sendToWorker({
   stencilId: e.stencilId,
   args: e.inputArgs
  });
 }
 sendToWorker(e) {
  this.processQueue ? this.childProcess.send(e, (e => {
   if (!(e && e instanceof Error) && (this.processQueue = !0, this.sendQueue.length > 0)) {
    const e = this.sendQueue.slice();
    this.sendQueue = [], e.forEach((e => this.sendToWorker(e)));
   }
  })) && !/^win/.test(process.platform) || (this.processQueue = !1) : this.sendQueue.push(e);
 }
 receiveFromWorker(e) {
  if (this.successfulMessage = !0, this.stopped) return;
  const t = this.tasks.get(e.stencilId);
  t ? (null != e.stencilRtnError ? t.reject(e.stencilRtnError) : t.resolve(e.stencilRtnValue), 
  this.tasks.delete(e.stencilId), this.emit("response", e)) : null != e.stencilRtnError && this.emit("error", e.stencilRtnError);
 }
 stop() {
  this.stopped = !0, this.tasks.forEach((e => e.reject(TASK_CANCELED_MSG))), this.tasks.clear(), 
  this.successfulMessage ? (this.childProcess.send({
   exit: !0
  }), setTimeout((() => {
   null === this.exitCode && this.childProcess.kill("SIGKILL");
  }), 100)) : this.childProcess.kill("SIGKILL");
 }
}

class NodeWorkerController extends require$$7.EventEmitter {
 constructor(e, t) {
  super(), this.forkModulePath = e, this.workerIds = 0, this.stencilId = 0, this.isEnding = !1, 
  this.taskQueue = [], this.workers = [];
  const r = require$$6.cpus().length;
  this.useForkedWorkers = t > 0, this.maxWorkers = Math.max(Math.min(t, r), 2) - 1, 
  this.useForkedWorkers ? this.startWorkers() : this.mainThreadRunner = require(e);
 }
 onError(e, t) {
  if ("ERR_IPC_CHANNEL_CLOSED" === e.code) return this.stopWorker(t);
  "EPIPE" !== e.code && console.error(e);
 }
 onExit(e) {
  setTimeout((() => {
   let t = !1;
   const r = this.workers.find((t => t.id === e));
   r && (r.tasks.forEach((e => {
    e.retries++, this.taskQueue.unshift(e), t = !0;
   })), r.tasks.clear()), this.stopWorker(e), t && this.processTaskQueue();
  }), 10);
 }
 startWorkers() {
  for (;this.workers.length < this.maxWorkers; ) this.startWorker();
 }
 startWorker() {
  const e = this.workerIds++, t = new NodeWorkerMain(e, this.forkModulePath);
  t.on("response", this.processTaskQueue.bind(this)), t.once("exit", (() => {
   this.onExit(e);
  })), t.on("error", (t => {
   this.onError(t, e);
  })), this.workers.push(t);
 }
 stopWorker(e) {
  const t = this.workers.find((t => t.id === e));
  if (t) {
   t.stop();
   const e = this.workers.indexOf(t);
   e > -1 && this.workers.splice(e, 1);
  }
 }
 processTaskQueue() {
  if (!this.isEnding) for (this.useForkedWorkers && this.startWorkers(); this.taskQueue.length > 0; ) {
   const e = getNextWorker(this.workers);
   if (!e) break;
   e.run(this.taskQueue.shift());
  }
 }
 send(...e) {
  return this.isEnding ? Promise.reject(TASK_CANCELED_MSG) : this.useForkedWorkers ? new Promise(((t, r) => {
   const n = {
    stencilId: this.stencilId++,
    inputArgs: e,
    retries: 0,
    resolve: t,
    reject: r
   };
   this.taskQueue.push(n), this.processTaskQueue();
  })) : this.mainThreadRunner[e[0]].apply(null, e.slice(1));
 }
 handler(e) {
  return (...t) => this.send(e, ...t);
 }
 cancelTasks() {
  for (const e of this.workers) e.tasks.forEach((e => e.reject(TASK_CANCELED_MSG))), 
  e.tasks.clear();
  this.taskQueue.length = 0;
 }
 destroy() {
  if (!this.isEnding) {
   this.isEnding = !0;
   for (const e of this.taskQueue) e.reject(TASK_CANCELED_MSG);
   this.taskQueue.length = 0;
   const e = this.workers.map((e => e.id));
   for (const t of e) this.stopWorker(t);
  }
 }
}

exports.createNodeLogger = e => {
 const t = function r(e) {
  return {
   cwd: () => e.cwd(),
   emoji: t => "win32" !== e.platform ? t : "",
   getColumns: () => {
    var t, r;
    const n = null !== (r = null === (t = null == e ? void 0 : e.stdout) || void 0 === t ? void 0 : t.columns) && void 0 !== r ? r : 80;
    return Math.max(Math.min(n, 120), 60);
   },
   memoryUsage: () => e.memoryUsage().rss,
   relativePath: (e, t) => path__default.default.relative(e, t),
   writeLogs: (e, t, r) => {
    if (r) try {
     fs__default.default.accessSync(e);
    } catch (e) {
     r = !1;
    }
    r ? fs__default.default.appendFileSync(e, t) : fs__default.default.writeFileSync(e, t);
   },
   createLineUpdater: async () => {
    const t = await Promise.resolve().then((function() {
     return _interopNamespace(require("readline"));
    }));
    let r = Promise.resolve();
    const n = n => (n = n.substring(0, e.stdout.columns - 5) + "[0m", r = r.then((() => new Promise((r => {
     t.clearLine(e.stdout, 0), t.cursorTo(e.stdout, 0, null), e.stdout.write(n, r);
    })))));
    return e.stdout.write("[?25l"), {
     update: n,
     stop: () => n("[?25h")
    };
   }
  };
 }(e.process);
 return createTerminalLogger(t);
}, exports.createNodeSys = function createNodeSys(e = {}) {
 var t;
 const r = null !== (t = null == e ? void 0 : e.process) && void 0 !== t ? t : global.process, n = new Set, i = [], s = require$$6.cpus(), o = s.length, a = require$$6.platform(), l = path__default.default.join(__dirname, "..", "..", "compiler", "stencil.js"), c = path__default.default.join(__dirname, "..", "..", "dev-server", "index.js"), u = () => {
  const e = [];
  let t;
  for (;"function" == typeof (t = i.pop()); ) try {
   const n = t();
   (r = n) && ("object" == typeof r || "function" == typeof r) && "function" == typeof r.then && e.push(n);
  } catch (e) {}
  var r;
  return e.length > 0 ? Promise.all(e) : null;
 }, f = {
  name: "node",
  version: r.versions.node,
  access: e => new Promise((t => {
   fs__default.default.access(e, (e => t(!e)));
  })),
  accessSync(e) {
   let t = !1;
   try {
    fs__default.default.accessSync(e), t = !0;
   } catch (e) {}
   return t;
  },
  addDestory(e) {
   n.add(e);
  },
  removeDestory(e) {
   n.delete(e);
  },
  applyPrerenderGlobalPatch(e) {
   if ("function" != typeof global.fetch) {
    const t = require(path__default.default.join(__dirname, "node-fetch.js"));
    global.fetch = (r, n) => {
     if ("string" == typeof r) {
      const i = new URL(r, e.devServerHostUrl).href;
      return t.fetch(i, n);
     }
     return r.url = new URL(r.url, e.devServerHostUrl).href, t.fetch(r, n);
    }, global.Headers = t.Headers, global.Request = t.Request, global.Response = t.Response, 
    global.FetchError = t.FetchError;
   }
   e.window.fetch = global.fetch, e.window.Headers = global.Headers, e.window.Request = global.Request, 
   e.window.Response = global.Response, e.window.FetchError = global.FetchError;
  },
  fetch: (e, t) => {
   const r = require(path__default.default.join(__dirname, "node-fetch.js"));
   if ("string" == typeof e) {
    const n = new URL(e).href;
    return r.fetch(n, t);
   }
   return e.url = new URL(e.url).href, r.fetch(e, t);
  },
  checkVersion,
  copyFile: (e, t) => new Promise((r => {
   fs__default.default.copyFile(e, t, (e => {
    r(!e);
   }));
  })),
  createDir: (e, t) => new Promise((r => {
   t ? fs__default.default.mkdir(e, t, (t => {
    r({
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     newDirs: [],
     error: t
    });
   })) : fs__default.default.mkdir(e, (t => {
    r({
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     newDirs: [],
     error: t
    });
   }));
  })),
  createDirSync(e, t) {
   const r = {
    basename: path__default.default.basename(e),
    dirname: path__default.default.dirname(e),
    path: e,
    newDirs: [],
    error: null
   };
   try {
    fs__default.default.mkdirSync(e, t);
   } catch (e) {
    r.error = e;
   }
   return r;
  },
  createWorkerController(e) {
   const t = path__default.default.join(__dirname, "worker.js");
   return new NodeWorkerController(t, e);
  },
  async destroy() {
   const e = [];
   n.forEach((t => {
    try {
     const r = t();
     r && r.then && e.push(r);
    } catch (e) {
     console.error(`node sys destroy: ${e}`);
    }
   })), e.length > 0 && await Promise.all(e), n.clear();
  },
  dynamicImport: e => Promise.resolve(require(e)),
  encodeToBase64: e => Buffer.from(e).toString("base64"),
  ensureDependencies: async () => ({
   stencilPath: f.getCompilerExecutingPath(),
   diagnostics: []
  }),
  async ensureResources() {},
  exit: async e => {
   await u(), exit(e);
  },
  getCurrentDirectory: () => normalizePath(r.cwd()),
  getCompilerExecutingPath: () => l,
  getDevServerExecutingPath: () => c,
  getEnvironmentVar: e => process.env[e],
  getLocalModulePath: () => null,
  getRemoteModuleUrl: () => null,
  glob: asyncGlob,
  hardwareConcurrency: o,
  isSymbolicLink: e => new Promise((t => {
   try {
    fs__default.default.lstat(e, ((e, r) => {
     t(!e && r.isSymbolicLink());
    }));
   } catch (e) {
    t(!1);
   }
  })),
  nextTick: r.nextTick,
  normalizePath,
  onProcessInterrupt: e => {
   i.includes(e) || i.push(e);
  },
  platformPath: path__default.default,
  readDir: e => new Promise((t => {
   fs__default.default.readdir(e, ((r, n) => {
    t(r ? [] : n.map((t => normalizePath(path__default.default.join(e, t)))));
   }));
  })),
  parseYarnLockFile: e => lockfile.parse(e),
  isTTY() {
   var e;
   return !!(null === (e = null === process || void 0 === process ? void 0 : process.stdout) || void 0 === e ? void 0 : e.isTTY);
  },
  readDirSync(e) {
   try {
    return fs__default.default.readdirSync(e).map((t => normalizePath(path__default.default.join(e, t))));
   } catch (e) {}
   return [];
  },
  readFile: (e, t) => new Promise("binary" === t ? t => {
   fs__default.default.readFile(e, ((e, r) => {
    t(r);
   }));
  } : t => {
   fs__default.default.readFile(e, "utf8", ((e, r) => {
    t(r);
   }));
  }),
  readFileSync(e) {
   try {
    return fs__default.default.readFileSync(e, "utf8");
   } catch (e) {}
  },
  homeDir() {
   try {
    return require$$6__namespace.homedir();
   } catch (e) {}
  },
  realpath: e => new Promise((t => {
   fs__default.default.realpath(e, "utf8", ((e, r) => {
    t({
     path: r,
     error: e
    });
   }));
  })),
  realpathSync(e) {
   const t = {
    path: void 0,
    error: null
   };
   try {
    t.path = fs__default.default.realpathSync(e, "utf8");
   } catch (e) {
    t.error = e;
   }
   return t;
  },
  rename: (e, t) => new Promise((r => {
   fs__default.default.rename(e, t, (n => {
    r({
     oldPath: e,
     newPath: t,
     error: n,
     oldDirs: [],
     oldFiles: [],
     newDirs: [],
     newFiles: [],
     renamed: [],
     isFile: !1,
     isDirectory: !1
    });
   }));
  })),
  resolvePath: e => normalizePath(e),
  removeDir: (e, t) => new Promise((r => {
   t && t.recursive ? fs__default.default.rmdir(e, {
    recursive: !0
   }, (t => {
    r({
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     removedDirs: [],
     removedFiles: [],
     error: t
    });
   })) : fs__default.default.rmdir(e, (t => {
    r({
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     removedDirs: [],
     removedFiles: [],
     error: t
    });
   }));
  })),
  removeDirSync(e, t) {
   try {
    return t && t.recursive ? fs__default.default.rmdirSync(e, {
     recursive: !0
    }) : fs__default.default.rmdirSync(e), {
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     removedDirs: [],
     removedFiles: [],
     error: null
    };
   } catch (t) {
    return {
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     removedDirs: [],
     removedFiles: [],
     error: t
    };
   }
  },
  removeFile: e => new Promise((t => {
   fs__default.default.unlink(e, (r => {
    t({
     basename: path__default.default.basename(e),
     dirname: path__default.default.dirname(e),
     path: e,
     error: r
    });
   }));
  })),
  removeFileSync(e) {
   const t = {
    basename: path__default.default.basename(e),
    dirname: path__default.default.dirname(e),
    path: e,
    error: null
   };
   try {
    fs__default.default.unlinkSync(e);
   } catch (e) {
    t.error = e;
   }
   return t;
  },
  setupCompiler(e) {
   const t = e.ts, r = t.sys.watchDirectory, n = t.sys.watchFile;
   f.watchTimeout = 80, f.events = (() => {
    const e = [], t = t => {
     const r = e.findIndex((e => e.callback === t));
     return r > -1 && (e.splice(r, 1), !0);
    };
    return {
     emit: (t, r) => {
      const n = t.toLowerCase().trim(), i = e.slice();
      for (const e of i) if (null == e.eventName) try {
       e.callback(t, r);
      } catch (e) {
       console.error(e);
      } else if (e.eventName === n) try {
       e.callback(r);
      } catch (e) {
       console.error(e);
      }
     },
     on: (r, n) => {
      if ("function" == typeof r) {
       const n = null, i = r;
       return e.push({
        eventName: n,
        callback: i
       }), () => t(i);
      }
      if ("string" == typeof r && "function" == typeof n) {
       const i = r.toLowerCase().trim(), s = n;
       return e.push({
        eventName: i,
        callback: s
       }), () => t(s);
      }
      return () => !1;
     },
     unsubscribeAll: () => {
      e.length = 0;
     }
    };
   })(), f.watchDirectory = (e, t, n) => {
    const i = r(e, (e => {
     t(normalizePath(e), "fileUpdate");
    }), n), s = () => {
     i.close();
    };
    return f.addDestory(s), {
     close() {
      f.removeDestory(s), i.close();
     }
    };
   }, f.watchFile = (e, r) => {
    const i = n(e, ((e, n) => {
     e = normalizePath(e), n === t.FileWatcherEventKind.Created ? (r(e, "fileAdd"), f.events.emit("fileAdd", e)) : n === t.FileWatcherEventKind.Changed ? (r(e, "fileUpdate"), 
     f.events.emit("fileUpdate", e)) : n === t.FileWatcherEventKind.Deleted && (r(e, "fileDelete"), 
     f.events.emit("fileDelete", e));
    }), 250, {
     watchFile: t.WatchFileKind.FixedPollingInterval,
     fallbackPolling: t.PollingWatchKind.FixedInterval
    }), s = () => {
     i.close();
    };
    return f.addDestory(s), {
     close() {
      f.removeDestory(s), i.close();
     }
    };
   };
  },
  stat: e => new Promise((t => {
   fs__default.default.stat(e, ((e, r) => {
    t(e ? {
     isDirectory: !1,
     isFile: !1,
     isSymbolicLink: !1,
     size: 0,
     mtimeMs: 0,
     error: e
    } : {
     isDirectory: r.isDirectory(),
     isFile: r.isFile(),
     isSymbolicLink: r.isSymbolicLink(),
     size: r.size,
     mtimeMs: r.mtimeMs,
     error: null
    });
   }));
  })),
  statSync(e) {
   try {
    const t = fs__default.default.statSync(e);
    return {
     isDirectory: t.isDirectory(),
     isFile: t.isFile(),
     isSymbolicLink: t.isSymbolicLink(),
     size: t.size,
     mtimeMs: t.mtimeMs,
     error: null
    };
   } catch (e) {
    return {
     isDirectory: !1,
     isFile: !1,
     isSymbolicLink: !1,
     size: 0,
     mtimeMs: 0,
     error: e
    };
   }
  },
  tmpDirSync: () => require$$6.tmpdir(),
  writeFile: (e, t) => new Promise((r => {
   fs__default.default.writeFile(e, t, (t => {
    r({
     path: e,
     error: t
    });
   }));
  })),
  writeFileSync(e, t) {
   const r = {
    path: e,
    error: null
   };
   try {
    fs__default.default.writeFileSync(e, t);
   } catch (e) {
    r.error = e;
   }
   return r;
  },
  generateContentHash(e, t) {
   let r = require$$3.createHash("sha1").update(e).digest("hex").toLowerCase();
   return "number" == typeof t && (r = r.slice(0, t)), Promise.resolve(r);
  },
  generateFileHash: (e, t) => new Promise(((r, n) => {
   const i = require$$3.createHash("sha1");
   fs__default.default.createReadStream(e).on("error", (e => n(e))).on("data", (e => i.update(e))).on("end", (() => {
    let e = i.digest("hex").toLowerCase();
    "number" == typeof t && (e = e.slice(0, t)), r(e);
   }));
  })),
  copy: nodeCopyTasks,
  details: {
   cpuModel: (Array.isArray(s) && s.length > 0 ? s[0] && s[0].model : "") || "",
   freemem: () => require$$6.freemem(),
   platform: "darwin" === a || "linux" === a ? a : "win32" === a ? "windows" : "",
   release: require$$6.release(),
   totalmem: require$$6.totalmem()
  }
 }, h = new NodeResolveModule;
 return f.lazyRequire = new NodeLazyRequire(h, {
  "@types/jest": {
   minVersion: "24.9.1",
   recommendedVersion: "27.0.3",
   maxVersion: "27.0.0"
  },
  jest: {
   minVersion: "24.9.1",
   recommendedVersion: "27.0.3",
   maxVersion: "27.0.0"
  },
  "jest-cli": {
   minVersion: "24.9.0",
   recommendedVersion: "27.4.5",
   maxVersion: "27.0.0"
  },
  puppeteer: {
   minVersion: "1.19.0",
   recommendedVersion: "10.0.0"
  },
  "puppeteer-core": {
   minVersion: "1.19.0",
   recommendedVersion: "5.2.1"
  },
  "workbox-build": {
   minVersion: "4.3.1",
   recommendedVersion: "4.3.1"
  }
 }), r.on("SIGINT", u), r.on("exit", u), f;
}, exports.setupNodeProcess = function setupNodeProcess(e) {
 e.process.on("unhandledRejection", (t => {
  if (!shouldIgnoreError(t)) {
   let r = "unhandledRejection";
   null != t && ("string" == typeof t ? r += ": " + t : t.stack ? r += ": " + t.stack : t.message && (r += ": " + t.message)), 
   e.logger.error(r);
  }
 }));
};