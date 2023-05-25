/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { Context, setPlatformHelpers, setMode, getMode } from '@stencil/core/internal/client';

// TODO(FW-2832): types
class Config {
  constructor() {
    this.m = new Map();
  }
  reset(configObj) {
    this.m = new Map(Object.entries(configObj));
  }
  get(key, fallback) {
    const value = this.m.get(key);
    return value !== undefined ? value : fallback;
  }
  getBoolean(key, fallback = false) {
    const val = this.m.get(key);
    if (val === undefined) {
      return fallback;
    }
    if (typeof val === 'string') {
      return val === 'true';
    }
    return !!val;
  }
  getNumber(key, fallback) {
    const val = parseFloat(this.m.get(key));
    return isNaN(val) ? (fallback !== undefined ? fallback : NaN) : val;
  }
  set(key, value) {
    this.m.set(key, value);
  }
}
const config = /*@__PURE__*/ new Config();
const configFromSession = (win) => {
  try {
    const configStr = win.sessionStorage.getItem(IONIC_SESSION_KEY);
    return configStr !== null ? JSON.parse(configStr) : {};
  }
  catch (e) {
    return {};
  }
};
const saveConfig = (win, c) => {
  try {
    win.sessionStorage.setItem(IONIC_SESSION_KEY, JSON.stringify(c));
  }
  catch (e) {
    return;
  }
};
const configFromURL = (win) => {
  const configObj = {};
  win.location.search
    .slice(1)
    .split('&')
    .map((entry) => entry.split('='))
    .map(([key, value]) => [decodeURIComponent(key), decodeURIComponent(value)])
    .filter(([key]) => startsWith(key, IONIC_PREFIX))
    .map(([key, value]) => [key.slice(IONIC_PREFIX.length), value])
    .forEach(([key, value]) => {
    configObj[key] = value;
  });
  return configObj;
};
const startsWith = (input, search) => {
  return input.substr(0, search.length) === search;
};
const IONIC_PREFIX = 'ionic:';
const IONIC_SESSION_KEY = 'ionic-persist-config';

const getPlatforms = (win) => setupPlatforms(win);
const isPlatform = (winOrPlatform, platform) => {
  if (typeof winOrPlatform === 'string') {
    platform = winOrPlatform;
    winOrPlatform = undefined;
  }
  return getPlatforms(winOrPlatform).includes(platform);
};
const setupPlatforms = (win = window) => {
  if (typeof win === 'undefined') {
    return [];
  }
  win.Ionic = win.Ionic || {};
  let platforms = win.Ionic.platforms;
  if (platforms == null) {
    platforms = win.Ionic.platforms = detectPlatforms(win);
    platforms.forEach((p) => win.document.documentElement.classList.add(`plt-${p}`));
  }
  return platforms;
};
const detectPlatforms = (win) => {
  const customPlatformMethods = config.get('platform');
  return Object.keys(PLATFORMS_MAP).filter((p) => {
    const customMethod = customPlatformMethods === null || customPlatformMethods === void 0 ? void 0 : customPlatformMethods[p];
    return typeof customMethod === 'function' ? customMethod(win) : PLATFORMS_MAP[p](win);
  });
};
const isMobileWeb = (win) => isMobile(win) && !isHybrid(win);
const isIpad = (win) => {
  // iOS 12 and below
  if (testUserAgent(win, /iPad/i)) {
    return true;
  }
  // iOS 13+
  if (testUserAgent(win, /Macintosh/i) && isMobile(win)) {
    return true;
  }
  return false;
};
const isIphone = (win) => testUserAgent(win, /iPhone/i);
const isIOS = (win) => testUserAgent(win, /iPhone|iPod/i) || isIpad(win);
const isAndroid = (win) => testUserAgent(win, /android|sink/i);
const isAndroidTablet = (win) => {
  return isAndroid(win) && !testUserAgent(win, /mobile/i);
};
const isPhablet = (win) => {
  const width = win.innerWidth;
  const height = win.innerHeight;
  const smallest = Math.min(width, height);
  const largest = Math.max(width, height);
  return smallest > 390 && smallest < 520 && largest > 620 && largest < 800;
};
const isTablet = (win) => {
  const width = win.innerWidth;
  const height = win.innerHeight;
  const smallest = Math.min(width, height);
  const largest = Math.max(width, height);
  return isIpad(win) || isAndroidTablet(win) || (smallest > 460 && smallest < 820 && largest > 780 && largest < 1400);
};
const isMobile = (win) => matchMedia(win, '(any-pointer:coarse)');
const isDesktop = (win) => !isMobile(win);
const isHybrid = (win) => isCordova(win) || isCapacitorNative(win);
const isCordova = (win) => !!(win['cordova'] || win['phonegap'] || win['PhoneGap']);
const isCapacitorNative = (win) => {
  const capacitor = win['Capacitor'];
  return !!(capacitor === null || capacitor === void 0 ? void 0 : capacitor.isNative);
};
const isElectron = (win) => testUserAgent(win, /electron/i);
const isPWA = (win) => { var _a; return !!(((_a = win.matchMedia) === null || _a === void 0 ? void 0 : _a.call(win, '(display-mode: standalone)').matches) || win.navigator.standalone); };
const testUserAgent = (win, expr) => expr.test(win.navigator.userAgent);
const matchMedia = (win, query) => { var _a; return (_a = win.matchMedia) === null || _a === void 0 ? void 0 : _a.call(win, query).matches; };
const PLATFORMS_MAP = {
  ipad: isIpad,
  iphone: isIphone,
  ios: isIOS,
  android: isAndroid,
  phablet: isPhablet,
  tablet: isTablet,
  cordova: isCordova,
  capacitor: isCapacitorNative,
  electron: isElectron,
  pwa: isPWA,
  mobile: isMobile,
  mobileweb: isMobileWeb,
  desktop: isDesktop,
  hybrid: isHybrid,
};

