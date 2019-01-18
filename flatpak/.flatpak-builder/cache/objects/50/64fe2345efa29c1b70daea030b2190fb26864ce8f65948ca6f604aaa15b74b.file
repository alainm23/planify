/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_CAL_CACHE_H
#define E_CAL_CACHE_H

#include <libebackend/libebackend.h>
#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_CAL_CACHE \
	(e_cal_cache_get_type ())
#define E_CAL_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_CACHE, ECalCache))
#define E_CAL_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_CACHE, ECalCacheClass))
#define E_IS_CAL_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_CACHE))
#define E_IS_CAL_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_CACHE))
#define E_CAL_CACHE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_CACHE, ECalCacheClass))

G_BEGIN_DECLS

typedef struct _ECalCache ECalCache;
typedef struct _ECalCacheClass ECalCacheClass;
typedef struct _ECalCachePrivate ECalCachePrivate;

/**
 * ECalCacheOfflineChange:
 * @uid: UID of the component
 * @rid: Recurrence-ID of the component
 * @revision: stored revision of the component
 * @object: the component itself, as iCalalendar string
 * @state: an #EOfflineState of the component
 *
 * Holds the information about offline change for one component.
 *
 * Since: 3.26
 **/
typedef struct {
	gchar *uid;
	gchar *rid;
	gchar *revision;
	gchar *object;
	EOfflineState state;
} ECalCacheOfflineChange;

#define E_TYPE_CAL_CACHE_OFFLINE_CHANGE (e_cal_cache_offline_change_get_type ())

GType		e_cal_cache_offline_change_get_type
						(void) G_GNUC_CONST;
ECalCacheOfflineChange *
		e_cal_cache_offline_change_new	(const gchar *uid,
						 const gchar *rid,
						 const gchar *revision,
						 const gchar *object,
						 EOfflineState state);
ECalCacheOfflineChange *
		e_cal_cache_offline_change_copy	(const ECalCacheOfflineChange *change);
void		e_cal_cache_offline_change_free	(/* ECalCacheOfflineChange */ gpointer change);

/**
 * ECalCacheSearchData:
 * @uid: the UID of this component
 * @rid: (nullable): the Recurrence-ID of this component
 * @object: the component string
 * @extra: any extra data associated with the component
 *
 * This structure is used to represent components returned
 * by the #ECalCache from various functions
 * such as e_cal_cache_search().
 *
 * The @extra parameter will contain any data which was
 * previously passed for this component in e_cal_cache_put_component()
 * or set with e_cal_cache_set_component_extra().
 *
 * These should be freed with e_cal_cache_search_data_free().
 *
 * Since: 3.26
 **/
typedef struct {
	gchar *uid;
	gchar *rid;
	gchar *object;
	gchar *extra;
} ECalCacheSearchData;

#define E_TYPE_CAL_CACHE_SEARCH_DATA (e_cal_cache_search_data_get_type ())

GType		e_cal_cache_search_data_get_type
						(void) G_GNUC_CONST;
ECalCacheSearchData *
		e_cal_cache_search_data_new	(const gchar *uid,
						 const gchar *rid,
						 const gchar *object,
						 const gchar *extra);
ECalCacheSearchData *
		e_cal_cache_search_data_copy	(const ECalCacheSearchData *data);
void		e_cal_cache_search_data_free	(/* ECalCacheSearchData * */ gpointer ptr);

/**
 * ECalCacheSearchFunc:
 * @cal_cache: an #ECalCache
 * @uid: a unique object identifier
 * @rid: (nullable): an optional Recurrence-ID of the object
 * @revision: the object revision
 * @object: the object itself
 * @extra: extra data stored with the object
 * @offline_state: objects offline state, one of #EOfflineState
 * @user_data: user data, as used in e_cal_cache_search_with_callback()
 *
 * A callback called for each object row when using
 * e_cal_cache_search_with_callback() function.
 *
 * Returns: %TRUE to continue, %FALSE to stop walk through.
 *
 * Since: 3.26
 **/
typedef gboolean (* ECalCacheSearchFunc)	(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 const gchar *revision,
						 const gchar *object,
						 const gchar *extra,
						 EOfflineState offline_state,
						 gpointer user_data);

/**
 * ECalCache:
 *
 * Contains only private data that should be read and manipulated using
 * the functions below.
 *
 * Since: 3.26
 **/
