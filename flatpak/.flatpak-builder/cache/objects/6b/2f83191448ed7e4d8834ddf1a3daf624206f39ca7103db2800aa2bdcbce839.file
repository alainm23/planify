#ifndef LIBICAL_ICAL_H
#define LIBICAL_ICAL_H
#ifndef S_SPLINT_S
#ifdef __cplusplus
extern "C" {
#endif
/*======================================================================
 FILE: icalversion.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
 ======================================================================*/

#ifndef ICAL_VERSION_H
#define ICAL_VERSION_H

#define ICAL_PACKAGE "libical"
#define ICAL_VERSION "3.0"

#define ICAL_MAJOR_VERSION (3)
#define ICAL_MINOR_VERSION (0)
#define ICAL_PATCH_VERSION (4)
#define ICAL_MICRO_VERSION ICAL_PATCH_VERSION

/**
 * ICAL_CHECK_VERSION:
 * @param major: major version (e.g. 1 for version 1.2.5)
 * @param minor: minor version (e.g. 2 for version 1.2.5)
 * @param micro: micro version (e.g. 5 for version 1.2.5)
 *
 * @return TRUE if the version of the LIBICAL header files
 * is the same as or newer than the passed-in version.
 */
#define ICAL_CHECK_VERSION(major,minor,micro)                          \
    (ICAL_MAJOR_VERSION > (major) ||                                   \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION > (minor)) || \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION == (minor) && \
    ICAL_MICRO_VERSION >= (micro)))

#endif

/*======================================================================
 FILE: icaltime.h
 CREATOR: eric 02 June 2000

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

/**     @file icaltime.h
 *      @brief struct icaltimetype is a pseudo-object that abstracts time
 *      handling.
 *
 *      It can represent either a DATE or a DATE-TIME (floating, UTC or in a
 *      given timezone), and it keeps track internally of its native timezone.
 *
 *      The typical usage is to call the correct constructor specifying the
 *      desired timezone. If this is not known until a later time, the
 *      correct behavior is to specify a NULL timezone and call
 *      icaltime_convert_to_zone() at a later time.
 *
 *      There are several ways to create a new icaltimetype:
 *
 *      - icaltime_null_time()
 *      - icaltime_null_date()
 *      - icaltime_current_time_with_zone()
 *      - icaltime_today()
 *      - icaltime_from_timet_with_zone(time_t tm, int is_date,
 *              icaltimezone *zone)
 *      - icaltime_from_day_of_year(int doy, int year)
 *
 *      italtimetype objects can be converted to different formats:
 *
 *      - icaltime_as_timet(struct icaltimetype tt)
 *      - icaltime_as_timet_with_zone(struct icaltimetype tt,
 *              icaltimezone *zone)
 *      - icaltime_as_ical_string(struct icaltimetype tt)
 *
 *      Accessor methods include:
 *
 *      - icaltime_get_timezone(struct icaltimetype t)
 *      - icaltime_get_tzid(struct icaltimetype t)
 *      - icaltime_set_timezone(struct icaltimetype t, const icaltimezone *zone)
 *      - icaltime_day_of_year(struct icaltimetype t)
 *      - icaltime_day_of_week(struct icaltimetype t)
 *      - icaltime_start_doy_week(struct icaltimetype t, int fdow)
 *      - icaltime_week_number(struct icaltimetype t)
 *
 *      Query methods include:
 *
 *      - icaltime_is_null_time(struct icaltimetype t)
 *      - icaltime_is_valid_time(struct icaltimetype t)
 *      - icaltime_is_date(struct icaltimetype t)
 *      - icaltime_is_utc(struct icaltimetype t)
 *
 *      Modify, compare and utility methods include:
 *
 *      - icaltime_compare(struct icaltimetype a,struct icaltimetype b)
 *      - icaltime_compare_date_only(struct icaltimetype a,
 *              struct icaltimetype b)
 *      - icaltime_adjust(struct icaltimetype *tt, int days, int hours,
 *              int minutes, int seconds);
 *      - icaltime_normalize(struct icaltimetype t);
 *      - icaltime_convert_to_zone(const struct icaltimetype tt,
 *              icaltimezone *zone);
 */

#ifndef ICALTIME_H
#define ICALTIME_H

#include "libical_ical_export.h"

#include <time.h>

/* An opaque struct representing a timezone. We declare this here to avoid
   a circular dependancy. */
#if !defined(ICALTIMEZONE_DEFINED)
#define ICALTIMEZONE_DEFINED
typedef struct _icaltimezone icaltimezone;
#endif

/** icaltime_span is returned by icalcomponent_get_span() */
struct icaltime_span
{
    time_t start;       /**< in UTC */
    time_t end;         /**< in UTC */
    int is_busy;        /**< 1->busy time, 0-> free time */
};

typedef struct icaltime_span icaltime_span;

struct icaltimetype
{
    int year;           /**< Actual year, e.g. 2001. */
    int month;          /**< 1 (Jan) to 12 (Dec). */
    int day;
    int hour;
    int minute;
    int second;

    int is_date;        /**< 1 -> interpret this as date. */

    int is_daylight;    /**< 1 -> time is in daylight savings time. */

    const icaltimezone *zone;  /**< timezone */
};

typedef struct icaltimetype icaltimetype;

/** Return a null time, which indicates no time has been set.
    This time represent the beginning of the epoch */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_null_time(void);

/** Return a null date */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_null_date(void);

/** Returns the current time in the given timezone, as an icaltimetype. */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_current_time_with_zone(const icaltimezone *zone);

/** Returns the current day as an icaltimetype, with is_date set. */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_today(void);

/** Convert seconds past UNIX epoch to a timetype, using timezones. */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_timet_with_zone(const time_t tm,
                                                                      const int is_date,
                                                                      const icaltimezone *zone);

/** create a time from an ISO format string */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_string(const char *str);

/** Create a new time, given a day of year and a year. */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_day_of_year(const int doy, const int year);

/**
 * Returns the time as seconds past the UNIX epoch
 *
 * This function probably won't do what you expect.  In particular, you should
 * only pass an icaltime in UTC, since no conversion is done.  Even in that case,
 * it's probably better to just use icaltime_as_timet_with_zone().
 */
LIBICAL_ICAL_EXPORT time_t icaltime_as_timet(const struct icaltimetype);

/** Return the time as seconds past the UNIX epoch, using timezones. */
LIBICAL_ICAL_EXPORT time_t icaltime_as_timet_with_zone(const struct icaltimetype tt,
                                                       const icaltimezone *zone);

/** Return a string represention of the time, in RFC5545 format. */
LIBICAL_ICAL_EXPORT const char *icaltime_as_ical_string(const struct icaltimetype tt);

LIBICAL_ICAL_EXPORT char *icaltime_as_ical_string_r(const struct icaltimetype tt);

/** @brief Return the timezone */
LIBICAL_ICAL_EXPORT const icaltimezone *icaltime_get_timezone(const struct icaltimetype t);

/** @brief Return the tzid, or NULL for a floating time */
LIBICAL_ICAL_EXPORT const char *icaltime_get_tzid(const struct icaltimetype t);

/** @brief Set the timezone */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_set_timezone(struct icaltimetype *t,
                                                              const icaltimezone *zone);

/** Return the day of the year of the given time */
LIBICAL_ICAL_EXPORT int icaltime_day_of_year(const struct icaltimetype t);

/** Return the day of the week of the given time. Sunday is 1 */
LIBICAL_ICAL_EXPORT int icaltime_day_of_week(const struct icaltimetype t);

/** Return the day of the year for the first day of the week that the
   given time is within. */
LIBICAL_ICAL_EXPORT int icaltime_start_doy_week(const struct icaltimetype t, int fdow);

/** Return the week number for the week the given time is within */
LIBICAL_ICAL_EXPORT int icaltime_week_number(const struct icaltimetype t);

/** Return true of the time is null. */
LIBICAL_ICAL_EXPORT int icaltime_is_null_time(const struct icaltimetype t);

/** Returns false if the time is clearly invalid, but is not null. This
   is usually the result of creating a new time type buy not clearing
   it, or setting one of the flags to an illegal value. */
LIBICAL_ICAL_EXPORT int icaltime_is_valid_time(const struct icaltimetype t);

/** @brief Returns true if time is of DATE type, false if DATE-TIME */
LIBICAL_ICAL_EXPORT int icaltime_is_date(const struct icaltimetype t);

/** @brief Returns true if time is relative to UTC zone */
LIBICAL_ICAL_EXPORT int icaltime_is_utc(const struct icaltimetype t);

/** Return -1, 0, or 1 to indicate that a is less than b, a equals b, or a is greater than b */
LIBICAL_ICAL_EXPORT int icaltime_compare(const struct icaltimetype a, const struct icaltimetype b);

/** like icaltime_compare, but only use the date parts. */
LIBICAL_ICAL_EXPORT int icaltime_compare_date_only(const struct icaltimetype a,
                                                   const struct icaltimetype b);

/** like icaltime_compare, but only use the date parts. */
LIBICAL_ICAL_EXPORT int icaltime_compare_date_only_tz(const struct icaltimetype a,
                                                      const struct icaltimetype b,
                                                      icaltimezone *tz);

/** Adds or subtracts a number of days, hours, minutes and seconds. */
LIBICAL_ICAL_EXPORT void icaltime_adjust(struct icaltimetype *tt,
                                         const int days, const int hours,
                                         const int minutes, const int seconds);

/** Normalize the icaltime, so that all fields are within the normal range. */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_normalize(const struct icaltimetype t);

/** convert tt, of timezone tzid, into a utc time. Does nothing if the
   time is already UTC.  */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_convert_to_zone(const struct icaltimetype tt,
                                                                 icaltimezone *zone);

/** Return the number of days in the given month */
LIBICAL_ICAL_EXPORT int icaltime_days_in_month(const int month, const int year);

/** Return whether you've specified a leapyear or not. */
LIBICAL_ICAL_EXPORT int icaltime_is_leap_year(const int year);

/** Return the number of days in this year */
LIBICAL_ICAL_EXPORT int icaltime_days_in_year(const int year);

/** @brief calculate an icaltimespan given a start and end time. */
LIBICAL_ICAL_EXPORT struct icaltime_span icaltime_span_new(struct icaltimetype dtstart,
                                                           struct icaltimetype dtend, int is_busy);

/** @brief Returns true if the two spans overlap **/
LIBICAL_ICAL_EXPORT int icaltime_span_overlaps(icaltime_span *s1, icaltime_span *s2);

/** @brief Returns true if the span is totally within the containing
 *  span
 */
LIBICAL_ICAL_EXPORT int icaltime_span_contains(icaltime_span *s, icaltime_span *container);

#endif /* !ICALTIME_H */

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

/*======================================================================
 FILE: icalenums.h

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 Contributions from:
    Graham Davison <g.m.davison@computer.org>
======================================================================*/

#ifndef ICALENUMS_H
#define ICALENUMS_H

#include "libical_ical_export.h"

/***********************************************************************
 * Component enumerations
**********************************************************************/

typedef enum icalcomponent_kind
{
    ICAL_NO_COMPONENT,
    ICAL_ANY_COMPONENT, /* Used to select all components */
    ICAL_XROOT_COMPONENT,
    ICAL_XATTACH_COMPONENT, /* MIME attached data, returned by parser. */
    ICAL_VEVENT_COMPONENT,
    ICAL_VTODO_COMPONENT,
    ICAL_VJOURNAL_COMPONENT,
    ICAL_VCALENDAR_COMPONENT,
    ICAL_VAGENDA_COMPONENT,
    ICAL_VFREEBUSY_COMPONENT,
    ICAL_VALARM_COMPONENT,
    ICAL_XAUDIOALARM_COMPONENT,
    ICAL_XDISPLAYALARM_COMPONENT,
    ICAL_XEMAILALARM_COMPONENT,
    ICAL_XPROCEDUREALARM_COMPONENT,
    ICAL_VTIMEZONE_COMPONENT,
    ICAL_XSTANDARD_COMPONENT,
    ICAL_XDAYLIGHT_COMPONENT,
    ICAL_X_COMPONENT,
    ICAL_VSCHEDULE_COMPONENT,
    ICAL_VQUERY_COMPONENT,
    ICAL_VREPLY_COMPONENT,
    ICAL_VCAR_COMPONENT,
    ICAL_VCOMMAND_COMPONENT,
    ICAL_XLICINVALID_COMPONENT,
    ICAL_XLICMIMEPART_COMPONENT, /* a non-stardard component that mirrors
                                           structure of MIME data */
    ICAL_VAVAILABILITY_COMPONENT,
    ICAL_XAVAILABLE_COMPONENT,
    ICAL_VPOLL_COMPONENT,
    ICAL_VVOTER_COMPONENT,
    ICAL_XVOTE_COMPONENT,
    ICAL_VPATCH_COMPONENT,
    ICAL_XPATCH_COMPONENT
} icalcomponent_kind;

/***********************************************************************
 * Request Status codes
 **********************************************************************/

typedef enum icalrequeststatus
{
    ICAL_UNKNOWN_STATUS,
    ICAL_2_0_SUCCESS_STATUS,
    ICAL_2_1_FALLBACK_STATUS,
    ICAL_2_2_IGPROP_STATUS,
    ICAL_2_3_IGPARAM_STATUS,
    ICAL_2_4_IGXPROP_STATUS,
    ICAL_2_5_IGXPARAM_STATUS,
    ICAL_2_6_IGCOMP_STATUS,
    ICAL_2_7_FORWARD_STATUS,
    ICAL_2_8_ONEEVENT_STATUS,
    ICAL_2_9_TRUNC_STATUS,
    ICAL_2_10_ONETODO_STATUS,
    ICAL_2_11_TRUNCRRULE_STATUS,
    ICAL_3_0_INVPROPNAME_STATUS,
    ICAL_3_1_INVPROPVAL_STATUS,
    ICAL_3_2_INVPARAM_STATUS,
    ICAL_3_3_INVPARAMVAL_STATUS,
    ICAL_3_4_INVCOMP_STATUS,
    ICAL_3_5_INVTIME_STATUS,
    ICAL_3_6_INVRULE_STATUS,
    ICAL_3_7_INVCU_STATUS,
    ICAL_3_8_NOAUTH_STATUS,
    ICAL_3_9_BADVERSION_STATUS,
    ICAL_3_10_TOOBIG_STATUS,
    ICAL_3_11_MISSREQCOMP_STATUS,
    ICAL_3_12_UNKCOMP_STATUS,
    ICAL_3_13_BADCOMP_STATUS,
    ICAL_3_14_NOCAP_STATUS,
    ICAL_3_15_INVCOMMAND,
    ICAL_4_0_BUSY_STATUS,
    ICAL_4_1_STORE_ACCESS_DENIED,
    ICAL_4_2_STORE_FAILED,
    ICAL_4_3_STORE_NOT_FOUND,
    ICAL_5_0_MAYBE_STATUS,
    ICAL_5_1_UNAVAIL_STATUS,
    ICAL_5_2_NOSERVICE_STATUS,
    ICAL_5_3_NOSCHED_STATUS,
    ICAL_6_1_CONTAINER_NOT_FOUND,
    ICAL_9_0_UNRECOGNIZED_COMMAND
} icalrequeststatus;

LIBICAL_ICAL_EXPORT const char *icalenum_reqstat_desc(icalrequeststatus stat);

LIBICAL_ICAL_EXPORT short icalenum_reqstat_major(icalrequeststatus stat);

LIBICAL_ICAL_EXPORT short icalenum_reqstat_minor(icalrequeststatus stat);

LIBICAL_ICAL_EXPORT icalrequeststatus icalenum_num_to_reqstat(short major, short minor);

LIBICAL_ICAL_EXPORT char *icalenum_reqstat_code(icalrequeststatus stat);

LIBICAL_ICAL_EXPORT char *icalenum_reqstat_code_r(icalrequeststatus stat);

/***********************************************************************
 * Conversion functions
**********************************************************************/

/* Thse routines used to be in icalenums.c, but were moved into the
   icalproperty, icalparameter, icalvalue, or icalcomponent modules. */

/*const char* icalproperty_kind_to_string(icalproperty_kind kind);*/
#define icalenum_property_kind_to_string(x) icalproperty_kind_to_string(x)

/*icalproperty_kind icalproperty_string_to_kind(const char* string)*/
#define icalenum_string_to_property_kind(x) icalproperty_string_to_kind(x)

/*icalvalue_kind icalproperty_kind_to_value_kind(icalproperty_kind kind);*/
#define icalenum_property_kind_to_value_kind(x) icalproperty_kind_to_value_kind(x)

/*const char* icalenum_method_to_string(icalproperty_method);*/
#define icalenum_method_to_string(x) icalproperty_method_to_string(x)

/*icalproperty_method icalenum_string_to_method(const char* string);*/
#define icalenum_string_to_method(x) icalproperty_string_to_method(x)

/*const char* icalenum_status_to_string(icalproperty_status);*/
#define icalenum_status_to_string(x) icalproperty_status_to_string(x)

/*icalproperty_status icalenum_string_to_status(const char* string);*/
#define icalenum_string_to_status(x) icalproperty_string_to_status(x)

/*icalvalue_kind icalenum_string_to_value_kind(const char* str);*/
#define icalenum_string_to_value_kind(x) icalvalue_string_to_kind(x)

/*const char* icalenum_value_kind_to_string(icalvalue_kind kind);*/
#define icalenum_value_kind_to_string(x) icalvalue_kind_to_string(x)

/*const char* icalenum_component_kind_to_string(icalcomponent_kind kind);*/
#define icalenum_component_kind_to_string(x) icalcomponent_kind_to_string(x)

/*icalcomponent_kind icalenum_string_to_component_kind(const char* string);*/
#define icalenum_string_to_component_kind(x) icalcomponent_string_to_kind(x)

#endif /* !ICALENUMS_H */

/*======================================================================
 FILE: icaltypes.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALTYPES_H
#define ICALTYPES_H

#include "libical_ical_export.h"


struct icaldatetimeperiodtype
{
    struct icaltimetype time;
    struct icalperiodtype period;
};

struct icalgeotype
{
    double lat;
    double lon;
};

struct icaltriggertype
{
    struct icaltimetype time;
    struct icaldurationtype duration;
};

LIBICAL_ICAL_EXPORT struct icaltriggertype icaltriggertype_from_int(const int reltime);

LIBICAL_ICAL_EXPORT struct icaltriggertype icaltriggertype_from_string(const char *str);

LIBICAL_ICAL_EXPORT int icaltriggertype_is_null_trigger(struct icaltriggertype tr);

LIBICAL_ICAL_EXPORT int icaltriggertype_is_bad_trigger(struct icaltriggertype tr);

/* struct icalreqstattype. This struct contains two string pointers,
but don't try to free either of them. The "desc" string is a pointer
to a static table inside the library.  Don't try to free it. The
"debug" string is a pointer into the string that the called passed
into to icalreqstattype_from_string. Don't try to free it either, and
don't use it after the original string has been freed.

BTW, you would get that original string from
*icalproperty_get_requeststatus() or icalvalue_get_text(), when
operating on the value of a request_status property. */

struct icalreqstattype
{
    icalrequeststatus code;
    const char *desc;
    const char *debug;
};

LIBICAL_ICAL_EXPORT struct icalreqstattype icalreqstattype_from_string(const char *str);

LIBICAL_ICAL_EXPORT const char *icalreqstattype_as_string(struct icalreqstattype);

LIBICAL_ICAL_EXPORT char *icalreqstattype_as_string_r(struct icalreqstattype);

struct icaltimezonephase
{
    const char *tzname;
    int is_stdandard;   /* 1 = standard tme, 0 = daylight savings time */
    struct icaltimetype dtstart;
    int offsetto;
    int tzoffsetfrom;
    const char *comment;
    struct icaldatetimeperiodtype rdate;
    const char *rrule;
};

struct icaltimezonetype
{
    const char *tzid;
    struct icaltimetype last_mod;
    const char *tzurl;

    /* Array of phases. The end of the array is a phase with tzname == 0 */
    struct icaltimezonephase *phases;
};

/* ical_unknown_token_handling :
 *    How should the ICAL library handle components, properties and parameters with
 *    unknown names?
 *    FIXME:  Currently only affects parameters.  Extend to components and properties.
 */
typedef enum ical_unknown_token_handling
{
    ICAL_ASSUME_IANA_TOKEN = 1,
    ICAL_DISCARD_TOKEN = 2,
    ICAL_TREAT_AS_ERROR = 3
} ical_unknown_token_handling;

LIBICAL_ICAL_EXPORT ical_unknown_token_handling ical_get_unknown_token_handling_setting(void);

LIBICAL_ICAL_EXPORT void ical_set_unknown_token_handling_setting(
    ical_unknown_token_handling newSetting);

#endif /* !ICALTYPES_H */

/*======================================================================
 FILE: icalarray.h
 CREATOR: Damon Chaplin 07 March 2001

 (C) COPYRIGHT 2001, Ximian, Inc.

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/** @file icalarray.h
 *
 *  @brief An array of arbitrarily-sized elements which grows
 *  dynamically as elements are added.
 */

#ifndef ICALARRAY_H
#define ICALARRAY_H

#include "libical_ical_export.h"

/**
 * @typedef icalarray
 * @brief A struct representing an icalarray object
 */
typedef struct _icalarray icalarray;
struct _icalarray
{
    size_t element_size;
    size_t increment_size;
    size_t num_elements;
    size_t space_allocated;
    void **chunks;
};

/**
 * @brief Creates new ::icalarray object.
 * @param element_size The size of the elements to be held by the array
 * @param increment_size How many extra elements worth of space to allocate on expansion
 * @return The new ::icalarray object
 * @sa icalarray_free()
 *
 * Creates a new ::icalarray object. The parameter @a element_size determines
 * the size of the elements that the array will hold (in bytes). The parameter
 * @a increment_size determines how many extra elements to be allocated when
 * expanding the array for performance reasons (expansions are expensive, since
 * it involves copying all existing elements).
 *
 * @par Error handling
 * If @a element_size or @a increment_size is not at least 1, using the ::icalarray
 * object results in undefined behaviour. If there is an error while creating the
 * object, it returns `NULL` and sets ::icalerrno to ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * The returned ::icalarray object is owned by the caller of the function,
 * and needs to be released properly after it's no longer needed with
 * icalarray_free().
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // use array
 * int a = 4;
 * icalarray_append(array, &a);
 * assert(*icalarray_element_at(array, 0) == a);
 *
 * // release memory
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT icalarray *icalarray_new(size_t element_size, size_t increment_size);

/**
 * @brief Copies an existing ::icalarray and it's elements, creating a new one.
 * @param array The array to copy
 * @return A new array, holding all the elements of @a array
 *
 * Creates a new ::icalarray object, copying all the existing elements from
 * @a array as well as it's properties (such as @a element_size and
 * @a increment_size) over.
 *
 * @par Error handling
 * If @a array is `NULL`, this method will return `NULL`. If there was an error
 * allocating memory while creating the copy, it will set ::icalerrno
 * to ::ICAL_ALLOCATION_ERROR.
 *
 * @par Ownership
 * The created copy is owned by the caller of the function, and needs to
 * be released with icalarray_free() after it's no longer being used.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // fill array
 * int a = 4;
 * icalarray_append(array, &a);
 *
 * // create copy of array
 * icalarray *copy = icalarray_copy(array);
 * assert(*icalarray_element_at(copy, 0) == a);
 *
 * // release arrays
 * icalarray_free(array);
 * icalarray_free(copy);
 * ```
 */
LIBICAL_ICAL_EXPORT icalarray *icalarray_copy(icalarray *array);

