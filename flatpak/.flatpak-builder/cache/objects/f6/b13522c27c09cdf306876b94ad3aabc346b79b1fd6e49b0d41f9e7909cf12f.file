/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-multipart.c : Abstract class for a multipart
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <glib/gi18n-lib.h>

#include "camel-mime-filter-canon.h"
#include "camel-mime-filter-crlf.h"
#include "camel-mime-message.h"
#include "camel-mime-parser.h"
#include "camel-mime-part.h"
#include "camel-multipart-signed.h"
#include "camel-object.h"
#include "camel-stream-filter.h"
#include "camel-stream-mem.h"

#define CAMEL_MULTIPART_SIGNED_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MULTIPART_SIGNED, CamelMultipartSignedPrivate))

struct _CamelMultipartSignedPrivate {
	/* These are the client visible parts,
	 * decoded forms of our data wrapper content. */
	CamelMimePart *content;
	CamelMimePart *signature;

	/* The raw content which must go over the wire, if we have
	 * generated it.
	 *
	 * XXX Perhaps this should just set data_wrapper->stream and
	 *     update start1/end1 accordingly, as it is done for other
	 *     parts, or visa versa? */
	CamelStream *contentraw;

	/* Offset pointers of start of boundary in content object. */
	goffset start1, end1;
	goffset start2, end2;
};

G_DEFINE_TYPE (
	CamelMultipartSigned,
	camel_multipart_signed,
	CAMEL_TYPE_MULTIPART)

static CamelStream *
multipart_signed_clip_stream (CamelMultipartSigned *mps,
                              goffset start,
                              goffset end)
{
	CamelDataWrapper *data_wrapper;
	GByteArray *src;
	GByteArray *dst;

	g_return_val_if_fail (start != -1, NULL);
	g_return_val_if_fail (end != -1, NULL);
	g_return_val_if_fail (end >= start, NULL);

	data_wrapper = CAMEL_DATA_WRAPPER (mps);

	src = camel_data_wrapper_get_byte_array (data_wrapper);
	dst = g_byte_array_new ();

	if (start >= 0 && end < src->len) {
		const guint8 *data = &src->data[start];
		g_byte_array_append (dst, data, end - start);
	}

	/* Stream takes ownership of the byte array. */
	return camel_stream_mem_new_with_byte_array (dst);
}

static gint
multipart_signed_skip_content (CamelMimeParser *cmp)
{
	gchar *buf;
	gsize len;
	gint state;

	switch (camel_mime_parser_state (cmp)) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
		/* body part */
		while (camel_mime_parser_step (cmp, &buf, &len) != CAMEL_MIME_PARSER_STATE_BODY_END)
			/* NOOP */ ;
		break;
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
		/* message body part */
		state = camel_mime_parser_step (cmp, &buf, &len);
		if (state != CAMEL_MIME_PARSER_STATE_EOF &&
		    state != CAMEL_MIME_PARSER_STATE_FROM_END) {
			multipart_signed_skip_content (cmp);
		} else {
			camel_mime_parser_unstep (cmp);
			break;
		}

		/* clean up followon state if any, see camel-mime-message.c */
		state = camel_mime_parser_step (cmp, &buf, &len);
		switch (state) {
		case CAMEL_MIME_PARSER_STATE_EOF:
		case CAMEL_MIME_PARSER_STATE_FROM_END: /* these doesn't belong to us */
			camel_mime_parser_unstep (cmp);
		case CAMEL_MIME_PARSER_STATE_MESSAGE_END:
			break;
		default:
			g_error ("Bad parser state: Expecting MESSAGE_END or EOF or EOM, got: %u", camel_mime_parser_state (cmp));
			camel_mime_parser_unstep (cmp);
			return -1;
		}
		break;
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		/* embedded multipart */
		while (camel_mime_parser_step (cmp, &buf, &len) != CAMEL_MIME_PARSER_STATE_MULTIPART_END)
			multipart_signed_skip_content (cmp);
		break;
	default:
		g_warning ("Invalid state encountered???: %u", camel_mime_parser_state (cmp));
	}

	return 0;
}

