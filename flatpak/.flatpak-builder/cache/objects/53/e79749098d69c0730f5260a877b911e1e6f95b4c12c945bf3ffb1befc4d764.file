/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Fabiano Fidêncio <fidencio@redhat.com>
 */

/*
 * This class handles and creates #EBackend objects from inside
 * their own subprocesses and also serves as the layer that does
 * the communication between #EDataBookFactory and #EBackend
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "e-book-backend.h"
#include "e-book-backend-factory.h"
#include "e-data-book.h"
#include "e-system-locale-watcher.h"
#include "e-subprocess-book-factory.h"

#include <e-dbus-subprocess-backend.h>

#define E_SUBPROCESS_BOOK_FACTORY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SUBPROCESS_BOOK_FACTORY, ESubprocessBookFactoryPrivate))

struct _ESubprocessBookFactoryPrivate {
	ESystemLocaleWatcher *locale_watcher;
	gulong notify_locale_id;
};

/* Forward Declarations */
static void	e_subprocess_book_factory_initable_init
						(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	ESubprocessBookFactory,
	e_subprocess_book_factory,
	E_TYPE_SUBPROCESS_FACTORY,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_subprocess_book_factory_initable_init))

static gchar *
subprocess_book_factory_open (ESubprocessFactory *subprocess_factory,
			      EBackend *backend,
			      GDBusConnection *connection,
			      gpointer data,
			      GCancellable *cancellable,
			      GError **error)
{
	ESubprocessBookFactory *subprocess_book_factory = E_SUBPROCESS_BOOK_FACTORY (subprocess_factory);
	EDataBook *data_book;
	gchar *object_path;

	/* If the backend already has an EDataBook installed, return its
	 * object path.  Otherwise we need to install a new EDataBook. */
	data_book = e_book_backend_ref_data_book (E_BOOK_BACKEND (backend));

	if (data_book != NULL) {
		object_path = g_strdup (e_data_book_get_object_path (data_book));
	} else {
		object_path = e_subprocess_factory_construct_path ();

		/* The EDataBook will attach itself to EBookBackend,
		 * so no need to call e_book_backend_set_data_book(). */
		data_book = e_data_book_new (
			E_BOOK_BACKEND (backend),
			connection, object_path, error);

		if (data_book != NULL) {
			gchar *locale;

			e_subprocess_factory_set_backend_callbacks (subprocess_factory, backend, data);

			locale = e_system_locale_watcher_dup_locale (subprocess_book_factory->priv->locale_watcher);

			/* Don't set the locale on a new book if we have not
			 * yet received a notification of a locale change
			 */
			if (locale)
				e_data_book_set_locale (data_book, locale, NULL, NULL);

			g_free (locale);
		} else {
			g_free (object_path);
			object_path = NULL;
		}
	}

	g_clear_object (&data_book);

	return object_path;
}

static EBackend *
subprocess_book_factory_ref_backend (ESourceRegistry *registry,
				     ESource *source,
				     const gchar *backend_factory_type_name)
{
	EBookBackendFactoryClass *backend_factory_class;
	GType backend_factory_type;

	backend_factory_type = g_type_from_name (backend_factory_type_name);
	if (!backend_factory_type)
		return NULL;

	backend_factory_class = g_type_class_ref (backend_factory_type);
	if (!backend_factory_class)
		return NULL;

	return g_object_new (
		backend_factory_class->backend_type,
		"registry", registry,
		"source", source, NULL);
}

static void
subprocess_book_factory_notify_locale_cb (GObject *object,
					  GParamSpec *pspec,
					  gpointer user_data)
{
	ESystemLocaleWatcher *watcher = E_SYSTEM_LOCALE_WATCHER (object);
	ESubprocessBookFactory *subprocess_factory = E_SUBPROCESS_BOOK_FACTORY (user_data);
	gchar *locale;

	locale = e_system_locale_watcher_dup_locale (watcher);

	if (locale) {
		GList *backends, *link;
		GError *local_error = NULL;

		backends = e_subprocess_factory_get_backends_list (E_SUBPROCESS_FACTORY (subprocess_factory));

		for (link = backends; link; link = g_list_next (link)) {
			EBackend *backend = link->data;
			EDataBook *data_book;

			data_book = e_book_backend_ref_data_book (E_BOOK_BACKEND (backend));

			if (!e_data_book_set_locale (data_book, locale, NULL, &local_error)) {
				g_warning ("Failed to set locale on addressbook: %s", local_error ? local_error->message : "Unknown error");
				g_clear_error (&local_error);
			}

			g_object_unref (data_book);
		}

		g_list_free_full (backends, g_object_unref);
		g_free (locale);
	}
}

static void
subprocess_book_factory_constructed (GObject *object)
{
	ESubprocessBookFactory *subprocess_factory;

	/* Chain up to parent's method */
	G_OBJECT_CLASS (e_subprocess_book_factory_parent_class)->constructed (object);

	subprocess_factory = E_SUBPROCESS_BOOK_FACTORY (object);
	subprocess_factory->priv->locale_watcher = e_system_locale_watcher_new ();

	subprocess_factory->priv->notify_locale_id = g_signal_connect (
		subprocess_factory->priv->locale_watcher, "notify::locale",
		G_CALLBACK (subprocess_book_factory_notify_locale_cb), subprocess_factory);
}

static void
subprocess_book_factory_dispose (GObject *object)
{
	ESubprocessBookFactory *subprocess_factory = E_SUBPROCESS_BOOK_FACTORY (object);

	if (subprocess_factory->priv->locale_watcher && subprocess_factory->priv->notify_locale_id) {
		g_signal_handler_disconnect (subprocess_factory->priv->locale_watcher, subprocess_factory->priv->notify_locale_id);
		subprocess_factory->priv->notify_locale_id = 0;
	}

	g_clear_object (&subprocess_factory->priv->locale_watcher);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_subprocess_book_factory_parent_class)->dispose (object);
}

static void
e_subprocess_book_factory_class_init (ESubprocessBookFactoryClass *class)
{
	GObjectClass *object_class;
	ESubprocessFactoryClass *subprocess_factory_class;

	g_type_class_add_private (class, sizeof (ESubprocessBookFactoryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = subprocess_book_factory_constructed;
	object_class->dispose = subprocess_book_factory_dispose;

	subprocess_factory_class = E_SUBPROCESS_FACTORY_CLASS (class);
	subprocess_factory_class->ref_backend = subprocess_book_factory_ref_backend;
	subprocess_factory_class->open_data = subprocess_book_factory_open;
}

static void
e_subprocess_book_factory_initable_init (GInitableIface *iface)
{
}

static void
e_subprocess_book_factory_init (ESubprocessBookFactory *subprocess_factory)
{
	subprocess_factory->priv = E_SUBPROCESS_BOOK_FACTORY_GET_PRIVATE (subprocess_factory);
}

ESubprocessBookFactory *
e_subprocess_book_factory_new (GCancellable *cancellable,
			       GError **error)
{
	return g_initable_new (
		E_TYPE_SUBPROCESS_BOOK_FACTORY,
		cancellable, error, NULL);
}
