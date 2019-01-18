/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

/**
 * SECTION: e-reminder-watcher
 * @include: libecal/libecal.h
 * @short_description: Calendar reminder watcher
 *
 * The #EReminderWatcher watches reminders in configured calendars
 * and notifies the owner about them through signals. It also remembers
 * past and snoozed reminders. It doesn't provide any GUI, it's all
 * up to the owner to provide such functionality.
 *
 * The API is thread safe and each signal is emitted from the thread of
 * the default main context of the process.
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

#include "libedataserver/libedataserver.h"

#include "e-cal-client.h"
#include "e-cal-system-timezone.h"
#include "e-cal-time-util.h"
#include "e-cal-util.h"

#include "e-reminder-watcher.h"

typedef struct _ClientData {
	EReminderWatcher *watcher; /* Just as an owner, not referenced */
	ECalClient *client;
	ECalClientView *view;
} ClientData;

struct _EReminderWatcherPrivate {
	GRecMutex lock;

	ESourceRegistry *registry;
	ESourceRegistryWatcher *registry_watcher;
	GCancellable *cancellable;
	GSettings *settings;
	gboolean timers_enabled;
	gulong past_changed_handler_id;
	gulong snoozed_changed_handler_id;
	guint expected_past_changes;
	guint expected_snoozed_changes;

	icaltimezone *default_zone;

	GSList *clients; /* ClientData * */
	GSList *snoozed; /* EReminderData * */
	GHashTable *scheduled; /* gchar *source_uid ~> GSList * { EReminderData * } */

	gulong construct_idle_id;
	gulong timer_handler_id;

	gint64 expected_wall_clock_time;
	gulong wall_clock_handler_id;

	gint64 next_midnight;
	gint64 next_trigger;
};

enum {
	PROP_0,
	PROP_REGISTRY,
	PROP_DEFAULT_ZONE,
	PROP_TIMERS_ENABLED
};

enum {
	FORMAT_TIME,
	TRIGGERED,
	CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (EReminderWatcher, e_reminder_watcher, G_TYPE_OBJECT)

G_DEFINE_BOXED_TYPE (EReminderData, e_reminder_data, e_reminder_data_copy, e_reminder_data_free)
G_DEFINE_BOXED_TYPE (EReminderWatcherZone, e_reminder_watcher_zone, e_reminder_watcher_zone_copy, e_reminder_watcher_zone_free)

static void
e_reminder_watcher_objects_added_cb (ECalClientView *view,
				     const GSList *objects, /* icalcomponent * */
				     gpointer user_data);
static void
e_reminder_watcher_objects_modified_cb (ECalClientView *view,
					const GSList *objects, /* icalcomponent * */
					gpointer user_data);
static void
e_reminder_watcher_objects_removed_cb (ECalClientView *view,
				       const GSList *uids, /* ECalComponentId * */
				       gpointer user_data);

static gboolean
e_reminder_watcher_debug_enabled (void)
{
	static gint enabled = -1;

	if (enabled == -1)
		enabled = g_strcmp0 (g_getenv ("ERW_DEBUG"), "1") == 0 ? 1 : 0;

	return enabled == 1;
}

static void
e_reminder_watcher_debug_print (const gchar *format,
				...) G_GNUC_PRINTF (1, 2);

static void
e_reminder_watcher_debug_print (const gchar *format,
				...)
{
	va_list args;

	if (!e_reminder_watcher_debug_enabled ())
		return;

	va_start (args, format);
	e_util_debug_printv ("ERW", format, args);
	va_end (args);
}

static const gchar *
e_reminder_watcher_timet_as_string (gint64 tt)
{
	static gchar buffers[10][32 + 1];
	static volatile gint curr_index = 0;
	gint counter = 0, index;
	struct icaltimetype itt;

	while (index = (curr_index + 1) % 10, !g_atomic_int_compare_and_exchange (&curr_index, curr_index, index)) {
		counter++;
		if (counter > 20)
			break;
	}

	itt = icaltime_from_timet_with_zone ((time_t) tt, 0, icaltimezone_get_utc_timezone ());

	g_snprintf (buffers[index], 32, "%04d%02d%02dT%02d%02d%02d",
		itt.year, itt.month, itt.day,
		itt.hour, itt.minute, itt.second);

	return buffers[index];
}

static ClientData *
client_data_new (EReminderWatcher *watcher,
		 ECalClient *client) /* Assumes ownership of the 'client' */
{
	ClientData *cd;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), NULL);

	cd = g_new0 (ClientData, 1);
	cd->watcher = watcher;
	cd->client = client;
	cd->view = NULL;

	return cd;
}

static void
client_data_free_view (ClientData *cd)
{
	GError *local_error = NULL;

	g_return_if_fail (cd != NULL);

	if (!cd->view)
		return;

	e_cal_client_view_stop (cd->view, &local_error);

	if (local_error) {
		e_reminder_watcher_debug_print ("Failed to stop view for %s: %s\n",
			e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))),
			local_error->message);

		g_clear_error (&local_error);
	} else {
		e_reminder_watcher_debug_print ("Stopped view for %s\n",
			e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))));
	}

	g_signal_handlers_disconnect_by_data (cd->view, cd->watcher);

	g_clear_object (&cd->view);
}

static void
client_data_free (gpointer ptr)
{
	ClientData *cd = ptr;

	if (cd) {
		client_data_free_view (cd);
		g_clear_object (&cd->client);
		g_free (cd);
	}
}

static void
client_data_source_written_cb (GObject *source_object,
			       GAsyncResult *result,
			       gpointer user_data)
{
	GError *local_error = NULL;

	e_source_write_finish (E_SOURCE (source_object), result, &local_error);

	if (local_error) {
		g_warning ("Failed to write source %s changes: %s", e_source_get_uid (E_SOURCE (source_object)), local_error->message);
		g_error_free (local_error);
	}
}

static time_t
client_get_last_notification_time (ECalClient *client)
{
	ESource *source;
	ESourceAlarms *alarms_extension;
	gchar *last_notified;
	GTimeVal tmval = { 0 };
	time_t value = 0, now;

	if (!client)
		return -1;

	source = e_client_get_source (E_CLIENT (client));
	if (!source || !e_source_has_extension (source, E_SOURCE_EXTENSION_ALARMS))
		return -1;

	alarms_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_ALARMS);
	last_notified = e_source_alarms_dup_last_notified (alarms_extension);

	if (last_notified && *last_notified &&
	    g_time_val_from_iso8601 (last_notified, &tmval)) {
		now = time (NULL);
		value = (time_t) tmval.tv_sec;

		if (value > now)
			value = now;
	}

	g_free (last_notified);

	return value;
}

static void
client_set_last_notification_time (ECalClient *client,
				   time_t tt)
{
	ESource *source;
	ESourceAlarms *alarms_extension;
	GTimeVal tv = { 0 };
	gchar *iso8601;
	time_t now;

	g_return_if_fail (client != NULL);
	g_return_if_fail (tt > 0);

	source = e_client_get_source (E_CLIENT (client));
	if (!source)
		return;

	alarms_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_ALARMS);
	iso8601 = e_source_alarms_dup_last_notified (alarms_extension);

	if (iso8601) {
		g_time_val_from_iso8601 (iso8601, &tv);
		g_free (iso8601);
	}

	now = time (NULL);

	if (tt > (time_t) tv.tv_sec || (time_t) tv.tv_sec > now) {
		tv.tv_sec = (glong) tt;
		iso8601 = g_time_val_to_iso8601 (&tv);
		e_source_alarms_set_last_notified (alarms_extension, iso8601);

		e_reminder_watcher_debug_print ("Changed last-notified for source %s (%s) to %s\n",
			e_source_get_uid (source),
			e_source_get_display_name (source),
			iso8601);

		g_free (iso8601);

		e_source_write (source, NULL, client_data_source_written_cb, NULL);
	}
}

static void
client_data_view_created_cb (GObject *source_object,
			     GAsyncResult *result,
			     gpointer user_data)
{
	ClientData *cd = user_data;
	ECalClient *client;
	ECalClientView *view = NULL;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_CAL_CLIENT (source_object));
	g_return_if_fail (cd != NULL);

	client = E_CAL_CLIENT (source_object);

	if (!e_cal_client_get_view_finish (client, result, &view, &local_error) || local_error || !view) {
		e_reminder_watcher_debug_print ("Failed to get view for %s: %s\n",
			e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))),
			local_error ? local_error->message : "Unknown error");
	} else {
		cd->view = view;

		e_reminder_watcher_debug_print ("Got view for %s\n",
			e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))));

		g_signal_connect (
			cd->view, "objects-added",
			G_CALLBACK (e_reminder_watcher_objects_added_cb), cd->watcher);
		g_signal_connect (
			cd->view, "objects-modified",
			G_CALLBACK (e_reminder_watcher_objects_modified_cb), cd->watcher);
		g_signal_connect (
			cd->view, "objects-removed",
			G_CALLBACK (e_reminder_watcher_objects_removed_cb), cd->watcher);

		e_cal_client_view_start (cd->view, &local_error);

		if (local_error) {
			e_reminder_watcher_debug_print ("Failed to start view for %s: %s\n",
				e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))),
				local_error ? local_error->message : "Unknown error");
		}
	}

	g_clear_error (&local_error);
}

static void
client_data_start_view (ClientData *cd,
			gint64 next_midnight,
			GCancellable *cancellable)
{
	gchar *iso_start, *iso_end;
	time_t start_tt;

	g_return_if_fail (cd != NULL);
	g_return_if_fail (cd->client != NULL);

	client_data_free_view (cd);

	start_tt = client_get_last_notification_time (cd->client) + 1;
	if (start_tt <= 0)
		start_tt = time (NULL);

	iso_start = isodate_from_time_t (start_tt);
	iso_end = isodate_from_time_t ((time_t) next_midnight);

	if (!iso_start || !iso_end) {
		e_reminder_watcher_debug_print ("Failed to convert last notification %" G_GINT64_FORMAT " or next midnight %" G_GINT64_FORMAT " into iso strings for client %s\n",
			(gint64) start_tt, next_midnight, e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))));
	} else {
		gchar *query;

		query = g_strdup_printf ("(has-alarms-in-range? (make-time \"%s\") (make-time \"%s\"))", iso_start, iso_end);

		e_reminder_watcher_debug_print ("Getting view for %s: %s\n",
			e_source_get_uid (e_client_get_source (E_CLIENT (cd->client))),
			query);

		e_cal_client_get_view (cd->client, query, cancellable, client_data_view_created_cb, cd);

		g_free (query);
	}

	g_free (iso_start);
	g_free (iso_end);
}

static EReminderData *
e_reminder_data_new_take_component (const gchar *source_uid,
				    ECalComponent *component,
				    const ECalComponentAlarmInstance *instance)
{
	EReminderData *rd;

	g_return_val_if_fail (source_uid != NULL, NULL);
	g_return_val_if_fail (component != NULL, NULL);
	g_return_val_if_fail (instance != NULL, NULL);

	rd = g_new0 (EReminderData, 1);
	rd->source_uid = g_strdup (source_uid);
	rd->component = component;
	rd->instance.auid = g_strdup (instance->auid);
	rd->instance.trigger = instance->trigger;
	rd->instance.occur_start = instance->occur_start;
	rd->instance.occur_end = instance->occur_end;

	return rd;
}

/**
 * e_reminder_data_new:
 * @source_uid: an #ESource UID, to which the @component belongs
 * @component: an #ECalComponent
 * @instance: an #ECalComponentAlarmInstance describing one reminder instance
 *
 * Returns: (transfer full): a new #EReminderData prefilled with given values.
 *    Free the returned structure with e_reminder_data_free() when no longer needed.
 *
 * Since: 3.30
 **/
