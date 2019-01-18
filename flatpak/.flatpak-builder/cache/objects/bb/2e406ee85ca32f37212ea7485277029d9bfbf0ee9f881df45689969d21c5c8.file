/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - Live search view implementation
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

/**
 * SECTION: e-data-cal-view
 * @include: libedata-cal/libedata-cal.h
 * @short_description: A server side object for issuing view notifications
 *
 * This class communicates with #ECalClientViews over the bus.
 *
 * Calendar backends can automatically own a number of views requested
 * by the client, this API can be used by the backend to issue notifications
 * which will be delivered to the #ECalClientView
 **/

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-cal-backend.h"
#include "e-cal-backend-sexp.h"
#include "e-data-cal-view.h"
#include "e-dbus-calendar-view.h"

#define E_DATA_CAL_VIEW_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DATA_CAL_VIEW, EDataCalViewPrivate))

/* how many items can be hold in a cache, before propagated to UI */
#define THRESHOLD_ITEMS 32

/* how long to wait until notifications are propagated to UI; in seconds */
#define THRESHOLD_SECONDS 2

struct _EDataCalViewPrivate {
	GDBusConnection *connection;
	EDBusCalendarView *dbus_object;
	gchar *object_path;

	/* The backend we are monitoring */
	ECalBackend *backend;

	gboolean started;
	gboolean stopped;
	gboolean complete;

	/* Sexp that defines the view */
	ECalBackendSExp *sexp;

	GArray *adds;
	GArray *changes;
	GArray *removes;

	GHashTable *ids;

	GMutex pending_mutex;
	guint flush_id;

	/* view flags */
	ECalClientViewFlags flags;

	/* which fields is listener interested in */
	GHashTable *fields_of_interest;
};

enum {
	PROP_0,
	PROP_BACKEND,
	PROP_CONNECTION,
	PROP_OBJECT_PATH,
	PROP_SEXP
};

/* Forward Declarations */
static void	e_data_cal_view_initable_init	(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EDataCalView,
	e_data_cal_view,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_data_cal_view_initable_init))

static guint
str_ic_hash (gconstpointer key)
{
	guint32 hash = 5381;
	const gchar *str = key;
	gint ii;

	if (str == NULL)
		return hash;

	for (ii = 0; str[ii] != '\0'; ii++)
		hash = hash * 33 + g_ascii_tolower (str[ii]);

	return hash;
}

static gboolean
str_ic_equal (gconstpointer a,
              gconstpointer b)
{
	const gchar *stra = a;
	const gchar *strb = b;
	gint ii;

	if (stra == NULL && strb == NULL)
		return TRUE;

	if (stra == NULL || strb == NULL)
		return FALSE;

	for (ii = 0; stra[ii] != '\0' && strb[ii] != '\0'; ii++) {
		if (g_ascii_tolower (stra[ii]) != g_ascii_tolower (strb[ii]))
			return FALSE;
	}

	return stra[ii] == strb[ii];
}

static guint
id_hash (gconstpointer key)
{
	const ECalComponentId *id = key;

	return g_str_hash (id->uid) ^ (id->rid ? g_str_hash (id->rid) : 0);
}

static gboolean
id_equal (gconstpointer a,
          gconstpointer b)
{
	const ECalComponentId *id_a = a;
	const ECalComponentId *id_b = b;

	return (g_strcmp0 (id_a->uid, id_b->uid) == 0) &&
		(g_strcmp0 (id_a->rid, id_b->rid) == 0);
}

static void
reset_array (GArray *array)
{
	gint i = 0;
	gchar *tmp = NULL;

	/* Free stored strings */
	for (i = 0; i < array->len; i++) {
		tmp = g_array_index (array, gchar *, i);
		g_free (tmp);
	}

	/* Force the array size to 0 */
	g_array_set_size (array, 0);
}

static gpointer
calview_start_thread (gpointer data)
{
	EDataCalView *view = data;

	if (view->priv->started && !view->priv->stopped)
		e_cal_backend_start_view (view->priv->backend, view);
	g_object_unref (view);

	return NULL;
}

