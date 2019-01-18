/*
 * camel-imapx-search.h
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

#ifndef CAMEL_IMAPX_SEARCH_H
#define CAMEL_IMAPX_SEARCH_H

#include <camel/camel.h>

#include "camel-imapx-store.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_SEARCH \
	(camel_imapx_search_get_type ())
#define CAMEL_IMAPX_SEARCH(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_SEARCH, CamelIMAPXSearch))
#define CAMEL_IMAPX_SEARCH_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_SEARCH, CamelIMAPXSearchClass))
#define CAMEL_IS_IMAPX_SEARCH(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_SEARCH))
#define CAMEL_IS_IMAPX_SEARCH_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_SEARCH))
#define CAMEL_IMAPX_SEARCH_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_SEARCH, CamelIMAPXSearchClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXSearch CamelIMAPXSearch;
typedef struct _CamelIMAPXSearchClass CamelIMAPXSearchClass;
typedef struct _CamelIMAPXSearchPrivate CamelIMAPXSearchPrivate;

/**
 * CamelIMAPXSearch:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _CamelIMAPXSearch {
	/*< private >*/
	CamelFolderSearch parent;
	CamelIMAPXSearchPrivate *priv;
};

struct _CamelIMAPXSearchClass {
	CamelFolderSearchClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_search_get_type	(void) G_GNUC_CONST;
CamelFolderSearch *
		camel_imapx_search_new		(CamelIMAPXStore *imapx_store);
CamelIMAPXStore *
		camel_imapx_search_ref_store	(CamelIMAPXSearch *search);
void		camel_imapx_search_set_store	(CamelIMAPXSearch *search,
						 CamelIMAPXStore *imapx_store);
void		camel_imapx_search_set_cancellable_and_error
						(CamelIMAPXSearch *search,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_IMAPX_SEARCH_H */

