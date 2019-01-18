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
 * SECTION: e-book-client-view
 * @include: libebook/libebook.h
 * @short_description: Recieving change notifications on addressbooks 
 *
 * This class provides functionality for watching for changes on a
 * given addressbook opened with an #EBookClient. Use e_book_client_get_view()
 * to create an #EBookClientView.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libedataserver/libedataserver.h>
#include <libedata-book/libedata-book.h>

#include "e-book-client.h"
#include "e-book-client-view.h"
#include "e-dbus-address-book-view.h"

#define E_BOOK_CLIENT_VIEW_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_CLIENT_VIEW, EBookClientViewPrivate))

typedef struct _SignalClosure SignalClosure;

struct _EBookClientViewPrivate {
	EBookClient *client;
	EDBusAddressBookView *dbus_proxy;
	GDBusConnection *connection;
	gchar *object_path;
	guint running : 1;
	guint complete : 1;

	GMainContext *main_context;
	GMutex main_context_lock;

	EBookBackend *direct_backend;

	gulong objects_added_handler_id;
	gulong objects_modified_handler_id;
	gulong objects_removed_handler_id;
	gulong progress_handler_id;
	gulong complete_handler_id;
};

struct _SignalClosure {
	GWeakRef client_view;
	GSList *object_list;
	GSList *string_list;
	gchar *message;
	guint percent;
	GError *error;
};

enum {
	PROP_0,
	PROP_CLIENT,
	PROP_CONNECTION,
	PROP_DIRECT_BACKEND,
	PROP_OBJECT_PATH
};

enum {
	OBJECTS_ADDED,
	OBJECTS_MODIFIED,
	OBJECTS_REMOVED,
	PROGRESS,
	COMPLETE,
	LAST_SIGNAL
};

/* Forward Declarations */
static void	e_book_client_view_initable_init
						(GInitableIface *iface);

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (
	EBookClientView,
	e_book_client_view,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_book_client_view_initable_init))

typedef struct {
	EBookClientView *client_view;
	guint signum;
} NotificationData;

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->client_view);

	g_slist_free_full (
		signal_closure->object_list,
		(GDestroyNotify) g_object_unref);

	g_slist_free_full (
		signal_closure->string_list,
		(GDestroyNotify) g_free);

	g_free (signal_closure->message);

	if (signal_closure->error != NULL)
		g_error_free (signal_closure->error);

	g_slice_free (SignalClosure, signal_closure);
}

static GMainContext *
book_client_view_ref_main_context (EBookClientView *client_view)
{
	GMainContext *main_context;

	/* Intentionally not checking for NULL so we get a console
	 * warning if we try to reference a NULL main context, but
	 * that should never happen. */

	g_mutex_lock (&client_view->priv->main_context_lock);

	main_context = g_main_context_ref (client_view->priv->main_context);

	g_mutex_unlock (&client_view->priv->main_context_lock);

	return main_context;
}

static void
book_client_view_set_main_context (EBookClientView *client_view,
                                   GMainContext *main_context)
{
	g_mutex_lock (&client_view->priv->main_context_lock);

	if (client_view->priv->main_context != NULL)
		g_main_context_unref (client_view->priv->main_context);

	client_view->priv->main_context = g_main_context_ref (main_context);

	g_mutex_unlock (&client_view->priv->main_context_lock);
}

static gboolean
book_client_view_emit_objects_added_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EBookClientView *client_view;

	client_view = g_weak_ref_get (&signal_closure->client_view);

	if (client_view != NULL) {
		g_signal_emit (
			client_view,
			signals[OBJECTS_ADDED], 0,
			signal_closure->object_list);
		g_object_unref (client_view);
	}

	return FALSE;
}

static gboolean
book_client_view_emit_objects_modified_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EBookClientView *client_view;

	client_view = g_weak_ref_get (&signal_closure->client_view);

	if (client_view != NULL) {
		g_signal_emit (
			client_view,
			signals[OBJECTS_MODIFIED], 0,
			signal_closure->object_list);
		g_object_unref (client_view);
	}

	return FALSE;
}

