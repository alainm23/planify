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
 * SECTION: e-data-book-factory
 * @include: libedata-book/libedata-book.h
 * @short_description: The main addressbook server object
 *
 * This class handles incomming D-Bus connections and creates
 * the #EDataBook layer for server side addressbooks to communicate
 * with client side #EBookClient objects.
 **/
#include "evolution-data-server-config.h"

#include <glib/gi18n.h>

/* Private D-Bus classes. */
#include <e-dbus-address-book-factory.h>

#include "e-book-backend.h"
#include "e-book-backend-factory.h"
#include "e-data-book.h"
#include "e-data-book-factory.h"
#include "e-system-locale-watcher.h"

#define d(x)

#define E_DATA_BOOK_FACTORY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DATA_BOOK_FACTORY, EDataBookFactoryPrivate))

struct _EDataBookFactoryPrivate {
	EDBusAddressBookFactory *dbus_factory;

	ESystemLocaleWatcher *locale_watcher;
	gulong notify_locale_id;
};

/* Forward Declarations */
static void	e_data_book_factory_initable_init
						(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EDataBookFactory,
	e_data_book_factory,
	E_TYPE_DATA_FACTORY,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_data_book_factory_initable_init))

static GDBusInterfaceSkeleton *
data_book_factory_get_dbus_interface_skeleton (EDBusServer *server)
{
	EDataBookFactory *factory;

	factory = E_DATA_BOOK_FACTORY (server);

	return G_DBUS_INTERFACE_SKELETON (factory->priv->dbus_factory);
}

static const gchar *
data_book_get_factory_name (EBackendFactory *backend_factory)
{
	EBookBackendFactoryClass *class;

	class = E_BOOK_BACKEND_FACTORY_GET_CLASS (E_BOOK_BACKEND_FACTORY (backend_factory));

	return class->factory_name;
}

static void
data_book_complete_open (EDataFactory *data_factory,
			 GDBusMethodInvocation *invocation,
			 const gchar *object_path,
			 const gchar *bus_name,
			 const gchar *extension_name)
{
	EDataBookFactory *data_book_factory = E_DATA_BOOK_FACTORY (data_factory);

	e_dbus_address_book_factory_complete_open_address_book (
		data_book_factory->priv->dbus_factory, invocation, object_path, bus_name);
}

static gchar *overwrite_subprocess_book_path = NULL;

static gboolean
data_book_factory_handle_open_address_book_cb (EDBusAddressBookFactory *iface,
                                               GDBusMethodInvocation *invocation,
                                               const gchar *uid,
                                               EDataBookFactory *factory)
{
	EDataFactory *data_factory = E_DATA_FACTORY (factory);

	e_data_factory_spawn_subprocess_backend (
		data_factory, invocation, uid, E_SOURCE_EXTENSION_ADDRESS_BOOK,
		overwrite_subprocess_book_path ? overwrite_subprocess_book_path : SUBPROCESS_BOOK_BACKEND_PATH);

	return TRUE;
}

static void
data_book_factory_backend_closed_cb (EBackend *backend,
				     const gchar *sender,
				     EDataFactory *data_factory)
{
	e_data_factory_backend_closed (data_factory, backend);
}

