/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
export const setupConfig = (config) => {
  const win = window;
  const Ionic = win.Ionic;
  // eslint-disable-next-line @typescript-eslint/prefer-optional-chain
  if (Ionic && Ionic.config && Ionic.config.constructor.name !== 'Object') {
    return;
  }
  win.Ionic = win.Ionic || {};
  win.Ionic.config = Object.assign(Object.assign({}, win.Ionic.config), config);
  return win.Ionic.config;
};
export const getMode = () => {
  var _a;
  const win = window;
  const config = (_a = win === null || win === void 0 ? void 0 : win.Ionic) === null || _a === void 0 ? void 0 : _a.config;
  if (config) {
    if (config.mode) {
      return config.mode;
    }
    else {
      return config.get('mode');
    }
  }
  return 'md';
};
export const ENABLE_HTML_CONTENT_DEFAULT = false;
