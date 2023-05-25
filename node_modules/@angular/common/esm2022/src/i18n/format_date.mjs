/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { FormatWidth, FormStyle, getLocaleDateFormat, getLocaleDateTimeFormat, getLocaleDayNames, getLocaleDayPeriods, getLocaleEraNames, getLocaleExtraDayPeriodRules, getLocaleExtraDayPeriods, getLocaleId, getLocaleMonthNames, getLocaleNumberSymbol, getLocaleTimeFormat, NumberSymbol, TranslationWidth } from './locale_data_api';
export const ISO8601_DATE_REGEX = /^(\d{4,})-?(\d\d)-?(\d\d)(?:T(\d\d)(?::?(\d\d)(?::?(\d\d)(?:\.(\d+))?)?)?(Z|([+-])(\d\d):?(\d\d))?)?$/;
//    1        2       3         4          5          6          7          8  9     10      11
const NAMED_FORMATS = {};
const DATE_FORMATS_SPLIT = /((?:[^BEGHLMOSWYZabcdhmswyz']+)|(?:'(?:[^']|'')*')|(?:G{1,5}|y{1,4}|Y{1,4}|M{1,5}|L{1,5}|w{1,2}|W{1}|d{1,2}|E{1,6}|c{1,6}|a{1,5}|b{1,5}|B{1,5}|h{1,2}|H{1,2}|m{1,2}|s{1,2}|S{1,3}|z{1,4}|Z{1,5}|O{1,4}))([\s\S]*)/;
var ZoneWidth;
(function (ZoneWidth) {
    ZoneWidth[ZoneWidth["Short"] = 0] = "Short";
    ZoneWidth[ZoneWidth["ShortGMT"] = 1] = "ShortGMT";
    ZoneWidth[ZoneWidth["Long"] = 2] = "Long";
    ZoneWidth[ZoneWidth["Extended"] = 3] = "Extended";
})(ZoneWidth || (ZoneWidth = {}));
var DateType;
(function (DateType) {
    DateType[DateType["FullYear"] = 0] = "FullYear";
    DateType[DateType["Month"] = 1] = "Month";
    DateType[DateType["Date"] = 2] = "Date";
    DateType[DateType["Hours"] = 3] = "Hours";
    DateType[DateType["Minutes"] = 4] = "Minutes";
    DateType[DateType["Seconds"] = 5] = "Seconds";
    DateType[DateType["FractionalSeconds"] = 6] = "FractionalSeconds";
    DateType[DateType["Day"] = 7] = "Day";
})(DateType || (DateType = {}));
var TranslationType;
(function (TranslationType) {
    TranslationType[TranslationType["DayPeriods"] = 0] = "DayPeriods";
    TranslationType[TranslationType["Days"] = 1] = "Days";
    TranslationType[TranslationType["Months"] = 2] = "Months";
    TranslationType[TranslationType["Eras"] = 3] = "Eras";
})(TranslationType || (TranslationType = {}));
/**
 * @ngModule CommonModule
 * @description
 *
 * Formats a date according to locale rules.
 *
 * @param value The date to format, as a Date, or a number (milliseconds since UTC epoch)
 * or an [ISO date-time string](https://www.w3.org/TR/NOTE-datetime).
 * @param format The date-time components to include. See `DatePipe` for details.
 * @param locale A locale code for the locale format rules to use.
 * @param timezone The time zone. A time zone offset from GMT (such as `'+0430'`),
 * or a standard UTC/GMT or continental US time zone abbreviation.
 * If not specified, uses host system settings.
 *
 * @returns The formatted date string.
 *
 * @see `DatePipe`
 * @see [Internationalization (i18n) Guide](https://angular.io/guide/i18n-overview)
 *
 * @publicApi
 */
export function formatDate(value, format, locale, timezone) {
    let date = toDate(value);
    const namedFormat = getNamedFormat(locale, format);
    format = namedFormat || format;
    let parts = [];
    let match;
    while (format) {
        match = DATE_FORMATS_SPLIT.exec(format);
        if (match) {
            parts = parts.concat(match.slice(1));
            const part = parts.pop();
            if (!part) {
                break;
            }
            format = part;
        }
        else {
            parts.push(format);
            break;
        }
    }
    let dateTimezoneOffset = date.getTimezoneOffset();
    if (timezone) {
        dateTimezoneOffset = timezoneToOffset(timezone, dateTimezoneOffset);
        date = convertTimezoneToLocal(date, timezone, true);
    }
    let text = '';
    parts.forEach(value => {
        const dateFormatter = getDateFormatter(value);
        text += dateFormatter ? dateFormatter(date, locale, dateTimezoneOffset) :
            value === '\'\'' ? '\'' :
                value.replace(/(^'|'$)/g, '').replace(/''/g, '\'');
    });
    return text;
}
/**
 * Create a new Date object with the given date value, and the time set to midnight.
 *
 * We cannot use `new Date(year, month, date)` because it maps years between 0 and 99 to 1900-1999.
 * See: https://github.com/angular/angular/issues/40377
 *
 * Note that this function returns a Date object whose time is midnight in the current locale's
 * timezone. In the future we might want to change this to be midnight in UTC, but this would be a
 * considerable breaking change.
 */
function createDate(year, month, date) {
    // The `newDate` is set to midnight (UTC) on January 1st 1970.
    // - In PST this will be December 31st 1969 at 4pm.
    // - In GMT this will be January 1st 1970 at 1am.
    // Note that they even have different years, dates and months!
    const newDate = new Date(0);
    // `setFullYear()` allows years like 0001 to be set correctly. This function does not
    // change the internal time of the date.
    // Consider calling `setFullYear(2019, 8, 20)` (September 20, 2019).
    // - In PST this will now be September 20, 2019 at 4pm
    // - In GMT this will now be September 20, 2019 at 1am
    newDate.setFullYear(year, month, date);
    // We want the final date to be at local midnight, so we reset the time.
    // - In PST this will now be September 20, 2019 at 12am
    // - In GMT this will now be September 20, 2019 at 12am
    newDate.setHours(0, 0, 0);
    return newDate;
}
function getNamedFormat(locale, format) {
    const localeId = getLocaleId(locale);
    NAMED_FORMATS[localeId] = NAMED_FORMATS[localeId] || {};
    if (NAMED_FORMATS[localeId][format]) {
        return NAMED_FORMATS[localeId][format];
    }
    let formatValue = '';
    switch (format) {
        case 'shortDate':
            formatValue = getLocaleDateFormat(locale, FormatWidth.Short);
            break;
        case 'mediumDate':
            formatValue = getLocaleDateFormat(locale, FormatWidth.Medium);
            break;
        case 'longDate':
            formatValue = getLocaleDateFormat(locale, FormatWidth.Long);
            break;
        case 'fullDate':
            formatValue = getLocaleDateFormat(locale, FormatWidth.Full);
            break;
        case 'shortTime':
            formatValue = getLocaleTimeFormat(locale, FormatWidth.Short);
            break;
        case 'mediumTime':
            formatValue = getLocaleTimeFormat(locale, FormatWidth.Medium);
            break;
        case 'longTime':
            formatValue = getLocaleTimeFormat(locale, FormatWidth.Long);
            break;
        case 'fullTime':
            formatValue = getLocaleTimeFormat(locale, FormatWidth.Full);
            break;
        case 'short':
            const shortTime = getNamedFormat(locale, 'shortTime');
            const shortDate = getNamedFormat(locale, 'shortDate');
            formatValue = formatDateTime(getLocaleDateTimeFormat(locale, FormatWidth.Short), [shortTime, shortDate]);
            break;
        case 'medium':
            const mediumTime = getNamedFormat(locale, 'mediumTime');
            const mediumDate = getNamedFormat(locale, 'mediumDate');
            formatValue = formatDateTime(getLocaleDateTimeFormat(locale, FormatWidth.Medium), [mediumTime, mediumDate]);
            break;
        case 'long':
            const longTime = getNamedFormat(locale, 'longTime');
            const longDate = getNamedFormat(locale, 'longDate');
            formatValue =
                formatDateTime(getLocaleDateTimeFormat(locale, FormatWidth.Long), [longTime, longDate]);
            break;
        case 'full':
            const fullTime = getNamedFormat(locale, 'fullTime');
            const fullDate = getNamedFormat(locale, 'fullDate');
            formatValue =
                formatDateTime(getLocaleDateTimeFormat(locale, FormatWidth.Full), [fullTime, fullDate]);
            break;
    }
    if (formatValue) {
        NAMED_FORMATS[localeId][format] = formatValue;
    }
    return formatValue;
}
function formatDateTime(str, opt_values) {
    if (opt_values) {
        str = str.replace(/\{([^}]+)}/g, function (match, key) {
            return (opt_values != null && key in opt_values) ? opt_values[key] : match;
        });
    }
    return str;
}
function padNumber(num, digits, minusSign = '-', trim, negWrap) {
    let neg = '';
    if (num < 0 || (negWrap && num <= 0)) {
        if (negWrap) {
            num = -num + 1;
        }
        else {
            num = -num;
            neg = minusSign;
        }
    }
    let strNum = String(num);
    while (strNum.length < digits) {
        strNum = '0' + strNum;
    }
    if (trim) {
        strNum = strNum.slice(strNum.length - digits);
    }
    return neg + strNum;
}
function formatFractionalSeconds(milliseconds, digits) {
    const strMs = padNumber(milliseconds, 3);
    return strMs.substring(0, digits);
}
/**
 * Returns a date formatter that transforms a date into its locale digit representation
 */
function dateGetter(name, size, offset = 0, trim = false, negWrap = false) {
    return function (date, locale) {
        let part = getDatePart(name, date);
        if (offset > 0 || part > -offset) {
            part += offset;
        }
        if (name === DateType.Hours) {
            if (part === 0 && offset === -12) {
                part = 12;
            }
        }
        else if (name === DateType.FractionalSeconds) {
            return formatFractionalSeconds(part, size);
        }
        const localeMinus = getLocaleNumberSymbol(locale, NumberSymbol.MinusSign);
        return padNumber(part, size, localeMinus, trim, negWrap);
    };
}
function getDatePart(part, date) {
    switch (part) {
        case DateType.FullYear:
            return date.getFullYear();
        case DateType.Month:
            return date.getMonth();
        case DateType.Date:
            return date.getDate();
        case DateType.Hours:
            return date.getHours();
        case DateType.Minutes:
            return date.getMinutes();
        case DateType.Seconds:
            return date.getSeconds();
        case DateType.FractionalSeconds:
            return date.getMilliseconds();
        case DateType.Day:
            return date.getDay();
        default:
            throw new Error(`Unknown DateType value "${part}".`);
    }
}
/**
 * Returns a date formatter that transforms a date into its locale string representation
 */
function dateStrGetter(name, width, form = FormStyle.Format, extended = false) {
    return function (date, locale) {
        return getDateTranslation(date, locale, name, width, form, extended);
    };
}
/**
 * Returns the locale translation of a date for a given form, type and width
 */
function getDateTranslation(date, locale, name, width, form, extended) {
    switch (name) {
        case TranslationType.Months:
            return getLocaleMonthNames(locale, form, width)[date.getMonth()];
        case TranslationType.Days:
            return getLocaleDayNames(locale, form, width)[date.getDay()];
        case TranslationType.DayPeriods:
            const currentHours = date.getHours();
            const currentMinutes = date.getMinutes();
            if (extended) {
                const rules = getLocaleExtraDayPeriodRules(locale);
                const dayPeriods = getLocaleExtraDayPeriods(locale, form, width);
                const index = rules.findIndex(rule => {
                    if (Array.isArray(rule)) {
                        // morning, afternoon, evening, night
                        const [from, to] = rule;
                        const afterFrom = currentHours >= from.hours && currentMinutes >= from.minutes;
                        const beforeTo = (currentHours < to.hours ||
                            (currentHours === to.hours && currentMinutes < to.minutes));
                        // We must account for normal rules that span a period during the day (e.g. 6am-9am)
                        // where `from` is less (earlier) than `to`. But also rules that span midnight (e.g.
                        // 10pm - 5am) where `from` is greater (later!) than `to`.
                        //
                        // In the first case the current time must be BOTH after `from` AND before `to`
                        // (e.g. 8am is after 6am AND before 10am).
                        //
                        // In the second case the current time must be EITHER after `from` OR before `to`
                        // (e.g. 4am is before 5am but not after 10pm; and 11pm is not before 5am but it is
                        // after 10pm).
                        if (from.hours < to.hours) {
                            if (afterFrom && beforeTo) {
                                return true;
                            }
                        }
                        else if (afterFrom || beforeTo) {
                            return true;
                        }
                    }
                    else { // noon or midnight
                        if (rule.hours === currentHours && rule.minutes === currentMinutes) {
                            return true;
                        }
                    }
                    return false;
                });
                if (index !== -1) {
                    return dayPeriods[index];
                }
            }
            // if no rules for the day periods, we use am/pm by default
            return getLocaleDayPeriods(locale, form, width)[currentHours < 12 ? 0 : 1];
        case TranslationType.Eras:
            return getLocaleEraNames(locale, width)[date.getFullYear() <= 0 ? 0 : 1];
        default:
            // This default case is not needed by TypeScript compiler, as the switch is exhaustive.
            // However Closure Compiler does not understand that and reports an error in typed mode.
            // The `throw new Error` below works around the problem, and the unexpected: never variable
            // makes sure tsc still checks this code is unreachable.
            const unexpected = name;
            throw new Error(`unexpected translation type ${unexpected}`);
    }
}
/**
 * Returns a date formatter that transforms a date and an offset into a timezone with ISO8601 or
 * GMT format depending on the width (eg: short = +0430, short:GMT = GMT+4, long = GMT+04:30,
 * extended = +04:30)
 */
function timeZoneGetter(width) {
    return function (date, locale, offset) {
        const zone = -1 * offset;
        const minusSign = getLocaleNumberSymbol(locale, NumberSymbol.MinusSign);
        const hours = zone > 0 ? Math.floor(zone / 60) : Math.ceil(zone / 60);
        switch (width) {
            case ZoneWidth.Short:
                return ((zone >= 0) ? '+' : '') + padNumber(hours, 2, minusSign) +
                    padNumber(Math.abs(zone % 60), 2, minusSign);
            case ZoneWidth.ShortGMT:
                return 'GMT' + ((zone >= 0) ? '+' : '') + padNumber(hours, 1, minusSign);
            case ZoneWidth.Long:
                return 'GMT' + ((zone >= 0) ? '+' : '') + padNumber(hours, 2, minusSign) + ':' +
                    padNumber(Math.abs(zone % 60), 2, minusSign);
            case ZoneWidth.Extended:
                if (offset === 0) {
                    return 'Z';
                }
                else {
                    return ((zone >= 0) ? '+' : '') + padNumber(hours, 2, minusSign) + ':' +
                        padNumber(Math.abs(zone % 60), 2, minusSign);
                }
            default:
                throw new Error(`Unknown zone width "${width}"`);
        }
    };
}
const JANUARY = 0;
const THURSDAY = 4;
function getFirstThursdayOfYear(year) {
    const firstDayOfYear = createDate(year, JANUARY, 1).getDay();
    return createDate(year, 0, 1 + ((firstDayOfYear <= THURSDAY) ? THURSDAY : THURSDAY + 7) - firstDayOfYear);
}
function getThursdayThisWeek(datetime) {
    return createDate(datetime.getFullYear(), datetime.getMonth(), datetime.getDate() + (THURSDAY - datetime.getDay()));
}
function weekGetter(size, monthBased = false) {
    return function (date, locale) {
        let result;
        if (monthBased) {
            const nbDaysBefore1stDayOfMonth = new Date(date.getFullYear(), date.getMonth(), 1).getDay() - 1;
            const today = date.getDate();
            result = 1 + Math.floor((today + nbDaysBefore1stDayOfMonth) / 7);
        }
        else {
            const thisThurs = getThursdayThisWeek(date);
            // Some days of a year are part of next year according to ISO 8601.
            // Compute the firstThurs from the year of this week's Thursday
            const firstThurs = getFirstThursdayOfYear(thisThurs.getFullYear());
            const diff = thisThurs.getTime() - firstThurs.getTime();
            result = 1 + Math.round(diff / 6.048e8); // 6.048e8 ms per week
        }
        return padNumber(result, size, getLocaleNumberSymbol(locale, NumberSymbol.MinusSign));
    };
}
/**
 * Returns a date formatter that provides the week-numbering year for the input date.
 */
function weekNumberingYearGetter(size, trim = false) {
    return function (date, locale) {
        const thisThurs = getThursdayThisWeek(date);
        const weekNumberingYear = thisThurs.getFullYear();
        return padNumber(weekNumberingYear, size, getLocaleNumberSymbol(locale, NumberSymbol.MinusSign), trim);
    };
}
const DATE_FORMATS = {};
// Based on CLDR formats:
// See complete list: http://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
// See also explanations: http://cldr.unicode.org/translation/date-time
// TODO(ocombe): support all missing cldr formats: U, Q, D, F, e, j, J, C, A, v, V, X, x
function getDateFormatter(format) {
    if (DATE_FORMATS[format]) {
        return DATE_FORMATS[format];
    }
    let formatter;
    switch (format) {
        // Era name (AD/BC)
        case 'G':
        case 'GG':
        case 'GGG':
            formatter = dateStrGetter(TranslationType.Eras, TranslationWidth.Abbreviated);
            break;
        case 'GGGG':
            formatter = dateStrGetter(TranslationType.Eras, TranslationWidth.Wide);
            break;
        case 'GGGGG':
            formatter = dateStrGetter(TranslationType.Eras, TranslationWidth.Narrow);
            break;
        // 1 digit representation of the year, e.g. (AD 1 => 1, AD 199 => 199)
        case 'y':
            formatter = dateGetter(DateType.FullYear, 1, 0, false, true);
            break;
        // 2 digit representation of the year, padded (00-99). (e.g. AD 2001 => 01, AD 2010 => 10)
        case 'yy':
            formatter = dateGetter(DateType.FullYear, 2, 0, true, true);
            break;
        // 3 digit representation of the year, padded (000-999). (e.g. AD 2001 => 01, AD 2010 => 10)
        case 'yyy':
            formatter = dateGetter(DateType.FullYear, 3, 0, false, true);
            break;
        // 4 digit representation of the year (e.g. AD 1 => 0001, AD 2010 => 2010)
        case 'yyyy':
            formatter = dateGetter(DateType.FullYear, 4, 0, false, true);
            break;
        // 1 digit representation of the week-numbering year, e.g. (AD 1 => 1, AD 199 => 199)
        case 'Y':
            formatter = weekNumberingYearGetter(1);
            break;
        // 2 digit representation of the week-numbering year, padded (00-99). (e.g. AD 2001 => 01, AD
        // 2010 => 10)
        case 'YY':
            formatter = weekNumberingYearGetter(2, true);
            break;
        // 3 digit representation of the week-numbering year, padded (000-999). (e.g. AD 1 => 001, AD
        // 2010 => 2010)
        case 'YYY':
            formatter = weekNumberingYearGetter(3);
            break;
        // 4 digit representation of the week-numbering year (e.g. AD 1 => 0001, AD 2010 => 2010)
        case 'YYYY':
            formatter = weekNumberingYearGetter(4);
            break;
        // Month of the year (1-12), numeric
        case 'M':
        case 'L':
            formatter = dateGetter(DateType.Month, 1, 1);
            break;
        case 'MM':
        case 'LL':
            formatter = dateGetter(DateType.Month, 2, 1);
            break;
        // Month of the year (January, ...), string, format
        case 'MMM':
            formatter = dateStrGetter(TranslationType.Months, TranslationWidth.Abbreviated);
            break;
        case 'MMMM':
            formatter = dateStrGetter(TranslationType.Months, TranslationWidth.Wide);
            break;
        case 'MMMMM':
            formatter = dateStrGetter(TranslationType.Months, TranslationWidth.Narrow);
            break;
        // Month of the year (January, ...), string, standalone
        case 'LLL':
            formatter =
                dateStrGetter(TranslationType.Months, TranslationWidth.Abbreviated, FormStyle.Standalone);
            break;
        case 'LLLL':
            formatter =
                dateStrGetter(TranslationType.Months, TranslationWidth.Wide, FormStyle.Standalone);
            break;
        case 'LLLLL':
            formatter =
                dateStrGetter(TranslationType.Months, TranslationWidth.Narrow, FormStyle.Standalone);
            break;
        // Week of the year (1, ... 52)
        case 'w':
            formatter = weekGetter(1);
            break;
        case 'ww':
            formatter = weekGetter(2);
            break;
        // Week of the month (1, ...)
        case 'W':
            formatter = weekGetter(1, true);
            break;
        // Day of the month (1-31)
        case 'd':
            formatter = dateGetter(DateType.Date, 1);
            break;
        case 'dd':
            formatter = dateGetter(DateType.Date, 2);
            break;
        // Day of the Week StandAlone (1, 1, Mon, Monday, M, Mo)
        case 'c':
        case 'cc':
            formatter = dateGetter(DateType.Day, 1);
            break;
        case 'ccc':
            formatter =
                dateStrGetter(TranslationType.Days, TranslationWidth.Abbreviated, FormStyle.Standalone);
            break;
        case 'cccc':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Wide, FormStyle.Standalone);
            break;
        case 'ccccc':
            formatter =
                dateStrGetter(TranslationType.Days, TranslationWidth.Narrow, FormStyle.Standalone);
            break;
        case 'cccccc':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Short, FormStyle.Standalone);
            break;
        // Day of the Week
        case 'E':
        case 'EE':
        case 'EEE':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Abbreviated);
            break;
        case 'EEEE':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Wide);
            break;
        case 'EEEEE':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Narrow);
            break;
        case 'EEEEEE':
            formatter = dateStrGetter(TranslationType.Days, TranslationWidth.Short);
            break;
        // Generic period of the day (am-pm)
        case 'a':
        case 'aa':
        case 'aaa':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Abbreviated);
            break;
        case 'aaaa':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Wide);
            break;
        case 'aaaaa':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Narrow);
            break;
        // Extended period of the day (midnight, at night, ...), standalone
        case 'b':
        case 'bb':
        case 'bbb':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Abbreviated, FormStyle.Standalone, true);
            break;
        case 'bbbb':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Wide, FormStyle.Standalone, true);
            break;
        case 'bbbbb':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Narrow, FormStyle.Standalone, true);
            break;
        // Extended period of the day (midnight, night, ...), standalone
        case 'B':
        case 'BB':
        case 'BBB':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Abbreviated, FormStyle.Format, true);
            break;
        case 'BBBB':
            formatter =
                dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Wide, FormStyle.Format, true);
            break;
        case 'BBBBB':
            formatter = dateStrGetter(TranslationType.DayPeriods, TranslationWidth.Narrow, FormStyle.Format, true);
            break;
        // Hour in AM/PM, (1-12)
        case 'h':
            formatter = dateGetter(DateType.Hours, 1, -12);
            break;
        case 'hh':
            formatter = dateGetter(DateType.Hours, 2, -12);
            break;
        // Hour of the day (0-23)
        case 'H':
            formatter = dateGetter(DateType.Hours, 1);
            break;
        // Hour in day, padded (00-23)
        case 'HH':
            formatter = dateGetter(DateType.Hours, 2);
            break;
        // Minute of the hour (0-59)
        case 'm':
            formatter = dateGetter(DateType.Minutes, 1);
            break;
        case 'mm':
            formatter = dateGetter(DateType.Minutes, 2);
            break;
        // Second of the minute (0-59)
        case 's':
            formatter = dateGetter(DateType.Seconds, 1);
            break;
        case 'ss':
            formatter = dateGetter(DateType.Seconds, 2);
            break;
        // Fractional second
        case 'S':
            formatter = dateGetter(DateType.FractionalSeconds, 1);
            break;
        case 'SS':
            formatter = dateGetter(DateType.FractionalSeconds, 2);
            break;
        case 'SSS':
            formatter = dateGetter(DateType.FractionalSeconds, 3);
            break;
        // Timezone ISO8601 short format (-0430)
        case 'Z':
        case 'ZZ':
        case 'ZZZ':
            formatter = timeZoneGetter(ZoneWidth.Short);
            break;
        // Timezone ISO8601 extended format (-04:30)
        case 'ZZZZZ':
            formatter = timeZoneGetter(ZoneWidth.Extended);
            break;
        // Timezone GMT short format (GMT+4)
        case 'O':
        case 'OO':
        case 'OOO':
        // Should be location, but fallback to format O instead because we don't have the data yet
        case 'z':
        case 'zz':
        case 'zzz':
            formatter = timeZoneGetter(ZoneWidth.ShortGMT);
            break;
        // Timezone GMT long format (GMT+0430)
        case 'OOOO':
        case 'ZZZZ':
        // Should be location, but fallback to format O instead because we don't have the data yet
        case 'zzzz':
            formatter = timeZoneGetter(ZoneWidth.Long);
            break;
        default:
            return null;
    }
    DATE_FORMATS[format] = formatter;
    return formatter;
}
function timezoneToOffset(timezone, fallback) {
    // Support: IE 11 only, Edge 13-15+
    // IE/Edge do not "understand" colon (`:`) in timezone
    timezone = timezone.replace(/:/g, '');
    const requestedTimezoneOffset = Date.parse('Jan 01, 1970 00:00:00 ' + timezone) / 60000;
    return isNaN(requestedTimezoneOffset) ? fallback : requestedTimezoneOffset;
}
function addDateMinutes(date, minutes) {
    date = new Date(date.getTime());
    date.setMinutes(date.getMinutes() + minutes);
    return date;
}
function convertTimezoneToLocal(date, timezone, reverse) {
    const reverseValue = reverse ? -1 : 1;
    const dateTimezoneOffset = date.getTimezoneOffset();
    const timezoneOffset = timezoneToOffset(timezone, dateTimezoneOffset);
    return addDateMinutes(date, reverseValue * (timezoneOffset - dateTimezoneOffset));
}
/**
 * Converts a value to date.
 *
 * Supported input formats:
 * - `Date`
 * - number: timestamp
 * - string: numeric (e.g. "1234"), ISO and date strings in a format supported by
 *   [Date.parse()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/parse).
 *   Note: ISO strings without time return a date without timeoffset.
 *
 * Throws if unable to convert to a date.
 */
