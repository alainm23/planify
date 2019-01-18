/*
 * camel-imapx-namespace-response.c
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
 * SECTION: camel-imapx-namespace-response
 * @include: camel/camel.h
 * @short_description: Stores an IMAP NAMESPACE response
 *
 * #CamelIMAPXNamespaceResponse encapsulates an IMAP NAMESPACE response,
 * which consists of a set of #CamelIMAPXNamespace objects grouped by
 * #CamelIMAPXNamespaceCategory.
 **/

#include "evolution-data-server-config.h"

#include "camel-imapx-namespace-response.h"

#include <string.h>

#include "camel-imapx-utils.h"

#define CAMEL_IMAPX_NAMESPACE_RESPONSE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, CamelIMAPXNamespaceResponsePrivate))

struct _CamelIMAPXNamespaceResponsePrivate {
	GQueue namespaces;
};

G_DEFINE_TYPE (
	CamelIMAPXNamespaceResponse,
	camel_imapx_namespace_response,
	G_TYPE_OBJECT)

static void
imapx_namespace_response_add (CamelIMAPXNamespaceResponse *response,
                              CamelIMAPXNamespaceCategory category,
                              const gchar *prefix,
                              gchar separator)
{
	CamelIMAPXNamespace *namespace;

	namespace = camel_imapx_namespace_new (category, prefix, separator);
	g_queue_push_tail (&response->priv->namespaces, namespace);
}

static void
imapx_namespace_response_dispose (GObject *object)
{
	CamelIMAPXNamespaceResponsePrivate *priv;

	priv = CAMEL_IMAPX_NAMESPACE_RESPONSE_GET_PRIVATE (object);

	while (!g_queue_is_empty (&priv->namespaces))
		g_object_unref (g_queue_pop_head (&priv->namespaces));

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_namespace_response_parent_class)->
		dispose (object);
}

static void
camel_imapx_namespace_response_class_init (CamelIMAPXNamespaceResponseClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (
		class, sizeof (CamelIMAPXNamespaceResponsePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = imapx_namespace_response_dispose;
}

static void
camel_imapx_namespace_response_init (CamelIMAPXNamespaceResponse *response)
{
	response->priv =
		CAMEL_IMAPX_NAMESPACE_RESPONSE_GET_PRIVATE (response);
}

static gboolean
imapx_namespace_response_parse_namespace (CamelIMAPXInputStream *stream,
                                          CamelIMAPXNamespaceResponse *response,
                                          CamelIMAPXNamespaceCategory category,
                                          GCancellable *cancellable,
                                          GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;
	gchar *prefix;
	gchar separator;
	gboolean success;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		return FALSE;
	if (tok == IMAPX_TOK_TOKEN) {
		if (g_ascii_toupper (token[0]) == 'N' &&
		    g_ascii_toupper (token[1]) == 'I' &&
		    g_ascii_toupper (token[2]) == 'L' &&
		    token[3] == 0)
			return TRUE;
	}
	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"namespace: expecting NIL or '('");
		return FALSE;
	}

repeat:
	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		return FALSE;
	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"namespace: expecting '('");
		return FALSE;
	}

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		return FALSE;
	if (tok != IMAPX_TOK_STRING) {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"namespace: expecting string");
		return FALSE;
	}

	prefix = g_strdup ((gchar *) token);

	success = camel_imapx_input_stream_nstring (
		stream, &token, cancellable, error);

	if (!success) {
		g_free (prefix);
		return FALSE;
	}

	separator = (token != NULL) ? (gchar) *token : '\0';

	imapx_namespace_response_add (response, category, prefix, separator);

	g_free (prefix);

	/* FIXME Parse any namespace response extensions. */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		return FALSE;
	if (tok != ')') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"namespace: expecting ')'");
		return FALSE;
	}

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		return FALSE;
	if (tok == '(') {
		camel_imapx_input_stream_ungettoken (stream, tok, token, len);
		goto repeat;
	}
	if (tok != ')') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"namespace: expecting '(' or ')'");
		return FALSE;
	}

	return TRUE;
}

