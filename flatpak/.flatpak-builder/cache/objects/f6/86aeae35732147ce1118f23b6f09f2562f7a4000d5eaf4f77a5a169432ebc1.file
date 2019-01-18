/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
/* camelMimePart.c : Abstract class for a mime_part
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
 *	    Michael Zucchi <notzed@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "camel-charset-map.h"
#include "camel-debug.h"
#include "camel-iconv.h"
#include "camel-filter-output-stream.h"
#include "camel-mime-filter-basic.h"
#include "camel-mime-filter-charset.h"
#include "camel-mime-filter-crlf.h"
#include "camel-mime-parser.h"
#include "camel-mime-part-utils.h"
#include "camel-mime-part.h"
#include "camel-mime-utils.h"
#include "camel-stream-filter.h"
#include "camel-stream-mem.h"
#include "camel-stream-null.h"
#include "camel-string-utils.h"

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#define CAMEL_MIME_PART_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_PART, CamelMimePartPrivate))

typedef struct _AsyncContext AsyncContext;

struct _CamelMimePartPrivate {
	gchar *description;
	CamelContentDisposition *disposition;
	gchar *content_id;
	gchar *content_md5;
	gchar *content_location;
	GList *content_languages;
	CamelTransferEncoding encoding;
	/* mime headers */
	CamelNameValueArray *headers;
};

struct _AsyncContext {
	CamelMimeParser *parser;
};

enum {
	PROP_0,
	PROP_CONTENT_ID,
	PROP_CONTENT_LOCATION,
	PROP_CONTENT_MD5,
	PROP_DESCRIPTION,
	PROP_DISPOSITION,
	PROP_FILENAME
};

typedef enum {
	HEADER_UNKNOWN,
	HEADER_DESCRIPTION,
	HEADER_DISPOSITION,
	HEADER_CONTENT_ID,
	HEADER_ENCODING,
	HEADER_CONTENT_MD5,
	HEADER_CONTENT_LOCATION,
	HEADER_CONTENT_LANGUAGES,
	HEADER_CONTENT_TYPE
} CamelHeaderType;

static GHashTable *header_name_table;
static GHashTable *header_formatted_table;

G_DEFINE_TYPE (CamelMimePart, camel_mime_part, CAMEL_TYPE_MEDIUM)

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->parser != NULL)
		g_object_unref (async_context->parser);

	g_slice_free (AsyncContext, async_context);
}

static gssize
write_header (gpointer stream,
              const gchar *name,
              const gchar *value,
              GCancellable *cancellable,
              GError **error)
{
	GString *buffer;
	gssize n_written = 0;

	buffer = g_string_new (name);
	g_string_append_c (buffer, ':');
	if (!isspace (value[0]))
		g_string_append_c (buffer, ' ');
	g_string_append (buffer, value);
	g_string_append_c (buffer, '\n');

	/* XXX For now we handle both types of streams. */

	if (CAMEL_IS_STREAM (stream)) {
		n_written = camel_stream_write (
			CAMEL_STREAM (stream),
			buffer->str, buffer->len,
			cancellable, error);
	} else if (G_IS_OUTPUT_STREAM (stream)) {
		gboolean success;
		gsize bytes_written = 0;

		success = g_output_stream_write_all (
			G_OUTPUT_STREAM (stream),
			buffer->str, buffer->len,
			&bytes_written, cancellable, error);
		if (success)
			n_written = (gssize) bytes_written;
		else
			n_written = -1;
	} else {
		g_warn_if_reached ();
	}

	g_string_free (buffer, TRUE);

	return n_written;
}

static gssize
write_references (gpointer stream,
                  const gchar *name,
                  const gchar *value,
                  GCancellable *cancellable,
                  GError **error)
{
	GString *buffer;
	const gchar *ids, *ide;
	gssize n_written = 0;
	gsize len;

	/* this is only approximate, based on the next >, this way it retains
	 * any content from the original which may not be properly formatted,
	 * etc.  It also doesn't handle the case where an individual messageid
	 * is too long, however thats a bad mail to start with ... */

	buffer = g_string_new (name);
	g_string_append_c (buffer, ':');
	if (!isspace (value[0]))
		g_string_append_c (buffer, ' ');

	/* Fold only when not folded already */
	if (!strchr (value, '\n')) {
		len = buffer->len;

		while (*value) {
			ids = value;
			ide = strchr (ids + 1, '>');
			if (ide)
				value = ++ide;
			else
				ide = value = strlen (ids) + ids;

			if (len > 0 && len + (ide - ids) >= CAMEL_FOLD_SIZE) {
				g_string_append_len (buffer, "\n\t", 2);
				len = 0;
			}

			g_string_append_len (buffer, ids, ide - ids);
			len += (ide - ids);
		}
	} else {
		g_string_append (buffer, value);
	}

	if (buffer->len > 0 && buffer->str[buffer->len - 1] != '\n')
		g_string_append_c (buffer, '\n');

	/* XXX For now we handle both types of streams. */

	if (CAMEL_IS_STREAM (stream)) {
		n_written = camel_stream_write (
			CAMEL_STREAM (stream),
			buffer->str, buffer->len,
			cancellable, error);
	} else if (G_IS_OUTPUT_STREAM (stream)) {
		gboolean success;
		gsize bytes_written = 0;

		success = g_output_stream_write_all (
			G_OUTPUT_STREAM (stream),
			buffer->str, buffer->len,
			&bytes_written, cancellable, error);
		if (success)
			n_written = (gssize) bytes_written;
		else
			n_written = -1;
	} else {
		g_warn_if_reached ();
	}

	g_string_free (buffer, TRUE);

	return n_written;
}

