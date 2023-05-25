import type { DatetimeParts } from '../datetime-interface';
export declare function convertDataToISO(data: DatetimeParts): string;
export declare function convertDataToISO(data: DatetimeParts[]): string[];
export declare function convertDataToISO(data: DatetimeParts | DatetimeParts[]): string | string[];
/**
 * Converts an 12 hour value to 24 hours.
 */
export declare const convert12HourTo24Hour: (hour: number, ampm?: 'am' | 'pm') => number;
export declare const getStartOfWeek: (refParts: DatetimeParts) => DatetimeParts;
export declare const getEndOfWeek: (refParts: DatetimeParts) => DatetimeParts;
export declare const getNextDay: (refParts: DatetimeParts) => DatetimeParts;
export declare const getPreviousDay: (refParts: DatetimeParts) => DatetimeParts;
export declare const getPreviousWeek: (refParts: DatetimeParts) => DatetimeParts;
export declare const getNextWeek: (refParts: DatetimeParts) => DatetimeParts;
/**
 * Given datetime parts, subtract
 * numDays from the date.
 * Returns a new DatetimeParts object
 * Currently can only go backward at most 1 month.
 */
export declare const subtractDays: (refParts: DatetimeParts, numDays: number) => {
  month: number;
  day: number;
  year: number;
};
/**
 * Given datetime parts, add
 * numDays to the date.
 * Returns a new DatetimeParts object
 * Currently can only go forward at most 1 month.
 */
export declare const addDays: (refParts: DatetimeParts, numDays: number) => {
  month: number;
  day: number;
  year: number;
};
/**
 * Given DatetimeParts, generate the previous month.
 */
export declare const getPreviousMonth: (refParts: DatetimeParts) => {
  month: number;
  year: number;
  day: number | null;
};
/**
 * Given DatetimeParts, generate the next month.
 */
export declare const getNextMonth: (refParts: DatetimeParts) => {
  month: number;
  year: number;
  day: number | null;
};
/**
 * Given DatetimeParts, generate the previous year.
 */
export declare const getPreviousYear: (refParts: DatetimeParts) => {
  month: number;
  year: number;
  day: number | null;
};
/**
 * Given DatetimeParts, generate the next year.
 */
export declare const getNextYear: (refParts: DatetimeParts) => {
  month: number;
  year: number;
  day: number | null;
};
/**
 * If PM, then internal value should
 * be converted to 24-hr time.
 * Does not apply when public
 * values are already 24-hr time.
 */
export declare const getInternalHourValue: (hour: number, use24Hour: boolean, ampm?: 'am' | 'pm') => number;
/**
 * Unless otherwise stated, all month values are
 * 1 indexed instead of the typical 0 index in JS Date.
 * Example:
 *   January = Month 0 when using JS Date
 *   January = Month 1 when using this datetime util
 */
/**
 * Given the current datetime parts and a new AM/PM value
 * calculate what the hour should be in 24-hour time format.
 * Used when toggling the AM/PM segment since we store our hours
 * in 24-hour time format internally.
 */
export declare const calculateHourFromAMPM: (currentParts: DatetimeParts, newAMPM: 'am' | 'pm') => number;
/**
 * Updates parts to ensure that month and day
 * values are valid. For days that do not exist,
 * or are outside the min/max bounds, the closest
 * valid day is used.
 */
export declare const validateParts: (parts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts) => DatetimeParts;
/**
 * Returns the closest date to refParts
 * that also meets the constraints of
 * the *Values params.
 * @param refParts The reference date
 * @param monthValues The allowed month values
 * @param dayValues The allowed day (of the month) values
 * @param yearValues The allowed year values
 * @param hourValues The allowed hour values
 * @param minuteValues The allowed minute values
 */
export declare const getClosestValidDate: (refParts: DatetimeParts, monthValues?: number[], dayValues?: number[], yearValues?: number[], hourValues?: number[], minuteValues?: number[]) => {
  dayOfWeek: undefined;
  month: number;
  day: number | null;
  year: number;
  hour?: number | undefined;
  minute?: number | undefined;
  ampm?: "am" | "pm" | undefined;
};