/**
 * camel_imapx_namespace_response_new:
 * @stream: a #CamelIMAPXInputStream
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to parse an IMAP NAMESPACE response from @stream and, if
 * successful, stores the response data in a new #CamelIMAPXNamespaceResponse.
 * If an error occurs, the function sets @error and returns %NULL.
 *
 * Returns: a #CamelIMAPXNamespaceResponse, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXNamespaceResponse *
camel_imapx_namespace_response_new (CamelIMAPXInputStream *stream,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelIMAPXNamespaceResponse *response;
	gint ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), NULL);

	response = g_object_new (CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, NULL);

	for (ii = 0; ii < 3; ii++) {
		CamelIMAPXNamespaceCategory category;
		gboolean success;

		/* Don't rely on the enum values being defined
		 * in the same order as the NAMESPACE response. */
		switch (ii) {
			case 0:
				category = CAMEL_IMAPX_NAMESPACE_PERSONAL;
				break;
			case 1:
				category = CAMEL_IMAPX_NAMESPACE_OTHER_USERS;
				break;
			case 2:
				category = CAMEL_IMAPX_NAMESPACE_SHARED;
				break;
		}

		success = imapx_namespace_response_parse_namespace (
			stream, response, category, cancellable, error);
		if (!success)
			goto fail;
	}

	/* Eat the newline. */
	if (!camel_imapx_input_stream_skip (stream, cancellable, error))
		goto fail;

	return response;

fail:
	g_clear_object (&response);

	return NULL;
}

/**
 * camel_imapx_namespace_response_faux_new:
 * @list_response: a #CamelIMAPXListResponse
 *
 * Fabricates a new #CamelIMAPXNamespaceResponse from @list_response.
 * The returned #CamelIMAPXNamespaceResponse will consist of a single
 * personal #CamelIMAPXNamespace with an empty mailbox prefix string,
 * and a mailbox separator character taken from @list_response.
 *
 * Use this function when the IMAP server does not list the "NAMESPACE"
 * keyword in its CAPABILITY response.
 *
 * Returns: a #CamelIMAPXNamespaceResponse
 *
 * Since: 3.12
 **/
CamelIMAPXNamespaceResponse *
camel_imapx_namespace_response_faux_new (CamelIMAPXListResponse *list_response)
{
	CamelIMAPXNamespaceResponse *response;
	CamelIMAPXNamespaceCategory category;
	gchar separator;

	g_return_val_if_fail (
		CAMEL_IS_IMAPX_LIST_RESPONSE (list_response), NULL);

	response = g_object_new (CAMEL_TYPE_IMAPX_NAMESPACE_RESPONSE, NULL);

	category = CAMEL_IMAPX_NAMESPACE_PERSONAL;
	separator = camel_imapx_list_response_get_separator (list_response);
	imapx_namespace_response_add (response, category, "", separator);

	return response;
}

/**
 * camel_imapx_namespace_response_list:
 * @response: a #CamelIMAPXNamespaceResponse
 *
 * Returns a list of IMAP namespaces in the order received from the IMAP
 * server, which means they are grouped by #CamelIMAPXNamespaceCategory.
 *
 * The namespaces returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished with
 * them.  Free the returned list itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of #CamelIMAPXNamespace instances
 *
 * Since: 3.12
 **/
GList *
camel_imapx_namespace_response_list (CamelIMAPXNamespaceResponse *response)
{
	GList *head;

	g_return_val_if_fail (
		CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (response), NULL);

	head = g_queue_peek_head_link (&response->priv->namespaces);

	return g_list_copy_deep (head, (GCopyFunc) g_object_ref, NULL);
}

/**
 * camel_imapx_namespace_response_remove:
 * @response: a #CamelIMAPXNamespaceResponse
 * @namespace: a #CamelIMAPXNamespace to add
 *
 * Adds a @namespace into the list of namespaces. It adds its own
 * reference on the @namespace.
 *
 * Since: 3.16
 **/
