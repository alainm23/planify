/*
 * e-extensible.h
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

#ifndef E_EXTENSIBLE_H
#define E_EXTENSIBLE_H

#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_EXTENSIBLE \
	(e_extensible_get_type ())
#define E_EXTENSIBLE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_EXTENSIBLE, EExtensible))
#define E_EXTENSIBLE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_EXTENSIBLE, EExtensibleInterface))
#define E_IS_EXTENSIBLE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_EXTENSIBLE))
#define E_IS_EXTENSIBLE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_EXTENSIBLE))
#define E_EXTENSIBLE_GET_INTERFACE(obj) \
	(G_TYPE_INSTANCE_GET_INTERFACE \
	((obj), E_TYPE_EXTENSIBLE, EExtensibleInterface))

G_BEGIN_DECLS

typedef struct _EExtensible EExtensible;
typedef struct _EExtensibleInterface EExtensibleInterface;

struct _EExtensibleInterface {
	GTypeInterface parent_interface;
};

GType		e_extensible_get_type		(void) G_GNUC_CONST;
void		e_extensible_load_extensions	(EExtensible *extensible);
GList *		e_extensible_list_extensions	(EExtensible *extensible,
						 GType extension_type);

G_END_DECLS

#endif /* E_EXTENSIBLE_H */
