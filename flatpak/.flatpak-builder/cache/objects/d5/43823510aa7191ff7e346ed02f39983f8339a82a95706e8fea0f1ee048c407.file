/*
 * camel-imapx-namespace.h
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

#ifndef CAMEL_IMAPX_NAMESPACE_H
#define CAMEL_IMAPX_NAMESPACE_H

#include <glib-object.h>

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_NAMESPACE \
	(camel_imapx_namespace_get_type ())
#define CAMEL_IMAPX_NAMESPACE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE, CamelIMAPXNamespace))
#define CAMEL_IMAPX_NAMESPACE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_NAMESPACE, CamelIMAPXNamespaceClass))
#define CAMEL_IS_IMAPX_NAMESPACE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE))
#define CAMEL_IS_IMAPX_NAMESPACE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_NAMESPACE))
#define CAMEL_IMAPX_NAMESPACE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE, CamelIMAPXNamespaceClass))

G_BEGIN_DECLS

/**
 * CamelIMAPXNamespaceCategory:
 * @CAMEL_IMAPX_NAMESPACE_PERSONAL:
 *   Mailboxes belonging to the authenticated user.
 * @CAMEL_IMAPX_NAMESPACE_OTHER_USERS:
 *   Personal mailboxes belonging to other users.
 * @CAMEL_IMAPX_NAMESPACE_SHARED:
 *   Mailboxes intended to be shared amongst users.
 *
 * Refer to <ulink url="http://tools.ietf.org/html/rfc2342">RFC 2342</ulink>
 * for more detailed namespace class descriptions.
 **/
typedef enum {
	CAMEL_IMAPX_NAMESPACE_PERSONAL,
	CAMEL_IMAPX_NAMESPACE_OTHER_USERS,
	CAMEL_IMAPX_NAMESPACE_SHARED
} CamelIMAPXNamespaceCategory;

typedef struct _CamelIMAPXNamespace CamelIMAPXNamespace;
typedef struct _CamelIMAPXNamespaceClass CamelIMAPXNamespaceClass;
typedef struct _CamelIMAPXNamespacePrivate CamelIMAPXNamespacePrivate;

/**
 * CamelIMAPXNamespace:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _CamelIMAPXNamespace {
	/*< private >*/
	GObject parent;
	CamelIMAPXNamespacePrivate *priv;
};

struct _CamelIMAPXNamespaceClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_namespace_get_type
					(void) G_GNUC_CONST;
CamelIMAPXNamespace *
		camel_imapx_namespace_new
					(CamelIMAPXNamespaceCategory category,
					 const gchar *prefix,
					 gchar separator);
gboolean	camel_imapx_namespace_equal
					(CamelIMAPXNamespace *namespace_a,
					 CamelIMAPXNamespace *namespace_b);
CamelIMAPXNamespaceCategory
		camel_imapx_namespace_get_category
					(CamelIMAPXNamespace *namespace_);
const gchar *	camel_imapx_namespace_get_prefix
					(CamelIMAPXNamespace *namespace_);
gchar		camel_imapx_namespace_get_separator
					(CamelIMAPXNamespace *namespace_);

G_END_DECLS

#endif /* CAMEL_IMAPX_NAMESPACE_H */

