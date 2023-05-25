/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
/**
 * This provides metadata that can be used to
 * create a unique screenshot URL.
 * For example, we need to be able to differentiate
 * between iOS in LTR mode and iOS in RTL mode.
 */
export const getSnapshotSettings = (page, testInfo) => {
  var _a, _b;
  const url = page.url();
  const splitUrl = url.split('?');
  const paramsString = splitUrl[1];
  const { mode, rtl } = testInfo.project.metadata;
  /**
   * Account for custom settings when overriding
   * the mode/rtl setting. Fall back to the
   * project metadata if nothing was found. This
   * will happen if you call page.getSnapshotSettings
   * before page.goto.
   */
  const urlToParams = new URLSearchParams(paramsString);
  const formattedMode = (_a = urlToParams.get('ionic:mode')) !== null && _a !== void 0 ? _a : mode;
  const formattedRtl = (_b = urlToParams.get('rtl')) !== null && _b !== void 0 ? _b : rtl;
  /**
   * If encoded in the search params, the rtl value
   * can be `'true'` instead of `true`.
   */
  const rtlString = formattedRtl === true || formattedRtl === 'true' ? 'rtl' : 'ltr';
  return `${formattedMode}-${rtlString}`;
};
