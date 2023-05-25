/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
import { printIonWarning } from '../../../utils/logging';
/**
 * Returns true if the selected day is equal to the reference day
 */
export const isSameDay = (baseParts, compareParts) => {
  return (baseParts.month === compareParts.month && baseParts.day === compareParts.day && baseParts.year === compareParts.year);
};
/**
 * Returns true is the selected day is before the reference day.
 */
export const isBefore = (baseParts, compareParts) => {
  return !!(baseParts.year < compareParts.year ||
    (baseParts.year === compareParts.year && baseParts.month < compareParts.month) ||
    (baseParts.year === compareParts.year &&
      baseParts.month === compareParts.month &&
      baseParts.day !== null &&
      baseParts.day < compareParts.day));
};
/**
 * Returns true is the selected day is after the reference day.
 */
export const isAfter = (baseParts, compareParts) => {
  return !!(baseParts.year > compareParts.year ||
    (baseParts.year === compareParts.year && baseParts.month > compareParts.month) ||
    (baseParts.year === compareParts.year &&
      baseParts.month === compareParts.month &&
      baseParts.day !== null &&
      baseParts.day > compareParts.day));
};
export const warnIfValueOutOfBounds = (value, min, max) => {
  const valueArray = Array.isArray(value) ? value : [value];
  for (const val of valueArray) {
    if ((min !== undefined && isBefore(val, min)) || (max !== undefined && isAfter(val, max))) {
      printIonWarning('The value provided to ion-datetime is out of bounds.\n\n' +
        `Min: ${JSON.stringify(min)}\n` +
        `Max: ${JSON.stringify(max)}\n` +
        `Value: ${JSON.stringify(value)}`);
      break;
    }
  }
};
