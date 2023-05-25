/*!
 Stencil Dev Server Client v2.22.3 | MIT Licensed | https://stenciljs.com
 */
var appErrorCss = "#dev-server-modal * { box-sizing: border-box !important; } #dev-server-modal { direction: ltr !important; display: block !important; position: absolute !important; top: 0 !important; right: 0 !important; bottom: 0 !important; left: 0 !important; z-index: 100000; margin: 0 !important; padding: 0 !important; font-family: -apple-system, 'Roboto', BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol' !important; font-size: 14px !important; line-height: 1.5 !important; -webkit-font-smoothing: antialiased; text-rendering: optimizeLegibility; text-size-adjust: none; word-wrap: break-word; color: #333 !important; background-color: white !important; box-sizing: border-box !important; overflow: hidden; user-select: auto; } #dev-server-modal-inner { position: relative !important; padding: 0 0 30px 0 !important; width: 100% !important; height: 100%; overflow-x: hidden; overflow-y: scroll; -webkit-overflow-scrolling: touch; } .dev-server-diagnostic { margin: 20px !important; border: 1px solid #ddd !important; border-radius: 3px !important; } .dev-server-diagnostic-masthead { padding: 8px 12px 12px 12px !important; } .dev-server-diagnostic-title { margin: 0 !important; font-weight: bold !important; color: #222 !important; } .dev-server-diagnostic-message { margin-top: 4px !important; color: #555 !important; } .dev-server-diagnostic-file { position: relative !important; border-top: 1px solid #ddd !important; } .dev-server-diagnostic-file-header { display: block !important; padding: 5px 10px !important; color: #555 !important; border-bottom: 1px solid #ddd !important; border-top-left-radius: 2px !important; border-top-right-radius: 2px !important; background-color: #f9f9f9 !important; font-family: Consolas, 'Liberation Mono', Menlo, Courier, monospace !important; font-size: 12px !important; } a.dev-server-diagnostic-file-header { color: #0000ee !important; text-decoration: underline !important; } a.dev-server-diagnostic-file-header:hover { text-decoration: none !important; background-color: #f4f4f4 !important; } .dev-server-diagnostic-file-name { font-weight: bold !important; } .dev-server-diagnostic-blob { overflow-x: auto !important; overflow-y: hidden !important; border-bottom-right-radius: 3px !important; border-bottom-left-radius: 3px !important; } .dev-server-diagnostic-table { margin: 0 !important; padding: 0 !important; border-spacing: 0 !important; border-collapse: collapse !important; border-width: 0 !important; border-style: none !important; -moz-tab-size: 2; tab-size: 2; } .dev-server-diagnostic-table td, .dev-server-diagnostic-table th { padding: 0 !important; border-width: 0 !important; border-style: none !important; } td.dev-server-diagnostic-blob-num { padding-right: 10px !important; padding-left: 10px !important; width: 1% !important; min-width: 50px !important; font-family: Consolas, 'Liberation Mono', Menlo, Courier, monospace !important; font-size: 12px !important; line-height: 20px !important; color: rgba(0, 0, 0, 0.3) !important; text-align: right !important; white-space: nowrap !important; vertical-align: top !important; -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; border: solid #eee !important; border-width: 0 1px 0 0 !important; } td.dev-server-diagnostic-blob-num::before { content: attr(data-line-number) !important; } .dev-server-diagnostic-error-line td.dev-server-diagnostic-blob-num { background-color: #ffdddd !important; border-color: #ffc9c9 !important; } .dev-server-diagnostic-error-line td.dev-server-diagnostic-blob-code { background: rgba(255, 221, 221, 0.25) !important; z-index: -1; } .dev-server-diagnostic-open-in-editor td.dev-server-diagnostic-blob-num:hover { cursor: pointer; background-color: #ffffe3 !important; font-weight: bold; } .dev-server-diagnostic-open-in-editor.dev-server-diagnostic-error-line td.dev-server-diagnostic-blob-num:hover { background-color: #ffdada !important; } td.dev-server-diagnostic-blob-code { position: relative !important; padding-right: 10px !important; padding-left: 10px !important; line-height: 20px !important; vertical-align: top !important; overflow: visible !important; font-family: Consolas, 'Liberation Mono', Menlo, Courier, monospace !important; font-size: 12px !important; color: #333 !important; word-wrap: normal !important; white-space: pre !important; } td.dev-server-diagnostic-blob-code::before { content: '' !important; } .dev-server-diagnostic-error-chr { position: relative !important; } .dev-server-diagnostic-error-chr::before { position: absolute !important; z-index: -1; top: -3px !important; left: 0px !important; width: 8px !important; height: 20px !important; background-color: #ffdddd !important; content: '' !important; } /** * GitHub Gist Theme * Author : Louis Barranqueiro - https://github.com/LouisBarranqueiro * https://highlightjs.org/ */ .hljs-comment, .hljs-meta { color: #969896; } .hljs-string, .hljs-variable, .hljs-template-variable, .hljs-strong, .hljs-emphasis, .hljs-quote { color: #df5000; } .hljs-keyword, .hljs-selector-tag, .hljs-type { color: #a71d5d; } .hljs-literal, .hljs-symbol, .hljs-bullet, .hljs-attribute { color: #0086b3; } .hljs-section, .hljs-name { color: #63a35c; } .hljs-tag { color: #333333; } .hljs-title, .hljs-attr, .hljs-selector-id, .hljs-selector-class, .hljs-selector-attr, .hljs-selector-pseudo { color: #795da3; } .hljs-addition { color: #55a532; background-color: #eaffea; } .hljs-deletion { color: #bd2c00; background-color: #ffecec; } .hljs-link { text-decoration: underline; }";

