/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
/* camel-mime-part-utils : Utility for mime parsing and so on
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 *          Michael Zucchi <notzed@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "camel-charset-map.h"
#include "camel-html-parser.h"
#include "camel-iconv.h"
#include "camel-mime-filter-basic.h"
#include "camel-mime-filter-charset.h"
#include "camel-mime-filter-crlf.h"
#include "camel-mime-message.h"
#include "camel-mime-part-utils.h"
#include "camel-multipart-encrypted.h"
#include "camel-multipart-signed.h"
#include "camel-multipart.h"
#include "camel-stream-filter.h"
#include "camel-stream-fs.h"
#include "camel-stream-mem.h"
#include "camel-stream-buffer.h"
#include "camel-utf8.h"

#define d(x) /* (printf("%s(%d): ", __FILE__, __LINE__),(x)) */

/* simple data wrapper */
static gboolean
simple_data_wrapper_construct_from_parser (CamelDataWrapper *dw,
                                           CamelMimeParser *mp,
                                           GCancellable *cancellable,
                                           GError **error)
{
	gchar *buf;
	GByteArray *buffer;
	CamelStream *mem;
	gsize len;
	gboolean success;

	d (printf ("simple_data_wrapper_construct_from_parser()\n"));

	/* read in the entire content */
	buffer = g_byte_array_new ();
	while (camel_mime_parser_step (mp, &buf, &len) != CAMEL_MIME_PARSER_STATE_BODY_END) {
		d (printf ("appending o/p data: %d: %.*s\n", len, len, buf));
		g_byte_array_append (buffer, (guint8 *) buf, len);
	}

	d (printf ("message part kept in memory!\n"));

	mem = camel_stream_mem_new_with_byte_array (buffer);
	success = camel_data_wrapper_construct_from_stream_sync (
		dw, mem, cancellable, error);
	g_object_unref (mem);

	return success;
}

/**
 * camel_mime_part_construct_content_from_parser:
 * @mime_part: a #CamelMimePart
 * @mp: a #CamelMimeParser
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Constructs the contnet of @mime_part from the given mime parser.
 *
 * Returns: whether succeeded
 *
 * Since: 2.24
 **/
gboolean
camel_mime_part_construct_content_from_parser (CamelMimePart *mime_part,
                                               CamelMimeParser *mp,
                                               GCancellable *cancellable,
                                               GError **error)
{
	CamelDataWrapper *content = NULL;
	CamelContentType *ct;
	gchar *encoding;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), FALSE);

	ct = camel_mime_parser_content_type (mp);

	encoding = camel_content_transfer_encoding_decode (camel_mime_parser_header (mp, "Content-Transfer-Encoding", NULL));

	switch (camel_mime_parser_state (mp)) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
		d (printf ("Creating body part\n"));
		/* multipart/signed is some type that we must treat as binary data. */
		if (camel_content_type_is (ct, "multipart", "signed")) {
			content = (CamelDataWrapper *) camel_multipart_signed_new ();
			camel_multipart_construct_from_parser ((CamelMultipart *) content, mp);
		} else {
			content = camel_data_wrapper_new ();
			success = simple_data_wrapper_construct_from_parser (
				content, mp, cancellable, error);
		}
		break;
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
		d (printf ("Creating message part\n"));
		content = (CamelDataWrapper *) camel_mime_message_new ();
		success = camel_mime_part_construct_from_parser_sync (
			(CamelMimePart *) content, mp, cancellable, error);
		break;
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		d (printf ("Creating multi-part\n"));
		if (camel_content_type_is (ct, "multipart", "encrypted"))
			content = (CamelDataWrapper *) camel_multipart_encrypted_new ();
		else if (camel_content_type_is (ct, "multipart", "signed"))
			content = (CamelDataWrapper *) camel_multipart_signed_new ();
		else
			content = (CamelDataWrapper *) camel_multipart_new ();

		camel_multipart_construct_from_parser ((CamelMultipart *) content, mp);
		d (printf ("Created multi-part\n"));
		break;
	default:
		g_warning ("Invalid state encountered???: %u", camel_mime_parser_state (mp));
	}

	if (content) {
		if (encoding)
			camel_data_wrapper_set_encoding (content, camel_transfer_encoding_from_string (encoding));

		camel_data_wrapper_set_mime_type_field (content, camel_mime_part_get_content_type (mime_part));
		camel_medium_set_content (CAMEL_MEDIUM (mime_part), content);
		g_object_unref (content);
	}

	g_free (encoding);

	return success;
}

