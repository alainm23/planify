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

#include "e-book.h"
#include "e-book-view.h"
#include "e-book-view-private.h"
#include "e-book-enumtypes.h"

G_DEFINE_TYPE (EBookView, e_book_view, G_TYPE_OBJECT);

#define E_BOOK_VIEW_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_VIEW, EBookViewPrivate))

struct _EBookViewPrivate {
	EBook *book;
	EBookClientView *client_view;

	gulong objects_added_handler_id;
	gulong objects_modified_handler_id;
	gulong objects_removed_handler_id;
	gulong progress_handler_id;
	gulong complete_handler_id;
};

enum {
	CONTACTS_CHANGED,
	CONTACTS_REMOVED,
	CONTACTS_ADDED,
	SEQUENCE_COMPLETE,
	VIEW_COMPLETE,
	STATUS_MESSAGE,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static void
book_view_objects_added_cb (EBookClientView *client_view,
                            const GSList *slist,
                            EBookView *book_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (book_view, signals[CONTACTS_ADDED], 0, list);

	g_list_free (list);
}

static void
book_view_objects_modified_cb (EBookClientView *client_view,
                               const GSList *slist,
                               EBookView *book_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (book_view, signals[CONTACTS_CHANGED], 0, list);

	g_list_free (list);
}

static void
book_view_objects_removed_cb (EBookClientView *client_view,
                              const GSList *slist,
                              EBookView *book_view)
{
	GList *list = NULL;

	/* XXX Never use GSList in a public API. */
	for (; slist != NULL; slist = g_slist_next (slist))
		list = g_list_prepend (list, slist->data);
	list = g_list_reverse (list);

	g_signal_emit (book_view, signals[CONTACTS_REMOVED], 0, list);

	g_list_free (list);
}

static void
book_view_progress_cb (EBookClientView *client_view,
                       guint percent,
                       const gchar *message,
                       EBookView *book_view)
{
	g_signal_emit (book_view, signals[STATUS_MESSAGE], 0, message);
}

static void
book_view_complete_cb (EBookClientView *client_view,
                       const GError *error,
                       EBookView *book_view)
{
	EBookViewStatus status;
	const gchar *message;

	if (error == NULL) {
		status = E_BOOK_VIEW_STATUS_OK;
	} else switch (error->code) {
		case E_DATA_BOOK_STATUS_SUCCESS:
			status = E_BOOK_VIEW_STATUS_OK;
			break;
		case E_DATA_BOOK_STATUS_SEARCH_TIME_LIMIT_EXCEEDED:
			status = E_BOOK_VIEW_STATUS_TIME_LIMIT_EXCEEDED;
			break;
		case E_DATA_BOOK_STATUS_SEARCH_SIZE_LIMIT_EXCEEDED:
			status = E_BOOK_VIEW_STATUS_SIZE_LIMIT_EXCEEDED;
			break;
		case E_DATA_BOOK_STATUS_INVALID_QUERY:
			status = E_BOOK_VIEW_ERROR_INVALID_QUERY;
			break;
		case E_DATA_BOOK_STATUS_QUERY_REFUSED:
			status = E_BOOK_VIEW_ERROR_QUERY_REFUSED;
			break;
		default:
			status = E_BOOK_VIEW_ERROR_OTHER_ERROR;
			break;
	}

	message = (error != NULL) ? error->message : "";

	g_signal_emit (book_view, signals[SEQUENCE_COMPLETE], 0, status);
	g_signal_emit (book_view, signals[VIEW_COMPLETE], 0, status, message);
}

static void
book_view_dispose (GObject *object)
{
	EBookViewPrivate *priv;

	priv = E_BOOK_VIEW_GET_PRIVATE (object);

	if (priv->book != NULL) {
		g_object_unref (priv->book);
		priv->book = NULL;
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
	G_OBJECT_CLASS (e_book_view_parent_class)->dispose (object);
}

static void
e_book_view_class_init (EBookViewClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBookViewPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = book_view_dispose;

	signals[CONTACTS_CHANGED] = g_signal_new (
		"contacts_changed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, contacts_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, G_TYPE_POINTER);

	signals[CONTACTS_REMOVED] = g_signal_new (
		"contacts_removed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, contacts_removed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, G_TYPE_POINTER);

	signals[CONTACTS_ADDED] = g_signal_new (
		"contacts_added",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, contacts_added),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, G_TYPE_POINTER);

	/* XXX The "sequence-complete" signal is deprecated. */
	signals[SEQUENCE_COMPLETE] = g_signal_new (
		"sequence_complete",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, sequence_complete),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, G_TYPE_UINT);

	signals[VIEW_COMPLETE] = g_signal_new (
		"view_complete",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, view_complete),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2, G_TYPE_UINT, G_TYPE_STRING);

	signals[STATUS_MESSAGE] = g_signal_new (
		"status_message",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookViewClass, status_message),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, G_TYPE_STRING);
}

