/*
 * e-client.h
 *
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_CLIENT_H
#define E_CLIENT_H

#include <gio/gio.h>

#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_CLIENT \
	(e_client_get_type ())
#define E_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CLIENT, EClient))
#define E_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CLIENT, EClientClass))
#define E_IS_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CLIENT))
#define E_IS_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CLIENT))
#define E_CLIENT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CLIENT, EClientClass))

/**
 * CLIENT_BACKEND_PROPERTY_ONLINE:
 *
 * The "online" property is "TRUE" when the client is fully opened and
 * online, "FALSE" at all other times.  See also e_client_is_online().
 *
 * Since: 3.2
 **/
#define CLIENT_BACKEND_PROPERTY_ONLINE			"online"

/**
 * CLIENT_BACKEND_PROPERTY_READONLY:
 *
 * The "online" property is "TRUE" if the backend has only read access
 * to its data, "FALSE" if the backend can modify its data.  See also
 * e_client_is_readonly().
 *
 * Since: 3.2
 **/
#define CLIENT_BACKEND_PROPERTY_READONLY		"readonly"

/**
 * CLIENT_BACKEND_PROPERTY_CACHE_DIR:
 *
 * The "cache-dir" property indicates the backend's local directory for
 * cached data.
 *
 * Since: 3.2
 **/
#define CLIENT_BACKEND_PROPERTY_CACHE_DIR		"cache-dir"

/**
 * CLIENT_BACKEND_PROPERTY_CAPABILITIES:
 *
 * The "capabilities" property is a comma-separated list of capabilities
 * supported by the backend.  The preferred method of retrieving and working
 * with capabilities is e_client_get_capabilities() and
 * e_client_check_capability().
 *
 * Since: 3.2
 **/
#define CLIENT_BACKEND_PROPERTY_CAPABILITIES		"capabilities"

/**
 * CLIENT_BACKEND_PROPERTY_REVISION:
 *
 * The current overall revision string, this can be used as
 * a quick check to see if data has changed at all since the
 * last time the revision was observed.
 *
 * Since: 3.4
 **/
#define CLIENT_BACKEND_PROPERTY_REVISION		"revision"

/**
 * E_CLIENT_ERROR:
 *
 * Error domain for #EClient operations.  Errors in this domain will be
 * from the #EClientError enumeration.  See #GError for more information
 * on error domains.
 *
 * Since: 3.2
 **/
#define E_CLIENT_ERROR		e_client_error_quark ()

G_BEGIN_DECLS

GQuark e_client_error_quark (void) G_GNUC_CONST;

/**
 * EClientError:
 * @E_CLIENT_ERROR_INVALID_ARG: Invalid argument was used
 * @E_CLIENT_ERROR_BUSY: The client is busy
 * @E_CLIENT_ERROR_SOURCE_NOT_LOADED: The source is not loaded
 * @E_CLIENT_ERROR_SOURCE_ALREADY_LOADED: The source is already loaded
 * @E_CLIENT_ERROR_AUTHENTICATION_FAILED: Authentication failed
 * @E_CLIENT_ERROR_AUTHENTICATION_REQUIRED: Authentication required
 * @E_CLIENT_ERROR_REPOSITORY_OFFLINE: The repository (client) is offline
 * @E_CLIENT_ERROR_OFFLINE_UNAVAILABLE: The operation is unavailable in offline mode
 * @E_CLIENT_ERROR_PERMISSION_DENIED: Permission denied for the operation
 * @E_CLIENT_ERROR_CANCELLED: The operation was cancelled
 * @E_CLIENT_ERROR_COULD_NOT_CANCEL: The operation cannot be cancelled
 * @E_CLIENT_ERROR_NOT_SUPPORTED: The operation is not supported
 * @E_CLIENT_ERROR_TLS_NOT_AVAILABLE: TLS is not available
 * @E_CLIENT_ERROR_UNSUPPORTED_AUTHENTICATION_METHOD: Requested authentication method is not supported
 * @E_CLIENT_ERROR_SEARCH_SIZE_LIMIT_EXCEEDED: Search size limit exceeded
 * @E_CLIENT_ERROR_SEARCH_TIME_LIMIT_EXCEEDED: Search time limit exceeded
 * @E_CLIENT_ERROR_INVALID_QUERY: The query was invalid
 * @E_CLIENT_ERROR_QUERY_REFUSED: The query was refused by the server side
 * @E_CLIENT_ERROR_DBUS_ERROR: A D-Bus error occurred
 * @E_CLIENT_ERROR_OTHER_ERROR: Other error
 * @E_CLIENT_ERROR_NOT_OPENED: The client is not opened
 * @E_CLIENT_ERROR_OUT_OF_SYNC: The clien tis out of sync
 *
 * Error codes for #EClient operations.
 *
 * Since: 3.2
 **/
