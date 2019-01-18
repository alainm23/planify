/* Evolution calendar - iCalendar file backend
 *
 * Copyright (C) 1993 Free Software Foundation, Inc.
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 *          Rodrigo Moya <rodrigo@ximian.com>
 *          Jan Brittenson <bson@gnu.ai.mit.edu>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include <libedataserver/libedataserver.h>

#include "e-cal-backend-file-events.h"

#ifndef O_BINARY
#define O_BINARY 0
#endif

#define E_CAL_BACKEND_FILE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_BACKEND_FILE, ECalBackendFilePrivate))

#define EDC_ERROR(_code) e_data_cal_create_error (_code, NULL)
#define EDC_ERROR_NO_URI() e_data_cal_create_error (OtherError, "Cannot get URI")

#define ECAL_REVISION_X_PROP  "X-EVOLUTION-DATA-REVISION"

/* Placeholder for each component and its recurrences */
typedef struct {
	ECalComponent *full_object;
	GHashTable *recurrences;
	GList *recurrences_list;
} ECalBackendFileObject;

/* Private part of the ECalBackendFile structure */
struct _ECalBackendFilePrivate {
	/* path where the calendar data is stored */
	gchar *path;

	/* Filename in the dir */
	gchar *file_name;
	gboolean is_dirty;
	guint dirty_idle_id;

	/* locked in high-level functions to ensure data is consistent
	 * in idle and CORBA thread(s?); because high-level functions
	 * may call other high-level functions the mutex must allow
	 * recursive locking
	 */
	GRecMutex idle_save_rmutex;

	/* Toplevel VCALENDAR component */
	icalcomponent *icalcomp;

	/* All the objects in the calendar, hashed by UID.  The
	 * hash key *is* the uid returned by cal_component_get_uid(); it is not
	 * copied, so don't free it when you remove an object from the hash
	 * table. Each item in the hash table is a ECalBackendFileObject.
	 */
	GHashTable *comp_uid_hash;

	EIntervalTree *interval_tree;

	GList *comp;

	/* guards refresh members */
	GMutex refresh_lock;
	/* set to TRUE to indicate thread should stop */
	gboolean refresh_thread_stop;
	/* condition for refreshing, not NULL when thread exists */
	GCond *refresh_cond;
	/* cond to know the refresh thread gone */
	GCond *refresh_gone_cond;
	/* increased when backend saves the file */
	guint refresh_skip;

	GFileMonitor *refresh_monitor;

	/* Just an incremental number to ensure uniqueness across revisions */
	guint revision_counter;
};



#define d(x)

static void e_cal_backend_file_dispose (GObject *object);
static void e_cal_backend_file_finalize (GObject *object);

static void free_refresh_data (ECalBackendFile *cbfile);

static void bump_revision (ECalBackendFile *cbfile);

static void	e_cal_backend_file_timezone_cache_init
					(ETimezoneCacheInterface *iface);

static ETimezoneCacheInterface *parent_timezone_cache_interface;

G_DEFINE_TYPE_WITH_CODE (
	ECalBackendFile,
	e_cal_backend_file,
	E_TYPE_CAL_BACKEND_SYNC,
	G_IMPLEMENT_INTERFACE (
		E_TYPE_TIMEZONE_CACHE,
		e_cal_backend_file_timezone_cache_init))

/* g_hash_table_foreach() callback to destroy a ECalBackendFileObject */
static void
free_object_data (gpointer data)
{
	ECalBackendFileObject *obj_data = data;

	if (obj_data->full_object)
		g_object_unref (obj_data->full_object);
	g_hash_table_destroy (obj_data->recurrences);
	g_list_free (obj_data->recurrences_list);

	g_free (obj_data);
}

/* Saves the calendar data */
static gboolean
save_file_when_idle (gpointer user_data)
{
	ECalBackendFilePrivate *priv;
	GError *e = NULL;
	GFile *file, *backup_file;
	GFileOutputStream *stream;
	gboolean succeeded;
	gchar *tmp, *backup_uristr;
	gchar *buf;
	ECalBackendFile *cbfile = user_data;
	gboolean writable;

	priv = cbfile->priv;
	g_return_val_if_fail (priv->path != NULL, FALSE);
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	writable = e_cal_backend_get_writable (E_CAL_BACKEND (cbfile));

	g_rec_mutex_lock (&priv->idle_save_rmutex);
	if (!priv->is_dirty || !writable) {
		priv->dirty_idle_id = 0;
		priv->is_dirty = FALSE;
		g_rec_mutex_unlock (&priv->idle_save_rmutex);
		return FALSE;
	}

	file = g_file_new_for_path (priv->path);
	if (!file)
		goto error_malformed_uri;

	/* save calendar to backup file */
	tmp = g_file_get_uri (file);
	if (!tmp) {
		g_object_unref (file);
		goto error_malformed_uri;
	}

	backup_uristr = g_strconcat (tmp, "~", NULL);
	backup_file = g_file_new_for_uri (backup_uristr);

	g_free (tmp);
	g_free (backup_uristr);

	if (!backup_file) {
		g_object_unref (file);
		goto error_malformed_uri;
	}

	priv->refresh_skip++;
	stream = g_file_replace (backup_file, NULL, FALSE, G_FILE_CREATE_NONE, NULL, &e);
	if (!stream || e) {
		if (stream)
			g_object_unref (stream);

		g_object_unref (file);
		g_object_unref (backup_file);
		priv->refresh_skip--;
		goto error;
	}

	buf = icalcomponent_as_ical_string_r (priv->icalcomp);
	succeeded = g_output_stream_write_all (G_OUTPUT_STREAM (stream), buf, strlen (buf) * sizeof (gchar), NULL, NULL, &e);
	g_free (buf);

	if (!succeeded || e) {
		g_object_unref (stream);
		g_object_unref (file);
		g_object_unref (backup_file);
		goto error;
	}

	succeeded = g_output_stream_close (G_OUTPUT_STREAM (stream), NULL, &e);
	g_object_unref (stream);

	if (!succeeded || e) {
		g_object_unref (file);
		g_object_unref (backup_file);
		goto error;
	}

	/* now copy the temporary file to the real file */
	g_file_move (backup_file, file, G_FILE_COPY_OVERWRITE, NULL, NULL, NULL, &e);

	g_object_unref (file);
	g_object_unref (backup_file);
	if (e)
		goto error;

	priv->is_dirty = FALSE;
	priv->dirty_idle_id = 0;

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	return FALSE;

 error_malformed_uri:
	g_rec_mutex_unlock (&priv->idle_save_rmutex);
	e_cal_backend_notify_error (E_CAL_BACKEND (cbfile),
				  _("Cannot save calendar data: Malformed URI."));
	return FALSE;

 error:
	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	if (e) {
		gchar *msg = g_strdup_printf ("%s: %s", _("Cannot save calendar data"), e->message);

		e_cal_backend_notify_error (E_CAL_BACKEND (cbfile), msg);
		g_free (msg);
		g_error_free (e);
	} else
		e_cal_backend_notify_error (E_CAL_BACKEND (cbfile), _("Cannot save calendar data"));

	return FALSE;
}

static void
save (ECalBackendFile *cbfile,
      gboolean do_bump_revision)
{
	ECalBackendFilePrivate *priv;

	if (do_bump_revision)
		bump_revision (cbfile);

	priv = cbfile->priv;

	g_rec_mutex_lock (&priv->idle_save_rmutex);
	priv->is_dirty = TRUE;

	if (!priv->dirty_idle_id)
		priv->dirty_idle_id = g_idle_add ((GSourceFunc) save_file_when_idle, cbfile);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

static void
free_calendar_components (GHashTable *comp_uid_hash,
                          icalcomponent *top_icomp)
{
	if (comp_uid_hash)
		g_hash_table_destroy (comp_uid_hash);

	if (top_icomp)
		icalcomponent_free (top_icomp);
}

static void
free_calendar_data (ECalBackendFile *cbfile)
{
	ECalBackendFilePrivate *priv;

	priv = cbfile->priv;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	e_intervaltree_destroy (priv->interval_tree);
	priv->interval_tree = NULL;

	free_calendar_components (priv->comp_uid_hash, priv->icalcomp);
	priv->comp_uid_hash = NULL;
	priv->icalcomp = NULL;

	g_list_free (priv->comp);
	priv->comp = NULL;

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

/* Dispose handler for the file backend */
static void
e_cal_backend_file_dispose (GObject *object)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	ESource *source;

	cbfile = E_CAL_BACKEND_FILE (object);
	priv = cbfile->priv;

	free_refresh_data (E_CAL_BACKEND_FILE (object));

	/* Save if necessary */
	if (priv->is_dirty)
		save_file_when_idle (cbfile);

	free_calendar_data (cbfile);

	source = e_backend_get_source (E_BACKEND (cbfile));
	if (source)
		g_signal_handlers_disconnect_matched (source, G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, cbfile);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_backend_file_parent_class)->dispose (object);
}

/* Finalize handler for the file backend */
static void
e_cal_backend_file_finalize (GObject *object)
{
	ECalBackendFilePrivate *priv;

	priv = E_CAL_BACKEND_FILE_GET_PRIVATE (object);

	/* Clean up */

	if (priv->dirty_idle_id)
		g_source_remove (priv->dirty_idle_id);

	g_mutex_clear (&priv->refresh_lock);

	g_rec_mutex_clear (&priv->idle_save_rmutex);

	g_free (priv->path);
	g_free (priv->file_name);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_backend_file_parent_class)->finalize (object);
}



/* Looks up an component by its UID on the backend's component hash table
 * and returns TRUE if any event (regardless whether it is the master or a child)
 * with that UID exists */
static gboolean
uid_in_use (ECalBackendFile *cbfile,
            const gchar *uid)
{
	ECalBackendFilePrivate *priv;
	ECalBackendFileObject *obj_data;

	priv = cbfile->priv;

	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	return obj_data != NULL;
}



static icalproperty *
get_revision_property (ECalBackendFile *cbfile)
{
	icalproperty *prop = NULL;

	if (cbfile->priv->icalcomp != NULL)
		prop = icalcomponent_get_first_property (
			cbfile->priv->icalcomp, ICAL_X_PROPERTY);

	while (prop != NULL) {
		const gchar *name = icalproperty_get_x_name (prop);

		if (name && strcmp (name, ECAL_REVISION_X_PROP) == 0)
			return prop;

		prop = icalcomponent_get_next_property (
			cbfile->priv->icalcomp, ICAL_X_PROPERTY);
	}

	return NULL;
}

static gchar *
make_revision_string (ECalBackendFile *cbfile)
{
	GTimeVal timeval;
	gchar   *datestr;
	gchar   *revision;

	g_get_current_time (&timeval);

	datestr = g_time_val_to_iso8601 (&timeval);
	revision = g_strdup_printf ("%s(%d)", datestr, cbfile->priv->revision_counter++);

	g_free (datestr);
	return revision;
}

static icalproperty *
ensure_revision (ECalBackendFile *cbfile)
{
	icalproperty *prop;

	if (cbfile->priv->icalcomp == NULL)
		return NULL;

	prop = get_revision_property (cbfile);

	if (prop == NULL) {
		gchar *revision = make_revision_string (cbfile);

		prop = icalproperty_new (ICAL_X_PROPERTY);

		icalproperty_set_x_name (prop, ECAL_REVISION_X_PROP);
		icalproperty_set_x (prop, revision);

		icalcomponent_add_property (cbfile->priv->icalcomp, prop);

		g_free (revision);
	}

	return prop;
}

static void
bump_revision (ECalBackendFile *cbfile)
{
	/* Update the revision string */
	icalproperty *prop = ensure_revision (cbfile);
	gchar        *revision = make_revision_string (cbfile);

	icalproperty_set_x (prop, revision);

	e_cal_backend_notify_property_changed (E_CAL_BACKEND (cbfile),
					      CAL_BACKEND_PROPERTY_REVISION,
					      revision);

	g_free (revision);
}

/* Calendar backend methods */

/* Get_email_address handler for the file backend */
static gchar *
e_cal_backend_file_get_backend_property (ECalBackend *backend,
                                         const gchar *prop_name)
{
	g_return_val_if_fail (prop_name != NULL, FALSE);

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		return g_strjoin (
			",",
			CAL_STATIC_CAPABILITY_NO_EMAIL_ALARMS,
			CAL_STATIC_CAPABILITY_NO_THISANDPRIOR,
			CAL_STATIC_CAPABILITY_DELEGATE_SUPPORTED,
			CAL_STATIC_CAPABILITY_REMOVE_ONLY_THIS,
			CAL_STATIC_CAPABILITY_BULK_ADDS,
			CAL_STATIC_CAPABILITY_BULK_MODIFIES,
			CAL_STATIC_CAPABILITY_BULK_REMOVES,
			CAL_STATIC_CAPABILITY_ALARM_DESCRIPTION,
			CAL_STATIC_CAPABILITY_TASK_CAN_RECUR,
			CAL_STATIC_CAPABILITY_COMPONENT_COLOR,
			NULL);

	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS) ||
		   g_str_equal (prop_name, CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS)) {
		/* A file backend has no particular email address associated
		 * with it (although that would be a useful feature some day).
		 */
		return NULL;

	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_DEFAULT_OBJECT)) {
		ECalComponent *comp;
		gchar *prop_value;

		comp = e_cal_component_new ();

		switch (e_cal_backend_get_kind (E_CAL_BACKEND (backend))) {
		case ICAL_VEVENT_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_EVENT);
			break;
		case ICAL_VTODO_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_TODO);
			break;
		case ICAL_VJOURNAL_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_JOURNAL);
			break;
		default:
			g_object_unref (comp);
			return NULL;
		}

		prop_value = e_cal_component_get_as_string (comp);

		g_object_unref (comp);

		return prop_value;

	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_REVISION)) {
		icalproperty *prop;
		const gchar *revision = NULL;

		/* This returns NULL if backend lacks an icalcomp. */
		prop = ensure_revision (E_CAL_BACKEND_FILE (backend));
		if (prop != NULL)
			revision = icalproperty_get_x (prop);

		return g_strdup (revision);
	}

	/* Chain up to parent's get_backend_property() method. */
	return E_CAL_BACKEND_CLASS (e_cal_backend_file_parent_class)->
		get_backend_property (backend, prop_name);
}

/* function to resolve timezones */
static icaltimezone *
resolve_tzid (const gchar *tzid,
              gpointer user_data)
{
	icalcomponent *vcalendar_comp = user_data;
	icaltimezone * zone;

	if (!tzid || !tzid[0])
		return NULL;
	else if (!strcmp (tzid, "UTC"))
		return icaltimezone_get_utc_timezone ();

	zone = icaltimezone_get_builtin_timezone_from_tzid (tzid);

	if (!zone)
		zone = icalcomponent_get_timezone (vcalendar_comp, tzid);

	return zone;
}

/* Checks if the specified component has a duplicated UID and if so changes it.
 * UIDs may be shared between components if there is at most one component
 * without RECURRENCE-ID (master) and all others have different RECURRENCE-ID
 * values.
 */
