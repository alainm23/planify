/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { RuntimeError } from '../../errors';
import { getPluralCase } from '../../i18n/localization';
import { assertDefined, assertDomNode, assertEqual, assertGreaterThan, assertIndexInRange, throwError } from '../../util/assert';
import { assertIndexInExpandoRange, assertTIcu } from '../assert';
import { attachPatchData } from '../context_discovery';
import { elementPropertyInternal, setElementAttribute } from '../instructions/shared';
import { ELEMENT_MARKER, I18nCreateOpCode, ICU_MARKER } from '../interfaces/i18n';
import { HEADER_OFFSET, RENDERER } from '../interfaces/view';
import { createCommentNode, createElementNode, createTextNode, nativeInsertBefore, nativeParentNode, nativeRemoveNode, updateTextNode } from '../node_manipulation';
import { getBindingIndex } from '../state';
import { renderStringify } from '../util/stringify_utils';
import { getNativeByIndex, unwrapRNode } from '../util/view_utils';
import { getLocaleId } from './i18n_locale_id';
import { getCurrentICUCaseIndex, getParentFromIcuCreateOpCode, getRefFromIcuCreateOpCode, getTIcu } from './i18n_util';
/**
 * Keep track of which input bindings in `ɵɵi18nExp` have changed.
 *
 * This is used to efficiently update expressions in i18n only when the corresponding input has
 * changed.
 *
 * 1) Each bit represents which of the `ɵɵi18nExp` has changed.
 * 2) There are 32 bits allowed in JS.
 * 3) Bit 32 is special as it is shared for all changes past 32. (In other words if you have more
 * than 32 `ɵɵi18nExp` then all changes past 32nd `ɵɵi18nExp` will be mapped to same bit. This means
 * that we may end up changing more than we need to. But i18n expressions with 32 bindings is rare
 * so in practice it should not be an issue.)
 */
let changeMask = 0b0;
/**
 * Keeps track of which bit needs to be updated in `changeMask`
 *
 * This value gets incremented on every call to `ɵɵi18nExp`
 */
let changeMaskCounter = 0;
/**
 * Keep track of which input bindings in `ɵɵi18nExp` have changed.
 *
 * `setMaskBit` gets invoked by each call to `ɵɵi18nExp`.
 *
 * @param hasChange did `ɵɵi18nExp` detect a change.
 */
export function setMaskBit(hasChange) {
    if (hasChange) {
        changeMask = changeMask | (1 << Math.min(changeMaskCounter, 31));
    }
    changeMaskCounter++;
}
export function applyI18n(tView, lView, index) {
    if (changeMaskCounter > 0) {
        ngDevMode && assertDefined(tView, `tView should be defined`);
        const tI18n = tView.data[index];
        // When `index` points to an `ɵɵi18nAttributes` then we have an array otherwise `TI18n`
        const updateOpCodes = Array.isArray(tI18n) ? tI18n : tI18n.update;
        const bindingsStartIndex = getBindingIndex() - changeMaskCounter - 1;
        applyUpdateOpCodes(tView, lView, updateOpCodes, bindingsStartIndex, changeMask);
    }
    // Reset changeMask & maskBit to default for the next update cycle
    changeMask = 0b0;
    changeMaskCounter = 0;
}
/**
 * Apply `I18nCreateOpCodes` op-codes as stored in `TI18n.create`.
 *
 * Creates text (and comment) nodes which are internationalized.
 *
 * @param lView Current lView
 * @param createOpCodes Set of op-codes to apply
 * @param parentRNode Parent node (so that direct children can be added eagerly) or `null` if it is
 *     a root node.
 * @param insertInFrontOf DOM node that should be used as an anchor.
 */
export function applyCreateOpCodes(lView, createOpCodes, parentRNode, insertInFrontOf) {
    const renderer = lView[RENDERER];
    for (let i = 0; i < createOpCodes.length; i++) {
        const opCode = createOpCodes[i++];
        const text = createOpCodes[i];
        const isComment = (opCode & I18nCreateOpCode.COMMENT) === I18nCreateOpCode.COMMENT;
        const appendNow = (opCode & I18nCreateOpCode.APPEND_EAGERLY) === I18nCreateOpCode.APPEND_EAGERLY;
        const index = opCode >>> I18nCreateOpCode.SHIFT;
        let rNode = lView[index];
        if (rNode === null) {
            // We only create new DOM nodes if they don't already exist: If ICU switches case back to a
            // case which was already instantiated, no need to create new DOM nodes.
            rNode = lView[index] =
                isComment ? renderer.createComment(text) : createTextNode(renderer, text);
        }
        if (appendNow && parentRNode !== null) {
            nativeInsertBefore(renderer, parentRNode, rNode, insertInFrontOf, false);
        }
    }
}
/**
 * Apply `I18nMutateOpCodes` OpCodes.
 *
 * @param tView Current `TView`
 * @param mutableOpCodes Mutable OpCodes to process
 * @param lView Current `LView`
 * @param anchorRNode place where the i18n node should be inserted.
 */
export function applyMutableOpCodes(tView, mutableOpCodes, lView, anchorRNode) {
    ngDevMode && assertDomNode(anchorRNode);
    const renderer = lView[RENDERER];
    // `rootIdx` represents the node into which all inserts happen.
    let rootIdx = null;
    // `rootRNode` represents the real node into which we insert. This can be different from
    // `lView[rootIdx]` if we have projection.
    //  - null we don't have a parent (as can be the case in when we are inserting into a root of
    //    LView which has no parent.)
    //  - `RElement` The element representing the root after taking projection into account.
    let rootRNode;
    for (let i = 0; i < mutableOpCodes.length; i++) {
        const opCode = mutableOpCodes[i];
        if (typeof opCode == 'string') {
            const textNodeIndex = mutableOpCodes[++i];
            if (lView[textNodeIndex] === null) {
                ngDevMode && ngDevMode.rendererCreateTextNode++;
                ngDevMode && assertIndexInRange(lView, textNodeIndex);
                lView[textNodeIndex] = createTextNode(renderer, opCode);
            }
        }
        else if (typeof opCode == 'number') {
            switch (opCode & 1 /* IcuCreateOpCode.MASK_INSTRUCTION */) {
                case 0 /* IcuCreateOpCode.AppendChild */:
                    const parentIdx = getParentFromIcuCreateOpCode(opCode);
                    if (rootIdx === null) {
                        // The first operation should save the `rootIdx` because the first operation
                        // must insert into the root. (Only subsequent operations can insert into a dynamic
                        // parent)
                        rootIdx = parentIdx;
                        rootRNode = nativeParentNode(renderer, anchorRNode);
                    }
                    let insertInFrontOf;
                    let parentRNode;
                    if (parentIdx === rootIdx) {
                        insertInFrontOf = anchorRNode;
                        parentRNode = rootRNode;
                    }
                    else {
                        insertInFrontOf = null;
                        parentRNode = unwrapRNode(lView[parentIdx]);
                    }
                    // FIXME(misko): Refactor with `processI18nText`
                    if (parentRNode !== null) {
                        // This can happen if the `LView` we are adding to is not attached to a parent `LView`.
                        // In such a case there is no "root" we can attach to. This is fine, as we still need to
                        // create the elements. When the `LView` gets later added to a parent these "root" nodes
                        // get picked up and added.
                        ngDevMode && assertDomNode(parentRNode);
                        const refIdx = getRefFromIcuCreateOpCode(opCode);
                        ngDevMode && assertGreaterThan(refIdx, HEADER_OFFSET, 'Missing ref');
                        // `unwrapRNode` is not needed here as all of these point to RNodes as part of the i18n
                        // which can't have components.
                        const child = lView[refIdx];
                        ngDevMode && assertDomNode(child);
                        nativeInsertBefore(renderer, parentRNode, child, insertInFrontOf, false);
                        const tIcu = getTIcu(tView, refIdx);
                        if (tIcu !== null && typeof tIcu === 'object') {
                            // If we just added a comment node which has ICU then that ICU may have already been
                            // rendered and therefore we need to re-add it here.
                            ngDevMode && assertTIcu(tIcu);
                            const caseIndex = getCurrentICUCaseIndex(tIcu, lView);
                            if (caseIndex !== null) {
                                applyMutableOpCodes(tView, tIcu.create[caseIndex], lView, lView[tIcu.anchorIdx]);
                            }
                        }
                    }
                    break;
                case 1 /* IcuCreateOpCode.Attr */:
                    const elementNodeIndex = opCode >>> 1 /* IcuCreateOpCode.SHIFT_REF */;
                    const attrName = mutableOpCodes[++i];
                    const attrValue = mutableOpCodes[++i];
                    // This code is used for ICU expressions only, since we don't support
                    // directives/components in ICUs, we don't need to worry about inputs here
                    setElementAttribute(renderer, getNativeByIndex(elementNodeIndex, lView), null, null, attrName, attrValue, null);
                    break;
                default:
                    if (ngDevMode) {
                        throw new RuntimeError(700 /* RuntimeErrorCode.INVALID_I18N_STRUCTURE */, `Unable to determine the type of mutate operation for "${opCode}"`);
                    }
            }
        }
        else {
            switch (opCode) {
                case ICU_MARKER:
                    const commentValue = mutableOpCodes[++i];
                    const commentNodeIndex = mutableOpCodes[++i];
                    if (lView[commentNodeIndex] === null) {
                        ngDevMode &&
                            assertEqual(typeof commentValue, 'string', `Expected "${commentValue}" to be a comment node value`);
                        ngDevMode && ngDevMode.rendererCreateComment++;
                        ngDevMode && assertIndexInExpandoRange(lView, commentNodeIndex);
                        const commentRNode = lView[commentNodeIndex] =
                            createCommentNode(renderer, commentValue);
                        // FIXME(misko): Attaching patch data is only needed for the root (Also add tests)
                        attachPatchData(commentRNode, lView);
                    }
                    break;
                case ELEMENT_MARKER:
                    const tagName = mutableOpCodes[++i];
                    const elementNodeIndex = mutableOpCodes[++i];
                    if (lView[elementNodeIndex] === null) {
                        ngDevMode &&
                            assertEqual(typeof tagName, 'string', `Expected "${tagName}" to be an element node tag name`);
                        ngDevMode && ngDevMode.rendererCreateElement++;
                        ngDevMode && assertIndexInExpandoRange(lView, elementNodeIndex);
                        const elementRNode = lView[elementNodeIndex] =
                            createElementNode(renderer, tagName, null);
                        // FIXME(misko): Attaching patch data is only needed for the root (Also add tests)
                        attachPatchData(elementRNode, lView);
                    }
                    break;
                default:
                    ngDevMode &&
                        throwError(`Unable to determine the type of mutate operation for "${opCode}"`);
            }
        }
    }
}
/**
 * Apply `I18nUpdateOpCodes` OpCodes
 *
 * @param tView Current `TView`
 * @param lView Current `LView`
 * @param updateOpCodes OpCodes to process
 * @param bindingsStartIndex Location of the first `ɵɵi18nApply`
 * @param changeMask Each bit corresponds to a `ɵɵi18nExp` (Counting backwards from
 *     `bindingsStartIndex`)
 */
export function applyUpdateOpCodes(tView, lView, updateOpCodes, bindingsStartIndex, changeMask) {
    for (let i = 0; i < updateOpCodes.length; i++) {
        // bit code to check if we should apply the next update
        const checkBit = updateOpCodes[i];
        // Number of opCodes to skip until next set of update codes
        const skipCodes = updateOpCodes[++i];
        if (checkBit & changeMask) {
            // The value has been updated since last checked
            let value = '';
            for (let j = i + 1; j <= (i + skipCodes); j++) {
                const opCode = updateOpCodes[j];
                if (typeof opCode == 'string') {
                    value += opCode;
                }
                else if (typeof opCode == 'number') {
                    if (opCode < 0) {
                        // Negative opCode represent `i18nExp` values offset.
                        value += renderStringify(lView[bindingsStartIndex - opCode]);
                    }
                    else {
                        const nodeIndex = (opCode >>> 2 /* I18nUpdateOpCode.SHIFT_REF */);
                        switch (opCode & 3 /* I18nUpdateOpCode.MASK_OPCODE */) {
                            case 1 /* I18nUpdateOpCode.Attr */:
                                const propName = updateOpCodes[++j];
                                const sanitizeFn = updateOpCodes[++j];
                                const tNodeOrTagName = tView.data[nodeIndex];
                                ngDevMode && assertDefined(tNodeOrTagName, 'Experting TNode or string');
                                if (typeof tNodeOrTagName === 'string') {
                                    // IF we don't have a `TNode`, then we are an element in ICU (as ICU content does
                                    // not have TNode), in which case we know that there are no directives, and hence
                                    // we use attribute setting.
                                    setElementAttribute(lView[RENDERER], lView[nodeIndex], null, tNodeOrTagName, propName, value, sanitizeFn);
                                }
                                else {
                                    elementPropertyInternal(tView, tNodeOrTagName, lView, propName, value, lView[RENDERER], sanitizeFn, false);
                                }
                                break;
                            case 0 /* I18nUpdateOpCode.Text */:
                                const rText = lView[nodeIndex];
                                rText !== null && updateTextNode(lView[RENDERER], rText, value);
                                break;
                            case 2 /* I18nUpdateOpCode.IcuSwitch */:
                                applyIcuSwitchCase(tView, getTIcu(tView, nodeIndex), lView, value);
                                break;
                            case 3 /* I18nUpdateOpCode.IcuUpdate */:
                                applyIcuUpdateCase(tView, getTIcu(tView, nodeIndex), bindingsStartIndex, lView);
                                break;
                        }
                    }
                }
            }
        }
        else {
            const opCode = updateOpCodes[i + 1];
            if (opCode > 0 && (opCode & 3 /* I18nUpdateOpCode.MASK_OPCODE */) === 3 /* I18nUpdateOpCode.IcuUpdate */) {
                // Special case for the `icuUpdateCase`. It could be that the mask did not match, but
                // we still need to execute `icuUpdateCase` because the case has changed recently due to
                // previous `icuSwitchCase` instruction. (`icuSwitchCase` and `icuUpdateCase` always come in
                // pairs.)
                const nodeIndex = (opCode >>> 2 /* I18nUpdateOpCode.SHIFT_REF */);
                const tIcu = getTIcu(tView, nodeIndex);
                const currentIndex = lView[tIcu.currentCaseLViewIndex];
                if (currentIndex < 0) {
                    applyIcuUpdateCase(tView, tIcu, bindingsStartIndex, lView);
                }
            }
        }
        i += skipCodes;
    }
}
/**
 * Apply OpCodes associated with updating an existing ICU.
 *
 * @param tView Current `TView`
 * @param tIcu Current `TIcu`
 * @param bindingsStartIndex Location of the first `ɵɵi18nApply`
 * @param lView Current `LView`
 */
