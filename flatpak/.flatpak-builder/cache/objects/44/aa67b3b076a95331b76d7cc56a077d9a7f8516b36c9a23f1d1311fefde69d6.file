/*
 * e-backend.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_BACKEND_H
#define E_BACKEND_H

#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_BACKEND \
	(e_backend_get_type ())
#define E_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BACKEND, EBackend))
#define E_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BACKEND, EBackendClass))
#define E_IS_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BACKEND))
#define E_IS_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BACKEND))
#define E_BACKEND_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BACKEND, EBackendClass))

G_BEGIN_DECLS

/* forward declaration */
struct _EUserPrompter;

typedef struct _EBackend EBackend;
typedef struct _EBackendClass EBackendClass;
typedef struct _EBackendPrivate EBackendPrivate;

/**
 * EBackend:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EBackend {
	/*< private >*/
	GObject parent;
	EBackendPrivate *priv;
};

/**
 * EBackendClass:
 * @authenticate_sync: Authenticate synchronously
 * @get_destination_address: Fetch the destination address
 * @prepare_shutdown: Prepare for shutdown
 *
 * Base class structure for the #EBackend class
 *
 * Since: 3.4
 **/
struct _EBackendClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/
	/* Methods */
	gboolean	(*get_destination_address)
						(EBackend *backend,
						 gchar **host,
						 guint16 *port);
	void		(*prepare_shutdown)	(EBackend *backend);

	ESourceAuthenticationResult
			(*authenticate_sync)	(EBackend *backend,
						 const ENamedParameters *credentials,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GCancellable *cancellable,
						 GError **error);

	/*< private >*/
	gpointer reserved[11];
};

GType		e_backend_get_type		(void) G_GNUC_CONST;
gboolean	e_backend_get_online		(EBackend *backend);
void		e_backend_set_online		(EBackend *backend,
						 gboolean online);
void		e_backend_ensure_online_state_updated
						(EBackend *backend,
						 GCancellable *cancellable);
ESource *	e_backend_get_source		(EBackend *backend);
GSocketConnectable *
		e_backend_ref_connectable	(EBackend *backend);
void		e_backend_set_connectable	(EBackend *backend,
						 GSocketConnectable *connectable);
GMainContext *	e_backend_ref_main_context	(EBackend *backend);
gboolean	e_backend_credentials_required_sync
						(EBackend *backend,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error,
						 GCancellable *cancellable,
						 GError **error);
void		e_backend_credentials_required	(EBackend *backend,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_backend_credentials_required_finish
						(EBackend *backend,
						 GAsyncResult *result,
						 GError **error);
void		e_backend_schedule_credentials_required
						(EBackend *backend,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error,
						 GCancellable *cancellable,
						 const gchar *who_calls);
void		e_backend_schedule_authenticate	(EBackend *backend,
						 const ENamedParameters *credentials);
void		e_backend_ensure_source_status_connected
						(EBackend *backend);
struct _EUserPrompter *
		e_backend_get_user_prompter	(EBackend *backend);
ETrustPromptResponse
		e_backend_trust_prompt_sync	(EBackend *backend,
						 const ENamedParameters *parameters,
						 GCancellable *cancellable,
						 GError **error);
void		e_backend_trust_prompt		(EBackend *backend,
						 const ENamedParameters *parameters,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
ETrustPromptResponse
		e_backend_trust_prompt_finish	(EBackend *backend,
						 GAsyncResult *result,
						 GError **error);

gboolean	e_backend_get_destination_address
						(EBackend *backend,
						 gchar **host,
						 guint16 *port);
gboolean	e_backend_is_destination_reachable
						(EBackend *backend,
						 GCancellable *cancellable,
						 GError **error);
void		e_backend_prepare_shutdown	(EBackend *backend);

G_END_DECLS

#endif /* E_BACKEND_H */
