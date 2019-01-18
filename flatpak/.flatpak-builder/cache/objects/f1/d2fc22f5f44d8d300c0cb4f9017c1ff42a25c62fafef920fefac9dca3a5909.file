/*
 * camel-imapx-status-response.c
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
 * SECTION: camel-imapx-status-response
 * @include: camel/camel.h
 * @short_description: Stores an IMAP STATUS respose
 *
 * #CamelIMAPXStatusResponse encapsulates an IMAP STATUS response, which
 * describes the current status of a mailbox in terms of various message
 * counts and change tracking indicators.
 **/

#include "evolution-data-server-config.h"

#include "camel-imapx-status-response.h"

#include "camel-imapx-utils.h"

#define CAMEL_IMAPX_STATUS_RESPONSE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_STATUS_RESPONSE, CamelIMAPXStatusResponsePrivate))

struct _CamelIMAPXStatusResponsePrivate {
	gchar *mailbox_name;

	guint32 messages;
	guint32 recent;
	guint32 unseen;
	guint32 uidnext;
	guint32 uidvalidity;
	guint64 highestmodseq;

	gboolean have_messages;
	gboolean have_recent;
	gboolean have_unseen;
	gboolean have_uidnext;
	gboolean have_uidvalidity;
	gboolean have_highestmodseq;
};

G_DEFINE_TYPE (
	CamelIMAPXStatusResponse,
	camel_imapx_status_response,
	G_TYPE_OBJECT)

static void
imapx_status_response_finalize (GObject *object)
{
	CamelIMAPXStatusResponsePrivate *priv;

	priv = CAMEL_IMAPX_STATUS_RESPONSE_GET_PRIVATE (object);

	g_free (priv->mailbox_name);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_status_response_parent_class)->
		finalize (object);
}

static void
camel_imapx_status_response_class_init (CamelIMAPXStatusResponseClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (
		class, sizeof (CamelIMAPXStatusResponsePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = imapx_status_response_finalize;
}

static void
camel_imapx_status_response_init (CamelIMAPXStatusResponse *response)
{
	response->priv = CAMEL_IMAPX_STATUS_RESPONSE_GET_PRIVATE (response);
}

/**
 * camel_imapx_status_response_new:
 * @stream: a #CamelIMAPXInputStream
 * @inbox_separator: the separator character for INBOX
 * @cancellable: a #GCancellable
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to parse an IMAP STATUS response from @stream and, if successful,
 * stores the response data in a new #CamelIMAPXStatusResponse.  If an error
 * occurs, the function sets @error and returns %NULL.
 *
 * Returns: a #CamelIMAPXStatusResponse, or %NULL
 *
 * Since: 3.10
 **/
CamelIMAPXStatusResponse *
camel_imapx_status_response_new (CamelIMAPXInputStream *stream,
                                 gchar inbox_separator,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelIMAPXStatusResponse *response;
	camel_imapx_token_t tok;
	guchar *token;
	guint len;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), NULL);

	response = g_object_new (CAMEL_TYPE_IMAPX_STATUS_RESPONSE, NULL);

	/* Parse mailbox name. */

	response->priv->mailbox_name = camel_imapx_parse_mailbox (
		stream, inbox_separator, cancellable, error);
	if (response->priv->mailbox_name == NULL)
		goto fail;

	/* Parse status attributes. */

	tok = camel_imapx_input_stream_token (
		CAMEL_IMAPX_INPUT_STREAM (stream),
		&token, &len, cancellable, error);
	if (tok == IMAPX_TOK_ERROR)
		goto fail;
	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"status: expecting '('");
		goto fail;
	}

	tok = camel_imapx_input_stream_token (
		CAMEL_IMAPX_INPUT_STREAM (stream),
		&token, &len, cancellable, error);

	while (tok == IMAPX_TOK_TOKEN) {
		guint64 number;
		gboolean success;

		switch (imapx_tokenise ((gchar *) token, len)) {
			case IMAPX_MESSAGES:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->messages = (guint32) number;
				response->priv->have_messages = TRUE;
				break;

			case IMAPX_RECENT:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->recent = (guint32) number;
				response->priv->have_recent = TRUE;
				break;

			case IMAPX_UNSEEN:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->unseen = (guint32) number;
				response->priv->have_unseen = TRUE;
				break;

			case IMAPX_UIDNEXT:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->uidnext = (guint32) number;
				response->priv->have_uidnext = TRUE;
				break;

			case IMAPX_UIDVALIDITY:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->uidvalidity = (guint32) number;
				response->priv->have_uidvalidity = TRUE;
				break;

			/* See RFC 4551 section 3.6 */
			case IMAPX_HIGHESTMODSEQ:
				success = camel_imapx_input_stream_number (
					CAMEL_IMAPX_INPUT_STREAM (stream),
					&number, cancellable, error);
				response->priv->highestmodseq = number;
				response->priv->have_highestmodseq = TRUE;
				break;

			default:
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"unknown status attribute");
				success = FALSE;
				break;
		}

		if (!success)
			goto fail;

		tok = camel_imapx_input_stream_token (
			CAMEL_IMAPX_INPUT_STREAM (stream),
			&token, &len, cancellable, error);
	}

	if (tok == IMAPX_TOK_ERROR)
		goto fail;

	if (tok != ')') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"status: expecting ')' or attribute");
		goto fail;
	}

	return response;

fail:
	g_clear_object (&response);

	return NULL;
}

/**
 * camel_imapx_status_response_get_mailbox_name:
 * @response: a #CamelIMAPXStatusResponse
 *
 * Returns the mailbox name for @response.
 *
 * Returns: the mailbox name
 *
 * Since: 3.10
 **/