export function toDate(value) {
    if (isDate(value)) {
        return value;
    }
    if (typeof value === 'number' && !isNaN(value)) {
        return new Date(value);
    }
    if (typeof value === 'string') {
        value = value.trim();
        if (/^(\d{4}(-\d{1,2}(-\d{1,2})?)?)$/.test(value)) {
            /* For ISO Strings without time the day, month and year must be extracted from the ISO String
            before Date creation to avoid time offset and errors in the new Date.
            If we only replace '-' with ',' in the ISO String ("2015,01,01"), and try to create a new
            date, some browsers (e.g. IE 9) will throw an invalid Date error.
            If we leave the '-' ("2015-01-01") and try to create a new Date("2015-01-01") the timeoffset
            is applied.
            Note: ISO months are 0 for January, 1 for February, ... */
            const [y, m = 1, d = 1] = value.split('-').map((val) => +val);
            return createDate(y, m - 1, d);
        }
        const parsedNb = parseFloat(value);
        // any string that only contains numbers, like "1234" but not like "1234hello"
        if (!isNaN(value - parsedNb)) {
            return new Date(parsedNb);
        }
        let match;
        if (match = value.match(ISO8601_DATE_REGEX)) {
            return isoStringToDate(match);
        }
    }
    const date = new Date(value);
    if (!isDate(date)) {
        throw new Error(`Unable to convert "${value}" into a date`);
    }
    return date;
}
/**
 * Converts a date in ISO8601 to a Date.
 * Used instead of `Date.parse` because of browser discrepancies.
 */
