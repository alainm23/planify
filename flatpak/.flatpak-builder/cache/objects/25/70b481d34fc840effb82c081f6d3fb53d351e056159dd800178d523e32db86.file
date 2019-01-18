/*
 * e-collection-backend-factory.h
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

#ifndef E_COLLECTION_BACKEND_FACTORY_H
#define E_COLLECTION_BACKEND_FACTORY_H

#include <libebackend/e-backend-factory.h>

/* Standard GObject macros */
#define E_TYPE_COLLECTION_BACKEND_FACTORY \
	(e_collection_backend_factory_get_type ())
#define E_COLLECTION_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_COLLECTION_BACKEND_FACTORY, ECollectionBackendFactory))
#define E_COLLECTION_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_COLLECTION_BACKEND_FACTORY, ECollectionBackendFactoryClass))
#define E_IS_COLLECTION_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_COLLECTION_BACKEND_FACTORY))
#define E_IS_COLLECTION_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_COLLECTION_BACKEND_FACTORY))
#define E_COLLECTION_BACKEND_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_COLLECTION_BACKEND_FACTORY, ECollectionBackendFactoryClass))

G_BEGIN_DECLS

typedef struct _ECollectionBackendFactory ECollectionBackendFactory;
typedef struct _ECollectionBackendFactoryClass ECollectionBackendFactoryClass;
typedef struct _ECollectionBackendFactoryPrivate ECollectionBackendFactoryPrivate;

/**
 * ECollectionBackendFactory:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ECollectionBackendFactory {
	/*< private >*/
	EBackendFactory parent;
	ECollectionBackendFactoryPrivate *priv;
};

struct _ECollectionBackendFactoryClass {
	/*< private >*/
	EBackendFactoryClass parent_class;

	const gchar *factory_name;
	GType backend_type;

	/* Methods */
	void		(*prepare_mail)	(ECollectionBackendFactory *factory,
					 ESource *mail_account_source,
					 ESource *mail_identity_source,
					 ESource *mail_transport_source);

	/*< private >*/
	gpointer reserved[16];
};

GType		e_collection_backend_factory_get_type
					(void) G_GNUC_CONST;
void		e_collection_backend_factory_prepare_mail
					(ECollectionBackendFactory *factory,
					 ESource *mail_account_source,
					 ESource *mail_identity_source,
					 ESource *mail_transport_source);

G_END_DECLS

#endif /* E_COLLECTION_BACKEND_FACTORY_H */

