/*
 * e-source-smime.h
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

#ifndef E_SOURCE_SMIME_H
#define E_SOURCE_SMIME_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_SMIME \
	(e_source_smime_get_type ())
#define E_SOURCE_SMIME(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_SMIME, ESourceSMIME))
#define E_SOURCE_SMIME_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_SMIME, ESourceSMIMEClass))
#define E_IS_SOURCE_SMIME(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_SMIME))
#define E_IS_SOURCE_SMIME_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_SMIME))
#define E_SOURCE_SMIME_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_SMIME, ESourceSMIMEClass))

/**
 * E_SOURCE_EXTENSION_SMIME:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceSMIME.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_SMIME "Secure MIME (S/MIME)"

G_BEGIN_DECLS

typedef struct _ESourceSMIME ESourceSMIME;
typedef struct _ESourceSMIMEClass ESourceSMIMEClass;
typedef struct _ESourceSMIMEPrivate ESourceSMIMEPrivate;

/**
 * ESourceSMIME:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceSMIME {
	/*< private >*/
	ESourceExtension parent;
	ESourceSMIMEPrivate *priv;
};

struct _ESourceSMIMEClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_smime_get_type		(void) G_GNUC_CONST;
const gchar *	e_source_smime_get_encryption_certificate
						(ESourceSMIME *extension);
gchar *		e_source_smime_dup_encryption_certificate
						(ESourceSMIME *extension);
void		e_source_smime_set_encryption_certificate
						(ESourceSMIME *extension,
						 const gchar *encryption_certificate);
gboolean	e_source_smime_get_encrypt_by_default
						(ESourceSMIME *extension);
void		e_source_smime_set_encrypt_by_default
						(ESourceSMIME *extension,
						 gboolean encrypt_by_default);
gboolean	e_source_smime_get_encrypt_to_self
						(ESourceSMIME *extension);
void		e_source_smime_set_encrypt_to_self
						(ESourceSMIME *extension,
						 gboolean encrypt_to_self);
const gchar *	e_source_smime_get_signing_algorithm
						(ESourceSMIME *extension);
gchar *		e_source_smime_dup_signing_algorithm
						(ESourceSMIME *extension);
void		e_source_smime_set_signing_algorithm
						(ESourceSMIME *extension,
						 const gchar *signing_algorithm);
const gchar *	e_source_smime_get_signing_certificate
						(ESourceSMIME *extension);
gchar *		e_source_smime_dup_signing_certificate
						(ESourceSMIME *extension);
void		e_source_smime_set_signing_certificate
						(ESourceSMIME *extension,
						 const gchar *signing_certificate);
gboolean	e_source_smime_get_sign_by_default
						(ESourceSMIME *extension);
void		e_source_smime_set_sign_by_default
						(ESourceSMIME *extension,
						 gboolean sign_by_default);

G_END_DECLS

#endif /* E_SOURCE_SMIME_H */

