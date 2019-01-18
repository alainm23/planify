/*
 * e-source-uoa.h
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

#ifndef E_SOURCE_UOA_H
#define E_SOURCE_UOA_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_UOA \
	(e_source_uoa_get_type ())
#define E_SOURCE_UOA(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_UOA, ESourceUoa))
#define E_SOURCE_UOA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_UOA, ESourceUoaClass))
#define E_IS_SOURCE_UOA(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_UOA))
#define E_IS_SOURCE_UOA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_UOA))
#define E_SOURCE_UOA_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_UOA, ESourceUoaClass))

/**
 * E_SOURCE_EXTENSION_UOA:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceUoa.  This is also used as a group name in key files.
 *
 * Since: 3.8
 **/
#define E_SOURCE_EXTENSION_UOA "Ubuntu Online Accounts"

G_BEGIN_DECLS

typedef struct _ESourceUoa ESourceUoa;
typedef struct _ESourceUoaClass ESourceUoaClass;
typedef struct _ESourceUoaPrivate ESourceUoaPrivate;

/**
 * ESourceUoa:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _ESourceUoa {
	/*< private >*/
	ESourceExtension parent;
	ESourceUoaPrivate *priv;
};

struct _ESourceUoaClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_uoa_get_type		(void) G_GNUC_CONST;
guint		e_source_uoa_get_account_id	(ESourceUoa *extension);
void		e_source_uoa_set_account_id	(ESourceUoa *extension,
						 guint account_id);

G_END_DECLS

#endif /* E_SOURCE_UOA */