G_DEFINE_BOXED_TYPE (CamelMessageContentInfo,
		camel_message_content_info,
		camel_message_content_info_copy,
		camel_message_content_info_free)

/**
 * camel_message_content_info_new:
 *
 * Allocate a new #CamelMessageContentInfo.
 *
 * Returns: (transfer full): a newly allocated #CamelMessageContentInfo
 **/
CamelMessageContentInfo *
camel_message_content_info_new (void)
{
	return g_slice_alloc0 (sizeof (CamelMessageContentInfo));
}

/**
 * camel_message_content_info_copy:
 * @src: (nullable): a source #CamelMessageContentInfo to copy
 *
 * Returns: a copy of @src, or %NULL, if @src was %NULL
 *
 * Since: 3.24
 **/
CamelMessageContentInfo *
camel_message_content_info_copy (const CamelMessageContentInfo *src)
{
	CamelMessageContentInfo *res;

	if (!src)
		return NULL;

	res = camel_message_content_info_new ();

	if (src->type) {
		gchar *content_type;

		content_type = camel_content_type_format (src->type);
		res->type = camel_content_type_decode (content_type);

		g_free (content_type);
	}

	if (src->disposition) {
		gchar *disposition;

		disposition = camel_content_disposition_format (src->disposition);
		res->disposition = camel_content_disposition_decode (disposition);

		g_free (disposition);
	}

	res->id = g_strdup (src->id);
	res->description = g_strdup (src->description);
	res->encoding = g_strdup (src->encoding);
	res->size = src->size;

	res->next = camel_message_content_info_copy (src->next);
	res->childs = camel_message_content_info_copy (src->childs);

	if (res->childs) {
		CamelMessageContentInfo *child;

		for (child = res->childs; child; child = child->next) {
			child->parent = res;
		}
	}

	return res;
}

/**
 * camel_message_content_info_free:
 * @ci: a #CamelMessageContentInfo
 *
 * Recursively frees the content info @ci, and all associated memory.
 **/
void
camel_message_content_info_free (CamelMessageContentInfo *ci)
{
	CamelMessageContentInfo *pw, *pn;

	pw = ci->childs;

	camel_content_type_unref (ci->type);
	camel_content_disposition_unref (ci->disposition);
	g_free (ci->id);
	g_free (ci->description);
	g_free (ci->encoding);
	g_slice_free1 (sizeof (CamelMessageContentInfo), ci);

	while (pw) {
		pn = pw->next;
		camel_message_content_info_free (pw);
		pw = pn;
	}
}

CamelMessageContentInfo *
camel_message_content_info_new_from_parser (CamelMimeParser *mp)
{
	CamelMessageContentInfo *ci = NULL;
	CamelNameValueArray *headers = NULL;

	g_return_val_if_fail (CAMEL_IS_MIME_PARSER (mp), NULL);

	switch (camel_mime_parser_state (mp)) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		headers = camel_mime_parser_dup_headers (mp);
		ci = camel_message_content_info_new_from_headers (headers);
		camel_name_value_array_free (headers);
		if (ci) {
			if (ci->type)
				camel_content_type_unref (ci->type);
			ci->type = camel_mime_parser_content_type (mp);
			camel_content_type_ref (ci->type);
		}
		break;
	default:
		g_error ("Invalid parser state");
	}

	return ci;
}