struct _ECalCache {
	/*< private >*/
	ECache parent;
	ECalCachePrivate *priv;
};

/**
 * ECalCacheClass:
 *
 * Class structure for the #ECalCache class.
 *
 * Since: 3.26
 */
struct _ECalCacheClass {
	/*< private >*/
	ECacheClass parent_class;

	/* Signals */
	gchar *		(* dup_component_revision)
						(ECalCache *cal_cache,
						 icalcomponent *icalcomp);
	icaltimezone *	(* get_timezone)	(ECalCache *cal_cache,
						 const gchar *tzid);

	/* Padding for future expansion */
	gpointer reserved[9];
};

GType		e_cal_cache_get_type		(void) G_GNUC_CONST;

ECalCache *	e_cal_cache_new			(const gchar *filename,
						 GCancellable *cancellable,
						 GError **error);
gchar *		e_cal_cache_dup_component_revision
						(ECalCache *cal_cache,
						 icalcomponent *icalcomp);
gboolean	e_cal_cache_contains		(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 ECacheDeletedFlag deleted_flag);
gboolean	e_cal_cache_put_component	(ECalCache *cal_cache,
						 ECalComponent *component,
						 const gchar *extra,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_put_components	(ECalCache *cal_cache,
						 const GSList *components, /* ECalComponent * */
						 const GSList *extras, /* gchar * */
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_remove_component	(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_remove_components	(ECalCache *cal_cache,
						 const GSList *ids, /* ECalComponentId * */
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_component	(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 ECalComponent **out_component,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_component_as_string
						(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 gchar **out_icalstring,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_set_component_extra	(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 const gchar *extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_component_extra	(ECalCache *cal_cache,
						 const gchar *uid,
						 const gchar *rid,
						 gchar **out_extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_ids_with_extra	(ECalCache *cal_cache,
						 const gchar *extra,
						 GSList **out_ids, /* ECalComponentId * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_components_by_uid
						(ECalCache *cal_cache,
						 const gchar *uid,
						 GSList **out_components, /* ECalComponent * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_components_by_uid_as_string
						(ECalCache *cal_cache,
						 const gchar *uid,
						 GSList **out_icalstrings, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_components_in_range
						(ECalCache *cal_cache,
						 time_t range_start,
						 time_t range_end,
						 GSList **out_components, /* ECalComponent * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_components_in_range_as_strings
						(ECalCache *cal_cache,
						 time_t range_start,
						 time_t range_end,
						 GSList **out_icalstrings, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_search		(ECalCache *cal_cache,
						 const gchar *sexp,
						 GSList **out_data, /* ECalCacheSearchData * * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_search_components	(ECalCache *cal_cache,
						 const gchar *sexp,
						 GSList **out_components, /* ECalComponent * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_search_ids		(ECalCache *cal_cache,
						 const gchar *sexp,
						 GSList **out_ids, /* ECalComponentId * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_search_with_callback
						(ECalCache *cal_cache,
						 const gchar *sexp,
						 ECalCacheSearchFunc func,
						 gpointer user_data,
						 GCancellable *cancellable,
						 GError **error);
GSList *	e_cal_cache_get_offline_changes	(ECalCache *cal_cache,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_delete_attachments	(ECalCache *cal_cache,
						 icalcomponent *component,
						 GCancellable *cancellable,
						 GError **error);

gboolean	e_cal_cache_put_timezone	(ECalCache *cal_cache,
						 const icaltimezone *zone,
						 guint inc_ref_counts,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_get_timezone	(ECalCache *cal_cache,
						 const gchar *tzid,
						 icaltimezone **out_zone,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_dup_timezone_as_string
						(ECalCache *cal_cache,
						 const gchar *tzid,
						 gchar **out_zone_string,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_list_timezones	(ECalCache *cal_cache,
						 GList **out_timezones,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_remove_timezone	(ECalCache *cal_cache,
						 const gchar *tzid,
						 guint dec_ref_counts,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_cache_remove_timezones	(ECalCache *cal_cache,
						 GCancellable *cancellable,
						 GError **error);
icaltimezone *	e_cal_cache_resolve_timezone_cb	(const gchar *tzid,
						 gpointer cal_cache,
						 GCancellable *cancellable,
						 GError **error);
icaltimezone *	e_cal_cache_resolve_timezone_simple_cb
						(const gchar *tzid,
						 gpointer cal_cache);

G_END_DECLS

#endif /* E_CAL_CACHE_H */
