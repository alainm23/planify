/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - Live view client object
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2009 Intel Corporation
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
 *          Ross Burton <ross@linux.intel.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include "e-cal.h"
#include "e-cal-view.h"
#include "e-cal-view-private.h"

#define E_CAL_VIEW_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_VIEW, ECalViewPrivate))

/* Private part of the ECalView structure */
struct _ECalViewPrivate {
	ECal *cal;
	ECalClientView *client_view;

	gulong objects_added_handler_id;
	gulong objects_modified_handler_id;
	gulong objects_removed_handler_id;
	gulong progress_handler_id;
	gulong complete_handler_id;
};

/* Signal IDs */
enum {
	OBJECTS_ADDED,
	OBJECTS_MODIFIED,
	OBJECTS_REMOVED,
	VIEW_PROGRESS,
	VIEW_DONE,
	VIEW_COMPLETE,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (ECalView, e_cal_view, G_TYPE_OBJECT);

static void
cal_view_objects_added_cb (ECalClientView *client_view,
                           const GSList *slist,
                           ECalView *cal_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (cal_view, signals[OBJECTS_ADDED], 0, list);

	g_list_free (list);
}

static void
cal_view_objects_modified_cb (ECalClientView *client_view,
                              const GSList *slist,
                              ECalView *cal_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (cal_view, signals[OBJECTS_MODIFIED], 0, list);

	g_list_free (list);
}

static void
cal_view_objects_removed_cb (ECalClientView *client_view,
                             const GSList *slist,
                             ECalView *cal_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (cal_view, signals[OBJECTS_REMOVED], 0, list);

	g_list_free (list);
}

static void
cal_view_progress_cb (ECalClientView *client_view,
                      guint percent,
                      const gchar *message,
                      ECalView *cal_view)
{
	g_signal_emit (cal_view, signals[VIEW_PROGRESS], 0, message, percent);
}

static void
cal_view_complete_cb (ECalClientView *client_view,
                      const GError *error,
                      ECalView *cal_view)
{
	ECalendarStatus status;
	const gchar *message;

	status = (error != NULL) ? error->code : 0;
	message = (error != NULL) ? error->message : "";

	g_signal_emit (cal_view, signals[VIEW_DONE], 0, status);
	g_signal_emit (cal_view, signals[VIEW_COMPLETE], 0, status, message);
}

static void
cal_view_dispose (GObject *object)
{
	ECalViewPrivate *priv;

	priv = E_CAL_VIEW_GET_PRIVATE (object);

	if (priv->cal != NULL) {
		g_object_unref (priv->cal);
		priv->cal = NULL;
	}

	if (priv->client_view != NULL) {
		g_signal_handler_disconnect (
			priv->client_view,
			priv->objects_added_handler_id);
		g_signal_handler_disconnect (
			priv->client_view,
			priv->objects_modified_handler_id);
		g_signal_handler_disconnect (
			priv->client_view,
			priv->objects_removed_handler_id);
		g_signal_handler_disconnect (
			priv->client_view,
			priv->progress_handler_id);
		g_signal_handler_disconnect (
			priv->client_view,
			priv->complete_handler_id);
		g_object_unref (priv->client_view);
		priv->client_view = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_view_parent_class)->dispose (object);
}

static void
e_cal_view_class_init (ECalViewClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECalViewPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = cal_view_dispose;

	/**
	 * ECalView::objects-added:
	 * @view:: self
	 * @objects: (type GLib.List) (transfer none) (element-type long):
	 */
	signals[OBJECTS_ADDED] = g_signal_new (
		"objects_added",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, objects_added),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	/**
	 * ECalView::objects-modified:
	 * @view:: self
	 * @objects: (type GLib.List) (transfer none) (element-type long):
	 */
	signals[OBJECTS_MODIFIED] = g_signal_new (
		"objects_modified",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, objects_modified),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	/**
	 * ECalView::objects-removed:
	 * @view:: self
	 * @objects: (type GLib.List) (transfer none) (element-type ECalComponentId):
	 */
	signals[OBJECTS_REMOVED] = g_signal_new (
		"objects_removed",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, objects_removed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	signals[VIEW_PROGRESS] = g_signal_new (
		"view_progress",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, view_progress),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_STRING,
		G_TYPE_UINT);

	/* XXX The "view-done" signal is deprecated. */
	signals[VIEW_DONE] = g_signal_new (
		"view_done",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, view_done),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_INT);

