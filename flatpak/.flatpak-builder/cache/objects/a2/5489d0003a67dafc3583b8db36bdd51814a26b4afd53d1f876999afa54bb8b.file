/*
 * e-source-collection.h
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

#ifndef E_SOURCE_COLLECTION_H
#define E_SOURCE_COLLECTION_H

#include <libedataserver/e-source-backend.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_COLLECTION \
	(e_source_collection_get_type ())
#define E_SOURCE_COLLECTION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_COLLECTION, ESourceCollection))
#define E_SOURCE_COLLECTION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_COLLECTION, ESourceCollectionClass))
#define E_IS_SOURCE_COLLECTION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_COLLECTION))
#define E_IS_SOURCE_COLLECTION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_COLLECTION))
#define E_SOURCE_COLLECTION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_COLLECTION, ESourceCollectionClass))

/**
 * E_SOURCE_EXTENSION_COLLECTION:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceCollection.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_COLLECTION "Collection"

G_BEGIN_DECLS

typedef struct _ESourceCollection ESourceCollection;
typedef struct _ESourceCollectionClass ESourceCollectionClass;
typedef struct _ESourceCollectionPrivate ESourceCollectionPrivate;

/**
 * ESourceCollection:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceCollection {
	/*< private >*/
	ESourceBackend parent;
	ESourceCollectionPrivate *priv;
};

struct _ESourceCollectionClass {
	ESourceBackendClass parent_class;
};

GType		e_source_collection_get_type	(void) G_GNUC_CONST;
const gchar *	e_source_collection_get_identity
						(ESourceCollection *extension);
gchar *		e_source_collection_dup_identity
						(ESourceCollection *extension);
void		e_source_collection_set_identity
						(ESourceCollection *extension,
						 const gchar *identity);
gboolean	e_source_collection_get_calendar_enabled
						(ESourceCollection *extension);
void		e_source_collection_set_calendar_enabled
						(ESourceCollection *extension,
						 gboolean calendar_enabled);
gboolean	e_source_collection_get_contacts_enabled
						(ESourceCollection *extension);
void		e_source_collection_set_contacts_enabled
						(ESourceCollection *extension,
						 gboolean contacts_enabled);
gboolean	e_source_collection_get_mail_enabled
						(ESourceCollection *extension);
void		e_source_collection_set_mail_enabled
						(ESourceCollection *extension,
						 gboolean mail_enabled);
const gchar *	e_source_collection_get_calendar_url
						(ESourceCollection *extension);
gchar *		e_source_collection_dup_calendar_url
						(ESourceCollection *extension);
void		e_source_collection_set_calendar_url
						(ESourceCollection *extension,
						 const gchar *calendar_url);
const gchar *	e_source_collection_get_contacts_url
						(ESourceCollection *extension);
gchar *		e_source_collection_dup_contacts_url
						(ESourceCollection *extension);
void		e_source_collection_set_contacts_url
						(ESourceCollection *extension,
						 const gchar *contacts_url);

G_END_DECLS

#endif /* E_SOURCE_COLLECTION_H */

