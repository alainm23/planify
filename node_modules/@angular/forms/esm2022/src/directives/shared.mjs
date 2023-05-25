/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { InjectionToken, ɵRuntimeError as RuntimeError } from '@angular/core';
import { getControlAsyncValidators, getControlValidators, mergeValidators } from '../validators';
import { BuiltInControlValueAccessor } from './control_value_accessor';
import { DefaultValueAccessor } from './default_value_accessor';
import { ngModelWarning } from './reactive_errors';
/**
 * Token to provide to allow SetDisabledState to always be called when a CVA is added, regardless of
 * whether the control is disabled or enabled.
 *
 * @see `FormsModule.withConfig`
 */
export const CALL_SET_DISABLED_STATE = new InjectionToken('CallSetDisabledState', { providedIn: 'root', factory: () => setDisabledStateDefault });
/**
 * Whether to use the fixed setDisabledState behavior by default.
 */
export const setDisabledStateDefault = 'always';
export function controlPath(name, parent) {
    return [...parent.path, name];
}
/**
 * Links a Form control and a Form directive by setting up callbacks (such as `onChange`) on both
 * instances. This function is typically invoked when form directive is being initialized.
 *
 * @param control Form control instance that should be linked.
 * @param dir Directive that should be linked with a given control.
 */
export function setUpControl(control, dir, callSetDisabledState = setDisabledStateDefault) {
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        if (!control)
            _throwError(dir, 'Cannot find control with');
        if (!dir.valueAccessor)
            _throwMissingValueAccessorError(dir);
    }
    setUpValidators(control, dir);
    dir.valueAccessor.writeValue(control.value);
    // The legacy behavior only calls the CVA's `setDisabledState` if the control is disabled.
    // If the `callSetDisabledState` option is set to `always`, then this bug is fixed and
    // the method is always called.
    if (control.disabled || callSetDisabledState === 'always') {
        dir.valueAccessor.setDisabledState?.(control.disabled);
    }
    setUpViewChangePipeline(control, dir);
    setUpModelChangePipeline(control, dir);
    setUpBlurPipeline(control, dir);
    setUpDisabledChangeHandler(control, dir);
}
/**
 * Reverts configuration performed by the `setUpControl` control function.
 * Effectively disconnects form control with a given form directive.
 * This function is typically invoked when corresponding form directive is being destroyed.
 *
 * @param control Form control which should be cleaned up.
 * @param dir Directive that should be disconnected from a given control.
 * @param validateControlPresenceOnChange Flag that indicates whether onChange handler should
 *     contain asserts to verify that it's not called once directive is destroyed. We need this flag
 *     to avoid potentially breaking changes caused by better control cleanup introduced in #39235.
 */
export function cleanUpControl(control, dir, validateControlPresenceOnChange = true) {
    const noop = () => {
        if (validateControlPresenceOnChange && (typeof ngDevMode === 'undefined' || ngDevMode)) {
            _noControlError(dir);
        }
    };
    // The `valueAccessor` field is typically defined on FromControl and FormControlName directive
    // instances and there is a logic in `selectValueAccessor` function that throws if it's not the
    // case. We still check the presence of `valueAccessor` before invoking its methods to make sure
    // that cleanup works correctly if app code or tests are setup to ignore the error thrown from
    // `selectValueAccessor`. See https://github.com/angular/angular/issues/40521.
    if (dir.valueAccessor) {
        dir.valueAccessor.registerOnChange(noop);
        dir.valueAccessor.registerOnTouched(noop);
    }
    cleanUpValidators(control, dir);
    if (control) {
        dir._invokeOnDestroyCallbacks();
        control._registerOnCollectionChange(() => { });
    }
}
function registerOnValidatorChange(validators, onChange) {
    validators.forEach((validator) => {
        if (validator.registerOnValidatorChange)
            validator.registerOnValidatorChange(onChange);
    });
}
/**
 * Sets up disabled change handler function on a given form control if ControlValueAccessor
 * associated with a given directive instance supports the `setDisabledState` call.
 *
 * @param control Form control where disabled change handler should be setup.
 * @param dir Corresponding directive instance associated with this control.
 */
export function setUpDisabledChangeHandler(control, dir) {
    if (dir.valueAccessor.setDisabledState) {
        const onDisabledChange = (isDisabled) => {
            dir.valueAccessor.setDisabledState(isDisabled);
        };
        control.registerOnDisabledChange(onDisabledChange);
        // Register a callback function to cleanup disabled change handler
        // from a control instance when a directive is destroyed.
        dir._registerOnDestroy(() => {
            control._unregisterOnDisabledChange(onDisabledChange);
        });
    }
}
/**
 * Sets up sync and async directive validators on provided form control.
 * This function merges validators from the directive into the validators of the control.
 *
 * @param control Form control where directive validators should be setup.
 * @param dir Directive instance that contains validators to be setup.
 */
export function setUpValidators(control, dir) {
    const validators = getControlValidators(control);
    if (dir.validator !== null) {
        control.setValidators(mergeValidators(validators, dir.validator));
    }
    else if (typeof validators === 'function') {
        // If sync validators are represented by a single validator function, we force the
        // `Validators.compose` call to happen by executing the `setValidators` function with
        // an array that contains that function. We need this to avoid possible discrepancies in
        // validators behavior, so sync validators are always processed by the `Validators.compose`.
        // Note: we should consider moving this logic inside the `setValidators` function itself, so we
        // have consistent behavior on AbstractControl API level. The same applies to the async
        // validators logic below.
        control.setValidators([validators]);
    }
    const asyncValidators = getControlAsyncValidators(control);
    if (dir.asyncValidator !== null) {
        control.setAsyncValidators(mergeValidators(asyncValidators, dir.asyncValidator));
    }
    else if (typeof asyncValidators === 'function') {
        control.setAsyncValidators([asyncValidators]);
    }
    // Re-run validation when validator binding changes, e.g. minlength=3 -> minlength=4
    const onValidatorChange = () => control.updateValueAndValidity();
    registerOnValidatorChange(dir._rawValidators, onValidatorChange);
    registerOnValidatorChange(dir._rawAsyncValidators, onValidatorChange);
}
/**
 * Cleans up sync and async directive validators on provided form control.
 * This function reverts the setup performed by the `setUpValidators` function, i.e.
 * removes directive-specific validators from a given control instance.
 *
 * @param control Form control from where directive validators should be removed.
 * @param dir Directive instance that contains validators to be removed.
 * @returns true if a control was updated as a result of this action.
 */
export function cleanUpValidators(control, dir) {
    let isControlUpdated = false;
    if (control !== null) {
        if (dir.validator !== null) {
            const validators = getControlValidators(control);
            if (Array.isArray(validators) && validators.length > 0) {
                // Filter out directive validator function.
                const updatedValidators = validators.filter((validator) => validator !== dir.validator);
                if (updatedValidators.length !== validators.length) {
                    isControlUpdated = true;
                    control.setValidators(updatedValidators);
                }
            }
        }
        if (dir.asyncValidator !== null) {
            const asyncValidators = getControlAsyncValidators(control);
            if (Array.isArray(asyncValidators) && asyncValidators.length > 0) {
                // Filter out directive async validator function.
                const updatedAsyncValidators = asyncValidators.filter((asyncValidator) => asyncValidator !== dir.asyncValidator);
                if (updatedAsyncValidators.length !== asyncValidators.length) {
                    isControlUpdated = true;
                    control.setAsyncValidators(updatedAsyncValidators);
                }
            }
        }
    }
    // Clear onValidatorChange callbacks by providing a noop function.
    const noop = () => { };
    registerOnValidatorChange(dir._rawValidators, noop);
    registerOnValidatorChange(dir._rawAsyncValidators, noop);
    return isControlUpdated;
}
function setUpViewChangePipeline(control, dir) {
    dir.valueAccessor.registerOnChange((newValue) => {
        control._pendingValue = newValue;
        control._pendingChange = true;
        control._pendingDirty = true;
        if (control.updateOn === 'change')
            updateControl(control, dir);
    });
}
function setUpBlurPipeline(control, dir) {
    dir.valueAccessor.registerOnTouched(() => {
        control._pendingTouched = true;
        if (control.updateOn === 'blur' && control._pendingChange)
            updateControl(control, dir);
        if (control.updateOn !== 'submit')
            control.markAsTouched();
    });
}
function updateControl(control, dir) {
    if (control._pendingDirty)
        control.markAsDirty();
    control.setValue(control._pendingValue, { emitModelToViewChange: false });
    dir.viewToModelUpdate(control._pendingValue);
    control._pendingChange = false;
}
function setUpModelChangePipeline(control, dir) {
    const onChange = (newValue, emitModelEvent) => {
        // control -> view
        dir.valueAccessor.writeValue(newValue);
        // control -> ngModel
        if (emitModelEvent)
            dir.viewToModelUpdate(newValue);
    };
    control.registerOnChange(onChange);
    // Register a callback function to cleanup onChange handler
    // from a control instance when a directive is destroyed.
    dir._registerOnDestroy(() => {
        control._unregisterOnChange(onChange);
    });
}
/**
 * Links a FormGroup or FormArray instance and corresponding Form directive by setting up validators
 * present in the view.
 *
 * @param control FormGroup or FormArray instance that should be linked.
 * @param dir Directive that provides view validators.
 */