static void
check_dup_uid (ECalBackendFile *cbfile,
               ECalComponent *comp)
{
	ECalBackendFilePrivate *priv;
	ECalBackendFileObject *obj_data;
	const gchar *uid = NULL;
	gchar *new_uid = NULL;
	gchar *rid = NULL;

	priv = cbfile->priv;

	e_cal_component_get_uid (comp, &uid);

	if (!uid) {
		g_warning ("Checking for duplicate uid, the component does not have a valid UID skipping it\n");
		return;
	}

	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	if (!obj_data)
		return; /* Everything is fine */

	rid = e_cal_component_get_recurid_as_string (comp);
	if (rid && *rid) {
		/* new component has rid, must not be the same as in other detached recurrence */
		if (!g_hash_table_lookup (obj_data->recurrences, rid))
			goto done;
	} else {
		/* new component has no rid, must not clash with existing master */
		if (!obj_data->full_object)
			goto done;
	}

	d (
		g_message (G_STRLOC ": Got object with duplicated UID `%s' and rid `%s', changing it...",
		uid,
		rid ? rid : ""));

	new_uid = e_util_generate_uid ();
	e_cal_component_set_uid (comp, new_uid);

	/* FIXME: I think we need to reset the SEQUENCE property and reset the
	 * CREATED/DTSTAMP/LAST-MODIFIED.
	 */

	save (cbfile, FALSE);

 done:
	g_free (rid);
	g_free (new_uid);
}

static struct icaltimetype
get_rid_icaltime (ECalComponent *comp)
{
	ECalComponentRange range;
	struct icaltimetype tt;

	e_cal_component_get_recurid (comp, &range);
	if (!range.datetime.value)
		return icaltime_null_time ();
	tt = *range.datetime.value;
	e_cal_component_free_range (&range);

	return tt;
}

/* Adds component to the interval tree
 */
static void
add_component_to_intervaltree (ECalBackendFile *cbfile,
                               ECalComponent *comp)
{
	time_t time_start = -1, time_end = -1;
	ECalBackendFilePrivate *priv;

	g_return_if_fail (cbfile != NULL);
	g_return_if_fail (comp != NULL);

	priv = cbfile->priv;

	e_cal_util_get_component_occur_times (
		comp, &time_start, &time_end,
		resolve_tzid, priv->icalcomp, icaltimezone_get_utc_timezone (),
		e_cal_backend_get_kind (E_CAL_BACKEND (cbfile)));

	if (time_end != -1 && time_start > time_end) {
		gchar *str = e_cal_component_get_as_string (comp);
		g_print ("Bogus component %s\n", str);
		g_free (str);
	} else {
		g_rec_mutex_lock (&priv->idle_save_rmutex);
		e_intervaltree_insert (priv->interval_tree, time_start, time_end, comp);
		g_rec_mutex_unlock (&priv->idle_save_rmutex);
	}
}

static gboolean
remove_component_from_intervaltree (ECalBackendFile *cbfile,
                                    ECalComponent *comp)
{
	const gchar *uid = NULL;
	gchar *rid;
	gboolean res;
	ECalBackendFilePrivate *priv;

	g_return_val_if_fail (cbfile != NULL, FALSE);
	g_return_val_if_fail (comp != NULL, FALSE);

	priv = cbfile->priv;

	rid = e_cal_component_get_recurid_as_string (comp);
	e_cal_component_get_uid (comp, &uid);

	g_rec_mutex_lock (&priv->idle_save_rmutex);
	res = e_intervaltree_remove (priv->interval_tree, uid, rid);
	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	g_free (rid);

	return res;
}

/* Tries to add an icalcomponent to the file backend.  We only store the objects
 * of the types we support; all others just remain in the toplevel component so
 * that we don't lose them.
 *
 * The caller is responsible for ensuring that the component has a UID and that
 * the UID is not in use already.
 */
static void
add_component (ECalBackendFile *cbfile,
               ECalComponent *comp,
               gboolean add_to_toplevel)
{
	ECalBackendFilePrivate *priv;
	ECalBackendFileObject *obj_data;
	const gchar *uid = NULL;

	priv = cbfile->priv;

	e_cal_component_get_uid (comp, &uid);

	if (!uid) {
		g_warning ("The component does not have a valid UID skipping it\n");
		return;
	}

	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	if (e_cal_component_is_instance (comp)) {
		gchar *rid;

		rid = e_cal_component_get_recurid_as_string (comp);
		if (obj_data) {
			if (g_hash_table_lookup (obj_data->recurrences, rid)) {
				g_warning (G_STRLOC ": Tried to add an already existing recurrence");
				g_free (rid);
				return;
			}
		} else {
			obj_data = g_new0 (ECalBackendFileObject, 1);
			obj_data->full_object = NULL;
			obj_data->recurrences = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);
			g_hash_table_insert (priv->comp_uid_hash, g_strdup (uid), obj_data);
		}

		g_hash_table_insert (obj_data->recurrences, rid, comp);
		obj_data->recurrences_list = g_list_append (obj_data->recurrences_list, comp);
	} else {
		if (obj_data) {
			if (obj_data->full_object) {
				g_warning (G_STRLOC ": Tried to add an already existing object");
				return;
			}

			obj_data->full_object = comp;
		} else {
			obj_data = g_new0 (ECalBackendFileObject, 1);
			obj_data->full_object = comp;
			obj_data->recurrences = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);

			g_hash_table_insert (priv->comp_uid_hash, g_strdup (uid), obj_data);
		}
	}

	add_component_to_intervaltree (cbfile, comp);

	priv->comp = g_list_prepend (priv->comp, comp);

	/* Put the object in the toplevel component if required */

	if (add_to_toplevel) {
		icalcomponent *icalcomp;

		icalcomp = e_cal_component_get_icalcomponent (comp);
		g_return_if_fail (icalcomp != NULL);

		icalcomponent_add_component (priv->icalcomp, icalcomp);
	}
}

/* g_hash_table_foreach_remove() callback to remove recurrences from the calendar */
static gboolean
remove_recurrence_cb (gpointer key,
                      gpointer value,
                      gpointer data)
{
	GList *l;
	icalcomponent *icalcomp;
	ECalBackendFilePrivate *priv;
	ECalComponent *comp = value;
	ECalBackendFile *cbfile = data;

	priv = cbfile->priv;

	/* remove the recurrence from the top-level calendar */
	icalcomp = e_cal_component_get_icalcomponent (comp);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	if (!remove_component_from_intervaltree (cbfile, comp)) {
		g_message (G_STRLOC " Could not remove component from interval tree!");
	}
	icalcomponent_remove_component (priv->icalcomp, icalcomp);

	/* remove it from our mapping */
	l = g_list_find (priv->comp, comp);
	priv->comp = g_list_delete_link (priv->comp, l);

	return TRUE;
}

/* Removes a component from the backend's hash and lists.  Does not perform
 * notification on the clients.  Also removes the component from the toplevel
 * icalcomponent.
 */
static void
remove_component (ECalBackendFile *cbfile,
                  const gchar *uid,
                  ECalBackendFileObject *obj_data)
{
	ECalBackendFilePrivate *priv;
	icalcomponent *icalcomp;
	GList *l;

	priv = cbfile->priv;

	/* Remove the icalcomp from the toplevel */
	if (obj_data->full_object) {
		icalcomp = e_cal_component_get_icalcomponent (obj_data->full_object);
		g_return_if_fail (icalcomp != NULL);

		icalcomponent_remove_component (priv->icalcomp, icalcomp);

		/* Remove it from our mapping */
		l = g_list_find (priv->comp, obj_data->full_object);
		g_return_if_fail (l != NULL);
		priv->comp = g_list_delete_link (priv->comp, l);

		if (!remove_component_from_intervaltree (cbfile, obj_data->full_object)) {
			g_message (G_STRLOC " Could not remove component from interval tree!");
		}
	}

	/* remove the recurrences also */
	g_hash_table_foreach_remove (obj_data->recurrences, (GHRFunc) remove_recurrence_cb, cbfile);

	g_hash_table_remove (priv->comp_uid_hash, uid);

	save (cbfile, TRUE);
}

/* Scans the toplevel VCALENDAR component and stores the objects it finds */
static void
scan_vcalendar (ECalBackendFile *cbfile)
{
	ECalBackendFilePrivate *priv;
	icalcompiter iter;

	priv = cbfile->priv;
	g_return_if_fail (priv->icalcomp != NULL);
	g_return_if_fail (priv->comp_uid_hash != NULL);

	for (iter = icalcomponent_begin_component (priv->icalcomp, ICAL_ANY_COMPONENT);
	     icalcompiter_deref (&iter) != NULL;
	     icalcompiter_next (&iter)) {
		icalcomponent *icalcomp;
		icalcomponent_kind kind;
		ECalComponent *comp;

		icalcomp = icalcompiter_deref (&iter);

		kind = icalcomponent_isa (icalcomp);

		if (!(kind == ICAL_VEVENT_COMPONENT
		      || kind == ICAL_VTODO_COMPONENT
		      || kind == ICAL_VJOURNAL_COMPONENT))
			continue;

		comp = e_cal_component_new ();

		if (!e_cal_component_set_icalcomponent (comp, icalcomp))
			continue;

		check_dup_uid (cbfile, comp);

		add_component (cbfile, comp, FALSE);
	}
}

static gchar *
uri_to_path (ECalBackend *backend)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	ESource *source;
	ESourceLocal *local_extension;
	GFile *custom_file;
	const gchar *extension_name;
	const gchar *cache_dir;
	gchar *filename = NULL;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	cache_dir = e_cal_backend_get_cache_dir (backend);

	source = e_backend_get_source (E_BACKEND (backend));

	extension_name = E_SOURCE_EXTENSION_LOCAL_BACKEND;
	local_extension = e_source_get_extension (source, extension_name);

	custom_file = e_source_local_dup_custom_file (local_extension);
	if (custom_file != NULL) {
		filename = g_file_get_path (custom_file);
		g_object_unref (custom_file);
	}

	if (filename == NULL)
		filename = g_build_filename (cache_dir, priv->file_name, NULL);

	if (filename != NULL && *filename == '\0') {
		g_free (filename);
		filename = NULL;
	}

	return filename;
}

static gpointer
refresh_thread_func (gpointer data)
{
	ECalBackendFile *cbfile = data;
	ECalBackendFilePrivate *priv;
	ESource *source;
	ESourceLocal *extension;
	GFileInfo *info;
	GFile *file;
	const gchar *extension_name;
	guint64 last_modified, modified;

	g_return_val_if_fail (cbfile != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_BACKEND_FILE (cbfile), NULL);

	priv = cbfile->priv;

	extension_name = E_SOURCE_EXTENSION_LOCAL_BACKEND;
	source = e_backend_get_source (E_BACKEND (cbfile));
	extension = e_source_get_extension (source, extension_name);

	/* This returns a newly-created GFile. */
	file = e_source_local_dup_custom_file (extension);
	g_return_val_if_fail (G_IS_FILE (file), NULL);

	info = g_file_query_info (
		file, G_FILE_ATTRIBUTE_TIME_MODIFIED,
		G_FILE_QUERY_INFO_NONE, NULL, NULL);
	g_return_val_if_fail (info != NULL, NULL);

	last_modified = g_file_info_get_attribute_uint64 (info, G_FILE_ATTRIBUTE_TIME_MODIFIED);
	g_object_unref (info);

	g_mutex_lock (&priv->refresh_lock);
	while (!priv->refresh_thread_stop) {
		g_cond_wait (priv->refresh_cond, &priv->refresh_lock);

		g_rec_mutex_lock (&priv->idle_save_rmutex);

		if (priv->refresh_skip > 0) {
			priv->refresh_skip--;
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			continue;
		}

		if (priv->is_dirty) {
			/* save before reload, if dirty */
			if (priv->dirty_idle_id) {
				g_source_remove (priv->dirty_idle_id);
				priv->dirty_idle_id = 0;
			}
			save_file_when_idle (cbfile);
			priv->refresh_skip = 0;
		}

		g_rec_mutex_unlock (&priv->idle_save_rmutex);

		info = g_file_query_info (file, G_FILE_ATTRIBUTE_TIME_MODIFIED, G_FILE_QUERY_INFO_NONE, NULL, NULL);
		if (!info)
			break;

		modified = g_file_info_get_attribute_uint64 (info, G_FILE_ATTRIBUTE_TIME_MODIFIED);
		g_object_unref (info);

		if (modified != last_modified) {
			last_modified = modified;
			e_cal_backend_file_reload (cbfile, NULL);
		}
	}

	g_object_unref (file);
	g_cond_signal (priv->refresh_gone_cond);
	g_mutex_unlock (&priv->refresh_lock);

	return NULL;
}

static void
custom_file_changed (GFileMonitor *monitor,
                     GFile *file,
                     GFile *other_file,
                     GFileMonitorEvent event_type,
                     ECalBackendFilePrivate *priv)
{
	if (priv->refresh_cond)
		g_cond_signal (priv->refresh_cond);
}

static void
prepare_refresh_data (ECalBackendFile *cbfile)
{
	ECalBackendFilePrivate *priv;
	ESource *source;
	ESourceLocal *local_extension;
	GFile *custom_file;
	const gchar *extension_name;

	g_return_if_fail (cbfile != NULL);

	priv = cbfile->priv;

	g_mutex_lock (&priv->refresh_lock);

	priv->refresh_thread_stop = FALSE;
	priv->refresh_skip = 0;

	source = e_backend_get_source (E_BACKEND (cbfile));

	extension_name = E_SOURCE_EXTENSION_LOCAL_BACKEND;
	local_extension = e_source_get_extension (source, extension_name);

	custom_file = e_source_local_dup_custom_file (local_extension);

	if (custom_file != NULL) {
		GError *error = NULL;

		priv->refresh_monitor = g_file_monitor_file (
			custom_file, G_FILE_MONITOR_WATCH_MOUNTS, NULL, &error);

		if (error == NULL) {
			g_signal_connect (
				priv->refresh_monitor, "changed",
				G_CALLBACK (custom_file_changed), priv);
		} else {
			g_warning ("%s", error->message);
			g_error_free (error);
		}

		g_object_unref (custom_file);
	}

	if (priv->refresh_monitor) {
		GThread *thread;

		priv->refresh_cond = g_new0 (GCond, 1);
		priv->refresh_gone_cond = g_new0 (GCond, 1);

		thread = g_thread_new (NULL, refresh_thread_func, cbfile);
		g_thread_unref (thread);
	}

	g_mutex_unlock (&priv->refresh_lock);
}

static void
free_refresh_data (ECalBackendFile *cbfile)
{
	ECalBackendFilePrivate *priv;

	g_return_if_fail (E_IS_CAL_BACKEND_FILE (cbfile));

	priv = cbfile->priv;

	g_mutex_lock (&priv->refresh_lock);

	if (priv->refresh_monitor)
		g_object_unref (priv->refresh_monitor);
	priv->refresh_monitor = NULL;

	if (priv->refresh_cond) {
		priv->refresh_thread_stop = TRUE;
		g_cond_signal (priv->refresh_cond);
		g_cond_wait (priv->refresh_gone_cond, &priv->refresh_lock);

		g_cond_clear (priv->refresh_cond);
		g_free (priv->refresh_cond);
		priv->refresh_cond = NULL;
		g_cond_clear (priv->refresh_gone_cond);
		g_free (priv->refresh_gone_cond);
		priv->refresh_gone_cond = NULL;
	}

	priv->refresh_skip = 0;

	g_mutex_unlock (&priv->refresh_lock);
}

