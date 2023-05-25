/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { getCompilerFacade } from '../../compiler/compiler_facade';
import { isForwardRef, resolveForwardRef } from '../../di/forward_ref';
import { getReflect, reflectDependencies } from '../../di/jit/util';
import { componentNeedsResolution, maybeQueueResolutionOfComponentResources } from '../../metadata/resource_loading';
import { ViewEncapsulation } from '../../metadata/view';
import { flatten } from '../../util/array_utils';
import { EMPTY_ARRAY, EMPTY_OBJ } from '../../util/empty';
import { initNgDevMode } from '../../util/ng_dev_mode';
import { getComponentDef, getDirectiveDef, getNgModuleDef, getPipeDef } from '../definition';
import { NG_COMP_DEF, NG_DIR_DEF, NG_FACTORY_DEF } from '../fields';
import { stringifyForError } from '../util/stringify_utils';
import { angularCoreEnv } from './environment';
import { getJitOptions } from './jit_options';
import { flushModuleScopingQueueAsMuchAsPossible, patchComponentDefWithScope, transitiveScopesFor } from './module';
import { isModuleWithProviders } from './util';
/**
 * Keep track of the compilation depth to avoid reentrancy issues during JIT compilation. This
 * matters in the following scenario:
 *
 * Consider a component 'A' that extends component 'B', both declared in module 'M'. During
 * the compilation of 'A' the definition of 'B' is requested to capture the inheritance chain,
 * potentially triggering compilation of 'B'. If this nested compilation were to trigger
 * `flushModuleScopingQueueAsMuchAsPossible` it may happen that module 'M' is still pending in the
 * queue, resulting in 'A' and 'B' to be patched with the NgModule scope. As the compilation of
 * 'A' is still in progress, this would introduce a circular dependency on its compilation. To avoid
 * this issue, the module scope queue is only flushed for compilations at the depth 0, to ensure
 * all compilations have finished.
 */
let compilationDepth = 0;
/**
 * Compile an Angular component according to its decorator metadata, and patch the resulting
 * component def (ɵcmp) onto the component type.
 *
 * Compilation may be asynchronous (due to the need to resolve URLs for the component template or
 * other resources, for example). In the event that compilation is not immediate, `compileComponent`
 * will enqueue resource resolution into a global queue and will fail to return the `ɵcmp`
 * until the global queue has been resolved with a call to `resolveComponentResources`.
 */
export function compileComponent(type, metadata) {
    // Initialize ngDevMode. This must be the first statement in compileComponent.
    // See the `initNgDevMode` docstring for more information.
    (typeof ngDevMode === 'undefined' || ngDevMode) && initNgDevMode();
    let ngComponentDef = null;
    // Metadata may have resources which need to be resolved.
    maybeQueueResolutionOfComponentResources(type, metadata);
    // Note that we're using the same function as `Directive`, because that's only subset of metadata
    // that we need to create the ngFactoryDef. We're avoiding using the component metadata
    // because we'd have to resolve the asynchronous templates.
    addDirectiveFactoryDef(type, metadata);
    Object.defineProperty(type, NG_COMP_DEF, {
        get: () => {
            if (ngComponentDef === null) {
                const compiler = getCompilerFacade({ usage: 0 /* JitCompilerUsage.Decorator */, kind: 'component', type: type });
                if (componentNeedsResolution(metadata)) {
                    const error = [`Component '${type.name}' is not resolved:`];
                    if (metadata.templateUrl) {
                        error.push(` - templateUrl: ${metadata.templateUrl}`);
                    }
                    if (metadata.styleUrls && metadata.styleUrls.length) {
                        error.push(` - styleUrls: ${JSON.stringify(metadata.styleUrls)}`);
                    }
                    error.push(`Did you run and wait for 'resolveComponentResources()'?`);
                    throw new Error(error.join('\n'));
                }
                // This const was called `jitOptions` previously but had to be renamed to `options` because
                // of a bug with Terser that caused optimized JIT builds to throw a `ReferenceError`.
                // This bug was investigated in https://github.com/angular/angular-cli/issues/17264.
                // We should not rename it back until https://github.com/terser/terser/issues/615 is fixed.
                const options = getJitOptions();
                let preserveWhitespaces = metadata.preserveWhitespaces;
                if (preserveWhitespaces === undefined) {
                    if (options !== null && options.preserveWhitespaces !== undefined) {
                        preserveWhitespaces = options.preserveWhitespaces;
                    }
                    else {
                        preserveWhitespaces = false;
                    }
                }
                let encapsulation = metadata.encapsulation;
                if (encapsulation === undefined) {
                    if (options !== null && options.defaultEncapsulation !== undefined) {
                        encapsulation = options.defaultEncapsulation;
                    }
                    else {
                        encapsulation = ViewEncapsulation.Emulated;
                    }
                }
                const templateUrl = metadata.templateUrl || `ng:///${type.name}/template.html`;
                const meta = {
                    ...directiveMetadata(type, metadata),
                    typeSourceSpan: compiler.createParseSourceSpan('Component', type.name, templateUrl),
                    template: metadata.template || '',
                    preserveWhitespaces,
                    styles: metadata.styles || EMPTY_ARRAY,
                    animations: metadata.animations,
                    // JIT components are always compiled against an empty set of `declarations`. Instead, the
                    // `directiveDefs` and `pipeDefs` are updated at a later point:
                    //  * for NgModule-based components, they're set when the NgModule which declares the
                    //    component resolves in the module scoping queue
                    //  * for standalone components, they're set just below, after `compileComponent`.
                    declarations: [],
                    changeDetection: metadata.changeDetection,
                    encapsulation,
                    interpolation: metadata.interpolation,
                    viewProviders: metadata.viewProviders || null,
                };
                compilationDepth++;
                try {
                    if (meta.usesInheritance) {
                        addDirectiveDefToUndecoratedParents(type);
                    }
                    ngComponentDef =
                        compiler.compileComponent(angularCoreEnv, templateUrl, meta);
                    if (metadata.standalone) {
                        // Patch the component definition for standalone components with `directiveDefs` and
                        // `pipeDefs` functions which lazily compute the directives/pipes available in the
                        // standalone component. Also set `dependencies` to the lazily resolved list of imports.
                        const imports = flatten(metadata.imports || EMPTY_ARRAY);
                        const { directiveDefs, pipeDefs } = getStandaloneDefFunctions(type, imports);
                        ngComponentDef.directiveDefs = directiveDefs;
                        ngComponentDef.pipeDefs = pipeDefs;
                        ngComponentDef.dependencies = () => imports.map(resolveForwardRef);
                    }
                }
                finally {
                    // Ensure that the compilation depth is decremented even when the compilation failed.
                    compilationDepth--;
                }
                if (compilationDepth === 0) {
                    // When NgModule decorator executed, we enqueued the module definition such that
                    // it would only dequeue and add itself as module scope to all of its declarations,
                    // but only if  if all of its declarations had resolved. This call runs the check
                    // to see if any modules that are in the queue can be dequeued and add scope to
                    // their declarations.
                    flushModuleScopingQueueAsMuchAsPossible();
                }
                // If component compilation is async, then the @NgModule annotation which declares the
                // component may execute and set an ngSelectorScope property on the component type. This
                // allows the component to patch itself with directiveDefs from the module after it
                // finishes compiling.
                if (hasSelectorScope(type)) {
                    const scopes = transitiveScopesFor(type.ngSelectorScope);
                    patchComponentDefWithScope(ngComponentDef, scopes);
                }
                if (metadata.schemas) {
                    if (metadata.standalone) {
                        ngComponentDef.schemas = metadata.schemas;
                    }
                    else {
                        throw new Error(`The 'schemas' was specified for the ${stringifyForError(type)} but is only valid on a component that is standalone.`);
                    }
                }
                else if (metadata.standalone) {
                    ngComponentDef.schemas = [];
                }
            }
            return ngComponentDef;
        },
        // Make the property configurable in dev mode to allow overriding in tests
        configurable: !!ngDevMode,
    });
}
function getDependencyTypeForError(type) {
    if (getComponentDef(type))
        return 'component';
    if (getDirectiveDef(type))
        return 'directive';
    if (getPipeDef(type))
        return 'pipe';
    return 'type';
}
function verifyStandaloneImport(depType, importingType) {
    if (isForwardRef(depType)) {
        depType = resolveForwardRef(depType);
        if (!depType) {
            throw new Error(`Expected forwardRef function, imported from "${stringifyForError(importingType)}", to return a standalone entity or NgModule but got "${stringifyForError(depType) || depType}".`);
        }
    }
    if (getNgModuleDef(depType) == null) {
        const def = getComponentDef(depType) || getDirectiveDef(depType) || getPipeDef(depType);
        if (def != null) {
            // if a component, directive or pipe is imported make sure that it is standalone
            if (!def.standalone) {
                throw new Error(`The "${stringifyForError(depType)}" ${getDependencyTypeForError(depType)}, imported from "${stringifyForError(importingType)}", is not standalone. Did you forget to add the standalone: true flag?`);
            }
        }
        else {
            // it can be either a module with provider or an unknown (not annotated) type
            if (isModuleWithProviders(depType)) {
                throw new Error(`A module with providers was imported from "${stringifyForError(importingType)}". Modules with providers are not supported in standalone components imports.`);
            }
            else {
                throw new Error(`The "${stringifyForError(depType)}" type, imported from "${stringifyForError(importingType)}", must be a standalone component / directive / pipe or an NgModule. Did you forget to add the required @Component / @Directive / @Pipe or @NgModule annotation?`);
            }
        }
    }
}
/**
 * Build memoized `directiveDefs` and `pipeDefs` functions for the component definition of a
 * standalone component, which process `imports` and filter out directives and pipes. The use of
 * memoized functions here allows for the delayed resolution of any `forwardRef`s present in the
 * component's `imports`.
 */
