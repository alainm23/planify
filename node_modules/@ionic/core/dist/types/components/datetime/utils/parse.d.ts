import type { DatetimeParts } from '../datetime-interface';
/**
 * Use to convert a string of comma separated numbers or
 * an array of numbers, and clean up any user input
 */
export declare const convertToArrayOfNumbers: (input?: number[] | number | string) => number[] | undefined;
/**
 * Extracts date information
 * from a .calendar-day element
 * into DatetimeParts.
 */
export declare const getPartsFromCalendarDay: (el: HTMLElement) => DatetimeParts;
/**
 * Given an ISO-8601 string, format out the parts
 * We do not use the JS Date object here because
 * it adjusts the date for the current timezone.
 */
export declare function parseDate(val: string): DatetimeParts;
export declare function parseDate(val: string[]): DatetimeParts[];
export declare function parseDate(val: undefined | null): undefined;
export declare function parseDate(val: string | string[]): DatetimeParts | DatetimeParts[];
export declare function parseDate(val: string | string[] | undefined | null): DatetimeParts | DatetimeParts[] | undefined;
export declare const clampDate: (dateParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts) => DatetimeParts;
/**
 * Parses an hour and returns if the value is in the morning (am) or afternoon (pm).
 * @param hour The hour to format, should be 0-23
 * @returns `pm` if the hour is greater than or equal to 12, `am` if less than 12.
 */
export declare const parseAmPm: (hour: number) => "am" | "pm";
/**
 * Takes a max date string and creates a DatetimeParts
 * object, filling in any missing information.
 * For example, max="2012" would fill in the missing
 * month, day, hour, and minute information.
 */
export declare const parseMaxParts: (max: string, todayParts: DatetimeParts) => DatetimeParts;
/**
 * Takes a min date string and creates a DatetimeParts
 * object, filling in any missing information.
 * For example, min="2012" would fill in the missing
 * month, day, hour, and minute information.
 */
export declare const parseMinParts: (min: string, todayParts: DatetimeParts) => DatetimeParts;