/**
 * @brief Frees an array object and everything that it contains.
 * @param array The array to release
 *
 * ### Example
 * ```c
 * // creating an array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // releasing it
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_free(icalarray *array);

/**
 * @brief Appends an element to an array.
 * @param array The array to append the element to
 * @param element The element to append
 *
 * Appends the given @a element to the @a array, reallocating
 * and expanding the array as needed.
 *
 * @par Error handling
 * If @a array or @a element is `NULL`, using this function results
 * in undefined behaviour (most likely a segfault).
 *
 * @par Ownership
 * The @a element does not get consumed by the method, since it creates
 * a copy of it
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // append data to it
 * int data = 42;
 * icalarray_append(array, &data);
 *
 * // release array
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_append(icalarray *array, const void *element);

/**
 * @brief Removes a given element from an array.
 * @brief array The array from which to remove the element
 * @brief position The position of the element to remove
 *
 * Removes the element at the given position from the array.
 *
 * @par Error handling
 * If @a array is `NULL`, using this function results in undefined behaviour.
 * If the array is empty, using this functino results in undefined behaviour.
 * If the @a position is non-existent, it removes the last element.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 2);
 *
 * // fill array
 * int data;
 * data = 4;
 * icalarray_append(array, &a);
 * data = 9;
 * icalarray_append(array, &a);
 * data = 7;
 * icalarray_append(array, &a);
 * data = 10;
 * icalarray_append(array, &a);
 *
 * // check array
 * assert(*icalarray_element_at(array, 0) == 4);
 * assert(*icalarray_element_at(array, 1) == 9);
 * assert(*icalarray_element_at(array, 2) == 7);
 * assert(*icalarray_element_at(array, 3) == 10);
 *
 * // remove the second element
 * icalarray_remove_element_at(array, 1);
 *
 * // check array
 * assert(*icalarray_element_at(array, 0) == 4);
 * assert(*icalarray_element_at(array, 1) == 7);
 * assert(*icalarray_element_at(array, 2) == 10);
 *
 * // release array
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_remove_element_at(icalarray *array, size_t position);

/**
 * @brief Access an array element
 * @param array The array object in which the element is stored
 * @param position The position of the element to access in the array
 * @return A pointer to the element inside the array
 *
 * Accesses an array element by returning a pointer to it, given an
 * @a array and a valid element @a position.
 *
 * @par Error handling
 * If @a array is `NULL`, using this function results in undefined behaviour.
 * If @a position is not a valid position in the array, using this function
 * results in undefined behaviour.
 *
 * @par Ownership
 * The element is owned by the ::icalarray, it must not be freed by
 * the user.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // fill array
 * int a = 4;
 * icalarray_append(array, &a);
 *
 * // access array element
 * int *element = icalarray_element_at(array, 0);
 * assert(element != NULL);
 * assert(*element == a);
 *
 * // change array element
 * *element = 14;
 * assert(*icalarray_element(array) == 14);
 *
 * // release memory
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void *icalarray_element_at(icalarray *array, size_t position);

/**
 * @brief Sorts the elements of an ::icalarray using the given comparison function.
 * @param array The array to sort
 * @param compare The comparison function to use
 *
 * @par Error handling
 * Passing `NULL` as either @a array or @a compare results in undefined
 * behaviour.
 *
 * ### Usage
 * ```c
 * int compare_ints(const void *a, const void *b) {
 *     return *((int*)a) - *((int*)b);
 * }
 *
 * int main(int argc, char *argv[]) {
 *     int numbers[] = {5, 2, 7, 4, 3, 1, 0, 8, 6, 9};
 *
 *     icalarray *array = icalarray_new(sizeof(int), 3);
 *
 *     // fill array
 *     for(int i = 0; i < 10; i++) {
 *         icalarray_append(array, &numbers[i]);
 *     }
 *
 *     // sort array
 *     icalarray_sort(array, compare_ints);
 *
 *     // print numbers
 *     for(int i = 0; i < 10; i++) {
 *         printf("%i\n", *((int*)icalarray_element_at(array, i)));
 *     }
 *
 *     return 0;
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_sort(icalarray *array,
                                        int (*compare) (const void *, const void *));

#endif /* ICALARRAY_H */

/*======================================================================
 FILE: icalrecur.h
 CREATOR: eric 20 March 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
========================================================================*/

/**
@file icalrecur.h
@brief Routines for dealing with recurring time

How to use:

1) Get a rule and a start time from a component

@code
        icalproperty rrule;
        struct icalrecurrencetype recur;
        struct icaltimetype dtstart;

        rrule = icalcomponent_get_first_property(comp,ICAL_RRULE_PROPERTY);
        recur = icalproperty_get_rrule(rrule);
        start = icalproperty_get_dtstart(dtstart);
@endcode

Or, just make them up:

@code
        recur = icalrecurrencetype_from_string("FREQ=YEARLY;BYDAY=SU,WE");
        dtstart = icaltime_from_string("19970101T123000")
@endcode

2) Create an iterator

@code
        icalrecur_iterator *ritr;
        ritr = icalrecur_iterator_new(recur,start);
@endcode

3) Iterator over the occurrences

@code
        struct icaltimetype next;
        while (next = icalrecur_iterator_next(ritr)
               && !icaltime_is_null_time(next){
                Do something with next
        }
@endcode

Note that that the time returned by icalrecur_iterator_next is in
whatever timezone that dtstart is in.

*/

#ifndef ICALRECUR_H
#define ICALRECUR_H

#include "libical_ical_export.h"


/*
 * Recurrence enumerations
 */

typedef enum icalrecurrencetype_frequency
{
    /* These enums are used to index an array, so don't change the
       order or the integers */

    ICAL_SECONDLY_RECURRENCE = 0,
    ICAL_MINUTELY_RECURRENCE = 1,
    ICAL_HOURLY_RECURRENCE = 2,
    ICAL_DAILY_RECURRENCE = 3,
    ICAL_WEEKLY_RECURRENCE = 4,
    ICAL_MONTHLY_RECURRENCE = 5,
    ICAL_YEARLY_RECURRENCE = 6,
    ICAL_NO_RECURRENCE = 7
} icalrecurrencetype_frequency;

typedef enum icalrecurrencetype_weekday
{
    ICAL_NO_WEEKDAY,
    ICAL_SUNDAY_WEEKDAY,
    ICAL_MONDAY_WEEKDAY,
    ICAL_TUESDAY_WEEKDAY,
    ICAL_WEDNESDAY_WEEKDAY,
    ICAL_THURSDAY_WEEKDAY,
    ICAL_FRIDAY_WEEKDAY,
    ICAL_SATURDAY_WEEKDAY
} icalrecurrencetype_weekday;

typedef enum icalrecurrencetype_skip
{
    ICAL_SKIP_BACKWARD = 0,
    ICAL_SKIP_FORWARD,
    ICAL_SKIP_OMIT,
    ICAL_SKIP_UNDEFINED
} icalrecurrencetype_skip;

enum icalrecurrence_array_max_values
{
    ICAL_RECURRENCE_ARRAY_MAX = 0x7f7f,
    ICAL_RECURRENCE_ARRAY_MAX_BYTE = 0x7f
};

/*
 * Recurrence enumerations conversion routines.
 */

LIBICAL_ICAL_EXPORT icalrecurrencetype_frequency icalrecur_string_to_freq(const char *str);
LIBICAL_ICAL_EXPORT const char *icalrecur_freq_to_string(icalrecurrencetype_frequency kind);

LIBICAL_ICAL_EXPORT icalrecurrencetype_skip icalrecur_string_to_skip(const char *str);
LIBICAL_ICAL_EXPORT const char *icalrecur_skip_to_string(icalrecurrencetype_skip kind);

LIBICAL_ICAL_EXPORT const char *icalrecur_weekday_to_string(icalrecurrencetype_weekday kind);
LIBICAL_ICAL_EXPORT icalrecurrencetype_weekday icalrecur_string_to_weekday(const char *str);

/**
 * Recurrence type routines
 */

/* See RFC 5545 Section 3.3.10, RECUR Value, and RFC 7529
 * for an explanation of the values and fields in struct icalrecurrencetype.
 *
 * The maximums below are based on lunisolar leap years (13 months)
 */
#define ICAL_BY_SECOND_SIZE     62      /* 0 to 60 */
#define ICAL_BY_MINUTE_SIZE     61      /* 0 to 59 */
#define ICAL_BY_HOUR_SIZE       25      /* 0 to 23 */
#define ICAL_BY_MONTH_SIZE      14      /* 1 to 13 */
#define ICAL_BY_MONTHDAY_SIZE   32      /* 1 to 31 */
#define ICAL_BY_WEEKNO_SIZE     56      /* 1 to 55 */
#define ICAL_BY_YEARDAY_SIZE    386     /* 1 to 385 */
#define ICAL_BY_SETPOS_SIZE     ICAL_BY_YEARDAY_SIZE          /* 1 to N */
#define ICAL_BY_DAY_SIZE        7*(ICAL_BY_WEEKNO_SIZE-1)+1   /* 1 to N */

/** Main struct for holding digested recurrence rules */
struct icalrecurrencetype
{
    icalrecurrencetype_frequency freq;

    /* until and count are mutually exclusive. */
    struct icaltimetype until;
    int count;

    short interval;

    icalrecurrencetype_weekday week_start;

    /* The BY* parameters can each take a list of values. Here I
     * assume that the list of values will not be larger than the
     * range of the value -- that is, the client will not name a
     * value more than once.

     * Each of the lists is terminated with the value
     * ICAL_RECURRENCE_ARRAY_MAX unless the list is full.
     */

    short by_second[ICAL_BY_SECOND_SIZE];
    short by_minute[ICAL_BY_MINUTE_SIZE];
    short by_hour[ICAL_BY_HOUR_SIZE];
    short by_day[ICAL_BY_DAY_SIZE];     /* Encoded value, see below */
    short by_month_day[ICAL_BY_MONTHDAY_SIZE];
    short by_year_day[ICAL_BY_YEARDAY_SIZE];
    short by_week_no[ICAL_BY_WEEKNO_SIZE];
    short by_month[ICAL_BY_MONTH_SIZE];
    short by_set_pos[ICAL_BY_SETPOS_SIZE];

    /* For RSCALE extension (RFC 7529) */
    char *rscale;
    icalrecurrencetype_skip skip;
};

LIBICAL_ICAL_EXPORT int icalrecurrencetype_rscale_is_supported(void);

LIBICAL_ICAL_EXPORT icalarray *icalrecurrencetype_rscale_supported_calendars(void);

LIBICAL_ICAL_EXPORT void icalrecurrencetype_clear(struct icalrecurrencetype *r);

/**
 * Array Encoding
 *
 * The 'day' element of the by_day array is encoded to allow
 * representation of both the day of the week ( Monday, Tueday), but also
 * the Nth day of the week ( First tuesday of the month, last thursday of
 * the year) These routines decode the day values
 */

/** 1 == Monday, etc. */
LIBICAL_ICAL_EXPORT enum icalrecurrencetype_weekday icalrecurrencetype_day_day_of_week(short day);

/** 0 == any of day of week. 1 == first, 2 = second, -2 == second to last, etc */
LIBICAL_ICAL_EXPORT int icalrecurrencetype_day_position(short day);

/**
 * The 'month' element of the by_month array is encoded to allow
 * representation of the "L" leap suffix (RFC 7529).
 * These routines decode the month values.
 */

LIBICAL_ICAL_EXPORT int icalrecurrencetype_month_is_leap(short month);

LIBICAL_ICAL_EXPORT int icalrecurrencetype_month_month(short month);

/** Recurrance rule parser */

/** Convert between strings and recurrencetype structures. */
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalrecurrencetype_from_string(const char *str);

LIBICAL_ICAL_EXPORT char *icalrecurrencetype_as_string(struct icalrecurrencetype *recur);

LIBICAL_ICAL_EXPORT char *icalrecurrencetype_as_string_r(struct icalrecurrencetype *recur);

/** Recurrence iteration routines */

typedef struct icalrecur_iterator_impl icalrecur_iterator;

/** Create a new recurrence rule iterator, starting at DTSTART */
LIBICAL_ICAL_EXPORT icalrecur_iterator *icalrecur_iterator_new(struct icalrecurrencetype rule,
                                                               struct icaltimetype dtstart);

/**
 * Sets the date-time at which the iterator will start,
 * where @p start is a value between DTSTART and UNTIL.
 *
 * NOTE: CAN NOT be used with RRULEs that contain COUNT.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT int icalrecur_iterator_set_start(icalrecur_iterator *impl,
                                                     struct icaltimetype start);

/** Get the next occurrence from an iterator */
LIBICAL_ICAL_EXPORT struct icaltimetype icalrecur_iterator_next(icalrecur_iterator *);

/** Free the iterator */
LIBICAL_ICAL_EXPORT void icalrecur_iterator_free(icalrecur_iterator *);

/**
 * Fills array up with at most 'count' time_t values, each
 *  representing an occurrence time in seconds past the POSIX epoch
 */
LIBICAL_ICAL_EXPORT int icalrecur_expand_recurrence(const char *rule, time_t start,
                                                    int count, time_t *array);

#endif

/*======================================================================
 FILE: icalattach.h
 CREATOR: acampi 28 May 02

 (C) COPYRIGHT 2002, Andrea Campi <a.campi@inet.it>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/**
 * @file icalattach.h
 * @brief A set of functions to handle iCal attachments.
 *
 * With the `ATTACH` property, the iCal standard defines a way to
 * associate a document object with a calendar component.
 *
 * These are represented with ::icalattach objects in libical.
 * This file contains functions to create and work with these
 * objects.
 */

#ifndef ICALATTACH_H
#define ICALATTACH_H

#include "libical_ical_export.h"

/**
 * @typedef icalattach
 * @brief An iCal attach object representing a link to a document object.
 *
 * Represents an association with a document object. ::icalattach objects
 * are reference counted, meaning that if the last reference to them is
 * removed (with icalattach_unref()), they are destroyed.
 */
typedef struct icalattach_impl icalattach;

/**
 * @typedef icalattach_free_fn_t
 * @brief (*unused*) Function to be called to free the data of an ::icalattach object.
 * @warning Currently not used
 *
 * This function type is used to free the data from an ::icalattach object created
 * with icalattach_new_from_data(). It is currently not used
 */
typedef void (*icalattach_free_fn_t) (unsigned char *data, void *user_data);

/**
 * @brief Create new ::icalattach object from a URL.
 * @param url The URL to create the object from
 * @return An ::icalattach object with the given URL as association
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a url is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. If there was an error allocating memory, it
 * returns `NULL` and sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The returned ::icalattach object is owned by the caller of the function.
 * ::icalattach objects are reference counted, which means that after
 * use, icalattach_unref() needs to be called to signal that they are
 * not used anymore.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks it
 * assert(icalattach_get_is_url(attach));
 * assert(0 == strcmp(icalattach_get_url(attach), "http://example.com"));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT icalattach *icalattach_new_from_url(const char *url);

/**
 * @brief Create new ::icalattach object from data.
 * @param data The data to create the ::icalattach from
 * @param free_fn (*unused*) The function to free the data
 * @param free_fn_data (*unused*) Data to pass to the @a free_fn
 * @return An ::icalattach object with the given data
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a url is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. If there was an error allocating memory, it
 * returns `NULL` and sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The returned ::icalattach object is owned by the caller of the function.
 * ::icalattach objects are reference counted, which means that after
 * use, icalattach_unref() needs to be called to signal that they are
 * not used anymore.
 */
LIBICAL_ICAL_EXPORT icalattach *icalattach_new_from_data(const char *data,
                                                         icalattach_free_fn_t free_fn,
                                                         void *free_fn_data);

/**
 * @brief Increments reference count of the ::icalattach.
 * @param attach The object to increase the reference count of
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a attach is `NULL`, or the reference count is smaller than 0,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * By increasing the refcount of @a attach, you are signaling that
 * you are using it, and it is the owner's responsibility to call
 * icalattach_unref() after it's no longer used.
 */
LIBICAL_ICAL_EXPORT void icalattach_ref(icalattach *attach);

/**
 * @brief Decrements reference count of the ::icalattach.
 * @param attach The object to decrease the reference count of
 * @sa icalattach_ref()
 *
 * Decreases the reference count of @a attach. If this was the
 * last user of the object, it is freed.
 *
 * @par Error handling
 * If @a attach is `NULL`, or the reference count is smaller than 0,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Calling this function releases the icalattach back to the library,
 * and it must not be used afterwards.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalattach_unref(icalattach *attach);

/**
 * @brief Determines if @a attach is an URL.
 * @param attach the ::icalattach object to check
 * @return 1 if it is a URL, otherwise 0.
 * @sa icalattach_get_url()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks if it is a URL
 * assert(icalattach_get_is_url(attach));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalattach_get_is_url(icalattach *attach);

/**
 * @brief Returns the URL of the ::icalattach object.
 * @param attach The object from which to return the URL
 * @return The URL of the object
 * @sa icalattach_get_is_url()
 *
 * Returns the URL of the ::icalattach object.
 *
 * @par Error handling
 * Returns `NULL` and set ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`. Undefined behaviour if the object is not
 * a URL (check with icalattach_get_is_url()).
 *
 * @par Ownership
 * The string returned is owned by libical and must not be freed
 * by the caller.
 *
 * # Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks it
 * assert(icalattach_get_is_url(attach));
 * assert(0 == strcmp(icalattach_get_url(attach), "http://example.com"));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalattach_get_url(icalattach *attach);

/**
 * @brief Returns the data of the ::icalattach object.
 * @param attach The object from which to return the data
 * @return The data of the object
 * @sa icalattach_get_is_url()
 *
 * Returns the URL of the ::icalattach object.
 *
 * @par Error handling
 * Returns `NULL` and set ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`. Undefined behaviour if the object is
 * a URL (check with icalattach_get_is_url()).
 *
 * @par Ownership
 * The string returned is owned by libical and must not be freed
 * by the caller.
 */
LIBICAL_ICAL_EXPORT unsigned char *icalattach_get_data(icalattach *attach);

#endif /* !ICALATTACH_H */

