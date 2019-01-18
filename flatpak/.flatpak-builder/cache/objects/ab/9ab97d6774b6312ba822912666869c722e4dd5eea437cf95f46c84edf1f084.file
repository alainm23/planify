/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2006 OpenedHand Ltd
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
 * Authors: Ross Burton <ross@linux.intel.com>
 */

/**
 * SECTION: e-data-book-view
 * @include: libedata-book/libedata-book.h
 * @short_description: A server side object for issuing view notifications
 *
 * This class communicates with #EBookClientViews over the bus.
 *
 * Addressbook backends can automatically own a number of views requested
 * by the client, this API can be used by the backend to issue notifications
 * which will be delivered to the #EBookClientView
 **/

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-data-book-view.h"

#include "e-data-book.h"
#include "e-book-backend.h"

#include "e-dbus-address-book-view.h"

#define E_DATA_BOOK_VIEW_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DATA_BOOK_VIEW, EDataBookViewPrivate))

/* how many items can be hold in a cache, before propagated to UI */
#define THRESHOLD_ITEMS 32

/* how long to wait until notifications are propagated to UI; in seconds */
#define THRESHOLD_SECONDS 2

struct _EDataBookViewPrivate {
	GDBusConnection *connection;
	EDBusAddressBookView *dbus_object;
	gchar *object_path;

	EBookBackend *backend;

	EBookBackendSExp *sexp;
	EBookClientViewFlags flags;

	gboolean running;
	gboolean complete;
	GMutex pending_mutex;

	GArray *adds;
	GArray *changes;
	GArray *removes;

	GHashTable *ids;

	guint flush_id;

	/* which fields is listener interested in */
	GHashTable *fields_of_interest;
	gboolean send_uids_only;
};

enum {
	PROP_0,
	PROP_BACKEND,
	PROP_CONNECTION,
	PROP_OBJECT_PATH,
	PROP_SEXP
};

/* Forward Declarations */
static void	e_data_book_view_initable_init	(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EDataBookView,
	e_data_book_view,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_data_book_view_initable_init))

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

static void
send_pending_adds (EDataBookView *view)
{
	if (view->priv->adds->len == 0)
		return;

	e_dbus_address_book_view_emit_objects_added (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->adds->data);
	reset_array (view->priv->adds);
}

static void
send_pending_changes (EDataBookView *view)
{
	if (view->priv->changes->len == 0)
		return;

	e_dbus_address_book_view_emit_objects_modified (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->changes->data);
	reset_array (view->priv->changes);
}

static void
send_pending_removes (EDataBookView *view)
{
	if (view->priv->removes->len == 0)
		return;

	e_dbus_address_book_view_emit_objects_removed (
		view->priv->dbus_object,
		(const gchar * const *) view->priv->removes->data);
	reset_array (view->priv->removes);
}

