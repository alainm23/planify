/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 * SECTION: e-cal-cache
 * @include: libedata-cal/libedata-cal.h
 * @short_description: An #ECache descendant for calendars
 *
 * The #ECalCache is an API for storing and looking up calendar
 * components in an #ECache.
 *
 * The API is thread safe, in the similar way as the #ECache is.
 *
 * Any operations which can take a lot of time to complete (depending
 * on the size of your calendar) can be cancelled using a #GCancellable.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>
#include <sqlite3.h>

#include <libebackend/libebackend.h>
#include <libecal/libecal.h>

#include "e-cal-backend-sexp.h"

#include "e-cal-cache.h"

#define E_CAL_CACHE_VERSION		3

#define ECC_TABLE_TIMEZONES		"timezones"

#define ECC_COLUMN_OCCUR_START		"occur_start"
#define ECC_COLUMN_OCCUR_END		"occur_end"
#define ECC_COLUMN_DUE			"due"
#define ECC_COLUMN_COMPLETED		"completed"
#define ECC_COLUMN_SUMMARY		"summary"
#define ECC_COLUMN_COMMENT		"comment"
#define ECC_COLUMN_DESCRIPTION		"description"
#define ECC_COLUMN_LOCATION		"location"
#define ECC_COLUMN_ATTENDEES		"attendees"
#define ECC_COLUMN_ORGANIZER		"organizer"
#define ECC_COLUMN_CLASSIFICATION	"classification"
#define ECC_COLUMN_STATUS		"status"
#define ECC_COLUMN_PRIORITY		"priority"
#define ECC_COLUMN_PERCENT_COMPLETE	"percent_complete"
#define ECC_COLUMN_CATEGORIES		"categories"
#define ECC_COLUMN_HAS_ALARM		"has_alarm"
#define ECC_COLUMN_HAS_ATTACHMENT	"has_attachment"
#define ECC_COLUMN_HAS_START		"has_start"
#define ECC_COLUMN_HAS_RECURRENCES	"has_recurrences"
#define ECC_COLUMN_EXTRA		"bdata"

struct _ECalCachePrivate {
	gboolean initializing;

	GHashTable *loaded_timezones; /* gchar *tzid ~> icaltimezone * */
	GHashTable *modified_timezones; /* gchar *tzid ~> icaltimezone * */
	GRecMutex timezones_lock;

	GHashTable *sexps; /* gint ~> ECalBackendSExp * */
	GMutex sexps_lock;
};

enum {
	DUP_COMPONENT_REVISION,
	GET_TIMEZONE,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

/* Private function, not meant to be part of the public API */
void _e_cal_cache_remove_loaded_timezones (ECalCache *cal_cache);

static void ecc_timezone_cache_init (ETimezoneCacheInterface *iface);

G_DEFINE_TYPE_WITH_CODE (ECalCache, e_cal_cache, E_TYPE_CACHE,
			 G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL)
			 G_IMPLEMENT_INTERFACE (E_TYPE_TIMEZONE_CACHE, ecc_timezone_cache_init))

G_DEFINE_BOXED_TYPE (ECalCacheOfflineChange, e_cal_cache_offline_change, e_cal_cache_offline_change_copy, e_cal_cache_offline_change_free)
G_DEFINE_BOXED_TYPE (ECalCacheSearchData, e_cal_cache_search_data, e_cal_cache_search_data_copy, e_cal_cache_search_data_free)

/**
 * e_cal_cache_offline_change_new:
 * @uid: a unique component identifier
 * @rid: (nullable):  a Recurrence-ID of the component
 * @revision: (nullable): a revision of the component
 * @object: (nullable): component itself
 * @state: an #EOfflineState
 *
 * Creates a new #ECalCacheOfflineChange with the offline @state
 * information for the given @uid.
 *
 * Returns: (transfer full): A new #ECalCacheOfflineChange. Free it with
 *    e_cal_cache_offline_change_free() when no longer needed.
 *
 * Since: 3.26
 **/
ECalCacheOfflineChange *
e_cal_cache_offline_change_new (const gchar *uid,
				const gchar *rid,
				const gchar *revision,
				const gchar *object,
				EOfflineState state)
{
	ECalCacheOfflineChange *change;

	g_return_val_if_fail (uid != NULL, NULL);

	change = g_new0 (ECalCacheOfflineChange, 1);
	change->uid = g_strdup (uid);
	change->rid = g_strdup (rid);
	change->revision = g_strdup (revision);
	change->object = g_strdup (object);
	change->state = state;

	return change;
}

/**
 * e_cal_cache_offline_change_copy:
 * @change: (nullable): a source #ECalCacheOfflineChange to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @change. Free it with
 *    e_cal_cache_offline_change_free() when no longer needed.
 *    If the @change is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
ECalCacheOfflineChange *
e_cal_cache_offline_change_copy (const ECalCacheOfflineChange *change)
{
	if (!change)
		return NULL;

	return e_cal_cache_offline_change_new (change->uid, change->rid, change->revision, change->object, change->state);
}

/**
 * e_cal_cache_offline_change_free:
 * @change: (nullable): an #ECalCacheOfflineChange
 *
 * Frees the @change structure, previously allocated with e_cal_cache_offline_change_new()
 * or e_cal_cache_offline_change_copy().
 *
 * Since: 3.26
 **/
void
e_cal_cache_offline_change_free (gpointer change)
{
	ECalCacheOfflineChange *chng = change;

	if (chng) {
		g_free (chng->uid);
		g_free (chng->rid);
		g_free (chng->revision);
		g_free (chng->object);
		g_free (chng);
	}
}

/**
 * e_cal_cache_search_data_new:
 * @uid: a component UID; cannot be %NULL
 * @rid: (nullable): a component Recurrence-ID; can be %NULL
 * @object: the component as an iCal string; cannot be %NULL
 * @extra: (nullable): any extra data stored with the component, or %NULL
 *
 * Creates a new #ECalCacheSearchData prefilled with the given values.
 *
 * Returns: (transfer full): A new #ECalCacheSearchData. Free it with
 *    e_cal_cache_search_data_free() when no longer needed.
 *
 * Since: 3.26
 **/
ECalCacheSearchData *
e_cal_cache_search_data_new (const gchar *uid,
			     const gchar *rid,
			     const gchar *object,
			     const gchar *extra)
{
	ECalCacheSearchData *data;

	g_return_val_if_fail (uid != NULL, NULL);
	g_return_val_if_fail (object != NULL, NULL);

	data = g_new0 (ECalCacheSearchData, 1);
	data->uid = g_strdup (uid);
	data->rid = (rid && *rid) ? g_strdup (rid) : NULL;
	data->object = g_strdup (object);
	data->extra = g_strdup (extra);

	return data;
}

/**
 * e_cal_cache_search_data_copy:
 * @data: (nullable): a source #ECalCacheSearchData to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @data. Free it with
 *    e_cal_cache_search_data_free() when no longer needed.
 *    If the @data is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
ECalCacheSearchData *
e_cal_cache_search_data_copy (const ECalCacheSearchData *data)
{
	if (!data)
		return NULL;

	return e_cal_cache_search_data_new (data->uid, data->rid, data->object, data->extra);
}

/**
 * e_cal_cache_search_data_free:
 * @ptr: (nullable): an #ECalCacheSearchData
 *
 * Frees the @ptr structure, previously allocated with e_cal_cache_search_data_new()
 * or e_cal_cache_search_data_copy().
 *
 * Since: 3.26
 **/
void
e_cal_cache_search_data_free (gpointer ptr)
{
	ECalCacheSearchData *data = ptr;

	if (data) {
		g_free (data->uid);
		g_free (data->rid);
		g_free (data->object);
		g_free (data->extra);
		g_free (data);
	}
}

static gint
ecc_take_sexp_object (ECalCache *cal_cache,
		      ECalBackendSExp *sexp)
{
	gint sexp_id;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), 0);
	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), 0);

	g_mutex_lock (&cal_cache->priv->sexps_lock);

	sexp_id = GPOINTER_TO_INT (sexp);
	while (g_hash_table_contains (cal_cache->priv->sexps, GINT_TO_POINTER (sexp_id))) {
		sexp_id++;
	}

	g_hash_table_insert (cal_cache->priv->sexps, GINT_TO_POINTER (sexp_id), sexp);

	g_mutex_unlock (&cal_cache->priv->sexps_lock);

	return sexp_id;
}

static void
ecc_free_sexp_object (ECalCache *cal_cache,
		      gint sexp_id)
{
	g_return_if_fail (E_IS_CAL_CACHE (cal_cache));

	g_mutex_lock (&cal_cache->priv->sexps_lock);

	g_warn_if_fail (g_hash_table_remove (cal_cache->priv->sexps, GINT_TO_POINTER (sexp_id)));

	g_mutex_unlock (&cal_cache->priv->sexps_lock);
}

static ECalBackendSExp *
ecc_ref_sexp_object (ECalCache *cal_cache,
		     gint sexp_id)
{
	ECalBackendSExp *sexp;

	g_mutex_lock (&cal_cache->priv->sexps_lock);

	sexp = g_hash_table_lookup (cal_cache->priv->sexps, GINT_TO_POINTER (sexp_id));
	if (sexp)
		g_object_ref (sexp);

	g_mutex_unlock (&cal_cache->priv->sexps_lock);

	return sexp;
}

/* check_sexp(sexp_id, icalstring) */
static void
ecc_check_sexp_func (sqlite3_context *context,
		     gint argc,
		     sqlite3_value **argv)
{
	ECalCache *cal_cache;
	ECalBackendSExp *sexp_obj;
	gint sexp_id;
	const gchar *icalstring;

	g_return_if_fail (context != NULL);
	g_return_if_fail (argc == 2);

	cal_cache = sqlite3_user_data (context);
	sexp_id = sqlite3_value_int (argv[0]);
	icalstring = (const gchar *) sqlite3_value_text (argv[1]);

	if (!E_IS_CAL_CACHE (cal_cache) || !icalstring || !*icalstring) {
		sqlite3_result_int (context, 0);
		return;
	}

	sexp_obj = ecc_ref_sexp_object (cal_cache, sexp_id);
	if (!sexp_obj) {
		sqlite3_result_int (context, 0);
		return;
	}

	if (e_cal_backend_sexp_match_object (sexp_obj, icalstring, E_TIMEZONE_CACHE (cal_cache)))
		sqlite3_result_int (context, 1);
	else
		sqlite3_result_int (context, 0);

	g_object_unref (sexp_obj);
}

/* negate(x) */
static void
ecc_negate_func (sqlite3_context *context,
		 gint argc,
		 sqlite3_value **argv)
{
	gint val;

	g_return_if_fail (context != NULL);
	g_return_if_fail (argc == 1);

	val = sqlite3_value_int (argv[0]);
	sqlite3_result_int (context, !val);
}

static gboolean
e_cal_cache_get_string (ECache *cache,
			gint ncols,
			const gchar **column_names,
			const gchar **column_values,
			gpointer user_data)
{
	gchar **pvalue = user_data;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (pvalue != NULL, FALSE);

	if (!*pvalue)
		*pvalue = g_strdup (column_values[0]);

	return TRUE;
}

static gboolean
e_cal_cache_get_strings (ECache *cache,
			 gint ncols,
			 const gchar **column_names,
			 const gchar **column_values,
			 gpointer user_data)
{
	GSList **pstrings = user_data;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (pstrings != NULL, FALSE);

	*pstrings = g_slist_prepend (*pstrings, g_strdup (column_values[0]));

	return TRUE;
}

static void
e_cal_cache_populate_other_columns (ECalCache *cal_cache,
				    GSList **out_other_columns)
{
	g_return_if_fail (out_other_columns != NULL);

	*out_other_columns = NULL;

	#define add_column(name, type, idx_name) \
		*out_other_columns = g_slist_prepend (*out_other_columns, \
			e_cache_column_info_new (name, type, idx_name))

	add_column (ECC_COLUMN_OCCUR_START, "TEXT", "IDX_OCCURSTART");
	add_column (ECC_COLUMN_OCCUR_END, "TEXT", "IDX_OCCUREND");
	add_column (ECC_COLUMN_DUE, "TEXT", "IDX_DUE");
	add_column (ECC_COLUMN_COMPLETED, "TEXT", "IDX_COMPLETED");
	add_column (ECC_COLUMN_SUMMARY, "TEXT", "IDX_SUMMARY");
	add_column (ECC_COLUMN_COMMENT, "TEXT", NULL);
	add_column (ECC_COLUMN_DESCRIPTION, "TEXT", NULL);
	add_column (ECC_COLUMN_LOCATION, "TEXT", NULL);
	add_column (ECC_COLUMN_ATTENDEES, "TEXT", NULL);
	add_column (ECC_COLUMN_ORGANIZER, "TEXT", NULL);
	add_column (ECC_COLUMN_CLASSIFICATION, "TEXT", NULL);
	add_column (ECC_COLUMN_STATUS, "TEXT", NULL);
	add_column (ECC_COLUMN_PRIORITY, "INTEGER", NULL);
	add_column (ECC_COLUMN_PERCENT_COMPLETE, "INTEGER", NULL);
	add_column (ECC_COLUMN_CATEGORIES, "TEXT", NULL);
	add_column (ECC_COLUMN_HAS_ALARM, "INTEGER", NULL);
	add_column (ECC_COLUMN_HAS_ATTACHMENT, "INTEGER", NULL);
	add_column (ECC_COLUMN_HAS_START, "INTEGER", NULL);
	add_column (ECC_COLUMN_HAS_RECURRENCES, "INTEGER", NULL);
	add_column (ECC_COLUMN_EXTRA, "TEXT", NULL);

	#undef add_column

	*out_other_columns = g_slist_reverse (*out_other_columns);
}

static gchar *
ecc_encode_id_sql (const gchar *uid,
		   const gchar *rid)
{
	g_return_val_if_fail (uid != NULL, NULL);

	if (rid && *rid)
		return g_strdup_printf ("%s\n%s", uid, rid);

	return g_strdup (uid);
}

static gboolean
ecc_decode_id_sql (const gchar *id,
		   gchar **out_uid,
		   gchar **out_rid)
{
	gchar **split;

	g_return_val_if_fail (id != NULL, FALSE);
	g_return_val_if_fail (out_uid != NULL, FALSE);
	g_return_val_if_fail (out_rid != NULL, FALSE);

	*out_uid = NULL;
	*out_rid = NULL;

	if (!*id)
		return FALSE;

	split = g_strsplit (id, "\n", 2);

	if (!split || !split[0] || !*split[0]) {
		g_strfreev (split);
		return FALSE;
	}

	*out_uid = split[0];

	if (split[1])
		*out_rid = split[1];

	/* array elements are taken by the out arguments */
	g_free (split);

	return TRUE;
}