static void
cal_backend_file_take_icalcomp (ECalBackendFile *cbfile,
                                icalcomponent *icalcomp)
{
	icalproperty *prop;

	g_warn_if_fail (cbfile->priv->icalcomp == NULL);
	cbfile->priv->icalcomp = icalcomp;

	prop = ensure_revision (cbfile);

	e_cal_backend_notify_property_changed (
		E_CAL_BACKEND (cbfile),
		CAL_BACKEND_PROPERTY_REVISION,
		icalproperty_get_x (prop));
}

/* Parses an open iCalendar file and loads it into the backend */
static void
open_cal (ECalBackendFile *cbfile,
          const gchar *uristr,
          GError **perror)
{
	ECalBackendFilePrivate *priv;
	icalcomponent *icalcomp;

	priv = cbfile->priv;

	free_refresh_data (cbfile);

	icalcomp = e_cal_util_parse_ics_file (uristr);
	if (!icalcomp) {
		g_propagate_error (perror, e_data_cal_create_error_fmt (OtherError, "Cannot parse ISC file '%s'", uristr));
		return;
	}

	/* FIXME: should we try to demangle XROOT components and
	 * individual components as well?
	 */

	if (icalcomponent_isa (icalcomp) != ICAL_VCALENDAR_COMPONENT) {
		icalcomponent_free (icalcomp);

		g_propagate_error (perror, e_data_cal_create_error_fmt (OtherError, "File '%s' is not v VCALENDAR component", uristr));
		return;
	}

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	cal_backend_file_take_icalcomp (cbfile, icalcomp);
	priv->path = uri_to_path (E_CAL_BACKEND (cbfile));

	priv->comp_uid_hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, free_object_data);
	priv->interval_tree = e_intervaltree_new ();
	scan_vcalendar (cbfile);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	prepare_refresh_data (cbfile);
}

typedef struct
{
	ECalBackend *backend;
	GHashTable *old_uid_hash;
	GHashTable *new_uid_hash;
}
BackendDeltaContext;

static void
notify_removals_cb (gpointer key,
                    gpointer value,
                    gpointer data)
{
	BackendDeltaContext *context = data;
	const gchar *uid = key;
	ECalBackendFileObject *old_obj_data = value;

	if (!g_hash_table_lookup (context->new_uid_hash, uid)) {
		ECalComponentId *id;

		/* Object was removed */

		if (!old_obj_data->full_object)
			return;

		id = e_cal_component_get_id (old_obj_data->full_object);

		e_cal_backend_notify_component_removed (context->backend, id, old_obj_data->full_object, NULL);

		e_cal_component_free_id (id);
	}
}

static void
notify_adds_modifies_cb (gpointer key,
                         gpointer value,
                         gpointer data)
{
	BackendDeltaContext *context = data;
	const gchar *uid = key;
	ECalBackendFileObject *new_obj_data = value;
	ECalBackendFileObject *old_obj_data;

	old_obj_data = g_hash_table_lookup (context->old_uid_hash, uid);

	if (!old_obj_data) {
		/* Object was added */
		if (!new_obj_data->full_object)
			return;

		e_cal_backend_notify_component_created (context->backend, new_obj_data->full_object);
	} else {
		gchar *old_obj_str, *new_obj_str;

		if (!old_obj_data->full_object || !new_obj_data->full_object)
			return;

		/* There should be better ways to compare an icalcomponent
		 * than serializing and comparing the strings...
		 */
		old_obj_str = e_cal_component_get_as_string (old_obj_data->full_object);
		new_obj_str = e_cal_component_get_as_string (new_obj_data->full_object);
		if (old_obj_str && new_obj_str && strcmp (old_obj_str, new_obj_str) != 0) {
			/* Object was modified */
			e_cal_backend_notify_component_modified (context->backend, old_obj_data->full_object, new_obj_data->full_object);
		}

		g_free (old_obj_str);
		g_free (new_obj_str);
	}
}

static void
notify_changes (ECalBackendFile *cbfile,
                GHashTable *old_uid_hash,
                GHashTable *new_uid_hash)
{
	BackendDeltaContext context;

	context.backend = E_CAL_BACKEND (cbfile);
	context.old_uid_hash = old_uid_hash;
	context.new_uid_hash = new_uid_hash;

	g_hash_table_foreach (old_uid_hash, (GHFunc) notify_removals_cb, &context);
	g_hash_table_foreach (new_uid_hash, (GHFunc) notify_adds_modifies_cb, &context);
}

static void
reload_cal (ECalBackendFile *cbfile,
            const gchar *uristr,
            GError **perror)
{
	ECalBackendFilePrivate *priv;
	icalcomponent *icalcomp, *icalcomp_old;
	GHashTable *comp_uid_hash_old;

	priv = cbfile->priv;

	icalcomp = e_cal_util_parse_ics_file (uristr);
	if (!icalcomp) {
		g_propagate_error (perror, e_data_cal_create_error_fmt (OtherError, "Cannot parse ISC file '%s'", uristr));
		return;
	}

	/* FIXME: should we try to demangle XROOT components and
	 * individual components as well?
	 */

	if (icalcomponent_isa (icalcomp) != ICAL_VCALENDAR_COMPONENT) {
		icalcomponent_free (icalcomp);

		g_propagate_error (perror, e_data_cal_create_error_fmt (OtherError, "File '%s' is not v VCALENDAR component", uristr));
		return;
	}

	/* Keep old data for comparison - free later */

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	icalcomp_old = priv->icalcomp;
	priv->icalcomp = NULL;

	comp_uid_hash_old = priv->comp_uid_hash;
	priv->comp_uid_hash = NULL;

	/* Load new calendar */

	free_calendar_data (cbfile);

	cal_backend_file_take_icalcomp (cbfile, icalcomp);

	priv->comp_uid_hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, free_object_data);
	priv->interval_tree = e_intervaltree_new ();
	scan_vcalendar (cbfile);

	priv->path = uri_to_path (E_CAL_BACKEND (cbfile));

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	/* Compare old and new versions of calendar */

	notify_changes (cbfile, comp_uid_hash_old, priv->comp_uid_hash);

	/* Free old data */

	free_calendar_components (comp_uid_hash_old, icalcomp_old);
}

static void
create_cal (ECalBackendFile *cbfile,
            const gchar *uristr,
            GError **perror)
{
	gchar *dirname;
	ECalBackendFilePrivate *priv;
	icalcomponent *icalcomp;

	free_refresh_data (cbfile);

	priv = cbfile->priv;

	/* Create the directory to contain the file */
	dirname = g_path_get_dirname (uristr);
	if (g_mkdir_with_parents (dirname, 0700) != 0) {
		g_free (dirname);
		g_propagate_error (perror, EDC_ERROR (NoSuchCal));
		return;
	}

	g_free (dirname);

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	/* Create the new calendar information */
	icalcomp = e_cal_util_new_top_level ();
	cal_backend_file_take_icalcomp (cbfile, icalcomp);

	/* Create our internal data */
	priv->comp_uid_hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, free_object_data);
	priv->interval_tree = e_intervaltree_new ();

	priv->path = uri_to_path (E_CAL_BACKEND (cbfile));

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	save (cbfile, TRUE);

	prepare_refresh_data (cbfile);
}

static gchar *
get_uri_string (ECalBackend *backend)
{
	gchar *str_uri, *full_uri;

	str_uri = uri_to_path (backend);
	full_uri = g_uri_unescape_string (str_uri, "");
	g_free (str_uri);

	return full_uri;
}

static void
source_changed_cb (ESource *source,
                   ECalBackend *backend)
{
	ESourceLocal *extension;
	const gchar *extension_name;
	gboolean backend_writable;
	gboolean source_writable;

	g_return_if_fail (source != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	extension_name = E_SOURCE_EXTENSION_LOCAL_BACKEND;
	extension = e_source_get_extension (source, extension_name);

	if (e_source_local_get_custom_file (extension) == NULL)
		return;

	source_writable = e_source_get_writable (source);
	backend_writable = e_cal_backend_get_writable (backend);

	if (source_writable != backend_writable) {
		backend_writable = source_writable;
		if (e_source_get_writable (source)) {
			gchar *str_uri = get_uri_string (backend);

			g_return_if_fail (str_uri != NULL);

			backend_writable = (g_access (str_uri, W_OK) != 0);

			g_free (str_uri);
		}

		e_cal_backend_set_writable (backend, backend_writable);
	}
}

/* Open handler for the file backend */
static void
e_cal_backend_file_open (ECalBackendSync *backend,
                         EDataCal *cal,
                         GCancellable *cancellable,
                         gboolean only_if_exists,
                         GError **perror)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	gchar *str_uri;
	gboolean writable = FALSE;
	GError *err = NULL;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;
	g_rec_mutex_lock (&priv->idle_save_rmutex);

	/* Local source is always connected. */
	e_source_set_connection_status (e_backend_get_source (E_BACKEND (backend)),
		E_SOURCE_CONNECTION_STATUS_CONNECTED);

	/* Claim a succesful open if we are already open */
	if (priv->path && priv->comp_uid_hash) {
		/* Success */
		goto done;
	}

	str_uri = get_uri_string (E_CAL_BACKEND (backend));
	if (!str_uri) {
		err = EDC_ERROR_NO_URI ();
		goto done;
	}

	writable = TRUE;
	if (g_access (str_uri, R_OK) == 0) {
		open_cal (cbfile, str_uri, &err);
		if (g_access (str_uri, W_OK) != 0)
			writable = FALSE;
	} else {
		if (only_if_exists)
			err = EDC_ERROR (NoSuchCal);
		else
			create_cal (cbfile, str_uri, &err);
	}

	if (!err) {
		if (writable) {
			ESource *source;

			source = e_backend_get_source (E_BACKEND (backend));

			g_signal_connect (
				source, "changed",
				G_CALLBACK (source_changed_cb), backend);

			if (!e_source_get_writable (source))
				writable = FALSE;
		}
	}

	g_free (str_uri);

  done:
	g_rec_mutex_unlock (&priv->idle_save_rmutex);
	e_cal_backend_set_writable (E_CAL_BACKEND (backend), writable);
	e_backend_set_online (E_BACKEND (backend), TRUE);

	if (err)
		g_propagate_error (perror, g_error_copy (err));
}

static void
add_detached_recur_to_vcalendar (gpointer key,
                                 gpointer value,
                                 gpointer user_data)
{
	ECalComponent *recurrence = value;
	icalcomponent *vcalendar = user_data;

	icalcomponent_add_component (
		vcalendar,
		icalcomponent_new_clone (e_cal_component_get_icalcomponent (recurrence)));
}

/* Get_object_component handler for the file backend */
static void
e_cal_backend_file_get_object (ECalBackendSync *backend,
                               EDataCal *cal,
                               GCancellable *cancellable,
                               const gchar *uid,
                               const gchar *rid,
                               gchar **object,
                               GError **error)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	ECalBackendFileObject *obj_data;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		return;
	}

	g_return_if_fail (uid != NULL);
	g_return_if_fail (priv->comp_uid_hash != NULL);

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	if (!obj_data) {
		g_rec_mutex_unlock (&priv->idle_save_rmutex);
		g_propagate_error (error, EDC_ERROR (ObjectNotFound));
		return;
	}

	if (rid && *rid) {
		ECalComponent *comp;

		comp = g_hash_table_lookup (obj_data->recurrences, rid);
		if (comp) {
			*object = e_cal_component_get_as_string (comp);
		} else {
			icalcomponent *icalcomp;
			struct icaltimetype itt;

			if (!obj_data->full_object) {
				g_rec_mutex_unlock (&priv->idle_save_rmutex);
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
				return;
			}

			itt = icaltime_from_string (rid);
			icalcomp = e_cal_util_construct_instance (
				e_cal_component_get_icalcomponent (obj_data->full_object),
				itt);
			if (!icalcomp) {
				g_rec_mutex_unlock (&priv->idle_save_rmutex);
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
				return;
			}

			*object = icalcomponent_as_ical_string_r (icalcomp);

			icalcomponent_free (icalcomp);
		}
	} else {
		if (g_hash_table_size (obj_data->recurrences) > 0) {
			icalcomponent *icalcomp;

			/* if we have detached recurrences, return a VCALENDAR */
			icalcomp = e_cal_util_new_top_level ();

			/* detached recurrences don't have full_object */
			if (obj_data->full_object)
				icalcomponent_add_component (
					icalcomp,
					icalcomponent_new_clone (e_cal_component_get_icalcomponent (obj_data->full_object)));

			/* add all detached recurrences */
			g_hash_table_foreach (obj_data->recurrences, (GHFunc) add_detached_recur_to_vcalendar, icalcomp);

			*object = icalcomponent_as_ical_string_r (icalcomp);

			icalcomponent_free (icalcomp);
		} else if (obj_data->full_object)
			*object = e_cal_component_get_as_string (obj_data->full_object);
	}

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

/* Add_timezone handler for the file backend */
static void
e_cal_backend_file_add_timezone (ECalBackendSync *backend,
                                 EDataCal *cal,
                                 GCancellable *cancellable,
                                 const gchar *tzobj,
                                 GError **error)
{
	ETimezoneCache *timezone_cache;
	icalcomponent *tz_comp;

	timezone_cache = E_TIMEZONE_CACHE (backend);

	tz_comp = icalparser_parse_string (tzobj);
	if (!tz_comp) {
		g_propagate_error (error, EDC_ERROR (InvalidObject));
		return;
	}

	if (icalcomponent_isa (tz_comp) == ICAL_VTIMEZONE_COMPONENT) {
		icaltimezone *zone;

		zone = icaltimezone_new ();
		icaltimezone_set_component (zone, tz_comp);
		e_timezone_cache_add_timezone (timezone_cache, zone);
		icaltimezone_free (zone, 1);
	}
}

typedef struct {
	GSList *comps_list;
	gboolean search_needed;
	const gchar *query;
	ECalBackendSExp *obj_sexp;
	ECalBackend *backend;
	EDataCalView *view;
	gboolean as_string;
} MatchObjectData;

static void
match_object_sexp_to_component (gpointer value,
                                gpointer data)
{
	ECalComponent * comp = value;
	MatchObjectData *match_data = data;
	ETimezoneCache *timezone_cache;
	const gchar *uid;

	e_cal_component_get_uid (comp, &uid);

	g_return_if_fail (comp != NULL);

	g_return_if_fail (match_data->backend != NULL);

	timezone_cache = E_TIMEZONE_CACHE (match_data->backend);

	if ((!match_data->search_needed) ||
	    (e_cal_backend_sexp_match_comp (match_data->obj_sexp, comp, timezone_cache))) {
		if (match_data->as_string)
			match_data->comps_list = g_slist_prepend (match_data->comps_list, e_cal_component_get_as_string (comp));
		else
			match_data->comps_list = g_slist_prepend (match_data->comps_list, comp);
	}
}

static void
match_recurrence_sexp (gpointer key,
                       gpointer value,
                       gpointer data)
{
	ECalComponent *comp = value;
	MatchObjectData *match_data = data;
	ETimezoneCache *timezone_cache;

	timezone_cache = E_TIMEZONE_CACHE (match_data->backend);

	if ((!match_data->search_needed) ||
	    (e_cal_backend_sexp_match_comp (match_data->obj_sexp, comp, timezone_cache))) {
		if (match_data->as_string)
			match_data->comps_list = g_slist_prepend (match_data->comps_list, e_cal_component_get_as_string (comp));
		else
			match_data->comps_list = g_slist_prepend (match_data->comps_list, comp);
	}
}

