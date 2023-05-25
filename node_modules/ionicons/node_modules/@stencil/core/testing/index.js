/*!
 Stencil Testing v2.22.3 | MIT Licensed | https://stenciljs.com
 */
function _lazyRequire(e) {
 return new Proxy({}, {
  get(t, r) {
   const s = require(e);
   return Reflect.get(s, r);
  },
  set(t, r, s) {
   const n = require(e);
   return Reflect.set(n, r, s);
  }
 });
}

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
   var s = Object.getOwnPropertyDescriptor(e, r);
   Object.defineProperty(t, r, s.get ? s : {
    enumerable: !0,
    get: function() {
     return e[r];
    }
   });
  }
 })), t.default = e, Object.freeze(t);
}

async function startPuppeteerBrowser(e) {
 if (!e.flags.e2e) return null;
 const t = process.env, r = e.testing.browserExecutablePath ? "puppeteer-core" : "puppeteer", s = e.sys.lazyRequire.getModulePath(e.rootDir, r), n = e.sys.lazyRequire.require(e.rootDir, s);
 t.__STENCIL_PUPPETEER_MODULE__ = s, t.__STENCIL_BROWSER_WAIT_UNTIL = e.testing.browserWaitUntil, 
 e.flags.devtools && (e.testing.browserDevtools = !0, e.testing.browserHeadless = !1, 
 t.__STENCIL_E2E_DEVTOOLS__ = "true"), e.logger.debug(`puppeteer: ${s}`), e.logger.debug(`puppeteer headless: ${e.testing.browserHeadless}`), 
 Array.isArray(e.testing.browserArgs) && e.logger.debug(`puppeteer args: ${e.testing.browserArgs.join(" ")}`), 
 "boolean" == typeof e.testing.browserDevtools && e.logger.debug(`puppeteer devtools: ${e.testing.browserDevtools}`), 
 "number" == typeof e.testing.browserSlowMo && e.logger.debug(`puppeteer slowMo: ${e.testing.browserSlowMo}`);
 const o = {
  ignoreHTTPSErrors: !0,
  slowMo: e.testing.browserSlowMo
 };
 let i;
 if (e.testing.browserWSEndpoint) i = await n.connect({
  browserWSEndpoint: e.testing.browserWSEndpoint,
  ...o
 }); else {
  const t = {
   args: e.testing.browserArgs,
   headless: e.testing.browserHeadless,
   devtools: e.testing.browserDevtools,
   ...o
  };
  e.testing.browserExecutablePath && (t.executablePath = e.testing.browserExecutablePath), 
  i = await n.launch({
   ...t
  });
 }
 return t.__STENCIL_BROWSER_WS_ENDPOINT__ = i.wsEndpoint(), e.logger.debug(`puppeteer browser wsEndpoint: ${t.__STENCIL_BROWSER_WS_ENDPOINT__}`), 
 i;
}

function transpile(e, t = {}) {
 t = {
  ...t,
  componentExport: null,
  componentMetadata: "compilerstatic",
  coreImportPath: isString(t.coreImportPath) ? t.coreImportPath : "@stencil/core/internal/testing",
  currentDirectory: t.currentDirectory || process.cwd(),
  module: "cjs",
  proxy: null,
  sourceMap: "inline",
  style: null,
  styleImportData: "queryparams",
  target: "es2015"
 };
 try {
  const e = process.versions.node.split(".");
  parseInt(e[0], 10) >= 10 && (t.target = "es2017");
 } catch (e) {}
 return stencil_js.transpileSync(e, t);
}

function formatDiagnostic(e) {
 let t = "";
 return e.relFilePath && (t += e.relFilePath, "number" == typeof e.lineNumber && (t += ":" + e.lineNumber + 1, 
 "number" == typeof e.columnNumber && (t += ":" + e.columnNumber)), t += "\n"), t += e.messageText, 
 t;
}

function getCompilerOptions(e) {
 if (_tsCompilerOptions) return _tsCompilerOptions;
 if ("string" != typeof e) return null;
 e = normalizePath(e);
 const t = stencil_js.ts.findConfigFile(e, stencil_js.ts.sys.fileExists);
 if (!t) return null;
 const r = stencil_js.ts.readConfigFile(t, stencil_js.ts.sys.readFile);
 if (r.error) throw new Error(formatDiagnostic((e => {
  const t = {
   level: "warn",
   type: "typescript",
   language: "typescript",
   header: "TypeScript",
   code: e.code.toString(),
   messageText: flattenDiagnosticMessageText(e, e.messageText),
   relFilePath: null,
   absFilePath: null,
   lines: []
  };
  if (1 === e.category && (t.level = "error"), e.file) {
   t.absFilePath = e.file.fileName;
   const s = "string" != typeof (r = e.file.text) ? [] : (r = r.replace(/\\r/g, "\n")).split("\n"), n = e.file.getLineAndCharacterOfPosition(e.start), o = {
    lineIndex: n.line,
    lineNumber: n.line + 1,
    text: s[n.line],
    errorCharStart: n.character,
    errorLength: Math.max(e.length, 1)
   };
   if (t.lineNumber = o.lineNumber, t.columnNumber = o.errorCharStart + 1, t.lines.push(o), 
   0 === o.errorLength && o.errorCharStart > 0 && (o.errorLength = 1, o.errorCharStart--), 
   o.lineIndex > 0) {
    const e = {
     lineIndex: o.lineIndex - 1,
     lineNumber: o.lineNumber - 1,
     text: s[o.lineIndex - 1],
     errorCharStart: -1,
     errorLength: -1
    };
    t.lines.unshift(e);
   }
   if (o.lineIndex + 1 < s.length) {
    const e = {
     lineIndex: o.lineIndex + 1,
     lineNumber: o.lineNumber + 1,
     text: s[o.lineIndex + 1],
     errorCharStart: -1,
     errorLength: -1
    };
    t.lines.push(e);
   }
  }
  var r;
  return t;
 })(r.error)));
 const s = stencil_js.ts.parseJsonConfigFileContent(r.config, stencil_js.ts.sys, e, void 0, t);
 return _tsCompilerOptions = s.options, _tsCompilerOptions;
}

function setScreenshotEmulateData(e, t) {
 const r = {
  userAgent: "default",
  viewport: {
   width: 800,
   height: 600,
   deviceScaleFactor: 1,
   isMobile: !1,
   hasTouch: !1,
   isLandscape: !1
  }
 };
 if ("string" == typeof e.device) try {
  const s = require(t.__STENCIL_PUPPETEER_MODULE__ + "/DeviceDescriptors")[e.device];
  if (!s) return void console.error(`invalid emulate device: ${e.device}`);
  r.device = e.device, r.userAgent = s.userAgent, r.viewport = s.viewport;
 } catch (e) {
  return void console.error("error loading puppeteer DeviceDescriptors", e);
 }
 e.viewport && ("number" == typeof e.viewport.width && (r.viewport.width = e.viewport.width), 
 "number" == typeof e.viewport.height && (r.viewport.height = e.viewport.height), 
 "number" == typeof e.viewport.deviceScaleFactor && (r.viewport.deviceScaleFactor = e.viewport.deviceScaleFactor), 
 "boolean" == typeof e.viewport.hasTouch && (r.viewport.hasTouch = e.viewport.hasTouch), 
 "boolean" == typeof e.viewport.isLandscape && (r.viewport.isLandscape = e.viewport.isLandscape), 
 "boolean" == typeof e.viewport.isMobile && (r.viewport.isMobile = e.viewport.isMobile), 
 "string" == typeof e.userAgent && (r.userAgent = e.userAgent)), t.__STENCIL_EMULATE__ = JSON.stringify(r);
}

async function runJest(e, t) {
 let r = !1;
 try {
  const s = function s(e, t) {
   let r = e.emulate.slice();
   if ("string" == typeof t.emulate) {
    const e = t.emulate.toLowerCase();
    r = r.filter((t => "string" == typeof t.device && t.device.toLowerCase() === e || !("string" != typeof t.userAgent || !t.userAgent.toLowerCase().includes(e))));
   }
   return r;
  }(e.testing, e.flags);
  t.__STENCIL_EMULATE_CONFIGS__ = JSON.stringify(s), t.__STENCIL_ENV__ = JSON.stringify(e.env), 
  e.flags.ci || e.flags.e2e ? t.__STENCIL_DEFAULT_TIMEOUT__ = "30000" : t.__STENCIL_DEFAULT_TIMEOUT__ = "15000", 
  e.flags.devtools && (t.__STENCIL_DEFAULT_TIMEOUT__ = "300000000"), e.logger.debug(`default timeout: ${t.__STENCIL_DEFAULT_TIMEOUT__}`);
  const n = function n(e) {
   const t = require("yargs"), r = e.flags.knownArgs.slice();
   r.some((e => e.startsWith("--max-workers") || e.startsWith("--maxWorkers"))) || r.push(`--max-workers=${e.maxConcurrentWorkers}`), 
   e.flags.devtools && r.push("--runInBand");
   const s = [ ...r, ...e.flags.unknownArgs ];
   e.logger.info(e.logger.magenta(`jest args: ${s.join(" ")}`));
   let n = t(s).argv;
   if (n = {
    detectLeaks: !1,
    "detect-leaks": !1,
    detectOpenHandles: !1,
    "detect-open-handles": !1,
    errorOnDeprecated: !1,
    "error-on-deprecated": !1,
    listTests: !1,
    "list-tests": !1,
    maxConcurrency: 5,
    "max-concurrency": 5,
    notifyMode: "failure-change",
    "notify-mode": "failure-change",
    passWithNoTests: !1,
    "pass-with-no-tests": !1,
    runTestsByPath: !1,
    "run-tests-by-path": !1,
    testLocationInResults: !1,
    "test-location-in-results": !1,
    ...n
   }, n.config = function o(e) {
    const t = e.testing, r = require("jest-config").defaults, s = Object.keys(r), n = {};
    return Object.keys(t).forEach((e => {
     s.includes(e) && (n[e] = t[e]);
    })), n.rootDir = e.rootDir, isString(t.collectCoverage) && (n.collectCoverage = t.collectCoverage), 
    Array.isArray(t.collectCoverageFrom) && (n.collectCoverageFrom = t.collectCoverageFrom), 
    isString(t.coverageDirectory) && (n.coverageDirectory = t.coverageDirectory), t.coverageThreshold && (n.coverageThreshold = t.coverageThreshold), 
    isString(t.globalSetup) && (n.globalSetup = t.globalSetup), isString(t.globalTeardown) && (n.globalTeardown = t.globalTeardown), 
    isString(t.preset) && (n.preset = t.preset), t.projects && (n.projects = t.projects), 
    Array.isArray(t.reporters) && (n.reporters = t.reporters), isString(t.testResultsProcessor) && (n.testResultsProcessor = t.testResultsProcessor), 
    t.transform && (n.transform = t.transform), t.verbose && (n.verbose = t.verbose), 
    n.testRunner = "jest-jasmine2", JSON.stringify(n);
   }(e), "string" == typeof n.maxWorkers) try {
    n.maxWorkers = parseInt(n.maxWorkers, 10);
   } catch (e) {}
   return "string" == typeof n.ci && (n.ci = "true" === n.ci || "" === n.ci), n;
  }(e), o = function o(e, t) {
   const r = t.projects ? t.projects : [];
   return r.push(e.rootDir), r;
  }(e, n), {runCLI: i} = require("@jest/core");
  r = !!(await i(n, o)).results.success;
 } catch (t) {
  e.logger.error(`runJest: ${t}`);
 }
 return r;
}

function toHaveClasses(e, t) {
 if (!e) throw new Error("expect toHaveClasses value is null");
 if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
 if (1 !== e.nodeType) throw new Error("expect toHaveClasses value is not an element");
 const r = t.every((t => e.classList.contains(t)));
 return {
  message: () => `expected to ${r ? "not " : ""}have css classes "${t.join(" ")}", but className is "${e.className}"`,
  pass: r
 };
}

function compareHtml(e, t, r) {
 if (null == e) throw new Error(`expect toEqualHtml() value is "${e}"`);
 if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
 let s;
 if (1 === e.nodeType) {
  const t = function n(e) {
   return e && e.ownerDocument && e.ownerDocument.defaultView && e.ownerDocument.defaultView.__stencil_spec_options || {};
  }(e);
  s = index_cjs.serializeNodeToHtml(e, {
   prettyHtml: !0,
   outerHtml: !0,
   removeHtmlComments: !1 === t.includeAnnotations,
   excludeTags: [ "body" ],
   serializeShadowRoot: r
  });
 } else if (11 === e.nodeType) s = index_cjs.serializeNodeToHtml(e, {
  prettyHtml: !0,
  excludeTags: [ "style" ],
  excludeTagContent: [ "style" ],
  serializeShadowRoot: r
 }); else {
  if ("string" != typeof e) throw new Error("expect toEqualHtml() value should be an element, shadow root or string.");
  {
   const t = index_cjs.parseHtmlToFragment(e);
   s = index_cjs.serializeNodeToHtml(t, {
    prettyHtml: !0,
    serializeShadowRoot: r
   });
  }
 }
 const o = index_cjs.parseHtmlToFragment(t), i = index_cjs.serializeNodeToHtml(o, {
  prettyHtml: !0,
  excludeTags: [ "body" ]
 });
 return s !== i ? (expect(s).toBe(i), {
  message: () => "HTML does not match",
  pass: !1
 }) : {
  message: () => "expect HTML to match",
  pass: !0
 };
}

async function globalMockFetch(e) {
 let t;
 if (null == e) throw new Error("missing url input for mock fetch()");
 if ("string" == typeof e) t = e; else {
  if ("string" != typeof e.url) throw new Error("invalid url for mock fetch()");
  t = e.url;
 }
 t = new URL(t, location.href).href;
 let r = mockedResponses.get(t);
 if (null == r) {
  const e = new URL(FETCH_DEFAULT_PATH, location.href);
  r = mockedResponses.get(e.href);
 }
 if (null == r) return new MockResponse404;
 const s = r.response.clone();
 return "number" != typeof s.status && (s.status = 200), "string" != typeof s.statusText && (s.status >= 500 ? s.statusText = "Internal Server Error" : 404 === s.status ? s.statusText = "Not Found" : s.status >= 400 ? s.statusText = "Bad Request" : 302 === s.status ? s.statusText = "Found" : 301 === s.status ? s.statusText = "Moved Permanently" : s.status >= 300 ? s.statusText = "Redirection" : s.statusText = "OK"), 
 s.ok = s.status >= 200 && s.status <= 299, "string" != typeof s.type && (s.type = "basic"), 
 s;
}

function setMockedResponse(e, t, r) {
 if (!e) throw new Error("MockResponse required");
 "string" == typeof e.url && "" !== e.url || ("string" == typeof t ? e.url = t : t && "string" == typeof t.url ? e.url = t.url : e.url = FETCH_DEFAULT_PATH);
 const s = new URL(e.url, location.href);
 e.url = s.href;
 const n = {
  response: e,
  reject: r
 };
 mockedResponses.set(e.url, n);
}

function resetBuildConditionals(e) {
 Object.keys(e).forEach((t => {
  e[t] = !0;
 })), e.isDev = !0, e.isTesting = !0, e.isDebug = !1, e.lazyLoad = !0, e.member = !0, 
 e.reflect = !0, e.scoped = !0, e.shadowDom = !0, e.slotRelocation = !0, e.asyncLoading = !0, 
 e.svg = !0, e.updatable = !0, e.vdomAttribute = !0, e.vdomClass = !0, e.vdomFunctional = !0, 
 e.vdomKey = !0, e.vdomPropOrAttr = !0, e.vdomRef = !0, e.vdomListener = !0, e.vdomStyle = !0, 
 e.vdomText = !0, e.vdomXlink = !0, e.allRenderFn = !1, e.devTools = !1, e.hydrateClientSide = !1, 
 e.hydrateServerSide = !1, e.cssAnnotations = !1, e.style = !1, e.hydratedAttribute = !1, 
 e.hydratedClass = !0, e.invisiblePrehydration = !0, e.appendChildSlotFix = !1, e.cloneNodeFix = !1, 
 e.dynamicImportShim = !1, e.hotModuleReplacement = !1, e.safari10 = !1, e.scriptDataOpts = !1, 
 e.scopedSlotTextContentFix = !1, e.slotChildNodesFix = !1;
}

function assertPath(e) {
 if ("string" != typeof e) throw new TypeError("Path must be a string. Received " + JSON.stringify(e));
}

function normalizeStringPosix(e, t) {
 var r, s, n, o = "", i = 0, a = -1, l = 0;
 for (s = 0; s <= e.length; ++s) {
  if (s < e.length) r = e.charCodeAt(s); else {
   if (47 === r) break;
   r = 47;
  }
  if (47 === r) {
   if (a === s - 1 || 1 === l) ; else if (a !== s - 1 && 2 === l) {
    if (o.length < 2 || 2 !== i || 46 !== o.charCodeAt(o.length - 1) || 46 !== o.charCodeAt(o.length - 2)) if (o.length > 2) {
     if ((n = o.lastIndexOf("/")) !== o.length - 1) {
      -1 === n ? (o = "", i = 0) : i = (o = o.slice(0, n)).length - 1 - o.lastIndexOf("/"), 
      a = s, l = 0;
      continue;
     }
    } else if (2 === o.length || 1 === o.length) {
     o = "", i = 0, a = s, l = 0;
     continue;
    }
    t && (o.length > 0 ? o += "/.." : o = "..", i = 2);
   } else o.length > 0 ? o += "/" + e.slice(a + 1, s) : o = e.slice(a + 1, s), i = s - a - 1;
   a = s, l = 0;
  } else 46 === r && -1 !== l ? ++l : l = -1;
 }
 return o;
}

function specifierIncluded$1(e, t) {
 var r, s, n, o = e.split("."), i = t.split(" "), a = i.length > 1 ? i[0] : "=", l = (i.length > 1 ? i[1] : i[0]).split(".");
 for (r = 0; r < 3; ++r) if ((s = parseInt(o[r] || 0, 10)) !== (n = parseInt(l[r] || 0, 10))) return "<" === a ? s < n : ">=" === a && s >= n;
 return ">=" === a;
}

function matchesRange$1(e, t) {
 var r, s = t.split(/ ?&& ?/);
 if (0 === s.length) return !1;
 for (r = 0; r < s.length; ++r) if (!specifierIncluded$1(e, s[r])) return !1;
 return !0;
}

function specifierIncluded(e) {
 var t, r, s, n = e.split(" "), o = n.length > 1 ? n[0] : "=", i = (n.length > 1 ? n[1] : n[0]).split(".");
 for (t = 0; t < 3; ++t) if ((r = parseInt(current[t] || 0, 10)) !== (s = parseInt(i[t] || 0, 10))) return "<" === o ? r < s : ">=" === o && r >= s;
 return ">=" === o;
}

function matchesRange(e) {
 var t, r = e.split(/ ?&& ?/);
 if (0 === r.length) return !1;
 for (t = 0; t < r.length; ++t) if (!specifierIncluded(r[t])) return !1;
 return !0;
}

function versionIncluded(e) {
 if ("boolean" == typeof e) return e;
 if (e && "object" == typeof e) {
  for (var t = 0; t < e.length; ++t) if (matchesRange(e[t])) return !0;
  return !1;
 }
 return matchesRange(e);
}

function mockConfig(e = {}) {
 const t = path__default.default.resolve("/");
 let {sys: r} = e;
 return r || (r = createTestingSystem()), r.getCurrentDirectory = () => t, {
  _isTesting: !0,
  buildAppCore: !1,
  buildDist: !0,
  buildEs5: !1,
  bundles: null,
  devMode: !0,
  enableCache: !1,
  extras: {},
  flags: createConfigFlags(),
  globalScript: null,
  hashFileNames: !1,
  logger: new TestingLogger,
  maxConcurrentWorkers: 0,
  minifyCss: !1,
  minifyJs: !1,
  namespace: "Testing",
  nodeResolve: {
   customResolveOptions: {}
  },
  outputTargets: null,
  rollupPlugins: {
   before: [],
   after: []
  },
  rootDir: t,
  sourceMap: !0,
  sys: r,
  testing: null,
  validateTypes: !1,
  ...e
 };
}

