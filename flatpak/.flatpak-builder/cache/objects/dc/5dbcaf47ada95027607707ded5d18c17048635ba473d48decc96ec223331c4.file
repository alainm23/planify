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

/* e-book deprecated since 3.2, use e-book-client instead */

/**
 * SECTION:e-book
 *
 * The old asynchronous API was deprecated since 3.0 and is replaced with
 * their an equivalent version which has a detailed #GError
 * structure in the asynchronous callback, instead of a status code only.
 *
 * As an example, e_book_async_open() is replaced by e_book_open_async().
 *
 * Deprecated: 3.2: Use #EBookClient instead.
 */

#include "evolution-data-server-config.h"

#include <unistd.h>
#include <string.h>
#include <glib/gi18n-lib.h>
#include "e-book.h"
#include "e-error.h"
#include "e-book-view-private.h"

#define E_BOOK_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK, EBookPrivate))

#define CLIENT_BACKEND_PROPERTY_CAPABILITIES		"capabilities"
#define BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS		"required-fields"
#define BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS		"supported-fields"

struct _EBookPrivate {
	EBookClient *client;
	gulong backend_died_handler_id;
	gulong notify_online_handler_id;
	gulong notify_readonly_handler_id;

	ESource *source;
	gchar *cap;
};

typedef struct {
	EBook *book;
	gpointer callback; /* TODO union */
	gpointer excallback;
	gpointer closure;
	gpointer data;
} AsyncData;

enum {
	PROP_0,
	PROP_SOURCE
};

enum {
	WRITABLE_STATUS,
	CONNECTION_STATUS,
	AUTH_REQUIRED,
	BACKEND_DIED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static void	e_book_initable_init		(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EBook, e_book, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, e_book_initable_init))

G_DEFINE_QUARK (e-book-error-quark, e_book_error)

static void
book_backend_died_cb (EClient *client,
                      EBook *book)
{
	/* Echo the signal emission from the EBookClient. */
	g_signal_emit (book, signals[BACKEND_DIED], 0);
}

static void
book_notify_online_cb (EClient *client,
                       GParamSpec *pspec,
                       EBook *book)
{
	gboolean online = e_client_is_online (client);

	g_signal_emit (book, signals[CONNECTION_STATUS], 0, online);
}

static void
book_notify_readonly_cb (EClient *client,
                         GParamSpec *pspec,
                         EBook *book)
{
	gboolean writable = !e_client_is_readonly (client);

	g_signal_emit (book, signals[WRITABLE_STATUS], 0, writable);
}

static void
book_set_source (EBook *book,
                 ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (book->priv->source == NULL);

	book->priv->source = g_object_ref (source);
}

