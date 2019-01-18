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

#ifndef EDS_DISABLE_DEPRECATED

#ifndef E_CAL_VIEW_H
#define E_CAL_VIEW_H

#include <glib-object.h>
#include <libecal/e-cal-types.h>

/* Standard GObject macros */
#define E_TYPE_CAL_VIEW \
	(e_cal_view_get_type ())
#define E_CAL_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_VIEW, ECalView))
#define E_CAL_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_VIEW, ECalViewClass))
#define E_IS_CAL_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_VIEW))
#define E_IS_CAL_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_VIEW))
#define E_CAL_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_VIEW, ECalViewClass))

G_BEGIN_DECLS

typedef struct _ECalView ECalView;
typedef struct _ECalViewClass ECalViewClass;
typedef struct _ECalViewPrivate ECalViewPrivate;

struct _ECal;

struct _ECalView {
	GObject object;
	ECalViewPrivate *priv;
};

struct _ECalViewClass {
	GObjectClass parent_class;

	/* Signals */
	void	(*objects_added)		(ECalView *cal_view,
						 GList *objects);
	void	(*objects_modified)		(ECalView *cal_view,
						 GList *objects);
	void	(*objects_removed)		(ECalView *cal_view,
						 GList *uids);
	void	(*view_progress)		(ECalView *cal_view,
						 gchar *message,
						 gint percent);
	void	(*view_done)			(ECalView *cal_view,
						 ECalendarStatus status);
	void	(*view_complete)		(ECalView *cal_view,
						 ECalendarStatus status,
						 const gchar *error_msg);
};

GType		e_cal_view_get_type		(void);
struct _ECal *	e_cal_view_get_client		(ECalView *cal_view);
void		e_cal_view_start		(ECalView *cal_view);
void		e_cal_view_stop			(ECalView *cal_view);

G_END_DECLS

#endif /* E_CAL_VIEW_H */

#endif /* EDS_DISABLE_DEPRECATED */
