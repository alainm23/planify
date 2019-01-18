/* Miscellaneous time-related utilities
 *
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

#include <string.h>
#include <ctype.h>
#include "e-cal-time-util.h"


#ifdef G_OS_WIN32
#ifdef gmtime_r
#undef gmtime_r
#endif

/* The gmtime() in Microsoft's C library is MT-safe */
#define gmtime_r(tp,tmp) (gmtime(tp)?(*(tmp)=*gmtime(tp),(tmp)):0)
#endif

#define REFORMATION_DAY 639787	/* First day of the reformation, counted from 1 Jan 1 */
#define MISSING_DAYS 11		/* They corrected out 11 days */
#define THURSDAY 4		/* First day of reformation */
#define SATURDAY 6		/* Offset value; 1 Jan 1 was a Saturday */
#define ISODATE_LENGTH 17 /* 4+2+2+1+2+2+2+1 + 1 */

/* Number of days in a month, using 0 (Jan) to 11 (Dec). For leap years,
 * add 1 to February (month 1). */
static const gint days_in_month[12] = {
	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

/**************************************************************************
 * time_t manipulation functions.
 *
 * NOTE: these use the Unix timezone functions like mktime() and localtime()
 * and so should not be used in Evolution. New Evolution code should use
 * icaltimetype values rather than time_t values wherever possible.
 **************************************************************************/

/**
 * time_add_day:
 * @time: A time_t value.
 * @days: Number of days to add.
 *
 * Adds a day onto the time, using local time.
 * Note that if clocks go forward due to daylight savings time, there are
 * some non-existent local times, so the hour may be changed to make it a
 * valid time. This also means that it may not be wise to keep calling
 * time_add_day() to step through a certain period - if the hour gets changed
 * to make it valid time, any further calls to time_add_day() will also return
 * this hour, which may not be what you want.
 *
 * Returns: a time_t value containing @time plus the days added.
 */
time_t
time_add_day (time_t time,
              gint days)
{
	struct tm *tm;

	tm = localtime (&time);
	tm->tm_mday += days;
	tm->tm_isdst = -1;

	return mktime (tm);
}

/**
 * time_add_week:
 * @time: A time_t value.
 * @weeks: Number of weeks to add.
 *
 * Adds the given number of weeks to a time value.
 *
 * Returns: a time_t value containing @time plus the weeks added.
 */
time_t
time_add_week (time_t time,
               gint weeks)
{
	return time_add_day (time, weeks * 7);
}

/**
 * time_day_begin:
 * @t: A time_t value.
 *
 * Returns the start of the day, according to the local time.
 *
 * Returns: the time corresponding to the beginning of the day.
 */
time_t
time_day_begin (time_t t)
{
	struct tm tm;

	tm = *localtime (&t);
	tm.tm_hour = tm.tm_min = tm.tm_sec = 0;
	tm.tm_isdst = -1;

	return mktime (&tm);
}

/**
 * time_day_end:
 * @t: A time_t value.
 *
 * Returns the end of the day, according to the local time.
 *
 * Returns: the time corresponding to the end of the day.
 */
time_t
time_day_end (time_t t)
{
	struct tm tm;

	tm = *localtime (&t);
	tm.tm_hour = tm.tm_min = tm.tm_sec = 0;
	tm.tm_mday++;
	tm.tm_isdst = -1;

	return mktime (&tm);
}

/**************************************************************************
 * time_t manipulation functions, using timezones in libical.
 *
 * NOTE: these are only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values rather than
 * time_t values wherever possible.
 **************************************************************************/

/**
 * time_add_day_with_zone:
 * @time: A time_t value.
 * @days: Number of days to add.
 * @zone: Timezone to use.
 *
 * Adds or subtracts a number of days to/from the given time_t value, using
 * the given timezone.
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: a time_t value containing @time plus the days added.
 */
time_t
time_add_day_with_zone (time_t time,
                        gint days,
                        icaltimezone *zone)
{
	struct icaltimetype tt;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Add/subtract the number of days. */
	icaltime_adjust (&tt, days, 0, 0, 0);

	/* Convert back to a time_t. */
	return icaltime_as_timet_with_zone (tt, zone);
}

/**
 * time_add_week_with_zone:
 * @time: A time_t value.
 * @weeks: Number of weeks to add.
 * @zone: Timezone to use.
 *
 * Adds or subtracts a number of weeks to/from the given time_t value, using
 * the given timezone.
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: a time_t value containing @time plus the weeks added.
 */
time_t
time_add_week_with_zone (time_t time,
                         gint weeks,
                         icaltimezone *zone)
{
	return time_add_day_with_zone (time, weeks * 7, zone);
}

/**
 * time_add_month_with_zone:
 * @time: A time_t value.
 * @months: Number of months to add.
 * @zone: Timezone to use.
 *
 * Adds or subtracts a number of months to/from the given time_t value, using
 * the given timezone.
 *
 * If the day would be off the end of the month (e.g. adding 1 month to
 * 30th January, would lead to an invalid day, 30th February), it moves it
 * down to the last day in the month, e.g. 28th Feb (or 29th in a leap year.)
 *
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: a time_t value containing @time plus the months added.
 */
time_t
time_add_month_with_zone (time_t time,
                          gint months,
                          icaltimezone *zone)
{
	struct icaltimetype tt;
	gint day, days_in_month;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Add on the number of months. */
	tt.month += months;

	/* Save the day, and set it to 1, so we don't overflow into the next
	 * month. */
	day = tt.day;
	tt.day = 1;

	/* Normalize it, fixing any month overflow. */
	tt = icaltime_normalize (tt);

	/* If we go past the end of a month, set it to the last day. */
	days_in_month = time_days_in_month (tt.year, tt.month - 1);
	if (day > days_in_month)
		day = days_in_month;

	tt.day = day;

	/* Convert back to a time_t. */
	return icaltime_as_timet_with_zone (tt, zone);
}

/**
 * time_year_begin_with_zone:
 * @time: A time_t value.
 * @zone: Timezone to use.
 *
 * Returns the start of the year containing the given time_t, using the given
 * timezone.
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: the beginning of the year.
 */
time_t
time_year_begin_with_zone (time_t time,
                           icaltimezone *zone)
{
	struct icaltimetype tt;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Set it to the start of the year. */
	tt.month = 1;
	tt.day = 1;
	tt.hour = 0;
	tt.minute = 0;
	tt.second = 0;

	/* Convert back to a time_t. */
	return icaltime_as_timet_with_zone (tt, zone);
}

/**
 * time_month_begin_with_zone:
 * @time: A time_t value.
 * @zone: Timezone to use.
 *
 * Returns the start of the month containing the given time_t, using the given
 * timezone.
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: the beginning of the month.
 */
time_t
time_month_begin_with_zone (time_t time,
                            icaltimezone *zone)
{
	struct icaltimetype tt;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Set it to the start of the month. */
	tt.day = 1;
	tt.hour = 0;
	tt.minute = 0;
	tt.second = 0;

	/* Convert back to a time_t. */
	return icaltime_as_timet_with_zone (tt, zone);
}

/**
 * time_week_begin_with_zone:
 * @time: A time_t value.
 * @week_start_day: Day to use as the starting of the week.
 * @zone: Timezone to use.
 *
 * Returns the start of the week containing the given time_t, using the given
 * timezone. week_start_day should use the same values as mktime(),
 * i.e. 0 (Sun) to 6 (Sat).
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: the beginning of the week.
 */
time_t
time_week_begin_with_zone (time_t time,
                           gint week_start_day,
                           icaltimezone *zone)
{
	struct icaltimetype tt;
	gint weekday, offset;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Get the weekday. */
	weekday = time_day_of_week (tt.day, tt.month - 1, tt.year);

	/* Calculate the current offset from the week start day. */
	offset = (weekday + 7 - week_start_day) % 7;

	/* Set it to the start of the month. */
	tt.day -= offset;
	tt.hour = 0;
	tt.minute = 0;
	tt.second = 0;

	/* Normalize it, to fix any overflow. */
	tt = icaltime_normalize (tt);

	/* Convert back to a time_t. */
	return icaltime_as_timet_with_zone (tt, zone);
}

/**
 * time_day_begin_with_zone:
 * @time: A time_t value.
 * @zone: Timezone to use.
 *
 * Returns the start of the day containing the given time_t, using the given
 * timezone.
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: the beginning of the day.
 */
time_t
time_day_begin_with_zone (time_t time,
                          icaltimezone *zone)
{
	struct icaltimetype tt;
	time_t new_time;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Set it to the start of the day. */
	tt.hour = 0;
	tt.minute = 0;
	tt.second = 0;

	/* Convert back to a time_t and make sure the time is in the past. */
	while (new_time = icaltime_as_timet_with_zone (tt, zone), new_time > time) {
		icaltime_adjust (&tt, 0, -1, 0, 0);
	}

	return new_time;
}

/**
 * time_day_end_with_zone:
 * @time: A time_t value.
 * @zone: Timezone to use.
 *
 * Returns the end of the day containing the given time_t, using the given
 * timezone. (The end of the day is the start of the next day.)
 * NOTE: this function is only here to make the transition to the timezone
 * functions easier. New code should use icaltimetype values and
 * icaltime_adjust() to add or subtract days, hours, minutes & seconds.
 *
 * Returns: the end of the day.
 */
time_t
time_day_end_with_zone (time_t time,
                        icaltimezone *zone)
{
	struct icaltimetype tt;
	time_t new_time;

	/* Convert to an icaltimetype. */
	tt = icaltime_from_timet_with_zone (time, FALSE, zone);

	/* Set it to the start of the next day. */
	tt.hour = 0;
	tt.minute = 0;
	tt.second = 0;

	icaltime_adjust (&tt, 1, 0, 0, 0);

	/* Convert back to a time_t and make sure the time is in the future. */
	while (new_time = icaltime_as_timet_with_zone (tt, zone), new_time <= time) {
		icaltime_adjust (&tt, 0, 1, 0, 0);
	}

	return new_time;
}

/**
 * time_to_gdate_with_zone:
 * @date: Destination #GDate value.
 * @time: A time value.
 * @zone: Desired timezone for destination @date, or NULL if the UTC timezone
 * is desired.
 *
 * Converts a time_t value to a #GDate structure using the specified timezone.
 * This is analogous to g_date_set_time() but takes the timezone into account.
 **/
void
time_to_gdate_with_zone (GDate *date,
                         time_t time,
                         icaltimezone *zone)
{
	struct icaltimetype tt;

	g_return_if_fail (date != NULL);
	g_return_if_fail (time != -1);

	tt = icaltime_from_timet_with_zone (
		time, FALSE,
		zone ? zone : icaltimezone_get_utc_timezone ());

	g_date_set_dmy (date, tt.day, tt.month, tt.year);
}

/**************************************************************************
 * General time functions.
 **************************************************************************/

/**
 * time_days_in_month:
 * @year: The year.
 * @month: The month.
 *
 * Returns the number of days in the month. Year is the normal year, e.g. 2001.
 * Month is 0 (Jan) to 11 (Dec).
 *
 * Returns: number of days in the given month/year.
 */
gint
time_days_in_month (gint year,
                    gint month)
{
	gint days;

	g_return_val_if_fail (year >= 1900, 0);
	g_return_val_if_fail ((month >= 0) && (month < 12), 0);

	days = days_in_month[month];
	if (month == 1 && time_is_leap_year (year))
		days++;

	return days;
}

/**
 * time_day_of_year:
 * @day: The day.
 * @month: The month.
 * @year: The year.
 *
 * Returns the 1-based day number within the year of the specified date.
 * Year is the normal year, e.g. 2001. Month is 0 to 11.
 *
 * Returns: the day of the year.
 */
gint
time_day_of_year (gint day,
                  gint month,
                  gint year)
{
	gint i;

	for (i = 0; i < month; i++) {
		day += days_in_month[i];

		if (i == 1 && time_is_leap_year (year))
			day++;
	}

	return day;
}

/**
 * time_day_of_week:
 * @day: The day.
 * @month: The month.
 * @year: The year.
 *
 * Returns the day of the week for the specified date, 0 (Sun) to 6 (Sat).
 * For the days that were removed on the Gregorian reformation, it returns
 * Thursday. Year is the normal year, e.g. 2001. Month is 0 to 11.
 *
 * Returns: the day of the week for the given date.
 */
gint
time_day_of_week (gint day,
                  gint month,
                  gint year)
{
	gint n;

	n = (year - 1) * 365 + time_leap_years_up_to (year - 1)
	  + time_day_of_year (day, month, year);

	if (n < REFORMATION_DAY)
		return (n - 1 + SATURDAY) % 7;

	if (n >= (REFORMATION_DAY + MISSING_DAYS))
		return (n - 1 + SATURDAY - MISSING_DAYS) % 7;

	return THURSDAY;
}

/**
 * time_is_leap_year:
 * @year: The year.
 *
 * Returns whether the specified year is a leap year. Year is the normal year,
 * e.g. 2001.
 *
 * Returns: TRUE if the year is leap, FALSE if not.
 */
gboolean
time_is_leap_year (gint year)
{
	if (year <= 1752)
		return !(year % 4);
	else
		return (!(year % 4) && (year % 100)) || !(year % 400);
}

/**
 * time_leap_years_up_to:
 * @year: The year.
 *
 * Returns the number of leap years since year 1 up to (but not including) the
 * specified year. Year is the normal year, e.g. 2001.
 *
 * Returns: number of leap years.
 */
gint
time_leap_years_up_to (gint year)
{
	/* There is normally a leap year every 4 years, except at the turn of
	 * centuries since 1700. But there is a leap year on centuries since 1700
	 * which are divisible by 400. */
	return (year / 4
		- ((year > 1700) ? (year / 100 - 17) : 0)
		+ ((year > 1600) ? ((year - 1600) / 400) : 0));
}

/**
 * isodate_from_time_t:
 * @t: A time value.
 *
 * Creates an ISO 8601 UTC representation from a time value.
 *
 * Returns: String with the ISO 8601 representation of the UTC time.
 **/
gchar *
isodate_from_time_t (time_t t)
{
	gchar *ret;
	struct tm stm;
	const gchar fmt[] = "%04d%02d%02dT%02d%02d%02dZ";

	gmtime_r (&t, &stm);
	ret = g_malloc (ISODATE_LENGTH);
	g_snprintf (
		ret, ISODATE_LENGTH, fmt,
		(stm.tm_year + 1900),
		(stm.tm_mon + 1),
		stm.tm_mday,
		stm.tm_hour,
		stm.tm_min,
		stm.tm_sec);

	return ret;
}

/**
 * time_from_isodate:
 * @str: Date/time value in ISO 8601 format.
 *
 * Converts an ISO 8601 UTC time string into a time_t value.
 *
 * Returns: Time_t corresponding to the specified ISO string.
 * Note that we only allow UTC times at present.
 **/
time_t
time_from_isodate (const gchar *str)
{
	struct icaltimetype tt = icaltime_null_time ();
	icaltimezone *utc_zone;
	gint len, i;

	g_return_val_if_fail (str != NULL, -1);

	/* yyyymmdd[Thhmmss[Z]] */

	len = strlen (str);

	if (!(len == 8 || len == 15 || len == 16))
		return -1;

	for (i = 0; i < len; i++)
		if (!((i != 8 && i != 15 && isdigit (str[i]))
		      || (i == 8 && str[i] == 'T')
		      || (i == 15 && str[i] == 'Z')))
			return -1;

#define digit_at(x,y) (x[y] - '0')

	tt.year = digit_at (str, 0) * 1000
		+ digit_at (str, 1) * 100
		+ digit_at (str, 2) * 10
		+ digit_at (str, 3);

	tt.month = digit_at (str, 4) * 10
		 + digit_at (str, 5);

	tt.day = digit_at (str, 6) * 10
	       + digit_at (str, 7);

	if (len > 8) {
		tt.hour = digit_at (str, 9) * 10
			+ digit_at (str, 10);
		tt.minute = digit_at (str, 11) * 10
			   + digit_at (str, 12);
		tt.second = digit_at (str, 13) * 10
			   + digit_at (str, 14);
	}

	utc_zone = icaltimezone_get_utc_timezone ();

	return icaltime_as_timet_with_zone (tt, utc_zone);
}

/**
 * icaltimetype_to_tm:
 * @itt: An icaltimetype structure.
 *
 * Convers an icaltimetype structure into a GLibc's struct tm.
 *
 * Returns: (transfer full): The converted time as a struct tm. All fields will be
 * set properly except for tm.tm_yday.
 *
 * Since: 2.22
 */
struct tm
icaltimetype_to_tm (struct icaltimetype *itt)
{
	struct tm tm;

	memset (&tm, 0, sizeof (struct tm));

	if (!itt->is_date) {
		tm.tm_sec = itt->second;
		tm.tm_min = itt->minute;
		tm.tm_hour = itt->hour;
	}

	tm.tm_mday = itt->day;
	tm.tm_mon = itt->month - 1;
	tm.tm_year = itt->year - 1900;
	tm.tm_wday = time_day_of_week (itt->day, itt->month - 1, itt->year);
	tm.tm_isdst = -1;

	return tm;
}

/**
 * icaltimetype_to_tm_with_zone:
 * @itt: A time value.
 * @from_zone: Source timezone.
 * @to_zone: Destination timezone.
 *
 * Converts a time value from one timezone to another, and returns a struct tm
 * representation of the time.
 *
 * Returns: (transfer full): The converted time as a struct tm. All fields will be
 * set properly except for tm.tm_yday.
 *
 * Since: 2.22
 **/
struct tm
icaltimetype_to_tm_with_zone (struct icaltimetype *itt,
                              icaltimezone *from_zone,
                              icaltimezone *to_zone)
{
	struct tm tm;
	struct icaltimetype itt_copy;

	memset (&tm, 0, sizeof (tm));
	tm.tm_isdst = -1;

	g_return_val_if_fail (itt != NULL, tm);

	itt_copy = *itt;

	icaltimezone_convert_time (&itt_copy, from_zone, to_zone);
	tm = icaltimetype_to_tm (&itt_copy);

	return tm;
}

/**
 * tm_to_icaltimetype:
 * @tm: A struct tm.
 * @is_date: Whether the given time is a date only or not.
 *
 * Converts a struct tm into an icaltimetype.
 *
 * Returns: (transfer full): The converted time as an icaltimetype.
 *
 * Since: 2.22
 */
struct icaltimetype
tm_to_icaltimetype (struct tm *tm,
                    gboolean is_date)
{
	struct icaltimetype itt;

	memset (&itt, 0, sizeof (struct icaltimetype));

	if (!is_date) {
		itt.second = tm->tm_sec;
		itt.minute = tm->tm_min;
		itt.hour = tm->tm_hour;
	}

	itt.day = tm->tm_mday;
	itt.month = tm->tm_mon + 1;
	itt.year = tm->tm_year + 1900;

	itt.is_date = is_date;

	return itt;
}