const gchar *
camel_imapx_status_response_get_mailbox_name (CamelIMAPXStatusResponse *response)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_STATUS_RESPONSE (response), NULL);

	return response->priv->mailbox_name;
}

/**
 * camel_imapx_status_response_get_messages:
 * @response: a #CamelIMAPXStatusResponse
 * @out_messages: return location for the status value, or %NULL
 *
 * If @response includes an updated "MESSAGES" value, write the value to
 * @out_messages and return %TRUE.  Otherwise leave @out_messages unset
 * and return %FALSE.
 *
 * The "MESSAGES" value refers to the number of messages in the mailbox.
 *
 * The @out_messages argument can be %NULL, in which case the function
 * simply returns whether an updated "MESSAGES" value is present.
 *
 * Returns: whether @out_messages was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_messages (CamelIMAPXStatusResponse *response,
                                          guint32 *out_messages)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_messages != NULL && response->priv->have_messages)
		*out_messages = response->priv->messages;

	return response->priv->have_messages;
}

/**
 * camel_imapx_status_response_get_recent:
 * @response: a #CamelIMAPXStatusResponse
 * @out_recent: return location for the status value, or %NULL
 *
 * If @response includes an updated "RECENT" value, write the value to
 * @out_recent and return %TRUE.  Otherwise leave @out_recent unset and
 * return %FALSE.
 *
 * The "RECENT" value refers to the number of messages with the \Recent
 * flag set.
 *
 * The @out_recent argument can be %NULL, in which case the function
 * simply returns whether an updated "RECENT" value is present.
 *
 * Returns: whether @out_recent was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_recent (CamelIMAPXStatusResponse *response,
                                        guint32 *out_recent)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_recent != NULL && response->priv->have_recent)
		*out_recent = response->priv->recent;

	return response->priv->have_recent;
}

/**
 * camel_imapx_status_response_get_unseen:
 * @response: a #CamelIMAPXStatusResponse
 * @out_unseen: return location for the status value, or %NULL
 *
 * If @response includes an updated "UNSEEN" value, write the value to
 * @out_unseen and return %TRUE.  Otherwise leave @out_unseen unset and
 * return %FALSE.
 *
 * The "UNSEEN" value refers to the number of messages which do not have
 * the \Seen flag set.
 *
 * The @out_unseen argument can be %NULL, in which case the function
 * simply returns whether an updated "UNSEEN" value is present.
 *
 * Returns: whether @out_unseen was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_unseen (CamelIMAPXStatusResponse *response,
                                        guint32 *out_unseen)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_unseen != NULL && response->priv->have_unseen)
		*out_unseen = response->priv->unseen;

	return response->priv->have_unseen;
}

/**
 * camel_imapx_status_response_get_uidnext:
 * @response: a #CamelIMAPXStatusResponse
 * @out_uidnext: return location for the status value, or %NULL
 *
 * If @response includes an updated "UIDNEXT" value, write the value to
 * @out_uidnext and return %TRUE.  Otherwise leave @out_uidnext unset and
 * return %FALSE.
 *
 * The "UIDNEXT" value refers to the next unique identifier value of the
 * mailbox.
 *
 * The @out_uidnext argument can be %NULL, in which case the function
 * simply returns whether an updated "UIDNEXT" value is present.
 *
 * Returns: whether @out_uidnext was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_uidnext (CamelIMAPXStatusResponse *response,
                                         guint32 *out_uidnext)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_uidnext != NULL && response->priv->have_uidnext)
		*out_uidnext = response->priv->uidnext;

	return response->priv->have_uidnext;
}

/**
 * camel_imapx_status_response_get_uidvalidity:
 * @response: a #CamelIMAPXStatusResponse
 * @out_uidvalidity: return location for the status value, or %NULL
 *
 * If @response includes an updated "UIDVALIDITY" value, write the value to
 * @out_uidvalidity and return %TRUE.  Otherwise leave @out_uidvalidity unset
 * and return %FALSE.
 *
 * The "UIDVALIDITY" value refers to the unique identifier validity of the
 * mailbox.
 *
 * The @out_uidvalidity argument can be %NULL, in which case the function
 * simply returns whether an updated "UIDVALIDITY" value is present.
 *
 * Returns: whether @out_uidvalidity was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_uidvalidity (CamelIMAPXStatusResponse *response,
                                             guint32 *out_uidvalidity)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_uidvalidity != NULL && response->priv->have_uidvalidity)
		*out_uidvalidity = response->priv->uidvalidity;

	return response->priv->have_uidvalidity;
}

/**
 * camel_imapx_status_response_get_highestmodseq:
 * @response: a #CamelIMAPXStatusResponse
 * @out_highestmodseq: return location for the status value, or %NULL
 *
 * If @response includes an updated "HIGHESTMODSEQ" value, write the value to
 * @out_highestmodseq and return %TRUE.  Otherwise leave @out_highestmodseq
 * unset and return %FALSE.
 *
 * The "HIGHESTMODSEQ" value refers to the the highest mod-sequence value of
 * all messages in the mailbox, assuming the server supports the persistent
 * storage of mod-sequences.
 *
 * The @out_highestmodseq argument can be %NULL, in which case the function
 * simply returns whether an updated "HIGHESTMODSEQ" value is present.
 *
 * Returns: whether @out_highestmodseq was set
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_status_response_get_highestmodseq (CamelIMAPXStatusResponse *response,
                                               guint64 *out_highestmodseq)
{
	g_return_val_if_fail (
		CAMEL_IS_IMAPX_STATUS_RESPONSE (response), FALSE);

	if (out_highestmodseq != NULL && response->priv->have_highestmodseq)
		*out_highestmodseq = response->priv->highestmodseq;

	return response->priv->have_highestmodseq;
}

