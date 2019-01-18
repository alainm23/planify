/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-cal-backend-store.c
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
 * Authors: Chenthill Palanisamy <pchenthill@novell.com>
 */

/**
 * SECTION: e-cal-backend-store
 * @include: libedata-cal/libedata-cal.h
 * @short_description: A helper class for storing calendar components
 *
 * This class can be used by backends to store calendar components.
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gstdio.h>

#include <libebackend/libebackend.h>

#include "e-cal-backend-intervaltree.h"

#include "e-cal-backend-store.h"

#define E_CAL_BACKEND_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_BACKEND_STORE, ECalBackendStorePrivate))

#define CACHE_FILE_NAME "calendar.ics"
#define KEY_FILE_NAME "keys.xml"
#define IDLE_SAVE_TIMEOUT_SECONDS 6

typedef struct {
	ECalComponent *comp;
	GHashTable *recurrences;
} FullCompObject;

struct _ECalBackendStorePrivate {
	gchar *path;
	EIntervalTree *intervaltree;
	gboolean loaded;

	GWeakRef timezone_cache;
	gulong timezone_added_handler_id;

	GHashTable *comp_uid_hash;
	EFileCache *keys_cache;

	GRWLock lock;

	gchar *cache_file_name;
	gchar *key_file_name;

	gboolean dirty;
	gboolean freeze_changes;

	guint save_timeout_id;
	GMutex save_timeout_lock;
	GList *timezones_to_save;
};

enum {
	PROP_0,
	PROP_PATH,
	PROP_TIMEZONE_CACHE,
};

G_DEFINE_TYPE (ECalBackendStore, e_cal_backend_store, G_TYPE_OBJECT)

static FullCompObject *
create_new_full_object (void)
{
	FullCompObject *obj;

	obj = g_new0 (FullCompObject, 1);
	obj->recurrences = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	return obj;
}

static void
destroy_full_object (FullCompObject *obj)
{
	if (obj == NULL)
		return;

	if (obj->comp != NULL)
		g_object_unref (obj->comp);

	g_hash_table_destroy (obj->recurrences);

	g_free (obj);
}

static void
cal_backend_store_free_zone (icaltimezone *zone)
{
	icaltimezone_free (zone, 1);
}

static void
cal_backend_store_add_timezone (ECalBackendStore *store,
                                icalcomponent *vtzcomp)
{
	ETimezoneCache *timezone_cache;
	icalproperty *prop;
	icaltimezone *zone;
	const gchar *tzid;

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);

	prop = icalcomponent_get_first_property (vtzcomp, ICAL_TZID_PROPERTY);
	if (prop == NULL)
		goto exit;

	tzid = icalproperty_get_tzid (prop);
	if (e_timezone_cache_get_timezone (timezone_cache, tzid) != NULL)
		goto exit;

	zone = icaltimezone_new ();

	vtzcomp = icalcomponent_new_clone (vtzcomp);
	if (!icaltimezone_set_component (zone, vtzcomp)) {
		icaltimezone_free (zone, TRUE);
		icalcomponent_free (vtzcomp);
		goto exit;
	}

	e_timezone_cache_add_timezone (timezone_cache, zone);

	icaltimezone_free (zone, TRUE);

exit:
	g_object_unref (timezone_cache);
}

static icaltimezone *
resolve_tzid (const gchar *tzid,
              gpointer user_data)
{
	ECalBackendStore *store;
	ETimezoneCache *timezone_cache;
	icaltimezone *zone;

	store = E_CAL_BACKEND_STORE (user_data);

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);
	zone = e_timezone_cache_get_timezone (timezone_cache, tzid);
	g_object_unref (timezone_cache);

	return zone;
}

static gboolean
cal_backend_store_internal_put_component (ECalBackendStore *store,
                                          ECalComponent *comp)
{
	FullCompObject *obj = NULL;
	const gchar *uid;

	g_return_val_if_fail (comp != NULL, FALSE);

	e_cal_component_get_uid (comp, &uid);

	if (uid == NULL) {
		g_warning ("The component does not have a valid uid \n");
		return FALSE;
	}

	g_rw_lock_writer_lock (&store->priv->lock);
	obj = g_hash_table_lookup (store->priv->comp_uid_hash, uid);
	if (obj == NULL) {
		obj = create_new_full_object ();
		g_hash_table_insert (
			store->priv->comp_uid_hash, g_strdup (uid), obj);
	}

	if (!e_cal_component_is_instance (comp)) {
		if (obj->comp != NULL)
			g_object_unref (obj->comp);

		obj->comp = comp;
	} else {
		gchar *rid = e_cal_component_get_recurid_as_string (comp);

		g_hash_table_insert (obj->recurrences, rid, comp);
	}

	g_object_ref (comp);
	g_rw_lock_writer_unlock (&store->priv->lock);

	return TRUE;
}

static gboolean
cal_backend_store_internal_remove_component (ECalBackendStore *store,
                                             const gchar *uid,
                                             const gchar *rid)
{
	FullCompObject *obj = NULL;
	gboolean ret_val = TRUE;
	gboolean remove_completely = FALSE;

	g_rw_lock_writer_lock (&store->priv->lock);

	obj = g_hash_table_lookup (store->priv->comp_uid_hash, uid);
	if (obj == NULL) {
		ret_val = FALSE;
		goto end;
	}

	if (rid != NULL && *rid) {
		ret_val = g_hash_table_remove (obj->recurrences, rid);

		if (ret_val && g_hash_table_size (obj->recurrences) == 0 && !obj->comp)
			remove_completely = TRUE;
	} else
		remove_completely = TRUE;

	if (remove_completely)
		g_hash_table_remove (store->priv->comp_uid_hash, uid);

end:
	g_rw_lock_writer_unlock (&store->priv->lock);

	return ret_val;

}

static void
cal_backend_store_scan_vcalendar (ECalBackendStore *store,
                                  icalcomponent *top_icalcomp)
{
	icalcompiter iter;
	time_t time_start, time_end;

	for (iter = icalcomponent_begin_component (top_icalcomp, ICAL_ANY_COMPONENT);
	     icalcompiter_deref (&iter) != NULL;
	     icalcompiter_next (&iter)) {
		const icaltimezone *dzone = NULL;
		icalcomponent *icalcomp;
		icalcomponent_kind kind;
		ECalComponent *comp;
		icalcomp = icalcompiter_deref (&iter);

		kind = icalcomponent_isa (icalcomp);

		if (!(kind == ICAL_VEVENT_COMPONENT
		      || kind == ICAL_VTODO_COMPONENT
		      || kind == ICAL_VJOURNAL_COMPONENT
		      || kind == ICAL_VTIMEZONE_COMPONENT))
			continue;

		if (kind == ICAL_VTIMEZONE_COMPONENT) {
			cal_backend_store_add_timezone (store, icalcomp);
			continue;
		}

		comp = e_cal_component_new ();

		if (!e_cal_component_set_icalcomponent (comp, icalcomponent_new_clone (icalcomp))) {
			g_object_unref (comp);
			continue;
		}

		dzone = e_cal_backend_store_get_default_timezone (store);
		e_cal_util_get_component_occur_times (
			comp, &time_start, &time_end,
			resolve_tzid, store, dzone, kind);

		cal_backend_store_internal_put_component (store, comp);
		e_cal_backend_store_interval_tree_add_comp (
			store, comp, time_start, time_end);

		g_object_unref (comp);
	}
}

static void
cal_backend_store_save_cache_now (ECalBackendStore *store,
                                  GList *timezones_to_save)
{
	GHashTableIter iter;
	icalcomponent *vcalcomp;
	gchar *data = NULL, *tmpfile;
	gsize len, nwrote;
	gpointer value;
	FILE *f;

	g_rw_lock_reader_lock (&store->priv->lock);

	vcalcomp = e_cal_util_new_top_level ();

	/* Add all timezone components. */
	while (timezones_to_save != NULL) {
		icaltimezone *tz;
		icalcomponent *tzcomp;

		tz = timezones_to_save->data;
		tzcomp = icaltimezone_get_component (tz);
		tzcomp = icalcomponent_new_clone (tzcomp);
		icalcomponent_add_component (vcalcomp, tzcomp);

		timezones_to_save = g_list_next (timezones_to_save);
	}

	/* Add all non-timezone components. */
	g_hash_table_iter_init (&iter, store->priv->comp_uid_hash);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		FullCompObject *obj = value;
		GHashTableIter recur_iter;

		if (obj->comp != NULL) {
			ECalComponent *comp = obj->comp;
			icalcomponent *icalcomp;

			icalcomp = e_cal_component_get_icalcomponent (comp);
			icalcomp = icalcomponent_new_clone (icalcomp);
			icalcomponent_add_component (vcalcomp, icalcomp);
		}

		g_hash_table_iter_init (&recur_iter, obj->recurrences);
		while (g_hash_table_iter_next (&recur_iter, NULL, &value)) {
			ECalComponent *comp = value;
			icalcomponent *icalcomp;

			icalcomp = e_cal_component_get_icalcomponent (comp);
			icalcomp = icalcomponent_new_clone (icalcomp);
			icalcomponent_add_component (vcalcomp, icalcomp);
		}
	}

	data = icalcomponent_as_ical_string_r (vcalcomp);
	icalcomponent_free (vcalcomp);

	tmpfile = g_strdup_printf ("%s~", store->priv->cache_file_name);
	f = g_fopen (tmpfile, "wb");
	if (!f)
		goto error;

	len = strlen (data);
	nwrote = fwrite (data, 1, len, f);
	if (fclose (f) != 0 || nwrote != len)
		goto error;

	if (g_rename (tmpfile, store->priv->cache_file_name) != 0)
		g_unlink (tmpfile);

	store->priv->dirty = FALSE;