static gboolean
impl_DataCalView_start (EDBusCalendarView *object,
                        GDBusMethodInvocation *invocation,
                        EDataCalView *view)
{
	if (!view->priv->started) {
		GThread *thread;

		view->priv->started = TRUE;
		e_debug_log (
			FALSE, E_DEBUG_LOG_DOMAIN_CAL_QUERIES,
			"---;%p;VIEW-START;%s;%s", view,
			e_cal_backend_sexp_text (view->priv->sexp),
			G_OBJECT_TYPE_NAME (view->priv->backend));

		thread = g_thread_new (
			NULL, calview_start_thread, g_object_ref (view));
		g_thread_unref (thread);
	}

	e_dbus_calendar_view_complete_start (object, invocation);

	return TRUE;
}

static gpointer
calview_stop_thread (gpointer data)
{
	EDataCalView *view = data;

	if (view->priv->stopped)
		e_cal_backend_stop_view (view->priv->backend, view);
	g_object_unref (view);

	return NULL;
}

static gboolean
impl_DataCalView_stop (EDBusCalendarView *object,
                       GDBusMethodInvocation *invocation,
                       EDataCalView *view)
{
	GThread *thread;

	view->priv->stopped = TRUE;

	thread = g_thread_new (NULL, calview_stop_thread, g_object_ref (view));
	g_thread_unref (thread);

	e_dbus_calendar_view_complete_stop (object, invocation);

	return TRUE;
}

static gboolean
impl_DataCalView_setFlags (EDBusCalendarView *object,
                           GDBusMethodInvocation *invocation,
                           ECalClientViewFlags flags,
                           EDataCalView *view)
{
	view->priv->flags = flags;

	e_dbus_calendar_view_complete_set_flags (object, invocation);

	return TRUE;
}

static gboolean
impl_DataCalView_dispose (EDBusCalendarView *object,
                          GDBusMethodInvocation *invocation,
                          EDataCalView *view)
{
	e_dbus_calendar_view_complete_dispose (object, invocation);

	e_cal_backend_stop_view (view->priv->backend, view);
	view->priv->stopped = TRUE;
	e_cal_backend_remove_view (view->priv->backend, view);

	return TRUE;
}

static gboolean
impl_DataCalView_set_fields_of_interest (EDBusCalendarView *object,
                                         GDBusMethodInvocation *invocation,
                                         const gchar * const *in_fields_of_interest,
                                         EDataCalView *view)
{
	gint ii;

	g_return_val_if_fail (in_fields_of_interest != NULL, TRUE);

	if (view->priv->fields_of_interest != NULL) {
		g_hash_table_destroy (view->priv->fields_of_interest);
		view->priv->fields_of_interest = NULL;
	}

	for (ii = 0; in_fields_of_interest[ii]; ii++) {
		const gchar *field = in_fields_of_interest[ii];

		if (!*field)
			continue;

		if (view->priv->fields_of_interest == NULL)
			view->priv->fields_of_interest =
				g_hash_table_new_full (
					(GHashFunc) str_ic_hash,
					(GEqualFunc) str_ic_equal,
					(GDestroyNotify) g_free,
					(GDestroyNotify) NULL);

		g_hash_table_insert (
			view->priv->fields_of_interest,
			g_strdup (field), GINT_TO_POINTER (1));
	}

	e_dbus_calendar_view_complete_set_fields_of_interest (object, invocation);

	return TRUE;
}

static void
data_cal_view_set_backend (EDataCalView *view,
                           ECalBackend *backend)
{
	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (view->priv->backend == NULL);

	view->priv->backend = g_object_ref (backend);
}

static void
data_cal_view_set_connection (EDataCalView *view,
                              GDBusConnection *connection)
{
	g_return_if_fail (G_IS_DBUS_CONNECTION (connection));
	g_return_if_fail (view->priv->connection == NULL);

	view->priv->connection = g_object_ref (connection);
}

static void
data_cal_view_set_object_path (EDataCalView *view,
                               const gchar *object_path)
{
	g_return_if_fail (object_path != NULL);
	g_return_if_fail (view->priv->object_path == NULL);

	view->priv->object_path = g_strdup (object_path);
}

