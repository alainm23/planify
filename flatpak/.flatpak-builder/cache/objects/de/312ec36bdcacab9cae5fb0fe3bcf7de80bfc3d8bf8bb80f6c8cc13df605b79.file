/*
 * e-module.h
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

#ifndef E_MODULE_H
#define E_MODULE_H

#include <gmodule.h>
#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_MODULE \
	(e_module_get_type ())
#define E_MODULE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_MODULE, EModule))
#define E_MODULE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_MODULE, EModuleClass))
#define E_IS_MODULE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_MODULE))
#define E_IS_MODULE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_MODULE))
#define E_MODULE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_MODULE, EModuleClass))

G_BEGIN_DECLS

typedef struct _EModule EModule;
typedef struct _EModuleClass EModuleClass;
typedef struct _EModulePrivate EModulePrivate;

/**
 * EModule:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EModule {
	/*< private >*/
	GTypeModule parent;
	EModulePrivate *priv;
};

struct _EModuleClass {
	GTypeModuleClass parent_class;
};

GType		e_module_get_type		(void) G_GNUC_CONST;
EModule *	e_module_new			(const gchar *filename);
const gchar *	e_module_get_filename		(EModule *module);
EModule *	e_module_load_file		(const gchar *filename);
GList *		e_module_load_all_in_directory	(const gchar *dirname);

G_END_DECLS

#endif /* E_MODULE_H */