error:
	g_rw_lock_reader_unlock (&store->priv->lock);
	g_free (tmpfile);
	g_free (data);
}

static gboolean
cal_backend_store_save_cache_timeout_cb (gpointer user_data)
{
	GWeakRef *weakref = user_data;
	GSource *source;
	ECalBackendStore *store;
	GList *timezones_to_save;

	source = g_main_current_source ();
	if (g_source_is_destroyed (source))
		return FALSE;

	g_return_val_if_fail (weakref != NULL, FALSE);

	store = g_weak_ref_get (weakref);
	if (!store)
		return FALSE;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);

	g_mutex_lock (&store->priv->save_timeout_lock);
	if (store->priv->save_timeout_id != g_source_get_id (source)) {
		g_mutex_unlock (&store->priv->save_timeout_lock);
		g_object_unref (store);
		return FALSE;
	}

	store->priv->save_timeout_id = 0;
	timezones_to_save = store->priv->timezones_to_save;
	store->priv->timezones_to_save = NULL;
	g_mutex_unlock (&store->priv->save_timeout_lock);

	cal_backend_store_save_cache_now (store, timezones_to_save);

	g_list_free_full (
		timezones_to_save,
		(GDestroyNotify) cal_backend_store_free_zone);

	g_object_unref (store);

	return FALSE;
}

