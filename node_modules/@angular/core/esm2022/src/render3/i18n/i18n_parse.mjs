/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import '../../util/ng_dev_mode';
import '../../util/ng_i18n_closure_mode';
import { XSS_SECURITY_URL } from '../../error_details_base_url';
import { getTemplateContent, URI_ATTRS, VALID_ATTRS, VALID_ELEMENTS } from '../../sanitization/html_sanitizer';
import { getInertBodyHelper } from '../../sanitization/inert_body';
import { _sanitizeUrl } from '../../sanitization/url_sanitizer';
import { assertDefined, assertEqual, assertGreaterThanOrEqual, assertOneOf, assertString } from '../../util/assert';
import { loadIcuContainerVisitor } from '../instructions/i18n_icu_container_visitor';
import { allocExpando, createTNodeAtIndex } from '../instructions/shared';
import { getDocument } from '../interfaces/document';
import { ELEMENT_MARKER, I18nCreateOpCode, ICU_MARKER } from '../interfaces/i18n';
import { HEADER_OFFSET } from '../interfaces/view';
import { getCurrentParentTNode, getCurrentTNode, setCurrentTNode } from '../state';
import { i18nCreateOpCodesToString, i18nRemoveOpCodesToString, i18nUpdateOpCodesToString, icuCreateOpCodesToString } from './i18n_debug';
import { addTNodeAndUpdateInsertBeforeIndex } from './i18n_insert_before_index';
import { ensureIcuContainerVisitorLoaded } from './i18n_tree_shaking';
import { createTNodePlaceholder, icuCreateOpCode, setTIcu, setTNodeInsertBeforeIndex } from './i18n_util';
const BINDING_REGEXP = /�(\d+):?\d*�/gi;
const ICU_REGEXP = /({\s*�\d+:?\d*�\s*,\s*\S{6}\s*,[\s\S]*})/gi;
const NESTED_ICU = /�(\d+)�/;
const ICU_BLOCK_REGEXP = /^\s*(�\d+:?\d*�)\s*,\s*(select|plural)\s*,/;
const MARKER = `�`;
const SUBTEMPLATE_REGEXP = /�\/?\*(\d+:\d+)�/gi;
const PH_REGEXP = /�(\/?[#*]\d+):?\d*�/gi;
/**
 * Angular uses the special entity &ngsp; as a placeholder for non-removable space.
 * It's replaced by the 0xE500 PUA (Private Use Areas) unicode character and later on replaced by a
 * space.
 * We are re-implementing the same idea since translations might contain this special character.
 */
const NGSP_UNICODE_REGEXP = /\uE500/g;
function replaceNgsp(value) {
    return value.replace(NGSP_UNICODE_REGEXP, ' ');
}
/**
 * Patch a `debug` property getter on top of the existing object.
 *
 * NOTE: always call this method with `ngDevMode && attachDebugObject(...)`
 *
 * @param obj Object to patch
 * @param debugGetter Getter returning a value to patch
 */
function attachDebugGetter(obj, debugGetter) {
    if (ngDevMode) {
        Object.defineProperty(obj, 'debug', { get: debugGetter, enumerable: false });
    }
    else {
        throw new Error('This method should be guarded with `ngDevMode` so that it can be tree shaken in production!');
    }
}
/**
 * Create dynamic nodes from i18n translation block.
 *
 * - Text nodes are created synchronously
 * - TNodes are linked into tree lazily
 *
 * @param tView Current `TView`
 * @parentTNodeIndex index to the parent TNode of this i18n block
 * @param lView Current `LView`
 * @param index Index of `ɵɵi18nStart` instruction.
 * @param message Message to translate.
 * @param subTemplateIndex Index into the sub template of message translation. (ie in case of
 *     `ngIf`) (-1 otherwise)
 */
export function i18nStartFirstCreatePass(tView, parentTNodeIndex, lView, index, message, subTemplateIndex) {
    const rootTNode = getCurrentParentTNode();
    const createOpCodes = [];
    const updateOpCodes = [];
    const existingTNodeStack = [[]];
    if (ngDevMode) {
        attachDebugGetter(createOpCodes, i18nCreateOpCodesToString);
        attachDebugGetter(updateOpCodes, i18nUpdateOpCodesToString);
    }
    message = getTranslationForTemplate(message, subTemplateIndex);
    const msgParts = replaceNgsp(message).split(PH_REGEXP);
    for (let i = 0; i < msgParts.length; i++) {
        let value = msgParts[i];
        if ((i & 1) === 0) {
            // Even indexes are text (including bindings & ICU expressions)
            const parts = i18nParseTextIntoPartsAndICU(value);
            for (let j = 0; j < parts.length; j++) {
                let part = parts[j];
                if ((j & 1) === 0) {
                    // `j` is odd therefore `part` is string
                    const text = part;
                    ngDevMode && assertString(text, 'Parsed ICU part should be string');
                    if (text !== '') {
                        i18nStartFirstCreatePassProcessTextNode(tView, rootTNode, existingTNodeStack[0], createOpCodes, updateOpCodes, lView, text);
                    }
                }
                else {
                    // `j` is Even therefor `part` is an `ICUExpression`
                    const icuExpression = part;
                    // Verify that ICU expression has the right shape. Translations might contain invalid
                    // constructions (while original messages were correct), so ICU parsing at runtime may
                    // not succeed (thus `icuExpression` remains a string).
                    // Note: we intentionally retain the error here by not using `ngDevMode`, because
                    // the value can change based on the locale and users aren't guaranteed to hit
                    // an invalid string while they're developing.
                    if (typeof icuExpression !== 'object') {
                        throw new Error(`Unable to parse ICU expression in "${message}" message.`);
                    }
                    const icuContainerTNode = createTNodeAndAddOpCode(tView, rootTNode, existingTNodeStack[0], lView, createOpCodes, ngDevMode ? `ICU ${index}:${icuExpression.mainBinding}` : '', true);
                    const icuNodeIndex = icuContainerTNode.index;
                    ngDevMode &&
                        assertGreaterThanOrEqual(icuNodeIndex, HEADER_OFFSET, 'Index must be in absolute LView offset');
                    icuStart(tView, lView, updateOpCodes, parentTNodeIndex, icuExpression, icuNodeIndex);
                }
            }
        }
        else {
            // Odd indexes are placeholders (elements and sub-templates)
            // At this point value is something like: '/#1:2' (originally coming from '�/#1:2�')
            const isClosing = value.charCodeAt(0) === 47 /* CharCode.SLASH */;
            const type = value.charCodeAt(isClosing ? 1 : 0);
            ngDevMode && assertOneOf(type, 42 /* CharCode.STAR */, 35 /* CharCode.HASH */);
            const index = HEADER_OFFSET + Number.parseInt(value.substring((isClosing ? 2 : 1)));
            if (isClosing) {
                existingTNodeStack.shift();
                setCurrentTNode(getCurrentParentTNode(), false);
            }
            else {
                const tNode = createTNodePlaceholder(tView, existingTNodeStack[0], index);
                existingTNodeStack.unshift([]);
                setCurrentTNode(tNode, true);
            }
        }
    }
    tView.data[index] = {
        create: createOpCodes,
        update: updateOpCodes,
    };
}
/**
 * Allocate space in i18n Range add create OpCode instruction to create a text or comment node.
 *
 * @param tView Current `TView` needed to allocate space in i18n range.
 * @param rootTNode Root `TNode` of the i18n block. This node determines if the new TNode will be
 *     added as part of the `i18nStart` instruction or as part of the `TNode.insertBeforeIndex`.
 * @param existingTNodes internal state for `addTNodeAndUpdateInsertBeforeIndex`.
 * @param lView Current `LView` needed to allocate space in i18n range.
 * @param createOpCodes Array storing `I18nCreateOpCodes` where new opCodes will be added.
 * @param text Text to be added when the `Text` or `Comment` node will be created.
 * @param isICU true if a `Comment` node for ICU (instead of `Text`) node should be created.
 */
function createTNodeAndAddOpCode(tView, rootTNode, existingTNodes, lView, createOpCodes, text, isICU) {
    const i18nNodeIdx = allocExpando(tView, lView, 1, null);
    let opCode = i18nNodeIdx << I18nCreateOpCode.SHIFT;
    let parentTNode = getCurrentParentTNode();
    if (rootTNode === parentTNode) {
        // FIXME(misko): A null `parentTNode` should represent when we fall of the `LView` boundary.
        // (there is no parent), but in some circumstances (because we are inconsistent about how we set
        // `previousOrParentTNode`) it could point to `rootTNode` So this is a work around.
        parentTNode = null;
    }
    if (parentTNode === null) {
        // If we don't have a parent that means that we can eagerly add nodes.
        // If we have a parent than these nodes can't be added now (as the parent has not been created
        // yet) and instead the `parentTNode` is responsible for adding it. See
        // `TNode.insertBeforeIndex`
        opCode |= I18nCreateOpCode.APPEND_EAGERLY;
    }
    if (isICU) {
        opCode |= I18nCreateOpCode.COMMENT;
        ensureIcuContainerVisitorLoaded(loadIcuContainerVisitor);
    }
    createOpCodes.push(opCode, text === null ? '' : text);
    // We store `{{?}}` so that when looking at debug `TNodeType.template` we can see where the
    // bindings are.
    const tNode = createTNodeAtIndex(tView, i18nNodeIdx, isICU ? 32 /* TNodeType.Icu */ : 1 /* TNodeType.Text */, text === null ? (ngDevMode ? '{{?}}' : '') : text, null);
    addTNodeAndUpdateInsertBeforeIndex(existingTNodes, tNode);
    const tNodeIdx = tNode.index;
    setCurrentTNode(tNode, false /* Text nodes are self closing */);
    if (parentTNode !== null && rootTNode !== parentTNode) {
        // We are a child of deeper node (rather than a direct child of `i18nStart` instruction.)
        // We have to make sure to add ourselves to the parent.
        setTNodeInsertBeforeIndex(parentTNode, tNodeIdx);
    }
    return tNode;
}
/**
 * Processes text node in i18n block.
 *
 * Text nodes can have:
 * - Create instruction in `createOpCodes` for creating the text node.
 * - Allocate spec for text node in i18n range of `LView`
 * - If contains binding:
 *    - bindings => allocate space in i18n range of `LView` to store the binding value.
 *    - populate `updateOpCodes` with update instructions.
 *
 * @param tView Current `TView`
 * @param rootTNode Root `TNode` of the i18n block. This node determines if the new TNode will
 *     be added as part of the `i18nStart` instruction or as part of the
 *     `TNode.insertBeforeIndex`.
 * @param existingTNodes internal state for `addTNodeAndUpdateInsertBeforeIndex`.
 * @param createOpCodes Location where the creation OpCodes will be stored.
 * @param lView Current `LView`
 * @param text The translated text (which may contain binding)
 */
function i18nStartFirstCreatePassProcessTextNode(tView, rootTNode, existingTNodes, createOpCodes, updateOpCodes, lView, text) {
    const hasBinding = text.match(BINDING_REGEXP);
    const tNode = createTNodeAndAddOpCode(tView, rootTNode, existingTNodes, lView, createOpCodes, hasBinding ? null : text, false);
    if (hasBinding) {
        generateBindingUpdateOpCodes(updateOpCodes, text, tNode.index, null, 0, null);
    }
}
/**
 * See `i18nAttributes` above.
 */
export function i18nAttributesFirstPass(tView, index, values) {
    const previousElement = getCurrentTNode();
    const previousElementIndex = previousElement.index;
    const updateOpCodes = [];
    if (ngDevMode) {
        attachDebugGetter(updateOpCodes, i18nUpdateOpCodesToString);
    }
    if (tView.firstCreatePass && tView.data[index] === null) {
        for (let i = 0; i < values.length; i += 2) {
            const attrName = values[i];
            const message = values[i + 1];
            if (message !== '') {
                // Check if attribute value contains an ICU and throw an error if that's the case.
                // ICUs in element attributes are not supported.
                // Note: we intentionally retain the error here by not using `ngDevMode`, because
                // the `value` can change based on the locale and users aren't guaranteed to hit
                // an invalid string while they're developing.
                if (ICU_REGEXP.test(message)) {
                    throw new Error(`ICU expressions are not supported in attributes. Message: "${message}".`);
                }
                // i18n attributes that hit this code path are guaranteed to have bindings, because
                // the compiler treats static i18n attributes as regular attribute bindings.
                // Since this may not be the first i18n attribute on this element we need to pass in how
                // many previous bindings there have already been.
                generateBindingUpdateOpCodes(updateOpCodes, message, previousElementIndex, attrName, countBindings(updateOpCodes), null);
            }
        }
        tView.data[index] = updateOpCodes;
    }
}
/**
 * Generate the OpCodes to update the bindings of a string.
 *
 * @param updateOpCodes Place where the update opcodes will be stored.
 * @param str The string containing the bindings.
 * @param destinationNode Index of the destination node which will receive the binding.
 * @param attrName Name of the attribute, if the string belongs to an attribute.
 * @param sanitizeFn Sanitization function used to sanitize the string after update, if necessary.
 * @param bindingStart The lView index of the next expression that can be bound via an opCode.
 * @returns The mask value for these bindings
 */
function generateBindingUpdateOpCodes(updateOpCodes, str, destinationNode, attrName, bindingStart, sanitizeFn) {
    ngDevMode &&
        assertGreaterThanOrEqual(destinationNode, HEADER_OFFSET, 'Index must be in absolute LView offset');
    const maskIndex = updateOpCodes.length; // Location of mask
    const sizeIndex = maskIndex + 1; // location of size for skipping
    updateOpCodes.push(null, null); // Alloc space for mask and size
    const startIndex = maskIndex + 2; // location of first allocation.
    if (ngDevMode) {
        attachDebugGetter(updateOpCodes, i18nUpdateOpCodesToString);
    }
    const textParts = str.split(BINDING_REGEXP);
    let mask = 0;
    for (let j = 0; j < textParts.length; j++) {
        const textValue = textParts[j];
        if (j & 1) {
            // Odd indexes are bindings
            const bindingIndex = bindingStart + parseInt(textValue, 10);
            updateOpCodes.push(-1 - bindingIndex);
            mask = mask | toMaskBit(bindingIndex);
        }
        else if (textValue !== '') {
            // Even indexes are text
            updateOpCodes.push(textValue);
        }
    }
    updateOpCodes.push(destinationNode << 2 /* I18nUpdateOpCode.SHIFT_REF */ |
        (attrName ? 1 /* I18nUpdateOpCode.Attr */ : 0 /* I18nUpdateOpCode.Text */));
    if (attrName) {
        updateOpCodes.push(attrName, sanitizeFn);
    }
    updateOpCodes[maskIndex] = mask;
    updateOpCodes[sizeIndex] = updateOpCodes.length - startIndex;
    return mask;
}
/**
 * Count the number of bindings in the given `opCodes`.
 *
 * It could be possible to speed this up, by passing the number of bindings found back from
 * `generateBindingUpdateOpCodes()` to `i18nAttributesFirstPass()` but this would then require more
 * complexity in the code and/or transient objects to be created.
 *
 * Since this function is only called once when the template is instantiated, is trivial in the
 * first instance (since `opCodes` will be an empty array), and it is not common for elements to
 * contain multiple i18n bound attributes, it seems like this is a reasonable compromise.
 */
function countBindings(opCodes) {
    let count = 0;
    for (let i = 0; i < opCodes.length; i++) {
        const opCode = opCodes[i];
        // Bindings are negative numbers.
        if (typeof opCode === 'number' && opCode < 0) {
            count++;
        }
    }
    return count;
}
/**
 * Convert binding index to mask bit.
 *
 * Each index represents a single bit on the bit-mask. Because bit-mask only has 32 bits, we make
 * the 32nd bit share all masks for all bindings higher than 32. Since it is extremely rare to
 * have more than 32 bindings this will be hit very rarely. The downside of hitting this corner
 * case is that we will execute binding code more often than necessary. (penalty of performance)
 */
function toMaskBit(bindingIndex) {
    return 1 << Math.min(bindingIndex, 31);
}
export function isRootTemplateMessage(subTemplateIndex) {
    return subTemplateIndex === -1;
}
/**
 * Removes everything inside the sub-templates of a message.
 */
function removeInnerTemplateTranslation(message) {
    let match;
    let res = '';
    let index = 0;
    let inTemplate = false;
    let tagMatched;
    while ((match = SUBTEMPLATE_REGEXP.exec(message)) !== null) {
        if (!inTemplate) {
            res += message.substring(index, match.index + match[0].length);
            tagMatched = match[1];
            inTemplate = true;
        }
        else {
            if (match[0] === `${MARKER}/*${tagMatched}${MARKER}`) {
                index = match.index;
                inTemplate = false;
            }
        }
    }
    ngDevMode &&
        assertEqual(inTemplate, false, `Tag mismatch: unable to find the end of the sub-template in the translation "${message}"`);
    res += message.slice(index);
    return res;
}
/**
 * Extracts a part of a message and removes the rest.
 *
 * This method is used for extracting a part of the message associated with a template. A
 * translated message can span multiple templates.
 *
 * Example:
 * ```
 * <div i18n>Translate <span *ngIf>me</span>!</div>
 * ```
 *
 * @param message The message to crop
 * @param subTemplateIndex Index of the sub-template to extract. If undefined it returns the
 * external template and removes all sub-templates.
 */
export function getTranslationForTemplate(message, subTemplateIndex) {
    if (isRootTemplateMessage(subTemplateIndex)) {
        // We want the root template message, ignore all sub-templates
        return removeInnerTemplateTranslation(message);
    }
    else {
        // We want a specific sub-template
        const start = message.indexOf(`:${subTemplateIndex}${MARKER}`) + 2 + subTemplateIndex.toString().length;
        const end = message.search(new RegExp(`${MARKER}\\/\\*\\d+:${subTemplateIndex}${MARKER}`));
        return removeInnerTemplateTranslation(message.substring(start, end));
    }
}
/**
 * Generate the OpCodes for ICU expressions.
 *
 * @param icuExpression
 * @param index Index where the anchor is stored and an optional `TIcuContainerNode`
 *   - `lView[anchorIdx]` points to a `Comment` node representing the anchor for the ICU.
 *   - `tView.data[anchorIdx]` points to the `TIcuContainerNode` if ICU is root (`null` otherwise)
 */
export function icuStart(tView, lView, updateOpCodes, parentIdx, icuExpression, anchorIdx) {
    ngDevMode && assertDefined(icuExpression, 'ICU expression must be defined');
    let bindingMask = 0;
    const tIcu = {
        type: icuExpression.type,
        currentCaseLViewIndex: allocExpando(tView, lView, 1, null),
        anchorIdx,
        cases: [],
        create: [],
        remove: [],
        update: []
    };
    addUpdateIcuSwitch(updateOpCodes, icuExpression, anchorIdx);
    setTIcu(tView, anchorIdx, tIcu);
    const values = icuExpression.values;
    for (let i = 0; i < values.length; i++) {
        // Each value is an array of strings & other ICU expressions
        const valueArr = values[i];
        const nestedIcus = [];
        for (let j = 0; j < valueArr.length; j++) {
            const value = valueArr[j];
            if (typeof value !== 'string') {
                // It is an nested ICU expression
                const icuIndex = nestedIcus.push(value) - 1;
                // Replace nested ICU expression by a comment node
                valueArr[j] = `<!--�${icuIndex}�-->`;
            }
        }
        bindingMask = parseIcuCase(tView, tIcu, lView, updateOpCodes, parentIdx, icuExpression.cases[i], valueArr.join(''), nestedIcus) |
            bindingMask;
    }
    if (bindingMask) {
        addUpdateIcuUpdate(updateOpCodes, bindingMask, anchorIdx);
    }
}
/**
 * Parses text containing an ICU expression and produces a JSON object for it.
 * Original code from closure library, modified for Angular.
 *
 * @param pattern Text containing an ICU expression that needs to be parsed.
 *
 */
export function parseICUBlock(pattern) {
    const cases = [];
    const values = [];
    let icuType = 1 /* IcuType.plural */;
    let mainBinding = 0;
    pattern = pattern.replace(ICU_BLOCK_REGEXP, function (str, binding, type) {
        if (type === 'select') {
            icuType = 0 /* IcuType.select */;
        }
        else {
            icuType = 1 /* IcuType.plural */;
        }
        mainBinding = parseInt(binding.slice(1), 10);
        return '';
    });
    const parts = i18nParseTextIntoPartsAndICU(pattern);
    // Looking for (key block)+ sequence. One of the keys has to be "other".
    for (let pos = 0; pos < parts.length;) {
        let key = parts[pos++].trim();
        if (icuType === 1 /* IcuType.plural */) {
            // Key can be "=x", we just want "x"
            key = key.replace(/\s*(?:=)?(\w+)\s*/, '$1');
        }
        if (key.length) {
            cases.push(key);
        }
        const blocks = i18nParseTextIntoPartsAndICU(parts[pos++]);
        if (cases.length > values.length) {
            values.push(blocks);
        }
    }
    // TODO(ocombe): support ICU expressions in attributes, see #21615
    return { type: icuType, mainBinding: mainBinding, cases, values };
}
/**
 * Breaks pattern into strings and top level {...} blocks.
 * Can be used to break a message into text and ICU expressions, or to break an ICU expression
 * into keys and cases. Original code from closure library, modified for Angular.
 *
 * @param pattern (sub)Pattern to be broken.
 * @returns An `Array<string|IcuExpression>` where:
 *   - odd positions: `string` => text between ICU expressions
 *   - even positions: `ICUExpression` => ICU expression parsed into `ICUExpression` record.
 */
export function i18nParseTextIntoPartsAndICU(pattern) {
    if (!pattern) {
        return [];
    }
    let prevPos = 0;
    const braceStack = [];
    const results = [];
    const braces = /[{}]/g;
    // lastIndex doesn't get set to 0 so we have to.
    braces.lastIndex = 0;
    let match;
    while (match = braces.exec(pattern)) {
        const pos = match.index;
        if (match[0] == '}') {
            braceStack.pop();
            if (braceStack.length == 0) {
                // End of the block.
                const block = pattern.substring(prevPos, pos);
                if (ICU_BLOCK_REGEXP.test(block)) {
                    results.push(parseICUBlock(block));
                }
                else {
                    results.push(block);
                }
                prevPos = pos + 1;
            }
        }
        else {
            if (braceStack.length == 0) {
                const substring = pattern.substring(prevPos, pos);
                results.push(substring);
                prevPos = pos + 1;
            }
            braceStack.push('{');
        }
    }
    const substring = pattern.substring(prevPos);
    results.push(substring);
    return results;
}
/**
 * Parses a node, its children and its siblings, and generates the mutate & update OpCodes.
 *
 */
export function parseIcuCase(tView, tIcu, lView, updateOpCodes, parentIdx, caseName, unsafeCaseHtml, nestedIcus) {
    const create = [];
    const remove = [];
    const update = [];
    if (ngDevMode) {
        attachDebugGetter(create, icuCreateOpCodesToString);
        attachDebugGetter(remove, i18nRemoveOpCodesToString);
        attachDebugGetter(update, i18nUpdateOpCodesToString);
    }
    tIcu.cases.push(caseName);
    tIcu.create.push(create);
    tIcu.remove.push(remove);
    tIcu.update.push(update);
    const inertBodyHelper = getInertBodyHelper(getDocument());
    const inertBodyElement = inertBodyHelper.getInertBodyElement(unsafeCaseHtml);
    ngDevMode && assertDefined(inertBodyElement, 'Unable to generate inert body element');
    const inertRootNode = getTemplateContent(inertBodyElement) || inertBodyElement;
    if (inertRootNode) {
        return walkIcuTree(tView, tIcu, lView, updateOpCodes, create, remove, update, inertRootNode, parentIdx, nestedIcus, 0);
    }
    else {
        return 0;
    }
}
function walkIcuTree(tView, tIcu, lView, sharedUpdateOpCodes, create, remove, update, parentNode, parentIdx, nestedIcus, depth) {
    let bindingMask = 0;
    let currentNode = parentNode.firstChild;
    while (currentNode) {
        const newIndex = allocExpando(tView, lView, 1, null);
        switch (currentNode.nodeType) {
            case Node.ELEMENT_NODE:
                const element = currentNode;
                const tagName = element.tagName.toLowerCase();
                if (VALID_ELEMENTS.hasOwnProperty(tagName)) {
                    addCreateNodeAndAppend(create, ELEMENT_MARKER, tagName, parentIdx, newIndex);
                    tView.data[newIndex] = tagName;
                    const elAttrs = element.attributes;
                    for (let i = 0; i < elAttrs.length; i++) {
                        const attr = elAttrs.item(i);
                        const lowerAttrName = attr.name.toLowerCase();
                        const hasBinding = !!attr.value.match(BINDING_REGEXP);
                        // we assume the input string is safe, unless it's using a binding
                        if (hasBinding) {
                            if (VALID_ATTRS.hasOwnProperty(lowerAttrName)) {
                                if (URI_ATTRS[lowerAttrName]) {
                                    generateBindingUpdateOpCodes(update, attr.value, newIndex, attr.name, 0, _sanitizeUrl);
                                }
                                else {
                                    generateBindingUpdateOpCodes(update, attr.value, newIndex, attr.name, 0, null);
                                }
                            }
                            else {
                                ngDevMode &&
                                    console.warn(`WARNING: ignoring unsafe attribute value ` +
                                        `${lowerAttrName} on element ${tagName} ` +
                                        `(see ${XSS_SECURITY_URL})`);
                            }
                        }
                        else {
                            addCreateAttribute(create, newIndex, attr);
                        }
                    }
                    // Parse the children of this node (if any)
                    bindingMask = walkIcuTree(tView, tIcu, lView, sharedUpdateOpCodes, create, remove, update, currentNode, newIndex, nestedIcus, depth + 1) |
                        bindingMask;
                    addRemoveNode(remove, newIndex, depth);
                }
                break;
            case Node.TEXT_NODE:
                const value = currentNode.textContent || '';
                const hasBinding = value.match(BINDING_REGEXP);
                addCreateNodeAndAppend(create, null, hasBinding ? '' : value, parentIdx, newIndex);
                addRemoveNode(remove, newIndex, depth);
                if (hasBinding) {
                    bindingMask =
                        generateBindingUpdateOpCodes(update, value, newIndex, null, 0, null) | bindingMask;
                }
                break;
            case Node.COMMENT_NODE:
                // Check if the comment node is a placeholder for a nested ICU
                const isNestedIcu = NESTED_ICU.exec(currentNode.textContent || '');
                if (isNestedIcu) {
                    const nestedIcuIndex = parseInt(isNestedIcu[1], 10);
                    const icuExpression = nestedIcus[nestedIcuIndex];
                    // Create the comment node that will anchor the ICU expression
                    addCreateNodeAndAppend(create, ICU_MARKER, ngDevMode ? `nested ICU ${nestedIcuIndex}` : '', parentIdx, newIndex);
                    icuStart(tView, lView, sharedUpdateOpCodes, parentIdx, icuExpression, newIndex);
                    addRemoveNestedIcu(remove, newIndex, depth);
                }
                break;
        }
        currentNode = currentNode.nextSibling;
    }
    return bindingMask;
}
function addRemoveNode(remove, index, depth) {
    if (depth === 0) {
        remove.push(index);
    }
}
function addRemoveNestedIcu(remove, index, depth) {
    if (depth === 0) {
        remove.push(~index); // remove ICU at `index`
        remove.push(index); // remove ICU comment at `index`
    }
}
function addUpdateIcuSwitch(update, icuExpression, index) {
    update.push(toMaskBit(icuExpression.mainBinding), 2, -1 - icuExpression.mainBinding, index << 2 /* I18nUpdateOpCode.SHIFT_REF */ | 2 /* I18nUpdateOpCode.IcuSwitch */);
}
function addUpdateIcuUpdate(update, bindingMask, index) {
    update.push(bindingMask, 1, index << 2 /* I18nUpdateOpCode.SHIFT_REF */ | 3 /* I18nUpdateOpCode.IcuUpdate */);
}
function addCreateNodeAndAppend(create, marker, text, appendToParentIdx, createAtIdx) {
    if (marker !== null) {
        create.push(marker);
    }
    create.push(text, createAtIdx, icuCreateOpCode(0 /* IcuCreateOpCode.AppendChild */, appendToParentIdx, createAtIdx));
}
function addCreateAttribute(create, newIndex, attr) {
    create.push(newIndex << 1 /* IcuCreateOpCode.SHIFT_REF */ | 1 /* IcuCreateOpCode.Attr */, attr.name, attr.value);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaTE4bl9wYXJzZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3JlbmRlcjMvaTE4bi9pMThuX3BhcnNlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUNILE9BQU8sd0JBQXdCLENBQUM7QUFDaEMsT0FBTyxpQ0FBaUMsQ0FBQztBQUV6QyxPQUFPLEVBQUMsZ0JBQWdCLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUM5RCxPQUFPLEVBQUMsa0JBQWtCLEVBQUUsU0FBUyxFQUFFLFdBQVcsRUFBRSxjQUFjLEVBQUMsTUFBTSxtQ0FBbUMsQ0FBQztBQUM3RyxPQUFPLEVBQUMsa0JBQWtCLEVBQUMsTUFBTSwrQkFBK0IsQ0FBQztBQUNqRSxPQUFPLEVBQUMsWUFBWSxFQUFDLE1BQU0sa0NBQWtDLENBQUM7QUFDOUQsT0FBTyxFQUFDLGFBQWEsRUFBRSxXQUFXLEVBQUUsd0JBQXdCLEVBQUUsV0FBVyxFQUFFLFlBQVksRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBRWxILE9BQU8sRUFBQyx1QkFBdUIsRUFBQyxNQUFNLDRDQUE0QyxDQUFDO0FBQ25GLE9BQU8sRUFBQyxZQUFZLEVBQUUsa0JBQWtCLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUN4RSxPQUFPLEVBQUMsV0FBVyxFQUFDLE1BQU0sd0JBQXdCLENBQUM7QUFDbkQsT0FBTyxFQUFDLGNBQWMsRUFBRSxnQkFBZ0IsRUFBNkUsVUFBVSxFQUF5RSxNQUFNLG9CQUFvQixDQUFDO0FBR25PLE9BQU8sRUFBQyxhQUFhLEVBQWUsTUFBTSxvQkFBb0IsQ0FBQztBQUMvRCxPQUFPLEVBQUMscUJBQXFCLEVBQUUsZUFBZSxFQUFFLGVBQWUsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUVqRixPQUFPLEVBQUMseUJBQXlCLEVBQUUseUJBQXlCLEVBQUUseUJBQXlCLEVBQUUsd0JBQXdCLEVBQUMsTUFBTSxjQUFj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U0FBUyxrQkFBa0IsQ0FBQyxNQUF5QixFQUFFLFdBQW1CLEVBQUUsS0FBYTtJQUN2RixNQUFNLENBQUMsSUFBSSxDQUFDLFdBQVcsRUFBRSxDQUFDLEVBQUUsS0FBSyxzQ0FBOEIscUNBQTZCLENBQUMsQ0FBQztBQUNoRyxDQUFDO0FBRUQsU0FBUyxzQkFBc0IsQ0FDM0IsTUFBd0IsRUFBRSxNQUFzQyxFQUFFLElBQVksRUFDOUUsaUJBQXlCLEVBQUUsV0FBbUI7SUFDaEQsSUFBSSxNQUFNLEtBQUssSUFBSSxFQUFFO1FBQ25CLE1BQU0sQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLENBQUM7S0FDckI7SUFDRCxNQUFNLENBQUMsSUFBSSxDQUNQLElBQUksRUFBRSxXQUFXLEVBQ2pCLGVBQWUsc0NBQThCLGlCQUFpQixFQUFFLFdBQVcsQ0FBQyxDQUFDLENBQUM7QUFDcEYsQ0FBQztBQUVELFNBQVMsa0JBQWtCLENBQUMsTUFBd0IsRUFBRSxRQUFnQixFQUFFLElBQVU7SUFDaEYsTUFBTSxDQUFDLElBQUksQ0FBQyxRQUFRLHFDQUE2QiwrQkFBdUIsRUFBRSxJQUFJLENBQUMsSUFBSSxFQUFFLElBQUksQ0FBQyxLQUFLLENBQUMsQ0FBQztBQUNuRyxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5pbXBvcnQgJy4uLy4uL3V0aWwvbmdfZGV2X21vZGUnO1xuaW1wb3J0ICcuLi8uLi91dGlsL25nX2kxOG5fY2xvc3VyZV9tb2RlJztcblxuaW1wb3J0IHtYU1NfU0VDVVJJVFlfVVJMfSBmcm9tICcuLi8uLi9lcnJvcl9kZXRhaWxzX2Jhc2VfdXJsJztcbmltcG9ydCB7Z2V0VGVtcGxhdGVDb250ZW50LCBVUklfQVRUUlMsIFZBTElEX0FUVFJTLCBWQUxJRF9FTEVNRU5UU30gZnJvbSAnLi4vLi4vc2FuaXRpemF0aW9uL2h0bWxfc2FuaXRpemVyJztcbmltcG9ydCB7Z2V0SW5lcnRCb2R5SGVscGVyfSBmcm9tICcuLi8uLi9zYW5pdGl6YXRpb24vaW5lcnRfYm9keSc7XG5pbXBvcnQge19zYW5pdGl6ZVVybH0gZnJvbSAnLi4vLi4vc2FuaXRpemF0aW9uL3VybF9zYW5pdGl6ZXInO1xuaW1wb3J0IHthc3NlcnREZWZpbmVkLCBhc3NlcnRFcXVhbCwgYXNzZXJ0R3JlYXRlclRoYW5PckVxdWFsLCBhc3NlcnRPbmVPZiwgYXNzZXJ0U3RyaW5nfSBmcm9tICcuLi8uLi91dGlsL2Fzc2VydCc7XG5pbXBvcnQge0NoYXJDb2RlfSBmcm9tICcuLi8uLi91dGlsL2NoYXJfY29kZSc7XG5pbXBvcnQge2xvYWRJY3VDb250YWluZXJWaXNpdG9yfSBmcm9tICcuLi9pbnN0cnVjdGlvbnMvaTE4bl9pY3VfY29udGFpbmVyX3Zpc2l0b3InO1xuaW1wb3J0IHthbGxvY0V4cGFuZG8sIGNyZWF0ZVROb2RlQXRJbmRleH0gZnJvbSAnLi4vaW5zdHJ1Y3Rpb25zL3NoYXJlZCc7XG5pbXBvcnQge2dldERvY3VtZW50fSBmcm9tICcuLi9pbnRlcmZhY2VzL2RvY3VtZW50JztcbmltcG9ydCB7RUxFTUVOVF9NQVJLRVIsIEkxOG5DcmVhdGVPcENvZGUsIEkxOG5DcmVhdGVPcENvZGVzLCBJMThuUmVtb3ZlT3BDb2RlcywgSTE4blVwZGF0ZU9wQ29kZSwgSTE4blVwZGF0ZU9wQ29kZXMsIElDVV9NQVJLRVIsIEljdUNyZWF0ZU9wQ29kZSwgSWN1Q3JlYXRlT3BDb2RlcywgSWN1RXhwcmVzc2lvbiwgSWN1VHlwZSwgVEkxOG4sIFRJY3V9IGZyb20gJy4uL2ludGVyZmFjZXMvaTE4bic7XG5pbXBvcnQge1ROb2RlLCBUTm9kZVR5cGV9IGZyb20gJy4uL2ludGVyZmFjZXMvbm9kZSc7XG5pbXBvcnQge1Nhbml0aXplckZufSBmcm9tICcuLi9pbnRlcmZhY2VzL3Nhbml0aXphdGlvbic7XG5pbXBvcnQge0hFQURFUl9PRkZTRVQsIExWaWV3LCBUVmlld30gZnJvbSAnLi4vaW50ZXJmYWNlcy92aWV3JztcbmltcG9ydCB7Z2V0Q3VycmVudFBhcmVudFROb2RlLCBnZXRDdXJyZW50VE5vZGUsIHNldEN1cnJlbnRUTm9kZX0gZnJvbSAnLi4vc3RhdGUnO1xuXG5pbXBvcnQge2kxOG5DcmVhdGVPcENvZGVzVG9TdHJpbmcsIGkxOG5SZW1vdmVPcENvZGVzVG9TdHJpbmcsIGkxOG5VcGRhdGVPcENvZGVzVG9TdHJpbmcsIGljdUNyZWF0ZU9wQ29kZXNUb1N0cmluZ30gZnJvbSAnLi9pMThuX2RlYnVnJztcbmltcG9ydCB7YWRkVE5vZGVBbmRVcGRhdGVJbnNlcnRCZWZvcmVJbmRleH0gZnJvbSAnLi9pMThuX2luc2VydF9iZWZvcmVfaW5kZXgnO1xuaW1wb3J0IHtlbnN1cmVJY3VDb250YWluZXJWaXNpdG9yTG9hZGVkfSBmcm9tICcuL2kxOG5fdHJlZV9zaGFraW5nJztcbmltcG9ydCB7Y3JlYXRlVE5vZGVQbGFjZWhvbGRlciwgaWN1Q3JlYXRlT3BDb2RlLCBzZXRUSWN1LCBzZXRUTm9kZUluc2VydEJlZm9yZUluZGV4fSBmcm9tICcuL2kxOG5fdXRpbCc7XG5cblxuXG5jb25zdCBCSU5ESU5HX1JFR0VYUCA9IC/vv70oXFxkKyk6P1xcZCrvv70vZ2k7XG5jb25zdCBJQ1VfUkVHRVhQID0gLyh7XFxzKu+/vVxcZCs6P1xcZCrvv71cXHMqLFxccypcXFN7Nn1cXHMqLFtcXHNcXFNdKn0pL2dpO1xuY29uc3QgTkVTVEVEX0lDVSA9IC/vv70oXFxkKynvv70vO1xuY29uc3QgSUNVX0JMT0NLX1JFR0VYUCA9IC9eXFxzKijvv71cXGQrOj9cXGQq77+9KVxccyosXFxzKihzZWxlY3R8cGx1cmFsKVxccyosLztcblxuY29uc3QgTUFSS0VSID0gYO+/vWA7XG5jb25zdCBTVUJURU1QTEFURV9SRUdFWFAgPSAv77+9XFwvP1xcKihcXGQrOlxcZCsp77+9L2dpO1xuY29uc3QgUEhfUkVHRVhQID0gL++/vShcXC8/WyMqXVxcZCspOj9cXGQq77+9L2dpO1xuXG4vKipcbiAqIEFuZ3VsYXIgdXNlcyB0aGUgc3BlY2lhbCBlbnRpdHkgJm5nc3A7IGFzIGEgcGxhY2Vob2xkZXIgZm9yIG5vbi1yZW1vdmFibGUgc3BhY2UuXG4gKiBJdCdzIHJlcGxhY2VkIGJ5IHRoZSAweEU1MDAgUFVBIChQcml2YXRlIFVzZSBBcmVhcykgdW5pY29kZSBjaGFyYWN0ZXIgYW5kIGxhdGVyIG9uIHJlcGxhY2VkIGJ5IGFcbiAqIHNwYWNlLlxuICogV2UgYXJlIHJlLWltcGxlbWVudGluZyB0aGUgc2FtZSBpZGVhIHNpbmNlIHRyYW5zbGF0aW9ucyBtaWdodCBjb250YWluIHRoaXMgc3BlY2lhbCBjaGFyYWN0ZXIuXG4gKi9cbmNvbnN0IE5HU1BfVU5JQ09ERV9SRUdFWFAgPSAvXFx1RTUwMC9nO1xuZnVuY3Rpb24gcmVwbGFjZU5nc3AodmFsdWU6IHN0cmluZyk6IHN0cmluZyB7XG4gIHJldHVybiB2YWx1ZS5yZXBsYWNlKE5HU1BfVU5JQ09ERV9SRUdFWFAsICcgJyk7XG59XG5cbi8qKlxuICogUGF0Y2ggYSBgZGVidWdgIHByb3BlcnR5IGdldHRlciBvbiB0b3Agb2YgdGhlIGV4aXN0aW5nIG9iamVjdC5cbiAqXG4gKiBOT1RFOiBhbHdheXMgY2FsbCB0aGlzIG1ldGhvZCB3aXRoIGBuZ0Rldk1vZGUgJiYgYXR0YWNoRGVidWdPYmplY3QoLi4uKWBcbiAqXG4gKiBAcGFyYW0gb2JqIE9iamVjdCB0byBwYXRjaFxuICogQHBhcmFtIGRlYnVnR2V0dGVyIEdldHRlciByZXR1cm5pbmcgYSB2YWx1ZSB0byBwYXRjaFxuICovXG5mdW5jdGlvbiBhdHRhY2hEZWJ1Z0dldHRlcjxUPihvYmo6IFQsIGRlYnVnR2V0dGVyOiAodGhpczogVCkgPT4gYW55KTogdm9pZCB7XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICBPYmplY3QuZGVmaW5lUHJvcGVydHkob2JqLCAnZGVidWcnLCB7Z2V0OiBkZWJ1Z0dldHRlciwgZW51bWVyYWJsZTogZmFsc2V9KTtcbiAgfSBlbHNlIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICdUaGlzIG1ldGhvZCBzaG91bGQgYmUgZ3VhcmRlZCB3aXRoIGBuZ0Rldk1vZGVgIHNvIHRoYXQgaXQgY2FuIGJlIHRyZWUgc2hha2VuIGluIHByb2R1Y3Rpb24hJyk7XG4gIH1cbn1cblxuLyoqXG4gKiBDcmVhdGUgZHluYW1pYyBub2RlcyBmcm9tIGkxOG4gdHJhbnNsYXRpb24gYmxvY2suXG4gKlxuICogLSBUZXh0IG5vZGVzIGFyZSBjcmVhdGVkIHN5bmNocm9ub3VzbHlcbiAqIC0gVE5vZGVzIGFyZSBsaW5rZWQgaW50byB0cmVlIGxhemlseVxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2BcbiAqIEBwYXJlbnRUTm9kZUluZGV4IGluZGV4IHRvIHRoZSBwYXJlbnQgVE5vZGUgb2YgdGhpcyBpMThuIGJsb2NrXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgXG4gKiBAcGFyYW0gaW5kZXggSW5kZXggb2YgYMm1ybVpMThuU3RhcnRgIGluc3RydWN0aW9uLlxuICogQHBhcmFtIG1lc3NhZ2UgTWVzc2FnZSB0byB0cmFuc2xhdGUuXG4gKiBAcGFyYW0gc3ViVGVtcGxhdGVJbmRleCBJbmRleCBpbnRvIHRoZSBzdWIgdGVtcGxhdGUgb2YgbWVzc2FnZSB0cmFuc2xhdGlvbi4gKGllIGluIGNhc2Ugb2ZcbiAqICAgICBgbmdJZmApICgtMSBvdGhlcndpc2UpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpMThuU3RhcnRGaXJzdENyZWF0ZVBhc3MoXG4gICAgdFZpZXc6IFRWaWV3LCBwYXJlbnRUTm9kZUluZGV4OiBudW1iZXIsIGxWaWV3OiBMVmlldywgaW5kZXg6IG51bWJlciwgbWVzc2FnZTogc3RyaW5nLFxuICAgIHN1YlRlbXBsYXRlSW5kZXg6IG51bWJlcikge1xuICBjb25zdCByb290VE5vZGUgPSBnZXRDdXJyZW50UGFyZW50VE5vZGUoKTtcbiAgY29uc3QgY3JlYXRlT3BDb2RlczogSTE4bkNyZWF0ZU9wQ29kZXMgPSBbXSBhcyBhbnk7XG4gIGNvbnN0IHVwZGF0ZU9wQ29kZXM6IEkxOG5VcGRhdGVPcENvZGVzID0gW10gYXMgYW55O1xuICBjb25zdCBleGlzdGluZ1ROb2RlU3RhY2s6IFROb2RlW11bXSA9IFtbXV07XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICBhdHRhY2hEZWJ1Z0dldHRlcihjcmVhdGVPcENvZGVzLCBpMThuQ3JlYXRlT3BDb2Rlc1RvU3RyaW5nKTtcbiAgICBhdHRhY2hEZWJ1Z0dldHRlcih1cGRhdGVPcENvZGVzLCBpMThuVXBkYXRlT3BDb2Rlc1RvU3RyaW5nKTtcbiAgfVxuXG4gIG1lc3NhZ2UgPSBnZXRUcmFuc2xhdGlvbkZvclRlbXBsYXRlKG1lc3NhZ2UsIHN1YlRlbXBsYXRlSW5kZXgpO1xuICBjb25zdCBtc2dQYXJ0cyA9IHJlcGxhY2VOZ3NwKG1lc3NhZ2UpLnNwbGl0KFBIX1JFR0VYUCk7XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgbXNnUGFydHMubGVuZ3RoOyBpKyspIHtcbiAgICBsZXQgdmFsdWUgPSBtc2dQYXJ0c1tpXTtcbiAgICBpZiAoKGkgJiAxKSA9PT0gMCkge1xuICAgICAgLy8gRXZlbiBpbmRleGVzIGFyZSB0ZXh0IChpbmNsdWRpbmcgYmluZGluZ3MgJiBJQ1UgZXhwcmVzc2lvbnMpXG4gICAgICBjb25zdCBwYXJ0cyA9IGkxOG5QYXJzZVRleHRJbnRvUGFydHNBbmRJQ1UodmFsdWUpO1xuICAgICAgZm9yIChsZXQgaiA9IDA7IGogPCBwYXJ0cy5sZW5ndGg7IGorKykge1xuICAgICAgICBsZXQgcGFydCA9IHBhcnRzW2pdO1xuICAgICAgICBpZiAoKGogJiAxKSA9PT0gMCkge1xuICAgICAgICAgIC8vIGBqYCBpcyBvZGQgdGhlcmVmb3JlIGBwYXJ0YCBpcyBzdHJpbmdcbiAgICAgICAgICBjb25zdCB0ZXh0ID0gcGFydCBhcyBzdHJpbmc7XG4gICAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydFN0cmluZyh0ZXh0LCAnUGFyc2VkIElDVSBwYXJ0IHNob3VsZCBiZSBzdHJpbmcnKTtcbiAgICAgICAgICBpZiAodGV4dCAhPT0gJycpIHtcbiAgICAgICAgICAgIGkxOG5TdGFydEZpcnN0Q3JlYXRlUGFzc1Byb2Nlc3NUZXh0Tm9kZShcbiAgICAgICAgICAgICAgICB0Vmlldywgcm9vdFROb2RlLCBleGlzdGluZ1ROb2RlU3RhY2tbMF0sIGNyZWF0ZU9wQ29kZXMsIHVwZGF0ZU9wQ29kZXMsIGxWaWV3LCB0ZXh0KTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gYGpgIGlzIEV2ZW4gdGhlcmVmb3IgYHBhcnRgIGlzIGFuIGBJQ1VFeHByZXNzaW9uYFxuICAgICAgICAgIGNvbnN0IGljdUV4cHJlc3Npb246IEljdUV4cHJlc3Npb24gPSBwYXJ0IGFzIEljdUV4cHJlc3Npb247XG4gICAgICAgICAgLy8gVmVyaWZ5IHRoYXQgSUNVIGV4cHJlc3Npb24gaGFzIHRoZSByaWdodCBzaGFwZS4gVHJhbnNsYXRpb25zIG1pZ2h0IGNvbnRhaW4gaW52YWxpZFxuICAgICAgICAgIC8vIGNvbnN0cnVjdGlvbnMgKHdoaWxlIG9yaWdpbmFsIG1lc3NhZ2VzIHdlcmUgY29ycmVjdCksIHNvIElDVSBwYXJzaW5nIGF0IHJ1bnRpbWUgbWF5XG4gICAgICAgICAgLy8gbm90IHN1Y2NlZWQgKHRodXMgYGljdUV4cHJlc3Npb25gIHJlbWFpbnMgYSBzdHJpbmcpLlxuICAgICAgICAgIC8vIE5vdGU6IHdlIGludGVudGlvbmFsbHkgcmV0YWluIHRoZSBlcnJvciBoZXJlIGJ5IG5vdCB1c2luZyBgbmdEZXZNb2RlYCwgYmVjYXVzZVxuICAgICAgICAgIC8vIHRoZSB2YWx1ZSBjYW4gY2hhbmdlIGJhc2VkIG9uIHRoZSBsb2NhbGUgYW5kIHVzZXJzIGFyZW4ndCBndWFyYW50ZWVkIHRvIGhpdFxuICAgICAgICAgIC8vIGFuIGludmFsaWQgc3RyaW5nIHdoaWxlIHRoZXkncmUgZGV2ZWxvcGluZy5cbiAgICAgICAgICBpZiAodHlwZW9mIGljdUV4cHJlc3Npb24gIT09ICdvYmplY3QnKSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYFVuYWJsZSB0byBwYXJzZSBJQ1UgZXhwcmVzc2lvbiBpbiBcIiR7bWVzc2FnZX1cIiBtZXNzYWdlLmApO1xuICAgICAgICAgIH1cbiAgICAgICAgICBjb25zdCBpY3VDb250YWluZXJUTm9kZSA9IGNyZWF0ZVROb2RlQW5kQWRkT3BDb2RlKFxuICAgICAgICAgICAgICB0Vmlldywgcm9vdFROb2RlLCBleGlzdGluZ1ROb2RlU3RhY2tbMF0sIGxWaWV3LCBjcmVhdGVPcENvZGVzLFxuICAgICAgICAgICAgICBuZ0Rldk1vZGUgPyBgSUNVICR7aW5kZXh9OiR7aWN1RXhwcmVzc2lvbi5tYWluQmluZGluZ31gIDogJycsIHRydWUpO1xuICAgICAgICAgIGNvbnN0IGljdU5vZGVJbmRleCA9IGljdUNvbnRhaW5lclROb2RlLmluZGV4O1xuICAgICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgICBhc3NlcnRHcmVhdGVyVGhhbk9yRXF1YWwoXG4gICAgICAgICAgICAgICAgICBpY3VOb2RlSW5kZXgsIEhFQURFUl9PRkZTRVQsICdJbmRleCBtdXN0IGJlIGluIGFic29sdXRlIExWaWV3IG9mZnNldCcpO1xuICAgICAgICAgIGljdVN0YXJ0KHRWaWV3LCBsVmlldywgdXBkYXRlT3BDb2RlcywgcGFyZW50VE5vZGVJbmRleCwgaWN1RXhwcmVzc2lvbiwgaWN1Tm9kZUluZGV4KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAvLyBPZGQgaW5kZXhlcyBhcmUgcGxhY2Vob2xkZXJzIChlbGVtZW50cyBhbmQgc3ViLXRlbXBsYXRlcylcbiAgICAgIC8vIEF0IHRoaXMgcG9pbnQgdmFsdWUgaXMgc29tZXRoaW5nIGxpa2U6ICcvIzE6MicgKG9yaWdpbmFsbHkgY29taW5nIGZyb20gJ++/vS8jMToy77+9JylcbiAgICAgIGNvbnN0IGlzQ2xvc2luZyA9IHZhbHVlLmNoYXJDb2RlQXQoMCkgPT09IENoYXJDb2RlLlNMQVNIO1xuICAgICAgY29uc3QgdHlwZSA9IHZhbHVlLmNoYXJDb2RlQXQoaXNDbG9zaW5nID8gMSA6IDApO1xuICAgICAgbmdEZXZNb2RlICYmIGFzc2VydE9uZU9mKHR5cGUsIENoYXJDb2RlLlNUQVIsIENoYXJDb2RlLkhBU0gpO1xuICAgICAgY29uc3QgaW5kZXggPSBIRUFERVJfT0ZGU0VUICsgTnVtYmVyLnBhcnNlSW50KHZhbHVlLnN1YnN0cmluZygoaXNDbG9zaW5nID8gMiA6IDEpKSk7XG4gICAgICBpZiAoaXNDbG9zaW5nKSB7XG4gICAgICAgIGV4aXN0aW5nVE5vZGVTdGFjay5zaGlmdCgpO1xuICAgICAgICBzZXRDdXJyZW50VE5vZGUoZ2V0Q3VycmVudFBhcmVudFROb2RlKCkhLCBmYWxzZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBjb25zdCB0Tm9kZSA9IGNyZWF0ZVROb2RlUGxhY2Vob2xkZXIodFZpZXcsIGV4aXN0aW5nVE5vZGVTdGFja1swXSwgaW5kZXgpO1xuICAgICAgICBleGlzdGluZ1ROb2RlU3RhY2sudW5zaGlmdChbXSk7XG4gICAgICAgIHNldEN1cnJlbnRUTm9kZSh0Tm9kZSwgdHJ1ZSk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgdFZpZXcuZGF0YVtpbmRleF0gPSA8VEkxOG4+e1xuICAgIGNyZWF0ZTogY3JlYXRlT3BDb2RlcyxcbiAgICB1cGRhdGU6IHVwZGF0ZU9wQ29kZXMsXG4gIH07XG59XG5cbi8qKlxuICogQWxsb2NhdGUgc3BhY2UgaW4gaTE4biBSYW5nZSBhZGQgY3JlYXRlIE9wQ29kZSBpbnN0cnVjdGlvbiB0byBjcmVhdGUgYSB0ZXh0IG9yIGNvbW1lbnQgbm9kZS5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgQ3VycmVudCBgVFZpZXdgIG5lZWRlZCB0byBhbGxvY2F0ZSBzcGFjZSBpbiBpMThuIHJhbmdlLlxuICogQHBhcmFtIHJvb3RUTm9kZSBSb290IGBUTm9kZWAgb2YgdGhlIGkxOG4gYmxvY2suIFRoaXMgbm9kZSBkZXRlcm1pbmVzIGlmIHRoZSBuZXcgVE5vZGUgd2lsbCBiZVxuICogICAgIGFkZGVkIGFzIHBhcnQgb2YgdGhlIGBpMThuU3RhcnRgIGluc3RydWN0aW9uIG9yIGFzIHBhcnQgb2YgdGhlIGBUTm9kZS5pbnNlcnRCZWZvcmVJbmRleGAuXG4gKiBAcGFyYW0gZXhpc3RpbmdUTm9kZXMgaW50ZXJuYWwgc3RhdGUgZm9yIGBhZGRUTm9kZUFuZFVwZGF0ZUluc2VydEJlZm9yZUluZGV4YC5cbiAqIEBwYXJhbSBsVmlldyBDdXJyZW50IGBMVmlld2AgbmVlZGVkIHRvIGFsbG9jYXRlIHNwYWNlIGluIGkxOG4gcmFuZ2UuXG4gKiBAcGFyYW0gY3JlYXRlT3BDb2RlcyBBcnJheSBzdG9yaW5nIGBJMThuQ3JlYXRlT3BDb2Rlc2Agd2hlcmUgbmV3IG9wQ29kZXMgd2lsbCBiZSBhZGRlZC5cbiAqIEBwYXJhbSB0ZXh0IFRleHQgdG8gYmUgYWRkZWQgd2hlbiB0aGUgYFRleHRgIG9yIGBDb21tZW50YCBub2RlIHdpbGwgYmUgY3JlYXRlZC5cbiAqIEBwYXJhbSBpc0lDVSB0cnVlIGlmIGEgYENvbW1lbnRgIG5vZGUgZm9yIElDVSAoaW5zdGVhZCBvZiBgVGV4dGApIG5vZGUgc2hvdWxkIGJlIGNyZWF0ZWQuXG4gKi9cbmZ1bmN0aW9uIGNyZWF0ZVROb2RlQW5kQWRkT3BDb2RlKFxuICAgIHRWaWV3OiBUVmlldywgcm9vdFROb2RlOiBUTm9kZXxudWxsLCBleGlzdGluZ1ROb2RlczogVE5vZGVbXSwgbFZpZXc6IExWaWV3LFxuICAgIGNyZWF0ZU9wQ29kZXM6IEkxOG5DcmVhdGVPcENvZGVzLCB0ZXh0OiBzdHJpbmd8bnVsbCwgaXNJQ1U6IGJvb2xlYW4pOiBUTm9kZSB7XG4gIGNvbnN0IGkxOG5Ob2RlSWR4ID0gYWxsb2NFeHBhbmRvKHRWaWV3LCBsVmlldywgMSwgbnVsbCk7XG4gIGxldCBvcENvZGUgPSBpMThuTm9kZUlkeCA8PCBJMThuQ3JlYXRlT3BDb2RlLlNISUZUO1xuICBsZXQgcGFyZW50VE5vZGUgPSBnZXRDdXJyZW50UGFyZW50VE5vZGUoKTtcblxuICBpZiAocm9vdFROb2RlID09PSBwYXJlbnRUTm9kZSkge1xuICAgIC8vIEZJWE1FKG1pc2tvKTogQSBudWxsIGBwYXJlbnRUTm9kZWAgc2hvdWxkIHJlcHJlc2VudCB3aGVuIHdlIGZhbGwgb2YgdGhlIGBMVmlld2AgYm91bmRhcnkuXG4gICAgLy8gKHRoZXJlIGlzIG5vIHBhcmVudCksIGJ1dCBpbiBzb21lIGNpcmN1bXN0YW5jZXMgKGJlY2F1c2Ugd2UgYXJlIGluY29uc2lzdGVudCBhYm91dCBob3cgd2Ugc2V0XG4gICAgLy8gYHByZXZpb3VzT3JQYXJlbnRUTm9kZWApIGl0IGNvdWxkIHBvaW50IHRvIGByb290VE5vZGVgIFNvIHRoaXMgaXMgYSB3b3JrIGFyb3VuZC5cbiAgICBwYXJlbnRUTm9kZSA9IG51bGw7XG4gIH1cbiAgaWYgKHBhcmVudFROb2RlID09PSBudWxsKSB7XG4gICAgLy8gSWYgd2UgZG9uJ3QgaGF2ZSBhIHBhcmVudCB0aGF0IG1lYW5zIHRoYXQgd2UgY2FuIGVhZ2VybHkgYWRkIG5vZGVzLlxuICAgIC8vIElmIHdlIGhhdmUgYSBwYXJlbnQgdGhhbiB0aGVzZSBub2RlcyBjYW4ndCBiZSBhZGRlZCBub3cgKGFzIHRoZSBwYXJlbnQgaGFzIG5vdCBiZWVuIGNyZWF0ZWRcbiAgICAvLyB5ZXQpIGFuZCBpbnN0ZWFkIHRoZSBgcGFyZW50VE5vZGVgIGlzIHJlc3BvbnNpYmxlIGZvciBhZGRpbmcgaXQuIFNlZVxuICAgIC8vIGBUTm9kZS5pbnNlcnRCZWZvcmVJbmRleGBcbiAgICBvcENvZGUgfD0gSTE4bkNyZWF0ZU9wQ29kZS5BUFBFTkRfRUFHRVJMWTtcbiAgfVxuICBpZiAoaXNJQ1UpIHtcbiAgICBvcENvZGUgfD0gSTE4bkNyZWF0ZU9wQ29kZS5DT01NRU5UO1xuICAgIGVuc3VyZUljdUNvbnRhaW5lclZpc2l0b3JMb2FkZWQobG9hZEljdUNvbnRhaW5lclZpc2l0b3IpO1xuICB9XG4gIGNyZWF0ZU9wQ29kZXMucHVzaChvcENvZGUsIHRleHQgPT09IG51bGwgPyAnJyA6IHRleHQpO1xuICAvLyBXZSBzdG9yZSBge3s/fX1gIHNvIHRoYXQgd2hlbiBsb29raW5nIGF0IGRlYnVnIGBUTm9kZVR5cGUudGVtcGxhdGVgIHdlIGNhbiBzZWUgd2hlcmUgdGhlXG4gIC8vIGJpbmRpbmdzIGFyZS5cbiAgY29uc3QgdE5vZGUgPSBjcmVhdGVUTm9kZUF0SW5kZXgoXG4gICAgICB0VmlldywgaTE4bk5vZGVJZHgsIGlzSUNVID8gVE5vZGVUeXBlLkljdSA6IFROb2RlVHlwZS5UZXh0LFxuICAgICAgdGV4dCA9PT0gbnVsbCA/IChuZ0Rldk1vZGUgPyAne3s/fX0nIDogJycpIDogdGV4dCwgbnVsbCk7XG4gIGFkZFROb2RlQW5kVXBkYXRlSW5zZXJ0QmVmb3JlSW5kZXgoZXhpc3RpbmdUTm9kZXMsIHROb2RlKTtcbiAgY29uc3QgdE5vZGVJZHggPSB0Tm9kZS5pbmRleDtcbiAgc2V0Q3VycmVudFROb2RlKHROb2RlLCBmYWxzZSAvKiBUZXh0IG5vZGVzIGFyZSBzZWxmIGNsb3NpbmcgKi8pO1xuICBpZiAocGFyZW50VE5vZGUgIT09IG51bGwgJiYgcm9vdFROb2RlICE9PSBwYXJlbnRUTm9kZSkge1xuICAgIC8vIFdlIGFyZSBhIGNoaWxkIG9mIGRlZXBlciBub2RlIChyYXRoZXIgdGhhbiBhIGRpcmVjdCBjaGlsZCBvZiBgaTE4blN0YXJ0YCBpbnN0cnVjdGlvbi4pXG4gICAgLy8gV2UgaGF2ZSB0byBtYWtlIHN1cmUgdG8gYWRkIG91cnNlbHZlcyB0byB0aGUgcGFyZW50LlxuICAgIHNldFROb2RlSW5zZXJ0QmVmb3JlSW5kZXgocGFyZW50VE5vZGUsIHROb2RlSWR4KTtcbiAgfVxuICByZXR1cm4gdE5vZGU7XG59XG5cbi8qKlxuICogUHJvY2Vzc2VzIHRleHQgbm9kZSBpbiBpMThuIGJsb2NrLlxuICpcbiAqIFRleHQgbm9kZXMgY2FuIGhhdmU6XG4gKiAtIENyZWF0ZSBpbnN0cnVjdGlvbiBpbiBgY3JlYXRlT3BDb2Rlc2AgZm9yIGNyZWF0aW5nIHRoZSB0ZXh0IG5vZGUuXG4gKiAtIEFsbG9jYXRlIHNwZWMgZm9yIHRleHQgbm9kZSBpbiBpMThuIHJhbmdlIG9mIGBMVmlld2BcbiAqIC0gSWYgY29udGFpbnMgYmluZGluZzpcbiAqICAgIC0gYmluZGluZ3MgPT4gYWxsb2NhdGUgc3BhY2UgaW4gaTE4biByYW5nZSBvZiBgTFZpZXdgIHRvIHN0b3JlIHRoZSBiaW5kaW5nIHZhbHVlLlxuICogICAgLSBwb3B1bGF0ZSBgdXBkYXRlT3BDb2Rlc2Agd2l0aCB1cGRhdGUgaW5zdHJ1Y3Rpb25zLlxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2BcbiAqIEBwYXJhbSByb290VE5vZGUgUm9vdCBgVE5vZGVgIG9mIHRoZSBpMThuIGJsb2NrLiBUaGlzIG5vZGUgZGV0ZXJtaW5lcyBpZiB0aGUgbmV3IFROb2RlIHdpbGxcbiAqICAgICBiZSBhZGRlZCBhcyBwYXJ0IG9mIHRoZSBgaTE4blN0YXJ0YCBpbnN0cnVjdGlvbiBvciBhcyBwYXJ0IG9mIHRoZVxuICogICAgIGBUTm9kZS5pbnNlcnRCZWZvcmVJbmRleGAuXG4gKiBAcGFyYW0gZXhpc3RpbmdUTm9kZXMgaW50ZXJuYWwgc3RhdGUgZm9yIGBhZGRUTm9kZUFuZFVwZGF0ZUluc2VydEJlZm9yZUluZGV4YC5cbiAqIEBwYXJhbSBjcmVhdGVPcENvZGVzIExvY2F0aW9uIHdoZXJlIHRoZSBjcmVhdGlvbiBPcENvZGVzIHdpbGwgYmUgc3RvcmVkLlxuICogQHBhcmFtIGxWaWV3IEN1cnJlbnQgYExWaWV3YFxuICogQHBhcmFtIHRleHQgVGhlIHRyYW5zbGF0ZWQgdGV4dCAod2hpY2ggbWF5IGNvbnRhaW4gYmluZGluZylcbiAqL1xuZnVuY3Rpb24gaTE4blN0YXJ0Rmlyc3RDcmVhdGVQYXNzUHJvY2Vzc1RleHROb2RlKFxuICAgIHRWaWV3OiBUVmlldywgcm9vdFROb2RlOiBUTm9kZXxudWxsLCBleGlzdGluZ1ROb2RlczogVE5vZGVbXSwgY3JlYXRlT3BDb2RlczogSTE4bkNyZWF0ZU9wQ29kZXMsXG4gICAgdXBkYXRlT3BDb2RlczogSTE4blVwZGF0ZU9wQ29kZXMsIGxWaWV3OiBMVmlldywgdGV4dDogc3RyaW5nKTogdm9pZCB7XG4gIGNvbnN0IGhhc0JpbmRpbmcgPSB0ZXh0Lm1hdGNoKEJJTkRJTkdfUkVHRVhQKTtcbiAgY29uc3QgdE5vZGUgPSBjcmVhdGVUTm9kZUFuZEFkZE9wQ29kZShcbiAgICAgIHRWaWV3LCByb290VE5vZGUsIGV4aXN0aW5nVE5vZGVzLCBsVmlldywgY3JlYXRlT3BDb2RlcywgaGFzQmluZGluZyA/IG51bGwgOiB0ZXh0LCBmYWxzZSk7XG4gIGlmIChoYXNCaW5kaW5nKSB7XG4gICAgZ2VuZXJhdGVCaW5kaW5nVXBkYXRlT3BDb2Rlcyh1cGRhdGVPcENvZGVzLCB0ZXh0LCB0Tm9kZS5pbmRleCwgbnVsbCwgMCwgbnVsbCk7XG4gIH1cbn1cblxuLyoqXG4gKiBTZWUgYGkxOG5BdHRyaWJ1dGVzYCBhYm92ZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGkxOG5BdHRyaWJ1dGVzRmlyc3RQYXNzKHRWaWV3OiBUVmlldywgaW5kZXg6IG51bWJlciwgdmFsdWVzOiBzdHJpbmdbXSkge1xuICBjb25zdCBwcmV2aW91c0VsZW1lbnQgPSBnZXRDdXJyZW50VE5vZGUoKSE7XG4gIGNvbnN0IHByZXZpb3VzRWxlbWVudEluZGV4ID0gcHJldmlvdXNFbGVtZW50LmluZGV4O1xuICBjb25zdCB1cGRhdGVPcENvZGVzOiBJMThuVXBkYXRlT3BDb2RlcyA9IFtdIGFzIGFueTtcbiAgaWYgKG5nRGV2TW9kZSkge1xuICAgIGF0dGFjaERlYnVnR2V0dGVyKHVwZGF0ZU9wQ29kZXMsIGkxOG5VcGRhdGVPcENvZGVzVG9TdHJpbmcpO1xuICB9XG4gIGlmICh0Vmlldy5maXJzdENyZWF0ZVBhc3MgJiYgdFZpZXcuZGF0YVtpbmRleF0gPT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IHZhbHVlcy5sZW5ndGg7IGkgKz0gMikge1xuICAgICAgY29uc3QgYXR0ck5hbWUgPSB2YWx1ZXNbaV07XG4gICAgICBjb25zdCBtZXNzYWdlID0gdmFsdWVzW2kgKyAxXTtcblxuICAgICAgaWYgKG1lc3NhZ2UgIT09ICcnKSB7XG4gICAgICAgIC8vIENoZWNrIGlmIGF0dHJpYnV0ZSB2YWx1ZSBjb250YWlucyBhbiBJQ1UgYW5kIHRocm93IGFuIGVycm9yIGlmIHRoYXQncyB0aGUgY2FzZS5cbiAgICAgICAgLy8gSUNVcyBpbiBlbGVtZW50IGF0dHJpYnV0ZXMgYXJlIG5vdCBzdXBwb3J0ZWQuXG4gICAgICAgIC8vIE5vdGU6IHdlIGludGVudGlvbmFsbHkgcmV0YWluIHRoZSBlcnJvciBoZXJlIGJ5IG5vdCB1c2luZyBgbmdEZXZNb2RlYCwgYmVjYXVzZVxuICAgICAgICAvLyB0aGUgYHZhbHVlYCBjYW4gY2hhbmdlIGJhc2VkIG9uIHRoZSBsb2NhbGUgYW5kIHVzZXJzIGFyZW4ndCBndWFyYW50ZWVkIHRvIGhpdFxuICAgICAgICAvLyBhbiBpbnZhbGlkIHN0cmluZyB3aGlsZSB0aGV5J3JlIGRldmVsb3BpbmcuXG4gICAgICAgIGlmIChJQ1VfUkVHRVhQLnRlc3QobWVzc2FnZSkpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgICAgIGBJQ1UgZXhwcmVzc2lvbnMgYXJlIG5vdCBzdXBwb3J0ZWQgaW4gYXR0cmlidXRlcy4gTWVzc2FnZTogXCIke21lc3NhZ2V9XCIuYCk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyBpMThuIGF0dHJpYnV0ZXMgdGhhdCBoaXQgdGhpcyBjb2RlIHBhdGggYXJlIGd1YXJhbnRlZWQgdG8gaGF2ZSBiaW5kaW5ncywgYmVjYXVzZVxuICAgICAgICAvLyB0aGUgY29tcGlsZXIgdHJlYXRzIHN0YXRpYyBpMThuIGF0dHJpYnV0ZXMgYXMgcmVndWxhciBhdHRyaWJ1dGUgYmluZGluZ3MuXG4gICAgICAgIC8vIFNpbmNlIHRoaXMgbWF5IG5vdCBiZSB0aGUgZmlyc3QgaTE4biBhdHRyaWJ1dGUgb24gdGhpcyBlbGVtZW50IHdlIG5lZWQgdG8gcGFzcyBpbiBob3dcbiAgICAgICAgLy8gbWFueSBwcmV2aW91cyBiaW5kaW5ncyB0aGVyZSBoYXZlIGFscmVhZHkgYmVlbi5cbiAgICAgICAgZ2VuZXJhdGVCaW5kaW5nVXBkYXRlT3BDb2RlcyhcbiAgICAgICAgICAgIHVwZGF0ZU9wQ29kZXMsIG1lc3NhZ2UsIHByZXZpb3VzRWxlbWVudEluZGV4LCBhdHRyTmFtZSwgY291bnRCaW5kaW5ncyh1cGRhdGVPcENvZGVzKSxcbiAgICAgICAgICAgIG51bGwpO1xuICAgICAgfVxuICAgIH1cbiAgICB0Vmlldy5kYXRhW2luZGV4XSA9IHVwZGF0ZU9wQ29kZXM7XG4gIH1cbn1cblxuXG4vKipcbiAqIEdlbmVyYXRlIHRoZSBPcENvZGVzIHRvIHVwZGF0ZSB0aGUgYmluZGluZ3Mgb2YgYSBzdHJpbmcuXG4gKlxuICogQHBhcmFtIHVwZGF0ZU9wQ29kZXMgUGxhY2Ugd2hlcmUgdGhlIHVwZGF0ZSBvcGNvZGVzIHdpbGwgYmUgc3RvcmVkLlxuICogQHBhcmFtIHN0ciBUaGUgc3RyaW5nIGNvbnRhaW5pbmcgdGhlIGJpbmRpbmdzLlxuICogQHBhcmFtIGRlc3RpbmF0aW9uTm9kZSBJbmRleCBvZiB0aGUgZGVzdGluYXRpb24gbm9kZSB3aGljaCB3aWxsIHJlY2VpdmUgdGhlIGJpbmRpbmcuXG4gKiBAcGFyYW0gYXR0ck5hbWUgTmFtZSBvZiB0aGUgYXR0cmlidXRlLCBpZiB0aGUgc3RyaW5nIGJlbG9uZ3MgdG8gYW4gYXR0cmlidXRlLlxuICogQHBhcmFtIHNhbml0aXplRm4gU2FuaXRpemF0aW9uIGZ1bmN0aW9uIHVzZWQgdG8gc2FuaXRpemUgdGhlIHN0cmluZyBhZnRlciB1cGRhdGUsIGlmIG5lY2Vzc2FyeS5cbiAqIEBwYXJhbSBiaW5kaW5nU3RhcnQgVGhlIGxWaWV3IGluZGV4IG9mIHRoZSBuZXh0IGV4cHJlc3Npb24gdGhhdCBjYW4gYmUgYm91bmQgdmlhIGFuIG9wQ29kZS5cbiAqIEByZXR1cm5zIFRoZSBtYXNrIHZhbHVlIGZvciB0aGVzZSBiaW5kaW5nc1xuICovXG5mdW5jdGlvbiBnZW5lcmF0ZUJpbmRpbmdVcGRhdGVPcENvZGVzKFxuICAgIHVwZGF0ZU9wQ29kZXM6IEkxOG5VcGRhdGVPcENvZGVzLCBzdHI6IHN0cmluZywgZGVzdGluYXRpb25Ob2RlOiBudW1iZXIsIGF0dHJOYW1lOiBzdHJpbmd8bnVsbCxcbiAgICBiaW5kaW5nU3RhcnQ6IG51bWJlciwgc2FuaXRpemVGbjogU2FuaXRpemVyRm58bnVsbCk6IG51bWJlciB7XG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0R3JlYXRlclRoYW5PckVxdWFsKFxuICAgICAgICAgIGRlc3RpbmF0aW9uTm9kZSwgSEVBREVSX09GRlNFVCwgJ0luZGV4IG11c3QgYmUgaW4gYWJzb2x1dGUgTFZpZXcgb2Zmc2V0Jyk7XG4gIGNvbnN0IG1hc2tJbmRleCA9IHVwZGF0ZU9wQ29kZXMubGVuZ3RoOyAgLy8gTG9jYXRpb24gb2YgbWFza1xuICBjb25zdCBzaXplSW5kZXggPSBtYXNrSW5kZXggKyAxOyAgICAgICAgIC8vIGxvY2F0aW9uIG9mIHNpemUgZm9yIHNraXBwaW5nXG4gIHVwZGF0ZU9wQ29kZXMucHVzaChudWxsLCBudWxsKTsgICAgICAgICAgLy8gQWxsb2Mgc3BhY2UgZm9yIG1hc2sgYW5kIHNpemVcbiAgY29uc3Qgc3RhcnRJbmRleCA9IG1hc2tJbmRleCArIDI7ICAgICAgICAvLyBsb2NhdGlvbiBvZiBmaXJzdCBhbGxvY2F0aW9uLlxuICBpZiAobmdEZXZNb2RlKSB7XG4gICAgYXR0YWNoRGVidWdHZXR0ZXIodXBkYXRlT3BDb2RlcywgaTE4blVwZGF0ZU9wQ29kZXNUb1N0cmluZyk7XG4gIH1cbiAgY29uc3QgdGV4dFBhcnRzID0gc3RyLnNwbGl0KEJJTkRJTkdfUkVHRVhQKTtcbiAgbGV0IG1hc2sgPSAwO1xuXG4gIGZvciAobGV0IGogPSAwOyBqIDwgdGV4dFBhcnRzLmxlbmd0aDsgaisrKSB7XG4gICAgY29uc3QgdGV4dFZhbHVlID0gdGV4dFBhcnRzW2pdO1xuXG4gICAgaWYgKGogJiAxKSB7XG4gICAgICAvLyBPZGQgaW5kZXhlcyBhcmUgYmluZGluZ3NcbiAgICAgIGNvbnN0IGJpbmRpbmdJbmRleCA9IGJpbmRpbmdTdGFydCArIHBhcnNlSW50KHRleHRWYWx1ZSwgMTApO1xuICAgICAgdXBkYXRlT3BDb2Rlcy5wdXNoKC0xIC0gYmluZGluZ0luZGV4KTtcbiAgICAgIG1hc2sgPSBtYXNrIHwgdG9NYXNrQml0KGJpbmRpbmdJbmRleCk7XG4gICAgfSBlbHNlIGlmICh0ZXh0VmFsdWUgIT09ICcnKSB7XG4gICAgICAvLyBFdmVuIGluZGV4ZXMgYXJlIHRleHRcbiAgICAgIHVwZGF0ZU9wQ29kZXMucHVzaCh0ZXh0VmFsdWUpO1xuICAgIH1cbiAgfVxuXG4gIHVwZGF0ZU9wQ29kZXMucHVzaChcbiAgICAgIGRlc3RpbmF0aW9uTm9kZSA8PCBJMThuVXBkYXRlT3BDb2RlLlNISUZUX1JFRiB8XG4gICAgICAoYXR0ck5hbWUgPyBJMThuVXBkYXRlT3BDb2RlLkF0dHIgOiBJMThuVXBkYXRlT3BDb2RlLlRleHQpKTtcbiAgaWYgKGF0dHJOYW1lKSB7XG4gICAgdXBkYXRlT3BDb2Rlcy5wdXNoKGF0dHJOYW1lLCBzYW5pdGl6ZUZuKTtcbiAgfVxuICB1cGRhdGVPcENvZGVzW21hc2tJbmRleF0gPSBtYXNrO1xuICB1cGRhdGVPcENvZGVzW3NpemVJbmRleF0gPSB1cGRhdGVPcENvZGVzLmxlbmd0aCAtIHN0YXJ0SW5kZXg7XG4gIHJldHVybiBtYXNrO1xufVxuXG4vKipcbiAqIENvdW50IHRoZSBudW1iZXIgb2YgYmluZGluZ3MgaW4gdGhlIGdpdmVuIGBvcENvZGVzYC5cbiAqXG4gKiBJdCBjb3VsZCBiZSBwb3NzaWJsZSB0byBzcGVlZCB0aGlzIHVwLCBieSBwYXNzaW5nIHRoZSBudW1iZXIgb2YgYmluZGluZ3MgZm91bmQgYmFjayBmcm9tXG4gKiBgZ2VuZXJhdGVCaW5kaW5nVXBkYXRlT3BDb2RlcygpYCB0byBgaTE4bkF0dHJpYnV0ZXNGaXJzdFBhc3MoKWAgYnV0IHRoaXMgd291bGQgdGhlbiByZXF1aXJlIG1vcmVcbiAqIGNvbXBsZXhpdHkgaW4gdGhlIGNvZGUgYW5kL29yIHRyYW5zaWVudCBvYmplY3RzIHRvIGJlIGNyZWF0ZWQuXG4gKlxuICogU2luY2UgdGhpcyBmdW5jdGlvbiBpcyBvbmx5IGNhbGxlZCBvbmNlIHdoZW4gdGhlIHRlbXBsYXRlIGlzIGluc3RhbnRpYXRlZCwgaXMgdHJpdmlhbCBpbiB0aGVcbiAqIGZpcnN0IGluc3RhbmNlIChzaW5jZSBgb3BDb2Rlc2Agd2lsbCBiZSBhbiBlbXB0eSBhcnJheSksIGFuZCBpdCBpcyBub3QgY29tbW9uIGZvciBlbGVtZW50cyB0b1xuICogY29udGFpbiBtdWx0aXBsZSBpMThuIGJvdW5kIGF0dHJpYnV0ZXMsIGl0IHNlZW1zIGxpa2UgdGhpcyBpcyBhIHJlYXNvbmFibGUgY29tcHJvbWlzZS5cbiAqL1xuZnVuY3Rpb24gY291bnRCaW5kaW5ncyhvcENvZGVzOiBJMThuVXBkYXRlT3BDb2Rlcyk6IG51bWJlciB7XG4gIGxldCBjb3VudCA9IDA7XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgb3BDb2Rlcy5sZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IG9wQ29kZSA9IG9wQ29kZXNbaV07XG4gICAgLy8gQmluZGluZ3MgYXJlIG5lZ2F0aXZlIG51bWJlcnMuXG4gICAgaWYgKHR5cGVvZiBvcENvZGUgPT09ICdudW1iZXInICYmIG9wQ29kZSA8IDApIHtcbiAgICAgIGNvdW50Kys7XG4gICAgfVxuICB9XG4gIHJldHVybiBjb3VudDtcbn1cblxuLyoqXG4gKiBDb252ZXJ0IGJpbmRpbmcgaW5kZXggdG8gbWFzayBiaXQuXG4gKlxuICogRWFjaCBpbmRleCByZXByZXNlbnRzIGEgc2luZ2xlIGJpdCBvbiB0aGUgYml0LW1hc2suIEJlY2F1c2UgYml0LW1hc2sgb25seSBoYXMgMzIgYml0cywgd2UgbWFrZVxuICogdGhlIDMybmQgYml0IHNoYXJlIGFsbCBtYXNrcyBmb3IgYWxsIGJpbmRpbmdzIGhpZ2hlciB0aGFuIDMyLiBTaW5jZSBpdCBpcyBleHRyZW1lbHkgcmFyZSB0b1xuICogaGF2ZSBtb3JlIHRoYW4gMzIgYmluZGluZ3MgdGhpcyB3aWxsIGJlIGhpdCB2ZXJ5IHJhcmVseS4gVGhlIGRvd25zaWRlIG9mIGhpdHRpbmcgdGhpcyBjb3JuZXJcbiAqIGNhc2UgaXMgdGhhdCB3ZSB3aWxsIGV4ZWN1dGUgYmluZGluZyBjb2RlIG1vcmUgb2Z0ZW4gdGhhbiBuZWNlc3NhcnkuIChwZW5hbHR5IG9mIHBlcmZvcm1hbmNlKVxuICovXG5mdW5jdGlvbiB0b01hc2tCaXQoYmluZGluZ0luZGV4OiBudW1iZXIpOiBudW1iZXIge1xuICByZXR1cm4gMSA8PCBNYXRoLm1pbihiaW5kaW5nSW5kZXgsIDMxKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGlzUm9vdFRlbXBsYXRlTWVzc2FnZShzdWJUZW1wbGF0ZUluZGV4OiBudW1iZXIpOiBzdWJUZW1wbGF0ZUluZGV4IGlzIC0gMSB7XG4gIHJldHVybiBzdWJUZW1wbGF0ZUluZGV4ID09PSAtMTtcbn1cblxuXG4vKipcbiAqIFJlbW92ZXMgZXZlcnl0aGluZyBpbnNpZGUgdGhlIHN1Yi10ZW1wbGF0ZXMgb2YgYSBtZXNzYWdlLlxuICovXG5mdW5jdGlvbiByZW1vdmVJbm5lclRlbXBsYXRlVHJhbnNsYXRpb24obWVzc2FnZTogc3RyaW5nKTogc3RyaW5nIHtcbiAgbGV0IG1hdGNoO1xuICBsZXQgcmVzID0gJyc7XG4gIGxldCBpbmRleCA9IDA7XG4gIGxldCBpblRlbXBsYXRlID0gZmFsc2U7XG4gIGxldCB0YWdNYXRjaGVkO1xuXG4gIHdoaWxlICgobWF0Y2ggPSBTVUJURU1QTEFURV9SRUdFWFAuZXhlYyhtZXNzYWdlKSkgIT09IG51bGwpIHtcbiAgICBpZiAoIWluVGVtcGxhdGUpIHtcbiAgICAgIHJlcyArPSBtZXNzYWdlLnN1YnN0cmluZyhpbmRleCwgbWF0Y2guaW5kZXggKyBtYXRjaFswXS5sZW5ndGgpO1xuICAgICAgdGFnTWF0Y2hlZCA9IG1hdGNoWzFdO1xuICAgICAgaW5UZW1wbGF0ZSA9IHRydWU7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChtYXRjaFswXSA9PT0gYCR7TUFSS0VSfS8qJHt0YWdNYXRjaGVkfSR7TUFSS0VSfWApIHtcbiAgICAgICAgaW5kZXggPSBtYXRjaC5pbmRleDtcbiAgICAgICAgaW5UZW1wbGF0ZSA9IGZhbHNlO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0RXF1YWwoXG4gICAgICAgICAgaW5UZW1wbGF0ZSwgZmFsc2UsXG4gICAgICAgICAgYFRhZyBtaXNtYXRjaDogdW5hYmxlIHRvIGZpbmQgdGhlIGVuZCBvZiB0aGUgc3ViLXRlbXBsYXRlIGluIHRoZSB0cmFuc2xhdGlvbiBcIiR7XG4gICAgICAgICAgICAgIG1lc3NhZ2V9XCJgKTtcblxuICByZXMgKz0gbWVzc2FnZS5zbGljZShpbmRleCk7XG4gIHJldHVybiByZXM7XG59XG5cblxuLyoqXG4gKiBFeHRyYWN0cyBhIHBhcnQgb2YgYSBtZXNzYWdlIGFuZCByZW1vdmVzIHRoZSByZXN0LlxuICpcbiAqIFRoaXMgbWV0aG9kIGlzIHVzZWQgZm9yIGV4dHJhY3RpbmcgYSBwYXJ0IG9mIHRoZSBtZXNzYWdlIGFzc29jaWF0ZWQgd2l0aCBhIHRlbXBsYXRlLiBBXG4gKiB0cmFuc2xhdGVkIG1lc3NhZ2UgY2FuIHNwYW4gbXVsdGlwbGUgdGVtcGxhdGVzLlxuICpcbiAqIEV4YW1wbGU6XG4gKiBgYGBcbiAqIDxkaXYgaTE4bj5UcmFuc2xhdGUgPHNwYW4gKm5nSWY+bWU8L3NwYW4+ITwvZGl2PlxuICogYGBgXG4gKlxuICogQHBhcmFtIG1lc3NhZ2UgVGhlIG1lc3NhZ2UgdG8gY3JvcFxuICogQHBhcmFtIHN1YlRlbXBsYXRlSW5kZXggSW5kZXggb2YgdGhlIHN1Yi10ZW1wbGF0ZSB0byBleHRyYWN0LiBJZiB1bmRlZmluZWQgaXQgcmV0dXJucyB0aGVcbiAqIGV4dGVybmFsIHRlbXBsYXRlIGFuZCByZW1vdmVzIGFsbCBzdWItdGVtcGxhdGVzLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0VHJhbnNsYXRpb25Gb3JUZW1wbGF0ZShtZXNzYWdlOiBzdHJpbmcsIHN1YlRlbXBsYXRlSW5kZXg6IG51bWJlcikge1xuICBpZiAoaXNSb290VGVtcGxhdGVNZXNzYWdlKHN1YlRlbXBsYXRlSW5kZXgpKSB7XG4gICAgLy8gV2Ugd2FudCB0aGUgcm9vdCB0ZW1wbGF0ZSBtZXNzYWdlLCBpZ25vcmUgYWxsIHN1Yi10ZW1wbGF0ZXNcbiAgICByZXR1cm4gcmVtb3ZlSW5uZXJUZW1wbGF0ZVRyYW5zbGF0aW9uKG1lc3NhZ2UpO1xuICB9IGVsc2Uge1xuICAgIC8vIFdlIHdhbnQgYSBzcGVjaWZpYyBzdWItdGVtcGxhdGVcbiAgICBjb25zdCBzdGFydCA9XG4gICAgICAgIG1lc3NhZ2UuaW5kZXhPZihgOiR7c3ViVGVtcGxhdGVJbmRleH0ke01BUktFUn1gKSArIDIgKyBzdWJUZW1wbGF0ZUluZGV4LnRvU3RyaW5nKCkubGVuZ3RoO1xuICAgIGNvbnN0IGVuZCA9IG1lc3NhZ2Uuc2VhcmNoKG5ldyBSZWdFeHAoYCR7TUFSS0VSfVxcXFwvXFxcXCpcXFxcZCs6JHtzdWJUZW1wbGF0ZUluZGV4fSR7TUFSS0VSfWApKTtcbiAgICByZXR1cm4gcmVtb3ZlSW5uZXJUZW1wbGF0ZVRyYW5zbGF0aW9uKG1lc3NhZ2Uuc3Vic3RyaW5nKHN0YXJ0LCBlbmQpKTtcbiAgfVxufVxuXG4vKipcbiAqIEdlbmVyYXRlIHRoZSBPcENvZGVzIGZvciBJQ1UgZXhwcmVzc2lvbnMuXG4gKlxuICogQHBhcmFtIGljdUV4cHJlc3Npb25cbiAqIEBwYXJhbSBpbmRleCBJbmRleCB3aGVyZSB0aGUgYW5jaG9yIGlzIHN0b3JlZCBhbmQgYW4gb3B0aW9uYWwgYFRJY3VDb250YWluZXJOb2RlYFxuICogICAtIGBsVmlld1thbmNob3JJZHhdYCBwb2ludHMgdG8gYSBgQ29tbWVudGAgbm9kZSByZXByZXNlbnRpbmcgdGhlIGFuY2hvciBmb3IgdGhlIElDVS5cbiAqICAgLSBgdFZpZXcuZGF0YVthbmNob3JJZHhdYCBwb2ludHMgdG8gdGhlIGBUSWN1Q29udGFpbmVyTm9kZWAgaWYgSUNVIGlzIHJvb3QgKGBudWxsYCBvdGhlcndpc2UpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpY3VTdGFydChcbiAgICB0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgdXBkYXRlT3BDb2RlczogSTE4blVwZGF0ZU9wQ29kZXMsIHBhcmVudElkeDogbnVtYmVyLFxuICAgIGljdUV4cHJlc3Npb246IEljdUV4cHJlc3Npb24sIGFuY2hvcklkeDogbnVtYmVyKSB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGljdUV4cHJlc3Npb24sICdJQ1UgZXhwcmVzc2lvbiBtdXN0IGJlIGRlZmluZWQnKTtcbiAgbGV0IGJpbmRpbmdNYXNrID0gMDtcbiAgY29uc3QgdEljdTogVEljdSA9IHtcbiAgICB0eXBlOiBpY3VFeHByZXNzaW9uLnR5cGUsXG4gICAgY3VycmVudENhc2VMVmlld0luZGV4OiBhbGxvY0V4cGFuZG8odFZpZXcsIGxWaWV3LCAxLCBudWxsKSxcbiAgICBhbmNob3JJZHgsXG4gICAgY2FzZXM6IFtdLFxuICAgIGNyZWF0ZTogW10sXG4gICAgcmVtb3ZlOiBbXSxcbiAgICB1cGRhdGU6IFtdXG4gIH07XG4gIGFkZFVwZGF0ZUljdVN3aXRjaCh1cGRhdGVPcENvZGVzLCBpY3VFeHByZXNzaW9uLCBhbmNob3JJZHgpO1xuICBzZXRUSWN1KHRWaWV3LCBhbmNob3JJZHgsIHRJY3UpO1xuICBjb25zdCB2YWx1ZXMgPSBpY3VFeHByZXNzaW9uLnZhbHVlcztcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCB2YWx1ZXMubGVuZ3RoOyBpKyspIHtcbiAgICAvLyBFYWNoIHZhbHVlIGlzIGFuIGFycmF5IG9mIHN0cmluZ3MgJiBvdGhlciBJQ1UgZXhwcmVzc2lvbnNcbiAgICBjb25zdCB2YWx1ZUFyciA9IHZhbHVlc1tpXTtcbiAgICBjb25zdCBuZXN0ZWRJY3VzOiBJY3VFeHByZXNzaW9uW10gPSBbXTtcbiAgICBmb3IgKGxldCBqID0gMDsgaiA8IHZhbHVlQXJyLmxlbmd0aDsgaisrKSB7XG4gICAgICBjb25zdCB2YWx1ZSA9IHZhbHVlQXJyW2pdO1xuICAgICAgaWYgKHR5cGVvZiB2YWx1ZSAhPT0gJ3N0cmluZycpIHtcbiAgICAgICAgLy8gSXQgaXMgYW4gbmVzdGVkIElDVSBleHByZXNzaW9uXG4gICAgICAgIGNvbnN0IGljdUluZGV4ID0gbmVzdGVkSWN1cy5wdXNoKHZhbHVlIGFzIEljdUV4cHJlc3Npb24pIC0gMTtcbiAgICAgICAgLy8gUmVwbGFjZSBuZXN0ZWQgSUNVIGV4cHJlc3Npb24gYnkgYSBjb21tZW50IG5vZGVcbiAgICAgICAgdmFsdWVBcnJbal0gPSBgPCEtLe+/vSR7aWN1SW5kZXh977+9LS0+YDtcbiAgICAgIH1cbiAgICB9XG4gICAgYmluZGluZ01hc2sgPSBwYXJzZUljdUNhc2UoXG4gICAgICAgICAgICAgICAgICAgICAgdFZpZXcsIHRJY3UsIGxWaWV3LCB1cGRhdGVPcENvZGVzLCBwYXJlbnRJZHgsIGljdUV4cHJlc3Npb24uY2FzZXNbaV0sXG4gICAgICAgICAgICAgICAgICAgICAgdmFsdWVBcnIuam9pbignJyksIG5lc3RlZEljdXMpIHxcbiAgICAgICAgYmluZGluZ01hc2s7XG4gIH1cbiAgaWYgKGJpbmRpbmdNYXNrKSB7XG4gICAgYWRkVXBkYXRlSWN1VXBkYXRlKHVwZGF0ZU9wQ29kZXMsIGJpbmRpbmdNYXNrLCBhbmNob3JJZHgpO1xuICB9XG59XG5cbi8qKlxuICogUGFyc2VzIHRleHQgY29udGFpbmluZyBhbiBJQ1UgZXhwcmVzc2lvbiBhbmQgcHJvZHVjZXMgYSBKU09OIG9iamVjdCBmb3IgaXQuXG4gKiBPcmlnaW5hbCBjb2RlIGZyb20gY2xvc3VyZSBsaWJyYXJ5LCBtb2RpZmllZCBmb3IgQW5ndWxhci5cbiAqXG4gKiBAcGFyYW0gcGF0dGVybiBUZXh0IGNvbnRhaW5pbmcgYW4gSUNVIGV4cHJlc3Npb24gdGhhdCBuZWVkcyB0byBiZSBwYXJzZWQuXG4gKlxuICovXG5leHBvcnQgZnVuY3Rpb24gcGFyc2VJQ1VCbG9jayhwYXR0ZXJuOiBzdHJpbmcpOiBJY3VFeHByZXNzaW9uIHtcbiAgY29uc3QgY2FzZXMgPSBbXTtcbiAgY29uc3QgdmFsdWVzOiAoc3RyaW5nfEljdUV4cHJlc3Npb24pW11bXSA9IFtdO1xuICBsZXQgaWN1VHlwZSA9IEljdVR5cGUucGx1cmFsO1xuICBsZXQgbWFpbkJpbmRpbmcgPSAwO1xuICBwYXR0ZXJuID0gcGF0dGVybi5yZXBsYWNlKElDVV9CTE9DS19SRUdFWFAsIGZ1bmN0aW9uKHN0cjogc3RyaW5nLCBiaW5kaW5nOiBzdHJpbmcsIHR5cGU6IHN0cmluZykge1xuICAgIGlmICh0eXBlID09PSAnc2VsZWN0Jykge1xuICAgICAgaWN1VHlwZSA9IEljdVR5cGUuc2VsZWN0O1xuICAgIH0gZWxzZSB7XG4gICAgICBpY3VUeXBlID0gSWN1VHlwZS5wbHVyYWw7XG4gICAgfVxuICAgIG1haW5CaW5kaW5nID0gcGFyc2VJbnQoYmluZGluZy5zbGljZSgxKSwgMTApO1xuICAgIHJldHVybiAnJztcbiAgfSk7XG5cbiAgY29uc3QgcGFydHMgPSBpMThuUGFyc2VUZXh0SW50b1BhcnRzQW5kSUNVKHBhdHRlcm4pIGFzIHN0cmluZ1tdO1xuICAvLyBMb29raW5nIGZvciAoa2V5IGJsb2NrKSsgc2VxdWVuY2UuIE9uZSBvZiB0aGUga2V5cyBoYXMgdG8gYmUgXCJvdGhlclwiLlxuICBmb3IgKGxldCBwb3MgPSAwOyBwb3MgPCBwYXJ0cy5sZW5ndGg7KSB7XG4gICAgbGV0IGtleSA9IHBhcnRzW3BvcysrXS50cmltKCk7XG4gICAgaWYgKGljdVR5cGUgPT09IEljdVR5cGUucGx1cmFsKSB7XG4gICAgICAvLyBLZXkgY2FuIGJlIFwiPXhcIiwgd2UganVzdCB3YW50IFwieFwiXG4gICAgICBrZXkgPSBrZXkucmVwbGFjZSgvXFxzKig/Oj0pPyhcXHcrKVxccyovLCAnJDEnKTtcbiAgICB9XG4gICAgaWYgKGtleS5sZW5ndGgpIHtcbiAgICAgIGNhc2VzLnB1c2goa2V5KTtcbiAgICB9XG5cbiAgICBjb25zdCBibG9ja3MgPSBpMThuUGFyc2VUZXh0SW50b1BhcnRzQW5kSUNVKHBhcnRzW3BvcysrXSkgYXMgc3RyaW5nW107XG4gICAgaWYgKGNhc2VzLmxlbmd0aCA+IHZhbHVlcy5sZW5ndGgpIHtcbiAgICAgIHZhbHVlcy5wdXNoKGJsb2Nrcyk7XG4gICAgfVxuICB9XG5cbiAgLy8gVE9ETyhvY29tYmUpOiBzdXBwb3J0IElDVSBleHByZXNzaW9ucyBpbiBhdHRyaWJ1dGVzLCBzZWUgIzIxNjE1XG4gIHJldHVybiB7dHlwZTogaWN1VHlwZSwgbWFpbkJpbmRpbmc6IG1haW5CaW5kaW5nLCBjYXNlcywgdmFsdWVzfTtcbn1cblxuXG4vKipcbiAqIEJyZWFrcyBwYXR0ZXJuIGludG8gc3RyaW5ncyBhbmQgdG9wIGxldmVsIHsuLi59IGJsb2Nrcy5cbiAqIENhbiBiZSB1c2VkIHRvIGJyZWFrIGEgbWVzc2FnZSBpbnRvIHRleHQgYW5kIElDVSBleHByZXNzaW9ucywgb3IgdG8gYnJlYWsgYW4gSUNVIGV4cHJlc3Npb25cbiAqIGludG8ga2V5cyBhbmQgY2FzZXMuIE9yaWdpbmFsIGNvZGUgZnJvbSBjbG9zdXJlIGxpYnJhcnksIG1vZGlmaWVkIGZvciBBbmd1bGFyLlxuICpcbiAqIEBwYXJhbSBwYXR0ZXJuIChzdWIpUGF0dGVybiB0byBiZSBicm9rZW4uXG4gKiBAcmV0dXJucyBBbiBgQXJyYXk8c3RyaW5nfEljdUV4cHJlc3Npb24+YCB3aGVyZTpcbiAqICAgLSBvZGQgcG9zaXRpb25zOiBgc3RyaW5nYCA9PiB0ZXh0IGJldHdlZW4gSUNVIGV4cHJlc3Npb25zXG4gKiAgIC0gZXZlbiBwb3NpdGlvbnM6IGBJQ1VFeHByZXNzaW9uYCA9PiBJQ1UgZXhwcmVzc2lvbiBwYXJzZWQgaW50byBgSUNVRXhwcmVzc2lvbmAgcmVjb3JkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gaTE4blBhcnNlVGV4dEludG9QYXJ0c0FuZElDVShwYXR0ZXJuOiBzdHJpbmcpOiAoc3RyaW5nfEljdUV4cHJlc3Npb24pW10ge1xuICBpZiAoIXBhdHRlcm4pIHtcbiAgICByZXR1cm4gW107XG4gIH1cblxuICBsZXQgcHJldlBvcyA9IDA7XG4gIGNvbnN0IGJyYWNlU3RhY2sgPSBbXTtcbiAgY29uc3QgcmVzdWx0czogKHN0cmluZ3xJY3VFeHByZXNzaW9uKVtdID0gW107XG4gIGNvbnN0IGJyYWNlcyA9IC9be31dL2c7XG4gIC8vIGxhc3RJbmRleCBkb2Vzbid0IGdldCBzZXQgdG8gMCBzbyB3ZSBoYXZlIHRvLlxuICBicmFjZXMubGFzdEluZGV4ID0gMDtcblxuICBsZXQgbWF0Y2g7XG4gIHdoaWxlIChtYXRjaCA9IGJyYWNlcy5leGVjKHBhdHRlcm4pKSB7XG4gICAgY29uc3QgcG9zID0gbWF0Y2guaW5kZXg7XG4gICAgaWYgKG1hdGNoWzBdID09ICd9Jykge1xuICAgICAgYnJhY2VTdGFjay5wb3AoKTtcblxuICAgICAgaWYgKGJyYWNlU3RhY2subGVuZ3RoID09IDApIHtcbiAgICAgICAgLy8gRW5kIG9mIHRoZSBibG9jay5cbiAgICAgICAgY29uc3QgYmxvY2sgPSBwYXR0ZXJuLnN1YnN0cmluZyhwcmV2UG9zLCBwb3MpO1xuICAgICAgICBpZiAoSUNVX0JMT0NLX1JFR0VYUC50ZXN0KGJsb2NrKSkge1xuICAgICAgICAgIHJlc3VsdHMucHVzaChwYXJzZUlDVUJsb2NrKGJsb2NrKSk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgcmVzdWx0cy5wdXNoKGJsb2NrKTtcbiAgICAgICAgfVxuXG4gICAgICAgIHByZXZQb3MgPSBwb3MgKyAxO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBpZiAoYnJhY2VTdGFjay5sZW5ndGggPT0gMCkge1xuICAgICAgICBjb25zdCBzdWJzdHJpbmcgPSBwYXR0ZXJuLnN1YnN0cmluZyhwcmV2UG9zLCBwb3MpO1xuICAgICAgICByZXN1bHRzLnB1c2goc3Vic3RyaW5nKTtcbiAgICAgICAgcHJldlBvcyA9IHBvcyArIDE7XG4gICAgICB9XG4gICAgICBicmFjZVN0YWNrLnB1c2goJ3snKTtcbiAgICB9XG4gIH1cblxuICBjb25zdCBzdWJzdHJpbmcgPSBwYXR0ZXJuLnN1YnN0cmluZyhwcmV2UG9zKTtcbiAgcmVzdWx0cy5wdXNoKHN1YnN0cmluZyk7XG4gIHJldHVybiByZXN1bHRzO1xufVxuXG5cbi8qKlxuICogUGFyc2VzIGEgbm9kZSwgaXRzIGNoaWxkcmVuIGFuZCBpdHMgc2libGluZ3MsIGFuZCBnZW5lcmF0ZXMgdGhlIG11dGF0ZSAmIHVwZGF0ZSBPcENvZGVzLlxuICpcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHBhcnNlSWN1Q2FzZShcbiAgICB0VmlldzogVFZpZXcsIHRJY3U6IFRJY3UsIGxWaWV3OiBMVmlldywgdXBkYXRlT3BDb2RlczogSTE4blVwZGF0ZU9wQ29kZXMsIHBhcmVudElkeDogbnVtYmVyLFxuICAgIGNhc2VOYW1lOiBzdHJpbmcsIHVuc2FmZUNhc2VIdG1sOiBzdHJpbmcsIG5lc3RlZEljdXM6IEljdUV4cHJlc3Npb25bXSk6IG51bWJlciB7XG4gIGNvbnN0IGNyZWF0ZTogSWN1Q3JlYXRlT3BDb2RlcyA9IFtdIGFzIGFueTtcbiAgY29uc3QgcmVtb3ZlOiBJMThuUmVtb3ZlT3BDb2RlcyA9IFtdIGFzIGFueTtcbiAgY29uc3QgdXBkYXRlOiBJMThuVXBkYXRlT3BDb2RlcyA9IFtdIGFzIGFueTtcbiAgaWYgKG5nRGV2TW9kZSkge1xuICAgIGF0dGFjaERlYnVnR2V0dGVyKGNyZWF0ZSwgaWN1Q3JlYXRlT3BDb2Rlc1RvU3RyaW5nKTtcbiAgICBhdHRhY2hEZWJ1Z0dldHRlcihyZW1vdmUsIGkxOG5SZW1vdmVPcENvZGVzVG9TdHJpbmcpO1xuICAgIGF0dGFjaERlYnVnR2V0dGVyKHVwZGF0ZSwgaTE4blVwZGF0ZU9wQ29kZXNUb1N0cmluZyk7XG4gIH1cbiAgdEljdS5jYXNlcy5wdXNoKGNhc2VOYW1lKTtcbiAgdEljdS5jcmVhdGUucHVzaChjcmVhdGUpO1xuICB0SWN1LnJlbW92ZS5wdXNoKHJlbW92ZSk7XG4gIHRJY3UudXBkYXRlLnB1c2godXBkYXRlKTtcblxuICBjb25zdCBpbmVydEJvZHlIZWxwZXIgPSBnZXRJbmVydEJvZHlIZWxwZXIoZ2V0RG9jdW1lbnQoKSk7XG4gIGNvbnN0IGluZXJ0Qm9keUVsZW1lbnQgPSBpbmVydEJvZHlIZWxwZXIuZ2V0SW5lcnRCb2R5RWxlbWVudCh1bnNhZmVDYXNlSHRtbCk7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGluZXJ0Qm9keUVsZW1lbnQsICdVbmFibGUgdG8gZ2VuZXJhdGUgaW5lcnQgYm9keSBlbGVtZW50Jyk7XG4gIGNvbnN0IGluZXJ0Um9vdE5vZGUgPSBnZXRUZW1wbGF0ZUNvbnRlbnQoaW5lcnRCb2R5RWxlbWVudCEpIGFzIEVsZW1lbnQgfHwgaW5lcnRCb2R5RWxlbWVudDtcbiAgaWYgKGluZXJ0Um9vdE5vZGUpIHtcbiAgICByZXR1cm4gd2Fsa0ljdVRyZWUoXG4gICAgICAgIHRWaWV3LCB0SWN1LCBsVmlldywgdXBkYXRlT3BDb2RlcywgY3JlYXRlLCByZW1vdmUsIHVwZGF0ZSwgaW5lcnRSb290Tm9kZSwgcGFyZW50SWR4LFxuICAgICAgICBuZXN0ZWRJY3VzLCAwKTtcbiAgfSBlbHNlIHtcbiAgICByZXR1cm4gMDtcbiAgfVxufVxuXG5mdW5jdGlvbiB3YWxrSWN1VHJlZShcbiAgICB0VmlldzogVFZpZXcsIHRJY3U6IFRJY3UsIGxWaWV3OiBMVmlldywgc2hhcmVkVXBkYXRlT3BDb2RlczogSTE4blVwZGF0ZU9wQ29kZXMsXG4gICAgY3JlYXRlOiBJY3VDcmVhdGVPcENvZGVzLCByZW1vdmU6IEkxOG5SZW1vdmVPcENvZGVzLCB1cGRhdGU6IEkxOG5VcGRhdGVPcENvZGVzLFxuICAgIHBhcmVudE5vZGU6IEVsZW1lbnQsIHBhcmVudElkeDogbnVtYmVyLCBuZXN0ZWRJY3VzOiBJY3VFeHByZXNzaW9uW10sIGRlcHRoOiBudW1iZXIpOiBudW1iZXIge1xuICBsZXQgYmluZGluZ01hc2sgPSAwO1xuICBsZXQgY3VycmVudE5vZGUgPSBwYXJlbnROb2RlLmZpcnN0Q2hpbGQ7XG4gIHdoaWxlIChjdXJyZW50Tm9kZSkge1xuICAgIGNvbnN0IG5ld0luZGV4ID0gYWxsb2NFeHBhbmRvKHRWaWV3LCBsVmlldywgMSwgbnVsbCk7XG4gICAgc3dpdGNoIChjdXJyZW50Tm9kZS5ub2RlVHlwZSkge1xuICAgICAgY2FzZSBOb2RlLkVMRU1FTlRfTk9ERTpcbiAgICAgICAgY29uc3QgZWxlbWVudCA9IGN1cnJlbnROb2RlIGFzIEVsZW1lbnQ7XG4gICAgICAgIGNvbnN0IHRhZ05hbWUgPSBlbGVtZW50LnRhZ05hbWUudG9Mb3dlckNhc2UoKTtcbiAgICAgICAgaWYgKFZBTElEX0VMRU1FTlRTLmhhc093blByb3BlcnR5KHRhZ05hbWUpKSB7XG4gICAgICAgICAgYWRkQ3JlYXRlTm9kZUFuZEFwcGVuZChjcmVhdGUsIEVMRU1FTlRfTUFSS0VSLCB0YWdOYW1lLCBwYXJlbnRJZHgsIG5ld0luZGV4KTtcbiAgICAgICAgICB0Vmlldy5kYXRhW25ld0luZGV4XSA9IHRhZ05hbWU7XG4gICAgICAgICAgY29uc3QgZWxBdHRycyA9IGVsZW1lbnQuYXR0cmlidXRlcztcbiAgICAgICAgICBmb3IgKGxldCBpID0gMDsgaSA8IGVsQXR0cnMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGNvbnN0IGF0dHIgPSBlbEF0dHJzLml0ZW0oaSkhO1xuICAgICAgICAgICAgY29uc3QgbG93ZXJBdHRyTmFtZSA9IGF0dHIubmFtZS50b0xvd2VyQ2FzZSgpO1xuICAgICAgICAgICAgY29uc3QgaGFzQmluZGluZyA9ICEhYXR0ci52YWx1ZS5tYXRjaChCSU5ESU5HX1JFR0VYUCk7XG4gICAgICAgICAgICAvLyB3ZSBhc3N1bWUgdGhlIGlucHV0IHN0cmluZyBpcyBzYWZlLCB1bmxlc3MgaXQncyB1c2luZyBhIGJpbmRpbmdcbiAgICAgICAgICAgIGlmIChoYXNCaW5kaW5nKSB7XG4gICAgICAgICAgICAgIGlmIChWQUxJRF9BVFRSUy5oYXNPd25Qcm9wZXJ0eShsb3dlckF0dHJOYW1lKSkge1xuICAgICAgICAgICAgICAgIGlmIChVUklfQVRUUlNbbG93ZXJBdHRyTmFtZV0pIHtcbiAgICAgICAgICAgICAgICAgIGdlbmVyYXRlQmluZGluZ1VwZGF0ZU9wQ29kZXMoXG4gICAgICAgICAgICAgICAgICAgICAgdXBkYXRlLCBhdHRyLnZhbHVlLCBuZXdJbmRleCwgYXR0ci5uYW1lLCAwLCBfc2FuaXRpemVVcmwpO1xuICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICBnZW5lcmF0ZUJpbmRpbmdVcGRhdGVPcENvZGVzKHVwZGF0ZSwgYXR0ci52YWx1ZSwgbmV3SW5kZXgsIGF0dHIubmFtZSwgMCwgbnVsbCk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLndhcm4oXG4gICAgICAgICAgICAgICAgICAgICAgICBgV0FSTklORzogaWdub3JpbmcgdW5zYWZlIGF0dHJpYnV0ZSB2YWx1ZSBgICtcbiAgICAgICAgICAgICAgICAgICAgICAgIGAke2xvd2VyQXR0ck5hbWV9IG9uIGVsZW1lbnQgJHt0YWdOYW1lfSBgICtcbiAgICAgICAgICAgICAgICAgICAgICAgIGAoc2VlICR7WFNTX1NFQ1VSSVRZX1VSTH0pYCk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIGFkZENyZWF0ZUF0dHJpYnV0ZShjcmVhdGUsIG5ld0luZGV4LCBhdHRyKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgICAgLy8gUGFyc2UgdGhlIGNoaWxkcmVuIG9mIHRoaXMgbm9kZSAoaWYgYW55KVxuICAgICAgICAgIGJpbmRpbmdNYXNrID0gd2Fsa0ljdVRyZWUoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdFZpZXcsIHRJY3UsIGxWaWV3LCBzaGFyZWRVcGRhdGVPcENvZGVzLCBjcmVhdGUsIHJlbW92ZSwgdXBkYXRlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGN1cnJlbnROb2RlIGFzIEVsZW1lbnQsIG5ld0luZGV4LCBuZXN0ZWRJY3VzLCBkZXB0aCArIDEpIHxcbiAgICAgICAgICAgICAgYmluZGluZ01hc2s7XG4gICAgICAgICAgYWRkUmVtb3ZlTm9kZShyZW1vdmUsIG5ld0luZGV4LCBkZXB0aCk7XG4gICAgICAgIH1cbiAgICAgICAgYnJlYWs7XG4gICAgICBjYXNlIE5vZGUuVEVYVF9OT0RFOlxuICAgICAgICBjb25zdCB2YWx1ZSA9IGN1cnJlbnROb2RlLnRleHRDb250ZW50IHx8ICcnO1xuICAgICAgICBjb25zdCBoYXNCaW5kaW5nID0gdmFsdWUubWF0Y2goQklORElOR19SRUdFWFApO1xuICAgICAgICBhZGRDcmVhdGVOb2RlQW5kQXBwZW5kKGNyZWF0ZSwgbnVsbCwgaGFzQmluZGluZyA/ICcnIDogdmFsdWUsIHBhcmVudElkeCwgbmV3SW5kZXgpO1xuICAgICAgICBhZGRSZW1vdmVOb2RlKHJlbW92ZSwgbmV3SW5kZXgsIGRlcHRoKTtcbiAgICAgICAgaWYgKGhhc0JpbmRpbmcpIHtcbiAgICAgICAgICBiaW5kaW5nTWFzayA9XG4gICAgICAgICAgICAgIGdlbmVyYXRlQmluZGluZ1VwZGF0ZU9wQ29kZXModXBkYXRlLCB2YWx1ZSwgbmV3SW5kZXgsIG51bGwsIDAsIG51bGwpIHwgYmluZGluZ01hc2s7XG4gICAgICAgIH1cbiAgICAgICAgYnJlYWs7XG4gICAgICBjYXNlIE5vZGUuQ09NTUVOVF9OT0RFOlxuICAgICAgICAvLyBDaGVjayBpZiB0aGUgY29tbWVudCBub2RlIGlzIGEgcGxhY2Vob2xkZXIgZm9yIGEgbmVzdGVkIElDVVxuICAgICAgICBjb25zdCBpc05lc3RlZEljdSA9IE5FU1RFRF9JQ1UuZXhlYyhjdXJyZW50Tm9kZS50ZXh0Q29udGVudCB8fCAnJyk7XG4gICAgICAgIGlmIChpc05lc3RlZEljdSkge1xuICAgICAgICAgIGNvbnN0IG5lc3RlZEljdUluZGV4ID0gcGFyc2VJbnQoaXNOZXN0ZWRJY3VbMV0sIDEwKTtcbiAgICAgICAgICBjb25zdCBpY3VFeHByZXNzaW9uOiBJY3VFeHByZXNzaW9uID0gbmVzdGVkSWN1c1tuZXN0ZWRJY3VJbmRleF07XG4gICAgICAgICAgLy8gQ3JlYXRlIHRoZSBjb21tZW50IG5vZGUgdGhhdCB3aWxsIGFuY2hvciB0aGUgSUNVIGV4cHJlc3Npb25cbiAgICAgICAgICBhZGRDcmVhdGVOb2RlQW5kQXBwZW5kKFxuICAgICAgICAgICAgICBjcmVhdGUsIElDVV9NQVJLRVIsIG5nRGV2TW9kZSA/IGBuZXN0ZWQgSUNVICR7bmVzdGVkSWN1SW5kZXh9YCA6ICcnLCBwYXJlbnRJZHgsXG4gICAgICAgICAgICAgIG5ld0luZGV4KTtcbiAgICAgICAgICBpY3VTdGFydCh0VmlldywgbFZpZXcsIHNoYXJlZFVwZGF0ZU9wQ29kZXMsIHBhcmVudElkeCwgaWN1RXhwcmVzc2lvbiwgbmV3SW5kZXgpO1xuICAgICAgICAgIGFkZFJlbW92ZU5lc3RlZEljdShyZW1vdmUsIG5ld0luZGV4LCBkZXB0aCk7XG4gICAgICAgIH1cbiAgICAgICAgYnJlYWs7XG4gICAgfVxuICAgIGN1cnJlbnROb2RlID0gY3VycmVudE5vZGUubmV4dFNpYmxpbmc7XG4gIH1cbiAgcmV0dXJuIGJpbmRpbmdNYXNrO1xufVxuXG5mdW5jdGlvbiBhZGRSZW1vdmVOb2RlKHJlbW92ZTogSTE4blJlbW92ZU9wQ29kZXMsIGluZGV4OiBudW1iZXIsIGRlcHRoOiBudW1iZXIpIHtcbiAgaWYgKGRlcHRoID09PSAwKSB7XG4gICAgcmVtb3ZlLnB1c2goaW5kZXgpO1xuICB9XG59XG5cbmZ1bmN0aW9uIGFkZFJlbW92ZU5lc3RlZEljdShyZW1vdmU6IEkxOG5SZW1vdmVPcENvZGVzLCBpbmRleDogbnVtYmVyLCBkZXB0aDogbnVtYmVyKSB7XG4gIGlmIChkZXB0aCA9PT0gMCkge1xuICAgIHJlbW92ZS5wdXNoKH5pbmRleCk7ICAvLyByZW1vdmUgSUNVIGF0IGBpbmRleGBcbiAgICByZW1vdmUucHVzaChpbmRleCk7ICAgLy8gcmVtb3ZlIElDVSBjb21tZW50IGF0IGBpbmRleGBcbiAgfVxufVxuXG5mdW5jdGlvbiBhZGRVcGRhdGVJY3VTd2l0Y2goXG4gICAgdXBkYXRlOiBJMThuVXBkYXRlT3BDb2RlcywgaWN1RXhwcmVzc2lvbjogSWN1RXhwcmVzc2lvbiwgaW5kZXg6IG51bWJlcikge1xuICB1cGRhdGUucHVzaChcbiAgICAgIHRvTWFza0JpdChpY3VFeHByZXNzaW9uLm1haW5CaW5kaW5nKSwgMiwgLTEgLSBpY3VFeHByZXNzaW9uLm1haW5CaW5kaW5nLFxuICAgICAgaW5kZXggPDwgSTE4blVwZGF0ZU9wQ29kZS5TSElGVF9SRUYgfCBJMThuVXBkYXRlT3BDb2RlLkljdVN3aXRjaCk7XG59XG5cbmZ1bmN0aW9uIGFkZFVwZGF0ZUljdVVwZGF0ZSh1cGRhdGU6IEkxOG5VcGRhdGVPcENvZGVzLCBiaW5kaW5nTWFzazogbnVtYmVyLCBpbmRleDogbnVtYmVyKSB7XG4gIHVwZGF0ZS5wdXNoKGJpbmRpbmdNYXNrLCAxLCBpbmRleCA8PCBJMThuVXBkYXRlT3BDb2RlLlNISUZUX1JFRiB8IEkxOG5VcGRhdGVPcENvZGUuSWN1VXBkYXRlKTtcbn1cblxuZnVuY3Rpb24gYWRkQ3JlYXRlTm9kZUFuZEFwcGVuZChcbiAgICBjcmVhdGU6IEljdUNyZWF0ZU9wQ29kZXMsIG1hcmtlcjogbnVsbHxJQ1VfTUFSS0VSfEVMRU1FTlRfTUFSS0VSLCB0ZXh0OiBzdHJpbmcsXG4gICAgYXBwZW5kVG9QYXJlbnRJZHg6IG51bWJlciwgY3JlYXRlQXRJZHg6IG51bWJlcikge1xuICBpZiAobWFya2VyICE9PSBudWxsKSB7XG4gICAgY3JlYXRlLnB1c2gobWFya2VyKTtcbiAgfVxuICBjcmVhdGUucHVzaChcbiAgICAgIHRleHQsIGNyZWF0ZUF0SWR4LFxuICAgICAgaWN1Q3JlYXRlT3BDb2RlKEljdUNyZWF0ZU9wQ29kZS5BcHBlbmRDaGlsZCwgYXBwZW5kVG9QYXJlbnRJZHgsIGNyZWF0ZUF0SWR4KSk7XG59XG5cbmZ1bmN0aW9uIGFkZENyZWF0ZUF0dHJpYnV0ZShjcmVhdGU6IEljdUNyZWF0ZU9wQ29kZXMsIG5ld0luZGV4OiBudW1iZXIsIGF0dHI6IEF0dHIpIHtcbiAgY3JlYXRlLnB1c2gobmV3SW5kZXggPDwgSWN1Q3JlYXRlT3BDb2RlLlNISUZUX1JFRiB8IEljdUNyZWF0ZU9wQ29kZS5BdHRyLCBhdHRyLm5hbWUsIGF0dHIudmFsdWUpO1xufVxuIl19