/*======================================================================
 FILE: icalvalue.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 1999, Eric Busboom  <eric@softwarestudio.org>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALDERIVEDVALUE_H
#define ICALDERIVEDVALUE_H

#include "libical_ical_export.h"


typedef struct icalvalue_impl icalvalue;

LIBICAL_ICAL_EXPORT void icalvalue_set_x(icalvalue *value, const char *v);
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_x(const char *v);
LIBICAL_ICAL_EXPORT const char *icalvalue_get_x(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_recur(struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_recur(icalvalue *value, struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalvalue_get_recur(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_trigger(struct icaltriggertype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_trigger(icalvalue *value, struct icaltriggertype v);
LIBICAL_ICAL_EXPORT struct icaltriggertype icalvalue_get_trigger(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_date(struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_date(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_date(icalvalue *value, struct icaltimetype v);

/**
 * Creates a new icalvalue representing the specified icaltimetype.
 * @param v is an @p icaltimetype
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetime(struct icaltimetype v);

/**
 * Returns the icaltimetype corresponding to the specified icalvalue.
 * @param a pointer to an icalvalue.
 * @returns the icaltimetype as datetime.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_datetime(const icalvalue *value);

/**
 * Sets an icalvalue for the specified icaltimetype.
 * @param value is a pointer to an icalvalue.
 * @param v is
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalvalue_set_datetime(icalvalue *value, struct icaltimetype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetimedate(struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_datetimedate(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_datetimedate(icalvalue *value, struct icaltimetype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetimeperiod(struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_datetimeperiod(icalvalue *value,
                                                      struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT struct icaldatetimeperiodtype icalvalue_get_datetimeperiod(const icalvalue *
                                                                               value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_geo(struct icalgeotype v);
LIBICAL_ICAL_EXPORT struct icalgeotype icalvalue_get_geo(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_geo(icalvalue *value, struct icalgeotype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_attach(icalattach *attach);
LIBICAL_ICAL_EXPORT void icalvalue_set_attach(icalvalue *value, icalattach *attach);
LIBICAL_ICAL_EXPORT icalattach *icalvalue_get_attach(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_binary(const char *v);
LIBICAL_ICAL_EXPORT void icalvalue_set_binary(icalvalue *value, const char *v);
LIBICAL_ICAL_EXPORT const char *icalvalue_get_binary(const icalvalue *value);

LIBICAL_ICAL_EXPORT void icalvalue_reset_kind(icalvalue *value);

typedef enum icalvalue_kind {
   ICAL_ANY_VALUE=5000,
    ICAL_ACTION_VALUE=5027,
    ICAL_ATTACH_VALUE=5003,
    ICAL_BINARY_VALUE=5011,
    ICAL_BOOLEAN_VALUE=5021,
    ICAL_BUSYTYPE_VALUE=5032,
    ICAL_CALADDRESS_VALUE=5023,
    ICAL_CARLEVEL_VALUE=5016,
    ICAL_CLASS_VALUE=5019,
    ICAL_CMD_VALUE=5010,
    ICAL_DATE_VALUE=5002,
    ICAL_DATETIME_VALUE=5028,
    ICAL_DATETIMEDATE_VALUE=5036,
    ICAL_DATETIMEPERIOD_VALUE=5015,
    ICAL_DURATION_VALUE=5020,
    ICAL_FLOAT_VALUE=5013,
    ICAL_GEO_VALUE=5004,
    ICAL_INTEGER_VALUE=5017,
    ICAL_METHOD_VALUE=5030,
    ICAL_PERIOD_VALUE=5014,
    ICAL_POLLCOMPLETION_VALUE=5034,
    ICAL_POLLMODE_VALUE=5033,
    ICAL_QUERY_VALUE=5001,
    ICAL_QUERYLEVEL_VALUE=5012,
    ICAL_RECUR_VALUE=5026,
    ICAL_REQUESTSTATUS_VALUE=5009,
    ICAL_STATUS_VALUE=5005,
    ICAL_STRING_VALUE=5007,
    ICAL_TASKMODE_VALUE=5035,
    ICAL_TEXT_VALUE=5008,
    ICAL_TRANSP_VALUE=5006,
    ICAL_TRIGGER_VALUE=5024,
    ICAL_URI_VALUE=5018,
    ICAL_UTCOFFSET_VALUE=5029,
    ICAL_X_VALUE=5022,
    ICAL_XLICCLASS_VALUE=5025,
   ICAL_NO_VALUE=5031
} icalvalue_kind ;

#define ICALPROPERTY_FIRST_ENUM 10000

typedef enum icalproperty_action {
    ICAL_ACTION_X = 10000,
    ICAL_ACTION_AUDIO = 10001,
    ICAL_ACTION_DISPLAY = 10002,
    ICAL_ACTION_EMAIL = 10003,
    ICAL_ACTION_PROCEDURE = 10004,
    ICAL_ACTION_NONE = 10099
} icalproperty_action;

typedef enum icalproperty_busytype {
    ICAL_BUSYTYPE_X = 10100,
    ICAL_BUSYTYPE_BUSY = 10101,
    ICAL_BUSYTYPE_BUSYUNAVAILABLE = 10102,
    ICAL_BUSYTYPE_BUSYTENTATIVE = 10103,
    ICAL_BUSYTYPE_NONE = 10199
} icalproperty_busytype;

typedef enum icalproperty_carlevel {
    ICAL_CARLEVEL_X = 10200,
    ICAL_CARLEVEL_CARNONE = 10201,
    ICAL_CARLEVEL_CARMIN = 10202,
    ICAL_CARLEVEL_CARFULL1 = 10203,
    ICAL_CARLEVEL_NONE = 10299
} icalproperty_carlevel;

typedef enum icalproperty_class {
    ICAL_CLASS_X = 10300,
    ICAL_CLASS_PUBLIC = 10301,
    ICAL_CLASS_PRIVATE = 10302,
    ICAL_CLASS_CONFIDENTIAL = 10303,
    ICAL_CLASS_NONE = 10399
} icalproperty_class;

typedef enum icalproperty_cmd {
    ICAL_CMD_X = 10400,
    ICAL_CMD_ABORT = 10401,
    ICAL_CMD_CONTINUE = 10402,
    ICAL_CMD_CREATE = 10403,
    ICAL_CMD_DELETE = 10404,
    ICAL_CMD_GENERATEUID = 10405,
    ICAL_CMD_GETCAPABILITY = 10406,
    ICAL_CMD_IDENTIFY = 10407,
    ICAL_CMD_MODIFY = 10408,
    ICAL_CMD_MOVE = 10409,
    ICAL_CMD_REPLY = 10410,
    ICAL_CMD_SEARCH = 10411,
    ICAL_CMD_SETLOCALE = 10412,
    ICAL_CMD_NONE = 10499
} icalproperty_cmd;

typedef enum icalproperty_method {
    ICAL_METHOD_X = 10500,
    ICAL_METHOD_PUBLISH = 10501,
    ICAL_METHOD_REQUEST = 10502,
    ICAL_METHOD_REPLY = 10503,
    ICAL_METHOD_ADD = 10504,
    ICAL_METHOD_CANCEL = 10505,
    ICAL_METHOD_REFRESH = 10506,
    ICAL_METHOD_COUNTER = 10507,
    ICAL_METHOD_DECLINECOUNTER = 10508,
    ICAL_METHOD_CREATE = 10509,
    ICAL_METHOD_READ = 10510,
    ICAL_METHOD_RESPONSE = 10511,
    ICAL_METHOD_MOVE = 10512,
    ICAL_METHOD_MODIFY = 10513,
    ICAL_METHOD_GENERATEUID = 10514,
    ICAL_METHOD_DELETE = 10515,
    ICAL_METHOD_POLLSTATUS = 10516,
    ICAL_METHOD_NONE = 10599
} icalproperty_method;

typedef enum icalproperty_pollcompletion {
    ICAL_POLLCOMPLETION_X = 10600,
    ICAL_POLLCOMPLETION_SERVER = 10601,
    ICAL_POLLCOMPLETION_SERVERSUBMIT = 10602,
    ICAL_POLLCOMPLETION_SERVERCHOICE = 10603,
    ICAL_POLLCOMPLETION_CLIENT = 10604,
    ICAL_POLLCOMPLETION_NONE = 10699
} icalproperty_pollcompletion;

typedef enum icalproperty_pollmode {
    ICAL_POLLMODE_X = 10700,
    ICAL_POLLMODE_BASIC = 10701,
    ICAL_POLLMODE_NONE = 10799
} icalproperty_pollmode;

typedef enum icalproperty_querylevel {
    ICAL_QUERYLEVEL_X = 10800,
    ICAL_QUERYLEVEL_CALQL1 = 10801,
    ICAL_QUERYLEVEL_CALQLNONE = 10802,
    ICAL_QUERYLEVEL_NONE = 10899
} icalproperty_querylevel;

typedef enum icalproperty_status {
    ICAL_STATUS_X = 10900,
    ICAL_STATUS_TENTATIVE = 10901,
    ICAL_STATUS_CONFIRMED = 10902,
    ICAL_STATUS_COMPLETED = 10903,
    ICAL_STATUS_NEEDSACTION = 10904,
    ICAL_STATUS_CANCELLED = 10905,
    ICAL_STATUS_INPROCESS = 10906,
    ICAL_STATUS_DRAFT = 10907,
    ICAL_STATUS_FINAL = 10908,
    ICAL_STATUS_SUBMITTED = 10909,
    ICAL_STATUS_PENDING = 10910,
    ICAL_STATUS_FAILED = 10911,
    ICAL_STATUS_DELETED = 10912,
    ICAL_STATUS_NONE = 10999
} icalproperty_status;

typedef enum icalproperty_taskmode {
    ICAL_TASKMODE_X = 11200,
    ICAL_TASKMODE_AUTOMATICCOMPLETION = 11201,
    ICAL_TASKMODE_AUTOMATICFAILURE = 11202,
    ICAL_TASKMODE_AUTOMATICSTATUS = 11203,
    ICAL_TASKMODE_NONE = 11299
} icalproperty_taskmode;

typedef enum icalproperty_transp {
    ICAL_TRANSP_X = 11000,
    ICAL_TRANSP_OPAQUE = 11001,
    ICAL_TRANSP_OPAQUENOCONFLICT = 11002,
    ICAL_TRANSP_TRANSPARENT = 11003,
    ICAL_TRANSP_TRANSPARENTNOCONFLICT = 11004,
    ICAL_TRANSP_NONE = 11099
} icalproperty_transp;

typedef enum icalproperty_xlicclass {
    ICAL_XLICCLASS_X = 11100,
    ICAL_XLICCLASS_PUBLISHNEW = 11101,
    ICAL_XLICCLASS_PUBLISHUPDATE = 11102,
    ICAL_XLICCLASS_PUBLISHFREEBUSY = 11103,
    ICAL_XLICCLASS_REQUESTNEW = 11104,
    ICAL_XLICCLASS_REQUESTUPDATE = 11105,
    ICAL_XLICCLASS_REQUESTRESCHEDULE = 11106,
    ICAL_XLICCLASS_REQUESTDELEGATE = 11107,
    ICAL_XLICCLASS_REQUESTNEWORGANIZER = 11108,
    ICAL_XLICCLASS_REQUESTFORWARD = 11109,
    ICAL_XLICCLASS_REQUESTSTATUS = 11110,
    ICAL_XLICCLASS_REQUESTFREEBUSY = 11111,
    ICAL_XLICCLASS_REPLYACCEPT = 11112,
    ICAL_XLICCLASS_REPLYDECLINE = 11113,
    ICAL_XLICCLASS_REPLYDELEGATE = 11114,
    ICAL_XLICCLASS_REPLYCRASHERACCEPT = 11115,
    ICAL_XLICCLASS_REPLYCRASHERDECLINE = 11116,
    ICAL_XLICCLASS_ADDINSTANCE = 11117,
    ICAL_XLICCLASS_CANCELEVENT = 11118,
    ICAL_XLICCLASS_CANCELINSTANCE = 11119,
    ICAL_XLICCLASS_CANCELALL = 11120,
    ICAL_XLICCLASS_REFRESH = 11121,
    ICAL_XLICCLASS_COUNTER = 11122,
    ICAL_XLICCLASS_DECLINECOUNTER = 11123,
    ICAL_XLICCLASS_MALFORMED = 11124,
    ICAL_XLICCLASS_OBSOLETE = 11125,
    ICAL_XLICCLASS_MISSEQUENCED = 11126,
    ICAL_XLICCLASS_UNKNOWN = 11127,
    ICAL_XLICCLASS_NONE = 11199
} icalproperty_xlicclass;

#define ICALPROPERTY_LAST_ENUM 11300

/* ACTION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_action(enum icalproperty_action v);
LIBICAL_ICAL_EXPORT enum icalproperty_action icalvalue_get_action(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_action(icalvalue *value, enum icalproperty_action v);

/* BOOLEAN */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_boolean(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_boolean(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_boolean(icalvalue *value, int v);

/* BUSYTYPE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_busytype(enum icalproperty_busytype v);
LIBICAL_ICAL_EXPORT enum icalproperty_busytype icalvalue_get_busytype(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_busytype(icalvalue *value, enum icalproperty_busytype v);

/* CAL-ADDRESS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_caladdress(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_caladdress(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_caladdress(icalvalue *value, const char * v);

/* CAR-LEVEL */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_carlevel(enum icalproperty_carlevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_carlevel icalvalue_get_carlevel(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_carlevel(icalvalue *value, enum icalproperty_carlevel v);

/* CMD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_cmd(enum icalproperty_cmd v);
LIBICAL_ICAL_EXPORT enum icalproperty_cmd icalvalue_get_cmd(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_cmd(icalvalue *value, enum icalproperty_cmd v);

/* DURATION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_duration(struct icaldurationtype v);
LIBICAL_ICAL_EXPORT struct icaldurationtype icalvalue_get_duration(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_duration(icalvalue *value, struct icaldurationtype v);

/* FLOAT */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_float(float v);
LIBICAL_ICAL_EXPORT float icalvalue_get_float(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_float(icalvalue *value, float v);

/* INTEGER */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_integer(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_integer(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_integer(icalvalue *value, int v);

/* METHOD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_method(enum icalproperty_method v);
LIBICAL_ICAL_EXPORT enum icalproperty_method icalvalue_get_method(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_method(icalvalue *value, enum icalproperty_method v);

/* PERIOD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_period(struct icalperiodtype v);
LIBICAL_ICAL_EXPORT struct icalperiodtype icalvalue_get_period(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_period(icalvalue *value, struct icalperiodtype v);

/* POLLCOMPLETION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_pollcompletion(enum icalproperty_pollcompletion v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollcompletion icalvalue_get_pollcompletion(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_pollcompletion(icalvalue *value, enum icalproperty_pollcompletion v);

/* POLLMODE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_pollmode(enum icalproperty_pollmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollmode icalvalue_get_pollmode(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_pollmode(icalvalue *value, enum icalproperty_pollmode v);

/* QUERY */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_query(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_query(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_query(icalvalue *value, const char * v);

/* QUERY-LEVEL */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_querylevel(enum icalproperty_querylevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_querylevel icalvalue_get_querylevel(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_querylevel(icalvalue *value, enum icalproperty_querylevel v);

/* REQUEST-STATUS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_requeststatus(struct icalreqstattype v);
LIBICAL_ICAL_EXPORT struct icalreqstattype icalvalue_get_requeststatus(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_requeststatus(icalvalue *value, struct icalreqstattype v);

/* STATUS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_status(enum icalproperty_status v);
LIBICAL_ICAL_EXPORT enum icalproperty_status icalvalue_get_status(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_status(icalvalue *value, enum icalproperty_status v);

/* STRING */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_string(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_string(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_string(icalvalue *value, const char * v);

/* TASKMODE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_taskmode(enum icalproperty_taskmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_taskmode icalvalue_get_taskmode(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_taskmode(icalvalue *value, enum icalproperty_taskmode v);

/* TEXT */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_text(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_text(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_text(icalvalue *value, const char * v);

/* TRANSP */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_transp(enum icalproperty_transp v);
LIBICAL_ICAL_EXPORT enum icalproperty_transp icalvalue_get_transp(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_transp(icalvalue *value, enum icalproperty_transp v);

/* URI */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_uri(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_uri(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_uri(icalvalue *value, const char * v);

/* UTC-OFFSET */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_utcoffset(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_utcoffset(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_utcoffset(icalvalue *value, int v);

/* X-LIC-CLASS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_xlicclass(enum icalproperty_xlicclass v);
LIBICAL_ICAL_EXPORT enum icalproperty_xlicclass icalvalue_get_xlicclass(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_xlicclass(icalvalue *value, enum icalproperty_xlicclass v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_class(enum icalproperty_class v);
LIBICAL_ICAL_EXPORT enum icalproperty_class icalvalue_get_class(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_class(icalvalue *value, enum icalproperty_class v);
#endif /*ICALVALUE_H*/

/*======================================================================
 FILE: icalparam.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

  The original code is icalparam.h
======================================================================*/
#ifndef ICALDERIVEDPARAMETER_H
#define ICALDERIVEDPARAMETER_H

#include "libical_ical_export.h"

typedef struct icalparameter_impl icalparameter;

LIBICAL_ICAL_EXPORT const char *icalparameter_enum_to_string(int e);
LIBICAL_ICAL_EXPORT int icalparameter_string_to_enum(const char *str);

/* START of section of machine generated code (mkderivedparameters.pl). Do not edit. */

typedef enum icalparameter_kind {
    ICAL_ANY_PARAMETER = 0,
    ICAL_ACTIONPARAM_PARAMETER = 1,
    ICAL_ALTREP_PARAMETER = 2,
    ICAL_CHARSET_PARAMETER = 3,
    ICAL_CN_PARAMETER = 4,
    ICAL_CUTYPE_PARAMETER = 5,
    ICAL_DELEGATEDFROM_PARAMETER = 6,
    ICAL_DELEGATEDTO_PARAMETER = 7,
    ICAL_DIR_PARAMETER = 8,
    ICAL_DISPLAY_PARAMETER = 46,
    ICAL_EMAIL_PARAMETER = 50,
    ICAL_ENABLE_PARAMETER = 9,
    ICAL_ENCODING_PARAMETER = 10,
    ICAL_FBTYPE_PARAMETER = 11,
    ICAL_FEATURE_PARAMETER = 48,
    ICAL_FILENAME_PARAMETER = 42,
    ICAL_FMTTYPE_PARAMETER = 12,
    ICAL_IANA_PARAMETER = 33,
    ICAL_ID_PARAMETER = 13,
    ICAL_LABEL_PARAMETER = 49,
    ICAL_LANGUAGE_PARAMETER = 14,
    ICAL_LATENCY_PARAMETER = 15,
    ICAL_LOCAL_PARAMETER = 16,
    ICAL_LOCALIZE_PARAMETER = 17,
    ICAL_MANAGEDID_PARAMETER = 40,
    ICAL_MEMBER_PARAMETER = 18,
    ICAL_MODIFIED_PARAMETER = 44,
    ICAL_OPTIONS_PARAMETER = 19,
    ICAL_PARTSTAT_PARAMETER = 20,
    ICAL_PATCHACTION_PARAMETER = 51,
    ICAL_PUBLICCOMMENT_PARAMETER = 37,
    ICAL_RANGE_PARAMETER = 21,
    ICAL_REASON_PARAMETER = 43,
    ICAL_RELATED_PARAMETER = 22,
    ICAL_RELTYPE_PARAMETER = 23,
    ICAL_REQUIRED_PARAMETER = 43,
    ICAL_RESPONSE_PARAMETER = 38,
    ICAL_ROLE_PARAMETER = 24,
    ICAL_RSVP_PARAMETER = 25,
    ICAL_SCHEDULEAGENT_PARAMETER = 34,
    ICAL_SCHEDULEFORCESEND_PARAMETER = 35,
    ICAL_SCHEDULESTATUS_PARAMETER = 36,
    ICAL_SENTBY_PARAMETER = 26,
    ICAL_SIZE_PARAMETER = 41,
    ICAL_STAYINFORMED_PARAMETER = 39,
    ICAL_SUBSTATE_PARAMETER = 45,
    ICAL_TZID_PARAMETER = 27,
    ICAL_VALUE_PARAMETER = 28,
    ICAL_X_PARAMETER = 29,
    ICAL_XLICCOMPARETYPE_PARAMETER = 30,
    ICAL_XLICERRORTYPE_PARAMETER = 31,
    ICAL_NO_PARAMETER = 32
} icalparameter_kind;

#define ICALPARAMETER_FIRST_ENUM 20000

typedef enum icalparameter_action {
    ICAL_ACTIONPARAM_X = 20000,
    ICAL_ACTIONPARAM_ASK = 20001,
    ICAL_ACTIONPARAM_ABORT = 20002,
    ICAL_ACTIONPARAM_NONE = 20099
} icalparameter_action;

typedef enum icalparameter_cutype {
    ICAL_CUTYPE_X = 20100,
    ICAL_CUTYPE_INDIVIDUAL = 20101,
    ICAL_CUTYPE_GROUP = 20102,
    ICAL_CUTYPE_RESOURCE = 20103,
    ICAL_CUTYPE_ROOM = 20104,
    ICAL_CUTYPE_UNKNOWN = 20105,
    ICAL_CUTYPE_NONE = 20199
} icalparameter_cutype;

typedef enum icalparameter_display {
    ICAL_DISPLAY_X = 22000,
    ICAL_DISPLAY_BADGE = 22001,
    ICAL_DISPLAY_GRAPHIC = 22002,
    ICAL_DISPLAY_FULLSIZE = 22003,
    ICAL_DISPLAY_THUMBNAIL = 22004,
    ICAL_DISPLAY_NONE = 22099
} icalparameter_display;

typedef enum icalparameter_enable {
    ICAL_ENABLE_X = 20200,
    ICAL_ENABLE_TRUE = 20201,
    ICAL_ENABLE_FALSE = 20202,
    ICAL_ENABLE_NONE = 20299
} icalparameter_enable;

typedef enum icalparameter_encoding {
    ICAL_ENCODING_X = 20300,
    ICAL_ENCODING_8BIT = 20301,
    ICAL_ENCODING_BASE64 = 20302,
    ICAL_ENCODING_NONE = 20399
} icalparameter_encoding;

typedef enum icalparameter_fbtype {
    ICAL_FBTYPE_X = 20400,
    ICAL_FBTYPE_FREE = 20401,
    ICAL_FBTYPE_BUSY = 20402,
    ICAL_FBTYPE_BUSYUNAVAILABLE = 20403,
    ICAL_FBTYPE_BUSYTENTATIVE = 20404,
    ICAL_FBTYPE_NONE = 20499
} icalparameter_fbtype;

typedef enum icalparameter_feature {
    ICAL_FEATURE_X = 22100,
    ICAL_FEATURE_AUDIO = 22101,
    ICAL_FEATURE_CHAT = 22102,
    ICAL_FEATURE_FEED = 22103,
    ICAL_FEATURE_MODERATOR = 22104,
    ICAL_FEATURE_PHONE = 22105,
    ICAL_FEATURE_SCREEN = 22106,
    ICAL_FEATURE_VIDEO = 22107,
    ICAL_FEATURE_NONE = 22199
} icalparameter_feature;

typedef enum icalparameter_local {
    ICAL_LOCAL_X = 20500,
    ICAL_LOCAL_TRUE = 20501,
    ICAL_LOCAL_FALSE = 20502,
    ICAL_LOCAL_NONE = 20599
} icalparameter_local;

typedef enum icalparameter_partstat {
    ICAL_PARTSTAT_X = 20600,
    ICAL_PARTSTAT_NEEDSACTION = 20601,
    ICAL_PARTSTAT_ACCEPTED = 20602,
    ICAL_PARTSTAT_DECLINED = 20603,
    ICAL_PARTSTAT_TENTATIVE = 20604,
    ICAL_PARTSTAT_DELEGATED = 20605,
    ICAL_PARTSTAT_COMPLETED = 20606,
    ICAL_PARTSTAT_INPROCESS = 20607,
    ICAL_PARTSTAT_FAILED = 20608,
    ICAL_PARTSTAT_NONE = 20699
} icalparameter_partstat;

typedef enum icalparameter_patchaction {
    ICAL_PATCHACTION_X = 22200,
    ICAL_PATCHACTION_CREATE = 22201,
    ICAL_PATCHACTION_BYNAME = 22202,
    ICAL_PATCHACTION_BYVALUE = 22203,
    ICAL_PATCHACTION_BYPARAM = 22204,
    ICAL_PATCHACTION_NONE = 22299
} icalparameter_patchaction;

typedef enum icalparameter_range {
    ICAL_RANGE_X = 20700,
    ICAL_RANGE_THISANDPRIOR = 20701,
    ICAL_RANGE_THISANDFUTURE = 20702,
    ICAL_RANGE_NONE = 20799
} icalparameter_range;

typedef enum icalparameter_related {
    ICAL_RELATED_X = 20800,
    ICAL_RELATED_START = 20801,
    ICAL_RELATED_END = 20802,
    ICAL_RELATED_NONE = 20899
} icalparameter_related;

typedef enum icalparameter_reltype {
    ICAL_RELTYPE_X = 20900,
    ICAL_RELTYPE_PARENT = 20901,
    ICAL_RELTYPE_CHILD = 20902,
    ICAL_RELTYPE_SIBLING = 20903,
    ICAL_RELTYPE_POLL = 20904,
    ICAL_RELTYPE_NONE = 20999
} icalparameter_reltype;

typedef enum icalparameter_required {
    ICAL_REQUIRED_X = 21000,
    ICAL_REQUIRED_TRUE = 21001,
    ICAL_REQUIRED_FALSE = 21002,
    ICAL_REQUIRED_NONE = 21099
} icalparameter_required;

typedef enum icalparameter_role {
    ICAL_ROLE_X = 21100,
    ICAL_ROLE_CHAIR = 21101,
    ICAL_ROLE_REQPARTICIPANT = 21102,
    ICAL_ROLE_OPTPARTICIPANT = 21103,
    ICAL_ROLE_NONPARTICIPANT = 21104,
    ICAL_ROLE_NONE = 21199
} icalparameter_role;

typedef enum icalparameter_rsvp {
    ICAL_RSVP_X = 21200,
    ICAL_RSVP_TRUE = 21201,
    ICAL_RSVP_FALSE = 21202,
    ICAL_RSVP_NONE = 21299
} icalparameter_rsvp;

typedef enum icalparameter_scheduleagent {
    ICAL_SCHEDULEAGENT_X = 21300,
    ICAL_SCHEDULEAGENT_SERVER = 21301,
    ICAL_SCHEDULEAGENT_CLIENT = 21302,
    ICAL_SCHEDULEAGENT_NONE = 21399
} icalparameter_scheduleagent;

typedef enum icalparameter_scheduleforcesend {
    ICAL_SCHEDULEFORCESEND_X = 21400,
    ICAL_SCHEDULEFORCESEND_REQUEST = 21401,
    ICAL_SCHEDULEFORCESEND_REPLY = 21402,
    ICAL_SCHEDULEFORCESEND_NONE = 21499
} icalparameter_scheduleforcesend;

typedef enum icalparameter_stayinformed {
    ICAL_STAYINFORMED_X = 21500,
    ICAL_STAYINFORMED_TRUE = 21501,
    ICAL_STAYINFORMED_FALSE = 21502,
    ICAL_STAYINFORMED_NONE = 21599
} icalparameter_stayinformed;

typedef enum icalparameter_substate {
    ICAL_SUBSTATE_X = 21900,
    ICAL_SUBSTATE_OK = 21901,
    ICAL_SUBSTATE_ERROR = 21902,
    ICAL_SUBSTATE_SUSPENDED = 21903,
    ICAL_SUBSTATE_NONE = 21999
} icalparameter_substate;

typedef enum icalparameter_value {
    ICAL_VALUE_X = 21600,
    ICAL_VALUE_BINARY = 21601,
    ICAL_VALUE_BOOLEAN = 21602,
    ICAL_VALUE_DATE = 21603,
    ICAL_VALUE_DURATION = 21604,
    ICAL_VALUE_FLOAT = 21605,
    ICAL_VALUE_INTEGER = 21606,
    ICAL_VALUE_PERIOD = 21607,
    ICAL_VALUE_RECUR = 21608,
    ICAL_VALUE_TEXT = 21609,
    ICAL_VALUE_URI = 21610,
    ICAL_VALUE_ERROR = 21611,
    ICAL_VALUE_DATETIME = 21612,
    ICAL_VALUE_UTCOFFSET = 21613,
    ICAL_VALUE_CALADDRESS = 21614,
    ICAL_VALUE_NONE = 21699
} icalparameter_value;

typedef enum icalparameter_xliccomparetype {
    ICAL_XLICCOMPARETYPE_X = 21700,
    ICAL_XLICCOMPARETYPE_EQUAL = 21701,
    ICAL_XLICCOMPARETYPE_NOTEQUAL = 21702,
    ICAL_XLICCOMPARETYPE_LESS = 21703,
    ICAL_XLICCOMPARETYPE_GREATER = 21704,
    ICAL_XLICCOMPARETYPE_LESSEQUAL = 21705,
    ICAL_XLICCOMPARETYPE_GREATEREQUAL = 21706,
    ICAL_XLICCOMPARETYPE_REGEX = 21707,
    ICAL_XLICCOMPARETYPE_ISNULL = 21708,
    ICAL_XLICCOMPARETYPE_ISNOTNULL = 21709,
    ICAL_XLICCOMPARETYPE_NONE = 21799
} icalparameter_xliccomparetype;

typedef enum icalparameter_xlicerrortype {
    ICAL_XLICERRORTYPE_X = 21800,
    ICAL_XLICERRORTYPE_COMPONENTPARSEERROR = 21801,
    ICAL_XLICERRORTYPE_PROPERTYPARSEERROR = 21802,
    ICAL_XLICERRORTYPE_PARAMETERNAMEPARSEERROR = 21803,
    ICAL_XLICERRORTYPE_PARAMETERVALUEPARSEERROR = 21804,
    ICAL_XLICERRORTYPE_VALUEPARSEERROR = 21805,
    ICAL_XLICERRORTYPE_INVALIDITIP = 21806,
    ICAL_XLICERRORTYPE_UNKNOWNVCALPROPERROR = 21807,
    ICAL_XLICERRORTYPE_MIMEPARSEERROR = 21808,
    ICAL_XLICERRORTYPE_VCALPROPPARSEERROR = 21809,
    ICAL_XLICERRORTYPE_NONE = 21899
} icalparameter_xlicerrortype;

#define ICALPARAMETER_LAST_ENUM 22300

/* ACTIONPARAM */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_actionparam(icalparameter_action v);
LIBICAL_ICAL_EXPORT icalparameter_action icalparameter_get_actionparam(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_actionparam(icalparameter *value, icalparameter_action v);

/* ALTREP */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_altrep(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_altrep(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_altrep(icalparameter *value, const char * v);

/* CHARSET */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_charset(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_charset(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_charset(icalparameter *value, const char * v);

/* CN */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_cn(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_cn(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_cn(icalparameter *value, const char * v);

/* CUTYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_cutype(icalparameter_cutype v);
LIBICAL_ICAL_EXPORT icalparameter_cutype icalparameter_get_cutype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_cutype(icalparameter *value, icalparameter_cutype v);

/* DELEGATED-FROM */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_delegatedfrom(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_delegatedfrom(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_delegatedfrom(icalparameter *value, const char * v);

/* DELEGATED-TO */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_delegatedto(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_delegatedto(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_delegatedto(icalparameter *value, const char * v);

/* DIR */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_dir(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_dir(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_dir(icalparameter *value, const char * v);

/* DISPLAY */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_display(icalparameter_display v);
LIBICAL_ICAL_EXPORT icalparameter_display icalparameter_get_display(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_display(icalparameter *value, icalparameter_display v);

/* EMAIL */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_email(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_email(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_email(icalparameter *value, const char * v);

/* ENABLE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_enable(icalparameter_enable v);
LIBICAL_ICAL_EXPORT icalparameter_enable icalparameter_get_enable(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_enable(icalparameter *value, icalparameter_enable v);

/* ENCODING */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_encoding(icalparameter_encoding v);
LIBICAL_ICAL_EXPORT icalparameter_encoding icalparameter_get_encoding(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_encoding(icalparameter *value, icalparameter_encoding v);

/* FBTYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_fbtype(icalparameter_fbtype v);
LIBICAL_ICAL_EXPORT icalparameter_fbtype icalparameter_get_fbtype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_fbtype(icalparameter *value, icalparameter_fbtype v);

/* FEATURE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_feature(icalparameter_feature v);
LIBICAL_ICAL_EXPORT icalparameter_feature icalparameter_get_feature(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_feature(icalparameter *value, icalparameter_feature v);

/* FILENAME */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_filename(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_filename(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_filename(icalparameter *value, const char * v);

/* FMTTYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_fmttype(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_fmttype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_fmttype(icalparameter *value, const char * v);

/* IANA */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_iana(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_iana(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_iana(icalparameter *value, const char * v);

/* ID */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_id(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_id(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_id(icalparameter *value, const char * v);

/* LABEL */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_label(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_label(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_label(icalparameter *value, const char * v);

/* LANGUAGE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_language(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_language(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_language(icalparameter *value, const char * v);

/* LATENCY */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_latency(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_latency(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_latency(icalparameter *value, const char * v);

/* LOCAL */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_local(icalparameter_local v);
LIBICAL_ICAL_EXPORT icalparameter_local icalparameter_get_local(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_local(icalparameter *value, icalparameter_local v);

/* LOCALIZE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_localize(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_localize(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_localize(icalparameter *value, const char * v);

/* MANAGED-ID */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_managedid(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_managedid(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_managedid(icalparameter *value, const char * v);

/* MEMBER */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_member(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_member(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_member(icalparameter *value, const char * v);

/* MODIFIED */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_modified(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_modified(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_modified(icalparameter *value, const char * v);

/* OPTIONS */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_options(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_options(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_options(icalparameter *value, const char * v);

/* PARTSTAT */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_partstat(icalparameter_partstat v);
LIBICAL_ICAL_EXPORT icalparameter_partstat icalparameter_get_partstat(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_partstat(icalparameter *value, icalparameter_partstat v);

/* PATCH-ACTION */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_patchaction(icalparameter_patchaction v);
LIBICAL_ICAL_EXPORT icalparameter_patchaction icalparameter_get_patchaction(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_patchaction(icalparameter *value, icalparameter_patchaction v);

/* PUBLIC-COMMENT */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_publiccomment(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_publiccomment(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_publiccomment(icalparameter *value, const char * v);

/* RANGE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_range(icalparameter_range v);
LIBICAL_ICAL_EXPORT icalparameter_range icalparameter_get_range(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_range(icalparameter *value, icalparameter_range v);

/* REASON */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_reason(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_reason(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_reason(icalparameter *value, const char * v);

/* RELATED */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_related(icalparameter_related v);
LIBICAL_ICAL_EXPORT icalparameter_related icalparameter_get_related(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_related(icalparameter *value, icalparameter_related v);

/* RELTYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_reltype(icalparameter_reltype v);
LIBICAL_ICAL_EXPORT icalparameter_reltype icalparameter_get_reltype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_reltype(icalparameter *value, icalparameter_reltype v);

/* REQUIRED */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_required(icalparameter_required v);
LIBICAL_ICAL_EXPORT icalparameter_required icalparameter_get_required(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_required(icalparameter *value, icalparameter_required v);

/* RESPONSE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_response(int v);
LIBICAL_ICAL_EXPORT int icalparameter_get_response(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_response(icalparameter *value, int v);

/* ROLE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_role(icalparameter_role v);
LIBICAL_ICAL_EXPORT icalparameter_role icalparameter_get_role(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_role(icalparameter *value, icalparameter_role v);

/* RSVP */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_rsvp(icalparameter_rsvp v);
LIBICAL_ICAL_EXPORT icalparameter_rsvp icalparameter_get_rsvp(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_rsvp(icalparameter *value, icalparameter_rsvp v);

/* SCHEDULE-AGENT */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_scheduleagent(icalparameter_scheduleagent v);
LIBICAL_ICAL_EXPORT icalparameter_scheduleagent icalparameter_get_scheduleagent(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_scheduleagent(icalparameter *value, icalparameter_scheduleagent v);

/* SCHEDULE-FORCE-SEND */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_scheduleforcesend(icalparameter_scheduleforcesend v);
LIBICAL_ICAL_EXPORT icalparameter_scheduleforcesend icalparameter_get_scheduleforcesend(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_scheduleforcesend(icalparameter *value, icalparameter_scheduleforcesend v);

/* SCHEDULE-STATUS */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_schedulestatus(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_schedulestatus(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_schedulestatus(icalparameter *value, const char * v);

/* SENT-BY */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_sentby(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_sentby(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_sentby(icalparameter *value, const char * v);

/* SIZE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_size(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_size(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_size(icalparameter *value, const char * v);

/* STAY-INFORMED */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_stayinformed(icalparameter_stayinformed v);
LIBICAL_ICAL_EXPORT icalparameter_stayinformed icalparameter_get_stayinformed(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_stayinformed(icalparameter *value, icalparameter_stayinformed v);

/* SUBSTATE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_substate(icalparameter_substate v);
LIBICAL_ICAL_EXPORT icalparameter_substate icalparameter_get_substate(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_substate(icalparameter *value, icalparameter_substate v);

/* TZID */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_tzid(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_tzid(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_tzid(icalparameter *value, const char * v);

/* VALUE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_value(icalparameter_value v);
LIBICAL_ICAL_EXPORT icalparameter_value icalparameter_get_value(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_value(icalparameter *value, icalparameter_value v);

/* X */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_x(const char * v);
LIBICAL_ICAL_EXPORT const char * icalparameter_get_x(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_x(icalparameter *value, const char * v);

/* X-LIC-COMPARETYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_xliccomparetype(icalparameter_xliccomparetype v);
LIBICAL_ICAL_EXPORT icalparameter_xliccomparetype icalparameter_get_xliccomparetype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_xliccomparetype(icalparameter *value, icalparameter_xliccomparetype v);

/* X-LIC-ERRORTYPE */
LIBICAL_ICAL_EXPORT icalparameter * icalparameter_new_xlicerrortype(icalparameter_xlicerrortype v);
LIBICAL_ICAL_EXPORT icalparameter_xlicerrortype icalparameter_get_xlicerrortype(const icalparameter *value);
LIBICAL_ICAL_EXPORT void icalparameter_set_xlicerrortype(icalparameter *value, icalparameter_xlicerrortype v);

#endif /*ICALPARAMETER_H*/

/* END   of section of machine generated code (mkderivedparameters.pl). Do not edit. */


/*======================================================================
 FILE: icalvalue.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
 ======================================================================*/

#ifndef ICALVALUE_H
#define ICALVALUE_H

#include "libical_ical_export.h"


#define ICAL_BOOLEAN_TRUE  1
#define ICAL_BOOLEAN_FALSE 0

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new(icalvalue_kind kind);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_clone(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_from_string(icalvalue_kind kind, const char *str);

LIBICAL_ICAL_EXPORT void icalvalue_free(icalvalue *value);

LIBICAL_ICAL_EXPORT int icalvalue_is_valid(const icalvalue *value);

LIBICAL_ICAL_EXPORT const char *icalvalue_as_ical_string(const icalvalue *value);

LIBICAL_ICAL_EXPORT char *icalvalue_as_ical_string_r(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue_kind icalvalue_isa(const icalvalue *value);

LIBICAL_ICAL_EXPORT int icalvalue_isa_value(void *);

LIBICAL_ICAL_EXPORT icalparameter_xliccomparetype icalvalue_compare(const icalvalue *a,
                                                                    const icalvalue *b);

/* Special, non autogenerated value accessors */

/* Defined in icalderivedvalue.h */
/* icalvalue* icalvalue_new_recur (struct icalrecurrencetype v); */
/* void icalvalue_set_recur(icalvalue* value, struct icalrecurrencetype v); */
/* struct icalrecurrencetype icalvalue_get_recur(const icalvalue* value); */

/* icalvalue* icalvalue_new_trigger (struct icaltriggertype v); */
/* void icalvalue_set_trigger(icalvalue* value, struct icaltriggertype v); */
/* struct icaltriggertype icalvalue_get_trigger(const icalvalue* value); */

/* icalvalue* icalvalue_new_datetimeperiod (struct icaldatetimeperiodtype v); */
/* void icalvalue_set_datetimeperiod(icalvalue* value, */
/*                                struct icaldatetimeperiodtype v); */
/* struct icaldatetimeperiodtype icalvalue_get_datetimeperiod(const icalvalue* value); */

/* Convert enumerations */

LIBICAL_ICAL_EXPORT icalvalue_kind icalvalue_string_to_kind(const char *str);

LIBICAL_ICAL_EXPORT const char *icalvalue_kind_to_string(const icalvalue_kind kind);

/** Check validity of a specific icalvalue_kind **/
LIBICAL_ICAL_EXPORT int icalvalue_kind_is_valid(const icalvalue_kind kind);

/** Encode a character string in ical format, esacpe certain characters, etc. */
LIBICAL_ICAL_EXPORT int icalvalue_encode_ical_string(const char *szText,
                                                     char *szEncText, int MaxBufferLen);

/** Extract the original character string encoded by the above function **/
LIBICAL_ICAL_EXPORT int icalvalue_decode_ical_string(const char *szText,
                                                     char *szDecText, int nMaxBufferLen);

/* For the library only -- do not make visible */
extern void print_date_to_string(char *str, const struct icaltimetype *data);
extern void print_datetime_to_string(char *str, const struct icaltimetype *data);

#endif /*ICALVALUE_H */

/*======================================================================
  FILE: icalparam.h
  CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/**
 * @file icalparameter.h
 *
 * Functions to work with ical parameter objects, which represent
 * parameters to property objects.
 */

#ifndef ICALPARAMETER_H
#define ICALPARAMETER_H

#include "libical_ical_export.h"


/* Declared in icalderivedparameter.h */
/*typedef struct icalparameter_impl icalparameter;*/

/**
 * @brief Creates new ::icalparameter object.
 * @param kind The kind of ::icalparameter to create.
 * @return An ::icalparameter with the given kind.
 *
 * @par Error handling
 * If there was an internal error regarding
 * memory allocation, it returns `NULL` and sets
 * ::icalerrno to ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *parameter = icalparameter_new();
 *
 * if(parameter) {
 *     // use parameter ...
 * }
 *
 * // release parameter
 * icalparameter_free(parameter);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new(icalparameter_kind kind);

/**
 * @brief Creates new ::icalparameter as a clone of the given one.
 * @param p The existing, non-`NULL` parameter to clone.
 * @return An ::icalparameter that is a clone of the given one.
 *
 * @par Error handling
 * If @a p is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If there was an internal error cloning the data, it returns `NULL`
 * without reporting any error in ::icalerrno.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```x
 * // create an icalparameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // clone the parameter
 * icalparameter *clone = icalparameter_new_clone(param);
 *
 * if(clone) {
 *     // use clone ...
 * }
 *
 * // release parameters
 * icalparameter_free(param);
 * icalparameter_free(clone);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_clone(icalparameter *p);

/**
 * @brief Create ::icalparameter object from string
 * @param value The string from which to create the ::icalparameter, in the form `"PARAMNAME=VALUE"`
 * @return An ::icalparameter that corresponds to the given string.
 *
 * @par Error handling
 * If there was an internal error copying data, it returns `NULL` and sets
 * ::icalerrno to ::ICAL_NEWFAILED_ERROR. If @a value was `NULL`, it returns
 * `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR. If @a value was malformed,
 * it returns `NULL` and sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     // use param ...
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_from_string(const char *value);

/**
 * @brief Create ::icalparameter of a given @a kind with a given @a value
 * @param kind The kind of ::icalparameter to create
 * @param value The value of the parameter
 * @return An ::icalparameter with the given kind and value.
 *
 * @par Error handling
 * If value is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Example
 * ```c
 * // create new parameter
 * icalparameter *param;
 * param = icalparameter_new_from_value_string(ICAL_ROLE_PARAMETER, "CHAIR");
 *
 * // check parameter
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "ROLE"));
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "CHAIR"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_from_value_string(icalparameter_kind kind,
                                                                       const char *value);

/**
 * @brief Frees an ::icalparameter object.
 * @param parameter The icalparameter to free
 *
 * This method needs to be used on all parameter objects returned
 * from any of the `_new()` methods including icalparameter_new(), icalparameter_new_clone(),
 * icalparameter_new_from_string() and icalparameter_new_from_value_string(),
 * when they are not needed anymore and to be released.
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new();
 *
 * if(param) {
 *     // use param...
 * }
 *
 * // after use, release it
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_free(icalparameter *parameter);

/**
 * @brief Convert ::icalparameter into an string representation
 * @param parameter The ::icalparameter to convert
 * @return A string representing the parameter according to RFC5445/RFC6868.
 * @sa icalparameter_as_ical_string_r()
 *
 * @par Error handling
 * If there is any error, the method returns `NULL`. Furthermore,
 * if @a parameter is `NULL`, it also sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If it doesn't recognize the kind of the parameter, it sets ::icalerrno
 * it ::ICAL_BADARG_ERROR. If the parameter is otherwise malformed, it
 * sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Strings returned by this method are owned by libical, they must
 * not be freed and they may be reclaimed with the next call into
 * the library. A version of this function, which returns strings
 * that are not owned by libical, is icalparameter_as_ical_string_r().
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     printf("%s\n", icalparameter_as_ical_string(param));
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalparameter_as_ical_string(icalparameter *parameter);

/**
 * @brief Convert ::icalparameter into an string representation
 * @param parameter The ::icalparameter to convert
 * @return A string representing the parameter according to RFC5445/RFC6868.
 * @sa icalparameter_as_ical_string()
 *
 * @par Error handling
 * If there is any error, the method returns `NULL`. Furthermore,
 * if parameter is `NULL`, it also sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If it doesn't recognize the kind of the parameter, it sets ::icalerrno
 * to ::ICAL_BADARG_ERROR. If the parameter is otherwise malformed, it
 * sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Strings returned by this method are owned by the caller, thus they need
 * to be manually `free()`d after use. A version of this function which returns
 * strings that do not need to be freed manually is
 * icalparameter_as_ical_string().
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     char *str = icalparameter_as_ical_string(param);
 *     printf("%s\n", str);
 *     free(str);
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalparameter_as_ical_string_r(icalparameter *parameter);

/**
 * Returns the icalparameter_kind of parameter.
 *
 * @param parameter The icalparameter whose kind to determine
 * @return The icalparameter_kind of the parameter
 *
 * @b Error handling
 * Returns ICAL_NO_PARAMETER when passed NULL.
 *
 * @b Usage
 * @code
 * // create parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // check what type of parameter this is
 * assert(icalparameter_isa(param) == ICAL_ROLE_PARAMETER);
 *
 * // release memory
 * icalparameter_free(param);
 * @endcode
 */
LIBICAL_ICAL_EXPORT icalparameter_kind icalparameter_isa(icalparameter *parameter);

/**
 * Determine if the given param is an icalparameter
 * @param param The libical-originated object to check
 * @return 1 if the object is an icalparameter, 0 otherwise.
 * @note This function expects to be given an object originating from
 *  libical - if this function is passed anything that is not from
 *  libical, it's behavior is undefined.
 *
 * @b Error handling
 * When given a `NULL` object, it returns 0.
 *
 * @b Usage
 * ```c
 * // create parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // check if it's a parameter
 * assert(icalparameter_isa_parameter(param));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalparameter_isa_parameter(void *param);

/* Access the name of an X parameter */

/**
 * @brief Sets the X-name of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The X-name to set @a param to
 * @sa icalparameter_get_xname()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets xname
 * icalparameter_set_xname(param, "X-TEST");
 *
 * // compare xname
 * assert(0 == strcmp(icalparameter_get_xname(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_xname(icalparameter *param, const char *v);

/**
 * @brief Returns the X-name of @a param
 * @param param The ::icalparameter whose X-name is to be returned
 * @return A string representing the X-name of @a param
 * @sa icalparameter_set_xname()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets xname
 * icalparameter_set_xname(param, "X-TEST");
 *
 * // compare xname
 * assert(0 == strcmp(icalparameter_get_xname(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_xname(icalparameter *param);

/**
 * @brief Sets the X-value of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The X-value to set @a param to
 * @sa icalparameter_get_xvalue()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("X-TEST=FAIL");
 *
 * // set test to success
 * icalparameter_set_xvalue(param, "SUCCESS");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_xvalue(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_xvalue(icalparameter *param, const char *v);

/**
 * @brief Returns the X-value of @a param
 * @param param The ::icalparameter whose X-value is to be returned
 * @return A string representing the X-value of @a param
 * @sa icalparameter_set_xvalue()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("X-TEST=FAIL");
 *
 * // set test to success
 * icalparameter_set_xvalue(param, "SUCCESS");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_xvalue(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_xvalue(icalparameter *param);

/* Access the name of an IANA parameter */

/**
 * @brief Sets the IANA name of @a param to @a v
 * @param param The icalparameter to change
 * @param v The IANA name to set @a param to
 * @sa icalparameter_get_iana_name()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets iana name
 * icalparameter_set_iana_name(param, "ROLE");
 *
 * // compare iana name
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_iana_name(icalparameter *param, const char *v);

/**
 * @brief Returns the IANA name of @a param
 * @param param The ::icalparameter whose IANA name is to be returned
 * @return A string representing the IANA name of @a param
 * @sa icalparameter_set_iana_name()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets iana name
 * icalparameter_set_iana_name(param, "X-TEST");
 *
 * // compare iana name
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_iana_name(icalparameter *param);

/**
 * @brief Sets the IANA value of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The IANA value to set @a param to
 * @sa icalparameter_get_iana_value()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=ATTENDEE");
 *
 * // set role to chair
 * icalparameter_set_iana_value(param, "CHAIR");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_iana_value(icalparameter *param, const char *v);

/**
 * @brief Returns the IANA value of @a param
 * @param param The ::icalparameter whose value is to be returned
 * @return A string representing the value of @a param
 * @sa icalparameter_set_iana_value()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=ATTENDEE");
 *
 * // set role to chair
 * icalparameter_set_iana_value(param, "CHAIR");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_iana_value(icalparameter *param);

/**
 * @brief Determines if two parameters have the same name
 * @param param1 First parameter to compare
 * @param param2 Second parameter to compare
 * @return 1 if they have the same name, 0 otherwise.
 *
 * @par Error handling
 * If either of @a param1 or @a param2 are `NULL`, it returns 0 and sets
 * ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Does not take ownership of either ::icalparameter.
 *
 * ### Example
 * ```c
 * // create two parameters
 * icalparameter *param1 = icalparameter_new_from_string("ROLE=CHAIR");
 * icalparameter *param2 = icalparameter_new_from_string("EMAIL=mailto@example.com");
 *
 * // compare parameter names for equality
 * assert(icalparameter_has_same_name(param1, param2) == 0);
 *
 * // release memory
 * icalparameter_free(param1);
 * icalparameter_free(param2);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalparameter_has_same_name(icalparameter *param1, icalparameter *param2);

/* Convert enumerations */

/**
 * @brief Returns a string representing the given ::icalparameter_kind
 * @param kind The icalparameter_kind
 * @return A string representing kind
 *
 * @par Error handling
 * When passed a non-existing ::icalparameter_kind, it returns `NULL`.
 *
 * @par Ownership
 * The string that is returned by this function is owned by libical and
 * must not be freed by the caller.
 *
 * ### Usage
 * ```c
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_ROLE_PARAMETER), "ROLE"));
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_EMAIL_PARAMETER), "EMAIL));
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_ID_PARAMETER), "ID"));
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_kind_to_string(icalparameter_kind kind);

/**
 * @brief Returns the ::icalparameter_kind for a given string
 * @param string A string describing an icalparameter_kind
 * @return An icalparameter_kind
 *
 * @par Error handling
 * Returns ::ICAL_NO_PARAMETER if @a string is `NULL`.
 * If it can't find the parameter, depending on
 * the ical_get_unknown_token_handling_setting(), it returns either
 * ::ICAL_NO_PARAMETER or ::ICAL_IANA_PARAMETER.
 *
 * @par Ownership
 * Does not take ownership of @a string.
 *
 * ### Usage
 * ```c
 * assert(icalparameter_string_to_kind("ROLE")  == ICAL_ROLE_PARAMETER);
 * assert(icalparameter_string_to_kind("EMAIL") == ICAL_EMAIL_PARAMETER);
 * assert(icalparameter_string_to_kind("ID")    == ICAL_ID_PARAMETER);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter_kind icalparameter_string_to_kind(const char *string);

/**
 * @brief Checks the validity of a ::icalparameter_kind
 * @param kind The icalparameter_kind
 * @return 1 if if the kind is valid, 0 otherwise
 *
 * ### Usage
 * ```c
 * assert(icalparameter_kind_is_valid(ICAL_ROLE_PARAMETER));
 * ```
 * @since 3.0.4
 */
LIBICAL_ICAL_EXPORT int icalparameter_kind_is_valid(const icalparameter_kind kind);

#endif

/*======================================================================
 FILE: icalderivedproperty.h
 CREATOR: eric 09 May 1999

 (C) COPYRIGHT 1999, Eric Busboom <eric@softwarestudio.org>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

  Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
 ======================================================================*/

#ifndef ICALDERIVEDPROPERTY_H
#define ICALDERIVEDPROPERTY_H

#include <time.h>


typedef struct icalproperty_impl icalproperty;

typedef enum icalproperty_kind {
    ICAL_ANY_PROPERTY = 0,
    ICAL_ACCEPTRESPONSE_PROPERTY = 102,
    ICAL_ACKNOWLEDGED_PROPERTY = 1,
    ICAL_ACTION_PROPERTY = 2,
    ICAL_ALLOWCONFLICT_PROPERTY = 3,
    ICAL_ATTACH_PROPERTY = 4,
    ICAL_ATTENDEE_PROPERTY = 5,
    ICAL_BUSYTYPE_PROPERTY = 101,
    ICAL_CALID_PROPERTY = 6,
    ICAL_CALMASTER_PROPERTY = 7,
    ICAL_CALSCALE_PROPERTY = 8,
    ICAL_CAPVERSION_PROPERTY = 9,
    ICAL_CARLEVEL_PROPERTY = 10,
    ICAL_CARID_PROPERTY = 11,
    ICAL_CATEGORIES_PROPERTY = 12,
    ICAL_CLASS_PROPERTY = 13,
    ICAL_CMD_PROPERTY = 14,
    ICAL_COLOR_PROPERTY = 118,
    ICAL_COMMENT_PROPERTY = 15,
    ICAL_COMPLETED_PROPERTY = 16,
    ICAL_COMPONENTS_PROPERTY = 17,
    ICAL_CONFERENCE_PROPERTY = 120,
    ICAL_CONTACT_PROPERTY = 18,
    ICAL_CREATED_PROPERTY = 19,
    ICAL_CSID_PROPERTY = 20,
    ICAL_DATEMAX_PROPERTY = 21,
    ICAL_DATEMIN_PROPERTY = 22,
    ICAL_DECREED_PROPERTY = 23,
    ICAL_DEFAULTCHARSET_PROPERTY = 24,
    ICAL_DEFAULTLOCALE_PROPERTY = 25,
    ICAL_DEFAULTTZID_PROPERTY = 26,
    ICAL_DEFAULTVCARS_PROPERTY = 27,
    ICAL_DENY_PROPERTY = 28,
    ICAL_DESCRIPTION_PROPERTY = 29,
    ICAL_DTEND_PROPERTY = 30,
    ICAL_DTSTAMP_PROPERTY = 31,
    ICAL_DTSTART_PROPERTY = 32,
    ICAL_DUE_PROPERTY = 33,
    ICAL_DURATION_PROPERTY = 34,
    ICAL_ESTIMATEDDURATION_PROPERTY = 113,
    ICAL_EXDATE_PROPERTY = 35,
    ICAL_EXPAND_PROPERTY = 36,
    ICAL_EXRULE_PROPERTY = 37,
    ICAL_FREEBUSY_PROPERTY = 38,
    ICAL_GEO_PROPERTY = 39,
    ICAL_GRANT_PROPERTY = 40,
    ICAL_IMAGE_PROPERTY = 119,
    ICAL_ITIPVERSION_PROPERTY = 41,
    ICAL_LASTMODIFIED_PROPERTY = 42,
    ICAL_LOCATION_PROPERTY = 43,
    ICAL_MAXCOMPONENTSIZE_PROPERTY = 44,
    ICAL_MAXDATE_PROPERTY = 45,
    ICAL_MAXRESULTS_PROPERTY = 46,
    ICAL_MAXRESULTSSIZE_PROPERTY = 47,
    ICAL_METHOD_PROPERTY = 48,
    ICAL_MINDATE_PROPERTY = 49,
    ICAL_MULTIPART_PROPERTY = 50,
    ICAL_NAME_PROPERTY = 115,
    ICAL_ORGANIZER_PROPERTY = 52,
    ICAL_OWNER_PROPERTY = 53,
    ICAL_PATCHDELETE_PROPERTY = 124,
    ICAL_PATCHORDER_PROPERTY = 122,
    ICAL_PATCHPARAMETER_PROPERTY = 125,
    ICAL_PATCHTARGET_PROPERTY = 123,
    ICAL_PATCHVERSION_PROPERTY = 121,
    ICAL_PERCENTCOMPLETE_PROPERTY = 54,
    ICAL_PERMISSION_PROPERTY = 55,
    ICAL_POLLCOMPLETION_PROPERTY = 110,
    ICAL_POLLITEMID_PROPERTY = 103,
    ICAL_POLLMODE_PROPERTY = 104,
    ICAL_POLLPROPERTIES_PROPERTY = 105,
    ICAL_POLLWINNER_PROPERTY = 106,
    ICAL_PRIORITY_PROPERTY = 56,
    ICAL_PRODID_PROPERTY = 57,
    ICAL_QUERY_PROPERTY = 58,
    ICAL_QUERYLEVEL_PROPERTY = 59,
    ICAL_QUERYID_PROPERTY = 60,
    ICAL_QUERYNAME_PROPERTY = 61,
    ICAL_RDATE_PROPERTY = 62,
    ICAL_RECURACCEPTED_PROPERTY = 63,
    ICAL_RECUREXPAND_PROPERTY = 64,
    ICAL_RECURLIMIT_PROPERTY = 65,
    ICAL_RECURRENCEID_PROPERTY = 66,
    ICAL_REFRESHINTERVAL_PROPERTY = 116,
    ICAL_RELATEDTO_PROPERTY = 67,
    ICAL_RELCALID_PROPERTY = 68,
    ICAL_REPEAT_PROPERTY = 69,
    ICAL_REPLYURL_PROPERTY = 111,
    ICAL_REQUESTSTATUS_PROPERTY = 70,
    ICAL_RESOURCES_PROPERTY = 71,
    ICAL_RESPONSE_PROPERTY = 112,
    ICAL_RESTRICTION_PROPERTY = 72,
    ICAL_RRULE_PROPERTY = 73,
    ICAL_SCOPE_PROPERTY = 74,
    ICAL_SEQUENCE_PROPERTY = 75,
    ICAL_SOURCE_PROPERTY = 117,
    ICAL_STATUS_PROPERTY = 76,
    ICAL_STORESEXPANDED_PROPERTY = 77,
    ICAL_SUMMARY_PROPERTY = 78,
    ICAL_TARGET_PROPERTY = 79,
    ICAL_TASKMODE_PROPERTY = 114,
    ICAL_TRANSP_PROPERTY = 80,
    ICAL_TRIGGER_PROPERTY = 81,
    ICAL_TZID_PROPERTY = 82,
    ICAL_TZIDALIASOF_PROPERTY = 108,
    ICAL_TZNAME_PROPERTY = 83,
    ICAL_TZOFFSETFROM_PROPERTY = 84,
    ICAL_TZOFFSETTO_PROPERTY = 85,
    ICAL_TZUNTIL_PROPERTY = 109,
    ICAL_TZURL_PROPERTY = 86,
    ICAL_UID_PROPERTY = 87,
    ICAL_URL_PROPERTY = 88,
    ICAL_VERSION_PROPERTY = 89,
    ICAL_VOTER_PROPERTY = 107,
    ICAL_X_PROPERTY = 90,
    ICAL_XLICCLASS_PROPERTY = 91,
    ICAL_XLICCLUSTERCOUNT_PROPERTY = 92,
    ICAL_XLICERROR_PROPERTY = 93,
    ICAL_XLICMIMECHARSET_PROPERTY = 94,
    ICAL_XLICMIMECID_PROPERTY = 95,
    ICAL_XLICMIMECONTENTTYPE_PROPERTY = 96,
    ICAL_XLICMIMEENCODING_PROPERTY = 97,
    ICAL_XLICMIMEFILENAME_PROPERTY = 98,
    ICAL_XLICMIMEOPTINFO_PROPERTY = 99,
    ICAL_NO_PROPERTY = 100
} icalproperty_kind;

/* ACCEPT-RESPONSE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_acceptresponse(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_acceptresponse(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_acceptresponse(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_acceptresponse(const char * v, ...);

/* ACKNOWLEDGED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_acknowledged(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_acknowledged(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_acknowledged(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_acknowledged(struct icaltimetype v, ...);

/* ACTION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_action(enum icalproperty_action v);
LIBICAL_ICAL_EXPORT void icalproperty_set_action(icalproperty *prop, enum icalproperty_action v);
LIBICAL_ICAL_EXPORT enum icalproperty_action icalproperty_get_action(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_action(enum icalproperty_action v, ...);

/* ALLOW-CONFLICT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_allowconflict(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_allowconflict(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_allowconflict(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_allowconflict(const char * v, ...);

/* ATTACH */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_attach(icalattach * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_attach(icalproperty *prop, icalattach * v);
LIBICAL_ICAL_EXPORT icalattach * icalproperty_get_attach(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_attach(icalattach * v, ...);

/* ATTENDEE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_attendee(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_attendee(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_attendee(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_attendee(const char * v, ...);

/* BUSYTYPE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_busytype(enum icalproperty_busytype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_busytype(icalproperty *prop, enum icalproperty_busytype v);
LIBICAL_ICAL_EXPORT enum icalproperty_busytype icalproperty_get_busytype(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_busytype(enum icalproperty_busytype v, ...);

/* CALID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_calid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_calid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_calid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_calid(const char * v, ...);

/* CALMASTER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_calmaster(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_calmaster(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_calmaster(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_calmaster(const char * v, ...);

/* CALSCALE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_calscale(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_calscale(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_calscale(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_calscale(const char * v, ...);

/* CAP-VERSION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_capversion(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_capversion(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_capversion(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_capversion(const char * v, ...);

/* CAR-LEVEL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_carlevel(enum icalproperty_carlevel v);
LIBICAL_ICAL_EXPORT void icalproperty_set_carlevel(icalproperty *prop, enum icalproperty_carlevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_carlevel icalproperty_get_carlevel(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_carlevel(enum icalproperty_carlevel v, ...);

/* CARID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_carid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_carid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_carid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_carid(const char * v, ...);

/* CATEGORIES */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_categories(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_categories(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_categories(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_categories(const char * v, ...);

/* CLASS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_class(enum icalproperty_class v);
LIBICAL_ICAL_EXPORT void icalproperty_set_class(icalproperty *prop, enum icalproperty_class v);
LIBICAL_ICAL_EXPORT enum icalproperty_class icalproperty_get_class(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_class(enum icalproperty_class v, ...);

/* CMD */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_cmd(enum icalproperty_cmd v);
LIBICAL_ICAL_EXPORT void icalproperty_set_cmd(icalproperty *prop, enum icalproperty_cmd v);
LIBICAL_ICAL_EXPORT enum icalproperty_cmd icalproperty_get_cmd(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_cmd(enum icalproperty_cmd v, ...);

/* COLOR */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_color(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_color(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_color(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_color(const char * v, ...);

/* COMMENT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_comment(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_comment(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_comment(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_comment(const char * v, ...);

/* COMPLETED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_completed(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_completed(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_completed(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_completed(struct icaltimetype v, ...);

/* COMPONENTS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_components(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_components(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_components(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_components(const char * v, ...);

/* CONFERENCE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_conference(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_conference(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_conference(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_conference(const char * v, ...);

/* CONTACT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_contact(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_contact(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_contact(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_contact(const char * v, ...);

/* CREATED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_created(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_created(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_created(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_created(struct icaltimetype v, ...);

/* CSID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_csid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_csid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_csid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_csid(const char * v, ...);

/* DATE-MAX */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_datemax(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_datemax(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_datemax(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_datemax(struct icaltimetype v, ...);

/* DATE-MIN */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_datemin(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_datemin(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_datemin(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_datemin(struct icaltimetype v, ...);

/* DECREED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_decreed(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_decreed(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_decreed(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_decreed(const char * v, ...);

/* DEFAULT-CHARSET */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_defaultcharset(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_defaultcharset(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_defaultcharset(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_defaultcharset(const char * v, ...);

/* DEFAULT-LOCALE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_defaultlocale(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_defaultlocale(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_defaultlocale(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_defaultlocale(const char * v, ...);

/* DEFAULT-TZID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_defaulttzid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_defaulttzid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_defaulttzid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_defaulttzid(const char * v, ...);

/* DEFAULT-VCARS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_defaultvcars(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_defaultvcars(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_defaultvcars(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_defaultvcars(const char * v, ...);

/* DENY */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_deny(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_deny(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_deny(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_deny(const char * v, ...);

/* DESCRIPTION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_description(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_description(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_description(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_description(const char * v, ...);

/* DTEND */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_dtend(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_dtend(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_dtend(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_dtend(struct icaltimetype v, ...);

/* DTSTAMP */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_dtstamp(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_dtstamp(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_dtstamp(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_dtstamp(struct icaltimetype v, ...);

/* DTSTART */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_dtstart(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_dtstart(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_dtstart(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_dtstart(struct icaltimetype v, ...);

/* DUE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_due(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_due(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_due(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_due(struct icaltimetype v, ...);

/* DURATION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_duration(struct icaldurationtype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_duration(icalproperty *prop, struct icaldurationtype v);
LIBICAL_ICAL_EXPORT struct icaldurationtype icalproperty_get_duration(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_duration(struct icaldurationtype v, ...);

/* ESTIMATED-DURATION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_estimatedduration(struct icaldurationtype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_estimatedduration(icalproperty *prop, struct icaldurationtype v);
LIBICAL_ICAL_EXPORT struct icaldurationtype icalproperty_get_estimatedduration(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_estimatedduration(struct icaldurationtype v, ...);

/* EXDATE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_exdate(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_exdate(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_exdate(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_exdate(struct icaltimetype v, ...);

/* EXPAND */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_expand(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_expand(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_expand(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_expand(int v, ...);

/* EXRULE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_exrule(struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_exrule(icalproperty *prop, struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalproperty_get_exrule(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_exrule(struct icalrecurrencetype v, ...);

/* FREEBUSY */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_freebusy(struct icalperiodtype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_freebusy(icalproperty *prop, struct icalperiodtype v);
LIBICAL_ICAL_EXPORT struct icalperiodtype icalproperty_get_freebusy(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_freebusy(struct icalperiodtype v, ...);

/* GEO */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_geo(struct icalgeotype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_geo(icalproperty *prop, struct icalgeotype v);
LIBICAL_ICAL_EXPORT struct icalgeotype icalproperty_get_geo(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_geo(struct icalgeotype v, ...);

/* GRANT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_grant(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_grant(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_grant(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_grant(const char * v, ...);

/* IMAGE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_image(icalattach * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_image(icalproperty *prop, icalattach * v);
LIBICAL_ICAL_EXPORT icalattach * icalproperty_get_image(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_image(icalattach * v, ...);

/* ITIP-VERSION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_itipversion(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_itipversion(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_itipversion(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_itipversion(const char * v, ...);

/* LAST-MODIFIED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_lastmodified(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_lastmodified(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_lastmodified(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_lastmodified(struct icaltimetype v, ...);

/* LOCATION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_location(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_location(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_location(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_location(const char * v, ...);

/* MAX-COMPONENT-SIZE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_maxcomponentsize(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_maxcomponentsize(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_maxcomponentsize(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_maxcomponentsize(int v, ...);

/* MAXDATE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_maxdate(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_maxdate(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_maxdate(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_maxdate(struct icaltimetype v, ...);

/* MAXRESULTS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_maxresults(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_maxresults(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_maxresults(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_maxresults(int v, ...);

/* MAXRESULTSSIZE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_maxresultssize(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_maxresultssize(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_maxresultssize(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_maxresultssize(int v, ...);

/* METHOD */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_method(enum icalproperty_method v);
LIBICAL_ICAL_EXPORT void icalproperty_set_method(icalproperty *prop, enum icalproperty_method v);
LIBICAL_ICAL_EXPORT enum icalproperty_method icalproperty_get_method(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_method(enum icalproperty_method v, ...);

/* MINDATE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_mindate(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_mindate(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_mindate(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_mindate(struct icaltimetype v, ...);

/* MULTIPART */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_multipart(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_multipart(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_multipart(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_multipart(const char * v, ...);

/* NAME */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_name(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_name(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_name(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_name(const char * v, ...);

/* ORGANIZER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_organizer(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_organizer(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_organizer(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_organizer(const char * v, ...);

/* OWNER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_owner(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_owner(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_owner(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_owner(const char * v, ...);

/* PATCH-DELETE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_patchdelete(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_patchdelete(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_patchdelete(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_patchdelete(const char * v, ...);

/* PATCH-ORDER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_patchorder(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_patchorder(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_patchorder(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_patchorder(int v, ...);

/* PATCH-PARAMETER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_patchparameter(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_patchparameter(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_patchparameter(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_patchparameter(const char * v, ...);

/* PATCH-TARGET */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_patchtarget(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_patchtarget(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_patchtarget(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_patchtarget(const char * v, ...);

/* PATCH-VERSION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_patchversion(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_patchversion(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_patchversion(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_patchversion(const char * v, ...);

/* PERCENT-COMPLETE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_percentcomplete(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_percentcomplete(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_percentcomplete(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_percentcomplete(int v, ...);

/* PERMISSION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_permission(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_permission(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_permission(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_permission(const char * v, ...);

/* POLL-COMPLETION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_pollcompletion(enum icalproperty_pollcompletion v);
LIBICAL_ICAL_EXPORT void icalproperty_set_pollcompletion(icalproperty *prop, enum icalproperty_pollcompletion v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollcompletion icalproperty_get_pollcompletion(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_pollcompletion(enum icalproperty_pollcompletion v, ...);

/* POLL-ITEM-ID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_pollitemid(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_pollitemid(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_pollitemid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_pollitemid(int v, ...);

/* POLL-MODE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_pollmode(enum icalproperty_pollmode v);
LIBICAL_ICAL_EXPORT void icalproperty_set_pollmode(icalproperty *prop, enum icalproperty_pollmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollmode icalproperty_get_pollmode(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_pollmode(enum icalproperty_pollmode v, ...);

/* POLL-PROPERTIES */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_pollproperties(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_pollproperties(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_pollproperties(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_pollproperties(const char * v, ...);

/* POLL-WINNER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_pollwinner(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_pollwinner(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_pollwinner(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_pollwinner(int v, ...);

/* PRIORITY */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_priority(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_priority(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_priority(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_priority(int v, ...);

/* PRODID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_prodid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_prodid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_prodid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_prodid(const char * v, ...);

/* QUERY */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_query(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_query(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_query(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_query(const char * v, ...);

/* QUERY-LEVEL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_querylevel(enum icalproperty_querylevel v);
LIBICAL_ICAL_EXPORT void icalproperty_set_querylevel(icalproperty *prop, enum icalproperty_querylevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_querylevel icalproperty_get_querylevel(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_querylevel(enum icalproperty_querylevel v, ...);

/* QUERYID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_queryid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_queryid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_queryid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_queryid(const char * v, ...);

/* QUERYNAME */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_queryname(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_queryname(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_queryname(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_queryname(const char * v, ...);

/* RDATE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_rdate(struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_rdate(icalproperty *prop, struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT struct icaldatetimeperiodtype icalproperty_get_rdate(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_rdate(struct icaldatetimeperiodtype v, ...);

/* RECUR-ACCEPTED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_recuraccepted(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_recuraccepted(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_recuraccepted(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_recuraccepted(const char * v, ...);

/* RECUR-EXPAND */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_recurexpand(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_recurexpand(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_recurexpand(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_recurexpand(const char * v, ...);

/* RECUR-LIMIT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_recurlimit(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_recurlimit(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_recurlimit(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_recurlimit(const char * v, ...);

/* RECURRENCE-ID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_recurrenceid(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_recurrenceid(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_recurrenceid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_recurrenceid(struct icaltimetype v, ...);

/* REFRESH-INTERVAL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_refreshinterval(struct icaldurationtype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_refreshinterval(icalproperty *prop, struct icaldurationtype v);
LIBICAL_ICAL_EXPORT struct icaldurationtype icalproperty_get_refreshinterval(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_refreshinterval(struct icaldurationtype v, ...);

/* RELATED-TO */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_relatedto(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_relatedto(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_relatedto(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_relatedto(const char * v, ...);

/* RELCALID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_relcalid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_relcalid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_relcalid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_relcalid(const char * v, ...);

/* REPEAT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_repeat(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_repeat(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_repeat(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_repeat(int v, ...);

/* REPLY-URL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_replyurl(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_replyurl(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_replyurl(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_replyurl(const char * v, ...);

/* REQUEST-STATUS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_requeststatus(struct icalreqstattype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_requeststatus(icalproperty *prop, struct icalreqstattype v);
LIBICAL_ICAL_EXPORT struct icalreqstattype icalproperty_get_requeststatus(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_requeststatus(struct icalreqstattype v, ...);

/* RESOURCES */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_resources(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_resources(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_resources(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_resources(const char * v, ...);

/* RESPONSE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_response(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_response(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_response(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_response(int v, ...);

/* RESTRICTION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_restriction(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_restriction(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_restriction(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_restriction(const char * v, ...);

/* RRULE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_rrule(struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_rrule(icalproperty *prop, struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalproperty_get_rrule(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_rrule(struct icalrecurrencetype v, ...);

/* SCOPE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_scope(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_scope(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_scope(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_scope(const char * v, ...);

/* SEQUENCE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_sequence(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_sequence(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_sequence(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_sequence(int v, ...);

/* SOURCE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_source(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_source(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_source(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_source(const char * v, ...);

/* STATUS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_status(enum icalproperty_status v);
LIBICAL_ICAL_EXPORT void icalproperty_set_status(icalproperty *prop, enum icalproperty_status v);
LIBICAL_ICAL_EXPORT enum icalproperty_status icalproperty_get_status(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_status(enum icalproperty_status v, ...);

/* STORES-EXPANDED */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_storesexpanded(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_storesexpanded(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_storesexpanded(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_storesexpanded(const char * v, ...);

/* SUMMARY */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_summary(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_summary(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_summary(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_summary(const char * v, ...);

/* TARGET */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_target(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_target(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_target(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_target(const char * v, ...);

/* TASK-MODE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_taskmode(enum icalproperty_taskmode v);
LIBICAL_ICAL_EXPORT void icalproperty_set_taskmode(icalproperty *prop, enum icalproperty_taskmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_taskmode icalproperty_get_taskmode(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_taskmode(enum icalproperty_taskmode v, ...);

/* TRANSP */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_transp(enum icalproperty_transp v);
LIBICAL_ICAL_EXPORT void icalproperty_set_transp(icalproperty *prop, enum icalproperty_transp v);
LIBICAL_ICAL_EXPORT enum icalproperty_transp icalproperty_get_transp(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_transp(enum icalproperty_transp v, ...);

/* TRIGGER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_trigger(struct icaltriggertype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_trigger(icalproperty *prop, struct icaltriggertype v);
LIBICAL_ICAL_EXPORT struct icaltriggertype icalproperty_get_trigger(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_trigger(struct icaltriggertype v, ...);

/* TZID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_tzid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzid(const char * v, ...);

/* TZID-ALIAS-OF */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzidaliasof(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzidaliasof(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_tzidaliasof(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzidaliasof(const char * v, ...);

/* TZNAME */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzname(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzname(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_tzname(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzname(const char * v, ...);

/* TZOFFSETFROM */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzoffsetfrom(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzoffsetfrom(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_tzoffsetfrom(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzoffsetfrom(int v, ...);

/* TZOFFSETTO */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzoffsetto(int v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzoffsetto(icalproperty *prop, int v);
LIBICAL_ICAL_EXPORT int icalproperty_get_tzoffsetto(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzoffsetto(int v, ...);

/* TZUNTIL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzuntil(struct icaltimetype v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzuntil(icalproperty *prop, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_tzuntil(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzuntil(struct icaltimetype v, ...);

/* TZURL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_tzurl(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_tzurl(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_tzurl(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_tzurl(const char * v, ...);

/* UID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_uid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_uid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_uid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_uid(const char * v, ...);

/* URL */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_url(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_url(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_url(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_url(const char * v, ...);

/* VERSION */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_version(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_version(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_version(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_version(const char * v, ...);

/* VOTER */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_voter(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_voter(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_voter(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_voter(const char * v, ...);

/* X */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_x(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_x(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_x(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_x(const char * v, ...);

/* X-LIC-CLASS */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicclass(enum icalproperty_xlicclass v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicclass(icalproperty *prop, enum icalproperty_xlicclass v);
LIBICAL_ICAL_EXPORT enum icalproperty_xlicclass icalproperty_get_xlicclass(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicclass(enum icalproperty_xlicclass v, ...);

/* X-LIC-CLUSTERCOUNT */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicclustercount(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicclustercount(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicclustercount(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicclustercount(const char * v, ...);

/* X-LIC-ERROR */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicerror(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicerror(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicerror(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicerror(const char * v, ...);

/* X-LIC-MIMECHARSET */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimecharset(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimecharset(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimecharset(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimecharset(const char * v, ...);

/* X-LIC-MIMECID */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimecid(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimecid(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimecid(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimecid(const char * v, ...);

/* X-LIC-MIMECONTENTTYPE */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimecontenttype(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimecontenttype(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimecontenttype(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimecontenttype(const char * v, ...);

/* X-LIC-MIMEENCODING */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimeencoding(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimeencoding(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimeencoding(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimeencoding(const char * v, ...);

/* X-LIC-MIMEFILENAME */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimefilename(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimefilename(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimefilename(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimefilename(const char * v, ...);

/* X-LIC-MIMEOPTINFO */
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_xlicmimeoptinfo(const char * v);
LIBICAL_ICAL_EXPORT void icalproperty_set_xlicmimeoptinfo(icalproperty *prop, const char * v);
LIBICAL_ICAL_EXPORT const char * icalproperty_get_xlicmimeoptinfo(const icalproperty *prop);
LIBICAL_ICAL_EXPORT icalproperty *icalproperty_vanew_xlicmimeoptinfo(const char * v, ...);

#endif /*ICALPROPERTY_H*/

/*======================================================================
 FILE: icalproperty.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALPROPERTY_H
#define ICALPROPERTY_H

#include "libical_ical_export.h"
        /* To get icalproperty_kind enumerations */

#include <stdarg.h>     /* for va_... */

LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new(icalproperty_kind kind);

LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_impl(icalproperty_kind kind);

LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_clone(icalproperty *prop);

LIBICAL_ICAL_EXPORT icalproperty *icalproperty_new_from_string(const char *str);

LIBICAL_ICAL_EXPORT const char *icalproperty_as_ical_string(icalproperty *prop);

LIBICAL_ICAL_EXPORT char *icalproperty_as_ical_string_r(icalproperty *prop);

LIBICAL_ICAL_EXPORT void icalproperty_free(icalproperty *prop);

LIBICAL_ICAL_EXPORT icalproperty_kind icalproperty_isa(icalproperty *property);

LIBICAL_ICAL_EXPORT int icalproperty_isa_property(void *property);

LIBICAL_ICAL_EXPORT void icalproperty_add_parameters(struct icalproperty_impl *prop, va_list args);

LIBICAL_ICAL_EXPORT void icalproperty_add_parameter(icalproperty *prop, icalparameter *parameter);

LIBICAL_ICAL_EXPORT void icalproperty_set_parameter(icalproperty *prop, icalparameter *parameter);

LIBICAL_ICAL_EXPORT void icalproperty_set_parameter_from_string(icalproperty *prop,
                                                                const char *name,
                                                                const char *value);
LIBICAL_ICAL_EXPORT const char *icalproperty_get_parameter_as_string(icalproperty *prop,
                                                                     const char *name);

LIBICAL_ICAL_EXPORT char *icalproperty_get_parameter_as_string_r(icalproperty *prop,
                                                                 const char *name);

LIBICAL_ICAL_EXPORT void icalproperty_remove_parameter_by_kind(icalproperty *prop,
                                                               icalparameter_kind kind);

LIBICAL_ICAL_EXPORT void icalproperty_remove_parameter_by_name(icalproperty *prop,
                                                               const char *name);

LIBICAL_ICAL_EXPORT void icalproperty_remove_parameter_by_ref(icalproperty *prop,
                                                              icalparameter *param);

LIBICAL_ICAL_EXPORT int icalproperty_count_parameters(const icalproperty *prop);

/* Iterate through the parameters */
LIBICAL_ICAL_EXPORT icalparameter *icalproperty_get_first_parameter(icalproperty *prop,
                                                                    icalparameter_kind kind);
LIBICAL_ICAL_EXPORT icalparameter *icalproperty_get_next_parameter(icalproperty *prop,
                                                                   icalparameter_kind kind);
/* Access the value of the property */
LIBICAL_ICAL_EXPORT void icalproperty_set_value(icalproperty *prop, icalvalue *value);
LIBICAL_ICAL_EXPORT void icalproperty_set_value_from_string(icalproperty *prop, const char *value,
                                                            const char *kind);

LIBICAL_ICAL_EXPORT icalvalue *icalproperty_get_value(const icalproperty *prop);
LIBICAL_ICAL_EXPORT const char *icalproperty_get_value_as_string(const icalproperty *prop);
LIBICAL_ICAL_EXPORT char *icalproperty_get_value_as_string_r(const icalproperty *prop);

/**
 * Sets the parent @p icalproperty for the specified @p icalvalue.
 */
LIBICAL_ICAL_EXPORT void icalvalue_set_parent(icalvalue *value, icalproperty *property);

/**
 * Returns the parent @p icalproperty for the specified @p icalvalue.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT icalproperty *icalvalue_get_parent(icalvalue *value);

/* Deal with X properties */

LIBICAL_ICAL_EXPORT void icalproperty_set_x_name(icalproperty *prop, const char *name);
LIBICAL_ICAL_EXPORT const char *icalproperty_get_x_name(icalproperty *prop);

/** Return the name of the property -- the type name converted to a
 *  string, or the value of _get_x_name if the type is and X
 *  property
 */
LIBICAL_ICAL_EXPORT const char *icalproperty_get_property_name(const icalproperty *prop);
LIBICAL_ICAL_EXPORT char *icalproperty_get_property_name_r(const icalproperty *prop);

LIBICAL_ICAL_EXPORT icalvalue_kind icalparameter_value_to_value_kind(icalparameter_value value);

/**
 * Sets the parent @p icalproperty for the specified @p icalparameter.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_parent(icalparameter *param, icalproperty *property);

/**
 * Returns the parent @p icalproperty for the specified @p icalparameter.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT icalproperty *icalparameter_get_parent(icalparameter *param);

/* Convert kinds to string and get default value type */
LIBICAL_ICAL_EXPORT icalvalue_kind icalproperty_kind_to_value_kind(icalproperty_kind kind);
LIBICAL_ICAL_EXPORT icalproperty_kind icalproperty_value_kind_to_kind(icalvalue_kind kind);
LIBICAL_ICAL_EXPORT const char *icalproperty_kind_to_string(icalproperty_kind kind);
LIBICAL_ICAL_EXPORT icalproperty_kind icalproperty_string_to_kind(const char *string);

/** Check validity of a specific icalproperty_kind **/
LIBICAL_ICAL_EXPORT int icalproperty_kind_is_valid(const icalproperty_kind kind);

LIBICAL_ICAL_EXPORT icalproperty_method icalproperty_string_to_method(const char *str);
LIBICAL_ICAL_EXPORT const char *icalproperty_method_to_string(icalproperty_method method);

LIBICAL_ICAL_EXPORT const char *icalproperty_enum_to_string(int e);
LIBICAL_ICAL_EXPORT char *icalproperty_enum_to_string_r(int e);
LIBICAL_ICAL_EXPORT int icalproperty_kind_and_string_to_enum(const int kind, const char *str);

LIBICAL_ICAL_EXPORT const char *icalproperty_status_to_string(icalproperty_status);
LIBICAL_ICAL_EXPORT icalproperty_status icalproperty_string_to_status(const char *string);

LIBICAL_ICAL_EXPORT int icalproperty_enum_belongs_to_property(icalproperty_kind kind, int e);

/**
 * Normalizes (reorders and sorts the parameters) the specified @p icalproperty.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalproperty_normalize(icalproperty *prop);

#endif /*ICALPROPERTY_H */

/*======================================================================
 FILE: pvl.h
 CREATOR: eric November, 1995

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICAL_PVL_H
#define ICAL_PVL_H

#include "libical_ical_export.h"

typedef struct pvl_list_t *pvl_list;
typedef struct pvl_elem_t *pvl_elem;

/**
 * This type is private. Always use pvl_elem instead. The struct would
 * not even appear in this header except to make code in the USE_MACROS
 * blocks work
 */

typedef struct pvl_elem_t
{
    int MAGIC;                          /**< Magic Identifier */
    void *d;                            /**< Pointer to data user is storing */
    struct pvl_elem_t *next;            /**< Next element */
    struct pvl_elem_t *prior;           /**< Prior element */
} pvl_elem_t;

/* Create new lists or elements */
LIBICAL_ICAL_EXPORT pvl_elem pvl_new_element(void *d, pvl_elem next, pvl_elem prior);

LIBICAL_ICAL_EXPORT pvl_list pvl_newlist(void);

LIBICAL_ICAL_EXPORT void pvl_free(pvl_list);

/* Add, remove, or get the head of the list */
LIBICAL_ICAL_EXPORT void pvl_unshift(pvl_list l, void *d);

LIBICAL_ICAL_EXPORT void *pvl_shift(pvl_list l);

LIBICAL_ICAL_EXPORT pvl_elem pvl_head(pvl_list);

/* Add, remove or get the tail of the list */
LIBICAL_ICAL_EXPORT void pvl_push(pvl_list l, void *d);

LIBICAL_ICAL_EXPORT void *pvl_pop(pvl_list l);

LIBICAL_ICAL_EXPORT pvl_elem pvl_tail(pvl_list);

/* Insert elements in random places */
typedef int (*pvl_comparef) (void *a, void *b); /* a, b are of the data type */

LIBICAL_ICAL_EXPORT void pvl_insert_ordered(pvl_list l, pvl_comparef f, void *d);

LIBICAL_ICAL_EXPORT void pvl_insert_after(pvl_list l, pvl_elem e, void *d);

LIBICAL_ICAL_EXPORT void pvl_insert_before(pvl_list l, pvl_elem e, void *d);

/* Remove an element, or clear the entire list */
LIBICAL_ICAL_EXPORT void *pvl_remove(pvl_list, pvl_elem);       /* Remove element, return data */

LIBICAL_ICAL_EXPORT void pvl_clear(pvl_list);   /* Remove all elements, de-allocate all data */

LIBICAL_ICAL_EXPORT int pvl_count(pvl_list);

/* Navagate the list */
LIBICAL_ICAL_EXPORT pvl_elem pvl_next(pvl_elem e);

LIBICAL_ICAL_EXPORT pvl_elem pvl_prior(pvl_elem e);

/* get the data in the list */
#if !defined(PVL_USE_MACROS)
LIBICAL_ICAL_EXPORT void *pvl_data(pvl_elem);
#else
#define pvl_data(x) x==0 ? 0 : ((struct pvl_elem_t *)x)->d;
#endif

/* Find an element for which a function returns true */
typedef int (*pvl_findf) (void *a, void *b);    /*a is list elem, b is other data */

LIBICAL_ICAL_EXPORT pvl_elem pvl_find(pvl_list l, pvl_findf f, void *v);

LIBICAL_ICAL_EXPORT pvl_elem pvl_find_next(pvl_list l, pvl_findf f, void *v);

/**
 * Pass each element in the list to a function
 * a is list elem, b is other data
 */
typedef void (*pvl_applyf) (void *a, void *b);

LIBICAL_ICAL_EXPORT void pvl_apply(pvl_list l, pvl_applyf f, void *v);

#endif /* ICAL_PVL_H */

/*======================================================================
 FILE: icalcomponent.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALCOMPONENT_H
#define ICALCOMPONENT_H

#include "libical_ical_export.h"


typedef struct icalcomponent_impl icalcomponent;

/* This is exposed so that callers will not have to allocate and
   deallocate iterators. Pretend that you can't see it. */
typedef struct icalcompiter
{
    icalcomponent_kind kind;
    pvl_elem iter;

} icalcompiter;

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new(icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_clone(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_from_string(const char *str);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_vanew(icalcomponent_kind kind, ...);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_x(const char *x_name);

LIBICAL_ICAL_EXPORT void icalcomponent_free(icalcomponent *component);

LIBICAL_ICAL_EXPORT char *icalcomponent_as_ical_string(icalcomponent *component);

LIBICAL_ICAL_EXPORT char *icalcomponent_as_ical_string_r(icalcomponent *component);

LIBICAL_ICAL_EXPORT int icalcomponent_is_valid(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalcomponent_kind icalcomponent_isa(const icalcomponent *component);

LIBICAL_ICAL_EXPORT int icalcomponent_isa_component(void *component);

/*
 * Working with properties
 */

LIBICAL_ICAL_EXPORT void icalcomponent_add_property(icalcomponent *component,
                                                    icalproperty *property);

LIBICAL_ICAL_EXPORT void icalcomponent_remove_property(icalcomponent *component,
                                                       icalproperty *property);

LIBICAL_ICAL_EXPORT int icalcomponent_count_properties(icalcomponent *component,
                                                       icalproperty_kind kind);

/**
 * Sets the parent icalcomponent for the specified icalproperty @p property.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalproperty_set_parent(icalproperty *property,
                                                 icalcomponent *component);

/**
 * Returns the parent @p icalcomponent for the specified @p icalproperty.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalproperty_get_parent(const icalproperty *property);

/* Iterate through the properties */
LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_current_property(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_first_property(icalcomponent *component,
                                                                   icalproperty_kind kind);
LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_next_property(icalcomponent *component,
                                                                  icalproperty_kind kind);

/*
 * Working with components
 */

/* Return the first VEVENT, VTODO or VJOURNAL sub-component of cop, or
   comp if it is one of those types */

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_inner(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_add_component(icalcomponent *parent, icalcomponent *child);

LIBICAL_ICAL_EXPORT void icalcomponent_remove_component(icalcomponent *parent,
                                                        icalcomponent *child);

LIBICAL_ICAL_EXPORT int icalcomponent_count_components(icalcomponent *component,
                                                       icalcomponent_kind kind);

/**
   This takes 2 VCALENDAR components and merges the second one into the first,
   resolving any problems with conflicting TZIDs. comp_to_merge will no
   longer exist after calling this function. */
LIBICAL_ICAL_EXPORT void icalcomponent_merge_component(icalcomponent *comp,
                                                       icalcomponent *comp_to_merge);

/* Iteration Routines. There are two forms of iterators, internal and
external. The internal ones came first, and are almost completely
sufficient, but they fail badly when you want to construct a loop that
removes components from the container.*/

/* Iterate through components */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_current_component(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_first_component(icalcomponent *component,
                                                                     icalcomponent_kind kind);
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_next_component(icalcomponent *component,
                                                                    icalcomponent_kind kind);

/* Using external iterators */
LIBICAL_ICAL_EXPORT icalcompiter icalcomponent_begin_component(icalcomponent *component,
                                                               icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcompiter icalcomponent_end_component(icalcomponent *component,
                                                             icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_next(icalcompiter * i);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_prior(icalcompiter * i);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_deref(icalcompiter * i);

/* Working with embedded error properties */

/* Check the component against itip rules and insert error properties*/
/* Working with embedded error properties */
LIBICAL_ICAL_EXPORT int icalcomponent_check_restrictions(icalcomponent *comp);

/** Count embedded errors. */
LIBICAL_ICAL_EXPORT int icalcomponent_count_errors(icalcomponent *component);

/** Remove all X-LIC-ERROR properties*/
LIBICAL_ICAL_EXPORT void icalcomponent_strip_errors(icalcomponent *component);

/** Convert some X-LIC-ERROR properties into RETURN-STATUS properties*/
LIBICAL_ICAL_EXPORT void icalcomponent_convert_errors(icalcomponent *component);

/* Internal operations. They are private, and you should not be using them. */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_parent(icalcomponent *component);

LIBICAL_ICAL_EXPORT void icalcomponent_set_parent(icalcomponent *component,
                                                  icalcomponent *parent);

/* Kind conversion routines */

LIBICAL_ICAL_EXPORT int icalcomponent_kind_is_valid(const icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcomponent_kind icalcomponent_string_to_kind(const char *string);

LIBICAL_ICAL_EXPORT const char *icalcomponent_kind_to_string(icalcomponent_kind kind);

/************* Derived class methods.  ****************************

If the code was in an OO language, the remaining routines would be
members of classes derived from icalcomponent. Don't call them on the
wrong component subtypes. */

/** For VCOMPONENT: Return a reference to the first VEVENT, VTODO or
   VJOURNAL */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_first_real_component(icalcomponent *c);

/** For VEVENT, VTODO, VJOURNAL and VTIMEZONE: report the start and end
   times of an event in UTC */
LIBICAL_ICAL_EXPORT struct icaltime_span icalcomponent_get_span(icalcomponent *comp);

/******************** Convenience routines **********************/

LIBICAL_ICAL_EXPORT void icalcomponent_set_dtstart(icalcomponent *comp, struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtstart(icalcomponent *comp);

/* For the icalcomponent routines only, dtend and duration are tied
   together. If you call the get routine for one and the other exists,
   the routine will calculate the return value. That is, if there is a
   DTEND and you call get_duration, the routine will return the difference
   between DTEND and DTSTART. However, if you call a set routine for
   one and the other exists, no action will be taken and icalerrno will
   be set to ICAL_MALFORMEDDATA_ERROR. If you call a set routine and
   neither exists, the routine will create the appropriate property. */

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtend(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_dtend(icalcomponent *comp, struct icaltimetype v);

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_due(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_due(icalcomponent *comp, struct icaltimetype v);

LIBICAL_ICAL_EXPORT void icalcomponent_set_duration(icalcomponent *comp,
                                                    struct icaldurationtype v);

LIBICAL_ICAL_EXPORT struct icaldurationtype icalcomponent_get_duration(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_method(icalcomponent *comp, icalproperty_method method);

LIBICAL_ICAL_EXPORT icalproperty_method icalcomponent_get_method(icalcomponent *comp);

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtstamp(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_dtstamp(icalcomponent *comp, struct icaltimetype v);

LIBICAL_ICAL_EXPORT void icalcomponent_set_summary(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_summary(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_comment(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_comment(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_uid(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_uid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_relcalid(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_relcalid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_recurrenceid(icalcomponent *comp,
                                                        struct icaltimetype v);

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_recurrenceid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_description(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_description(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_location(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_location(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_sequence(icalcomponent *comp, int v);

LIBICAL_ICAL_EXPORT int icalcomponent_get_sequence(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_status(icalcomponent *comp, enum icalproperty_status v);

LIBICAL_ICAL_EXPORT enum icalproperty_status icalcomponent_get_status(icalcomponent *comp);

/** Calls the given function for each TZID parameter found in the
    component, and any subcomponents. */
LIBICAL_ICAL_EXPORT void icalcomponent_foreach_tzid(icalcomponent *comp,
                                                    void (*callback) (icalparameter *param,
                                                                      void *data),
                                                    void *callback_data);

/** Returns the icaltimezone in the component corresponding to the
    TZID, or NULL if it can't be found. */
LIBICAL_ICAL_EXPORT icaltimezone *icalcomponent_get_timezone(icalcomponent *comp,
                                                             const char *tzid);

LIBICAL_ICAL_EXPORT int icalproperty_recurrence_is_excluded(icalcomponent *comp,
                                                            struct icaltimetype *dtstart,
                                                            struct icaltimetype *recurtime);

LIBICAL_ICAL_EXPORT void icalcomponent_foreach_recurrence(icalcomponent *comp,
                                                          struct icaltimetype start,
                                                          struct icaltimetype end,
                                                          void (*callback) (icalcomponent *comp,
                                                                            struct icaltime_span *
                                                                            span, void *data),
                                                          void *callback_data);

/**
 * Normalizes (reorders and sorts the properties) the specified icalcomponent @p comp.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalcomponent_normalize(icalcomponent *comp);

/*************** Type Specific routines ***************/

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vcalendar(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vevent(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vtodo(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vjournal(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_valarm(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vfreebusy(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vtimezone(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xstandard(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xdaylight(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vagenda(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vquery(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vavailability(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xavailable(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vpoll(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vvoter(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xvote(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vpatch(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xpatch(void);

#endif /* !ICALCOMPONENT_H */

/*======================================================================
 FILE: icaltimezone.h
 CREATOR: Damon Chaplin 15 March 2001

 (C) COPYRIGHT 2001, Damon Chaplin <damon@ximian.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/
/**
 * @file icaltimezone.h
 * @brief timezone handling routines
 */

#ifndef ICALTIMEZONE_H
#define ICALTIMEZONE_H

#include "libical_ical_export.h"


#include <stdio.h>

#if !defined(ICALTIMEZONE_DEFINED)
#define ICALTIMEZONE_DEFINED
/** @brief An opaque struct representing a timezone.
 * We declare this here to avoid a circular dependancy.
 */
typedef struct _icaltimezone icaltimezone;
#endif

/**
 * @par Creating/Destroying individual icaltimezones.
 */

/** Creates a new icaltimezone. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_new(void);

LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_copy(icaltimezone *originalzone);

/** Frees all memory used for the icaltimezone. Set free_struct to free the
   icaltimezone struct as well. */
LIBICAL_ICAL_EXPORT void icaltimezone_free(icaltimezone *zone, int free_struct);

/** Sets the prefix to be used for tzid's generated from system tzdata.
    Must be globally unique (such as a domain name owned by the developer
    of the calling application), and begin and end with forward slashes.
    Do not change or de-allocate the string buffer after calling this.
 */
LIBICAL_ICAL_EXPORT void icaltimezone_set_tzid_prefix(const char *new_prefix);

/**
 * @par Accessing timezones.
 */

/** Free any builtin timezone information **/
LIBICAL_ICAL_EXPORT void icaltimezone_free_builtin_timezones(void);

/** Returns the array of builtin icaltimezones. */
LIBICAL_ICAL_EXPORT icalarray *icaltimezone_get_builtin_timezones(void);

/** Returns a single builtin timezone, given its Olson city name. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone(const char *location);

/** Returns a single builtin timezone, given its offset. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone_from_offset(int offset,
                                                                                const char *tzname);

/** Returns a single builtin timezone, given its TZID. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone_from_tzid(const char *tzid);

/** Returns the UTC timezone. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_utc_timezone(void);

/** Returns the TZID of a timezone. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_tzid(icaltimezone *zone);

/** Returns the city name of a timezone. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_location(icaltimezone *zone);

/** Returns the TZNAME properties used in the latest STANDARD and DAYLIGHT
   components. If they are the same it will return just one, e.g. "LMT".
   If they are different it will format them like "EST/EDT". Note that this
   may also return NULL. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_tznames(icaltimezone *zone);

/** Returns the latitude of a builtin timezone. */
LIBICAL_ICAL_EXPORT double icaltimezone_get_latitude(icaltimezone *zone);

/** Returns the longitude of a builtin timezone. */
LIBICAL_ICAL_EXPORT double icaltimezone_get_longitude(icaltimezone *zone);

/** Returns the VTIMEZONE component of a timezone. */
LIBICAL_ICAL_EXPORT icalcomponent *icaltimezone_get_component(icaltimezone *zone);

/** Sets the VTIMEZONE component of an icaltimezone, initializing the tzid,
   location & tzname fields. It returns 1 on success or 0 on failure, i.e.
   no TZID was found. */
LIBICAL_ICAL_EXPORT int icaltimezone_set_component(icaltimezone *zone, icalcomponent *comp);

LIBICAL_ICAL_EXPORT const char *icaltimezone_get_display_name(icaltimezone *zone);

/**
 * @par Converting times between timezones.
 */

LIBICAL_ICAL_EXPORT void icaltimezone_convert_time(struct icaltimetype *tt,
                                                   icaltimezone *from_zone,
                                                   icaltimezone *to_zone);

/**
 * @par Getting offsets from UTC.
 */

/** Calculates the UTC offset of a given local time in the given
   timezone.  It is the number of seconds to add to UTC to get local
   time.  The is_daylight flag is set to 1 if the time is in
   daylight-savings time. */
LIBICAL_ICAL_EXPORT int icaltimezone_get_utc_offset(icaltimezone *zone,
                                                    struct icaltimetype *tt, int *is_daylight);

/** Calculates the UTC offset of a given UTC time in the given
   timezone.  It is the number of seconds to add to UTC to get local
   time.  The is_daylight flag is set to 1 if the time is in
   daylight-savings time. */
LIBICAL_ICAL_EXPORT int icaltimezone_get_utc_offset_of_utc_time(icaltimezone *zone,
                                                                struct icaltimetype *tt,
                                                                int *is_daylight);

/*
 * Handling arrays of timezones. Mainly for internal use.
 */
LIBICAL_ICAL_EXPORT icalarray *icaltimezone_array_new(void);

LIBICAL_ICAL_EXPORT void icaltimezone_array_append_from_vtimezone(icalarray *timezones,
                                                                  icalcomponent *child);

LIBICAL_ICAL_EXPORT void icaltimezone_array_free(icalarray *timezones);

/*
 * By request (issue #112) make vtimezone functions public
 */
LIBICAL_ICAL_EXPORT void icaltimezone_expand_vtimezone(icalcomponent *comp,
                                                       int end_year, icalarray *changes);

LIBICAL_ICAL_EXPORT char *icaltimezone_get_location_from_vtimezone(icalcomponent *component);

LIBICAL_ICAL_EXPORT char *icaltimezone_get_tznames_from_vtimezone(icalcomponent *component);

/*
 * @par Handling the default location the timezone files
 */

/** Set the directory to look for the zonefiles */
LIBICAL_ICAL_EXPORT void set_zone_directory(const char *path);

/** Free memory dedicated to the zonefile directory */
LIBICAL_ICAL_EXPORT void free_zone_directory(void);

LIBICAL_ICAL_EXPORT void icaltimezone_release_zone_tab(void);

/*
 * @par Handling whether to use builtin timezone files
 */
LIBICAL_ICAL_EXPORT void icaltimezone_set_builtin_tzdata(int set);

LIBICAL_ICAL_EXPORT int icaltimezone_get_builtin_tzdata(void);

/*
 * @par Debugging Output.
 */

/** Dumps information about changes in the timezone up to and including
   max_year. */
LIBICAL_ICAL_EXPORT int icaltimezone_dump_changes(icaltimezone *zone, int max_year, FILE *fp);

/* For the library only -- do not make visible */
extern const char *icaltimezone_tzid_prefix(void);

#endif /* ICALTIMEZONE_H */

/*
 * Authors :
 *  Chenthill Palanisamy <pchenthill@novell.com>
 *
 * Copyright 2007, Novell, Inc.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of either:
 *
 *   The LGPL as published by the Free Software Foundation, version
 *   2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * Or:
 *
 *   The Mozilla Public License Version 2.0. You may obtain a copy of
 *   the License at http://www.mozilla.org/MPL/
 */

#ifndef ICALTZUTIL_H
#define ICALTZUTIL_H

#include "libical_ical_export.h"


#if defined(sun) && defined(__SVR4)
#define ZONES_TAB_SYSTEM_FILENAME "tab/zone_sun.tab"
#else
#define ZONES_TAB_SYSTEM_FILENAME "zone.tab"
#endif

LIBICAL_ICAL_EXPORT const char *icaltzutil_get_zone_directory(void);

LIBICAL_ICAL_EXPORT icalcomponent *icaltzutil_fetch_timezone(const char *location);

#endif

/*======================================================================
 FILE: icalparser.h
 CREATOR: eric 20 April 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

  The original code is icalparser.h
======================================================================*/

#ifndef ICALPARSER_H
#define ICALPARSER_H

#include "libical_ical_export.h"


/**
 * @file  icalparser.h
 * @brief Line-oriented parsing.
 *
 * This file provides methods to parse iCalendar-formatted data
 * into the structures provided by this library.
 *
 * ### Usage
 * Create a new parser via icalparser_new_parser(), then add lines one at
 * a time with icalparser_add_line(). icalparser_add_line() will return
 * non-zero when it has finished with a component.
 */

/**
 * @struct icalparser_impl
 * @typedef icalparser
 * @private
 *
 * Implementation of the icalparser struct, which holds the
 * state for the current parsing operation.
 */
typedef struct icalparser_impl icalparser;

/**
 * @enum icalparser_state
 * @typedef icalparser_state
 * @brief Represents the current state of the parser
 */
typedef enum icalparser_state
{
    /** An error occurred while parsing. */
    ICALPARSER_ERROR,

    /** Parsing was successful. */
    ICALPARSER_SUCCESS,

    /** Currently parsing the begin of a component */
    ICALPARSER_BEGIN_COMP,

    /** Currently parsing the end of the component */
    ICALPARSER_END_COMP,

    /** Parsing is currently in progress */
    ICALPARSER_IN_PROGRESS
} icalparser_state;

typedef char *(*icalparser_line_gen_func) (char *s, size_t size, void *d);

/**
 * @brief Creates a new ::icalparser.
 * @return An ::icalparser object
 *
 * @par Error handling
 * On error, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * All ::icalparser objects created with this function need to be
 * freed using the icalparser_free() function.
 *
 * ### Usage
 * ```c
 * // create new parser
 * icalparser *parser = icalparser_new();
 *
 * // do something with it...
 *
 * // free parser
 * icalparser_free(parser);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparser *icalparser_new(void);

/**
 * @brief Adds a single line to be parsed by the ::icalparser.
 * @param parser The parser to use
 * @param str A string representing a single line of RFC5545-formatted iCalendar data
 * @return When this was the last line of the component to be parsed,
 *  it returns the icalcomponent, otherwise it returns `NULL`.
 * @sa icalparser_parse()
 *
 * @par Error handling
 * -   If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to
 *     ::ICAL_BADARG_ERROR.
 * -   If @a line is empty, if returns `NULL`
 * -   If @a line is `NULL`, it returns `NULL` and sets the @a parser's ::icalparser_state to
 *     ::ICALPARSER_ERROR.
 * -   For errors during parsing, the functions can set the ::icalparser_state to
 *     ::ICALPARSER_ERROR and/or return components of the type ::ICAL_XLICINVALID_COMPONENT,
 *     or components with properties of the type ::ICAL_XLICERROR_PROPERTY.
 *
 * @par Ownership
 * Ownership of the @a str is transferred to libical upon calling this
 * method. The returned ::icalcomponent is owned by the caller and needs
 * to be `free()`d with the appropriate method after it's no longer needed.
 *
 * ### Example
 * ```c
 * char* read_stream(char *s, size_t size, void *d)
 * {
       return fgets(s, (int)size, (FILE*)d);
 * }
 *
 * void parse()
 * {
 *     char* line;
 *     FILE* stream;
 *     icalcomponent *component;
 *
 *     icalparser *parser = icalparser_new();
 *     stream = fopen(argv[1],"r");
 *
 *     icalparser_set_gen_data(parser, stream);
 *
 *     do{
 *         // get a single content line
 *         line = icalparser_get_line(parser, read_stream);
 *
 *         // add that line to the parser
 *         c = icalparser_add_line(parser,line);
 *
 *         // once we parsed a component, print it
 *         if (c != 0) {
 *             printf("%s", icalcomponent_as_ical_string(c));
 *             icalcomponent_free(c);
 *         }
 *     } while (line != 0);
 *
 *     icalparser_free(parser);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_add_line(icalparser *parser, char *str);

/**
 * @brief Cleans out an ::icalparser and returns whatever it has parsed so far.
 * @param parser The ::icalparser to clean
 * @return The parsed ::icalcomponent
 *
 * @par Error handling
 * If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. For parsing errors, it inserts an `X-LIC-ERROR`
 * property into the affected components.
 *
 * @par Ownership
 * The returned ::icalcomponent is property of the caller and needs to be
 * free'd with icalcomponent_free() after use.
 *
 * This will parse components even if it hasn't encountered a proper
 * `END` tag for it yet and return them, as well as clearing any intermediate
 * state resulting from being in the middle of parsing something so the
 * parser can be used to parse something new.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_clean(icalparser *parser);

/**
 * @brief Returns current state of the icalparser
 * @param parser The (valid, non-`NULL`) parser object
 * @return The current state of the icalparser, as an ::icalparser_state
 *
 * ### Example
 * ```c
 * icalparser *parser = icalparser_new();
 *
 * // use icalparser...
 *
 * if(icalparser_get_state(parser) == ICALPARSER_ERROR) {
 *     // handle error
 * } else {
 *     // ...
 * }
 * ```
 *
 * icalparser_free(parser);
 */
LIBICAL_ICAL_EXPORT icalparser_state icalparser_get_state(icalparser *parser);

/**
 * @brief Frees an ::icalparser object.
 * @param parser The ::icalparser to be freed.
 *
 * ### Example
 * ```c
 * icalparser *parser = icalparser_new();
 *
 * // use parser ...
 *
 * icalparser_free(parser);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparser_free(icalparser *parser);

/**
 * @brief Message oriented parsing.
 * @param parser The parser to use
 * @param line_gen_func A function that returns one content line per invocation
 * @return The parsed icalcomponent
 * @sa icalparser_parse_string()
 *
 * Reads an icalcomponent using the supplied @a line_gen_func, returning the parsed
 * component (or `NULL` on error).
 *
 * @par Error handling
 * -   If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * -   If data read by @a line_gen_func is empty, if returns `NULL`
 * -   If data read by @a line_gen_func is `NULL`, it returns `NULL`
 *     and sets the @a parser's ::icalparser_state to ::ICALPARSER_ERROR.
 * -   For errors during parsing, the functions can set the ::icalparser_state to
 *     ::ICALPARSER_ERROR and/or return components of the type ::ICAL_XLICINVALID_COMPONENT,
 *     or components with properties of the type ::ICAL_XLICERROR_PROPERTY.
 *
 * @par Ownership
 * The returned ::icalcomponent is owned by the caller of the function, and
 * needs to be `free()`d with the appropriate method when no longer needed.
 *
 * ### Example
 * ```c
 * char* read_stream(char *s, size_t size, void *d)
 * {
       return fgets(s, (int)size, (FILE*)d);
 * }
 *
 * void parse()
 * {
 *     char* line;
 *     FILE* stream;
 *     icalcomponent *component;
 *
 *     icalparser *parser = icalparser_new();
 *     stream = fopen(argv[1],"r");
 *
 *     icalparser_set_gen_data(parser, stream);
 *
 *     // use the parse method to parse the input data
 *     component = icalparser_parse(parser, read_stream);
 *
 *     // once we parsed a component, print it
 *     printf("%s", icalcomponent_as_ical_string(c));
 *     icalcomponent_free(c);
 *
 *     icalparser_free(parser);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_parse(icalparser *parser,
                                                    icalparser_line_gen_func line_gen_func);

/**
 * @brief Sets the data that icalparser_parse will give to the line_gen_func
 * as the parameter 'd'.
 * @param parser The icalparser this applies to
 * @param data The pointer which will be passed to the line_gen_func as argument `d`
 *
 * If you use any of the icalparser_parser() or icalparser_get_line() functions,
 * the @a line_gen_func that they expect has a third `void* d` argument. This function
 * sets what will be passed to your @a line_gen_function as such argument.
 */
LIBICAL_ICAL_EXPORT void icalparser_set_gen_data(icalparser *parser, void *data);

/**
 * @brief Parse a string and return the parsed ::icalcomponent.
 * @param str The iCal formatted data to be parsed
 * @return An ::icalcomponent representing the iCalendar
 *
 * @par Error handling
 * On error, returns `NULL` and sets ::icalerrno
 *
 * @par Ownership
 * The returned ::icalcomponent is owned by the caller of the function, and
 * needs to be free'd with the appropriate functions after use.
 *
 * ### Example
 * ```c
 * char *ical_string;
 *
 * // parse ical_string
 * icalcomponent *component = icalparser_parse_string(ical_string);
 *
 * if(!icalerrno || component == NULL) {
 *     // use component ...
 * }
 *
 * // release component
 * icalcomponent_free(component);
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_parse_string(const char *str);

/***********************************************************************
 * Parser support functions
 ***********************************************************************/

/**
 * @brief Given a line generator function, return a single iCal content line.
 * @return Aa pointer to a single line of data or `NULL` if it reached
 *  end of file reading from the @a line_gen_func. Note that the pointer
 *  returned is owned by libical and must not be `free()`d by the user.
 * @param parser The parser object to use
 * @param line_gen_func The function to use for reading data
 *
 * This function uses the supplied @a line_gen_func to read data in,
 * until it has read a full line, and returns the full line.
 * To supply arbitrary data (as the parameter @a d) to your @a line_gen_func,
 * call icalparser_set_gen_data().
 */
LIBICAL_ICAL_EXPORT char *icalparser_get_line(icalparser *parser,
                                              icalparser_line_gen_func line_gen_func);

LIBICAL_ICAL_EXPORT char *icalparser_string_line_generator(char *out, size_t buf_size, void *d);

#endif /* !ICALPARSE_H */

/*======================================================================
 FILE: icalmemory.h
 CREATOR: eric 30 June 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The Initial Developer of the Original Code is Eric Busboom
======================================================================*/

#ifndef ICALMEMORY_H
#define ICALMEMORY_H

/**
 * @file icalmemory.h
 * @brief Common memory management routines.
 *
 * libical often passes strings back to the caller. To make these
 * interfaces simple, I did not want the caller to have to pass in a
 * memory buffer, but having libical pass out newly allocated memory
 * makes it difficult to de-allocate the memory.
 *
 * The ring buffer in this scheme makes it possible for libical to pass out
 * references to memory which the caller does not own, and be able to
 * de-allocate the memory later. The ring allows libical to have several buffers
 * active simultaneously, which is handy when creating string representations of
 * components. Methods for working with these temporary buffers are marked with
 * `icalmemory_tmp_*()`.
 *
 * Other memory management routines include wrappers around the system
 * management routines like icalmemory_new_buffer() and icalmemory_free_buffer()
 * as well as routines to work with strings, like icalmemory_append_string().
 */

#include "libical_ical_export.h"

/**
 * @brief Creates a new temporary buffer on the ring and returns it.
 * @param size How big (in bytes) the buffer should be
 * @return A pointer to the newly created buffer on the ring
 *
 * Creates a temporary buffer on the ring. Regardless of what @a size you
 * specify, the buffer will always be at least ::MIN_BUFFER_SIZE big, and it
 * will be zeroed out.
 *
 * @par Error handling
 * If there is a problem allocating memory for the buffer, it sets ::icalerrno
 * to ::ICAL_NEWFAILED_ERROR and returns `NULL`.
 *
 * @par Ownership
 * The returned buffer is owned by icalmemory. It must not be freed by the
 * caller and the returned memory will be automatically reclaimed as more items
 * are added to the ring buffer.
 *
 * ### Usage
 * ```c
 * char *str = icalmemory_tmp_buffer(256);
 * strcpy(str, "some data");
 *
 * // use str
 * ```
 */
LIBICAL_ICAL_EXPORT void *icalmemory_tmp_buffer(size_t size);

/**
 * @brief Creates a copy of the given string, stored on the ring buffer, and
 *  returns it.
 * @param str The string to copy
 * @return A copy of @a str, which has been placed on the ring buffer for
 *  automatic reclamation.
 *
 * @par Error handling
 * The passed string @a str must not be `NULL`, otherwise a segfault might
 * ensue, since the routine calls `strlen()` on it.
 *
 * @par Ownership
 * The returned string is owned by icalmemory. It must not be freed by the
 * caller, and it will be automatically reclaimed as more items are added to the
 * buffer.
 *
 * ### Usage
 * ```c
 * const char *str = "Example string";
 * char *tmp_copy = icalmemory_tmp_copy(str);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalmemory_tmp_copy(const char *str);

/**
 * @brief Add an externally allocated buffer to the ring.
 * @param buf The externally allocated buffer to add to the ring
 *
 * Adds an externally allocated buffer to the ring. This ensures that libical
 * will `free()` the buffer automatically, either after ::BUFFER_RING_SIZE other
 * buffers have been created or added, or after ::icalmemory_free_ring() has
 * been called.
 *
 * @par Error handling
 * No error is raised if @a buf is `NULL`.
 *
 * @par Ownership
 * After adding @a buf to the ring, it becomes owned by icalmemory and must not
 * be `free()`d manually anymore, it leads to a double-`free()` when icalmemory
 * reclaims the memory.
 *
 * ### Usage
 * ```c
 * char *buf = calloc(256, sizeof(char));
 *
 * icalmemory_add_tmp_buffer(buf);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalmemory_add_tmp_buffer(void *buf);

/**
 * @brief Free all memory used in the ring
 *
 * Frees all memory used in the ring. Depending on if ::HAVE_PTHREAD is set or
 * not, the ring buffer is allocated on a per-thread basis, meaning that if all
 * rings are to be released, it must be called once in every thread.
 *
 * ### Usage
 * ``` c
 * void *buf = icalmemory_tmp_buffer(256);
 *
 * // use buf
 *
 * // release buf and all other memory in the ring buffer
 * icalmemory_free_ring();
 * ```
 */
LIBICAL_ICAL_EXPORT void icalmemory_free_ring(void);

/* Non-tmp buffers must be freed. These are mostly wrappers around
 * malloc, etc, but are used so the caller can change the memory
 * allocators in a future version of the library */

/**
 * @brief Creates new buffer with the specified size.
 * @param size The size of the buffer that is to be created.
 * @return A pointer to the newly-created buffer.
 * @sa icalmemory_free_buffer()
 *
 * @par Error handling
 * If there is a problem allocating memory, it sets ::icalerrno to
 * ::ICAL_NEWFAILED_ERROR and returns `NULL`.
 *
 * @par Ownership
 * Buffers created with this method are owned by the caller. The must be
 * released with the appropriate icalmemory_free_buffer() method.
 *
 * This creates a new (non-temporary) buffer of the specified @a size. All
 * buffers returned by this method are zeroed-out.
 *
 * ### Usage
 * ```c
 * // create buffer
 * char *buffer = icalmemory_new_buffer(50);
 *
 * // fill buffer
 * strcpy(buffer, "some data");
 *
 * // release buffer
 * icalmemory_free_buffer(buffer);
 * ```
 */
LIBICAL_ICAL_EXPORT void *icalmemory_new_buffer(size_t size);

/**
 * @brief Resizes a buffer created with icalmemory_new_buffer().
 * @param buf The buffer to be resized.
 * @param size The new size of the buffer.
 * @return The new, resized buffer.
 * @sa icalmemory_new_buffer()
 * @warning This method may not be used for temporary buffers (buffers allocated
 * with icalmemory_tmp_buffer() and related functions)!
 *
 * @par Error handling
 * If there is a problem while reallocating the buffer, the method sets
 * ::icalerrno to ::ICAL_NEWFAILED_ERROR and returns `NULL`.
 *
 * @par Ownership
 * The returned buffer is owned by the caller and needs to be released with the
 * appropriate icalmemory_free_buffer() method. The old buffer, @a buf, can not
 * be used anymore after calling this method.
 *
 * ### Usage
 * ```c
 * // create new buffer
 * char *buffer = icalmemory_new_buffer(10);
 *
 * // fill buffer
 * strcpy(buffer, "some data");
 *
 * // expand buffer
 * buffer = icalmemory_resize_buffer(buffer, 20);
 *
 * // fill with more data
 * strcpy(buffer, "a lot more data");
 *
 * // release
 * icalmemory_free_buffer(buffer);
 * ```
 */
LIBICAL_ICAL_EXPORT void *icalmemory_resize_buffer(void *buf, size_t size);

/**
 * @brief Releases a buffer
 * @param buf The buffer to release
 * @sa icalmemory_new_buffer()
 *
 * Releases the memory of the buffer.
 */
LIBICAL_ICAL_EXPORT void icalmemory_free_buffer(void *buf);

/* THESE ROUTINES CAN NOT BE USED ON TMP BUFFERS. Only use them on
   normally allocated memory, or on buffers created from
   icalmemory_new_buffer, never with buffers created by
   icalmemory_tmp_buffer. If icalmemory_append_string has to resize a
   buffer on the ring, the ring will loose track of it an you will
   have memory problems. */

/**
 * @brief Append a string to a buffer.
 * @param buf The buffer to append the string to.
 * @param pos The position to append the string at.
 * @param buf_size The size of the buffer (will be changed if buffer is
 * reallocated)
 * @param string The string to append to the buffer.
 * @warning This method may not be used for temporary buffers (buffers allocated
 *  with icalmemory_tmp_buffer() and related functions)!
 *
 * @par Error handling
 * Sets ::icalerrno to ::ICAL_BADARG_ERROR if @a buf, `*buf`, @a pos, `* pos`,
 * @a buf_size or @a string are `NULL`.
 *
 * This method will copy the string @a string to the buffer @a buf starting at
 * position @a pos, reallocing @a buf if it is too small. @a buf_size is the
 * size of @a buf and will be changed if @a buf is reallocated. @a pos will
 * point to the last byte of the new string in @a buf, usually a `'\0'`
 *
 * ### Example
 * ```c
 * // creates a new buffer
 * int buffer_len = 15;
 * char *buffer = icalmemory_new_buffer(buffer_len);
 * strcpy(buffer, "My name is: ");
 *
 * // append a string to the buffer
 * int buffer_end = strlen(buffer);
 * char *buffer_end_pos = buffer[buffer_str_end];
 * icalmemory_append_string(&buffer, &buffer_end_pos, &buffer_len, "John Doe");
 *
 * // print string
 * printf("%s\n", buffer);
 *
 * // release memory
 * icalmemory_free_buffer(buffer);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalmemory_append_string(char **buf, char **pos, size_t *buf_size,
                                                  const char *string);

/**
 * @brief Append a character to a buffer.
 * @param buf The buffer to append the character to.
 * @param pos The position to append the character at.
 * @param buf_size The size of the buffer (will be changed if buffer is
 *  reallocated)
 * @param ch The character to append to the buffer.
 * @warning This method may not be used for temporary buffers (buffers allocated
 *  with icalmemory_tmp_buffer() and related functions)!
 *
 * @par Error handling
 * Sets ::icalerrno to ::ICAL_BADARG_ERROR if @a buf, `*buf`, @a pos, `* pos`,
 * or @a buf_size `NULL`.
 *
 * This method will copy the character @a ch and a `'\0'` character after it to
 * the buffer @a buf starting at position @a pos, reallocing @a buf if it is too
 * small. @a buf_size is the size of @a buf and will be changed if @a buf is
 * reallocated. @a pos will point to the new terminating `'\0'` character @a
 * buf.
 *
 * ### Example
 * ```c
 * // creates a new buffer
 * int buffer_len = 15;
 * char *buffer = icalmemory_new_buffer(buffer_len);
 * strcpy(buffer, "My number is: ");
 *
 * // append a char to the buffer
 * int buffer_end = strlen(buffer);
 * char *buffer_end_pos = buffer[buffer_str_end];
 * icalmemory_append_char(&buffer, &buffer_end_pos, &buffer_len, '7');
 *
 * // print string
 * printf("%s\n", buffer);
 *
 * // release memory
 * icalmemory_free_buffer(buffer);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalmemory_append_char(char **buf, char **pos, size_t *buf_size, char ch);

/**
 * @brief Create a duplicate of a string.
 * @param s The string to duplicate.
 * @return A pointer to a string containing the same data as @a s
 *
 * @par Error handling
 * The string @a s must not be `NULL`, otherwise depending on the `libc` used,
 * it might lead to undefined behaviour (read: segfaults).
 *
 * @par Ownership
 * The returned string is owned by the caller and needs to be released with the
 * appropriate `free()` method.
 *
 * A wrapper around `strdup()`.  Partly to trap calls to `strdup()`, partly
 * because in `-ansi`, `gcc` on Red Hat claims that `strdup()` is undeclared.
 *
 * ### Usage
 * ```c
 * const char *my_str = "LibIcal";
 * char *dup = icalmemory_strdup(my_str);
 * printf("%s\n", dup);
 * free(dup);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalmemory_strdup(const char *s);

#endif /* !ICALMEMORY_H */

/*======================================================================
  FILE: icalerror.h
  CREATOR: eric 09 May 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The original code is icalerror.h
======================================================================*/

#ifndef ICALERROR_H
#define ICALERROR_H

#include "libical_ical_export.h"
#include <assert.h>
#include <stdio.h>

/**
 * @file icalerror.h
 * @brief Error handling for libical
 *
 * Most routines will set the global error value ::icalerrno on errors.
 * This variable is an enumeration; permissible values can be found in
 * icalerror.h. If the routine returns an enum ::icalerrorenum, then the
 * return value will be the same as ::icalerrno. You can use icalerror_strerror()
 * to get a string that describes the error, or icalerror_perror() to
 * get a string describing the current error set in ::icalerrno.
 */

#define ICAL_SETERROR_ISFUNC

/**
 * @brief Triggered before any error is called
 *
 * This routine is called before any error is triggered.
 * It is called by icalerror_set_errno(), so it does not
 * appear in all of the macros below.
 *
 * This routine can be used while debugging by setting
 * a breakpoint here.
 */
LIBICAL_ICAL_EXPORT void icalerror_stop_here(void);

/**
 * @brief Triggered to abort the process
 *
 * This routine is called to abort the process in the
 * case of an error.
 */
LIBICAL_ICAL_EXPORT void icalerror_crash_here(void);

#ifndef _MSC_VER
#pragma GCC visibility push(default)
#endif
/**
 * @typedef icalerrorenum
 * @enum icalerrorenum
 * @brief Represents the different types of errors that
 *  can be triggered in libical
 *
 * Each of these values represent a different type of error, which
 * is stored in ::icalerrno on exit of the library function (or
 * can be returned, but if it is, ::icalerrno is also set).
 */
typedef enum icalerrorenum
{
    /** No error happened */
    ICAL_NO_ERROR = 0,

    /** A bad argument was passed to a function */
    ICAL_BADARG_ERROR,

    /** An error occurred while creating a new object with a `*_new()` routine */
    ICAL_NEWFAILED_ERROR,

    /** An error occurred while allocating some memory */
    ICAL_ALLOCATION_ERROR,

    /** Malformed data was passed to a function */
    ICAL_MALFORMEDDATA_ERROR,

    /** An error occurred while parsing part of an iCal component */
    ICAL_PARSE_ERROR,

    /** An internal error happened in library code */
    ICAL_INTERNAL_ERROR, /* Like assert --internal consist. prob */

    /** An error happened while working with a file */
    ICAL_FILE_ERROR,

    /** Failure to properly sequence calls to a set of interfaces */
    ICAL_USAGE_ERROR,

    /** An unimplemented function was called */
    ICAL_UNIMPLEMENTED_ERROR,

    /** An unknown error occurred */
    ICAL_UNKNOWN_ERROR  /* Used for problems in input to icalerror_strerror() */
} icalerrorenum;
#ifndef _MSC_VER
#pragma GCC visibility pop
#endif

/**
 * @brief Return the current ::icalerrno value
 * @return A pointer to the current ::icalerrno value
 *
 * Yields a pointer to the current ::icalerrno value. This can
 * be used to access (read from and write to) it.
 *
 * ### Examples
 * ```c
 * assert(*icalerrno_return() == icalerrno);
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorenum *icalerrno_return(void);

/**
 * @brief Access the current ::icalerrno value
 * @return The current ::icalerrno value
 * @note Pseudo-variable that can be used to access the current
 *  ::icalerrno.
 *
 * ### Usage
 * ```c
 * if(icalerrno == ICAL_PARSE_ERROR) {
 *     // ...
 * }
 *
 * // resets error
 * icalerrno = ICAL_NO_ERROR;
 * ```
 */
#define icalerrno (*(icalerrno_return()))

/**
 * @brief Change if errors are fatal
 * @param fatal If true, libical aborts after a call to icalerror_set_error()
 * @warning NOT THREAD SAFE: it is recommended that you do not change
 *  this in a multithreaded program.
 *
 * ### Usage
 * ```c
 * icalerror_set_errors_are_fatal(true); // default
 * icalerror_set_errors_are_fatal(false);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_errors_are_fatal(int fatal);

/**
 * @brief Determine if errors are fatal
 * @return True if libical errors are fatal
 *
 * ### Usage
 * ```c
 * if(icalerror_get_errors_are_fatal()) {
 *     // since errors are fatal, this will abort the
 *     // program.
 *     icalerror_set_errno(ICAL_PARSE_ERROR);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT int icalerror_get_errors_are_fatal(void);

/* Warning messages */

/**
 * @def icalerror_warn(message)
 * @brief Prints a formatted warning message to stderr
 * @param message Warning message to print
 *
 * ### Usage
 * ```c
 * icalerror_warn("Non-standard tag encountered");
 * ```
 */

#ifdef __GNUC__ca
#define icalerror_warn(message) \
{fprintf(stderr, "%s(), %s:%d: %s\n", __FUNCTION__, __FILE__, __LINE__, message);}
#else /* __GNU_C__ */
#define icalerror_warn(message) \
{fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, message);}
#endif /* __GNU_C__ */

/**
 * @brief Reset icalerrno to ::ICAL_NO_ERROR
 *
 * ### Usage
 * ```c
 * if(icalerrno == ICAL_PARSE_ERROR) {
 *     // ignore parsing errors
 *     icalerror_clear_errno();
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_clear_errno(void);

/**
 * @enum icalerrorstate
 * @typedef icalerrorstate
 * @brief Determine if an error is fatal or non-fatal.
 */
typedef enum icalerrorstate
{
    /** Fatal */
    ICAL_ERROR_FATAL,

    /** Non-fatal */
    ICAL_ERROR_NONFATAL,

    /** Fatal if icalerror_errors_are_fatal(), non-fatal otherwise. */
    ICAL_ERROR_DEFAULT,

    /** Asked state for an unknown error type */
    ICAL_ERROR_UNKNOWN
} icalerrorstate;

/**
 * @brief Find description string for error
 * @param e The type of error that occurred
 * @return A string describing the error that occurred
 *
 * @par Error handling
 * If the type of error @a e wasn't found, it returns the description
 * for ::ICAL_UNKNOWN_ERROR.
 *
 * @par Ownership
 * The string that is returned is owned by the library and must not
 * be free'd() by the user.
 *
 * ### Usage
 * ```c
 * if(icalerrno != ICAL_NO_ERROR) {
 *     printf("%s\n", icalerror_strerror(icalerrno));
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalerror_strerror(icalerrorenum e);

/**
 * @brief Return the description string for the current error in ::icalerrno
 *
 * @par Error handling
 * If the type of error @a e wasn't found, it returns the description
 * for ::ICAL_UNKNOWN_ERROR.
 *
 * @par Ownership
 * The string that is returned is owned by the library and must not
 * be free'd() by the user.
 *
 * ### Usage
 * ```c
 * if(icalerrno != ICAL_NO_ERROR) {
 *     printf("%s\n", icalerror_perror());
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalerror_perror(void);

/**
 * @brief Prints backtrace
 * @note Only works on systems that support it (HAVE_BACKTRACE enabled).
 *
 * ### Usage
 * ```
 * if(icalerrno != ICAL_NO_ERROR) {
 *     ical_bt();
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void ical_bt(void);

/**
 * @brief Set the ::icalerrorstate for a given ::icalerrorenum @a error
 * @param error The error to change
 * @param state The new error state of the error
 *
 * Sets the severity of a given error. For example, it can be used to
 * set the severity of an ::ICAL_PARSE_ERROR to be an ::ICAL_ERROR_NONFATAL.
 *
 * ### Usage
 * ```c
 * icalerror_set_error_state(ICAL_PARSE_ERROR, ICAL_ERROR_NONFATAL);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_error_state(icalerrorenum error, icalerrorstate state);

/**
 * @brief Get the error state (severity) for a given error
 * @param error The error to examine
 * @return Returns the severity of the error
 */
LIBICAL_ICAL_EXPORT icalerrorstate icalerror_get_error_state(icalerrorenum error);

/**
 * @brief Read an error from a string
 * @param str The error name string
 * @return An ::icalerrorenum representing the error
 *
 * @par Error handling
 * If the error specified in @a str can't be found, instead
 * ::ICAL_UNKNOWN_ERROR is returned.
 *
 * ### Usage
 * ```c
 * assert(icalerror_error_from_string("PARSE") == ICAL_PARSE_ERROR);
 * assert(icalerror_error_from_string("NONSENSE") == ICAL_UNKNOWN_ERROR);
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorenum icalerror_error_from_string(const char *str);

/**
 * @def icalerror_set_errno(x)
 * @brief Sets the ::icalerrno to a given error
 * @param x The error to set ::icalerrno to
 *
 * Sets ::icalerrno to the error given in @a x. Additionally, if
 * the error is an ::ICAL_ERROR_FATAL or if it's an ::ICAL_ERROR_DEFAULT
 * and ::ICAL_ERRORS_ARE_FATAL is true, it prints a warning to @a stderr
 * and aborts the process.
 *
 * ### Usage
 * ```c
 * icalerror_set_errno(ICAL_PARSE_ERROR);
 * ```
 */
#if !defined(ICAL_SETERROR_ISFUNC)
#define icalerror_set_errno(x) \
icalerrno = x; \
if(icalerror_get_error_state(x) == ICAL_ERROR_FATAL || \
   (icalerror_get_error_state(x) == ICAL_ERROR_DEFAULT && \
    icalerror_get_errors_are_fatal() == 1)){              \
   icalerror_warn(icalerror_strerror(x)); \
   ical_bt(); \
   assert(0); \
} }
#else
/**
 * @brief Sets the ::icalerrno to a given error
 * @param x The error to set ::icalerrno to
 *
 * Sets ::icalerrno to the error given in @a x. Additionally, if
 * the error is an ::ICAL_ERROR_FATAL or if it's an ::ICAL_ERROR_DEFAULT
 * and ::ICAL_ERRORS_ARE_FATAL is true, it prints a warning to @a stderr
 * and aborts the process.
 *
 * ### Usage
 * ```c
 * icalerror_set_errno(ICAL_PARSE_ERROR);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_errno(icalerrorenum x);
#endif

/**
 * @def ICAL_ERRORS_ARE_FATAL
 * @brief Determines if all libical errors are fatal and lead to
 *  the process aborting.
 *
 * If set to 1, all libical errors are fatal and lead to the
 * process aborting upon encountering on. Otherwise, errors
 * are nonfatal.
 *
 * Can be checked with libical_get_errors_are_fatal().
 */

#if !defined(ICAL_ERRORS_ARE_FATAL)
#define ICAL_ERRORS_ARE_FATAL 0
#endif

#if ICAL_ERRORS_ARE_FATAL == 1
#undef NDEBUG
#endif

#define icalerror_check_value_type(value,type);
#define icalerror_check_property_type(value,type);
#define icalerror_check_parameter_type(value,type);
#define icalerror_check_component_type(value,type);

/* Assert with a message */
/**
 * @def icalerror_assert(test, message)
 * @brief Assert with a message
 * @param test The assertion to test
 * @param message The message to print on failure of assertion
 *
 * Tests the given assertion @a test, and if it fails, prints the
 * @a message given on @a stderr as a warning and aborts the process.
 * This only works if ::ICAL_ERRORS_ARE_FATAL is true, otherwise
 * does nothing.
 */
#if ICAL_ERRORS_ARE_FATAL == 1

#ifdef __GNUC__
#define icalerror_assert(test,message) \
if (!(test)) { \
    fprintf(stderr, "%s(), %s:%d: %s\n", __FUNCTION__, __FILE__, __LINE__, message); \
    icalerror_stop_here(); \
    abort();}
#else /*__GNUC__*/
#define icalerror_assert(test,message) \
if (!(test)) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, message); \
    icalerror_stop_here(); \
    abort();}
#endif /*__GNUC__*/

#else /* ICAL_ERRORS_ARE_FATAL */
#define icalerror_assert(test,message)
#endif /* ICAL_ERRORS_ARE_FATAL */

/**
 * @brief Checks the assertion @a test and raises error on failure
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * ### Example
 * ```c
 * void test_function(icalcomponent *component) {
 *    icalerror_check_arg(component != 0, "component");
 *
 *    // use component
 * }
 * ```
 */
#define icalerror_check_arg(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns void
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return `void`.
 *
 * ### Example
 * ```c
 * void test_function(icalcomponent *component) {
 *    icalerror_check_arg_rv(component != 0, "component");
 *
 *    // use component
 * }
 * ```
 */
#define icalerror_check_arg_rv(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns 0
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return `0`.
 *
 * ### Example
 * ```c
 * int test_function(icalcomponent *component) {
 *    icalerror_check_arg_rz(component != 0, "component");
 *
 *    // use component
 *    return icalcomponent_count_kinds(component, ICAL_ANY_COMPONENT);
 * }
 * ```
 */
#define icalerror_check_arg_rz(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return 0; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns @a error
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 * @param error What to return on error
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it aborts the process with `assert(0)` and causes the enclosing
 * function to return @a error.
 *
 * ### Example
 * ```c
 * icalcomponent *test_function(icalcomponent *component) {
 *    icalerror_check_arg_re(component != 0, "component", NULL);
 *
 *    // use component
 *    return icalcomponent_get_first_real_component(component);
 * }
 * ```
 */
#define icalerror_check_arg_re(test,arg,error) \
if (!(test)) { \
    icalerror_stop_here(); \
    assert(0); \
    return error; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns @a x
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 * @param x    What to return on error
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return @a x.
 *
 * ### Example
 * ```c
 * icalcomponent *test_function(icalcomponent *component) {
 *    icalerror_check_arg_rx(component != 0, "component", NULL);
 *
 *    // use component
 *    return icalcomponent_get_first_real_component(component);
 * }
 * ```
 */
#define icalerror_check_arg_rx(test,arg,x) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return x; \
}

/* String interfaces to set an error to NONFATAL and restore it to its original value */

/**
 * @brief Suppresses a given error
 * @param error The name of the error to suppress
 * @return The previous icalerrorstate (severity)
 *
 * Calling this function causes the given error to be listed as
 * ::ICAL_ERROR_NONFATAL, and thus suppressed. Error states can be
 * restored with icalerror_restore().
 *
 * ### Usage
 * ```c
 * // suppresses internal errors
 * icalerror_supress("INTERNAL");
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorstate icalerror_supress(const char *error);

/**
 * Assign the given error the given icalerrorstate (severity)
 * @param error The error in question
 * @param es The icalerrorstate (severity) to set it to
 *
 * Calling the function changes the ::icalerrorstate of the given error.
 *
 * ### Usage
 * ```c
 * // suppress internal errors
 * icalerror_supress("INTERNAL");
 *
 * // ...
 *
 * // restore internal errors
 * icalerror_restore("INTERNAL", ICAL_ERROR_DEFAULT);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_restore(const char *error, icalerrorstate es);

#endif /* !ICALERROR_H */

/*======================================================================
  FILE: icalrestriction.h
  CREATOR: eric 24 April 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The original code is icalrestriction.h

 Contributions from:
    Graham Davison (g.m.davison@computer.org)
======================================================================*/

#ifndef ICALRESTRICTION_H
#define ICALRESTRICTION_H

/**
 * @file icalrestriction.h
 * @brief Functions to check if an ::icalcomponent meets the restrictions
 *  imposed by the standard.
 */

#include "libical_ical_export.h"


/**
 * @brief The kinds of icalrestrictions there are
 *
 * These must stay in this order for icalrestriction_compare to work
 */
typedef enum icalrestriction_kind
{
    /** No restriction */
    ICAL_RESTRICTION_NONE = 0, /* 0 */

    /** Zero */
    ICAL_RESTRICTION_ZERO, /* 1 */

    /** One */
    ICAL_RESTRICTION_ONE, /* 2 */

    /** Zero or more */
    ICAL_RESTRICTION_ZEROPLUS, /* 3 */

    /** One or more */
    ICAL_RESTRICTION_ONEPLUS, /* 4 */

    /** Zero or one */
    ICAL_RESTRICTION_ZEROORONE, /* 5 */

    /** Zero or one, exclusive with another property */
    ICAL_RESTRICTION_ONEEXCLUSIVE, /* 6 */

    /** Zero or one, mutual with another property */
    ICAL_RESTRICTION_ONEMUTUAL, /* 7 */

    /** Unknown */
    ICAL_RESTRICTION_UNKNOWN    /* 8 */
} icalrestriction_kind;

/**
 * @brief Checks if the given @a count is in accordance with the given
 *  restriction, @a restr.
 * @param restr The restriction to apply to the @a count
 * @param count The amount present that is to be checked against the restriction
 * @return 1 if the restriction is met, 0 if not
 *
 * ### Example
 * ```c
 * assert(icalrestriction_compare(ICALRESTRICTION_ONEPLUS, 5) == true);
 * assert(icalrestriction_compare(ICALRESTRICTION_NONE,    3) == false);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalrestriction_compare(icalrestriction_kind restr, int count);

/**
 * @brief Checks if a given `VCALENDAR` meets all the restrictions imposed by
 *  the standard.
 * @param comp The `VCALENDAR` component to check
 * @return 1 if the restrictions are met, 0 if not
 *
 * @par Error handling
 * Returns 0 and sets ::icalerrno if `NULL` is passed as @a comp, or if the
 * component is not a `VCALENDAR`.
 *
 * ### Example
 * ```c
 * icalcomponent *component = // ...
 *
 * // check component
 * assert(icalrestriction_check(component) == true);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalrestriction_check(icalcomponent *comp);

#endif /* !ICALRESTRICTION_H */

/*======================================================================
 FILE: sspm.h Mime Parser
 CREATOR: eric 25 June 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

  The Initial Developer of the Original Code is Eric Busboom
======================================================================*/

#ifndef ICAL_SSPM_H
#define ICAL_SSPM_H

#include "libical_ical_export.h"

enum sspm_major_type
{
    SSPM_NO_MAJOR_TYPE,
    SSPM_TEXT_MAJOR_TYPE,
    SSPM_IMAGE_MAJOR_TYPE,
    SSPM_AUDIO_MAJOR_TYPE,
    SSPM_VIDEO_MAJOR_TYPE,
    SSPM_APPLICATION_MAJOR_TYPE,
    SSPM_MULTIPART_MAJOR_TYPE,
    SSPM_MESSAGE_MAJOR_TYPE,
    SSPM_UNKNOWN_MAJOR_TYPE
};

enum sspm_minor_type
{
    SSPM_NO_MINOR_TYPE,
    SSPM_ANY_MINOR_TYPE,
    SSPM_PLAIN_MINOR_TYPE,
    SSPM_RFC822_MINOR_TYPE,
    SSPM_DIGEST_MINOR_TYPE,
    SSPM_CALENDAR_MINOR_TYPE,
    SSPM_MIXED_MINOR_TYPE,
    SSPM_RELATED_MINOR_TYPE,
    SSPM_ALTERNATIVE_MINOR_TYPE,
    SSPM_PARALLEL_MINOR_TYPE,
    SSPM_UNKNOWN_MINOR_TYPE
};

enum sspm_encoding
{
    SSPM_NO_ENCODING,
    SSPM_QUOTED_PRINTABLE_ENCODING,
    SSPM_8BIT_ENCODING,
    SSPM_7BIT_ENCODING,
    SSPM_BINARY_ENCODING,
    SSPM_BASE64_ENCODING,
    SSPM_UNKNOWN_ENCODING
};

enum sspm_error
{
    SSPM_NO_ERROR,
    SSPM_UNEXPECTED_BOUNDARY_ERROR,
    SSPM_WRONG_BOUNDARY_ERROR,
    SSPM_NO_BOUNDARY_ERROR,
    SSPM_NO_HEADER_ERROR,
    SSPM_MALFORMED_HEADER_ERROR
};

struct sspm_header
{
    int def;
    char *boundary;
    enum sspm_major_type major;
    enum sspm_minor_type minor;
    char *minor_text;
    char **content_type_params;
    char *charset;
    enum sspm_encoding encoding;
    char *filename;
    char *content_id;
    enum sspm_error error;
    char *error_text;
};

struct sspm_part
{
    struct sspm_header header;
    int level;
    size_t data_size;
    void *data;
};

struct sspm_action_map
{
    enum sspm_major_type major;
    enum sspm_minor_type minor;
    void *(*new_part) (void);
    void (*add_line) (void *part, struct sspm_header * header, const char *line, size_t size);
    void *(*end_part) (void *part);
    void (*free_part) (void *part);
};

LIBICAL_ICAL_EXPORT const char *sspm_major_type_string(enum sspm_major_type type);

LIBICAL_ICAL_EXPORT const char *sspm_minor_type_string(enum sspm_minor_type type);

LIBICAL_ICAL_EXPORT const char *sspm_encoding_string(enum sspm_encoding type);

LIBICAL_ICAL_EXPORT int sspm_parse_mime(struct sspm_part *parts,
                                        size_t max_parts,
                                        const struct sspm_action_map *actions,
                                        char *(*get_string) (char *s, size_t size, void *data),
                                        void *get_string_data, struct sspm_header *first_header);

LIBICAL_ICAL_EXPORT void sspm_free_parts(struct sspm_part *parts, size_t max_parts);

LIBICAL_ICAL_EXPORT char *decode_quoted_printable(char *dest, char *src, size_t *size);

LIBICAL_ICAL_EXPORT char *decode_base64(char *dest, char *src, size_t *size);

LIBICAL_ICAL_EXPORT int sspm_write_mime(struct sspm_part *parts, size_t num_parts,
                                        char **output_string, const char *header);

#endif /* ICAL_SSPM_H */

/*======================================================================
 FILE: icalmime.h
 CREATOR: eric 26 July 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALMIME_H
#define ICALMIME_H

#include "libical_ical_export.h"


LIBICAL_ICAL_EXPORT icalcomponent *icalmime_parse(char *(*line_gen_func) (char *s,
                                                                          size_t size,
                                                                          void *d), void *data);

#endif /* !ICALMIME_H */

/*======================================================================
 FILE: icallangbind.h
 CREATOR: eric 25 jan 2001

 (C) COPYRIGHT 1999 Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALLANGBIND_H
#define ICALLANGBIND_H

#include "libical_ical_export.h"


LIBICAL_ICAL_EXPORT int *icallangbind_new_array(int size);

LIBICAL_ICAL_EXPORT void icallangbind_free_array(int *array);

LIBICAL_ICAL_EXPORT int icallangbind_access_array(int *array, int index);

LIBICAL_ICAL_EXPORT icalproperty *icallangbind_get_first_property(icalcomponent *c,
                                                                  const char *prop);

LIBICAL_ICAL_EXPORT icalproperty *icallangbind_get_next_property(icalcomponent *c,
                                                                 const char *prop);

LIBICAL_ICAL_EXPORT icalcomponent *icallangbind_get_first_component(icalcomponent *c,
                                                                    const char *comp);

LIBICAL_ICAL_EXPORT icalcomponent *icallangbind_get_next_component(icalcomponent *c,
                                                                   const char *comp);

LIBICAL_ICAL_EXPORT icalparameter *icallangbind_get_first_parameter(icalproperty *prop);

LIBICAL_ICAL_EXPORT icalparameter *icallangbind_get_next_parameter(icalproperty *prop);

LIBICAL_ICAL_EXPORT const char *icallangbind_property_eval_string(icalproperty *prop,
                                                                  const char *sep);

LIBICAL_ICAL_EXPORT char *icallangbind_property_eval_string_r(icalproperty *prop,
                                                              const char *sep);

LIBICAL_ICAL_EXPORT int icallangbind_string_to_open_flag(const char *str);

LIBICAL_ICAL_EXPORT const char *icallangbind_quote_as_ical(const char *str);

LIBICAL_ICAL_EXPORT char *icallangbind_quote_as_ical_r(const char *str);

#endif


#ifdef __cplusplus
}
#endif
#endif
#endif
