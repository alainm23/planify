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

#include "evolution-data-server-config.h"

#define _XOPEN_SOURCE
#define _XOPEN_SOURCE_EXTENDED 1  /* for strptime */

/* For tm_gmtoff */
#define _BSD_SOURCE 1
#define _DEFAULT_SOURCE 1

#include <time.h>
#include <sys/time.h>

#ifdef HAVE_NL_LANGINFO
#include <langinfo.h>
#endif /* HAVE_NL_LANGINFO */

#include <string.h>
#include <ctype.h>
#include <glib/gi18n-lib.h>
#include "e-time-utils.h"
#include "e-data-server-util.h"

#ifdef G_OS_WIN32
#ifdef localtime_r
#undef localtime_r
#endif

/* The localtime() in Microsoft's C library is MT-safe */
#define localtime_r(tp,tmp) (localtime(tp)?(*(tmp)=*localtime(tp),(tmp)):0)

#include <windows.h>

static const gchar *
get_locale_string (gint lctype)
{
	gint nbytes = GetLocaleInfo (GetThreadLocale (), lctype, NULL, 0);
	gchar *tem;
	GQuark quark;

	if (nbytes == 0)
		return "???";

	tem = g_malloc (nbytes);

	if (GetLocaleInfo (GetThreadLocale (), lctype, tem, nbytes) == 0) {
		g_free (tem);
		return "???";
	}

	quark = g_quark_from_string (tem);
	g_free (tem);

	return g_quark_to_string (quark);
}

static const gchar *
translate_picture (const gchar *picture)
{
	GString *s = g_string_new ("");
	GQuark quark;

	while (*picture) {
		const gchar *q = picture + 1;
		gint count;

		while (*picture == *q)
			q++;
		count = q - picture;

		switch (*picture) {
		case '\'':
			picture++;
			while (*picture && *picture != '\'') {
				g_string_append_c (s, *picture);
				picture++;
			}
			break;
		case 'd':
			switch (count) {
			case 1:
			case 2:
				g_string_append (s, "%d");
				break;
			case 3:
			case 4:
				g_string_append (s, "%a");
				break;
			}
			picture += count - 1;
			break;
		case 'M':
			switch (count) {
			case 1:
			case 2:
				g_string_append (s, "%m");
				break;
			case 3:
			case 4:
				g_string_append (s, "%b");
				break;
			}
			picture += count - 1;
			break;
		case 'y':
			switch (count) {
			case 1:	/* Last digit of year. Ugh... */
			case 2:
				g_string_append (s, "%y");
				break;
			case 4:
				g_string_append (s, "%Y");
				break;
			}
			picture += count - 1;
			break;
		case 'g':
			/* Era. Huh. Just ignore, as the era stuff
			 * implementation below depends on glibc.
			 */
			picture += count - 1;
			break;
		case 'h':
			g_string_append (s, "%I");
			picture += count - 1;
			break;
		case 'H':
			g_string_append (s, "%H");
			picture += count - 1;
			break;
		case 'm':
			g_string_append (s, "%M");
			picture += count - 1;
			break;
		case 's':
			g_string_append (s, "%S");
			picture += count - 1;
			break;
		case 't':
			g_string_append (s, "%p");
			picture += count - 1;
			break;
		default:
			g_string_append_c (s, *picture);
			break;
		}
		if (*picture)
			picture++;
	}

	quark = g_quark_from_string (s->str);
	g_string_free (s, TRUE);

	return g_quark_to_string (quark);
}

#endif

#ifndef HAVE_STRPTIME

/* strptime() implementation lifted from glibc */

enum ptime_locale_status { not, loc, raw };

/* Copyright (C) 2002, 2004 Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 *
 * The GNU C Library is free software; you can redistribute it and / or
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * The GNU C Library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * License along with the GNU C Library; if not, see <http://www.gnu.org/licenses/>.
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110 - 1301 USA.  */

#include "evolution-data-server-config.h"

#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <string.h>
#include <time.h>

#ifdef _LIBC
# include "../locale/localeinfo.h"
#endif

#ifndef __P
# if defined __GNUC__ || (defined __STDC__ && __STDC__)
#  define __P(args) args
# else
#  define __P(args) ()
# endif  /* GCC.  */
#endif  /* Not __P.  */

#if !defined HAVE_LOCALTIME_R && !defined localtime_r
# ifdef _LIBC
#  define localtime_r __localtime_r
# else
/* Approximate localtime_r as best we can in its absence.  */
#  define localtime_r my_localtime_r
static struct tm *localtime_r __P ((const time_t *, struct tm *));
static struct tm *
localtime_r (t,
             tp)
     const time_t *t;
     struct tm *tp;
{
  struct tm *l = localtime (t);
  if (!l)
    return 0;
  *tp = *l;
  return tp;
}
# endif /* !_LIBC */
#endif /* HAVE_LOCALTIME_R && !defined (localtime_r) */

#define match_char(ch1, ch2) if (ch1 != ch2) return NULL
#if defined _LIBC && defined __GNUC__ && __GNUC__ >= 2
# define match_string(cs1, s2) \
  ({ gsize len = strlen (cs1); \
     gint result = __strncasecmp_l ((cs1), (s2), len, locale) == 0; \
     if (result) (s2) += len; \
     result; })
#else
/* Oh come on.  Get a reasonable compiler.  */
# define match_string(cs1, s2) \
  (g_ascii_strncasecmp ((cs1), (s2), strlen (cs1)) ? 0 : ((s2) += strlen (cs1), 1))
#endif
/* We intentionally do not use isdigit() for testing because this will
 * lead to problems with the wide character version.  */
#define get_number(from, to, n) \
  do { \
    gint __n = n; \
    val = 0; \
    while (*rp == ' ') \
      ++rp; \
    if (*rp < '0' || *rp > '9') \
      return NULL; \
    do { \
      val *= 10; \
      val += *rp++ - '0'; \
    } while (--__n > 0 && val * 10 <= to && *rp >= '0' && *rp <= '9'); \
    if (val < from || val > to) \
      return NULL; \
  } while (0)
#ifdef _NL_CURRENT
# define get_alt_number(from, to, n) \
  ({ \
     __label__ do_normal; \
 \
     if (*decided != raw) \
       { \
	 val = _nl_parse_alt_digit (&rp HELPER_LOCALE_ARG); \
	 if (val == -1 && *decided != loc) \
	   { \
	     *decided = loc; \
	     goto do_normal; \
	   } \
	if (val < from || val > to) \
	  return NULL; \
       } \
     else \
       { \
       do_normal: \
	 get_number (from, to, n); \
       } \
    0; \
  })
#else
# define get_alt_number(from, to, n) \
  /* We don't have the alternate representation.  */ \
  get_number (from, to, n)
#endif
#define recursive(new_fmt) \
  (*(new_fmt) != '\0' \
   && (rp = __strptime_internal (rp, (new_fmt), tm, \
				 decided, era_cnt LOCALE_ARG)) != NULL)

#ifdef _LIBC
/* This is defined in locale/C-time.c in the GNU libc.  */
extern const struct locale_data _nl_C_LC_TIME attribute_hidden;

# define weekday_name (&_nl_C_LC_TIME.values[_NL_ITEM_INDEX (DAY_1)].string)
# define ab_weekday_name \
  (&_nl_C_LC_TIME.values[_NL_ITEM_INDEX (ABDAY_1)].string)
# define month_name (&_nl_C_LC_TIME.values[_NL_ITEM_INDEX (MON_1)].string)
# define ab_month_name (&_nl_C_LC_TIME.values[_NL_ITEM_INDEX (ABMON_1)].string)
# define HERE_D_T_FMT (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (D_T_FMT)].string)
# define HERE_D_FMT (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (D_FMT)].string)
# define HERE_AM_STR (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (AM_STR)].string)
# define HERE_PM_STR (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (PM_STR)].string)
# define HERE_T_FMT_AMPM \
  (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (T_FMT_AMPM)].string)
