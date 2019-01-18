/*
 * e-book-client.c
 *
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
 * Copyright (C) 2012 Intel Corporation
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
 */

/**
 * SECTION: e-book-client
 * @include: libebook/libebook.h
 * @short_description: Accessing and modifying an addressbook 
 *
 * This class is the main user facing API for accessing and modifying
 * the addressbook.
 **/

#include "evolution-data-server-config.h"

#include <locale.h>
#include <glib/gi18n-lib.h>
#include <gio/gio.h>

/* Private D-Bus classes. */
#include <e-dbus-address-book.h>
#include <e-dbus-address-book-factory.h>
#include <e-dbus-direct-book.h>

#include <libedataserver/libedataserver.h>
#include <libedataserver/e-client-private.h>

#include <libebackend/libebackend.h>
#include <libedata-book/libedata-book.h>

#include "e-book-client.h"

#define E_BOOK_CLIENT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_CLIENT, EBookClientPrivate))

/* Set this to a sufficiently large value
 * to cover most long-running operations. */
#define DBUS_PROXY_TIMEOUT_MS (3 * 60 * 1000)  /* 3 minutes */

typedef struct _AsyncContext AsyncContext;
typedef struct _SignalClosure SignalClosure;
typedef struct _ConnectClosure ConnectClosure;
typedef struct _RunInThreadClosure RunInThreadClosure;

struct _EBookClientPrivate {
	EDBusAddressBook *dbus_proxy;
	EBookBackend *direct_backend;
	guint name_watcher_id;

	gulong dbus_proxy_error_handler_id;
	gulong dbus_proxy_notify_handler_id;

	gchar *locale;
};

struct _AsyncContext {
	EContact *contact;
	EBookClientView *client_view;
	EBookClientCursor *client_cursor;
	GSList *object_list;
	GSList *string_list;
	EContactField *sort_fields;
	EBookCursorSortType *sort_types;
	guint n_sort_fields;
	gchar *sexp;
	gchar *uid;
	GMainContext *context;
};

struct _SignalClosure {
	GWeakRef client;
	gchar *property_name;
	gchar *property_value;
	gchar *error_message;
};

struct _ConnectClosure {
	ESource *source;
	GCancellable *cancellable;
	guint32 wait_for_connected_seconds;
};

struct _RunInThreadClosure {
	GSimpleAsyncThreadFunc func;
	GSimpleAsyncResult *simple;
	GCancellable *cancellable;
};

/* Forward Declarations */
static void	e_book_client_initable_init
					(GInitableIface *iface);
static void	e_book_client_async_initable_init
					(GAsyncInitableIface *iface);
static void     book_client_set_locale  (EBookClient *client,
					 const gchar *locale);

enum {
	PROP_0,
	PROP_LOCALE
};

G_DEFINE_TYPE_WITH_CODE (
	EBookClient,
	e_book_client,
	E_TYPE_CLIENT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_book_client_initable_init)
	G_IMPLEMENT_INTERFACE (
		G_TYPE_ASYNC_INITABLE,
		e_book_client_async_initable_init))

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->contact != NULL)
		g_object_unref (async_context->contact);

	if (async_context->client_view != NULL)
		g_object_unref (async_context->client_view);

	if (async_context->client_cursor != NULL)
		g_object_unref (async_context->client_cursor);

	if (async_context->context)
		g_main_context_unref (async_context->context);

	g_slist_free_full (
		async_context->object_list,
		(GDestroyNotify) g_object_unref);

	g_slist_free_full (
		async_context->string_list,
		(GDestroyNotify) g_free);

	g_free (async_context->sort_fields);
	g_free (async_context->sort_types);

	g_free (async_context->sexp);
	g_free (async_context->uid);

	g_slice_free (AsyncContext, async_context);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->client);

	g_free (signal_closure->property_name);
	g_free (signal_closure->property_value);
	g_free (signal_closure->error_message);

	g_slice_free (SignalClosure, signal_closure);
}

static void
connect_closure_free (ConnectClosure *connect_closure)
{
	if (connect_closure->source != NULL)
		g_object_unref (connect_closure->source);

	if (connect_closure->cancellable != NULL)
		g_object_unref (connect_closure->cancellable);

	g_slice_free (ConnectClosure, connect_closure);
}

static void
run_in_thread_closure_free (RunInThreadClosure *run_in_thread_closure)
{
	if (run_in_thread_closure->simple != NULL)
		g_object_unref (run_in_thread_closure->simple);

	if (run_in_thread_closure->cancellable != NULL)
		g_object_unref (run_in_thread_closure->cancellable);

	g_slice_free (RunInThreadClosure, run_in_thread_closure);
}

/*
 * Well-known book backend properties:
 * @BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS: Retrieves comma-separated list
 *   of required fields by the backend. Use e_client_util_parse_comma_strings()
 *   to parse returned string value into a #GSList. These fields are required
 *   to be filled in for all contacts.
 * @BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS: Retrieves comma-separated list
 *   of supported fields by the backend. Use e_client_util_parse_comma_strings()
 *   to parse returned string value into a #GSList. These fields can be
 *   stored for contacts.
 *
 * See also: @CLIENT_BACKEND_PROPERTY_OPENED, @CLIENT_BACKEND_PROPERTY_OPENING,
 *   @CLIENT_BACKEND_PROPERTY_ONLINE, @CLIENT_BACKEND_PROPERTY_READONLY
 *   @CLIENT_BACKEND_PROPERTY_CACHE_DIR, @CLIENT_BACKEND_PROPERTY_CAPABILITIES
 */

static EBookBackend *
book_client_load_direct_backend (ESourceRegistry *registry,
                                 ESource *source,
                                 const gchar *backend_path,
                                 const gchar *backend_name,
                                 const gchar *config,
                                 GError **error)
{
	static GHashTable *modules_table = NULL;
	G_LOCK_DEFINE_STATIC (modules_table);

	EModule *module;
	GType factory_type;
	EBookBackend *backend;
	EBookBackendFactoryClass *factory_class;

	g_return_val_if_fail (backend_path != NULL, NULL);
	g_return_val_if_fail (backend_name != NULL, NULL);

	G_LOCK (modules_table);

	if (modules_table == NULL)
		modules_table = g_hash_table_new (
			(GHashFunc) g_str_hash,
			(GEqualFunc) g_str_equal);

	module = g_hash_table_lookup (modules_table, backend_path);

	if (module == NULL) {
		module = e_module_new (backend_path);
		g_hash_table_insert (
			modules_table, g_strdup (backend_path), module);
	}

	G_UNLOCK (modules_table);

	if (!g_type_module_use (G_TYPE_MODULE (module))) {
		g_set_error (
			error, E_CLIENT_ERROR,
			E_CLIENT_ERROR_OTHER_ERROR,
			"Failed to use EModule at path '%s'",
			backend_path);
		return NULL;
	}

	factory_type = g_type_from_name (backend_name);
	if (factory_type == G_TYPE_INVALID) {
		g_set_error (
			error, E_CLIENT_ERROR,
			E_CLIENT_ERROR_OTHER_ERROR,
			"Failed to get backend factory '%s' "
			"from EModule at path '%s'",
			backend_name, backend_path);
		g_type_module_unuse (G_TYPE_MODULE (module));
		return NULL;
	}

	factory_class = g_type_class_ref (factory_type);

	backend = g_object_new (
		factory_class->backend_type,
		"registry", registry,
		"source", source, NULL);

	/* The backend must be configured for direct access
	 * before calling g_initable_init(), since backends
	 * can access their content in initable_init(). */
	e_book_backend_configure_direct (backend, config);

	if (!g_initable_init (G_INITABLE (backend), NULL, error)) {
		g_type_module_unuse (G_TYPE_MODULE (module));
		g_object_unref (backend);
		backend = NULL;
	}

	g_type_class_unref (factory_class);

	/* XXX Until backend methods can be updated, EBookBackend
	 *     still needs an EDataBook to catch "respond" calls. */
	if (backend != NULL) {
		EDataBook *data_book;

		data_book = g_initable_new (
			E_TYPE_DATA_BOOK, NULL, error,
			"backend", backend, NULL);

		if (data_book == NULL) {
			g_type_module_unuse (G_TYPE_MODULE (module));
			g_object_unref (backend);
			backend = NULL;
		}

		g_clear_object (&data_book);

	}

	return backend;
}

static gpointer
book_client_dbus_thread (gpointer user_data)
{
	GMainContext *main_context = user_data;
	GMainLoop *main_loop;

	g_main_context_push_thread_default (main_context);

	main_loop = g_main_loop_new (main_context, FALSE);
	g_main_loop_run (main_loop);
	g_main_loop_unref (main_loop);

	g_main_context_pop_thread_default (main_context);

	g_main_context_unref (main_context);

	return NULL;
}

static gpointer
book_client_dbus_thread_init (gpointer unused)
{
	GMainContext *main_context;

	main_context = g_main_context_new ();

	/* This thread terminates when the process itself terminates, so
	 * no need to worry about unreferencing the returned GThread. */
	g_thread_new (
		"book-client-dbus-thread",
		book_client_dbus_thread,
		g_main_context_ref (main_context));

	return main_context;
}

static GMainContext *
book_client_ref_dbus_main_context (void)
{
	static GOnce book_client_dbus_thread_once = G_ONCE_INIT;

	g_once (
		&book_client_dbus_thread_once,
		book_client_dbus_thread_init, NULL);

	return g_main_context_ref (book_client_dbus_thread_once.retval);
}

static gboolean
book_client_run_in_dbus_thread_idle_cb (gpointer user_data)
{
	RunInThreadClosure *closure = user_data;
	GObject *source_object;
	GAsyncResult *result;

	result = G_ASYNC_RESULT (closure->simple);
	source_object = g_async_result_get_source_object (result);

	closure->func (
		closure->simple,
		source_object,
		closure->cancellable);

	if (source_object != NULL)
		g_object_unref (source_object);

	g_simple_async_result_complete_in_idle (closure->simple);

	return FALSE;
}

