/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Evolution calendar recurrence rule functions
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
 * Authors: Damon Chaplin <damon@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdlib.h>
#include <string.h>
#include <glib/gi18n-lib.h>

#include "e-cal-recur.h"
#include "e-cal-time-util.h"
#include "e-cal-client.h"

static gint
e_timetype_compare (gconstpointer a,
		    gconstpointer b)
{
	const struct icaltimetype *tta = a;
	const struct icaltimetype *ttb = b;

	if (!tta || !ttb) {
		if (tta == ttb)
			return 0;
		if (!tta)
			return -1;
		return 1;
	}

	if (tta->is_date || ttb->is_date)
		return icaltime_compare_date_only (*tta, *ttb);

	return icaltime_compare (*tta, *ttb);
}

static gint
e_timetype_compare_without_date (gconstpointer a,
				 gconstpointer b)
{
	const struct icaltimetype *tta = a;
	const struct icaltimetype *ttb = b;

	if (!tta || !ttb) {
		if (tta == ttb)
			return 0;
		if (!tta)
			return -1;
		return 1;
	}

	return icaltime_compare (*tta, *ttb);
}

static guint
e_timetype_hash (gconstpointer v)
{
	const struct icaltimetype *ttv = v;
	struct icaltimetype tt;

	if (!ttv)
		return 0;

	tt = icaltime_convert_to_zone (*ttv, icaltimezone_get_utc_timezone ());

	return g_int_hash (&(tt.year)) ^
		g_int_hash (&(tt.month)) ^
		g_int_hash (&(tt.day));
}

typedef struct _EInstanceTime
{
	struct icaltimetype tt;
	gboolean duration_set;
	gint duration_days;
	gint duration_seconds;
} EInstanceTime;

static EInstanceTime *
e_instance_time_new (const struct icaltimetype *tt,
		     const struct icaldurationtype *duration)
{
	EInstanceTime *it;

	if (!tt)
		return NULL;

	it = g_new0 (EInstanceTime, 1);

	it->tt = *tt;
	it->duration_set = duration && !icaldurationtype_is_null_duration (*duration);

	if (it->duration_set) {
		gint64 dur;

		g_warn_if_fail (!duration->is_neg);

		dur = (gint64) (duration->weeks * 7 + duration->days) * (24 * 60 * 60) +
			(duration->hours * 60 * 60) +
			(duration->minutes * 60) +
			duration->seconds;

		it->duration_days = dur / (24 * 60 * 60);
		it->duration_seconds = dur % (24 * 60 * 60);
	}

	return it;
}

static gint
e_instance_time_compare (gconstpointer a,
			 gconstpointer b)
{
	const EInstanceTime *ait = a;
	const EInstanceTime *bit = b;

	if (!ait || !bit) {
		if (ait == bit)
			return 0;

		if (!ait)
			return -1;

		return 1;
	}

	return e_timetype_compare (&(ait->tt), &(bit->tt));
}

static guint
e_instance_time_hash (gconstpointer v)
{
	const EInstanceTime *it = v;

	if (!it)
		return 0;

	return e_timetype_hash (&it->tt);
}

static gboolean
e_instance_time_equal (gconstpointer v1,
		       gconstpointer v2)
{
	return e_instance_time_compare (v1, v2) == 0;
}

static gint
e_instance_time_compare_ptr_array (gconstpointer a,
				   gconstpointer b)
{
	gconstpointer *aa = (gconstpointer *) a, *bb = (gconstpointer *) b;

	return e_instance_time_compare (*aa, *bb);
}

