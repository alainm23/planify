/*
 * e-source-backend.h
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

#ifndef E_SOURCE_BACKEND_H
#define E_SOURCE_BACKEND_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_BACKEND \
	(e_source_backend_get_type ())
#define E_SOURCE_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_BACKEND, ESourceBackend))
#define E_SOURCE_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_BACKEND, ESourceBackendClass))
#define E_IS_SOURCE_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_BACKEND))
#define E_IS_SOURCE_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_BACKEND))
#define E_SOURCE_BACKEND_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_BACKEND, ESourceBackendClass))

G_BEGIN_DECLS

typedef struct _ESourceBackend ESourceBackend;
typedef struct _ESourceBackendClass ESourceBackendClass;
typedef struct _ESourceBackendPrivate ESourceBackendPrivate;

/**
 * ESourceBackend:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceBackend {
	/*< private >*/
	ESourceExtension parent;
	ESourceBackendPrivate *priv;
};

struct _ESourceBackendClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_backend_get_type	(void) G_GNUC_CONST;
const gchar *	e_source_backend_get_backend_name
						(ESourceBackend *extension);
gchar *		e_source_backend_dup_backend_name
						(ESourceBackend *extension);
void		e_source_backend_set_backend_name
						(ESourceBackend *extension,
						 const gchar *backend_name);

G_END_DECLS

#endif /* E_SOURCE_BACKEND_H */