typedef enum {
	E_CLIENT_ERROR_INVALID_ARG,
	E_CLIENT_ERROR_BUSY,
	E_CLIENT_ERROR_SOURCE_NOT_LOADED,
	E_CLIENT_ERROR_SOURCE_ALREADY_LOADED,
	E_CLIENT_ERROR_AUTHENTICATION_FAILED,
	E_CLIENT_ERROR_AUTHENTICATION_REQUIRED,
	E_CLIENT_ERROR_REPOSITORY_OFFLINE,
	E_CLIENT_ERROR_OFFLINE_UNAVAILABLE,
	E_CLIENT_ERROR_PERMISSION_DENIED,
	E_CLIENT_ERROR_CANCELLED,
	E_CLIENT_ERROR_COULD_NOT_CANCEL,
	E_CLIENT_ERROR_NOT_SUPPORTED,
	E_CLIENT_ERROR_TLS_NOT_AVAILABLE,
	E_CLIENT_ERROR_UNSUPPORTED_AUTHENTICATION_METHOD,
	E_CLIENT_ERROR_SEARCH_SIZE_LIMIT_EXCEEDED,
	E_CLIENT_ERROR_SEARCH_TIME_LIMIT_EXCEEDED,
	E_CLIENT_ERROR_INVALID_QUERY,
	E_CLIENT_ERROR_QUERY_REFUSED,
	E_CLIENT_ERROR_DBUS_ERROR,
	E_CLIENT_ERROR_OTHER_ERROR,
	E_CLIENT_ERROR_NOT_OPENED,
	E_CLIENT_ERROR_OUT_OF_SYNC
} EClientError;

const gchar *	e_client_error_to_string	(EClientError code);

/**
 * EClient:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
typedef struct _EClient EClient;
typedef struct _EClientClass EClientClass;
typedef struct _EClientPrivate EClientPrivate;

struct _EClient {
	/*< private >*/
	GObject parent;
	EClientPrivate *priv;
};

struct _EClientClass {
	/*< private >*/
	GObjectClass parent;

	/* This method is deprecated. */
	GDBusProxy *	(*get_dbus_proxy)	(EClient *client);

	/* This method is deprecated. */
	void		(*unwrap_dbus_error)	(EClient *client,
						 GError *dbus_error,
						 GError **out_error);

	/* This method is deprecated. */
	void		(*retrieve_capabilities)
						(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*retrieve_capabilities_finish)
						(EClient *client,
						 GAsyncResult *result,
						 gchar **capabilities,
						 GError **error);
	gboolean	(*retrieve_capabilities_sync)
						(EClient *client,
						 gchar **capabilities,
						 GCancellable *cancellable,
						 GError **error);

	void		(*get_backend_property)	(EClient *client,
						 const gchar *prop_name,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*get_backend_property_finish)
						(EClient *client,
						 GAsyncResult *result,
						 gchar **prop_value,
						 GError **error);
	gboolean	(*get_backend_property_sync)
						(EClient *client,
						 const gchar *prop_name,
						 gchar **prop_value,
						 GCancellable *cancellable,
						 GError **error);

	/* This method is deprecated. */
	void		(*set_backend_property)	(EClient *client,
						 const gchar *prop_name,
						 const gchar *prop_value,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*set_backend_property_finish)
						(EClient *client,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*set_backend_property_sync)
						(EClient *client,
						 const gchar *prop_name,
						 const gchar *prop_value,
						 GCancellable *cancellable,
						 GError **error);

	void		(*open)			(EClient *client,
						 gboolean only_if_exists,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*open_finish)		(EClient *client,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*open_sync)		(EClient *client,
						 gboolean only_if_exists,
						 GCancellable *cancellable,
						 GError **error);

	void		(*remove)		(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*remove_finish)	(EClient *client,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*remove_sync)		(EClient *client,
						 GCancellable *cancellable,
						 GError **error);

	void		(*refresh)		(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*refresh_finish)	(EClient *client,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*refresh_sync)		(EClient *client,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*retrieve_properties_sync)
						(EClient *client,
						 GCancellable *cancellable,
						 GError **error);

	void		(*opened)		(EClient *client,
						 const GError *error);
	void		(*backend_error)	(EClient *client,
						 const gchar *error_msg);
	void		(*backend_died)		(EClient *client);
	void		(*backend_property_changed)
						(EClient *client,
						 const gchar *prop_name,
						 const gchar *prop_value);
};

GType		e_client_get_type		(void) G_GNUC_CONST;

ESource *	e_client_get_source		(EClient *client);
const GSList *	e_client_get_capabilities	(EClient *client);
GMainContext *	e_client_ref_main_context	(EClient *client);
gboolean	e_client_check_capability	(EClient *client,
						 const gchar *capability);