static gboolean
e_cal_cache_get_ids (ECache *cache,
		     gint ncols,
		     const gchar **column_names,
		     const gchar **column_values,
		     gpointer user_data)
{
	GSList **out_ids = user_data;
	gchar *uid = NULL, *rid = NULL;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (out_ids != NULL, FALSE);

	if (ecc_decode_id_sql (column_values[0], &uid, &rid)) {
		*out_ids = g_slist_prepend (*out_ids, e_cal_component_id_new (uid, rid));

		g_free (uid);
		g_free (rid);
	}

	return TRUE;
}

static icaltimezone *
ecc_resolve_tzid_cb (const gchar *tzid,
		     gpointer user_data)
{
	ECalCache *cal_cache = user_data;
	icaltimezone *zone = NULL;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	if (e_cal_cache_get_timezone (cal_cache, tzid, &zone, NULL, NULL) && zone)
		return zone;

	zone = icaltimezone_get_builtin_timezone (tzid);
	if (!zone)
		zone = icaltimezone_get_builtin_timezone_from_tzid (tzid);
	if (!zone) {
		tzid = e_cal_match_tzid (tzid);
		zone = icaltimezone_get_builtin_timezone (tzid);
	}

	if (!zone)
		zone = icaltimezone_get_builtin_timezone_from_tzid (tzid);

	return zone;
}

static gchar *
ecc_encode_itt_to_sql (struct icaltimetype itt)
{
	return g_strdup_printf ("%04d%02d%02d%02d%02d%02d",
		itt.year, itt.month, itt.day,
		itt.hour, itt.minute, itt.second);
}

static gchar *
ecc_encode_time_to_sql (ECalCache *cal_cache,
			const ECalComponentDateTime *dt)
{
	struct icaltimetype itt;
	icaltimezone *zone = NULL;

	if (!dt || !dt->value)
		return NULL;

	itt = *dt->value;

	if (!itt.is_date && !icaltime_is_utc (itt) && dt->tzid && *dt->tzid)
		zone = ecc_resolve_tzid_cb (dt->tzid, cal_cache);

	icaltimezone_convert_time (&itt, zone, icaltimezone_get_utc_timezone ());

	return ecc_encode_itt_to_sql (itt);
}

static gchar *
ecc_encode_timet_to_sql (ECalCache *cal_cache,
			 time_t tt)
{
	struct icaltimetype itt;

	if (tt <= 0)
		return NULL;

	itt = icaltime_from_timet_with_zone (tt, FALSE, icaltimezone_get_utc_timezone ());

	return ecc_encode_itt_to_sql (itt);
}

static gchar *
ecc_extract_text_list (const GSList *list)
{
	const GSList *link;
	GString *value;

	if (!list)
		return NULL;

	value = g_string_new ("");

	for (link = list; link; link = g_slist_next (link)) {
		ECalComponentText *text = link->data;

		if (text && text->value) {
			gchar *str;

			str = e_util_utf8_decompose (text->value);
			if (str)
				g_string_append (value, str);
			g_free (str);
		}
	}

	return g_string_free (value, !value->len);
}

static gchar *
ecc_extract_comment (ECalComponent *comp)
{
	GSList *list = NULL;
	gchar *value;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	e_cal_component_get_comment_list (comp, &list);
	value = ecc_extract_text_list (list);
	e_cal_component_free_text_list (list);

	return value;
}

static gchar *
ecc_extract_description (ECalComponent *comp)
{
	GSList *list = NULL;
	gchar *value;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	e_cal_component_get_description_list (comp, &list);
	value = ecc_extract_text_list (list);
	e_cal_component_free_text_list (list);

	return value;
}

static void
ecc_encode_mail (GString *out_value,
		 const gchar *in_cn,
		 const gchar *in_val)
{
	gchar *cn = NULL, *val = NULL;

	g_return_if_fail (in_val != NULL);

	if (in_cn && *in_cn)
		cn = e_util_utf8_decompose (in_cn);

	if (in_val) {
		const gchar *str = in_val;

		if (g_ascii_strncasecmp (str, "mailto:", 7) == 0) {
			str += 7;
		}

		if (*str)
			val = e_util_utf8_decompose (str);
	}

	if ((cn && *cn) || (val && *val)) {
		if (out_value->len)
			g_string_append_c (out_value, '\n');
		if (cn && *cn)
			g_string_append (out_value, cn);
		if (val && *val) {
			if (cn && *cn)
				g_string_append_c (out_value, '\t');
			g_string_append (out_value, val);
		}
	}

	g_free (cn);
	g_free (val);
}

static gchar *
ecc_extract_attendees (ECalComponent *comp)
{
	GSList *attendees = NULL, *link;
	GString *value;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	e_cal_component_get_attendee_list (comp, &attendees);
	if (!attendees)
		return NULL;

	value = g_string_new ("");

	for (link = attendees; link; link = g_slist_next (link)) {
		ECalComponentAttendee *att = link->data;

		if (!att)
			continue;

		ecc_encode_mail (value, att->cn, att->value);
	}

	e_cal_component_free_attendee_list (attendees);

	if (value->len) {
		/* This way it is encoded as:
		   <\n> <common-name> <\t> <mail> <\n> <common-name> <\t> <mail> <\n> ... </n> */
		g_string_prepend (value, "\n");
		g_string_append (value, "\n");
	}

	return g_string_free (value, !value->len);
}

static gchar *
ecc_extract_organizer (ECalComponent *comp)
{
	ECalComponentOrganizer org;
	GString *value;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	e_cal_component_get_organizer (comp, &org);

	if (!org.value)
		return NULL;

	value = g_string_new ("");

	ecc_encode_mail (value, org.cn, org.value);

	return g_string_free (value, !value->len);
}

static gchar *
ecc_extract_categories (ECalComponent *comp)
{
	GSList *categories, *link;
	GString *value;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	e_cal_component_get_categories_list (comp, &categories);

	if (!categories)
		return NULL;

	value = g_string_new ("");

	for (link = categories; link; link = g_slist_next (link)) {
		const gchar *category = link->data;

		if (category && *category) {
			if (value->len)
				g_string_append_c (value, '\n');
			g_string_append (value, category);
		}
	}

	e_cal_component_free_categories_list (categories);

	if (value->len) {
		/* This way it is encoded as:
		   <\n> <category> <\n> <category> <\n> ... </n>
		   which allows to search for exact category with: LIKE "%\ncategory\n%"
		*/
		g_string_prepend (value, "\n");
		g_string_append (value, "\n");
	}

	return g_string_free (value, !value->len);
}

static const gchar *
ecc_get_classification_as_string (ECalComponentClassification classification)
{
	const gchar *str;

	switch (classification) {
	case E_CAL_COMPONENT_CLASS_PUBLIC:
		str = "public";
		break;
	case E_CAL_COMPONENT_CLASS_PRIVATE:
		str = "private";
		break;
	case E_CAL_COMPONENT_CLASS_CONFIDENTIAL:
		str = "confidential";
		break;
	default:
		str = NULL;
		break;
	}

	return str;
}

static const gchar *
ecc_get_status_as_string (icalproperty_status status)
{
	switch (status) {
	case ICAL_STATUS_NONE:
		return "not started";
	case ICAL_STATUS_COMPLETED:
		return "completed";
	case ICAL_STATUS_CANCELLED:
		return "cancelled";
	case ICAL_STATUS_INPROCESS:
		return "in progress";
	case ICAL_STATUS_NEEDSACTION:
		return "needs action";
	case ICAL_STATUS_TENTATIVE:
		return "tentative";
	case ICAL_STATUS_CONFIRMED:
		return "confirmed";
	case ICAL_STATUS_DRAFT:
		return "draft";
	case ICAL_STATUS_FINAL:
		return "final";
	case ICAL_STATUS_SUBMITTED:
		return "submitted";
	case ICAL_STATUS_PENDING:
		return "pending";
	case ICAL_STATUS_FAILED:
		return "failed";
#ifdef HAVE_ICAL_STATUS_DELETED
	case ICAL_STATUS_DELETED:
		return "deleted";
#endif
	case ICAL_STATUS_X:
		break;
	}

	return NULL;
}

static void
ecc_fill_other_columns (ECalCache *cal_cache,
			ECacheColumnValues *other_columns,
			ECalComponent *comp)
{
	time_t occur_start = -1, occur_end = -1;
	ECalComponentDateTime dt;
	ECalComponentText text;
	ECalComponentClassification classification = E_CAL_COMPONENT_CLASS_PUBLIC;
	icalcomponent *icalcomp;
	icalproperty_status status = ICAL_STATUS_NONE;
	struct icaltimetype *itt;
	const gchar *str = NULL;
	gint *pint = NULL;
	gboolean has;

	g_return_if_fail (E_IS_CAL_CACHE (cal_cache));
	g_return_if_fail (other_columns != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	#define add_value(_col, _val) e_cache_column_values_take_value (other_columns, _col, _val)

	icalcomp = e_cal_component_get_icalcomponent (comp);

	e_cal_util_get_component_occur_times (
		comp, &occur_start, &occur_end,
		ecc_resolve_tzid_cb, cal_cache, icaltimezone_get_utc_timezone (),
		icalcomponent_isa (icalcomp));

	e_cal_component_get_dtstart (comp, &dt);
	add_value (ECC_COLUMN_OCCUR_START, dt.value && ((dt.tzid && *dt.tzid) || icaltime_is_utc (*dt.value)) ? ecc_encode_timet_to_sql (cal_cache, occur_start) : NULL);

	has = dt.value != NULL;
	add_value (ECC_COLUMN_HAS_START, g_strdup (has ? "1" : "0"));
	e_cal_component_free_datetime (&dt);

	e_cal_component_get_dtend (comp, &dt);
	add_value (ECC_COLUMN_OCCUR_END, dt.value && ((dt.tzid && *dt.tzid) || icaltime_is_utc (*dt.value)) ? ecc_encode_timet_to_sql (cal_cache, occur_end) : NULL);
	e_cal_component_free_datetime (&dt);

	e_cal_component_get_due (comp, &dt);
	add_value (ECC_COLUMN_DUE, ecc_encode_time_to_sql (cal_cache, &dt));
	e_cal_component_free_datetime (&dt);

	itt = NULL;
	e_cal_component_get_completed (comp, &itt);
	add_value (ECC_COLUMN_COMPLETED, itt ? ecc_encode_itt_to_sql (*itt) : NULL);
	if (itt)
		e_cal_component_free_icaltimetype (itt);

	text.value = NULL;
	e_cal_component_get_summary (comp, &text);
	add_value (ECC_COLUMN_SUMMARY, text.value ? e_util_utf8_decompose (text.value) : NULL);

	e_cal_component_get_location (comp, &str);
	add_value (ECC_COLUMN_LOCATION, str ? e_util_utf8_decompose (str) : NULL);

	e_cal_component_get_classification (comp, &classification);
	add_value (ECC_COLUMN_CLASSIFICATION, g_strdup (ecc_get_classification_as_string (classification)));

	e_cal_component_get_status (comp, &status);
	add_value (ECC_COLUMN_STATUS, g_strdup (ecc_get_status_as_string (status)));

	e_cal_component_get_priority (comp, &pint);
	add_value (ECC_COLUMN_PRIORITY, pint && *pint ? g_strdup_printf ("%d", *pint) : NULL);
	if (pint) {
		e_cal_component_free_priority (pint);
		pint = NULL;
	}

	e_cal_component_get_percent (comp, &pint);
	add_value (ECC_COLUMN_PERCENT_COMPLETE, pint && *pint ? g_strdup_printf ("%d", *pint) : NULL);
	if (pint) {
		e_cal_component_free_percent (pint);
		pint = NULL;
	}

	has = e_cal_component_has_alarms (comp);
	add_value (ECC_COLUMN_HAS_ALARM, g_strdup (has ? "1" : "0"));

	has = e_cal_component_has_attachments (comp);
	add_value (ECC_COLUMN_HAS_ATTACHMENT, g_strdup (has ? "1" : "0"));

	has = e_cal_component_has_recurrences (comp) ||
	      e_cal_component_is_instance (comp);
	add_value (ECC_COLUMN_HAS_RECURRENCES, g_strdup (has ? "1" : "0"));

	add_value (ECC_COLUMN_COMMENT, ecc_extract_comment (comp));
	add_value (ECC_COLUMN_DESCRIPTION, ecc_extract_description (comp));
	add_value (ECC_COLUMN_ATTENDEES, ecc_extract_attendees (comp));
	add_value (ECC_COLUMN_ORGANIZER, ecc_extract_organizer (comp));
	add_value (ECC_COLUMN_CATEGORIES, ecc_extract_categories (comp));
}

static gchar *
ecc_range_as_where_clause (const gchar *start_str,
			   const gchar *end_str)
{
	GString *stmt;

	if (!start_str && !end_str)
		return NULL;

	stmt = g_string_sized_new (64);

	if (start_str) {
		e_cache_sqlite_stmt_append_printf (stmt,
			"(" ECC_COLUMN_OCCUR_END " IS NULL OR " ECC_COLUMN_OCCUR_END ">=%Q)",
			start_str);
	}

	if (end_str) {
		if (start_str) {
			g_string_prepend (stmt, "(");
			g_string_append (stmt, " AND ");
		}

		e_cache_sqlite_stmt_append_printf (stmt,
			"(" ECC_COLUMN_OCCUR_START " IS NULL OR " ECC_COLUMN_OCCUR_START "<=%Q)",
			end_str);

		if (start_str)
			g_string_append (stmt, ")");
	}

	return g_string_free (stmt, FALSE);
}

typedef struct _SExpToSqlContext {
	ECalCache *cal_cache;
	guint not_level;
	gboolean requires_check_sexp;
} SExpToSqlContext;

static ESExpResult *
ecc_sexp_func_and_or (ESExp *esexp,
		      gint argc,
		      ESExpTerm **argv,
		      gpointer user_data,
		      const gchar *oper)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result, *r1;
	GString *stmt;
	gint ii;

	g_return_val_if_fail (ctx != NULL, NULL);

	stmt = g_string_new ("(");

	for (ii = 0; ii < argc; ii++) {
		r1 = e_sexp_term_eval (esexp, argv[ii]);

		if (r1 && r1->type == ESEXP_RES_STRING && r1->value.string) {
			if (stmt->len > 1)
				g_string_append_printf (stmt, " %s ", oper);

			g_string_append_printf (stmt, "(%s)", r1->value.string);
		} else {
			ctx->requires_check_sexp = TRUE;
		}

		e_sexp_result_free (esexp, r1);
	}

	if (stmt->len == 1 && !ctx->not_level) {
		if (g_str_equal (oper, "AND"))
			g_string_append_c (stmt, '1');
		else
			g_string_append_c (stmt, '0');
	}

	g_string_append_c (stmt, ')');

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_string_free (stmt, stmt->len <= 2);

	return result;
}