static gint
multipart_signed_parse_content (CamelMultipartSigned *mps)
{
	CamelMimeParser *cmp;
	CamelMultipart *mp = (CamelMultipart *) mps;
	CamelDataWrapper *data_wrapper;
	GByteArray *byte_array;
	CamelStream *stream;
	const gchar *boundary;
	gchar *buf;
	gsize len;
	gint state;

	boundary = camel_multipart_get_boundary (mp);
	g_return_val_if_fail (boundary != NULL, -1);

	data_wrapper = CAMEL_DATA_WRAPPER (mps);
	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	stream = camel_stream_mem_new ();

	/* Do not give the stream ownership of the byte array. */
	camel_stream_mem_set_byte_array (
		CAMEL_STREAM_MEM (stream), byte_array);

	/* This is all seriously complex.
	 * This is so we can parse all cases properly, without altering the content.
	 * All we are doing is finding part offsets. */

	cmp = camel_mime_parser_new ();
	camel_mime_parser_init_with_stream (cmp, stream, NULL);
	camel_mime_parser_push_state (cmp, CAMEL_MIME_PARSER_STATE_MULTIPART, boundary);

	mps->priv->start1 = -1;
	mps->priv->end1 = -1;
	mps->priv->start2 = -1;
	mps->priv->end2 = -1;

	while ((state = camel_mime_parser_step (cmp, &buf, &len)) != CAMEL_MIME_PARSER_STATE_MULTIPART_END) {
		if (mps->priv->start1 == -1) {
			mps->priv->start1 = camel_mime_parser_tell_start_headers (cmp);
		} else if (mps->priv->start2 == -1) {
			mps->priv->start2 = camel_mime_parser_tell_start_headers (cmp);
			mps->priv->end1 = camel_mime_parser_tell_start_boundary (cmp);
			if (mps->priv->end1 > mps->priv->start1 && byte_array->data[mps->priv->end1 - 1] == '\n')
				mps->priv->end1--;
			if (mps->priv->end1 > mps->priv->start1 && byte_array->data[mps->priv->end1 - 1] == '\r')
				mps->priv->end1--;
		} else {
			g_warning ("multipart/signed has more than 2 parts, remaining parts ignored");
			state = CAMEL_MIME_PARSER_STATE_MULTIPART_END;
			break;
		}

		if (multipart_signed_skip_content (cmp) == -1)
			break;
	}

	if (state == CAMEL_MIME_PARSER_STATE_MULTIPART_END) {
		mps->priv->end2 = camel_mime_parser_tell_start_boundary (cmp);

		camel_multipart_set_preface (mp, camel_mime_parser_preface (cmp));
		camel_multipart_set_postface (mp, camel_mime_parser_postface (cmp));
	}

	g_object_unref (cmp);
	g_object_unref (stream);

	if (mps->priv->end2 == -1 || mps->priv->start2 == -1) {
		if (mps->priv->end1 == -1)
			mps->priv->start1 = -1;

		return -1;
	}

	return 0;
}

static void
multipart_signed_dispose (GObject *object)
{
	CamelMultipartSignedPrivate *priv;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (object);

	g_clear_object (&priv->content);
	g_clear_object (&priv->signature);
	g_clear_object (&priv->contentraw);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_multipart_signed_parent_class)->dispose (object);
}