/* loads in a hash table the set of header names we */
/* recognize and associate them with a unique enum  */
/* identifier (see CamelHeaderType above)           */
static void
init_header_name_table (void)
{
	if (header_name_table)
		return;

	header_name_table = g_hash_table_new (
		camel_strcase_hash, camel_strcase_equal);
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-Description",
		GINT_TO_POINTER (HEADER_DESCRIPTION));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-Disposition",
		GINT_TO_POINTER (HEADER_DISPOSITION));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-id",
		GINT_TO_POINTER (HEADER_CONTENT_ID));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-Transfer-Encoding",
		GINT_TO_POINTER (HEADER_ENCODING));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-MD5",
		GINT_TO_POINTER (HEADER_CONTENT_MD5));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-Location",
		GINT_TO_POINTER (HEADER_CONTENT_LOCATION));
	g_hash_table_insert (
		header_name_table,
		(gpointer) "Content-Type",
		GINT_TO_POINTER (HEADER_CONTENT_TYPE));

	header_formatted_table = g_hash_table_new (
		camel_strcase_hash, camel_strcase_equal);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "Content-Type", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "Content-Disposition", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "From", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "Reply-To", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "Message-ID", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "In-Reply-To", write_header);
	g_hash_table_insert (
		header_formatted_table,
		(gpointer) "References", write_references);
}

static void
mime_part_set_disposition (CamelMimePart *mime_part,
                           const gchar *disposition)
{
	camel_content_disposition_unref (mime_part->priv->disposition);
	if (disposition)
		mime_part->priv->disposition =
			camel_content_disposition_decode (disposition);
	else
		mime_part->priv->disposition = NULL;
}

static gboolean
mime_part_process_header (CamelMedium *medium,
                          const gchar *name,
                          const gchar *value)
{
	CamelMimePart *mime_part = CAMEL_MIME_PART (medium);
	CamelHeaderType header_type;
	CamelContentType *content_type;
	const gchar *charset;
	gchar *text;

	/* Try to parse the header pair. If it corresponds to something   */
	/* known, the job is done in the parsing routine. If not,         */
	/* we simply add the header in a raw fashion                      */

	header_type = (CamelHeaderType) GPOINTER_TO_INT (g_hash_table_lookup (header_name_table, name));
	switch (header_type) {
	case HEADER_DESCRIPTION: /* raw header->utf8 conversion */
		g_free (mime_part->priv->description);
		if (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (mime_part))) {
			charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (mime_part)), "charset");
			charset = camel_iconv_charset_name (charset);
		} else
			charset = NULL;
		mime_part->priv->description = g_strstrip (camel_header_decode_string (value, charset));
		break;
	case HEADER_DISPOSITION:
		mime_part_set_disposition (mime_part, value);
		break;
	case HEADER_CONTENT_ID:
		g_free (mime_part->priv->content_id);
		mime_part->priv->content_id = camel_header_contentid_decode (value);
		break;
	case HEADER_ENCODING:
		text = camel_header_token_decode (value);
		mime_part->priv->encoding = camel_transfer_encoding_from_string (text);
		g_free (text);
		break;
	case HEADER_CONTENT_MD5:
		g_free (mime_part->priv->content_md5);
		mime_part->priv->content_md5 = g_strdup (value);
		break;
	case HEADER_CONTENT_LOCATION:
		g_free (mime_part->priv->content_location);
		mime_part->priv->content_location = camel_header_location_decode (value);
		break;
	case HEADER_CONTENT_TYPE:
		content_type = camel_content_type_decode (value);
		if (content_type)
			camel_data_wrapper_take_mime_type_field (CAMEL_DATA_WRAPPER (mime_part), content_type);
		break;
	default:
		return FALSE;
	}
	return TRUE;
}