	signals[VIEW_COMPLETE] = g_signal_new (
		"view_complete",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalViewClass, view_complete),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_UINT,
		G_TYPE_STRING);
}

static void
e_cal_view_init (ECalView *cal_view)
{
	cal_view->priv = E_CAL_VIEW_GET_PRIVATE (cal_view);
}

ECalView *
_e_cal_view_new (ECal *cal,
                 ECalClientView *client_view)
{
	ECalView *cal_view;
	gulong handler_id;

	g_return_val_if_fail (E_IS_CAL (cal), NULL);
	g_return_val_if_fail (E_IS_CAL_CLIENT_VIEW (client_view), NULL);

	cal_view = g_object_new (E_TYPE_CAL_VIEW, NULL);

	cal_view->priv->cal = g_object_ref (cal);
	cal_view->priv->client_view = g_object_ref (client_view);

	handler_id = g_signal_connect (
		client_view, "objects-added",
		G_CALLBACK (cal_view_objects_added_cb), cal_view);
	cal_view->priv->objects_added_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "objects-modified",
		G_CALLBACK (cal_view_objects_modified_cb), cal_view);
	cal_view->priv->objects_modified_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "objects-removed",
		G_CALLBACK (cal_view_objects_removed_cb), cal_view);
	cal_view->priv->objects_removed_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "progress",
		G_CALLBACK (cal_view_progress_cb), cal_view);
	cal_view->priv->progress_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "complete",
		G_CALLBACK (cal_view_complete_cb), cal_view);
	cal_view->priv->complete_handler_id = handler_id;

	return cal_view;
}

/**
 * e_cal_view_get_client: (skip)
 * @cal_view: A #ECalView object.
 *
 * Get the #ECal associated with this view.
 *
 * Returns: (transfer none): the associated client.
 *
 * Since: 2.22
 *
 * Deprecated: 3.2: Use #ECalClientView
 */
ECal *
e_cal_view_get_client (ECalView *cal_view)
{
	g_return_val_if_fail (E_IS_CAL_VIEW (cal_view), NULL);

	return cal_view->priv->cal;
}

/**
 * e_cal_view_start:
 * @cal_view: A #ECalView object.
 *
 * Starts a live query to the calendar/tasks backend.
 *
 * Since: 2.22
 *
 * Deprecated: 3.2: Use #ECalClientView
 */
void
e_cal_view_start (ECalView *cal_view)
{
	GError *error = NULL;

	g_return_if_fail (E_IS_CAL_VIEW (cal_view));

	e_cal_client_view_start (cal_view->priv->client_view, &error);

	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);

		/* Fake a sequence-complete so the
		 * application knows this failed. */
		g_signal_emit (
			cal_view, signals[VIEW_DONE], 0,
			E_CALENDAR_STATUS_DBUS_EXCEPTION);
		g_signal_emit (
			cal_view, signals[VIEW_COMPLETE], 0,
			E_CALENDAR_STATUS_DBUS_EXCEPTION, error->message);

		g_error_free (error);
	}
}

/**
 * e_cal_view_stop:
 * @cal_view: A #ECalView object.
 *
 * Stops a live query to the calendar/tasks backend.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #ECalClientView
 */
void
e_cal_view_stop (ECalView *cal_view)
{
	GError *error = NULL;

	g_return_if_fail (E_IS_CAL_VIEW (cal_view));

	e_cal_client_view_stop (cal_view->priv->client_view, &error);

	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
	}
}