static gssize
multipart_signed_write_to_stream_sync (CamelDataWrapper *data_wrapper,
                                       CamelStream *stream,
                                       GCancellable *cancellable,
                                       GError **error)
{
	CamelMultipartSignedPrivate *priv;
	CamelMultipart *mp = (CamelMultipart *) data_wrapper;
	GByteArray *byte_array;
	const gchar *boundary;
	const gchar *preface;
	const gchar *postface;
	gssize total = 0;
	gssize count;
	gchar *content;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (data_wrapper);

	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	/* we have 3 basic cases:
	 * 1. constructed, we write out the data wrapper stream we got
	 * 2. signed content, we create and write out a new stream
	 * 3. invalid
	 */

	/* 1 */
	/* FIXME: locking? */
	if (byte_array->len > 0) {
		return camel_stream_write (
			stream, (gchar *) byte_array->data,
			byte_array->len, cancellable, error);
	}

	/* 3 */
	if (priv->contentraw == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("No content available"));
		return -1;
	}

	/* 3 */
	if (priv->signature == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("No signature available"));
		return -1;
	}

	boundary = camel_multipart_get_boundary (mp);
	preface = camel_multipart_get_preface (mp);
	postface = camel_multipart_get_postface (mp);

	/* 2 */
	if (preface != NULL) {
		count = camel_stream_write_string (
			stream, preface, cancellable, error);
		if (count == -1)
			return -1;
		total += count;
	}

	/* first boundary */
	content = g_strdup_printf ("\n--%s\n", boundary);
	count = camel_stream_write_string (
		stream, content, cancellable, error);
	g_free (content);
	if (count == -1)
		return -1;
	total += count;

	/* output content part */
	/* XXX Both CamelGpgContext and CamelSMIMEContext set this
	 *     to a memory stream, so assume it's always seekable. */
	g_seekable_seek (
		G_SEEKABLE (priv->contentraw), 0, G_SEEK_SET, NULL, NULL);
	count = camel_stream_write_to_stream (
		priv->contentraw, stream, cancellable, error);
	if (count == -1)
		return -1;
	total += count;

	/* boundary */
	content = g_strdup_printf ("\n--%s\n", boundary);
	count = camel_stream_write_string (
		stream, content, cancellable, error);
	g_free (content);
	if (count == -1)
		return -1;
	total += count;

	/* signature */
	count = camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (priv->signature),
		stream, cancellable, error);
	if (count == -1)
		return -1;
	total += count;

	/* write the terminating boudary delimiter */
	content = g_strdup_printf ("\n--%s--\n", boundary);
	count = camel_stream_write_string (
		stream, content, cancellable, error);
	g_free (content);
	if (count == -1)
		return -1;
	total += count;

	/* and finally the postface */
	if (postface != NULL) {
		count = camel_stream_write_string (
			stream, postface, cancellable, error);
		if (count == -1)
			return -1;
		total += count;
	}

	return total;
}

static gboolean
multipart_signed_construct_from_stream_sync (CamelDataWrapper *data_wrapper,
                                             CamelStream *stream,
                                             GCancellable *cancellable,
                                             GError **error)
{
	CamelMultipartSignedPrivate *priv;
	CamelDataWrapperClass *parent_class;
	gboolean success;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (data_wrapper);

	/* Chain up to parent's construct_from_stream_sync() method. */
	parent_class = CAMEL_DATA_WRAPPER_CLASS (
		camel_multipart_signed_parent_class);
	success = parent_class->construct_from_stream_sync (
		data_wrapper, stream, cancellable, error);

	if (success) {
		priv->start1 = -1;
		g_clear_object (&priv->content);
		g_clear_object (&priv->signature);
		g_clear_object (&priv->contentraw);
	}

	return success;
}