const appError = (data) => {
    const results = {
        diagnostics: [],
        status: null,
    };
    if (data && data.window && Array.isArray(data.buildResults.diagnostics)) {
        const diagnostics = data.buildResults.diagnostics.filter((diagnostic) => diagnostic.level === 'error');
        if (diagnostics.length > 0) {
            const modal = getDevServerModal(data.window.document);
            diagnostics.forEach((diagnostic) => {
                results.diagnostics.push(diagnostic);
                appendDiagnostic(data.window.document, data.openInEditor, modal, diagnostic);
            });
            results.status = 'error';
        }
    }
    return results;
};
const appendDiagnostic = (doc, openInEditor, modal, diagnostic) => {
    const card = doc.createElement('div');
    card.className = 'dev-server-diagnostic';
    const masthead = doc.createElement('div');
    masthead.className = 'dev-server-diagnostic-masthead';
    masthead.title = `${escapeHtml(diagnostic.type)} error: ${escapeHtml(diagnostic.code)}`;
    card.appendChild(masthead);
    const title = doc.createElement('div');
    title.className = 'dev-server-diagnostic-title';
    if (typeof diagnostic.header === 'string' && diagnostic.header.trim().length > 0) {
        title.textContent = diagnostic.header;
    }
    else {
        title.textContent = `${titleCase(diagnostic.type)} ${titleCase(diagnostic.level)}`;
    }
    masthead.appendChild(title);
    const message = doc.createElement('div');
    message.className = 'dev-server-diagnostic-message';
    message.textContent = diagnostic.messageText;
    masthead.appendChild(message);
    const file = doc.createElement('div');
    file.className = 'dev-server-diagnostic-file';
    card.appendChild(file);
    const isUrl = typeof diagnostic.absFilePath === 'string' && diagnostic.absFilePath.indexOf('http') === 0;
    const canOpenInEditor = typeof openInEditor === 'function' && typeof diagnostic.absFilePath === 'string' && !isUrl;
    if (isUrl) {
        const fileHeader = doc.createElement('a');
        fileHeader.href = diagnostic.absFilePath;
        fileHeader.setAttribute('target', '_blank');
        fileHeader.setAttribute('rel', 'noopener noreferrer');
        fileHeader.className = 'dev-server-diagnostic-file-header';
        const filePath = doc.createElement('span');
        filePath.className = 'dev-server-diagnostic-file-path';
        filePath.textContent = diagnostic.absFilePath;
        fileHeader.appendChild(filePath);
        file.appendChild(fileHeader);
    }
    else if (diagnostic.relFilePath) {
        const fileHeader = doc.createElement(canOpenInEditor ? 'a' : 'div');
        fileHeader.className = 'dev-server-diagnostic-file-header';
        if (diagnostic.absFilePath) {
            fileHeader.title = escapeHtml(diagnostic.absFilePath);
            if (canOpenInEditor) {
                addOpenInEditor(openInEditor, fileHeader, diagnostic.absFilePath, diagnostic.lineNumber, diagnostic.columnNumber);
            }
        }
        const parts = diagnostic.relFilePath.split('/');
        const fileName = doc.createElement('span');
        fileName.className = 'dev-server-diagnostic-file-name';
        fileName.textContent = parts.pop();
        const filePath = doc.createElement('span');
        filePath.className = 'dev-server-diagnostic-file-path';
        filePath.textContent = parts.join('/') + '/';
        fileHeader.appendChild(filePath);
        fileHeader.appendChild(fileName);
        file.appendChild(fileHeader);
    }
    if (diagnostic.lines && diagnostic.lines.length > 0) {
        const blob = doc.createElement('div');
        blob.className = 'dev-server-diagnostic-blob';
        file.appendChild(blob);
        const table = doc.createElement('table');
        table.className = 'dev-server-diagnostic-table';
        blob.appendChild(table);
        prepareLines(diagnostic.lines).forEach((l) => {
            const tr = doc.createElement('tr');
            if (l.errorCharStart > 0) {
                tr.classList.add('dev-server-diagnostic-error-line');
            }
            if (canOpenInEditor) {
                tr.classList.add('dev-server-diagnostic-open-in-editor');
            }
            table.appendChild(tr);
            const tdNum = doc.createElement('td');
            tdNum.className = 'dev-server-diagnostic-blob-num';
            if (l.lineNumber > 0) {
                tdNum.setAttribute('data-line-number', l.lineNumber + '');
                tdNum.title = escapeHtml(diagnostic.relFilePath) + ', line ' + l.lineNumber;
                if (canOpenInEditor) {
                    const column = l.lineNumber === diagnostic.lineNumber ? diagnostic.columnNumber : 1;
                    addOpenInEditor(openInEditor, tdNum, diagnostic.absFilePath, l.lineNumber, column);
                }
            }
            tr.appendChild(tdNum);
            const tdCode = doc.createElement('td');
            tdCode.className = 'dev-server-diagnostic-blob-code';
            tdCode.innerHTML = highlightError(l.text, l.errorCharStart, l.errorLength);
            tr.appendChild(tdCode);
        });
    }
    modal.appendChild(card);
};
const addOpenInEditor = (openInEditor, elm, file, line, column) => {
    if (elm.tagName === 'A') {
        elm.href = '#open-in-editor';
    }
    if (typeof line !== 'number' || line < 1) {
        line = 1;
    }
    if (typeof column !== 'number' || column < 1) {
        column = 1;
    }
    elm.addEventListener('click', (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        openInEditor({
            file: file,
            line: line,
            column: column,
        });
    });
};
const getDevServerModal = (doc) => {
    let outer = doc.getElementById(DEV_SERVER_MODAL);
    if (!outer) {
        outer = doc.createElement('div');
        outer.id = DEV_SERVER_MODAL;
        outer.setAttribute('role', 'dialog');
        doc.body.appendChild(outer);
    }
    outer.innerHTML = `<style>${appErrorCss}</style><div id="${DEV_SERVER_MODAL}-inner"></div>`;
    return doc.getElementById(`${DEV_SERVER_MODAL}-inner`);
};
const clearAppErrorModal = (data) => {
    const appErrorElm = data.window.document.getElementById(DEV_SERVER_MODAL);
    if (appErrorElm) {
        appErrorElm.parentNode.removeChild(appErrorElm);
    }
};
const escapeHtml = (unsafe) => {
    if (typeof unsafe === 'number' || typeof unsafe === 'boolean') {
        return unsafe.toString();
    }
    if (typeof unsafe === 'string') {
        return unsafe
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }
    return '';
};
const titleCase = (str) => str.charAt(0).toUpperCase() + str.slice(1);
const highlightError = (text, errorCharStart, errorLength) => {
    if (typeof text !== 'string') {
        return '';
    }
    const errorCharEnd = errorCharStart + errorLength;
    return text
        .split('')
        .map((inputChar, charIndex) => {
        let outputChar;
        if (inputChar === `<`) {
            outputChar = `&lt;`;
        }
        else if (inputChar === `>`) {
            outputChar = `&gt;`;
        }
        else if (inputChar === `"`) {
            outputChar = `&quot;`;
        }
        else if (inputChar === `'`) {
            outputChar = `&#039;`;
        }
        else if (inputChar === `&`) {
            outputChar = `&amp;`;
        }
        else {
            outputChar = inputChar;
        }
        if (charIndex >= errorCharStart && charIndex < errorCharEnd) {
            outputChar = `<span class="dev-server-diagnostic-error-chr">${outputChar}</span>`;
        }
        return outputChar;
    })
        .join('');
};
const prepareLines = (orgLines) => {
    const lines = JSON.parse(JSON.stringify(orgLines));
    for (let i = 0; i < 100; i++) {
        if (!eachLineHasLeadingWhitespace(lines)) {
            return lines;
        }
        for (let i = 0; i < lines.length; i++) {
            lines[i].text = lines[i].text.slice(1);
            lines[i].errorCharStart--;
            if (!lines[i].text.length) {
                return lines;
            }
        }
    }
    return lines;
};
const eachLineHasLeadingWhitespace = (lines) => {
    if (!lines.length) {
        return false;
    }
    for (let i = 0; i < lines.length; i++) {
        if (!lines[i].text || lines[i].text.length < 1) {
            return false;
        }
        const firstChar = lines[i].text.charAt(0);
        if (firstChar !== ' ' && firstChar !== '\t') {
            return false;
        }
    }
    return true;
};
const DEV_SERVER_MODAL = `dev-server-modal`;

