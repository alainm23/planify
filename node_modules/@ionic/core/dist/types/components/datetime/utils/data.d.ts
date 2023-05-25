import type { Mode } from '../../../interface';
import type { PickerColumnItem } from '../../picker-column-internal/picker-column-internal-interfaces';
import type { DatetimeParts } from '../datetime-interface';
/**
 * Returns the current date as
 * an ISO string in the user's
 * time zone.
 */
export declare const getToday: () => string;
/**
 * Given a locale and a mode,
 * return an array with formatted days
 * of the week. iOS should display days
 * such as "Mon" or "Tue".
 * MD should display days such as "M"
 * or "T".
 */
export declare const getDaysOfWeek: (locale: string, mode: Mode, firstDayOfWeek?: number) => string[];
/**
 * Returns an array containing all of the
 * days in a month for a given year. Values are
 * aligned with a week calendar starting on
 * the firstDayOfWeek value (Sunday by default)
 * using null values.
 */
export declare const getDaysOfMonth: (month: number, year: number, firstDayOfWeek: number) => ({
  day: number;
  dayOfWeek: number;
} | {
  day: null;
  dayOfWeek: null;
})[];
/**
 * Given a local, reference datetime parts and option
 * max/min bound datetime parts, calculate the acceptable
 * hour and minute values according to the bounds and locale.
 */
export declare const generateTime: (refParts: DatetimeParts, hourCycle?: 'h12' | 'h23', minParts?: DatetimeParts, maxParts?: DatetimeParts, hourValues?: number[], minuteValues?: number[]) => {
  hours: number[];
  minutes: number[];
  am: boolean;
  pm: boolean;
};
/**
 * Given DatetimeParts, generate the previous,
 * current, and and next months.
 */
export declare const generateMonths: (refParts: DatetimeParts) => DatetimeParts[];
export declare const getMonthColumnData: (locale: string, refParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts, monthValues?: number[], formatOptions?: Intl.DateTimeFormatOptions) => PickerColumnItem[];
/**
 * Returns information regarding
 * selectable dates (i.e 1st, 2nd, 3rd, etc)
 * within a reference month.
 * @param locale The locale to format the date with
 * @param refParts The reference month/year to generate dates for
 * @param minParts The minimum bound on the date that can be returned
 * @param maxParts The maximum bound on the date that can be returned
 * @param dayValues The allowed date values
 * @returns Date data to be used in ion-picker-column-internal
 */
export declare const getDayColumnData: (locale: string, refParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts, dayValues?: number[], formatOptions?: Intl.DateTimeFormatOptions) => PickerColumnItem[];
export declare const getYearColumnData: (locale: string, refParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts, yearValues?: number[]) => PickerColumnItem[];
interface CombinedDateColumnData {
  parts: DatetimeParts[];
  items: PickerColumnItem[];
}
/**
 * Creates and returns picker items
 * that represent the days in a month.
 * Example: "Thu, Jun 2"
 */
export declare const getCombinedDateColumnData: (locale: string, todayParts: DatetimeParts, minParts: DatetimeParts, maxParts: DatetimeParts, dayValues?: number[], monthValues?: number[]) => CombinedDateColumnData;
export declare const getTimeColumnsData: (locale: string, refParts: DatetimeParts, hourCycle?: 'h23' | 'h12', minParts?: DatetimeParts, maxParts?: DatetimeParts, allowedHourValues?: number[], allowedMinuteValues?: number[]) => {
  [key: string]: PickerColumnItem[];
};
export {};
