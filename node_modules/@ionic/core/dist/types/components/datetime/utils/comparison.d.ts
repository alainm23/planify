import type { DatetimeParts } from '../datetime-interface';
/**
 * Returns true if the selected day is equal to the reference day
 */
export declare const isSameDay: (baseParts: DatetimeParts, compareParts: DatetimeParts) => boolean;
/**
 * Returns true is the selected day is before the reference day.
 */
export declare const isBefore: (baseParts: DatetimeParts, compareParts: DatetimeParts) => boolean;
/**
 * Returns true is the selected day is after the reference day.
 */
export declare const isAfter: (baseParts: DatetimeParts, compareParts: DatetimeParts) => boolean;
export declare const warnIfValueOutOfBounds: (value: DatetimeParts | DatetimeParts[], min: DatetimeParts, max: DatetimeParts) => void;
