/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
export const hostContext = (selector, el) => {
  return el.closest(selector) !== null;
};
/**
 * Create the mode and color classes for the component based on the classes passed in
 */
export const createColorClasses = (color, cssClassMap) => {
  return typeof color === 'string' && color.length > 0
    ? Object.assign({ 'ion-color': true, [`ion-color-${color}`]: true }, cssClassMap) : cssClassMap;
};
export const getClassList = (classes) => {
  if (classes !== undefined) {
    const array = Array.isArray(classes) ? classes : classes.split(' ');
    return array
      .filter((c) => c != null)
      .map((c) => c.trim())
      .filter((c) => c !== '');
  }
  return [];
};
export const getClassMap = (classes) => {
  const map = {};
  getClassList(classes).forEach((c) => (map[c] = true));
  return map;
};
const SCHEME = /^[a-z][a-z0-9+\-.]*:/;
export const openURL = async (url, ev, direction, animation) => {
  if (url != null && url[0] !== '#' && !SCHEME.test(url)) {
    const router = document.querySelector('ion-router');
    if (router) {
      if (ev != null) {
        ev.preventDefault();
      }
      return router.push(url, direction, animation);
    }
  }
  return false;
};
