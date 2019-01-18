/* Evolution calendar - Live search view implementation
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 */

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_DATA_CAL_VIEW_H
#define E_DATA_CAL_VIEW_H

#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_DATA_CAL_VIEW \
	(e_data_cal_view_get_type ())
#define E_DATA_CAL_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_CAL_VIEW, EDataCalView))
#define E_DATA_CAL_VIEW_CLASS(klass) \
	(G_TYPE_CHECK_CLASS_CAST \
	((klass), E_TYPE_DATA_CAL_VIEW, EDataCalViewClass))
#define E_IS_DATA_CAL_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_CAL_VIEW))
#define E_IS_DATA_CAL_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_CAL_VIEW))
#define E_DATA_CAL_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_CAL_VIEW, EDataCalViewClass))

G_BEGIN_DECLS

struct _ECalBackend;
struct _ECalBackendSExp;

typedef struct _EDataCalView EDataCalView;
typedef struct _EDataCalViewClass EDataCalViewClass;
typedef struct _EDataCalViewPrivate EDataCalViewPrivate;

struct _EDataCalView {
	GObject parent;
	EDataCalViewPrivate *priv;
};

struct _EDataCalViewClass {
	GObjectClass parent_class;
};

GType		e_data_cal_view_get_type	(void) G_GNUC_CONST;
EDataCalView *	e_data_cal_view_new		(struct _ECalBackend *backend,
						 struct _ECalBackendSExp *sexp,
						 GDBusConnection *connection,
						 const gchar *object_path,
						 GError **error);
struct _ECalBackend *
		e_data_cal_view_get_backend	(EDataCalView *view);
GDBusConnection *
		e_data_cal_view_get_connection	(EDataCalView *view);
const gchar *	e_data_cal_view_get_object_path	(EDataCalView *view);
struct _ECalBackendSExp *
		e_data_cal_view_get_sexp	(EDataCalView *view);
gboolean	e_data_cal_view_object_matches	(EDataCalView *view,
						 const gchar *object);
gboolean	e_data_cal_view_component_matches
						(EDataCalView *view,
						 ECalComponent *component);
gboolean	e_data_cal_view_is_started	(EDataCalView *view);
gboolean	e_data_cal_view_is_completed	(EDataCalView *view);
gboolean	e_data_cal_view_is_stopped	(EDataCalView *view);
GHashTable *	e_data_cal_view_get_fields_of_interest
						(EDataCalView *view);
ECalClientViewFlags
		e_data_cal_view_get_flags	(EDataCalView *view);

gchar *		e_data_cal_view_get_component_string
						(EDataCalView *view,
						 ECalComponent *component);

void		e_data_cal_view_notify_components_added
						(EDataCalView *view,
						 const GSList *ecalcomponents);
void		e_data_cal_view_notify_components_added_1
						(EDataCalView *view,
						 ECalComponent *component);
void		e_data_cal_view_notify_components_modified
						(EDataCalView *view,
						 const GSList *ecalcomponents);
void		e_data_cal_view_notify_components_modified_1
						(EDataCalView *view,
						 ECalComponent *component);

void		e_data_cal_view_notify_objects_removed
						(EDataCalView *view,
						 const GSList *ids);
void		e_data_cal_view_notify_objects_removed_1
						(EDataCalView *view,
						 const ECalComponentId *id);
void		e_data_cal_view_notify_progress	(EDataCalView *view,
						 gint percent,
						 const gchar *message);
void		e_data_cal_view_notify_complete	(EDataCalView *view,
						 const GError *error);

G_END_DECLS

#endif /* E_DATA_CAL_VIEW_H */