EReminderData *
e_reminder_data_new (const gchar *source_uid,
		     const ECalComponent *component,
		     const ECalComponentAlarmInstance *instance)
{
	g_return_val_if_fail (source_uid != NULL, NULL);
	g_return_val_if_fail (component != NULL, NULL);
	g_return_val_if_fail (instance != NULL, NULL);

	return e_reminder_data_new_take_component (source_uid, e_cal_component_clone ((ECalComponent *) component), instance);
}

/**
 * e_reminder_data_copy:
 * @rd: (nullable): source #EReminderData, or %NULL
 *
 * Copies given #EReminderData structure. When the @rd is %NULL, simply returns %NULL as well.
 *
 * Returns: (transfer full): copy of @rd. Free the returned structure
 *    with e_reminder_data_free() when no longer needed.
 *
 * Since: 3.30
 **/
EReminderData *
e_reminder_data_copy (const EReminderData *rd)
{
	if (!rd)
		return NULL;

	return e_reminder_data_new_take_component (rd->source_uid, g_object_ref (rd->component), &(rd->instance));
}

/**
 * e_reminder_data_free:
 * @rd: (nullable): an #EReminderData, or %NULL
 *
 * Frees previously allocated #EReminderData structure with e_reminder_data_new()
 * or e_reminder_data_copy(). The function does nothing when @rd is %NULL.
 *
 * Since: 3.30
 **/
void
e_reminder_data_free (gpointer rd)
{
	EReminderData *ptr = rd;

	if (ptr) {
		g_clear_object (&ptr->component);
		g_free (ptr->source_uid);
		g_free (ptr->instance.auid);
		g_free (ptr);
	}
}

/**
 * e_reminder_watcher_zone_copy:
 * @watcher_zone: (nullable): an #EReminderWatcherZone to copy, or %NULL
 *
 * Returns: (transfer full): copy of @watcher_zone, or %NULL, when it's also %NULL.
 *    Free returned instance with e_reminder_watcher_zone_free(), when no longer needed.
 *
 * Since: 3.30
 **/
EReminderWatcherZone *
e_reminder_watcher_zone_copy (const EReminderWatcherZone *watcher_zone)
{
	if (!watcher_zone)
		return NULL;

	return (EReminderWatcherZone *) icaltimezone_copy ((icaltimezone *) watcher_zone);
}

/**
 * e_reminder_watcher_zone_free:
 * @watcher_zone: (nullable): an #EReminderWatcherZone to free
 *
 * Frees @watcher_zone, previously allocated with e_reminder_watcher_zone_copy().
 * The function does nothing when the @watcher_zone is %NULL.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_zone_free (EReminderWatcherZone *watcher_zone)
{
	if (watcher_zone)
		icaltimezone_free ((icaltimezone *) watcher_zone, 1);
}

static gchar *
e_reminder_data_to_string (const EReminderData *rd)
{
	GString *str;
	gchar *icalstr;

	g_return_val_if_fail (rd != NULL, NULL);
	g_return_val_if_fail (rd->source_uid != NULL, NULL);
	g_return_val_if_fail (rd->component != NULL, NULL);

	icalstr = e_cal_component_get_as_string (rd->component);
	g_return_val_if_fail (icalstr != NULL, NULL);

	str = g_string_sized_new (strlen (icalstr) + 100);
	g_string_append (str, rd->source_uid);
	g_string_append_c (str, '\n');

	if (rd->instance.auid)
		g_string_append (str, rd->instance.auid);
	g_string_append_c (str, '\n');

	g_string_append_printf (str, "%" G_GINT64_FORMAT, (gint64) rd->instance.trigger);
	g_string_append_c (str, '\n');

	g_string_append_printf (str, "%" G_GINT64_FORMAT, (gint64) rd->instance.occur_start);
	g_string_append_c (str, '\n');

	g_string_append_printf (str, "%" G_GINT64_FORMAT, (gint64) rd->instance.occur_end);
	g_string_append_c (str, '\n');

	g_string_append (str, icalstr);

	g_free (icalstr);

	return g_string_free (str, FALSE);
}

static EReminderData *
e_reminder_data_from_string (const gchar *str)
{
	gchar **strv;
	EReminderData *rd;
	ECalComponent *component;
	ECalComponentAlarmInstance instance;

	g_return_val_if_fail (str != NULL, NULL);

	strv = g_strsplit (str, "\n", 6);
	if (!strv)
		return NULL;

	if (!strv[0] || !strv[1] || !strv[2] || !strv[3] || !strv[4] || !strv[5] || strv[6]) {
		g_strfreev (strv);
		return NULL;
	}

	component = e_cal_component_new_from_string (strv[5]);
	if (!component) {
		g_strfreev (strv);
		return NULL;
	}

	instance.auid = (*(strv[1])) ? strv[1] : NULL;
	instance.trigger = g_ascii_strtoll (strv[2], NULL, 10);
	instance.occur_start = g_ascii_strtoll (strv[3], NULL, 10);
	instance.occur_end = g_ascii_strtoll (strv[4], NULL, 10);

	rd = e_reminder_data_new_take_component (strv[0], component, &instance);

	g_strfreev (strv);

	return rd;
}

static gint
e_reminder_data_compare (gconstpointer ptr1,
			 gconstpointer ptr2)
{
	const EReminderData *rd1 = ptr1, *rd2 = ptr2;

	if (!rd1 || !rd2) {
		if (rd1 == rd2)
			return 0;
		return !rd1 ? -1 : 1;
	}

	if (rd1->instance.trigger == rd2->instance.trigger)
		return 0;

	return rd1->instance.trigger < rd2->instance.trigger ? -1 : 1;
}

static void
e_reminder_watcher_free_rd_slist (gpointer ptr)
{
	GSList *lst = ptr;

	g_slist_free_full (lst, e_reminder_data_free);
}

/* Moves those 'data' to a new GSList for which match_func() returns TRUE.
   The passed-in slist has set the ::data members of the moved items to NULL.
   The function reverses order of the items in the returned GSList. */
static GSList *
e_reminder_watcher_move_matched (GSList *slist,
				 gboolean (* match_func) (gpointer data,
							  gpointer user_data),
				 gpointer user_data)
{
	GSList *res = NULL, *link;

	g_return_val_if_fail (match_func != NULL, NULL);

	for (link = slist; link; link = g_slist_next (link)) {
		if (match_func (link->data, user_data)) {
			res = g_slist_prepend (res, link->data);
			link->data = NULL;
		}
	}

	return res;
}

static gboolean
match_not_component_id_cb (gpointer data,
			   gpointer user_data)
{
	EReminderData *rd = data;
	ECalComponentId *id = user_data, *rd_id;
	gboolean match;

	if (!rd || !id)
		return FALSE;

	rd_id = e_cal_component_get_id (rd->component);
	match = rd_id && e_cal_component_id_equal (rd_id, id);
	e_cal_component_free_id (rd_id);

	return !match;
}

typedef struct _ObjectsChangedData {
	ECalClient *client;
	GSList *ids; /* ECalComponentId * */
	time_t interval_start;
	time_t interval_end;
	icaltimezone *zone;
} ObjectsChangedData;

static void
objects_changed_data_free (gpointer ptr)
{
	ObjectsChangedData *ocd = ptr;

	if (ocd) {
		g_clear_object (&ocd->client);
		g_slist_free_full (ocd->ids, (GDestroyNotify) e_cal_component_free_id);
		if (ocd->zone)
			e_reminder_watcher_zone_free (ocd->zone);
		g_free (ocd);
	}
}

static void
e_reminder_watcher_objects_changed_thread (GTask *task,
					   gpointer source_object,
					   gpointer task_data,
					   GCancellable *cancellable)
{
	EReminderWatcher *watcher;
	ESource *source;
	ObjectsChangedData *ocd = task_data;
	const gchar *source_uid;
	GSList *link, *reminders = NULL;

	g_return_if_fail (E_IS_REMINDER_WATCHER (source_object));
	g_return_if_fail (ocd != NULL);

	watcher = E_REMINDER_WATCHER (source_object);
	source = e_client_get_source (E_CLIENT (ocd->client));
	source_uid = e_source_get_uid (source);

	for (link = ocd->ids; link && !g_cancellable_is_cancelled (cancellable); link = g_slist_next (link)) {
		const ECalComponentId *id = link->data;
		icalcomponent *icalcomp = NULL;
		GError *local_error = NULL;

		if (!id || !id->uid || !*id->uid)
			continue;

		if (e_cal_client_get_object_sync (ocd->client, id->uid, id->rid, &icalcomp, cancellable, &local_error) && !local_error && icalcomp) {
			ECalComponent *ecomp;

			ecomp = e_cal_component_new_from_icalcomponent (icalcomp);
			if (ecomp) {
				ECalComponentAlarmAction omit[] = { -1 };
				ECalComponentAlarms *alarms;

				alarms = e_cal_util_generate_alarms_for_comp (
					ecomp, ocd->interval_start, ocd->interval_end, omit, e_cal_client_resolve_tzid_cb,
					ocd->client, ocd->zone);

				if (alarms && alarms->alarms) {
					GSList *alink;

					e_reminder_watcher_debug_print ("Source %s: Got %d alarms for object '%s':'%s' at interval %s .. %s\n", source_uid,
						g_slist_length (alarms->alarms), id->uid, id->rid ? id->rid : "",
						e_reminder_watcher_timet_as_string (ocd->interval_start),
						e_reminder_watcher_timet_as_string (ocd->interval_end));

					for (alink = alarms->alarms; alink; alink = g_slist_next (alink)) {
						const ECalComponentAlarmInstance *instance = alink->data;

						if (instance) {
							reminders = g_slist_prepend (reminders, e_reminder_data_new_take_component (
								source_uid, g_object_ref (alarms->comp), instance));
						}
					}
				} else {
					e_reminder_watcher_debug_print ("Source %s: Got no alarms for object '%s':'%s' at interval %s .. %s\n", source_uid,
						id->uid, id->rid ? id->rid : "",
						e_reminder_watcher_timet_as_string (ocd->interval_start),
						e_reminder_watcher_timet_as_string (ocd->interval_end));
				}

				if (alarms)
					e_cal_component_alarms_free (alarms);

				g_object_unref (ecomp);
			}
		} else {
			e_reminder_watcher_debug_print ("Source %s: Failed to get object '%s':'%s': %s\n", source_uid,
				id->uid, id->rid ? id->rid : "", local_error ? local_error->message : "Unknown error");
			g_clear_error (&local_error);
		}

	}

	if (reminders && !g_cancellable_is_cancelled (cancellable)) {
		g_rec_mutex_lock (&watcher->priv->lock);

		if (watcher->priv->scheduled) {
			gpointer orig_key, orig_value;
			GSList *scheduled;
			gboolean needs_reverse = FALSE;

			if (g_hash_table_lookup_extended (watcher->priv->scheduled, source_uid, &orig_key, &orig_value)) {
				scheduled = orig_value;
				g_warn_if_fail (g_hash_table_steal (watcher->priv->scheduled, orig_key));
				g_free (orig_key);
			} else {
				scheduled = NULL;
			}

			for (link = ocd->ids; link && !g_cancellable_is_cancelled (cancellable); link = g_slist_next (link)) {
				ECalComponentId *id = link->data;
				GSList *new_scheduled;

				if (!id || !id->uid)
					continue;

				new_scheduled = e_reminder_watcher_move_matched (scheduled, match_not_component_id_cb, id);
				g_slist_free_full (scheduled, e_reminder_data_free);
				scheduled = new_scheduled;
				needs_reverse = !needs_reverse;
			}

			if (reminders->next && reminders->next->next && reminders->next->next->next && reminders->next->next->next->next) {
				scheduled = g_slist_concat (reminders, scheduled);
				scheduled = g_slist_sort (scheduled, e_reminder_data_compare);
			} else {
				if (needs_reverse && scheduled)
					scheduled = g_slist_reverse (scheduled);

				for (link = reminders; link; link = g_slist_next (link)) {
					EReminderData *rd = link->data;

					if (rd)
						scheduled = g_slist_insert_sorted (scheduled, rd, e_reminder_data_compare);
				}

				/* ::data is taken by 'scheduled' */
				g_slist_free (reminders);
			}

			if (scheduled)
				g_hash_table_insert (watcher->priv->scheduled, g_strdup (source_uid), scheduled);
		}

		g_rec_mutex_unlock (&watcher->priv->lock);

		e_reminder_watcher_timer_elapsed (watcher);
	} else if (reminders) {
		g_slist_free_full (reminders, e_reminder_data_free);
	}
}