static gboolean
book_client_view_emit_objects_removed_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EBookClientView *client_view;

	client_view = g_weak_ref_get (&signal_closure->client_view);

	if (client_view != NULL) {
		g_signal_emit (
			client_view,
			signals[OBJECTS_REMOVED], 0,
			signal_closure->string_list);
		g_object_unref (client_view);
	}

	return FALSE;
}

static gboolean
book_client_view_emit_progress_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EBookClientView *client_view;

	client_view = g_weak_ref_get (&signal_closure->client_view);

	if (client_view != NULL) {
		g_signal_emit (
			client_view,
			signals[PROGRESS], 0,
			signal_closure->percent,
			signal_closure->message);
		g_object_unref (client_view);
	}

	return FALSE;
}

static gboolean
book_client_view_emit_complete_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EBookClientView *client_view;

	client_view = g_weak_ref_get (&signal_closure->client_view);

	if (client_view != NULL) {
		g_signal_emit (
			client_view,
			signals[COMPLETE], 0,
			signal_closure->error);
		g_object_unref (client_view);
	}

	return FALSE;
}

static void
book_client_view_emit_objects_added (EBookClientView *client_view,
                                     GSList *object_list)
{
	GSource *idle_source;
	GMainContext *main_context;
	SignalClosure *signal_closure;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->client_view, client_view);
	signal_closure->object_list = object_list;  /* takes ownership */

	main_context = book_client_view_ref_main_context (client_view);

	idle_source = g_idle_source_new ();
	g_source_set_callback (
		idle_source,
		book_client_view_emit_objects_added_idle_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static void
book_client_view_emit_objects_modified (EBookClientView *client_view,
                                        GSList *object_list)
{
	GSource *idle_source;
	GMainContext *main_context;
	SignalClosure *signal_closure;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->client_view, client_view);
	signal_closure->object_list = object_list;  /* takes ownership */

	main_context = book_client_view_ref_main_context (client_view);

	idle_source = g_idle_source_new ();
	g_source_set_callback (
		idle_source,
		book_client_view_emit_objects_modified_idle_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static gchar *
direct_contacts_query (const gchar * const *uids)
{
	EBookQuery *query, **qs;
	gchar *sexp;
	gint i, len;

	len = g_strv_length ((gchar **) uids);
	qs = g_new0 (EBookQuery *, len);

	for (i = 0; uids[i] != NULL; i++) {
		const gchar *uid = uids[i];

		qs[i] = e_book_query_field_test (E_CONTACT_UID, E_BOOK_QUERY_IS, uid);
	}

	query = e_book_query_or (len, qs, TRUE);
	sexp = e_book_query_to_string (query);
	e_book_query_unref (query);

	return sexp;
}

static void
direct_contacts_ready (GObject *source_object,
                       GAsyncResult *result,
                       gpointer user_data)
{
	NotificationData *data = (NotificationData *) user_data;
	GQueue queue = G_QUEUE_INIT;
	GSList *list = NULL;
	GError *local_error = NULL;

	e_book_backend_get_contact_list_finish (
		E_BOOK_BACKEND (source_object),
		result, &queue, &local_error);

	while (!g_queue_is_empty (&queue))
		list = g_slist_prepend (list, g_queue_pop_head (&queue));

	list = g_slist_reverse (list);

	if (local_error != NULL) {
		g_warn_if_fail (list == NULL);
		g_warning (
			"Error fetching contacts directly: %s\n",
			local_error->message);
		g_error_free (local_error);

	} else if (data->signum == OBJECTS_ADDED) {
		/* Takes ownership of the linked list. */
		book_client_view_emit_objects_added (
			data->client_view, list);

	} else if (data->signum == OBJECTS_MODIFIED) {
		/* Takes ownership of the linked list. */
		book_client_view_emit_objects_modified (
			data->client_view, list);

	} else {
		g_slist_free_full (list, (GDestroyNotify) g_object_unref);
	}

	g_object_unref (data->client_view);
	g_slice_free (NotificationData, data);
}

static void
direct_contacts_fetch (EBookClientView *client_view,
                       const gchar * const *uids,
                       guint signum)
{
	EBookBackend *backend;
	NotificationData *data;
	gchar *sexp = direct_contacts_query (uids);

	backend = client_view->priv->direct_backend;

	/* Until the view has completely loaded, we need to make
	 * sync calls to the backend
	 */
	if (!client_view->priv->complete) {
		GQueue queue = G_QUEUE_INIT;
		GSList *list = NULL;
		GError *local_error = NULL;

		e_book_backend_get_contact_list_sync (
			backend, sexp, &queue, NULL, &local_error);

		while (!g_queue_is_empty (&queue)) {
			list = g_slist_prepend (
				list, g_queue_pop_head (&queue));
		}

		list = g_slist_reverse (list);

		if (local_error != NULL) {
			g_warn_if_fail (list == NULL);
			g_warning (
				"Error fetching contacts directly: %s\n",
				local_error->message);
			g_error_free (local_error);

		} else if (signum == OBJECTS_ADDED) {
			/* Takes ownership of the linked list. */
			book_client_view_emit_objects_added (
				client_view, list);

		} else if (signum == OBJECTS_MODIFIED) {
			/* Takes ownership of the linked list. */
			book_client_view_emit_objects_modified (
				client_view, list);

		} else {
			g_slist_free_full (
				list, (GDestroyNotify) g_object_unref);
		}

	} else {
		/* Make async calls, avoid blocking the thread owning the view
		 * as much as possible
		 */
		data = g_slice_new (NotificationData);
		data->client_view = g_object_ref (client_view);
		data->signum = signum;

		e_book_backend_get_contact_list (
			backend, sexp, NULL, direct_contacts_ready, data);
	}

	g_free (sexp);
}

static void
book_client_view_objects_added_cb (EDBusAddressBookView *object,
                                   const gchar * const *vcards,
                                   GWeakRef *client_view_weak_ref)
{
	EBookClientView *client_view;

	client_view = g_weak_ref_get (client_view_weak_ref);

	if (client_view != NULL) {
		GSList *list = NULL;
		gint ii;

		if (!client_view->priv->running) {
			g_object_unref (client_view);
			return;
		}

		/* array contains UIDs only */
		if (client_view->priv->direct_backend != NULL) {
			direct_contacts_fetch (
				client_view, vcards, OBJECTS_ADDED);
			g_object_unref (client_view);
			return;
		}

		/* array contains both UID and vcard */
		for (ii = 0; vcards[ii] != NULL && vcards[ii + 1] != NULL; ii += 2) {
			EContact *contact;
			const gchar *vcard = vcards[ii];
			const gchar *uid = vcards[ii + 1];

			contact = e_contact_new_from_vcard_with_uid (vcard, uid);
			list = g_slist_prepend (list, contact);
		}

		list = g_slist_reverse (list);

		/* Takes ownership of the linked list. */
		book_client_view_emit_objects_added (client_view, list);

		g_object_unref (client_view);
	}
}

static void
book_client_view_objects_modified_cb (EDBusAddressBookView *object,
                                      const gchar * const *vcards,
                                      GWeakRef *client_view_weak_ref)
{
	EBookClientView *client_view;

	client_view = g_weak_ref_get (client_view_weak_ref);

	if (client_view != NULL) {
		GSList *list = NULL;
		gint ii;

		if (!client_view->priv->running) {
			g_object_unref (client_view);
			return;
		}

		/* array contains UIDs only */
		if (client_view->priv->direct_backend != NULL) {
			direct_contacts_fetch (
				client_view, vcards, OBJECTS_MODIFIED);
			g_object_unref (client_view);
			return;
		}

		/* array contains both UID and vcard */
		for (ii = 0; vcards[ii] != NULL && vcards[ii + 1] != NULL; ii += 2) {
			EContact *contact;
			const gchar *vcard = vcards[ii];
			const gchar *uid = vcards[ii + 1];

			contact = e_contact_new_from_vcard_with_uid (vcard, uid);
			list = g_slist_prepend (list, contact);
		}

		list = g_slist_reverse (list);

		/* Takes ownership of the linked list. */
		book_client_view_emit_objects_modified (client_view, list);

		g_object_unref (client_view);
	}
}

static void
book_client_view_objects_removed_cb (EDBusAddressBookView *object,
                                     const gchar * const *uids,
                                     GWeakRef *client_view_weak_ref)
{
	EBookClientView *client_view;

	client_view = g_weak_ref_get (client_view_weak_ref);

	if (client_view != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;
		GSList *list = NULL;
		gint ii;

		if (!client_view->priv->running) {
			g_object_unref (client_view);
			return;
		}

		for (ii = 0; uids[ii] != NULL; ii++)
			list = g_slist_prepend (list, g_strdup (uids[ii]));

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client_view, client_view);
		signal_closure->string_list = g_slist_reverse (list);

		main_context = book_client_view_ref_main_context (client_view);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			book_client_view_emit_objects_removed_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client_view);
	}
}

