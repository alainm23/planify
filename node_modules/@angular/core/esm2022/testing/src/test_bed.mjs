/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
// The formatter and CI disagree on how this import statement should be formatted. Both try to keep
// it on one line, too, which has gotten very hard to read & manage. So disable the formatter for
// this statement only.
/* clang-format off */
import { EnvironmentInjector, InjectFlags, Injector, NgZone, ɵconvertToBitFlags as convertToBitFlags, ɵflushModuleScopingQueueAsMuchAsPossible as flushModuleScopingQueueAsMuchAsPossible, ɵgetUnknownElementStrictMode as getUnknownElementStrictMode, ɵgetUnknownPropertyStrictMode as getUnknownPropertyStrictMode, ɵRender3ComponentFactory as ComponentFactory, ɵresetCompiledComponents as resetCompiledComponents, ɵsetAllowDuplicateNgModuleIdsForTest as setAllowDuplicateNgModuleIdsForTest, ɵsetUnknownElementStrictMode as setUnknownElementStrictMode, ɵsetUnknownPropertyStrictMode as setUnknownPropertyStrictMode, ɵstringify as stringify } from '@angular/core';
/* clang-format on */
import { ComponentFixture } from './component_fixture';
import { ComponentFixtureAutoDetect, ComponentFixtureNoNgZone, TEARDOWN_TESTING_MODULE_ON_DESTROY_DEFAULT, TestComponentRenderer, THROW_ON_UNKNOWN_ELEMENTS_DEFAULT, THROW_ON_UNKNOWN_PROPERTIES_DEFAULT } from './test_bed_common';
import { TestBedCompiler } from './test_bed_compiler';
let _nextRootElementId = 0;
/**
 * Returns a singleton of the `TestBed` class.
 *
 * @publicApi
 */
export function getTestBed() {
    return TestBedImpl.INSTANCE;
}
/**
 * @description
 * Configures and initializes environment for unit testing and provides methods for
 * creating components and services in unit tests.
 *
 * TestBed is the primary api for writing unit tests for Angular applications and libraries.
 */
class TestBedImpl {
    constructor() {
        // Properties
        this.platform = null;
        this.ngModule = null;
        this._compiler = null;
        this._testModuleRef = null;
        this._activeFixtures = [];
        /**
         * Internal-only flag to indicate whether a module
         * scoping queue has been checked and flushed already.
         * @nodoc
         */
        this.globalCompilationChecked = false;
    }
    static { this._INSTANCE = null; }
    static get INSTANCE() {
        return TestBedImpl._INSTANCE = TestBedImpl._INSTANCE || new TestBedImpl();
    }
    /**
     * Initialize the environment for testing with a compiler factory, a PlatformRef, and an
     * angular module. These are common to every test in the suite.
     *
     * This may only be called once, to set up the common providers for the current test
     * suite on the current platform. If you absolutely need to change the providers,
     * first use `resetTestEnvironment`.
     *
     * Test modules and platforms for individual platforms are available from
     * '@angular/<platform_name>/testing'.
     *
     * @publicApi
     */
    static initTestEnvironment(ngModule, platform, options) {
        const testBed = TestBedImpl.INSTANCE;
        testBed.initTestEnvironment(ngModule, platform, options);
        return testBed;
    }
    /**
     * Reset the providers for the test injector.
     *
     * @publicApi
     */
    static resetTestEnvironment() {
        TestBedImpl.INSTANCE.resetTestEnvironment();
    }
    static configureCompiler(config) {
        return TestBedImpl.INSTANCE.configureCompiler(config);
    }
    /**
     * Allows overriding default providers, directives, pipes, modules of the test injector,
     * which are defined in test_injector.js
     */
    static configureTestingModule(moduleDef) {
        return TestBedImpl.INSTANCE.configureTestingModule(moduleDef);
    }
    /**
     * Compile components with a `templateUrl` for the test's NgModule.
     * It is necessary to call this function
     * as fetching urls is asynchronous.
     */
    static compileComponents() {
        return TestBedImpl.INSTANCE.compileComponents();
    }
    static overrideModule(ngModule, override) {
        return TestBedImpl.INSTANCE.overrideModule(ngModule, override);
    }
    static overrideComponent(component, override) {
        return TestBedImpl.INSTANCE.overrideComponent(component, override);
    }
    static overrideDirective(directive, override) {
        return TestBedImpl.INSTANCE.overrideDirective(directive, override);
    }
    static overridePipe(pipe, override) {
        return TestBedImpl.INSTANCE.overridePipe(pipe, override);
    }
    static overrideTemplate(component, template) {
        return TestBedImpl.INSTANCE.overrideTemplate(component, template);
    }
    /**
     * Overrides the template of the given component, compiling the template
     * in the context of the TestingModule.
     *
     * Note: This works for JIT and AOTed components as well.
     */
    static overrideTemplateUsingTestingModule(component, template) {
        return TestBedImpl.INSTANCE.overrideTemplateUsingTestingModule(component, template);
    }
    static overrideProvider(token, provider) {
        return TestBedImpl.INSTANCE.overrideProvider(token, provider);
    }
    static inject(token, notFoundValue, flags) {
        return TestBedImpl.INSTANCE.inject(token, notFoundValue, convertToBitFlags(flags));
    }
    /** @deprecated from v9.0.0 use TestBed.inject */
    static get(token, notFoundValue = Injector.THROW_IF_NOT_FOUND, flags = InjectFlags.Default) {
        return TestBedImpl.INSTANCE.inject(token, notFoundValue, flags);
    }
    /**
     * Runs the given function in the `EnvironmentInjector` context of `TestBed`.
     *
     * @see EnvironmentInjector#runInContext
     */
    static runInInjectionContext(fn) {
        return TestBedImpl.INSTANCE.runInInjectionContext(fn);
    }
    static createComponent(component) {
        return TestBedImpl.INSTANCE.createComponent(component);
    }
    static resetTestingModule() {
        return TestBedImpl.INSTANCE.resetTestingModule();
    }
    static execute(tokens, fn, context) {
        return TestBedImpl.INSTANCE.execute(tokens, fn, context);
    }
    static get platform() {
        return TestBedImpl.INSTANCE.platform;
    }
    static get ngModule() {
        return TestBedImpl.INSTANCE.ngModule;
    }
    /**
     * Initialize the environment for testing with a compiler factory, a PlatformRef, and an
     * angular module. These are common to every test in the suite.
     *
     * This may only be called once, to set up the common providers for the current test
     * suite on the current platform. If you absolutely need to change the providers,
     * first use `resetTestEnvironment`.
     *
     * Test modules and platforms for individual platforms are available from
     * '@angular/<platform_name>/testing'.
     *
     * @publicApi
     */
    initTestEnvironment(ngModule, platform, options) {
        if (this.platform || this.ngModule) {
            throw new Error('Cannot set base providers because it has already been called');
        }
        TestBedImpl._environmentTeardownOptions = options?.teardown;
        TestBedImpl._environmentErrorOnUnknownElementsOption = options?.errorOnUnknownElements;
        TestBedImpl._environmentErrorOnUnknownPropertiesOption = options?.errorOnUnknownProperties;
        this.platform = platform;
        this.ngModule = ngModule;
        this._compiler = new TestBedCompiler(this.platform, this.ngModule);
        // TestBed does not have an API which can reliably detect the start of a test, and thus could be
        // used to track the state of the NgModule registry and reset it correctly. Instead, when we
        // know we're in a testing scenario, we disable the check for duplicate NgModule registration
        // completely.
        setAllowDuplicateNgModuleIdsForTest(true);
    }
    /**
     * Reset the providers for the test injector.
     *
     * @publicApi
     */
    resetTestEnvironment() {
        this.resetTestingModule();
        this._compiler = null;
        this.platform = null;
        this.ngModule = null;
        TestBedImpl._environmentTeardownOptions = undefined;
        setAllowDuplicateNgModuleIdsForTest(false);
    }
    resetTestingModule() {
        this.checkGlobalCompilationFinished();
        resetCompiledComponents();
        if (this._compiler !== null) {
            this.compiler.restoreOriginalState();
        }
        this._compiler = new TestBedCompiler(this.platform, this.ngModule);
        // Restore the previous value of the "error on unknown elements" option
        setUnknownElementStrictMode(this._previousErrorOnUnknownElementsOption ?? THROW_ON_UNKNOWN_ELEMENTS_DEFAULT);
        // Restore the previous value of the "error on unknown properties" option
        setUnknownPropertyStrictMode(this._previousErrorOnUnknownPropertiesOption ?? THROW_ON_UNKNOWN_PROPERTIES_DEFAULT);
        // We have to chain a couple of try/finally blocks, because each step can
        // throw errors and we don't want it to interrupt the next step and we also
        // want an error to be thrown at the end.
        try {
            this.destroyActiveFixtures();
        }
        finally {
            try {
                if (this.shouldTearDownTestingModule()) {
                    this.tearDownTestingModule();
                }
            }
            finally {
                this._testModuleRef = null;
                this._instanceTeardownOptions = undefined;
                this._instanceErrorOnUnknownElementsOption = undefined;
                this._instanceErrorOnUnknownPropertiesOption = undefined;
            }
        }
        return this;
    }
    configureCompiler(config) {
        if (config.useJit != null) {
            throw new Error('the Render3 compiler JiT mode is not configurable !');
        }
        if (config.providers !== undefined) {
            this.compiler.setCompilerProviders(config.providers);
        }
        return this;
    }
    configureTestingModule(moduleDef) {
        this.assertNotInstantiated('R3TestBed.configureTestingModule', 'configure the test module');
        // Trigger module scoping queue flush before executing other TestBed operations in a test.
        // This is needed for the first test invocation to ensure that globally declared modules have
        // their components scoped properly. See the `checkGlobalCompilationFinished` function
        // description for additional info.
        this.checkGlobalCompilationFinished();
        // Always re-assign the options, even if they're undefined.
        // This ensures that we don't carry them between tests.
        this._instanceTeardownOptions = moduleDef.teardown;
        this._instanceErrorOnUnknownElementsOption = moduleDef.errorOnUnknownElements;
        this._instanceErrorOnUnknownPropertiesOption = moduleDef.errorOnUnknownProperties;
        // Store the current value of the strict mode option,
        // so we can restore it later
        this._previousErrorOnUnknownElementsOption = getUnknownElementStrictMode();
        setUnknownElementStrictMode(this.shouldThrowErrorOnUnknownElements());
        this._previousErrorOnUnknownPropertiesOption = getUnknownPropertyStrictMode();
        setUnknownPropertyStrictMode(this.shouldThrowErrorOnUnknownProperties());
        this.compiler.configureTestingModule(moduleDef);
        return this;
    }
    compileComponents() {
        return this.compiler.compileComponents();
    }
    inject(token, notFoundValue, flags) {
        if (token === TestBed) {
            return this;
        }
        const UNDEFINED = {};
        const result = this.testModuleRef.injector.get(token, UNDEFINED, convertToBitFlags(flags));
        return result === UNDEFINED ? this.compiler.injector.get(token, notFoundValue, flags) :
            result;
    }
    /** @deprecated from v9.0.0 use TestBed.inject */
    get(token, notFoundValue = Injector.THROW_IF_NOT_FOUND, flags = InjectFlags.Default) {
        return this.inject(token, notFoundValue, flags);
    }
    runInInjectionContext(fn) {
        return this.inject(EnvironmentInjector).runInContext(fn);
    }
    execute(tokens, fn, context) {
        const params = tokens.map(t => this.inject(t));
        return fn.apply(context, params);
    }
    overrideModule(ngModule, override) {
        this.assertNotInstantiated('overrideModule', 'override module metadata');
        this.compiler.overrideModule(ngModule, override);
        return this;
    }
    overrideComponent(component, override) {
        this.assertNotInstantiated('overrideComponent', 'override component metadata');
        this.compiler.overrideComponent(component, override);
        return this;
    }
    overrideTemplateUsingTestingModule(component, template) {
        this.assertNotInstantiated('R3TestBed.overrideTemplateUsingTestingModule', 'Cannot override template when the test module has already been instantiated');
        this.compiler.overrideTemplateUsingTestingModule(component, template);
        return this;
    }
    overrideDirective(directive, override) {
        this.assertNotInstantiated('overrideDirective', 'override directive metadata');
        this.compiler.overrideDirective(directive, override);
        return this;
    }
    overridePipe(pipe, override) {
        this.assertNotInstantiated('overridePipe', 'override pipe metadata');
        this.compiler.overridePipe(pipe, override);
        return this;
    }
    /**
     * Overwrites all providers for the given token with the given provider definition.
     */
    overrideProvider(token, provider) {
        this.assertNotInstantiated('overrideProvider', 'override provider');
        this.compiler.overrideProvider(token, provider);
        return this;
    }
    overrideTemplate(component, template) {
        return this.overrideComponent(component, { set: { template, templateUrl: null } });
    }
    createComponent(type) {
        const testComponentRenderer = this.inject(TestComponentRenderer);
        const rootElId = `root${_nextRootElementId++}`;
        testComponentRenderer.insertRootElement(rootElId);
        const componentDef = type.ɵcmp;
        if (!componentDef) {
            throw new Error(`It looks like '${stringify(type)}' has not been compiled.`);
        }
        const noNgZone = this.inject(ComponentFixtureNoNgZone, false);
        const autoDetect = this.inject(ComponentFixtureAutoDetect, false);
        const ngZone = noNgZone ? null : this.inject(NgZone, null);
        const componentFactory = new ComponentFactory(componentDef);
        const initComponent = () => {
            const componentRef = componentFactory.create(Injector.NULL, [], `#${rootElId}`, this.testModuleRef);
            return new ComponentFixture(componentRef, ngZone, autoDetect);
        };
        const fixture = ngZone ? ngZone.run(initComponent) : initComponent();
        this._activeFixtures.push(fixture);
        return fixture;
    }
    /**
     * @internal strip this from published d.ts files due to
     * https://github.com/microsoft/TypeScript/issues/36216
     */
    get compiler() {
        if (this._compiler === null) {
            throw new Error(`Need to call TestBed.initTestEnvironment() first`);
        }
        return this._compiler;
    }
    /**
     * @internal strip this from published d.ts files due to
     * https://github.com/microsoft/TypeScript/issues/36216
     */
    get testModuleRef() {
        if (this._testModuleRef === null) {
            this._testModuleRef = this.compiler.finalize();
        }
        return this._testModuleRef;
    }
    assertNotInstantiated(methodName, methodDescription) {
        if (this._testModuleRef !== null) {
            throw new Error(`Cannot ${methodDescription} when the test module has already been instantiated. ` +
                `Make sure you are not using \`inject\` before \`${methodName}\`.`);
        }
    }
    /**
     * Check whether the module scoping queue should be flushed, and flush it if needed.
     *
     * When the TestBed is reset, it clears the JIT module compilation queue, cancelling any
     * in-progress module compilation. This creates a potential hazard - the very first time the
     * TestBed is initialized (or if it's reset without being initialized), there may be pending
     * compilations of modules declared in global scope. These compilations should be finished.
     *
     * To ensure that globally declared modules have their components scoped properly, this function
     * is called whenever TestBed is initialized or reset. The _first_ time that this happens, prior
     * to any other operations, the scoping queue is flushed.
     */
    checkGlobalCompilationFinished() {
        // Checking _testNgModuleRef is null should not be necessary, but is left in as an additional
        // guard that compilations queued in tests (after instantiation) are never flushed accidentally.
        if (!this.globalCompilationChecked && this._testModuleRef === null) {
            flushModuleScopingQueueAsMuchAsPossible();
        }
        this.globalCompilationChecked = true;
    }
    destroyActiveFixtures() {
        let errorCount = 0;
        this._activeFixtures.forEach((fixture) => {
            try {
                fixture.destroy();
            }
            catch (e) {
                errorCount++;
                console.error('Error during cleanup of component', {
                    component: fixture.componentInstance,
                    stacktrace: e,
                });
            }
        });
        this._activeFixtures = [];
        if (errorCount > 0 && this.shouldRethrowTeardownErrors()) {
            throw Error(`${errorCount} ${(errorCount === 1 ? 'component' : 'components')} ` +
                `threw errors during cleanup`);
        }
    }
    shouldRethrowTeardownErrors() {
        const instanceOptions = this._instanceTeardownOptions;
        const environmentOptions = TestBedImpl._environmentTeardownOptions;
        // If the new teardown behavior hasn't been configured, preserve the old behavior.
        if (!instanceOptions && !environmentOptions) {
            return TEARDOWN_TESTING_MODULE_ON_DESTROY_DEFAULT;
        }
        // Otherwise use the configured behavior or default to rethrowing.
        return instanceOptions?.rethrowErrors ?? environmentOptions?.rethrowErrors ??
            this.shouldTearDownTestingModule();
    }
    shouldThrowErrorOnUnknownElements() {
        // Check if a configuration has been provided to throw when an unknown element is found
        return this._instanceErrorOnUnknownElementsOption ??
            TestBedImpl._environmentErrorOnUnknownElementsOption ?? THROW_ON_UNKNOWN_ELEMENTS_DEFAULT;
    }
    shouldThrowErrorOnUnknownProperties() {
        // Check if a configuration has been provided to throw when an unknown property is found
        return this._instanceErrorOnUnknownPropertiesOption ??
            TestBedImpl._environmentErrorOnUnknownPropertiesOption ??
            THROW_ON_UNKNOWN_PROPERTIES_DEFAULT;
    }
    shouldTearDownTestingModule() {
        return this._instanceTeardownOptions?.destroyAfterEach ??
            TestBedImpl._environmentTeardownOptions?.destroyAfterEach ??
            TEARDOWN_TESTING_MODULE_ON_DESTROY_DEFAULT;
    }
    tearDownTestingModule() {
        // If the module ref has already been destroyed, we won't be able to get a test renderer.
        if (this._testModuleRef === null) {
            return;
        }
        // Resolve the renderer ahead of time, because we want to remove the root elements as the very
        // last step, but the injector will be destroyed as a part of the module ref destruction.
        const testRenderer = this.inject(TestComponentRenderer);
        try {
            this._testModuleRef.destroy();
        }
        catch (e) {
            if (this.shouldRethrowTeardownErrors()) {
                throw e;
            }
            else {
                console.error('Error during cleanup of a testing module', {
                    component: this._testModuleRef.instance,
                    stacktrace: e,
                });
            }
        }
        finally {
            testRenderer.removeAllRootElements?.();
        }
    }
}
export { TestBedImpl };
/**
 * @description
 * Configures and initializes environment for unit testing and provides methods for
 * creating components and services in unit tests.
 *
 * `TestBed` is the primary api for writing unit tests for Angular applications and libraries.
 *
 * @publicApi
 */