static void
cal_backend_store_save_cache (ECalBackendStore *store)
{
	ETimezoneCache *timezone_cache;
	GList *list, *link;

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);
	g_return_if_fail (timezone_cache != NULL);

	/* Clone the icaltimezone structs in case
	 * the timeout outlives the ETimezoneCache. */
	list = e_timezone_cache_list_timezones (timezone_cache);
	for (link = list; link != NULL; link = g_list_next (link)) {
		icaltimezone *tz;
		icalcomponent *tzcomp;

		tz = icaltimezone_new ();
		tzcomp = icaltimezone_get_component (link->data);
		tzcomp = icalcomponent_new_clone (tzcomp);
		icaltimezone_set_component (tz, tzcomp);

		link->data = tz;
	}

	g_object_unref (timezone_cache);

	g_mutex_lock (&store->priv->save_timeout_lock);

	if (store->priv->save_timeout_id > 0)
		g_source_remove (store->priv->save_timeout_id);

	store->priv->save_timeout_id = e_named_timeout_add_seconds_full (
		G_PRIORITY_DEFAULT, IDLE_SAVE_TIMEOUT_SECONDS,
		cal_backend_store_save_cache_timeout_cb, e_weak_ref_new (store),
		(GDestroyNotify) e_weak_ref_free);

	g_list_free_full (
		store->priv->timezones_to_save,
		(GDestroyNotify) cal_backend_store_free_zone);

	store->priv->timezones_to_save = list;  /* takes ownership */

	g_mutex_unlock (&store->priv->save_timeout_lock);
}

static void
cal_backend_store_timezone_added_cb (ETimezoneCache *timezone_cache,
                                     icaltimezone *zone,
                                     ECalBackendStore *store)
{
	store->priv->dirty = TRUE;

	if (!store->priv->freeze_changes)
		cal_backend_store_save_cache (store);
}

static void
cal_backend_store_set_path (ECalBackendStore *store,
                            const gchar *path)
{
	g_return_if_fail (store->priv->path == NULL);
	g_return_if_fail (path != NULL);

	store->priv->path = g_strdup (path);
}

static void
cal_backend_store_set_timezone_cache (ECalBackendStore *store,
                                      ETimezoneCache *timezone_cache)
{
	g_return_if_fail (E_IS_TIMEZONE_CACHE (timezone_cache));

	g_weak_ref_set (&store->priv->timezone_cache, timezone_cache);
}