static ESExpResult *
ecc_sexp_func_and (ESExp *esexp,
		   gint argc,
		   ESExpTerm **argv,
		   gpointer user_data)
{
	return ecc_sexp_func_and_or (esexp, argc, argv, user_data, "AND");
}

static ESExpResult *
ecc_sexp_func_or (ESExp *esexp,
		   gint argc,
		   ESExpTerm **argv,
		   gpointer user_data)
{
	return ecc_sexp_func_and_or (esexp, argc, argv, user_data, "OR");
}

static ESExpResult *
ecc_sexp_func_not (ESExp *esexp,
		   gint argc,
		   ESExpTerm **argv,
		   gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result, *r1;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc != 1)
		return NULL;

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);

	ctx->not_level++;

	r1 = e_sexp_term_eval (esexp, argv[0]);

	ctx->not_level--;

	if (r1 && r1->type == ESEXP_RES_STRING && r1->value.string) {
		result->value.string = g_strdup_printf ("negate(%s)", r1->value.string);
	} else {
		ctx->requires_check_sexp = TRUE;
	}

	e_sexp_result_free (esexp, r1);

	return result;
}

static ESExpResult *
ecc_sexp_func_uid (ESExp *esexp,
		   gint argc,
		   ESExpResult **argv,
		   gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;
	const gchar *uid;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc != 1 ||
	    argv[0]->type != ESEXP_RES_STRING) {
		return NULL;
	}

	uid = argv[0]->value.string;

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);

	if (!uid) {
		result->value.string = g_strdup (E_CACHE_COLUMN_UID " IS NULL");
	} else {
		gchar *stmt;

		stmt = e_cache_sqlite_stmt_printf (E_CACHE_COLUMN_UID "=%Q OR " E_CACHE_COLUMN_UID " LIKE '%q\n%%'", uid, uid);

		result->value.string = g_strdup (stmt);

		e_cache_sqlite_stmt_free (stmt);
	}

	return result;
}

static ESExpResult *
ecc_sexp_func_occur_in_time_range (ESExp *esexp,
				   gint argc,
				   ESExpResult **argv,
				   gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	if ((argc != 2 && argc != 3) ||
	    argv[0]->type != ESEXP_RES_TIME ||
	    argv[1]->type != ESEXP_RES_TIME ||
	    (argc == 3 && argv[2]->type != ESEXP_RES_STRING)) {
		return NULL;
	}

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);

	if (!ctx->not_level) {
		struct icaltimetype itt_start, itt_end;
		gchar *start_str, *end_str;

		/* The default zone argument, if any, is ignored here */
		itt_start = icaltime_from_timet_with_zone (argv[0]->value.time, 0, NULL);
		itt_end = icaltime_from_timet_with_zone (argv[1]->value.time, 0, NULL);

		start_str = ecc_encode_itt_to_sql (itt_start);
		end_str = ecc_encode_itt_to_sql (itt_end);

		result->value.string = ecc_range_as_where_clause (start_str, end_str);

		if (!result->value.string)
			result->value.string = g_strdup ("1=1");

		g_free (start_str);
		g_free (end_str);
	} else {
		result->value.string = NULL;
	}

	ctx->requires_check_sexp = TRUE;

	return result;
}

static ESExpResult *
ecc_sexp_func_due_in_time_range (ESExp *esexp,
				 gint argc,
				 ESExpResult **argv,
				 gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;
	gchar *start_str, *end_str;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc != 2 ||
	    argv[0]->type != ESEXP_RES_TIME ||
	    argv[1]->type != ESEXP_RES_TIME) {
		return NULL;
	}

	start_str = ecc_encode_timet_to_sql (ctx->cal_cache, argv[0]->value.time);
	end_str = ecc_encode_timet_to_sql (ctx->cal_cache, argv[1]->value.time);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s>='%s' AND %s<='%s')",
		ECC_COLUMN_DUE, ECC_COLUMN_DUE, start_str,
		ECC_COLUMN_DUE, end_str);

	g_free (start_str);
	g_free (end_str);

	return result;
}

static ESExpResult *
ecc_sexp_func_contains (ESExp *esexp,
			gint argc,
			ESExpResult **argv,
			gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;
	const gchar *field, *column = NULL;
	gchar *str;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc != 2 ||
	    argv[0]->type != ESEXP_RES_STRING ||
	    argv[1]->type != ESEXP_RES_STRING) {
		return NULL;
	}

	field = argv[0]->value.string;
	str = e_util_utf8_decompose (argv[1]->value.string);

	if (g_str_equal (field, "comment"))
		column = ECC_COLUMN_COMMENT;
	else if (g_str_equal (field, "description"))
		column = ECC_COLUMN_DESCRIPTION;
	else if (g_str_equal (field, "summary"))
		column = ECC_COLUMN_SUMMARY;
	else if (g_str_equal (field, "location"))
		column = ECC_COLUMN_LOCATION;
	else if (g_str_equal (field, "attendee"))
		column = ECC_COLUMN_ATTENDEES;
	else if (g_str_equal (field, "organizer"))
		column = ECC_COLUMN_ORGANIZER;
	else if (g_str_equal (field, "classification"))
		column = ECC_COLUMN_CLASSIFICATION;
	else if (g_str_equal (field, "status"))
		column = ECC_COLUMN_STATUS;
	else if (g_str_equal (field, "priority"))
		column = ECC_COLUMN_PRIORITY;

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);

	/* everything matches an empty string */
	if (!str || !*str) {
		result->value.string = g_strdup ("1=1");
	} else if (column) {
		gchar *stmt;

		if (g_str_equal (column, ECC_COLUMN_PRIORITY)) {
			if (g_ascii_strcasecmp (str, "UNDEFINED") == 0)
				stmt = e_cache_sqlite_stmt_printf ("%s IS NULL", column);
			else if (g_ascii_strcasecmp (str, "HIGH") == 0)
				stmt = e_cache_sqlite_stmt_printf ("%s<=4", column);
			else if (g_ascii_strcasecmp (str, "NORMAL") == 0)
				stmt = e_cache_sqlite_stmt_printf ("%s=5", column);
			else if (g_ascii_strcasecmp (str, "LOW") == 0)
				stmt = e_cache_sqlite_stmt_printf ("%s>5", column);
			else
				stmt = e_cache_sqlite_stmt_printf ("%s IS NOT NULL", column);
		} else if (g_str_equal (column, ECC_COLUMN_CLASSIFICATION) ||
			   g_str_equal (column, ECC_COLUMN_STATUS)) {
			stmt = e_cache_sqlite_stmt_printf ("%s='%q'", column, str);
		} else {
			stmt = e_cache_sqlite_stmt_printf ("%s LIKE '%%%q%%'", column, str);
		}
		result->value.string = g_strdup (stmt);
		e_cache_sqlite_stmt_free (stmt);
	} else if (g_str_equal (field, "any")) {
		GString *stmt;

		stmt = g_string_new ("");

		e_cache_sqlite_stmt_append_printf (stmt, "(%s LIKE '%%%q%%'", ECC_COLUMN_COMMENT, str);
		e_cache_sqlite_stmt_append_printf (stmt, " OR %s LIKE '%%%q%%'", ECC_COLUMN_DESCRIPTION, str);
		e_cache_sqlite_stmt_append_printf (stmt, " OR %s LIKE '%%%q%%'", ECC_COLUMN_SUMMARY, str);
		e_cache_sqlite_stmt_append_printf (stmt, " OR %s LIKE '%%%q%%')", ECC_COLUMN_LOCATION, str);

		result->value.string = g_string_free (stmt, FALSE);
	} else {
		ctx->requires_check_sexp = TRUE;
	}

	g_free (str);

	return result;
}

static ESExpResult *
ecc_sexp_func_has_start (ESExp *esexp,
			 gint argc,
			 ESExpResult **argv,
			 gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s=1)",
		ECC_COLUMN_HAS_START, ECC_COLUMN_HAS_START);

	return result;
}

static ESExpResult *
ecc_sexp_func_has_alarms (ESExp *esexp,
			  gint argc,
			  ESExpResult **argv,
			  gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s=1)",
		ECC_COLUMN_HAS_ALARM, ECC_COLUMN_HAS_ALARM);

	return result;
}

static ESExpResult *
ecc_sexp_func_has_alarms_in_range (ESExp *esexp,
				   gint argc,
				   ESExpResult **argv,
				   gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	ctx->requires_check_sexp = TRUE;

	if (!ctx->not_level)
		return ecc_sexp_func_has_alarms (esexp, argc, argv, user_data);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = NULL;

	return result;
}

static ESExpResult *
ecc_sexp_func_has_recurrences (ESExp *esexp,
			       gint argc,
			       ESExpResult **argv,
			       gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s=1)",
		ECC_COLUMN_HAS_RECURRENCES, ECC_COLUMN_HAS_RECURRENCES);

	return result;
}

/* (has-categories? STR+)
 * (has-categories? #f)
 */
static ESExpResult *
ecc_sexp_func_has_categories (ESExp *esexp,
			      gint argc,
			      ESExpResult **argv,
			      gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;
	gboolean unfiled;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc < 1)
		return NULL;

	unfiled = argc == 1 && argv[0]->type == ESEXP_RES_BOOL;

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);

	if (unfiled) {
		result->value.string = g_strdup_printf ("%s IS NULL",
			ECC_COLUMN_CATEGORIES);
	} else {
		GString *tmp;
		gint ii;

		tmp = g_string_new ("(" ECC_COLUMN_CATEGORIES " NOT NULL");

		for (ii = 0; ii < argc; ii++) {
			if (argv[ii]->type != ESEXP_RES_STRING) {
				g_warn_if_reached ();
				continue;
			}

			e_cache_sqlite_stmt_append_printf (tmp, " AND " ECC_COLUMN_CATEGORIES " LIKE '%%\n%q\n%%'",
				argv[ii]->value.string);
		}

		g_string_append_c (tmp, ')');

		result->value.string = g_string_free (tmp, FALSE);
	}

	return result;
}

static ESExpResult *
ecc_sexp_func_is_completed (ESExp *esexp,
			    gint argc,
			    ESExpResult **argv,
			    gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("%s NOT NULL OR (%s NOT NULL AND %s='%s')",
		ECC_COLUMN_COMPLETED, ECC_COLUMN_STATUS, ECC_COLUMN_STATUS, ecc_get_status_as_string (ICAL_STATUS_COMPLETED));

	return result;
}

static ESExpResult *
ecc_sexp_func_completed_before (ESExp *esexp,
				gint argc,
				ESExpResult **argv,
				gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	gchar *tmp;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	if (argc != 1 ||
	    argv[0]->type != ESEXP_RES_TIME) {
		return NULL;
	}

	tmp = ecc_encode_timet_to_sql (ctx->cal_cache, argv[0]->value.time);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s<'%s')",
		ECC_COLUMN_COMPLETED, ECC_COLUMN_COMPLETED, tmp);

	g_free (tmp);

	return result;
}

static ESExpResult *
ecc_sexp_func_has_attachment (ESExp *esexp,
			      gint argc,
			      ESExpResult **argv,
			      gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup_printf ("(%s NOT NULL AND %s=1)",
		ECC_COLUMN_HAS_ATTACHMENT, ECC_COLUMN_HAS_ATTACHMENT);

	return result;
}

static ESExpResult *
ecc_sexp_func_percent_complete (ESExp *esexp,
				gint argc,
				ESExpResult **argv,
				gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = g_strdup (ECC_COLUMN_PERCENT_COMPLETE);

	return result;
}

/* check_sexp(sexp_id, icalstring); that's a fallback for anything
   not being part of the summary */
static ESExpResult *
ecc_sexp_func_check_sexp (ESExp *esexp,
			  gint argc,
			  ESExpResult **argv,
			  gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = NULL;

	ctx->requires_check_sexp = TRUE;

	return result;
}

static ESExpResult *
ecc_sexp_func_icheck_sexp (ESExp *esexp,
			   gint argc,
			   ESExpTerm **argv,
			   gpointer user_data)
{
	SExpToSqlContext *ctx = user_data;
	ESExpResult *result;

	g_return_val_if_fail (ctx != NULL, NULL);

	result = e_sexp_result_new (esexp, ESEXP_RES_STRING);
	result->value.string = NULL;

	ctx->requires_check_sexp = TRUE;

	return result;
}

static struct {
	const gchar *name;
	gpointer func;
	gint type; /* 1 for term-function, 0 for result-function */
} symbols[] = {
	{ "and",			ecc_sexp_func_and, 1 },
	{ "or",				ecc_sexp_func_or, 1 },
	{ "not",			ecc_sexp_func_not, 1 },
	{ "<",				ecc_sexp_func_icheck_sexp, 1 },
	{ ">",				ecc_sexp_func_icheck_sexp, 1 },
	{ "=",				ecc_sexp_func_icheck_sexp, 1 },
	{ "+",				ecc_sexp_func_check_sexp, 0 },
	{ "-",				ecc_sexp_func_check_sexp, 0 },
	{ "cast-int",			ecc_sexp_func_check_sexp, 0 },
	{ "cast-string",		ecc_sexp_func_check_sexp, 0 },
	{ "if",				ecc_sexp_func_icheck_sexp, 1 },
	{ "begin",			ecc_sexp_func_icheck_sexp, 1 },

	/* Time-related functions */
	{ "time-now",			e_cal_backend_sexp_func_time_now, 0 },
	{ "make-time",			e_cal_backend_sexp_func_make_time, 0 },
	{ "time-add-day",		e_cal_backend_sexp_func_time_add_day, 0 },
	{ "time-day-begin",		e_cal_backend_sexp_func_time_day_begin, 0 },
	{ "time-day-end",		e_cal_backend_sexp_func_time_day_end, 0 },

	/* Component-related functions */
	{ "uid?",			ecc_sexp_func_uid, 0 },
	{ "occur-in-time-range?",	ecc_sexp_func_occur_in_time_range, 0 },
	{ "due-in-time-range?",		ecc_sexp_func_due_in_time_range, 0 },
	{ "contains?",			ecc_sexp_func_contains, 0 },
	{ "has-start?",			ecc_sexp_func_has_start, 0 },
	{ "has-alarms?",		ecc_sexp_func_has_alarms, 0 },
	{ "has-alarms-in-range?",	ecc_sexp_func_has_alarms_in_range, 0 },
	{ "has-recurrences?",		ecc_sexp_func_has_recurrences, 0 },
	{ "has-categories?",		ecc_sexp_func_has_categories, 0 },
	{ "is-completed?",		ecc_sexp_func_is_completed, 0 },
	{ "completed-before?",		ecc_sexp_func_completed_before, 0 },
	{ "has-attachments?",		ecc_sexp_func_has_attachment, 0 },
	{ "percent-complete?",		ecc_sexp_func_percent_complete, 0 },
	{ "occurrences-count?",		ecc_sexp_func_check_sexp, 0 }
};