static void
mime_part_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONTENT_ID:
			camel_mime_part_set_content_id (
				CAMEL_MIME_PART (object),
				g_value_get_string (value));
			return;

		case PROP_CONTENT_MD5:
			camel_mime_part_set_content_md5 (
				CAMEL_MIME_PART (object),
				g_value_get_string (value));
			return;

		case PROP_CONTENT_LOCATION:
			camel_mime_part_set_content_location (
				CAMEL_MIME_PART (object),
				g_value_get_string (value));
			return;

		case PROP_DESCRIPTION:
			camel_mime_part_set_description (
				CAMEL_MIME_PART (object),
				g_value_get_string (value));
			return;

		case PROP_DISPOSITION:
			camel_mime_part_set_disposition (
				CAMEL_MIME_PART (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
mime_part_get_property (GObject *object,
                        guint property_id,
                        GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONTENT_ID:
			g_value_set_string (
				value, camel_mime_part_get_content_id (
				CAMEL_MIME_PART (object)));
			return;

		case PROP_CONTENT_MD5:
			g_value_set_string (
				value, camel_mime_part_get_content_md5 (
				CAMEL_MIME_PART (object)));
			return;

		case PROP_CONTENT_LOCATION:
			g_value_set_string (
				value, camel_mime_part_get_content_location (
				CAMEL_MIME_PART (object)));
			return;

		case PROP_DESCRIPTION:
			g_value_set_string (
				value, camel_mime_part_get_description (
				CAMEL_MIME_PART (object)));
			return;

		case PROP_DISPOSITION:
			g_value_set_string (
				value, camel_mime_part_get_disposition (
				CAMEL_MIME_PART (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
mime_part_finalize (GObject *object)
{
	CamelMimePartPrivate *priv;

	priv = CAMEL_MIME_PART_GET_PRIVATE (object);

	g_free (priv->description);
	g_free (priv->content_id);
	g_free (priv->content_md5);
	g_free (priv->content_location);

	g_list_free_full (priv->content_languages, (GDestroyNotify) g_free);
	camel_content_disposition_unref (priv->disposition);
	camel_name_value_array_free (priv->headers);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_mime_part_parent_class)->finalize (object);
}

static void
mime_part_add_header (CamelMedium *medium,
                      const gchar *name,
                      const gchar *value)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);

	/* Try to parse the header pair. If it corresponds to something   */
	/* known, the job is done in the parsing routine. If not,         */
	/* we simply add the header in a raw fashion                      */

	/* If it was one of the headers we handled, it must be unique, set it instead of add */
	if (mime_part_process_header (medium, name, value))
		camel_name_value_array_remove_named (part->priv->headers, CAMEL_COMPARE_CASE_INSENSITIVE, name, TRUE);

	camel_name_value_array_append (part->priv->headers, name, value);
}

static void
mime_part_set_header (CamelMedium *medium,
                      const gchar *name,
                      const gchar *value)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);

	mime_part_process_header (medium, name, value);
	camel_name_value_array_remove_named (part->priv->headers, CAMEL_COMPARE_CASE_INSENSITIVE, name, TRUE);

	camel_name_value_array_append (part->priv->headers, name, value);
}

static void
mime_part_remove_header (CamelMedium *medium,
                         const gchar *name)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);

	mime_part_process_header (medium, name, NULL);
	camel_name_value_array_remove_named (part->priv->headers, CAMEL_COMPARE_CASE_INSENSITIVE, name, TRUE);
}

static const gchar *
mime_part_get_header (CamelMedium *medium,
                      const gchar *name)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);
	const gchar *value;

	value = camel_name_value_array_get_named (part->priv->headers, CAMEL_COMPARE_CASE_INSENSITIVE, name);

	/* Skip leading whitespace. */
	while (value != NULL && g_ascii_isspace (*value))
		value++;

	return value;
}

static CamelNameValueArray *
mime_part_dup_headers (CamelMedium *medium)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);

	return camel_name_value_array_copy (part->priv->headers);
}

static const CamelNameValueArray *
mime_part_get_headers (CamelMedium *medium)
{
	CamelMimePart *part = CAMEL_MIME_PART (medium);

	return part->priv->headers;
}

static void
mime_part_set_content (CamelMedium *medium,
                       CamelDataWrapper *content)
{
	CamelDataWrapper *mime_part = CAMEL_DATA_WRAPPER (medium);
	CamelMediumClass *medium_class;
	CamelContentType *content_type;

	/* Chain up to parent's set_content() method. */
	medium_class = CAMEL_MEDIUM_CLASS (camel_mime_part_parent_class);
	medium_class->set_content (medium, content);

	content_type = camel_data_wrapper_get_mime_type_field (content);
	if (camel_data_wrapper_get_mime_type_field (mime_part) != content_type) {
		gchar *txt;

		txt = camel_content_type_format (content_type);
		camel_medium_set_header (medium, "Content-Type", txt);
		g_free (txt);
	}
}

