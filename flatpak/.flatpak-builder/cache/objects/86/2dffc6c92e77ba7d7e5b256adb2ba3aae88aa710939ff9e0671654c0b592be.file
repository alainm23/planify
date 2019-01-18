/*
 * camel-imapx-namespace-response.h
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

#ifndef CAMEL_IMAPX_NAMESPACE_RESPONSE_H
#define CAMEL_IMAPX_NAMESPACE_RESPONSE_H

#include "camel-imapx-namespace.h"
#include "camel-imapx-list-response.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE \
	(camel_imapx_namespace_response_get_type ())
#define CAMEL_IMAPX_NAMESPACE_RESPONSE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, CamelIMAPXNamespaceResponse))
#define CAMEL_IMAPX_NAMESPACE_RESPONSE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, CamelIMAPXNamespaceResponseClass))
#define CAMEL_IS_IMAPX_NAMESPACE_RESPONSE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE))
#define CAMEL_IS_IMAPX_NAMESPACE_RESPONSE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE))
#define CAMEL_IMAPX_NAMESPACE_RESPONSE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, CamelIMAPXNamespaceResponseClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXNamespaceResponse CamelIMAPXNamespaceResponse;
typedef struct _CamelIMAPXNamespaceResponseClass CamelIMAPXNamespaceResponseClass;
typedef struct _CamelIMAPXNamespaceResponsePrivate CamelIMAPXNamespaceResponsePrivate;

/**
 * CamelIMAPXNamespaceResponse:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _CamelIMAPXNamespaceResponse {
	/*< private >*/
	GObject parent;
	CamelIMAPXNamespaceResponsePrivate *priv;
};

struct _CamelIMAPXNamespaceResponseClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_namespace_response_get_type
					(void) G_GNUC_CONST;
CamelIMAPXNamespaceResponse *
		camel_imapx_namespace_response_new
					(CamelIMAPXInputStream *stream,
					 GCancellable *cancellable,
					 GError **error);
CamelIMAPXNamespaceResponse *
		camel_imapx_namespace_response_faux_new
					(CamelIMAPXListResponse *list_response);
GList *		camel_imapx_namespace_response_list
					(CamelIMAPXNamespaceResponse *response);
void		camel_imapx_namespace_response_add
					(CamelIMAPXNamespaceResponse *response,
					 CamelIMAPXNamespace *namespace);
void		camel_imapx_namespace_response_remove
					(CamelIMAPXNamespaceResponse *response,
					 CamelIMAPXNamespace *namespace);
CamelIMAPXNamespace *
		camel_imapx_namespace_response_lookup
					(CamelIMAPXNamespaceResponse *response,
					 const gchar *mailbox_name,
					 gchar separator);
CamelIMAPXNamespace *
		camel_imapx_namespace_response_lookup_for_path
					(CamelIMAPXNamespaceResponse *response,
					 const gchar *folder_path);

G_END_DECLS

#endif /* CAMEL_IMAPX_NAMESPACE_RESPONSE_H */