static void
cal_backend_store_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_PATH:
			cal_backend_store_set_path (
				E_CAL_BACKEND_STORE (object),
				g_value_get_string (value));
			return;

		case PROP_TIMEZONE_CACHE:
			cal_backend_store_set_timezone_cache (
				E_CAL_BACKEND_STORE (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_backend_store_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_PATH:
			g_value_set_string (
				value,
				e_cal_backend_store_get_path (
				E_CAL_BACKEND_STORE (object)));
			return;

		case PROP_TIMEZONE_CACHE:
			g_value_take_object (
				value,
				e_cal_backend_store_ref_timezone_cache (
				E_CAL_BACKEND_STORE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_backend_store_dispose (GObject *object)
{
	ECalBackendStorePrivate *priv;
	ETimezoneCache *timezone_cache;
	GList *timezones_to_save = NULL;
	gboolean save_needed = FALSE;

	priv = E_CAL_BACKEND_STORE_GET_PRIVATE (object);

	/* If a save is scheduled, cancel it and save now. */
	g_mutex_lock (&priv->save_timeout_lock);
	if (priv->save_timeout_id > 0 || priv->dirty) {
		if (priv->save_timeout_id > 0) {
			g_source_remove (priv->save_timeout_id);
			priv->save_timeout_id = 0;
		}

		timezones_to_save = priv->timezones_to_save;
		priv->timezones_to_save = NULL;
		save_needed = TRUE;
	}
	g_mutex_unlock (&priv->save_timeout_lock);

	if (save_needed) {
		cal_backend_store_save_cache_now (
			E_CAL_BACKEND_STORE (object),
			timezones_to_save);
		g_list_free_full (
			timezones_to_save,
			(GDestroyNotify) cal_backend_store_free_zone);
	}

	timezone_cache = g_weak_ref_get (&priv->timezone_cache);
	if (timezone_cache != NULL) {
		g_signal_handler_disconnect (
			timezone_cache,
			priv->timezone_added_handler_id);
		g_object_unref (timezone_cache);

		g_weak_ref_set (&priv->timezone_cache, NULL);
		priv->timezone_added_handler_id = 0;
	}

	g_hash_table_remove_all (priv->comp_uid_hash);

	if (priv->keys_cache != NULL) {
		g_object_unref (priv->keys_cache);
		priv->keys_cache = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_backend_store_parent_class)->dispose (object);
}

static void
cal_backend_store_finalize (GObject *object)
{
	ECalBackendStorePrivate *priv;

	priv = E_CAL_BACKEND_STORE_GET_PRIVATE (object);

	if (priv->intervaltree) {
		e_intervaltree_destroy (priv->intervaltree);
		priv->intervaltree = NULL;
	}

	g_hash_table_destroy (priv->comp_uid_hash);

	g_rw_lock_clear (&priv->lock);

	g_free (priv->path);
	g_free (priv->cache_file_name);
	g_free (priv->key_file_name);

	g_mutex_clear (&priv->save_timeout_lock);
	g_weak_ref_clear (&priv->timezone_cache);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_backend_store_parent_class)->finalize (object);
}

static void
cal_backend_store_constructed (GObject *object)
{
	ECalBackendStore *store;
	ETimezoneCache *timezone_cache;
	const gchar *path;
	gulong handler_id;

	store = E_CAL_BACKEND_STORE (object);
	path = e_cal_backend_store_get_path (store);
	store->priv->cache_file_name =
		g_build_filename (path, CACHE_FILE_NAME, NULL);
	store->priv->key_file_name =
		g_build_filename (path, KEY_FILE_NAME, NULL);

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);

	handler_id = g_signal_connect (
		timezone_cache, "timezone-added",
		G_CALLBACK (cal_backend_store_timezone_added_cb), store);

	store->priv->timezone_added_handler_id = handler_id;

	g_object_unref (timezone_cache);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_cal_backend_store_parent_class)->constructed (object);
}

static gboolean
cal_backend_store_load (ECalBackendStore *store)
{
	icalcomponent *icalcomp;

	if (store->priv->cache_file_name == NULL)
		return FALSE;

	if (store->priv->key_file_name == NULL)
		return FALSE;

	/* Parse keys */
	store->priv->keys_cache =
		e_file_cache_new (store->priv->key_file_name);

	/* Parse components */
	icalcomp = e_cal_util_parse_ics_file (store->priv->cache_file_name);
	if (!icalcomp)
		return FALSE;

	if (icalcomponent_isa (icalcomp) != ICAL_VCALENDAR_COMPONENT) {
		icalcomponent_free (icalcomp);

		return FALSE;
	}
	cal_backend_store_scan_vcalendar (store, icalcomp);
	icalcomponent_free (icalcomp);

	return TRUE;
}

static gboolean
cal_backend_store_clean (ECalBackendStore *store)
{
	g_rw_lock_writer_lock (&store->priv->lock);

	e_file_cache_clean (store->priv->keys_cache);
	g_hash_table_remove_all (store->priv->comp_uid_hash);

	g_rw_lock_writer_unlock (&store->priv->lock);

	cal_backend_store_save_cache (store);

	return TRUE;
}

static ECalComponent *
cal_backend_store_get_component (ECalBackendStore *store,
                                 const gchar *uid,
                                 const gchar *rid)
{
	FullCompObject *obj = NULL;
	ECalComponent *comp = NULL;

	g_rw_lock_reader_lock (&store->priv->lock);

	obj = g_hash_table_lookup (store->priv->comp_uid_hash, uid);
	if (obj == NULL)
		goto end;

	if (rid != NULL && *rid)
		comp = g_hash_table_lookup (obj->recurrences, rid);
	else
		comp = obj->comp;

	if (comp != NULL)
		g_object_ref (comp);

end:
	g_rw_lock_reader_unlock (&store->priv->lock);

	return comp;
}

static gboolean
cal_backend_store_put_component (ECalBackendStore *store,
                                 ECalComponent *comp)
{
	gboolean ret_val = FALSE;

	ret_val = cal_backend_store_internal_put_component (store, comp);

	if (ret_val) {
		store->priv->dirty = TRUE;

		if (!store->priv->freeze_changes)
			cal_backend_store_save_cache (store);
	}

	return ret_val;
}

static gboolean
cal_backend_store_remove_component (ECalBackendStore *store,
                                    const gchar *uid,
                                    const gchar *rid)
{
	gboolean ret_val = FALSE;

	ret_val = cal_backend_store_internal_remove_component (
		store, uid, rid);

	if (ret_val) {
		store->priv->dirty = TRUE;

		if (!store->priv->freeze_changes)
			cal_backend_store_save_cache (store);
	}

	return ret_val;
}

static gboolean
cal_backend_store_has_component (ECalBackendStore *store,
                                 const gchar *uid,
                                 const gchar *rid)
{
	gboolean ret_val = FALSE;
	FullCompObject *obj = NULL;

	g_rw_lock_reader_lock (&store->priv->lock);

	obj = g_hash_table_lookup (store->priv->comp_uid_hash, uid);
	if (obj == NULL) {
		goto end;
	}

	if (rid != NULL) {
		ECalComponent *comp = g_hash_table_lookup (obj->recurrences, rid);

		if (comp != NULL)
			ret_val = TRUE;
	} else
		ret_val = TRUE;

end:
	g_rw_lock_reader_unlock (&store->priv->lock);
	return ret_val;
}

static const icaltimezone *
cal_backend_store_get_default_timezone (ECalBackendStore *store)
{
	ETimezoneCache *timezone_cache;
	const icaltimezone *zone = NULL;
	const gchar *tzid;

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);

	g_rw_lock_reader_lock (&store->priv->lock);

	tzid = e_file_cache_get_object (
		store->priv->keys_cache, "default-zone");
	if (tzid != NULL)
		zone = e_timezone_cache_get_timezone (timezone_cache, tzid);

	g_rw_lock_reader_unlock (&store->priv->lock);

	g_object_unref (timezone_cache);

	return zone;
}

