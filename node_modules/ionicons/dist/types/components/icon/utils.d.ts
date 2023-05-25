import { Icon } from './icon';
export declare const getIconMap: () => Map<string, string>;
export declare const addIcons: (icons: {
  [name: string]: string;
}) => void;
export declare const getUrl: (i: Icon) => string | null;
export declare const getName: (iconName: string | undefined, icon: string | undefined, mode: string | undefined, ios: string | undefined, md: string | undefined) => string | null;
export declare const getSrc: (src: string | undefined) => string | null;
export declare const isSrc: (str: string) => boolean;
export declare const isStr: (val: any) => val is string;
export declare const toLower: (val: string) => string;
/**
 * Elements inside of web components sometimes need to inherit global attributes
 * set on the host. For example, the inner input in `ion-input` should inherit
 * the `title` attribute that developers set directly on `ion-input`. This
 * helper function should be called in componentWillLoad and assigned to a variable
 * that is later used in the render function.
 *
 * This does not need to be reactive as changing attributes on the host element
 * does not trigger a re-render.
 */
export declare const inheritAttributes: (el: HTMLElement, attributes?: string[]) => {
  [k: string]: any;
};
/**
 * Returns `true` if the document or host element
 * has a `dir` set to `rtl`. The host value will always
 * take priority over the root document value.
 */
export declare const isRTL: (hostEl?: Pick<HTMLElement, 'dir'>) => boolean;
