/*
 * e-source.h
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

#ifndef E_SOURCE_H
#define E_SOURCE_H

#include <gio/gio.h>
#include <libedataserver/e-data-server-util.h>
#include <libedataserver/e-source-enums.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE \
	(e_source_get_type ())
#define E_SOURCE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE, ESource))
#define E_SOURCE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE, ESourceClass))
#define E_IS_SOURCE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE))
#define E_IS_SOURCE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE))
#define E_SOURCE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE, ESourceClass))

/**
 * E_SOURCE_PARAM_SETTING:
 *
 * Extends #GParamFlags to indicate the #GObject property is associated
 * with a key file value.  Use this flag when installing #GObject properties
 * in #ESourceExtension subclasses.
 *
 * Since: 3.6
 **/
#define E_SOURCE_PARAM_SETTING (1 << G_PARAM_USER_SHIFT)

/**
 * E_SOURCE_CREDENTIAL_USERNAME:
 *
 * A name of the named parameter used for usernames in credentials,
 * used to authenticate users with e_source_invoke_authenticate_sync()
 * and e_source_invoke_authenticate(). The named parameter is optional,
 * different authentication methods can use different names.
 *
 * Since: 3.16
 **/
#define E_SOURCE_CREDENTIAL_USERNAME "username"

/**
 * E_SOURCE_CREDENTIAL_PASSWORD:
 *
 * A name of the named parameter used for passwords in credentials,
 * used to authenticate users with e_source_invoke_authenticate_sync()
 * and e_source_invoke_authenticate(). The named parameter is optional,
 * different authentication methods can use different names.
 *
 * Since: 3.16
 **/
#define E_SOURCE_CREDENTIAL_PASSWORD "password"

/**
 * E_SOURCE_CREDENTIAL_SSL_TRUST:
 *
 * A name of the named parameter used for SSL/TLS trust in credentials,
 * used to authenticate users with e_source_invoke_authenticate_sync()
 * and e_source_invoke_authenticate(). The named parameter is optional.
 * Its value corresponds to current ESourceWebdav::ssl-trust property,
 * in case the ESource has that extension available. This is required
 * to have up-to-date data on the server side, when the client side
 * just saved the SSL trust change, which might not be propagated
 * into the server (factory) side quickly enough. The key is added into
 * the credentials in e_source_invoke_authenticate() automatically, if the
 * corresponding ESource contain a WebDAV extension and the key
 * is not part of the credentials already.
 *
 * Since: 3.16
 **/
#define E_SOURCE_CREDENTIAL_SSL_TRUST "ssl-trust"

G_BEGIN_DECLS

typedef struct _ESource ESource;
typedef struct _ESourceClass ESourceClass;
typedef struct _ESourcePrivate ESourcePrivate;

/**
 * ESource:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESource {
	/*< private >*/
	GObject parent;
	ESourcePrivate *priv;
};

struct _ESourceClass {
	GObjectClass parent_class;

	/* Signals */
	void		(*changed)		(ESource *source);
	void		(*credentials_required)	(ESource *source,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error);
	void		(* authenticate)	(ESource *source,
						 const ENamedParameters *credentials);

	/* Methods */
	gboolean	(*remove_sync)		(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*remove)		(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*remove_finish)	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*write_sync)		(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*write)		(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*write_finish)		(ESource *source,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*remote_create_sync)	(ESource *source,
						 ESource *scratch_source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*remote_create)	(ESource *source,
						 ESource *scratch_source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*remote_create_finish)	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*remote_delete_sync)	(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*remote_delete)	(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*remote_delete_finish)	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*get_oauth2_access_token_sync)
						(ESource *source,
						 GCancellable *cancellable,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GError **error);
	void		(*get_oauth2_access_token)
						(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*get_oauth2_access_token_finish)
						(ESource *source,
						 GAsyncResult *result,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GError **error);
	gboolean	(*invoke_credentials_required_impl)
						(ESource *source,
						 gpointer dbus_source, /* EDBusSource * */
						 const gchar *arg_reason,
						 const gchar *arg_certificate_pem,
						 const gchar *arg_certificate_errors,
						 const gchar *arg_dbus_error_name,
						 const gchar *arg_dbus_error_message,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*invoke_authenticate_impl)
						(ESource *source,
						 gpointer dbus_source, /* EDBusSource * */
						 const gchar * const *arg_credentials,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*unset_last_credentials_required_arguments_impl)
						(ESource *source,
						 GCancellable *cancellable,
						 GError **error);

	/* Reserved slots. */
	gpointer reserved[6];
};