static void
e_reminder_watcher_objects_changed_done_cb (GObject *source_object,
					    GAsyncResult *result,
					    gpointer user_data)
{
	/* Nothing to be done here */
}

static void
e_reminder_watcher_objects_changed (EReminderWatcher *watcher,
				    ECalClient *client,
				    const GSList *objects) /* icalcomponent * */
{
	GSList *link, *ids = NULL;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (E_IS_CAL_CLIENT (client));

	g_rec_mutex_lock (&watcher->priv->lock);

	if (!watcher->priv->scheduled) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	for (link = (GSList *) objects; link; link = g_slist_next (link)) {
		icalcomponent *icalcomp = link->data;
		ECalComponentId *id;
		const gchar *uid;
		gchar *rid = NULL;

		uid = icalcomponent_get_uid (icalcomp);
		if (!uid || !*uid)
			continue;

		if (e_cal_util_component_is_instance (icalcomp)) {
			struct icaltimetype itt;

			itt = icalcomponent_get_recurrenceid (icalcomp);
			if (icaltime_is_valid_time (itt) && !icaltime_is_null_time (itt))
				rid = icaltime_as_ical_string_r (itt);
			else
				rid = g_strdup ("0");
		}

		id = e_cal_component_id_new (uid, rid && *rid ? rid : NULL);

		g_free (rid);

		if (id)
			ids = g_slist_prepend (ids, id);
	}

	if (ids) {
		ObjectsChangedData *ocd;
		GTask *task;

		ocd = g_new0 (ObjectsChangedData, 1);
		ocd->client = g_object_ref (client);
		ocd->ids = ids;
		ocd->interval_start = client_get_last_notification_time (client) + 1;
		if (ocd->interval_start <= 0)
			ocd->interval_start = time (NULL);
		ocd->interval_end = watcher->priv->next_midnight;
		ocd->zone = e_reminder_watcher_dup_default_zone (watcher);

		task = g_task_new (watcher, watcher->priv->cancellable, e_reminder_watcher_objects_changed_done_cb, NULL);
		g_task_set_source_tag (task, e_reminder_watcher_objects_changed_thread);
		g_task_set_task_data (task, ocd, objects_changed_data_free);

		g_task_run_in_thread (task, e_reminder_watcher_objects_changed_thread);

		g_object_unref (task);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_objects_removed (EReminderWatcher *watcher,
				    const gchar *source_uid,
				    const GSList *uids) /* ECalComponentId * */
{
	GSList *link, *scheduled;
	gpointer orig_key = NULL, orig_value = NULL;
	gboolean needs_reverse = FALSE;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (source_uid != NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (!watcher->priv->scheduled) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	if (g_hash_table_lookup_extended (watcher->priv->scheduled, source_uid, &orig_key, &orig_value)) {
		scheduled = orig_value;
		g_warn_if_fail (g_hash_table_steal (watcher->priv->scheduled, orig_key));
		g_free (orig_key);
	} else {
		scheduled = NULL;
	}

	for (link = (GSList *) uids; link && scheduled; link = g_slist_next (link)) {
		ECalComponentId *id = link->data;
		GSList *new_scheduled;

		if (!id || !id->uid)
			continue;

		new_scheduled = e_reminder_watcher_move_matched (scheduled, match_not_component_id_cb, id);
		g_slist_free_full (scheduled, e_reminder_data_free);
		scheduled = new_scheduled;
		needs_reverse = !needs_reverse;
	}

	if (scheduled) {
		if (needs_reverse)
			scheduled = g_slist_reverse (scheduled);
		g_hash_table_insert (watcher->priv->scheduled, g_strdup (source_uid), scheduled);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_objects_added_cb (ECalClientView *view,
				     const GSList *objects, /* icalcomponent * */
				     gpointer user_data)
{
	EReminderWatcher *watcher = user_data;
	ECalClient *client;
	ESource *source;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	client = e_cal_client_view_ref_client (view);
	source = client ? e_client_get_source (E_CLIENT (client)) : NULL;

	e_reminder_watcher_debug_print ("View for %s added %d objects\n",
		source ? e_source_get_uid (source) : "[null]",
		g_slist_length ((GSList *) objects));

	if (source)
		e_reminder_watcher_objects_changed (watcher, client, objects);

	g_clear_object (&client);
}

static void
e_reminder_watcher_objects_modified_cb (ECalClientView *view,
					const GSList *objects, /* icalcomponent * */
					gpointer user_data)
{
	EReminderWatcher *watcher = user_data;
	ECalClient *client;
	ESource *source;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	client = e_cal_client_view_ref_client (view);
	source = client ? e_client_get_source (E_CLIENT (client)) : NULL;

	e_reminder_watcher_debug_print ("View for %s modified %d objects\n",
		source ? e_source_get_uid (source) : "[null]",
		g_slist_length ((GSList *) objects));

	if (source)
		e_reminder_watcher_objects_changed (watcher, client, objects);

	g_clear_object (&client);
}

static void
e_reminder_watcher_objects_removed_cb (ECalClientView *view,
				       const GSList *uids, /* ECalComponentId * */
				       gpointer user_data)
{
	EReminderWatcher *watcher = user_data;
	ECalClient *client;
	ESource *source;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	client = e_cal_client_view_ref_client (view);
	source = client ? e_client_get_source (E_CLIENT (client)) : NULL;

	e_reminder_watcher_debug_print ("View for %s removed %d objects\n",
		source ? e_source_get_uid (source) : "[null]",
		g_slist_length ((GSList *) uids));

	if (source)
		e_reminder_watcher_objects_removed (watcher, e_source_get_uid (source), uids);

	g_clear_object (&client);
}

static void
e_reminder_watcher_calc_next_midnight (EReminderWatcher *watcher)
{
	time_t now, midnight;

	g_rec_mutex_lock (&watcher->priv->lock);

	now = time (NULL);
	midnight = time_day_end_with_zone (now, watcher->priv->default_zone);

	while (midnight <= now) {
		now += 60 * 60; /* increment one day */
		midnight = time_day_end_with_zone (now, watcher->priv->default_zone);
		e_reminder_watcher_debug_print ("Required correction of the day end, now at %s\n", e_reminder_watcher_timet_as_string ((gint64) midnight));
	}

	if (watcher->priv->next_midnight != midnight && watcher->priv->timers_enabled) {
		GSList *link;

		e_reminder_watcher_debug_print ("Next midnight at %s\n", e_reminder_watcher_timet_as_string ((gint64) midnight));
		watcher->priv->next_midnight = midnight;

		for (link = watcher->priv->clients; link; link = g_slist_next (link)) {
			ClientData *cd = link->data;

			if (cd && cd->client)
				client_data_start_view (cd, watcher->priv->next_midnight, watcher->priv->cancellable);
		}
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static gboolean
e_reminder_watcher_timer_elapsed_cb (gpointer user_data)
{
	EReminderWatcher *watcher = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_rec_mutex_lock (&watcher->priv->lock);
	watcher->priv->timer_handler_id = 0;
	g_rec_mutex_unlock (&watcher->priv->lock);

	e_reminder_watcher_timer_elapsed (watcher);

	return FALSE;
}

static void
e_reminder_watcher_schedule_timer_impl (EReminderWatcher *watcher,
					gint64 at_time)
{
	gint64 current_time;

	g_rec_mutex_lock (&watcher->priv->lock);

	current_time = g_get_real_time () / G_USEC_PER_SEC;

	if (current_time >= at_time) {
		e_reminder_watcher_timer_elapsed (watcher);
	} else {
		if (watcher->priv->timer_handler_id)
			g_source_remove (watcher->priv->timer_handler_id);

		watcher->priv->timer_handler_id = e_named_timeout_add_seconds (at_time - current_time, e_reminder_watcher_timer_elapsed_cb, watcher);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_format_time_impl (EReminderWatcher *watcher,
				     const EReminderData *rd,
				     struct icaltimetype *itt,
				     gchar **inout_buffer,
				     gint buffer_size)
{
	struct tm tm;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (rd != NULL);
	g_return_if_fail (itt != NULL);
	g_return_if_fail (inout_buffer != NULL);
	g_return_if_fail (*inout_buffer != NULL);
	g_return_if_fail (buffer_size > 0);

	tm = icaltimetype_to_tm (itt);
	e_time_format_date_and_time (&tm, FALSE, FALSE, FALSE, *inout_buffer, buffer_size);
}

static GSList * /* EReminderData * */
e_reminder_watcher_reminders_from_key (EReminderWatcher *watcher,
				       const gchar *key)
{
	GSList *list = NULL;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (watcher->priv->settings) {
		gchar **strv;
		gint ii;

		strv = g_settings_get_strv (watcher->priv->settings, key);
		if (strv) {
			for (ii = 0; strv[ii]; ii++) {
				EReminderData *rd;

				rd = e_reminder_data_from_string (strv[ii]);
				if (rd)
					list = g_slist_prepend (list, rd);
			}

			g_strfreev (strv);
		}
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	return g_slist_reverse (list);
}

static gchar **
e_reminder_watcher_slist_to_strv (const GSList *reminders) /* EReminderData * */
{
	GSList *link;
	gint ii;
	gchar **strv;

	if (!reminders)
		return NULL;

	strv = g_new0 (gchar *, 1 + g_slist_length ((GSList *) reminders));

	for (ii = 0, link = (GSList *) reminders; link; link = g_slist_next (link)) {
		gchar *str;

		str = e_reminder_data_to_string (link->data);
		if (str) {
			strv[ii] = str;
			ii++;
		}
	}

	strv[ii] = NULL;

	return strv;
}

static EReminderData * /* one from reminders, corresponding to rd */
e_reminder_watcher_find (GSList *reminders, /* EReminderData * */
			 const EReminderData *rd)
{
	ECalComponentId *id1 = NULL;
	EReminderData *found = NULL;
	GSList *link;

	g_return_val_if_fail (rd != NULL, NULL);

	for (link = reminders; !found && link; link = g_slist_next (link)) {
		EReminderData *rd2 = link->data;
		ECalComponentId *id2;

		if (!rd2 || g_strcmp0 (rd2->source_uid, rd->source_uid) != 0)
			continue;

		if (!id1) {
			id1 = e_cal_component_get_id (rd->component);
			if (!id1)
				break;
		}

		id2 = e_cal_component_get_id (rd2->component);

		if (id2) {
			if (g_strcmp0 (id1->uid, id2->uid) == 0 && (
			    (g_strcmp0 (id1->rid, id2->rid) == 0 ||
			    ((!id1->rid || !*(id1->rid)) && (!id2->rid || !*(id2->rid))))) &&
			    g_strcmp0 (rd->instance.auid, rd2->instance.auid) == 0 &&
			    rd->instance.trigger == rd2->instance.trigger)
				found = rd2;

			e_cal_component_free_id (id2);
		}
	}

	if (id1)
		e_cal_component_free_id (id1);

	return found;
}

typedef struct _EmitSignalData {
	EReminderWatcher *watcher;
	guint signal_id;
	GSList *reminders; /* EReminderData * */
	gboolean is_snoozed; /* only for the triggered signal */
} EmitSignalData;

static void
emit_signal_data_free (gpointer ptr)
{
	EmitSignalData *esd = ptr;

	if (esd) {
		g_clear_object (&esd->watcher);
		g_slist_free_full (esd->reminders, e_reminder_data_free);
		g_free (esd);
	}
}

static gboolean
e_reminder_watcher_emit_signal_idle_cb (gpointer user_data)
{
	EmitSignalData *esd = user_data;

	g_return_val_if_fail (esd != NULL, FALSE);
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (esd->watcher), FALSE);

	if (esd->signal_id == signals[TRIGGERED])
		g_signal_emit (esd->watcher, esd->signal_id, 0, esd->reminders, esd->is_snoozed, NULL);
	else
		g_signal_emit (esd->watcher, esd->signal_id, 0, esd->reminders, NULL);

	return FALSE;
}

static void
e_reminder_watcher_emit_signal_idle_multiple (EReminderWatcher *watcher,
					      guint signal_id,
					      const GSList *reminders, /* EReminderData * */
					      gboolean is_snoozed)
{
	EmitSignalData *esd;

	esd = g_new0 (EmitSignalData, 1);
	esd->watcher = g_object_ref (watcher);
	esd->signal_id = signal_id;
	esd->reminders = g_slist_copy_deep ((GSList *) reminders, (GCopyFunc) e_reminder_data_copy, NULL);
	esd->is_snoozed = is_snoozed;

	g_idle_add_full (G_PRIORITY_HIGH_IDLE, e_reminder_watcher_emit_signal_idle_cb, esd, emit_signal_data_free);
}

static void
e_reminder_watcher_emit_signal_idle (EReminderWatcher *watcher,
				     guint signal_id,
				     const EReminderData *rd)
{
	GSList *reminders = NULL;

	if (rd)
		reminders = g_slist_prepend (NULL, e_reminder_data_copy (rd));

	e_reminder_watcher_emit_signal_idle_multiple (watcher, signal_id, reminders, FALSE);

	g_slist_free_full (reminders, e_reminder_data_free);
}

static void
e_reminder_watcher_save_list (EReminderWatcher *watcher,
			      const gchar *key,
			      const GSList *reminders) /* EReminderData * */
{
	gchar **strv;

	strv = e_reminder_watcher_slist_to_strv (reminders);
	g_settings_set_strv (watcher->priv->settings, key, (const gchar * const *) strv);
	g_strfreev (strv);
}

static void
e_reminder_watcher_save_past (EReminderWatcher *watcher,
			      GSList *reminders) /* EReminderData * */
{
	g_rec_mutex_lock (&watcher->priv->lock);
	watcher->priv->expected_past_changes++;
	e_reminder_watcher_save_list (watcher, "reminders-past", reminders);
	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_save_snoozed (EReminderWatcher *watcher)
{
	g_rec_mutex_lock (&watcher->priv->lock);
	watcher->priv->expected_snoozed_changes++;
	e_reminder_watcher_save_list (watcher, "reminders-snoozed", watcher->priv->snoozed);
	g_rec_mutex_unlock (&watcher->priv->lock);
}

static gboolean
e_reminder_watcher_remove_from_past (EReminderWatcher *watcher,
				     const EReminderData *rd)
{
	GSList *reminders;
	EReminderData *found;
	gboolean changed = FALSE;

	g_return_val_if_fail (rd != NULL, FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	reminders = e_reminder_watcher_dup_past (watcher);
	found = e_reminder_watcher_find (reminders, rd);
	if (found) {
		reminders = g_slist_remove (reminders, found);
		changed = TRUE;

		e_reminder_watcher_save_past (watcher, reminders);

		e_reminder_watcher_debug_print ("Removed reminder from past for '%s' from %s at %s\n",
			icalcomponent_get_summary (e_cal_component_get_icalcomponent (found->component)),
			found->source_uid,
			e_reminder_watcher_timet_as_string (found->instance.trigger));

		e_reminder_data_free (found);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	g_slist_free_full (reminders, e_reminder_data_free);

	return changed;
}

static gboolean
e_reminder_watcher_remove_from_snoozed (EReminderWatcher *watcher,
					const EReminderData *rd,
					gboolean with_save)
{
	EReminderData *found;
	gboolean changed = FALSE;

	g_return_val_if_fail (rd != NULL, FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	found = e_reminder_watcher_find (watcher->priv->snoozed, rd);
	if (found) {
		watcher->priv->snoozed = g_slist_remove (watcher->priv->snoozed, found);
		changed = TRUE;

		if (with_save)
			e_reminder_watcher_save_snoozed (watcher);

		e_reminder_watcher_debug_print ("Removed reminder from snoozed for '%s' from %s at %s\n",
			icalcomponent_get_summary (e_cal_component_get_icalcomponent (found->component)),
			found->source_uid,
			e_reminder_watcher_timet_as_string (found->instance.trigger));

		e_reminder_data_free (found);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	return changed;
}

static ECalClient *
e_reminder_watcher_ref_client (EReminderWatcher *watcher,
			       const gchar *source_uid,
			       GCancellable *cancellable)
{
	ECalClient *client = NULL;
	GSList *link;

	g_return_val_if_fail (source_uid != NULL, NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	for (link = watcher->priv->clients; link; link = g_slist_next (link)) {
		const ClientData *cd = link->data;

		if (!cd || !cd->client)
			continue;

		if (g_strcmp0 (source_uid, e_source_get_uid (e_client_get_source (E_CLIENT (cd->client)))) == 0) {
			client = g_object_ref (cd->client);
			break;
		}
	}

	if (!client && cancellable) {
		ESourceRegistry *registry;
		ESource *source;

		registry = g_object_ref (watcher->priv->registry);

		g_rec_mutex_unlock (&watcher->priv->lock);

		source = e_source_registry_ref_source (registry, source_uid);
		if (source) {
			ECalClientSourceType source_type = E_CAL_CLIENT_SOURCE_TYPE_LAST;

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR))
				source_type = E_CAL_CLIENT_SOURCE_TYPE_EVENTS;
			else if (e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST))
				source_type = E_CAL_CLIENT_SOURCE_TYPE_MEMOS;
			else if (e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST))
				source_type = E_CAL_CLIENT_SOURCE_TYPE_TASKS;

			if (source_type != E_CAL_CLIENT_SOURCE_TYPE_LAST) {
				EReminderWatcherClass *klass;
				EClient *tmp_client;
				GError *local_error = NULL;

				klass = E_REMINDER_WATCHER_GET_CLASS (watcher);
				if (klass && klass->cal_client_connect_sync) {
					tmp_client = klass->cal_client_connect_sync (watcher, source, source_type, 30, cancellable, &local_error);
				} else {
					g_warn_if_fail (klass && klass->cal_client_connect_sync);
					tmp_client = NULL;
				}

				if (tmp_client)
					client = E_CAL_CLIENT (tmp_client);

				if (!client) {
					e_reminder_watcher_debug_print ("Failed to connect client '%s': %s\n", source_uid, local_error ? local_error->message : "Unknown error");
					g_clear_error (&local_error);
				} else if (tmp_client) {
					client = E_CAL_CLIENT (tmp_client);
				}
			}
		}

		g_clear_object (&source);
		g_clear_object (&registry);
	} else {
		g_rec_mutex_unlock (&watcher->priv->lock);
	}

	return client;
}

static gboolean
e_reminder_watcher_add (GSList **inout_reminders, /* EReminderData * */
			EReminderData *rd, /* assumes ownership of 'rd' */
			gboolean with_lookup,
			gboolean sorted)
{
	g_return_val_if_fail (inout_reminders != NULL, FALSE);

	if (with_lookup) {
		EReminderData *found;

		found = e_reminder_watcher_find (*inout_reminders, rd);
		if (found) {
			*inout_reminders = g_slist_remove (*inout_reminders, found);
			e_reminder_data_free (found);
		}
	}

	if (sorted)
		*inout_reminders = g_slist_insert_sorted (*inout_reminders, rd, e_reminder_data_compare);
	else
		*inout_reminders = g_slist_prepend (*inout_reminders, rd);

	return TRUE;
}

static void
e_reminder_watcher_gather_nearest_scheduled_cb (gpointer key,
						gpointer value,
						gpointer user_data)
{
	GSList *reminders = value;
	gint *out_nearest = user_data;
	EReminderData *rd = reminders ? reminders->data : NULL;

	if (rd && out_nearest && (!*out_nearest || rd->instance.trigger < *out_nearest))
		*out_nearest = rd->instance.trigger;
}

static gint64
e_reminder_watcher_get_nearest_scheduled (EReminderWatcher *watcher)
{
	gint64 res = 0;

	g_rec_mutex_lock (&watcher->priv->lock);

	if (watcher->priv->scheduled)
		g_hash_table_foreach (watcher->priv->scheduled, e_reminder_watcher_gather_nearest_scheduled_cb, &res);

	g_rec_mutex_unlock (&watcher->priv->lock);

	return res;
}

static void
e_reminder_watcher_maybe_schedule_next_trigger (EReminderWatcher *watcher,
						gint64 next_trigger)
{
	g_rec_mutex_lock (&watcher->priv->lock);

	if (!watcher->priv->timers_enabled) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	e_reminder_watcher_calc_next_midnight (watcher);

	if (watcher->priv->snoozed && watcher->priv->snoozed->data) {
		const EReminderData *rd = watcher->priv->snoozed->data;

		if (next_trigger <= 0 || rd->instance.trigger < next_trigger)
			next_trigger = rd->instance.trigger;
	}

	if (watcher->priv->scheduled) {
		gint64 nearest_scheduled = e_reminder_watcher_get_nearest_scheduled (watcher);

		if (nearest_scheduled > 0 && (next_trigger <= 0 || nearest_scheduled < next_trigger))
			next_trigger = nearest_scheduled;
	}

	if (next_trigger <= 0 || watcher->priv->next_midnight < next_trigger)
		next_trigger = watcher->priv->next_midnight;

	if (watcher->priv->next_trigger != next_trigger) {
		EReminderWatcherClass *klass;

		watcher->priv->next_trigger = next_trigger;

		klass = E_REMINDER_WATCHER_GET_CLASS (watcher);
		g_warn_if_fail (klass->schedule_timer != NULL);

		e_reminder_watcher_debug_print ("Going to schedule next trigger at %s\n", e_reminder_watcher_timet_as_string (next_trigger));

		if (klass->schedule_timer)
			klass->schedule_timer (watcher, next_trigger);
		else
			e_reminder_watcher_schedule_timer_impl (watcher, next_trigger);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_reminders_past_changed_cb (GSettings *settings,
					      const gchar *key,
					      gpointer user_data)
{
	EReminderWatcher *watcher = user_data;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (key != NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (watcher->priv->expected_past_changes) {
		watcher->priv->expected_past_changes--;
		e_reminder_watcher_debug_print ("GSettings::%s possibly changed, but ignored, because it was expected\n", key);
	} else {
		e_reminder_watcher_debug_print ("GSettings::%s possibly changed\n", key);

		/* Cannot determine whether it really changed, because the past reminders
		   are not held in memory. */
		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_reminders_snoozed_changed_cb (GSettings *settings,
						 const gchar *key,
						 gpointer user_data)
{
	EReminderWatcher *watcher = user_data;
	GSList *new_snoozed, *old_snoozed, *link;
	gboolean changed = FALSE;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (key != NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (watcher->priv->expected_snoozed_changes) {
		watcher->priv->expected_snoozed_changes--;
		e_reminder_watcher_debug_print ("GSettings::%s possibly changed, but ignored, because it was expected\n", key);
		g_rec_mutex_unlock (&watcher->priv->lock);

		return;
	}

	e_reminder_watcher_debug_print ("GSettings::%s possibly changed\n", key);

	new_snoozed = e_reminder_watcher_reminders_from_key (watcher, "reminders-snoozed");
	if (new_snoozed) {
		old_snoozed = watcher->priv->snoozed;
		watcher->priv->snoozed = g_slist_sort (new_snoozed, e_reminder_data_compare);

		for (link = old_snoozed; link; link = g_slist_next (link)) {
			EReminderData *rd = link->data;

			if (rd && !e_reminder_watcher_find (watcher->priv->snoozed, rd)) {
				changed = TRUE;

				e_reminder_watcher_debug_print ("Removed reminder from snoozed for '%s' from %s at %s\n",
					icalcomponent_get_summary (e_cal_component_get_icalcomponent (rd->component)),
					rd->source_uid,
					e_reminder_watcher_timet_as_string (rd->instance.trigger));
			}
		}

		for (link = watcher->priv->snoozed; link; link = g_slist_next (link)) {
			EReminderData *rd = link->data;

			if (rd && !e_reminder_watcher_find (old_snoozed, rd)) {
				changed = TRUE;

				e_reminder_watcher_debug_print ("Added reminder to snoozed for '%s' from %s at %s\n",
					icalcomponent_get_summary (e_cal_component_get_icalcomponent (rd->component)),
					rd->source_uid,
					e_reminder_watcher_timet_as_string (rd->instance.trigger));
			}
		}

		g_slist_free_full (old_snoozed, e_reminder_data_free);
	} else if (watcher->priv->snoozed) {
		old_snoozed = watcher->priv->snoozed;
		watcher->priv->snoozed = NULL;

		changed = TRUE;

		for (link = old_snoozed; link; link = g_slist_next (link)) {
			EReminderData *rd = link->data;

			if (!rd)
				continue;

			e_reminder_watcher_debug_print ("Removed reminder from snoozed for '%s' from %s at %s\n",
				icalcomponent_get_summary (e_cal_component_get_icalcomponent (rd->component)),
				rd->source_uid,
				e_reminder_watcher_timet_as_string (rd->instance.trigger));
		}

		g_slist_free_full (old_snoozed, e_reminder_data_free);
	}

	if (changed) {
		e_reminder_watcher_maybe_schedule_next_trigger (watcher, 0);
		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static gboolean
e_reminder_watcher_filter_source_cb (ESourceRegistryWatcher *watcher,
				     ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	if (!e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR) &&
	    !e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST) &&
	    !e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST))
		return FALSE;

	return !e_source_has_extension (source, E_SOURCE_EXTENSION_ALARMS) ||
	    e_source_alarms_get_include_me (e_source_get_extension (source, E_SOURCE_EXTENSION_ALARMS));
}

static void
e_reminder_watcher_client_connect_cb (GObject *source_object,
				      GAsyncResult *result,
				      gpointer user_data)
{
	EReminderWatcher *watcher = user_data;
	EReminderWatcherClass *klass;
	EClient *client;
	ClientData *cd;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	klass = E_REMINDER_WATCHER_GET_CLASS (watcher);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->cal_client_connect_finish != NULL);

	client = klass->cal_client_connect_finish (watcher, result, &local_error);
	if (!client) {
		e_reminder_watcher_debug_print ("Failed to connect client: %s\n", local_error ? local_error->message : "Unknown error");
		g_clear_error (&local_error);
		g_object_unref (watcher);
		return;
	}

	g_rec_mutex_lock (&watcher->priv->lock);

	cd = client_data_new (watcher, E_CAL_CLIENT (client));
	if (cd) {
		ESource *source = e_client_get_source (client);

		e_reminder_watcher_debug_print ("Connected client: %s (%s)\n", e_source_get_uid (source), e_source_get_display_name (source));

		watcher->priv->clients = g_slist_prepend (watcher->priv->clients, cd);

		if (watcher->priv->timers_enabled)
			client_data_start_view (cd, watcher->priv->next_midnight, watcher->priv->cancellable);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	g_object_unref (watcher);
}

static void
e_reminder_watcher_source_appeared_cb (EReminderWatcher *watcher,
				       ESource *source)
{
	EReminderWatcherClass *klass;
	ECalClientSourceType source_type;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (E_IS_SOURCE (source));

	klass = E_REMINDER_WATCHER_GET_CLASS (watcher);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->cal_client_connect != NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR))
		source_type = E_CAL_CLIENT_SOURCE_TYPE_EVENTS;
	else if (e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST))
		source_type = E_CAL_CLIENT_SOURCE_TYPE_MEMOS;
	else if (e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST))
		source_type = E_CAL_CLIENT_SOURCE_TYPE_TASKS;
	else {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	if (watcher->priv->timers_enabled)
		klass->cal_client_connect (watcher, source, source_type, 30, watcher->priv->cancellable, e_reminder_watcher_client_connect_cb, g_object_ref (watcher));

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_source_disappeared_cb (EReminderWatcher *watcher,
					  ESource *source)
{
	GSList *link;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (E_IS_SOURCE (source));

	g_rec_mutex_lock (&watcher->priv->lock);

	for (link = watcher->priv->clients; link; link = g_slist_next (link)) {
		ClientData *cd = link->data;

		if (cd && cd->client && g_strcmp0 (e_source_get_uid (source),
		    e_source_get_uid (e_client_get_source (E_CLIENT (cd->client)))) == 0) {
			e_reminder_watcher_debug_print ("Removed client: %s (%s)\n", e_source_get_uid (source), e_source_get_display_name (source));
			watcher->priv->clients = g_slist_remove (watcher->priv->clients, cd);
			client_data_free (cd);
			break;
		}
	}

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static gboolean
e_reminder_watcher_construct_idle_cb (gpointer user_data)
{
	EReminderWatcher *watcher = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	watcher->priv->construct_idle_id = 0;
	watcher->priv->registry_watcher = e_source_registry_watcher_new (watcher->priv->registry, NULL);

	g_signal_connect (watcher->priv->registry_watcher, "filter",
		G_CALLBACK (e_reminder_watcher_filter_source_cb), watcher);

	g_signal_connect_swapped (watcher->priv->registry_watcher, "appeared",
		G_CALLBACK (e_reminder_watcher_source_appeared_cb), watcher);

	g_signal_connect_swapped (watcher->priv->registry_watcher, "disappeared",
		G_CALLBACK (e_reminder_watcher_source_disappeared_cb), watcher);

	e_source_registry_watcher_reclaim (watcher->priv->registry_watcher);

	if (!watcher->priv->snoozed)
		watcher->priv->snoozed = e_reminder_watcher_reminders_from_key (watcher, "reminders-snoozed");

	e_reminder_watcher_maybe_schedule_next_trigger (watcher, 0);

	if (!watcher->priv->past_changed_handler_id) {
		watcher->priv->past_changed_handler_id = g_signal_connect (watcher->priv->settings, "changed::reminders-past",
			G_CALLBACK (e_reminder_watcher_reminders_past_changed_cb), watcher);
	}

	if (!watcher->priv->snoozed_changed_handler_id) {
		watcher->priv->snoozed_changed_handler_id = g_signal_connect (watcher->priv->settings, "changed::reminders-snoozed",
			G_CALLBACK (e_reminder_watcher_reminders_snoozed_changed_cb), watcher);
	}

	/* Read from the keys, otherwise the "changed" signal won't be emitted by GSettings */
	g_strfreev (g_settings_get_strv (watcher->priv->settings, "reminders-past"));
	g_strfreev (g_settings_get_strv (watcher->priv->settings, "reminders-snoozed"));

	g_rec_mutex_unlock (&watcher->priv->lock);

	return FALSE;
}

static EClient *
e_reminder_watcher_cal_client_connect_sync (EReminderWatcher *watcher,
					    ESource *source,
					    ECalClientSourceType source_type,
					    guint32 wait_for_connected_seconds,
					    GCancellable *cancellable,
					    GError **error)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	return e_cal_client_connect_sync (source, source_type, wait_for_connected_seconds, cancellable, error);
}

static void
e_reminder_watcher_cal_client_connect (EReminderWatcher *watcher,
				       ESource *source,
				       ECalClientSourceType source_type,
				       guint32 wait_for_connected_seconds,
				       GCancellable *cancellable,
				       GAsyncReadyCallback callback,
				       gpointer user_data)
{
	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	e_cal_client_connect (source, source_type, wait_for_connected_seconds, cancellable, callback, user_data);
}

static EClient *
e_reminder_watcher_cal_client_connect_finish (EReminderWatcher *watcher,
					      GAsyncResult *result,
					      GError **error)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	return e_cal_client_connect_finish (result, error);
}

static void
reminder_watcher_set_registry (EReminderWatcher *watcher,
			       ESourceRegistry *registry)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (watcher->priv->registry == NULL);

	watcher->priv->registry = g_object_ref (registry);
}

static void
e_reminder_watcher_set_property (GObject *object,
				 guint property_id,
				 const GValue *value,
				 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			reminder_watcher_set_registry (
				E_REMINDER_WATCHER (object),
				g_value_get_object (value));
			return;

		case PROP_DEFAULT_ZONE:
			e_reminder_watcher_set_default_zone (
				E_REMINDER_WATCHER (object),
				g_value_get_boxed (value));
			return;

		case PROP_TIMERS_ENABLED:
			e_reminder_watcher_set_timers_enabled (
				E_REMINDER_WATCHER (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_reminder_watcher_get_property (GObject *object,
				 guint property_id,
				 GValue *value,
				 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			g_value_set_object (
				value,
				e_reminder_watcher_get_registry (
				E_REMINDER_WATCHER (object)));
			return;

		case PROP_DEFAULT_ZONE:
			g_value_take_boxed (
				value,
				e_reminder_watcher_dup_default_zone (
				E_REMINDER_WATCHER (object)));
			return;

		case PROP_TIMERS_ENABLED:
			g_value_set_boolean (
				value,
				e_reminder_watcher_get_timers_enabled (
				E_REMINDER_WATCHER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_reminder_watcher_constructed (GObject *object)
{
	EReminderWatcher *watcher = E_REMINDER_WATCHER (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminder_watcher_parent_class)->constructed (object);

	g_rec_mutex_lock (&watcher->priv->lock);

	watcher->priv->construct_idle_id = g_idle_add (e_reminder_watcher_construct_idle_cb, watcher);

	g_rec_mutex_unlock (&watcher->priv->lock);
}

static void
e_reminder_watcher_dispose (GObject *object)
{
	EReminderWatcher *watcher = E_REMINDER_WATCHER (object);

	g_rec_mutex_lock (&watcher->priv->lock);

	if (watcher->priv->construct_idle_id) {
		g_source_remove (watcher->priv->construct_idle_id);
		watcher->priv->construct_idle_id = 0;
	}

	if (watcher->priv->wall_clock_handler_id) {
		g_source_remove (watcher->priv->wall_clock_handler_id);
		watcher->priv->wall_clock_handler_id = 0;
	}

	if (watcher->priv->timer_handler_id) {
		g_source_remove (watcher->priv->timer_handler_id);
		watcher->priv->timer_handler_id = 0;
	}

	if (watcher->priv->cancellable)
		g_cancellable_cancel (watcher->priv->cancellable);

	g_slist_free_full (watcher->priv->clients, client_data_free);
	watcher->priv->clients = NULL;

	g_slist_free_full (watcher->priv->snoozed, e_reminder_data_free);
	watcher->priv->snoozed = NULL;

	if (watcher->priv->scheduled) {
		g_hash_table_destroy (watcher->priv->scheduled);
		watcher->priv->scheduled = NULL;
	}

	if (watcher->priv->settings && watcher->priv->past_changed_handler_id) {
		g_signal_handler_disconnect (watcher->priv->settings, watcher->priv->past_changed_handler_id);
		watcher->priv->past_changed_handler_id = 0;
	}

	if (watcher->priv->settings && watcher->priv->snoozed_changed_handler_id) {
		g_signal_handler_disconnect (watcher->priv->settings, watcher->priv->snoozed_changed_handler_id);
		watcher->priv->snoozed_changed_handler_id = 0;
	}

	g_clear_object (&watcher->priv->cancellable);
	g_clear_object (&watcher->priv->settings);
	g_clear_object (&watcher->priv->registry_watcher);
	g_clear_object (&watcher->priv->registry);

	g_rec_mutex_unlock (&watcher->priv->lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminder_watcher_parent_class)->dispose (object);
}

static void
e_reminder_watcher_finalize (GObject *object)
{
	EReminderWatcher *watcher = E_REMINDER_WATCHER (object);

	e_reminder_watcher_zone_free ((EReminderWatcherZone *) watcher->priv->default_zone);
	g_rec_mutex_clear (&watcher->priv->lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminder_watcher_parent_class)->finalize (object);
}

static void
e_reminder_watcher_class_init (EReminderWatcherClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (EReminderWatcherPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = e_reminder_watcher_set_property;
	object_class->get_property = e_reminder_watcher_get_property;
	object_class->constructed = e_reminder_watcher_constructed;
	object_class->dispose = e_reminder_watcher_dispose;
	object_class->finalize = e_reminder_watcher_finalize;

	klass->schedule_timer = e_reminder_watcher_schedule_timer_impl;
	klass->format_time = e_reminder_watcher_format_time_impl;
	klass->cal_client_connect_sync = e_reminder_watcher_cal_client_connect_sync;
	klass->cal_client_connect = e_reminder_watcher_cal_client_connect;
	klass->cal_client_connect_finish = e_reminder_watcher_cal_client_connect_finish;

	/**
	 * EReminderWatcher:registry:
	 *
	 * The #ESourceRegistry which manages #ESource instances.
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_REGISTRY,
		g_param_spec_object (
			"registry",
			"Registry",
			"Data source registry",
			E_TYPE_SOURCE_REGISTRY,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EReminderWatcher:default-zone:
	 *
	 * An icaltimezone to be used as the default time zone.
	 * It's encapsulated in a boxed type #EReminderWatcherZone.
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_DEFAULT_ZONE,
		g_param_spec_boxed (
			"default-zone",
			"Default Zone",
			"The default time zone",
			E_TYPE_REMINDER_WATCHER_ZONE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EReminderWatcher:timers-enabled:
	 *
	 * Whether timers are enabled for the #EReminderWatcher. See
	 * e_reminder_watcher_set_timers_enabled() for more information
	 * what it means.
	 *
	 * Default: %TRUE
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_TIMERS_ENABLED,
		g_param_spec_boolean (
			"timers-enabled",
			"Timers Enabled",
			"Whether can schedule timers",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EReminderWatcher::format-time:
	 * @watcher: an #EReminderWatcher
	 * @rd: an #EReminderData
	 * @itt: a pointer to struct icaltimetype
	 * @inout_buffer: (caller allocates) (inout): a pointer to a buffer to fill with formatted @itt
	 * @buffer_size: size of inout_buffer
	 *
	 * Formats time @itt to a string and writes it to @inout_buffer, which can hold
	 * up to @buffer_size bytes. The first character of @inout_buffer is the nul-byte
	 * when nothing wrote to it yet.
	 *
	 * Since: 3.30
	 **/
	signals[FORMAT_TIME] = g_signal_new (
		"format-time",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (EReminderWatcherClass, format_time),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 4,
		G_TYPE_POINTER,
		G_TYPE_POINTER,
		G_TYPE_POINTER,
		G_TYPE_INT);

	/**
	 * EReminderWatcher::triggered:
	 * @watcher: an #EReminderWatcher
	 * @reminders: (element-type EReminderData): a #GSList of #EReminderData
	 * @snoozed: %TRUE, when the @reminders had been snoozed, %FALSE otherwise
	 *
	 * Signal is emitted when any reminder is either overdue or triggered.
	 *
	 * Since: 3.30
	 **/
	signals[TRIGGERED] = g_signal_new (
		"triggered",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EReminderWatcherClass, triggered),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 2,
		G_TYPE_POINTER,
		G_TYPE_BOOLEAN);

	/**
	 * EReminderWatcher::changed:
	 * @watcher: an #EReminderWatcher
	 *
	 * Signal is emitted when the list of past or snoozed reminders
	 * changes. It's called also when GSettings key for past reminders
	 * is notified as changed, because this list is not held in memory.
	 *
	 * Since: 3.30
	 **/
	signals[CHANGED] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EReminderWatcherClass, changed),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 0,
		G_TYPE_NONE);
}

static void
e_reminder_watcher_init (EReminderWatcher *watcher)
{
	icaltimezone *zone = NULL;
	gchar *location;

	location = e_cal_system_timezone_get_location ();
	if (location) {
		zone = icaltimezone_get_builtin_timezone (location);
		g_free (location);
	}

	if (!zone)
		zone = icaltimezone_get_utc_timezone ();

	watcher->priv = G_TYPE_INSTANCE_GET_PRIVATE (watcher, E_TYPE_REMINDER_WATCHER, EReminderWatcherPrivate);
	watcher->priv->cancellable = g_cancellable_new ();
	watcher->priv->settings = g_settings_new ("org.gnome.evolution-data-server.calendar");
	watcher->priv->scheduled = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, e_reminder_watcher_free_rd_slist);
	watcher->priv->default_zone = icaltimezone_copy (zone);
	watcher->priv->timers_enabled = TRUE;

	g_rec_mutex_init (&watcher->priv->lock);
}

/**
 * e_reminder_watcher_new:
 * @registry: (transfer none): an #ESourceRegistry
 *
 * Creates a new #EReminderWatcher, which will use the @registry. It adds
 * its own reference to @registry. Free the created #EReminderWatcher
 * with g_object_unref() when no longer needed.
 *
 * Returns: (transfer full): a new instance of #EReminderWatcher
 *
 * Since: 3.30
 **/
EReminderWatcher *
e_reminder_watcher_new (ESourceRegistry *registry)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), NULL);

	return g_object_new (E_TYPE_REMINDER_WATCHER,
		"registry", registry,
		NULL);
}

/**
 * e_reminder_watcher_get_registry:
 * @watcher: an #EReminderWatcher
 *
 * Returns: (transfer none): an #ESourceRegistry with which the @watcher
 *    had been created
 **/
ESourceRegistry *
e_reminder_watcher_get_registry (EReminderWatcher *watcher)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	return watcher->priv->registry;
}

/**
 * e_reminders_widget_ref_opened_client:
 * @watcher: an #EReminderWatcher
 * @source_uid: an #ESource UID of the calendar to return
 *
 * Returns: (nullable) (transfer full): a referenced #ECalClient for the @source_uid,
 *    if any such is opened; %NULL otherwise.
 *
 * Since: 3.30
 **/
ECalClient *
e_reminder_watcher_ref_opened_client (EReminderWatcher *watcher,
				      const gchar *source_uid)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);
	g_return_val_if_fail (source_uid != NULL, NULL);

	return e_reminder_watcher_ref_client (watcher, source_uid, NULL);
}

/**
 * e_reminder_watcher_set_default_zone:
 * @watcher: an #EReminderWatcher
 * @zone: (nullable): an icaltimezone or #EReminderWatcherZone structure
 *
 * Sets the default zone for the @watcher. This is used when calculating
 * trigger times for floating component times. When the @zone is %NULL,
 * then sets a UTC time zone.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_set_default_zone (EReminderWatcher *watcher,
				     const icaltimezone *zone)
{
	const gchar *new_location;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	if (!zone)
		zone = icaltimezone_get_utc_timezone ();

	g_rec_mutex_lock (&watcher->priv->lock);

	new_location = icaltimezone_get_location ((icaltimezone *) zone);

	if (new_location && g_strcmp0 (new_location,
	    icaltimezone_get_location (watcher->priv->default_zone)) == 0) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	e_reminder_watcher_zone_free ((EReminderWatcherZone *) watcher->priv->default_zone);
	watcher->priv->default_zone = (icaltimezone *) e_reminder_watcher_zone_copy ((const EReminderWatcherZone *) zone);

	g_rec_mutex_unlock (&watcher->priv->lock);

	g_object_notify (G_OBJECT (watcher), "default-zone");
}

/**
 * e_reminder_watcher_dup_default_zone:
 * @watcher: an #EReminderWatcher
 *
 * Returns: (transfer full): A copy of the currently set default time zone.
 *    Use e_reminder_watcher_zone_free() to free it, when no longer needed.
 *
 * Since: 3.30
 **/
icaltimezone *
e_reminder_watcher_dup_default_zone (EReminderWatcher *watcher)
{
	icaltimezone *zone;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	zone = (icaltimezone *) e_reminder_watcher_zone_copy ((EReminderWatcherZone *) watcher->priv->default_zone);

	g_rec_mutex_unlock (&watcher->priv->lock);

	return zone;
}

/**
 * e_reminder_watcher_get_timers_enabled:
 * @watcher: an #EReminderWatcher
 *
 * Returns: whether timers are enabled for the @watcher. See
 *    e_reminder_watcher_set_timers_enabled() for more information
 *    what it means.
 *
 * Since: 3.30
 **/
gboolean
e_reminder_watcher_get_timers_enabled (EReminderWatcher *watcher)
{
	gboolean enabled;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	enabled = watcher->priv->timers_enabled;

	g_rec_mutex_unlock (&watcher->priv->lock);

	return enabled;
}

/**
 * e_reminder_watcher_set_timers_enabled:
 * @watcher: an #EReminderWatcher
 * @enabled: a value to set
 *
 * The @watcher can be used both for scheduling the timers for the reminders
 * and respond to them through the "triggered" signal, or only to listen for
 * changes on the past reminders. The default is to have timers enabled, thus
 * to response to scheduled reminders. Disabling the timers also means there
 * will be less resources needed by the @watcher.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_set_timers_enabled (EReminderWatcher *watcher,
				       gboolean enabled)
{
	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	g_rec_mutex_lock (&watcher->priv->lock);

	if (!enabled == !watcher->priv->timers_enabled) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	watcher->priv->timers_enabled = enabled;

	if (watcher->priv->timers_enabled &&
	    !watcher->priv->construct_idle_id) {
		e_source_registry_watcher_reclaim (watcher->priv->registry_watcher);
		e_reminder_watcher_maybe_schedule_next_trigger (watcher, 0);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	g_object_notify (G_OBJECT (watcher), "timers-enabled");
}

static gchar *
e_reminder_watcher_get_alarm_summary (EReminderWatcher *watcher,
				      const EReminderData *rd)
{
	ECalComponentText summary_text, alarm_text;
	ECalComponentAlarm *alarm;
	gchar *alarm_summary;

	g_return_val_if_fail (watcher != NULL, NULL);
	g_return_val_if_fail (rd != NULL, NULL);

	summary_text.value = NULL;
	alarm_text.value = NULL;

	e_cal_component_get_summary (rd->component, &summary_text);

	alarm = e_cal_component_get_alarm (rd->component, rd->instance.auid);
	if (alarm) {
		ECalClient *client;

		client = e_reminder_watcher_ref_opened_client (watcher, rd->source_uid);

		if (client && e_client_check_capability (E_CLIENT (client), CAL_STATIC_CAPABILITY_ALARM_DESCRIPTION)) {
			e_cal_component_alarm_get_description (alarm, &alarm_text);
			if (!alarm_text.value || !*alarm_text.value)
				alarm_text.value = NULL;
		}

		g_clear_object (&client);
	}

	if (alarm_text.value && summary_text.value &&
	    e_util_utf8_strcasecmp (alarm_text.value, summary_text.value) == 0)
		alarm_text.value = NULL;

	if (summary_text.value && *summary_text.value &&
	    alarm_text.value && *alarm_text.value)
		alarm_summary = g_strconcat (summary_text.value, "\n", alarm_text.value, NULL);
	else if (summary_text.value && *summary_text.value)
		alarm_summary = g_strdup (summary_text.value);
	else if (alarm_text.value && *alarm_text.value)
		alarm_summary = g_strdup (alarm_text.value);
	else
		alarm_summary = NULL;

	if (alarm)
		e_cal_component_alarm_free (alarm);

	return alarm_summary;
}

/**
 * e_reminder_watcher_describe_data:
 * @watcher: an #EReminderWatcher
 * @rd: an #EReminderData
 * @flags: bit-or of #EReminderWatcherDescribeFlags
 *
 * Returns a new string with a text description of the @rd. The text format
 * can be influenced with @flags.
 *
 * Free the returned string with g_free(), when no longer needed.
 *
 * Returns: (transfer full): a new string with a text description of the @rd.
 *
 * Since: 3.30
 **/
gchar *
e_reminder_watcher_describe_data (EReminderWatcher *watcher,
				  const EReminderData *rd,
				  guint32 flags)
{
	icalcomponent *icalcomp;
	gchar *description = NULL;
	gboolean use_markup;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);
	g_return_val_if_fail (rd != NULL, NULL);

	use_markup = (flags & E_REMINDER_WATCHER_DESCRIBE_FLAG_MARKUP) != 0;

	icalcomp = e_cal_component_get_icalcomponent (rd->component);
	if (icalcomp) {
		gchar *summary;
		const gchar *location;
		gchar *timediff = NULL, *tmp;
		gchar timestr[255];
		GString *markup;

		timestr[0] = 0;
		markup = g_string_sized_new (256);
		summary = e_reminder_watcher_get_alarm_summary (watcher, rd);
		location = icalcomponent_get_location (icalcomp);

		if (rd->instance.occur_start > 0) {
			gchar *timestrptr = timestr;
			icaltimezone *zone;
			struct icaltimetype itt;
			gboolean is_date = FALSE;

			if (rd->instance.occur_end > rd->instance.occur_start) {
				timediff = e_cal_util_seconds_to_string (rd->instance.occur_end - rd->instance.occur_start);
			}

			zone = e_reminder_watcher_dup_default_zone (watcher);
			if (zone && (!icaltimezone_get_location (zone) || g_strcmp0 (icaltimezone_get_location (zone), "UTC") == 0)) {
				icaltimezone_free (zone, 1);
				zone = NULL;
			}

			itt = icalcomponent_get_dtstart (icalcomp);
			if (icaltime_is_valid_time (itt) && !icaltime_is_null_time (itt))
				is_date = itt.is_date;

			itt = icaltime_from_timet_with_zone (rd->instance.occur_start, is_date, zone);

			g_signal_emit (watcher, signals[FORMAT_TIME], 0, rd, &itt, &timestrptr, 254, NULL);

			if (!*timestr)
				e_reminder_watcher_format_time_impl (watcher, rd, &itt, &timestrptr, 254);

			if (zone)
				icaltimezone_free (zone, 1);
		}

		if (!summary || !*summary) {
			g_free (summary);
			summary = g_strdup (_( "No Summary"));
		}

		if (use_markup) {
			tmp = g_markup_printf_escaped ("<b>%s</b>", summary);
			g_string_append (markup, tmp);
			g_free (tmp);
		} else {
			g_string_append (markup, summary);
		}
		g_string_append_c (markup, '\n');

		if (*timestr) {
			/* Translators: The first %s is replaced with the time string,
			   the second %s with a duration, and the third %s with an event location,
			   making it something like: "24.1.2018 10:30 (30 minutes) Meeting room A1" */
			#define FMT_TIME_TIME_LOCATION C_("overdue", "%s (%s) %s")

			/* Translators: The first %s is replaced with the time string,
			   the second %s with a duration, making is something like:
			   "24.1.2018 10:30 (30 minutes)" */
			#define FMT_TIME_TIME C_("overdue", "%s (%s)")

			/* Translators: The first %s is replaced with the time string,
			   the second %s with an event location, making it something like:
			   "24.1.2018 10:30 Meeting room A1" */
			#define FMT_TIME_LOCATION C_("overdue", "%s %s")

			if (timediff && *timediff) {
				if (location && *location) {
					if (use_markup)
						tmp = g_markup_printf_escaped (FMT_TIME_TIME_LOCATION, timestr, timediff, location);
					else
						tmp = g_strdup_printf (FMT_TIME_TIME_LOCATION, timestr, timediff, location);
				} else {
					if (use_markup)
						tmp = g_markup_printf_escaped (FMT_TIME_TIME, timestr, timediff);
					else
						tmp = g_strdup_printf (FMT_TIME_TIME, timestr, timediff);
				}
			} else if (location && *location) {
				if (use_markup)
					tmp = g_markup_printf_escaped (FMT_TIME_LOCATION, timestr, location);
				else
					tmp = g_strdup_printf (FMT_TIME_LOCATION, timestr, location);
			} else {
				if (use_markup)
					tmp = g_markup_escape_text (timestr, -1);
				else
					tmp = g_strdup (timestr);
			}

			if (use_markup)
				g_string_append (markup, "<small>");
			g_string_append (markup, tmp);
			if (use_markup)
				g_string_append (markup, "</small>");

			g_free (tmp);
		} else if (location && *location) {
			if (use_markup) {
				tmp = g_markup_printf_escaped ("%s", location);

				g_string_append (markup, "<small>");
				g_string_append (markup, tmp);
				g_string_append (markup, "</small>");

				g_free (tmp);
			} else {
				g_string_append (markup, location);
			}
		}

		description = g_string_free (markup, FALSE);

		g_free (timediff);
		g_free (summary);
	}

	return description;
}

typedef struct _ForeachTriggerData {
	gint64 current_time;
	GSList *triggered; /* EReminderData * */
	GHashTable *insert_back; /* gchar * ~> GSList * { EReminderData * } */
} ForeachTriggerData;

static gboolean
foreach_trigger_cb (gpointer key,
		    gpointer value,
		    gpointer user_data)
{
	gchar *source_uid = key;
	GSList *reminders = value, *link;
	ForeachTriggerData *ftd = user_data;
	EReminderData *rd;

	if (!source_uid || !reminders || !ftd)
		return FALSE;

	for (link = reminders; link; link = g_slist_next (link)) {
		rd = link->data;

		if (!rd || rd->instance.trigger > ftd->current_time)
			break;
	}

	if (link == reminders)
		return FALSE;

	if (link) {
		GSList *prev;

		for (prev = reminders; prev; prev = g_slist_next (prev)) {
			if (prev->next == link) {
				prev->next = NULL;
				break;
			}
		}
	}

	ftd->triggered = g_slist_concat (ftd->triggered, reminders);

	if (link) {
		g_hash_table_insert (ftd->insert_back, source_uid, link);
	} else {
		g_free (source_uid);
	}

	return TRUE;
}

/**
 * e_reminder_watcher_timer_elapsed:
 * @watcher: an #EReminderWatcher
 *
 * Notifies the #watcher that the timer previously scheduled
 * with EReminderWatcherClass::schedule_timer elapsed. This can
 * be used by the descendants which override the default implementation
 * of EReminderWatcherClass::schedule_timer. There is always scheduled
 * only one timer and once it's elapsed it should be also removed,
 * the same when the EReminderWatcherClass::schedule_timer is called
 * and the previously scheduled timer was not elapsed yet, the previous
 * should be removed first, aka every call to EReminderWatcherClass::schedule_timer
 * replaces any previously scheduled timer.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_timer_elapsed (EReminderWatcher *watcher)
{
	ForeachTriggerData ftd;
	GSList *snoozed, *link, *triggered_snoozed = NULL;
	gboolean changed = FALSE;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	ftd.current_time = g_get_real_time () / G_USEC_PER_SEC;

	e_reminder_watcher_debug_print ("Timer elapsed called at %s\n", e_reminder_watcher_timet_as_string (ftd.current_time));

	g_rec_mutex_lock (&watcher->priv->lock);

	if (!watcher->priv->scheduled) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		return;
	}

	ftd.triggered = NULL;
	ftd.insert_back = g_hash_table_new (g_str_hash, g_str_equal);

	g_hash_table_foreach_steal (watcher->priv->scheduled, foreach_trigger_cb, &ftd);

	if (g_hash_table_size (ftd.insert_back) > 0) {
		GHashTableIter iter;
		gpointer key, value;

		g_hash_table_iter_init (&iter, ftd.insert_back);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			g_warn_if_fail (key != NULL);
			g_warn_if_fail (value != NULL);

			if (key && value)
				g_hash_table_insert (watcher->priv->scheduled, key, value);
		}
	}

	g_hash_table_destroy (ftd.insert_back);

	snoozed = e_reminder_watcher_dup_snoozed (watcher);

	for (link = snoozed; link; link = g_slist_next (link)) {
		EReminderData *rd = link->data;

		if (rd && rd->instance.trigger <= ftd.current_time) {
			link->data = NULL;

			changed = e_reminder_watcher_remove_from_snoozed (watcher, rd, FALSE) || changed;

			triggered_snoozed = g_slist_prepend (triggered_snoozed, rd);
		}
	}

	g_slist_free_full (snoozed, e_reminder_data_free);

	if (ftd.triggered || triggered_snoozed) {
		GHashTable *last_notifies;
		GHashTableIter iter;
		GSList *past;
		gpointer key, value;

		last_notifies = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, g_free);

		past = e_reminder_watcher_dup_past (watcher);

		for (link = ftd.triggered; link; link = g_slist_next (link)) {
			EReminderData *rd = e_reminder_data_copy (link->data);

			if (rd) {
				if (e_reminder_watcher_add (&past, rd, TRUE, FALSE)) {
					time_t *ptrigger;

					ptrigger = g_hash_table_lookup (last_notifies, rd->source_uid);
					if (ptrigger) {
						if (*ptrigger < rd->instance.trigger)
							*ptrigger = rd->instance.trigger;
					} else {
						ptrigger = g_new0 (time_t, 1);
						*ptrigger = rd->instance.trigger;
						g_hash_table_insert (last_notifies, rd->source_uid, ptrigger);
					}
				}
			}
		}

		for (link = triggered_snoozed; link; link = g_slist_next (link)) {
			EReminderData *rd = e_reminder_data_copy (link->data);

			if (rd) {
				if (e_reminder_watcher_add (&past, rd, TRUE, FALSE)) {
					time_t *ptrigger;

					ptrigger = g_hash_table_lookup (last_notifies, rd->source_uid);
					if (ptrigger) {
						if (*ptrigger < rd->instance.trigger)
							*ptrigger = rd->instance.trigger;
					} else {
						ptrigger = g_new0 (time_t, 1);
						*ptrigger = rd->instance.trigger;
						g_hash_table_insert (last_notifies, rd->source_uid, ptrigger);
					}
				}
			}
		}

		e_reminder_watcher_save_past (watcher, past);

		g_hash_table_iter_init (&iter, last_notifies);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			const gchar *source_uid = key;
			const time_t *ptrigger = value;

			if (source_uid && ptrigger) {
				ECalClient *client = e_reminder_watcher_ref_client (watcher, source_uid, NULL);

				if (client) {
					client_set_last_notification_time (client, *ptrigger);
					g_object_unref (client);
				}
			}
		}

		/* Destroy before the 'past', because keys are from its data */
		g_hash_table_destroy (last_notifies);
		g_slist_free_full (past, e_reminder_data_free);
	}

	if (changed)
		e_reminder_watcher_save_snoozed (watcher);

	if (ftd.triggered || triggered_snoozed) {
		if (triggered_snoozed)
			e_reminder_watcher_emit_signal_idle_multiple (watcher, signals[TRIGGERED], triggered_snoozed, TRUE);

		if (ftd.triggered)
			e_reminder_watcher_emit_signal_idle_multiple (watcher, signals[TRIGGERED], ftd.triggered, FALSE);

		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);

		g_slist_free_full (triggered_snoozed, e_reminder_data_free);
		g_slist_free_full (ftd.triggered, e_reminder_data_free);
	}

	/* To make sure the timer is re-scheduled */
	watcher->priv->next_trigger = 0;

	e_reminder_watcher_maybe_schedule_next_trigger (watcher, 0);

	g_rec_mutex_unlock (&watcher->priv->lock);
}

/**
 * e_reminder_watcher_dup_past:
 * @watcher: an #EReminderWatcher
 *
 * Gathers a #GSList of all past reminders which had not been removed after
 * EReminderWatcher::triggered signal. Such reminders are remembered
 * across sessions, until they are dismissed by e_reminder_watcher_dismiss()
 * or its synchronous variant. These reminders can be also snoozed
 * with e_reminder_watcher_snooze(), which removes them from the past
 * reminders into the list of snoozed reminders, see e_reminder_watcher_dup_snoozed().
 *
 * Free the returned #GSList with
 * g_slist_free_full (reminders, e_reminder_data_free);
 * when no longer needed.
 *
 * Returns: (transfer full) (element-type EReminderData) (nullable): a newly
 *    allocated #GSList of the past reminders, or %NULL, when there are none
 *
 * Since: 3.30
 **/
GSList *
e_reminder_watcher_dup_past (EReminderWatcher *watcher)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	return e_reminder_watcher_reminders_from_key (watcher, "reminders-past");
}

/**
 * e_reminder_watcher_dup_snoozed:
 * @watcher: an #EReminderWatcher
 *
 * Gathers a #GSList of currently snoozed reminder with e_reminder_watcher_snooze().
 * The snoozed reminders are remembered across sessions and they are re-triggered
 * when their snooze time elapses, which can move them back to the list of past reminders.
 *
 * Free the returned #GSList with
 * g_slist_free_full (reminders, e_reminder_data_free);
 * when no longer needed.
 *
 * Returns: (transfer full) (element-type EReminderData) (nullable): a newly
 *    allocated #GSList of the snoozed reminders, or %NULL, when there are none
 *
 * Since: 3.30
 **/
GSList *
e_reminder_watcher_dup_snoozed (EReminderWatcher *watcher)
{
	GSList *list;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	list = g_slist_copy_deep (watcher->priv->snoozed, (GCopyFunc) e_reminder_data_copy, NULL);

	g_rec_mutex_unlock (&watcher->priv->lock);

	return list;
}

/**
 * e_reminder_watcher_snooze:
 * @watcher: an #EReminderWatcher
 * @rd: an #EReminderData identifying the reminder
 * @until: time_t as gint64, when the @rd should be retriggered
 *
 * Snoozes @rd until @until, which is an absolute time when the @rd
 * should be retriggered. This moves the @rd from the list of past
 * reminders into the list of snoozed reminders and invokes the "changed"
 * signal.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_snooze (EReminderWatcher *watcher,
			   const EReminderData *rd,
			   gint64 until)
{
	EReminderData *rd_copy;
	gboolean changed;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (rd != NULL);

	g_rec_mutex_lock (&watcher->priv->lock);

	rd_copy = e_reminder_data_copy (rd);
	if (!rd_copy) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		g_warn_if_reached ();
		return;
	}

	changed = e_reminder_watcher_remove_from_past (watcher, rd_copy);
	changed = e_reminder_watcher_remove_from_snoozed (watcher, rd_copy, FALSE) || changed;

	rd_copy->instance.trigger = (time_t) until;

	changed = e_reminder_watcher_add (&watcher->priv->snoozed, rd_copy, FALSE, TRUE) || changed;

	e_reminder_watcher_debug_print ("Added reminder to snoozed for '%s' from %s at %s\n",
		icalcomponent_get_summary (e_cal_component_get_icalcomponent (rd_copy->component)),
		rd_copy->source_uid,
		e_reminder_watcher_timet_as_string (rd_copy->instance.trigger));

	e_reminder_watcher_save_snoozed (watcher);
	e_reminder_watcher_maybe_schedule_next_trigger (watcher, until);

	g_rec_mutex_unlock (&watcher->priv->lock);

	if (changed)
		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);
}

static void
e_reminder_watcher_dismiss_thread (GTask *task,
				   gpointer source_object,
				   gpointer task_data,
				   GCancellable *cancellable)
{
	GError *local_error = NULL;

	if (!e_reminder_watcher_dismiss_sync (E_REMINDER_WATCHER (source_object), task_data, cancellable, &local_error)) {
		if (local_error)
			g_task_return_error (task, local_error);
		else
			g_task_return_boolean (task, FALSE);
	} else {
		g_task_return_boolean (task, TRUE);
	}
}

/**
 * e_reminder_watcher_dismiss:
 * @watcher: an #EReminderWatcher
 * @rd: an #EReminderData to dismiss
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously dismiss single reminder in the past or snoozed reminders.
 *
 * When the operation is finished, @callback will be called. You can
 * then call e_reminder_watcher_dismiss_finish() to get the result of
 * the operation.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_dismiss (EReminderWatcher *watcher,
			    const EReminderData *rd,
			    GCancellable *cancellable,
			    GAsyncReadyCallback callback,
			    gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (rd != NULL);

	task = g_task_new (watcher, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_reminder_watcher_dismiss);
	g_task_set_task_data (task, e_reminder_data_copy (rd), e_reminder_data_free);

	g_task_run_in_thread (task, e_reminder_watcher_dismiss_thread);

	g_object_unref (task);
}

/**
 * e_reminder_watcher_dismiss_finish:
 * @watcher: an #EReminderWatcher
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_reminder_watcher_dismiss().
 *
 * Returns: whether succeeded
 *
 * Since: 3.30
 **/
gboolean
e_reminder_watcher_dismiss_finish (EReminderWatcher *watcher,
				   GAsyncResult *result,
				   GError **error)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, watcher), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_reminder_watcher_dismiss), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

static gboolean
e_reminder_watcher_dismiss_one_sync (ECalClient *client,
				     const EReminderData *rd,
				     GCancellable *cancellable,
				     GError **error)
{
	ECalComponentId *id;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);

	id = e_cal_component_get_id (rd->component);
	if (id) {
		GError *local_error = NULL;

		success = e_cal_client_discard_alarm_sync (client, id->uid, id->rid, rd->instance.auid, cancellable, &local_error);

		e_reminder_watcher_debug_print ("Discard alarm for '%s' from %s (uid:%s rid:%s auid:%s) %s%s%s%s\n",
			icalcomponent_get_summary (e_cal_component_get_icalcomponent (rd->component)),
			rd->source_uid, id->uid, id->rid ? id->rid : "null", rd->instance.auid,
			success ? "succeeded" : "failed",
			(!success || local_error) ? " (" : "",
			local_error ? local_error->message : success ? "" : "Unknown error",
			(!success || local_error) ? ")" : "");

		/* Ignore all errors here, users cannot usually do anything with it anyway */
		success = TRUE;
		g_clear_error (&local_error);

		e_cal_component_free_id (id);
	}

	return success;
}

/**
 * e_reminder_watcher_dismiss_sync:
 * @watcher: an #EReminderWatcher
 * @rd: an #EReminderData to dismiss
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously dismiss single reminder in the past or snoozed reminders.
 *
 * Returns: whether succeeded
 *
 * Since: 3.30
 **/
gboolean
e_reminder_watcher_dismiss_sync (EReminderWatcher *watcher,
				 const EReminderData *rd,
				 GCancellable *cancellable,
				 GError **error)
{
	EReminderData *rd_copy;
	ECalClient *client = NULL;
	gboolean changed, success = TRUE;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	rd_copy = e_reminder_data_copy (rd);
	if (!rd_copy) {
		g_rec_mutex_unlock (&watcher->priv->lock);
		g_warn_if_reached ();
		return FALSE;
	}

	changed = e_reminder_watcher_remove_from_past (watcher, rd_copy);
	changed = e_reminder_watcher_remove_from_snoozed (watcher, rd_copy, TRUE) || changed;

	if (changed)
		client = e_reminder_watcher_ref_client (watcher, rd_copy->source_uid, cancellable ? cancellable : watcher->priv->cancellable);

	e_reminder_watcher_maybe_schedule_next_trigger (watcher, 0);

	g_rec_mutex_unlock (&watcher->priv->lock);

	if (changed)
		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);

	if (client) {
		success = e_reminder_watcher_dismiss_one_sync (client, rd, cancellable, error);
		g_object_unref (client);
	}

	e_reminder_data_free (rd_copy);

	return success;
}