function applyIcuUpdateCase(tView, tIcu, bindingsStartIndex, lView) {
    ngDevMode && assertIndexInRange(lView, tIcu.currentCaseLViewIndex);
    let activeCaseIndex = lView[tIcu.currentCaseLViewIndex];
    if (activeCaseIndex !== null) {
        let mask = changeMask;
        if (activeCaseIndex < 0) {
            // Clear the flag.
            // Negative number means that the ICU was freshly created and we need to force the update.
            activeCaseIndex = lView[tIcu.currentCaseLViewIndex] = ~activeCaseIndex;
            // -1 is same as all bits on, which simulates creation since it marks all bits dirty
            mask = -1;
        }
        applyUpdateOpCodes(tView, lView, tIcu.update[activeCaseIndex], bindingsStartIndex, mask);
    }
}
/**
 * Apply OpCodes associated with switching a case on ICU.
 *
 * This involves tearing down existing case and than building up a new case.
 *
 * @param tView Current `TView`
 * @param tIcu Current `TIcu`
 * @param lView Current `LView`
 * @param value Value of the case to update to.
 */
function applyIcuSwitchCase(tView, tIcu, lView, value) {
    // Rebuild a new case for this ICU
    const caseIndex = getCaseIndex(tIcu, value);
    let activeCaseIndex = getCurrentICUCaseIndex(tIcu, lView);
    if (activeCaseIndex !== caseIndex) {
        applyIcuSwitchCaseRemove(tView, tIcu, lView);
        lView[tIcu.currentCaseLViewIndex] = caseIndex === null ? null : ~caseIndex;
        if (caseIndex !== null) {
            // Add the nodes for the new case
            const anchorRNode = lView[tIcu.anchorIdx];
            if (anchorRNode) {
                ngDevMode && assertDomNode(anchorRNode);
                applyMutableOpCodes(tView, tIcu.create[caseIndex], lView, anchorRNode);
            }
        }
    }
}
/**
 * Apply OpCodes associated with tearing ICU case.
 *
 * This involves tearing down existing case and than building up a new case.
 *
 * @param tView Current `TView`
 * @param tIcu Current `TIcu`
 * @param lView Current `LView`
 */
function applyIcuSwitchCaseRemove(tView, tIcu, lView) {
    let activeCaseIndex = getCurrentICUCaseIndex(tIcu, lView);
    if (activeCaseIndex !== null) {
        const removeCodes = tIcu.remove[activeCaseIndex];
        for (let i = 0; i < removeCodes.length; i++) {
            const nodeOrIcuIndex = removeCodes[i];
            if (nodeOrIcuIndex > 0) {
                // Positive numbers are `RNode`s.
                const rNode = getNativeByIndex(nodeOrIcuIndex, lView);
                rNode !== null && nativeRemoveNode(lView[RENDERER], rNode);
            }
            else {
                // Negative numbers are ICUs
                applyIcuSwitchCaseRemove(tView, getTIcu(tView, ~nodeOrIcuIndex), lView);
            }
        }
    }
}
/**
 * Returns the index of the current case of an ICU expression depending on the main binding value
 *
 * @param icuExpression
 * @param bindingValue The value of the main binding used by this ICU expression
 */