static void
book_client_view_progress_cb (EDBusAddressBookView *object,
                              guint percent,
                              const gchar *message,
                              GWeakRef *client_view_weak_ref)
{
	EBookClientView *client_view;

	client_view = g_weak_ref_get (client_view_weak_ref);

	if (client_view != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		if (!client_view->priv->running) {
			g_object_unref (client_view);
			return;
		}

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client_view, client_view);
		signal_closure->message = g_strdup (message);
		signal_closure->percent = percent;

		main_context = book_client_view_ref_main_context (client_view);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			book_client_view_emit_progress_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client_view);
	}
}

static void
book_client_view_complete_cb (EDBusAddressBookView *object,
			      const gchar *arg_error_name,
			      const gchar *arg_error_message,
                              GWeakRef *client_view_weak_ref)
{
	EBookClientView *client_view;

	client_view = g_weak_ref_get (client_view_weak_ref);

	if (client_view != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		if (!client_view->priv->running) {
			g_object_unref (client_view);
			return;
		}

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client_view, client_view);
		if (arg_error_name && *arg_error_name && arg_error_message)
			signal_closure->error = g_dbus_error_new_for_dbus_error (arg_error_name, arg_error_message);
		else
			signal_closure->error = NULL;

		if (signal_closure->error)
			g_dbus_error_strip_remote_error (signal_closure->error);

		main_context = book_client_view_ref_main_context (client_view);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			book_client_view_emit_complete_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		client_view->priv->complete = TRUE;

		g_object_unref (client_view);
	}
}

