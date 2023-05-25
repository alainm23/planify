/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { InjectionToken } from '../di/injection_token';
import { inject } from '../di/injector_compatibility';
import { InjectFlags } from '../di/interface/injector';
import { DEFAULT_LOCALE_ID, USD_CURRENCY_CODE } from './localization';
/**
 * Work out the locale from the potential global properties.
 *
 * * Closure Compiler: use `goog.LOCALE`.
 * * Ivy enabled: use `$localize.locale`
 */
export function getGlobalLocale() {
    if (typeof ngI18nClosureMode !== 'undefined' && ngI18nClosureMode &&
        typeof goog !== 'undefined' && goog.LOCALE !== 'en') {
        // * The default `goog.LOCALE` value is `en`, while Angular used `en-US`.
        // * In order to preserve backwards compatibility, we use Angular default value over
        //   Closure Compiler's one.
        return goog.LOCALE;
    }
    else {
        // KEEP `typeof $localize !== 'undefined' && $localize.locale` IN SYNC WITH THE LOCALIZE
        // COMPILE-TIME INLINER.
        //
        // * During compile time inlining of translations the expression will be replaced
        //   with a string literal that is the current locale. Other forms of this expression are not
        //   guaranteed to be replaced.
        //
        // * During runtime translation evaluation, the developer is required to set `$localize.locale`
        //   if required, or just to provide their own `LOCALE_ID` provider.
        return (typeof $localize !== 'undefined' && $localize.locale) || DEFAULT_LOCALE_ID;
    }
}
/**
 * Provide this token to set the locale of your application.
 * It is used for i18n extraction, by i18n pipes (DatePipe, I18nPluralPipe, CurrencyPipe,
 * DecimalPipe and PercentPipe) and by ICU expressions.
 *
 * See the [i18n guide](guide/i18n-common-locale-id) for more information.
 *
 * @usageNotes
 * ### Example
 *
 * ```typescript
 * import { LOCALE_ID } from '@angular/core';
 * import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
 * import { AppModule } from './app/app.module';
 *
 * platformBrowserDynamic().bootstrapModule(AppModule, {
 *   providers: [{provide: LOCALE_ID, useValue: 'en-US' }]
 * });
 * ```
 *
 * @publicApi
 */
export const LOCALE_ID = new InjectionToken('LocaleId', {
    providedIn: 'root',
    factory: () => inject(LOCALE_ID, InjectFlags.Optional | InjectFlags.SkipSelf) || getGlobalLocale(),
});
/**
 * Provide this token to set the default currency code your application uses for
 * CurrencyPipe when there is no currency code passed into it. This is only used by
 * CurrencyPipe and has no relation to locale currency. Defaults to USD if not configured.
 *
 * See the [i18n guide](guide/i18n-common-locale-id) for more information.
 *
 * <div class="alert is-helpful">
 *
 * **Deprecation notice:**
 *
 * The default currency code is currently always `USD` but this is deprecated from v9.
 *
 * **In v10 the default currency code will be taken from the current locale.**
 *
 * If you need the previous behavior then set it by creating a `DEFAULT_CURRENCY_CODE` provider in
 * your application `NgModule`:
 *
 * ```ts
 * {provide: DEFAULT_CURRENCY_CODE, useValue: 'USD'}
 * ```
 *
 * </div>
 *
 * @usageNotes
 * ### Example
 *
 * ```typescript
 * import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
 * import { AppModule } from './app/app.module';
 *
 * platformBrowserDynamic().bootstrapModule(AppModule, {
 *   providers: [{provide: DEFAULT_CURRENCY_CODE, useValue: 'EUR' }]
 * });
 * ```
 *
 * @publicApi
 */
export const DEFAULT_CURRENCY_CODE = new InjectionToken('DefaultCurrencyCode', {
    providedIn: 'root',
    factory: () => USD_CURRENCY_CODE,
});
/**
 * Use this token at bootstrap to provide the content of your translation file (`xtb`,
 * `xlf` or `xlf2`) when you want to translate your application in another language.
 *
 * See the [i18n guide](guide/i18n-common-merge) for more information.
 *
 * @usageNotes
 * ### Example
 *
 * ```typescript
 * import { TRANSLATIONS } from '@angular/core';
 * import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
 * import { AppModule } from './app/app.module';
 *
 * // content of your translation file
 * const translations = '....';
 *
 * platformBrowserDynamic().bootstrapModule(AppModule, {
 *   providers: [{provide: TRANSLATIONS, useValue: translations }]
 * });
 * ```
 *
 * @publicApi
 */