# define HERE_T_FMT (_nl_C_LC_TIME.values[_NL_ITEM_INDEX (T_FMT)].string)

# define strncasecmp(s1, s2, n) __strncasecmp (s1, s2, n)
#else
static gchar const weekday_name[][10] =
  {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
  };
static gchar const ab_weekday_name[][4] =
  {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
  };
static gchar const month_name[][10] =
  {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  };
static gchar const ab_month_name[][4] =
  {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  };
# define HERE_D_T_FMT "%a %b %e %H:%M:%S %Y"
# define HERE_D_FMT "%m/%d/%y"
# define HERE_AM_STR "AM"
# define HERE_PM_STR "PM"
# define HERE_T_FMT_AMPM "%I:%M:%S %p"
# define HERE_T_FMT "%H:%M:%S"

static const gushort __mon_yday[2][13] =
  {
    /* Normal years.  */
    { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 },
    /* Leap years.  */
    { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 }
  };
#endif

#if defined _LIBC
/* We use this code also for the extended locale handling where the
 * function gets as an additional argument the locale which has to be
 * used.  To access the values we have to redefine the _NL_CURRENT
 * macro.  */
# define strptime		__strptime_l
# undef _NL_CURRENT
# define _NL_CURRENT(category, item) \
  (current->values[_NL_ITEM_INDEX (item)].string)
# undef _NL_CURRENT_WORD
# define _NL_CURRENT_WORD(category, item) \
  (current->values[_NL_ITEM_INDEX (item)].word)
# define LOCALE_PARAM , locale
# define LOCALE_ARG , locale
# define LOCALE_PARAM_PROTO , __locale_t locale
# define LOCALE_PARAM_DECL __locale_t locale;
# define HELPER_LOCALE_ARG , current
# define ISSPACE(Ch) __isspace_l (Ch, locale)
#else
# define LOCALE_PARAM
# define LOCALE_ARG
# define LOCALE_PARAM_DECL
# define LOCALE_PARAM_PROTO
# define HELPER_LOCALE_ARG
# define ISSPACE(Ch) isspace (Ch)
#endif

#ifndef __isleap
/* Nonzero if YEAR is a leap year (every 4 years,
 * except every 100th isn't, and every 400th is).  */
# define __isleap(year) \
  ((year) % 4 == 0 && ((year) % 100 != 0 || (year) % 400 == 0))
#endif

/* Compute the day of the week.  */
static void
day_of_the_week (struct tm *tm)
{
  /* We know that January 1st 1970 was a Thursday (= 4).  Compute the
     the difference between this data in the one on TM and so determine
     the weekday.  */
  gint corr_year = 1900 + tm->tm_year - (tm->tm_mon < 2);
  gint wday = (-473
	      + (365 * (tm->tm_year - 70))
	      + (corr_year / 4)
	      - ((corr_year / 4) / 25) + ((corr_year / 4) % 25 < 0)
	      + (((corr_year / 4) / 25) / 4)
	      + __mon_yday[0][tm->tm_mon]
	      + tm->tm_mday - 1);
  tm->tm_wday = ((wday % 7) + 7) % 7;
}

/* Compute the day of the year.  */
static void
day_of_the_year (struct tm *tm)
{
  tm->tm_yday = (__mon_yday[__isleap (1900 + tm->tm_year)][tm->tm_mon]
		 + (tm->tm_mday - 1));
}

#ifdef _LIBC
gchar *
internal_function
#else
static gchar *
#endif
__strptime_internal (rp,
                     fmt,
                     tm,
                     decided,
                     era_cnt LOCALE_PARAM)
     const gchar *rp;
     const gchar *fmt;
     struct tm *tm;
     enum ptime_locale_status *decided;
     gint era_cnt;
     LOCALE_PARAM_DECL
{
#ifdef _LIBC
  struct locale_data *const current = locale->__locales[LC_TIME];
#endif

  const gchar *rp_backup;
  gint cnt;
  gsize val;
  gint have_I, is_pm;
  gint century, want_century;
  gint want_era;
  gint have_wday, want_xday;
  gint have_yday;
  gint have_mon, have_mday;
  gint have_uweek, have_wweek;
  gint week_no;
#ifdef _NL_CURRENT
  gsize num_eras;
#endif
  struct era_entry *era;

  have_I = is_pm = 0;
  century = -1;
  want_century = 0;
  want_era = 0;
  era = NULL;
  week_no = 0;

  have_wday = want_xday = have_yday = have_mon = have_mday = have_uweek = 0;
  have_wweek = 0;

  while (*fmt != '\0')
    {
      /* A white space in the format string matches 0 more or white
	 space in the input string.  */
      if (ISSPACE (*fmt))
	{
	  while (ISSPACE (*rp))
	    ++rp;
	  ++fmt;
	  continue;
	}

      /* Any character but `%' must be matched by the same character
	 in the iput string.  */
      if (*fmt != '%')
	{
	  match_char (*fmt++, *rp++);
	  continue;
	}

      ++fmt;
#ifndef _NL_CURRENT
      /* We need this for handling the `E' modifier.  */
    start_over:
#endif

      /* Make back up of current processing pointer.  */
      rp_backup = rp;

      switch (*fmt++)
	{
	case '%':
	  /* Match the `%' character itself.  */
	  match_char ('%', *rp++);
	  break;
	case 'a':
	case 'A':
	  /* Match day of week.  */
	  for (cnt = 0; cnt < 7; ++cnt)
	    {
#ifdef _NL_CURRENT
	      if (*decided !=raw)
		{
		  if (match_string (_NL_CURRENT (LC_TIME, DAY_1 + cnt), rp))
		    {
		      if (*decided == not
			  && strcmp (_NL_CURRENT (LC_TIME, DAY_1 + cnt),
				     weekday_name[cnt]))
			*decided = loc;
		      break;
		    }
		  if (match_string (_NL_CURRENT (LC_TIME, ABDAY_1 + cnt), rp))
		    {
		      if (*decided == not
			  && strcmp (_NL_CURRENT (LC_TIME, ABDAY_1 + cnt),
				     ab_weekday_name[cnt]))
			*decided = loc;
		      break;
		    }
		}
#elif defined (G_OS_WIN32)
	      if (*decided !=raw)
		{
		  const gchar *locale_str;

		  locale_str = get_locale_string (LOCALE_SDAYNAME1 + cnt);
		  if (match_string (locale_str, rp))
		    {
		      if (*decided == not
			  && strcmp (locale_str, weekday_name[cnt]))
			*decided = loc;
		      break;
		    }

		  locale_str = get_locale_string (LOCALE_SABBREVDAYNAME1 + cnt);
		  if (match_string (locale_str, rp))
		    {
		      if (*decided == not
			  && strcmp (locale_str, ab_weekday_name[cnt]))
			*decided = loc;
		      break;
		    }
		}
#endif
	      if (*decided != loc
		  && (match_string (weekday_name[cnt], rp)
		      || match_string (ab_weekday_name[cnt], rp)))
		{
		  *decided = raw;
		  break;
		}
	    }
	  if (cnt == 7)
	    /* Does not match a weekday name.  */
	    return NULL;
	  tm->tm_wday = cnt;
	  have_wday = 1;
	  break;
	case 'b':
	case 'B':
	case 'h':
	  /* Match month name.  */
	  for (cnt = 0; cnt < 12; ++cnt)
	    {
#ifdef _NL_CURRENT
	      if (*decided !=raw)
		{
		  if (match_string (_NL_CURRENT (LC_TIME, MON_1 + cnt), rp))
		    {
		      if (*decided == not
			  && strcmp (_NL_CURRENT (LC_TIME, MON_1 + cnt),
				     month_name[cnt]))
			*decided = loc;
		      break;
		    }
		  if (match_string (_NL_CURRENT (LC_TIME, ABMON_1 + cnt), rp))
		    {
		      if (*decided == not
			  && strcmp (_NL_CURRENT (LC_TIME, ABMON_1 + cnt),
				     ab_month_name[cnt]))
			*decided = loc;
		      break;
		    }
		}
#elif defined (G_OS_WIN32)
	      if (*decided !=raw)
		{
		  const gchar *locale_str;

		  locale_str = get_locale_string (LOCALE_SMONTHNAME1 + cnt);
		  if (match_string (locale_str, rp))
		    {
		      if (*decided == not
			  && strcmp (locale_str, month_name[cnt]))
			*decided = loc;
		      break;
		    }

		  locale_str = get_locale_string (LOCALE_SABBREVMONTHNAME1 + cnt);
		  if (match_string (locale_str, rp))
		    {
		      if (*decided == not
			  && strcmp (locale_str, ab_month_name[cnt]))
			*decided = loc;
		      break;
		    }
		}
#endif
	      if (match_string (month_name[cnt], rp)
		  || match_string (ab_month_name[cnt], rp))
		{
		  *decided = raw;
		  break;
		}
	    }
	  if (cnt == 12)
	    /* Does not match a month name.  */
	    return NULL;
	  tm->tm_mon = cnt;
	  want_xday = 1;
	  break;
	case 'c':
	  /* Match locale's date and time format.  */
#ifdef _NL_CURRENT
	  if (*decided != raw)
	    {
	      if (!recursive (_NL_CURRENT (LC_TIME, D_T_FMT)))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not &&
		      strcmp (_NL_CURRENT (LC_TIME, D_T_FMT), HERE_D_T_FMT))
		    *decided = loc;
		  want_xday = 1;
		  break;
		}
	      *decided = raw;
	    }
#elif defined (G_OS_WIN32)
	  if (*decided != raw)
	    {
	      gchar *d_t_fmt =
		      g_strconcat (get_locale_string (LOCALE_SSHORTDATE),
				   " ",
				   get_locale_string (LOCALE_STIMEFORMAT),
				   NULL);
	      const gchar *posix_d_t_fmt = translate_picture (d_t_fmt);

	      g_free (d_t_fmt);

	      if (!recursive (posix_d_t_fmt))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not &&
		      strcmp (posix_d_t_fmt, HERE_D_T_FMT))
		    *decided = loc;
		  want_xday = 1;
		  break;
		}
	      *decided = raw;
	    }
