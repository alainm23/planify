/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ɵɵdefineInjectable, ɵɵinject } from '@angular/core';
import { DOCUMENT } from './dom_tokens';
/**
 * Defines a scroll position manager. Implemented by `BrowserViewportScroller`.
 *
 * @publicApi
 */
class ViewportScroller {
    // De-sugared tree-shakable injection
    // See #23917
    /** @nocollapse */
    static { this.ɵprov = ɵɵdefineInjectable({
        token: ViewportScroller,
        providedIn: 'root',
        factory: () => new BrowserViewportScroller(ɵɵinject(DOCUMENT), window)
    }); }
}
export { ViewportScroller };
/**
 * Manages the scroll position for a browser window.
 */
export class BrowserViewportScroller {
    constructor(document, window) {
        this.document = document;
        this.window = window;
        this.offset = () => [0, 0];
    }
    /**
     * Configures the top offset used when scrolling to an anchor.
     * @param offset A position in screen coordinates (a tuple with x and y values)
     * or a function that returns the top offset position.
     *
     */
    setOffset(offset) {
        if (Array.isArray(offset)) {
            this.offset = () => offset;
        }
        else {
            this.offset = offset;
        }
    }
    /**
     * Retrieves the current scroll position.
     * @returns The position in screen coordinates.
     */
    getScrollPosition() {
        if (this.supportsScrolling()) {
            return [this.window.pageXOffset, this.window.pageYOffset];
        }
        else {
            return [0, 0];
        }
    }
    /**
     * Sets the scroll position.
     * @param position The new position in screen coordinates.
     */
    scrollToPosition(position) {
        if (this.supportsScrolling()) {
            this.window.scrollTo(position[0], position[1]);
        }
    }
    /**
     * Scrolls to an element and attempts to focus the element.
     *
     * Note that the function name here is misleading in that the target string may be an ID for a
     * non-anchor element.
     *
     * @param target The ID of an element or name of the anchor.
     *
     * @see https://html.spec.whatwg.org/#the-indicated-part-of-the-document
     * @see https://html.spec.whatwg.org/#scroll-to-fragid
     */
    scrollToAnchor(target) {
        if (!this.supportsScrolling()) {
            return;
        }
        const elSelected = findAnchorFromDocument(this.document, target);
        if (elSelected) {
            this.scrollToElement(elSelected);
            // After scrolling to the element, the spec dictates that we follow the focus steps for the
            // target. Rather than following the robust steps, simply attempt focus.
            //
            // @see https://html.spec.whatwg.org/#get-the-focusable-area
            // @see https://developer.mozilla.org/en-US/docs/Web/API/HTMLOrForeignElement/focus
            // @see https://html.spec.whatwg.org/#focusable-area
            elSelected.focus();
        }
    }
    /**
     * Disables automatic scroll restoration provided by the browser.
     */
    setHistoryScrollRestoration(scrollRestoration) {
        if (this.supportScrollRestoration()) {
            const history = this.window.history;
            if (history && history.scrollRestoration) {
                history.scrollRestoration = scrollRestoration;
            }
        }
    }
    /**
     * Scrolls to an element using the native offset and the specified offset set on this scroller.
     *
     * The offset can be used when we know that there is a floating header and scrolling naively to an
     * element (ex: `scrollIntoView`) leaves the element hidden behind the floating header.
     */
    scrollToElement(el) {
        const rect = el.getBoundingClientRect();
        const left = rect.left + this.window.pageXOffset;
        const top = rect.top + this.window.pageYOffset;
        const offset = this.offset();
        this.window.scrollTo(left - offset[0], top - offset[1]);
    }
    /**
     * We only support scroll restoration when we can get a hold of window.
     * This means that we do not support this behavior when running in a web worker.
     *
     * Lifting this restriction right now would require more changes in the dom adapter.
     * Since webworkers aren't widely used, we will lift it once RouterScroller is
     * battle-tested.
     */
    supportScrollRestoration() {
        try {
            if (!this.supportsScrolling()) {
                return false;
            }
            // The `scrollRestoration` property could be on the `history` instance or its prototype.
            const scrollRestorationDescriptor = getScrollRestorationProperty(this.window.history) ||
                getScrollRestorationProperty(Object.getPrototypeOf(this.window.history));
            // We can write to the `scrollRestoration` property if it is a writable data field or it has a
            // setter function.
            return !!scrollRestorationDescriptor &&
                !!(scrollRestorationDescriptor.writable || scrollRestorationDescriptor.set);
        }
        catch {
            return false;
        }
    }
    supportsScrolling() {
        try {
            return !!this.window && !!this.window.scrollTo && 'pageXOffset' in this.window;
        }
        catch {
            return false;
        }
    }
}
function getScrollRestorationProperty(obj) {
    return Object.getOwnPropertyDescriptor(obj, 'scrollRestoration');
}
function findAnchorFromDocument(document, target) {
    const documentResult = document.getElementById(target) || document.getElementsByName(target)[0];
    if (documentResult) {
        return documentResult;
    }
    // `getElementById` and `getElementsByName` won't pierce through the shadow DOM so we
    // have to traverse the DOM manually and do the lookup through the shadow roots.
    if (typeof document.createTreeWalker === 'function' && document.body &&
        typeof document.body.attachShadow === 'function') {
        const treeWalker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT);
        let currentNode = treeWalker.currentNode;
        while (currentNode) {
            const shadowRoot = currentNode.shadowRoot;
            if (shadowRoot) {
                // Note that `ShadowRoot` doesn't support `getElementsByName`
                // so we have to fall back to `querySelector`.
                const result = shadowRoot.getElementById(target) || shadowRoot.querySelector(`[name="${target}"]`);
                if (result) {
                    return result;
                }
            }
            currentNode = treeWalker.nextNode();
        }
    }
    return null;
}
/**
 * Provides an empty implementation of the viewport scroller.
 */
