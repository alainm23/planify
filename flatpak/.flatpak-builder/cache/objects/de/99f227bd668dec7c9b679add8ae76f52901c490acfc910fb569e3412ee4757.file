/*
 * e-source-mail-account.h
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

#ifndef E_SOURCE_MAIL_ACCOUNT_H
#define E_SOURCE_MAIL_ACCOUNT_H

#include <libedataserver/e-source-backend.h>
#include <libedataserver/e-source-enums.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_ACCOUNT \
	(e_source_mail_account_get_type ())
#define E_SOURCE_MAIL_ACCOUNT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_ACCOUNT, ESourceMailAccount))
#define E_SOURCE_MAIL_ACCOUNT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_ACCOUNT, ESourceMailAccountClass))
#define E_IS_SOURCE_MAIL_ACCOUNT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_ACCOUNT))
#define E_IS_SOURCE_MAIL_ACCOUNT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_ACCOUNT))
#define E_SOURCE_MAIL_ACCOUNT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_ACCOUNT, ESourceMailAccountClass))

/**
 * E_SOURCE_EXTENSION_MAIL_ACCOUNT:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailAccount.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_ACCOUNT "Mail Account"

G_BEGIN_DECLS

typedef struct _ESourceMailAccount ESourceMailAccount;
typedef struct _ESourceMailAccountClass ESourceMailAccountClass;
typedef struct _ESourceMailAccountPrivate ESourceMailAccountPrivate;

/**
 * ESourceMailAccount:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceMailAccount {
	/*< private >*/
	ESourceBackend parent;
	ESourceMailAccountPrivate *priv;
};

struct _ESourceMailAccountClass {
	ESourceBackendClass parent_class;
};

GType		e_source_mail_account_get_type
					(void) G_GNUC_CONST;
const gchar *	e_source_mail_account_get_identity_uid
					(ESourceMailAccount *extension);
gchar *		e_source_mail_account_dup_identity_uid
					(ESourceMailAccount *extension);
void		e_source_mail_account_set_identity_uid
					(ESourceMailAccount *extension,
					 const gchar *identity_uid);
const gchar *	e_source_mail_account_get_archive_folder
					(ESourceMailAccount *extension);
gchar *		e_source_mail_account_dup_archive_folder
					(ESourceMailAccount *extension);
void		e_source_mail_account_set_archive_folder
					(ESourceMailAccount *extension,
					 const gchar *archive_folder);
gboolean	e_source_mail_account_get_needs_initial_setup
					(ESourceMailAccount *extension);
void		e_source_mail_account_set_needs_initial_setup
					(ESourceMailAccount *extension,
					 gboolean needs_initial_setup);
EThreeState	e_source_mail_account_get_mark_seen
					(ESourceMailAccount *extension);
void		e_source_mail_account_set_mark_seen
					(ESourceMailAccount *extension,
					 EThreeState mark_seen);
gint		e_source_mail_account_get_mark_seen_timeout
					(ESourceMailAccount *extension);
void		e_source_mail_account_set_mark_seen_timeout
					(ESourceMailAccount *extension,
					 gint timeout);

G_END_DECLS

#endif /* E_SOURCE_MAIL_ACCOUNT_H */
