/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { ErrorHandler } from '../../error_handler';
import { RuntimeError } from '../../errors';
import { SKIP_HYDRATION_ATTR_NAME } from '../../hydration/skip_hydration';
import { PRESERVE_HOST_CONTENT, PRESERVE_HOST_CONTENT_DEFAULT } from '../../hydration/tokens';
import { processTextNodeMarkersBeforeHydration } from '../../hydration/utils';
import { ViewEncapsulation } from '../../metadata/view';
import { validateAgainstEventAttributes, validateAgainstEventProperties } from '../../sanitization/sanitization';
import { setActiveConsumer } from '../../signals';
import { assertDefined, assertEqual, assertGreaterThan, assertGreaterThanOrEqual, assertIndexInRange, assertNotEqual, assertNotSame, assertSame, assertString } from '../../util/assert';
import { escapeCommentText } from '../../util/dom';
import { normalizeDebugBindingName, normalizeDebugBindingValue } from '../../util/ng_reflect';
import { stringify } from '../../util/stringify';
import { assertFirstCreatePass, assertFirstUpdatePass, assertLView, assertTNodeForLView, assertTNodeForTView } from '../assert';
import { attachPatchData } from '../context_discovery';
import { getFactoryDef } from '../definition_factory';
import { diPublicInInjector, getNodeInjectable, getOrCreateNodeInjectorForNode } from '../di';
import { throwMultipleComponentError } from '../errors';
import { CONTAINER_HEADER_OFFSET } from '../interfaces/container';
import { NodeInjectorFactory } from '../interfaces/injector';
import { getUniqueLViewId } from '../interfaces/lview_tracking';
import { isComponentDef, isComponentHost, isContentQueryHost } from '../interfaces/type_checks';
import { CHILD_HEAD, CHILD_TAIL, CLEANUP, CONTEXT, DECLARATION_COMPONENT_VIEW, DECLARATION_VIEW, EMBEDDED_VIEW_INJECTOR, ENVIRONMENT, FLAGS, HEADER_OFFSET, HOST, HYDRATION, ID, INJECTOR, NEXT, PARENT, REACTIVE_HOST_BINDING_CONSUMER, REACTIVE_TEMPLATE_CONSUMER, RENDERER, T_HOST, TVIEW } from '../interfaces/view';
import { assertPureTNodeType, assertTNodeType } from '../node_assert';
import { clearElementContents, updateTextNode } from '../node_manipulation';
import { isInlineTemplate, isNodeMatchingSelectorList } from '../node_selector_matcher';
import { profiler } from '../profiler';
import { commitLViewConsumerIfHasProducers, getReactiveLViewConsumer } from '../reactive_lview_consumer';
import { getBindingsEnabled, getCurrentDirectiveIndex, getCurrentParentTNode, getCurrentTNodePlaceholderOk, getSelectedIndex, isCurrentTNodeParent, isInCheckNoChangesMode, isInI18nBlock, setBindingRootForHostBindings, setCurrentDirectiveIndex, setCurrentQueryIndex, setCurrentTNode, setSelectedIndex } from '../state';
import { NO_CHANGE } from '../tokens';
import { mergeHostAttrs } from '../util/attrs_utils';
import { INTERPOLATION_DELIMITER } from '../util/misc_utils';
import { renderStringify } from '../util/stringify_utils';
import { getComponentLViewByIndex, getNativeByIndex, getNativeByTNode, resetPreOrderHookFlags, unwrapLView } from '../util/view_utils';
import { selectIndexInternal } from './advance';
import { ɵɵdirectiveInject } from './di';
import { handleUnknownPropertyError, isPropertyValid, matchingSchemas } from './element_validation';
/**
 * Invoke `HostBindingsFunction`s for view.
 *
 * This methods executes `TView.hostBindingOpCodes`. It is used to execute the
 * `HostBindingsFunction`s associated with the current `LView`.
 *
 * @param tView Current `TView`.
 * @param lView Current `LView`.
 */
export function processHostBindingOpCodes(tView, lView) {
    const hostBindingOpCodes = tView.hostBindingOpCodes;
    if (hostBindingOpCodes === null)
        return;
    const consumer = getReactiveLViewConsumer(lView, REACTIVE_HOST_BINDING_CONSUMER);
    try {
        for (let i = 0; i < hostBindingOpCodes.length; i++) {
            const opCode = hostBindingOpCodes[i];
            if (opCode < 0) {
                // Negative numbers are element indexes.
                setSelectedIndex(~opCode);
            }
            else {
                // Positive numbers are NumberTuple which store bindingRootIndex and directiveIndex.
                const directiveIdx = opCode;
                const bindingRootIndx = hostBindingOpCodes[++i];
                const hostBindingFn = hostBindingOpCodes[++i];
                setBindingRootForHostBindings(bindingRootIndx, directiveIdx);
                const context = lView[directiveIdx];
                consumer.runInContext(hostBindingFn, 2 /* RenderFlags.Update */, context);
            }
        }
    }
    finally {
        if (lView[REACTIVE_HOST_BINDING_CONSUMER] === null) {
            commitLViewConsumerIfHasProducers(lView, REACTIVE_HOST_BINDING_CONSUMER);
        }
        setSelectedIndex(-1);
    }
}
export function createLView(parentLView, tView, context, flags, host, tHostNode, environment, renderer, injector, embeddedViewInjector, hydrationInfo) {
    const lView = tView.blueprint.slice();
    lView[HOST] = host;
    lView[FLAGS] = flags | 4 /* LViewFlags.CreationMode */ | 128 /* LViewFlags.Attached */ | 8 /* LViewFlags.FirstLViewPass */;
    if (embeddedViewInjector !== null ||
        (parentLView && (parentLView[FLAGS] & 2048 /* LViewFlags.HasEmbeddedViewInjector */))) {
        lView[FLAGS] |= 2048 /* LViewFlags.HasEmbeddedViewInjector */;
    }
    resetPreOrderHookFlags(lView);
    ngDevMode && tView.declTNode && parentLView && assertTNodeForLView(tView.declTNode, parentLView);
    lView[PARENT] = lView[DECLARATION_VIEW] = parentLView;
    lView[CONTEXT] = context;
    lView[ENVIRONMENT] = (environment || parentLView && parentLView[ENVIRONMENT]);
    ngDevMode && assertDefined(lView[ENVIRONMENT], 'LViewEnvironment is required');
    lView[RENDERER] = (renderer || parentLView && parentLView[RENDERER]);
    ngDevMode && assertDefined(lView[RENDERER], 'Renderer is required');
    lView[INJECTOR] = injector || parentLView && parentLView[INJECTOR] || null;
    lView[T_HOST] = tHostNode;
    lView[ID] = getUniqueLViewId();
    lView[HYDRATION] = hydrationInfo;
    lView[EMBEDDED_VIEW_INJECTOR] = embeddedViewInjector;
    ngDevMode &&
        assertEqual(tView.type == 2 /* TViewType.Embedded */ ? parentLView !== null : true, true, 'Embedded views must have parentLView');
    lView[DECLARATION_COMPONENT_VIEW] =
        tView.type == 2 /* TViewType.Embedded */ ? parentLView[DECLARATION_COMPONENT_VIEW] : lView;
    return lView;
}
export function getOrCreateTNode(tView, index, type, name, attrs) {
    ngDevMode && index !== 0 && // 0 are bogus nodes and they are OK. See `createContainerRef` in
        // `view_engine_compatibility` for additional context.
        assertGreaterThanOrEqual(index, HEADER_OFFSET, 'TNodes can\'t be in the LView header.');
    // Keep this function short, so that the VM will inline it.
    ngDevMode && assertPureTNodeType(type);
    let tNode = tView.data[index];
    if (tNode === null) {
        tNode = createTNodeAtIndex(tView, index, type, name, attrs);
        if (isInI18nBlock()) {
            // If we are in i18n block then all elements should be pre declared through `Placeholder`
            // See `TNodeType.Placeholder` and `LFrame.inI18n` for more context.
            // If the `TNode` was not pre-declared than it means it was not mentioned which means it was
            // removed, so we mark it as detached.
            tNode.flags |= 32 /* TNodeFlags.isDetached */;
        }
    }
    else if (tNode.type & 64 /* TNodeType.Placeholder */) {
        tNode.type = type;
        tNode.value = name;
        tNode.attrs = attrs;
        const parent = getCurrentParentTNode();
        tNode.injectorIndex = parent === null ? -1 : parent.injectorIndex;
        ngDevMode && assertTNodeForTView(tNode, tView);
        ngDevMode && assertEqual(index, tNode.index, 'Expecting same index');
    }
    setCurrentTNode(tNode, true);
    return tNode;
}
export function createTNodeAtIndex(tView, index, type, name, attrs) {
    const currentTNode = getCurrentTNodePlaceholderOk();
    const isParent = isCurrentTNodeParent();
    const parent = isParent ? currentTNode : currentTNode && currentTNode.parent;
    // Parents cannot cross component boundaries because components will be used in multiple places.
    const tNode = tView.data[index] =
        createTNode(tView, parent, type, index, name, attrs);
    // Assign a pointer to the first child node of a given view. The first node is not always the one
    // at index 0, in case of i18n, index 0 can be the instruction `i18nStart` and the first node has
    // the index 1 or more, so we can't just check node index.
    if (tView.firstChild === null) {
        tView.firstChild = tNode;
    }
    if (currentTNode !== null) {
        if (isParent) {
            // FIXME(misko): This logic looks unnecessarily complicated. Could we simplify?
            if (currentTNode.child == null && tNode.parent !== null) {
                // We are in the same view, which means we are adding content node to the parent view.
                currentTNode.child = tNode;
            }
        }
        else {
            if (currentTNode.next === null) {
                // In the case of i18n the `currentTNode` may already be linked, in which case we don't want
                // to break the links which i18n created.
                currentTNode.next = tNode;
                tNode.prev = currentTNode;
            }
        }
    }
    return tNode;
}
/**
 * When elements are created dynamically after a view blueprint is created (e.g. through
 * i18nApply()), we need to adjust the blueprint for future
 * template passes.
 *
 * @param tView `TView` associated with `LView`
 * @param lView The `LView` containing the blueprint to adjust
 * @param numSlotsToAlloc The number of slots to alloc in the LView, should be >0
 * @param initialValue Initial value to store in blueprint
 */
export function allocExpando(tView, lView, numSlotsToAlloc, initialValue) {
    if (numSlotsToAlloc === 0)
        return -1;
    if (ngDevMode) {
        assertFirstCreatePass(tView);
        assertSame(tView, lView[TVIEW], '`LView` must be associated with `TView`!');
        assertEqual(tView.data.length, lView.length, 'Expecting LView to be same size as TView');
        assertEqual(tView.data.length, tView.blueprint.length, 'Expecting Blueprint to be same size as TView');
        assertFirstUpdatePass(tView);
    }
    const allocIdx = lView.length;
    for (let i = 0; i < numSlotsToAlloc; i++) {
        lView.push(initialValue);
        tView.blueprint.push(initialValue);
        tView.data.push(null);
    }
    return allocIdx;
}
export function executeTemplate(tView, lView, templateFn, rf, context) {
    const consumer = getReactiveLViewConsumer(lView, REACTIVE_TEMPLATE_CONSUMER);
    const prevSelectedIndex = getSelectedIndex();
    const isUpdatePhase = rf & 2 /* RenderFlags.Update */;
    try {
        setSelectedIndex(-1);
        if (isUpdatePhase && lView.length > HEADER_OFFSET) {
            // When we're updating, inherently select 0 so we don't
            // have to generate that instruction for most update blocks.
            selectIndexInternal(tView, lView, HEADER_OFFSET, !!ngDevMode && isInCheckNoChangesMode());
        }
        const preHookType = isUpdatePhase ? 2 /* ProfilerEvent.TemplateUpdateStart */ : 0 /* ProfilerEvent.TemplateCreateStart */;
        profiler(preHookType, context);
        if (isUpdatePhase) {
            consumer.runInContext(templateFn, rf, context);
        }
        else {
            const prevConsumer = setActiveConsumer(null);
            try {
                templateFn(rf, context);
            }
            finally {
                setActiveConsumer(prevConsumer);
            }
        }
    }
    finally {
        if (isUpdatePhase && lView[REACTIVE_TEMPLATE_CONSUMER] === null) {
            commitLViewConsumerIfHasProducers(lView, REACTIVE_TEMPLATE_CONSUMER);
        }
        setSelectedIndex(prevSelectedIndex);
        const postHookType = isUpdatePhase ? 3 /* ProfilerEvent.TemplateUpdateEnd */ : 1 /* ProfilerEvent.TemplateCreateEnd */;
        profiler(postHookType, context);
    }
}
//////////////////////////
//// Element
//////////////////////////
export function executeContentQueries(tView, tNode, lView) {
    if (isContentQueryHost(tNode)) {
        const prevConsumer = setActiveConsumer(null);
        try {
            const start = tNode.directiveStart;
            const end = tNode.directiveEnd;
            for (let directiveIndex = start; directiveIndex < end; directiveIndex++) {
                const def = tView.data[directiveIndex];
                if (def.contentQueries) {
                    def.contentQueries(1 /* RenderFlags.Create */, lView[directiveIndex], directiveIndex);
                }
            }
        }
        finally {
            setActiveConsumer(prevConsumer);
        }
    }
}
/**
 * Creates directive instances.
 */
export function createDirectivesInstances(tView, lView, tNode) {
    if (!getBindingsEnabled())
        return;
    instantiateAllDirectives(tView, lView, tNode, getNativeByTNode(tNode, lView));
    if ((tNode.flags & 64 /* TNodeFlags.hasHostBindings */) === 64 /* TNodeFlags.hasHostBindings */) {
        invokeDirectivesHostBindings(tView, lView, tNode);
    }
}
/**
 * Takes a list of local names and indices and pushes the resolved local variable values
 * to LView in the same order as they are loaded in the template with load().
 */
export function saveResolvedLocalsInData(viewData, tNode, localRefExtractor = getNativeByTNode) {
    const localNames = tNode.localNames;
    if (localNames !== null) {
        let localIndex = tNode.index + 1;
        for (let i = 0; i < localNames.length; i += 2) {
            const index = localNames[i + 1];
            const value = index === -1 ?
                localRefExtractor(tNode, viewData) :
                viewData[index];
            viewData[localIndex++] = value;
        }
    }
}
/**
 * Gets TView from a template function or creates a new TView
 * if it doesn't already exist.
 *
 * @param def ComponentDef
 * @returns TView
 */
export function getOrCreateComponentTView(def) {
    const tView = def.tView;
    // Create a TView if there isn't one, or recreate it if the first create pass didn't
    // complete successfully since we can't know for sure whether it's in a usable shape.
    if (tView === null || tView.incompleteFirstPass) {
        // Declaration node here is null since this function is called when we dynamically create a
        // component and hence there is no declaration.
        const declTNode = null;
        return def.tView = createTView(1 /* TViewType.Component */, declTNode, def.template, def.decls, def.vars, def.directiveDefs, def.pipeDefs, def.viewQuery, def.schemas, def.consts, def.id);
    }
    return tView;
}
/**
 * Creates a TView instance
 *
 * @param type Type of `TView`.
 * @param declTNode Declaration location of this `TView`.
 * @param templateFn Template function
 * @param decls The number of nodes, local refs, and pipes in this template
 * @param directives Registry of directives for this view
 * @param pipes Registry of pipes for this view
 * @param viewQuery View queries for this view
 * @param schemas Schemas for this view
 * @param consts Constants for this view
 */
export function createTView(type, declTNode, templateFn, decls, vars, directives, pipes, viewQuery, schemas, constsOrFactory, ssrId) {
    ngDevMode && ngDevMode.tView++;
    const bindingStartIndex = HEADER_OFFSET + decls;
    // This length does not yet contain host bindings from child directives because at this point,
    // we don't know which directives are active on this template. As soon as a directive is matched
    // that has a host binding, we will update the blueprint with that def's hostVars count.
    const initialViewLength = bindingStartIndex + vars;
    const blueprint = createViewBlueprint(bindingStartIndex, initialViewLength);
    const consts = typeof constsOrFactory === 'function' ? constsOrFactory() : constsOrFactory;
    const tView = blueprint[TVIEW] = {
        type: type,
        blueprint: blueprint,
        template: templateFn,
        queries: null,
        viewQuery: viewQuery,
        declTNode: declTNode,
        data: blueprint.slice().fill(null, bindingStartIndex),
        bindingStartIndex: bindingStartIndex,
        expandoStartIndex: initialViewLength,
        hostBindingOpCodes: null,
        firstCreatePass: true,
        firstUpdatePass: true,
        staticViewQueries: false,
        staticContentQueries: false,
        preOrderHooks: null,
        preOrderCheckHooks: null,
        contentHooks: null,
        contentCheckHooks: null,
        viewHooks: null,
        viewCheckHooks: null,
        destroyHooks: null,
        cleanup: null,
        contentQueries: null,
        components: null,
        directiveRegistry: typeof directives === 'function' ? directives() : directives,
        pipeRegistry: typeof pipes === 'function' ? pipes() : pipes,
        firstChild: null,
        schemas: schemas,
        consts: consts,
        incompleteFirstPass: false,
        ssrId,
    };
    if (ngDevMode) {
        // For performance reasons it is important that the tView retains the same shape during runtime.
        // (To make sure that all of the code is monomorphic.) For this reason we seal the object to
        // prevent class transitions.
        Object.seal(tView);
    }
    return tView;
}
function createViewBlueprint(bindingStartIndex, initialViewLength) {
    const blueprint = [];
    for (let i = 0; i < initialViewLength; i++) {
        blueprint.push(i < bindingStartIndex ? null : NO_CHANGE);
    }
    return blueprint;
}
/**
 * Locates the host native element, used for bootstrapping existing nodes into rendering pipeline.
 *
 * @param renderer the renderer used to locate the element.
 * @param elementOrSelector Render element or CSS selector to locate the element.
 * @param encapsulation View Encapsulation defined for component that requests host element.
 * @param injector Root view injector instance.
 */
export function locateHostElement(renderer, elementOrSelector, encapsulation, injector) {
    // Note: we use default value for the `PRESERVE_HOST_CONTENT` here even though it's a
    // tree-shakable one (providedIn:'root'). This code path can be triggered during dynamic
    // component creation (after calling ViewContainerRef.createComponent) when an injector
    // instance can be provided. The injector instance might be disconnected from the main DI
    // tree, thus the `PRESERVE_HOST_CONTENT` would not be able to instantiate. In this case, the
    // default value will be used.
    const preserveHostContent = injector.get(PRESERVE_HOST_CONTENT, PRESERVE_HOST_CONTENT_DEFAULT);
    // When using native Shadow DOM, do not clear host element to allow native slot
    // projection.
    const preserveContent = preserveHostContent || encapsulation === ViewEncapsulation.ShadowDom;
    const rootElement = renderer.selectRootElement(elementOrSelector, preserveContent);
    applyRootElementTransform(rootElement);
    return rootElement;
}
/**
 * Applies any root element transformations that are needed. If hydration is enabled,
 * this will process corrupted text nodes.
 *
 * @param rootElement the app root HTML Element
 */
export function applyRootElementTransform(rootElement) {
    _applyRootElementTransformImpl(rootElement);
}
/**
 * Reference to a function that applies transformations to the root HTML element
 * of an app. When hydration is enabled, this processes any corrupt text nodes
 * so they are properly hydratable on the client.
 *
 * @param rootElement the app root HTML Element
 */
let _applyRootElementTransformImpl = (rootElement) => null;
/**
 * Processes text node markers before hydration begins. This replaces any special comment
 * nodes that were added prior to serialization are swapped out to restore proper text
 * nodes before hydration.
 *
 * @param rootElement the app root HTML Element
 */
export function applyRootElementTransformImpl(rootElement) {
    if (rootElement.hasAttribute(SKIP_HYDRATION_ATTR_NAME)) {
        // Handle a situation when the `ngSkipHydration` attribute is applied
        // to the root node of an application. In this case, we should clear
        // the contents and render everything from scratch.
        clearElementContents(rootElement);
    }
    else {
        processTextNodeMarkersBeforeHydration(rootElement);
    }
}
/**
 * Sets the implementation for the `applyRootElementTransform` function.
 */
export function enableApplyRootElementTransformImpl() {
    _applyRootElementTransformImpl = applyRootElementTransformImpl;
}
/**
 * Saves context for this cleanup function in LView.cleanupInstances.
 *
 * On the first template pass, saves in TView:
 * - Cleanup function
 * - Index of context we just saved in LView.cleanupInstances
 */
export function storeCleanupWithContext(tView, lView, context, cleanupFn) {
    const lCleanup = getOrCreateLViewCleanup(lView);
    // Historically the `storeCleanupWithContext` was used to register both framework-level and
    // user-defined cleanup callbacks, but over time those two types of cleanups were separated.
    // This dev mode checks assures that user-level cleanup callbacks are _not_ stored in data
    // structures reserved for framework-specific hooks.
    ngDevMode &&
        assertDefined(context, 'Cleanup context is mandatory when registering framework-level destroy hooks');
    lCleanup.push(context);
    if (tView.firstCreatePass) {
        getOrCreateTViewCleanup(tView).push(cleanupFn, lCleanup.length - 1);
    }
    else {
        // Make sure that no new framework-level cleanup functions are registered after the first
        // template pass is done (and TView data structures are meant to fully constructed).
        if (ngDevMode) {
            Object.freeze(getOrCreateTViewCleanup(tView));
        }
    }
}
export function createTNode(tView, tParent, type, index, value, attrs) {
    ngDevMode && index !== 0 && // 0 are bogus nodes and they are OK. See `createContainerRef` in
        // `view_engine_compatibility` for additional context.
        assertGreaterThanOrEqual(index, HEADER_OFFSET, 'TNodes can\'t be in the LView header.');
    ngDevMode && assertNotSame(attrs, undefined, '\'undefined\' is not valid value for \'attrs\'');
    ngDevMode && ngDevMode.tNode++;
    ngDevMode && tParent && assertTNodeForTView(tParent, tView);
    let injectorIndex = tParent ? tParent.injectorIndex : -1;
    const tNode = {
        type,
        index,
        insertBeforeIndex: null,
        injectorIndex,
        directiveStart: -1,
        directiveEnd: -1,
        directiveStylingLast: -1,
        componentOffset: -1,
        propertyBindings: null,
        flags: 0,
        providerIndexes: 0,
        value: value,
        attrs: attrs,
        mergedAttrs: null,
        localNames: null,
        initialInputs: undefined,
        inputs: null,
        outputs: null,
        tView: null,
        next: null,
        prev: null,
        projectionNext: null,
        child: null,
        parent: tParent,
        projection: null,
        styles: null,
        stylesWithoutHost: null,
        residualStyles: undefined,
        classes: null,
        classesWithoutHost: null,
        residualClasses: undefined,
        classBindings: 0,
        styleBindings: 0,
    };
    if (ngDevMode) {
        // For performance reasons it is important that the tNode retains the same shape during runtime.
        // (To make sure that all of the code is monomorphic.) For this reason we seal the object to
        // prevent class transitions.
        Object.seal(tNode);
    }
    return tNode;
}
/**
 * Generates the `PropertyAliases` data structure from the provided input/output mapping.
 * @param aliasMap Input/output mapping from the directive definition.
 * @param directiveIndex Index of the directive.
 * @param propertyAliases Object in which to store the results.
 * @param hostDirectiveAliasMap Object used to alias or filter out properties for host directives.
 * If the mapping is provided, it'll act as an allowlist, as well as a mapping of what public
 * name inputs/outputs should be exposed under.
 */
function generatePropertyAliases(aliasMap, directiveIndex, propertyAliases, hostDirectiveAliasMap) {
    for (let publicName in aliasMap) {
        if (aliasMap.hasOwnProperty(publicName)) {
            propertyAliases = propertyAliases === null ? {} : propertyAliases;
            const internalName = aliasMap[publicName];
            // If there are no host directive mappings, we want to remap using the alias map from the
            // definition itself. If there is an alias map, it has two functions:
            // 1. It serves as an allowlist of bindings that are exposed by the host directives. Only the
            // ones inside the host directive map will be exposed on the host.
            // 2. The public name of the property is aliased using the host directive alias map, rather
            // than the alias map from the definition.
            if (hostDirectiveAliasMap === null) {
                addPropertyAlias(propertyAliases, directiveIndex, publicName, internalName);
            }
            else if (hostDirectiveAliasMap.hasOwnProperty(publicName)) {
                addPropertyAlias(propertyAliases, directiveIndex, hostDirectiveAliasMap[publicName], internalName);
            }
        }
    }
    return propertyAliases;
}
function addPropertyAlias(propertyAliases, directiveIndex, publicName, internalName) {
    if (propertyAliases.hasOwnProperty(publicName)) {
        propertyAliases[publicName].push(directiveIndex, internalName);
    }
    else {
        propertyAliases[publicName] = [directiveIndex, internalName];
    }
}
/**
 * Initializes data structures required to work with directive inputs and outputs.
 * Initialization is done for all directives matched on a given TNode.
 */
function initializeInputAndOutputAliases(tView, tNode, hostDirectiveDefinitionMap) {
    ngDevMode && assertFirstCreatePass(tView);
    const start = tNode.directiveStart;
    const end = tNode.directiveEnd;
    const tViewData = tView.data;
    const tNodeAttrs = tNode.attrs;
    const inputsFromAttrs = [];
    let inputsStore = null;
    let outputsStore = null;
    for (let directiveIndex = start; directiveIndex < end; directiveIndex++) {
        const directiveDef = tViewData[directiveIndex];
        const aliasData = hostDirectiveDefinitionMap ? hostDirectiveDefinitionMap.get(directiveDef) : null;
        const aliasedInputs = aliasData ? aliasData.inputs : null;
        const aliasedOutputs = aliasData ? aliasData.outputs : null;
        inputsStore =
            generatePropertyAliases(directiveDef.inputs, directiveIndex, inputsStore, aliasedInputs);
        outputsStore =
            generatePropertyAliases(directiveDef.outputs, directiveIndex, outputsStore, aliasedOutputs);
        // Do not use unbound attributes as inputs to structural directives, since structural
        // directive inputs can only be set using microsyntax (e.g. `<div *dir="exp">`).
        // TODO(FW-1930): microsyntax expressions may also contain unbound/static attributes, which
        // should be set for inline templates.
        const initialInputs = (inputsStore !== null && tNodeAttrs !== null && !isInlineTemplate(tNode)) ?
            generateInitialInputs(inputsStore, directiveIndex, tNodeAttrs) :
            null;
        inputsFromAttrs.push(initialInputs);
    }
    if (inputsStore !== null) {
        if (inputsStore.hasOwnProperty('class')) {
            tNode.flags |= 8 /* TNodeFlags.hasClassInput */;
        }
        if (inputsStore.hasOwnProperty('style')) {
            tNode.flags |= 16 /* TNodeFlags.hasStyleInput */;
        }
    }
    tNode.initialInputs = inputsFromAttrs;
    tNode.inputs = inputsStore;
    tNode.outputs = outputsStore;
}
/**
 * Mapping between attributes names that don't correspond to their element property names.
 *
 * Performance note: this function is written as a series of if checks (instead of, say, a property
 * object lookup) for performance reasons - the series of `if` checks seems to be the fastest way of
 * mapping property names. Do NOT change without benchmarking.
 *
 * Note: this mapping has to be kept in sync with the equally named mapping in the template
 * type-checking machinery of ngtsc.
 */
function mapPropName(name) {
    if (name === 'class')
        return 'className';
    if (name === 'for')
        return 'htmlFor';
    if (name === 'formaction')
        return 'formAction';
    if (name === 'innerHtml')
        return 'innerHTML';
    if (name === 'readonly')
        return 'readOnly';
    if (name === 'tabindex')
        return 'tabIndex';
    return name;
}
export function elementPropertyInternal(tView, tNode, lView, propName, value, renderer, sanitizer, nativeOnly) {
    ngDevMode && assertNotSame(value, NO_CHANGE, 'Incoming value should never be NO_CHANGE.');
    const element = getNativeByTNode(tNode, lView);
    let inputData = tNode.inputs;
    let dataValue;
    if (!nativeOnly && inputData != null && (dataValue = inputData[propName])) {
        setInputsForProperty(tView, lView, dataValue, propName, value);
        if (isComponentHost(tNode))
            markDirtyIfOnPush(lView, tNode.index);
        if (ngDevMode) {
            setNgReflectProperties(lView, element, tNode.type, dataValue, value);
        }
    }
    else if (tNode.type & 3 /* TNodeType.AnyRNode */) {
        propName = mapPropName(propName);
        if (ngDevMode) {
            validateAgainstEventProperties(propName);
            if (!isPropertyValid(element, propName, tNode.value, tView.schemas)) {
                handleUnknownPropertyError(propName, tNode.value, tNode.type, lView);
            }
            ngDevMode.rendererSetProperty++;
        }
        // It is assumed that the sanitizer is only added when the compiler determines that the
        // property is risky, so sanitization can be done without further checks.
        value = sanitizer != null ? sanitizer(value, tNode.value || '', propName) : value;
        renderer.setProperty(element, propName, value);
    }
    else if (tNode.type & 12 /* TNodeType.AnyContainer */) {
        // If the node is a container and the property didn't
        // match any of the inputs or schemas we should throw.
        if (ngDevMode && !matchingSchemas(tView.schemas, tNode.value)) {
            handleUnknownPropertyError(propName, tNode.value, tNode.type, lView);
        }
    }
}
/** If node is an OnPush component, marks its LView dirty. */
export function markDirtyIfOnPush(lView, viewIndex) {
    ngDevMode && assertLView(lView);
    const childComponentLView = getComponentLViewByIndex(viewIndex, lView);
    if (!(childComponentLView[FLAGS] & 16 /* LViewFlags.CheckAlways */)) {
        childComponentLView[FLAGS] |= 64 /* LViewFlags.Dirty */;
    }
}
function setNgReflectProperty(lView, element, type, attrName, value) {
    const renderer = lView[RENDERER];
    attrName = normalizeDebugBindingName(attrName);
    const debugValue = normalizeDebugBindingValue(value);
    if (type & 3 /* TNodeType.AnyRNode */) {
        if (value == null) {
            renderer.removeAttribute(element, attrName);
        }
        else {
            renderer.setAttribute(element, attrName, debugValue);
        }
    }
    else {
        const textContent = escapeCommentText(`bindings=${JSON.stringify({ [attrName]: debugValue }, null, 2)}`);
        renderer.setValue(element, textContent);
    }
}
export function setNgReflectProperties(lView, element, type, dataValue, value) {
    if (type & (3 /* TNodeType.AnyRNode */ | 4 /* TNodeType.Container */)) {
        /**
         * dataValue is an array containing runtime input or output names for the directives:
         * i+0: directive instance index
         * i+1: privateName
         *
         * e.g. [0, 'change', 'change-minified']
         * we want to set the reflected property with the privateName: dataValue[i+1]
         */
        for (let i = 0; i < dataValue.length; i += 2) {
            setNgReflectProperty(lView, element, type, dataValue[i + 1], value);
        }
    }
}
/**
 * Resolve the matched directives on a node.
 */