static gssize
multipart_signed_write_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                              GOutputStream *output_stream,
                                              GCancellable *cancellable,
                                              GError **error)
{
	CamelMultipartSignedPrivate *priv;
	CamelMultipart *mp = (CamelMultipart *) data_wrapper;
	GByteArray *byte_array;
	const gchar *boundary;
	const gchar *preface;
	const gchar *postface;
	gsize bytes_written;
	gssize total = 0;
	gssize result;
	gchar *content;
	gboolean success;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (data_wrapper);

	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	/* we have 3 basic cases:
	 * 1. constructed, we write out the data wrapper stream we got
	 * 2. signed content, we create and write out a new stream
	 * 3. invalid
	 */

	/* 1 */
	/* FIXME: locking? */
	if (byte_array->len > 0) {
		success = g_output_stream_write_all (
			output_stream,
			byte_array->data, byte_array->len,
			&bytes_written, cancellable, error);
		return success ? (gssize) bytes_written : -1;
	}

	/* 3 */
	if (priv->contentraw == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("No content available"));
		return -1;
	}

	/* 3 */
	if (priv->signature == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("No signature available"));
		return -1;
	}

	boundary = camel_multipart_get_boundary (mp);
	preface = camel_multipart_get_preface (mp);
	postface = camel_multipart_get_postface (mp);

	/* 2 */
	if (preface != NULL) {
		success = g_output_stream_write_all (
			output_stream,
			preface, strlen (preface),
			&bytes_written, cancellable, error);
		if (!success)
			return -1;
		total += (gssize) bytes_written;
	}

	/* first boundary */
	content = g_strdup_printf ("\n--%s\n", boundary);
	success = g_output_stream_write_all (
		output_stream,
		content, strlen (content),
		&bytes_written, cancellable, error);
	g_free (content);
	if (!success)
		return -1;
	total += (gssize) bytes_written;

	/* output content part */
	/* XXX Both CamelGpgContext and CamelSMIMEContext set this
	 *     to a memory stream, so we'll assume it to be so and
	 *     grab its GByteArray.  Would be better to store the
	 *     raw message content as a reference-counted GBytes
	 *     rather than a stream. */
	g_return_val_if_fail (CAMEL_IS_STREAM_MEM (priv->contentraw), -1);
	byte_array = camel_stream_mem_get_byte_array (
		CAMEL_STREAM_MEM (priv->contentraw));
	success = g_output_stream_write_all (
		output_stream,
		byte_array->data, byte_array->len,
		&bytes_written, cancellable, error);
	if (!success)
		return -1;
	total += (gssize) bytes_written;

	/* boundary */
	content = g_strdup_printf ("\n--%s\n", boundary);
	success = g_output_stream_write_all (
		output_stream,
		content, strlen (content),
		&bytes_written, cancellable, error);
	g_free (content);
	if (!success)
		return -1;
	total += (gssize) bytes_written;

	/* signature */
	result = camel_data_wrapper_write_to_output_stream_sync (
		CAMEL_DATA_WRAPPER (priv->signature),
		output_stream, cancellable, error);
	if (result == -1)
		return -1;
	total += result;

	/* write the terminating boudary delimiter */
	content = g_strdup_printf ("\n--%s--\n", boundary);
	success = g_output_stream_write_all (
		output_stream,
		content, strlen (content),
		&bytes_written, cancellable, error);
	g_free (content);
	if (!success)
		return -1;
	total += (gssize) bytes_written;

	/* and finally the postface */
	if (postface != NULL) {
		success = g_output_stream_write_all (
			output_stream,
			postface, strlen (postface),
			&bytes_written, cancellable, error);
		if (!success)
			return -1;
		total += (gssize) bytes_written;
	}

	return total;
}

static gboolean
multipart_signed_construct_from_input_stream_sync (CamelDataWrapper *data_wrapper,
                                                   GInputStream *input_stream,
                                                   GCancellable *cancellable,
                                                   GError **error)
{	CamelMultipartSignedPrivate *priv;
	gboolean success;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (data_wrapper);

	/* Chain up to parent's construct_from_input_stream_sync() method. */
	success = CAMEL_DATA_WRAPPER_CLASS (
		camel_multipart_signed_parent_class)->
		construct_from_input_stream_sync (
		data_wrapper, input_stream, cancellable, error);

	if (success) {
		priv->start1 = -1;
		g_clear_object (&priv->content);
		g_clear_object (&priv->signature);
		g_clear_object (&priv->contentraw);
	}

	return success;
}

