/* Miscellaneous time-related utilities
 *
 * Copyright (C) 1998 The Free Software Foundation
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Federico Mena <federico@ximian.com>
 *          Miguel de Icaza <miguel@ximian.com>
 *          Damon Chaplin <damon@ximian.com>
 */

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef TIMEUTIL_H
#define TIMEUTIL_H

#include <time.h>
#include <libical/ical.h>
#include <glib.h>

G_BEGIN_DECLS

/**************************************************************************
 * General time functions.
 **************************************************************************/

/* Returns the number of days in the month. Year is the normal year, e.g. 2001.
 * Month is 0 (Jan) to 11 (Dec). */
gint	time_days_in_month	(gint year, gint month);

/* Returns the 1-based day number within the year of the specified date.
 * Year is the normal year, e.g. 2001. Month is 0 to 11. */
gint	time_day_of_year	(gint day, gint month, gint year);

/* Returns the day of the week for the specified date, 0 (Sun) to 6 (Sat).
 * For the days that were removed on the Gregorian reformation, it returns
 * Thursday. Year is the normal year, e.g. 2001. Month is 0 to 11. */
gint	time_day_of_week	(gint day, gint month, gint year);

/* Returns whether the specified year is a leap year. Year is the normal year,
 * e.g. 2001. */
gboolean time_is_leap_year	(gint year);

/* Returns the number of leap years since year 1 up to (but not including) the
 * specified year. Year is the normal year, e.g. 2001. */
gint	time_leap_years_up_to	(gint year);

/* Convert to or from an ISO 8601 representation of a time, in UTC,
 * e.g. "20010708T183000Z". */
gchar   *isodate_from_time_t     (time_t t);
time_t	time_from_isodate	(const gchar *str);

/**************************************************************************
 * time_t manipulation functions.
 *
 * NOTE: these use the Unix timezone functions like mktime() and localtime()
 * and so should not be used in Evolution. New Evolution code should use
 * icaltimetype values rather than time_t values wherever possible.
 **************************************************************************/

/* Add or subtract a number of days, weeks or months. */
time_t	time_add_day		(time_t time, gint days);
time_t	time_add_week		(time_t time, gint weeks);

/* Returns the beginning or end of the day. */
time_t	time_day_begin		(time_t t);
time_t	time_day_end		(time_t t);

/**************************************************************************
 * time_t manipulation functions, using timezones in libical.
 *
 * NOTE: these are only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values rather than
 * time_t values wherever possible.
 **************************************************************************/

/* Adds or subtracts a number of days to/from the given time_t value, using
 * the given timezone. */
time_t	time_add_day_with_zone (time_t time, gint days, icaltimezone *zone);

/* Adds or subtracts a number of weeks to/from the given time_t value, using
 * the given timezone. */
time_t	time_add_week_with_zone (time_t time, gint weeks, icaltimezone *zone);

/* Adds or subtracts a number of months to/from the given time_t value, using
 * the given timezone. */
time_t	time_add_month_with_zone (time_t time, gint months, icaltimezone *zone);

/* Returns the start of the year containing the given time_t, using the given
 * timezone. */
time_t	time_year_begin_with_zone (time_t time, icaltimezone *zone);

/* Returns the start of the month containing the given time_t, using the given
 * timezone. */
time_t	time_month_begin_with_zone (time_t time, icaltimezone *zone);

/* Returns the start of the week containing the given time_t, using the given
 * timezone. week_start_day should use the same values as mktime (),
 * i.e. 0 (Sun) to 6 (Sat). */
time_t	time_week_begin_with_zone (time_t time, gint week_start_day,
				   icaltimezone *zone);

/* Returns the start of the day containing the given time_t, using the given
 * timezone. */
time_t	time_day_begin_with_zone (time_t time, icaltimezone *zone);

/* Returns the end of the day containing the given time_t, using the given
 * timezone. (The end of the day is the start of the next day.) */
time_t	time_day_end_with_zone (time_t time, icaltimezone *zone);

void time_to_gdate_with_zone (GDate *date, time_t time, icaltimezone *zone);

/**************************************************************************
 * struct tm manipulation
 **************************************************************************/

struct tm icaltimetype_to_tm (struct icaltimetype *itt);
struct tm icaltimetype_to_tm_with_zone (struct icaltimetype *itt,
					icaltimezone *from_zone,
					icaltimezone *to_zone);
struct icaltimetype tm_to_icaltimetype (struct tm *tm, gboolean is_date);

G_END_DECLS

#endif