static void
match_object_sexp (gpointer key,
                   gpointer value,
                   gpointer data)
{
	ECalBackendFileObject *obj_data = value;
	MatchObjectData *match_data = data;
	ETimezoneCache *timezone_cache;

	timezone_cache = E_TIMEZONE_CACHE (match_data->backend);

	if (obj_data->full_object) {
		if ((!match_data->search_needed) ||
		    (e_cal_backend_sexp_match_comp (match_data->obj_sexp,
						    obj_data->full_object,
						    timezone_cache))) {
			if (match_data->as_string)
				match_data->comps_list = g_slist_prepend (match_data->comps_list, e_cal_component_get_as_string (obj_data->full_object));
			else
				match_data->comps_list = g_slist_prepend (match_data->comps_list, obj_data->full_object);
		}
	}

	/* match also recurrences */
	g_hash_table_foreach (obj_data->recurrences,
			      (GHFunc) match_recurrence_sexp,
			      match_data);
}

/* Get_objects_in_range handler for the file backend */
static void
e_cal_backend_file_get_object_list (ECalBackendSync *backend,
                                    EDataCal *cal,
                                    GCancellable *cancellable,
                                    const gchar *sexp,
                                    GSList **objects,
                                    GError **perror)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	MatchObjectData match_data = { 0, };
	time_t occur_start = -1, occur_end = -1;
	gboolean prunning_by_time;
	GList * objs_occuring_in_tw;
	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	d (g_message (G_STRLOC ": Getting object list (%s)", sexp));

	match_data.search_needed = TRUE;
	match_data.query = sexp;
	match_data.comps_list = NULL;
	match_data.as_string = TRUE;
	match_data.backend = E_CAL_BACKEND (backend);

	if (sexp && !strcmp (sexp, "#t"))
		match_data.search_needed = FALSE;

	match_data.obj_sexp = e_cal_backend_sexp_new (sexp);
	if (!match_data.obj_sexp) {
		g_propagate_error (perror, EDC_ERROR (InvalidQuery));
		return;
	}

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	prunning_by_time = e_cal_backend_sexp_evaluate_occur_times (
		match_data.obj_sexp,
		&occur_start,
		&occur_end);

	objs_occuring_in_tw = NULL;

	if (!prunning_by_time) {
		g_hash_table_foreach (priv->comp_uid_hash, (GHFunc) match_object_sexp,
				      &match_data);
	} else {
		objs_occuring_in_tw = e_intervaltree_search (
			priv->interval_tree,
			occur_start, occur_end);

		g_list_foreach (objs_occuring_in_tw, (GFunc) match_object_sexp_to_component,
			       &match_data);
	}

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	*objects = g_slist_reverse (match_data.comps_list);

	if (objs_occuring_in_tw) {
		g_list_foreach (objs_occuring_in_tw, (GFunc) g_object_unref, NULL);
		g_list_free (objs_occuring_in_tw);
	}

	g_object_unref (match_data.obj_sexp);
}

static void
add_attach_uris (GSList **attachment_uris,
                 icalcomponent *icalcomp)
{
	icalproperty *prop;

	g_return_if_fail (attachment_uris != NULL);
	g_return_if_fail (icalcomp != NULL);

	for (prop = icalcomponent_get_first_property (icalcomp, ICAL_ATTACH_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (icalcomp, ICAL_ATTACH_PROPERTY)) {
		icalattach *attach = icalproperty_get_attach (prop);

		if (attach && icalattach_get_is_url (attach)) {
			const gchar *url;

			url = icalattach_get_url (attach);
			if (url) {
				gsize buf_size;
				gchar *buf;

				buf_size = strlen (url);
				buf = g_malloc0 (buf_size + 1);

				icalvalue_decode_ical_string (url, buf, buf_size);

				*attachment_uris = g_slist_prepend (*attachment_uris, g_strdup (buf));

				g_free (buf);
			}
		}
	}
}

static void
add_detached_recur_attach_uris (gpointer key,
                                gpointer value,
                                gpointer user_data)
{
	ECalComponent *recurrence = value;
	GSList **attachment_uris = user_data;

	add_attach_uris (attachment_uris, e_cal_component_get_icalcomponent (recurrence));
}

/* Gets the list of attachments */
static void
e_cal_backend_file_get_attachment_uris (ECalBackendSync *backend,
                                        EDataCal *cal,
                                        GCancellable *cancellable,
                                        const gchar *uid,
                                        const gchar *rid,
                                        GSList **attachment_uris,
                                        GError **error)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	ECalBackendFileObject *obj_data;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	g_return_if_fail (priv->comp_uid_hash != NULL);

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	if (!obj_data) {
		g_rec_mutex_unlock (&priv->idle_save_rmutex);
		g_propagate_error (error, EDC_ERROR (ObjectNotFound));
		return;
	}

	if (rid && *rid) {
		ECalComponent *comp;

		comp = g_hash_table_lookup (obj_data->recurrences, rid);
		if (comp) {
			add_attach_uris (attachment_uris, e_cal_component_get_icalcomponent (comp));
		} else {
			icalcomponent *icalcomp;
			struct icaltimetype itt;

			if (!obj_data->full_object) {
				g_rec_mutex_unlock (&priv->idle_save_rmutex);
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
				return;
			}

			itt = icaltime_from_string (rid);
			icalcomp = e_cal_util_construct_instance (
				e_cal_component_get_icalcomponent (obj_data->full_object),
				itt);
			if (!icalcomp) {
				g_rec_mutex_unlock (&priv->idle_save_rmutex);
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
				return;
			}

			add_attach_uris (attachment_uris, icalcomp);

			icalcomponent_free (icalcomp);
		}
	} else {
		if (g_hash_table_size (obj_data->recurrences) > 0) {
			/* detached recurrences don't have full_object */
			if (obj_data->full_object)
				add_attach_uris (attachment_uris, e_cal_component_get_icalcomponent (obj_data->full_object));

			/* add all detached recurrences */
			g_hash_table_foreach (obj_data->recurrences, add_detached_recur_attach_uris, attachment_uris);
		} else if (obj_data->full_object)
			add_attach_uris (attachment_uris, e_cal_component_get_icalcomponent (obj_data->full_object));
	}

	*attachment_uris = g_slist_reverse (*attachment_uris);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

/* get_query handler for the file backend */
static void
e_cal_backend_file_start_view (ECalBackend *backend,
                               EDataCalView *query)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	ECalBackendSExp *sexp;
	MatchObjectData match_data = { 0, };
	time_t occur_start = -1, occur_end = -1;
	gboolean prunning_by_time;
	GList * objs_occuring_in_tw;
	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	sexp = e_data_cal_view_get_sexp (query);

	d (g_message (G_STRLOC ": Starting query (%s)", e_cal_backend_sexp_text (sexp)));

	/* try to match all currently existing objects */
	match_data.search_needed = TRUE;
	match_data.query = e_cal_backend_sexp_text (sexp);
	match_data.comps_list = NULL;
	match_data.as_string = FALSE;
	match_data.backend = backend;
	match_data.obj_sexp = e_data_cal_view_get_sexp (query);
	match_data.view = query;

	if (match_data.query && !strcmp (match_data.query, "#t"))
		match_data.search_needed = FALSE;

	if (!match_data.obj_sexp) {
		GError *error = EDC_ERROR (InvalidQuery);
		e_data_cal_view_notify_complete (query, error);
		g_error_free (error);
		return;
	}
	prunning_by_time = e_cal_backend_sexp_evaluate_occur_times (
		match_data.obj_sexp,
		&occur_start,
		&occur_end);

	objs_occuring_in_tw = NULL;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	if (!prunning_by_time) {
		/* full scan */
		g_hash_table_foreach (priv->comp_uid_hash, (GHFunc) match_object_sexp,
				      &match_data);

		e_debug_log (
			FALSE, E_DEBUG_LOG_DOMAIN_CAL_QUERIES,  "---;%p;QUERY-ITEMS;%s;%s;%d", query,
			e_cal_backend_sexp_text (sexp), G_OBJECT_TYPE_NAME (backend),
			g_hash_table_size (priv->comp_uid_hash));
	} else {
		/* matches objects in new "interval tree" way */
		/* events occuring in time window */
		objs_occuring_in_tw = e_intervaltree_search (priv->interval_tree, occur_start, occur_end);

		g_list_foreach (objs_occuring_in_tw, (GFunc) match_object_sexp_to_component,
			       &match_data);

		e_debug_log (
			FALSE, E_DEBUG_LOG_DOMAIN_CAL_QUERIES,  "---;%p;QUERY-ITEMS;%s;%s;%d", query,
			e_cal_backend_sexp_text (sexp), G_OBJECT_TYPE_NAME (backend),
			g_list_length (objs_occuring_in_tw));
	}

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	/* notify listeners of all objects */
	if (match_data.comps_list) {
		match_data.comps_list = g_slist_reverse (match_data.comps_list);

		e_data_cal_view_notify_components_added (query, match_data.comps_list);

		/* free memory */
		g_slist_free (match_data.comps_list);
	}

	if (objs_occuring_in_tw) {
		g_list_foreach (objs_occuring_in_tw, (GFunc) g_object_unref, NULL);
		g_list_free (objs_occuring_in_tw);
	}

	e_data_cal_view_notify_complete (query, NULL /* Success */);
}

static gboolean
free_busy_instance (ECalComponent *comp,
                    time_t instance_start,
                    time_t instance_end,
                    gpointer data)
{
	icalcomponent *vfb = data;
	icalproperty *prop;
	icalparameter *param;
	struct icalperiodtype ipt;
	icaltimezone *utc_zone;
	const gchar *summary, *location;

	utc_zone = icaltimezone_get_utc_timezone ();

	ipt.start = icaltime_from_timet_with_zone (instance_start, FALSE, utc_zone);
	ipt.end = icaltime_from_timet_with_zone (instance_end, FALSE, utc_zone);
	ipt.duration = icaldurationtype_null_duration ();

        /* add busy information to the vfb component */
	prop = icalproperty_new (ICAL_FREEBUSY_PROPERTY);
	icalproperty_set_freebusy (prop, ipt);

	param = icalparameter_new_fbtype (ICAL_FBTYPE_BUSY);
	icalproperty_add_parameter (prop, param);

	summary = icalcomponent_get_summary (e_cal_component_get_icalcomponent (comp));
	if (summary && *summary)
		icalproperty_set_parameter_from_string (prop, "X-SUMMARY", summary);
	location = icalcomponent_get_location (e_cal_component_get_icalcomponent (comp));
	if (location && *location)
		icalproperty_set_parameter_from_string (prop, "X-LOCATION", location);

	icalcomponent_add_property (vfb, prop);

	return TRUE;
}

static icalcomponent *
create_user_free_busy (ECalBackendFile *cbfile,
                       const gchar *address,
                       const gchar *cn,
                       time_t start,
                       time_t end)
{
	ECalBackendFilePrivate *priv;
	GList *l;
	icalcomponent *vfb;
	icaltimezone *utc_zone;
	ECalBackendSExp *obj_sexp;
	gchar *query, *iso_start, *iso_end;

	priv = cbfile->priv;

	/* create the (unique) VFREEBUSY object that we'll return */
	vfb = icalcomponent_new_vfreebusy ();
	if (address != NULL) {
		icalproperty *prop;
		icalparameter *param;

		prop = icalproperty_new_organizer (address);
		if (prop != NULL && cn != NULL) {
			param = icalparameter_new_cn (cn);
			icalproperty_add_parameter (prop, param);
		}
		if (prop != NULL)
			icalcomponent_add_property (vfb, prop);
	}
	utc_zone = icaltimezone_get_utc_timezone ();
	icalcomponent_set_dtstart (vfb, icaltime_from_timet_with_zone (start, FALSE, utc_zone));
	icalcomponent_set_dtend (vfb, icaltime_from_timet_with_zone (end, FALSE, utc_zone));

	/* add all objects in the given interval */
	iso_start = isodate_from_time_t (start);
	iso_end = isodate_from_time_t (end);
	query = g_strdup_printf (
		"occur-in-time-range? (make-time \"%s\") (make-time \"%s\")",
		iso_start, iso_end);
	obj_sexp = e_cal_backend_sexp_new (query);
	g_free (query);
	g_free (iso_start);
	g_free (iso_end);

	if (!obj_sexp)
		return vfb;

	for (l = priv->comp; l; l = l->next) {
		ECalComponent *comp = l->data;
		icalcomponent *icalcomp, *vcalendar_comp;
		icalproperty *prop;

		icalcomp = e_cal_component_get_icalcomponent (comp);
		if (!icalcomp)
			continue;

		/* If the event is TRANSPARENT, skip it. */
		prop = icalcomponent_get_first_property (
			icalcomp,
			ICAL_TRANSP_PROPERTY);
		if (prop) {
			icalproperty_transp transp_val = icalproperty_get_transp (prop);
			if (transp_val == ICAL_TRANSP_TRANSPARENT ||
			    transp_val == ICAL_TRANSP_TRANSPARENTNOCONFLICT)
				continue;
		}

		if (!e_cal_backend_sexp_match_comp (
			obj_sexp, l->data,
			E_TIMEZONE_CACHE (cbfile)))
			continue;

		vcalendar_comp = icalcomponent_get_parent (icalcomp);
		e_cal_recur_generate_instances (
			comp, start, end,
			free_busy_instance,
			vfb,
			resolve_tzid,
			vcalendar_comp,
			icaltimezone_get_utc_timezone ());
	}
	g_object_unref (obj_sexp);

	return vfb;
}

/* Get_free_busy handler for the file backend */
static void
e_cal_backend_file_get_free_busy (ECalBackendSync *backend,
                                  EDataCal *cal,
                                  GCancellable *cancellable,
                                  const GSList *users,
                                  time_t start,
                                  time_t end,
                                  GSList **freebusy,
                                  GError **error)
{
	ESourceRegistry *registry;
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	gchar *address, *name;
	icalcomponent *vfb;
	gchar *calobj;
	const GSList *l;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR));
		return;
	}

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	*freebusy = NULL;

	registry = e_cal_backend_get_registry (E_CAL_BACKEND (backend));

	if (users == NULL) {
		if (e_cal_backend_mail_account_get_default (registry, &address, &name)) {
			vfb = create_user_free_busy (cbfile, address, name, start, end);
			calobj = icalcomponent_as_ical_string_r (vfb);
			*freebusy = g_slist_append (*freebusy, calobj);
			icalcomponent_free (vfb);
			g_free (address);
			g_free (name);
		}
	} else {
		for (l = users; l != NULL; l = l->next ) {
			address = l->data;
			if (e_cal_backend_mail_account_is_valid (registry, address, &name)) {
				vfb = create_user_free_busy (cbfile, address, name, start, end);
				calobj = icalcomponent_as_ical_string_r (vfb);
				*freebusy = g_slist_append (*freebusy, calobj);
				icalcomponent_free (vfb);
				g_free (name);
			}
		}
	}

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