export function resolveDirectives(tView, lView, tNode, localRefs) {
    // Please make sure to have explicit type for `exportsMap`. Inferred type triggers bug in
    // tsickle.
    ngDevMode && assertFirstCreatePass(tView);
    if (getBindingsEnabled()) {
        const exportsMap = localRefs === null ? null : { '': -1 };
        const matchResult = findDirectiveDefMatches(tView, tNode);
        let directiveDefs;
        let hostDirectiveDefs;
        if (matchResult === null) {
            directiveDefs = hostDirectiveDefs = null;
        }
        else {
            [directiveDefs, hostDirectiveDefs] = matchResult;
        }
        if (directiveDefs !== null) {
            initializeDirectives(tView, lView, tNode, directiveDefs, exportsMap, hostDirectiveDefs);
        }
        if (exportsMap)
            cacheMatchingLocalNames(tNode, localRefs, exportsMap);
    }
    // Merge the template attrs last so that they have the highest priority.
    tNode.mergedAttrs = mergeHostAttrs(tNode.mergedAttrs, tNode.attrs);
}
/** Initializes the data structures necessary for a list of directives to be instantiated. */
export function initializeDirectives(tView, lView, tNode, directives, exportsMap, hostDirectiveDefs) {
    ngDevMode && assertFirstCreatePass(tView);
    // Publishes the directive types to DI so they can be injected. Needs to
    // happen in a separate pass before the TNode flags have been initialized.
    for (let i = 0; i < directives.length; i++) {
        diPublicInInjector(getOrCreateNodeInjectorForNode(tNode, lView), tView, directives[i].type);
    }
    initTNodeFlags(tNode, tView.data.length, directives.length);
    // When the same token is provided by several directives on the same node, some rules apply in
    // the viewEngine:
    // - viewProviders have priority over providers
    // - the last directive in NgModule.declarations has priority over the previous one
    // So to match these rules, the order in which providers are added in the arrays is very
    // important.
    for (let i = 0; i < directives.length; i++) {
        const def = directives[i];
        if (def.providersResolver)
            def.providersResolver(def);
    }
    let preOrderHooksFound = false;
    let preOrderCheckHooksFound = false;
    let directiveIdx = allocExpando(tView, lView, directives.length, null);
    ngDevMode &&
        assertSame(directiveIdx, tNode.directiveStart, 'TNode.directiveStart should point to just allocated space');
    for (let i = 0; i < directives.length; i++) {
        const def = directives[i];
        // Merge the attrs in the order of matches. This assumes that the first directive is the
        // component itself, so that the component has the least priority.
        tNode.mergedAttrs = mergeHostAttrs(tNode.mergedAttrs, def.hostAttrs);
        configureViewWithDirective(tView, tNode, lView, directiveIdx, def);
        saveNameToExportMap(directiveIdx, def, exportsMap);
        if (def.contentQueries !== null)
            tNode.flags |= 4 /* TNodeFlags.hasContentQuery */;
        if (def.hostBindings !== null || def.hostAttrs !== null || def.hostVars !== 0)
            tNode.flags |= 64 /* TNodeFlags.hasHostBindings */;
        const lifeCycleHooks = def.type.prototype;
        // Only push a node index into the preOrderHooks array if this is the first
        // pre-order hook found on this node.
        if (!preOrderHooksFound &&
            (lifeCycleHooks.ngOnChanges || lifeCycleHooks.ngOnInit || lifeCycleHooks.ngDoCheck)) {
            // We will push the actual hook function into this array later during dir instantiation.
            // We cannot do it now because we must ensure hooks are registered in the same
            // order that directives are created (i.e. injection order).
            (tView.preOrderHooks ??= []).push(tNode.index);
            preOrderHooksFound = true;
        }
        if (!preOrderCheckHooksFound && (lifeCycleHooks.ngOnChanges || lifeCycleHooks.ngDoCheck)) {
            (tView.preOrderCheckHooks ??= []).push(tNode.index);
            preOrderCheckHooksFound = true;
        }
        directiveIdx++;
    }
    initializeInputAndOutputAliases(tView, tNode, hostDirectiveDefs);
}
/**
 * Add `hostBindings` to the `TView.hostBindingOpCodes`.
 *
 * @param tView `TView` to which the `hostBindings` should be added.
 * @param tNode `TNode` the element which contains the directive
 * @param directiveIdx Directive index in view.
 * @param directiveVarsIdx Where will the directive's vars be stored
 * @param def `ComponentDef`/`DirectiveDef`, which contains the `hostVars`/`hostBindings` to add.
 */
export function registerHostBindingOpCodes(tView, tNode, directiveIdx, directiveVarsIdx, def) {
    ngDevMode && assertFirstCreatePass(tView);
    const hostBindings = def.hostBindings;
    if (hostBindings) {
        let hostBindingOpCodes = tView.hostBindingOpCodes;
        if (hostBindingOpCodes === null) {
            hostBindingOpCodes = tView.hostBindingOpCodes = [];
        }
        const elementIndx = ~tNode.index;
        if (lastSelectedElementIdx(hostBindingOpCodes) != elementIndx) {
            // Conditionally add select element so that we are more efficient in execution.
            // NOTE: this is strictly not necessary and it trades code size for runtime perf.
            // (We could just always add it.)
            hostBindingOpCodes.push(elementIndx);
        }
        hostBindingOpCodes.push(directiveIdx, directiveVarsIdx, hostBindings);
    }
}
/**
 * Returns the last selected element index in the `HostBindingOpCodes`
 *
 * For perf reasons we don't need to update the selected element index in `HostBindingOpCodes` only
 * if it changes. This method returns the last index (or '0' if not found.)
 *
 * Selected element index are only the ones which are negative.
 */
function lastSelectedElementIdx(hostBindingOpCodes) {
    let i = hostBindingOpCodes.length;
    while (i > 0) {
        const value = hostBindingOpCodes[--i];
        if (typeof value === 'number' && value < 0) {
            return value;
        }
    }
    return 0;
}
/**
 * Instantiate all the directives that were previously resolved on the current node.
 */
function instantiateAllDirectives(tView, lView, tNode, native) {
    const start = tNode.directiveStart;
    const end = tNode.directiveEnd;
    // The component view needs to be created before creating the node injector
    // since it is used to inject some special symbols like `ChangeDetectorRef`.
    if (isComponentHost(tNode)) {
        ngDevMode && assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */);
        addComponentLogic(lView, tNode, tView.data[start + tNode.componentOffset]);
    }
    if (!tView.firstCreatePass) {
        getOrCreateNodeInjectorForNode(tNode, lView);
    }
    attachPatchData(native, lView);
    const initialInputs = tNode.initialInputs;
    for (let i = start; i < end; i++) {
        const def = tView.data[i];
        const directive = getNodeInjectable(lView, tView, i, tNode);
        attachPatchData(directive, lView);
        if (initialInputs !== null) {
            setInputsFromAttrs(lView, i - start, directive, def, tNode, initialInputs);
        }
        if (isComponentDef(def)) {
            const componentView = getComponentLViewByIndex(tNode.index, lView);
            componentView[CONTEXT] = getNodeInjectable(lView, tView, i, tNode);
        }
    }
}
export function invokeDirectivesHostBindings(tView, lView, tNode) {
    const start = tNode.directiveStart;
    const end = tNode.directiveEnd;
    const elementIndex = tNode.index;
    const currentDirectiveIndex = getCurrentDirectiveIndex();
    try {
        setSelectedIndex(elementIndex);
        for (let dirIndex = start; dirIndex < end; dirIndex++) {
            const def = tView.data[dirIndex];
            const directive = lView[dirIndex];
            setCurrentDirectiveIndex(dirIndex);
            if (def.hostBindings !== null || def.hostVars !== 0 || def.hostAttrs !== null) {
                invokeHostBindingsInCreationMode(def, directive);
            }
        }
    }
    finally {
        setSelectedIndex(-1);
        setCurrentDirectiveIndex(currentDirectiveIndex);
    }
}
/**
 * Invoke the host bindings in creation mode.
 *
 * @param def `DirectiveDef` which may contain the `hostBindings` function.
 * @param directive Instance of directive.
 */
export function invokeHostBindingsInCreationMode(def, directive) {
    if (def.hostBindings !== null) {
        def.hostBindings(1 /* RenderFlags.Create */, directive);
    }
}
/**
 * Matches the current node against all available selectors.
 * If a component is matched (at most one), it is returned in first position in the array.
 */
function findDirectiveDefMatches(tView, tNode) {
    ngDevMode && assertFirstCreatePass(tView);
    ngDevMode && assertTNodeType(tNode, 3 /* TNodeType.AnyRNode */ | 12 /* TNodeType.AnyContainer */);
    const registry = tView.directiveRegistry;
    let matches = null;
    let hostDirectiveDefs = null;
    if (registry) {
        for (let i = 0; i < registry.length; i++) {
            const def = registry[i];
            if (isNodeMatchingSelectorList(tNode, def.selectors, /* isProjectionMode */ false)) {
                matches || (matches = []);
                if (isComponentDef(def)) {
                    if (ngDevMode) {
                        assertTNodeType(tNode, 2 /* TNodeType.Element */, `"${tNode.value}" tags cannot be used as component hosts. ` +
                            `Please use a different tag to activate the ${stringify(def.type)} component.`);
                        if (isComponentHost(tNode)) {
                            throwMultipleComponentError(tNode, matches.find(isComponentDef).type, def.type);
                        }
                    }
                    // Components are inserted at the front of the matches array so that their lifecycle
                    // hooks run before any directive lifecycle hooks. This appears to be for ViewEngine
                    // compatibility. This logic doesn't make sense with host directives, because it
                    // would allow the host directives to undo any overrides the host may have made.
                    // To handle this case, the host directives of components are inserted at the beginning
                    // of the array, followed by the component. As such, the insertion order is as follows:
                    // 1. Host directives belonging to the selector-matched component.
                    // 2. Selector-matched component.
                    // 3. Host directives belonging to selector-matched directives.
                    // 4. Selector-matched directives.
                    if (def.findHostDirectiveDefs !== null) {
                        const hostDirectiveMatches = [];
                        hostDirectiveDefs = hostDirectiveDefs || new Map();
                        def.findHostDirectiveDefs(def, hostDirectiveMatches, hostDirectiveDefs);
                        // Add all host directives declared on this component, followed by the component itself.
                        // Host directives should execute first so the host has a chance to override changes
                        // to the DOM made by them.
                        matches.unshift(...hostDirectiveMatches, def);
                        // Component is offset starting from the beginning of the host directives array.
                        const componentOffset = hostDirectiveMatches.length;
                        markAsComponentHost(tView, tNode, componentOffset);
                    }
                    else {
                        // No host directives on this component, just add the
                        // component def to the beginning of the matches.
                        matches.unshift(def);
                        markAsComponentHost(tView, tNode, 0);
                    }
                }
                else {
                    // Append any host directives to the matches first.
                    hostDirectiveDefs = hostDirectiveDefs || new Map();
                    def.findHostDirectiveDefs?.(def, matches, hostDirectiveDefs);
                    matches.push(def);
                }
            }
        }
    }
    return matches === null ? null : [matches, hostDirectiveDefs];
}
/**
 * Marks a given TNode as a component's host. This consists of:
 * - setting the component offset on the TNode.
 * - storing index of component's host element so it will be queued for view refresh during CD.
 */
export function markAsComponentHost(tView, hostTNode, componentOffset) {
    ngDevMode && assertFirstCreatePass(tView);
    ngDevMode && assertGreaterThan(componentOffset, -1, 'componentOffset must be great than -1');
    hostTNode.componentOffset = componentOffset;
    (tView.components ??= []).push(hostTNode.index);
}
/** Caches local names and their matching directive indices for query and template lookups. */
function cacheMatchingLocalNames(tNode, localRefs, exportsMap) {
    if (localRefs) {
        const localNames = tNode.localNames = [];
        // Local names must be stored in tNode in the same order that localRefs are defined
        // in the template to ensure the data is loaded in the same slots as their refs
        // in the template (for template queries).
        for (let i = 0; i < localRefs.length; i += 2) {
            const index = exportsMap[localRefs[i + 1]];
            if (index == null)
                throw new RuntimeError(-301 /* RuntimeErrorCode.EXPORT_NOT_FOUND */, ngDevMode && `Export of name '${localRefs[i + 1]}' not found!`);
            localNames.push(localRefs[i], index);
        }
    }
}
/**
 * Builds up an export map as directives are created, so local refs can be quickly mapped
 * to their directive instances.
 */
function saveNameToExportMap(directiveIdx, def, exportsMap) {
    if (exportsMap) {
        if (def.exportAs) {
            for (let i = 0; i < def.exportAs.length; i++) {
                exportsMap[def.exportAs[i]] = directiveIdx;
            }
        }
        if (isComponentDef(def))
            exportsMap[''] = directiveIdx;
    }
}
/**
 * Initializes the flags on the current node, setting all indices to the initial index,
 * the directive count to 0, and adding the isComponent flag.
 * @param index the initial index
 */
export function initTNodeFlags(tNode, index, numberOfDirectives) {
    ngDevMode &&
        assertNotEqual(numberOfDirectives, tNode.directiveEnd - tNode.directiveStart, 'Reached the max number of directives');
    tNode.flags |= 1 /* TNodeFlags.isDirectiveHost */;
    // When the first directive is created on a node, save the index
    tNode.directiveStart = index;
    tNode.directiveEnd = index + numberOfDirectives;
    tNode.providerIndexes = index;
}
/**
 * Setup directive for instantiation.
 *
 * We need to create a `NodeInjectorFactory` which is then inserted in both the `Blueprint` as well
 * as `LView`. `TView` gets the `DirectiveDef`.
 *
 * @param tView `TView`
 * @param tNode `TNode`
 * @param lView `LView`
 * @param directiveIndex Index where the directive will be stored in the Expando.
 * @param def `DirectiveDef`
 */
export function configureViewWithDirective(tView, tNode, lView, directiveIndex, def) {
    ngDevMode &&
        assertGreaterThanOrEqual(directiveIndex, HEADER_OFFSET, 'Must be in Expando section');
    tView.data[directiveIndex] = def;
    const directiveFactory = def.factory || (def.factory = getFactoryDef(def.type, true));
    // Even though `directiveFactory` will already be using `ɵɵdirectiveInject` in its generated code,
    // we also want to support `inject()` directly from the directive constructor context so we set
    // `ɵɵdirectiveInject` as the inject implementation here too.
    const nodeInjectorFactory = new NodeInjectorFactory(directiveFactory, isComponentDef(def), ɵɵdirectiveInject);
    tView.blueprint[directiveIndex] = nodeInjectorFactory;
    lView[directiveIndex] = nodeInjectorFactory;
    registerHostBindingOpCodes(tView, tNode, directiveIndex, allocExpando(tView, lView, def.hostVars, NO_CHANGE), def);
}
function addComponentLogic(lView, hostTNode, def) {
    const native = getNativeByTNode(hostTNode, lView);
    const tView = getOrCreateComponentTView(def);
    // Only component views should be added to the view tree directly. Embedded views are
    // accessed through their containers because they may be removed / re-added later.
    const rendererFactory = lView[ENVIRONMENT].rendererFactory;
    const componentView = addToViewTree(lView, createLView(lView, tView, null, def.onPush ? 64 /* LViewFlags.Dirty */ : 16 /* LViewFlags.CheckAlways */, native, hostTNode, null, rendererFactory.createRenderer(native, def), null, null, null));
    // Component view will always be created before any injected LContainers,
    // so this is a regular element, wrap it with the component view
    lView[hostTNode.index] = componentView;
}
export function elementAttributeInternal(tNode, lView, name, value, sanitizer, namespace) {
    if (ngDevMode) {
        assertNotSame(value, NO_CHANGE, 'Incoming value should never be NO_CHANGE.');
        validateAgainstEventAttributes(name);
        assertTNodeType(tNode, 2 /* TNodeType.Element */, `Attempted to set attribute \`${name}\` on a container node. ` +
            `Host bindings are not valid on ng-container or ng-template.`);
    }
    const element = getNativeByTNode(tNode, lView);
    setElementAttribute(lView[RENDERER], element, namespace, tNode.value, name, value, sanitizer);
}
export function setElementAttribute(renderer, element, namespace, tagName, name, value, sanitizer) {
    if (value == null) {
        ngDevMode && ngDevMode.rendererRemoveAttribute++;
        renderer.removeAttribute(element, name, namespace);
    }
    else {
        ngDevMode && ngDevMode.rendererSetAttribute++;
        const strValue = sanitizer == null ? renderStringify(value) : sanitizer(value, tagName || '', name);
        renderer.setAttribute(element, name, strValue, namespace);
    }
}
/**
 * Sets initial input properties on directive instances from attribute data
 *
 * @param lView Current LView that is being processed.
 * @param directiveIndex Index of the directive in directives array
 * @param instance Instance of the directive on which to set the initial inputs
 * @param def The directive def that contains the list of inputs
 * @param tNode The static data for this node
 */
function setInputsFromAttrs(lView, directiveIndex, instance, def, tNode, initialInputData) {
    const initialInputs = initialInputData[directiveIndex];
    if (initialInputs !== null) {
        for (let i = 0; i < initialInputs.length;) {
            const publicName = initialInputs[i++];
            const privateName = initialInputs[i++];
            const value = initialInputs[i++];
            writeToDirectiveInput(def, instance, publicName, privateName, value);
            if (ngDevMode) {
                const nativeElement = getNativeByTNode(tNode, lView);
                setNgReflectProperty(lView, nativeElement, tNode.type, privateName, value);
            }
        }
    }
}
function writeToDirectiveInput(def, instance, publicName, privateName, value) {
    const prevConsumer = setActiveConsumer(null);
    try {
        if (def.setInput !== null) {
            def.setInput(instance, value, publicName, privateName);
        }
        else {
            instance[privateName] = value;
        }
    }
    finally {
        setActiveConsumer(prevConsumer);
    }
}
/**
 * Generates initialInputData for a node and stores it in the template's static storage
 * so subsequent template invocations don't have to recalculate it.
 *
 * initialInputData is an array containing values that need to be set as input properties
 * for directives on this node, but only once on creation. We need this array to support
 * the case where you set an @Input property of a directive using attribute-like syntax.
 * e.g. if you have a `name` @Input, you can set it once like this:
 *
 * <my-component name="Bess"></my-component>
 *
 * @param inputs Input alias map that was generated from the directive def inputs.
 * @param directiveIndex Index of the directive that is currently being processed.
 * @param attrs Static attrs on this node.
 */
function generateInitialInputs(inputs, directiveIndex, attrs) {
    let inputsToStore = null;
    let i = 0;
    while (i < attrs.length) {
        const attrName = attrs[i];
        if (attrName === 0 /* AttributeMarker.NamespaceURI */) {
            // We do not allow inputs on namespaced attributes.
            i += 4;
            continue;
        }
        else if (attrName === 5 /* AttributeMarker.ProjectAs */) {
            // Skip over the `ngProjectAs` value.
            i += 2;
            continue;
        }
        // If we hit any other attribute markers, we're done anyway. None of those are valid inputs.
        if (typeof attrName === 'number')
            break;
        if (inputs.hasOwnProperty(attrName)) {
            if (inputsToStore === null)
                inputsToStore = [];
            // Find the input's public name from the input store. Note that we can be found easier
            // through the directive def, but we want to do it using the inputs store so that it can
            // account for host directive aliases.
            const inputConfig = inputs[attrName];
            for (let j = 0; j < inputConfig.length; j += 2) {
                if (inputConfig[j] === directiveIndex) {
                    inputsToStore.push(attrName, inputConfig[j + 1], attrs[i + 1]);
                    // A directive can't have multiple inputs with the same name so we can break here.
                    break;
                }
            }
        }
        i += 2;
    }
    return inputsToStore;
}
//////////////////////////
//// ViewContainer & View
//////////////////////////
/**
 * Creates a LContainer, either from a container instruction, or for a ViewContainerRef.
 *
 * @param hostNative The host element for the LContainer
 * @param hostTNode The host TNode for the LContainer
 * @param currentView The parent view of the LContainer
 * @param native The native comment element
 * @param isForViewContainerRef Optional a flag indicating the ViewContainerRef case
 * @returns LContainer
 */
export function createLContainer(hostNative, currentView, native, tNode) {
    ngDevMode && assertLView(currentView);
    const lContainer = [
        hostNative,
        true,
        false,
        currentView,
        null,
        0,
        tNode,
        native,
        null,
        null,
        null, // dehydrated views
    ];
    ngDevMode &&
        assertEqual(lContainer.length, CONTAINER_HEADER_OFFSET, 'Should allocate correct number of slots for LContainer header.');
    return lContainer;
}
/** Refreshes all content queries declared by directives in a given view */
export function refreshContentQueries(tView, lView) {
    const contentQueries = tView.contentQueries;
    if (contentQueries !== null) {
        for (let i = 0; i < contentQueries.length; i += 2) {
            const queryStartIdx = contentQueries[i];
            const directiveDefIdx = contentQueries[i + 1];
            if (directiveDefIdx !== -1) {
                const directiveDef = tView.data[directiveDefIdx];
                ngDevMode && assertDefined(directiveDef, 'DirectiveDef not found.');
                ngDevMode &&
                    assertDefined(directiveDef.contentQueries, 'contentQueries function should be defined');
                setCurrentQueryIndex(queryStartIdx);
                directiveDef.contentQueries(2 /* RenderFlags.Update */, lView[directiveDefIdx], directiveDefIdx);
            }
        }
    }
}
/**
 * Adds LView or LContainer to the end of the current view tree.
 *
 * This structure will be used to traverse through nested views to remove listeners
 * and call onDestroy callbacks.
 *
 * @param lView The view where LView or LContainer should be added
 * @param adjustedHostIndex Index of the view's host node in LView[], adjusted for header
 * @param lViewOrLContainer The LView or LContainer to add to the view tree
 * @returns The state passed in
 */
export function addToViewTree(lView, lViewOrLContainer) {
    // TODO(benlesh/misko): This implementation is incorrect, because it always adds the LContainer
    // to the end of the queue, which means if the developer retrieves the LContainers from RNodes out
    // of order, the change detection will run out of order, as the act of retrieving the the
    // LContainer from the RNode is what adds it to the queue.
    if (lView[CHILD_HEAD]) {
        lView[CHILD_TAIL][NEXT] = lViewOrLContainer;
    }
    else {
        lView[CHILD_HEAD] = lViewOrLContainer;
    }
    lView[CHILD_TAIL] = lViewOrLContainer;
    return lViewOrLContainer;
}
///////////////////////////////
//// Change detection
///////////////////////////////
export function executeViewQueryFn(flags, viewQueryFn, component) {
    ngDevMode && assertDefined(viewQueryFn, 'View queries function to execute must be defined.');
    setCurrentQueryIndex(0);
    const prevConsumer = setActiveConsumer(null);
    try {
        viewQueryFn(flags, component);
    }
    finally {
        setActiveConsumer(prevConsumer);
    }
}
///////////////////////////////
//// Bindings & interpolations
///////////////////////////////
/**
 * Stores meta-data for a property binding to be used by TestBed's `DebugElement.properties`.
 *
 * In order to support TestBed's `DebugElement.properties` we need to save, for each binding:
 * - a bound property name;
 * - a static parts of interpolated strings;
 *
 * A given property metadata is saved at the binding's index in the `TView.data` (in other words, a
 * property binding metadata will be stored in `TView.data` at the same index as a bound value in
 * `LView`). Metadata are represented as `INTERPOLATION_DELIMITER`-delimited string with the
 * following format:
 * - `propertyName` for bound properties;
 * - `propertyName�prefix�interpolation_static_part1�..interpolation_static_partN�suffix` for
 * interpolated properties.
 *
 * @param tData `TData` where meta-data will be saved;
 * @param tNode `TNode` that is a target of the binding;
 * @param propertyName bound property name;
 * @param bindingIndex binding index in `LView`
 * @param interpolationParts static interpolation parts (for property interpolations)
 */
export function storePropertyBindingMetadata(tData, tNode, propertyName, bindingIndex, ...interpolationParts) {
    // Binding meta-data are stored only the first time a given property instruction is processed.
    // Since we don't have a concept of the "first update pass" we need to check for presence of the
    // binding meta-data to decide if one should be stored (or if was stored already).
    if (tData[bindingIndex] === null) {
        if (tNode.inputs == null || !tNode.inputs[propertyName]) {
            const propBindingIdxs = tNode.propertyBindings || (tNode.propertyBindings = []);
            propBindingIdxs.push(bindingIndex);
            let bindingMetadata = propertyName;
            if (interpolationParts.length > 0) {
                bindingMetadata +=
                    INTERPOLATION_DELIMITER + interpolationParts.join(INTERPOLATION_DELIMITER);
            }
            tData[bindingIndex] = bindingMetadata;
        }
    }
}
export function getOrCreateLViewCleanup(view) {
    // top level variables should not be exported for performance reasons (PERF_NOTES.md)
    return view[CLEANUP] || (view[CLEANUP] = []);
}
export function getOrCreateTViewCleanup(tView) {
    return tView.cleanup || (tView.cleanup = []);
}
/**
 * There are cases where the sub component's renderer needs to be included
 * instead of the current renderer (see the componentSyntheticHost* instructions).
 */
export function loadComponentRenderer(currentDef, tNode, lView) {
    // TODO(FW-2043): the `currentDef` is null when host bindings are invoked while creating root
    // component (see packages/core/src/render3/component.ts). This is not consistent with the process
    // of creating inner components, when current directive index is available in the state. In order
    // to avoid relying on current def being `null` (thus special-casing root component creation), the
    // process of creating root component should be unified with the process of creating inner
    // components.
    if (currentDef === null || isComponentDef(currentDef)) {
        lView = unwrapLView(lView[tNode.index]);
    }
    return lView[RENDERER];
}
/** Handles an error thrown in an LView. */
export function handleError(lView, error) {
    const injector = lView[INJECTOR];
    const errorHandler = injector ? injector.get(ErrorHandler, null) : null;
    errorHandler && errorHandler.handleError(error);
}
/**
 * Set the inputs of directives at the current node to corresponding value.
 *
 * @param tView The current TView
 * @param lView the `LView` which contains the directives.
 * @param inputs mapping between the public "input" name and privately-known,
 *        possibly minified, property names to write to.
 * @param value Value to set.
 */
export function setInputsForProperty(tView, lView, inputs, publicName, value) {
    for (let i = 0; i < inputs.length;) {
        const index = inputs[i++];
        const privateName = inputs[i++];
        const instance = lView[index];
        ngDevMode && assertIndexInRange(lView, index);
        const def = tView.data[index];
        writeToDirectiveInput(def, instance, publicName, privateName, value);
    }
}
/**
 * Updates a text binding at a given index in a given LView.
 */
