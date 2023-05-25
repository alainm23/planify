/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { getNullInjector } from '../di/r3_injector';
import { ComponentFactory } from './component_ref';
import { getComponentDef } from './definition';
import { assertComponentDef } from './errors';
/**
 * Creates a `ComponentRef` instance based on provided component type and a set of options.
 *
 * @usageNotes
 *
 * The example below demonstrates how the `createComponent` function can be used
 * to create an instance of a ComponentRef dynamically and attach it to an ApplicationRef,
 * so that it gets included into change detection cycles.
 *
 * Note: the example uses standalone components, but the function can also be used for
 * non-standalone components (declared in an NgModule) as well.
 *
 * ```typescript
 * @Component({
 *   standalone: true,
 *   template: `Hello {{ name }}!`
 * })
 * class HelloComponent {
 *   name = 'Angular';
 * }
 *
 * @Component({
 *   standalone: true,
 *   template: `<div id="hello-component-host"></div>`
 * })
 * class RootComponent {}
 *
 * // Bootstrap an application.
 * const applicationRef = await bootstrapApplication(RootComponent);
 *
 * // Locate a DOM node that would be used as a host.
 * const host = document.getElementById('hello-component-host');
 *
 * // Get an `EnvironmentInjector` instance from the `ApplicationRef`.
 * const environmentInjector = applicationRef.injector;
 *
 * // We can now create a `ComponentRef` instance.
 * const componentRef = createComponent(HelloComponent, {host, environmentInjector});
 *
 * // Last step is to register the newly created ref using the `ApplicationRef` instance
 * // to include the component view into change detection cycles.
 * applicationRef.attachView(componentRef.hostView);
 * ```
 *
 * @param component Component class reference.
 * @param options Set of options to use:
 *  * `environmentInjector`: An `EnvironmentInjector` instance to be used for the component, see
 * additional info about it at https://angular.io/guide/standalone-components#environment-injectors.
 *  * `hostElement` (optional): A DOM node that should act as a host node for the component. If not
 * provided, Angular creates one based on the tag name used in the component selector (and falls
 * back to using `div` if selector doesn't have tag name info).
 *  * `elementInjector` (optional): An `ElementInjector` instance, see additional info about it at
 * https://angular.io/guide/hierarchical-dependency-injection#elementinjector.
 *  * `projectableNodes` (optional): A list of DOM nodes that should be projected through
 *                      [`<ng-content>`](api/core/ng-content) of the new component instance.
 * @returns ComponentRef instance that represents a given Component.
 *
 * @publicApi
 */
export function createComponent(component, options) {
    ngDevMode && assertComponentDef(component);
    const componentDef = getComponentDef(component);
    const elementInjector = options.elementInjector || getNullInjector();
    const factory = new ComponentFactory(componentDef);
    return factory.create(elementInjector, options.projectableNodes, options.hostElement, options.environmentInjector);
}
/**
 * Creates an object that allows to retrieve component metadata.
 *
 * @usageNotes
 *
 * The example below demonstrates how to use the function and how the fields
 * of the returned object map to the component metadata.
 *
 * ```typescript
 * @Component({
 *   standalone: true,
 *   selector: 'foo-component',
 *   template: `
 *     <ng-content></ng-content>
 *     <ng-content select="content-selector-a"></ng-content>
 *   `,
 * })
 * class FooComponent {
 *   @Input('inputName') inputPropName: string;
 *   @Output('outputName') outputPropName = new EventEmitter<void>();
 * }
 *
 * const mirror = reflectComponentType(FooComponent);
 * expect(mirror.type).toBe(FooComponent);
 * expect(mirror.selector).toBe('foo-component');
 * expect(mirror.isStandalone).toBe(true);
 * expect(mirror.inputs).toEqual([{propName: 'inputName', templateName: 'inputPropName'}]);
 * expect(mirror.outputs).toEqual([{propName: 'outputName', templateName: 'outputPropName'}]);
 * expect(mirror.ngContentSelectors).toEqual([
 *   '*',                 // first `<ng-content>` in a template, the selector defaults to `*`
 *   'content-selector-a' // second `<ng-content>` in a template
 * ]);
 * ```
 *
 * @param component Component class reference.
 * @returns An object that allows to retrieve component metadata.
 *
 * @publicApi
 */