static gboolean
ecc_convert_sexp_to_sql (ECalCache *cal_cache,
			 const gchar *sexp_str,
			 gint sexp_id,
			 gchar **out_where_clause,
			 GCancellable *cancellable,
			 GError **error)
{
	SExpToSqlContext ctx;
	ESExp *sexp_parser;
	gint esexp_error, ii;
	gboolean success = FALSE;

	g_return_val_if_fail (out_where_clause != NULL, FALSE);

	*out_where_clause = NULL;

	/* Include everything */
	if (!sexp_str || !*sexp_str || g_strcmp0 (sexp_str, "#t") == 0)
		return TRUE;

	ctx.cal_cache = cal_cache;
	ctx.not_level = 0;
	ctx.requires_check_sexp = FALSE;

	sexp_parser = e_sexp_new ();

	for (ii = 0; ii < G_N_ELEMENTS (symbols); ii++) {
		if (symbols[ii].type == 1) {
			e_sexp_add_ifunction (sexp_parser, 0, symbols[ii].name, symbols[ii].func, &ctx);
		} else {
			e_sexp_add_function (sexp_parser, 0, symbols[ii].name, symbols[ii].func, &ctx);
		}
	}

	e_sexp_input_text (sexp_parser, sexp_str, strlen (sexp_str));
	esexp_error = e_sexp_parse (sexp_parser);

	if (esexp_error != -1) {
		ESExpResult *result;

		result = e_sexp_eval (sexp_parser);

		if (result) {
			if (result->type == ESEXP_RES_STRING) {
				if (ctx.requires_check_sexp) {
					if (result->value.string) {
						*out_where_clause = g_strdup_printf ("((%s) AND check_sexp(%d,%s))",
							result->value.string, sexp_id, E_CACHE_COLUMN_OBJECT);
					} else {
						*out_where_clause = g_strdup_printf ("check_sexp(%d,%s)",
							sexp_id, E_CACHE_COLUMN_OBJECT);
					}
				} else {
					/* Just steal the string from the ESExpResult */
					*out_where_clause = result->value.string;
					result->value.string = NULL;
				}
				success = TRUE;
			}
		}

		e_sexp_result_free (sexp_parser, result);
	}

	g_object_unref (sexp_parser);

	if (!success) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
			_("Invalid query: %s"), sexp_str);
	}

	return success;
}

typedef struct {
	gint extra_idx;
	ECalCacheSearchFunc func;
	gpointer func_user_data;
} SearchContext;

static gboolean
ecc_search_foreach_cb (ECache *cache,
		       const gchar *uid,
		       const gchar *revision,
		       const gchar *object,
		       EOfflineState offline_state,
		       gint ncols,
		       const gchar *column_names[],
		       const gchar *column_values[],
		       gpointer user_data)
{
	SearchContext *ctx = user_data;
	gchar *comp_uid = NULL, *comp_rid = NULL;
	gboolean can_continue;

	g_return_val_if_fail (ctx != NULL, FALSE);
	g_return_val_if_fail (ctx->func != NULL, FALSE);

	if (ctx->extra_idx == -1) {
		gint ii;

		for (ii = 0; ii < ncols; ii++) {
			if (column_names[ii] && g_ascii_strcasecmp (column_names[ii], ECC_COLUMN_EXTRA) == 0) {
				ctx->extra_idx = ii;
				break;
			}
		}
	}

	g_return_val_if_fail (ctx->extra_idx != -1, FALSE);

	g_warn_if_fail (ecc_decode_id_sql (uid, &comp_uid, &comp_rid));

	/* This type-cast for performance reason */
	can_continue = ctx->func ((ECalCache *) cache, comp_uid, comp_rid, revision, object,
		column_values[ctx->extra_idx], offline_state, ctx->func_user_data);

	g_free (comp_uid);
	g_free (comp_rid);

	return can_continue;
}

static gboolean
ecc_search_internal (ECalCache *cal_cache,
		     const gchar *sexp_str,
		     gint sexp_id,
		     ECalCacheSearchFunc func,
		     gpointer user_data,
		     GCancellable *cancellable,
		     GError **error)
{
	gchar *where_clause = NULL;
	SearchContext ctx;
	gboolean success;

	if (!ecc_convert_sexp_to_sql (cal_cache, sexp_str, sexp_id, &where_clause, cancellable, error)) {
		return FALSE;
	}

	ctx.extra_idx = -1;
	ctx.func = func;
	ctx.func_user_data = user_data;

	success = e_cache_foreach (E_CACHE (cal_cache), E_CACHE_EXCLUDE_DELETED,
		where_clause, ecc_search_foreach_cb, &ctx,
		cancellable, error);

	g_free (where_clause);

	return success;
}

static gboolean
ecc_init_aux_tables (ECalCache *cal_cache,
		     GCancellable *cancellable,
		     GError **error)
{
	gchar *stmt;
	gboolean success;

	stmt = e_cache_sqlite_stmt_printf ("CREATE TABLE IF NOT EXISTS %Q ("
		"tzid TEXT PRIMARY KEY, "
		"zone TEXT, "
		"refs INTEGER)",
		ECC_TABLE_TIMEZONES);
	success = e_cache_sqlite_exec (E_CACHE (cal_cache), stmt, cancellable, error);
	e_cache_sqlite_stmt_free (stmt);

	return success;
}

static gboolean
ecc_init_sqlite_functions (ECalCache *cal_cache,
			   GCancellable *cancellable,
			   GError **error)
{
	gint ret;
	gpointer sqlitedb;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	sqlitedb = e_cache_get_sqlitedb (E_CACHE (cal_cache));
	g_return_val_if_fail (sqlitedb != NULL, FALSE);

	/* check_sexp(sexp_id, icalstring) */
	ret = sqlite3_create_function (sqlitedb,
		"check_sexp", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC,
		cal_cache, ecc_check_sexp_func,
		NULL, NULL);

	if (ret == SQLITE_OK) {
		/* negate(x) */
		ret = sqlite3_create_function (sqlitedb,
			"negate", 1, SQLITE_UTF8 | SQLITE_DETERMINISTIC,
			NULL, ecc_negate_func,
			NULL, NULL);
	}

	if (ret != SQLITE_OK) {
		const gchar *errmsg = sqlite3_errmsg (sqlitedb);

		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_ENGINE,
			_("Failed to create SQLite function, error code “%d”: %s"),
			ret, errmsg ? errmsg : _("Unknown error"));

		return FALSE;
	}

	return TRUE;
}

typedef struct _ComponentInfo {
	GSList *online_comps; /* ECalComponent * */
	GSList *online_extras; /* gchar * */
	GSList *offline_comps; /* ECalComponent * */
	GSList *offline_extras; /* gchar * */
} ComponentInfo;

static void
component_info_clear (ComponentInfo *ci)
{
	if (ci) {
		g_slist_free_full (ci->online_comps, g_object_unref);
		g_slist_free_full (ci->online_extras, g_free);
		g_slist_free_full (ci->offline_comps, g_object_unref);
		g_slist_free_full (ci->offline_extras, g_free);
	}
}

static gboolean
cal_cache_gather_v1_affected_cb (ECalCache *cal_cache,
				 const gchar *uid,
				 const gchar *rid,
				 const gchar *revision,
				 const gchar *object,
				 const gchar *extra,
				 EOfflineState offline_state,
				 gpointer user_data)
{
	ComponentInfo *ci = user_data;
	ECalComponent *comp;
	ECalComponentDateTime dt;

	g_return_val_if_fail (object != NULL, FALSE);
	g_return_val_if_fail (ci != NULL, FALSE);

	if (offline_state == E_OFFLINE_STATE_LOCALLY_DELETED)
		return TRUE;

	comp = e_cal_component_new_from_string (object);
	if (!comp)
		return TRUE;

	e_cal_component_get_due (comp, &dt);

	if (dt.value && !icaltime_is_utc (*dt.value) && (!dt.tzid || !*dt.tzid)) {
		GSList **pcomps, **pextras;

		if (offline_state == E_OFFLINE_STATE_SYNCED) {
			pcomps = &ci->online_comps;
			pextras = &ci->online_extras;
		} else {
			pcomps = &ci->offline_comps;
			pextras = &ci->offline_extras;
		}

		*pcomps = g_slist_prepend (*pcomps, g_object_ref (comp));
		*pextras = g_slist_prepend (*pextras, g_strdup (extra));
	}

	e_cal_component_free_datetime (&dt);
	g_object_unref (comp);

	return TRUE;
}

static icaltimezone *
ecc_timezone_from_string (const gchar *icalstring)
{
	icalcomponent *component;

	g_return_val_if_fail (icalstring != NULL, NULL);

	component = icalcomponent_new_from_string (icalstring);
	if (component) {
		icaltimezone *zone;

		zone = icaltimezone_new ();
		if (!icaltimezone_set_component (zone, component)) {
			icalcomponent_free (component);
			icaltimezone_free (zone, 1);
		} else {
			return zone;
		}
	}

	return NULL;
}

static gboolean
ecc_tzid_is_libical_builtin (const gchar *tzid)
{
	const gchar *matched_tzid;

	if (!tzid || !*tzid || icaltimezone_get_builtin_timezone (tzid))
		return TRUE;

	matched_tzid = e_cal_match_tzid (tzid);
	return matched_tzid && icaltimezone_get_builtin_timezone_from_tzid (matched_tzid);
}

typedef struct _TimezoneMigrationData {
	icaltimezone *zone;
	guint refs;
	gboolean is_deref; /* TRUE when should dereference, instead of reference, the timezone with refs references */
} TimezoneMigrationData;

static void
timezone_migration_data_free (gpointer ptr)
{
	TimezoneMigrationData *tmd = ptr;

	if (tmd) {
		if (tmd->zone)
			icaltimezone_free (tmd->zone, 1);
		g_free (tmd);
	}
}

typedef struct _CountTimezonesData {
	ECalCache *cal_cache;
	GHashTable *timezones;
	gboolean is_inc;
	GCancellable *cancellable;
} CountTimezonesData;

static void
ecc_count_timezones_in_icalcomp_cb (icalparameter *param,
				    gpointer user_data)
{
	CountTimezonesData *ctd = user_data;
	TimezoneMigrationData *tmd;
	const gchar *tzid;

	g_return_if_fail (ctd != NULL);

	tzid = icalparameter_get_tzid (param);
	if (!tzid)
		return;

	tmd = g_hash_table_lookup (ctd->timezones, tzid);
	if (tmd) {
		if (ctd->is_inc) {
			if (tmd->is_deref) {
				if (!tmd->refs) {
					tmd->refs++;
					tmd->is_deref = FALSE;
				} else {
					tmd->refs--;
				}
			} else {
				tmd->refs++;
			}
		} else {
			if (tmd->is_deref) {
				tmd->refs++;
			} else {
				if (!tmd->refs) {
					tmd->refs++;
					tmd->is_deref = TRUE;
				} else {
					tmd->refs--;
				}
			}
		}
	} else if (!ecc_tzid_is_libical_builtin (tzid)) {
		icaltimezone *zone = NULL;

		g_signal_emit (ctd->cal_cache, signals[GET_TIMEZONE], 0, tzid, &zone);

		if (!zone && !e_cal_cache_get_timezone (ctd->cal_cache, tzid, &zone, ctd->cancellable, NULL))
			zone = NULL;

		/* Make a copy of it, it's not owned by the caller, but by the originator */
		if (zone) {
			icalcomponent *zonecomp;

			zonecomp = icaltimezone_get_component (zone);
			if (zonecomp) {
				icalcomponent *clone;

				clone = icalcomponent_new_clone (zonecomp);
				/* icaltimezone_copy() doesn't carry over the component, thus do it this way */
				zone = icaltimezone_new ();
				if (!icaltimezone_set_component (zone, clone)) {
					icalcomponent_free (clone);
					icaltimezone_free (zone, 1);
					zone = NULL;
				}
			} else {
				zone = NULL;
			}
		}

		if (zone) {
			tmd = g_new0 (TimezoneMigrationData, 1);
			tmd->is_deref = !ctd->is_inc;
			tmd->refs = 1;
			tmd->zone = zone;

			g_hash_table_insert (ctd->timezones, g_strdup (tzid), tmd);
		}
	}
}

static void
ecc_count_timezones_for_component (ECalCache *cal_cache,
				   GHashTable *timezones,
				   icalcomponent *icalcomp,
				   gboolean is_inc,
				   GCancellable *cancellable)
{
	g_return_if_fail (E_IS_CAL_CACHE (cal_cache));
	g_return_if_fail (timezones != NULL);

	if (icalcomp) {
		CountTimezonesData ctd;

		ctd.cal_cache = cal_cache;
		ctd.timezones = timezones;
		ctd.is_inc = is_inc;
		ctd.cancellable = cancellable;

		icalcomponent_foreach_tzid (icalcomp, ecc_count_timezones_in_icalcomp_cb, &ctd);
	}
}

static void
ecc_count_timezones_for_old_component (ECalCache *cal_cache,
				       GHashTable *timezones,
				       const gchar *uid_in_table,
				       GCancellable *cancellable)
{
	gchar *objstr;

	g_return_if_fail (E_IS_CAL_CACHE (cal_cache));
	g_return_if_fail (timezones != NULL);
	g_return_if_fail (uid_in_table != NULL);

	objstr = e_cache_get_object_include_deleted (E_CACHE (cal_cache), uid_in_table, NULL, NULL, cancellable, NULL);
	if (objstr) {
		icalcomponent *icalcomp;

		icalcomp = icalcomponent_new_from_string (objstr);
		if (icalcomp) {
			ecc_count_timezones_for_component (cal_cache, timezones, icalcomp, FALSE, cancellable);
			icalcomponent_free (icalcomp);
		}

		g_free (objstr);
	}
}

static gboolean
ecc_update_timezones_table (ECalCache *cal_cache,
			    GHashTable *timezones,
			    GCancellable *cancellable,
			    GError **error)
{
	GHashTableIter iter;
	gpointer key, value;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (timezones != NULL, FALSE);

	g_hash_table_iter_init (&iter, timezones);

	while (success && g_hash_table_iter_next (&iter, &key, &value)) {
		const gchar *tzid = key;
		TimezoneMigrationData *tmd = value;

		if (!tzid || !tmd || !tmd->refs)
			continue;

		if (tmd->is_deref) {
			success = e_cal_cache_remove_timezone (cal_cache, tzid, tmd->refs, cancellable, error);
		} else {
			success = e_cal_cache_put_timezone (cal_cache, tmd->zone, tmd->refs, cancellable, error);
		}
	}

	return success;
}

