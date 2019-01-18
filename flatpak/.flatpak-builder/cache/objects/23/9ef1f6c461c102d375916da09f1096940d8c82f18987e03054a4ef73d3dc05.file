/*
 * camel-imapx-namespace.c
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

/**
 * SECTION: camel-imapx-namespace
 * @include: camel/camel.h
 * @short_description: Stores an IMAP namespace
 *
 * #CamelIMAPXNamespace encapsulates an IMAP namespace, which consists of a
 * namespace category (personal/other users/shared), a mailbox prefix string,
 * and a mailbox separator character.
 **/

#include "evolution-data-server-config.h"

#include "camel-imapx-namespace.h"

#define CAMEL_IMAPX_NAMESPACE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE, CamelIMAPXNamespacePrivate))

struct _CamelIMAPXNamespacePrivate {
	CamelIMAPXNamespaceCategory category;
	gchar *prefix;
	gchar separator;
};

G_DEFINE_TYPE (
	CamelIMAPXNamespace,
	camel_imapx_namespace,
	G_TYPE_OBJECT)

static void
imapx_namespace_finalize (GObject *object)
{
	CamelIMAPXNamespacePrivate *priv;

	priv = CAMEL_IMAPX_NAMESPACE_GET_PRIVATE (object);

	g_free (priv->prefix);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_namespace_parent_class)->finalize (object);
}

static void
camel_imapx_namespace_class_init (CamelIMAPXNamespaceClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXNamespacePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = imapx_namespace_finalize;
}

static void
camel_imapx_namespace_init (CamelIMAPXNamespace *namespace)
{
	namespace->priv = CAMEL_IMAPX_NAMESPACE_GET_PRIVATE (namespace);
}

/**
 * camel_imapx_namespace_new:
 * @category: a #CamelIMAPXNamespaceCategory
 * @prefix: a mailbox prefix string
 * @separator: a mailbox path separator character
 *
 * Creates a new #CamelIMAPXNamespace from @category, @prefix and @separator.
 *
 * Returns: a new #CamelIMAPXNamespace
 *
 * Since: 3.12
 **/
CamelIMAPXNamespace *
camel_imapx_namespace_new (CamelIMAPXNamespaceCategory category,
                           const gchar *prefix,
                           gchar separator)
{
	CamelIMAPXNamespace *namespace;

	/* Note, mailbox path separator can be NIL. */
	g_return_val_if_fail (prefix != NULL, NULL);

	/* Not bothering with GObject properties for this class. */

	namespace = g_object_new (CAMEL_TYPE_IMAPX_NAMESPACE, NULL);
	namespace->priv->category = category;
	namespace->priv->prefix = g_strdup (prefix);
	namespace->priv->separator = separator;

	return namespace;
}

/**
 * camel_imapx_namespace_equal:
 * @namespace_a: a #CamelIMAPXNamespace
 * @namespace_b: another #CamelIMAPXNamespace
 *
 * Returns whether @namespace_a and @namespace_b are equivalent, meaning
 * they share the same category, prefix string, and path separator character.
 *
 * Returns: %TRUE if @namespace_a and @namespace_b are equal
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_namespace_equal (CamelIMAPXNamespace *namespace_a,
                             CamelIMAPXNamespace *namespace_b)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace_a), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace_b), FALSE);

	if (namespace_a == namespace_b)
		return TRUE;

	if (namespace_a->priv->category != namespace_b->priv->category)
		return FALSE;

	if (namespace_a->priv->separator != namespace_b->priv->separator)
		return FALSE;

	return g_str_equal (
		namespace_a->priv->prefix,
		namespace_b->priv->prefix);
}

/**
 * camel_imapx_namespace_get_category:
 * @namespace_: a #CamelIMAPXNamespace
 *
 * Returns the #CamelIMAPXNamespaceCategory for @namespace.
 *
 * Returns: a #CamelIMAPXNamespaceCategory
 *
 * Since: 3.12
 **/
CamelIMAPXNamespaceCategory
camel_imapx_namespace_get_category (CamelIMAPXNamespace *namespace)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_NAMESPACE (namespace),
		CAMEL_IMAPX_NAMESPACE_PERSONAL);

	return namespace->priv->category;
}

/**
 * camel_imapx_namespace_get_prefix:
 * @namespace_: a #CamelIMAPXNamespace
 *
 * Returns the mailbox prefix string for @namespace.
 *
 * Returns: a mailbox prefix string
 *
 * Since: 3.12
 **/
const gchar *
camel_imapx_namespace_get_prefix (CamelIMAPXNamespace *namespace)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace), NULL);

	return namespace->priv->prefix;
}

/**
 * camel_imapx_namespace_get_separator:
 * @namespace_: a #CamelIMAPXNamespace
 *
 * Returns the mailbox path separator charactor for @namespace.
 *
 * Returns: the mailbox path separator character
 *
 * Since: 3.12
 **/
gchar
camel_imapx_namespace_get_separator (CamelIMAPXNamespace *namespace)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace), '\0');

	return namespace->priv->separator;
}