function mockCompilerCtx(e) {
 e || (e = mockConfig());
 const t = {
  version: 1,
  activeBuildId: 0,
  activeDirsAdded: [],
  activeDirsDeleted: [],
  activeFilesAdded: [],
  activeFilesDeleted: [],
  activeFilesUpdated: [],
  addWatchDir: noop,
  addWatchFile: noop,
  cachedGlobalStyle: null,
  changedFiles: new Set,
  changedModules: new Set,
  collections: [],
  compilerOptions: null,
  cache: null,
  cssModuleImports: new Map,
  events: buildEvents(),
  fs: null,
  hasSuccessfulBuild: !1,
  isActivelyBuilding: !1,
  lastBuildResults: null,
  moduleMap: new Map,
  nodeMap: new WeakMap,
  reset: noop,
  resolvedCollections: new Set,
  rollupCache: new Map,
  rollupCacheHydrate: null,
  rollupCacheLazy: null,
  rollupCacheNative: null,
  styleModeNames: new Set,
  worker: stencil_js.createWorkerContext(e.sys)
 };
 return Object.defineProperty(t, "fs", {
  get() {
   return null == this._fs && (this._fs = (e => {
    const t = new Map, r = new Map, s = async (e, r = {}) => {
     e = normalizePath(e);
     const s = [];
     if (!0 === r.inMemoryOnly) {
      let n = e;
      n.endsWith("/") || (n += "/");
      const i = e.split("/");
      t.forEach(((t, n) => {
       if (!n.startsWith(e)) return;
       const a = n.split("/");
       if ((a.length === i.length + 1 || r.recursive && a.length > i.length) && t.exists) {
        const e = {
         absPath: n,
         relPath: a[i.length],
         isDirectory: t.isDirectory,
         isFile: t.isFile
        };
        o(r, e) || s.push(e);
       }
      }));
     } else await n(e, e, r, s);
     return s.sort(((e, t) => e.absPath < t.absPath ? -1 : e.absPath > t.absPath ? 1 : 0));
    }, n = async (t, r, s, i) => {
     const a = await e.readDir(r);
     if (a.length > 0) {
      const e = v(r);
      e.exists = !0, e.isFile = !1, e.isDirectory = !0, await Promise.all(a.map((async e => {
       const r = normalizePath(e), a = normalizePath(path$2.relative(t, r)), c = await l(r), u = {
        absPath: r,
        relPath: a,
        isDirectory: c.isDirectory,
        isFile: c.isFile
       };
       o(s, u) || (i.push(u), !0 === s.recursive && !0 === c.isDirectory && await n(t, r, s, i));
      })));
     }
    }, o = (e, t) => {
     if (t.isDirectory) {
      if (Array.isArray(e.excludeDirNames)) {
       const r = path$2.basename(t.absPath);
       if (e.excludeDirNames.some((e => r === e))) return !0;
      }
     } else if (Array.isArray(e.excludeExtensions)) {
      const r = t.relPath.toLowerCase();
      if (e.excludeExtensions.some((e => r.endsWith(e)))) return !0;
     }
     return !1;
    }, i = async e => {
     const t = v(e);
     t.isFile = !1, t.isDirectory = !0, t.queueWriteToDisk || (t.queueDeleteFromDisk = !0);
     try {
      const t = await s(e, {
       recursive: !0
      });
      await Promise.all(t.map((e => e.relPath.endsWith(".gitkeep") ? null : a(e.absPath))));
     } catch (e) {}
    }, a = async e => {
     const t = v(e);
     t.queueWriteToDisk || (t.queueDeleteFromDisk = !0);
    }, l = async t => {
     const r = v(t);
     if ("boolean" != typeof r.isDirectory || "boolean" != typeof r.isFile) {
      const s = await e.stat(t);
      s.error ? r.exists = !1 : (r.exists = !0, s.isFile ? (r.isFile = !0, r.isDirectory = !1, 
      r.size = s.size) : s.isDirectory ? (r.isFile = !1, r.isDirectory = !0, r.size = s.size) : (r.isFile = !1, 
      r.isDirectory = !1, r.size = null));
     }
     return {
      exists: !!r.exists,
      isFile: !!r.isFile,
      isDirectory: !!r.isDirectory,
      size: "number" == typeof r.size ? r.size : 0
     };
    }, c = t => {
     const r = v(t);
     if ("boolean" != typeof r.isDirectory || "boolean" != typeof r.isFile) {
      const s = e.statSync(t);
      s.error ? r.exists = !1 : (r.exists = !0, s.isFile ? (r.isFile = !0, r.isDirectory = !1, 
      r.size = s.size) : s.isDirectory ? (r.isFile = !1, r.isDirectory = !0, r.size = s.size) : (r.isFile = !1, 
      r.isDirectory = !1, r.size = null));
     }
     return {
      exists: !!r.exists,
      isFile: !!r.isFile,
      isDirectory: !!r.isDirectory,
      size: r.size
     };
    }, u = async (t, s, n) => {
     if ("string" != typeof t) throw new Error(`writeFile, invalid filePath: ${t}`);
     if ("string" != typeof s) throw new Error(`writeFile, invalid content: ${t}`);
     const o = {
      ignored: !1,
      changedContent: !1,
      queuedWrite: !1
     };
     if (!0 === shouldIgnore(t)) return o.ignored = !0, o;
     const i = v(t);
     if (i.exists = !0, i.isFile = !0, i.isDirectory = !1, i.queueDeleteFromDisk = !1, 
     "string" == typeof i.fileText ? o.changedContent = i.fileText.replace(/\r/g, "") !== s.replace(/\r/g, "") : o.changedContent = !0, 
     i.fileText = s, o.queuedWrite = !1, null != n && ("string" == typeof n.outputTargetType && r.set(t, n.outputTargetType), 
     !1 === n.useCache && (i.useCache = !1)), null != n && !0 === n.inMemoryOnly) i.queueWriteToDisk ? o.queuedWrite = !0 : i.queueWriteToDisk = !1, 
     await d(t, !0); else if (null != n && !0 === n.immediateWrite) {
      if (o.changedContent || !0 !== n.useCache) {
       const r = await e.readFile(t);
       "string" == typeof r && (o.changedContent = i.fileText.replace(/\r/g, "") !== r.replace(/\r/g, "")), 
       o.changedContent && (await d(t, !1), await e.writeFile(t, i.fileText));
      }
     } else i.queueWriteToDisk || !0 !== o.changedContent || (i.queueWriteToDisk = !0, 
     o.queuedWrite = !0);
     return o;
    }, d = async (e, t) => {
     const r = [];
     for (;"string" == typeof (e = path$2.dirname(e)) && e.length > 0 && "/" !== e && !1 === e.endsWith(":/") && !1 === e.endsWith(":\\"); ) r.push(e);
     r.reverse(), await h(r, t);
    }, h = async (t, r) => {
     const s = [];
     for (const n of t) {
      const t = v(n);
      if (!0 !== t.exists || !0 !== t.isDirectory) try {
       t.exists = !0, t.isDirectory = !0, t.isFile = !1, r || await e.createDir(n), s.push(n);
      } catch (e) {}
     }
     return s;
    }, p = t => {
     const r = Promise.all(t.map((async t => {
      const [r, s] = t;
      return await e.copyFile(r, s), [ r, s ];
     })));
     return r;
    }, f = e => Promise.all(e.map((async e => {
     if ("string" != typeof e) throw new Error("unable to writeFile without filePath");
     return m(e);
    }))), m = async t => {
     const r = v(t);
     if (null == r.fileText) throw new Error(`unable to find item fileText to write: ${t}`);
     return await e.writeFile(t, r.fileText), !1 === r.useCache && _(t), t;
    }, g = async t => await Promise.all(t.map((async t => {
     if ("string" != typeof t) throw new Error("unable to unlink without filePath");
     return await e.removeFile(t), t;
    }))), y = async t => {
     const r = [];
     for (const s of t) await e.removeDir(s), r.push(s);
     return r;
    }, w = e => {
     e = normalizePath(e), t.forEach(((t, r) => {
      const s = path$2.relative(e, r).split("/")[0];
      s.startsWith(".") || s.startsWith("/") || _(r);
     }));
    }, _ = e => {
     e = normalizePath(e);
     const r = t.get(e);
     null == r || r.queueWriteToDisk || t.delete(e);
    }, v = e => {
     e = normalizePath(e);
     let r = t.get(e);
     return null != r || t.set(e, r = {
      exists: null,
      fileText: null,
      size: null,
      mtimeMs: null,
      isDirectory: null,
      isFile: null,
      queueCopyFileToDest: null,
      queueDeleteFromDisk: null,
      queueWriteToDisk: null,
      useCache: null
     }), r;
    }, b = 5242880;
    return {
     access: async e => {
      const t = v(e);
      return "boolean" != typeof t.exists ? (await l(e)).exists : t.exists;
     },
     accessSync: e => {
      const t = v(e);
      return "boolean" != typeof t.exists ? c(e).exists : t.exists;
     },
     cancelDeleteDirectoriesFromDisk: e => {
      for (const t of e) {
       const e = v(t);
       !0 === e.queueDeleteFromDisk && (e.queueDeleteFromDisk = !1);
      }
     },
     cancelDeleteFilesFromDisk: e => {
      for (const t of e) {
       const e = v(t);
       !0 === e.isFile && !0 === e.queueDeleteFromDisk && (e.queueDeleteFromDisk = !1);
      }
     },
     clearCache: () => {
      t.clear();
     },
     clearDirCache: w,
     clearFileCache: _,
     commit: async () => {
      const e = getCommitInstructions(t), r = await h(e.dirsToEnsure, !1), s = await f(e.filesToWrite), n = await p(e.filesToCopy), o = await g(e.filesToDelete), i = await y(e.dirsToDelete);
      return e.filesToDelete.forEach(_), e.dirsToDelete.forEach(w), {
       filesCopied: n,
       filesWritten: s,
       filesDeleted: o,
       dirsDeleted: i,
       dirsAdded: r
      };
     },
     copyFile: async (e, t) => {
      v(e).queueCopyFileToDest = t;
     },
     emptyDirs: async e => {
      e = e.filter(isString).map(normalizePath).reduce(((e, t) => (e.includes(t) || e.push(t), 
      e)), []);
      const t = await Promise.all(e.map((e => s(e, {
       recursive: !0
      })))), r = [];
      for (const e of t) for (const t of e) r.includes(t.absPath) || r.push(t.absPath);
      r.sort(((e, t) => {
       const r = e.split("/").length, s = t.split("/").length;
       return r < s ? 1 : r > s ? -1 : 0;
      })), await Promise.all(r.map(a)), e.forEach((e => {
       const t = v(e);
       t.isFile = !1, t.isDirectory = !0, t.queueWriteToDisk = !0, t.queueDeleteFromDisk = !1;
      }));
     },
     getBuildOutputs: () => {
      const e = [];
      return r.forEach(((t, r) => {
       const s = e.find((e => e.type === t));
       s ? s.files.push(r) : e.push({
        type: t,
        files: [ r ]
       });
      })), e.forEach((e => e.files.sort())), e.sort(((e, t) => e.type < t.type ? -1 : e.type > t.type ? 1 : 0));
     },
     getItem: v,
     getMemoryStats: () => `data length: ${t.size}`,
     readFile: async (t, r) => {
      if (null == r || !0 === r.useCache || void 0 === r.useCache) {
       const e = v(t);
       if (e.exists && "string" == typeof e.fileText) return e.fileText;
      }
      const s = await e.readFile(t), n = v(t);
      return "string" == typeof s ? s.length < b && (n.exists = !0, n.isFile = !0, n.isDirectory = !1, 
      n.fileText = s) : n.exists = !1, s;
     },
     readFileSync: (t, r) => {
      if (null == r || !0 === r.useCache || void 0 === r.useCache) {
       const e = v(t);
       if (e.exists && "string" == typeof e.fileText) return e.fileText;
      }
      const s = e.readFileSync(t), n = v(t);
      return "string" == typeof s ? s.length < b && (n.exists = !0, n.isFile = !0, n.isDirectory = !1, 
      n.fileText = s) : n.exists = !1, s;
     },
     readdir: s,
     remove: async e => {
      const t = await l(e);
      !0 === t.isDirectory ? await i(e) : !0 === t.isFile && await a(e);
     },
     stat: l,
     statSync: c,
     sys: e,
     writeFile: u,
     writeFiles: (e, t) => {
      const r = [];
      return isIterable(e) ? e.forEach(((e, s) => {
       r.push(u(s, e, t));
      })) : Object.keys(e).map((s => {
       r.push(u(s, e[s], t));
      })), Promise.all(r);
     }
    };
   })(e.sys)), this._fs;
  }
 }), Object.defineProperty(t, "cache", {
  get() {
   return null == this._cache && (this._cache = function r(e, t) {
    e || (e = mockConfig()), t || (t = mockCompilerCtx(e)), e.enableCache = !0;
    const r = new Cache(e, t.fs);
    return r.initCacheDir(), r;
   }(e, t)), this._cache;
  }
 }), t;
}

function mockLogger() {
 return new TestingLogger;
}

async function initPageEvents(e) {
 e._e2eEvents = new Map, e._e2eEventIds = 0, e.spyOnEvent = pageSpyOnEvent.bind(e, e), 
 await e.exposeFunction("stencilOnEvent", ((t, r) => {
  !function s(e, t, r) {
   const s = e.get(t);
   s && s.callback(r);
  }(e._e2eEvents, t, r);
 })), await e.evaluateOnNewDocument(browserContextEvents);
}

async function pageSpyOnEvent(e, t, r) {
 const s = new EventSpy(t), n = "document" !== r ? () => window : () => document, o = await e.evaluateHandle(n);
 return await addE2EListener(e, o, t, (e => {
  s.push(e);
 })), s;
}

async function waitForEvent(e, t, r) {
 const s = .5 * jasmine.DEFAULT_TIMEOUT_INTERVAL, n = await e.evaluate(((e, t, r) => new Promise(((s, n) => {
  const o = setTimeout((() => {
   n(new Error(`waitForEvent() timeout, eventName: ${t}`));
  }), r);
  e.addEventListener(t, (e => {
   clearTimeout(o), s(window.stencilSerializeEvent(e));
  }), {
   once: !0
  });
 }))), r, t, s);
 return await e.waitForChanges(), n;
}

async function addE2EListener(e, t, r, s) {
 const n = e._e2eEventIds++;
 e._e2eEvents.set(n, {
  eventName: r,
  callback: s
 });
 const o = t.executionContext();
 await o.evaluate(((e, t, r) => {
  e.addEventListener(r, (e => {
   window.stencilOnEvent(t, window.stencilSerializeEvent(e));
  }));
 }), t, n, r);
}

function browserContextEvents() {
 const e = () => {
  const e = [], t = (e, r) => {
   if (null != r && 1 === r.nodeType) for (let s = 0; s < r.children.length; s++) {
    const n = r.children[s];
    n.tagName.includes("-") && "function" == typeof n.componentOnReady && e.push(n.componentOnReady()), 
    t(e, n);
   }
  };
  return t(e, window.document.documentElement), Promise.all(e).catch((e => console.error(e)));
 }, t = () => e().then((() => new Promise((e => {
  requestAnimationFrame(e);
 })))).then((() => e())).then((() => {
  window.stencilAppLoaded = !0;
 }));
 window.stencilSerializeEventTarget = e => e ? e === window ? {
  serializedWindow: !0
 } : e === document ? {
  serializedDocument: !0
 } : null != e.nodeType ? {
  serializedElement: !0,
  nodeName: e.nodeName,
  nodeValue: e.nodeValue,
  nodeType: e.nodeType,
  tagName: e.tagName,
  className: e.className,
  id: e.id
 } : null : null, window.stencilSerializeEvent = e => ({
  bubbles: e.bubbles,
  cancelBubble: e.cancelBubble,
  cancelable: e.cancelable,
  composed: e.composed,
  currentTarget: window.stencilSerializeEventTarget(e.currentTarget),
  defaultPrevented: e.defaultPrevented,
  detail: e.detail,
  eventPhase: e.eventPhase,
  isTrusted: e.isTrusted,
  returnValue: e.returnValue,
  srcElement: window.stencilSerializeEventTarget(e.srcElement),
  target: window.stencilSerializeEventTarget(e.target),
  timeStamp: e.timeStamp,
  type: e.type,
  isSerializedEvent: !0
 }), "complete" === window.document.readyState ? t() : document.addEventListener("readystatechange", (function(e) {
  "complete" == e.target.readyState && t();
 }));
}

async function find(e, t, r) {
 const {lightSelector: s, shadowSelector: n, text: o, contains: i} = getSelector(r);
 let a;
 if (a = "string" == typeof s ? await async function l(e, t, r, s) {
  let n = await t.$(r);
  if (!n) return null;
  if (s) {
   const t = await e.evaluateHandle(((e, t) => {
    if (!e.shadowRoot) throw new Error(`shadow root does not exist for element: ${e.tagName.toLowerCase()}`);
    return e.shadowRoot.querySelector(t);
   }), n, s);
   if (await n.dispose(), !t) return null;
   n = t.asElement();
  }
  return n;
 }(e, t, s, n) : await async function c(e, t, r, s) {
  const n = await e.evaluateHandle(((e, t, r) => {
   let s = null;
   return function e(n) {
    if (n && !s) if (3 === n.nodeType) {
     if ("string" == typeof t && n.textContent.trim() === t) return void (s = n.parentElement);
     if ("string" == typeof r && n.textContent.includes(r)) return void (s = n.parentElement);
    } else {
     if ("SCRIPT" === n.nodeName || "STYLE" === n.nodeName) return;
     if (e(n.shadowRoot), n.childNodes) for (let t = 0; t < n.childNodes.length; t++) e(n.childNodes[t]);
    }
   }(e), s;
  }), t, r, s);
  return n ? n.asElement() : null;
 }(e, t, o, i), !a) return null;
 const u = new E2EElement(e, a);
 return await u.e2eSync(), u;
}

async function findAll(e, t, r) {
 const s = [], {lightSelector: n, shadowSelector: o} = getSelector(r), i = await t.$$(n);
 if (0 === i.length) return s;
 if (o) for (let t = 0; t < i.length; t++) {
  const r = i[t].executionContext(), n = await r.evaluateHandle(((e, t) => {
   if (!e.shadowRoot) throw new Error(`shadow root does not exist for element: ${e.tagName.toLowerCase()}`);
   return e.shadowRoot.querySelectorAll(t);
  }), i[t], o);
  await i[t].dispose();
  const a = await n.getProperties();
  await n.dispose();
  for (const t of a.values()) {
   const r = t.asElement();
   if (r) {
    const t = new E2EElement(e, r);
    await t.e2eSync(), s.push(t);
   }
  }
 } else for (let t = 0; t < i.length; t++) {
  const r = new E2EElement(e, i[t]);
  await r.e2eSync(), s.push(r);
 }
 return s;
}

function getSelector(e) {
 const t = {
  lightSelector: null,
  shadowSelector: null,
  text: null,
  contains: null
 };
 if ("string" == typeof e) {
  const r = e.split(">>>");
  t.lightSelector = r[0].trim(), t.shadowSelector = r.length > 1 ? r[1].trim() : null;
 } else if ("string" == typeof e.text) t.text = e.text.trim(); else {
  if ("string" != typeof e.contains) throw new Error(`invalid find selector: ${e}`);
  t.contains = e.contains.trim();
 }
 return t;
}

async function writeScreenshotData(e, t) {
 const r = function s(e, t) {
  const r = `${t}.json`;
  return path__default.default.join(e, r);
 }(e, t.id), n = JSON.stringify(t, null, 2);
 await writeFile(r, n);
}

function writeFile(e, t) {
 return new Promise(((r, s) => {
  fs__default.default.writeFile(e, t, (e => {
   e ? s(e) : r();
  }));
 }));
}

async function compareScreenshot(e, t, r, s, n, o, i, a) {
 const l = `${crypto$3.createHash("md5").update(r).digest("hex")}.png`, c = path$2.join(t.imagesDir, l);
 await async function u(e, t) {
  const r = await function s(e) {
   return new Promise((t => {
    fs__default.default.access(e, (e => t(!e)));
   }));
  }(e);
  r || await writeFile(e, t);
 }(c, r), r = null, i && (i = normalizePath(path$2.relative(t.rootDir, i)));
 const d = function h(e, t) {
  if ("string" != typeof t || 0 === t.trim().length) throw new Error("invalid test description");
  const r = crypto$3.createHash("md5");
  return r.update(t + ":"), r.update(e.userAgent + ":"), r.update(e.viewport.width + ":"), 
  r.update(e.viewport.height + ":"), r.update(e.viewport.deviceScaleFactor + ":"), 
  r.update(e.viewport.hasTouch + ":"), r.update(e.viewport.isMobile + ":"), r.digest("hex").slice(0, 8).toLowerCase();
 }(e, s), p = {
  id: d,
  image: l,
  device: e.device,
  userAgent: e.userAgent,
  desc: s,
  testPath: i,
  width: n,
  height: o,
  deviceScaleFactor: e.viewport.deviceScaleFactor,
  hasTouch: e.viewport.hasTouch,
  isLandscape: e.viewport.isLandscape,
  isMobile: e.viewport.isMobile,
  diff: {
   id: d,
   desc: s,
   imageA: l,
   imageB: l,
   mismatchedPixels: 0,
   device: e.device,
   userAgent: e.userAgent,
   width: n,
   height: o,
   deviceScaleFactor: e.viewport.deviceScaleFactor,
   hasTouch: e.viewport.hasTouch,
   isLandscape: e.viewport.isLandscape,
   isMobile: e.viewport.isMobile,
   allowableMismatchedPixels: t.allowableMismatchedPixels,
   allowableMismatchedRatio: t.allowableMismatchedRatio,
   testPath: i
  }
 };
 if (t.updateMaster) return await writeScreenshotData(t.currentBuildDir, p), p.diff;
 const f = t.masterScreenshots[p.id];
 if (!f) return await writeScreenshotData(t.currentBuildDir, p), p.diff;
 if (p.diff.imageA = f, p.diff.imageA !== p.diff.imageB) {
  p.diff.cacheKey = function m(e, t, r) {
   const s = crypto$3.createHash("md5");
   return s.update(`${e}:${t}:${r}`), s.digest("hex").slice(0, 10);
  }(p.diff.imageA, p.diff.imageB, a);
  const r = t.cache[p.diff.cacheKey];
  if ("number" != typeof r || isNaN(r)) {
   const r = Math.round(e.viewport.width * e.viewport.deviceScaleFactor), s = Math.round(e.viewport.height * e.viewport.deviceScaleFactor), n = {
    imageAPath: path$2.join(t.imagesDir, p.diff.imageA),
    imageBPath: path$2.join(t.imagesDir, p.diff.imageB),
    width: r,
    height: s,
    pixelmatchThreshold: a
   };
   p.diff.mismatchedPixels = await async function g(e, t) {
    return new Promise(((r, s) => {
     const n = .5 * jasmine.DEFAULT_TIMEOUT_INTERVAL, o = setTimeout((() => {
      s(`getMismatchedPixels timeout: ${n}ms`);
     }), n);
     try {
      const n = {
       execArgv: process.execArgv.filter((e => !/^--(debug|inspect)/.test(e))),
       env: process.env,
       cwd: process.cwd(),
       stdio: [ "pipe", "pipe", "pipe", "ipc" ]
      }, i = child_process$2.fork(e, [], n);
      i.on("message", (e => {
       i.kill(), clearTimeout(o), r(e);
      })), i.on("error", (e => {
       clearTimeout(o), s(e);
      })), i.send(t);
     } catch (e) {
      clearTimeout(o), s(`getMismatchedPixels error: ${e}`);
     }
    }));
   }(t.pixelmatchModulePath, n);
  } else p.diff.mismatchedPixels = r;
 }
 return await writeScreenshotData(t.currentBuildDir, p), p.diff;
}

async function e2eGoTo(e, t, r = {}) {
 if (e.isClosed()) throw new Error("e2eGoTo unavailable: page already closed");
 if ("string" != typeof t) throw new Error("invalid gotoTest() url");
 if (!t.startsWith("/")) throw new Error("gotoTest() url must start with /");
 const s = env.__STENCIL_BROWSER_URL__;
 if ("string" != typeof s) throw new Error("invalid gotoTest() browser url");
 const n = s + t.substring(1);
 r.waitUntil || (r.waitUntil = env.__STENCIL_BROWSER_WAIT_UNTIL);
 const o = await e._e2eGoto(n, r);
 if (!o.ok()) throw new Error(`Testing unable to load ${t}, HTTP status: ${o.status()}`);
 return await waitForStencil(e, r), o;
}

