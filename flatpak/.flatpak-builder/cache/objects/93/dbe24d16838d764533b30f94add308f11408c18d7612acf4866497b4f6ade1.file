/*
 * e-source-autoconfig.h
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

#ifndef E_SOURCE_AUTOCONFIG_H
#define E_SOURCE_AUTOCONFIG_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_AUTOCONFIG \
	(e_source_autoconfig_get_type ())
#define E_SOURCE_AUTOCONFIG(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_AUTOCONFIG, ESourceAutoconfig))
#define E_SOURCE_AUTOCONFIG_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_AUTOCONFIG, ESourceAutoconfigClass))
#define E_IS_SOURCE_AUTOCONFIG(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_AUTOCONFIG))
#define E_IS_SOURCE_AUTOCONFIG_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_AUTOCONFIG))
#define E_SOURCE_AUTOCONFIG_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_AUTOCONFIG, ESourceAutoconfigClass))

/**
 * E_SOURCE_EXTENSION_AUTOCONFIG:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceAutoconfig.  This is also used as a group name in key files.
 *
 * Since: 3.24
 **/
#define E_SOURCE_EXTENSION_AUTOCONFIG "Autoconfig"

G_BEGIN_DECLS

typedef struct _ESourceAutoconfig ESourceAutoconfig;
typedef struct _ESourceAutoconfigClass ESourceAutoconfigClass;
typedef struct _ESourceAutoconfigPrivate ESourceAutoconfigPrivate;

/**
 * ESourceAutoconfig:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.24
 **/
struct _ESourceAutoconfig {
	/*< private >*/
	ESourceExtension parent;
	ESourceAutoconfigPrivate *priv;
};

struct _ESourceAutoconfigClass {
	ESourceExtensionClass parent_class;
};

GType			e_source_autoconfig_get_type
						(void) G_GNUC_CONST;
const gchar *		e_source_autoconfig_get_revision
						(ESourceAutoconfig *extension);
gchar *			e_source_autoconfig_dup_revision
						(ESourceAutoconfig *extension);
void			e_source_autoconfig_set_revision
						(ESourceAutoconfig *extension,
						 const gchar *revision);

G_END_DECLS

#endif /* E_SOURCE_AUTOCONFIG_H */