#endif
	  if (!recursive (HERE_D_T_FMT))
	    return NULL;
	  want_xday = 1;
	  break;
	case 'C':
	  /* Match century number.  */
#ifdef _NL_CURRENT
	match_century:
#endif
	  get_number (0, 99, 2);
	  century = val;
	  want_xday = 1;
	  break;
	case 'd':
	case 'e':
	  /* Match day of month.  */
	  get_number (1, 31, 2);
	  tm->tm_mday = val;
	  have_mday = 1;
	  want_xday = 1;
	  break;
	case 'F':
	  if (!recursive ("%Y-%m-%d"))
	    return NULL;
	  want_xday = 1;
	  break;
	case 'x':
#ifdef _NL_CURRENT
	  if (*decided != raw)
	    {
	      if (!recursive (_NL_CURRENT (LC_TIME, D_FMT)))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not
		      && strcmp (_NL_CURRENT (LC_TIME, D_FMT), HERE_D_FMT))
		    *decided = loc;
		  want_xday = 1;
		  break;
		}
	      *decided = raw;
	    }
#elif defined (G_OS_WIN32)
	  if (*decided != raw)
	    {
		const gchar *picture;
		const gchar *posix_d_fmt;

		picture = get_locale_string (LOCALE_SSHORTDATE);
		posix_d_fmt = translate_picture (picture);

		if (!recursive (posix_d_fmt))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not
		      && strcmp (posix_d_fmt, HERE_D_FMT))
		    *decided = loc;
		  want_xday = 1;
		  break;
		}
	      *decided = raw;
	    }
#endif
	  /* Fall through.  */
	case 'D':
	  /* Match standard day format.  */
	  if (!recursive (HERE_D_FMT))
	    return NULL;
	  want_xday = 1;
	  break;
	case 'k':
	case 'H':
	  /* Match hour in 24-hour clock.  */
	  get_number (0, 23, 2);
	  tm->tm_hour = val;
	  have_I = 0;
	  break;
	case 'l':
	  /* Match hour in 12-hour clock.  GNU extension.  */
	case 'I':
	  /* Match hour in 12-hour clock.  */
	  get_number (1, 12, 2);
	  tm->tm_hour = val % 12;
	  have_I = 1;
	  break;
	case 'j':
	  /* Match day number of year.  */
	  get_number (1, 366, 3);
	  tm->tm_yday = val - 1;
	  have_yday = 1;
	  break;
	case 'm':
	  /* Match number of month.  */
	  get_number (1, 12, 2);
	  tm->tm_mon = val - 1;
	  have_mon = 1;
	  want_xday = 1;
	  break;
	case 'M':
	  /* Match minute.  */
	  get_number (0, 59, 2);
	  tm->tm_min = val;
	  break;
	case 'n':
	case 't':
	  /* Match any white space.  */
	  while (ISSPACE (*rp))
	    ++rp;
	  break;
	case 'p':
	  /* Match locale's equivalent of AM/PM.  */
#ifdef _NL_CURRENT
	  if (*decided != raw)
	    {
	      if (match_string (_NL_CURRENT (LC_TIME, AM_STR), rp))
		{
		  if (strcmp (_NL_CURRENT (LC_TIME, AM_STR), HERE_AM_STR))
		    *decided = loc;
		  break;
		}
	      if (match_string (_NL_CURRENT (LC_TIME, PM_STR), rp))
		{
		  if (strcmp (_NL_CURRENT (LC_TIME, PM_STR), HERE_PM_STR))
		    *decided = loc;
		  is_pm = 1;
		  break;
		}
	      *decided = raw;
	    }
#elif defined (G_OS_WIN32)
	  if (*decided != raw)
	    {
		if (match_string (get_locale_string (LOCALE_S1159), rp))
		{
		    if (strcmp (get_locale_string (LOCALE_S1159), HERE_AM_STR))
		    *decided = loc;
		  break;
		}
		if (match_string (get_locale_string (LOCALE_S2359), rp))
		{
		  if (strcmp (get_locale_string (LOCALE_S2359), HERE_PM_STR))
		    *decided = loc;
		  is_pm = 1;
		  break;
		}
	      *decided = raw;
	    }
#endif
	  if (!match_string (HERE_AM_STR, rp))
	    {
	      if (match_string (HERE_PM_STR, rp))
		is_pm = 1;
	      else
		return NULL;
	    }
	  break;
	case 'r':
#ifdef _NL_CURRENT
	  if (*decided != raw)
	    {
	      if (!recursive (_NL_CURRENT (LC_TIME, T_FMT_AMPM)))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not &&
		      strcmp (_NL_CURRENT (LC_TIME, T_FMT_AMPM),
			      HERE_T_FMT_AMPM))
		    *decided = loc;
		  break;
		}
	      *decided = raw;
	    }
#elif defined (G_OS_WIN32)
	  if (*decided != raw)
	    {
	      gchar *t_p_fmt =
		      g_strconcat (get_locale_string (LOCALE_STIMEFORMAT),
				   " tt",
				   NULL);
	      const gchar *posix_t_p_fmt = translate_picture (t_p_fmt);

	      g_free (t_p_fmt);

	      if (!recursive (posix_t_p_fmt))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (*decided == not &&
		      strcmp (posix_t_p_fmt,
			      HERE_T_FMT_AMPM))
		    *decided = loc;
		  break;
		}
	      *decided = raw;
	    }