static gboolean
e_cal_cache_fill_tmd_cb (ECache *cache,
			 gint ncols,
			 const gchar *column_names[],
			 const gchar *column_values[],
			 gpointer user_data)
{
	GHashTable *timezones = user_data; /* gchar *tzid ~> TimezoneMigrationData * */

	g_return_val_if_fail (timezones != NULL, FALSE);
	g_return_val_if_fail (ncols == 2, FALSE);

	/* Verify the timezone is not provided twice */
	if (!g_hash_table_lookup (timezones, column_values[0])) {
		icaltimezone *zone;

		zone = ecc_timezone_from_string (column_values[1]);
		if (zone) {
			TimezoneMigrationData *tmd;

			tmd = g_new0 (TimezoneMigrationData, 1);
			tmd->zone = zone;
			tmd->refs = 0;

			g_hash_table_insert (timezones, g_strdup (column_values[0]), tmd);
		}
	}

	return TRUE;
}

static void
ecc_count_tmd_refs_cb (icalparameter *param,
		       gpointer user_data)
{
	GHashTable *timezones = user_data;
	const gchar *tzid;
	TimezoneMigrationData *tmd;

	tzid = icalparameter_get_tzid (param);
	if (!tzid || !timezones)
		return;

	tmd = g_hash_table_lookup (timezones, tzid);
	if (tmd)
		tmd->refs++;
}

static gboolean
cal_cache_count_tmd_refs (ECalCache *cal_cache,
			  const gchar *uid,
			  const gchar *rid,
			  const gchar *revision,
			  const gchar *object,
			  const gchar *extra,
			  EOfflineState offline_state,
			  gpointer user_data)
{
	GHashTable *timezones = user_data;
	icalcomponent *icalcomp;

	g_return_val_if_fail (timezones != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	icalcomp = icalcomponent_new_from_string (object);
	if (icalcomp) {
		icalcomponent_foreach_tzid (icalcomp, ecc_count_tmd_refs_cb, timezones);
		icalcomponent_free (icalcomp);
	}

	return TRUE;
}

static gboolean
e_cal_cache_table_refs_column_exists_cb (ECache *cache,
					 gint ncols,
					 const gchar *column_names[],
					 const gchar *column_values[],
					 gpointer user_data)
{
	gboolean *prefs_column_exists = user_data;
	gint ii;

	g_return_val_if_fail (prefs_column_exists != NULL, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);

	for (ii = 0; ii < ncols && !*prefs_column_exists; ii++) {
		if (column_names[ii] && camel_strcase_equal (column_names[ii], "name")) {
			if (column_values[ii])
				*prefs_column_exists = camel_strcase_equal (column_values[ii], "refs");
			break;
		}
	}

	return TRUE;
}

static gboolean
e_cal_cache_migrate (ECache *cache,
		     gint from_version,
		     GCancellable *cancellable,
		     GError **error)
{
	ECalCache *cal_cache = E_CAL_CACHE (cache);
	GHashTable *timezones = NULL; /* gchar *tzid ~> TimezoneMigrationData * */
	gboolean success = TRUE;

	/* Add any version-related changes here (E_CAL_CACHE_VERSION) */

	if (from_version > 0 && from_version < 3) {
		gboolean refs_column_exists = FALSE;
		gchar *stmt;

		g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

		/* In case an older version modified the local cache version,
		   then the ALTER TABLE command can fail due to duplicate 'refs' column */
		success = e_cache_sqlite_select (E_CACHE (cal_cache), "PRAGMA table_info (" ECC_TABLE_TIMEZONES ")",
			e_cal_cache_table_refs_column_exists_cb, &refs_column_exists, cancellable, NULL);

		if (!success || !refs_column_exists) {
			stmt = e_cache_sqlite_stmt_printf ("ALTER TABLE %Q ADD COLUMN refs INTEGER", ECC_TABLE_TIMEZONES);
			success = e_cache_sqlite_exec (E_CACHE (cal_cache), stmt, cancellable, error);
			e_cache_sqlite_stmt_free (stmt);
		}

		if (success) {
			timezones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, timezone_migration_data_free);

			stmt = e_cache_sqlite_stmt_printf ("SELECT tzid, zone FROM " ECC_TABLE_TIMEZONES);
			success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt,
				e_cal_cache_fill_tmd_cb, timezones, cancellable, error);
			e_cache_sqlite_stmt_free (stmt);
		}

		g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
	}

	if (success && from_version == 1) {
		/* Version 1 incorrectly stored DATE-only DUE values */
		ComponentInfo ci;

		memset (&ci, 0, sizeof (ComponentInfo));

		if (e_cal_cache_search_with_callback (cal_cache, NULL, cal_cache_gather_v1_affected_cb, &ci, cancellable, NULL)) {
			gboolean success = TRUE;

			if (ci.online_comps)
				success = e_cal_cache_put_components (cal_cache, ci.online_comps, ci.online_extras, E_CACHE_IS_ONLINE, cancellable, NULL);

			if (success && ci.offline_comps)
				e_cal_cache_put_components (cal_cache, ci.offline_comps, ci.offline_extras, E_CACHE_IS_OFFLINE, cancellable, NULL);
		}

		component_info_clear (&ci);
	}

	if (success && timezones) {
		g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

		success = e_cal_cache_remove_timezones (cal_cache, cancellable, error);
		if (success) {
			_e_cal_cache_remove_loaded_timezones (cal_cache);

			success = e_cal_cache_search_with_callback (cal_cache, NULL,
				cal_cache_count_tmd_refs, timezones, cancellable, error);
		}

		if (success) {
			GHashTableIter iter;
			gpointer value;

			g_hash_table_iter_init (&iter, timezones);
			while (success && g_hash_table_iter_next (&iter, NULL, &value)) {
				TimezoneMigrationData *tmd = value;

				if (tmd && tmd->refs > 0)
					success = e_cal_cache_put_timezone (cal_cache, tmd->zone, tmd->refs, cancellable, error);
			}
		}

		g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
	}

	if (timezones)
		g_hash_table_destroy (timezones);

	return success;
}

static gboolean
e_cal_cache_initialize (ECalCache *cal_cache,
			const gchar *filename,
			GCancellable *cancellable,
			GError **error)
{
	ECache *cache;
	GSList *other_columns = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (filename != NULL, FALSE);

	cal_cache->priv->initializing = TRUE;

	cache = E_CACHE (cal_cache);

	e_cal_cache_populate_other_columns (cal_cache, &other_columns);

	success = e_cache_initialize_sync (cache, filename, other_columns, cancellable, error);
	if (!success)
		goto exit;

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	success = success && ecc_init_aux_tables (cal_cache, cancellable, error);

	success = success && ecc_init_sqlite_functions (cal_cache, cancellable, error);

	/* Check for data migration */
	success = success && e_cal_cache_migrate (cache, e_cache_get_version (cache), cancellable, error);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	if (!success)
		goto exit;

	if (e_cache_get_version (cache) != E_CAL_CACHE_VERSION)
		e_cache_set_version (cache, E_CAL_CACHE_VERSION);

 exit:
	g_slist_free_full (other_columns, e_cache_column_info_free);

	cal_cache->priv->initializing = FALSE;

	return success;
}

/**
 * e_cal_cache_new:
 * @filename: file name to load or create the new cache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #ECalCache.
 *
 * Returns: (transfer full) (nullable): A new #ECalCache or %NULL on error
 *
 * Since: 3.26
 **/
ECalCache *
e_cal_cache_new (const gchar *filename,
		 GCancellable *cancellable,
		 GError **error)
{
	ECalCache *cal_cache;

	g_return_val_if_fail (filename != NULL, NULL);

	cal_cache = g_object_new (E_TYPE_CAL_CACHE, NULL);

	if (!e_cal_cache_initialize (cal_cache, filename, cancellable, error)) {
		g_object_unref (cal_cache);
		cal_cache = NULL;
	}

	return cal_cache;
}

/**
 * e_cal_cache_dup_component_revision:
 * @cal_cache: an #ECalCache
 * @icalcomp: an icalcomponent
 *
 * Returns the @icalcomp revision, used to detect changes.
 * The returned string should be freed with g_free(), when
 * no longer needed.
 *
 * Returns: (transfer full): A newly allocated string containing
 *    revision of the @icalcomp.
 *
 * Since: 3.26
 **/
gchar *
e_cal_cache_dup_component_revision (ECalCache *cal_cache,
				    icalcomponent *icalcomp)
{
	gchar *revision = NULL;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);
	g_return_val_if_fail (icalcomp != NULL, NULL);

	g_signal_emit (cal_cache, signals[DUP_COMPONENT_REVISION], 0, icalcomp, &revision);

	return revision;
}