function getCaseIndex(icuExpression, bindingValue) {
    let index = icuExpression.cases.indexOf(bindingValue);
    if (index === -1) {
        switch (icuExpression.type) {
            case 1 /* IcuType.plural */: {
                const resolvedCase = getPluralCase(bindingValue, getLocaleId());
                index = icuExpression.cases.indexOf(resolvedCase);
                if (index === -1 && resolvedCase !== 'other') {
                    index = icuExpression.cases.indexOf('other');
                }
                break;
            }
            case 0 /* IcuType.select */: {
                index = icuExpression.cases.indexOf('other');
                break;
            }
        }
    }
    return index === -1 ? null : index;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaTE4bl9hcHBseS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3JlbmRlcjMvaTE4bi9pMThuX2FwcGx5LnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxZQUFZLEVBQW1CLE1BQU0sY0FBYyxDQUFDO0FBQzVELE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSx5QkFBeUIsQ0FBQztBQUN0RCxPQUFPLEVBQUMsYUFBYSxFQUFFLGFBQWEsRUFBRSxXQUFXLEVBQUUsaUJBQWlCLEVBQUUsa0JBQWtCLEVBQUUsVUFBVSxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDL0gsT0FBTyxFQUFDLHlCQUF5QixFQUFFLFVBQVUsRUFBQyxNQUFNLFdBQVcsQ0FBQztBQUNoRSxPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0sc0JBQXNCLENBQUM7QUFDckQsT0FBTyxFQUFDLHVCQUF1QixFQUFFLG1CQUFtQixFQUFDLE1BQU0sd0JBQXdCLENBQUM7QUFDcEYsT0FBTyxFQUFDLGNBQWMsRUFBRSxnQkFBZ0IsRUFBMEQsVUFBVSxFQUEwRCxNQUFNLG9CQUFvQixDQUFDO0FBSWpNLE9BQU8sRUFBQyxhQUFhLEVBQVMsUUFBUSxFQUFRLE1BQU0sb0JBQW9CLENBQUM7QUFDekUsT0FBTyxFQUFDLGlCQUFpQixFQUFFLGlCQUFpQixFQUFFLGNBQWMsRUFBRSxrQkFBa0IsRUFBRSxnQkFBZ0IsRUFBRSxnQkFBZ0IsRUFBRSxjQUFjLEVBQUMsTUFBTSxzQkFBc0IsQ0FBQztBQUNsSyxPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0sVUFBVSxDQUFDO0FBQ3pDLE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSx5QkFBeUIsQ0FBQztBQUN4RCxPQUFPLEVBQUMsZ0JBQWdCLEVBQUUsV0FBVyxFQUFDLE1BQU0sb0JBQW9CLENBQUM7QUFFakUsT0FBTyxFQUFDLFdBQVcsRUFBQyxNQUFNLGtCQUFrQixDQUFDO0FBQzdDLE9BQU8sRUFBQyxzQkFBc0IsRUFBRSw0QkFBNEIsRUFBRSx5QkFBeUIsRUFBRSxPQUFPLEVBQUMsTUFBTSxhQUFhLENBQUM7QUFJckg7Ozs7Ozs7Ozs7OztHQVlHO0FBQ0gsSUFBSSxVQUFVLEdBQUcsR0FBRyxDQUFDO0FBRXJCOzs7O0dBSUc7QUFDSCxJQUFJLGlCQUFpQixHQUFHLENBQUMsQ0FBQztBQUUxQjs7Ozs7O0dBTUc7QUFDSCxNQUFNLFVBQVUsVUFBVSxDQUFDLFNBQWtCO0lBQzNDLElBQUksU0FBUyxFQUFFO1FBQ2IsVUFBVSxHQUFHLFVBQVUsR0FBRyxDQUFDLENBQUMsSUFBSSxJQUFJLENBQUMsR0FBRyxDQUFDLGlCQUFpQixFQUFFLEVBQUUsQ0FBQyxDQUFDLENBQUM7S0FDbEU7SUFDRCxpQkFBaUIsRUFBRSxDQUFDO0FBQ3RCLENBQUM7QUFFRCxNQUFNLFVBQVUsU0FBUyxDQUFDLEtBQVksRUFBRSxLQUFZLEVBQUUsS0FBYTtJQUNqRSxJQUFJLGlCQUFpQixHQUFHLENBQUMsRUFBRTtRQUN6QixTQUFTLElBQUksYUFBYSxDQUFDLEtBQUssRUFBRSx5QkFBeUIsQ0FBQyxDQUFDO1FBQzdELE1BQU0sS0FBSyxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUE4QixDQUFDO1FBQzdELHVGQUF1RjtRQUN2RixNQUFNLGFBQWEsR0FDZixLQUFLLENBQUMsT0FBTyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUEwQixDQUFDLENBQUMsQ0FBRSxLQUFlLENBQUMsTUFBTSxDQUFDO1FBQ2hGLE1BQU0sa0JBQWtCLEdBQUcsZUFBZSxFQUFFLEdBQUcsaUJBQWlCLEdBQUcsQ0FBQyxDQUFDO1FBQ3JFLGtCQUFrQixDQUFDLEtBQUssRUFBRSxLQUFLLEVBQUUsYUFBYSxFQUFFLGtCQUFrQixFQUFFLFVBQVUsQ0FBQyxDQUFDO0tBQ2pGO0lBQ0Qsa0VBQWtFO0lBQ2xFLFVBQVUsR0FBRyxHQUFHLENBQUM7SUFDakIsaUJBQWlCLEdBQUcsQ0FBQyxDQUFDO0FBQ3hCLENBQUM7QUFHRDs7Ozs7Ozs7OztHQVVHO0FBQ0gsTUFBTSxVQUFVLGtCQUFrQixDQUM5QixLQUFZLEVBQUUsYUFBZ0MsRUFBRSxXQUEwQixFQUMxRSxlQUE4QjtJQUNoQyxNQUFNLFFBQVEsR0FBRyxLQUFLLENBQUMsUUFBUSxDQUFDLENBQUM7SUFDakMsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLGFBQWEsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7UUFDN0MsTUFBTSxNQUFNLEdBQUcsYUFBYSxDQUFDLENBQUMsRUFBRSxDQUFRLENBQUM7UUFDekMsTUFBTSxJQUFJLEdBQUcsYUFBYSxDQUFDLENBQUMsQ0FBVyxDQUFDO1FBQ3hDLE1BQU0sU0FBUyxHQUFHLENBQUMsTUFBTSxHQUFHLGdCQUFnQixDQUFDLE9BQU8sQ0FBQyxLQUFLLGdCQUFnQixDQUFDLE9BQU8sQ0FBQztRQUNuRixNQUFNLFNBQVMsR0FDWCxDQUFDLE1BQU0sR0FBRyxnQkFBZ0IsQ0FBQyxjQUFjLENBQUMsS0FBSyxnQkFBZ0IsQ0FBQyxjQUFjLENBQUM7UUFDbkYsTUFBTSxLQUFLLEdBQUcsTUFBTSxLQUFLLGdCQUFnQixDQUFDLEtBQUssQ0FBQztRQUNoRCxJQUFJLEtBQUssR0FBRyxLQUFLLENBQUMsS0FBSyxDQUFDLENBQUM7UUFDekIsSUFBSSxLQUFLLEtBQUssSUFBSSxFQUFFO1lBQ2xCLDJGQUEyRjtZQUMzRix3RUFBd0U7WUFDeEUsS0FBSyxHQUFHLEtBQUssQ0FBQyxLQUFLLENBQUM7Z0JBQ2hCLFNBQVMsQ0FBQyxDQUFDLENBQUMsUUFBUSxDQUFDLGFBQWEsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsY0FBYyxDQUFDLFFBQVEsRUFBRSxJQUFJLENBQUMsQ0FBQztTQUMvRTtRQUNELElBQUksU0FBUyxJQUFJLFdBQVcsS0FBSyxJQUFJLEVBQUU7WUFDckMsa0JBQWtCLENBQUMsUUFBUSxFQUFFLFdBQVcsRUFBRSxLQUFLLEVBQUUsZUFBZSxFQUFFLEtBQUssQ0FBQyxDQUFDO1NBQzFFO0tBQ0Y7QUFDSCxDQUFDO0FBRUQ7Ozs7Ozs7R0FPRztBQUNILE1BQU0sVUFBVSxtQkFBbUIsQ0FDL0IsS0FBWSxFQUFFLGNBQWdDLEVBQUUsS0FBWSxFQUFFLFdBQWtCO0lBQ2xGLFNBQVMsSUFBSSxhQUFhLENBQUMsV0FBVyxDQUFDLENBQUM7SUFDeEMsTUFBTSxRQUFRLEdBQUcsS0FBSyxDQUFDLFFBQVEsQ0FBQyxDQUFDO0lBQ2pDLCtEQUErRDtJQUMvRCxJQUFJLE9BQU8sR0FBZ0IsSUFBSSxDQUFDO0lBQ2hDLHdGQUF3RjtJQUN4RiwwQ0FBMEM7SUFDMUMsNkZBQTZGO0lBQzdGLGlDQUFpQztJQUNqQyx3RkFBd0Y7SUFDeEYsSUFBSSxTQUF5QixDQUFDO0lBQzlCLEtBQUssSUFBSSxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxjQUFjLENBQUMsTUFBTSxFQUFFLENBQUMsRUFBRSxFQUFFO1FBQzlDLE1BQU0sTUFBTSxHQUFHLGNBQWMsQ0FBQyxDQUFDLENBQUMsQ0FBQztRQUNqQyxJQUFJLE9BQU8sTUFBTSxJQUFJLFFBQVEsRUFBRTtZQUM3QixNQUFNLGFBQWEsR0FBRyxjQUFjLENBQUMsRUFBRSxDQUFDLENBQVcsQ0FBQztZQUNwRCxJQUFJLEtBQUssQ0FBQyxhQUFhLENBQUMsS0FBSyxJQUFJLEVBQUU7Z0JBQ2pDLFNBQVMsSUFBSSxTQUFTLENBQUMsc0JBQXNCLEVBQUUsQ0FBQztnQkFDaEQsU0FBUyxJQUFJLGtCQUFrQixDQUFDLEtBQUssRUFBRSxhQUFhLENBQUMsQ0FBQztnQkFDdEQsS0FBSyxDQUFDLGFBQWEsQ0FBQyxHQUFHLGNBQWMsQ0FBQyxRQUFRLEVBQUUsTUFBTSxDQUFDLENBQUM7YUFDekQ7U0FDRjthQUFNLElBQUksT0FBTyxNQUFNLElBQUksUUFBUSxFQUFFO1lBQ3BDLFFBQVEsTUFBTSwyQ0FBbUMsRUFBRTtnQkFDakQ7b0JBQ0UsTUFBTSxTQUFTLEdBQUcsNEJBQTRCLENBQUMsTUFBTSxDQUFDLENBQUM7b0JBQ3ZELElBQUksT0FBTyxLQUFLLElBQUksRUFBRTt3QkFDcEIsNEVBQTRFO3dCQUM1RSxtRkFBbUY7d0JBQ25GLFVBQVU7d0JBQ1YsT0FBTyxHQUFHLFNBQVMsQ0FBQzt3QkFDcEIsU0FBUyxHQUFHLGdCQUFnQixDQUFDLFFBQVEsRUFBRSxXQUFXLENBQUMsQ0FBQztxQkFDckQ7b0JBQ0QsSUFBSSxlQUEyQixDQUFDO29CQUNoQyxJQUFJLFdBQTBCLENBQUM7b0JBQy9CLElBQUksU0FBUyxLQUFLLE9BQU8sRUFBRTt3QkFDekIsZUFBZSxHQUFHLFdBQVcsQ0FBQzt3QkFDOUIsV0FBVyxHQUFHLFNBQVMsQ0FBQztxQkFDekI7eUJBQU07d0JBQ0wsZUFBZSxHQUFHLElBQUksQ0FBQzt3QkFDdkIsV0FBVyxHQUFHLFdBQVcsQ0FBQyxLQUFLLENBQUMsU0FBUyxDQUFDLENBQWEsQ0FBQztxQkFDekQ7b0JBQ0QsZ0RBQWdEO29CQUNoRCxJQUFJLFdBQVcsS0FBSyxJQUFJLEVBQUU7d0JBQ3hCLHVGQUF1Rjt3QkFDdkYsd0ZBQXdGO3dCQUN4Rix3RkFBd0Y7d0JBQ3hGLDJCQUEyQjt3QkFDM0IsU0FBUyxJQUFJLGFBQWEsQ0FBQyxXQUFXLENBQUMsQ0FBQzt3QkFDeEMsTUFBTSxNQUFNLEdBQUcseUJBQXlCLENBQUMsTUFBTSxDQUFDLENBQUM7d0JBQ2pELFNBQVMsSUFBSSxpQkFBaUIsQ0FBQyxNQUFNLEVBQUUsYUFBYSxFQUFFLGFBQWEsQ0FBQyxDQUFDO3dCQUNyRSx1RkFBdUY7d0JBQ3ZGLCtCQUErQjt3QkFDL0IsTUFBTSxLQUFLLEdBQUcsS0FBSyxDQUFDLE1BQU0sQ0FBYSxDQUFDO3dCQUN4QyxTQUFTLElBQUksYUFBYSxDQUFDLEtBQUssQ0FBQyxDQUFDO3dCQUNsQyxrQkFBa0IsQ0FBQyxRQUFRLEVBQUUsV0FBVyxFQUFFLEtBQUssRUFBRSxlQUFlLEVBQUUsS0FBSyxDQUFDLENBQUM7d0JBQ3pFLE1BQU0sSUFBSSxHQUFHLE9BQU8sQ0FBQyxLQUFLLEVBQUUsTUFBTSxDQUFDLENBQUM7d0JBQ3BDLElBQUksSUFBSSxLQUFLLElBQUksSUFBSSxPQUFPLElBQUksS0FBSyxRQUFRLEVBQUU7NEJBQzdDLG9GQUFvRjs0QkFDcEYsb0RBQW9EOzRCQUNwRCxTQUFTLElBQUksVUFBVSxDQUFDLElBQUksQ0FBQyxDQUFDOzRCQUM5QixNQUFNLFNBQVMsR0FBRyxzQkFBc0IsQ0FBQyxJQUFJLEVBQUUsS0FBSyxDQUFDLENBQUM7NEJBQ3RELElBQUksU0FBUyxLQUFLLElBQUksRUFBRTtnQ0FDdEIsbUJBQW1CLENBQUMsS0FBSyxFQUFFLElBQUksQ0FBQyxNQUFNLENBQUMsU0FBUyxDQUFDLEVBQUUsS0FBSyxFQUFFLEtBQUssQ0FBQyxJQUFJLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQzs2QkFDbEY7eUJBQ0Y7cUJBQ0Y7b0JBQ0QsTUFBTTtnQkFDUjtvQkFDRSxNQUFNLGdCQUFnQixHQUFHLE1BQU0sc0NBQThCLENBQUM7b0JBQzlELE1BQU0sUUFBUSxHQUFHLGNBQWMsQ0FBQyxFQUFFLENBQUMsQ0FBVyxDQUFDO29CQUMvQyxNQUFNLFNBQVMsR0FBRyxjQUFjLENBQUMsRUFBRSxDQUFDLENBQVcsQ0FBQztvQkFDaEQscUVBQXFFO29CQUNyRSwwRUFBMEU7b0JBQzFFLG1CQUFtQixDQUNmLFFBQVEsRUFBRSxnQkFBZ0IsQ0FBQyxnQkFBZ0IsRUFBRSxLQUFLLENBQWEsRUFBRSxJQUFJLEVBQUUsSUFBSSxFQUFFLFFBQVEsRUFDckYsU0FBUyxFQUFFLElBQUksQ0FBQyxDQUFDO29CQUNyQixNQUFNO2dCQUNSO29CQUNFLElBQUksU0FBUyxFQUFFO3dCQUNiLE1BQU0sSUFBSSxZQUFZLG9EQUVsQix5REFBeUQsTUFBTSxHQUFHLENBQUMsQ0FBQztxQkFDekU7YUFDSjtTQUNGO2FBQU07WUFDTCxRQUFRLE1BQU0sRUFBRTtnQkFDZCxLQUFLLFVBQVU7b0JBQ2IsTUFBTSxZQUFZLEdBQUcsY0FBYyxDQUFDLEVBQUUsQ0FBQyxDQUFXLENBQUM7b0JBQ25ELE1BQU0sZ0JBQWdCLEdBQUcsY0FBYyxDQUFDLEVBQUUsQ0FBQyxDQUFXLENBQUM7b0JBQ3ZELElBQUksS0FBSyxDQUFDLGdCQUFnQixDQUFDLEtBQUssSUFBSSxFQUFFO3dCQUNwQyxTQUFTOzRCQUNMLFdBQVcsQ0FDUCxPQUFPLFlBQVksRUFBRSxRQUFRLEVBQzdCLGFBQWEsWUFBWSw4QkFBOEIsQ0FBQyxDQUFDO3dCQUNqRSxTQUFTLElBQUksU0FBUyxDQUFDLHFCQUFxQixFQUFFLENBQUM7d0JBQy9DLFNBQVMsSUFBSSx5QkFBeUIsQ0FBQyxLQUFLLEVBQUUsZ0JBQWdCLENBQUMsQ0FBQzt3QkFDaEUsTUFBTSxZQUFZLEdBQUcsS0FBSyxDQUFDLGdCQUFnQixDQUFDOzRCQUN4QyxpQkFBaUIsQ0FBQyxRQUFRLEVBQUUsWUFBWSxDQUFDLENBQUM7d0JBQzlDLGtGQUFrRjt3QkFDbEYsZUFBZSxDQUFDLFlBQVksRUFBRSxLQUFLLENBQUMsQ0FBQztxQkFDdEM7b0JBQ0QsTUFBTTtnQkFDUixLQUFLLGNBQWM7b0JBQ2pCLE1BQU0sT0FBTyxHQUFHLGNBQWMsQ0FBQyxFQUFFLENBQUMsQ0FBVyxDQUFDO29CQUM5QyxNQUFNLGdCQUFnQixHQUFHLGNBQWMsQ0FBQyxFQUFFLENBQUMsQ0FBVyxDQUFDO29CQUN2RCxJQUFJLEtBQUssQ0FBQyxnQkFBZ0IsQ0FBQyxLQUFLLElBQUksRUFBRTt3QkFDcEMsU0FBUzs0QkFDTCxXQUFXLENBQ1AsT0FBTyxPQUFPLEVBQUUsUUFBUSxFQUN4QixhQUFhLE9BQU8sa0NBQWtDLENBQUMsQ0FBQzt3QkFFaEUsU0FBUyxJQUFJLFNBQVMsQ0FBQyxxQkFBcUIsRUFBRSxDQUFDO3dCQUMvQyxTQUFTLElBQUkseUJBQXlCLENBQUMsS0FBSyxFQUFFLGdCQUFnQixDQUFDLENBQUM7d0JBQ2hFLE1BQU0sWUFBWSxHQUFHLEtBQUssQ0FBQyxnQkFBZ0IsQ0FBQzs0QkFDeEMsaUJBQWlCLENBQUMsUUFBUSxFQUFFLE9BQU8sRUFBRSxJQUFJLENBQUMsQ0FBQzt3QkFDL0Msa0ZBQWtGO3dCQUNsRixlQUFlLENBQUMsWUFBWSxFQUFFLEtBQUssQ0FBQyxDQUFDO3FCQUN0QztvQkFDRCxNQUFNO2dCQUNSO29CQUNFLFNBQVM7d0JBQ0wsVUFBVSxDQUFDLHlEQUF5RCxNQUFNLEdBQUcsQ0FBQyxDQUFDO2FBQ3RGO1NBQ0Y7S0FDRjtBQUNILENBQUM7QUFHRDs7Ozs7Ozs7O0dBU0c7QUFDSCxNQUFNLFVBQVUsa0JBQWtCLENBQzlCLEtBQVksRUFBRSxLQUFZLEVBQUUsYUFBZ0MsRUFBRSxrQkFBMEIsRUFDeEYsVUFBa0I7SUFDcEIsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLGFBQWEsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7UUFDN0MsdURBQXVEO1FBQ3ZELE1BQU0sUUFBUSxHQUFHLGFBQWEsQ0FBQyxDQUFDLENBQVcsQ0FBQztRQUM1QywyREFBMkQ7UUFDM0QsTUFBTSxTQUFTLEdBQUcsYUFBYSxDQUFDLEVBQUUsQ0FBQyxDQUFXLENBQUM7UUFDL0MsSUFBSSxRQUFRLEdBQUcsVUFBVSxFQUFFO1lBQ3pCLGdEQUFnRDtZQUNoRCxJQUFJLEtBQUssR0FBRyxFQUFFLENBQUM7WUFDZixLQUFLLElBQUksQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxJQUFJLENBQUMsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxFQUFFLENBQUMsRUFBRSxFQUFFO2dCQUM3QyxNQUFNLE1BQU0sR0FBRyxhQUFhLENBQUMsQ0FBQyxDQUFDLENBQUM7Z0JBQ2hDLElBQUksT0FBTyxNQUFNLElBQUksUUFBUSxFQUFFO29CQUM3QixLQUFLLElBQUksTUFBTSxDQUFDO2lCQUNqQjtxQkFBTSxJQUFJLE9BQU8sTUFBTSxJQUFJLFFBQVEsRUFBRTtvQkFDcEMsSUFBSSxNQUFNLEdBQUcsQ0FBQyxFQUFFO3dCQUNkLHFEQUFxRDt3QkFDckQsS0FBSyxJQUFJLGVBQWUsQ0FBQyxLQUFLLENBQUMsa0JBQWtCLEdBQUcsTUFBTSxDQUFDLENBQUMsQ0FBQztxQkFDOUQ7eUJBQU07d0JBQ0wsTUFBTSxTQUFTLEdBQUcsQ0FBQyxNQUFNLHVDQUErQixDQUFDLENBQUM7d0JBQzFELFFBQVEsTUFBTSx1Q0FBK0IsRUFBRTs0QkFDN0M7Z0NBQ0UsTUFBTSxRQUFRLEdBQUcsYUFBYSxDQUFDLEVBQUUsQ0FBQyxDQUFXLENBQUM7Z0NBQzlDLE1BQU0sVUFBVSxHQUFHLGFBQWEsQ0FBQyxFQUFFLENBQUMsQ0FBdUIsQ0FBQztnQ0FDNUQsTUFBTSxjQUFjLEdBQUcsS0FBSyxDQUFDLElBQUksQ0FBQyxTQUFTLENBQW1CLENBQUM7Z0NBQy9ELFNBQVMsSUFBSSxhQUFhLENBQUMsY0FBYyxFQUFFLDJCQUEyQixDQUFDLENBQUM7Z0NBQ3hFLElBQUksT0FBTyxjQUFjLEtBQUssUUFBUSxFQUFFO29DQUN0QyxpRkFBaUY7b0NBQ2pGLGlGQUFpRjtvQ0FDakYsNEJBQTRCO29DQUM1QixtQkFBbUIsQ0FDZixLQUFLLENBQUMsUUFBUSxDQUFDLEVBQUUsS0FBSyxDQUFDLFNBQVMsQ0FBQyxFQUFFLElBQUksRUFBRSxjQUFjLEVBQUUsUUFBUSxFQUFFLEtBQUssRUFDeEUsVUFBVSxDQUFDLENBQUM7aUNBQ2pCO3FDQUFNO29DQUNMLHVCQUF1QixDQUNuQixLQUFLLEVBQUUsY0FBYyxFQUFFLEtBQUssRUFBRSxRQUFRLEVBQUUsS0FBSyxFQUFFLEtBQUssQ0FBQyxRQUFRLENBQUMsRUFBRSxVQUFVLEVBQzFFLEtBQUssQ0FBQyxDQUFDO2lDQUNaO2dDQUNELE1BQU07NEJBQ1I7Z0NBQ0UsTUFBTSxLQUFLLEdBQUcsS0FBSyxDQUFDLFNBQVMsQ0FBaUIsQ0FBQztnQ0FDL0MsS0FBSyxLQUFLLElBQUksSUFBSSxjQUFjLENBQUMsS0FBSyxDQUFDLFFBQVEsQ0FBQyxFQUFFLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztnQ0FDaEUsTUFBTTs0QkFDUjtnQ0FDRSxrQkFBa0IsQ0FBQyxLQUFLLEVBQUUsT0FBTyxDQUFDLEtBQUssRUFBRSxTQUFTLENBQUUsRUFBRSxLQUFLLEVBQUUsS0FBSyxDQUFDLENBQUM7Z0NBQ3BFLE1BQU07NEJBQ1I7Z0NBQ0Usa0JBQWtCLENBQUMsS0FBSyxFQUFFLE9BQU8sQ0FBQyxLQUFLLEVBQUUsU0FBUyxDQUFFLEVBQUUsa0JBQWtCLEVBQUUsS0FBSyxDQUFDLENBQUM7Z0NBQ2pGLE1BQU07eUJBQ1Q7cUJBQ0Y7aUJBQ0Y7YUFDRjtTQUNGO2FBQU07WUFDTCxNQUFNLE1BQU0sR0FBRyxhQUFhLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBVyxDQUFDO1lBQzlDLElBQUksTUFBTSxHQUFHLENBQUMsSUFBSSxDQUFDLE1BQU0sdUNBQStCLENBQUMsdUNBQStCLEVBQUU7Z0JBQ3hGLHFGQUFxRjtnQkFDckYsd0ZBQXdGO2dCQUN4Riw0RkFBNEY7Z0JBQzVGLFVBQVU7Z0JBQ1YsTUFBTSxTQUFTLEdBQUcsQ0FBQyxNQUFNLHVDQUErQixDQUFDLENBQUM7Z0JBQzFELE1BQU0sSUFBSSxHQUFHLE9BQU8sQ0FBQyxLQUFLLEVBQUUsU0FBUyxDQUFFLENBQUM7Z0JBQ3hDLE1BQU0sWUFBWSxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUMscUJBQXFCLENBQUMsQ0FBQztnQkFDdkQsSUFBSSxZQUFZLEdBQUcsQ0FBQyxFQUFFO29CQUNwQixrQkFBa0IsQ0FBQyxLQUFLLEVBQUUsSUFBSSxFQUFFLGtCQUFrQixFQUFFLEtBQUssQ0FBQyxDQUFDO2lCQUM1RDthQUNGO1NBQ0Y7UUFDRCxDQUFDLElBQUksU0FBUyxDQUFDO0tBQ2hCO0FBQ0gsQ0FBQztBQUVEOzs7Ozs7O0dBT0c7QUFDSCxTQUFTLGtCQUFrQixDQUFDLEtBQVksRUFBRSxJQUFVLEVBQUUsa0JBQTBCLEVBQUUsS0FBWTtJQUM1RixTQUFTLElBQUksa0JBQWtCLENBQUMsS0FBSyxFQUFFLElBQUksQ0FBQyxxQkFBcUIsQ0FBQyxDQUFDO0lBQ25FLElBQUksZUFBZSxHQUFHLEtBQUssQ0FBQyxJQUFJLENBQUMscUJBQXFCLENBQUMsQ0FBQztJQUN4RCxJQUFJLGVBQWUsS0FBSyxJQUFJLEVBQUU7UUFDNUIsSUFBSSxJQUFJLEdBQUcsVUFBVSxDQUFDO1FBQ3RCLElBQUksZUFBZSxHQUFHLENBQUMsRUFBRTtZQUN2QixrQkFBa0I7WUFDbEIsMEZBQTBGO1lBQzFGLGVBQWUsR0FBRyxLQUFLLENBQUMsSUFBSSxDQUFDLHFCQUFxQixDQUFDLEdBQUcsQ0FBQyxlQUFlLENBQUM7WUFDdkUsb0ZBQW9GO1lBQ3BGLElBQUksR0FBRyxDQUFDLENBQUMsQ0FBQztTQUNYO1FBQ0Qsa0JBQWtCLENBQUMsS0FBSyxFQUFFLEtBQUssRUFBRSxJQUFJLENBQUMsTUFBTSxDQUFDLGVBQWUsQ0FBQyxFQUFFLGtCQUFrQixFQUFFLElBQUksQ0FBQyxDQUFDO0tBQzFGO0FBQ0gsQ0FBQztBQUVEOzs7Ozs7Ozs7R0FTRztBQUNILFNBQVMsa0JBQWtCLENBQUMsS0FBWSxFQUFFLElBQVUsRUFBRSxLQUFZLEVBQUUsS0FBYTtJQUMvRSxrQ0FBa0M7SUFDbEMsTUFBTSxTQUFTLEdBQUcsWUFBWSxDQUFDLElBQUksRUFBRSxLQUFLLENBQUMsQ0FBQztJQUM1QyxJQUFJLGVBQWUsR0FBRyxzQkFBc0IsQ0FBQyxJQUFJLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDMUQsSUFBSSxlQUFlLEtBQUssU0FBUyxFQUFFO1FBQ2pDLHdCQUF3QixDQUFDLEtBQUssRUFBRSxJQUFJLEVBQUUsS0FBSyxDQUFDLENBQUM7UUFDN0MsS0FBSyxDQUFDLElBQUksQ0FBQyxxQkFBcUIsQ0FBQyxHQUFHLFNBQVMsS0FBSyxJQUFJLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUM7UUFDM0UsSUFBSSxTQUFTLEtBQUssSUFBSSxFQUFFO1lBQ3RCLGlDQUFpQztZQUNqQyxNQUFNLFdBQVcsR0FBRyxLQUFLLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDO1lBQzFDLElBQUksV0FBVyxFQUFFO2dCQUNmLFNBQVMsSUFBSSxhQUFhLENBQUMsV0FBVyxDQUFDLENBQUM7Z0JBQ3hDLG1CQUFtQixDQUFDLEtBQUssRUFBRSxJQUFJLENBQUMsTUFBTSxDQUFDLFNBQVMsQ0FBQyxFQUFFLEtBQUssRUFBRSxXQUFXLENBQUMsQ0FBQzthQUN4RTtTQUNGO0tBQ0Y7QUFDSCxDQUFDO0FBRUQ7Ozs7Ozs7O0dBUUc7QUFDSCxTQUFTLHdCQUF3QixDQUFDLEtBQVksRUFBRSxJQUFVLEVBQUUsS0FBWTtJQUN0RSxJQUFJLGVBQWUsR0FBRyxzQkFBc0IsQ0FBQyxJQUFJLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDMUQsSUFBSSxlQUFlLEtBQUssSUFBSSxFQUFFO1FBQzVCLE1BQU0sV0FBVyxHQUFHLElBQUksQ0FBQyxNQUFNLENBQUMsZUFBZSxDQUFDLENBQUM7UUFDakQsS0FBSyxJQUFJLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLFdBQVcsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUU7WUFDM0MsTUFBTSxjQUFjLEdBQUcsV0FBVyxDQUFDLENBQUMsQ0FBVyxDQUFDO1lBQ2hELElBQUksY0FBYyxHQUFHLENBQUMsRUFBRTtnQkFDdEIsaUNBQWlDO2dCQUNqQyxNQUFNLEtBQUssR0FBRyxnQkFBZ0IsQ0FBQyxjQUFjLEVBQUUsS0FBSyxDQUFDLENBQUM7Z0JBQ3RELEtBQUssS0FBSyxJQUFJLElBQUksZ0JBQWdCLENBQUMsS0FBSyxDQUFDLFFBQVEsQ0FBQyxFQUFFLEtBQUssQ0FBQyxDQUFDO2FBQzVEO2lCQUFNO2dCQUNMLDRCQUE0QjtnQkFDNUIsd0JBQXdCLENBQUMsS0FBSyxFQUFFLE9BQU8sQ0FBQyxLQUFLLEVBQUUsQ0FBQyxjQUFjLENBQUUsRUFBRSxLQUFLLENBQUMsQ0FBQzthQUMxRTtTQUNGO0tBQ0Y7QUFDSCxDQUFDO0FBR0Q7Ozs7O0dBS0c7QUFDSCxTQUFTLFlBQVksQ0FBQyxhQUFtQixFQUFFLFlBQW9CO0lBQzdELElBQUksS0FBSyxHQUFHLGFBQWEsQ0FBQyxLQUFLLENBQUMsT0FBTyxDQUFDLFlBQVksQ0FBQyxDQUFDO0lBQ3RELElBQUksS0FBSyxLQUFLLENBQUMsQ0FBQyxFQUFFO1FBQ2hCLFFBQVEsYUFBYSxDQUFDLElBQUksRUFBRTtZQUMxQiwyQkFBbUIsQ0FBQyxDQUFDO2dCQUNuQixNQUFNLFlBQVksR0FBRyxhQUFhLENBQUMsWUFBWSxFQUFFLFdBQVcsRUFBRSxDQUFDLENBQUM7Z0JBQ2hFLEtBQUssR0FBRyxhQUFhLENBQUMsS0FBSyxDQUFDLE9BQU8sQ0FBQyxZQUFZLENBQUMsQ0FBQztnQkFDbEQsSUFBSSxLQUFLLEtBQUssQ0FBQyxDQUFDLElBQUksWUFBWSxLQUFLLE9BQU8sRUFBRTtvQkFDNUMsS0FBSyxHQUFHLGFBQWEsQ0FBQyxLQUFLLENBQUMsT0FBTyxDQUFDLE9BQU8sQ0FBQyxDQUFDO2lCQUM5QztnQkFDRCxNQUFNO2FBQ1A7WUFDRCwyQkFBbUIsQ0FBQyxDQUFDO2dCQUNuQixLQUFLLEdBQUcsYUFBYSxDQUFDLEtBQUssQ0FBQyxPQUFPLENBQUMsT0FBTyxDQUFDLENBQUM7Z0JBQzdDLE1BQU07YUFDUDtTQUNGO0tBQ0Y7SUFDRCxPQUFPLEtBQUssS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUM7QUFDckMsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge1J1bnRpbWVFcnJvciwgUnVudGltZUVycm9yQ29kZX0gZnJvbSAnLi4vLi4vZXJyb3JzJztcbmltcG9ydCB7Z2V0UGx1cmFsQ2FzZX0gZnJvbSAnLi4vLi4vaTE4bi9sb2NhbGl6YXRpb24nO1xuaW1wb3J0IHthc3NlcnREZWZpbmVkLCBhc3NlcnREb21Ob2RlLCBhc3NlcnRFcXVhbCwgYXNzZXJ0R3JlYXRlclRoYW4sIGFzc2VydEluZGV4SW5SYW5nZSwgdGhyb3dFcnJvcn0gZnJvbSAnLi4vLi4vdXRpbC9hc3NlcnQnO1xuaW1wb3J0IHthc3NlcnRJbmRleEluRXhwYW5kb1JhbmdlLCBhc3NlcnRUSWN1fSBmcm9tICcuLi9hc3NlcnQnO1xuaW1wb3J0IHthdHRhY2hQYXRjaERhdGF9IGZyb20gJy4uL2NvbnRleHRfZGlzY292ZXJ5JztcbmltcG9ydCB7ZWxlbWVudFByb3BlcnR5SW50ZXJuYWwsIHNldEVsZW1lbnRBdHRyaWJ1dGV9IGZyb20gJy4uL2luc3RydWN0aW9ucy9zaGFyZWQnO1xuaW1wb3J0IHtFTEVNRU5UX01BUktFUiwgSTE4bkNyZWF0ZU9wQ29kZSwgSTE4bkNyZWF0ZU9wQ29kZXMsIEkxOG5VcGRhdGVPcENvZGUsIEkxOG5VcGRhdGVPcENvZGVzLCBJQ1VfTUFSS0VSLCBJY3VDcmVhdGVPcENvZGUsIEljdUNyZWF0ZU9wQ29kZXMsIEljdVR5cGUsIFRJMThuLCBUSWN1fSBmcm9tICcuLi9pbnRlcmZhY2VzL2kxOG4nO1xuaW1wb3J0IHtUTm9kZX0gZnJvbSAnLi4vaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7UkVsZW1lbnQsIFJOb2RlLCBSVGV4dH0gZnJvbSAnLi4vaW50ZXJmYWNlcy9yZW5kZXJlcl9kb20nO1xuaW1wb3J0IHtTYW5pdGl6ZXJGbn0gZnJvbSAnLi4vaW50ZXJmYWNlcy9zYW5pdGl6YXRpb24nO1xuaW1wb3J0IHtIRUFERVJfT0ZGU0VULCBMVmlldywgUkVOREVSRVIsIFRWaWV3fSBmcm9tICcuLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtjcmVhdGVDb21tZW50Tm9kZSwgY3JlYXRlRWxlbWVudE5vZGUsIGNyZWF0ZVRleHROb2RlLCBuYXRpdmVJbnNlcnRCZWZvcmUsIG5hdGl2ZVBhcmVudE5vZGUsIG5hdGl2ZVJlbW92ZU5vZGUsIHVwZGF0ZVRleHROb2RlfSBmcm9tICcuLi9ub2RlX21hbmlwdWxhdGlvbic7XG5pbXBvcnQge2dldEJpbmRpbmdJbmRleH0gZnJvbSAnLi4vc3RhdGUnO1xuaW1wb3J0IHtyZW5kZXJTdHJpbmdpZnl9IGZyb20gJy4uL3V0aWwvc3RyaW5naWZ5X3V0aWxzJztcbmltcG9ydCB7Z2V0TmF0aXZlQnlJbmRleCwgdW53cmFwUk5vZGV9IGZyb20gJy4uL3V0aWwvdmlld191dGlscyc7XG5cbmltcG9ydCB7Z2V0TG9jYWxlSWR9IGZyb20gJy4vaTE4bl9sb2NhbGVfaWQnO1xuaW1wb3J0IHtnZXRDdXJyZW50SUNVQ2FzZUluZGV4LCBnZXRQYXJlbnRGcm9tSWN1Q3JlYXRlT3BDb2RlLCBnZXRSZWZGcm9tSWN1Q3JlYXRlT3BDb2RlLCBnZXRUSWN1fSBmcm9tICcuL2kxOG5fdXRpbCc7XG5cblxuXG4vKipcbiAqIEtlZXAgdHJhY2sgb2Ygd2hpY2ggaW5wdXQgYmluZGluZ3MgaW4gYMm1ybVpMThuRXhwYCBoYXZlIGNoYW5nZWQuXG4gKlxuICogVGhpcyBpcyB1c2VkIHRvIGVmZmljaWVudGx5IHVwZGF0ZSBleHByZXNzaW9ucyBpbiBpMThuIG9ubHkgd2hlbiB0aGUgY29ycmVzcG9uZGluZyBpbnB1dCBoYXNcbiAqIGNoYW5nZWQuXG4gKlxuICogMSkgRWFjaCBiaXQgcmVwcmVzZW50cyB3aGljaCBvZiB0aGUgYMm1ybVpMThuRXhwYCBoYXMgY2hhbmdlZC5cbiAqIDIpIFRoZXJlIGFyZSAzMiBiaXRzIGFsbG93ZWQgaW4gSlMuXG4gKiAzKSBCaXQgMzIgaXMgc3BlY2lhbCBhcyBpdCBpcyBzaGFyZWQgZm9yIGFsbCBjaGFuZ2VzIHBhc3QgMzIuIChJbiBvdGhlciB3b3JkcyBpZiB5b3UgaGF2ZSBtb3JlXG4gKiB0aGFuIDMyIGDJtcm1aTE4bkV4cGAgdGhlbiBhbGwgY2hhbmdlcyBwYXN0IDMybmQgYMm1ybVpMThuRXhwYCB3aWxsIGJlIG1hcHBlZCB0byBzYW1lIGJpdC4gVGhpcyBtZWFuc1xuICogdGhhdCB3ZSBtYXkgZW5kIHVwIGNoYW5naW5nIG1vcmUgdGhhbiB3ZSBuZWVkIHRvLiBCdXQgaTE4biBleHByZXNzaW9ucyB3aXRoIDMyIGJpbmRpbmdzIGlzIHJhcmVcbiAqIHNvIGluIHByYWN0aWNlIGl0IHNob3VsZCBub3QgYmUgYW4gaXNzdWUuKVxuICovXG5sZXQgY2hhbmdlTWFzayA9IDBiMDtcblxuLyoqXG4gKiBLZWVwcyB0cmFjayBvZiB3aGljaCBiaXQgbmVlZHMgdG8gYmUgdXBkYXRlZCBpbiBgY2hhbmdlTWFza2BcbiAqXG4gKiBUaGlzIHZhbHVlIGdldHMgaW5jcmVtZW50ZWQgb24gZXZlcnkgY2FsbCB0byBgybXJtWkxOG5FeHBgXG4gKi9cbmxldCBjaGFuZ2VNYXNrQ291bnRlciA9IDA7XG5cbi8qKlxuICogS2VlcCB0cmFjayBvZiB3aGljaCBpbnB1dCBiaW5kaW5ncyBpbiBgybXJtWkxOG5FeHBgIGhhdmUgY2hhbmdlZC5cbiAqXG4gKiBgc2V0TWFza0JpdGAgZ2V0cyBpbnZva2VkIGJ5IGVhY2ggY2FsbCB0byBgybXJtWkxOG5FeHBgLlxuICpcbiAqIEBwYXJhbSBoYXNDaGFuZ2UgZGlkIGDJtcm1aTE4bkV4cGAgZGV0ZWN0IGEgY2hhbmdlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gc2V0TWFza0JpdChoYXNDaGFuZ2U6IGJvb2xlYW4pIHtcbiAgaWYgKGhhc0NoYW5nZSkge1xuICAgIGNoYW5nZU1hc2sgPSBjaGFuZ2VNYXNrIHwgKDEgPDwgTWF0aC5taW4oY2hhbmdlTWFza0NvdW50ZXIsIDMxKSk7XG4gIH1cbiAgY2hhbmdlTWFza0NvdW50ZXIrKztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGFwcGx5STE4bih0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgaW5kZXg6IG51bWJlcikge1xuICBpZiAoY2hhbmdlTWFza0NvdW50ZXIgPiAwKSB7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQodFZpZXcsIGB0VmlldyBzaG91bGQgYmUgZGVmaW5lZGApO1xuICAgIGNvbnN0IHRJMThuID0gdFZpZXcuZGF0YVtpbmRleF0gYXMgVEkxOG4gfCBJMThuVXBkYXRlT3BDb2RlcztcbiAgICAvLyBXaGVuIGBpbmRleGAgcG9pbnRzIHRvIGFuIGDJtcm1aTE4bkF0dHJpYnV0ZXNgIHRoZW4gd2UgaGF2ZSBhbiBhcnJheSBvdGhlcndpc2UgYFRJMThuYFxuICAgIGNvbnN0IHVwZGF0ZU9wQ29kZXM6IEkxOG5VcGRhdGVPcENvZGVzID1cbiAgICAgICAgQXJyYXkuaXNBcnJheSh0STE4bikgPyB0STE4biBhcyBJMThuVXBkYXRlT3BDb2RlcyA6ICh0STE4biBhcyBUSTE4bikudXBkYXRlO1xuICAgIGNvbnN0IGJpbmRpbmdzU3RhcnRJbmRleCA9IGdldEJpbmRpbmdJbmRleCgpIC0gY2hhbmdlTWFza0NvdW50ZXIgLSAxO1xuICAgIGFwcGx5VXBkYXRlT3BDb2Rlcyh0VmlldywgbFZpZXcsIHVwZGF0ZU9wQ29kZXMsIGJpbmRpbmdzU3RhcnRJbmRleCwgY2hhbmdlTWFzayk7XG4gIH1cbiAgLy8gUmVzZXQgY2hhbmdlTWFzayAmIG1hc2tCaXQgdG8gZGVmYXVsdCBmb3IgdGhlIG5leHQgdXBkYXRlIGN5Y2xlXG4gIGNoYW5nZU1hc2sgPSAwYjA7XG4gIGNoYW5nZU1hc2tDb3VudGVyID0gMDtcbn1cblxuXG4vKipcbiAqIEFwcGx5IGBJMThuQ3JlYXRlT3BDb2Rlc2Agb3AtY29kZXMgYXMgc3RvcmVkIGluIGBUSTE4bi5jcmVhdGVgLlxuICpcbiAqIENyZWF0ZXMgdGV4dCAoYW5kIGNvbW1lbnQpIG5vZGVzIHdoaWNoIGFyZSBpbnRlcm5hdGlvbmFsaXplZC5cbiAqXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBsVmlld1xuICogQHBhcmFtIGNyZWF0ZU9wQ29kZXMgU2V0IG9mIG9wLWNvZGVzIHRvIGFwcGx5XG4gKiBAcGFyYW0gcGFyZW50Uk5vZGUgUGFyZW50IG5vZGUgKHNvIHRoYXQgZGlyZWN0IGNoaWxkcmVuIGNhbiBiZSBhZGRlZCBlYWdlcmx5KSBvciBgbnVsbGAgaWYgaXQgaXNcbiAqICAgICBhIHJvb3Qgbm9kZS5cbiAqIEBwYXJhbSBpbnNlcnRJbkZyb250T2YgRE9NIG5vZGUgdGhhdCBzaG91bGQgYmUgdXNlZCBhcyBhbiBhbmNob3IuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhcHBseUNyZWF0ZU9wQ29kZXMoXG4gICAgbFZpZXc6IExWaWV3LCBjcmVhdGVPcENvZGVzOiBJMThuQ3JlYXRlT3BDb2RlcywgcGFyZW50Uk5vZGU6IFJFbGVtZW50fG51bGwsXG4gICAgaW5zZXJ0SW5Gcm9udE9mOiBSRWxlbWVudHxudWxsKTogdm9pZCB7XG4gIGNvbnN0IHJlbmRlcmVyID0gbFZpZXdbUkVOREVSRVJdO1xuICBmb3IgKGxldCBpID0gMDsgaSA8IGNyZWF0ZU9wQ29kZXMubGVuZ3RoOyBpKyspIHtcbiAgICBjb25zdCBvcENvZGUgPSBjcmVhdGVPcENvZGVzW2krK10gYXMgYW55O1xuICAgIGNvbnN0IHRleHQgPSBjcmVhdGVPcENvZGVzW2ldIGFzIHN0cmluZztcbiAgICBjb25zdCBpc0NvbW1lbnQgPSAob3BDb2RlICYgSTE4bkNyZWF0ZU9wQ29kZS5DT01NRU5UKSA9PT0gSTE4bkNyZWF0ZU9wQ29kZS5DT01NRU5UO1xuICAgIGNvbnN0IGFwcGVuZE5vdyA9XG4gICAgICAgIChvcENvZGUgJiBJMThuQ3JlYXRlT3BDb2RlLkFQUEVORF9FQUdFUkxZKSA9PT0gSTE4bkNyZWF0ZU9wQ29kZS5BUFBFTkRfRUFHRVJMWTtcbiAgICBjb25zdCBpbmRleCA9IG9wQ29kZSA+Pj4gSTE4bkNyZWF0ZU9wQ29kZS5TSElGVDtcbiAgICBsZXQgck5vZGUgPSBsVmlld1tpbmRleF07XG4gICAgaWYgKHJOb2RlID09PSBudWxsKSB7XG4gICAgICAvLyBXZSBvbmx5IGNyZWF0ZSBuZXcgRE9NIG5vZGVzIGlmIHRoZXkgZG9uJ3QgYWxyZWFkeSBleGlzdDogSWYgSUNVIHN3aXRjaGVzIGNhc2UgYmFjayB0byBhXG4gICAgICAvLyBjYXNlIHdoaWNoIHdhcyBhbHJlYWR5IGluc3RhbnRpYXRlZCwgbm8gbmVlZCB0byBjcmVhdGUgbmV3IERPTSBub2Rlcy5cbiAgICAgIHJOb2RlID0gbFZpZXdbaW5kZXhdID1cbiAgICAgICAgICBpc0NvbW1lbnQgPyByZW5kZXJlci5jcmVhdGVDb21tZW50KHRleHQpIDogY3JlYXRlVGV4dE5vZGUocmVuZGVyZXIsIHRleHQpO1xuICAgIH1cbiAgICBpZiAoYXBwZW5kTm93ICYmIHBhcmVudFJOb2RlICE9PSBudWxsKSB7XG4gICAgICBuYXRpdmVJbnNlcnRCZWZvcmUocmVuZGVyZXIsIHBhcmVudFJOb2RlLCByTm9kZSwgaW5zZXJ0SW5Gcm9udE9mLCBmYWxzZSk7XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogQXBwbHkgYEkxOG5NdXRhdGVPcENvZGVzYCBPcENvZGVzLlxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2BcbiAqIEBwYXJhbSBtdXRhYmxlT3BDb2RlcyBNdXRhYmxlIE9wQ29kZXMgdG8gcHJvY2Vzc1xuICogQHBhcmFtIGxWaWV3IEN1cnJlbnQgYExWaWV3YFxuICogQHBhcmFtIGFuY2hvclJOb2RlIHBsYWNlIHdoZXJlIHRoZSBpMThuIG5vZGUgc2hvdWxkIGJlIGluc2VydGVkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gYXBwbHlNdXRhYmxlT3BDb2RlcyhcbiAgICB0VmlldzogVFZpZXcsIG11dGFibGVPcENvZGVzOiBJY3VDcmVhdGVPcENvZGVzLCBsVmlldzogTFZpZXcsIGFuY2hvclJOb2RlOiBSTm9kZSk6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RG9tTm9kZShhbmNob3JSTm9kZSk7XG4gIGNvbnN0IHJlbmRlcmVyID0gbFZpZXdbUkVOREVSRVJdO1xuICAvLyBgcm9vdElkeGAgcmVwcmVzZW50cyB0aGUgbm9kZSBpbnRvIHdoaWNoIGFsbCBpbnNlcnRzIGhhcHBlbi5cbiAgbGV0IHJvb3RJZHg6IG51bWJlcnxudWxsID0gbnVsbDtcbiAgLy8gYHJvb3RSTm9kZWAgcmVwcmVzZW50cyB0aGUgcmVhbCBub2RlIGludG8gd2hpY2ggd2UgaW5zZXJ0LiBUaGlzIGNhbiBiZSBkaWZmZXJlbnQgZnJvbVxuICAvLyBgbFZpZXdbcm9vdElkeF1gIGlmIHdlIGhhdmUgcHJvamVjdGlvbi5cbiAgLy8gIC0gbnVsbCB3ZSBkb24ndCBoYXZlIGEgcGFyZW50IChhcyBjYW4gYmUgdGhlIGNhc2UgaW4gd2hlbiB3ZSBhcmUgaW5zZXJ0aW5nIGludG8gYSByb290IG9mXG4gIC8vICAgIExWaWV3IHdoaWNoIGhhcyBubyBwYXJlbnQuKVxuICAvLyAgLSBgUkVsZW1lbnRgIFRoZSBlbGVtZW50IHJlcHJlc2VudGluZyB0aGUgcm9vdCBhZnRlciB0YWtpbmcgcHJvamVjdGlvbiBpbnRvIGFjY291bnQuXG4gIGxldCByb290Uk5vZGUhOiBSRWxlbWVudHxudWxsO1xuICBmb3IgKGxldCBpID0gMDsgaSA8IG11dGFibGVPcENvZGVzLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3Qgb3BDb2RlID0gbXV0YWJsZU9wQ29kZXNbaV07XG4gICAgaWYgKHR5cGVvZiBvcENvZGUgPT0gJ3N0cmluZycpIHtcbiAgICAgIGNvbnN0IHRleHROb2RlSW5kZXggPSBtdXRhYmxlT3BDb2Rlc1srK2ldIGFzIG51bWJlcjtcbiAgICAgIGlmIChsVmlld1t0ZXh0Tm9kZUluZGV4XSA9PT0gbnVsbCkge1xuICAgICAgICBuZ0Rldk1vZGUgJiYgbmdEZXZNb2RlLnJlbmRlcmVyQ3JlYXRlVGV4dE5vZGUrKztcbiAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydEluZGV4SW5SYW5nZShsVmlldywgdGV4dE5vZGVJbmRleCk7XG4gICAgICAgIGxWaWV3W3RleHROb2RlSW5kZXhdID0gY3JlYXRlVGV4dE5vZGUocmVuZGVyZXIsIG9wQ29kZSk7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmICh0eXBlb2Ygb3BDb2RlID09ICdudW1iZXInKSB7XG4gICAgICBzd2l0Y2ggKG9wQ29kZSAmIEljdUNyZWF0ZU9wQ29kZS5NQVNLX0lOU1RSVUNUSU9OKSB7XG4gICAgICAgIGNhc2UgSWN1Q3JlYXRlT3BDb2RlLkFwcGVuZENoaWxkOlxuICAgICAgICAgIGNvbnN0IHBhcmVudElkeCA9IGdldFBhcmVudEZyb21JY3VDcmVhdGVPcENvZGUob3BDb2RlKTtcbiAgICAgICAgICBpZiAocm9vdElkeCA9PT0gbnVsbCkge1xuICAgICAgICAgICAgLy8gVGhlIGZpcnN0IG9wZXJhdGlvbiBzaG91bGQgc2F2ZSB0aGUgYHJvb3RJZHhgIGJlY2F1c2UgdGhlIGZpcnN0IG9wZXJhdGlvblxuICAgICAgICAgICAgLy8gbXVzdCBpbnNlcnQgaW50byB0aGUgcm9vdC4gKE9ubHkgc3Vic2VxdWVudCBvcGVyYXRpb25zIGNhbiBpbnNlcnQgaW50byBhIGR5bmFtaWNcbiAgICAgICAgICAgIC8vIHBhcmVudClcbiAgICAgICAgICAgIHJvb3RJZHggPSBwYXJlbnRJZHg7XG4gICAgICAgICAgICByb290Uk5vZGUgPSBuYXRpdmVQYXJlbnROb2RlKHJlbmRlcmVyLCBhbmNob3JSTm9kZSk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGxldCBpbnNlcnRJbkZyb250T2Y6IFJOb2RlfG51bGw7XG4gICAgICAgICAgbGV0IHBhcmVudFJOb2RlOiBSRWxlbWVudHxudWxsO1xuICAgICAgICAgIGlmIChwYXJlbnRJZHggPT09IHJvb3RJZHgpIHtcbiAgICAgICAgICAgIGluc2VydEluRnJvbnRPZiA9IGFuY2hvclJOb2RlO1xuICAgICAgICAgICAgcGFyZW50Uk5vZGUgPSByb290Uk5vZGU7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGluc2VydEluRnJvbnRPZiA9IG51bGw7XG4gICAgICAgICAgICBwYXJlbnRSTm9kZSA9IHVud3JhcFJOb2RlKGxWaWV3W3BhcmVudElkeF0pIGFzIFJFbGVtZW50O1xuICAgICAgICAgIH1cbiAgICAgICAgICAvLyBGSVhNRShtaXNrbyk6IFJlZmFjdG9yIHdpdGggYHByb2Nlc3NJMThuVGV4dGBcbiAgICAgICAgICBpZiAocGFyZW50Uk5vZGUgIT09IG51bGwpIHtcbiAgICAgICAgICAgIC8vIFRoaXMgY2FuIGhhcHBlbiBpZiB0aGUgYExWaWV3YCB3ZSBhcmUgYWRkaW5nIHRvIGlzIG5vdCBhdHRhY2hlZCB0byBhIHBhcmVudCBgTFZpZXdgLlxuICAgICAgICAgICAgLy8gSW4gc3VjaCBhIGNhc2UgdGhlcmUgaXMgbm8gXCJyb290XCIgd2UgY2FuIGF0dGFjaCB0by4gVGhpcyBpcyBmaW5lLCBhcyB3ZSBzdGlsbCBuZWVkIHRvXG4gICAgICAgICAgICAvLyBjcmVhdGUgdGhlIGVsZW1lbnRzLiBXaGVuIHRoZSBgTFZpZXdgIGdldHMgbGF0ZXIgYWRkZWQgdG8gYSBwYXJlbnQgdGhlc2UgXCJyb290XCIgbm9kZXNcbiAgICAgICAgICAgIC8vIGdldCBwaWNrZWQgdXAgYW5kIGFkZGVkLlxuICAgICAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydERvbU5vZGUocGFyZW50Uk5vZGUpO1xuICAgICAgICAgICAgY29uc3QgcmVmSWR4ID0gZ2V0UmVmRnJvbUljdUNyZWF0ZU9wQ29kZShvcENvZGUpO1xuICAgICAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydEdyZWF0ZXJUaGFuKHJlZklkeCwgSEVBREVSX09GRlNFVCwgJ01pc3NpbmcgcmVmJyk7XG4gICAgICAgICAgICAvLyBgdW53cmFwUk5vZGVgIGlzIG5vdCBuZWVkZWQgaGVyZSBhcyBhbGwgb2YgdGhlc2UgcG9pbnQgdG8gUk5vZGVzIGFzIHBhcnQgb2YgdGhlIGkxOG5cbiAgICAgICAgICAgIC8vIHdoaWNoIGNhbid0IGhhdmUgY29tcG9uZW50cy5cbiAgICAgICAgICAgIGNvbnN0IGNoaWxkID0gbFZpZXdbcmVmSWR4XSBhcyBSRWxlbWVudDtcbiAgICAgICAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnREb21Ob2RlKGNoaWxkKTtcbiAgICAgICAgICAgIG5hdGl2ZUluc2VydEJlZm9yZShyZW5kZXJlciwgcGFyZW50Uk5vZGUsIGNoaWxkLCBpbnNlcnRJbkZyb250T2YsIGZhbHNlKTtcbiAgICAgICAgICAgIGNvbnN0IHRJY3UgPSBnZXRUSWN1KHRWaWV3LCByZWZJZHgpO1xuICAgICAgICAgICAgaWYgKHRJY3UgIT09IG51bGwgJiYgdHlwZW9mIHRJY3UgPT09ICdvYmplY3QnKSB7XG4gICAgICAgICAgICAgIC8vIElmIHdlIGp1c3QgYWRkZWQgYSBjb21tZW50IG5vZGUgd2hpY2ggaGFzIElDVSB0aGVuIHRoYXQgSUNVIG1heSBoYXZlIGFscmVhZHkgYmVlblxuICAgICAgICAgICAgICAvLyByZW5kZXJlZCBhbmQgdGhlcmVmb3JlIHdlIG5lZWQgdG8gcmUtYWRkIGl0IGhlcmUuXG4gICAgICAgICAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRUSWN1KHRJY3UpO1xuICAgICAgICAgICAgICBjb25zdCBjYXNlSW5kZXggPSBnZXRDdXJyZW50SUNVQ2FzZUluZGV4KHRJY3UsIGxWaWV3KTtcbiAgICAgICAgICAgICAgaWYgKGNhc2VJbmRleCAhPT0gbnVsbCkge1xuICAgICAgICAgICAgICAgIGFwcGx5TXV0YWJsZU9wQ29kZXModFZpZXcsIHRJY3UuY3JlYXRlW2Nhc2VJbmRleF0sIGxWaWV3LCBsVmlld1t0SWN1LmFuY2hvcklkeF0pO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIEljdUNyZWF0ZU9wQ29kZS5BdHRyOlxuICAgICAgICAgIGNvbnN0IGVsZW1lbnROb2RlSW5kZXggPSBvcENvZGUgPj4+IEljdUNyZWF0ZU9wQ29kZS5TSElGVF9SRUY7XG4gICAgICAgICAgY29uc3QgYXR0ck5hbWUgPSBtdXRhYmxlT3BDb2Rlc1srK2ldIGFzIHN0cmluZztcbiAgICAgICAgICBjb25zdCBhdHRyVmFsdWUgPSBtdXRhYmxlT3BDb2Rlc1srK2ldIGFzIHN0cmluZztcbiAgICAgICAgICAvLyBUaGlzIGNvZGUgaXMgdXNlZCBmb3IgSUNVIGV4cHJlc3Npb25zIG9ubHksIHNpbmNlIHdlIGRvbid0IHN1cHBvcnRcbiAgICAgICAgICAvLyBkaXJlY3RpdmVzL2NvbXBvbmVudHMgaW4gSUNVcywgd2UgZG9uJ3QgbmVlZCB0byB3b3JyeSBhYm91dCBpbnB1dHMgaGVyZVxuICAgICAgICAgIHNldEVsZW1lbnRBdHRyaWJ1dGUoXG4gICAgICAgICAgICAgIHJlbmRlcmVyLCBnZXROYXRpdmVCeUluZGV4KGVsZW1lbnROb2RlSW5kZXgsIGxWaWV3KSBhcyBSRWxlbWVudCwgbnVsbCwgbnVsbCwgYXR0ck5hbWUsXG4gICAgICAgICAgICAgIGF0dHJWYWx1ZSwgbnVsbCk7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIGRlZmF1bHQ6XG4gICAgICAgICAgaWYgKG5nRGV2TW9kZSkge1xuICAgICAgICAgICAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgICAgICAgICAgICBSdW50aW1lRXJyb3JDb2RlLklOVkFMSURfSTE4Tl9TVFJVQ1RVUkUsXG4gICAgICAgICAgICAgICAgYFVuYWJsZSB0byBkZXRlcm1pbmUgdGhlIHR5cGUgb2YgbXV0YXRlIG9wZXJhdGlvbiBmb3IgXCIke29wQ29kZX1cImApO1xuICAgICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgc3dpdGNoIChvcENvZGUpIHtcbiAgICAgICAgY2FzZSBJQ1VfTUFSS0VSOlxuICAgICAgICAgIGNvbnN0IGNvbW1lbnRWYWx1ZSA9IG11dGFibGVPcENvZGVzWysraV0gYXMgc3RyaW5nO1xuICAgICAgICAgIGNvbnN0IGNvbW1lbnROb2RlSW5kZXggPSBtdXRhYmxlT3BDb2Rlc1srK2ldIGFzIG51bWJlcjtcbiAgICAgICAgICBpZiAobFZpZXdbY29tbWVudE5vZGVJbmRleF0gPT09IG51bGwpIHtcbiAgICAgICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgICAgIGFzc2VydEVxdWFsKFxuICAgICAgICAgICAgICAgICAgICB0eXBlb2YgY29tbWVudFZhbHVlLCAnc3RyaW5nJyxcbiAgICAgICAgICAgICAgICAgICAgYEV4cGVjdGVkIFwiJHtjb21tZW50VmFsdWV9XCIgdG8gYmUgYSBjb21tZW50IG5vZGUgdmFsdWVgKTtcbiAgICAgICAgICAgIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJDcmVhdGVDb21tZW50Kys7XG4gICAgICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0SW5kZXhJbkV4cGFuZG9SYW5nZShsVmlldywgY29tbWVudE5vZGVJbmRleCk7XG4gICAgICAgICAgICBjb25zdCBjb21tZW50Uk5vZGUgPSBsVmlld1tjb21tZW50Tm9kZUluZGV4XSA9XG4gICAgICAgICAgICAgICAgY3JlYXRlQ29tbWVudE5vZGUocmVuZGVyZXIsIGNvbW1lbnRWYWx1ZSk7XG4gICAgICAgICAgICAvLyBGSVhNRShtaXNrbyk6IEF0dGFjaGluZyBwYXRjaCBkYXRhIGlzIG9ubHkgbmVlZGVkIGZvciB0aGUgcm9vdCAoQWxzbyBhZGQgdGVzdHMpXG4gICAgICAgICAgICBhdHRhY2hQYXRjaERhdGEoY29tbWVudFJOb2RlLCBsVmlldyk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIEVMRU1FTlRfTUFSS0VSOlxuICAgICAgICAgIGNvbnN0IHRhZ05hbWUgPSBtdXRhYmxlT3BDb2Rlc1srK2ldIGFzIHN0cmluZztcbiAgICAgICAgICBjb25zdCBlbGVtZW50Tm9kZUluZGV4ID0gbXV0YWJsZU9wQ29kZXNbKytpXSBhcyBudW1iZXI7XG4gICAgICAgICAgaWYgKGxWaWV3W2VsZW1lbnROb2RlSW5kZXhdID09PSBudWxsKSB7XG4gICAgICAgICAgICBuZ0Rldk1vZGUgJiZcbiAgICAgICAgICAgICAgICBhc3NlcnRFcXVhbChcbiAgICAgICAgICAgICAgICAgICAgdHlwZW9mIHRhZ05hbWUsICdzdHJpbmcnLFxuICAgICAgICAgICAgICAgICAgICBgRXhwZWN0ZWQgXCIke3RhZ05hbWV9XCIgdG8gYmUgYW4gZWxlbWVudCBub2RlIHRhZyBuYW1lYCk7XG5cbiAgICAgICAgICAgIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJDcmVhdGVFbGVtZW50Kys7XG4gICAgICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0SW5kZXhJbkV4cGFuZG9SYW5nZShsVmlldywgZWxlbWVudE5vZGVJbmRleCk7XG4gICAgICAgICAgICBjb25zdCBlbGVtZW50Uk5vZGUgPSBsVmlld1tlbGVtZW50Tm9kZUluZGV4XSA9XG4gICAgICAgICAgICAgICAgY3JlYXRlRWxlbWVudE5vZGUocmVuZGVyZXIsIHRhZ05hbWUsIG51bGwpO1xuICAgICAgICAgICAgLy8gRklYTUUobWlza28pOiBBdHRhY2hpbmcgcGF0Y2ggZGF0YSBpcyBvbmx5IG5lZWRlZCBmb3IgdGhlIHJvb3QgKEFsc28gYWRkIHRlc3RzKVxuICAgICAgICAgICAgYXR0YWNoUGF0Y2hEYXRhKGVsZW1lbnRSTm9kZSwgbFZpZXcpO1xuICAgICAgICAgIH1cbiAgICAgICAgICBicmVhaztcbiAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICBuZ0Rldk1vZGUgJiZcbiAgICAgICAgICAgICAgdGhyb3dFcnJvcihgVW5hYmxlIHRvIGRldGVybWluZSB0aGUgdHlwZSBvZiBtdXRhdGUgb3BlcmF0aW9uIGZvciBcIiR7b3BDb2RlfVwiYCk7XG4gICAgICB9XG4gICAgfVxuICB9XG59XG5cblxuLyoqXG4gKiBBcHBseSBgSTE4blVwZGF0ZU9wQ29kZXNgIE9wQ29kZXNcbiAqXG4gKiBAcGFyYW0gdFZpZXcgQ3VycmVudCBgVFZpZXdgXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgXG4gKiBAcGFyYW0gdXBkYXRlT3BDb2RlcyBPcENvZGVzIHRvIHByb2Nlc3NcbiAqIEBwYXJhbSBiaW5kaW5nc1N0YXJ0SW5kZXggTG9jYXRpb24gb2YgdGhlIGZpcnN0IGDJtcm1aTE4bkFwcGx5YFxuICogQHBhcmFtIGNoYW5nZU1hc2sgRWFjaCBiaXQgY29ycmVzcG9uZHMgdG8gYSBgybXJtWkxOG5FeHBgIChDb3VudGluZyBiYWNrd2FyZHMgZnJvbVxuICogICAgIGBiaW5kaW5nc1N0YXJ0SW5kZXhgKVxuICovXG5leHBvcnQgZnVuY3Rpb24gYXBwbHlVcGRhdGVPcENvZGVzKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCB1cGRhdGVPcENvZGVzOiBJMThuVXBkYXRlT3BDb2RlcywgYmluZGluZ3NTdGFydEluZGV4OiBudW1iZXIsXG4gICAgY2hhbmdlTWFzazogbnVtYmVyKSB7XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgdXBkYXRlT3BDb2Rlcy5sZW5ndGg7IGkrKykge1xuICAgIC8vIGJpdCBjb2RlIHRvIGNoZWNrIGlmIHdlIHNob3VsZCBhcHBseSB0aGUgbmV4dCB1cGRhdGVcbiAgICBjb25zdCBjaGVja0JpdCA9IHVwZGF0ZU9wQ29kZXNbaV0gYXMgbnVtYmVyO1xuICAgIC8vIE51bWJlciBvZiBvcENvZGVzIHRvIHNraXAgdW50aWwgbmV4dCBzZXQgb2YgdXBkYXRlIGNvZGVzXG4gICAgY29uc3Qgc2tpcENvZGVzID0gdXBkYXRlT3BDb2Rlc1srK2ldIGFzIG51bWJlcjtcbiAgICBpZiAoY2hlY2tCaXQgJiBjaGFuZ2VNYXNrKSB7XG4gICAgICAvLyBUaGUgdmFsdWUgaGFzIGJlZW4gdXBkYXRlZCBzaW5jZSBsYXN0IGNoZWNrZWRcbiAgICAgIGxldCB2YWx1ZSA9ICcnO1xuICAgICAgZm9yIChsZXQgaiA9IGkgKyAxOyBqIDw9IChpICsgc2tpcENvZGVzKTsgaisrKSB7XG4gICAgICAgIGNvbnN0IG9wQ29kZSA9IHVwZGF0ZU9wQ29kZXNbal07XG4gICAgICAgIGlmICh0eXBlb2Ygb3BDb2RlID09ICdzdHJpbmcnKSB7XG4gICAgICAgICAgdmFsdWUgKz0gb3BDb2RlO1xuICAgICAgICB9IGVsc2UgaWYgKHR5cGVvZiBvcENvZGUgPT0gJ251bWJlcicpIHtcbiAgICAgICAgICBpZiAob3BDb2RlIDwgMCkge1xuICAgICAgICAgICAgLy8gTmVnYXRpdmUgb3BDb2RlIHJlcHJlc2VudCBgaTE4bkV4cGAgdmFsdWVzIG9mZnNldC5cbiAgICAgICAgICAgIHZhbHVlICs9IHJlbmRlclN0cmluZ2lmeShsVmlld1tiaW5kaW5nc1N0YXJ0SW5kZXggLSBvcENvZGVdKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY29uc3Qgbm9kZUluZGV4ID0gKG9wQ29kZSA+Pj4gSTE4blVwZGF0ZU9wQ29kZS5TSElGVF9SRUYpO1xuICAgICAgICAgICAgc3dpdGNoIChvcENvZGUgJiBJMThuVXBkYXRlT3BDb2RlLk1BU0tfT1BDT0RFKSB7XG4gICAgICAgICAgICAgIGNhc2UgSTE4blVwZGF0ZU9wQ29kZS5BdHRyOlxuICAgICAgICAgICAgICAgIGNvbnN0IHByb3BOYW1lID0gdXBkYXRlT3BDb2Rlc1srK2pdIGFzIHN0cmluZztcbiAgICAgICAgICAgICAgICBjb25zdCBzYW5pdGl6ZUZuID0gdXBkYXRlT3BDb2Rlc1srK2pdIGFzIFNhbml0aXplckZuIHwgbnVsbDtcbiAgICAgICAgICAgICAgICBjb25zdCB0Tm9kZU9yVGFnTmFtZSA9IHRWaWV3LmRhdGFbbm9kZUluZGV4XSBhcyBUTm9kZSB8IHN0cmluZztcbiAgICAgICAgICAgICAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZCh0Tm9kZU9yVGFnTmFtZSwgJ0V4cGVydGluZyBUTm9kZSBvciBzdHJpbmcnKTtcbiAgICAgICAgICAgICAgICBpZiAodHlwZW9mIHROb2RlT3JUYWdOYW1lID09PSAnc3RyaW5nJykge1xuICAgICAgICAgICAgICAgICAgLy8gSUYgd2UgZG9uJ3QgaGF2ZSBhIGBUTm9kZWAsIHRoZW4gd2UgYXJlIGFuIGVsZW1lbnQgaW4gSUNVIChhcyBJQ1UgY29udGVudCBkb2VzXG4gICAgICAgICAgICAgICAgICAvLyBub3QgaGF2ZSBUTm9kZSksIGluIHdoaWNoIGNhc2Ugd2Uga25vdyB0aGF0IHRoZXJlIGFyZSBubyBkaXJlY3RpdmVzLCBhbmQgaGVuY2VcbiAgICAgICAgICAgICAgICAgIC8vIHdlIHVzZSBhdHRyaWJ1dGUgc2V0dGluZy5cbiAgICAgICAgICAgICAgICAgIHNldEVsZW1lbnRBdHRyaWJ1dGUoXG4gICAgICAgICAgICAgICAgICAgICAgbFZpZXdbUkVOREVSRVJdLCBsVmlld1tub2RlSW5kZXhdLCBudWxsLCB0Tm9kZU9yVGFnTmFtZSwgcHJvcE5hbWUsIHZhbHVlLFxuICAgICAgICAgICAgICAgICAgICAgIHNhbml0aXplRm4pO1xuICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICBlbGVtZW50UHJvcGVydHlJbnRlcm5hbChcbiAgICAgICAgICAgICAgICAgICAgICB0VmlldywgdE5vZGVPclRhZ05hbWUsIGxWaWV3LCBwcm9wTmFtZSwgdmFsdWUsIGxWaWV3W1JFTkRFUkVSXSwgc2FuaXRpemVGbixcbiAgICAgICAgICAgICAgICAgICAgICBmYWxzZSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICBjYXNlIEkxOG5VcGRhdGVPcENvZGUuVGV4dDpcbiAgICAgICAgICAgICAgICBjb25zdCByVGV4dCA9IGxWaWV3W25vZGVJbmRleF0gYXMgUlRleHQgfCBudWxsO1xuICAgICAgICAgICAgICAgIHJUZXh0ICE9PSBudWxsICYmIHVwZGF0ZVRleHROb2RlKGxWaWV3W1JFTkRFUkVSXSwgclRleHQsIHZhbHVlKTtcbiAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgY2FzZSBJMThuVXBkYXRlT3BDb2RlLkljdVN3aXRjaDpcbiAgICAgICAgICAgICAgICBhcHBseUljdVN3aXRjaENhc2UodFZpZXcsIGdldFRJY3UodFZpZXcsIG5vZGVJbmRleCkhLCBsVmlldywgdmFsdWUpO1xuICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICBjYXNlIEkxOG5VcGRhdGVPcENvZGUuSWN1VXBkYXRlOlxuICAgICAgICAgICAgICAgIGFwcGx5SWN1VXBkYXRlQ2FzZSh0VmlldywgZ2V0VEljdSh0Vmlldywgbm9kZUluZGV4KSEsIGJpbmRpbmdzU3RhcnRJbmRleCwgbFZpZXcpO1xuICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBjb25zdCBvcENvZGUgPSB1cGRhdGVPcENvZGVzW2kgKyAxXSBhcyBudW1iZXI7XG4gICAgICBpZiAob3BDb2RlID4gMCAmJiAob3BDb2RlICYgSTE4blVwZGF0ZU9wQ29kZS5NQVNLX09QQ09ERSkgPT09IEkxOG5VcGRhdGVPcENvZGUuSWN1VXBkYXRlKSB7XG4gICAgICAgIC8vIFNwZWNpYWwgY2FzZSBmb3IgdGhlIGBpY3VVcGRhdGVDYXNlYC4gSXQgY291bGQgYmUgdGhhdCB0aGUgbWFzayBkaWQgbm90IG1hdGNoLCBidXRcbiAgICAgICAgLy8gd2Ugc3RpbGwgbmVlZCB0byBleGVjdXRlIGBpY3VVcGRhdGVDYXNlYCBiZWNhdXNlIHRoZSBjYXNlIGhhcyBjaGFuZ2VkIHJlY2VudGx5IGR1ZSB0b1xuICAgICAgICAvLyBwcmV2aW91cyBgaWN1U3dpdGNoQ2FzZWAgaW5zdHJ1Y3Rpb24uIChgaWN1U3dpdGNoQ2FzZWAgYW5kIGBpY3VVcGRhdGVDYXNlYCBhbHdheXMgY29tZSBpblxuICAgICAgICAvLyBwYWlycy4pXG4gICAgICAgIGNvbnN0IG5vZGVJbmRleCA9IChvcENvZGUgPj4+IEkxOG5VcGRhdGVPcENvZGUuU0hJRlRfUkVGKTtcbiAgICAgICAgY29uc3QgdEljdSA9IGdldFRJY3UodFZpZXcsIG5vZGVJbmRleCkhO1xuICAgICAgICBjb25zdCBjdXJyZW50SW5kZXggPSBsVmlld1t0SWN1LmN1cnJlbnRDYXNlTFZpZXdJbmRleF07XG4gICAgICAgIGlmIChjdXJyZW50SW5kZXggPCAwKSB7XG4gICAgICAgICAgYXBwbHlJY3VVcGRhdGVDYXNlKHRWaWV3LCB0SWN1LCBiaW5kaW5nc1N0YXJ0SW5kZXgsIGxWaWV3KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICBpICs9IHNraXBDb2RlcztcbiAgfVxufVxuXG4vKipcbiAqIEFwcGx5IE9wQ29kZXMgYXNzb2NpYXRlZCB3aXRoIHVwZGF0aW5nIGFuIGV4aXN0aW5nIElDVS5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgQ3VycmVudCBgVFZpZXdgXG4gKiBAcGFyYW0gdEljdSBDdXJyZW50IGBUSWN1YFxuICogQHBhcmFtIGJpbmRpbmdzU3RhcnRJbmRleCBMb2NhdGlvbiBvZiB0aGUgZmlyc3QgYMm1ybVpMThuQXBwbHlgXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgXG4gKi9cbmZ1bmN0aW9uIGFwcGx5SWN1VXBkYXRlQ2FzZSh0VmlldzogVFZpZXcsIHRJY3U6IFRJY3UsIGJpbmRpbmdzU3RhcnRJbmRleDogbnVtYmVyLCBsVmlldzogTFZpZXcpIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEluZGV4SW5SYW5nZShsVmlldywgdEljdS5jdXJyZW50Q2FzZUxWaWV3SW5kZXgpO1xuICBsZXQgYWN0aXZlQ2FzZUluZGV4ID0gbFZpZXdbdEljdS5jdXJyZW50Q2FzZUxWaWV3SW5kZXhdO1xuICBpZiAoYWN0aXZlQ2FzZUluZGV4ICE9PSBudWxsKSB7XG4gICAgbGV0IG1hc2sgPSBjaGFuZ2VNYXNrO1xuICAgIGlmIChhY3RpdmVDYXNlSW5kZXggPCAwKSB7XG4gICAgICAvLyBDbGVhciB0aGUgZmxhZy5cbiAgICAgIC8vIE5lZ2F0aXZlIG51bWJlciBtZWFucyB0aGF0IHRoZSBJQ1Ugd2FzIGZyZXNobHkgY3JlYXRlZCBhbmQgd2UgbmVlZCB0byBmb3JjZSB0aGUgdXBkYXRlLlxuICAgICAgYWN0aXZlQ2FzZUluZGV4ID0gbFZpZXdbdEljdS5jdXJyZW50Q2FzZUxWaWV3SW5kZXhdID0gfmFjdGl2ZUNhc2VJbmRleDtcbiAgICAgIC8vIC0xIGlzIHNhbWUgYXMgYWxsIGJpdHMgb24sIHdoaWNoIHNpbXVsYXRlcyBjcmVhdGlvbiBzaW5jZSBpdCBtYXJrcyBhbGwgYml0cyBkaXJ0eVxuICAgICAgbWFzayA9IC0xO1xuICAgIH1cbiAgICBhcHBseVVwZGF0ZU9wQ29kZXModFZpZXcsIGxWaWV3LCB0SWN1LnVwZGF0ZVthY3RpdmVDYXNlSW5kZXhdLCBiaW5kaW5nc1N0YXJ0SW5kZXgsIG1hc2spO1xuICB9XG59XG5cbi8qKlxuICogQXBwbHkgT3BDb2RlcyBhc3NvY2lhdGVkIHdpdGggc3dpdGNoaW5nIGEgY2FzZSBvbiBJQ1UuXG4gKlxuICogVGhpcyBpbnZvbHZlcyB0ZWFyaW5nIGRvd24gZXhpc3RpbmcgY2FzZSBhbmQgdGhhbiBidWlsZGluZyB1cCBhIG5ldyBjYXNlLlxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2BcbiAqIEBwYXJhbSB0SWN1IEN1cnJlbnQgYFRJY3VgXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgXG4gKiBAcGFyYW0gdmFsdWUgVmFsdWUgb2YgdGhlIGNhc2UgdG8gdXBkYXRlIHRvLlxuICovXG5mdW5jdGlvbiBhcHBseUljdVN3aXRjaENhc2UodFZpZXc6IFRWaWV3LCB0SWN1OiBUSWN1LCBsVmlldzogTFZpZXcsIHZhbHVlOiBzdHJpbmcpIHtcbiAgLy8gUmVidWlsZCBhIG5ldyBjYXNlIGZvciB0aGlzIElDVVxuICBjb25zdCBjYXNlSW5kZXggPSBnZXRDYXNlSW5kZXgodEljdSwgdmFsdWUpO1xuICBsZXQgYWN0aXZlQ2FzZUluZGV4ID0gZ2V0Q3VycmVudElDVUNhc2VJbmRleCh0SWN1LCBsVmlldyk7XG4gIGlmIChhY3RpdmVDYXNlSW5kZXggIT09IGNhc2VJbmRleCkge1xuICAgIGFwcGx5SWN1U3dpdGNoQ2FzZVJlbW92ZSh0VmlldywgdEljdSwgbFZpZXcpO1xuICAgIGxWaWV3W3RJY3UuY3VycmVudENhc2VMVmlld0luZGV4XSA9IGNhc2VJbmRleCA9PT0gbnVsbCA/IG51bGwgOiB+Y2FzZUluZGV4O1xuICAgIGlmIChjYXNlSW5kZXggIT09IG51bGwpIHtcbiAgICAgIC8vIEFkZCB0aGUgbm9kZXMgZm9yIHRoZSBuZXcgY2FzZVxuICAgICAgY29uc3QgYW5jaG9yUk5vZGUgPSBsVmlld1t0SWN1LmFuY2hvcklkeF07XG4gICAgICBpZiAoYW5jaG9yUk5vZGUpIHtcbiAgICAgICAgbmdEZXZNb2RlICYmIGFzc2VydERvbU5vZGUoYW5jaG9yUk5vZGUpO1xuICAgICAgICBhcHBseU11dGFibGVPcENvZGVzKHRWaWV3LCB0SWN1LmNyZWF0ZVtjYXNlSW5kZXhdLCBsVmlldywgYW5jaG9yUk5vZGUpO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEFwcGx5IE9wQ29kZXMgYXNzb2NpYXRlZCB3aXRoIHRlYXJpbmcgSUNVIGNhc2UuXG4gKlxuICogVGhpcyBpbnZvbHZlcyB0ZWFyaW5nIGRvd24gZXhpc3RpbmcgY2FzZSBhbmQgdGhhbiBidWlsZGluZyB1cCBhIG5ldyBjYXNlLlxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2BcbiAqIEBwYXJhbSB0SWN1IEN1cnJlbnQgYFRJY3VgXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgXG4gKi9cbmZ1bmN0aW9uIGFwcGx5SWN1U3dpdGNoQ2FzZVJlbW92ZSh0VmlldzogVFZpZXcsIHRJY3U6IFRJY3UsIGxWaWV3OiBMVmlldykge1xuICBsZXQgYWN0aXZlQ2FzZUluZGV4ID0gZ2V0Q3VycmVudElDVUNhc2VJbmRleCh0SWN1LCBsVmlldyk7XG4gIGlmIChhY3RpdmVDYXNlSW5kZXggIT09IG51bGwpIHtcbiAgICBjb25zdCByZW1vdmVDb2RlcyA9IHRJY3UucmVtb3ZlW2FjdGl2ZUNhc2VJbmRleF07XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCByZW1vdmVDb2Rlcy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3Qgbm9kZU9ySWN1SW5kZXggPSByZW1vdmVDb2Rlc1tpXSBhcyBudW1iZXI7XG4gICAgICBpZiAobm9kZU9ySWN1SW5kZXggPiAwKSB7XG4gICAgICAgIC8vIFBvc2l0aXZlIG51bWJlcnMgYXJlIGBSTm9kZWBzLlxuICAgICAgICBjb25zdCByTm9kZSA9IGdldE5hdGl2ZUJ5SW5kZXgobm9kZU9ySWN1SW5kZXgsIGxWaWV3KTtcbiAgICAgICAgck5vZGUgIT09IG51bGwgJiYgbmF0aXZlUmVtb3ZlTm9kZShsVmlld1tSRU5ERVJFUl0sIHJOb2RlKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIE5lZ2F0aXZlIG51bWJlcnMgYXJlIElDVXNcbiAgICAgICAgYXBwbHlJY3VTd2l0Y2hDYXNlUmVtb3ZlKHRWaWV3LCBnZXRUSWN1KHRWaWV3LCB+bm9kZU9ySWN1SW5kZXgpISwgbFZpZXcpO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG5cbi8qKlxuICogUmV0dXJucyB0aGUgaW5kZXggb2YgdGhlIGN1cnJlbnQgY2FzZSBvZiBhbiBJQ1UgZXhwcmVzc2lvbiBkZXBlbmRpbmcgb24gdGhlIG1haW4gYmluZGluZyB2YWx1ZVxuICpcbiAqIEBwYXJhbSBpY3VFeHByZXNzaW9uXG4gKiBAcGFyYW0gYmluZGluZ1ZhbHVlIFRoZSB2YWx1ZSBvZiB0aGUgbWFpbiBiaW5kaW5nIHVzZWQgYnkgdGhpcyBJQ1UgZXhwcmVzc2lvblxuICovXG5mdW5jdGlvbiBnZXRDYXNlSW5kZXgoaWN1RXhwcmVzc2lvbjogVEljdSwgYmluZGluZ1ZhbHVlOiBzdHJpbmcpOiBudW1iZXJ8bnVsbCB7XG4gIGxldCBpbmRleCA9IGljdUV4cHJlc3Npb24uY2FzZXMuaW5kZXhPZihiaW5kaW5nVmFsdWUpO1xuICBpZiAoaW5kZXggPT09IC0xKSB7XG4gICAgc3dpdGNoIChpY3VFeHByZXNzaW9uLnR5cGUpIHtcbiAgICAgIGNhc2UgSWN1VHlwZS5wbHVyYWw6IHtcbiAgICAgICAgY29uc3QgcmVzb2x2ZWRDYXNlID0gZ2V0UGx1cmFsQ2FzZShiaW5kaW5nVmFsdWUsIGdldExvY2FsZUlkKCkpO1xuICAgICAgICBpbmRleCA9IGljdUV4cHJlc3Npb24uY2FzZXMuaW5kZXhPZihyZXNvbHZlZENhc2UpO1xuICAgICAgICBpZiAoaW5kZXggPT09IC0xICYmIHJlc29sdmVkQ2FzZSAhPT0gJ290aGVyJykge1xuICAgICAgICAgIGluZGV4ID0gaWN1RXhwcmVzc2lvbi5jYXNlcy5pbmRleE9mKCdvdGhlcicpO1xuICAgICAgICB9XG4gICAgICAgIGJyZWFrO1xuICAgICAgfVxuICAgICAgY2FzZSBJY3VUeXBlLnNlbGVjdDoge1xuICAgICAgICBpbmRleCA9IGljdUV4cHJlc3Npb24uY2FzZXMuaW5kZXhPZignb3RoZXInKTtcbiAgICAgICAgYnJlYWs7XG4gICAgICB9XG4gICAgfVxuICB9XG4gIHJldHVybiBpbmRleCA9PT0gLTEgPyBudWxsIDogaW5kZXg7XG59XG4iXX0=