static void
e_book_view_init (EBookView *book_view)
{
	book_view->priv = E_BOOK_VIEW_GET_PRIVATE (book_view);
}

EBookView *
_e_book_view_new (EBook *book,
                  EBookClientView *client_view)
{
	EBookView *book_view;
	gulong handler_id;

	g_return_val_if_fail (E_IS_BOOK (book), NULL);
	g_return_val_if_fail (E_IS_BOOK_CLIENT_VIEW (client_view), NULL);

	book_view = g_object_new (E_TYPE_BOOK_VIEW, NULL);

	book_view->priv->book = g_object_ref (book);
	book_view->priv->client_view = g_object_ref (client_view);

	handler_id = g_signal_connect (
		client_view, "objects-added",
		G_CALLBACK (book_view_objects_added_cb), book_view);
	book_view->priv->objects_added_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "objects-modified",
		G_CALLBACK (book_view_objects_modified_cb), book_view);
	book_view->priv->objects_modified_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "objects-removed",
		G_CALLBACK (book_view_objects_removed_cb), book_view);
	book_view->priv->objects_removed_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "progress",
		G_CALLBACK (book_view_progress_cb), book_view);
	book_view->priv->progress_handler_id = handler_id;

	handler_id = g_signal_connect (
		client_view, "complete",
		G_CALLBACK (book_view_complete_cb), book_view);
	book_view->priv->complete_handler_id = handler_id;

	return book_view;
}

/**
 * e_book_view_get_book:
 * @book_view: an #EBookView
 *
 * Returns the #EBook that this book view is monitoring.
 *
 * Returns: (transfer none): an #EBook.
 *
 * Since: 2.22
 **/
EBook *
e_book_view_get_book (EBookView *book_view)
{
	g_return_val_if_fail (E_IS_BOOK_VIEW (book_view), NULL);

	return book_view->priv->book;
}

/**
 * e_book_view_start:
 * @book_view: an #EBookView
 *
 * Tells @book_view to start processing events.
 */
void
e_book_view_start (EBookView *book_view)
{
	GError *error = NULL;

	g_return_if_fail (E_IS_BOOK_VIEW (book_view));

	e_book_client_view_start (book_view->priv->client_view, &error);

	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);

		/* Fake a sequence-complete so the
		 * application knows this failed. */
		g_signal_emit (
			book_view, signals[SEQUENCE_COMPLETE], 0,
			E_BOOK_VIEW_ERROR_OTHER_ERROR);
		g_signal_emit (
			book_view, signals[VIEW_COMPLETE], 0,
			E_BOOK_VIEW_ERROR_OTHER_ERROR, error->message);

		g_error_free (error);
	}
}

/**
 * e_book_view_stop:
 * @book_view: an #EBookView
 *
 * Tells @book_view to stop processing events.
 **/
void
e_book_view_stop (EBookView *book_view)
{
	GError *error = NULL;

	g_return_if_fail (E_IS_BOOK_VIEW (book_view));

	e_book_client_view_stop (book_view->priv->client_view, &error);

	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
	}
}