static void
e_reminder_watcher_dismiss_all_thread (GTask *task,
				       gpointer source_object,
				       gpointer task_data,
				       GCancellable *cancellable)
{
	GError *local_error = NULL;

	if (!e_reminder_watcher_dismiss_all_sync (E_REMINDER_WATCHER (source_object), cancellable, &local_error)) {
		if (local_error)
			g_task_return_error (task, local_error);
		else
			g_task_return_boolean (task, FALSE);
	} else {
		g_task_return_boolean (task, TRUE);
	}
}

/**
 * e_reminder_watcher_dismiss_all:
 * @watcher: an #EReminderWatcher
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously dismiss all past reminders.
 *
 * When the operation is finished, @callback will be called. You can
 * then call e_reminder_watcher_dismiss_all_finish() to get the result
 * of the operation.
 *
 * Since: 3.30
 **/
void
e_reminder_watcher_dismiss_all (EReminderWatcher *watcher,
				GCancellable *cancellable,
				GAsyncReadyCallback callback,
				gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));

	task = g_task_new (watcher, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_reminder_watcher_dismiss_all);

	g_task_run_in_thread (task, e_reminder_watcher_dismiss_all_thread);

	g_object_unref (task);
}

/**
 * e_reminder_watcher_dismiss_all_finish:
 * @watcher: an #EReminderWatcher
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_reminder_watcher_dismiss_all().
 *
 * Returns: whether succeeded
 *
 * Since: 3.30
 **/