static gssize
mime_part_write_to_stream_sync (CamelDataWrapper *dw,
                                CamelStream *stream,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelMimePart *mp = CAMEL_MIME_PART (dw);
	CamelMedium *medium = CAMEL_MEDIUM (dw);
	CamelStream *ostream = stream;
	CamelDataWrapper *content;
	gssize total = 0;
	gssize count;
	gint errnosav;
	guint ii;
	const gchar *header_name = NULL, *header_value = NULL;

	d (printf ("mime_part::write_to_stream\n"));

	/* FIXME: something needs to be done about this ... */
	/* TODO: content-languages header? */

	for (ii = 0; camel_name_value_array_get (mp->priv->headers, ii, &header_name, &header_value); ii++) {
		gssize (*writefn) (
			gpointer stream,
			const gchar *name,
			const gchar *value,
			GCancellable *cancellable,
			GError **error);
		if (header_value == NULL) {
			g_warning ("header_value is NULL here for %s", header_name);
			count = 0;
		} else if ((writefn = g_hash_table_lookup (header_formatted_table, header_name)) == NULL) {
			gchar *val = camel_header_fold (header_value, strlen (header_name));
			count = write_header (
				stream, header_name, val,
				cancellable, error);
			g_free (val);
		} else {
			count = writefn (
				stream, header_name, header_value,
				cancellable, error);
		}
		if (count == -1)
			return -1;
		total += count;
	}

	count = camel_stream_write (stream, "\n", 1, cancellable, error);
	if (count == -1)
		return -1;
	total += count;

	content = camel_medium_get_content (medium);
	if (content) {
		CamelMimeFilter *filter = NULL;
		CamelStream *filter_stream = NULL;
		CamelMimeFilter *charenc = NULL;
		const gchar *content_charset = NULL;
		const gchar *part_charset = NULL;
		gboolean reencode = FALSE;
		const gchar *filename;

		if (camel_content_type_is (camel_data_wrapper_get_mime_type_field (dw), "text", "*")) {
			content_charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (content), "charset");
			part_charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (dw), "charset");

			if (content_charset && part_charset) {
				content_charset = camel_iconv_charset_name (content_charset);
				part_charset = camel_iconv_charset_name (part_charset);
			}
		}

		if (mp->priv->encoding != camel_data_wrapper_get_encoding (content)) {
			gchar *content;

			switch (mp->priv->encoding) {
			case CAMEL_TRANSFER_ENCODING_BASE64:
				filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_BASE64_ENC);
				break;
			case CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE:
				filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_QP_ENC);
				break;
			case CAMEL_TRANSFER_ENCODING_UUENCODE:
				filename = camel_mime_part_get_filename (mp);
				if (filename == NULL)
					filename = "untitled";

				content = g_strdup_printf (
					"begin 644 %s\n", filename);
				count = camel_stream_write_string (
					ostream, content, cancellable, error);
				g_free (content);

				if (count == -1)
					return -1;

				total += count;
				filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_UU_ENC);
				break;
			default:
				/* content is encoded but the part doesn't want to be... */
				reencode = TRUE;
				break;
			}
		}

		if (content_charset && part_charset && part_charset != content_charset)
			charenc = camel_mime_filter_charset_new (content_charset, part_charset);

		if (filter || charenc) {
			filter_stream = camel_stream_filter_new (stream);

			/* if we have a character encoder, add that always */
			if (charenc) {
				camel_stream_filter_add (
					CAMEL_STREAM_FILTER (filter_stream), charenc);
				g_object_unref (charenc);
			}

			if (filter) {
				camel_stream_filter_add (
					CAMEL_STREAM_FILTER (filter_stream), filter);
				g_object_unref (filter);
			}

			stream = filter_stream;

			reencode = TRUE;
		}

		if (reencode)
			count = camel_data_wrapper_decode_to_stream_sync (
				content, stream, cancellable, error);
		else
			count = camel_data_wrapper_write_to_stream_sync (
				content, stream, cancellable, error);

		if (filter_stream) {
			errnosav = errno;
			camel_stream_flush (stream, NULL, NULL);
			g_object_unref (filter_stream);
			errno = errnosav;
		}

		if (count == -1)
			return -1;

		total += count;

		if (reencode && mp->priv->encoding == CAMEL_TRANSFER_ENCODING_UUENCODE) {
			count = camel_stream_write (
				ostream, "end\n", 4, cancellable, error);
			if (count == -1)
				return -1;
			total += count;
		}
	} else {
		g_warning ("No content for medium, nothing to write");
	}

	return total;
}

static gboolean
mime_part_construct_from_stream_sync (CamelDataWrapper *dw,
                                      CamelStream *stream,
                                      GCancellable *cancellable,
                                      GError **error)
{
	CamelMimeParser *parser;
	gboolean success;

	d (printf ("mime_part::construct_from_stream()\n"));

	parser = camel_mime_parser_new ();
	if (camel_mime_parser_init_with_stream (parser, stream, error) == -1) {
		success = FALSE;
	} else {
		success = camel_mime_part_construct_from_parser_sync (
			CAMEL_MIME_PART (dw), parser, cancellable, error);
	}
	g_object_unref (parser);

	return success;
}

