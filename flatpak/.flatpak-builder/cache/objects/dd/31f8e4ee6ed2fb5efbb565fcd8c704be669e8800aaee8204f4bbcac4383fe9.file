/*======================================================================
 FILE: icalperiod.h
 CREATOR: eric 26 Jan 2001

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The Original Code is eric. The Initial Developer of the Original
 Code is Eric Busboom
======================================================================*/

#ifndef ICALPERIOD_H
#define ICALPERIOD_H

/**
 * @file icalperiod.h
 * @brief Functions for working with iCal periods (of time).
 */

#include "libical_ical_export.h"
#include "icalduration.h"
#include "icaltime.h"

/**
 * @brief Struct to represent a period in time.
 */
struct icalperiodtype
{
    struct icaltimetype start;
    struct icaltimetype end;
    struct icaldurationtype duration;
};

/**
 * @brief Constructs a new ::icalperiodtype from @a str
 * @param str The string from which to construct a time period
 * @return An ::icalperiodtype representing the peroid @a str
 * @sa icaltime_from_string(), icaldurationtype_from_string()
 *
 * @par Error handling
 * If @a str is not properly formatted, it sets ::icalerrno to
 * ::ICAL_MALFORMEDDATA_ERROR and returns icalperiodtype_null_period().
 *
 * ### Data format
 * There are two ways to specify a duration; either a start time
 * and an end time can be specified, or a start time and a duration.
 * The format for there is as such:
 * -   `<STARTTIME>/<ENDTIME>`
 * -   `<STARTTIME>/<DURATION>`
 *
 * The format for the times is the same as those used by
 * icaltime_from_string(), and the format for the duration
 * is the same as that used by icaldurationtype_from_string().
 *
 * ### Usage
 * ```c
 * // create icalperiodtype
 * const char *period_string = "20170606T090000/20170607T090000";
 * struct icalperiodtype period = icalperiodtype_from_string(period_string);
 *
 * // print period in iCal format
 * printf("%s\n", icalperiodtype_as_ical_string(period));
 * ```
 */
LIBICAL_ICAL_EXPORT struct icalperiodtype icalperiodtype_from_string(const char *str);

/**
 * @brief Converts an ::icalperiodtype into an iCal-formatted string.
 * @param p The time period to convert
 * @return A string representing the iCal-formatted period
 * @sa icalperiodtype_as_ical_string_r()
 *
 * @par Error handling
 * Sets ::icalerrno to ::ICAL_ALLOCATION_ERROR if there was an
 * internal error allocating memory.
 *
 * @par Ownership
 * The string returned by this method is owned by libical and must not be
 * `free()` by the caller.
 *
 * ### Example
 * ```c
 * // create icalperiodtype
 * const char *period_string = "20170606T090000/20170607T090000";
 * struct icalperiodtype period = icalperiodtype_from_string(period_string);
 *
 * // print period in iCal format
 * printf("%s\n", icalperiodtype_as_ical_string(period));
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalperiodtype_as_ical_string(struct icalperiodtype p);

/**
 * @brief Converts an ::icalperiodtype into an iCal-formatted string.
 * @param p The time period to convert
 * @return A string representing the iCal-formatted period
 * @sa icalperiodtype_as_ical_string()
 *
 * @par Error handling
 * Sets ::icalerrno to ::ICAL_ALLOCATION_ERROR if there was an
 * internal error allocating memory.
 *
 * @par Ownership
 * The string returned by this method is owned by the caller and must be
 * released with the appropriate function after use.
 *
 * ### Example
 * ```c
 * // create icalperiodtype
 * const char *period_string = "20170606T090000/20170607T090000";
 * struct icalperiodtype period = icalperiodtype_from_string(period_string);
 *
 * // print period in iCal format
 * const char *period_string_gen = icalperiodtype_as_ical_string_r(period);
 * printf("%s\n", period_string_gen);
 * icalmemory_free_buffer(period_string_gen);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalperiodtype_as_ical_string_r(struct icalperiodtype p);

/**
 * Creates a null period ::icalperiodtype.
 * @return An ::icalperiodtype representing a null period
 * @sa icalperiodtype_is_null_period()
 *
 * ### Usage
 * ```c
 * // creates null period
 * struct icalperiodtype period = icalperiodtype_null_period();
 *
 * // verifies start, end and length
 * assert(icaltime_is_null_time(period.start));
 * assert(icaltime_is_null_time(period.end));
 * assert(icaldurationtype_is_null_duratino(period.duration));
 * ```
 */
LIBICAL_ICAL_EXPORT struct icalperiodtype icalperiodtype_null_period(void);

/**
 * Checks if a given ::icalperiodtype is a null period.
 * @return 1 if @a p is a null period, 0 otherwise
 * @sa icalperiodtype_null_period()
 *
 * ### Usage
 * ```c
 * // creates null period
 * struct icalperiodtype period = icalperiodtype_null_period();
 *
 * // checks if it's a null period
 * assert(icalperiodtype_is_null_period(period));
 * ```
 */
LIBICAL_ICAL_EXPORT int icalperiodtype_is_null_period(struct icalperiodtype p);

/**
 * Checks if a given ::icalperiodtype is a valid period.
 * @return 1 if @a p is a valid period, 0 otherwise
 *
 * ### Usage
 * ```c
 * // creates null period
 * struct icalperiodtype period = icalperiodtype_null_period();
 *
 * // a null period isn't a valid period
 * assert(icalperiodtype_is_valid_period(period) == 0);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalperiodtype_is_valid_period(struct icalperiodtype p);

#endif /* !ICALTIME_H */