gboolean
e_reminder_watcher_dismiss_all_finish (EReminderWatcher *watcher,
				       GAsyncResult *result,
				       GError **error)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, watcher), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_reminder_watcher_dismiss_all), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_reminder_watcher_dismiss_all_sync:
 * @watcher: an #EReminderWatcher
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously dismiss all past reminders. The operation stops after
 * the first error is encountered, which can be before all the past
 * reminders are dismissed.
 *
 * Returns: whether succeeded.
 *
 * Since: 3.30
 **/
gboolean
e_reminder_watcher_dismiss_all_sync (EReminderWatcher *watcher,
				     GCancellable *cancellable,
				     GError **error)
{
	GHashTable *clients; /* gchar *source_uid ~> ECalClient * */
	GSList *reminders, *link;
	gboolean success = TRUE, changed = FALSE;

	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);

	clients = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);
	reminders = e_reminder_watcher_dup_past (watcher);

	for (link = reminders; link; link = g_slist_next (link)) {
		EReminderData *rd = link->data;
		ECalClient *client;

		client = g_hash_table_lookup (clients, rd->source_uid);
		if (!client) {
			client = e_reminder_watcher_ref_client (watcher, rd->source_uid, cancellable ? cancellable : watcher->priv->cancellable);
			if (client) {
				g_hash_table_insert (clients, g_strdup (rd->source_uid), client);
			}
		}

		if (client) {
			success = e_reminder_watcher_dismiss_one_sync (client, rd, cancellable, error);

			/* To keep the failed discard in the saved list. */
			if (!success)
				break;
		}
	}

	if (link != reminders && reminders) {
		e_reminder_watcher_save_past (watcher, link);
		changed = TRUE;
	}

	g_slist_free_full (reminders, e_reminder_data_free);
	g_hash_table_destroy (clients);

	g_rec_mutex_unlock (&watcher->priv->lock);

	if (changed)
		e_reminder_watcher_emit_signal_idle (watcher, signals[CHANGED], NULL);

	return success;
}
