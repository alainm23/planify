/*
 * module-yahoo-backend.c
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

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_YAHOO_BACKEND \
	(e_yahoo_backend_get_type ())
#define E_YAHOO_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_YAHOO_BACKEND, EYahooBackend))

/* Just for readability... */
#define METHOD(x) (CAMEL_NETWORK_SECURITY_METHOD_##x)

/* IMAP Configuration Details */
#define YAHOO_IMAP_BACKEND_NAME		"imapx"
#define YAHOO_IMAP_HOST			"imap.mail.yahoo.com"
#define YAHOO_IMAP_PORT			993
#define YAHOO_IMAP_SECURITY_METHOD	METHOD (SSL_ON_ALTERNATE_PORT)

/* SMTP Configuration Details */
#define YAHOO_SMTP_BACKEND_NAME		"smtp"
#define YAHOO_SMTP_HOST			"smtp.mail.yahoo.com"
#define YAHOO_SMTP_PORT			465
#define YAHOO_SMTP_SECURITY_METHOD	METHOD (SSL_ON_ALTERNATE_PORT)

/* WebDAV Configuration Details */
#define YAHOO_WEBDAV_URL		"https://caldav.calendar.yahoo.com/dav/"


typedef struct _EYahooBackend EYahooBackend;
typedef struct _EYahooBackendClass EYahooBackendClass;

typedef struct _EYahooBackendFactory EYahooBackendFactory;
typedef struct _EYahooBackendFactoryClass EYahooBackendFactoryClass;

struct _EYahooBackend {
	EWebDAVCollectionBackend parent;
	GWeakRef mail_identity_source;
};

struct _EYahooBackendClass {
	EWebDAVCollectionBackendClass parent_class;
};

struct _EYahooBackendFactory {
	ECollectionBackendFactory parent;
};

struct _EYahooBackendFactoryClass {
	ECollectionBackendFactoryClass parent_class;
};

/* Module Entry Points */
void e_module_load (GTypeModule *type_module);
void e_module_unload (GTypeModule *type_module);

/* Forward Declarations */
GType e_yahoo_backend_get_type (void);
GType e_yahoo_backend_factory_get_type (void);

G_DEFINE_DYNAMIC_TYPE (
	EYahooBackend,
	e_yahoo_backend,
	E_TYPE_WEBDAV_COLLECTION_BACKEND)

G_DEFINE_DYNAMIC_TYPE (
	EYahooBackendFactory,
	e_yahoo_backend_factory,
	E_TYPE_COLLECTION_BACKEND_FACTORY)

static ESourceAuthenticationResult
yahoo_backend_authenticate_sync (EBackend *backend,
				 const ENamedParameters *credentials,
				 gchar **out_certificate_pem,
				 GTlsCertificateFlags *out_certificate_errors,
				 GCancellable *cancellable,
				 GError **error)
{
	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), E_SOURCE_AUTHENTICATION_ERROR);

	return e_webdav_collection_backend_discover_sync (E_WEBDAV_COLLECTION_BACKEND (backend),
		YAHOO_WEBDAV_URL, YAHOO_WEBDAV_URL, credentials,
		out_certificate_pem, out_certificate_errors, cancellable, error);
}

static void
yahoo_backend_child_added (ECollectionBackend *backend,
                           ESource *child_source)
{
	EYahooBackend *yahoo_backend;
	ESource *collection_source;
	const gchar *extension_name;
	gboolean is_mail = FALSE;

	/* Chain up to parent's child_added() method. */
	E_COLLECTION_BACKEND_CLASS (e_yahoo_backend_parent_class)->
		child_added (backend, child_source);

	yahoo_backend = E_YAHOO_BACKEND (backend);
	collection_source = e_backend_get_source (E_BACKEND (backend));

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	is_mail |= e_source_has_extension (child_source, extension_name);

	/* Take special note of the mail identity source.
	 * We need it to build the calendar CalDAV path. */
	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	if (e_source_has_extension (child_source, extension_name)) {
		GWeakRef *weak_ref;

		weak_ref = &yahoo_backend->mail_identity_source;
		g_weak_ref_set (weak_ref, child_source);
		is_mail = TRUE;
	}

	extension_name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
	is_mail |= e_source_has_extension (child_source, extension_name);

	/* Synchronize mail-related user with the collection identity. */
	extension_name = E_SOURCE_EXTENSION_AUTHENTICATION;
	if (is_mail && e_source_has_extension (child_source, extension_name)) {
		ESourceAuthentication *auth_child_extension;
		ESourceCollection *collection_extension;
		const gchar *collection_identity;
		const gchar *auth_child_user;

		extension_name = E_SOURCE_EXTENSION_COLLECTION;
		collection_extension = e_source_get_extension (
			collection_source, extension_name);
		collection_identity = e_source_collection_get_identity (
			collection_extension);

		extension_name = E_SOURCE_EXTENSION_AUTHENTICATION;
		auth_child_extension = e_source_get_extension (
			child_source, extension_name);
		auth_child_user = e_source_authentication_get_user (
			auth_child_extension);

		/* XXX Do not override an existing user name setting.
		 *     The IMAP or (especially) SMTP configuration may
		 *     have been modified to use a non-Yahoo! server. */
		if (auth_child_user == NULL)
			e_source_authentication_set_user (
				auth_child_extension,
				collection_identity);
	}
}