export const TestBed = TestBedImpl;
/**
 * Allows injecting dependencies in `beforeEach()` and `it()`. Note: this function
 * (imported from the `@angular/core/testing` package) can **only** be used to inject dependencies
 * in tests. To inject dependencies in your application code, use the [`inject`](api/core/inject)
 * function from the `@angular/core` package instead.
 *
 * Example:
 *
 * ```
 * beforeEach(inject([Dependency, AClass], (dep, object) => {
 *   // some code that uses `dep` and `object`
 *   // ...
 * }));
 *
 * it('...', inject([AClass], (object) => {
 *   object.doSomething();
 *   expect(...);
 * })
 * ```
 *
 * @publicApi
 */
export function inject(tokens, fn) {
    const testBed = TestBedImpl.INSTANCE;
    // Not using an arrow function to preserve context passed from call site
    return function () {
        return testBed.execute(tokens, fn, this);
    };
}
/**
 * @publicApi
 */
export class InjectSetupWrapper {
    constructor(_moduleDef) {
        this._moduleDef = _moduleDef;
    }
    _addModule() {
        const moduleDef = this._moduleDef();
        if (moduleDef) {
            TestBedImpl.configureTestingModule(moduleDef);
        }
    }
    inject(tokens, fn) {
        const self = this;
        // Not using an arrow function to preserve context passed from call site
        return function () {
            self._addModule();
            return inject(tokens, fn).call(this);
        };
    }
}
export function withModule(moduleDef, fn) {
    if (fn) {
        // Not using an arrow function to preserve context passed from call site
        return function () {
            const testBed = TestBedImpl.INSTANCE;
            if (moduleDef) {
                testBed.configureTestingModule(moduleDef);
            }
            return fn.apply(this);
        };
    }
    return new InjectSetupWrapper(() => moduleDef);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidGVzdF9iZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb3JlL3Rlc3Rpbmcvc3JjL3Rlc3RfYmVkLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILG1HQUFtRztBQUNuRyxpR0FBaUc7QUFDakcsdUJBQXVCO0FBRXZCLHNCQUFzQjtBQUN0QixPQUFPLEVBR0wsbUJBQW1CLEVBQ25CLFdBQVcsRUFHWCxRQUFRLEVBRVIsTUFBTSxFQUtOLGtCQUFrQixJQUFJLGlCQUFpQixFQUN2Qyx3Q0FBd0MsSUFBSSx1Q0FBdUMsRUFDbkYsNEJBQTRCLElBQUksMkJBQTJCLEVBQzNELDZCQUE2QixJQUFJLDRCQUE0QixFQUM3RCx3QkFBd0IsSUFBSSxnQkFBZ0IsRUFFNUMsd0JBQXdCLElBQUksdUJBQXVCLEVBQ25ELG9DQUFvQyxJQUFJLG1DQUFtQyxFQUMzRSw0QkFBNEIsSUFBSSwyQkFBMkIsRUFDM0QsNkJBQTZCLElBQUksNEJBQTRCLEVBQzdELFVBQVUsSUFBSSxTQUFTLEVBQ3hCLE1BQU0sZUFBZSxDQUFDO0FBRXZCLHFCQUFxQjtBQUVyQixPQUFPLEVBQUMsZ0JBQWdCLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQUVyRCxPQUFPLEVBQUMsMEJBQTBCLEVBQUUsd0JBQXdCLEVBQXlCLDBDQUEwQyxFQUFFLHFCQUFxQixFQUE4QyxpQ0FBaUMsRUFBRSxtQ0FBbUMsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBQ3JTLE9BQU8sRUFBQyxlQUFlLEVBQUMsTUFBTSxxQkFBcUIsQ0FBQztBQWdHcEQsSUFBSSxrQkFBa0IsR0FBRyxDQUFDLENBQUM7QUFFM0I7Ozs7R0FJRztBQUNILE1BQU0sVUFBVSxVQUFVO0lBQ3hCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQztBQUM5QixDQUFDO0FBRUQ7Ozs7OztHQU1HO0FBQ0gsTUFBYSxXQUFXO0lBQXhCO1FBNE1FLGFBQWE7UUFFYixhQUFRLEdBQWdCLElBQUssQ0FBQztRQUM5QixhQUFRLEdBQTBCLElBQUssQ0FBQztRQUVoQyxjQUFTLEdBQXlCLElBQUksQ0FBQztRQUN2QyxtQkFBYyxHQUEwQixJQUFJLENBQUM7UUFFN0Msb0JBQWUsR0FBNEIsRUFBRSxDQUFDO1FBRXREOzs7O1dBSUc7UUFDSCw2QkFBd0IsR0FBRyxLQUFLLENBQUM7SUE2V25DLENBQUM7YUF2a0JnQixjQUFTLEdBQXFCLElBQUksQUFBekIsQ0FBMEI7SUFFbEQsTUFBTSxLQUFLLFFBQVE7UUFDakIsT0FBTyxXQUFXLENBQUMsU0FBUyxHQUFHLFdBQVcsQ0FBQyxTQUFTLElBQUksSUFBSSxXQUFXLEVBQUUsQ0FBQztJQUM1RSxDQUFDO0lBa0REOzs7Ozs7Ozs7Ozs7T0FZRztJQUNILE1BQU0sQ0FBQyxtQkFBbUIsQ0FDdEIsUUFBK0IsRUFBRSxRQUFxQixFQUN0RCxPQUFnQztRQUNsQyxNQUFNLE9BQU8sR0FBRyxXQUFXLENBQUMsUUFBUSxDQUFDO1FBQ3JDLE9BQU8sQ0FBQyxtQkFBbUIsQ0FBQyxRQUFRLEVBQUUsUUFBUSxFQUFFLE9BQU8sQ0FBQyxDQUFDO1FBQ3pELE9BQU8sT0FBTyxDQUFDO0lBQ2pCLENBQUM7SUFFRDs7OztPQUlHO0lBQ0gsTUFBTSxDQUFDLG9CQUFvQjtRQUN6QixXQUFXLENBQUMsUUFBUSxDQUFDLG9CQUFvQixFQUFFLENBQUM7SUFDOUMsQ0FBQztJQUVELE1BQU0sQ0FBQyxpQkFBaUIsQ0FBQyxNQUE4QztRQUNyRSxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsaUJBQWlCLENBQUMsTUFBTSxDQUFDLENBQUM7SUFDeEQsQ0FBQztJQUVEOzs7T0FHRztJQUNILE1BQU0sQ0FBQyxzQkFBc0IsQ0FBQyxTQUE2QjtRQUN6RCxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsc0JBQXNCLENBQUMsU0FBUyxDQUFDLENBQUM7SUFDaEUsQ0FBQztJQUVEOzs7O09BSUc7SUFDSCxNQUFNLENBQUMsaUJBQWlCO1FBQ3RCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsRUFBRSxDQUFDO0lBQ2xELENBQUM7SUFFRCxNQUFNLENBQUMsY0FBYyxDQUFDLFFBQW1CLEVBQUUsUUFBb0M7UUFDN0UsT0FBTyxXQUFXLENBQUMsUUFBUSxDQUFDLGNBQWMsQ0FBQyxRQUFRLEVBQUUsUUFBUSxDQUFDLENBQUM7SUFDakUsQ0FBQztJQUVELE1BQU0sQ0FBQyxpQkFBaUIsQ0FBQyxTQUFvQixFQUFFLFFBQXFDO1FBQ2xGLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsQ0FBQyxTQUFTLEVBQUUsUUFBUSxDQUFDLENBQUM7SUFDckUsQ0FBQztJQUVELE1BQU0sQ0FBQyxpQkFBaUIsQ0FBQyxTQUFvQixFQUFFLFFBQXFDO1FBQ2xGLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsQ0FBQyxTQUFTLEVBQUUsUUFBUSxDQUFDLENBQUM7SUFDckUsQ0FBQztJQUVELE1BQU0sQ0FBQyxZQUFZLENBQUMsSUFBZSxFQUFFLFFBQWdDO1FBQ25FLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxZQUFZLENBQUMsSUFBSSxFQUFFLFFBQVEsQ0FBQyxDQUFDO0lBQzNELENBQUM7SUFFRCxNQUFNLENBQUMsZ0JBQWdCLENBQUMsU0FBb0IsRUFBRSxRQUFnQjtRQUM1RCxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsZ0JBQWdCLENBQUMsU0FBUyxFQUFFLFFBQVEsQ0FBQyxDQUFDO0lBQ3BFLENBQUM7SUFFRDs7Ozs7T0FLRztJQUNILE1BQU0sQ0FBQyxrQ0FBa0MsQ0FBQyxTQUFvQixFQUFFLFFBQWdCO1FBQzlFLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxrQ0FBa0MsQ0FBQyxTQUFTLEVBQUUsUUFBUSxDQUFDLENBQUM7SUFDdEYsQ0FBQztJQU9ELE1BQU0sQ0FBQyxnQkFBZ0IsQ0FBQyxLQUFVLEVBQUUsUUFJbkM7UUFDQyxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsZ0JBQWdCLENBQUMsS0FBSyxFQUFFLFFBQVEsQ0FBQyxDQUFDO0lBQ2hFLENBQUM7SUFZRCxNQUFNLENBQUMsTUFBTSxDQUNULEtBQXVCLEVBQUUsYUFBc0IsRUFBRSxLQUFpQztRQUNwRixPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsTUFBTSxDQUFDLEtBQUssRUFBRSxhQUFhLEVBQUUsaUJBQWlCLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQztJQUNyRixDQUFDO0lBTUQsaURBQWlEO0lBQ2pELE1BQU0sQ0FBQyxHQUFHLENBQ04sS0FBVSxFQUFFLGdCQUFxQixRQUFRLENBQUMsa0JBQWtCLEVBQzVELFFBQXFCLFdBQVcsQ0FBQyxPQUFPO1FBQzFDLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxNQUFNLENBQUMsS0FBSyxFQUFFLGFBQWEsRUFBRSxLQUFLLENBQUMsQ0FBQztJQUNsRSxDQUFDO0lBRUQ7Ozs7T0FJRztJQUNILE1BQU0sQ0FBQyxxQkFBcUIsQ0FBSSxFQUFXO1FBQ3pDLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxxQkFBcUIsQ0FBQyxFQUFFLENBQUMsQ0FBQztJQUN4RCxDQUFDO0lBRUQsTUFBTSxDQUFDLGVBQWUsQ0FBSSxTQUFrQjtRQUMxQyxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsZUFBZSxDQUFDLFNBQVMsQ0FBQyxDQUFDO0lBQ3pELENBQUM7SUFFRCxNQUFNLENBQUMsa0JBQWtCO1FBQ3ZCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxrQkFBa0IsRUFBRSxDQUFDO0lBQ25ELENBQUM7SUFFRCxNQUFNLENBQUMsT0FBTyxDQUFDLE1BQWEsRUFBRSxFQUFZLEVBQUUsT0FBYTtRQUN2RCxPQUFPLFdBQVcsQ0FBQyxRQUFRLENBQUMsT0FBTyxDQUFDLE1BQU0sRUFBRSxFQUFFLEVBQUUsT0FBTyxDQUFDLENBQUM7SUFDM0QsQ0FBQztJQUVELE1BQU0sS0FBSyxRQUFRO1FBQ2pCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxRQUFRLENBQUM7SUFDdkMsQ0FBQztJQUVELE1BQU0sS0FBSyxRQUFRO1FBQ2pCLE9BQU8sV0FBVyxDQUFDLFFBQVEsQ0FBQyxRQUFRLENBQUM7SUFDdkMsQ0FBQztJQW1CRDs7Ozs7Ozs7Ozs7O09BWUc7SUFDSCxtQkFBbUIsQ0FDZixRQUErQixFQUFFLFFBQXFCLEVBQ3RELE9BQWdDO1FBQ2xDLElBQUksSUFBSSxDQUFDLFFBQVEsSUFBSSxJQUFJLENBQUMsUUFBUSxFQUFFO1lBQ2xDLE1BQU0sSUFBSSxLQUFLLENBQUMsOERBQThELENBQUMsQ0FBQztTQUNqRjtRQUVELFdBQVcsQ0FBQywyQkFBMkIsR0FBRyxPQUFPLEVBQUUsUUFBUSxDQUFDO1FBRTVELFdBQVcsQ0FBQyx3Q0FBd0MsR0FBRyxPQUFPLEVBQUUsc0JBQXNCLENBQUM7UUFFdkYsV0FBVyxDQUFDLDBDQUEwQyxHQUFHLE9BQU8sRUFBRSx3QkFBd0IsQ0FBQztRQUUzRixJQUFJLENBQUMsUUFBUSxHQUFHLFFBQVEsQ0FBQztRQUN6QixJQUFJLENBQUMsUUFBUSxHQUFHLFFBQVEsQ0FBQztRQUN6QixJQUFJLENBQUMsU0FBUyxHQUFHLElBQUksZUFBZSxDQUFDLElBQUksQ0FBQyxRQUFRLEVBQUUsSUFBSSxDQUFDLFFBQVEsQ0FBQyxDQUFDO1FBRW5FLGdHQUFnRztRQUNoRyw0RkFBNEY7UUFDNUYsNkZBQTZGO1FBQzdGLGNBQWM7UUFDZCxtQ0FBbUMsQ0FBQyxJQUFJLENBQUMsQ0FBQztJQUM1QyxDQUFDO0lBRUQ7Ozs7T0FJRztJQUNILG9CQUFvQjtRQUNsQixJQUFJLENBQUMsa0JBQWtCLEVBQUUsQ0FBQztRQUMxQixJQUFJLENBQUMsU0FBUyxHQUFHLElBQUksQ0FBQztRQUN0QixJQUFJLENBQUMsUUFBUSxHQUFHLElBQUssQ0FBQztRQUN0QixJQUFJLENBQUMsUUFBUSxHQUFHLElBQUssQ0FBQztRQUN0QixXQUFXLENBQUMsMkJBQTJCLEdBQUcsU0FBUyxDQUFDO1FBQ3BELG1DQUFtQyxDQUFDLEtBQUssQ0FBQyxDQUFDO0lBQzdDLENBQUM7SUFFRCxrQkFBa0I7UUFDaEIsSUFBSSxDQUFDLDhCQUE4QixFQUFFLENBQUM7UUFDdEMsdUJBQXVCLEVBQUUsQ0FBQztRQUMxQixJQUFJLElBQUksQ0FBQyxTQUFTLEtBQUssSUFBSSxFQUFFO1lBQzNCLElBQUksQ0FBQyxRQUFRLENBQUMsb0JBQW9CLEVBQUUsQ0FBQztTQUN0QztRQUNELElBQUksQ0FBQyxTQUFTLEdBQUcsSUFBSSxlQUFlLENBQUMsSUFBSSxDQUFDLFFBQVEsRUFBRSxJQUFJLENBQUMsUUFBUSxDQUFDLENBQUM7UUFDbkUsdUVBQXVFO1FBQ3ZFLDJCQUEyQixDQUN2QixJQUFJLENBQUMscUNBQXFDLElBQUksaUNBQWlDLENBQUMsQ0FBQztRQUNyRix5RUFBeUU7UUFDekUsNEJBQTRCLENBQ3hCLElBQUksQ0FBQyx1Q0FBdUMsSUFBSSxtQ0FBbUMsQ0FBQyxDQUFDO1FBRXpGLHlFQUF5RTtRQUN6RSwyRUFBMkU7UUFDM0UseUNBQXlDO1FBQ3pDLElBQUk7WUFDRixJQUFJLENBQUMscUJBQXFCLEVBQUUsQ0FBQztTQUM5QjtnQkFBUztZQUNSLElBQUk7Z0JBQ0YsSUFBSSxJQUFJLENBQUMsMkJBQTJCLEVBQUUsRUFBRTtvQkFDdEMsSUFBSSxDQUFDLHFCQUFxQixFQUFFLENBQUM7aUJBQzlCO2FBQ0Y7b0JBQVM7Z0JBQ1IsSUFBSSxDQUFDLGNBQWMsR0FBRyxJQUFJLENBQUM7Z0JBQzNCLElBQUksQ0FBQyx3QkFBd0IsR0FBRyxTQUFTLENBQUM7Z0JBQzFDLElBQUksQ0FBQyxxQ0FBcUMsR0FBRyxTQUFTLENBQUM7Z0JBQ3ZELElBQUksQ0FBQyx1Q0FBdUMsR0FBRyxTQUFTLENBQUM7YUFDMUQ7U0FDRjtRQUNELE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELGlCQUFpQixDQUFDLE1BQThDO1FBQzlELElBQUksTUFBTSxDQUFDLE1BQU0sSUFBSSxJQUFJLEVBQUU7WUFDekIsTUFBTSxJQUFJLEtBQUssQ0FBQyxxREFBcUQsQ0FBQyxDQUFDO1NBQ3hFO1FBRUQsSUFBSSxNQUFNLENBQUMsU0FBUyxLQUFLLFNBQVMsRUFBRTtZQUNsQyxJQUFJLENBQUMsUUFBUSxDQUFDLG9CQUFvQixDQUFDLE1BQU0sQ0FBQyxTQUFTLENBQUMsQ0FBQztTQUN0RDtRQUNELE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELHNCQUFzQixDQUFDLFNBQTZCO1FBQ2xELElBQUksQ0FBQyxxQkFBcUIsQ0FBQyxrQ0FBa0MsRUFBRSwyQkFBMkIsQ0FBQyxDQUFDO1FBRTVGLDBGQUEwRjtRQUMxRiw2RkFBNkY7UUFDN0Ysc0ZBQXNGO1FBQ3RGLG1DQUFtQztRQUNuQyxJQUFJLENBQUMsOEJBQThCLEVBQUUsQ0FBQztRQUV0QywyREFBMkQ7UUFDM0QsdURBQXVEO1FBQ3ZELElBQUksQ0FBQyx3QkFBd0IsR0FBRyxTQUFTLENBQUMsUUFBUSxDQUFDO1FBQ25ELElBQUksQ0FBQyxxQ0FBcUMsR0FBRyxTQUFTLENBQUMsc0JBQXNCLENBQUM7UUFDOUUsSUFBSSxDQUFDLHVDQUF1QyxHQUFHLFNBQVMsQ0FBQyx3QkFBd0IsQ0FBQztRQUNsRixxREFBcUQ7UUFDckQsNkJBQTZCO1FBQzdCLElBQUksQ0FBQyxxQ0FBcUMsR0FBRywyQkFBMkIsRUFBRSxDQUFDO1FBQzNFLDJCQUEyQixDQUFDLElBQUksQ0FBQyxpQ0FBaUMsRUFBRSxDQUFDLENBQUM7UUFDdEUsSUFBSSxDQUFDLHVDQUF1QyxHQUFHLDRCQUE0QixFQUFFLENBQUM7UUFDOUUsNEJBQTRCLENBQUMsSUFBSSxDQUFDLG1DQUFtQyxFQUFFLENBQUMsQ0FBQztRQUN6RSxJQUFJLENBQUMsUUFBUSxDQUFDLHNCQUFzQixDQUFDLFNBQVMsQ0FBQyxDQUFDO1FBQ2hELE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELGlCQUFpQjtRQUNmLE9BQU8sSUFBSSxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsRUFBRSxDQUFDO0lBQzNDLENBQUM7SUFXRCxNQUFNLENBQUksS0FBdUIsRUFBRSxhQUFzQixFQUFFLEtBQWlDO1FBRTFGLElBQUksS0FBZ0IsS0FBSyxPQUFPLEVBQUU7WUFDaEMsT0FBTyxJQUFXLENBQUM7U0FDcEI7UUFDRCxNQUFNLFNBQVMsR0FBRyxFQUFrQixDQUFDO1FBQ3JDLE1BQU0sTUFBTSxHQUFHLElBQUksQ0FBQyxhQUFhLENBQUMsUUFBUSxDQUFDLEdBQUcsQ0FBQyxLQUFLLEVBQUUsU0FBUyxFQUFFLGlCQUFpQixDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUM7UUFDM0YsT0FBTyxNQUFNLEtBQUssU0FBUyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsUUFBUSxDQUFDLFFBQVEsQ0FBQyxHQUFHLENBQUMsS0FBSyxFQUFFLGFBQWEsRUFBRSxLQUFLLENBQVEsQ0FBQyxDQUFDO1lBQ2hFLE1BQU0sQ0FBQztJQUN2QyxDQUFDO0lBTUQsaURBQWlEO0lBQ2pELEdBQUcsQ0FBQyxLQUFVLEVBQUUsZ0JBQXFCLFFBQVEsQ0FBQyxrQkFBa0IsRUFDNUQsUUFBcUIsV0FBVyxDQUFDLE9BQU87UUFDMUMsT0FBTyxJQUFJLENBQUMsTUFBTSxDQUFDLEtBQUssRUFBRSxhQUFhLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFDbEQsQ0FBQztJQUVELHFCQUFxQixDQUFJLEVBQVc7UUFDbEMsT0FBTyxJQUFJLENBQUMsTUFBTSxDQUFDLG1CQUFtQixDQUFDLENBQUMsWUFBWSxDQUFDLEVBQUUsQ0FBQyxDQUFDO0lBQzNELENBQUM7SUFFRCxPQUFPLENBQUMsTUFBYSxFQUFFLEVBQVksRUFBRSxPQUFhO1FBQ2hELE1BQU0sTUFBTSxHQUFHLE1BQU0sQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUM7UUFDL0MsT0FBTyxFQUFFLENBQUMsS0FBSyxDQUFDLE9BQU8sRUFBRSxNQUFNLENBQUMsQ0FBQztJQUNuQyxDQUFDO0lBRUQsY0FBYyxDQUFDLFFBQW1CLEVBQUUsUUFBb0M7UUFDdEUsSUFBSSxDQUFDLHFCQUFxQixDQUFDLGdCQUFnQixFQUFFLDBCQUEwQixDQUFDLENBQUM7UUFDekUsSUFBSSxDQUFDLFFBQVEsQ0FBQyxjQUFjLENBQUMsUUFBUSxFQUFFLFFBQVEsQ0FBQyxDQUFDO1FBQ2pELE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELGlCQUFpQixDQUFDLFNBQW9CLEVBQUUsUUFBcUM7UUFDM0UsSUFBSSxDQUFDLHFCQUFxQixDQUFDLG1CQUFtQixFQUFFLDZCQUE2QixDQUFDLENBQUM7UUFDL0UsSUFBSSxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsQ0FBQyxTQUFTLEVBQUUsUUFBUSxDQUFDLENBQUM7UUFDckQsT0FBTyxJQUFJLENBQUM7SUFDZCxDQUFDO0lBRUQsa0NBQWtDLENBQUMsU0FBb0IsRUFBRSxRQUFnQjtRQUN2RSxJQUFJLENBQUMscUJBQXFCLENBQ3RCLDhDQUE4QyxFQUM5Qyw2RUFBNkUsQ0FBQyxDQUFDO1FBQ25GLElBQUksQ0FBQyxRQUFRLENBQUMsa0NBQWtDLENBQUMsU0FBUyxFQUFFLFFBQVEsQ0FBQyxDQUFDO1FBQ3RFLE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELGlCQUFpQixDQUFDLFNBQW9CLEVBQUUsUUFBcUM7UUFDM0UsSUFBSSxDQUFDLHFCQUFxQixDQUFDLG1CQUFtQixFQUFFLDZCQUE2QixDQUFDLENBQUM7UUFDL0UsSUFBSSxDQUFDLFFBQVEsQ0FBQyxpQkFBaUIsQ0FBQyxTQUFTLEVBQUUsUUFBUSxDQUFDLENBQUM7UUFDckQsT0FBTyxJQUFJLENBQUM7SUFDZCxDQUFDO0lBRUQsWUFBWSxDQUFDLElBQWUsRUFBRSxRQUFnQztRQUM1RCxJQUFJLENBQUMscUJBQXFCLENBQUMsY0FBYyxFQUFFLHdCQUF3QixDQUFDLENBQUM7UUFDckUsSUFBSSxDQUFDLFFBQVEsQ0FBQyxZQUFZLENBQUMsSUFBSSxFQUFFLFFBQVEsQ0FBQyxDQUFDO1FBQzNDLE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVEOztPQUVHO0lBQ0gsZ0JBQWdCLENBQUMsS0FBVSxFQUFFLFFBQStEO1FBRTFGLElBQUksQ0FBQyxxQkFBcUIsQ0FBQyxrQkFBa0IsRUFBRSxtQkFBbUIsQ0FBQyxDQUFDO1FBQ3BFLElBQUksQ0FBQyxRQUFRLENBQUMsZ0JBQWdCLENBQUMsS0FBSyxFQUFFLFFBQVEsQ0FBQyxDQUFDO1FBQ2hELE9BQU8sSUFBSSxDQUFDO0lBQ2QsQ0FBQztJQUVELGdCQUFnQixDQUFDLFNBQW9CLEVBQUUsUUFBZ0I7UUFDckQsT0FBTyxJQUFJLENBQUMsaUJBQWlCLENBQUMsU0FBUyxFQUFFLEVBQUMsR0FBRyxFQUFFLEVBQUMsUUFBUSxFQUFFLFdBQVcsRUFBRSxJQUFLLEVBQUMsRUFBQyxDQUFDLENBQUM7SUFDbEYsQ0FBQztJQUVELGVBQWUsQ0FBSSxJQUFhO1FBQzlCLE1BQU0scUJBQXFCLEdBQUcsSUFBSSxDQUFDLE1BQU0sQ0FBQyxxQkFBcUIsQ0FBQyxDQUFDO1FBQ2pFLE1BQU0sUUFBUSxHQUFHLE9BQU8sa0JBQWtCLEVBQUUsRUFBRSxDQUFDO1FBQy9DLHFCQUFxQixDQUFDLGlCQUFpQixDQUFDLFFBQVEsQ0FBQyxDQUFDO1FBRWxELE1BQU0sWUFBWSxHQUFJLElBQVksQ0FBQyxJQUFJLENBQUM7UUFFeEMsSUFBSSxDQUFDLFlBQVksRUFBRTtZQUNqQixNQUFNLElBQUksS0FBSyxDQUFDLGtCQUFrQixTQUFTLENBQUMsSUFBSSxDQUFDLDBCQUEwQixDQUFDLENBQUM7U0FDOUU7UUFFRCxNQUFNLFFBQVEsR0FBRyxJQUFJLENBQUMsTUFBTSxDQUFDLHdCQUF3QixFQUFFLEtBQUssQ0FBQyxDQUFDO1FBQzlELE1BQU0sVUFBVSxHQUFZLElBQUksQ0FBQyxNQUFNLENBQUMsMEJBQTBCLEVBQUUsS0FBSyxDQUFDLENBQUM7UUFDM0UsTUFBTSxNQUFNLEdBQWdCLFFBQVEsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLE1BQU0sRUFBRSxJQUFJLENBQUMsQ0FBQztRQUN4RSxNQUFNLGdCQUFnQixHQUFHLElBQUksZ0JBQWdCLENBQUMsWUFBWSxDQUFDLENBQUM7UUFDNUQsTUFBTSxhQUFhLEdBQUcsR0FBRyxFQUFFO1lBQ3pCLE1BQU0sWUFBWSxHQUNkLGdCQUFnQixDQUFDLE1BQU0sQ0FBQyxRQUFRLENBQUMsSUFBSSxFQUFFLEVBQUUsRUFBRSxJQUFJLFFBQVEsRUFBRSxFQUFFLElBQUksQ0FBQyxhQUFhLENBQUMsQ0FBQztZQUNuRixPQUFPLElBQUksZ0JBQWdCLENBQU0sWUFBWSxFQUFFLE1BQU0sRUFBRSxVQUFVLENBQUMsQ0FBQztRQUNyRSxDQUFDLENBQUM7UUFDRixNQUFNLE9BQU8sR0FBRyxNQUFNLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxHQUFHLENBQUMsYUFBYSxDQUFDLENBQUMsQ0FBQyxDQUFDLGFBQWEsRUFBRSxDQUFDO1FBQ3JFLElBQUksQ0FBQyxlQUFlLENBQUMsSUFBSSxDQUFDLE9BQU8sQ0FBQyxDQUFDO1FBQ25DLE9BQU8sT0FBTyxDQUFDO0lBQ2pCLENBQUM7SUFFRDs7O09BR0c7SUFDSCxJQUFZLFFBQVE7UUFDbEIsSUFBSSxJQUFJLENBQUMsU0FBUyxLQUFLLElBQUksRUFBRTtZQUMzQixNQUFNLElBQUksS0FBSyxDQUFDLGtEQUFrRCxDQUFDLENBQUM7U0FDckU7UUFDRCxPQUFPLElBQUksQ0FBQyxTQUFTLENBQUM7SUFDeEIsQ0FBQztJQUVEOzs7T0FHRztJQUNILElBQVksYUFBYTtRQUN2QixJQUFJLElBQUksQ0FBQyxjQUFjLEtBQUssSUFBSSxFQUFFO1lBQ2hDLElBQUksQ0FBQyxjQUFjLEdBQUcsSUFBSSxDQUFDLFFBQVEsQ0FBQyxRQUFRLEVBQUUsQ0FBQztTQUNoRDtRQUNELE9BQU8sSUFBSSxDQUFDLGNBQWMsQ0FBQztJQUM3QixDQUFDO0lBRU8scUJBQXFCLENBQUMsVUFBa0IsRUFBRSxpQkFBeUI7UUFDekUsSUFBSSxJQUFJLENBQUMsY0FBYyxLQUFLLElBQUksRUFBRTtZQUNoQyxNQUFNLElBQUksS0FBSyxDQUNYLFVBQVUsaUJBQWlCLHVEQUF1RDtnQkFDbEYsbURBQW1ELFVBQVUsS0FBSyxDQUFDLENBQUM7U0FDekU7SUFDSCxDQUFDO0lBRUQ7Ozs7Ozs7Ozs7O09BV0c7SUFDSyw4QkFBOEI7UUFDcEMsNkZBQTZGO1FBQzdGLGdHQUFnRztRQUNoRyxJQUFJLENBQUMsSUFBSSxDQUFDLHdCQUF3QixJQUFJLElBQUksQ0FBQyxjQUFjLEtBQUssSUFBSSxFQUFFO1lBQ2xFLHVDQUF1QyxFQUFFLENBQUM7U0FDM0M7UUFDRCxJQUFJLENBQUMsd0JBQXdCLEdBQUcsSUFBSSxDQUFDO0lBQ3ZDLENBQUM7SUFFTyxxQkFBcUI7UUFDM0IsSUFBSSxVQUFVLEdBQUcsQ0FBQyxDQUFDO1FBQ25CLElBQUksQ0FBQyxlQUFlLENBQUMsT0FBTyxDQUFDLENBQUMsT0FBTyxFQUFFLEVBQUU7WUFDdkMsSUFBSTtnQkFDRixPQUFPLENBQUMsT0FBTyxFQUFFLENBQUM7YUFDbkI7WUFBQyxPQUFPLENBQUMsRUFBRTtnQkFDVixVQUFVLEVBQUUsQ0FBQztnQkFDYixPQUFPLENBQUMsS0FBSyxDQUFDLG1DQUFtQyxFQUFFO29CQUNqRCxTQUFTLEVBQUUsT0FBTyxDQUFDLGlCQUFpQjtvQkFDcEMsVUFBVSxFQUFFLENBQUM7aUJBQ2QsQ0FBQyxDQUFDO2FBQ0o7UUFDSCxDQUFDLENBQUMsQ0FBQztRQUNILElBQUksQ0FBQyxlQUFlLEdBQUcsRUFBRSxDQUFDO1FBRTFCLElBQUksVUFBVSxHQUFHLENBQUMsSUFBSSxJQUFJLENBQUMsMkJBQTJCLEVBQUUsRUFBRTtZQUN4RCxNQUFNLEtBQUssQ0FDUCxHQUFHLFVBQVUsSUFBSSxDQUFDLFVBQVUsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLFdBQVcsQ0FBQyxDQUFDLENBQUMsWUFBWSxDQUFDLEdBQUc7Z0JBQ25FLDZCQUE2QixDQUFDLENBQUM7U0FDcEM7SUFDSCxDQUFDO0lBRUQsMkJBQTJCO1FBQ3pCLE1BQU0sZUFBZSxHQUFHLElBQUksQ0FBQyx3QkFBd0IsQ0FBQztRQUN0RCxNQUFNLGtCQUFrQixHQUFHLFdBQVcsQ0FBQywyQkFBMkIsQ0FBQztRQUVuRSxrRkFBa0Y7UUFDbEYsSUFBSSxDQUFDLGVBQWUsSUFBSSxDQUFDLGtCQUFrQixFQUFFO1lBQzNDLE9BQU8sMENBQTBDLENBQUM7U0FDbkQ7UUFFRCxrRUFBa0U7UUFDbEUsT0FBTyxlQUFlLEVBQUUsYUFBYSxJQUFJLGtCQUFrQixFQUFFLGFBQWE7WUFDdEUsSUFBSSxDQUFDLDJCQUEyQixFQUFFLENBQUM7SUFDekMsQ0FBQztJQUVELGlDQUFpQztRQUMvQix1RkFBdUY7UUFDdkYsT0FBTyxJQUFJLENBQUMscUNBQXFDO1lBQzdDLFdBQVcsQ0FBQyx3Q0FBd0MsSUFBSSxpQ0FBaUMsQ0FBQztJQUNoRyxDQUFDO0lBRUQsbUNBQW1DO1FBQ2pDLHdGQUF3RjtRQUN4RixPQUFPLElBQUksQ0FBQyx1Q0FBdUM7WUFDL0MsV0FBVyxDQUFDLDBDQUEwQztZQUN0RCxtQ0FBbUMsQ0FBQztJQUMxQyxDQUFDO0lBRUQsMkJBQTJCO1FBQ3pCLE9BQU8sSUFBSSxDQUFDLHdCQUF3QixFQUFFLGdCQUFnQjtZQUNsRCxXQUFXLENBQUMsMkJBQTJCLEVBQUUsZ0JBQWdCO1lBQ3pELDBDQUEwQyxDQUFDO0lBQ2pELENBQUM7SUFFRCxxQkFBcUI7UUFDbkIseUZBQXlGO1FBQ3pGLElBQUksSUFBSSxDQUFDLGNBQWMsS0FBSyxJQUFJLEVBQUU7WUFDaEMsT0FBTztTQUNSO1FBQ0QsOEZBQThGO1FBQzlGLHlGQUF5RjtRQUN6RixNQUFNLFlBQVksR0FBRyxJQUFJLENBQUMsTUFBTSxDQUFDLHFCQUFxQixDQUFDLENBQUM7UUFDeEQsSUFBSTtZQUNGLElBQUksQ0FBQyxjQUFjLENBQUMsT0FBTyxFQUFFLENBQUM7U0FDL0I7UUFBQyxPQUFPLENBQUMsRUFBRTtZQUNWLElBQUksSUFBSSxDQUFDLDJCQUEyQixFQUFFLEVBQUU7Z0JBQ3RDLE1BQU0sQ0FBQyxDQUFDO2FBQ1Q7aUJBQU07Z0JBQ0wsT0FBTyxDQUFDLEtBQUssQ0FBQywwQ0FBMEMsRUFBRTtvQkFDeEQsU0FBUyxFQUFFLElBQUksQ0FBQyxjQUFjLENBQUMsUUFBUTtvQkFDdkMsVUFBVSxFQUFFLENBQUM7aUJBQ2QsQ0FBQyxDQUFDO2FBQ0o7U0FDRjtnQkFBUztZQUNSLFlBQVksQ0FBQyxxQkFBcUIsRUFBRSxFQUFFLENBQUM7U0FDeEM7SUFDSCxDQUFDOztTQXZrQlUsV0FBVztBQTBrQnhCOzs7Ozs7OztHQVFHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sT0FBTyxHQUFrQixXQUFXLENBQUM7QUFFbEQ7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQXFCRztBQUNILE1BQU0sVUFBVSxNQUFNLENBQUMsTUFBYSxFQUFFLEVBQVk7SUFDaEQsTUFBTSxPQUFPLEdBQUcsV0FBVyxDQUFDLFFBQVEsQ0FBQztJQUNyQyx3RUFBd0U7SUFDeEUsT0FBTztRQUNMLE9BQU8sT0FBTyxDQUFDLE9BQU8sQ0FBQyxNQUFNLEVBQUUsRUFBRSxFQUFFLElBQUksQ0FBQyxDQUFDO0lBQzNDLENBQUMsQ0FBQztBQUNKLENBQUM7QUFFRDs7R0FFRztBQUNILE1BQU0sT0FBTyxrQkFBa0I7SUFDN0IsWUFBb0IsVUFBb0M7UUFBcEMsZUFBVSxHQUFWLFVBQVUsQ0FBMEI7SUFBRyxDQUFDO0lBRXBELFVBQVU7UUFDaEIsTUFBTSxTQUFTLEdBQUcsSUFBSSxDQUFDLFVBQVUsRUFBRSxDQUFDO1FBQ3BDLElBQUksU0FBUyxFQUFFO1lBQ2IsV0FBVyxDQUFDLHNCQUFzQixDQUFDLFNBQVMsQ0FBQyxDQUFDO1NBQy9DO0lBQ0gsQ0FBQztJQUVELE1BQU0sQ0FBQyxNQUFhLEVBQUUsRUFBWTtRQUNoQyxNQUFNLElBQUksR0FBRyxJQUFJLENBQUM7UUFDbEIsd0VBQXdFO1FBQ3hFLE9BQU87WUFDTCxJQUFJLENBQUMsVUFBVSxFQUFFLENBQUM7WUFDbEIsT0FBTyxNQUFNLENBQUMsTUFBTSxFQUFFLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBQztRQUN2QyxDQUFDLENBQUM7SUFDSixDQUFDO0NBQ0Y7QUFPRCxNQUFNLFVBQVUsVUFBVSxDQUFDLFNBQTZCLEVBQUUsRUFBa0I7SUFFMUUsSUFBSSxFQUFFLEVBQUU7UUFDTix3RUFBd0U7UUFDeEUsT0FBTztZQUNMLE1BQU0sT0FBTyxHQUFHLFdBQVcsQ0FBQyxRQUFRLENBQUM7WUFDckMsSUFBSSxTQUFTLEVBQUU7Z0JBQ2IsT0FBTyxDQUFDLHNCQUFzQixDQUFDLFNBQVMsQ0FBQyxDQUFDO2FBQzNDO1lBQ0QsT0FBTyxFQUFFLENBQUMsS0FBSyxDQUFDLElBQUksQ0FBQyxDQUFDO1FBQ3hCLENBQUMsQ0FBQztLQUNIO0lBQ0QsT0FBTyxJQUFJLGtCQUFrQixDQUFDLEdBQUcsRUFBRSxDQUFDLFNBQVMsQ0FBQyxDQUFDO0FBQ2pELENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuLy8gVGhlIGZvcm1hdHRlciBhbmQgQ0kgZGlzYWdyZWUgb24gaG93IHRoaXMgaW1wb3J0IHN0YXRlbWVudCBzaG91bGQgYmUgZm9ybWF0dGVkLiBCb3RoIHRyeSB0byBrZWVwXG4vLyBpdCBvbiBvbmUgbGluZSwgdG9vLCB3aGljaCBoYXMgZ290dGVuIHZlcnkgaGFyZCB0byByZWFkICYgbWFuYWdlLiBTbyBkaXNhYmxlIHRoZSBmb3JtYXR0ZXIgZm9yXG4vLyB0aGlzIHN0YXRlbWVudCBvbmx5LlxuXG4vKiBjbGFuZy1mb3JtYXQgb2ZmICovXG5pbXBvcnQge1xuICBDb21wb25lbnQsXG4gIERpcmVjdGl2ZSxcbiAgRW52aXJvbm1lbnRJbmplY3RvcixcbiAgSW5qZWN0RmxhZ3MsXG4gIEluamVjdGlvblRva2VuLFxuICBJbmplY3RPcHRpb25zLFxuICBJbmplY3RvcixcbiAgTmdNb2R1bGUsXG4gIE5nWm9uZSxcbiAgUGlwZSxcbiAgUGxhdGZvcm1SZWYsXG4gIFByb3ZpZGVyVG9rZW4sXG4gIFR5cGUsXG4gIMm1Y29udmVydFRvQml0RmxhZ3MgYXMgY29udmVydFRvQml0RmxhZ3MsXG4gIMm1Zmx1c2hNb2R1bGVTY29waW5nUXVldWVBc011Y2hBc1Bvc3NpYmxlIGFzIGZsdXNoTW9kdWxlU2NvcGluZ1F1ZXVlQXNNdWNoQXNQb3NzaWJsZSxcbiAgybVnZXRVbmtub3duRWxlbWVudFN0cmljdE1vZGUgYXMgZ2V0VW5rbm93bkVsZW1lbnRTdHJpY3RNb2RlLFxuICDJtWdldFVua25vd25Qcm9wZXJ0eVN0cmljdE1vZGUgYXMgZ2V0VW5rbm93blByb3BlcnR5U3RyaWN0TW9kZSxcbiAgybVSZW5kZXIzQ29tcG9uZW50RmFjdG9yeSBhcyBDb21wb25lbnRGYWN0b3J5LFxuICDJtVJlbmRlcjNOZ01vZHVsZVJlZiBhcyBOZ01vZHVsZVJlZixcbiAgybVyZXNldENvbXBpbGVkQ29tcG9uZW50cyBhcyByZXNldENvbXBpbGVkQ29tcG9uZW50cyxcbiAgybVzZXRBbGxvd0R1cGxpY2F0ZU5nTW9kdWxlSWRzRm9yVGVzdCBhcyBzZXRBbGxvd0R1cGxpY2F0ZU5nTW9kdWxlSWRzRm9yVGVzdCxcbiAgybVzZXRVbmtub3duRWxlbWVudFN0cmljdE1vZGUgYXMgc2V0VW5rbm93bkVsZW1lbnRTdHJpY3RNb2RlLFxuICDJtXNldFVua25vd25Qcm9wZXJ0eVN0cmljdE1vZGUgYXMgc2V0VW5rbm93blByb3BlcnR5U3RyaWN0TW9kZSxcbiAgybVzdHJpbmdpZnkgYXMgc3RyaW5naWZ5XG59IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuXG4vKiBjbGFuZy1mb3JtYXQgb24gKi9cblxuaW1wb3J0IHtDb21wb25lbnRGaXh0dXJlfSBmcm9tICcuL2NvbXBvbmVudF9maXh0dXJlJztcbmltcG9ydCB7TWV0YWRhdGFPdmVycmlkZX0gZnJvbSAnLi9tZXRhZGF0YV9vdmVycmlkZSc7XG5pbXBvcnQge0NvbXBvbmVudEZpeHR1cmVBdXRvRGV0ZWN0LCBDb21wb25lbnRGaXh0dXJlTm9OZ1pvbmUsIE1vZHVsZVRlYXJkb3duT3B0aW9ucywgVEVBUkRPV05fVEVTVElOR19NT0RVTEVfT05fREVTVFJPWV9ERUZBVUxULCBUZXN0Q29tcG9uZW50UmVuZGVyZXIsIFRlc3RFbnZpcm9ubWVudE9wdGlvbnMsIFRlc3RNb2R1bGVNZXRhZGF0YSwgVEhST1dfT05fVU5LTk9XTl9FTEVNRU5UU19ERUZBVUxULCBUSFJPV19PTl9VTktOT1dOX1BST1BFUlRJRVNfREVGQVVMVH0gZnJvbSAnLi90ZXN0X2JlZF9jb21tb24nO1xuaW1wb3J0IHtUZXN0QmVkQ29tcGlsZXJ9IGZyb20gJy4vdGVzdF9iZWRfY29tcGlsZXInO1xuXG4vKipcbiAqIFN0YXRpYyBtZXRob2RzIGltcGxlbWVudGVkIGJ5IHRoZSBgVGVzdEJlZGAuXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgaW50ZXJmYWNlIFRlc3RCZWRTdGF0aWMgZXh0ZW5kcyBUZXN0QmVkIHtcbiAgbmV3KC4uLmFyZ3M6IGFueVtdKTogVGVzdEJlZDtcbn1cblxuLyoqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgVGVzdEJlZCB7XG4gIGdldCBwbGF0Zm9ybSgpOiBQbGF0Zm9ybVJlZjtcblxuICBnZXQgbmdNb2R1bGUoKTogVHlwZTxhbnk+fFR5cGU8YW55PltdO1xuXG4gIC8qKlxuICAgKiBJbml0aWFsaXplIHRoZSBlbnZpcm9ubWVudCBmb3IgdGVzdGluZyB3aXRoIGEgY29tcGlsZXIgZmFjdG9yeSwgYSBQbGF0Zm9ybVJlZiwgYW5kIGFuXG4gICAqIGFuZ3VsYXIgbW9kdWxlLiBUaGVzZSBhcmUgY29tbW9uIHRvIGV2ZXJ5IHRlc3QgaW4gdGhlIHN1aXRlLlxuICAgKlxuICAgKiBUaGlzIG1heSBvbmx5IGJlIGNhbGxlZCBvbmNlLCB0byBzZXQgdXAgdGhlIGNvbW1vbiBwcm92aWRlcnMgZm9yIHRoZSBjdXJyZW50IHRlc3RcbiAgICogc3VpdGUgb24gdGhlIGN1cnJlbnQgcGxhdGZvcm0uIElmIHlvdSBhYnNvbHV0ZWx5IG5lZWQgdG8gY2hhbmdlIHRoZSBwcm92aWRlcnMsXG4gICAqIGZpcnN0IHVzZSBgcmVzZXRUZXN0RW52aXJvbm1lbnRgLlxuICAgKlxuICAgKiBUZXN0IG1vZHVsZXMgYW5kIHBsYXRmb3JtcyBmb3IgaW5kaXZpZHVhbCBwbGF0Zm9ybXMgYXJlIGF2YWlsYWJsZSBmcm9tXG4gICAqICdAYW5ndWxhci88cGxhdGZvcm1fbmFtZT4vdGVzdGluZycuXG4gICAqL1xuICBpbml0VGVzdEVudmlyb25tZW50KFxuICAgICAgbmdNb2R1bGU6IFR5cGU8YW55PnxUeXBlPGFueT5bXSwgcGxhdGZvcm06IFBsYXRmb3JtUmVmLFxuICAgICAgb3B0aW9ucz86IFRlc3RFbnZpcm9ubWVudE9wdGlvbnMpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBSZXNldCB0aGUgcHJvdmlkZXJzIGZvciB0aGUgdGVzdCBpbmplY3Rvci5cbiAgICovXG4gIHJlc2V0VGVzdEVudmlyb25tZW50KCk6IHZvaWQ7XG5cbiAgcmVzZXRUZXN0aW5nTW9kdWxlKCk6IFRlc3RCZWQ7XG5cbiAgY29uZmlndXJlQ29tcGlsZXIoY29uZmlnOiB7cHJvdmlkZXJzPzogYW55W10sIHVzZUppdD86IGJvb2xlYW59KTogdm9pZDtcblxuICBjb25maWd1cmVUZXN0aW5nTW9kdWxlKG1vZHVsZURlZjogVGVzdE1vZHVsZU1ldGFkYXRhKTogVGVzdEJlZDtcblxuICBjb21waWxlQ29tcG9uZW50cygpOiBQcm9taXNlPGFueT47XG5cbiAgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlOiB1bmRlZmluZWQsIG9wdGlvbnM6IEluamVjdE9wdGlvbnMme1xuICAgIG9wdGlvbmFsPzogZmFsc2VcbiAgfSk6IFQ7XG4gIGluamVjdDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZTogbnVsbHx1bmRlZmluZWQsIG9wdGlvbnM6IEluamVjdE9wdGlvbnMpOiBUfG51bGw7XG4gIGluamVjdDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZT86IFQsIG9wdGlvbnM/OiBJbmplY3RPcHRpb25zKTogVDtcbiAgLyoqIEBkZXByZWNhdGVkIHVzZSBvYmplY3QtYmFzZWQgZmxhZ3MgKGBJbmplY3RPcHRpb25zYCkgaW5zdGVhZC4gKi9cbiAgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgZmxhZ3M/OiBJbmplY3RGbGFncyk6IFQ7XG4gIC8qKiBAZGVwcmVjYXRlZCB1c2Ugb2JqZWN0LWJhc2VkIGZsYWdzIChgSW5qZWN0T3B0aW9uc2ApIGluc3RlYWQuICovXG4gIGluamVjdDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZTogbnVsbCwgZmxhZ3M/OiBJbmplY3RGbGFncyk6IFR8bnVsbDtcblxuICAvKiogQGRlcHJlY2F0ZWQgZnJvbSB2OS4wLjAgdXNlIFRlc3RCZWQuaW5qZWN0ICovXG4gIGdldDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZT86IFQsIGZsYWdzPzogSW5qZWN0RmxhZ3MpOiBhbnk7XG4gIC8qKiBAZGVwcmVjYXRlZCBmcm9tIHY5LjAuMCB1c2UgVGVzdEJlZC5pbmplY3QgKi9cbiAgZ2V0KHRva2VuOiBhbnksIG5vdEZvdW5kVmFsdWU/OiBhbnkpOiBhbnk7XG5cbiAgLyoqXG4gICAqIFJ1bnMgdGhlIGdpdmVuIGZ1bmN0aW9uIGluIHRoZSBgRW52aXJvbm1lbnRJbmplY3RvcmAgY29udGV4dCBvZiBgVGVzdEJlZGAuXG4gICAqXG4gICAqIEBzZWUgRW52aXJvbm1lbnRJbmplY3RvciNydW5JbkNvbnRleHRcbiAgICovXG4gIHJ1bkluSW5qZWN0aW9uQ29udGV4dDxUPihmbjogKCkgPT4gVCk6IFQ7XG5cbiAgZXhlY3V0ZSh0b2tlbnM6IGFueVtdLCBmbjogRnVuY3Rpb24sIGNvbnRleHQ/OiBhbnkpOiBhbnk7XG5cbiAgb3ZlcnJpZGVNb2R1bGUobmdNb2R1bGU6IFR5cGU8YW55Piwgb3ZlcnJpZGU6IE1ldGFkYXRhT3ZlcnJpZGU8TmdNb2R1bGU+KTogVGVzdEJlZDtcblxuICBvdmVycmlkZUNvbXBvbmVudChjb21wb25lbnQ6IFR5cGU8YW55Piwgb3ZlcnJpZGU6IE1ldGFkYXRhT3ZlcnJpZGU8Q29tcG9uZW50Pik6IFRlc3RCZWQ7XG5cbiAgb3ZlcnJpZGVEaXJlY3RpdmUoZGlyZWN0aXZlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPERpcmVjdGl2ZT4pOiBUZXN0QmVkO1xuXG4gIG92ZXJyaWRlUGlwZShwaXBlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPFBpcGU+KTogVGVzdEJlZDtcblxuICBvdmVycmlkZVRlbXBsYXRlKGNvbXBvbmVudDogVHlwZTxhbnk+LCB0ZW1wbGF0ZTogc3RyaW5nKTogVGVzdEJlZDtcblxuICAvKipcbiAgICogT3ZlcndyaXRlcyBhbGwgcHJvdmlkZXJzIGZvciB0aGUgZ2l2ZW4gdG9rZW4gd2l0aCB0aGUgZ2l2ZW4gcHJvdmlkZXIgZGVmaW5pdGlvbi5cbiAgICovXG4gIG92ZXJyaWRlUHJvdmlkZXIodG9rZW46IGFueSwgcHJvdmlkZXI6IHt1c2VGYWN0b3J5OiBGdW5jdGlvbiwgZGVwczogYW55W10sIG11bHRpPzogYm9vbGVhbn0pOlxuICAgICAgVGVzdEJlZDtcbiAgb3ZlcnJpZGVQcm92aWRlcih0b2tlbjogYW55LCBwcm92aWRlcjoge3VzZVZhbHVlOiBhbnksIG11bHRpPzogYm9vbGVhbn0pOiBUZXN0QmVkO1xuICBvdmVycmlkZVByb3ZpZGVyKFxuICAgICAgdG9rZW46IGFueSxcbiAgICAgIHByb3ZpZGVyOiB7dXNlRmFjdG9yeT86IEZ1bmN0aW9uLCB1c2VWYWx1ZT86IGFueSwgZGVwcz86IGFueVtdLCBtdWx0aT86IGJvb2xlYW59KTogVGVzdEJlZDtcblxuICBvdmVycmlkZVRlbXBsYXRlVXNpbmdUZXN0aW5nTW9kdWxlKGNvbXBvbmVudDogVHlwZTxhbnk+LCB0ZW1wbGF0ZTogc3RyaW5nKTogVGVzdEJlZDtcblxuICBjcmVhdGVDb21wb25lbnQ8VD4oY29tcG9uZW50OiBUeXBlPFQ+KTogQ29tcG9uZW50Rml4dHVyZTxUPjtcbn1cblxubGV0IF9uZXh0Um9vdEVsZW1lbnRJZCA9IDA7XG5cbi8qKlxuICogUmV0dXJucyBhIHNpbmdsZXRvbiBvZiB0aGUgYFRlc3RCZWRgIGNsYXNzLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIGdldFRlc3RCZWQoKTogVGVzdEJlZCB7XG4gIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRTtcbn1cblxuLyoqXG4gKiBAZGVzY3JpcHRpb25cbiAqIENvbmZpZ3VyZXMgYW5kIGluaXRpYWxpemVzIGVudmlyb25tZW50IGZvciB1bml0IHRlc3RpbmcgYW5kIHByb3ZpZGVzIG1ldGhvZHMgZm9yXG4gKiBjcmVhdGluZyBjb21wb25lbnRzIGFuZCBzZXJ2aWNlcyBpbiB1bml0IHRlc3RzLlxuICpcbiAqIFRlc3RCZWQgaXMgdGhlIHByaW1hcnkgYXBpIGZvciB3cml0aW5nIHVuaXQgdGVzdHMgZm9yIEFuZ3VsYXIgYXBwbGljYXRpb25zIGFuZCBsaWJyYXJpZXMuXG4gKi9cbmV4cG9ydCBjbGFzcyBUZXN0QmVkSW1wbCBpbXBsZW1lbnRzIFRlc3RCZWQge1xuICBwcml2YXRlIHN0YXRpYyBfSU5TVEFOQ0U6IFRlc3RCZWRJbXBsfG51bGwgPSBudWxsO1xuXG4gIHN0YXRpYyBnZXQgSU5TVEFOQ0UoKTogVGVzdEJlZEltcGwge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5fSU5TVEFOQ0UgPSBUZXN0QmVkSW1wbC5fSU5TVEFOQ0UgfHwgbmV3IFRlc3RCZWRJbXBsKCk7XG4gIH1cblxuICAvKipcbiAgICogVGVhcmRvd24gb3B0aW9ucyB0aGF0IGhhdmUgYmVlbiBjb25maWd1cmVkIGF0IHRoZSBlbnZpcm9ubWVudCBsZXZlbC5cbiAgICogVXNlZCBhcyBhIGZhbGxiYWNrIGlmIG5vIGluc3RhbmNlLWxldmVsIG9wdGlvbnMgaGF2ZSBiZWVuIHByb3ZpZGVkLlxuICAgKi9cbiAgcHJpdmF0ZSBzdGF0aWMgX2Vudmlyb25tZW50VGVhcmRvd25PcHRpb25zOiBNb2R1bGVUZWFyZG93bk9wdGlvbnN8dW5kZWZpbmVkO1xuXG4gIC8qKlxuICAgKiBcIkVycm9yIG9uIHVua25vd24gZWxlbWVudHNcIiBvcHRpb24gdGhhdCBoYXMgYmVlbiBjb25maWd1cmVkIGF0IHRoZSBlbnZpcm9ubWVudCBsZXZlbC5cbiAgICogVXNlZCBhcyBhIGZhbGxiYWNrIGlmIG5vIGluc3RhbmNlLWxldmVsIG9wdGlvbiBoYXMgYmVlbiBwcm92aWRlZC5cbiAgICovXG4gIHByaXZhdGUgc3RhdGljIF9lbnZpcm9ubWVudEVycm9yT25Vbmtub3duRWxlbWVudHNPcHRpb246IGJvb2xlYW58dW5kZWZpbmVkO1xuXG4gIC8qKlxuICAgKiBcIkVycm9yIG9uIHVua25vd24gcHJvcGVydGllc1wiIG9wdGlvbiB0aGF0IGhhcyBiZWVuIGNvbmZpZ3VyZWQgYXQgdGhlIGVudmlyb25tZW50IGxldmVsLlxuICAgKiBVc2VkIGFzIGEgZmFsbGJhY2sgaWYgbm8gaW5zdGFuY2UtbGV2ZWwgb3B0aW9uIGhhcyBiZWVuIHByb3ZpZGVkLlxuICAgKi9cbiAgcHJpdmF0ZSBzdGF0aWMgX2Vudmlyb25tZW50RXJyb3JPblVua25vd25Qcm9wZXJ0aWVzT3B0aW9uOiBib29sZWFufHVuZGVmaW5lZDtcblxuICAvKipcbiAgICogVGVhcmRvd24gb3B0aW9ucyB0aGF0IGhhdmUgYmVlbiBjb25maWd1cmVkIGF0IHRoZSBgVGVzdEJlZGAgaW5zdGFuY2UgbGV2ZWwuXG4gICAqIFRoZXNlIG9wdGlvbnMgdGFrZSBwcmVjZWRlbmNlIG92ZXIgdGhlIGVudmlyb25tZW50LWxldmVsIG9uZXMuXG4gICAqL1xuICBwcml2YXRlIF9pbnN0YW5jZVRlYXJkb3duT3B0aW9uczogTW9kdWxlVGVhcmRvd25PcHRpb25zfHVuZGVmaW5lZDtcblxuICAvKipcbiAgICogXCJFcnJvciBvbiB1bmtub3duIGVsZW1lbnRzXCIgb3B0aW9uIHRoYXQgaGFzIGJlZW4gY29uZmlndXJlZCBhdCB0aGUgYFRlc3RCZWRgIGluc3RhbmNlIGxldmVsLlxuICAgKiBUaGlzIG9wdGlvbiB0YWtlcyBwcmVjZWRlbmNlIG92ZXIgdGhlIGVudmlyb25tZW50LWxldmVsIG9uZS5cbiAgICovXG4gIHByaXZhdGUgX2luc3RhbmNlRXJyb3JPblVua25vd25FbGVtZW50c09wdGlvbjogYm9vbGVhbnx1bmRlZmluZWQ7XG5cbiAgLyoqXG4gICAqIFwiRXJyb3Igb24gdW5rbm93biBwcm9wZXJ0aWVzXCIgb3B0aW9uIHRoYXQgaGFzIGJlZW4gY29uZmlndXJlZCBhdCB0aGUgYFRlc3RCZWRgIGluc3RhbmNlIGxldmVsLlxuICAgKiBUaGlzIG9wdGlvbiB0YWtlcyBwcmVjZWRlbmNlIG92ZXIgdGhlIGVudmlyb25tZW50LWxldmVsIG9uZS5cbiAgICovXG4gIHByaXZhdGUgX2luc3RhbmNlRXJyb3JPblVua25vd25Qcm9wZXJ0aWVzT3B0aW9uOiBib29sZWFufHVuZGVmaW5lZDtcblxuICAvKipcbiAgICogU3RvcmVzIHRoZSBwcmV2aW91cyBcIkVycm9yIG9uIHVua25vd24gZWxlbWVudHNcIiBvcHRpb24gdmFsdWUsXG4gICAqIGFsbG93aW5nIHRvIHJlc3RvcmUgaXQgaW4gdGhlIHJlc2V0IHRlc3RpbmcgbW9kdWxlIGxvZ2ljLlxuICAgKi9cbiAgcHJpdmF0ZSBfcHJldmlvdXNFcnJvck9uVW5rbm93bkVsZW1lbnRzT3B0aW9uOiBib29sZWFufHVuZGVmaW5lZDtcblxuICAvKipcbiAgICogU3RvcmVzIHRoZSBwcmV2aW91cyBcIkVycm9yIG9uIHVua25vd24gcHJvcGVydGllc1wiIG9wdGlvbiB2YWx1ZSxcbiAgICogYWxsb3dpbmcgdG8gcmVzdG9yZSBpdCBpbiB0aGUgcmVzZXQgdGVzdGluZyBtb2R1bGUgbG9naWMuXG4gICAqL1xuICBwcml2YXRlIF9wcmV2aW91c0Vycm9yT25Vbmtub3duUHJvcGVydGllc09wdGlvbjogYm9vbGVhbnx1bmRlZmluZWQ7XG5cbiAgLyoqXG4gICAqIEluaXRpYWxpemUgdGhlIGVudmlyb25tZW50IGZvciB0ZXN0aW5nIHdpdGggYSBjb21waWxlciBmYWN0b3J5LCBhIFBsYXRmb3JtUmVmLCBhbmQgYW5cbiAgICogYW5ndWxhciBtb2R1bGUuIFRoZXNlIGFyZSBjb21tb24gdG8gZXZlcnkgdGVzdCBpbiB0aGUgc3VpdGUuXG4gICAqXG4gICAqIFRoaXMgbWF5IG9ubHkgYmUgY2FsbGVkIG9uY2UsIHRvIHNldCB1cCB0aGUgY29tbW9uIHByb3ZpZGVycyBmb3IgdGhlIGN1cnJlbnQgdGVzdFxuICAgKiBzdWl0ZSBvbiB0aGUgY3VycmVudCBwbGF0Zm9ybS4gSWYgeW91IGFic29sdXRlbHkgbmVlZCB0byBjaGFuZ2UgdGhlIHByb3ZpZGVycyxcbiAgICogZmlyc3QgdXNlIGByZXNldFRlc3RFbnZpcm9ubWVudGAuXG4gICAqXG4gICAqIFRlc3QgbW9kdWxlcyBhbmQgcGxhdGZvcm1zIGZvciBpbmRpdmlkdWFsIHBsYXRmb3JtcyBhcmUgYXZhaWxhYmxlIGZyb21cbiAgICogJ0Bhbmd1bGFyLzxwbGF0Zm9ybV9uYW1lPi90ZXN0aW5nJy5cbiAgICpcbiAgICogQHB1YmxpY0FwaVxuICAgKi9cbiAgc3RhdGljIGluaXRUZXN0RW52aXJvbm1lbnQoXG4gICAgICBuZ01vZHVsZTogVHlwZTxhbnk+fFR5cGU8YW55PltdLCBwbGF0Zm9ybTogUGxhdGZvcm1SZWYsXG4gICAgICBvcHRpb25zPzogVGVzdEVudmlyb25tZW50T3B0aW9ucyk6IFRlc3RCZWQge1xuICAgIGNvbnN0IHRlc3RCZWQgPSBUZXN0QmVkSW1wbC5JTlNUQU5DRTtcbiAgICB0ZXN0QmVkLmluaXRUZXN0RW52aXJvbm1lbnQobmdNb2R1bGUsIHBsYXRmb3JtLCBvcHRpb25zKTtcbiAgICByZXR1cm4gdGVzdEJlZDtcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXNldCB0aGUgcHJvdmlkZXJzIGZvciB0aGUgdGVzdCBpbmplY3Rvci5cbiAgICpcbiAgICogQHB1YmxpY0FwaVxuICAgKi9cbiAgc3RhdGljIHJlc2V0VGVzdEVudmlyb25tZW50KCk6IHZvaWQge1xuICAgIFRlc3RCZWRJbXBsLklOU1RBTkNFLnJlc2V0VGVzdEVudmlyb25tZW50KCk7XG4gIH1cblxuICBzdGF0aWMgY29uZmlndXJlQ29tcGlsZXIoY29uZmlnOiB7cHJvdmlkZXJzPzogYW55W107IHVzZUppdD86IGJvb2xlYW47fSk6IFRlc3RCZWQge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5jb25maWd1cmVDb21waWxlcihjb25maWcpO1xuICB9XG5cbiAgLyoqXG4gICAqIEFsbG93cyBvdmVycmlkaW5nIGRlZmF1bHQgcHJvdmlkZXJzLCBkaXJlY3RpdmVzLCBwaXBlcywgbW9kdWxlcyBvZiB0aGUgdGVzdCBpbmplY3RvcixcbiAgICogd2hpY2ggYXJlIGRlZmluZWQgaW4gdGVzdF9pbmplY3Rvci5qc1xuICAgKi9cbiAgc3RhdGljIGNvbmZpZ3VyZVRlc3RpbmdNb2R1bGUobW9kdWxlRGVmOiBUZXN0TW9kdWxlTWV0YWRhdGEpOiBUZXN0QmVkIHtcbiAgICByZXR1cm4gVGVzdEJlZEltcGwuSU5TVEFOQ0UuY29uZmlndXJlVGVzdGluZ01vZHVsZShtb2R1bGVEZWYpO1xuICB9XG5cbiAgLyoqXG4gICAqIENvbXBpbGUgY29tcG9uZW50cyB3aXRoIGEgYHRlbXBsYXRlVXJsYCBmb3IgdGhlIHRlc3QncyBOZ01vZHVsZS5cbiAgICogSXQgaXMgbmVjZXNzYXJ5IHRvIGNhbGwgdGhpcyBmdW5jdGlvblxuICAgKiBhcyBmZXRjaGluZyB1cmxzIGlzIGFzeW5jaHJvbm91cy5cbiAgICovXG4gIHN0YXRpYyBjb21waWxlQ29tcG9uZW50cygpOiBQcm9taXNlPGFueT4ge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5jb21waWxlQ29tcG9uZW50cygpO1xuICB9XG5cbiAgc3RhdGljIG92ZXJyaWRlTW9kdWxlKG5nTW9kdWxlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPE5nTW9kdWxlPik6IFRlc3RCZWQge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5vdmVycmlkZU1vZHVsZShuZ01vZHVsZSwgb3ZlcnJpZGUpO1xuICB9XG5cbiAgc3RhdGljIG92ZXJyaWRlQ29tcG9uZW50KGNvbXBvbmVudDogVHlwZTxhbnk+LCBvdmVycmlkZTogTWV0YWRhdGFPdmVycmlkZTxDb21wb25lbnQ+KTogVGVzdEJlZCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLm92ZXJyaWRlQ29tcG9uZW50KGNvbXBvbmVudCwgb3ZlcnJpZGUpO1xuICB9XG5cbiAgc3RhdGljIG92ZXJyaWRlRGlyZWN0aXZlKGRpcmVjdGl2ZTogVHlwZTxhbnk+LCBvdmVycmlkZTogTWV0YWRhdGFPdmVycmlkZTxEaXJlY3RpdmU+KTogVGVzdEJlZCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLm92ZXJyaWRlRGlyZWN0aXZlKGRpcmVjdGl2ZSwgb3ZlcnJpZGUpO1xuICB9XG5cbiAgc3RhdGljIG92ZXJyaWRlUGlwZShwaXBlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPFBpcGU+KTogVGVzdEJlZCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLm92ZXJyaWRlUGlwZShwaXBlLCBvdmVycmlkZSk7XG4gIH1cblxuICBzdGF0aWMgb3ZlcnJpZGVUZW1wbGF0ZShjb21wb25lbnQ6IFR5cGU8YW55PiwgdGVtcGxhdGU6IHN0cmluZyk6IFRlc3RCZWQge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5vdmVycmlkZVRlbXBsYXRlKGNvbXBvbmVudCwgdGVtcGxhdGUpO1xuICB9XG5cbiAgLyoqXG4gICAqIE92ZXJyaWRlcyB0aGUgdGVtcGxhdGUgb2YgdGhlIGdpdmVuIGNvbXBvbmVudCwgY29tcGlsaW5nIHRoZSB0ZW1wbGF0ZVxuICAgKiBpbiB0aGUgY29udGV4dCBvZiB0aGUgVGVzdGluZ01vZHVsZS5cbiAgICpcbiAgICogTm90ZTogVGhpcyB3b3JrcyBmb3IgSklUIGFuZCBBT1RlZCBjb21wb25lbnRzIGFzIHdlbGwuXG4gICAqL1xuICBzdGF0aWMgb3ZlcnJpZGVUZW1wbGF0ZVVzaW5nVGVzdGluZ01vZHVsZShjb21wb25lbnQ6IFR5cGU8YW55PiwgdGVtcGxhdGU6IHN0cmluZyk6IFRlc3RCZWQge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5vdmVycmlkZVRlbXBsYXRlVXNpbmdUZXN0aW5nTW9kdWxlKGNvbXBvbmVudCwgdGVtcGxhdGUpO1xuICB9XG5cbiAgc3RhdGljIG92ZXJyaWRlUHJvdmlkZXIodG9rZW46IGFueSwgcHJvdmlkZXI6IHtcbiAgICB1c2VGYWN0b3J5OiBGdW5jdGlvbixcbiAgICBkZXBzOiBhbnlbXSxcbiAgfSk6IFRlc3RCZWQ7XG4gIHN0YXRpYyBvdmVycmlkZVByb3ZpZGVyKHRva2VuOiBhbnksIHByb3ZpZGVyOiB7dXNlVmFsdWU6IGFueTt9KTogVGVzdEJlZDtcbiAgc3RhdGljIG92ZXJyaWRlUHJvdmlkZXIodG9rZW46IGFueSwgcHJvdmlkZXI6IHtcbiAgICB1c2VGYWN0b3J5PzogRnVuY3Rpb24sXG4gICAgdXNlVmFsdWU/OiBhbnksXG4gICAgZGVwcz86IGFueVtdLFxuICB9KTogVGVzdEJlZCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLm92ZXJyaWRlUHJvdmlkZXIodG9rZW4sIHByb3ZpZGVyKTtcbiAgfVxuXG4gIHN0YXRpYyBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU6IHVuZGVmaW5lZCwgb3B0aW9uczogSW5qZWN0T3B0aW9ucyZ7XG4gICAgb3B0aW9uYWw/OiBmYWxzZVxuICB9KTogVDtcbiAgc3RhdGljIGluamVjdDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZTogbnVsbHx1bmRlZmluZWQsIG9wdGlvbnM6IEluamVjdE9wdGlvbnMpOlxuICAgICAgVHxudWxsO1xuICBzdGF0aWMgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgb3B0aW9ucz86IEluamVjdE9wdGlvbnMpOiBUO1xuICAvKiogQGRlcHJlY2F0ZWQgdXNlIG9iamVjdC1iYXNlZCBmbGFncyAoYEluamVjdE9wdGlvbnNgKSBpbnN0ZWFkLiAqL1xuICBzdGF0aWMgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgZmxhZ3M/OiBJbmplY3RGbGFncyk6IFQ7XG4gIC8qKiBAZGVwcmVjYXRlZCB1c2Ugb2JqZWN0LWJhc2VkIGZsYWdzIChgSW5qZWN0T3B0aW9uc2ApIGluc3RlYWQuICovXG4gIHN0YXRpYyBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU6IG51bGwsIGZsYWdzPzogSW5qZWN0RmxhZ3MpOiBUfG51bGw7XG4gIHN0YXRpYyBpbmplY3Q8VD4oXG4gICAgICB0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZT86IFR8bnVsbCwgZmxhZ3M/OiBJbmplY3RGbGFnc3xJbmplY3RPcHRpb25zKTogVHxudWxsIHtcbiAgICByZXR1cm4gVGVzdEJlZEltcGwuSU5TVEFOQ0UuaW5qZWN0KHRva2VuLCBub3RGb3VuZFZhbHVlLCBjb252ZXJ0VG9CaXRGbGFncyhmbGFncykpO1xuICB9XG5cbiAgLyoqIEBkZXByZWNhdGVkIGZyb20gdjkuMC4wIHVzZSBUZXN0QmVkLmluamVjdCAqL1xuICBzdGF0aWMgZ2V0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgZmxhZ3M/OiBJbmplY3RGbGFncyk6IGFueTtcbiAgLyoqIEBkZXByZWNhdGVkIGZyb20gdjkuMC4wIHVzZSBUZXN0QmVkLmluamVjdCAqL1xuICBzdGF0aWMgZ2V0KHRva2VuOiBhbnksIG5vdEZvdW5kVmFsdWU/OiBhbnkpOiBhbnk7XG4gIC8qKiBAZGVwcmVjYXRlZCBmcm9tIHY5LjAuMCB1c2UgVGVzdEJlZC5pbmplY3QgKi9cbiAgc3RhdGljIGdldChcbiAgICAgIHRva2VuOiBhbnksIG5vdEZvdW5kVmFsdWU6IGFueSA9IEluamVjdG9yLlRIUk9XX0lGX05PVF9GT1VORCxcbiAgICAgIGZsYWdzOiBJbmplY3RGbGFncyA9IEluamVjdEZsYWdzLkRlZmF1bHQpOiBhbnkge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5pbmplY3QodG9rZW4sIG5vdEZvdW5kVmFsdWUsIGZsYWdzKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBSdW5zIHRoZSBnaXZlbiBmdW5jdGlvbiBpbiB0aGUgYEVudmlyb25tZW50SW5qZWN0b3JgIGNvbnRleHQgb2YgYFRlc3RCZWRgLlxuICAgKlxuICAgKiBAc2VlIEVudmlyb25tZW50SW5qZWN0b3IjcnVuSW5Db250ZXh0XG4gICAqL1xuICBzdGF0aWMgcnVuSW5JbmplY3Rpb25Db250ZXh0PFQ+KGZuOiAoKSA9PiBUKTogVCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLnJ1bkluSW5qZWN0aW9uQ29udGV4dChmbik7XG4gIH1cblxuICBzdGF0aWMgY3JlYXRlQ29tcG9uZW50PFQ+KGNvbXBvbmVudDogVHlwZTxUPik6IENvbXBvbmVudEZpeHR1cmU8VD4ge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5jcmVhdGVDb21wb25lbnQoY29tcG9uZW50KTtcbiAgfVxuXG4gIHN0YXRpYyByZXNldFRlc3RpbmdNb2R1bGUoKTogVGVzdEJlZCB7XG4gICAgcmV0dXJuIFRlc3RCZWRJbXBsLklOU1RBTkNFLnJlc2V0VGVzdGluZ01vZHVsZSgpO1xuICB9XG5cbiAgc3RhdGljIGV4ZWN1dGUodG9rZW5zOiBhbnlbXSwgZm46IEZ1bmN0aW9uLCBjb250ZXh0PzogYW55KTogYW55IHtcbiAgICByZXR1cm4gVGVzdEJlZEltcGwuSU5TVEFOQ0UuZXhlY3V0ZSh0b2tlbnMsIGZuLCBjb250ZXh0KTtcbiAgfVxuXG4gIHN0YXRpYyBnZXQgcGxhdGZvcm0oKTogUGxhdGZvcm1SZWYge1xuICAgIHJldHVybiBUZXN0QmVkSW1wbC5JTlNUQU5DRS5wbGF0Zm9ybTtcbiAgfVxuXG4gIHN0YXRpYyBnZXQgbmdNb2R1bGUoKTogVHlwZTxhbnk+fFR5cGU8YW55PltdIHtcbiAgICByZXR1cm4gVGVzdEJlZEltcGwuSU5TVEFOQ0UubmdNb2R1bGU7XG4gIH1cblxuICAvLyBQcm9wZXJ0aWVzXG5cbiAgcGxhdGZvcm06IFBsYXRmb3JtUmVmID0gbnVsbCE7XG4gIG5nTW9kdWxlOiBUeXBlPGFueT58VHlwZTxhbnk+W10gPSBudWxsITtcblxuICBwcml2YXRlIF9jb21waWxlcjogVGVzdEJlZENvbXBpbGVyfG51bGwgPSBudWxsO1xuICBwcml2YXRlIF90ZXN0TW9kdWxlUmVmOiBOZ01vZHVsZVJlZjxhbnk+fG51bGwgPSBudWxsO1xuXG4gIHByaXZhdGUgX2FjdGl2ZUZpeHR1cmVzOiBDb21wb25lbnRGaXh0dXJlPGFueT5bXSA9IFtdO1xuXG4gIC8qKlxuICAgKiBJbnRlcm5hbC1vbmx5IGZsYWcgdG8gaW5kaWNhdGUgd2hldGhlciBhIG1vZHVsZVxuICAgKiBzY29waW5nIHF1ZXVlIGhhcyBiZWVuIGNoZWNrZWQgYW5kIGZsdXNoZWQgYWxyZWFkeS5cbiAgICogQG5vZG9jXG4gICAqL1xuICBnbG9iYWxDb21waWxhdGlvbkNoZWNrZWQgPSBmYWxzZTtcblxuICAvKipcbiAgICogSW5pdGlhbGl6ZSB0aGUgZW52aXJvbm1lbnQgZm9yIHRlc3Rpbmcgd2l0aCBhIGNvbXBpbGVyIGZhY3RvcnksIGEgUGxhdGZvcm1SZWYsIGFuZCBhblxuICAgKiBhbmd1bGFyIG1vZHVsZS4gVGhlc2UgYXJlIGNvbW1vbiB0byBldmVyeSB0ZXN0IGluIHRoZSBzdWl0ZS5cbiAgICpcbiAgICogVGhpcyBtYXkgb25seSBiZSBjYWxsZWQgb25jZSwgdG8gc2V0IHVwIHRoZSBjb21tb24gcHJvdmlkZXJzIGZvciB0aGUgY3VycmVudCB0ZXN0XG4gICAqIHN1aXRlIG9uIHRoZSBjdXJyZW50IHBsYXRmb3JtLiBJZiB5b3UgYWJzb2x1dGVseSBuZWVkIHRvIGNoYW5nZSB0aGUgcHJvdmlkZXJzLFxuICAgKiBmaXJzdCB1c2UgYHJlc2V0VGVzdEVudmlyb25tZW50YC5cbiAgICpcbiAgICogVGVzdCBtb2R1bGVzIGFuZCBwbGF0Zm9ybXMgZm9yIGluZGl2aWR1YWwgcGxhdGZvcm1zIGFyZSBhdmFpbGFibGUgZnJvbVxuICAgKiAnQGFuZ3VsYXIvPHBsYXRmb3JtX25hbWU+L3Rlc3RpbmcnLlxuICAgKlxuICAgKiBAcHVibGljQXBpXG4gICAqL1xuICBpbml0VGVzdEVudmlyb25tZW50KFxuICAgICAgbmdNb2R1bGU6IFR5cGU8YW55PnxUeXBlPGFueT5bXSwgcGxhdGZvcm06IFBsYXRmb3JtUmVmLFxuICAgICAgb3B0aW9ucz86IFRlc3RFbnZpcm9ubWVudE9wdGlvbnMpOiB2b2lkIHtcbiAgICBpZiAodGhpcy5wbGF0Zm9ybSB8fCB0aGlzLm5nTW9kdWxlKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoJ0Nhbm5vdCBzZXQgYmFzZSBwcm92aWRlcnMgYmVjYXVzZSBpdCBoYXMgYWxyZWFkeSBiZWVuIGNhbGxlZCcpO1xuICAgIH1cblxuICAgIFRlc3RCZWRJbXBsLl9lbnZpcm9ubWVudFRlYXJkb3duT3B0aW9ucyA9IG9wdGlvbnM/LnRlYXJkb3duO1xuXG4gICAgVGVzdEJlZEltcGwuX2Vudmlyb25tZW50RXJyb3JPblVua25vd25FbGVtZW50c09wdGlvbiA9IG9wdGlvbnM/LmVycm9yT25Vbmtub3duRWxlbWVudHM7XG5cbiAgICBUZXN0QmVkSW1wbC5fZW52aXJvbm1lbnRFcnJvck9uVW5rbm93blByb3BlcnRpZXNPcHRpb24gPSBvcHRpb25zPy5lcnJvck9uVW5rbm93blByb3BlcnRpZXM7XG5cbiAgICB0aGlzLnBsYXRmb3JtID0gcGxhdGZvcm07XG4gICAgdGhpcy5uZ01vZHVsZSA9IG5nTW9kdWxlO1xuICAgIHRoaXMuX2NvbXBpbGVyID0gbmV3IFRlc3RCZWRDb21waWxlcih0aGlzLnBsYXRmb3JtLCB0aGlzLm5nTW9kdWxlKTtcblxuICAgIC8vIFRlc3RCZWQgZG9lcyBub3QgaGF2ZSBhbiBBUEkgd2hpY2ggY2FuIHJlbGlhYmx5IGRldGVjdCB0aGUgc3RhcnQgb2YgYSB0ZXN0LCBhbmQgdGh1cyBjb3VsZCBiZVxuICAgIC8vIHVzZWQgdG8gdHJhY2sgdGhlIHN0YXRlIG9mIHRoZSBOZ01vZHVsZSByZWdpc3RyeSBhbmQgcmVzZXQgaXQgY29ycmVjdGx5LiBJbnN0ZWFkLCB3aGVuIHdlXG4gICAgLy8ga25vdyB3ZSdyZSBpbiBhIHRlc3Rpbmcgc2NlbmFyaW8sIHdlIGRpc2FibGUgdGhlIGNoZWNrIGZvciBkdXBsaWNhdGUgTmdNb2R1bGUgcmVnaXN0cmF0aW9uXG4gICAgLy8gY29tcGxldGVseS5cbiAgICBzZXRBbGxvd0R1cGxpY2F0ZU5nTW9kdWxlSWRzRm9yVGVzdCh0cnVlKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXNldCB0aGUgcHJvdmlkZXJzIGZvciB0aGUgdGVzdCBpbmplY3Rvci5cbiAgICpcbiAgICogQHB1YmxpY0FwaVxuICAgKi9cbiAgcmVzZXRUZXN0RW52aXJvbm1lbnQoKTogdm9pZCB7XG4gICAgdGhpcy5yZXNldFRlc3RpbmdNb2R1bGUoKTtcbiAgICB0aGlzLl9jb21waWxlciA9IG51bGw7XG4gICAgdGhpcy5wbGF0Zm9ybSA9IG51bGwhO1xuICAgIHRoaXMubmdNb2R1bGUgPSBudWxsITtcbiAgICBUZXN0QmVkSW1wbC5fZW52aXJvbm1lbnRUZWFyZG93bk9wdGlvbnMgPSB1bmRlZmluZWQ7XG4gICAgc2V0QWxsb3dEdXBsaWNhdGVOZ01vZHVsZUlkc0ZvclRlc3QoZmFsc2UpO1xuICB9XG5cbiAgcmVzZXRUZXN0aW5nTW9kdWxlKCk6IHRoaXMge1xuICAgIHRoaXMuY2hlY2tHbG9iYWxDb21waWxhdGlvbkZpbmlzaGVkKCk7XG4gICAgcmVzZXRDb21waWxlZENvbXBvbmVudHMoKTtcbiAgICBpZiAodGhpcy5fY29tcGlsZXIgIT09IG51bGwpIHtcbiAgICAgIHRoaXMuY29tcGlsZXIucmVzdG9yZU9yaWdpbmFsU3RhdGUoKTtcbiAgICB9XG4gICAgdGhpcy5fY29tcGlsZXIgPSBuZXcgVGVzdEJlZENvbXBpbGVyKHRoaXMucGxhdGZvcm0sIHRoaXMubmdNb2R1bGUpO1xuICAgIC8vIFJlc3RvcmUgdGhlIHByZXZpb3VzIHZhbHVlIG9mIHRoZSBcImVycm9yIG9uIHVua25vd24gZWxlbWVudHNcIiBvcHRpb25cbiAgICBzZXRVbmtub3duRWxlbWVudFN0cmljdE1vZGUoXG4gICAgICAgIHRoaXMuX3ByZXZpb3VzRXJyb3JPblVua25vd25FbGVtZW50c09wdGlvbiA/PyBUSFJPV19PTl9VTktOT1dOX0VMRU1FTlRTX0RFRkFVTFQpO1xuICAgIC8vIFJlc3RvcmUgdGhlIHByZXZpb3VzIHZhbHVlIG9mIHRoZSBcImVycm9yIG9uIHVua25vd24gcHJvcGVydGllc1wiIG9wdGlvblxuICAgIHNldFVua25vd25Qcm9wZXJ0eVN0cmljdE1vZGUoXG4gICAgICAgIHRoaXMuX3ByZXZpb3VzRXJyb3JPblVua25vd25Qcm9wZXJ0aWVzT3B0aW9uID8/IFRIUk9XX09OX1VOS05PV05fUFJPUEVSVElFU19ERUZBVUxUKTtcblxuICAgIC8vIFdlIGhhdmUgdG8gY2hhaW4gYSBjb3VwbGUgb2YgdHJ5L2ZpbmFsbHkgYmxvY2tzLCBiZWNhdXNlIGVhY2ggc3RlcCBjYW5cbiAgICAvLyB0aHJvdyBlcnJvcnMgYW5kIHdlIGRvbid0IHdhbnQgaXQgdG8gaW50ZXJydXB0IHRoZSBuZXh0IHN0ZXAgYW5kIHdlIGFsc29cbiAgICAvLyB3YW50IGFuIGVycm9yIHRvIGJlIHRocm93biBhdCB0aGUgZW5kLlxuICAgIHRyeSB7XG4gICAgICB0aGlzLmRlc3Ryb3lBY3RpdmVGaXh0dXJlcygpO1xuICAgIH0gZmluYWxseSB7XG4gICAgICB0cnkge1xuICAgICAgICBpZiAodGhpcy5zaG91bGRUZWFyRG93blRlc3RpbmdNb2R1bGUoKSkge1xuICAgICAgICAgIHRoaXMudGVhckRvd25UZXN0aW5nTW9kdWxlKCk7XG4gICAgICAgIH1cbiAgICAgIH0gZmluYWxseSB7XG4gICAgICAgIHRoaXMuX3Rlc3RNb2R1bGVSZWYgPSBudWxsO1xuICAgICAgICB0aGlzLl9pbnN0YW5jZVRlYXJkb3duT3B0aW9ucyA9IHVuZGVmaW5lZDtcbiAgICAgICAgdGhpcy5faW5zdGFuY2VFcnJvck9uVW5rbm93bkVsZW1lbnRzT3B0aW9uID0gdW5kZWZpbmVkO1xuICAgICAgICB0aGlzLl9pbnN0YW5jZUVycm9yT25Vbmtub3duUHJvcGVydGllc09wdGlvbiA9IHVuZGVmaW5lZDtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICBjb25maWd1cmVDb21waWxlcihjb25maWc6IHtwcm92aWRlcnM/OiBhbnlbXTsgdXNlSml0PzogYm9vbGVhbjt9KTogdGhpcyB7XG4gICAgaWYgKGNvbmZpZy51c2VKaXQgIT0gbnVsbCkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKCd0aGUgUmVuZGVyMyBjb21waWxlciBKaVQgbW9kZSBpcyBub3QgY29uZmlndXJhYmxlICEnKTtcbiAgICB9XG5cbiAgICBpZiAoY29uZmlnLnByb3ZpZGVycyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICB0aGlzLmNvbXBpbGVyLnNldENvbXBpbGVyUHJvdmlkZXJzKGNvbmZpZy5wcm92aWRlcnMpO1xuICAgIH1cbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIGNvbmZpZ3VyZVRlc3RpbmdNb2R1bGUobW9kdWxlRGVmOiBUZXN0TW9kdWxlTWV0YWRhdGEpOiB0aGlzIHtcbiAgICB0aGlzLmFzc2VydE5vdEluc3RhbnRpYXRlZCgnUjNUZXN0QmVkLmNvbmZpZ3VyZVRlc3RpbmdNb2R1bGUnLCAnY29uZmlndXJlIHRoZSB0ZXN0IG1vZHVsZScpO1xuXG4gICAgLy8gVHJpZ2dlciBtb2R1bGUgc2NvcGluZyBxdWV1ZSBmbHVzaCBiZWZvcmUgZXhlY3V0aW5nIG90aGVyIFRlc3RCZWQgb3BlcmF0aW9ucyBpbiBhIHRlc3QuXG4gICAgLy8gVGhpcyBpcyBuZWVkZWQgZm9yIHRoZSBmaXJzdCB0ZXN0IGludm9jYXRpb24gdG8gZW5zdXJlIHRoYXQgZ2xvYmFsbHkgZGVjbGFyZWQgbW9kdWxlcyBoYXZlXG4gICAgLy8gdGhlaXIgY29tcG9uZW50cyBzY29wZWQgcHJvcGVybHkuIFNlZSB0aGUgYGNoZWNrR2xvYmFsQ29tcGlsYXRpb25GaW5pc2hlZGAgZnVuY3Rpb25cbiAgICAvLyBkZXNjcmlwdGlvbiBmb3IgYWRkaXRpb25hbCBpbmZvLlxuICAgIHRoaXMuY2hlY2tHbG9iYWxDb21waWxhdGlvbkZpbmlzaGVkKCk7XG5cbiAgICAvLyBBbHdheXMgcmUtYXNzaWduIHRoZSBvcHRpb25zLCBldmVuIGlmIHRoZXkncmUgdW5kZWZpbmVkLlxuICAgIC8vIFRoaXMgZW5zdXJlcyB0aGF0IHdlIGRvbid0IGNhcnJ5IHRoZW0gYmV0d2VlbiB0ZXN0cy5cbiAgICB0aGlzLl9pbnN0YW5jZVRlYXJkb3duT3B0aW9ucyA9IG1vZHVsZURlZi50ZWFyZG93bjtcbiAgICB0aGlzLl9pbnN0YW5jZUVycm9yT25Vbmtub3duRWxlbWVudHNPcHRpb24gPSBtb2R1bGVEZWYuZXJyb3JPblVua25vd25FbGVtZW50cztcbiAgICB0aGlzLl9pbnN0YW5jZUVycm9yT25Vbmtub3duUHJvcGVydGllc09wdGlvbiA9IG1vZHVsZURlZi5lcnJvck9uVW5rbm93blByb3BlcnRpZXM7XG4gICAgLy8gU3RvcmUgdGhlIGN1cnJlbnQgdmFsdWUgb2YgdGhlIHN0cmljdCBtb2RlIG9wdGlvbixcbiAgICAvLyBzbyB3ZSBjYW4gcmVzdG9yZSBpdCBsYXRlclxuICAgIHRoaXMuX3ByZXZpb3VzRXJyb3JPblVua25vd25FbGVtZW50c09wdGlvbiA9IGdldFVua25vd25FbGVtZW50U3RyaWN0TW9kZSgpO1xuICAgIHNldFVua25vd25FbGVtZW50U3RyaWN0TW9kZSh0aGlzLnNob3VsZFRocm93RXJyb3JPblVua25vd25FbGVtZW50cygpKTtcbiAgICB0aGlzLl9wcmV2aW91c0Vycm9yT25Vbmtub3duUHJvcGVydGllc09wdGlvbiA9IGdldFVua25vd25Qcm9wZXJ0eVN0cmljdE1vZGUoKTtcbiAgICBzZXRVbmtub3duUHJvcGVydHlTdHJpY3RNb2RlKHRoaXMuc2hvdWxkVGhyb3dFcnJvck9uVW5rbm93blByb3BlcnRpZXMoKSk7XG4gICAgdGhpcy5jb21waWxlci5jb25maWd1cmVUZXN0aW5nTW9kdWxlKG1vZHVsZURlZik7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICBjb21waWxlQ29tcG9uZW50cygpOiBQcm9taXNlPGFueT4ge1xuICAgIHJldHVybiB0aGlzLmNvbXBpbGVyLmNvbXBpbGVDb21wb25lbnRzKCk7XG4gIH1cblxuICBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU6IHVuZGVmaW5lZCwgb3B0aW9uczogSW5qZWN0T3B0aW9ucyZ7XG4gICAgb3B0aW9uYWw6IHRydWVcbiAgfSk6IFR8bnVsbDtcbiAgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlPzogVCwgb3B0aW9ucz86IEluamVjdE9wdGlvbnMpOiBUO1xuICBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU6IG51bGwsIG9wdGlvbnM/OiBJbmplY3RPcHRpb25zKTogVHxudWxsO1xuICAvKiogQGRlcHJlY2F0ZWQgdXNlIG9iamVjdC1iYXNlZCBmbGFncyAoYEluamVjdE9wdGlvbnNgKSBpbnN0ZWFkLiAqL1xuICBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU/OiBULCBmbGFncz86IEluamVjdEZsYWdzKTogVDtcbiAgLyoqIEBkZXByZWNhdGVkIHVzZSBvYmplY3QtYmFzZWQgZmxhZ3MgKGBJbmplY3RPcHRpb25zYCkgaW5zdGVhZC4gKi9cbiAgaW5qZWN0PFQ+KHRva2VuOiBQcm92aWRlclRva2VuPFQ+LCBub3RGb3VuZFZhbHVlOiBudWxsLCBmbGFncz86IEluamVjdEZsYWdzKTogVHxudWxsO1xuICBpbmplY3Q8VD4odG9rZW46IFByb3ZpZGVyVG9rZW48VD4sIG5vdEZvdW5kVmFsdWU/OiBUfG51bGwsIGZsYWdzPzogSW5qZWN0RmxhZ3N8SW5qZWN0T3B0aW9ucyk6IFRcbiAgICAgIHxudWxsIHtcbiAgICBpZiAodG9rZW4gYXMgdW5rbm93biA9PT0gVGVzdEJlZCkge1xuICAgICAgcmV0dXJuIHRoaXMgYXMgYW55O1xuICAgIH1cbiAgICBjb25zdCBVTkRFRklORUQgPSB7fSBhcyB1bmtub3duIGFzIFQ7XG4gICAgY29uc3QgcmVzdWx0ID0gdGhpcy50ZXN0TW9kdWxlUmVmLmluamVjdG9yLmdldCh0b2tlbiwgVU5ERUZJTkVELCBjb252ZXJ0VG9CaXRGbGFncyhmbGFncykpO1xuICAgIHJldHVybiByZXN1bHQgPT09IFVOREVGSU5FRCA/IHRoaXMuY29tcGlsZXIuaW5qZWN0b3IuZ2V0KHRva2VuLCBub3RGb3VuZFZhbHVlLCBmbGFncykgYXMgYW55IDpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXN1bHQ7XG4gIH1cblxuICAvKiogQGRlcHJlY2F0ZWQgZnJvbSB2OS4wLjAgdXNlIFRlc3RCZWQuaW5qZWN0ICovXG4gIGdldDxUPih0b2tlbjogUHJvdmlkZXJUb2tlbjxUPiwgbm90Rm91bmRWYWx1ZT86IFQsIGZsYWdzPzogSW5qZWN0RmxhZ3MpOiBhbnk7XG4gIC8qKiBAZGVwcmVjYXRlZCBmcm9tIHY5LjAuMCB1c2UgVGVzdEJlZC5pbmplY3QgKi9cbiAgZ2V0KHRva2VuOiBhbnksIG5vdEZvdW5kVmFsdWU/OiBhbnkpOiBhbnk7XG4gIC8qKiBAZGVwcmVjYXRlZCBmcm9tIHY5LjAuMCB1c2UgVGVzdEJlZC5pbmplY3QgKi9cbiAgZ2V0KHRva2VuOiBhbnksIG5vdEZvdW5kVmFsdWU6IGFueSA9IEluamVjdG9yLlRIUk9XX0lGX05PVF9GT1VORCxcbiAgICAgIGZsYWdzOiBJbmplY3RGbGFncyA9IEluamVjdEZsYWdzLkRlZmF1bHQpOiBhbnkge1xuICAgIHJldHVybiB0aGlzLmluamVjdCh0b2tlbiwgbm90Rm91bmRWYWx1ZSwgZmxhZ3MpO1xuICB9XG5cbiAgcnVuSW5JbmplY3Rpb25Db250ZXh0PFQ+KGZuOiAoKSA9PiBUKTogVCB7XG4gICAgcmV0dXJuIHRoaXMuaW5qZWN0KEVudmlyb25tZW50SW5qZWN0b3IpLnJ1bkluQ29udGV4dChmbik7XG4gIH1cblxuICBleGVjdXRlKHRva2VuczogYW55W10sIGZuOiBGdW5jdGlvbiwgY29udGV4dD86IGFueSk6IGFueSB7XG4gICAgY29uc3QgcGFyYW1zID0gdG9rZW5zLm1hcCh0ID0+IHRoaXMuaW5qZWN0KHQpKTtcbiAgICByZXR1cm4gZm4uYXBwbHkoY29udGV4dCwgcGFyYW1zKTtcbiAgfVxuXG4gIG92ZXJyaWRlTW9kdWxlKG5nTW9kdWxlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPE5nTW9kdWxlPik6IHRoaXMge1xuICAgIHRoaXMuYXNzZXJ0Tm90SW5zdGFudGlhdGVkKCdvdmVycmlkZU1vZHVsZScsICdvdmVycmlkZSBtb2R1bGUgbWV0YWRhdGEnKTtcbiAgICB0aGlzLmNvbXBpbGVyLm92ZXJyaWRlTW9kdWxlKG5nTW9kdWxlLCBvdmVycmlkZSk7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICBvdmVycmlkZUNvbXBvbmVudChjb21wb25lbnQ6IFR5cGU8YW55Piwgb3ZlcnJpZGU6IE1ldGFkYXRhT3ZlcnJpZGU8Q29tcG9uZW50Pik6IHRoaXMge1xuICAgIHRoaXMuYXNzZXJ0Tm90SW5zdGFudGlhdGVkKCdvdmVycmlkZUNvbXBvbmVudCcsICdvdmVycmlkZSBjb21wb25lbnQgbWV0YWRhdGEnKTtcbiAgICB0aGlzLmNvbXBpbGVyLm92ZXJyaWRlQ29tcG9uZW50KGNvbXBvbmVudCwgb3ZlcnJpZGUpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgb3ZlcnJpZGVUZW1wbGF0ZVVzaW5nVGVzdGluZ01vZHVsZShjb21wb25lbnQ6IFR5cGU8YW55PiwgdGVtcGxhdGU6IHN0cmluZyk6IHRoaXMge1xuICAgIHRoaXMuYXNzZXJ0Tm90SW5zdGFudGlhdGVkKFxuICAgICAgICAnUjNUZXN0QmVkLm92ZXJyaWRlVGVtcGxhdGVVc2luZ1Rlc3RpbmdNb2R1bGUnLFxuICAgICAgICAnQ2Fubm90IG92ZXJyaWRlIHRlbXBsYXRlIHdoZW4gdGhlIHRlc3QgbW9kdWxlIGhhcyBhbHJlYWR5IGJlZW4gaW5zdGFudGlhdGVkJyk7XG4gICAgdGhpcy5jb21waWxlci5vdmVycmlkZVRlbXBsYXRlVXNpbmdUZXN0aW5nTW9kdWxlKGNvbXBvbmVudCwgdGVtcGxhdGUpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgb3ZlcnJpZGVEaXJlY3RpdmUoZGlyZWN0aXZlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPERpcmVjdGl2ZT4pOiB0aGlzIHtcbiAgICB0aGlzLmFzc2VydE5vdEluc3RhbnRpYXRlZCgnb3ZlcnJpZGVEaXJlY3RpdmUnLCAnb3ZlcnJpZGUgZGlyZWN0aXZlIG1ldGFkYXRhJyk7XG4gICAgdGhpcy5jb21waWxlci5vdmVycmlkZURpcmVjdGl2ZShkaXJlY3RpdmUsIG92ZXJyaWRlKTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIG92ZXJyaWRlUGlwZShwaXBlOiBUeXBlPGFueT4sIG92ZXJyaWRlOiBNZXRhZGF0YU92ZXJyaWRlPFBpcGU+KTogdGhpcyB7XG4gICAgdGhpcy5hc3NlcnROb3RJbnN0YW50aWF0ZWQoJ292ZXJyaWRlUGlwZScsICdvdmVycmlkZSBwaXBlIG1ldGFkYXRhJyk7XG4gICAgdGhpcy5jb21waWxlci5vdmVycmlkZVBpcGUocGlwZSwgb3ZlcnJpZGUpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgLyoqXG4gICAqIE92ZXJ3cml0ZXMgYWxsIHByb3ZpZGVycyBmb3IgdGhlIGdpdmVuIHRva2VuIHdpdGggdGhlIGdpdmVuIHByb3ZpZGVyIGRlZmluaXRpb24uXG4gICAqL1xuICBvdmVycmlkZVByb3ZpZGVyKHRva2VuOiBhbnksIHByb3ZpZGVyOiB7dXNlRmFjdG9yeT86IEZ1bmN0aW9uLCB1c2VWYWx1ZT86IGFueSwgZGVwcz86IGFueVtdfSk6XG4gICAgICB0aGlzIHtcbiAgICB0aGlzLmFzc2VydE5vdEluc3RhbnRpYXRlZCgnb3ZlcnJpZGVQcm92aWRlcicsICdvdmVycmlkZSBwcm92aWRlcicpO1xuICAgIHRoaXMuY29tcGlsZXIub3ZlcnJpZGVQcm92aWRlcih0b2tlbiwgcHJvdmlkZXIpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgb3ZlcnJpZGVUZW1wbGF0ZShjb21wb25lbnQ6IFR5cGU8YW55PiwgdGVtcGxhdGU6IHN0cmluZyk6IFRlc3RCZWQge1xuICAgIHJldHVybiB0aGlzLm92ZXJyaWRlQ29tcG9uZW50KGNvbXBvbmVudCwge3NldDoge3RlbXBsYXRlLCB0ZW1wbGF0ZVVybDogbnVsbCF9fSk7XG4gIH1cblxuICBjcmVhdGVDb21wb25lbnQ8VD4odHlwZTogVHlwZTxUPik6IENvbXBvbmVudEZpeHR1cmU8VD4ge1xuICAgIGNvbnN0IHRlc3RDb21wb25lbnRSZW5kZXJlciA9IHRoaXMuaW5qZWN0KFRlc3RDb21wb25lbnRSZW5kZXJlcik7XG4gICAgY29uc3Qgcm9vdEVsSWQgPSBgcm9vdCR7X25leHRSb290RWxlbWVudElkKyt9YDtcbiAgICB0ZXN0Q29tcG9uZW50UmVuZGVyZXIuaW5zZXJ0Um9vdEVsZW1lbnQocm9vdEVsSWQpO1xuXG4gICAgY29uc3QgY29tcG9uZW50RGVmID0gKHR5cGUgYXMgYW55KS7JtWNtcDtcblxuICAgIGlmICghY29tcG9uZW50RGVmKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYEl0IGxvb2tzIGxpa2UgJyR7c3RyaW5naWZ5KHR5cGUpfScgaGFzIG5vdCBiZWVuIGNvbXBpbGVkLmApO1xuICAgIH1cblxuICAgIGNvbnN0IG5vTmdab25lID0gdGhpcy5pbmplY3QoQ29tcG9uZW50Rml4dHVyZU5vTmdab25lLCBmYWxzZSk7XG4gICAgY29uc3QgYXV0b0RldGVjdDogYm9vbGVhbiA9IHRoaXMuaW5qZWN0KENvbXBvbmVudEZpeHR1cmVBdXRvRGV0ZWN0LCBmYWxzZSk7XG4gICAgY29uc3Qgbmdab25lOiBOZ1pvbmV8bnVsbCA9IG5vTmdab25lID8gbnVsbCA6IHRoaXMuaW5qZWN0KE5nWm9uZSwgbnVsbCk7XG4gICAgY29uc3QgY29tcG9uZW50RmFjdG9yeSA9IG5ldyBDb21wb25lbnRGYWN0b3J5KGNvbXBvbmVudERlZik7XG4gICAgY29uc3QgaW5pdENvbXBvbmVudCA9ICgpID0+IHtcbiAgICAgIGNvbnN0IGNvbXBvbmVudFJlZiA9XG4gICAgICAgICAgY29tcG9uZW50RmFjdG9yeS5jcmVhdGUoSW5qZWN0b3IuTlVMTCwgW10sIGAjJHtyb290RWxJZH1gLCB0aGlzLnRlc3RNb2R1bGVSZWYpO1xuICAgICAgcmV0dXJuIG5ldyBDb21wb25lbnRGaXh0dXJlPGFueT4oY29tcG9uZW50UmVmLCBuZ1pvbmUsIGF1dG9EZXRlY3QpO1xuICAgIH07XG4gICAgY29uc3QgZml4dHVyZSA9IG5nWm9uZSA/IG5nWm9uZS5ydW4oaW5pdENvbXBvbmVudCkgOiBpbml0Q29tcG9uZW50KCk7XG4gICAgdGhpcy5fYWN0aXZlRml4dHVyZXMucHVzaChmaXh0dXJlKTtcbiAgICByZXR1cm4gZml4dHVyZTtcbiAgfVxuXG4gIC8qKlxuICAgKiBAaW50ZXJuYWwgc3RyaXAgdGhpcyBmcm9tIHB1Ymxpc2hlZCBkLnRzIGZpbGVzIGR1ZSB0b1xuICAgKiBodHRwczovL2dpdGh1Yi5jb20vbWljcm9zb2Z0L1R5cGVTY3JpcHQvaXNzdWVzLzM2MjE2XG4gICAqL1xuICBwcml2YXRlIGdldCBjb21waWxlcigpOiBUZXN0QmVkQ29tcGlsZXIge1xuICAgIGlmICh0aGlzLl9jb21waWxlciA9PT0gbnVsbCkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKGBOZWVkIHRvIGNhbGwgVGVzdEJlZC5pbml0VGVzdEVudmlyb25tZW50KCkgZmlyc3RgKTtcbiAgICB9XG4gICAgcmV0dXJuIHRoaXMuX2NvbXBpbGVyO1xuICB9XG5cbiAgLyoqXG4gICAqIEBpbnRlcm5hbCBzdHJpcCB0aGlzIGZyb20gcHVibGlzaGVkIGQudHMgZmlsZXMgZHVlIHRvXG4gICAqIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNyb3NvZnQvVHlwZVNjcmlwdC9pc3N1ZXMvMzYyMTZcbiAgICovXG4gIHByaXZhdGUgZ2V0IHRlc3RNb2R1bGVSZWYoKTogTmdNb2R1bGVSZWY8YW55PiB7XG4gICAgaWYgKHRoaXMuX3Rlc3RNb2R1bGVSZWYgPT09IG51bGwpIHtcbiAgICAgIHRoaXMuX3Rlc3RNb2R1bGVSZWYgPSB0aGlzLmNvbXBpbGVyLmZpbmFsaXplKCk7XG4gICAgfVxuICAgIHJldHVybiB0aGlzLl90ZXN0TW9kdWxlUmVmO1xuICB9XG5cbiAgcHJpdmF0ZSBhc3NlcnROb3RJbnN0YW50aWF0ZWQobWV0aG9kTmFtZTogc3RyaW5nLCBtZXRob2REZXNjcmlwdGlvbjogc3RyaW5nKSB7XG4gICAgaWYgKHRoaXMuX3Rlc3RNb2R1bGVSZWYgIT09IG51bGwpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihcbiAgICAgICAgICBgQ2Fubm90ICR7bWV0aG9kRGVzY3JpcHRpb259IHdoZW4gdGhlIHRlc3QgbW9kdWxlIGhhcyBhbHJlYWR5IGJlZW4gaW5zdGFudGlhdGVkLiBgICtcbiAgICAgICAgICBgTWFrZSBzdXJlIHlvdSBhcmUgbm90IHVzaW5nIFxcYGluamVjdFxcYCBiZWZvcmUgXFxgJHttZXRob2ROYW1lfVxcYC5gKTtcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogQ2hlY2sgd2hldGhlciB0aGUgbW9kdWxlIHNjb3BpbmcgcXVldWUgc2hvdWxkIGJlIGZsdXNoZWQsIGFuZCBmbHVzaCBpdCBpZiBuZWVkZWQuXG4gICAqXG4gICAqIFdoZW4gdGhlIFRlc3RCZWQgaXMgcmVzZXQsIGl0IGNsZWFycyB0aGUgSklUIG1vZHVsZSBjb21waWxhdGlvbiBxdWV1ZSwgY2FuY2VsbGluZyBhbnlcbiAgICogaW4tcHJvZ3Jlc3MgbW9kdWxlIGNvbXBpbGF0aW9uLiBUaGlzIGNyZWF0ZXMgYSBwb3RlbnRpYWwgaGF6YXJkIC0gdGhlIHZlcnkgZmlyc3QgdGltZSB0aGVcbiAgICogVGVzdEJlZCBpcyBpbml0aWFsaXplZCAob3IgaWYgaXQncyByZXNldCB3aXRob3V0IGJlaW5nIGluaXRpYWxpemVkKSwgdGhlcmUgbWF5IGJlIHBlbmRpbmdcbiAgICogY29tcGlsYXRpb25zIG9mIG1vZHVsZXMgZGVjbGFyZWQgaW4gZ2xvYmFsIHNjb3BlLiBUaGVzZSBjb21waWxhdGlvbnMgc2hvdWxkIGJlIGZpbmlzaGVkLlxuICAgKlxuICAgKiBUbyBlbnN1cmUgdGhhdCBnbG9iYWxseSBkZWNsYXJlZCBtb2R1bGVzIGhhdmUgdGhlaXIgY29tcG9uZW50cyBzY29wZWQgcHJvcGVybHksIHRoaXMgZnVuY3Rpb25cbiAgICogaXMgY2FsbGVkIHdoZW5ldmVyIFRlc3RCZWQgaXMgaW5pdGlhbGl6ZWQgb3IgcmVzZXQuIFRoZSBfZmlyc3RfIHRpbWUgdGhhdCB0aGlzIGhhcHBlbnMsIHByaW9yXG4gICAqIHRvIGFueSBvdGhlciBvcGVyYXRpb25zLCB0aGUgc2NvcGluZyBxdWV1ZSBpcyBmbHVzaGVkLlxuICAgKi9cbiAgcHJpdmF0ZSBjaGVja0dsb2JhbENvbXBpbGF0aW9uRmluaXNoZWQoKTogdm9pZCB7XG4gICAgLy8gQ2hlY2tpbmcgX3Rlc3ROZ01vZHVsZVJlZiBpcyBudWxsIHNob3VsZCBub3QgYmUgbmVjZXNzYXJ5LCBidXQgaXMgbGVmdCBpbiBhcyBhbiBhZGRpdGlvbmFsXG4gICAgLy8gZ3VhcmQgdGhhdCBjb21waWxhdGlvbnMgcXVldWVkIGluIHRlc3RzIChhZnRlciBpbnN0YW50aWF0aW9uKSBhcmUgbmV2ZXIgZmx1c2hlZCBhY2NpZGVudGFsbHkuXG4gICAgaWYgKCF0aGlzLmdsb2JhbENvbXBpbGF0aW9uQ2hlY2tlZCAmJiB0aGlzLl90ZXN0TW9kdWxlUmVmID09PSBudWxsKSB7XG4gICAgICBmbHVzaE1vZHVsZVNjb3BpbmdRdWV1ZUFzTXVjaEFzUG9zc2libGUoKTtcbiAgICB9XG4gICAgdGhpcy5nbG9iYWxDb21waWxhdGlvbkNoZWNrZWQgPSB0cnVlO1xuICB9XG5cbiAgcHJpdmF0ZSBkZXN0cm95QWN0aXZlRml4dHVyZXMoKTogdm9pZCB7XG4gICAgbGV0IGVycm9yQ291bnQgPSAwO1xuICAgIHRoaXMuX2FjdGl2ZUZpeHR1cmVzLmZvckVhY2goKGZpeHR1cmUpID0+IHtcbiAgICAgIHRyeSB7XG4gICAgICAgIGZpeHR1cmUuZGVzdHJveSgpO1xuICAgICAgfSBjYXRjaCAoZSkge1xuICAgICAgICBlcnJvckNvdW50Kys7XG4gICAgICAgIGNvbnNvbGUuZXJyb3IoJ0Vycm9yIGR1cmluZyBjbGVhbnVwIG9mIGNvbXBvbmVudCcsIHtcbiAgICAgICAgICBjb21wb25lbnQ6IGZpeHR1cmUuY29tcG9uZW50SW5zdGFuY2UsXG4gICAgICAgICAgc3RhY2t0cmFjZTogZSxcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfSk7XG4gICAgdGhpcy5fYWN0aXZlRml4dHVyZXMgPSBbXTtcblxuICAgIGlmIChlcnJvckNvdW50ID4gMCAmJiB0aGlzLnNob3VsZFJldGhyb3dUZWFyZG93bkVycm9ycygpKSB7XG4gICAgICB0aHJvdyBFcnJvcihcbiAgICAgICAgICBgJHtlcnJvckNvdW50fSAkeyhlcnJvckNvdW50ID09PSAxID8gJ2NvbXBvbmVudCcgOiAnY29tcG9uZW50cycpfSBgICtcbiAgICAgICAgICBgdGhyZXcgZXJyb3JzIGR1cmluZyBjbGVhbnVwYCk7XG4gICAgfVxuICB9XG5cbiAgc2hvdWxkUmV0aHJvd1RlYXJkb3duRXJyb3JzKCk6IGJvb2xlYW4ge1xuICAgIGNvbnN0IGluc3RhbmNlT3B0aW9ucyA9IHRoaXMuX2luc3RhbmNlVGVhcmRvd25PcHRpb25zO1xuICAgIGNvbnN0IGVudmlyb25tZW50T3B0aW9ucyA9IFRlc3RCZWRJbXBsLl9lbnZpcm9ubWVudFRlYXJkb3duT3B0aW9ucztcblxuICAgIC8vIElmIHRoZSBuZXcgdGVhcmRvd24gYmVoYXZpb3IgaGFzbid0IGJlZW4gY29uZmlndXJlZCwgcHJlc2VydmUgdGhlIG9sZCBiZWhhdmlvci5cbiAgICBpZiAoIWluc3RhbmNlT3B0aW9ucyAmJiAhZW52aXJvbm1lbnRPcHRpb25zKSB7XG4gICAgICByZXR1cm4gVEVBUkRPV05fVEVTVElOR19NT0RVTEVfT05fREVTVFJPWV9ERUZBVUxUO1xuICAgIH1cblxuICAgIC8vIE90aGVyd2lzZSB1c2UgdGhlIGNvbmZpZ3VyZWQgYmVoYXZpb3Igb3IgZGVmYXVsdCB0byByZXRocm93aW5nLlxuICAgIHJldHVybiBpbnN0YW5jZU9wdGlvbnM/LnJldGhyb3dFcnJvcnMgPz8gZW52aXJvbm1lbnRPcHRpb25zPy5yZXRocm93RXJyb3JzID8/XG4gICAgICAgIHRoaXMuc2hvdWxkVGVhckRvd25UZXN0aW5nTW9kdWxlKCk7XG4gIH1cblxuICBzaG91bGRUaHJvd0Vycm9yT25Vbmtub3duRWxlbWVudHMoKTogYm9vbGVhbiB7XG4gICAgLy8gQ2hlY2sgaWYgYSBjb25maWd1cmF0aW9uIGhhcyBiZWVuIHByb3ZpZGVkIHRvIHRocm93IHdoZW4gYW4gdW5rbm93biBlbGVtZW50IGlzIGZvdW5kXG4gICAgcmV0dXJuIHRoaXMuX2luc3RhbmNlRXJyb3JPblVua25vd25FbGVtZW50c09wdGlvbiA/P1xuICAgICAgICBUZXN0QmVkSW1wbC5fZW52aXJvbm1lbnRFcnJvck9uVW5rbm93bkVsZW1lbnRzT3B0aW9uID8/IFRIUk9XX09OX1VOS05PV05fRUxFTUVOVFNfREVGQVVMVDtcbiAgfVxuXG4gIHNob3VsZFRocm93RXJyb3JPblVua25vd25Qcm9wZXJ0aWVzKCk6IGJvb2xlYW4ge1xuICAgIC8vIENoZWNrIGlmIGEgY29uZmlndXJhdGlvbiBoYXMgYmVlbiBwcm92aWRlZCB0byB0aHJvdyB3aGVuIGFuIHVua25vd24gcHJvcGVydHkgaXMgZm91bmRcbiAgICByZXR1cm4gdGhpcy5faW5zdGFuY2VFcnJvck9uVW5rbm93blByb3BlcnRpZXNPcHRpb24gPz9cbiAgICAgICAgVGVzdEJlZEltcGwuX2Vudmlyb25tZW50RXJyb3JPblVua25vd25Qcm9wZXJ0aWVzT3B0aW9uID8/XG4gICAgICAgIFRIUk9XX09OX1VOS05PV05fUFJPUEVSVElFU19ERUZBVUxUO1xuICB9XG5cbiAgc2hvdWxkVGVhckRvd25UZXN0aW5nTW9kdWxlKCk6IGJvb2xlYW4ge1xuICAgIHJldHVybiB0aGlzLl9pbnN0YW5jZVRlYXJkb3duT3B0aW9ucz8uZGVzdHJveUFmdGVyRWFjaCA/P1xuICAgICAgICBUZXN0QmVkSW1wbC5fZW52aXJvbm1lbnRUZWFyZG93bk9wdGlvbnM/LmRlc3Ryb3lBZnRlckVhY2ggPz9cbiAgICAgICAgVEVBUkRPV05fVEVTVElOR19NT0RVTEVfT05fREVTVFJPWV9ERUZBVUxUO1xuICB9XG5cbiAgdGVhckRvd25UZXN0aW5nTW9kdWxlKCkge1xuICAgIC8vIElmIHRoZSBtb2R1bGUgcmVmIGhhcyBhbHJlYWR5IGJlZW4gZGVzdHJveWVkLCB3ZSB3b24ndCBiZSBhYmxlIHRvIGdldCBhIHRlc3QgcmVuZGVyZXIuXG4gICAgaWYgKHRoaXMuX3Rlc3RNb2R1bGVSZWYgPT09IG51bGwpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgLy8gUmVzb2x2ZSB0aGUgcmVuZGVyZXIgYWhlYWQgb2YgdGltZSwgYmVjYXVzZSB3ZSB3YW50IHRvIHJlbW92ZSB0aGUgcm9vdCBlbGVtZW50cyBhcyB0aGUgdmVyeVxuICAgIC8vIGxhc3Qgc3RlcCwgYnV0IHRoZSBpbmplY3RvciB3aWxsIGJlIGRlc3Ryb3llZCBhcyBhIHBhcnQgb2YgdGhlIG1vZHVsZSByZWYgZGVzdHJ1Y3Rpb24uXG4gICAgY29uc3QgdGVzdFJlbmRlcmVyID0gdGhpcy5pbmplY3QoVGVzdENvbXBvbmVudFJlbmRlcmVyKTtcbiAgICB0cnkge1xuICAgICAgdGhpcy5fdGVzdE1vZHVsZVJlZi5kZXN0cm95KCk7XG4gICAgfSBjYXRjaCAoZSkge1xuICAgICAgaWYgKHRoaXMuc2hvdWxkUmV0aHJvd1RlYXJkb3duRXJyb3JzKCkpIHtcbiAgICAgICAgdGhyb3cgZTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGNvbnNvbGUuZXJyb3IoJ0Vycm9yIGR1cmluZyBjbGVhbnVwIG9mIGEgdGVzdGluZyBtb2R1bGUnLCB7XG4gICAgICAgICAgY29tcG9uZW50OiB0aGlzLl90ZXN0TW9kdWxlUmVmLmluc3RhbmNlLFxuICAgICAgICAgIHN0YWNrdHJhY2U6IGUsXG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH0gZmluYWxseSB7XG4gICAgICB0ZXN0UmVuZGVyZXIucmVtb3ZlQWxsUm9vdEVsZW1lbnRzPy4oKTtcbiAgICB9XG4gIH1cbn1cblxuLyoqXG4gKiBAZGVzY3JpcHRpb25cbiAqIENvbmZpZ3VyZXMgYW5kIGluaXRpYWxpemVzIGVudmlyb25tZW50IGZvciB1bml0IHRlc3RpbmcgYW5kIHByb3ZpZGVzIG1ldGhvZHMgZm9yXG4gKiBjcmVhdGluZyBjb21wb25lbnRzIGFuZCBzZXJ2aWNlcyBpbiB1bml0IHRlc3RzLlxuICpcbiAqIGBUZXN0QmVkYCBpcyB0aGUgcHJpbWFyeSBhcGkgZm9yIHdyaXRpbmcgdW5pdCB0ZXN0cyBmb3IgQW5ndWxhciBhcHBsaWNhdGlvbnMgYW5kIGxpYnJhcmllcy5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBUZXN0QmVkOiBUZXN0QmVkU3RhdGljID0gVGVzdEJlZEltcGw7XG5cbi8qKlxuICogQWxsb3dzIGluamVjdGluZyBkZXBlbmRlbmNpZXMgaW4gYGJlZm9yZUVhY2goKWAgYW5kIGBpdCgpYC4gTm90ZTogdGhpcyBmdW5jdGlvblxuICogKGltcG9ydGVkIGZyb20gdGhlIGBAYW5ndWxhci9jb3JlL3Rlc3RpbmdgIHBhY2thZ2UpIGNhbiAqKm9ubHkqKiBiZSB1c2VkIHRvIGluamVjdCBkZXBlbmRlbmNpZXNcbiAqIGluIHRlc3RzLiBUbyBpbmplY3QgZGVwZW5kZW5jaWVzIGluIHlvdXIgYXBwbGljYXRpb24gY29kZSwgdXNlIHRoZSBbYGluamVjdGBdKGFwaS9jb3JlL2luamVjdClcbiAqIGZ1bmN0aW9uIGZyb20gdGhlIGBAYW5ndWxhci9jb3JlYCBwYWNrYWdlIGluc3RlYWQuXG4gKlxuICogRXhhbXBsZTpcbiAqXG4gKiBgYGBcbiAqIGJlZm9yZUVhY2goaW5qZWN0KFtEZXBlbmRlbmN5LCBBQ2xhc3NdLCAoZGVwLCBvYmplY3QpID0+IHtcbiAqICAgLy8gc29tZSBjb2RlIHRoYXQgdXNlcyBgZGVwYCBhbmQgYG9iamVjdGBcbiAqICAgLy8gLi4uXG4gKiB9KSk7XG4gKlxuICogaXQoJy4uLicsIGluamVjdChbQUNsYXNzXSwgKG9iamVjdCkgPT4ge1xuICogICBvYmplY3QuZG9Tb21ldGhpbmcoKTtcbiAqICAgZXhwZWN0KC4uLik7XG4gKiB9KVxuICogYGBgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gaW5qZWN0KHRva2VuczogYW55W10sIGZuOiBGdW5jdGlvbik6ICgpID0+IGFueSB7XG4gIGNvbnN0IHRlc3RCZWQgPSBUZXN0QmVkSW1wbC5JTlNUQU5DRTtcbiAgLy8gTm90IHVzaW5nIGFuIGFycm93IGZ1bmN0aW9uIHRvIHByZXNlcnZlIGNvbnRleHQgcGFzc2VkIGZyb20gY2FsbCBzaXRlXG4gIHJldHVybiBmdW5jdGlvbih0aGlzOiB1bmtub3duKSB7XG4gICAgcmV0dXJuIHRlc3RCZWQuZXhlY3V0ZSh0b2tlbnMsIGZuLCB0aGlzKTtcbiAgfTtcbn1cblxuLyoqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjbGFzcyBJbmplY3RTZXR1cFdyYXBwZXIge1xuICBjb25zdHJ1Y3Rvcihwcml2YXRlIF9tb2R1bGVEZWY6ICgpID0+IFRlc3RNb2R1bGVNZXRhZGF0YSkge31cblxuICBwcml2YXRlIF9hZGRNb2R1bGUoKSB7XG4gICAgY29uc3QgbW9kdWxlRGVmID0gdGhpcy5fbW9kdWxlRGVmKCk7XG4gICAgaWYgKG1vZHVsZURlZikge1xuICAgICAgVGVzdEJlZEltcGwuY29uZmlndXJlVGVzdGluZ01vZHVsZShtb2R1bGVEZWYpO1xuICAgIH1cbiAgfVxuXG4gIGluamVjdCh0b2tlbnM6IGFueVtdLCBmbjogRnVuY3Rpb24pOiAoKSA9PiBhbnkge1xuICAgIGNvbnN0IHNlbGYgPSB0aGlzO1xuICAgIC8vIE5vdCB1c2luZyBhbiBhcnJvdyBmdW5jdGlvbiB0byBwcmVzZXJ2ZSBjb250ZXh0IHBhc3NlZCBmcm9tIGNhbGwgc2l0ZVxuICAgIHJldHVybiBmdW5jdGlvbih0aGlzOiB1bmtub3duKSB7XG4gICAgICBzZWxmLl9hZGRNb2R1bGUoKTtcbiAgICAgIHJldHVybiBpbmplY3QodG9rZW5zLCBmbikuY2FsbCh0aGlzKTtcbiAgICB9O1xuICB9XG59XG5cbi8qKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gd2l0aE1vZHVsZShtb2R1bGVEZWY6IFRlc3RNb2R1bGVNZXRhZGF0YSk6IEluamVjdFNldHVwV3JhcHBlcjtcbmV4cG9ydCBmdW5jdGlvbiB3aXRoTW9kdWxlKG1vZHVsZURlZjogVGVzdE1vZHVsZU1ldGFkYXRhLCBmbjogRnVuY3Rpb24pOiAoKSA9PiBhbnk7XG5leHBvcnQgZnVuY3Rpb24gd2l0aE1vZHVsZShtb2R1bGVEZWY6IFRlc3RNb2R1bGVNZXRhZGF0YSwgZm4/OiBGdW5jdGlvbnxudWxsKTogKCgpID0+IGFueSl8XG4gICAgSW5qZWN0U2V0dXBXcmFwcGVyIHtcbiAgaWYgKGZuKSB7XG4gICAgLy8gTm90IHVzaW5nIGFuIGFycm93IGZ1bmN0aW9uIHRvIHByZXNlcnZlIGNvbnRleHQgcGFzc2VkIGZyb20gY2FsbCBzaXRlXG4gICAgcmV0dXJuIGZ1bmN0aW9uKHRoaXM6IHVua25vd24pIHtcbiAgICAgIGNvbnN0IHRlc3RCZWQgPSBUZXN0QmVkSW1wbC5JTlNUQU5DRTtcbiAgICAgIGlmIChtb2R1bGVEZWYpIHtcbiAgICAgICAgdGVzdEJlZC5jb25maWd1cmVUZXN0aW5nTW9kdWxlKG1vZHVsZURlZik7XG4gICAgICB9XG4gICAgICByZXR1cm4gZm4uYXBwbHkodGhpcyk7XG4gICAgfTtcbiAgfVxuICByZXR1cm4gbmV3IEluamVjdFNldHVwV3JhcHBlcigoKSA9PiBtb2R1bGVEZWYpO1xufVxuIl19