static void
multipart_signed_add_part (CamelMultipart *multipart,
                           CamelMimePart *part)
{
	g_warning ("Cannot add parts to a signed part using add_part");
}

static CamelMimePart *
multipart_signed_get_part (CamelMultipart *multipart,
                           guint index)
{
	CamelMultipartSigned *mps;
	CamelDataWrapper *data_wrapper;
	CamelStream *stream;
	GByteArray *byte_array;

	mps = CAMEL_MULTIPART_SIGNED (multipart);

	data_wrapper = CAMEL_DATA_WRAPPER (multipart);
	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	switch (index) {
	case CAMEL_MULTIPART_SIGNED_CONTENT:
		if (mps->priv->content != NULL)
			return mps->priv->content;
		if (mps->priv->contentraw != NULL) {
			g_return_val_if_fail (
				G_IS_SEEKABLE (mps->priv->contentraw), NULL);
			stream = g_object_ref (mps->priv->contentraw);
		} else if (mps->priv->start1 == -1
			   && multipart_signed_parse_content (mps) == -1
			   && byte_array->len == 0) {
			g_warning ("Trying to get content on an invalid multipart/signed");
			return NULL;
		} else if (byte_array->len == 0) {
			return NULL;
		} else if (mps->priv->start1 == -1) {
			stream = camel_stream_mem_new ();
			camel_stream_mem_set_byte_array (
				CAMEL_STREAM_MEM (stream), byte_array);
		} else {
			stream = multipart_signed_clip_stream (
				mps, mps->priv->start1, mps->priv->end1);
		}
		g_seekable_seek (
			G_SEEKABLE (stream), 0, G_SEEK_SET, NULL, NULL);
		mps->priv->content = camel_mime_part_new ();
		camel_data_wrapper_construct_from_stream_sync (
			CAMEL_DATA_WRAPPER (mps->priv->content),
			stream, NULL, NULL);
		g_object_unref (stream);
		return mps->priv->content;
	case CAMEL_MULTIPART_SIGNED_SIGNATURE:
		if (mps->priv->signature != NULL)
			return mps->priv->signature;
		if (mps->priv->start1 == -1
		    && multipart_signed_parse_content (mps) == -1) {
			g_warning ("Trying to get signature on invalid multipart/signed");
			return NULL;
		} else if (byte_array->len == 0) {
			return NULL;
		}
		stream = multipart_signed_clip_stream (
			mps, mps->priv->start2, mps->priv->end2);
		g_seekable_seek (
			G_SEEKABLE (stream), 0, G_SEEK_SET, NULL, NULL);
		mps->priv->signature = camel_mime_part_new ();
		camel_data_wrapper_construct_from_stream_sync (
			CAMEL_DATA_WRAPPER (mps->priv->signature),
			stream, NULL, NULL);
		g_object_unref (stream);
		return mps->priv->signature;
	default:
		g_warning ("trying to get object out of bounds for multipart");
	}

	return NULL;
}

static guint
multipart_signed_get_number (CamelMultipart *multipart)
{
	CamelMultipartSigned *mps = (CamelMultipartSigned *) multipart;
	CamelDataWrapper *data_wrapper;
	GByteArray *byte_array;

	data_wrapper = CAMEL_DATA_WRAPPER (multipart);
	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	/* check what we have, so we return something reasonable */

	if ((mps->priv->content || mps->priv->contentraw) && mps->priv->signature)
		return 2;

	if (mps->priv->start1 == -1 && multipart_signed_parse_content (mps) == -1) {
		if (byte_array->len == 0)
			return 0;
		else
			return 1;
	} else {
		return 2;
	}
}