static gssize
mime_part_write_to_output_stream_sync (CamelDataWrapper *dw,
                                       GOutputStream *output_stream,
                                       GCancellable *cancellable,
                                       GError **error)
{
	CamelMimePart *mp = CAMEL_MIME_PART (dw);
	CamelMedium *medium = CAMEL_MEDIUM (dw);
	CamelDataWrapper *content;
	gsize bytes_written;
	gssize total = 0;
	gssize result;
	gboolean success;
	guint ii;
	const gchar *header_name = NULL, *header_value = NULL;

	d (printf ("mime_part::write_to_stream\n"));

	/* FIXME: something needs to be done about this ... */
	/* TODO: content-languages header? */

	for (ii = 0; camel_name_value_array_get (mp->priv->headers, ii, &header_name, &header_value); ii++) {
		gssize (*writefn) (
			gpointer stream,
			const gchar *name,
			const gchar *value,
			GCancellable *cancellable,
			GError **error);
		if (header_value == NULL) {
			g_warning ("header_value is NULL here for %s", header_name);
			bytes_written = 0;
			result = 0;
		} else if ((writefn = g_hash_table_lookup (header_formatted_table, header_name)) == NULL) {
			gchar *val = camel_header_fold (header_value, strlen (header_name));
			result = write_header (
				output_stream, header_name, val,
				cancellable, error);
			g_free (val);
		} else {
			result = writefn (
				output_stream, header_name, header_value,
				cancellable, error);
		}
		if (result == -1)
			return -1;
		total += result;
	}

	success = g_output_stream_write_all (
		output_stream, "\n", 1,
		&bytes_written, cancellable, error);
	if (!success)
		return -1;
	total += (gssize) bytes_written;

	content = camel_medium_get_content (medium);
	if (content) {
		CamelMimeFilter *filter = NULL;
		GOutputStream *filter_stream;
		const gchar *content_charset = NULL;
		const gchar *part_charset = NULL;
		gboolean content_type_is_text;
		gboolean uuencoded = FALSE;
		gboolean reencode = FALSE;
		const gchar *filename;

		content_type_is_text =
			camel_content_type_is (camel_data_wrapper_get_mime_type_field (dw), "text", "*");

		if (content_type_is_text) {
			content_charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (content), "charset");
			part_charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (dw), "charset");

			if (content_charset && part_charset) {
				content_charset = camel_iconv_charset_name (content_charset);
				part_charset = camel_iconv_charset_name (part_charset);
			}
		}

		if (mp->priv->encoding != camel_data_wrapper_get_encoding (content)) {
			gchar *content;

			switch (mp->priv->encoding) {
			case CAMEL_TRANSFER_ENCODING_BASE64:
				filter = camel_mime_filter_basic_new (
					CAMEL_MIME_FILTER_BASIC_BASE64_ENC);
				break;
			case CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE:
				filter = camel_mime_filter_basic_new (
					CAMEL_MIME_FILTER_BASIC_QP_ENC);
				break;
			case CAMEL_TRANSFER_ENCODING_UUENCODE:
				filename = camel_mime_part_get_filename (mp);
				if (filename == NULL)
					filename = "untitled";

				content = g_strdup_printf (
					"begin 644 %s\n", filename);
				success = g_output_stream_write_all (
					output_stream,
					content, strlen (content),
					&bytes_written, cancellable, error);
				g_free (content);

				if (!success)
					return -1;

				uuencoded = TRUE;

				total += bytes_written;
				filter = camel_mime_filter_basic_new (
					CAMEL_MIME_FILTER_BASIC_UU_ENC);
				break;
			default:
				/* content is encoded but the part doesn't want to be... */
				reencode = TRUE;
				break;
			}
		}

		filter_stream = g_object_ref (output_stream);

		if (content_charset && part_charset && part_charset != content_charset) {
			CamelMimeFilter *charenc;
			GOutputStream *temp_stream;

			charenc = camel_mime_filter_charset_new (
				content_charset, part_charset);
			temp_stream = camel_filter_output_stream_new (
				filter_stream, charenc);
			g_filter_output_stream_set_close_base_stream (
				G_FILTER_OUTPUT_STREAM (temp_stream), FALSE);
			g_object_unref (charenc);

			g_object_unref (filter_stream);
			filter_stream = temp_stream;

			reencode = TRUE;
		}

		if (filter != NULL) {
			GOutputStream *temp_stream;

			temp_stream = camel_filter_output_stream_new (
				filter_stream, filter);
			g_filter_output_stream_set_close_base_stream (
				G_FILTER_OUTPUT_STREAM (temp_stream), FALSE);
			g_object_unref (filter);

			g_object_unref (filter_stream);
			filter_stream = temp_stream;

			reencode = TRUE;
		}

		if (reencode)
			result = camel_data_wrapper_decode_to_output_stream_sync (
				content, filter_stream, cancellable, error);
		else
			result = camel_data_wrapper_write_to_output_stream_sync (
				content, filter_stream, cancellable, error);

		g_object_unref (filter_stream);

		if (result == -1)
			return -1;

		total += result;

		if (uuencoded) {
			success = g_output_stream_write_all (
				output_stream, "end\n", 4,
				&bytes_written, cancellable, error);
			if (!success)
				return -1;
			total += (gssize) bytes_written;
		}
	} else {
		g_warning ("No content for medium, nothing to write");
	}

	return total;
}

static gboolean
mime_part_construct_from_input_stream_sync (CamelDataWrapper *dw,
                                            GInputStream *input_stream,
                                            GCancellable *cancellable,
                                            GError **error)
{
	CamelMimeParser *parser;
	gboolean success;

	parser = camel_mime_parser_new ();
	camel_mime_parser_init_with_input_stream (parser, input_stream);

	success = camel_mime_part_construct_from_parser_sync (
		CAMEL_MIME_PART (dw), parser, cancellable, error);

	g_object_unref (parser);

	return success;
}

static gboolean
mime_part_construct_from_parser_sync (CamelMimePart *mime_part,
                                      CamelMimeParser *parser,
                                      GCancellable *cancellable,
                                      GError **error)
{
	CamelDataWrapper *dw = (CamelDataWrapper *) mime_part;
	CamelNameValueArray *headers;
	const gchar *content;
	gchar *buf;
	gsize len;
	gint err;
	guint ii;
	gboolean success = TRUE;
	const gchar *header_name = NULL, *header_value = NULL;

	switch (camel_mime_parser_step (parser, &buf, &len)) {
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
		/* set the default type of a message always */
		camel_data_wrapper_take_mime_type_field (dw, camel_content_type_decode ("message/rfc822"));
		/* coverity[fallthrough] */
		/* falls through */

	case CAMEL_MIME_PARSER_STATE_HEADER:
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		/* we have the headers, build them into 'us' */
		headers = camel_mime_parser_dup_headers (parser);

		/* if content-type exists, process it first, set for fallback charset in headers */
		content = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Type");
		if (content)
			mime_part_process_header (CAMEL_MEDIUM (dw), "content-type", content);

		for (ii = 0; camel_name_value_array_get (headers, ii, &header_name, &header_value); ii++) {
			if (g_ascii_strcasecmp (header_name, "content-type") == 0 && header_value != content)
				camel_medium_add_header (CAMEL_MEDIUM (dw), "X-Invalid-Content-Type", header_value);
			else
				camel_medium_add_header (CAMEL_MEDIUM (dw), header_name, header_value);
		}

		camel_name_value_array_free (headers);

		success = camel_mime_part_construct_content_from_parser (
			mime_part, parser, cancellable, error);
		break;
	default:
		g_warning ("Invalid state encountered???: %u", camel_mime_parser_state (parser));
	}

	err = camel_mime_parser_errno (parser);
	if (err != 0) {
		errno = err;
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		success = FALSE;
	}

	return success;
}

