/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { XSS_SECURITY_URL } from '../error_details_base_url';
import { trustedHTMLFromString } from '../util/security/trusted_types';
import { getInertBodyHelper } from './inert_body';
import { _sanitizeUrl } from './url_sanitizer';
function tagSet(tags) {
    const res = {};
    for (const t of tags.split(','))
        res[t] = true;
    return res;
}
function merge(...sets) {
    const res = {};
    for (const s of sets) {
        for (const v in s) {
            if (s.hasOwnProperty(v))
                res[v] = true;
        }
    }
    return res;
}
// Good source of info about elements and attributes
// https://html.spec.whatwg.org/#semantics
// https://simon.html5.org/html-elements
// Safe Void Elements - HTML5
// https://html.spec.whatwg.org/#void-elements
const VOID_ELEMENTS = tagSet('area,br,col,hr,img,wbr');
// Elements that you can, intentionally, leave open (and which close themselves)
// https://html.spec.whatwg.org/#optional-tags
const OPTIONAL_END_TAG_BLOCK_ELEMENTS = tagSet('colgroup,dd,dt,li,p,tbody,td,tfoot,th,thead,tr');
const OPTIONAL_END_TAG_INLINE_ELEMENTS = tagSet('rp,rt');
const OPTIONAL_END_TAG_ELEMENTS = merge(OPTIONAL_END_TAG_INLINE_ELEMENTS, OPTIONAL_END_TAG_BLOCK_ELEMENTS);
// Safe Block Elements - HTML5
const BLOCK_ELEMENTS = merge(OPTIONAL_END_TAG_BLOCK_ELEMENTS, tagSet('address,article,' +
    'aside,blockquote,caption,center,del,details,dialog,dir,div,dl,figure,figcaption,footer,h1,h2,h3,h4,h5,' +
    'h6,header,hgroup,hr,ins,main,map,menu,nav,ol,pre,section,summary,table,ul'));
// Inline Elements - HTML5
const INLINE_ELEMENTS = merge(OPTIONAL_END_TAG_INLINE_ELEMENTS, tagSet('a,abbr,acronym,audio,b,' +
    'bdi,bdo,big,br,cite,code,del,dfn,em,font,i,img,ins,kbd,label,map,mark,picture,q,ruby,rp,rt,s,' +
    'samp,small,source,span,strike,strong,sub,sup,time,track,tt,u,var,video'));
export const VALID_ELEMENTS = merge(VOID_ELEMENTS, BLOCK_ELEMENTS, INLINE_ELEMENTS, OPTIONAL_END_TAG_ELEMENTS);
// Attributes that have href and hence need to be sanitized
export const URI_ATTRS = tagSet('background,cite,href,itemtype,longdesc,poster,src,xlink:href');
const HTML_ATTRS = tagSet('abbr,accesskey,align,alt,autoplay,axis,bgcolor,border,cellpadding,cellspacing,class,clear,color,cols,colspan,' +
    'compact,controls,coords,datetime,default,dir,download,face,headers,height,hidden,hreflang,hspace,' +
    'ismap,itemscope,itemprop,kind,label,lang,language,loop,media,muted,nohref,nowrap,open,preload,rel,rev,role,rows,rowspan,rules,' +
    'scope,scrolling,shape,size,sizes,span,srclang,srcset,start,summary,tabindex,target,title,translate,type,usemap,' +
    'valign,value,vspace,width');
// Accessibility attributes as per WAI-ARIA 1.1 (W3C Working Draft 14 December 2018)
const ARIA_ATTRS = tagSet('aria-activedescendant,aria-atomic,aria-autocomplete,aria-busy,aria-checked,aria-colcount,aria-colindex,' +
    'aria-colspan,aria-controls,aria-current,aria-describedby,aria-details,aria-disabled,aria-dropeffect,' +
    'aria-errormessage,aria-expanded,aria-flowto,aria-grabbed,aria-haspopup,aria-hidden,aria-invalid,' +
    'aria-keyshortcuts,aria-label,aria-labelledby,aria-level,aria-live,aria-modal,aria-multiline,' +
    'aria-multiselectable,aria-orientation,aria-owns,aria-placeholder,aria-posinset,aria-pressed,aria-readonly,' +
    'aria-relevant,aria-required,aria-roledescription,aria-rowcount,aria-rowindex,aria-rowspan,aria-selected,' +
    'aria-setsize,aria-sort,aria-valuemax,aria-valuemin,aria-valuenow,aria-valuetext');
// NB: This currently consciously doesn't support SVG. SVG sanitization has had several security
// issues in the past, so it seems safer to leave it out if possible. If support for binding SVG via
// innerHTML is required, SVG attributes should be added here.
// NB: Sanitization does not allow <form> elements or other active elements (<button> etc). Those
// can be sanitized, but they increase security surface area without a legitimate use case, so they
// are left out here.
export const VALID_ATTRS = merge(URI_ATTRS, HTML_ATTRS, ARIA_ATTRS);
// Elements whose content should not be traversed/preserved, if the elements themselves are invalid.
//
// Typically, `<invalid>Some content</invalid>` would traverse (and in this case preserve)
// `Some content`, but strip `invalid-element` opening/closing tags. For some elements, though, we
// don't want to preserve the content, if the elements themselves are going to be removed.
const SKIP_TRAVERSING_CONTENT_IF_INVALID_ELEMENTS = tagSet('script,style,template');
/**
 * SanitizingHtmlSerializer serializes a DOM fragment, stripping out any unsafe elements and unsafe
 * attributes.
 */
