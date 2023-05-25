import type { ComponentInterface } from '../../stencil-public-runtime';
import type { IonicSafeString } from '../../utils/sanitization';
import type { SpinnerTypes } from '../spinner/spinner-configs';
export declare class InfiniteScrollContent implements ComponentInterface {
  private customHTMLEnabled;
  /**
   * An animated SVG spinner that shows while loading.
   */
  loadingSpinner?: SpinnerTypes | null;
  /**
   * Optional text to display while loading.
   * `loadingText` can accept either plaintext or HTML as a string.
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
  loadingText?: string | IonicSafeString;
  componentDidLoad(): void;
  private renderLoadingText;
  render(): any;
}
