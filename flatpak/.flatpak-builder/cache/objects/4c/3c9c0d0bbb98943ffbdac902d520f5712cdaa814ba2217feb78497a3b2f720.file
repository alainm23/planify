/*
 * e-data-factory.h
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

#ifndef E_SUBPROCESS_FACTORY_H
#define E_SUBPROCESS_FACTORY_H

#include <libebackend/e-backend-factory.h>

/* Standard GObject macros */
#define E_TYPE_SUBPROCESS_FACTORY \
	(e_subprocess_factory_get_type ())
#define E_SUBPROCESS_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SUBPROCESS_FACTORY, ESubprocessFactory))
#define E_SUBPROCESS_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SUBPROCESS_FACTORY, ESubprocessFactoryClass))
#define E_IS_SUBPROCESS_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SUBPROCESS_FACTORY))
#define E_IS_SUBPROCESS_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SUBPROCESS_FACTORY))
#define E_SUBPROCESS_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SUBPROCESS_FACTORY, ESubprocessFactoryClass))

G_BEGIN_DECLS

typedef struct _ESubprocessFactory ESubprocessFactory;
typedef struct _ESubprocessFactoryClass ESubprocessFactoryClass;
typedef struct _ESubprocessFactoryPrivate ESubprocessFactoryPrivate;

/**
 * ESubprocessFactory:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.16
 **/
struct _ESubprocessFactory {
	/*< private >*/
	GObject parent;
	ESubprocessFactoryPrivate *priv;
};

struct _ESubprocessFactoryClass {
	GObjectClass parent_class;

	EBackend *	(*ref_backend)		(ESourceRegistry *registry,
						 ESource *source,
						 const gchar *backend_factory_type_name);
	gchar *		(*open_data)		(ESubprocessFactory *subprocess_factory,
						 EBackend *backend,
						 GDBusConnection *connection,
						 gpointer data,
						 GCancellable *cancellable,
						 GError **error);

	/* Signals */
	void		(*backend_created)	(ESubprocessFactory *subprocess_factory,
						 EBackend *backend);
	void		(*backend_closed)	(ESubprocessFactory *subprocess_factory,
						 EBackend *backend);

};

GType		e_subprocess_factory_get_type
						(void) G_GNUC_CONST;

EBackend *	e_subprocess_factory_ref_initable_backend
						(ESubprocessFactory *subprocess_factory,
						 const gchar *uid,
						 const gchar *backend_factory_type_name,
						 const gchar *module_filename,
						 GCancellable *cancellable,
						 GError **error);
ESourceRegistry *
		e_subprocess_factory_get_registry
						(ESubprocessFactory *subprocess_factory);
gchar *		e_subprocess_factory_open_backend
						(ESubprocessFactory *subprocess_factory,
						 GDBusConnection *connection,
						 const gchar *uid,
						 const gchar *backend_factory_type_name,
						 const gchar *module_filename,
						 GDBusInterfaceSkeleton *proxy,
						 GCancellable *cancellable,
						 GError **error);
gchar *		e_subprocess_factory_construct_path
						(void);
void		e_subprocess_factory_set_backend_callbacks
						(ESubprocessFactory *subprocess_factory,
						 EBackend *backend,
						 GDBusInterfaceSkeleton *proxy);
void		e_subprocess_factory_call_backends_prepare_shutdown
						(ESubprocessFactory *subprocess_factory);
GList *		e_subprocess_factory_get_backends_list
						(ESubprocessFactory *subprocess_factory);

G_END_DECLS

#endif /* E_SUBPROCESS_FACTORY_H */