let defaultMode;
const getIonMode = (ref) => {
  return (ref && getMode(ref)) || defaultMode;
};
const initialize = (userConfig = {}) => {
  if (typeof window === 'undefined') {
    return;
  }
  const doc = window.document;
  const win = window;
  Context.config = config;
  const Ionic = (win.Ionic = win.Ionic || {});
  const platformHelpers = {};
  if (userConfig._ael) {
    platformHelpers.ael = userConfig._ael;
  }
  if (userConfig._rel) {
    platformHelpers.rel = userConfig._rel;
  }
  if (userConfig._ce) {
    platformHelpers.ce = userConfig._ce;
  }
  setPlatformHelpers(platformHelpers);
  // create the Ionic.config from raw config object (if it exists)
  // and convert Ionic.config into a ConfigApi that has a get() fn
  const configObj = Object.assign(Object.assign(Object.assign(Object.assign(Object.assign({}, configFromSession(win)), { persistConfig: false }), Ionic.config), configFromURL(win)), userConfig);
  config.reset(configObj);
  if (config.getBoolean('persistConfig')) {
    saveConfig(win, configObj);
  }
  // Setup platforms
  setupPlatforms(win);
  // first see if the mode was set as an attribute on <html>
  // which could have been set by the user, or by pre-rendering
  // otherwise get the mode via config settings, and fallback to md
  Ionic.config = config;
  Ionic.mode = defaultMode = config.get('mode', doc.documentElement.getAttribute('mode') || (isPlatform(win, 'ios') ? 'ios' : 'md'));
  config.set('mode', defaultMode);
  doc.documentElement.setAttribute('mode', defaultMode);
  doc.documentElement.classList.add(defaultMode);
  if (config.getBoolean('_testing')) {
    config.set('animated', false);
  }
  const isIonicElement = (elm) => { var _a; return (_a = elm.tagName) === null || _a === void 0 ? void 0 : _a.startsWith('ION-'); };
  const isAllowedIonicModeValue = (elmMode) => ['ios', 'md'].includes(elmMode);
  setMode((elm) => {
    while (elm) {
      const elmMode = elm.mode || elm.getAttribute('mode');
      if (elmMode) {
        if (isAllowedIonicModeValue(elmMode)) {
          return elmMode;
        }
        else if (isIonicElement(elm)) {
          console.warn('Invalid ionic mode: "' + elmMode + '", expected: "ios" or "md"');
        }
      }
      elm = elm.parentElement;
    }
    return defaultMode;
  });
};

export { isPlatform as a, getIonMode as b, config as c, getPlatforms as g, initialize as i };
