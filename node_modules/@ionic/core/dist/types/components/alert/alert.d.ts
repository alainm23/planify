import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AnimationBuilder, OverlayInterface, FrameworkDelegate } from '../../interface';
import type { OverlayEventDetail } from '../../utils/overlays-interface';
import type { IonicSafeString } from '../../utils/sanitization';
import type { AlertButton, AlertInput } from './alert-interface';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Alert implements ComponentInterface, OverlayInterface {
  private readonly delegateController;
  private readonly triggerController;
  private customHTMLEnabled;
  private activeId?;
  private inputType?;
  private processedInputs;
  private processedButtons;
  private wrapperEl?;
  private gesture?;
  private currentTransition?;
  presented: boolean;
  lastFocus?: HTMLElement;
  el: HTMLIonAlertElement;
  /** @internal */
  overlayIndex: number;
  /** @internal */
  delegate?: FrameworkDelegate;
  /** @internal */
  hasController: boolean;
  /**
   * If `true`, the keyboard will be automatically dismissed when the overlay is presented.
   */
  keyboardClose: boolean;
  /**
   * Animation to use when the alert is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the alert is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * The main title in the heading of the alert.
   */
  header?: string;
  /**
   * The subtitle in the heading of the alert. Displayed under the title.
   */
  subHeader?: string;
  /**
   * The main message to be displayed in the alert.
   * `message` can accept either plaintext or HTML as a string.
   * To display characters normally reserved for HTML, they
   * must be escaped. For example `<Ionic>` would become
   * `&lt;Ionic&gt;`
   *
   * For more information: [Security Documentation](https://ionicframework.com/docs/faq/security)
   *
   * This property accepts custom HTML as a string.
   * Content is parsed as plaintext by default.
   * `innerHTMLTemplatesEnabled` must be set to `true` in the Ionic config
   * before custom HTML can be used.
   */
  message?: string | IonicSafeString;
  /**
   * Array of buttons to be added to the alert.
   */
  buttons: (AlertButton | string)[];
  /**
   * Array of input to show in the alert.
   */
  inputs: AlertInput[];
  /**
   * If `true`, the alert will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * If `true`, the alert will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the alert will animate.
   */
  animated: boolean;
  /**
   * Additional attributes to pass to the alert.
   */
  htmlAttributes?: {
    [key: string]: any;
  };
  /**
   * If `true`, the alert will open. If `false`, the alert will close.
   * Use this if you need finer grained control over presentation, otherwise
   * just use the alertController or the `trigger` property.
   * Note: `isOpen` will not automatically be set back to `false` when
   * the alert dismisses. You will need to do that in your code.
   */
  isOpen: boolean;
  onIsOpenChange(newValue: boolean, oldValue: boolean): void;
  /**
   * An ID corresponding to the trigger element that
   * causes the alert to open when clicked.
   */
  trigger: string | undefined;
  triggerChanged(): void;
  /**
   * Emitted after the alert has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the alert has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the alert has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the alert has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the alert has presented.
   * Shorthand for ionAlertWillDismiss.
   */
  didPresentShorthand: EventEmitter<void>;
  /**
   * Emitted before the alert has presented.
   * Shorthand for ionAlertWillPresent.
   */
  willPresentShorthand: EventEmitter<void>;
  /**
   * Emitted before the alert has dismissed.
   * Shorthand for ionAlertWillDismiss.
   */
  willDismissShorthand: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the alert has dismissed.
   * Shorthand for ionAlertDidDismiss.
   */
  didDismissShorthand: EventEmitter<OverlayEventDetail>;
  onKeydown(ev: any): void;
  buttonsChanged(): void;
  inputsChanged(): void;
  connectedCallback(): void;
  componentWillLoad(): void;
  disconnectedCallback(): void;
  componentDidLoad(): void;
  /**
   * Present the alert overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the alert overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the alert.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the alert.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the alert did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the alert will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private rbClick;
  private cbClick;
  private buttonClick;
  private callButtonHandler;
  private getValues;
  private renderAlertInputs;
  private renderCheckbox;
  private renderRadio;
  private renderInput;
  private onBackdropTap;
  private dispatchCancelHandler;
  private renderAlertButtons;
  private renderAlertMessage;
  render(): any;
}
