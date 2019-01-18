/* Evolution calendar - Live view client object
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

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef E_CAL_CLIENT_VIEW_H
#define E_CAL_CLIENT_VIEW_H

#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_CAL_CLIENT_VIEW \
	(e_cal_client_view_get_type ())
#define E_CAL_CLIENT_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_CLIENT_VIEW, ECalClientView))
#define E_CAL_CLIENT_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_CLIENT_VIEW, ECalClientViewClass))
#define E_IS_CAL_CLIENT_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_CLIENT_VIEW))
#define E_IS_CAL_CLIENT_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_CLIENT_VIEW))
#define E_CAL_CLIENT_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_CLIENT_VIEW, ECalClientViewClass))

G_BEGIN_DECLS

typedef struct _ECalClientView ECalClientView;
typedef struct _ECalClientViewClass ECalClientViewClass;
typedef struct _ECalClientViewPrivate ECalClientViewPrivate;

struct _ECalClient;

/**
 * ECalClientViewFlags:
 * @E_CAL_CLIENT_VIEW_FLAGS_NONE:
 *   Symbolic value for no flags
 * @E_CAL_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL:
 *   If this flag is set then all objects matching the view's query will
 *   be sent as notifications when starting the view, otherwise only future
 *   changes will be reported.  The default for a #ECalClientView is %TRUE.
 *
 * Flags that control the behaviour of an #ECalClientView.
 *
 * Since: 3.6
 */
typedef enum {
	E_CAL_CLIENT_VIEW_FLAGS_NONE = 0,
	E_CAL_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL = (1 << 0)
} ECalClientViewFlags;

/**
 * ECalClientView:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
struct _ECalClientView {
	/*< private >*/
	GObject object;
	ECalClientViewPrivate *priv;
};

/**
 * ECalClientViewClass:
 * @objects_added: A signal emitted when new objects are added into the view
 * @objects_modified: A signal emitted when some objects are modified in the view
 * @objects_removed: A signal emitted when some objects are removed from the view
 * @progress: A signal emitted when the backend notifies about the progress
 * @complete: A signal emitted when the backend finished initial view population
 *
 * Base class structure for the #ECalClientView class
 **/
struct _ECalClientViewClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/
	/* Signals */
	void		(*objects_added)	(ECalClientView *client_view,
						 const GSList *objects);
	void		(*objects_modified)	(ECalClientView *client_view,
						 const GSList *objects);
	void		(*objects_removed)	(ECalClientView *client_view,
						 const GSList *uids);
	void		(*progress)		(ECalClientView *client_view,
						 guint percent,
						 const gchar *message);
	void		(*complete)		(ECalClientView *client_view,
						 const GError *error);
};

GType		e_cal_client_view_get_type	(void) G_GNUC_CONST;
struct _ECalClient *
		e_cal_client_view_ref_client	(ECalClientView *client_view);
GDBusConnection *
		e_cal_client_view_get_connection
						(ECalClientView *client_view);
const gchar *	e_cal_client_view_get_object_path
						(ECalClientView *client_view);
gboolean	e_cal_client_view_is_running	(ECalClientView *client_view);
void		e_cal_client_view_set_fields_of_interest
						(ECalClientView *client_view,
						 const GSList *fields_of_interest,
						 GError **error);
void		e_cal_client_view_start		(ECalClientView *client_view,
						 GError **error);
void		e_cal_client_view_stop		(ECalClientView *client_view,
						 GError **error);
void		e_cal_client_view_set_flags	(ECalClientView *client_view,
						 ECalClientViewFlags flags,
						 GError **error);

#ifndef EDS_DISABLE_DEPRECATED
struct _ECalClient *
		e_cal_client_view_get_client	(ECalClientView *client_view);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_CAL_CLIENT_VIEW_H */
