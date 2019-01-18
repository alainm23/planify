/*======================================================================
 FILE: icalduration.h
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

#ifndef ICALDURATION_H
#define ICALDURATION_H

/**
 * @file icalduration.h
 * @brief Methods for working with durations in iCal
 */

#include "libical_ical_export.h"
#include "icaltime.h"

/**
 * @brief A struct representing a duration
 */
struct icaldurationtype
{
    int is_neg;
    unsigned int days;
    unsigned int weeks;
    unsigned int hours;
    unsigned int minutes;
    unsigned int seconds;
};

/**
 * @brief Creates a new ::icaldurationtype from a duration in seconds.
 * @param t The duration in seconds
 * @return An ::icaldurationtype representing the duration @a t in seconds
 *
 * ### Example
 * ```c
 * // create a new icaldurationtype with a duration of 60 seconds
 * struct icaldurationtype duration;
 * duration = icaldurationtype_from_int(60);
 *
 * // verify that the duration is one minute
 * assert(duration.minutes == 1);
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icaldurationtype_from_int(int t);

/**
 * @brief Creates a new ::icaldurationtype from a duration given as a string.
 * @param dur The duration as a string
 * @return An ::icaldurationtype representing the duration @a dur
 *
 * @par Error handling
 * When given bad input, it sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR and
 * returnes icaldurationtype_bad_duration().
 *
 * ### Usage
 * ```c
 * // create a new icaldurationtype
 * struct icaldurationtype duration;
 * duration = icaldurationtype_from_string("+PT05M");
 *
 * // verify that it's 5 minutes
 * assert(duration.minutes == 5);
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icaldurationtype_from_string(const char *dur);

/**
 * @brief Converts an ::icaldurationtype into the duration in seconds as `int`.
 * @param duration The duration to convert to seconds
 * @return An `int` representing the duration in seconds
 *
 * ### Usage
 * ```c
 * // create icaldurationtype with given duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_from_int(3532342);
 *
 * // get the duration in seconds and verify it
 * assert(icaldurationtype_as_int(duration) == 3532342);
 * ```
 */
LIBICAL_ICAL_EXPORT int icaldurationtype_as_int(struct icaldurationtype duration);

/**
 * Converts an icaldurationtype into the iCal format as string.
 * @param The icaldurationtype to convert to iCal format
 * @return A string representing duration @p d in iCal format
 * @sa icaldurationtype_as_ical_string_r()
 *
 * @b Ownership
 * The string returned by this function is owned by the caller and needs to be
 * released with `free()` after it's no longer needed.
 *
 * @b Usage
 * ```c
 * // create new duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_from_int(3424224);
 *
 * // print as ical-formatted string
 * char *ical = icaldurationtype_as_ical_string(duration);
 * printf("%s\n", ical);
 *
 * // release string
 * free(ical);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icaldurationtype_as_ical_string(struct icaldurationtype d);

/**
 * Converts an icaldurationtype into the iCal format as string.
 * @param The icaldurationtype to convert to iCal format
 * @return A string representing duration @p d in iCal format
 * @sa icaldurationtype_as_ical_string()
 *
 * @b Ownership
 * The string returned by this function is owned by libical and must not be
 * released by the caller of the function.
 *
 * @b Usage
 * ```c
 * // create new duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_from_int(3424224);
 *
 * // print as ical-formatted string
 * printf("%s\n", icaldurationtype_as_ical_string(duration));
 * ```
 */
LIBICAL_ICAL_EXPORT char *icaldurationtype_as_ical_string_r(struct icaldurationtype d);

/**
 * @brief Creates a duration with zero length.
 * @return An ::icaldurationtype with a zero length
 * @sa icaldurationtype_is_null_duration()
 *
 * ### Usage
 * ```c
 * // create null duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_null_duration();
 *
 * // make sure it's zero length
 * assert(duration.days     == 0);
 * assert(duration.weeks    == 0);
 * assert(duration.hours    == 0);
 * assert(duration.minutes  == 0);
 * assert(duration.seconds  == 0);
 * assert(icalduration_is_null_duration(duration));
 * assert(icalduration_as_int(duration) == 0);
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icaldurationtype_null_duration(void);

/**
 * @brief Creates a bad duration (used to indicate error).
 * @return A bad duration
 * @sa icaldurationtype_is_bad_duration()
 *
 * ### Usage
 * ```c
 * // create bad duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_bad_duration();
 *
 * // make sure it's bad
 * assert(icaldurationtype_is_bad_duration(duration));
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icaldurationtype_bad_duration(void);

/**
 * @brief Checks if a duration is a null duration.
 * @param d The duration to check
 * @return 1 if the duration is a null duration, 0 otherwise
 * @sa icalduration_null_duration()
 *
 * ### Usage
 * ```
 * // make null duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_null_duration();
 *
 * // check null duration
 * assert(icaldurationtype_is_null_duration(duration));
 * ```
 */
LIBICAL_ICAL_EXPORT int icaldurationtype_is_null_duration(struct icaldurationtype d);

/**
 * @brief Checks if a duration is a bad duration.
 * @param d The duration to check
 * @return 1 if the duration is a bad duration, 0 otherwise
 * @sa icalduration_bad_duration()
 *
 * ### Usage
 * ```
 * // make bad duration
 * struct icaldurationtype duration;
 * duration = icaldurationtype_bad_duration();
 *
 * // check bad duration
 * assert(icaldurationtype_is_bad_duration(duration));
 * ```
 */
LIBICAL_ICAL_EXPORT int icaldurationtype_is_bad_duration(struct icaldurationtype d);

/**
 * @brief Adds a duration to an ::icaltime object and returns the result.
 * @param t The time object to add the duration to
 * @param d The duration to add to the time object
 * @return The new ::icaltimetype which has been added the duration to
 *
 * ### Example
 * ```c
 * struct icaltimetype time;
 * struct icaldurationtype duration;
 *
 * // create time and duration objects
 * time = icaltime_today();
 * duration = icaldurationtype_from_int(60);
 *
 * // add the duration to the time object
 * time = icaltime_add(time, duration);
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_add(struct icaltimetype t,
                                                     struct icaldurationtype d);

/**
 * @brief Returns the difference between two ::icaltimetype as a duration.
 * @param t1 The first point in time
 * @param t2 The second point in time
 * @return An ::icaldurationtype representing the duration the elapsed between
 * @a t1 and @a t2
 *
 * ### Usage
 * ```c
 * struct icaltimetype t1 = icaltime_from_day_of_year(111, 2018);
 * struct icaltimetype t2 = icaltime_from_day_of_year(112, 2018);
 * struct icaldurationtype duration;
 *
 * // calculate duration between time points
 * duration = icaltime_subtract(t1, t2);
 * ```
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icaltime_subtract(struct icaltimetype t1,
                                                              struct icaltimetype t2);

#endif /* !ICALDURATION_H */