async function e2eSetContent(e, t, r = {}) {
 if (e.isClosed()) throw new Error("e2eSetContent unavailable: page already closed");
 if ("string" != typeof t) throw new Error("invalid e2eSetContent() html");
 const s = [], n = env.__STENCIL_APP_SCRIPT_URL__;
 if ("string" != typeof n) throw new Error("invalid e2eSetContent() app script url");
 s.push("<!doctype html>"), s.push("<html>"), s.push("<head>");
 const o = env.__STENCIL_APP_STYLE_URL__;
 "string" == typeof o && s.push(`<link rel="stylesheet" href="${o}">`), s.push(`<script type="module" src="${n}"><\/script>`), 
 s.push("</head>"), s.push("<body>"), s.push(t), s.push("</body>"), s.push("</html>");
 const i = env.__STENCIL_BROWSER_URL__;
 await e.setRequestInterception(!0), e.on("request", (e => {
  i === e.url() ? e.respond({
   status: 200,
   contentType: "text/html",
   body: s.join("\n")
  }) : e.continue();
 })), r.waitUntil || (r.waitUntil = env.__STENCIL_BROWSER_WAIT_UNTIL);
 const a = await e._e2eGoto(i, r);
 if (!a.ok()) throw new Error("Testing unable to load content");
 return await waitForStencil(e, r), a;
}

async function waitForStencil(e, t) {
 try {
  const r = "number" == typeof t.timeout ? t.timeout : 4750;
  await e.waitForFunction("window.stencilAppLoaded", {
   timeout: r
  });
 } catch (e) {
  throw new Error("App did not load in allowed time. Please ensure the content loads a stencil application.");
 }
}

async function waitForChanges(e) {
 try {
  if (e.isClosed()) return;
  if (await Promise.all(e._e2eElements.map((e => e.e2eRunActions()))), e.isClosed()) return;
  if (await e.evaluate((() => new Promise((e => {
   requestAnimationFrame((() => {
    const t = [], r = (e, t) => {
     if (null != e) {
      "shadowRoot" in e && e.shadowRoot instanceof ShadowRoot && r(e.shadowRoot, t);
      const s = e.children, n = s.length;
      for (let e = 0; e < n; e++) {
       const n = s[e];
       null != n && (n.tagName.includes("-") && "function" == typeof n.componentOnReady && t.push(n.componentOnReady()), 
       r(n, t));
      }
     }
    };
    r(document.documentElement, t), Promise.all(t).then((() => {
     e();
    })).catch((() => {
     e();
    }));
   }));
  })))), e.isClosed()) return;
  "function" == typeof e.waitForTimeout ? await e.waitForTimeout(100) : await e.waitFor(100), 
  await Promise.all(e._e2eElements.map((e => e.e2eSync())));
 } catch (e) {}
}

function serializeConsoleMessage(e) {
 return `${e.text()} ${function t(e) {
  let t = "";
  return e && e.url && (t = `\nLocation: ${e.url}`, e.lineNumber && (t += `:${e.lineNumber}`), 
  e.columnNumber && (t += `:${e.columnNumber}`)), t;
 }(e.location())}`;
}

function findRootComponent(e, t) {
 if (null != t) {
  const r = t.children, s = r.length;
  for (let t = 0; t < s; t++) {
   const s = r[t];
   if (e.has(s.nodeName.toLowerCase())) return s;
  }
  for (let t = 0; t < s; t++) {
   const s = findRootComponent(e, r[t]);
   if (null != s) return s;
  }
 }
 return null;
}

function createBuildId() {
 const e = new Date;
 let t = e.getFullYear() + "";
 return t += ("0" + (e.getMonth() + 1)).slice(-2), t += ("0" + e.getDate()).slice(-2), 
 t += ("0" + e.getHours()).slice(-2), t += ("0" + e.getMinutes()).slice(-2), t += ("0" + e.getSeconds()).slice(-2), 
 t;
}

function createBuildMessage() {
 const e = new Date;
 let t = e.getFullYear() + "-";
 return t += ("0" + (e.getMonth() + 1)).slice(-2) + "-", t += ("0" + e.getDate()).slice(-2) + " ", 
 t += ("0" + e.getHours()).slice(-2) + ":", t += ("0" + e.getMinutes()).slice(-2) + ":", 
 t += ("0" + e.getSeconds()).slice(-2), `Build: ${t}`;
}

function getAppStyleUrl(e, t) {
 return e.globalStyle ? getAppUrl(e, t, `${e.fsNamespace}.css`) : null;
}

function getAppUrl(e, t, r) {
 const s = e.outputTargets.find(isOutputTargetWww);
 if (s) {
  const e = s.buildDir, n = path$2.join(e, r), o = path$2.relative(s.dir, n);
  return new URL(o, t).href;
 }
 const n = e.outputTargets.find(isOutputTargetDistLazy);
 if (n) {
  const s = n.esmDir, o = path$2.join(s, r), i = path$2.relative(e.rootDir, o);
  return new URL(i, t).href;
 }
 return t;
}

var posix, pathBrowserify, caller, pathParse, parse, getNodeModulesDirs, nodeModulesPaths, normalizeOptions, ERROR_MESSAGE, slice, toStr, implementation, functionBind, src, isCoreModule, realpathFS$1, defaultIsFile$1, defaultIsDir$1, defaultRealpath, maybeRealpath, defaultReadPackage, getPackageCandidates$1, async, current, core, mod, core_1, isCore, realpathFS, defaultIsFile, defaultIsDir, defaultRealpathSync, maybeRealpathSync, defaultReadPackageSync, getPackageCandidates, sync, resolve;

