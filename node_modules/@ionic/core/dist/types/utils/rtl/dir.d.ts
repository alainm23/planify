/**
 * Returns `true` if the document or host element
 * has a `dir` set to `rtl`. The host value will always
 * take priority over the root document value.
 */
export declare const isRTL: (hostEl?: Pick<HTMLElement, 'dir'>) => boolean;