#endif
	  if (!recursive (HERE_T_FMT_AMPM))
	    return NULL;
	  break;
	case 'R':
	  if (!recursive ("%H:%M"))
	    return NULL;
	  break;
	case 's':
	  {
	    /* The number of seconds may be very high so we cannot use
	       the `get_number' macro.  Instead read the number
	       character for character and construct the result while
	       doing this.  */
	    time_t secs = 0;
	    if (*rp < '0' || *rp > '9')
	      /* We need at least one digit.  */
	      return NULL;

	    do
	      {
		secs *= 10;
		secs += *rp++ - '0';
	      }
	    while (*rp >= '0' && *rp <= '9');

	    if (localtime_r (&secs, tm) == NULL)
	      /* Error in function.  */
	      return NULL;
	  }
	  break;
	case 'S':
	  get_number (0, 61, 2);
	  tm->tm_sec = val;
	  break;
	case 'X':
#ifdef _NL_CURRENT
	  if (*decided != raw)
	    {
	      if (!recursive (_NL_CURRENT (LC_TIME, T_FMT)))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (strcmp (_NL_CURRENT (LC_TIME, T_FMT), HERE_T_FMT))
		    *decided = loc;
		  break;
		}
	      *decided = raw;
	    }
#elif defined (G_OS_WIN32)
	  if (*decided != raw)
	    {
	      const gchar *picture;
	      const gchar *posix_t_fmt;

	      picture = get_locale_string (LOCALE_STIMEFORMAT);
	      posix_t_fmt = translate_picture (picture);

	      if (!recursive (posix_t_fmt))
		{
		  if (*decided == loc)
		    return NULL;
		  else
		    rp = rp_backup;
		}
	      else
		{
		  if (strcmp (posix_t_fmt, HERE_T_FMT))
		    *decided = loc;
		  break;
		}
	      *decided = raw;
	    }
#endif
	  /* Fall through.  */
	case 'T':
	  if (!recursive (HERE_T_FMT))
	    return NULL;
	  break;
	case 'u':
	  get_number (1, 7, 1);
	  tm->tm_wday = val % 7;
	  have_wday = 1;
	  break;
	case 'g':
	  get_number (0, 99, 2);
	  /* XXX This cannot determine any field in TM.  */
	  break;
	case 'G':
	  if (*rp < '0' || *rp > '9')
	    return NULL;
	  /* XXX Ignore the number since we would need some more
	     information to compute a real date.  */
	  do
	    ++rp;
	  while (*rp >= '0' && *rp <= '9');
	  break;
	case 'U':
	  get_number (0, 53, 2);
	  week_no = val;
	  have_uweek = 1;
	  break;
	case 'W':
	  get_number (0, 53, 2);
	  week_no = val;
	  have_wweek = 1;
	  break;
	case 'V':
	  get_number (0, 53, 2);
	  /* XXX This cannot determine any field in TM without some
	     information.  */
	  break;
	case 'w':
	  /* Match number of weekday.  */
	  get_number (0, 6, 1);
	  tm->tm_wday = val;
	  have_wday = 1;
	  break;
	case 'y':
#ifdef _NL_CURRENT
	match_year_in_century:
#endif
	  /* Match year within century.  */
	  get_number (0, 99, 2);
	  /* The "Year 2000: The Millennium Rollover" paper suggests that
	   * values in the range 69-99 refer to the twentieth century.  */
	  tm->tm_year = val >= 69 ? val : val + 100;
	  /* Indicate that we want to use the century, if specified.  */
	  want_century = 1;
	  want_xday = 1;
	  break;
	case 'Y':
	  /* Match year including century number.  */
	  get_number (0, 9999, 4);
	  tm->tm_year = val - 1900;
	  want_century = 0;
	  want_xday = 1;
	  break;
	case 'Z':
	  /* XXX How to handle this?  */
	  break;
	case 'E':
#ifdef _NL_CURRENT
	  switch (*fmt++)
	    {
	    case 'c':
	      /* Match locale's alternate date and time format.  */
	      if (*decided != raw)
		{
		  const gchar *fmt = _NL_CURRENT (LC_TIME, ERA_D_T_FMT);

		  if (*fmt == '\0')
		    fmt = _NL_CURRENT (LC_TIME, D_T_FMT);

		  if (!recursive (fmt))
		    {
		      if (*decided == loc)
			return NULL;
		      else
			rp = rp_backup;
		    }
		  else
		    {
		      if (strcmp (fmt, HERE_D_T_FMT))
			*decided = loc;
		      want_xday = 1;
		      break;
		    }
		  *decided = raw;
		}
	      /* The C locale has no era information, so use the
		 normal representation.  */
	      if (!recursive (HERE_D_T_FMT))
		return NULL;
	      want_xday = 1;
	      break;
	    case 'C':
	      if (*decided != raw)
		{
		  if (era_cnt >= 0)
		    {
		      era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
		      if (era != NULL && match_string (era->era_name, rp))
			{
			  *decided = loc;
			  break;
			}
		      else
			return NULL;
		    }

		  num_eras = _NL_CURRENT_WORD (LC_TIME, _NL_TIME_ERA_NUM_ENTRIES);
		  for (era_cnt = 0; era_cnt < (gint) num_eras;
		       ++era_cnt, rp = rp_backup)
		    {
			era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
		      if (era != NULL && match_string (era->era_name, rp))
			{
			  *decided = loc;
			  break;
			}
		    }
		  if (era_cnt != (gint) num_eras)
		    break;

		  era_cnt = -1;
		  if (*decided == loc)
		    return NULL;

		  *decided = raw;
		}
	      /* The C locale has no era information, so use the
		 normal representation.  */
	      goto match_century;
	    case 'y':
	      if (*decided != raw)
		{
		  get_number (0, 9999, 4);
		  tm->tm_year = val;
		  want_era = 1;
		  want_xday = 1;
		  want_century = 1;

		  if (era_cnt >= 0)
		    {
		      assert (*decided == loc);

		      era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
		      gint match = FALSE;
		      if (era != NULL)
			{
			  gint delta = ((tm->tm_year - era->offset)
				       * era->absolute_direction);
			  match = (delta >= 0
				   && delta < (((int64_t) era->stop_date[0]
						- (int64_t) era->start_date[0])
					       * era->absolute_direction));
			}
		      if (!match)
			return NULL;

		      break;
		    }

		  num_eras = _NL_CURRENT_WORD (LC_TIME, _NL_TIME_ERA_NUM_ENTRIES);
		  for (era_cnt = 0; era_cnt < (gint) num_eras; ++era_cnt)
		    {
		      era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
		      if (era != NULL)
			{
			  gint delta = ((tm->tm_year - era->offset)
				       * era->absolute_direction);
			  if (delta >= 0
			      && delta < (((int64_t) era->stop_date[0]
					   - (int64_t) era->start_date[0])
					  * era->absolute_direction))
			    {
			      *decided = loc;
			      break;
			    }
			}
		    }
		  if (era_cnt != (gint) num_eras)
		    break;

		  era_cnt = -1;
		  if (*decided == loc)
		    return NULL;

		  *decided = raw;
		}

	      goto match_year_in_century;
	    case 'Y':
	      if (*decided != raw)
		{
			num_eras = _NL_CURRENT_WORD (
			LC_TIME,
			_NL_TIME_ERA_NUM_ENTRIES);
		  for (era_cnt = 0; era_cnt < (gint) num_eras;
		       ++era_cnt, rp = rp_backup)
		    {
		      era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
		      if (era != NULL && recursive (era->era_format))
			break;
		    }
		  if (era_cnt == (gint) num_eras)
		    {
		      era_cnt = -1;
		      if (*decided == loc)
			return NULL;
		      else
			rp = rp_backup;
		    }
		  else
		    {
		      *decided = loc;
		      era_cnt = -1;
		      break;
		    }

		  *decided = raw;
		}
	      get_number (0, 9999, 4);
	      tm->tm_year = val - 1900;
	      want_century = 0;
	      want_xday = 1;
	      break;
	    case 'x':
	      if (*decided != raw)
		{
		  const gchar *fmt = _NL_CURRENT (LC_TIME, ERA_D_FMT);

		  if (*fmt == '\0')
		    fmt = _NL_CURRENT (LC_TIME, D_FMT);

		  if (!recursive (fmt))
		    {
		      if (*decided == loc)
			return NULL;
		      else
			rp = rp_backup;
		    }
		  else
		    {
		      if (strcmp (fmt, HERE_D_FMT))
			*decided = loc;
		      break;
		    }
		  *decided = raw;
		}
	      if (!recursive (HERE_D_FMT))
		return NULL;
	      break;
	    case 'X':
	      if (*decided != raw)
		{
		  const gchar *fmt = _NL_CURRENT (LC_TIME, ERA_T_FMT);

		  if (*fmt == '\0')
		    fmt = _NL_CURRENT (LC_TIME, T_FMT);

		  if (!recursive (fmt))
		    {
		      if (*decided == loc)
			return NULL;
		      else
			rp = rp_backup;
		    }
		  else
		    {
		      if (strcmp (fmt, HERE_T_FMT))
			*decided = loc;
		      break;
		    }
		  *decided = raw;
		}
	      if (!recursive (HERE_T_FMT))
		return NULL;
	      break;
	    default:
	      return NULL;
	    }
	  break;