static gboolean
cal_backend_store_set_default_timezone (ECalBackendStore *store,
                                        icaltimezone *zone)
{
	ETimezoneCache *timezone_cache;
	const gchar *key = "default-zone";
	const gchar *tzid;

	timezone_cache = e_cal_backend_store_ref_timezone_cache (store);
	e_timezone_cache_add_timezone (timezone_cache, zone);
	g_object_unref (timezone_cache);

	g_rw_lock_writer_lock (&store->priv->lock);

	tzid = icaltimezone_get_tzid (zone);

	if (e_file_cache_get_object (store->priv->keys_cache, key))
		e_file_cache_replace_object (
			store->priv->keys_cache, key, tzid);
	else
		e_file_cache_add_object (
			store->priv->keys_cache, key, tzid);

	g_rw_lock_writer_unlock (&store->priv->lock);

	return TRUE;
}

static GSList *
cal_backend_store_get_components_by_uid (ECalBackendStore *store,
                                         const gchar *uid)
{
	FullCompObject *obj = NULL;
	GSList *comps = NULL;
	GHashTableIter iter;
	gpointer value;

	g_rw_lock_reader_lock (&store->priv->lock);

	obj = g_hash_table_lookup (store->priv->comp_uid_hash, uid);
	if (obj == NULL) {
		goto end;
	}

	if (obj->comp != NULL)
		comps = g_slist_append (comps, g_object_ref (obj->comp));

	g_hash_table_iter_init (&iter, obj->recurrences);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		ECalComponent *comp = E_CAL_COMPONENT (value);
		comps = g_slist_prepend (comps, g_object_ref (comp));
	}

end:
	g_rw_lock_reader_unlock (&store->priv->lock);

	return comps;
}

static const gchar *
cal_backend_store_get_key_value (ECalBackendStore *store,
                                 const gchar *key)
{
	const gchar *value;

	g_rw_lock_reader_lock (&store->priv->lock);
	value = e_file_cache_get_object (store->priv->keys_cache, key);
	g_rw_lock_reader_unlock (&store->priv->lock);

	return value;
}

static gboolean
cal_backend_store_put_key_value (ECalBackendStore *store,
                                 const gchar *key,
                                 const gchar *value)
{
	gboolean ret_val = FALSE;

	g_rw_lock_writer_lock (&store->priv->lock);

	if (!value)
		ret_val = e_file_cache_remove_object (
			store->priv->keys_cache, key);
	else {
		if (e_file_cache_get_object (store->priv->keys_cache, key))
			ret_val = e_file_cache_replace_object (
				store->priv->keys_cache, key, value);
		else
			ret_val = e_file_cache_add_object (
				store->priv->keys_cache, key, value);
	}

	g_rw_lock_writer_unlock (&store->priv->lock);

	return ret_val;
}

static void
cal_backend_store_thaw_changes (ECalBackendStore *store)
{
	store->priv->freeze_changes = FALSE;

	e_file_cache_thaw_changes (store->priv->keys_cache);
	if (store->priv->dirty) {
		cal_backend_store_save_cache (store);
	}
}

static void
cal_backend_store_freeze_changes (ECalBackendStore *store)
{
	store->priv->freeze_changes = TRUE;
	e_file_cache_freeze_changes (store->priv->keys_cache);
}

static GSList *
cal_backend_store_get_components (ECalBackendStore *store)
{
	GHashTableIter iter;
	GSList *list = NULL;
	gpointer value;

	g_rw_lock_reader_lock (&store->priv->lock);

	g_hash_table_iter_init (&iter, store->priv->comp_uid_hash);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		FullCompObject *obj = value;
		GHashTableIter recur_iter;

		if (obj->comp != NULL) {
			ECalComponent *comp = g_object_ref (obj->comp);
			list = g_slist_prepend (list, comp);
		}

		g_hash_table_iter_init (&recur_iter, obj->recurrences);
		while (g_hash_table_iter_next (&recur_iter, NULL, &value)) {
			ECalComponent *comp = g_object_ref (value);
			list = g_slist_prepend (list, comp);
		}
	}

	g_rw_lock_reader_unlock (&store->priv->lock);

	return list;
}