function getStandaloneDefFunctions(type, imports) {
    let cachedDirectiveDefs = null;
    let cachedPipeDefs = null;
    const directiveDefs = () => {
        if (cachedDirectiveDefs === null) {
            // Standalone components are always able to self-reference, so include the component's own
            // definition in its `directiveDefs`.
            cachedDirectiveDefs = [getComponentDef(type)];
            const seen = new Set();
            for (const rawDep of imports) {
                ngDevMode && verifyStandaloneImport(rawDep, type);
                const dep = resolveForwardRef(rawDep);
                if (seen.has(dep)) {
                    continue;
                }
                seen.add(dep);
                if (!!getNgModuleDef(dep)) {
                    const scope = transitiveScopesFor(dep);
                    for (const dir of scope.exported.directives) {
                        const def = getComponentDef(dir) || getDirectiveDef(dir);
                        if (def && !seen.has(dir)) {
                            seen.add(dir);
                            cachedDirectiveDefs.push(def);
                        }
                    }
                }
                else {
                    const def = getComponentDef(dep) || getDirectiveDef(dep);
                    if (def) {
                        cachedDirectiveDefs.push(def);
                    }
                }
            }
        }
        return cachedDirectiveDefs;
    };
    const pipeDefs = () => {
        if (cachedPipeDefs === null) {
            cachedPipeDefs = [];
            const seen = new Set();
            for (const rawDep of imports) {
                const dep = resolveForwardRef(rawDep);
                if (seen.has(dep)) {
                    continue;
                }
                seen.add(dep);
                if (!!getNgModuleDef(dep)) {
                    const scope = transitiveScopesFor(dep);
                    for (const pipe of scope.exported.pipes) {
                        const def = getPipeDef(pipe);
                        if (def && !seen.has(pipe)) {
                            seen.add(pipe);
                            cachedPipeDefs.push(def);
                        }
                    }
                }
                else {
                    const def = getPipeDef(dep);
                    if (def) {
                        cachedPipeDefs.push(def);
                    }
                }
            }
        }
        return cachedPipeDefs;
    };
    return {
        directiveDefs,
        pipeDefs,
    };
}
function hasSelectorScope(component) {
    return component.ngSelectorScope !== undefined;
}
/**
 * Compile an Angular directive according to its decorator metadata, and patch the resulting
 * directive def onto the component type.
 *
 * In the event that compilation is not immediate, `compileDirective` will return a `Promise` which
 * will resolve when compilation completes and the directive becomes usable.
 */
export function compileDirective(type, directive) {
    let ngDirectiveDef = null;
    addDirectiveFactoryDef(type, directive || {});
    Object.defineProperty(type, NG_DIR_DEF, {
        get: () => {
            if (ngDirectiveDef === null) {
                // `directive` can be null in the case of abstract directives as a base class
                // that use `@Directive()` with no selector. In that case, pass empty object to the
                // `directiveMetadata` function instead of null.
                const meta = getDirectiveMetadata(type, directive || {});
                const compiler = getCompilerFacade({ usage: 0 /* JitCompilerUsage.Decorator */, kind: 'directive', type });
                ngDirectiveDef =
                    compiler.compileDirective(angularCoreEnv, meta.sourceMapUrl, meta.metadata);
            }
            return ngDirectiveDef;
        },
        // Make the property configurable in dev mode to allow overriding in tests
        configurable: !!ngDevMode,
    });
}
function getDirectiveMetadata(type, metadata) {
    const name = type && type.name;
    const sourceMapUrl = `ng:///${name}/ɵdir.js`;
    const compiler = getCompilerFacade({ usage: 0 /* JitCompilerUsage.Decorator */, kind: 'directive', type });
    const facade = directiveMetadata(type, metadata);
    facade.typeSourceSpan = compiler.createParseSourceSpan('Directive', name, sourceMapUrl);
    if (facade.usesInheritance) {
        addDirectiveDefToUndecoratedParents(type);
    }
    return { metadata: facade, sourceMapUrl };
}
function addDirectiveFactoryDef(type, metadata) {
    let ngFactoryDef = null;
    Object.defineProperty(type, NG_FACTORY_DEF, {
        get: () => {
            if (ngFactoryDef === null) {
                const meta = getDirectiveMetadata(type, metadata);
                const compiler = getCompilerFacade({ usage: 0 /* JitCompilerUsage.Decorator */, kind: 'directive', type });
                ngFactoryDef = compiler.compileFactory(angularCoreEnv, `ng:///${type.name}/ɵfac.js`, {
                    name: meta.metadata.name,
                    type: meta.metadata.type,
                    typeArgumentCount: 0,
                    deps: reflectDependencies(type),
                    target: compiler.FactoryTarget.Directive
                });
            }
            return ngFactoryDef;
        },
        // Make the property configurable in dev mode to allow overriding in tests
        configurable: !!ngDevMode,
    });
}
export function extendsDirectlyFromObject(type) {
    return Object.getPrototypeOf(type.prototype) === Object.prototype;
}
/**
 * Extract the `R3DirectiveMetadata` for a particular directive (either a `Directive` or a
 * `Component`).
 */
export function directiveMetadata(type, metadata) {
    // Reflect inputs and outputs.
    const reflect = getReflect();
    const propMetadata = reflect.ownPropMetadata(type);
    return {
        name: type.name,
        type: type,
        selector: metadata.selector !== undefined ? metadata.selector : null,
        host: metadata.host || EMPTY_OBJ,
        propMetadata: propMetadata,
        inputs: metadata.inputs || EMPTY_ARRAY,
        outputs: metadata.outputs || EMPTY_ARRAY,
        queries: extractQueriesMetadata(type, propMetadata, isContentQuery),
        lifecycle: { usesOnChanges: reflect.hasLifecycleHook(type, 'ngOnChanges') },
        typeSourceSpan: null,
        usesInheritance: !extendsDirectlyFromObject(type),
        exportAs: extractExportAs(metadata.exportAs),
        providers: metadata.providers || null,
        viewQueries: extractQueriesMetadata(type, propMetadata, isViewQuery),
        isStandalone: !!metadata.standalone,
        hostDirectives: metadata.hostDirectives?.map(directive => typeof directive === 'function' ? { directive } : directive) ||
            null
    };
}
/**
 * Adds a directive definition to all parent classes of a type that don't have an Angular decorator.
 */