static void
book_set_property (GObject *object,
                   guint property_id,
                   const GValue *value,
                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			book_set_source (
				E_BOOK (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
book_get_property (GObject *object,
                   guint property_id,
                   GValue *value,
                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			g_value_set_object (
				value, e_book_get_source (
				E_BOOK (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
book_dispose (GObject *object)
{
	EBookPrivate *priv;

	priv = E_BOOK_GET_PRIVATE (object);

	if (priv->client != NULL) {
		g_signal_handler_disconnect (
			priv->client,
			priv->backend_died_handler_id);
		g_signal_handler_disconnect (
			priv->client,
			priv->notify_online_handler_id);
		g_signal_handler_disconnect (
			priv->client,
			priv->notify_readonly_handler_id);
		g_object_unref (priv->client);
		priv->client = NULL;
	}

	if (priv->source != NULL) {
		g_object_unref (priv->source);
		priv->source = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_book_parent_class)->dispose (object);
}

static void
book_finalize (GObject *object)
{
	EBookPrivate *priv;

	priv = E_BOOK_GET_PRIVATE (object);

	g_free (priv->cap);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_parent_class)->finalize (object);
}

static gboolean
book_initable_init (GInitable *initable,
                    GCancellable *cancellable,
                    GError **error)
{
	EBook *book = E_BOOK (initable);
	ESource *source;

	source = e_book_get_source (book);

	book->priv->client = e_book_client_new (source, error);

	if (book->priv->client == NULL)
		return FALSE;

	book->priv->backend_died_handler_id = g_signal_connect (
		book->priv->client, "backend-died",
		G_CALLBACK (book_backend_died_cb), book);

	book->priv->notify_online_handler_id = g_signal_connect (
		book->priv->client, "notify::online",
		G_CALLBACK (book_notify_online_cb), book);

	book->priv->notify_readonly_handler_id = g_signal_connect (
		book->priv->client, "notify::readonly",
		G_CALLBACK (book_notify_readonly_cb), book);

	return TRUE;
}

static void
e_book_class_init (EBookClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBookPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = book_set_property;
	object_class->get_property = book_get_property;
	object_class->dispose = book_dispose;
	object_class->finalize = book_finalize;

	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			"The data source for this EBook",
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	signals[WRITABLE_STATUS] = g_signal_new (
		"writable_status",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClass, writable_status),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_BOOLEAN);

	signals[CONNECTION_STATUS] = g_signal_new (
		"connection_status",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClass, connection_status),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_BOOLEAN);

	signals[BACKEND_DIED] = g_signal_new (
		"backend_died",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClass, backend_died),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_book_initable_init (GInitableIface *iface)
{
	iface->init = book_initable_init;
}

static void
e_book_init (EBook *book)
{
	book->priv = E_BOOK_GET_PRIVATE (book);
}

/**
 * e_book_add_contact:
 * @book: an #EBook
 * @contact: an #EContact
 * @error: a #GError to set on failure
 *
 * Adds @contact to @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_book_client_add_contact_sync() instead.
 **/
gboolean
e_book_add_contact (EBook *book,
                    EContact *contact,
                    GError **error)
{
	gchar *added_uid = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	success = e_book_client_add_contact_sync (
		book->priv->client, contact, &added_uid, NULL, error);

	if (added_uid != NULL) {
		e_contact_set (contact, E_CONTACT_UID, added_uid);
		g_free (added_uid);
	}

	return success;
}

static void
add_contact_reply (GObject *source_object,
                   GAsyncResult *result,
                   gpointer user_data)
{
	AsyncData *data = user_data;
	EBookIdCallback cb = data->callback;
	EBookIdAsyncCallback excb = data->excallback;
	gchar *added_uid = NULL;
	GError *error = NULL;

	e_book_client_add_contact_finish (
		E_BOOK_CLIENT (source_object), result, &added_uid, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, added_uid, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, NULL, data->closure);
	if (excb != NULL)
		excb (data->book, error, added_uid, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_free (added_uid);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_add_contact:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Adds @contact to @book without blocking.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Deprecated: 3.0: Use e_book_add_contact_async() instead.
 **/
gboolean
e_book_async_add_contact (EBook *book,
                          EContact *contact,
                          EBookIdCallback cb,
                          gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_book_client_add_contact (
		book->priv->client, contact, NULL,
		add_contact_reply, data);

	return TRUE;
}

/**
 * e_book_add_contact_async:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Adds @contact to @book without blocking.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_add_contact() and
 *                  e_book_client_add_contact_finish() instead.
 **/
gboolean
e_book_add_contact_async (EBook *book,
                          EContact *contact,
                          EBookIdAsyncCallback cb,
                          gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_book_client_add_contact (
		book->priv->client, contact, NULL,
		add_contact_reply, data);

	return TRUE;
}

/**
 * e_book_commit_contact:
 * @book: an #EBook
 * @contact: an #EContact
 * @error: a #GError to set on failure
 *
 * Applies the changes made to @contact to the stored version in
 * @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_modify_contact_sync() instead.
 **/
gboolean
e_book_commit_contact (EBook *book,
                       EContact *contact,
                       GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	return e_book_client_modify_contact_sync (
		book->priv->client, contact, NULL, error);
}

static void
modify_contacts_reply (GObject *source_object,
                       GAsyncResult *result,
                       gpointer user_data)
{
	AsyncData *data = user_data;
	EBookCallback cb = data->callback;
	EBookAsyncCallback excb = data->excallback;
	GError *error = NULL;

	e_book_client_modify_contact_finish (
		E_BOOK_CLIENT (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);
	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_commit_contact:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Applies the changes made to @contact to the stored version in
 * @book without blocking.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Deprecated: 3.0: Use e_book_commit_contact_async() instead.
 **/
gboolean
e_book_async_commit_contact (EBook *book,
                             EContact *contact,
                             EBookCallback cb,
                             gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_book_client_modify_contact (
		book->priv->client, contact, NULL,
		modify_contacts_reply, data);

	return TRUE;
}

/**
 * e_book_commit_contact_async:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Applies the changes made to @contact to the stored version in
 * @book without blocking.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_modify_contact() and
 *                  e_book_client_modify_contact_finish() instead.
 **/
gboolean
e_book_commit_contact_async (EBook *book,
                             EContact *contact,
                             EBookAsyncCallback cb,
                             gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_book_client_modify_contact (
		book->priv->client, contact, NULL,
		modify_contacts_reply, data);

	return TRUE;
}

/**
 * e_book_get_required_fields:
 * @book: an #EBook
 * @fields: (out) (transfer full) (element-type utf8): a #GList of fields
 *          to set on success
 * @error: a #GError to set on failure
 *
 * Gets a list of fields that are required to be filled in for
 * all contacts in this @book. The list will contain pointers
 * to allocated strings, and both the #GList and the strings
 * must be freed by the caller.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_client_get_backend_property_sync() on
 * an #EBookClient object with #BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS instead.
 **/
gboolean
e_book_get_required_fields (EBook *book,
                            GList **fields,
                            GError **error)
{
	gchar *prop_value = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	if (fields != NULL)
		*fields = NULL;

	success = e_client_get_backend_property_sync (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS,
		&prop_value, NULL, error);

	if (success && fields != NULL) {
		GQueue queue = G_QUEUE_INIT;
		gchar **strv;
		gint ii;

		strv = g_strsplit (prop_value, ",", -1);

		for (ii = 0; strv != NULL && strv[ii] != NULL; ii++)
			g_queue_push_tail (&queue, strv[ii]);

		/* The GQueue now owns the strings in the string array,
		 * so use g_free() instead of g_strfreev() to free just
		 * the array itself. */
		g_free (strv);

		/* Transfer ownership of the GQueue content. */
		*fields = g_queue_peek_head_link (&queue);
	}

	g_free (prop_value);

	return success;
}

static void
get_required_fields_reply (GObject *source_object,
                           GAsyncResult *result,
                           gpointer user_data)
{
	AsyncData *data = user_data;
	EBookEListCallback cb = data->callback;
	EBookEListAsyncCallback excb = data->excallback;
	EList *elist;
	gchar *prop_value = NULL;
	GError *error = NULL;

	e_client_get_backend_property_finish (
		E_CLIENT (source_object), result, &prop_value, &error);

	/* Sanity check. */
	g_return_if_fail (
		((prop_value != NULL) && (error == NULL)) ||
		((prop_value == NULL) && (error != NULL)));

	/* In the event of an error, we pass an empty EList. */
	elist = e_list_new (NULL, (EListFreeFunc) g_free, NULL);

	if (prop_value != NULL) {
		gchar **strv;
		gint ii;

		strv = g_strsplit (prop_value, ",", -1);
		for (ii = 0; strv != NULL && strv[ii] != NULL; ii++) {
			gchar *utf8 = e_util_utf8_make_valid (strv[ii]);
			e_list_append (elist, utf8);
		}
		g_strfreev (strv);
	}

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, elist, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, elist, data->closure);
	if (excb != NULL)
		excb (data->book, error, elist, data->closure);

	g_object_unref (elist);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_get_required_fields:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Gets a list of fields that are required to be filled in for
 * all contacts in this @book. This function does not block.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Deprecated: 3.0: Use e_book_get_required_fields_async() instead.
 **/
gboolean
e_book_async_get_required_fields (EBook *book,
                                  EBookEListCallback cb,
                                  gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_client_get_backend_property (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS,
		NULL, get_required_fields_reply, data);

	return TRUE;
}

/**
 * e_book_get_required_fields_async:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Gets a list of fields that are required to be filled in for
 * all contacts in this @book. This function does not block.
 *
 * Returns: %TRUE if the operation was started, %FALSE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_client_get_backend_property() and
 *                  e_client_get_backend_property_finish() on an
 *                  #EBookClient object with
 *                  #BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS instead.
 **/
gboolean
e_book_get_required_fields_async (EBook *book,
                                  EBookEListAsyncCallback cb,
                                  gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_client_get_backend_property (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS,
		NULL, get_required_fields_reply, data);

	return TRUE;
}

/**
 * e_book_get_supported_fields:
 * @book: an #EBook
 * @fields: (out) (transfer full) (element-type utf8): a #GList of fields
 *          to set on success
 * @error: a #GError to set on failure
 *
 * Gets a list of fields that can be stored for contacts
 * in this @book. Other fields may be discarded. The list
 * will contain pointers to allocated strings, and both the
 * #GList and the strings must be freed by the caller.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_client_get_backend_property_sync() on
 * an #EBookClient object with #BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS instead.
 **/
gboolean
e_book_get_supported_fields (EBook *book,
                             GList **fields,
                             GError **error)
{
	gchar *prop_value = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	if (fields != NULL)
		*fields = NULL;

	success = e_client_get_backend_property_sync (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS,
		&prop_value, NULL, error);

	if (success && fields != NULL) {
		GQueue queue = G_QUEUE_INIT;
		gchar **strv;
		gint ii;

		strv = g_strsplit (prop_value, ",", -1);

		for (ii = 0; strv != NULL && strv[ii] != NULL; ii++)
			g_queue_push_tail (&queue, strv[ii]);

		/* The GQueue now owns the strings in the string array,
		 * so use g_free() instead of g_strfreev() to free just
		 * the array itself. */
		g_free (strv);

		/* Transfer ownership of the GQueue content. */
		*fields = g_queue_peek_head_link (&queue);
	}

	g_free (prop_value);

	return success;
}

static void
get_supported_fields_reply (GObject *source_object,
                            GAsyncResult *result,
                            gpointer user_data)
{
	AsyncData *data = user_data;
	EBookEListCallback cb = data->callback;
	EBookEListAsyncCallback excb = data->excallback;
	EList *elist;
	gchar *prop_value = NULL;
	GError *error = NULL;

	e_client_get_backend_property_finish (
		E_CLIENT (source_object), result, &prop_value, &error);

	/* Sanity check. */
	g_return_if_fail (
		((prop_value != NULL) && (error == NULL)) ||
		((prop_value == NULL) && (error != NULL)));

	/* In the event of an error, we pass an empty EList. */
	elist = e_list_new (NULL, (EListFreeFunc) g_free, NULL);

	if (prop_value != NULL) {
		gchar **strv;
		gint ii;

		strv = g_strsplit (prop_value, ",", -1);
		for (ii = 0; strv != NULL && strv[ii] != NULL; ii++) {
			gchar *utf8 = e_util_utf8_make_valid (strv[ii]);
			e_list_append (elist, utf8);
		}
		g_strfreev (strv);
	}

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, elist, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, elist, data->closure);
	if (excb != NULL)
		excb (data->book, error, elist, data->closure);

	g_object_unref (elist);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_get_supported_fields:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Gets a list of fields that can be stored for contacts
 * in this @book. Other fields may be discarded. This
 * function does not block.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.0: Use e_book_get_supported_fields_async() instead.
 **/
gboolean
e_book_async_get_supported_fields (EBook *book,
                                   EBookEListCallback cb,
                                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_client_get_backend_property (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS,
		NULL, get_supported_fields_reply, data);

	return TRUE;
}

/**
 * e_book_get_supported_fields_async:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Gets a list of fields that can be stored for contacts
 * in this @book. Other fields may be discarded. This
 * function does not block.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_client_get_backend_property() and
 *                  e_client_get_backend_property_finish() on an
 *                  #EBookClient object with
 *                  #BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS instead.
 **/
gboolean
e_book_get_supported_fields_async (EBook *book,
                                   EBookEListAsyncCallback cb,
                                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_client_get_backend_property (
		E_CLIENT (book->priv->client),
		BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS,
		NULL, get_supported_fields_reply, data);

	return TRUE;
}

/**
 * e_book_get_supported_auth_methods:
 * @book: an #EBook
 * @auth_methods: (out) (transfer full) (element-type utf8): a #GList of
 *                auth methods to set on success
 * @error: a #GError to set on failure
 *
 * Queries @book for the list of authentication methods it supports.
 * The list will contain pointers to allocated strings, and both the
 * #GList and the strings must be freed by the caller.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: The property is no longer supported.
 **/
gboolean
e_book_get_supported_auth_methods (EBook *book,
                                   GList **auth_methods,
                                   GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	if (auth_methods != NULL)
		*auth_methods = NULL;

	return TRUE;
}

/**
 * e_book_async_get_supported_auth_methods:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Queries @book for the list of authentication methods it supports.
 * This function does not block.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.0: The property is no longer supported.
 **/
gboolean
e_book_async_get_supported_auth_methods (EBook *book,
                                         EBookEListCallback cb,
                                         gpointer closure)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	if (cb != NULL) {
		/* Pass the callback an empty list. */
		EList *elist = e_list_new (NULL, NULL, NULL);
		cb (book, E_BOOK_ERROR_OK, elist, closure);
		g_object_unref (elist);
	}

	return TRUE;
}

/**
 * e_book_get_supported_auth_methods_async:
 * @book: an #EBook
 * @cb: (scope async): function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Queries @book for the list of authentication methods it supports.
 * This function does not block.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: The property is no longer supported.
 **/
gboolean
e_book_get_supported_auth_methods_async (EBook *book,
                                         EBookEListAsyncCallback cb,
                                         gpointer closure)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	if (cb != NULL) {
		/* Pass the callback an empty list. */
		EList *elist = e_list_new (NULL, NULL, NULL);
		cb (book, NULL, elist, closure);
		g_object_unref (elist);
	}

	return TRUE;
}

/**
 * e_book_get_contact:
 * @book: an #EBook
 * @id: a unique string ID specifying the contact
 * @contact: (out) (transfer full): an #EContact
 * @error: a #GError to set on failure
 *
 * Fills in @contact with the contents of the vcard in @book
 * corresponding to @id.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_get_contact_sync() instead.
 **/
gboolean
e_book_get_contact (EBook *book,
                    const gchar *id,
                    EContact **contact,
                    GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);
	g_return_val_if_fail (contact != NULL, FALSE);

	return e_book_client_get_contact_sync (
		book->priv->client, id, contact, NULL, error);
}

static void
get_contact_reply (GObject *source_object,
                   GAsyncResult *result,
                   gpointer user_data)
{
	AsyncData *data = user_data;
	EBookContactCallback cb = data->callback;
	EBookContactAsyncCallback excb = data->excallback;
	EContact *contact = NULL;
	GError *error = NULL;

	if (!e_book_client_get_contact_finish (
		E_BOOK_CLIENT (source_object), result, &contact, &error)) {

		if (!error)
			error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, contact, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, NULL, data->closure);
	if (excb != NULL)
		excb (data->book, error, contact, data->closure);

	if (contact != NULL)
		g_object_unref (contact);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_get_contact:
 * @book: an #EBook
 * @id: a unique string ID specifying the contact
 * @cb: (scope async): function to call when operation finishes
 * @closure: data to pass to callback function
 *
 * Retrieves a contact specified by @id from @book.
 *
 * Returns: %FALSE if successful, %TRUE otherwise
 *
 * Deprecated: 3.0: Use e_book_get_contact_async() instead.
 **/
gboolean
e_book_async_get_contact (EBook *book,
                          const gchar *id,
                          EBookContactCallback cb,
                          gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_book_client_get_contact (
		E_BOOK_CLIENT (book->priv->client),
		id, NULL, get_contact_reply, data);

	return TRUE;
}

/**
 * e_book_get_contact_async:
 * @book: an #EBook
 * @id: a unique string ID specifying the contact
 * @cb: (scope async): function to call when operation finishes
 * @closure: data to pass to callback function
 *
 * Retrieves a contact specified by @id from @book.
 *
 * Returns: %FALSE if successful, %TRUE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_get_contact() and
 *                  e_book_client_get_contact_finish() instead.
 **/
gboolean
e_book_get_contact_async (EBook *book,
                          const gchar *id,
                          EBookContactAsyncCallback cb,
                          gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_book_client_get_contact (
		E_BOOK_CLIENT (book->priv->client),
		id, NULL, get_contact_reply, data);

	return TRUE;
}

/**
 * e_book_remove_contact:
 * @book: an #EBook
 * @id: a string
 * @error: a #GError to set on failure
 *
 * Removes the contact with id @id from @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_remove_contact_by_uid_sync() or
 *                  e_book_client_remove_contact_sync() instead.
 **/
gboolean
e_book_remove_contact (EBook *book,
                       const gchar *id,
                       GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	return e_book_client_remove_contact_by_uid_sync (
		book->priv->client, id, NULL, error);
}

static void
remove_contact_reply (GObject *source_object,
                      GAsyncResult *result,
                      gpointer user_data)
{
	AsyncData *data = user_data;
	EBookCallback cb = data->callback;
	EBookAsyncCallback excb = data->excallback;
	GError *error = NULL;

	e_book_client_remove_contact_finish (
		E_BOOK_CLIENT (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);
	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_remove_contacts:
 * @book: an #EBook
 * @ids: (element-type utf8): an #GList of const gchar *id's
 * @error: a #GError to set on failure
 *
 * Removes the contacts with ids from the list @ids from @book.  This is
 * always more efficient than calling e_book_remove_contact() if you
 * have more than one id to remove, as some backends can implement it
 * as a batch request.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_remove_contacts_sync() instead.
 **/
gboolean
e_book_remove_contacts (EBook *book,
                        GList *ids,
                        GError **error)
{
	GSList *slist = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (ids != NULL, FALSE);

	/* XXX Never use GSList in a public API. */
	while (ids != NULL) {
		slist = g_slist_prepend (slist, ids->data);
		ids = g_list_next (ids);
	}
	slist = g_slist_reverse (slist);

	success = e_book_client_remove_contacts_sync (
		book->priv->client, slist, NULL, error);

	g_slist_free (slist);

	return success;
}

/**
 * e_book_async_remove_contact:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes @contact from @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.0: Use e_book_remove_contact_async() instead.
 **/
gboolean
e_book_async_remove_contact (EBook *book,
                             EContact *contact,
                             EBookCallback cb,
                             gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_book_client_remove_contact (
		E_BOOK_CLIENT (book->priv->client),
		contact, NULL, remove_contact_reply, data);

	return TRUE;
}

/**
 * e_book_remove_contact_async:
 * @book: an #EBook
 * @contact: an #EContact
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes @contact from @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_remove_contact() and
 *                  e_book_client_remove_contact_finish() instead.
 **/
gboolean
e_book_remove_contact_async (EBook *book,
                             EContact *contact,
                             EBookAsyncCallback cb,
                             gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_book_client_remove_contact (
		E_BOOK_CLIENT (book->priv->client),
		contact, NULL, remove_contact_reply, data);

	return TRUE;
}

static void
remove_contact_by_id_reply (GObject *source_object,
                            GAsyncResult *result,
                            gpointer user_data)
{
	AsyncData *data = user_data;
	EBookCallback cb = data->callback;
	EBookAsyncCallback excb = data->excallback;
	GError *error = NULL;

	e_book_client_remove_contact_by_uid_finish (
		E_BOOK_CLIENT (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);
	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_remove_contact_by_id:
 * @book: an #EBook
 * @id: a unique ID string specifying the contact
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes the contact with id @id from @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.0: Use e_book_remove_contact_by_id_async() instead.
 **/
gboolean
e_book_async_remove_contact_by_id (EBook *book,
                                   const gchar *id,
                                   EBookCallback cb,
                                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_book_client_remove_contact_by_uid (
		E_BOOK_CLIENT (book->priv->client),
		id, NULL, remove_contact_by_id_reply, data);

	return TRUE;
}

/**
 * e_book_remove_contact_by_id_async:
 * @book: an #EBook
 * @id: a unique ID string specifying the contact
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes the contact with id @id from @book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_remove_contact_by_uid() and
 *                  e_book_client_remove_contact_by_uid_finish() instead.
 **/
gboolean
e_book_remove_contact_by_id_async (EBook *book,
                                   const gchar *id,
                                   EBookAsyncCallback cb,
                                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_book_client_remove_contact_by_uid (
		E_BOOK_CLIENT (book->priv->client),
		id, NULL, remove_contact_by_id_reply, data);

	return TRUE;
}

static void
remove_contacts_reply (GObject *source_object,
                       GAsyncResult *result,
                       gpointer user_data)
{
	AsyncData *data = user_data;
	EBookCallback cb = data->callback;
	EBookAsyncCallback excb = data->excallback;
	GError *error = NULL;

	e_book_client_remove_contacts_finish (
		E_BOOK_CLIENT (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);
	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_remove_contacts:
 * @book: an #EBook
 * @ids: (element-type utf8): a #GList of const gchar *id's
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes the contacts with ids from the list @ids from @book.  This is
 * always more efficient than calling e_book_remove_contact() if you
 * have more than one id to remove, as some backends can implement it
 * as a batch request.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.0: Use e_book_remove_contacts_async() instead.
 **/
gboolean
e_book_async_remove_contacts (EBook *book,
                              GList *ids,
                              EBookCallback cb,
                              gpointer closure)
{
	AsyncData *data;
	GSList *slist = NULL;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	/* XXX Never use GSList in a public API. */
	while (ids != NULL) {
		slist = g_slist_prepend (slist, ids->data);
		ids = g_list_next (ids);
	}
	slist = g_slist_reverse (slist);

	e_book_client_remove_contacts (
		E_BOOK_CLIENT (book->priv->client),
		slist, NULL, remove_contacts_reply, data);

	g_slist_free (slist);

	return TRUE;
}

/**
 * e_book_remove_contacts_async:
 * @book: an #EBook
 * @ids: (element-type utf8): a #GList of const gchar *id's
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Removes the contacts with ids from the list @ids from @book.  This is
 * always more efficient than calling e_book_remove_contact() if you
 * have more than one id to remove, as some backends can implement it
 * as a batch request.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_remove_contacts() and
 *                  e_book_client_remove_contacts_finish() instead.
 **/
gboolean
e_book_remove_contacts_async (EBook *book,
                              GList *ids,
                              EBookAsyncCallback cb,
                              gpointer closure)
{
	AsyncData *data;
	GSList *slist = NULL;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	/* XXX Never use GSList in a public API. */
	while (ids != NULL) {
		slist = g_slist_prepend (slist, ids->data);
		ids = g_list_next (ids);
	}
	slist = g_slist_reverse (slist);

	e_book_client_remove_contacts (
		E_BOOK_CLIENT (book->priv->client),
		slist, NULL, remove_contacts_reply, data);

	g_slist_free (slist);

	return TRUE;
}

/**
 * e_book_get_book_view:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @requested_fields: (allow-none) (element-type utf8): a #GList containing
 *                    the names of fields to return, or NULL for all
 * @max_results: the maximum number of contacts to show (or 0 for all)
 * @book_view: (out): A #EBookView pointer, will be set to the view
 * @error: a #GError to set on failure
 *
 * Query @book with @query, creating a #EBookView in @book_view with the fields
 * specified by @requested_fields and limited at @max_results records. On an
 * error, @error is set and %FALSE returned.
 *
 * Returns: %TRUE if successful, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_get_view_sync() instead.
 **/
gboolean
e_book_get_book_view (EBook *book,
                      EBookQuery *query,
                      GList *requested_fields,
                      gint max_results,
                      EBookView **book_view,
                      GError **error)
{
	EBookClientView *client_view = NULL;
	gchar *sexp;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);
	g_return_val_if_fail (book_view != NULL, FALSE);

	sexp = e_book_query_to_string (query);

	success = e_book_client_get_view_sync (
		book->priv->client, sexp, &client_view, NULL, error);

	g_free (sexp);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (client_view != NULL)) ||
		(!success && (client_view == NULL)), FALSE);

	if (client_view != NULL) {
		*book_view = _e_book_view_new (book, client_view);
		g_object_unref (client_view);
	}

	return success;
}

static void
get_book_view_reply (GObject *source_object,
                     GAsyncResult *result,
                     gpointer user_data)
{
	AsyncData *data = user_data;
	EBookBookViewCallback cb = data->callback;
	EBookBookViewAsyncCallback excb = data->excallback;
	EBookClientView *client_view = NULL;
	EBookView *view = NULL;
	GError *error = NULL;

	e_book_client_get_view_finish (
		E_BOOK_CLIENT (source_object),
		result, &client_view, &error);

	/* Sanity check. */
	g_return_if_fail (
		((client_view != NULL) && (error == NULL)) ||
		((client_view == NULL) && (error != NULL)));

	if (client_view != NULL) {
		view = _e_book_view_new (data->book, client_view);
		g_object_unref (client_view);
	}

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, view, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, NULL, data->closure);
	if (excb != NULL)
		excb (data->book, error, view, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_get_book_view:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @requested_fields: (element-type utf8): a #GList containing the names of
 *                    fields to return, or NULL for all
 * @max_results: the maximum number of contacts to show (or 0 for all)
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Query @book with @query, creating a #EBookView with the fields
 * specified by @requested_fields and limited at @max_results records.
 *
 * Returns: %FALSE if successful, %TRUE otherwise
 *
 * Deprecated: 3.0: Use e_book_get_book_view_async() instead.
 **/
gboolean
e_book_async_get_book_view (EBook *book,
                            EBookQuery *query,
                            GList *requested_fields,
                            gint max_results,
                            EBookBookViewCallback cb,
                            gpointer closure)
{
	AsyncData *data;
	gchar *sexp;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	sexp = e_book_query_to_string (query);

	e_book_client_get_view (
		book->priv->client, sexp,
		NULL, get_book_view_reply, data);

	g_free (sexp);

	return TRUE;
}

/**
 * e_book_get_book_view_async:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @requested_fields: (allow-none) (element-type utf8): a #GList containing
 *                    the names of fields to
 * return, or NULL for all
 * @max_results: the maximum number of contacts to show (or 0 for all)
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Query @book with @query, creating a #EBookView with the fields
 * specified by @requested_fields and limited at @max_results records.
 *
 * Returns: %FALSE if successful, %TRUE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_get_view() and
 *                  e_book_client_get_view_finish() instead.
 **/
gboolean
e_book_get_book_view_async (EBook *book,
                            EBookQuery *query,
                            GList *requested_fields,
                            gint max_results,
                            EBookBookViewAsyncCallback cb,
                            gpointer closure)
{
	AsyncData *data;
	gchar *sexp;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	sexp = e_book_query_to_string (query);

	e_book_client_get_view (
		book->priv->client, sexp,
		NULL, get_book_view_reply, data);

	g_free (sexp);

	return TRUE;
}

/**
 * e_book_get_contacts:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @contacts: (element-type utf8): a #GList pointer, will be set to the
 *            list of contacts
 * @error: a #GError to set on failure
 *
 * Query @book with @query, setting @contacts to the list of contacts which
 * matched. On failed, @error will be set and %FALSE returned.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_book_client_get_contacts_sync() instead.
 **/
gboolean
e_book_get_contacts (EBook *book,
                     EBookQuery *query,
                     GList **contacts,
                     GError **error)
{
	GSList *slist = NULL;
	gchar *sexp;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	if (contacts != NULL)
		*contacts = NULL;

	sexp = e_book_query_to_string (query);

	success = e_book_client_get_contacts_sync (
		E_BOOK_CLIENT (book->priv->client),
		sexp, &slist, NULL, error);

	g_free (sexp);

	/* XXX Never use GSList in a public API. */
	if (success && contacts != NULL) {
		GList *list = NULL;
		GSList *link;

		for (link = slist; link != NULL; link = g_slist_next (link)) {
			EContact *contact = E_CONTACT (link->data);
			list = g_list_prepend (list, g_object_ref (contact));
		}

		*contacts = g_list_reverse (list);
	}

	g_slist_free_full (slist, (GDestroyNotify) g_object_unref);

	return success;
}

static void
get_contacts_reply (GObject *source_object,
                    GAsyncResult *result,
                    gpointer user_data)
{
	AsyncData *data = user_data;
	EBookListAsyncCallback excb = data->excallback;
	EBookListCallback cb = data->callback;
	GSList *slist = NULL;
	GList *list = NULL;
	GError *error = NULL;

	e_book_client_get_contacts_finish (
		E_BOOK_CLIENT (source_object), result, &slist, &error);

	/* XXX Never use GSList in a public API. */
	if (error == NULL) {
		GSList *link;

		for (link = slist; link != NULL; link = g_slist_next (link)) {
			EContact *contact = E_CONTACT (link->data);
			list = g_list_prepend (list, g_object_ref (contact));
		}

		list = g_list_reverse (list);
	}

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, list, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, list, data->closure);
	if (excb != NULL)
		excb (data->book, error, list, data->closure);

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
	g_slist_free_full (slist, (GDestroyNotify) g_object_unref);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_get_contacts:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Query @book with @query.
 *
 * Returns: %FALSE on success, %TRUE otherwise
 *
 * Deprecated: 3.0: Use e_book_get_contacts_async() instead.
 **/
gboolean
e_book_async_get_contacts (EBook *book,
                           EBookQuery *query,
                           EBookListCallback cb,
                           gpointer closure)
{
	AsyncData *data;
	gchar *sexp;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	sexp = e_book_query_to_string (query);

	e_book_client_get_contacts (
		E_BOOK_CLIENT (book->priv->client),
		sexp, NULL, get_contacts_reply, data);

	g_free (sexp);

	return TRUE;
}

/**
 * e_book_get_contacts_async:
 * @book: an #EBook
 * @query: an #EBookQuery
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Query @book with @query.
 *
 * Returns: %FALSE on success, %TRUE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_book_client_get_contacts() and
 *                  e_book_client_get_contacts_finish() instead.
 **/
gboolean
e_book_get_contacts_async (EBook *book,
                           EBookQuery *query,
                           EBookListAsyncCallback cb,
                           gpointer closure)
{
	AsyncData *data;
	gchar *sexp;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	sexp = e_book_query_to_string (query);

	e_book_client_get_contacts (
		E_BOOK_CLIENT (book->priv->client),
		sexp, NULL, get_contacts_reply, data);

	g_free (sexp);

	return TRUE;
}

/**
 * e_book_get_changes: (skip)
 * @book: an #EBook
 * @changeid:  the change ID
 * @changes: (out) (transfer full): return location for a #GList of #EBookChange items
 * @error: a #GError to set on failure.
 *
 * Get the set of changes since the previous call to e_book_get_changes()
 * for a given change ID.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
gboolean
e_book_get_changes (EBook *book,
                    const gchar *changeid,
                    GList **changes,
                    GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	g_set_error (
		error, E_BOOK_ERROR,
		E_BOOK_ERROR_NOT_SUPPORTED,
		"Not supported");

	return FALSE;
}

/**
 * e_book_async_get_changes:
 * @book: an #EBook
 * @changeid:  the change ID
 * @cb: (scope async): function to call when operation finishes
 * @closure: data to pass to callback function
 *
 * Get the set of changes since the previous call to
 * e_book_async_get_changes() for a given change ID.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Deprecated: 3.0: Use e_book_get_changes_async() instead.
 */
gboolean
e_book_async_get_changes (EBook *book,
                          const gchar *changeid,
                          EBookListCallback cb,
                          gpointer closure)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	cb (book, E_BOOK_ERROR_NOT_SUPPORTED, NULL, closure);

	return TRUE;
}

/**
 * e_book_get_changes_async:
 * @book: an #EBook
 * @changeid:  the change ID
 * @cb: (scope async): function to call when operation finishes
 * @closure: data to pass to callback function
 *
 * Get the set of changes since the previous call to
 * e_book_async_get_changes() for a given change ID.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
gboolean
e_book_get_changes_async (EBook *book,
                          const gchar *changeid,
                          EBookListAsyncCallback cb,
                          gpointer closure)
{
	GError *error;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	error = g_error_new (
		E_BOOK_ERROR,
		E_BOOK_ERROR_NOT_SUPPORTED,
		"Not supported");

	cb (book, error, NULL, closure);

	g_error_free (error);

	return TRUE;
}

/**
 * e_book_free_change_list:
 * @change_list: (element-type EBookChange): a #GList of #EBookChange items
 *
 * Free the contents of #change_list, and the list itself.
 *
 * Deprecated: 3.2: Related function has been dropped completely.
 */
void
e_book_free_change_list (GList *change_list)
{
	GList *l;
	for (l = change_list; l; l = l->next) {
		EBookChange *change = l->data;

		g_object_unref (change->contact);
		g_slice_free (EBookChange, change);
	}

	g_list_free (change_list);
}

/**
 * e_book_cancel:
 * @book: an #EBook
 * @error: a #GError to set on failure
 *
 * Used to cancel an already running operation on @book.  This
 * function makes a synchronous CORBA to the backend telling it to
 * cancel the operation.  If the operation wasn't cancellable (either
 * transiently or permanently) or had already comopleted on the server
 * side, this function will return E_BOOK_STATUS_COULD_NOT_CANCEL, and
 * the operation will continue uncancelled.  If the operation could be
 * cancelled, this function will return E_BOOK_ERROR_OK, and the
 * blocked e_book function corresponding to current operation will
 * return with a status of E_BOOK_STATUS_CANCELLED.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Deprecated: 3.2: Use e_client_cancel_all() on an #EBookClient object instead.
 **/
gboolean
e_book_cancel (EBook *book,
               GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	e_client_cancel_all (E_CLIENT (book->priv->client));

	return TRUE;
}

/**
 * e_book_cancel_async_op:
 * @book: an #EBook
 * @error: return location for a #GError, or %NULL
 *
 * Similar to above e_book_cancel function, only cancels last, still running,
 * asynchronous operation.
 *
 * Returns: %TRUE on success, %FALSE otherwise
 *
 * Since: 2.24
 *
 * Deprecated: 3.2: Use e_client_cancel_all() on an #EBookClient object instead.
 **/
gboolean
e_book_cancel_async_op (EBook *book,
                        GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	e_client_cancel_all (E_CLIENT (book->priv->client));

	return TRUE;
}

/**
 * e_book_open:
 * @book: an #EBook
 * @only_if_exists: if %TRUE, fail if this book doesn't already exist,
 *                  otherwise create it first
 * @error: a #GError to set on failure
 *
 * Opens the addressbook, making it ready for queries and other operations.
 *
 * Returns: %TRUE if the book was successfully opened, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_client_open_sync() on an #EBookClient object instead.
 */
gboolean
e_book_open (EBook *book,
             gboolean only_if_exists,
             GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	return e_client_open_sync (
		E_CLIENT (book->priv->client),
		only_if_exists, NULL, error);
}

static void
open_reply (GObject *source_object,
            GAsyncResult *result,
            gpointer user_data)
{
	AsyncData *data = user_data;
	EBookCallback cb = data->callback;
	EBookAsyncCallback excb = data->excallback;
	GError *error = NULL;

	e_client_open_finish (E_CLIENT (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);
	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);
	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_open:
 * @book: an #EBook
 * @only_if_exists: if %TRUE, fail if this book doesn't already exist,
 *                  otherwise create it first
 * @open_response: (scope call) (closure closure): a function to call when
 *                 the operation finishes
 * @closure: data to pass to callback function
 *
 * Opens the addressbook, making it ready for queries and other operations.
 * This function does not block.
 *
 * Returns: %FALSE if successful, %TRUE otherwise.
 *
 * Deprecated: 3.0: Use e_book_open_async() instead.
 **/
gboolean
e_book_async_open (EBook *book,
                   gboolean only_if_exists,
                   EBookCallback cb,
                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	e_client_open (
		E_CLIENT (book->priv->client),
		only_if_exists, NULL, open_reply, data);

	return TRUE;
}

/**
 * e_book_open_async:
 * @book: an #EBook
 * @only_if_exists: if %TRUE, fail if this book doesn't already exist,
 *                  otherwise create it first
 * @open_response: (scope call): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Opens the addressbook, making it ready for queries and other operations.
 * This function does not block.
 *
 * Returns: %FALSE if successful, %TRUE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_client_open() and e_client_open_finish() on an
 *                  #EBookClient object instead.
 **/
gboolean
e_book_open_async (EBook *book,
                   gboolean only_if_exists,
                   EBookAsyncCallback cb,
                   gpointer closure)
{
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	e_client_open (
		E_CLIENT (book->priv->client),
		only_if_exists, NULL, open_reply, data);

	return TRUE;
}

/**
 * e_book_remove:
 * @book: an #EBook
 * @error: a #GError to set on failure
 *
 * Removes the backing data for this #EBook. For example, with the file backend this
 * deletes the database file. You cannot get it back!
 *
 * Returns: %TRUE on success, %FALSE on failure.
 *
 * Deprecated: 3.2: Use e_client_remove_sync() on an #EBookClient object instead.
 */
gboolean
e_book_remove (EBook *book,
               GError **error)
{
	ESource *source;
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	source = e_book_get_source (book);

	return e_source_remove_sync (source, NULL, error);
}

static void
remove_reply (GObject *source_object,
              GAsyncResult *result,
              gpointer user_data)
{
	AsyncData *data = user_data;
	EBookAsyncCallback excb = data->excallback;
	EBookCallback cb = data->callback;
	GError *error = NULL;

	e_source_remove_finish (E_SOURCE (source_object), result, &error);

	if (cb != NULL && error == NULL)
		cb (data->book, E_BOOK_ERROR_OK, data->closure);

	if (cb != NULL && error != NULL)
		cb (data->book, error->code, data->closure);

	if (excb != NULL)
		excb (data->book, error, data->closure);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (data->book);
	g_slice_free (AsyncData, data);
}

/**
 * e_book_async_remove:
 * @book: an #EBook
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Remove the backing data for this #EBook. For example, with the file backend this
 * deletes the database file. You cannot get it back!
 *
 * Returns: %FALSE if successful, %TRUE otherwise.
 *
 * Deprecated: 3.0: Use e_book_remove_async() instead.
 **/
gboolean
e_book_async_remove (EBook *book,
                     EBookCallback cb,
                     gpointer closure)
{
	ESource *source;
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->callback = cb;
	data->closure = closure;

	source = e_book_get_source (book);

	e_source_remove (source, NULL, remove_reply, data);

	return TRUE;
}

/**
 * e_book_remove_async:
 * @book: an #EBook
 * @cb: (scope async): a function to call when the operation finishes
 * @closure: data to pass to callback function
 *
 * Remove the backing data for this #EBook. For example, with the file
 * backend this deletes the database file. You cannot get it back!
 *
 * Returns: %FALSE if successful, %TRUE otherwise.
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use e_client_remove() and e_client_remove_finish() on an
 *                  #EBookClient object instead.
 **/
gboolean
e_book_remove_async (EBook *book,
                     EBookAsyncCallback cb,
                     gpointer closure)
{
	ESource *source;
	AsyncData *data;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	data = g_slice_new0 (AsyncData);
	data->book = g_object_ref (book);
	data->excallback = cb;
	data->closure = closure;

	source = e_book_get_source (book);

	e_source_remove (source, NULL, remove_reply, data);

	return TRUE;
}

/**
 * e_book_get_source:
 * @book: an #EBook
 *
 * Get the #ESource that this book has loaded.
 *
 * Returns: (transfer none): The source.
 *
 * Deprecated: 3.2: Use e_client_get_source() on an #EBookClient object instead.
 */
ESource *
e_book_get_source (EBook *book)
{
	g_return_val_if_fail (E_IS_BOOK (book), NULL);

	return book->priv->source;
}

/**
 * e_book_get_static_capabilities:
 * @book: an #EBook
 * @error: an #GError to set on failure
 *
 * Get the list of capabilities which the backend for this address book
 * supports. This string should not be freed.
 *
 * Returns: The capabilities list
 *
 * Deprecated: 3.2: Use e_client_get_capabilities() on an #EBookClient object.
 */
const gchar *
e_book_get_static_capabilities (EBook *book,
                                GError **error)
{
	g_return_val_if_fail (E_IS_BOOK (book), NULL);

	if (book->priv->cap == NULL) {
		gboolean success;

		success = e_client_retrieve_capabilities_sync (
			E_CLIENT (book->priv->client),
			&book->priv->cap, NULL, error);

		/* Sanity check. */
		g_return_val_if_fail (
			(success && (book->priv->cap != NULL)) ||
			(!success && (book->priv->cap == NULL)), NULL);
	}

	return book->priv->cap;
}

/**
 * e_book_check_static_capability:
 * @book: an #EBook
 * @cap: A capability string
 *
 * Check to see if the backend for this address book supports the capability
 * @cap.
 *
 * Returns: %TRUE if the backend supports @cap, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_client_check_capability() on an #EBookClient object instead.
 */
gboolean
e_book_check_static_capability (EBook *book,
                                const gchar *cap)
{
	const gchar *caps;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	caps = e_book_get_static_capabilities (book, NULL);

	/* XXX this is an inexact test but it works for our use */
	if (caps && strstr (caps, cap))
		return TRUE;

	return FALSE;
}

/**
 * e_book_is_opened:
 * @book: and #EBook
 *
 * Check if this book has been opened.
 *
 * Returns: %TRUE if this book has been opened, otherwise %FALSE.
 *
 * Deprecated: 3.2: Use e_client_is_opened() on an #EBookClient object instead.
 */
gboolean
e_book_is_opened (EBook *book)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	return e_client_is_opened (E_CLIENT (book->priv->client));
}

/**
 * e_book_is_writable:
 * @book: an #EBook
 *
 * Check if this book is writable.
 *
 * Returns: %TRUE if this book is writable, otherwise %FALSE.
 *
 * Deprecated: 3.2: Use e_client_is_readonly() on an #EBookClient object instead.
 */
gboolean
e_book_is_writable (EBook *book)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	return !e_client_is_readonly (E_CLIENT (book->priv->client));
}

/**
 * e_book_is_online:
 * @book: an #EBook
 *
 * Check if this book is connected.
 *
 * Returns: %TRUE if this book is connected, otherwise %FALSE.
 *
 * Deprecated: 3.2: Use e_client_is_online() on an #EBookClient object instead.
 **/
gboolean
e_book_is_online (EBook *book)
{
	g_return_val_if_fail (E_IS_BOOK (book), FALSE);

	return e_client_is_online (E_CLIENT (book->priv->client));
}

#define SELF_UID_PATH_ID "org.gnome.evolution-data-server.addressbook"
#define SELF_UID_KEY "self-contact-uid"

static EContact *
make_me_card (void)
{
	GString *vcard;
	const gchar *s;
	EContact *contact;

	vcard = g_string_new ("BEGIN:VCARD\nVERSION:3.0\n");

	s = g_get_user_name ();
	if (s)
		g_string_append_printf (vcard, "NICKNAME:%s\n", s);

	s = g_get_real_name ();
	if (s && strcmp (s, "Unknown") != 0) {
		ENameWestern *western;

		g_string_append_printf (vcard, "FN:%s\n", s);

		western = e_name_western_parse (s);
		g_string_append_printf (
			vcard, "N:%s;%s;%s;%s;%s\n",
			western->last ? western->last : "",
			western->first ? western->first : "",
			western->middle ? western->middle : "",
			western->prefix ? western->prefix : "",
			western->suffix ? western->suffix : "");
		e_name_western_free (western);
	}
	g_string_append (vcard, "END:VCARD");

	contact = e_contact_new_from_vcard (vcard->str);

	g_string_free (vcard, TRUE);

	return contact;
}

/**
 * e_book_get_self:
 * @registry: an #ESourceRegistry
 * @contact: (out): an #EContact pointer to set
 * @book: (out): an #EBook pointer to set
 * @error: a #GError to set on failure
 *
 * Get the #EContact referring to the user of the address book
 * and set it in @contact and @book.
 *
 * Returns: %TRUE if successful, otherwise %FALSE.
 *
 * Deprecated: 3.2: Use e_book_client_get_self() instead.
 **/
gboolean
e_book_get_self (ESourceRegistry *registry,
                 EContact **contact,
                 EBook **book,
                 GError **error)
{
	ESource *source;
	GError *e = NULL;
	GSettings *settings;
	gboolean status;
	gchar *uid;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);

	source = e_source_registry_ref_builtin_address_book (registry);
	*book = e_book_new (source, &e);
	g_object_unref (source);

	if (!*book) {
		if (error)
			g_propagate_error (error, e);
		return FALSE;
	}

	status = e_book_open (*book, FALSE, &e);
	if (status == FALSE) {
		g_object_unref (*book);
		*book = NULL;
		if (error)
			g_propagate_error (error, e);
		return FALSE;
	}

	settings = g_settings_new (SELF_UID_PATH_ID);
	uid = g_settings_get_string (settings, SELF_UID_KEY);
	g_object_unref (settings);

	if (uid) {
		gboolean got;

		/* Don't care about errors because we'll create a
		 * new card on failure. */
		got = e_book_get_contact (*book, uid, contact, NULL);
		g_free (uid);
		if (got)
			return TRUE;
	}

	*contact = make_me_card ();
	if (!e_book_add_contact (*book, *contact, &e)) {
		/* TODO: return NULL or the contact anyway? */
		g_object_unref (*book);
		*book = NULL;
		g_object_unref (*contact);
		*contact = NULL;
		if (error)
			g_propagate_error (error, e);
		return FALSE;
	}

	e_book_set_self (*book, *contact, NULL);

	return TRUE;
}

/**
 * e_book_set_self:
 * @book: an #EBook
 * @contact: an #EContact
 * @error: a #GError to set on failure
 *
 * Specify that @contact residing in @book is the #EContact that
 * refers to the user of the address book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_book_client_set_self() instead.
 **/
gboolean
e_book_set_self (EBook *book,
                 EContact *contact,
                 GError **error)
{
	GSettings *settings;

	g_return_val_if_fail (E_IS_BOOK (book), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	settings = g_settings_new (SELF_UID_PATH_ID);
	g_settings_set_string (
		settings, SELF_UID_KEY,
		e_contact_get_const (contact, E_CONTACT_UID));
	g_object_unref (settings);

	return TRUE;
}

/**
 * e_book_is_self:
 * @contact: an #EContact
 *
 * Check if @contact is the user of the address book.
 *
 * Returns: %TRUE if @contact is the user, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_book_client_is_self() instead.
 **/
gboolean
e_book_is_self (EContact *contact)
{
	GSettings *settings;
	gchar *uid;
	gboolean rv;

	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	settings = g_settings_new (SELF_UID_PATH_ID);
	uid = g_settings_get_string (settings, SELF_UID_KEY);
	g_object_unref (settings);

	rv = (uid && !strcmp (uid, e_contact_get_const (contact, E_CONTACT_UID)));

	g_free (uid);

	return rv;
}

/**
 * e_book_new:
 * @source: an #ESource
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EBook corresponding to the given @source.  There are
 * only two operations that are valid on this book at this point:
 * e_book_open(), and e_book_remove().
 *
 * Returns: a new but unopened #EBook.
 *
 * Deprecated: 3.2: Use e_book_client_new() instead.
 */
EBook *
e_book_new (ESource *source,
            GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return g_initable_new (
		E_TYPE_BOOK, NULL, error,
		"source", source, NULL);
}

