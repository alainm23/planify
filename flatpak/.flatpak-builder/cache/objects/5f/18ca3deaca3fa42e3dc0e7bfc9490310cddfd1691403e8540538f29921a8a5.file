/*
 * e-source-openpgp.h
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

#ifndef E_SOURCE_OPENPGP_H
#define E_SOURCE_OPENPGP_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_OPENPGP \
	(e_source_openpgp_get_type ())
#define E_SOURCE_OPENPGP(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_OPENPGP, ESourceOpenPGP))
#define E_SOURCE_OPENPGP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_OPENPGP, ESourceOpenPGPClass))
#define E_IS_SOURCE_OPENPGP(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_OPENPGP))
#define E_IS_SOURCE_OPENPGP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_OPENPGP))
#define E_SOURCE_OPENPGP_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_OPENPGP, ESourceOpenPGPClass))

/**
 * E_SOURCE_EXTENSION_OPENPGP:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceOpenPGP.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_OPENPGP "Pretty Good Privacy (OpenPGP)"

G_BEGIN_DECLS

typedef struct _ESourceOpenPGP ESourceOpenPGP;
typedef struct _ESourceOpenPGPClass ESourceOpenPGPClass;
typedef struct _ESourceOpenPGPPrivate ESourceOpenPGPPrivate;

/**
 * ESourceOpenPGP:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceOpenPGP {
	/*< private >*/
	ESourceExtension parent;
	ESourceOpenPGPPrivate *priv;
};

struct _ESourceOpenPGPClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_openpgp_get_type	(void) G_GNUC_CONST;
gboolean	e_source_openpgp_get_always_trust
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_always_trust
						(ESourceOpenPGP *extension,
						 gboolean always_trust);
gboolean	e_source_openpgp_get_encrypt_to_self
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_encrypt_to_self
						(ESourceOpenPGP *extension,
						 gboolean encrypt_to_self);
const gchar *	e_source_openpgp_get_key_id	(ESourceOpenPGP *extension);
gchar *		e_source_openpgp_dup_key_id	(ESourceOpenPGP *extension);
void		e_source_openpgp_set_key_id	(ESourceOpenPGP *extension,
						 const gchar *key_id);
const gchar *	e_source_openpgp_get_signing_algorithm
						(ESourceOpenPGP *extension);
gchar *		e_source_openpgp_dup_signing_algorithm
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_signing_algorithm
						(ESourceOpenPGP *extension,
						 const gchar *signing_algorithm);
gboolean	e_source_openpgp_get_sign_by_default
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_sign_by_default
						(ESourceOpenPGP *extension,
						 gboolean sign_by_default);
gboolean	e_source_openpgp_get_encrypt_by_default
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_encrypt_by_default
						(ESourceOpenPGP *extension,
						 gboolean encrypt_by_default);
gboolean	e_source_openpgp_get_prefer_inline
						(ESourceOpenPGP *extension);
void		e_source_openpgp_set_prefer_inline
						(ESourceOpenPGP *extension,
						 gboolean prefer_inline);

G_END_DECLS

#endif /* E_SOURCE_OPENPGP_H */

