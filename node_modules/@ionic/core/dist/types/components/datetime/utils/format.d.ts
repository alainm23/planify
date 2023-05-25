import type { DatetimeParts } from '../datetime-interface';
export declare const getLocalizedTime: (locale: string, refParts: DatetimeParts, use24Hour: boolean) => string;
/**
 * Adds padding to a time value so
 * that it is always 2 digits.
 */
export declare const addTimePadding: (value: number) => string;
/**
 * Formats 24 hour times so that
 * it always has 2 digits. For
 * 12 hour times it ensures that
 * hour 0 is formatted as '12'.
 */
export declare const getFormattedHour: (hour: number, use24Hour: boolean) => string;
/**
 * Generates an aria-label to be read by screen readers
 * given a local, a date, and whether or not that date is
 * today's date.
 */
export declare const generateDayAriaLabel: (locale: string, today: boolean, refParts: DatetimeParts) => string | null;
/**
 * Gets the day of the week, month, and day
 * Used for the header in MD mode.
 */
export declare const getMonthAndDay: (locale: string, refParts: DatetimeParts) => string;
/**
 * Given a locale and a date object,
 * return a formatted string that includes
 * the month name and full year.
 * Example: May 2021
 */
export declare const getMonthAndYear: (locale: string, refParts: DatetimeParts) => string;
/**
 * Given a locale and a date object,
 * return a formatted string that includes
 * the short month, numeric day, and full year.
 * Example: Apr 22, 2021
 */
export declare const getMonthDayAndYear: (locale: string, refParts: DatetimeParts) => string;
/**
 * Given a locale and a date object,
 * return a formatted string that includes
 * the numeric day.
 * Note: Some languages will add literal characters
 * to the end. This function removes those literals.
 * Example: 29
 */
export declare const getDay: (locale: string, refParts: DatetimeParts) => string;
/**
 * Given a locale and a date object,
 * return a formatted string that includes
 * the numeric year.
 * Example: 2022
 */
export declare const getYear: (locale: string, refParts: DatetimeParts) => string;
/**
 * Given a locale, DatetimeParts, and options
 * format the DatetimeParts according to the options
 * and locale combination. This returns a string. If
 * you want an array of the individual pieces
 * that make up the localized date string, use
 * getLocalizedDateTimeParts.
 */
export declare const getLocalizedDateTime: (locale: string, refParts: DatetimeParts, options: Intl.DateTimeFormatOptions) => string;
/**
 * Given a locale, DatetimeParts, and options
 * format the DatetimeParts according to the options
 * and locale combination. This returns an array of
 * each piece of the date.
 */
export declare const getLocalizedDateTimeParts: (locale: string, refParts: DatetimeParts, options: Intl.DateTimeFormatOptions) => Intl.DateTimeFormatPart[];
/**
 * Gets a localized version of "Today"
 * Falls back to "Today" in English for
 * browsers that do not support RelativeTimeFormat.
 */
export declare const getTodayLabel: (locale: string) => string;
/**
 * When calling toISOString(), the browser
 * will convert the date to UTC time by either adding
 * or subtracting the time zone offset.
 * To work around this, we need to either add
 * or subtract the time zone offset to the Date
 * object prior to calling toISOString().
 * This allows us to get an ISO string
 * that is in the user's time zone.
 *
 * Example:
 * Time zone offset is 240
 * Meaning: The browser needs to add 240 minutes
 * to the Date object to get UTC time.
 * What Ionic does: We subtract 240 minutes
 * from the Date object. The browser then adds
 * 240 minutes in toISOString(). The result
 * is a time that is in the user's time zone
 * and not UTC.
 *
 * Note: Some timezones include minute adjustments
 * such as 30 or 45 minutes. This is why we use setMinutes
 * instead of setHours.
 * Example: India Standard Time
 * Timezone offset: -330 = -5.5 hours.
 *
 * List of timezones with 30 and 45 minute timezones:
 * https://www.timeanddate.com/time/time-zones-interesting.html
 */
export declare const removeDateTzOffset: (date: Date) => Date;
/**
 * Formats the locale's string representation of the day period (am/pm) for a given
 * ref parts day period.
 *
 * @param locale The locale to format the day period in.
 * @param value The date string, in ISO format.
 * @returns The localized day period (am/pm) representation of the given value.
 */
export declare const getLocalizedDayPeriod: (locale: string, dayPeriod: 'am' | 'pm' | undefined) => string;
/**
 * Formats the datetime's value to a string, for use in the native input.
 *
 * @param value The value to format, either an ISO string or an array thereof.
 */
export declare const formatValue: (value: string | string[] | null | undefined) => string | null | undefined;
