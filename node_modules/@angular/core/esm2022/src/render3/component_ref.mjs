/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { convertToBitFlags } from '../di/injector_compatibility';
import { EnvironmentInjector } from '../di/r3_injector';
import { RuntimeError } from '../errors';
import { retrieveHydrationInfo } from '../hydration/utils';
import { ComponentFactory as AbstractComponentFactory, ComponentRef as AbstractComponentRef } from '../linker/component_factory';
import { ComponentFactoryResolver as AbstractComponentFactoryResolver } from '../linker/component_factory_resolver';
import { createElementRef } from '../linker/element_ref';
import { RendererFactory2 } from '../render/api';
import { Sanitizer } from '../sanitization/sanitizer';
import { assertDefined, assertGreaterThan, assertIndexInRange } from '../util/assert';
import { VERSION } from '../version';
import { NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR } from '../view/provider_flags';
import { assertComponentType } from './assert';
import { attachPatchData } from './context_discovery';
import { getComponentDef } from './definition';
import { getNodeInjectable, NodeInjector } from './di';
import { throwProviderNotFoundError } from './errors_di';
import { registerPostOrderHooks } from './hooks';
import { reportUnknownPropertyError } from './instructions/element_validation';
import { markViewDirty } from './instructions/mark_view_dirty';
import { renderView } from './instructions/render';
import { addToViewTree, createLView, createTView, executeContentQueries, getOrCreateComponentTView, getOrCreateTNode, initializeDirectives, invokeDirectivesHostBindings, locateHostElement, markAsComponentHost, setInputsForProperty } from './instructions/shared';
import { CONTEXT, HEADER_OFFSET, INJECTOR, TVIEW } from './interfaces/view';
import { MATH_ML_NAMESPACE, SVG_NAMESPACE } from './namespaces';
import { createElementNode, setupStaticAttributes, writeDirectClass } from './node_manipulation';
import { extractAttrsAndClassesFromSelector, stringifyCSSSelectorList } from './node_selector_matcher';
import { EffectManager } from './reactivity/effect';
import { enterView, getCurrentTNode, getLView, leaveView } from './state';
import { computeStaticStyling } from './styling/static_styling';
import { mergeHostAttrs, setUpAttributes } from './util/attrs_utils';
import { stringifyForError } from './util/stringify_utils';
import { getComponentLViewByIndex, getNativeByTNode, getTNode } from './util/view_utils';
import { RootViewRef } from './view_ref';
export class ComponentFactoryResolver extends AbstractComponentFactoryResolver {
    /**
     * @param ngModule The NgModuleRef to which all resolved factories are bound.
     */
    constructor(ngModule) {
        super();
        this.ngModule = ngModule;
    }
    resolveComponentFactory(component) {
        ngDevMode && assertComponentType(component);
        const componentDef = getComponentDef(component);
        return new ComponentFactory(componentDef, this.ngModule);
    }
}
function toRefArray(map) {
    const array = [];
    for (let nonMinified in map) {
        if (map.hasOwnProperty(nonMinified)) {
            const minified = map[nonMinified];
            array.push({ propName: minified, templateName: nonMinified });
        }
    }
    return array;
}
function getNamespace(elementName) {
    const name = elementName.toLowerCase();
    return name === 'svg' ? SVG_NAMESPACE : (name === 'math' ? MATH_ML_NAMESPACE : null);
}
/**
 * Injector that looks up a value using a specific injector, before falling back to the module
 * injector. Used primarily when creating components or embedded views dynamically.
 */
class ChainedInjector {
    constructor(injector, parentInjector) {
        this.injector = injector;
        this.parentInjector = parentInjector;
    }
    get(token, notFoundValue, flags) {
        flags = convertToBitFlags(flags);
        const value = this.injector.get(token, NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR, flags);
        if (value !== NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR ||
            notFoundValue === NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR) {
            // Return the value from the root element injector when
            // - it provides it
            //   (value !== NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR)
            // - the module injector should not be checked
            //   (notFoundValue === NOT_FOUND_CHECK_ONLY_ELEMENT_INJECTOR)
            return value;
        }
        return this.parentInjector.get(token, notFoundValue, flags);
    }
}
/**
 * ComponentFactory interface implementation.
 */
export class ComponentFactory extends AbstractComponentFactory {
    get inputs() {
        return toRefArray(this.componentDef.inputs);
    }
    get outputs() {
        return toRefArray(this.componentDef.outputs);
    }
    /**
     * @param componentDef The component definition.
     * @param ngModule The NgModuleRef to which the factory is bound.
     */
    constructor(componentDef, ngModule) {
        super();
        this.componentDef = componentDef;
        this.ngModule = ngModule;
        this.componentType = componentDef.type;
        this.selector = stringifyCSSSelectorList(componentDef.selectors);
        this.ngContentSelectors =
            componentDef.ngContentSelectors ? componentDef.ngContentSelectors : [];
        this.isBoundToModule = !!ngModule;
    }
    create(injector, projectableNodes, rootSelectorOrNode, environmentInjector) {
        environmentInjector = environmentInjector || this.ngModule;
        let realEnvironmentInjector = environmentInjector instanceof EnvironmentInjector ?
            environmentInjector :
            environmentInjector?.injector;
        if (realEnvironmentInjector && this.componentDef.getStandaloneInjector !== null) {
            realEnvironmentInjector = this.componentDef.getStandaloneInjector(realEnvironmentInjector) ||
                realEnvironmentInjector;
        }
        const rootViewInjector = realEnvironmentInjector ? new ChainedInjector(injector, realEnvironmentInjector) : injector;
        const rendererFactory = rootViewInjector.get(RendererFactory2, null);
        if (rendererFactory === null) {
            throw new RuntimeError(407 /* RuntimeErrorCode.RENDERER_NOT_FOUND */, ngDevMode &&
                'Angular was not able to inject a renderer (RendererFactory2). ' +
                    'Likely this is due to a broken DI hierarchy. ' +
                    'Make sure that any injector used to create this component has a correct parent.');
        }
        const sanitizer = rootViewInjector.get(Sanitizer, null);
        const effectManager = rootViewInjector.get(EffectManager, null);
        const environment = {
            rendererFactory,
            sanitizer,
            effectManager,
        };
        const hostRenderer = rendererFactory.createRenderer(null, this.componentDef);
        // Determine a tag name used for creating host elements when this component is created
        // dynamically. Default to 'div' if this component did not specify any tag name in its selector.
        const elementName = this.componentDef.selectors[0][0] || 'div';
        const hostRNode = rootSelectorOrNode ?
            locateHostElement(hostRenderer, rootSelectorOrNode, this.componentDef.encapsulation, rootViewInjector) :
            createElementNode(hostRenderer, elementName, getNamespace(elementName));
        const rootFlags = this.componentDef.onPush ? 64 /* LViewFlags.Dirty */ | 512 /* LViewFlags.IsRoot */ :
            16 /* LViewFlags.CheckAlways */ | 512 /* LViewFlags.IsRoot */;
        // Create the root view. Uses empty TView and ContentTemplate.
        const rootTView = createTView(0 /* TViewType.Root */, null, null, 1, 0, null, null, null, null, null, null);
        const rootLView = createLView(null, rootTView, null, rootFlags, null, null, environment, hostRenderer, rootViewInjector, null, null);
        // rootView is the parent when bootstrapping
        // TODO(misko): it looks like we are entering view here but we don't really need to as
        // `renderView` does that. However as the code is written it is needed because
        // `createRootComponentView` and `createRootComponent` both read global state. Fixing those
        // issues would allow us to drop this.
        enterView(rootLView);
        let component;
        let tElementNode;
        try {
            const rootComponentDef = this.componentDef;
            let rootDirectives;
            let hostDirectiveDefs = null;
            if (rootComponentDef.findHostDirectiveDefs) {
                rootDirectives = [];
                hostDirectiveDefs = new Map();
                rootComponentDef.findHostDirectiveDefs(rootComponentDef, rootDirectives, hostDirectiveDefs);
                rootDirectives.push(rootComponentDef);
            }
            else {
                rootDirectives = [rootComponentDef];
            }
            const hostTNode = createRootComponentTNode(rootLView, hostRNode);
            const componentView = createRootComponentView(hostTNode, hostRNode, rootComponentDef, rootDirectives, rootLView, environment, hostRenderer);
            tElementNode = getTNode(rootTView, HEADER_OFFSET);
            // TODO(crisbeto): in practice `hostRNode` should always be defined, but there are some tests
            // where the renderer is mocked out and `undefined` is returned. We should update the tests so
            // that this check can be removed.
            if (hostRNode) {
                setRootNodeAttributes(hostRenderer, rootComponentDef, hostRNode, rootSelectorOrNode);
            }
            if (projectableNodes !== undefined) {
                projectNodes(tElementNode, this.ngContentSelectors, projectableNodes);
            }
            // TODO: should LifecycleHooksFeature and other host features be generated by the compiler and
            // executed here?
            // Angular 5 reference: https://stackblitz.com/edit/lifecycle-hooks-vcref
            component = createRootComponent(componentView, rootComponentDef, rootDirectives, hostDirectiveDefs, rootLView, [LifecycleHooksFeature]);
            renderView(rootTView, rootLView, null);
        }
        finally {
            leaveView();
        }
        return new ComponentRef(this.componentType, component, createElementRef(tElementNode, rootLView), rootLView, tElementNode);
    }
}
/**
 * Represents an instance of a Component created via a {@link ComponentFactory}.
 *
 * `ComponentRef` provides access to the Component Instance as well other objects related to this
 * Component Instance and allows you to destroy the Component Instance via the {@link #destroy}
 * method.
 *
 */