static void
yahoo_backend_finalize (GObject *object)
{
	EYahooBackend *backend = E_YAHOO_BACKEND (object);

	g_weak_ref_clear (&backend->mail_identity_source);

	G_OBJECT_CLASS (e_yahoo_backend_parent_class)->finalize (object);
}

static void
e_yahoo_backend_class_init (EYahooBackendClass *class)
{
	GObjectClass *object_class;
	EBackendClass *backend_class;
	ECollectionBackendClass *collection_backend_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = yahoo_backend_finalize;

	backend_class = E_BACKEND_CLASS (class);
	backend_class->authenticate_sync = yahoo_backend_authenticate_sync;

	collection_backend_class = E_COLLECTION_BACKEND_CLASS (class);
	collection_backend_class->child_added = yahoo_backend_child_added;
}

static void
e_yahoo_backend_class_finalize (EYahooBackendClass *class)
{
}

static void
e_yahoo_backend_init (EYahooBackend *backend)
{
	g_weak_ref_init (&backend->mail_identity_source, NULL);
}

static void
yahoo_backend_prepare_mail_account_source (ESource *source)
{
	ESourceCamel *camel_extension;
	ESourceExtension *extension;
	CamelSettings *settings;
	const gchar *backend_name;
	const gchar *extension_name;

	backend_name = YAHOO_IMAP_BACKEND_NAME;

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	extension = e_source_get_extension (source, extension_name);

	e_source_backend_set_backend_name (
		E_SOURCE_BACKEND (extension), backend_name);

	extension_name = e_source_camel_get_extension_name (backend_name);
	camel_extension = e_source_get_extension (source, extension_name);
	settings = e_source_camel_get_settings (camel_extension);

	/* The "auth-mechanism" should be determined elsewhere. */

	camel_network_settings_set_host (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_IMAP_HOST);

	camel_network_settings_set_port (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_IMAP_PORT);

	camel_network_settings_set_security_method (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_IMAP_SECURITY_METHOD);
}

static void
yahoo_backend_prepare_mail_transport_source (ESource *source)
{
	ESourceCamel *camel_extension;
	ESourceExtension *extension;
	CamelSettings *settings;
	const gchar *backend_name;
	const gchar *extension_name;

	/* Configure the mail transport source. */

	backend_name = YAHOO_SMTP_BACKEND_NAME;

	extension_name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
	extension = e_source_get_extension (source, extension_name);

	e_source_backend_set_backend_name (
		E_SOURCE_BACKEND (extension), backend_name);

	extension_name = e_source_camel_get_extension_name (backend_name);
	camel_extension = e_source_get_extension (source, extension_name);
	settings = e_source_camel_get_settings (camel_extension);

	/* The "auth-mechanism" should be determined elsewhere. */

	camel_network_settings_set_host (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_SMTP_HOST);

	camel_network_settings_set_port (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_SMTP_PORT);

	camel_network_settings_set_security_method (
		CAMEL_NETWORK_SETTINGS (settings),
		YAHOO_SMTP_SECURITY_METHOD);
}

static void
yahoo_backend_factory_prepare_mail (ECollectionBackendFactory *factory,
                                    ESource *mail_account_source,
                                    ESource *mail_identity_source,
                                    ESource *mail_transport_source)
{
	ECollectionBackendFactoryClass *parent_class;

	/* Chain up to parent's prepare_mail() method. */
	parent_class =
		E_COLLECTION_BACKEND_FACTORY_CLASS (
		e_yahoo_backend_factory_parent_class);
	parent_class->prepare_mail (
		factory,
		mail_account_source,
		mail_identity_source,
		mail_transport_source);

	yahoo_backend_prepare_mail_account_source (mail_account_source);
	yahoo_backend_prepare_mail_transport_source (mail_transport_source);
}

static void
e_yahoo_backend_factory_class_init (EYahooBackendFactoryClass *class)
{
	ECollectionBackendFactoryClass *factory_class;

	factory_class = E_COLLECTION_BACKEND_FACTORY_CLASS (class);
	factory_class->factory_name = "yahoo";
	factory_class->backend_type = E_TYPE_YAHOO_BACKEND;
	factory_class->prepare_mail = yahoo_backend_factory_prepare_mail;
}

static void
e_yahoo_backend_factory_class_finalize (EYahooBackendFactoryClass *class)
{
}

static void
e_yahoo_backend_factory_init (EYahooBackendFactory *factory)
{
}

G_MODULE_EXPORT void
e_module_load (GTypeModule *type_module)
{
	e_yahoo_backend_register_type (type_module);
	e_yahoo_backend_factory_register_type (type_module);
}

G_MODULE_EXPORT void
e_module_unload (GTypeModule *type_module)
{
}