static void
book_client_view_set_client (EBookClientView *client_view,
                             EBookClient *client)
{
	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (client_view->priv->client == NULL);

	client_view->priv->client = g_object_ref (client);
}

static void
book_client_view_set_connection (EBookClientView *client_view,
                                 GDBusConnection *connection)
{
	g_return_if_fail (G_IS_DBUS_CONNECTION (connection));
	g_return_if_fail (client_view->priv->connection == NULL);

	client_view->priv->connection = g_object_ref (connection);
}

static void
book_client_view_set_direct_backend (EBookClientView *client_view,
                                     EBookBackend *backend)
{
	if (backend == NULL)
		return;

	g_return_if_fail (E_IS_BOOK_BACKEND (backend));
	g_return_if_fail (client_view->priv->direct_backend == NULL);

	client_view->priv->direct_backend = g_object_ref (backend);
}

static void
book_client_view_set_object_path (EBookClientView *client_view,
                                  const gchar *object_path)
{
	g_return_if_fail (object_path != NULL);
	g_return_if_fail (client_view->priv->object_path == NULL);

	client_view->priv->object_path = g_strdup (object_path);
}

static void
book_client_view_set_property (GObject *object,
                               guint property_id,
                               const GValue *value,
                               GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CLIENT:
			book_client_view_set_client (
				E_BOOK_CLIENT_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_CONNECTION:
			book_client_view_set_connection (
				E_BOOK_CLIENT_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_DIRECT_BACKEND:
			book_client_view_set_direct_backend (
				E_BOOK_CLIENT_VIEW (object),
				g_value_get_object (value));
			return;

		case PROP_OBJECT_PATH:
			book_client_view_set_object_path (
				E_BOOK_CLIENT_VIEW (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
book_client_view_get_property (GObject *object,
                               guint property_id,
                               GValue *value,
                               GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CLIENT:
			g_value_take_object (
				value,
				e_book_client_view_ref_client (
				E_BOOK_CLIENT_VIEW (object)));
			return;

		case PROP_CONNECTION:
			g_value_set_object (
				value,
				e_book_client_view_get_connection (
				E_BOOK_CLIENT_VIEW (object)));
			return;

		case PROP_OBJECT_PATH:
			g_value_set_string (
				value,
				e_book_client_view_get_object_path (
				E_BOOK_CLIENT_VIEW (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
book_client_view_dispose (GObject *object)
{
	EBookClientViewPrivate *priv;

	priv = E_BOOK_CLIENT_VIEW_GET_PRIVATE (object);

	g_clear_object (&priv->client);

	if (priv->connection != NULL) {
		g_object_unref (priv->connection);
		priv->connection = NULL;
	}

	if (priv->main_context != NULL) {
		g_main_context_unref (priv->main_context);
		priv->main_context = NULL;
	}

	if (priv->direct_backend != NULL) {
		g_object_unref (priv->direct_backend);
		priv->direct_backend = NULL;
	}

	if (priv->dbus_proxy != NULL) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->objects_added_handler_id);
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->objects_modified_handler_id);
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->objects_removed_handler_id);
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->progress_handler_id);
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->complete_handler_id);

		/* Call D-Bus dispose() asynchronously so we don't block this dispose().
		 * Also omit a callback function, so the GDBusMessage
		 * uses G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED.
		 */
		e_dbus_address_book_view_call_dispose (priv->dbus_proxy, NULL, NULL, NULL);
		g_object_unref (priv->dbus_proxy);
		priv->dbus_proxy = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_book_client_view_parent_class)->dispose (object);
}

static void
book_client_view_finalize (GObject *object)
{
	EBookClientViewPrivate *priv;

	priv = E_BOOK_CLIENT_VIEW_GET_PRIVATE (object);

	g_free (priv->object_path);

	g_mutex_clear (&priv->main_context_lock);
	g_clear_object (&priv->client);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_client_view_parent_class)->finalize (object);
}

static gboolean
book_client_view_initable_init (GInitable *initable,
                                GCancellable *cancellable,
                                GError **error)
{
	EBookClient *book_client;
	EBookClientViewPrivate *priv;
	EDBusAddressBookView *dbus_bookview;
	gulong handler_id;
	gchar *bus_name;

	priv = E_BOOK_CLIENT_VIEW_GET_PRIVATE (initable);

	book_client = priv->client ? g_object_ref (priv->client) : NULL;
	if (book_client == NULL) {
		g_set_error (
			error, E_CLIENT_ERROR,
			E_CLIENT_ERROR_OTHER_ERROR,
			_("Client disappeared"));

		return FALSE;
	}

	bus_name = e_client_dup_bus_name (E_CLIENT (book_client));
	g_object_unref (book_client);

	dbus_bookview = e_dbus_address_book_view_proxy_new_sync (
		priv->connection,
		G_DBUS_PROXY_FLAGS_NONE,
		bus_name,
		priv->object_path,
		cancellable, error);

	g_free (bus_name);

	if (dbus_bookview == NULL)
		return FALSE;

	priv->dbus_proxy = dbus_bookview;

	handler_id = g_signal_connect_data (
		priv->dbus_proxy, "objects-added",
		G_CALLBACK (book_client_view_objects_added_cb),
		e_weak_ref_new (initable),
		(GClosureNotify) e_weak_ref_free, 0);
	priv->objects_added_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		priv->dbus_proxy, "objects-modified",
		G_CALLBACK (book_client_view_objects_modified_cb),
		e_weak_ref_new (initable),
		(GClosureNotify) e_weak_ref_free, 0);
	priv->objects_modified_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		priv->dbus_proxy, "objects-removed",
		G_CALLBACK (book_client_view_objects_removed_cb),
		e_weak_ref_new (initable),
		(GClosureNotify) e_weak_ref_free, 0);
	priv->objects_removed_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		priv->dbus_proxy, "progress",
		G_CALLBACK (book_client_view_progress_cb),
		e_weak_ref_new (initable),
		(GClosureNotify) e_weak_ref_free, 0);
	priv->progress_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		priv->dbus_proxy, "complete",
		G_CALLBACK (book_client_view_complete_cb),
		e_weak_ref_new (initable),
		(GClosureNotify) e_weak_ref_free, 0);
	priv->complete_handler_id = handler_id;

	/* When in direct read access mode, we add a special field
	 * to fields-of-interest indicating we only want uids sent. */
	if (priv->direct_backend != NULL)
		e_book_client_view_set_fields_of_interest (
			E_BOOK_CLIENT_VIEW (initable), NULL, NULL);

	return TRUE;
}