static gboolean
pending_flush_timeout_cb (gpointer data)
{
	EDataBookView *view = data;

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
ensure_pending_flush_timeout (EDataBookView *view)
{
	if (view->priv->flush_id > 0)
		return;

	view->priv->flush_id = e_named_timeout_add_seconds (
		THRESHOLD_SECONDS, pending_flush_timeout_cb, view);
}

static gpointer
bookview_start_thread (gpointer data)
{
	EDataBookView *view = data;

	if (view->priv->running)
		e_book_backend_start_view (view->priv->backend, view);
	g_object_unref (view);

	return NULL;
}

static gboolean
impl_DataBookView_start (EDBusAddressBookView *object,
                         GDBusMethodInvocation *invocation,
                         EDataBookView *view)
{
	GThread *thread;

	view->priv->running = TRUE;
	view->priv->complete = FALSE;

	thread = g_thread_new (
		NULL, bookview_start_thread, g_object_ref (view));
	g_thread_unref (thread);

	e_dbus_address_book_view_complete_start (object, invocation);

	return TRUE;
}

static gpointer
bookview_stop_thread (gpointer data)
{
	EDataBookView *view = data;

	if (!view->priv->running)
		e_book_backend_stop_view (view->priv->backend, view);
	g_object_unref (view);

	return NULL;
}

static gboolean
impl_DataBookView_stop (EDBusAddressBookView *object,
                        GDBusMethodInvocation *invocation,
                        EDataBookView *view)
{
	GThread *thread;

	view->priv->running = FALSE;
	view->priv->complete = FALSE;

	thread = g_thread_new (
		NULL, bookview_stop_thread, g_object_ref (view));
	g_thread_unref (thread);

	e_dbus_address_book_view_complete_stop (object, invocation);

	return TRUE;
}

static gboolean
impl_DataBookView_setFlags (EDBusAddressBookView *object,
                            GDBusMethodInvocation *invocation,
                            EBookClientViewFlags flags,
                            EDataBookView *view)
{
	view->priv->flags = flags;

	e_dbus_address_book_view_complete_set_flags (object, invocation);

	return TRUE;
}

static gboolean
impl_DataBookView_dispose (EDBusAddressBookView *object,
                           GDBusMethodInvocation *invocation,
                           EDataBookView *view)
{
	e_dbus_address_book_view_complete_dispose (object, invocation);

	e_book_backend_stop_view (view->priv->backend, view);
	view->priv->running = FALSE;
	e_book_backend_remove_view (view->priv->backend, view);

	return TRUE;
}

static gboolean
impl_DataBookView_set_fields_of_interest (EDBusAddressBookView *object,
                                          GDBusMethodInvocation *invocation,
                                          const gchar * const *in_fields_of_interest,
                                          EDataBookView *view)
{
	gint ii;

	g_return_val_if_fail (in_fields_of_interest != NULL, TRUE);

	if (view->priv->fields_of_interest != NULL) {
		g_hash_table_destroy (view->priv->fields_of_interest);
		view->priv->fields_of_interest = NULL;
	}

	view->priv->send_uids_only = FALSE;

	for (ii = 0; in_fields_of_interest[ii]; ii++) {
		const gchar *field = in_fields_of_interest[ii];

		if (!*field)
			continue;

		if (strcmp (field, "x-evolution-uids-only") == 0) {
			view->priv->send_uids_only = TRUE;
			continue;
		}

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

	e_dbus_address_book_view_complete_set_fields_of_interest (object, invocation);

	return TRUE;
}

static void
data_book_view_set_backend (EDataBookView *view,
                            EBookBackend *backend)
{
	g_return_if_fail (E_IS_BOOK_BACKEND (backend));
	g_return_if_fail (view->priv->backend == NULL);

	view->priv->backend = g_object_ref (backend);
}

static void
data_book_view_set_connection (EDataBookView *view,
                               GDBusConnection *connection)
{
	g_return_if_fail (G_IS_DBUS_CONNECTION (connection));
	g_return_if_fail (view->priv->connection == NULL);

	view->priv->connection = g_object_ref (connection);
}

static void
data_book_view_set_object_path (EDataBookView *view,
                                const gchar *object_path)
{
	g_return_if_fail (object_path != NULL);
	g_return_if_fail (view->priv->object_path == NULL);

	view->priv->object_path = g_strdup (object_path);
}

static void
data_book_view_set_sexp (EDataBookView *view,
                         EBookBackendSExp *sexp)
{
	g_return_if_fail (E_IS_BOOK_BACKEND_SEXP (sexp));
	g_return_if_fail (view->priv->sexp == NULL);

	view->priv->sexp = g_object_ref (sexp);
}

static void
data_book_view_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			data_book_view_set_backend (
				E_DATA_BOOK_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_CONNECTION:
			data_book_view_set_connection (
				E_DATA_BOOK_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_OBJECT_PATH:
			data_book_view_set_object_path (
				E_DATA_BOOK_VIEW (object),
				g_value_get_string (value));
			return;

		case PROP_SEXP:
			data_book_view_set_sexp (
				E_DATA_BOOK_VIEW (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_book_view_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			g_value_set_object (
				value,
				e_data_book_view_get_backend (
				E_DATA_BOOK_VIEW (object)));
			return;

		case PROP_CONNECTION:
			g_value_set_object (
				value,
				e_data_book_view_get_connection (
				E_DATA_BOOK_VIEW (object)));
			return;

		case PROP_OBJECT_PATH:
			g_value_set_string (
				value,
				e_data_book_view_get_object_path (
				E_DATA_BOOK_VIEW (object)));
			return;

		case PROP_SEXP:
			g_value_set_object (
				value,
				e_data_book_view_get_sexp (
				E_DATA_BOOK_VIEW (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_book_view_dispose (GObject *object)
{
	EDataBookViewPrivate *priv;

	priv = E_DATA_BOOK_VIEW_GET_PRIVATE (object);

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
	G_OBJECT_CLASS (e_data_book_view_parent_class)->dispose (object);
}

static void
data_book_view_finalize (GObject *object)
{
	EDataBookViewPrivate *priv;

	priv = E_DATA_BOOK_VIEW_GET_PRIVATE (object);

	g_free (priv->object_path);

	reset_array (priv->adds);
	reset_array (priv->changes);
	reset_array (priv->removes);
	g_array_free (priv->adds, TRUE);
	g_array_free (priv->changes, TRUE);
	g_array_free (priv->removes, TRUE);

	if (priv->fields_of_interest)
		g_hash_table_destroy (priv->fields_of_interest);

	g_mutex_clear (&priv->pending_mutex);

	g_hash_table_destroy (priv->ids);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_data_book_view_parent_class)->finalize (object);
}

static gboolean
data_book_view_initable_init (GInitable *initable,
                              GCancellable *cancellable,
                              GError **error)
{
	EDataBookView *view;

	view = E_DATA_BOOK_VIEW (initable);

	return g_dbus_interface_skeleton_export (
		G_DBUS_INTERFACE_SKELETON (view->priv->dbus_object),
		view->priv->connection,
		view->priv->object_path,
		error);
}

static void
e_data_book_view_class_init (EDataBookViewClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EDataBookViewPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = data_book_view_set_property;
	object_class->get_property = data_book_view_get_property;
	object_class->dispose = data_book_view_dispose;
	object_class->finalize = data_book_view_finalize;

	g_object_class_install_property (
		object_class,
		PROP_BACKEND,
		g_param_spec_object (
			"backend",
			"Backend",
			"The backend being monitored",
			E_TYPE_BOOK_BACKEND,
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
			E_TYPE_BOOK_BACKEND_SEXP,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_data_book_view_initable_init (GInitableIface *iface)
{
	iface->init = data_book_view_initable_init;
}

static void
e_data_book_view_init (EDataBookView *view)
{
	view->priv = E_DATA_BOOK_VIEW_GET_PRIVATE (view);

	view->priv->flags = E_BOOK_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL;

	view->priv->dbus_object = e_dbus_address_book_view_skeleton_new ();
	g_signal_connect (
		view->priv->dbus_object, "handle-start",
		G_CALLBACK (impl_DataBookView_start), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-stop",
		G_CALLBACK (impl_DataBookView_stop), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-set-flags",
		G_CALLBACK (impl_DataBookView_setFlags), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-dispose",
		G_CALLBACK (impl_DataBookView_dispose), view);
	g_signal_connect (
		view->priv->dbus_object, "handle-set-fields-of-interest",
		G_CALLBACK (impl_DataBookView_set_fields_of_interest), view);

	view->priv->fields_of_interest = NULL;
	view->priv->running = FALSE;
	view->priv->complete = FALSE;
	g_mutex_init (&view->priv->pending_mutex);

	/* THRESHOLD_ITEMS * 2 because we store UID and vcard */
	view->priv->adds = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS * 2);
	view->priv->changes = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS * 2);
	view->priv->removes = g_array_sized_new (
		TRUE, TRUE, sizeof (gchar *), THRESHOLD_ITEMS);

	view->priv->ids = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) NULL);

	view->priv->flush_id = 0;
}

/**
 * e_data_book_view_new:
 * @backend: an #EBookBackend
 * @sexp: an #EBookBackendSExp
 * @connection: a #GDBusConnection
 * @object_path: an object path for the view
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EDataBookView and exports its D-Bus interface on
 * @connection at @object_path.  If an error occurs while exporting,
 * the function sets @error and returns %NULL.
 *
 * Returns: an #EDataBookView
 */
EDataBookView *
e_data_book_view_new (EBookBackend *backend,
                      EBookBackendSExp *sexp,
                      GDBusConnection *connection,
                      const gchar *object_path,
                      GError **error)
{
	g_return_val_if_fail (E_IS_BOOK_BACKEND (backend), NULL);
	g_return_val_if_fail (E_IS_BOOK_BACKEND_SEXP (sexp), NULL);
	g_return_val_if_fail (G_IS_DBUS_CONNECTION (connection), NULL);
	g_return_val_if_fail (object_path != NULL, NULL);

	return g_initable_new (
		E_TYPE_DATA_BOOK_VIEW, NULL, error,
		"backend", backend,
		"connection", connection,
		"object-path", object_path,
		"sexp", sexp, NULL);
}

/**
 * e_data_book_view_get_backend:
 * @view: an #EDataBookView
 *
 * Gets the backend that @view is querying.
 *
 * Returns: The associated #EBookBackend.
 **/
EBookBackend *
e_data_book_view_get_backend (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	return view->priv->backend;
}

/**
 * e_data_book_view_get_sexp:
 * @view: an #EDataBookView
 *
 * Gets the s-expression used for matching contacts to @view.
 *
 * Returns: The #EBookBackendSExp used.
 *
 * Since: 3.8
 **/
EBookBackendSExp *
e_data_book_view_get_sexp (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	return view->priv->sexp;
}

/**
 * e_data_book_view_get_connection:
 * @view: an #EDataBookView
 *
 * Returns the #GDBusConnection on which the AddressBookView D-Bus
 * interface is exported.
 *
 * Returns: the #GDBusConnection
 *
 * Since: 3.8
 **/
GDBusConnection *
e_data_book_view_get_connection (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	return view->priv->connection;
}

/**
 * e_data_book_view_get_object_path:
 * @view: an #EDataBookView
 *
 * Returns the object path at which the AddressBookView D-Bus interface
 * is exported.
 *
 * Returns: the object path
 *
 * Since: 3.8
 **/
const gchar *
e_data_book_view_get_object_path (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	return view->priv->object_path;
}

/**
 * e_data_book_view_get_flags:
 * @view: an #EDataBookView
 *
 * Gets the #EBookClientViewFlags that control the behaviour of @view.
 *
 * Returns: the flags for @view.
 *
 * Since: 3.4
 **/
EBookClientViewFlags
e_data_book_view_get_flags (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), 0);

	return view->priv->flags;
}

/*
 * Queue @vcard to be sent as a change notification.
 */
static void
notify_change (EDataBookView *view,
               const gchar *id,
               const gchar *vcard)
{
	gchar *utf8_vcard, *utf8_id;

	send_pending_adds (view);
	send_pending_removes (view);

	if (view->priv->changes->len == THRESHOLD_ITEMS * 2) {
		send_pending_changes (view);
	}

	if (view->priv->send_uids_only == FALSE) {
		utf8_vcard = e_util_utf8_make_valid (vcard);
		g_array_append_val (view->priv->changes, utf8_vcard);
	}

	utf8_id = e_util_utf8_make_valid (id);
	g_array_append_val (view->priv->changes, utf8_id);

	ensure_pending_flush_timeout (view);
}

/*
 * Queue @id to be sent as a change notification.
 */
static void
notify_remove (EDataBookView *view,
               const gchar *id)
{
	gchar *valid_id;

	send_pending_adds (view);
	send_pending_changes (view);

	if (view->priv->removes->len == THRESHOLD_ITEMS) {
		send_pending_removes (view);
	}

	valid_id = e_util_utf8_make_valid (id);
	g_array_append_val (view->priv->removes, valid_id);
	g_hash_table_remove (view->priv->ids, valid_id);

	ensure_pending_flush_timeout (view);
}

/*
 * Queue @id and @vcard to be sent as a change notification.
 */
static void
notify_add (EDataBookView *view,
            const gchar *id,
            const gchar *vcard)
{
	EBookClientViewFlags flags;
	gchar *utf8_vcard, *utf8_id;

	send_pending_changes (view);
	send_pending_removes (view);

	utf8_id = e_util_utf8_make_valid (id);

	/* Do not send contact add notifications during initial stage */
	flags = e_data_book_view_get_flags (view);
	if (view->priv->complete || (flags & E_BOOK_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL) != 0) {
		gchar *utf8_id_copy = g_strdup (utf8_id);

		if (view->priv->adds->len == THRESHOLD_ITEMS) {
			send_pending_adds (view);
		}

		if (view->priv->send_uids_only == FALSE) {
			utf8_vcard = e_util_utf8_make_valid (vcard);
			g_array_append_val (view->priv->adds, utf8_vcard);
		}

		g_array_append_val (view->priv->adds, utf8_id_copy);

		ensure_pending_flush_timeout (view);
	}

	g_hash_table_insert (view->priv->ids, utf8_id, GUINT_TO_POINTER (1));
}

static gboolean
id_is_in_view (EDataBookView *view,
               const gchar *id)
{
	gchar *valid_id;
	gboolean res;

	g_return_val_if_fail (view != NULL, FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	valid_id = e_util_utf8_make_valid (id);
	res = g_hash_table_lookup (view->priv->ids, valid_id) != NULL;
	g_free (valid_id);

	return res;
}

/**
 * e_data_book_view_notify_update:
 * @view: an #EDataBookView
 * @contact: an #EContact
 *
 * Notify listeners that @contact has changed. This can
 * trigger an add, change or removal event depending on
 * whether the change causes the contact to start matching,
 * no longer match, or stay matching the query specified
 * by @view.
 **/
void
e_data_book_view_notify_update (EDataBookView *view,
                                const EContact *contact)
{
	gboolean currently_in_view, want_in_view;
	const gchar *id;
	gchar *vcard;

	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));
	g_return_if_fail (E_IS_CONTACT (contact));

	if (!view->priv->running)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	id = e_contact_get_const ((EContact *) contact, E_CONTACT_UID);

	currently_in_view = id_is_in_view (view, id);
	want_in_view = e_book_backend_sexp_match_contact (
		view->priv->sexp, (EContact *) contact);

	if (want_in_view) {
		vcard = e_vcard_to_string (
			E_VCARD (contact),
			EVC_FORMAT_VCARD_30);

		if (currently_in_view)
			notify_change (view, id, vcard);
		else
			notify_add (view, id, vcard);

		g_free (vcard);
	} else {
		if (currently_in_view)
			notify_remove (view, id);
		/* else nothing; we're removing a card that wasn't there */
	}

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_book_view_notify_update_vcard:
 * @view: an #EDataBookView
 * @id: a unique id of the @vcard
 * @vcard: a plain vCard
 *
 * Notify listeners that @vcard has changed. This can
 * trigger an add, change or removal event depending on
 * whether the change causes the contact to start matching,
 * no longer match, or stay matching the query specified
 * by @view.  This method should be preferred over
 * e_data_book_view_notify_update() when the native
 * representation of a contact is a vCard.
 **/
void
e_data_book_view_notify_update_vcard (EDataBookView *view,
                                      const gchar *id,
                                      const gchar *vcard)
{
	gboolean currently_in_view, want_in_view;
	EContact *contact;

	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));
	g_return_if_fail (id != NULL);
	g_return_if_fail (vcard != NULL);

	if (!view->priv->running)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	contact = e_contact_new_from_vcard_with_uid (vcard, id);
	currently_in_view = id_is_in_view (view, id);
	want_in_view = e_book_backend_sexp_match_contact (
		view->priv->sexp, contact);

	if (want_in_view) {
		if (currently_in_view)
			notify_change (view, id, vcard);
		else
			notify_add (view, id, vcard);
	} else {
		if (currently_in_view)
			notify_remove (view, id);
	}

	/* Do this last so that id is still valid when notify_ is called */
	g_object_unref (contact);

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_book_view_notify_update_prefiltered_vcard:
 * @view: an #EDataBookView
 * @id: the UID of this contact
 * @vcard: a plain vCard
 *
 * Notify listeners that @vcard has changed. This can
 * trigger an add, change or removal event depending on
 * whether the change causes the contact to start matching,
 * no longer match, or stay matching the query specified
 * by @view.  This method should be preferred over
 * e_data_book_view_notify_update() when the native
 * representation of a contact is a vCard.
 *
 * The important difference between this method and
 * e_data_book_view_notify_update() and
 * e_data_book_view_notify_update_vcard() is
 * that it doesn't match the contact against the book view query to see if it
 * should be included, it assumes that this has been done and the contact is
 * known to exist in the view.
 **/
void
e_data_book_view_notify_update_prefiltered_vcard (EDataBookView *view,
                                                  const gchar *id,
                                                  const gchar *vcard)
{
	gboolean currently_in_view;

	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));
	g_return_if_fail (id != NULL);
	g_return_if_fail (vcard != NULL);

	if (!view->priv->running)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	currently_in_view = id_is_in_view (view, id);

	if (currently_in_view)
		notify_change (view, id, vcard);
	else
		notify_add (view, id, vcard);

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_book_view_notify_remove:
 * @view: an #EDataBookView
 * @id: a unique contact ID
 *
 * Notify listeners that a contact specified by @id
 * was removed from @view.
 **/
void
e_data_book_view_notify_remove (EDataBookView *view,
                                const gchar *id)
{
	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));
	g_return_if_fail (id != NULL);

	if (!view->priv->running)
		return;

	g_mutex_lock (&view->priv->pending_mutex);

	if (id_is_in_view (view, id))
		notify_remove (view, id);

	g_mutex_unlock (&view->priv->pending_mutex);
}

/**
 * e_data_book_view_notify_complete:
 * @view: an #EDataBookView
 * @error: the error of the query, if any
 *
 * Notifies listeners that all pending updates on @view
 * have been sent. The listener's information should now be
 * in sync with the backend's.
 **/
void
e_data_book_view_notify_complete (EDataBookView *view,
                                  const GError *error)
{
	gchar *error_name, *error_message;

	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));

	if (!view->priv->running)
		return;

	/* View is complete */
	view->priv->complete = TRUE;

	g_mutex_lock (&view->priv->pending_mutex);

	send_pending_adds (view);
	send_pending_changes (view);
	send_pending_removes (view);

	g_mutex_unlock (&view->priv->pending_mutex);

	if (error) {
		gchar *dbus_error_name = g_dbus_error_encode_gerror (error);

		error_name = e_util_utf8_make_valid (dbus_error_name ? dbus_error_name : "");
		error_message = e_util_utf8_make_valid (error->message);

		g_free (dbus_error_name);
	} else {
		error_name = g_strdup ("");
		error_message = g_strdup ("");
	}

	e_dbus_address_book_view_emit_complete (
		view->priv->dbus_object,
		error_name,
		error_message);

	g_free (error_name);
	g_free (error_message);
}

