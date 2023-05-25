import type { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
/**
 * @part image - The inner `img` element.
 */
export declare class Img implements ComponentInterface {
  private io?;
  private inheritedAttributes;
  el: HTMLElement;
  loadSrc?: string;
  loadError?: () => void;
  /**
   * This attribute defines the alternative text describing the image.
   * Users will see this text displayed if the image URL is wrong,
   * the image is not in one of the supported formats, or if the image is not yet downloaded.
   */
  alt?: string;
  /**
   * The image URL. This attribute is mandatory for the `<img>` element.
   */
  src?: string;
  srcChanged(): void;
  /** Emitted when the img src has been set */
  ionImgWillLoad: EventEmitter<void>;
  /** Emitted when the image has finished loading */
  ionImgDidLoad: EventEmitter<void>;
  /** Emitted when the img fails to load */
  ionError: EventEmitter<void>;
  componentWillLoad(): void;
  componentDidLoad(): void;
  private addIO;
  private load;
  private onLoad;
  private onError;
  private removeIO;
  render(): any;
}