static void
e_book_client_view_class_init (EBookClientViewClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBookClientViewPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = book_client_view_set_property;
	object_class->get_property = book_client_view_get_property;
	object_class->dispose = book_client_view_dispose;
	object_class->finalize = book_client_view_finalize;

	g_object_class_install_property (
		object_class,
		PROP_CLIENT,
		g_param_spec_object (
			"client",
			"Client",
			"The EBookClient for the view",
			E_TYPE_BOOK_CLIENT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CONNECTION,
		g_param_spec_object (
			"connection",
			"Connection",
			"The GDBusConnection used "
			"to create the D-Bus proxy",
			G_TYPE_DBUS_CONNECTION,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_DIRECT_BACKEND,
		g_param_spec_object (
			"direct-backend",
			"Direct Backend",
			"The EBookBackend to fetch contact "
			"data from, if direct read access "
			"is enabled",
			E_TYPE_BOOK_BACKEND,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_OBJECT_PATH,
		g_param_spec_string (
			"object-path",
			"Object Path",
			"The object path used "
			"to create the D-Bus proxy",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	signals[OBJECTS_ADDED] = g_signal_new (
		"objects-added",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientViewClass, objects_added),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	signals[OBJECTS_MODIFIED] = g_signal_new (
		"objects-modified",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientViewClass, objects_modified),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	signals[OBJECTS_REMOVED] = g_signal_new (
		"objects-removed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientViewClass, objects_removed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	signals[PROGRESS] = g_signal_new (
		"progress",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientViewClass, progress),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_UINT,
		G_TYPE_STRING);

	signals[COMPLETE] = g_signal_new (
		"complete",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientViewClass, complete),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_ERROR);
}

static void
e_book_client_view_initable_init (GInitableIface *iface)
{
	iface->init = book_client_view_initable_init;
}

static void
e_book_client_view_init (EBookClientView *client_view)
{
	client_view->priv = E_BOOK_CLIENT_VIEW_GET_PRIVATE (client_view);

	g_mutex_init (&client_view->priv->main_context_lock);
	client_view->priv->client = NULL;
}

/**
 * e_book_client_view_ref_client:
 * @client_view: an #EBookClientView
 *
 * Returns the #EBookClientView:client associated with @client_view.
 *
 * The returned #EBookClient is referenced for thread-safety.  Unreference
 * the #EBookClient with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): an #EBookClient
 *
 * Since: 3.10
 **/
EBookClient *
e_book_client_view_ref_client (EBookClientView *client_view)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view), NULL);

	if (!client_view->priv->client)
		return NULL;

	return g_object_ref (client_view->priv->client);
}