static GSList *
cal_backend_store_get_component_ids (ECalBackendStore *store)
{
	GHashTableIter iter;
	GSList *list = NULL;
	gpointer value;

	g_rw_lock_reader_lock (&store->priv->lock);

	g_hash_table_iter_init (&iter, store->priv->comp_uid_hash);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		FullCompObject *obj = value;
		GHashTableIter recur_iter;

		if (obj->comp != NULL) {
			ECalComponentId *id;
			id = e_cal_component_get_id (obj->comp);
			list = g_slist_prepend (list, id);
		}

		g_hash_table_iter_init (&recur_iter, obj->recurrences);
		while (g_hash_table_iter_next (&recur_iter, NULL, &value)) {
			ECalComponentId *id;
			id = e_cal_component_get_id (value);
			list = g_slist_prepend (list, id);
		}
	}

	g_rw_lock_reader_unlock (&store->priv->lock);

	return list;
}

static void
e_cal_backend_store_class_init (ECalBackendStoreClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECalBackendStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = cal_backend_store_set_property;
	object_class->get_property = cal_backend_store_get_property;
	object_class->dispose = cal_backend_store_dispose;
	object_class->finalize = cal_backend_store_finalize;
	object_class->constructed = cal_backend_store_constructed;

	class->load = cal_backend_store_load;
	class->clean = cal_backend_store_clean;
	class->get_component = cal_backend_store_get_component;
	class->put_component = cal_backend_store_put_component;
	class->remove_component = cal_backend_store_remove_component;
	class->has_component = cal_backend_store_has_component;
	class->get_default_timezone = cal_backend_store_get_default_timezone;
	class->set_default_timezone = cal_backend_store_set_default_timezone;
	class->get_components_by_uid = cal_backend_store_get_components_by_uid;
	class->get_key_value = cal_backend_store_get_key_value;
	class->put_key_value = cal_backend_store_put_key_value;
	class->thaw_changes = cal_backend_store_thaw_changes;
	class->freeze_changes = cal_backend_store_freeze_changes;
	class->get_components = cal_backend_store_get_components;
	class->get_component_ids = cal_backend_store_get_component_ids;

	/**
	 * ECalBackendStore:path:
	 *
	 * The directory to store the file.
	 */
	g_object_class_install_property (
		object_class,
		PROP_PATH,
		g_param_spec_string (
			"path",
			"Path",
			"The directory to store the file",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECalBackendStore:timezone-cache:
	 *
	 * An object implementing the ETimezoneCache interface.
	 */
	g_object_class_install_property (
		object_class,
		PROP_TIMEZONE_CACHE,
		g_param_spec_object (
			"timezone-cache",
			"Timezone Cache",
			"An object implementing the "
			"ETimezoneCache interface",
			E_TYPE_TIMEZONE_CACHE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_cal_backend_store_init (ECalBackendStore *store)
{
	GHashTable *comp_uid_hash;

	comp_uid_hash = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) destroy_full_object);

	store->priv = E_CAL_BACKEND_STORE_GET_PRIVATE (store);

	store->priv->intervaltree = e_intervaltree_new ();
	store->priv->comp_uid_hash = comp_uid_hash;
	g_rw_lock_init (&store->priv->lock);
	g_mutex_init (&store->priv->save_timeout_lock);
	g_weak_ref_init (&store->priv->timezone_cache, NULL);
}

/**
 * e_cal_backend_store_new:
 * @path: the directory for the store file
 * @cache: an #ETimezoneCache
 *
 * Creates a new #ECalBackendStore from @path and @cache.
 *
 * Returns: a new #ECalBackendStore
 *
 * Since: 3.8
 **/
ECalBackendStore *
e_cal_backend_store_new (const gchar *path,
                         ETimezoneCache *cache)
{
	g_return_val_if_fail (path != NULL, NULL);
	g_return_val_if_fail (E_IS_TIMEZONE_CACHE (cache), NULL);

	return g_object_new (
		E_TYPE_CAL_BACKEND_STORE,
		"path", path, "timezone-cache", cache, NULL);
}

/**
 * e_cal_backend_store_get_path:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
const gchar *
e_cal_backend_store_get_path (ECalBackendStore *store)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	return store->priv->path;
}

/**
 * e_cal_backend_store_ref_timezone_cache:
 * @store: an #ECalBackendStore
 *
 * Returns the #ETimezoneCache passed to e_cal_backend_store_new().
 *
 * The returned #ETimezoneCache is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: an #ETimezoneCache
 *
 * Since: 3.8
 **/
ETimezoneCache *
e_cal_backend_store_ref_timezone_cache (ECalBackendStore *store)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	return g_weak_ref_get (&store->priv->timezone_cache);
}

/**
 * e_cal_backend_store_load:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_load (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);

	if (store->priv->loaded)
		return TRUE;

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->load != NULL, FALSE);

	store->priv->loaded = class->load (store);

	return store->priv->loaded;
}

/**
 * e_cal_backend_store_clean:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_clean (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->clean != NULL, FALSE);

	if (store->priv->intervaltree != NULL) {
		e_intervaltree_destroy (store->priv->intervaltree);
		store->priv->intervaltree = e_intervaltree_new ();
	}

	return class->clean (store);
}

/**
 * e_cal_backend_store_get_component:
 * @store: an #ECalBackendStore
 * @uid: the uid of the component to fetch
 * @rid: the recurrence id of the component to fetch
 *
 * Fetches a component by @uid and @rid
 *
 * Returns: An #ECalComponent
 *
 * Since: 2.28
 **/
ECalComponent *
e_cal_backend_store_get_component (ECalBackendStore *store,
                                   const gchar *uid,
                                   const gchar *rid)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_component != NULL, NULL);

	return class->get_component (store, uid, rid);
}

