/*
 * e-source-mail-identity.h
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

#ifndef E_SOURCE_MAIL_IDENTITY_H
#define E_SOURCE_MAIL_IDENTITY_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_IDENTITY \
	(e_source_mail_identity_get_type ())
#define E_SOURCE_MAIL_IDENTITY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_IDENTITY, ESourceMailIdentity))
#define E_SOURCE_MAIL_IDENTITY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_IDENTITY, ESourceMailIdentityClass))
#define E_IS_SOURCE_MAIL_IDENTITY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_IDENTITY))
#define E_IS_SOURCE_MAIL_IDENTITY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_IDENTITY))
#define E_SOURCE_MAIL_IDENTITY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_IDENTITY, ESourceMailIdentityClass))

/**
 * E_SOURCE_EXTENSION_MAIL_IDENTITY:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailIdentity.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_IDENTITY "Mail Identity"

G_BEGIN_DECLS

typedef struct _ESourceMailIdentity ESourceMailIdentity;
typedef struct _ESourceMailIdentityClass ESourceMailIdentityClass;
typedef struct _ESourceMailIdentityPrivate ESourceMailIdentityPrivate;

/**
 * ESourceMailIdentity:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceMailIdentity {
	/*< private >*/
	ESourceExtension parent;
	ESourceMailIdentityPrivate *priv;
};

struct _ESourceMailIdentityClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_mail_identity_get_type
					(void) G_GNUC_CONST;
const gchar *	e_source_mail_identity_get_address
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_address
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_address
					(ESourceMailIdentity *extension,
					 const gchar *address);
const gchar *	e_source_mail_identity_get_name
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_name
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_name
					(ESourceMailIdentity *extension,
					 const gchar *name);
const gchar *	e_source_mail_identity_get_organization
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_organization
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_organization
					(ESourceMailIdentity *extension,
					 const gchar *organization);
const gchar *	e_source_mail_identity_get_reply_to
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_reply_to
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_reply_to
					(ESourceMailIdentity *extension,
					 const gchar *reply_to);
const gchar *	e_source_mail_identity_get_signature_uid
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_signature_uid
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_signature_uid
					(ESourceMailIdentity *extension,
					 const gchar *signature_uid);
const gchar *	e_source_mail_identity_get_aliases
					(ESourceMailIdentity *extension);
gchar *		e_source_mail_identity_dup_aliases
					(ESourceMailIdentity *extension);
void		e_source_mail_identity_set_aliases
					(ESourceMailIdentity *extension,
					 const gchar *aliases);
GHashTable *	e_source_mail_identity_get_aliases_as_hash_table
					(ESourceMailIdentity *extension);

G_END_DECLS

#endif /* E_SOURCE_MAIL_IDENTITY_H */