class SanitizingHtmlSerializer {
    constructor() {
        // Explicitly track if something was stripped, to avoid accidentally warning of sanitization just
        // because characters were re-encoded.
        this.sanitizedSomething = false;
        this.buf = [];
    }
    sanitizeChildren(el) {
        // This cannot use a TreeWalker, as it has to run on Angular's various DOM adapters.
        // However this code never accesses properties off of `document` before deleting its contents
        // again, so it shouldn't be vulnerable to DOM clobbering.
        let current = el.firstChild;
        let traverseContent = true;
        while (current) {
            if (current.nodeType === Node.ELEMENT_NODE) {
                traverseContent = this.startElement(current);
            }
            else if (current.nodeType === Node.TEXT_NODE) {
                this.chars(current.nodeValue);
            }
            else {
                // Strip non-element, non-text nodes.
                this.sanitizedSomething = true;
            }
            if (traverseContent && current.firstChild) {
                current = current.firstChild;
                continue;
            }
            while (current) {
                // Leaving the element. Walk up and to the right, closing tags as we go.
                if (current.nodeType === Node.ELEMENT_NODE) {
                    this.endElement(current);
                }
                let next = this.checkClobberedElement(current, current.nextSibling);
                if (next) {
                    current = next;
                    break;
                }
                current = this.checkClobberedElement(current, current.parentNode);
            }
        }
        return this.buf.join('');
    }
    /**
     * Sanitizes an opening element tag (if valid) and returns whether the element's contents should
     * be traversed. Element content must always be traversed (even if the element itself is not
     * valid/safe), unless the element is one of `SKIP_TRAVERSING_CONTENT_IF_INVALID_ELEMENTS`.
     *
     * @param element The element to sanitize.
     * @return True if the element's contents should be traversed.
     */
    startElement(element) {
        const tagName = element.nodeName.toLowerCase();
        if (!VALID_ELEMENTS.hasOwnProperty(tagName)) {
            this.sanitizedSomething = true;
            return !SKIP_TRAVERSING_CONTENT_IF_INVALID_ELEMENTS.hasOwnProperty(tagName);
        }
        this.buf.push('<');
        this.buf.push(tagName);
        const elAttrs = element.attributes;
        for (let i = 0; i < elAttrs.length; i++) {
            const elAttr = elAttrs.item(i);
            const attrName = elAttr.name;
            const lower = attrName.toLowerCase();
            if (!VALID_ATTRS.hasOwnProperty(lower)) {
                this.sanitizedSomething = true;
                continue;
            }
            let value = elAttr.value;
            // TODO(martinprobst): Special case image URIs for data:image/...
            if (URI_ATTRS[lower])
                value = _sanitizeUrl(value);
            this.buf.push(' ', attrName, '="', encodeEntities(value), '"');
        }
        this.buf.push('>');
        return true;
    }
    endElement(current) {
        const tagName = current.nodeName.toLowerCase();
        if (VALID_ELEMENTS.hasOwnProperty(tagName) && !VOID_ELEMENTS.hasOwnProperty(tagName)) {
            this.buf.push('</');
            this.buf.push(tagName);
            this.buf.push('>');
        }
    }
    chars(chars) {
        this.buf.push(encodeEntities(chars));
    }
    checkClobberedElement(node, nextNode) {
        if (nextNode &&
            (node.compareDocumentPosition(nextNode) &
                Node.DOCUMENT_POSITION_CONTAINED_BY) === Node.DOCUMENT_POSITION_CONTAINED_BY) {
            throw new Error(`Failed to sanitize html because the element is clobbered: ${node.outerHTML}`);
        }
        return nextNode;
    }
}
// Regular Expressions for parsing tags and attributes
const SURROGATE_PAIR_REGEXP = /[\uD800-\uDBFF][\uDC00-\uDFFF]/g;
// ! to ~ is the ASCII range.
const NON_ALPHANUMERIC_REGEXP = /([^\#-~ |!])/g;
/**
 * Escapes all potentially dangerous characters, so that the
 * resulting string can be safely inserted into attribute or
 * element text.
 * @param value
 */
function encodeEntities(value) {
    return value.replace(/&/g, '&amp;')
        .replace(SURROGATE_PAIR_REGEXP, function (match) {
        const hi = match.charCodeAt(0);
        const low = match.charCodeAt(1);
        return '&#' + (((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000) + ';';
    })
        .replace(NON_ALPHANUMERIC_REGEXP, function (match) {
        return '&#' + match.charCodeAt(0) + ';';
    })
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}
let inertBodyHelper;
/**
 * Sanitizes the given unsafe, untrusted HTML fragment, and returns HTML text that is safe to add to
 * the DOM in a browser environment.
 */
export function _sanitizeHtml(defaultDoc, unsafeHtmlInput) {
    let inertBodyElement = null;
    try {
        inertBodyHelper = inertBodyHelper || getInertBodyHelper(defaultDoc);
        // Make sure unsafeHtml is actually a string (TypeScript types are not enforced at runtime).
        let unsafeHtml = unsafeHtmlInput ? String(unsafeHtmlInput) : '';
        inertBodyElement = inertBodyHelper.getInertBodyElement(unsafeHtml);
        // mXSS protection. Repeatedly parse the document to make sure it stabilizes, so that a browser
        // trying to auto-correct incorrect HTML cannot cause formerly inert HTML to become dangerous.
        let mXSSAttempts = 5;
        let parsedHtml = unsafeHtml;
        do {
            if (mXSSAttempts === 0) {
                throw new Error('Failed to sanitize html because the input is unstable');
            }
            mXSSAttempts--;
            unsafeHtml = parsedHtml;
            parsedHtml = inertBodyElement.innerHTML;
            inertBodyElement = inertBodyHelper.getInertBodyElement(unsafeHtml);
        } while (unsafeHtml !== parsedHtml);
        const sanitizer = new SanitizingHtmlSerializer();
        const safeHtml = sanitizer.sanitizeChildren(getTemplateContent(inertBodyElement) || inertBodyElement);
        if ((typeof ngDevMode === 'undefined' || ngDevMode) && sanitizer.sanitizedSomething) {
            console.warn(`WARNING: sanitizing HTML stripped some content, see ${XSS_SECURITY_URL}`);
        }
        return trustedHTMLFromString(safeHtml);
    }
    finally {
        // In case anything goes wrong, clear out inertElement to reset the entire DOM structure.
        if (inertBodyElement) {
            const parent = getTemplateContent(inertBodyElement) || inertBodyElement;
            while (parent.firstChild) {
                parent.removeChild(parent.firstChild);
            }
        }
    }
}
export function getTemplateContent(el) {
    return 'content' in el /** Microsoft/TypeScript#21517 */ && isTemplateElement(el) ?
        el.content :
        null;
}
function isTemplateElement(el) {
    return el.nodeType === Node.ELEMENT_NODE && el.nodeName === 'TEMPLATE';
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaHRtbF9zYW5pdGl6ZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3NyYy9zYW5pdGl6YXRpb24vaHRtbF9zYW5pdGl6ZXIudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLGdCQUFnQixFQUFDLE1BQU0sMkJBQTJCLENBQUM7QUFFM0QsT0FBTyxFQUFDLHFCQUFxQixFQUFDLE1BQU0sZ0NBQWdDLENBQUM7QUFFckUsT0FBTyxFQUFDLGtCQUFrQixFQUFrQixNQUFNLGNBQWMsQ0FBQztBQUNqRSxPQUFPLEVBQUMsWUFBWSxFQUFDLE1BQU0saUJBQWlCLENBQUM7QUFFN0MsU0FBUyxNQUFNLENBQUMsSUFBWTtJQUMxQixNQUFNLEdBQUcsR0FBMkIsRUFBRSxDQUFDO0lBQ3ZDLEtBQUssTUFBTSxDQUFDLElBQUksSUFBSSxDQUFDLEtBQUssQ0FBQyxHQUFHLENBQUM7UUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsSUFBSSxDQUFDO0lBQy9DLE9BQU8sR0FBRyxDQUFDO0FBQ2IsQ0FBQztBQUVELFNBQVMsS0FBSyxDQUFDLEdBQUcsSUFBOEI7SUFDOUMsTUFBTSxHQUFHLEdBQTJCLEVBQUUsQ0FBQztJQUN2QyxLQUFLLE1BQU0sQ0FBQyxJQUFJLElBQUksRUFBRTtRQUNwQixLQUFLLE1BQU0sQ0FBQyxJQUFJLENBQUMsRUFBRTtZQUNqQixJQUFJLENBQUMsQ0FBQyxjQUFjLENBQUMsQ0FBQyxDQUFDO2dCQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxJQUFJLENBQUM7U0FDeEM7S0FDRjtJQUNELE9BQU8sR0FBRyxDQUFDO0FBQ2IsQ0FBQztBQUVELG9EQUFvRDtBQUNwRCwwQ0FBMEM7QUFDMUMsd0NBQXdDO0FBRXhDLDZCQUE2QjtBQUM3Qiw4Q0FBOEM7QUFDOUMsTUFBTSxhQUFhLEdBQUcsTUFBTSxDQUFDLHdCQUF3QixD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Q0FBQyxPQUFPLFNBQVMsS0FBSyxXQUFXLElBQUksU0FBUyxDQUFDLElBQUksU0FBUyxDQUFDLGtCQUFrQixFQUFFO1lBQ25GLE9BQU8sQ0FBQyxJQUFJLENBQUMsdURBQXVELGdCQUFnQixFQUFFLENBQUMsQ0FBQztTQUN6RjtRQUVELE9BQU8scUJBQXFCLENBQUMsUUFBUSxDQUFDLENBQUM7S0FDeEM7WUFBUztRQUNSLHlGQUF5RjtRQUN6RixJQUFJLGdCQUFnQixFQUFFO1lBQ3BCLE1BQU0sTUFBTSxHQUFHLGtCQUFrQixDQUFDLGdCQUFnQixDQUFDLElBQUksZ0JBQWdCLENBQUM7WUFDeEUsT0FBTyxNQUFNLENBQUMsVUFBVSxFQUFFO2dCQUN4QixNQUFNLENBQUMsV0FBVyxDQUFDLE1BQU0sQ0FBQyxVQUFVLENBQUMsQ0FBQzthQUN2QztTQUNGO0tBQ0Y7QUFDSCxDQUFDO0FBRUQsTUFBTSxVQUFVLGtCQUFrQixDQUFDLEVBQVE7SUFDekMsT0FBTyxTQUFTLElBQUssRUFBUyxDQUFDLGlDQUFrQyxJQUFJLGlCQUFpQixDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUM7UUFDeEYsRUFBRSxDQUFDLE9BQU8sQ0FBQyxDQUFDO1FBQ1osSUFBSSxDQUFDO0FBQ1gsQ0FBQztBQUNELFNBQVMsaUJBQWlCLENBQUMsRUFBUTtJQUNqQyxPQUFPLEVBQUUsQ0FBQyxRQUFRLEtBQUssSUFBSSxDQUFDLFlBQVksSUFBSSxFQUFFLENBQUMsUUFBUSxLQUFLLFVBQVUsQ0FBQztBQUN6RSxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7WFNTX1NFQ1VSSVRZX1VSTH0gZnJvbSAnLi4vZXJyb3JfZGV0YWlsc19iYXNlX3VybCc7XG5pbXBvcnQge1RydXN0ZWRIVE1MfSBmcm9tICcuLi91dGlsL3NlY3VyaXR5L3RydXN0ZWRfdHlwZV9kZWZzJztcbmltcG9ydCB7dHJ1c3RlZEhUTUxGcm9tU3RyaW5nfSBmcm9tICcuLi91dGlsL3NlY3VyaXR5L3RydXN0ZWRfdHlwZXMnO1xuXG5pbXBvcnQge2dldEluZXJ0Qm9keUhlbHBlciwgSW5lcnRCb2R5SGVscGVyfSBmcm9tICcuL2luZXJ0X2JvZHknO1xuaW1wb3J0IHtfc2FuaXRpemVVcmx9IGZyb20gJy4vdXJsX3Nhbml0aXplcic7XG5cbmZ1bmN0aW9uIHRhZ1NldCh0YWdzOiBzdHJpbmcpOiB7W2s6IHN0cmluZ106IGJvb2xlYW59IHtcbiAgY29uc3QgcmVzOiB7W2s6IHN0cmluZ106IGJvb2xlYW59ID0ge307XG4gIGZvciAoY29uc3QgdCBvZiB0YWdzLnNwbGl0KCcsJykpIHJlc1t0XSA9IHRydWU7XG4gIHJldHVybiByZXM7XG59XG5cbmZ1bmN0aW9uIG1lcmdlKC4uLnNldHM6IHtbazogc3RyaW5nXTogYm9vbGVhbn1bXSk6IHtbazogc3RyaW5nXTogYm9vbGVhbn0ge1xuICBjb25zdCByZXM6IHtbazogc3RyaW5nXTogYm9vbGVhbn0gPSB7fTtcbiAgZm9yIChjb25zdCBzIG9mIHNldHMpIHtcbiAgICBmb3IgKGNvbnN0IHYgaW4gcykge1xuICAgICAgaWYgKHMuaGFzT3duUHJvcGVydHkodikpIHJlc1t2XSA9IHRydWU7XG4gICAgfVxuICB9XG4gIHJldHVybiByZXM7XG59XG5cbi8vIEdvb2Qgc291cmNlIG9mIGluZm8gYWJvdXQgZWxlbWVudHMgYW5kIGF0dHJpYnV0ZXNcbi8vIGh0dHBzOi8vaHRtbC5zcGVjLndoYXR3Zy5vcmcvI3NlbWFudGljc1xuLy8gaHR0cHM6Ly9zaW1vbi5odG1sNS5vcmcvaHRtbC1lbGVtZW50c1xuXG4vLyBTYWZlIFZvaWQgRWxlbWVudHMgLSBIVE1MNVxuLy8gaHR0cHM6Ly9odG1sLnNwZWMud2hhdHdnLm9yZy8jdm9pZC1lbGVtZW50c1xuY29uc3QgVk9JRF9FTEVNRU5UUyA9IHRhZ1NldCgnYXJlYSxicixjb2wsaHIsaW1nLHdicicpO1xuXG4vLyBFbGVtZW50cyB0aGF0IHlvdSBjYW4sIGludGVudGlvbmFsbHksIGxlYXZlIG9wZW4gKGFuZCB3aGljaCBjbG9zZSB0aGVtc2VsdmVzKVxuLy8gaHR0cHM6Ly9odG1sLnNwZWMud2hhdHdnLm9yZy8jb3B0aW9uYWwtdGFnc1xuY29uc3QgT1BUSU9OQUxfRU5EX1RBR19CTE9DS19FTEVNRU5UUyA9IHRhZ1NldCgnY29sZ3JvdXAsZGQsZHQsbGkscCx0Ym9keSx0ZCx0Zm9vdCx0aCx0aGVhZCx0cicpO1xuY29uc3QgT1BUSU9OQUxfRU5EX1RBR19JTkxJTkVfRUxFTUVOVFMgPSB0YWdTZXQoJ3JwLHJ0Jyk7XG5jb25zdCBPUFRJT05BTF9FTkRfVEFHX0VMRU1FTlRTID1cbiAgICBtZXJnZShPUFRJT05BTF9FTkRfVEFHX0lOTElORV9FTEVNRU5UUywgT1BUSU9OQUxfRU5EX1RBR19CTE9DS19FTEVNRU5UUyk7XG5cbi8vIFNhZmUgQmxvY2sgRWxlbWVudHMgLSBIVE1MNVxuY29uc3QgQkxPQ0tfRUxFTUVOVFMgPSBtZXJnZShcbiAgICBPUFRJT05BTF9FTkRfVEFHX0JMT0NLX0VMRU1FTlRTLFxuICAgIHRhZ1NldChcbiAgICAgICAgJ2FkZHJlc3MsYXJ0aWNsZSwnICtcbiAgICAgICAgJ2FzaWRlLGJsb2NrcXVvdGUsY2FwdGlvbixjZW50ZXIsZGVsLGRldGFpbHMsZGlhbG9nLGRpcixkaXYsZGwsZmlndXJlLGZpZ2NhcHRpb24sZm9vdGVyLGgxLGgyLGgzLGg0LGg1LCcgK1xuICAgICAgICAnaDYsaGVhZGVyLGhncm91cCxocixpbnMsbWFpbixtYXAsbWVudSxuYXYsb2wscHJlLHNlY3Rpb24sc3VtbWFyeSx0YWJsZSx1bCcpKTtcblxuLy8gSW5saW5lIEVsZW1lbnRzIC0gSFRNTDVcbmNvbnN0IElOTElORV9FTEVNRU5UUyA9IG1lcmdlKFxuICAgIE9QVElPTkFMX0VORF9UQUdfSU5MSU5FX0VMRU1FTlRTLFxuICAgIHRhZ1NldChcbiAgICAgICAgJ2EsYWJicixhY3JvbnltLGF1ZGlvLGIsJyArXG4gICAgICAgICdiZGksYmRvLGJpZyxicixjaXRlLGNvZGUsZGVsLGRmbixlbSxmb250LGksaW1nLGlucyxrYmQsbGFiZWwsbWFwLG1hcmsscGljdHVyZSxxLHJ1YnkscnAscnQscywnICtcbiAgICAgICAgJ3NhbXAsc21hbGwsc291cmNlLHNwYW4sc3RyaWtlLHN0cm9uZyxzdWIsc3VwLHRpbWUsdHJhY2ssdHQsdSx2YXIsdmlkZW8nKSk7XG5cbmV4cG9ydCBjb25zdCBWQUxJRF9FTEVNRU5UUyA9XG4gICAgbWVyZ2UoVk9JRF9FTEVNRU5UUywgQkxPQ0tfRUxFTUVOVFMsIElOTElORV9FTEVNRU5UUywgT1BUSU9OQUxfRU5EX1RBR19FTEVNRU5UUyk7XG5cbi8vIEF0dHJpYnV0ZXMgdGhhdCBoYXZlIGhyZWYgYW5kIGhlbmNlIG5lZWQgdG8gYmUgc2FuaXRpemVkXG5leHBvcnQgY29uc3QgVVJJX0FUVFJTID0gdGFnU2V0KCdiYWNrZ3JvdW5kLGNpdGUsaHJlZixpdGVtdHlwZSxsb25nZGVzYyxwb3N0ZXIsc3JjLHhsaW5rOmhyZWYnKTtcblxuY29uc3QgSFRNTF9BVFRSUyA9IHRhZ1NldChcbiAgICAnYWJicixhY2Nlc3NrZXksYWxpZ24sYWx0LGF1dG9wbGF5LGF4aXMsYmdjb2xvcixib3JkZXIsY2VsbHBhZGRpbmcsY2VsbHNwYWNpbmcsY2xhc3MsY2xlYXIsY29sb3IsY29scyxjb2xzcGFuLCcgK1xuICAgICdjb21wYWN0LGNvbnRyb2xzLGNvb3JkcyxkYXRldGltZSxkZWZhdWx0LGRpcixkb3dubG9hZCxmYWNlLGhlYWRlcnMsaGVpZ2h0LGhpZGRlbixocmVmbGFuZyxoc3BhY2UsJyArXG4gICAgJ2lzbWFwLGl0ZW1zY29wZSxpdGVtcHJvcCxraW5kLGxhYmVsLGxhbmcsbGFuZ3VhZ2UsbG9vcCxtZWRpYSxtdXRlZCxub2hyZWYsbm93cmFwLG9wZW4scHJlbG9hZCxyZWwscmV2LHJvbGUscm93cyxyb3dzcGFuLHJ1bGVzLCcgK1xuICAgICdzY29wZSxzY3JvbGxpbmcsc2hhcGUsc2l6ZSxzaXplcyxzcGFuLHNyY2xhbmcsc3Jjc2V0LHN0YXJ0LHN1bW1hcnksdGFiaW5kZXgsdGFyZ2V0LHRpdGxlLHRyYW5zbGF0ZSx0eXBlLHVzZW1hcCwnICtcbiAgICAndmFsaWduLHZhbHVlLHZzcGFjZSx3aWR0aCcpO1xuXG4vLyBBY2Nlc3NpYmlsaXR5IGF0dHJpYnV0ZXMgYXMgcGVyIFdBSS1BUklBIDEuMSAoVzNDIFdvcmtpbmcgRHJhZnQgMTQgRGVjZW1iZXIgMjAxOClcbmNvbnN0IEFSSUFfQVRUUlMgPSB0YWdTZXQoXG4gICAgJ2FyaWEtYWN0aXZlZGVzY2VuZGFudCxhcmlhLWF0b21pYyxhcmlhLWF1dG9jb21wbGV0ZSxhcmlhLWJ1c3ksYXJpYS1jaGVja2VkLGFyaWEtY29sY291bnQsYXJpYS1jb2xpbmRleCwnICtcbiAgICAnYXJpYS1jb2xzcGFuLGFyaWEtY29udHJvbHMsYXJpYS1jdXJyZW50LGFyaWEtZGVzY3JpYmVkYnksYXJpYS1kZXRhaWxzLGFyaWEtZGlzYWJsZWQsYXJpYS1kcm9wZWZmZWN0LCcgK1xuICAgICdhcmlhLWVycm9ybWVzc2FnZSxhcmlhLWV4cGFuZGVkLGFyaWEtZmxvd3RvLGFyaWEtZ3JhYmJlZCxhcmlhLWhhc3BvcHVwLGFyaWEtaGlkZGVuLGFyaWEtaW52YWxpZCwnICtcbiAgICAnYXJpYS1rZXlzaG9ydGN1dHMsYXJpYS1sYWJlbCxhcmlhLWxhYmVsbGVkYnksYXJpYS1sZXZlbCxhcmlhLWxpdmUsYXJpYS1tb2RhbCxhcmlhLW11bHRpbGluZSwnICtcbiAgICAnYXJpYS1tdWx0aXNlbGVjdGFibGUsYXJpYS1vcmllbnRhdGlvbixhcmlhLW93bnMsYXJpYS1wbGFjZWhvbGRlcixhcmlhLXBvc2luc2V0LGFyaWEtcHJlc3NlZCxhcmlhLXJlYWRvbmx5LCcgK1xuICAgICdhcmlhLXJlbGV2YW50LGFyaWEtcmVxdWlyZWQsYXJpYS1yb2xlZGVzY3JpcHRpb24sYXJpYS1yb3djb3VudCxhcmlhLXJvd2luZGV4LGFyaWEtcm93c3BhbixhcmlhLXNlbGVjdGVkLCcgK1xuICAgICdhcmlhLXNldHNpemUsYXJpYS1zb3J0LGFyaWEtdmFsdWVtYXgsYXJpYS12YWx1ZW1pbixhcmlhLXZhbHVlbm93LGFyaWEtdmFsdWV0ZXh0Jyk7XG5cbi8vIE5COiBUaGlzIGN1cnJlbnRseSBjb25zY2lvdXNseSBkb2Vzbid0IHN1cHBvcnQgU1ZHLiBTVkcgc2FuaXRpemF0aW9uIGhhcyBoYWQgc2V2ZXJhbCBzZWN1cml0eVxuLy8gaXNzdWVzIGluIHRoZSBwYXN0LCBzbyBpdCBzZWVtcyBzYWZlciB0byBsZWF2ZSBpdCBvdXQgaWYgcG9zc2libGUuIElmIHN1cHBvcnQgZm9yIGJpbmRpbmcgU1ZHIHZpYVxuLy8gaW5uZXJIVE1MIGlzIHJlcXVpcmVkLCBTVkcgYXR0cmlidXRlcyBzaG91bGQgYmUgYWRkZWQgaGVyZS5cblxuLy8gTkI6IFNhbml0aXphdGlvbiBkb2VzIG5vdCBhbGxvdyA8Zm9ybT4gZWxlbWVudHMgb3Igb3RoZXIgYWN0aXZlIGVsZW1lbnRzICg8YnV0dG9uPiBldGMpLiBUaG9zZVxuLy8gY2FuIGJlIHNhbml0aXplZCwgYnV0IHRoZXkgaW5jcmVhc2Ugc2VjdXJpdHkgc3VyZmFjZSBhcmVhIHdpdGhvdXQgYSBsZWdpdGltYXRlIHVzZSBjYXNlLCBzbyB0aGV5XG4vLyBhcmUgbGVmdCBvdXQgaGVyZS5cblxuZXhwb3J0IGNvbnN0IFZBTElEX0FUVFJTID0gbWVyZ2UoVVJJX0FUVFJTLCBIVE1MX0FUVFJTLCBBUklBX0FUVFJTKTtcblxuLy8gRWxlbWVudHMgd2hvc2UgY29udGVudCBzaG91bGQgbm90IGJlIHRyYXZlcnNlZC9wcmVzZXJ2ZWQsIGlmIHRoZSBlbGVtZW50cyB0aGVtc2VsdmVzIGFyZSBpbnZhbGlkLlxuLy9cbi8vIFR5cGljYWxseSwgYDxpbnZhbGlkPlNvbWUgY29udGVudDwvaW52YWxpZD5gIHdvdWxkIHRyYXZlcnNlIChhbmQgaW4gdGhpcyBjYXNlIHByZXNlcnZlKVxuLy8gYFNvbWUgY29udGVudGAsIGJ1dCBzdHJpcCBgaW52YWxpZC1lbGVtZW50YCBvcGVuaW5nL2Nsb3NpbmcgdGFncy4gRm9yIHNvbWUgZWxlbWVudHMsIHRob3VnaCwgd2Vcbi8vIGRvbid0IHdhbnQgdG8gcHJlc2VydmUgdGhlIGNvbnRlbnQsIGlmIHRoZSBlbGVtZW50cyB0aGVtc2VsdmVzIGFyZSBnb2luZyB0byBiZSByZW1vdmVkLlxuY29uc3QgU0tJUF9UUkFWRVJTSU5HX0NPTlRFTlRfSUZfSU5WQUxJRF9FTEVNRU5UUyA9IHRhZ1NldCgnc2NyaXB0LHN0eWxlLHRlbXBsYXRlJyk7XG5cbi8qKlxuICogU2FuaXRpemluZ0h0bWxTZXJpYWxpemVyIHNlcmlhbGl6ZXMgYSBET00gZnJhZ21lbnQsIHN0cmlwcGluZyBvdXQgYW55IHVuc2FmZSBlbGVtZW50cyBhbmQgdW5zYWZlXG4gKiBhdHRyaWJ1dGVzLlxuICovXG5jbGFzcyBTYW5pdGl6aW5nSHRtbFNlcmlhbGl6ZXIge1xuICAvLyBFeHBsaWNpdGx5IHRyYWNrIGlmIHNvbWV0aGluZyB3YXMgc3RyaXBwZWQsIHRvIGF2b2lkIGFjY2lkZW50YWxseSB3YXJuaW5nIG9mIHNhbml0aXphdGlvbiBqdXN0XG4gIC8vIGJlY2F1c2UgY2hhcmFjdGVycyB3ZXJlIHJlLWVuY29kZWQuXG4gIHB1YmxpYyBzYW5pdGl6ZWRTb21ldGhpbmcgPSBmYWxzZTtcbiAgcHJpdmF0ZSBidWY6IHN0cmluZ1tdID0gW107XG5cbiAgc2FuaXRpemVDaGlsZHJlbihlbDogRWxlbWVudCk6IHN0cmluZyB7XG4gICAgLy8gVGhpcyBjYW5ub3QgdXNlIGEgVHJlZVdhbGtlciwgYXMgaXQgaGFzIHRvIHJ1biBvbiBBbmd1bGFyJ3MgdmFyaW91cyBET00gYWRhcHRlcnMuXG4gICAgLy8gSG93ZXZlciB0aGlzIGNvZGUgbmV2ZXIgYWNjZXNzZXMgcHJvcGVydGllcyBvZmYgb2YgYGRvY3VtZW50YCBiZWZvcmUgZGVsZXRpbmcgaXRzIGNvbnRlbnRzXG4gICAgLy8gYWdhaW4sIHNvIGl0IHNob3VsZG4ndCBiZSB2dWxuZXJhYmxlIHRvIERPTSBjbG9iYmVyaW5nLlxuICAgIGxldCBjdXJyZW50OiBOb2RlID0gZWwuZmlyc3RDaGlsZCE7XG4gICAgbGV0IHRyYXZlcnNlQ29udGVudCA9IHRydWU7XG4gICAgd2hpbGUgKGN1cnJlbnQpIHtcbiAgICAgIGlmIChjdXJyZW50Lm5vZGVUeXBlID09PSBOb2RlLkVMRU1FTlRfTk9ERSkge1xuICAgICAgICB0cmF2ZXJzZUNvbnRlbnQgPSB0aGlzLnN0YXJ0RWxlbWVudChjdXJyZW50IGFzIEVsZW1lbnQpO1xuICAgICAgfSBlbHNlIGlmIChjdXJyZW50Lm5vZGVUeXBlID09PSBOb2RlLlRFWFRfTk9ERSkge1xuICAgICAgICB0aGlzLmNoYXJzKGN1cnJlbnQubm9kZVZhbHVlISk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICAvLyBTdHJpcCBub24tZWxlbWVudCwgbm9uLXRleHQgbm9kZXMuXG4gICAgICAgIHRoaXMuc2FuaXRpemVkU29tZXRoaW5nID0gdHJ1ZTtcbiAgICAgIH1cbiAgICAgIGlmICh0cmF2ZXJzZUNvbnRlbnQgJiYgY3VycmVudC5maXJzdENoaWxkKSB7XG4gICAgICAgIGN1cnJlbnQgPSBjdXJyZW50LmZpcnN0Q2hpbGQhO1xuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cbiAgICAgIHdoaWxlIChjdXJyZW50KSB7XG4gICAgICAgIC8vIExlYXZpbmcgdGhlIGVsZW1lbnQuIFdhbGsgdXAgYW5kIHRvIHRoZSByaWdodCwgY2xvc2luZyB0YWdzIGFzIHdlIGdvLlxuICAgICAgICBpZiAoY3VycmVudC5ub2RlVHlwZSA9PT0gTm9kZS5FTEVNRU5UX05PREUpIHtcbiAgICAgICAgICB0aGlzLmVuZEVsZW1lbnQoY3VycmVudCBhcyBFbGVtZW50KTtcbiAgICAgICAgfVxuXG4gICAgICAgIGxldCBuZXh0ID0gdGhpcy5jaGVja0Nsb2JiZXJlZEVsZW1lbnQoY3VycmVudCwgY3VycmVudC5uZXh0U2libGluZyEpO1xuXG4gICAgICAgIGlmIChuZXh0KSB7XG4gICAgICAgICAgY3VycmVudCA9IG5leHQ7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cblxuICAgICAgICBjdXJyZW50ID0gdGhpcy5jaGVja0Nsb2JiZXJlZEVsZW1lbnQoY3VycmVudCwgY3VycmVudC5wYXJlbnROb2RlISk7XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiB0aGlzLmJ1Zi5qb2luKCcnKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBTYW5pdGl6ZXMgYW4gb3BlbmluZyBlbGVtZW50IHRhZyAoaWYgdmFsaWQpIGFuZCByZXR1cm5zIHdoZXRoZXIgdGhlIGVsZW1lbnQncyBjb250ZW50cyBzaG91bGRcbiAgICogYmUgdHJhdmVyc2VkLiBFbGVtZW50IGNvbnRlbnQgbXVzdCBhbHdheXMgYmUgdHJhdmVyc2VkIChldmVuIGlmIHRoZSBlbGVtZW50IGl0c2VsZiBpcyBub3RcbiAgICogdmFsaWQvc2FmZSksIHVubGVzcyB0aGUgZWxlbWVudCBpcyBvbmUgb2YgYFNLSVBfVFJBVkVSU0lOR19DT05URU5UX0lGX0lOVkFMSURfRUxFTUVOVFNgLlxuICAgKlxuICAgKiBAcGFyYW0gZWxlbWVudCBUaGUgZWxlbWVudCB0byBzYW5pdGl6ZS5cbiAgICogQHJldHVybiBUcnVlIGlmIHRoZSBlbGVtZW50J3MgY29udGVudHMgc2hvdWxkIGJlIHRyYXZlcnNlZC5cbiAgICovXG4gIHByaXZhdGUgc3RhcnRFbGVtZW50KGVsZW1lbnQ6IEVsZW1lbnQpOiBib29sZWFuIHtcbiAgICBjb25zdCB0YWdOYW1lID0gZWxlbWVudC5ub2RlTmFtZS50b0xvd2VyQ2FzZSgpO1xuICAgIGlmICghVkFMSURfRUxFTUVOVFMuaGFzT3duUHJvcGVydHkodGFnTmFtZSkpIHtcbiAgICAgIHRoaXMuc2FuaXRpemVkU29tZXRoaW5nID0gdHJ1ZTtcbiAgICAgIHJldHVybiAhU0tJUF9UUkFWRVJTSU5HX0NPTlRFTlRfSUZfSU5WQUxJRF9FTEVNRU5UUy5oYXNPd25Qcm9wZXJ0eSh0YWdOYW1lKTtcbiAgICB9XG4gICAgdGhpcy5idWYucHVzaCgnPCcpO1xuICAgIHRoaXMuYnVmLnB1c2godGFnTmFtZSk7XG4gICAgY29uc3QgZWxBdHRycyA9IGVsZW1lbnQuYXR0cmlidXRlcztcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGVsQXR0cnMubGVuZ3RoOyBpKyspIHtcbiAgICAgIGNvbnN0IGVsQXR0ciA9IGVsQXR0cnMuaXRlbShpKTtcbiAgICAgIGNvbnN0IGF0dHJOYW1lID0gZWxBdHRyIS5uYW1lO1xuICAgICAgY29uc3QgbG93ZXIgPSBhdHRyTmFtZS50b0xvd2VyQ2FzZSgpO1xuICAgICAgaWYgKCFWQUxJRF9BVFRSUy5oYXNPd25Qcm9wZXJ0eShsb3dlcikpIHtcbiAgICAgICAgdGhpcy5zYW5pdGl6ZWRTb21ldGhpbmcgPSB0cnVlO1xuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cbiAgICAgIGxldCB2YWx1ZSA9IGVsQXR0ciEudmFsdWU7XG4gICAgICAvLyBUT0RPKG1hcnRpbnByb2JzdCk6IFNwZWNpYWwgY2FzZSBpbWFnZSBVUklzIGZvciBkYXRhOmltYWdlLy4uLlxuICAgICAgaWYgKFVSSV9BVFRSU1tsb3dlcl0pIHZhbHVlID0gX3Nhbml0aXplVXJsKHZhbHVlKTtcbiAgICAgIHRoaXMuYnVmLnB1c2goJyAnLCBhdHRyTmFtZSwgJz1cIicsIGVuY29kZUVudGl0aWVzKHZhbHVlKSwgJ1wiJyk7XG4gICAgfVxuICAgIHRoaXMuYnVmLnB1c2goJz4nKTtcbiAgICByZXR1cm4gdHJ1ZTtcbiAgfVxuXG4gIHByaXZhdGUgZW5kRWxlbWVudChjdXJyZW50OiBFbGVtZW50KSB7XG4gICAgY29uc3QgdGFnTmFtZSA9IGN1cnJlbnQubm9kZU5hbWUudG9Mb3dlckNhc2UoKTtcbiAgICBpZiAoVkFMSURfRUxFTUVOVFMuaGFzT3duUHJvcGVydHkodGFnTmFtZSkgJiYgIVZPSURfRUxFTUVOVFMuaGFzT3duUHJvcGVydHkodGFnTmFtZSkpIHtcbiAgICAgIHRoaXMuYnVmLnB1c2goJzwvJyk7XG4gICAgICB0aGlzLmJ1Zi5wdXNoKHRhZ05hbWUpO1xuICAgICAgdGhpcy5idWYucHVzaCgnPicpO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgY2hhcnMoY2hhcnM6IHN0cmluZykge1xuICAgIHRoaXMuYnVmLnB1c2goZW5jb2RlRW50aXRpZXMoY2hhcnMpKTtcbiAgfVxuXG4gIGNoZWNrQ2xvYmJlcmVkRWxlbWVudChub2RlOiBOb2RlLCBuZXh0Tm9kZTogTm9kZSk6IE5vZGUge1xuICAgIGlmIChuZXh0Tm9kZSAmJlxuICAgICAgICAobm9kZS5jb21wYXJlRG9jdW1lbnRQb3NpdGlvbihuZXh0Tm9kZSkgJlxuICAgICAgICAgTm9kZS5ET0NVTUVOVF9QT1NJVElPTl9DT05UQUlORURfQlkpID09PcKgTm9kZS5ET0NVTUVOVF9QT1NJVElPTl9DT05UQUlORURfQlkpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihgRmFpbGVkIHRvIHNhbml0aXplIGh0bWwgYmVjYXVzZSB0aGUgZWxlbWVudCBpcyBjbG9iYmVyZWQ6ICR7XG4gICAgICAgICAgKG5vZGUgYXMgRWxlbWVudCkub3V0ZXJIVE1MfWApO1xuICAgIH1cbiAgICByZXR1cm4gbmV4dE5vZGU7XG4gIH1cbn1cblxuLy8gUmVndWxhciBFeHByZXNzaW9ucyBmb3IgcGFyc2luZyB0YWdzIGFuZCBhdHRyaWJ1dGVzXG5jb25zdCBTVVJST0dBVEVfUEFJUl9SRUdFWFAgPSAvW1xcdUQ4MDAtXFx1REJGRl1bXFx1REMwMC1cXHVERkZGXS9nO1xuLy8gISB0byB+IGlzIHRoZSBBU0NJSSByYW5nZS5cbmNvbnN0IE5PTl9BTFBIQU5VTUVSSUNfUkVHRVhQID0gLyhbXlxcIy1+IHwhXSkvZztcblxuLyoqXG4gKiBFc2NhcGVzIGFsbCBwb3RlbnRpYWxseSBkYW5nZXJvdXMgY2hhcmFjdGVycywgc28gdGhhdCB0aGVcbiAqIHJlc3VsdGluZyBzdHJpbmcgY2FuIGJlIHNhZmVseSBpbnNlcnRlZCBpbnRvIGF0dHJpYnV0ZSBvclxuICogZWxlbWVudCB0ZXh0LlxuICogQHBhcmFtIHZhbHVlXG4gKi9cbmZ1bmN0aW9uIGVuY29kZUVudGl0aWVzKHZhbHVlOiBzdHJpbmcpIHtcbiAgcmV0dXJuIHZhbHVlLnJlcGxhY2UoLyYvZywgJyZhbXA7JylcbiAgICAgIC5yZXBsYWNlKFxuICAgICAgICAgIFNVUlJPR0FURV9QQUlSX1JFR0VYUCxcbiAgICAgICAgICBmdW5jdGlvbihtYXRjaDogc3RyaW5nKSB7XG4gICAgICAgICAgICBjb25zdCBoaSA9IG1hdGNoLmNoYXJDb2RlQXQoMCk7XG4gICAgICAgICAgICBjb25zdCBsb3cgPSBtYXRjaC5jaGFyQ29kZUF0KDEpO1xuICAgICAgICAgICAgcmV0dXJuICcmIycgKyAoKChoaSAtIDB4RDgwMCkgKiAweDQwMCkgKyAobG93IC0gMHhEQzAwKSArIDB4MTAwMDApICsgJzsnO1xuICAgICAgICAgIH0pXG4gICAgICAucmVwbGFjZShcbiAgICAgICAgICBOT05fQUxQSEFOVU1FUklDX1JFR0VYUCxcbiAgICAgICAgICBmdW5jdGlvbihtYXRjaDogc3RyaW5nKSB7XG4gICAgICAgICAgICByZXR1cm4gJyYjJyArIG1hdGNoLmNoYXJDb2RlQXQoMCkgKyAnOyc7XG4gICAgICAgICAgfSlcbiAgICAgIC5yZXBsYWNlKC88L2csICcmbHQ7JylcbiAgICAgIC5yZXBsYWNlKC8+L2csICcmZ3Q7Jyk7XG59XG5cbmxldCBpbmVydEJvZHlIZWxwZXI6IEluZXJ0Qm9keUhlbHBlcjtcblxuLyoqXG4gKiBTYW5pdGl6ZXMgdGhlIGdpdmVuIHVuc2FmZSwgdW50cnVzdGVkIEhUTUwgZnJhZ21lbnQsIGFuZCByZXR1cm5zIEhUTUwgdGV4dCB0aGF0IGlzIHNhZmUgdG8gYWRkIHRvXG4gKiB0aGUgRE9NIGluIGEgYnJvd3NlciBlbnZpcm9ubWVudC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIF9zYW5pdGl6ZUh0bWwoZGVmYXVsdERvYzogYW55LCB1bnNhZmVIdG1sSW5wdXQ6IHN0cmluZyk6IFRydXN0ZWRIVE1MfHN0cmluZyB7XG4gIGxldCBpbmVydEJvZHlFbGVtZW50OiBIVE1MRWxlbWVudHxudWxsID0gbnVsbDtcbiAgdHJ5IHtcbiAgICBpbmVydEJvZHlIZWxwZXIgPSBpbmVydEJvZHlIZWxwZXIgfHwgZ2V0SW5lcnRCb2R5SGVscGVyKGRlZmF1bHREb2MpO1xuICAgIC8vIE1ha2Ugc3VyZSB1bnNhZmVIdG1sIGlzIGFjdHVhbGx5IGEgc3RyaW5nIChUeXBlU2NyaXB0IHR5cGVzIGFyZSBub3QgZW5mb3JjZWQgYXQgcnVudGltZSkuXG4gICAgbGV0IHVuc2FmZUh0bWwgPSB1bnNhZmVIdG1sSW5wdXQgPyBTdHJpbmcodW5zYWZlSHRtbElucHV0KSA6ICcnO1xuICAgIGluZXJ0Qm9keUVsZW1lbnQgPSBpbmVydEJvZHlIZWxwZXIuZ2V0SW5lcnRCb2R5RWxlbWVudCh1bnNhZmVIdG1sKTtcblxuICAgIC8vIG1YU1MgcHJvdGVjdGlvbi4gUmVwZWF0ZWRseSBwYXJzZSB0aGUgZG9jdW1lbnQgdG8gbWFrZSBzdXJlIGl0IHN0YWJpbGl6ZXMsIHNvIHRoYXQgYSBicm93c2VyXG4gICAgLy8gdHJ5aW5nIHRvIGF1dG8tY29ycmVjdCBpbmNvcnJlY3QgSFRNTCBjYW5ub3QgY2F1c2UgZm9ybWVybHkgaW5lcnQgSFRNTCB0byBiZWNvbWUgZGFuZ2Vyb3VzLlxuICAgIGxldCBtWFNTQXR0ZW1wdHMgPSA1O1xuICAgIGxldCBwYXJzZWRIdG1sID0gdW5zYWZlSHRtbDtcblxuICAgIGRvIHtcbiAgICAgIGlmIChtWFNTQXR0ZW1wdHMgPT09IDApIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdGYWlsZWQgdG8gc2FuaXRpemUgaHRtbCBiZWNhdXNlIHRoZSBpbnB1dCBpcyB1bnN0YWJsZScpO1xuICAgICAgfVxuICAgICAgbVhTU0F0dGVtcHRzLS07XG5cbiAgICAgIHVuc2FmZUh0bWwgPSBwYXJzZWRIdG1sO1xuICAgICAgcGFyc2VkSHRtbCA9IGluZXJ0Qm9keUVsZW1lbnQhLmlubmVySFRNTDtcbiAgICAgIGluZXJ0Qm9keUVsZW1lbnQgPSBpbmVydEJvZHlIZWxwZXIuZ2V0SW5lcnRCb2R5RWxlbWVudCh1bnNhZmVIdG1sKTtcbiAgICB9IHdoaWxlICh1bnNhZmVIdG1sICE9PSBwYXJzZWRIdG1sKTtcblxuICAgIGNvbnN0IHNhbml0aXplciA9IG5ldyBTYW5pdGl6aW5nSHRtbFNlcmlhbGl6ZXIoKTtcbiAgICBjb25zdCBzYWZlSHRtbCA9IHNhbml0aXplci5zYW5pdGl6ZUNoaWxkcmVuKFxuICAgICAgICBnZXRUZW1wbGF0ZUNvbnRlbnQoaW5lcnRCb2R5RWxlbWVudCEpIGFzIEVsZW1lbnQgfHwgaW5lcnRCb2R5RWxlbWVudCk7XG4gICAgaWYgKCh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpICYmIHNhbml0aXplci5zYW5pdGl6ZWRTb21ldGhpbmcpIHtcbiAgICAgIGNvbnNvbGUud2FybihgV0FSTklORzogc2FuaXRpemluZyBIVE1MIHN0cmlwcGVkIHNvbWUgY29udGVudCwgc2VlICR7WFNTX1NFQ1VSSVRZX1VSTH1gKTtcbiAgICB9XG5cbiAgICByZXR1cm4gdHJ1c3RlZEhUTUxGcm9tU3RyaW5nKHNhZmVIdG1sKTtcbiAgfSBmaW5hbGx5IHtcbiAgICAvLyBJbiBjYXNlIGFueXRoaW5nIGdvZXMgd3JvbmcsIGNsZWFyIG91dCBpbmVydEVsZW1lbnQgdG8gcmVzZXQgdGhlIGVudGlyZSBET00gc3RydWN0dXJlLlxuICAgIGlmIChpbmVydEJvZHlFbGVtZW50KSB7XG4gICAgICBjb25zdCBwYXJlbnQgPSBnZXRUZW1wbGF0ZUNvbnRlbnQoaW5lcnRCb2R5RWxlbWVudCkgfHwgaW5lcnRCb2R5RWxlbWVudDtcbiAgICAgIHdoaWxlIChwYXJlbnQuZmlyc3RDaGlsZCkge1xuICAgICAgICBwYXJlbnQucmVtb3ZlQ2hpbGQocGFyZW50LmZpcnN0Q2hpbGQpO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG5leHBvcnQgZnVuY3Rpb24gZ2V0VGVtcGxhdGVDb250ZW50KGVsOiBOb2RlKTogTm9kZXxudWxsIHtcbiAgcmV0dXJuICdjb250ZW50JyBpbiAoZWwgYXMgYW55IC8qKiBNaWNyb3NvZnQvVHlwZVNjcmlwdCMyMTUxNyAqLykgJiYgaXNUZW1wbGF0ZUVsZW1lbnQoZWwpID9cbiAgICAgIGVsLmNvbnRlbnQgOlxuICAgICAgbnVsbDtcbn1cbmZ1bmN0aW9uIGlzVGVtcGxhdGVFbGVtZW50KGVsOiBOb2RlKTogZWwgaXMgSFRNTFRlbXBsYXRlRWxlbWVudCB7XG4gIHJldHVybiBlbC5ub2RlVHlwZSA9PT0gTm9kZS5FTEVNRU5UX05PREUgJiYgZWwubm9kZU5hbWUgPT09ICdURU1QTEFURSc7XG59XG4iXX0=