CamelMessageContentInfo *
camel_message_content_info_new_from_message (CamelMimePart *mp)
{
	CamelMessageContentInfo *ci = NULL;
	const CamelNameValueArray *headers = NULL;

	g_return_val_if_fail (CAMEL_IS_MIME_PART (mp), NULL);

	headers = camel_medium_get_headers (CAMEL_MEDIUM (mp));
	ci = camel_message_content_info_new_from_headers (headers);

	return ci;
}

CamelMessageContentInfo *
camel_message_content_info_new_from_headers (const CamelNameValueArray *headers)
{
	CamelMessageContentInfo *ci;
	const gchar *charset;

	ci = camel_message_content_info_new ();

	charset = camel_iconv_locale_charset ();
	ci->id = camel_header_msgid_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-ID"));
	ci->description = camel_header_decode_string (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Description"), charset);
	ci->encoding = camel_content_transfer_encoding_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Transfer-Encoding"));
	ci->type = camel_content_type_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Type"));
	ci->disposition = camel_content_disposition_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Disposition"));

	return ci;
}

/* Calls the @func for each ci, including the top one. The @func can return TRUE to
   continue processing or FALSE to stop it.
   The function returns FALSE on error or when the @func returned FALSE, otherwise
   it returns TRUE. */
gboolean
camel_message_content_info_traverse (CamelMessageContentInfo *ci,
				     gboolean (* func) (CamelMessageContentInfo *ci,
							gint depth,
							gpointer user_data),
				     gpointer user_data)
{
	CamelMessageContentInfo *next, *cur;
	gint depth = 0;

	g_return_val_if_fail (ci != NULL, FALSE);
	g_return_val_if_fail (func != NULL, FALSE);

	cur = ci;
	do {
		if (!func (cur, depth, user_data))
			return FALSE;

		next = cur->childs;
		if (next)
			depth++;
		else
			next = cur->next;

		if (!next) {
			next = cur->parent;
			depth--;

			if (depth < 0) {
				next = NULL;
				break;
			}

			while (next) {
				CamelMessageContentInfo *sibl;

				sibl = next->next;
				if (sibl) {
					next = sibl;
					break;
				}

				next = next->parent;
				depth--;

				if (depth < 0) {
					next = NULL;
					break;
				}
			}
		}

		cur = next;
	} while (cur);

	return TRUE;
}

static gboolean
dump_content_into_cb (CamelMessageContentInfo *ci,
		      gint depth,
		      gpointer user_data)
{
	depth = (GPOINTER_TO_INT (user_data) + depth) * 4;

	if (ci->type)
		printf ("%*scontent-type: %s/%s\n", depth, "",
			ci->type->type ? ci->type->type : "(null)",
			ci->type->subtype ? ci->type->subtype : "(null)");
	else
		printf ("%*scontent-type: <unset>\n", depth, "");

	printf ("%*scontent-transfer-encoding: %s\n", depth, "", ci->encoding ? ci->encoding : "(null)");
	printf ("%*scontent-description: %s\n", depth, "", ci->description ? ci->description : "(null)");

	if (ci->disposition) {
		gchar *disposition;

		disposition = camel_content_disposition_format (ci->disposition);
		printf ("%*scontent-disposition: %s\n", depth, "", disposition ? disposition : "(null)");
		g_free (disposition);
	} else {
		printf ("%*scontent-disposition: <unset>\n", depth, "");
	}

	printf ("%*ssize: %" G_GUINT32_FORMAT "\n", depth, "", ci->size);

	return TRUE;
}

void
camel_message_content_info_dump (CamelMessageContentInfo *ci,
				 gint depth)
{
	if (ci == NULL) {
		printf ("%*s<empty>\n", depth * 4, "");
		return;
	}

	camel_message_content_info_traverse (ci, dump_content_into_cb, GINT_TO_POINTER (depth));
}