static void
data_cal_view_set_sexp (EDataCalView *view,
                        ECalBackendSExp *sexp)
{
	g_return_if_fail (E_IS_CAL_BACKEND_SEXP (sexp));
	g_return_if_fail (view->priv->sexp == NULL);

	view->priv->sexp = g_object_ref (sexp);
}

static void
data_cal_view_set_property (GObject *object,
                            guint property_id,
                            const GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			data_cal_view_set_backend (
				E_DATA_CAL_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_CONNECTION:
			data_cal_view_set_connection (
				E_DATA_CAL_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_OBJECT_PATH:
			data_cal_view_set_object_path (
				E_DATA_CAL_VIEW (object),
				g_value_get_string (value));
			return;

		case PROP_SEXP:
			data_cal_view_set_sexp (
				E_DATA_CAL_VIEW (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_cal_view_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			g_value_set_object (
				value,
				e_data_cal_view_get_backend (
				E_DATA_CAL_VIEW (object)));
			return;

		case PROP_CONNECTION:
			g_value_set_object (
				value,
				e_data_cal_view_get_connection (
				E_DATA_CAL_VIEW (object)));
			return;

		case PROP_OBJECT_PATH:
			g_value_set_string (
				value,
				e_data_cal_view_get_object_path (
				E_DATA_CAL_VIEW (object)));
			return;

		case PROP_SEXP:
			g_value_set_object (
				value,
				e_data_cal_view_get_sexp (
				E_DATA_CAL_VIEW (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_cal_view_dispose (GObject *object)
{
	EDataCalViewPrivate *priv;

	priv = E_DATA_CAL_VIEW_GET_PRIVATE (object);

	g_mutex_lock (&priv->pending_mutex);

	if (priv->flush_id > 0) {
		g_source_remove (priv->flush_id);
		priv->flush_id = 0;
	}

	g_mutex_unlock (&priv->pending_mutex);

	g_clear_object (&priv->connection);
	g_clear_object (&priv->dbus_object);
	g_clear_object (&priv->backend);
	g_clear_object (&priv->sexp);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_data_cal_view_parent_class)->dispose (object);
}

static void
data_cal_view_finalize (GObject *object)
{
	EDataCalViewPrivate *priv;

	priv = E_DATA_CAL_VIEW_GET_PRIVATE (object);

	g_free (priv->object_path);

	reset_array (priv->adds);
	reset_array (priv->changes);
	reset_array (priv->removes);

	g_array_free (priv->adds, TRUE);
	g_array_free (priv->changes, TRUE);
	g_array_free (priv->removes, TRUE);

	g_hash_table_destroy (priv->ids);

	if (priv->fields_of_interest != NULL)
		g_hash_table_destroy (priv->fields_of_interest);

	g_mutex_clear (&priv->pending_mutex);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_data_cal_view_parent_class)->finalize (object);
}

static gboolean
data_cal_view_initable_init (GInitable *initable,
                             GCancellable *cancellable,
                             GError **error)
{
	EDataCalView *view;

	view = E_DATA_CAL_VIEW (initable);

	return g_dbus_interface_skeleton_export (
		G_DBUS_INTERFACE_SKELETON (view->priv->dbus_object),
		view->priv->connection,
		view->priv->object_path,
		error);
}

static void
e_data_cal_view_class_init (EDataCalViewClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EDataCalViewPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = data_cal_view_set_property;
	object_class->get_property = data_cal_view_get_property;
	object_class->dispose = data_cal_view_dispose;
	object_class->finalize = data_cal_view_finalize;

	g_object_class_install_property (
		object_class,
		PROP_BACKEND,
		g_param_spec_object (
			"backend",
			"Backend",
			"The backend being monitored",
			E_TYPE_CAL_BACKEND,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CONNECTION,
		g_param_spec_object (
			"connection",
			"Connection",
			"The GDBusConnection on which "
			"to export the view interface",
			G_TYPE_DBUS_CONNECTION,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_OBJECT_PATH,
		g_param_spec_string (
			"object-path",
			"Object Path",
			"The object path at which to "
			"export the view interface",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SEXP,
		g_param_spec_object (
			"sexp",
			"S-Expression",
			"The query expression for this view",
			E_TYPE_CAL_BACKEND_SEXP,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_data_cal_view_initable_init (GInitableIface *iface)
{
	iface->init = data_cal_view_initable_init;
}

static void
e_data_cal_view_init (EDataCalView *view)
{
	view->priv = E_DATA_CAL_VIEW_GET_PRIVATE (view);

	view->priv->flags = E_CAL_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL;

	view->priv->dbus_object = e_dbus_calendar_view_skeleton_new ();
	g_signal_connect (
		view->priv->dbus_object, "handle-start",
		G_CALLBACK (impl_DataCalView_start), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-stop",
		G_CALLBACK (impl_DataCalView_stop), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-set-flags",
		G_CALLBACK (impl_DataCalView_setFlags), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-dispose",
		G_CALLBACK (impl_DataCalView_dispose), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-set-fields-of-interest",
		G_CALLBACK (impl_DataCalView_set_fields_of_interest), view);

	view->priv->backend = NULL;
	view->priv->started = FALSE;
	view->priv->stopped = FALSE;
	view->priv->complete = FALSE;
	view->priv->sexp = NULL;
	view->priv->fields_of_interest = NULL;

	view->priv->adds = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS);
	view->priv->changes = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS);
	view->priv->removes = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS);

	view->priv->ids = g_hash_table_new_full (
		(GHashFunc) id_hash,
		(GEqualFunc) id_equal,
		(GDestroyNotify) e_cal_component_free_id,
		(GDestroyNotify) NULL);

	g_mutex_init (&view->priv->pending_mutex);
	view->priv->flush_id = 0;
}

/**
 * e_data_cal_view_new:
 * @backend: an #ECalBackend
 * @sexp: an #ECalBackendSExp
 * @connection: a #GDBusConnection
 * @object_path: an object path for the view
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EDataCalView and exports its D-Bus interface on
 * @connection at @object_path.  If an error occurs while exporting,
 * the function sets @error and returns %NULL.
 *
 * Returns: an #EDataCalView
 **/
EDataCalView *
e_data_cal_view_new (ECalBackend *backend,
                     ECalBackendSExp *sexp,
                     GDBusConnection *connection,
                     const gchar *object_path,
                     GError **error)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (E_IS_CAL_BACKEND_SEXP (sexp), NULL);
	g_return_val_if_fail (G_IS_DBUS_CONNECTION (connection), NULL);
	g_return_val_if_fail (object_path != NULL, NULL);

	return g_initable_new (
		E_TYPE_DATA_CAL_VIEW, NULL, error,
		"backend", backend,
		"connection", connection,
		"object-path", object_path,
		"sexp", sexp,
		NULL);
}

static void
send_pending_adds (EDataCalView *view)
{
	if (view->priv->adds->len == 0)
		return;

	e_dbus_calendar_view_emit_objects_added (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->adds->data);
	reset_array (view->priv->adds);
}

static void
send_pending_changes (EDataCalView *view)
{
	if (view->priv->changes->len == 0)
		return;

	e_dbus_calendar_view_emit_objects_modified (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->changes->data);
	reset_array (view->priv->changes);
}

static void
send_pending_removes (EDataCalView *view)
{
	if (view->priv->removes->len == 0)
		return;

	/* send ECalComponentIds as <uid>[\n<rid>], as encoded in notify_remove() */
	e_dbus_calendar_view_emit_objects_removed (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->removes->data);
	reset_array (view->priv->removes);
}

static gboolean
pending_flush_timeout_cb (gpointer data)
{
	EDataCalView *view = data;

	g_mutex_lock (&view->priv->pending_mutex);

	view->priv->flush_id = 0;

	if (!g_source_is_destroyed (g_main_current_source ())) {
		send_pending_adds (view);
		send_pending_changes (view);
		send_pending_removes (view);
	}

	g_mutex_unlock (&view->priv->pending_mutex);

	return FALSE;
}

static void
ensure_pending_flush_timeout (EDataCalView *view)
{
	if (view->priv->flush_id > 0)
		return;

	if (e_data_cal_view_is_completed (view)) {
		view->priv->flush_id = e_named_timeout_add (
			10 /* ms */, pending_flush_timeout_cb, view);
	} else {
		view->priv->flush_id = e_named_timeout_add_seconds (
			THRESHOLD_SECONDS, pending_flush_timeout_cb, view);
	}
}

static void
notify_add_component (EDataCalView *view,
                      /* const */ ECalComponent *comp)
{
	ECalClientViewFlags flags;
	gchar *obj;

	obj = e_data_cal_view_get_component_string (view, comp);

	send_pending_changes (view);
	send_pending_removes (view);

	/* Do not send component add notifications during initial stage */
	flags = e_data_cal_view_get_flags (view);
	if (view->priv->complete || (flags & E_CAL_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL) != 0) {
		if (view->priv->adds->len == THRESHOLD_ITEMS)
			send_pending_adds (view);
		g_array_append_val (view->priv->adds, obj);

		ensure_pending_flush_timeout (view);
	}

	g_hash_table_insert (
		view->priv->ids,
		e_cal_component_get_id (comp),
		GUINT_TO_POINTER (1));
}

static void
notify_change (EDataCalView *view,
               gchar *obj)
{
	send_pending_adds (view);
	send_pending_removes (view);

	if (view->priv->changes->len == THRESHOLD_ITEMS)
		send_pending_changes (view);

	g_array_append_val (view->priv->changes, obj);

	ensure_pending_flush_timeout (view);
}

static void
notify_change_component (EDataCalView *view,
                         ECalComponent *comp)
{
	gchar *obj;

	obj = e_data_cal_view_get_component_string (view, comp);

	notify_change (view, obj);
}

static void
notify_remove (EDataCalView *view,
               ECalComponentId *id)
{
	gchar *ids;
	gsize ids_len, ids_offset;
	gchar *uid, *rid;
	gsize uid_len, rid_len;

	send_pending_adds (view);
	send_pending_changes (view);

	if (view->priv->removes->len == THRESHOLD_ITEMS)
		send_pending_removes (view);

	/* store ECalComponentId as <uid>[\n<rid>] (matches D-Bus API) */
	if (id->uid) {
		uid = e_util_utf8_make_valid (id->uid);
		uid_len = strlen (uid);
	} else {
		uid = NULL;
		uid_len = 0;
	}
	if (id->rid) {
		rid = e_util_utf8_make_valid (id->rid);
		rid_len = strlen (rid);
	} else {
		rid = NULL;
		rid_len = 0;
	}
	if (uid_len && !rid_len) {
		/* shortcut */
		ids = uid;
		uid = NULL;
	} else {
		/* concatenate */
		ids_len = uid_len + rid_len + (rid_len ? 2 : 1);
		ids = g_malloc (ids_len);
		if (uid_len)
			g_strlcpy (ids, uid, ids_len);
		if (rid_len) {
			ids_offset = uid_len + 1;
			g_strlcpy (ids + ids_offset, rid, ids_len - ids_offset);
		}
	}
	g_array_append_val (view->priv->removes, ids);
	g_free (uid);
	g_free (rid);

	g_hash_table_remove (view->priv->ids, id);

	ensure_pending_flush_timeout (view);
}

/**
 * e_data_cal_view_get_backend:
 * @view: an #EDataCalView
 *
 * Gets the backend that @view is querying.
 *
 * Returns: The associated #ECalBackend.
 *
 * Since: 3.8
 **/
ECalBackend *
e_data_cal_view_get_backend (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	return view->priv->backend;
}

/**
 * e_data_cal_view_get_connection:
 * @view: an #EDataCalView
 *
 * Returns the #GDBusConnection on which the CalendarView D-Bus
 * interface is exported.
 *
 * Returns: the #GDBusConnection
 *
 * Since: 3.8
 **/
GDBusConnection *
e_data_cal_view_get_connection (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	return view->priv->connection;
}

/**
 * e_data_cal_view_get_object_path:
 * @view: an #EDataCalView
 *
 * Return the object path at which the CalendarView D-Bus inteface is
 * exported.
 *
 * Returns: the object path
 *
 * Since: 3.8
 **/
const gchar *
e_data_cal_view_get_object_path (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	return view->priv->object_path;
}

/**
 * e_data_cal_view_get_sexp:
 * @view: an #EDataCalView
 *
 * Get the #ECalBackendSExp object used for the given view.
 *
 * Returns: The expression object used to search.
 *
 * Since: 3.8
 */
ECalBackendSExp *
e_data_cal_view_get_sexp (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	return view->priv->sexp;
}

/**
 * e_data_cal_view_object_matches:
 * @view: an #EDataCalView
 * @object: Object to match.
 *
 * Compares the given @object to the regular expression used for the
 * given view.
 *
 * Returns: TRUE if the object matches the expression, FALSE if not.
 */
gboolean
e_data_cal_view_object_matches (EDataCalView *view,
                                const gchar *object)
{
	ECalBackend *backend;
	ECalBackendSExp *sexp;

	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	sexp = e_data_cal_view_get_sexp (view);
	backend = e_data_cal_view_get_backend (view);

	return e_cal_backend_sexp_match_object (
		sexp, object, E_TIMEZONE_CACHE (backend));
}

/**
 * e_data_cal_view_component_matches:
 * @view: an #EDataCalView
 * @component: the #ECalComponent object to match.
 *
 * Compares the given @component to the regular expression used for the
 * given view.
 *
 * Returns: TRUE if the object matches the expression, FALSE if not.
 *
 * Since: 3.4
 */
gboolean
e_data_cal_view_component_matches (EDataCalView *view,
                                   ECalComponent *component)
{
	ECalBackend *backend;
	ECalBackendSExp *sexp;

	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (component), FALSE);

	sexp = e_data_cal_view_get_sexp (view);
	backend = e_data_cal_view_get_backend (view);

	return e_cal_backend_sexp_match_comp (
		sexp, component, E_TIMEZONE_CACHE (backend));
}

/**
 * e_data_cal_view_is_started:
 * @view: an #EDataCalView
 *
 * Checks whether the given view has already been started.
 *
 * Returns: TRUE if the view has already been started, FALSE otherwise.
 */
gboolean
e_data_cal_view_is_started (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), FALSE);

	return view->priv->started;
}

/**
 * e_data_cal_view_is_stopped:
 * @view: an #EDataCalView
 *
 * Checks whether the given view has been stopped.
 *
 * Returns: TRUE if the view has been stopped, FALSE otherwise.
 *
 * Since: 2.32
 */
gboolean
e_data_cal_view_is_stopped (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), FALSE);

	return view->priv->stopped;
}

/**
 * e_data_cal_view_is_completed:
 * @view: an #EDataCalView
 *
 * Checks whether the given view is already completed. Being completed means the initial
 * matching of objects have been finished, not that no more notifications about
 * changes will be sent. In fact, even after completed, notifications will still be sent
 * if there are changes in the objects matching the view search expression.
 *
 * Returns: TRUE if the view is completed, FALSE if still in progress.
 *
 * Since: 3.2
 */
gboolean
e_data_cal_view_is_completed (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), FALSE);

	return view->priv->complete;
}

/**
 * e_data_cal_view_get_fields_of_interest:
 * @view: an #EDataCalView
 *
 * Returns: Hash table of field names which the listener is interested in.
 * Backends can return fully populated objects, but the listener advertised
 * that it will use only these. Returns %NULL for all available fields.
 *
 * Note: The data pointer in the hash table has no special meaning, it's
 * only GINT_TO_POINTER(1) for easier checking. Also, field names are
 * compared case insensitively.
 *
 * Since: 3.2
 **/
/* const */ GHashTable *
e_data_cal_view_get_fields_of_interest (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	return view->priv->fields_of_interest;
}

/**
 * e_data_cal_view_get_flags:
 * @view: an #EDataCalView
 *
 * Gets the #ECalClientViewFlags that control the behaviour of @view.
 *
 * Returns: the flags for @view.
 *
 * Since: 3.6
 **/
ECalClientViewFlags
e_data_cal_view_get_flags (EDataCalView *view)
{
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), 0);

	return view->priv->flags;
}