/**
 * e_cal_backend_store_has_component:
 * @store: an #ECalBackendStore
 * @uid: the uid of the component to check
 * @rid: the recurrence id of the component to check
 *
 * Returns: Whether there was a component for @uid and @rid
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_has_component (ECalBackendStore *store,
                                   const gchar *uid,
                                   const gchar *rid)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->has_component != NULL, FALSE);

	return class->has_component (store, uid, rid);
}

/**
 * e_cal_backend_store_put_component_with_time_range:
 * @store: an #ECalBackendStore
 * @comp: the #ECalComponent to add
 * @occurence_start: start time of this component
 * @occurence_end: end time of this component
 *
 * Returns: whether @comp was successfully added
 *
 * Since: 2.32
 **/
gboolean
e_cal_backend_store_put_component_with_time_range (ECalBackendStore *store,
                                                   ECalComponent *comp,
                                                   time_t occurence_start,
                                                   time_t occurence_end)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->put_component != NULL, FALSE);

	if (class->put_component (store, comp)) {
		if (e_intervaltree_insert (
			store->priv->intervaltree,
			occurence_start, occurence_end, comp))
			return TRUE;
	}

	return FALSE;

}

/**
 * e_cal_backend_store_put_component:
 * @store: an #ECalBackendStore
 * @comp: the #ECalComponent to add
 *
 * Returns: whether @comp was successfully added
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_put_component (ECalBackendStore *store,
                                   ECalComponent *comp)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->put_component != NULL, FALSE);

	return class->put_component (store, comp);
}

/**
 * e_cal_backend_store_remove_component:
 * @store: an #ECalBackendStore
 * @uid: the uid of the component to remove
 * @rid: the recurrence id of the component to remove
 *
 * Returns: whether the component was successfully removed
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_remove_component (ECalBackendStore *store,
                                      const gchar *uid,
                                      const gchar *rid)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remove_component != NULL, FALSE);

	if (class->remove_component (store, uid, rid)) {
		if (e_intervaltree_remove (store->priv->intervaltree, uid, rid))
			return TRUE;
	}

	return FALSE;
}

/**
 * e_cal_backend_store_get_default_timezone:
 * @store: an #ECalBackendStore
 *
 * Fetch the default timezone
 *
 * Returns: (transfer none): The default timezone
 *
 * Since: 2.28
 **/
const icaltimezone *
e_cal_backend_store_get_default_timezone (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_default_timezone != NULL, NULL);

	return class->get_default_timezone (store);
}

/**
 * e_cal_backend_store_set_default_timezone:
 * @store: an #ECalBackendStore
 * @zone: the timezone to set
 *
 * Returns: whether the timezone was successfully set
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_set_default_timezone (ECalBackendStore *store,
                                          icaltimezone *zone)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (zone != NULL, FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->set_default_timezone != NULL, FALSE);

	return class->set_default_timezone (store, zone);
}

/**
 * e_cal_backend_store_get_components_by_uid:
 * @store: an #ECalBackendStore
 * @uid: the @uid of the components to fetch
 *
 * Returns: a list of components matching @uid
 *
 * Since: 2.28
 **/
GSList *
e_cal_backend_store_get_components_by_uid (ECalBackendStore *store,
                                           const gchar *uid)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_components_by_uid != NULL, NULL);

	return class->get_components_by_uid (store, uid);
}

/**
 * e_cal_backend_store_get_components_by_uid_as_ical_string:
 * @store: an #ECalBackendStore
 * @uid: a component UID
 *
 * Returns: Newly allocated ical string containing all
 *   instances with given @uid. Free returned pointer with g_free(),
 *   when no longer needed.
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_store_get_components_by_uid_as_ical_string (ECalBackendStore *store,
                                                          const gchar *uid)
{
	GSList *comps;
	gchar *ical_string = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	comps = e_cal_backend_store_get_components_by_uid (store, uid);
	if (!comps)
		return NULL;

	if (!comps->next) {
		ical_string = e_cal_component_get_as_string (comps->data);
	} else {
		GSList *citer;
		icalcomponent *icalcomp;

		/* if we have detached recurrences, return a VCALENDAR */
		icalcomp = e_cal_util_new_top_level ();

		for (citer = comps; citer; citer = g_slist_next (citer)) {
			ECalComponent *comp = citer->data;

			icalcomponent_add_component (
				icalcomp,
				icalcomponent_new_clone (e_cal_component_get_icalcomponent (comp)));
		}

		ical_string = icalcomponent_as_ical_string_r (icalcomp);

		icalcomponent_free (icalcomp);
	}

	g_slist_free_full (comps, g_object_unref);

	return ical_string;
}

