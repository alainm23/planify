/*
 * e-source-mail-signature.h
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

#ifndef E_SOURCE_MAIL_SIGNATURE_H
#define E_SOURCE_MAIL_SIGNATURE_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_SIGNATURE \
	(e_source_mail_signature_get_type ())
#define E_SOURCE_MAIL_SIGNATURE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_SIGNATURE, ESourceMailSignature))
#define E_SOURCE_MAIL_SIGNATURE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_SIGNATURE, ESourceMailSignatureClass))
#define E_IS_SOURCE_MAIL_SIGNATURE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_SIGNATURE))
#define E_IS_SOURCE_MAIL_SIGNATURE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_SIGNATURE))
#define E_SOURCE_MAIL_SIGNATURE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_SIGNATURE, ESourceMailSignatureClass))

/**
 * E_SOURCE_EXTENSION_MAIL_SIGNATURE:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailSignature.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_SIGNATURE "Mail Signature"

G_BEGIN_DECLS

typedef struct _ESourceMailSignature ESourceMailSignature;
typedef struct _ESourceMailSignatureClass ESourceMailSignatureClass;
typedef struct _ESourceMailSignaturePrivate ESourceMailSignaturePrivate;

/**
 * ESourceMailSignature:
 *
 * Contains only private data that should be read and manipulated using the
 * function below.
 *
 * Since: 3.6
 **/
struct _ESourceMailSignature {
	/*< private >*/
	ESourceExtension parent;
	ESourceMailSignaturePrivate *priv;
};

struct _ESourceMailSignatureClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_mail_signature_get_type
					(void) G_GNUC_CONST;
GFile *		e_source_mail_signature_get_file
					(ESourceMailSignature *extension);
const gchar *	e_source_mail_signature_get_mime_type
					(ESourceMailSignature *extension);
gchar *		e_source_mail_signature_dup_mime_type
					(ESourceMailSignature *extension);
void		e_source_mail_signature_set_mime_type
					(ESourceMailSignature *extension,
					 const gchar *mime_type);

gboolean	e_source_mail_signature_load_sync
					(ESource *source,
					 gchar **contents,
					 gsize *length,
					 GCancellable *cancellable,
					 GError **error);
void		e_source_mail_signature_load
					(ESource *source,
					 gint io_priority,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	e_source_mail_signature_load_finish
					(ESource *source,
					 GAsyncResult *result,
					 gchar **contents,
					 gsize *length,
					 GError **error);
gboolean	e_source_mail_signature_replace_sync
					(ESource *source,
					 const gchar *contents,
					 gsize length,
					 GCancellable *cancellable,
					 GError **error);
void		e_source_mail_signature_replace
					(ESource *source,
					 const gchar *contents,
					 gsize length,
					 gint io_priority,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	e_source_mail_signature_replace_finish
					(ESource *source,
					 GAsyncResult *result,
					 GError **error);
gboolean	e_source_mail_signature_symlink_sync
					(ESource *source,
					 const gchar *symlink_target,
					 GCancellable *cancellable,
					 GError **error);
void		e_source_mail_signature_symlink
					(ESource *source,
					 const gchar *symlink_target,
					 gint io_priority,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	e_source_mail_signature_symlink_finish
					(ESource *source,
					 GAsyncResult *result,
					 GError **error);

G_END_DECLS

#endif /* E_SOURCE_MAIL_SIGNATURE_H */