export const TRANSLATIONS = new InjectionToken('Translations');
/**
 * Provide this token at bootstrap to set the format of your {@link TRANSLATIONS}: `xtb`,
 * `xlf` or `xlf2`.
 *
 * See the [i18n guide](guide/i18n-common-merge) for more information.
 *
 * @usageNotes
 * ### Example
 *
 * ```typescript
 * import { TRANSLATIONS_FORMAT } from '@angular/core';
 * import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
 * import { AppModule } from './app/app.module';
 *
 * platformBrowserDynamic().bootstrapModule(AppModule, {
 *   providers: [{provide: TRANSLATIONS_FORMAT, useValue: 'xlf' }]
 * });
 * ```
 *
 * @publicApi
 */
export const TRANSLATIONS_FORMAT = new InjectionToken('TranslationsFormat');
/**
 * Use this enum at bootstrap as an option of `bootstrapModule` to define the strategy
 * that the compiler should use in case of missing translations:
 * - Error: throw if you have missing translations.
 * - Warning (default): show a warning in the console and/or shell.
 * - Ignore: do nothing.
 *
 * See the [i18n guide](guide/i18n-common-merge#report-missing-translations) for more information.
 *
 * @usageNotes
 * ### Example
 * ```typescript
 * import { MissingTranslationStrategy } from '@angular/core';
 * import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
 * import { AppModule } from './app/app.module';
 *
 * platformBrowserDynamic().bootstrapModule(AppModule, {
 *   missingTranslation: MissingTranslationStrategy.Error
 * });
 * ```
 *
 * @publicApi
 */