export class ComponentRef extends AbstractComponentRef {
    constructor(componentType, instance, location, _rootLView, _tNode) {
        super();
        this.location = location;
        this._rootLView = _rootLView;
        this._tNode = _tNode;
        this.previousInputValues = null;
        this.instance = instance;
        this.hostView = this.changeDetectorRef = new RootViewRef(_rootLView);
        this.componentType = componentType;
    }
    setInput(name, value) {
        const inputData = this._tNode.inputs;
        let dataValue;
        if (inputData !== null && (dataValue = inputData[name])) {
            this.previousInputValues ??= new Map();
            // Do not set the input if it is the same as the last value
            // This behavior matches `bindingUpdated` when binding inputs in templates.
            if (this.previousInputValues.has(name) &&
                Object.is(this.previousInputValues.get(name), value)) {
                return;
            }
            const lView = this._rootLView;
            setInputsForProperty(lView[TVIEW], lView, dataValue, name, value);
            this.previousInputValues.set(name, value);
            const childComponentLView = getComponentLViewByIndex(this._tNode.index, lView);
            markViewDirty(childComponentLView);
        }
        else {
            if (ngDevMode) {
                const cmpNameForError = stringifyForError(this.componentType);
                let message = `Can't set value of the '${name}' input on the '${cmpNameForError}' component. `;
                message += `Make sure that the '${name}' property is annotated with @Input() or a mapped @Input('${name}') exists.`;
                reportUnknownPropertyError(message);
            }
        }
    }
    get injector() {
        return new NodeInjector(this._tNode, this._rootLView);
    }
    destroy() {
        this.hostView.destroy();
    }
    onDestroy(callback) {
        this.hostView.onDestroy(callback);
    }
}
// TODO: A hack to not pull in the NullInjector from @angular/core.
export const NULL_INJECTOR = {
    get: (token, notFoundValue) => {
        throwProviderNotFoundError(token, 'NullInjector');
    }
};
/** Creates a TNode that can be used to instantiate a root component. */
function createRootComponentTNode(lView, rNode) {
    const tView = lView[TVIEW];
    const index = HEADER_OFFSET;
    ngDevMode && assertIndexInRange(lView, index);
    lView[index] = rNode;
    // '#host' is added here as we don't know the real host DOM name (we don't want to read it) and at
    // the same time we want to communicate the debug `TNode` that this is a special `TNode`
    // representing a host element.
    return getOrCreateTNode(tView, index, 2 /* TNodeType.Element */, '#host', null);
}
/**
 * Creates the root component view and the root component node.
 *
 * @param hostRNode Render host element.
 * @param rootComponentDef ComponentDef
 * @param rootView The parent view where the host node is stored
 * @param rendererFactory Factory to be used for creating child renderers.
 * @param hostRenderer The current renderer
 * @param sanitizer The sanitizer, if provided
 *
 * @returns Component view created
 */
function createRootComponentView(tNode, hostRNode, rootComponentDef, rootDirectives, rootView, environment, hostRenderer) {
    const tView = rootView[TVIEW];
    applyRootComponentStyling(rootDirectives, tNode, hostRNode, hostRenderer);
    // Hydration info is on the host element and needs to be retreived
    // and passed to the component LView.
    let hydrationInfo = null;
    if (hostRNode !== null) {
        hydrationInfo = retrieveHydrationInfo(hostRNode, rootView[INJECTOR]);
    }
    const viewRenderer = environment.rendererFactory.createRenderer(hostRNode, rootComponentDef);
    const componentView = createLView(rootView, getOrCreateComponentTView(rootComponentDef), null, rootComponentDef.onPush ? 64 /* LViewFlags.Dirty */ : 16 /* LViewFlags.CheckAlways */, rootView[tNode.index], tNode, environment, viewRenderer, null, null, hydrationInfo);
    if (tView.firstCreatePass) {
        markAsComponentHost(tView, tNode, rootDirectives.length - 1);
    }
    addToViewTree(rootView, componentView);
    // Store component view at node index, with node as the HOST
    return rootView[tNode.index] = componentView;
}
/** Sets up the styling information on a root component. */
function applyRootComponentStyling(rootDirectives, tNode, rNode, hostRenderer) {
    for (const def of rootDirectives) {
        tNode.mergedAttrs = mergeHostAttrs(tNode.mergedAttrs, def.hostAttrs);
    }
    if (tNode.mergedAttrs !== null) {
        computeStaticStyling(tNode, tNode.mergedAttrs, true);
        if (rNode !== null) {
            setupStaticAttributes(hostRenderer, rNode, tNode);
        }
    }
}
/**
 * Creates a root component and sets it up with features and host bindings.Shared by
 * renderComponent() and ViewContainerRef.createComponent().
 */
function createRootComponent(componentView, rootComponentDef, rootDirectives, hostDirectiveDefs, rootLView, hostFeatures) {
    const rootTNode = getCurrentTNode();
    ngDevMode && assertDefined(rootTNode, 'tNode should have been already created');
    const tView = rootLView[TVIEW];
    const native = getNativeByTNode(rootTNode, rootLView);
    initializeDirectives(tView, rootLView, rootTNode, rootDirectives, null, hostDirectiveDefs);
    for (let i = 0; i < rootDirectives.length; i++) {
        const directiveIndex = rootTNode.directiveStart + i;
        const directiveInstance = getNodeInjectable(rootLView, tView, directiveIndex, rootTNode);
        attachPatchData(directiveInstance, rootLView);
    }
    invokeDirectivesHostBindings(tView, rootLView, rootTNode);
    if (native) {
        attachPatchData(native, rootLView);
    }
    // We're guaranteed for the `componentOffset` to be positive here
    // since a root component always matches a component def.
    ngDevMode &&
        assertGreaterThan(rootTNode.componentOffset, -1, 'componentOffset must be great than -1');
    const component = getNodeInjectable(rootLView, tView, rootTNode.directiveStart + rootTNode.componentOffset, rootTNode);
    componentView[CONTEXT] = rootLView[CONTEXT] = component;
    if (hostFeatures !== null) {
        for (const feature of hostFeatures) {
            feature(component, rootComponentDef);
        }
    }
    // We want to generate an empty QueryList for root content queries for backwards
    // compatibility with ViewEngine.
    executeContentQueries(tView, rootTNode, componentView);
    return component;
}
/** Sets the static attributes on a root component. */
function setRootNodeAttributes(hostRenderer, componentDef, hostRNode, rootSelectorOrNode) {
    if (rootSelectorOrNode) {
        setUpAttributes(hostRenderer, hostRNode, ['ng-version', VERSION.full]);
    }
    else {
        // If host element is created as a part of this function call (i.e. `rootSelectorOrNode`
        // is not defined), also apply attributes and classes extracted from component selector.
        // Extract attributes and classes from the first selector only to match VE behavior.
        const { attrs, classes } = extractAttrsAndClassesFromSelector(componentDef.selectors[0]);
        if (attrs) {
            setUpAttributes(hostRenderer, hostRNode, attrs);
        }
        if (classes && classes.length > 0) {
            writeDirectClass(hostRenderer, hostRNode, classes.join(' '));
        }
    }
}
/** Projects the `projectableNodes` that were specified when creating a root component. */
function projectNodes(tNode, ngContentSelectors, projectableNodes) {
    const projection = tNode.projection = [];
    for (let i = 0; i < ngContentSelectors.length; i++) {
        const nodesforSlot = projectableNodes[i];
        // Projectable nodes can be passed as array of arrays or an array of iterables (ngUpgrade
        // case). Here we do normalize passed data structure to be an array of arrays to avoid
        // complex checks down the line.
        // We also normalize the length of the passed in projectable nodes (to match the number of
        // <ng-container> slots defined by a component).
        projection.push(nodesforSlot != null ? Array.from(nodesforSlot) : null);
    }
}
/**
 * Used to enable lifecycle hooks on the root component.
 *
 * Include this feature when calling `renderComponent` if the root component
 * you are rendering has lifecycle hooks defined. Otherwise, the hooks won't
 * be called properly.
 *
 * Example:
 *
 * ```
 * renderComponent(AppComponent, {hostFeatures: [LifecycleHooksFeature]});
 * ```
 */
