/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵisPromise as isPromise } from '@angular/core';
import { ReplaySubject } from 'rxjs';
import { deepEqual, isAnchor } from './utils';
const PATH_MATCH = /^([^?#]*)(\?([^#]*))?(#(.*))?$/;
const DOUBLE_SLASH_REGEX = /^\s*[\\/]{2,}/;
const IGNORE_URI_REGEXP = /^\s*(javascript|mailto):/i;
const DEFAULT_PORTS = {
    'http:': 80,
    'https:': 443,
    'ftp:': 21
};
/**
 * Location service that provides a drop-in replacement for the $location service
 * provided in AngularJS.
 *
 * @see [Using the Angular Unified Location Service](guide/upgrade#using-the-unified-angular-location-service)
 *
 * @publicApi
 */
export class $locationShim {
    constructor($injector, location, platformLocation, urlCodec, locationStrategy) {
        this.location = location;
        this.platformLocation = platformLocation;
        this.urlCodec = urlCodec;
        this.locationStrategy = locationStrategy;
        this.initializing = true;
        this.updateBrowser = false;
        this.$$absUrl = '';
        this.$$url = '';
        this.$$host = '';
        this.$$replace = false;
        this.$$path = '';
        this.$$search = '';
        this.$$hash = '';
        this.$$changeListeners = [];
        this.cachedState = null;
        this.urlChanges = new ReplaySubject(1);
        this.lastBrowserUrl = '';
        // This variable should be used *only* inside the cacheState function.
        this.lastCachedState = null;
        const initialUrl = this.browserUrl();
        let parsedUrl = this.urlCodec.parse(initialUrl);
        if (typeof parsedUrl === 'string') {
            throw 'Invalid URL';
        }
        this.$$protocol = parsedUrl.protocol;
        this.$$host = parsedUrl.hostname;
        this.$$port = parseInt(parsedUrl.port) || DEFAULT_PORTS[parsedUrl.protocol] || null;
        this.$$parseLinkUrl(initialUrl, initialUrl);
        this.cacheState();
        this.$$state = this.browserState();
        this.location.onUrlChange((newUrl, newState) => {
            this.urlChanges.next({ newUrl, newState });
        });
        if (isPromise($injector)) {
            $injector.then($i => this.initialize($i));
        }
        else {
            this.initialize($injector);
        }
    }
    initialize($injector) {
        const $rootScope = $injector.get('$rootScope');
        const $rootElement = $injector.get('$rootElement');
        $rootElement.on('click', (event) => {
            if (event.ctrlKey || event.metaKey || event.shiftKey || event.which === 2 ||
                event.button === 2) {
                return;
            }
            let elm = event.target;
            // traverse the DOM up to find first A tag
            while (elm && elm.nodeName.toLowerCase() !== 'a') {
                // ignore rewriting if no A tag (reached root element, or no parent - removed from document)
                if (elm === $rootElement[0] || !(elm = elm.parentNode)) {
                    return;
                }
            }
            if (!isAnchor(elm)) {
                return;
            }
            const absHref = elm.href;
            const relHref = elm.getAttribute('href');
            // Ignore when url is started with javascript: or mailto:
            if (IGNORE_URI_REGEXP.test(absHref)) {
                return;
            }
            if (absHref && !elm.getAttribute('target') && !event.isDefaultPrevented()) {
                if (this.$$parseLinkUrl(absHref, relHref)) {
                    // We do a preventDefault for all urls that are part of the AngularJS application,
                    // in html5mode and also without, so that we are able to abort navigation without
                    // getting double entries in the location history.
                    event.preventDefault();
                    // update location manually
                    if (this.absUrl() !== this.browserUrl()) {
                        $rootScope.$apply();
                    }
                }
            }
        });
        this.urlChanges.subscribe(({ newUrl, newState }) => {
            const oldUrl = this.absUrl();
            const oldState = this.$$state;
            this.$$parse(newUrl);
            newUrl = this.absUrl();
            this.$$state = newState;
            const defaultPrevented = $rootScope.$broadcast('$locationChangeStart', newUrl, oldUrl, newState, oldState)
                .defaultPrevented;
            // if the location was changed by a `$locationChangeStart` handler then stop
            // processing this location change
            if (this.absUrl() !== newUrl)
                return;
            // If default was prevented, set back to old state. This is the state that was locally
            // cached in the $location service.
            if (defaultPrevented) {
                this.$$parse(oldUrl);
                this.state(oldState);
                this.setBrowserUrlWithFallback(oldUrl, false, oldState);
                this.$$notifyChangeListeners(this.url(), this.$$state, oldUrl, oldState);
            }
            else {
                this.initializing = false;
                $rootScope.$broadcast('$locationChangeSuccess', newUrl, oldUrl, newState, oldState);
                this.resetBrowserUpdate();
            }
            if (!$rootScope.$$phase) {
                $rootScope.$digest();
            }
        });
        // update browser
        $rootScope.$watch(() => {
            if (this.initializing || this.updateBrowser) {
                this.updateBrowser = false;
                const oldUrl = this.browserUrl();
                const newUrl = this.absUrl();
                const oldState = this.browserState();
                let currentReplace = this.$$replace;
                const urlOrStateChanged = !this.urlCodec.areEqual(oldUrl, newUrl) || oldState !== this.$$state;
                // Fire location changes one time to on initialization. This must be done on the
                // next tick (thus inside $evalAsync()) in order for listeners to be registered
                // before the event fires. Mimicing behavior from $locationWatch:
                // https://github.com/angular/angular.js/blob/master/src/ng/location.js#L983
                if (this.initializing || urlOrStateChanged) {
                    this.initializing = false;
                    $rootScope.$evalAsync(() => {
                        // Get the new URL again since it could have changed due to async update
                        const newUrl = this.absUrl();
                        const defaultPrevented = $rootScope
                            .$broadcast('$locationChangeStart', newUrl, oldUrl, this.$$state, oldState)
                            .defaultPrevented;
                        // if the location was changed by a `$locationChangeStart` handler then stop
                        // processing this location change
                        if (this.absUrl() !== newUrl)
                            return;
                        if (defaultPrevented) {
                            this.$$parse(oldUrl);
                            this.$$state = oldState;
                        }
                        else {
                            // This block doesn't run when initializing because it's going to perform the update
                            // to the URL which shouldn't be needed when initializing.
                            if (urlOrStateChanged) {
                                this.setBrowserUrlWithFallback(newUrl, currentReplace, oldState === this.$$state ? null : this.$$state);
                                this.$$replace = false;
                            }
                            $rootScope.$broadcast('$locationChangeSuccess', newUrl, oldUrl, this.$$state, oldState);
                            if (urlOrStateChanged) {
                                this.$$notifyChangeListeners(this.url(), this.$$state, oldUrl, oldState);
                            }
                        }
                    });
                }
            }
            this.$$replace = false;
        });
    }
    resetBrowserUpdate() {
        this.$$replace = false;
        this.$$state = this.browserState();
        this.updateBrowser = false;
        this.lastBrowserUrl = this.browserUrl();
    }
    browserUrl(url, replace, state) {
        // In modern browsers `history.state` is `null` by default; treating it separately
        // from `undefined` would cause `$browser.url('/foo')` to change `history.state`
        // to undefined via `pushState`. Instead, let's change `undefined` to `null` here.
        if (typeof state === 'undefined') {
            state = null;
        }
        // setter
        if (url) {
            let sameState = this.lastHistoryState === state;
            // Normalize the inputted URL
            url = this.urlCodec.parse(url).href;
            // Don't change anything if previous and current URLs and states match.
            if (this.lastBrowserUrl === url && sameState) {
                return this;
            }
            this.lastBrowserUrl = url;
            this.lastHistoryState = state;
            // Remove server base from URL as the Angular APIs for updating URL require
            // it to be the path+.
            url = this.stripBaseUrl(this.getServerBase(), url) || url;
            // Set the URL
            if (replace) {
                this.locationStrategy.replaceState(state, '', url, '');
            }
            else {
                this.locationStrategy.pushState(state, '', url, '');
            }
            this.cacheState();
            return this;
            // getter
        }
        else {
            return this.platformLocation.href;
        }
    }
    cacheState() {
        // This should be the only place in $browser where `history.state` is read.
        this.cachedState = this.platformLocation.getState();
        if (typeof this.cachedState === 'undefined') {
            this.cachedState = null;
        }
        // Prevent callbacks fo fire twice if both hashchange & popstate were fired.
        if (deepEqual(this.cachedState, this.lastCachedState)) {
            this.cachedState = this.lastCachedState;
        }
        this.lastCachedState = this.cachedState;
        this.lastHistoryState = this.cachedState;
    }
    /**
     * This function emulates the $browser.state() function from AngularJS. It will cause
     * history.state to be cached unless changed with deep equality check.
     */
    browserState() {
        return this.cachedState;
    }
    stripBaseUrl(base, url) {
        if (url.startsWith(base)) {
            return url.slice(base.length);
        }
        return undefined;
    }
    getServerBase() {
        const { protocol, hostname, port } = this.platformLocation;
        const baseHref = this.locationStrategy.getBaseHref();
        let url = `${protocol}//${hostname}${port ? ':' + port : ''}${baseHref || '/'}`;
        return url.endsWith('/') ? url : url + '/';
    }
    parseAppUrl(url) {
        if (DOUBLE_SLASH_REGEX.test(url)) {
            throw new Error(`Bad Path - URL cannot start with double slashes: ${url}`);
        }
        let prefixed = (url.charAt(0) !== '/');
        if (prefixed) {
            url = '/' + url;
        }
        let match = this.urlCodec.parse(url, this.getServerBase());
        if (typeof match === 'string') {
            throw new Error(`Bad URL - Cannot parse URL: ${url}`);
        }
        let path = prefixed && match.pathname.charAt(0) === '/' ? match.pathname.substring(1) : match.pathname;
        this.$$path = this.urlCodec.decodePath(path);
        this.$$search = this.urlCodec.decodeSearch(match.search);
        this.$$hash = this.urlCodec.decodeHash(match.hash);
        // make sure path starts with '/';
        if (this.$$path && this.$$path.charAt(0) !== '/') {
            this.$$path = '/' + this.$$path;
        }
    }
    /**
     * Registers listeners for URL changes. This API is used to catch updates performed by the
     * AngularJS framework. These changes are a subset of the `$locationChangeStart` and
     * `$locationChangeSuccess` events which fire when AngularJS updates its internally-referenced
     * version of the browser URL.
     *
     * It's possible for `$locationChange` events to happen, but for the browser URL
     * (window.location) to remain unchanged. This `onChange` callback will fire only when AngularJS
     * actually updates the browser URL (window.location).
     *
     * @param fn The callback function that is triggered for the listener when the URL changes.
     * @param err The callback function that is triggered when an error occurs.
     */
    onChange(fn, err = (e) => { }) {
        this.$$changeListeners.push([fn, err]);
    }
    /** @internal */
    $$notifyChangeListeners(url = '', state, oldUrl = '', oldState) {
        this.$$changeListeners.forEach(([fn, err]) => {
            try {
                fn(url, state, oldUrl, oldState);
            }
            catch (e) {
                err(e);
            }
        });
    }
    /**
     * Parses the provided URL, and sets the current URL to the parsed result.
     *
     * @param url The URL string.
     */
    $$parse(url) {
        let pathUrl;
        if (url.startsWith('/')) {
            pathUrl = url;
        }
        else {
            // Remove protocol & hostname if URL starts with it
            pathUrl = this.stripBaseUrl(this.getServerBase(), url);
        }
        if (typeof pathUrl === 'undefined') {
            throw new Error(`Invalid url "${url}", missing path prefix "${this.getServerBase()}".`);
        }
        this.parseAppUrl(pathUrl);
        if (!this.$$path) {
            this.$$path = '/';
        }
        this.composeUrls();
    }
    /**
     * Parses the provided URL and its relative URL.
     *
     * @param url The full URL string.
     * @param relHref A URL string relative to the full URL string.
     */
    $$parseLinkUrl(url, relHref) {
        // When relHref is passed, it should be a hash and is handled separately
        if (relHref && relHref[0] === '#') {
            this.hash(relHref.slice(1));
            return true;
        }
        let rewrittenUrl;
        let appUrl = this.stripBaseUrl(this.getServerBase(), url);
        if (typeof appUrl !== 'undefined') {
            rewrittenUrl = this.getServerBase() + appUrl;
        }
        else if (this.getServerBase() === url + '/') {
            rewrittenUrl = this.getServerBase();
        }
        // Set the URL
        if (rewrittenUrl) {
            this.$$parse(rewrittenUrl);
        }
        return !!rewrittenUrl;
    }
    setBrowserUrlWithFallback(url, replace, state) {
        const oldUrl = this.url();
        const oldState = this.$$state;
        try {
            this.browserUrl(url, replace, state);
            // Make sure $location.state() returns referentially identical (not just deeply equal)
            // state object; this makes possible quick checking if the state changed in the digest
            // loop. Checking deep equality would be too expensive.
            this.$$state = this.browserState();
        }
        catch (e) {
            // Restore old values if pushState fails
            this.url(oldUrl);
            this.$$state = oldState;
            throw e;
        }
    }
    composeUrls() {
        this.$$url = this.urlCodec.normalize(this.$$path, this.$$search, this.$$hash);
        this.$$absUrl = this.getServerBase() + this.$$url.slice(1); // remove '/' from front of URL
        this.updateBrowser = true;
    }
    /**
     * Retrieves the full URL representation with all segments encoded according to
     * rules specified in
     * [RFC 3986](https://tools.ietf.org/html/rfc3986).
     *
     *
     * ```js
     * // given URL http://example.com/#/some/path?foo=bar&baz=xoxo
     * let absUrl = $location.absUrl();
     * // => "http://example.com/#/some/path?foo=bar&baz=xoxo"
     * ```
     */
    absUrl() {
        return this.$$absUrl;
    }
    url(url) {
        if (typeof url === 'string') {
            if (!url.length) {
                url = '/';
            }
            const match = PATH_MATCH.exec(url);
            if (!match)
                return this;
            if (match[1] || url === '')
                this.path(this.urlCodec.decodePath(match[1]));
            if (match[2] || match[1] || url === '')
                this.search(match[3] || '');
            this.hash(match[5] || '');
            // Chainable method
            return this;
        }
        return this.$$url;
    }
    /**
     * Retrieves the protocol of the current URL.
     *
     * ```js
     * // given URL http://example.com/#/some/path?foo=bar&baz=xoxo
     * let protocol = $location.protocol();
     * // => "http"
     * ```
     */
    protocol() {
        return this.$$protocol;
    }
    /**
     * Retrieves the protocol of the current URL.
     *
     * In contrast to the non-AngularJS version `location.host` which returns `hostname:port`, this
     * returns the `hostname` portion only.
     *
     *
     * ```js
     * // given URL http://example.com/#/some/path?foo=bar&baz=xoxo
     * let host = $location.host();
     * // => "example.com"
     *
     * // given URL http://user:password@example.com:8080/#/some/path?foo=bar&baz=xoxo
     * host = $location.host();
     * // => "example.com"
     * host = location.host;
     * // => "example.com:8080"
     * ```
     */
    host() {
        return this.$$host;
    }
    /**
     * Retrieves the port of the current URL.
     *
     * ```js
     * // given URL http://example.com/#/some/path?foo=bar&baz=xoxo
     * let port = $location.port();
     * // => 80
     * ```
     */
    port() {
        return this.$$port;
    }
    path(path) {
        if (typeof path === 'undefined') {
            return this.$$path;
        }
        // null path converts to empty string. Prepend with "/" if needed.
        path = path !== null ? path.toString() : '';
        path = path.charAt(0) === '/' ? path : '/' + path;
        this.$$path = path;
        this.composeUrls();
        return this;
    }
    search(search, paramValue) {
        switch (arguments.length) {
            case 0:
                return this.$$search;
            case 1:
                if (typeof search === 'string' || typeof search === 'number') {
                    this.$$search = this.urlCodec.decodeSearch(search.toString());
                }
                else if (typeof search === 'object' && search !== null) {
                    // Copy the object so it's never mutated
                    search = { ...search };
                    // remove object undefined or null properties
                    for (const key in search) {
                        if (search[key] == null)
                            delete search[key];
                    }
                    this.$$search = search;
                }
                else {
                    throw new Error('LocationProvider.search(): First argument must be a string or an object.');
                }
                break;
            default:
                if (typeof search === 'string') {
                    const currentSearch = this.search();
                    if (typeof paramValue === 'undefined' || paramValue === null) {
                        delete currentSearch[search];
                        return this.search(currentSearch);
                    }
                    else {
                        currentSearch[search] = paramValue;
                        return this.search(currentSearch);
                    }
                }
        }
        this.composeUrls();
        return this;
    }
    hash(hash) {
        if (typeof hash === 'undefined') {
            return this.$$hash;
        }
        this.$$hash = hash !== null ? hash.toString() : '';
        this.composeUrls();
        return this;
    }
    /**
     * Changes to `$location` during the current `$digest` will replace the current
     * history record, instead of adding a new one.
     */
    replace() {
        this.$$replace = true;
        return this;
    }
    state(state) {
        if (typeof state === 'undefined') {
            return this.$$state;
        }
        this.$$state = state;
        return this;
    }
}
/**
 * The factory function used to create an instance of the `$locationShim` in Angular,
 * and provides an API-compatible `$locationProvider` for AngularJS.
 *
 * @publicApi
 */
export class $locationShimProvider {
    constructor(ngUpgrade, location, platformLocation, urlCodec, locationStrategy) {
        this.ngUpgrade = ngUpgrade;
        this.location = location;
        this.platformLocation = platformLocation;
        this.urlCodec = urlCodec;
        this.locationStrategy = locationStrategy;
    }
    /**
     * Factory method that returns an instance of the $locationShim
     */
    $get() {
        return new $locationShim(this.ngUpgrade.$injector, this.location, this.platformLocation, this.urlCodec, this.locationStrategy);
    }
    /**
     * Stub method used to keep API compatible with AngularJS. This setting is configured through
     * the LocationUpgradeModule's `config` method in your Angular app.
     */
    hashPrefix(prefix) {
        throw new Error('Configure LocationUpgrade through LocationUpgradeModule.config method.');
    }
    /**
     * Stub method used to keep API compatible with AngularJS. This setting is configured through
     * the LocationUpgradeModule's `config` method in your Angular app.
     */
    html5Mode(mode) {
        throw new Error('Configure LocationUpgrade through LocationUpgradeModule.config method.');
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibG9jYXRpb25fc2hpbS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvbW1vbi91cGdyYWRlL3NyYy9sb2NhdGlvbl9zaGltLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxVQUFVLElBQUksU0FBUyxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBRXRELE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxNQUFNLENBQUM7QUFHbkMsT0FBTyxFQUFDLFNBQVMsRUFBRSxRQUFRLEVBQUMsTUFBTSxTQUFTLENBQUM7QUFFNUMsTUFBTSxVQUFVLEdBQUcsZ0NBQWdDLENBQUM7QUFDcEQsTUFBTSxrQkFBa0IsR0FBRyxlQUFlLENBQUM7QUFDM0MsTUFBTSxpQkFBaUIsR0FBRywyQkFBMkIsQ0FBQztBQUN0RCxNQUFNLGFBQWEsR0FBNEI7SUFDN0MsT0FBTyxFQUFFLEVBQUU7SUFDWCxRQUFRLEVBQUUsR0FBRztJQUNiLE1BQU0sRUFBRSxFQUFFO0NBQ1gsQ0FBQztBQUVGOzs7Ozs7O0dBT0c7QUFDSCxNQUFNLE9BQU8sYUFBYTtJQXVCeEIsWUFDSSxTQUFjLEVBQVUsUUFBa0IsRUFBVSxnQkFBa0MsRUFDOUUsUUFBa0IsRUFBVSxnQkFBa0M7UUFEOUMsYUFBUSxHQUFSLFFBQVEsQ0FBVTtRQUFVLHFCQUFnQixHQUFoQixnQkFBZ0IsQ0FBa0I7UUFDOUUsYUFBUSxHQUFSLFFBQVEsQ0FBVTtRQUFVLHFCQUFnQixHQUFoQixnQkFBZ0IsQ0FBa0I7UUF4QmxFLGlCQUFZLEdBQUcsSUFBSSxDQUFDO1FBQ3BCLGtCQUFhLEdBQUcsS0FBSyxDQUFDO1FBQ3RCLGFBQVEsR0FBVyxFQUFFLENBQUM7UUFDdEIsVUFBSyxHQUFXLEVBQUUsQ0FBQztRQUVuQixXQUFNLEdBQVcsRUFBRSxDQUFDO1FBRXBCLGNBQVMsR0FBWSxLQUFLLENBQUM7UUFDM0IsV0FBTSxHQUFXLEVB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QWhCLGdCQUFnQixDQUFrQjtJQUFHLENBQUM7SUFFbEQ7O09BRUc7SUFDSCxJQUFJO1FBQ0YsT0FBTyxJQUFJLGFBQWEsQ0FDcEIsSUFBSSxDQUFDLFNBQVMsQ0FBQyxTQUFTLEVBQUUsSUFBSSxDQUFDLFFBQVEsRUFBRSxJQUFJLENBQUMsZ0JBQWdCLEVBQUUsSUFBSSxDQUFDLFFBQVEsRUFDN0UsSUFBSSxDQUFDLGdCQUFnQixDQUFDLENBQUM7SUFDN0IsQ0FBQztJQUVEOzs7T0FHRztJQUNILFVBQVUsQ0FBQyxNQUFlO1FBQ3hCLE1BQU0sSUFBSSxLQUFLLENBQUMsd0VBQXdFLENBQUMsQ0FBQztJQUM1RixDQUFDO0lBRUQ7OztPQUdHO0lBQ0gsU0FBUyxDQUFDLElBQVU7UUFDbEIsTUFBTSxJQUFJLEtBQUssQ0FBQyx3RUFBd0UsQ0FBQyxDQUFDO0lBQzVGLENBQUM7Q0FDRiIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0xvY2F0aW9uLCBMb2NhdGlvblN0cmF0ZWd5LCBQbGF0Zm9ybUxvY2F0aW9ufSBmcm9tICdAYW5ndWxhci9jb21tb24nO1xuaW1wb3J0IHvJtWlzUHJvbWlzZSBhcyBpc1Byb21pc2V9IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuaW1wb3J0IHtVcGdyYWRlTW9kdWxlfSBmcm9tICdAYW5ndWxhci91cGdyYWRlL3N0YXRpYyc7XG5pbXBvcnQge1JlcGxheVN1YmplY3R9IGZyb20gJ3J4anMnO1xuXG5pbXBvcnQge1VybENvZGVjfSBmcm9tICcuL3BhcmFtcyc7XG5pbXBvcnQge2RlZXBFcXVhbCwgaXNBbmNob3J9IGZyb20gJy4vdXRpbHMnO1xuXG5jb25zdCBQQVRIX01BVENIID0gL14oW14/I10qKShcXD8oW14jXSopKT8oIyguKikpPyQvO1xuY29uc3QgRE9VQkxFX1NMQVNIX1JFR0VYID0gL15cXHMqW1xcXFwvXXsyLH0vO1xuY29uc3QgSUdOT1JFX1VSSV9SRUdFWFAgPSAvXlxccyooamF2YXNjcmlwdHxtYWlsdG8pOi9pO1xuY29uc3QgREVGQVVMVF9QT1JUUzoge1trZXk6IHN0cmluZ106IG51bWJlcn0gPSB7XG4gICdodHRwOic6IDgwLFxuICAnaHR0cHM6JzogNDQzLFxuICAnZnRwOic6IDIxXG59O1xuXG4vKipcbiAqIExvY2F0aW9uIHNlcnZpY2UgdGhhdCBwcm92aWRlcyBhIGRyb3AtaW4gcmVwbGFjZW1lbnQgZm9yIHRoZSAkbG9jYXRpb24gc2VydmljZVxuICogcHJvdmlkZWQgaW4gQW5ndWxhckpTLlxuICpcbiAqIEBzZWUgW1VzaW5nIHRoZSBBbmd1bGFyIFVuaWZpZWQgTG9jYXRpb24gU2VydmljZV0oZ3VpZGUvdXBncmFkZSN1c2luZy10aGUtdW5pZmllZC1hbmd1bGFyLWxvY2F0aW9uLXNlcnZpY2UpXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgY2xhc3MgJGxvY2F0aW9uU2hpbSB7XG4gIHByaXZhdGUgaW5pdGlhbGl6aW5nID0gdHJ1ZTtcbiAgcHJpdmF0ZSB1cGRhdGVCcm93c2VyID0gZmFsc2U7XG4gIHByaXZhdGUgJCRhYnNVcmw6IHN0cmluZyA9ICcnO1xuICBwcml2YXRlICQkdXJsOiBzdHJpbmcgPSAnJztcbiAgcHJpdmF0ZSAkJHByb3RvY29sOiBzdHJpbmc7XG4gIHByaXZhdGUgJCRob3N0OiBzdHJpbmcgPSAnJztcbiAgcHJpdmF0ZSAkJHBvcnQ6IG51bWJlcnxudWxsO1xuICBwcml2YXRlICQkcmVwbGFjZTogYm9vbGVhbiA9IGZhbHNlO1xuICBwcml2YXRlICQkcGF0aDogc3RyaW5nID0gJyc7XG4gIHByaXZhdGUgJCRzZWFyY2g6IGFueSA9ICcnO1xuICBwcml2YXRlICQkaGFzaDogc3RyaW5nID0gJyc7XG4gIHByaXZhdGUgJCRzdGF0ZTogdW5rbm93bjtcbiAgcHJpdmF0ZSAkJGNoYW5nZUxpc3RlbmVyczogW1xuICAgICgodXJsOiBzdHJpbmcsIHN0YXRlOiB1bmtub3duLCBvbGRVcmw6IHN0cmluZywgb2xkU3RhdGU6IHVua25vd24sIGVycj86IChlOiBFcnJvcikgPT4gdm9pZCkgPT5cbiAgICAgICAgIHZvaWQpLFxuICAgIChlOiBFcnJvcikgPT4gdm9pZFxuICBdW10gPSBbXTtcblxuICBwcml2YXRlIGNhY2hlZFN0YXRlOiB1bmtub3duID0gbnVsbDtcblxuICBwcml2YXRlIHVybENoYW5nZXMgPSBuZXcgUmVwbGF5U3ViamVjdDx7bmV3VXJsOiBzdHJpbmcsIG5ld1N0YXRlOiB1bmtub3dufT4oMSk7XG5cbiAgY29uc3RydWN0b3IoXG4gICAgICAkaW5qZWN0b3I6IGFueSwgcHJpdmF0ZSBsb2NhdGlvbjogTG9jYXRpb24sIHByaXZhdGUgcGxhdGZvcm1Mb2NhdGlvbjogUGxhdGZvcm1Mb2NhdGlvbixcbiAgICAgIHByaXZhdGUgdXJsQ29kZWM6IFVybENvZGVjLCBwcml2YXRlIGxvY2F0aW9uU3RyYXRlZ3k6IExvY2F0aW9uU3RyYXRlZ3kpIHtcbiAgICBjb25zdCBpbml0aWFsVXJsID0gdGhpcy5icm93c2VyVXJsKCk7XG5cbiAgICBsZXQgcGFyc2VkVXJsID0gdGhpcy51cmxDb2RlYy5wYXJzZShpbml0aWFsVXJsKTtcblxuICAgIGlmICh0eXBlb2YgcGFyc2VkVXJsID09PSAnc3RyaW5nJykge1xuICAgICAgdGhyb3cgJ0ludmFsaWQgVVJMJztcbiAgICB9XG5cbiAgICB0aGlzLiQkcHJvdG9jb2wgPSBwYXJzZWRVcmwucHJvdG9jb2w7XG4gICAgdGhpcy4kJGhvc3QgPSBwYXJzZWRVcmwuaG9zdG5hbWU7XG4gICAgdGhpcy4kJHBvcnQgPSBwYXJzZUludChwYXJzZWRVcmwucG9ydCkgfHwgREVGQVVMVF9QT1JUU1twYXJzZWRVcmwucHJvdG9jb2xdIHx8IG51bGw7XG5cbiAgICB0aGlzLiQkcGFyc2VMaW5rVXJsKGluaXRpYWxVcmwsIGluaXRpYWxVcmwpO1xuICAgIHRoaXMuY2FjaGVTdGF0ZSgpO1xuICAgIHRoaXMuJCRzdGF0ZSA9IHRoaXMuYnJvd3NlclN0YXRlKCk7XG5cbiAgICB0aGlzLmxvY2F0aW9uLm9uVXJsQ2hhbmdlKChuZXdVcmwsIG5ld1N0YXRlKSA9PiB7XG4gICAgICB0aGlzLnVybENoYW5nZXMubmV4dCh7bmV3VXJsLCBuZXdTdGF0ZX0pO1xuICAgIH0pO1xuXG4gICAgaWYgKGlzUHJvbWlzZSgkaW5qZWN0b3IpKSB7XG4gICAgICAkaW5qZWN0b3IudGhlbigkaSA9PiB0aGlzLmluaXRpYWxpemUoJGkpKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5pbml0aWFsaXplKCRpbmplY3Rvcik7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBpbml0aWFsaXplKCRpbmplY3RvcjogYW55KSB7XG4gICAgY29uc3QgJHJvb3RTY29wZSA9ICRpbmplY3Rvci5nZXQoJyRyb290U2NvcGUnKTtcbiAgICBjb25zdCAkcm9vdEVsZW1lbnQgPSAkaW5qZWN0b3IuZ2V0KCckcm9vdEVsZW1lbnQnKTtcblxuICAgICRyb290RWxlbWVudC5vbignY2xpY2snLCAoZXZlbnQ6IGFueSkgPT4ge1xuICAgICAgaWYgKGV2ZW50LmN0cmxLZXkgfHwgZXZlbnQubWV0YUtleSB8fCBldmVudC5zaGlmdEtleSB8fCBldmVudC53aGljaCA9PT0gMiB8fFxuICAgICAgICAgIGV2ZW50LmJ1dHRvbiA9PT0gMikge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIGxldCBlbG06IChOb2RlJlBhcmVudE5vZGUpfG51bGwgPSBldmVudC50YXJnZXQ7XG5cbiAgICAgIC8vIHRyYXZlcnNlIHRoZSBET00gdXAgdG8gZmluZCBmaXJzdCBBIHRhZ1xuICAgICAgd2hpbGUgKGVsbSAmJiBlbG0ubm9kZU5hbWUudG9Mb3dlckNhc2UoKSAhPT0gJ2EnKSB7XG4gICAgICAgIC8vIGlnbm9yZSByZXdyaXRpbmcgaWYgbm8gQSB0YWcgKHJlYWNoZWQgcm9vdCBlbGVtZW50LCBvciBubyBwYXJlbnQgLSByZW1vdmVkIGZyb20gZG9jdW1lbnQpXG4gICAgICAgIGlmIChlbG0gPT09ICRyb290RWxlbWVudFswXSB8fCAhKGVsbSA9IGVsbS5wYXJlbnROb2RlKSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBpZiAoIWlzQW5jaG9yKGVsbSkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBhYnNIcmVmID0gZWxtLmhyZWY7XG4gICAgICBjb25zdCByZWxIcmVmID0gZWxtLmdldEF0dHJpYnV0ZSgnaHJlZicpO1xuXG4gICAgICAvLyBJZ25vcmUgd2hlbiB1cmwgaXMgc3RhcnRlZCB3aXRoIGphdmFzY3JpcHQ6IG9yIG1haWx0bzpcbiAgICAgIGlmIChJR05PUkVfVVJJX1JFR0VYUC50ZXN0KGFic0hyZWYpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgaWYgKGFic0hyZWYgJiYgIWVsbS5nZXRBdHRyaWJ1dGUoJ3RhcmdldCcpICYmICFldmVudC5pc0RlZmF1bHRQcmV2ZW50ZWQoKSkge1xuICAgICAgICBpZiAodGhpcy4kJHBhcnNlTGlua1VybChhYnNIcmVmLCByZWxIcmVmKSkge1xuICAgICAgICAgIC8vIFdlIGRvIGEgcHJldmVudERlZmF1bHQgZm9yIGFsbCB1cmxzIHRoYXQgYXJlIHBhcnQgb2YgdGhlIEFuZ3VsYXJKUyBhcHBsaWNhdGlvbixcbiAgICAgICAgICAvLyBpbiBodG1sNW1vZGUgYW5kIGFsc28gd2l0aG91dCwgc28gdGhhdCB3ZSBhcmUgYWJsZSB0byBhYm9ydCBuYXZpZ2F0aW9uIHdpdGhvdXRcbiAgICAgICAgICAvLyBnZXR0aW5nIGRvdWJsZSBlbnRyaWVzIGluIHRoZSBsb2NhdGlvbiBoaXN0b3J5LlxuICAgICAgICAgIGV2ZW50LnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgICAgLy8gdXBkYXRlIGxvY2F0aW9uIG1hbnVhbGx5XG4gICAgICAgICAgaWYgKHRoaXMuYWJzVXJsKCkgIT09IHRoaXMuYnJvd3NlclVybCgpKSB7XG4gICAgICAgICAgICAkcm9vdFNjb3BlLiRhcHBseSgpO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0pO1xuXG4gICAgdGhpcy51cmxDaGFuZ2VzLnN1YnNjcmliZSgoe25ld1VybCwgbmV3U3RhdGV9KSA9PiB7XG4gICAgICBjb25zdCBvbGRVcmwgPSB0aGlzLmFic1VybCgpO1xuICAgICAgY29uc3Qgb2xkU3RhdGUgPSB0aGlzLiQkc3RhdGU7XG4gICAgICB0aGlzLiQkcGFyc2UobmV3VXJsKTtcbiAgICAgIG5ld1VybCA9IHRoaXMuYWJzVXJsKCk7XG4gICAgICB0aGlzLiQkc3RhdGUgPSBuZXdTdGF0ZTtcbiAgICAgIGNvbnN0IGRlZmF1bHRQcmV2ZW50ZWQgPVxuICAgICAgICAgICRyb290U2NvcGUuJGJyb2FkY2FzdCgnJGxvY2F0aW9uQ2hhbmdlU3RhcnQnLCBuZXdVcmwsIG9sZFVybCwgbmV3U3RhdGUsIG9sZFN0YXRlKVxuICAgICAgICAgICAgICAuZGVmYXVsdFByZXZlbnRlZDtcblxuICAgICAgLy8gaWYgdGhlIGxvY2F0aW9uIHdhcyBjaGFuZ2VkIGJ5IGEgYCRsb2NhdGlvbkNoYW5nZVN0YXJ0YCBoYW5kbGVyIHRoZW4gc3RvcFxuICAgICAgLy8gcHJvY2Vzc2luZyB0aGlzIGxvY2F0aW9uIGNoYW5nZVxuICAgICAgaWYgKHRoaXMuYWJzVXJsKCkgIT09IG5ld1VybCkgcmV0dXJuO1xuXG4gICAgICAvLyBJZiBkZWZhdWx0IHdhcyBwcmV2ZW50ZWQsIHNldCBiYWNrIHRvIG9sZCBzdGF0ZS4gVGhpcyBpcyB0aGUgc3RhdGUgdGhhdCB3YXMgbG9jYWxseVxuICAgICAgLy8gY2FjaGVkIGluIHRoZSAkbG9jYXRpb24gc2VydmljZS5cbiAgICAgIGlmIChkZWZhdWx0UHJldmVudGVkKSB7XG4gICAgICAgIHRoaXMuJCRwYXJzZShvbGRVcmwpO1xuICAgICAgICB0aGlzLnN0YXRlKG9sZFN0YXRlKTtcbiAgICAgICAgdGhpcy5zZXRCcm93c2VyVXJsV2l0aEZhbGxiYWNrKG9sZFVybCwgZmFsc2UsIG9sZFN0YXRlKTtcbiAgICAgICAgdGhpcy4kJG5vdGlmeUNoYW5nZUxpc3RlbmVycyh0aGlzLnVybCgpLCB0aGlzLiQkc3RhdGUsIG9sZFVybCwgb2xkU3RhdGUpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGhpcy5pbml0aWFsaXppbmcgPSBmYWxzZTtcbiAgICAgICAgJHJvb3RTY29wZS4kYnJvYWRjYXN0KCckbG9jYXRpb25DaGFuZ2VTdWNjZXNzJywgbmV3VXJsLCBvbGRVcmwsIG5ld1N0YXRlLCBvbGRTdGF0ZSk7XG4gICAgICAgIHRoaXMucmVzZXRCcm93c2VyVXBkYXRlKCk7XG4gICAgICB9XG4gICAgICBpZiAoISRyb290U2NvcGUuJCRwaGFzZSkge1xuICAgICAgICAkcm9vdFNjb3BlLiRkaWdlc3QoKTtcbiAgICAgIH1cbiAgICB9KTtcblxuICAgIC8vIHVwZGF0ZSBicm93c2VyXG4gICAgJHJvb3RTY29wZS4kd2F0Y2goKCkgPT4ge1xuICAgICAgaWYgKHRoaXMuaW5pdGlhbGl6aW5nIHx8IHRoaXMudXBkYXRlQnJvd3Nlcikge1xuICAgICAgICB0aGlzLnVwZGF0ZUJyb3dzZXIgPSBmYWxzZTtcblxuICAgICAgICBjb25zdCBvbGRVcmwgPSB0aGlzLmJyb3dzZXJVcmwoKTtcbiAgICAgICAgY29uc3QgbmV3VXJsID0gdGhpcy5hYnNVcmwoKTtcbiAgICAgICAgY29uc3Qgb2xkU3RhdGUgPSB0aGlzLmJyb3dzZXJTdGF0ZSgpO1xuICAgICAgICBsZXQgY3VycmVudFJlcGxhY2UgPSB0aGlzLiQkcmVwbGFjZTtcblxuICAgICAgICBjb25zdCB1cmxPclN0YXRlQ2hhbmdlZCA9XG4gICAgICAgICAgICAhdGhpcy51cmxDb2RlYy5hcmVFcXVhbChvbGRVcmwsIG5ld1VybCkgfHwgb2xkU3RhdGUgIT09IHRoaXMuJCRzdGF0ZTtcblxuICAgICAgICAvLyBGaXJlIGxvY2F0aW9uIGNoYW5nZXMgb25lIHRpbWUgdG8gb24gaW5pdGlhbGl6YXRpb24uIFRoaXMgbXVzdCBiZSBkb25lIG9uIHRoZVxuICAgICAgICAvLyBuZXh0IHRpY2sgKHRodXMgaW5zaWRlICRldmFsQXN5bmMoKSkgaW4gb3JkZXIgZm9yIGxpc3RlbmVycyB0byBiZSByZWdpc3RlcmVkXG4gICAgICAgIC8vIGJlZm9yZSB0aGUgZXZlbnQgZmlyZXMuIE1pbWljaW5nIGJlaGF2aW9yIGZyb20gJGxvY2F0aW9uV2F0Y2g6XG4gICAgICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIuanMvYmxvYi9tYXN0ZXIvc3JjL25nL2xvY2F0aW9uLmpzI0w5ODNcbiAgICAgICAgaWYgKHRoaXMuaW5pdGlhbGl6aW5nIHx8IHVybE9yU3RhdGVDaGFuZ2VkKSB7XG4gICAgICAgICAgdGhpcy5pbml0aWFsaXppbmcgPSBmYWxzZTtcblxuICAgICAgICAgICRyb290U2NvcGUuJGV2YWxBc3luYygoKSA9PiB7XG4gICAgICAgICAgICAvLyBHZXQgdGhlIG5ldyBVUkwgYWdhaW4gc2luY2UgaXQgY291bGQgaGF2ZSBjaGFuZ2VkIGR1ZSB0byBhc3luYyB1cGRhdGVcbiAgICAgICAgICAgIGNvbnN0IG5ld1VybCA9IHRoaXMuYWJzVXJsKCk7XG4gICAgICAgICAgICBjb25zdCBkZWZhdWx0UHJldmVudGVkID1cbiAgICAgICAgICAgICAgICAkcm9vdFNjb3BlXG4gICAgICAgICAgICAgICAgICAgIC4kYnJvYWRjYXN0KCckbG9jYXRpb25DaGFuZ2VTdGFydCcsIG5ld1VybCwgb2xkVXJsLCB0aGlzLiQkc3RhdGUsIG9sZFN0YXRlKVxuICAgICAgICAgICAgICAgICAgICAuZGVmYXVsdFByZXZlbnRlZDtcblxuICAgICAgICAgICAgLy8gaWYgdGhlIGxvY2F0aW9uIHdhcyBjaGFuZ2VkIGJ5IGEgYCRsb2NhdGlvbkNoYW5nZVN0YXJ0YCBoYW5kbGVyIHRoZW4gc3RvcFxuICAgICAgICAgICAgLy8gcHJvY2Vzc2luZyB0aGlzIGxvY2F0aW9uIGNoYW5nZVxuICAgICAgICAgICAgaWYgKHRoaXMuYWJzVXJsKCkgIT09IG5ld1VybCkgcmV0dXJuO1xuXG4gICAgICAgICAgICBpZiAoZGVmYXVsdFByZXZlbnRlZCkge1xuICAgICAgICAgICAgICB0aGlzLiQkcGFyc2Uob2xkVXJsKTtcbiAgICAgICAgICAgICAgdGhpcy4kJHN0YXRlID0gb2xkU3RhdGU7XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAvLyBUaGlzIGJsb2NrIGRvZXNuJ3QgcnVuIHdoZW4gaW5pdGlhbGl6aW5nIGJlY2F1c2UgaXQncyBnb2luZyB0byBwZXJmb3JtIHRoZSB1cGRhdGVcbiAgICAgICAgICAgICAgLy8gdG8gdGhlIFVSTCB3aGljaCBzaG91bGRuJ3QgYmUgbmVlZGVkIHdoZW4gaW5pdGlhbGl6aW5nLlxuICAgICAgICAgICAgICBpZiAodXJsT3JTdGF0ZUNoYW5nZWQpIHtcbiAgICAgICAgICAgICAgICB0aGlzLnNldEJyb3dzZXJVcmxXaXRoRmFsbGJhY2soXG4gICAgICAgICAgICAgICAgICAgIG5ld1VybCwgY3VycmVudFJlcGxhY2UsIG9sZFN0YXRlID09PSB0aGlzLiQkc3RhdGUgPyBudWxsIDogdGhpcy4kJHN0YXRlKTtcbiAgICAgICAgICAgICAgICB0aGlzLiQkcmVwbGFjZSA9IGZhbHNlO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICRyb290U2NvcGUuJGJyb2FkY2FzdChcbiAgICAgICAgICAgICAgICAgICckbG9jYXRpb25DaGFuZ2VTdWNjZXNzJywgbmV3VXJsLCBvbGRVcmwsIHRoaXMuJCRzdGF0ZSwgb2xkU3RhdGUpO1xuICAgICAgICAgICAgICBpZiAodXJsT3JTdGF0ZUNoYW5nZWQpIHtcbiAgICAgICAgICAgICAgICB0aGlzLiQkbm90aWZ5Q2hhbmdlTGlzdGVuZXJzKHRoaXMudXJsKCksIHRoaXMuJCRzdGF0ZSwgb2xkVXJsLCBvbGRTdGF0ZSk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgdGhpcy4kJHJlcGxhY2UgPSBmYWxzZTtcbiAgICB9KTtcbiAgfVxuXG4gIHByaXZhdGUgcmVzZXRCcm93c2VyVXBkYXRlKCkge1xuICAgIHRoaXMuJCRyZXBsYWNlID0gZmFsc2U7XG4gICAgdGhpcy4kJHN0YXRlID0gdGhpcy5icm93c2VyU3RhdGUoKTtcbiAgICB0aGlzLnVwZGF0ZUJyb3dzZXIgPSBmYWxzZTtcbiAgICB0aGlzLmxhc3RCcm93c2VyVXJsID0gdGhpcy5icm93c2VyVXJsKCk7XG4gIH1cblxuICBwcml2YXRlIGxhc3RIaXN0b3J5U3RhdGU6IHVua25vd247XG4gIHByaXZhdGUgbGFzdEJyb3dzZXJVcmw6IHN0cmluZyA9ICcnO1xuICBwcml2YXRlIGJyb3dzZXJVcmwoKTogc3RyaW5nO1xuICBwcml2YXRlIGJyb3dzZXJVcmwodXJsOiBzdHJpbmcsIHJlcGxhY2U/OiBib29sZWFuLCBzdGF0ZT86IHVua25vd24pOiB0aGlzO1xuICBwcml2YXRlIGJyb3dzZXJVcmwodXJsPzogc3RyaW5nLCByZXBsYWNlPzogYm9vbGVhbiwgc3RhdGU/OiB1bmtub3duKSB7XG4gICAgLy8gSW4gbW9kZXJuIGJyb3dzZXJzIGBoaXN0b3J5LnN0YXRlYCBpcyBgbnVsbGAgYnkgZGVmYXVsdDsgdHJlYXRpbmcgaXQgc2VwYXJhdGVseVxuICAgIC8vIGZyb20gYHVuZGVmaW5lZGAgd291bGQgY2F1c2UgYCRicm93c2VyLnVybCgnL2ZvbycpYCB0byBjaGFuZ2UgYGhpc3Rvcnkuc3RhdGVgXG4gICAgLy8gdG8gdW5kZWZpbmVkIHZpYSBgcHVzaFN0YXRlYC4gSW5zdGVhZCwgbGV0J3MgY2hhbmdlIGB1bmRlZmluZWRgIHRvIGBudWxsYCBoZXJlLlxuICAgIGlmICh0eXBlb2Ygc3RhdGUgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICBzdGF0ZSA9IG51bGw7XG4gICAgfVxuXG4gICAgLy8gc2V0dGVyXG4gICAgaWYgKHVybCkge1xuICAgICAgbGV0IHNhbWVTdGF0ZSA9IHRoaXMubGFzdEhpc3RvcnlTdGF0ZSA9PT0gc3RhdGU7XG5cbiAgICAgIC8vIE5vcm1hbGl6ZSB0aGUgaW5wdXR0ZWQgVVJMXG4gICAgICB1cmwgPSB0aGlzLnVybENvZGVjLnBhcnNlKHVybCkuaHJlZjtcblxuICAgICAgLy8gRG9uJ3QgY2hhbmdlIGFueXRoaW5nIGlmIHByZXZpb3VzIGFuZCBjdXJyZW50IFVSTHMgYW5kIHN0YXRlcyBtYXRjaC5cbiAgICAgIGlmICh0aGlzLmxhc3RCcm93c2VyVXJsID09PSB1cmwgJiYgc2FtZVN0YXRlKSB7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgICAgfVxuICAgICAgdGhpcy5sYXN0QnJvd3NlclVybCA9IHVybDtcbiAgICAgIHRoaXMubGFzdEhpc3RvcnlTdGF0ZSA9IHN0YXRlO1xuXG4gICAgICAvLyBSZW1vdmUgc2VydmVyIGJhc2UgZnJvbSBVUkwgYXMgdGhlIEFuZ3VsYXIgQVBJcyBmb3IgdXBkYXRpbmcgVVJMIHJlcXVpcmVcbiAgICAgIC8vIGl0IHRvIGJlIHRoZSBwYXRoKy5cbiAgICAgIHVybCA9IHRoaXMuc3RyaXBCYXNlVXJsKHRoaXMuZ2V0U2VydmVyQmFzZSgpLCB1cmwpIHx8IHVybDtcblxuICAgICAgLy8gU2V0IHRoZSBVUkxcbiAgICAgIGlmIChyZXBsYWNlKSB7XG4gICAgICAgIHRoaXMubG9jYXRpb25TdHJhdGVneS5yZXBsYWNlU3RhdGUoc3RhdGUsICcnLCB1cmwsICcnKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMubG9jYXRpb25TdHJhdGVneS5wdXNoU3RhdGUoc3RhdGUsICcnLCB1cmwsICcnKTtcbiAgICAgIH1cblxuICAgICAgdGhpcy5jYWNoZVN0YXRlKCk7XG5cbiAgICAgIHJldHVybiB0aGlzO1xuICAgICAgLy8gZ2V0dGVyXG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiB0aGlzLnBsYXRmb3JtTG9jYXRpb24uaHJlZjtcbiAgICB9XG4gIH1cblxuICAvLyBUaGlzIHZhcmlhYmxlIHNob3VsZCBiZSB1c2VkICpvbmx5KiBpbnNpZGUgdGhlIGNhY2hlU3RhdGUgZnVuY3Rpb24uXG4gIHByaXZhdGUgbGFzdENhY2hlZFN0YXRlOiB1bmtub3duID0gbnVsbDtcbiAgcHJpdmF0ZSBjYWNoZVN0YXRlKCkge1xuICAgIC8vIFRoaXMgc2hvdWxkIGJlIHRoZSBvbmx5IHBsYWNlIGluICRicm93c2VyIHdoZXJlIGBoaXN0b3J5LnN0YXRlYCBpcyByZWFkLlxuICAgIHRoaXMuY2FjaGVkU3RhdGUgPSB0aGlzLnBsYXRmb3JtTG9jYXRpb24uZ2V0U3RhdGUoKTtcbiAgICBpZiAodHlwZW9mIHRoaXMuY2FjaGVkU3RhdGUgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICB0aGlzLmNhY2hlZFN0YXRlID0gbnVsbDtcbiAgICB9XG5cbiAgICAvLyBQcmV2ZW50IGNhbGxiYWNrcyBmbyBmaXJlIHR3aWNlIGlmIGJvdGggaGFzaGNoYW5nZSAmIHBvcHN0YXRlIHdlcmUgZmlyZWQuXG4gICAgaWYgKGRlZXBFcXVhbCh0aGlzLmNhY2hlZFN0YXRlLCB0aGlzLmxhc3RDYWNoZWRTdGF0ZSkpIHtcbiAgICAgIHRoaXMuY2FjaGVkU3RhdGUgPSB0aGlzLmxhc3RDYWNoZWRTdGF0ZTtcbiAgICB9XG5cbiAgICB0aGlzLmxhc3RDYWNoZWRTdGF0ZSA9IHRoaXMuY2FjaGVkU3RhdGU7XG4gICAgdGhpcy5sYXN0SGlzdG9yeVN0YXRlID0gdGhpcy5jYWNoZWRTdGF0ZTtcbiAgfVxuXG4gIC8qKlxuICAgKiBUaGlzIGZ1bmN0aW9uIGVtdWxhdGVzIHRoZSAkYnJvd3Nlci5zdGF0ZSgpIGZ1bmN0aW9uIGZyb20gQW5ndWxhckpTLiBJdCB3aWxsIGNhdXNlXG4gICAqIGhpc3Rvcnkuc3RhdGUgdG8gYmUgY2FjaGVkIHVubGVzcyBjaGFuZ2VkIHdpdGggZGVlcCBlcXVhbGl0eSBjaGVjay5cbiAgICovXG4gIHByaXZhdGUgYnJvd3NlclN0YXRlKCk6IHVua25vd24ge1xuICAgIHJldHVybiB0aGlzLmNhY2hlZFN0YXRlO1xuICB9XG5cbiAgcHJpdmF0ZSBzdHJpcEJhc2VVcmwoYmFzZTogc3RyaW5nLCB1cmw6IHN0cmluZykge1xuICAgIGlmICh1cmwuc3RhcnRzV2l0aChiYXNlKSkge1xuICAgICAgcmV0dXJuIHVybC5zbGljZShiYXNlLmxlbmd0aCk7XG4gICAgfVxuICAgIHJldHVybiB1bmRlZmluZWQ7XG4gIH1cblxuICBwcml2YXRlIGdldFNlcnZlckJhc2UoKSB7XG4gICAgY29uc3Qge3Byb3RvY29sLCBob3N0bmFtZSwgcG9ydH0gPSB0aGlzLnBsYXRmb3JtTG9jYXRpb247XG4gICAgY29uc3QgYmFzZUhyZWYgPSB0aGlzLmxvY2F0aW9uU3RyYXRlZ3kuZ2V0QmFzZUhyZWYoKTtcbiAgICBsZXQgdXJsID0gYCR7cHJvdG9jb2x9Ly8ke2hvc3RuYW1lfSR7cG9ydCA/ICc6JyArIHBvcnQgOiAnJ30ke2Jhc2VIcmVmIHx8ICcvJ31gO1xuICAgIHJldHVybiB1cmwuZW5kc1dpdGgoJy8nKSA/IHVybCA6IHVybCArICcvJztcbiAgfVxuXG4gIHByaXZhdGUgcGFyc2VBcHBVcmwodXJsOiBzdHJpbmcpIHtcbiAgICBpZiAoRE9VQkxFX1NMQVNIX1JFR0VYLnRlc3QodXJsKSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKGBCYWQgUGF0aCAtIFVSTCBjYW5ub3Qgc3RhcnQgd2l0aCBkb3VibGUgc2xhc2hlczogJHt1cmx9YCk7XG4gICAgfVxuXG4gICAgbGV0IHByZWZpeGVkID0gKHVybC5jaGFyQXQoMCkgIT09ICcvJyk7XG4gICAgaWYgKHByZWZpeGVkKSB7XG4gICAgICB1cmwgPSAnLycgKyB1cmw7XG4gICAgfVxuICAgIGxldCBtYXRjaCA9IHRoaXMudXJsQ29kZWMucGFyc2UodXJsLCB0aGlzLmdldFNlcnZlckJhc2UoKSk7XG4gICAgaWYgKHR5cGVvZiBtYXRjaCA9PT0gJ3N0cmluZycpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihgQmFkIFVSTCAtIENhbm5vdCBwYXJzZSBVUkw6ICR7dXJsfWApO1xuICAgIH1cbiAgICBsZXQgcGF0aCA9XG4gICAgICAgIHByZWZpeGVkICYmIG1hdGNoLnBhdGhuYW1lLmNoYXJBdCgwKSA9PT0gJy8nID8gbWF0Y2gucGF0aG5hbWUuc3Vic3RyaW5nKDEpIDogbWF0Y2gucGF0aG5hbWU7XG4gICAgdGhpcy4kJHBhdGggPSB0aGlzLnVybENvZGVjLmRlY29kZVBhdGgocGF0aCk7XG4gICAgdGhpcy4kJHNlYXJjaCA9IHRoaXMudXJsQ29kZWMuZGVjb2RlU2VhcmNoKG1hdGNoLnNlYXJjaCk7XG4gICAgdGhpcy4kJGhhc2ggPSB0aGlzLnVybENvZGVjLmRlY29kZUhhc2gobWF0Y2guaGFzaCk7XG5cbiAgICAvLyBtYWtlIHN1cmUgcGF0aCBzdGFydHMgd2l0aCAnLyc7XG4gICAgaWYgKHRoaXMuJCRwYXRoICYmIHRoaXMuJCRwYXRoLmNoYXJBdCgwKSAhPT0gJy8nKSB7XG4gICAgICB0aGlzLiQkcGF0aCA9ICcvJyArIHRoaXMuJCRwYXRoO1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBSZWdpc3RlcnMgbGlzdGVuZXJzIGZvciBVUkwgY2hhbmdlcy4gVGhpcyBBUEkgaXMgdXNlZCB0byBjYXRjaCB1cGRhdGVzIHBlcmZvcm1lZCBieSB0aGVcbiAgICogQW5ndWxhckpTIGZyYW1ld29yay4gVGhlc2UgY2hhbmdlcyBhcmUgYSBzdWJzZXQgb2YgdGhlIGAkbG9jYXRpb25DaGFuZ2VTdGFydGAgYW5kXG4gICAqIGAkbG9jYXRpb25DaGFuZ2VTdWNjZXNzYCBldmVudHMgd2hpY2ggZmlyZSB3aGVuIEFuZ3VsYXJKUyB1cGRhdGVzIGl0cyBpbnRlcm5hbGx5LXJlZmVyZW5jZWRcbiAgICogdmVyc2lvbiBvZiB0aGUgYnJvd3NlciBVUkwuXG4gICAqXG4gICAqIEl0J3MgcG9zc2libGUgZm9yIGAkbG9jYXRpb25DaGFuZ2VgIGV2ZW50cyB0byBoYXBwZW4sIGJ1dCBmb3IgdGhlIGJyb3dzZXIgVVJMXG4gICAqICh3aW5kb3cubG9jYXRpb24pIHRvIHJlbWFpbiB1bmNoYW5nZWQuIFRoaXMgYG9uQ2hhbmdlYCBjYWxsYmFjayB3aWxsIGZpcmUgb25seSB3aGVuIEFuZ3VsYXJKU1xuICAgKiBhY3R1YWxseSB1cGRhdGVzIHRoZSBicm93c2VyIFVSTCAod2luZG93LmxvY2F0aW9uKS5cbiAgICpcbiAgICogQHBhcmFtIGZuIFRoZSBjYWxsYmFjayBmdW5jdGlvbiB0aGF0IGlzIHRyaWdnZXJlZCBmb3IgdGhlIGxpc3RlbmVyIHdoZW4gdGhlIFVSTCBjaGFuZ2VzLlxuICAgKiBAcGFyYW0gZXJyIFRoZSBjYWxsYmFjayBmdW5jdGlvbiB0aGF0IGlzIHRyaWdnZXJlZCB3aGVuIGFuIGVycm9yIG9jY3Vycy5cbiAgICovXG4gIG9uQ2hhbmdlKFxuICAgICAgZm46ICh1cmw6IHN0cmluZywgc3RhdGU6IHVua25vd24sIG9sZFVybDogc3RyaW5nLCBvbGRTdGF0ZTogdW5rbm93bikgPT4gdm9pZCxcbiAgICAgIGVycjogKGU6IEVycm9yKSA9PiB2b2lkID0gKGU6IEVycm9yKSA9PiB7fSkge1xuICAgIHRoaXMuJCRjaGFuZ2VMaXN0ZW5lcnMucHVzaChbZm4sIGVycl0pO1xuICB9XG5cbiAgLyoqIEBpbnRlcm5hbCAqL1xuICAkJG5vdGlmeUNoYW5nZUxpc3RlbmVycyhcbiAgICAgIHVybDogc3RyaW5nID0gJycsIHN0YXRlOiB1bmtub3duLCBvbGRVcmw6IHN0cmluZyA9ICcnLCBvbGRTdGF0ZTogdW5rbm93bikge1xuICAgIHRoaXMuJCRjaGFuZ2VMaXN0ZW5lcnMuZm9yRWFjaCgoW2ZuLCBlcnJdKSA9PiB7XG4gICAgICB0cnkge1xuICAgICAgICBmbih1cmwsIHN0YXRlLCBvbGRVcmwsIG9sZFN0YXRlKTtcbiAgICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgZXJyKGUgYXMgRXJyb3IpO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG5cbiAgLyoqXG4gICAqIFBhcnNlcyB0aGUgcHJvdmlkZWQgVVJMLCBhbmQgc2V0cyB0aGUgY3VycmVudCBVUkwgdG8gdGhlIHBhcnNlZCByZXN1bHQuXG4gICAqXG4gICAqIEBwYXJhbSB1cmwgVGhlIFVSTCBzdHJpbmcuXG4gICAqL1xuICAkJHBhcnNlKHVybDogc3RyaW5nKSB7XG4gICAgbGV0IHBhdGhVcmw6IHN0cmluZ3x1bmRlZmluZWQ7XG4gICAgaWYgKHVybC5zdGFydHNXaXRoKCcvJykpIHtcbiAgICAgIHBhdGhVcmwgPSB1cmw7XG4gICAgfSBlbHNlIHtcbiAgICAgIC8vIFJlbW92ZSBwcm90b2NvbCAmIGhvc3RuYW1lIGlmIFVSTCBzdGFydHMgd2l0aCBpdFxuICAgICAgcGF0aFVybCA9IHRoaXMuc3RyaXBCYXNlVXJsKHRoaXMuZ2V0U2VydmVyQmFzZSgpLCB1cmwpO1xuICAgIH1cbiAgICBpZiAodHlwZW9mIHBhdGhVcmwgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYEludmFsaWQgdXJsIFwiJHt1cmx9XCIsIG1pc3NpbmcgcGF0aCBwcmVmaXggXCIke3RoaXMuZ2V0U2VydmVyQmFzZSgpfVwiLmApO1xuICAgIH1cblxuICAgIHRoaXMucGFyc2VBcHBVcmwocGF0aFVybCk7XG5cbiAgICBpZiAoIXRoaXMuJCRwYXRoKSB7XG4gICAgICB0aGlzLiQkcGF0aCA9ICcvJztcbiAgICB9XG4gICAgdGhpcy5jb21wb3NlVXJscygpO1xuICB9XG5cbiAgLyoqXG4gICAqIFBhcnNlcyB0aGUgcHJvdmlkZWQgVVJMIGFuZCBpdHMgcmVsYXRpdmUgVVJMLlxuICAgKlxuICAgKiBAcGFyYW0gdXJsIFRoZSBmdWxsIFVSTCBzdHJpbmcuXG4gICAqIEBwYXJhbSByZWxIcmVmIEEgVVJMIHN0cmluZyByZWxhdGl2ZSB0byB0aGUgZnVsbCBVUkwgc3RyaW5nLlxuICAgKi9cbiAgJCRwYXJzZUxpbmtVcmwodXJsOiBzdHJpbmcsIHJlbEhyZWY/OiBzdHJpbmd8bnVsbCk6IGJvb2xlYW4ge1xuICAgIC8vIFdoZW4gcmVsSHJlZiBpcyBwYXNzZWQsIGl0IHNob3VsZCBiZSBhIGhhc2ggYW5kIGlzIGhhbmRsZWQgc2VwYXJhdGVseVxuICAgIGlmIChyZWxIcmVmICYmIHJlbEhyZWZbMF0gPT09ICcjJykge1xuICAgICAgdGhpcy5oYXNoKHJlbEhyZWYuc2xpY2UoMSkpO1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuICAgIGxldCByZXdyaXR0ZW5Vcmw7XG4gICAgbGV0IGFwcFVybCA9IHRoaXMuc3RyaXBCYXNlVXJsKHRoaXMuZ2V0U2VydmVyQmFzZSgpLCB1cmwpO1xuICAgIGlmICh0eXBlb2YgYXBwVXJsICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgcmV3cml0dGVuVXJsID0gdGhpcy5nZXRTZXJ2ZXJCYXNlKCkgKyBhcHBVcmw7XG4gICAgfSBlbHNlIGlmICh0aGlzLmdldFNlcnZlckJhc2UoKSA9PT0gdXJsICsgJy8nKSB7XG4gICAgICByZXdyaXR0ZW5VcmwgPSB0aGlzLmdldFNlcnZlckJhc2UoKTtcbiAgICB9XG4gICAgLy8gU2V0IHRoZSBVUkxcbiAgICBpZiAocmV3cml0dGVuVXJsKSB7XG4gICAgICB0aGlzLiQkcGFyc2UocmV3cml0dGVuVXJsKTtcbiAgICB9XG4gICAgcmV0dXJuICEhcmV3cml0dGVuVXJsO1xuICB9XG5cbiAgcHJpdmF0ZSBzZXRCcm93c2VyVXJsV2l0aEZhbGxiYWNrKHVybDogc3RyaW5nLCByZXBsYWNlOiBib29sZWFuLCBzdGF0ZTogdW5rbm93bikge1xuICAgIGNvbnN0IG9sZFVybCA9IHRoaXMudXJsKCk7XG4gICAgY29uc3Qgb2xkU3RhdGUgPSB0aGlzLiQkc3RhdGU7XG4gICAgdHJ5IHtcbiAgICAgIHRoaXMuYnJvd3NlclVybCh1cmwsIHJlcGxhY2UsIHN0YXRlKTtcblxuICAgICAgLy8gTWFrZSBzdXJlICRsb2NhdGlvbi5zdGF0ZSgpIHJldHVybnMgcmVmZXJlbnRpYWxseSBpZGVudGljYWwgKG5vdCBqdXN0IGRlZXBseSBlcXVhbClcbiAgICAgIC8vIHN0YXRlIG9iamVjdDsgdGhpcyBtYWtlcyBwb3NzaWJsZSBxdWljayBjaGVja2luZyBpZiB0aGUgc3RhdGUgY2hhbmdlZCBpbiB0aGUgZGlnZXN0XG4gICAgICAvLyBsb29wLiBDaGVja2luZyBkZWVwIGVxdWFsaXR5IHdvdWxkIGJlIHRvbyBleHBlbnNpdmUuXG4gICAgICB0aGlzLiQkc3RhdGUgPSB0aGlzLmJyb3dzZXJTdGF0ZSgpO1xuICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgIC8vIFJlc3RvcmUgb2xkIHZhbHVlcyBpZiBwdXNoU3RhdGUgZmFpbHNcbiAgICAgIHRoaXMudXJsKG9sZFVybCk7XG4gICAgICB0aGlzLiQkc3RhdGUgPSBvbGRTdGF0ZTtcblxuICAgICAgdGhyb3cgZTtcbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGNvbXBvc2VVcmxzKCkge1xuICAgIHRoaXMuJCR1cmwgPSB0aGlzLnVybENvZGVjLm5vcm1hbGl6ZSh0aGlzLiQkcGF0aCwgdGhpcy4kJHNlYXJjaCwgdGhpcy4kJGhhc2gpO1xuICAgIHRoaXMuJCRhYnNVcmwgPSB0aGlzLmdldFNlcnZlckJhc2UoKSArIHRoaXMuJCR1cmwuc2xpY2UoMSk7ICAvLyByZW1vdmUgJy8nIGZyb20gZnJvbnQgb2YgVVJMXG4gICAgdGhpcy51cGRhdGVCcm93c2VyID0gdHJ1ZTtcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZXMgdGhlIGZ1bGwgVVJMIHJlcHJlc2VudGF0aW9uIHdpdGggYWxsIHNlZ21lbnRzIGVuY29kZWQgYWNjb3JkaW5nIHRvXG4gICAqIHJ1bGVzIHNwZWNpZmllZCBpblxuICAgKiBbUkZDIDM5ODZdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMzOTg2KS5cbiAgICpcbiAgICpcbiAgICogYGBganNcbiAgICogLy8gZ2l2ZW4gVVJMIGh0dHA6Ly9leGFtcGxlLmNvbS8jL3NvbWUvcGF0aD9mb289YmFyJmJhej14b3hvXG4gICAqIGxldCBhYnNVcmwgPSAkbG9jYXRpb24uYWJzVXJsKCk7XG4gICAqIC8vID0+IFwiaHR0cDovL2V4YW1wbGUuY29tLyMvc29tZS9wYXRoP2Zvbz1iYXImYmF6PXhveG9cIlxuICAgKiBgYGBcbiAgICovXG4gIGFic1VybCgpOiBzdHJpbmcge1xuICAgIHJldHVybiB0aGlzLiQkYWJzVXJsO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyB0aGUgY3VycmVudCBVUkwsIG9yIHNldHMgYSBuZXcgVVJMLiBXaGVuIHNldHRpbmcgYSBVUkwsXG4gICAqIGNoYW5nZXMgdGhlIHBhdGgsIHNlYXJjaCwgYW5kIGhhc2gsIGFuZCByZXR1cm5zIGEgcmVmZXJlbmNlIHRvIGl0cyBvd24gaW5zdGFuY2UuXG4gICAqXG4gICAqIGBgYGpzXG4gICAqIC8vIGdpdmVuIFVSTCBodHRwOi8vZXhhbXBsZS5jb20vIy9zb21lL3BhdGg/Zm9vPWJhciZiYXo9eG94b1xuICAgKiBsZXQgdXJsID0gJGxvY2F0aW9uLnVybCgpO1xuICAgKiAvLyA9PiBcIi9zb21lL3BhdGg/Zm9vPWJhciZiYXo9eG94b1wiXG4gICAqIGBgYFxuICAgKi9cbiAgdXJsKCk6IHN0cmluZztcbiAgdXJsKHVybDogc3RyaW5nKTogdGhpcztcbiAgdXJsKHVybD86IHN0cmluZyk6IHN0cmluZ3x0aGlzIHtcbiAgICBpZiAodHlwZW9mIHVybCA9PT0gJ3N0cmluZycpIHtcbiAgICAgIGlmICghdXJsLmxlbmd0aCkge1xuICAgICAgICB1cmwgPSAnLyc7XG4gICAgICB9XG5cbiAgICAgIGNvbnN0IG1hdGNoID0gUEFUSF9NQVRDSC5leGVjKHVybCk7XG4gICAgICBpZiAoIW1hdGNoKSByZXR1cm4gdGhpcztcbiAgICAgIGlmIChtYXRjaFsxXSB8fCB1cmwgPT09ICcnKSB0aGlzLnBhdGgodGhpcy51cmxDb2RlYy5kZWNvZGVQYXRoKG1hdGNoWzFdKSk7XG4gICAgICBpZiAobWF0Y2hbMl0gfHwgbWF0Y2hbMV0gfHwgdXJsID09PSAnJykgdGhpcy5zZWFyY2gobWF0Y2hbM10gfHwgJycpO1xuICAgICAgdGhpcy5oYXNoKG1hdGNoWzVdIHx8ICcnKTtcblxuICAgICAgLy8gQ2hhaW5hYmxlIG1ldGhvZFxuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcmV0dXJuIHRoaXMuJCR1cmw7XG4gIH1cblxuICAvKipcbiAgICogUmV0cmlldmVzIHRoZSBwcm90b2NvbCBvZiB0aGUgY3VycmVudCBVUkwuXG4gICAqXG4gICAqIGBgYGpzXG4gICAqIC8vIGdpdmVuIFVSTCBodHRwOi8vZXhhbXBsZS5jb20vIy9zb21lL3BhdGg/Zm9vPWJhciZiYXo9eG94b1xuICAgKiBsZXQgcHJvdG9jb2wgPSAkbG9jYXRpb24ucHJvdG9jb2woKTtcbiAgICogLy8gPT4gXCJodHRwXCJcbiAgICogYGBgXG4gICAqL1xuICBwcm90b2NvbCgpOiBzdHJpbmcge1xuICAgIHJldHVybiB0aGlzLiQkcHJvdG9jb2w7XG4gIH1cblxuICAvKipcbiAgICogUmV0cmlldmVzIHRoZSBwcm90b2NvbCBvZiB0aGUgY3VycmVudCBVUkwuXG4gICAqXG4gICAqIEluIGNvbnRyYXN0IHRvIHRoZSBub24tQW5ndWxhckpTIHZlcnNpb24gYGxvY2F0aW9uLmhvc3RgIHdoaWNoIHJldHVybnMgYGhvc3RuYW1lOnBvcnRgLCB0aGlzXG4gICAqIHJldHVybnMgdGhlIGBob3N0bmFtZWAgcG9ydGlvbiBvbmx5LlxuICAgKlxuICAgKlxuICAgKiBgYGBqc1xuICAgKiAvLyBnaXZlbiBVUkwgaHR0cDovL2V4YW1wbGUuY29tLyMvc29tZS9wYXRoP2Zvbz1iYXImYmF6PXhveG9cbiAgICogbGV0IGhvc3QgPSAkbG9jYXRpb24uaG9zdCgpO1xuICAgKiAvLyA9PiBcImV4YW1wbGUuY29tXCJcbiAgICpcbiAgICogLy8gZ2l2ZW4gVVJMIGh0dHA6Ly91c2VyOnBhc3N3b3JkQGV4YW1wbGUuY29tOjgwODAvIy9zb21lL3BhdGg/Zm9vPWJhciZiYXo9eG94b1xuICAgKiBob3N0ID0gJGxvY2F0aW9uLmhvc3QoKTtcbiAgICogLy8gPT4gXCJleGFtcGxlLmNvbVwiXG4gICAqIGhvc3QgPSBsb2NhdGlvbi5ob3N0O1xuICAgKiAvLyA9PiBcImV4YW1wbGUuY29tOjgwODBcIlxuICAgKiBgYGBcbiAgICovXG4gIGhvc3QoKTogc3RyaW5nIHtcbiAgICByZXR1cm4gdGhpcy4kJGhvc3Q7XG4gIH1cblxuICAvKipcbiAgICogUmV0cmlldmVzIHRoZSBwb3J0IG9mIHRoZSBjdXJyZW50IFVSTC5cbiAgICpcbiAgICogYGBganNcbiAgICogLy8gZ2l2ZW4gVVJMIGh0dHA6Ly9leGFtcGxlLmNvbS8jL3NvbWUvcGF0aD9mb289YmFyJmJhej14b3hvXG4gICAqIGxldCBwb3J0ID0gJGxvY2F0aW9uLnBvcnQoKTtcbiAgICogLy8gPT4gODBcbiAgICogYGBgXG4gICAqL1xuICBwb3J0KCk6IG51bWJlcnxudWxsIHtcbiAgICByZXR1cm4gdGhpcy4kJHBvcnQ7XG4gIH1cblxuICAvKipcbiAgICogUmV0cmlldmVzIHRoZSBwYXRoIG9mIHRoZSBjdXJyZW50IFVSTCwgb3IgY2hhbmdlcyB0aGUgcGF0aCBhbmQgcmV0dXJucyBhIHJlZmVyZW5jZSB0byBpdHMgb3duXG4gICAqIGluc3RhbmNlLlxuICAgKlxuICAgKiBQYXRocyBzaG91bGQgYWx3YXlzIGJlZ2luIHdpdGggZm9yd2FyZCBzbGFzaCAoLykuIFRoaXMgbWV0aG9kIGFkZHMgdGhlIGZvcndhcmQgc2xhc2hcbiAgICogaWYgaXQgaXMgbWlzc2luZy5cbiAgICpcbiAgICogYGBganNcbiAgICogLy8gZ2l2ZW4gVVJMIGh0dHA6Ly9leGFtcGxlLmNvbS8jL3NvbWUvcGF0aD9mb289YmFyJmJhej14b3hvXG4gICAqIGxldCBwYXRoID0gJGxvY2F0aW9uLnBhdGgoKTtcbiAgICogLy8gPT4gXCIvc29tZS9wYXRoXCJcbiAgICogYGBgXG4gICAqL1xuICBwYXRoKCk6IHN0cmluZztcbiAgcGF0aChwYXRoOiBzdHJpbmd8bnVtYmVyfG51bGwpOiB0aGlzO1xuICBwYXRoKHBhdGg/OiBzdHJpbmd8bnVtYmVyfG51bGwpOiBzdHJpbmd8dGhpcyB7XG4gICAgaWYgKHR5cGVvZiBwYXRoID09PSAndW5kZWZpbmVkJykge1xuICAgICAgcmV0dXJuIHRoaXMuJCRwYXRoO1xuICAgIH1cblxuICAgIC8vIG51bGwgcGF0aCBjb252ZXJ0cyB0byBlbXB0eSBzdHJpbmcuIFByZXBlbmQgd2l0aCBcIi9cIiBpZiBuZWVkZWQuXG4gICAgcGF0aCA9IHBhdGggIT09IG51bGwgPyBwYXRoLnRvU3RyaW5nKCkgOiAnJztcbiAgICBwYXRoID0gcGF0aC5jaGFyQXQoMCkgPT09ICcvJyA/IHBhdGggOiAnLycgKyBwYXRoO1xuXG4gICAgdGhpcy4kJHBhdGggPSBwYXRoO1xuXG4gICAgdGhpcy5jb21wb3NlVXJscygpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyBhIG1hcCBvZiB0aGUgc2VhcmNoIHBhcmFtZXRlcnMgb2YgdGhlIGN1cnJlbnQgVVJMLCBvciBjaGFuZ2VzIGEgc2VhcmNoXG4gICAqIHBhcnQgYW5kIHJldHVybnMgYSByZWZlcmVuY2UgdG8gaXRzIG93biBpbnN0YW5jZS5cbiAgICpcbiAgICpcbiAgICogYGBganNcbiAgICogLy8gZ2l2ZW4gVVJMIGh0dHA6Ly9leGFtcGxlLmNvbS8jL3NvbWUvcGF0aD9mb289YmFyJmJhej14b3hvXG4gICAqIGxldCBzZWFyY2hPYmplY3QgPSAkbG9jYXRpb24uc2VhcmNoKCk7XG4gICAqIC8vID0+IHtmb286ICdiYXInLCBiYXo6ICd4b3hvJ31cbiAgICpcbiAgICogLy8gc2V0IGZvbyB0byAneWlwZWUnXG4gICAqICRsb2NhdGlvbi5zZWFyY2goJ2ZvbycsICd5aXBlZScpO1xuICAgKiAvLyAkbG9jYXRpb24uc2VhcmNoKCkgPT4ge2ZvbzogJ3lpcGVlJywgYmF6OiAneG94byd9XG4gICAqIGBgYFxuICAgKlxuICAgKiBAcGFyYW0ge3N0cmluZ3xPYmplY3QuPHN0cmluZz58T2JqZWN0LjxBcnJheS48c3RyaW5nPj59IHNlYXJjaCBOZXcgc2VhcmNoIHBhcmFtcyAtIHN0cmluZyBvclxuICAgKiBoYXNoIG9iamVjdC5cbiAgICpcbiAgICogV2hlbiBjYWxsZWQgd2l0aCBhIHNpbmdsZSBhcmd1bWVudCB0aGUgbWV0aG9kIGFjdHMgYXMgYSBzZXR0ZXIsIHNldHRpbmcgdGhlIGBzZWFyY2hgIGNvbXBvbmVudFxuICAgKiBvZiBgJGxvY2F0aW9uYCB0byB0aGUgc3BlY2lmaWVkIHZhbHVlLlxuICAgKlxuICAgKiBJZiB0aGUgYXJndW1lbnQgaXMgYSBoYXNoIG9iamVjdCBjb250YWluaW5nIGFuIGFycmF5IG9mIHZhbHVlcywgdGhlc2UgdmFsdWVzIHdpbGwgYmUgZW5jb2RlZFxuICAgKiBhcyBkdXBsaWNhdGUgc2VhcmNoIHBhcmFtZXRlcnMgaW4gdGhlIFVSTC5cbiAgICpcbiAgICogQHBhcmFtIHsoc3RyaW5nfE51bWJlcnxBcnJheTxzdHJpbmc+fGJvb2xlYW4pPX0gcGFyYW1WYWx1ZSBJZiBgc2VhcmNoYCBpcyBhIHN0cmluZyBvciBudW1iZXIsXG4gICAqICAgICB0aGVuIGBwYXJhbVZhbHVlYFxuICAgKiB3aWxsIG92ZXJyaWRlIG9ubHkgYSBzaW5nbGUgc2VhcmNoIHByb3BlcnR5LlxuICAgKlxuICAgKiBJZiBgcGFyYW1WYWx1ZWAgaXMgYW4gYXJyYXksIGl0IHdpbGwgb3ZlcnJpZGUgdGhlIHByb3BlcnR5IG9mIHRoZSBgc2VhcmNoYCBjb21wb25lbnQgb2ZcbiAgICogYCRsb2NhdGlvbmAgc3BlY2lmaWVkIHZpYSB0aGUgZmlyc3QgYXJndW1lbnQuXG4gICAqXG4gICAqIElmIGBwYXJhbVZhbHVlYCBpcyBgbnVsbGAsIHRoZSBwcm9wZXJ0eSBzcGVjaWZpZWQgdmlhIHRoZSBmaXJzdCBhcmd1bWVudCB3aWxsIGJlIGRlbGV0ZWQuXG4gICAqXG4gICAqIElmIGBwYXJhbVZhbHVlYCBpcyBgdHJ1ZWAsIHRoZSBwcm9wZXJ0eSBzcGVjaWZpZWQgdmlhIHRoZSBmaXJzdCBhcmd1bWVudCB3aWxsIGJlIGFkZGVkIHdpdGggbm9cbiAgICogdmFsdWUgbm9yIHRyYWlsaW5nIGVxdWFsIHNpZ24uXG4gICAqXG4gICAqIEByZXR1cm4ge09iamVjdH0gVGhlIHBhcnNlZCBgc2VhcmNoYCBvYmplY3Qgb2YgdGhlIGN1cnJlbnQgVVJMLCBvciB0aGUgY2hhbmdlZCBgc2VhcmNoYCBvYmplY3QuXG4gICAqL1xuICBzZWFyY2goKToge1trZXk6IHN0cmluZ106IHVua25vd259O1xuICBzZWFyY2goc2VhcmNoOiBzdHJpbmd8bnVtYmVyfHtba2V5OiBzdHJpbmddOiB1bmtub3dufSk6IHRoaXM7XG4gIHNlYXJjaChcbiAgICAgIHNlYXJjaDogc3RyaW5nfG51bWJlcnx7W2tleTogc3RyaW5nXTogdW5rbm93bn0sXG4gICAgICBwYXJhbVZhbHVlOiBudWxsfHVuZGVmaW5lZHxzdHJpbmd8bnVtYmVyfGJvb2xlYW58c3RyaW5nW10pOiB0aGlzO1xuICBzZWFyY2goXG4gICAgICBzZWFyY2g/OiBzdHJpbmd8bnVtYmVyfHtba2V5OiBzdHJpbmddOiB1bmtub3dufSxcbiAgICAgIHBhcmFtVmFsdWU/OiBudWxsfHVuZGVmaW5lZHxzdHJpbmd8bnVtYmVyfGJvb2xlYW58c3RyaW5nW10pOiB7W2tleTogc3RyaW5nXTogdW5rbm93bn18dGhpcyB7XG4gICAgc3dpdGNoIChhcmd1bWVudHMubGVuZ3RoKSB7XG4gICAgICBjYXNlIDA6XG4gICAgICAgIHJldHVybiB0aGlzLiQkc2VhcmNoO1xuICAgICAgY2FzZSAxOlxuICAgICAgICBpZiAodHlwZW9mIHNlYXJjaCA9PT0gJ3N0cmluZycgfHwgdHlwZW9mIHNlYXJjaCA9PT0gJ251bWJlcicpIHtcbiAgICAgICAgICB0aGlzLiQkc2VhcmNoID0gdGhpcy51cmxDb2RlYy5kZWNvZGVTZWFyY2goc2VhcmNoLnRvU3RyaW5nKCkpO1xuICAgICAgICB9IGVsc2UgaWYgKHR5cGVvZiBzZWFyY2ggPT09ICdvYmplY3QnICYmIHNlYXJjaCAhPT0gbnVsbCkge1xuICAgICAgICAgIC8vIENvcHkgdGhlIG9iamVjdCBzbyBpdCdzIG5ldmVyIG11dGF0ZWRcbiAgICAgICAgICBzZWFyY2ggPSB7Li4uc2VhcmNofTtcbiAgICAgICAgICAvLyByZW1vdmUgb2JqZWN0IHVuZGVmaW5lZCBvciBudWxsIHByb3BlcnRpZXNcbiAgICAgICAgICBmb3IgKGNvbnN0IGtleSBpbiBzZWFyY2gpIHtcbiAgICAgICAgICAgIGlmIChzZWFyY2hba2V5XSA9PSBudWxsKSBkZWxldGUgc2VhcmNoW2tleV07XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgdGhpcy4kJHNlYXJjaCA9IHNlYXJjaDtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgICAgICdMb2NhdGlvblByb3ZpZGVyLnNlYXJjaCgpOiBGaXJzdCBhcmd1bWVudCBtdXN0IGJlIGEgc3RyaW5nIG9yIGFuIG9iamVjdC4nKTtcbiAgICAgICAgfVxuICAgICAgICBicmVhaztcbiAgICAgIGRlZmF1bHQ6XG4gICAgICAgIGlmICh0eXBlb2Ygc2VhcmNoID09PSAnc3RyaW5nJykge1xuICAgICAgICAgIGNvbnN0IGN1cnJlbnRTZWFyY2ggPSB0aGlzLnNlYXJjaCgpO1xuICAgICAgICAgIGlmICh0eXBlb2YgcGFyYW1WYWx1ZSA9PT0gJ3VuZGVmaW5lZCcgfHwgcGFyYW1WYWx1ZSA9PT0gbnVsbCkge1xuICAgICAgICAgICAgZGVsZXRlIGN1cnJlbnRTZWFyY2hbc2VhcmNoXTtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLnNlYXJjaChjdXJyZW50U2VhcmNoKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY3VycmVudFNlYXJjaFtzZWFyY2hdID0gcGFyYW1WYWx1ZTtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLnNlYXJjaChjdXJyZW50U2VhcmNoKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XG4gICAgdGhpcy5jb21wb3NlVXJscygpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyB0aGUgY3VycmVudCBoYXNoIGZyYWdtZW50LCBvciBjaGFuZ2VzIHRoZSBoYXNoIGZyYWdtZW50IGFuZCByZXR1cm5zIGEgcmVmZXJlbmNlIHRvXG4gICAqIGl0cyBvd24gaW5zdGFuY2UuXG4gICAqXG4gICAqIGBgYGpzXG4gICAqIC8vIGdpdmVuIFVSTCBodHRwOi8vZXhhbXBsZS5jb20vIy9zb21lL3BhdGg/Zm9vPWJhciZiYXo9eG94byNoYXNoVmFsdWVcbiAgICogbGV0IGhhc2ggPSAkbG9jYXRpb24uaGFzaCgpO1xuICAgKiAvLyA9PiBcImhhc2hWYWx1ZVwiXG4gICAqIGBgYFxuICAgKi9cbiAgaGFzaCgpOiBzdHJpbmc7XG4gIGhhc2goaGFzaDogc3RyaW5nfG51bWJlcnxudWxsKTogdGhpcztcbiAgaGFzaChoYXNoPzogc3RyaW5nfG51bWJlcnxudWxsKTogc3RyaW5nfHRoaXMge1xuICAgIGlmICh0eXBlb2YgaGFzaCA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgIHJldHVybiB0aGlzLiQkaGFzaDtcbiAgICB9XG5cbiAgICB0aGlzLiQkaGFzaCA9IGhhc2ggIT09IG51bGwgPyBoYXNoLnRvU3RyaW5nKCkgOiAnJztcblxuICAgIHRoaXMuY29tcG9zZVVybHMoKTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIC8qKlxuICAgKiBDaGFuZ2VzIHRvIGAkbG9jYXRpb25gIGR1cmluZyB0aGUgY3VycmVudCBgJGRpZ2VzdGAgd2lsbCByZXBsYWNlIHRoZSBjdXJyZW50XG4gICAqIGhpc3RvcnkgcmVjb3JkLCBpbnN0ZWFkIG9mIGFkZGluZyBhIG5ldyBvbmUuXG4gICAqL1xuICByZXBsYWNlKCk6IHRoaXMge1xuICAgIHRoaXMuJCRyZXBsYWNlID0gdHJ1ZTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZXMgdGhlIGhpc3Rvcnkgc3RhdGUgb2JqZWN0IHdoZW4gY2FsbGVkIHdpdGhvdXQgYW55IHBhcmFtZXRlci5cbiAgICpcbiAgICogQ2hhbmdlIHRoZSBoaXN0b3J5IHN0YXRlIG9iamVjdCB3aGVuIGNhbGxlZCB3aXRoIG9uZSBwYXJhbWV0ZXIgYW5kIHJldHVybiBgJGxvY2F0aW9uYC5cbiAgICogVGhlIHN0YXRlIG9iamVjdCBpcyBsYXRlciBwYXNzZWQgdG8gYHB1c2hTdGF0ZWAgb3IgYHJlcGxhY2VTdGF0ZWAuXG4gICAqXG4gICAqIFRoaXMgbWV0aG9kIGlzIHN1cHBvcnRlZCBvbmx5IGluIEhUTUw1IG1vZGUgYW5kIG9ubHkgaW4gYnJvd3NlcnMgc3VwcG9ydGluZ1xuICAgKiB0aGUgSFRNTDUgSGlzdG9yeSBBUEkgbWV0aG9kcyBzdWNoIGFzIGBwdXNoU3RhdGVgIGFuZCBgcmVwbGFjZVN0YXRlYC4gSWYgeW91IG5lZWQgdG8gc3VwcG9ydFxuICAgKiBvbGRlciBicm93c2VycyAobGlrZSBBbmRyb2lkIDwgNC4wKSwgZG9uJ3QgdXNlIHRoaXMgbWV0aG9kLlxuICAgKlxuICAgKi9cbiAgc3RhdGUoKTogdW5rbm93bjtcbiAgc3RhdGUoc3RhdGU6IHVua25vd24pOiB0aGlzO1xuICBzdGF0ZShzdGF0ZT86IHVua25vd24pOiB1bmtub3dufHRoaXMge1xuICAgIGlmICh0eXBlb2Ygc3RhdGUgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICByZXR1cm4gdGhpcy4kJHN0YXRlO1xuICAgIH1cblxuICAgIHRoaXMuJCRzdGF0ZSA9IHN0YXRlO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG59XG5cbi8qKlxuICogVGhlIGZhY3RvcnkgZnVuY3Rpb24gdXNlZCB0byBjcmVhdGUgYW4gaW5zdGFuY2Ugb2YgdGhlIGAkbG9jYXRpb25TaGltYCBpbiBBbmd1bGFyLFxuICogYW5kIHByb3ZpZGVzIGFuIEFQSS1jb21wYXRpYmxlIGAkbG9jYXRpb25Qcm92aWRlcmAgZm9yIEFuZ3VsYXJKUy5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyAkbG9jYXRpb25TaGltUHJvdmlkZXIge1xuICBjb25zdHJ1Y3RvcihcbiAgICAgIHByaXZhdGUgbmdVcGdyYWRlOiBVcGdyYWRlTW9kdWxlLCBwcml2YXRlIGxvY2F0aW9uOiBMb2NhdGlvbixcbiAgICAgIHByaXZhdGUgcGxhdGZvcm1Mb2NhdGlvbjogUGxhdGZvcm1Mb2NhdGlvbiwgcHJpdmF0ZSB1cmxDb2RlYzogVXJsQ29kZWMsXG4gICAgICBwcml2YXRlIGxvY2F0aW9uU3RyYXRlZ3k6IExvY2F0aW9uU3RyYXRlZ3kpIHt9XG5cbiAgLyoqXG4gICAqIEZhY3RvcnkgbWV0aG9kIHRoYXQgcmV0dXJucyBhbiBpbnN0YW5jZSBvZiB0aGUgJGxvY2F0aW9uU2hpbVxuICAgKi9cbiAgJGdldCgpIHtcbiAgICByZXR1cm4gbmV3ICRsb2NhdGlvblNoaW0oXG4gICAgICAgIHRoaXMubmdVcGdyYWRlLiRpbmplY3RvciwgdGhpcy5sb2NhdGlvbiwgdGhpcy5wbGF0Zm9ybUxvY2F0aW9uLCB0aGlzLnVybENvZGVjLFxuICAgICAgICB0aGlzLmxvY2F0aW9uU3RyYXRlZ3kpO1xuICB9XG5cbiAgLyoqXG4gICAqIFN0dWIgbWV0aG9kIHVzZWQgdG8ga2VlcCBBUEkgY29tcGF0aWJsZSB3aXRoIEFuZ3VsYXJKUy4gVGhpcyBzZXR0aW5nIGlzIGNvbmZpZ3VyZWQgdGhyb3VnaFxuICAgKiB0aGUgTG9jYXRpb25VcGdyYWRlTW9kdWxlJ3MgYGNvbmZpZ2AgbWV0aG9kIGluIHlvdXIgQW5ndWxhciBhcHAuXG4gICAqL1xuICBoYXNoUHJlZml4KHByZWZpeD86IHN0cmluZykge1xuICAgIHRocm93IG5ldyBFcnJvcignQ29uZmlndXJlIExvY2F0aW9uVXBncmFkZSB0aHJvdWdoIExvY2F0aW9uVXBncmFkZU1vZHVsZS5jb25maWcgbWV0aG9kLicpO1xuICB9XG5cbiAgLyoqXG4gICAqIFN0dWIgbWV0aG9kIHVzZWQgdG8ga2VlcCBBUEkgY29tcGF0aWJsZSB3aXRoIEFuZ3VsYXJKUy4gVGhpcyBzZXR0aW5nIGlzIGNvbmZpZ3VyZWQgdGhyb3VnaFxuICAgKiB0aGUgTG9jYXRpb25VcGdyYWRlTW9kdWxlJ3MgYGNvbmZpZ2AgbWV0aG9kIGluIHlvdXIgQW5ndWxhciBhcHAuXG4gICAqL1xuICBodG1sNU1vZGUobW9kZT86IGFueSkge1xuICAgIHRocm93IG5ldyBFcnJvcignQ29uZmlndXJlIExvY2F0aW9uVXBncmFkZSB0aHJvdWdoIExvY2F0aW9uVXBncmFkZU1vZHVsZS5jb25maWcgbWV0aG9kLicpO1xuICB9XG59XG4iXX0=