/*
 * module-outlook-backend.c
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

/* XXX E-D-S currently only supports email access to Outlook.com accounts.
 *     This is not unlike the the built-in collection backend written for
 *     GOA's "IMAP/SMTP" accounts, but I wrote an "outlook" module anyway
 *     as a placeholder with hopes that Microsoft will eventually provide
 *     access to calendar+contacts via CalDAV/CardDAV or even EWS. */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_OUTLOOK_BACKEND \
	(e_outlook_backend_get_type ())
#define E_OUTLOOK_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_OUTLOOK_BACKEND, EOutlookBackend))

/* Just for readability... */
#define METHOD(x) (CAMEL_NETWORK_SECURITY_METHOD_##x)

/* IMAP Configuration Details */
#define OUTLOOK_IMAP_BACKEND_NAME	"imapx"
#define OUTLOOK_IMAP_HOST		"imap-mail.outlook.com"
#define OUTLOOK_IMAP_PORT		993
#define OUTLOOK_IMAP_SECURITY_METHOD	METHOD (SSL_ON_ALTERNATE_PORT)

/* SMTP Configuration Details */
#define OUTLOOK_SMTP_BACKEND_NAME	"smtp"
#define OUTLOOK_SMTP_HOST		"smtp-mail.outlook.com"
#define OUTLOOK_SMTP_PORT		587
#define OUTLOOK_SMTP_SECURITY_METHOD	METHOD (STARTTLS_ON_STANDARD_PORT)

typedef struct _EOutlookBackend EOutlookBackend;
typedef struct _EOutlookBackendClass EOutlookBackendClass;

typedef struct _EOutlookBackendFactory EOutlookBackendFactory;
typedef struct _EOutlookBackendFactoryClass EOutlookBackendFactoryClass;

struct _EOutlookBackend {
	ECollectionBackend parent;
};

struct _EOutlookBackendClass {
	ECollectionBackendClass parent_class;
};

struct _EOutlookBackendFactory {
	ECollectionBackendFactory parent;
};

struct _EOutlookBackendFactoryClass {
	ECollectionBackendFactoryClass parent_class;
};

/* Module Entry Points */
void e_module_load (GTypeModule *type_module);
void e_module_unload (GTypeModule *type_module);

/* Forward Declarations */
GType e_outlook_backend_get_type (void);
GType e_outlook_backend_factory_get_type (void);

G_DEFINE_DYNAMIC_TYPE (
	EOutlookBackend,
	e_outlook_backend,
	E_TYPE_COLLECTION_BACKEND)

G_DEFINE_DYNAMIC_TYPE (
	EOutlookBackendFactory,
	e_outlook_backend_factory,
	E_TYPE_COLLECTION_BACKEND_FACTORY)

static void
outlook_backend_child_added (ECollectionBackend *backend,
                             ESource *child_source)
{
	ESource *collection_source;
	const gchar *extension_name;
	gboolean is_mail = FALSE;

	/* Chain up to parent's child_added() method. */
	E_COLLECTION_BACKEND_CLASS (e_outlook_backend_parent_class)->
		child_added (backend, child_source);

	collection_source = e_backend_get_source (E_BACKEND (backend));

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	is_mail |= e_source_has_extension (child_source, extension_name);

	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	is_mail |= e_source_has_extension (child_source, extension_name);

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
		 *     have been modified to use a non-Outlook server. */
		if (auth_child_user == NULL)
			e_source_authentication_set_user (
				auth_child_extension,
				collection_identity);
	}
}

static void
e_outlook_backend_class_init (EOutlookBackendClass *class)
{
	ECollectionBackendClass *backend_class;

	backend_class = E_COLLECTION_BACKEND_CLASS (class);
	backend_class->child_added = outlook_backend_child_added;
}

static void
e_outlook_backend_class_finalize (EOutlookBackendClass *class)
{
}

static void
e_outlook_backend_init (EOutlookBackend *backend)
{
}

static void
outlook_backend_prepare_mail_account_source (ESource *source)
{
	ESourceCamel *camel_extension;
	ESourceExtension *extension;
	CamelSettings *settings;
	const gchar *backend_name;
	const gchar *extension_name;

	backend_name = OUTLOOK_IMAP_BACKEND_NAME;

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
		OUTLOOK_IMAP_HOST);

	camel_network_settings_set_port (
		CAMEL_NETWORK_SETTINGS (settings),
		OUTLOOK_IMAP_PORT);

	camel_network_settings_set_security_method (
		CAMEL_NETWORK_SETTINGS (settings),
		OUTLOOK_IMAP_SECURITY_METHOD);
}

static void
outlook_backend_prepare_mail_transport_source (ESource *source)
{
	ESourceCamel *camel_extension;
	ESourceExtension *extension;
	CamelSettings *settings;
	const gchar *backend_name;
	const gchar *extension_name;

	backend_name = OUTLOOK_SMTP_BACKEND_NAME;

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
		OUTLOOK_SMTP_HOST);

	camel_network_settings_set_port (
		CAMEL_NETWORK_SETTINGS (settings),
		OUTLOOK_SMTP_PORT);

	camel_network_settings_set_security_method (
		CAMEL_NETWORK_SETTINGS (settings),
		OUTLOOK_SMTP_SECURITY_METHOD);
}

static void
outlook_backend_factory_prepare_mail (ECollectionBackendFactory *factory,
                                      ESource *mail_account_source,
                                      ESource *mail_identity_source,
                                      ESource *mail_transport_source)
{
	ECollectionBackendFactoryClass *parent_class;

	/* Chain up to parent's prepare_mail() method. */
	parent_class =
		E_COLLECTION_BACKEND_FACTORY_CLASS (
		e_outlook_backend_factory_parent_class);
	parent_class->prepare_mail (
		factory,
		mail_account_source,
		mail_identity_source,
		mail_transport_source);

	outlook_backend_prepare_mail_account_source (mail_account_source);
	outlook_backend_prepare_mail_transport_source (mail_transport_source);
}

static void
e_outlook_backend_factory_class_init (EOutlookBackendFactoryClass *class)
{
	ECollectionBackendFactoryClass *factory_class;

	factory_class = E_COLLECTION_BACKEND_FACTORY_CLASS (class);
	factory_class->factory_name = "outlook";
	factory_class->backend_type = E_TYPE_OUTLOOK_BACKEND;
	factory_class->prepare_mail = outlook_backend_factory_prepare_mail;
}

static void
e_outlook_backend_factory_class_finalize (EOutlookBackendFactoryClass *class)
{
}

static void
e_outlook_backend_factory_init (EOutlookBackendFactory *factory)
{
}

G_MODULE_EXPORT void
e_module_load (GTypeModule *type_module)
{
	e_outlook_backend_register_type (type_module);
	e_outlook_backend_factory_register_type (type_module);
}

G_MODULE_EXPORT void
e_module_unload (GTypeModule *type_module)
{
}