const emitBuildLog = (win, buildLog) => {
    win.dispatchEvent(new CustomEvent(BUILD_LOG, { detail: buildLog }));
};
const emitBuildResults = (win, buildResults) => {
    win.dispatchEvent(new CustomEvent(BUILD_RESULTS, { detail: buildResults }));
};
const emitBuildStatus = (win, buildStatus) => {
    win.dispatchEvent(new CustomEvent(BUILD_STATUS, { detail: buildStatus }));
};
const onBuildLog = (win, cb) => {
    win.addEventListener(BUILD_LOG, (ev) => {
        cb(ev.detail);
    });
};
const onBuildResults = (win, cb) => {
    win.addEventListener(BUILD_RESULTS, (ev) => {
        cb(ev.detail);
    });
};
const onBuildStatus = (win, cb) => {
    win.addEventListener(BUILD_STATUS, (ev) => {
        cb(ev.detail);
    });
};
const BUILD_LOG = `devserver:buildlog`;
const BUILD_RESULTS = `devserver:buildresults`;
const BUILD_STATUS = `devserver:buildstatus`;

const getHmrHref = (versionId, fileName, testUrl) => {
    if (typeof testUrl === 'string' && testUrl.trim() !== '') {
        if (getUrlFileName(fileName) === getUrlFileName(testUrl)) {
            // only compare by filename w/out querystrings, not full path
            return setHmrQueryString(testUrl, versionId);
        }
    }
    return testUrl;
};
const getUrlFileName = (url) => {
    // not using URL because IE11 doesn't support it
    const splt = url.split('/');
    return splt[splt.length - 1].split('&')[0].split('?')[0];
};
const parseQuerystring = (oldQs) => {
    const newQs = {};
    if (typeof oldQs === 'string') {
        oldQs.split('&').forEach((kv) => {
            const splt = kv.split('=');
            newQs[splt[0]] = splt[1] ? splt[1] : '';
        });
    }
    return newQs;
};
const stringifyQuerystring = (qs) => Object.keys(qs)
    .map((key) => key + '=' + qs[key])
    .join('&');