GType		e_source_get_type		(void) G_GNUC_CONST;
ESource *	e_source_new			(GDBusObject *dbus_object,
						 GMainContext *main_context,
						 GError **error);
ESource *	e_source_new_with_uid		(const gchar *uid,
						 GMainContext *main_context,
						 GError **error);
guint		e_source_hash			(ESource *source);
gboolean	e_source_equal			(ESource *source1,
						 ESource *source2);
void		e_source_changed		(ESource *source);
const gchar *	e_source_get_uid		(ESource *source);
gchar *		e_source_dup_uid		(ESource *source);
const gchar *	e_source_get_parent		(ESource *source);
gchar *		e_source_dup_parent		(ESource *source);
void		e_source_set_parent		(ESource *source,
						 const gchar *parent);
gboolean	e_source_get_enabled		(ESource *source);
void		e_source_set_enabled		(ESource *source,
						 gboolean enabled);
gboolean	e_source_get_writable		(ESource *source);
gboolean	e_source_get_removable		(ESource *source);
gboolean	e_source_get_remote_creatable	(ESource *source);
gboolean	e_source_get_remote_deletable	(ESource *source);
gpointer	e_source_get_extension		(ESource *source,
						 const gchar *extension_name);
gboolean	e_source_has_extension		(ESource *source,
						 const gchar *extension_name);
GDBusObject *	e_source_ref_dbus_object	(ESource *source);
GMainContext *	e_source_ref_main_context	(ESource *source);
const gchar *	e_source_get_display_name	(ESource *source);
gchar *		e_source_dup_display_name	(ESource *source);
void		e_source_set_display_name	(ESource *source,
						 const gchar *display_name);
gchar *		e_source_dup_secret_label	(ESource *source);
gint		e_source_compare_by_display_name
						(ESource *source1,
						 ESource *source2);
gchar *		e_source_to_string		(ESource *source,
						 gsize *length);
gchar *		e_source_parameter_to_key	(const gchar *param_name);
ESourceConnectionStatus
		e_source_get_connection_status	(ESource *source);
void		e_source_set_connection_status	(ESource *source,
						 ESourceConnectionStatus connection_status);
gboolean	e_source_remove_sync		(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_remove			(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_remove_finish		(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_write_sync		(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_write			(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_write_finish		(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_remote_create_sync	(ESource *source,
						 ESource *scratch_source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_remote_create		(ESource *source,
						 ESource *scratch_source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_remote_create_finish	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_remote_delete_sync	(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_remote_delete		(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_remote_delete_finish	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_get_oauth2_access_token_sync
						(ESource *source,
						 GCancellable *cancellable,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GError **error);
void		e_source_get_oauth2_access_token
						(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_get_oauth2_access_token_finish
						(ESource *source,
						 GAsyncResult *result,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GError **error);

/* Password Management */
gboolean	e_source_store_password_sync	(ESource *source,
						 const gchar *password,
						 gboolean permanently,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_store_password		(ESource *source,
						 const gchar *password,
						 gboolean permanently,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_store_password_finish	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_lookup_password_sync	(ESource *source,
						 GCancellable *cancellable,
						 gchar **out_password,
						 GError **error);
void		e_source_lookup_password	(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_lookup_password_finish	(ESource *source,
						 GAsyncResult *result,
						 gchar **out_password,
						 GError **error);
gboolean	e_source_delete_password_sync	(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_delete_password	(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_delete_password_finish	(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_invoke_credentials_required_sync
						(ESource *source,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_invoke_credentials_required
						(ESource *source,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_invoke_credentials_required_finish
						(ESource *source,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_invoke_authenticate_sync
						(ESource *source,
						 const ENamedParameters *credentials,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_invoke_authenticate	(ESource *source,
						 const ENamedParameters *credentials,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_invoke_authenticate_finish
						(ESource *source,
						 GAsyncResult *result,
						 GError **error);
void		e_source_emit_credentials_required
						(ESource *source,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error);
gboolean	e_source_get_last_credentials_required_arguments_sync
						(ESource *source,
						 ESourceCredentialsReason *out_reason,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GError **out_op_error,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_get_last_credentials_required_arguments
						(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_get_last_credentials_required_arguments_finish
						(ESource *source,
						 GAsyncResult *result,
						 ESourceCredentialsReason *out_reason,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GError **out_op_error,
						 GError **error);
gboolean	e_source_unset_last_credentials_required_arguments_sync
						(ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_unset_last_credentials_required_arguments
						(ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_unset_last_credentials_required_arguments_finish
						(ESource *source,
						 GAsyncResult *result,
						 GError **error);

G_END_DECLS

#endif /* E_SOURCE_H */