/**
 * e_cal_cache_contains:
 * @cal_cache: an #ECalCache
 * @uid: component UID
 * @rid: (nullable): optional component Recurrence-ID or %NULL
 * @deleted_flag: one of #ECacheDeletedFlag enum
 *
 * Checkes whether the @cal_cache contains an object with
 * the given @uid and @rid. The @rid can be an empty string
 * or %NULL to search for the master object, otherwise the check
 * is done for a detached instance, not for a recurrence instance.
 *
 * Returns: Whether the the object had been found.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_contains (ECalCache *cal_cache,
		      const gchar *uid,
		      const gchar *rid,
		      ECacheDeletedFlag deleted_flag)
{
	gchar *id;
	gboolean found;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	id = ecc_encode_id_sql (uid, rid);

	found = e_cache_contains (E_CACHE (cal_cache), id, deleted_flag);

	g_free (id);

	return found;
}

/**
 * e_cal_cache_put_component:
 * @cal_cache: an #ECalCache
 * @component: an #ECalComponent to put into the @cal_cache
 * @extra: (nullable): an extra data to store in association with the @component
 * @offline_flag: one of #ECacheOfflineFlag, whether putting this component in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Adds a @component into the @cal_cache. Any existing with the same UID
 * and RID is replaced.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_put_component (ECalCache *cal_cache,
			   ECalComponent *component,
			   const gchar *extra,
			   ECacheOfflineFlag offline_flag,
			   GCancellable *cancellable,
			   GError **error)
{
	GSList *components = NULL;
	GSList *extras = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	components = g_slist_prepend (components, component);
	if (extra)
		extras = g_slist_prepend (extras, (gpointer) extra);

	success = e_cal_cache_put_components (cal_cache, components, extras, offline_flag, cancellable, error);

	g_slist_free (components);
	g_slist_free (extras);

	return success;
}

/**
 * e_cal_cache_put_components:
 * @cal_cache: an #ECalCache
 * @components: (element-type ECalComponent): a #GSList of #ECalComponent to put into the @cal_cache
 * @extras: (nullable) (element-type utf8): an extra data to store in association with the @components
 * @offline_flag: one of #ECacheOfflineFlag, whether putting these components in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Adds a list of @components into the @cal_cache. Any existing with the same UID
 * and RID are replaced.
 *
 * If @extras is not %NULL, it's length should be the same as the length
 * of the @components.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_put_components (ECalCache *cal_cache,
			    const GSList *components,
			    const GSList *extras,
			    ECacheOfflineFlag offline_flag,
			    GCancellable *cancellable,
			    GError **error)
{
	const GSList *clink, *elink;
	ECache *cache;
	ECacheColumnValues *other_columns;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (extras == NULL || g_slist_length ((GSList *) components) == g_slist_length ((GSList *) extras), FALSE);

	cache = E_CACHE (cal_cache);
	other_columns = e_cache_column_values_new ();

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);
	e_cache_freeze_revision_change (cache);

	for (clink = components, elink = extras; clink; clink = g_slist_next (clink), elink = g_slist_next (elink)) {
		ECalComponent *component = clink->data;
		const gchar *extra = elink ? elink->data : NULL;
		ECalComponentId *id;
		gchar *uid, *rev, *icalstring;

		g_return_val_if_fail (E_IS_CAL_COMPONENT (component), FALSE);

		icalstring = e_cal_component_get_as_string (component);
		g_return_val_if_fail (icalstring != NULL, FALSE);

		e_cache_column_values_remove_all (other_columns);

		if (extra)
			e_cache_column_values_take_value (other_columns, ECC_COLUMN_EXTRA, g_strdup (extra));

		id = e_cal_component_get_id (component);
		if (id) {
			uid = ecc_encode_id_sql (id->uid, id->rid);
		} else {
			g_warn_if_reached ();
			uid = g_strdup ("");
		}
		e_cal_component_free_id (id);

		rev = e_cal_cache_dup_component_revision (cal_cache, e_cal_component_get_icalcomponent (component));

		success = e_cache_put (cache, uid, rev, icalstring, other_columns, offline_flag, cancellable, error);

		g_free (icalstring);
		g_free (rev);
		g_free (uid);

		if (!success)
			break;
	}

	e_cache_thaw_revision_change (cache);
	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	e_cache_column_values_free (other_columns);

	return success;
}

/**
 * e_cal_cache_remove_component:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component to remove
 * @rid: (nullable): an optional Recurrence-ID to remove
 * @offline_flag: one of #ECacheOfflineFlag, whether removing this component in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes a component identified by @uid and @rid from the @cal_cache.
 * When the @rid is %NULL, or an empty string, then removes the master
 * object only, without any detached instance.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_remove_component (ECalCache *cal_cache,
			      const gchar *uid,
			      const gchar *rid,
			      ECacheOfflineFlag offline_flag,
			      GCancellable *cancellable,
			      GError **error)
{
	ECalComponentId id;
	GSList *ids = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	id.uid = (gchar *) uid;
	id.rid = (gchar *) rid;

	ids = g_slist_prepend (ids, &id);

	success = e_cal_cache_remove_components (cal_cache, ids, offline_flag, cancellable, error);

	g_slist_free (ids);

	return success;
}

/**
 * e_cal_cache_remove_components:
 * @cal_cache: an #ECalCache
 * @ids: (element-type ECalComponentId): a #GSList of components to remove
 * @offline_flag: one of #ECacheOfflineFlag, whether removing these comonents in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes components identified by @uid and @rid from the @cal_cache
 * in the @ids list. When the @rid is %NULL, or an empty string, then
 * removes the master object only, without any detached instance.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_remove_components (ECalCache *cal_cache,
			       const GSList *ids,
			       ECacheOfflineFlag offline_flag,
			       GCancellable *cancellable,
			       GError **error)
{
	ECache *cache;
	const GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	cache = E_CACHE (cal_cache);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);
	e_cache_freeze_revision_change (cache);

	for (link = ids; success && link; link = g_slist_next (link)) {
		const ECalComponentId *id = link->data;
		gchar *uid;

		g_warn_if_fail (id != NULL);

		if (!id)
			continue;

		uid = ecc_encode_id_sql (id->uid, id->rid);

		success = e_cache_remove (cache, uid, offline_flag, cancellable, error);

		g_free (uid);
	}

	e_cache_thaw_revision_change (cache);
	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cal_cache_get_component:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @rid: (nullable): an optional Recurrence-ID
 * @out_component: (out) (transfer full): return location for an #ECalComponent
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a component identified by @uid, and optionally by the @rid,
 * from the @cal_cache. The returned @out_component should be freed with
 * g_object_unref(), when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_component (ECalCache *cal_cache,
			   const gchar *uid,
			   const gchar *rid,
			   ECalComponent **out_component,
			   GCancellable *cancellable,
			   GError **error)
{
	gchar *icalstring = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_component != NULL, FALSE);

	success = e_cal_cache_get_component_as_string (cal_cache, uid, rid, &icalstring, cancellable, error);
	if (success) {
		*out_component = e_cal_component_new_from_string (icalstring);
		g_free (icalstring);
	}

	return success;
}

/**
 * e_cal_cache_get_component_as_string:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @rid: (nullable): an optional Recurrence-ID
 * @out_icalstring: (out) (transfer full): return location for an iCalendar string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a component identified by @uid, and optionally by the @rid,
 * from the @cal_cache. The returned @out_icalstring should be freed with
 * g_free(), when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_component_as_string (ECalCache *cal_cache,
				     const gchar *uid,
				     const gchar *rid,
				     gchar **out_icalstring,
				     GCancellable *cancellable,
				     GError **error)
{
	gchar *id;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_icalstring != NULL, FALSE);

	id = ecc_encode_id_sql (uid, rid);

	*out_icalstring = e_cache_get (E_CACHE (cal_cache), id, NULL, NULL, cancellable, error);

	g_free (id);

	return *out_icalstring != NULL;
}

/**
 * e_cal_cache_set_component_extra:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @rid: (nullable): an optional Recurrence-ID
 * @extra: (nullable): extra data to set for the component
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Sets or replaces the extra data associated with a component
 * identified by @uid and optionally @rid.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_set_component_extra (ECalCache *cal_cache,
				 const gchar *uid,
				 const gchar *rid,
				 const gchar *extra,
				 GCancellable *cancellable,
				 GError **error)
{
	gchar *id, *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	id = ecc_encode_id_sql (uid, rid);

	if (!e_cache_contains (E_CACHE (cal_cache), id, E_CACHE_INCLUDE_DELETED)) {
		g_free (id);

		if (rid && *rid)
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s”, “%s” not found"), uid, rid);
		else
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);

		return FALSE;
	}

	if (extra) {
		stmt = e_cache_sqlite_stmt_printf (
			"UPDATE " E_CACHE_TABLE_OBJECTS " SET " ECC_COLUMN_EXTRA "=%Q"
			" WHERE " E_CACHE_COLUMN_UID "=%Q",
			extra, id);
	} else {
		stmt = e_cache_sqlite_stmt_printf (
			"UPDATE " E_CACHE_TABLE_OBJECTS " SET " ECC_COLUMN_EXTRA "=NULL"
			" WHERE " E_CACHE_COLUMN_UID "=%Q",
			id);
	}

	success = e_cache_sqlite_exec (E_CACHE (cal_cache), stmt, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);
	g_free (id);

	return success;
}

/**
 * e_cal_cache_get_component_extra:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @rid: (nullable): an optional Recurrence-ID
 * @out_extra: (out) (transfer full): return location to store the extra data
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the extra data previously set for @uid and @rid, either with
 * e_cal_cache_set_component_extra() or when adding components.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_component_extra (ECalCache *cal_cache,
				 const gchar *uid,
				 const gchar *rid,
				 gchar **out_extra,
				 GCancellable *cancellable,
				 GError **error)
{
	gchar *id, *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	id = ecc_encode_id_sql (uid, rid);

	if (!e_cache_contains (E_CACHE (cal_cache), id, E_CACHE_INCLUDE_DELETED)) {
		g_free (id);

		if (rid && *rid)
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s”, “%s” not found"), uid, rid);
		else
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);

		return FALSE;
	}

	stmt = e_cache_sqlite_stmt_printf (
		"SELECT " ECC_COLUMN_EXTRA " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " E_CACHE_COLUMN_UID "=%Q",
		id);

	success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt, e_cal_cache_get_string, out_extra, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);
	g_free (id);

	return success;
}

/**
 * e_cal_cache_get_ids_with_extra:
 * @cal_cache: an #ECalCache
 * @extra: an extra column value to search for
 * @out_ids: (out) (transfer full) (element-type ECalComponentId): return location to store the ids to
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets all the ID-s the @extra data is set for.
 *
 * The @out_ids should be freed with
 * g_slist_free_full (ids, (GDestroyNotify) e_cal_component_free_id);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_ids_with_extra (ECalCache *cal_cache,
				const gchar *extra,
				GSList **out_ids,
				GCancellable *cancellable,
				GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (extra != NULL, FALSE);
	g_return_val_if_fail (out_ids != NULL, FALSE);

	*out_ids = NULL;

	stmt = e_cache_sqlite_stmt_printf (
		"SELECT " E_CACHE_COLUMN_UID " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " ECC_COLUMN_EXTRA "=%Q",
		extra);

	success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt, e_cal_cache_get_ids, out_ids, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	if (success && !*out_ids) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object with extra “%s” not found"), extra);
		success = FALSE;
	} else {
		*out_ids = g_slist_reverse (*out_ids);
	}

	return success;
}

static GSList *
ecc_icalstrings_to_components (GSList *icalstrings)
{
	GSList *link;

	for (link = icalstrings; link; link = g_slist_next (link)) {
		gchar *icalstring = link->data;

		link->data = e_cal_component_new_from_string (icalstring);

		g_free (icalstring);
	}

	return icalstrings;
}

/**
 * e_cal_cache_get_components_by_uid:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @out_components: (out) (transfer full) (element-type ECalComponent): return location for the components
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the master object and all detached instances for a component
 * identified by the @uid. Free the returned #GSList with
 * g_slist_free_full (components, g_object_unref); when
 * no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_components_by_uid (ECalCache *cal_cache,
				   const gchar *uid,
				   GSList **out_components,
				   GCancellable *cancellable,
				   GError **error)
{
	GSList *icalstrings = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_components != NULL, FALSE);

	success = e_cal_cache_get_components_by_uid_as_string (cal_cache, uid, &icalstrings, cancellable, error);
	if (success) {
		*out_components = ecc_icalstrings_to_components (icalstrings);
	}

	return success;
}

/**
 * e_cal_cache_get_components_by_uid_as_string:
 * @cal_cache: an #ECalCache
 * @uid: a UID of the component
 * @out_icalstrings: (out) (transfer full) (element-type utf8): return location for the iCal strings
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the master object and all detached instances as string
 * for a component identified by the @uid. Free the returned #GSList
 * with g_slist_free_full (icalstrings, g_free); when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_components_by_uid_as_string (ECalCache *cal_cache,
					      const gchar *uid,
					      GSList **out_icalstrings,
					      GCancellable *cancellable,
					      GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_icalstrings != NULL, FALSE);

	*out_icalstrings = NULL;

	/* Using 'ORDER BY' to get the master object first */
	stmt = e_cache_sqlite_stmt_printf (
		"SELECT " E_CACHE_COLUMN_OBJECT " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " E_CACHE_COLUMN_UID "=%Q OR " E_CACHE_COLUMN_UID " LIKE '%q\n%%'"
		" ORDER BY " E_CACHE_COLUMN_UID,
		uid, uid);

	success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt, e_cal_cache_get_strings, out_icalstrings, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	if (success && !*out_icalstrings) {
		success = FALSE;
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
	} else if (success) {
		*out_icalstrings = g_slist_reverse (*out_icalstrings);
	}

	return success;
}

/**
 * e_cal_cache_get_components_in_range:
 * @cal_cache: an #ECalCache
 * @range_start: start of the range, as time_t, inclusive
 * @range_end: end of the range, as time_t, exclusive
 * @out_components: (out) (transfer full) (element-type ECalComponent): return location for the components
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a list of components which occur in the given time range.
 * It's not an error if none is found.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_components_in_range (ECalCache *cal_cache,
				     time_t range_start,
				     time_t range_end,
				     GSList **out_components,
				     GCancellable *cancellable,
				     GError **error)
{
	GSList *icalstrings = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_components != NULL, FALSE);

	success = e_cal_cache_get_components_in_range_as_strings (cal_cache, range_start, range_end, &icalstrings, cancellable, error);
	if (success)
		*out_components = ecc_icalstrings_to_components (icalstrings);

	return success;
}

static gboolean
ecc_search_icalstrings_cb (ECalCache *cal_cache,
			   const gchar *uid,
			   const gchar *rid,
			   const gchar *revision,
			   const gchar *object,
			   const gchar *extra,
			   EOfflineState offline_state,
			   gpointer user_data)
{
	GSList **out_icalstrings = user_data;

	g_return_val_if_fail (out_icalstrings != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	*out_icalstrings = g_slist_prepend (*out_icalstrings, g_strdup (object));

	return TRUE;
}

/**
 * e_cal_cache_get_components_in_range_as_strings:
 * @cal_cache: an #ECalCache
 * @range_start: start of the range, as time_t, inclusive
 * @range_end: end of the range, as time_t, exclusive
 * @out_icalstrings: (out) (transfer full) (element-type utf8): return location for the iCal strings
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a list of components, as iCal strings, which occur in the given time range.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_components_in_range_as_strings (ECalCache *cal_cache,
						time_t range_start,
						time_t range_end,
						GSList **out_icalstrings,
						GCancellable *cancellable,
						GError **error)
{
	gchar *sexp;
	struct icaltimetype itt_start, itt_end;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_icalstrings != NULL, FALSE);

	*out_icalstrings = NULL;

	itt_start = icaltime_from_timet_with_zone (range_start, FALSE, NULL);
	itt_end = icaltime_from_timet_with_zone (range_end, FALSE, NULL);

	sexp = g_strdup_printf ("(occur-in-time-range? (make-time \"%04d%02d%02dT%02d%02d%02dZ\") (make-time \"%04d%02d%02dT%02d%02d%02dZ\"))",
		itt_start.year, itt_start.month, itt_start.day, itt_start.hour, itt_start.minute, itt_start.second,
		itt_end.year, itt_end.month, itt_end.day, itt_end.hour, itt_end.minute, itt_end.second);

	success = e_cal_cache_search_with_callback (cal_cache, sexp, ecc_search_icalstrings_cb,
		out_icalstrings, cancellable, error);

	g_free (sexp);

	if (success) {
		*out_icalstrings = g_slist_reverse (*out_icalstrings);
	} else {
		g_slist_free_full (*out_icalstrings, g_free);
		*out_icalstrings = NULL;
	}

	return success;
}

static gboolean
ecc_search_data_cb (ECalCache *cal_cache,
		    const gchar *uid,
		    const gchar *rid,
		    const gchar *revision,
		    const gchar *object,
		    const gchar *extra,
		    EOfflineState offline_state,
		    gpointer user_data)
{
	GSList **out_data = user_data;

	g_return_val_if_fail (out_data != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	*out_data = g_slist_prepend (*out_data,
		e_cal_cache_search_data_new (uid, rid, object, extra));

	return TRUE;
}

static gboolean
ecc_search_components_cb (ECalCache *cal_cache,
			  const gchar *uid,
			  const gchar *rid,
			  const gchar *revision,
			  const gchar *object,
			  const gchar *extra,
			  EOfflineState offline_state,
			  gpointer user_data)
{
	GSList **out_components = user_data;

	g_return_val_if_fail (out_components != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	*out_components = g_slist_prepend (*out_components,
		e_cal_component_new_from_string (object));

	return TRUE;
}

static gboolean
ecc_search_ids_cb (ECalCache *cal_cache,
		   const gchar *uid,
		   const gchar *rid,
		   const gchar *revision,
		   const gchar *object,
		   const gchar *extra,
		   EOfflineState offline_state,
		   gpointer user_data)
{
	GSList **out_ids = user_data;

	g_return_val_if_fail (out_ids != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	*out_ids = g_slist_prepend (*out_ids, e_cal_component_id_new (uid, rid));

	return TRUE;
}

/**
 * e_cal_cache_search:
 * @cal_cache: an #ECalCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to list all stored components
 * @out_data: (out) (transfer full) (element-type ECalCacheSearchData): stored components, as search data, satisfied by @sexp
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches the @cal_cache with the given @sexp and
 * returns those components which satisfy the search
 * expression as a #GSList of #ECalCacheSearchData.
 * The @out_data should be freed with
 * g_slist_free_full (data, e_cal_cache_search_data_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_search (ECalCache *cal_cache,
		    const gchar *sexp,
		    GSList **out_data,
		    GCancellable *cancellable,
		    GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_data != NULL, FALSE);

	*out_data = NULL;

	success = e_cal_cache_search_with_callback (cal_cache, sexp, ecc_search_data_cb,
		out_data, cancellable, error);
	if (success) {
		*out_data = g_slist_reverse (*out_data);
	} else {
		g_slist_free_full (*out_data, e_cal_cache_search_data_free);
		*out_data = NULL;
	}

	return success;
}

/**
 * e_cal_cache_search_components:
 * @cal_cache: an #ECalCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to list all stored components
 * @out_components: (out) (transfer full) (element-type ECalComponent): stored components satisfied by @sexp
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches the @cal_cache with the given @sexp and
 * returns those components which satisfy the search
 * expression. The @out_components should be freed with
 * g_slist_free_full (components, g_object_unref); when
 * no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_search_components (ECalCache *cal_cache,
			       const gchar *sexp,
			       GSList **out_components,
			       GCancellable *cancellable,
			       GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_components != NULL, FALSE);

	*out_components = NULL;

	success = e_cal_cache_search_with_callback (cal_cache, sexp, ecc_search_components_cb,
		out_components, cancellable, error);
	if (success) {
		*out_components = g_slist_reverse (*out_components);
	} else {
		g_slist_free_full (*out_components, g_object_unref);
		*out_components = NULL;
	}

	return success;
}

/**
 * e_cal_cache_search_ids:
 * @cal_cache: an #ECalCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to list all stored components
 * @out_ids: (out) (transfer full) (element-type ECalComponentId): IDs of stored components satisfied by @sexp
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches the @cal_cache with the given @sexp and returns ECalComponentId
 * for those components which satisfy the search expression.
 * The @out_ids should be freed with
 * g_slist_free_full (ids, (GDestroyNotify) e_cal_component_free_id);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_search_ids (ECalCache *cal_cache,
			const gchar *sexp,
			GSList **out_ids,
			GCancellable *cancellable,
			GError **error)

{
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_ids != NULL, FALSE);

	*out_ids = NULL;

	success = e_cal_cache_search_with_callback (cal_cache, sexp, ecc_search_ids_cb,
		out_ids, cancellable, error);
	if (success) {
		*out_ids = g_slist_reverse (*out_ids);
	} else {
		g_slist_free_full (*out_ids, (GDestroyNotify) e_cal_component_free_id);
		*out_ids = NULL;
	}

	return success;
}

/**
 * e_cal_cache_search_with_callback:
 * @cal_cache: an #ECalCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to list all stored components
 * @func: an #ECalCacheSearchFunc callback to call for each row which satisfies @sexp
 * @user_data: user data for @func
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches the @cal_cache with the given @sexp and calls @func for each
 * row which satisfy the search expression.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_search_with_callback (ECalCache *cal_cache,
				  const gchar *sexp,
				  ECalCacheSearchFunc func,
				  gpointer user_data,
				  GCancellable *cancellable,
				  GError **error)
{
	ECalBackendSExp *bsexp = NULL;
	gint sexp_id = -1;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (func != NULL, FALSE);

	if (sexp && *sexp && g_strcmp0 (sexp, "#t") != 0) {
		bsexp = e_cal_backend_sexp_new (sexp);
		if (!bsexp) {
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
				_("Invalid query: %s"), sexp);
			return FALSE;
		}

		sexp_id = ecc_take_sexp_object (cal_cache, bsexp);
	} else {
		sexp = NULL;
	}

	success = ecc_search_internal (cal_cache, sexp, sexp_id, func, user_data, cancellable, error);

	if (bsexp)
		ecc_free_sexp_object (cal_cache, sexp_id);

	return success;
}

/**
 * e_cal_cache_get_offline_changes:
 * @cal_cache: an #ECalCache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * The same as e_cache_get_offline_changes(), only splits the saved UID
 * into UID and RID and saved the data into #ECalCacheOfflineChange structure.
 *
 * Returns: (transfer full) (element-type ECalCacheOfflineChange): A newly allocated list of all
 *    offline changes. Free it with g_slist_free_full (slist, e_cal_cache_offline_change_free);
 *    when no longer needed.
 *
 * Since: 3.26
 **/
