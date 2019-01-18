/*
 * e-extension.h
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

#ifndef E_EXTENSION_H
#define E_EXTENSION_H

#include <libedataserver/e-extensible.h>

/* Standard GObject macros */
#define E_TYPE_EXTENSION \
	(e_extension_get_type ())
#define E_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_EXTENSION, EExtension))
#define E_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_EXTENSION, EExtensionClass))
#define E_IS_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_EXTENSION))
#define E_IS_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_EXTENSION))
#define E_EXTENSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_EXTENSION, EExtensionClass))

G_BEGIN_DECLS

typedef struct _EExtension EExtension;
typedef struct _EExtensionClass EExtensionClass;
typedef struct _EExtensionPrivate EExtensionPrivate;

/**
 * EExtension:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EExtension {
	/*< private >*/
	GObject parent;
	EExtensionPrivate *priv;
};

struct _EExtensionClass {
	GObjectClass parent_class;

	/* The type to extend. */
	GType extensible_type;
};

GType		e_extension_get_type		(void) G_GNUC_CONST;
EExtensible *	e_extension_get_extensible	(EExtension *extension);

G_END_DECLS

#endif /* E_EXTENSION_H */