export function isoStringToDate(match) {
    const date = new Date(0);
    let tzHour = 0;
    let tzMin = 0;
    // match[8] means that the string contains "Z" (UTC) or a timezone like "+01:00" or "+0100"
    const dateSetter = match[8] ? date.setUTCFullYear : date.setFullYear;
    const timeSetter = match[8] ? date.setUTCHours : date.setHours;
    // if there is a timezone defined like "+01:00" or "+0100"
    if (match[9]) {
        tzHour = Number(match[9] + match[10]);
        tzMin = Number(match[9] + match[11]);
    }
    dateSetter.call(date, Number(match[1]), Number(match[2]) - 1, Number(match[3]));
    const h = Number(match[4] || 0) - tzHour;
    const m = Number(match[5] || 0) - tzMin;
    const s = Number(match[6] || 0);
    // The ECMAScript specification (https://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.11)
    // defines that `DateTime` milliseconds should always be rounded down, so that `999.9ms`
    // becomes `999ms`.
    const ms = Math.floor(parseFloat('0.' + (match[7] || 0)) * 1000);
    timeSetter.call(date, h, m, s, ms);
    return date;
}
export function isDate(value) {
    return value instanceof Date && !isNaN(value.valueOf());
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZm9ybWF0X2RhdGUuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi8uLi8uLi8uLi8uLi9wYWNrYWdlcy9jb21tb24vc3JjL2kxOG4vZm9ybWF0X2RhdGUudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLFdBQVcsRUFBRSxTQUFTLEVBQUUsbUJBQW1CLEVBQUUsdUJBQXVCLEVBQUUsaUJBQWlCLEVBQUUsbUJBQW1CLEVBQUUsaUJBQWlCLEVBQUUsNEJBQTRCLEVBQUUsd0JBQXdCLEVBQUUsV0FBVyxFQUFFLG1CQUFtQixFQUFFLHFCQUFxQixFQUFFLG1CQUFtQixFQUFFLFlBQVksRUFBUSxnQkFBZ0IsRUFBQyxNQUFNLG1CQUFtQixDQUFDO0FBRTlVLE1BQU0sQ0FBQyxNQUFNLGtCQUFrQixHQUMzQix1R0FBdUcsQ0FBQztBQUM1RyxnR0FBZ0c7QUFDaEcsTUFBTSxhQUFhLEdBQXFELEVBQUUsQ0FBQztBQUMzRSxNQUFNLGtCQUFrQixHQUNwQixtTkFBbU4sQ0FBQztBQUV4TixJQUFLLFNBS0o7QUFMRCxXQUFLLFNBQVM7SUFDWiwyQ0FBSyxDQUFBO0lBQ0wsaURBQVEsQ0FBQTtJQUNSLHlDQUFJLENBQUE7SUFDSixpREFBUSxDQUFBO0FBQ1YsQ0FBQyxFQUxJLFNBQVMsS0FBVCxTQUFTLFFBS2I7QUFFRCxJQUFLLFFBU0o7QUFURCxXQUFLLFFBQVE7SUFDWCwrQ0FBUSxDQUFBO0lBQ1IseUNBQUssQ0FBQTtJQUNMLHVDQUFJLENBQUE7SUFDSix5Q0FBSyxDQUFBO0lBQ0wsNkNBQU8sQ0FBQTtJQUNQLDZDQUFPLENBQUE7SUFDUCxpRUFBaUIsQ0FBQTtJQUNqQixxQ0FBRyxDQUFBO0FBQ0wsQ0FBQyxFQVRJLFFBQVEsS0FBUixRQUFRLFFBU1o7QUFFRCxJQUFLLGVBS0o7QUFMRCxXQUFLLGVBQWU7SUFDbEIsaUVBQVUsQ0FBQTtJQUNWLHFEQUFJLENBQUE7SUFDSix5REFBTSxDQUFB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ZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7Rm9ybWF0V2lkdGgsIEZvcm1TdHlsZSwgZ2V0TG9jYWxlRGF0ZUZvcm1hdCwgZ2V0TG9jYWxlRGF0ZVRpbWVGb3JtYXQsIGdldExvY2FsZURheU5hbWVzLCBnZXRMb2NhbGVEYXlQZXJpb2RzLCBnZXRMb2NhbGVFcmFOYW1lcywgZ2V0TG9jYWxlRXh0cmFEYXlQZXJpb2RSdWxlcywgZ2V0TG9jYWxlRXh0cmFEYXlQZXJpb2RzLCBnZXRMb2NhbGVJZCwgZ2V0TG9jYWxlTW9udGhOYW1lcywgZ2V0TG9jYWxlTnVtYmVyU3ltYm9sLCBnZXRMb2NhbGVUaW1lRm9ybWF0LCBOdW1iZXJTeW1ib2wsIFRpbWUsIFRyYW5zbGF0aW9uV2lkdGh9IGZyb20gJy4vbG9jYWxlX2RhdGFfYXBpJztcblxuZXhwb3J0IGNvbnN0IElTTzg2MDFfREFURV9SRUdFWCA9XG4gICAgL14oXFxkezQsfSktPyhcXGRcXGQpLT8oXFxkXFxkKSg/OlQoXFxkXFxkKSg/Ojo/KFxcZFxcZCkoPzo6PyhcXGRcXGQpKD86XFwuKFxcZCspKT8pPyk/KFp8KFsrLV0pKFxcZFxcZCk6PyhcXGRcXGQpKT8pPyQvO1xuLy8gICAgMSAgICAgICAgMiAgICAgICAzICAgICAgICAgNCAgICAgICAgICA1ICAgICAgICAgIDYgICAgICAgICAgNyAgICAgICAgICA4ICA5ICAgICAxMCAgICAgIDExXG5jb25zdCBOQU1FRF9GT1JNQVRTOiB7W2xvY2FsZUlkOiBzdHJpbmddOiB7W2Zvcm1hdDogc3RyaW5nXTogc3RyaW5nfX0gPSB7fTtcbmNvbnN0IERBVEVfRk9STUFUU19TUExJVCA9XG4gICAgLygoPzpbXkJFR0hMTU9TV1laYWJjZGhtc3d5eiddKyl8KD86Jyg/OlteJ118JycpKicpfCg/Okd7MSw1fXx5ezEsNH18WXsxLDR9fE17MSw1fXxMezEsNX18d3sxLDJ9fFd7MX18ZHsxLDJ9fEV7MSw2fXxjezEsNn18YXsxLDV9fGJ7MSw1fXxCezEsNX18aHsxLDJ9fEh7MSwyfXxtezEsMn18c3sxLDJ9fFN7MSwzfXx6ezEsNH18WnsxLDV9fE97MSw0fSkpKFtcXHNcXFNdKikvO1xuXG5lbnVtIFpvbmVXaWR0aCB7XG4gIFNob3J0LFxuICBTaG9ydEdNVCxcbiAgTG9uZyxcbiAgRXh0ZW5kZWRcbn1cblxuZW51bSBEYXRlVHlwZSB7XG4gIEZ1bGxZZWFyLFxuICBNb250aCxcbiAgRGF0ZSxcbiAgSG91cnMsXG4gIE1pbnV0ZXMsXG4gIFNlY29uZHMsXG4gIEZyYWN0aW9uYWxTZWNvbmRzLFxuICBEYXlcbn1cblxuZW51bSBUcmFuc2xhdGlvblR5cGUge1xuICBEYXlQZXJpb2RzLFxuICBEYXlzLFxuICBNb250aHMsXG4gIEVyYXNcbn1cblxuLyoqXG4gKiBAbmdNb2R1bGUgQ29tbW9uTW9kdWxlXG4gKiBAZGVzY3JpcHRpb25cbiAqXG4gKiBGb3JtYXRzIGEgZGF0ZSBhY2NvcmRpbmcgdG8gbG9jYWxlIHJ1bGVzLlxuICpcbiAqIEBwYXJhbSB2YWx1ZSBUaGUgZGF0ZSB0byBmb3JtYXQsIGFzIGEgRGF0ZSwgb3IgYSBudW1iZXIgKG1pbGxpc2Vjb25kcyBzaW5jZSBVVEMgZXBvY2gpXG4gKiBvciBhbiBbSVNPIGRhdGUtdGltZSBzdHJpbmddKGh0dHBzOi8vd3d3LnczLm9yZy9UUi9OT1RFLWRhdGV0aW1lKS5cbiAqIEBwYXJhbSBmb3JtYXQgVGhlIGRhdGUtdGltZSBjb21wb25lbnRzIHRvIGluY2x1ZGUuIFNlZSBgRGF0ZVBpcGVgIGZvciBkZXRhaWxzLlxuICogQHBhcmFtIGxvY2FsZSBBIGxvY2FsZSBjb2RlIGZvciB0aGUgbG9jYWxlIGZvcm1hdCBydWxlcyB0byB1c2UuXG4gKiBAcGFyYW0gdGltZXpvbmUgVGhlIHRpbWUgem9uZS4gQSB0aW1lIHpvbmUgb2Zmc2V0IGZyb20gR01UIChzdWNoIGFzIGAnKzA0MzAnYCksXG4gKiBvciBhIHN0YW5kYXJkIFVUQy9HTVQgb3IgY29udGluZW50YWwgVVMgdGltZSB6b25lIGFiYnJldmlhdGlvbi5cbiAqIElmIG5vdCBzcGVjaWZpZWQsIHVzZXMgaG9zdCBzeXN0ZW0gc2V0dGluZ3MuXG4gKlxuICogQHJldHVybnMgVGhlIGZvcm1hdHRlZCBkYXRlIHN0cmluZy5cbiAqXG4gKiBAc2VlIGBEYXRlUGlwZWBcbiAqIEBzZWUgW0ludGVybmF0aW9uYWxpemF0aW9uIChpMThuKSBHdWlkZV0oaHR0cHM6Ly9hbmd1bGFyLmlvL2d1aWRlL2kxOG4tb3ZlcnZpZXcpXG4gKlxuICogQHB1YmxpY0FwaVxuICovXG5leHBvcnQgZnVuY3Rpb24gZm9ybWF0RGF0ZShcbiAgICB2YWx1ZTogc3RyaW5nfG51bWJlcnxEYXRlLCBmb3JtYXQ6IHN0cmluZywgbG9jYWxlOiBzdHJpbmcsIHRpbWV6b25lPzogc3RyaW5nKTogc3RyaW5nIHtcbiAgbGV0IGRhdGUgPSB0b0RhdGUodmFsdWUpO1xuICBjb25zdCBuYW1lZEZvcm1hdCA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgZm9ybWF0KTtcbiAgZm9ybWF0ID0gbmFtZWRGb3JtYXQgfHwgZm9ybWF0O1xuXG4gIGxldCBwYXJ0czogc3RyaW5nW10gPSBbXTtcbiAgbGV0IG1hdGNoO1xuICB3aGlsZSAoZm9ybWF0KSB7XG4gICAgbWF0Y2ggPSBEQVRFX0ZPUk1BVFNfU1BMSVQuZXhlYyhmb3JtYXQpO1xuICAgIGlmIChtYXRjaCkge1xuICAgICAgcGFydHMgPSBwYXJ0cy5jb25jYXQobWF0Y2guc2xpY2UoMSkpO1xuICAgICAgY29uc3QgcGFydCA9IHBhcnRzLnBvcCgpO1xuICAgICAgaWYgKCFwYXJ0KSB7XG4gICAgICAgIGJyZWFrO1xuICAgICAgfVxuICAgICAgZm9ybWF0ID0gcGFydDtcbiAgICB9IGVsc2Uge1xuICAgICAgcGFydHMucHVzaChmb3JtYXQpO1xuICAgICAgYnJlYWs7XG4gICAgfVxuICB9XG5cbiAgbGV0IGRhdGVUaW1lem9uZU9mZnNldCA9IGRhdGUuZ2V0VGltZXpvbmVPZmZzZXQoKTtcbiAgaWYgKHRpbWV6b25lKSB7XG4gICAgZGF0ZVRpbWV6b25lT2Zmc2V0ID0gdGltZXpvbmVUb09mZnNldCh0aW1lem9uZSwgZGF0ZVRpbWV6b25lT2Zmc2V0KTtcbiAgICBkYXRlID0gY29udmVydFRpbWV6b25lVG9Mb2NhbChkYXRlLCB0aW1lem9uZSwgdHJ1ZSk7XG4gIH1cblxuICBsZXQgdGV4dCA9ICcnO1xuICBwYXJ0cy5mb3JFYWNoKHZhbHVlID0+IHtcbiAgICBjb25zdCBkYXRlRm9ybWF0dGVyID0gZ2V0RGF0ZUZvcm1hdHRlcih2YWx1ZSk7XG4gICAgdGV4dCArPSBkYXRlRm9ybWF0dGVyID8gZGF0ZUZvcm1hdHRlcihkYXRlLCBsb2NhbGUsIGRhdGVUaW1lem9uZU9mZnNldCkgOlxuICAgICAgICB2YWx1ZSA9PT0gJ1xcJ1xcJycgID8gJ1xcJycgOlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlLnJlcGxhY2UoLyheJ3wnJCkvZywgJycpLnJlcGxhY2UoLycnL2csICdcXCcnKTtcbiAgfSk7XG5cbiAgcmV0dXJuIHRleHQ7XG59XG5cbi8qKlxuICogQ3JlYXRlIGEgbmV3IERhdGUgb2JqZWN0IHdpdGggdGhlIGdpdmVuIGRhdGUgdmFsdWUsIGFuZCB0aGUgdGltZSBzZXQgdG8gbWlkbmlnaHQuXG4gKlxuICogV2UgY2Fubm90IHVzZSBgbmV3IERhdGUoeWVhciwgbW9udGgsIGRhdGUpYCBiZWNhdXNlIGl0IG1hcHMgeWVhcnMgYmV0d2VlbiAwIGFuZCA5OSB0byAxOTAwLTE5OTkuXG4gKiBTZWU6IGh0dHBzOi8vZ2l0aHViLmNvbS9hbmd1bGFyL2FuZ3VsYXIvaXNzdWVzLzQwMzc3XG4gKlxuICogTm90ZSB0aGF0IHRoaXMgZnVuY3Rpb24gcmV0dXJucyBhIERhdGUgb2JqZWN0IHdob3NlIHRpbWUgaXMgbWlkbmlnaHQgaW4gdGhlIGN1cnJlbnQgbG9jYWxlJ3NcbiAqIHRpbWV6b25lLiBJbiB0aGUgZnV0dXJlIHdlIG1pZ2h0IHdhbnQgdG8gY2hhbmdlIHRoaXMgdG8gYmUgbWlkbmlnaHQgaW4gVVRDLCBidXQgdGhpcyB3b3VsZCBiZSBhXG4gKiBjb25zaWRlcmFibGUgYnJlYWtpbmcgY2hhbmdlLlxuICovXG5mdW5jdGlvbiBjcmVhdGVEYXRlKHllYXI6IG51bWJlciwgbW9udGg6IG51bWJlciwgZGF0ZTogbnVtYmVyKTogRGF0ZSB7XG4gIC8vIFRoZSBgbmV3RGF0ZWAgaXMgc2V0IHRvIG1pZG5pZ2h0IChVVEMpIG9uIEphbnVhcnkgMXN0IDE5NzAuXG4gIC8vIC0gSW4gUFNUIHRoaXMgd2lsbCBiZSBEZWNlbWJlciAzMXN0IDE5NjkgYXQgNHBtLlxuICAvLyAtIEluIEdNVCB0aGlzIHdpbGwgYmUgSmFudWFyeSAxc3QgMTk3MCBhdCAxYW0uXG4gIC8vIE5vdGUgdGhhdCB0aGV5IGV2ZW4gaGF2ZSBkaWZmZXJlbnQgeWVhcnMsIGRhdGVzIGFuZCBtb250aHMhXG4gIGNvbnN0IG5ld0RhdGUgPSBuZXcgRGF0ZSgwKTtcblxuICAvLyBgc2V0RnVsbFllYXIoKWAgYWxsb3dzIHllYXJzIGxpa2UgMDAwMSB0byBiZSBzZXQgY29ycmVjdGx5LiBUaGlzIGZ1bmN0aW9uIGRvZXMgbm90XG4gIC8vIGNoYW5nZSB0aGUgaW50ZXJuYWwgdGltZSBvZiB0aGUgZGF0ZS5cbiAgLy8gQ29uc2lkZXIgY2FsbGluZyBgc2V0RnVsbFllYXIoMjAxOSwgOCwgMjApYCAoU2VwdGVtYmVyIDIwLCAyMDE5KS5cbiAgLy8gLSBJbiBQU1QgdGhpcyB3aWxsIG5vdyBiZSBTZXB0ZW1iZXIgMjAsIDIwMTkgYXQgNHBtXG4gIC8vIC0gSW4gR01UIHRoaXMgd2lsbCBub3cgYmUgU2VwdGVtYmVyIDIwLCAyMDE5IGF0IDFhbVxuXG4gIG5ld0RhdGUuc2V0RnVsbFllYXIoeWVhciwgbW9udGgsIGRhdGUpO1xuICAvLyBXZSB3YW50IHRoZSBmaW5hbCBkYXRlIHRvIGJlIGF0IGxvY2FsIG1pZG5pZ2h0LCBzbyB3ZSByZXNldCB0aGUgdGltZS5cbiAgLy8gLSBJbiBQU1QgdGhpcyB3aWxsIG5vdyBiZSBTZXB0ZW1iZXIgMjAsIDIwMTkgYXQgMTJhbVxuICAvLyAtIEluIEdNVCB0aGlzIHdpbGwgbm93IGJlIFNlcHRlbWJlciAyMCwgMjAxOSBhdCAxMmFtXG4gIG5ld0RhdGUuc2V0SG91cnMoMCwgMCwgMCk7XG5cbiAgcmV0dXJuIG5ld0RhdGU7XG59XG5cbmZ1bmN0aW9uIGdldE5hbWVkRm9ybWF0KGxvY2FsZTogc3RyaW5nLCBmb3JtYXQ6IHN0cmluZyk6IHN0cmluZyB7XG4gIGNvbnN0IGxvY2FsZUlkID0gZ2V0TG9jYWxlSWQobG9jYWxlKTtcbiAgTkFNRURfRk9STUFUU1tsb2NhbGVJZF0gPSBOQU1FRF9GT1JNQVRTW2xvY2FsZUlkXSB8fCB7fTtcblxuICBpZiAoTkFNRURfRk9STUFUU1tsb2NhbGVJZF1bZm9ybWF0XSkge1xuICAgIHJldHVybiBOQU1FRF9GT1JNQVRTW2xvY2FsZUlkXVtmb3JtYXRdO1xuICB9XG5cbiAgbGV0IGZvcm1hdFZhbHVlID0gJyc7XG4gIHN3aXRjaCAoZm9ybWF0KSB7XG4gICAgY2FzZSAnc2hvcnREYXRlJzpcbiAgICAgIGZvcm1hdFZhbHVlID0gZ2V0TG9jYWxlRGF0ZUZvcm1hdChsb2NhbGUsIEZvcm1hdFdpZHRoLlNob3J0KTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ21lZGl1bURhdGUnOlxuICAgICAgZm9ybWF0VmFsdWUgPSBnZXRMb2NhbGVEYXRlRm9ybWF0KGxvY2FsZSwgRm9ybWF0V2lkdGguTWVkaXVtKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ2xvbmdEYXRlJzpcbiAgICAgIGZvcm1hdFZhbHVlID0gZ2V0TG9jYWxlRGF0ZUZvcm1hdChsb2NhbGUsIEZvcm1hdFdpZHRoLkxvbmcpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnZnVsbERhdGUnOlxuICAgICAgZm9ybWF0VmFsdWUgPSBnZXRMb2NhbGVEYXRlRm9ybWF0KGxvY2FsZSwgRm9ybWF0V2lkdGguRnVsbCk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdzaG9ydFRpbWUnOlxuICAgICAgZm9ybWF0VmFsdWUgPSBnZXRMb2NhbGVUaW1lRm9ybWF0KGxvY2FsZSwgRm9ybWF0V2lkdGguU2hvcnQpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnbWVkaXVtVGltZSc6XG4gICAgICBmb3JtYXRWYWx1ZSA9IGdldExvY2FsZVRpbWVGb3JtYXQobG9jYWxlLCBGb3JtYXRXaWR0aC5NZWRpdW0pO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnbG9uZ1RpbWUnOlxuICAgICAgZm9ybWF0VmFsdWUgPSBnZXRMb2NhbGVUaW1lRm9ybWF0KGxvY2FsZSwgRm9ybWF0V2lkdGguTG9uZyk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdmdWxsVGltZSc6XG4gICAgICBmb3JtYXRWYWx1ZSA9IGdldExvY2FsZVRpbWVGb3JtYXQobG9jYWxlLCBGb3JtYXRXaWR0aC5GdWxsKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ3Nob3J0JzpcbiAgICAgIGNvbnN0IHNob3J0VGltZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ3Nob3J0VGltZScpO1xuICAgICAgY29uc3Qgc2hvcnREYXRlID0gZ2V0TmFtZWRGb3JtYXQobG9jYWxlLCAnc2hvcnREYXRlJyk7XG4gICAgICBmb3JtYXRWYWx1ZSA9IGZvcm1hdERhdGVUaW1lKFxuICAgICAgICAgIGdldExvY2FsZURhdGVUaW1lRm9ybWF0KGxvY2FsZSwgRm9ybWF0V2lkdGguU2hvcnQpLCBbc2hvcnRUaW1lLCBzaG9ydERhdGVdKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ21lZGl1bSc6XG4gICAgICBjb25zdCBtZWRpdW1UaW1lID0gZ2V0TmFtZWRGb3JtYXQobG9jYWxlLCAnbWVkaXVtVGltZScpO1xuICAgICAgY29uc3QgbWVkaXVtRGF0ZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ21lZGl1bURhdGUnKTtcbiAgICAgIGZvcm1hdFZhbHVlID0gZm9ybWF0RGF0ZVRpbWUoXG4gICAgICAgICAgZ2V0TG9jYWxlRGF0ZVRpbWVGb3JtYXQobG9jYWxlLCBGb3JtYXRXaWR0aC5NZWRpdW0pLCBbbWVkaXVtVGltZSwgbWVkaXVtRGF0ZV0pO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnbG9uZyc6XG4gICAgICBjb25zdCBsb25nVGltZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ2xvbmdUaW1lJyk7XG4gICAgICBjb25zdCBsb25nRGF0ZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ2xvbmdEYXRlJyk7XG4gICAgICBmb3JtYXRWYWx1ZSA9XG4gICAgICAgICAgZm9ybWF0RGF0ZVRpbWUoZ2V0TG9jYWxlRGF0ZVRpbWVGb3JtYXQobG9jYWxlLCBGb3JtYXRXaWR0aC5Mb25nKSwgW2xvbmdUaW1lLCBsb25nRGF0ZV0pO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnZnVsbCc6XG4gICAgICBjb25zdCBmdWxsVGltZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ2Z1bGxUaW1lJyk7XG4gICAgICBjb25zdCBmdWxsRGF0ZSA9IGdldE5hbWVkRm9ybWF0KGxvY2FsZSwgJ2Z1bGxEYXRlJyk7XG4gICAgICBmb3JtYXRWYWx1ZSA9XG4gICAgICAgICAgZm9ybWF0RGF0ZVRpbWUoZ2V0TG9jYWxlRGF0ZVRpbWVGb3JtYXQobG9jYWxlLCBGb3JtYXRXaWR0aC5GdWxsKSwgW2Z1bGxUaW1lLCBmdWxsRGF0ZV0pO1xuICAgICAgYnJlYWs7XG4gIH1cbiAgaWYgKGZvcm1hdFZhbHVlKSB7XG4gICAgTkFNRURfRk9STUFUU1tsb2NhbGVJZF1bZm9ybWF0XSA9IGZvcm1hdFZhbHVlO1xuICB9XG4gIHJldHVybiBmb3JtYXRWYWx1ZTtcbn1cblxuZnVuY3Rpb24gZm9ybWF0RGF0ZVRpbWUoc3RyOiBzdHJpbmcsIG9wdF92YWx1ZXM6IHN0cmluZ1tdKSB7XG4gIGlmIChvcHRfdmFsdWVzKSB7XG4gICAgc3RyID0gc3RyLnJlcGxhY2UoL1xceyhbXn1dKyl9L2csIGZ1bmN0aW9uKG1hdGNoLCBrZXkpIHtcbiAgICAgIHJldHVybiAob3B0X3ZhbHVlcyAhPSBudWxsICYmIGtleSBpbiBvcHRfdmFsdWVzKSA/IG9wdF92YWx1ZXNba2V5XSA6IG1hdGNoO1xuICAgIH0pO1xuICB9XG4gIHJldHVybiBzdHI7XG59XG5cbmZ1bmN0aW9uIHBhZE51bWJlcihcbiAgICBudW06IG51bWJlciwgZGlnaXRzOiBudW1iZXIsIG1pbnVzU2lnbiA9ICctJywgdHJpbT86IGJvb2xlYW4sIG5lZ1dyYXA/OiBib29sZWFuKTogc3RyaW5nIHtcbiAgbGV0IG5lZyA9ICcnO1xuICBpZiAobnVtIDwgMCB8fCAobmVnV3JhcCAmJiBudW0gPD0gMCkpIHtcbiAgICBpZiAobmVnV3JhcCkge1xuICAgICAgbnVtID0gLW51bSArIDE7XG4gICAgfSBlbHNlIHtcbiAgICAgIG51bSA9IC1udW07XG4gICAgICBuZWcgPSBtaW51c1NpZ247XG4gICAgfVxuICB9XG4gIGxldCBzdHJOdW0gPSBTdHJpbmcobnVtKTtcbiAgd2hpbGUgKHN0ck51bS5sZW5ndGggPCBkaWdpdHMpIHtcbiAgICBzdHJOdW0gPSAnMCcgKyBzdHJOdW07XG4gIH1cbiAgaWYgKHRyaW0pIHtcbiAgICBzdHJOdW0gPSBzdHJOdW0uc2xpY2Uoc3RyTnVtLmxlbmd0aCAtIGRpZ2l0cyk7XG4gIH1cbiAgcmV0dXJuIG5lZyArIHN0ck51bTtcbn1cblxuZnVuY3Rpb24gZm9ybWF0RnJhY3Rpb25hbFNlY29uZHMobWlsbGlzZWNvbmRzOiBudW1iZXIsIGRpZ2l0czogbnVtYmVyKTogc3RyaW5nIHtcbiAgY29uc3Qgc3RyTXMgPSBwYWROdW1iZXIobWlsbGlzZWNvbmRzLCAzKTtcbiAgcmV0dXJuIHN0ck1zLnN1YnN0cmluZygwLCBkaWdpdHMpO1xufVxuXG4vKipcbiAqIFJldHVybnMgYSBkYXRlIGZvcm1hdHRlciB0aGF0IHRyYW5zZm9ybXMgYSBkYXRlIGludG8gaXRzIGxvY2FsZSBkaWdpdCByZXByZXNlbnRhdGlvblxuICovXG5mdW5jdGlvbiBkYXRlR2V0dGVyKFxuICAgIG5hbWU6IERhdGVUeXBlLCBzaXplOiBudW1iZXIsIG9mZnNldDogbnVtYmVyID0gMCwgdHJpbSA9IGZhbHNlLFxuICAgIG5lZ1dyYXAgPSBmYWxzZSk6IERhdGVGb3JtYXR0ZXIge1xuICByZXR1cm4gZnVuY3Rpb24oZGF0ZTogRGF0ZSwgbG9jYWxlOiBzdHJpbmcpOiBzdHJpbmcge1xuICAgIGxldCBwYXJ0ID0gZ2V0RGF0ZVBhcnQobmFtZSwgZGF0ZSk7XG4gICAgaWYgKG9mZnNldCA+IDAgfHwgcGFydCA+IC1vZmZzZXQpIHtcbiAgICAgIHBhcnQgKz0gb2Zmc2V0O1xuICAgIH1cblxuICAgIGlmIChuYW1lID09PSBEYXRlVHlwZS5Ib3Vycykge1xuICAgICAgaWYgKHBhcnQgPT09IDAgJiYgb2Zmc2V0ID09PSAtMTIpIHtcbiAgICAgICAgcGFydCA9IDEyO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZiAobmFtZSA9PT0gRGF0ZVR5cGUuRnJhY3Rpb25hbFNlY29uZHMpIHtcbiAgICAgIHJldHVybiBmb3JtYXRGcmFjdGlvbmFsU2Vjb25kcyhwYXJ0LCBzaXplKTtcbiAgICB9XG5cbiAgICBjb25zdCBsb2NhbGVNaW51cyA9IGdldExvY2FsZU51bWJlclN5bWJvbChsb2NhbGUsIE51bWJlclN5bWJvbC5NaW51c1NpZ24pO1xuICAgIHJldHVybiBwYWROdW1iZXIocGFydCwgc2l6ZSwgbG9jYWxlTWludXMsIHRyaW0sIG5lZ1dyYXApO1xuICB9O1xufVxuXG5mdW5jdGlvbiBnZXREYXRlUGFydChwYXJ0OiBEYXRlVHlwZSwgZGF0ZTogRGF0ZSk6IG51bWJlciB7XG4gIHN3aXRjaCAocGFydCkge1xuICAgIGNhc2UgRGF0ZVR5cGUuRnVsbFllYXI6XG4gICAgICByZXR1cm4gZGF0ZS5nZXRGdWxsWWVhcigpO1xuICAgIGNhc2UgRGF0ZVR5cGUuTW9udGg6XG4gICAgICByZXR1cm4gZGF0ZS5nZXRNb250aCgpO1xuICAgIGNhc2UgRGF0ZVR5cGUuRGF0ZTpcbiAgICAgIHJldHVybiBkYXRlLmdldERhdGUoKTtcbiAgICBjYXNlIERhdGVUeXBlLkhvdXJzOlxuICAgICAgcmV0dXJuIGRhdGUuZ2V0SG91cnMoKTtcbiAgICBjYXNlIERhdGVUeXBlLk1pbnV0ZXM6XG4gICAgICByZXR1cm4gZGF0ZS5nZXRNaW51dGVzKCk7XG4gICAgY2FzZSBEYXRlVHlwZS5TZWNvbmRzOlxuICAgICAgcmV0dXJuIGRhdGUuZ2V0U2Vjb25kcygpO1xuICAgIGNhc2UgRGF0ZVR5cGUuRnJhY3Rpb25hbFNlY29uZHM6XG4gICAgICByZXR1cm4gZGF0ZS5nZXRNaWxsaXNlY29uZHMoKTtcbiAgICBjYXNlIERhdGVUeXBlLkRheTpcbiAgICAgIHJldHVybiBkYXRlLmdldERheSgpO1xuICAgIGRlZmF1bHQ6XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYFVua25vd24gRGF0ZVR5cGUgdmFsdWUgXCIke3BhcnR9XCIuYCk7XG4gIH1cbn1cblxuLyoqXG4gKiBSZXR1cm5zIGEgZGF0ZSBmb3JtYXR0ZXIgdGhhdCB0cmFuc2Zvcm1zIGEgZGF0ZSBpbnRvIGl0cyBsb2NhbGUgc3RyaW5nIHJlcHJlc2VudGF0aW9uXG4gKi9cbmZ1bmN0aW9uIGRhdGVTdHJHZXR0ZXIoXG4gICAgbmFtZTogVHJhbnNsYXRpb25UeXBlLCB3aWR0aDogVHJhbnNsYXRpb25XaWR0aCwgZm9ybTogRm9ybVN0eWxlID0gRm9ybVN0eWxlLkZvcm1hdCxcbiAgICBleHRlbmRlZCA9IGZhbHNlKTogRGF0ZUZvcm1hdHRlciB7XG4gIHJldHVybiBmdW5jdGlvbihkYXRlOiBEYXRlLCBsb2NhbGU6IHN0cmluZyk6IHN0cmluZyB7XG4gICAgcmV0dXJuIGdldERhdGVUcmFuc2xhdGlvbihkYXRlLCBsb2NhbGUsIG5hbWUsIHdpZHRoLCBmb3JtLCBleHRlbmRlZCk7XG4gIH07XG59XG5cbi8qKlxuICogUmV0dXJucyB0aGUgbG9jYWxlIHRyYW5zbGF0aW9uIG9mIGEgZGF0ZSBmb3IgYSBnaXZlbiBmb3JtLCB0eXBlIGFuZCB3aWR0aFxuICovXG5mdW5jdGlvbiBnZXREYXRlVHJhbnNsYXRpb24oXG4gICAgZGF0ZTogRGF0ZSwgbG9jYWxlOiBzdHJpbmcsIG5hbWU6IFRyYW5zbGF0aW9uVHlwZSwgd2lkdGg6IFRyYW5zbGF0aW9uV2lkdGgsIGZvcm06IEZvcm1TdHlsZSxcbiAgICBleHRlbmRlZDogYm9vbGVhbikge1xuICBzd2l0Y2ggKG5hbWUpIHtcbiAgICBjYXNlIFRyYW5zbGF0aW9uVHlwZS5Nb250aHM6XG4gICAgICByZXR1cm4gZ2V0TG9jYWxlTW9udGhOYW1lcyhsb2NhbGUsIGZvcm0sIHdpZHRoKVtkYXRlLmdldE1vbnRoKCldO1xuICAgIGNhc2UgVHJhbnNsYXRpb25UeXBlLkRheXM6XG4gICAgICByZXR1cm4gZ2V0TG9jYWxlRGF5TmFtZXMobG9jYWxlLCBmb3JtLCB3aWR0aClbZGF0ZS5nZXREYXkoKV07XG4gICAgY2FzZSBUcmFuc2xhdGlvblR5cGUuRGF5UGVyaW9kczpcbiAgICAgIGNvbnN0IGN1cnJlbnRIb3VycyA9IGRhdGUuZ2V0SG91cnMoKTtcbiAgICAgIGNvbnN0IGN1cnJlbnRNaW51dGVzID0gZGF0ZS5nZXRNaW51dGVzKCk7XG4gICAgICBpZiAoZXh0ZW5kZWQpIHtcbiAgICAgICAgY29uc3QgcnVsZXMgPSBnZXRMb2NhbGVFeHRyYURheVBlcmlvZFJ1bGVzKGxvY2FsZSk7XG4gICAgICAgIGNvbnN0IGRheVBlcmlvZHMgPSBnZXRMb2NhbGVFeHRyYURheVBlcmlvZHMobG9jYWxlLCBmb3JtLCB3aWR0aCk7XG4gICAgICAgIGNvbnN0IGluZGV4ID0gcnVsZXMuZmluZEluZGV4KHJ1bGUgPT4ge1xuICAgICAgICAgIGlmIChBcnJheS5pc0FycmF5KHJ1bGUpKSB7XG4gICAgICAgICAgICAvLyBtb3JuaW5nLCBhZnRlcm5vb24sIGV2ZW5pbmcsIG5pZ2h0XG4gICAgICAgICAgICBjb25zdCBbZnJvbSwgdG9dID0gcnVsZTtcbiAgICAgICAgICAgIGNvbnN0IGFmdGVyRnJvbSA9IGN1cnJlbnRIb3VycyA+PSBmcm9tLmhvdXJzICYmIGN1cnJlbnRNaW51dGVzID49IGZyb20ubWludXRlcztcbiAgICAgICAgICAgIGNvbnN0IGJlZm9yZVRvID1cbiAgICAgICAgICAgICAgICAoY3VycmVudEhvdXJzIDwgdG8uaG91cnMgfHxcbiAgICAgICAgICAgICAgICAgKGN1cnJlbnRIb3VycyA9PT0gdG8uaG91cnMgJiYgY3VycmVudE1pbnV0ZXMgPCB0by5taW51dGVzKSk7XG4gICAgICAgICAgICAvLyBXZSBtdXN0IGFjY291bnQgZm9yIG5vcm1hbCBydWxlcyB0aGF0IHNwYW4gYSBwZXJpb2QgZHVyaW5nIHRoZSBkYXkgKGUuZy4gNmFtLTlhbSlcbiAgICAgICAgICAgIC8vIHdoZXJlIGBmcm9tYCBpcyBsZXNzIChlYXJsaWVyKSB0aGFuIGB0b2AuIEJ1dCBhbHNvIHJ1bGVzIHRoYXQgc3BhbiBtaWRuaWdodCAoZS5nLlxuICAgICAgICAgICAgLy8gMTBwbSAtIDVhbSkgd2hlcmUgYGZyb21gIGlzIGdyZWF0ZXIgKGxhdGVyISkgdGhhbiBgdG9gLlxuICAgICAgICAgICAgLy9cbiAgICAgICAgICAgIC8vIEluIHRoZSBmaXJzdCBjYXNlIHRoZSBjdXJyZW50IHRpbWUgbXVzdCBiZSBCT1RIIGFmdGVyIGBmcm9tYCBBTkQgYmVmb3JlIGB0b2BcbiAgICAgICAgICAgIC8vIChlLmcuIDhhbSBpcyBhZnRlciA2YW0gQU5EIGJlZm9yZSAxMGFtKS5cbiAgICAgICAgICAgIC8vXG4gICAgICAgICAgICAvLyBJbiB0aGUgc2Vjb25kIGNhc2UgdGhlIGN1cnJlbnQgdGltZSBtdXN0IGJlIEVJVEhFUiBhZnRlciBgZnJvbWAgT1IgYmVmb3JlIGB0b2BcbiAgICAgICAgICAgIC8vIChlLmcuIDRhbSBpcyBiZWZvcmUgNWFtIGJ1dCBub3QgYWZ0ZXIgMTBwbTsgYW5kIDExcG0gaXMgbm90IGJlZm9yZSA1YW0gYnV0IGl0IGlzXG4gICAgICAgICAgICAvLyBhZnRlciAxMHBtKS5cbiAgICAgICAgICAgIGlmIChmcm9tLmhvdXJzIDwgdG8uaG91cnMpIHtcbiAgICAgICAgICAgICAgaWYgKGFmdGVyRnJvbSAmJiBiZWZvcmVUbykge1xuICAgICAgICAgICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9IGVsc2UgaWYgKGFmdGVyRnJvbSB8fCBiZWZvcmVUbykge1xuICAgICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9IGVsc2UgeyAgLy8gbm9vbiBvciBtaWRuaWdodFxuICAgICAgICAgICAgaWYgKHJ1bGUuaG91cnMgPT09IGN1cnJlbnRIb3VycyAmJiBydWxlLm1pbnV0ZXMgPT09IGN1cnJlbnRNaW51dGVzKSB7XG4gICAgICAgICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgIH0pO1xuICAgICAgICBpZiAoaW5kZXggIT09IC0xKSB7XG4gICAgICAgICAgcmV0dXJuIGRheVBlcmlvZHNbaW5kZXhdO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgICAvLyBpZiBubyBydWxlcyBmb3IgdGhlIGRheSBwZXJpb2RzLCB3ZSB1c2UgYW0vcG0gYnkgZGVmYXVsdFxuICAgICAgcmV0dXJuIGdldExvY2FsZURheVBlcmlvZHMobG9jYWxlLCBmb3JtLCA8VHJhbnNsYXRpb25XaWR0aD53aWR0aClbY3VycmVudEhvdXJzIDwgMTIgPyAwIDogMV07XG4gICAgY2FzZSBUcmFuc2xhdGlvblR5cGUuRXJhczpcbiAgICAgIHJldHVybiBnZXRMb2NhbGVFcmFOYW1lcyhsb2NhbGUsIDxUcmFuc2xhdGlvbldpZHRoPndpZHRoKVtkYXRlLmdldEZ1bGxZZWFyKCkgPD0gMCA/IDAgOiAxXTtcbiAgICBkZWZhdWx0OlxuICAgICAgLy8gVGhpcyBkZWZhdWx0IGNhc2UgaXMgbm90IG5lZWRlZCBieSBUeXBlU2NyaXB0IGNvbXBpbGVyLCBhcyB0aGUgc3dpdGNoIGlzIGV4aGF1c3RpdmUuXG4gICAgICAvLyBIb3dldmVyIENsb3N1cmUgQ29tcGlsZXIgZG9lcyBub3QgdW5kZXJzdGFuZCB0aGF0IGFuZCByZXBvcnRzIGFuIGVycm9yIGluIHR5cGVkIG1vZGUuXG4gICAgICAvLyBUaGUgYHRocm93IG5ldyBFcnJvcmAgYmVsb3cgd29ya3MgYXJvdW5kIHRoZSBwcm9ibGVtLCBhbmQgdGhlIHVuZXhwZWN0ZWQ6IG5ldmVyIHZhcmlhYmxlXG4gICAgICAvLyBtYWtlcyBzdXJlIHRzYyBzdGlsbCBjaGVja3MgdGhpcyBjb2RlIGlzIHVucmVhY2hhYmxlLlxuICAgICAgY29uc3QgdW5leHBlY3RlZDogbmV2ZXIgPSBuYW1lO1xuICAgICAgdGhyb3cgbmV3IEVycm9yKGB1bmV4cGVjdGVkIHRyYW5zbGF0aW9uIHR5cGUgJHt1bmV4cGVjdGVkfWApO1xuICB9XG59XG5cbi8qKlxuICogUmV0dXJucyBhIGRhdGUgZm9ybWF0dGVyIHRoYXQgdHJhbnNmb3JtcyBhIGRhdGUgYW5kIGFuIG9mZnNldCBpbnRvIGEgdGltZXpvbmUgd2l0aCBJU084NjAxIG9yXG4gKiBHTVQgZm9ybWF0IGRlcGVuZGluZyBvbiB0aGUgd2lkdGggKGVnOiBzaG9ydCA9ICswNDMwLCBzaG9ydDpHTVQgPSBHTVQrNCwgbG9uZyA9IEdNVCswNDozMCxcbiAqIGV4dGVuZGVkID0gKzA0OjMwKVxuICovXG5mdW5jdGlvbiB0aW1lWm9uZUdldHRlcih3aWR0aDogWm9uZVdpZHRoKTogRGF0ZUZvcm1hdHRlciB7XG4gIHJldHVybiBmdW5jdGlvbihkYXRlOiBEYXRlLCBsb2NhbGU6IHN0cmluZywgb2Zmc2V0OiBudW1iZXIpIHtcbiAgICBjb25zdCB6b25lID0gLTEgKiBvZmZzZXQ7XG4gICAgY29uc3QgbWludXNTaWduID0gZ2V0TG9jYWxlTnVtYmVyU3ltYm9sKGxvY2FsZSwgTnVtYmVyU3ltYm9sLk1pbnVzU2lnbik7XG4gICAgY29uc3QgaG91cnMgPSB6b25lID4gMCA/IE1hdGguZmxvb3Ioem9uZSAvIDYwKSA6IE1hdGguY2VpbCh6b25lIC8gNjApO1xuICAgIHN3aXRjaCAod2lkdGgpIHtcbiAgICAgIGNhc2UgWm9uZVdpZHRoLlNob3J0OlxuICAgICAgICByZXR1cm4gKCh6b25lID49IDApID8gJysnIDogJycpICsgcGFkTnVtYmVyKGhvdXJzLCAyLCBtaW51c1NpZ24pICtcbiAgICAgICAgICAgIHBhZE51bWJlcihNYXRoLmFicyh6b25lICUgNjApLCAyLCBtaW51c1NpZ24pO1xuICAgICAgY2FzZSBab25lV2lkdGguU2hvcnRHTVQ6XG4gICAgICAgIHJldHVybiAnR01UJyArICgoem9uZSA+PSAwKSA/ICcrJyA6ICcnKSArIHBhZE51bWJlcihob3VycywgMSwgbWludXNTaWduKTtcbiAgICAgIGNhc2UgWm9uZVdpZHRoLkxvbmc6XG4gICAgICAgIHJldHVybiAnR01UJyArICgoem9uZSA+PSAwKSA/ICcrJyA6ICcnKSArIHBhZE51bWJlcihob3VycywgMiwgbWludXNTaWduKSArICc6JyArXG4gICAgICAgICAgICBwYWROdW1iZXIoTWF0aC5hYnMoem9uZSAlIDYwKSwgMiwgbWludXNTaWduKTtcbiAgICAgIGNhc2UgWm9uZVdpZHRoLkV4dGVuZGVkOlxuICAgICAgICBpZiAob2Zmc2V0ID09PSAwKSB7XG4gICAgICAgICAgcmV0dXJuICdaJztcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICByZXR1cm4gKCh6b25lID49IDApID8gJysnIDogJycpICsgcGFkTnVtYmVyKGhvdXJzLCAyLCBtaW51c1NpZ24pICsgJzonICtcbiAgICAgICAgICAgICAgcGFkTnVtYmVyKE1hdGguYWJzKHpvbmUgJSA2MCksIDIsIG1pbnVzU2lnbik7XG4gICAgICAgIH1cbiAgICAgIGRlZmF1bHQ6XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihgVW5rbm93biB6b25lIHdpZHRoIFwiJHt3aWR0aH1cImApO1xuICAgIH1cbiAgfTtcbn1cblxuY29uc3QgSkFOVUFSWSA9IDA7XG5jb25zdCBUSFVSU0RBWSA9IDQ7XG5mdW5jdGlvbiBnZXRGaXJzdFRodXJzZGF5T2ZZZWFyKHllYXI6IG51bWJlcikge1xuICBjb25zdCBmaXJzdERheU9mWWVhciA9IGNyZWF0ZURhdGUoeWVhciwgSkFOVUFSWSwgMSkuZ2V0RGF5KCk7XG4gIHJldHVybiBjcmVhdGVEYXRlKFxuICAgICAgeWVhciwgMCwgMSArICgoZmlyc3REYXlPZlllYXIgPD0gVEhVUlNEQVkpID8gVEhVUlNEQVkgOiBUSFVSU0RBWSArIDcpIC0gZmlyc3REYXlPZlllYXIpO1xufVxuXG5mdW5jdGlvbiBnZXRUaHVyc2RheVRoaXNXZWVrKGRhdGV0aW1lOiBEYXRlKSB7XG4gIHJldHVybiBjcmVhdGVEYXRlKFxuICAgICAgZGF0ZXRpbWUuZ2V0RnVsbFllYXIoKSwgZGF0ZXRpbWUuZ2V0TW9udGgoKSxcbiAgICAgIGRhdGV0aW1lLmdldERhdGUoKSArIChUSFVSU0RBWSAtIGRhdGV0aW1lLmdldERheSgpKSk7XG59XG5cbmZ1bmN0aW9uIHdlZWtHZXR0ZXIoc2l6ZTogbnVtYmVyLCBtb250aEJhc2VkID0gZmFsc2UpOiBEYXRlRm9ybWF0dGVyIHtcbiAgcmV0dXJuIGZ1bmN0aW9uKGRhdGU6IERhdGUsIGxvY2FsZTogc3RyaW5nKSB7XG4gICAgbGV0IHJlc3VsdDtcbiAgICBpZiAobW9udGhCYXNlZCkge1xuICAgICAgY29uc3QgbmJEYXlzQmVmb3JlMXN0RGF5T2ZNb250aCA9XG4gICAgICAgICAgbmV3IERhdGUoZGF0ZS5nZXRGdWxsWWVhcigpLCBkYXRlLmdldE1vbnRoKCksIDEpLmdldERheSgpIC0gMTtcbiAgICAgIGNvbnN0IHRvZGF5ID0gZGF0ZS5nZXREYXRlKCk7XG4gICAgICByZXN1bHQgPSAxICsgTWF0aC5mbG9vcigodG9kYXkgKyBuYkRheXNCZWZvcmUxc3REYXlPZk1vbnRoKSAvIDcpO1xuICAgIH0gZWxzZSB7XG4gICAgICBjb25zdCB0aGlzVGh1cnMgPSBnZXRUaHVyc2RheVRoaXNXZWVrKGRhdGUpO1xuICAgICAgLy8gU29tZSBkYXlzIG9mIGEgeWVhciBhcmUgcGFydCBvZiBuZXh0IHllYXIgYWNjb3JkaW5nIHRvIElTTyA4NjAxLlxuICAgICAgLy8gQ29tcHV0ZSB0aGUgZmlyc3RUaHVycyBmcm9tIHRoZSB5ZWFyIG9mIHRoaXMgd2VlaydzIFRodXJzZGF5XG4gICAgICBjb25zdCBmaXJzdFRodXJzID0gZ2V0Rmlyc3RUaHVyc2RheU9mWWVhcih0aGlzVGh1cnMuZ2V0RnVsbFllYXIoKSk7XG4gICAgICBjb25zdCBkaWZmID0gdGhpc1RodXJzLmdldFRpbWUoKSAtIGZpcnN0VGh1cnMuZ2V0VGltZSgpO1xuICAgICAgcmVzdWx0ID0gMSArIE1hdGgucm91bmQoZGlmZiAvIDYuMDQ4ZTgpOyAgLy8gNi4wNDhlOCBtcyBwZXIgd2Vla1xuICAgIH1cblxuICAgIHJldHVybiBwYWROdW1iZXIocmVzdWx0LCBzaXplLCBnZXRMb2NhbGVOdW1iZXJTeW1ib2wobG9jYWxlLCBOdW1iZXJTeW1ib2wuTWludXNTaWduKSk7XG4gIH07XG59XG5cbi8qKlxuICogUmV0dXJucyBhIGRhdGUgZm9ybWF0dGVyIHRoYXQgcHJvdmlkZXMgdGhlIHdlZWstbnVtYmVyaW5nIHllYXIgZm9yIHRoZSBpbnB1dCBkYXRlLlxuICovXG5mdW5jdGlvbiB3ZWVrTnVtYmVyaW5nWWVhckdldHRlcihzaXplOiBudW1iZXIsIHRyaW0gPSBmYWxzZSk6IERhdGVGb3JtYXR0ZXIge1xuICByZXR1cm4gZnVuY3Rpb24oZGF0ZTogRGF0ZSwgbG9jYWxlOiBzdHJpbmcpIHtcbiAgICBjb25zdCB0aGlzVGh1cnMgPSBnZXRUaHVyc2RheVRoaXNXZWVrKGRhdGUpO1xuICAgIGNvbnN0IHdlZWtOdW1iZXJpbmdZZWFyID0gdGhpc1RodXJzLmdldEZ1bGxZZWFyKCk7XG4gICAgcmV0dXJuIHBhZE51bWJlcihcbiAgICAgICAgd2Vla051bWJlcmluZ1llYXIsIHNpemUsIGdldExvY2FsZU51bWJlclN5bWJvbChsb2NhbGUsIE51bWJlclN5bWJvbC5NaW51c1NpZ24pLCB0cmltKTtcbiAgfTtcbn1cblxudHlwZSBEYXRlRm9ybWF0dGVyID0gKGRhdGU6IERhdGUsIGxvY2FsZTogc3RyaW5nLCBvZmZzZXQ6IG51bWJlcikgPT4gc3RyaW5nO1xuXG5jb25zdCBEQVRFX0ZPUk1BVFM6IHtbZm9ybWF0OiBzdHJpbmddOiBEYXRlRm9ybWF0dGVyfSA9IHt9O1xuXG4vLyBCYXNlZCBvbiBDTERSIGZvcm1hdHM6XG4vLyBTZWUgY29tcGxldGUgbGlzdDogaHR0cDovL3d3dy51bmljb2RlLm9yZy9yZXBvcnRzL3RyMzUvdHIzNS1kYXRlcy5odG1sI0RhdGVfRmllbGRfU3ltYm9sX1RhYmxlXG4vLyBTZWUgYWxzbyBleHBsYW5hdGlvbnM6IGh0dHA6Ly9jbGRyLnVuaWNvZGUub3JnL3RyYW5zbGF0aW9uL2RhdGUtdGltZVxuLy8gVE9ETyhvY29tYmUpOiBzdXBwb3J0IGFsbCBtaXNzaW5nIGNsZHIgZm9ybWF0czogVSwgUSwgRCwgRiwgZSwgaiwgSiwgQywgQSwgdiwgViwgWCwgeFxuZnVuY3Rpb24gZ2V0RGF0ZUZvcm1hdHRlcihmb3JtYXQ6IHN0cmluZyk6IERhdGVGb3JtYXR0ZXJ8bnVsbCB7XG4gIGlmIChEQVRFX0ZPUk1BVFNbZm9ybWF0XSkge1xuICAgIHJldHVybiBEQVRFX0ZPUk1BVFNbZm9ybWF0XTtcbiAgfVxuICBsZXQgZm9ybWF0dGVyO1xuICBzd2l0Y2ggKGZvcm1hdCkge1xuICAgIC8vIEVyYSBuYW1lIChBRC9CQylcbiAgICBjYXNlICdHJzpcbiAgICBjYXNlICdHRyc6XG4gICAgY2FzZSAnR0dHJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLkVyYXMsIFRyYW5zbGF0aW9uV2lkdGguQWJicmV2aWF0ZWQpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnR0dHRyc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5FcmFzLCBUcmFuc2xhdGlvbldpZHRoLldpZGUpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnR0dHR0cnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRXJhcywgVHJhbnNsYXRpb25XaWR0aC5OYXJyb3cpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyAxIGRpZ2l0IHJlcHJlc2VudGF0aW9uIG9mIHRoZSB5ZWFyLCBlLmcuIChBRCAxID0+IDEsIEFEIDE5OSA9PiAxOTkpXG4gICAgY2FzZSAneSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLkZ1bGxZZWFyLCAxLCAwLCBmYWxzZSwgdHJ1ZSk7XG4gICAgICBicmVhaztcbiAgICAvLyAyIGRpZ2l0IHJlcHJlc2VudGF0aW9uIG9mIHRoZSB5ZWFyLCBwYWRkZWQgKDAwLTk5KS4gKGUuZy4gQUQgMjAwMSA9PiAwMSwgQUQgMjAxMCA9PiAxMClcbiAgICBjYXNlICd5eSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLkZ1bGxZZWFyLCAyLCAwLCB0cnVlLCB0cnVlKTtcbiAgICAgIGJyZWFrO1xuICAgIC8vIDMgZGlnaXQgcmVwcmVzZW50YXRpb24gb2YgdGhlIHllYXIsIHBhZGRlZCAoMDAwLTk5OSkuIChlLmcuIEFEIDIwMDEgPT4gMDEsIEFEIDIwMTAgPT4gMTApXG4gICAgY2FzZSAneXl5JzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVHZXR0ZXIoRGF0ZVR5cGUuRnVsbFllYXIsIDMsIDAsIGZhbHNlLCB0cnVlKTtcbiAgICAgIGJyZWFrO1xuICAgIC8vIDQgZGlnaXQgcmVwcmVzZW50YXRpb24gb2YgdGhlIHllYXIgKGUuZy4gQUQgMSA9PiAwMDAxLCBBRCAyMDEwID0+IDIwMTApXG4gICAgY2FzZSAneXl5eSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLkZ1bGxZZWFyLCA0LCAwLCBmYWxzZSwgdHJ1ZSk7XG4gICAgICBicmVhaztcblxuICAgIC8vIDEgZGlnaXQgcmVwcmVzZW50YXRpb24gb2YgdGhlIHdlZWstbnVtYmVyaW5nIHllYXIsIGUuZy4gKEFEIDEgPT4gMSwgQUQgMTk5ID0+IDE5OSlcbiAgICBjYXNlICdZJzpcbiAgICAgIGZvcm1hdHRlciA9IHdlZWtOdW1iZXJpbmdZZWFyR2V0dGVyKDEpO1xuICAgICAgYnJlYWs7XG4gICAgLy8gMiBkaWdpdCByZXByZXNlbnRhdGlvbiBvZiB0aGUgd2Vlay1udW1iZXJpbmcgeWVhciwgcGFkZGVkICgwMC05OSkuIChlLmcuIEFEIDIwMDEgPT4gMDEsIEFEXG4gICAgLy8gMjAxMCA9PiAxMClcbiAgICBjYXNlICdZWSc6XG4gICAgICBmb3JtYXR0ZXIgPSB3ZWVrTnVtYmVyaW5nWWVhckdldHRlcigyLCB0cnVlKTtcbiAgICAgIGJyZWFrO1xuICAgIC8vIDMgZGlnaXQgcmVwcmVzZW50YXRpb24gb2YgdGhlIHdlZWstbnVtYmVyaW5nIHllYXIsIHBhZGRlZCAoMDAwLTk5OSkuIChlLmcuIEFEIDEgPT4gMDAxLCBBRFxuICAgIC8vIDIwMTAgPT4gMjAxMClcbiAgICBjYXNlICdZWVknOlxuICAgICAgZm9ybWF0dGVyID0gd2Vla051bWJlcmluZ1llYXJHZXR0ZXIoMyk7XG4gICAgICBicmVhaztcbiAgICAvLyA0IGRpZ2l0IHJlcHJlc2VudGF0aW9uIG9mIHRoZSB3ZWVrLW51bWJlcmluZyB5ZWFyIChlLmcuIEFEIDEgPT4gMDAwMSwgQUQgMjAxMCA9PiAyMDEwKVxuICAgIGNhc2UgJ1lZWVknOlxuICAgICAgZm9ybWF0dGVyID0gd2Vla051bWJlcmluZ1llYXJHZXR0ZXIoNCk7XG4gICAgICBicmVhaztcblxuICAgIC8vIE1vbnRoIG9mIHRoZSB5ZWFyICgxLTEyKSwgbnVtZXJpY1xuICAgIGNhc2UgJ00nOlxuICAgIGNhc2UgJ0wnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5Nb250aCwgMSwgMSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdNTSc6XG4gICAgY2FzZSAnTEwnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5Nb250aCwgMiwgMSk7XG4gICAgICBicmVhaztcblxuICAgIC8vIE1vbnRoIG9mIHRoZSB5ZWFyIChKYW51YXJ5LCAuLi4pLCBzdHJpbmcsIGZvcm1hdFxuICAgIGNhc2UgJ01NTSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5Nb250aHMsIFRyYW5zbGF0aW9uV2lkdGguQWJicmV2aWF0ZWQpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnTU1NTSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5Nb250aHMsIFRyYW5zbGF0aW9uV2lkdGguV2lkZSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdNTU1NTSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5Nb250aHMsIFRyYW5zbGF0aW9uV2lkdGguTmFycm93KTtcbiAgICAgIGJyZWFrO1xuXG4gICAgLy8gTW9udGggb2YgdGhlIHllYXIgKEphbnVhcnksIC4uLiksIHN0cmluZywgc3RhbmRhbG9uZVxuICAgIGNhc2UgJ0xMTCc6XG4gICAgICBmb3JtYXR0ZXIgPVxuICAgICAgICAgIGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLk1vbnRocywgVHJhbnNsYXRpb25XaWR0aC5BYmJyZXZpYXRlZCwgRm9ybVN0eWxlLlN0YW5kYWxvbmUpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnTExMTCc6XG4gICAgICBmb3JtYXR0ZXIgPVxuICAgICAgICAgIGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLk1vbnRocywgVHJhbnNsYXRpb25XaWR0aC5XaWRlLCBGb3JtU3R5bGUuU3RhbmRhbG9uZSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdMTExMTCc6XG4gICAgICBmb3JtYXR0ZXIgPVxuICAgICAgICAgIGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLk1vbnRocywgVHJhbnNsYXRpb25XaWR0aC5OYXJyb3csIEZvcm1TdHlsZS5TdGFuZGFsb25lKTtcbiAgICAgIGJyZWFrO1xuXG4gICAgLy8gV2VlayBvZiB0aGUgeWVhciAoMSwgLi4uIDUyKVxuICAgIGNhc2UgJ3cnOlxuICAgICAgZm9ybWF0dGVyID0gd2Vla0dldHRlcigxKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ3d3JzpcbiAgICAgIGZvcm1hdHRlciA9IHdlZWtHZXR0ZXIoMik7XG4gICAgICBicmVhaztcblxuICAgIC8vIFdlZWsgb2YgdGhlIG1vbnRoICgxLCAuLi4pXG4gICAgY2FzZSAnVyc6XG4gICAgICBmb3JtYXR0ZXIgPSB3ZWVrR2V0dGVyKDEsIHRydWUpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyBEYXkgb2YgdGhlIG1vbnRoICgxLTMxKVxuICAgIGNhc2UgJ2QnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5EYXRlLCAxKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ2RkJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVHZXR0ZXIoRGF0ZVR5cGUuRGF0ZSwgMik7XG4gICAgICBicmVhaztcblxuICAgIC8vIERheSBvZiB0aGUgV2VlayBTdGFuZEFsb25lICgxLCAxLCBNb24sIE1vbmRheSwgTSwgTW8pXG4gICAgY2FzZSAnYyc6XG4gICAgY2FzZSAnY2MnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5EYXksIDEpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnY2NjJzpcbiAgICAgIGZvcm1hdHRlciA9XG4gICAgICAgICAgZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRGF5cywgVHJhbnNsYXRpb25XaWR0aC5BYmJyZXZpYXRlZCwgRm9ybVN0eWxlLlN0YW5kYWxvbmUpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnY2NjYyc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5EYXlzLCBUcmFuc2xhdGlvbldpZHRoLldpZGUsIEZvcm1TdHlsZS5TdGFuZGFsb25lKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ2NjY2NjJzpcbiAgICAgIGZvcm1hdHRlciA9XG4gICAgICAgICAgZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRGF5cywgVHJhbnNsYXRpb25XaWR0aC5OYXJyb3csIEZvcm1TdHlsZS5TdGFuZGFsb25lKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ2NjY2NjYyc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5EYXlzLCBUcmFuc2xhdGlvbldpZHRoLlNob3J0LCBGb3JtU3R5bGUuU3RhbmRhbG9uZSk7XG4gICAgICBicmVhaztcblxuICAgIC8vIERheSBvZiB0aGUgV2Vla1xuICAgIGNhc2UgJ0UnOlxuICAgIGNhc2UgJ0VFJzpcbiAgICBjYXNlICdFRUUnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRGF5cywgVHJhbnNsYXRpb25XaWR0aC5BYmJyZXZpYXRlZCk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdFRUVFJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLkRheXMsIFRyYW5zbGF0aW9uV2lkdGguV2lkZSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdFRUVFRSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5EYXlzLCBUcmFuc2xhdGlvbldpZHRoLk5hcnJvdyk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdFRUVFRUUnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRGF5cywgVHJhbnNsYXRpb25XaWR0aC5TaG9ydCk7XG4gICAgICBicmVhaztcblxuICAgIC8vIEdlbmVyaWMgcGVyaW9kIG9mIHRoZSBkYXkgKGFtLXBtKVxuICAgIGNhc2UgJ2EnOlxuICAgIGNhc2UgJ2FhJzpcbiAgICBjYXNlICdhYWEnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihUcmFuc2xhdGlvblR5cGUuRGF5UGVyaW9kcywgVHJhbnNsYXRpb25XaWR0aC5BYmJyZXZpYXRlZCk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdhYWFhJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVTdHJHZXR0ZXIoVHJhbnNsYXRpb25UeXBlLkRheVBlcmlvZHMsIFRyYW5zbGF0aW9uV2lkdGguV2lkZSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdhYWFhYSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5EYXlQZXJpb2RzLCBUcmFuc2xhdGlvbldpZHRoLk5hcnJvdyk7XG4gICAgICBicmVhaztcblxuICAgIC8vIEV4dGVuZGVkIHBlcmlvZCBvZiB0aGUgZGF5IChtaWRuaWdodCwgYXQgbmlnaHQsIC4uLiksIHN0YW5kYWxvbmVcbiAgICBjYXNlICdiJzpcbiAgICBjYXNlICdiYic6XG4gICAgY2FzZSAnYmJiJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVTdHJHZXR0ZXIoXG4gICAgICAgICAgVHJhbnNsYXRpb25UeXBlLkRheVBlcmlvZHMsIFRyYW5zbGF0aW9uV2lkdGguQWJicmV2aWF0ZWQsIEZvcm1TdHlsZS5TdGFuZGFsb25lLCB0cnVlKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ2JiYmInOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihcbiAgICAgICAgICBUcmFuc2xhdGlvblR5cGUuRGF5UGVyaW9kcywgVHJhbnNsYXRpb25XaWR0aC5XaWRlLCBGb3JtU3R5bGUuU3RhbmRhbG9uZSwgdHJ1ZSk7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdiYmJiYic6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFxuICAgICAgICAgIFRyYW5zbGF0aW9uVHlwZS5EYXlQZXJpb2RzLCBUcmFuc2xhdGlvbldpZHRoLk5hcnJvdywgRm9ybVN0eWxlLlN0YW5kYWxvbmUsIHRydWUpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyBFeHRlbmRlZCBwZXJpb2Qgb2YgdGhlIGRheSAobWlkbmlnaHQsIG5pZ2h0LCAuLi4pLCBzdGFuZGFsb25lXG4gICAgY2FzZSAnQic6XG4gICAgY2FzZSAnQkInOlxuICAgIGNhc2UgJ0JCQic6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlU3RyR2V0dGVyKFxuICAgICAgICAgIFRyYW5zbGF0aW9uVHlwZS5EYXlQZXJpb2RzLCBUcmFuc2xhdGlvbldpZHRoLkFiYnJldmlhdGVkLCBGb3JtU3R5bGUuRm9ybWF0LCB0cnVlKTtcbiAgICAgIGJyZWFrO1xuICAgIGNhc2UgJ0JCQkInOlxuICAgICAgZm9ybWF0dGVyID1cbiAgICAgICAgICBkYXRlU3RyR2V0dGVyKFRyYW5zbGF0aW9uVHlwZS5EYXlQZXJpb2RzLCBUcmFuc2xhdGlvbldpZHRoLldpZGUsIEZvcm1TdHlsZS5Gb3JtYXQsIHRydWUpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnQkJCQkInOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZVN0ckdldHRlcihcbiAgICAgICAgICBUcmFuc2xhdGlvblR5cGUuRGF5UGVyaW9kcywgVHJhbnNsYXRpb25XaWR0aC5OYXJyb3csIEZvcm1TdHlsZS5Gb3JtYXQsIHRydWUpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyBIb3VyIGluIEFNL1BNLCAoMS0xMilcbiAgICBjYXNlICdoJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVHZXR0ZXIoRGF0ZVR5cGUuSG91cnMsIDEsIC0xMik7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdoaCc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLkhvdXJzLCAyLCAtMTIpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyBIb3VyIG9mIHRoZSBkYXkgKDAtMjMpXG4gICAgY2FzZSAnSCc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLkhvdXJzLCAxKTtcbiAgICAgIGJyZWFrO1xuICAgIC8vIEhvdXIgaW4gZGF5LCBwYWRkZWQgKDAwLTIzKVxuICAgIGNhc2UgJ0hIJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVHZXR0ZXIoRGF0ZVR5cGUuSG91cnMsIDIpO1xuICAgICAgYnJlYWs7XG5cbiAgICAvLyBNaW51dGUgb2YgdGhlIGhvdXIgKDAtNTkpXG4gICAgY2FzZSAnbSc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLk1pbnV0ZXMsIDEpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnbW0nOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5NaW51dGVzLCAyKTtcbiAgICAgIGJyZWFrO1xuXG4gICAgLy8gU2Vjb25kIG9mIHRoZSBtaW51dGUgKDAtNTkpXG4gICAgY2FzZSAncyc6XG4gICAgICBmb3JtYXR0ZXIgPSBkYXRlR2V0dGVyKERhdGVUeXBlLlNlY29uZHMsIDEpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnc3MnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5TZWNvbmRzLCAyKTtcbiAgICAgIGJyZWFrO1xuXG4gICAgLy8gRnJhY3Rpb25hbCBzZWNvbmRcbiAgICBjYXNlICdTJzpcbiAgICAgIGZvcm1hdHRlciA9IGRhdGVHZXR0ZXIoRGF0ZVR5cGUuRnJhY3Rpb25hbFNlY29uZHMsIDEpO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnU1MnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5GcmFjdGlvbmFsU2Vjb25kcywgMik7XG4gICAgICBicmVhaztcbiAgICBjYXNlICdTU1MnOlxuICAgICAgZm9ybWF0dGVyID0gZGF0ZUdldHRlcihEYXRlVHlwZS5GcmFjdGlvbmFsU2Vjb25kcywgMyk7XG4gICAgICBicmVhaztcblxuXG4gICAgLy8gVGltZXpvbmUgSVNPODYwMSBzaG9ydCBmb3JtYXQgKC0wNDMwKVxuICAgIGNhc2UgJ1onOlxuICAgIGNhc2UgJ1paJzpcbiAgICBjYXNlICdaWlonOlxuICAgICAgZm9ybWF0dGVyID0gdGltZVpvbmVHZXR0ZXIoWm9uZVdpZHRoLlNob3J0KTtcbiAgICAgIGJyZWFrO1xuICAgIC8vIFRpbWV6b25lIElTTzg2MDEgZXh0ZW5kZWQgZm9ybWF0ICgtMDQ6MzApXG4gICAgY2FzZSAnWlpaWlonOlxuICAgICAgZm9ybWF0dGVyID0gdGltZVpvbmVHZXR0ZXIoWm9uZVdpZHRoLkV4dGVuZGVkKTtcbiAgICAgIGJyZWFrO1xuXG4gICAgLy8gVGltZXpvbmUgR01UIHNob3J0IGZvcm1hdCAoR01UKzQpXG4gICAgY2FzZSAnTyc6XG4gICAgY2FzZSAnT08nOlxuICAgIGNhc2UgJ09PTyc6XG4gICAgLy8gU2hvdWxkIGJlIGxvY2F0aW9uLCBidXQgZmFsbGJhY2sgdG8gZm9ybWF0IE8gaW5zdGVhZCBiZWNhdXNlIHdlIGRvbid0IGhhdmUgdGhlIGRhdGEgeWV0XG4gICAgY2FzZSAneic6XG4gICAgY2FzZSAnenonOlxuICAgIGNhc2UgJ3p6eic6XG4gICAgICBmb3JtYXR0ZXIgPSB0aW1lWm9uZUdldHRlcihab25lV2lkdGguU2hvcnRHTVQpO1xuICAgICAgYnJlYWs7XG4gICAgLy8gVGltZXpvbmUgR01UIGxvbmcgZm9ybWF0IChHTVQrMDQzMClcbiAgICBjYXNlICdPT09PJzpcbiAgICBjYXNlICdaWlpaJzpcbiAgICAvLyBTaG91bGQgYmUgbG9jYXRpb24sIGJ1dCBmYWxsYmFjayB0byBmb3JtYXQgTyBpbnN0ZWFkIGJlY2F1c2Ugd2UgZG9uJ3QgaGF2ZSB0aGUgZGF0YSB5ZXRcbiAgICBjYXNlICd6enp6JzpcbiAgICAgIGZvcm1hdHRlciA9IHRpbWVab25lR2V0dGVyKFpvbmVXaWR0aC5Mb25nKTtcbiAgICAgIGJyZWFrO1xuICAgIGRlZmF1bHQ6XG4gICAgICByZXR1cm4gbnVsbDtcbiAgfVxuICBEQVRFX0ZPUk1BVFNbZm9ybWF0XSA9IGZvcm1hdHRlcjtcbiAgcmV0dXJuIGZvcm1hdHRlcjtcbn1cblxuZnVuY3Rpb24gdGltZXpvbmVUb09mZnNldCh0aW1lem9uZTogc3RyaW5nLCBmYWxsYmFjazogbnVtYmVyKTogbnVtYmVyIHtcbiAgLy8gU3VwcG9ydDogSUUgMTEgb25seSwgRWRnZSAxMy0xNStcbiAgLy8gSUUvRWRnZSBkbyBub3QgXCJ1bmRlcnN0YW5kXCIgY29sb24gKGA6YCkgaW4gdGltZXpvbmVcbiAgdGltZXpvbmUgPSB0aW1lem9uZS5yZXBsYWNlKC86L2csICcnKTtcbiAgY29uc3QgcmVxdWVzdGVkVGltZXpvbmVPZmZzZXQgPSBEYXRlLnBhcnNlKCdKYW4gMDEsIDE5NzAgMDA6MDA6MDAgJyArIHRpbWV6b25lKSAvIDYwMDAwO1xuICByZXR1cm4gaXNOYU4ocmVxdWVzdGVkVGltZXpvbmVPZmZzZXQpID8gZmFsbGJhY2sgOiByZXF1ZXN0ZWRUaW1lem9uZU9mZnNldDtcbn1cblxuZnVuY3Rpb24gYWRkRGF0ZU1pbnV0ZXMoZGF0ZTogRGF0ZSwgbWludXRlczogbnVtYmVyKSB7XG4gIGRhdGUgPSBuZXcgRGF0ZShkYXRlLmdldFRpbWUoKSk7XG4gIGRhdGUuc2V0TWludXRlcyhkYXRlLmdldE1pbnV0ZXMoKSArIG1pbnV0ZXMpO1xuICByZXR1cm4gZGF0ZTtcbn1cblxuZnVuY3Rpb24gY29udmVydFRpbWV6b25lVG9Mb2NhbChkYXRlOiBEYXRlLCB0aW1lem9uZTogc3RyaW5nLCByZXZlcnNlOiBib29sZWFuKTogRGF0ZSB7XG4gIGNvbnN0IHJldmVyc2VWYWx1ZSA9IHJldmVyc2UgPyAtMSA6IDE7XG4gIGNvbnN0IGRhdGVUaW1lem9uZU9mZnNldCA9IGRhdGUuZ2V0VGltZXpvbmVPZmZzZXQoKTtcbiAgY29uc3QgdGltZXpvbmVPZmZzZXQgPSB0aW1lem9uZVRvT2Zmc2V0KHRpbWV6b25lLCBkYXRlVGltZXpvbmVPZmZzZXQpO1xuICByZXR1cm4gYWRkRGF0ZU1pbnV0ZXMoZGF0ZSwgcmV2ZXJzZVZhbHVlICogKHRpbWV6b25lT2Zmc2V0IC0gZGF0ZVRpbWV6b25lT2Zmc2V0KSk7XG59XG5cbi8qKlxuICogQ29udmVydHMgYSB2YWx1ZSB0byBkYXRlLlxuICpcbiAqIFN1cHBvcnRlZCBpbnB1dCBmb3JtYXRzOlxuICogLSBgRGF0ZWBcbiAqIC0gbnVtYmVyOiB0aW1lc3RhbXBcbiAqIC0gc3RyaW5nOiBudW1lcmljIChlLmcuIFwiMTIzNFwiKSwgSVNPIGFuZCBkYXRlIHN0cmluZ3MgaW4gYSBmb3JtYXQgc3VwcG9ydGVkIGJ5XG4gKiAgIFtEYXRlLnBhcnNlKCldKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0phdmFTY3JpcHQvUmVmZXJlbmNlL0dsb2JhbF9PYmplY3RzL0RhdGUvcGFyc2UpLlxuICogICBOb3RlOiBJU08gc3RyaW5ncyB3aXRob3V0IHRpbWUgcmV0dXJuIGEgZGF0ZSB3aXRob3V0IHRpbWVvZmZzZXQuXG4gKlxuICogVGhyb3dzIGlmIHVuYWJsZSB0byBjb252ZXJ0IHRvIGEgZGF0ZS5cbiAqL1xuZXhwb3J0IGZ1bmN0aW9uIHRvRGF0ZSh2YWx1ZTogc3RyaW5nfG51bWJlcnxEYXRlKTogRGF0ZSB7XG4gIGlmIChpc0RhdGUodmFsdWUpKSB7XG4gICAgcmV0dXJuIHZhbHVlO1xuICB9XG5cbiAgaWYgKHR5cGVvZiB2YWx1ZSA9PT0gJ251bWJlcicgJiYgIWlzTmFOKHZhbHVlKSkge1xuICAgIHJldHVybiBuZXcgRGF0ZSh2YWx1ZSk7XG4gIH1cblxuICBpZiAodHlwZW9mIHZhbHVlID09PSAnc3RyaW5nJykge1xuICAgIHZhbHVlID0gdmFsdWUudHJpbSgpO1xuXG4gICAgaWYgKC9eKFxcZHs0fSgtXFxkezEsMn0oLVxcZHsxLDJ9KT8pPykkLy50ZXN0KHZhbHVlKSkge1xuICAgICAgLyogRm9yIElTTyBTdHJpbmdzIHdpdGhvdXQgdGltZSB0aGUgZGF5LCBtb250aCBhbmQgeWVhciBtdXN0IGJlIGV4dHJhY3RlZCBmcm9tIHRoZSBJU08gU3RyaW5nXG4gICAgICBiZWZvcmUgRGF0ZSBjcmVhdGlvbiB0byBhdm9pZCB0aW1lIG9mZnNldCBhbmQgZXJyb3JzIGluIHRoZSBuZXcgRGF0ZS5cbiAgICAgIElmIHdlIG9ubHkgcmVwbGFjZSAnLScgd2l0aCAnLCcgaW4gdGhlIElTTyBTdHJpbmcgKFwiMjAxNSwwMSwwMVwiKSwgYW5kIHRyeSB0byBjcmVhdGUgYSBuZXdcbiAgICAgIGRhdGUsIHNvbWUgYnJvd3NlcnMgKGUuZy4gSUUgOSkgd2lsbCB0aHJvdyBhbiBpbnZhbGlkIERhdGUgZXJyb3IuXG4gICAgICBJZiB3ZSBsZWF2ZSB0aGUgJy0nIChcIjIwMTUtMDEtMDFcIikgYW5kIHRyeSB0byBjcmVhdGUgYSBuZXcgRGF0ZShcIjIwMTUtMDEtMDFcIikgdGhlIHRpbWVvZmZzZXRcbiAgICAgIGlzIGFwcGxpZWQuXG4gICAgICBOb3RlOiBJU08gbW9udGhzIGFyZSAwIGZvciBKYW51YXJ5LCAxIGZvciBGZWJydWFyeSwgLi4uICovXG4gICAgICBjb25zdCBbeSwgbSA9IDEsIGQgPSAxXSA9IHZhbHVlLnNwbGl0KCctJykubWFwKCh2YWw6IHN0cmluZykgPT4gK3ZhbCk7XG4gICAgICByZXR1cm4gY3JlYXRlRGF0ZSh5LCBtIC0gMSwgZCk7XG4gICAgfVxuXG4gICAgY29uc3QgcGFyc2VkTmIgPSBwYXJzZUZsb2F0KHZhbHVlKTtcblxuICAgIC8vIGFueSBzdHJpbmcgdGhhdCBvbmx5IGNvbnRhaW5zIG51bWJlcnMsIGxpa2UgXCIxMjM0XCIgYnV0IG5vdCBsaWtlIFwiMTIzNGhlbGxvXCJcbiAgICBpZiAoIWlzTmFOKHZhbHVlIGFzIGFueSAtIHBhcnNlZE5iKSkge1xuICAgICAgcmV0dXJuIG5ldyBEYXRlKHBhcnNlZE5iKTtcbiAgICB9XG5cbiAgICBsZXQgbWF0Y2g6IFJlZ0V4cE1hdGNoQXJyYXl8bnVsbDtcbiAgICBpZiAobWF0Y2ggPSB2YWx1ZS5tYXRjaChJU084NjAxX0RBVEVfUkVHRVgpKSB7XG4gICAgICByZXR1cm4gaXNvU3RyaW5nVG9EYXRlKG1hdGNoKTtcbiAgICB9XG4gIH1cblxuICBjb25zdCBkYXRlID0gbmV3IERhdGUodmFsdWUgYXMgYW55KTtcbiAgaWYgKCFpc0RhdGUoZGF0ZSkpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFVuYWJsZSB0byBjb252ZXJ0IFwiJHt2YWx1ZX1cIiBpbnRvIGEgZGF0ZWApO1xuICB9XG4gIHJldHVybiBkYXRlO1xufVxuXG4vKipcbiAqIENvbnZlcnRzIGEgZGF0ZSBpbiBJU084NjAxIHRvIGEgRGF0ZS5cbiAqIFVzZWQgaW5zdGVhZCBvZiBgRGF0ZS5wYXJzZWAgYmVjYXVzZSBvZiBicm93c2VyIGRpc2NyZXBhbmNpZXMuXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBpc29TdHJpbmdUb0RhdGUobWF0Y2g6IFJlZ0V4cE1hdGNoQXJyYXkpOiBEYXRlIHtcbiAgY29uc3QgZGF0ZSA9IG5ldyBEYXRlKDApO1xuICBsZXQgdHpIb3VyID0gMDtcbiAgbGV0IHR6TWluID0gMDtcblxuICAvLyBtYXRjaFs4XSBtZWFucyB0aGF0IHRoZSBzdHJpbmcgY29udGFpbnMgXCJaXCIgKFVUQykgb3IgYSB0aW1lem9uZSBsaWtlIFwiKzAxOjAwXCIgb3IgXCIrMDEwMFwiXG4gIGNvbnN0IGRhdGVTZXR0ZXIgPSBtYXRjaFs4XSA/IGRhdGUuc2V0VVRDRnVsbFllYXIgOiBkYXRlLnNldEZ1bGxZZWFyO1xuICBjb25zdCB0aW1lU2V0dGVyID0gbWF0Y2hbOF0gPyBkYXRlLnNldFVUQ0hvdXJzIDogZGF0ZS5zZXRIb3VycztcblxuICAvLyBpZiB0aGVyZSBpcyBhIHRpbWV6b25lIGRlZmluZWQgbGlrZSBcIiswMTowMFwiIG9yIFwiKzAxMDBcIlxuICBpZiAobWF0Y2hbOV0pIHtcbiAgICB0ekhvdXIgPSBOdW1iZXIobWF0Y2hbOV0gKyBtYXRjaFsxMF0pO1xuICAgIHR6TWluID0gTnVtYmVyKG1hdGNoWzldICsgbWF0Y2hbMTFdKTtcbiAgfVxuICBkYXRlU2V0dGVyLmNhbGwoZGF0ZSwgTnVtYmVyKG1hdGNoWzFdKSwgTnVtYmVyKG1hdGNoWzJdKSAtIDEsIE51bWJlcihtYXRjaFszXSkpO1xuICBjb25zdCBoID0gTnVtYmVyKG1hdGNoWzRdIHx8IDApIC0gdHpIb3VyO1xuICBjb25zdCBtID0gTnVtYmVyKG1hdGNoWzVdIHx8IDApIC0gdHpNaW47XG4gIGNvbnN0IHMgPSBOdW1iZXIobWF0Y2hbNl0gfHwgMCk7XG4gIC8vIFRoZSBFQ01BU2NyaXB0IHNwZWNpZmljYXRpb24gKGh0dHBzOi8vd3d3LmVjbWEtaW50ZXJuYXRpb25hbC5vcmcvZWNtYS0yNjIvNS4xLyNzZWMtMTUuOS4xLjExKVxuICAvLyBkZWZpbmVzIHRoYXQgYERhdGVUaW1lYCBtaWxsaXNlY29uZHMgc2hvdWxkIGFsd2F5cyBiZSByb3VuZGVkIGRvd24sIHNvIHRoYXQgYDk5OS45bXNgXG4gIC8vIGJlY29tZXMgYDk5OW1zYC5cbiAgY29uc3QgbXMgPSBNYXRoLmZsb29yKHBhcnNlRmxvYXQoJzAuJyArIChtYXRjaFs3XSB8fCAwKSkgKiAxMDAwKTtcbiAgdGltZVNldHRlci5jYWxsKGRhdGUsIGgsIG0sIHMsIG1zKTtcbiAgcmV0dXJuIGRhdGU7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBpc0RhdGUodmFsdWU6IGFueSk6IHZhbHVlIGlzIERhdGUge1xuICByZXR1cm4gdmFsdWUgaW5zdGFuY2VvZiBEYXRlICYmICFpc05hTih2YWx1ZS52YWx1ZU9mKCkpO1xufVxuIl19