GSList *
e_cal_cache_get_offline_changes	(ECalCache *cal_cache,
				 GCancellable *cancellable,
				 GError **error)
{
	GSList *changes, *link;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	changes = e_cache_get_offline_changes (E_CACHE (cal_cache), cancellable, error);

	for (link = changes; link; link = g_slist_next (link)) {
		ECacheOfflineChange *cache_change = link->data;
		ECalCacheOfflineChange *cal_change;
		gchar *uid = NULL, *rid = NULL;

		if (!cache_change || !ecc_decode_id_sql (cache_change->uid, &uid, &rid)) {
			g_warn_if_reached ();

			e_cache_offline_change_free (cache_change);
			link->data = NULL;

			continue;
		}

		cal_change = e_cal_cache_offline_change_new (uid, rid, cache_change->revision, cache_change->object, cache_change->state);
		link->data = cal_change;

		e_cache_offline_change_free (cache_change);
		g_free (uid);
		g_free (rid);
	}

	return changes;
}

/**
 * e_cal_cache_delete_attachments:
 * @cal_cache: an #ECalCache
 * @component: an icalcomponent
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes all locally stored attachments beside the cache file from the disk.
 * This doesn't modify the @component. It's usually called before the @component
 * is being removed from the @cal_cache.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_delete_attachments (ECalCache *cal_cache,
				icalcomponent *component,
				GCancellable *cancellable,
				GError **error)
{
	icalproperty *prop;
	gchar *cache_dirname = NULL;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (component != NULL, FALSE);

	for (prop = icalcomponent_get_first_property (component, ICAL_ATTACH_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (component, ICAL_ATTACH_PROPERTY)) {
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

				if (g_str_has_prefix (buf, "file://")) {
					gchar *filename;

					filename = g_filename_from_uri (buf, NULL, NULL);
					if (filename) {
						if (!cache_dirname)
							cache_dirname = g_path_get_dirname (e_cache_get_filename (E_CACHE (cal_cache)));

						if (g_str_has_prefix (filename, cache_dirname) &&
						    g_unlink (filename) == -1) {
							/* Ignore these errors */
						}

						g_free (filename);
					}
				}

				g_free (buf);
			}
		}
	}

	g_free (cache_dirname);

	return TRUE;
}

static gboolean
e_cal_cache_get_uint64_cb (ECache *cache,
			   gint ncols,
			   const gchar **column_names,
			   const gchar **column_values,
			   gpointer user_data)
{
	guint64 *pui64 = user_data;

	g_return_val_if_fail (pui64 != NULL, FALSE);

	if (ncols == 1) {
		*pui64 = column_values[0] ? g_ascii_strtoull (column_values[0], NULL, 10) : 0;
	} else {
		*pui64 = 0;
	}

	return TRUE;
}

static gint
e_cal_cache_get_current_timezone_refs (ECalCache *cal_cache,
				       const gchar *tzid,
				       GCancellable *cancellable)
{
	guint64 existing_refs = -1;
	gchar *stmt;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), -1);
	g_return_val_if_fail (tzid != NULL, -1);

	stmt = e_cache_sqlite_stmt_printf ("SELECT refs FROM " ECC_TABLE_TIMEZONES " WHERE tzid=%Q", tzid);

	if (!e_cache_sqlite_select (E_CACHE (cal_cache), stmt, e_cal_cache_get_uint64_cb, &existing_refs, cancellable, NULL))
		existing_refs = -1;

	e_cache_sqlite_stmt_free (stmt);

	return (gint) existing_refs;
}

/**
 * e_cal_cache_put_timezone:
 * @cal_cache: an #ECalCache
 * @zone: an icaltimezone to put
 * @inc_ref_counts: how many refs to add, or 0 to have it stored forever
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Puts the @zone into the @cal_cache using its timezone ID as
 * an identificator. The function adds a new or replaces existing,
 * if any such already exists in the @cal_cache. The function does
 * nothing and returns %TRUE, when the passed-in @zone is libical
 * builtin timezone.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_put_timezone (ECalCache *cal_cache,
			  const icaltimezone *zone,
			  guint inc_ref_counts,
			  GCancellable *cancellable,
			  GError **error)
{
	gboolean success;
	gchar *stmt;
	const gchar *tzid;
	gchar *component_str;
	icalcomponent *component;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (zone != NULL, FALSE);

	tzid = icaltimezone_get_tzid ((icaltimezone *) zone);
	if (!tzid) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Cannot add timezone without tzid"));
		return FALSE;
	}

	if (ecc_tzid_is_libical_builtin (icaltimezone_get_tzid ((icaltimezone *) zone)))
		return TRUE;

	component = icaltimezone_get_component ((icaltimezone *) zone);
	if (!component) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Cannot add timezone without component"));
		return FALSE;
	}

	component_str = icalcomponent_as_ical_string_r (component);
	if (!component_str) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Cannot add timezone with invalid component"));
		return FALSE;
	}

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	if (inc_ref_counts > 0) {
		gint current_refs;

		current_refs = e_cal_cache_get_current_timezone_refs (cal_cache, tzid, cancellable);

		/* Zero means keep forever */
		if (current_refs == 0)
			inc_ref_counts = 0;
		else if (current_refs > 0)
			inc_ref_counts += current_refs;
	}

	stmt = e_cache_sqlite_stmt_printf (
		"INSERT or REPLACE INTO " ECC_TABLE_TIMEZONES " (tzid, zone, refs) VALUES (%Q, %Q, %u)",
		tzid, component_str, inc_ref_counts);

	success = e_cache_sqlite_exec (E_CACHE (cal_cache), stmt, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	g_free (component_str);

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	return success;
}

/**
 * e_cal_cache_get_timezone:
 * @cal_cache: an #ECalCache
 * @tzid: a timezone ID to get
 * @out_zone: (out) (transfer none): return location for the icaltimezone
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a timezone with given @tzid, which had been previously put
 * into the @cal_cache with e_cal_cache_put_timezone().
 * The returned icaltimezone is owned by the @cal_cache and should
 * not be freed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_get_timezone (ECalCache *cal_cache,
			  const gchar *tzid,
			  icaltimezone **out_zone,
			  GCancellable *cancellable,
			  GError **error)

{
	gchar *zone_str = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (tzid != NULL, FALSE);
	g_return_val_if_fail (out_zone != NULL, FALSE);

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	*out_zone = g_hash_table_lookup (cal_cache->priv->loaded_timezones, tzid);
	if (*out_zone) {
		g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
		return TRUE;
	}

	*out_zone = g_hash_table_lookup (cal_cache->priv->modified_timezones, tzid);
	if (*out_zone) {
		g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
		return TRUE;
	}

	success = e_cal_cache_dup_timezone_as_string (cal_cache, tzid, &zone_str, cancellable, error);

	if (success && zone_str) {
		icaltimezone *zone;

		zone = ecc_timezone_from_string (zone_str);
		if (zone) {
			g_hash_table_insert (cal_cache->priv->loaded_timezones, g_strdup (tzid), zone);
			*out_zone = zone;
		} else {
			success = FALSE;
		}
	}

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	g_free (zone_str);

	return success;
}

/**
 * e_cal_cache_dup_timezone_as_string:
 * @cal_cache: an #ECalCache
 * @tzid: a timezone ID to get
 * @out_zone_string: (out) (transfer full): return location for the icaltimezone as iCal string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a timezone with given @tzid, which had been previously put
 * into the @cal_cache with e_cal_cache_put_timezone().
 * The returned string is an iCal string for that icaltimezone and
 * should be freed with g_free() when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_dup_timezone_as_string (ECalCache *cal_cache,
				    const gchar *tzid,
				    gchar **out_zone_string,
				    GCancellable *cancellable,
				    GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (tzid != NULL, FALSE);
	g_return_val_if_fail (out_zone_string, FALSE);

	*out_zone_string = NULL;

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	stmt = e_cache_sqlite_stmt_printf (
		"SELECT zone FROM " ECC_TABLE_TIMEZONES " WHERE tzid=%Q",
		tzid);

	success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt, e_cal_cache_get_string, out_zone_string, cancellable, error) &&
		*out_zone_string != NULL;

	e_cache_sqlite_stmt_free (stmt);

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	return success;
}

static gboolean
e_cal_cache_load_zones_cb (ECache *cache,
			   gint ncols,
			   const gchar *column_names[],
			   const gchar *column_values[],
			   gpointer user_data)
{
	GHashTable *loaded_zones = user_data;

	g_return_val_if_fail (loaded_zones != NULL, FALSE);
	g_return_val_if_fail (ncols == 2, FALSE);

	/* Do not overwrite already loaded timezones, they can be used anywhere around */
	if (!g_hash_table_lookup (loaded_zones, column_values[0])) {
		icaltimezone *zone;

		zone = ecc_timezone_from_string (column_values[1]);
		if (zone) {
			g_hash_table_insert (loaded_zones, g_strdup (column_values[0]), zone);
		}
	}

	return TRUE;
}

/**
 * e_cal_cache_list_timezones:
 * @cal_cache: an #ECalCache
 * @out_timezones: (out) (transfer container) (element-type icaltimezone): return location for the list of stored timezones
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a list of all stored timezones by the @cal_cache.
 * Only the returned list should be freed with g_list_free()
 * when no longer needed; the icaltimezone-s are owned
 * by the @cal_cache.
 *
 * Note: The list can contain timezones previously stored
 * in the cache, but removed from it since they were loaded,
 * because these are freed only when also the @cal_cache is freed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_list_timezones (ECalCache *cal_cache,
			    GList **out_timezones,
			    GCancellable *cancellable,
			    GError **error)
{
	guint64 n_stored = 0;
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (out_timezones != NULL, FALSE);

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	success = e_cache_sqlite_select (E_CACHE (cal_cache),
		"SELECT COUNT(*) FROM " ECC_TABLE_TIMEZONES,
		e_cal_cache_get_uint64_cb, &n_stored, cancellable, error);

	if (success && n_stored != g_hash_table_size (cal_cache->priv->loaded_timezones)) {
		if (n_stored == 0) {
			g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
			*out_timezones = NULL;

			return TRUE;
		}

		stmt = e_cache_sqlite_stmt_printf ("SELECT tzid, zone FROM " ECC_TABLE_TIMEZONES);
		success = e_cache_sqlite_select (E_CACHE (cal_cache), stmt,
			e_cal_cache_load_zones_cb, cal_cache->priv->loaded_timezones, cancellable, error);
		e_cache_sqlite_stmt_free (stmt);
	}

	if (success) {
		GList *loaded, *modified;

		loaded = g_hash_table_get_values (cal_cache->priv->loaded_timezones);
		modified = g_hash_table_get_values (cal_cache->priv->modified_timezones);

		if (loaded && modified)
			*out_timezones = g_list_concat (loaded, modified);
		else
			*out_timezones = loaded ? loaded : modified;
	}

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	return success;
}

/**
 * e_cal_cache_remove_timezone:
 * @cal_cache: an #ECalCache
 * @tzid: timezone ID to remove/dereference
 * @dec_ref_counts: reference counts to drop, 0 to remove it regardless of the current reference count
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Dereferences use count of the time zone with ID @tzid by @dec_ref_counts
 * and removes the timezone from the cache when the reference count reaches
 * zero. Special case is with @dec_ref_counts being zero, in which case
 * the corresponding timezone is removed regardless of the current reference
 * count.
 *
 * It's not an error when the timezone doesn't exist in the cache.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.30
 **/
