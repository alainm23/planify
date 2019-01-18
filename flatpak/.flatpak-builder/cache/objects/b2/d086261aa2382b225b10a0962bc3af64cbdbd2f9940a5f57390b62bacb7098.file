/*
 * e-backend-factory.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_BACKEND_FACTORY_H
#define E_BACKEND_FACTORY_H

#include <libedataserver/libedataserver.h>
#include <libebackend/e-backend.h>

/* Standard GObject macros */
#define E_TYPE_BACKEND_FACTORY \
	(e_backend_factory_get_type ())
#define E_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BACKEND_FACTORY, EBackendFactory))
#define E_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BACKEND_FACTORY, EBackendFactoryClass))
#define E_IS_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BACKEND_FACTORY))
#define E_IS_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BACKEND_FACTORY))
#define E_BACKEND_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BACKEND_FACTORY, EBackendFactoryClass))

G_BEGIN_DECLS

typedef struct _EBackendFactory EBackendFactory;
typedef struct _EBackendFactoryClass EBackendFactoryClass;
typedef struct _EBackendFactoryPrivate EBackendFactoryPrivate;

/**
 * EBackendFactory:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EBackendFactory {
	/*< private >*/
	EExtension parent;
	EBackendFactoryPrivate *priv;
};

/**
 * EBackendFactoryClass:
 * @get_hash_key: Get the hash key for this factory
 * @new_backend: Create a new #EBackend of the appropriate type for the passed #ESource
 * @e_module: An #EModule associated with this backend factory
 * @share_subprocess: Whether subporcesses for this backend factory should share one process
 *
 * Base class structure for the #EBackendFactory class
 *
 * Since: 3.4
 **/
struct _EBackendFactoryClass {
	/*< private >*/
	EExtensionClass parent_class;

	/*< public >*/
	/* Methods */
	const gchar *	(*get_hash_key)		(EBackendFactory *factory);
	EBackend *	(*new_backend)		(EBackendFactory *factory,
						 ESource *source);

	struct _EModule	*e_module;
	gboolean	share_subprocess;

	/*< private >*/
	gpointer reserved[15];
};

GType		e_backend_factory_get_type	(void) G_GNUC_CONST;
const gchar *	e_backend_factory_get_hash_key	(EBackendFactory *factory);
EBackend *	e_backend_factory_new_backend	(EBackendFactory *factory,
						 ESource *source);
const gchar *  e_backend_factory_get_module_filename
						(EBackendFactory *factory);
gboolean	e_backend_factory_share_subprocess
						(EBackendFactory *factory);


G_END_DECLS

#endif /* E_BACKEND_FACTORY_H */