#else
	  /* We have no information about the era format.  Just use
	     the normal format.  */
	  if (*fmt != 'c' && *fmt != 'C' && *fmt != 'y' && *fmt != 'Y'
	      && *fmt != 'x' && *fmt != 'X')
	    /* This is an illegal format.  */
	    return NULL;

	  goto start_over;
#endif
	case 'O':
	  switch (*fmt++)
	    {
	    case 'd':
	    case 'e':
	      /* Match day of month using alternate numeric symbols.  */
	      get_alt_number (1, 31, 2);
	      tm->tm_mday = val;
	      have_mday = 1;
	      want_xday = 1;
	      break;
	    case 'H':
	      /* Match hour in 24-hour clock using alternate numeric
		 symbols.  */
	      get_alt_number (0, 23, 2);
	      tm->tm_hour = val;
	      have_I = 0;
	      break;
	    case 'I':
	      /* Match hour in 12-hour clock using alternate numeric
		 symbols.  */
	      get_alt_number (1, 12, 2);
	      tm->tm_hour = val % 12;
	      have_I = 1;
	      break;
	    case 'm':
	      /* Match month using alternate numeric symbols.  */
	      get_alt_number (1, 12, 2);
	      tm->tm_mon = val - 1;
	      have_mon = 1;
	      want_xday = 1;
	      break;
	    case 'M':
	      /* Match minutes using alternate numeric symbols.  */
	      get_alt_number (0, 59, 2);
	      tm->tm_min = val;
	      break;
	    case 'S':
	      /* Match seconds using alternate numeric symbols.  */
	      get_alt_number (0, 61, 2);
	      tm->tm_sec = val;
	      break;
	    case 'U':
	      get_alt_number (0, 53, 2);
	      week_no = val;
	      have_uweek = 1;
	      break;
	    case 'W':
	      get_alt_number (0, 53, 2);
	      week_no = val;
	      have_wweek = 1;
	      break;
	    case 'V':
	      get_alt_number (0, 53, 2);
	      /* XXX This cannot determine any field in TM without
		 further information.  */
	      break;
	    case 'w':
	      /* Match number of weekday using alternate numeric symbols.  */
	      get_alt_number (0, 6, 1);
	      tm->tm_wday = val;
	      have_wday = 1;
	      break;
	    case 'y':
	      /* Match year within century using alternate numeric symbols.  */
	      get_alt_number (0, 99, 2);
	      tm->tm_year = val >= 69 ? val : val + 100;
	      want_xday = 1;
	      break;
	    default:
	      return NULL;
	    }
	  break;
	default:
	  return NULL;
	}
    }

  if (have_I && is_pm)
    tm->tm_hour += 12;

  if (century != -1)
    {
      if (want_century)
	tm->tm_year = tm->tm_year % 100 + (century - 19) * 100;
      else
	/* Only the century, but not the year.  Strange, but so be it.  */
	tm->tm_year = (century - 19) * 100;
    }

#ifdef _NL_CURRENT
  if (era_cnt != -1)
    {
      era = _nl_select_era_entry (era_cnt HELPER_LOCALE_ARG);
      if (era == NULL)
	return NULL;
      if (want_era)
	tm->tm_year = (era->start_date[0]
		       + ((tm->tm_year - era->offset)
			  * era->absolute_direction));
      else
	/* Era start year assumed.  */
	tm->tm_year = era->start_date[0];
    }
  else
#endif
    if (want_era)
      {
	/* No era found but we have seen an E modifier.  Rectify some
	 * values.  */
	if (want_century && century == -1 && tm->tm_year < 69)
	  tm->tm_year += 100;
      }

  if (want_xday && !have_wday)
    {
      if ( !(have_mon && have_mday) && have_yday)
	{
	  /* We don't have tm_mon and/or tm_mday, compute them.  */
	  gint t_mon = 0;
	  while (__mon_yday[__isleap (1900 + tm->tm_year)][t_mon] <= tm->tm_yday)
	      t_mon++;
	  if (!have_mon)
	      tm->tm_mon = t_mon - 1;
	  if (!have_mday)
	      tm->tm_mday =
		(tm->tm_yday
		 - __mon_yday[__isleap (1900 + tm->tm_year)][t_mon - 1] + 1);
	}
      day_of_the_week (tm);
    }

  if (want_xday && !have_yday)
    day_of_the_year (tm);

  if ((have_uweek || have_wweek) && have_wday)
    {
      gint save_wday = tm->tm_wday;
      gint save_mday = tm->tm_mday;
      gint save_mon = tm->tm_mon;
      gint w_offset = have_uweek ? 0 : 1;

      tm->tm_mday = 1;
      tm->tm_mon = 0;
      day_of_the_week (tm);
      if (have_mday)
	tm->tm_mday = save_mday;
      if (have_mon)
	tm->tm_mon = save_mon;

      if (!have_yday)
	tm->tm_yday = ((7 - (tm->tm_wday - w_offset)) % 7
		       + (week_no - 1) *7
		       + save_wday - w_offset);

      if (!have_mday || !have_mon)
	{
	  gint t_mon = 0;
	  while (__mon_yday[__isleap (1900 + tm->tm_year)][t_mon]
		 <= tm->tm_yday)
	    t_mon++;
	  if (!have_mon)
	    tm->tm_mon = t_mon - 1;
	  if (!have_mday)
	      tm->tm_mday =
		(tm->tm_yday
		 - __mon_yday[__isleap (1900 + tm->tm_year)][t_mon - 1] + 1);
	}

      tm->tm_wday = save_wday;
    }

  return (gchar *) rp;
}

static gchar *
strptime (buf,
          format,
          tm LOCALE_PARAM)
     const gchar *buf;
     const gchar *format;
     struct tm *tm;
     LOCALE_PARAM_DECL
{
  enum ptime_locale_status decided;

#ifdef _NL_CURRENT
  decided = not;
#elif defined (G_OS_WIN32)
  decided = not;
#else
  decided = raw;
#endif
  return __strptime_internal (buf, format, tm, &decided, -1 LOCALE_ARG);
}

#ifdef _LIBC
weak_alias (__strptime_l,
            strptime_l)
#endif
#endif	/* HAVE_STRPTIME */

