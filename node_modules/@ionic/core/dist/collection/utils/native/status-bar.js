/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { win } from '../window';
export var Style;
(function (Style) {
  Style["Dark"] = "DARK";
  Style["Light"] = "LIGHT";
  Style["Default"] = "DEFAULT";
})(Style || (Style = {}));
export const StatusBar = {
  getEngine() {
    var _a;
    return ((_a = win === null || win === void 0 ? void 0 : win.Capacitor) === null || _a === void 0 ? void 0 : _a.isPluginAvailable('StatusBar')) && (win === null || win === void 0 ? void 0 : win.Capacitor.Plugins.StatusBar);
  },
  supportsDefaultStatusBarStyle() {
    var _a;
    /**
     * The 'DEFAULT' status bar style was added
     * to the @capacitor/status-bar plugin in Capacitor 3.
     * PluginHeaders is only supported in Capacitor 3+,
     * so we can use this to detect Capacitor 3.
     */
    return !!((_a = win === null || win === void 0 ? void 0 : win.Capacitor) === null || _a === void 0 ? void 0 : _a.PluginHeaders);
  },
  setStyle(options) {
    const engine = this.getEngine();
    if (!engine) {
      return;
    }
    engine.setStyle(options);
  },
  getStyle: async function () {
    const engine = this.getEngine();
    if (!engine) {
      return Style.Default;
    }
    const { style } = await engine.getInfo();
    return style;
  },
};