static void
book_client_run_in_dbus_thread (GSimpleAsyncResult *simple,
                                GSimpleAsyncThreadFunc func,
                                gint io_priority,
                                GCancellable *cancellable)
{
	RunInThreadClosure *closure;
	GMainContext *main_context;
	GSource *idle_source;

	main_context = book_client_ref_dbus_main_context ();

	closure = g_slice_new0 (RunInThreadClosure);
	closure->func = func;
	closure->simple = g_object_ref (simple);

	if (G_IS_CANCELLABLE (cancellable))
		closure->cancellable = g_object_ref (cancellable);

	idle_source = g_idle_source_new ();
	g_source_set_priority (idle_source, io_priority);
	g_source_set_callback (
		idle_source, book_client_run_in_dbus_thread_idle_cb,
		closure, (GDestroyNotify) run_in_thread_closure_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static gboolean
book_client_emit_backend_died_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		g_signal_emit_by_name (client, "backend-died");
		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
book_client_emit_backend_error_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		g_signal_emit_by_name (
			client, "backend-error",
			signal_closure->error_message);
		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
book_client_emit_backend_property_changed_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		gchar *prop_value = NULL;

		/* Notify that the "locale" property has changed in the calling thread 
		 */
		if (g_str_equal (signal_closure->property_name, "locale")) {
			EBookClient *book_client = E_BOOK_CLIENT (client);

			book_client_set_locale (book_client, signal_closure->property_value);

		} else {

			/* XXX Despite appearances, this function does not block. */
			e_client_get_backend_property_sync (
				client,
				signal_closure->property_name,
				&prop_value, NULL, NULL);

			if (prop_value != NULL) {
				g_signal_emit_by_name (
					client,
					"backend-property-changed",
					signal_closure->property_name,
					prop_value);
				g_free (prop_value);
			}
		}

		g_object_unref (client);
	}

	return FALSE;
}

static void
book_client_dbus_proxy_error_cb (EDBusAddressBook *dbus_proxy,
                                 const gchar *error_message,
                                 GWeakRef *client_weak_ref)
{
	EClient *client;

	client = g_weak_ref_get (client_weak_ref);

	if (client != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);
		signal_closure->error_message = g_strdup (error_message);

		main_context = e_client_ref_main_context (client);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			book_client_emit_backend_error_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client);
	}
}

static void
book_client_dbus_proxy_property_changed (EClient *client,
					 const gchar *property_name,
					 const GValue *value,
					 gboolean is_in_main_thread)
{
	const gchar *backend_prop_name = NULL;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (property_name != NULL);

	if (g_str_equal (property_name, "cache-dir")) {
		backend_prop_name = CLIENT_BACKEND_PROPERTY_CACHE_DIR;
	}

	if (g_str_equal (property_name, "capabilities")) {
		gchar **strv;
		gchar *csv = NULL;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_CAPABILITIES;

		strv = g_value_get_boxed (value);
		if (strv != NULL) {
			csv = g_strjoinv (",", strv);
		}
		e_client_set_capabilities (client, csv);
		g_free (csv);
	}

	if (g_str_equal (property_name, "online")) {
		gboolean online;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_ONLINE;

		online = g_value_get_boolean (value);
		e_client_set_online (client, online);
	}

	if (g_str_equal (property_name, "required-fields")) {
		backend_prop_name = BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS;
	}

	if (g_str_equal (property_name, "revision")) {
		backend_prop_name = CLIENT_BACKEND_PROPERTY_REVISION;
	}

	if (g_str_equal (property_name, "supported-fields")) {
		backend_prop_name = BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS;
	}

	if (g_str_equal (property_name, "writable")) {
		gboolean writable;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_READONLY;

		writable = g_value_get_boolean (value);
		e_client_set_readonly (client, !writable);
	}

	if (g_str_equal (property_name, "locale")) {
		backend_prop_name = "locale";
	}

	if (backend_prop_name != NULL) {
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);
		signal_closure->property_name = g_strdup (backend_prop_name);

		/* The 'locale' is not an EClient property, so just transport
		 * the value directly on the SignalClosure
		 */
		if (g_str_equal (backend_prop_name, "locale"))
			signal_closure->property_value = g_value_dup_string (value);

		if (is_in_main_thread) {
			book_client_emit_backend_property_changed_idle_cb (signal_closure);
			signal_closure_free (signal_closure);
		} else {
			GSource *idle_source;
			GMainContext *main_context;

			main_context = e_client_ref_main_context (client);

			idle_source = g_idle_source_new ();
			g_source_set_callback (
				idle_source,
				book_client_emit_backend_property_changed_idle_cb,
				signal_closure,
				(GDestroyNotify) signal_closure_free);
			g_source_attach (idle_source, main_context);
			g_source_unref (idle_source);

			g_main_context_unref (main_context);
		}
	}
}

typedef struct {
	EClient *client;
	gchar *property_name;
	GValue property_value;
} IdleProxyNotifyData;

static void
idle_proxy_notify_data_free (gpointer ptr)
{
	IdleProxyNotifyData *ipn = ptr;

	if (ipn) {
		g_clear_object (&ipn->client);
		g_free (ipn->property_name);
		g_value_unset (&ipn->property_value);
		g_free (ipn);
	}
}

static gboolean
book_client_proxy_notify_idle_cb (gpointer user_data)
{
	IdleProxyNotifyData *ipn = user_data;

	g_return_val_if_fail (ipn != NULL, FALSE);

	book_client_dbus_proxy_property_changed (ipn->client, ipn->property_name, &ipn->property_value, TRUE);

	return FALSE;
}

static void
book_client_dbus_proxy_notify_cb (EDBusAddressBook *dbus_proxy,
                                  GParamSpec *pspec,
                                  GWeakRef *client_weak_ref)
{
	EClient *client;
	GSource *idle_source;
	GMainContext *main_context;
	IdleProxyNotifyData *ipn;

	client = g_weak_ref_get (client_weak_ref);
	if (client == NULL)
		return;

	ipn = g_new0 (IdleProxyNotifyData, 1);
	ipn->client = g_object_ref (client);
	ipn->property_name = g_strdup (pspec->name);
	g_value_init (&ipn->property_value, pspec->value_type);
	g_object_get_property (G_OBJECT (dbus_proxy), pspec->name, &ipn->property_value);

	main_context = e_client_ref_main_context (client);

	idle_source = g_idle_source_new ();
	g_source_set_callback (idle_source, book_client_proxy_notify_idle_cb,
		ipn, idle_proxy_notify_data_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
	g_object_unref (client);
}

static void
book_client_name_vanished_cb (GDBusConnection *connection,
                              const gchar *name,
                              GWeakRef *client_weak_ref)
{
	EClient *client;

	client = g_weak_ref_get (client_weak_ref);

	if (client != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);

		main_context = e_client_ref_main_context (client);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			book_client_emit_backend_died_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client);
	}
}

static void
book_client_dispose (GObject *object)
{
	EBookClientPrivate *priv;

	priv = E_BOOK_CLIENT_GET_PRIVATE (object);

	if (priv->dbus_proxy_error_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->dbus_proxy_error_handler_id);
		priv->dbus_proxy_error_handler_id = 0;
	}

	if (priv->dbus_proxy_notify_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->dbus_proxy_notify_handler_id);
		priv->dbus_proxy_notify_handler_id = 0;
	}

	if (priv->dbus_proxy != NULL) {
		/* Call close() asynchronously so we don't block dispose().
		 * Also omit a callback function, so the GDBusMessage uses
		 * G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED. */
		e_dbus_address_book_call_close (
			priv->dbus_proxy, NULL, NULL, NULL);
		g_object_unref (priv->dbus_proxy);
		priv->dbus_proxy = NULL;
	}

	if (priv->direct_backend != NULL) {
		g_object_unref (priv->direct_backend);
		priv->direct_backend = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_book_client_parent_class)->dispose (object);
}

static void
book_client_finalize (GObject *object)
{
	EBookClientPrivate *priv;

	priv = E_BOOK_CLIENT_GET_PRIVATE (object);

	if (priv->name_watcher_id > 0)
		g_bus_unwatch_name (priv->name_watcher_id);

	g_free (priv->locale);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_client_parent_class)->finalize (object);
}