function addDirectiveDefToUndecoratedParents(type) {
    const objPrototype = Object.prototype;
    let parent = Object.getPrototypeOf(type.prototype).constructor;
    // Go up the prototype until we hit `Object`.
    while (parent && parent !== objPrototype) {
        // Since inheritance works if the class was annotated already, we only need to add
        // the def if there are no annotations and the def hasn't been created already.
        if (!getDirectiveDef(parent) && !getComponentDef(parent) &&
            shouldAddAbstractDirective(parent)) {
            compileDirective(parent, null);
        }
        parent = Object.getPrototypeOf(parent);
    }
}
function convertToR3QueryPredicate(selector) {
    return typeof selector === 'string' ? splitByComma(selector) : resolveForwardRef(selector);
}
export function convertToR3QueryMetadata(propertyName, ann) {
    return {
        propertyName: propertyName,
        predicate: convertToR3QueryPredicate(ann.selector),
        descendants: ann.descendants,
        first: ann.first,
        read: ann.read ? ann.read : null,
        static: !!ann.static,
        emitDistinctChangesOnly: !!ann.emitDistinctChangesOnly,
    };
}
function extractQueriesMetadata(type, propMetadata, isQueryAnn) {
    const queriesMeta = [];
    for (const field in propMetadata) {
        if (propMetadata.hasOwnProperty(field)) {
            const annotations = propMetadata[field];
            annotations.forEach(ann => {
                if (isQueryAnn(ann)) {
                    if (!ann.selector) {
                        throw new Error(`Can't construct a query for the property "${field}" of ` +
                            `"${stringifyForError(type)}" since the query selector wasn't defined.`);
                    }
                    if (annotations.some(isInputAnnotation)) {
                        throw new Error(`Cannot combine @Input decorators with query decorators`);
                    }
                    queriesMeta.push(convertToR3QueryMetadata(field, ann));
                }
            });
        }
    }
    return queriesMeta;
}
function extractExportAs(exportAs) {
    return exportAs === undefined ? null : splitByComma(exportAs);
}
function isContentQuery(value) {
    const name = value.ngMetadataName;
    return name === 'ContentChild' || name === 'ContentChildren';
}
function isViewQuery(value) {
    const name = value.ngMetadataName;
    return name === 'ViewChild' || name === 'ViewChildren';
}
function isInputAnnotation(value) {
    return value.ngMetadataName === 'Input';
}
function splitByComma(value) {
    return value.split(',').map(piece => piece.trim());
}
const LIFECYCLE_HOOKS = [
    'ngOnChanges', 'ngOnInit', 'ngOnDestroy', 'ngDoCheck', 'ngAfterViewInit', 'ngAfterViewChecked',
    'ngAfterContentInit', 'ngAfterContentChecked'
];
function shouldAddAbstractDirective(type) {
    const reflect = getReflect();
    if (LIFECYCLE_HOOKS.some(hookName => reflect.hasLifecycleHook(type, hookName))) {
        return true;
    }
    const propMetadata = reflect.propMetadata(type);
    for (const field in propMetadata) {
        const annotations = propMetadata[field];
        for (let i = 0; i < annotations.length; i++) {
            const current = annotations[i];
            const metadataName = current.ngMetadataName;
            if (isInputAnnotation(current) || isContentQuery(current) || isViewQuery(current) ||
                metadataName === 'Output' || metadataName === 'HostBinding' ||
                metadataName === 'HostListener') {
                return true;
            }
        }
    }
    return false;
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZGlyZWN0aXZlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9qaXQvZGlyZWN0aXZlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBQyxpQkFBaUIsRUFBOEMsTUFBTSxnQ0FBZ0MsQ0FBQztBQUU5RyxPQUFPLEVBQUMsWUFBWSxFQUFFLGlCQUFpQixFQUFDLE1BQU0sc0JBQXNCLENBQUM7QUFDckUsT0FBTyxFQUFDLFVBQVUsRUFBRSxtQkFBbUIsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBSWxFLE9BQU8sRUFBQyx3QkFBd0IsRUFBRSx3Q0FBd0MsRUFBQyxNQUFNLGlDQUFpQyxDQUFDO0FBQ25ILE9BQU8sRUFBQyxpQkFBaUIsRUFBQyxNQUFNLHFCQUFxQixDQUFDO0FBQ3RELE9BQU8sRUFBQyxPQUFPLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUMvQyxPQUFPLEVBQUMsV0FBVyxFQUFFLFNBQVMsRUFBQyxNQUFNLGtCQUFrQixDQUFDO0FBQ3hELE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSx3QkFBd0IsQ0FBQztBQUNyRCxPQUFPLEVBQUMsZUFBZSxFQUFFLGVBQWUsRUFBRSxjQUFjLEVBQUUsVUFBVSxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQzNGLE9BQU8sRUFBQyxXQUFXLEVBQUUsVUFBVSxFQUFFLGNBQWMsRUFBQyxNQUFNLFdBQVcsQ0FBQztBQUVsRSxPQUFPLEVBQUMsaUJBQWlCLEVBQUMsTUFBTSx5QkFBeUIsQ0FBQztBQUUxRCxPQUFPLEVBQUMsY0FBYyxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBQzdDLE9BQU8sRUFBQyxhQUFhLEVBQUMsTUFBTSxlQUFlLENBQUM7QUFDNUMsT0FBTyxFQUFDLHVDQUF1QyxFQUFFLDBCQUEwQixFQUFFLG1CQUFtQixFQUFDLE1BQU0sVUFBVSxDQUFDO0FBQ2xILE9B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QyxDQUFDLENBQUMsQ0FBQztZQUMvQixNQUFNLFlBQVksR0FBRyxPQUFPLENBQUMsY0FBYyxDQUFDO1lBRTVDLElBQUksaUJBQWlCLENBQUMsT0FBTyxDQUFDLElBQUksY0FBYyxDQUFDLE9BQU8sQ0FBQyxJQUFJLFdBQVcsQ0FBQyxPQUFPLENBQUM7Z0JBQzdFLFlBQVksS0FBSyxRQUFRLElBQUksWUFBWSxLQUFLLGFBQWE7Z0JBQzNELFlBQVksS0FBSyxjQUFjLEVBQUU7Z0JBQ25DLE9BQU8sSUFBSSxDQUFDO2FBQ2I7U0FDRjtLQUNGO0lBRUQsT0FBTyxLQUFLLENBQUM7QUFDZixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Z2V0Q29tcGlsZXJGYWNhZGUsIEppdENvbXBpbGVyVXNhZ2UsIFIzRGlyZWN0aXZlTWV0YWRhdGFGYWNhZGV9IGZyb20gJy4uLy4uL2NvbXBpbGVyL2NvbXBpbGVyX2ZhY2FkZSc7XG5pbXBvcnQge1IzQ29tcG9uZW50TWV0YWRhdGFGYWNhZGUsIFIzUXVlcnlNZXRhZGF0YUZhY2FkZX0gZnJvbSAnLi4vLi4vY29tcGlsZXIvY29tcGlsZXJfZmFjYWRlX2ludGVyZmFjZSc7XG5pbXBvcnQge2lzRm9yd2FyZFJlZiwgcmVzb2x2ZUZvcndhcmRSZWZ9IGZyb20gJy4uLy4uL2RpL2ZvcndhcmRfcmVmJztcbmltcG9ydCB7Z2V0UmVmbGVjdCwgcmVmbGVjdERlcGVuZGVuY2llc30gZnJvbSAnLi4vLi4vZGkvaml0L3V0aWwnO1xuaW1wb3J0IHtUeXBlfSBmcm9tICcuLi8uLi9pbnRlcmZhY2UvdHlwZSc7XG5pbXBvcnQge1F1ZXJ5fSBmcm9tICcuLi8uLi9tZXRhZGF0YS9kaSc7XG5pbXBvcnQge0NvbXBvbmVudCwgRGlyZWN0aXZlLCBJbnB1dH0gZnJvbSAnLi4vLi4vbWV0YWRhdGEvZGlyZWN0aXZlcyc7XG5pbXBvcnQge2NvbXBvbmVudE5lZWRzUmVzb2x1dGlvbiwgbWF5YmVRdWV1ZVJlc29sdXRpb25PZkNvbXBvbmVudFJlc291cmNlc30gZnJvbSAnLi4vLi4vbWV0YWRhdGEvcmVzb3VyY2VfbG9hZGluZyc7XG5pbXBvcnQge1ZpZXdFbmNhcHN1bGF0aW9ufSBmcm9tICcuLi8uLi9tZXRhZGF0YS92aWV3JztcbmltcG9ydCB7ZmxhdHRlbn0gZnJvbSAnLi4vLi4vdXRpbC9hcnJheV91dGlscyc7XG5pbXBvcnQge0VNUFRZX0FSUkFZLCBFTVBUWV9PQkp9IGZyb20gJy4uLy4uL3V0aWwvZW1wdHknO1xuaW1wb3J0IHtpbml0TmdEZXZNb2RlfSBmcm9tICcuLi8uLi91dGlsL25nX2Rldl9tb2RlJztcbmltcG9ydCB7Z2V0Q29tcG9uZW50RGVmLCBnZXREaXJlY3RpdmVEZWYsIGdldE5nTW9kdWxlRGVmLCBnZXRQaXBlRGVmfSBmcm9tICcuLi9kZWZpbml0aW9uJztcbmltcG9ydCB7TkdfQ09NUF9ERUYsIE5HX0RJUl9ERUYsIE5HX0ZBQ1RPUllfREVGfSBmcm9tICcuLi9maWVsZHMnO1xuaW1wb3J0IHtDb21wb25lbnREZWYsIENvbXBvbmVudFR5cGUsIERpcmVjdGl2ZURlZkxpc3QsIFBpcGVEZWZMaXN0fSBmcm9tICcuLi9pbnRlcmZhY2VzL2RlZmluaXRpb24nO1xuaW1wb3J0IHtzdHJpbmdpZnlGb3JFcnJvcn0gZnJvbSAnLi4vdXRpbC9zdHJpbmdpZnlfdXRpbHMnO1xuXG5pbXBvcnQge2FuZ3VsYXJDb3JlRW52fSBmcm9tICcuL2Vudmlyb25tZW50JztcbmltcG9ydCB7Z2V0Sml0T3B0aW9uc30gZnJvbSAnLi9qaXRfb3B0aW9ucyc7XG5pbXBvcnQge2ZsdXNoTW9kdWxlU2NvcGluZ1F1ZXVlQXNNdWNoQXNQb3NzaWJsZSwgcGF0Y2hDb21wb25lbnREZWZXaXRoU2NvcGUsIHRyYW5zaXRpdmVTY29wZXNGb3J9IGZyb20gJy4vbW9kdWxlJztcbmltcG9ydCB7aXNNb2R1bGVXaXRoUHJvdmlkZXJzfSBmcm9tICcuL3V0aWwnO1xuXG4vKipcbiAqIEtlZXAgdHJhY2sgb2YgdGhlIGNvbXBpbGF0aW9uIGRlcHRoIHRvIGF2b2lkIHJlZW50cmFuY3kgaXNzdWVzIGR1cmluZyBKSVQgY29tcGlsYXRpb24uIFRoaXNcbiAqIG1hdHRlcnMgaW4gdGhlIGZvbGxvd2luZyBzY2VuYXJpbzpcbiAqXG4gKiBDb25zaWRlciBhIGNvbXBvbmVudCAnQScgdGhhdCBleHRlbmRzIGNvbXBvbmVudCAnQicsIGJvdGggZGVjbGFyZWQgaW4gbW9kdWxlICdNJy4gRHVyaW5nXG4gKiB0aGUgY29tcGlsYXRpb24gb2YgJ0EnIHRoZSBkZWZpbml0aW9uIG9mICdCJyBpcyByZXF1ZXN0ZWQgdG8gY2FwdHVyZSB0aGUgaW5oZXJpdGFuY2UgY2hhaW4sXG4gKiBwb3RlbnRpYWxseSB0cmlnZ2VyaW5nIGNvbXBpbGF0aW9uIG9mICdCJy4gSWYgdGhpcyBuZXN0ZWQgY29tcGlsYXRpb24gd2VyZSB0byB0cmlnZ2VyXG4gKiBgZmx1c2hNb2R1bGVTY29waW5nUXVldWVBc011Y2hBc1Bvc3NpYmxlYCBpdCBtYXkgaGFwcGVuIHRoYXQgbW9kdWxlICdNJyBpcyBzdGlsbCBwZW5kaW5nIGluIHRoZVxuICogcXVldWUsIHJlc3VsdGluZyBpbiAnQScgYW5kICdCJyB0byBiZSBwYXRjaGVkIHdpdGggdGhlIE5nTW9kdWxlIHNjb3BlLiBBcyB0aGUgY29tcGlsYXRpb24gb2ZcbiAqICdBJyBpcyBzdGlsbCBpbiBwcm9ncmVzcywgdGhpcyB3b3VsZCBpbnRyb2R1Y2UgYSBjaXJjdWxhciBkZXBlbmRlbmN5IG9uIGl0cyBjb21waWxhdGlvbi4gVG8gYXZvaWRcbiAqIHRoaXMgaXNzdWUsIHRoZSBtb2R1bGUgc2NvcGUgcXVldWUgaXMgb25seSBmbHVzaGVkIGZvciBjb21waWxhdGlvbnMgYXQgdGhlIGRlcHRoIDAsIHRvIGVuc3VyZVxuICogYWxsIGNvbXBpbGF0aW9ucyBoYXZlIGZpbmlzaGVkLlxuICovXG5sZXQgY29tcGlsYXRpb25EZXB0aCA9IDA7XG5cbi8qKlxuICogQ29tcGlsZSBhbiBBbmd1bGFyIGNvbXBvbmVudCBhY2NvcmRpbmcgdG8gaXRzIGRlY29yYXRvciBtZXRhZGF0YSwgYW5kIHBhdGNoIHRoZSByZXN1bHRpbmdcbiAqIGNvbXBvbmVudCBkZWYgKMm1Y21wKSBvbnRvIHRoZSBjb21wb25lbnQgdHlwZS5cbiAqXG4gKiBDb21waWxhdGlvbiBtYXkgYmUgYXN5bmNocm9ub3VzIChkdWUgdG8gdGhlIG5lZWQgdG8gcmVzb2x2ZSBVUkxzIGZvciB0aGUgY29tcG9uZW50IHRlbXBsYXRlIG9yXG4gKiBvdGhlciByZXNvdXJjZXMsIGZvciBleGFtcGxlKS4gSW4gdGhlIGV2ZW50IHRoYXQgY29tcGlsYXRpb24gaXMgbm90IGltbWVkaWF0ZSwgYGNvbXBpbGVDb21wb25lbnRgXG4gKiB3aWxsIGVucXVldWUgcmVzb3VyY2UgcmVzb2x1dGlvbiBpbnRvIGEgZ2xvYmFsIHF1ZXVlIGFuZCB3aWxsIGZhaWwgdG8gcmV0dXJuIHRoZSBgybVjbXBgXG4gKiB1bnRpbCB0aGUgZ2xvYmFsIHF1ZXVlIGhhcyBiZWVuIHJlc29sdmVkIHdpdGggYSBjYWxsIHRvIGByZXNvbHZlQ29tcG9uZW50UmVzb3VyY2VzYC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNvbXBpbGVDb21wb25lbnQodHlwZTogVHlwZTxhbnk+LCBtZXRhZGF0YTogQ29tcG9uZW50KTogdm9pZCB7XG4gIC8vIEluaXRpYWxpemUgbmdEZXZNb2RlLiBUaGlzIG11c3QgYmUgdGhlIGZpcnN0IHN0YXRlbWVudCBpbiBjb21waWxlQ29tcG9uZW50LlxuICAvLyBTZWUgdGhlIGBpbml0TmdEZXZNb2RlYCBkb2NzdHJpbmcgZm9yIG1vcmUgaW5mb3JtYXRpb24uXG4gICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpICYmIGluaXROZ0Rldk1vZGUoKTtcblxuICBsZXQgbmdDb21wb25lbnREZWY6IENvbXBvbmVudERlZjx1bmtub3duPnxudWxsID0gbnVsbDtcblxuICAvLyBNZXRhZGF0YSBtYXkgaGF2ZSByZXNvdXJjZXMgd2hpY2ggbmVlZCB0byBiZSByZXNvbHZlZC5cbiAgbWF5YmVRdWV1ZVJlc29sdXRpb25PZkNvbXBvbmVudFJlc291cmNlcyh0eXBlLCBtZXRhZGF0YSk7XG5cbiAgLy8gTm90ZSB0aGF0IHdlJ3JlIHVzaW5nIHRoZSBzYW1lIGZ1bmN0aW9uIGFzIGBEaXJlY3RpdmVgLCBiZWNhdXNlIHRoYXQncyBvbmx5IHN1YnNldCBvZiBtZXRhZGF0YVxuICAvLyB0aGF0IHdlIG5lZWQgdG8gY3JlYXRlIHRoZSBuZ0ZhY3RvcnlEZWYuIFdlJ3JlIGF2b2lkaW5nIHVzaW5nIHRoZSBjb21wb25lbnQgbWV0YWRhdGFcbiAgLy8gYmVjYXVzZSB3ZSdkIGhhdmUgdG8gcmVzb2x2ZSB0aGUgYXN5bmNocm9ub3VzIHRlbXBsYXRlcy5cbiAgYWRkRGlyZWN0aXZlRmFjdG9yeURlZih0eXBlLCBtZXRhZGF0YSk7XG5cbiAgT2JqZWN0LmRlZmluZVByb3BlcnR5KHR5cGUsIE5HX0NPTVBfREVGLCB7XG4gICAgZ2V0OiAoKSA9PiB7XG4gICAgICBpZiAobmdDb21wb25lbnREZWYgPT09IG51bGwpIHtcbiAgICAgICAgY29uc3QgY29tcGlsZXIgPVxuICAgICAgICAgICAgZ2V0Q29tcGlsZXJGYWNhZGUoe3VzYWdlOiBKaXRDb21waWxlclVzYWdlLkRlY29yYXRvciwga2luZDogJ2NvbXBvbmVudCcsIHR5cGU6IHR5cGV9KTtcblxuICAgICAgICBpZiAoY29tcG9uZW50TmVlZHNSZXNvbHV0aW9uKG1ldGFkYXRhKSkge1xuICAgICAgICAgIGNvbnN0IGVycm9yID0gW2BDb21wb25lbnQgJyR7dHlwZS5uYW1lfScgaXMgbm90IHJlc29sdmVkOmBdO1xuICAgICAgICAgIGlmIChtZXRhZGF0YS50ZW1wbGF0ZVVybCkge1xuICAgICAgICAgICAgZXJyb3IucHVzaChgIC0gdGVtcGxhdGVVcmw6ICR7bWV0YWRhdGEudGVtcGxhdGVVcmx9YCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGlmIChtZXRhZGF0YS5zdHlsZVVybHMgJiYgbWV0YWRhdGEuc3R5bGVVcmxzLmxlbmd0aCkge1xuICAgICAgICAgICAgZXJyb3IucHVzaChgIC0gc3R5bGVVcmxzOiAke0pTT04uc3RyaW5naWZ5KG1ldGFkYXRhLnN0eWxlVXJscyl9YCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGVycm9yLnB1c2goYERpZCB5b3UgcnVuIGFuZCB3YWl0IGZvciAncmVzb2x2ZUNvbXBvbmVudFJlc291cmNlcygpJz9gKTtcbiAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoZXJyb3Iuam9pbignXFxuJykpO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gVGhpcyBjb25zdCB3YXMgY2FsbGVkIGBqaXRPcHRpb25zYCBwcmV2aW91c2x5IGJ1dCBoYWQgdG8gYmUgcmVuYW1lZCB0byBgb3B0aW9uc2AgYmVjYXVzZVxuICAgICAgICAvLyBvZiBhIGJ1ZyB3aXRoIFRlcnNlciB0aGF0IGNhdXNlZCBvcHRpbWl6ZWQgSklUIGJ1aWxkcyB0byB0aHJvdyBhIGBSZWZlcmVuY2VFcnJvcmAuXG4gICAgICAgIC8vIFRoaXMgYnVnIHdhcyBpbnZlc3RpZ2F0ZWQgaW4gaHR0cHM6Ly9naXRodWIuY29tL2FuZ3VsYXIvYW5ndWxhci1jbGkvaXNzdWVzLzE3MjY0LlxuICAgICAgICAvLyBXZSBzaG91bGQgbm90IHJlbmFtZSBpdCBiYWNrIHVudGlsIGh0dHBzOi8vZ2l0aHViLmNvbS90ZXJzZXIvdGVyc2VyL2lzc3Vlcy82MTUgaXMgZml4ZWQuXG4gICAgICAgIGNvbnN0IG9wdGlvbnMgPSBnZXRKaXRPcHRpb25zKCk7XG4gICAgICAgIGxldCBwcmVzZXJ2ZVdoaXRlc3BhY2VzID0gbWV0YWRhdGEucHJlc2VydmVXaGl0ZXNwYWNlcztcbiAgICAgICAgaWYgKHByZXNlcnZlV2hpdGVzcGFjZXMgPT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgIGlmIChvcHRpb25zICE9PSBudWxsICYmIG9wdGlvbnMucHJlc2VydmVXaGl0ZXNwYWNlcyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICAgICAgICBwcmVzZXJ2ZVdoaXRlc3BhY2VzID0gb3B0aW9ucy5wcmVzZXJ2ZVdoaXRlc3BhY2VzO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBwcmVzZXJ2ZVdoaXRlc3BhY2VzID0gZmFsc2U7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIGxldCBlbmNhcHN1bGF0aW9uID0gbWV0YWRhdGEuZW5jYXBzdWxhdGlvbjtcbiAgICAgICAgaWYgKGVuY2Fwc3VsYXRpb24gPT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgIGlmIChvcHRpb25zICE9PSBudWxsICYmIG9wdGlvbnMuZGVmYXVsdEVuY2Fwc3VsYXRpb24gIT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgZW5jYXBzdWxhdGlvbiA9IG9wdGlvbnMuZGVmYXVsdEVuY2Fwc3VsYXRpb247XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGVuY2Fwc3VsYXRpb24gPSBWaWV3RW5jYXBzdWxhdGlvbi5FbXVsYXRlZDtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCB0ZW1wbGF0ZVVybCA9IG1ldGFkYXRhLnRlbXBsYXRlVXJsIHx8IGBuZzovLy8ke3R5cGUubmFtZX0vdGVtcGxhdGUuaHRtbGA7XG4gICAgICAgIGNvbnN0IG1ldGE6IFIzQ29tcG9uZW50TWV0YWRhdGFGYWNhZGUgPSB7XG4gICAgICAgICAgLi4uZGlyZWN0aXZlTWV0YWRhdGEodHlwZSwgbWV0YWRhdGEpLFxuICAgICAgICAgIHR5cGVTb3VyY2VTcGFuOiBjb21waWxlci5jcmVhdGVQYXJzZVNvdXJjZVNwYW4oJ0NvbXBvbmVudCcsIHR5cGUubmFtZSwgdGVtcGxhdGVVcmwpLFxuICAgICAgICAgIHRlbXBsYXRlOiBtZXRhZGF0YS50ZW1wbGF0ZSB8fCAnJyxcbiAgICAgICAgICBwcmVzZXJ2ZVdoaXRlc3BhY2VzLFxuICAgICAgICAgIHN0eWxlczogbWV0YWRhdGEuc3R5bGVzIHx8IEVNUFRZX0FSUkFZLFxuICAgICAgICAgIGFuaW1hdGlvbnM6IG1ldGFkYXRhLmFuaW1hdGlvbnMsXG4gICAgICAgICAgLy8gSklUIGNvbXBvbmVudHMgYXJlIGFsd2F5cyBjb21waWxlZCBhZ2FpbnN0IGFuIGVtcHR5IHNldCBvZiBgZGVjbGFyYXRpb25zYC4gSW5zdGVhZCwgdGhlXG4gICAgICAgICAgLy8gYGRpcmVjdGl2ZURlZnNgIGFuZCBgcGlwZURlZnNgIGFyZSB1cGRhdGVkIGF0IGEgbGF0ZXIgcG9pbnQ6XG4gICAgICAgICAgLy8gICogZm9yIE5nTW9kdWxlLWJhc2VkIGNvbXBvbmVudHMsIHRoZXkncmUgc2V0IHdoZW4gdGhlIE5nTW9kdWxlIHdoaWNoIGRlY2xhcmVzIHRoZVxuICAgICAgICAgIC8vICAgIGNvbXBvbmVudCByZXNvbHZlcyBpbiB0aGUgbW9kdWxlIHNjb3BpbmcgcXVldWVcbiAgICAgICAgICAvLyAgKiBmb3Igc3RhbmRhbG9uZSBjb21wb25lbnRzLCB0aGV5J3JlIHNldCBqdXN0IGJlbG93LCBhZnRlciBgY29tcGlsZUNvbXBvbmVudGAuXG4gICAgICAgICAgZGVjbGFyYXRpb25zOiBbXSxcbiAgICAgICAgICBjaGFuZ2VEZXRlY3Rpb246IG1ldGFkYXRhLmNoYW5nZURldGVjdGlvbixcbiAgICAgICAgICBlbmNhcHN1bGF0aW9uLFxuICAgICAgICAgIGludGVycG9sYXRpb246IG1ldGFkYXRhLmludGVycG9sYXRpb24sXG4gICAgICAgICAgdmlld1Byb3ZpZGVyczogbWV0YWRhdGEudmlld1Byb3ZpZGVycyB8fCBudWxsLFxuICAgICAgICB9O1xuXG4gICAgICAgIGNvbXBpbGF0aW9uRGVwdGgrKztcbiAgICAgICAgdHJ5IHtcbiAgICAgICAgICBpZiAobWV0YS51c2VzSW5oZXJpdGFuY2UpIHtcbiAgICAgICAgICAgIGFkZERpcmVjdGl2ZURlZlRvVW5kZWNvcmF0ZWRQYXJlbnRzKHR5cGUpO1xuICAgICAgICAgIH1cbiAgICAgICAgICBuZ0NvbXBvbmVudERlZiA9XG4gICAgICAgICAgICAgIGNvbXBpbGVyLmNvbXBpbGVDb21wb25lbnQoYW5ndWxhckNvcmVFbnYsIHRlbXBsYXRlVXJsLCBtZXRhKSBhcyBDb21wb25lbnREZWY8dW5rbm93bj47XG5cbiAgICAgICAgICBpZiAobWV0YWRhdGEuc3RhbmRhbG9uZSkge1xuICAgICAgICAgICAgLy8gUGF0Y2ggdGhlIGNvbXBvbmVudCBkZWZpbml0aW9uIGZvciBzdGFuZGFsb25lIGNvbXBvbmVudHMgd2l0aCBgZGlyZWN0aXZlRGVmc2AgYW5kXG4gICAgICAgICAgICAvLyBgcGlwZURlZnNgIGZ1bmN0aW9ucyB3aGljaCBsYXppbHkgY29tcHV0ZSB0aGUgZGlyZWN0aXZlcy9waXBlcyBhdmFpbGFibGUgaW4gdGhlXG4gICAgICAgICAgICAvLyBzdGFuZGFsb25lIGNvbXBvbmVudC4gQWxzbyBzZXQgYGRlcGVuZGVuY2llc2AgdG8gdGhlIGxhemlseSByZXNvbHZlZCBsaXN0IG9mIGltcG9ydHMuXG4gICAgICAgICAgICBjb25zdCBpbXBvcnRzOiBUeXBlPGFueT5bXSA9IGZsYXR0ZW4obWV0YWRhdGEuaW1wb3J0cyB8fCBFTVBUWV9BUlJBWSk7XG4gICAgICAgICAgICBjb25zdCB7ZGlyZWN0aXZlRGVmcywgcGlwZURlZnN9ID0gZ2V0U3RhbmRhbG9uZURlZkZ1bmN0aW9ucyh0eXBlLCBpbXBvcnRzKTtcbiAgICAgICAgICAgIG5nQ29tcG9uZW50RGVmLmRpcmVjdGl2ZURlZnMgPSBkaXJlY3RpdmVEZWZzO1xuICAgICAgICAgICAgbmdDb21wb25lbnREZWYucGlwZURlZnMgPSBwaXBlRGVmcztcbiAgICAgICAgICAgIG5nQ29tcG9uZW50RGVmLmRlcGVuZGVuY2llcyA9ICgpID0+IGltcG9ydHMubWFwKHJlc29sdmVGb3J3YXJkUmVmKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZmluYWxseSB7XG4gICAgICAgICAgLy8gRW5zdXJlIHRoYXQgdGhlIGNvbXBpbGF0aW9uIGRlcHRoIGlzIGRlY3JlbWVudGVkIGV2ZW4gd2hlbiB0aGUgY29tcGlsYXRpb24gZmFpbGVkLlxuICAgICAgICAgIGNvbXBpbGF0aW9uRGVwdGgtLTtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChjb21waWxhdGlvbkRlcHRoID09PSAwKSB7XG4gICAgICAgICAgLy8gV2hlbiBOZ01vZHVsZSBkZWNvcmF0b3IgZXhlY3V0ZWQsIHdlIGVucXVldWVkIHRoZSBtb2R1bGUgZGVmaW5pdGlvbiBzdWNoIHRoYXRcbiAgICAgICAgICAvLyBpdCB3b3VsZCBvbmx5IGRlcXVldWUgYW5kIGFkZCBpdHNlbGYgYXMgbW9kdWxlIHNjb3BlIHRvIGFsbCBvZiBpdHMgZGVjbGFyYXRpb25zLFxuICAgICAgICAgIC8vIGJ1dCBvbmx5IGlmICBpZiBhbGwgb2YgaXRzIGRlY2xhcmF0aW9ucyBoYWQgcmVzb2x2ZWQuIFRoaXMgY2FsbCBydW5zIHRoZSBjaGVja1xuICAgICAgICAgIC8vIHRvIHNlZSBpZiBhbnkgbW9kdWxlcyB0aGF0IGFyZSBpbiB0aGUgcXVldWUgY2FuIGJlIGRlcXVldWVkIGFuZCBhZGQgc2NvcGUgdG9cbiAgICAgICAgICAvLyB0aGVpciBkZWNsYXJhdGlvbnMuXG4gICAgICAgICAgZmx1c2hNb2R1bGVTY29waW5nUXVldWVBc011Y2hBc1Bvc3NpYmxlKCk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyBJZiBjb21wb25lbnQgY29tcGlsYXRpb24gaXMgYXN5bmMsIHRoZW4gdGhlIEBOZ01vZHVsZSBhbm5vdGF0aW9uIHdoaWNoIGRlY2xhcmVzIHRoZVxuICAgICAgICAvLyBjb21wb25lbnQgbWF5IGV4ZWN1dGUgYW5kIHNldCBhbiBuZ1NlbGVjdG9yU2NvcGUgcHJvcGVydHkgb24gdGhlIGNvbXBvbmVudCB0eXBlLiBUaGlzXG4gICAgICAgIC8vIGFsbG93cyB0aGUgY29tcG9uZW50IHRvIHBhdGNoIGl0c2VsZiB3aXRoIGRpcmVjdGl2ZURlZnMgZnJvbSB0aGUgbW9kdWxlIGFmdGVyIGl0XG4gICAgICAgIC8vIGZpbmlzaGVzIGNvbXBpbGluZy5cbiAgICAgICAgaWYgKGhhc1NlbGVjdG9yU2NvcGUodHlwZSkpIHtcbiAgICAgICAgICBjb25zdCBzY29wZXMgPSB0cmFuc2l0aXZlU2NvcGVzRm9yKHR5cGUubmdTZWxlY3RvclNjb3BlKTtcbiAgICAgICAgICBwYXRjaENvbXBvbmVudERlZldpdGhTY29wZShuZ0NvbXBvbmVudERlZiwgc2NvcGVzKTtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChtZXRhZGF0YS5zY2hlbWFzKSB7XG4gICAgICAgICAgaWYgKG1ldGFkYXRhLnN0YW5kYWxvbmUpIHtcbiAgICAgICAgICAgIG5nQ29tcG9uZW50RGVmLnNjaGVtYXMgPSBtZXRhZGF0YS5zY2hlbWFzO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYFRoZSAnc2NoZW1hcycgd2FzIHNwZWNpZmllZCBmb3IgdGhlICR7XG4gICAgICAgICAgICAgICAgc3RyaW5naWZ5Rm9yRXJyb3IodHlwZSl9IGJ1dCBpcyBvbmx5IHZhbGlkIG9uIGEgY29tcG9uZW50IHRoYXQgaXMgc3RhbmRhbG9uZS5gKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSBpZiAobWV0YWRhdGEuc3RhbmRhbG9uZSkge1xuICAgICAgICAgIG5nQ29tcG9uZW50RGVmLnNjaGVtYXMgPSBbXTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgcmV0dXJuIG5nQ29tcG9uZW50RGVmO1xuICAgIH0sXG4gICAgLy8gTWFrZSB0aGUgcHJvcGVydHkgY29uZmlndXJhYmxlIGluIGRldiBtb2RlIHRvIGFsbG93IG92ZXJyaWRpbmcgaW4gdGVzdHNcbiAgICBjb25maWd1cmFibGU6ICEhbmdEZXZNb2RlLFxuICB9KTtcbn1cblxuZnVuY3Rpb24gZ2V0RGVwZW5kZW5jeVR5cGVGb3JFcnJvcih0eXBlOiBUeXBlPGFueT4pIHtcbiAgaWYgKGdldENvbXBvbmVudERlZih0eXBlKSkgcmV0dXJuICdjb21wb25lbnQnO1xuICBpZiAoZ2V0RGlyZWN0aXZlRGVmKHR5cGUpKSByZXR1cm4gJ2RpcmVjdGl2ZSc7XG4gIGlmIChnZXRQaXBlRGVmKHR5cGUpKSByZXR1cm4gJ3BpcGUnO1xuICByZXR1cm4gJ3R5cGUnO1xufVxuXG5mdW5jdGlvbiB2ZXJpZnlTdGFuZGFsb25lSW1wb3J0KGRlcFR5cGU6IFR5cGU8dW5rbm93bj4sIGltcG9ydGluZ1R5cGU6IFR5cGU8dW5rbm93bj4pIHtcbiAgaWYgKGlzRm9yd2FyZFJlZihkZXBUeXBlKSkge1xuICAgIGRlcFR5cGUgPSByZXNvbHZlRm9yd2FyZFJlZihkZXBUeXBlKTtcbiAgICBpZiAoIWRlcFR5cGUpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihgRXhwZWN0ZWQgZm9yd2FyZFJlZiBmdW5jdGlvbiwgaW1wb3J0ZWQgZnJvbSBcIiR7XG4gICAgICAgICAgc3RyaW5naWZ5Rm9yRXJyb3IoaW1wb3J0aW5nVHlwZSl9XCIsIHRvIHJldHVybiBhIHN0YW5kYWxvbmUgZW50aXR5IG9yIE5nTW9kdWxlIGJ1dCBnb3QgXCIke1xuICAgICAgICAgIHN0cmluZ2lmeUZvckVycm9yKGRlcFR5cGUpIHx8IGRlcFR5cGV9XCIuYCk7XG4gICAgfVxuICB9XG5cbiAgaWYgKGdldE5nTW9kdWxlRGVmKGRlcFR5cGUpID09IG51bGwpIHtcbiAgICBjb25zdCBkZWYgPSBnZXRDb21wb25lbnREZWYoZGVwVHlwZSkgfHwgZ2V0RGlyZWN0aXZlRGVmKGRlcFR5cGUpIHx8IGdldFBpcGVEZWYoZGVwVHlwZSk7XG4gICAgaWYgKGRlZiAhPSBudWxsKSB7XG4gICAgICAvLyBpZiBhIGNvbXBvbmVudCwgZGlyZWN0aXZlIG9yIHBpcGUgaXMgaW1wb3J0ZWQgbWFrZSBzdXJlIHRoYXQgaXQgaXMgc3RhbmRhbG9uZVxuICAgICAgaWYgKCFkZWYuc3RhbmRhbG9uZSkge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYFRoZSBcIiR7c3RyaW5naWZ5Rm9yRXJyb3IoZGVwVHlwZSl9XCIgJHtcbiAgICAgICAgICAgIGdldERlcGVuZGVuY3lUeXBlRm9yRXJyb3IoZGVwVHlwZSl9LCBpbXBvcnRlZCBmcm9tIFwiJHtcbiAgICAgICAgICAgIHN0cmluZ2lmeUZvckVycm9yKFxuICAgICAgICAgICAgICAgIGltcG9ydGluZ1R5cGUpfVwiLCBpcyBub3Qgc3RhbmRhbG9uZS4gRGlkIHlvdSBmb3JnZXQgdG8gYWRkIHRoZSBzdGFuZGFsb25lOiB0cnVlIGZsYWc/YCk7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIC8vIGl0IGNhbiBiZSBlaXRoZXIgYSBtb2R1bGUgd2l0aCBwcm92aWRlciBvciBhbiB1bmtub3duIChub3QgYW5ub3RhdGVkKSB0eXBlXG4gICAgICBpZiAoaXNNb2R1bGVXaXRoUHJvdmlkZXJzKGRlcFR5cGUpKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihgQSBtb2R1bGUgd2l0aCBwcm92aWRlcnMgd2FzIGltcG9ydGVkIGZyb20gXCIke1xuICAgICAgICAgICAgc3RyaW5naWZ5Rm9yRXJyb3IoXG4gICAgICAgICAgICAgICAgaW1wb3J0aW5nVHlwZSl9XCIuIE1vZHVsZXMgd2l0aCBwcm92aWRlcnMgYXJlIG5vdCBzdXBwb3J0ZWQgaW4gc3RhbmRhbG9uZSBjb21wb25lbnRzIGltcG9ydHMuYCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYFRoZSBcIiR7c3RyaW5naWZ5Rm9yRXJyb3IoZGVwVHlwZSl9XCIgdHlwZSwgaW1wb3J0ZWQgZnJvbSBcIiR7XG4gICAgICAgICAgICBzdHJpbmdpZnlGb3JFcnJvcihcbiAgICAgICAgICAgICAgICBpbXBvcnRpbmdUeXBlKX1cIiwgbXVzdCBiZSBhIHN0YW5kYWxvbmUgY29tcG9uZW50IC8gZGlyZWN0aXZlIC8gcGlwZSBvciBhbiBOZ01vZHVsZS4gRGlkIHlvdSBmb3JnZXQgdG8gYWRkIHRoZSByZXF1aXJlZCBAQ29tcG9uZW50IC8gQERpcmVjdGl2ZSAvIEBQaXBlIG9yIEBOZ01vZHVsZSBhbm5vdGF0aW9uP2ApO1xuICAgICAgfVxuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIEJ1aWxkIG1lbW9pemVkIGBkaXJlY3RpdmVEZWZzYCBhbmQgYHBpcGVEZWZzYCBmdW5jdGlvbnMgZm9yIHRoZSBjb21wb25lbnQgZGVmaW5pdGlvbiBvZiBhXG4gKiBzdGFuZGFsb25lIGNvbXBvbmVudCwgd2hpY2ggcHJvY2VzcyBgaW1wb3J0c2AgYW5kIGZpbHRlciBvdXQgZGlyZWN0aXZlcyBhbmQgcGlwZXMuIFRoZSB1c2Ugb2ZcbiAqIG1lbW9pemVkIGZ1bmN0aW9ucyBoZXJlIGFsbG93cyBmb3IgdGhlIGRlbGF5ZWQgcmVzb2x1dGlvbiBvZiBhbnkgYGZvcndhcmRSZWZgcyBwcmVzZW50IGluIHRoZVxuICogY29tcG9uZW50J3MgYGltcG9ydHNgLlxuICovXG5mdW5jdGlvbiBnZXRTdGFuZGFsb25lRGVmRnVuY3Rpb25zKHR5cGU6IFR5cGU8YW55PiwgaW1wb3J0czogVHlwZTxhbnk+W10pOiB7XG4gIGRpcmVjdGl2ZURlZnM6ICgpID0+IERpcmVjdGl2ZURlZkxpc3QsXG4gIHBpcGVEZWZzOiAoKSA9PiBQaXBlRGVmTGlzdCxcbn0ge1xuICBsZXQgY2FjaGVkRGlyZWN0aXZlRGVmczogRGlyZWN0aXZlRGVmTGlzdHxudWxsID0gbnVsbDtcbiAgbGV0IGNhY2hlZFBpcGVEZWZzOiBQaXBlRGVmTGlzdHxudWxsID0gbnVsbDtcbiAgY29uc3QgZGlyZWN0aXZlRGVmcyA9ICgpID0+IHtcbiAgICBpZiAoY2FjaGVkRGlyZWN0aXZlRGVmcyA9PT0gbnVsbCkge1xuICAgICAgLy8gU3RhbmRhbG9uZSBjb21wb25lbnRzIGFyZSBhbHdheXMgYWJsZSB0byBzZWxmLXJlZmVyZW5jZSwgc28gaW5jbHVkZSB0aGUgY29tcG9uZW50J3Mgb3duXG4gICAgICAvLyBkZWZpbml0aW9uIGluIGl0cyBgZGlyZWN0aXZlRGVmc2AuXG4gICAgICBjYWNoZWREaXJlY3RpdmVEZWZzID0gW2dldENvbXBvbmVudERlZih0eXBlKSFdO1xuICAgICAgY29uc3Qgc2VlbiA9IG5ldyBTZXQ8VHlwZTx1bmtub3duPj4oKTtcblxuICAgICAgZm9yIChjb25zdCByYXdEZXAgb2YgaW1wb3J0cykge1xuICAgICAgICBuZ0Rldk1vZGUgJiYgdmVyaWZ5U3RhbmRhbG9uZUltcG9ydChyYXdEZXAsIHR5cGUpO1xuXG4gICAgICAgIGNvbnN0IGRlcCA9IHJlc29sdmVGb3J3YXJkUmVmKHJhd0RlcCk7XG4gICAgICAgIGlmIChzZWVuLmhhcyhkZXApKSB7XG4gICAgICAgICAgY29udGludWU7XG4gICAgICAgIH1cbiAgICAgICAgc2Vlbi5hZGQoZGVwKTtcblxuICAgICAgICBpZiAoISFnZXROZ01vZHVsZURlZihkZXApKSB7XG4gICAgICAgICAgY29uc3Qgc2NvcGUgPSB0cmFuc2l0aXZlU2NvcGVzRm9yKGRlcCk7XG4gICAgICAgICAgZm9yIChjb25zdCBkaXIgb2Ygc2NvcGUuZXhwb3J0ZWQuZGlyZWN0aXZlcykge1xuICAgICAgICAgICAgY29uc3QgZGVmID0gZ2V0Q29tcG9uZW50RGVmKGRpcikgfHwgZ2V0RGlyZWN0aXZlRGVmKGRpcik7XG4gICAgICAgICAgICBpZiAoZGVmICYmICFzZWVuLmhhcyhkaXIpKSB7XG4gICAgICAgICAgICAgIHNlZW4uYWRkKGRpcik7XG4gICAgICAgICAgICAgIGNhY2hlZERpcmVjdGl2ZURlZnMucHVzaChkZWYpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBjb25zdCBkZWYgPSBnZXRDb21wb25lbnREZWYoZGVwKSB8fCBnZXREaXJlY3RpdmVEZWYoZGVwKTtcbiAgICAgICAgICBpZiAoZGVmKSB7XG4gICAgICAgICAgICBjYWNoZWREaXJlY3RpdmVEZWZzLnB1c2goZGVmKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIGNhY2hlZERpcmVjdGl2ZURlZnM7XG4gIH07XG5cbiAgY29uc3QgcGlwZURlZnMgPSAoKSA9PiB7XG4gICAgaWYgKGNhY2hlZFBpcGVEZWZzID09PSBudWxsKSB7XG4gICAgICBjYWNoZWRQaXBlRGVmcyA9IFtdO1xuICAgICAgY29uc3Qgc2VlbiA9IG5ldyBTZXQ8VHlwZTx1bmtub3duPj4oKTtcblxuICAgICAgZm9yIChjb25zdCByYXdEZXAgb2YgaW1wb3J0cykge1xuICAgICAgICBjb25zdCBkZXAgPSByZXNvbHZlRm9yd2FyZFJlZihyYXdEZXApO1xuICAgICAgICBpZiAoc2Vlbi5oYXMoZGVwKSkge1xuICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICB9XG4gICAgICAgIHNlZW4uYWRkKGRlcCk7XG5cbiAgICAgICAgaWYgKCEhZ2V0TmdNb2R1bGVEZWYoZGVwKSkge1xuICAgICAgICAgIGNvbnN0IHNjb3BlID0gdHJhbnNpdGl2ZVNjb3Blc0ZvcihkZXApO1xuICAgICAgICAgIGZvciAoY29uc3QgcGlwZSBvZiBzY29wZS5leHBvcnRlZC5waXBlcykge1xuICAgICAgICAgICAgY29uc3QgZGVmID0gZ2V0UGlwZURlZihwaXBlKTtcbiAgICAgICAgICAgIGlmIChkZWYgJiYgIXNlZW4uaGFzKHBpcGUpKSB7XG4gICAgICAgICAgICAgIHNlZW4uYWRkKHBpcGUpO1xuICAgICAgICAgICAgICBjYWNoZWRQaXBlRGVmcy5wdXNoKGRlZik7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGNvbnN0IGRlZiA9IGdldFBpcGVEZWYoZGVwKTtcbiAgICAgICAgICBpZiAoZGVmKSB7XG4gICAgICAgICAgICBjYWNoZWRQaXBlRGVmcy5wdXNoKGRlZik7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBjYWNoZWRQaXBlRGVmcztcbiAgfTtcblxuICByZXR1cm4ge1xuICAgIGRpcmVjdGl2ZURlZnMsXG4gICAgcGlwZURlZnMsXG4gIH07XG59XG5cbmZ1bmN0aW9uIGhhc1NlbGVjdG9yU2NvcGU8VD4oY29tcG9uZW50OiBUeXBlPFQ+KTogY29tcG9uZW50IGlzIFR5cGU8VD4mXG4gICAge25nU2VsZWN0b3JTY29wZTogVHlwZTxhbnk+fSB7XG4gIHJldHVybiAoY29tcG9uZW50IGFzIHtuZ1NlbGVjdG9yU2NvcGU/OiBhbnl9KS5uZ1NlbGVjdG9yU2NvcGUgIT09IHVuZGVmaW5lZDtcbn1cblxuLyoqXG4gKiBDb21waWxlIGFuIEFuZ3VsYXIgZGlyZWN0aXZlIGFjY29yZGluZyB0byBpdHMgZGVjb3JhdG9yIG1ldGFkYXRhLCBhbmQgcGF0Y2ggdGhlIHJlc3VsdGluZ1xuICogZGlyZWN0aXZlIGRlZiBvbnRvIHRoZSBjb21wb25lbnQgdHlwZS5cbiAqXG4gKiBJbiB0aGUgZXZlbnQgdGhhdCBjb21waWxhdGlvbiBpcyBub3QgaW1tZWRpYXRlLCBgY29tcGlsZURpcmVjdGl2ZWAgd2lsbCByZXR1cm4gYSBgUHJvbWlzZWAgd2hpY2hcbiAqIHdpbGwgcmVzb2x2ZSB3aGVuIGNvbXBpbGF0aW9uIGNvbXBsZXRlcyBhbmQgdGhlIGRpcmVjdGl2ZSBiZWNvbWVzIHVzYWJsZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGNvbXBpbGVEaXJlY3RpdmUodHlwZTogVHlwZTxhbnk+LCBkaXJlY3RpdmU6IERpcmVjdGl2ZXxudWxsKTogdm9pZCB7XG4gIGxldCBuZ0RpcmVjdGl2ZURlZjogYW55ID0gbnVsbDtcblxuICBhZGREaXJlY3RpdmVGYWN0b3J5RGVmKHR5cGUsIGRpcmVjdGl2ZSB8fCB7fSk7XG5cbiAgT2JqZWN0LmRlZmluZVByb3BlcnR5KHR5cGUsIE5HX0RJUl9ERUYsIHtcbiAgICBnZXQ6ICgpID0+IHtcbiAgICAgIGlmIChuZ0RpcmVjdGl2ZURlZiA9PT0gbnVsbCkge1xuICAgICAgICAvLyBgZGlyZWN0aXZlYCBjYW4gYmUgbnVsbCBpbiB0aGUgY2FzZSBvZiBhYnN0cmFjdCBkaXJlY3RpdmVzIGFzIGEgYmFzZSBjbGFzc1xuICAgICAgICAvLyB0aGF0IHVzZSBgQERpcmVjdGl2ZSgpYCB3aXRoIG5vIHNlbGVjdG9yLiBJbiB0aGF0IGNhc2UsIHBhc3MgZW1wdHkgb2JqZWN0IHRvIHRoZVxuICAgICAgICAvLyBgZGlyZWN0aXZlTWV0YWRhdGFgIGZ1bmN0aW9uIGluc3RlYWQgb2YgbnVsbC5cbiAgICAgICAgY29uc3QgbWV0YSA9IGdldERpcmVjdGl2ZU1ldGFkYXRhKHR5cGUsIGRpcmVjdGl2ZSB8fCB7fSk7XG4gICAgICAgIGNvbnN0IGNvbXBpbGVyID1cbiAgICAgICAgICAgIGdldENvbXBpbGVyRmFjYWRlKHt1c2FnZTogSml0Q29tcGlsZXJVc2FnZS5EZWNvcmF0b3IsIGtpbmQ6ICdkaXJlY3RpdmUnLCB0eXBlfSk7XG4gICAgICAgIG5nRGlyZWN0aXZlRGVmID1cbiAgICAgICAgICAgIGNvbXBpbGVyLmNvbXBpbGVEaXJlY3RpdmUoYW5ndWxhckNvcmVFbnYsIG1ldGEuc291cmNlTWFwVXJsLCBtZXRhLm1ldGFkYXRhKTtcbiAgICAgIH1cbiAgICAgIHJldHVybiBuZ0RpcmVjdGl2ZURlZjtcbiAgICB9LFxuICAgIC8vIE1ha2UgdGhlIHByb3BlcnR5IGNvbmZpZ3VyYWJsZSBpbiBkZXYgbW9kZSB0byBhbGxvdyBvdmVycmlkaW5nIGluIHRlc3RzXG4gICAgY29uZmlndXJhYmxlOiAhIW5nRGV2TW9kZSxcbiAgfSk7XG59XG5cbmZ1bmN0aW9uIGdldERpcmVjdGl2ZU1ldGFkYXRhKHR5cGU6IFR5cGU8YW55PiwgbWV0YWRhdGE6IERpcmVjdGl2ZSkge1xuICBjb25zdCBuYW1lID0gdHlwZSAmJiB0eXBlLm5hbWU7XG4gIGNvbnN0IHNvdXJjZU1hcFVybCA9IGBuZzovLy8ke25hbWV9L8m1ZGlyLmpzYDtcbiAgY29uc3QgY29tcGlsZXIgPSBnZXRDb21waWxlckZhY2FkZSh7dXNhZ2U6IEppdENvbXBpbGVyVXNhZ2UuRGVjb3JhdG9yLCBraW5kOiAnZGlyZWN0aXZlJywgdHlwZX0pO1xuICBjb25zdCBmYWNhZGUgPSBkaXJlY3RpdmVNZXRhZGF0YSh0eXBlIGFzIENvbXBvbmVudFR5cGU8YW55PiwgbWV0YWRhdGEpO1xuICBmYWNhZGUudHlwZVNvdXJjZVNwYW4gPSBjb21waWxlci5jcmVhdGVQYXJzZVNvdXJjZVNwYW4oJ0RpcmVjdGl2ZScsIG5hbWUsIHNvdXJjZU1hcFVybCk7XG4gIGlmIChmYWNhZGUudXNlc0luaGVyaXRhbmNlKSB7XG4gICAgYWRkRGlyZWN0aXZlRGVmVG9VbmRlY29yYXRlZFBhcmVudHModHlwZSk7XG4gIH1cbiAgcmV0dXJuIHttZXRhZGF0YTogZmFjYWRlLCBzb3VyY2VNYXBVcmx9O1xufVxuXG5mdW5jdGlvbiBhZGREaXJlY3RpdmVGYWN0b3J5RGVmKHR5cGU6IFR5cGU8YW55PiwgbWV0YWRhdGE6IERpcmVjdGl2ZXxDb21wb25lbnQpIHtcbiAgbGV0IG5nRmFjdG9yeURlZjogYW55ID0gbnVsbDtcblxuICBPYmplY3QuZGVmaW5lUHJvcGVydHkodHlwZSwgTkdfRkFDVE9SWV9ERUYsIHtcbiAgICBnZXQ6ICgpID0+IHtcbiAgICAgIGlmIChuZ0ZhY3RvcnlEZWYgPT09IG51bGwpIHtcbiAgICAgICAgY29uc3QgbWV0YSA9IGdldERpcmVjdGl2ZU1ldGFkYXRhKHR5cGUsIG1ldGFkYXRhKTtcbiAgICAgICAgY29uc3QgY29tcGlsZXIgPVxuICAgICAgICAgICAgZ2V0Q29tcGlsZXJGYWNhZGUoe3VzYWdlOiBKaXRDb21waWxlclVzYWdlLkRlY29yYXRvciwga2luZDogJ2RpcmVjdGl2ZScsIHR5cGV9KTtcbiAgICAgICAgbmdGYWN0b3J5RGVmID0gY29tcGlsZXIuY29tcGlsZUZhY3RvcnkoYW5ndWxhckNvcmVFbnYsIGBuZzovLy8ke3R5cGUubmFtZX0vybVmYWMuanNgLCB7XG4gICAgICAgICAgbmFtZTogbWV0YS5tZXRhZGF0YS5uYW1lLFxuICAgICAgICAgIHR5cGU6IG1ldGEubWV0YWRhdGEudHlwZSxcbiAgICAgICAgICB0eXBlQXJndW1lbnRDb3VudDogMCxcbiAgICAgICAgICBkZXBzOiByZWZsZWN0RGVwZW5kZW5jaWVzKHR5cGUpLFxuICAgICAgICAgIHRhcmdldDogY29tcGlsZXIuRmFjdG9yeVRhcmdldC5EaXJlY3RpdmVcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gbmdGYWN0b3J5RGVmO1xuICAgIH0sXG4gICAgLy8gTWFrZSB0aGUgcHJvcGVydHkgY29uZmlndXJhYmxlIGluIGRldiBtb2RlIHRvIGFsbG93IG92ZXJyaWRpbmcgaW4gdGVzdHNcbiAgICBjb25maWd1cmFibGU6ICEhbmdEZXZNb2RlLFxuICB9KTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGV4dGVuZHNEaXJlY3RseUZyb21PYmplY3QodHlwZTogVHlwZTxhbnk+KTogYm9vbGVhbiB7XG4gIHJldHVybiBPYmplY3QuZ2V0UHJvdG90eXBlT2YodHlwZS5wcm90b3R5cGUpID09PSBPYmplY3QucHJvdG90eXBlO1xufVxuXG4vKipcbiAqIEV4dHJhY3QgdGhlIGBSM0RpcmVjdGl2ZU1ldGFkYXRhYCBmb3IgYSBwYXJ0aWN1bGFyIGRpcmVjdGl2ZSAoZWl0aGVyIGEgYERpcmVjdGl2ZWAgb3IgYVxuICogYENvbXBvbmVudGApLlxuICovXG5leHBvcnQgZnVuY3Rpb24gZGlyZWN0aXZlTWV0YWRhdGEodHlwZTogVHlwZTxhbnk+LCBtZXRhZGF0YTogRGlyZWN0aXZlKTogUjNEaXJlY3RpdmVNZXRhZGF0YUZhY2FkZSB7XG4gIC8vIFJlZmxlY3QgaW5wdXRzIGFuZCBvdXRwdXRzLlxuICBjb25zdCByZWZsZWN0ID0gZ2V0UmVmbGVjdCgpO1xuICBjb25zdCBwcm9wTWV0YWRhdGEgPSByZWZsZWN0Lm93blByb3BNZXRhZGF0YSh0eXBlKTtcblxuICByZXR1cm4ge1xuICAgIG5hbWU6IHR5cGUubmFtZSxcbiAgICB0eXBlOiB0eXBlLFxuICAgIHNlbGVjdG9yOiBtZXRhZGF0YS5zZWxlY3RvciAhPT0gdW5kZWZpbmVkID8gbWV0YWRhdGEuc2VsZWN0b3IgOiBudWxsLFxuICAgIGhvc3Q6IG1ldGFkYXRhLmhvc3QgfHwgRU1QVFlfT0JKLFxuICAgIHByb3BNZXRhZGF0YTogcHJvcE1ldGFkYXRhLFxuICAgIGlucHV0czogbWV0YWRhdGEuaW5wdXRzIHx8IEVNUFRZX0FSUkFZLFxuICAgIG91dHB1dHM6IG1ldGFkYXRhLm91dHB1dHMgfHwgRU1QVFlfQVJSQVksXG4gICAgcXVlcmllczogZXh0cmFjdFF1ZXJpZXNNZXRhZGF0YSh0eXBlLCBwcm9wTWV0YWRhdGEsIGlzQ29udGVudFF1ZXJ5KSxcbiAgICBsaWZlY3ljbGU6IHt1c2VzT25DaGFuZ2VzOiByZWZsZWN0Lmhhc0xpZmVjeWNsZUhvb2sodHlwZSwgJ25nT25DaGFuZ2VzJyl9LFxuICAgIHR5cGVTb3VyY2VTcGFuOiBudWxsISxcbiAgICB1c2VzSW5oZXJpdGFuY2U6ICFleHRlbmRzRGlyZWN0bHlGcm9tT2JqZWN0KHR5cGUpLFxuICAgIGV4cG9ydEFzOiBleHRyYWN0RXhwb3J0QXMobWV0YWRhdGEuZXhwb3J0QXMpLFxuICAgIHByb3ZpZGVyczogbWV0YWRhdGEucHJvdmlkZXJzIHx8IG51bGwsXG4gICAgdmlld1F1ZXJpZXM6IGV4dHJhY3RRdWVyaWVzTWV0YWRhdGEodHlwZSwgcHJvcE1ldGFkYXRhLCBpc1ZpZXdRdWVyeSksXG4gICAgaXNTdGFuZGFsb25lOiAhIW1ldGFkYXRhLnN0YW5kYWxvbmUsXG4gICAgaG9zdERpcmVjdGl2ZXM6IG1ldGFkYXRhLmhvc3REaXJlY3RpdmVzPy5tYXAoXG4gICAgICAgICAgICAgICAgICAgICAgICBkaXJlY3RpdmUgPT4gdHlwZW9mIGRpcmVjdGl2ZSA9PT0gJ2Z1bmN0aW9uJyA/IHtkaXJlY3RpdmV9IDogZGlyZWN0aXZlKSB8fFxuICAgICAgICBudWxsXG4gIH07XG59XG5cbi8qKlxuICogQWRkcyBhIGRpcmVjdGl2ZSBkZWZpbml0aW9uIHRvIGFsbCBwYXJlbnQgY2xhc3NlcyBvZiBhIHR5cGUgdGhhdCBkb24ndCBoYXZlIGFuIEFuZ3VsYXIgZGVjb3JhdG9yLlxuICovXG5mdW5jdGlvbiBhZGREaXJlY3RpdmVEZWZUb1VuZGVjb3JhdGVkUGFyZW50cyh0eXBlOiBUeXBlPGFueT4pIHtcbiAgY29uc3Qgb2JqUHJvdG90eXBlID0gT2JqZWN0LnByb3RvdHlwZTtcbiAgbGV0IHBhcmVudCA9IE9iamVjdC5nZXRQcm90b3R5cGVPZih0eXBlLnByb3RvdHlwZSkuY29uc3RydWN0b3I7XG5cbiAgLy8gR28gdXAgdGhlIHByb3RvdHlwZSB1bnRpbCB3ZSBoaXQgYE9iamVjdGAuXG4gIHdoaWxlIChwYXJlbnQgJiYgcGFyZW50ICE9PSBvYmpQcm90b3R5cGUpIHtcbiAgICAvLyBTaW5jZSBpbmhlcml0YW5jZSB3b3JrcyBpZiB0aGUgY2xhc3Mgd2FzIGFubm90YXRlZCBhbHJlYWR5LCB3ZSBvbmx5IG5lZWQgdG8gYWRkXG4gICAgLy8gdGhlIGRlZiBpZiB0aGVyZSBhcmUgbm8gYW5ub3RhdGlvbnMgYW5kIHRoZSBkZWYgaGFzbid0IGJlZW4gY3JlYXRlZCBhbHJlYWR5LlxuICAgIGlmICghZ2V0RGlyZWN0aXZlRGVmKHBhcmVudCkgJiYgIWdldENvbXBvbmVudERlZihwYXJlbnQpICYmXG4gICAgICAgIHNob3VsZEFkZEFic3RyYWN0RGlyZWN0aXZlKHBhcmVudCkpIHtcbiAgICAgIGNvbXBpbGVEaXJlY3RpdmUocGFyZW50LCBudWxsKTtcbiAgICB9XG4gICAgcGFyZW50ID0gT2JqZWN0LmdldFByb3RvdHlwZU9mKHBhcmVudCk7XG4gIH1cbn1cblxuZnVuY3Rpb24gY29udmVydFRvUjNRdWVyeVByZWRpY2F0ZShzZWxlY3RvcjogYW55KTogYW55fHN0cmluZ1tdIHtcbiAgcmV0dXJuIHR5cGVvZiBzZWxlY3RvciA9PT0gJ3N0cmluZycgPyBzcGxpdEJ5Q29tbWEoc2VsZWN0b3IpIDogcmVzb2x2ZUZvcndhcmRSZWYoc2VsZWN0b3IpO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY29udmVydFRvUjNRdWVyeU1ldGFkYXRhKHByb3BlcnR5TmFtZTogc3RyaW5nLCBhbm46IFF1ZXJ5KTogUjNRdWVyeU1ldGFkYXRhRmFjYWRlIHtcbiAgcmV0dXJuIHtcbiAgICBwcm9wZXJ0eU5hbWU6IHByb3BlcnR5TmFtZSxcbiAgICBwcmVkaWNhdGU6IGNvbnZlcnRUb1IzUXVlcnlQcmVkaWNhdGUoYW5uLnNlbGVjdG9yKSxcbiAgICBkZXNjZW5kYW50czogYW5uLmRlc2NlbmRhbnRzLFxuICAgIGZpcnN0OiBhbm4uZmlyc3QsXG4gICAgcmVhZDogYW5uLnJlYWQgPyBhbm4ucmVhZCA6IG51bGwsXG4gICAgc3RhdGljOiAhIWFubi5zdGF0aWMsXG4gICAgZW1pdERpc3RpbmN0Q2hhbmdlc09ubHk6ICEhYW5uLmVtaXREaXN0aW5jdENoYW5nZXNPbmx5LFxuICB9O1xufVxuZnVuY3Rpb24gZXh0cmFjdFF1ZXJpZXNNZXRhZGF0YShcbiAgICB0eXBlOiBUeXBlPGFueT4sIHByb3BNZXRhZGF0YToge1trZXk6IHN0cmluZ106IGFueVtdfSxcbiAgICBpc1F1ZXJ5QW5uOiAoYW5uOiBhbnkpID0+IGFubiBpcyBRdWVyeSk6IFIzUXVlcnlNZXRhZGF0YUZhY2FkZVtdIHtcbiAgY29uc3QgcXVlcmllc01ldGE6IFIzUXVlcnlNZXRhZGF0YUZhY2FkZVtdID0gW107XG4gIGZvciAoY29uc3QgZmllbGQgaW4gcHJvcE1ldGFkYXRhKSB7XG4gICAgaWYgKHByb3BNZXRhZGF0YS5oYXNPd25Qcm9wZXJ0eShmaWVsZCkpIHtcbiAgICAgIGNvbnN0IGFubm90YXRpb25zID0gcHJvcE1ldGFkYXRhW2ZpZWxkXTtcbiAgICAgIGFubm90YXRpb25zLmZvckVhY2goYW5uID0+IHtcbiAgICAgICAgaWYgKGlzUXVlcnlBbm4oYW5uKSkge1xuICAgICAgICAgIGlmICghYW5uLnNlbGVjdG9yKSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgICAgICAgYENhbid0IGNvbnN0cnVjdCBhIHF1ZXJ5IGZvciB0aGUgcHJvcGVydHkgXCIke2ZpZWxkfVwiIG9mIGAgK1xuICAgICAgICAgICAgICAgIGBcIiR7c3RyaW5naWZ5Rm9yRXJyb3IodHlwZSl9XCIgc2luY2UgdGhlIHF1ZXJ5IHNlbGVjdG9yIHdhc24ndCBkZWZpbmVkLmApO1xuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAoYW5ub3RhdGlvbnMuc29tZShpc0lucHV0QW5ub3RhdGlvbikpIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihgQ2Fubm90IGNvbWJpbmUgQElucHV0IGRlY29yYXRvcnMgd2l0aCBxdWVyeSBkZWNvcmF0b3JzYCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIHF1ZXJpZXNNZXRhLnB1c2goY29udmVydFRvUjNRdWVyeU1ldGFkYXRhKGZpZWxkLCBhbm4pKTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfVxuICB9XG4gIHJldHVybiBxdWVyaWVzTWV0YTtcbn1cblxuZnVuY3Rpb24gZXh0cmFjdEV4cG9ydEFzKGV4cG9ydEFzOiBzdHJpbmd8dW5kZWZpbmVkKTogc3RyaW5nW118bnVsbCB7XG4gIHJldHVybiBleHBvcnRBcyA9PT0gdW5kZWZpbmVkID8gbnVsbCA6IHNwbGl0QnlDb21tYShleHBvcnRBcyk7XG59XG5cbmZ1bmN0aW9uIGlzQ29udGVudFF1ZXJ5KHZhbHVlOiBhbnkpOiB2YWx1ZSBpcyBRdWVyeSB7XG4gIGNvbnN0IG5hbWUgPSB2YWx1ZS5uZ01ldGFkYXRhTmFtZTtcbiAgcmV0dXJuIG5hbWUgPT09ICdDb250ZW50Q2hpbGQnIHx8IG5hbWUgPT09ICdDb250ZW50Q2hpbGRyZW4nO1xufVxuXG5mdW5jdGlvbiBpc1ZpZXdRdWVyeSh2YWx1ZTogYW55KTogdmFsdWUgaXMgUXVlcnkge1xuICBjb25zdCBuYW1lID0gdmFsdWUubmdNZXRhZGF0YU5hbWU7XG4gIHJldHVybiBuYW1lID09PSAnVmlld0NoaWxkJyB8fCBuYW1lID09PSAnVmlld0NoaWxkcmVuJztcbn1cblxuZnVuY3Rpb24gaXNJbnB1dEFubm90YXRpb24odmFsdWU6IGFueSk6IHZhbHVlIGlzIElucHV0IHtcbiAgcmV0dXJuIHZhbHVlLm5nTWV0YWRhdGFOYW1lID09PSAnSW5wdXQnO1xufVxuXG5mdW5jdGlvbiBzcGxpdEJ5Q29tbWEodmFsdWU6IHN0cmluZyk6IHN0cmluZ1tdIHtcbiAgcmV0dXJuIHZhbHVlLnNwbGl0KCcsJykubWFwKHBpZWNlID0+IHBpZWNlLnRyaW0oKSk7XG59XG5cbmNvbnN0IExJRkVDWUNMRV9IT09LUyA9IFtcbiAgJ25nT25DaGFuZ2VzJywgJ25nT25Jbml0JywgJ25nT25EZXN0cm95JywgJ25nRG9DaGVjaycsICduZ0FmdGVyVmlld0luaXQnLCAnbmdBZnRlclZpZXdDaGVja2VkJyxcbiAgJ25nQWZ0ZXJDb250ZW50SW5pdCcsICduZ0FmdGVyQ29udGVudENoZWNrZWQnXG5dO1xuXG5mdW5jdGlvbiBzaG91bGRBZGRBYnN0cmFjdERpcmVjdGl2ZSh0eXBlOiBUeXBlPGFueT4pOiBib29sZWFuIHtcbiAgY29uc3QgcmVmbGVjdCA9IGdldFJlZmxlY3QoKTtcblxuICBpZiAoTElGRUNZQ0xFX0hPT0tTLnNvbWUoaG9va05hbWUgPT4gcmVmbGVjdC5oYXNMaWZlY3ljbGVIb29rKHR5cGUsIGhvb2tOYW1lKSkpIHtcbiAgICByZXR1cm4gdHJ1ZTtcbiAgfVxuXG4gIGNvbnN0IHByb3BNZXRhZGF0YSA9IHJlZmxlY3QucHJvcE1ldGFkYXRhKHR5cGUpO1xuXG4gIGZvciAoY29uc3QgZmllbGQgaW4gcHJvcE1ldGFkYXRhKSB7XG4gICAgY29uc3QgYW5ub3RhdGlvbnMgPSBwcm9wTWV0YWRhdGFbZmllbGRdO1xuXG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBhbm5vdGF0aW9ucy5sZW5ndGg7IGkrKykge1xuICAgICAgY29uc3QgY3VycmVudCA9IGFubm90YXRpb25zW2ldO1xuICAgICAgY29uc3QgbWV0YWRhdGFOYW1lID0gY3VycmVudC5uZ01ldGFkYXRhTmFtZTtcblxuICAgICAgaWYgKGlzSW5wdXRBbm5vdGF0aW9uKGN1cnJlbnQpIHx8IGlzQ29udGVudFF1ZXJ5KGN1cnJlbnQpIHx8IGlzVmlld1F1ZXJ5KGN1cnJlbnQpIHx8XG4gICAgICAgICAgbWV0YWRhdGFOYW1lID09PSAnT3V0cHV0JyB8fCBtZXRhZGF0YU5hbWUgPT09ICdIb3N0QmluZGluZycgfHxcbiAgICAgICAgICBtZXRhZGF0YU5hbWUgPT09ICdIb3N0TGlzdGVuZXInKSB7XG4gICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIHJldHVybiBmYWxzZTtcbn1cbiJdfQ==