/**
 * e_data_book_view_notify_progress:
 * @view: an #EDataBookView
 * @percent: percent done; use -1 when not available
 * @message: a text message
 *
 * Provides listeners with a human-readable text describing the
 * current backend operation. This can be used for progress
 * reporting.
 *
 * Since: 3.2
 **/
void
e_data_book_view_notify_progress (EDataBookView *view,
                                  guint percent,
                                  const gchar *message)
{
	gchar *dbus_message = NULL;

	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));

	if (!view->priv->running)
		return;

	e_dbus_address_book_view_emit_progress (
		view->priv->dbus_object, percent,
		e_util_ensure_gdbus_string (message, &dbus_message));

	g_free (dbus_message);
}

/**
 * e_data_book_view_get_fields_of_interest:
 * @view: an #EDataBookView
 *
 * Returns: Hash table of field names which the listener is interested in.
 * Backends can return fully populated objects, but the listener advertised
 * that it will use only these. Returns %NULL for all available fields.
 *
 * Note: The data pointer in the hash table has no special meaning, it's
 * only GINT_TO_POINTER(1) for easier checking. Also, field names are
 * compared case insensitively.
 **/
GHashTable *
e_data_book_view_get_fields_of_interest (EDataBookView *view)
{
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	return view->priv->fields_of_interest;
}