export function textBindingInternal(lView, index, value) {
    ngDevMode && assertString(value, 'Value should be a string');
    ngDevMode && assertNotSame(value, NO_CHANGE, 'value should not be NO_CHANGE');
    ngDevMode && assertIndexInRange(lView, index);
    const element = getNativeByIndex(index, lView);
    ngDevMode && assertDefined(element, 'native element should exist');
    updateTextNode(lView[RENDERER], element, value);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic2hhcmVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9pbnN0cnVjdGlvbnMvc2hhcmVkLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUdILE9BQU8sRUFBQyxZQUFZLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQUNqRCxPQUFPLEVBQUMsWUFBWSxFQUFtQixNQUFNLGNBQWMsQ0FBQztBQUU1RCxPQUFPLEVBQUMsd0JBQXdCLEVBQUMsTUFBTSxnQ0FBZ0MsQ0FBQztBQUN4RSxPQUFPLEVBQUMscUJBQXFCLEVBQUUsNkJBQTZCLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUM1RixPQUFPLEVBQUMscUNBQXFDLEVBQUMsTUFBTSx1QkFBdUIsQ0FBQztBQUc1RSxPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQUN0RCxPQUFPLEVBQUMsOEJBQThCLEVBQUUsOEJBQThCLEVBQUMsTUFBTSxpQ0FBaUMsQ0FBQztBQUMvRyxPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFDaEQsT0FBTyxFQUFDLGFBQWEsRUFBRSxXQUFXLEVBQUUsaUJBQWlCLEVBQUUsd0JBQXdCLEVBQUUsa0JBQWtCLEVBQUUsY0FBYyxFQUFFLGFBQWEsRUFBRSxVQUFVLEVBQUUsWUFBWSxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDdkwsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFDakQsT0FBTyxFQUFDLHlCQUF5QixFQUFFLDBCQUEwQixFQUFDLE1BQU0sdUJBQXVCLENBQUM7QUFDNUYsT0FBTyxFQUFDLFNBQVMsRUFBQyxNQUFNLHNCQUFzQixDQUFDO0FBQy9DLE9BQU8sRUFBQyxxQkFBcUIsRUFBRSxxQkFBcUIsRUFBRSxXQUFXLEVBQUUsbUJBQW1CLEVBQUUsbUJBQW1CLEVBQUMsTUFB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UyxJQUFJLFlBQVksQ0FBQyxLQUFLLEVBQUUsMEJBQTBCLENBQUMsQ0FBQztJQUM3RCxTQUFTLElBQUksYUFBYSxDQUFDLEtBQUssRUFBRSxTQUFnQixFQUFFLCtCQUErQixDQUFDLENBQUM7SUFDckYsU0FBUyxJQUFJLGtCQUFrQixDQUFDLEtBQUssRUFBRSxLQUFLLENBQUMsQ0FBQztJQUM5QyxNQUFNLE9BQU8sR0FBRyxnQkFBZ0IsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFpQixDQUFDO0lBQy9ELFNBQVMsSUFBSSxhQUFhLENBQUMsT0FBTyxFQUFFLDZCQUE2QixDQUFDLENBQUM7SUFDbkUsY0FBYyxDQUFDLEtBQUssQ0FBQyxRQUFRLENBQUMsRUFBRSxPQUFPLEVBQUUsS0FBSyxDQUFDLENBQUM7QUFDbEQsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0luamVjdG9yfSBmcm9tICcuLi8uLi9kaS9pbmplY3Rvcic7XG5pbXBvcnQge0Vycm9ySGFuZGxlcn0gZnJvbSAnLi4vLi4vZXJyb3JfaGFuZGxlcic7XG5pbXBvcnQge1J1bnRpbWVFcnJvciwgUnVudGltZUVycm9yQ29kZX0gZnJvbSAnLi4vLi4vZXJyb3JzJztcbmltcG9ydCB7RGVoeWRyYXRlZFZpZXd9IGZyb20gJy4uLy4uL2h5ZHJhdGlvbi9pbnRlcmZhY2VzJztcbmltcG9ydCB7U0tJUF9IWURSQVRJT05fQVRUUl9OQU1FfSBmcm9tICcuLi8uLi9oeWRyYXRpb24vc2tpcF9oeWRyYXRpb24nO1xuaW1wb3J0IHtQUkVTRVJWRV9IT1NUX0NPTlRFTlQsIFBSRVNFUlZFX0hPU1RfQ09OVEVOVF9ERUZBVUxUfSBmcm9tICcuLi8uLi9oeWRyYXRpb24vdG9rZW5zJztcbmltcG9ydCB7cHJvY2Vzc1RleHROb2RlTWFya2Vyc0JlZm9yZUh5ZHJhdGlvbn0gZnJvbSAnLi4vLi4vaHlkcmF0aW9uL3V0aWxzJztcbmltcG9ydCB7RG9DaGVjaywgT25DaGFuZ2VzLCBPbkluaXR9IGZyb20gJy4uLy4uL2ludGVyZmFjZS9saWZlY3ljbGVfaG9va3MnO1xuaW1wb3J0IHtTY2hlbWFNZXRhZGF0YX0gZnJvbSAnLi4vLi4vbWV0YWRhdGEvc2NoZW1hJztcbmltcG9ydCB7Vmlld0VuY2Fwc3VsYXRpb259IGZyb20gJy4uLy4uL21ldGFkYXRhL3ZpZXcnO1xuaW1wb3J0IHt2YWxpZGF0ZUFnYWluc3RFdmVudEF0dHJpYnV0ZXMsIHZhbGlkYXRlQWdhaW5zdEV2ZW50UHJvcGVydGllc30gZnJvbSAnLi4vLi4vc2FuaXRpemF0aW9uL3Nhbml0aXphdGlvbic7XG5pbXBvcnQge3NldEFjdGl2ZUNvbnN1bWVyfSBmcm9tICcuLi8uLi9zaWduYWxzJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZCwgYXNzZXJ0RXF1YWwsIGFzc2VydEdyZWF0ZXJUaGFuLCBhc3NlcnRHcmVhdGVyVGhhbk9yRXF1YWwsIGFzc2VydEluZGV4SW5SYW5nZSwgYXNzZXJ0Tm90RXF1YWwsIGFzc2VydE5vdFNhbWUsIGFzc2VydFNhbWUsIGFzc2VydFN0cmluZ30gZnJvbSAnLi4vLi4vdXRpbC9hc3NlcnQnO1xuaW1wb3J0IHtlc2NhcGVDb21tZW50VGV4dH0gZnJvbSAnLi4vLi4vdXRpbC9kb20nO1xuaW1wb3J0IHtub3JtYWxpemVEZWJ1Z0JpbmRpbmdOYW1lLCBub3JtYWxpemVEZWJ1Z0JpbmRpbmdWYWx1ZX0gZnJvbSAnLi4vLi4vdXRpbC9uZ19yZWZsZWN0JztcbmltcG9ydCB7c3RyaW5naWZ5fSBmcm9tICcuLi8uLi91dGlsL3N0cmluZ2lmeSc7XG5pbXBvcnQge2Fzc2VydEZpcnN0Q3JlYXRlUGFzcywgYXNzZXJ0Rmlyc3RVcGRhdGVQYXNzLCBhc3NlcnRMVmlldywgYXNzZXJ0VE5vZGVGb3JMVmlldywgYXNzZXJ0VE5vZGVGb3JUVmlld30gZnJvbSAnLi4vYXNzZXJ0JztcbmltcG9ydCB7YXR0YWNoUGF0Y2hEYXRhfSBmcm9tICcuLi9jb250ZXh0X2Rpc2NvdmVyeSc7XG5pbXBvcnQge2dldEZhY3RvcnlEZWZ9IGZyb20gJy4uL2RlZmluaXRpb25fZmFjdG9yeSc7XG5pbXBvcnQge2RpUHVibGljSW5JbmplY3RvciwgZ2V0Tm9kZUluamVjdGFibGUsIGdldE9yQ3JlYXRlTm9kZUluamVjdG9yRm9yTm9kZX0gZnJvbSAnLi4vZGknO1xuaW1wb3J0IHt0aHJvd011bHRpcGxlQ29tcG9uZW50RXJyb3J9IGZyb20gJy4uL2Vycm9ycyc7XG5pbXBvcnQge0NPTlRBSU5FUl9IRUFERVJfT0ZGU0VULCBMQ29udGFpbmVyfSBmcm9tICcuLi9pbnRlcmZhY2VzL2NvbnRhaW5lcic7XG5pbXBvcnQge0NvbXBvbmVudERlZiwgQ29tcG9uZW50VGVtcGxhdGUsIERpcmVjdGl2ZURlZiwgRGlyZWN0aXZlRGVmTGlzdE9yRmFjdG9yeSwgSG9zdEJpbmRpbmdzRnVuY3Rpb24sIEhvc3REaXJlY3RpdmVCaW5kaW5nTWFwLCBIb3N0RGlyZWN0aXZlRGVmcywgUGlwZURlZkxpc3RPckZhY3RvcnksIFJlbmRlckZsYWdzLCBWaWV3UXVlcmllc0Z1bmN0aW9ufSBmcm9tICcuLi9pbnRlcmZhY2VzL2RlZmluaXRpb24nO1xuaW1wb3J0IHtOb2RlSW5qZWN0b3JGYWN0b3J5fSBmcm9tICcuLi9pbnRlcmZhY2VzL2luamVjdG9yJztcbmltcG9ydCB7Z2V0VW5pcXVlTFZpZXdJZH0gZnJvbSAnLi4vaW50ZXJmYWNlcy9sdmlld190cmFja2luZyc7XG5pbXBvcnQge0F0dHJpYnV0ZU1hcmtlciwgSW5pdGlhbElucHV0RGF0YSwgSW5pdGlhbElucHV0cywgTG9jYWxSZWZFeHRyYWN0b3IsIFByb3BlcnR5QWxpYXNlcywgUHJvcGVydHlBbGlhc1ZhbHVlLCBUQXR0cmlidXRlcywgVENvbnN0YW50c09yRmFjdG9yeSwgVENvbnRhaW5lck5vZGUsIFREaXJlY3RpdmVIb3N0Tm9kZSwgVEVsZW1lbnRDb250YWluZXJOb2RlLCBURWxlbWVudE5vZGUsIFRJY3VDb250YWluZXJOb2RlLCBUTm9kZSwgVE5vZGVGbGFncywgVE5vZGVUeXBlLCBUUHJvamVjdGlvbk5vZGV9IGZyb20gJy4uL2ludGVyZmFjZXMvbm9kZSc7XG5pbXBvcnQge1JlbmRlcmVyfSBmcm9tICcuLi9pbnRlcmZhY2VzL3JlbmRlcmVyJztcbmltcG9ydCB7UkNvbW1lbnQsIFJFbGVtZW50LCBSTm9kZSwgUlRleHR9IGZyb20gJy4uL2ludGVyZmFjZXMvcmVuZGVyZXJfZG9tJztcbmltcG9ydCB7U2FuaXRpemVyRm59IGZyb20gJy4uL2ludGVyZmFjZXMvc2FuaXRpemF0aW9uJztcbmltcG9ydCB7aXNDb21wb25lbnREZWYsIGlzQ29tcG9uZW50SG9zdCwgaXNDb250ZW50UXVlcnlIb3N0fSBmcm9tICcuLi9pbnRlcmZhY2VzL3R5cGVfY2hlY2tzJztcbmltcG9ydCB7Q0hJTERfSEVBRCwgQ0hJTERfVEFJTCwgQ0xFQU5VUCwgQ09OVEVYVCwgREVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVcsIERFQ0xBUkFUSU9OX1ZJRVcsIEVNQkVEREVEX1ZJRVdfSU5KRUNUT1IsIEVOVklST05NRU5ULCBGTEFHUywgSEVBREVSX09GRlNFVCwgSE9TVCwgSG9zdEJpbmRpbmdPcENvZGVzLCBIWURSQVRJT04sIElELCBJTkpFQ1RPUiwgTFZpZXcsIExWaWV3RW52aXJvbm1lbnQsIExWaWV3RmxhZ3MsIE5FWFQsIFBBUkVOVCwgUkVBQ1RJVkVfSE9TVF9CSU5ESU5HX0NPTlNVTUVSLCBSRUFDVElWRV9URU1QTEFURV9DT05TVU1FUiwgUkVOREVSRVIsIFRfSE9TVCwgVERhdGEsIFRWSUVXLCBUVmlldywgVFZpZXdUeXBlfSBmcm9tICcuLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHthc3NlcnRQdXJlVE5vZGVUeXBlLCBhc3NlcnRUTm9kZVR5cGV9IGZyb20gJy4uL25vZGVfYXNzZXJ0JztcbmltcG9ydCB7Y2xlYXJFbGVtZW50Q29udGVudHMsIHVwZGF0ZVRleHROb2RlfSBmcm9tICcuLi9ub2RlX21hbmlwdWxhdGlvbic7XG5pbXBvcnQge2lzSW5saW5lVGVtcGxhdGUsIGlzTm9kZU1hdGNoaW5nU2VsZWN0b3JMaXN0fSBmcm9tICcuLi9ub2RlX3NlbGVjdG9yX21hdGNoZXInO1xuaW1wb3J0IHtwcm9maWxlciwgUHJvZmlsZXJFdmVudH0gZnJvbSAnLi4vcHJvZmlsZXInO1xuaW1wb3J0IHtjb21taXRMVmlld0NvbnN1bWVySWZIYXNQcm9kdWNlcnMsIGdldFJlYWN0aXZlTFZpZXdDb25zdW1lcn0gZnJvbSAnLi4vcmVhY3RpdmVfbHZpZXdfY29uc3VtZXInO1xuaW1wb3J0IHtnZXRCaW5kaW5nc0VuYWJsZWQsIGdldEN1cnJlbnREaXJlY3RpdmVJbmRleCwgZ2V0Q3VycmVudFBhcmVudFROb2RlLCBnZXRDdXJyZW50VE5vZGVQbGFjZWhvbGRlck9rLCBnZXRTZWxlY3RlZEluZGV4LCBpc0N1cnJlbnRUTm9kZVBhcmVudCwgaXNJbkNoZWNrTm9DaGFuZ2VzTW9kZSwgaXNJbkkxOG5CbG9jaywgbGVhdmVWaWV3LCBzZXRCaW5kaW5nUm9vdEZvckhvc3RCaW5kaW5ncywgc2V0Q3VycmVudERpcmVjdGl2ZUluZGV4LCBzZXRDdXJyZW50UXVlcnlJbmRleCwgc2V0Q3VycmVudFROb2RlLCBzZXRTZWxlY3RlZEluZGV4fSBmcm9tICcuLi9zdGF0ZSc7XG5pbXBvcnQge05PX0NIQU5HRX0gZnJvbSAnLi4vdG9rZW5zJztcbmltcG9ydCB7bWVyZ2VIb3N0QXR0cnN9IGZyb20gJy4uL3V0aWwvYXR0cnNfdXRpbHMnO1xuaW1wb3J0IHtJTlRFUlBPTEFUSU9OX0RFTElNSVRFUn0gZnJvbSAnLi4vdXRpbC9taXNjX3V0aWxzJztcbmltcG9ydCB7cmVuZGVyU3RyaW5naWZ5fSBmcm9tICcuLi91dGlsL3N0cmluZ2lmeV91dGlscyc7XG5pbXBvcnQge2dldENvbXBvbmVudExWaWV3QnlJbmRleCwgZ2V0TmF0aXZlQnlJbmRleCwgZ2V0TmF0aXZlQnlUTm9kZSwgcmVzZXRQcmVPcmRlckhvb2tGbGFncywgdW53cmFwTFZpZXd9IGZyb20gJy4uL3V0aWwvdmlld191dGlscyc7XG5cbmltcG9ydCB7c2VsZWN0SW5kZXhJbnRlcm5hbH0gZnJvbSAnLi9hZHZhbmNlJztcbmltcG9ydCB7ybXJtWRpcmVjdGl2ZUluamVjdH0gZnJvbSAnLi9kaSc7XG5pbXBvcnQge2hhbmRsZVVua25vd25Qcm9wZXJ0eUVycm9yLCBpc1Byb3BlcnR5VmFsaWQsIG1hdGNoaW5nU2NoZW1hc30gZnJvbSAnLi9lbGVtZW50X3ZhbGlkYXRpb24nO1xuXG4vKipcbiAqIEludm9rZSBgSG9zdEJpbmRpbmdzRnVuY3Rpb25gcyBmb3Igdmlldy5cbiAqXG4gKiBUaGlzIG1ldGhvZHMgZXhlY3V0ZXMgYFRWaWV3Lmhvc3RCaW5kaW5nT3BDb2Rlc2AuIEl0IGlzIHVzZWQgdG8gZXhlY3V0ZSB0aGVcbiAqIGBIb3N0QmluZGluZ3NGdW5jdGlvbmBzIGFzc29jaWF0ZWQgd2l0aCB0aGUgY3VycmVudCBgTFZpZXdgLlxuICpcbiAqIEBwYXJhbSB0VmlldyBDdXJyZW50IGBUVmlld2AuXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBgTFZpZXdgLlxuICovXG5leHBvcnQgZnVuY3Rpb24gcHJvY2Vzc0hvc3RCaW5kaW5nT3BDb2Rlcyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldyk6IHZvaWQge1xuICBjb25zdCBob3N0QmluZGluZ09wQ29kZXMgPSB0Vmlldy5ob3N0QmluZGluZ09wQ29kZXM7XG4gIGlmIChob3N0QmluZGluZ09wQ29kZXMgPT09IG51bGwpIHJldHVybjtcbiAgY29uc3QgY29uc3VtZXIgPSBnZXRSZWFjdGl2ZUxWaWV3Q29uc3VtZXIobFZpZXcsIFJFQUNUSVZFX0hPU1RfQklORElOR19DT05TVU1FUik7XG4gIHRyeSB7XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBob3N0QmluZGluZ09wQ29kZXMubGVuZ3RoOyBpKyspIHtcbiAgICAgIGNvbnN0IG9wQ29kZSA9IGhvc3RCaW5kaW5nT3BDb2Rlc1tpXSBhcyBudW1iZXI7XG4gICAgICBpZiAob3BDb2RlIDwgMCkge1xuICAgICAgICAvLyBOZWdhdGl2ZSBudW1iZXJzIGFyZSBlbGVtZW50IGluZGV4ZXMuXG4gICAgICAgIHNldFNlbGVjdGVkSW5kZXgofm9wQ29kZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICAvLyBQb3NpdGl2ZSBudW1iZXJzIGFyZSBOdW1iZXJUdXBsZSB3aGljaCBzdG9yZSBiaW5kaW5nUm9vdEluZGV4IGFuZCBkaXJlY3RpdmVJbmRleC5cbiAgICAgICAgY29uc3QgZGlyZWN0aXZlSWR4ID0gb3BDb2RlO1xuICAgICAgICBjb25zdCBiaW5kaW5nUm9vdEluZHggPSBob3N0QmluZGluZ09wQ29kZXNbKytpXSBhcyBudW1iZXI7XG4gICAgICAgIGNvbnN0IGhvc3RCaW5kaW5nRm4gPSBob3N0QmluZGluZ09wQ29kZXNbKytpXSBhcyBIb3N0QmluZGluZ3NGdW5jdGlvbjxhbnk+O1xuICAgICAgICBzZXRCaW5kaW5nUm9vdEZvckhvc3RCaW5kaW5ncyhiaW5kaW5nUm9vdEluZHgsIGRpcmVjdGl2ZUlkeCk7XG4gICAgICAgIGNvbnN0IGNvbnRleHQgPSBsVmlld1tkaXJlY3RpdmVJZHhdO1xuICAgICAgICBjb25zdW1lci5ydW5JbkNvbnRleHQoaG9zdEJpbmRpbmdGbiwgUmVuZGVyRmxhZ3MuVXBkYXRlLCBjb250ZXh0KTtcbiAgICAgIH1cbiAgICB9XG4gIH0gZmluYWxseSB7XG4gICAgaWYgKGxWaWV3W1JFQUNUSVZFX0hPU1RfQklORElOR19DT05TVU1FUl0gPT09IG51bGwpIHtcbiAgICAgIGNvbW1pdExWaWV3Q29uc3VtZXJJZkhhc1Byb2R1Y2VycyhsVmlldywgUkVBQ1RJVkVfSE9TVF9CSU5ESU5HX0NPTlNVTUVSKTtcbiAgICB9XG4gICAgc2V0U2VsZWN0ZWRJbmRleCgtMSk7XG4gIH1cbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZUxWaWV3PFQ+KFxuICAgIHBhcmVudExWaWV3OiBMVmlld3xudWxsLCB0VmlldzogVFZpZXcsIGNvbnRleHQ6IFR8bnVsbCwgZmxhZ3M6IExWaWV3RmxhZ3MsIGhvc3Q6IFJFbGVtZW50fG51bGwsXG4gICAgdEhvc3ROb2RlOiBUTm9kZXxudWxsLCBlbnZpcm9ubWVudDogTFZpZXdFbnZpcm9ubWVudHxudWxsLCByZW5kZXJlcjogUmVuZGVyZXJ8bnVsbCxcbiAgICBpbmplY3RvcjogSW5qZWN0b3J8bnVsbCwgZW1iZWRkZWRWaWV3SW5qZWN0b3I6IEluamVjdG9yfG51bGwsXG4gICAgaHlkcmF0aW9uSW5mbzogRGVoeWRyYXRlZFZpZXd8bnVsbCk6IExWaWV3IHtcbiAgY29uc3QgbFZpZXcgPSB0Vmlldy5ibHVlcHJpbnQuc2xpY2UoKSBhcyBMVmlldztcbiAgbFZpZXdbSE9TVF0gPSBob3N0O1xuICBsVmlld1tGTEFHU10gPSBmbGFncyB8IExWaWV3RmxhZ3MuQ3JlYXRpb25Nb2RlIHwgTFZpZXdGbGFncy5BdHRhY2hlZCB8IExWaWV3RmxhZ3MuRmlyc3RMVmlld1Bhc3M7XG4gIGlmIChlbWJlZGRlZFZpZXdJbmplY3RvciAhPT0gbnVsbCB8fFxuICAgICAgKHBhcmVudExWaWV3ICYmIChwYXJlbnRMVmlld1tGTEFHU10gJiBMVmlld0ZsYWdzLkhhc0VtYmVkZGVkVmlld0luamVjdG9yKSkpIHtcbiAgICBsVmlld1tGTEFHU10gfD0gTFZpZXdGbGFncy5IYXNFbWJlZGRlZFZpZXdJbmplY3RvcjtcbiAgfVxuICByZXNldFByZU9yZGVySG9va0ZsYWdzKGxWaWV3KTtcbiAgbmdEZXZNb2RlICYmIHRWaWV3LmRlY2xUTm9kZSAmJiBwYXJlbnRMVmlldyAmJiBhc3NlcnRUTm9kZUZvckxWaWV3KHRWaWV3LmRlY2xUTm9kZSwgcGFyZW50TFZpZXcpO1xuICBsVmlld1tQQVJFTlRdID0gbFZpZXdbREVDTEFSQVRJT05fVklFV10gPSBwYXJlbnRMVmlldztcbiAgbFZpZXdbQ09OVEVYVF0gPSBjb250ZXh0O1xuICBsVmlld1tFTlZJUk9OTUVOVF0gPSAoZW52aXJvbm1lbnQgfHwgcGFyZW50TFZpZXcgJiYgcGFyZW50TFZpZXdbRU5WSVJPTk1FTlRdKSE7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGxWaWV3W0VOVklST05NRU5UXSwgJ0xWaWV3RW52aXJvbm1lbnQgaXMgcmVxdWlyZWQnKTtcbiAgbFZpZXdbUkVOREVSRVJdID0gKHJlbmRlcmVyIHx8IHBhcmVudExWaWV3ICYmIHBhcmVudExWaWV3W1JFTkRFUkVSXSkhO1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0RGVmaW5lZChsVmlld1tSRU5ERVJFUl0sICdSZW5kZXJlciBpcyByZXF1aXJlZCcpO1xuICBsVmlld1tJTkpFQ1RPUiBhcyBhbnldID0gaW5qZWN0b3IgfHwgcGFyZW50TFZpZXcgJiYgcGFyZW50TFZpZXdbSU5KRUNUT1JdIHx8IG51bGw7XG4gIGxWaWV3W1RfSE9TVF0gPSB0SG9zdE5vZGU7XG4gIGxWaWV3W0lEXSA9IGdldFVuaXF1ZUxWaWV3SWQoKTtcbiAgbFZpZXdbSFlEUkFUSU9OXSA9IGh5ZHJhdGlvbkluZm87XG4gIGxWaWV3W0VNQkVEREVEX1ZJRVdfSU5KRUNUT1IgYXMgYW55XSA9IGVtYmVkZGVkVmlld0luamVjdG9yO1xuXG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0RXF1YWwoXG4gICAgICAgICAgdFZpZXcudHlwZSA9PSBUVmlld1R5cGUuRW1iZWRkZWQgPyBwYXJlbnRMVmlldyAhPT0gbnVsbCA6IHRydWUsIHRydWUsXG4gICAgICAgICAgJ0VtYmVkZGVkIHZpZXdzIG11c3QgaGF2ZSBwYXJlbnRMVmlldycpO1xuICBsVmlld1tERUNMQVJBVElPTl9DT01QT05FTlRfVklFV10gPVxuICAgICAgdFZpZXcudHlwZSA9PSBUVmlld1R5cGUuRW1iZWRkZWQgPyBwYXJlbnRMVmlldyFbREVDTEFSQVRJT05fQ09NUE9ORU5UX1ZJRVddIDogbFZpZXc7XG4gIHJldHVybiBsVmlldztcbn1cblxuLyoqXG4gKiBDcmVhdGUgYW5kIHN0b3JlcyB0aGUgVE5vZGUsIGFuZCBob29rcyBpdCB1cCB0byB0aGUgdHJlZS5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgVGhlIGN1cnJlbnQgYFRWaWV3YC5cbiAqIEBwYXJhbSBpbmRleCBUaGUgaW5kZXggYXQgd2hpY2ggdGhlIFROb2RlIHNob3VsZCBiZSBzYXZlZCAobnVsbCBpZiB2aWV3LCBzaW5jZSB0aGV5IGFyZSBub3RcbiAqIHNhdmVkKS5cbiAqIEBwYXJhbSB0eXBlIFRoZSB0eXBlIG9mIFROb2RlIHRvIGNyZWF0ZVxuICogQHBhcmFtIG5hdGl2ZSBUaGUgbmF0aXZlIGVsZW1lbnQgZm9yIHRoaXMgbm9kZSwgaWYgYXBwbGljYWJsZVxuICogQHBhcmFtIG5hbWUgVGhlIHRhZyBuYW1lIG9mIHRoZSBhc3NvY2lhdGVkIG5hdGl2ZSBlbGVtZW50LCBpZiBhcHBsaWNhYmxlXG4gKiBAcGFyYW0gYXR0cnMgQW55IGF0dHJzIGZvciB0aGUgbmF0aXZlIGVsZW1lbnQsIGlmIGFwcGxpY2FibGVcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldE9yQ3JlYXRlVE5vZGUoXG4gICAgdFZpZXc6IFRWaWV3LCBpbmRleDogbnVtYmVyLCB0eXBlOiBUTm9kZVR5cGUuRWxlbWVudHxUTm9kZVR5cGUuVGV4dCwgbmFtZTogc3RyaW5nfG51bGwsXG4gICAgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBURWxlbWVudE5vZGU7XG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIGluZGV4OiBudW1iZXIsIHR5cGU6IFROb2RlVHlwZS5Db250YWluZXIsIG5hbWU6IHN0cmluZ3xudWxsLFxuICAgIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTogVENvbnRhaW5lck5vZGU7XG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIGluZGV4OiBudW1iZXIsIHR5cGU6IFROb2RlVHlwZS5Qcm9qZWN0aW9uLCBuYW1lOiBudWxsLFxuICAgIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTogVFByb2plY3Rpb25Ob2RlO1xuZXhwb3J0IGZ1bmN0aW9uIGdldE9yQ3JlYXRlVE5vZGUoXG4gICAgdFZpZXc6IFRWaWV3LCBpbmRleDogbnVtYmVyLCB0eXBlOiBUTm9kZVR5cGUuRWxlbWVudENvbnRhaW5lciwgbmFtZTogc3RyaW5nfG51bGwsXG4gICAgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBURWxlbWVudENvbnRhaW5lck5vZGU7XG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIGluZGV4OiBudW1iZXIsIHR5cGU6IFROb2RlVHlwZS5JY3UsIG5hbWU6IG51bGwsXG4gICAgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBURWxlbWVudENvbnRhaW5lck5vZGU7XG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIGluZGV4OiBudW1iZXIsIHR5cGU6IFROb2RlVHlwZSwgbmFtZTogc3RyaW5nfG51bGwsIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTpcbiAgICBURWxlbWVudE5vZGUmVENvbnRhaW5lck5vZGUmVEVsZW1lbnRDb250YWluZXJOb2RlJlRQcm9qZWN0aW9uTm9kZSZUSWN1Q29udGFpbmVyTm9kZSB7XG4gIG5nRGV2TW9kZSAmJiBpbmRleCAhPT0gMCAmJiAgLy8gMCBhcmUgYm9ndXMgbm9kZXMgYW5kIHRoZXkgYXJlIE9LLiBTZWUgYGNyZWF0ZUNvbnRhaW5lclJlZmAgaW5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAvLyBgdmlld19lbmdpbmVfY29tcGF0aWJpbGl0eWAgZm9yIGFkZGl0aW9uYWwgY29udGV4dC5cbiAgICAgIGFzc2VydEdyZWF0ZXJUaGFuT3JFcXVhbChpbmRleCwgSEVBREVSX09GRlNFVCwgJ1ROb2RlcyBjYW5cXCd0IGJlIGluIHRoZSBMVmlldyBoZWFkZXIuJyk7XG4gIC8vIEtlZXAgdGhpcyBmdW5jdGlvbiBzaG9ydCwgc28gdGhhdCB0aGUgVk0gd2lsbCBpbmxpbmUgaXQuXG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRQdXJlVE5vZGVUeXBlKHR5cGUpO1xuICBsZXQgdE5vZGUgPSB0Vmlldy5kYXRhW2luZGV4XSBhcyBUTm9kZTtcbiAgaWYgKHROb2RlID09PSBudWxsKSB7XG4gICAgdE5vZGUgPSBjcmVhdGVUTm9kZUF0SW5kZXgodFZpZXcsIGluZGV4LCB0eXBlLCBuYW1lLCBhdHRycyk7XG4gICAgaWYgKGlzSW5JMThuQmxvY2soKSkge1xuICAgICAgLy8gSWYgd2UgYXJlIGluIGkxOG4gYmxvY2sgdGhlbiBhbGwgZWxlbWVudHMgc2hvdWxkIGJlIHByZSBkZWNsYXJlZCB0aHJvdWdoIGBQbGFjZWhvbGRlcmBcbiAgICAgIC8vIFNlZSBgVE5vZGVUeXBlLlBsYWNlaG9sZGVyYCBhbmQgYExGcmFtZS5pbkkxOG5gIGZvciBtb3JlIGNvbnRleHQuXG4gICAgICAvLyBJZiB0aGUgYFROb2RlYCB3YXMgbm90IHByZS1kZWNsYXJlZCB0aGFuIGl0IG1lYW5zIGl0IHdhcyBub3QgbWVudGlvbmVkIHdoaWNoIG1lYW5zIGl0IHdhc1xuICAgICAgLy8gcmVtb3ZlZCwgc28gd2UgbWFyayBpdCBhcyBkZXRhY2hlZC5cbiAgICAgIHROb2RlLmZsYWdzIHw9IFROb2RlRmxhZ3MuaXNEZXRhY2hlZDtcbiAgICB9XG4gIH0gZWxzZSBpZiAodE5vZGUudHlwZSAmIFROb2RlVHlwZS5QbGFjZWhvbGRlcikge1xuICAgIHROb2RlLnR5cGUgPSB0eXBlO1xuICAgIHROb2RlLnZhbHVlID0gbmFtZTtcbiAgICB0Tm9kZS5hdHRycyA9IGF0dHJzO1xuICAgIGNvbnN0IHBhcmVudCA9IGdldEN1cnJlbnRQYXJlbnRUTm9kZSgpO1xuICAgIHROb2RlLmluamVjdG9ySW5kZXggPSBwYXJlbnQgPT09IG51bGwgPyAtMSA6IHBhcmVudC5pbmplY3RvckluZGV4O1xuICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRUTm9kZUZvclRWaWV3KHROb2RlLCB0Vmlldyk7XG4gICAgbmdEZXZNb2RlICYmIGFzc2VydEVxdWFsKGluZGV4LCB0Tm9kZS5pbmRleCwgJ0V4cGVjdGluZyBzYW1lIGluZGV4Jyk7XG4gIH1cbiAgc2V0Q3VycmVudFROb2RlKHROb2RlLCB0cnVlKTtcbiAgcmV0dXJuIHROb2RlIGFzIFRFbGVtZW50Tm9kZSAmIFRDb250YWluZXJOb2RlICYgVEVsZW1lbnRDb250YWluZXJOb2RlICYgVFByb2plY3Rpb25Ob2RlICZcbiAgICAgIFRJY3VDb250YWluZXJOb2RlO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVE5vZGVBdEluZGV4KFxuICAgIHRWaWV3OiBUVmlldywgaW5kZXg6IG51bWJlciwgdHlwZTogVE5vZGVUeXBlLCBuYW1lOiBzdHJpbmd8bnVsbCwgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpIHtcbiAgY29uc3QgY3VycmVudFROb2RlID0gZ2V0Q3VycmVudFROb2RlUGxhY2Vob2xkZXJPaygpO1xuICBjb25zdCBpc1BhcmVudCA9IGlzQ3VycmVudFROb2RlUGFyZW50KCk7XG4gIGNvbnN0IHBhcmVudCA9IGlzUGFyZW50ID8gY3VycmVudFROb2RlIDogY3VycmVudFROb2RlICYmIGN1cnJlbnRUTm9kZS5wYXJlbnQ7XG4gIC8vIFBhcmVudHMgY2Fubm90IGNyb3NzIGNvbXBvbmVudCBib3VuZGFyaWVzIGJlY2F1c2UgY29tcG9uZW50cyB3aWxsIGJlIHVzZWQgaW4gbXVsdGlwbGUgcGxhY2VzLlxuICBjb25zdCB0Tm9kZSA9IHRWaWV3LmRhdGFbaW5kZXhdID1cbiAgICAgIGNyZWF0ZVROb2RlKHRWaWV3LCBwYXJlbnQgYXMgVEVsZW1lbnROb2RlIHwgVENvbnRhaW5lck5vZGUsIHR5cGUsIGluZGV4LCBuYW1lLCBhdHRycyk7XG4gIC8vIEFzc2lnbiBhIHBvaW50ZXIgdG8gdGhlIGZpcnN0IGNoaWxkIG5vZGUgb2YgYSBnaXZlbiB2aWV3LiBUaGUgZmlyc3Qgbm9kZSBpcyBub3QgYWx3YXlzIHRoZSBvbmVcbiAgLy8gYXQgaW5kZXggMCwgaW4gY2FzZSBvZiBpMThuLCBpbmRleCAwIGNhbiBiZSB0aGUgaW5zdHJ1Y3Rpb24gYGkxOG5TdGFydGAgYW5kIHRoZSBmaXJzdCBub2RlIGhhc1xuICAvLyB0aGUgaW5kZXggMSBvciBtb3JlLCBzbyB3ZSBjYW4ndCBqdXN0IGNoZWNrIG5vZGUgaW5kZXguXG4gIGlmICh0Vmlldy5maXJzdENoaWxkID09PSBudWxsKSB7XG4gICAgdFZpZXcuZmlyc3RDaGlsZCA9IHROb2RlO1xuICB9XG4gIGlmIChjdXJyZW50VE5vZGUgIT09IG51bGwpIHtcbiAgICBpZiAoaXNQYXJlbnQpIHtcbiAgICAgIC8vIEZJWE1FKG1pc2tvKTogVGhpcyBsb2dpYyBsb29rcyB1bm5lY2Vzc2FyaWx5IGNvbXBsaWNhdGVkLiBDb3VsZCB3ZSBzaW1wbGlmeT9cbiAgICAgIGlmIChjdXJyZW50VE5vZGUuY2hpbGQgPT0gbnVsbCAmJiB0Tm9kZS5wYXJlbnQgIT09IG51bGwpIHtcbiAgICAgICAgLy8gV2UgYXJlIGluIHRoZSBzYW1lIHZpZXcsIHdoaWNoIG1lYW5zIHdlIGFyZSBhZGRpbmcgY29udGVudCBub2RlIHRvIHRoZSBwYXJlbnQgdmlldy5cbiAgICAgICAgY3VycmVudFROb2RlLmNoaWxkID0gdE5vZGU7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChjdXJyZW50VE5vZGUubmV4dCA9PT0gbnVsbCkge1xuICAgICAgICAvLyBJbiB0aGUgY2FzZSBvZiBpMThuIHRoZSBgY3VycmVudFROb2RlYCBtYXkgYWxyZWFkeSBiZSBsaW5rZWQsIGluIHdoaWNoIGNhc2Ugd2UgZG9uJ3Qgd2FudFxuICAgICAgICAvLyB0byBicmVhayB0aGUgbGlua3Mgd2hpY2ggaTE4biBjcmVhdGVkLlxuICAgICAgICBjdXJyZW50VE5vZGUubmV4dCA9IHROb2RlO1xuICAgICAgICB0Tm9kZS5wcmV2ID0gY3VycmVudFROb2RlO1xuICAgICAgfVxuICAgIH1cbiAgfVxuICByZXR1cm4gdE5vZGU7XG59XG5cbi8qKlxuICogV2hlbiBlbGVtZW50cyBhcmUgY3JlYXRlZCBkeW5hbWljYWxseSBhZnRlciBhIHZpZXcgYmx1ZXByaW50IGlzIGNyZWF0ZWQgKGUuZy4gdGhyb3VnaFxuICogaTE4bkFwcGx5KCkpLCB3ZSBuZWVkIHRvIGFkanVzdCB0aGUgYmx1ZXByaW50IGZvciBmdXR1cmVcbiAqIHRlbXBsYXRlIHBhc3Nlcy5cbiAqXG4gKiBAcGFyYW0gdFZpZXcgYFRWaWV3YCBhc3NvY2lhdGVkIHdpdGggYExWaWV3YFxuICogQHBhcmFtIGxWaWV3IFRoZSBgTFZpZXdgIGNvbnRhaW5pbmcgdGhlIGJsdWVwcmludCB0byBhZGp1c3RcbiAqIEBwYXJhbSBudW1TbG90c1RvQWxsb2MgVGhlIG51bWJlciBvZiBzbG90cyB0byBhbGxvYyBpbiB0aGUgTFZpZXcsIHNob3VsZCBiZSA+MFxuICogQHBhcmFtIGluaXRpYWxWYWx1ZSBJbml0aWFsIHZhbHVlIHRvIHN0b3JlIGluIGJsdWVwcmludFxuICovXG5leHBvcnQgZnVuY3Rpb24gYWxsb2NFeHBhbmRvKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCBudW1TbG90c1RvQWxsb2M6IG51bWJlciwgaW5pdGlhbFZhbHVlOiBhbnkpOiBudW1iZXIge1xuICBpZiAobnVtU2xvdHNUb0FsbG9jID09PSAwKSByZXR1cm4gLTE7XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICBhc3NlcnRGaXJzdENyZWF0ZVBhc3ModFZpZXcpO1xuICAgIGFzc2VydFNhbWUodFZpZXcsIGxWaWV3W1RWSUVXXSwgJ2BMVmlld2AgbXVzdCBiZSBhc3NvY2lhdGVkIHdpdGggYFRWaWV3YCEnKTtcbiAgICBhc3NlcnRFcXVhbCh0Vmlldy5kYXRhLmxlbmd0aCwgbFZpZXcubGVuZ3RoLCAnRXhwZWN0aW5nIExWaWV3IHRvIGJlIHNhbWUgc2l6ZSBhcyBUVmlldycpO1xuICAgIGFzc2VydEVxdWFsKFxuICAgICAgICB0Vmlldy5kYXRhLmxlbmd0aCwgdFZpZXcuYmx1ZXByaW50Lmxlbmd0aCwgJ0V4cGVjdGluZyBCbHVlcHJpbnQgdG8gYmUgc2FtZSBzaXplIGFzIFRWaWV3Jyk7XG4gICAgYXNzZXJ0Rmlyc3RVcGRhdGVQYXNzKHRWaWV3KTtcbiAgfVxuICBjb25zdCBhbGxvY0lkeCA9IGxWaWV3Lmxlbmd0aDtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBudW1TbG90c1RvQWxsb2M7IGkrKykge1xuICAgIGxWaWV3LnB1c2goaW5pdGlhbFZhbHVlKTtcbiAgICB0Vmlldy5ibHVlcHJpbnQucHVzaChpbml0aWFsVmFsdWUpO1xuICAgIHRWaWV3LmRhdGEucHVzaChudWxsKTtcbiAgfVxuICByZXR1cm4gYWxsb2NJZHg7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBleGVjdXRlVGVtcGxhdGU8VD4oXG4gICAgdFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXc8VD4sIHRlbXBsYXRlRm46IENvbXBvbmVudFRlbXBsYXRlPFQ+LCByZjogUmVuZGVyRmxhZ3MsIGNvbnRleHQ6IFQpIHtcbiAgY29uc3QgY29uc3VtZXIgPSBnZXRSZWFjdGl2ZUxWaWV3Q29uc3VtZXIobFZpZXcsIFJFQUNUSVZFX1RFTVBMQVRFX0NPTlNVTUVSKTtcbiAgY29uc3QgcHJldlNlbGVjdGVkSW5kZXggPSBnZXRTZWxlY3RlZEluZGV4KCk7XG4gIGNvbnN0IGlzVXBkYXRlUGhhc2UgPSByZiAmIFJlbmRlckZsYWdzLlVwZGF0ZTtcbiAgdHJ5IHtcbiAgICBzZXRTZWxlY3RlZEluZGV4KC0xKTtcbiAgICBpZiAoaXNVcGRhdGVQaGFzZSAmJiBsVmlldy5sZW5ndGggPiBIRUFERVJfT0ZGU0VUKSB7XG4gICAgICAvLyBXaGVuIHdlJ3JlIHVwZGF0aW5nLCBpbmhlcmVudGx5IHNlbGVjdCAwIHNvIHdlIGRvbid0XG4gICAgICAvLyBoYXZlIHRvIGdlbmVyYXRlIHRoYXQgaW5zdHJ1Y3Rpb24gZm9yIG1vc3QgdXBkYXRlIGJsb2Nrcy5cbiAgICAgIHNlbGVjdEluZGV4SW50ZXJuYWwodFZpZXcsIGxWaWV3LCBIRUFERVJfT0ZGU0VULCAhIW5nRGV2TW9kZSAmJiBpc0luQ2hlY2tOb0NoYW5nZXNNb2RlKCkpO1xuICAgIH1cblxuICAgIGNvbnN0IHByZUhvb2tUeXBlID1cbiAgICAgICAgaXNVcGRhdGVQaGFzZSA/IFByb2ZpbGVyRXZlbnQuVGVtcGxhdGVVcGRhdGVTdGFydCA6IFByb2ZpbGVyRXZlbnQuVGVtcGxhdGVDcmVhdGVTdGFydDtcbiAgICBwcm9maWxlcihwcmVIb29rVHlwZSwgY29udGV4dCBhcyB1bmtub3duIGFzIHt9KTtcbiAgICBpZiAoaXNVcGRhdGVQaGFzZSkge1xuICAgICAgY29uc3VtZXIucnVuSW5Db250ZXh0KHRlbXBsYXRlRm4sIHJmLCBjb250ZXh0KTtcbiAgICB9IGVsc2Uge1xuICAgICAgY29uc3QgcHJldkNvbnN1bWVyID0gc2V0QWN0aXZlQ29uc3VtZXIobnVsbCk7XG4gICAgICB0cnkge1xuICAgICAgICB0ZW1wbGF0ZUZuKHJmLCBjb250ZXh0KTtcbiAgICAgIH0gZmluYWxseSB7XG4gICAgICAgIHNldEFjdGl2ZUNvbnN1bWVyKHByZXZDb25zdW1lcik7XG4gICAgICB9XG4gICAgfVxuICB9IGZpbmFsbHkge1xuICAgIGlmIChpc1VwZGF0ZVBoYXNlICYmIGxWaWV3W1JFQUNUSVZFX1RFTVBMQVRFX0NPTlNVTUVSXSA9PT0gbnVsbCkge1xuICAgICAgY29tbWl0TFZpZXdDb25zdW1lcklmSGFzUHJvZHVjZXJzKGxWaWV3LCBSRUFDVElWRV9URU1QTEFURV9DT05TVU1FUik7XG4gICAgfVxuICAgIHNldFNlbGVjdGVkSW5kZXgocHJldlNlbGVjdGVkSW5kZXgpO1xuXG4gICAgY29uc3QgcG9zdEhvb2tUeXBlID1cbiAgICAgICAgaXNVcGRhdGVQaGFzZSA/IFByb2ZpbGVyRXZlbnQuVGVtcGxhdGVVcGRhdGVFbmQgOiBQcm9maWxlckV2ZW50LlRlbXBsYXRlQ3JlYXRlRW5kO1xuICAgIHByb2ZpbGVyKHBvc3RIb29rVHlwZSwgY29udGV4dCBhcyB1bmtub3duIGFzIHt9KTtcbiAgfVxufVxuXG4vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuLy8vLyBFbGVtZW50XG4vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuXG5leHBvcnQgZnVuY3Rpb24gZXhlY3V0ZUNvbnRlbnRRdWVyaWVzKHRWaWV3OiBUVmlldywgdE5vZGU6IFROb2RlLCBsVmlldzogTFZpZXcpIHtcbiAgaWYgKGlzQ29udGVudFF1ZXJ5SG9zdCh0Tm9kZSkpIHtcbiAgICBjb25zdCBwcmV2Q29uc3VtZXIgPSBzZXRBY3RpdmVDb25zdW1lcihudWxsKTtcbiAgICB0cnkge1xuICAgICAgY29uc3Qgc3RhcnQgPSB0Tm9kZS5kaXJlY3RpdmVTdGFydDtcbiAgICAgIGNvbnN0IGVuZCA9IHROb2RlLmRpcmVjdGl2ZUVuZDtcbiAgICAgIGZvciAobGV0IGRpcmVjdGl2ZUluZGV4ID0gc3RhcnQ7IGRpcmVjdGl2ZUluZGV4IDwgZW5kOyBkaXJlY3RpdmVJbmRleCsrKSB7XG4gICAgICAgIGNvbnN0IGRlZiA9IHRWaWV3LmRhdGFbZGlyZWN0aXZlSW5kZXhdIGFzIERpcmVjdGl2ZURlZjxhbnk+O1xuICAgICAgICBpZiAoZGVmLmNvbnRlbnRRdWVyaWVzKSB7XG4gICAgICAgICAgZGVmLmNvbnRlbnRRdWVyaWVzKFJlbmRlckZsYWdzLkNyZWF0ZSwgbFZpZXdbZGlyZWN0aXZlSW5kZXhdLCBkaXJlY3RpdmVJbmRleCk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGZpbmFsbHkge1xuICAgICAgc2V0QWN0aXZlQ29uc3VtZXIocHJldkNvbnN1bWVyKTtcbiAgICB9XG4gIH1cbn1cblxuXG4vKipcbiAqIENyZWF0ZXMgZGlyZWN0aXZlIGluc3RhbmNlcy5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZURpcmVjdGl2ZXNJbnN0YW5jZXModFZpZXc6IFRWaWV3LCBsVmlldzogTFZpZXcsIHROb2RlOiBURGlyZWN0aXZlSG9zdE5vZGUpIHtcbiAgaWYgKCFnZXRCaW5kaW5nc0VuYWJsZWQoKSkgcmV0dXJuO1xuICBpbnN0YW50aWF0ZUFsbERpcmVjdGl2ZXModFZpZXcsIGxWaWV3LCB0Tm9kZSwgZ2V0TmF0aXZlQnlUTm9kZSh0Tm9kZSwgbFZpZXcpKTtcbiAgaWYgKCh0Tm9kZS5mbGFncyAmIFROb2RlRmxhZ3MuaGFzSG9zdEJpbmRpbmdzKSA9PT0gVE5vZGVGbGFncy5oYXNIb3N0QmluZGluZ3MpIHtcbiAgICBpbnZva2VEaXJlY3RpdmVzSG9zdEJpbmRpbmdzKHRWaWV3LCBsVmlldywgdE5vZGUpO1xuICB9XG59XG5cbi8qKlxuICogVGFrZXMgYSBsaXN0IG9mIGxvY2FsIG5hbWVzIGFuZCBpbmRpY2VzIGFuZCBwdXNoZXMgdGhlIHJlc29sdmVkIGxvY2FsIHZhcmlhYmxlIHZhbHVlc1xuICogdG8gTFZpZXcgaW4gdGhlIHNhbWUgb3JkZXIgYXMgdGhleSBhcmUgbG9hZGVkIGluIHRoZSB0ZW1wbGF0ZSB3aXRoIGxvYWQoKS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNhdmVSZXNvbHZlZExvY2Fsc0luRGF0YShcbiAgICB2aWV3RGF0YTogTFZpZXcsIHROb2RlOiBURGlyZWN0aXZlSG9zdE5vZGUsXG4gICAgbG9jYWxSZWZFeHRyYWN0b3I6IExvY2FsUmVmRXh0cmFjdG9yID0gZ2V0TmF0aXZlQnlUTm9kZSk6IHZvaWQge1xuICBjb25zdCBsb2NhbE5hbWVzID0gdE5vZGUubG9jYWxOYW1lcztcbiAgaWYgKGxvY2FsTmFtZXMgIT09IG51bGwpIHtcbiAgICBsZXQgbG9jYWxJbmRleCA9IHROb2RlLmluZGV4ICsgMTtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGxvY2FsTmFtZXMubGVuZ3RoOyBpICs9IDIpIHtcbiAgICAgIGNvbnN0IGluZGV4ID0gbG9jYWxOYW1lc1tpICsgMV0gYXMgbnVtYmVyO1xuICAgICAgY29uc3QgdmFsdWUgPSBpbmRleCA9PT0gLTEgP1xuICAgICAgICAgIGxvY2FsUmVmRXh0cmFjdG9yKFxuICAgICAgICAgICAgICB0Tm9kZSBhcyBURWxlbWVudE5vZGUgfCBUQ29udGFpbmVyTm9kZSB8IFRFbGVtZW50Q29udGFpbmVyTm9kZSwgdmlld0RhdGEpIDpcbiAgICAgICAgICB2aWV3RGF0YVtpbmRleF07XG4gICAgICB2aWV3RGF0YVtsb2NhbEluZGV4KytdID0gdmFsdWU7XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogR2V0cyBUVmlldyBmcm9tIGEgdGVtcGxhdGUgZnVuY3Rpb24gb3IgY3JlYXRlcyBhIG5ldyBUVmlld1xuICogaWYgaXQgZG9lc24ndCBhbHJlYWR5IGV4aXN0LlxuICpcbiAqIEBwYXJhbSBkZWYgQ29tcG9uZW50RGVmXG4gKiBAcmV0dXJucyBUVmlld1xuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0T3JDcmVhdGVDb21wb25lbnRUVmlldyhkZWY6IENvbXBvbmVudERlZjxhbnk+KTogVFZpZXcge1xuICBjb25zdCB0VmlldyA9IGRlZi50VmlldztcblxuICAvLyBDcmVhdGUgYSBUVmlldyBpZiB0aGVyZSBpc24ndCBvbmUsIG9yIHJlY3JlYXRlIGl0IGlmIHRoZSBmaXJzdCBjcmVhdGUgcGFzcyBkaWRuJ3RcbiAgLy8gY29tcGxldGUgc3VjY2Vzc2Z1bGx5IHNpbmNlIHdlIGNhbid0IGtub3cgZm9yIHN1cmUgd2hldGhlciBpdCdzIGluIGEgdXNhYmxlIHNoYXBlLlxuICBpZiAodFZpZXcgPT09IG51bGwgfHwgdFZpZXcuaW5jb21wbGV0ZUZpcnN0UGFzcykge1xuICAgIC8vIERlY2xhcmF0aW9uIG5vZGUgaGVyZSBpcyBudWxsIHNpbmNlIHRoaXMgZnVuY3Rpb24gaXMgY2FsbGVkIHdoZW4gd2UgZHluYW1pY2FsbHkgY3JlYXRlIGFcbiAgICAvLyBjb21wb25lbnQgYW5kIGhlbmNlIHRoZXJlIGlzIG5vIGRlY2xhcmF0aW9uLlxuICAgIGNvbnN0IGRlY2xUTm9kZSA9IG51bGw7XG4gICAgcmV0dXJuIGRlZi50VmlldyA9IGNyZWF0ZVRWaWV3KFxuICAgICAgICAgICAgICAgVFZpZXdUeXBlLkNvbXBvbmVudCwgZGVjbFROb2RlLCBkZWYudGVtcGxhdGUsIGRlZi5kZWNscywgZGVmLnZhcnMsIGRlZi5kaXJlY3RpdmVEZWZzLFxuICAgICAgICAgICAgICAgZGVmLnBpcGVEZWZzLCBkZWYudmlld1F1ZXJ5LCBkZWYuc2NoZW1hcywgZGVmLmNvbnN0cywgZGVmLmlkKTtcbiAgfVxuXG4gIHJldHVybiB0Vmlldztcbn1cblxuXG4vKipcbiAqIENyZWF0ZXMgYSBUVmlldyBpbnN0YW5jZVxuICpcbiAqIEBwYXJhbSB0eXBlIFR5cGUgb2YgYFRWaWV3YC5cbiAqIEBwYXJhbSBkZWNsVE5vZGUgRGVjbGFyYXRpb24gbG9jYXRpb24gb2YgdGhpcyBgVFZpZXdgLlxuICogQHBhcmFtIHRlbXBsYXRlRm4gVGVtcGxhdGUgZnVuY3Rpb25cbiAqIEBwYXJhbSBkZWNscyBUaGUgbnVtYmVyIG9mIG5vZGVzLCBsb2NhbCByZWZzLCBhbmQgcGlwZXMgaW4gdGhpcyB0ZW1wbGF0ZVxuICogQHBhcmFtIGRpcmVjdGl2ZXMgUmVnaXN0cnkgb2YgZGlyZWN0aXZlcyBmb3IgdGhpcyB2aWV3XG4gKiBAcGFyYW0gcGlwZXMgUmVnaXN0cnkgb2YgcGlwZXMgZm9yIHRoaXMgdmlld1xuICogQHBhcmFtIHZpZXdRdWVyeSBWaWV3IHF1ZXJpZXMgZm9yIHRoaXMgdmlld1xuICogQHBhcmFtIHNjaGVtYXMgU2NoZW1hcyBmb3IgdGhpcyB2aWV3XG4gKiBAcGFyYW0gY29uc3RzIENvbnN0YW50cyBmb3IgdGhpcyB2aWV3XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUVmlldyhcbiAgICB0eXBlOiBUVmlld1R5cGUsIGRlY2xUTm9kZTogVE5vZGV8bnVsbCwgdGVtcGxhdGVGbjogQ29tcG9uZW50VGVtcGxhdGU8YW55PnxudWxsLCBkZWNsczogbnVtYmVyLFxuICAgIHZhcnM6IG51bWJlciwgZGlyZWN0aXZlczogRGlyZWN0aXZlRGVmTGlzdE9yRmFjdG9yeXxudWxsLCBwaXBlczogUGlwZURlZkxpc3RPckZhY3Rvcnl8bnVsbCxcbiAgICB2aWV3UXVlcnk6IFZpZXdRdWVyaWVzRnVuY3Rpb248YW55PnxudWxsLCBzY2hlbWFzOiBTY2hlbWFNZXRhZGF0YVtdfG51bGwsXG4gICAgY29uc3RzT3JGYWN0b3J5OiBUQ29uc3RhbnRzT3JGYWN0b3J5fG51bGwsIHNzcklkOiBzdHJpbmd8bnVsbCk6IFRWaWV3IHtcbiAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS50VmlldysrO1xuICBjb25zdCBiaW5kaW5nU3RhcnRJbmRleCA9IEhFQURFUl9PRkZTRVQgKyBkZWNscztcbiAgLy8gVGhpcyBsZW5ndGggZG9lcyBub3QgeWV0IGNvbnRhaW4gaG9zdCBiaW5kaW5ncyBmcm9tIGNoaWxkIGRpcmVjdGl2ZXMgYmVjYXVzZSBhdCB0aGlzIHBvaW50LFxuICAvLyB3ZSBkb24ndCBrbm93IHdoaWNoIGRpcmVjdGl2ZXMgYXJlIGFjdGl2ZSBvbiB0aGlzIHRlbXBsYXRlLiBBcyBzb29uIGFzIGEgZGlyZWN0aXZlIGlzIG1hdGNoZWRcbiAgLy8gdGhhdCBoYXMgYSBob3N0IGJpbmRpbmcsIHdlIHdpbGwgdXBkYXRlIHRoZSBibHVlcHJpbnQgd2l0aCB0aGF0IGRlZidzIGhvc3RWYXJzIGNvdW50LlxuICBjb25zdCBpbml0aWFsVmlld0xlbmd0aCA9IGJpbmRpbmdTdGFydEluZGV4ICsgdmFycztcbiAgY29uc3QgYmx1ZXByaW50ID0gY3JlYXRlVmlld0JsdWVwcmludChiaW5kaW5nU3RhcnRJbmRleCwgaW5pdGlhbFZpZXdMZW5ndGgpO1xuICBjb25zdCBjb25zdHMgPSB0eXBlb2YgY29uc3RzT3JGYWN0b3J5ID09PSAnZnVuY3Rpb24nID8gY29uc3RzT3JGYWN0b3J5KCkgOiBjb25zdHNPckZhY3Rvcnk7XG4gIGNvbnN0IHRWaWV3ID0gYmx1ZXByaW50W1RWSUVXIGFzIGFueV0gPSB7XG4gICAgdHlwZTogdHlwZSxcbiAgICBibHVlcHJpbnQ6IGJsdWVwcmludCxcbiAgICB0ZW1wbGF0ZTogdGVtcGxhdGVGbixcbiAgICBxdWVyaWVzOiBudWxsLFxuICAgIHZpZXdRdWVyeTogdmlld1F1ZXJ5LFxuICAgIGRlY2xUTm9kZTogZGVjbFROb2RlLFxuICAgIGRhdGE6IGJsdWVwcmludC5zbGljZSgpLmZpbGwobnVsbCwgYmluZGluZ1N0YXJ0SW5kZXgpLFxuICAgIGJpbmRpbmdTdGFydEluZGV4OiBiaW5kaW5nU3RhcnRJbmRleCxcbiAgICBleHBhbmRvU3RhcnRJbmRleDogaW5pdGlhbFZpZXdMZW5ndGgsXG4gICAgaG9zdEJpbmRpbmdPcENvZGVzOiBudWxsLFxuICAgIGZpcnN0Q3JlYXRlUGFzczogdHJ1ZSxcbiAgICBmaXJzdFVwZGF0ZVBhc3M6IHRydWUsXG4gICAgc3RhdGljVmlld1F1ZXJpZXM6IGZhbHNlLFxuICAgIHN0YXRpY0NvbnRlbnRRdWVyaWVzOiBmYWxzZSxcbiAgICBwcmVPcmRlckhvb2tzOiBudWxsLFxuICAgIHByZU9yZGVyQ2hlY2tIb29rczogbnVsbCxcbiAgICBjb250ZW50SG9va3M6IG51bGwsXG4gICAgY29udGVudENoZWNrSG9va3M6IG51bGwsXG4gICAgdmlld0hvb2tzOiBudWxsLFxuICAgIHZpZXdDaGVja0hvb2tzOiBudWxsLFxuICAgIGRlc3Ryb3lIb29rczogbnVsbCxcbiAgICBjbGVhbnVwOiBudWxsLFxuICAgIGNvbnRlbnRRdWVyaWVzOiBudWxsLFxuICAgIGNvbXBvbmVudHM6IG51bGwsXG4gICAgZGlyZWN0aXZlUmVnaXN0cnk6IHR5cGVvZiBkaXJlY3RpdmVzID09PSAnZnVuY3Rpb24nID8gZGlyZWN0aXZlcygpIDogZGlyZWN0aXZlcyxcbiAgICBwaXBlUmVnaXN0cnk6IHR5cGVvZiBwaXBlcyA9PT0gJ2Z1bmN0aW9uJyA/IHBpcGVzKCkgOiBwaXBlcyxcbiAgICBmaXJzdENoaWxkOiBudWxsLFxuICAgIHNjaGVtYXM6IHNjaGVtYXMsXG4gICAgY29uc3RzOiBjb25zdHMsXG4gICAgaW5jb21wbGV0ZUZpcnN0UGFzczogZmFsc2UsXG4gICAgc3NySWQsXG4gIH07XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAvLyBGb3IgcGVyZm9ybWFuY2UgcmVhc29ucyBpdCBpcyBpbXBvcnRhbnQgdGhhdCB0aGUgdFZpZXcgcmV0YWlucyB0aGUgc2FtZSBzaGFwZSBkdXJpbmcgcnVudGltZS5cbiAgICAvLyAoVG8gbWFrZSBzdXJlIHRoYXQgYWxsIG9mIHRoZSBjb2RlIGlzIG1vbm9tb3JwaGljLikgRm9yIHRoaXMgcmVhc29uIHdlIHNlYWwgdGhlIG9iamVjdCB0b1xuICAgIC8vIHByZXZlbnQgY2xhc3MgdHJhbnNpdGlvbnMuXG4gICAgT2JqZWN0LnNlYWwodFZpZXcpO1xuICB9XG4gIHJldHVybiB0Vmlldztcbn1cblxuZnVuY3Rpb24gY3JlYXRlVmlld0JsdWVwcmludChiaW5kaW5nU3RhcnRJbmRleDogbnVtYmVyLCBpbml0aWFsVmlld0xlbmd0aDogbnVtYmVyKTogTFZpZXcge1xuICBjb25zdCBibHVlcHJpbnQgPSBbXTtcblxuICBmb3IgKGxldCBpID0gMDsgaSA8IGluaXRpYWxWaWV3TGVuZ3RoOyBpKyspIHtcbiAgICBibHVlcHJpbnQucHVzaChpIDwgYmluZGluZ1N0YXJ0SW5kZXggPyBudWxsIDogTk9fQ0hBTkdFKTtcbiAgfVxuXG4gIHJldHVybiBibHVlcHJpbnQgYXMgTFZpZXc7XG59XG5cbi8qKlxuICogTG9jYXRlcyB0aGUgaG9zdCBuYXRpdmUgZWxlbWVudCwgdXNlZCBmb3IgYm9vdHN0cmFwcGluZyBleGlzdGluZyBub2RlcyBpbnRvIHJlbmRlcmluZyBwaXBlbGluZS5cbiAqXG4gKiBAcGFyYW0gcmVuZGVyZXIgdGhlIHJlbmRlcmVyIHVzZWQgdG8gbG9jYXRlIHRoZSBlbGVtZW50LlxuICogQHBhcmFtIGVsZW1lbnRPclNlbGVjdG9yIFJlbmRlciBlbGVtZW50IG9yIENTUyBzZWxlY3RvciB0byBsb2NhdGUgdGhlIGVsZW1lbnQuXG4gKiBAcGFyYW0gZW5jYXBzdWxhdGlvbiBWaWV3IEVuY2Fwc3VsYXRpb24gZGVmaW5lZCBmb3IgY29tcG9uZW50IHRoYXQgcmVxdWVzdHMgaG9zdCBlbGVtZW50LlxuICogQHBhcmFtIGluamVjdG9yIFJvb3QgdmlldyBpbmplY3RvciBpbnN0YW5jZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGxvY2F0ZUhvc3RFbGVtZW50KFxuICAgIHJlbmRlcmVyOiBSZW5kZXJlciwgZWxlbWVudE9yU2VsZWN0b3I6IFJFbGVtZW50fHN0cmluZywgZW5jYXBzdWxhdGlvbjogVmlld0VuY2Fwc3VsYXRpb24sXG4gICAgaW5qZWN0b3I6IEluamVjdG9yKTogUkVsZW1lbnQge1xuICAvLyBOb3RlOiB3ZSB1c2UgZGVmYXVsdCB2YWx1ZSBmb3IgdGhlIGBQUkVTRVJWRV9IT1NUX0NPTlRFTlRgIGhlcmUgZXZlbiB0aG91Z2ggaXQncyBhXG4gIC8vIHRyZWUtc2hha2FibGUgb25lIChwcm92aWRlZEluOidyb290JykuIFRoaXMgY29kZSBwYXRoIGNhbiBiZSB0cmlnZ2VyZWQgZHVyaW5nIGR5bmFtaWNcbiAgLy8gY29tcG9uZW50IGNyZWF0aW9uIChhZnRlciBjYWxsaW5nIFZpZXdDb250YWluZXJSZWYuY3JlYXRlQ29tcG9uZW50KSB3aGVuIGFuIGluamVjdG9yXG4gIC8vIGluc3RhbmNlIGNhbiBiZSBwcm92aWRlZC4gVGhlIGluamVjdG9yIGluc3RhbmNlIG1pZ2h0IGJlIGRpc2Nvbm5lY3RlZCBmcm9tIHRoZSBtYWluIERJXG4gIC8vIHRyZWUsIHRodXMgdGhlIGBQUkVTRVJWRV9IT1NUX0NPTlRFTlRgIHdvdWxkIG5vdCBiZSBhYmxlIHRvIGluc3RhbnRpYXRlLiBJbiB0aGlzIGNhc2UsIHRoZVxuICAvLyBkZWZhdWx0IHZhbHVlIHdpbGwgYmUgdXNlZC5cbiAgY29uc3QgcHJlc2VydmVIb3N0Q29udGVudCA9IGluamVjdG9yLmdldChQUkVTRVJWRV9IT1NUX0NPTlRFTlQsIFBSRVNFUlZFX0hPU1RfQ09OVEVOVF9ERUZBVUxUKTtcblxuICAvLyBXaGVuIHVzaW5nIG5hdGl2ZSBTaGFkb3cgRE9NLCBkbyBub3QgY2xlYXIgaG9zdCBlbGVtZW50IHRvIGFsbG93IG5hdGl2ZSBzbG90XG4gIC8vIHByb2plY3Rpb24uXG4gIGNvbnN0IHByZXNlcnZlQ29udGVudCA9IHByZXNlcnZlSG9zdENvbnRlbnQgfHwgZW5jYXBzdWxhdGlvbiA9PT0gVmlld0VuY2Fwc3VsYXRpb24uU2hhZG93RG9tO1xuICBjb25zdCByb290RWxlbWVudCA9IHJlbmRlcmVyLnNlbGVjdFJvb3RFbGVtZW50KGVsZW1lbnRPclNlbGVjdG9yLCBwcmVzZXJ2ZUNvbnRlbnQpO1xuICBhcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtKHJvb3RFbGVtZW50IGFzIEhUTUxFbGVtZW50KTtcbiAgcmV0dXJuIHJvb3RFbGVtZW50O1xufVxuXG4vKipcbiAqIEFwcGxpZXMgYW55IHJvb3QgZWxlbWVudCB0cmFuc2Zvcm1hdGlvbnMgdGhhdCBhcmUgbmVlZGVkLiBJZiBoeWRyYXRpb24gaXMgZW5hYmxlZCxcbiAqIHRoaXMgd2lsbCBwcm9jZXNzIGNvcnJ1cHRlZCB0ZXh0IG5vZGVzLlxuICpcbiAqIEBwYXJhbSByb290RWxlbWVudCB0aGUgYXBwIHJvb3QgSFRNTCBFbGVtZW50XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtKHJvb3RFbGVtZW50OiBIVE1MRWxlbWVudCkge1xuICBfYXBwbHlSb290RWxlbWVudFRyYW5zZm9ybUltcGwocm9vdEVsZW1lbnQgYXMgSFRNTEVsZW1lbnQpO1xufVxuXG4vKipcbiAqIFJlZmVyZW5jZSB0byBhIGZ1bmN0aW9uIHRoYXQgYXBwbGllcyB0cmFuc2Zvcm1hdGlvbnMgdG8gdGhlIHJvb3QgSFRNTCBlbGVtZW50XG4gKiBvZiBhbiBhcHAuIFdoZW4gaHlkcmF0aW9uIGlzIGVuYWJsZWQsIHRoaXMgcHJvY2Vzc2VzIGFueSBjb3JydXB0IHRleHQgbm9kZXNcbiAqIHNvIHRoZXkgYXJlIHByb3Blcmx5IGh5ZHJhdGFibGUgb24gdGhlIGNsaWVudC5cbiAqXG4gKiBAcGFyYW0gcm9vdEVsZW1lbnQgdGhlIGFwcCByb290IEhUTUwgRWxlbWVudFxuICovXG5sZXQgX2FwcGx5Um9vdEVsZW1lbnRUcmFuc2Zvcm1JbXBsOiB0eXBlb2YgYXBwbHlSb290RWxlbWVudFRyYW5zZm9ybUltcGwgPVxuICAgIChyb290RWxlbWVudDogSFRNTEVsZW1lbnQpID0+IG51bGw7XG5cbi8qKlxuICogUHJvY2Vzc2VzIHRleHQgbm9kZSBtYXJrZXJzIGJlZm9yZSBoeWRyYXRpb24gYmVnaW5zLiBUaGlzIHJlcGxhY2VzIGFueSBzcGVjaWFsIGNvbW1lbnRcbiAqIG5vZGVzIHRoYXQgd2VyZSBhZGRlZCBwcmlvciB0byBzZXJpYWxpemF0aW9uIGFyZSBzd2FwcGVkIG91dCB0byByZXN0b3JlIHByb3BlciB0ZXh0XG4gKiBub2RlcyBiZWZvcmUgaHlkcmF0aW9uLlxuICpcbiAqIEBwYXJhbSByb290RWxlbWVudCB0aGUgYXBwIHJvb3QgSFRNTCBFbGVtZW50XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBhcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtSW1wbChyb290RWxlbWVudDogSFRNTEVsZW1lbnQpIHtcbiAgaWYgKHJvb3RFbGVtZW50Lmhhc0F0dHJpYnV0ZShTS0lQX0hZRFJBVElPTl9BVFRSX05BTUUpKSB7XG4gICAgLy8gSGFuZGxlIGEgc2l0dWF0aW9uIHdoZW4gdGhlIGBuZ1NraXBIeWRyYXRpb25gIGF0dHJpYnV0ZSBpcyBhcHBsaWVkXG4gICAgLy8gdG8gdGhlIHJvb3Qgbm9kZSBvZiBhbiBhcHBsaWNhdGlvbi4gSW4gdGhpcyBjYXNlLCB3ZSBzaG91bGQgY2xlYXJcbiAgICAvLyB0aGUgY29udGVudHMgYW5kIHJlbmRlciBldmVyeXRoaW5nIGZyb20gc2NyYXRjaC5cbiAgICBjbGVhckVsZW1lbnRDb250ZW50cyhyb290RWxlbWVudCBhcyBSRWxlbWVudCk7XG4gIH0gZWxzZSB7XG4gICAgcHJvY2Vzc1RleHROb2RlTWFya2Vyc0JlZm9yZUh5ZHJhdGlvbihyb290RWxlbWVudCk7XG4gIH1cbn1cblxuLyoqXG4gKiBTZXRzIHRoZSBpbXBsZW1lbnRhdGlvbiBmb3IgdGhlIGBhcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtYCBmdW5jdGlvbi5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGVuYWJsZUFwcGx5Um9vdEVsZW1lbnRUcmFuc2Zvcm1JbXBsKCkge1xuICBfYXBwbHlSb290RWxlbWVudFRyYW5zZm9ybUltcGwgPSBhcHBseVJvb3RFbGVtZW50VHJhbnNmb3JtSW1wbDtcbn1cblxuLyoqXG4gKiBTYXZlcyBjb250ZXh0IGZvciB0aGlzIGNsZWFudXAgZnVuY3Rpb24gaW4gTFZpZXcuY2xlYW51cEluc3RhbmNlcy5cbiAqXG4gKiBPbiB0aGUgZmlyc3QgdGVtcGxhdGUgcGFzcywgc2F2ZXMgaW4gVFZpZXc6XG4gKiAtIENsZWFudXAgZnVuY3Rpb25cbiAqIC0gSW5kZXggb2YgY29udGV4dCB3ZSBqdXN0IHNhdmVkIGluIExWaWV3LmNsZWFudXBJbnN0YW5jZXNcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHN0b3JlQ2xlYW51cFdpdGhDb250ZXh0KFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCBjb250ZXh0OiBhbnksIGNsZWFudXBGbjogRnVuY3Rpb24pOiB2b2lkIHtcbiAgY29uc3QgbENsZWFudXAgPSBnZXRPckNyZWF0ZUxWaWV3Q2xlYW51cChsVmlldyk7XG5cbiAgLy8gSGlzdG9yaWNhbGx5IHRoZSBgc3RvcmVDbGVhbnVwV2l0aENvbnRleHRgIHdhcyB1c2VkIHRvIHJlZ2lzdGVyIGJvdGggZnJhbWV3b3JrLWxldmVsIGFuZFxuICAvLyB1c2VyLWRlZmluZWQgY2xlYW51cCBjYWxsYmFja3MsIGJ1dCBvdmVyIHRpbWUgdGhvc2UgdHdvIHR5cGVzIG9mIGNsZWFudXBzIHdlcmUgc2VwYXJhdGVkLlxuICAvLyBUaGlzIGRldiBtb2RlIGNoZWNrcyBhc3N1cmVzIHRoYXQgdXNlci1sZXZlbCBjbGVhbnVwIGNhbGxiYWNrcyBhcmUgX25vdF8gc3RvcmVkIGluIGRhdGFcbiAgLy8gc3RydWN0dXJlcyByZXNlcnZlZCBmb3IgZnJhbWV3b3JrLXNwZWNpZmljIGhvb2tzLlxuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydERlZmluZWQoXG4gICAgICAgICAgY29udGV4dCwgJ0NsZWFudXAgY29udGV4dCBpcyBtYW5kYXRvcnkgd2hlbiByZWdpc3RlcmluZyBmcmFtZXdvcmstbGV2ZWwgZGVzdHJveSBob29rcycpO1xuICBsQ2xlYW51cC5wdXNoKGNvbnRleHQpO1xuXG4gIGlmICh0Vmlldy5maXJzdENyZWF0ZVBhc3MpIHtcbiAgICBnZXRPckNyZWF0ZVRWaWV3Q2xlYW51cCh0VmlldykucHVzaChjbGVhbnVwRm4sIGxDbGVhbnVwLmxlbmd0aCAtIDEpO1xuICB9IGVsc2Uge1xuICAgIC8vIE1ha2Ugc3VyZSB0aGF0IG5vIG5ldyBmcmFtZXdvcmstbGV2ZWwgY2xlYW51cCBmdW5jdGlvbnMgYXJlIHJlZ2lzdGVyZWQgYWZ0ZXIgdGhlIGZpcnN0XG4gICAgLy8gdGVtcGxhdGUgcGFzcyBpcyBkb25lIChhbmQgVFZpZXcgZGF0YSBzdHJ1Y3R1cmVzIGFyZSBtZWFudCB0byBmdWxseSBjb25zdHJ1Y3RlZCkuXG4gICAgaWYgKG5nRGV2TW9kZSkge1xuICAgICAgT2JqZWN0LmZyZWV6ZShnZXRPckNyZWF0ZVRWaWV3Q2xlYW51cCh0VmlldykpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIENvbnN0cnVjdHMgYSBUTm9kZSBvYmplY3QgZnJvbSB0aGUgYXJndW1lbnRzLlxuICpcbiAqIEBwYXJhbSB0VmlldyBgVFZpZXdgIHRvIHdoaWNoIHRoaXMgYFROb2RlYCBiZWxvbmdzXG4gKiBAcGFyYW0gdFBhcmVudCBQYXJlbnQgYFROb2RlYFxuICogQHBhcmFtIHR5cGUgVGhlIHR5cGUgb2YgdGhlIG5vZGVcbiAqIEBwYXJhbSBpbmRleCBUaGUgaW5kZXggb2YgdGhlIFROb2RlIGluIFRWaWV3LmRhdGEsIGFkanVzdGVkIGZvciBIRUFERVJfT0ZGU0VUXG4gKiBAcGFyYW0gdGFnTmFtZSBUaGUgdGFnIG5hbWUgb2YgdGhlIG5vZGVcbiAqIEBwYXJhbSBhdHRycyBUaGUgYXR0cmlidXRlcyBkZWZpbmVkIG9uIHRoaXMgbm9kZVxuICogQHJldHVybnMgdGhlIFROb2RlIG9iamVjdFxuICovXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVE5vZGUoXG4gICAgdFZpZXc6IFRWaWV3LCB0UGFyZW50OiBURWxlbWVudE5vZGV8VENvbnRhaW5lck5vZGV8bnVsbCwgdHlwZTogVE5vZGVUeXBlLkNvbnRhaW5lcixcbiAgICBpbmRleDogbnVtYmVyLCB0YWdOYW1lOiBzdHJpbmd8bnVsbCwgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBUQ29udGFpbmVyTm9kZTtcbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIHRQYXJlbnQ6IFRFbGVtZW50Tm9kZXxUQ29udGFpbmVyTm9kZXxudWxsLCB0eXBlOiBUTm9kZVR5cGUuRWxlbWVudHxUTm9kZVR5cGUuVGV4dCxcbiAgICBpbmRleDogbnVtYmVyLCB0YWdOYW1lOiBzdHJpbmd8bnVsbCwgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBURWxlbWVudE5vZGU7XG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVE5vZGUoXG4gICAgdFZpZXc6IFRWaWV3LCB0UGFyZW50OiBURWxlbWVudE5vZGV8VENvbnRhaW5lck5vZGV8bnVsbCwgdHlwZTogVE5vZGVUeXBlLkVsZW1lbnRDb250YWluZXIsXG4gICAgaW5kZXg6IG51bWJlciwgdGFnTmFtZTogc3RyaW5nfG51bGwsIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTogVEVsZW1lbnRDb250YWluZXJOb2RlO1xuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVROb2RlKFxuICAgIHRWaWV3OiBUVmlldywgdFBhcmVudDogVEVsZW1lbnROb2RlfFRDb250YWluZXJOb2RlfG51bGwsIHR5cGU6IFROb2RlVHlwZS5JY3UsIGluZGV4OiBudW1iZXIsXG4gICAgdGFnTmFtZTogc3RyaW5nfG51bGwsIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTogVEljdUNvbnRhaW5lck5vZGU7XG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVE5vZGUoXG4gICAgdFZpZXc6IFRWaWV3LCB0UGFyZW50OiBURWxlbWVudE5vZGV8VENvbnRhaW5lck5vZGV8bnVsbCwgdHlwZTogVE5vZGVUeXBlLlByb2plY3Rpb24sXG4gICAgaW5kZXg6IG51bWJlciwgdGFnTmFtZTogc3RyaW5nfG51bGwsIGF0dHJzOiBUQXR0cmlidXRlc3xudWxsKTogVFByb2plY3Rpb25Ob2RlO1xuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVROb2RlKFxuICAgIHRWaWV3OiBUVmlldywgdFBhcmVudDogVEVsZW1lbnROb2RlfFRDb250YWluZXJOb2RlfG51bGwsIHR5cGU6IFROb2RlVHlwZSwgaW5kZXg6IG51bWJlcixcbiAgICB0YWdOYW1lOiBzdHJpbmd8bnVsbCwgYXR0cnM6IFRBdHRyaWJ1dGVzfG51bGwpOiBUTm9kZTtcbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUTm9kZShcbiAgICB0VmlldzogVFZpZXcsIHRQYXJlbnQ6IFRFbGVtZW50Tm9kZXxUQ29udGFpbmVyTm9kZXxudWxsLCB0eXBlOiBUTm9kZVR5cGUsIGluZGV4OiBudW1iZXIsXG4gICAgdmFsdWU6IHN0cmluZ3xudWxsLCBhdHRyczogVEF0dHJpYnV0ZXN8bnVsbCk6IFROb2RlIHtcbiAgbmdEZXZNb2RlICYmIGluZGV4ICE9PSAwICYmICAvLyAwIGFyZSBib2d1cyBub2RlcyBhbmQgdGhleSBhcmUgT0suIFNlZSBgY3JlYXRlQ29udGFpbmVyUmVmYCBpblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIGB2aWV3X2VuZ2luZV9jb21wYXRpYmlsaXR5YCBmb3IgYWRkaXRpb25hbCBjb250ZXh0LlxuICAgICAgYXNzZXJ0R3JlYXRlclRoYW5PckVxdWFsKGluZGV4LCBIRUFERVJfT0ZGU0VULCAnVE5vZGVzIGNhblxcJ3QgYmUgaW4gdGhlIExWaWV3IGhlYWRlci4nKTtcbiAgbmdEZXZNb2RlICYmIGFzc2VydE5vdFNhbWUoYXR0cnMsIHVuZGVmaW5lZCwgJ1xcJ3VuZGVmaW5lZFxcJyBpcyBub3QgdmFsaWQgdmFsdWUgZm9yIFxcJ2F0dHJzXFwnJyk7XG4gIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUudE5vZGUrKztcbiAgbmdEZXZNb2RlICYmIHRQYXJlbnQgJiYgYXNzZXJ0VE5vZGVGb3JUVmlldyh0UGFyZW50LCB0Vmlldyk7XG4gIGxldCBpbmplY3RvckluZGV4ID0gdFBhcmVudCA/IHRQYXJlbnQuaW5qZWN0b3JJbmRleCA6IC0xO1xuICBjb25zdCB0Tm9kZSA9IHtcbiAgICB0eXBlLFxuICAgIGluZGV4LFxuICAgIGluc2VydEJlZm9yZUluZGV4OiBudWxsLFxuICAgIGluamVjdG9ySW5kZXgsXG4gICAgZGlyZWN0aXZlU3RhcnQ6IC0xLFxuICAgIGRpcmVjdGl2ZUVuZDogLTEsXG4gICAgZGlyZWN0aXZlU3R5bGluZ0xhc3Q6IC0xLFxuICAgIGNvbXBvbmVudE9mZnNldDogLTEsXG4gICAgcHJvcGVydHlCaW5kaW5nczogbnVsbCxcbiAgICBmbGFnczogMCxcbiAgICBwcm92aWRlckluZGV4ZXM6IDAsXG4gICAgdmFsdWU6IHZhbHVlLFxuICAgIGF0dHJzOiBhdHRycyxcbiAgICBtZXJnZWRBdHRyczogbnVsbCxcbiAgICBsb2NhbE5hbWVzOiBudWxsLFxuICAgIGluaXRpYWxJbnB1dHM6IHVuZGVmaW5lZCxcbiAgICBpbnB1dHM6IG51bGwsXG4gICAgb3V0cHV0czogbnVsbCxcbiAgICB0VmlldzogbnVsbCxcbiAgICBuZXh0OiBudWxsLFxuICAgIHByZXY6IG51bGwsXG4gICAgcHJvamVjdGlvbk5leHQ6IG51bGwsXG4gICAgY2hpbGQ6IG51bGwsXG4gICAgcGFyZW50OiB0UGFyZW50LFxuICAgIHByb2plY3Rpb246IG51bGwsXG4gICAgc3R5bGVzOiBudWxsLFxuICAgIHN0eWxlc1dpdGhvdXRIb3N0OiBudWxsLFxuICAgIHJlc2lkdWFsU3R5bGVzOiB1bmRlZmluZWQsXG4gICAgY2xhc3NlczogbnVsbCxcbiAgICBjbGFzc2VzV2l0aG91dEhvc3Q6IG51bGwsXG4gICAgcmVzaWR1YWxDbGFzc2VzOiB1bmRlZmluZWQsXG4gICAgY2xhc3NCaW5kaW5nczogMCBhcyBhbnksXG4gICAgc3R5bGVCaW5kaW5nczogMCBhcyBhbnksXG4gIH07XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAvLyBGb3IgcGVyZm9ybWFuY2UgcmVhc29ucyBpdCBpcyBpbXBvcnRhbnQgdGhhdCB0aGUgdE5vZGUgcmV0YWlucyB0aGUgc2FtZSBzaGFwZSBkdXJpbmcgcnVudGltZS5cbiAgICAvLyAoVG8gbWFrZSBzdXJlIHRoYXQgYWxsIG9mIHRoZSBjb2RlIGlzIG1vbm9tb3JwaGljLikgRm9yIHRoaXMgcmVhc29uIHdlIHNlYWwgdGhlIG9iamVjdCB0b1xuICAgIC8vIHByZXZlbnQgY2xhc3MgdHJhbnNpdGlvbnMuXG4gICAgT2JqZWN0LnNlYWwodE5vZGUpO1xuICB9XG4gIHJldHVybiB0Tm9kZTtcbn1cblxuLyoqXG4gKiBHZW5lcmF0ZXMgdGhlIGBQcm9wZXJ0eUFsaWFzZXNgIGRhdGEgc3RydWN0dXJlIGZyb20gdGhlIHByb3ZpZGVkIGlucHV0L291dHB1dCBtYXBwaW5nLlxuICogQHBhcmFtIGFsaWFzTWFwIElucHV0L291dHB1dCBtYXBwaW5nIGZyb20gdGhlIGRpcmVjdGl2ZSBkZWZpbml0aW9uLlxuICogQHBhcmFtIGRpcmVjdGl2ZUluZGV4IEluZGV4IG9mIHRoZSBkaXJlY3RpdmUuXG4gKiBAcGFyYW0gcHJvcGVydHlBbGlhc2VzIE9iamVjdCBpbiB3aGljaCB0byBzdG9yZSB0aGUgcmVzdWx0cy5cbiAqIEBwYXJhbSBob3N0RGlyZWN0aXZlQWxpYXNNYXAgT2JqZWN0IHVzZWQgdG8gYWxpYXMgb3IgZmlsdGVyIG91dCBwcm9wZXJ0aWVzIGZvciBob3N0IGRpcmVjdGl2ZXMuXG4gKiBJZiB0aGUgbWFwcGluZyBpcyBwcm92aWRlZCwgaXQnbGwgYWN0IGFzIGFuIGFsbG93bGlzdCwgYXMgd2VsbCBhcyBhIG1hcHBpbmcgb2Ygd2hhdCBwdWJsaWNcbiAqIG5hbWUgaW5wdXRzL291dHB1dHMgc2hvdWxkIGJlIGV4cG9zZWQgdW5kZXIuXG4gKi9cbmZ1bmN0aW9uIGdlbmVyYXRlUHJvcGVydHlBbGlhc2VzKFxuICAgIGFsaWFzTWFwOiB7W3B1YmxpY05hbWU6IHN0cmluZ106IHN0cmluZ30sIGRpcmVjdGl2ZUluZGV4OiBudW1iZXIsXG4gICAgcHJvcGVydHlBbGlhc2VzOiBQcm9wZXJ0eUFsaWFzZXN8bnVsbCxcbiAgICBob3N0RGlyZWN0aXZlQWxpYXNNYXA6IEhvc3REaXJlY3RpdmVCaW5kaW5nTWFwfG51bGwpOiBQcm9wZXJ0eUFsaWFzZXN8bnVsbCB7XG4gIGZvciAobGV0IHB1YmxpY05hbWUgaW4gYWxpYXNNYXApIHtcbiAgICBpZiAoYWxpYXNNYXAuaGFzT3duUHJvcGVydHkocHVibGljTmFtZSkpIHtcbiAgICAgIHByb3BlcnR5QWxpYXNlcyA9IHByb3BlcnR5QWxpYXNlcyA9PT0gbnVsbCA/IHt9IDogcHJvcGVydHlBbGlhc2VzO1xuICAgICAgY29uc3QgaW50ZXJuYWxOYW1lID0gYWxpYXNNYXBbcHVibGljTmFtZV07XG5cbiAgICAgIC8vIElmIHRoZXJlIGFyZSBubyBob3N0IGRpcmVjdGl2ZSBtYXBwaW5ncywgd2Ugd2FudCB0byByZW1hcCB1c2luZyB0aGUgYWxpYXMgbWFwIGZyb20gdGhlXG4gICAgICAvLyBkZWZpbml0aW9uIGl0c2VsZi4gSWYgdGhlcmUgaXMgYW4gYWxpYXMgbWFwLCBpdCBoYXMgdHdvIGZ1bmN0aW9uczpcbiAgICAgIC8vIDEuIEl0IHNlcnZlcyBhcyBhbiBhbGxvd2xpc3Qgb2YgYmluZGluZ3MgdGhhdCBhcmUgZXhwb3NlZCBieSB0aGUgaG9zdCBkaXJlY3RpdmVzLiBPbmx5IHRoZVxuICAgICAgLy8gb25lcyBpbnNpZGUgdGhlIGhvc3QgZGlyZWN0aXZlIG1hcCB3aWxsIGJlIGV4cG9zZWQgb24gdGhlIGhvc3QuXG4gICAgICAvLyAyLiBUaGUgcHVibGljIG5hbWUgb2YgdGhlIHByb3BlcnR5IGlzIGFsaWFzZWQgdXNpbmcgdGhlIGhvc3QgZGlyZWN0aXZlIGFsaWFzIG1hcCwgcmF0aGVyXG4gICAgICAvLyB0aGFuIHRoZSBhbGlhcyBtYXAgZnJvbSB0aGUgZGVmaW5pdGlvbi5cbiAgICAgIGlmIChob3N0RGlyZWN0aXZlQWxpYXNNYXAgPT09IG51bGwpIHtcbiAgICAgICAgYWRkUHJvcGVydHlBbGlhcyhwcm9wZXJ0eUFsaWFzZXMsIGRpcmVjdGl2ZUluZGV4LCBwdWJsaWNOYW1lLCBpbnRlcm5hbE5hbWUpO1xuICAgICAgfSBlbHNlIGlmIChob3N0RGlyZWN0aXZlQWxpYXNNYXAuaGFzT3duUHJvcGVydHkocHVibGljTmFtZSkpIHtcbiAgICAgICAgYWRkUHJvcGVydHlBbGlhcyhcbiAgICAgICAgICAgIHByb3BlcnR5QWxpYXNlcywgZGlyZWN0aXZlSW5kZXgsIGhvc3REaXJlY3RpdmVBbGlhc01hcFtwdWJsaWNOYW1lXSwgaW50ZXJuYWxOYW1lKTtcbiAgICAgIH1cbiAgICB9XG4gIH1cbiAgcmV0dXJuIHByb3BlcnR5QWxpYXNlcztcbn1cblxuZnVuY3Rpb24gYWRkUHJvcGVydHlBbGlhcyhcbiAgICBwcm9wZXJ0eUFsaWFzZXM6IFByb3BlcnR5QWxpYXNlcywgZGlyZWN0aXZlSW5kZXg6IG51bWJlciwgcHVibGljTmFtZTogc3RyaW5nLFxuICAgIGludGVybmFsTmFtZTogc3RyaW5nKSB7XG4gIGlmIChwcm9wZXJ0eUFsaWFzZXMuaGFzT3duUHJvcGVydHkocHVibGljTmFtZSkpIHtcbiAgICBwcm9wZXJ0eUFsaWFzZXNbcHVibGljTmFtZV0ucHVzaChkaXJlY3RpdmVJbmRleCwgaW50ZXJuYWxOYW1lKTtcbiAgfSBlbHNlIHtcbiAgICBwcm9wZXJ0eUFsaWFzZXNbcHVibGljTmFtZV0gPSBbZGlyZWN0aXZlSW5kZXgsIGludGVybmFsTmFtZV07XG4gIH1cbn1cblxuLyoqXG4gKiBJbml0aWFsaXplcyBkYXRhIHN0cnVjdHVyZXMgcmVxdWlyZWQgdG8gd29yayB3aXRoIGRpcmVjdGl2ZSBpbnB1dHMgYW5kIG91dHB1dHMuXG4gKiBJbml0aWFsaXphdGlvbiBpcyBkb25lIGZvciBhbGwgZGlyZWN0aXZlcyBtYXRjaGVkIG9uIGEgZ2l2ZW4gVE5vZGUuXG4gKi9cbmZ1bmN0aW9uIGluaXRpYWxpemVJbnB1dEFuZE91dHB1dEFsaWFzZXMoXG4gICAgdFZpZXc6IFRWaWV3LCB0Tm9kZTogVE5vZGUsIGhvc3REaXJlY3RpdmVEZWZpbml0aW9uTWFwOiBIb3N0RGlyZWN0aXZlRGVmc3xudWxsKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRGaXJzdENyZWF0ZVBhc3ModFZpZXcpO1xuXG4gIGNvbnN0IHN0YXJ0ID0gdE5vZGUuZGlyZWN0aXZlU3RhcnQ7XG4gIGNvbnN0IGVuZCA9IHROb2RlLmRpcmVjdGl2ZUVuZDtcbiAgY29uc3QgdFZpZXdEYXRhID0gdFZpZXcuZGF0YTtcblxuICBjb25zdCB0Tm9kZUF0dHJzID0gdE5vZGUuYXR0cnM7XG4gIGNvbnN0IGlucHV0c0Zyb21BdHRyczogSW5pdGlhbElucHV0RGF0YSA9IFtdO1xuICBsZXQgaW5wdXRzU3RvcmU6IFByb3BlcnR5QWxpYXNlc3xudWxsID0gbnVsbDtcbiAgbGV0IG91dHB1dHNTdG9yZTogUHJvcGVydHlBbGlhc2VzfG51bGwgPSBudWxsO1xuXG4gIGZvciAobGV0IGRpcmVjdGl2ZUluZGV4ID0gc3RhcnQ7IGRpcmVjdGl2ZUluZGV4IDwgZW5kOyBkaXJlY3RpdmVJbmRleCsrKSB7XG4gICAgY29uc3QgZGlyZWN0aXZlRGVmID0gdFZpZXdEYXRhW2RpcmVjdGl2ZUluZGV4XSBhcyBEaXJlY3RpdmVEZWY8YW55PjtcbiAgICBjb25zdCBhbGlhc0RhdGEgPVxuICAgICAgICBob3N0RGlyZWN0aXZlRGVmaW5pdGlvbk1hcCA/IGhvc3REaXJlY3RpdmVEZWZpbml0aW9uTWFwLmdldChkaXJlY3RpdmVEZWYpIDogbnVsbDtcbiAgICBjb25zdCBhbGlhc2VkSW5wdXRzID0gYWxpYXNEYXRhID8gYWxpYXNEYXRhLmlucHV0cyA6IG51bGw7XG4gICAgY29uc3QgYWxpYXNlZE91dHB1dHMgPSBhbGlhc0RhdGEgPyBhbGlhc0RhdGEub3V0cHV0cyA6IG51bGw7XG5cbiAgICBpbnB1dHNTdG9yZSA9XG4gICAgICAgIGdlbmVyYXRlUHJvcGVydHlBbGlhc2VzKGRpcmVjdGl2ZURlZi5pbnB1dHMsIGRpcmVjdGl2ZUluZGV4LCBpbnB1dHNTdG9yZSwgYWxpYXNlZElucHV0cyk7XG4gICAgb3V0cHV0c1N0b3JlID1cbiAgICAgICAgZ2VuZXJhdGVQcm9wZXJ0eUFsaWFzZXMoZGlyZWN0aXZlRGVmLm91dHB1dHMsIGRpcmVjdGl2ZUluZGV4LCBvdXRwdXRzU3RvcmUsIGFsaWFzZWRPdXRwdXRzKTtcbiAgICAvLyBEbyBub3QgdXNlIHVuYm91bmQgYXR0cmlidXRlcyBhcyBpbnB1dHMgdG8gc3RydWN0dXJhbCBkaXJlY3RpdmVzLCBzaW5jZSBzdHJ1Y3R1cmFsXG4gICAgLy8gZGlyZWN0aXZlIGlucHV0cyBjYW4gb25seSBiZSBzZXQgdXNpbmcgbWljcm9zeW50YXggKGUuZy4gYDxkaXYgKmRpcj1cImV4cFwiPmApLlxuICAgIC8vIFRPRE8oRlctMTkzMCk6IG1pY3Jvc3ludGF4IGV4cHJlc3Npb25zIG1heSBhbHNvIGNvbnRhaW4gdW5ib3VuZC9zdGF0aWMgYXR0cmlidXRlcywgd2hpY2hcbiAgICAvLyBzaG91bGQgYmUgc2V0IGZvciBpbmxpbmUgdGVtcGxhdGVzLlxuICAgIGNvbnN0IGluaXRpYWxJbnB1dHMgPVxuICAgICAgICAoaW5wdXRzU3RvcmUgIT09IG51bGwgJiYgdE5vZGVBdHRycyAhPT0gbnVsbCAmJiAhaXNJbmxpbmVUZW1wbGF0ZSh0Tm9kZSkpID9cbiAgICAgICAgZ2VuZXJhdGVJbml0aWFsSW5wdXRzKGlucHV0c1N0b3JlLCBkaXJlY3RpdmVJbmRleCwgdE5vZGVBdHRycykgOlxuICAgICAgICBudWxsO1xuICAgIGlucHV0c0Zyb21BdHRycy5wdXNoKGluaXRpYWxJbnB1dHMpO1xuICB9XG5cbiAgaWYgKGlucHV0c1N0b3JlICE9PSBudWxsKSB7XG4gICAgaWYgKGlucHV0c1N0b3JlLmhhc093blByb3BlcnR5KCdjbGFzcycpKSB7XG4gICAgICB0Tm9kZS5mbGFncyB8PSBUTm9kZUZsYWdzLmhhc0NsYXNzSW5wdXQ7XG4gICAgfVxuICAgIGlmIChpbnB1dHNTdG9yZS5oYXNPd25Qcm9wZXJ0eSgnc3R5bGUnKSkge1xuICAgICAgdE5vZGUuZmxhZ3MgfD0gVE5vZGVGbGFncy5oYXNTdHlsZUlucHV0O1xuICAgIH1cbiAgfVxuXG4gIHROb2RlLmluaXRpYWxJbnB1dHMgPSBpbnB1dHNGcm9tQXR0cnM7XG4gIHROb2RlLmlucHV0cyA9IGlucHV0c1N0b3JlO1xuICB0Tm9kZS5vdXRwdXRzID0gb3V0cHV0c1N0b3JlO1xufVxuXG4vKipcbiAqIE1hcHBpbmcgYmV0d2VlbiBhdHRyaWJ1dGVzIG5hbWVzIHRoYXQgZG9uJ3QgY29ycmVzcG9uZCB0byB0aGVpciBlbGVtZW50IHByb3BlcnR5IG5hbWVzLlxuICpcbiAqIFBlcmZvcm1hbmNlIG5vdGU6IHRoaXMgZnVuY3Rpb24gaXMgd3JpdHRlbiBhcyBhIHNlcmllcyBvZiBpZiBjaGVja3MgKGluc3RlYWQgb2YsIHNheSwgYSBwcm9wZXJ0eVxuICogb2JqZWN0IGxvb2t1cCkgZm9yIHBlcmZvcm1hbmNlIHJlYXNvbnMgLSB0aGUgc2VyaWVzIG9mIGBpZmAgY2hlY2tzIHNlZW1zIHRvIGJlIHRoZSBmYXN0ZXN0IHdheSBvZlxuICogbWFwcGluZyBwcm9wZXJ0eSBuYW1lcy4gRG8gTk9UIGNoYW5nZSB3aXRob3V0IGJlbmNobWFya2luZy5cbiAqXG4gKiBOb3RlOiB0aGlzIG1hcHBpbmcgaGFzIHRvIGJlIGtlcHQgaW4gc3luYyB3aXRoIHRoZSBlcXVhbGx5IG5hbWVkIG1hcHBpbmcgaW4gdGhlIHRlbXBsYXRlXG4gKiB0eXBlLWNoZWNraW5nIG1hY2hpbmVyeSBvZiBuZ3RzYy5cbiAqL1xuZnVuY3Rpb24gbWFwUHJvcE5hbWUobmFtZTogc3RyaW5nKTogc3RyaW5nIHtcbiAgaWYgKG5hbWUgPT09ICdjbGFzcycpIHJldHVybiAnY2xhc3NOYW1lJztcbiAgaWYgKG5hbWUgPT09ICdmb3InKSByZXR1cm4gJ2h0bWxGb3InO1xuICBpZiAobmFtZSA9PT0gJ2Zvcm1hY3Rpb24nKSByZXR1cm4gJ2Zvcm1BY3Rpb24nO1xuICBpZiAobmFtZSA9PT0gJ2lubmVySHRtbCcpIHJldHVybiAnaW5uZXJIVE1MJztcbiAgaWYgKG5hbWUgPT09ICdyZWFkb25seScpIHJldHVybiAncmVhZE9ubHknO1xuICBpZiAobmFtZSA9PT0gJ3RhYmluZGV4JykgcmV0dXJuICd0YWJJbmRleCc7XG4gIHJldHVybiBuYW1lO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gZWxlbWVudFByb3BlcnR5SW50ZXJuYWw8VD4oXG4gICAgdFZpZXc6IFRWaWV3LCB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldywgcHJvcE5hbWU6IHN0cmluZywgdmFsdWU6IFQsIHJlbmRlcmVyOiBSZW5kZXJlcixcbiAgICBzYW5pdGl6ZXI6IFNhbml0aXplckZufG51bGx8dW5kZWZpbmVkLCBuYXRpdmVPbmx5OiBib29sZWFuKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnROb3RTYW1lKHZhbHVlLCBOT19DSEFOR0UgYXMgYW55LCAnSW5jb21pbmcgdmFsdWUgc2hvdWxkIG5ldmVyIGJlIE5PX0NIQU5HRS4nKTtcbiAgY29uc3QgZWxlbWVudCA9IGdldE5hdGl2ZUJ5VE5vZGUodE5vZGUsIGxWaWV3KSBhcyBSRWxlbWVudCB8IFJDb21tZW50O1xuICBsZXQgaW5wdXREYXRhID0gdE5vZGUuaW5wdXRzO1xuICBsZXQgZGF0YVZhbHVlOiBQcm9wZXJ0eUFsaWFzVmFsdWV8dW5kZWZpbmVkO1xuICBpZiAoIW5hdGl2ZU9ubHkgJiYgaW5wdXREYXRhICE9IG51bGwgJiYgKGRhdGFWYWx1ZSA9IGlucHV0RGF0YVtwcm9wTmFtZV0pKSB7XG4gICAgc2V0SW5wdXRzRm9yUHJvcGVydHkodFZpZXcsIGxWaWV3LCBkYXRhVmFsdWUsIHByb3BOYW1lLCB2YWx1ZSk7XG4gICAgaWYgKGlzQ29tcG9uZW50SG9zdCh0Tm9kZSkpIG1hcmtEaXJ0eUlmT25QdXNoKGxWaWV3LCB0Tm9kZS5pbmRleCk7XG4gICAgaWYgKG5nRGV2TW9kZSkge1xuICAgICAgc2V0TmdSZWZsZWN0UHJvcGVydGllcyhsVmlldywgZWxlbWVudCwgdE5vZGUudHlwZSwgZGF0YVZhbHVlLCB2YWx1ZSk7XG4gICAgfVxuICB9IGVsc2UgaWYgKHROb2RlLnR5cGUgJiBUTm9kZVR5cGUuQW55Uk5vZGUpIHtcbiAgICBwcm9wTmFtZSA9IG1hcFByb3BOYW1lKHByb3BOYW1lKTtcblxuICAgIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAgIHZhbGlkYXRlQWdhaW5zdEV2ZW50UHJvcGVydGllcyhwcm9wTmFtZSk7XG4gICAgICBpZiAoIWlzUHJvcGVydHlWYWxpZChlbGVtZW50LCBwcm9wTmFtZSwgdE5vZGUudmFsdWUsIHRWaWV3LnNjaGVtYXMpKSB7XG4gICAgICAgIGhhbmRsZVVua25vd25Qcm9wZXJ0eUVycm9yKHByb3BOYW1lLCB0Tm9kZS52YWx1ZSwgdE5vZGUudHlwZSwgbFZpZXcpO1xuICAgICAgfVxuICAgICAgbmdEZXZNb2RlLnJlbmRlcmVyU2V0UHJvcGVydHkrKztcbiAgICB9XG5cbiAgICAvLyBJdCBpcyBhc3N1bWVkIHRoYXQgdGhlIHNhbml0aXplciBpcyBvbmx5IGFkZGVkIHdoZW4gdGhlIGNvbXBpbGVyIGRldGVybWluZXMgdGhhdCB0aGVcbiAgICAvLyBwcm9wZXJ0eSBpcyByaXNreSwgc28gc2FuaXRpemF0aW9uIGNhbiBiZSBkb25lIHdpdGhvdXQgZnVydGhlciBjaGVja3MuXG4gICAgdmFsdWUgPSBzYW5pdGl6ZXIgIT0gbnVsbCA/IChzYW5pdGl6ZXIodmFsdWUsIHROb2RlLnZhbHVlIHx8ICcnLCBwcm9wTmFtZSkgYXMgYW55KSA6IHZhbHVlO1xuICAgIHJlbmRlcmVyLnNldFByb3BlcnR5KGVsZW1lbnQgYXMgUkVsZW1lbnQsIHByb3BOYW1lLCB2YWx1ZSk7XG4gIH0gZWxzZSBpZiAodE5vZGUudHlwZSAmIFROb2RlVHlwZS5BbnlDb250YWluZXIpIHtcbiAgICAvLyBJZiB0aGUgbm9kZSBpcyBhIGNvbnRhaW5lciBhbmQgdGhlIHByb3BlcnR5IGRpZG4ndFxuICAgIC8vIG1hdGNoIGFueSBvZiB0aGUgaW5wdXRzIG9yIHNjaGVtYXMgd2Ugc2hvdWxkIHRocm93LlxuICAgIGlmIChuZ0Rldk1vZGUgJiYgIW1hdGNoaW5nU2NoZW1hcyh0Vmlldy5zY2hlbWFzLCB0Tm9kZS52YWx1ZSkpIHtcbiAgICAgIGhhbmRsZVVua25vd25Qcm9wZXJ0eUVycm9yKHByb3BOYW1lLCB0Tm9kZS52YWx1ZSwgdE5vZGUudHlwZSwgbFZpZXcpO1xuICAgIH1cbiAgfVxufVxuXG4vKiogSWYgbm9kZSBpcyBhbiBPblB1c2ggY29tcG9uZW50LCBtYXJrcyBpdHMgTFZpZXcgZGlydHkuICovXG5leHBvcnQgZnVuY3Rpb24gbWFya0RpcnR5SWZPblB1c2gobFZpZXc6IExWaWV3LCB2aWV3SW5kZXg6IG51bWJlcik6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TFZpZXcobFZpZXcpO1xuICBjb25zdCBjaGlsZENvbXBvbmVudExWaWV3ID0gZ2V0Q29tcG9uZW50TFZpZXdCeUluZGV4KHZpZXdJbmRleCwgbFZpZXcpO1xuICBpZiAoIShjaGlsZENvbXBvbmVudExWaWV3W0ZMQUdTXSAmIExWaWV3RmxhZ3MuQ2hlY2tBbHdheXMpKSB7XG4gICAgY2hpbGRDb21wb25lbnRMVmlld1tGTEFHU10gfD0gTFZpZXdGbGFncy5EaXJ0eTtcbiAgfVxufVxuXG5mdW5jdGlvbiBzZXROZ1JlZmxlY3RQcm9wZXJ0eShcbiAgICBsVmlldzogTFZpZXcsIGVsZW1lbnQ6IFJFbGVtZW50fFJDb21tZW50LCB0eXBlOiBUTm9kZVR5cGUsIGF0dHJOYW1lOiBzdHJpbmcsIHZhbHVlOiBhbnkpIHtcbiAgY29uc3QgcmVuZGVyZXIgPSBsVmlld1tSRU5ERVJFUl07XG4gIGF0dHJOYW1lID0gbm9ybWFsaXplRGVidWdCaW5kaW5nTmFtZShhdHRyTmFtZSk7XG4gIGNvbnN0IGRlYnVnVmFsdWUgPSBub3JtYWxpemVEZWJ1Z0JpbmRpbmdWYWx1ZSh2YWx1ZSk7XG4gIGlmICh0eXBlICYgVE5vZGVUeXBlLkFueVJOb2RlKSB7XG4gICAgaWYgKHZhbHVlID09IG51bGwpIHtcbiAgICAgIHJlbmRlcmVyLnJlbW92ZUF0dHJpYnV0ZSgoZWxlbWVudCBhcyBSRWxlbWVudCksIGF0dHJOYW1lKTtcbiAgICB9IGVsc2Uge1xuICAgICAgcmVuZGVyZXIuc2V0QXR0cmlidXRlKChlbGVtZW50IGFzIFJFbGVtZW50KSwgYXR0ck5hbWUsIGRlYnVnVmFsdWUpO1xuICAgIH1cbiAgfSBlbHNlIHtcbiAgICBjb25zdCB0ZXh0Q29udGVudCA9XG4gICAgICAgIGVzY2FwZUNvbW1lbnRUZXh0KGBiaW5kaW5ncz0ke0pTT04uc3RyaW5naWZ5KHtbYXR0ck5hbWVdOiBkZWJ1Z1ZhbHVlfSwgbnVsbCwgMil9YCk7XG4gICAgcmVuZGVyZXIuc2V0VmFsdWUoKGVsZW1lbnQgYXMgUkNvbW1lbnQpLCB0ZXh0Q29udGVudCk7XG4gIH1cbn1cblxuZXhwb3J0IGZ1bmN0aW9uIHNldE5nUmVmbGVjdFByb3BlcnRpZXMoXG4gICAgbFZpZXc6IExWaWV3LCBlbGVtZW50OiBSRWxlbWVudHxSQ29tbWVudCwgdHlwZTogVE5vZGVUeXBlLCBkYXRhVmFsdWU6IFByb3BlcnR5QWxpYXNWYWx1ZSxcbiAgICB2YWx1ZTogYW55KSB7XG4gIGlmICh0eXBlICYgKFROb2RlVHlwZS5BbnlSTm9kZSB8IFROb2RlVHlwZS5Db250YWluZXIpKSB7XG4gICAgLyoqXG4gICAgICogZGF0YVZhbHVlIGlzIGFuIGFycmF5IGNvbnRhaW5pbmcgcnVudGltZSBpbnB1dCBvciBvdXRwdXQgbmFtZXMgZm9yIHRoZSBkaXJlY3RpdmVzOlxuICAgICAqIGkrMDogZGlyZWN0aXZlIGluc3RhbmNlIGluZGV4XG4gICAgICogaSsxOiBwcml2YXRlTmFtZVxuICAgICAqXG4gICAgICogZS5nLiBbMCwgJ2NoYW5nZScsICdjaGFuZ2UtbWluaWZpZWQnXVxuICAgICAqIHdlIHdhbnQgdG8gc2V0IHRoZSByZWZsZWN0ZWQgcHJvcGVydHkgd2l0aCB0aGUgcHJpdmF0ZU5hbWU6IGRhdGFWYWx1ZVtpKzFdXG4gICAgICovXG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBkYXRhVmFsdWUubGVuZ3RoOyBpICs9IDIpIHtcbiAgICAgIHNldE5nUmVmbGVjdFByb3BlcnR5KGxWaWV3LCBlbGVtZW50LCB0eXBlLCBkYXRhVmFsdWVbaSArIDFdIGFzIHN0cmluZywgdmFsdWUpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIFJlc29sdmUgdGhlIG1hdGNoZWQgZGlyZWN0aXZlcyBvbiBhIG5vZGUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiByZXNvbHZlRGlyZWN0aXZlcyhcbiAgICB0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgdE5vZGU6IFRFbGVtZW50Tm9kZXxUQ29udGFpbmVyTm9kZXxURWxlbWVudENvbnRhaW5lck5vZGUsXG4gICAgbG9jYWxSZWZzOiBzdHJpbmdbXXxudWxsKTogdm9pZCB7XG4gIC8vIFBsZWFzZSBtYWtlIHN1cmUgdG8gaGF2ZSBleHBsaWNpdCB0eXBlIGZvciBgZXhwb3J0c01hcGAuIEluZmVycmVkIHR5cGUgdHJpZ2dlcnMgYnVnIGluXG4gIC8vIHRzaWNrbGUuXG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRGaXJzdENyZWF0ZVBhc3ModFZpZXcpO1xuXG4gIGlmIChnZXRCaW5kaW5nc0VuYWJsZWQoKSkge1xuICAgIGNvbnN0IGV4cG9ydHNNYXA6ICh7W2tleTogc3RyaW5nXTogbnVtYmVyfXxudWxsKSA9IGxvY2FsUmVmcyA9PT0gbnVsbCA/IG51bGwgOiB7Jyc6IC0xfTtcbiAgICBjb25zdCBtYXRjaFJlc3VsdCA9IGZpbmREaXJlY3RpdmVEZWZNYXRjaGVzKHRWaWV3LCB0Tm9kZSk7XG4gICAgbGV0IGRpcmVjdGl2ZURlZnM6IERpcmVjdGl2ZURlZjx1bmtub3duPltdfG51bGw7XG4gICAgbGV0IGhvc3REaXJlY3RpdmVEZWZzOiBIb3N0RGlyZWN0aXZlRGVmc3xudWxsO1xuXG4gICAgaWYgKG1hdGNoUmVzdWx0ID09PSBudWxsKSB7XG4gICAgICBkaXJlY3RpdmVEZWZzID0gaG9zdERpcmVjdGl2ZURlZnMgPSBudWxsO1xuICAgIH0gZWxzZSB7XG4gICAgICBbZGlyZWN0aXZlRGVmcywgaG9zdERpcmVjdGl2ZURlZnNdID0gbWF0Y2hSZXN1bHQ7XG4gICAgfVxuXG4gICAgaWYgKGRpcmVjdGl2ZURlZnMgIT09IG51bGwpIHtcbiAgICAgIGluaXRpYWxpemVEaXJlY3RpdmVzKHRWaWV3LCBsVmlldywgdE5vZGUsIGRpcmVjdGl2ZURlZnMsIGV4cG9ydHNNYXAsIGhvc3REaXJlY3RpdmVEZWZzKTtcbiAgICB9XG4gICAgaWYgKGV4cG9ydHNNYXApIGNhY2hlTWF0Y2hpbmdMb2NhbE5hbWVzKHROb2RlLCBsb2NhbFJlZnMsIGV4cG9ydHNNYXApO1xuICB9XG4gIC8vIE1lcmdlIHRoZSB0ZW1wbGF0ZSBhdHRycyBsYXN0IHNvIHRoYXQgdGhleSBoYXZlIHRoZSBoaWdoZXN0IHByaW9yaXR5LlxuICB0Tm9kZS5tZXJnZWRBdHRycyA9IG1lcmdlSG9zdEF0dHJzKHROb2RlLm1lcmdlZEF0dHJzLCB0Tm9kZS5hdHRycyk7XG59XG5cbi8qKiBJbml0aWFsaXplcyB0aGUgZGF0YSBzdHJ1Y3R1cmVzIG5lY2Vzc2FyeSBmb3IgYSBsaXN0IG9mIGRpcmVjdGl2ZXMgdG8gYmUgaW5zdGFudGlhdGVkLiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGluaXRpYWxpemVEaXJlY3RpdmVzKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3PHVua25vd24+LCB0Tm9kZTogVEVsZW1lbnROb2RlfFRDb250YWluZXJOb2RlfFRFbGVtZW50Q29udGFpbmVyTm9kZSxcbiAgICBkaXJlY3RpdmVzOiBEaXJlY3RpdmVEZWY8dW5rbm93bj5bXSwgZXhwb3J0c01hcDoge1trZXk6IHN0cmluZ106IG51bWJlcjt9fG51bGwsXG4gICAgaG9zdERpcmVjdGl2ZURlZnM6IEhvc3REaXJlY3RpdmVEZWZzfG51bGwpIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEZpcnN0Q3JlYXRlUGFzcyh0Vmlldyk7XG5cbiAgLy8gUHVibGlzaGVzIHRoZSBkaXJlY3RpdmUgdHlwZXMgdG8gREkgc28gdGhleSBjYW4gYmUgaW5qZWN0ZWQuIE5lZWRzIHRvXG4gIC8vIGhhcHBlbiBpbiBhIHNlcGFyYXRlIHBhc3MgYmVmb3JlIHRoZSBUTm9kZSBmbGFncyBoYXZlIGJlZW4gaW5pdGlhbGl6ZWQuXG4gIGZvciAobGV0IGkgPSAwOyBpIDwgZGlyZWN0aXZlcy5sZW5ndGg7IGkrKykge1xuICAgIGRpUHVibGljSW5JbmplY3RvcihnZXRPckNyZWF0ZU5vZGVJbmplY3RvckZvck5vZGUodE5vZGUsIGxWaWV3KSwgdFZpZXcsIGRpcmVjdGl2ZXNbaV0udHlwZSk7XG4gIH1cblxuICBpbml0VE5vZGVGbGFncyh0Tm9kZSwgdFZpZXcuZGF0YS5sZW5ndGgsIGRpcmVjdGl2ZXMubGVuZ3RoKTtcblxuICAvLyBXaGVuIHRoZSBzYW1lIHRva2VuIGlzIHByb3ZpZGVkIGJ5IHNldmVyYWwgZGlyZWN0aXZlcyBvbiB0aGUgc2FtZSBub2RlLCBzb21lIHJ1bGVzIGFwcGx5IGluXG4gIC8vIHRoZSB2aWV3RW5naW5lOlxuICAvLyAtIHZpZXdQcm92aWRlcnMgaGF2ZSBwcmlvcml0eSBvdmVyIHByb3ZpZGVyc1xuICAvLyAtIHRoZSBsYXN0IGRpcmVjdGl2ZSBpbiBOZ01vZHVsZS5kZWNsYXJhdGlvbnMgaGFzIHByaW9yaXR5IG92ZXIgdGhlIHByZXZpb3VzIG9uZVxuICAvLyBTbyB0byBtYXRjaCB0aGVzZSBydWxlcywgdGhlIG9yZGVyIGluIHdoaWNoIHByb3ZpZGVycyBhcmUgYWRkZWQgaW4gdGhlIGFycmF5cyBpcyB2ZXJ5XG4gIC8vIGltcG9ydGFudC5cbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBkaXJlY3RpdmVzLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgZGVmID0gZGlyZWN0aXZlc1tpXTtcbiAgICBpZiAoZGVmLnByb3ZpZGVyc1Jlc29sdmVyKSBkZWYucHJvdmlkZXJzUmVzb2x2ZXIoZGVmKTtcbiAgfVxuICBsZXQgcHJlT3JkZXJIb29rc0ZvdW5kID0gZmFsc2U7XG4gIGxldCBwcmVPcmRlckNoZWNrSG9va3NGb3VuZCA9IGZhbHNlO1xuICBsZXQgZGlyZWN0aXZlSWR4ID0gYWxsb2NFeHBhbmRvKHRWaWV3LCBsVmlldywgZGlyZWN0aXZlcy5sZW5ndGgsIG51bGwpO1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydFNhbWUoXG4gICAgICAgICAgZGlyZWN0aXZlSWR4LCB0Tm9kZS5kaXJlY3RpdmVTdGFydCxcbiAgICAgICAgICAnVE5vZGUuZGlyZWN0aXZlU3RhcnQgc2hvdWxkIHBvaW50IHRvIGp1c3QgYWxsb2NhdGVkIHNwYWNlJyk7XG5cbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBkaXJlY3RpdmVzLmxlbmd0aDsgaSsrKSB7XG4gICAgY29uc3QgZGVmID0gZGlyZWN0aXZlc1tpXTtcbiAgICAvLyBNZXJnZSB0aGUgYXR0cnMgaW4gdGhlIG9yZGVyIG9mIG1hdGNoZXMuIFRoaXMgYXNzdW1lcyB0aGF0IHRoZSBmaXJzdCBkaXJlY3RpdmUgaXMgdGhlXG4gICAgLy8gY29tcG9uZW50IGl0c2VsZiwgc28gdGhhdCB0aGUgY29tcG9uZW50IGhhcyB0aGUgbGVhc3QgcHJpb3JpdHkuXG4gICAgdE5vZGUubWVyZ2VkQXR0cnMgPSBtZXJnZUhvc3RBdHRycyh0Tm9kZS5tZXJnZWRBdHRycywgZGVmLmhvc3RBdHRycyk7XG5cbiAgICBjb25maWd1cmVWaWV3V2l0aERpcmVjdGl2ZSh0VmlldywgdE5vZGUsIGxWaWV3LCBkaXJlY3RpdmVJZHgsIGRlZik7XG4gICAgc2F2ZU5hbWVUb0V4cG9ydE1hcChkaXJlY3RpdmVJZHgsIGRlZiwgZXhwb3J0c01hcCk7XG5cbiAgICBpZiAoZGVmLmNvbnRlbnRRdWVyaWVzICE9PSBudWxsKSB0Tm9kZS5mbGFncyB8PSBUTm9kZUZsYWdzLmhhc0NvbnRlbnRRdWVyeTtcbiAgICBpZiAoZGVmLmhvc3RCaW5kaW5ncyAhPT0gbnVsbCB8fCBkZWYuaG9zdEF0dHJzICE9PSBudWxsIHx8IGRlZi5ob3N0VmFycyAhPT0gMClcbiAgICAgIHROb2RlLmZsYWdzIHw9IFROb2RlRmxhZ3MuaGFzSG9zdEJpbmRpbmdzO1xuXG4gICAgY29uc3QgbGlmZUN5Y2xlSG9va3M6IFBhcnRpYWw8T25DaGFuZ2VzJk9uSW5pdCZEb0NoZWNrPiA9IGRlZi50eXBlLnByb3RvdHlwZTtcbiAgICAvLyBPbmx5IHB1c2ggYSBub2RlIGluZGV4IGludG8gdGhlIHByZU9yZGVySG9va3MgYXJyYXkgaWYgdGhpcyBpcyB0aGUgZmlyc3RcbiAgICAvLyBwcmUtb3JkZXIgaG9vayBmb3VuZCBvbiB0aGlzIG5vZGUuXG4gICAgaWYgKCFwcmVPcmRlckhvb2tzRm91bmQgJiZcbiAgICAgICAgKGxpZmVDeWNsZUhvb2tzLm5nT25DaGFuZ2VzIHx8IGxpZmVDeWNsZUhvb2tzLm5nT25Jbml0IHx8IGxpZmVDeWNsZUhvb2tzLm5nRG9DaGVjaykpIHtcbiAgICAgIC8vIFdlIHdpbGwgcHVzaCB0aGUgYWN0dWFsIGhvb2sgZnVuY3Rpb24gaW50byB0aGlzIGFycmF5IGxhdGVyIGR1cmluZyBkaXIgaW5zdGFudGlhdGlvbi5cbiAgICAgIC8vIFdlIGNhbm5vdCBkbyBpdCBub3cgYmVjYXVzZSB3ZSBtdXN0IGVuc3VyZSBob29rcyBhcmUgcmVnaXN0ZXJlZCBpbiB0aGUgc2FtZVxuICAgICAgLy8gb3JkZXIgdGhhdCBkaXJlY3RpdmVzIGFyZSBjcmVhdGVkIChpLmUuIGluamVjdGlvbiBvcmRlcikuXG4gICAgICAodFZpZXcucHJlT3JkZXJIb29rcyA/Pz0gW10pLnB1c2godE5vZGUuaW5kZXgpO1xuICAgICAgcHJlT3JkZXJIb29rc0ZvdW5kID0gdHJ1ZTtcbiAgICB9XG5cbiAgICBpZiAoIXByZU9yZGVyQ2hlY2tIb29rc0ZvdW5kICYmIChsaWZlQ3ljbGVIb29rcy5uZ09uQ2hhbmdlcyB8fCBsaWZlQ3ljbGVIb29rcy5uZ0RvQ2hlY2spKSB7XG4gICAgICAodFZpZXcucHJlT3JkZXJDaGVja0hvb2tzID8/PSBbXSkucHVzaCh0Tm9kZS5pbmRleCk7XG4gICAgICBwcmVPcmRlckNoZWNrSG9va3NGb3VuZCA9IHRydWU7XG4gICAgfVxuXG4gICAgZGlyZWN0aXZlSWR4Kys7XG4gIH1cblxuICBpbml0aWFsaXplSW5wdXRBbmRPdXRwdXRBbGlhc2VzKHRWaWV3LCB0Tm9kZSwgaG9zdERpcmVjdGl2ZURlZnMpO1xufVxuXG4vKipcbiAqIEFkZCBgaG9zdEJpbmRpbmdzYCB0byB0aGUgYFRWaWV3Lmhvc3RCaW5kaW5nT3BDb2Rlc2AuXG4gKlxuICogQHBhcmFtIHRWaWV3IGBUVmlld2AgdG8gd2hpY2ggdGhlIGBob3N0QmluZGluZ3NgIHNob3VsZCBiZSBhZGRlZC5cbiAqIEBwYXJhbSB0Tm9kZSBgVE5vZGVgIHRoZSBlbGVtZW50IHdoaWNoIGNvbnRhaW5zIHRoZSBkaXJlY3RpdmVcbiAqIEBwYXJhbSBkaXJlY3RpdmVJZHggRGlyZWN0aXZlIGluZGV4IGluIHZpZXcuXG4gKiBAcGFyYW0gZGlyZWN0aXZlVmFyc0lkeCBXaGVyZSB3aWxsIHRoZSBkaXJlY3RpdmUncyB2YXJzIGJlIHN0b3JlZFxuICogQHBhcmFtIGRlZiBgQ29tcG9uZW50RGVmYC9gRGlyZWN0aXZlRGVmYCwgd2hpY2ggY29udGFpbnMgdGhlIGBob3N0VmFyc2AvYGhvc3RCaW5kaW5nc2AgdG8gYWRkLlxuICovXG5leHBvcnQgZnVuY3Rpb24gcmVnaXN0ZXJIb3N0QmluZGluZ09wQ29kZXMoXG4gICAgdFZpZXc6IFRWaWV3LCB0Tm9kZTogVE5vZGUsIGRpcmVjdGl2ZUlkeDogbnVtYmVyLCBkaXJlY3RpdmVWYXJzSWR4OiBudW1iZXIsXG4gICAgZGVmOiBDb21wb25lbnREZWY8YW55PnxEaXJlY3RpdmVEZWY8YW55Pik6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0Rmlyc3RDcmVhdGVQYXNzKHRWaWV3KTtcblxuICBjb25zdCBob3N0QmluZGluZ3MgPSBkZWYuaG9zdEJpbmRpbmdzO1xuICBpZiAoaG9zdEJpbmRpbmdzKSB7XG4gICAgbGV0IGhvc3RCaW5kaW5nT3BDb2RlcyA9IHRWaWV3Lmhvc3RCaW5kaW5nT3BDb2RlcztcbiAgICBpZiAoaG9zdEJpbmRpbmdPcENvZGVzID09PSBudWxsKSB7XG4gICAgICBob3N0QmluZGluZ09wQ29kZXMgPSB0Vmlldy5ob3N0QmluZGluZ09wQ29kZXMgPSBbXSBhcyBhbnkgYXMgSG9zdEJpbmRpbmdPcENvZGVzO1xuICAgIH1cbiAgICBjb25zdCBlbGVtZW50SW5keCA9IH50Tm9kZS5pbmRleDtcbiAgICBpZiAobGFzdFNlbGVjdGVkRWxlbWVudElkeChob3N0QmluZGluZ09wQ29kZXMpICE9IGVsZW1lbnRJbmR4KSB7XG4gICAgICAvLyBDb25kaXRpb25hbGx5IGFkZCBzZWxlY3QgZWxlbWVudCBzbyB0aGF0IHdlIGFyZSBtb3JlIGVmZmljaWVudCBpbiBleGVjdXRpb24uXG4gICAgICAvLyBOT1RFOiB0aGlzIGlzIHN0cmljdGx5IG5vdCBuZWNlc3NhcnkgYW5kIGl0IHRyYWRlcyBjb2RlIHNpemUgZm9yIHJ1bnRpbWUgcGVyZi5cbiAgICAgIC8vIChXZSBjb3VsZCBqdXN0IGFsd2F5cyBhZGQgaXQuKVxuICAgICAgaG9zdEJpbmRpbmdPcENvZGVzLnB1c2goZWxlbWVudEluZHgpO1xuICAgIH1cbiAgICBob3N0QmluZGluZ09wQ29kZXMucHVzaChkaXJlY3RpdmVJZHgsIGRpcmVjdGl2ZVZhcnNJZHgsIGhvc3RCaW5kaW5ncyk7XG4gIH1cbn1cblxuLyoqXG4gKiBSZXR1cm5zIHRoZSBsYXN0IHNlbGVjdGVkIGVsZW1lbnQgaW5kZXggaW4gdGhlIGBIb3N0QmluZGluZ09wQ29kZXNgXG4gKlxuICogRm9yIHBlcmYgcmVhc29ucyB3ZSBkb24ndCBuZWVkIHRvIHVwZGF0ZSB0aGUgc2VsZWN0ZWQgZWxlbWVudCBpbmRleCBpbiBgSG9zdEJpbmRpbmdPcENvZGVzYCBvbmx5XG4gKiBpZiBpdCBjaGFuZ2VzLiBUaGlzIG1ldGhvZCByZXR1cm5zIHRoZSBsYXN0IGluZGV4IChvciAnMCcgaWYgbm90IGZvdW5kLilcbiAqXG4gKiBTZWxlY3RlZCBlbGVtZW50IGluZGV4IGFyZSBvbmx5IHRoZSBvbmVzIHdoaWNoIGFyZSBuZWdhdGl2ZS5cbiAqL1xuZnVuY3Rpb24gbGFzdFNlbGVjdGVkRWxlbWVudElkeChob3N0QmluZGluZ09wQ29kZXM6IEhvc3RCaW5kaW5nT3BDb2Rlcyk6IG51bWJlciB7XG4gIGxldCBpID0gaG9zdEJpbmRpbmdPcENvZGVzLmxlbmd0aDtcbiAgd2hpbGUgKGkgPiAwKSB7XG4gICAgY29uc3QgdmFsdWUgPSBob3N0QmluZGluZ09wQ29kZXNbLS1pXTtcbiAgICBpZiAodHlwZW9mIHZhbHVlID09PSAnbnVtYmVyJyAmJiB2YWx1ZSA8IDApIHtcbiAgICAgIHJldHVybiB2YWx1ZTtcbiAgICB9XG4gIH1cbiAgcmV0dXJuIDA7XG59XG5cblxuLyoqXG4gKiBJbnN0YW50aWF0ZSBhbGwgdGhlIGRpcmVjdGl2ZXMgdGhhdCB3ZXJlIHByZXZpb3VzbHkgcmVzb2x2ZWQgb24gdGhlIGN1cnJlbnQgbm9kZS5cbiAqL1xuZnVuY3Rpb24gaW5zdGFudGlhdGVBbGxEaXJlY3RpdmVzKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCB0Tm9kZTogVERpcmVjdGl2ZUhvc3ROb2RlLCBuYXRpdmU6IFJOb2RlKSB7XG4gIGNvbnN0IHN0YXJ0ID0gdE5vZGUuZGlyZWN0aXZlU3RhcnQ7XG4gIGNvbnN0IGVuZCA9IHROb2RlLmRpcmVjdGl2ZUVuZDtcblxuICAvLyBUaGUgY29tcG9uZW50IHZpZXcgbmVlZHMgdG8gYmUgY3JlYXRlZCBiZWZvcmUgY3JlYXRpbmcgdGhlIG5vZGUgaW5qZWN0b3JcbiAgLy8gc2luY2UgaXQgaXMgdXNlZCB0byBpbmplY3Qgc29tZSBzcGVjaWFsIHN5bWJvbHMgbGlrZSBgQ2hhbmdlRGV0ZWN0b3JSZWZgLlxuICBpZiAoaXNDb21wb25lbnRIb3N0KHROb2RlKSkge1xuICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRUTm9kZVR5cGUodE5vZGUsIFROb2RlVHlwZS5BbnlSTm9kZSk7XG4gICAgYWRkQ29tcG9uZW50TG9naWMoXG4gICAgICAgIGxWaWV3LCB0Tm9kZSBhcyBURWxlbWVudE5vZGUsXG4gICAgICAgIHRWaWV3LmRhdGFbc3RhcnQgKyB0Tm9kZS5jb21wb25lbnRPZmZzZXRdIGFzIENvbXBvbmVudERlZjx1bmtub3duPik7XG4gIH1cblxuICBpZiAoIXRWaWV3LmZpcnN0Q3JlYXRlUGFzcykge1xuICAgIGdldE9yQ3JlYXRlTm9kZUluamVjdG9yRm9yTm9kZSh0Tm9kZSwgbFZpZXcpO1xuICB9XG5cbiAgYXR0YWNoUGF0Y2hEYXRhKG5hdGl2ZSwgbFZpZXcpO1xuXG4gIGNvbnN0IGluaXRpYWxJbnB1dHMgPSB0Tm9kZS5pbml0aWFsSW5wdXRzO1xuICBmb3IgKGxldCBpID0gc3RhcnQ7IGkgPCBlbmQ7IGkrKykge1xuICAgIGNvbnN0IGRlZiA9IHRWaWV3LmRhdGFbaV0gYXMgRGlyZWN0aXZlRGVmPGFueT47XG4gICAgY29uc3QgZGlyZWN0aXZlID0gZ2V0Tm9kZUluamVjdGFibGUobFZpZXcsIHRWaWV3LCBpLCB0Tm9kZSk7XG4gICAgYXR0YWNoUGF0Y2hEYXRhKGRpcmVjdGl2ZSwgbFZpZXcpO1xuXG4gICAgaWYgKGluaXRpYWxJbnB1dHMgIT09IG51bGwpIHtcbiAgICAgIHNldElucHV0c0Zyb21BdHRycyhsVmlldywgaSAtIHN0YXJ0LCBkaXJlY3RpdmUsIGRlZiwgdE5vZGUsIGluaXRpYWxJbnB1dHMhKTtcbiAgICB9XG5cbiAgICBpZiAoaXNDb21wb25lbnREZWYoZGVmKSkge1xuICAgICAgY29uc3QgY29tcG9uZW50VmlldyA9IGdldENvbXBvbmVudExWaWV3QnlJbmRleCh0Tm9kZS5pbmRleCwgbFZpZXcpO1xuICAgICAgY29tcG9uZW50Vmlld1tDT05URVhUXSA9IGdldE5vZGVJbmplY3RhYmxlKGxWaWV3LCB0VmlldywgaSwgdE5vZGUpO1xuICAgIH1cbiAgfVxufVxuXG5leHBvcnQgZnVuY3Rpb24gaW52b2tlRGlyZWN0aXZlc0hvc3RCaW5kaW5ncyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldywgdE5vZGU6IFROb2RlKSB7XG4gIGNvbnN0IHN0YXJ0ID0gdE5vZGUuZGlyZWN0aXZlU3RhcnQ7XG4gIGNvbnN0IGVuZCA9IHROb2RlLmRpcmVjdGl2ZUVuZDtcbiAgY29uc3QgZWxlbWVudEluZGV4ID0gdE5vZGUuaW5kZXg7XG4gIGNvbnN0IGN1cnJlbnREaXJlY3RpdmVJbmRleCA9IGdldEN1cnJlbnREaXJlY3RpdmVJbmRleCgpO1xuICB0cnkge1xuICAgIHNldFNlbGVjdGVkSW5kZXgoZWxlbWVudEluZGV4KTtcbiAgICBmb3IgKGxldCBkaXJJbmRleCA9IHN0YXJ0OyBkaXJJbmRleCA8IGVuZDsgZGlySW5kZXgrKykge1xuICAgICAgY29uc3QgZGVmID0gdFZpZXcuZGF0YVtkaXJJbmRleF0gYXMgRGlyZWN0aXZlRGVmPHVua25vd24+O1xuICAgICAgY29uc3QgZGlyZWN0aXZlID0gbFZpZXdbZGlySW5kZXhdO1xuICAgICAgc2V0Q3VycmVudERpcmVjdGl2ZUluZGV4KGRpckluZGV4KTtcbiAgICAgIGlmIChkZWYuaG9zdEJpbmRpbmdzICE9PSBudWxsIHx8IGRlZi5ob3N0VmFycyAhPT0gMCB8fCBkZWYuaG9zdEF0dHJzICE9PSBudWxsKSB7XG4gICAgICAgIGludm9rZUhvc3RCaW5kaW5nc0luQ3JlYXRpb25Nb2RlKGRlZiwgZGlyZWN0aXZlKTtcbiAgICAgIH1cbiAgICB9XG4gIH0gZmluYWxseSB7XG4gICAgc2V0U2VsZWN0ZWRJbmRleCgtMSk7XG4gICAgc2V0Q3VycmVudERpcmVjdGl2ZUluZGV4KGN1cnJlbnREaXJlY3RpdmVJbmRleCk7XG4gIH1cbn1cblxuLyoqXG4gKiBJbnZva2UgdGhlIGhvc3QgYmluZGluZ3MgaW4gY3JlYXRpb24gbW9kZS5cbiAqXG4gKiBAcGFyYW0gZGVmIGBEaXJlY3RpdmVEZWZgIHdoaWNoIG1heSBjb250YWluIHRoZSBgaG9zdEJpbmRpbmdzYCBmdW5jdGlvbi5cbiAqIEBwYXJhbSBkaXJlY3RpdmUgSW5zdGFuY2Ugb2YgZGlyZWN0aXZlLlxuICovXG5leHBvcnQgZnVuY3Rpb24gaW52b2tlSG9zdEJpbmRpbmdzSW5DcmVhdGlvbk1vZGUoZGVmOiBEaXJlY3RpdmVEZWY8YW55PiwgZGlyZWN0aXZlOiBhbnkpIHtcbiAgaWYgKGRlZi5ob3N0QmluZGluZ3MgIT09IG51bGwpIHtcbiAgICBkZWYuaG9zdEJpbmRpbmdzIShSZW5kZXJGbGFncy5DcmVhdGUsIGRpcmVjdGl2ZSk7XG4gIH1cbn1cblxuLyoqXG4gKiBNYXRjaGVzIHRoZSBjdXJyZW50IG5vZGUgYWdhaW5zdCBhbGwgYXZhaWxhYmxlIHNlbGVjdG9ycy5cbiAqIElmIGEgY29tcG9uZW50IGlzIG1hdGNoZWQgKGF0IG1vc3Qgb25lKSwgaXQgaXMgcmV0dXJuZWQgaW4gZmlyc3QgcG9zaXRpb24gaW4gdGhlIGFycmF5LlxuICovXG5mdW5jdGlvbiBmaW5kRGlyZWN0aXZlRGVmTWF0Y2hlcyhcbiAgICB0VmlldzogVFZpZXcsIHROb2RlOiBURWxlbWVudE5vZGV8VENvbnRhaW5lck5vZGV8VEVsZW1lbnRDb250YWluZXJOb2RlKTpcbiAgICBbbWF0Y2hlczogRGlyZWN0aXZlRGVmPHVua25vd24+W10sIGhvc3REaXJlY3RpdmVEZWZzOiBIb3N0RGlyZWN0aXZlRGVmc3xudWxsXXxudWxsIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEZpcnN0Q3JlYXRlUGFzcyh0Vmlldyk7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRUTm9kZVR5cGUodE5vZGUsIFROb2RlVHlwZS5BbnlSTm9kZSB8IFROb2RlVHlwZS5BbnlDb250YWluZXIpO1xuXG4gIGNvbnN0IHJlZ2lzdHJ5ID0gdFZpZXcuZGlyZWN0aXZlUmVnaXN0cnk7XG4gIGxldCBtYXRjaGVzOiBEaXJlY3RpdmVEZWY8dW5rbm93bj5bXXxudWxsID0gbnVsbDtcbiAgbGV0IGhvc3REaXJlY3RpdmVEZWZzOiBIb3N0RGlyZWN0aXZlRGVmc3xudWxsID0gbnVsbDtcbiAgaWYgKHJlZ2lzdHJ5KSB7XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCByZWdpc3RyeS5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3QgZGVmID0gcmVnaXN0cnlbaV0gYXMgQ29tcG9uZW50RGVmPGFueT58IERpcmVjdGl2ZURlZjxhbnk+O1xuICAgICAgaWYgKGlzTm9kZU1hdGNoaW5nU2VsZWN0b3JMaXN0KHROb2RlLCBkZWYuc2VsZWN0b3JzISwgLyogaXNQcm9qZWN0aW9uTW9kZSAqLyBmYWxzZSkpIHtcbiAgICAgICAgbWF0Y2hlcyB8fCAobWF0Y2hlcyA9IFtdKTtcblxuICAgICAgICBpZiAoaXNDb21wb25lbnREZWYoZGVmKSkge1xuICAgICAgICAgIGlmIChuZ0Rldk1vZGUpIHtcbiAgICAgICAgICAgIGFzc2VydFROb2RlVHlwZShcbiAgICAgICAgICAgICAgICB0Tm9kZSwgVE5vZGVUeXBlLkVsZW1lbnQsXG4gICAgICAgICAgICAgICAgYFwiJHt0Tm9kZS52YWx1ZX1cIiB0YWdzIGNhbm5vdCBiZSB1c2VkIGFzIGNvbXBvbmVudCBob3N0cy4gYCArXG4gICAgICAgICAgICAgICAgICAgIGBQbGVhc2UgdXNlIGEgZGlmZmVyZW50IHRhZyB0byBhY3RpdmF0ZSB0aGUgJHtzdHJpbmdpZnkoZGVmLnR5cGUpfSBjb21wb25lbnQuYCk7XG5cbiAgICAgICAgICAgIGlmIChpc0NvbXBvbmVudEhvc3QodE5vZGUpKSB7XG4gICAgICAgICAgICAgIHRocm93TXVsdGlwbGVDb21wb25lbnRFcnJvcih0Tm9kZSwgbWF0Y2hlcy5maW5kKGlzQ29tcG9uZW50RGVmKSEudHlwZSwgZGVmLnR5cGUpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIENvbXBvbmVudHMgYXJlIGluc2VydGVkIGF0IHRoZSBmcm9udCBvZiB0aGUgbWF0Y2hlcyBhcnJheSBzbyB0aGF0IHRoZWlyIGxpZmVjeWNsZVxuICAgICAgICAgIC8vIGhvb2tzIHJ1biBiZWZvcmUgYW55IGRpcmVjdGl2ZSBsaWZlY3ljbGUgaG9va3MuIFRoaXMgYXBwZWFycyB0byBiZSBmb3IgVmlld0VuZ2luZVxuICAgICAgICAgIC8vIGNvbXBhdGliaWxpdHkuIFRoaXMgbG9naWMgZG9lc24ndCBtYWtlIHNlbnNlIHdpdGggaG9zdCBkaXJlY3RpdmVzLCBiZWNhdXNlIGl0XG4gICAgICAgICAgLy8gd291bGQgYWxsb3cgdGhlIGhvc3QgZGlyZWN0aXZlcyB0byB1bmRvIGFueSBvdmVycmlkZXMgdGhlIGhvc3QgbWF5IGhhdmUgbWFkZS5cbiAgICAgICAgICAvLyBUbyBoYW5kbGUgdGhpcyBjYXNlLCB0aGUgaG9zdCBkaXJlY3RpdmVzIG9mIGNvbXBvbmVudHMgYXJlIGluc2VydGVkIGF0IHRoZSBiZWdpbm5pbmdcbiAgICAgICAgICAvLyBvZiB0aGUgYXJyYXksIGZvbGxvd2VkIGJ5IHRoZSBjb21wb25lbnQuIEFzIHN1Y2gsIHRoZSBpbnNlcnRpb24gb3JkZXIgaXMgYXMgZm9sbG93czpcbiAgICAgICAgICAvLyAxLiBIb3N0IGRpcmVjdGl2ZXMgYmVsb25naW5nIHRvIHRoZSBzZWxlY3Rvci1tYXRjaGVkIGNvbXBvbmVudC5cbiAgICAgICAgICAvLyAyLiBTZWxlY3Rvci1tYXRjaGVkIGNvbXBvbmVudC5cbiAgICAgICAgICAvLyAzLiBIb3N0IGRpcmVjdGl2ZXMgYmVsb25naW5nIHRvIHNlbGVjdG9yLW1hdGNoZWQgZGlyZWN0aXZlcy5cbiAgICAgICAgICAvLyA0LiBTZWxlY3Rvci1tYXRjaGVkIGRpcmVjdGl2ZXMuXG4gICAgICAgICAgaWYgKGRlZi5maW5kSG9zdERpcmVjdGl2ZURlZnMgIT09IG51bGwpIHtcbiAgICAgICAgICAgIGNvbnN0IGhvc3REaXJlY3RpdmVNYXRjaGVzOiBEaXJlY3RpdmVEZWY8dW5rbm93bj5bXSA9IFtdO1xuICAgICAgICAgICAgaG9zdERpcmVjdGl2ZURlZnMgPSBob3N0RGlyZWN0aXZlRGVmcyB8fCBuZXcgTWFwKCk7XG4gICAgICAgICAgICBkZWYuZmluZEhvc3REaXJlY3RpdmVEZWZzKGRlZiwgaG9zdERpcmVjdGl2ZU1hdGNoZXMsIGhvc3REaXJlY3RpdmVEZWZzKTtcbiAgICAgICAgICAgIC8vIEFkZCBhbGwgaG9zdCBkaXJlY3RpdmVzIGRlY2xhcmVkIG9uIHRoaXMgY29tcG9uZW50LCBmb2xsb3dlZCBieSB0aGUgY29tcG9uZW50IGl0c2VsZi5cbiAgICAgICAgICAgIC8vIEhvc3QgZGlyZWN0aXZlcyBzaG91bGQgZXhlY3V0ZSBmaXJzdCBzbyB0aGUgaG9zdCBoYXMgYSBjaGFuY2UgdG8gb3ZlcnJpZGUgY2hhbmdlc1xuICAgICAgICAgICAgLy8gdG8gdGhlIERPTSBtYWRlIGJ5IHRoZW0uXG4gICAgICAgICAgICBtYXRjaGVzLnVuc2hpZnQoLi4uaG9zdERpcmVjdGl2ZU1hdGNoZXMsIGRlZik7XG4gICAgICAgICAgICAvLyBDb21wb25lbnQgaXMgb2Zmc2V0IHN0YXJ0aW5nIGZyb20gdGhlIGJlZ2lubmluZyBvZiB0aGUgaG9zdCBkaXJlY3RpdmVzIGFycmF5LlxuICAgICAgICAgICAgY29uc3QgY29tcG9uZW50T2Zmc2V0ID0gaG9zdERpcmVjdGl2ZU1hdGNoZXMubGVuZ3RoO1xuICAgICAgICAgICAgbWFya0FzQ29tcG9uZW50SG9zdCh0VmlldywgdE5vZGUsIGNvbXBvbmVudE9mZnNldCk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIC8vIE5vIGhvc3QgZGlyZWN0aXZlcyBvbiB0aGlzIGNvbXBvbmVudCwganVzdCBhZGQgdGhlXG4gICAgICAgICAgICAvLyBjb21wb25lbnQgZGVmIHRvIHRoZSBiZWdpbm5pbmcgb2YgdGhlIG1hdGNoZXMuXG4gICAgICAgICAgICBtYXRjaGVzLnVuc2hpZnQoZGVmKTtcbiAgICAgICAgICAgIG1hcmtBc0NvbXBvbmVudEhvc3QodFZpZXcsIHROb2RlLCAwKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gQXBwZW5kIGFueSBob3N0IGRpcmVjdGl2ZXMgdG8gdGhlIG1hdGNoZXMgZmlyc3QuXG4gICAgICAgICAgaG9zdERpcmVjdGl2ZURlZnMgPSBob3N0RGlyZWN0aXZlRGVmcyB8fCBuZXcgTWFwKCk7XG4gICAgICAgICAgZGVmLmZpbmRIb3N0RGlyZWN0aXZlRGVmcz8uKGRlZiwgbWF0Y2hlcywgaG9zdERpcmVjdGl2ZURlZnMpO1xuICAgICAgICAgIG1hdGNoZXMucHVzaChkZWYpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuICB9XG4gIHJldHVybiBtYXRjaGVzID09PSBudWxsID8gbnVsbCA6IFttYXRjaGVzLCBob3N0RGlyZWN0aXZlRGVmc107XG59XG5cbi8qKlxuICogTWFya3MgYSBnaXZlbiBUTm9kZSBhcyBhIGNvbXBvbmVudCdzIGhvc3QuIFRoaXMgY29uc2lzdHMgb2Y6XG4gKiAtIHNldHRpbmcgdGhlIGNvbXBvbmVudCBvZmZzZXQgb24gdGhlIFROb2RlLlxuICogLSBzdG9yaW5nIGluZGV4IG9mIGNvbXBvbmVudCdzIGhvc3QgZWxlbWVudCBzbyBpdCB3aWxsIGJlIHF1ZXVlZCBmb3IgdmlldyByZWZyZXNoIGR1cmluZyBDRC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIG1hcmtBc0NvbXBvbmVudEhvc3QodFZpZXc6IFRWaWV3LCBob3N0VE5vZGU6IFROb2RlLCBjb21wb25lbnRPZmZzZXQ6IG51bWJlcik6IHZvaWQge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0Rmlyc3RDcmVhdGVQYXNzKHRWaWV3KTtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEdyZWF0ZXJUaGFuKGNvbXBvbmVudE9mZnNldCwgLTEsICdjb21wb25lbnRPZmZzZXQgbXVzdCBiZSBncmVhdCB0aGFuIC0xJyk7XG4gIGhvc3RUTm9kZS5jb21wb25lbnRPZmZzZXQgPSBjb21wb25lbnRPZmZzZXQ7XG4gICh0Vmlldy5jb21wb25lbnRzID8/PSBbXSkucHVzaChob3N0VE5vZGUuaW5kZXgpO1xufVxuXG4vKiogQ2FjaGVzIGxvY2FsIG5hbWVzIGFuZCB0aGVpciBtYXRjaGluZyBkaXJlY3RpdmUgaW5kaWNlcyBmb3IgcXVlcnkgYW5kIHRlbXBsYXRlIGxvb2t1cHMuICovXG5mdW5jdGlvbiBjYWNoZU1hdGNoaW5nTG9jYWxOYW1lcyhcbiAgICB0Tm9kZTogVE5vZGUsIGxvY2FsUmVmczogc3RyaW5nW118bnVsbCwgZXhwb3J0c01hcDoge1trZXk6IHN0cmluZ106IG51bWJlcn0pOiB2b2lkIHtcbiAgaWYgKGxvY2FsUmVmcykge1xuICAgIGNvbnN0IGxvY2FsTmFtZXM6IChzdHJpbmd8bnVtYmVyKVtdID0gdE5vZGUubG9jYWxOYW1lcyA9IFtdO1xuXG4gICAgLy8gTG9jYWwgbmFtZXMgbXVzdCBiZSBzdG9yZWQgaW4gdE5vZGUgaW4gdGhlIHNhbWUgb3JkZXIgdGhhdCBsb2NhbFJlZnMgYXJlIGRlZmluZWRcbiAgICAvLyBpbiB0aGUgdGVtcGxhdGUgdG8gZW5zdXJlIHRoZSBkYXRhIGlzIGxvYWRlZCBpbiB0aGUgc2FtZSBzbG90cyBhcyB0aGVpciByZWZzXG4gICAgLy8gaW4gdGhlIHRlbXBsYXRlIChmb3IgdGVtcGxhdGUgcXVlcmllcykuXG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBsb2NhbFJlZnMubGVuZ3RoOyBpICs9IDIpIHtcbiAgICAgIGNvbnN0IGluZGV4ID0gZXhwb3J0c01hcFtsb2NhbFJlZnNbaSArIDFdXTtcbiAgICAgIGlmIChpbmRleCA9PSBudWxsKVxuICAgICAgICB0aHJvdyBuZXcgUnVudGltZUVycm9yKFxuICAgICAgICAgICAgUnVudGltZUVycm9yQ29kZS5FWFBPUlRfTk9UX0ZPVU5ELFxuICAgICAgICAgICAgbmdEZXZNb2RlICYmIGBFeHBvcnQgb2YgbmFtZSAnJHtsb2NhbFJlZnNbaSArIDFdfScgbm90IGZvdW5kIWApO1xuICAgICAgbG9jYWxOYW1lcy5wdXNoKGxvY2FsUmVmc1tpXSwgaW5kZXgpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEJ1aWxkcyB1cCBhbiBleHBvcnQgbWFwIGFzIGRpcmVjdGl2ZXMgYXJlIGNyZWF0ZWQsIHNvIGxvY2FsIHJlZnMgY2FuIGJlIHF1aWNrbHkgbWFwcGVkXG4gKiB0byB0aGVpciBkaXJlY3RpdmUgaW5zdGFuY2VzLlxuICovXG5mdW5jdGlvbiBzYXZlTmFtZVRvRXhwb3J0TWFwKFxuICAgIGRpcmVjdGl2ZUlkeDogbnVtYmVyLCBkZWY6IERpcmVjdGl2ZURlZjxhbnk+fENvbXBvbmVudERlZjxhbnk+LFxuICAgIGV4cG9ydHNNYXA6IHtba2V5OiBzdHJpbmddOiBudW1iZXJ9fG51bGwpIHtcbiAgaWYgKGV4cG9ydHNNYXApIHtcbiAgICBpZiAoZGVmLmV4cG9ydEFzKSB7XG4gICAgICBmb3IgKGxldCBpID0gMDsgaSA8IGRlZi5leHBvcnRBcy5sZW5ndGg7IGkrKykge1xuICAgICAgICBleHBvcnRzTWFwW2RlZi5leHBvcnRBc1tpXV0gPSBkaXJlY3RpdmVJZHg7XG4gICAgICB9XG4gICAgfVxuICAgIGlmIChpc0NvbXBvbmVudERlZihkZWYpKSBleHBvcnRzTWFwWycnXSA9IGRpcmVjdGl2ZUlkeDtcbiAgfVxufVxuXG4vKipcbiAqIEluaXRpYWxpemVzIHRoZSBmbGFncyBvbiB0aGUgY3VycmVudCBub2RlLCBzZXR0aW5nIGFsbCBpbmRpY2VzIHRvIHRoZSBpbml0aWFsIGluZGV4LFxuICogdGhlIGRpcmVjdGl2ZSBjb3VudCB0byAwLCBhbmQgYWRkaW5nIHRoZSBpc0NvbXBvbmVudCBmbGFnLlxuICogQHBhcmFtIGluZGV4IHRoZSBpbml0aWFsIGluZGV4XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpbml0VE5vZGVGbGFncyh0Tm9kZTogVE5vZGUsIGluZGV4OiBudW1iZXIsIG51bWJlck9mRGlyZWN0aXZlczogbnVtYmVyKSB7XG4gIG5nRGV2TW9kZSAmJlxuICAgICAgYXNzZXJ0Tm90RXF1YWwoXG4gICAgICAgICAgbnVtYmVyT2ZEaXJlY3RpdmVzLCB0Tm9kZS5kaXJlY3RpdmVFbmQgLSB0Tm9kZS5kaXJlY3RpdmVTdGFydCxcbiAgICAgICAgICAnUmVhY2hlZCB0aGUgbWF4IG51bWJlciBvZiBkaXJlY3RpdmVzJyk7XG4gIHROb2RlLmZsYWdzIHw9IFROb2RlRmxhZ3MuaXNEaXJlY3RpdmVIb3N0O1xuICAvLyBXaGVuIHRoZSBmaXJzdCBkaXJlY3RpdmUgaXMgY3JlYXRlZCBvbiBhIG5vZGUsIHNhdmUgdGhlIGluZGV4XG4gIHROb2RlLmRpcmVjdGl2ZVN0YXJ0ID0gaW5kZXg7XG4gIHROb2RlLmRpcmVjdGl2ZUVuZCA9IGluZGV4ICsgbnVtYmVyT2ZEaXJlY3RpdmVzO1xuICB0Tm9kZS5wcm92aWRlckluZGV4ZXMgPSBpbmRleDtcbn1cblxuLyoqXG4gKiBTZXR1cCBkaXJlY3RpdmUgZm9yIGluc3RhbnRpYXRpb24uXG4gKlxuICogV2UgbmVlZCB0byBjcmVhdGUgYSBgTm9kZUluamVjdG9yRmFjdG9yeWAgd2hpY2ggaXMgdGhlbiBpbnNlcnRlZCBpbiBib3RoIHRoZSBgQmx1ZXByaW50YCBhcyB3ZWxsXG4gKiBhcyBgTFZpZXdgLiBgVFZpZXdgIGdldHMgdGhlIGBEaXJlY3RpdmVEZWZgLlxuICpcbiAqIEBwYXJhbSB0VmlldyBgVFZpZXdgXG4gKiBAcGFyYW0gdE5vZGUgYFROb2RlYFxuICogQHBhcmFtIGxWaWV3IGBMVmlld2BcbiAqIEBwYXJhbSBkaXJlY3RpdmVJbmRleCBJbmRleCB3aGVyZSB0aGUgZGlyZWN0aXZlIHdpbGwgYmUgc3RvcmVkIGluIHRoZSBFeHBhbmRvLlxuICogQHBhcmFtIGRlZiBgRGlyZWN0aXZlRGVmYFxuICovXG5leHBvcnQgZnVuY3Rpb24gY29uZmlndXJlVmlld1dpdGhEaXJlY3RpdmU8VD4oXG4gICAgdFZpZXc6IFRWaWV3LCB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldywgZGlyZWN0aXZlSW5kZXg6IG51bWJlciwgZGVmOiBEaXJlY3RpdmVEZWY8VD4pOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmXG4gICAgICBhc3NlcnRHcmVhdGVyVGhhbk9yRXF1YWwoZGlyZWN0aXZlSW5kZXgsIEhFQURFUl9PRkZTRVQsICdNdXN0IGJlIGluIEV4cGFuZG8gc2VjdGlvbicpO1xuICB0Vmlldy5kYXRhW2RpcmVjdGl2ZUluZGV4XSA9IGRlZjtcbiAgY29uc3QgZGlyZWN0aXZlRmFjdG9yeSA9XG4gICAgICBkZWYuZmFjdG9yeSB8fCAoKGRlZiBhcyB7ZmFjdG9yeTogRnVuY3Rpb259KS5mYWN0b3J5ID0gZ2V0RmFjdG9yeURlZihkZWYudHlwZSwgdHJ1ZSkpO1xuICAvLyBFdmVuIHRob3VnaCBgZGlyZWN0aXZlRmFjdG9yeWAgd2lsbCBhbHJlYWR5IGJlIHVzaW5nIGDJtcm1ZGlyZWN0aXZlSW5qZWN0YCBpbiBpdHMgZ2VuZXJhdGVkIGNvZGUsXG4gIC8vIHdlIGFsc28gd2FudCB0byBzdXBwb3J0IGBpbmplY3QoKWAgZGlyZWN0bHkgZnJvbSB0aGUgZGlyZWN0aXZlIGNvbnN0cnVjdG9yIGNvbnRleHQgc28gd2Ugc2V0XG4gIC8vIGDJtcm1ZGlyZWN0aXZlSW5qZWN0YCBhcyB0aGUgaW5qZWN0IGltcGxlbWVudGF0aW9uIGhlcmUgdG9vLlxuICBjb25zdCBub2RlSW5qZWN0b3JGYWN0b3J5ID1cbiAgICAgIG5ldyBOb2RlSW5qZWN0b3JGYWN0b3J5KGRpcmVjdGl2ZUZhY3RvcnksIGlzQ29tcG9uZW50RGVmKGRlZiksIMm1ybVkaXJlY3RpdmVJbmplY3QpO1xuICB0Vmlldy5ibHVlcHJpbnRbZGlyZWN0aXZlSW5kZXhdID0gbm9kZUluamVjdG9yRmFjdG9yeTtcbiAgbFZpZXdbZGlyZWN0aXZlSW5kZXhdID0gbm9kZUluamVjdG9yRmFjdG9yeTtcblxuICByZWdpc3Rlckhvc3RCaW5kaW5nT3BDb2RlcyhcbiAgICAgIHRWaWV3LCB0Tm9kZSwgZGlyZWN0aXZlSW5kZXgsIGFsbG9jRXhwYW5kbyh0VmlldywgbFZpZXcsIGRlZi5ob3N0VmFycywgTk9fQ0hBTkdFKSwgZGVmKTtcbn1cblxuZnVuY3Rpb24gYWRkQ29tcG9uZW50TG9naWM8VD4obFZpZXc6IExWaWV3LCBob3N0VE5vZGU6IFRFbGVtZW50Tm9kZSwgZGVmOiBDb21wb25lbnREZWY8VD4pOiB2b2lkIHtcbiAgY29uc3QgbmF0aXZlID0gZ2V0TmF0aXZlQnlUTm9kZShob3N0VE5vZGUsIGxWaWV3KSBhcyBSRWxlbWVudDtcbiAgY29uc3QgdFZpZXcgPSBnZXRPckNyZWF0ZUNvbXBvbmVudFRWaWV3KGRlZik7XG5cbiAgLy8gT25seSBjb21wb25lbnQgdmlld3Mgc2hvdWxkIGJlIGFkZGVkIHRvIHRoZSB2aWV3IHRyZWUgZGlyZWN0bHkuIEVtYmVkZGVkIHZpZXdzIGFyZVxuICAvLyBhY2Nlc3NlZCB0aHJvdWdoIHRoZWlyIGNvbnRhaW5lcnMgYmVjYXVzZSB0aGV5IG1heSBiZSByZW1vdmVkIC8gcmUtYWRkZWQgbGF0ZXIuXG4gIGNvbnN0IHJlbmRlcmVyRmFjdG9yeSA9IGxWaWV3W0VOVklST05NRU5UXS5yZW5kZXJlckZhY3Rvcnk7XG4gIGNvbnN0IGNvbXBvbmVudFZpZXcgPSBhZGRUb1ZpZXdUcmVlKFxuICAgICAgbFZpZXcsXG4gICAgICBjcmVhdGVMVmlldyhcbiAgICAgICAgICBsVmlldywgdFZpZXcsIG51bGwsIGRlZi5vblB1c2ggPyBMVmlld0ZsYWdzLkRpcnR5IDogTFZpZXdGbGFncy5DaGVja0Fsd2F5cywgbmF0aXZlLFxuICAgICAgICAgIGhvc3RUTm9kZSBhcyBURWxlbWVudE5vZGUsIG51bGwsIHJlbmRlcmVyRmFjdG9yeS5jcmVhdGVSZW5kZXJlcihuYXRpdmUsIGRlZiksIG51bGwsIG51bGwsXG4gICAgICAgICAgbnVsbCkpO1xuXG4gIC8vIENvbXBvbmVudCB2aWV3IHdpbGwgYWx3YXlzIGJlIGNyZWF0ZWQgYmVmb3JlIGFueSBpbmplY3RlZCBMQ29udGFpbmVycyxcbiAgLy8gc28gdGhpcyBpcyBhIHJlZ3VsYXIgZWxlbWVudCwgd3JhcCBpdCB3aXRoIHRoZSBjb21wb25lbnQgdmlld1xuICBsVmlld1tob3N0VE5vZGUuaW5kZXhdID0gY29tcG9uZW50Vmlldztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGVsZW1lbnRBdHRyaWJ1dGVJbnRlcm5hbChcbiAgICB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldywgbmFtZTogc3RyaW5nLCB2YWx1ZTogYW55LCBzYW5pdGl6ZXI6IFNhbml0aXplckZufG51bGx8dW5kZWZpbmVkLFxuICAgIG5hbWVzcGFjZTogc3RyaW5nfG51bGx8dW5kZWZpbmVkKSB7XG4gIGlmIChuZ0Rldk1vZGUpIHtcbiAgICBhc3NlcnROb3RTYW1lKHZhbHVlLCBOT19DSEFOR0UgYXMgYW55LCAnSW5jb21pbmcgdmFsdWUgc2hvdWxkIG5ldmVyIGJlIE5PX0NIQU5HRS4nKTtcbiAgICB2YWxpZGF0ZUFnYWluc3RFdmVudEF0dHJpYnV0ZXMobmFtZSk7XG4gICAgYXNzZXJ0VE5vZGVUeXBlKFxuICAgICAgICB0Tm9kZSwgVE5vZGVUeXBlLkVsZW1lbnQsXG4gICAgICAgIGBBdHRlbXB0ZWQgdG8gc2V0IGF0dHJpYnV0ZSBcXGAke25hbWV9XFxgIG9uIGEgY29udGFpbmVyIG5vZGUuIGAgK1xuICAgICAgICAgICAgYEhvc3QgYmluZGluZ3MgYXJlIG5vdCB2YWxpZCBvbiBuZy1jb250YWluZXIgb3IgbmctdGVtcGxhdGUuYCk7XG4gIH1cbiAgY29uc3QgZWxlbWVudCA9IGdldE5hdGl2ZUJ5VE5vZGUodE5vZGUsIGxWaWV3KSBhcyBSRWxlbWVudDtcbiAgc2V0RWxlbWVudEF0dHJpYnV0ZShsVmlld1tSRU5ERVJFUl0sIGVsZW1lbnQsIG5hbWVzcGFjZSwgdE5vZGUudmFsdWUsIG5hbWUsIHZhbHVlLCBzYW5pdGl6ZXIpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gc2V0RWxlbWVudEF0dHJpYnV0ZShcbiAgICByZW5kZXJlcjogUmVuZGVyZXIsIGVsZW1lbnQ6IFJFbGVtZW50LCBuYW1lc3BhY2U6IHN0cmluZ3xudWxsfHVuZGVmaW5lZCwgdGFnTmFtZTogc3RyaW5nfG51bGwsXG4gICAgbmFtZTogc3RyaW5nLCB2YWx1ZTogYW55LCBzYW5pdGl6ZXI6IFNhbml0aXplckZufG51bGx8dW5kZWZpbmVkKSB7XG4gIGlmICh2YWx1ZSA9PSBudWxsKSB7XG4gICAgbmdEZXZNb2RlICYmIG5nRGV2TW9kZS5yZW5kZXJlclJlbW92ZUF0dHJpYnV0ZSsrO1xuICAgIHJlbmRlcmVyLnJlbW92ZUF0dHJpYnV0ZShlbGVtZW50LCBuYW1lLCBuYW1lc3BhY2UpO1xuICB9IGVsc2Uge1xuICAgIG5nRGV2TW9kZSAmJiBuZ0Rldk1vZGUucmVuZGVyZXJTZXRBdHRyaWJ1dGUrKztcbiAgICBjb25zdCBzdHJWYWx1ZSA9XG4gICAgICAgIHNhbml0aXplciA9PSBudWxsID8gcmVuZGVyU3RyaW5naWZ5KHZhbHVlKSA6IHNhbml0aXplcih2YWx1ZSwgdGFnTmFtZSB8fCAnJywgbmFtZSk7XG5cblxuICAgIHJlbmRlcmVyLnNldEF0dHJpYnV0ZShlbGVtZW50LCBuYW1lLCBzdHJWYWx1ZSBhcyBzdHJpbmcsIG5hbWVzcGFjZSk7XG4gIH1cbn1cblxuLyoqXG4gKiBTZXRzIGluaXRpYWwgaW5wdXQgcHJvcGVydGllcyBvbiBkaXJlY3RpdmUgaW5zdGFuY2VzIGZyb20gYXR0cmlidXRlIGRhdGFcbiAqXG4gKiBAcGFyYW0gbFZpZXcgQ3VycmVudCBMVmlldyB0aGF0IGlzIGJlaW5nIHByb2Nlc3NlZC5cbiAqIEBwYXJhbSBkaXJlY3RpdmVJbmRleCBJbmRleCBvZiB0aGUgZGlyZWN0aXZlIGluIGRpcmVjdGl2ZXMgYXJyYXlcbiAqIEBwYXJhbSBpbnN0YW5jZSBJbnN0YW5jZSBvZiB0aGUgZGlyZWN0aXZlIG9uIHdoaWNoIHRvIHNldCB0aGUgaW5pdGlhbCBpbnB1dHNcbiAqIEBwYXJhbSBkZWYgVGhlIGRpcmVjdGl2ZSBkZWYgdGhhdCBjb250YWlucyB0aGUgbGlzdCBvZiBpbnB1dHNcbiAqIEBwYXJhbSB0Tm9kZSBUaGUgc3RhdGljIGRhdGEgZm9yIHRoaXMgbm9kZVxuICovXG5mdW5jdGlvbiBzZXRJbnB1dHNGcm9tQXR0cnM8VD4oXG4gICAgbFZpZXc6IExWaWV3LCBkaXJlY3RpdmVJbmRleDogbnVtYmVyLCBpbnN0YW5jZTogVCwgZGVmOiBEaXJlY3RpdmVEZWY8VD4sIHROb2RlOiBUTm9kZSxcbiAgICBpbml0aWFsSW5wdXREYXRhOiBJbml0aWFsSW5wdXREYXRhKTogdm9pZCB7XG4gIGNvbnN0IGluaXRpYWxJbnB1dHM6IEluaXRpYWxJbnB1dHN8bnVsbCA9IGluaXRpYWxJbnB1dERhdGEhW2RpcmVjdGl2ZUluZGV4XTtcbiAgaWYgKGluaXRpYWxJbnB1dHMgIT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGluaXRpYWxJbnB1dHMubGVuZ3RoOykge1xuICAgICAgY29uc3QgcHVibGljTmFtZSA9IGluaXRpYWxJbnB1dHNbaSsrXTtcbiAgICAgIGNvbnN0IHByaXZhdGVOYW1lID0gaW5pdGlhbElucHV0c1tpKytdO1xuICAgICAgY29uc3QgdmFsdWUgPSBpbml0aWFsSW5wdXRzW2krK107XG5cbiAgICAgIHdyaXRlVG9EaXJlY3RpdmVJbnB1dDxUPihkZWYsIGluc3RhbmNlLCBwdWJsaWNOYW1lLCBwcml2YXRlTmFtZSwgdmFsdWUpO1xuXG4gICAgICBpZiAobmdEZXZNb2RlKSB7XG4gICAgICAgIGNvbnN0IG5hdGl2ZUVsZW1lbnQgPSBnZXROYXRpdmVCeVROb2RlKHROb2RlLCBsVmlldykgYXMgUkVsZW1lbnQ7XG4gICAgICAgIHNldE5nUmVmbGVjdFByb3BlcnR5KGxWaWV3LCBuYXRpdmVFbGVtZW50LCB0Tm9kZS50eXBlLCBwcml2YXRlTmFtZSwgdmFsdWUpO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG5mdW5jdGlvbiB3cml0ZVRvRGlyZWN0aXZlSW5wdXQ8VD4oXG4gICAgZGVmOiBEaXJlY3RpdmVEZWY8VD4sIGluc3RhbmNlOiBULCBwdWJsaWNOYW1lOiBzdHJpbmcsIHByaXZhdGVOYW1lOiBzdHJpbmcsIHZhbHVlOiBzdHJpbmcpIHtcbiAgY29uc3QgcHJldkNvbnN1bWVyID0gc2V0QWN0aXZlQ29uc3VtZXIobnVsbCk7XG4gIHRyeSB7XG4gICAgaWYgKGRlZi5zZXRJbnB1dCAhPT0gbnVsbCkge1xuICAgICAgZGVmLnNldElucHV0KGluc3RhbmNlLCB2YWx1ZSwgcHVibGljTmFtZSwgcHJpdmF0ZU5hbWUpO1xuICAgIH0gZWxzZSB7XG4gICAgICAoaW5zdGFuY2UgYXMgYW55KVtwcml2YXRlTmFtZV0gPSB2YWx1ZTtcbiAgICB9XG4gIH0gZmluYWxseSB7XG4gICAgc2V0QWN0aXZlQ29uc3VtZXIocHJldkNvbnN1bWVyKTtcbiAgfVxufVxuXG4vKipcbiAqIEdlbmVyYXRlcyBpbml0aWFsSW5wdXREYXRhIGZvciBhIG5vZGUgYW5kIHN0b3JlcyBpdCBpbiB0aGUgdGVtcGxhdGUncyBzdGF0aWMgc3RvcmFnZVxuICogc28gc3Vic2VxdWVudCB0ZW1wbGF0ZSBpbnZvY2F0aW9ucyBkb24ndCBoYXZlIHRvIHJlY2FsY3VsYXRlIGl0LlxuICpcbiAqIGluaXRpYWxJbnB1dERhdGEgaXMgYW4gYXJyYXkgY29udGFpbmluZyB2YWx1ZXMgdGhhdCBuZWVkIHRvIGJlIHNldCBhcyBpbnB1dCBwcm9wZXJ0aWVzXG4gKiBmb3IgZGlyZWN0aXZlcyBvbiB0aGlzIG5vZGUsIGJ1dCBvbmx5IG9uY2Ugb24gY3JlYXRpb24uIFdlIG5lZWQgdGhpcyBhcnJheSB0byBzdXBwb3J0XG4gKiB0aGUgY2FzZSB3aGVyZSB5b3Ugc2V0IGFuIEBJbnB1dCBwcm9wZXJ0eSBvZiBhIGRpcmVjdGl2ZSB1c2luZyBhdHRyaWJ1dGUtbGlrZSBzeW50YXguXG4gKiBlLmcuIGlmIHlvdSBoYXZlIGEgYG5hbWVgIEBJbnB1dCwgeW91IGNhbiBzZXQgaXQgb25jZSBsaWtlIHRoaXM6XG4gKlxuICogPG15LWNvbXBvbmVudCBuYW1lPVwiQmVzc1wiPjwvbXktY29tcG9uZW50PlxuICpcbiAqIEBwYXJhbSBpbnB1dHMgSW5wdXQgYWxpYXMgbWFwIHRoYXQgd2FzIGdlbmVyYXRlZCBmcm9tIHRoZSBkaXJlY3RpdmUgZGVmIGlucHV0cy5cbiAqIEBwYXJhbSBkaXJlY3RpdmVJbmRleCBJbmRleCBvZiB0aGUgZGlyZWN0aXZlIHRoYXQgaXMgY3VycmVudGx5IGJlaW5nIHByb2Nlc3NlZC5cbiAqIEBwYXJhbSBhdHRycyBTdGF0aWMgYXR0cnMgb24gdGhpcyBub2RlLlxuICovXG5mdW5jdGlvbiBnZW5lcmF0ZUluaXRpYWxJbnB1dHMoXG4gICAgaW5wdXRzOiBQcm9wZXJ0eUFsaWFzZXMsIGRpcmVjdGl2ZUluZGV4OiBudW1iZXIsIGF0dHJzOiBUQXR0cmlidXRlcyk6IEluaXRpYWxJbnB1dHN8bnVsbCB7XG4gIGxldCBpbnB1dHNUb1N0b3JlOiBJbml0aWFsSW5wdXRzfG51bGwgPSBudWxsO1xuICBsZXQgaSA9IDA7XG4gIHdoaWxlIChpIDwgYXR0cnMubGVuZ3RoKSB7XG4gICAgY29uc3QgYXR0ck5hbWUgPSBhdHRyc1tpXTtcbiAgICBpZiAoYXR0ck5hbWUgPT09IEF0dHJpYnV0ZU1hcmtlci5OYW1lc3BhY2VVUkkpIHtcbiAgICAgIC8vIFdlIGRvIG5vdCBhbGxvdyBpbnB1dHMgb24gbmFtZXNwYWNlZCBhdHRyaWJ1dGVzLlxuICAgICAgaSArPSA0O1xuICAgICAgY29udGludWU7XG4gICAgfSBlbHNlIGlmIChhdHRyTmFtZSA9PT0gQXR0cmlidXRlTWFya2VyLlByb2plY3RBcykge1xuICAgICAgLy8gU2tpcCBvdmVyIHRoZSBgbmdQcm9qZWN0QXNgIHZhbHVlLlxuICAgICAgaSArPSAyO1xuICAgICAgY29udGludWU7XG4gICAgfVxuXG4gICAgLy8gSWYgd2UgaGl0IGFueSBvdGhlciBhdHRyaWJ1dGUgbWFya2Vycywgd2UncmUgZG9uZSBhbnl3YXkuIE5vbmUgb2YgdGhvc2UgYXJlIHZhbGlkIGlucHV0cy5cbiAgICBpZiAodHlwZW9mIGF0dHJOYW1lID09PSAnbnVtYmVyJykgYnJlYWs7XG5cbiAgICBpZiAoaW5wdXRzLmhhc093blByb3BlcnR5KGF0dHJOYW1lIGFzIHN0cmluZykpIHtcbiAgICAgIGlmIChpbnB1dHNUb1N0b3JlID09PSBudWxsKSBpbnB1dHNUb1N0b3JlID0gW107XG5cbiAgICAgIC8vIEZpbmQgdGhlIGlucHV0J3MgcHVibGljIG5hbWUgZnJvbSB0aGUgaW5wdXQgc3RvcmUuIE5vdGUgdGhhdCB3ZSBjYW4gYmUgZm91bmQgZWFzaWVyXG4gICAgICAvLyB0aHJvdWdoIHRoZSBkaXJlY3RpdmUgZGVmLCBidXQgd2Ugd2FudCB0byBkbyBpdCB1c2luZyB0aGUgaW5wdXRzIHN0b3JlIHNvIHRoYXQgaXQgY2FuXG4gICAgICAvLyBhY2NvdW50IGZvciBob3N0IGRpcmVjdGl2ZSBhbGlhc2VzLlxuICAgICAgY29uc3QgaW5wdXRDb25maWcgPSBpbnB1dHNbYXR0ck5hbWUgYXMgc3RyaW5nXTtcbiAgICAgIGZvciAobGV0IGogPSAwOyBqIDwgaW5wdXRDb25maWcubGVuZ3RoOyBqICs9IDIpIHtcbiAgICAgICAgaWYgKGlucHV0Q29uZmlnW2pdID09PSBkaXJlY3RpdmVJbmRleCkge1xuICAgICAgICAgIGlucHV0c1RvU3RvcmUucHVzaChcbiAgICAgICAgICAgICAgYXR0ck5hbWUgYXMgc3RyaW5nLCBpbnB1dENvbmZpZ1tqICsgMV0gYXMgc3RyaW5nLCBhdHRyc1tpICsgMV0gYXMgc3RyaW5nKTtcbiAgICAgICAgICAvLyBBIGRpcmVjdGl2ZSBjYW4ndCBoYXZlIG11bHRpcGxlIGlucHV0cyB3aXRoIHRoZSBzYW1lIG5hbWUgc28gd2UgY2FuIGJyZWFrIGhlcmUuXG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICBpICs9IDI7XG4gIH1cbiAgcmV0dXJuIGlucHV0c1RvU3RvcmU7XG59XG5cbi8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG4vLy8vIFZpZXdDb250YWluZXIgJiBWaWV3XG4vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuXG4vKipcbiAqIENyZWF0ZXMgYSBMQ29udGFpbmVyLCBlaXRoZXIgZnJvbSBhIGNvbnRhaW5lciBpbnN0cnVjdGlvbiwgb3IgZm9yIGEgVmlld0NvbnRhaW5lclJlZi5cbiAqXG4gKiBAcGFyYW0gaG9zdE5hdGl2ZSBUaGUgaG9zdCBlbGVtZW50IGZvciB0aGUgTENvbnRhaW5lclxuICogQHBhcmFtIGhvc3RUTm9kZSBUaGUgaG9zdCBUTm9kZSBmb3IgdGhlIExDb250YWluZXJcbiAqIEBwYXJhbSBjdXJyZW50VmlldyBUaGUgcGFyZW50IHZpZXcgb2YgdGhlIExDb250YWluZXJcbiAqIEBwYXJhbSBuYXRpdmUgVGhlIG5hdGl2ZSBjb21tZW50IGVsZW1lbnRcbiAqIEBwYXJhbSBpc0ZvclZpZXdDb250YWluZXJSZWYgT3B0aW9uYWwgYSBmbGFnIGluZGljYXRpbmcgdGhlIFZpZXdDb250YWluZXJSZWYgY2FzZVxuICogQHJldHVybnMgTENvbnRhaW5lclxuICovXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlTENvbnRhaW5lcihcbiAgICBob3N0TmF0aXZlOiBSRWxlbWVudHxSQ29tbWVudHxMVmlldywgY3VycmVudFZpZXc6IExWaWV3LCBuYXRpdmU6IFJDb21tZW50LFxuICAgIHROb2RlOiBUTm9kZSk6IExDb250YWluZXIge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0TFZpZXcoY3VycmVudFZpZXcpO1xuICBjb25zdCBsQ29udGFpbmVyOiBMQ29udGFpbmVyID0gW1xuICAgIGhvc3ROYXRpdmUsICAgLy8gaG9zdCBuYXRpdmVcbiAgICB0cnVlLCAgICAgICAgIC8vIEJvb2xlYW4gYHRydWVgIGluIHRoaXMgcG9zaXRpb24gc2lnbmlmaWVzIHRoYXQgdGhpcyBpcyBhbiBgTENvbnRhaW5lcmBcbiAgICBmYWxzZSwgICAgICAgIC8vIGhhcyB0cmFuc3BsYW50ZWQgdmlld3NcbiAgICBjdXJyZW50VmlldywgIC8vIHBhcmVudFxuICAgIG51bGwsICAgICAgICAgLy8gbmV4dFxuICAgIDAsICAgICAgICAgICAgLy8gdHJhbnNwbGFudGVkIHZpZXdzIHRvIHJlZnJlc2ggY291bnRcbiAgICB0Tm9kZSwgICAgICAgIC8vIHRfaG9zdFxuICAgIG5hdGl2ZSwgICAgICAgLy8gbmF0aXZlLFxuICAgIG51bGwsICAgICAgICAgLy8gdmlldyByZWZzXG4gICAgbnVsbCwgICAgICAgICAvLyBtb3ZlZCB2aWV3c1xuICAgIG51bGwsICAgICAgICAgLy8gZGVoeWRyYXRlZCB2aWV3c1xuICBdO1xuICBuZ0Rldk1vZGUgJiZcbiAgICAgIGFzc2VydEVxdWFsKFxuICAgICAgICAgIGxDb250YWluZXIubGVuZ3RoLCBDT05UQUlORVJfSEVBREVSX09GRlNFVCxcbiAgICAgICAgICAnU2hvdWxkIGFsbG9jYXRlIGNvcnJlY3QgbnVtYmVyIG9mIHNsb3RzIGZvciBMQ29udGFpbmVyIGhlYWRlci4nKTtcbiAgcmV0dXJuIGxDb250YWluZXI7XG59XG5cbi8qKiBSZWZyZXNoZXMgYWxsIGNvbnRlbnQgcXVlcmllcyBkZWNsYXJlZCBieSBkaXJlY3RpdmVzIGluIGEgZ2l2ZW4gdmlldyAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlZnJlc2hDb250ZW50UXVlcmllcyh0VmlldzogVFZpZXcsIGxWaWV3OiBMVmlldyk6IHZvaWQge1xuICBjb25zdCBjb250ZW50UXVlcmllcyA9IHRWaWV3LmNvbnRlbnRRdWVyaWVzO1xuICBpZiAoY29udGVudFF1ZXJpZXMgIT09IG51bGwpIHtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGNvbnRlbnRRdWVyaWVzLmxlbmd0aDsgaSArPSAyKSB7XG4gICAgICBjb25zdCBxdWVyeVN0YXJ0SWR4ID0gY29udGVudFF1ZXJpZXNbaV07XG4gICAgICBjb25zdCBkaXJlY3RpdmVEZWZJZHggPSBjb250ZW50UXVlcmllc1tpICsgMV07XG4gICAgICBpZiAoZGlyZWN0aXZlRGVmSWR4ICE9PSAtMSkge1xuICAgICAgICBjb25zdCBkaXJlY3RpdmVEZWYgPSB0Vmlldy5kYXRhW2RpcmVjdGl2ZURlZklkeF0gYXMgRGlyZWN0aXZlRGVmPGFueT47XG4gICAgICAgIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGRpcmVjdGl2ZURlZiwgJ0RpcmVjdGl2ZURlZiBub3QgZm91bmQuJyk7XG4gICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgYXNzZXJ0RGVmaW5lZChkaXJlY3RpdmVEZWYuY29udGVudFF1ZXJpZXMsICdjb250ZW50UXVlcmllcyBmdW5jdGlvbiBzaG91bGQgYmUgZGVmaW5lZCcpO1xuICAgICAgICBzZXRDdXJyZW50UXVlcnlJbmRleChxdWVyeVN0YXJ0SWR4KTtcbiAgICAgICAgZGlyZWN0aXZlRGVmLmNvbnRlbnRRdWVyaWVzIShSZW5kZXJGbGFncy5VcGRhdGUsIGxWaWV3W2RpcmVjdGl2ZURlZklkeF0sIGRpcmVjdGl2ZURlZklkeCk7XG4gICAgICB9XG4gICAgfVxuICB9XG59XG5cbi8qKlxuICogQWRkcyBMVmlldyBvciBMQ29udGFpbmVyIHRvIHRoZSBlbmQgb2YgdGhlIGN1cnJlbnQgdmlldyB0cmVlLlxuICpcbiAqIFRoaXMgc3RydWN0dXJlIHdpbGwgYmUgdXNlZCB0byB0cmF2ZXJzZSB0aHJvdWdoIG5lc3RlZCB2aWV3cyB0byByZW1vdmUgbGlzdGVuZXJzXG4gKiBhbmQgY2FsbCBvbkRlc3Ryb3kgY2FsbGJhY2tzLlxuICpcbiAqIEBwYXJhbSBsVmlldyBUaGUgdmlldyB3aGVyZSBMVmlldyBvciBMQ29udGFpbmVyIHNob3VsZCBiZSBhZGRlZFxuICogQHBhcmFtIGFkanVzdGVkSG9zdEluZGV4IEluZGV4IG9mIHRoZSB2aWV3J3MgaG9zdCBub2RlIGluIExWaWV3W10sIGFkanVzdGVkIGZvciBoZWFkZXJcbiAqIEBwYXJhbSBsVmlld09yTENvbnRhaW5lciBUaGUgTFZpZXcgb3IgTENvbnRhaW5lciB0byBhZGQgdG8gdGhlIHZpZXcgdHJlZVxuICogQHJldHVybnMgVGhlIHN0YXRlIHBhc3NlZCBpblxuICovXG5leHBvcnQgZnVuY3Rpb24gYWRkVG9WaWV3VHJlZTxUIGV4dGVuZHMgTFZpZXd8TENvbnRhaW5lcj4obFZpZXc6IExWaWV3LCBsVmlld09yTENvbnRhaW5lcjogVCk6IFQge1xuICAvLyBUT0RPKGJlbmxlc2gvbWlza28pOiBUaGlzIGltcGxlbWVudGF0aW9uIGlzIGluY29ycmVjdCwgYmVjYXVzZSBpdCBhbHdheXMgYWRkcyB0aGUgTENvbnRhaW5lclxuICAvLyB0byB0aGUgZW5kIG9mIHRoZSBxdWV1ZSwgd2hpY2ggbWVhbnMgaWYgdGhlIGRldmVsb3BlciByZXRyaWV2ZXMgdGhlIExDb250YWluZXJzIGZyb20gUk5vZGVzIG91dFxuICAvLyBvZiBvcmRlciwgdGhlIGNoYW5nZSBkZXRlY3Rpb24gd2lsbCBydW4gb3V0IG9mIG9yZGVyLCBhcyB0aGUgYWN0IG9mIHJldHJpZXZpbmcgdGhlIHRoZVxuICAvLyBMQ29udGFpbmVyIGZyb20gdGhlIFJOb2RlIGlzIHdoYXQgYWRkcyBpdCB0byB0aGUgcXVldWUuXG4gIGlmIChsVmlld1tDSElMRF9IRUFEXSkge1xuICAgIGxWaWV3W0NISUxEX1RBSUxdIVtORVhUXSA9IGxWaWV3T3JMQ29udGFpbmVyO1xuICB9IGVsc2Uge1xuICAgIGxWaWV3W0NISUxEX0hFQURdID0gbFZpZXdPckxDb250YWluZXI7XG4gIH1cbiAgbFZpZXdbQ0hJTERfVEFJTF0gPSBsVmlld09yTENvbnRhaW5lcjtcbiAgcmV0dXJuIGxWaWV3T3JMQ29udGFpbmVyO1xufVxuXG4vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG4vLy8vIENoYW5nZSBkZXRlY3Rpb25cbi8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy9cblxuZXhwb3J0IGZ1bmN0aW9uIGV4ZWN1dGVWaWV3UXVlcnlGbjxUPihcbiAgICBmbGFnczogUmVuZGVyRmxhZ3MsIHZpZXdRdWVyeUZuOiBWaWV3UXVlcmllc0Z1bmN0aW9uPFQ+LCBjb21wb25lbnQ6IFQpOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQodmlld1F1ZXJ5Rm4sICdWaWV3IHF1ZXJpZXMgZnVuY3Rpb24gdG8gZXhlY3V0ZSBtdXN0IGJlIGRlZmluZWQuJyk7XG4gIHNldEN1cnJlbnRRdWVyeUluZGV4KDApO1xuICBjb25zdCBwcmV2Q29uc3VtZXIgPSBzZXRBY3RpdmVDb25zdW1lcihudWxsKTtcbiAgdHJ5IHtcbiAgICB2aWV3UXVlcnlGbihmbGFncywgY29tcG9uZW50KTtcbiAgfSBmaW5hbGx5IHtcbiAgICBzZXRBY3RpdmVDb25zdW1lcihwcmV2Q29uc3VtZXIpO1xuICB9XG59XG5cbi8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy9cbi8vLy8gQmluZGluZ3MgJiBpbnRlcnBvbGF0aW9uc1xuLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuXG4vKipcbiAqIFN0b3JlcyBtZXRhLWRhdGEgZm9yIGEgcHJvcGVydHkgYmluZGluZyB0byBiZSB1c2VkIGJ5IFRlc3RCZWQncyBgRGVidWdFbGVtZW50LnByb3BlcnRpZXNgLlxuICpcbiAqIEluIG9yZGVyIHRvIHN1cHBvcnQgVGVzdEJlZCdzIGBEZWJ1Z0VsZW1lbnQucHJvcGVydGllc2Agd2UgbmVlZCB0byBzYXZlLCBmb3IgZWFjaCBiaW5kaW5nOlxuICogLSBhIGJvdW5kIHByb3BlcnR5IG5hbWU7XG4gKiAtIGEgc3RhdGljIHBhcnRzIG9mIGludGVycG9sYXRlZCBzdHJpbmdzO1xuICpcbiAqIEEgZ2l2ZW4gcHJvcGVydHkgbWV0YWRhdGEgaXMgc2F2ZWQgYXQgdGhlIGJpbmRpbmcncyBpbmRleCBpbiB0aGUgYFRWaWV3LmRhdGFgIChpbiBvdGhlciB3b3JkcywgYVxuICogcHJvcGVydHkgYmluZGluZyBtZXRhZGF0YSB3aWxsIGJlIHN0b3JlZCBpbiBgVFZpZXcuZGF0YWAgYXQgdGhlIHNhbWUgaW5kZXggYXMgYSBib3VuZCB2YWx1ZSBpblxuICogYExWaWV3YCkuIE1ldGFkYXRhIGFyZSByZXByZXNlbnRlZCBhcyBgSU5URVJQT0xBVElPTl9ERUxJTUlURVJgLWRlbGltaXRlZCBzdHJpbmcgd2l0aCB0aGVcbiAqIGZvbGxvd2luZyBmb3JtYXQ6XG4gKiAtIGBwcm9wZXJ0eU5hbWVgIGZvciBib3VuZCBwcm9wZXJ0aWVzO1xuICogLSBgcHJvcGVydHlOYW1l77+9cHJlZml477+9aW50ZXJwb2xhdGlvbl9zdGF0aWNfcGFydDHvv70uLmludGVycG9sYXRpb25fc3RhdGljX3BhcnRO77+9c3VmZml4YCBmb3JcbiAqIGludGVycG9sYXRlZCBwcm9wZXJ0aWVzLlxuICpcbiAqIEBwYXJhbSB0RGF0YSBgVERhdGFgIHdoZXJlIG1ldGEtZGF0YSB3aWxsIGJlIHNhdmVkO1xuICogQHBhcmFtIHROb2RlIGBUTm9kZWAgdGhhdCBpcyBhIHRhcmdldCBvZiB0aGUgYmluZGluZztcbiAqIEBwYXJhbSBwcm9wZXJ0eU5hbWUgYm91bmQgcHJvcGVydHkgbmFtZTtcbiAqIEBwYXJhbSBiaW5kaW5nSW5kZXggYmluZGluZyBpbmRleCBpbiBgTFZpZXdgXG4gKiBAcGFyYW0gaW50ZXJwb2xhdGlvblBhcnRzIHN0YXRpYyBpbnRlcnBvbGF0aW9uIHBhcnRzIChmb3IgcHJvcGVydHkgaW50ZXJwb2xhdGlvbnMpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzdG9yZVByb3BlcnR5QmluZGluZ01ldGFkYXRhKFxuICAgIHREYXRhOiBURGF0YSwgdE5vZGU6IFROb2RlLCBwcm9wZXJ0eU5hbWU6IHN0cmluZywgYmluZGluZ0luZGV4OiBudW1iZXIsXG4gICAgLi4uaW50ZXJwb2xhdGlvblBhcnRzOiBzdHJpbmdbXSkge1xuICAvLyBCaW5kaW5nIG1ldGEtZGF0YSBhcmUgc3RvcmVkIG9ubHkgdGhlIGZpcnN0IHRpbWUgYSBnaXZlbiBwcm9wZXJ0eSBpbnN0cnVjdGlvbiBpcyBwcm9jZXNzZWQuXG4gIC8vIFNpbmNlIHdlIGRvbid0IGhhdmUgYSBjb25jZXB0IG9mIHRoZSBcImZpcnN0IHVwZGF0ZSBwYXNzXCIgd2UgbmVlZCB0byBjaGVjayBmb3IgcHJlc2VuY2Ugb2YgdGhlXG4gIC8vIGJpbmRpbmcgbWV0YS1kYXRhIHRvIGRlY2lkZSBpZiBvbmUgc2hvdWxkIGJlIHN0b3JlZCAob3IgaWYgd2FzIHN0b3JlZCBhbHJlYWR5KS5cbiAgaWYgKHREYXRhW2JpbmRpbmdJbmRleF0gPT09IG51bGwpIHtcbiAgICBpZiAodE5vZGUuaW5wdXRzID09IG51bGwgfHwgIXROb2RlLmlucHV0c1twcm9wZXJ0eU5hbWVdKSB7XG4gICAgICBjb25zdCBwcm9wQmluZGluZ0lkeHMgPSB0Tm9kZS5wcm9wZXJ0eUJpbmRpbmdzIHx8ICh0Tm9kZS5wcm9wZXJ0eUJpbmRpbmdzID0gW10pO1xuICAgICAgcHJvcEJpbmRpbmdJZHhzLnB1c2goYmluZGluZ0luZGV4KTtcbiAgICAgIGxldCBiaW5kaW5nTWV0YWRhdGEgPSBwcm9wZXJ0eU5hbWU7XG4gICAgICBpZiAoaW50ZXJwb2xhdGlvblBhcnRzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgYmluZGluZ01ldGFkYXRhICs9XG4gICAgICAgICAgICBJTlRFUlBPTEFUSU9OX0RFTElNSVRFUiArIGludGVycG9sYXRpb25QYXJ0cy5qb2luKElOVEVSUE9MQVRJT05fREVMSU1JVEVSKTtcbiAgICAgIH1cbiAgICAgIHREYXRhW2JpbmRpbmdJbmRleF0gPSBiaW5kaW5nTWV0YWRhdGE7XG4gICAgfVxuICB9XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBnZXRPckNyZWF0ZUxWaWV3Q2xlYW51cCh2aWV3OiBMVmlldyk6IGFueVtdIHtcbiAgLy8gdG9wIGxldmVsIHZhcmlhYmxlcyBzaG91bGQgbm90IGJlIGV4cG9ydGVkIGZvciBwZXJmb3JtYW5jZSByZWFzb25zIChQRVJGX05PVEVTLm1kKVxuICByZXR1cm4gdmlld1tDTEVBTlVQXSB8fCAodmlld1tDTEVBTlVQXSA9IFtdKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldE9yQ3JlYXRlVFZpZXdDbGVhbnVwKHRWaWV3OiBUVmlldyk6IGFueVtdIHtcbiAgcmV0dXJuIHRWaWV3LmNsZWFudXAgfHwgKHRWaWV3LmNsZWFudXAgPSBbXSk7XG59XG5cbi8qKlxuICogVGhlcmUgYXJlIGNhc2VzIHdoZXJlIHRoZSBzdWIgY29tcG9uZW50J3MgcmVuZGVyZXIgbmVlZHMgdG8gYmUgaW5jbHVkZWRcbiAqIGluc3RlYWQgb2YgdGhlIGN1cnJlbnQgcmVuZGVyZXIgKHNlZSB0aGUgY29tcG9uZW50U3ludGhldGljSG9zdCogaW5zdHJ1Y3Rpb25zKS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGxvYWRDb21wb25lbnRSZW5kZXJlcihcbiAgICBjdXJyZW50RGVmOiBEaXJlY3RpdmVEZWY8YW55PnxudWxsLCB0Tm9kZTogVE5vZGUsIGxWaWV3OiBMVmlldyk6IFJlbmRlcmVyIHtcbiAgLy8gVE9ETyhGVy0yMDQzKTogdGhlIGBjdXJyZW50RGVmYCBpcyBudWxsIHdoZW4gaG9zdCBiaW5kaW5ncyBhcmUgaW52b2tlZCB3aGlsZSBjcmVhdGluZyByb290XG4gIC8vIGNvbXBvbmVudCAoc2VlIHBhY2thZ2VzL2NvcmUvc3JjL3JlbmRlcjMvY29tcG9uZW50LnRzKS4gVGhpcyBpcyBub3QgY29uc2lzdGVudCB3aXRoIHRoZSBwcm9jZXNzXG4gIC8vIG9mIGNyZWF0aW5nIGlubmVyIGNvbXBvbmVudHMsIHdoZW4gY3VycmVudCBkaXJlY3RpdmUgaW5kZXggaXMgYXZhaWxhYmxlIGluIHRoZSBzdGF0ZS4gSW4gb3JkZXJcbiAgLy8gdG8gYXZvaWQgcmVseWluZyBvbiBjdXJyZW50IGRlZiBiZWluZyBgbnVsbGAgKHRodXMgc3BlY2lhbC1jYXNpbmcgcm9vdCBjb21wb25lbnQgY3JlYXRpb24pLCB0aGVcbiAgLy8gcHJvY2VzcyBvZiBjcmVhdGluZyByb290IGNvbXBvbmVudCBzaG91bGQgYmUgdW5pZmllZCB3aXRoIHRoZSBwcm9jZXNzIG9mIGNyZWF0aW5nIGlubmVyXG4gIC8vIGNvbXBvbmVudHMuXG4gIGlmIChjdXJyZW50RGVmID09PSBudWxsIHx8IGlzQ29tcG9uZW50RGVmKGN1cnJlbnREZWYpKSB7XG4gICAgbFZpZXcgPSB1bndyYXBMVmlldyhsVmlld1t0Tm9kZS5pbmRleF0pITtcbiAgfVxuICByZXR1cm4gbFZpZXdbUkVOREVSRVJdO1xufVxuXG4vKiogSGFuZGxlcyBhbiBlcnJvciB0aHJvd24gaW4gYW4gTFZpZXcuICovXG5leHBvcnQgZnVuY3Rpb24gaGFuZGxlRXJyb3IobFZpZXc6IExWaWV3LCBlcnJvcjogYW55KTogdm9pZCB7XG4gIGNvbnN0IGluamVjdG9yID0gbFZpZXdbSU5KRUNUT1JdO1xuICBjb25zdCBlcnJvckhhbmRsZXIgPSBpbmplY3RvciA/IGluamVjdG9yLmdldChFcnJvckhhbmRsZXIsIG51bGwpIDogbnVsbDtcbiAgZXJyb3JIYW5kbGVyICYmIGVycm9ySGFuZGxlci5oYW5kbGVFcnJvcihlcnJvcik7XG59XG5cbi8qKlxuICogU2V0IHRoZSBpbnB1dHMgb2YgZGlyZWN0aXZlcyBhdCB0aGUgY3VycmVudCBub2RlIHRvIGNvcnJlc3BvbmRpbmcgdmFsdWUuXG4gKlxuICogQHBhcmFtIHRWaWV3IFRoZSBjdXJyZW50IFRWaWV3XG4gKiBAcGFyYW0gbFZpZXcgdGhlIGBMVmlld2Agd2hpY2ggY29udGFpbnMgdGhlIGRpcmVjdGl2ZXMuXG4gKiBAcGFyYW0gaW5wdXRzIG1hcHBpbmcgYmV0d2VlbiB0aGUgcHVibGljIFwiaW5wdXRcIiBuYW1lIGFuZCBwcml2YXRlbHkta25vd24sXG4gKiAgICAgICAgcG9zc2libHkgbWluaWZpZWQsIHByb3BlcnR5IG5hbWVzIHRvIHdyaXRlIHRvLlxuICogQHBhcmFtIHZhbHVlIFZhbHVlIHRvIHNldC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldElucHV0c0ZvclByb3BlcnR5KFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCBpbnB1dHM6IFByb3BlcnR5QWxpYXNWYWx1ZSwgcHVibGljTmFtZTogc3RyaW5nLCB2YWx1ZTogYW55KTogdm9pZCB7XG4gIGZvciAobGV0IGkgPSAwOyBpIDwgaW5wdXRzLmxlbmd0aDspIHtcbiAgICBjb25zdCBpbmRleCA9IGlucHV0c1tpKytdIGFzIG51bWJlcjtcbiAgICBjb25zdCBwcml2YXRlTmFtZSA9IGlucHV0c1tpKytdIGFzIHN0cmluZztcbiAgICBjb25zdCBpbnN0YW5jZSA9IGxWaWV3W2luZGV4XTtcbiAgICBuZ0Rldk1vZGUgJiYgYXNzZXJ0SW5kZXhJblJhbmdlKGxWaWV3LCBpbmRleCk7XG4gICAgY29uc3QgZGVmID0gdFZpZXcuZGF0YVtpbmRleF0gYXMgRGlyZWN0aXZlRGVmPGFueT47XG5cbiAgICB3cml0ZVRvRGlyZWN0aXZlSW5wdXQoZGVmLCBpbnN0YW5jZSwgcHVibGljTmFtZSwgcHJpdmF0ZU5hbWUsIHZhbHVlKTtcbiAgfVxufVxuXG4vKipcbiAqIFVwZGF0ZXMgYSB0ZXh0IGJpbmRpbmcgYXQgYSBnaXZlbiBpbmRleCBpbiBhIGdpdmVuIExWaWV3LlxuICovXG5leHBvcnQgZnVuY3Rpb24gdGV4dEJpbmRpbmdJbnRlcm5hbChsVmlldzogTFZpZXcsIGluZGV4OiBudW1iZXIsIHZhbHVlOiBzdHJpbmcpOiB2b2lkIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydFN0cmluZyh2YWx1ZSwgJ1ZhbHVlIHNob3VsZCBiZSBhIHN0cmluZycpO1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0Tm90U2FtZSh2YWx1ZSwgTk9fQ0hBTkdFIGFzIGFueSwgJ3ZhbHVlIHNob3VsZCBub3QgYmUgTk9fQ0hBTkdFJyk7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRJbmRleEluUmFuZ2UobFZpZXcsIGluZGV4KTtcbiAgY29uc3QgZWxlbWVudCA9IGdldE5hdGl2ZUJ5SW5kZXgoaW5kZXgsIGxWaWV3KSBhcyBhbnkgYXMgUlRleHQ7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKGVsZW1lbnQsICduYXRpdmUgZWxlbWVudCBzaG91bGQgZXhpc3QnKTtcbiAgdXBkYXRlVGV4dE5vZGUobFZpZXdbUkVOREVSRVJdLCBlbGVtZW50LCB2YWx1ZSk7XG59XG4iXX0=