gboolean
e_cal_cache_remove_timezone (ECalCache *cal_cache,
			     const gchar *tzid,
			     guint dec_ref_counts,
			     GCancellable *cancellable,
			     GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (tzid != NULL, FALSE);

	e_cache_lock (E_CACHE (cal_cache), E_CACHE_LOCK_WRITE);

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	if (dec_ref_counts) {
		gint current_refs;

		current_refs = e_cal_cache_get_current_timezone_refs (cal_cache, tzid, cancellable);
		if (current_refs <= 0) {
			g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
			e_cache_unlock (E_CACHE (cal_cache), E_CACHE_UNLOCK_COMMIT);

			return TRUE;
		}

		if (current_refs >= dec_ref_counts)
			dec_ref_counts = current_refs - dec_ref_counts;
		else
			dec_ref_counts = 0;
	}

	if (dec_ref_counts)
		stmt = e_cache_sqlite_stmt_printf ("UPDATE " ECC_TABLE_TIMEZONES " SET refs=%u WHERE tzid=%Q", dec_ref_counts, tzid);
	else
		stmt = e_cache_sqlite_stmt_printf ("DELETE FROM " ECC_TABLE_TIMEZONES " WHERE tzid=%Q", tzid);

	success = e_cache_sqlite_exec (E_CACHE (cal_cache), stmt, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	e_cache_unlock (E_CACHE (cal_cache), success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cal_cache_remove_timezones:
 * @cal_cache: an #ECalCache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes all stored timezones from the @cal_cache.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_cache_remove_timezones (ECalCache *cal_cache,
			      GCancellable *cancellable,
			      GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	e_cache_lock (E_CACHE (cal_cache), E_CACHE_LOCK_WRITE);

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	success = e_cache_sqlite_exec (E_CACHE (cal_cache), "DELETE FROM " ECC_TABLE_TIMEZONES, cancellable, error);

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	e_cache_unlock (E_CACHE (cal_cache), success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/* Private function, not meant to be part of the public API */
void
_e_cal_cache_remove_loaded_timezones (ECalCache *cal_cache)
{
	g_return_if_fail (E_IS_CAL_CACHE (cal_cache));

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	g_hash_table_remove_all (cal_cache->priv->loaded_timezones);
	g_hash_table_remove_all (cal_cache->priv->modified_timezones);

	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);
}

/**
 * e_cal_cache_resolve_timezone_cb:
 * @tzid: a timezone ID
 * @cal_cache: an #ECalCache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * An #ECalRecurResolveTimezoneCb callback, which can be used
 * with e_cal_recur_generate_instances_sync(). The @cal_cache
 * is supposed to be an #ECalCache instance. See also
 * e_cal_cache_resolve_timezone_simple_cb().
 *
 * Returns: (transfer none) (nullable): the resolved icaltimezone, or %NULL, if not found
 *
 * Since: 3.26
 **/
icaltimezone *
e_cal_cache_resolve_timezone_cb (const gchar *tzid,
				 gpointer cal_cache,
				 GCancellable *cancellable,
				 GError **error)
{
	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	return e_cal_cache_resolve_timezone_simple_cb (tzid, cal_cache);
}

/**
 * e_cal_cache_resolve_timezone_simple_cb:
 * @tzid: a timezone ID
 * @cal_cache: an #ECalCache
 *
 * An #ECalRecurResolveTimezoneFn callback, which can be used
 * with e_cal_recur_ensure_end_dates() and simialr functions.
 * The @cal_cache is supposed to be an #ECalCache instance. See
 * also e_cal_cache_resolve_timezone_cb().
 *
 * Returns: (transfer none) (nullable): the resolved icaltimezone, or %NULL, if not found
 *
 * Since: 3.26
 **/
icaltimezone *
e_cal_cache_resolve_timezone_simple_cb (const gchar *tzid,
					gpointer cal_cache)
{
	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	return e_timezone_cache_get_timezone (E_TIMEZONE_CACHE (cal_cache), tzid);
}

static gboolean
ecc_search_delete_attachment_cb (ECalCache *cal_cache,
				 const gchar *uid,
				 const gchar *rid,
				 const gchar *revision,
				 const gchar *object,
				 const gchar *extra,
				 EOfflineState offline_state,
				 gpointer user_data)
{
	icalcomponent *icalcomp;
	GCancellable *cancellable = user_data;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	icalcomp = icalcomponent_new_from_string (object);
	if (!icalcomp)
		return TRUE;

	if (!e_cal_cache_delete_attachments (cal_cache, icalcomp, cancellable, &local_error)) {
		if (rid && !*rid)
			rid = NULL;

		g_debug ("%s: Failed to remove attachments for '%s%s%s': %s", G_STRFUNC,
			uid, rid ? "|" : "", rid ? rid : "", local_error ? local_error->message : "Unknown error");
		g_clear_error (&local_error);
	}

	icalcomponent_free (icalcomp);

	return !g_cancellable_is_cancelled (cancellable);
}

static gboolean
ecc_empty_aux_tables (ECache *cache,
		      GCancellable *cancellable,
		      GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cache), FALSE);

	stmt = e_cache_sqlite_stmt_printf ("DELETE FROM %Q", ECC_TABLE_TIMEZONES);
	success = e_cache_sqlite_exec (cache, stmt, cancellable, error);
	e_cache_sqlite_stmt_free (stmt);

	return success;
}

/* The default revision is a concatenation of
   <DTSTAMP> "-" <LAST-MODIFIED> "-" <SEQUENCE> */
static gchar *
ecc_dup_component_revision (ECalCache *cal_cache,
			    icalcomponent *icalcomp)
{
	struct icaltimetype itt;
	icalproperty *prop;
	GString *revision;

	g_return_val_if_fail (icalcomp != NULL, NULL);

	revision = g_string_sized_new (48);

	itt = icalcomponent_get_dtstamp (icalcomp);
	if (icaltime_is_null_time (itt) || !icaltime_is_valid_time (itt)) {
		g_string_append_c (revision, 'x');
	} else {
		g_string_append_printf (revision, "%04d%02d%02d%02d%02d%02d",
			itt.year, itt.month, itt.day,
			itt.hour, itt.minute, itt.second);
	}

	g_string_append_c (revision, '-');

	prop = icalcomponent_get_first_property (icalcomp, ICAL_LASTMODIFIED_PROPERTY);
	if (prop)
		itt = icalproperty_get_lastmodified (prop);

	if (!prop || icaltime_is_null_time (itt) || !icaltime_is_valid_time (itt)) {
		g_string_append_c (revision, 'x');
	} else {
		g_string_append_printf (revision, "%04d%02d%02d%02d%02d%02d",
			itt.year, itt.month, itt.day,
			itt.hour, itt.minute, itt.second);
	}

	g_string_append_c (revision, '-');

	prop = icalcomponent_get_first_property (icalcomp, ICAL_SEQUENCE_PROPERTY);
	if (!prop) {
		g_string_append_c (revision, 'x');
	} else {
		g_string_append_printf (revision, "%d", icalproperty_get_sequence (prop));
	}

	return g_string_free (revision, FALSE);
}

static gboolean
e_cal_cache_put_locked (ECache *cache,
			const gchar *uid,
			const gchar *revision,
			const gchar *object,
			ECacheColumnValues *other_columns,
			EOfflineState offline_state,
			gboolean is_replace,
			GCancellable *cancellable,
			GError **error)
{
	GHashTable *timezones = NULL; /* gchar *tzid ~> TimezoneMigrationData * */
	ECalCache *cal_cache;
	ECalComponent *comp;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_cal_cache_parent_class)->put_locked != NULL, FALSE);

	cal_cache = E_CAL_CACHE (cache);

	comp = e_cal_component_new_from_string (object);
	if (!comp)
		return FALSE;

	ecc_fill_other_columns (cal_cache, other_columns, comp);

	if (!cal_cache->priv->initializing) {
		timezones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, timezone_migration_data_free);

		ecc_count_timezones_for_component (cal_cache, timezones, e_cal_component_get_icalcomponent (comp), TRUE, cancellable);

		if (is_replace)
			ecc_count_timezones_for_old_component (cal_cache, timezones, uid, cancellable);
	}

	success = E_CACHE_CLASS (e_cal_cache_parent_class)->put_locked (cache, uid, revision, object, other_columns, offline_state,
		is_replace, cancellable, error);

	if (success)
		success = ecc_update_timezones_table (cal_cache, timezones, cancellable, error);

	if (timezones)
		g_hash_table_destroy (timezones);

	g_clear_object (&comp);

	return success;
}

static gboolean
e_cal_cache_remove_locked (ECache *cache,
			   const gchar *uid,
			   GCancellable *cancellable,
			   GError **error)
{
	GHashTable *timezones = NULL; /* gchar *tzid ~> TimezoneMigrationData * */
	ECalCache *cal_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	cal_cache = E_CAL_CACHE (cache);

	if (!cal_cache->priv->initializing) {
		timezones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, timezone_migration_data_free);

		ecc_count_timezones_for_old_component (cal_cache, timezones, uid, cancellable);
	}

	success = E_CACHE_CLASS (e_cal_cache_parent_class)->remove_locked (cache, uid, cancellable, error);

	if (success)
		success = ecc_update_timezones_table (cal_cache, timezones, cancellable, error);

	if (timezones)
		g_hash_table_destroy (timezones);

	return success;
}

static gboolean
e_cal_cache_remove_all_locked (ECache *cache,
			       const GSList *uids,
			       GCancellable *cancellable,
			       GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_cal_cache_parent_class)->remove_all_locked != NULL, FALSE);

	/* Cannot free content of priv->loaded_timezones and priv->modified_timezones,
	   because those can be used anywhere */
	success = ecc_empty_aux_tables (cache, cancellable, error) &&
		e_cal_cache_search_with_callback (E_CAL_CACHE (cache), NULL,
		ecc_search_delete_attachment_cb, cancellable, cancellable, error);

	success = success && E_CACHE_CLASS (e_cal_cache_parent_class)->remove_all_locked (cache, uids, cancellable, error);

	return success;
}

static void
cal_cache_free_zone (gpointer ptr)
{
	icaltimezone *zone = ptr;

	if (zone)
		icaltimezone_free (zone, 1);
}

static void
ecc_add_cached_timezone (ETimezoneCache *cache,
			 icaltimezone *zone)
{
	ECalCache *cal_cache;

	cal_cache = E_CAL_CACHE (cache);

	if (!zone || ecc_tzid_is_libical_builtin (icaltimezone_get_tzid (zone)))
		return;

	e_cal_cache_put_timezone (cal_cache, zone, 0, NULL, NULL);
}

static icaltimezone *
ecc_get_cached_timezone (ETimezoneCache *cache,
			 const gchar *tzid)
{
	ECalCache *cal_cache;
	icaltimezone *zone = NULL;
	icaltimezone *builtin_zone = NULL;
	icalcomponent *icalcomp;
	icalproperty *prop;
	const gchar *builtin_tzid;

	cal_cache = E_CAL_CACHE (cache);

	if (g_str_equal (tzid, "UTC"))
		return icaltimezone_get_utc_timezone ();

	g_rec_mutex_lock (&cal_cache->priv->timezones_lock);

	/* See if we already have it in the cache. */
	zone = g_hash_table_lookup (cal_cache->priv->loaded_timezones, tzid);
	if (zone)
		goto exit;

	zone = g_hash_table_lookup (cal_cache->priv->modified_timezones, tzid);
	if (zone)
		goto exit;

	/* Try the location first */
	/*zone = icaltimezone_get_builtin_timezone (tzid);
	if (zone)
		goto exit;*/

	/* Try to replace the original time zone with a more complete
	 * and/or potentially updated built-in time zone.  Note this also
	 * applies to TZIDs which match built-in time zones exactly: they
	 * are extracted via icaltimezone_get_builtin_timezone_from_tzid(). */

	builtin_tzid = e_cal_match_tzid (tzid);

	if (builtin_tzid)
		builtin_zone = icaltimezone_get_builtin_timezone_from_tzid (builtin_tzid);

	if (!builtin_zone) {
		e_cal_cache_get_timezone (cal_cache, tzid, &zone, NULL, NULL);
		goto exit;
	}

	/* Use the built-in time zone *and* rename it.  Likely the caller
	 * is asking for a specific TZID because it has an event with such
	 * a TZID.  Returning an icaltimezone with a different TZID would
	 * lead to broken VCALENDARs in the caller. */

	icalcomp = icaltimezone_get_component (builtin_zone);
	icalcomp = icalcomponent_new_clone (icalcomp);

	prop = icalcomponent_get_first_property (icalcomp, ICAL_ANY_PROPERTY);

	while (prop != NULL) {
		if (icalproperty_isa (prop) == ICAL_TZID_PROPERTY) {
			icalproperty_set_value_from_string (prop, tzid, "NO");
			break;
		}

		prop = icalcomponent_get_next_property (icalcomp, ICAL_ANY_PROPERTY);
	}

	if (icalcomp != NULL) {
		zone = icaltimezone_new ();
		if (icaltimezone_set_component (zone, icalcomp)) {
			tzid = icaltimezone_get_tzid (zone);
			g_hash_table_insert (cal_cache->priv->modified_timezones, g_strdup (tzid), zone);
		} else {
			icalcomponent_free (icalcomp);
			icaltimezone_free (zone, 1);
			zone = NULL;
		}
	}

 exit:
	g_rec_mutex_unlock (&cal_cache->priv->timezones_lock);

	return zone;
}

static GList *
ecc_list_cached_timezones (ETimezoneCache *cache)
{
	GList *timezones = NULL;

	if (!e_cal_cache_list_timezones (E_CAL_CACHE (cache), &timezones, NULL, NULL))
		return NULL;

	return timezones;
}

static void
e_cal_cache_finalize (GObject *object)
{
	ECalCache *cal_cache = E_CAL_CACHE (object);

	g_hash_table_destroy (cal_cache->priv->loaded_timezones);
	g_hash_table_destroy (cal_cache->priv->modified_timezones);
	g_hash_table_destroy (cal_cache->priv->sexps);

	g_rec_mutex_clear (&cal_cache->priv->timezones_lock);
	g_mutex_clear (&cal_cache->priv->sexps_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cal_cache_parent_class)->finalize (object);
}

static void
e_cal_cache_class_init (ECalCacheClass *klass)
{
	GObjectClass *object_class;
	ECacheClass *cache_class;

	g_type_class_add_private (klass, sizeof (ECalCachePrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = e_cal_cache_finalize;

	cache_class = E_CACHE_CLASS (klass);
	cache_class->put_locked = e_cal_cache_put_locked;
	cache_class->remove_locked = e_cal_cache_remove_locked;
	cache_class->remove_all_locked = e_cal_cache_remove_all_locked;

	klass->dup_component_revision = ecc_dup_component_revision;

	/**
	 * ECalCache:dup-component-revision:
	 * A signal being called to get revision of an icalcomponent.
	 * The default implementation uses a concatenation of
	 * DTSTAMP '-' LASTMODIFIED '-' SEQUENCE.
	 **/
	signals[DUP_COMPONENT_REVISION] = g_signal_new (
		"dup-component-revision",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (ECalCacheClass, dup_component_revision),
		g_signal_accumulator_first_wins,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_STRING, 1,
		G_TYPE_POINTER);

	/**
	 * ECalCache:get-timezone:
	 * @cal_cache: an #ECalCache
	 * @tzid: timezone ID
	 *
	 * A signal being called to get timezone when putting component
	 * into the cache. It's used to make sure the cache contains
	 * all timezones which are needed by the component. The returned
	 * icaltimezone will not be freed.
	 *
	 * Since: 3.30
	 **/
	signals[GET_TIMEZONE] = g_signal_new (
		"get-timezone",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (ECalCacheClass, get_timezone),
		g_signal_accumulator_first_wins,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_POINTER, 1,
		G_TYPE_STRING);
}

static void
ecc_timezone_cache_init (ETimezoneCacheInterface *iface)
{
	iface->add_timezone = ecc_add_cached_timezone;
	iface->get_timezone = ecc_get_cached_timezone;
	iface->list_timezones = ecc_list_cached_timezones;
}

static void
e_cal_cache_init (ECalCache *cal_cache)
{
	cal_cache->priv = G_TYPE_INSTANCE_GET_PRIVATE (cal_cache, E_TYPE_CAL_CACHE, ECalCachePrivate);
	cal_cache->priv->loaded_timezones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, cal_cache_free_zone);
	cal_cache->priv->modified_timezones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, cal_cache_free_zone);

	cal_cache->priv->sexps = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, g_object_unref);

	g_rec_mutex_init (&cal_cache->priv->timezones_lock);
	g_mutex_init (&cal_cache->priv->sexps_lock);
}
