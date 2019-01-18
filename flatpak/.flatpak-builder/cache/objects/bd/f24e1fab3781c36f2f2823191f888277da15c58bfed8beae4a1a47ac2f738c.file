/*
 * camel-imapx-list-response.h
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

#ifndef CAMEL_IMAPX_LIST_RESPONSE_H
#define CAMEL_IMAPX_LIST_RESPONSE_H

#include <gio/gio.h>

#include "camel-imapx-input-stream.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_LIST_RESPONSE \
	(camel_imapx_list_response_get_type ())
#define CAMEL_IMAPX_LIST_RESPONSE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_LIST_RESPONSE, CamelIMAPXListResponse))
#define CAMEL_IMAPX_LIST_RESPONSE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_LIST_RESPONSE, CamelIMAPXListResponseClass))
#define CAMEL_IS_IMAPX_LIST_RESPONSE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_LIST_RESPONSE))
#define CAMEL_IS_IMAPX_LIST_RESPONSE_CLASS(cls) \
	(G_TYPE_CHECK_INSTANCE_CLASS \
	((cls), CAMEL_TYPE_IMAPX_LIST_RESPONSE))
#define CAMEL_IMAPX_LIST_RESPONSE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_LIST_RESPONSE, CamelIMAPXListResponseClass))

/* RFC 3501 Standard Flags */
#define CAMEL_IMAPX_LIST_ATTR_MARKED		"\\Marked"
#define CAMEL_IMAPX_LIST_ATTR_NOINFERIORS	"\\NoInferiors"
#define CAMEL_IMAPX_LIST_ATTR_NOSELECT		"\\NoSelect"
#define CAMEL_IMAPX_LIST_ATTR_UNMARKED		"\\Unmarked"

/* RFC 5258 "LIST-EXTENDED" Flags */
#define CAMEL_IMAPX_LIST_ATTR_HASCHILDREN	"\\HasChildren"
#define CAMEL_IMAPX_LIST_ATTR_HASNOCHILDREN	"\\HasNoChildren"
#define CAMEL_IMAPX_LIST_ATTR_NONEXISTENT	"\\NonExistent"
#define CAMEL_IMAPX_LIST_ATTR_REMOTE		"\\Remote"
#define CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED	"\\Subscribed"

/* RFC 6154 "SPECIAL-USE" Flags */
#define CAMEL_IMAPX_LIST_ATTR_ALL		"\\All"
#define CAMEL_IMAPX_LIST_ATTR_ARCHIVE		"\\Archive"
#define CAMEL_IMAPX_LIST_ATTR_DRAFTS		"\\Drafts"
#define CAMEL_IMAPX_LIST_ATTR_FLAGGED		"\\Flagged"
#define CAMEL_IMAPX_LIST_ATTR_JUNK		"\\Junk"
#define CAMEL_IMAPX_LIST_ATTR_SENT		"\\Sent"
#define CAMEL_IMAPX_LIST_ATTR_TRASH		"\\Trash"

G_BEGIN_DECLS

typedef struct _CamelIMAPXListResponse CamelIMAPXListResponse;
typedef struct _CamelIMAPXListResponseClass CamelIMAPXListResponseClass;
typedef struct _CamelIMAPXListResponsePrivate CamelIMAPXListResponsePrivate;

/**
 * CamelIMAPXListResponse:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.10
 **/
struct _CamelIMAPXListResponse {
	/*< private >*/
	GObject parent;
	CamelIMAPXListResponsePrivate *priv;
};

struct _CamelIMAPXListResponseClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_list_response_get_type
					(void) G_GNUC_CONST;
CamelIMAPXListResponse *
		camel_imapx_list_response_new
					(CamelIMAPXInputStream *stream,
					 GCancellable *cancellable,
					 GError **error);
guint		camel_imapx_list_response_hash
					(CamelIMAPXListResponse *response);
gboolean	camel_imapx_list_response_equal
					(CamelIMAPXListResponse *response_a,
					 CamelIMAPXListResponse *response_b);
gint		camel_imapx_list_response_compare
					(CamelIMAPXListResponse *response_a,
					 CamelIMAPXListResponse *response_b);
const gchar *	camel_imapx_list_response_get_mailbox_name
					(CamelIMAPXListResponse *response);
gchar		camel_imapx_list_response_get_separator
					(CamelIMAPXListResponse *response);
void		camel_imapx_list_response_add_attribute
					(CamelIMAPXListResponse *response,
					 const gchar *attribute);
gboolean	camel_imapx_list_response_has_attribute
					(CamelIMAPXListResponse *response,
					 const gchar *attribute);
GHashTable *	camel_imapx_list_response_dup_attributes
					(CamelIMAPXListResponse *response);
GVariant *	camel_imapx_list_response_ref_extended_item
					(CamelIMAPXListResponse *response,
					 const gchar *extended_item_tag);
const gchar *	camel_imapx_list_response_get_oldname
					(CamelIMAPXListResponse *response);

G_END_DECLS

#endif /* CAMEL_IMAPX_LIST_RESPONSE_H */