static gboolean
filter_component (icalcomponent *icomponent,
                  GHashTable *fields_of_interest,
                  GString *string)
{
	gchar             *str;

	/* RFC 2445 explicitly says that the newline is *ALWAYS* a \r\n (CRLF)!!!! */
	const gchar        newline[] = "\r\n";

	icalcomponent_kind kind;
	const gchar       *kind_string;
	icalproperty      *prop;
	icalcomponent     *icomp;
	gboolean           fail = FALSE;

	g_return_val_if_fail (icomponent != NULL, FALSE);

	/* Open iCalendar string */
	g_string_append (string, "BEGIN:");

	kind = icalcomponent_isa (icomponent);

	/* if (kind != ICAL_X_COMPONENT) { */
	/* 	kind_string  = icalcomponent_kind_to_string (kind); */
	/* } else { */
	/* 	kind_string = icomponent->x_name; */
	/* } */

	kind_string = icalcomponent_kind_to_string (kind);

	g_string_append (string, kind_string);
	g_string_append (string, newline);

	for (prop = icalcomponent_get_first_property (icomponent, ICAL_ANY_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (icomponent, ICAL_ANY_PROPERTY)) {
		const gchar *name;
		gboolean     is_field_of_interest;

		name = icalproperty_get_property_name (prop);

		if (!name) {
			g_warning ("NULL ical property name encountered while serializing component");
			fail = TRUE;
			break;
		}

		is_field_of_interest = GPOINTER_TO_INT (g_hash_table_lookup (fields_of_interest, name));

		/* Append any name that is mentioned in the fields-of-interest */
		if (is_field_of_interest) {
			str = icalproperty_as_ical_string_r (prop);
			g_string_append (string, str);
			g_free (str);
		}
	}

	for (icomp = icalcomponent_get_first_component (icomponent, ICAL_ANY_COMPONENT);
	     fail == FALSE && icomp;
	     icomp = icalcomponent_get_next_component (icomponent, ICAL_ANY_COMPONENT)) {

		if (!filter_component (icomp, fields_of_interest, string)) {
			fail = TRUE;
			break;
		}
	}

	g_string_append (string, "END:");
	g_string_append (string, icalcomponent_kind_to_string (kind));
	g_string_append (string, newline);

	return fail == FALSE;
}

/**
 * e_data_cal_view_get_component_string:
 * @view: an #EDataCalView
 * @component: The #ECalComponent to get the string for.
 *
 * This function is similar to e_cal_component_get_as_string() except
 * that it takes into account the fields-of-interest that @view is 
 * configured with and filters out any unneeded fields.
 *
 * Returns: (transfer full): A newly allocated string representation of
 * @component suitable for @view.
 *
 * Since: 3.4
 */
gchar *
e_data_cal_view_get_component_string (EDataCalView *view,
                                      ECalComponent *component)
{
	gchar *str = NULL, *res = NULL;

	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (component), NULL);

	if (view->priv->fields_of_interest) {
		GString *string = g_string_new ("");
		icalcomponent *icalcomp = e_cal_component_get_icalcomponent (component);

		if (filter_component (icalcomp, view->priv->fields_of_interest, string))
			str = g_string_free (string, FALSE);
		else
			g_string_free (string, TRUE);
	}

	if (!str)
		str = e_cal_component_get_as_string (component);

	if (e_util_ensure_gdbus_string (str, &res) == str)
		res = str;
	else
		g_free (str);

	return res;
}

