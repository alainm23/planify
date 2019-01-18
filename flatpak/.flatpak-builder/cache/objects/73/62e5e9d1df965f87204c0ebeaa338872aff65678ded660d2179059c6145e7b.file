/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-cal-backend-store.h
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

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_CAL_BACKEND_STORE_H
#define E_CAL_BACKEND_STORE_H

#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_CAL_BACKEND_STORE \
	(e_cal_backend_store_get_type ())
#define E_CAL_BACKEND_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_STORE, ECalBackendStore))
#define E_CAL_BACKEND_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_STORE, ECalBackendStoreClass))
#define E_IS_CAL_BACKEND_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_STORE))
#define E_IS_CAL_BACKEND_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_STORE))
#define E_CAL_BACKEND_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_STORE, ECalBackendStoreClass))

G_BEGIN_DECLS

typedef struct _ECalBackendStore ECalBackendStore;
typedef struct _ECalBackendStoreClass ECalBackendStoreClass;
typedef struct _ECalBackendStorePrivate ECalBackendStorePrivate;

/**
 * ECalBackendStore:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 2.28
 **/
struct _ECalBackendStore {
	/*< private >*/
	GObject parent;
	ECalBackendStorePrivate *priv;
};

/**
 * ECalBackendStoreClass:
 * @load: FIXME: Doxument me
 * @clean: FIXME: Doxument me
 * @get_component: FIXME: Doxument me
 * @put_component: FIXME: Doxument me
 * @remove_component: FIXME: Doxument me
 * @has_component: FIXME: Doxument me
 * @get_components_by_uid: FIXME: Doxument me
 * @get_components: FIXME: Doxument me
 * @get_component_ids: FIXME: Doxument me
 * @get_default_timezone: FIXME: Doxument me
 * @set_default_timezone: FIXME: Doxument me
 * @thaw_changes: FIXME: Doxument me
 * @freeze_changes: FIXME: Doxument me
 * @get_key_value: FIXME: Doxument me
 * @put_key_value: FIXME: Doxument me
 *
 * Class structure for the #ECalBackendStore class.
 *
 * Since: 2.28
 */
struct _ECalBackendStoreClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/

	/* virtual methods */
	gboolean	(*load)			(ECalBackendStore *store);
	gboolean	(*clean)		(ECalBackendStore *store);
	ECalComponent *	(*get_component)	(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
	gboolean	(*put_component)	(ECalBackendStore *store,
						 ECalComponent *comp);
	gboolean	(*remove_component)	(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
	gboolean	(*has_component)	(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
	GSList *	(*get_components_by_uid)(ECalBackendStore *store,
						 const gchar *uid);
	GSList *	(*get_components)	(ECalBackendStore *store);

	GSList *	(*get_component_ids)	(ECalBackendStore *store);
	const icaltimezone *
			(*get_default_timezone)	(ECalBackendStore *store);
	gboolean	(*set_default_timezone)	(ECalBackendStore *store,
						 icaltimezone *zone);
	void		(*thaw_changes)		(ECalBackendStore *store);
	void		(*freeze_changes)	(ECalBackendStore *store);
	const gchar *	(*get_key_value)	(ECalBackendStore *store,
						 const gchar *key);
	gboolean	(*put_key_value)	(ECalBackendStore *store,
						 const gchar *key,
						 const gchar *value);
};

GType		e_cal_backend_store_get_type	(void);
ECalBackendStore *
		e_cal_backend_store_new		(const gchar *path,
						 ETimezoneCache *cache);
const gchar *	e_cal_backend_store_get_path	(ECalBackendStore *store);
ETimezoneCache *
		e_cal_backend_store_ref_timezone_cache
						(ECalBackendStore *store);
gboolean	e_cal_backend_store_load	(ECalBackendStore *store);
gboolean	e_cal_backend_store_is_loaded	(ECalBackendStore *store);
gboolean	e_cal_backend_store_clean	(ECalBackendStore *store);
ECalComponent *	e_cal_backend_store_get_component
						(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
gboolean	e_cal_backend_store_put_component_with_time_range
						(ECalBackendStore *store,
						 ECalComponent *comp,
						 time_t occurence_start,
						 time_t occurence_end);
gboolean	e_cal_backend_store_put_component
						(ECalBackendStore *store,
						 ECalComponent *comp);
gboolean	e_cal_backend_store_remove_component
						(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
gboolean	e_cal_backend_store_has_component
						(ECalBackendStore *store,
						 const gchar *uid,
						 const gchar *rid);
const icaltimezone *
		e_cal_backend_store_get_default_timezone
						(ECalBackendStore *store);
gboolean	e_cal_backend_store_set_default_timezone
						(ECalBackendStore *store,
						 icaltimezone *zone);
GSList *	e_cal_backend_store_get_components_by_uid
						(ECalBackendStore *store,
						 const gchar *uid);
gchar *		e_cal_backend_store_get_components_by_uid_as_ical_string
						(ECalBackendStore *store,
						 const gchar *uid);
GSList *	e_cal_backend_store_get_components
						(ECalBackendStore *store);
GSList *	e_cal_backend_store_get_components_occuring_in_range
						(ECalBackendStore *store,
						 time_t start,
						 time_t end);
GSList *	e_cal_backend_store_get_component_ids
						(ECalBackendStore *store);
const gchar *	e_cal_backend_store_get_key_value
						(ECalBackendStore *store,
						 const gchar *key);
gboolean	e_cal_backend_store_put_key_value
						(ECalBackendStore *store,
						 const gchar *key,
						 const gchar *value);
void		e_cal_backend_store_thaw_changes (ECalBackendStore *store);
void		e_cal_backend_store_freeze_changes
						(ECalBackendStore *store);
void		e_cal_backend_store_interval_tree_add_comp
						(ECalBackendStore *store,
						 ECalComponent *comp,
						 time_t occurence_start,
						 time_t occurence_end);

G_END_DECLS

#endif /* E_CAL_BACKEND_STORE_H */