static gint
multipart_signed_construct_from_parser (CamelMultipart *multipart,
                                        CamelMimeParser *mp)
{
	CamelMultipartSignedPrivate *priv;
	gint err;
	CamelContentType *content_type;
	CamelDataWrapper *data_wrapper;
	GByteArray *byte_array;
	gchar *buf;
	gsize len;

	priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (multipart);

	/* we *must not* be in multipart state, otherwise the mime parser will
	 * parse the headers which is a no no @#$@# stupid multipart/signed spec */
	g_return_val_if_fail (camel_mime_parser_state (mp) == CAMEL_MIME_PARSER_STATE_HEADER, -1);

	/* All we do is copy it to a memstream */
	content_type = camel_mime_parser_content_type (mp);
	camel_multipart_set_boundary (multipart, camel_content_type_param (content_type, "boundary"));

	data_wrapper = CAMEL_DATA_WRAPPER (multipart);
	byte_array = camel_data_wrapper_get_byte_array (data_wrapper);

	/* Wipe any previous contents from the byte array. */
	g_byte_array_set_size (byte_array, 0);

	while (camel_mime_parser_step (mp, &buf, &len) != CAMEL_MIME_PARSER_STATE_BODY_END)
		g_byte_array_append (byte_array, (guint8 *) buf, len);

	priv->start1 = -1;
	g_clear_object (&priv->content);
	g_clear_object (&priv->signature);
	g_clear_object (&priv->contentraw);

	err = camel_mime_parser_errno (mp);
	if (err != 0) {
		errno = err;
		return -1;
	} else
		return 0;
}

