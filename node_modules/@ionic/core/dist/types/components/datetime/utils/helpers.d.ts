/**
 * Determines if given year is a
 * leap year. Returns `true` if year
 * is a leap year. Returns `false`
 * otherwise.
 */
export declare const isLeapYear: (year: number) => boolean;
export declare const is24Hour: (locale: string, hourCycle?: 'h23' | 'h12') => boolean;
/**
 * Given a date object, returns the number
 * of days in that month.
 * Month value begin at 1, not 0.
 * i.e. January = month 1.
 */
export declare const getNumDaysInMonth: (month: number, year: number) => 29 | 30 | 28 | 31;
/**
 * Certain locales display month then year while
 * others display year then month.
 * We can use Intl.DateTimeFormat to determine
 * the ordering for each locale.
 * The formatOptions param can be used to customize
 * which pieces of a date to compare against the month
 * with. For example, some locales render dd/mm/yyyy
 * while others render mm/dd/yyyy. This function can be
 * used for variations of the same "month first" check.
 */
export declare const isMonthFirstLocale: (locale: string, formatOptions?: Intl.DateTimeFormatOptions) => boolean;
/**
 * Determines if the given locale formats the day period (am/pm) to the
 * left or right of the hour.
 * @param locale The locale to check.
 * @returns `true` if the locale formats the day period to the left of the hour.
 */
export declare const isLocaleDayPeriodRTL: (locale: string) => boolean;