/**
 * e_data_cal_view_notify_components_added:
 * @view: an #EDataCalView
 * @ecalcomponents: List of #ECalComponent-s that have been added.
 *
 * Notifies all view listeners of the addition of a list of components.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 */
void
e_data_cal_view_notify_components_added (EDataCalView *view,
                                         const GSList *ecalcomponents)
{
	const GSList *l;

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (ecalcomponents == NULL)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	for (l = ecalcomponents; l; l = l->next) {
		ECalComponent *comp = l->data;

		g_warn_if_fail (E_IS_CAL_COMPONENT (comp));

		notify_add_component (view, comp);
	}

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_cal_view_notify_components_added_1:
 * @view: an #EDataCalView
 * @component: The #ECalComponent that has been added.
 *
 * Notifies all the view listeners of the addition of a single object.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 */
void
e_data_cal_view_notify_components_added_1 (EDataCalView *view,
                                           ECalComponent *component)
{
	GSList l = {NULL,};

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));
	g_return_if_fail (E_IS_CAL_COMPONENT (component));

	l.data = (gpointer) component;
	e_data_cal_view_notify_components_added (view, &l);
}

/**
 * e_data_cal_view_notify_components_modified:
 * @view: an #EDataCalView
 * @ecalcomponents: List of modified #ECalComponent-s.
 *
 * Notifies all view listeners of the modification of a list of components.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 */
