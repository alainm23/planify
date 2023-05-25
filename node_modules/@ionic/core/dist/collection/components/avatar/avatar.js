/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { Host, h } from '@stencil/core';
import { getIonMode } from '../../global/ionic-global';
export class Avatar {
  render() {
    return (h(Host, { class: getIonMode(this) }, h("slot", null)));
  }
  static get is() { return "ion-avatar"; }
  static get encapsulation() { return "shadow"; }
  static get originalStyleUrls() {
    return {
      "ios": ["avatar.ios.scss"],
      "md": ["avatar.md.scss"]
    };
  }
  static get styleUrls() {
    return {
      "ios": ["avatar.ios.css"],
      "md": ["avatar.md.css"]
    };
  }
}