static void
camel_mime_part_class_init (CamelMimePartClass *class)
{
	GObjectClass *object_class;
	CamelMediumClass *medium_class;
	CamelDataWrapperClass *data_wrapper_class;

	g_type_class_add_private (class, sizeof (CamelMimePartPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = mime_part_set_property;
	object_class->get_property = mime_part_get_property;
	object_class->finalize = mime_part_finalize;

	medium_class = CAMEL_MEDIUM_CLASS (class);
	medium_class->add_header = mime_part_add_header;
	medium_class->set_header = mime_part_set_header;
	medium_class->remove_header = mime_part_remove_header;
	medium_class->get_header = mime_part_get_header;
	medium_class->dup_headers = mime_part_dup_headers;
	medium_class->get_headers = mime_part_get_headers;
	medium_class->set_content = mime_part_set_content;

	data_wrapper_class = CAMEL_DATA_WRAPPER_CLASS (class);
	data_wrapper_class->write_to_stream_sync = mime_part_write_to_stream_sync;
	data_wrapper_class->construct_from_stream_sync = mime_part_construct_from_stream_sync;
	data_wrapper_class->write_to_output_stream_sync = mime_part_write_to_output_stream_sync;
	data_wrapper_class->construct_from_input_stream_sync = mime_part_construct_from_input_stream_sync;

	class->construct_from_parser_sync = mime_part_construct_from_parser_sync;

	g_object_class_install_property (
		object_class,
		PROP_CONTENT_ID,
		g_param_spec_string (
			"content-id",
			"Content ID",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_CONTENT_MD5,
		g_param_spec_string (
			"content-md5",
			"Content MD5",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_DESCRIPTION,
		g_param_spec_string (
			"description",
			"Description",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_DISPOSITION,
		g_param_spec_string (
			"disposition",
			"Disposition",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	init_header_name_table ();
}

static void
camel_mime_part_init (CamelMimePart *mime_part)
{
	CamelDataWrapper *data_wrapper;

	mime_part->priv = CAMEL_MIME_PART_GET_PRIVATE (mime_part);
	mime_part->priv->encoding = CAMEL_TRANSFER_ENCODING_DEFAULT;
	mime_part->priv->headers = camel_name_value_array_new ();

	data_wrapper = CAMEL_DATA_WRAPPER (mime_part);

	camel_data_wrapper_take_mime_type_field (data_wrapper, camel_content_type_new ("text", "plain"));
}

/**
 * camel_mime_part_new:
 *
 * Create a new MIME part.
 *
 * Returns: a new #CamelMimePart
 **/
CamelMimePart *
camel_mime_part_new (void)
{
	return g_object_new (CAMEL_TYPE_MIME_PART, NULL);
}

/**
 * camel_mime_part_set_content:
 * @mime_part: a #CamelMimePart
 * @data: (array length=length) (nullable): data to put into the part
 * @length: length of @data
 * @type: (nullable): Content-Type of the data
 *
 * Utility function used to set the content of a mime part object to
 * be the provided data. If @length is 0, this routine can be used as
 * a way to remove old content (in which case @data and @type are
 * ignored and may be %NULL).
 **/
void
camel_mime_part_set_content (CamelMimePart *mime_part,
                             const gchar *data,
                             gint length,
                             const gchar *type) /* why on earth is the type last? */
{
	CamelMedium *medium = CAMEL_MEDIUM (mime_part);

	if (length) {
		CamelDataWrapper *dw;
		CamelStream *stream;

		dw = camel_data_wrapper_new ();
		camel_data_wrapper_set_mime_type (dw, type);
		stream = camel_stream_mem_new_with_buffer (data, length);
		camel_data_wrapper_construct_from_stream_sync (
			dw, stream, NULL, NULL);
		g_object_unref (stream);
		camel_medium_set_content (medium, dw);
		g_object_unref (dw);
	} else
		camel_medium_set_content (medium, NULL);
}

/**
 * camel_mime_part_get_content_disposition:
 * @mime_part: a #CamelMimePart
 *
 * Get the disposition of the MIME part as a structure.
 * Returned pointer is owned by @mime_part.
 *
 * Returns: the disposition structure
 *
 * Since: 2.30
 **/
const CamelContentDisposition *
camel_mime_part_get_content_disposition (CamelMimePart *mime_part)
{
	g_return_val_if_fail (mime_part != NULL, NULL);

	return mime_part->priv->disposition;
}

/**
 * camel_mime_part_get_content_id:
 * @mime_part: a #CamelMimePart
 *
 * Get the content-id field of a MIME part.
 *
 * Returns: the content-id field of the MIME part
 **/
const gchar *
camel_mime_part_get_content_id (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	return mime_part->priv->content_id;
}

/**
 * camel_mime_part_set_content_id:
 * @mime_part: a #CamelMimePart
 * @contentid: content id
 *
 * Set the content-id field on a MIME part.
 **/
void
camel_mime_part_set_content_id (CamelMimePart *mime_part,
                                const gchar *contentid)
{
	CamelMedium *medium;
	gchar *cid, *id;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	if (contentid)
		id = g_strstrip (g_strdup (contentid));
	else
		id = camel_header_msgid_generate (NULL);

	cid = g_strdup_printf ("<%s>", id);
	camel_medium_set_header (medium, "Content-ID", cid);
	g_free (cid);

	g_free (id);

	g_object_notify (G_OBJECT (mime_part), "content-id");
}

/**
 * camel_mime_part_get_content_location:
 * @mime_part: a #CamelMimePart
 *
 * Get the content-location field of a MIME part.
 *
 * Returns: the content-location field of a MIME part
 **/
const gchar *
camel_mime_part_get_content_location (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	return mime_part->priv->content_location;
}

/**
 * camel_mime_part_set_content_location:
 * @mime_part: a #CamelMimePart
 * @location: the content-location value of the MIME part
 *
 * Set the content-location field of the MIME part.
 **/
void
camel_mime_part_set_content_location (CamelMimePart *mime_part,
                                      const gchar *location)
{
	CamelMedium *medium;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	/* FIXME: this should perform content-location folding */
	camel_medium_set_header (medium, "Content-Location", location);

	g_object_notify (G_OBJECT (mime_part), "content-location");
}

/**
 * camel_mime_part_get_content_md5:
 * @mime_part: a #CamelMimePart
 *
 * Get the content-md5 field of the MIME part.
 *
 * Returns: the content-md5 field of the MIME part
 **/
const gchar *
camel_mime_part_get_content_md5 (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	return mime_part->priv->content_md5;
}

/**
 * camel_mime_part_set_content_md5:
 * @mime_part: a #CamelMimePart
 * @md5sum: the md5sum of the MIME part
 *
 * Set the content-md5 field of the MIME part.
 **/
void
camel_mime_part_set_content_md5 (CamelMimePart *mime_part,
                                 const gchar *content_md5)
{
	CamelMedium *medium;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	camel_medium_set_header (medium, "Content-MD5", content_md5);
}

/**
 * camel_mime_part_get_content_languages:
 * @mime_part: a #CamelMimePart
 *
 * Get the Content-Languages set on the MIME part.
 *
 * Returns: (element-type utf8) (transfer none): a #GList of languages
 **/
const GList *
camel_mime_part_get_content_languages (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	return mime_part->priv->content_languages;
}

/**
 * camel_mime_part_set_content_languages:
 * @mime_part: a #CamelMimePart
 * @content_languages: (element-type utf8): list of languages
 *
 * Set the Content-Languages field of a MIME part.
 **/
void
camel_mime_part_set_content_languages (CamelMimePart *mime_part,
                                       GList *content_languages)
{
	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	g_list_free_full (
		mime_part->priv->content_languages,
		(GDestroyNotify) g_free);

	mime_part->priv->content_languages = content_languages;

	/* FIXME: translate to a header and set it */
}

/**
 * camel_mime_part_get_content_type:
 * @mime_part: a #CamelMimePart
 *
 * Get the Content-Type of a MIME part.
 *
 * Returns: (transfer none): the parsed #CamelContentType of the MIME part
 **/
CamelContentType *
camel_mime_part_get_content_type (CamelMimePart *mime_part)
{
	CamelDataWrapper *data_wrapper;

	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	data_wrapper = CAMEL_DATA_WRAPPER (mime_part);

	return camel_data_wrapper_get_mime_type_field (data_wrapper);
}

/**
 * camel_mime_part_set_content_type:
 * @mime_part: a #CamelMimePart
 * @content_type: content-type string
 *
 * Set the content-type on a MIME part.
 **/
void
camel_mime_part_set_content_type (CamelMimePart *mime_part,
                                  const gchar *content_type)
{
	CamelMedium *medium;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	camel_medium_set_header (medium, "Content-Type", content_type);
}

/**
 * camel_mime_part_get_description:
 * @mime_part: a #CamelMimePart
 *
 * Get the description of the MIME part.
 *
 * Returns: the description
 **/
const gchar *
camel_mime_part_get_description (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	return mime_part->priv->description;
}

/**
 * camel_mime_part_set_description:
 * @mime_part: a #CamelMimePart
 * @description: description of the MIME part
 *
 * Set a description on the MIME part.
 **/
void
camel_mime_part_set_description (CamelMimePart *mime_part,
                                 const gchar *description)
{
	CamelMedium *medium;
	gchar *text;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));
	g_return_if_fail (description != NULL);

	medium = CAMEL_MEDIUM (mime_part);

	text = camel_header_encode_string ((guchar *) description);
	camel_medium_set_header (medium, "Content-Description", text);
	g_free (text);

	g_object_notify (G_OBJECT (mime_part), "description");
}

/**
 * camel_mime_part_get_disposition:
 * @mime_part: a #CamelMimePart
 *
 * Get the disposition of the MIME part.
 *
 * Returns: the disposition
 **/
const gchar *
camel_mime_part_get_disposition (CamelMimePart *mime_part)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), NULL);

	if (mime_part->priv->disposition)
		return mime_part->priv->disposition->disposition;
	else
		return NULL;
}

/**
 * camel_mime_part_set_disposition:
 * @mime_part: a #CamelMimePart
 * @disposition: disposition of the MIME part
 *
 * Set a disposition on the MIME part.
 **/
void
camel_mime_part_set_disposition (CamelMimePart *mime_part,
                                 const gchar *disposition)
{
	CamelMedium *medium;
	gchar *text;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	/* we poke in a new disposition (so we dont lose 'filename', etc) */
	if (mime_part->priv->disposition == NULL)
		mime_part_set_disposition (mime_part, disposition);

	if (mime_part->priv->disposition != NULL) {
		g_free (mime_part->priv->disposition->disposition);
		mime_part->priv->disposition->disposition = g_strdup (disposition);
	}

	text = camel_content_disposition_format (mime_part->priv->disposition);
	camel_medium_set_header (medium, "Content-Disposition", text);
	g_free (text);

	g_object_notify (G_OBJECT (mime_part), "disposition");
}

/**
 * camel_mime_part_get_encoding:
 * @mime_part: a #CamelMimePart
 *
 * Get the Content-Transfer-Encoding of a MIME part.
 *
 * Returns: a #CamelTransferEncoding
 **/
CamelTransferEncoding
camel_mime_part_get_encoding (CamelMimePart *mime_part)
{
	g_return_val_if_fail (
		CAMEL_IS_MIME_PART (mime_part),
		CAMEL_TRANSFER_ENCODING_DEFAULT);

	return mime_part->priv->encoding;
}

/**
 * camel_mime_part_set_encoding:
 * @mime_part: a #CamelMimePart
 * @encoding: a #CamelTransferEncoding
 *
 * Set the Content-Transfer-Encoding to use on a MIME part.
 **/
void
camel_mime_part_set_encoding (CamelMimePart *mime_part,
                              CamelTransferEncoding encoding)
{
	CamelMedium *medium;
	const gchar *text;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));

	medium = CAMEL_MEDIUM (mime_part);

	text = camel_transfer_encoding_to_string (encoding);
	camel_medium_set_header (medium, "Content-Transfer-Encoding", text);
}

