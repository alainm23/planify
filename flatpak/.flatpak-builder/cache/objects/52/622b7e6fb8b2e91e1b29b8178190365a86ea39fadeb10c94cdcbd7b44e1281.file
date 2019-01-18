/*
 * e-source-selectable.h
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

#ifndef E_SOURCE_SELECTABLE_H
#define E_SOURCE_SELECTABLE_H

#include <libedataserver/e-source-backend.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_SELECTABLE \
	(e_source_selectable_get_type ())
#define E_SOURCE_SELECTABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_SELECTABLE, ESourceSelectable))
#define E_SOURCE_SELECTABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_SELECTABLE, ESourceSelectableClass))
#define E_IS_SOURCE_SELECTABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_SELECTABLE))
#define E_IS_SOURCE_SELECTABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_SELECTABLE))
#define E_SOURCE_SELECTABLE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_SELECTABLE, ESourceSelectableClass))

G_BEGIN_DECLS

typedef struct _ESourceSelectable ESourceSelectable;
typedef struct _ESourceSelectableClass ESourceSelectableClass;
typedef struct _ESourceSelectablePrivate ESourceSelectablePrivate;

/**
 * ESourceSelectable:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceSelectable {
	/*< private >*/
	ESourceBackend parent;
	ESourceSelectablePrivate *priv;
};

struct _ESourceSelectableClass {
	ESourceBackendClass parent_class;
};

GType		e_source_selectable_get_type	(void) G_GNUC_CONST;
const gchar *	e_source_selectable_get_color	(ESourceSelectable *extension);
gchar *		e_source_selectable_dup_color	(ESourceSelectable *extension);
void		e_source_selectable_set_color	(ESourceSelectable *extension,
						 const gchar *color);
gboolean	e_source_selectable_get_selected
						(ESourceSelectable *extension);
void		e_source_selectable_set_selected
						(ESourceSelectable *extension,
						 gboolean selected);

G_END_DECLS

#endif /* E_SOURCE_SELECTABLE_H */