export function setUpFormContainer(control, dir) {
    if (control == null && (typeof ngDevMode === 'undefined' || ngDevMode))
        _throwError(dir, 'Cannot find control with');
    setUpValidators(control, dir);
}
/**
 * Reverts the setup performed by the `setUpFormContainer` function.
 *
 * @param control FormGroup or FormArray instance that should be cleaned up.
 * @param dir Directive that provided view validators.
 * @returns true if a control was updated as a result of this action.
 */
export function cleanUpFormContainer(control, dir) {
    return cleanUpValidators(control, dir);
}
function _noControlError(dir) {
    return _throwError(dir, 'There is no FormControl instance attached to form control element with');
}
function _throwError(dir, message) {
    const messageEnd = _describeControlLocation(dir);
    throw new Error(`${message} ${messageEnd}`);
}
function _describeControlLocation(dir) {
    const path = dir.path;
    if (path && path.length > 1)
        return `path: '${path.join(' -> ')}'`;
    if (path?.[0])
        return `name: '${path}'`;
    return 'unspecified name attribute';
}
function _throwMissingValueAccessorError(dir) {
    const loc = _describeControlLocation(dir);
    throw new RuntimeError(-1203 /* RuntimeErrorCode.NG_MISSING_VALUE_ACCESSOR */, `No value accessor for form control ${loc}.`);
}
function _throwInvalidValueAccessorError(dir) {
    const loc = _describeControlLocation(dir);
    throw new RuntimeError(1200 /* RuntimeErrorCode.NG_VALUE_ACCESSOR_NOT_PROVIDED */, `Value accessor was not provided as an array for form control with ${loc}. ` +
        `Check that the \`NG_VALUE_ACCESSOR\` token is configured as a \`multi: true\` provider.`);
}
export function isPropertyUpdated(changes, viewModel) {
    if (!changes.hasOwnProperty('model'))
        return false;
    const change = changes['model'];
    if (change.isFirstChange())
        return true;
    return !Object.is(viewModel, change.currentValue);
}
export function isBuiltInAccessor(valueAccessor) {
    // Check if a given value accessor is an instance of a class that directly extends
    // `BuiltInControlValueAccessor` one.
    return Object.getPrototypeOf(valueAccessor.constructor) === BuiltInControlValueAccessor;
}
export function syncPendingControls(form, directives) {
    form._syncPendingControls();
    directives.forEach((dir) => {
        const control = dir.control;
        if (control.updateOn === 'submit' && control._pendingChange) {
            dir.viewToModelUpdate(control._pendingValue);
            control._pendingChange = false;
        }
    });
}
// TODO: vsavkin remove it once https://github.com/angular/angular/issues/3011 is implemented
export function selectValueAccessor(dir, valueAccessors) {
    if (!valueAccessors)
        return null;
    if (!Array.isArray(valueAccessors) && (typeof ngDevMode === 'undefined' || ngDevMode))
        _throwInvalidValueAccessorError(dir);
    let defaultAccessor = undefined;
    let builtinAccessor = undefined;
    let customAccessor = undefined;
    valueAccessors.forEach((v) => {
        if (v.constructor === DefaultValueAccessor) {
            defaultAccessor = v;
        }
        else if (isBuiltInAccessor(v)) {
            if (builtinAccessor && (typeof ngDevMode === 'undefined' || ngDevMode))
                _throwError(dir, 'More than one built-in value accessor matches form control with');
            builtinAccessor = v;
        }
        else {
            if (customAccessor && (typeof ngDevMode === 'undefined' || ngDevMode))
                _throwError(dir, 'More than one custom value accessor matches form control with');
            customAccessor = v;
        }
    });
    if (customAccessor)
        return customAccessor;
    if (builtinAccessor)
        return builtinAccessor;
    if (defaultAccessor)
        return defaultAccessor;
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        _throwError(dir, 'No valid value accessor for form control with');
    }
    return null;
}
export function removeListItem(list, el) {
    const index = list.indexOf(el);
    if (index > -1)
        list.splice(index, 1);
}
// TODO(kara): remove after deprecation period
export function _ngModelWarning(name, type, instance, warningConfig) {
    if (warningConfig === 'never')
        return;
    if (((warningConfig === null || warningConfig === 'once') && !type._ngModelWarningSentOnce) ||
        (warningConfig === 'always' && !instance._ngModelWarningSent)) {
        console.warn(ngModelWarning(name));
        type._ngModelWarningSentOnce = true;
        instance._ngModelWarningSent = true;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic2hhcmVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvZm9ybXMvc3JjL2RpcmVjdGl2ZXMvc2hhcmVkLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUVILE9BQU8sRUFBUyxjQUFjLEVBQUUsYUFBYSxJQUFJLFlBQVksRUFBQyxNQUFNLGVBQWUsQ0FBQztBQU9wRixPQUFPLEVBQUMseUJBQXlCLEVBQUUsb0JBQW9CLEVBQUUsZUFBZSxFQUFDLE1BQU0sZUFBZSxDQUFDO0FBSy9GLE9BQU8sRUFBQywyQkFBMkIsRUFBdUIsTUFBTSwwQkFBMEIsQ0FBQztBQUMzRixPQUFPLEVBQUMsb0JBQW9CLEVBQUMsTUFBTSwwQkFBMEIsQ0FBQztBQUc5RCxPQUFPLEVBQUMsY0FBYyxFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFHakQ7Ozs7O0dBS0c7QUFDSCxNQUFNLENBQUMsTUFBTSx1QkFBdUIsR0FBRyxJQUFJLGNBQWMsQ0FDckQsc0JBQXNCLEVBQUUsRUFBQyxVQUFVLEVBQUUsTUFBTSxFQUFFLE9BQU8sRUFBRSxHQUFHLEVBQUUsQ0FBQyx1QkFBdUIsRUFBQyxDQUFDLENBQUM7QUFZMUY7O0dBRUc7QUFDSCxNQUFNLENBQUMsTUFBTSx1QkFBdUIsR0FBMkIsUUFBUSxDQUFDO0FBRXhFLE1BQU0sVUFBVSxXQUFXLENBQUMsSUFBaUIsRUFBRSxNQUF3QjtJQUNyRSxPQUFPLENBQUMsR0FBRyxNQUFNLENBQUMsSUFBSyxFQUFFLElBQUssQ0FBQyxDQUFDO0FBQ2xDLENBQUM7QUFFRDs7Ozs7O0dBTUc7QUFDSCxNQUFNLFVBQVUsWUFBWSxDQUN4QixPQUFvQixFQUFFLEdBQWMsRUFDcEMsdUJBQStDLHVCQUF1QjtJQUN4RSxJQUFJLE9BQU8sU0FBUyxLQUFLLFdBQVcsSUFBSSxTQUFTLEVBQUU7UUFDakQsSUFBSSxDQUFDLE9BQU87WUFBRSxXQUFXLENBQUMsR0FBRyxFQUFF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QUNoRCxNQUFNLEtBQUssR0FBRyxJQUFJLENBQUMsT0FBTyxDQUFDLEVBQUUsQ0FBQyxDQUFDO0lBQy9CLElBQUksS0FBSyxHQUFHLENBQUMsQ0FBQztRQUFFLElBQUksQ0FBQyxNQUFNLENBQUMsS0FBSyxFQUFFLENBQUMsQ0FBQyxDQUFDO0FBQ3hDLENBQUM7QUFFRCw4Q0FBOEM7QUFDOUMsTUFBTSxVQUFVLGVBQWUsQ0FDM0IsSUFBWSxFQUFFLElBQXdDLEVBQ3RELFFBQXdDLEVBQUUsYUFBMEI7SUFDdEUsSUFBSSxhQUFhLEtBQUssT0FBTztRQUFFLE9BQU87SUFFdEMsSUFBSSxDQUFDLENBQUMsYUFBYSxLQUFLLElBQUksSUFBSSxhQUFhLEtBQUssTUFBTSxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsdUJBQXVCLENBQUM7UUFDdkYsQ0FBQyxhQUFhLEtBQUssUUFBUSxJQUFJLENBQUMsUUFBUSxDQUFDLG1CQUFtQixDQUFDLEVBQUU7UUFDakUsT0FBTyxDQUFDLElBQUksQ0FBQyxjQUFjLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQztRQUNuQyxJQUFJLENBQUMsdUJBQXVCLEdBQUcsSUFBSSxDQUFDO1FBQ3BDLFFBQVEsQ0FBQyxtQkFBbUIsR0FBRyxJQUFJLENBQUM7S0FDckM7QUFDSCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7SW5qZWN0LCBJbmplY3Rpb25Ub2tlbiwgybVSdW50aW1lRXJyb3IgYXMgUnVudGltZUVycm9yfSBmcm9tICdAYW5ndWxhci9jb3JlJztcblxuaW1wb3J0IHtSdW50aW1lRXJyb3JDb2RlfSBmcm9tICcuLi9lcnJvcnMnO1xuaW1wb3J0IHtBYnN0cmFjdENvbnRyb2x9IGZyb20gJy4uL21vZGVsL2Fic3RyYWN0X21vZGVsJztcbmltcG9ydCB7Rm9ybUFycmF5fSBmcm9tICcuLi9tb2RlbC9mb3JtX2FycmF5JztcbmltcG9ydCB7Rm9ybUNvbnRyb2x9IGZyb20gJy4uL21vZGVsL2Zvcm1fY29udHJvbCc7XG5pbXBvcnQge0Zvcm1Hcm91cH0gZnJvbSAnLi4vbW9kZWwvZm9ybV9ncm91cCc7XG5pbXBvcnQge2dldENvbnRyb2xBc3luY1ZhbGlkYXRvcnMsIGdldENvbnRyb2xWYWxpZGF0b3JzLCBtZXJnZVZhbGlkYXRvcnN9IGZyb20gJy4uL3ZhbGlkYXRvcnMnO1xuXG5pbXBvcnQge0Fic3RyYWN0Q29udHJvbERpcmVjdGl2ZX0gZnJvbSAnLi9hYnN0cmFjdF9jb250cm9sX2RpcmVjdGl2ZSc7XG5pbXBvcnQge0Fic3RyYWN0Rm9ybUdyb3VwRGlyZWN0aXZlfSBmcm9tICcuL2Fic3RyYWN0X2Zvcm1fZ3JvdXBfZGlyZWN0aXZlJztcbmltcG9ydCB7Q29udHJvbENvbnRhaW5lcn0gZnJvbSAnLi9jb250cm9sX2NvbnRhaW5lcic7XG5pbXBvcnQge0J1aWx0SW5Db250cm9sVmFsdWVBY2Nlc3NvciwgQ29udHJvbFZhbHVlQWNjZXNzb3J9IGZyb20gJy4vY29udHJvbF92YWx1ZV9hY2Nlc3Nvcic7XG5pbXBvcnQge0RlZmF1bHRWYWx1ZUFjY2Vzc29yfSBmcm9tICcuL2RlZmF1bHRfdmFsdWVfYWNjZXNzb3InO1xuaW1wb3J0IHtOZ0NvbnRyb2x9IGZyb20gJy4vbmdfY29udHJvbCc7XG5pbXBvcnQge0Zvcm1BcnJheU5hbWV9IGZyb20gJy4vcmVhY3RpdmVfZGlyZWN0aXZlcy9mb3JtX2dyb3VwX25hbWUnO1xuaW1wb3J0IHtuZ01vZGVsV2FybmluZ30gZnJvbSAnLi9yZWFjdGl2ZV9lcnJvcnMnO1xuaW1wb3J0IHtBc3luY1ZhbGlkYXRvckZuLCBWYWxpZGF0b3IsIFZhbGlkYXRvckZufSBmcm9tICcuL3ZhbGlkYXRvcnMnO1xuXG4vKipcbiAqIFRva2VuIHRvIHByb3ZpZGUgdG8gYWxsb3cgU2V0RGlzYWJsZWRTdGF0ZSB0byBhbHdheXMgYmUgY2FsbGVkIHdoZW4gYSBDVkEgaXMgYWRkZWQsIHJlZ2FyZGxlc3Mgb2ZcbiAqIHdoZXRoZXIgdGhlIGNvbnRyb2wgaXMgZGlzYWJsZWQgb3IgZW5hYmxlZC5cbiAqXG4gKiBAc2VlIGBGb3Jtc01vZHVsZS53aXRoQ29uZmlnYFxuICovXG5leHBvcnQgY29uc3QgQ0FMTF9TRVRfRElTQUJMRURfU1RBVEUgPSBuZXcgSW5qZWN0aW9uVG9rZW4oXG4gICAgJ0NhbGxTZXREaXNhYmxlZFN0YXRlJywge3Byb3ZpZGVkSW46ICdyb290JywgZmFjdG9yeTogKCkgPT4gc2V0RGlzYWJsZWRTdGF0ZURlZmF1bHR9KTtcblxuLyoqXG4gKiBUaGUgdHlwZSBmb3IgQ0FMTF9TRVRfRElTQUJMRURfU1RBVEUuIElmIGBhbHdheXNgLCB0aGVuIENvbnRyb2xWYWx1ZUFjY2Vzc29yIHdpbGwgYWx3YXlzIGNhbGxcbiAqIGBzZXREaXNhYmxlZFN0YXRlYCB3aGVuIGF0dGFjaGVkLCB3aGljaCBpcyB0aGUgbW9zdCBjb3JyZWN0IGJlaGF2aW9yLiBPdGhlcndpc2UsIGl0IHdpbGwgb25seSBiZVxuICogY2FsbGVkIHdoZW4gZGlzYWJsZWQsIHdoaWNoIGlzIHRoZSBsZWdhY3kgYmVoYXZpb3IgZm9yIGNvbXBhdGliaWxpdHkuXG4gKlxuICogQHB1YmxpY0FwaVxuICogQHNlZSBgRm9ybXNNb2R1bGUud2l0aENvbmZpZ2BcbiAqL1xuZXhwb3J0IHR5cGUgU2V0RGlzYWJsZWRTdGF0ZU9wdGlvbiA9ICd3aGVuRGlzYWJsZWRGb3JMZWdhY3lDb2RlJ3wnYWx3YXlzJztcblxuLyoqXG4gKiBXaGV0aGVyIHRvIHVzZSB0aGUgZml4ZWQgc2V0RGlzYWJsZWRTdGF0ZSBiZWhhdmlvciBieSBkZWZhdWx0LlxuICovXG5leHBvcnQgY29uc3Qgc2V0RGlzYWJsZWRTdGF0ZURlZmF1bHQ6IFNldERpc2FibGVkU3RhdGVPcHRpb24gPSAnYWx3YXlzJztcblxuZXhwb3J0IGZ1bmN0aW9uIGNvbnRyb2xQYXRoKG5hbWU6IHN0cmluZ3xudWxsLCBwYXJlbnQ6IENvbnRyb2xDb250YWluZXIpOiBzdHJpbmdbXSB7XG4gIHJldHVybiBbLi4ucGFyZW50LnBhdGghLCBuYW1lIV07XG59XG5cbi8qKlxuICogTGlua3MgYSBGb3JtIGNvbnRyb2wgYW5kIGEgRm9ybSBkaXJlY3RpdmUgYnkgc2V0dGluZyB1cCBjYWxsYmFja3MgKHN1Y2ggYXMgYG9uQ2hhbmdlYCkgb24gYm90aFxuICogaW5zdGFuY2VzLiBUaGlzIGZ1bmN0aW9uIGlzIHR5cGljYWxseSBpbnZva2VkIHdoZW4gZm9ybSBkaXJlY3RpdmUgaXMgYmVpbmcgaW5pdGlhbGl6ZWQuXG4gKlxuICogQHBhcmFtIGNvbnRyb2wgRm9ybSBjb250cm9sIGluc3RhbmNlIHRoYXQgc2hvdWxkIGJlIGxpbmtlZC5cbiAqIEBwYXJhbSBkaXIgRGlyZWN0aXZlIHRoYXQgc2hvdWxkIGJlIGxpbmtlZCB3aXRoIGEgZ2l2ZW4gY29udHJvbC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldFVwQ29udHJvbChcbiAgICBjb250cm9sOiBGb3JtQ29udHJvbCwgZGlyOiBOZ0NvbnRyb2wsXG4gICAgY2FsbFNldERpc2FibGVkU3RhdGU6IFNldERpc2FibGVkU3RhdGVPcHRpb24gPSBzZXREaXNhYmxlZFN0YXRlRGVmYXVsdCk6IHZvaWQge1xuICBpZiAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSB7XG4gICAgaWYgKCFjb250cm9sKSBfdGhyb3dFcnJvcihkaXIsICdDYW5ub3QgZmluZCBjb250cm9sIHdpdGgnKTtcbiAgICBpZiAoIWRpci52YWx1ZUFjY2Vzc29yKSBfdGhyb3dNaXNzaW5nVmFsdWVBY2Nlc3NvckVycm9yKGRpcik7XG4gIH1cblxuICBzZXRVcFZhbGlkYXRvcnMoY29udHJvbCwgZGlyKTtcblxuICBkaXIudmFsdWVBY2Nlc3NvciEud3JpdGVWYWx1ZShjb250cm9sLnZhbHVlKTtcblxuICAvLyBUaGUgbGVnYWN5IGJlaGF2aW9yIG9ubHkgY2FsbHMgdGhlIENWQSdzIGBzZXREaXNhYmxlZFN0YXRlYCBpZiB0aGUgY29udHJvbCBpcyBkaXNhYmxlZC5cbiAgLy8gSWYgdGhlIGBjYWxsU2V0RGlzYWJsZWRTdGF0ZWAgb3B0aW9uIGlzIHNldCB0byBgYWx3YXlzYCwgdGhlbiB0aGlzIGJ1ZyBpcyBmaXhlZCBhbmRcbiAgLy8gdGhlIG1ldGhvZCBpcyBhbHdheXMgY2FsbGVkLlxuICBpZiAoY29udHJvbC5kaXNhYmxlZCB8fCBjYWxsU2V0RGlzYWJsZWRTdGF0ZSA9PT0gJ2Fsd2F5cycpIHtcbiAgICBkaXIudmFsdWVBY2Nlc3NvciEuc2V0RGlzYWJsZWRTdGF0ZT8uKGNvbnRyb2wuZGlzYWJsZWQpO1xuICB9XG5cbiAgc2V0VXBWaWV3Q2hhbmdlUGlwZWxpbmUoY29udHJvbCwgZGlyKTtcbiAgc2V0VXBNb2RlbENoYW5nZVBpcGVsaW5lKGNvbnRyb2wsIGRpcik7XG5cbiAgc2V0VXBCbHVyUGlwZWxpbmUoY29udHJvbCwgZGlyKTtcblxuICBzZXRVcERpc2FibGVkQ2hhbmdlSGFuZGxlcihjb250cm9sLCBkaXIpO1xufVxuXG4vKipcbiAqIFJldmVydHMgY29uZmlndXJhdGlvbiBwZXJmb3JtZWQgYnkgdGhlIGBzZXRVcENvbnRyb2xgIGNvbnRyb2wgZnVuY3Rpb24uXG4gKiBFZmZlY3RpdmVseSBkaXNjb25uZWN0cyBmb3JtIGNvbnRyb2wgd2l0aCBhIGdpdmVuIGZvcm0gZGlyZWN0aXZlLlxuICogVGhpcyBmdW5jdGlvbiBpcyB0eXBpY2FsbHkgaW52b2tlZCB3aGVuIGNvcnJlc3BvbmRpbmcgZm9ybSBkaXJlY3RpdmUgaXMgYmVpbmcgZGVzdHJveWVkLlxuICpcbiAqIEBwYXJhbSBjb250cm9sIEZvcm0gY29udHJvbCB3aGljaCBzaG91bGQgYmUgY2xlYW5lZCB1cC5cbiAqIEBwYXJhbSBkaXIgRGlyZWN0aXZlIHRoYXQgc2hvdWxkIGJlIGRpc2Nvbm5lY3RlZCBmcm9tIGEgZ2l2ZW4gY29udHJvbC5cbiAqIEBwYXJhbSB2YWxpZGF0ZUNvbnRyb2xQcmVzZW5jZU9uQ2hhbmdlIEZsYWcgdGhhdCBpbmRpY2F0ZXMgd2hldGhlciBvbkNoYW5nZSBoYW5kbGVyIHNob3VsZFxuICogICAgIGNvbnRhaW4gYXNzZXJ0cyB0byB2ZXJpZnkgdGhhdCBpdCdzIG5vdCBjYWxsZWQgb25jZSBkaXJlY3RpdmUgaXMgZGVzdHJveWVkLiBXZSBuZWVkIHRoaXMgZmxhZ1xuICogICAgIHRvIGF2b2lkIHBvdGVudGlhbGx5IGJyZWFraW5nIGNoYW5nZXMgY2F1c2VkIGJ5IGJldHRlciBjb250cm9sIGNsZWFudXAgaW50cm9kdWNlZCBpbiAjMzkyMzUuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjbGVhblVwQ29udHJvbChcbiAgICBjb250cm9sOiBGb3JtQ29udHJvbHxudWxsLCBkaXI6IE5nQ29udHJvbCxcbiAgICB2YWxpZGF0ZUNvbnRyb2xQcmVzZW5jZU9uQ2hhbmdlOiBib29sZWFuID0gdHJ1ZSk6IHZvaWQge1xuICBjb25zdCBub29wID0gKCkgPT4ge1xuICAgIGlmICh2YWxpZGF0ZUNvbnRyb2xQcmVzZW5jZU9uQ2hhbmdlICYmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpKSB7XG4gICAgICBfbm9Db250cm9sRXJyb3IoZGlyKTtcbiAgICB9XG4gIH07XG5cbiAgLy8gVGhlIGB2YWx1ZUFjY2Vzc29yYCBmaWVsZCBpcyB0eXBpY2FsbHkgZGVmaW5lZCBvbiBGcm9tQ29udHJvbCBhbmQgRm9ybUNvbnRyb2xOYW1lIGRpcmVjdGl2ZVxuICAvLyBpbnN0YW5jZXMgYW5kIHRoZXJlIGlzIGEgbG9naWMgaW4gYHNlbGVjdFZhbHVlQWNjZXNzb3JgIGZ1bmN0aW9uIHRoYXQgdGhyb3dzIGlmIGl0J3Mgbm90IHRoZVxuICAvLyBjYXNlLiBXZSBzdGlsbCBjaGVjayB0aGUgcHJlc2VuY2Ugb2YgYHZhbHVlQWNjZXNzb3JgIGJlZm9yZSBpbnZva2luZyBpdHMgbWV0aG9kcyB0byBtYWtlIHN1cmVcbiAgLy8gdGhhdCBjbGVhbnVwIHdvcmtzIGNvcnJlY3RseSBpZiBhcHAgY29kZSBvciB0ZXN0cyBhcmUgc2V0dXAgdG8gaWdub3JlIHRoZSBlcnJvciB0aHJvd24gZnJvbVxuICAvLyBgc2VsZWN0VmFsdWVBY2Nlc3NvcmAuIFNlZSBodHRwczovL2dpdGh1Yi5jb20vYW5ndWxhci9hbmd1bGFyL2lzc3Vlcy80MDUyMS5cbiAgaWYgKGRpci52YWx1ZUFjY2Vzc29yKSB7XG4gICAgZGlyLnZhbHVlQWNjZXNzb3IucmVnaXN0ZXJPbkNoYW5nZShub29wKTtcbiAgICBkaXIudmFsdWVBY2Nlc3Nvci5yZWdpc3Rlck9uVG91Y2hlZChub29wKTtcbiAgfVxuXG4gIGNsZWFuVXBWYWxpZGF0b3JzKGNvbnRyb2wsIGRpcik7XG5cbiAgaWYgKGNvbnRyb2wpIHtcbiAgICBkaXIuX2ludm9rZU9uRGVzdHJveUNhbGxiYWNrcygpO1xuICAgIGNvbnRyb2wuX3JlZ2lzdGVyT25Db2xsZWN0aW9uQ2hhbmdlKCgpID0+IHt9KTtcbiAgfVxufVxuXG5mdW5jdGlvbiByZWdpc3Rlck9uVmFsaWRhdG9yQ2hhbmdlPFY+KHZhbGlkYXRvcnM6IChWfFZhbGlkYXRvcilbXSwgb25DaGFuZ2U6ICgpID0+IHZvaWQpOiB2b2lkIHtcbiAgdmFsaWRhdG9ycy5mb3JFYWNoKCh2YWxpZGF0b3I6IFZ8VmFsaWRhdG9yKSA9PiB7XG4gICAgaWYgKCg8VmFsaWRhdG9yPnZhbGlkYXRvcikucmVnaXN0ZXJPblZhbGlkYXRvckNoYW5nZSlcbiAgICAgICg8VmFsaWRhdG9yPnZhbGlkYXRvcikucmVnaXN0ZXJPblZhbGlkYXRvckNoYW5nZSEob25DaGFuZ2UpO1xuICB9KTtcbn1cblxuLyoqXG4gKiBTZXRzIHVwIGRpc2FibGVkIGNoYW5nZSBoYW5kbGVyIGZ1bmN0aW9uIG9uIGEgZ2l2ZW4gZm9ybSBjb250cm9sIGlmIENvbnRyb2xWYWx1ZUFjY2Vzc29yXG4gKiBhc3NvY2lhdGVkIHdpdGggYSBnaXZlbiBkaXJlY3RpdmUgaW5zdGFuY2Ugc3VwcG9ydHMgdGhlIGBzZXREaXNhYmxlZFN0YXRlYCBjYWxsLlxuICpcbiAqIEBwYXJhbSBjb250cm9sIEZvcm0gY29udHJvbCB3aGVyZSBkaXNhYmxlZCBjaGFuZ2UgaGFuZGxlciBzaG91bGQgYmUgc2V0dXAuXG4gKiBAcGFyYW0gZGlyIENvcnJlc3BvbmRpbmcgZGlyZWN0aXZlIGluc3RhbmNlIGFzc29jaWF0ZWQgd2l0aCB0aGlzIGNvbnRyb2wuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBzZXRVcERpc2FibGVkQ2hhbmdlSGFuZGxlcihjb250cm9sOiBGb3JtQ29udHJvbCwgZGlyOiBOZ0NvbnRyb2wpOiB2b2lkIHtcbiAgaWYgKGRpci52YWx1ZUFjY2Vzc29yIS5zZXREaXNhYmxlZFN0YXRlKSB7XG4gICAgY29uc3Qgb25EaXNhYmxlZENoYW5nZSA9IChpc0Rpc2FibGVkOiBib29sZWFuKSA9PiB7XG4gICAgICBkaXIudmFsdWVBY2Nlc3NvciEuc2V0RGlzYWJsZWRTdGF0ZSEoaXNEaXNhYmxlZCk7XG4gICAgfTtcbiAgICBjb250cm9sLnJlZ2lzdGVyT25EaXNhYmxlZENoYW5nZShvbkRpc2FibGVkQ2hhbmdlKTtcblxuICAgIC8vIFJlZ2lzdGVyIGEgY2FsbGJhY2sgZnVuY3Rpb24gdG8gY2xlYW51cCBkaXNhYmxlZCBjaGFuZ2UgaGFuZGxlclxuICAgIC8vIGZyb20gYSBjb250cm9sIGluc3RhbmNlIHdoZW4gYSBkaXJlY3RpdmUgaXMgZGVzdHJveWVkLlxuICAgIGRpci5fcmVnaXN0ZXJPbkRlc3Ryb3koKCkgPT4ge1xuICAgICAgY29udHJvbC5fdW5yZWdpc3Rlck9uRGlzYWJsZWRDaGFuZ2Uob25EaXNhYmxlZENoYW5nZSk7XG4gICAgfSk7XG4gIH1cbn1cblxuLyoqXG4gKiBTZXRzIHVwIHN5bmMgYW5kIGFzeW5jIGRpcmVjdGl2ZSB2YWxpZGF0b3JzIG9uIHByb3ZpZGVkIGZvcm0gY29udHJvbC5cbiAqIFRoaXMgZnVuY3Rpb24gbWVyZ2VzIHZhbGlkYXRvcnMgZnJvbSB0aGUgZGlyZWN0aXZlIGludG8gdGhlIHZhbGlkYXRvcnMgb2YgdGhlIGNvbnRyb2wuXG4gKlxuICogQHBhcmFtIGNvbnRyb2wgRm9ybSBjb250cm9sIHdoZXJlIGRpcmVjdGl2ZSB2YWxpZGF0b3JzIHNob3VsZCBiZSBzZXR1cC5cbiAqIEBwYXJhbSBkaXIgRGlyZWN0aXZlIGluc3RhbmNlIHRoYXQgY29udGFpbnMgdmFsaWRhdG9ycyB0byBiZSBzZXR1cC5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHNldFVwVmFsaWRhdG9ycyhjb250cm9sOiBBYnN0cmFjdENvbnRyb2wsIGRpcjogQWJzdHJhY3RDb250cm9sRGlyZWN0aXZlKTogdm9pZCB7XG4gIGNvbnN0IHZhbGlkYXRvcnMgPSBnZXRDb250cm9sVmFsaWRhdG9ycyhjb250cm9sKTtcbiAgaWYgKGRpci52YWxpZGF0b3IgIT09IG51bGwpIHtcbiAgICBjb250cm9sLnNldFZhbGlkYXRvcnMobWVyZ2VWYWxpZGF0b3JzPFZhbGlkYXRvckZuPih2YWxpZGF0b3JzLCBkaXIudmFsaWRhdG9yKSk7XG4gIH0gZWxzZSBpZiAodHlwZW9mIHZhbGlkYXRvcnMgPT09ICdmdW5jdGlvbicpIHtcbiAgICAvLyBJZiBzeW5jIHZhbGlkYXRvcnMgYXJlIHJlcHJlc2VudGVkIGJ5IGEgc2luZ2xlIHZhbGlkYXRvciBmdW5jdGlvbiwgd2UgZm9yY2UgdGhlXG4gICAgLy8gYFZhbGlkYXRvcnMuY29tcG9zZWAgY2FsbCB0byBoYXBwZW4gYnkgZXhlY3V0aW5nIHRoZSBgc2V0VmFsaWRhdG9yc2AgZnVuY3Rpb24gd2l0aFxuICAgIC8vIGFuIGFycmF5IHRoYXQgY29udGFpbnMgdGhhdCBmdW5jdGlvbi4gV2UgbmVlZCB0aGlzIHRvIGF2b2lkIHBvc3NpYmxlIGRpc2NyZXBhbmNpZXMgaW5cbiAgICAvLyB2YWxpZGF0b3JzIGJlaGF2aW9yLCBzbyBzeW5jIHZhbGlkYXRvcnMgYXJlIGFsd2F5cyBwcm9jZXNzZWQgYnkgdGhlIGBWYWxpZGF0b3JzLmNvbXBvc2VgLlxuICAgIC8vIE5vdGU6IHdlIHNob3VsZCBjb25zaWRlciBtb3ZpbmcgdGhpcyBsb2dpYyBpbnNpZGUgdGhlIGBzZXRWYWxpZGF0b3JzYCBmdW5jdGlvbiBpdHNlbGYsIHNvIHdlXG4gICAgLy8gaGF2ZSBjb25zaXN0ZW50IGJlaGF2aW9yIG9uIEFic3RyYWN0Q29udHJvbCBBUEkgbGV2ZWwuIFRoZSBzYW1lIGFwcGxpZXMgdG8gdGhlIGFzeW5jXG4gICAgLy8gdmFsaWRhdG9ycyBsb2dpYyBiZWxvdy5cbiAgICBjb250cm9sLnNldFZhbGlkYXRvcnMoW3ZhbGlkYXRvcnNdKTtcbiAgfVxuXG4gIGNvbnN0IGFzeW5jVmFsaWRhdG9ycyA9IGdldENvbnRyb2xBc3luY1ZhbGlkYXRvcnMoY29udHJvbCk7XG4gIGlmIChkaXIuYXN5bmNWYWxpZGF0b3IgIT09IG51bGwpIHtcbiAgICBjb250cm9sLnNldEFzeW5jVmFsaWRhdG9ycyhcbiAgICAgICAgbWVyZ2VWYWxpZGF0b3JzPEFzeW5jVmFsaWRhdG9yRm4+KGFzeW5jVmFsaWRhdG9ycywgZGlyLmFzeW5jVmFsaWRhdG9yKSk7XG4gIH0gZWxzZSBpZiAodHlwZW9mIGFzeW5jVmFsaWRhdG9ycyA9PT0gJ2Z1bmN0aW9uJykge1xuICAgIGNvbnRyb2wuc2V0QXN5bmNWYWxpZGF0b3JzKFthc3luY1ZhbGlkYXRvcnNdKTtcbiAgfVxuXG4gIC8vIFJlLXJ1biB2YWxpZGF0aW9uIHdoZW4gdmFsaWRhdG9yIGJpbmRpbmcgY2hhbmdlcywgZS5nLiBtaW5sZW5ndGg9MyAtPiBtaW5sZW5ndGg9NFxuICBjb25zdCBvblZhbGlkYXRvckNoYW5nZSA9ICgpID0+IGNvbnRyb2wudXBkYXRlVmFsdWVBbmRWYWxpZGl0eSgpO1xuICByZWdpc3Rlck9uVmFsaWRhdG9yQ2hhbmdlPFZhbGlkYXRvckZuPihkaXIuX3Jhd1ZhbGlkYXRvcnMsIG9uVmFsaWRhdG9yQ2hhbmdlKTtcbiAgcmVnaXN0ZXJPblZhbGlkYXRvckNoYW5nZTxBc3luY1ZhbGlkYXRvckZuPihkaXIuX3Jhd0FzeW5jVmFsaWRhdG9ycywgb25WYWxpZGF0b3JDaGFuZ2UpO1xufVxuXG4vKipcbiAqIENsZWFucyB1cCBzeW5jIGFuZCBhc3luYyBkaXJlY3RpdmUgdmFsaWRhdG9ycyBvbiBwcm92aWRlZCBmb3JtIGNvbnRyb2wuXG4gKiBUaGlzIGZ1bmN0aW9uIHJldmVydHMgdGhlIHNldHVwIHBlcmZvcm1lZCBieSB0aGUgYHNldFVwVmFsaWRhdG9yc2AgZnVuY3Rpb24sIGkuZS5cbiAqIHJlbW92ZXMgZGlyZWN0aXZlLXNwZWNpZmljIHZhbGlkYXRvcnMgZnJvbSBhIGdpdmVuIGNvbnRyb2wgaW5zdGFuY2UuXG4gKlxuICogQHBhcmFtIGNvbnRyb2wgRm9ybSBjb250cm9sIGZyb20gd2hlcmUgZGlyZWN0aXZlIHZhbGlkYXRvcnMgc2hvdWxkIGJlIHJlbW92ZWQuXG4gKiBAcGFyYW0gZGlyIERpcmVjdGl2ZSBpbnN0YW5jZSB0aGF0IGNvbnRhaW5zIHZhbGlkYXRvcnMgdG8gYmUgcmVtb3ZlZC5cbiAqIEByZXR1cm5zIHRydWUgaWYgYSBjb250cm9sIHdhcyB1cGRhdGVkIGFzIGEgcmVzdWx0IG9mIHRoaXMgYWN0aW9uLlxuICovXG5leHBvcnQgZnVuY3Rpb24gY2xlYW5VcFZhbGlkYXRvcnMoXG4gICAgY29udHJvbDogQWJzdHJhY3RDb250cm9sfG51bGwsIGRpcjogQWJzdHJhY3RDb250cm9sRGlyZWN0aXZlKTogYm9vbGVhbiB7XG4gIGxldCBpc0NvbnRyb2xVcGRhdGVkID0gZmFsc2U7XG4gIGlmIChjb250cm9sICE9PSBudWxsKSB7XG4gICAgaWYgKGRpci52YWxpZGF0b3IgIT09IG51bGwpIHtcbiAgICAgIGNvbnN0IHZhbGlkYXRvcnMgPSBnZXRDb250cm9sVmFsaWRhdG9ycyhjb250cm9sKTtcbiAgICAgIGlmIChBcnJheS5pc0FycmF5KHZhbGlkYXRvcnMpICYmIHZhbGlkYXRvcnMubGVuZ3RoID4gMCkge1xuICAgICAgICAvLyBGaWx0ZXIgb3V0IGRpcmVjdGl2ZSB2YWxpZGF0b3IgZnVuY3Rpb24uXG4gICAgICAgIGNvbnN0IHVwZGF0ZWRWYWxpZGF0b3JzID0gdmFsaWRhdG9ycy5maWx0ZXIoKHZhbGlkYXRvcikgPT4gdmFsaWRhdG9yICE9PSBkaXIudmFsaWRhdG9yKTtcbiAgICAgICAgaWYgKHVwZGF0ZWRWYWxpZGF0b3JzLmxlbmd0aCAhPT0gdmFsaWRhdG9ycy5sZW5ndGgpIHtcbiAgICAgICAgICBpc0NvbnRyb2xVcGRhdGVkID0gdHJ1ZTtcbiAgICAgICAgICBjb250cm9sLnNldFZhbGlkYXRvcnModXBkYXRlZFZhbGlkYXRvcnMpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgaWYgKGRpci5hc3luY1ZhbGlkYXRvciAhPT0gbnVsbCkge1xuICAgICAgY29uc3QgYXN5bmNWYWxpZGF0b3JzID0gZ2V0Q29udHJvbEFzeW5jVmFsaWRhdG9ycyhjb250cm9sKTtcbiAgICAgIGlmIChBcnJheS5pc0FycmF5KGFzeW5jVmFsaWRhdG9ycykgJiYgYXN5bmNWYWxpZGF0b3JzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgLy8gRmlsdGVyIG91dCBkaXJlY3RpdmUgYXN5bmMgdmFsaWRhdG9yIGZ1bmN0aW9uLlxuICAgICAgICBjb25zdCB1cGRhdGVkQXN5bmNWYWxpZGF0b3JzID1cbiAgICAgICAgICAgIGFzeW5jVmFsaWRhdG9ycy5maWx0ZXIoKGFzeW5jVmFsaWRhdG9yKSA9PiBhc3luY1ZhbGlkYXRvciAhPT0gZGlyLmFzeW5jVmFsaWRhdG9yKTtcbiAgICAgICAgaWYgKHVwZGF0ZWRBc3luY1ZhbGlkYXRvcnMubGVuZ3RoICE9PSBhc3luY1ZhbGlkYXRvcnMubGVuZ3RoKSB7XG4gICAgICAgICAgaXNDb250cm9sVXBkYXRlZCA9IHRydWU7XG4gICAgICAgICAgY29udHJvbC5zZXRBc3luY1ZhbGlkYXRvcnModXBkYXRlZEFzeW5jVmFsaWRhdG9ycyk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICAvLyBDbGVhciBvblZhbGlkYXRvckNoYW5nZSBjYWxsYmFja3MgYnkgcHJvdmlkaW5nIGEgbm9vcCBmdW5jdGlvbi5cbiAgY29uc3Qgbm9vcCA9ICgpID0+IHt9O1xuICByZWdpc3Rlck9uVmFsaWRhdG9yQ2hhbmdlPFZhbGlkYXRvckZuPihkaXIuX3Jhd1ZhbGlkYXRvcnMsIG5vb3ApO1xuICByZWdpc3Rlck9uVmFsaWRhdG9yQ2hhbmdlPEFzeW5jVmFsaWRhdG9yRm4+KGRpci5fcmF3QXN5bmNWYWxpZGF0b3JzLCBub29wKTtcblxuICByZXR1cm4gaXNDb250cm9sVXBkYXRlZDtcbn1cblxuZnVuY3Rpb24gc2V0VXBWaWV3Q2hhbmdlUGlwZWxpbmUoY29udHJvbDogRm9ybUNvbnRyb2wsIGRpcjogTmdDb250cm9sKTogdm9pZCB7XG4gIGRpci52YWx1ZUFjY2Vzc29yIS5yZWdpc3Rlck9uQ2hhbmdlKChuZXdWYWx1ZTogYW55KSA9PiB7XG4gICAgY29udHJvbC5fcGVuZGluZ1ZhbHVlID0gbmV3VmFsdWU7XG4gICAgY29udHJvbC5fcGVuZGluZ0NoYW5nZSA9IHRydWU7XG4gICAgY29udHJvbC5fcGVuZGluZ0RpcnR5ID0gdHJ1ZTtcblxuICAgIGlmIChjb250cm9sLnVwZGF0ZU9uID09PSAnY2hhbmdlJykgdXBkYXRlQ29udHJvbChjb250cm9sLCBkaXIpO1xuICB9KTtcbn1cblxuZnVuY3Rpb24gc2V0VXBCbHVyUGlwZWxpbmUoY29udHJvbDogRm9ybUNvbnRyb2wsIGRpcjogTmdDb250cm9sKTogdm9pZCB7XG4gIGRpci52YWx1ZUFjY2Vzc29yIS5yZWdpc3Rlck9uVG91Y2hlZCgoKSA9PiB7XG4gICAgY29udHJvbC5fcGVuZGluZ1RvdWNoZWQgPSB0cnVlO1xuXG4gICAgaWYgKGNvbnRyb2wudXBkYXRlT24gPT09ICdibHVyJyAmJiBjb250cm9sLl9wZW5kaW5nQ2hhbmdlKSB1cGRhdGVDb250cm9sKGNvbnRyb2wsIGRpcik7XG4gICAgaWYgKGNvbnRyb2wudXBkYXRlT24gIT09ICdzdWJtaXQnKSBjb250cm9sLm1hcmtBc1RvdWNoZWQoKTtcbiAgfSk7XG59XG5cbmZ1bmN0aW9uIHVwZGF0ZUNvbnRyb2woY29udHJvbDogRm9ybUNvbnRyb2wsIGRpcjogTmdDb250cm9sKTogdm9pZCB7XG4gIGlmIChjb250cm9sLl9wZW5kaW5nRGlydHkpIGNvbnRyb2wubWFya0FzRGlydHkoKTtcbiAgY29udHJvbC5zZXRWYWx1ZShjb250cm9sLl9wZW5kaW5nVmFsdWUsIHtlbWl0TW9kZWxUb1ZpZXdDaGFuZ2U6IGZhbHNlfSk7XG4gIGRpci52aWV3VG9Nb2RlbFVwZGF0ZShjb250cm9sLl9wZW5kaW5nVmFsdWUpO1xuICBjb250cm9sLl9wZW5kaW5nQ2hhbmdlID0gZmFsc2U7XG59XG5cbmZ1bmN0aW9uIHNldFVwTW9kZWxDaGFuZ2VQaXBlbGluZShjb250cm9sOiBGb3JtQ29udHJvbCwgZGlyOiBOZ0NvbnRyb2wpOiB2b2lkIHtcbiAgY29uc3Qgb25DaGFuZ2UgPSAobmV3VmFsdWU/OiBhbnksIGVtaXRNb2RlbEV2ZW50PzogYm9vbGVhbikgPT4ge1xuICAgIC8vIGNvbnRyb2wgLT4gdmlld1xuICAgIGRpci52YWx1ZUFjY2Vzc29yIS53cml0ZVZhbHVlKG5ld1ZhbHVlKTtcblxuICAgIC8vIGNvbnRyb2wgLT4gbmdNb2RlbFxuICAgIGlmIChlbWl0TW9kZWxFdmVudCkgZGlyLnZpZXdUb01vZGVsVXBkYXRlKG5ld1ZhbHVlKTtcbiAgfTtcbiAgY29udHJvbC5yZWdpc3Rlck9uQ2hhbmdlKG9uQ2hhbmdlKTtcblxuICAvLyBSZWdpc3RlciBhIGNhbGxiYWNrIGZ1bmN0aW9uIHRvIGNsZWFudXAgb25DaGFuZ2UgaGFuZGxlclxuICAvLyBmcm9tIGEgY29udHJvbCBpbnN0YW5jZSB3aGVuIGEgZGlyZWN0aXZlIGlzIGRlc3Ryb3llZC5cbiAgZGlyLl9yZWdpc3Rlck9uRGVzdHJveSgoKSA9PiB7XG4gICAgY29udHJvbC5fdW5yZWdpc3Rlck9uQ2hhbmdlKG9uQ2hhbmdlKTtcbiAgfSk7XG59XG5cbi8qKlxuICogTGlua3MgYSBGb3JtR3JvdXAgb3IgRm9ybUFycmF5IGluc3RhbmNlIGFuZCBjb3JyZXNwb25kaW5nIEZvcm0gZGlyZWN0aXZlIGJ5IHNldHRpbmcgdXAgdmFsaWRhdG9yc1xuICogcHJlc2VudCBpbiB0aGUgdmlldy5cbiAqXG4gKiBAcGFyYW0gY29udHJvbCBGb3JtR3JvdXAgb3IgRm9ybUFycmF5IGluc3RhbmNlIHRoYXQgc2hvdWxkIGJlIGxpbmtlZC5cbiAqIEBwYXJhbSBkaXIgRGlyZWN0aXZlIHRoYXQgcHJvdmlkZXMgdmlldyB2YWxpZGF0b3JzLlxuICovXG5leHBvcnQgZnVuY3Rpb24gc2V0VXBGb3JtQ29udGFpbmVyKFxuICAgIGNvbnRyb2w6IEZvcm1Hcm91cHxGb3JtQXJyYXksIGRpcjogQWJzdHJhY3RGb3JtR3JvdXBEaXJlY3RpdmV8Rm9ybUFycmF5TmFtZSkge1xuICBpZiAoY29udHJvbCA9PSBudWxsICYmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpKVxuICAgIF90aHJvd0Vycm9yKGRpciwgJ0Nhbm5vdCBmaW5kIGNvbnRyb2wgd2l0aCcpO1xuICBzZXRVcFZhbGlkYXRvcnMoY29udHJvbCwgZGlyKTtcbn1cblxuLyoqXG4gKiBSZXZlcnRzIHRoZSBzZXR1cCBwZXJmb3JtZWQgYnkgdGhlIGBzZXRVcEZvcm1Db250YWluZXJgIGZ1bmN0aW9uLlxuICpcbiAqIEBwYXJhbSBjb250cm9sIEZvcm1Hcm91cCBvciBGb3JtQXJyYXkgaW5zdGFuY2UgdGhhdCBzaG91bGQgYmUgY2xlYW5lZCB1cC5cbiAqIEBwYXJhbSBkaXIgRGlyZWN0aXZlIHRoYXQgcHJvdmlkZWQgdmlldyB2YWxpZGF0b3JzLlxuICogQHJldHVybnMgdHJ1ZSBpZiBhIGNvbnRyb2wgd2FzIHVwZGF0ZWQgYXMgYSByZXN1bHQgb2YgdGhpcyBhY3Rpb24uXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBjbGVhblVwRm9ybUNvbnRhaW5lcihcbiAgICBjb250cm9sOiBGb3JtR3JvdXB8Rm9ybUFycmF5LCBkaXI6IEFic3RyYWN0Rm9ybUdyb3VwRGlyZWN0aXZlfEZvcm1BcnJheU5hbWUpOiBib29sZWFuIHtcbiAgcmV0dXJuIGNsZWFuVXBWYWxpZGF0b3JzKGNvbnRyb2wsIGRpcik7XG59XG5cbmZ1bmN0aW9uIF9ub0NvbnRyb2xFcnJvcihkaXI6IE5nQ29udHJvbCkge1xuICByZXR1cm4gX3Rocm93RXJyb3IoZGlyLCAnVGhlcmUgaXMgbm8gRm9ybUNvbnRyb2wgaW5zdGFuY2UgYXR0YWNoZWQgdG8gZm9ybSBjb250cm9sIGVsZW1lbnQgd2l0aCcpO1xufVxuXG5mdW5jdGlvbiBfdGhyb3dFcnJvcihkaXI6IEFic3RyYWN0Q29udHJvbERpcmVjdGl2ZSwgbWVzc2FnZTogc3RyaW5nKTogdm9pZCB7XG4gIGNvbnN0IG1lc3NhZ2VFbmQgPSBfZGVzY3JpYmVDb250cm9sTG9jYXRpb24oZGlyKTtcbiAgdGhyb3cgbmV3IEVycm9yKGAke21lc3NhZ2V9ICR7bWVzc2FnZUVuZH1gKTtcbn1cblxuZnVuY3Rpb24gX2Rlc2NyaWJlQ29udHJvbExvY2F0aW9uKGRpcjogQWJzdHJhY3RDb250cm9sRGlyZWN0aXZlKTogc3RyaW5nIHtcbiAgY29uc3QgcGF0aCA9IGRpci5wYXRoO1xuICBpZiAocGF0aCAmJiBwYXRoLmxlbmd0aCA+IDEpIHJldHVybiBgcGF0aDogJyR7cGF0aC5qb2luKCcgLT4gJyl9J2A7XG4gIGlmIChwYXRoPy5bMF0pIHJldHVybiBgbmFtZTogJyR7cGF0aH0nYDtcbiAgcmV0dXJuICd1bnNwZWNpZmllZCBuYW1lIGF0dHJpYnV0ZSc7XG59XG5cbmZ1bmN0aW9uIF90aHJvd01pc3NpbmdWYWx1ZUFjY2Vzc29yRXJyb3IoZGlyOiBBYnN0cmFjdENvbnRyb2xEaXJlY3RpdmUpIHtcbiAgY29uc3QgbG9jID0gX2Rlc2NyaWJlQ29udHJvbExvY2F0aW9uKGRpcik7XG4gIHRocm93IG5ldyBSdW50aW1lRXJyb3IoXG4gICAgICBSdW50aW1lRXJyb3JDb2RlLk5HX01JU1NJTkdfVkFMVUVfQUNDRVNTT1IsIGBObyB2YWx1ZSBhY2Nlc3NvciBmb3IgZm9ybSBjb250cm9sICR7bG9jfS5gKTtcbn1cblxuZnVuY3Rpb24gX3Rocm93SW52YWxpZFZhbHVlQWNjZXNzb3JFcnJvcihkaXI6IEFic3RyYWN0Q29udHJvbERpcmVjdGl2ZSkge1xuICBjb25zdCBsb2MgPSBfZGVzY3JpYmVDb250cm9sTG9jYXRpb24oZGlyKTtcbiAgdGhyb3cgbmV3IFJ1bnRpbWVFcnJvcihcbiAgICAgIFJ1bnRpbWVFcnJvckNvZGUuTkdfVkFMVUVfQUNDRVNTT1JfTk9UX1BST1ZJREVELFxuICAgICAgYFZhbHVlIGFjY2Vzc29yIHdhcyBub3QgcHJvdmlkZWQgYXMgYW4gYXJyYXkgZm9yIGZvcm0gY29udHJvbCB3aXRoICR7bG9jfS4gYCArXG4gICAgICAgICAgYENoZWNrIHRoYXQgdGhlIFxcYE5HX1ZBTFVFX0FDQ0VTU09SXFxgIHRva2VuIGlzIGNvbmZpZ3VyZWQgYXMgYSBcXGBtdWx0aTogdHJ1ZVxcYCBwcm92aWRlci5gKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGlzUHJvcGVydHlVcGRhdGVkKGNoYW5nZXM6IHtba2V5OiBzdHJpbmddOiBhbnl9LCB2aWV3TW9kZWw6IGFueSk6IGJvb2xlYW4ge1xuICBpZiAoIWNoYW5nZXMuaGFzT3duUHJvcGVydHkoJ21vZGVsJykpIHJldHVybiBmYWxzZTtcbiAgY29uc3QgY2hhbmdlID0gY2hhbmdlc1snbW9kZWwnXTtcblxuICBpZiAoY2hhbmdlLmlzRmlyc3RDaGFuZ2UoKSkgcmV0dXJuIHRydWU7XG4gIHJldHVybiAhT2JqZWN0LmlzKHZpZXdNb2RlbCwgY2hhbmdlLmN1cnJlbnRWYWx1ZSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc0J1aWx0SW5BY2Nlc3Nvcih2YWx1ZUFjY2Vzc29yOiBDb250cm9sVmFsdWVBY2Nlc3Nvcik6IGJvb2xlYW4ge1xuICAvLyBDaGVjayBpZiBhIGdpdmVuIHZhbHVlIGFjY2Vzc29yIGlzIGFuIGluc3RhbmNlIG9mIGEgY2xhc3MgdGhhdCBkaXJlY3RseSBleHRlbmRzXG4gIC8vIGBCdWlsdEluQ29udHJvbFZhbHVlQWNjZXNzb3JgIG9uZS5cbiAgcmV0dXJuIE9iamVjdC5nZXRQcm90b3R5cGVPZih2YWx1ZUFjY2Vzc29yLmNvbnN0cnVjdG9yKSA9PT0gQnVpbHRJbkNvbnRyb2xWYWx1ZUFjY2Vzc29yO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gc3luY1BlbmRpbmdDb250cm9scyhmb3JtOiBGb3JtR3JvdXAsIGRpcmVjdGl2ZXM6IFNldDxOZ0NvbnRyb2w+fE5nQ29udHJvbFtdKTogdm9pZCB7XG4gIGZvcm0uX3N5bmNQZW5kaW5nQ29udHJvbHMoKTtcbiAgZGlyZWN0aXZlcy5mb3JFYWNoKChkaXI6IE5nQ29udHJvbCkgPT4ge1xuICAgIGNvbnN0IGNvbnRyb2wgPSBkaXIuY29udHJvbCBhcyBGb3JtQ29udHJvbDtcbiAgICBpZiAoY29udHJvbC51cGRhdGVPbiA9PT0gJ3N1Ym1pdCcgJiYgY29udHJvbC5fcGVuZGluZ0NoYW5nZSkge1xuICAgICAgZGlyLnZpZXdUb01vZGVsVXBkYXRlKGNvbnRyb2wuX3BlbmRpbmdWYWx1ZSk7XG4gICAgICBjb250cm9sLl9wZW5kaW5nQ2hhbmdlID0gZmFsc2U7XG4gICAgfVxuICB9KTtcbn1cblxuLy8gVE9ETzogdnNhdmtpbiByZW1vdmUgaXQgb25jZSBodHRwczovL2dpdGh1Yi5jb20vYW5ndWxhci9hbmd1bGFyL2lzc3Vlcy8zMDExIGlzIGltcGxlbWVudGVkXG5leHBvcnQgZnVuY3Rpb24gc2VsZWN0VmFsdWVBY2Nlc3NvcihcbiAgICBkaXI6IE5nQ29udHJvbCwgdmFsdWVBY2Nlc3NvcnM6IENvbnRyb2xWYWx1ZUFjY2Vzc29yW10pOiBDb250cm9sVmFsdWVBY2Nlc3NvcnxudWxsIHtcbiAgaWYgKCF2YWx1ZUFjY2Vzc29ycykgcmV0dXJuIG51bGw7XG5cbiAgaWYgKCFBcnJheS5pc0FycmF5KHZhbHVlQWNjZXNzb3JzKSAmJiAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSlcbiAgICBfdGhyb3dJbnZhbGlkVmFsdWVBY2Nlc3NvckVycm9yKGRpcik7XG5cbiAgbGV0IGRlZmF1bHRBY2Nlc3NvcjogQ29udHJvbFZhbHVlQWNjZXNzb3J8dW5kZWZpbmVkID0gdW5kZWZpbmVkO1xuICBsZXQgYnVpbHRpbkFjY2Vzc29yOiBDb250cm9sVmFsdWVBY2Nlc3Nvcnx1bmRlZmluZWQgPSB1bmRlZmluZWQ7XG4gIGxldCBjdXN0b21BY2Nlc3NvcjogQ29udHJvbFZhbHVlQWNjZXNzb3J8dW5kZWZpbmVkID0gdW5kZWZpbmVkO1xuXG4gIHZhbHVlQWNjZXNzb3JzLmZvckVhY2goKHY6IENvbnRyb2xWYWx1ZUFjY2Vzc29yKSA9PiB7XG4gICAgaWYgKHYuY29uc3RydWN0b3IgPT09IERlZmF1bHRWYWx1ZUFjY2Vzc29yKSB7XG4gICAgICBkZWZhdWx0QWNjZXNzb3IgPSB2O1xuICAgIH0gZWxzZSBpZiAoaXNCdWlsdEluQWNjZXNzb3IodikpIHtcbiAgICAgIGlmIChidWlsdGluQWNjZXNzb3IgJiYgKHR5cGVvZiBuZ0Rldk1vZGUgPT09ICd1bmRlZmluZWQnIHx8IG5nRGV2TW9kZSkpXG4gICAgICAgIF90aHJvd0Vycm9yKGRpciwgJ01vcmUgdGhhbiBvbmUgYnVpbHQtaW4gdmFsdWUgYWNjZXNzb3IgbWF0Y2hlcyBmb3JtIGNvbnRyb2wgd2l0aCcpO1xuICAgICAgYnVpbHRpbkFjY2Vzc29yID0gdjtcbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKGN1c3RvbUFjY2Vzc29yICYmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpKVxuICAgICAgICBfdGhyb3dFcnJvcihkaXIsICdNb3JlIHRoYW4gb25lIGN1c3RvbSB2YWx1ZSBhY2Nlc3NvciBtYXRjaGVzIGZvcm0gY29udHJvbCB3aXRoJyk7XG4gICAgICBjdXN0b21BY2Nlc3NvciA9IHY7XG4gICAgfVxuICB9KTtcblxuICBpZiAoY3VzdG9tQWNjZXNzb3IpIHJldHVybiBjdXN0b21BY2Nlc3NvcjtcbiAgaWYgKGJ1aWx0aW5BY2Nlc3NvcikgcmV0dXJuIGJ1aWx0aW5BY2Nlc3NvcjtcbiAgaWYgKGRlZmF1bHRBY2Nlc3NvcikgcmV0dXJuIGRlZmF1bHRBY2Nlc3NvcjtcblxuICBpZiAodHlwZW9mIG5nRGV2TW9kZSA9PT0gJ3VuZGVmaW5lZCcgfHwgbmdEZXZNb2RlKSB7XG4gICAgX3Rocm93RXJyb3IoZGlyLCAnTm8gdmFsaWQgdmFsdWUgYWNjZXNzb3IgZm9yIGZvcm0gY29udHJvbCB3aXRoJyk7XG4gIH1cbiAgcmV0dXJuIG51bGw7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiByZW1vdmVMaXN0SXRlbTxUPihsaXN0OiBUW10sIGVsOiBUKTogdm9pZCB7XG4gIGNvbnN0IGluZGV4ID0gbGlzdC5pbmRleE9mKGVsKTtcbiAgaWYgKGluZGV4ID4gLTEpIGxpc3Quc3BsaWNlKGluZGV4LCAxKTtcbn1cblxuLy8gVE9ETyhrYXJhKTogcmVtb3ZlIGFmdGVyIGRlcHJlY2F0aW9uIHBlcmlvZFxuZXhwb3J0IGZ1bmN0aW9uIF9uZ01vZGVsV2FybmluZyhcbiAgICBuYW1lOiBzdHJpbmcsIHR5cGU6IHtfbmdNb2RlbFdhcm5pbmdTZW50T25jZTogYm9vbGVhbn0sXG4gICAgaW5zdGFuY2U6IHtfbmdNb2RlbFdhcm5pbmdTZW50OiBib29sZWFufSwgd2FybmluZ0NvbmZpZzogc3RyaW5nfG51bGwpIHtcbiAgaWYgKHdhcm5pbmdDb25maWcgPT09ICduZXZlcicpIHJldHVybjtcblxuICBpZiAoKCh3YXJuaW5nQ29uZmlnID09PSBudWxsIHx8IHdhcm5pbmdDb25maWcgPT09ICdvbmNlJykgJiYgIXR5cGUuX25nTW9kZWxXYXJuaW5nU2VudE9uY2UpIHx8XG4gICAgICAod2FybmluZ0NvbmZpZyA9PT0gJ2Fsd2F5cycgJiYgIWluc3RhbmNlLl9uZ01vZGVsV2FybmluZ1NlbnQpKSB7XG4gICAgY29uc29sZS53YXJuKG5nTW9kZWxXYXJuaW5nKG5hbWUpKTtcbiAgICB0eXBlLl9uZ01vZGVsV2FybmluZ1NlbnRPbmNlID0gdHJ1ZTtcbiAgICBpbnN0YW5jZS5fbmdNb2RlbFdhcm5pbmdTZW50ID0gdHJ1ZTtcbiAgfVxufVxuIl19