/* Returns whether a string is NULL, empty, or full of whitespace */
static gboolean
string_is_empty (const gchar *value)
{
	const gchar *p;
	gboolean empty = TRUE;

	if (value) {
		p = value;
		while (*p) {
			if (!isspace (*p)) {
				empty = FALSE;
				break;
			}
			p++;
		}
	}
	return empty;
}

/* Takes a number of format strings for strptime() and attempts to parse a
 * string with them.
 */
static ETimeParseStatus
parse_with_strptime (const gchar *value,
                     struct tm *result,
                     const gchar **formats,
                     gint n_formats)
{
	const gchar *parse_end = NULL, *pos;
	gchar *locale_str;
	gchar *format_str;
	ETimeParseStatus parse_ret;
	gint i, n;

	if (string_is_empty (value)) {
		memset (result, 0, sizeof (*result));
		result->tm_isdst = -1;
		return E_TIME_PARSE_NONE;
	}

	parse_ret = E_TIME_PARSE_INVALID;
	locale_str = g_locale_from_utf8 (value, -1, NULL, NULL, NULL);
	pos = (const gchar *) locale_str;

	if (!locale_str)
		return E_TIME_PARSE_INVALID;

	/* Skip whitespace */
	while (n = (gint)((guchar) * pos), isspace (n) != 0)
		pos++;

	/* Try each of the formats in turn */

	for (i = 0; i < n_formats; i++) {
		memset (result, 0, sizeof (*result));
		format_str = g_locale_from_utf8 (formats[i], -1, NULL, NULL, NULL);
		parse_end = strptime (pos, format_str, result);
		g_free (format_str);
		if (parse_end) {
			/* If we parsed something, make sure we parsed the entire string. */
			/* Skip whitespace */
			while (isspace (*parse_end))
				parse_end++;

			if (*parse_end == '\0') {
				parse_ret = E_TIME_PARSE_OK;
				break;
			}
		}
	}

	result->tm_isdst = -1;

	g_free (locale_str);

	return (parse_ret);

}

static void
correct_two_digit_year (struct tm *result,
                        gboolean *two_digit_year)
{
	g_return_if_fail (result != NULL);

	if (two_digit_year)
		*two_digit_year = FALSE;

	/* If a 2-digit year was used we use the current century. */
	if (result->tm_year < 0 && result->tm_year < -1800) {
		time_t t = time (NULL);
		struct tm *today_tm = localtime (&t);

		/* This should convert it into a value from 0 to 99. */
		result->tm_year += 1900;

		/* Now add on the century. */
		result->tm_year += today_tm->tm_year
			- (today_tm->tm_year % 100);

		if (two_digit_year)
			*two_digit_year = TRUE;
	}
}

/* Returns TRUE if the locale has 'am' and 'pm' strings defined, in which
 * case the user can choose between 12 and 24-hour time formats. */
static gboolean
locale_supports_12_hour_format (void)
{
	struct tm tmp_tm = { 0 };
	gchar s[40];

	/* Fill the struct tm with some sane values. */
	tmp_tm.tm_year = 2000;
	tmp_tm.tm_mon = 0;
	tmp_tm.tm_mday = 1;
	tmp_tm.tm_sec = 0;
	tmp_tm.tm_isdst = 0;
	tmp_tm.tm_hour = 1;
	tmp_tm.tm_min = 0;
	tmp_tm.tm_wday = 6;
	tmp_tm.tm_yday = 6;

	e_utf8_strftime (s, sizeof (s), "%p", &tmp_tm);

	if (!s[0]) {
		tmp_tm.tm_hour = 13;
		tmp_tm.tm_min = 0;

		e_utf8_strftime (s, sizeof (s), "%p", &tmp_tm);
	}

	return s[0] != '\0';
}