static void
book_client_process_properties (EBookClient *book_client,
				gchar * const *properties)
{
	GObject *dbus_proxy;
	GObjectClass *object_class;
	gint ii;

	g_return_if_fail (E_IS_BOOK_CLIENT (book_client));

	dbus_proxy = G_OBJECT (book_client->priv->dbus_proxy);
	g_return_if_fail (G_IS_OBJECT (dbus_proxy));

	if (!properties)
		return;

	object_class = G_OBJECT_GET_CLASS (dbus_proxy);

	for (ii = 0; properties[ii]; ii++) {
		if (!(ii & 1) && properties[ii + 1]) {
			GParamSpec *param;
			GVariant *expected = NULL;

			param = g_object_class_find_property (object_class, properties[ii]);
			if (param) {
				#define WORKOUT(gvl, gvr) \
					if (g_type_is_a (param->value_type, G_TYPE_ ## gvl)) { \
						expected = g_variant_parse (G_VARIANT_TYPE_ ## gvr, properties[ii + 1], NULL, NULL, NULL); \
					}

				WORKOUT (BOOLEAN, BOOLEAN);
				WORKOUT (STRING, STRING);
				WORKOUT (STRV, STRING_ARRAY);
				WORKOUT (UCHAR, BYTE);
				WORKOUT (INT, INT32);
				WORKOUT (UINT, UINT32);
				WORKOUT (INT64, INT64);
				WORKOUT (UINT64, UINT64);
				WORKOUT (DOUBLE, DOUBLE);

				#undef WORKOUT
			}

			/* Update the property always, even when the current value on the GDBusProxy
			   matches the expected value, because sometimes the proxy can have up-to-date
			   values, but still not propagated into EClient properties. */
			if (expected) {
				GValue value = G_VALUE_INIT;

				g_dbus_gvariant_to_gvalue (expected, &value);

				book_client_dbus_proxy_property_changed (E_CLIENT (book_client), param->name, &value, FALSE);

				g_value_unset (&value);
				g_variant_unref (expected);
			}
		}
	}
}

static GDBusProxy *
book_client_get_dbus_proxy (EClient *client)
{
	EBookClientPrivate *priv;

	priv = E_BOOK_CLIENT_GET_PRIVATE (client);

	return G_DBUS_PROXY (priv->dbus_proxy);
}

static gboolean
book_client_get_backend_property_sync (EClient *client,
                                       const gchar *prop_name,
                                       gchar **prop_value,
                                       GCancellable *cancellable,
                                       GError **error)
{
	EBookClient *book_client;
	EDBusAddressBook *dbus_proxy;
	gchar **strv;

	book_client = E_BOOK_CLIENT (client);
	dbus_proxy = book_client->priv->dbus_proxy;

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENED)) {
		*prop_value = g_strdup ("TRUE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENING)) {
		*prop_value = g_strdup ("FALSE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_ONLINE)) {
		if (e_dbus_address_book_get_online (dbus_proxy))
			*prop_value = g_strdup ("TRUE");
		else
			*prop_value = g_strdup ("FALSE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_READONLY)) {
		if (e_dbus_address_book_get_writable (dbus_proxy))
			*prop_value = g_strdup ("FALSE");
		else
			*prop_value = g_strdup ("TRUE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CACHE_DIR)) {
		*prop_value = e_dbus_address_book_dup_cache_dir (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_REVISION)) {
		*prop_value = e_dbus_address_book_dup_revision (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		strv = e_dbus_address_book_dup_capabilities (dbus_proxy);
		if (strv != NULL)
			*prop_value = g_strjoinv (",", strv);
		else
			*prop_value = g_strdup ("");
		g_strfreev (strv);
		return TRUE;
	}

	if (g_str_equal (prop_name, BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS)) {
		strv = e_dbus_address_book_dup_required_fields (dbus_proxy);
		if (strv != NULL)
			*prop_value = g_strjoinv (",", strv);
		else
			*prop_value = g_strdup ("");
		g_strfreev (strv);
		return TRUE;
	}

	if (g_str_equal (prop_name, BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS)) {
		strv = e_dbus_address_book_dup_supported_fields (dbus_proxy);
		if (strv != NULL)
			*prop_value = g_strjoinv (",", strv);
		else
			*prop_value = g_strdup ("");
		g_strfreev (strv);
		return TRUE;
	}

	g_set_error (
		error, E_CLIENT_ERROR, E_CLIENT_ERROR_NOT_SUPPORTED,
		_("Unknown book property “%s”"), prop_name);

	return TRUE;
}

static gboolean
book_client_set_backend_property_sync (EClient *client,
                                       const gchar *prop_name,
                                       const gchar *prop_value,
                                       GCancellable *cancellable,
                                       GError **error)
{
	g_set_error (
		error, E_CLIENT_ERROR,
		E_CLIENT_ERROR_NOT_SUPPORTED,
		_("Cannot change value of book property “%s”"),
		prop_name);

	return FALSE;
}

static gboolean
book_client_open_sync (EClient *client,
                       gboolean only_if_exists,
                       GCancellable *cancellable,
                       GError **error)
{
	EBookClient *book_client;
	gchar **properties = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);

	book_client = E_BOOK_CLIENT (client);

	e_dbus_address_book_call_open_sync (
		book_client->priv->dbus_proxy, &properties, cancellable, &local_error);

	book_client_process_properties (book_client, properties);
	g_strfreev (properties);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
book_client_refresh_sync (EClient *client,
                          GCancellable *cancellable,
                          GError **error)
{
	EBookClient *book_client;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);

	book_client = E_BOOK_CLIENT (client);

	e_dbus_address_book_call_refresh_sync (
		book_client->priv->dbus_proxy, cancellable, &local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
book_client_retrieve_properties_sync (EClient *client,
				      GCancellable *cancellable,
				      GError **error)
{
	EBookClient *book_client;
	gchar **properties = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);

	book_client = E_BOOK_CLIENT (client);

	e_dbus_address_book_call_retrieve_properties_sync (
		book_client->priv->dbus_proxy, &properties, cancellable, &local_error);

	book_client_process_properties (book_client, properties);
	g_strfreev (properties);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
book_client_init_in_dbus_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	EBookClientPrivate *priv;
	EDBusAddressBookFactory *factory_proxy;
	GDBusConnection *connection;
	GDBusProxy *proxy;
	EClient *client;
	ESource *source;
	const gchar *uid;
	gchar *object_path = NULL;
	gchar *bus_name = NULL;
	gulong handler_id;
	GError *local_error = NULL;

	priv = E_BOOK_CLIENT_GET_PRIVATE (source_object);

	client = E_CLIENT (source_object);
	source = e_client_get_source (client);
	uid = e_source_get_uid (source);

	connection = g_bus_get_sync (
		G_BUS_TYPE_SESSION, cancellable, &local_error);

	/* Sanity check. */
	g_return_if_fail (
		((connection != NULL) && (local_error == NULL)) ||
		((connection == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		return;
	}

	factory_proxy = e_dbus_address_book_factory_proxy_new_sync (
		connection,
		G_DBUS_PROXY_FLAGS_NONE,
		ADDRESS_BOOK_DBUS_SERVICE_NAME,
		"/org/gnome/evolution/dataserver/AddressBookFactory",
		cancellable, &local_error);

	/* Sanity check. */
	g_return_if_fail (
		((factory_proxy != NULL) && (local_error == NULL)) ||
		((factory_proxy == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	e_dbus_address_book_factory_call_open_address_book_sync (
		factory_proxy, uid, &object_path, &bus_name, cancellable, &local_error);

	g_object_unref (factory_proxy);

	/* Sanity check. */
	g_return_if_fail (
		(((object_path != NULL) || (bus_name != NULL)) && (local_error == NULL)) ||
		(((object_path == NULL) || (bus_name == NULL)) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	e_client_set_bus_name (client, bus_name);

	priv->dbus_proxy = e_dbus_address_book_proxy_new_sync (
		connection,
		G_DBUS_PROXY_FLAGS_DO_NOT_AUTO_START,
		bus_name, object_path, cancellable, &local_error);

	g_free (object_path);
	g_free (bus_name);

	/* Sanity check. */
	g_return_if_fail (
		((priv->dbus_proxy != NULL) && (local_error == NULL)) ||
		((priv->dbus_proxy == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	/* Configure our new GDBusProxy. */

	proxy = G_DBUS_PROXY (priv->dbus_proxy);

	g_dbus_proxy_set_default_timeout (proxy, DBUS_PROXY_TIMEOUT_MS);

	priv->name_watcher_id = g_bus_watch_name_on_connection (
		connection,
		g_dbus_proxy_get_name (proxy),
		G_BUS_NAME_WATCHER_FLAGS_NONE,
		(GBusNameAppearedCallback) NULL,
		(GBusNameVanishedCallback) book_client_name_vanished_cb,
		e_weak_ref_new (client),
		(GDestroyNotify) e_weak_ref_free);

	handler_id = g_signal_connect_data (
		proxy, "error",
		G_CALLBACK (book_client_dbus_proxy_error_cb),
		e_weak_ref_new (client),
		(GClosureNotify) e_weak_ref_free,
		0);
	priv->dbus_proxy_error_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		proxy, "notify",
		G_CALLBACK (book_client_dbus_proxy_notify_cb),
		e_weak_ref_new (client),
		(GClosureNotify) e_weak_ref_free,
		0);
	priv->dbus_proxy_notify_handler_id = handler_id;

	/* Initialize our public-facing GObject properties. */
	g_object_notify (G_OBJECT (proxy), "online");
	g_object_notify (G_OBJECT (proxy), "writable");
	g_object_notify (G_OBJECT (proxy), "capabilities");

	book_client_set_locale (
		E_BOOK_CLIENT (client),
		e_dbus_address_book_get_locale (priv->dbus_proxy));

	g_object_unref (connection);
}

static gboolean
book_client_initable_init (GInitable *initable,
                           GCancellable *cancellable,
                           GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	g_async_initable_init_async (
		G_ASYNC_INITABLE (initable),
		G_PRIORITY_DEFAULT, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = g_async_initable_init_finish (
		G_ASYNC_INITABLE (initable), result, error);

	e_async_closure_free (closure);

	return success;
}

static void
book_client_initable_init_async (GAsyncInitable *initable,
                                 gint io_priority,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (initable), callback, user_data,
		book_client_initable_init_async);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	book_client_run_in_dbus_thread (
		simple, book_client_init_in_dbus_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

static gboolean
book_client_initable_init_finish (GAsyncInitable *initable,
                                  GAsyncResult *result,
                                  GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (initable),
		book_client_initable_init_async), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static void
book_client_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	EBookClient *book_client;

	book_client = E_BOOK_CLIENT (object);

	switch (property_id) {
		case PROP_LOCALE:
			g_value_set_string (
				value,
				book_client->priv->locale);
			return;

	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_book_client_class_init (EBookClientClass *class)
{
	GObjectClass *object_class;
	EClientClass *client_class;

	g_type_class_add_private (class, sizeof (EBookClientPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = book_client_dispose;
	object_class->finalize = book_client_finalize;
	object_class->get_property = book_client_get_property;

	client_class = E_CLIENT_CLASS (class);
	client_class->get_dbus_proxy = book_client_get_dbus_proxy;
	client_class->get_backend_property_sync = book_client_get_backend_property_sync;
	client_class->set_backend_property_sync = book_client_set_backend_property_sync;
	client_class->open_sync = book_client_open_sync;
	client_class->refresh_sync = book_client_refresh_sync;
	client_class->retrieve_properties_sync = book_client_retrieve_properties_sync;

	/**
	 * EBookClient:locale:
	 *
	 * The currently active locale for this addressbook.
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_LOCALE,
		g_param_spec_string (
			"locale",
			"Locale",
			"The currently active locale for this addressbook",
			NULL,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));
}

static void
e_book_client_initable_init (GInitableIface *iface)
{
	iface->init = book_client_initable_init;
}

static void
e_book_client_async_initable_init (GAsyncInitableIface *iface)
{
	iface->init_async = book_client_initable_init_async;
	iface->init_finish = book_client_initable_init_finish;
}

static void
e_book_client_init (EBookClient *client)
{
	const gchar *default_locale;

	client->priv = E_BOOK_CLIENT_GET_PRIVATE (client);

	default_locale = setlocale (LC_COLLATE, NULL);
	client->priv->locale = g_strdup (default_locale);
}

/**
 * e_book_client_connect_sync:
 * @source: an #ESource
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EBookClient for @source.  If an error occurs, the function
 * will set @error and return %FALSE.
 *
 * Unlike with e_book_client_new(), there is no need to call
 * e_client_open_sync() after obtaining the #EBookClient.
 *
 * The @wait_for_connected_seconds argument had been added since 3.16,
 * to let the caller decide how long to wait for the backend to fully
 * connect to its (possibly remote) data store. This is required due
 * to a change in the authentication process, which is fully asynchronous
 * and done on the client side, while not every client is supposed to
 * response to authentication requests. In case the backend will not connect
 * within the set interval, then it is opened in an offline mode. A special
 * value -1 can be used to not wait for the connected state at all.
 *
 * For error handling convenience, any error message returned by this
 * function will have a descriptive prefix that includes the display
 * name of @source.
 *
 * Returns: (transfer full) (type EBookClient): a new #EBookClient, or %NULL
 *
 * Since: 3.8
 **/
EClient *
e_book_client_connect_sync (ESource *source,
			    guint32 wait_for_connected_seconds,
                            GCancellable *cancellable,
                            GError **error)
{
	EBookClient *client;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	client = g_object_new (
		E_TYPE_BOOK_CLIENT,
		"source", source, NULL);

	g_initable_init (G_INITABLE (client), cancellable, &local_error);

	if (local_error == NULL) {
		gchar **properties = NULL;

		e_dbus_address_book_call_open_sync (
			client->priv->dbus_proxy, &properties, cancellable, &local_error);

		book_client_process_properties (client, properties);
		g_strfreev (properties);
	}

	if (!local_error && wait_for_connected_seconds != (guint32) -1) {
		/* These errors are ignored, the book is left opened in an offline mode. */
		e_client_wait_for_connected_sync (E_CLIENT (client),
			wait_for_connected_seconds, cancellable, NULL);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		g_prefix_error (
			error, _("Unable to connect to “%s”: "),
			e_source_get_display_name (source));
		g_object_unref (client);
		return NULL;
	}

	return E_CLIENT (client);
}

static void
book_client_connect_wait_for_connected_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	/* These errors are ignored, the book is left opened in an offline mode. */
	e_client_wait_for_connected_finish (E_CLIENT (source_object), result, NULL);

	g_simple_async_result_complete (simple);

	g_object_unref (simple);
}

/* Helper for e_book_client_connect() */
static void
book_client_connect_open_cb (GObject *source_object,
                             GAsyncResult *result,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	gchar **properties = NULL;
	GObject *client_object;
	GError *local_error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	e_dbus_address_book_call_open_finish (
		E_DBUS_ADDRESS_BOOK (source_object), &properties, result, &local_error);

	client_object = g_async_result_get_source_object (G_ASYNC_RESULT (simple));
	if (client_object) {
		book_client_process_properties (E_BOOK_CLIENT (client_object), properties);

		if (!local_error) {
			ConnectClosure *closure;

			closure = g_simple_async_result_get_op_res_gpointer (simple);
			if (closure->wait_for_connected_seconds != (guint32) -1) {
				e_client_wait_for_connected (E_CLIENT (client_object),
					closure->wait_for_connected_seconds,
					closure->cancellable,
					book_client_connect_wait_for_connected_cb, g_object_ref (simple));

				g_clear_object (&client_object);
				g_object_unref (simple);
				g_strfreev (properties);
				return;
			}
		}

		g_clear_object (&client_object);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
	}

	g_simple_async_result_complete (simple);

	g_object_unref (simple);
	g_strfreev (properties);
}

/* Helper for e_book_client_connect() */
static void
book_client_connect_init_cb (GObject *source_object,
                             GAsyncResult *result,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	EBookClientPrivate *priv;
	ConnectClosure *closure;
	GError *local_error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	g_async_initable_init_finish (
		G_ASYNC_INITABLE (source_object), result, &local_error);

	if (local_error != NULL) {
		g_simple_async_result_take_error (simple, local_error);
		g_simple_async_result_complete (simple);
		goto exit;
	}

	/* Note, we're repurposing some function parameters. */

	result = G_ASYNC_RESULT (simple);
	source_object = g_async_result_get_source_object (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	priv = E_BOOK_CLIENT_GET_PRIVATE (source_object);

	e_dbus_address_book_call_open (
		priv->dbus_proxy,
		closure->cancellable,
		book_client_connect_open_cb,
		g_object_ref (simple));

	g_object_unref (source_object);

exit:
	g_object_unref (simple);
}

/**
 * e_book_client_connect:
 * @source: an #ESource
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously creates a new #EBookClient for @source.
 *
 * The @wait_for_connected_seconds argument had been added since 3.16,
 * to let the caller decide how long to wait for the backend to fully
 * connect to its (possibly remote) data store. This is required due
 * to a change in the authentication process, which is fully asynchronous
 * and done on the client side, while not every client is supposed to
 * response to authentication requests. In case the backend will not connect
 * within the set interval, then it is opened in an offline mode. A special
 * value -1 can be used to not wait for the connected state at all.
 *
 * Unlike with e_book_client_new(), there is no need to call e_client_open()
 * after obtaining the #EBookClient.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_book_client_connect_finish() to get the result of the operation.
 *
 * Since: 3.8
 **/
void
e_book_client_connect (ESource *source,
		       guint32 wait_for_connected_seconds,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	EBookClient *client;

	g_return_if_fail (E_IS_SOURCE (source));

	/* Two things with this: 1) instantiate the client object
	 * immediately to make sure the thread-default GMainContext
	 * gets plucked, and 2) do not call the D-Bus open() method
	 * from our designated D-Bus thread -- it may take a long
	 * time and block other clients from receiving signals. */

	closure = g_slice_new0 (ConnectClosure);
	closure->source = g_object_ref (source);
	closure->wait_for_connected_seconds = wait_for_connected_seconds;

	if (G_IS_CANCELLABLE (cancellable))
		closure->cancellable = g_object_ref (cancellable);

	client = g_object_new (
		E_TYPE_BOOK_CLIENT,
		"source", source, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, e_book_client_connect);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, closure, (GDestroyNotify) connect_closure_free);

	g_async_initable_init_async (
		G_ASYNC_INITABLE (client),
		G_PRIORITY_DEFAULT, cancellable,
		book_client_connect_init_cb,
		g_object_ref (simple));

	g_object_unref (simple);
	g_object_unref (client);
}

/**
 * e_book_client_connect_finish:
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_book_client_connect().  If an
 * error occurs in connecting to the D-Bus service, the function sets
 * @error and returns %NULL.
 *
 * For error handling convenience, any error message returned by this
 * function will have a descriptive prefix that includes the display
 * name of the #ESource passed to e_book_client_connect().
 *
 * Returns: (transfer full) (type EBookClient): a new #EBookClient, or %NULL
 *
 * Since: 3.8
 **/
EClient *
e_book_client_connect_finish (GAsyncResult *result,
                              GError **error)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	gpointer source_tag;

	g_return_val_if_fail (G_IS_SIMPLE_ASYNC_RESULT (result), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	source_tag = g_simple_async_result_get_source_tag (simple);
	g_return_val_if_fail (source_tag == e_book_client_connect, NULL);

	if (g_simple_async_result_propagate_error (simple, error)) {
		g_prefix_error (
			error, _("Unable to connect to “%s”: "),
			e_source_get_display_name (closure->source));
		return NULL;
	}

	return E_CLIENT (g_async_result_get_source_object (result));
}

/**
 * e_book_client_new:
 * @source: An #ESource pointer
 * @error: A #GError pointer
 *
 * Creates a new #EBookClient corresponding to the given source.  There are
 * only two operations that are valid on this book at this point:
 * e_client_open(), and e_client_remove().
 *
 * Returns: a new but unopened #EBookClient.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: It covertly makes synchronous D-Bus calls, with no
 *                  way to cancel.  Use e_book_client_connect() instead,
 *                  which combines e_book_client_new() and e_client_open()
 *                  into one step.
 **/
EBookClient *
e_book_client_new (ESource *source,
                   GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return g_initable_new (
		E_TYPE_BOOK_CLIENT, NULL, error,
		"source", source, NULL);
}

/* Direct Read Access connect helper */
static void
connect_direct (EBookClient *client,
                GCancellable *cancellable,
                ESourceRegistry *registry)
{
	EBookClientPrivate *priv;
	EDBusDirectBook *direct_config;
	const gchar *backend_name, *backend_path, *config;
	gchar *bus_name;

	priv = E_BOOK_CLIENT_GET_PRIVATE (client);

	if (registry)
		g_object_ref (registry);
	else {
		registry = e_source_registry_new_sync (cancellable, NULL);

		if (!registry)
			return;
	}

	bus_name = e_client_dup_bus_name (E_CLIENT (client));

	direct_config = e_dbus_direct_book_proxy_new_sync (
		g_dbus_proxy_get_connection (G_DBUS_PROXY (priv->dbus_proxy)),
		G_DBUS_PROXY_FLAGS_NONE,
		bus_name,
		g_dbus_proxy_get_object_path (G_DBUS_PROXY (priv->dbus_proxy)),
		NULL, NULL);

	g_free (bus_name);

	backend_path = e_dbus_direct_book_get_backend_path (direct_config);
	backend_name = e_dbus_direct_book_get_backend_name (direct_config);
	config = e_dbus_direct_book_get_backend_config (direct_config);

	if (backend_path != NULL && *backend_path != '\0' &&
	    backend_name != NULL && *backend_name != '\0') {
		priv->direct_backend = book_client_load_direct_backend (
			registry, e_client_get_source (E_CLIENT (client)),
			backend_path,
			backend_name,
			config, NULL);

	}

	g_object_unref (direct_config);
	g_object_unref (registry);

	/* We have to perform the opening of the direct backend separately
	 * from the EClient->open() implementation, because the direct
	 * backend does not exist yet. */
	if (priv->direct_backend != NULL &&
	    !e_book_backend_open_sync (priv->direct_backend,
				       cancellable,
				       NULL))
		g_clear_object (&priv->direct_backend);
}

/**
 * e_book_client_connect_direct_sync:
 * @registry: an #ESourceRegistry
 * @source: an #ESource
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Like e_book_client_connect_sync(), except creates the book client for
 * direct read access to the underlying addressbook.
 *
 * Returns: (transfer full) (type EBookClient): a new but unopened #EBookClient.
 *
 * Since: 3.8
 **/
EClient *
e_book_client_connect_direct_sync (ESourceRegistry *registry,
                                   ESource *source,
				   guint32 wait_for_connected_seconds,
                                   GCancellable *cancellable,
                                   GError **error)
{
	EClient *client;

	client = e_book_client_connect_sync (source, wait_for_connected_seconds, cancellable, error);

	if (!client)
		return NULL;

	/* Connect the direct EDataBook connection */
	connect_direct (E_BOOK_CLIENT (client), cancellable, registry);

	return client;

}

/* Helper for e_book_client_connect_direct() */
static void
book_client_connect_direct_init_cb (GObject *source_object,
                                    GAsyncResult *result,
                                    gpointer user_data)
{
	GSimpleAsyncResult *simple;
	EBookClientPrivate *priv;
	ConnectClosure *closure;
	GError *error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	g_async_initable_init_finish (
		G_ASYNC_INITABLE (source_object), result, &error);

	if (error != NULL) {
		g_simple_async_result_take_error (simple, error);
		g_simple_async_result_complete (simple);
		goto exit;
	}

	/* Note, we're repurposing some function parameters. */
	result = G_ASYNC_RESULT (simple);
	source_object = g_async_result_get_source_object (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	priv = E_BOOK_CLIENT_GET_PRIVATE (source_object);

	e_dbus_address_book_call_open (
		priv->dbus_proxy,
		closure->cancellable,
		book_client_connect_open_cb,
		g_object_ref (simple));

	/* Make the DRA connection */
	connect_direct (E_BOOK_CLIENT (source_object), closure->cancellable, NULL);

	g_object_unref (source_object);

exit:
	g_object_unref (simple);
}

/**
 * e_book_client_connect_direct:
 * @source: an #ESource
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Like e_book_client_connect(), except creates the book client for
 * direct read access to the underlying addressbook.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_book_client_connect_direct_finish() to get the result of the operation.
 *
 * Since: 3.12
 **/
void
e_book_client_connect_direct (ESource *source,
			      guint32 wait_for_connected_seconds,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	EBookClient *client;

	g_return_if_fail (E_IS_SOURCE (source));

	/* Two things with this: 1) instantiate the client object
	 * immediately to make sure the thread-default GMainContext
	 * gets plucked, and 2) do not call the D-Bus open() method
	 * from our designated D-Bus thread -- it may take a long
	 * time and block other clients from receiving signals. */
	closure = g_slice_new0 (ConnectClosure);
	closure->source = g_object_ref (source);
	closure->wait_for_connected_seconds = wait_for_connected_seconds;

	if (G_IS_CANCELLABLE (cancellable))
		closure->cancellable = g_object_ref (cancellable);

	client = g_object_new (
		E_TYPE_BOOK_CLIENT,
		"source", source, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, e_book_client_connect_direct);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, closure, (GDestroyNotify) connect_closure_free);

	g_async_initable_init_async (
		G_ASYNC_INITABLE (client),
		G_PRIORITY_DEFAULT, cancellable,
		book_client_connect_direct_init_cb,
		g_object_ref (simple));

	g_object_unref (simple);
	g_object_unref (client);
}

/**
 * e_book_client_connect_direct_finish:
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_book_client_connect_direct().
 * If an error occurs in connecting to the D-Bus service, the function sets
 * @error and returns %NULL.
 *
 * For error handling convenience, any error message returned by this
 * function will have a descriptive prefix that includes the display
 * name of the #ESource passed to e_book_client_connect_direct().
 *
 * Returns: (transfer full) (type EBookClient): a new #EBookClient, or %NULL
 *
 * Since: 3.12
 **/
EClient *
e_book_client_connect_direct_finish (GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	gpointer source_tag;

	g_return_val_if_fail (G_IS_SIMPLE_ASYNC_RESULT (result), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	source_tag = g_simple_async_result_get_source_tag (simple);
	g_return_val_if_fail (source_tag == e_book_client_connect_direct, NULL);

	if (g_simple_async_result_propagate_error (simple, error)) {
		g_prefix_error (
			error, _("Unable to connect to “%s”: "),
			e_source_get_display_name (closure->source));
		return NULL;
	}

	return E_CLIENT (g_async_result_get_source_object (result));
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
 * e_book_client_get_self:
 * @registry: an #ESourceRegistry
 * @out_contact: (out): an #EContact pointer to set
 * @out_client: (out): an #EBookClient pointer to set
 * @error: a #GError to set on failure
 *
 * Get the #EContact referring to the user of the address book
 * and set it in @out_contact and @out_client.
 *
 * Returns: %TRUE if successful, otherwise %FALSE.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_self (ESourceRegistry *registry,
                        EContact **out_contact,
                        EBookClient **out_client,
                        GError **error)
{
	EBookClient *book_client;
	ESource *source;
	EContact *contact = NULL;
	GSettings *settings;
	gchar *uid;
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);
	g_return_val_if_fail (out_contact != NULL, FALSE);
	g_return_val_if_fail (out_client != NULL, FALSE);

	source = e_source_registry_ref_builtin_address_book (registry);
	book_client = e_book_client_new (source, error);
	g_object_unref (source);

	if (book_client == NULL)
		return FALSE;

	success = e_client_open_sync (
		E_CLIENT (book_client), FALSE, NULL, error);
	if (!success) {
		g_object_unref (book_client);
		return FALSE;
	}

	*out_client = book_client;

	settings = g_settings_new (SELF_UID_PATH_ID);
	uid = g_settings_get_string (settings, SELF_UID_KEY);
	g_object_unref (settings);

	if (uid) {
		/* Don't care about errors because
		 * we'll create a new card on failure. */
		/* coverity[unchecked_value] */
		if (!e_book_client_get_contact_sync (book_client, uid, &contact, NULL, NULL))
			contact = NULL;

		g_free (uid);

		if (contact != NULL) {
			*out_client = book_client;
			*out_contact = contact;
			return TRUE;
		}
	}

	uid = NULL;
	contact = make_me_card ();
	success = e_book_client_add_contact_sync (
		book_client, contact, &uid, NULL, error);
	if (!success) {
		g_object_unref (book_client);
		g_object_unref (contact);
		return FALSE;
	}

	if (uid != NULL) {
		e_contact_set (contact, E_CONTACT_UID, uid);
		g_free (uid);
	}

	e_book_client_set_self (book_client, contact, NULL);

	*out_client = book_client;
	*out_contact = contact;

	return TRUE;
}

/**
 * e_book_client_set_self:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @error: a #GError to set on failure
 *
 * Specify that @contact residing in @client is the #EContact that
 * refers to the user of the address book.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_set_self (EBookClient *client,
                        EContact *contact,
                        GError **error)
{
	GSettings *settings;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (contact != NULL, FALSE);
	g_return_val_if_fail (
		e_contact_get_const (contact, E_CONTACT_UID) != NULL, FALSE);

	settings = g_settings_new (SELF_UID_PATH_ID);
	g_settings_set_string (
		settings, SELF_UID_KEY,
		e_contact_get_const (contact, E_CONTACT_UID));
	g_object_unref (settings);

	return TRUE;
}

/**
 * e_book_client_is_self:
 * @contact: an #EContact
 *
 * Check if @contact is the user of the address book.
 *
 * Returns: %TRUE if @contact is the user, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_is_self (EContact *contact)
{
	static GSettings *settings;
	static GMutex mutex;
	const gchar *contact_uid;
	gchar *uid;
	gboolean is_self;

	g_return_val_if_fail (contact && E_IS_CONTACT (contact), FALSE);

	/*
	 * It would be nice to attach this instance to the EBookClient
	 * instance so that it can be free again later, but
	 * unfortunately the API doesn't allow that.
	 */
	g_mutex_lock (&mutex);
	if (!settings)
		settings = g_settings_new (SELF_UID_PATH_ID);
	uid = g_settings_get_string (settings, SELF_UID_KEY);
	g_mutex_unlock (&mutex);

	contact_uid = e_contact_get_const (contact, E_CONTACT_UID);
	is_self = (uid != NULL) && (g_strcmp0 (uid, contact_uid) == 0);

	g_free (uid);

	return is_self;
}

/* Helper for e_book_client_add_contact() */
static void
book_client_add_contact_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_add_contact_sync (
		E_BOOK_CLIENT (source_object),
		async_context->contact,
		&async_context->uid,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_add_contact:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Adds @contact to @client.
 * The call is finished by e_book_client_add_contact_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_add_contact (EBookClient *client,
                           EContact *contact,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (E_IS_CONTACT (contact));

	async_context = g_slice_new0 (AsyncContext);
	async_context->contact = g_object_ref (contact);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_add_contact);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_add_contact_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_add_contact_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_added_uid: (out): UID of a newly added contact; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_add_contact() and
 * sets @out_added_uid to a UID of a newly added contact.
 * This string should be freed with g_free().
 *
 * Note: This is not modifying original #EContact.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_add_contact_finish (EBookClient *client,
                                  GAsyncResult *result,
                                  gchar **out_added_uid,
                                  GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_add_contact), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->uid != NULL, FALSE);

	if (out_added_uid != NULL) {
		*out_added_uid = async_context->uid;
		async_context->uid = NULL;
	}

	return TRUE;
}

/**
 * e_book_client_add_contact_sync:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @out_added_uid: (out): UID of a newly added contact; can be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Adds @contact to @client and
 * sets @out_added_uid to a UID of a newly added contact.
 * This string should be freed with g_free().
 *
 * Note: This is not modifying original @contact, thus if it's needed,
 * then use e_contact_set (contact, E_CONTACT_UID, new_uid).
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_add_contact_sync (EBookClient *client,
                                EContact *contact,
                                gchar **out_added_uid,
                                GCancellable *cancellable,
                                GError **error)
{
	GSList link = { contact, NULL };
	GSList *uids = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	success = e_book_client_add_contacts_sync (
		client, &link, &uids, cancellable, error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (uids != NULL)) ||
		(!success && (uids == NULL)), FALSE);

	if (uids != NULL) {
		if (out_added_uid != NULL)
			*out_added_uid = g_strdup (uids->data);

		g_slist_free_full (uids, (GDestroyNotify) g_free);
	}

	return success;
}

/* Helper for e_book_client_add_contacts() */
static void
book_client_add_contacts_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_add_contacts_sync (
		E_BOOK_CLIENT (source_object),
		async_context->object_list,
		&async_context->string_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_add_contacts:
 * @client: an #EBookClient
 * @contacts: (element-type EContact): a #GSList of #EContact objects to add
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Adds @contacts to @client.
 * The call is finished by e_book_client_add_contacts_finish()
 * from the @callback.
 *
 * Since: 3.4
 **/
void
e_book_client_add_contacts (EBookClient *client,
                            GSList *contacts,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (contacts != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->object_list = g_slist_copy_deep (
		contacts, (GCopyFunc) g_object_ref, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_add_contacts);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_add_contacts_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_add_contacts_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_added_uids: (out) (element-type utf8) (allow-none): UIDs of
 *                  newly added contacts; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_add_contacts() and
 * sets @out_added_uids to the UIDs of newly added contacts if successful.
 * This #GSList should be freed with e_client_util_free_string_slist().
 *
 * If any of the contacts cannot be inserted, all of the insertions will be
 * reverted and this method will return %FALSE.
 *
 * Note: This is not modifying original #EContact objects.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.4
 **/
gboolean
e_book_client_add_contacts_finish (EBookClient *client,
                                   GAsyncResult *result,
                                   GSList **out_added_uids,
                                   GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_add_contacts), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_added_uids != NULL) {
		*out_added_uids = async_context->string_list;
		async_context->string_list = NULL;
	}

	return TRUE;
}

/**
 * e_book_client_add_contacts_sync:
 * @client: an #EBookClient
 * @contacts: (element-type EContact): a #GSList of #EContact objects to add
 * @out_added_uids: (out) (element-type utf8) (allow-none): UIDs of newly
 *                  added contacts; can be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Adds @contacts to @client and
 * sets @out_added_uids to the UIDs of newly added contacts if successful.
 * This #GSList should be freed with e_client_util_free_string_slist().
 *
 * If any of the contacts cannot be inserted, all of the insertions will be
 * reverted and this method will return %FALSE.
 *
 * Note: This is not modifying original @contacts, thus if it's needed,
 * then use e_contact_set (contact, E_CONTACT_UID, new_uid).
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.4
 **/
gboolean
e_book_client_add_contacts_sync (EBookClient *client,
                                 GSList *contacts,
                                 GSList **out_added_uids,
                                 GCancellable *cancellable,
                                 GError **error)
{
	GSList *link;
	gchar **strv;
	gchar **uids = NULL;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (contacts != NULL, FALSE);

	/* Build a string array, ensuring each element is valid UTF-8. */
	strv = g_new0 (gchar *, g_slist_length (contacts) + 1);
	for (link = contacts; link != NULL; link = g_slist_next (link)) {
		EVCard *vcard;
		gchar *string;

		vcard = E_VCARD (link->data);
		string = e_vcard_to_string (vcard, EVC_FORMAT_VCARD_30);
		strv[ii++] = e_util_utf8_make_valid (string);
		g_free (string);
	}

	e_dbus_address_book_call_create_contacts_sync (
		client->priv->dbus_proxy,
		(const gchar * const *) strv,
		&uids, cancellable, &local_error);

	g_strfreev (strv);

	/* Sanity check. */
	g_return_val_if_fail (
		((uids != NULL) && (local_error == NULL)) ||
		((uids == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	/* XXX We should have passed the string array directly
	 *     back to the caller instead of building a linked
	 *     list.  This is unnecessary work. */
	if (out_added_uids != NULL) {
		GSList *tmp = NULL;
		gint ii;

		/* Take ownership of the string array elements. */
		for (ii = 0; uids[ii] != NULL; ii++) {
			tmp = g_slist_prepend (tmp, uids[ii]);
			uids[ii] = NULL;
		}

		*out_added_uids = g_slist_reverse (tmp);
	}

	g_strfreev (uids);

	return TRUE;
}

/* Helper for e_book_client_modify_contact() */
static void
book_client_modify_contact_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_modify_contact_sync (
		E_BOOK_CLIENT (source_object),
		async_context->contact,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_modify_contact:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Applies the changes made to @contact to the stored version in @client.
 * The call is finished by e_book_client_modify_contact_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_modify_contact (EBookClient *client,
                              EContact *contact,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (E_IS_CONTACT (contact));

	async_context = g_slice_new0 (AsyncContext);
	async_context->contact = g_object_ref (contact);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_modify_contact);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_modify_contact_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_modify_contact_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_modify_contact().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_modify_contact_finish (EBookClient *client,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_modify_contact), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_book_client_modify_contact_sync:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Applies the changes made to @contact to the stored version in @client.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_modify_contact_sync (EBookClient *client,
                                   EContact *contact,
                                   GCancellable *cancellable,
                                   GError **error)
{
	GSList link = { contact, NULL };

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	return e_book_client_modify_contacts_sync (
		client, &link, cancellable, error);
}

/* Helper for e_book_client_modify_contacts() */
static void
book_client_modify_contacts_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_modify_contacts_sync (
		E_BOOK_CLIENT (source_object),
		async_context->object_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_modify_contacts:
 * @client: an #EBookClient
 * @contacts: (element-type EContact): a #GSList of #EContact objects
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Applies the changes made to @contacts to the stored versions in @client.
 * The call is finished by e_book_client_modify_contacts_finish()
 * from the @callback.
 *
 * Since: 3.4
 **/
void
e_book_client_modify_contacts (EBookClient *client,
                               GSList *contacts,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (contacts != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->object_list = g_slist_copy_deep (
		contacts, (GCopyFunc) g_object_ref, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_modify_contacts);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_modify_contacts_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_modify_contacts_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_modify_contacts().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.4
 **/
gboolean
e_book_client_modify_contacts_finish (EBookClient *client,
                                      GAsyncResult *result,
                                      GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_modify_contacts), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_book_client_modify_contacts_sync:
 * @client: an #EBookClient
 * @contacts: (element-type EContact): a #GSList of #EContact objects
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Applies the changes made to @contacts to the stored versions in @client.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.4
 **/
gboolean
e_book_client_modify_contacts_sync (EBookClient *client,
                                    GSList *contacts,
                                    GCancellable *cancellable,
                                    GError **error)
{
	GSList *link;
	gchar **strv;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (contacts != NULL, FALSE);

	/* Build a string array, ensuring each element is valid UTF-8. */
	strv = g_new0 (gchar *, g_slist_length (contacts) + 1);
	for (link = contacts; link != NULL; link = g_slist_next (link)) {
		EVCard *vcard;
		gchar *string;

		vcard = E_VCARD (link->data);
		string = e_vcard_to_string (vcard, EVC_FORMAT_VCARD_30);
		strv[ii++] = e_util_utf8_make_valid (string);
		g_free (string);
	}

	e_dbus_address_book_call_modify_contacts_sync (
		client->priv->dbus_proxy,
		(const gchar * const *) strv,
		cancellable, &local_error);

	g_strfreev (strv);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_book_client_remove_contact() */
static void
book_client_remove_contact_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_remove_contact_sync (
		E_BOOK_CLIENT (source_object),
		async_context->contact,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_remove_contact:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Removes @contact from the @client.
 * The call is finished by e_book_client_remove_contact_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_remove_contact (EBookClient *client,
                              /* const */ EContact *contact,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (E_IS_CONTACT (contact));

	async_context = g_slice_new0 (AsyncContext);
	async_context->contact = g_object_ref (contact);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_remove_contact);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_remove_contact_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_remove_contact_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_remove_contact().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contact_finish (EBookClient *client,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_remove_contact), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_book_client_remove_contact_sync:
 * @client: an #EBookClient
 * @contact: an #EContact
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Removes @contact from the @client.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contact_sync (EBookClient *client,
                                   EContact *contact,
                                   GCancellable *cancellable,
                                   GError **error)
{
	const gchar *uid;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	uid = e_contact_get_const (contact, E_CONTACT_UID);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_book_client_remove_contact_by_uid_sync (
		client, uid, cancellable, error);
}

/* Helper for e_book_client_remove_contact_by_uid() */
static void
book_client_remove_contact_by_uid_thread (GSimpleAsyncResult *simple,
                                          GObject *source_object,
                                          GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_remove_contact_by_uid_sync (
		E_BOOK_CLIENT (source_object),
		async_context->uid,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_remove_contact_by_uid:
 * @client: an #EBookClient
 * @uid: a UID of a contact to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Removes contact with @uid from the @client.
 * The call is finished by e_book_client_remove_contact_by_uid_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_remove_contact_by_uid (EBookClient *client,
                                     const gchar *uid,
                                     GCancellable *cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (uid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_remove_contact_by_uid);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_remove_contact_by_uid_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_remove_contact_by_uid_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_remove_contact_by_uid().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contact_by_uid_finish (EBookClient *client,
                                            GAsyncResult *result,
                                            GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_remove_contact_by_uid), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_book_client_remove_contact_by_uid_sync:
 * @client: an #EBookClient
 * @uid: a UID of a contact to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Removes contact with @uid from the @client.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contact_by_uid_sync (EBookClient *client,
                                          const gchar *uid,
                                          GCancellable *cancellable,
                                          GError **error)
{
	GSList link = { (gpointer) uid, NULL };

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_book_client_remove_contacts_sync (
		client, &link, cancellable, error);
}

/* Helper for e_book_client_remove_contacts() */
static void
book_client_remove_contacts_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_remove_contacts_sync (
		E_BOOK_CLIENT (source_object),
		async_context->string_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_remove_contacts:
 * @client: an #EBookClient
 * @uids: (element-type utf8): a #GSList of UIDs to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Removes the contacts with uids from the list @uids from @client.  This is
 * always more efficient than calling e_book_client_remove_contact() if you
 * have more than one uid to remove, as some backends can implement it
 * as a batch request.
 * The call is finished by e_book_client_remove_contacts_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_remove_contacts (EBookClient *client,
                               const GSList *uids,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (uids != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->string_list = g_slist_copy_deep (
		(GSList *) uids, (GCopyFunc) g_strdup, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_remove_contacts);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_remove_contacts_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_remove_contacts_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_remove_contacts().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contacts_finish (EBookClient *client,
                                      GAsyncResult *result,
                                      GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_remove_contacts), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_book_client_remove_contacts_sync:
 * @client: an #EBookClient
 * @uids: (element-type utf8): a #GSList of UIDs to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Removes the contacts with uids from the list @uids from @client.  This is
 * always more efficient than calling e_book_client_remove_contact() if you
 * have more than one uid to remove, as some backends can implement it
 * as a batch request.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_remove_contacts_sync (EBookClient *client,
                                    const GSList *uids,
                                    GCancellable *cancellable,
                                    GError **error)
{
	gchar **strv;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	strv = g_new0 (gchar *, g_slist_length ((GSList *) uids) + 1);
	while (uids != NULL) {
		strv[ii++] = e_util_utf8_make_valid (uids->data);
		uids = g_slist_next (uids);
	}

	e_dbus_address_book_call_remove_contacts_sync (
		client->priv->dbus_proxy,
		(const gchar * const *) strv,
		cancellable, &local_error);

	g_strfreev (strv);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_book_client_get_contact() */
static void
book_client_get_contact_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_get_contact_sync (
		E_BOOK_CLIENT (source_object),
		async_context->uid,
		&async_context->contact,
		cancellable, &local_error)) {
			if (!local_error)
				local_error = g_error_new_literal (
					E_CLIENT_ERROR,
					E_CLIENT_ERROR_OTHER_ERROR,
					_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_get_contact:
 * @client: an #EBookClient
 * @uid: a unique string ID specifying the contact
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Receive #EContact from the @client for the gived @uid.
 * The call is finished by e_book_client_get_contact_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_book_client_get_contact (EBookClient *client,
                           const gchar *uid,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (uid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_get_contact);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_get_contact_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_get_contact_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_contact: (out): an #EContact for previously given uid
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_get_contact().
 * If successful, then the @out_contact is set to newly allocated
 * #EContact, which should be freed with g_object_unref().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contact_finish (EBookClient *client,
                                  GAsyncResult *result,
                                  EContact **out_contact,
                                  GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_get_contact), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->contact != NULL, FALSE);

	if (out_contact != NULL)
		*out_contact = g_object_ref (async_context->contact);

	return TRUE;
}

/**
 * e_book_client_get_contact_sync:
 * @client: an #EBookClient
 * @uid: a unique string ID specifying the contact
 * @out_contact: (out): an #EContact for given @uid
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Receive #EContact from the @client for the gived @uid.
 * If successful, then the @out_contact is set to newly allocated
 * #EContact, which should be freed with g_object_unref().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contact_sync (EBookClient *client,
                                const gchar *uid,
                                EContact **out_contact,
                                GCancellable *cancellable,
                                GError **error)
{
	gchar *utf8_uid;
	gchar *vcard = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_contact != NULL, FALSE);

	if (client->priv->direct_backend != NULL) {
		EContact *contact;
		gboolean success = FALSE;

		/* Direct backend is not using D-Bus (obviously),
		 * so no need to strip D-Bus info from the error. */
		contact = e_book_backend_get_contact_sync (
			client->priv->direct_backend,
			uid, cancellable, error);

		if (contact != NULL) {
			*out_contact = g_object_ref (contact);
			g_object_unref (contact);
			success = TRUE;
		}

		return success;
	}

	utf8_uid = e_util_utf8_make_valid (uid);

	e_dbus_address_book_call_get_contact_sync (
		client->priv->dbus_proxy, utf8_uid,
		&vcard, cancellable, &local_error);

	/* Sanity check. */
	g_return_val_if_fail (
		((vcard != NULL) && (local_error == NULL)) ||
		((vcard == NULL) && (local_error != NULL)), FALSE);

	if (vcard != NULL) {
		*out_contact =
			e_contact_new_from_vcard_with_uid (vcard, utf8_uid);
		g_free (vcard);
	}

	g_free (utf8_uid);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_book_client_get_contacts() */
static void
book_client_get_contacts_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_get_contacts_sync (
		E_BOOK_CLIENT (source_object),
		async_context->sexp,
		&async_context->object_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_get_contacts:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Query @client with @sexp, receiving a list of contacts which
 * matched. The call is finished by e_book_client_get_contacts_finish()
 * from the @callback.
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Since: 3.2
 **/
void
e_book_client_get_contacts (EBookClient *client,
                            const gchar *sexp,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_get_contacts);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_get_contacts_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_get_contacts_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_contacts: (element-type EContact) (out) (transfer full): a #GSList
 *                of matched #EContact(s)
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_get_contacts().
 * If successful, then the @out_contacts is set to newly allocated list of
 * #EContact(s), which should be freed with e_client_util_free_object_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contacts_finish (EBookClient *client,
                                   GAsyncResult *result,
                                   GSList **out_contacts,
                                   GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_get_contacts), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_contacts != NULL) {
		*out_contacts = async_context->object_list;
		async_context->object_list = NULL;
	}

	return TRUE;
}

/**
 * e_book_client_get_contacts_sync:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @out_contacts: (element-type EContact) (out): a #GSList of matched
 *                #EContact(s)
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Query @client with @sexp, receiving a list of contacts which matched.
 * If successful, then the @out_contacts is set to newly allocated #GSList of
 * #EContact(s), which should be freed with e_client_util_free_object_slist().
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contacts_sync (EBookClient *client,
                                 const gchar *sexp,
                                 GSList **out_contacts,
                                 GCancellable *cancellable,
                                 GError **error)
{
	gchar *utf8_sexp;
	gchar **vcards = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	if (client->priv->direct_backend != NULL) {
		GQueue queue = G_QUEUE_INIT;
		GSList *list = NULL;
		gboolean success;

		/* Direct backend is not using D-Bus (obviously),
		 * so no need to strip D-Bus info from the error. */
		success = e_book_backend_get_contact_list_sync (
			client->priv->direct_backend,
			sexp, &queue, cancellable, error);

		if (success) {
			while (!g_queue_is_empty (&queue)) {
				EContact *contact;

				contact = g_queue_pop_head (&queue);
				list = g_slist_prepend (list, contact);
			}

			*out_contacts = g_slist_reverse (list);
		}

		return success;
	}

	utf8_sexp = e_util_utf8_make_valid (sexp);

	e_dbus_address_book_call_get_contact_list_sync (
		client->priv->dbus_proxy, utf8_sexp,
		&vcards, cancellable, &local_error);

	g_free (utf8_sexp);

	/* Sanity check. */
	g_return_val_if_fail (
		((vcards != NULL) && (local_error == NULL)) ||
		((vcards == NULL) && (local_error != NULL)), FALSE);

	if (vcards != NULL) {
		EContact *contact;
		GSList *tmp = NULL;
		gint ii;

		for (ii = 0; vcards[ii] != NULL; ii++) {
			contact = e_contact_new_from_vcard (vcards[ii]);
			tmp = g_slist_prepend (tmp, contact);
		}

		*out_contacts = g_slist_reverse (tmp);

		g_strfreev (vcards);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_book_client_get_contacts_uids() */
static void
book_client_get_contacts_uids_thread (GSimpleAsyncResult *simple,
                                      GObject *source_object,
                                      GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_book_client_get_contacts_uids_sync (
		E_BOOK_CLIENT (source_object),
		async_context->sexp,
		&async_context->string_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_book_client_get_contacts_uids:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Query @client with @sexp, receiving a list of contacts UIDs which
 * matched. The call is finished by e_book_client_get_contacts_uids_finish()
 * from the @callback.
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Since: 3.2
 **/
void
e_book_client_get_contacts_uids (EBookClient *client,
                                 const gchar *sexp,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_get_contacts_uids);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, book_client_get_contacts_uids_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_get_contacts_uids_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_contact_uids: (element-type utf8) (out): a #GSList of matched
 *                    contact UIDs stored as strings
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_get_contacts_uids().
 * If successful, then the @out_contact_uids is set to newly allocated list
 * of UID strings, which should be freed with e_client_util_free_string_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contacts_uids_finish (EBookClient *client,
                                        GAsyncResult *result,
                                        GSList **out_contact_uids,
                                        GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_get_contacts_uids), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_contact_uids != NULL) {
		*out_contact_uids = async_context->string_list;
		async_context->string_list = NULL;
	}

	return TRUE;
}

/**
 * e_book_client_get_contacts_uids_sync:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @out_contact_uids: (element-type utf8) (out): a #GSList of matched
 *                    contacts UIDs stored as strings
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Query @client with @sexp, receiving a list of contacts UIDs which matched.
 * If successful, then the @out_contact_uids is set to newly allocated list
 * of UID strings, which should be freed with e_client_util_free_string_slist().
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_contacts_uids_sync (EBookClient *client,
                                      const gchar *sexp,
                                      GSList **out_contact_uids,
                                      GCancellable *cancellable,
                                      GError **error)
{
	gchar *utf8_sexp;
	gchar **uids = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_contact_uids != NULL, FALSE);

	if (client->priv->direct_backend != NULL) {
		GQueue queue = G_QUEUE_INIT;
		GSList *list = NULL;
		gboolean success;

		/* Direct backend is not using D-Bus (obviously),
		 * so no need to strip D-Bus info from the error. */
		success = e_book_backend_get_contact_list_uids_sync (
			client->priv->direct_backend,
			sexp, &queue, cancellable, error);

		if (success) {
			while (!g_queue_is_empty (&queue)) {
				gchar *uid;

				uid = g_queue_pop_head (&queue);
				list = g_slist_prepend (list, uid);
			}

			*out_contact_uids = g_slist_reverse (list);
		}

		return success;
	}

	utf8_sexp = e_util_utf8_make_valid (sexp);

	e_dbus_address_book_call_get_contact_list_uids_sync (
		client->priv->dbus_proxy, utf8_sexp,
		&uids, cancellable, &local_error);

	g_free (utf8_sexp);

	/* Sanity check. */
	g_return_val_if_fail (
		((uids != NULL) && (local_error == NULL)) ||
		((uids == NULL) && (local_error != NULL)), FALSE);

	/* XXX We should have passed the string array directly
	 *     back to the caller instead of building a linked
	 *     list.  This is unnecessary work. */
	if (uids != NULL) {
		GSList *tmp = NULL;
		gint ii;

		/* Take ownership of the string array elements. */
		for (ii = 0; uids[ii] != NULL; ii++) {
			tmp = g_slist_prepend (tmp, uids[ii]);
			uids[ii] = NULL;
		}

		*out_contact_uids = g_slist_reverse (tmp);

		g_free (uids);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_book_client_get_view() */
static void
book_client_get_view_in_dbus_thread (GSimpleAsyncResult *simple,
                                     GObject *source_object,
                                     GCancellable *cancellable)
{
	EBookClient *client = E_BOOK_CLIENT (source_object);
	AsyncContext *async_context;
	gchar *utf8_sexp;
	gchar *object_path = NULL;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	utf8_sexp = e_util_utf8_make_valid (async_context->sexp);

	e_dbus_address_book_call_get_view_sync (
		client->priv->dbus_proxy, utf8_sexp,
		&object_path, cancellable, &local_error);

	g_free (utf8_sexp);

	/* Sanity check. */
	g_return_if_fail (
		((object_path != NULL) && (local_error == NULL)) ||
		((object_path == NULL) && (local_error != NULL)));

	if (object_path != NULL) {
		GDBusConnection *connection;
		EBookClientView *client_view;

		connection = g_dbus_proxy_get_connection (
			G_DBUS_PROXY (client->priv->dbus_proxy));

		client_view = g_initable_new (
			E_TYPE_BOOK_CLIENT_VIEW,
			cancellable, &local_error,
			"client", client,
			"connection", connection,
			"object-path", object_path,
			"direct-backend", client->priv->direct_backend,
			NULL);

		/* Sanity check. */
		g_return_if_fail (
			((client_view != NULL) && (local_error == NULL)) ||
			((client_view == NULL) && (local_error != NULL)));

		async_context->client_view = client_view;

		g_free (object_path);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
	}
}

/**
 * e_book_client_get_view:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Query @client with @sexp, creating an #EBookClientView.
 * The call is finished by e_book_client_get_view_finish()
 * from the @callback.
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Since: 3.2
 **/
void
e_book_client_get_view (EBookClient *client,
                        const gchar *sexp,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_get_view);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	book_client_run_in_dbus_thread (
		simple, book_client_get_view_in_dbus_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_get_view_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_view: (out): an #EBookClientView
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_get_view().
 * If successful, then the @out_view is set to newly allocated
 * #EBookClientView, which should be freed with g_object_unref().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_view_finish (EBookClient *client,
                               GAsyncResult *result,
                               EBookClientView **out_view,
                               GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_get_view), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->client_view != NULL, FALSE);

	if (out_view != NULL)
		*out_view = g_object_ref (async_context->client_view);

	return TRUE;
}

/**
 * e_book_client_get_view_sync:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @out_view: (out): an #EBookClientView
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Query @client with @sexp, creating an #EBookClientView.
 * If successful, then the @out_view is set to newly allocated
 * #EBookClientView, which should be freed with g_object_unref().
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_book_client_get_view_sync (EBookClient *client,
                             const gchar *sexp,
                             EBookClientView **out_view,
                             GCancellable *cancellable,
                             GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_view != NULL, FALSE);

	closure = e_async_closure_new ();

	e_book_client_get_view (
		client, sexp, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_book_client_get_view_finish (
		client, result, out_view, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_book_client_get_cursor() */
static const gchar **
sort_param_to_strv (gpointer param,
                    gint n_fields,
                    gboolean keys)
{
	const gchar **array;
	gint i;

	array = (const gchar **) g_new0 (gchar *, n_fields + 1);

	/* string arrays are shallow allocated, the strings themselves
	 * are intern strings and don't need to be dupped.
	 */
	for (i = 0; i < n_fields; i++) {

		if (keys) {
			EContactField *fields = (EContactField *) param;

			array[i] = e_contact_field_name (fields[i]);
		} else {
			EBookCursorSortType *types = (EBookCursorSortType *) param;

			array[i] = e_enum_to_string (
				E_TYPE_BOOK_CURSOR_SORT_TYPE,
				types[i]);
		}
	}

	return array;
}

/* This is ugly and should change yes, currently EBookClientCursor
 * needs to keep a strong reference to the EBookClient to keep it alive
 * long enough to ask the EBookClient to delete a direct cursor on
 * the EBookClientCursor's behalf, otherwise direct cursors are leaked.
 */
void book_client_delete_direct_cursor (EBookClient *client,
				       EDataBookCursor *cursor);

void
book_client_delete_direct_cursor (EBookClient *client,
                                  EDataBookCursor *cursor)
{
	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (E_IS_DATA_BOOK_CURSOR (cursor));

	if (!client->priv->direct_backend) {
		g_warning ("Tried to delete a cursor in DRA mode but the direct backend is missing");
		return;
	}

	e_book_backend_delete_cursor (
		client->priv->direct_backend,
		cursor, NULL);
}

static void
book_client_get_cursor_in_dbus_thread (GSimpleAsyncResult *simple,
                                       GObject *source_object,
                                       GCancellable *cancellable)
{
	EBookClient *client = E_BOOK_CLIENT (source_object);
	AsyncContext *async_context;
	gchar *utf8_sexp;
	gchar *object_path = NULL;
	GError *local_error = NULL;
	const gchar **sort_fields;
	const gchar **sort_types;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	sort_fields = sort_param_to_strv (
		async_context->sort_fields,
		async_context->n_sort_fields, TRUE);
	sort_types = sort_param_to_strv (
		async_context->sort_types,
		async_context->n_sort_fields, FALSE);

	/* Direct Read Access cursor don't need any D-Bus connection
	 * themselves, just give them an EDataBookCursor directly. */
	if (client->priv->direct_backend) {
		EDataBookCursor *cursor;

		cursor = e_book_backend_create_cursor (
			client->priv->direct_backend,
			async_context->sort_fields,
			async_context->sort_types,
			async_context->n_sort_fields,
			&local_error);

		if (cursor != NULL) {
			e_data_book_cursor_set_sexp (
				cursor,
				async_context->sexp,
				cancellable, &local_error);

			if (local_error != NULL) {
				e_book_backend_delete_cursor (
					client->priv->direct_backend,
					cursor,
					NULL);
				cursor = NULL;
			}
		}

		if (cursor != NULL) {
			EBookClientCursor *client_cursor;

			/* The client cursor will take a ref, but
			 * e_book_backend_create_cursor() returns
			 * a pointer to a cursor owned by the backend,
			 * don't unref the returned pointer here.
			 */
			client_cursor = g_initable_new (
				E_TYPE_BOOK_CLIENT_CURSOR,
				cancellable, &local_error,
				"sort-fields", sort_fields,
				"client", client,
				"context", async_context->context,
				"direct-cursor", cursor,
				NULL);

			/* Sanity check. */
			g_return_if_fail (
					  ((client_cursor != NULL) && (local_error == NULL)) ||
					  ((client_cursor == NULL) && (local_error != NULL)));

			async_context->client_cursor = client_cursor;
		}

	} else {
		utf8_sexp = e_util_utf8_make_valid (async_context->sexp);

		e_dbus_address_book_call_get_cursor_sync (
			client->priv->dbus_proxy, utf8_sexp,
			(const gchar *const *) sort_fields,
			(const gchar *const *) sort_types,
			&object_path, cancellable, &local_error);

		g_free (utf8_sexp);

		/* Sanity check. */
		g_return_if_fail (
			  ((object_path != NULL) && (local_error == NULL)) ||
			  ((object_path == NULL) && (local_error != NULL)));

		if (object_path != NULL) {
			GDBusConnection *connection;
			EBookClientCursor *client_cursor;

			connection = g_dbus_proxy_get_connection (
				G_DBUS_PROXY (client->priv->dbus_proxy));

			client_cursor = g_initable_new (
				E_TYPE_BOOK_CLIENT_CURSOR,
				cancellable, &local_error,
				"sort-fields", sort_fields,
				"client", client,
				"context", async_context->context,
				"connection", connection,
				"object-path", object_path,
				NULL);

			/* Sanity check. */
			g_return_if_fail (
					  ((client_cursor != NULL) && (local_error == NULL)) ||
					  ((client_cursor == NULL) && (local_error != NULL)));

			async_context->client_cursor = client_cursor;

			g_free (object_path);
		}
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
	}

	g_free (sort_fields);
	g_free (sort_types);
}

/* Need to catch the GMainContext of the actual caller,
 * we do this dance because e_async_closure_new ()
 * steps on the thread default main context (so we
 * can use this in the sync call as well).
 */
static void
e_book_client_get_cursor_with_context (EBookClient *client,
                                       const gchar *sexp,
                                       const EContactField *sort_fields,
                                       const EBookCursorSortType *sort_types,
                                       guint n_fields,
                                       GMainContext *context,
                                       GCancellable *cancellable,
                                       GAsyncReadyCallback callback,
                                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (sort_fields != NULL);
	g_return_if_fail (sort_types != NULL);
	g_return_if_fail (n_fields > 0);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);
	async_context->sort_fields = g_memdup (sort_fields, sizeof (EContactField) * n_fields);
	async_context->sort_types = g_memdup (sort_types, sizeof (EBookCursorSortType) * n_fields);
	async_context->n_sort_fields = n_fields;
	async_context->context = g_main_context_ref (context);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_book_client_get_cursor);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	book_client_run_in_dbus_thread (
		simple, book_client_get_cursor_in_dbus_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_get_cursor:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @sort_fields: an array of #EContactFields to sort the cursor with
 * @sort_types: an array of #EBookCursorSortTypes to complement @sort_fields
 * @n_fields: the length of the input @sort_fields and @sort_types arrays
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Create an #EBookClientCursor.
 * The call is finished by e_book_client_get_view_finish()
 * from the @callback.
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Since: 3.12
 */
void
e_book_client_get_cursor (EBookClient *client,
                          const gchar *sexp,
                          const EContactField *sort_fields,
                          const EBookCursorSortType *sort_types,
                          guint n_fields,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GMainContext *context;

	context = g_main_context_ref_thread_default ();
	e_book_client_get_cursor_with_context (
		client, sexp,
		sort_fields,
		sort_types,
		n_fields,
		context,
		cancellable,
		callback,
		user_data);
	g_main_context_unref (context);
}

/**
 * e_book_client_get_cursor_finish:
 * @client: an #EBookClient
 * @result: a #GAsyncResult
 * @out_cursor: (out): return location for an #EBookClientCursor
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_book_client_get_cursor().
 * If successful, then the @out_cursor is set to newly create
 * #EBookClientCursor, the cursor should be freed with g_object_unref()
 * when no longer needed.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.12
 */
gboolean
e_book_client_get_cursor_finish (EBookClient *client,
                                 GAsyncResult *result,
                                 EBookClientCursor **out_cursor,
                                 GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_book_client_get_cursor), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->client_cursor != NULL, FALSE);

	if (out_cursor != NULL)
		*out_cursor = g_object_ref (async_context->client_cursor);

	return TRUE;
}

/**
 * e_book_client_get_cursor_sync:
 * @client: an #EBookClient
 * @sexp: an S-expression representing the query
 * @sort_fields: an array of #EContactFields to sort the cursor with
 * @sort_types: an array of #EBookCursorSortTypes to complement @sort_fields
 * @n_fields: the length of the input @sort_fields and @sort_types arrays
 * @out_cursor: (out): return location for an #EBookClientCursor
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Create an #EBookClientCursor. If successful, then the @out_cursor is set
 * to newly allocated #EBookClientCursor, the cursor should be freed with g_object_unref()
 * when no longer needed.
 *
 * Note: @sexp can be obtained through #EBookQuery, by converting it
 * to a string with e_book_query_to_string().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.12
 */
gboolean
e_book_client_get_cursor_sync (EBookClient *client,
                               const gchar *sexp,
                               const EContactField *sort_fields,
                               const EBookCursorSortType *sort_types,
                               guint n_fields,
                               EBookClientCursor **out_cursor,
                               GCancellable *cancellable,
                               GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;
	GMainContext *context;

	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), FALSE);
	g_return_val_if_fail (sort_fields != NULL, FALSE);
	g_return_val_if_fail (sort_types != NULL, FALSE);
	g_return_val_if_fail (n_fields > 0, FALSE);
	g_return_val_if_fail (out_cursor != NULL, FALSE);

	/* Get the main context before e_async_closure_new () steps on it */
	context = g_main_context_ref_thread_default ();

	closure = e_async_closure_new ();

	e_book_client_get_cursor_with_context (
		client, sexp,
		sort_fields,
		sort_types,
		n_fields,
		context,
		cancellable,
		e_async_closure_callback, closure);

	g_main_context_unref (context);

	result = e_async_closure_wait (closure);

	success = e_book_client_get_cursor_finish (
		client, result, out_cursor, error);

	e_async_closure_free (closure);

	return success;
}

static void
book_client_set_locale (EBookClient *client,
                        const gchar *locale)
{
	if (g_strcmp0 (client->priv->locale, locale) != 0) {
		g_free (client->priv->locale);
		client->priv->locale = g_strdup (locale);

		g_object_notify (G_OBJECT (client), "locale");
	}
}

/**
 * e_book_client_get_locale:
 * @client: an #EBookClient
 *
 * Reports the locale in use for @client. The addressbook might sort contacts
 * in different orders, or store and compare phone numbers in different ways
 * depending on the currently set locale.
 *
 * Locales can change dynamically if systemd decides to change the locale, so
 * it's important to listen for notifications on the #EBookClient:locale property
 * if you depend on sorted result lists. Ordered results should be reloaded
 * after a locale change is detected.
 *
 * Returns: (transfer none): The currently set locale for @client
 *
 * Since: 3.12
 */
const gchar *
e_book_client_get_locale (EBookClient *client)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT (client), NULL);

	return client->priv->locale;
}