static gboolean
ensure_timezone (icalcomponent *comp,
		 struct icaltimetype *tt,
		 icalproperty_kind prop_kind,
		 icalproperty *prop,
		 ECalRecurResolveTimezoneCb get_tz_callback,
		 gpointer get_tz_callback_user_data,
		 icaltimezone *default_timezone,
		 GCancellable *cancellable,
		 GError **error)
{
	icalparameter *param;
	const gchar *tzid;
	GError *local_error = NULL;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	if (!tt)
		return TRUE;

	/* Do not trust the 'zone' set on the structure, as it can come from
	   a different icalcomponent and cause use-after-free. */
	if (tt->zone != icaltimezone_get_utc_timezone ())
		tt->zone = NULL;

	if (icaltime_is_utc (*tt))
		return TRUE;

	tt->zone = default_timezone;

	if (tt->is_date)
		return TRUE;

	if (!prop)
		prop = icalcomponent_get_first_property (comp, prop_kind);
	if (!prop)
		return TRUE;

	param = icalproperty_get_first_parameter (prop, ICAL_TZID_PARAMETER);
	if (!param)
		return TRUE;

	tzid = icalparameter_get_tzid (param);
	if (!tzid || !*tzid)
		return TRUE;

	if (get_tz_callback)
		tt->zone = get_tz_callback (tzid, get_tz_callback_user_data, cancellable, &local_error);
	else
		tt->zone = NULL;

	if (!tt->zone)
		tt->zone = default_timezone;

	/* Timezone not found is not a fatal error */
	if (g_error_matches (local_error, E_CAL_CLIENT_ERROR, E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND))
		g_clear_error (&local_error);

	if (local_error) {
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
apply_duration (struct icaltimetype *tt,
		const struct icaldurationtype *duration)
{
	gint64 days, seconds;

	g_return_if_fail (tt != NULL);
	g_return_if_fail (duration != NULL);

	if (icaldurationtype_is_null_duration (*duration))
		return;

	days = (gint64) duration->days + 7 * ((gint64) duration->weeks);
	seconds = ((gint64) duration->hours * 60 * 60) + ((gint64) duration->minutes * 60) + duration->seconds;
	days += seconds / (24 * 60 * 60);
	seconds = seconds % (24 * 60 * 60);

	if (seconds != 0) {
		tt->is_date = 0;
	}

	icaltime_adjust (tt,
		(duration->is_neg ? -1 : 1) * ((gint) days),
		0, 0,
		(duration->is_neg ? -1 : 1) * ((gint) seconds));
}

static gboolean
intersects_interval (const struct icaltimetype *tt,
		     const struct icaldurationtype *duration,
		     gint default_duration_days,
		     gint default_duration_seconds,
		     const struct icaltimetype *interval_start,
		     const struct icaltimetype *interval_end)
{
	struct icaltimetype ttstart, ttend;

	if (!tt || !interval_start || !interval_end)
		return FALSE;

	ttstart = *tt;
	ttend = ttstart;

	if (duration && !icaldurationtype_is_null_duration (*duration)) {
		apply_duration (&ttend, duration);
	} else if (default_duration_days || default_duration_seconds) {
		if (default_duration_seconds != 0) {
			ttend.is_date = 0;
		}

		icaltime_adjust (&ttend, default_duration_days, 0, 0, default_duration_seconds);
	}

	return e_timetype_compare_without_date (&ttstart, interval_end) < 0 &&
	       e_timetype_compare_without_date (interval_start, &ttend) < 0;
}

/**
 * e_cal_recur_generate_instances_sync:
 * @comp: an icalcomponent
 * @interval_start: an interval start, for which generate instances
 * @interval_end: an interval end, for which generate instances
 * @callback: (scope call): a callback to be called for each instance
 * @callback_user_data: (closure callback): user data for @callback
 * @get_tz_callback: (scope call): a callback to call when resolving timezone
 * @get_tz_callback_user_data: (closure get_tz_callback): user data for @get_tz_callback
 * @default_timezone: a default icaltimezone
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Calls the given callback function for each occurrence of the event that
 * intersects the range between the given @start and @end times (the end time is
 * not included). Note that the occurrences may start before the given start
 * time.
 *
 * If the callback routine returns FALSE the occurrence generation stops.
 *
 * The start and end times are required valid times, start before end time.
 *
 * The @get_tz_callback is used to resolve references to timezones. It is passed
 * a TZID and should return the icaltimezone * corresponding to that TZID. We need to
 * do this as we access timezones in different ways on the client & server.
 *
 * The default_timezone argument is used for DTSTART or DTEND properties that
 * are DATE values or do not have a TZID (i.e. floating times).
 *
 * Returns: %TRUE if successful (when all instances had been returned), %FALSE otherwise.
 *
 * Since: 3.20
 **/
gboolean
e_cal_recur_generate_instances_sync (icalcomponent *comp,
				     struct icaltimetype interval_start,
				     struct icaltimetype interval_end,
				     ECalRecurInstanceCb callback,
				     gpointer callback_user_data,
				     ECalRecurResolveTimezoneCb get_tz_callback,
				     gpointer get_tz_callback_user_data,
				     icaltimezone *default_timezone,
				     GCancellable *cancellable,
				     GError **error)
{
	struct icaltimetype dtstart, dtend, next;
	gint64 duration_days, duration_seconds;
	icalproperty *prop;
	GHashTable *times;
	gboolean success = TRUE;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (callback != NULL, FALSE);
	g_return_val_if_fail (icaltime_compare (interval_start, interval_end) < 0, FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	times = g_hash_table_new_full (e_instance_time_hash, e_instance_time_equal, g_free, NULL);

	dtstart = icalcomponent_get_dtstart (comp);
	success = ensure_timezone (comp, &dtstart, ICAL_DTSTART_PROPERTY, NULL,
		get_tz_callback, get_tz_callback_user_data, default_timezone, cancellable, error);

	duration_seconds = 0;
	dtend = icalcomponent_get_dtend (comp);

	if (icaltime_is_null_time (dtend)) {
		dtend = icalcomponent_get_due (comp);
		if (icaltime_is_null_time (dtend)) {
			struct icaldurationtype comp_duration;

			comp_duration = icalcomponent_get_duration (comp);

			if (!icaldurationtype_is_null_duration (comp_duration)) {
				dtend = dtstart;

				apply_duration (&dtend, &comp_duration);
			}
		}

		/* If there is no DTEND, then if DTSTART is a DATE-TIME value
		 * we use the same time (so we have a single point in time).
		 * If DTSTART is a DATE value we add 1 day. */
		if (icaltime_is_null_time (dtend)) {
			dtend = dtstart;

			if (dtend.is_date)
				icaltime_adjust (&dtend, 1, 0, 0, 0);
		}
	} else {
		/* If both DTSTART and DTEND are DATE values, and they are the
		 * same day, we add 1 day to DTEND. This means that most
		 * events created with the old Evolution behavior will still
		 * work OK. I'm not sure what Outlook does in this case. */
		if (dtstart.is_date && dtend.is_date) {
			if (icaltime_compare_date_only (dtstart, dtend) == 0) {
				icaltime_adjust (&dtend, 1, 0, 0, 0);
			}
		}
	}

	if (success && !icaltime_is_null_time (dtend)) {
		success = ensure_timezone (comp, &dtend, ICAL_DTEND_PROPERTY, NULL,
			get_tz_callback, get_tz_callback_user_data, default_timezone, cancellable, error);
		duration_seconds = (gint64) icaltime_as_timet_with_zone (dtend, dtend.zone) -
			(gint64) icaltime_as_timet_with_zone (dtstart, dtstart.zone);
		if (duration_seconds < 0)
			duration_seconds = 0;
	}

	duration_days = duration_seconds / (24 * 60 * 60);
	duration_seconds = duration_seconds % (24 * 60 * 60);

	if (success && intersects_interval (&dtstart, NULL, duration_days, duration_seconds, &interval_start, &interval_end)) {
		g_hash_table_insert (times, e_instance_time_new (&dtstart, NULL), NULL);
	}

	/* If this is a detached instance, then use only the DTSTART value */
	if (success && icaltime_is_null_time (icalcomponent_get_recurrenceid (comp))) {
		for (prop = icalcomponent_get_first_property (comp, ICAL_RRULE_PROPERTY);
		     prop && success;
		     prop = icalcomponent_get_next_property (comp, ICAL_RRULE_PROPERTY)) {
			struct icalrecurrencetype rrule = icalproperty_get_rrule (prop);
			icalrecur_iterator *riter;

			if (!icaltime_is_null_time (rrule.until)) {
				success = ensure_timezone (comp, &rrule.until, 0, prop,
					get_tz_callback, get_tz_callback_user_data, (icaltimezone *) dtstart.zone,
					cancellable, error);
				if (!success)
					break;
			}

			if (!icaltime_is_null_time (rrule.until) &&
			    rrule.until.is_date && !dtstart.is_date) {
				icaltime_adjust (&rrule.until, 1, 0, 0, 0);
				rrule.until.is_date = 0;
				rrule.until.hour = 0;
				rrule.until.minute = 0;
				rrule.until.second = 0;

				if (!rrule.until.zone && !icaltime_is_utc (rrule.until))
					rrule.until.zone = dtstart.zone;
			}

			riter = icalrecur_iterator_new (rrule, dtstart);
			if (riter) {
				struct icaltimetype prev = icaltime_null_time ();

				for (next = icalrecur_iterator_next (riter);
				     !icaltime_is_null_time (next) && icaltime_compare (next, interval_end) <= 0;
				     next = icalrecur_iterator_next (riter)) {
					if (!icaltime_is_null_time (prev) &&
					    icaltime_compare (next, prev) == 0)
						break;
					prev = next;

					if (intersects_interval (&next, NULL, duration_days, duration_seconds, &interval_start, &interval_end)) {
						g_hash_table_insert (times, e_instance_time_new (&next, NULL), NULL);
					}
				}

				icalrecur_iterator_free (riter);
			}
		}

		for (prop = icalcomponent_get_first_property (comp, ICAL_RDATE_PROPERTY);
		     prop && success;
		     prop = icalcomponent_get_next_property (comp, ICAL_RDATE_PROPERTY)) {
			struct icaldatetimeperiodtype rdate = icalproperty_get_rdate (prop);
			struct icaltimetype tt = icaltime_null_time ();
			struct icaldurationtype duration = icaldurationtype_null_duration ();

			if (!icaltime_is_null_time (rdate.time)) {
				tt = rdate.time;
			} else if (!icalperiodtype_is_null_period (rdate.period)) {
				tt = rdate.period.start;

				if (!icaltime_is_null_time (rdate.period.end)) {
					time_t diff;

					diff = icaltime_as_timet (rdate.period.end) - icaltime_as_timet (rdate.period.start);
					if (diff < 0) {
						duration.is_neg = 1;
						diff = diff * (-1);
					}

					#define set_and_dec(member, num) G_STMT_START { \
						member = diff / (num); \
						diff = diff % (num); \
						} G_STMT_END
					set_and_dec (duration.weeks, 7 * 24 * 60 * 60);
					set_and_dec (duration.days, 24 * 60 * 60);
					set_and_dec (duration.hours, 60 * 60);
					set_and_dec (duration.minutes, 60);
					set_and_dec (duration.seconds, 1);
					#undef set_and_dec

					g_warn_if_fail (diff == 0);
				} else if (!icaldurationtype_is_null_duration (rdate.period.duration)) {
					duration = rdate.period.duration;
				}

				if (!icaldurationtype_is_null_duration (duration) &&
				    !icaltime_is_null_time (tt)) {
					if (duration.is_neg) {
						apply_duration (&tt, &duration);

						duration.is_neg = 0;
					}
				}
			}

			if (!icaltime_is_null_time (tt)) {
				success = ensure_timezone (comp, &tt, 0, prop,
					get_tz_callback, get_tz_callback_user_data, (icaltimezone *) dtstart.zone,
					cancellable, error);
				if (!success)
					break;

				if (intersects_interval (&tt, &duration, duration_days, duration_seconds, &interval_start, &interval_end)) {
					g_hash_table_insert (times, e_instance_time_new (&tt, &duration), NULL);
				}
			}
		}

		for (prop = icalcomponent_get_first_property (comp, ICAL_EXRULE_PROPERTY);
		     prop && success;
		     prop = icalcomponent_get_next_property (comp, ICAL_EXRULE_PROPERTY)) {
			struct icalrecurrencetype exrule = icalproperty_get_exrule (prop);
			icalrecur_iterator *riter;

			if (!icaltime_is_null_time (exrule.until)) {
				success = ensure_timezone (comp, &exrule.until, 0, prop,
					get_tz_callback, get_tz_callback_user_data, (icaltimezone *) dtstart.zone,
					cancellable, error);
				if (!success)
					break;
			}

			if (!icaltime_is_null_time (exrule.until) &&
			    exrule.until.is_date && !dtstart.is_date) {
				icaltime_adjust (&exrule.until, 1, 0, 0, 0);
				exrule.until.is_date = 0;
				exrule.until.hour = 0;
				exrule.until.minute = 0;
				exrule.until.second = 0;

				if (!exrule.until.zone && !icaltime_is_utc (exrule.until))
					exrule.until.zone = dtstart.zone;
			}

			riter = icalrecur_iterator_new (exrule, dtstart);
			if (riter) {
				struct icaltimetype prev = icaltime_null_time ();

				for (next = icalrecur_iterator_next (riter);
				     !icaltime_is_null_time (next) && icaltime_compare (next, interval_end) <= 0;
				     next = icalrecur_iterator_next (riter)) {
					if (!icaltime_is_null_time (prev) &&
					    icaltime_compare (next, prev) == 0)
						break;
					prev = next;

					if (intersects_interval (&next, NULL, duration_days, duration_seconds, &interval_start, &interval_end)) {
						EInstanceTime it;

						it.tt = next;
						it.duration_set = FALSE;

						g_hash_table_remove (times, &it);
					}
				}

				icalrecur_iterator_free (riter);
			}
		}

		for (prop = icalcomponent_get_first_property (comp, ICAL_EXDATE_PROPERTY);
		     prop && success;
		     prop = icalcomponent_get_next_property (comp, ICAL_EXDATE_PROPERTY)) {
			struct icaltimetype exdate = icalproperty_get_exdate (prop);

			if (icaltime_is_null_time (exdate))
				continue;

			success = ensure_timezone (comp, &exdate, 0, prop,
				get_tz_callback, get_tz_callback_user_data, (icaltimezone *) dtstart.zone,
				cancellable, error);
			if (!success)
				break;

			if (!exdate.zone && !icaltime_is_utc (exdate))
				exdate.zone = dtstart.zone;

			if (intersects_interval (&exdate, NULL, duration_days, duration_seconds, &interval_start, &interval_end)) {
				EInstanceTime it;

				it.tt = exdate;
				it.duration_set = FALSE;

				g_hash_table_remove (times, &it);
			}
		}
	}

	if (success && g_hash_table_size (times) > 0) {
		GPtrArray *times_array;
		GHashTableIter hiter;
		gpointer key, value;
		gint ii;

		times_array = g_ptr_array_sized_new (g_hash_table_size (times));

		g_hash_table_iter_init (&hiter, times);
		while (g_hash_table_iter_next (&hiter, &key, &value)) {
			EInstanceTime *it = key;

			if (!it)
				continue;

			g_ptr_array_add (times_array, it);
		}

		g_ptr_array_sort (times_array, e_instance_time_compare_ptr_array);

		for (ii = 0; ii < times_array->len; ii++) {
			EInstanceTime *it = g_ptr_array_index (times_array, ii);
			struct icaltimetype ttend;
			gint dur_days = duration_days, dur_seconds = duration_seconds;

			if (!it)
				continue;

			ttend = it->tt;

			if (it->duration_set) {
				dur_days = it->duration_days;
				dur_seconds = it->duration_seconds;
			}

			if (dur_seconds != 0)
				ttend.is_date = 0;

			icaltime_adjust (&ttend, dur_days, 0, 0, dur_seconds);

			if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
				success = FALSE;
				break;
			}

			success = callback (comp, it->tt, ttend, callback_user_data, cancellable, error);
			if (!success)
				break;
		}

		g_ptr_array_free (times_array, TRUE);
	}

	g_hash_table_destroy (times);

	return success;
}

/*
 * Introduction to The Recurrence Generation Functions:
 *
 * Note: This is pretty complicated. See the iCalendar spec (RFC 2445) for
 *       the specification of the recurrence rules and lots of examples
 *	 (sections 4.3.10 & 4.8.5). We also want to support the older
 *	 vCalendar spec, though this should be easy since it is basically a
 *	 subset of iCalendar.
 *
 * o An iCalendar event can have any number of recurrence rules specifying
 *   occurrences of the event, as well as dates & times of specific
 *   occurrences. It can also have any number of recurrence rules and
 *   specific dates & times specifying exceptions to the occurrences.
 *   So we first merge all the occurrences generated, eliminating any
 *   duplicates, then we generate all the exceptions and remove these to
 *   form the final set of occurrences.
 *
 * o There are 7 frequencies of occurrences: YEARLY, MONTHLY, WEEKLY, DAILY,
 *   HOURLY, MINUTELY & SECONDLY. The 'interval' property specifies the
 *   multiples of the frequency which we step by. We generate a 'set' of
 *   occurrences for each period defined by the frequency & interval.
 *   So for a YEARLY frequency with an interval of 3, we generate a set of
 *   occurrences for every 3rd year. We use complete years here -  any
 *   generated occurrences that occur before the event's start (or after its
 *   end) are just discarded.
 *
 * o There are 8 frequency modifiers: BYMONTH, BYWEEKNO, BYYEARDAY, BYMONTHDAY,
 *   BYDAY, BYHOUR, BYMINUTE & BYSECOND. These can either add extra occurrences
 *   or filter out occurrences. For example 'FREQ=YEARLY;BYMONTH=1,2' produces
 *   2 occurrences for each year rather than the default 1. And
 *   'FREQ=DAILY;BYMONTH=1' filters out all occurrences except those in Jan.
 *   If the modifier works on periods which are less than the recurrence
 *   frequency, then extra occurrences are added, otherwise occurrences are
 *   filtered. So we have 2 functions for each modifier - one to expand events
 *   and the other to filter. We use a table of functions for each frequency
 *   which points to the appropriate function to use for each modifier.
 *
 * o Any number of frequency modifiers can be used in a recurrence rule.
 *   (Though the iCalendar spec says that BYWEEKNO can only be used in a YEARLY
 *   rule, and some modifiers aren't appropriate for some frequencies - e.g.
 *   BYMONTHDAY is not really useful in a WEEKLY frequency, and BYYEARDAY is
 *   not useful in a MONTHLY or WEEKLY frequency).
 *   The frequency modifiers are applied in the order given above. The first 5
 *   modifier rules (BYMONTH, BYWEEKNO, BYYEARDAY, BYMONTHDAY & BYDAY) all
 *   produce the days on which the occurrences take place, and so we have to
 *   compute some of these in parallel rather than sequentially, or we may end
 *   up with too many days.
 *
 * o Note that some expansion functions may produce days which are invalid,
 *   e.g. 31st September, 30th Feb. These invalid days are removed before the
 *   BYHOUR, BYMINUTE & BYSECOND modifier functions are applied.
 *
 * o After the set of occurrences for the frequency interval are generated,
 *   the BYSETPOS property is used to select which of the occurrences are
 *   finally output. If BYSETPOS is not specified then all the occurrences are
 *   output.
 *
 *
 * FIXME: I think there are a few errors in this code:
 *
 *  1) I'm not sure it should be generating events in parallel like it says
 *     above. That needs to be checked.
 *
 *  2) I didn't think about timezone changes when implementing this. I just
 *     assumed all the occurrences of the event would be in local time.
 *     But when clocks go back or forwards due to daylight-saving time, some
 *     special handling may be needed, especially for the shorter frequencies.
 *     e.g. for a MINUTELY frequency it should probably iterate over all the
 *     minutes before and after clocks go back (i.e. some may be the same local
 *     time but have different UTC offsets). For longer frequencies, if an
 *     occurrence lands on the overlapping or non-existant time when clocks
 *     go back/forward, then it may need to choose which of the times to use
 *     or move the time forward or something. I'm not sure this is clear in the
 *     spec.
 */

/* This is the maximum year we will go up to (inclusive). Since we use time_t
 * values we can't go past 2037 anyway, and some of our VTIMEZONEs may stop
 * at 2037 as well. */
#define MAX_YEAR	2037

/* Define this for some debugging output. */
#if 0
#define CAL_OBJ_DEBUG	1
#endif

/* We will use icalrecurrencetype instead of this eventually. */
typedef struct {
	icalrecurrencetype_frequency freq;

	gint            interval;

	/* Specifies the end of the recurrence, inclusive. No occurrences are
	 * generated after this date. If it is 0, the event recurs forever. */
	time_t         enddate;

	/* WKST property - the week start day: 0 = Monday to 6 = Sunday. */
	gint	       week_start_day;

	/* NOTE: I've used GList's here, but it doesn't matter if we use
	 * other data structures like arrays. The code should be easy to
	 * change. So long as it is easy to see if the modifier is set. */

	/* For BYMONTH modifier. A list of GINT_TO_POINTERs, 0-11. */
	GList	      *bymonth;

	/* For BYWEEKNO modifier. A list of GINT_TO_POINTERs, [+-]1-53. */
	GList	      *byweekno;

	/* For BYYEARDAY modifier. A list of GINT_TO_POINTERs, [+-]1-366. */
	GList	      *byyearday;

	/* For BYMONTHDAY modifier. A list of GINT_TO_POINTERs, [+-]1-31. */
	GList	      *bymonthday;

	/* For BYDAY modifier. A list of GINT_TO_POINTERs, in pairs.
	 * The first of each pair is the weekday, 0 = Monday to 6 = Sunday.
	 * The second of each pair is the week number[+-]0-53. */
	GList	      *byday;

	/* For BYHOUR modifier. A list of GINT_TO_POINTERs, 0-23. */
	GList	      *byhour;

	/* For BYMINUTE modifier. A list of GINT_TO_POINTERs, 0-59. */
	GList	      *byminute;

	/* For BYSECOND modifier. A list of GINT_TO_POINTERs, 0-60. */
	GList	      *bysecond;

	/* For BYSETPOS modifier. A list of GINT_TO_POINTERs, +ve or -ve. */
	GList	      *bysetpos;
} ECalRecurrence;

/* This is what we use to pass to all the filter functions. */
typedef struct _RecurData RecurData;
struct _RecurData {
	ECalRecurrence *recur;

	/* This is used for the WEEKLY frequency. It is the offset from the
	 * week_start_day. */
	gint weekday_offset;

	/* This is used for fast lookup in BYMONTH filtering. */
	guint8 months[12];

	/* This is used for fast lookup in BYYEARDAY filtering. */
	guint8 yeardays[367], neg_yeardays[367]; /* Days are 1 - 366. */

	/* This is used for fast lookup in BYMONTHDAY filtering. */
	guint8 monthdays[32], neg_monthdays[32]; /* Days are 1 to 31. */

	/* This is used for fast lookup in BYDAY filtering. */
	guint8 weekdays[7];

	/* This is used for fast lookup in BYHOUR filtering. */
	guint8 hours[24];

	/* This is used for fast lookup in BYMINUTE filtering. */
	guint8 minutes[60];

	/* This is used for fast lookup in BYSECOND filtering. */
	guint8 seconds[62];
};

/* This is what we use to represent a date & time. */
typedef struct _CalObjTime CalObjTime;
struct _CalObjTime {
	guint16 year;
	guint8 month;		/* 0 - 11 */
	guint8 day;		/* 1 - 31 */
	guint8 hour;		/* 0 - 23 */
	guint8 minute;		/* 0 - 59 */
	guint8 second;		/* 0 - 59 (maybe up to 61 for leap seconds) */
	guint8 flags;		/* The meaning of this depends on where the
				 * CalObjTime is used. In most cases this is
				 * set to TRUE to indicate that this is an
				 * RDATE with an end or a duration set.
				 * In the exceptions code, this is set to TRUE
				 * to indicate that this is an EXDATE with a
				 * DATE value. */
};

/* This is what we use to represent specific recurrence dates.
 * Note that we assume it starts with a CalObjTime when sorting. */
typedef struct _CalObjRecurrenceDate CalObjRecurrenceDate;
struct _CalObjRecurrenceDate {
	CalObjTime start;
	ECalComponentPeriod *period;
};

/* The paramter we use to store the enddate in RRULE and EXRULE properties. */
#define EVOLUTION_END_DATE_PARAMETER	"X-EVOLUTION-ENDDATE"

typedef gboolean (*CalObjFindStartFn) (CalObjTime *event_start,
				       CalObjTime *event_end,
				       RecurData  *recur_data,
				       CalObjTime *interval_start,
				       CalObjTime *interval_end,
				       CalObjTime *cotime);
typedef gboolean (*CalObjFindNextFn)  (CalObjTime *cotime,
				       CalObjTime *event_end,
				       RecurData  *recur_data,
				       CalObjTime *interval_end);
typedef GArray *	 (*CalObjFilterFn)    (RecurData  *recur_data,
				       GArray     *occs);

typedef struct _ECalRecurVTable ECalRecurVTable;
struct _ECalRecurVTable {
	CalObjFindStartFn find_start_position;
	CalObjFindNextFn find_next_position;

	CalObjFilterFn bymonth_filter;
	CalObjFilterFn byweekno_filter;
	CalObjFilterFn byyearday_filter;
	CalObjFilterFn bymonthday_filter;
	CalObjFilterFn byday_filter;
	CalObjFilterFn byhour_filter;
	CalObjFilterFn byminute_filter;
	CalObjFilterFn bysecond_filter;
};

/* This is used to specify which parts of the CalObjTime to compare in
 * cal_obj_time_compare (). */
typedef enum {
	CALOBJ_YEAR,
	CALOBJ_MONTH,
	CALOBJ_DAY,
	CALOBJ_HOUR,
	CALOBJ_MINUTE,
	CALOBJ_SECOND
} CalObjTimeComparison;

static void e_cal_recur_generate_instances_of_rule (ECalComponent	*comp,
						  icalproperty	*prop,
						  time_t	 start,
						  time_t	 end,
						  ECalRecurInstanceFn cb,
						  gpointer       cb_data,
						  ECalRecurResolveTimezoneFn  tz_cb,
						  gpointer	 tz_cb_data,
						  icaltimezone	*default_timezone);

static ECalRecurrence * e_cal_recur_from_icalproperty (icalproperty *prop,
						    gboolean exception,
						    icaltimezone *zone,
						    gboolean convert_end_date);
static gint e_cal_recur_ical_weekday_to_weekday	(enum icalrecurrencetype_weekday day);
static void	e_cal_recur_free			(ECalRecurrence	*r);

static gboolean cal_object_get_rdate_end	(CalObjTime	*occ,
						 GArray		*rdate_periods,
						 icaltimezone	*zone);
static void	cal_object_compute_duration	(CalObjTime	*start,
						 CalObjTime	*end,
						 gint		*days,
						 gint		*seconds);

static gboolean generate_instances_for_chunk	(ECalComponent		*comp,
						 time_t			 comp_dtstart,
						 icaltimezone		*zone,
						 GSList			*rrules,
						 GSList			*rdates,
						 GSList			*exrules,
						 GSList			*exdates,
						 gboolean		 single_rule,
						 CalObjTime		*event_start,
						 time_t			 interval_start,
						 CalObjTime		*chunk_start,
						 CalObjTime		*chunk_end,
						 gint			 duration_days,
						 gint			 duration_seconds,
						 gboolean		 convert_end_date,
						 ECalRecurInstanceFn	 cb,
						 gpointer		 cb_data);

static GArray * cal_obj_expand_recurrence	(CalObjTime	  *event_start,
						 icaltimezone	  *zone,
						 ECalRecurrence	  *recur,
						 CalObjTime	  *interval_start,
						 CalObjTime	  *interval_end,
						 gboolean	  *finished);

static GArray *	cal_obj_generate_set_yearly	(RecurData	*recur_data,
						 ECalRecurVTable *vtable,
						 CalObjTime	*occ);
static GArray *	cal_obj_generate_set_monthly	(RecurData	*recur_data,
						 ECalRecurVTable *vtable,
						 CalObjTime	*occ);
static GArray *	cal_obj_generate_set_default	(RecurData	*recur_data,
						 ECalRecurVTable *vtable,
						 CalObjTime	*occ);

static gboolean cal_obj_get_vtable		(ECalRecurrence *recur,
						 ECalRecurVTable *out_vtable);
static void	cal_obj_initialize_recur_data	(RecurData	*recur_data,
						 ECalRecurrence	*recur,
						 CalObjTime	*event_start);
static void	cal_obj_sort_occurrences	(GArray		*occs);
static gint	cal_obj_time_compare_func	(const void	*arg1,
						 const void	*arg2);
static void	cal_obj_remove_duplicates_and_invalid_dates (GArray	*occs);
static void	cal_obj_remove_exceptions	(GArray		*occs,
						 GArray		*ex_occs);
static GArray *	cal_obj_bysetpos_filter		(ECalRecurrence	*recur,
						 GArray		*occs);

static gboolean cal_obj_yearly_find_start_position (CalObjTime *event_start,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_start,
						    CalObjTime *interval_end,
						    CalObjTime *cotime);
static gboolean cal_obj_yearly_find_next_position  (CalObjTime *cotime,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_end);

static gboolean cal_obj_monthly_find_start_position (CalObjTime *event_start,
						     CalObjTime *event_end,
						     RecurData  *recur_data,
						     CalObjTime *interval_start,
						     CalObjTime *interval_end,
						     CalObjTime *cotime);
static gboolean cal_obj_monthly_find_next_position  (CalObjTime *cotime,
						     CalObjTime *event_end,
						     RecurData  *recur_data,
						     CalObjTime *interval_end);

static gboolean cal_obj_weekly_find_start_position (CalObjTime *event_start,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_start,
						    CalObjTime *interval_end,
						    CalObjTime *cotime);
static gboolean cal_obj_weekly_find_next_position  (CalObjTime *cotime,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_end);

static gboolean cal_obj_daily_find_start_position  (CalObjTime *event_start,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_start,
						    CalObjTime *interval_end,
						    CalObjTime *cotime);
static gboolean cal_obj_daily_find_next_position   (CalObjTime *cotime,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_end);

static gboolean cal_obj_hourly_find_start_position (CalObjTime *event_start,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_start,
						    CalObjTime *interval_end,
						    CalObjTime *cotime);
static gboolean cal_obj_hourly_find_next_position  (CalObjTime *cotime,
						    CalObjTime *event_end,
						    RecurData  *recur_data,
						    CalObjTime *interval_end);

static gboolean cal_obj_minutely_find_start_position (CalObjTime *event_start,
						      CalObjTime *event_end,
						      RecurData  *recur_data,
						      CalObjTime *interval_start,
						      CalObjTime *interval_end,
						      CalObjTime *cotime);
static gboolean cal_obj_minutely_find_next_position  (CalObjTime *cotime,
						      CalObjTime *event_end,
						      RecurData  *recur_data,
						      CalObjTime *interval_end);

static gboolean cal_obj_secondly_find_start_position (CalObjTime *event_start,
						      CalObjTime *event_end,
						      RecurData  *recur_data,
						      CalObjTime *interval_start,
						      CalObjTime *interval_end,
						      CalObjTime *cotime);
static gboolean cal_obj_secondly_find_next_position  (CalObjTime *cotime,
						      CalObjTime *event_end,
						      RecurData  *recur_data,
						      CalObjTime *interval_end);

static GArray * cal_obj_bymonth_expand		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_bymonth_filter		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byweekno_expand		(RecurData  *recur_data,
						 GArray     *occs);
#if 0
/* This isn't used at present. */
static GArray * cal_obj_byweekno_filter		(RecurData  *recur_data,
						 GArray     *occs);
#endif
static GArray * cal_obj_byyearday_expand		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byyearday_filter		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_bymonthday_expand	(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_bymonthday_filter	(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byday_expand_yearly	(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byday_expand_monthly	(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byday_expand_weekly	(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byday_filter		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byhour_expand		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byhour_filter		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byminute_expand		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_byminute_filter		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_bysecond_expand		(RecurData  *recur_data,
						 GArray     *occs);
static GArray * cal_obj_bysecond_filter		(RecurData  *recur_data,
						 GArray     *occs);

static void cal_obj_time_add_months		(CalObjTime *cotime,
						 gint	     months);
static void cal_obj_time_add_days		(CalObjTime *cotime,
						 gint	     days);
static void cal_obj_time_add_hours		(CalObjTime *cotime,
						 gint	     hours);
static void cal_obj_time_add_minutes		(CalObjTime *cotime,
						 gint	     minutes);
static void cal_obj_time_add_seconds		(CalObjTime *cotime,
						 gint	     seconds);
static gint cal_obj_time_compare		(CalObjTime *cotime1,
						 CalObjTime *cotime2,
						 CalObjTimeComparison type);
static gint cal_obj_time_weekday		(CalObjTime *cotime);
static gint cal_obj_time_weekday_offset		(CalObjTime *cotime,
						 ECalRecurrence *recur);
static gint cal_obj_time_day_of_year		(CalObjTime *cotime);
static void cal_obj_time_find_first_week	(CalObjTime *cotime,
						 RecurData  *recur_data);
static void cal_object_time_from_time		(CalObjTime *cotime,
						 time_t      t,
						 icaltimezone *zone);
static gint cal_obj_date_only_compare_func	(gconstpointer arg1,
						 gconstpointer arg2);
static gboolean e_cal_recur_ensure_rule_end_date	(ECalComponent	*comp,
						 icalproperty	*prop,
						 gboolean	 exception,
						 gboolean	 refresh,
						 ECalRecurResolveTimezoneFn tz_cb,
						 gpointer	 tz_cb_data);
static gboolean e_cal_recur_ensure_rule_end_date_cb	(ECalComponent	*comp,
							 time_t		 instance_start,
							 time_t		 instance_end,
							 gpointer	 data);
static time_t e_cal_recur_get_rule_end_date	(icalproperty	*prop,
						 icaltimezone	*default_timezone);
static void e_cal_recur_set_rule_end_date		(icalproperty	*prop,
						 time_t		 end_date);

#ifdef CAL_OBJ_DEBUG
static const gchar * cal_obj_time_to_string		(CalObjTime	*cotime);
#endif

static ECalRecurVTable cal_obj_yearly_vtable = {
	cal_obj_yearly_find_start_position,
	cal_obj_yearly_find_next_position,

	cal_obj_bymonth_expand,
	cal_obj_byweekno_expand,
	cal_obj_byyearday_expand,
	cal_obj_bymonthday_expand,
	cal_obj_byday_expand_yearly,
	cal_obj_byhour_expand,
	cal_obj_byminute_expand,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_monthly_vtable = {
	cal_obj_monthly_find_start_position,
	cal_obj_monthly_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	NULL, /* BYYEARDAY is not useful in a MONTHLY frequency. */
	cal_obj_bymonthday_filter,
	cal_obj_byday_expand_monthly,
	cal_obj_byhour_expand,
	cal_obj_byminute_expand,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_weekly_vtable = {
	cal_obj_weekly_find_start_position,
	cal_obj_weekly_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	NULL, /* BYYEARDAY is not useful in a WEEKLY frequency. */
	NULL, /* BYMONTHDAY is not useful in a WEEKLY frequency. */
	cal_obj_byday_expand_weekly,
	cal_obj_byhour_expand,
	cal_obj_byminute_expand,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_daily_vtable = {
	cal_obj_daily_find_start_position,
	cal_obj_daily_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	cal_obj_byyearday_filter,
	cal_obj_bymonthday_filter,
	cal_obj_byday_filter,
	cal_obj_byhour_expand,
	cal_obj_byminute_expand,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_hourly_vtable = {
	cal_obj_hourly_find_start_position,
	cal_obj_hourly_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	cal_obj_byyearday_filter,
	cal_obj_bymonthday_filter,
	cal_obj_byday_filter,
	cal_obj_byhour_filter,
	cal_obj_byminute_expand,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_minutely_vtable = {
	cal_obj_minutely_find_start_position,
	cal_obj_minutely_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	cal_obj_byyearday_filter,
	cal_obj_bymonthday_filter,
	cal_obj_byday_filter,
	cal_obj_byhour_filter,
	cal_obj_byminute_filter,
	cal_obj_bysecond_expand
};

static ECalRecurVTable cal_obj_secondly_vtable = {
	cal_obj_secondly_find_start_position,
	cal_obj_secondly_find_next_position,

	cal_obj_bymonth_filter,
	NULL, /* BYWEEKNO is only applicable to YEARLY frequency. */
	cal_obj_byyearday_filter,
	cal_obj_bymonthday_filter,
	cal_obj_byday_filter,
	cal_obj_byhour_filter,
	cal_obj_byminute_filter,
	cal_obj_bysecond_filter
};

#ifdef HAVE_LIBICAL_2_0
struct BackwardCompatibilityData
{
	ECalComponent *comp;
	ECalRecurInstanceFn cb;
	gpointer cb_data;
	ECalRecurResolveTimezoneFn tz_cb;
	gpointer tz_cb_data;
};

static icaltimezone *
backward_compatibility_resolve_timezone_cb (const gchar *tzid,
					    gpointer user_data,
					    GCancellable *cancellable,
					    GError **error)
{
	struct BackwardCompatibilityData *bcd = user_data;

	if (bcd && bcd->tz_cb)
		return bcd->tz_cb (tzid, bcd->tz_cb_data);

	return NULL;
}

static gboolean
backward_compatibility_instance_cb (icalcomponent *comp,
				    struct icaltimetype instance_start,
				    struct icaltimetype instance_end,
				    gpointer user_data,
				    GCancellable *cancellable,
				    GError **error)
{
	struct BackwardCompatibilityData *bcd = user_data;

	if (bcd && bcd->cb) {
		time_t istart, iend;

		if (instance_start.zone)
			istart = icaltime_as_timet_with_zone (instance_start, instance_start.zone);
		else
			istart = icaltime_as_timet (instance_start);

		if (instance_end.zone)
			iend = icaltime_as_timet_with_zone (instance_end, instance_end.zone);
		else
			iend = icaltime_as_timet (instance_end);

		return bcd->cb (bcd->comp, istart, iend, bcd->cb_data);
	}

	return FALSE;
}

#endif

/**
 * e_cal_recur_generate_instances:
 * @comp: A calendar component object
 * @start: Range start time
 * @end: Range end time
 * @cb: (closure cb_data) (scope call): Callback function
 * @cb_data: (closure): Closure data for the callback function
 * @tz_cb: (closure tz_cb_data) (scope call): Callback for retrieving timezones
 * @tz_cb_data: (closure): Closure data for the timezone callback
 * @default_timezone: Default timezone to use when a timezone cannot be
 * found
 *
 * Calls the given callback function for each occurrence of the event that
 * intersects the range between the given @start and @end times (the end time is
 * not included). Note that the occurrences may start before the given start
 * time.
 *
 * If the callback routine returns FALSE the occurrence generation stops.
 *
 * Both start and end can be -1, in which case we start at the events first
 * instance and continue until it ends, or forever if it has no enddate.
 *
 * The tz_cb is used to resolve references to timezones. It is passed a TZID
 * and should return the icaltimezone* corresponding to that TZID. We need to
 * do this as we access timezones in different ways on the client & server.
 *
 * The default_timezone argument is used for DTSTART or DTEND properties that
 * are DATE values or do not have a TZID (i.e. floating times).
 *
 * Note: This will be replaced by e_cal_recur_generate_instances_sync().
 */
void
e_cal_recur_generate_instances (ECalComponent *comp,
                                time_t start,
                                time_t end,
                                ECalRecurInstanceFn cb,
                                gpointer cb_data,
                                ECalRecurResolveTimezoneFn tz_cb,
                                gpointer tz_cb_data,
                                icaltimezone *default_timezone)
{
#ifdef HAVE_LIBICAL_2_0
	struct icaltimetype istart, iend;
	struct BackwardCompatibilityData bcd;

	bcd.comp = comp;
	bcd.cb = cb;
	bcd.cb_data = cb_data;
	bcd.tz_cb = tz_cb;
	bcd.tz_cb_data = tz_cb_data;

	istart = icaltime_from_timet_with_zone (start, FALSE, icaltimezone_get_utc_timezone ());
	iend = icaltime_from_timet_with_zone (end, FALSE, icaltimezone_get_utc_timezone ());

	e_cal_recur_generate_instances_sync (e_cal_component_get_icalcomponent (comp), istart, iend,
		backward_compatibility_instance_cb, &bcd,
		backward_compatibility_resolve_timezone_cb, &bcd,
		default_timezone, NULL, NULL);
#else
	e_cal_recur_generate_instances_of_rule (
		comp, NULL, start, end,
		cb, cb_data, tz_cb, tz_cb_data,
		default_timezone);
#endif
}

/*
 * Calls the given callback function for each occurrence of the given
 * recurrence rule between the given start and end times. If the rule is NULL
 * it uses all the rules from the component.
 *
 * If the callback routine returns FALSE the occurrence generation stops.
 *
 * The use of the specific rule is for determining the end of a rule when
 * COUNT is set. The callback will count instances and store the enddate
 * when COUNT is reached.
 *
 * Both start and end can be -1, in which case we start at the events first
 * instance and continue until it ends, or forever if it has no enddate.
 */
static void
e_cal_recur_generate_instances_of_rule (ECalComponent *comp,
                                        icalproperty *prop,
                                        time_t start,
                                        time_t end,
                                        ECalRecurInstanceFn cb,
                                        gpointer cb_data,
                                        ECalRecurResolveTimezoneFn tz_cb,
                                        gpointer tz_cb_data,
                                        icaltimezone *default_timezone)
{
	ECalComponentDateTime dtstart, dtend;
	time_t dtstart_time, dtend_time;
	GSList *rrules = NULL, *rdates = NULL, elem;
	GSList *exrules = NULL, *exdates = NULL;
	CalObjTime interval_start, interval_end, event_start, event_end;
	CalObjTime chunk_start, chunk_end;
	gint days, seconds, year;
	gboolean single_rule, convert_end_date = FALSE;
	icaltimezone *start_zone = NULL, *end_zone = NULL;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (cb != NULL);
	g_return_if_fail (tz_cb != NULL);
	g_return_if_fail (start >= -1);
	g_return_if_fail (end >= -1);

	/* Get dtstart, dtend, recurrences, and exceptions. Note that
	 * cal_component_get_dtend () will convert a DURATION property to a
	 * DTEND so we don't need to worry about that. */

	e_cal_component_get_dtstart (comp, &dtstart);
	e_cal_component_get_dtend (comp, &dtend);

	if (!dtstart.value) {
		g_message (
			"e_cal_recur_generate_instances_of_rule(): bogus "
			"component, does not have DTSTART.  Skipping...");
		goto out;
	}

	/* For DATE-TIME values with a TZID, we use the supplied callback to
	 * resolve the TZID. For DATE values and DATE-TIME values without a
	 * TZID (i.e. floating times) we use the default timezone. */
	if (dtstart.tzid && !dtstart.value->is_date) {
		start_zone = (*tz_cb) (dtstart.tzid, tz_cb_data);
		if (!start_zone)
			start_zone = default_timezone;
	} else {
		start_zone = default_timezone;

		/* Flag that we need to convert the saved ENDDATE property
		 * to the default timezone. */
		convert_end_date = TRUE;
	}

	dtstart_time = icaltime_as_timet_with_zone (
		*dtstart.value,
		start_zone);
	if (start == -1)
		start = dtstart_time;

	if (dtend.value) {
		/* If both DTSTART and DTEND are DATE values, and they are the
		 * same day, we add 1 day to DTEND. This means that most
		 * events created with the old Evolution behavior will still
		 * work OK. I'm not sure what Outlook does in this case. */
		if (dtstart.value->is_date && dtend.value->is_date) {
			if (icaltime_compare_date_only (*dtstart.value,
							*dtend.value) == 0) {
				icaltime_adjust (dtend.value, 1, 0, 0, 0);
			}
		}
	} else {
		/* If there is no DTEND, then if DTSTART is a DATE-TIME value
		 * we use the same time (so we have a single point in time).
		 * If DTSTART is a DATE value we add 1 day. */
		dtend.value = g_new (struct icaltimetype, 1);
		*dtend.value = *dtstart.value;

		if (dtstart.value->is_date) {
			icaltime_adjust (dtend.value, 1, 0, 0, 0);
		}
	}

	if (dtend.tzid && !dtend.value->is_date) {
		end_zone = (*tz_cb) (dtend.tzid, tz_cb_data);
		if (!end_zone)
			end_zone = default_timezone;
	} else {
		end_zone = default_timezone;
	}

	/* We don't do this any more, since Outlook assumes that the DTEND
	 * date is not included. */
#if 0
	/* If DTEND is a DATE value, we add 1 day to it so that it includes
	 * the entire day. */
	if (dtend.value->is_date) {
		dtend.value->hour = 0;
		dtend.value->minute = 0;
		dtend.value->second = 0;
		icaltime_adjust (dtend.value, 1, 0, 0, 0);
	}
#endif
	dtend_time = icaltime_as_timet_with_zone (*dtend.value, end_zone);

	/* If there is no recurrence, just call the callback if the event
	 * intersects the given interval. */
	if (!(e_cal_component_has_recurrences (comp)
	      || e_cal_component_has_exceptions (comp))) {
		if (e_cal_component_get_vtype (comp) == E_CAL_COMPONENT_JOURNAL) {
			icaltimetype start_t = icaltime_from_timet_with_zone (start, FALSE, default_timezone);
			icaltimetype end_t = icaltime_from_timet_with_zone (end, FALSE, default_timezone);

			if ((icaltime_compare_date_only (*dtstart.value, start_t) >= 0) && ((icaltime_compare_date_only (*dtstart.value, end_t) < 0)))
				(* cb) (comp, dtstart_time, dtend_time, cb_data);
		} else if  ((end == -1 || dtstart_time < end) && dtend_time > start) {
			(* cb) (comp, dtstart_time, dtend_time, cb_data);
		}

		goto out;
	}

	/* If a specific recurrence rule is being used, set up a simple list,
	 * else get the recurrence rules from the component. */
	if (prop) {
		single_rule = TRUE;

		elem.data = prop;
		elem.next = NULL;
		rrules = &elem;
	} else if (e_cal_component_is_instance (comp)) {
		single_rule = FALSE;
	} else {
		single_rule = FALSE;

		/* Make sure all the enddates for the rules are set. */
		e_cal_recur_ensure_end_dates (comp, FALSE, tz_cb, tz_cb_data);

		e_cal_component_get_rrule_property_list (comp, &rrules);
		e_cal_component_get_rdate_list (comp, &rdates);
		e_cal_component_get_exrule_property_list (comp, &exrules);
		e_cal_component_get_exdate_list (comp, &exdates);
	}

	/* Convert the interval start & end to CalObjTime. Note that if end
	 * is -1 interval_end won't be set, so don't use it!
	 * Also note that we use end - 1 since we want the interval to be
	 * inclusive as it makes the code simpler. We do all calculation
	 * in the timezone of the DTSTART. */
	cal_object_time_from_time (&interval_start, start, start_zone);
	if (end != -1)
		cal_object_time_from_time (&interval_end, end - 1, start_zone);

	cal_object_time_from_time (&event_start, dtstart_time, start_zone);
	cal_object_time_from_time (&event_end, dtend_time, start_zone);

	/* Calculate the duration of the event, which we use for all
	 * occurrences. We can't just subtract start from end since that may
	 * be affected by daylight-saving time. So we want a value of days
	 * + seconds. */
	cal_object_compute_duration (
		&event_start, &event_end,
		&days, &seconds);

	/* Take off the duration from interval_start, so we get occurrences
	 * that start just before the start time but overlap it. But only do
	 * that if the interval is after the event's start time. */
	if (start > dtstart_time) {
		cal_obj_time_add_days (&interval_start, -days);
		cal_obj_time_add_seconds (&interval_start, -seconds);
	}

	/* Expand the recurrence for each year between start & end, or until
	 * the callback returns 0 if end is 0. We do a year at a time to
	 * give the callback function a chance to break out of the loop, and
	 * so we don't get into problems with infinite recurrences. Since we
	 * have to work on complete sets of occurrences, if there is a yearly
	 * frequency it wouldn't make sense to break it into smaller chunks,
	 * since we would then be calculating the same sets several times.
	 * Though this does mean that we sometimes do a lot more work than
	 * is necessary, e.g. if COUNT is set to something quite low. */
	for (year = interval_start.year;
	     (end == -1 || year <= interval_end.year) && year <= MAX_YEAR;
	     year++) {
		chunk_start = interval_start;
		chunk_start.year = year;
		if (end != -1)
			chunk_end = interval_end;
		chunk_end.year = year;

		if (year != interval_start.year) {
			chunk_start.month = 0;
			chunk_start.day = 1;
			chunk_start.hour = 0;
			chunk_start.minute = 0;
			chunk_start.second = 0;
		}
		if (end == -1 || year != interval_end.year) {
			chunk_end.month = 11;
			chunk_end.day = 31;
			chunk_end.hour = 23;
			chunk_end.minute = 59;
			chunk_end.second = 61;
			chunk_end.flags = FALSE;
		}

		if (!generate_instances_for_chunk (comp, dtstart_time,
						   start_zone,
						   rrules, rdates,
						   exrules, exdates,
						   single_rule,
						   &event_start,
						   start,
						   &chunk_start, &chunk_end,
						   days, seconds,
						   convert_end_date,
						   cb, cb_data))
			break;
	}

	if (!prop) {
		e_cal_component_free_period_list (rdates);
		e_cal_component_free_exdate_list (exdates);
	}

 out:
	e_cal_component_free_datetime (&dtstart);
	e_cal_component_free_datetime (&dtend);
}

/* Builds a list of GINT_TO_POINTER() elements out of a short array from a
 * struct icalrecurrencetype.
 */
static GList *
array_to_list (gshort *array,
               gint max_elements)
{
	GList *l;
	gint i;

	l = NULL;

	for (i = 0; i < max_elements && array[i] != ICAL_RECURRENCE_ARRAY_MAX; i++)
		l = g_list_prepend (l, GINT_TO_POINTER ((gint) (array[i])));
	return g_list_reverse (l);
}

/**
 * e_cal_recur_get_enddate:
 * @ir: RRULE or EXRULE recurrence 
 * @prop: An RRULE or EXRULE #icalproperty. 
 * @zone: The DTSTART timezone, used for converting the UNTIL property if it
 * is given as a DATE value.
 * @convert_end_date: TRUE if the saved end date needs to be converted to the
 * given @zone timezone. This is needed if the DTSTART is a DATE or floating
 * time.
 * 
 * Finds out end time of (reccurent) event.
 *
 * Returns: End timepoint of given event
 *
 * Since: 2.32
 */
time_t
e_cal_recur_obtain_enddate (struct icalrecurrencetype *ir,
                            icalproperty *prop,
          icaltimezone *zone,
                            gboolean convert_end_date)
{
	time_t enddate = -1;

	g_return_val_if_fail (prop != NULL, 0);
	g_return_val_if_fail (ir != NULL, 0);

	if (ir->count != 0) {
		/* If COUNT is set, we use the pre-calculated enddate.
		Note that this can be 0 if the RULE doesn't actually
		generate COUNT instances. */
		enddate = e_cal_recur_get_rule_end_date (prop, convert_end_date ? zone : NULL);
	} else {
		if (icaltime_is_null_time (ir->until)) {
			/* If neither COUNT or UNTIL is set, the event
			recurs forever. */
		} else if (ir->until.is_date) {
			/* If UNTIL is a DATE, we stop at the end of
			the day, in local time (with the DTSTART timezone).
			Note that UNTIL is inclusive so we stop before
			midnight. */
			ir->until.hour = 23;
			ir->until.minute = 59;
			ir->until.second = 59;
			ir->until.is_date = FALSE;

			enddate = icaltime_as_timet_with_zone (ir->until, zone);
#if 0
	g_print ("  until: %li - %s", r->enddate, ctime (&r->enddate));
#endif

		} else {
		/* If UNTIL is a DATE-TIME, it must be in UTC. */
		icaltimezone *utc_zone;
		utc_zone = icaltimezone_get_utc_timezone ();
		enddate = icaltime_as_timet_with_zone (ir->until, utc_zone);
		}
	}

	return enddate;
}

/**
 * e_cal_recur_from_icalproperty:
 * @prop: An RRULE or EXRULE #icalproperty.
 * @exception: TRUE if this is an EXRULE rather than an RRULE.
 * @zone: The DTSTART timezone, used for converting the UNTIL property if it
 * is given as a DATE value.
 * @convert_end_date: TRUE if the saved end date needs to be converted to the
 * given @zone timezone. This is needed if the DTSTART is a DATE or floating
 * time.
 *
 * Converts an #icalproperty to a #ECalRecurrence.  This should be
 * freed using the e_cal_recur_free() function.
 *
 * Returns: #ECalRecurrence structure.
 **/
static ECalRecurrence *
e_cal_recur_from_icalproperty (icalproperty *prop,
                               gboolean exception,
                               icaltimezone *zone,
                               gboolean convert_end_date)
{
	struct icalrecurrencetype ir;
	ECalRecurrence *r;
	gint max_elements, i;
	GList *elem;

	g_return_val_if_fail (prop != NULL, NULL);

	r = g_new (ECalRecurrence, 1);

	if (exception)
		ir = icalproperty_get_exrule (prop);
	else
		ir = icalproperty_get_rrule (prop);

	r->freq = ir.freq;

	if (G_UNLIKELY (ir.interval < 1)) {
		g_warning (
			"Invalid interval in rule %s - using 1\n",
			icalrecurrencetype_as_string (&ir));
		r->interval = 1;
	} else {
		r->interval = ir.interval;
	}

  r->enddate = e_cal_recur_obtain_enddate (&ir, prop, zone, convert_end_date);

	r->week_start_day = e_cal_recur_ical_weekday_to_weekday (ir.week_start);

	r->bymonth = array_to_list (ir.by_month, G_N_ELEMENTS (ir.by_month));
	for (elem = r->bymonth; elem; elem = elem->next) {
		/* We need to convert from 1-12 to 0-11, i.e. subtract 1. */
		gint month = GPOINTER_TO_INT (elem->data) - 1;
		elem->data = GINT_TO_POINTER (month);
	}

	r->byweekno = array_to_list (ir.by_week_no, G_N_ELEMENTS (ir.by_week_no));

	r->byyearday = array_to_list (ir.by_year_day, G_N_ELEMENTS (ir.by_year_day));

	r->bymonthday = array_to_list (ir.by_month_day, G_N_ELEMENTS (ir.by_month_day));

	/* FIXME: libical only supports 8 values, out of possible 107 * 7. */
	r->byday = NULL;
	max_elements = G_N_ELEMENTS (ir.by_day);
	for (i = 0; i < max_elements && ir.by_day[i] != ICAL_RECURRENCE_ARRAY_MAX; i++) {
		enum icalrecurrencetype_weekday day;
		gint weeknum, weekday;

		day = icalrecurrencetype_day_day_of_week (ir.by_day[i]);
		weeknum = icalrecurrencetype_day_position (ir.by_day[i]);

		weekday = e_cal_recur_ical_weekday_to_weekday (day);

		r->byday = g_list_prepend (
			r->byday,
			GINT_TO_POINTER (weeknum));
		r->byday = g_list_prepend (
			r->byday,
			GINT_TO_POINTER (weekday));
	}

	r->byhour = array_to_list (ir.by_hour, G_N_ELEMENTS (ir.by_hour));

	r->byminute = array_to_list (ir.by_minute, G_N_ELEMENTS (ir.by_minute));

	r->bysecond = array_to_list (ir.by_second, G_N_ELEMENTS (ir.by_second));

	r->bysetpos = array_to_list (ir.by_set_pos, G_N_ELEMENTS (ir.by_set_pos));

	return r;
}

static gint
e_cal_recur_ical_weekday_to_weekday (enum icalrecurrencetype_weekday day)
{
	gint weekday;

	switch (day) {
	case ICAL_NO_WEEKDAY:		/* Monday is the default in RFC2445. */
	case ICAL_MONDAY_WEEKDAY:
		weekday = 0;
		break;
	case ICAL_TUESDAY_WEEKDAY:
		weekday = 1;
		break;
	case ICAL_WEDNESDAY_WEEKDAY:
		weekday = 2;
		break;
	case ICAL_THURSDAY_WEEKDAY:
		weekday = 3;
		break;
	case ICAL_FRIDAY_WEEKDAY:
		weekday = 4;
		break;
	case ICAL_SATURDAY_WEEKDAY:
		weekday = 5;
		break;
	case ICAL_SUNDAY_WEEKDAY:
		weekday = 6;
		break;
	default:
		g_warning (
			"e_cal_recur_ical_weekday_to_weekday(): Unknown week day %d",
			day);
		weekday = 0;
	}

	return weekday;
}

/**
 * e_cal_recur_free:
 * @r: A #ECalRecurrence structure.
 *
 * Frees a #ECalRecurrence structure.
 **/
static void
e_cal_recur_free (ECalRecurrence *r)
{
	g_return_if_fail (r != NULL);

	g_list_free (r->bymonth);
	g_list_free (r->byweekno);
	g_list_free (r->byyearday);
	g_list_free (r->bymonthday);
	g_list_free (r->byday);
	g_list_free (r->byhour);
	g_list_free (r->byminute);
	g_list_free (r->bysecond);
	g_list_free (r->bysetpos);

	g_free (r);
}

/* Generates one year's worth of recurrence instances.  Returns TRUE if all the
 * callback invocations returned TRUE, or FALSE when any one of them returns
 * FALSE, i.e. meaning that the instance generation should be stopped.
 *
 * This should only output instances whose start time is between chunk_start
 * and chunk_end (inclusive), or we may generate duplicates when we do the next
 * chunk. (This applies mainly to weekly recurrences, since weeks can span 2
 * years.)
 *
 * It should also only output instances that are on or after the event's
 * DTSTART property and that intersect the required interval, between
 * interval_start and interval_end.
 */
static gboolean
generate_instances_for_chunk (ECalComponent *comp,
                              time_t comp_dtstart,
                              icaltimezone *zone,
                              GSList *rrules,
                              GSList *rdates,
                              GSList *exrules,
                              GSList *exdates,
                              gboolean single_rule,
                              CalObjTime *event_start,
                              time_t interval_start,
                              CalObjTime *chunk_start,
                              CalObjTime *chunk_end,
                              gint duration_days,
                              gint duration_seconds,
                              gboolean convert_end_date,
                              ECalRecurInstanceFn cb,
                              gpointer cb_data)
{
	GArray *occs, *ex_occs, *tmp_occs, *rdate_periods;
	CalObjTime cotime, *occ;
	GSList *elem;
	gint i;
	time_t start_time, end_time;
	struct icaltimetype start_tt, end_tt;
	gboolean cb_status = TRUE, rule_finished, finished = TRUE;

#if 0
	g_print (
		"In generate_instances_for_chunk rrules: %p\n"
		"  %i/%i/%i %02i:%02i:%02i - %i/%i/%i %02i:%02i:%02i\n",
		rrules,
		chunk_start->day, chunk_start->month + 1,
		chunk_start->year, chunk_start->hour,
		chunk_start->minute, chunk_start->second,
		chunk_end->day, chunk_end->month + 1,
		chunk_end->year, chunk_end->hour,
		chunk_end->minute, chunk_end->second);
#endif

	occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
	ex_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
	rdate_periods = g_array_new (
		FALSE, FALSE,
		sizeof (CalObjRecurrenceDate));

	/* The original DTSTART property is included in the occurrence set,
	 * but not if we are just generating occurrences for a single rule. */
	if (!single_rule) {
		/* We add it if it is in this chunk. If it is after this chunk
		 * we set finished to FALSE, since we know we aren't finished
		 * yet. */
		if (cal_obj_time_compare_func (event_start, chunk_end) >= 0)
			finished = FALSE;
		else if (cal_obj_time_compare_func (event_start, chunk_start) >= 0)
			g_array_append_vals (occs, event_start, 1);
	}

	/* Expand each of the recurrence rules. */
	for (elem = rrules; elem; elem = elem->next) {
		icalproperty *prop;
		ECalRecurrence *r;

		prop = elem->data;
		r = e_cal_recur_from_icalproperty (
			prop, FALSE, zone,
			convert_end_date);

		tmp_occs = cal_obj_expand_recurrence (
			event_start, zone, r,
			chunk_start,
			chunk_end,
			&rule_finished);
		e_cal_recur_free (r);

		/* If any of the rules return FALSE for finished, we know we
		 * have to carry on so we set finished to FALSE. */
		if (!rule_finished)
			finished = FALSE;

		g_array_append_vals (occs, tmp_occs->data, tmp_occs->len);
		g_array_free (tmp_occs, TRUE);
	}

	/* Add on specific RDATE occurrence dates. If they have an end time
	 * or duration set, flag them as RDATEs, and store a pointer to the
	 * period in the rdate_periods array. Otherwise we can just treat them
	 * as normal occurrences. */
	for (elem = rdates; elem; elem = elem->next) {
		ECalComponentPeriod *p;
		CalObjRecurrenceDate rdate;
		struct icaltimetype tt;

		p = elem->data;

		tt = icaltime_convert_to_zone (p->start, zone);
		cotime.year = tt.year;
		cotime.month = tt.month - 1;
		cotime.day = tt.day;
		cotime.hour = tt.hour;
		cotime.minute = tt.minute;
		cotime.second = tt.second;
		cotime.flags = FALSE;

		/* If the rdate is after the current chunk we set finished
		 * to FALSE, and we skip it. */
		if (cal_obj_time_compare_func (&cotime, chunk_end) >= 0) {
			finished = FALSE;
			continue;
		}

		/* Check if the end date or duration is set. If it is we need
		 * to store it so we can get it later. (libical seems to set
		 * second to -1 to denote an unset time. See icalvalue.c)
		 * FIXME. */
		if (p->type != E_CAL_COMPONENT_PERIOD_DATETIME
		    || p->u.end.second != -1) {
			cotime.flags = TRUE;

			rdate.start = cotime;
			rdate.period = p;
			g_array_append_val (rdate_periods, rdate);
		}

		g_array_append_val (occs, cotime);
	}

	/* Expand each of the exception rules. */
	for (elem = exrules; elem; elem = elem->next) {
		icalproperty *prop;
		ECalRecurrence *r;

		prop = elem->data;
		r = e_cal_recur_from_icalproperty (
			prop, FALSE, zone,
			convert_end_date);

		tmp_occs = cal_obj_expand_recurrence (
			event_start, zone, r,
			chunk_start,
			chunk_end,
			&rule_finished);
		e_cal_recur_free (r);

		g_array_append_vals (ex_occs, tmp_occs->data, tmp_occs->len);
		g_array_free (tmp_occs, TRUE);
	}

	/* Add on specific exception dates. */
	for (elem = exdates; elem; elem = elem->next) {
		ECalComponentDateTime *cdt;
		struct icaltimetype tt;

		cdt = elem->data;
		tt = icaltime_convert_to_zone (*cdt->value, zone);

		cotime.year = tt.year;
		cotime.month = tt.month - 1;
		cotime.day = tt.day;

		/* If the EXDATE has a DATE value, set the time to the start
		 * of the day and set flags to TRUE so we know to skip all
		 * occurrences on that date. */
		if (cdt->value->is_date) {
			cotime.hour = 0;
			cotime.minute = 0;
			cotime.second = 0;
			cotime.flags = TRUE;
		} else {
			cotime.hour = tt.hour;
			cotime.minute = tt.minute;
			cotime.second = tt.second;
			cotime.flags = FALSE;
		}

		g_array_append_val (ex_occs, cotime);
	}

	/* Sort all the arrays. */
	cal_obj_sort_occurrences (occs);
	cal_obj_sort_occurrences (ex_occs);

	if (rdate_periods->data && rdate_periods->len) {
		qsort (rdate_periods->data, rdate_periods->len,
			sizeof (CalObjRecurrenceDate), cal_obj_time_compare_func);
	}

	/* Create the final array, by removing the exceptions from the
	 * occurrences, and removing any duplicates. */
	cal_obj_remove_exceptions (occs, ex_occs);

	/* Call the callback for each occurrence. If it returns 0 we break
	 * out of the loop. */
	for (i = 0; i < occs->len; i++) {
		/* Convert each CalObjTime into a start & end time_t, and
		 * check it is within the bounds of the event & interval. */
		occ = &g_array_index (occs, CalObjTime, i);
#if 0
		g_print (
			"Checking occurrence: %s\n",
			cal_obj_time_to_string (occ));
#endif
		start_tt = icaltime_null_time ();
		start_tt.year = occ->year;
		start_tt.month = occ->month + 1;
		start_tt.day = occ->day;
		start_tt.hour = occ->hour;
		start_tt.minute = occ->minute;
		start_tt.second = occ->second;
		start_time = icaltime_as_timet_with_zone (start_tt, zone);

		if (start_time == -1) {
			g_warning ("time_t out of range");
			finished = TRUE;
			break;
		}

		/* Check to ensure that the start time is at or after the
		 * event's DTSTART time, and that it is inside the chunk that
		 * we are currently working on. (Note that the chunk_end time
		 * is never after the interval end time, so this also tests
		 * that we don't go past the end of the required interval). */
		if (start_time < comp_dtstart
		    || cal_obj_time_compare_func (occ, chunk_start) < 0
		    || cal_obj_time_compare_func (occ, chunk_end) > 0) {
#if 0
			g_print ("  start time invalid\n");
#endif
			continue;
		}

		if (occ->flags) {
			/* If it is an RDATE, we see if the end date or
			 * duration was set. If not, we use the same duration
			 * as the original occurrence. */
			if (!cal_object_get_rdate_end (occ, rdate_periods, zone)) {
				cal_obj_time_add_days (occ, duration_days);
				cal_obj_time_add_seconds (
					occ,
					duration_seconds);
			}
		} else {
			cal_obj_time_add_days (occ, duration_days);
			cal_obj_time_add_seconds (occ, duration_seconds);
		}

		end_tt = icaltime_null_time ();
		end_tt.year = occ->year;
		end_tt.month = occ->month + 1;
		end_tt.day = occ->day;
		end_tt.hour = occ->hour;
		end_tt.minute = occ->minute;
		end_tt.second = occ->second;
		end_time = icaltime_as_timet_with_zone (end_tt, zone);

		if (end_time == -1) {
			g_warning ("time_t out of range");
			finished = TRUE;
			break;
		}

		/* Check that the end time is after the interval start, so we
		 * know that it intersects the required interval. */
		if (end_time <= interval_start) {
#if 0
			g_print ("  end time invalid\n");
#endif
			continue;
		}

		cb_status = (*cb) (comp, start_time, end_time, cb_data);
		if (!cb_status)
			break;
	}

	g_array_free (occs, TRUE);
	g_array_free (ex_occs, TRUE);
	g_array_free (rdate_periods, TRUE);

	/* We return TRUE (i.e. carry on) only if the callback has always
	 * returned TRUE and we know that we have more occurrences to generate
	 * (i.e. finished is FALSE). */
	return cb_status && !finished;
}

/* This looks up the occurrence time in the sorted rdate_periods array, and
 * tries to compute the end time of the occurrence. If no end time or duration
 * is set it returns FALSE and the default duration will be used. */
static gboolean
cal_object_get_rdate_end (CalObjTime *occ,
                          GArray *rdate_periods,
                          icaltimezone *zone)
{
	CalObjRecurrenceDate *rdate = NULL;
	ECalComponentPeriod *p;
	gint lower, upper, middle, cmp = 0;

	lower = 0;
	upper = rdate_periods->len;

	while (lower < upper) {
		middle = (lower + upper) >> 1;

		rdate = &g_array_index (rdate_periods, CalObjRecurrenceDate,
					middle);

		cmp = cal_obj_time_compare_func (occ, &rdate->start);

		if (cmp == 0)
			break;
		else if (cmp < 0)
			upper = middle;
		else
			lower = middle + 1;
	}

	/* This should never happen. */
	if (cmp == 0) {
		#ifdef CAL_OBJ_DEBUG
		g_debug ("%s: Recurrence date %s not found", G_STRFUNC, cal_obj_time_to_string (cc));
		#endif
		return FALSE;
	}

	p = rdate->period;
	if (p->type == E_CAL_COMPONENT_PERIOD_DATETIME) {
		struct icaltimetype tt =
			icaltime_convert_to_zone (p->u.end, zone);
		occ->year = tt.year;
		occ->month = tt.month - 1;
		occ->day = tt.day;
		occ->hour = tt.hour;
		occ->minute = tt.minute;
		occ->second = tt.second;
		occ->flags = FALSE;
	} else {
		cal_obj_time_add_days (
			occ,
			p->u.duration.weeks * 7 +
			p->u.duration.days);
		cal_obj_time_add_hours (occ, p->u.duration.hours);
		cal_obj_time_add_minutes (occ, p->u.duration.minutes);
		cal_obj_time_add_seconds (occ, p->u.duration.seconds);
	}

	return TRUE;
}

static void
cal_object_compute_duration (CalObjTime *start,
                             CalObjTime *end,
                             gint *days,
                             gint *seconds)
{
	GDate start_date, end_date;
	gint start_seconds, end_seconds;

	g_date_clear (&start_date, 1);
	g_date_clear (&end_date, 1);
	g_date_set_dmy (
		&start_date, start->day, start->month + 1, start->year);
	g_date_set_dmy (
		&end_date, end->day, end->month + 1, end->year);

	*days = g_date_get_julian (&end_date) - g_date_get_julian (&start_date);
	start_seconds = start->hour * 3600 + start->minute * 60
		+ start->second;
	end_seconds = end->hour * 3600 + end->minute * 60 + end->second;

	*seconds = end_seconds - start_seconds;
	if (*seconds < 0) {
		*days = *days - 1;
		*seconds += 24 * 60 * 60;
	}
}

/* Returns an unsorted GArray of CalObjTime's resulting from expanding the
 * given recurrence rule within the given interval. Note that it doesn't
 * clip the generated occurrences to the interval, i.e. if the interval
 * starts part way through the year this function still returns all the
 * occurrences for the year. Clipping is done later.
 * The finished flag is set to FALSE if there are more occurrences to generate
 * after the given interval.*/
static GArray *
cal_obj_expand_recurrence (CalObjTime *event_start,
                           icaltimezone *zone,
                           ECalRecurrence *recur,
                           CalObjTime *interval_start,
                           CalObjTime *interval_end,
                           gboolean *finished)
{
	ECalRecurVTable vtable;
	CalObjTime *event_end = NULL, event_end_cotime;
	RecurData recur_data;
	CalObjTime occ, *cotime;
	GArray *all_occs, *occs;
	gint len;

	/* This is the resulting array of CalObjTime elements. */
	all_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	*finished = TRUE;

	if (!cal_obj_get_vtable (recur, &vtable))
		return all_occs;

	/* Calculate some useful data such as some fast lookup tables. */
	cal_obj_initialize_recur_data (&recur_data, recur, event_start);

	/* Compute the event_end, if the recur's enddate is set. */
	if (recur->enddate > 0) {
		cal_object_time_from_time (
			&event_end_cotime,
			recur->enddate, zone);
		event_end = &event_end_cotime;

		/* If the enddate is before the requested interval return. */
		if (cal_obj_time_compare_func (event_end, interval_start) < 0)
			return all_occs;
	}

	/* Set finished to FALSE if we know there will be more occurrences to
	 * do after this interval. */
	if (!interval_end || !event_end
	    || cal_obj_time_compare_func (event_end, interval_end) > 0)
		*finished = FALSE;

	/* Get the first period based on the frequency and the interval that
	 * intersects the interval between start and end. */
	if ((*vtable.find_start_position) (event_start, event_end,
					    &recur_data,
					    interval_start, interval_end,
					    &occ))
		return all_occs;

	/* Loop until the event ends or we go past the end of the required
	 * interval. */
	for (;;) {
		/* Generate the set of occurrences for this period. */
		switch (recur->freq) {
		case ICAL_YEARLY_RECURRENCE:
			occs = cal_obj_generate_set_yearly (
				&recur_data,
				&vtable, &occ);
			break;
		case ICAL_MONTHLY_RECURRENCE:
			occs = cal_obj_generate_set_monthly (
				&recur_data,
				&vtable, &occ);
			break;
		default:
			occs = cal_obj_generate_set_default (
				&recur_data,
				&vtable, &occ);
			break;
		}

		/* Sort the occurrences and remove duplicates. */
		cal_obj_sort_occurrences (occs);
		cal_obj_remove_duplicates_and_invalid_dates (occs);

		/* Apply the BYSETPOS property. */
		occs = cal_obj_bysetpos_filter (recur, occs);

		/* Remove any occs after event_end. */
		len = occs->len - 1;
		if (event_end) {
			while (len >= 0) {
				cotime = &g_array_index (occs, CalObjTime,
							 len);
				if (cal_obj_time_compare_func (cotime,
							       event_end) <= 0)
					break;
				len--;
			}
		}

		/* Add the occurrences onto the main array. */
		if (len >= 0)
			g_array_append_vals (all_occs, occs->data, len + 1);

		g_array_free (occs, TRUE);

		/* Skip to the next period, or exit the loop if finished. */
		if ((*vtable.find_next_position) (&occ, event_end,
						   &recur_data, interval_end))
			break;
	}

	return all_occs;
}

static GArray *
cal_obj_generate_set_yearly (RecurData *recur_data,
                             ECalRecurVTable *vtable,
                             CalObjTime *occ)
{
	ECalRecurrence *recur = recur_data->recur;
	GArray *occs_arrays[4], *occs, *occs2;
	gint num_occs_arrays = 0, i;

	/* This is a bit complicated, since the iCalendar spec says that
	 * several BYxxx modifiers can be used simultaneously. So we have to
	 * be quite careful when determining the days of the occurrences.
	 * The BYHOUR, BYMINUTE & BYSECOND modifiers are no problem at all.
	 *
	 * The modifiers we have to worry about are: BYMONTH, BYWEEKNO,
	 * BYYEARDAY, BYMONTHDAY & BYDAY. We can't do these sequentially
	 * since each filter will mess up the results of the previous one.
	 * But they aren't all completely independant, e.g. BYMONTHDAY and
	 * BYDAY are related to BYMONTH, and BYDAY is related to BYWEEKNO.
	 *
	 * BYDAY & BYMONTHDAY can also be applied independently, which makes
	 * it worse. So we assume that if BYMONTH or BYWEEKNO is used, then
	 * the BYDAY modifier applies to those, else it is applied
	 * independantly.
	 *
	 * We expand the occurrences in parallel into the occs_arrays[] array,
	 * and then merge them all into one GArray before expanding BYHOUR,
	 * BYMINUTE & BYSECOND. */

	if (recur->bymonth) {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);

		occs = (*vtable->bymonth_filter) (recur_data, occs);

		/* If BYMONTHDAY & BYDAY are both set we need to expand them
		 * in parallel and add the results. */
		if (recur->bymonthday && recur->byday) {
			CalObjTime *prev_occ = NULL;
			GArray *new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

			/* Copy the occs array. */
			occs2 = g_array_new (
				FALSE, FALSE,
				sizeof (CalObjTime));
			g_array_append_vals (occs2, occs->data, occs->len);

			occs = (*vtable->bymonthday_filter) (recur_data, occs);
			/* Note that we explicitly call the monthly version
			 * of the BYDAY expansion filter. */
			occs2 = cal_obj_byday_expand_monthly (
				recur_data,
				occs2);

			/* Add only intersection of those two arrays. */
			g_array_append_vals (occs, occs2->data, occs2->len);
			cal_obj_sort_occurrences (occs);
			for (i = 0; i < occs->len; i++) {
				CalObjTime *act_occ = &g_array_index (occs, CalObjTime, i);

				if (prev_occ && cal_obj_time_compare_func (act_occ, prev_occ) == 0) {
					prev_occ = NULL;
					g_array_append_vals (new_occs, act_occ, 1);
				} else {
					prev_occ = act_occ;
				}
			}

			g_array_free (occs, TRUE);
			g_array_free (occs2, TRUE);

			occs = new_occs;
		} else {
			occs = (*vtable->bymonthday_filter) (recur_data, occs);
			/* Note that we explicitly call the monthly version
			 * of the BYDAY expansion filter. */
			occs = cal_obj_byday_expand_monthly (recur_data, occs);
		}

		occs_arrays[num_occs_arrays++] = occs;
	}

	if (recur->byweekno) {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);

		occs = (*vtable->byweekno_filter) (recur_data, occs);
		/* Note that we explicitly call the weekly version of the
		 * BYDAY expansion filter. */
		occs = cal_obj_byday_expand_weekly (recur_data, occs);

		occs_arrays[num_occs_arrays++] = occs;
	}

	if (recur->byyearday) {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);

		occs = (*vtable->byyearday_filter) (recur_data, occs);

		occs_arrays[num_occs_arrays++] = occs;
	}

	/* If BYMONTHDAY is set, and BYMONTH is not set, we need to
	 * expand BYMONTHDAY independantly. */
	if (recur->bymonthday && !recur->bymonth) {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);

		occs = (*vtable->bymonthday_filter) (recur_data, occs);

		occs_arrays[num_occs_arrays++] = occs;
	}

	/* If BYDAY is set, and BYMONTH and BYWEEKNO are not set, we need to
	 * expand BYDAY independantly. */
	if (recur->byday && !recur->bymonth && !recur->byweekno) {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);

		occs = (*vtable->byday_filter) (recur_data, occs);

		occs_arrays[num_occs_arrays++] = occs;
	}

	/* Add all the arrays together. If no filters were used we just
	 * create an array with one element. */
	if (num_occs_arrays > 0) {
		occs = occs_arrays[0];
		for (i = 1; i < num_occs_arrays; i++) {
			occs2 = occs_arrays[i];
			g_array_append_vals (occs, occs2->data, occs2->len);
			g_array_free (occs2, TRUE);
		}
	} else {
		occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
		g_array_append_vals (occs, occ, 1);
	}

	/* Now expand BYHOUR, BYMINUTE & BYSECOND. */
	occs = (*vtable->byhour_filter) (recur_data, occs);
	occs = (*vtable->byminute_filter) (recur_data, occs);
	occs = (*vtable->bysecond_filter) (recur_data, occs);

	return occs;
}

static GArray *
cal_obj_generate_set_monthly (RecurData *recur_data,
                              ECalRecurVTable *vtable,
                              CalObjTime *occ)
{
	GArray *occs;

	/* We start with just the one time in each set. */
	occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
	g_array_append_vals (occs, occ, 1);

	occs = (*vtable->bymonth_filter) (recur_data, occs);

	/* We need to combine the output of BYMONTHDAY & BYDAY, by doing them
	 * in parallel rather than sequentially. If we did them sequentially
	 * then we would lose the occurrences generated by BYMONTHDAY, and
	 * instead have repetitions of the occurrences from BYDAY. */
	if (recur_data->recur->bymonthday && recur_data->recur->byday) {
		occs = (*vtable->byday_filter) (recur_data, occs);
		occs = (*vtable->bymonthday_filter) (recur_data, occs);
	} else {
		occs = (*vtable->bymonthday_filter) (recur_data, occs);
		occs = (*vtable->byday_filter) (recur_data, occs);
	}

	occs = (*vtable->byhour_filter) (recur_data, occs);
	occs = (*vtable->byminute_filter) (recur_data, occs);
	occs = (*vtable->bysecond_filter) (recur_data, occs);

	return occs;
}

static GArray *
cal_obj_generate_set_default (RecurData *recur_data,
                              ECalRecurVTable *vtable,
                              CalObjTime *occ)
{
	GArray *occs;

#if 0
	g_print (
		"Generating set for %i/%i/%i %02i:%02i:%02i\n",
		occ->day, occ->month + 1, occ->year, occ->hour, occ->minute,
		occ->second);
#endif

	/* We start with just the one time in the set. */
	occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));
	g_array_append_vals (occs, occ, 1);

	occs = (*vtable->bymonth_filter) (recur_data, occs);
	if (vtable->byweekno_filter)
		occs = (*vtable->byweekno_filter) (recur_data, occs);
	if (vtable->byyearday_filter)
		occs = (*vtable->byyearday_filter) (recur_data, occs);
	if (vtable->bymonthday_filter)
		occs = (*vtable->bymonthday_filter) (recur_data, occs);
	occs = (*vtable->byday_filter) (recur_data, occs);

	occs = (*vtable->byhour_filter) (recur_data, occs);
	occs = (*vtable->byminute_filter) (recur_data, occs);
	occs = (*vtable->bysecond_filter) (recur_data, occs);

	return occs;
}

/* Returns the function table corresponding to the recurrence frequency. */
static gboolean
cal_obj_get_vtable (ECalRecurrence *recur,
		    ECalRecurVTable *out_vtable)
{
	gboolean valid = TRUE;

	switch (recur->freq) {
	case ICAL_YEARLY_RECURRENCE:
		*out_vtable = cal_obj_yearly_vtable;
		break;
	case ICAL_MONTHLY_RECURRENCE:
		*out_vtable = cal_obj_monthly_vtable;
		if (recur->bymonthday && recur->byday)
			out_vtable->bymonthday_filter = cal_obj_bymonthday_filter;
		else
			out_vtable->bymonthday_filter = cal_obj_bymonthday_expand;
		break;
	case ICAL_WEEKLY_RECURRENCE:
		*out_vtable = cal_obj_weekly_vtable;
		break;
	case ICAL_DAILY_RECURRENCE:
		*out_vtable = cal_obj_daily_vtable;
		break;
	case ICAL_HOURLY_RECURRENCE:
		*out_vtable = cal_obj_hourly_vtable;
		break;
	case ICAL_MINUTELY_RECURRENCE:
		*out_vtable = cal_obj_minutely_vtable;
		break;
	case ICAL_SECONDLY_RECURRENCE:
		*out_vtable = cal_obj_secondly_vtable;
		break;
	default:
		g_warning ("Unknown recurrence frequency");
		valid = FALSE;
	}

	return valid;
}

/* This creates a number of fast lookup tables used when filtering with the
 * modifier properties BYMONTH, BYYEARDAY etc. */
static void
cal_obj_initialize_recur_data (RecurData *recur_data,
                               ECalRecurrence *recur,
                               CalObjTime *event_start)
{
	GList *elem;
	gint month, yearday, monthday, weekday, hour, minute, second;

	/* Clear the entire RecurData. */
	memset (recur_data, 0, sizeof (RecurData));

	recur_data->recur = recur;

	/* Set the weekday, used for the WEEKLY frequency and the BYWEEKNO
	 * modifier. */
	recur_data->weekday_offset = cal_obj_time_weekday_offset (
		event_start,
		recur);

	/* Create an array of months from bymonths for fast lookup. */
	elem = recur->bymonth;
	while (elem) {
		month = GPOINTER_TO_INT (elem->data);
		recur_data->months[month] = 1;
		elem = elem->next;
	}

	/* Create an array of yeardays from byyearday for fast lookup.
	 * We create a second array to handle the negative values. The first
	 * element there corresponds to the last day of the year. */
	elem = recur->byyearday;
	while (elem) {
		yearday = GPOINTER_TO_INT (elem->data);
		if (yearday >= 0)
			recur_data->yeardays[yearday] = 1;
		else
			recur_data->neg_yeardays[-yearday] = 1;
		elem = elem->next;
	}

	/* Create an array of monthdays from bymonthday for fast lookup.
	 * We create a second array to handle the negative values. The first
	 * element there corresponds to the last day of the month. */
	elem = recur->bymonthday;
	while (elem) {
		monthday = GPOINTER_TO_INT (elem->data);
		if (monthday >= 0)
			recur_data->monthdays[monthday] = 1;
		else
			recur_data->neg_monthdays[-monthday] = 1;
		elem = elem->next;
	}

	/* Create an array of weekdays from byday for fast lookup. */
	elem = recur->byday;
	while (elem) {
		weekday = GPOINTER_TO_INT (elem->data);
		recur_data->weekdays[weekday] = 1;
		elem = elem->next;
		/* the second element is week_num, skip it */
		if (elem)
			elem = elem->next;
	}

	/* Create an array of hours from byhour for fast lookup. */
	elem = recur->byhour;
	while (elem) {
		hour = GPOINTER_TO_INT (elem->data);
		recur_data->hours[hour] = 1;
		elem = elem->next;
	}

	/* Create an array of minutes from byminutes for fast lookup. */
	elem = recur->byminute;
	while (elem) {
		minute = GPOINTER_TO_INT (elem->data);
		recur_data->minutes[minute] = 1;
		elem = elem->next;
	}

	/* Create an array of seconds from byseconds for fast lookup. */
	elem = recur->bysecond;
	while (elem) {
		second = GPOINTER_TO_INT (elem->data);
		recur_data->seconds[second] = 1;
		elem = elem->next;
	}
}

static void
cal_obj_sort_occurrences (GArray *occs)
{
	if (occs->data && occs->len) {
		qsort (occs->data, occs->len, sizeof (CalObjTime),
			cal_obj_time_compare_func);
	}
}

static void
cal_obj_remove_duplicates_and_invalid_dates (GArray *occs)
{
	static const gint days_in_month[12] = {
		31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	};

	CalObjTime *occ, *prev_occ = NULL;
	gint len, i, j = 0, year, month, days;
	gboolean keep_occ;

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		keep_occ = TRUE;

		if (prev_occ && cal_obj_time_compare_func (occ,
							   prev_occ) == 0)
			keep_occ = FALSE;

		year = occ->year;
		month = occ->month;
		days = days_in_month[occ->month];
		/* If it is february and a leap year, add a day. */
		if (month == 1 && (year % 4 == 0
				   && (year % 100 != 0
				       || year % 400 == 0)))
			days++;

		if (occ->day > days) {
			/* move occurrence to the last day of the month */
			occ->day = days;
		}

		if (keep_occ) {
			if (i != j)
				g_array_index (occs, CalObjTime, j)
 = g_array_index (occs, CalObjTime, i);
			j++;
		}

		prev_occ = occ;
	}

	g_array_set_size (occs, j);
}

/* Removes the exceptions from the ex_occs array from the occurrences in the
 * occs array, and removes any duplicates. Both arrays are sorted. */
static void
cal_obj_remove_exceptions (GArray *occs,
                           GArray *ex_occs)
{
	CalObjTime *occ, *prev_occ = NULL, *ex_occ = NULL, *last_occ_kept;
	gint i, j = 0, cmp, ex_index, occs_len, ex_occs_len;
	gboolean keep_occ, current_time_is_exception = FALSE;

	if (occs->len == 0)
		return;

	ex_index = 0;
	occs_len = occs->len;
	ex_occs_len = ex_occs->len;

	if (ex_occs_len > 0)
		ex_occ = &g_array_index (ex_occs, CalObjTime, ex_index);

	for (i = 0; i < occs_len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		keep_occ = TRUE;

		/* If the occurrence is a duplicate of the previous one, skip
		 * it. */
		if (prev_occ
		    && cal_obj_time_compare_func (occ, prev_occ) == 0) {
			keep_occ = FALSE;

			/* If this occurrence is an RDATE with an end or
			 * duration set, and the previous occurrence in the
			 * array was kept, set the RDATE flag of the last one,
			 * so we still use the end date or duration. */
			if (occ->flags && !current_time_is_exception) {
				last_occ_kept = &g_array_index (occs,
								CalObjTime,
								j - 1);
				last_occ_kept->flags = TRUE;
			}
		} else {
			/* We've found a new occurrence time. Reset the flag
			 * to indicate that it hasn't been found in the
			 * exceptions array (yet). */
			current_time_is_exception = FALSE;

			if (ex_occ) {
				/* Step through the exceptions until we come
				 * to one that matches or follows this
				 * occurrence. */
				while (ex_occ) {
					/* If the exception is an EXDATE with
					 * a DATE value, we only have to
					 * compare the date. */
					if (ex_occ->flags)
						cmp = cal_obj_date_only_compare_func (ex_occ, occ);
					else
						cmp = cal_obj_time_compare_func (ex_occ, occ);

					if (cmp > 0)
						break;

					/* Move to the next exception, or set
					 * ex_occ to NULL when we reach the
					 * end of array. */
					ex_index++;
					if (ex_index < ex_occs_len)
						ex_occ = &g_array_index (ex_occs, CalObjTime, ex_index);
					else
						ex_occ = NULL;

					/* If the exception did match this
					 * occurrence we remove it, and set the
					 * flag to indicate that the current
					 * time is an exception. */
					if (cmp == 0) {
						current_time_is_exception = TRUE;
						keep_occ = FALSE;
						break;
					}
				}
			}
		}

		if (keep_occ) {
			/* We are keeping this occurrence, so we move it to
			 * the next free space, unless its position hasn't
			 * changed (i.e. all previous occurrences were also
			 * kept). */
			if (i != j)
				g_array_index (occs, CalObjTime, j)
 = g_array_index (occs, CalObjTime, i);
			j++;
		}

		prev_occ = occ;
	}

	g_array_set_size (occs, j);
}

static GArray *
cal_obj_bysetpos_filter (ECalRecurrence *recur,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, pos;

	/* If BYSETPOS has not been specified, or the array is empty, just
	 * return the array. */
	elem = recur->bysetpos;
	if (!elem || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	/* Iterate over the indices given in bysetpos, adding the corresponding
	 * element from occs to new_occs. */
	len = occs->len;
	while (elem) {
		pos = GPOINTER_TO_INT (elem->data);

		/* Negative values count back from the end of the array. */
		if (pos < 0)
			pos += len;
		/* Positive values need to be decremented since the array is
		 * 0 - based. */
		else
			pos--;

		if (pos >= 0 && pos < len) {
			occ = &g_array_index (occs, CalObjTime, pos);
			g_array_append_vals (new_occs, occ, 1);
		}
		elem = elem->next;
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* Finds the first year from the event_start, counting in multiples of the
 * recurrence interval, that intersects the given interval. It returns TRUE
 * if there is no intersection. */
static gboolean
cal_obj_yearly_find_start_position (CalObjTime *event_start,
                                    CalObjTime *event_end,
                                    RecurData *recur_data,
                                    CalObjTime *interval_start,
                                    CalObjTime *interval_end,
                                    CalObjTime *cotime)
{
	*cotime = *event_start;

	/* Move on to the next interval, if the event starts before the
	 * given interval. */
	if (cotime->year < interval_start->year) {
		gint years = interval_start->year - cotime->year
			+ recur_data->recur->interval - 1;
		years -= years % recur_data->recur->interval;
		/* NOTE: The day may now be invalid, e.g. 29th Feb. */
		cotime->year += years;
	}

	if ((event_end && cotime->year > event_end->year)
	    || (interval_end && cotime->year > interval_end->year))
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_yearly_find_next_position (CalObjTime *cotime,
                                   CalObjTime *event_end,
                                   RecurData *recur_data,
                                   CalObjTime *interval_end)
{
	/* NOTE: The day may now be invalid, e.g. 29th Feb. */
	cotime->year += recur_data->recur->interval;

	if ((event_end && cotime->year > event_end->year)
	    || (interval_end && cotime->year > interval_end->year))
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_monthly_find_start_position (CalObjTime *event_start,
                                     CalObjTime *event_end,
                                     RecurData *recur_data,
                                     CalObjTime *interval_start,
                                     CalObjTime *interval_end,
                                     CalObjTime *cotime)
{
	*cotime = *event_start;

	/* Move on to the next interval, if the event starts before the
	 * given interval. */
	if (cal_obj_time_compare (cotime, interval_start, CALOBJ_MONTH) < 0) {
		gint months = (interval_start->year - cotime->year) * 12
			+ interval_start->month - cotime->month
			+ recur_data->recur->interval - 1;
		months -= months % recur_data->recur->interval;
		/* NOTE: The day may now be invalid, e.g. 31st Sep. */
		cal_obj_time_add_months (cotime, months);
	}

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_MONTH) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_MONTH) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_monthly_find_next_position (CalObjTime *cotime,
                                    CalObjTime *event_end,
                                    RecurData *recur_data,
                                    CalObjTime *interval_end)
{
	/* NOTE: The day may now be invalid, e.g. 31st Sep. */
	cal_obj_time_add_months (cotime, recur_data->recur->interval);

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_MONTH) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_MONTH) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_weekly_find_start_position (CalObjTime *event_start,
                                    CalObjTime *event_end,
                                    RecurData *recur_data,
                                    CalObjTime *interval_start,
                                    CalObjTime *interval_end,
                                    CalObjTime *cotime)
{
	GDate event_start_date, interval_start_date;
	guint32 event_start_julian, interval_start_julian;
	gint interval_start_weekday_offset;
	CalObjTime week_start;

	if (event_end && cal_obj_time_compare (event_end, interval_start,
					       CALOBJ_DAY) < 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (event_start, interval_end,
						  CALOBJ_DAY) > 0)
		return TRUE;

	*cotime = *event_start;

	/* Convert the event start and interval start to GDates, so we can
	 * easily find the number of days between them. */
	g_date_clear (&event_start_date, 1);
	g_date_set_dmy (
		&event_start_date, event_start->day,
		event_start->month + 1, event_start->year);
	g_date_clear (&interval_start_date, 1);
	g_date_set_dmy (
		&interval_start_date, interval_start->day,
		interval_start->month + 1, interval_start->year);

	/* Calculate the start of the weeks corresponding to the event start
	 * and interval start. */
	event_start_julian = g_date_get_julian (&event_start_date);
	event_start_julian -= recur_data->weekday_offset;

	interval_start_julian = g_date_get_julian (&interval_start_date);
	interval_start_weekday_offset = cal_obj_time_weekday_offset (interval_start, recur_data->recur);
	interval_start_julian -= interval_start_weekday_offset;

	/* We want to find the first full week using the recurrence interval
	 * that intersects the given interval dates. */
	if (event_start_julian < interval_start_julian) {
		gint weeks = (interval_start_julian - event_start_julian) / 7;
		weeks += recur_data->recur->interval - 1;
		weeks -= weeks % recur_data->recur->interval;
		cal_obj_time_add_days (cotime, weeks * 7);
	}

	week_start = *cotime;
	cal_obj_time_add_days (&week_start, -recur_data->weekday_offset);

	if (event_end && cal_obj_time_compare (&week_start, event_end,
					       CALOBJ_DAY) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (&week_start, interval_end,
						  CALOBJ_DAY) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_weekly_find_next_position (CalObjTime *cotime,
                                   CalObjTime *event_end,
                                   RecurData *recur_data,
                                   CalObjTime *interval_end)
{
	CalObjTime week_start;

	cal_obj_time_add_days (cotime, recur_data->recur->interval * 7);

	/* Return TRUE if the start of this week is after the event finishes
	 * or is after the end of the required interval. */
	week_start = *cotime;
	cal_obj_time_add_days (&week_start, -recur_data->weekday_offset);

#ifdef CAL_OBJ_DEBUG
	g_print ("Next  day: %s\n", cal_obj_time_to_string (cotime));
	g_print ("Week Start: %s\n", cal_obj_time_to_string (&week_start));
#endif

	if (event_end && cal_obj_time_compare (&week_start, event_end,
					       CALOBJ_DAY) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (&week_start, interval_end,
						  CALOBJ_DAY) > 0) {
#ifdef CAL_OBJ_DEBUG
		g_print (
			"Interval end reached: %s\n",
			cal_obj_time_to_string (interval_end));
#endif
		return TRUE;
	}

	return FALSE;
}

static gboolean
cal_obj_daily_find_start_position (CalObjTime *event_start,
                                   CalObjTime *event_end,
                                   RecurData *recur_data,
                                   CalObjTime *interval_start,
                                   CalObjTime *interval_end,
                                   CalObjTime *cotime)
{
	GDate event_start_date, interval_start_date;
	guint32 event_start_julian, interval_start_julian, days;

	if (interval_end && cal_obj_time_compare (event_start, interval_end,
						  CALOBJ_DAY) > 0)
		return TRUE;
	if (event_end && cal_obj_time_compare (event_end, interval_start,
					       CALOBJ_DAY) < 0)
		return TRUE;

	*cotime = *event_start;

	/* Convert the event start and interval start to GDates, so we can
	 * easily find the number of days between them. */
	g_date_clear (&event_start_date, 1);
	g_date_set_dmy (
		&event_start_date, event_start->day,
		event_start->month + 1, event_start->year);
	g_date_clear (&interval_start_date, 1);
	g_date_set_dmy (
		&interval_start_date, interval_start->day,
		interval_start->month + 1, interval_start->year);

	event_start_julian = g_date_get_julian (&event_start_date);
	interval_start_julian = g_date_get_julian (&interval_start_date);

	if (event_start_julian < interval_start_julian) {
		days = interval_start_julian - event_start_julian
			+ recur_data->recur->interval - 1;
		days -= days % recur_data->recur->interval;
		cal_obj_time_add_days (cotime, days);
	}

	if (event_end && cal_obj_time_compare (cotime, event_end, CALOBJ_DAY) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end, CALOBJ_DAY) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_daily_find_next_position (CalObjTime *cotime,
                                  CalObjTime *event_end,
                                  RecurData *recur_data,
                                  CalObjTime *interval_end)
{
	cal_obj_time_add_days (cotime, recur_data->recur->interval);

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_DAY) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_DAY) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_hourly_find_start_position (CalObjTime *event_start,
                                    CalObjTime *event_end,
                                    RecurData *recur_data,
                                    CalObjTime *interval_start,
                                    CalObjTime *interval_end,
                                    CalObjTime *cotime)
{
	GDate event_start_date, interval_start_date;
	guint32 event_start_julian, interval_start_julian, hours;

	if (interval_end && cal_obj_time_compare (event_start, interval_end,
						  CALOBJ_HOUR) > 0)
		return TRUE;
	if (event_end && cal_obj_time_compare (event_end, interval_start,
					       CALOBJ_HOUR) < 0)
		return TRUE;

	*cotime = *event_start;

	if (cal_obj_time_compare (event_start, interval_start,
				  CALOBJ_HOUR) < 0) {
		/* Convert the event start and interval start to GDates, so we
		 * can easily find the number of days between them. */
		g_date_clear (&event_start_date, 1);
		g_date_set_dmy (
			&event_start_date, event_start->day,
			event_start->month + 1, event_start->year);
		g_date_clear (&interval_start_date, 1);
		g_date_set_dmy (
			&interval_start_date, interval_start->day,
			interval_start->month + 1,
			interval_start->year);

		event_start_julian = g_date_get_julian (&event_start_date);
		interval_start_julian = g_date_get_julian (&interval_start_date);

		hours = (interval_start_julian - event_start_julian) * 24;
		hours += interval_start->hour - event_start->hour;
		hours += recur_data->recur->interval - 1;
		hours -= hours % recur_data->recur->interval;
		cal_obj_time_add_hours (cotime, hours);
	}

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_HOUR) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_HOUR) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_hourly_find_next_position (CalObjTime *cotime,
                                   CalObjTime *event_end,
                                   RecurData *recur_data,
                                   CalObjTime *interval_end)
{
	cal_obj_time_add_hours (cotime, recur_data->recur->interval);

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_HOUR) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_HOUR) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_minutely_find_start_position (CalObjTime *event_start,
                                      CalObjTime *event_end,
                                      RecurData *recur_data,
                                      CalObjTime *interval_start,
                                      CalObjTime *interval_end,
                                      CalObjTime *cotime)
{
	GDate event_start_date, interval_start_date;
	guint32 event_start_julian, interval_start_julian, minutes;

	if (interval_end && cal_obj_time_compare (event_start, interval_end,
						  CALOBJ_MINUTE) > 0)
		return TRUE;
	if (event_end && cal_obj_time_compare (event_end, interval_start,
					       CALOBJ_MINUTE) < 0)
		return TRUE;

	*cotime = *event_start;

	if (cal_obj_time_compare (event_start, interval_start,
				  CALOBJ_MINUTE) < 0) {
		/* Convert the event start and interval start to GDates, so we
		 * can easily find the number of days between them. */
		g_date_clear (&event_start_date, 1);
		g_date_set_dmy (
			&event_start_date, event_start->day,
			event_start->month + 1, event_start->year);
		g_date_clear (&interval_start_date, 1);
		g_date_set_dmy (
			&interval_start_date, interval_start->day,
			interval_start->month + 1,
			interval_start->year);

		event_start_julian = g_date_get_julian (&event_start_date);
		interval_start_julian = g_date_get_julian (&interval_start_date);

		minutes = (interval_start_julian - event_start_julian)
			* 24 * 60;
		minutes += (interval_start->hour - event_start->hour) * 24;
		minutes += interval_start->minute - event_start->minute;
		minutes += recur_data->recur->interval - 1;
		minutes -= minutes % recur_data->recur->interval;
		cal_obj_time_add_minutes (cotime, minutes);
	}

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_MINUTE) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_MINUTE) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_minutely_find_next_position (CalObjTime *cotime,
                                     CalObjTime *event_end,
                                     RecurData *recur_data,
                                     CalObjTime *interval_end)
{
	cal_obj_time_add_minutes (cotime, recur_data->recur->interval);

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_MINUTE) > 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_MINUTE) > 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_secondly_find_start_position (CalObjTime *event_start,
                                      CalObjTime *event_end,
                                      RecurData *recur_data,
                                      CalObjTime *interval_start,
                                      CalObjTime *interval_end,
                                      CalObjTime *cotime)
{
	GDate event_start_date, interval_start_date;
	guint32 event_start_julian, interval_start_julian, seconds;

	if (interval_end && cal_obj_time_compare (event_start, interval_end,
						  CALOBJ_SECOND) > 0)
		return TRUE;
	if (event_end && cal_obj_time_compare (event_end, interval_start,
					       CALOBJ_SECOND) < 0)
		return TRUE;

	*cotime = *event_start;

	if (cal_obj_time_compare (event_start, interval_start,
				  CALOBJ_SECOND) < 0) {
		/* Convert the event start and interval start to GDates, so we
		 * can easily find the number of days between them. */
		g_date_clear (&event_start_date, 1);
		g_date_set_dmy (
			&event_start_date, event_start->day,
			event_start->month + 1, event_start->year);
		g_date_clear (&interval_start_date, 1);
		g_date_set_dmy (
			&interval_start_date, interval_start->day,
			interval_start->month + 1,
			interval_start->year);

		event_start_julian = g_date_get_julian (&event_start_date);
		interval_start_julian = g_date_get_julian (&interval_start_date);

		seconds = (interval_start_julian - event_start_julian)
			* 24 * 60 * 60;
		seconds += (interval_start->hour - event_start->hour)
			* 24 * 60;
		seconds += (interval_start->minute - event_start->minute) * 60;
		seconds += interval_start->second - event_start->second;
		seconds += recur_data->recur->interval - 1;
		seconds -= seconds % recur_data->recur->interval;
		cal_obj_time_add_seconds (cotime, seconds);
	}

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_SECOND) >= 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_SECOND) >= 0)
		return TRUE;

	return FALSE;
}

static gboolean
cal_obj_secondly_find_next_position (CalObjTime *cotime,
                                     CalObjTime *event_end,
                                     RecurData *recur_data,
                                     CalObjTime *interval_end)
{
	cal_obj_time_add_seconds (cotime, recur_data->recur->interval);

	if (event_end && cal_obj_time_compare (cotime, event_end,
					       CALOBJ_SECOND) >= 0)
		return TRUE;
	if (interval_end && cal_obj_time_compare (cotime, interval_end,
						  CALOBJ_SECOND) >= 0)
		return TRUE;

	return FALSE;
}

/* If the BYMONTH rule is specified it expands each occurrence in occs, by
 * using each of the months in the bymonth list. */
static GArray *
cal_obj_bymonth_expand (RecurData *recur_data,
                        GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i;

	/* If BYMONTH has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bymonth || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->bymonth;
		while (elem) {
			/* NOTE: The day may now be invalid, e.g. 31st Feb. */
			occ->month = GPOINTER_TO_INT (elem->data);
			g_array_append_vals (new_occs, occ, 1);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYMONTH rule is specified it filters out all occurrences in occs
 * which do not match one of the months in the bymonth list. */
static GArray *
cal_obj_bymonth_filter (RecurData *recur_data,
                        GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i;

	/* If BYMONTH has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bymonth || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		if (recur_data->months[occ->month])
			g_array_append_vals (new_occs, occ, 1);
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_byweekno_expand (RecurData *recur_data,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ, year_start_cotime, year_end_cotime, cotime;
	GList *elem;
	gint len, i, weekno;

	/* If BYWEEKNO has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byweekno || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		/* Find the day that would correspond to week 1 (note that
		 * week 1 is the first week starting from the specified week
		 * start day that has 4 days in the new year). */
		year_start_cotime = *occ;
		cal_obj_time_find_first_week (
			&year_start_cotime,
			recur_data);

		/* Find the day that would correspond to week 1 of the next
		 * year, which we use for -ve week numbers. */
		year_end_cotime = *occ;
		year_end_cotime.year++;
		cal_obj_time_find_first_week (
			&year_end_cotime,
			recur_data);

		/* Now iterate over the week numbers in byweekno, generating a
		 * new occurrence for each one. */
		elem = recur_data->recur->byweekno;
		while (elem) {
			weekno = GPOINTER_TO_INT (elem->data);
			if (weekno > 0) {
				cotime = year_start_cotime;
				cal_obj_time_add_days (
					&cotime,
					(weekno - 1) * 7);
			} else {
				cotime = year_end_cotime;
				cal_obj_time_add_days (&cotime, weekno * 7);
			}

			/* Skip occurrences if they fall outside the year. */
			if (cotime.year == occ->year)
				g_array_append_val (new_occs, cotime);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_byyearday_expand (RecurData *recur_data,
                          GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ, year_start_cotime, year_end_cotime, cotime;
	GList *elem;
	gint len, i, dayno;

	/* If BYYEARDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byyearday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		/* Find the day that would correspond to day 1. */
		year_start_cotime = *occ;
		year_start_cotime.month = 0;
		year_start_cotime.day = 1;

		/* Find the day that would correspond to day 1 of the next
		 * year, which we use for -ve day numbers. */
		year_end_cotime = *occ;
		year_end_cotime.year++;
		year_end_cotime.month = 0;
		year_end_cotime.day = 1;

		/* Now iterate over the day numbers in byyearday, generating a
		 * new occurrence for each one. */
		elem = recur_data->recur->byyearday;
		while (elem) {
			dayno = GPOINTER_TO_INT (elem->data);
			if (dayno > 0) {
				cotime = year_start_cotime;
				cal_obj_time_add_days (&cotime, dayno - 1);
			} else {
				cotime = year_end_cotime;
				cal_obj_time_add_days (&cotime, dayno);
			}

			/* Skip occurrences if they fall outside the year. */
			if (cotime.year == occ->year)
				g_array_append_val (new_occs, cotime);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* Note: occs must not contain invalid dates, e.g. 31st September. */
static GArray *
cal_obj_byyearday_filter (RecurData *recur_data,
                          GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint yearday, len, i, days_in_year;

	/* If BYYEARDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byyearday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		yearday = cal_obj_time_day_of_year (occ);
		if (recur_data->yeardays[yearday]) {
			g_array_append_vals (new_occs, occ, 1);
		} else {
			days_in_year = g_date_is_leap_year (occ->year)
				? 366 : 365;
			if (recur_data->neg_yeardays[days_in_year + 1
						    - yearday])
				g_array_append_vals (new_occs, occ, 1);
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_bymonthday_expand (RecurData *recur_data,
                           GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ, month_start_cotime, month_end_cotime, cotime;
	GList *elem;
	gint len, i, dayno;

	/* If BYMONTHDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bymonthday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		/* Find the day that would correspond to day 1. */
		month_start_cotime = *occ;
		month_start_cotime.day = 1;

		/* Find the day that would correspond to day 1 of the next
		 * month, which we use for -ve day numbers. */
		month_end_cotime = *occ;
		month_end_cotime.month++;
		month_end_cotime.day = 1;

		/* Now iterate over the day numbers in bymonthday, generating a
		 * new occurrence for each one. */
		elem = recur_data->recur->bymonthday;
		while (elem) {
			dayno = GPOINTER_TO_INT (elem->data);
			if (dayno > 0) {
				cotime = month_start_cotime;
				cal_obj_time_add_days (&cotime, dayno - 1);
			} else {
				cotime = month_end_cotime;
				cal_obj_time_add_days (&cotime, dayno);
			}
			if (cotime.month == occ->month) {
				g_array_append_val (new_occs, cotime);
			} else {
				/* set to last day in month */
				cotime.month = occ->month;
				cotime.day = time_days_in_month (occ->year, occ->month);
				g_array_append_val (new_occs, cotime);
			}

			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_bymonthday_filter (RecurData *recur_data,
                           GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i, days_in_month;

	/* If BYMONTHDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bymonthday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		if (recur_data->monthdays[occ->day]) {
			g_array_append_vals (new_occs, occ, 1);
		} else {
			days_in_month = time_days_in_month (
				occ->year,
				occ->month);
			if (recur_data->neg_monthdays[days_in_month + 1 - occ->day])
				g_array_append_vals (new_occs, occ, 1);
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_byday_expand_yearly (RecurData *recur_data,
                             GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i, weekday, week_num;
	gint first_weekday, last_weekday, offset;
	guint16 year;

	/* If BYDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->byday;
		while (elem) {
			weekday = GPOINTER_TO_INT (elem->data);
			elem = elem->next;
			week_num = GPOINTER_TO_INT (elem->data);
			elem = elem->next;

			year = occ->year;
			if (week_num == 0) {
				/* Expand to every Mon/Tue/etc. in the year. */
				occ->month = 0;
				occ->day = 1;
				first_weekday = cal_obj_time_weekday (occ);
				offset = (weekday + 7 - first_weekday) % 7;
				cal_obj_time_add_days (occ, offset);

				while (occ->year == year) {
					g_array_append_vals (new_occs, occ, 1);
					cal_obj_time_add_days (occ, 7);
				}

			} else if (week_num > 0) {
				/* Add the nth Mon/Tue/etc. in the year. */
				occ->month = 0;
				occ->day = 1;
				first_weekday = cal_obj_time_weekday (occ);
				offset = (weekday + 7 - first_weekday) % 7;
				offset += (week_num - 1) * 7;
				cal_obj_time_add_days (occ, offset);
				if (occ->year == year)
					g_array_append_vals (new_occs, occ, 1);

			} else {
				/* Add the -nth Mon/Tue/etc. in the year. */
				occ->month = 11;
				occ->day = 31;
				last_weekday = cal_obj_time_weekday (occ);
				offset = (last_weekday + 7 - weekday) % 7;
				offset += (week_num - 1) * 7;
				cal_obj_time_add_days (occ, -offset);
				if (occ->year == year)
					g_array_append_vals (new_occs, occ, 1);
			}

			/* Reset the year, as we may have gone past the end. */
			occ->year = year;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

static GArray *
cal_obj_byday_expand_monthly (RecurData *recur_data,
                              GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i, weekday, week_num;
	gint first_weekday, last_weekday, offset;
	guint16 year;
	guint8 month;

	/* If BYDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->byday;
		while (elem) {
			weekday = GPOINTER_TO_INT (elem->data);
			elem = elem->next;
			week_num = GPOINTER_TO_INT (elem->data);
			elem = elem->next;

			year = occ->year;
			month = occ->month;
			if (week_num == 0) {
				/* Expand to every Mon/Tue/etc. in the month.*/
				occ->day = 1;
				first_weekday = cal_obj_time_weekday (occ);
				offset = (weekday + 7 - first_weekday) % 7;
				cal_obj_time_add_days (occ, offset);

				while (occ->year == year
				       && occ->month == month) {
					g_array_append_vals (new_occs, occ, 1);
					cal_obj_time_add_days (occ, 7);
				}

			} else if (week_num > 0) {
				/* Add the nth Mon/Tue/etc. in the month. */
				occ->day = 1;
				first_weekday = cal_obj_time_weekday (occ);
				offset = (weekday + 7 - first_weekday) % 7;
				offset += (week_num - 1) * 7;
				cal_obj_time_add_days (occ, offset);
				if (occ->year == year && occ->month == month)
					g_array_append_vals (new_occs, occ, 1);

			} else {
				/* Add the -nth Mon/Tue/etc. in the month. */
				occ->day = time_days_in_month (
					occ->year,
					occ->month);
				last_weekday = cal_obj_time_weekday (occ);

				/* This calculates the number of days to step
				 * backwards from the last day of the month
				 * to the weekday we want. */
				offset = (last_weekday + 7 - weekday) % 7;

				/* This adds on the weeks. */
				offset += (-week_num - 1) * 7;

				cal_obj_time_add_days (occ, -offset);
				if (occ->year == year && occ->month == month)
					g_array_append_vals (new_occs, occ, 1);
			}

			/* Reset the year & month, as we may have gone past
			 * the end. */
			occ->year = year;
			occ->month = month;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* Note: occs must not contain invalid dates, e.g. 31st September. */
static GArray *
cal_obj_byday_expand_weekly (RecurData *recur_data,
                             GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i, weekday;
	gint weekday_offset, new_weekday_offset;

	/* If BYDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->byday;
		while (elem) {
			weekday = GPOINTER_TO_INT (elem->data);
			elem = elem->next;

			/* FIXME: Currently we just ignore this, but maybe we
			 * should skip all elements where week_num != 0.
			 * The spec isn't clear about this. */
			/*week_num = GPOINTER_TO_INT (elem->data);*/
			elem = elem->next;

			weekday_offset = cal_obj_time_weekday_offset (occ, recur_data->recur);
			new_weekday_offset = (weekday + 7 - recur_data->recur->week_start_day) % 7;
			cal_obj_time_add_days (occ, new_weekday_offset - weekday_offset);
			g_array_append_vals (new_occs, occ, 1);
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* Note: occs must not contain invalid dates, e.g. 31st September. */
static GArray *
cal_obj_byday_filter (RecurData *recur_data,
                      GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i, weekday;

	/* If BYDAY has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byday || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		weekday = cal_obj_time_weekday (occ);

		/* See if the weekday on its own is set. */
		if (recur_data->weekdays[weekday])
			g_array_append_vals (new_occs, occ, 1);
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYHOUR rule is specified it expands each occurrence in occs, by
 * using each of the hours in the byhour list. */
static GArray *
cal_obj_byhour_expand (RecurData *recur_data,
                       GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i;

	/* If BYHOUR has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byhour || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->byhour;
		while (elem) {
			occ->hour = GPOINTER_TO_INT (elem->data);
			g_array_append_vals (new_occs, occ, 1);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYHOUR rule is specified it filters out all occurrences in occs
 * which do not match one of the hours in the byhour list. */
static GArray *
cal_obj_byhour_filter (RecurData *recur_data,
                       GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i;

	/* If BYHOUR has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byhour || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		if (recur_data->hours[occ->hour])
			g_array_append_vals (new_occs, occ, 1);
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYMINUTE rule is specified it expands each occurrence in occs, by
 * using each of the minutes in the byminute list. */
static GArray *
cal_obj_byminute_expand (RecurData *recur_data,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i;

	/* If BYMINUTE has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byminute || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->byminute;
		while (elem) {
			occ->minute = GPOINTER_TO_INT (elem->data);
			g_array_append_vals (new_occs, occ, 1);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYMINUTE rule is specified it filters out all occurrences in occs
 * which do not match one of the minutes in the byminute list. */
static GArray *
cal_obj_byminute_filter (RecurData *recur_data,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i;

	/* If BYMINUTE has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->byminute || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		if (recur_data->minutes[occ->minute])
			g_array_append_vals (new_occs, occ, 1);
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYSECOND rule is specified it expands each occurrence in occs, by
 * using each of the seconds in the bysecond list. */
static GArray *
cal_obj_bysecond_expand (RecurData *recur_data,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	GList *elem;
	gint len, i;

	/* If BYSECOND has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bysecond || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);

		elem = recur_data->recur->bysecond;
		while (elem) {
			occ->second = GPOINTER_TO_INT (elem->data);
			g_array_append_vals (new_occs, occ, 1);
			elem = elem->next;
		}
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* If the BYSECOND rule is specified it filters out all occurrences in occs
 * which do not match one of the seconds in the bysecond list. */
static GArray *
cal_obj_bysecond_filter (RecurData *recur_data,
                         GArray *occs)
{
	GArray *new_occs;
	CalObjTime *occ;
	gint len, i;

	/* If BYSECOND has not been specified, or the array is empty, just
	 * return the array. */
	if (!recur_data->recur->bysecond || occs->len == 0)
		return occs;

	new_occs = g_array_new (FALSE, FALSE, sizeof (CalObjTime));

	len = occs->len;
	for (i = 0; i < len; i++) {
		occ = &g_array_index (occs, CalObjTime, i);
		if (recur_data->seconds[occ->second])
			g_array_append_vals (new_occs, occ, 1);
	}

	g_array_free (occs, TRUE);

	return new_occs;
}

/* Adds a positive or negative number of months to the given CalObjTime,
 * updating the year appropriately so we end up with a valid month.
 * Note that the day may be invalid, e.g. 30th Feb. */
static void
cal_obj_time_add_months (CalObjTime *cotime,
                         gint months)
{
	guint month, years;

	/* We use a guint to avoid overflow on the guint8. */
	month = cotime->month + months;
	cotime->month = month % 12;
	if (month > 0) {
		cotime->year += month / 12;
	} else {
		years = month / 12;
		if (cotime->month != 0) {
			cotime->month += 12;
			years -= 1;
		}
		cotime->year += years;
	}
}

/* Adds a positive or negative number of days to the given CalObjTime,
 * updating the month and year appropriately so we end up with a valid day. */
static void
cal_obj_time_add_days (CalObjTime *cotime,
                       gint days)
{
	gint day, days_in_month;

	/* We use a guint to avoid overflow on the guint8. */
	day = cotime->day;
	day += days;

	if (days >= 0) {
		for (;;) {
			days_in_month = time_days_in_month (
				cotime->year,
				cotime->month);
			if (day <= days_in_month)
				break;

			cotime->month++;
			if (cotime->month >= 12) {
				cotime->year++;
				cotime->month = 0;
			}

			day -= days_in_month;
		}

		cotime->day = (guint8) day;
	} else {
		while (day <= 0) {
			if (cotime->month == 0) {
				cotime->year--;
				cotime->month = 11;
			} else {
				cotime->month--;
			}

			days_in_month = time_days_in_month (
				cotime->year,
				cotime->month);
			day += days_in_month;
		}

		cotime->day = (guint8) day;
	}
}

/* Adds a positive or negative number of hours to the given CalObjTime,
 * updating the day, month & year appropriately so we end up with a valid
 * time. */
static void
cal_obj_time_add_hours (CalObjTime *cotime,
                        gint hours)
{
	gint hour, days;

	/* We use a gint to avoid overflow on the guint8. */
	hour = cotime->hour + hours;
	cotime->hour = hour % 24;
	if (hour >= 0) {
		if (hour >= 24)
			cal_obj_time_add_days (cotime, hour / 24);
	} else {
		days = hour / 24;
		if (cotime->hour != 0) {
			cotime->hour += 24;
			days -= 1;
		}
		cal_obj_time_add_days (cotime, days);
	}
}

/* Adds a positive or negative number of minutes to the given CalObjTime,
 * updating the rest of the CalObjTime appropriately. */
static void
cal_obj_time_add_minutes (CalObjTime *cotime,
                          gint minutes)
{
	gint minute, hours;

	/* We use a gint to avoid overflow on the guint8. */
	minute = cotime->minute + minutes;
	cotime->minute = minute % 60;
	if (minute >= 0) {
		if (minute >= 60)
			cal_obj_time_add_hours (cotime, minute / 60);
	} else {
		hours = minute / 60;
		if (cotime->minute != 0) {
			cotime->minute += 60;
			hours -= 1;
		}
		cal_obj_time_add_hours (cotime, hours);
	}
}

/* Adds a positive or negative number of seconds to the given CalObjTime,
 * updating the rest of the CalObjTime appropriately. */
static void
cal_obj_time_add_seconds (CalObjTime *cotime,
                          gint seconds)
{
	gint second, minutes;

	/* We use a gint to avoid overflow on the guint8. */
	second = cotime->second + seconds;
	cotime->second = second % 60;
	if (second >= 0) {
		if (second >= 60)
			cal_obj_time_add_minutes (cotime, second / 60);
	} else {
		minutes = second / 60;
		if (cotime->second != 0) {
			cotime->second += 60;
			minutes -= 1;
		}
		cal_obj_time_add_minutes (cotime, minutes);
	}
}

/* Compares 2 CalObjTimes. Returns -1 if the cotime1 is before cotime2, 0 if
 * they are the same, or 1 if cotime1 is after cotime2. The comparison type
 * specifies which parts of the times we are interested in, e.g. if CALOBJ_DAY
 * is used we only want to know if the days are different. */
static gint
cal_obj_time_compare (CalObjTime *cotime1,
                      CalObjTime *cotime2,
                      CalObjTimeComparison type)
{
	if (cotime1->year < cotime2->year)
		return -1;
	if (cotime1->year > cotime2->year)
		return 1;

	if (type == CALOBJ_YEAR)
		return 0;

	if (cotime1->month < cotime2->month)
		return -1;
	if (cotime1->month > cotime2->month)
		return 1;

	if (type == CALOBJ_MONTH)
		return 0;

	if (cotime1->day < cotime2->day)
		return -1;
	if (cotime1->day > cotime2->day)
		return 1;

	if (type == CALOBJ_DAY)
		return 0;

	if (cotime1->hour < cotime2->hour)
		return -1;
	if (cotime1->hour > cotime2->hour)
		return 1;

	if (type == CALOBJ_HOUR)
		return 0;

	if (cotime1->minute < cotime2->minute)
		return -1;
	if (cotime1->minute > cotime2->minute)
		return 1;

	if (type == CALOBJ_MINUTE)
		return 0;

	if (cotime1->second < cotime2->second)
		return -1;
	if (cotime1->second > cotime2->second)
		return 1;

	return 0;
}

/* This is the same as the above function, but without the comparison type.
 * It is used for qsort (). */
static gint
cal_obj_time_compare_func (gconstpointer arg1,
                           gconstpointer arg2)
{
	CalObjTime *cotime1, *cotime2;
	gint retval;

	cotime1 = (CalObjTime *) arg1;
	cotime2 = (CalObjTime *) arg2;

	if (!cotime1 || !cotime2) {
		if (cotime1 == cotime2)
			return 0;

		return cotime2 ? -1 : 1;
	}

	if (cotime1->year < cotime2->year)
		retval = -1;
	else if (cotime1->year > cotime2->year)
		retval = 1;

	else if (cotime1->month < cotime2->month)
		retval = -1;
	else if (cotime1->month > cotime2->month)
		retval = 1;

	else if (cotime1->day < cotime2->day)
		retval = -1;
	else if (cotime1->day > cotime2->day)
		retval = 1;

	else if (cotime1->hour < cotime2->hour)
		retval = -1;
	else if (cotime1->hour > cotime2->hour)
		retval = 1;

	else if (cotime1->minute < cotime2->minute)
		retval = -1;
	else if (cotime1->minute > cotime2->minute)
		retval = 1;

	else if (cotime1->second < cotime2->second)
		retval = -1;
	else if (cotime1->second > cotime2->second)
		retval = 1;

	else
		retval = 0;

#if 0
	g_print ("%s - ", cal_obj_time_to_string (cotime1));
	g_print ("%s : %i\n", cal_obj_time_to_string (cotime2), retval);
#endif

	return retval;
}

static gint
cal_obj_date_only_compare_func (gconstpointer arg1,
                                gconstpointer arg2)
{
	CalObjTime *cotime1, *cotime2;

	cotime1 = (CalObjTime *) arg1;
	cotime2 = (CalObjTime *) arg2;

	if (cotime1->year < cotime2->year)
		return -1;
	if (cotime1->year > cotime2->year)
		return 1;

	if (cotime1->month < cotime2->month)
		return -1;
	if (cotime1->month > cotime2->month)
		return 1;

	if (cotime1->day < cotime2->day)
		return -1;
	if (cotime1->day > cotime2->day)
		return 1;

	return 0;
}

/* Returns the weekday of the given CalObjTime, from 0 (Mon) - 6 (Sun). */
static gint
cal_obj_time_weekday (CalObjTime *cotime)
{
	GDate date;
	gint weekday;

	g_date_clear (&date, 1);
	g_date_set_dmy (&date, cotime->day, cotime->month + 1, cotime->year);

	/* This results in a value of 0 (Monday) - 6 (Sunday). */
	weekday = g_date_get_weekday (&date) - 1;

	return weekday;
}

/* Returns the weekday of the given CalObjTime, from 0 - 6. The week start
 * day is Monday by default, but can be set in the recurrence rule. */
static gint
cal_obj_time_weekday_offset (CalObjTime *cotime,
                             ECalRecurrence *recur)
{
	GDate date;
	gint weekday, offset;

	g_date_clear (&date, 1);
	g_date_set_dmy (&date, cotime->day, cotime->month + 1, cotime->year);

	/* This results in a value of 0 (Monday) - 6 (Sunday). */
	weekday = g_date_get_weekday (&date) - 1;

	/* This calculates the offset of our day from the start of the week.
	 * We just add on a week (to avoid any possible negative values) and
	 * then subtract the specified week start day, then convert it into a
	 * value from 0-6. */
	offset = (weekday + 7 - recur->week_start_day) % 7;

	return offset;
}

/* Returns the day of the year of the given CalObjTime, from 1 - 366. */
static gint
cal_obj_time_day_of_year (CalObjTime *cotime)
{
	GDate date;

	g_date_clear (&date, 1);
	g_date_set_dmy (&date, cotime->day, cotime->month + 1, cotime->year);

	return g_date_get_day_of_year (&date);
}

/* Finds the first week in the given CalObjTime's year, using the same weekday
 * as the event start day (i.e. from the RecurData).
 * The first week of the year is the first week starting from the specified
 * week start day that has 4 days in the new year. It may be in the previous
 * year. */
static void
cal_obj_time_find_first_week (CalObjTime *cotime,
                              RecurData *recur_data)
{
	GDate date;
	gint weekday, week_start_day, first_full_week_start_offset, offset;

	/* Find out the weekday of the 1st of the year, 0 (Mon) - 6 (Sun). */
	g_date_clear (&date, 1);
	g_date_set_dmy (&date, 1, 1, cotime->year);
	weekday = g_date_get_weekday (&date) - 1;

	/* Calculate the first day of the year that starts a new week, i.e. the
	 * first week_start_day after weekday, using 0 = 1st Jan.
	 * e.g. if the 1st Jan is a Tuesday (1) and week_start_day is a
	 * Monday (0), the result will be (0 + 7 - 1) % 7 = 6 (7th Jan). */
	week_start_day = recur_data->recur->week_start_day;
	first_full_week_start_offset = (week_start_day + 7 - weekday) % 7;

	/* Now see if we have to move backwards 1 week, i.e. if the week
	 * starts on or after Jan 5th (since the previous week has 4 days in
	 * this year and so will be the first week of the year). */
	if (first_full_week_start_offset >= 4)
		first_full_week_start_offset -= 7;

	/* Now add the days to get to the event's weekday. */
	offset = first_full_week_start_offset + recur_data->weekday_offset;

	/* Now move the cotime to the appropriate day. */
	cotime->month = 0;
	cotime->day = 1;
	cal_obj_time_add_days (cotime, offset);
}

static void
cal_object_time_from_time (CalObjTime *cotime,
                           time_t t,
                           icaltimezone *zone)
{
	struct icaltimetype tt;

	tt = icaltime_from_timet_with_zone (t, FALSE, zone);

	cotime->year = tt.year;
	cotime->month = tt.month - 1;
	cotime->day = tt.day;
	cotime->hour = tt.hour;
	cotime->minute = tt.minute;
	cotime->second = tt.second;
	cotime->flags = FALSE;
}

/* Debugging function to convert a CalObjTime to a string. It uses a static
 * buffer so beware. */
#ifdef CAL_OBJ_DEBUG
static const gchar *
cal_obj_time_to_string (CalObjTime *cotime)
{
	static gchar buffer[50];
	gchar *weekdays[] = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun",
			     "   " };
	gint weekday;

	weekday = cal_obj_time_weekday (cotime);

	g_snprintf (
		buffer, sizeof (buffer),
		"%s %02i/%02i/%04i %02i:%02i:%02i",
		weekdays[weekday],
		cotime->day, cotime->month + 1, cotime->year,
		cotime->hour, cotime->minute, cotime->second);

	return buffer;
}
#endif

/**
 * e_cal_recur_ensure_end_dates:
 * @comp: an #ECalComponent
 * @refresh: %TRUE to recalculate all end dates
 * @tz_cb: (closure tz_cb_data) (scope call): function to call to resolve
 * timezones
 * @tz_cb_data: (closure): data to pass to @tz_cb
 *
 * This recalculates the end dates for recurrence & exception rules which use
 * the COUNT property. If @refresh is %TRUE it will recalculate all enddates
 * for rules which use COUNT. If @refresh is %FALSE, it will only calculate
 * the enddate if it hasn't already been set. It returns %TRUE if the component
 * was changed, i.e. if the component should be saved at some point.
 * We store the enddate in the "X-EVOLUTION-ENDDATE" parameter of the RRULE
 * or EXRULE.
 *
 * Returns: %TRUE if the component was changed, %FALSE otherwise
 *
 * Since: 2.32
 **/
gboolean
e_cal_recur_ensure_end_dates (ECalComponent *comp,
                              gboolean refresh,
                              ECalRecurResolveTimezoneFn tz_cb,
                              gpointer tz_cb_data)
{
	GSList *rrules, *exrules, *elem;
	gboolean changed = FALSE;

	/* Do the RRULEs. */
	e_cal_component_get_rrule_property_list (comp, &rrules);
	for (elem = rrules; elem; elem = elem->next) {
		changed |= e_cal_recur_ensure_rule_end_date (comp, elem->data,
							   FALSE, refresh,
							   tz_cb, tz_cb_data);
	}

	/* Do the EXRULEs. */
	e_cal_component_get_exrule_property_list (comp, &exrules);
	for (elem = exrules; elem; elem = elem->next) {
		changed |= e_cal_recur_ensure_rule_end_date (comp, elem->data,
							   TRUE, refresh,
							   tz_cb, tz_cb_data);
	}

	return changed;
}

typedef struct _ECalRecurEnsureEndDateData ECalRecurEnsureEndDateData;
struct _ECalRecurEnsureEndDateData {
	gint count;
	gint instances;
	time_t end_date;
};

static gboolean
e_cal_recur_ensure_rule_end_date (ECalComponent *comp,
                                  icalproperty *prop,
                                  gboolean exception,
                                  gboolean refresh,
                                  ECalRecurResolveTimezoneFn tz_cb,
                                  gpointer tz_cb_data)
{
	struct icalrecurrencetype rule;
	ECalRecurEnsureEndDateData cb_data;

	if (exception)
		rule = icalproperty_get_exrule (prop);
	else
		rule = icalproperty_get_rrule (prop);

	/* If the rule doesn't use COUNT just return. */
	if (rule.count == 0)
		return FALSE;

	/* If refresh is FALSE, we check if the enddate is already set, and
	 * if it is we just return. */
	if (!refresh) {
		if (e_cal_recur_get_rule_end_date (prop, NULL) != -1)
			return FALSE;
	} else {
		/* Remove the property parameter, thus it'll not influence the regeneration */
		icalproperty_remove_parameter_by_name (prop, EVOLUTION_END_DATE_PARAMETER);
	}

	/* Calculate the end date. Note that we initialize end_date to 0, so
	 * if the RULE doesn't generate COUNT instances we save a time_t of 0.
	 * Also note that we use the UTC timezone as the default timezone.
	 * In get_end_date () if the DTSTART is a DATE or floating time, we will
	 * convert the ENDDATE to the current timezone. */
	cb_data.count = rule.count;
	cb_data.instances = 0;
	cb_data.end_date = 0;
	e_cal_recur_generate_instances_of_rule (
		comp, prop, -1, -1,
		e_cal_recur_ensure_rule_end_date_cb,
		&cb_data, tz_cb, tz_cb_data,
		icaltimezone_get_utc_timezone ());

	/* Store the end date in the "X-EVOLUTION-ENDDATE" parameter of the
	 * rule. */
	e_cal_recur_set_rule_end_date (prop, cb_data.end_date);

	return TRUE;
}

static gboolean
e_cal_recur_ensure_rule_end_date_cb (ECalComponent *comp,
                                     time_t instance_start,
                                     time_t instance_end,
                                     gpointer data)
{
	ECalRecurEnsureEndDateData *cb_data;

	cb_data = (ECalRecurEnsureEndDateData *) data;

	cb_data->instances++;

	if (cb_data->instances == cb_data->count) {
		cb_data->end_date = instance_start;
		return FALSE;
	}

	return TRUE;
}

/* If default_timezone is set, the saved ENDDATE parameter is assumed to be
 * in that timezone. This is used when the DTSTART is a DATE or floating
 * value, since the RRULE end date will change depending on the timezone that
 * it is evaluated in. */
static time_t
e_cal_recur_get_rule_end_date (icalproperty *prop,
                               icaltimezone *default_timezone)
{
	icalparameter *param;
	const gchar *xname, *xvalue;
	icalvalue *value;
	struct icaltimetype icaltime;
	icaltimezone *zone;

	param = icalproperty_get_first_parameter (prop, ICAL_X_PARAMETER);
	while (param) {
		xname = icalparameter_get_xname (param);
		if (xname && !strcmp (xname, EVOLUTION_END_DATE_PARAMETER)) {
			xvalue = icalparameter_get_x (param);
			value = icalvalue_new_from_string (
				ICAL_DATETIME_VALUE,
				xvalue);
			if (value) {
				icaltime = icalvalue_get_datetime (value);
				icalvalue_free (value);

				zone = default_timezone ? default_timezone :
					icaltimezone_get_utc_timezone ();
				return icaltime_as_timet_with_zone (
					icaltime,
					zone);
			}
		}

		param = icalproperty_get_next_parameter (
			prop,
			ICAL_X_PARAMETER);
	}

	return -1;
}

static void
e_cal_recur_set_rule_end_date (icalproperty *prop,
                               time_t end_date)
{
	icalparameter *param;
	icalvalue *value;
	icaltimezone *utc_zone;
	struct icaltimetype icaltime;
	const gchar *xname;
	gchar *end_date_string;

	/* We save the value as a UTC DATE-TIME. */
	utc_zone = icaltimezone_get_utc_timezone ();
	icaltime = icaltime_from_timet_with_zone (end_date, FALSE, utc_zone);
	value = icalvalue_new_datetime (icaltime);
	end_date_string = icalvalue_as_ical_string_r (value);
	icalvalue_free (value);

	/* If we already have an X-EVOLUTION-ENDDATE parameter, set the value
	 * to the new date-time. */
	param = icalproperty_get_first_parameter (prop, ICAL_X_PARAMETER);
	while (param) {
		xname = icalparameter_get_xname (param);
		if (xname && !strcmp (xname, EVOLUTION_END_DATE_PARAMETER)) {
			icalparameter_set_x (param, end_date_string);
			return;
		}
		param = icalproperty_get_next_parameter (prop, ICAL_X_PARAMETER);
	}

	/* Create a new X-EVOLUTION-ENDDATE and add it to the property. */
	param = icalparameter_new_x (end_date_string);
	icalparameter_set_xname (param, EVOLUTION_END_DATE_PARAMETER);
	icalproperty_add_parameter (prop, param);

	g_free (end_date_string);
}

#ifdef G_OS_WIN32
#undef e_cal_recur_nth
static
#endif
/**
 * e_cal_recur_nth:
 *
 * An array of 31 translated strings for each day of the month (i.e. "1st",
 * "2nd", and so on).
 *
 * Deprecated: 3.28: Use e_cal_recur_get_localized_nth() instead
 */
const gchar *e_cal_recur_nth[31] = {
	N_("1st"),
	N_("2nd"),
	N_("3rd"),
	N_("4th"),
	N_("5th"),
	N_("6th"),
	N_("7th"),
	N_("8th"),
	N_("9th"),
	N_("10th"),
	N_("11th"),
	N_("12th"),
	N_("13th"),
	N_("14th"),
	N_("15th"),
	N_("16th"),
	N_("17th"),
	N_("18th"),
	N_("19th"),
	N_("20th"),
	N_("21st"),
	N_("22nd"),
	N_("23rd"),
	N_("24th"),
	N_("25th"),
	N_("26th"),
	N_("27th"),
	N_("28th"),
	N_("29th"),
	N_("30th"),
	N_("31st")
};

#ifdef G_OS_WIN32

/**
 * e_cal_get_recur_nth:
 *
 * Returns an array of 31 translated strings for each day of the month
 * (i.e. "1st", "2nd", and so on).
 *
 * Returns: a pointer to an array of strings.  This array is static, do not free it.
 *
 * Deprecated: 3.28: Use e_cal_recur_get_localized_nth() instead
 */
const gchar **
e_cal_get_recur_nth (void)
{
	return e_cal_recur_nth;
}

#endif

/**
 * e_cal_recur_get_localized_nth:
 * @nth: the nth index, counting from zero
 *
 * Returns: Localized text for the nth position, counting from zero, which means
 *    for '0' it'll return "1st", for '1' it'll return "2nd" and so on, up to 30,
 *    when it'll return "31st".
 *
 * Since: 3.28
 **/
const gchar *
e_cal_recur_get_localized_nth (gint nth)
{
	g_return_val_if_fail (nth >= 0 && nth < G_N_ELEMENTS (e_cal_recur_nth), NULL);

	return _(e_cal_recur_nth[nth]);
}

static gint
cal_comp_util_recurrence_count_by_xxx (gshort *field,
				       gint max_elements)
{
	gint ii;

	for (ii = 0; ii < max_elements; ii++)
		if (field[ii] == ICAL_RECURRENCE_ARRAY_MAX)
			break;

	return ii;
}

/**
 * e_cal_recur_describe_recurrence:
 * @icalcomp: an icalcomponent
 * @week_start_day: a day when the week starts
 * @flags: bit-or of #ECalRecurDescribeRecurrenceFlags
 *
 * Describes some simple types of recurrences in a human-readable and localized way.
 * The @flags influence the output output format and what to do when the @icalcomp
 * contain more complicated recurrence, some which the function cannot describe.
 *
 * The @week_start_day is used for weekly recurrences, to start the list of selected
 * days at that day.
 *
 * Free the returned string with g_free(), when no longer needed.
 *
 * Returns: (nullable) (transfer full): a newly allocated string, which
 *    describes the recurrence of the @icalcomp, or #NULL, when the @icalcomp
 *    doesn't recur or the recurrence is too complicated to describe, also
 *    according to given @flags.
 *
 * Since: 3.30
 **/
gchar *
e_cal_recur_describe_recurrence (icalcomponent *icalcomp,
				 GDateWeekday week_start_day,
				 guint32 flags)
{
	gchar *prefix = NULL, *mid = NULL, *suffix = NULL, *result = NULL;
	icalproperty *prop;
	struct icalrecurrencetype rrule;
	gint n_by_second, n_by_minute, n_by_hour;
	gint n_by_day, n_by_month_day, n_by_year_day;
	gint n_by_week_no, n_by_month, n_by_set_pos;
	gboolean prefixed, fallback;

	g_return_val_if_fail (icalcomp != NULL, NULL);

	prefixed = (flags & E_CAL_RECUR_DESCRIBE_RECURRENCE_FLAG_PREFIXED) != 0;
	fallback = (flags & E_CAL_RECUR_DESCRIBE_RECURRENCE_FLAG_FALLBACK) != 0;

	prop = icalcomponent_get_first_property (icalcomp, ICAL_RRULE_PROPERTY);
	if (!prop)
		return NULL;

	switch (icalcomponent_isa (icalcomp)) {
	case ICAL_VEVENT_COMPONENT:
	case ICAL_VTODO_COMPONENT:
	case ICAL_VJOURNAL_COMPONENT:
		break;
	default:
		return NULL;
	}

	if (icalcomponent_count_properties (icalcomp, ICAL_RRULE_PROPERTY) != 1 ||
	    icalcomponent_count_properties (icalcomp, ICAL_RDATE_PROPERTY) != 0 ||
	    icalcomponent_count_properties (icalcomp, ICAL_EXRULE_PROPERTY) != 0)
		goto custom;

	rrule = icalproperty_get_rrule (prop);

	switch (rrule.freq) {
	case ICAL_DAILY_RECURRENCE:
	case ICAL_WEEKLY_RECURRENCE:
	case ICAL_MONTHLY_RECURRENCE:
	case ICAL_YEARLY_RECURRENCE:
		break;
	default:
		goto custom;

	}

#define N_HAS_BY(field) (cal_comp_util_recurrence_count_by_xxx (field, G_N_ELEMENTS (field)))

	n_by_second = N_HAS_BY (rrule.by_second);
	n_by_minute = N_HAS_BY (rrule.by_minute);
	n_by_hour = N_HAS_BY (rrule.by_hour);
	n_by_day = N_HAS_BY (rrule.by_day);
	n_by_month_day = N_HAS_BY (rrule.by_month_day);
	n_by_year_day = N_HAS_BY (rrule.by_year_day);
	n_by_week_no = N_HAS_BY (rrule.by_week_no);
	n_by_month = N_HAS_BY (rrule.by_month);
	n_by_set_pos = N_HAS_BY (rrule.by_set_pos);

#undef N_HAS_BY

	if (n_by_second != 0 ||
	    n_by_minute != 0 ||
	    n_by_hour != 0)
		goto custom;

	switch (rrule.freq) {
	case ICAL_DAILY_RECURRENCE:
		if (n_by_day != 0 ||
		    n_by_month_day != 0 ||
		    n_by_year_day != 0 ||
		    n_by_week_no != 0 ||
		    n_by_month != 0 ||
		    n_by_set_pos != 0)
			goto custom;

		if (rrule.interval > 0) {
			if (!rrule.count && !rrule.until.year) {
				if (prefixed) {
					result = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"every day forever",
							"every %d days forever",
							rrule.interval), rrule.interval);
				} else {
					result = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"Every day forever",
							"Every %d days forever",
							rrule.interval), rrule.interval);
				}
			} else {
				if (prefixed) {
					prefix = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"every day",
							"every %d days",
							rrule.interval), rrule.interval);
				} else {
					prefix = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"Every day",
							"Every %d days",
							rrule.interval), rrule.interval);
				}
			}
		}
		break;

	case ICAL_WEEKLY_RECURRENCE: {
		gint ii, ndays;
		guint8 day_mask;
		gint day_shift = week_start_day;

		/* Sunday is at bit 0 in the day_mask */
		if (day_shift < 0 || day_shift >= G_DATE_SUNDAY)
			day_shift = 0;

		if (n_by_month_day != 0 ||
		    n_by_year_day != 0 ||
		    n_by_week_no != 0 ||
		    n_by_month != 0 ||
		    n_by_set_pos != 0)
			goto custom;

		day_mask = 0;

		for (ii = 0; ii < 8 && rrule.by_day[ii] != ICAL_RECURRENCE_ARRAY_MAX; ii++) {
			enum icalrecurrencetype_weekday weekday;
			gint pos;

			weekday = icalrecurrencetype_day_day_of_week (rrule.by_day[ii]);
			pos = icalrecurrencetype_day_position (rrule.by_day[ii]);

			if (pos != 0)
				goto custom;

			switch (weekday) {
			case ICAL_SUNDAY_WEEKDAY:
				day_mask |= 1 << 0;
				break;

			case ICAL_MONDAY_WEEKDAY:
				day_mask |= 1 << 1;
				break;

			case ICAL_TUESDAY_WEEKDAY:
				day_mask |= 1 << 2;
				break;

			case ICAL_WEDNESDAY_WEEKDAY:
				day_mask |= 1 << 3;
				break;

			case ICAL_THURSDAY_WEEKDAY:
				day_mask |= 1 << 4;
				break;

			case ICAL_FRIDAY_WEEKDAY:
				day_mask |= 1 << 5;
				break;

			case ICAL_SATURDAY_WEEKDAY:
				day_mask |= 1 << 6;
				break;

			default:
				break;
			}
		}

		if (ii == 0) {
			struct icaltimetype dtstart;

			dtstart = icalcomponent_get_dtstart (icalcomp);

			ii = icaltime_day_of_week (dtstart);
			if (ii >= 1)
				day_mask |= 1 << (ii - 1);
		}

		ndays = 0;

		for (ii = 0; ii < 7; ii++) {
			if ((day_mask & (1 << ii)) != 0)
				ndays++;
		}

		if (prefixed) {
			prefix = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
					"every week",
					"every %d weeks",
					rrule.interval), rrule.interval);
		} else {
			prefix = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
					"Every week",
					"Every %d weeks",
					rrule.interval), rrule.interval);
		}

		for (ii = 0; ii < 7 && ndays; ii++) {
			gint bit = ((ii + day_shift) % 7);

			if ((day_mask & (1 << bit)) != 0) {
				/* Translators: This is used to merge set of week day names in a recurrence, which can contain any
				   of the week day names. The string always starts with "on DAYNAME", then it can continue either
				   with ", DAYNAME" or " and DAYNAME", thus it can be something like "on Monday and Tuesday"
				   or "on Monday, Wednesday and Friday" or simply "on Saturday". The '%1$s' is replaced with
				   the previously gathered text, while the '%2$s' is replaced with the text to append. */
				#define merge_fmt C_("recur-description-dayname", "%1$s%2$s")
				#define merge_string(_on_str, _merge_str, _and_str) G_STMT_START {\
					if (mid) { \
						gchar *tmp; \
						if (ndays == 1) \
							tmp = g_strdup_printf (merge_fmt, mid, _and_str); \
						else \
							tmp = g_strdup_printf (merge_fmt, mid, _merge_str); \
						g_free (mid); \
						mid = tmp; \
					} else { \
						mid = g_strdup (_on_str); \
					} \
					ndays--; \
					} G_STMT_END
				switch (bit) {
				case 0:
					merge_string (C_("recur-description", "on Sunday"),
						      C_("recur-description", ", Sunday"),
						      C_("recur-description", " and Sunday"));
					break;
				case 1:
					merge_string (C_("recur-description", "on Monday"),
						      C_("recur-description", ", Monday"),
						      C_("recur-description", " and Monday"));
					break;
				case 2:
					merge_string (C_("recur-description", "on Tuesday"),
						      C_("recur-description", ", Tuesday"),
						      C_("recur-description", " and Tuesday"));
					break;
				case 3:
					merge_string (C_("recur-description", "on Wednesday"),
						      C_("recur-description", ", Wednesday"),
						      C_("recur-description", " and Wednesday"));
					break;
				case 4:
					merge_string (C_("recur-description", "on Thursday"),
						      C_("recur-description", ", Thursday"),
						      C_("recur-description", " and Thursday"));
					break;
				case 5:
					merge_string (C_("recur-description", "on Friday"),
						      C_("recur-description", ", Friday"),
						      C_("recur-description", " and Friday"));
					break;
				case 6:
					merge_string (C_("recur-description", "on Saturday"),
						      C_("recur-description", ", Saturday"),
						      C_("recur-description", " and Saturday"));
					break;
				default:
					g_warn_if_reached ();
					break;
				}
				#undef merge_string
				#undef merge_fmt
			}
		}
		break;
	}

	case ICAL_MONTHLY_RECURRENCE: {
		enum month_num_options {
			MONTH_NUM_INVALID = -1,
			MONTH_NUM_FIRST,
			MONTH_NUM_SECOND,
			MONTH_NUM_THIRD,
			MONTH_NUM_FOURTH,
			MONTH_NUM_FIFTH,
			MONTH_NUM_LAST,
			MONTH_NUM_DAY,
			MONTH_NUM_OTHER
		};

		enum month_day_options {
			MONTH_DAY_NTH,
			MONTH_DAY_MON,
			MONTH_DAY_TUE,
			MONTH_DAY_WED,
			MONTH_DAY_THU,
			MONTH_DAY_FRI,
			MONTH_DAY_SAT,
			MONTH_DAY_SUN
		};

		gint month_index = 1;
		enum month_day_options month_day;
		enum month_num_options month_num;

		if (n_by_year_day != 0 ||
		    n_by_week_no != 0 ||
		    n_by_month != 0 ||
		    n_by_set_pos > 1)
			goto custom;

		if (n_by_month_day == 1) {
			gint nth;

			if (n_by_set_pos != 0)
				goto custom;

			nth = rrule.by_month_day[0];
			if (nth < 1 && nth != -1)
				goto custom;

			if (nth == -1) {
				struct icaltimetype dtstart;

				dtstart = icalcomponent_get_dtstart (icalcomp);

				month_index = dtstart.day;
				month_num = MONTH_NUM_LAST;
			} else {
				month_index = nth;
				month_num = MONTH_NUM_DAY;
			}
			month_day = MONTH_DAY_NTH;

		} else if (n_by_day == 1) {
			enum icalrecurrencetype_weekday weekday;
			gint pos;

			/* Outlook 2000 uses BYDAY=TU;BYSETPOS=2, and will not
			 * accept BYDAY=2TU. So we now use the same as Outlook
			 * by default. */

			weekday = icalrecurrencetype_day_day_of_week (rrule.by_day[0]);
			pos = icalrecurrencetype_day_position (rrule.by_day[0]);

			if (pos == 0) {
				if (n_by_set_pos != 1)
					goto custom;
				pos = rrule.by_set_pos[0];
			} else if (pos < 0) {
				goto custom;
			}

			switch (weekday) {
			case ICAL_MONDAY_WEEKDAY:
				month_day = MONTH_DAY_MON;
				break;

			case ICAL_TUESDAY_WEEKDAY:
				month_day = MONTH_DAY_TUE;
				break;

			case ICAL_WEDNESDAY_WEEKDAY:
				month_day = MONTH_DAY_WED;
				break;

			case ICAL_THURSDAY_WEEKDAY:
				month_day = MONTH_DAY_THU;
				break;

			case ICAL_FRIDAY_WEEKDAY:
				month_day = MONTH_DAY_FRI;
				break;

			case ICAL_SATURDAY_WEEKDAY:
				month_day = MONTH_DAY_SAT;
				break;

			case ICAL_SUNDAY_WEEKDAY:
				month_day = MONTH_DAY_SUN;
				break;

			default:
				goto custom;
			}

			if (pos == -1)
				month_num = MONTH_NUM_LAST;
			else
				month_num = pos - 1;
		} else {
			goto custom;
		}

		if (prefixed) {
			prefix = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
					"every month",
					"every %d months",
					rrule.interval), rrule.interval);
		} else {
			prefix = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
					"Every month",
					"Every %d months",
					rrule.interval), rrule.interval);
		}

		switch (month_day) {
		case MONTH_DAY_NTH:
			if (month_num == MONTH_NUM_LAST) {
				switch (month_index) {
				case 0:
					mid = g_strdup (C_("recur-description", "on the last Sunday"));
					break;
				case 1:
					mid = g_strdup (C_("recur-description", "on the last Monday"));
					break;
				case 2:
					mid = g_strdup (C_("recur-description", "on the last Tuesday"));
					break;
				case 3:
					mid = g_strdup (C_("recur-description", "on the last Wednesday"));
					break;
				case 4:
					mid = g_strdup (C_("recur-description", "on the last Thursday"));
					break;
				case 5:
					mid = g_strdup (C_("recur-description", "on the last Friday"));
					break;
				case 6:
					mid = g_strdup (C_("recur-description", "on the last Saturday"));
					break;
				default:
					g_warning ("%s: What is month_index:%d for the last day?", G_STRFUNC, month_index);
					break;
				}
			} else { /* month_num = MONTH_NUM_DAY; */
				switch (month_index) {
				case 1:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 1st day"));
					break;
				case 2:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 2nd day"));
					break;
				case 3:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 3rd day"));
					break;
				case 4:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 4th day"));
					break;
				case 5:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 5th day"));
					break;
				case 6:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 6th day"));
					break;
				case 7:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 7th day"));
					break;
				case 8:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 8th day"));
					break;
				case 9:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 9th day"));
					break;
				case 10:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 10th day"));
					break;
				case 11:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 11th day"));
					break;
				case 12:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 12th day"));
					break;
				case 13:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 13th day"));
					break;
				case 14:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 14th day"));
					break;
				case 15:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 15th day"));
					break;
				case 16:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 16th day"));
					break;
				case 17:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 17th day"));
					break;
				case 18:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 18th day"));
					break;
				case 19:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 19th day"));
					break;
				case 20:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 20th day"));
					break;
				case 21:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 21st day"));
					break;
				case 22:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 22nd day"));
					break;
				case 23:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 23rd day"));
					break;
				case 24:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 24th day"));
					break;
				case 25:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 25th day"));
					break;
				case 26:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 26th day"));
					break;
				case 27:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 27th day"));
					break;
				case 28:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 28th day"));
					break;
				case 29:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 29th day"));
					break;
				case 30:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 30th day"));
					break;
				case 31:
					/* Translators: This is added to a monthly recurrence, forming something like "Every month on the Xth day" */
					mid = g_strdup (C_("recur-description", "on the 31st day"));
					break;
				}
			}
			break;
		case MONTH_DAY_MON:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Monday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Monday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Monday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Monday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Monday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Monday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_TUE:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Tuesday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Tuesday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Tuesday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Tuesday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Tuesday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Tuesday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_WED:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Wednesday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Wednesday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Wednesday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Wednesday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Wednesday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Wednesday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_THU:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Thursday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Thursday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Thursday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Thursday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Thursday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Thursday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_FRI:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Friday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Friday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Friday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Friday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Friday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Friday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_SAT:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Saturday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Saturday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Saturday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Saturday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Saturday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Saturday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		case MONTH_DAY_SUN:
			switch (month_num) {
			case MONTH_NUM_FIRST:
				mid = g_strdup (C_("recur-description", "on the first Sunday"));
				break;
			case MONTH_NUM_SECOND:
				mid = g_strdup (C_("recur-description", "on the second Sunday"));
				break;
			case MONTH_NUM_THIRD:
				mid = g_strdup (C_("recur-description", "on the third Sunday"));
				break;
			case MONTH_NUM_FOURTH:
				mid = g_strdup (C_("recur-description", "on the fourth Sunday"));
				break;
			case MONTH_NUM_FIFTH:
				mid = g_strdup (C_("recur-description", "on the fifth Sunday"));
				break;
			case MONTH_NUM_LAST:
				mid = g_strdup (C_("recur-description", "on the last Sunday"));
				break;
			default:
				g_warning ("%s: What is month_num:%d for month_day:%d?", G_STRFUNC, month_num, month_day);
				break;
			}
			break;
		}

		break;
	}

	case ICAL_YEARLY_RECURRENCE:
		if (n_by_day != 0 ||
		    n_by_month_day != 0 ||
		    n_by_year_day != 0 ||
		    n_by_week_no != 0 ||
		    n_by_month != 0 ||
		    n_by_set_pos != 0)
			goto custom;

		if (rrule.interval > 0) {
			if (!rrule.count && !rrule.until.year) {
				if (prefixed) {
					result = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"every year forever",
							"every %d years forever",
							rrule.interval), rrule.interval);
				} else {
					result = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"Every year forever",
							"Every %d years forever",
							rrule.interval), rrule.interval);
				}
			} else {
				if (prefixed) {
					prefix = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"every year",
							"every %d years",
							rrule.interval), rrule.interval);
				} else {
					prefix = g_strdup_printf (
						g_dngettext (GETTEXT_PACKAGE,
							"Every year",
							"Every %d years",
							rrule.interval), rrule.interval);
				}
			}
		}
		break;

	default:
		break;
	}

	if (prefix) {
		if (rrule.count) {
			suffix = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
					/* Translators: This is one of the last possible parts of a recurrence description.
					   The text is appended at the end of the complete recurrence description, making it
					   for example: "Every 3 days for 10 occurrences" */
					"for one occurrence",
					"for %d occurrences",
					rrule.count), rrule.count);
		} else if (rrule.until.year) {
			struct tm tm;
			gchar dt_str[256];

			dt_str[0] = 0;

			if (!rrule.until.is_date) {
				icaltimezone *from_zone, *to_zone;
				struct icaltimetype dtstart;

				dtstart = icalcomponent_get_dtstart (icalcomp);

				from_zone = icaltimezone_get_utc_timezone ();
				to_zone = (icaltimezone *) dtstart.zone;

				if (to_zone)
					icaltimezone_convert_time (&rrule.until, from_zone, to_zone);

				rrule.until.hour = 0;
				rrule.until.minute = 0;
				rrule.until.second = 0;
				rrule.until.is_date = TRUE;
			}

			tm = icaltimetype_to_tm (&rrule.until);
			e_time_format_date_and_time (&tm, FALSE, FALSE, FALSE, dt_str, 255);

			if (*dt_str) {
				/* Translators: This is one of the last possible parts of a recurrence description.
				   The '%s' is replaced with actual date, thus it can create something like
				   "until Mon 15.1.2018". The text is appended at the end of the complete
				   recurrence description, making it for example: "Every 3 days until Mon 15.1.2018" */
				suffix = g_strdup_printf (C_("recur-description", "until %s"), dt_str);
			}
		} else {
			/* Translators: This is one of the last possible parts of a recurrence description.
			   The text is appended at the end of the complete recurrence description, making it
			   for example: "Every 2 months on Tuesday, Thursday and Friday forever" */
			suffix = g_strdup (C_("recur-description", "forever"));
		}
	}

 custom:
	if (!result && prefix && suffix) {
		if (mid) {
			/* Translators: This constructs a complete recurrence description; the '%1$s' is like "Every 2 weeks",
			   the '%2$s' is like "on Tuesday and Friday" and the '%3$s' is like "for 10 occurrences", constructing
			   together one sentence: "Every 2 weeks on Tuesday and Friday for 10 occurrences". */
			result = g_strdup_printf (C_("recur-description", "%1$s %2$s %3$s"), prefix, mid, suffix);
		} else {
			/* Translators: This constructs a complete recurrence description; the '%1$s' is like "Every 2 days",
			   the '%2$s' is like "for 10 occurrences", constructing together one sentence:
			   "Every 2 days for 10 occurrences". */
			result = g_strdup_printf (C_("recur-description", "%1$s %2$s"), prefix, suffix);
		}
	}

	if (result) {
		gint n_exdates;
		gchar *tmp;

		n_exdates = icalcomponent_count_properties (icalcomp, ICAL_EXDATE_PROPERTY);
		if (n_exdates > 0) {
			gchar *exdates_str;

			exdates_str = g_strdup_printf (
				g_dngettext (GETTEXT_PACKAGE,
				/* Translators: This text is appended at the end of complete recur description using "%s%s" in
				   context "recur-description" */
					", with one exception",
					", with %d exceptions",
					n_exdates), n_exdates);

			/* Translators: This appends text like ", with 3 exceptions" at the end of complete recurrence description.
			   The "%1$s" is replaced with the recurrence description, the "%2$s" with the text about exceptions.
			   It will form something like: "Every 2 weeks on Tuesday and Friday for 10 occurrences, with 3 exceptions" */
			tmp = g_strdup_printf (C_("recur-description", "%1$s%2$s"), result, exdates_str);

			g_free (exdates_str);
			g_free (result);
			result = tmp;
		}

		if (prefixed) {
			const gchar *comp_prefix;

			if (icalcomponent_isa (icalcomp) == ICAL_VEVENT_COMPONENT) {
				if (icalcomponent_count_properties (icalcomp, ICAL_ORGANIZER_PROPERTY) > 0 &&
				    icalcomponent_count_properties (icalcomp, ICAL_ATTENDEE_PROPERTY) > 0) {
					comp_prefix = C_("recur-description", "The meeting recurs");
				} else {
					comp_prefix = C_("recur-description", "The appointment recurs");
				}
			} else if (icalcomponent_isa (icalcomp) == ICAL_VTODO_COMPONENT) {
				comp_prefix = C_("recur-description", "The task recurs");
			} else /* if (icalcomponent_isa (icalcomp) == ICAL_VJOURNAL_COMPONENT) */ {
				comp_prefix = C_("recur-description", "The memo recurs");
			}

			/* Translators: This adds a prefix in front of the complete recurrence description.
			   The '%1$s' is replaced with something like "The meeting recurs" and
			   the '%2$s' with something like "every 2 days forever", thus forming
			   sentence like "This meeting recurs every 2 days forever" */
			tmp = g_strdup_printf (C_("recur-description-prefix", "%1$s %2$s"), comp_prefix, result);

			g_free (result);
			result = tmp;
		}
	} else if (fallback) {
		if (icalcomponent_isa (icalcomp) == ICAL_VEVENT_COMPONENT) {
			if (icalcomponent_count_properties (icalcomp, ICAL_ORGANIZER_PROPERTY) > 0 &&
			    icalcomponent_count_properties (icalcomp, ICAL_ATTENDEE_PROPERTY) > 0) {
				result = g_strdup (C_("recur-description", "The meeting recurs"));
			} else {
				result = g_strdup (C_("recur-description", "The appointment recurs"));
			}
		} else if (icalcomponent_isa (icalcomp) == ICAL_VTODO_COMPONENT) {
			result = g_strdup (C_("recur-description", "The task recurs"));
		} else if (icalcomponent_isa (icalcomp) == ICAL_VJOURNAL_COMPONENT) {
			result = g_strdup (C_("recur-description", "The memo recurs"));
		}
	}

	g_free (prefix);
	g_free (mid);
	g_free (suffix);

	return result;
}