export function reflectComponentType(component) {
    const componentDef = getComponentDef(component);
    if (!componentDef)
        return null;
    const factory = new ComponentFactory(componentDef);
    return {
        get selector() {
            return factory.selector;
        },
        get type() {
            return factory.componentType;
        },
        get inputs() {
            return factory.inputs;
        },
        get outputs() {
            return factory.outputs;
        },
        get ngContentSelectors() {
            return factory.ngContentSelectors;
        },
        get isStandalone() {
            return componentDef.standalone;
        },
    };
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29tcG9uZW50LmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvcmVuZGVyMy9jb21wb25lbnQudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBR0gsT0FBTyxFQUFzQixlQUFlLEVBQUMsTUFBTSxtQkFBbUIsQ0FBQztBQUl2RSxPQUFPLEVBQUMsZ0JBQWdCLEVBQUMsTUFBTSxpQkFBaUIsQ0FBQztBQUNqRCxPQUFPLEVBQUMsZUFBZSxFQUFDLE1BQU0sY0FBYyxDQUFDO0FBQzdDLE9BQU8sRUFBQyxrQkFBa0IsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUU1Qzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQTBERztBQUNILE1BQU0sVUFBVSxlQUFlLENBQUksU0FBa0IsRUFBRSxPQUt0RDtJQUNDLFNBQVMsSUFBSSxrQkFBa0IsQ0FBQyxTQUFTLENBQUMsQ0FBQztJQUMzQyxNQUFNLFlBQVksR0FBRyxlQUFlLENBQUMsU0FBUyxDQUFFLENBQUM7SUFDakQsTUFBTSxlQUFlLEdBQUcsT0FBTyxDQUFDLGVBQWUsSUFBSSxlQUFlLEVBQUUsQ0FBQztJQUNyRSxNQUFNLE9BQU8sR0FBRyxJQUFJLGdCQUFnQixDQUFJLFlBQVksQ0FBQyxDQUFDO0lBQ3RELE9BQU8sT0FBTyxDQUFDLE1BQU0sQ0FDakIsZUFBZSxFQUFFLE9BQU8sQ0FBQyxnQkFBZ0IsRUFBRSxPQUFPLENBQUMsV0FBVyxFQUFFLE9BQU8sQ0FBQyxtQkFBbUIsQ0FBQyxDQUFDO0FBQ25HLENBQUM7QUFvQ0Q7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBc0NHO0FBQ0gsTUFBTSxVQUFVLG9CQUFvQixDQUFJLFNBQWtCO0lBQ3hELE1BQU0sWUFBWSxHQUFHLGVBQWUsQ0FBQyxTQUFTLENBQUMsQ0FBQztJQUNoRCxJQUFJLENBQUMsWUFBWTtRQUFFLE9BQU8sSUFBSSxDQUFDO0lBRS9CLE1BQU0sT0FBTyxHQUFHLElBQUksZ0JBQWdCLENBQUksWUFBWSxDQUFDLENBQUM7SUFDdEQsT0FBTztRQUNMLElBQUksUUFBUTtZQUNWLE9BQU8sT0FBTyxDQUFDLFFBQVEsQ0FBQztRQUMxQixDQUFDO1FBQ0QsSUFBSSxJQUFJO1lBQ04sT0FBTyxPQUFPLENBQUMsYUFBYSxDQUFDO1FBQy9CLENBQUM7UUFDRCxJQUFJLE1BQU07WUFDUixPQUFPLE9BQU8sQ0FBQyxNQUFNLENBQUM7UUFDeEIsQ0FBQztRQUNELElBQUksT0FBTztZQUNULE9BQU8sT0FBTyxDQUFDLE9BQU8sQ0FBQztRQUN6QixDQUFDO1FBQ0QsSUFBSSxrQkFBa0I7WUFDcEIsT0FBTyxPQUFPLENBQUMsa0JBQWtCLENBQUM7UUFDcEMsQ0FBQztRQUNELElBQUksWUFBWTtZQUNkLE9BQU8sWUFBWSxDQUFDLFVBQVUsQ0FBQztRQUNqQyxDQUFDO0tBQ0YsQ0FBQztBQUNKLENBQUMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtJbmplY3Rvcn0gZnJvbSAnLi4vZGkvaW5qZWN0b3InO1xuaW1wb3J0IHtFbnZpcm9ubWVudEluamVjdG9yLCBnZXROdWxsSW5qZWN0b3J9IGZyb20gJy4uL2RpL3IzX2luamVjdG9yJztcbmltcG9ydCB7VHlwZX0gZnJvbSAnLi4vaW50ZXJmYWNlL3R5cGUnO1xuaW1wb3J0IHtDb21wb25lbnRSZWZ9IGZyb20gJy4uL2xpbmtlci9jb21wb25lbnRfZmFjdG9yeSc7XG5cbmltcG9ydCB7Q29tcG9uZW50RmFjdG9yeX0gZnJvbSAnLi9jb21wb25lbnRfcmVmJztcbmltcG9ydCB7Z2V0Q29tcG9uZW50RGVmfSBmcm9tICcuL2RlZmluaXRpb24nO1xuaW1wb3J0IHthc3NlcnRDb21wb25lbnREZWZ9IGZyb20gJy4vZXJyb3JzJztcblxuLyoqXG4gKiBDcmVhdGVzIGEgYENvbXBvbmVudFJlZmAgaW5zdGFuY2UgYmFzZWQgb24gcHJvdmlkZWQgY29tcG9uZW50IHR5cGUgYW5kIGEgc2V0IG9mIG9wdGlvbnMuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBUaGUgZXhhbXBsZSBiZWxvdyBkZW1vbnN0cmF0ZXMgaG93IHRoZSBgY3JlYXRlQ29tcG9uZW50YCBmdW5jdGlvbiBjYW4gYmUgdXNlZFxuICogdG8gY3JlYXRlIGFuIGluc3RhbmNlIG9mIGEgQ29tcG9uZW50UmVmIGR5bmFtaWNhbGx5IGFuZCBhdHRhY2ggaXQgdG8gYW4gQXBwbGljYXRpb25SZWYsXG4gKiBzbyB0aGF0IGl0IGdldHMgaW5jbHVkZWQgaW50byBjaGFuZ2UgZGV0ZWN0aW9uIGN5Y2xlcy5cbiAqXG4gKiBOb3RlOiB0aGUgZXhhbXBsZSB1c2VzIHN0YW5kYWxvbmUgY29tcG9uZW50cywgYnV0IHRoZSBmdW5jdGlvbiBjYW4gYWxzbyBiZSB1c2VkIGZvclxuICogbm9uLXN0YW5kYWxvbmUgY29tcG9uZW50cyAoZGVjbGFyZWQgaW4gYW4gTmdNb2R1bGUpIGFzIHdlbGwuXG4gKlxuICogYGBgdHlwZXNjcmlwdFxuICogQENvbXBvbmVudCh7XG4gKiAgIHN0YW5kYWxvbmU6IHRydWUsXG4gKiAgIHRlbXBsYXRlOiBgSGVsbG8ge3sgbmFtZSB9fSFgXG4gKiB9KVxuICogY2xhc3MgSGVsbG9Db21wb25lbnQge1xuICogICBuYW1lID0gJ0FuZ3VsYXInO1xuICogfVxuICpcbiAqIEBDb21wb25lbnQoe1xuICogICBzdGFuZGFsb25lOiB0cnVlLFxuICogICB0ZW1wbGF0ZTogYDxkaXYgaWQ9XCJoZWxsby1jb21wb25lbnQtaG9zdFwiPjwvZGl2PmBcbiAqIH0pXG4gKiBjbGFzcyBSb290Q29tcG9uZW50IHt9XG4gKlxuICogLy8gQm9vdHN0cmFwIGFuIGFwcGxpY2F0aW9uLlxuICogY29uc3QgYXBwbGljYXRpb25SZWYgPSBhd2FpdCBib290c3RyYXBBcHBsaWNhdGlvbihSb290Q29tcG9uZW50KTtcbiAqXG4gKiAvLyBMb2NhdGUgYSBET00gbm9kZSB0aGF0IHdvdWxkIGJlIHVzZWQgYXMgYSBob3N0LlxuICogY29uc3QgaG9zdCA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdoZWxsby1jb21wb25lbnQtaG9zdCcpO1xuICpcbiAqIC8vIEdldCBhbiBgRW52aXJvbm1lbnRJbmplY3RvcmAgaW5zdGFuY2UgZnJvbSB0aGUgYEFwcGxpY2F0aW9uUmVmYC5cbiAqIGNvbnN0IGVudmlyb25tZW50SW5qZWN0b3IgPSBhcHBsaWNhdGlvblJlZi5pbmplY3RvcjtcbiAqXG4gKiAvLyBXZSBjYW4gbm93IGNyZWF0ZSBhIGBDb21wb25lbnRSZWZgIGluc3RhbmNlLlxuICogY29uc3QgY29tcG9uZW50UmVmID0gY3JlYXRlQ29tcG9uZW50KEhlbGxvQ29tcG9uZW50LCB7aG9zdCwgZW52aXJvbm1lbnRJbmplY3Rvcn0pO1xuICpcbiAqIC8vIExhc3Qgc3RlcCBpcyB0byByZWdpc3RlciB0aGUgbmV3bHkgY3JlYXRlZCByZWYgdXNpbmcgdGhlIGBBcHBsaWNhdGlvblJlZmAgaW5zdGFuY2VcbiAqIC8vIHRvIGluY2x1ZGUgdGhlIGNvbXBvbmVudCB2aWV3IGludG8gY2hhbmdlIGRldGVjdGlvbiBjeWNsZXMuXG4gKiBhcHBsaWNhdGlvblJlZi5hdHRhY2hWaWV3KGNvbXBvbmVudFJlZi5ob3N0Vmlldyk7XG4gKiBgYGBcbiAqXG4gKiBAcGFyYW0gY29tcG9uZW50IENvbXBvbmVudCBjbGFzcyByZWZlcmVuY2UuXG4gKiBAcGFyYW0gb3B0aW9ucyBTZXQgb2Ygb3B0aW9ucyB0byB1c2U6XG4gKiAgKiBgZW52aXJvbm1lbnRJbmplY3RvcmA6IEFuIGBFbnZpcm9ubWVudEluamVjdG9yYCBpbnN0YW5jZSB0byBiZSB1c2VkIGZvciB0aGUgY29tcG9uZW50LCBzZWVcbiAqIGFkZGl0aW9uYWwgaW5mbyBhYm91dCBpdCBhdCBodHRwczovL2FuZ3VsYXIuaW8vZ3VpZGUvc3RhbmRhbG9uZS1jb21wb25lbnRzI2Vudmlyb25tZW50LWluamVjdG9ycy5cbiAqICAqIGBob3N0RWxlbWVudGAgKG9wdGlvbmFsKTogQSBET00gbm9kZSB0aGF0IHNob3VsZCBhY3QgYXMgYSBob3N0IG5vZGUgZm9yIHRoZSBjb21wb25lbnQuIElmIG5vdFxuICogcHJvdmlkZWQsIEFuZ3VsYXIgY3JlYXRlcyBvbmUgYmFzZWQgb24gdGhlIHRhZyBuYW1lIHVzZWQgaW4gdGhlIGNvbXBvbmVudCBzZWxlY3RvciAoYW5kIGZhbGxzXG4gKiBiYWNrIHRvIHVzaW5nIGBkaXZgIGlmIHNlbGVjdG9yIGRvZXNuJ3QgaGF2ZSB0YWcgbmFtZSBpbmZvKS5cbiAqICAqIGBlbGVtZW50SW5qZWN0b3JgIChvcHRpb25hbCk6IEFuIGBFbGVtZW50SW5qZWN0b3JgIGluc3RhbmNlLCBzZWUgYWRkaXRpb25hbCBpbmZvIGFib3V0IGl0IGF0XG4gKiBodHRwczovL2FuZ3VsYXIuaW8vZ3VpZGUvaGllcmFyY2hpY2FsLWRlcGVuZGVuY3ktaW5qZWN0aW9uI2VsZW1lbnRpbmplY3Rvci5cbiAqICAqIGBwcm9qZWN0YWJsZU5vZGVzYCAob3B0aW9uYWwpOiBBIGxpc3Qgb2YgRE9NIG5vZGVzIHRoYXQgc2hvdWxkIGJlIHByb2plY3RlZCB0aHJvdWdoXG4gKiAgICAgICAgICAgICAgICAgICAgICBbYDxuZy1jb250ZW50PmBdKGFwaS9jb3JlL25nLWNvbnRlbnQpIG9mIHRoZSBuZXcgY29tcG9uZW50IGluc3RhbmNlLlxuICogQHJldHVybnMgQ29tcG9uZW50UmVmIGluc3RhbmNlIHRoYXQgcmVwcmVzZW50cyBhIGdpdmVuIENvbXBvbmVudC5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVDb21wb25lbnQ8Qz4oY29tcG9uZW50OiBUeXBlPEM+LCBvcHRpb25zOiB7XG4gIGVudmlyb25tZW50SW5qZWN0b3I6IEVudmlyb25tZW50SW5qZWN0b3IsXG4gIGhvc3RFbGVtZW50PzogRWxlbWVudCxcbiAgZWxlbWVudEluamVjdG9yPzogSW5qZWN0b3IsXG4gIHByb2plY3RhYmxlTm9kZXM/OiBOb2RlW11bXSxcbn0pOiBDb21wb25lbnRSZWY8Qz4ge1xuICBuZ0Rldk1vZGUgJiYgYXNzZXJ0Q29tcG9uZW50RGVmKGNvbXBvbmVudCk7XG4gIGNvbnN0IGNvbXBvbmVudERlZiA9IGdldENvbXBvbmVudERlZihjb21wb25lbnQpITtcbiAgY29uc3QgZWxlbWVudEluamVjdG9yID0gb3B0aW9ucy5lbGVtZW50SW5qZWN0b3IgfHwgZ2V0TnVsbEluamVjdG9yKCk7XG4gIGNvbnN0IGZhY3RvcnkgPSBuZXcgQ29tcG9uZW50RmFjdG9yeTxDPihjb21wb25lbnREZWYpO1xuICByZXR1cm4gZmFjdG9yeS5jcmVhdGUoXG4gICAgICBlbGVtZW50SW5qZWN0b3IsIG9wdGlvbnMucHJvamVjdGFibGVOb2Rlcywgb3B0aW9ucy5ob3N0RWxlbWVudCwgb3B0aW9ucy5lbnZpcm9ubWVudEluamVjdG9yKTtcbn1cblxuLyoqXG4gKiBBbiBpbnRlcmZhY2UgdGhhdCBkZXNjcmliZXMgdGhlIHN1YnNldCBvZiBjb21wb25lbnQgbWV0YWRhdGFcbiAqIHRoYXQgY2FuIGJlIHJldHJpZXZlZCB1c2luZyB0aGUgYHJlZmxlY3RDb21wb25lbnRUeXBlYCBmdW5jdGlvbi5cbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgQ29tcG9uZW50TWlycm9yPEM+IHtcbiAgLyoqXG4gICAqIFRoZSBjb21wb25lbnQncyBIVE1MIHNlbGVjdG9yLlxuICAgKi9cbiAgZ2V0IHNlbGVjdG9yKCk6IHN0cmluZztcbiAgLyoqXG4gICAqIFRoZSB0eXBlIG9mIGNvbXBvbmVudCB0aGUgZmFjdG9yeSB3aWxsIGNyZWF0ZS5cbiAgICovXG4gIGdldCB0eXBlKCk6IFR5cGU8Qz47XG4gIC8qKlxuICAgKiBUaGUgaW5wdXRzIG9mIHRoZSBjb21wb25lbnQuXG4gICAqL1xuICBnZXQgaW5wdXRzKCk6IFJlYWRvbmx5QXJyYXk8e3JlYWRvbmx5IHByb3BOYW1lOiBzdHJpbmcsIHJlYWRvbmx5IHRlbXBsYXRlTmFtZTogc3RyaW5nfT47XG4gIC8qKlxuICAgKiBUaGUgb3V0cHV0cyBvZiB0aGUgY29tcG9uZW50LlxuICAgKi9cbiAgZ2V0IG91dHB1dHMoKTogUmVhZG9ubHlBcnJheTx7cmVhZG9ubHkgcHJvcE5hbWU6IHN0cmluZywgcmVhZG9ubHkgdGVtcGxhdGVOYW1lOiBzdHJpbmd9PjtcbiAgLyoqXG4gICAqIFNlbGVjdG9yIGZvciBhbGwgPG5nLWNvbnRlbnQ+IGVsZW1lbnRzIGluIHRoZSBjb21wb25lbnQuXG4gICAqL1xuICBnZXQgbmdDb250ZW50U2VsZWN0b3JzKCk6IFJlYWRvbmx5QXJyYXk8c3RyaW5nPjtcbiAgLyoqXG4gICAqIFdoZXRoZXIgdGhpcyBjb21wb25lbnQgaXMgbWFya2VkIGFzIHN0YW5kYWxvbmUuXG4gICAqIE5vdGU6IGFuIGV4dHJhIGZsYWcsIG5vdCBwcmVzZW50IGluIGBDb21wb25lbnRGYWN0b3J5YC5cbiAgICovXG4gIGdldCBpc1N0YW5kYWxvbmUoKTogYm9vbGVhbjtcbn1cblxuLyoqXG4gKiBDcmVhdGVzIGFuIG9iamVjdCB0aGF0IGFsbG93cyB0byByZXRyaWV2ZSBjb21wb25lbnQgbWV0YWRhdGEuXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqXG4gKiBUaGUgZXhhbXBsZSBiZWxvdyBkZW1vbnN0cmF0ZXMgaG93IHRvIHVzZSB0aGUgZnVuY3Rpb24gYW5kIGhvdyB0aGUgZmllbGRzXG4gKiBvZiB0aGUgcmV0dXJuZWQgb2JqZWN0IG1hcCB0byB0aGUgY29tcG9uZW50IG1ldGFkYXRhLlxuICpcbiAqIGBgYHR5cGVzY3JpcHRcbiAqIEBDb21wb25lbnQoe1xuICogICBzdGFuZGFsb25lOiB0cnVlLFxuICogICBzZWxlY3RvcjogJ2Zvby1jb21wb25lbnQnLFxuICogICB0ZW1wbGF0ZTogYFxuICogICAgIDxuZy1jb250ZW50PjwvbmctY29udGVudD5cbiAqICAgICA8bmctY29udGVudCBzZWxlY3Q9XCJjb250ZW50LXNlbGVjdG9yLWFcIj48L25nLWNvbnRlbnQ+XG4gKiAgIGAsXG4gKiB9KVxuICogY2xhc3MgRm9vQ29tcG9uZW50IHtcbiAqICAgQElucHV0KCdpbnB1dE5hbWUnKSBpbnB1dFByb3BOYW1lOiBzdHJpbmc7XG4gKiAgIEBPdXRwdXQoJ291dHB1dE5hbWUnKSBvdXRwdXRQcm9wTmFtZSA9IG5ldyBFdmVudEVtaXR0ZXI8dm9pZD4oKTtcbiAqIH1cbiAqXG4gKiBjb25zdCBtaXJyb3IgPSByZWZsZWN0Q29tcG9uZW50VHlwZShGb29Db21wb25lbnQpO1xuICogZXhwZWN0KG1pcnJvci50eXBlKS50b0JlKEZvb0NvbXBvbmVudCk7XG4gKiBleHBlY3QobWlycm9yLnNlbGVjdG9yKS50b0JlKCdmb28tY29tcG9uZW50Jyk7XG4gKiBleHBlY3QobWlycm9yLmlzU3RhbmRhbG9uZSkudG9CZSh0cnVlKTtcbiAqIGV4cGVjdChtaXJyb3IuaW5wdXRzKS50b0VxdWFsKFt7cHJvcE5hbWU6ICdpbnB1dE5hbWUnLCB0ZW1wbGF0ZU5hbWU6ICdpbnB1dFByb3BOYW1lJ31dKTtcbiAqIGV4cGVjdChtaXJyb3Iub3V0cHV0cykudG9FcXVhbChbe3Byb3BOYW1lOiAnb3V0cHV0TmFtZScsIHRlbXBsYXRlTmFtZTogJ291dHB1dFByb3BOYW1lJ31dKTtcbiAqIGV4cGVjdChtaXJyb3IubmdDb250ZW50U2VsZWN0b3JzKS50b0VxdWFsKFtcbiAqICAgJyonLCAgICAgICAgICAgICAgICAgLy8gZmlyc3QgYDxuZy1jb250ZW50PmAgaW4gYSB0ZW1wbGF0ZSwgdGhlIHNlbGVjdG9yIGRlZmF1bHRzIHRvIGAqYFxuICogICAnY29udGVudC1zZWxlY3Rvci1hJyAvLyBzZWNvbmQgYDxuZy1jb250ZW50PmAgaW4gYSB0ZW1wbGF0ZVxuICogXSk7XG4gKiBgYGBcbiAqXG4gKiBAcGFyYW0gY29tcG9uZW50IENvbXBvbmVudCBjbGFzcyByZWZlcmVuY2UuXG4gKiBAcmV0dXJucyBBbiBvYmplY3QgdGhhdCBhbGxvd3MgdG8gcmV0cmlldmUgY29tcG9uZW50IG1ldGFkYXRhLlxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHJlZmxlY3RDb21wb25lbnRUeXBlPEM+KGNvbXBvbmVudDogVHlwZTxDPik6IENvbXBvbmVudE1pcnJvcjxDPnxudWxsIHtcbiAgY29uc3QgY29tcG9uZW50RGVmID0gZ2V0Q29tcG9uZW50RGVmKGNvbXBvbmVudCk7XG4gIGlmICghY29tcG9uZW50RGVmKSByZXR1cm4gbnVsbDtcblxuICBjb25zdCBmYWN0b3J5ID0gbmV3IENvbXBvbmVudEZhY3Rvcnk8Qz4oY29tcG9uZW50RGVmKTtcbiAgcmV0dXJuIHtcbiAgICBnZXQgc2VsZWN0b3IoKTogc3RyaW5nIHtcbiAgICAgIHJldHVybiBmYWN0b3J5LnNlbGVjdG9yO1xuICAgIH0sXG4gICAgZ2V0IHR5cGUoKTogVHlwZTxDPiB7XG4gICAgICByZXR1cm4gZmFjdG9yeS5jb21wb25lbnRUeXBlO1xuICAgIH0sXG4gICAgZ2V0IGlucHV0cygpOiBSZWFkb25seUFycmF5PHtwcm9wTmFtZTogc3RyaW5nLCB0ZW1wbGF0ZU5hbWU6IHN0cmluZ30+IHtcbiAgICAgIHJldHVybiBmYWN0b3J5LmlucHV0cztcbiAgICB9LFxuICAgIGdldCBvdXRwdXRzKCk6IFJlYWRvbmx5QXJyYXk8e3Byb3BOYW1lOiBzdHJpbmcsIHRlbXBsYXRlTmFtZTogc3RyaW5nfT4ge1xuICAgICAgcmV0dXJuIGZhY3Rvcnkub3V0cHV0cztcbiAgICB9LFxuICAgIGdldCBuZ0NvbnRlbnRTZWxlY3RvcnMoKTogUmVhZG9ubHlBcnJheTxzdHJpbmc+IHtcbiAgICAgIHJldHVybiBmYWN0b3J5Lm5nQ29udGVudFNlbGVjdG9ycztcbiAgICB9LFxuICAgIGdldCBpc1N0YW5kYWxvbmUoKTogYm9vbGVhbiB7XG4gICAgICByZXR1cm4gY29tcG9uZW50RGVmLnN0YW5kYWxvbmU7XG4gICAgfSxcbiAgfTtcbn1cbiJdfQ==