import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
import type { AnimationBuilder, FrameworkDelegate, OverlayInterface } from '../../interface';
import type { OverlayEventDetail } from '../../utils/overlays-interface';
import type { IonicSafeString } from '../../utils/sanitization';
import type { SpinnerTypes } from '../spinner/spinner-configs';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Loading implements ComponentInterface, OverlayInterface {
  private readonly delegateController;
  private readonly triggerController;
  private customHTMLEnabled;
  private durationTimeout?;
  private currentTransition?;
  presented: boolean;
  lastFocus?: HTMLElement;
  el: HTMLIonLoadingElement;
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
   * Animation to use when the loading indicator is presented.
   */
  enterAnimation?: AnimationBuilder;
  /**
   * Animation to use when the loading indicator is dismissed.
   */
  leaveAnimation?: AnimationBuilder;
  /**
   * Optional text content to display in the loading indicator.
   *
   * This property accepts custom HTML as a string.
   * Content is parsed as plaintext by default.
   * `innerHTMLTemplatesEnabled` must be set to `true` in the Ionic config
   * before custom HTML can be used.
   */
  message?: string | IonicSafeString;
  /**
   * Additional classes to apply for custom CSS. If multiple classes are
   * provided they should be separated by spaces.
   */
  cssClass?: string | string[];
  /**
   * Number of milliseconds to wait before dismissing the loading indicator.
   */
  duration: number;
  /**
   * If `true`, the loading indicator will be dismissed when the backdrop is clicked.
   */
  backdropDismiss: boolean;
  /**
   * If `true`, a backdrop will be displayed behind the loading indicator.
   */
  showBackdrop: boolean;
  /**
   * The name of the spinner to display.
   */
  spinner?: SpinnerTypes | null;
  /**
   * If `true`, the loading indicator will be translucent.
   * Only applies when the mode is `"ios"` and the device supports
   * [`backdrop-filter`](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter#Browser_compatibility).
   */
  translucent: boolean;
  /**
   * If `true`, the loading indicator will animate.
   */
  animated: boolean;
  /**
   * Additional attributes to pass to the loader.
   */
  htmlAttributes?: {
    [key: string]: any;
  };
  /**
   * If `true`, the loading indicator will open. If `false`, the loading indicator will close.
   * Use this if you need finer grained control over presentation, otherwise
   * just use the loadingController or the `trigger` property.
   * Note: `isOpen` will not automatically be set back to `false` when
   * the loading indicator dismisses. You will need to do that in your code.
   */
  isOpen: boolean;
  onIsOpenChange(newValue: boolean, oldValue: boolean): void;
  /**
   * An ID corresponding to the trigger element that
   * causes the loading indicator to open when clicked.
   */
  trigger: string | undefined;
  triggerChanged(): void;
  /**
   * Emitted after the loading has presented.
   */
  didPresent: EventEmitter<void>;
  /**
   * Emitted before the loading has presented.
   */
  willPresent: EventEmitter<void>;
  /**
   * Emitted before the loading has dismissed.
   */
  willDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the loading has dismissed.
   */
  didDismiss: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the loading indicator has presented.
   * Shorthand for ionLoadingWillDismiss.
   */
  didPresentShorthand: EventEmitter<void>;
  /**
   * Emitted before the loading indicator has presented.
   * Shorthand for ionLoadingWillPresent.
   */
  willPresentShorthand: EventEmitter<void>;
  /**
   * Emitted before the loading indicator has dismissed.
   * Shorthand for ionLoadingWillDismiss.
   */
  willDismissShorthand: EventEmitter<OverlayEventDetail>;
  /**
   * Emitted after the loading indicator has dismissed.
   * Shorthand for ionLoadingDidDismiss.
   */
  didDismissShorthand: EventEmitter<OverlayEventDetail>;
  connectedCallback(): void;
  componentWillLoad(): void;
  componentDidLoad(): void;
  disconnectedCallback(): void;
  /**
   * Present the loading overlay after it has been created.
   */
  present(): Promise<void>;
  /**
   * Dismiss the loading overlay after it has been presented.
   *
   * @param data Any data to emit in the dismiss events.
   * @param role The role of the element that is dismissing the loading.
   * This can be useful in a button handler for determining which button was
   * clicked to dismiss the loading.
   * Some examples include: ``"cancel"`, `"destructive"`, "selected"`, and `"backdrop"`.
   */
  dismiss(data?: any, role?: string): Promise<boolean>;
  /**
   * Returns a promise that resolves when the loading did dismiss.
   */
  onDidDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  /**
   * Returns a promise that resolves when the loading will dismiss.
   */
  onWillDismiss<T = any>(): Promise<OverlayEventDetail<T>>;
  private onBackdropTap;
  private renderLoadingMessage;
  render(): any;
}