/**
 * camel_mime_part_get_filename:
 * @mime_part: a #CamelMimePart
 *
 * Get the filename of a MIME part.
 *
 * Returns: the filename of the MIME part
 **/
const gchar *
camel_mime_part_get_filename (CamelMimePart *mime_part)
{
	if (mime_part->priv->disposition) {
		const gchar *name = camel_header_param (
			mime_part->priv->disposition->params, "filename");
		if (name)
			return name;
	}

	return camel_content_type_param (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (mime_part)), "name");
}

/**
 * camel_mime_part_set_filename:
 * @mime_part: a #CamelMimePart
 * @filename: filename given to the MIME part
 *
 * Set the filename on a MIME part.
 **/
void
camel_mime_part_set_filename (CamelMimePart *mime_part,
                              const gchar *filename)
{
	CamelDataWrapper *dw;
	CamelMedium *medium;
	gchar *str;

	medium = CAMEL_MEDIUM (mime_part);

	if (mime_part->priv->disposition == NULL)
		mime_part->priv->disposition =
			camel_content_disposition_decode ("attachment");

	camel_header_set_param (
		&mime_part->priv->disposition->params, "filename", filename);
	str = camel_content_disposition_format (mime_part->priv->disposition);

	camel_medium_set_header (medium, "Content-Disposition", str);
	g_free (str);

	dw = (CamelDataWrapper *) mime_part;
	if (!camel_data_wrapper_get_mime_type_field (dw))
		camel_data_wrapper_take_mime_type_field (dw, camel_content_type_new ("application", "octet-stream"));
	camel_content_type_set_param (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (dw)), "name", filename);
	str = camel_content_type_format (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (dw)));
	camel_medium_set_header (medium, "Content-Type", str);
	g_free (str);
}