/**
 * e_cal_backend_store_get_components:
 * @store: an #ECalBackendStore
 *
 * Returns: the list of components in @store
 *
 * Since: 2.28
 **/
GSList *
e_cal_backend_store_get_components (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_components != NULL, NULL);

	return class->get_components (store);
}

/**
 * e_cal_backend_store_get_components_occuring_in_range:
 * @store: An #ECalBackendStore object.
 * @start: Start time
 * @end: End time
 *
 * Retrieves a list of components stored in the store, that are occuring
 * in time range [start, end].
 *
 * Returns: (transfer full): A list of the components. Each item in the list is
 * an #ECalComponent, which should be freed when no longer needed.
 *
 * Since: 2.32
 */
GSList *
e_cal_backend_store_get_components_occuring_in_range (ECalBackendStore *store,
                                                      time_t start,
                                                      time_t end)
{
	GList *l, *objects;
	GSList *list = NULL;
	icalcomponent *icalcomp;

	g_return_val_if_fail (store != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	objects = e_intervaltree_search (
		store->priv->intervaltree, start, end);

	if (objects == NULL)
		return NULL;

	for (l = objects; l != NULL; l = g_list_next (l)) {
		ECalComponent *comp = l->data;
		icalcomp = e_cal_component_get_icalcomponent (comp);
		if (icalcomp) {
			icalcomponent_kind kind;

			kind = icalcomponent_isa (icalcomp);
			if (kind == ICAL_VEVENT_COMPONENT ||
			    kind == ICAL_VTODO_COMPONENT ||
			    kind == ICAL_VJOURNAL_COMPONENT) {
				list = g_slist_prepend (list, comp);
			} else {
				g_object_unref (comp);
			}
		}
	}

	g_list_free (objects);

	return g_slist_reverse (list);
}

/**
 * e_cal_backend_store_get_component_ids:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
GSList *
e_cal_backend_store_get_component_ids (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_component_ids != NULL, NULL);

	return class->get_component_ids (store);
}

/**
 * e_cal_backend_store_get_key_value:
 * @store: an #ECalBackendStore
 * @key: the key for the value to fetch
 *
 * Returns: (transfer none): The value matching @key
 *
 * Since: 2.28
 **/
const gchar *
e_cal_backend_store_get_key_value (ECalBackendStore *store,
                                   const gchar *key)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), NULL);
	g_return_val_if_fail (key != NULL, NULL);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_key_value != NULL, NULL);

	return class->get_key_value (store, key);
}

/**
 * e_cal_backend_store_put_key_value:
 * @store: an #ECalBackendStore
 * @key: the key for the value to set
 * @value: the value to set for @key
 *
 * Returns: whether @value was successfully set for @key
 *
 * Since: 2.28
 **/
gboolean
e_cal_backend_store_put_key_value (ECalBackendStore *store,
                                   const gchar *key,
                                   const gchar *value)
{
	ECalBackendStoreClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND_STORE (store), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->put_key_value != NULL, FALSE);

	return class->put_key_value (store, key, value);
}

/**
 * e_cal_backend_store_thaw_changes:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
void
e_cal_backend_store_thaw_changes (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_if_fail (E_IS_CAL_BACKEND_STORE (store));

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->thaw_changes != NULL);

	class->thaw_changes (store);
}

/**
 * e_cal_backend_store_freeze_changes:
 * @store: an #ECalBackendStore
 *
 * Since: 2.28
 **/
void
e_cal_backend_store_freeze_changes (ECalBackendStore *store)
{
	ECalBackendStoreClass *class;

	g_return_if_fail (E_IS_CAL_BACKEND_STORE (store));

	class = E_CAL_BACKEND_STORE_GET_CLASS (store);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->freeze_changes != NULL);

	class->freeze_changes (store);
}

/**
 * e_cal_backend_store_interval_tree_add_comp:
 * @store: an #ECalBackendStore
 * @comp: the #ECalComponent to add
 * @occurence_start: start time for @comp
 * @occurence_end: end time for @comp
 *
 * Since: 2.32
 **/
void
e_cal_backend_store_interval_tree_add_comp (ECalBackendStore *store,
                                            ECalComponent *comp,
                                            time_t occurence_start,
                                            time_t occurence_end)
{
	g_return_if_fail (E_IS_CAL_BACKEND_STORE (store));
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	e_intervaltree_insert (
		store->priv->intervaltree,
		occurence_start, occurence_end, comp);
}