void
camel_imapx_namespace_response_add (CamelIMAPXNamespaceResponse *response,
				    CamelIMAPXNamespace *namespace)
{
	g_return_if_fail (CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (response));
	g_return_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace));

	g_queue_push_tail (&response->priv->namespaces, g_object_ref (namespace));
}

/**
 * camel_imapx_namespace_response_remove:
 * @response: a #CamelIMAPXNamespaceResponse
 * @namespace: a #CamelIMAPXNamespace to remove
 *
 * Removes @namespace from the list of namespaces in the @response.
 * If no such namespace exists then does nothing.
 *
 * Since: 3.16
 **/
void
camel_imapx_namespace_response_remove (CamelIMAPXNamespaceResponse *response,
				       CamelIMAPXNamespace *namespace)
{
	GList *link;

	g_return_if_fail (CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (response));
	g_return_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace));

	for (link = g_queue_peek_head_link (&response->priv->namespaces);
	     link; link = g_list_next (link)) {
		CamelIMAPXNamespace *ns = link->data;

		if (camel_imapx_namespace_equal (namespace, ns)) {
			g_queue_remove (&response->priv->namespaces, ns);
			g_object_unref (ns);
			break;
		}
	}
}

/**
 * camel_imapx_namespace_response_lookup:
 * @response: a #CamelIMAPXNamespaceResponse
 * @mailbox_name: a mailbox name
 * @separator: a mailbox path separator character
 *
 * Attempts to match @mailbox_name and @separator to a known IMAP namespace
 * and returns a #CamelIMAPXNamespace, or %NULL if no match was found.
 *
 * The returned #CamelIMAPXNamespace is referenced for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXNamespace, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXNamespace *
camel_imapx_namespace_response_lookup (CamelIMAPXNamespaceResponse *response,
                                       const gchar *mailbox_name,
                                       gchar separator)
{
	CamelIMAPXNamespace *match = NULL;
	GQueue candidates = G_QUEUE_INIT;
	GList *head, *link;
	guint ii, length;

	g_return_val_if_fail (
		CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (response), NULL);
	g_return_val_if_fail (mailbox_name != NULL, NULL);

	/* Collect all namespaces with matching separators. */

	head = g_queue_peek_head_link (&response->priv->namespaces);

	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelIMAPXNamespace *namespace;
		gchar ns_separator;

		namespace = CAMEL_IMAPX_NAMESPACE (link->data);
		ns_separator = camel_imapx_namespace_get_separator (namespace);

		if (separator == ns_separator)
			g_queue_push_tail (&candidates, namespace);
	}

	/* Check namespaces with non-empty prefix strings.
	 * Discard those that don't match the mailbox name. */

	length = g_queue_get_length (&candidates);

	for (ii = 0; ii < length; ii++) {
		CamelIMAPXNamespace *namespace;
		const gchar *ns_prefix;

		namespace = g_queue_pop_head (&candidates);
		ns_prefix = camel_imapx_namespace_get_prefix (namespace);
		g_return_val_if_fail (ns_prefix != NULL, NULL);

		/* Put namespaces with empty prefix strings
		 * back on the tail of the candidates queue. */
		if (*ns_prefix == '\0') {
			g_queue_push_tail (&candidates, namespace);
			continue;
		}

		/* Stop processing if we find a match. */
		if (g_str_has_prefix (mailbox_name, ns_prefix)) {
			match = namespace;
			break;
		}
	}

	/* Remaining namespaces have empty prefix strings.
	 * Return the first one as the matching namespace. */

	if (match == NULL)
		match = g_queue_pop_head (&candidates);

	g_queue_clear (&candidates);

	if (match != NULL)
		g_object_ref (match);

	return match;
}

