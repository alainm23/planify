import type { DatetimeHighlight, DatetimeHighlightCallback, DatetimeHighlightStyle, DatetimeParts } from '../datetime-interface';
export declare const isYearDisabled: (refYear: number, minParts?: DatetimeParts, maxParts?: DatetimeParts) => boolean;
/**
 * Returns true if a given day should
 * not be interactive according to its value,
 * or the max/min dates.
 */
export declare const isDayDisabled: (refParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts, dayValues?: number[]) => boolean;
/**
 * Given a locale, a date, the selected date(s), and today's date,
 * generate the state for a given calendar day button.
 */
export declare const getCalendarDayState: (locale: string, refParts: DatetimeParts, activeParts: DatetimeParts | DatetimeParts[], todayParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts, dayValues?: number[]) => {
  disabled: boolean;
  isActive: boolean;
  isToday: boolean;
  ariaSelected: string | null;
  ariaLabel: string | null;
  text: string | null;
};
/**
 * Returns `true` if the month is disabled given the
 * current date value and min/max date constraints.
 */
export declare const isMonthDisabled: (refParts: DatetimeParts, { minParts, maxParts, }: {
  minParts?: DatetimeParts | undefined;
  maxParts?: DatetimeParts | undefined;
}) => boolean;
/**
 * Given a working date, an optional minimum date range,
 * and an optional maximum date range; determine if the
 * previous navigation button is disabled.
 */
export declare const isPrevMonthDisabled: (refParts: DatetimeParts, minParts?: DatetimeParts, maxParts?: DatetimeParts) => boolean;
/**
 * Given a working date and a maximum date range,
 * determine if the next navigation button is disabled.
 */
export declare const isNextMonthDisabled: (refParts: DatetimeParts, maxParts?: DatetimeParts) => boolean;
/**
 * Given the value of the highlightedDates property
 * and an ISO string, return the styles to use for
 * that date, or undefined if none are found.
 */
export declare const getHighlightStyles: (highlightedDates: DatetimeHighlight[] | DatetimeHighlightCallback, dateIsoString: string, el: HTMLIonDatetimeElement) => DatetimeHighlightStyle | undefined;