static void
sanitize_component (ECalBackendFile *cbfile,
                    ECalComponent *comp)
{
	ECalComponentDateTime dt;
	icaltimezone *zone;

	/* Check dtstart, dtend and due's timezone, and convert it to local
	 * default timezone if the timezone is not in our builtin timezone
	 * list */
	e_cal_component_get_dtstart (comp, &dt);
	if (dt.value && dt.tzid) {
		zone = e_timezone_cache_get_timezone (
			E_TIMEZONE_CACHE (cbfile), dt.tzid);
		if (!zone) {
			g_free ((gchar *) dt.tzid);
			dt.tzid = g_strdup ("UTC");
			e_cal_component_set_dtstart (comp, &dt);
		}
	}
	e_cal_component_free_datetime (&dt);

	e_cal_component_get_dtend (comp, &dt);
	if (dt.value && dt.tzid) {
		zone = e_timezone_cache_get_timezone (
			E_TIMEZONE_CACHE (cbfile), dt.tzid);
		if (!zone) {
			g_free ((gchar *) dt.tzid);
			dt.tzid = g_strdup ("UTC");
			e_cal_component_set_dtend (comp, &dt);
		}
	}
	e_cal_component_free_datetime (&dt);

	e_cal_component_get_due (comp, &dt);
	if (dt.value && dt.tzid) {
		zone = e_timezone_cache_get_timezone (
			E_TIMEZONE_CACHE (cbfile), dt.tzid);
		if (!zone) {
			g_free ((gchar *) dt.tzid);
			dt.tzid = g_strdup ("UTC");
			e_cal_component_set_due (comp, &dt);
		}
	}
	e_cal_component_free_datetime (&dt);
	e_cal_component_abort_sequence (comp);

}

static void
e_cal_backend_file_create_objects (ECalBackendSync *backend,
                                   EDataCal *cal,
                                   GCancellable *cancellable,
                                   const GSList *in_calobjs,
                                   GSList **uids,
                                   GSList **new_components,
                                   GError **error)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	GSList *icalcomps = NULL;
	const GSList *l;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR));
		return;
	}

	if (uids)
		*uids = NULL;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	/* First step, parse input strings and do uid verification: may fail */
	for (l = in_calobjs; l; l = l->next) {
		icalcomponent *icalcomp;
		const gchar *comp_uid;

		/* Parse the icalendar text */
		icalcomp = icalparser_parse_string ((gchar *) l->data);
		if (!icalcomp) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (InvalidObject));
			return;
		}

		/* Append icalcomponent to icalcomps */
		icalcomps = g_slist_prepend (icalcomps, icalcomp);

		/* Check kind with the parent */
		if (icalcomponent_isa (icalcomp) != e_cal_backend_get_kind (E_CAL_BACKEND (backend))) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (InvalidObject));
			return;
		}

		/* Get the UID */
		comp_uid = icalcomponent_get_uid (icalcomp);
		if (!comp_uid) {
			gchar *new_uid;

			new_uid = e_util_generate_uid ();
			if (!new_uid) {
				g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
				g_rec_mutex_unlock (&priv->idle_save_rmutex);
				g_propagate_error (error, EDC_ERROR (InvalidObject));
				return;
			}

			icalcomponent_set_uid (icalcomp, new_uid);
			comp_uid = icalcomponent_get_uid (icalcomp);

			g_free (new_uid);
		}

		/* check that the object is not in our cache */
		if (uid_in_use (cbfile, comp_uid)) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (ObjectIdAlreadyExists));
			return;
		}
	}

	icalcomps = g_slist_reverse (icalcomps);

	/* Second step, add the objects */
	for (l = icalcomps; l; l = l->next) {
		ECalComponent *comp;
		struct icaltimetype current;
		icalcomponent *icalcomp = l->data;

		/* Create the cal component */
		comp = e_cal_component_new ();
		e_cal_component_set_icalcomponent (comp, icalcomp);

		/* Set the created and last modified times on the component, if not there already */
		current = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());

		if (!icalcomponent_get_first_property (icalcomp, ICAL_CREATED_PROPERTY)) {
			/* Update both when CREATED is missing, to make sure the LAST-MODIFIED
			   is not before CREATED */
			e_cal_component_set_created (comp, &current);
			e_cal_component_set_last_modified (comp, &current);
		} else if (!icalcomponent_get_first_property (icalcomp, ICAL_LASTMODIFIED_PROPERTY)) {
			e_cal_component_set_last_modified (comp, &current);
		}

		/* sanitize the component*/
		sanitize_component (cbfile, comp);

		/* Add the object */
		add_component (cbfile, comp, TRUE);

		/* Keep the UID and the modified component to return them later */
		if (uids)
			*uids = g_slist_prepend (*uids, g_strdup (icalcomponent_get_uid (icalcomp)));

		*new_components = g_slist_prepend (*new_components, e_cal_component_clone (comp));
	}

	g_slist_free (icalcomps);

	/* Save the file */
	save (cbfile, TRUE);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	if (uids)
		*uids = g_slist_reverse (*uids);

	*new_components = g_slist_reverse (*new_components);
}

typedef struct {
	ECalBackendFile *cbfile;
	ECalBackendFileObject *obj_data;
	const gchar *rid;
	ECalObjModType mod;
} RemoveRecurrenceData;

static gboolean
remove_object_instance_cb (gpointer key,
                           gpointer value,
                           gpointer user_data)
{
	time_t fromtt, instancett;
	ECalComponent *instance = value;
	RemoveRecurrenceData *rrdata = user_data;

	fromtt = icaltime_as_timet (icaltime_from_string (rrdata->rid));
	instancett = icaltime_as_timet (get_rid_icaltime (instance));

	if (fromtt > 0 && instancett > 0) {
		if ((rrdata->mod == E_CAL_OBJ_MOD_THIS_AND_PRIOR && instancett <= fromtt) ||
		    (rrdata->mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE && instancett >= fromtt)) {
			/* remove the component from our data */
			icalcomponent_remove_component (
				rrdata->cbfile->priv->icalcomp,
				e_cal_component_get_icalcomponent (instance));
			rrdata->cbfile->priv->comp = g_list_remove (rrdata->cbfile->priv->comp, instance);

			rrdata->obj_data->recurrences_list = g_list_remove (rrdata->obj_data->recurrences_list, instance);

			return TRUE;
		}
	}

	return FALSE;
}

static void
e_cal_backend_file_modify_objects (ECalBackendSync *backend,
                                   EDataCal *cal,
                                   GCancellable *cancellable,
                                   const GSList *calobjs,
                                   ECalObjModType mod,
                                   GSList **old_components,
                                   GSList **new_components,
                                   GError **error)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	GSList *icalcomps = NULL;
	const GSList *l;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR));
		return;
	}

	switch (mod) {
	case E_CAL_OBJ_MOD_THIS:
	case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
	case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
	case E_CAL_OBJ_MOD_ALL:
		break;
	default:
		g_propagate_error (error, EDC_ERROR (NotSupported));
		return;
	}

	if (old_components)
		*old_components = NULL;
	if (new_components)
		*new_components = NULL;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	/* First step, parse input strings and do uid verification: may fail */
	for (l = calobjs; l; l = l->next) {
		const gchar *comp_uid;
		icalcomponent *icalcomp;

		/* Parse the icalendar text */
		icalcomp = icalparser_parse_string (l->data);
		if (!icalcomp) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (InvalidObject));
			return;
		}

		icalcomps = g_slist_prepend (icalcomps, icalcomp);

		/* Check kind with the parent */
		if (icalcomponent_isa (icalcomp) != e_cal_backend_get_kind (E_CAL_BACKEND (backend))) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (InvalidObject));
			return;
		}

		/* Get the uid */
		comp_uid = icalcomponent_get_uid (icalcomp);

		/* Get the object from our cache */
		if (!g_hash_table_lookup (priv->comp_uid_hash, comp_uid)) {
			g_slist_free_full (icalcomps, (GDestroyNotify) icalcomponent_free);
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return;
		}
	}

	icalcomps = g_slist_reverse (icalcomps);

	/* Second step, update the objects */
	for (l = icalcomps; l; l = l->next) {
		struct icaltimetype current;
		RemoveRecurrenceData rrdata;
		GList *detached = NULL;
		gchar *rid = NULL;
		gchar *real_rid;
		const gchar *comp_uid;
		icalcomponent * icalcomp = l->data, *split_icalcomp = NULL;
		ECalComponent *comp, *recurrence;
		ECalBackendFileObject *obj_data;

		comp_uid = icalcomponent_get_uid (icalcomp);
		obj_data = g_hash_table_lookup (priv->comp_uid_hash, comp_uid);

		/* Create the cal component */
		comp = e_cal_component_new ();
		e_cal_component_set_icalcomponent (comp, icalcomp);

		/* Set the last modified time on the component */
		current = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());
		e_cal_component_set_last_modified (comp, &current);

		/* sanitize the component*/
		sanitize_component (cbfile, comp);
		rid = e_cal_component_get_recurid_as_string (comp);

		/* handle mod_type */
		switch (mod) {
		case E_CAL_OBJ_MOD_THIS:
			if (!rid || !*rid) {
				if (old_components)
					*old_components = g_slist_prepend (*old_components, obj_data->full_object ? e_cal_component_clone (obj_data->full_object) : NULL);

				/* replace only the full object */
				if (obj_data->full_object) {
					icalcomponent_remove_component (
						priv->icalcomp,
						e_cal_component_get_icalcomponent (obj_data->full_object));
					priv->comp = g_list_remove (priv->comp, obj_data->full_object);

					g_object_unref (obj_data->full_object);
				}

				/* add the new object */
				obj_data->full_object = comp;

				e_cal_recur_ensure_end_dates (comp, TRUE, resolve_tzid, priv->icalcomp);

				if (!remove_component_from_intervaltree (cbfile, comp)) {
					g_message (G_STRLOC " Could not remove component from interval tree!");
				}

				add_component_to_intervaltree (cbfile, comp);

				icalcomponent_add_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (obj_data->full_object));
				priv->comp = g_list_prepend (priv->comp, obj_data->full_object);
				break;
			}

			if (g_hash_table_lookup_extended (obj_data->recurrences, rid, (gpointer *) &real_rid, (gpointer *) &recurrence)) {
				if (old_components)
					*old_components = g_slist_prepend (*old_components, e_cal_component_clone (recurrence));

				/* remove the component from our data */
				icalcomponent_remove_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (recurrence));
				priv->comp = g_list_remove (priv->comp, recurrence);
				obj_data->recurrences_list = g_list_remove (obj_data->recurrences_list, recurrence);
				g_hash_table_remove (obj_data->recurrences, rid);
			} else {
				if (old_components)
					*old_components = g_slist_prepend (*old_components, NULL);
			}

			/* add the detached instance */
			g_hash_table_insert (
				obj_data->recurrences,
				g_strdup (rid),
				comp);
			icalcomponent_add_component (
				priv->icalcomp,
				e_cal_component_get_icalcomponent (comp));
			priv->comp = g_list_append (priv->comp, comp);
			obj_data->recurrences_list = g_list_append (obj_data->recurrences_list, comp);
			break;
		case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
		case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
			if (!rid || !*rid)
				goto like_mod_all;

			/* remove the component from our data, temporarily */
			if (obj_data->full_object) {
				if (mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE &&
				    e_cal_util_is_first_instance (obj_data->full_object, icalcomponent_get_recurrenceid (icalcomp), resolve_tzid, priv->icalcomp)) {
					icalproperty *prop = icalcomponent_get_first_property (icalcomp, ICAL_RECURRENCEID_PROPERTY);

					if (prop)
						icalcomponent_remove_property (icalcomp, prop);

					e_cal_component_rescan (comp);

					goto like_mod_all;
				}

				icalcomponent_remove_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (obj_data->full_object));
				priv->comp = g_list_remove (priv->comp, obj_data->full_object);
			}

			/* now deal with the detached recurrence */
			if (g_hash_table_lookup_extended (obj_data->recurrences, rid,
							  (gpointer *) &real_rid, (gpointer *) &recurrence)) {
				if (old_components)
					*old_components = g_slist_prepend (*old_components, e_cal_component_clone (recurrence));

				/* remove the component from our data */
				icalcomponent_remove_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (recurrence));
				priv->comp = g_list_remove (priv->comp, recurrence);
				obj_data->recurrences_list = g_list_remove (obj_data->recurrences_list, recurrence);
				g_hash_table_remove (obj_data->recurrences, rid);
			} else {
				if (*old_components)
					*old_components = g_slist_prepend (*old_components, obj_data->full_object ? e_cal_component_clone (obj_data->full_object) : NULL);
			}

			rrdata.cbfile = cbfile;
			rrdata.obj_data = obj_data;
			rrdata.rid = rid;
			rrdata.mod = mod;
			g_hash_table_foreach_remove (obj_data->recurrences, (GHRFunc) remove_object_instance_cb, &rrdata);

			/* add the modified object to the beginning of the list,
			 * so that it's always before any detached instance we
			 * might have */
			if (obj_data->full_object) {
				struct icaltimetype rid_struct = icalcomponent_get_recurrenceid (icalcomp), master_dtstart;
				icalcomponent *master_icalcomp = e_cal_component_get_icalcomponent (obj_data->full_object);
				icalproperty *prop = icalcomponent_get_first_property (icalcomp, ICAL_RECURRENCEID_PROPERTY);

				if (prop)
					icalcomponent_remove_property (icalcomp, prop);

				master_dtstart = icalcomponent_get_dtstart (master_icalcomp);
				if (master_dtstart.zone && master_dtstart.zone != rid_struct.zone)
					rid_struct = icaltime_convert_to_zone (rid_struct, (icaltimezone *) master_dtstart.zone);
				split_icalcomp = e_cal_util_split_at_instance (icalcomp, rid_struct, master_dtstart);
				if (split_icalcomp) {
					ECalComponent *prev_comp;
					prev_comp = e_cal_component_clone (obj_data->full_object);

					rid_struct = icaltime_convert_to_zone (rid_struct, icaltimezone_get_utc_timezone ());
					e_cal_util_remove_instances (e_cal_component_get_icalcomponent (obj_data->full_object), rid_struct, mod);
					e_cal_component_rescan (obj_data->full_object);
					e_cal_recur_ensure_end_dates (obj_data->full_object, TRUE, resolve_tzid, priv->icalcomp);

					e_cal_backend_notify_component_modified (E_CAL_BACKEND (backend), prev_comp, obj_data->full_object);

					g_clear_object (&prev_comp);
				}

				icalcomponent_add_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (obj_data->full_object));
				priv->comp = g_list_prepend (priv->comp, obj_data->full_object);
			} else {
				struct icaltimetype rid_struct = icalcomponent_get_recurrenceid (icalcomp);

				split_icalcomp = e_cal_util_split_at_instance (icalcomp, rid_struct, icaltime_null_time ());
			}

			if (split_icalcomp) {
				gchar *new_uid;

				new_uid = e_util_generate_uid ();
				icalcomponent_set_uid (split_icalcomp, new_uid);
				g_free (new_uid);

				g_warn_if_fail (e_cal_component_set_icalcomponent (comp, split_icalcomp));
				e_cal_recur_ensure_end_dates (comp, TRUE, resolve_tzid, priv->icalcomp);

				/* sanitize the component */
				sanitize_component (cbfile, comp);

				/* Add the object */
				add_component (cbfile, comp, TRUE);
			}
			break;
		case E_CAL_OBJ_MOD_ALL :
 like_mod_all:
			/* Remove the old version */
			if (old_components)
				*old_components = g_slist_prepend (*old_components, obj_data->full_object ? e_cal_component_clone (obj_data->full_object) : NULL);

			if (obj_data->recurrences_list) {
				/* has detached components, preserve them */
				GList *ll;

				for (ll = obj_data->recurrences_list; ll; ll = ll->next) {
					detached = g_list_prepend (detached, g_object_ref (ll->data));
				}
			}

			remove_component (cbfile, comp_uid, obj_data);

			e_cal_recur_ensure_end_dates (comp, TRUE, resolve_tzid, priv->icalcomp);

			/* Add the new object */
			add_component (cbfile, comp, TRUE);

			if (detached) {
				/* it had some detached components, place them back */
				comp_uid = icalcomponent_get_uid (e_cal_component_get_icalcomponent (comp));

				if ((obj_data = g_hash_table_lookup (priv->comp_uid_hash, comp_uid)) != NULL) {
					GList *ll;

					for (ll = detached; ll; ll = ll->next) {
						ECalComponent *c = ll->data;

						g_hash_table_insert (obj_data->recurrences, e_cal_component_get_recurid_as_string (c), c);
						icalcomponent_add_component (priv->icalcomp, e_cal_component_get_icalcomponent (c));
						priv->comp = g_list_append (priv->comp, c);
						obj_data->recurrences_list = g_list_append (obj_data->recurrences_list, c);
					}
				}

				g_list_free (detached);
			}
			break;
		/* coverity[dead_error_begin] */
		case E_CAL_OBJ_MOD_ONLY_THIS:
			/* not reached, keep compiler happy */
			g_warn_if_reached ();
			break;
		}

		g_free (rid);

		if (new_components) {
			*new_components = g_slist_prepend (*new_components, e_cal_component_clone (comp));
		}
	}

	g_slist_free (icalcomps);

	/* All the components were updated, now we save the file */
	save (cbfile, TRUE);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	if (old_components)
		*old_components = g_slist_reverse (*old_components);

	if (new_components)
		*new_components = g_slist_reverse (*new_components);
}