/* Helper for camel_imapx_namespace_response_lookup_for_path() */
static gint
imapx_namespace_response_rank_candidates (gconstpointer a,
                                          gconstpointer b,
                                          gpointer user_data)
{
	CamelIMAPXNamespace *namespace_a;
	CamelIMAPXNamespace *namespace_b;
	const gchar *prefix_a;
	const gchar *prefix_b;
	gsize prefix_len_a;
	gsize prefix_len_b;

	namespace_a = CAMEL_IMAPX_NAMESPACE (a);
	namespace_b = CAMEL_IMAPX_NAMESPACE (b);

	prefix_a = camel_imapx_namespace_get_prefix (namespace_a);
	prefix_b = camel_imapx_namespace_get_prefix (namespace_b);

	prefix_len_a = strlen (prefix_a);
	prefix_len_b = strlen (prefix_b);

	/* Rank namespaces by longest prefix string. */

	if (prefix_len_a > prefix_len_b)
		return -1;

	if (prefix_len_a < prefix_len_b)
		return 1;

	/* For namespaces with equal length prefixes, compare the prefix
	 * strings themselves.  Kind of arbitrary, but we have no better
	 * criteria.  Should rarely come up for a sanely configured IMAP
	 * server anyway. */
	return strcmp (prefix_a, prefix_b);
}

/**
 * camel_imapx_namespace_response_lookup_for_path:
 * @response: a #CamelIMAPXNamespaceResponse
 * @folder_path: a Camel folder path
 *
 * Attempts to match @folder_path to a known IMAP namespace and returns a
 * #CamelIMAPXNamespace, or %NULL if no match was found.
 *
 * If the result is ambiguous, meaning @folder_path could belong to one of
 * several IMAP namespaces, the namespace with the longest matching prefix
 * string is preferred.  This has the effect of giving a namespace with an
 * empty prefix the lowest priority.
 *
 * The returned #CamelIMAPXNamespace is referenced for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXNamespace, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXNamespace *
camel_imapx_namespace_response_lookup_for_path (CamelIMAPXNamespaceResponse *response,
                                                const gchar *folder_path)
{
	CamelIMAPXNamespace *match = NULL;
	GQueue candidates = G_QUEUE_INIT;
	GList *head, *link;
	gboolean find_empty_prefix;

	g_return_val_if_fail (
		CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (response), NULL);
	g_return_val_if_fail (folder_path != NULL, NULL);

	/* Special cases:
	 * If the folder path is empty or names the INBOX, then
	 * find the first namespace with an empty prefix string. */
	find_empty_prefix =
		(*folder_path == '\0') ||
		(g_ascii_strcasecmp (folder_path, "INBOX") == 0);

	head = g_queue_peek_head_link (&response->priv->namespaces);

	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelIMAPXNamespace *namespace;
		const gchar *prefix;
		gchar *path_prefix;
		gchar separator;

		namespace = CAMEL_IMAPX_NAMESPACE (link->data);
		prefix = camel_imapx_namespace_get_prefix (namespace);
		separator = camel_imapx_namespace_get_separator (namespace);

		/* Special handling when searching for an empty prefix. */
		if (find_empty_prefix) {
			if (*prefix == '\0' ||
			    g_ascii_strcasecmp (prefix, "INBOX") == 0 ||
			    (g_ascii_strncasecmp (prefix, "INBOX", 5) == 0 &&
			     prefix[5] == separator && !prefix[6])) {
				g_queue_push_tail (&candidates, namespace);
				break;
			}
			continue;
		}

		/* Convert the prefix to a folder path segment. */
		path_prefix = camel_imapx_mailbox_to_folder_path (
			prefix, separator);

		if (g_str_has_prefix (folder_path, path_prefix)) {
			g_queue_insert_sorted (
				&candidates, namespace,
				imapx_namespace_response_rank_candidates,
				NULL);
		}

		g_free (path_prefix);
	}

	/* First candidate is the preferred namespace. */
	match = g_queue_pop_head (&candidates);

	/* Fallback to the first known namespace when none suitable for the given path found */
	if (!match && head && head->data)
		match = head->data;

	if (match != NULL)
		g_object_ref (match);

	/* Discard any unselected candidates. */
	g_queue_clear (&candidates);

	return match;
}

