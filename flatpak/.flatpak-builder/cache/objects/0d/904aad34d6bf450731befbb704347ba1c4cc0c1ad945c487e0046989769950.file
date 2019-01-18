/*
 * e-source-camel.h
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

#ifndef E_SOURCE_CAMEL_H
#define E_SOURCE_CAMEL_H

#include <camel/camel.h>
#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_CAMEL \
	(e_source_camel_get_type ())
#define E_SOURCE_CAMEL(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_CAMEL, ESourceCamel))
#define E_SOURCE_CAMEL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_CAMEL, ESourceCamelClass))
#define E_IS_SOURCE_CAMEL(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_CAMEL))
#define E_IS_SOURCE_CAMEL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_CAMEL))
#define E_SOURCE_CAMEL_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_CAMEL, ESourceCamelClass))

G_BEGIN_DECLS

typedef struct _ESourceCamel ESourceCamel;
typedef struct _ESourceCamelClass ESourceCamelClass;
typedef struct _ESourceCamelPrivate ESourceCamelPrivate;

/**
 * ESourceCamel:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceCamel {
	/*< private >*/
	ESourceExtension parent;
	ESourceCamelPrivate *priv;
};

struct _ESourceCamelClass {
	ESourceExtensionClass parent_class;

	/* Same idea as in CamelServiceClass. */
	GType settings_type;
};

GType		e_source_camel_get_type		(void) G_GNUC_CONST;
void		e_source_camel_register_types	(void);
GType		e_source_camel_generate_subtype	(const gchar *protocol,
						 GType settings_type);
CamelSettings *	e_source_camel_get_settings	(ESourceCamel *extension);
const gchar *	e_source_camel_get_type_name	(const gchar *protocol);
const gchar *	e_source_camel_get_extension_name
						(const gchar *protocol);
void		e_source_camel_configure_service
						(ESource *source,
						 CamelService *service);

G_END_DECLS

#endif /* E_SOURCE_CAMEL_H */