/**
 * Remove one and only one instance. The object may be empty
 * afterwards, in which case it will be removed completely.
 *
 * @mod    E_CAL_OBJ_MOD_THIS or E_CAL_OBJ_MOD_ONLY_THIS: the later only
 *         removes the instance, the former also adds an EXDATE if rid is set
 *         TODO: E_CAL_OBJ_MOD_ONLY_THIS
 * @uid    pointer to UID which must remain valid even if the object gets
 *         removed
 * @rid    NULL, "", or non-empty string when manipulating a specific recurrence;
 *         also must remain valid
 * @error  may be NULL if caller is not interested in errors
 * @return modified object or NULL if it got removed
 */
static ECalBackendFileObject *
remove_instance (ECalBackendFile *cbfile,
                 ECalBackendFileObject *obj_data,
                 const gchar *uid,
                 const gchar *rid,
                 ECalObjModType mod,
                 ECalComponent **old_comp,
                 ECalComponent **new_comp,
                 GError **error)
{
	gchar *hash_rid;
	ECalComponent *comp;
	struct icaltimetype current;

	/* only check for non-NULL below, empty string is detected here */
	if (rid && !*rid)
		rid = NULL;

	if (rid) {
		struct icaltimetype rid_struct;

		/* remove recurrence */
		if (g_hash_table_lookup_extended (obj_data->recurrences, rid,
						  (gpointer *) &hash_rid, (gpointer *) &comp)) {
			/* Removing without parent or not modifying parent?
			 * Report removal to caller. */
			if (old_comp &&
			    (!obj_data->full_object || mod == E_CAL_OBJ_MOD_ONLY_THIS)) {
				*old_comp = e_cal_component_clone (comp);
			}

			/* Reporting parent modification to caller?
			 * Report directly instead of going via caller. */
			if (obj_data->full_object &&
			    mod != E_CAL_OBJ_MOD_ONLY_THIS) {
				/* old object string not provided,
				 * instead rely on the view detecting
				 * whether it contains the id */
				ECalComponentId id;
				id.uid = (gchar *) uid;
				id.rid = (gchar *) rid;
				e_cal_backend_notify_component_removed (E_CAL_BACKEND (cbfile), &id, NULL, NULL);
			}

			/* remove the component from our data */
			icalcomponent_remove_component (
				cbfile->priv->icalcomp,
				e_cal_component_get_icalcomponent (comp));
			cbfile->priv->comp = g_list_remove (cbfile->priv->comp, comp);
			obj_data->recurrences_list = g_list_remove (obj_data->recurrences_list, comp);
			g_hash_table_remove (obj_data->recurrences, rid);
		} else if (mod == E_CAL_OBJ_MOD_ONLY_THIS) {
			if (error)
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return obj_data;
		} else {
			/* not an error, only add EXDATE */
		}
		/* component empty? */
		if (!obj_data->full_object) {
			if (!obj_data->recurrences_list) {
				/* empty now, remove it */
				remove_component (cbfile, uid, obj_data);
				return NULL;
			} else {
				return obj_data;
			}
		}

		/* avoid modifying parent? */
		if (mod == E_CAL_OBJ_MOD_ONLY_THIS)
			return obj_data;

		/* remove the main component from our data before modifying it */
		icalcomponent_remove_component (
			cbfile->priv->icalcomp,
			e_cal_component_get_icalcomponent (obj_data->full_object));
		cbfile->priv->comp = g_list_remove (cbfile->priv->comp, obj_data->full_object);

		/* add EXDATE or EXRULE to parent, report as update */
		if (old_comp) {
			*old_comp = e_cal_component_clone (obj_data->full_object);
		}

		rid_struct = icaltime_from_string (rid);
		if (!rid_struct.zone) {
			struct icaltimetype master_dtstart = icalcomponent_get_dtstart (e_cal_component_get_icalcomponent (obj_data->full_object));
			if (master_dtstart.zone && master_dtstart.zone != rid_struct.zone)
				rid_struct = icaltime_convert_to_zone (rid_struct, (icaltimezone *) master_dtstart.zone);
			rid_struct = icaltime_convert_to_zone (rid_struct, icaltimezone_get_utc_timezone ());
		}

		e_cal_util_remove_instances (
			e_cal_component_get_icalcomponent (obj_data->full_object),
			rid_struct, E_CAL_OBJ_MOD_THIS);

		/* Since we are only removing one instance of recurrence
		 * event, update the last modified time on the component */
		current = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());
		e_cal_component_set_last_modified (obj_data->full_object, &current);

		/* report update */
		if (new_comp) {
			*new_comp = e_cal_component_clone (obj_data->full_object);
		}

		/* add the modified object to the beginning of the list,
		 * so that it's always before any detached instance we
		 * might have */
		icalcomponent_add_component (
			cbfile->priv->icalcomp,
			e_cal_component_get_icalcomponent (obj_data->full_object));
		cbfile->priv->comp = g_list_prepend (cbfile->priv->comp, obj_data->full_object);
	} else {
		if (!obj_data->full_object) {
			/* Nothing to do, parent doesn't exist. Tell
			 * caller about this? Not an error with
			 * E_CAL_OBJ_MOD_THIS. */
			if (mod == E_CAL_OBJ_MOD_ONLY_THIS && error)
				g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return obj_data;
		}

		/* remove the main component from our data before deleting it */
		if (!remove_component_from_intervaltree (cbfile, obj_data->full_object)) {
			/* return without changing anything */
			g_message (G_STRLOC " Could not remove component from interval tree!");
			return obj_data;
		}
		icalcomponent_remove_component (
			cbfile->priv->icalcomp,
			e_cal_component_get_icalcomponent (obj_data->full_object));
		cbfile->priv->comp = g_list_remove (cbfile->priv->comp, obj_data->full_object);

		/* remove parent, report as removal */
		if (old_comp) {
			*old_comp = g_object_ref (obj_data->full_object);
		}
		g_object_unref (obj_data->full_object);
		obj_data->full_object = NULL;

		/* component may be empty now, check that */
		if (!obj_data->recurrences_list) {
			remove_component (cbfile, uid, obj_data);
			return NULL;
		}
	}

	/* component still exists in a modified form */
	return obj_data;
}

static ECalComponent *
clone_ecalcomp_from_fileobject (ECalBackendFileObject *obj_data,
                                const gchar *rid)
{
	ECalComponent *comp = obj_data->full_object;
	gchar         *real_rid;

	if (!comp)
		return NULL;

	if (rid) {
		if (!g_hash_table_lookup_extended (obj_data->recurrences, rid,
						  (gpointer *) &real_rid, (gpointer *) &comp)) {
			/* FIXME remove this once we delete an instance from master object through
			 * modify request by setting exception */
			comp = obj_data->full_object;
		}
	}

	return comp ? e_cal_component_clone (comp) : NULL;
}

static void
notify_comp_removed_cb (gpointer pecalcomp,
                        gpointer pbackend)
{
	ECalComponent *comp = pecalcomp;
	ECalBackend *backend = pbackend;
	ECalComponentId *id;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (backend != NULL);

	id = e_cal_component_get_id (comp);
	g_return_if_fail (id != NULL);

	e_cal_backend_notify_component_removed (backend, id, comp, NULL);

	e_cal_component_free_id (id);
}

/* Remove_object handler for the file backend */
static void
e_cal_backend_file_remove_objects (ECalBackendSync *backend,
                                   EDataCal *cal,
                                   GCancellable *cancellable,
                                   const GSList *ids,
                                   ECalObjModType mod,
                                   GSList **old_components,
                                   GSList **new_components,
                                   GError **error)
{
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	const GSList *l;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR));
		return;
	}

	switch (mod) {
	case E_CAL_OBJ_MOD_THIS:
	case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
	case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
	case E_CAL_OBJ_MOD_ONLY_THIS:
	case E_CAL_OBJ_MOD_ALL:
		break;
	default:
		g_propagate_error (error, EDC_ERROR (NotSupported));
		return;
	}

	*old_components = *new_components = NULL;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	/* First step, validate the input */
	for (l = ids; l; l = l->next) {
		ECalComponentId *id = l->data;
				/* Make the ID contains a uid */
		if (!id || !id->uid) {
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return;
		}
				/* Check that it has a recurrence id if mod is E_CAL_OBJ_MOD_THIS_AND_PRIOR
					 or E_CAL_OBJ_MOD_THIS_AND_FUTURE */
		if ((mod == E_CAL_OBJ_MOD_THIS_AND_PRIOR || mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE) &&
			(!id->rid || !*(id->rid))) {
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return;
		}
				/* Make sure the uid exists in the local hash table */
		if (!g_hash_table_lookup (priv->comp_uid_hash, id->uid)) {
			g_rec_mutex_unlock (&priv->idle_save_rmutex);
			g_propagate_error (error, EDC_ERROR (ObjectNotFound));
			return;
		}
	}

	/* Second step, remove objects from the calendar */
	for (l = ids; l; l = l->next) {
		const gchar *recur_id = NULL;
		ECalComponent *comp;
		RemoveRecurrenceData rrdata;
		ECalBackendFileObject *obj_data;
		ECalComponentId *id = l->data;

		obj_data = g_hash_table_lookup (priv->comp_uid_hash, id->uid);

		if (id->rid && *(id->rid))
			recur_id = id->rid;

		switch (mod) {
		case E_CAL_OBJ_MOD_ALL :
			*old_components = g_slist_prepend (*old_components, clone_ecalcomp_from_fileobject (obj_data, recur_id));
			*new_components = g_slist_prepend (*new_components, NULL);

			if (obj_data->recurrences_list)
				g_list_foreach (obj_data->recurrences_list, notify_comp_removed_cb, cbfile);
			remove_component (cbfile, id->uid, obj_data);
			break;
		case E_CAL_OBJ_MOD_ONLY_THIS:
		case E_CAL_OBJ_MOD_THIS: {
			ECalComponent *old_component = NULL;
			ECalComponent *new_component = NULL;

			remove_instance (
				cbfile, obj_data, id->uid, recur_id, mod,
				&old_component, &new_component, error);

			*old_components = g_slist_prepend (*old_components, old_component);
			*new_components = g_slist_prepend (*new_components, new_component);
			break;
		}
		case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
		case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
			comp = obj_data->full_object;

			if (comp) {
				struct icaltimetype rid_struct;

				*old_components = g_slist_prepend (*old_components, e_cal_component_clone (comp));

				/* remove the component from our data, temporarily */
				icalcomponent_remove_component (
					priv->icalcomp,
					e_cal_component_get_icalcomponent (comp));
				priv->comp = g_list_remove (priv->comp, comp);

				rid_struct = icaltime_from_string (recur_id);
				if (!rid_struct.zone) {
					struct icaltimetype master_dtstart = icalcomponent_get_dtstart (e_cal_component_get_icalcomponent (comp));
					if (master_dtstart.zone && master_dtstart.zone != rid_struct.zone)
						rid_struct = icaltime_convert_to_zone (rid_struct, (icaltimezone *) master_dtstart.zone);
					rid_struct = icaltime_convert_to_zone (rid_struct, icaltimezone_get_utc_timezone ());
				}
				e_cal_util_remove_instances (
					e_cal_component_get_icalcomponent (comp),
					rid_struct, mod);
			} else {
				*old_components = g_slist_prepend (*old_components, NULL);
			}

			/* now remove all detached instances */
			rrdata.cbfile = cbfile;
			rrdata.obj_data = obj_data;
			rrdata.rid = recur_id;
			rrdata.mod = mod;
			g_hash_table_foreach_remove (obj_data->recurrences, (GHRFunc) remove_object_instance_cb, &rrdata);

			/* add the modified object to the beginning of the list,
			 * so that it's always before any detached instance we
			 * might have */
			if (comp)
				priv->comp = g_list_prepend (priv->comp, comp);

			if (obj_data->full_object) {
				*new_components = g_slist_prepend (*new_components, e_cal_component_clone (obj_data->full_object));
			} else {
				*new_components = g_slist_prepend (*new_components, NULL);
			}
			break;
		}
	}

	save (cbfile, TRUE);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	*old_components = g_slist_reverse (*old_components);
	*new_components = g_slist_reverse (*new_components);
}

static gboolean
cancel_received_object (ECalBackendFile *cbfile,
                        ECalComponent *comp,
                        ECalComponent **old_comp,
                        ECalComponent **new_comp)
{
	ECalBackendFileObject *obj_data;
	ECalBackendFilePrivate *priv;
	gchar *rid;
	const gchar *uid = NULL;

	priv = cbfile->priv;

	*old_comp = NULL;
	*new_comp = NULL;

	e_cal_component_get_uid (comp, &uid);

	/* Find the old version of the component. */
	obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
	if (!obj_data)
		return FALSE;

	/* And remove it */
	rid = e_cal_component_get_recurid_as_string (comp);
	if (rid && *rid) {
		obj_data = remove_instance (
			cbfile, obj_data, uid, rid, E_CAL_OBJ_MOD_THIS,
			old_comp, new_comp, NULL);
		if (obj_data && obj_data->full_object && !*new_comp) {
			*new_comp = e_cal_component_clone (obj_data->full_object);
		}
	} else {
		/* report as removal by keeping *new_component NULL */
		if (obj_data->full_object) {
			*old_comp = e_cal_component_clone (obj_data->full_object);
		}
		remove_component (cbfile, uid, obj_data);
	}

	g_free (rid);

	return TRUE;
}