/**
 * e_book_client_view_get_client:
 * @client_view: an #EBookClientView
 *
 * Returns the #EBookClientView:client associated with @client_view.
 *
 * Returns: (transfer none): an #EBookClient
 *
 * Deprecated: 3.10: Use e_book_client_view_ref_client() instead.
 **/
EBookClient *
e_book_client_view_get_client (EBookClientView *client_view)
{
	EBookClient *client;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view), NULL);

	client = e_book_client_view_ref_client (client_view);

	/* XXX Drop the EBookClient reference for backward-compatibility.
	 *     This is risky.  Without a reference, the EBookClient could
	 *     be finalized while the caller is still using it. */
	if (client != NULL)
		g_object_unref (client);

	return client;
}

/**
 * e_book_client_view_get_connection:
 * @client_view: an #EBookClientView
 *
 * Returns the #GDBusConnection used to create the D-Bus proxy.
 *
 * Returns: (transfer none): the #GDBusConnection
 *
 * Since: 3.8
 **/
GDBusConnection *
e_book_client_view_get_connection (EBookClientView *client_view)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view), NULL);

	return client_view->priv->connection;
}

/**
 * e_book_client_view_get_object_path:
 * @client_view: an #EBookClientView
 *
 * Returns the object path used to create the D-Bus proxy.
 *
 * Returns: the object path
 *
 * Since: 3.8
 **/