/**
 * camel_mime_part_construct_from_parser_sync:
 * @mime_part: a #CamelMimePart
 * @parser: a #CamelMimeParser
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Constructs a MIME part from a parser.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_mime_part_construct_from_parser_sync (CamelMimePart *mime_part,
                                            CamelMimeParser *parser,
                                            GCancellable *cancellable,
                                            GError **error)
{
	CamelMimePartClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_PARSER (parser), FALSE);

	class = CAMEL_MIME_PART_GET_CLASS (mime_part);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->construct_from_parser_sync != NULL, FALSE);

	success = class->construct_from_parser_sync (
		mime_part, parser, cancellable, error);
	CAMEL_CHECK_GERROR (
		mime_part, construct_from_parser_sync, success, error);

	return success;
}

/* Helper for camel_mime_part_construct_from_parser() */
static void
mime_part_construct_from_parser_thread (GTask *task,
                                        gpointer source_object,
                                        gpointer task_data,
                                        GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_mime_part_construct_from_parser_sync (
		CAMEL_MIME_PART (source_object),
		async_context->parser,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_mime_part_construct_from_parser:
 * @mime_part: a #CamelMimePart
 * @parser: a #CamelMimeParser
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously constructs a MIME part from a parser.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_mime_part_construct_from_parser_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_mime_part_construct_from_parser (CamelMimePart *mime_part,
                                       CamelMimeParser *parser,
                                       gint io_priority,
                                       GCancellable *cancellable,
                                       GAsyncReadyCallback callback,
                                       gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_MIME_PART (mime_part));
	g_return_if_fail (CAMEL_IS_MIME_PARSER (parser));

	async_context = g_slice_new0 (AsyncContext);
	async_context->parser = g_object_ref (parser);

	task = g_task_new (mime_part, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_mime_part_construct_from_parser);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, mime_part_construct_from_parser_thread);

	g_object_unref (task);
}

/**
 * camel_mime_part_construct_from_parser_finish:
 * @mime_part: a #CamelMimePart
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_mime_part_construct_from_parser().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_mime_part_construct_from_parser_finish (CamelMimePart *mime_part,
                                              GAsyncResult *result,
                                              GError **error)
{
	g_return_val_if_fail (CAMEL_IS_MIME_PART (mime_part), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, mime_part), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_mime_part_construct_from_parser), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}
