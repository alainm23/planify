/*
 Stencil Client Patch Esm v2.22.3 | MIT Licensed | https://stenciljs.com
 */
import { BUILD } from '@stencil/core/internal/app-data';
import { CSS, plt, win, promiseResolve } from '@stencil/core';
const patchEsm = () => {
    // NOTE!! This fn cannot use async/await!
    // @ts-ignore
    if (BUILD.cssVarShim && !(CSS && CSS.supports && CSS.supports('color', 'var(--c)'))) {
        // @ts-ignore
        return import(/* webpackChunkName: "polyfills-css-shim" */ './css-shim.js').then(() => {
            if ((plt.$cssShim$ = win.__cssshim)) {
                return plt.$cssShim$.i();
            }
            else {
                // for better minification
                return 0;
            }
        });
    }
    return promiseResolve();
};
export { patchEsm };