export class NullViewportScroller {
    /**
     * Empty implementation
     */
    setOffset(offset) { }
    /**
     * Empty implementation
     */
    getScrollPosition() {
        return [0, 0];
    }
    /**
     * Empty implementation
     */
    scrollToPosition(position) { }
    /**
     * Empty implementation
     */
    scrollToAnchor(anchor) { }
    /**
     * Empty implementation
     */
    setHistoryScrollRestoration(scrollRestoration) { }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidmlld3BvcnRfc2Nyb2xsZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb21tb24vc3JjL3ZpZXdwb3J0X3Njcm9sbGVyLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxrQkFBa0IsRUFBRSxRQUFRLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFFM0QsT0FBTyxFQUFDLFFBQVEsRUFBQyxNQUFNLGNBQWMsQ0FBQztBQUl0Qzs7OztHQUlHO0FBQ0gsTUFBc0IsZ0JBQWdCO0lBQ3BDLHFDQUFxQztJQUNyQyxhQUFhO0lBQ2Isa0JBQWtCO2FBQ1gsVUFBSyxHQUE2QixrQkFBa0IsQ0FBQztRQUMxRCxLQUFLLEVBQUUsZ0JBQWdCO1FBQ3ZCLFVBQVUsRUFBRSxNQUFNO1FBQ2xCLE9BQU8sRUFBRSxHQUFHLEVBQUUsQ0FBQyxJQUFJLHVCQUF1QixDQUFDLFFBQVEsQ0FBQyxRQUFRLENBQUMsRUFBRSxNQUFNLENBQUM7S0FDdkUsQ0FBQyxDQUFDOztTQVJpQixnQkFBZ0I7QUE0Q3RDOztHQUVHO0FBQ0gsTUFBTSxPQUFPLHVCQUF1QjtJQUdsQyxZQUFvQixRQUFrQixFQUFVLE1BQWM7UUFBMUMsYUFBUSxHQUFSLFFBQVEsQ0FBVTtRQUFVLFdBQU0sR0FBTixNQUFNLENBQVE7UUFGdEQsV0FBTSxHQUEyQixHQUFHLEVBQUUsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQztJQUVXLENBQUM7SUFFbEU7Ozs7O09BS0c7SUFDSCxTQUFTLENBQUMsTUFBaUQ7UUFDekQsSUFBSSxLQUFLLENBQUMsT0FBTyxDQUFDLE1BQU0sQ0FBQyxFQUFFO1lBQ3pCLElBQUksQ0FBQyxNQUFNLEdBQUcsR0FBRyxFQUFFLENBQUMsTUFBTSxDQUFDO1NBQzVCO2FBQU07WUFDTCxJQUFJLENBQUMsTUFBTSxHQUFHLE1BQU0sQ0FBQztTQUN0QjtJQUNILENBQUM7SUFF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LENBQUMsSUFBSSxVQUFVLENBQUMsYUFBYSxDQUFDLFVBQVUsTUFBTSxJQUFJLENBQUMsQ0FBQztnQkFDeEYsSUFBSSxNQUFNLEVBQUU7b0JBQ1YsT0FBTyxNQUFNLENBQUM7aUJBQ2Y7YUFDRjtZQUVELFdBQVcsR0FBRyxVQUFVLENBQUMsUUFBUSxFQUF3QixDQUFDO1NBQzNEO0tBQ0Y7SUFFRCxPQUFPLElBQUksQ0FBQztBQUNkLENBQUM7QUFFRDs7R0FFRztBQUNILE1BQU0sT0FBTyxvQkFBb0I7SUFDL0I7O09BRUc7SUFDSCxTQUFTLENBQUMsTUFBaUQsSUFBUyxDQUFDO0lBRXJFOztPQUVHO0lBQ0gsaUJBQWlCO1FBQ2YsT0FBTyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQztJQUNoQixDQUFDO0lBRUQ7O09BRUc7SUFDSCxnQkFBZ0IsQ0FBQyxRQUEwQixJQUFTLENBQUM7SUFFckQ7O09BRUc7SUFDSCxjQUFjLENBQUMsTUFBYyxJQUFTLENBQUM7SUFFdkM7O09BRUc7SUFDSCwyQkFBMkIsQ0FBQyxpQkFBa0MsSUFBUyxDQUFDO0NBQ3pFIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7ybXJtWRlZmluZUluamVjdGFibGUsIMm1ybVpbmplY3R9IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuXG5pbXBvcnQge0RPQ1VNRU5UfSBmcm9tICcuL2RvbV90b2tlbnMnO1xuXG5cblxuLyoqXG4gKiBEZWZpbmVzIGEgc2Nyb2xsIHBvc2l0aW9uIG1hbmFnZXIuIEltcGxlbWVudGVkIGJ5IGBCcm93c2VyVmlld3BvcnRTY3JvbGxlcmAuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgYWJzdHJhY3QgY2xhc3MgVmlld3BvcnRTY3JvbGxlciB7XG4gIC8vIERlLXN1Z2FyZWQgdHJlZS1zaGFrYWJsZSBpbmplY3Rpb25cbiAgLy8gU2VlICMyMzkxN1xuICAvKiogQG5vY29sbGFwc2UgKi9cbiAgc3RhdGljIMm1cHJvdiA9IC8qKiBAcHVyZU9yQnJlYWtNeUNvZGUgKi8gybXJtWRlZmluZUluamVjdGFibGUoe1xuICAgIHRva2VuOiBWaWV3cG9ydFNjcm9sbGVyLFxuICAgIHByb3ZpZGVkSW46ICdyb290JyxcbiAgICBmYWN0b3J5OiAoKSA9PiBuZXcgQnJvd3NlclZpZXdwb3J0U2Nyb2xsZXIoybXJtWluamVjdChET0NVTUVOVCksIHdpbmRvdylcbiAgfSk7XG5cbiAgLyoqXG4gICAqIENvbmZpZ3VyZXMgdGhlIHRvcCBvZmZzZXQgdXNlZCB3aGVuIHNjcm9sbGluZyB0byBhbiBhbmNob3IuXG4gICAqIEBwYXJhbSBvZmZzZXQgQSBwb3NpdGlvbiBpbiBzY3JlZW4gY29vcmRpbmF0ZXMgKGEgdHVwbGUgd2l0aCB4IGFuZCB5IHZhbHVlcylcbiAgICogb3IgYSBmdW5jdGlvbiB0aGF0IHJldHVybnMgdGhlIHRvcCBvZmZzZXQgcG9zaXRpb24uXG4gICAqXG4gICAqL1xuICBhYnN0cmFjdCBzZXRPZmZzZXQob2Zmc2V0OiBbbnVtYmVyLCBudW1iZXJdfCgoKSA9PiBbbnVtYmVyLCBudW1iZXJdKSk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFJldHJpZXZlcyB0aGUgY3VycmVudCBzY3JvbGwgcG9zaXRpb24uXG4gICAqIEByZXR1cm5zIEEgcG9zaXRpb24gaW4gc2NyZWVuIGNvb3JkaW5hdGVzIChhIHR1cGxlIHdpdGggeCBhbmQgeSB2YWx1ZXMpLlxuICAgKi9cbiAgYWJzdHJhY3QgZ2V0U2Nyb2xsUG9zaXRpb24oKTogW251bWJlciwgbnVtYmVyXTtcblxuICAvKipcbiAgICogU2Nyb2xscyB0byBhIHNwZWNpZmllZCBwb3NpdGlvbi5cbiAgICogQHBhcmFtIHBvc2l0aW9uIEEgcG9zaXRpb24gaW4gc2NyZWVuIGNvb3JkaW5hdGVzIChhIHR1cGxlIHdpdGggeCBhbmQgeSB2YWx1ZXMpLlxuICAgKi9cbiAgYWJzdHJhY3Qgc2Nyb2xsVG9Qb3NpdGlvbihwb3NpdGlvbjogW251bWJlciwgbnVtYmVyXSk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFNjcm9sbHMgdG8gYW4gYW5jaG9yIGVsZW1lbnQuXG4gICAqIEBwYXJhbSBhbmNob3IgVGhlIElEIG9mIHRoZSBhbmNob3IgZWxlbWVudC5cbiAgICovXG4gIGFic3RyYWN0IHNjcm9sbFRvQW5jaG9yKGFuY2hvcjogc3RyaW5nKTogdm9pZDtcblxuICAvKipcbiAgICogRGlzYWJsZXMgYXV0b21hdGljIHNjcm9sbCByZXN0b3JhdGlvbiBwcm92aWRlZCBieSB0aGUgYnJvd3Nlci5cbiAgICogU2VlIGFsc28gW3dpbmRvdy5oaXN0b3J5LnNjcm9sbFJlc3RvcmF0aW9uXG4gICAqIGluZm9dKGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3dlYi91cGRhdGVzLzIwMTUvMDkvaGlzdG9yeS1hcGktc2Nyb2xsLXJlc3RvcmF0aW9uKS5cbiAgICovXG4gIGFic3RyYWN0IHNldEhpc3RvcnlTY3JvbGxSZXN0b3JhdGlvbihzY3JvbGxSZXN0b3JhdGlvbjogJ2F1dG8nfCdtYW51YWwnKTogdm9pZDtcbn1cblxuLyoqXG4gKiBNYW5hZ2VzIHRoZSBzY3JvbGwgcG9zaXRpb24gZm9yIGEgYnJvd3NlciB3aW5kb3cuXG4gKi9cbmV4cG9ydCBjbGFzcyBCcm93c2VyVmlld3BvcnRTY3JvbGxlciBpbXBsZW1lbnRzIFZpZXdwb3J0U2Nyb2xsZXIge1xuICBwcml2YXRlIG9mZnNldDogKCkgPT4gW251bWJlciwgbnVtYmVyXSA9ICgpID0+IFswLCAwXTtcblxuICBjb25zdHJ1Y3Rvcihwcml2YXRlIGRvY3VtZW50OiBEb2N1bWVudCwgcHJpdmF0ZSB3aW5kb3c6IFdpbmRvdykge31cblxuICAvKipcbiAgICogQ29uZmlndXJlcyB0aGUgdG9wIG9mZnNldCB1c2VkIHdoZW4gc2Nyb2xsaW5nIHRvIGFuIGFuY2hvci5cbiAgICogQHBhcmFtIG9mZnNldCBBIHBvc2l0aW9uIGluIHNjcmVlbiBjb29yZGluYXRlcyAoYSB0dXBsZSB3aXRoIHggYW5kIHkgdmFsdWVzKVxuICAgKiBvciBhIGZ1bmN0aW9uIHRoYXQgcmV0dXJucyB0aGUgdG9wIG9mZnNldCBwb3NpdGlvbi5cbiAgICpcbiAgICovXG4gIHNldE9mZnNldChvZmZzZXQ6IFtudW1iZXIsIG51bWJlcl18KCgpID0+IFtudW1iZXIsIG51bWJlcl0pKTogdm9pZCB7XG4gICAgaWYgKEFycmF5LmlzQXJyYXkob2Zmc2V0KSkge1xuICAgICAgdGhpcy5vZmZzZXQgPSAoKSA9PiBvZmZzZXQ7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMub2Zmc2V0ID0gb2Zmc2V0O1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBSZXRyaWV2ZXMgdGhlIGN1cnJlbnQgc2Nyb2xsIHBvc2l0aW9uLlxuICAgKiBAcmV0dXJucyBUaGUgcG9zaXRpb24gaW4gc2NyZWVuIGNvb3JkaW5hdGVzLlxuICAgKi9cbiAgZ2V0U2Nyb2xsUG9zaXRpb24oKTogW251bWJlciwgbnVtYmVyXSB7XG4gICAgaWYgKHRoaXMuc3VwcG9ydHNTY3JvbGxpbmcoKSkge1xuICAgICAgcmV0dXJuIFt0aGlzLndpbmRvdy5wYWdlWE9mZnNldCwgdGhpcy53aW5kb3cucGFnZVlPZmZzZXRdO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gWzAsIDBdO1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBTZXRzIHRoZSBzY3JvbGwgcG9zaXRpb24uXG4gICAqIEBwYXJhbSBwb3NpdGlvbiBUaGUgbmV3IHBvc2l0aW9uIGluIHNjcmVlbiBjb29yZGluYXRlcy5cbiAgICovXG4gIHNjcm9sbFRvUG9zaXRpb24ocG9zaXRpb246IFtudW1iZXIsIG51bWJlcl0pOiB2b2lkIHtcbiAgICBpZiAodGhpcy5zdXBwb3J0c1Njcm9sbGluZygpKSB7XG4gICAgICB0aGlzLndpbmRvdy5zY3JvbGxUbyhwb3NpdGlvblswXSwgcG9zaXRpb25bMV0pO1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBTY3JvbGxzIHRvIGFuIGVsZW1lbnQgYW5kIGF0dGVtcHRzIHRvIGZvY3VzIHRoZSBlbGVtZW50LlxuICAgKlxuICAgKiBOb3RlIHRoYXQgdGhlIGZ1bmN0aW9uIG5hbWUgaGVyZSBpcyBtaXNsZWFkaW5nIGluIHRoYXQgdGhlIHRhcmdldCBzdHJpbmcgbWF5IGJlIGFuIElEIGZvciBhXG4gICAqIG5vbi1hbmNob3IgZWxlbWVudC5cbiAgICpcbiAgICogQHBhcmFtIHRhcmdldCBUaGUgSUQgb2YgYW4gZWxlbWVudCBvciBuYW1lIG9mIHRoZSBhbmNob3IuXG4gICAqXG4gICAqIEBzZWUgaHR0cHM6Ly9odG1sLnNwZWMud2hhdHdnLm9yZy8jdGhlLWluZGljYXRlZC1wYXJ0LW9mLXRoZS1kb2N1bWVudFxuICAgKiBAc2VlIGh0dHBzOi8vaHRtbC5zcGVjLndoYXR3Zy5vcmcvI3Njcm9sbC10by1mcmFnaWRcbiAgICovXG4gIHNjcm9sbFRvQW5jaG9yKHRhcmdldDogc3RyaW5nKTogdm9pZCB7XG4gICAgaWYgKCF0aGlzLnN1cHBvcnRzU2Nyb2xsaW5nKCkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICBjb25zdCBlbFNlbGVjdGVkID0gZmluZEFuY2hvckZyb21Eb2N1bWVudCh0aGlzLmRvY3VtZW50LCB0YXJnZXQpO1xuXG4gICAgaWYgKGVsU2VsZWN0ZWQpIHtcbiAgICAgIHRoaXMuc2Nyb2xsVG9FbGVtZW50KGVsU2VsZWN0ZWQpO1xuICAgICAgLy8gQWZ0ZXIgc2Nyb2xsaW5nIHRvIHRoZSBlbGVtZW50LCB0aGUgc3BlYyBkaWN0YXRlcyB0aGF0IHdlIGZvbGxvdyB0aGUgZm9jdXMgc3RlcHMgZm9yIHRoZVxuICAgICAgLy8gdGFyZ2V0LiBSYXRoZXIgdGhhbiBmb2xsb3dpbmcgdGhlIHJvYnVzdCBzdGVwcywgc2ltcGx5IGF0dGVtcHQgZm9jdXMuXG4gICAgICAvL1xuICAgICAgLy8gQHNlZSBodHRwczovL2h0bWwuc3BlYy53aGF0d2cub3JnLyNnZXQtdGhlLWZvY3VzYWJsZS1hcmVhXG4gICAgICAvLyBAc2VlIGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0FQSS9IVE1MT3JGb3JlaWduRWxlbWVudC9mb2N1c1xuICAgICAgLy8gQHNlZSBodHRwczovL2h0bWwuc3BlYy53aGF0d2cub3JnLyNmb2N1c2FibGUtYXJlYVxuICAgICAgZWxTZWxlY3RlZC5mb2N1cygpO1xuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBEaXNhYmxlcyBhdXRvbWF0aWMgc2Nyb2xsIHJlc3RvcmF0aW9uIHByb3ZpZGVkIGJ5IHRoZSBicm93c2VyLlxuICAgKi9cbiAgc2V0SGlzdG9yeVNjcm9sbFJlc3RvcmF0aW9uKHNjcm9sbFJlc3RvcmF0aW9uOiAnYXV0byd8J21hbnVhbCcpOiB2b2lkIHtcbiAgICBpZiAodGhpcy5zdXBwb3J0U2Nyb2xsUmVzdG9yYXRpb24oKSkge1xuICAgICAgY29uc3QgaGlzdG9yeSA9IHRoaXMud2luZG93Lmhpc3Rvcnk7XG4gICAgICBpZiAoaGlzdG9yeSAmJiBoaXN0b3J5LnNjcm9sbFJlc3RvcmF0aW9uKSB7XG4gICAgICAgIGhpc3Rvcnkuc2Nyb2xsUmVzdG9yYXRpb24gPSBzY3JvbGxSZXN0b3JhdGlvbjtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogU2Nyb2xscyB0byBhbiBlbGVtZW50IHVzaW5nIHRoZSBuYXRpdmUgb2Zmc2V0IGFuZCB0aGUgc3BlY2lmaWVkIG9mZnNldCBzZXQgb24gdGhpcyBzY3JvbGxlci5cbiAgICpcbiAgICogVGhlIG9mZnNldCBjYW4gYmUgdXNlZCB3aGVuIHdlIGtub3cgdGhhdCB0aGVyZSBpcyBhIGZsb2F0aW5nIGhlYWRlciBhbmQgc2Nyb2xsaW5nIG5haXZlbHkgdG8gYW5cbiAgICogZWxlbWVudCAoZXg6IGBzY3JvbGxJbnRvVmlld2ApIGxlYXZlcyB0aGUgZWxlbWVudCBoaWRkZW4gYmVoaW5kIHRoZSBmbG9hdGluZyBoZWFkZXIuXG4gICAqL1xuICBwcml2YXRlIHNjcm9sbFRvRWxlbWVudChlbDogSFRNTEVsZW1lbnQpOiB2b2lkIHtcbiAgICBjb25zdCByZWN0ID0gZWwuZ2V0Qm91bmRpbmdDbGllbnRSZWN0KCk7XG4gICAgY29uc3QgbGVmdCA9IHJlY3QubGVmdCArIHRoaXMud2luZG93LnBhZ2VYT2Zmc2V0O1xuICAgIGNvbnN0IHRvcCA9IHJlY3QudG9wICsgdGhpcy53aW5kb3cucGFnZVlPZmZzZXQ7XG4gICAgY29uc3Qgb2Zmc2V0ID0gdGhpcy5vZmZzZXQoKTtcbiAgICB0aGlzLndpbmRvdy5zY3JvbGxUbyhsZWZ0IC0gb2Zmc2V0WzBdLCB0b3AgLSBvZmZzZXRbMV0pO1xuICB9XG5cbiAgLyoqXG4gICAqIFdlIG9ubHkgc3VwcG9ydCBzY3JvbGwgcmVzdG9yYXRpb24gd2hlbiB3ZSBjYW4gZ2V0IGEgaG9sZCBvZiB3aW5kb3cuXG4gICAqIFRoaXMgbWVhbnMgdGhhdCB3ZSBkbyBub3Qgc3VwcG9ydCB0aGlzIGJlaGF2aW9yIHdoZW4gcnVubmluZyBpbiBhIHdlYiB3b3JrZXIuXG4gICAqXG4gICAqIExpZnRpbmcgdGhpcyByZXN0cmljdGlvbiByaWdodCBub3cgd291bGQgcmVxdWlyZSBtb3JlIGNoYW5nZXMgaW4gdGhlIGRvbSBhZGFwdGVyLlxuICAgKiBTaW5jZSB3ZWJ3b3JrZXJzIGFyZW4ndCB3aWRlbHkgdXNlZCwgd2Ugd2lsbCBsaWZ0IGl0IG9uY2UgUm91dGVyU2Nyb2xsZXIgaXNcbiAgICogYmF0dGxlLXRlc3RlZC5cbiAgICovXG4gIHByaXZhdGUgc3VwcG9ydFNjcm9sbFJlc3RvcmF0aW9uKCk6IGJvb2xlYW4ge1xuICAgIHRyeSB7XG4gICAgICBpZiAoIXRoaXMuc3VwcG9ydHNTY3JvbGxpbmcoKSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgICAvLyBUaGUgYHNjcm9sbFJlc3RvcmF0aW9uYCBwcm9wZXJ0eSBjb3VsZCBiZSBvbiB0aGUgYGhpc3RvcnlgIGluc3RhbmNlIG9yIGl0cyBwcm90b3R5cGUuXG4gICAgICBjb25zdCBzY3JvbGxSZXN0b3JhdGlvbkRlc2NyaXB0b3IgPSBnZXRTY3JvbGxSZXN0b3JhdGlvblByb3BlcnR5KHRoaXMud2luZG93Lmhpc3RvcnkpIHx8XG4gICAgICAgICAgZ2V0U2Nyb2xsUmVzdG9yYXRpb25Qcm9wZXJ0eShPYmplY3QuZ2V0UHJvdG90eXBlT2YodGhpcy53aW5kb3cuaGlzdG9yeSkpO1xuICAgICAgLy8gV2UgY2FuIHdyaXRlIHRvIHRoZSBgc2Nyb2xsUmVzdG9yYXRpb25gIHByb3BlcnR5IGlmIGl0IGlzIGEgd3JpdGFibGUgZGF0YSBmaWVsZCBvciBpdCBoYXMgYVxuICAgICAgLy8gc2V0dGVyIGZ1bmN0aW9uLlxuICAgICAgcmV0dXJuICEhc2Nyb2xsUmVzdG9yYXRpb25EZXNjcmlwdG9yICYmXG4gICAgICAgICAgISEoc2Nyb2xsUmVzdG9yYXRpb25EZXNjcmlwdG9yLndyaXRhYmxlIHx8IHNjcm9sbFJlc3RvcmF0aW9uRGVzY3JpcHRvci5zZXQpO1xuICAgIH0gY2F0Y2gge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgc3VwcG9ydHNTY3JvbGxpbmcoKTogYm9vbGVhbiB7XG4gICAgdHJ5IHtcbiAgICAgIHJldHVybiAhIXRoaXMud2luZG93ICYmICEhdGhpcy53aW5kb3cuc2Nyb2xsVG8gJiYgJ3BhZ2VYT2Zmc2V0JyBpbiB0aGlzLndpbmRvdztcbiAgICB9IGNhdGNoIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gIH1cbn1cblxuZnVuY3Rpb24gZ2V0U2Nyb2xsUmVzdG9yYXRpb25Qcm9wZXJ0eShvYmo6IGFueSk6IFByb3BlcnR5RGVzY3JpcHRvcnx1bmRlZmluZWQge1xuICByZXR1cm4gT2JqZWN0LmdldE93blByb3BlcnR5RGVzY3JpcHRvcihvYmosICdzY3JvbGxSZXN0b3JhdGlvbicpO1xufVxuXG5mdW5jdGlvbiBmaW5kQW5jaG9yRnJvbURvY3VtZW50KGRvY3VtZW50OiBEb2N1bWVudCwgdGFyZ2V0OiBzdHJpbmcpOiBIVE1MRWxlbWVudHxudWxsIHtcbiAgY29uc3QgZG9jdW1lbnRSZXN1bHQgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCh0YXJnZXQpIHx8IGRvY3VtZW50LmdldEVsZW1lbnRzQnlOYW1lKHRhcmdldClbMF07XG5cbiAgaWYgKGRvY3VtZW50UmVzdWx0KSB7XG4gICAgcmV0dXJuIGRvY3VtZW50UmVzdWx0O1xuICB9XG5cbiAgLy8gYGdldEVsZW1lbnRCeUlkYCBhbmQgYGdldEVsZW1lbnRzQnlOYW1lYCB3b24ndCBwaWVyY2UgdGhyb3VnaCB0aGUgc2hhZG93IERPTSBzbyB3ZVxuICAvLyBoYXZlIHRvIHRyYXZlcnNlIHRoZSBET00gbWFudWFsbHkgYW5kIGRvIHRoZSBsb29rdXAgdGhyb3VnaCB0aGUgc2hhZG93IHJvb3RzLlxuICBpZiAodHlwZW9mIGRvY3VtZW50LmNyZWF0ZVRyZWVXYWxrZXIgPT09ICdmdW5jdGlvbicgJiYgZG9jdW1lbnQuYm9keSAmJlxuICAgICAgdHlwZW9mIGRvY3VtZW50LmJvZHkuYXR0YWNoU2hhZG93ID09PSAnZnVuY3Rpb24nKSB7XG4gICAgY29uc3QgdHJlZVdhbGtlciA9IGRvY3VtZW50LmNyZWF0ZVRyZWVXYWxrZXIoZG9jdW1lbnQuYm9keSwgTm9kZUZpbHRlci5TSE9XX0VMRU1FTlQpO1xuICAgIGxldCBjdXJyZW50Tm9kZSA9IHRyZWVXYWxrZXIuY3VycmVudE5vZGUgYXMgSFRNTEVsZW1lbnQgfCBudWxsO1xuXG4gICAgd2hpbGUgKGN1cnJlbnROb2RlKSB7XG4gICAgICBjb25zdCBzaGFkb3dSb290ID0gY3VycmVudE5vZGUuc2hhZG93Um9vdDtcblxuICAgICAgaWYgKHNoYWRvd1Jvb3QpIHtcbiAgICAgICAgLy8gTm90ZSB0aGF0IGBTaGFkb3dSb290YCBkb2Vzbid0IHN1cHBvcnQgYGdldEVsZW1lbnRzQnlOYW1lYFxuICAgICAgICAvLyBzbyB3ZSBoYXZlIHRvIGZhbGwgYmFjayB0byBgcXVlcnlTZWxlY3RvcmAuXG4gICAgICAgIGNvbnN0IHJlc3VsdCA9XG4gICAgICAgICAgICBzaGFkb3dSb290LmdldEVsZW1lbnRCeUlkKHRhcmdldCkgfHwgc2hhZG93Um9vdC5xdWVyeVNlbGVjdG9yKGBbbmFtZT1cIiR7dGFyZ2V0fVwiXWApO1xuICAgICAgICBpZiAocmVzdWx0KSB7XG4gICAgICAgICAgcmV0dXJuIHJlc3VsdDtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBjdXJyZW50Tm9kZSA9IHRyZWVXYWxrZXIubmV4dE5vZGUoKSBhcyBIVE1MRWxlbWVudCB8IG51bGw7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIG51bGw7XG59XG5cbi8qKlxuICogUHJvdmlkZXMgYW4gZW1wdHkgaW1wbGVtZW50YXRpb24gb2YgdGhlIHZpZXdwb3J0IHNjcm9sbGVyLlxuICovXG5leHBvcnQgY2xhc3MgTnVsbFZpZXdwb3J0U2Nyb2xsZXIgaW1wbGVtZW50cyBWaWV3cG9ydFNjcm9sbGVyIHtcbiAgLyoqXG4gICAqIEVtcHR5IGltcGxlbWVudGF0aW9uXG4gICAqL1xuICBzZXRPZmZzZXQob2Zmc2V0OiBbbnVtYmVyLCBudW1iZXJdfCgoKSA9PiBbbnVtYmVyLCBudW1iZXJdKSk6IHZvaWQge31cblxuICAvKipcbiAgICogRW1wdHkgaW1wbGVtZW50YXRpb25cbiAgICovXG4gIGdldFNjcm9sbFBvc2l0aW9uKCk6IFtudW1iZXIsIG51bWJlcl0ge1xuICAgIHJldHVybiBbMCwgMF07XG4gIH1cblxuICAvKipcbiAgICogRW1wdHkgaW1wbGVtZW50YXRpb25cbiAgICovXG4gIHNjcm9sbFRvUG9zaXRpb24ocG9zaXRpb246IFtudW1iZXIsIG51bWJlcl0pOiB2b2lkIHt9XG5cbiAgLyoqXG4gICAqIEVtcHR5IGltcGxlbWVudGF0aW9uXG4gICAqL1xuICBzY3JvbGxUb0FuY2hvcihhbmNob3I6IHN0cmluZyk6IHZvaWQge31cblxuICAvKipcbiAgICogRW1wdHkgaW1wbGVtZW50YXRpb25cbiAgICovXG4gIHNldEhpc3RvcnlTY3JvbGxSZXN0b3JhdGlvbihzY3JvbGxSZXN0b3JhdGlvbjogJ2F1dG8nfCdtYW51YWwnKTogdm9pZCB7fVxufVxuIl19