/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Time utility functions
 *
 * (C) 2001 Ximian, Inc.
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
 * Authors: Damon Chaplin (damon@ximian.com)
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_TIME_UTILS_H
#define E_TIME_UTILS_H

#include <time.h>
#include <glib.h>

G_BEGIN_DECLS

/**
 * ETimeParseStatus:
 * @E_TIME_PARSE_OK: The time string was parsed successfully.
 * @E_TIME_PARSE_NONE: The time string was empty.
 * @E_TIME_PARSE_INVALID: The time string was not formatted correctly.
 **/
typedef enum {
	E_TIME_PARSE_OK,
	E_TIME_PARSE_NONE,
	E_TIME_PARSE_INVALID
} ETimeParseStatus;

/* Tries to parse a string containing a date and time. */
ETimeParseStatus
		e_time_parse_date_and_time	(const gchar *value,
						 struct tm *result);

/* Tries to parse a string containing a date. */
ETimeParseStatus
		e_time_parse_date		(const gchar *value,
						 struct tm *result);

/* Same behavior as the functions above with two_digit_year set to NULL. */
ETimeParseStatus
		e_time_parse_date_and_time_ex	(const gchar *value,
						 struct tm *result,
						 gboolean *two_digit_year);
ETimeParseStatus
		e_time_parse_date_ex		(const gchar *value,
						 struct tm *result,
						 gboolean *two_digit_year);

/* Tries to parse a string containing a time. */
ETimeParseStatus
		e_time_parse_time		(const gchar *value,
						 struct tm *result);

/* Turns a struct tm into a string like "Wed  3/12/00 12:00:00 AM". */
void		e_time_format_date_and_time	(struct tm *date_tm,
						 gboolean use_24_hour_format,
						 gboolean show_midnight,
						 gboolean show_zero_seconds,
						 gchar *buffer,
						 gint buffer_size);

/* Formats a time from a struct tm, e.g. "01:59 PM". */
void		e_time_format_time		(struct tm *date_tm,
						 gboolean use_24_hour_format,
						 gboolean show_zero_seconds,
						 gchar *buffer,
						 gint buffer_size);

/* Like mktime(3), but assumes UTC instead of local timezone. */
time_t		e_mktime_utc			(struct tm *tm);

/* Like localtime_r(3), but also returns an offset in minutes after UTC.
 * (Calling gmtime with tt + offset would generate the same tm) */
void		e_localtime_with_offset		(time_t tt,
						 struct tm *tm,
						 gint *offset);

/* Returns format like %x, but always exchange all 'y' to 'Y'
 * (force 4 digit year in format).
 * Caller is responsible to g_free returned pointer. */
gchar *		e_time_get_d_fmt_with_4digit_year
						(void);

G_END_DECLS

#endif /* E_TIME_UTILS_H */