export function LifecycleHooksFeature() {
    const tNode = getCurrentTNode();
    ngDevMode && assertDefined(tNode, 'TNode is required');
    registerPostOrderHooks(getLView()[TVIEW], tNode);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29tcG9uZW50X3JlZi5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3JlbmRlcjMvY29tcG9uZW50X3JlZi50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTs7Ozs7O0dBTUc7QUFJSCxPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUcvRCxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUN0RCxPQUFPLEVBQUMsWUFBWSxFQUFtQixNQUFNLFdBQVcsQ0FBQztBQUV6RCxPQUFPLEVBQUMscUJBQXFCLEVBQUMsTUFBTSxvQkFBb0IsQ0FBQztBQUV6RCxPQUFPLEVBQUMsZ0JBQWdCLElBQUksd0JBQXdCLEVBQUUsWUFBWSxJQUFJLG9CQUFvQixFQUFDLE1BQU0sNkJBQTZCLENBQUM7QUFDL0gsT0FBTyxFQUFDLHdCQUF3QixJQUFJLGdDQUFnQyxFQUFDLE1BQU0sc0NBQXNDLENBQUM7QUFDbEgsT0FBTyxFQUFDLGdCQUFnQixFQUFhLE1BQU0sdUJBQXVCLENBQUM7QUFFbkUsT0FBTyxFQUFZLGdCQUFnQixFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQzFELE9BQU8sRUFBQyxTQUFTLEVBQUMsTUFBTSwyQkFBMkIsQ0FBQztBQUNwRCxPQUFPLEVBQUMsYUFBYSxFQUFFLGlCQUFpQixFQUFFLGtCQUFrQixFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFDcEYsT0FBTyxFQUFDLE9BQU8sRUFBQyxNQUFNLFlBQVksQ0FBQztBQUNuQyxPQUFPLEVBQUMscUNBQXFDLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUU3RSxPQUFPLEVBQUMsbUJBQW1CLEVBQUMsTUFBTSxVQUFVLENBQUM7QUFDN0MsT0FBTyxFQUFDLGVBQWUsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBQ3BELE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSxjQUFjLENBQUM7QUFDN0Ms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QUM7QUFFRDs7Ozs7Ozs7Ozs7O0dBWUc7QUFDSCxNQUFNLFVBQVUscUJBQXFCO0lBQ25DLE1BQU0sS0FBSyxHQUFHLGVBQWUsRUFBRyxDQUFDO0lBQ2pDLFNBQVMsSUFBSSxhQUFhLENBQUMsS0FBSyxFQUFFLG1CQUFtQixDQUFDLENBQUM7SUFDdkQsc0JBQXNCLENBQUMsUUFBUSxFQUFFLENBQUMsS0FBSyxDQUFDLEVBQUUsS0FBSyxDQUFDLENBQUM7QUFDbkQsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGxpY2Vuc2VcbiAqIENvcHlyaWdodCBHb29nbGUgTExDIEFsbCBSaWdodHMgUmVzZXJ2ZWQuXG4gKlxuICogVXNlIG9mIHRoaXMgc291cmNlIGNvZGUgaXMgZ292ZXJuZWQgYnkgYW4gTUlULXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmVcbiAqIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgYXQgaHR0cHM6Ly9hbmd1bGFyLmlvL2xpY2Vuc2VcbiAqL1xuXG5pbXBvcnQge0NoYW5nZURldGVjdG9yUmVmfSBmcm9tICcuLi9jaGFuZ2VfZGV0ZWN0aW9uL2NoYW5nZV9kZXRlY3Rvcl9yZWYnO1xuaW1wb3J0IHtJbmplY3Rvcn0gZnJvbSAnLi4vZGkvaW5qZWN0b3InO1xuaW1wb3J0IHtjb252ZXJ0VG9CaXRGbGFnc30gZnJvbSAnLi4vZGkvaW5qZWN0b3JfY29tcGF0aWJpbGl0eSc7XG5pbXBvcnQge0luamVjdEZsYWdzLCBJbmplY3RPcHRpb25zfSBmcm9tICcuLi9kaS9pbnRlcmZhY2UvaW5qZWN0b3InO1xuaW1wb3J0IHtQcm92aWRlclRva2VufSBmcm9tICcuLi9kaS9wcm92aWRlcl90b2tlbic7XG5pbXBvcnQge0Vudmlyb25tZW50SW5qZWN0b3J9IGZyb20gJy4uL2RpL3IzX2luamVjdG9yJztcbmltcG9ydCB7UnVudGltZUVycm9yLCBSdW50aW1lRXJyb3JDb2RlfSBmcm9tICcuLi9lcnJvcnMnO1xuaW1wb3J0IHtEZWh5ZHJhdGVkVmlld30gZnJvbSAnLi4vaHlkcmF0aW9uL2ludGVyZmFjZXMnO1xuaW1wb3J0IHtyZXRyaWV2ZUh5ZHJhdGlvbkluZm99IGZyb20gJy4uL2h5ZHJhdGlvbi91dGlscyc7XG5pbXBvcnQge1R5cGV9IGZyb20gJy4uL2ludGVyZmFjZS90eXBlJztcbmltcG9ydCB7Q29tcG9uZW50RmFjdG9yeSBhcyBBYnN0cmFjdENvbXBvbmVudEZhY3RvcnksIENvbXBvbmVudFJlZiBhcyBBYnN0cmFjdENvbXBvbmVudFJlZn0gZnJvbSAnLi4vbGlua2VyL2NvbXBvbmVudF9mYWN0b3J5JztcbmltcG9ydCB7Q29tcG9uZW50RmFjdG9yeVJlc29sdmVyIGFzIEFic3RyYWN0Q29tcG9uZW50RmFjdG9yeVJlc29sdmVyfSBmcm9tICcuLi9saW5rZXIvY29tcG9uZW50X2ZhY3RvcnlfcmVzb2x2ZXInO1xuaW1wb3J0IHtjcmVhdGVFbGVtZW50UmVmLCBFbGVtZW50UmVmfSBmcm9tICcuLi9saW5rZXIvZWxlbWVudF9yZWYnO1xuaW1wb3J0IHtOZ01vZHVsZVJlZn0gZnJvbSAnLi4vbGlua2VyL25nX21vZHVsZV9mYWN0b3J5JztcbmltcG9ydCB7UmVuZGVyZXIyLCBSZW5kZXJlckZhY3RvcnkyfSBmcm9tICcuLi9yZW5kZXIvYXBpJztcbmltcG9ydCB7U2FuaXRpemVyfSBmcm9tICcuLi9zYW5pdGl6YXRpb24vc2FuaXRpemVyJztcbmltcG9ydCB7YXNzZXJ0RGVmaW5lZCwgYXNzZXJ0R3JlYXRlclRoYW4sIGFzc2VydEluZGV4SW5SYW5nZX0gZnJvbSAnLi4vdXRpbC9hc3NlcnQnO1xuaW1wb3J0IHtWRVJTSU9OfSBmcm9tICcuLi92ZXJzaW9uJztcbmltcG9ydCB7Tk9UX0ZPVU5EX0NIRUNLX09OTFlfRUxFTUVOVF9JTkpFQ1RPUn0gZnJvbSAnLi4vdmlldy9wcm92aWRlcl9mbGFncyc7XG5cbmltcG9ydCB7YXNzZXJ0Q29tcG9uZW50VHlwZX0gZnJvbSAnLi9hc3NlcnQnO1xuaW1wb3J0IHthdHRhY2hQYXRjaERhdGF9IGZyb20gJy4vY29udGV4dF9kaXNjb3ZlcnknO1xuaW1wb3J0IHtnZXRDb21wb25lbnREZWZ9IGZyb20gJy4vZGVmaW5pdGlvbic7XG5pbXBvcnQge2dldE5vZGVJbmplY3RhYmxlLCBOb2RlSW5qZWN0b3J9IGZyb20gJy4vZGknO1xuaW1wb3J0IHt0aHJvd1Byb3ZpZGVyTm90Rm91bmRFcnJvcn0gZnJvbSAnLi9lcnJvcnNfZGknO1xuaW1wb3J0IHtyZWdpc3RlclBvc3RPcmRlckhvb2tzfSBmcm9tICcuL2hvb2tzJztcbmltcG9ydCB7cmVwb3J0VW5rbm93blByb3BlcnR5RXJyb3J9IGZyb20gJy4vaW5zdHJ1Y3Rpb25zL2VsZW1lbnRfdmFsaWRhdGlvbic7XG5pbXBvcnQge21hcmtWaWV3RGlydHl9IGZyb20gJy4vaW5zdHJ1Y3Rpb25zL21hcmtfdmlld19kaXJ0eSc7XG5pbXBvcnQge3JlbmRlclZpZXd9IGZyb20gJy4vaW5zdHJ1Y3Rpb25zL3JlbmRlcic7XG5pbXBvcnQge2FkZFRvVmlld1RyZWUsIGNyZWF0ZUxWaWV3LCBjcmVhdGVUVmlldywgZXhlY3V0ZUNvbnRlbnRRdWVyaWVzLCBnZXRPckNyZWF0ZUNvbXBvbmVudFRWaWV3LCBnZXRPckNyZWF0ZVROb2RlLCBpbml0aWFsaXplRGlyZWN0aXZlcywgaW52b2tlRGlyZWN0aXZlc0hvc3RCaW5kaW5ncywgbG9jYXRlSG9zdEVsZW1lbnQsIG1hcmtBc0NvbXBvbmVudEhvc3QsIHNldElucHV0c0ZvclByb3BlcnR5fSBmcm9tICcuL2luc3RydWN0aW9ucy9zaGFyZWQnO1xuaW1wb3J0IHtDb21wb25lbnREZWYsIERpcmVjdGl2ZURlZiwgSG9zdERpcmVjdGl2ZURlZnN9IGZyb20gJy4vaW50ZXJmYWNlcy9kZWZpbml0aW9uJztcbmltcG9ydCB7UHJvcGVydHlBbGlhc1ZhbHVlLCBUQ29udGFpbmVyTm9kZSwgVEVsZW1lbnRDb250YWluZXJOb2RlLCBURWxlbWVudE5vZGUsIFROb2RlLCBUTm9kZVR5cGV9IGZyb20gJy4vaW50ZXJmYWNlcy9ub2RlJztcbmltcG9ydCB7UmVuZGVyZXJ9IGZyb20gJy4vaW50ZXJmYWNlcy9yZW5kZXJlcic7XG5pbXBvcnQge1JFbGVtZW50LCBSTm9kZX0gZnJvbSAnLi9pbnRlcmZhY2VzL3JlbmRlcmVyX2RvbSc7XG5pbXBvcnQge0NPTlRFWFQsIEhFQURFUl9PRkZTRVQsIElOSkVDVE9SLCBMVmlldywgTFZpZXdFbnZpcm9ubWVudCwgTFZpZXdGbGFncywgVFZJRVcsIFRWaWV3VHlwZX0gZnJvbSAnLi9pbnRlcmZhY2VzL3ZpZXcnO1xuaW1wb3J0IHtNQVRIX01MX05BTUVTUEFDRSwgU1ZHX05BTUVTUEFDRX0gZnJvbSAnLi9uYW1lc3BhY2VzJztcbmltcG9ydCB7Y3JlYXRlRWxlbWVudE5vZGUsIHNldHVwU3RhdGljQXR0cmlidXRlcywgd3JpdGVEaXJlY3RDbGFzc30gZnJvbSAnLi9ub2RlX21hbmlwdWxhdGlvbic7XG5pbXBvcnQge2V4dHJhY3RBdHRyc0FuZENsYXNzZXNGcm9tU2VsZWN0b3IsIHN0cmluZ2lmeUNTU1NlbGVjdG9yTGlzdH0gZnJvbSAnLi9ub2RlX3NlbGVjdG9yX21hdGNoZXInO1xuaW1wb3J0IHtFZmZlY3RNYW5hZ2VyfSBmcm9tICcuL3JlYWN0aXZpdHkvZWZmZWN0JztcbmltcG9ydCB7ZW50ZXJWaWV3LCBnZXRDdXJyZW50VE5vZGUsIGdldExWaWV3LCBsZWF2ZVZpZXd9IGZyb20gJy4vc3RhdGUnO1xuaW1wb3J0IHtjb21wdXRlU3RhdGljU3R5bGluZ30gZnJvbSAnLi9zdHlsaW5nL3N0YXRpY19zdHlsaW5nJztcbmltcG9ydCB7bWVyZ2VIb3N0QXR0cnMsIHNldFVwQXR0cmlidXRlc30gZnJvbSAnLi91dGlsL2F0dHJzX3V0aWxzJztcbmltcG9ydCB7c3RyaW5naWZ5Rm9yRXJyb3J9IGZyb20gJy4vdXRpbC9zdHJpbmdpZnlfdXRpbHMnO1xuaW1wb3J0IHtnZXRDb21wb25lbnRMVmlld0J5SW5kZXgsIGdldE5hdGl2ZUJ5VE5vZGUsIGdldFROb2RlfSBmcm9tICcuL3V0aWwvdmlld191dGlscyc7XG5pbXBvcnQge1Jvb3RWaWV3UmVmLCBWaWV3UmVmfSBmcm9tICcuL3ZpZXdfcmVmJztcblxuZXhwb3J0IGNsYXNzIENvbXBvbmVudEZhY3RvcnlSZXNvbHZlciBleHRlbmRzIEFic3RyYWN0Q29tcG9uZW50RmFjdG9yeVJlc29sdmVyIHtcbiAgLyoqXG4gICAqIEBwYXJhbSBuZ01vZHVsZSBUaGUgTmdNb2R1bGVSZWYgdG8gd2hpY2ggYWxsIHJlc29sdmVkIGZhY3RvcmllcyBhcmUgYm91bmQuXG4gICAqL1xuICBjb25zdHJ1Y3Rvcihwcml2YXRlIG5nTW9kdWxlPzogTmdNb2R1bGVSZWY8YW55Pikge1xuICAgIHN1cGVyKCk7XG4gIH1cblxuICBvdmVycmlkZSByZXNvbHZlQ29tcG9uZW50RmFjdG9yeTxUPihjb21wb25lbnQ6IFR5cGU8VD4pOiBBYnN0cmFjdENvbXBvbmVudEZhY3Rvcnk8VD4ge1xuICAgIG5nRGV2TW9kZSAmJiBhc3NlcnRDb21wb25lbnRUeXBlKGNvbXBvbmVudCk7XG4gICAgY29uc3QgY29tcG9uZW50RGVmID0gZ2V0Q29tcG9uZW50RGVmKGNvbXBvbmVudCkhO1xuICAgIHJldHVybiBuZXcgQ29tcG9uZW50RmFjdG9yeShjb21wb25lbnREZWYsIHRoaXMubmdNb2R1bGUpO1xuICB9XG59XG5cbmZ1bmN0aW9uIHRvUmVmQXJyYXkobWFwOiB7W2tleTogc3RyaW5nXTogc3RyaW5nfSk6IHtwcm9wTmFtZTogc3RyaW5nOyB0ZW1wbGF0ZU5hbWU6IHN0cmluZzt9W10ge1xuICBjb25zdCBhcnJheToge3Byb3BOYW1lOiBzdHJpbmc7IHRlbXBsYXRlTmFtZTogc3RyaW5nO31bXSA9IFtdO1xuICBmb3IgKGxldCBub25NaW5pZmllZCBpbiBtYXApIHtcbiAgICBpZiAobWFwLmhhc093blByb3BlcnR5KG5vbk1pbmlmaWVkKSkge1xuICAgICAgY29uc3QgbWluaWZpZWQgPSBtYXBbbm9uTWluaWZpZWRdO1xuICAgICAgYXJyYXkucHVzaCh7cHJvcE5hbWU6IG1pbmlmaWVkLCB0ZW1wbGF0ZU5hbWU6IG5vbk1pbmlmaWVkfSk7XG4gICAgfVxuICB9XG4gIHJldHVybiBhcnJheTtcbn1cblxuZnVuY3Rpb24gZ2V0TmFtZXNwYWNlKGVsZW1lbnROYW1lOiBzdHJpbmcpOiBzdHJpbmd8bnVsbCB7XG4gIGNvbnN0IG5hbWUgPSBlbGVtZW50TmFtZS50b0xvd2VyQ2FzZSgpO1xuICByZXR1cm4gbmFtZSA9PT0gJ3N2ZycgPyBTVkdfTkFNRVNQQUNFIDogKG5hbWUgPT09ICdtYXRoJyA/IE1BVEhfTUxfTkFNRVNQQUNFIDogbnVsbCk7XG59XG5cbi8qKlxuICogSW5qZWN0b3IgdGhhdCBsb29rcyB1cCBhIHZhbHVlIHVzaW5nIGEgc3BlY2lmaWMgaW5qZWN0b3IsIGJlZm9yZSBmYWxsaW5nIGJhY2sgdG8gdGhlIG1vZHVsZVxuICogaW5qZWN0b3IuIFVzZWQgcHJpbWFyaWx5IHdoZW4gY3JlYXRpbmcgY29tcG9uZW50cyBvciBlbWJlZGRlZCB2aWV3cyBkeW5hbWljYWxseS5cbiAqL1xuY2xhc3MgQ2hhaW5lZEluamVjdG9yIGltcGxlbWVudHMgSW5qZWN0b3Ige1xuICBjb25zdHJ1Y3Rvcihwcml2YXRlIGluamVjdG9yOiBJbmplY3RvciwgcHJpdmF0ZSBwYXJlbnRJbmplY3RvcjogSW5qZWN0b3IpIHt9XG5cbiAgZ2V0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgZmxhZ3M/OiBJbmplY3RGbGFnc3xJbmplY3RPcHRpb25zKTogVCB7XG4gICAgZmxhZ3MgPSBjb252ZXJ0VG9CaXRGbGFncyhmbGFncyk7XG4gICAgY29uc3QgdmFsdWUgPSB0aGlzLmluamVjdG9yLmdldDxUfHR5cGVvZiBOT1RfRk9VTkRfQ0hFQ0tfT05MWV9FTEVNRU5UX0lOSkVDVE9SPihcbiAgICAgICAgdG9rZW4sIE5PVF9GT1VORF9DSEVDS19PTkxZX0VMRU1FTlRfSU5KRUNUT1IsIGZsYWdzKTtcblxuICAgIGlmICh2YWx1ZSAhPT0gTk9UX0ZPVU5EX0NIRUNLX09OTFlfRUxFTUVOVF9JTkpFQ1RPUiB8fFxuICAgICAgICBub3RGb3VuZFZhbHVlID09PSAoTk9UX0ZPVU5EX0NIRUNLX09OTFlfRUxFTUVOVF9JTkpFQ1RPUiBhcyB1bmtub3duIGFzIFQpKSB7XG4gICAgICAvLyBSZXR1cm4gdGhlIHZhbHVlIGZyb20gdGhlIHJvb3QgZWxlbWVudCBpbmplY3RvciB3aGVuXG4gICAgICAvLyAtIGl0IHByb3ZpZGVzIGl0XG4gICAgICAvLyAgICh2YWx1ZSAhPT0gTk9UX0ZPVU5EX0NIRUNLX09OTFlfRUxFTUVOVF9JTkpFQ1RPUilcbiAgICAgIC8vIC0gdGhlIG1vZHVsZSBpbmplY3RvciBzaG91bGQgbm90IGJlIGNoZWNrZWRcbiAgICAgIC8vICAgKG5vdEZvdW5kVmFsdWUgPT09IE5PVF9GT1VORF9DSEVDS19PTkxZX0VMRU1FTlRfSU5KRUNUT1IpXG4gICAgICByZXR1cm4gdmFsdWUgYXMgVDtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcy5wYXJlbnRJbmplY3Rvci5nZXQodG9rZW4sIG5vdEZvdW5kVmFsdWUsIGZsYWdzKTtcbiAgfVxufVxuXG4vKipcbiAqIENvbXBvbmVudEZhY3RvcnkgaW50ZXJmYWNlIGltcGxlbWVudGF0aW9uLlxuICovXG5leHBvcnQgY2xhc3MgQ29tcG9uZW50RmFjdG9yeTxUPiBleHRlbmRzIEFic3RyYWN0Q29tcG9uZW50RmFjdG9yeTxUPiB7XG4gIG92ZXJyaWRlIHNlbGVjdG9yOiBzdHJpbmc7XG4gIG92ZXJyaWRlIGNvbXBvbmVudFR5cGU6IFR5cGU8YW55PjtcbiAgb3ZlcnJpZGUgbmdDb250ZW50U2VsZWN0b3JzOiBzdHJpbmdbXTtcbiAgaXNCb3VuZFRvTW9kdWxlOiBib29sZWFuO1xuXG4gIG92ZXJyaWRlIGdldCBpbnB1dHMoKToge3Byb3BOYW1lOiBzdHJpbmc7IHRlbXBsYXRlTmFtZTogc3RyaW5nO31bXSB7XG4gICAgcmV0dXJuIHRvUmVmQXJyYXkodGhpcy5jb21wb25lbnREZWYuaW5wdXRzKTtcbiAgfVxuXG4gIG92ZXJyaWRlIGdldCBvdXRwdXRzKCk6IHtwcm9wTmFtZTogc3RyaW5nOyB0ZW1wbGF0ZU5hbWU6IHN0cmluZzt9W10ge1xuICAgIHJldHVybiB0b1JlZkFycmF5KHRoaXMuY29tcG9uZW50RGVmLm91dHB1dHMpO1xuICB9XG5cbiAgLyoqXG4gICAqIEBwYXJhbSBjb21wb25lbnREZWYgVGhlIGNvbXBvbmVudCBkZWZpbml0aW9uLlxuICAgKiBAcGFyYW0gbmdNb2R1bGUgVGhlIE5nTW9kdWxlUmVmIHRvIHdoaWNoIHRoZSBmYWN0b3J5IGlzIGJvdW5kLlxuICAgKi9cbiAgY29uc3RydWN0b3IocHJpdmF0ZSBjb21wb25lbnREZWY6IENvbXBvbmVudERlZjxhbnk+LCBwcml2YXRlIG5nTW9kdWxlPzogTmdNb2R1bGVSZWY8YW55Pikge1xuICAgIHN1cGVyKCk7XG4gICAgdGhpcy5jb21wb25lbnRUeXBlID0gY29tcG9uZW50RGVmLnR5cGU7XG4gICAgdGhpcy5zZWxlY3RvciA9IHN0cmluZ2lmeUNTU1NlbGVjdG9yTGlzdChjb21wb25lbnREZWYuc2VsZWN0b3JzKTtcbiAgICB0aGlzLm5nQ29udGVudFNlbGVjdG9ycyA9XG4gICAgICAgIGNvbXBvbmVudERlZi5uZ0NvbnRlbnRTZWxlY3RvcnMgPyBjb21wb25lbnREZWYubmdDb250ZW50U2VsZWN0b3JzIDogW107XG4gICAgdGhpcy5pc0JvdW5kVG9Nb2R1bGUgPSAhIW5nTW9kdWxlO1xuICB9XG5cbiAgb3ZlcnJpZGUgY3JlYXRlKFxuICAgICAgaW5qZWN0b3I6IEluamVjdG9yLCBwcm9qZWN0YWJsZU5vZGVzPzogYW55W11bXXx1bmRlZmluZWQsIHJvb3RTZWxlY3Rvck9yTm9kZT86IGFueSxcbiAgICAgIGVudmlyb25tZW50SW5qZWN0b3I/OiBOZ01vZHVsZVJlZjxhbnk+fEVudmlyb25tZW50SW5qZWN0b3J8XG4gICAgICB1bmRlZmluZWQpOiBBYnN0cmFjdENvbXBvbmVudFJlZjxUPiB7XG4gICAgZW52aXJvbm1lbnRJbmplY3RvciA9IGVudmlyb25tZW50SW5qZWN0b3IgfHwgdGhpcy5uZ01vZHVsZTtcblxuICAgIGxldCByZWFsRW52aXJvbm1lbnRJbmplY3RvciA9IGVudmlyb25tZW50SW5qZWN0b3IgaW5zdGFuY2VvZiBFbnZpcm9ubWVudEluamVjdG9yID9cbiAgICAgICAgZW52aXJvbm1lbnRJbmplY3RvciA6XG4gICAgICAgIGVudmlyb25tZW50SW5qZWN0b3I/LmluamVjdG9yO1xuXG4gICAgaWYgKHJlYWxFbnZpcm9ubWVudEluamVjdG9yICYmIHRoaXMuY29tcG9uZW50RGVmLmdldFN0YW5kYWxvbmVJbmplY3RvciAhPT0gbnVsbCkge1xuICAgICAgcmVhbEVudmlyb25tZW50SW5qZWN0b3IgPSB0aGlzLmNvbXBvbmVudERlZi5nZXRTdGFuZGFsb25lSW5qZWN0b3IocmVhbEVudmlyb25tZW50SW5qZWN0b3IpIHx8XG4gICAgICAgICAgcmVhbEVudmlyb25tZW50SW5qZWN0b3I7XG4gICAgfVxuXG4gICAgY29uc3Qgcm9vdFZpZXdJbmplY3RvciA9XG4gICAgICAgIHJlYWxFbnZpcm9ubWVudEluamVjdG9yID8gbmV3IENoYWluZWRJbmplY3RvcihpbmplY3RvciwgcmVhbEVudmlyb25tZW50SW5qZWN0b3IpIDogaW5qZWN0b3I7XG5cbiAgICBjb25zdCByZW5kZXJlckZhY3RvcnkgPSByb290Vmlld0luamVjdG9yLmdldChSZW5kZXJlckZhY3RvcnkyLCBudWxsKTtcbiAgICBpZiAocmVuZGVyZXJGYWN0b3J5ID09PSBudWxsKSB7XG4gICAgICB0aHJvdyBuZXcgUnVudGltZUVycm9yKFxuICAgICAgICAgIFJ1bnRpbWVFcnJvckNvZGUuUkVOREVSRVJfTk9UX0ZPVU5ELFxuICAgICAgICAgIG5nRGV2TW9kZSAmJlxuICAgICAgICAgICAgICAnQW5ndWxhciB3YXMgbm90IGFibGUgdG8gaW5qZWN0IGEgcmVuZGVyZXIgKFJlbmRlcmVyRmFjdG9yeTIpLiAnICtcbiAgICAgICAgICAgICAgICAgICdMaWtlbHkgdGhpcyBpcyBkdWUgdG8gYSBicm9rZW4gREkgaGllcmFyY2h5LiAnICtcbiAgICAgICAgICAgICAgICAgICdNYWtlIHN1cmUgdGhhdCBhbnkgaW5qZWN0b3IgdXNlZCB0byBjcmVhdGUgdGhpcyBjb21wb25lbnQgaGFzIGEgY29ycmVjdCBwYXJlbnQuJyk7XG4gICAgfVxuICAgIGNvbnN0IHNhbml0aXplciA9IHJvb3RWaWV3SW5qZWN0b3IuZ2V0KFNhbml0aXplciwgbnVsbCk7XG5cbiAgICBjb25zdCBlZmZlY3RNYW5hZ2VyID0gcm9vdFZpZXdJbmplY3Rvci5nZXQoRWZmZWN0TWFuYWdlciwgbnVsbCk7XG5cbiAgICBjb25zdCBlbnZpcm9ubWVudDogTFZpZXdFbnZpcm9ubWVudCA9IHtcbiAgICAgIHJlbmRlcmVyRmFjdG9yeSxcbiAgICAgIHNhbml0aXplcixcbiAgICAgIGVmZmVjdE1hbmFnZXIsXG4gICAgfTtcblxuICAgIGNvbnN0IGhvc3RSZW5kZXJlciA9IHJlbmRlcmVyRmFjdG9yeS5jcmVhdGVSZW5kZXJlcihudWxsLCB0aGlzLmNvbXBvbmVudERlZik7XG4gICAgLy8gRGV0ZXJtaW5lIGEgdGFnIG5hbWUgdXNlZCBmb3IgY3JlYXRpbmcgaG9zdCBlbGVtZW50cyB3aGVuIHRoaXMgY29tcG9uZW50IGlzIGNyZWF0ZWRcbiAgICAvLyBkeW5hbWljYWxseS4gRGVmYXVsdCB0byAnZGl2JyBpZiB0aGlzIGNvbXBvbmVudCBkaWQgbm90IHNwZWNpZnkgYW55IHRhZyBuYW1lIGluIGl0cyBzZWxlY3Rvci5cbiAgICBjb25zdCBlbGVtZW50TmFtZSA9IHRoaXMuY29tcG9uZW50RGVmLnNlbGVjdG9yc1swXVswXSBhcyBzdHJpbmcgfHwgJ2Rpdic7XG4gICAgY29uc3QgaG9zdFJOb2RlID0gcm9vdFNlbGVjdG9yT3JOb2RlID9cbiAgICAgICAgbG9jYXRlSG9zdEVsZW1lbnQoXG4gICAgICAgICAgICBob3N0UmVuZGVyZXIsIHJvb3RTZWxlY3Rvck9yTm9kZSwgdGhpcy5jb21wb25lbnREZWYuZW5jYXBzdWxhdGlvbiwgcm9vdFZpZXdJbmplY3RvcikgOlxuICAgICAgICBjcmVhdGVFbGVtZW50Tm9kZShob3N0UmVuZGVyZXIsIGVsZW1lbnROYW1lLCBnZXROYW1lc3BhY2UoZWxlbWVudE5hbWUpKTtcblxuICAgIGNvbnN0IHJvb3RGbGFncyA9IHRoaXMuY29tcG9uZW50RGVmLm9uUHVzaCA/IExWaWV3RmxhZ3MuRGlydHkgfCBMVmlld0ZsYWdzLklzUm9vdCA6XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgTFZpZXdGbGFncy5DaGVja0Fsd2F5cyB8IExWaWV3RmxhZ3MuSXNSb290O1xuXG4gICAgLy8gQ3JlYXRlIHRoZSByb290IHZpZXcuIFVzZXMgZW1wdHkgVFZpZXcgYW5kIENvbnRlbnRUZW1wbGF0ZS5cbiAgICBjb25zdCByb290VFZpZXcgPVxuICAgICAgICBjcmVhdGVUVmlldyhUVmlld1R5cGUuUm9vdCwgbnVsbCwgbnVsbCwgMSwgMCwgbnVsbCwgbnVsbCwgbnVsbCwgbnVsbCwgbnVsbCwgbnVsbCk7XG4gICAgY29uc3Qgcm9vdExWaWV3ID0gY3JlYXRlTFZpZXcoXG4gICAgICAgIG51bGwsIHJvb3RUVmlldywgbnVsbCwgcm9vdEZsYWdzLCBudWxsLCBudWxsLCBlbnZpcm9ubWVudCwgaG9zdFJlbmRlcmVyLCByb290Vmlld0luamVjdG9yLFxuICAgICAgICBudWxsLCBudWxsKTtcblxuICAgIC8vIHJvb3RWaWV3IGlzIHRoZSBwYXJlbnQgd2hlbiBib290c3RyYXBwaW5nXG4gICAgLy8gVE9ETyhtaXNrbyk6IGl0IGxvb2tzIGxpa2Ugd2UgYXJlIGVudGVyaW5nIHZpZXcgaGVyZSBidXQgd2UgZG9uJ3QgcmVhbGx5IG5lZWQgdG8gYXNcbiAgICAvLyBgcmVuZGVyVmlld2AgZG9lcyB0aGF0LiBIb3dldmVyIGFzIHRoZSBjb2RlIGlzIHdyaXR0ZW4gaXQgaXMgbmVlZGVkIGJlY2F1c2VcbiAgICAvLyBgY3JlYXRlUm9vdENvbXBvbmVudFZpZXdgIGFuZCBgY3JlYXRlUm9vdENvbXBvbmVudGAgYm90aCByZWFkIGdsb2JhbCBzdGF0ZS4gRml4aW5nIHRob3NlXG4gICAgLy8gaXNzdWVzIHdvdWxkIGFsbG93IHVzIHRvIGRyb3AgdGhpcy5cbiAgICBlbnRlclZpZXcocm9vdExWaWV3KTtcblxuICAgIGxldCBjb21wb25lbnQ6IFQ7XG4gICAgbGV0IHRFbGVtZW50Tm9kZTogVEVsZW1lbnROb2RlO1xuXG4gICAgdHJ5IHtcbiAgICAgIGNvbnN0IHJvb3RDb21wb25lbnREZWYgPSB0aGlzLmNvbXBvbmVudERlZjtcbiAgICAgIGxldCByb290RGlyZWN0aXZlczogRGlyZWN0aXZlRGVmPHVua25vd24+W107XG4gICAgICBsZXQgaG9zdERpcmVjdGl2ZURlZnM6IEhvc3REaXJlY3RpdmVEZWZzfG51bGwgPSBudWxsO1xuXG4gICAgICBpZiAocm9vdENvbXBvbmVudERlZi5maW5kSG9zdERpcmVjdGl2ZURlZnMpIHtcbiAgICAgICAgcm9vdERpcmVjdGl2ZXMgPSBbXTtcbiAgICAgICAgaG9zdERpcmVjdGl2ZURlZnMgPSBuZXcgTWFwKCk7XG4gICAgICAgIHJvb3RDb21wb25lbnREZWYuZmluZEhvc3REaXJlY3RpdmVEZWZzKHJvb3RDb21wb25lbnREZWYsIHJvb3REaXJlY3RpdmVzLCBob3N0RGlyZWN0aXZlRGVmcyk7XG4gICAgICAgIHJvb3REaXJlY3RpdmVzLnB1c2gocm9vdENvbXBvbmVudERlZik7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByb290RGlyZWN0aXZlcyA9IFtyb290Q29tcG9uZW50RGVmXTtcbiAgICAgIH1cblxuICAgICAgY29uc3QgaG9zdFROb2RlID0gY3JlYXRlUm9vdENvbXBvbmVudFROb2RlKHJvb3RMVmlldywgaG9zdFJOb2RlKTtcbiAgICAgIGNvbnN0IGNvbXBvbmVudFZpZXcgPSBjcmVhdGVSb290Q29tcG9uZW50VmlldyhcbiAgICAgICAgICBob3N0VE5vZGUsIGhvc3RSTm9kZSwgcm9vdENvbXBvbmVudERlZiwgcm9vdERpcmVjdGl2ZXMsIHJvb3RMVmlldywgZW52aXJvbm1lbnQsXG4gICAgICAgICAgaG9zdFJlbmRlcmVyKTtcblxuICAgICAgdEVsZW1lbnROb2RlID0gZ2V0VE5vZGUocm9vdFRWaWV3LCBIRUFERVJfT0ZGU0VUKSBhcyBURWxlbWVudE5vZGU7XG5cbiAgICAgIC8vIFRPRE8oY3Jpc2JldG8pOiBpbiBwcmFjdGljZSBgaG9zdFJOb2RlYCBzaG91bGQgYWx3YXlzIGJlIGRlZmluZWQsIGJ1dCB0aGVyZSBhcmUgc29tZSB0ZXN0c1xuICAgICAgLy8gd2hlcmUgdGhlIHJlbmRlcmVyIGlzIG1vY2tlZCBvdXQgYW5kIGB1bmRlZmluZWRgIGlzIHJldHVybmVkLiBXZSBzaG91bGQgdXBkYXRlIHRoZSB0ZXN0cyBzb1xuICAgICAgLy8gdGhhdCB0aGlzIGNoZWNrIGNhbiBiZSByZW1vdmVkLlxuICAgICAgaWYgKGhvc3RSTm9kZSkge1xuICAgICAgICBzZXRSb290Tm9kZUF0dHJpYnV0ZXMoaG9zdFJlbmRlcmVyLCByb290Q29tcG9uZW50RGVmLCBob3N0Uk5vZGUsIHJvb3RTZWxlY3Rvck9yTm9kZSk7XG4gICAgICB9XG5cbiAgICAgIGlmIChwcm9qZWN0YWJsZU5vZGVzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgcHJvamVjdE5vZGVzKHRFbGVtZW50Tm9kZSwgdGhpcy5uZ0NvbnRlbnRTZWxlY3RvcnMsIHByb2plY3RhYmxlTm9kZXMpO1xuICAgICAgfVxuXG4gICAgICAvLyBUT0RPOiBzaG91bGQgTGlmZWN5Y2xlSG9va3NGZWF0dXJlIGFuZCBvdGhlciBob3N0IGZlYXR1cmVzIGJlIGdlbmVyYXRlZCBieSB0aGUgY29tcGlsZXIgYW5kXG4gICAgICAvLyBleGVjdXRlZCBoZXJlP1xuICAgICAgLy8gQW5ndWxhciA1IHJlZmVyZW5jZTogaHR0cHM6Ly9zdGFja2JsaXR6LmNvbS9lZGl0L2xpZmVjeWNsZS1ob29rcy12Y3JlZlxuICAgICAgY29tcG9uZW50ID0gY3JlYXRlUm9vdENvbXBvbmVudChcbiAgICAgICAgICBjb21wb25lbnRWaWV3LCByb290Q29tcG9uZW50RGVmLCByb290RGlyZWN0aXZlcywgaG9zdERpcmVjdGl2ZURlZnMsIHJvb3RMVmlldyxcbiAgICAgICAgICBbTGlmZWN5Y2xlSG9va3NGZWF0dXJlXSk7XG4gICAgICByZW5kZXJWaWV3KHJvb3RUVmlldywgcm9vdExWaWV3LCBudWxsKTtcbiAgICB9IGZpbmFsbHkge1xuICAgICAgbGVhdmVWaWV3KCk7XG4gICAgfVxuXG4gICAgcmV0dXJuIG5ldyBDb21wb25lbnRSZWYoXG4gICAgICAgIHRoaXMuY29tcG9uZW50VHlwZSwgY29tcG9uZW50LCBjcmVhdGVFbGVtZW50UmVmKHRFbGVtZW50Tm9kZSwgcm9vdExWaWV3KSwgcm9vdExWaWV3LFxuICAgICAgICB0RWxlbWVudE5vZGUpO1xuICB9XG59XG5cbi8qKlxuICogUmVwcmVzZW50cyBhbiBpbnN0YW5jZSBvZiBhIENvbXBvbmVudCBjcmVhdGVkIHZpYSBhIHtAbGluayBDb21wb25lbnRGYWN0b3J5fS5cbiAqXG4gKiBgQ29tcG9uZW50UmVmYCBwcm92aWRlcyBhY2Nlc3MgdG8gdGhlIENvbXBvbmVudCBJbnN0YW5jZSBhcyB3ZWxsIG90aGVyIG9iamVjdHMgcmVsYXRlZCB0byB0aGlzXG4gKiBDb21wb25lbnQgSW5zdGFuY2UgYW5kIGFsbG93cyB5b3UgdG8gZGVzdHJveSB0aGUgQ29tcG9uZW50IEluc3RhbmNlIHZpYSB0aGUge0BsaW5rICNkZXN0cm95fVxuICogbWV0aG9kLlxuICpcbiAqL1xuZXhwb3J0IGNsYXNzIENvbXBvbmVudFJlZjxUPiBleHRlbmRzIEFic3RyYWN0Q29tcG9uZW50UmVmPFQ+IHtcbiAgb3ZlcnJpZGUgaW5zdGFuY2U6IFQ7XG4gIG92ZXJyaWRlIGhvc3RWaWV3OiBWaWV3UmVmPFQ+O1xuICBvdmVycmlkZSBjaGFuZ2VEZXRlY3RvclJlZjogQ2hhbmdlRGV0ZWN0b3JSZWY7XG4gIG92ZXJyaWRlIGNvbXBvbmVudFR5cGU6IFR5cGU8VD47XG4gIHByaXZhdGUgcHJldmlvdXNJbnB1dFZhbHVlczogTWFwPHN0cmluZywgdW5rbm93bj58bnVsbCA9IG51bGw7XG5cbiAgY29uc3RydWN0b3IoXG4gICAgICBjb21wb25lbnRUeXBlOiBUeXBlPFQ+LCBpbnN0YW5jZTogVCwgcHVibGljIGxvY2F0aW9uOiBFbGVtZW50UmVmLCBwcml2YXRlIF9yb290TFZpZXc6IExWaWV3LFxuICAgICAgcHJpdmF0ZSBfdE5vZGU6IFRFbGVtZW50Tm9kZXxUQ29udGFpbmVyTm9kZXxURWxlbWVudENvbnRhaW5lck5vZGUpIHtcbiAgICBzdXBlcigpO1xuICAgIHRoaXMuaW5zdGFuY2UgPSBpbnN0YW5jZTtcbiAgICB0aGlzLmhvc3RWaWV3ID0gdGhpcy5jaGFuZ2VEZXRlY3RvclJlZiA9IG5ldyBSb290Vmlld1JlZjxUPihfcm9vdExWaWV3KTtcbiAgICB0aGlzLmNvbXBvbmVudFR5cGUgPSBjb21wb25lbnRUeXBlO1xuICB9XG5cbiAgb3ZlcnJpZGUgc2V0SW5wdXQobmFtZTogc3RyaW5nLCB2YWx1ZTogdW5rbm93bik6IHZvaWQge1xuICAgIGNvbnN0IGlucHV0RGF0YSA9IHRoaXMuX3ROb2RlLmlucHV0cztcbiAgICBsZXQgZGF0YVZhbHVlOiBQcm9wZXJ0eUFsaWFzVmFsdWV8dW5kZWZpbmVkO1xuICAgIGlmIChpbnB1dERhdGEgIT09IG51bGwgJiYgKGRhdGFWYWx1ZSA9IGlucHV0RGF0YVtuYW1lXSkpIHtcbiAgICAgIHRoaXMucHJldmlvdXNJbnB1dFZhbHVlcyA/Pz0gbmV3IE1hcCgpO1xuICAgICAgLy8gRG8gbm90IHNldCB0aGUgaW5wdXQgaWYgaXQgaXMgdGhlIHNhbWUgYXMgdGhlIGxhc3QgdmFsdWVcbiAgICAgIC8vIFRoaXMgYmVoYXZpb3IgbWF0Y2hlcyBgYmluZGluZ1VwZGF0ZWRgIHdoZW4gYmluZGluZyBpbnB1dHMgaW4gdGVtcGxhdGVzLlxuICAgICAgaWYgKHRoaXMucHJldmlvdXNJbnB1dFZhbHVlcy5oYXMobmFtZSkgJiZcbiAgICAgICAgICBPYmplY3QuaXModGhpcy5wcmV2aW91c0lucHV0VmFsdWVzLmdldChuYW1lKSwgdmFsdWUpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgY29uc3QgbFZpZXcgPSB0aGlzLl9yb290TFZpZXc7XG4gICAgICBzZXRJbnB1dHNGb3JQcm9wZXJ0eShsVmlld1tUVklFV10sIGxWaWV3LCBkYXRhVmFsdWUsIG5hbWUsIHZhbHVlKTtcbiAgICAgIHRoaXMucHJldmlvdXNJbnB1dFZhbHVlcy5zZXQobmFtZSwgdmFsdWUpO1xuICAgICAgY29uc3QgY2hpbGRDb21wb25lbnRMVmlldyA9IGdldENvbXBvbmVudExWaWV3QnlJbmRleCh0aGlzLl90Tm9kZS5pbmRleCwgbFZpZXcpO1xuICAgICAgbWFya1ZpZXdEaXJ0eShjaGlsZENvbXBvbmVudExWaWV3KTtcbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKG5nRGV2TW9kZSkge1xuICAgICAgICBjb25zdCBjbXBOYW1lRm9yRXJyb3IgPSBzdHJpbmdpZnlGb3JFcnJvcih0aGlzLmNvbXBvbmVudFR5cGUpO1xuICAgICAgICBsZXQgbWVzc2FnZSA9XG4gICAgICAgICAgICBgQ2FuJ3Qgc2V0IHZhbHVlIG9mIHRoZSAnJHtuYW1lfScgaW5wdXQgb24gdGhlICcke2NtcE5hbWVGb3JFcnJvcn0nIGNvbXBvbmVudC4gYDtcbiAgICAgICAgbWVzc2FnZSArPSBgTWFrZSBzdXJlIHRoYXQgdGhlICcke1xuICAgICAgICAgICAgbmFtZX0nIHByb3BlcnR5IGlzIGFubm90YXRlZCB3aXRoIEBJbnB1dCgpIG9yIGEgbWFwcGVkIEBJbnB1dCgnJHtuYW1lfScpIGV4aXN0cy5gO1xuICAgICAgICByZXBvcnRVbmtub3duUHJvcGVydHlFcnJvcihtZXNzYWdlKTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBvdmVycmlkZSBnZXQgaW5qZWN0b3IoKTogSW5qZWN0b3Ige1xuICAgIHJldHVybiBuZXcgTm9kZUluamVjdG9yKHRoaXMuX3ROb2RlLCB0aGlzLl9yb290TFZpZXcpO1xuICB9XG5cbiAgb3ZlcnJpZGUgZGVzdHJveSgpOiB2b2lkIHtcbiAgICB0aGlzLmhvc3RWaWV3LmRlc3Ryb3koKTtcbiAgfVxuXG4gIG92ZXJyaWRlIG9uRGVzdHJveShjYWxsYmFjazogKCkgPT4gdm9pZCk6IHZvaWQge1xuICAgIHRoaXMuaG9zdFZpZXcub25EZXN0cm95KGNhbGxiYWNrKTtcbiAgfVxufVxuXG4vKiogUmVwcmVzZW50cyBhIEhvc3RGZWF0dXJlIGZ1bmN0aW9uLiAqL1xudHlwZSBIb3N0RmVhdHVyZSA9ICg8VD4oY29tcG9uZW50OiBULCBjb21wb25lbnREZWY6IENvbXBvbmVudERlZjxUPikgPT4gdm9pZCk7XG5cbi8vIFRPRE86IEEgaGFjayB0byBub3QgcHVsbCBpbiB0aGUgTnVsbEluamVjdG9yIGZyb20gQGFuZ3VsYXIvY29yZS5cbmV4cG9ydCBjb25zdCBOVUxMX0lOSkVDVE9SOiBJbmplY3RvciA9IHtcbiAgZ2V0OiAodG9rZW46IGFueSwgbm90Rm91bmRWYWx1ZT86IGFueSkgPT4ge1xuICAgIHRocm93UHJvdmlkZXJOb3RGb3VuZEVycm9yKHRva2VuLCAnTnVsbEluamVjdG9yJyk7XG4gIH1cbn07XG5cbi8qKiBDcmVhdGVzIGEgVE5vZGUgdGhhdCBjYW4gYmUgdXNlZCB0byBpbnN0YW50aWF0ZSBhIHJvb3QgY29tcG9uZW50LiAqL1xuZnVuY3Rpb24gY3JlYXRlUm9vdENvbXBvbmVudFROb2RlKGxWaWV3OiBMVmlldywgck5vZGU6IFJOb2RlKTogVEVsZW1lbnROb2RlIHtcbiAgY29uc3QgdFZpZXcgPSBsVmlld1tUVklFV107XG4gIGNvbnN0IGluZGV4ID0gSEVBREVSX09GRlNFVDtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEluZGV4SW5SYW5nZShsVmlldywgaW5kZXgpO1xuICBsVmlld1tpbmRleF0gPSByTm9kZTtcblxuICAvLyAnI2hvc3QnIGlzIGFkZGVkIGhlcmUgYXMgd2UgZG9uJ3Qga25vdyB0aGUgcmVhbCBob3N0IERPTSBuYW1lICh3ZSBkb24ndCB3YW50IHRvIHJlYWQgaXQpIGFuZCBhdFxuICAvLyB0aGUgc2FtZSB0aW1lIHdlIHdhbnQgdG8gY29tbXVuaWNhdGUgdGhlIGRlYnVnIGBUTm9kZWAgdGhhdCB0aGlzIGlzIGEgc3BlY2lhbCBgVE5vZGVgXG4gIC8vIHJlcHJlc2VudGluZyBhIGhvc3QgZWxlbWVudC5cbiAgcmV0dXJuIGdldE9yQ3JlYXRlVE5vZGUodFZpZXcsIGluZGV4LCBUTm9kZVR5cGUuRWxlbWVudCwgJyNob3N0JywgbnVsbCk7XG59XG5cbi8qKlxuICogQ3JlYXRlcyB0aGUgcm9vdCBjb21wb25lbnQgdmlldyBhbmQgdGhlIHJvb3QgY29tcG9uZW50IG5vZGUuXG4gKlxuICogQHBhcmFtIGhvc3RSTm9kZSBSZW5kZXIgaG9zdCBlbGVtZW50LlxuICogQHBhcmFtIHJvb3RDb21wb25lbnREZWYgQ29tcG9uZW50RGVmXG4gKiBAcGFyYW0gcm9vdFZpZXcgVGhlIHBhcmVudCB2aWV3IHdoZXJlIHRoZSBob3N0IG5vZGUgaXMgc3RvcmVkXG4gKiBAcGFyYW0gcmVuZGVyZXJGYWN0b3J5IEZhY3RvcnkgdG8gYmUgdXNlZCBmb3IgY3JlYXRpbmcgY2hpbGQgcmVuZGVyZXJzLlxuICogQHBhcmFtIGhvc3RSZW5kZXJlciBUaGUgY3VycmVudCByZW5kZXJlclxuICogQHBhcmFtIHNhbml0aXplciBUaGUgc2FuaXRpemVyLCBpZiBwcm92aWRlZFxuICpcbiAqIEByZXR1cm5zIENvbXBvbmVudCB2aWV3IGNyZWF0ZWRcbiAqL1xuZnVuY3Rpb24gY3JlYXRlUm9vdENvbXBvbmVudFZpZXcoXG4gICAgdE5vZGU6IFRFbGVtZW50Tm9kZSwgaG9zdFJOb2RlOiBSRWxlbWVudHxudWxsLCByb290Q29tcG9uZW50RGVmOiBDb21wb25lbnREZWY8YW55PixcbiAgICByb290RGlyZWN0aXZlczogRGlyZWN0aXZlRGVmPGFueT5bXSwgcm9vdFZpZXc6IExWaWV3LCBlbnZpcm9ubWVudDogTFZpZXdFbnZpcm9ubWVudCxcbiAgICBob3N0UmVuZGVyZXI6IFJlbmRlcmVyKTogTFZpZXcge1xuICBjb25zdCB0VmlldyA9IHJvb3RWaWV3W1RWSUVXXTtcbiAgYXBwbHlSb290Q29tcG9uZW50U3R5bGluZyhyb290RGlyZWN0aXZlcywgdE5vZGUsIGhvc3RSTm9kZSwgaG9zdFJlbmRlcmVyKTtcblxuICAvLyBIeWRyYXRpb24gaW5mbyBpcyBvbiB0aGUgaG9zdCBlbGVtZW50IGFuZCBuZWVkcyB0byBiZSByZXRyZWl2ZWRcbiAgLy8gYW5kIHBhc3NlZCB0byB0aGUgY29tcG9uZW50IExWaWV3LlxuICBsZXQgaHlkcmF0aW9uSW5mbzogRGVoeWRyYXRlZFZpZXd8bnVsbCA9IG51bGw7XG4gIGlmIChob3N0Uk5vZGUgIT09IG51bGwpIHtcbiAgICBoeWRyYXRpb25JbmZvID0gcmV0cmlldmVIeWRyYXRpb25JbmZvKGhvc3RSTm9kZSwgcm9vdFZpZXdbSU5KRUNUT1JdISk7XG4gIH1cbiAgY29uc3Qgdmlld1JlbmRlcmVyID0gZW52aXJvbm1lbnQucmVuZGVyZXJGYWN0b3J5LmNyZWF0ZVJlbmRlcmVyKGhvc3RSTm9kZSwgcm9vdENvbXBvbmVudERlZik7XG4gIGNvbnN0IGNvbXBvbmVudFZpZXcgPSBjcmVhdGVMVmlldyhcbiAgICAgIHJvb3RWaWV3LCBnZXRPckNyZWF0ZUNvbXBvbmVudFRWaWV3KHJvb3RDb21wb25lbnREZWYpLCBudWxsLFxuICAgICAgcm9vdENvbXBvbmVudERlZi5vblB1c2ggPyBMVmlld0ZsYWdzLkRpcnR5IDogTFZpZXdGbGFncy5DaGVja0Fsd2F5cywgcm9vdFZpZXdbdE5vZGUuaW5kZXhdLFxuICAgICAgdE5vZGUsIGVudmlyb25tZW50LCB2aWV3UmVuZGVyZXIsIG51bGwsIG51bGwsIGh5ZHJhdGlvbkluZm8pO1xuXG4gIGlmICh0Vmlldy5maXJzdENyZWF0ZVBhc3MpIHtcbiAgICBtYXJrQXNDb21wb25lbnRIb3N0KHRWaWV3LCB0Tm9kZSwgcm9vdERpcmVjdGl2ZXMubGVuZ3RoIC0gMSk7XG4gIH1cblxuICBhZGRUb1ZpZXdUcmVlKHJvb3RWaWV3LCBjb21wb25lbnRWaWV3KTtcblxuICAvLyBTdG9yZSBjb21wb25lbnQgdmlldyBhdCBub2RlIGluZGV4LCB3aXRoIG5vZGUgYXMgdGhlIEhPU1RcbiAgcmV0dXJuIHJvb3RWaWV3W3ROb2RlLmluZGV4XSA9IGNvbXBvbmVudFZpZXc7XG59XG5cbi8qKiBTZXRzIHVwIHRoZSBzdHlsaW5nIGluZm9ybWF0aW9uIG9uIGEgcm9vdCBjb21wb25lbnQuICovXG5mdW5jdGlvbiBhcHBseVJvb3RDb21wb25lbnRTdHlsaW5nKFxuICAgIHJvb3REaXJlY3RpdmVzOiBEaXJlY3RpdmVEZWY8YW55PltdLCB0Tm9kZTogVEVsZW1lbnROb2RlLCByTm9kZTogUkVsZW1lbnR8bnVsbCxcbiAgICBob3N0UmVuZGVyZXI6IFJlbmRlcmVyKTogdm9pZCB7XG4gIGZvciAoY29uc3QgZGVmIG9mIHJvb3REaXJlY3RpdmVzKSB7XG4gICAgdE5vZGUubWVyZ2VkQXR0cnMgPSBtZXJnZUhvc3RBdHRycyh0Tm9kZS5tZXJnZWRBdHRycywgZGVmLmhvc3RBdHRycyk7XG4gIH1cblxuICBpZiAodE5vZGUubWVyZ2VkQXR0cnMgIT09IG51bGwpIHtcbiAgICBjb21wdXRlU3RhdGljU3R5bGluZyh0Tm9kZSwgdE5vZGUubWVyZ2VkQXR0cnMsIHRydWUpO1xuXG4gICAgaWYgKHJOb2RlICE9PSBudWxsKSB7XG4gICAgICBzZXR1cFN0YXRpY0F0dHJpYnV0ZXMoaG9zdFJlbmRlcmVyLCByTm9kZSwgdE5vZGUpO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIENyZWF0ZXMgYSByb290IGNvbXBvbmVudCBhbmQgc2V0cyBpdCB1cCB3aXRoIGZlYXR1cmVzIGFuZCBob3N0IGJpbmRpbmdzLlNoYXJlZCBieVxuICogcmVuZGVyQ29tcG9uZW50KCkgYW5kIFZpZXdDb250YWluZXJSZWYuY3JlYXRlQ29tcG9uZW50KCkuXG4gKi9cbmZ1bmN0aW9uIGNyZWF0ZVJvb3RDb21wb25lbnQ8VD4oXG4gICAgY29tcG9uZW50VmlldzogTFZpZXcsIHJvb3RDb21wb25lbnREZWY6IENvbXBvbmVudERlZjxUPiwgcm9vdERpcmVjdGl2ZXM6IERpcmVjdGl2ZURlZjxhbnk+W10sXG4gICAgaG9zdERpcmVjdGl2ZURlZnM6IEhvc3REaXJlY3RpdmVEZWZzfG51bGwsIHJvb3RMVmlldzogTFZpZXcsXG4gICAgaG9zdEZlYXR1cmVzOiBIb3N0RmVhdHVyZVtdfG51bGwpOiBhbnkge1xuICBjb25zdCByb290VE5vZGUgPSBnZXRDdXJyZW50VE5vZGUoKSBhcyBURWxlbWVudE5vZGU7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnREZWZpbmVkKHJvb3RUTm9kZSwgJ3ROb2RlIHNob3VsZCBoYXZlIGJlZW4gYWxyZWFkeSBjcmVhdGVkJyk7XG4gIGNvbnN0IHRWaWV3ID0gcm9vdExWaWV3W1RWSUVXXTtcbiAgY29uc3QgbmF0aXZlID0gZ2V0TmF0aXZlQnlUTm9kZShyb290VE5vZGUsIHJvb3RMVmlldyk7XG5cbiAgaW5pdGlhbGl6ZURpcmVjdGl2ZXModFZpZXcsIHJvb3RMVmlldywgcm9vdFROb2RlLCByb290RGlyZWN0aXZlcywgbnVsbCwgaG9zdERpcmVjdGl2ZURlZnMpO1xuXG4gIGZvciAobGV0IGkgPSAwOyBpIDwgcm9vdERpcmVjdGl2ZXMubGVuZ3RoOyBpKyspIHtcbiAgICBjb25zdCBkaXJlY3RpdmVJbmRleCA9IHJvb3RUTm9kZS5kaXJlY3RpdmVTdGFydCArIGk7XG4gICAgY29uc3QgZGlyZWN0aXZlSW5zdGFuY2UgPSBnZXROb2RlSW5qZWN0YWJsZShyb290TFZpZXcsIHRWaWV3LCBkaXJlY3RpdmVJbmRleCwgcm9vdFROb2RlKTtcbiAgICBhdHRhY2hQYXRjaERhdGEoZGlyZWN0aXZlSW5zdGFuY2UsIHJvb3RMVmlldyk7XG4gIH1cblxuICBpbnZva2VEaXJlY3RpdmVzSG9zdEJpbmRpbmdzKHRWaWV3LCByb290TFZpZXcsIHJvb3RUTm9kZSk7XG5cbiAgaWYgKG5hdGl2ZSkge1xuICAgIGF0dGFjaFBhdGNoRGF0YShuYXRpdmUsIHJvb3RMVmlldyk7XG4gIH1cblxuICAvLyBXZSdyZSBndWFyYW50ZWVkIGZvciB0aGUgYGNvbXBvbmVudE9mZnNldGAgdG8gYmUgcG9zaXRpdmUgaGVyZVxuICAvLyBzaW5jZSBhIHJvb3QgY29tcG9uZW50IGFsd2F5cyBtYXRjaGVzIGEgY29tcG9uZW50IGRlZi5cbiAgbmdEZXZNb2RlICYmXG4gICAgICBhc3NlcnRHcmVhdGVyVGhhbihyb290VE5vZGUuY29tcG9uZW50T2Zmc2V0LCAtMSwgJ2NvbXBvbmVudE9mZnNldCBtdXN0IGJlIGdyZWF0IHRoYW4gLTEnKTtcbiAgY29uc3QgY29tcG9uZW50ID0gZ2V0Tm9kZUluamVjdGFibGUoXG4gICAgICByb290TFZpZXcsIHRWaWV3LCByb290VE5vZGUuZGlyZWN0aXZlU3RhcnQgKyByb290VE5vZGUuY29tcG9uZW50T2Zmc2V0LCByb290VE5vZGUpO1xuICBjb21wb25lbnRWaWV3W0NPTlRFWFRdID0gcm9vdExWaWV3W0NPTlRFWFRdID0gY29tcG9uZW50O1xuXG4gIGlmIChob3N0RmVhdHVyZXMgIT09IG51bGwpIHtcbiAgICBmb3IgKGNvbnN0IGZlYXR1cmUgb2YgaG9zdEZlYXR1cmVzKSB7XG4gICAgICBmZWF0dXJlKGNvbXBvbmVudCwgcm9vdENvbXBvbmVudERlZik7XG4gICAgfVxuICB9XG5cbiAgLy8gV2Ugd2FudCB0byBnZW5lcmF0ZSBhbiBlbXB0eSBRdWVyeUxpc3QgZm9yIHJvb3QgY29udGVudCBxdWVyaWVzIGZvciBiYWNrd2FyZHNcbiAgLy8gY29tcGF0aWJpbGl0eSB3aXRoIFZpZXdFbmdpbmUuXG4gIGV4ZWN1dGVDb250ZW50UXVlcmllcyh0Vmlldywgcm9vdFROb2RlLCBjb21wb25lbnRWaWV3KTtcblxuICByZXR1cm4gY29tcG9uZW50O1xufVxuXG4vKiogU2V0cyB0aGUgc3RhdGljIGF0dHJpYnV0ZXMgb24gYSByb290IGNvbXBvbmVudC4gKi9cbmZ1bmN0aW9uIHNldFJvb3ROb2RlQXR0cmlidXRlcyhcbiAgICBob3N0UmVuZGVyZXI6IFJlbmRlcmVyMiwgY29tcG9uZW50RGVmOiBDb21wb25lbnREZWY8dW5rbm93bj4sIGhvc3RSTm9kZTogUkVsZW1lbnQsXG4gICAgcm9vdFNlbGVjdG9yT3JOb2RlOiBhbnkpIHtcbiAgaWYgKHJvb3RTZWxlY3Rvck9yTm9kZSkge1xuICAgIHNldFVwQXR0cmlidXRlcyhob3N0UmVuZGVyZXIsIGhvc3RSTm9kZSwgWyduZy12ZXJzaW9uJywgVkVSU0lPTi5mdWxsXSk7XG4gIH0gZWxzZSB7XG4gICAgLy8gSWYgaG9zdCBlbGVtZW50IGlzIGNyZWF0ZWQgYXMgYSBwYXJ0IG9mIHRoaXMgZnVuY3Rpb24gY2FsbCAoaS5lLiBgcm9vdFNlbGVjdG9yT3JOb2RlYFxuICAgIC8vIGlzIG5vdCBkZWZpbmVkKSwgYWxzbyBhcHBseSBhdHRyaWJ1dGVzIGFuZCBjbGFzc2VzIGV4dHJhY3RlZCBmcm9tIGNvbXBvbmVudCBzZWxlY3Rvci5cbiAgICAvLyBFeHRyYWN0IGF0dHJpYnV0ZXMgYW5kIGNsYXNzZXMgZnJvbSB0aGUgZmlyc3Qgc2VsZWN0b3Igb25seSB0byBtYXRjaCBWRSBiZWhhdmlvci5cbiAgICBjb25zdCB7YXR0cnMsIGNsYXNzZXN9ID0gZXh0cmFjdEF0dHJzQW5kQ2xhc3Nlc0Zyb21TZWxlY3Rvcihjb21wb25lbnREZWYuc2VsZWN0b3JzWzBdKTtcbiAgICBpZiAoYXR0cnMpIHtcbiAgICAgIHNldFVwQXR0cmlidXRlcyhob3N0UmVuZGVyZXIsIGhvc3RSTm9kZSwgYXR0cnMpO1xuICAgIH1cbiAgICBpZiAoY2xhc3NlcyAmJiBjbGFzc2VzLmxlbmd0aCA+IDApIHtcbiAgICAgIHdyaXRlRGlyZWN0Q2xhc3MoaG9zdFJlbmRlcmVyLCBob3N0Uk5vZGUsIGNsYXNzZXMuam9pbignICcpKTtcbiAgICB9XG4gIH1cbn1cblxuLyoqIFByb2plY3RzIHRoZSBgcHJvamVjdGFibGVOb2Rlc2AgdGhhdCB3ZXJlIHNwZWNpZmllZCB3aGVuIGNyZWF0aW5nIGEgcm9vdCBjb21wb25lbnQuICovXG5mdW5jdGlvbiBwcm9qZWN0Tm9kZXMoXG4gICAgdE5vZGU6IFRFbGVtZW50Tm9kZSwgbmdDb250ZW50U2VsZWN0b3JzOiBzdHJpbmdbXSwgcHJvamVjdGFibGVOb2RlczogYW55W11bXSkge1xuICBjb25zdCBwcm9qZWN0aW9uOiAoVE5vZGV8Uk5vZGVbXXxudWxsKVtdID0gdE5vZGUucHJvamVjdGlvbiA9IFtdO1xuICBmb3IgKGxldCBpID0gMDsgaSA8IG5nQ29udGVudFNlbGVjdG9ycy5sZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IG5vZGVzZm9yU2xvdCA9IHByb2plY3RhYmxlTm9kZXNbaV07XG4gICAgLy8gUHJvamVjdGFibGUgbm9kZXMgY2FuIGJlIHBhc3NlZCBhcyBhcnJheSBvZiBhcnJheXMgb3IgYW4gYXJyYXkgb2YgaXRlcmFibGVzIChuZ1VwZ3JhZGVcbiAgICAvLyBjYXNlKS4gSGVyZSB3ZSBkbyBub3JtYWxpemUgcGFzc2VkIGRhdGEgc3RydWN0dXJlIHRvIGJlIGFuIGFycmF5IG9mIGFycmF5cyB0byBhdm9pZFxuICAgIC8vIGNvbXBsZXggY2hlY2tzIGRvd24gdGhlIGxpbmUuXG4gICAgLy8gV2UgYWxzbyBub3JtYWxpemUgdGhlIGxlbmd0aCBvZiB0aGUgcGFzc2VkIGluIHByb2plY3RhYmxlIG5vZGVzICh0byBtYXRjaCB0aGUgbnVtYmVyIG9mXG4gICAgLy8gPG5nLWNvbnRhaW5lcj4gc2xvdHMgZGVmaW5lZCBieSBhIGNvbXBvbmVudCkuXG4gICAgcHJvamVjdGlvbi5wdXNoKG5vZGVzZm9yU2xvdCAhPSBudWxsID8gQXJyYXkuZnJvbShub2Rlc2ZvclNsb3QpIDogbnVsbCk7XG4gIH1cbn1cblxuLyoqXG4gKiBVc2VkIHRvIGVuYWJsZSBsaWZlY3ljbGUgaG9va3Mgb24gdGhlIHJvb3QgY29tcG9uZW50LlxuICpcbiAqIEluY2x1ZGUgdGhpcyBmZWF0dXJlIHdoZW4gY2FsbGluZyBgcmVuZGVyQ29tcG9uZW50YCBpZiB0aGUgcm9vdCBjb21wb25lbnRcbiAqIHlvdSBhcmUgcmVuZGVyaW5nIGhhcyBsaWZlY3ljbGUgaG9va3MgZGVmaW5lZC4gT3RoZXJ3aXNlLCB0aGUgaG9va3Mgd29uJ3RcbiAqIGJlIGNhbGxlZCBwcm9wZXJseS5cbiAqXG4gKiBFeGFtcGxlOlxuICpcbiAqIGBgYFxuICogcmVuZGVyQ29tcG9uZW50KEFwcENvbXBvbmVudCwge2hvc3RGZWF0dXJlczogW0xpZmVjeWNsZUhvb2tzRmVhdHVyZV19KTtcbiAqIGBgYFxuICovXG5leHBvcnQgZnVuY3Rpb24gTGlmZWN5Y2xlSG9va3NGZWF0dXJlKCk6IHZvaWQge1xuICBjb25zdCB0Tm9kZSA9IGdldEN1cnJlbnRUTm9kZSgpITtcbiAgbmdEZXZNb2RlICYmIGFzc2VydERlZmluZWQodE5vZGUsICdUTm9kZSBpcyByZXF1aXJlZCcpO1xuICByZWdpc3RlclBvc3RPcmRlckhvb2tzKGdldExWaWV3KClbVFZJRVddLCB0Tm9kZSk7XG59XG4iXX0=