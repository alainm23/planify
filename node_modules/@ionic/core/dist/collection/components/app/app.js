/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { Build, Host, h } from '@stencil/core';
import { config } from '../../global/config';
import { getIonMode } from '../../global/ionic-global';
import { isPlatform } from '../../utils/platform';
export class App {
  componentDidLoad() {
    if (Build.isBrowser) {
      rIC(async () => {
        const isHybrid = isPlatform(window, 'hybrid');
        if (!config.getBoolean('_testing')) {
          import('../../utils/tap-click').then((module) => module.startTapClick(config));
        }
        if (config.getBoolean('statusTap', isHybrid)) {
          import('../../utils/status-tap').then((module) => module.startStatusTap());
        }
        if (config.getBoolean('inputShims', needInputShims())) {
          /**
           * needInputShims() ensures that only iOS and Android
           * platforms proceed into this block.
           */
          const platform = isPlatform(window, 'ios') ? 'ios' : 'android';
          import('../../utils/input-shims/input-shims').then((module) => module.startInputShims(config, platform));
        }
        const hardwareBackButtonModule = await import('../../utils/hardware-back-button');
        if (config.getBoolean('hardwareBackButton', isHybrid)) {
          hardwareBackButtonModule.startHardwareBackButton();
        }
        else {
          hardwareBackButtonModule.blockHardwareBackButton();
        }
        if (typeof window !== 'undefined') {
          import('../../utils/keyboard/keyboard').then((module) => module.startKeyboardAssist(window));
        }
        import('../../utils/focus-visible').then((module) => (this.focusVisible = module.startFocusVisible()));
      });
    }
  }
  /**
   * @internal
   * Used to set focus on an element that uses `ion-focusable`.
   * Do not use this if focusing the element as a result of a keyboard
   * event as the focus utility should handle this for us. This method
   * should be used when we want to programmatically focus an element as
   * a result of another user action. (Ex: We focus the first element
   * inside of a popover when the user presents it, but the popover is not always
   * presented as a result of keyboard action.)
   */
  async setFocus(elements) {
    if (this.focusVisible) {
      this.focusVisible.setFocus(elements);
    }
  }
  render() {
    const mode = getIonMode(this);
    return (h(Host, { class: {
        [mode]: true,
        'ion-page': true,
        'force-statusbar-padding': config.getBoolean('_forceStatusbarPadding'),
      } }));
  }
  static get is() { return "ion-app"; }
  static get originalStyleUrls() {
    return {
      "$": ["app.scss"]
    };
  }
  static get styleUrls() {
    return {
      "$": ["app.css"]
    };
  }
  static get methods() {
    return {
      "setFocus": {
        "complexType": {
          "signature": "(elements: HTMLElement[]) => Promise<void>",
          "parameters": [{
              "tags": [],
              "text": ""
            }],
          "references": {
            "Promise": {
              "location": "global"
            },
            "HTMLElement": {
              "location": "global"
            }
          },
          "return": "Promise<void>"
        },
        "docs": {
          "text": "",
          "tags": [{
              "name": "internal",
              "text": "Used to set focus on an element that uses `ion-focusable`.\nDo not use this if focusing the element as a result of a keyboard\nevent as the focus utility should handle this for us. This method\nshould be used when we want to programmatically focus an element as\na result of another user action. (Ex: We focus the first element\ninside of a popover when the user presents it, but the popover is not always\npresented as a result of keyboard action.)"
            }]
        }
      }
    };
  }
  static get elementRef() { return "el"; }
}
const needInputShims = () => {
  /**
   * iOS always needs input shims
   */
  const needsShimsIOS = isPlatform(window, 'ios') && isPlatform(window, 'mobile');
  if (needsShimsIOS) {
    return true;
  }
  /**
   * Android only needs input shims when running
   * in the browser and only if the browser is using the
   * new Chrome 108+ resize behavior: https://developer.chrome.com/blog/viewport-resize-behavior/
   */
  const isAndroidMobileWeb = isPlatform(window, 'android') && isPlatform(window, 'mobileweb');
  if (isAndroidMobileWeb) {
    return true;
  }
  return false;
};
const rIC = (callback) => {
  if ('requestIdleCallback' in window) {
    window.requestIdleCallback(callback);
  }
  else {
    setTimeout(callback, 32);
  }
};