const setQueryString = (url, qsKey, qsValue) => {
    // not using URL because IE11 doesn't support it
    const urlSplt = url.split('?');
    const urlPath = urlSplt[0];
    const qs = parseQuerystring(urlSplt[1]);
    qs[qsKey] = qsValue;
    return urlPath + '?' + stringifyQuerystring(qs);
};
const setHmrQueryString = (url, versionId) => setQueryString(url, 's-hmr', versionId);
const updateCssUrlValue = (versionId, fileName, oldCss) => {
    const reg = /url\((['"]?)(.*)\1\)/gi;
    let result;
    let newCss = oldCss;
    while ((result = reg.exec(oldCss)) !== null) {
        const url = result[2];
        newCss = newCss.replace(url, getHmrHref(versionId, fileName, url));
    }
    return newCss;
};
const isLinkStylesheet = (elm) => elm.nodeName.toLowerCase() === 'link' &&
    elm.href &&
    elm.rel &&
    elm.rel.toLowerCase() === 'stylesheet';
const isTemplate = (elm) => elm.nodeName.toLowerCase() === 'template' &&
    !!elm.content &&
    elm.content.nodeType === 11;
const setHmrAttr = (elm, versionId) => elm.setAttribute('data-hmr', versionId);
const hasShadowRoot = (elm) => !!elm.shadowRoot && elm.shadowRoot.nodeType === 11 && elm.shadowRoot !== elm;
const isElement = (elm) => !!elm && elm.nodeType === 1 && !!elm.getAttribute;

const hmrComponents = (elm, versionId, hmrTagNames) => {
    const updatedTags = [];
    hmrTagNames.forEach((hmrTagName) => {
        hmrComponent(updatedTags, elm, versionId, hmrTagName);
    });
    return updatedTags.sort();
};
const hmrComponent = (updatedTags, elm, versionId, cmpTagName) => {
    // drill down through every node in the page
    // to include shadow roots and look for this
    // component tag to run hmr() on
    if (elm.nodeName.toLowerCase() === cmpTagName && typeof elm['s-hmr'] === 'function') {
        elm['s-hmr'](versionId);
        setHmrAttr(elm, versionId);
        if (updatedTags.indexOf(cmpTagName) === -1) {
            updatedTags.push(cmpTagName);
        }
    }
    if (hasShadowRoot(elm)) {
        hmrComponent(updatedTags, elm.shadowRoot, versionId, cmpTagName);
    }
    if (elm.children) {
        for (let i = 0; i < elm.children.length; i++) {
            hmrComponent(updatedTags, elm.children[i], versionId, cmpTagName);
        }
    }
};

const hmrExternalStyles = (elm, versionId, cssFileNames) => {
    if (isLinkStylesheet(elm)) {
        cssFileNames.forEach((cssFileName) => {
            hmrStylesheetLink(elm, versionId, cssFileName);
        });
    }
    if (isTemplate(elm)) {
        hmrExternalStyles(elm.content, versionId, cssFileNames);
    }
    if (hasShadowRoot(elm)) {
        hmrExternalStyles(elm.shadowRoot, versionId, cssFileNames);
    }
    if (elm.children) {
        for (let i = 0; i < elm.children.length; i++) {
            hmrExternalStyles(elm.children[i], versionId, cssFileNames);
        }
    }
    return cssFileNames.sort();
};
const hmrStylesheetLink = (styleSheetElm, versionId, cssFileName) => {
    const orgHref = styleSheetElm.getAttribute('href');
    const newHref = getHmrHref(versionId, cssFileName, styleSheetElm.href);
    if (newHref !== orgHref) {
        styleSheetElm.setAttribute('href', newHref);
        setHmrAttr(styleSheetElm, versionId);
    }
};

const hmrImages = (win, doc, versionId, imageFileNames) => {
    if (win.location.protocol !== 'file:' && doc.styleSheets) {
        hmrStyleSheetsImages(doc, versionId, imageFileNames);
    }
    hmrImagesElements(win, doc.documentElement, versionId, imageFileNames);
    return imageFileNames.sort();
};
const hmrStyleSheetsImages = (doc, versionId, imageFileNames) => {
    const cssImageProps = Object.keys(doc.documentElement.style).filter((cssProp) => {
        return cssProp.endsWith('Image');
    });
    for (let i = 0; i < doc.styleSheets.length; i++) {
        hmrStyleSheetImages(cssImageProps, doc.styleSheets[i], versionId, imageFileNames);
    }
};
const hmrStyleSheetImages = (cssImageProps, styleSheet, versionId, imageFileNames) => {
    try {
        const cssRules = styleSheet.cssRules;
        for (let i = 0; i < cssRules.length; i++) {
            const cssRule = cssRules[i];
            switch (cssRule.type) {
                case CSSRule.IMPORT_RULE:
                    hmrStyleSheetImages(cssImageProps, cssRule.styleSheet, versionId, imageFileNames);
                    break;
                case CSSRule.STYLE_RULE:
                    hmrStyleSheetRuleImages(cssImageProps, cssRule, versionId, imageFileNames);
                    break;
                case CSSRule.MEDIA_RULE:
                    hmrStyleSheetImages(cssImageProps, cssRule, versionId, imageFileNames);
                    break;
            }
        }
    }
    catch (e) {
        console.error('hmrStyleSheetImages: ' + e);
    }
};
const hmrStyleSheetRuleImages = (cssImageProps, cssRule, versionId, imageFileNames) => {
    cssImageProps.forEach((cssImageProp) => {
        imageFileNames.forEach((imageFileName) => {
            const oldCssText = cssRule.style[cssImageProp];
            const newCssText = updateCssUrlValue(versionId, imageFileName, oldCssText);
            if (oldCssText !== newCssText) {
                cssRule.style[cssImageProp] = newCssText;
            }
        });
    });
};
const hmrImagesElements = (win, elm, versionId, imageFileNames) => {
    const tagName = elm.nodeName.toLowerCase();
    if (tagName === 'img') {
        hmrImgElement(elm, versionId, imageFileNames);
    }
    if (isElement(elm)) {
        const styleAttr = elm.getAttribute('style');
        if (styleAttr) {
            hmrUpdateStyleAttr(elm, versionId, imageFileNames, styleAttr);
        }
    }
    if (tagName === 'style') {
        hmrUpdateStyleElementUrl(elm, versionId, imageFileNames);
    }
    if (win.location.protocol !== 'file:' && isLinkStylesheet(elm)) {
        hmrUpdateLinkElementUrl(elm, versionId, imageFileNames);
    }
    if (isTemplate(elm)) {
        hmrImagesElements(win, elm.content, versionId, imageFileNames);
    }
    if (hasShadowRoot(elm)) {
        hmrImagesElements(win, elm.shadowRoot, versionId, imageFileNames);
    }
    if (elm.children) {
        for (let i = 0; i < elm.children.length; i++) {
            hmrImagesElements(win, elm.children[i], versionId, imageFileNames);
        }
    }
};
const hmrImgElement = (imgElm, versionId, imageFileNames) => {
    imageFileNames.forEach((imageFileName) => {
        const orgSrc = imgElm.getAttribute('src');
        const newSrc = getHmrHref(versionId, imageFileName, orgSrc);
        if (newSrc !== orgSrc) {
            imgElm.setAttribute('src', newSrc);
            setHmrAttr(imgElm, versionId);
        }
    });
};
const hmrUpdateStyleAttr = (elm, versionId, imageFileNames, oldStyleAttr) => {
    imageFileNames.forEach((imageFileName) => {
        const newStyleAttr = updateCssUrlValue(versionId, imageFileName, oldStyleAttr);
        if (newStyleAttr !== oldStyleAttr) {
            elm.setAttribute('style', newStyleAttr);
            setHmrAttr(elm, versionId);
        }
    });
};
const hmrUpdateStyleElementUrl = (styleElm, versionId, imageFileNames) => {
    imageFileNames.forEach((imageFileName) => {
        const oldCssText = styleElm.innerHTML;
        const newCssText = updateCssUrlValue(versionId, imageFileName, oldCssText);
        if (newCssText !== oldCssText) {
            styleElm.innerHTML = newCssText;
            setHmrAttr(styleElm, versionId);
        }
    });
};
const hmrUpdateLinkElementUrl = (linkElm, versionId, imageFileNames) => {
    linkElm.href = setQueryString(linkElm.href, 's-hmr-urls', imageFileNames.sort().join(','));
    linkElm.href = setHmrQueryString(linkElm.href, versionId);
    linkElm.setAttribute('data-hmr', versionId);
};

const hmrInlineStyles = (elm, versionId, stylesUpdatedData) => {
    const stylesUpdated = stylesUpdatedData;
    if (isElement(elm) && elm.nodeName.toLowerCase() === 'style') {
        stylesUpdated.forEach((styleUpdated) => {
            hmrStyleElement(elm, versionId, styleUpdated);
        });
    }
    if (isTemplate(elm)) {
        hmrInlineStyles(elm.content, versionId, stylesUpdated);
    }
    if (hasShadowRoot(elm)) {
        hmrInlineStyles(elm.shadowRoot, versionId, stylesUpdated);
    }
    if (elm.children) {
        for (let i = 0; i < elm.children.length; i++) {
            hmrInlineStyles(elm.children[i], versionId, stylesUpdated);
        }
    }
    return stylesUpdated
        .map((s) => s.styleTag)
        .reduce((arr, v) => {
        if (arr.indexOf(v) === -1) {
            arr.push(v);
        }
        return arr;
    }, [])
        .sort();
};
const hmrStyleElement = (elm, versionId, stylesUpdated) => {
    const styleId = elm.getAttribute('sty-id');
    if (styleId === stylesUpdated.styleId && stylesUpdated.styleText) {
        // if we made it this far then it's a match!
        // update the new style text
        elm.innerHTML = stylesUpdated.styleText.replace(/\\n/g, '\n');
        elm.setAttribute('data-hmr', versionId);
    }
};

const hmrWindow = (data) => {
    const results = {
        updatedComponents: [],
        updatedExternalStyles: [],
        updatedInlineStyles: [],
        updatedImages: [],
        versionId: '',
    };
    try {
        if (!data ||
            !data.window ||
            !data.window.document.documentElement ||
            !data.hmr ||
            typeof data.hmr.versionId !== 'string') {
            return results;
        }
        const win = data.window;
        const doc = win.document;
        const hmr = data.hmr;
        const documentElement = doc.documentElement;
        const versionId = hmr.versionId;
        results.versionId = versionId;
        if (hmr.componentsUpdated) {
            results.updatedComponents = hmrComponents(documentElement, versionId, hmr.componentsUpdated);
        }
        if (hmr.inlineStylesUpdated) {
            results.updatedInlineStyles = hmrInlineStyles(documentElement, versionId, hmr.inlineStylesUpdated);
        }
        if (hmr.externalStylesUpdated) {
            results.updatedExternalStyles = hmrExternalStyles(documentElement, versionId, hmr.externalStylesUpdated);
        }
        if (hmr.imagesUpdated) {
            results.updatedImages = hmrImages(win, doc, versionId, hmr.imagesUpdated);
        }
        setHmrAttr(documentElement, versionId);
    }
    catch (e) {
        console.error(e);
    }
    return results;
};

const logBuild = (msg) => log(BLUE, 'Build', msg);
const logReload = (msg) => logWarn('Reload', msg);
const logWarn = (prefix, msg) => log(YELLOW, prefix, msg);
const logDisabled = (prefix, msg) => log(GRAY, prefix, msg);
const logDiagnostic = (diag) => {
    const diagnostic = diag;
    let color = RED;
    let prefix = 'Error';
    if (diagnostic.level === 'warn') {
        color = YELLOW;
        prefix = 'Warning';
    }
    if (diagnostic.header) {
        prefix = diagnostic.header;
    }
    let msg = ``;
    if (diagnostic.relFilePath) {
        msg += diagnostic.relFilePath;
        if (typeof diagnostic.lineNumber === 'number' && diagnostic.lineNumber > 0) {
            msg += ', line ' + diagnostic.lineNumber;
            if (typeof diagnostic.columnNumber === 'number' && diagnostic.columnNumber > 0) {
                msg += ', column ' + diagnostic.columnNumber;
            }
        }
        msg += `\n`;
    }
    msg += diagnostic.messageText;
    log(color, prefix, msg);
};
const log = (color, prefix, msg) => {
    if (typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.indexOf('Trident') > -1) {
        console.log(prefix, msg);
    }
    else {
        console.log.apply(console, [
            '%c' + prefix,
            `background: ${color}; color: white; padding: 2px 3px; border-radius: 2px; font-size: 0.8em;`,
            msg,
        ]);
    }
};
const YELLOW = `#f39c12`;
const RED = `#c0392b`;
const BLUE = `#3498db`;
const GRAY = `#717171`;

const initBuildProgress = (data) => {
    const win = data.window;
    const doc = win.document;
    const barColor = `#5851ff`;
    const errorColor = `#b70c19`;
    let addBarTimerId;
    let removeBarTimerId;
    let opacityTimerId;
    let incIntervalId;
    let progressIncrease;
    let currentProgress = 0;
    function update() {
        clearTimeout(opacityTimerId);
        clearTimeout(removeBarTimerId);
        const progressBar = getProgressBar();
        if (!progressBar) {
            createProgressBar();
            addBarTimerId = setTimeout(update, 16);
            return;
        }
        progressBar.style.background = barColor;
        progressBar.style.opacity = `1`;
        progressBar.style.transform = `scaleX(${Math.min(1, displayProgress())})`;
        if (incIntervalId == null) {
            incIntervalId = setInterval(() => {
                progressIncrease += Math.random() * 0.05 + 0.01;
                if (displayProgress() < 0.9) {
                    update();
                }
                else {
                    clearInterval(incIntervalId);
                }
            }, 800);
        }
    }
    function reset() {
        clearInterval(incIntervalId);
        progressIncrease = 0.05;
        incIntervalId = null;
        clearTimeout(opacityTimerId);
        clearTimeout(addBarTimerId);
        clearTimeout(removeBarTimerId);
        const progressBar = getProgressBar();
        if (progressBar) {
            if (currentProgress >= 1) {
                progressBar.style.transform = `scaleX(1)`;
            }
            opacityTimerId = setTimeout(() => {
                try {
                    const progressBar = getProgressBar();
                    if (progressBar) {
                        progressBar.style.opacity = `0`;
                    }
                }
                catch (e) { }
            }, 150);
            removeBarTimerId = setTimeout(() => {
                try {
                    const progressBar = getProgressBar();
                    if (progressBar) {
                        progressBar.parentNode.removeChild(progressBar);
                    }
                }
                catch (e) { }
            }, 1000);
        }
    }
    function displayProgress() {
        const p = currentProgress + progressIncrease;
        return Math.max(0, Math.min(1, p));
    }
    reset();
    onBuildLog(win, (buildLog) => {
        currentProgress = buildLog.progress;
        if (currentProgress >= 0 && currentProgress < 1) {
            update();
        }
        else {
            reset();
        }
    });
    onBuildResults(win, (buildResults) => {
        if (buildResults.hasError) {
            const progressBar = getProgressBar();
            if (progressBar) {
                progressBar.style.transform = `scaleX(1)`;
                progressBar.style.background = errorColor;
            }
        }
        reset();
    });
    onBuildStatus(win, (buildStatus) => {
        if (buildStatus === 'disabled') {
            reset();
        }
    });
    if (doc.head.dataset.tmpl === 'tmpl-initial-load') {
        update();
    }
    const PROGRESS_BAR_ID = `dev-server-progress-bar`;
    function getProgressBar() {
        return doc.getElementById(PROGRESS_BAR_ID);
    }
    function createProgressBar() {
        const progressBar = doc.createElement('div');
        progressBar.id = PROGRESS_BAR_ID;
        progressBar.style.position = `absolute`;
        progressBar.style.top = `0`;
        progressBar.style.left = `0`;
        progressBar.style.zIndex = `100001`;
        progressBar.style.width = `100%`;
        progressBar.style.height = `2px`;
        progressBar.style.transform = `scaleX(0)`;
        progressBar.style.opacity = `1`;
        progressBar.style.background = barColor;
        progressBar.style.transformOrigin = `left center`;
        progressBar.style.transition = `transform .1s ease-in-out, opacity .5s ease-in`;
        progressBar.style.contain = `strict`;
        doc.body.appendChild(progressBar);
    }
};

const initBuildStatus = (data) => {
    const win = data.window;
    const doc = win.document;
    const iconElms = getFavIcons(doc);
    iconElms.forEach((iconElm) => {
        if (iconElm.href) {
            iconElm.dataset.href = iconElm.href;
            iconElm.dataset.type = iconElm.type;
        }
    });
    onBuildStatus(win, (buildStatus) => {
        updateBuildStatus(doc, buildStatus);
    });
};
const updateBuildStatus = (doc, status) => {
    const iconElms = getFavIcons(doc);
    iconElms.forEach((iconElm) => {
        updateFavIcon(iconElm, status);
    });
};
const updateFavIcon = (linkElm, status) => {
    if (status === 'pending') {
        linkElm.href = ICON_PENDING;
        linkElm.type = ICON_TYPE;
        linkElm.setAttribute('data-status', status);
    }
    else if (status === 'error') {
        linkElm.href = ICON_ERROR;
        linkElm.type = ICON_TYPE;
        linkElm.setAttribute('data-status', status);
    }
    else if (status === 'disabled') {
        linkElm.href = ICON_DISABLED;
        linkElm.type = ICON_TYPE;
        linkElm.setAttribute('data-status', status);
    }
    else {
        linkElm.removeAttribute('data-status');
        if (linkElm.dataset.href) {
            linkElm.href = linkElm.dataset.href;
            linkElm.type = linkElm.dataset.type;
        }
        else {
            linkElm.href = ICON_DEFAULT;
            linkElm.type = ICON_TYPE;
        }
    }
};
const getFavIcons = (doc) => {
    const iconElms = [];
    const linkElms = doc.querySelectorAll('link');
    for (let i = 0; i < linkElms.length; i++) {
        if (linkElms[i].href &&
            linkElms[i].rel &&
            (linkElms[i].rel.indexOf('shortcut') > -1 || linkElms[i].rel.indexOf('icon') > -1)) {
            iconElms.push(linkElms[i]);
        }
    }
    if (iconElms.length === 0) {
        const linkElm = doc.createElement('link');
        linkElm.rel = 'shortcut icon';
        doc.head.appendChild(linkElm);
        iconElms.push(linkElm);
    }
    return iconElms;
};
const ICON_DEFAULT = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw1AAAAnFBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD4jUzeAAAAM3RSTlMAsGDs4wML8QEbBvr2FMhAM7+ILCUPnNzXrX04otO6j3RiT0ggzLSTcmtWUUWoZlknghZc2mZzAAACrklEQVR42u3dWXLiUAyFYWEwg40x8wxhSIAwJtH+99ZVeeinfriXVpWk5Hyr+C2VrgkAAAAAAAAAAAw5sZQ7aUhYypw07FjKC2ko2yxk2SQFgwYLOWSkYFhlIZ06KWhNWMhqRApGKxYyaZGCeoeFVIekIDuwkEaXFDSXLKRdkoYjS9mRhjlLSUjDO0s5kYYzS+mThn3OQsYqAbQQC7hZSgoGYgHUy0jBa42FvKkEUDERC6CCFIzeWEjtlRRkPbGAG5CCtCIWQAtS0ByzkHxPGvos5UEaNizlnTRsWconhbM4wTpSFHMTrFtKCroNFrLGBOsJLbGAWxWkoFiJBRAmWE/I1r4nWOmNheTeJ1gX0vDJUrYUweAEa04aHs5XePvc9wpPboJ1SCmOsRVkr04aromUEQEAgB9lxaZ++ATFpNDv6Y8qm1QdBk9QTAr9ni6mbFK7DJ6g2LQLXoHZlFCQdMY2nYJXYDb1g1dgNo2boSswm2Zp6ArMptCFyIVtCl2IlDmbNC0QcPEQcD8l4HLvAXdxHnBb5wG3QcDFQ8D9mIDrIeCiIeDiA25oNeA+EHDREHDxAbdmmxBwT0HARQbciW0KDbiEbQoNuB3bFBxwbTYJAfcUBFxkwFG/YlNJAADgxzCRcqUY9m7KGgNSUEx9H3XXO76Puv/OY5wedX/flHk+6j46v2maO79purPvm6Yz+75puua+b5q6Dd/PEsrNMyZfFM5gAMW+ymPtWciYV3ksBpBOwKUH3wHXXLKUM2l4cR5wG+cBlzgPuJ3zgJNb6FRwlP4Ln1X8wrOKeFbxP6Qz3wEn+KzilWLYe5UnMuDwY5BvD+cBt899B9zC+49Bqr4DrlXzHXDF1HfA1Tu+Ay5b+w649OY74OjoO+Bo7jzg7s4DDgAAAAAAAAAA/u0POrfnVIaqz/QAAAAASUVORK5CYII=';
const ICON_PENDING = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw1AAAAjVBMVEUAAAD8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjL8kjLn7xn3AAAALnRSTlMAsFBgAaDxfPpAdTMcD/fs47kDBhVXJQpvLNbInIiBRvSqIb+TZ2OOONxdzUxpgKSpAAAAA69JREFUeNrt3FtvskAQxvERFQXFioqnCkqth572+3+8947dN00TliF5ZpP53ZOAveg/OzCklFJKKaWUUkoppQTZm77cCGFo+jIhhG/TlwchJAvTk/GIAA6x6Um+JoDti+nJ644A5h+mJ8eMALKj6cnHnAB2r80NLJ4jf3Vz+cuWANZ5cwPTM/l7by6PZwQwGptGQf4q++dLCOHdNIbkb2IvjwjAvYEf8pe6j4/wYxopr/9SQih4BXa3l5eEcJ7a++c9/gkSQE8bcCWvXwcrAjjYADrxHv8KCbi3JasgD5fm8i9IAG1swMXzDv0X2wDaEED21dzA5UDeVoPm8uUbAayvvAI42YA7EIDzA5pv8lc6/UoAoxMv4CZuvyKUpnHn9VNBAG6B7XkBtCeEO6/AbvbyihAiXsB92svfCcA9wap4j19DAmgWs37AZCrnBKvu8vgX9AmWE3BZh/6L7QkWJIA2RxtwHQpml9sAQp9gXWbkbxz4CdYDfIK1qk1j3IV9fPgJFlNECJXhYfSfsBHkhBCKwEd452nYI7wncwQJP8GKTU+uO0I4D/uSkVJKqXAkA5nK9icoIi3nrU9QRHrZtj5BESmetT5BEantPCh7NTJFrUdgMg1bj8BkSv1HYJ8RmjMQKf1HYDdC+/R/IyQFzbD4AxH+CIyPPxCJoEdQ/IFIMgXNEPkDkd8jMLQs5wRcTXA1J+By/BGO+0ovYwQGU3kPRLJfIzCkCSfgpgmhpc5AxD/gIkLb8wKO0DTgoNyaGQQecNfQAy7TgGtHA04DLtyA24UecHngAVdrwIkJuAitU8DJ1Dbghkam9gEnU+uAWxiRjhsdoXagI1TPgKNyIBO+ZpRSSrW3HfblTAA9/juPDwTAfiMK9VG3PY/hwX7Ubc9j+AoCWNWGp+NSH4HflE2IgXUEGPI3TTfmN4ndv2kSsRUJvpUn4W1FShbYb5rc84ySAtzKs3W3IgW4lWfO24q0zsFbebIjaysSjbtt5RHzUf0DHHCrAW8gVYEDzl0LGYW4lefB24uYQgOOfwN7dMANeW/k3DkBJ2CrUNE54GRsFYIHnPNR+iPEgHPWKo5DDDhnrWKeBRhwzlrFeNtlq5CgtYqzAAPODaBzgAH331rFAAOOqsDXKjL3IqboN7ILJ4BCDDh3r3SIAfd0AijEgHP3So/8wQNuvjRBbxVij5A6Bpy8EZJnwIkbIfkFnLwRkm/ASRshXbwDTtYICRRwt7BHqEoppZRSSimllFLqD/8AOXJZHefotiIAAAAASUVORK5CYII=';
const ICON_ERROR = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw1AAAAkFBMVEUAAAD5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0H5Q0HYvLBZAAAAL3RSTlMAsGDjA/rsC/ElHRUBBssz9pFCvoh0UEcsD9ec3K19OLiiaNLEYlmoVeiCbmE+GuMl4I8AAAKQSURBVHja7d1njupQDIZhAymEUIZQQu9taN7/7q50pfl/TmTJtvQ9q3hzLDsEAAAAAAAAAACGzFjKiTS0WcqONMxZypg0fH5YyLFPChZdFnIYkILil4VcclLw3bCQ85IULM8sZPMlBfmFhfwWpGBwYCHdESnoH1nIz4c0jFnKnDTsWEqbNJxYyow03FjKlDTUKQtZqwTQXizgtgkpWGQsZKIScL0OCxmqBFC5EQugkhQshyyk0yMFgwkLyRakIGmJBdCeFPTXLCStScOUpdwogsEXrBdpuLKUJ4XDC9afKmUh94QUjLy/YGViAZRTOIMBtypJQXn2HUC5WMBleMFqILmzkLSicBZfsB6k4clSrqTh5XyEd3MeQHXqe4Qn94LVSiicwRHkJScNdVvKkgAAwI+qZdM0/AXFpE4v+AXFpKwIfkExKfR7ulyxSWkV/IJi0zx4BGbTm4IkW7ZpFjwCs2kaPAKzad0PHYHZtE1CR2A2TQahIzCbhnnwCMykVYmAi4aAQ8BZ4T3grgi4BhBwCDgbEHCNIOAQcCYg4BpCwCHgLEDAaYgPuDfbhIBrBAGHgDMhNOBo2rKpIgAA8KNoS6kplq2dsu6CFJQr30vd+dD3Uvf/nTLHS93J3flZwrHznaad852mE/veaXqw752mKvW90zTq+j5LWGS+r/J8xQKoU1AUa2chm1zlsXQWUifgkoPvgOsffQccjZ0H3Mx5wL2dB9zcecB9sJTePOBM3cU+46wiziq6C7hk6zvg3J9VfDK7vir0ch5wN+cBV6e+A27v/ccgme+AkxshTXKKYW6EFH0X29gIKTLgzI2QYgPO2ggpLuDsvaDEBZy9EVJcwBkcIT0IAAAAAAAAAADs+AdjeyF69/r87QAAAABJRU5ErkJggg==';
const ICON_DISABLED = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw1AAAAeFBMVEUAAAC4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7+4t7/uGGySAAAAJ3RSTlMAsGAE7OMcAQvxJRX69kHWyL8zq5GIdEcsD5zcfVg4uKLNa1JPZoK/xdPIAAACiklEQVR42u3dW5KqUAyF4QgCCggqIt7t9pb5z/Ccvjz2w95UqpJ0r28Uf2WTQAAAAAAAAAAAYMiWpTxJQ8JSTqThwVI2pKFZsJC3ghTs5izkmpKCcspCljNSkB9ZSLsnBfuWhRxzUjBbspBpSQrSKwuZr0lB8cZCFg1p2LCUB2k4sZSENNxYypY0nFlKTxqGmoUcClJwEQu4SUoKdmIBtEpJQZ6xkHeVAKqOYgFUkYL9OwvJclKQrsQCbkcK0olYAF1IQXFgIfVAGnqWcqZwFidYN4phb4L1onCYYMlPsLqUFKwxwRozwTIYcG1FCqrWdwBhgqU7wUo7FlJ7n2DdScPL+RPezfkT3tl5AA217yc89xMssYBbzUjDkEjZEwAA+NFMbOrDJygmZXnwBMWkaRk8QTFpvg6eoJi0aIInKDY9gp/AbEqCJyg2bYOfwGzqKUzPNh2K0Ccwm0IfRBK2KfSLkDvbFPog0tRsUlsh4EZAwP2SgKu9B9wdATcOAg4BZwACbgQEHALOCATcCAg4BJwVCLhREHB/LOAebFNwwC3YJATcKAi4yICjfmJTQwAA4EeZSBkojrWdsvmO4hjbKYtd6ra2Uxa71G1tp0xnqbvo+IPfpe4Nf3K703Ridr3T9OQPfnea7szseaepqX3vNH3NM/xe5fmeZ7i9yiMXQFlJEeydhYy4ymMygCICzmQAxQactbOQMQFnMoBiAs7iVaHIgDN3VSgq4AxeFYoOOGNXhbCUPkaJs4o4q/iXzyp2vgPO/VnFl/OAu/F/jq8KnZ0H3FD7DriL9x+DTH0HXJ75Driq9R1ws6XvgEuvvgOu6HwHHG18BxydnAfc03nAAQAAAAAAAADAz/4BoL2Us9XM2zMAAAAASUVORK5CYII=';
const ICON_TYPE = 'image/x-icon';

export { appError, clearAppErrorModal, emitBuildLog, emitBuildResults, emitBuildStatus, hmrWindow, initBuildProgress, initBuildStatus, logBuild, logDiagnostic, logDisabled, logReload, logWarn, onBuildLog, onBuildResults, onBuildStatus };
