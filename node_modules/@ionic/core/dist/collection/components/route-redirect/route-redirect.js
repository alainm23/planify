export class RouteRedirect {
  constructor() {
    this.from = undefined;
    this.to = undefined;
  }
  propDidChange() {
    this.ionRouteRedirectChanged.emit();
  }
  connectedCallback() {
    this.ionRouteRedirectChanged.emit();
  }
  static get is() { return "ion-route-redirect"; }
  static get properties() {
    return {
      "from": {
        "type": "string",
        "mutable": false,
        "complexType": {
          "original": "string",
          "resolved": "string",
          "references": {}
        },
        "required": true,
        "optional": false,
        "docs": {
          "tags": [],
          "text": "A redirect route, redirects \"from\" a URL \"to\" another URL. This property is that \"from\" URL.\nIt needs to be an exact match of the navigated URL in order to apply.\n\nThe path specified in this value is always an absolute path, even if the initial `/` slash\nis not specified."
        },
        "attribute": "from",
        "reflect": false
      },
      "to": {
        "type": "string",
        "mutable": false,
        "complexType": {
          "original": "string | undefined | null",
          "resolved": "null | string | undefined",
          "references": {}
        },
        "required": true,
        "optional": false,
        "docs": {
          "tags": [],
          "text": "A redirect route, redirects \"from\" a URL \"to\" another URL. This property is that \"to\" URL.\nWhen the defined `ion-route-redirect` rule matches, the router will redirect to the path\nspecified in this property.\n\nThe value of this property is always an absolute path inside the scope of routes defined in\n`ion-router` it can't be used with another router or to perform a redirection to a different domain.\n\nNote that this is a virtual redirect, it will not cause a real browser refresh, again, it's\na redirect inside the context of ion-router.\n\nWhen this property is not specified or his value is `undefined` the whole redirect route is noop,\neven if the \"from\" value matches."
        },
        "attribute": "to",
        "reflect": false
      }
    };
  }
  static get events() {
    return [{
        "method": "ionRouteRedirectChanged",
        "name": "ionRouteRedirectChanged",
        "bubbles": true,
        "cancelable": true,
        "composed": true,
        "docs": {
          "tags": [],
          "text": "Internal event that fires when any value of this rule is added/removed from the DOM,\nor any of his public properties changes.\n\n`ion-router` captures this event in order to update his internal registry of router rules."
        },
        "complexType": {
          "original": "any",
          "resolved": "any",
          "references": {}
        }
      }];
  }
  static get watchers() {
    return [{
        "propName": "from",
        "methodName": "propDidChange"
      }, {
        "propName": "to",
        "methodName": "propDidChange"
      }];
  }
}
