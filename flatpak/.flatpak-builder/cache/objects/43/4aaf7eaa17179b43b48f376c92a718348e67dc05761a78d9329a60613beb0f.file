/*
 * e-source-extension.h
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

#ifndef E_SOURCE_EXTENSION_H
#define E_SOURCE_EXTENSION_H

#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_EXTENSION \
	(e_source_extension_get_type ())
#define E_SOURCE_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_EXTENSION, ESourceExtension))
#define E_SOURCE_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_EXTENSION, ESourceExtensionClass))
#define E_IS_SOURCE_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_EXTENSION))
#define E_IS_SOURCE_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_EXTENSION))
#define E_SOURCE_EXTENSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_EXTENSION, ESourceExtensionClass))

G_BEGIN_DECLS

typedef struct _ESourceExtension ESourceExtension;
typedef struct _ESourceExtensionClass ESourceExtensionClass;
typedef struct _ESourceExtensionPrivate ESourceExtensionPrivate;

/**
 * ESourceExtension:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceExtension {
	/*< private >*/
	GObject parent;
	ESourceExtensionPrivate *priv;
};

struct _ESourceExtensionClass {
	GObjectClass parent_class;

	const gchar *name;
};

GType		e_source_extension_get_type	(void) G_GNUC_CONST;
ESource *	e_source_extension_ref_source	(ESourceExtension *extension);
void		e_source_extension_property_lock
						(ESourceExtension *extension);
void		e_source_extension_property_unlock
						(ESourceExtension *extension);

#ifndef EDS_DISABLE_DEPRECATED
ESource *	e_source_extension_get_source	(ESourceExtension *extension);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_SOURCE_EXTENSION_H */