const stencil_js = require("../compiler/stencil.js"), appData = _lazyRequire("@stencil/core/internal/app-data"), testing = _lazyRequire("@stencil/core/internal/testing"), index_cjs = _lazyRequire("../mock-doc/index.cjs"), path$2 = require("path"), crypto$3 = require("crypto"), os$2 = require("os"), process$3 = require("process"), fs$2 = require("fs"), index_js = _lazyRequire("../dev-server/index.js"), child_process$2 = require("child_process"), path__default = _interopDefaultLegacy(path$2), os__namespace = _interopNamespace(os$2), process__namespace = _interopNamespace(process$3), fs__default = _interopDefaultLegacy(fs$2), formatComponentRuntimeMembers = (e, t = !0) => ({
 ...formatPropertiesRuntimeMember(e.properties),
 ...formatStatesRuntimeMember(e.states),
 ...t ? formatMethodsRuntimeMember(e.methods) : {}
}), formatPropertiesRuntimeMember = e => {
 const t = {};
 return e.forEach((e => {
  t[e.name] = trimFalsy([ formatFlags(e), formatAttrName(e) ]);
 })), t;
}, formatFlags = e => {
 let t = formatPropType(e.type);
 return e.mutable && (t |= 1024), e.reflect && (t |= 512), t;
}, formatAttrName = e => {
 if ("string" == typeof e.attribute) {
  if (e.name === e.attribute) return;
  return e.attribute;
 }
}, formatPropType = e => "string" === e ? 1 : "number" === e ? 2 : "boolean" === e ? 4 : "any" === e ? 8 : 16, formatStatesRuntimeMember = e => {
 const t = {};
 return e.forEach((e => {
  t[e.name] = [ 32 ];
 })), t;
}, formatMethodsRuntimeMember = e => {
 const t = {};
 return e.forEach((e => {
  t[e.name] = [ 64 ];
 })), t;
}, formatHostListeners = e => e.listeners.map((e => [ computeListenerFlags(e), e.name, e.method ])), computeListenerFlags = e => {
 let t = 0;
 switch (e.capture && (t |= 2), e.passive && (t |= 1), e.target) {
 case "document":
  t |= 4;
  break;

 case "window":
  t |= 8;
  break;

 case "body":
  t |= 16;
  break;

 case "parent":
  t |= 32;
 }
 return t;
}, trimFalsy = e => {
 const t = e;
 for (let e = t.length - 1; e >= 0 && !t[e]; e--) t.pop();
 return t;
}, noop = () => {}, isFunction = e => "function" == typeof e, isString = e => "string" == typeof e, isIterable = e => (e => null != e)(e) && isFunction(e[Symbol.iterator]), windowsPathRegex = /^(?:[a-zA-Z]:|[\\/]{2}[^\\/]+[\\/]+[^\\/]+)?[\\/]$/, hasError = e => null != e && 0 !== e.length && e.some((e => "error" === e.level && "runtime" !== e.type)), normalizePath = e => {
 if ("string" != typeof e) throw new Error("invalid path to normalize");
 e = normalizeSlashes(e.trim());
 const t = pathComponents(e, getRootLength(e)), r = reducePathComponents(t), s = r[0], n = r[1], o = s + r.slice(1).join("/");
 return "" === o ? "." : "" === s && n && e.includes("/") && !n.startsWith(".") && !n.startsWith("@") ? "./" + o : o;
}, normalizeSlashes = e => e.replace(backslashRegExp, "/"), backslashRegExp = /\\/g, reducePathComponents = e => {
 if (!Array.isArray(e) || 0 === e.length) return [];
 const t = [ e[0] ];
 for (let r = 1; r < e.length; r++) {
  const s = e[r];
  if (s && "." !== s) {
   if (".." === s) if (t.length > 1) {
    if (".." !== t[t.length - 1]) {
     t.pop();
     continue;
    }
   } else if (t[0]) continue;
   t.push(s);
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
  const t = r + "://".length, s = e.indexOf("/", t);
  if (-1 !== s) {
   const n = e.slice(0, r), o = e.slice(t, s);
   if ("file" === n && ("" === o || "localhost" === o) && isVolumeCharacter(e.charCodeAt(s + 1))) {
    const t = getFileUrlVolumeSeparatorEnd(e, s + 2);
    if (-1 !== t) {
     if (47 === e.charCodeAt(t)) return ~(t + 1);
     if (t === e.length) return ~t;
    }
   }
   return ~(s + 1);
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
 const r = e.substring(0, t), s = e.substring(t).split("/"), n = s.length;
 return n > 0 && !s[n - 1] && s.pop(), [ r, ...s ];
}, normalizeFsPath = e => normalizePath(e.split("?")[0].replace(/\0/g, "")), flattenDiagnosticMessageText = (e, t) => {
 var r, s;
 if ("string" == typeof t) return t;
 if (void 0 === t) return "";
 const n = [], o = (null !== (s = null === (r = e.file) || void 0 === r ? void 0 : r.fileName) && void 0 !== s ? s : "").includes("stencil.config");
 o && n.push(2322);
 let i = "";
 if (!n.includes(t.code) && (i = t.messageText, isIterable(t.next))) for (const r of t.next) i += flattenDiagnosticMessageText(e, r);
 return o && (i = i.replace("type 'StencilConfig'", "Stencil Config"), i = i.replace("Object literal may only specify known properties, but ", ""), 
 i = i.replace("Object literal may only specify known properties, and ", "")), i.trim();
}, isJest27TransformOptions = e => null != e && "object" == typeof e && e.hasOwnProperty("config");

let _tsCompilerOptions = null, _tsCompilerOptionsKey = null;

const jestPreprocessor = {
 process(e, t, r, s) {
  if (isJest27TransformOptions(r) && (s = r.config), !s) throw "Unable to find Jest transformation options.";
  if (function n(e, t) {
   var r;
   const s = (null !== (r = e.split(".").pop()) && void 0 !== r ? r : "").toLowerCase().split("?")[0];
   if ("ts" === s || "tsx" === s || "jsx" === s) return !0;
   if ("mjs" === s) return !0;
   if ("js" === s) {
    if (t.includes("import ") || t.includes("import.") || t.includes("import(")) return !0;
    if (t.includes("export ")) return !0;
   }
   return "css" === s;
  }(t, e)) {
   const r = {
    file: t,
    currentDirectory: s.rootDir
   }, n = getCompilerOptions(s.rootDir);
   n && (n.baseUrl && (r.baseUrl = n.baseUrl), n.paths && (r.paths = n.paths));
   const o = transpile(e, r), i = o.diagnostics.some((e => "error" === e.level));
   if (o.diagnostics && i) {
    const e = o.diagnostics.map(formatDiagnostic).join("\n\n");
    throw new Error(e);
   }
   return o.code;
  }
  return e;
 },
 getCacheKey(e, t, r, s) {
  if (isJest27TransformOptions(r) && (s = r.config), !s) throw "Unable to find Jest transformation options.";
  if (!_tsCompilerOptionsKey) {
   const e = getCompilerOptions(s.rootDir);
   _tsCompilerOptionsKey = JSON.stringify(e);
  }
  return [ process.version, _tsCompilerOptionsKey, e, t, r, !!s.instrument, 7 ].join(":");
 }
}, deepEqual = function e(t, r) {
 if (t === r) return !0;
 if (t && r && "object" == typeof t && "object" == typeof r) {
  const s = Array.isArray(t), n = Array.isArray(r);
  let o, i, a;
  if (s && n) {
   if (i = t.length, i != r.length) return !1;
   for (o = i; 0 != o--; ) if (!e(t[o], r[o])) return !1;
   return !0;
  }
  if (s != n) return !1;
  const l = t instanceof Date, c = r instanceof Date;
  if (l != c) return !1;
  if (l && c) return t.getTime() == r.getTime();
  const u = t instanceof RegExp, d = r instanceof RegExp;
  if (u != d) return !1;
  if (u && d) return t.toString() == r.toString();
  const h = Object.keys(t);
  if (i = h.length, i !== Object.keys(r).length) return !1;
  for (o = i; 0 != o--; ) if (!Object.prototype.hasOwnProperty.call(r, h[o])) return !1;
  for (o = i; 0 != o--; ) if (a = h[o], !e(t[a], r[a])) return !1;
  return !0;
 }
 return t != t && r != r;
}, expectExtend = {
 toEqualAttribute: function toEqualAttribute(e, t, r) {
  if (!e) throw new Error("expect toMatchAttribute value is null");
  if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
  if (1 !== e.nodeType) throw new Error("expect toMatchAttribute value is not an element");
  let s = e.getAttribute(t);
  null != r && (r = String(r)), null != s && (s = String(s));
  const n = r === s;
  return {
   message: () => `expected attribute ${t} "${r}" to ${n ? "not " : ""}equal "${s}"`,
   pass: n
  };
 },
 toEqualAttributes: function toEqualAttributes(e, t) {
  if (!e) throw new Error("expect toEqualAttributes value is null");
  if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
  if (1 !== e.nodeType) throw new Error("expect toEqualAttributes value is not an element");
  const r = Object.keys(t), s = r.every((r => {
   let s = t[r];
   return null != s && (s = String(s)), e.getAttribute(r) === s;
  }));
  return {
   message: () => `expected attributes to ${s ? "not " : ""}equal ${r.map((e => `[${e}="${t[e]}"]`)).join(", ")}`,
   pass: s
  };
 },
 toEqualHtml: function toEqualHtml(e, t) {
  return compareHtml(e, t, !0);
 },
 toEqualLightHtml: function toEqualLightHtml(e, t) {
  return compareHtml(e, t, !1);
 },
 toEqualText: function toEqualText(e, t) {
  if (null == e) throw new Error(`expect toEqualText() value is "${e}"`);
  if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
  let r;
  1 === e.nodeType ? r = e.textContent.replace(/\s\s+/g, " ").trim() : null != e && (r = String(e).replace(/\s\s+/g, " ").trim()), 
  "string" == typeof t && (t = t.replace(/\s\s+/g, " ").trim());
  const s = r === t;
  return {
   message: () => `expected textContent "${t}" to ${s ? "not " : ""}equal "${r}"`,
   pass: s
  };
 },
 toHaveAttribute: function toHaveAttribute(e, t) {
  if (!e) throw new Error("expect toHaveAttribute value is null");
  if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
  if (1 !== e.nodeType) throw new Error("expect toHaveAttribute value is not an element");
  const r = e.hasAttribute(t);
  return {
   message: () => `expected to ${r ? "not " : ""}have the attribute "${t}"`,
   pass: r
  };
 },
 toHaveClass: function toHaveClass(e, t) {
  if (!e) throw new Error("expect toHaveClass value is null");
  if ("function" == typeof e.then) throw new Error("element must be a resolved value, not a promise, before it can be tested");
  if (1 !== e.nodeType) throw new Error("expect toHaveClass value is not an element");
  const r = e.classList.contains(t);
  return {
   message: () => `expected to ${r ? "not " : ""}have css class "${t}"`,
   pass: r
  };
 },
 toHaveClasses,
 toMatchClasses: function toMatchClasses(e, t) {
  let {pass: r} = toHaveClasses(e, t);
  return r && (r = t.length === e.classList.length), {
   message: () => `expected to ${r ? "not " : ""}match css classes "${t.join(" ")}", but className is "${e.className}"`,
   pass: r
  };
 },
 toHaveReceivedEvent: function toHaveReceivedEvent(e) {
  if (!e) throw new Error("toHaveReceivedEvent event spy is null");
  if ("function" == typeof e.then) throw new Error("event spy must be a resolved value, not a promise, before it can be tested");
  if (!e.eventName) throw new Error("toHaveReceivedEvent did not receive an event spy");
  const t = e.events.length > 0;
  return {
   message: () => `expected to have ${t ? "not " : ""}called "${e.eventName}" event`,
   pass: t
  };
 },
 toHaveReceivedEventDetail: function toHaveReceivedEventDetail(e, t) {
  if (!e) throw new Error("toHaveReceivedEventDetail event spy is null");
  if ("function" == typeof e.then) throw new Error("event spy must be a resolved value, not a promise, before it can be tested");
  if (!e.eventName) throw new Error("toHaveReceivedEventDetail did not receive an event spy");
  if (!e.lastEvent) throw new Error(`event "${e.eventName}" was not received`);
  const r = deepEqual(e.lastEvent.detail, t);
  return expect(e.lastEvent.detail).toEqual(t), {
   message: () => `expected event "${e.eventName}" detail to ${r ? "not " : ""}equal`,
   pass: r
  };
 },
 toHaveReceivedEventTimes: function toHaveReceivedEventTimes(e, t) {
  if (!e) throw new Error("toHaveReceivedEventTimes event spy is null");
  if ("function" == typeof e.then) throw new Error("event spy must be a resolved value, not a promise, before it can be tested");
  if (!e.eventName) throw new Error("toHaveReceivedEventTimes did not receive an event spy");
  return {
   message: () => `expected event "${e.eventName}" to have been called ${t} times, but was called ${e.events.length} time${e.events.length > 1 ? "s" : ""}`,
   pass: e.length === t
  };
 },
 toHaveFirstReceivedEventDetail: function toHaveFirstReceivedEventDetail(e, t) {
  if (!e) throw new Error("toHaveFirstReceivedEventDetail event spy is null");
  if ("function" == typeof e.then) throw new Error("event spy must be a resolved value, not a promise, before it can be tested");
  if (!e.eventName) throw new Error("toHaveFirstReceivedEventDetail did not receive an event spy");
  if (!e.firstEvent) throw new Error(`event "${e.eventName}" was not received`);
  const r = deepEqual(e.firstEvent.detail, t);
  return expect(e.lastEvent.detail).toEqual(t), {
   message: () => `expected event "${e.eventName}" detail to ${r ? "not " : ""}equal`,
   pass: r
  };
 },
 toHaveNthReceivedEventDetail: function toHaveNthReceivedEventDetail(e, t, r) {
  if (!e) throw new Error("toHaveNthReceivedEventDetail event spy is null");
  if ("function" == typeof e.then) throw new Error("event spy must be a resolved value, not a promise, before it can be tested");
  if (!e.eventName) throw new Error("toHaveNthReceivedEventDetail did not receive an event spy");
  if (!e.firstEvent) throw new Error(`event "${e.eventName}" was not received`);
  const s = e.events[t];
  if (!s) throw new Error(`event at index ${t} was not received`);
  const n = deepEqual(s.detail, r);
  return expect(s.detail).toEqual(r), {
   message: () => `expected event "${e.eventName}" detail to ${n ? "not " : ""}equal`,
   pass: n
  };
 },
 toMatchScreenshot: function toMatchScreenshot(e, t = {}) {
  if (!e) throw new Error("expect toMatchScreenshot value is null");
  if ("function" == typeof e.then) throw new Error("expect(compare).toMatchScreenshot() must be a resolved value, not a promise, before it can be tested");
  if ("number" != typeof e.mismatchedPixels) throw new Error("expect toMatchScreenshot() value is not a screenshot compare");
  const r = e.device || e.userAgent;
  if ("number" == typeof t.allowableMismatchedRatio) {
   if (t.allowableMismatchedRatio < 0 || t.allowableMismatchedRatio > 1) throw new Error("expect toMatchScreenshot() allowableMismatchedRatio must be a value ranging from 0 to 1");
   const s = e.mismatchedPixels / (e.width * e.deviceScaleFactor * (e.height * e.deviceScaleFactor));
   return {
    message: () => `${r}: screenshot has a mismatch ratio of "${s}" for "${e.desc}", but expected ratio to be less than "${t.allowableMismatchedRatio}"`,
    pass: s <= t.allowableMismatchedRatio
   };
  }
  if ("number" == typeof t.allowableMismatchedPixels) {
   if (t.allowableMismatchedPixels < 0) throw new Error("expect toMatchScreenshot() allowableMismatchedPixels value must be a value that is 0 or greater");
   return {
    message: () => `${r}: screenshot has "${e.mismatchedPixels}" mismatched pixels for "${e.desc}", but expected less than "${t.allowableMismatchedPixels}" mismatched pixels`,
    pass: e.mismatchedPixels <= t.allowableMismatchedPixels
   };
  }
  if ("number" == typeof e.allowableMismatchedRatio) {
   const t = e.mismatchedPixels / (e.width * e.deviceScaleFactor * (e.height * e.deviceScaleFactor));
   return {
    message: () => `${r}: screenshot has a mismatch ratio of "${t}" for "${e.desc}", but expected ratio to be less than "${e.allowableMismatchedRatio}"`,
    pass: t <= e.allowableMismatchedRatio
   };
  }
  if ("number" == typeof e.allowableMismatchedPixels) return {
   message: () => `${r}: screenshot has "${e.mismatchedPixels}" mismatched pixels for "${e.desc}", but expected less than "${e.allowableMismatchedPixels}" mismatched pixels`,
   pass: e.mismatchedPixels <= e.allowableMismatchedPixels
  };
  throw new Error("expect toMatchScreenshot() missing allowableMismatchedPixels in testing config");
 }
};

class MockHeaders {
 constructor(e) {
  if (this._values = [], "object" == typeof e) if ("function" == typeof e[Symbol.iterator]) {
   const t = [];
   for (const r of e) "function" == typeof r[Symbol.iterator] && t.push([ ...r ]);
   for (const e of t) this.append(e[0], e[1]);
  } else for (const t in e) this.append(t, e[t]);
 }
 append(e, t) {
  this._values.push([ e, t + "" ]);
 }
 delete(e) {
  e = e.toLowerCase();
  for (let t = this._values.length - 1; t >= 0; t--) this._values[t][0].toLowerCase() === e && this._values.splice(t, 1);
 }
 entries() {
  const e = [];
  for (const t of this.keys()) e.push([ t, this.get(t) ]);
  let t = -1;
  return {
   next: () => (t++, {
    value: e[t],
    done: !e[t]
   }),
   [Symbol.iterator]() {
    return this;
   }
  };
 }
 forEach(e) {
  for (const t of this.entries()) e(t[1], t[0]);
 }
 get(e) {
  const t = [];
  e = e.toLowerCase();
  for (const r of this._values) r[0].toLowerCase() === e && t.push(r[1]);
  return t.length > 0 ? t.join(", ") : null;
 }
 has(e) {
  e = e.toLowerCase();
  for (const t of this._values) if (t[0].toLowerCase() === e) return !0;
  return !1;
 }
 keys() {
  const e = [];
  for (const t of this._values) {
   const r = t[0].toLowerCase();
   e.includes(r) || e.push(r);
  }
  let t = -1;
  return {
   next: () => (t++, {
    value: e[t],
    done: !e[t]
   }),
   [Symbol.iterator]() {
    return this;
   }
  };
 }
 set(e, t) {
  for (const r of this._values) if (r[0].toLowerCase() === e.toLowerCase()) return void (r[1] = t + "");
  this.append(e, t);
 }
 values() {
  const e = this._values;
  let t = -1;
  return {
   next() {
    t++;
    const r = !e[t];
    return {
     value: r ? void 0 : e[t][1],
     done: r
    };
   },
   [Symbol.iterator]() {
    return this;
   }
  };
 }
 [Symbol.iterator]() {
  return this.entries();
 }
}

class MockRequest {
 constructor(e, t = {}) {
  this._method = "GET", this._url = "/", this.bodyUsed = !1, this.cache = "default", 
  this.credentials = "same-origin", this.integrity = "", this.keepalive = !1, this.mode = "cors", 
  this.redirect = "follow", this.referrer = "about:client", this.referrerPolicy = "", 
  "string" == typeof e ? this.url = e : e && (Object.assign(this, e), this.headers = new MockHeaders(e.headers)), 
  Object.assign(this, t), t.headers && (this.headers = new MockHeaders(t.headers)), 
  this.headers || (this.headers = new MockHeaders);
 }
 get url() {
  return "string" == typeof this._url ? new URL(this._url, location.href).href : new URL("/", location.href).href;
 }
 set url(e) {
  this._url = e;
 }
 get method() {
  return "string" == typeof this._method ? this._method.toUpperCase() : "GET";
 }
 set method(e) {
  this._method = e;
 }
 clone() {
  const e = {
   ...this
  };
  return e.headers = new MockHeaders(this.headers), new MockRequest(e);
 }
}

class MockResponse {
 constructor(e, t = {}) {
  this.ok = !0, this.status = 200, this.statusText = "", this.type = "default", this.url = "", 
  this._body = e, t && Object.assign(this, t), this.headers = new MockHeaders(t.headers);
 }
 async json() {
  return JSON.parse(this._body);
 }
 async text() {
  return this._body;
 }
 clone() {
  const e = {
   ...this
  };
  return e.headers = new MockHeaders(this.headers), new MockResponse(this._body, e);
 }
}

const mockedResponses = new Map, mockFetch = {
 json(e, t) {
  setMockedResponse(new MockResponse(JSON.stringify(e, null, 2), {
   headers: new MockHeaders({
    "Content-Type": "application/json"
   })
  }), t, !1);
 },
 text(e, t) {
  setMockedResponse(new MockResponse(e, {
   headers: new MockHeaders({
    "Content-Type": "text/plain"
   })
  }), t, !1);
 },
 response(e, t) {
  setMockedResponse(e, t, !1);
 },
 reject(e, t) {
  setMockedResponse(e, t, !0);
 },
 reset: function mockFetchReset() {
  mockedResponses.clear();
 }
};

class MockResponse404 extends MockResponse {
 constructor() {
  super("", {
   headers: new MockHeaders({
    "Content-Type": "text/plain"
   })
  }), this.ok = !1, this.status = 404, this.statusText = "Not Found";
 }
 async json() {
  return {
   status: 404,
   statusText: "Not Found"
  };
 }
 async text() {
  return "Not Found";
 }
}

const FETCH_DEFAULT_PATH = "/mock-fetch-data", HtmlSerializer = {
 print: e => index_cjs.serializeNodeToHtml(e, {
  serializeShadowRoot: !0,
  prettyHtml: !0,
  outerHtml: !0
 }),
 test: e => null != e && (e instanceof HTMLElement || e instanceof index_cjs.MockNode)
}, createConfigFlags = (e = {}) => ({
 task: null,
 args: [],
 knownArgs: [],
 unknownArgs: [],
 ...e
});

class BuildContext {
 constructor(e, t) {
  this.buildId = -1, this.buildMessages = [], this.buildResults = null, this.bundleBuildCount = 0, 
  this.collections = [], this.completedTasks = [], this.components = [], this.componentGraph = new Map, 
  this.data = {}, this.buildStats = void 0, this.diagnostics = [], this.dirsAdded = [], 
  this.dirsDeleted = [], this.entryModules = [], this.filesAdded = [], this.filesChanged = [], 
  this.filesDeleted = [], this.filesUpdated = [], this.filesWritten = [], this.globalStyle = void 0, 
  this.hasConfigChanges = !1, this.hasFinished = !1, this.hasHtmlChanges = !1, this.hasPrintedResults = !1, 
  this.hasServiceWorkerChanges = !1, this.hasScriptChanges = !0, this.hasStyleChanges = !0, 
  this.hydrateAppFilePath = null, this.indexBuildCount = 0, this.indexDoc = void 0, 
  this.isRebuild = !1, this.moduleFiles = [], this.outputs = [], this.packageJson = {}, 
  this.packageJsonFilePath = null, this.pendingCopyTasks = [], this.requiresFullBuild = !0, 
  this.scriptsAdded = [], this.scriptsDeleted = [], this.startTime = Date.now(), this.styleBuildCount = 0, 
  this.stylesPromise = null, this.stylesUpdated = [], this.timeSpan = null, this.transpileBuildCount = 0, 
  this.config = e, this.compilerCtx = t, this.buildId = ++this.compilerCtx.activeBuildId, 
  this.debug = e.logger.debug.bind(e.logger);
 }
 start() {
  const e = `${this.isRebuild ? "rebuild" : "build"}, ${this.config.fsNamespace}, ${this.config.devMode ? "dev" : "prod"} mode, started`, t = {
   buildId: this.buildId,
   messages: [],
   progress: 0
  };
  this.compilerCtx.events.emit("buildLog", t), this.timeSpan = this.createTimeSpan(e), 
  this.timestamp = getBuildTimestamp(), this.debug(`start build, ${this.timestamp}`);
  const r = {
   buildId: this.buildId,
   timestamp: this.timestamp
  };
  this.compilerCtx.events.emit("buildStart", r);
 }
 createTimeSpan(e, t) {
  if (!this.hasFinished || t) {
   t && this.config.watch && (e = `${this.config.logger.cyan("[" + this.buildId + "]")} ${e}`);
   const r = this.config.logger.createTimeSpan(e, t, this.buildMessages);
   if (!t && this.compilerCtx.events) {
    const e = {
     buildId: this.buildId,
     messages: this.buildMessages,
     progress: getProgress(this.completedTasks)
    };
    this.compilerCtx.events.emit("buildLog", e);
   }
   return {
    duration: () => r.duration(),
    finish: (e, s, n, o) => {
     if ((!this.hasFinished || t) && (t && this.config.watch && (e = `${this.config.logger.cyan("[" + this.buildId + "]")} ${e}`), 
     r.finish(e, s, n, o), !t)) {
      const e = {
       buildId: this.buildId,
       messages: this.buildMessages.slice(),
       progress: getProgress(this.completedTasks)
      };
      this.compilerCtx.events.emit("buildLog", e);
     }
     return r.duration();
    }
   };
  }
  return {
   duration: () => 0,
   finish: () => 0
  };
 }
 debug(e) {
  this.config.logger.debug(e);
 }
 get hasError() {
  return hasError(this.diagnostics);
 }
 get hasWarning() {
  return null != (e = this.diagnostics) && 0 !== e.length && e.some((e => "warn" === e.level));
  var e;
 }
 progress(e) {
  this.completedTasks.push(e);
 }
 async validateTypesBuild() {
  this.hasError || this.validateTypesPromise && (this.config.watch || (this.debug("build, non-watch, waiting on validateTypes"), 
  await this.validateTypesPromise, this.debug("build, non-watch, finished waiting on validateTypes")));
 }
}

const getBuildTimestamp = () => {
 const e = new Date;
 let t = e.getUTCFullYear() + "-";
 return t += ("0" + (e.getUTCMonth() + 1)).slice(-2) + "-", t += ("0" + e.getUTCDate()).slice(-2) + "T", 
 t += ("0" + e.getUTCHours()).slice(-2) + ":", t += ("0" + e.getUTCMinutes()).slice(-2) + ":", 
 t += ("0" + e.getUTCSeconds()).slice(-2), t;
}, getProgress = e => {
 let t = 0;
 const r = Object.keys(ProgressTask);
 return r.forEach(((r, s) => {
  e.includes(ProgressTask[r]) && (t = s);
 })), (t + 1) / r.length;
}, ProgressTask = {
 emptyOutputTargets: {},
 transpileApp: {},
 generateStyles: {},
 generateOutputTargets: {},
 validateTypesBuild: {},
 writeBuildFiles: {}
};

class Cache {
 constructor(e, t) {
  this.config = e, this.cacheFs = t, this.failed = 0, this.skip = !1, this.sys = e.sys, 
  this.logger = e.logger;
 }
 async initCacheDir() {
  if (!this.config._isTesting && this.config.cacheDir) {
   if (!this.config.enableCache || !this.cacheFs) return this.config.logger.info("cache optimizations disabled"), 
   void this.clearDiskCache();
   this.config.logger.debug(`cache enabled, cacheDir: ${this.config.cacheDir}`);
   try {
    const e = path$2.join(this.config.cacheDir, "_README.log");
    await this.cacheFs.writeFile(e, CACHE_DIR_README);
   } catch (e) {
    this.logger.error(`Cache, initCacheDir: ${e}`), this.config.enableCache = !1;
   }
  }
 }
 async get(e) {
  if (!this.config.enableCache || this.skip) return null;
  if (this.failed >= MAX_FAILED) return this.skip || (this.skip = !0, this.logger.debug(`cache had ${this.failed} failed ops, skip disk ops for remander of build`)), 
  null;
  let t;
  try {
   t = await this.cacheFs.readFile(this.getCacheFilePath(e)), this.failed = 0, this.skip = !1;
  } catch (e) {
   this.failed++, t = null;
  }
  return t;
 }
 async put(e, t) {
  if (!this.config.enableCache) return !1;
  let r;
  try {
   await this.cacheFs.writeFile(this.getCacheFilePath(e), t), r = !0;
  } catch (e) {
   this.failed++, r = !1;
  }
  return r;
 }
 async has(e) {
  return "string" == typeof await this.get(e);
 }
 async createKey(e, ...t) {
  return this.config.enableCache ? e + "_" + await this.sys.generateContentHash(JSON.stringify(t), 32) : e + 9999999 * Math.random();
 }
 async commit() {
  this.config.enableCache && (this.skip = !1, this.failed = 0, await this.cacheFs.commit(), 
  await this.clearExpiredCache());
 }
 clear() {
  null != this.cacheFs && this.cacheFs.clearCache();
 }
 async clearExpiredCache() {
  if (null == this.cacheFs || null == this.sys.cacheStorage) return;
  const e = Date.now(), t = await this.sys.cacheStorage.get(EXP_STORAGE_KEY);
  if (null != t) {
   if (e - t < ONE_DAY) return;
   const r = this.cacheFs.sys, s = await r.readDir(this.config.cacheDir), n = s.map((e => path$2.join(this.config.cacheDir, e)));
   let o = 0;
   const i = n.map((async t => {
    const s = (await r.stat(t)).mtimeMs;
    e - s > ONE_WEEK && (await r.removeFile(t), o++);
   }));
   await Promise.all(i), this.logger.debug(`clearExpiredCache, cachedFileNames: ${s.length}, totalCleared: ${o}`);
  }
  this.logger.debug("clearExpiredCache, set last clear"), await this.sys.cacheStorage.set(EXP_STORAGE_KEY, e);
 }
 async clearDiskCache() {
  null != this.cacheFs && await this.cacheFs.access(this.config.cacheDir) && (await this.cacheFs.remove(this.config.cacheDir), 
  await this.cacheFs.commit());
 }
 getCacheFilePath(e) {
  return path$2.join(this.config.cacheDir, e) + ".log";
 }
 getMemoryStats() {
  return null != this.cacheFs ? this.cacheFs.getMemoryStats() : null;
 }
}

const MAX_FAILED = 100, ONE_DAY = 864e5, ONE_WEEK = 7 * ONE_DAY, EXP_STORAGE_KEY = "last_clear_expired_cache", CACHE_DIR_README = '# Stencil Cache Directory\n\nThis directory contains files which the compiler has\ncached for faster builds. To disable caching, please set\n"enableCache: false" within the stencil config.\n\nTo change the cache directory, please update the\n"cacheDir" property within the stencil config.\n', buildEvents = () => {
 const e = [], t = t => {
  const r = e.findIndex((e => e.callback === t));
  return r > -1 && (e.splice(r, 1), !0);
 };
 return {
  emit: (t, r) => {
   const s = t.toLowerCase().trim(), n = e.slice();
   for (const e of n) if (null == e.eventName) try {
    e.callback(t, r);
   } catch (e) {
    console.error(e);
   } else if (e.eventName === s) try {
    e.callback(r);
   } catch (e) {
    console.error(e);
   }
  },
  on: (r, s) => {
   if ("function" == typeof r) {
    const s = null, n = r;
    return e.push({
     eventName: s,
     callback: n
    }), () => t(n);
   }
   if ("string" == typeof r && "function" == typeof s) {
    const n = r.toLowerCase().trim(), o = s;
    return e.push({
     eventName: n,
     callback: o
    }), () => t(o);
   }
   return () => !1;
  },
  unsubscribeAll: () => {
   e.length = 0;
  }
 };
}, getCommitInstructions = e => {
 const t = {
  filesToDelete: [],
  filesToWrite: [],
  filesToCopy: [],
  dirsToDelete: [],
  dirsToEnsure: []
 };
 e.forEach(((e, r) => {
  if (!0 === e.queueWriteToDisk) {
   if (!0 === e.isFile) {
    t.filesToWrite.push(r);
    const e = normalizePath(path$2.dirname(r));
    t.dirsToEnsure.includes(e) || t.dirsToEnsure.push(e);
    const s = t.dirsToDelete.indexOf(e);
    s > -1 && t.dirsToDelete.splice(s, 1);
    const n = t.filesToDelete.indexOf(r);
    n > -1 && t.filesToDelete.splice(n, 1);
   } else if (!0 === e.isDirectory) {
    t.dirsToEnsure.includes(r) || t.dirsToEnsure.push(r);
    const e = t.dirsToDelete.indexOf(r);
    e > -1 && t.dirsToDelete.splice(e, 1);
   }
  } else if (!0 === e.queueDeleteFromDisk) e.isDirectory && !t.dirsToEnsure.includes(r) ? t.dirsToDelete.push(r) : e.isFile && !t.filesToWrite.includes(r) && t.filesToDelete.push(r); else if ("string" == typeof e.queueCopyFileToDest) {
   const s = r, n = e.queueCopyFileToDest;
   t.filesToCopy.push([ s, n ]);
   const o = normalizePath(path$2.dirname(n));
   t.dirsToEnsure.includes(o) || t.dirsToEnsure.push(o);
   const i = t.dirsToDelete.indexOf(o);
   i > -1 && t.dirsToDelete.splice(i, 1);
   const a = t.filesToDelete.indexOf(n);
   a > -1 && t.filesToDelete.splice(a, 1);
  }
  e.queueDeleteFromDisk = !1, e.queueWriteToDisk = !1;
 }));
 for (let e = 0, r = t.dirsToEnsure.length; e < r; e++) {
  const r = t.dirsToEnsure[e].split("/");
  for (let e = 2; e < r.length; e++) {
   const s = r.slice(0, e).join("/");
   !1 === t.dirsToEnsure.includes(s) && t.dirsToEnsure.push(s);
  }
 }
 t.dirsToEnsure.sort(((e, t) => {
  const r = e.split("/").length, s = t.split("/").length;
  return r < s ? -1 : r > s ? 1 : e.length < t.length ? -1 : e.length > t.length ? 1 : 0;
 })), t.dirsToDelete.sort(((e, t) => {
  const r = e.split("/").length, s = t.split("/").length;
  return r < s ? 1 : r > s ? -1 : e.length < t.length ? 1 : e.length > t.length ? -1 : 0;
 }));
 for (const e of t.dirsToEnsure) {
  const r = t.dirsToDelete.indexOf(e);
  r > -1 && t.dirsToDelete.splice(r, 1);
 }
 return t.dirsToDelete = t.dirsToDelete.filter((e => "/" !== e && !0 !== e.endsWith(":/"))), 
 t.dirsToEnsure = t.dirsToEnsure.filter((t => {
  const r = e.get(t);
  return (null == r || !0 !== r.exists || !0 !== r.isDirectory) && "/" !== t && !t.endsWith(":/");
 })), t;
}, shouldIgnore = e => (e = e.trim().toLowerCase(), IGNORE.some((t => e.endsWith(t)))), IGNORE = [ ".ds_store", ".gitignore", "desktop.ini", "thumbs.db" ];

class TestingLogger {
 constructor() {
  this.isEnabled = !1;
 }
 setLevel(e) {}
 getLevel() {
  return "info";
 }
 enableColors(e) {}
 emoji(e) {
  return "";
 }
 info(...e) {
  this.isEnabled && console.log(...e);
 }
 warn(...e) {
  this.isEnabled && console.warn(...e);
 }
 error(...e) {
  this.isEnabled && console.error(...e);
 }
 debug(...e) {
  this.isEnabled && console.log(...e);
 }
 color(e, t) {}
 red(e) {
  return e;
 }
 green(e) {
  return e;
 }
 yellow(e) {
  return e;
 }
 blue(e) {
  return e;
 }
 magenta(e) {
  return e;
 }
 cyan(e) {
  return e;
 }
 gray(e) {
  return e;
 }
 bold(e) {
  return e;
 }
 dim(e) {
  return e;
 }
 bgRed(e) {
  return e;
 }
 createTimeSpan(e, t = !1) {
  return {
   duration: () => 0,
   finish: () => 0
  };
 }
 printDiagnostics(e) {}
}

(posix = {
 resolve: function e() {
  var t, r, s, n = "", o = !1;
  for (r = arguments.length - 1; r >= -1 && !o; r--) r >= 0 ? s = arguments[r] : (void 0 === t && (t = process.cwd()), 
  s = t), assertPath(s), 0 !== s.length && (n = s + "/" + n, o = 47 === s.charCodeAt(0));
  return n = normalizeStringPosix(n, !o), o ? n.length > 0 ? "/" + n : "/" : n.length > 0 ? n : ".";
 },
 normalize: function e(t) {
  var r, s;
  return assertPath(t), 0 === t.length ? "." : (r = 47 === t.charCodeAt(0), s = 47 === t.charCodeAt(t.length - 1), 
  0 !== (t = normalizeStringPosix(t, !r)).length || r || (t = "."), t.length > 0 && s && (t += "/"), 
  r ? "/" + t : t);
 },
 isAbsolute: function e(t) {
  return assertPath(t), t.length > 0 && 47 === t.charCodeAt(0);
 },
 join: function e() {
  var t, r, s;
  if (0 === arguments.length) return ".";
  for (r = 0; r < arguments.length; ++r) assertPath(s = arguments[r]), s.length > 0 && (void 0 === t ? t = s : t += "/" + s);
  return void 0 === t ? "." : posix.normalize(t);
 },
 relative: function e(t, r) {
  var s, n, o, i, a, l, c, u, d, h;
  if (assertPath(t), assertPath(r), t === r) return "";
  if ((t = posix.resolve(t)) === (r = posix.resolve(r))) return "";
  for (s = 1; s < t.length && 47 === t.charCodeAt(s); ++s) ;
  for (o = (n = t.length) - s, i = 1; i < r.length && 47 === r.charCodeAt(i); ++i) ;
  for (l = o < (a = r.length - i) ? o : a, c = -1, u = 0; u <= l; ++u) {
   if (u === l) {
    if (a > l) {
     if (47 === r.charCodeAt(i + u)) return r.slice(i + u + 1);
     if (0 === u) return r.slice(i + u);
    } else o > l && (47 === t.charCodeAt(s + u) ? c = u : 0 === u && (c = 0));
    break;
   }
   if ((d = t.charCodeAt(s + u)) !== r.charCodeAt(i + u)) break;
   47 === d && (c = u);
  }
  for (h = "", u = s + c + 1; u <= n; ++u) u !== n && 47 !== t.charCodeAt(u) || (0 === h.length ? h += ".." : h += "/..");
  return h.length > 0 ? h + r.slice(i + c) : (i += c, 47 === r.charCodeAt(i) && ++i, 
  r.slice(i));
 },
 _makeLong: function e(t) {
  return t;
 },
 dirname: function e(t) {
  var r, s, n, o;
  if (assertPath(t), 0 === t.length) return ".";
  for (r = 47 === t.charCodeAt(0), s = -1, n = !0, o = t.length - 1; o >= 1; --o) if (47 === t.charCodeAt(o)) {
   if (!n) {
    s = o;
    break;
   }
  } else n = !1;
  return -1 === s ? r ? "/" : "." : r && 1 === s ? "//" : t.slice(0, s);
 },
 basename: function e(t, r) {
  var s, n, o, i, a, l, c;
  if (void 0 !== r && "string" != typeof r) throw new TypeError('"ext" argument must be a string');
  if (assertPath(t), s = 0, n = -1, o = !0, void 0 !== r && r.length > 0 && r.length <= t.length) {
   if (r.length === t.length && r === t) return "";
   for (a = r.length - 1, l = -1, i = t.length - 1; i >= 0; --i) if (47 === (c = t.charCodeAt(i))) {
    if (!o) {
     s = i + 1;
     break;
    }
   } else -1 === l && (o = !1, l = i + 1), a >= 0 && (c === r.charCodeAt(a) ? -1 == --a && (n = i) : (a = -1, 
   n = l));
   return s === n ? n = l : -1 === n && (n = t.length), t.slice(s, n);
  }
  for (i = t.length - 1; i >= 0; --i) if (47 === t.charCodeAt(i)) {
   if (!o) {
    s = i + 1;
    break;
   }
  } else -1 === n && (o = !1, n = i + 1);
  return -1 === n ? "" : t.slice(s, n);
 },
 extname: function e(t) {
  var r, s, n, o, i, a, l;
  for (assertPath(t), r = -1, s = 0, n = -1, o = !0, i = 0, a = t.length - 1; a >= 0; --a) if (47 !== (l = t.charCodeAt(a))) -1 === n && (o = !1, 
  n = a + 1), 46 === l ? -1 === r ? r = a : 1 !== i && (i = 1) : -1 !== r && (i = -1); else if (!o) {
   s = a + 1;
   break;
  }
  return -1 === r || -1 === n || 0 === i || 1 === i && r === n - 1 && r === s + 1 ? "" : t.slice(r, n);
 },
 format: function e(t) {
  if (null === t || "object" != typeof t) throw new TypeError('The "pathObject" argument must be of type Object. Received type ' + typeof t);
  return function r(e, t) {
   var r = t.dir || t.root, s = t.base || (t.name || "") + (t.ext || "");
   return r ? r === t.root ? r + s : r + e + s : s;
  }("/", t);
 },
 parse: function e(t) {
  var r, s, n, o, i, a, l, c, u, d;
  if (assertPath(t), r = {
   root: "",
   dir: "",
   base: "",
   ext: "",
   name: ""
  }, 0 === t.length) return r;
  for ((n = 47 === (s = t.charCodeAt(0))) ? (r.root = "/", o = 1) : o = 0, i = -1, 
  a = 0, l = -1, c = !0, u = t.length - 1, d = 0; u >= o; --u) if (47 !== (s = t.charCodeAt(u))) -1 === l && (c = !1, 
  l = u + 1), 46 === s ? -1 === i ? i = u : 1 !== d && (d = 1) : -1 !== i && (d = -1); else if (!c) {
   a = u + 1;
   break;
  }
  return -1 === i || -1 === l || 0 === d || 1 === d && i === l - 1 && i === a + 1 ? -1 !== l && (r.base = r.name = 0 === a && n ? t.slice(1, l) : t.slice(a, l)) : (0 === a && n ? (r.name = t.slice(1, i), 
  r.base = t.slice(1, l)) : (r.name = t.slice(a, i), r.base = t.slice(a, l)), r.ext = t.slice(i, l)), 
  a > 0 ? r.dir = t.slice(0, a - 1) : n && (r.dir = "/"), r;
 },
 sep: "/",
 delimiter: ":",
 win32: null,
 posix: null
}).posix = posix, pathBrowserify = posix;

const IS_NODE_ENV = !("undefined" == typeof global || "function" != typeof require || !global.process || "string" != typeof __filename || global.origin && "string" == typeof global.origin);

IS_NODE_ENV && process.platform;

const IS_BROWSER_ENV = "undefined" != typeof location && "undefined" != typeof navigator && "undefined" != typeof XMLHttpRequest, IS_WEB_WORKER_ENV = IS_BROWSER_ENV && "undefined" != typeof self && "function" == typeof self.importScripts, HAS_WEB_WORKER = IS_BROWSER_ENV && "function" == typeof Worker, IS_FETCH_ENV = "function" == typeof fetch;

IS_NODE_ENV && require, IS_NODE_ENV && process.cwd;

const YELLOW = "#f39c12", RED = "#c0392b", BLUE = "#3498db";

caller = function() {
 var e, t = Error.prepareStackTrace;
 return Error.prepareStackTrace = function(e, t) {
  return t;
 }, e = (new Error).stack, Error.prepareStackTrace = t, e[2].getFileName();
}, pathParse = function createCommonjsModule(e, t, r) {
 return e(r = {
  path: t,
  exports: {},
  require: function(e, t) {
   return function s() {
    throw new Error("Dynamic requires are not currently supported by @rollup/plugin-commonjs");
   }(null == t && r.path);
  }
 }, r.exports), r.exports;
}((function(e) {
 var t, r, s = "win32" === process.platform, n = /^(((?:[a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?[\\\/]?)(?:[^\\\/]*[\\\/])*)((\.{1,2}|[^\\\/]+?|)(\.[^.\/\\]*|))[\\\/]*$/, o = {
  parse: function(e) {
   if ("string" != typeof e) throw new TypeError("Parameter 'pathString' must be a string, not " + typeof e);
   var t = function r(e) {
    return n.exec(e).slice(1);
   }(e);
   if (!t || 5 !== t.length) throw new TypeError("Invalid path '" + e + "'");
   return {
    root: t[1],
    dir: t[0] === t[1] ? t[0] : t[0].slice(0, -1),
    base: t[2],
    ext: t[4],
    name: t[3]
   };
  }
 };
 t = /^((\/?)(?:[^\/]*\/)*)((\.{1,2}|[^\/]+?|)(\.[^.\/]*|))[\/]*$/, (r = {}).parse = function(e) {
  if ("string" != typeof e) throw new TypeError("Parameter 'pathString' must be a string, not " + typeof e);
  var r = function s(e) {
   return t.exec(e).slice(1);
  }(e);
  if (!r || 5 !== r.length) throw new TypeError("Invalid path '" + e + "'");
  return {
   root: r[1],
   dir: r[0].slice(0, -1),
   base: r[2],
   ext: r[4],
   name: r[3]
  };
 }, e.exports = s ? o.parse : r.parse, e.exports.posix = r.parse, e.exports.win32 = o.parse;
})), parse = path__default.default.parse || pathParse, getNodeModulesDirs = function e(t, r) {
 var s, n, o = "/";
 for (/^([A-Za-z]:)/.test(t) ? o = "" : /^\\\\/.test(t) && (o = "\\\\"), s = [ t ], 
 n = parse(t); n.dir !== s[s.length - 1]; ) s.push(n.dir), n = parse(n.dir);
 return s.reduce((function(e, t) {
  return e.concat(r.map((function(e) {
   return path__default.default.resolve(o, t, e);
  })));
 }), []);
}, nodeModulesPaths = function e(t, r, s) {
 var n, o = r && r.moduleDirectory ? [].concat(r.moduleDirectory) : [ "node_modules" ];
 return r && "function" == typeof r.paths ? r.paths(s, t, (function() {
  return getNodeModulesDirs(t, o);
 }), r) : (n = getNodeModulesDirs(t, o), r && r.paths ? n.concat(r.paths) : n);
}, normalizeOptions = function(e, t) {
 return t || {};
}, ERROR_MESSAGE = "Function.prototype.bind called on incompatible ", slice = Array.prototype.slice, 
toStr = Object.prototype.toString, implementation = function e(t) {
 var r, s, n, o, i, a, l, c = this;
 if ("function" != typeof c || "[object Function]" !== toStr.call(c)) throw new TypeError(ERROR_MESSAGE + c);
 for (r = slice.call(arguments, 1), n = function() {
  if (this instanceof s) {
   var e = c.apply(this, r.concat(slice.call(arguments)));
   return Object(e) === e ? e : this;
  }
  return c.apply(t, r.concat(slice.call(arguments)));
 }, o = Math.max(0, c.length - r.length), i = [], a = 0; a < o; a++) i.push("$" + a);
 return s = Function("binder", "return function (" + i.join(",") + "){ return binder.apply(this,arguments); }")(n), 
 c.prototype && ((l = function e() {}).prototype = c.prototype, s.prototype = new l, 
 l.prototype = null), s;
}, functionBind = Function.prototype.bind || implementation, src = functionBind.call(Function.call, Object.prototype.hasOwnProperty);

const data$1 = {
 assert: !0,
 "assert/strict": ">= 15",
 async_hooks: ">= 8",
 buffer_ieee754: "< 0.9.7",
 buffer: !0,
 child_process: !0,
 cluster: !0,
 console: !0,
 constants: !0,
 crypto: !0,
 _debug_agent: ">= 1 && < 8",
 _debugger: "< 8",
 dgram: !0,
 diagnostics_channel: ">= 15.1",
 dns: !0,
 "dns/promises": ">= 15",
 domain: ">= 0.7.12",
 events: !0,
 freelist: "< 6",
 fs: !0,
 "fs/promises": [ ">= 10 && < 10.1", ">= 14" ],
 _http_agent: ">= 0.11.1",
 _http_client: ">= 0.11.1",
 _http_common: ">= 0.11.1",
 _http_incoming: ">= 0.11.1",
 _http_outgoing: ">= 0.11.1",
 _http_server: ">= 0.11.1",
 http: !0,
 http2: ">= 8.8",
 https: !0,
 inspector: ">= 8.0.0",
 _linklist: "< 8",
 module: !0,
 net: !0,
 "node-inspect/lib/_inspect": ">= 7.6.0 && < 12",
 "node-inspect/lib/internal/inspect_client": ">= 7.6.0 && < 12",
 "node-inspect/lib/internal/inspect_repl": ">= 7.6.0 && < 12",
 os: !0,
 path: !0,
 "path/posix": ">= 15.3",
 "path/win32": ">= 15.3",
 perf_hooks: ">= 8.5",
 process: ">= 1",
 punycode: !0,
 querystring: !0,
 readline: !0,
 repl: !0,
 smalloc: ">= 0.11.5 && < 3",
 _stream_duplex: ">= 0.9.4",
 _stream_transform: ">= 0.9.4",
 _stream_wrap: ">= 1.4.1",
 _stream_passthrough: ">= 0.9.4",
 _stream_readable: ">= 0.9.4",
 _stream_writable: ">= 0.9.4",
 stream: !0,
 "stream/promises": ">= 15",
 string_decoder: !0,
 sys: [ ">= 0.6 && < 0.7", ">= 0.8" ],
 timers: !0,
 "timers/promises": ">= 15",
 _tls_common: ">= 0.11.13",
 _tls_legacy: ">= 0.11.3 && < 10",
 _tls_wrap: ">= 0.11.3",
 tls: !0,
 trace_events: ">= 10",
 tty: !0,
 url: !0,
 util: !0,
 "util/types": ">= 15.3",
 "v8/tools/arguments": ">= 10 && < 12",
 "v8/tools/codemap": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/consarray": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/csvparser": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/logreader": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/profile_view": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/splaytree": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 v8: ">= 1",
 vm: !0,
 wasi: ">= 13.4 && < 13.5",
 worker_threads: ">= 11.7",
 zlib: !0
};

isCoreModule = function e(t, r) {
 return src(data$1, t) && function s(e, t) {
  var r, s;
  if ("boolean" == typeof t) return t;
  if ("string" != typeof (r = void 0 === e ? process.versions && process.versions.node && process.versions.node : e)) throw new TypeError(void 0 === e ? "Unable to determine current node version" : "If provided, a valid node version is required");
  if (t && "object" == typeof t) {
   for (s = 0; s < t.length; ++s) if (matchesRange$1(r, t[s])) return !0;
   return !1;
  }
  return matchesRange$1(r, t);
 }(r, data$1[t]);
}, realpathFS$1 = fs__default.default.realpath && "function" == typeof fs__default.default.realpath.native ? fs__default.default.realpath.native : fs__default.default.realpath, 
defaultIsFile$1 = function e(t, r) {
 fs__default.default.stat(t, (function(e, t) {
  return e ? "ENOENT" === e.code || "ENOTDIR" === e.code ? r(null, !1) : r(e) : r(null, t.isFile() || t.isFIFO());
 }));
}, defaultIsDir$1 = function e(t, r) {
 fs__default.default.stat(t, (function(e, t) {
  return e ? "ENOENT" === e.code || "ENOTDIR" === e.code ? r(null, !1) : r(e) : r(null, t.isDirectory());
 }));
}, defaultRealpath = function e(t, r) {
 realpathFS$1(t, (function(e, s) {
  e && "ENOENT" !== e.code ? r(e) : r(null, e ? t : s);
 }));
}, maybeRealpath = function e(t, r, s, n) {
 s && !1 === s.preserveSymlinks ? t(r, n) : n(null, r);
}, defaultReadPackage = function e(t, r, s) {
 t(r, (function(e, t) {
  if (e) s(e); else try {
   var r = JSON.parse(t);
   s(null, r);
  } catch (e) {
   s(null);
  }
 }));
}, getPackageCandidates$1 = function e(t, r, s) {
 var n, o = nodeModulesPaths(r, s, t);
 for (n = 0; n < o.length; n++) o[n] = path__default.default.join(o[n], t);
 return o;
}, async = function e(t, r, s) {
 function n(e) {
  if (/^(?:\.\.?(?:\/|$)|\/|([A-Za-z]:)?[/\\])/.test(t)) T = path__default.default.resolve(e, t), 
  "." !== t && ".." !== t && "/" !== t.slice(-1) || (T += "/"), /\/$/.test(t) && T === e ? l(T, C.package, o) : i(T, C.package, o); else {
   if (_ && isCoreModule(t)) return S(null, t);
   !function r(e, t, s) {
    var n = function() {
     return getPackageCandidates$1(e, t, C);
    };
    c(s, y ? y(e, t, n, C) : n());
   }(t, e, (function(e, r, s) {
    if (e) S(e); else {
     if (r) return maybeRealpath(f, r, C, (function(e, t) {
      e ? S(e) : S(null, t, s);
     }));
     var n = new Error("Cannot find module '" + t + "' from '" + b + "'");
     n.code = "MODULE_NOT_FOUND", S(n);
    }
   }));
  }
 }
 function o(e, r, s) {
  e ? S(e) : r ? S(null, r, s) : l(T, (function(e, r, s) {
   if (e) S(e); else if (r) maybeRealpath(f, r, C, (function(e, t) {
    e ? S(e) : S(null, t, s);
   })); else {
    var n = new Error("Cannot find module '" + t + "' from '" + b + "'");
    n.code = "MODULE_NOT_FOUND", S(n);
   }
  }));
 }
 function i(e, t, r) {
  var s = t, n = r;
  "function" == typeof s && (n = s, s = void 0), function e(t, r, s) {
   function o(s, o, a) {
    var u, h, p;
    return c = o, s ? n(s) : a && c && C.pathFilter && (h = (u = path__default.default.relative(a, l)).slice(0, u.length - t[0].length), 
    p = C.pathFilter(c, r, h)) ? e([ "" ].concat(w.slice()), path__default.default.resolve(a, p), c) : void d(l, i);
   }
   function i(s, o) {
    return s ? n(s) : o ? n(null, l, c) : void e(t.slice(1), r, c);
   }
   var l, c;
   if (0 === t.length) return n(null, void 0, s);
   l = r + t[0], (c = s) ? o(null, c) : a(path__default.default.dirname(l), o);
  }([ "" ].concat(w), e, s);
 }
 function a(e, t) {
  return "" === e || "/" === e || "win32" === process.platform && /^\w:[/\\]*$/.test(e) || /[/\\]node_modules[/\\]*$/.test(e) ? t(null) : void maybeRealpath(f, e, C, (function(r, s) {
   if (r) return a(path__default.default.dirname(e), t);
   var n = path__default.default.join(s, "package.json");
   d(n, (function(r, s) {
    if (!s) return a(path__default.default.dirname(e), t);
    m(p, n, (function(r, s) {
     r && t(r);
     var o = s;
     o && C.packageFilter && (o = C.packageFilter(o, n)), t(null, o, e);
    }));
   }));
  }));
 }
 function l(e, t, r) {
  var s = r, n = t;
  "function" == typeof n && (s = n, n = C.package), maybeRealpath(f, e, C, (function(t, r) {
   if (t) return s(t);
   var o = path__default.default.join(r, "package.json");
   d(o, (function(t, r) {
    return t ? s(t) : r ? void m(p, o, (function(t, r) {
     var n, a;
     return t ? s(t) : ((n = r) && C.packageFilter && (n = C.packageFilter(n, o)), n && n.main ? "string" != typeof n.main ? ((a = new TypeError("package “" + n.name + "” `main` must be a string")).code = "INVALID_PACKAGE_MAIN", 
     s(a)) : ("." !== n.main && "./" !== n.main || (n.main = "index"), void i(path__default.default.resolve(e, n.main), n, (function(t, r, n) {
      return t ? s(t) : r ? s(null, r, n) : n ? void l(path__default.default.resolve(e, n.main), n, (function(t, r, n) {
       return t ? s(t) : r ? s(null, r, n) : void i(path__default.default.join(e, "index"), n, s);
      })) : i(path__default.default.join(e, "index"), n, s);
     }))) : void i(path__default.default.join(e, "/index"), n, s));
    })) : i(path__default.default.join(e, "index"), n, s);
   }));
  }));
 }
 function c(e, t) {
  function r(t, r, o) {
   return t ? e(t) : r ? e(null, r, o) : void l(n, C.package, s);
  }
  function s(r, s, n) {
   return r ? e(r) : s ? e(null, s, n) : void c(e, t.slice(1));
  }
  if (0 === t.length) return e(null, void 0);
  var n = t[0];
  h(path__default.default.dirname(n), (function o(s, a) {
   return s ? e(s) : a ? void i(n, C.package, r) : c(e, t.slice(1));
  }));
 }
 var u, d, h, p, f, m, g, y, w, _, v, b, E, T, S = s, C = r;
 return "function" == typeof r && (S = C, C = {}), "string" != typeof t ? (u = new TypeError("Path must be a string."), 
 process.nextTick((function() {
  S(u);
 }))) : (C = normalizeOptions(0, C), d = C.isFile || defaultIsFile$1, h = C.isDirectory || defaultIsDir$1, 
 p = C.readFile || fs__default.default.readFile, f = C.realpath || defaultRealpath, 
 m = C.readPackage || defaultReadPackage, C.readFile && C.readPackage ? (g = new TypeError("`readFile` and `readPackage` are mutually exclusive."), 
 process.nextTick((function() {
  S(g);
 }))) : (y = C.packageIterator, w = C.extensions || [ ".js" ], _ = !1 !== C.includeCoreModules, 
 v = C.basedir || path__default.default.dirname(caller()), b = C.filename || v, C.paths = C.paths || [], 
 E = path__default.default.resolve(v), void maybeRealpath(f, E, C, (function(e, t) {
  e ? S(e) : n(t);
 }))));
};

const data = {
 assert: !0,
 "assert/strict": ">= 15",
 async_hooks: ">= 8",
 buffer_ieee754: "< 0.9.7",
 buffer: !0,
 child_process: !0,
 cluster: !0,
 console: !0,
 constants: !0,
 crypto: !0,
 _debug_agent: ">= 1 && < 8",
 _debugger: "< 8",
 dgram: !0,
 diagnostics_channel: ">= 15.1",
 dns: !0,
 "dns/promises": ">= 15",
 domain: ">= 0.7.12",
 events: !0,
 freelist: "< 6",
 fs: !0,
 "fs/promises": [ ">= 10 && < 10.1", ">= 14" ],
 _http_agent: ">= 0.11.1",
 _http_client: ">= 0.11.1",
 _http_common: ">= 0.11.1",
 _http_incoming: ">= 0.11.1",
 _http_outgoing: ">= 0.11.1",
 _http_server: ">= 0.11.1",
 http: !0,
 http2: ">= 8.8",
 https: !0,
 inspector: ">= 8.0.0",
 _linklist: "< 8",
 module: !0,
 net: !0,
 "node-inspect/lib/_inspect": ">= 7.6.0 && < 12",
 "node-inspect/lib/internal/inspect_client": ">= 7.6.0 && < 12",
 "node-inspect/lib/internal/inspect_repl": ">= 7.6.0 && < 12",
 os: !0,
 path: !0,
 "path/posix": ">= 15.3",
 "path/win32": ">= 15.3",
 perf_hooks: ">= 8.5",
 process: ">= 1",
 punycode: !0,
 querystring: !0,
 readline: !0,
 repl: !0,
 smalloc: ">= 0.11.5 && < 3",
 _stream_duplex: ">= 0.9.4",
 _stream_transform: ">= 0.9.4",
 _stream_wrap: ">= 1.4.1",
 _stream_passthrough: ">= 0.9.4",
 _stream_readable: ">= 0.9.4",
 _stream_writable: ">= 0.9.4",
 stream: !0,
 "stream/promises": ">= 15",
 string_decoder: !0,
 sys: [ ">= 0.6 && < 0.7", ">= 0.8" ],
 timers: !0,
 "timers/promises": ">= 15",
 _tls_common: ">= 0.11.13",
 _tls_legacy: ">= 0.11.3 && < 10",
 _tls_wrap: ">= 0.11.3",
 tls: !0,
 trace_events: ">= 10",
 tty: !0,
 url: !0,
 util: !0,
 "util/types": ">= 15.3",
 "v8/tools/arguments": ">= 10 && < 12",
 "v8/tools/codemap": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/consarray": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/csvparser": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/logreader": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/profile_view": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 "v8/tools/splaytree": [ ">= 4.4.0 && < 5", ">= 5.2.0 && < 12" ],
 v8: ">= 1",
 vm: !0,
 wasi: ">= 13.4 && < 13.5",
 worker_threads: ">= 11.7",
 zlib: !0
};

for (mod in current = process.versions && process.versions.node && process.versions.node.split(".") || [], 
core = {}, data) Object.prototype.hasOwnProperty.call(data, mod) && (core[mod] = versionIncluded(data[mod]));

core_1 = core, isCore = function e(t) {
 return isCoreModule(t);
}, realpathFS = fs__default.default.realpathSync && "function" == typeof fs__default.default.realpathSync.native ? fs__default.default.realpathSync.native : fs__default.default.realpathSync, 
defaultIsFile = function e(t) {
 try {
  var r = fs__default.default.statSync(t);
 } catch (e) {
  if (e && ("ENOENT" === e.code || "ENOTDIR" === e.code)) return !1;
  throw e;
 }
 return r.isFile() || r.isFIFO();
}, defaultIsDir = function e(t) {
 try {
  var r = fs__default.default.statSync(t);
 } catch (e) {
  if (e && ("ENOENT" === e.code || "ENOTDIR" === e.code)) return !1;
  throw e;
 }
 return r.isDirectory();
}, defaultRealpathSync = function e(t) {
 try {
  return realpathFS(t);
 } catch (e) {
  if ("ENOENT" !== e.code) throw e;
 }
 return t;
}, maybeRealpathSync = function e(t, r, s) {
 return s && !1 === s.preserveSymlinks ? t(r) : r;
}, defaultReadPackageSync = function e(t, r) {
 var s = t(r);
 try {
  return JSON.parse(s);
 } catch (e) {}
}, getPackageCandidates = function e(t, r, s) {
 var n, o = nodeModulesPaths(r, s, t);
 for (n = 0; n < o.length; n++) o[n] = path__default.default.join(o[n], t);
 return o;
}, sync = function e(t, r) {
 function s(e) {
  var t, r, s, o, l = n(path__default.default.dirname(e));
  if (l && l.dir && l.pkg && i.pathFilter && (t = path__default.default.relative(l.dir, e), 
  (r = i.pathFilter(l.pkg, e, t)) && (e = path__default.default.resolve(l.dir, r))), 
  a(e)) return e;
  for (s = 0; s < p.length; s++) if (o = e + p[s], a(o)) return o;
 }
 function n(e) {
  var t, r;
  if ("" !== e && "/" !== e && !("win32" === process.platform && /^\w:[/\\]*$/.test(e) || /[/\\]node_modules[/\\]*$/.test(e))) return t = path__default.default.join(maybeRealpathSync(u, e, i), "package.json"), 
  a(t) ? ((r = d(l, t)) && i.packageFilter && (r = i.packageFilter(r, e)), {
   pkg: r,
   dir: e
  }) : n(path__default.default.dirname(e));
 }
 function o(e) {
  var t, r, n, c, h = path__default.default.join(maybeRealpathSync(u, e, i), "/package.json");
  if (a(h)) {
   try {
    t = d(l, h);
   } catch (e) {}
   if (t && i.packageFilter && (t = i.packageFilter(t, e)), t && t.main) {
    if ("string" != typeof t.main) throw (r = new TypeError("package “" + t.name + "” `main` must be a string")).code = "INVALID_PACKAGE_MAIN", 
    r;
    "." !== t.main && "./" !== t.main || (t.main = "index");
    try {
     if (n = s(path__default.default.resolve(e, t.main))) return n;
     if (c = o(path__default.default.resolve(e, t.main))) return c;
    } catch (e) {}
   }
  }
  return s(path__default.default.join(e, "/index"));
 }
 var i, a, l, c, u, d, h, p, f, m, g, y, w, _, v, b;
 if ("string" != typeof t) throw new TypeError("Path must be a string.");
 if (i = normalizeOptions(0, r), a = i.isFile || defaultIsFile, l = i.readFileSync || fs__default.default.readFileSync, 
 c = i.isDirectory || defaultIsDir, u = i.realpathSync || defaultRealpathSync, d = i.readPackageSync || defaultReadPackageSync, 
 i.readFileSync && i.readPackageSync) throw new TypeError("`readFileSync` and `readPackageSync` are mutually exclusive.");
 if (h = i.packageIterator, p = i.extensions || [ ".js" ], f = !1 !== i.includeCoreModules, 
 m = i.basedir || path__default.default.dirname(caller()), g = i.filename || m, i.paths = i.paths || [], 
 y = maybeRealpathSync(u, path__default.default.resolve(m), i), /^(?:\.\.?(?:\/|$)|\/|([A-Za-z]:)?[/\\])/.test(t)) {
  if (w = path__default.default.resolve(y, t), "." !== t && ".." !== t && "/" !== t.slice(-1) || (w += "/"), 
  _ = s(w) || o(w)) return maybeRealpathSync(u, _, i);
 } else {
  if (f && isCoreModule(t)) return t;
  if (v = function E(e, t) {
   var r, n, a, l, u = function() {
    return getPackageCandidates(e, t, i);
   }, d = h ? h(e, t, u, i) : u();
   for (r = 0; r < d.length; r++) if (n = d[r], c(path__default.default.dirname(n))) {
    if (a = s(n)) return a;
    if (l = o(n)) return l;
   }
  }(t, y), v) return maybeRealpathSync(u, v, i);
 }
 throw (b = new Error("Cannot find module '" + t + "' from '" + g + "'")).code = "MODULE_NOT_FOUND", 
 b;
}, async.core = core_1, async.isCore = isCore, async.sync = sync, resolve = async;

const COMMON_DIR_MODULE_EXTS = [ ".tsx", ".ts", ".mjs", ".js", ".jsx", ".json", ".md" ], COMMON_DIR_FILENAMES = [ "package.json", "index.js", "index.mjs" ], getCommonDirName = (e, t) => e + "/" + t, isCommonDirModuleFile = e => COMMON_DIR_MODULE_EXTS.some((t => e.endsWith(t))), shouldFetchModule = e => IS_FETCH_ENV && IS_BROWSER_ENV && isNodeModulePath(e), isNodeModulePath = e => normalizePath(e).split("/").includes("node_modules"), getPackageDirPath = (e, t) => {
 const r = normalizePath(e).split("/"), s = (e => {
  e.startsWith("~") && (e = e.substring(1));
  const t = e.split("/"), r = {
   moduleId: null,
   filePath: null,
   scope: null,
   scopeSubModuleId: null
  };
  return e.startsWith("@") && t.length > 1 ? (r.moduleId = t.slice(0, 2).join("/"), 
  r.filePath = t.slice(2).join("/"), r.scope = t[0], r.scopeSubModuleId = t[1]) : (r.moduleId = t[0], 
  r.filePath = t.slice(1).join("/")), r;
 })(t);
 for (let e = r.length - 1; e >= 1; e--) if ("node_modules" === r[e - 1]) if (s.scope) {
  if (r[e] === s.scope && r[e + 1] === s.scopeSubModuleId) return r.slice(0, e + 2).join("/");
 } else if (r[e] === s.moduleId) return r.slice(0, e + 1).join("/");
 return null;
}, packageVersions = new Map, known404Urls = new Set, getCommonDirUrl = (e, t, r, s) => getNodeModuleFetchUrl(e, t, r) + "/" + s, getNodeModuleFetchUrl = (e, t, r) => {
 let s = (r = normalizePath(r)).split("/").filter((e => e.length));
 const n = s.lastIndexOf("node_modules");
 n > -1 && n < s.length - 1 && (s = s.slice(n + 1));
 let o = s.shift();
 o.startsWith("@") && (o += "/" + s.shift());
 const i = s.join("/");
 return "@stencil/core" === o ? ((e, t) => {
  let r = (t = normalizePath(t)).split("/");
  const s = r.lastIndexOf("node_modules");
  s > -1 && s < r.length - 1 && (r = r.slice(s + 1), r = r[0].startsWith("@") ? r.slice(2) : r.slice(1), 
  t = r.join("/"));
  const n = new URL("../", e).href;
  return new URL("./" + t, n).href;
 })(e.getCompilerExecutingPath(), i) : e.getRemoteModuleUrl({
  moduleId: o,
  version: t.get(o),
  path: i
 });
}, knownUrlSkips = [ "/@stencil/core/internal.js", "/@stencil/core/internal.json", "/@stencil/core/internal.mjs", "/@stencil/core/internal/stencil-core.js/index.json", "/@stencil/core/internal/stencil-core.js.json", "/@stencil/core/internal/stencil-core.js/package.json", "/@stencil/core.js", "/@stencil/core.json", "/@stencil/core.mjs", "/@stencil/core.css", "/@stencil/core/index.js", "/@stencil/core/index.json", "/@stencil/core/index.mjs", "/@stencil/core/index.css", "/@stencil/package.json" ], fetchModuleAsync = async (e, t, r, s, n) => {
 if (!((e => {
  if (!(e => e.endsWith(".d.ts"))(t = e) && t.endsWith(".ts") || (e => e.endsWith(".tsx"))(e)) return !0;
  var t;
  const r = e.split("/"), s = r[r.length - 2], n = r[r.length - 1];
  return !("node_modules" !== s || !isCommonDirModuleFile(n));
 })(n) || known404Urls.has(s) || (e => knownUrlSkips.some((t => e.endsWith(t))))(s))) try {
  const o = await ((e, t, r) => e && isFunction(e.fetch) ? e.fetch(t, r) : fetch(t, r))(e, s);
  if (o) {
   if (o.ok) {
    const i = await o.clone().text();
    return await (async (e, t, r, s, n, o) => {
     r.endsWith("package.json") && ((e, t) => {
      try {
       const r = JSON.parse(t);
       r.name && r.version && ((e, t, r) => {
        e.set(t, r);
       })(e, r.name, r.version);
      } catch (e) {}
     })(o, n);
     let i = path$2.dirname(s);
     for (;"/" !== i && "" !== i; ) t ? (t.clearFileCache(i), await t.sys.createDir(i)) : await e.createDir(i), 
     i = path$2.dirname(i);
     t ? (t.clearFileCache(s), await t.sys.writeFile(s, n)) : await e.writeFile(s, n);
    })(e, t, s, n, i, r), i;
   }
   404 === o.status && known404Urls.add(s);
  }
 } catch (e) {
  console.error(e);
 }
}, createSystem = e => {
 var t;
 const r = null !== (t = null == e ? void 0 : e.logger) && void 0 !== t ? t : (() => {
  let e = IS_BROWSER_ENV, t = "info";
  return {
   enableColors: t => e = t,
   getLevel: () => t,
   setLevel: e => t = e,
   emoji: e => e,
   info: console.log.bind(console),
   warn: console.warn.bind(console),
   error: console.error.bind(console),
   debug: console.debug.bind(console),
   red: e => e,
   green: e => e,
   yellow: e => e,
   blue: e => e,
   magenta: e => e,
   cyan: e => e,
   gray: e => e,
   bold: e => e,
   dim: e => e,
   bgRed: e => e,
   createTimeSpan: (e, t = !1) => ({
    duration: () => 0,
    finish: () => 0
   }),
   printDiagnostics(t) {
    t.forEach((t => ((e, t) => {
     let r = BLUE, s = "Build", n = "";
     "error" === e.level ? (r = RED, s = "Error") : "warn" === e.level && (r = YELLOW, 
     s = "Warning"), e.header && (s = e.header);
     const o = e.relFilePath || e.absFilePath;
     if (o && (n += o, "number" == typeof e.lineNumber && e.lineNumber > 0 && (n += ", line " + e.lineNumber, 
     "number" == typeof e.columnNumber && e.columnNumber > 0 && (n += ", column " + e.columnNumber)), 
     n += "\n"), n += e.messageText, e.lines && e.lines.length > 0 && (e.lines.forEach((e => {
      n += "\n" + e.lineNumber + ":  " + e.text;
     })), n += "\n"), t) {
      const e = [ "%c" + s, `background: ${r}; color: white; padding: 2px 3px; border-radius: 2px; font-size: 0.8em;` ];
      console.log(...e, n);
     } else "error" === e.level ? console.error(n) : "warn" === e.level ? console.warn(n) : console.log(n);
    })(t, e)));
   }
  };
 })(), s = new Map, n = new Set, o = e => n.add(e), i = e => n.delete(e), a = buildEvents(), l = IS_BROWSER_ENV && navigator.hardwareConcurrency || 1, c = e => {
  if ("/" === e || "" === e) return "/";
  const t = path$2.dirname(e), r = path$2.basename(e);
  return t.endsWith("/") ? normalizePath(`${t}${r}`) : normalizePath(`${t}/${r}`);
 }, u = e => {
  const t = s.get(c(e));
  return !(!t || !(t.isDirectory || t.isFile && "string" == typeof t.data));
 }, d = (e, t) => {
  e = c(e);
  const r = {
   basename: path$2.basename(e),
   dirname: path$2.dirname(e),
   path: e,
   newDirs: [],
   error: null
  };
  return h(e, t, r), r;
 }, h = (e, t, r) => {
  const n = path$2.dirname(e);
  t && t.recursive && !(e => "/" === e || windowsPathRegex.test(e))(n) && h(n, t, r);
  const o = s.get(e);
  o ? (o.isDirectory = !0, o.isFile = !1) : (s.set(e, {
   basename: path$2.basename(e),
   dirname: n,
   isDirectory: !0,
   isFile: !1,
   watcherCallbacks: null,
   data: void 0
  }), r.newDirs.push(e), b(e, new Set));
 }, p = e => {
  e = c(e);
  const t = [], r = s.get(e);
  return r && r.isDirectory && s.forEach(((r, s) => {
   "/" !== s && (r.isDirectory || r.isFile && "string" == typeof r.data) && (e.endsWith("/") && `${e}${r.basename}` === s || `${e}/${r.basename}` === s) && t.push(s);
  })), t.sort();
 }, f = e => {
  e = c(e);
  const t = s.get(e);
  if (t && t.isFile) return t.data;
 }, m = e => ({
  path: c(e),
  error: null
 }), g = (e, t, r) => {
  const n = _(e);
  if (!n.error && !r.error) if (n.isFile) {
   const n = path$2.dirname(t), o = d(n, {
    recursive: !0
   }), i = s.get(e).data, a = E(t, i);
   r.newDirs.push(...o.newDirs), r.renamed.push({
    oldPath: e,
    newPath: t,
    isDirectory: !1,
    isFile: !0
   }), a.error ? r.error = a.error : r.newFiles.push(t);
  } else if (n.isDirectory) {
   const s = p(e), n = d(t, {
    recursive: !0
   });
   r.newDirs.push(...n.newDirs), r.renamed.push({
    oldPath: e,
    newPath: t,
    isDirectory: !0,
    isFile: !1
   });
   for (const n of s) {
    const s = n.replace(e, t);
    g(n, s, r);
   }
  }
 }, y = (e, t = {}) => {
  const r = {
   basename: path$2.basename(e),
   dirname: path$2.dirname(e),
   path: e,
   removedDirs: [],
   removedFiles: [],
   error: null
  };
  return w(e, t, r), r;
 }, w = (e, t, r) => {
  if (!r.error) {
   e = c(e);
   const n = p(e);
   if (t && t.recursive) for (const e of n) {
    const n = s.get(e);
    if (n) if (n.isDirectory) w(e, t, r); else if (n.isFile) {
     const t = v(e);
     t.error ? r.error = t.error : r.removedFiles.push(e);
    }
   } else if (n.length > 0) return void (r.error = "cannot delete directory that contains files/subdirectories");
   s.delete(e), b(e, new Set), r.removedDirs.push(e);
  }
 }, _ = e => {
  e = c(e);
  const t = s.get(e);
  return t && (t.isDirectory || t.isFile && "string" == typeof t.data) ? {
   isDirectory: t.isDirectory,
   isFile: t.isFile,
   isSymbolicLink: !1,
   size: t.isFile && t.data ? t.data.length : 0,
   error: null
  } : {
   isDirectory: !1,
   isFile: !1,
   isSymbolicLink: !1,
   size: 0,
   error: `ENOENT: no such file or directory, statSync '${e}'`
  };
 }, v = e => {
  e = c(e);
  const t = {
   basename: path$2.basename(e),
   dirname: path$2.dirname(e),
   path: e,
   error: null
  }, r = s.get(e);
  if (r) {
   if (r.watcherCallbacks) for (const t of r.watcherCallbacks) t(e, "fileDelete");
   s.delete(e), b(e, new Set);
  }
  return t;
 }, b = (e, t) => {
  const r = c(path$2.dirname(e)), n = s.get(r);
  if (n && n.isDirectory && n.watcherCallbacks) for (const t of n.watcherCallbacks) t(e, null);
  t.has(r) || (t.add(r), b(r, t));
 }, E = (e, t) => {
  const r = {
   path: e = c(e),
   error: null
  }, n = s.get(e);
  if (n) {
   const r = n.data !== t;
   if (n.data = t, r && n.watcherCallbacks) for (const t of n.watcherCallbacks) t(e, "fileUpdate");
  } else s.set(e, {
   basename: path$2.basename(e),
   dirname: path$2.dirname(e),
   isDirectory: !1,
   isFile: !0,
   watcherCallbacks: null,
   data: t
  }), b(e, new Set);
  return r;
 }, T = "undefined" != typeof self ? null === self || void 0 === self ? void 0 : self.fetch : "undefined" != typeof window ? null === window || void 0 === window ? void 0 : window.fetch : "undefined" != typeof global ? null === global || void 0 === global ? void 0 : global.fetch : void 0, S = Promise.resolve();
 d("/");
 const C = {
  name: "in-memory",
  version: "2.22.3",
  events: a,
  access: async e => u(e),
  accessSync: u,
  addDestory: o,
  copyFile: async (e, t) => (E(t, f(e)), !0),
  createDir: async (e, t) => d(e, t),
  createDirSync: d,
  homeDir: () => os__namespace.homedir(),
  isTTY: () => {
   var e;
   return !!(null === (e = null == process__namespace ? void 0 : process__namespace.stdout) || void 0 === e ? void 0 : e.isTTY);
  },
  getEnvironmentVar: e => null == process__namespace ? void 0 : process__namespace.env[e],
  destroy: async () => {
   const e = [];
   n.forEach((t => {
    try {
     const r = t();
     r && r.then && e.push(r);
    } catch (e) {
     r.error(`stencil sys destroy: ${e}`);
    }
   })), await Promise.all(e), n.clear();
  },
  encodeToBase64: e => btoa(unescape(encodeURIComponent(e))),
  exit: async e => r.warn(`exit ${e}`),
  getCurrentDirectory: () => "/",
  getCompilerExecutingPath: () => IS_WEB_WORKER_ENV ? location.href : C.getRemoteModuleUrl({
   moduleId: "@stencil/core",
   path: "compiler/stencil.min.js"
  }),
  getLocalModulePath: e => path$2.join(e.rootDir, "node_modules", e.moduleId, e.path),
  getRemoteModuleUrl: e => {
   const t = `${e.moduleId}${e.version ? "@" + e.version : ""}/${e.path}`;
   return new URL(t, "https://cdn.jsdelivr.net/npm/").href;
  },
  hardwareConcurrency: l,
  isSymbolicLink: async e => !1,
  nextTick: e => S.then(e),
  normalizePath: c,
  platformPath: pathBrowserify,
  readDir: async e => p(e),
  readDirSync: p,
  readFile: async e => f(e),
  readFileSync: f,
  realpath: async e => m(e),
  realpathSync: m,
  removeDestory: i,
  rename: async (e, t) => {
   const r = {
    oldPath: e = normalizePath(e),
    newPath: t = normalizePath(t),
    renamed: [],
    oldDirs: [],
    oldFiles: [],
    newDirs: [],
    newFiles: [],
    isFile: !1,
    isDirectory: !1,
    error: null
   }, s = _(e);
   if (s.error) r.error = `${e} does not exist`; else if (s.isFile ? r.isFile = !0 : s.isDirectory && (r.isDirectory = !0), 
   g(e, t, r), !r.error) if (r.isDirectory) {
    const t = y(e, {
     recursive: !0
    });
    t.error ? r.error = t.error : (r.oldDirs.push(...t.removedDirs), r.oldFiles.push(...t.removedFiles));
   } else if (r.isFile) {
    const t = v(e);
    t.error ? r.error = t.error : r.oldFiles.push(e);
   }
   return r;
  },
  fetch: T,
  resolvePath: e => c(e),
  removeDir: async (e, t = {}) => y(e, t),
  removeDirSync: y,
  stat: async e => _(e),
  statSync: _,
  tmpDirSync: () => "/.tmp",
  removeFile: async e => v(e),
  removeFileSync: v,
  watchDirectory: (e, t) => {
   e = c(e);
   const r = s.get(e), n = () => {
    const r = s.get(e);
    if (r && r.watcherCallbacks) {
     const e = r.watcherCallbacks.indexOf(t);
     e > -1 && r.watcherCallbacks.splice(e, 1);
    }
   };
   return o(n), r ? (r.isDirectory = !0, r.isFile = !1, r.watcherCallbacks = r.watcherCallbacks || [], 
   r.watcherCallbacks.push(t)) : s.set(e, {
    basename: path$2.basename(e),
    dirname: path$2.dirname(e),
    isDirectory: !0,
    isFile: !1,
    watcherCallbacks: [ t ],
    data: void 0
   }), {
    close() {
     i(n), n();
    }
   };
  },
  watchFile: (e, t) => {
   e = c(e);
   const r = s.get(e), n = () => {
    const r = s.get(e);
    if (r && r.watcherCallbacks) {
     const e = r.watcherCallbacks.indexOf(t);
     e > -1 && r.watcherCallbacks.splice(e, 1);
    }
   };
   return o(n), r ? (r.isDirectory = !1, r.isFile = !0, r.watcherCallbacks = r.watcherCallbacks || [], 
   r.watcherCallbacks.push(t)) : s.set(e, {
    basename: path$2.basename(e),
    dirname: path$2.dirname(e),
    isDirectory: !1,
    isFile: !0,
    watcherCallbacks: [ t ],
    data: void 0
   }), {
    close() {
     i(n), n();
    }
   };
  },
  watchTimeout: 32,
  writeFile: async (e, t) => E(e, t),
  writeFileSync: E,
  generateContentHash: async (e, t) => {
   const r = await crypto.subtle.digest("SHA-256", (new TextEncoder).encode(e));
   let s = Array.from(new Uint8Array(r)).map((e => e.toString(16).padStart(2, "0"))).join("");
   return "number" == typeof t && (s = s.slice(0, t)), s;
  },
  createWorkerController: HAS_WEB_WORKER ? e => ((e, t) => {
   let r, s = 0, n = !1, o = !1, i = 0;
   const a = new Map, l = [], c = [], u = Math.max(Math.min(t, e.hardwareConcurrency), 2) - 1, d = Promise.resolve(), h = e => console.error(e), p = () => {
    let t = null;
    const s = e.getCompilerExecutingPath(), o = {
     name: "stencil.worker." + i++
    };
    try {
     t = new Worker(s, o);
    } catch (e) {
     null == r && (r = new Blob([ `importScripts('${s}');` ], {
      type: "application/javascript"
     })), t = new Worker(URL.createObjectURL(r), o);
    }
    const l = {
     worker: t,
     activeTasks: 0,
     sendQueue: []
    };
    return t.onerror = h, t.onmessage = e => ((e, t) => {
     if (!n) {
      const r = t.data;
      if (Array.isArray(r)) for (const t of r) if (t) {
       const r = a.get(t.stencilId);
       r ? (a.delete(t.stencilId), t.stencilRtnError ? r.reject(t.stencilRtnError) : r.resolve(t.stencilRtnValue), 
       e.activeTasks--, (e.activeTasks < 0 || e.activeTasks > 50) && (e.activeTasks = 0)) : t.stencilRtnError && console.error(t.stencilRtnError);
      }
     }
    })(l, e), l;
   }, f = e => {
    e.sendQueue.length > 0 && (e.worker.postMessage(e.sendQueue), e.sendQueue.length = 0);
   }, m = e => {
    let t;
    if (c.length > 0) {
     if (t = c[0], u > 1) {
      for (const e of c) e.activeTasks < t.activeTasks && (t = e);
      t.activeTasks > 0 && c.length < u && (t = p(), c.push(t));
     }
    } else t = p(), c.push(t);
    t.activeTasks++, t.sendQueue.push(e);
   }, g = () => {
    o = !1, l.forEach(m), l.length = 0, c.forEach(f);
   }, y = (...e) => new Promise(((t, r) => {
    if (n) r("task canceled"); else {
     const n = {
      stencilId: s++,
      args: e
     };
     l.push(n), a.set(n.stencilId, {
      resolve: t,
      reject: r
     }), o || (o = !0, d.then(g));
    }
   }));
   return {
    send: y,
    destroy: () => {
     n = !0, a.forEach((e => e.reject("task canceled"))), a.clear(), c.forEach((e => e.worker.terminate())), 
     c.length = 0;
    },
    handler: e => function(...t) {
     return y(e, ...t);
    },
    maxWorkers: u
   };
  })(C, e) : null,
  details: {
   cpuModel: "",
   freemem: () => 0,
   platform: "",
   release: "",
   totalmem: 0
  },
  copy: async (e, t) => (r.info("todo, copy task", e.length, t), {
   diagnostics: [],
   dirPaths: [],
   filePaths: []
  })
 };
 return C.resolveModuleId = e => ((e, t, r) => {
  const s = ((e, t, r) => ({
   async isFile(s, n) {
    const o = normalizeFsPath(s);
    if ((await t.stat(o)).isFile) n(null, !0); else {
     if (shouldFetchModule(o) && r.some((e => o.endsWith(e)))) {
      const r = getNodeModuleFetchUrl(e, packageVersions, o);
      return void n(null, "string" == typeof await fetchModuleAsync(e, t, packageVersions, r, o));
     }
     n(null, !1);
    }
   },
   async isDirectory(r, s) {
    const n = normalizeFsPath(r);
    if ((await t.stat(n)).isDirectory) s(null, !0); else {
     if (shouldFetchModule(n)) {
      if ("node_modules" === path$2.basename(n)) return t.sys.createDirSync(n), t.clearFileCache(n), 
      void s(null, !0);
      if (isCommonDirModuleFile(n)) return void s(null, !1);
      for (const r of COMMON_DIR_FILENAMES) {
       const o = getCommonDirUrl(e, packageVersions, n, r), i = getCommonDirName(n, r), a = await fetchModuleAsync(e, t, packageVersions, o, i);
       if (isString(a)) return void s(null, !0);
      }
     }
     s(null, !1);
    }
   },
   async readFile(e, r) {
    const s = normalizeFsPath(e), n = await t.readFile(s);
    return isString(n) ? r(null, n) : r(`readFile not found: ${e}`);
   },
   async realpath(t, r) {
    const s = normalizeFsPath(t), n = await e.realpath(s);
    n.error && "ENOENT" !== n.error.code ? r(n.error) : r(null, n.error ? s : n.path);
   },
   extensions: r
  }))(e, null, r.exts);
  return s.basedir = path$2.dirname(normalizeFsPath(r.containingFile)), r.packageFilter ? s.packageFilter = r.packageFilter : null !== r.packageFilter && (s.packageFilter = e => (isString(e.main) && "" !== e.main || (e.main = "package.json"), 
  e)), new Promise(((e, t) => {
   resolve(r.moduleId, s, ((s, n, o) => {
    if (s) t(s); else {
     n = normalizePath(n);
     const t = {
      moduleId: r.moduleId,
      resolveId: n,
      pkgData: o,
      pkgDirPath: getPackageDirPath(n, r.moduleId)
     };
     e(t);
    }
   }));
  }));
 })(C, 0, e), C;
}, createTestingSystem = () => {
 let e = 0, t = 0;
 const r = createSystem();
 r.platformPath = path__default.default, r.generateContentHash = (e, t) => {
  let r = crypto$3.createHash("sha1").update(e).digest("hex").toLowerCase();
  return "number" == typeof t && (r = r.slice(0, t)), Promise.resolve(r);
 };
 const s = t => {
  const r = t;
  return (...t) => (e++, r.apply(r, t));
 }, n = e => {
  const r = e;
  return (...e) => (t++, r.apply(r, e));
 };
 if (r.access = s(r.access), r.accessSync = s(r.accessSync), r.homeDir = s(r.homeDir), 
 r.readFile = s(r.readFile), r.readFileSync = s(r.readFileSync), r.readDir = s(r.readDir), 
 r.readDirSync = s(r.readDirSync), r.stat = s(r.stat), r.statSync = s(r.statSync), 
 r.copyFile = n(r.copyFile), r.createDir = n(r.createDir), r.createDirSync = n(r.createDirSync), 
 r.removeFile = n(r.removeFile), r.removeFileSync = n(r.removeFileSync), r.writeFile = n(r.writeFile), 
 r.writeFileSync = n(r.writeFileSync), r.getCompilerExecutingPath = () => "bin/stencil.js", 
 Object.defineProperties(r, {
  diskReads: {
   get: () => e,
   set(t) {
    e = t;
   }
  },
  diskWrites: {
   get: () => t,
   set(e) {
    t = e;
   }
  }
 }), !function o(e) {
  return "diskReads" in e && "diskWrites" in e;
 }(r)) throw new Error("could not generate TestingSystem");
 return r;
};

class EventSpy {
 constructor(e) {
  this.eventName = e, this.events = [], this.cursor = 0, this.queuedHandler = [];
 }
 get length() {
  return this.events.length;
 }
 get firstEvent() {
  return this.events[0] || null;
 }
 get lastEvent() {
  return this.events[this.events.length - 1] || null;
 }
 next() {
  const e = this.cursor;
  this.cursor++;
  const t = this.events[e];
  if (t) return Promise.resolve({
   done: !1,
   value: t
  });
  {
   let t;
   const r = new Promise((e => t = e));
   return this.queuedHandler.push(t), r.then((() => ({
    done: !1,
    value: this.events[e]
   })));
  }
 }
 push(e) {
  this.events.push(e);
  const t = this.queuedHandler.shift();
  t && t();
 }
}

class E2EElement extends index_cjs.MockHTMLElement {
 _queueAction(e) {
  this._queuedActions.push(e);
 }
 constructor(e, t) {
  super(null, null), this._page = e, this._elmHandle = t, this._queuedActions = [], 
  e._e2eElements.push(this);
 }
 find(e) {
  return find(this._page, this._elmHandle, e);
 }
 findAll(e) {
  return findAll(this._page, this._elmHandle, e);
 }
 callMethod(e, ...t) {
  return this._queueAction({
   methodName: e,
   methodArgs: t
  }), this.e2eRunActions();
 }
 triggerEvent(e, t) {
  this._queueAction({
   eventName: e,
   eventInitDict: t
  });
 }
 async spyOnEvent(e) {
  const t = new EventSpy(e);
  return await addE2EListener(this._page, this._elmHandle, e, (e => {
   t.push(e);
  })), t;
 }
 async click(e) {
  await this._elmHandle.click(e), await this._page.waitForChanges();
 }
 async focus() {
  await this._elmHandle.focus(), await this._page.waitForChanges();
 }
 async hover() {
  await this._elmHandle.hover(), await this._page.waitForChanges();
 }
 async isVisible() {
  this._validate();
  let e = !1;
  try {
   const t = this._elmHandle.executionContext();
   e = await t.evaluate((e => new Promise((t => {
    window.requestAnimationFrame((() => {
     if (e.isConnected) {
      const r = window.getComputedStyle(e);
      r && "none" !== r.display && "hidden" !== r.visibility && "0" !== r.opacity ? window.requestAnimationFrame((() => {
       e.clientWidth, t(!0);
      })) : t(!1);
     } else t(!1);
    }));
   }))), this._elmHandle);
  } catch (e) {}
  return e;
 }
 waitForEvent(e) {
  return waitForEvent(this._page, e, this._elmHandle);
 }
 waitForVisible() {
  return new Promise(((e, t) => {
   const r = setInterval((async () => {
    await this.isVisible() && (clearInterval(r), clearTimeout(o), e());
   }), 10), s = .5 * jasmine.DEFAULT_TIMEOUT_INTERVAL, n = new Error(`waitForVisible timed out: ${s}ms`), o = setTimeout((() => {
    clearTimeout(r), t(n);
   }), s);
  }));
 }
 waitForNotVisible() {
  return new Promise(((e, t) => {
   const r = setInterval((async () => {
    await this.isVisible() || (clearInterval(r), clearTimeout(o), e());
   }), 10), s = .5 * jasmine.DEFAULT_TIMEOUT_INTERVAL, n = new Error(`waitForNotVisible timed out: ${s}ms`), o = setTimeout((() => {
    clearTimeout(r), t(n);
   }), s);
  }));
 }
 isIntersectingViewport() {
  return this._elmHandle.isIntersectingViewport();
 }
 async press(e, t) {
  await this._elmHandle.press(e, t), await this._page.waitForChanges();
 }
 async tap() {
  await this._elmHandle.tap(), await this._page.waitForChanges();
 }
 async type(e, t) {
  await this._elmHandle.type(e, t), await this._page.waitForChanges();
 }
 async getProperty(e) {
  this._validate();
  const t = this._elmHandle.executionContext();
  return await t.evaluate(((e, t) => e[t]), this._elmHandle, e);
 }
 setProperty(e, t) {
  this._queueAction({
   setPropertyName: e,
   setPropertyValue: t
  });
 }
 getAttribute(e) {
  return this._validate(), super.getAttribute(e);
 }
 setAttribute(e, t) {
  this._queueAction({
   setAttributeName: e,
   setAttributeValue: t
  });
 }
 removeAttribute(e) {
  this._queueAction({
   removeAttribute: e
  });
 }
 toggleAttribute(e, t) {
  this._queueAction({
   toggleAttributeName: e,
   toggleAttributeForce: t
  });
 }
 get classList() {
  return {
   add: (...e) => {
    e.forEach((e => {
     this._queueAction({
      classAdd: e
     });
    }));
   },
   remove: (...e) => {
    e.forEach((e => {
     this._queueAction({
      classRemove: e
     });
    }));
   },
   toggle: e => {
    this._queueAction({
     classToggle: e
    });
   },
   contains: e => (this._validate(), super.className.split(" ").includes(e))
  };
 }
 get className() {
  return this._validate(), super.className;
 }
 set className(e) {
  this._queueAction({
   setPropertyName: "className",
   setPropertyValue: e
  });
 }
 get id() {
  return this._validate(), super.id;
 }
 set id(e) {
  this._queueAction({
   setPropertyName: "id",
   setPropertyValue: e
  });
 }
 get innerHTML() {
  return this._validate(), super.innerHTML;
 }
 set innerHTML(e) {
  this._queueAction({
   setPropertyName: "innerHTML",
   setPropertyValue: e
  });
 }
 get innerText() {
  return this._validate(), super.innerText;
 }
 set innerText(e) {
  this._queueAction({
   setPropertyName: "innerText",
   setPropertyValue: e
  });
 }
 get nodeValue() {
  return this._validate(), super.nodeValue;
 }
 set nodeValue(e) {
  "string" == typeof e && this._queueAction({
   setPropertyName: "nodeValue",
   setPropertyValue: e
  });
 }
 get outerHTML() {
  return this._validate(), super.outerHTML;
 }
 set outerHTML(e) {
  throw new Error("outerHTML is read-only");
 }
 get shadowRoot() {
  return this._validate(), super.shadowRoot;
 }
 set shadowRoot(e) {
  super.shadowRoot = e;
 }
 get tabIndex() {
  return this._validate(), super.tabIndex;
 }
 set tabIndex(e) {
  this._queueAction({
   setPropertyName: "tabIndex",
   setPropertyValue: e
  });
 }
 get textContent() {
  return this._validate(), super.textContent;
 }
 set textContent(e) {
  this._queueAction({
   setPropertyName: "textContent",
   setPropertyValue: e
  });
 }
 get title() {
  return this._validate(), super.title;
 }
 set title(e) {
  this._queueAction({
   setPropertyName: "title",
   setPropertyValue: e
  });
 }
 async getComputedStyle(e) {
  const t = await this._page.evaluate(((e, t) => {
   const r = {}, s = window.getComputedStyle(e, t);
   return Object.keys(s).forEach((e => {
    if (isNaN(e)) {
     const t = s[e];
     null != t && (r[e] = t);
    } else {
     const t = s[e];
     if (t.includes("-")) {
      const e = s.getPropertyValue(t);
      null != e && (r[t] = e);
     }
    }
   })), r;
  }), this._elmHandle, e);
  return t.getPropertyValue = e => t[e], t;
 }
 async e2eRunActions() {
  if (0 === this._queuedActions.length) return;
  const e = this._elmHandle.executionContext(), t = await e.evaluate(((e, t) => e.componentOnReady().then((() => {
   let r = null;
   return t.forEach((t => {
    if (t.methodName) r = e[t.methodName].apply(e, t.methodArgs); else if (t.setPropertyName) e[t.setPropertyName] = t.setPropertyValue; else if (t.setAttributeName) e.setAttribute(t.setAttributeName, t.setAttributeValue); else if (t.removeAttribute) e.removeAttribute(t.removeAttribute); else if (t.toggleAttributeName) "boolean" == typeof t.toggleAttributeForce ? e.toggleAttribute(t.toggleAttributeName, t.toggleAttributeForce) : e.toggleAttribute(t.toggleAttributeName); else if (t.classAdd) e.classList.add(t.classAdd); else if (t.classRemove) e.classList.remove(t.classRemove); else if (t.classToggle) e.classList.toggle(t.classToggle); else if (t.eventName) {
     const r = t.eventInitDict || {};
     "boolean" != typeof r.bubbles && (r.bubbles = !0), "boolean" != typeof r.cancelable && (r.cancelable = !0), 
     "boolean" != typeof r.composed && (r.composed = !0);
     const s = new CustomEvent(t.eventName, r);
     e.dispatchEvent(s);
    }
   })), r && "function" == typeof r.then ? r.then((e => e)) : r;
  }))), this._elmHandle, this._queuedActions);
  return this._queuedActions.length = 0, t;
 }
 async e2eSync() {
  const e = this._elmHandle.executionContext(), {outerHTML: t, shadowRootHTML: r} = await e.evaluate((e => ({
   outerHTML: e.outerHTML,
   shadowRootHTML: e.shadowRoot ? e.shadowRoot.innerHTML : null
  })), this._elmHandle);
  "string" == typeof r ? (this.shadowRoot = index_cjs.parseHtmlToFragment(r), this.shadowRoot.host = this) : this.shadowRoot = null;
  const s = index_cjs.parseHtmlToFragment(t).firstElementChild;
  for (this.nodeName = s.nodeName, this.attributes = index_cjs.cloneAttributes(s.attributes); this.childNodes.length > 0; ) this.removeChild(this.childNodes[0]);
  for (;s.childNodes.length > 0; ) this.appendChild(s.childNodes[0]);
 }
 _validate() {
  if (this._queuedActions.length > 0) throw new Error("await page.waitForChanges() must be called before reading element information");
 }
 async e2eDispose() {
  this._elmHandle && (await this._elmHandle.dispose(), this._elmHandle = null);
  const e = this._page._e2eElements.indexOf(this);
  e > -1 && this._page._e2eElements.splice(e, 1), this._page = null;
 }
}

const env = process.env, isOutputTargetDistLazy = e => e.type === DIST_LAZY, isOutputTargetWww = e => e.type === WWW, DIST_LAZY = "dist-lazy", WWW = "www";

exports.MockHeaders = MockHeaders, exports.MockRequest = MockRequest, exports.MockResponse = MockResponse, 
exports.createJestPuppeteerEnvironment = function createJestPuppeteerEnvironment() {
 const e = require("jest-environment-node");
 return class extends e {
  constructor(e) {
   super(e), this.browser = null, this.pages = [];
  }
  async setup() {
   "true" === process.env.__STENCIL_E2E_TESTS__ && (this.global.__NEW_TEST_PAGE__ = this.newPuppeteerPage.bind(this), 
   this.global.__CLOSE_OPEN_PAGES__ = this.closeOpenPages.bind(this));
  }
  async newPuppeteerPage() {
   this.browser || (this.browser = await async function e() {
    const e = process.env, t = e.__STENCIL_BROWSER_WS_ENDPOINT__;
    if (!t) return null;
    const r = {
     browserWSEndpoint: t,
     ignoreHTTPSErrors: !0
    }, s = require(e.__STENCIL_PUPPETEER_MODULE__);
    return await s.connect(r);
   }());
   const t = await function r(e) {
    return e.newPage();
   }(this.browser);
   this.pages.push(t);
   const s = process.env;
   return "string" == typeof s.__STENCIL_DEFAULT_TIMEOUT__ && t.setDefaultTimeout(parseInt(s.__STENCIL_DEFAULT_TIMEOUT__, 10)), 
   t;
  }
  async closeOpenPages() {
   await Promise.all(this.pages.map((e => e.close()))), this.pages.length = 0;
  }
  async teardown() {
   await super.teardown(), await this.closeOpenPages(), await async function e(t) {
    if (t) try {
     t.disconnect();
    } catch (e) {}
   }(this.browser), this.browser = null;
  }
  getVmContext() {
   return super.getVmContext();
  }
 };
}, exports.createTestRunner = function createTestRunner() {
 var e;
 const t = null !== (e = require("jest-runner").default) && void 0 !== e ? e : require("jest-runner");
 return class r extends t {
  async runTests(e, t, r, s, n, o) {
   const i = process.env;
   if (e = e.filter((e => function t(e, r) {
    const s = (e = e.toLowerCase().replace(/\\/g, "/")).includes(".e2e.") || e.includes("/e2e.");
    return !("true" !== r.__STENCIL_E2E_TESTS__ || !s) || "true" === r.__STENCIL_SPEC_TESTS__ && !s;
   }(e.path, i))), "true" === i.__STENCIL_SCREENSHOT__) {
    const a = JSON.parse(i.__STENCIL_EMULATE_CONFIGS__);
    for (let l = 0; l < a.length; l++) setScreenshotEmulateData(a[l], i), await super.runTests(e, t, r, s, n, o);
   } else await super.runTests(e, t, r, s, n, o);
  }
 };
}, exports.createTesting = async e => {
 e = function t(e) {
  return e.buildEs5 = !1, e.devMode = !0, e.minifyCss = !1, e.minifyJs = !1, e.hashFileNames = !1, 
  e.validateTypes = !1, e._isTesting = !0, e.buildDist = !0, e.flags.serve = !1, e.flags.open = !1, 
  e.outputTargets.forEach((e => {
   "www" === e.type && (e.serviceWorker = null);
  })), e.flags.args.includes("--watchAll") && (e.watch = !0), e;
 }(e);
 const {createCompiler: r} = require("../compiler/stencil.js"), s = await r(e);
 let n, o;
 const i = async () => {
  const t = [];
  e && (e.sys && e.sys.destroy && t.push(e.sys.destroy()), e = null), n && (n.close && t.push(n.close()), 
  n = null), o && (o.close && t.push(o.close()), o = null), await Promise.all(t);
 };
 return {
  destroy: i,
  run: async (t = {}) => {
   let r, a = !1, l = !1, c = null;
   const u = [];
   try {
    if (!t.spec && !t.e2e) return e.logger.error("Testing requires either the --spec or --e2e command line flags, or both. For example, to run unit tests, use the command: stencil test --spec"), 
    !1;
    if (r = process.env, t.e2e && (u.push("e2e"), r.__STENCIL_E2E_TESTS__ = "true"), 
    t.spec && (u.push("spec"), r.__STENCIL_SPEC_TESTS__ = "true"), e.logger.info(e.logger.magenta(`testing ${u.join(" and ")} files${e.watch ? " (watch)" : ""}`)), 
    a = !(!t.e2e || !t.screenshot), a && (r.__STENCIL_SCREENSHOT__ = "true", t.updateScreenshot ? e.logger.info(e.logger.magenta("updating master screenshots")) : e.logger.info(e.logger.magenta("comparing against master screenshots"))), 
    t.e2e) {
     let t = null;
     e.outputTargets.forEach((e => {
      e.empty = !1;
     }));
     const a = !(e.flags && !1 === e.flags.build);
     a && e.watch && (c = await s.createWatcher()), a && (c ? (t = new Promise((e => {
      const t = c.on("buildFinish", (r => {
       t(), e(r);
      }));
     })), c.start()) : t = s.build()), e.devServer.openBrowser = !1, e.devServer.gzip = !1, 
     e.devServer.reloadStrategy = null;
     const l = await Promise.all([ index_js.start(e.devServer, e.logger), startPuppeteerBrowser(e) ]);
     if (n = l[0], o = l[1], t) {
      const r = await t;
      if (!r || !e.watch && hasError(r && r.diagnostics)) return await i(), !1;
     }
     n && (r.__STENCIL_BROWSER_URL__ = n.browserUrl, e.logger.debug(`e2e dev server url: ${r.__STENCIL_BROWSER_URL__}`), 
     r.__STENCIL_APP_SCRIPT_URL__ = function d(e, t) {
      return getAppUrl(e, t, `${e.fsNamespace}.esm.js`);
     }(e, n.browserUrl), e.logger.debug(`e2e app script url: ${r.__STENCIL_APP_SCRIPT_URL__}`), 
     getAppStyleUrl(e, n.browserUrl) && (r.__STENCIL_APP_STYLE_URL__ = getAppStyleUrl(e, n.browserUrl), 
     e.logger.debug(`e2e app style url: ${r.__STENCIL_APP_STYLE_URL__}`)));
    }
   } catch (t) {
    return e.logger.error(t), !1;
   }
   try {
    l = a ? await async function h(e, t) {
     e.logger.debug(`screenshot connector: ${e.testing.screenshotConnector}`);
     const r = new (require(e.testing.screenshotConnector)), s = path$2.join(e.sys.getCompilerExecutingPath(), "..", "..", "screenshot", "pixel-match.js");
     e.logger.debug(`pixelmatch module: ${s}`);
     const n = e.logger.createTimeSpan("screenshot, initBuild started", !0);
     await r.initBuild({
      buildId: createBuildId(),
      buildMessage: createBuildMessage(),
      buildTimestamp: Date.now(),
      appNamespace: e.namespace,
      rootDir: e.rootDir,
      cacheDir: e.cacheDir,
      packageDir: path$2.join(e.sys.getCompilerExecutingPath(), "..", ".."),
      updateMaster: e.flags.updateScreenshot,
      logger: e.logger,
      allowableMismatchedPixels: e.testing.allowableMismatchedPixels,
      allowableMismatchedRatio: e.testing.allowableMismatchedRatio,
      pixelmatchThreshold: e.testing.pixelmatchThreshold,
      waitBeforeScreenshot: e.testing.waitBeforeScreenshot,
      pixelmatchModulePath: s
     }), e.flags.updateScreenshot || await r.pullMasterBuild(), n.finish("screenshot, initBuild finished");
     const o = await Promise.all([ await r.getMasterBuild(), await r.getScreenshotCache() ]), i = o[0], a = o[1];
     t.__STENCIL_SCREENSHOT_BUILD__ = r.toJson(i, a);
     const l = e.logger.createTimeSpan("screenshot, tests started", !0), c = await runJest(e, t);
     l.finish(`screenshot, tests finished, passed: ${c}`);
     try {
      const t = e.logger.createTimeSpan("screenshot, completeTimespan started", !0);
      let s = await r.completeBuild(i);
      if (t.finish("screenshot, completeTimespan finished"), s) {
       const t = e.logger.createTimeSpan("screenshot, publishBuild started", !0);
       if (s = await r.publishBuild(s), t.finish("screenshot, publishBuild finished"), 
       e.flags.updateScreenshot) s.currentBuild && "string" == typeof s.currentBuild.previewUrl && e.logger.info(e.logger.magenta(s.currentBuild.previewUrl)); else if (s.compare) {
        try {
         await r.updateScreenshotCache(a, s);
        } catch (t) {
         e.logger.error(t);
        }
        e.logger.info(`screenshots compared: ${s.compare.diffs.length}`), "string" == typeof s.compare.url && e.logger.info(e.logger.magenta(s.compare.url));
       }
      }
     } catch (t) {
      t instanceof Error ? e.logger.error(t, t.stack) : e.logger.error(t);
     }
     return c;
    }(e, r) : await runJest(e, r), e.logger.info(""), c && await c.close();
   } catch (t) {
    e.logger.error(t);
   }
   return l;
  }
 };
}, exports.jestPreprocessor = jestPreprocessor, exports.jestSetupTestFramework = function jestSetupTestFramework() {
 global.Context = {}, global.resourcesUrl = "/build", expect.extend(expectExtend), 
 expect.addSnapshotSerializer(HtmlSerializer), index_cjs.setupGlobal(global), function e(t) {
  const r = t.window;
  "fetch" in r || (r.fetch = function(e) {
   return globalMockFetch(e);
  }), "fetch" in t || (t.fetch = function(e) {
   return globalMockFetch(e);
  });
 }(global), beforeEach((() => {
  testing.resetPlatform(), testing.setErrorHandler(void 0), resetBuildConditionals(appData.BUILD), 
  testing.modeResolutionChain.length = 0;
 })), afterEach((async () => {
  global.__CLOSE_OPEN_PAGES__ && await global.__CLOSE_OPEN_PAGES__(), testing.stopAutoApplyChanges(), 
  index_cjs.teardownGlobal(global), global.Context = {}, global.resourcesUrl = "/build";
 }));
 const t = jasmine.getEnv();
 null != t && t.addReporter({
  specStarted: e => {
   global.currentSpec = e;
  }
 }), global.screenshotDescriptions = new Set;
 const r = process.env;
 if ("string" == typeof r.__STENCIL_DEFAULT_TIMEOUT__) {
  const e = parseInt(r.__STENCIL_DEFAULT_TIMEOUT__, 10);
  jest.setTimeout(1.5 * e), jasmine.DEFAULT_TIMEOUT_INTERVAL = e;
 }
 if ("string" == typeof r.__STENCIL_ENV__) {
  const e = JSON.parse(r.__STENCIL_ENV__);
  Object.assign(appData.Env, e);
 }
}, exports.mockBuildCtx = function mockBuildCtx(e, t) {
 return e || (e = mockConfig()), t || (t = mockCompilerCtx(e)), new BuildContext(e, t);
}, exports.mockCompilerCtx = mockCompilerCtx, exports.mockCompilerSystem = function mockCompilerSystem() {
 return createTestingSystem();
}, exports.mockConfig = mockConfig, exports.mockDocument = function mockDocument(e = null) {
 return new index_cjs.MockWindow(e).document;
}, exports.mockFetch = mockFetch, exports.mockLoadConfigInit = e => ({
 config: {},
 configPath: void 0,
 initTsConfig: !0,
 logger: void 0,
 sys: void 0,
 ...e
}), exports.mockLogger = mockLogger, exports.mockModule = (e = {}) => ({
 cmps: [],
 coreRuntimeApis: [],
 collectionName: "",
 dtsFilePath: "",
 excludeFromCollection: !1,
 externalImports: [],
 htmlAttrNames: [],
 htmlTagNames: [],
 htmlParts: [],
 isCollectionDependency: !1,
 isLegacy: !1,
 jsFilePath: "",
 localImports: [],
 originalImports: [],
 originalCollectionComponentPath: "",
 potentialCmpRefs: [],
 sourceFilePath: "",
 staticSourceFile: "",
 staticSourceFileText: "",
 sourceMapPath: "",
 sourceMapFileText: "",
 hasVdomAttribute: !1,
 hasVdomClass: !1,
 hasVdomFunctional: !1,
 hasVdomKey: !1,
 hasVdomListener: !1,
 hasVdomPropOrAttr: !1,
 hasVdomRef: !1,
 hasVdomRender: !1,
 hasVdomStyle: !1,
 hasVdomText: !1,
 hasVdomXlink: !1,
 ...e
}), exports.mockValidatedConfig = function mockValidatedConfig(e = {}) {
 var t;
 const r = mockConfig(e);
 return {
  ...r,
  flags: createConfigFlags(),
  logger: mockLogger(),
  outputTargets: null !== (t = r.outputTargets) && void 0 !== t ? t : [],
  rootDir: path__default.default.resolve("/"),
  sys: createTestingSystem(),
  testing: {},
  ...e
 };
}, exports.mockWindow = function mockWindow(e = null) {
 return new index_cjs.MockWindow(e);
}, exports.newE2EPage = async function newE2EPage(e = {}) {
 if (!global.__NEW_TEST_PAGE__) throw new Error("newE2EPage() is only available from E2E tests, and ran with the --e2e cmd line flag.");
 const t = await global.__NEW_TEST_PAGE__(), r = [];
 try {
  t._e2eElements = [], t._e2eGoto = t.goto, t._e2eClose = t.close, await async function s(e) {
   if (e.isClosed()) return;
   const t = env.__STENCIL_EMULATE__;
   if (!t) return;
   const r = JSON.parse(t), s = {
    viewport: r.viewport,
    userAgent: r.userAgent
   };
   await e.emulate(s);
  }(t), await t.setCacheEnabled(!1), await initPageEvents(t), function n(e) {
   const t = process.env;
   "true" === t.__STENCIL_SCREENSHOT__ ? e.compareScreenshot = (r, s) => {
    const n = global;
    let o, i = "", a = "";
    if (n.currentSpec && ("string" == typeof n.currentSpec.fullName && (i = n.currentSpec.fullName), 
    "string" == typeof n.currentSpec.testPath && (a = n.currentSpec.testPath)), "string" == typeof r ? (i.length > 0 ? i += ", " + r : i = r, 
    "object" == typeof s && (o = s)) : "object" == typeof r && (o = r), i = i.trim(), 
    o = o || {}, !i) throw new Error(`Invalid screenshot description in "${a}"`);
    if (n.screenshotDescriptions.has(i)) throw new Error(`Screenshot description "${i}" found in "${a}" cannot be used for multiple screenshots and must be unique. To make screenshot descriptions unique within the same test, use the first argument to "compareScreenshot", such as "compareScreenshot('more to the description')".`);
    return n.screenshotDescriptions.add(i), async function l(e, t, r, s, n) {
     if ("string" != typeof t.__STENCIL_EMULATE__) throw new Error("compareScreenshot, missing screenshot emulate env var");
     if ("string" != typeof t.__STENCIL_SCREENSHOT_BUILD__) throw new Error("compareScreenshot, missing screen build env var");
     const o = JSON.parse(t.__STENCIL_EMULATE__), i = JSON.parse(t.__STENCIL_SCREENSHOT_BUILD__);
     await function a(e) {
      return new Promise((t => setTimeout(t, e)));
     }(i.timeoutBeforeScreenshot), await e.evaluate((() => new Promise((e => {
      window.requestAnimationFrame((() => {
       e();
      }));
     }))));
     const l = function c(e) {
      const t = {
       type: "png",
       fullPage: e.fullPage,
       omitBackground: e.omitBackground,
       encoding: "binary"
      };
      return e.clip && (t.clip = {
       x: e.clip.x,
       y: e.clip.y,
       width: e.clip.width,
       height: e.clip.height
      }), t;
     }(n), u = await e.screenshot(l), d = "number" == typeof n.pixelmatchThreshold ? n.pixelmatchThreshold : i.pixelmatchThreshold;
     let h = o.viewport.width, p = o.viewport.height;
     return n && n.clip && ("number" == typeof n.clip.width && (h = n.clip.width), "number" == typeof n.clip.height && (p = n.clip.height)), 
     await compareScreenshot(o, i, u, r, h, p, s, d);
    }(e, t, i, a, o);
   } : e.compareScreenshot = async () => ({
    mismatchedPixels: 0,
    allowableMismatchedPixels: 1,
    allowableMismatchedRatio: 1,
    desc: "",
    width: 1,
    height: 1,
    deviceScaleFactor: 1
   });
  }(t);
  let s = null;
  t.close = async e => {
   try {
    if (Array.isArray(t._e2eElements)) {
     const e = t._e2eElements.map((async e => {
      "function" == typeof e.e2eDispose && await e.e2eDispose();
     }));
     await Promise.all(e);
    }
   } catch (e) {}
   const r = () => {
    throw new Error("The page was already closed");
   };
   t._e2eElements = r, t._e2eEvents = r, t._e2eGoto = r, t.find = r, t.debugger = r, 
   t.findAll = r, t.compareScreenshot = r, t.setContent = r, t.spyOnEvent = r, t.waitForChanges = r, 
   t.waitForEvent = r;
   try {
    t.isClosed() || await t._e2eClose(e);
   } catch (e) {}
  };
  const n = async () => (s || (s = t.evaluateHandle((() => document))), (await s).asElement());
  t.find = async e => {
   const r = await n();
   return find(t, r, e);
  }, t.findAll = async e => {
   const r = await n();
   return findAll(t, r, e);
  }, t.waitForEvent = async e => {
   const r = await n();
   return waitForEvent(t, e, r);
  }, t.getDiagnostics = () => r, t.waitForChanges = waitForChanges.bind(null, t), 
  t.debugger = () => {
   if ("true" !== env.__STENCIL_E2E_DEVTOOLS__) throw new Error("Set the --devtools flag in order to use E2EPage.debugger()");
   return t.evaluate((() => new Promise((e => {
    e();
   }))));
  };
  const o = !0 === e.failOnConsoleError, i = !0 === e.failOnNetworkError;
  t.on("console", (e => {
   if ("error" === e.type() && (r.push({
    type: "error",
    message: e.text(),
    location: e.location().url
   }), o)) throw new Error(serializeConsoleMessage(e));
   !function t(e) {
    const t = serializeConsoleMessage(e), r = e.type(), s = "warning" === r ? "warn" : r;
    "debug" !== s && ("function" == typeof console[s] ? console[s](t) : console.log(r, t));
   }(e);
  })), t.on("pageerror", (e => {
   throw r.push({
    type: "pageerror",
    message: e.message,
    location: e.stack
   }), e;
  })), t.on("requestfailed", (e => {
   if (r.push({
    type: "requestfailed",
    message: e.failure().errorText,
    location: e.url()
   }), i) throw new Error(e.failure().errorText);
   console.error("requestfailed", e.url());
  })), "string" == typeof e.html ? await e2eSetContent(t, e.html, {
   waitUntil: e.waitUntil
  }) : "string" == typeof e.url ? await e2eGoTo(t, e.url, {
   waitUntil: e.waitUntil
  }) : (t.goto = e2eGoTo.bind(null, t), t.setContent = e2eSetContent.bind(null, t));
 } catch (e) {
  throw t && (t.isClosed() || await t.close()), e;
 }
 return t;
}, exports.newSpecPage = async function newSpecPage(e) {
 var t;
 if (null == e) throw new Error("NewSpecPageOptions required");
 testing.resetPlatform(null !== (t = e.platform) && void 0 !== t ? t : {}), resetBuildConditionals(appData.BUILD), 
 Array.isArray(e.components) && testing.registerComponents(e.components), e.hydrateClientSide && (e.includeAnnotations = !0), 
 e.hydrateServerSide ? (e.includeAnnotations = !0, testing.setSupportsShadowDom(!1)) : (e.includeAnnotations = !!e.includeAnnotations, 
 !1 === e.supportsShadowDom ? testing.setSupportsShadowDom(!1) : testing.setSupportsShadowDom(!0)), 
 appData.BUILD.cssAnnotations = e.includeAnnotations;
 const r = new Set;
 testing.win.__stencil_spec_options = e;
 const s = testing.win.document, n = {
  win: testing.win,
  doc: s,
  body: s.body,
  build: appData.BUILD,
  styles: testing.styles,
  setContent: e => (s.body.innerHTML = e, testing.flushAll()),
  waitForChanges: testing.flushAll,
  flushLoadModule: testing.flushLoadModule,
  flushQueue: testing.flushQueue
 }, o = e.components.map((e => {
  if (null == e.COMPILER_META) throw new Error('Invalid component class: Missing static "COMPILER_META" property.');
  r.add(e.COMPILER_META.tagName), e.isProxied = !1, function t(e) {
   var t, r, s, n, o, i;
   "function" == typeof (null === (t = e.prototype) || void 0 === t ? void 0 : t.__componentWillLoad) && (e.prototype.componentWillLoad = e.prototype.__componentWillLoad, 
   e.prototype.__componentWillLoad = null), "function" == typeof (null === (r = e.prototype) || void 0 === r ? void 0 : r.__componentWillUpdate) && (e.prototype.componentWillUpdate = e.prototype.__componentWillUpdate, 
   e.prototype.__componentWillUpdate = null), "function" == typeof (null === (s = e.prototype) || void 0 === s ? void 0 : s.__componentWillRender) && (e.prototype.componentWillRender = e.prototype.__componentWillRender, 
   e.prototype.__componentWillRender = null), "function" == typeof (null === (n = e.prototype) || void 0 === n ? void 0 : n.componentWillLoad) && (e.prototype.__componentWillLoad = e.prototype.componentWillLoad, 
   e.prototype.componentWillLoad = function() {
    const e = this.__componentWillLoad();
    return null != e && "function" == typeof e.then ? testing.writeTask((() => e)) : testing.writeTask((() => Promise.resolve())), 
    e;
   }), "function" == typeof (null === (o = e.prototype) || void 0 === o ? void 0 : o.componentWillUpdate) && (e.prototype.__componentWillUpdate = e.prototype.componentWillUpdate, 
   e.prototype.componentWillUpdate = function() {
    const e = this.__componentWillUpdate();
    return null != e && "function" == typeof e.then ? testing.writeTask((() => e)) : testing.writeTask((() => Promise.resolve())), 
    e;
   }), "function" == typeof (null === (i = e.prototype) || void 0 === i ? void 0 : i.componentWillRender) && (e.prototype.__componentWillRender = e.prototype.componentWillRender, 
   e.prototype.componentWillRender = function() {
    const e = this.__componentWillRender();
    return null != e && "function" == typeof e.then ? testing.writeTask((() => e)) : testing.writeTask((() => Promise.resolve())), 
    e;
   });
  }(e);
  const s = `${e.COMPILER_META.tagName}.${Math.round(899999 * Math.random()) + 1e5}`, n = e.COMPILER_META.styles;
  if (Array.isArray(n)) if (n.length > 1) {
   const t = {};
   n.forEach((e => {
    t[e.modeName] = e.styleStr;
   })), e.style = t;
  } else 1 === n.length && (e.style = n[0].styleStr);
  testing.registerModule(s, e);
  const o = ((e, t) => [ e, t.map((e => ((e, t) => {
   let r = 0;
   "shadow" === e.encapsulation ? (r |= 1, e.shadowDelegatesFocus && (r |= 16)) : "scoped" === e.encapsulation && (r |= 2), 
   "shadow" !== e.encapsulation && e.htmlTagNames.includes("slot") && (r |= 4), e.hasMode && (r |= 32);
   const s = formatComponentRuntimeMembers(e, t), n = formatHostListeners(e);
   return trimFalsy([ r, e.tagName, Object.keys(s).length > 0 ? s : void 0, n.length > 0 ? n : void 0 ]);
  })(e, !0))) ])(s, [ e.COMPILER_META ]);
  return o;
 })), i = (e => {
  const t = e.some((e => e.htmlTagNames.includes("slot"))), r = e.some((e => "shadow" === e.encapsulation)), s = e.some((e => "shadow" !== e.encapsulation && e.htmlTagNames.includes("slot"))), n = {
   allRenderFn: e.every((e => e.hasRenderFn)),
   cmpDidLoad: e.some((e => e.hasComponentDidLoadFn)),
   cmpShouldUpdate: e.some((e => e.hasComponentShouldUpdateFn)),
   cmpDidUnload: e.some((e => e.hasComponentDidUnloadFn)),
   cmpDidUpdate: e.some((e => e.hasComponentDidUpdateFn)),
   cmpDidRender: e.some((e => e.hasComponentDidRenderFn)),
   cmpWillLoad: e.some((e => e.hasComponentWillLoadFn)),
   cmpWillUpdate: e.some((e => e.hasComponentWillUpdateFn)),
   cmpWillRender: e.some((e => e.hasComponentWillRenderFn)),
   connectedCallback: e.some((e => e.hasConnectedCallbackFn)),
   disconnectedCallback: e.some((e => e.hasDisconnectedCallbackFn)),
   element: e.some((e => e.hasElement)),
   event: e.some((e => e.hasEvent)),
   hasRenderFn: e.some((e => e.hasRenderFn)),
   lifecycle: e.some((e => e.hasLifecycle)),
   asyncLoading: !1,
   hostListener: e.some((e => e.hasListener)),
   hostListenerTargetWindow: e.some((e => e.hasListenerTargetWindow)),
   hostListenerTargetDocument: e.some((e => e.hasListenerTargetDocument)),
   hostListenerTargetBody: e.some((e => e.hasListenerTargetBody)),
   hostListenerTargetParent: e.some((e => e.hasListenerTargetParent)),
   hostListenerTarget: e.some((e => e.hasListenerTarget)),
   member: e.some((e => e.hasMember)),
   method: e.some((e => e.hasMethod)),
   mode: e.some((e => e.hasMode)),
   observeAttribute: e.some((e => e.hasAttribute)),
   prop: e.some((e => e.hasProp)),
   propBoolean: e.some((e => e.hasPropBoolean)),
   propNumber: e.some((e => e.hasPropNumber)),
   propString: e.some((e => e.hasPropString)),
   propMutable: e.some((e => e.hasPropMutable)),
   reflect: e.some((e => e.hasReflect)),
   scoped: e.some((e => "scoped" === e.encapsulation)),
   shadowDom: r,
   shadowDelegatesFocus: r && e.some((e => e.shadowDelegatesFocus)),
   slot: t,
   slotRelocation: s,
   state: e.some((e => e.hasState)),
   style: e.some((e => e.hasStyle)),
   svg: e.some((e => e.htmlTagNames.includes("svg"))),
   updatable: e.some((e => e.isUpdateable)),
   vdomAttribute: e.some((e => e.hasVdomAttribute)),
   vdomXlink: e.some((e => e.hasVdomXlink)),
   vdomClass: e.some((e => e.hasVdomClass)),
   vdomFunctional: e.some((e => e.hasVdomFunctional)),
   vdomKey: e.some((e => e.hasVdomKey)),
   vdomListener: e.some((e => e.hasVdomListener)),
   vdomPropOrAttr: e.some((e => e.hasVdomPropOrAttr)),
   vdomRef: e.some((e => e.hasVdomRef)),
   vdomRender: e.some((e => e.hasVdomRender)),
   vdomStyle: e.some((e => e.hasVdomStyle)),
   vdomText: e.some((e => e.hasVdomText)),
   watchCallback: e.some((e => e.hasWatchCallback)),
   taskQueue: !0
  };
  return n.asyncLoading = n.cmpWillUpdate || n.cmpWillLoad || n.cmpWillRender, n.vdomAttribute = n.vdomAttribute || n.reflect, 
  n.vdomPropOrAttr = n.vdomPropOrAttr || n.reflect, n;
 })(e.components.map((e => e.COMPILER_META)));
 if (e.strictBuild ? Object.assign(appData.BUILD, i) : Object.keys(i).forEach((e => {
  !0 === i[e] && (appData.BUILD[e] = !0);
 })), appData.BUILD.asyncLoading = !0, e.hydrateClientSide ? (appData.BUILD.hydrateClientSide = !0, 
 appData.BUILD.hydrateServerSide = !1) : e.hydrateServerSide && (appData.BUILD.hydrateServerSide = !0, 
 appData.BUILD.hydrateClientSide = !1), appData.BUILD.cloneNodeFix = !1, appData.BUILD.shadowDomShim = !1, 
 appData.BUILD.safari10 = !1, appData.BUILD.attachStyles = !!e.attachStyles, "string" == typeof e.url && (n.win.location.href = e.url), 
 "string" == typeof e.direction && n.doc.documentElement.setAttribute("dir", e.direction), 
 "string" == typeof e.language && n.doc.documentElement.setAttribute("lang", e.language), 
 "string" == typeof e.cookie) try {
  n.doc.cookie = e.cookie;
 } catch (e) {}
 if ("string" == typeof e.referrer) try {
  n.doc.referrer = e.referrer;
 } catch (e) {}
 if ("string" == typeof e.userAgent) try {
  n.win.navigator.userAgent = e.userAgent;
 } catch (e) {}
 if (testing.bootstrapLazy(o), "function" == typeof e.template) {
  const t = {
   $ancestorComponent$: void 0,
   $flags$: 0,
   $modeName$: void 0,
   $cmpMeta$: {
    $flags$: 0,
    $tagName$: "body"
   },
   $hostElement$: n.body
  };
  testing.renderVdom(t, e.template());
 } else "string" == typeof e.html && (n.body.innerHTML = e.html);
 !1 !== e.flushQueue && await n.waitForChanges();
 let a = null;
 return Object.defineProperty(n, "root", {
  get() {
   if (null == a && (a = findRootComponent(r, n.body)), null != a) return a;
   const e = n.body.firstElementChild;
   return null != e ? e : null;
  }
 }), Object.defineProperty(n, "rootInstance", {
  get() {
   const e = testing.getHostRef(n.root);
   return null != e ? e.$lazyInstance$ : null;
  }
 }), e.hydrateServerSide && testing.insertVdomAnnotations(s, []), e.autoApplyChanges && (testing.startAutoApplyChanges(), 
 n.waitForChanges = () => (console.error('waitForChanges() cannot be used manually if the "startAutoApplyChanges" option is enabled'), 
 Promise.resolve())), n;
}, exports.shuffleArray = function shuffleArray(e) {
 let t, r, s = e.length;
 for (;0 !== s; ) r = Math.floor(Math.random() * s), s -= 1, t = e[s], e[s] = e[r], 
 e[r] = t;
 return e;
}, exports.transpile = transpile;