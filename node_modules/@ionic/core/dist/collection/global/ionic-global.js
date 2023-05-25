/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { getMode, setMode, setPlatformHelpers } from '@stencil/core';
import { isPlatform, setupPlatforms } from '../utils/platform';
import { config, configFromSession, configFromURL, saveConfig } from './config';
let defaultMode;
export const getIonMode = (ref) => {
  return (ref && getMode(ref)) || defaultMode;
};
export const initialize = (userConfig = {}) => {
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
export default initialize;