static void
camel_multipart_signed_class_init (CamelMultipartSignedClass *class)
{
	GObjectClass *object_class;
	CamelDataWrapperClass *data_wrapper_class;
	CamelMultipartClass *multipart_class;

	g_type_class_add_private (class, sizeof (CamelMultipartSignedPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = multipart_signed_dispose;

	data_wrapper_class = CAMEL_DATA_WRAPPER_CLASS (class);
	data_wrapper_class->write_to_stream_sync = multipart_signed_write_to_stream_sync;
	data_wrapper_class->decode_to_stream_sync = multipart_signed_write_to_stream_sync;
	data_wrapper_class->construct_from_stream_sync = multipart_signed_construct_from_stream_sync;
	data_wrapper_class->write_to_output_stream_sync = multipart_signed_write_to_output_stream_sync;
	data_wrapper_class->decode_to_output_stream_sync = multipart_signed_write_to_output_stream_sync;
	data_wrapper_class->construct_from_input_stream_sync = multipart_signed_construct_from_input_stream_sync;

	multipart_class = CAMEL_MULTIPART_CLASS (class);
	multipart_class->add_part = multipart_signed_add_part;
	multipart_class->get_part = multipart_signed_get_part;
	multipart_class->get_number = multipart_signed_get_number;
	multipart_class->construct_from_parser = multipart_signed_construct_from_parser;
}

static void
camel_multipart_signed_init (CamelMultipartSigned *multipart)
{
	multipart->priv = CAMEL_MULTIPART_SIGNED_GET_PRIVATE (multipart);

	camel_data_wrapper_set_mime_type (
		CAMEL_DATA_WRAPPER (multipart), "multipart/signed");

	multipart->priv->start1 = -1;
}

/**
 * camel_multipart_signed_new:
 *
 * Create a new #CamelMultipartSigned object.
 *
 * A MultipartSigned should be used to store and create parts of
 * type "multipart/signed".  This is because multipart/signed is
 * entirely broken-by-design (tm) and uses completely
 * different semantics to other mutlipart types.  It must be treated
 * as opaque data by any transport.  See rfc 3156 for details.
 *
 * There are 3 ways to create the part:
 * Use construct_from_stream.  If this is used, then you must
 * set the mime_type appropriately to match the data uses, so
 * that the multiple parts my be extracted.
 *
 * Use construct_from_parser.  The parser MUST be in the #CAMEL_MIME_PARSER_STATE_HEADER
 * state, and the current content_type MUST be "multipart/signed" with
 * the appropriate boundary and it SHOULD include the appropriate protocol
 * and hash specifiers.
 *
 * Use sign_part.  A signature part will automatically be created
 * and the whole part may be written using write_to_stream to
 * create a 'transport-safe' version (as safe as can be expected with
 * such a broken specification).
 *
 * Returns: a new #CamelMultipartSigned object
 **/
CamelMultipartSigned *
camel_multipart_signed_new (void)
{
	return g_object_new (CAMEL_TYPE_MULTIPART_SIGNED, NULL);
}

/**
 * camel_multipart_signed_get_content_stream:
 * @mps: a #CamelMultipartSigned object
 * @error: return location for a #GError, or %NULL
 *
 * Get the raw signed content stream of the multipart/signed MIME part
 * suitable for use with verification of the signature.
 *
 * Returns: (transfer full): the signed content stream
 **/
CamelStream *
camel_multipart_signed_get_content_stream (CamelMultipartSigned *mps,
                                           GError **error)
{
	CamelStream *constream;

	/* we need to be able to verify stuff we just signed as well as stuff we loaded from a stream/parser */

	if (mps->priv->contentraw) {
		constream = g_object_ref (mps->priv->contentraw);
	} else {
		CamelStream *base_stream;
		CamelStream *filter_stream;
		CamelMimeFilter *canon_filter;

		if (mps->priv->start1 == -1 && multipart_signed_parse_content (mps) == -1) {
			g_set_error (
				error, CAMEL_ERROR,
				CAMEL_ERROR_GENERIC,
				_("parse error"));
			return NULL;
		}

		/* first, prepare our parts */

		base_stream = multipart_signed_clip_stream (
			mps, mps->priv->start1, mps->priv->end1);

		filter_stream = camel_stream_filter_new (base_stream);

		/* Note: see rfc2015 or rfc3156, section 5 */
		canon_filter = camel_mime_filter_canon_new (
			CAMEL_MIME_FILTER_CANON_CRLF);
		camel_stream_filter_add (
			CAMEL_STREAM_FILTER (filter_stream), canon_filter);
		g_object_unref (canon_filter);

		/* We want to return a pure memory stream,
		 * so apply the CRLF filter ahead of time. */
		constream = camel_stream_mem_new ();
		camel_stream_write_to_stream (
			filter_stream, constream, NULL, NULL);

		g_object_unref (filter_stream);
		g_object_unref (base_stream);

		/* rewind to the beginning of a stream */
		g_seekable_seek (G_SEEKABLE (constream), 0, G_SEEK_SET, NULL, NULL);
	}

	return constream;
}

/**
 * camel_multipart_signed_set_content_stream:
 * @mps: a #CamelMultipartSigned
 * @content_stream: a #CamelStream
 *
 * Explicits sets the raw signed content stream of the multipart/signed
 * MIME part.
 *
 * Since: 3.12
 **/
void
camel_multipart_signed_set_content_stream (CamelMultipartSigned *mps,
                                           CamelStream *content_stream)
{
	g_return_if_fail (CAMEL_IS_MULTIPART_SIGNED (mps));
	g_return_if_fail (CAMEL_IS_STREAM (content_stream));

	g_clear_object (&mps->priv->contentraw);
	mps->priv->contentraw = g_object_ref (content_stream);
}

/**
 * camel_multipart_signed_set_signature:
 * @mps: a #CamelMultipartSigned
 * @signature: a #CamelMimePart
 *
 * Explicitly sets the signature part of @mps.
 *
 * Since: 3.12
 **/
void
camel_multipart_signed_set_signature (CamelMultipartSigned *mps,
                                      CamelMimePart *signature)
{
	g_return_if_fail (CAMEL_IS_MULTIPART_SIGNED (mps));
	g_return_if_fail (CAMEL_IS_MIME_PART (signature));

	g_clear_object (&mps->priv->signature);
	mps->priv->signature = g_object_ref (signature);
}