void
e_data_cal_view_notify_components_modified (EDataCalView *view,
                                            const GSList *ecalcomponents)
{
	const GSList *l;

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (ecalcomponents == NULL)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	for (l = ecalcomponents; l; l = l->next) {
		ECalComponent *comp = l->data;

		g_warn_if_fail (E_IS_CAL_COMPONENT (comp));

		notify_change_component (view, comp);
	}

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_cal_view_notify_components_modified_1:
 * @view: an #EDataCalView
 * @component: The modified #ECalComponent.
 *
 * Notifies all view listeners of the modification of @component.
 * 
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 */
void
e_data_cal_view_notify_components_modified_1 (EDataCalView *view,
                                              ECalComponent *component)
{
	GSList l = {NULL,};

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));
	g_return_if_fail (E_IS_CAL_COMPONENT (component));

	l.data = (gpointer) component;
	e_data_cal_view_notify_components_modified (view, &l);
}

/**
 * e_data_cal_view_notify_objects_removed:
 * @view: an #EDataCalView
 * @ids: List of IDs for the objects that have been removed.
 *
 * Notifies all view listener of the removal of a list of objects.
 */
void
e_data_cal_view_notify_objects_removed (EDataCalView *view,
                                        const GSList *ids)
{
	const GSList *l;

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (ids == NULL)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	for (l = ids; l; l = l->next) {
		ECalComponentId *id = l->data;
		if (g_hash_table_lookup (view->priv->ids, id))
		    notify_remove (view, id);
	}

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_cal_view_notify_objects_removed_1:
 * @view: an #EDataCalView
 * @id: ID of the removed object.
 *
 * Notifies all view listener of the removal of a single object.
 */
void
e_data_cal_view_notify_objects_removed_1 (EDataCalView *view,
                                          const ECalComponentId *id)
{
	GSList l = {NULL,};

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));
	g_return_if_fail (id != NULL);

	l.data = (gpointer) id;
	e_data_cal_view_notify_objects_removed (view, &l);
}