const gchar *
e_book_client_view_get_object_path (EBookClientView *client_view)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view), NULL);

	return client_view->priv->object_path;
}

/**
 * e_book_client_view_start:
 * @client_view: an #EBookClientView
 * @error: return location for a #GError, or %NULL
 *
 * Tells @client_view to start processing events.
 */
void
e_book_client_view_start (EBookClientView *client_view,
                          GError **error)
{
	GMainContext *main_context;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view));

	/* Emit signals from the current thread-default main context. */
	main_context = g_main_context_ref_thread_default ();
	book_client_view_set_main_context (client_view, main_context);
	g_main_context_unref (main_context);

	client_view->priv->running = TRUE;

	e_dbus_address_book_view_call_start_sync (
		client_view->priv->dbus_proxy, NULL, &local_error);

	if (local_error != NULL) {
		client_view->priv->running = FALSE;
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
	}
}

/**
 * e_book_client_view_stop:
 * @client_view: an #EBookClientView
 * @error: return location for a #GError, or %NULL
 *
 * Tells @client_view to stop processing events.
 **/
void
e_book_client_view_stop (EBookClientView *client_view,
                         GError **error)
{
	GError *local_error = NULL;

	g_return_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view));

	client_view->priv->running = FALSE;

	e_dbus_address_book_view_call_stop_sync (
		client_view->priv->dbus_proxy, NULL, &local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
	}
}

/**
 * e_book_client_view_set_flags:
 * @client_view: an #EBookClientView
 * @flags: the #EBookClientViewFlags for @client_view
 * @error: return location for a #GError, or %NULL
 *
 * Sets the @flags which control the behaviour of @client_view.
 *
 * Since: 3.4
 */
void
e_book_client_view_set_flags (EBookClientView *client_view,
                              EBookClientViewFlags flags,
                              GError **error)
{
	GError *local_error = NULL;

	g_return_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view));

	e_dbus_address_book_view_call_set_flags_sync (
		client_view->priv->dbus_proxy, flags, NULL, &local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
	}
}

/**
 * e_book_client_view_set_fields_of_interest:
 * @client_view: an #EBookClientView
 * @fields_of_interest: (element-type utf8): List of field names in which
 *                      the client is interested
 * @error: return location for a #GError, or %NULL
 *
 * Client can instruct server to which fields it is interested in only, thus
 * the server can return less data over the wire. The server can still return
 * complete objects, this is just a hint to it that the listed fields will
 * be used only. The UID field is returned always. Initial views has no fields
 * of interest and using %NULL for @fields_of_interest will unset any previous
 * changes.
 *
 * Some backends can use summary information of its cache to create artifical
 * objects, which will omit stored object parsing. If this cannot be done then
 * it will simply return object as is stored in the cache.
 **/
void
e_book_client_view_set_fields_of_interest (EBookClientView *client_view,
                                           const GSList *fields_of_interest,
                                           GError **error)
{
	gchar **strv;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view));

	/* When in direct read access mode, ensure that the
	 * backend is configured to only send us UIDs for everything,
	 *
	 * Just ignore the fields_of_interest and use them locally
	 * when filtering cards to be returned in direct reads. */
	if (client_view->priv->direct_backend != NULL) {
		GSList uid_field = { 0, };

		uid_field.data = (gpointer)"x-evolution-uids-only";
		strv = e_client_util_slist_to_strv (&uid_field);
	} else
		strv = e_client_util_slist_to_strv (fields_of_interest);

	e_dbus_address_book_view_call_set_fields_of_interest_sync (
		client_view->priv->dbus_proxy,
		(const gchar * const *) strv,
		NULL, &local_error);
	g_strfreev (strv);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
	}
}