static EBackend *
data_book_factory_create_backend (EDataFactory *data_factory,
				  EBackendFactory *backend_factory,
				  ESource *source)
{
	EBookBackendFactoryClass *backend_factory_class;
	EBackend *backend;

	g_return_val_if_fail (E_IS_DATA_BOOK_FACTORY (data_factory), NULL);
	g_return_val_if_fail (E_IS_BOOK_BACKEND_FACTORY (backend_factory), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	backend_factory_class = E_BOOK_BACKEND_FACTORY_GET_CLASS (backend_factory);
	g_return_val_if_fail (backend_factory_class != NULL, NULL);

	if (g_type_is_a (backend_factory_class->backend_type, G_TYPE_INITABLE)) {
		GError *local_error = NULL;

		backend = g_initable_new (backend_factory_class->backend_type, NULL, &local_error,
			"registry", e_data_factory_get_registry (data_factory),
			"source", source,
			NULL);

		if (!backend)
			g_warning ("%s: Failed to create backend: %s\n", G_STRFUNC, local_error ? local_error->message : "Unknown error");

		g_clear_error (&local_error);
	} else {
		backend = g_object_new (backend_factory_class->backend_type,
			"registry", e_data_factory_get_registry (data_factory),
			"source", source,
			NULL);
	}

	if (backend) {
		g_signal_connect (backend, "closed",
			G_CALLBACK (data_book_factory_backend_closed_cb), data_factory);
	}

	return backend;
}

static gchar *
data_book_factory_open_backend (EDataFactory *data_factory,
				EBackend *backend,
				GDBusConnection *connection,
				GCancellable *cancellable,
				GError **error)
{
	EDataBook *data_book;
	gchar *object_path;

	g_return_val_if_fail (E_IS_DATA_BOOK_FACTORY (data_factory), NULL);
	g_return_val_if_fail (E_IS_BOOK_BACKEND (backend), NULL);
	g_return_val_if_fail (G_IS_DBUS_CONNECTION (connection), NULL);

	/* If the backend already has an EDataBook installed, return its
	 * object path.  Otherwise we need to install a new EDataBook. */
	data_book = e_book_backend_ref_data_book (E_BOOK_BACKEND (backend));

	if (data_book != NULL) {
		object_path = g_strdup (e_data_book_get_object_path (data_book));
	} else {
		object_path = e_subprocess_factory_construct_path ();

		/* The EDataBook will attach itself to EBookBackend,
		 * so no need to call e_book_backend_set_data_book(). */
		data_book = e_data_book_new (E_BOOK_BACKEND (backend), connection, object_path, error);

		if (data_book) {
			EDataBookFactory *data_book_factory = E_DATA_BOOK_FACTORY (data_factory);
			gchar *locale;

			locale = e_system_locale_watcher_dup_locale (data_book_factory->priv->locale_watcher);

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

static void
data_book_factory_notify_locale_cb (GObject *object,
				    GParamSpec *pspec,
				    gpointer user_data)
{
	ESystemLocaleWatcher *watcher = E_SYSTEM_LOCALE_WATCHER (object);
	EDataBookFactory *data_book_factory = E_DATA_BOOK_FACTORY (user_data);
	gchar *locale;

	locale = e_system_locale_watcher_dup_locale (watcher);

	if (locale) {
		GSList *backends, *link;
		GError *local_error = NULL;

		backends = e_data_factory_list_opened_backends (E_DATA_FACTORY (data_book_factory));

		for (link = backends; link; link = g_slist_next (link)) {
			EBackend *backend = link->data;
			EDataBook *data_book;

			data_book = e_book_backend_ref_data_book (E_BOOK_BACKEND (backend));

			if (!e_data_book_set_locale (data_book, locale, NULL, &local_error)) {
				g_warning ("Failed to set locale on addressbook: %s", local_error ? local_error->message : "Unknown error");
				g_clear_error (&local_error);
			}

			g_object_unref (data_book);
		}

		g_slist_free_full (backends, g_object_unref);
		g_free (locale);
	}
}

static void
data_book_factory_constructed (GObject *object)
{
	EDataBookFactory *data_book_factory;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_data_book_factory_parent_class)->constructed (object);

	data_book_factory = E_DATA_BOOK_FACTORY (object);

	/* Listen to locale changes only when the backends run in the factory process,
	   aka when the backend-per-process is disabled */
	if (!e_data_factory_use_backend_per_process (E_DATA_FACTORY (data_book_factory))) {
		data_book_factory->priv->locale_watcher = e_system_locale_watcher_new ();

		data_book_factory->priv->notify_locale_id = g_signal_connect (
			data_book_factory->priv->locale_watcher, "notify::locale",
			G_CALLBACK (data_book_factory_notify_locale_cb), data_book_factory);
	}
}

static void
data_book_factory_dispose (GObject *object)
{
	EDataBookFactory *factory;

	factory = E_DATA_BOOK_FACTORY (object);

	if (factory->priv->locale_watcher && factory->priv->notify_locale_id) {
		g_signal_handler_disconnect (factory->priv->locale_watcher, factory->priv->notify_locale_id);
		factory->priv->notify_locale_id = 0;
	}

	g_clear_object (&factory->priv->dbus_factory);
	g_clear_object (&factory->priv->locale_watcher);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_data_book_factory_parent_class)->dispose (object);
}

static void
e_data_book_factory_class_init (EDataBookFactoryClass *class)
{
	GObjectClass *object_class;
	EDBusServerClass *dbus_server_class;
	EDataFactoryClass *data_factory_class;
	const gchar *modules_directory = BACKENDDIR;
	const gchar *modules_directory_env;
	const gchar *subprocess_book_path_env;

	modules_directory_env = g_getenv (EDS_ADDRESS_BOOK_MODULES);
	if (modules_directory_env &&
	    g_file_test (modules_directory_env, G_FILE_TEST_IS_DIR))
		modules_directory = g_strdup (modules_directory_env);

	subprocess_book_path_env = g_getenv (EDS_SUBPROCESS_BOOK_PATH);
	if (subprocess_book_path_env &&
	    g_file_test (subprocess_book_path_env, G_FILE_TEST_IS_EXECUTABLE))
		overwrite_subprocess_book_path = g_strdup (subprocess_book_path_env);

	g_type_class_add_private (class, sizeof (EDataBookFactoryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = data_book_factory_constructed;
	object_class->dispose = data_book_factory_dispose;

	dbus_server_class = E_DBUS_SERVER_CLASS (class);
	dbus_server_class->bus_name = ADDRESS_BOOK_DBUS_SERVICE_NAME;
	dbus_server_class->module_directory = modules_directory;

	data_factory_class = E_DATA_FACTORY_CLASS (class);
	data_factory_class->backend_factory_type = E_TYPE_BOOK_BACKEND_FACTORY;
	data_factory_class->factory_object_path = "/org/gnome/evolution/dataserver/AddressBookFactory";
	data_factory_class->subprocess_object_path_prefix = "/org/gnome/evolution/dataserver/Subprocess/Backend/AddressBook";
	data_factory_class->subprocess_bus_name_prefix = "org.gnome.evolution.dataserver.Subprocess.Backend.AddressBook";
	data_factory_class->get_dbus_interface_skeleton = data_book_factory_get_dbus_interface_skeleton;
	data_factory_class->get_factory_name = data_book_get_factory_name;
	data_factory_class->complete_open = data_book_complete_open;
	data_factory_class->create_backend = data_book_factory_create_backend;
	data_factory_class->open_backend = data_book_factory_open_backend;
}

static void
e_data_book_factory_initable_init (GInitableIface *iface)
{
}

static void
e_data_book_factory_init (EDataBookFactory *factory)
{
	factory->priv = E_DATA_BOOK_FACTORY_GET_PRIVATE (factory);

	factory->priv->dbus_factory =
		e_dbus_address_book_factory_skeleton_new ();

	g_signal_connect (
		factory->priv->dbus_factory, "handle-open-address-book",
		G_CALLBACK (data_book_factory_handle_open_address_book_cb),
		factory);
}

EDBusServer *
e_data_book_factory_new (gint backend_per_process,
			 GCancellable *cancellable,
                         GError **error)
{
	return g_initable_new (E_TYPE_DATA_BOOK_FACTORY, cancellable, error,
		"reload-supported", TRUE,
		"backend-per-process", backend_per_process,
		NULL);
}