gboolean	e_client_check_refresh_supported
						(EClient *client);
gboolean	e_client_is_readonly		(EClient *client);
gboolean	e_client_is_online		(EClient *client);

void		e_client_get_backend_property	(EClient *client,
						 const gchar *prop_name,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_get_backend_property_finish
						(EClient *client,
						 GAsyncResult *result,
						 gchar **prop_value,
						 GError **error);
gboolean	e_client_get_backend_property_sync
						(EClient *client,
						 const gchar *prop_name,
						 gchar **prop_value,
						 GCancellable *cancellable,
						 GError **error);

void		e_client_refresh		(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_refresh_finish		(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_client_refresh_sync		(EClient *client,
						 GCancellable *cancellable,
						 GError **error);

void		e_client_wait_for_connected	(EClient *client,
						 guint32 timeout_seconds,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_wait_for_connected_finish
						(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_client_wait_for_connected_sync(EClient *client,
						 guint32 timeout_seconds,
						 GCancellable *cancellable,
						 GError **error);

GSList *	e_client_util_parse_comma_strings
						(const gchar *strings);

#ifndef EDS_DISABLE_DEPRECATED
/**
 * CLIENT_BACKEND_PROPERTY_OPENED:
 *
 * The "opened" property is "TRUE" when the client is fully opened,
 * "FALSE" at all other times.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients don't need to care if they're fully opened
 *                  anymore.  This property will always return %TRUE.
 **/
#define CLIENT_BACKEND_PROPERTY_OPENED			"opened"

/**
 * CLIENT_BACKEND_PROPERTY_OPENING:
 *
 * The "opening" property is "TRUE" when the client is in the process of
 * opening, "FALSE" at all other times.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients don't need to care if they're fully opened
 *                  anymore.  This property will always return %FALSE.
 **/
#define CLIENT_BACKEND_PROPERTY_OPENING			"opening"

GError *	e_client_error_create		(EClientError code,
						 const gchar *custom_msg);
gboolean	e_client_is_opened		(EClient *client);
void		e_client_cancel_all		(EClient *client);
void		e_client_unwrap_dbus_error	(EClient *client,
						 GError *dbus_error,
						 GError **out_error);
void		e_client_retrieve_capabilities	(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_retrieve_capabilities_finish
						(EClient *client,
						 GAsyncResult *result,
						 gchar **capabilities,
						 GError **error);
gboolean	e_client_retrieve_capabilities_sync
						(EClient *client,
						 gchar **capabilities,
						 GCancellable *cancellable,
						 GError **error);
void		e_client_set_backend_property	(EClient *client,
						 const gchar *prop_name,
						 const gchar *prop_value,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_set_backend_property_finish
						(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_client_set_backend_property_sync
						(EClient *client,
						 const gchar *prop_name,
						 const gchar *prop_value,
						 GCancellable *cancellable,
						 GError **error);
void		e_client_open			(EClient *client,
						 gboolean only_if_exists,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_open_finish		(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_client_open_sync		(EClient *client,
						 gboolean only_if_exists,
						 GCancellable *cancellable,
						 GError **error);
void		e_client_remove			(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_remove_finish		(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_client_remove_sync		(EClient *client,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_client_retrieve_properties_sync
						(EClient *client,
						 GCancellable *cancellable,
						 GError **error);
void		e_client_retrieve_properties	(EClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_client_retrieve_properties_finish
						(EClient *client,
						 GAsyncResult *result,
						 GError **error);
gchar **	e_client_util_slist_to_strv	(const GSList *strings);
GSList *	e_client_util_strv_to_slist	(const gchar * const *strv);
GSList *	e_client_util_copy_string_slist	(GSList *copy_to,
						 const GSList *strings);
GSList *	e_client_util_copy_object_slist	(GSList *copy_to,
						 const GSList *objects);
void		e_client_util_free_string_slist	(GSList *strings);
void		e_client_util_free_object_slist	(GSList *objects);
gchar *		e_client_dup_bus_name		(EClient *client);
void		e_client_set_bus_name		(EClient *client,
						 const gchar *bus_name);


typedef struct _EClientErrorsList EClientErrorsList;

/**
 * EClientErrorsList:
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: This structure is no longer used.
 **/
struct _EClientErrorsList {
	/*< private >*/
	const gchar *name;
	gint err_code;
};

gboolean	e_client_util_unwrap_dbus_error	(GError *dbus_error,
						 GError **client_error,
						 const EClientErrorsList *known_errors,
						 guint known_errors_count,
						 GQuark known_errors_domain,
						 gboolean fail_when_none_matched);

#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_CLIENT_H */