static gboolean
has_correct_date (const struct tm *value)
{
	const gint days_in_month[12] = {
		31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
	gint days, year;

	g_return_val_if_fail (value != NULL, FALSE);
	g_return_val_if_fail (value->tm_mon >= 0 && value->tm_mon < 12, FALSE);

	year = value->tm_year + 1900;
	days = days_in_month[value->tm_mon];
	if (value->tm_mon == 1 &&
		((year <= 1752) ? (!(year % 4)) :
		((!(year % 4) && (year % 100)) || !(year % 400))))
		days++;

	return value->tm_mday >= 1 && value->tm_mday <= days;
}

/**
 * e_time_parse_date_and_time_ex:
 * @value: The string to parse a date and time from.
 * @result: A #tm to store the result in.
 * @two_digit_year: set to TRUE, is parsing with two-digit year, else FALSE,
 *    but only when not NULL.
 *
 * Parses a string @value containing a date and a time and stores the
 * result in @result. The date in @value is expected to be in a format
 * like "Wed 3/13/00 14:20:00", though gettext() is used to support the
 * appropriate local formats. There is also some leniency on the
 * format of the string, e.g. the weekday can be skipped or 12-hour
 * formats with am/pm can be used.
 *
 * Returns: E_TIME_PARSE_OK if the string was successfully parsed,
 *          E_TIME_PARSE_NONE if the string was empty, or
 *          E_TIME_PARSE_INVALID if the string could not be parsed.
 *
 * Since: 2.22
 */
ETimeParseStatus
e_time_parse_date_and_time_ex (const gchar *value,
                               struct tm *result,
                               gboolean *two_digit_year)
{
	struct tm *today_tm;
	time_t t;
	const gchar *format[16];
	gint num_formats = 0;
	gboolean use_12_hour_formats = locale_supports_12_hour_format ();
	ETimeParseStatus status;

	if (string_is_empty (value)) {
		memset (result, 0, sizeof (*result));
		result->tm_isdst = -1;
		return E_TIME_PARSE_NONE;
	}

	/* We'll parse the whole date and time in one go, otherwise we get
	 * into i18n problems. We attempt to parse with several formats,
	 * longest first. Note that we only use the '%p' specifier if the
	 * locale actually has 'am' and 'pm' strings defined, otherwise we
	 * will get incorrect results. Note also that we try to use exactly
	 * the same strings as in e_time_format_date_and_time (), to try to
	 * avoid i18n problems. We also use cut-down versions, so users don't
	 * have to type in the weekday or the seconds, for example.
	 * Note that all these formats include the full date, and the time
	 * will be set to 00:00:00 before parsing, so we don't need to worry
	 * about filling in any missing fields after parsing. */

	/*
	 * Try the full times, with the weekday. Then try without seconds,
	 * and without minutes, and finally with no time at all.
	 */
	if (use_12_hour_formats) {
		/* strptime format of a weekday, a date and a time,
		 * in 12-hour format. */
		format[num_formats++] = _("%a %m/%d/%Y %I:%M:%S %p");
	}

	/* strptime format of a weekday, a date and a time,
	 * in 24-hour format. */
	format[num_formats++] = _("%a %m/%d/%Y %H:%M:%S");

	if (use_12_hour_formats) {
		/* strptime format of a weekday, a date and a time,
		 * in 12-hour format, without seconds. */
		format[num_formats++] = _("%a %m/%d/%Y %I:%M %p");
	}

	/* strptime format of a weekday, a date and a time,
	 * in 24-hour format, without seconds. */
	format[num_formats++] = _("%a %m/%d/%Y %H:%M");

	if (use_12_hour_formats) {
		/* strptime format of a weekday, a date and a time,
		 * in 12-hour format, without minutes or seconds. */
		format[num_formats++] = _("%a %m/%d/%Y %I %p");
	}

	/* strptime format of a weekday, a date and a time,
	 * in 24-hour format, without minutes or seconds. */
	format[num_formats++] = _("%a %m/%d/%Y %H");

	/* strptime format of a weekday and a date. */
	format[num_formats++] = _("%a %m/%d/%Y");

	/*
	 * Now try all the above formats again, but without the weekday.
	 */
	if (use_12_hour_formats) {
		/* strptime format of a date and a time, in 12-hour format. */
		format[num_formats++] = _("%m/%d/%Y %I:%M:%S %p");
	}

	/* strptime format of a date and a time, in 24-hour format. */
	format[num_formats++] = _("%m/%d/%Y %H:%M:%S");

	if (use_12_hour_formats) {
		/* strptime format of a date and a time, in 12-hour format,
		 * without seconds. */
		format[num_formats++] = _("%m/%d/%Y %I:%M %p");
	}

	/* strptime format of a date and a time, in 24-hour format,
	 * without seconds. */
	format[num_formats++] = _("%m/%d/%Y %H:%M");

	if (use_12_hour_formats) {
		/* strptime format of a date and a time, in 12-hour format,
		 * without minutes or seconds. */
		format[num_formats++] = _("%m/%d/%Y %I %p");
	}

	/* strptime format of a date and a time, in 24-hour format,
	 * without minutes or seconds. */
	format[num_formats++] = _("%m/%d/%Y %H");

	/* strptime format of a weekday and a date. */
	format[num_formats++] = _("%m/%d/%Y");

	if (two_digit_year)
		*two_digit_year = FALSE;

	status = parse_with_strptime (value, result, format, num_formats);

	if (status == E_TIME_PARSE_OK && !has_correct_date (result))
		status = E_TIME_PARSE_INVALID;

	/* Note that we checked if it was empty already, so it is either OK
	 * or INVALID here. */
	if (status == E_TIME_PARSE_OK) {
		correct_two_digit_year (result, two_digit_year);
	} else {
		/* Now we try to just parse a time, assuming the current day.*/
		status = e_time_parse_time (value, result);
		if (status == E_TIME_PARSE_OK) {
			/* We fill in the current day. */
			t = time (NULL);
			today_tm = localtime (&t);
			result->tm_mday = today_tm->tm_mday;
			result->tm_mon = today_tm->tm_mon;
			result->tm_year = today_tm->tm_year;
		}
	}

	return status;
}

/**
 * e_time_parse_date_and_time:
 * @value: the string to parse a date and time from
 * @result: a #tm to store the result in
 *
 * Parses a string @value containing a date and a time and stores the
 * result in @result. The date in @value is expected to be in a format
 * like "Wed 3/13/00 14:20:00", though gettext() is used to support the
 * appropriate local formats. There is also some leniency on the
 * format of the string, e.g. the weekday can be skipped or 12-hour
 * formats with am/pm can be used.
 *
 * Returns: E_TIME_PARSE_OK if the string was successfully parsed,
 *          E_TIME_PARSE_NONE if the string was empty, or
 *          E_TIME_PARSE_INVALID if the string could not be parsed.
 */
ETimeParseStatus
e_time_parse_date_and_time (const gchar *value,
                            struct tm *result)
{
	return e_time_parse_date_and_time_ex (value, result, NULL);
}

/**
 * e_time_parse_date_ex:
 * @value: A date string.
 * @result: Return value for the parsed date.
 * @two_digit_year: set to TRUE, is parsing with two-digit year, else FALSE,
 *    but only when not NULL.
 *
 * Takes in a date string entered by the user and tries to convert it to
 * a struct #tm.
 *
 * Returns: An #ETimeParseStatus result code indicating whether
 * @value was an empty string, a valid date, or an invalid date.
 *
 * Since: 2.22
 **/
ETimeParseStatus
e_time_parse_date_ex (const gchar *value,
                      struct tm *result,
                      gboolean *two_digit_year)
{
	const gchar *format[4];
	ETimeParseStatus status;

	g_return_val_if_fail (value != NULL, E_TIME_PARSE_INVALID);
	g_return_val_if_fail (result != NULL, E_TIME_PARSE_INVALID);

	/* according to the current locale */
	format[0] = ("%x");

	/* according to the current locale with forced 4-digit year*/
	format[1] = e_time_get_d_fmt_with_4digit_year ();

	/* strptime format of a weekday and a date. */
	format[2] = _("%a %m/%d/%Y");

	/* This is the preferred date format for the locale. */
	format[3] = _("%m/%d/%Y");

	if (two_digit_year) {
		/* when we need to know about two digit year, then always first try
		 * full year, because for example nl_NL have format %d-%m-%y and it
		 * changes from two year itself, which isn't what we want */
		const gchar *tmp = format[1];
		format[1] = format[0];
		format[0] = tmp;
		*two_digit_year = FALSE;
	}

	status = parse_with_strptime (value, result, format, G_N_ELEMENTS (format));

	if (status == E_TIME_PARSE_OK && !has_correct_date (result))
		status = E_TIME_PARSE_INVALID;

	if (status == E_TIME_PARSE_OK) {
		correct_two_digit_year (result, two_digit_year);
	}

	if (two_digit_year)
		g_free ((gchar *) format[0]);
	else
		g_free ((gchar *) format[1]);

	return status;
}

/**
 * e_time_parse_date:
 * @value: A date string.
 * @result: Return value for the parsed date.
 *
 * Takes in a date string entered by the user and tries to convert it to
 * a struct #tm.
 *
 * Returns: An #ETimeParseStatus result code indicating whether
 * @value was an empty string, a valid date, or an invalid date.
 **/
ETimeParseStatus
e_time_parse_date (const gchar *value,
                   struct tm *result)
{
	return e_time_parse_date_ex (value, result, NULL);
}

/**
 * e_time_parse_time:
 * @value: The string to parse a time from.
 * @result: A #tm to store the result in.
 *
 * Parses @value, a string containing a time. @value is expected to be
 * in a format like "14:20:00". gettext() is used to
 * support the appropriate local formats and slightly
 * different formats, such as 12-hour formats with am/pm,
 * are accepted as well.
 *
 * Returns: An #ETimeParseStatus result code indicating whether
 * @value was an empty string, a valid date, or an invalid date.
 **/
ETimeParseStatus
e_time_parse_time (const gchar *value,
                   struct tm *result)
{
	const gchar *format[7];
	gint num_formats = 0;
	gboolean use_12_hour_formats = locale_supports_12_hour_format ();

	if (use_12_hour_formats) {
		/* strptime format for a time of day, in 12-hour format. */
		format[num_formats++] = _("%I:%M:%S %p");
	}

	/* strptime format for a time of day, in 24-hour format. */
	format[num_formats++] = _("%H:%M:%S");

	if (use_12_hour_formats) {
		/* strptime format for time of day, without seconds,
		 * in 12-hour format. */
		format[num_formats++] = _("%I:%M %p");
	}

	/* strptime format for time of day, without seconds 24-hour format. */
	format[num_formats++] = _("%H:%M");

	/* strptime format for time of day, without seconds 24-hour format,
	 * and no colon. */
	format[num_formats++] = _("%H%M");

	if (use_12_hour_formats) {
		/* strptime format for hour and AM/PM, 12-hour format. */
		format[num_formats++] = _("%I %p");
	}

	/* strptime format for hour, 24-hour format. */
	format[num_formats++] = "%H";

	return parse_with_strptime (value, result, format, num_formats);
}

/**
 * e_time_format_date_and_time:
 * @date_tm: The #tm to convert to a string.
 * @use_24_hour_format: A #gboolean.
 * @show_midnight: A #gboolean.
 * @show_zero_seconds: A #gboolean.
 * @buffer: A #char buffer to store the time string in.
 * @buffer_size: The length of @buffer.
 *
 * Creates a string representation of the time value @date_tm and
 * stores it in @buffer.  @buffer_size should be at least 64 to be
 * safe. If @show_midnight is %FALSE, and the time is midnight, then
 * only the date is stored in @buffer. If @show_zero_seconds is
 * %FALSE, then if the time has zero seconds only the hour and minute
 * of the time are stored in @buffer.
 **/
void
e_time_format_date_and_time (struct tm *date_tm,
                             gboolean use_24_hour_format,
                             gboolean show_midnight,
                             gboolean show_zero_seconds,
                             gchar *buffer,
                             gint buffer_size)
{
	gchar *format;

	if (!show_midnight && date_tm->tm_hour == 0
	    && date_tm->tm_min == 0 && date_tm->tm_sec == 0) {
		/* strftime format of a weekday and a date. */
		format = _("%a %m/%d/%Y");
	} else if (use_24_hour_format) {
		if (!show_zero_seconds && date_tm->tm_sec == 0)
			/* strftime format of a weekday, a date and a
			 * time, in 24-hour format, without seconds. */
			format = _("%a %m/%d/%Y %H:%M");
		else
			/* strftime format of a weekday, a date and a
			 * time, in 24-hour format. */
			format = _("%a %m/%d/%Y %H:%M:%S");
	} else {
		if (!show_zero_seconds && date_tm->tm_sec == 0)
			/* strftime format of a weekday, a date and a
			 * time, in 12-hour format, without seconds. */
			format = _("%a %m/%d/%Y %I:%M %p");
		else
			/* strftime format of a weekday, a date and a
			 * time, in 12-hour format. */
			format = _("%a %m/%d/%Y %I:%M:%S %p");
	}

	/* strftime returns 0 if the string doesn't fit, and leaves the buffer
	 * undefined, so we set it to the empty string in that case. */
	if (e_utf8_strftime (buffer, buffer_size, format, date_tm) == 0)
		buffer[0] = '\0';
}

/**
 * e_time_format_time:
 * @date_tm: The #tm to convert to a string.
 * @use_24_hour_format: A #gboolean.
 * @show_zero_seconds: A #gboolean.
 * @buffer: The #char buffer to store the result in.
 * @buffer_size: The length of @buffer.
 *
 * Creates a string representation of a time value in @date_tm and
 * stores it in @buffer. @buffer_size should be at least 64.
 **/
void
e_time_format_time (struct tm *date_tm,
                    gboolean use_24_hour_format,
                    gboolean show_zero_seconds,
                    gchar *buffer,
                    gint buffer_size)
{
	gchar *format;

	if (use_24_hour_format) {
		if (!show_zero_seconds && date_tm->tm_sec == 0)
			/* strftime format of a time in 24-hour format,
			 * without seconds. */
			format = _("%H:%M");
		else
			/* strftime format of a time in 24-hour format. */
			format = _("%H:%M:%S");
	} else {
		if (!show_zero_seconds && date_tm->tm_sec == 0)
			/* strftime format of a time in 12-hour format,
			 * without seconds. */
			format = _("%I:%M %p");
		else
			/* strftime format of a time in 12-hour format. */
			format = _("%I:%M:%S %p");
	}

	/* strftime returns 0 if the string doesn't fit, and leaves the buffer
	 * undefined, so we set it to the empty string in that case. */
	if (e_utf8_strftime (buffer, buffer_size, format, date_tm) == 0)
		buffer[0] = '\0';
}

/**
 * e_mktime_utc:
 * @tm: The #tm to convert to a calendar time representation.
 *
 * Like mktime(3), but assumes UTC instead of local timezone.
 *
 * Returns: The calendar time representation of @tm.
 **/
time_t
e_mktime_utc (struct tm *tm)
{
	time_t tt;

	tm->tm_isdst = -1;
	tt = mktime (tm);

#if defined (HAVE_TM_GMTOFF)
	tt += tm->tm_gmtoff;
#elif defined (HAVE_TIMEZONE)
	if (tm->tm_isdst > 0) {
  #if defined (HAVE_ALTZONE)
		tt -= altzone;
  #else /* !defined (HAVE_ALTZONE) */
		tt -= (timezone - 3600);
  #endif
	} else
		tt -= timezone;
#endif

	return tt;
}

/**
 * e_localtime_with_offset:
 * @tt: The #time_t to convert.
 * @tm: The #tm to store the result in.
 * @offset: The #int to store the offset in.
 *
 * Converts the calendar time time representation @tt to a broken-down
 * time representation, store in @tm, and provides the offset in
 * seconds from UTC time, stored in @offset.
 **/
void
e_localtime_with_offset (time_t tt,
                         struct tm *tm,
                         gint *offset)
{
	localtime_r (&tt, tm);

#if defined (HAVE_TM_GMTOFF)
	*offset = tm->tm_gmtoff;
#elif defined (HAVE_TIMEZONE)
	if (tm->tm_isdst > 0) {
  #if defined (HAVE_ALTZONE)
		*offset = -altzone;
  #else /* !defined (HAVE_ALTZONE) */
		*offset = -(timezone - 3600);
  #endif
	} else
		*offset = -timezone;
#endif
}

#ifdef G_OS_WIN32
static gint _e_string_replace (gchar **str, const gchar *old, const gchar *new)
{
	GRegex *my_regex = g_regex_new (old, 0, 0, NULL);
	gchar *buf = *str;
	*str = g_regex_replace(my_regex, buf, -1, 0, new, 0, NULL);
	g_free (buf);
	g_regex_unref (my_regex);
    return 0;
}
#endif

/**
 * e_time_get_d_fmt_with_4digit_year:
 *
 * Retrieves a date format string with a 4-digit year (D_FMT on systems with
 * nl_langinfo() available). In case the current locale doesn't support 4-digit
 * year, the function returns format as specified by the locale.
 *
 * Free the returned string with g_free().
 *
 * Returns: a newly-allocated date format string
 *
 * Since: 2.22
 **/
gchar *
e_time_get_d_fmt_with_4digit_year (void)
{
	gchar *p;
	gchar *res = NULL;
#if defined(HAVE_NL_LANGINFO)
	res = g_strdup (nl_langinfo (D_FMT) );
#elif defined(G_OS_WIN32)
#define GET_LOCALE_INFO(str, len) \
	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SLONGDATE, str, len)
	gint format_string_length = GET_LOCALE_INFO (NULL, 0);
	if (format_string_length > 0) {
		gsize format_bytes_read;
		gsize format_bytes_written;
		gchar *format_string;

		format_string = g_strnfill (format_string_length + 1, '\0');
		GET_LOCALE_INFO (format_string, format_string_length);
		res = g_locale_to_utf8 (
			format_string,
			format_string_length,
			&format_bytes_read,
			&format_bytes_written,
			NULL);
		g_free (format_string);

		/* now, convert the res to format of nl_langinfo */
		_e_string_replace (&res, "\\bd\\b", "%#d");	/* d -> %#d */
		_e_string_replace (&res, "\\bdd\\b", "%d");	/* dd -> %d */
		_e_string_replace (&res, "\\bddd\\b", "%a");	/* ddd -> %a */
		_e_string_replace (&res, "\\bdddd\\b", "%A");	/* dddd -> %A */
		_e_string_replace (&res, "\\bM\\b", "%#m");	/* M -> %#m */
		_e_string_replace (&res, "\\bMM\\b", "%m");	/* MM -> %m */
		_e_string_replace (&res, "\\bMMM\\b", "%b");	/* MMM -> %b */
		_e_string_replace (&res, "\\bMMMM\\b", "%B");	/* MMMM -> %B */
		_e_string_replace (&res, "\\by\\b", "%#y");	/* y -> %y */
		_e_string_replace (&res, "\\byy\\b", "%y");	/* yy -> %y */
		_e_string_replace (&res, "\\byyyy\\b", "%Y");	/* yyyy -> %Y */
		_e_string_replace (&res, "\\byyyyy\\b", "%Y");	/* yyyyy -> %Y */
	}
#undef GET_LOCALE_INFO
	/* TODO Implement this for other systems. */
#else
	/* This will not work for other systems. */
	res = g_strdup ("%x");
#endif

	for (p = res; p && *p; p++) {
		if (*p == 'y' && p != res && p[-1] == '%')
			*p = 'Y';
	}

	return res;
}