typedef struct {
	GHashTable *zones;

	gboolean found;
} ECalBackendFileTzidData;

static void
check_tzids (icalparameter *param,
             gpointer data)
{
	ECalBackendFileTzidData *tzdata = data;
	const gchar *tzid;

	tzid = icalparameter_get_tzid (param);
	if (!tzid || g_hash_table_lookup (tzdata->zones, tzid))
		tzdata->found = FALSE;
}

/* This function is largely duplicated in
 * ../groupwise/e-cal-backend-groupwise.c
 */
static void
fetch_attachments (ECalBackendSync *backend,
                   ECalComponent *comp)
{
	GSList *attach_list = NULL, *new_attach_list = NULL;
	GSList *l;
	gchar *dest_url, *dest_file;
	gint fd, fileindex;
	const gchar *uid;

	e_cal_component_get_attachment_list (comp, &attach_list);
	e_cal_component_get_uid (comp, &uid);

	for (l = attach_list, fileindex = 0; l; l = l->next, fileindex++) {
		gchar *sfname = g_filename_from_uri ((const gchar *) l->data, NULL, NULL);
		gchar *filename;
		GMappedFile *mapped_file;
		GError *error = NULL;

		if (!sfname)
			continue;

		mapped_file = g_mapped_file_new (sfname, FALSE, &error);
		if (!mapped_file) {
			g_message (
				"DEBUG: could not map %s: %s\n",
				sfname, error ? error->message : "???");
			g_error_free (error);
			g_free (sfname);
			continue;
		}
		filename = g_path_get_basename (sfname);
		dest_file = e_cal_backend_create_cache_filename (E_CAL_BACKEND (backend), uid, filename, fileindex);
		g_free (filename);
		fd = g_open (dest_file, O_RDWR | O_CREAT | O_TRUNC | O_BINARY, 0600);
		if (fd == -1) {
			/* TODO handle error conditions */
			g_message (
				"DEBUG: could not open %s for writing\n",
				dest_file);
		} else if (write (fd, g_mapped_file_get_contents (mapped_file),
				  g_mapped_file_get_length (mapped_file)) == -1) {
			/* TODO handle error condition */
			g_message ("DEBUG: attachment write failed.\n");
		}

		g_mapped_file_unref (mapped_file);

		if (fd != -1)
			close (fd);
		dest_url = g_filename_to_uri (dest_file, NULL, NULL);
		g_free (dest_file);
		new_attach_list = g_slist_append (new_attach_list, dest_url);
		g_free (sfname);
	}

	e_cal_component_set_attachment_list (comp, new_attach_list);
}

static gint
masters_first_cmp (gconstpointer ptr1,
		   gconstpointer ptr2)
{
	icalcomponent *icomp1 = (icalcomponent *) ptr1;
	icalcomponent *icomp2 = (icalcomponent *) ptr2;
	gboolean has_rid1, has_rid2;

	has_rid1 = (icomp1 && icalcomponent_get_first_property (icomp1, ICAL_RECURRENCEID_PROPERTY)) ? 1 : 0;
	has_rid2 = (icomp2 && icalcomponent_get_first_property (icomp2, ICAL_RECURRENCEID_PROPERTY)) ? 1 : 0;

	if (has_rid1 == has_rid2)
		return g_strcmp0 (icomp1 ? icalcomponent_get_uid (icomp1) : NULL,
				  icomp2 ? icalcomponent_get_uid (icomp2) : NULL);

	if (has_rid1)
		return 1;

	return -1;
}

/* Update_objects handler for the file backend. */
static void
e_cal_backend_file_receive_objects (ECalBackendSync *backend,
                                    EDataCal *cal,
                                    GCancellable *cancellable,
                                    const gchar *calobj,
                                    GError **error)
{
	ESourceRegistry *registry;
	ECalBackendFile *cbfile;
	ECalBackendFilePrivate *priv;
	icalcomponent *toplevel_comp, *icalcomp = NULL;
	icalcomponent_kind kind;
	icalproperty_method toplevel_method, method;
	icalcomponent *subcomp;
	GList *comps, *del_comps, *l;
	ECalComponent *comp;
	struct icaltimetype current;
	ECalBackendFileTzidData tzdata;
	GError *err = NULL;

	cbfile = E_CAL_BACKEND_FILE (backend);
	priv = cbfile->priv;

	if (priv->icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR));
		return;
	}

	/* Pull the component from the string and ensure that it is sane */
	toplevel_comp = icalparser_parse_string ((gchar *) calobj);
	if (!toplevel_comp) {
		g_propagate_error (error, EDC_ERROR (InvalidObject));
		return;
	}

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	registry = e_cal_backend_get_registry (E_CAL_BACKEND (backend));

	kind = icalcomponent_isa (toplevel_comp);
	if (kind != ICAL_VCALENDAR_COMPONENT) {
		/* If its not a VCALENDAR, make it one to simplify below */
		icalcomp = toplevel_comp;
		toplevel_comp = e_cal_util_new_top_level ();
		if (icalcomponent_get_method (icalcomp) == ICAL_METHOD_CANCEL)
			icalcomponent_set_method (toplevel_comp, ICAL_METHOD_CANCEL);
		else
			icalcomponent_set_method (toplevel_comp, ICAL_METHOD_PUBLISH);
		icalcomponent_add_component (toplevel_comp, icalcomp);
	} else {
		if (!icalcomponent_get_first_property (toplevel_comp, ICAL_METHOD_PROPERTY))
			icalcomponent_set_method (toplevel_comp, ICAL_METHOD_PUBLISH);
	}

	toplevel_method = icalcomponent_get_method (toplevel_comp);

	/* Build a list of timezones so we can make sure all the objects have valid info */
	tzdata.zones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

	subcomp = icalcomponent_get_first_component (toplevel_comp, ICAL_VTIMEZONE_COMPONENT);
	while (subcomp) {
		icaltimezone *zone;

		zone = icaltimezone_new ();
		if (icaltimezone_set_component (zone, subcomp))
			g_hash_table_insert (tzdata.zones, g_strdup (icaltimezone_get_tzid (zone)), NULL);

		subcomp = icalcomponent_get_next_component (toplevel_comp, ICAL_VTIMEZONE_COMPONENT);
	}

	/* First we make sure all the components are usuable */
	comps = del_comps = NULL;
	kind = e_cal_backend_get_kind (E_CAL_BACKEND (backend));

	subcomp = icalcomponent_get_first_component (toplevel_comp, ICAL_ANY_COMPONENT);
	while (subcomp) {
		icalcomponent_kind child_kind = icalcomponent_isa (subcomp);

		if (child_kind != kind) {
			/* remove the component from the toplevel VCALENDAR */
			if (child_kind != ICAL_VTIMEZONE_COMPONENT)
				del_comps = g_list_prepend (del_comps, subcomp);

			subcomp = icalcomponent_get_next_component (toplevel_comp, ICAL_ANY_COMPONENT);
			continue;
		}

		tzdata.found = TRUE;
		icalcomponent_foreach_tzid (subcomp, check_tzids, &tzdata);

		if (!tzdata.found) {
			err = EDC_ERROR (InvalidObject);
			goto error;
		}

		if (!icalcomponent_get_uid (subcomp)) {
			if (toplevel_method == ICAL_METHOD_PUBLISH) {

				gchar *new_uid = NULL;

				new_uid = e_util_generate_uid ();
				icalcomponent_set_uid (subcomp, new_uid);
				g_free (new_uid);
			} else {
				err = EDC_ERROR (InvalidObject);
				goto error;
			}

		}

		comps = g_list_prepend (comps, subcomp);
		subcomp = icalcomponent_get_next_component (toplevel_comp, ICAL_ANY_COMPONENT);
	}

	/* Now we remove the components we don't care about */
	for (l = del_comps; l; l = l->next) {
		subcomp = l->data;

		icalcomponent_remove_component (toplevel_comp, subcomp);
		icalcomponent_free (subcomp);
	}

	g_list_free (del_comps);

        /* check and patch timezones */
	if (!e_cal_client_check_timezones (toplevel_comp,
			       NULL,
			       e_cal_client_tzlookup_icomp,
			       priv->icalcomp,
			       NULL,
			       &err)) {
		/*
		 * This makes assumptions about what kind of
		 * errors can occur inside e_cal_check_timezones().
		 * We control it, so that should be safe, but
		 * is the code really identical with the calendar
		 * status?
		 */
		goto error;
	}

	/* Merge the iCalendar components with our existing VCALENDAR,
	 * resolving any conflicting TZIDs. */
	icalcomponent_merge_component (priv->icalcomp, toplevel_comp);

	/* Now we manipulate the components we care about */
	comps = g_list_sort (comps, masters_first_cmp);

	for (l = comps; l; l = l->next) {
		ECalComponent *old_component = NULL;
		ECalComponent *new_component = NULL;
		const gchar *uid;
		gchar *rid;
		ECalBackendFileObject *obj_data;
		gboolean is_declined;

		subcomp = l->data;

		/* Create the cal component */
		comp = e_cal_component_new ();
		e_cal_component_set_icalcomponent (comp, subcomp);

		/* Set the created and last modified times on the component, if not there already */
		current = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());

		if (!icalcomponent_get_first_property (icalcomp, ICAL_CREATED_PROPERTY)) {
			/* Update both when CREATED is missing, to make sure the LAST-MODIFIED
			   is not before CREATED */
			e_cal_component_set_created (comp, &current);
			e_cal_component_set_last_modified (comp, &current);
		} else if (!icalcomponent_get_first_property (icalcomp, ICAL_LASTMODIFIED_PROPERTY)) {
			e_cal_component_set_last_modified (comp, &current);
		}

		e_cal_component_get_uid (comp, &uid);
		rid = e_cal_component_get_recurid_as_string (comp);

		if (icalcomponent_get_first_property (subcomp, ICAL_METHOD_PROPERTY))
			method = icalcomponent_get_method (subcomp);
		else
			method = toplevel_method;

		switch (method) {
		case ICAL_METHOD_PUBLISH:
		case ICAL_METHOD_REQUEST:
		case ICAL_METHOD_REPLY:
			is_declined = e_cal_backend_user_declined (registry, subcomp);

			/* handle attachments */
			if (!is_declined && e_cal_component_has_attachments (comp))
				fetch_attachments (backend, comp);
			obj_data = g_hash_table_lookup (priv->comp_uid_hash, uid);
			if (obj_data) {

				if (rid) {
					ECalComponent *ignore_comp = NULL;

					remove_instance (
						cbfile, obj_data, uid, rid, E_CAL_OBJ_MOD_THIS,
						&old_component, &ignore_comp, NULL);

					if (ignore_comp)
						g_object_unref (ignore_comp);
				} else {
					if (obj_data->full_object) {
						old_component = e_cal_component_clone (obj_data->full_object);
					}
					remove_component (cbfile, uid, obj_data);
				}

				if (!is_declined)
					add_component (cbfile, comp, FALSE);

				if (!is_declined)
					e_cal_backend_notify_component_modified (E_CAL_BACKEND (backend),
										 old_component, comp);
				else {
					ECalComponentId *id = e_cal_component_get_id (comp);

					e_cal_backend_notify_component_removed (E_CAL_BACKEND (backend),
										id, old_component,
										rid ? comp : NULL);

					e_cal_component_free_id (id);
					g_object_unref (comp);
				}

				if (old_component)
					g_object_unref (old_component);

			} else if (!is_declined) {
				add_component (cbfile, comp, FALSE);

				e_cal_backend_notify_component_created (E_CAL_BACKEND (backend), comp);
			} else {
				g_object_unref (comp);
			}
			g_free (rid);
			break;
		case ICAL_METHOD_ADD:
			/* FIXME This should be doable once all the recurid stuff is done */
			err = EDC_ERROR (UnsupportedMethod);
			g_object_unref (comp);
			g_free (rid);
			goto error;
			break;
		case ICAL_METHOD_COUNTER:
			err = EDC_ERROR (UnsupportedMethod);
			g_object_unref (comp);
			g_free (rid);
			goto error;
			break;
		case ICAL_METHOD_DECLINECOUNTER:
			err = EDC_ERROR (UnsupportedMethod);
			g_object_unref (comp);
			g_free (rid);
			goto error;
			break;
		case ICAL_METHOD_CANCEL:
			if (cancel_received_object (cbfile, comp, &old_component, &new_component)) {
				ECalComponentId *id;

				id = e_cal_component_get_id (comp);

				e_cal_backend_notify_component_removed (E_CAL_BACKEND (backend),
									id, old_component, new_component);

				/* remove the component from the toplevel VCALENDAR */
				icalcomponent_remove_component (toplevel_comp, subcomp);
				icalcomponent_free (subcomp);
				e_cal_component_free_id (id);

				if (new_component)
					g_object_unref (new_component);
				if (old_component)
					g_object_unref (old_component);
			}
			g_object_unref (comp);
			g_free (rid);
			break;
		default:
			err = EDC_ERROR (UnsupportedMethod);
			g_object_unref (comp);
			g_free (rid);
			goto error;
		}
	}

	g_list_free (comps);

	save (cbfile, TRUE);

 error:
	g_hash_table_destroy (tzdata.zones);
	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	if (err)
		g_propagate_error (error, err);
}

static void
e_cal_backend_file_send_objects (ECalBackendSync *backend,
                                 EDataCal *cal,
                                 GCancellable *cancellable,
                                 const gchar *calobj,
                                 GSList **users,
                                 gchar **modified_calobj,
                                 GError **perror)
{
	*users = NULL;
	*modified_calobj = g_strdup (calobj);
}

static void
cal_backend_file_constructed (GObject *object)
{
	ECalBackend *backend;
	ESourceRegistry *registry;
	ESource *builtin_source;
	ESource *source;
	icalcomponent_kind kind;
	const gchar *user_data_dir;
	const gchar *component_type;
	const gchar *uid;
	gchar *filename;

	user_data_dir = e_get_user_data_dir ();

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_cal_backend_file_parent_class)->constructed (object);

	/* Override the cache directory that the parent class just set. */

	backend = E_CAL_BACKEND (object);
	kind = e_cal_backend_get_kind (backend);
	source = e_backend_get_source (E_BACKEND (backend));
	registry = e_cal_backend_get_registry (E_CAL_BACKEND (backend));

	uid = e_source_get_uid (source);
	g_return_if_fail (uid != NULL);

	switch (kind) {
		case ICAL_VEVENT_COMPONENT:
			component_type = "calendar";
			builtin_source = e_source_registry_ref_builtin_calendar (registry);
			break;
		case ICAL_VTODO_COMPONENT:
			component_type = "tasks";
			builtin_source = e_source_registry_ref_builtin_task_list (registry);
			break;
		case ICAL_VJOURNAL_COMPONENT:
			component_type = "memos";
			builtin_source = e_source_registry_ref_builtin_memo_list (registry);
			break;
		default:
			g_warn_if_reached ();
			component_type = "calendar";
			builtin_source = e_source_registry_ref_builtin_calendar (registry);
			break;
	}

	/* XXX Backward-compatibility hack:
	 *
	 * The special built-in "Personal" data source UIDs are now named
	 * "system-$COMPONENT" but since the data directories are already
	 * split out by component, we'll continue to use the old "system"
	 * directories for these particular data sources. */
	if (e_source_equal (source, builtin_source))
		uid = "system";

	filename = g_build_filename (user_data_dir, component_type, uid, NULL);
	e_cal_backend_set_cache_dir (backend, filename);
	g_free (filename);

	g_object_unref (builtin_source);
}