export var MissingTranslationStrategy;
(function (MissingTranslationStrategy) {
    MissingTranslationStrategy[MissingTranslationStrategy["Error"] = 0] = "Error";
    MissingTranslationStrategy[MissingTranslationStrategy["Warning"] = 1] = "Warning";
    MissingTranslationStrategy[MissingTranslationStrategy["Ignore"] = 2] = "Ignore";
})(MissingTranslationStrategy || (MissingTranslationStrategy = {}));
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoidG9rZW5zLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvaTE4bi90b2tlbnMudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLGNBQWMsRUFBQyxNQUFNLHVCQUF1QixDQUFDO0FBQ3JELE9BQU8sRUFBQyxNQUFNLEVBQUMsTUFBTSw4QkFBOEIsQ0FBQztBQUNwRCxPQUFPLEVBQUMsV0FBVyxFQUFDLE1BQU0sMEJBQTBCLENBQUM7QUFFckQsT0FBTyxFQUFDLGlCQUFpQixFQUFFLGlCQUFpQixFQUFDLE1BQU0sZ0JBQWdCLENBQUM7QUFJcEU7Ozs7O0dBS0c7QUFDSCxNQUFNLFVBQVUsZUFBZTtJQUM3QixJQUFJLE9BQU8saUJBQWlCLEtBQUssV0FBVyxJQUFJLGlCQUFpQjtRQUM3RCxPQUFPLElBQUksS0FBSyxXQUFXLElBQUksSUFBSSxDQUFDLE1BQU0sS0FBSyxJQUFJLEVBQUU7UUFDdkQseUVBQXlFO1FBQ3pFLG9GQUFvRjtRQUNwRiw0QkFBNEI7UUFDNUIsT0FBTyxJQUFJLENBQUMsTUFBTSxDQUFDO0tBQ3BCO1NBQU07UUFDTCx3RkFBd0Y7UUFDeEYsd0JBQXdCO1FBQ3hCLEVBQUU7UUFDRixpRkFBaUY7UUFDakYsNkZBQTZGO1FBQzdGLCtCQUErQjtRQUMvQixFQUFFO1FBQ0YsK0ZBQStGO1FBQy9GLG9FQUFvRTtRQUNwRSxPQUFPLENBQUMsT0FBTyxTQUFTLEtBQUssV0FBVyxJQUFJLFNBQVMsQ0FBQyxNQUFNLENBQUMsSUFBSSxpQkFBaUIsQ0FBQztLQUNwRjtBQUNILENBQUM7QUFFRDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBcUJHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sU0FBUyxHQUEyQixJQUFJLGNBQWMsQ0FBQyxVQUFVLEVBQUU7SUFDOUUsVUFBVSxFQUFFLE1BQU07SUFDbEIsT0FBTyxFQUFFLEdBQUcsRUFBRSxDQUNWLE1BQU0sQ0FBQyxTQUFTLEVBQUUsV0FBVyxDQUFDLFFBQVEsR0FBRyxXQUFXLENBQUMsUUFBUSxDQUFDLElBQUksZUFBZSxFQUFFO0NBQ3hGLENBQUMsQ0FBQztBQUVIOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBcUNHO0FBQ0gsTUFBTSxDQUFDLE1BQU0scUJBQXFCLEdBQUcsSUFBSSxjQUFjLENBQVMscUJBQXFCLEVBQUU7SUFDckYsVUFBVSxFQUFFLE1BQU07SUFDbEIsT0FBTyxFQUFFLEdBQUcsRUFBRSxDQUFDLGlCQUFpQjtDQUNqQyxDQUFDLENBQUM7QUFFSDs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7R0F1Qkc7QUFDSCxNQUFNLENBQUMsTUFBTSxZQUFZLEdBQUcsSUFBSSxjQUFjLENBQVMsY0FBYyxDQUFDLENBQUM7QUFFdkU7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBb0JHO0FBQ0gsTUFBTSxDQUFDLE1BQU0sbUJBQW1CLEdBQUcsSUFBSSxjQUFjLENBQVMsb0JBQW9CLENBQUMsQ0FBQztBQUVwRjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztHQXNCRztBQUNILE1BQU0sQ0FBTixJQUFZLDBCQUlYO0FBSkQsV0FBWSwwQkFBMEI7SUFDcEMsNkVBQVMsQ0FBQTtJQUNULGlGQUFXLENBQUE7SUFDWCwrRUFBVSxDQUFBO0FBQ1osQ0FBQyxFQUpXLDBCQUEwQixLQUExQiwwQkFBMEIsUUFJckMiLCJzb3VyY2VzQ29udGVudCI6WyIvKipcbiAqIEBsaWNlbnNlXG4gKiBDb3B5cmlnaHQgR29vZ2xlIExMQyBBbGwgUmlnaHRzIFJlc2VydmVkLlxuICpcbiAqIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVkIGJ5IGFuIE1JVC1zdHlsZSBsaWNlbnNlIHRoYXQgY2FuIGJlXG4gKiBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGF0IGh0dHBzOi8vYW5ndWxhci5pby9saWNlbnNlXG4gKi9cblxuaW1wb3J0IHtJbmplY3Rpb25Ub2tlbn0gZnJvbSAnLi4vZGkvaW5qZWN0aW9uX3Rva2VuJztcbmltcG9ydCB7aW5qZWN0fSBmcm9tICcuLi9kaS9pbmplY3Rvcl9jb21wYXRpYmlsaXR5JztcbmltcG9ydCB7SW5qZWN0RmxhZ3N9IGZyb20gJy4uL2RpL2ludGVyZmFjZS9pbmplY3Rvcic7XG5cbmltcG9ydCB7REVGQVVMVF9MT0NBTEVfSUQsIFVTRF9DVVJSRU5DWV9DT0RFfSBmcm9tICcuL2xvY2FsaXphdGlvbic7XG5cbmRlY2xhcmUgY29uc3QgJGxvY2FsaXplOiB7bG9jYWxlPzogc3RyaW5nfTtcblxuLyoqXG4gKiBXb3JrIG91dCB0aGUgbG9jYWxlIGZyb20gdGhlIHBvdGVudGlhbCBnbG9iYWwgcHJvcGVydGllcy5cbiAqXG4gKiAqIENsb3N1cmUgQ29tcGlsZXI6IHVzZSBgZ29vZy5MT0NBTEVgLlxuICogKiBJdnkgZW5hYmxlZDogdXNlIGAkbG9jYWxpemUubG9jYWxlYFxuICovXG5leHBvcnQgZnVuY3Rpb24gZ2V0R2xvYmFsTG9jYWxlKCk6IHN0cmluZyB7XG4gIGlmICh0eXBlb2YgbmdJMThuQ2xvc3VyZU1vZGUgIT09ICd1bmRlZmluZWQnICYmIG5nSTE4bkNsb3N1cmVNb2RlICYmXG4gICAgICB0eXBlb2YgZ29vZyAhPT0gJ3VuZGVmaW5lZCcgJiYgZ29vZy5MT0NBTEUgIT09ICdlbicpIHtcbiAgICAvLyAqIFRoZSBkZWZhdWx0IGBnb29nLkxPQ0FMRWAgdmFsdWUgaXMgYGVuYCwgd2hpbGUgQW5ndWxhciB1c2VkIGBlbi1VU2AuXG4gICAgLy8gKiBJbiBvcmRlciB0byBwcmVzZXJ2ZSBiYWNrd2FyZHMgY29tcGF0aWJpbGl0eSwgd2UgdXNlIEFuZ3VsYXIgZGVmYXVsdCB2YWx1ZSBvdmVyXG4gICAgLy8gICBDbG9zdXJlIENvbXBpbGVyJ3Mgb25lLlxuICAgIHJldHVybiBnb29nLkxPQ0FMRTtcbiAgfSBlbHNlIHtcbiAgICAvLyBLRUVQIGB0eXBlb2YgJGxvY2FsaXplICE9PSAndW5kZWZpbmVkJyAmJiAkbG9jYWxpemUubG9jYWxlYCBJTiBTWU5DIFdJVEggVEhFIExPQ0FMSVpFXG4gICAgLy8gQ09NUElMRS1USU1FIElOTElORVIuXG4gICAgLy9cbiAgICAvLyAqIER1cmluZyBjb21waWxlIHRpbWUgaW5saW5pbmcgb2YgdHJhbnNsYXRpb25zIHRoZSBleHByZXNzaW9uIHdpbGwgYmUgcmVwbGFjZWRcbiAgICAvLyAgIHdpdGggYSBzdHJpbmcgbGl0ZXJhbCB0aGF0IGlzIHRoZSBjdXJyZW50IGxvY2FsZS4gT3RoZXIgZm9ybXMgb2YgdGhpcyBleHByZXNzaW9uIGFyZSBub3RcbiAgICAvLyAgIGd1YXJhbnRlZWQgdG8gYmUgcmVwbGFjZWQuXG4gICAgLy9cbiAgICAvLyAqIER1cmluZyBydW50aW1lIHRyYW5zbGF0aW9uIGV2YWx1YXRpb24sIHRoZSBkZXZlbG9wZXIgaXMgcmVxdWlyZWQgdG8gc2V0IGAkbG9jYWxpemUubG9jYWxlYFxuICAgIC8vICAgaWYgcmVxdWlyZWQsIG9yIGp1c3QgdG8gcHJvdmlkZSB0aGVpciBvd24gYExPQ0FMRV9JRGAgcHJvdmlkZXIuXG4gICAgcmV0dXJuICh0eXBlb2YgJGxvY2FsaXplICE9PSAndW5kZWZpbmVkJyAmJiAkbG9jYWxpemUubG9jYWxlKSB8fCBERUZBVUxUX0xPQ0FMRV9JRDtcbiAgfVxufVxuXG4vKipcbiAqIFByb3ZpZGUgdGhpcyB0b2tlbiB0byBzZXQgdGhlIGxvY2FsZSBvZiB5b3VyIGFwcGxpY2F0aW9uLlxuICogSXQgaXMgdXNlZCBmb3IgaTE4biBleHRyYWN0aW9uLCBieSBpMThuIHBpcGVzIChEYXRlUGlwZSwgSTE4blBsdXJhbFBpcGUsIEN1cnJlbmN5UGlwZSxcbiAqIERlY2ltYWxQaXBlIGFuZCBQZXJjZW50UGlwZSkgYW5kIGJ5IElDVSBleHByZXNzaW9ucy5cbiAqXG4gKiBTZWUgdGhlIFtpMThuIGd1aWRlXShndWlkZS9pMThuLWNvbW1vbi1sb2NhbGUtaWQpIGZvciBtb3JlIGluZm9ybWF0aW9uLlxuICpcbiAqIEB1c2FnZU5vdGVzXG4gKiAjIyMgRXhhbXBsZVxuICpcbiAqIGBgYHR5cGVzY3JpcHRcbiAqIGltcG9ydCB7IExPQ0FMRV9JRCB9IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuICogaW1wb3J0IHsgcGxhdGZvcm1Ccm93c2VyRHluYW1pYyB9IGZyb20gJ0Bhbmd1bGFyL3BsYXRmb3JtLWJyb3dzZXItZHluYW1pYyc7XG4gKiBpbXBvcnQgeyBBcHBNb2R1bGUgfSBmcm9tICcuL2FwcC9hcHAubW9kdWxlJztcbiAqXG4gKiBwbGF0Zm9ybUJyb3dzZXJEeW5hbWljKCkuYm9vdHN0cmFwTW9kdWxlKEFwcE1vZHVsZSwge1xuICogICBwcm92aWRlcnM6IFt7cHJvdmlkZTogTE9DQUxFX0lELCB1c2VWYWx1ZTogJ2VuLVVTJyB9XVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBMT0NBTEVfSUQ6IEluamVjdGlvblRva2VuPHN0cmluZz4gPSBuZXcgSW5qZWN0aW9uVG9rZW4oJ0xvY2FsZUlkJywge1xuICBwcm92aWRlZEluOiAncm9vdCcsXG4gIGZhY3Rvcnk6ICgpID0+XG4gICAgICBpbmplY3QoTE9DQUxFX0lELCBJbmplY3RGbGFncy5PcHRpb25hbCB8IEluamVjdEZsYWdzLlNraXBTZWxmKSB8fCBnZXRHbG9iYWxMb2NhbGUoKSxcbn0pO1xuXG4vKipcbiAqIFByb3ZpZGUgdGhpcyB0b2tlbiB0byBzZXQgdGhlIGRlZmF1bHQgY3VycmVuY3kgY29kZSB5b3VyIGFwcGxpY2F0aW9uIHVzZXMgZm9yXG4gKiBDdXJyZW5jeVBpcGUgd2hlbiB0aGVyZSBpcyBubyBjdXJyZW5jeSBjb2RlIHBhc3NlZCBpbnRvIGl0LiBUaGlzIGlzIG9ubHkgdXNlZCBieVxuICogQ3VycmVuY3lQaXBlIGFuZCBoYXMgbm8gcmVsYXRpb24gdG8gbG9jYWxlIGN1cnJlbmN5LiBEZWZhdWx0cyB0byBVU0QgaWYgbm90IGNvbmZpZ3VyZWQuXG4gKlxuICogU2VlIHRoZSBbaTE4biBndWlkZV0oZ3VpZGUvaTE4bi1jb21tb24tbG9jYWxlLWlkKSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAqXG4gKiA8ZGl2IGNsYXNzPVwiYWxlcnQgaXMtaGVscGZ1bFwiPlxuICpcbiAqICoqRGVwcmVjYXRpb24gbm90aWNlOioqXG4gKlxuICogVGhlIGRlZmF1bHQgY3VycmVuY3kgY29kZSBpcyBjdXJyZW50bHkgYWx3YXlzIGBVU0RgIGJ1dCB0aGlzIGlzIGRlcHJlY2F0ZWQgZnJvbSB2OS5cbiAqXG4gKiAqKkluIHYxMCB0aGUgZGVmYXVsdCBjdXJyZW5jeSBjb2RlIHdpbGwgYmUgdGFrZW4gZnJvbSB0aGUgY3VycmVudCBsb2NhbGUuKipcbiAqXG4gKiBJZiB5b3UgbmVlZCB0aGUgcHJldmlvdXMgYmVoYXZpb3IgdGhlbiBzZXQgaXQgYnkgY3JlYXRpbmcgYSBgREVGQVVMVF9DVVJSRU5DWV9DT0RFYCBwcm92aWRlciBpblxuICogeW91ciBhcHBsaWNhdGlvbiBgTmdNb2R1bGVgOlxuICpcbiAqIGBgYHRzXG4gKiB7cHJvdmlkZTogREVGQVVMVF9DVVJSRU5DWV9DT0RFLCB1c2VWYWx1ZTogJ1VTRCd9XG4gKiBgYGBcbiAqXG4gKiA8L2Rpdj5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICogIyMjIEV4YW1wbGVcbiAqXG4gKiBgYGB0eXBlc2NyaXB0XG4gKiBpbXBvcnQgeyBwbGF0Zm9ybUJyb3dzZXJEeW5hbWljIH0gZnJvbSAnQGFuZ3VsYXIvcGxhdGZvcm0tYnJvd3Nlci1keW5hbWljJztcbiAqIGltcG9ydCB7IEFwcE1vZHVsZSB9IGZyb20gJy4vYXBwL2FwcC5tb2R1bGUnO1xuICpcbiAqIHBsYXRmb3JtQnJvd3NlckR5bmFtaWMoKS5ib290c3RyYXBNb2R1bGUoQXBwTW9kdWxlLCB7XG4gKiAgIHByb3ZpZGVyczogW3twcm92aWRlOiBERUZBVUxUX0NVUlJFTkNZX0NPREUsIHVzZVZhbHVlOiAnRVVSJyB9XVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBERUZBVUxUX0NVUlJFTkNZX0NPREUgPSBuZXcgSW5qZWN0aW9uVG9rZW48c3RyaW5nPignRGVmYXVsdEN1cnJlbmN5Q29kZScsIHtcbiAgcHJvdmlkZWRJbjogJ3Jvb3QnLFxuICBmYWN0b3J5OiAoKSA9PiBVU0RfQ1VSUkVOQ1lfQ09ERSxcbn0pO1xuXG4vKipcbiAqIFVzZSB0aGlzIHRva2VuIGF0IGJvb3RzdHJhcCB0byBwcm92aWRlIHRoZSBjb250ZW50IG9mIHlvdXIgdHJhbnNsYXRpb24gZmlsZSAoYHh0YmAsXG4gKiBgeGxmYCBvciBgeGxmMmApIHdoZW4geW91IHdhbnQgdG8gdHJhbnNsYXRlIHlvdXIgYXBwbGljYXRpb24gaW4gYW5vdGhlciBsYW5ndWFnZS5cbiAqXG4gKiBTZWUgdGhlIFtpMThuIGd1aWRlXShndWlkZS9pMThuLWNvbW1vbi1tZXJnZSkgZm9yIG1vcmUgaW5mb3JtYXRpb24uXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqICMjIyBFeGFtcGxlXG4gKlxuICogYGBgdHlwZXNjcmlwdFxuICogaW1wb3J0IHsgVFJBTlNMQVRJT05TIH0gZnJvbSAnQGFuZ3VsYXIvY29yZSc7XG4gKiBpbXBvcnQgeyBwbGF0Zm9ybUJyb3dzZXJEeW5hbWljIH0gZnJvbSAnQGFuZ3VsYXIvcGxhdGZvcm0tYnJvd3Nlci1keW5hbWljJztcbiAqIGltcG9ydCB7IEFwcE1vZHVsZSB9IGZyb20gJy4vYXBwL2FwcC5tb2R1bGUnO1xuICpcbiAqIC8vIGNvbnRlbnQgb2YgeW91ciB0cmFuc2xhdGlvbiBmaWxlXG4gKiBjb25zdCB0cmFuc2xhdGlvbnMgPSAnLi4uLic7XG4gKlxuICogcGxhdGZvcm1Ccm93c2VyRHluYW1pYygpLmJvb3RzdHJhcE1vZHVsZShBcHBNb2R1bGUsIHtcbiAqICAgcHJvdmlkZXJzOiBbe3Byb3ZpZGU6IFRSQU5TTEFUSU9OUywgdXNlVmFsdWU6IHRyYW5zbGF0aW9ucyB9XVxuICogfSk7XG4gKiBgYGBcbiAqXG4gKiBAcHVibGljQXBpXG4gKi9cbmV4cG9ydCBjb25zdCBUUkFOU0xBVElPTlMgPSBuZXcgSW5qZWN0aW9uVG9rZW48c3RyaW5nPignVHJhbnNsYXRpb25zJyk7XG5cbi8qKlxuICogUHJvdmlkZSB0aGlzIHRva2VuIGF0IGJvb3RzdHJhcCB0byBzZXQgdGhlIGZvcm1hdCBvZiB5b3VyIHtAbGluayBUUkFOU0xBVElPTlN9OiBgeHRiYCxcbiAqIGB4bGZgIG9yIGB4bGYyYC5cbiAqXG4gKiBTZWUgdGhlIFtpMThuIGd1aWRlXShndWlkZS9pMThuLWNvbW1vbi1tZXJnZSkgZm9yIG1vcmUgaW5mb3JtYXRpb24uXG4gKlxuICogQHVzYWdlTm90ZXNcbiAqICMjIyBFeGFtcGxlXG4gKlxuICogYGBgdHlwZXNjcmlwdFxuICogaW1wb3J0IHsgVFJBTlNMQVRJT05TX0ZPUk1BVCB9IGZyb20gJ0Bhbmd1bGFyL2NvcmUnO1xuICogaW1wb3J0IHsgcGxhdGZvcm1Ccm93c2VyRHluYW1pYyB9IGZyb20gJ0Bhbmd1bGFyL3BsYXRmb3JtLWJyb3dzZXItZHluYW1pYyc7XG4gKiBpbXBvcnQgeyBBcHBNb2R1bGUgfSBmcm9tICcuL2FwcC9hcHAubW9kdWxlJztcbiAqXG4gKiBwbGF0Zm9ybUJyb3dzZXJEeW5hbWljKCkuYm9vdHN0cmFwTW9kdWxlKEFwcE1vZHVsZSwge1xuICogICBwcm92aWRlcnM6IFt7cHJvdmlkZTogVFJBTlNMQVRJT05TX0ZPUk1BVCwgdXNlVmFsdWU6ICd4bGYnIH1dXG4gKiB9KTtcbiAqIGBgYFxuICpcbiAqIEBwdWJsaWNBcGlcbiAqL1xuZXhwb3J0IGNvbnN0IFRSQU5TTEFUSU9OU19GT1JNQVQgPSBuZXcgSW5qZWN0aW9uVG9rZW48c3RyaW5nPignVHJhbnNsYXRpb25zRm9ybWF0Jyk7XG5cbi8qKlxuICogVXNlIHRoaXMgZW51bSBhdCBib290c3RyYXAgYXMgYW4gb3B0aW9uIG9mIGBib290c3RyYXBNb2R1bGVgIHRvIGRlZmluZSB0aGUgc3RyYXRlZ3lcbiAqIHRoYXQgdGhlIGNvbXBpbGVyIHNob3VsZCB1c2UgaW4gY2FzZSBvZiBtaXNzaW5nIHRyYW5zbGF0aW9uczpcbiAqIC0gRXJyb3I6IHRocm93IGlmIHlvdSBoYXZlIG1pc3NpbmcgdHJhbnNsYXRpb25zLlxuICogLSBXYXJuaW5nIChkZWZhdWx0KTogc2hvdyBhIHdhcm5pbmcgaW4gdGhlIGNvbnNvbGUgYW5kL29yIHNoZWxsLlxuICogLSBJZ25vcmU6IGRvIG5vdGhpbmcuXG4gKlxuICogU2VlIHRoZSBbaTE4biBndWlkZV0oZ3VpZGUvaTE4bi1jb21tb24tbWVyZ2UjcmVwb3J0LW1pc3NpbmctdHJhbnNsYXRpb25zKSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAqXG4gKiBAdXNhZ2VOb3Rlc1xuICogIyMjIEV4YW1wbGVcbiAqIGBgYHR5cGVzY3JpcHRcbiAqIGltcG9ydCB7IE1pc3NpbmdUcmFuc2xhdGlvblN0cmF0ZWd5IH0gZnJvbSAnQGFuZ3VsYXIvY29yZSc7XG4gKiBpbXBvcnQgeyBwbGF0Zm9ybUJyb3dzZXJEeW5hbWljIH0gZnJvbSAnQGFuZ3VsYXIvcGxhdGZvcm0tYnJvd3Nlci1keW5hbWljJztcbiAqIGltcG9ydCB7IEFwcE1vZHVsZSB9IGZyb20gJy4vYXBwL2FwcC5tb2R1bGUnO1xuICpcbiAqIHBsYXRmb3JtQnJvd3NlckR5bmFtaWMoKS5ib290c3RyYXBNb2R1bGUoQXBwTW9kdWxlLCB7XG4gKiAgIG1pc3NpbmdUcmFuc2xhdGlvbjogTWlzc2luZ1RyYW5zbGF0aW9uU3RyYXRlZ3kuRXJyb3JcbiAqIH0pO1xuICogYGBgXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZW51bSBNaXNzaW5nVHJhbnNsYXRpb25TdHJhdGVneSB7XG4gIEVycm9yID0gMCxcbiAgV2FybmluZyA9IDEsXG4gIElnbm9yZSA9IDIsXG59XG4iXX0=