/**
 * e_data_cal_view_notify_progress:
 * @view: an #EDataCalView
 * @percent: Percentage completed.
 * @message: Progress message to send to listeners.
 *
 * Notifies all view listeners of progress messages.
 */
void
e_data_cal_view_notify_progress (EDataCalView *view,
                                 gint percent,
                                 const gchar *message)
{
	gchar *dbus_message = NULL;

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (!view->priv->started || view->priv->stopped)
		return;

	e_dbus_calendar_view_emit_progress (
		view->priv->dbus_object, percent,
		e_util_ensure_gdbus_string (message, &dbus_message));

	g_free (dbus_message);
}

/**
 * e_data_cal_view_notify_complete:
 * @view: an #EDataCalView
 * @error: View completion error, if any.
 *
 * Notifies all view listeners of the completion of the view, including a
 * status code.
 *
 * Since: 3.2
 **/
void
e_data_cal_view_notify_complete (EDataCalView *view,
                                 const GError *error)
{
	gchar *error_name, *error_message;

	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (!view->priv->started || view->priv->stopped)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	view->priv->complete = TRUE;

	send_pending_adds (view);
	send_pending_changes (view);
	send_pending_removes (view);

	if (error) {
		gchar *dbus_error_name = g_dbus_error_encode_gerror (error);

		error_name = e_util_utf8_make_valid (dbus_error_name ? dbus_error_name : "");
		error_message = e_util_utf8_make_valid (error->message);

		g_free (dbus_error_name);
	} else {
		error_name = g_strdup ("");
		error_message = g_strdup ("");
	}

	e_dbus_calendar_view_emit_complete (
		view->priv->dbus_object,
		error_name,
		error_message);

	g_free (error_name);
	g_free (error_message);

	g_mutex_unlock (&view->priv->pending_mutex);
}