static void
cal_backend_file_add_cached_timezone (ETimezoneCache *cache,
                                      icaltimezone *zone)
{
	ECalBackendFilePrivate *priv;
	const gchar *tzid;
	gboolean timezone_added = FALSE;

	priv = E_CAL_BACKEND_FILE_GET_PRIVATE (cache);

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	tzid = icaltimezone_get_tzid (zone);
	if (icalcomponent_get_timezone (priv->icalcomp, tzid) == NULL) {
		icalcomponent *tz_comp;

		tz_comp = icaltimezone_get_component (zone);
		tz_comp = icalcomponent_new_clone (tz_comp);
		icalcomponent_add_component (priv->icalcomp, tz_comp);

		timezone_added = TRUE;
		save (E_CAL_BACKEND_FILE (cache), TRUE);
	}

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	/* Emit the signal outside of the mutex. */
	if (timezone_added)
		g_signal_emit_by_name (cache, "timezone-added", zone);
}

static icaltimezone *
cal_backend_file_get_cached_timezone (ETimezoneCache *cache,
                                      const gchar *tzid)
{
	ECalBackendFilePrivate *priv;
	icaltimezone *zone;

	priv = E_CAL_BACKEND_FILE_GET_PRIVATE (cache);

	g_rec_mutex_lock (&priv->idle_save_rmutex);
	zone = icalcomponent_get_timezone (priv->icalcomp, tzid);
	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	if (zone != NULL)
		return zone;

	/* Chain up and let ECalBackend try to match
	 * the TZID against a built-in icaltimezone. */
	return parent_timezone_cache_interface->get_timezone (cache, tzid);
}

static GList *
cal_backend_file_list_cached_timezones (ETimezoneCache *cache)
{
	/* XXX As of 3.7, the only e_timezone_cache_list_timezones()
	 *     call comes from ECalBackendStore, which this backend
	 *     does not use.  So we should never get here.  Emit a
	 *     runtime warning so we know if this changes. */

	g_return_val_if_reached (NULL);
}

static void
e_cal_backend_file_class_init (ECalBackendFileClass *class)
{
	GObjectClass *object_class;
	ECalBackendClass *backend_class;
	ECalBackendSyncClass *sync_class;

	g_type_class_add_private (class, sizeof (ECalBackendFilePrivate));

	object_class = (GObjectClass *) class;
	backend_class = (ECalBackendClass *) class;
	sync_class = (ECalBackendSyncClass *) class;

	object_class->dispose = e_cal_backend_file_dispose;
	object_class->finalize = e_cal_backend_file_finalize;
	object_class->constructed = cal_backend_file_constructed;

	backend_class->get_backend_property = e_cal_backend_file_get_backend_property;

	sync_class->open_sync = e_cal_backend_file_open;
	sync_class->create_objects_sync = e_cal_backend_file_create_objects;
	sync_class->modify_objects_sync = e_cal_backend_file_modify_objects;
	sync_class->remove_objects_sync = e_cal_backend_file_remove_objects;
	sync_class->receive_objects_sync = e_cal_backend_file_receive_objects;
	sync_class->send_objects_sync = e_cal_backend_file_send_objects;
	sync_class->get_object_sync = e_cal_backend_file_get_object;
	sync_class->get_object_list_sync = e_cal_backend_file_get_object_list;
	sync_class->get_attachment_uris_sync = e_cal_backend_file_get_attachment_uris;
	sync_class->add_timezone_sync = e_cal_backend_file_add_timezone;
	sync_class->get_free_busy_sync = e_cal_backend_file_get_free_busy;

	backend_class->start_view = e_cal_backend_file_start_view;

	/* Register our ESource extension. */
	E_TYPE_SOURCE_LOCAL;
}

static void
e_cal_backend_file_timezone_cache_init (ETimezoneCacheInterface *iface)
{
	parent_timezone_cache_interface = g_type_interface_peek_parent (iface);

	iface->add_timezone = cal_backend_file_add_cached_timezone;
	iface->get_timezone = cal_backend_file_get_cached_timezone;
	iface->list_timezones = cal_backend_file_list_cached_timezones;
}

static void
e_cal_backend_file_init (ECalBackendFile *cbfile)
{
	cbfile->priv = E_CAL_BACKEND_FILE_GET_PRIVATE (cbfile);

	cbfile->priv->file_name = g_strdup ("calendar.ics");

	g_rec_mutex_init (&cbfile->priv->idle_save_rmutex);

	g_mutex_init (&cbfile->priv->refresh_lock);
}

void
e_cal_backend_file_set_file_name (ECalBackendFile *cbfile,
                                  const gchar *file_name)
{
	ECalBackendFilePrivate *priv;

	g_return_if_fail (cbfile != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND_FILE (cbfile));
	g_return_if_fail (file_name != NULL);

	priv = cbfile->priv;
	g_rec_mutex_lock (&priv->idle_save_rmutex);

	if (priv->file_name)
		g_free (priv->file_name);

	priv->file_name = g_strdup (file_name);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);
}

const gchar *
e_cal_backend_file_get_file_name (ECalBackendFile *cbfile)
{
	ECalBackendFilePrivate *priv;

	g_return_val_if_fail (cbfile != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_BACKEND_FILE (cbfile), NULL);

	priv = cbfile->priv;

	return priv->file_name;
}

void
e_cal_backend_file_reload (ECalBackendFile *cbfile,
                           GError **perror)
{
	ECalBackendFilePrivate *priv;
	gchar *str_uri;
	gboolean writable = FALSE;
	GError *err = NULL;

	priv = cbfile->priv;
	g_rec_mutex_lock (&priv->idle_save_rmutex);

	str_uri = get_uri_string (E_CAL_BACKEND (cbfile));
	if (!str_uri) {
		err = EDC_ERROR_NO_URI ();
		goto done;
	}

	writable = e_cal_backend_get_writable (E_CAL_BACKEND (cbfile));

	if (g_access (str_uri, R_OK) == 0) {
		reload_cal (cbfile, str_uri, &err);
		if (g_access (str_uri, W_OK) != 0)
			writable = FALSE;
	} else {
		err = EDC_ERROR (NoSuchCal);
	}

	g_free (str_uri);

	if (!err && writable) {
		ESource *source;

		source = e_backend_get_source (E_BACKEND (cbfile));

		if (!e_source_get_writable (source))
			writable = FALSE;
	}
  done:
	g_rec_mutex_unlock (&priv->idle_save_rmutex);
	e_cal_backend_set_writable (E_CAL_BACKEND (cbfile), writable);

	if (err)
		g_propagate_error (perror, err);
}

#ifdef TEST_QUERY_RESULT

static void
test_query_by_scanning_all_objects (ECalBackendFile *cbfile,
                                    const gchar *sexp,
                                    GSList **objects)
{
	MatchObjectData match_data;
	ECalBackendFilePrivate *priv;

	priv = cbfile->priv;

	match_data.search_needed = TRUE;
	match_data.query = sexp;
	match_data.comps_list = NULL;
	match_data.as_string = TRUE;
	match_data.backend = E_CAL_BACKEND (cbfile);

	if (sexp && !strcmp (sexp, "#t"))
		match_data.search_needed = FALSE;

	match_data.obj_sexp = e_cal_backend_sexp_new (sexp);
	if (!match_data.obj_sexp)
		return;

	g_rec_mutex_lock (&priv->idle_save_rmutex);

	if (!match_data.obj_sexp)
	{
		g_message (G_STRLOC ": Getting object list (%s)", sexp);
		exit (-1);
	}

	g_hash_table_foreach (priv->comp_uid_hash, (GHFunc) match_object_sexp,
			&match_data);

	g_rec_mutex_unlock (&priv->idle_save_rmutex);

	*objects = g_slist_reverse (match_data.comps_list);

	g_object_unref (match_data.obj_sexp);
}

static void
write_list (GSList *list)
{
	GSList *l;

	for (l = list; l; l = l->next)
	{
		const gchar *str = l->data;
		ECalComponent *comp = e_cal_component_new_from_string (str);
		const gchar *uid;
		e_cal_component_get_uid (comp, &uid);
		g_print ("%s\n", uid);
	}
}

static void
get_difference_of_lists (ECalBackendFile *cbfile,
                         GSList *smaller,
                         GSList *bigger)
{
	GSList *l, *lsmaller;

	for (l = bigger; l; l = l->next) {
		gchar *str = l->data;
		const gchar *uid;
		ECalComponent *comp = e_cal_component_new_from_string (str);
		gboolean found = FALSE;
		e_cal_component_get_uid (comp, &uid);

		for (lsmaller = smaller; lsmaller && !found; lsmaller = lsmaller->next)
		{
			gchar *strsmaller = lsmaller->data;
			const gchar *uidsmaller;
			ECalComponent *compsmaller = e_cal_component_new_from_string (strsmaller);
			e_cal_component_get_uid (compsmaller, &uidsmaller);

			found = strcmp (uid, uidsmaller) == 0;

			g_object_unref (compsmaller);
		}

		if (!found)
		{
			time_t time_start, time_end;
			printf ("%s IS MISSING\n", uid);

			e_cal_util_get_component_occur_times (
				comp, &time_start, &time_end,
				resolve_tzid, cbfile->priv->icalcomp,
				icaltimezone_get_utc_timezone (),
				e_cal_backend_get_kind (E_CAL_BACKEND (cbfile)));

			d (printf ("start %s\n", asctime (gmtime (&time_start))));
			d (printf ("end %s\n", asctime (gmtime (&time_end))));
		}

		g_object_unref (comp);
	}
}

static void
test_query (ECalBackendFile *cbfile,
            const gchar *query)
{
	GSList *objects = NULL, *all_objects = NULL;

	g_return_if_fail (query != NULL);

	d (g_print ("Query %s\n", query));

	test_query_by_scanning_all_objects (cbfile, query, &all_objects);
	e_cal_backend_file_get_object_list (E_CAL_BACKEND_SYNC (cbfile), NULL, NULL, query, &objects, NULL);
	if (objects == NULL)
	{
		g_message (G_STRLOC " failed to get objects\n");
		exit (0);
	}

	if (g_slist_length (objects) < g_slist_length (all_objects) )
	{
		g_print ("ERROR\n");
		get_difference_of_lists (cbfile, objects, all_objects);
		exit (-1);
	}
	else if (g_slist_length (objects) > g_slist_length (all_objects) )
	{
		g_print ("ERROR\n");
		write_list (all_objects);
		get_difference_of_lists (cbfile, all_objects, objects);
		exit (-1);
	}

	g_slist_foreach (objects, (GFunc) g_free, NULL);
	g_slist_free (objects);
	g_slist_foreach (all_objects, (GFunc) g_free, NULL);
	g_slist_free (all_objects);
}

static void
execute_query (ECalBackendFile *cbfile,
               const gchar *query)
{
	GSList *objects = NULL;

	g_return_if_fail (query != NULL);

	d (g_print ("Query %s\n", query));
	e_cal_backend_file_get_object_list (E_CAL_BACKEND_SYNC (cbfile), NULL, NULL, query, &objects, NULL);
	if (objects == NULL)
	{
		g_message (G_STRLOC " failed to get objects\n");
		exit (0);
	}

	g_slist_foreach (objects, (GFunc) g_free, NULL);
	g_slist_free (objects);
}

static gchar *fname = NULL;
static gboolean only_execute = FALSE;
static gchar *calendar_fname = NULL;

static GOptionEntry entries[] =
{
  { "test-file", 't', 0, G_OPTION_ARG_STRING, &fname, "File with prepared queries", NULL },
  { "only-execute", 'e', 0, G_OPTION_ARG_NONE, &only_execute, "Only execute, do not test query", NULL },
  { "calendar-file", 'c', 0, G_OPTION_ARG_STRING, &calendar_fname, "Path to the calendar.ics file", NULL },
  { NULL }
};

/* Always add at least this many bytes when extending the buffer.  */
#define MIN_CHUNK 64

static gint
private_getline (gchar **lineptr,
                 gsize *n,
                 FILE *stream)
{
	gint nchars_avail;
	gchar *read_pos;

	if (!lineptr || !n || !stream)
		return -1;

	if (!*lineptr) {
		*n = MIN_CHUNK;
		*lineptr = (char *)malloc (*n);
		if (!*lineptr)
			return -1;
	}

	nchars_avail = (gint) *n;
	read_pos = *lineptr;

	for (;;) {
		gint c = getc (stream);

		if (nchars_avail < 2) {
			if (*n > MIN_CHUNK)
				*n *= 2;
			else
				*n += MIN_CHUNK;

			nchars_avail = (gint)(*n + *lineptr - read_pos);
			*lineptr = (char *)realloc (*lineptr, *n);
			if (!*lineptr)
				return -1;
			read_pos = *n - nchars_avail + *lineptr;
		}

		if (ferror (stream) || c == EOF) {
			if (read_pos == *lineptr)
				return -1;
			else
				break;
		}

		*read_pos++ = c;
		nchars_avail--;

		if (c == '\n')
			/* Return the line.  */
			break;
	}

	*read_pos = '\0';

	return (gint)(read_pos - (*lineptr));
}

gint
main (gint argc,
      gchar **argv)
{
	gchar * line = NULL;
	gsize len = 0;
	ECalBackendFile * cbfile;
	gint num = 0;
	GError *error = NULL;
	GOptionContext *context;
	FILE * fin = NULL;

	context = g_option_context_new ("- test utility for e-d-s file backend");
	g_option_context_add_main_entries (context, entries, GETTEXT_PACKAGE);
	if (!g_option_context_parse (context, &argc, &argv, &error))
	{
		g_print ("option parsing failed: %s\n", error->message);
		exit (1);
	}

	calendar_fname = g_strdup ("calendar.ics");

	if (!calendar_fname)
	{
		g_message (G_STRLOC " Please, use -c parameter");
		exit (-1);
	}

	cbfile = g_object_new (E_TYPE_CAL_BACKEND_FILE, NULL);
	open_cal (cbfile, calendar_fname, &error);
	if (error != NULL) {
		g_message (G_STRLOC " Could not open calendar %s: %s", calendar_fname, error->message);
		exit (-1);
	}

	if (fname)
	{
		fin = fopen (fname, "r");

		if (!fin)
		{
			g_message (G_STRLOC " Could not open file %s", fname);
			goto err0;
		}
	}
	else
	{
		g_message (G_STRLOC " Reading from stdin");
		fin = stdin;
	}

	while (private_getline (&line, &len, fin) != -1) {
		g_print ("Query %d: %s", num++, line);

		if (only_execute)
			execute_query (cbfile, line);
		else
			test_query (cbfile, line);
	}

	if (line)
		free (line);

	if (fname)
		fclose (fin);

err0:
	g_object_unref (cbfile);

	return 0;
}
#endif
