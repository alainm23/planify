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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <string.h> /* strlen() */
#include <time.h>   /* for time */
#include <unistd.h> /* for getpid */

#include "camel-mime-part.h"
#include "camel-multipart.h"
#include "camel-stream-mem.h"

#define CAMEL_MULTIPART_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MULTIPART, CamelMultipartPrivate))

struct _CamelMultipartPrivate {
	GPtrArray *parts;
	gchar *preface;
	gchar *postface;
};

G_DEFINE_TYPE (CamelMultipart, camel_multipart, CAMEL_TYPE_DATA_WRAPPER)

static void
multipart_dispose (GObject *object)
{
	CamelMultipartPrivate *priv;

	priv = CAMEL_MULTIPART_GET_PRIVATE (object);

	g_ptr_array_set_size (priv->parts, 0);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_multipart_parent_class)->dispose (object);
}

static void
multipart_finalize (GObject *object)
{
	CamelMultipartPrivate *priv;

	priv = CAMEL_MULTIPART_GET_PRIVATE (object);

	g_ptr_array_unref (priv->parts);

	g_free (priv->preface);
	g_free (priv->postface);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_multipart_parent_class)->finalize (object);
}

static gboolean
multipart_is_offline (CamelDataWrapper *data_wrapper)
{
	CamelMultipartPrivate *priv;
	CamelDataWrapper *part;
	guint ii;

	priv = CAMEL_MULTIPART_GET_PRIVATE (data_wrapper);

	/* Chain up to parent's is_offline() method. */
	if (CAMEL_DATA_WRAPPER_CLASS (camel_multipart_parent_class)->is_offline (data_wrapper))
		return TRUE;

	for (ii = 0; ii < priv->parts->len; ii++) {
		part = g_ptr_array_index (priv->parts, ii);
		if (camel_data_wrapper_is_offline (part))
			return TRUE;
	}

	return FALSE;
}

/* this is MIME specific, doesn't belong here really */
static gssize
multipart_write_to_stream_sync (CamelDataWrapper *data_wrapper,
                                CamelStream *stream,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelMultipartPrivate *priv;
	const gchar *boundary;
	gchar *content;
	gssize total = 0;
	gssize count;
	guint ii;

	priv = CAMEL_MULTIPART_GET_PRIVATE (data_wrapper);

	/* get the bundary text */
	boundary = camel_multipart_get_boundary (
		CAMEL_MULTIPART (data_wrapper));

	/* we cannot write a multipart without a boundary string */
	g_return_val_if_fail (boundary, -1);

	/*
	 * write the preface text (usually something like
	 *   "This is a mime message, if you see this, then
	 *    your mail client probably doesn't support ...."
	 */
	if (priv->preface != NULL) {
		count = camel_stream_write_string (
			stream, priv->preface, cancellable, error);
		if (count == -1)
			return -1;
		total += count;
	}

	/*
	 * Now, write all the parts, separated by the boundary
	 * delimiter
	 */
	for (ii = 0; ii < priv->parts->len; ii++) {
		CamelDataWrapper *part;

		part = g_ptr_array_index (priv->parts, ii);

		content = g_strdup_printf ("\n--%s\n", boundary);
		count = camel_stream_write_string (
			stream, content, cancellable, error);
		g_free (content);
		if (count == -1)
			return -1;
		total += count;

		count = camel_data_wrapper_write_to_stream_sync (
			part, stream, cancellable, error);
		if (count == -1)
			return -1;
		total += count;
	}

	/* write the terminating boudary delimiter */
	content = g_strdup_printf ("\n--%s--\n", boundary);
	count = camel_stream_write_string (
		stream, content, cancellable, error);
	g_free (content);
	if (count == -1)
		return -1;
	total += count;

	/* and finally the postface */
	if (priv->postface != NULL) {
		count = camel_stream_write_string (
			stream, priv->postface, cancellable, error);
		if (count == -1)
			return -1;
		total += count;
	}

	return total;
}

/* this is MIME specific, doesn't belong here really */
static gssize
multipart_write_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                       GOutputStream *output_stream,
                                       GCancellable *cancellable,
                                       GError **error)
{
	CamelMultipartPrivate *priv;
	const gchar *boundary;
	gchar *content;
	gsize bytes_written;
	gssize total = 0;
	gboolean success;
	guint ii;

	priv = CAMEL_MULTIPART_GET_PRIVATE (data_wrapper);

	/* get the bundary text */
	boundary = camel_multipart_get_boundary (
		CAMEL_MULTIPART (data_wrapper));

	/* we cannot write a multipart without a boundary string */
	g_return_val_if_fail (boundary, -1);

	/*
	 * write the preface text (usually something like
	 *   "This is a mime message, if you see this, then
	 *    your mail client probably doesn't support ...."
	 */
	if (priv->preface != NULL) {
		success = g_output_stream_write_all (
			output_stream,
			priv->preface, strlen (priv->preface),
			&bytes_written, cancellable, error);
		if (!success)
			return -1;
		total += (gsize) bytes_written;
	}

	/*
	 * Now, write all the parts, separated by the boundary
	 * delimiter
	 */
	for (ii = 0; ii < priv->parts->len; ii++) {
		CamelDataWrapper *part;
		gssize result;

		part = g_ptr_array_index (priv->parts, ii);

		content = g_strdup_printf ("\n--%s\n", boundary);
		success = g_output_stream_write_all (
			output_stream,
			content, strlen (content),
			&bytes_written, cancellable, error);
		g_free (content);
		if (!success)
			return -1;
		total += (gsize) bytes_written;

		result = camel_data_wrapper_write_to_output_stream_sync (
			part, output_stream, cancellable, error);
		if (result == -1)
			return -1;
		total += result;
	}

	/* write the terminating boudary delimiter */
	content = g_strdup_printf ("\n--%s--\n", boundary);
	success = g_output_stream_write_all (
		output_stream,
		content, strlen (content),
		&bytes_written, cancellable, error);
	g_free (content);
	if (!success)
		return -1;
	total += (gsize) bytes_written;

	/* and finally the postface */
	if (priv->postface != NULL) {
		success = g_output_stream_write_all (
			output_stream,
			priv->postface, strlen (priv->postface),
			&bytes_written, cancellable, error);
		if (!success)
			return -1;
		total += (gsize) bytes_written;
	}

	return total;
}

static void
multipart_add_part (CamelMultipart *multipart,
                    CamelMimePart *part)
{
	g_ptr_array_add (multipart->priv->parts, g_object_ref (part));
}

static CamelMimePart *
multipart_get_part (CamelMultipart *multipart,
                    guint index)
{
	if (index >= multipart->priv->parts->len)
		return NULL;

	return g_ptr_array_index (multipart->priv->parts, index);
}

static guint
multipart_get_number (CamelMultipart *multipart)
{
	return multipart->priv->parts->len;
}

static void
multipart_set_boundary (CamelMultipart *multipart,
                        const gchar *boundary)
{
	CamelDataWrapper *cdw = CAMEL_DATA_WRAPPER (multipart);
	gchar *bgen, bbuf[27], *p;
	guint8 *digest;
	gsize length;
	gint state, save;

	g_return_if_fail (camel_data_wrapper_get_mime_type_field (cdw) != NULL);

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	if (!boundary) {
		GChecksum *checksum;

		/* Generate a fairly random boundary string. */
		bgen = g_strdup_printf (
			"%p:%lu:%lu",
			(gpointer) multipart,
			(gulong) getpid (),
			(gulong) time (NULL));

		checksum = g_checksum_new (G_CHECKSUM_MD5);
		g_checksum_update (checksum, (guchar *) bgen, -1);
		g_checksum_get_digest (checksum, digest, &length);
		g_checksum_free (checksum);

		g_free (bgen);
		g_strlcpy (bbuf, "=-", sizeof (bbuf));
		p = bbuf + 2;
		state = save = 0;
		p += g_base64_encode_step (
			(guchar *) digest, length, FALSE, p, &state, &save);
		*p = '\0';

		boundary = bbuf;
	}

	camel_content_type_set_param (camel_data_wrapper_get_mime_type_field (cdw), "boundary", boundary);
}

static const gchar *
multipart_get_boundary (CamelMultipart *multipart)
{
	CamelDataWrapper *cdw = CAMEL_DATA_WRAPPER (multipart);

	g_return_val_if_fail (camel_data_wrapper_get_mime_type_field (cdw) != NULL, NULL);
	return camel_content_type_param (camel_data_wrapper_get_mime_type_field (cdw), "boundary");
}

static gint
multipart_construct_from_parser (CamelMultipart *multipart,
                                 CamelMimeParser *mp)
{
	gint err;
	CamelContentType *content_type;
	CamelMimePart *bodypart;
	gchar *buf;
	gsize len;

	g_return_val_if_fail (camel_mime_parser_state (mp) == CAMEL_MIME_PARSER_STATE_MULTIPART, -1);

	content_type = camel_mime_parser_content_type (mp);
	camel_multipart_set_boundary (
		multipart,
		camel_content_type_param (content_type, "boundary"));

	while (camel_mime_parser_step (mp, &buf, &len) != CAMEL_MIME_PARSER_STATE_MULTIPART_END) {
		camel_mime_parser_unstep (mp);
		bodypart = camel_mime_part_new ();
		camel_mime_part_construct_from_parser_sync (
			bodypart, mp, NULL, NULL);
		camel_multipart_add_part (multipart, bodypart);
		g_object_unref (bodypart);
	}

	/* these are only return valid data in the MULTIPART_END state */
	camel_multipart_set_preface (multipart, camel_mime_parser_preface (mp));
	camel_multipart_set_postface (multipart, camel_mime_parser_postface (mp));

	err = camel_mime_parser_errno (mp);
	if (err != 0) {
		errno = err;
		return -1;
	} else
		return 0;
}

static void
camel_multipart_class_init (CamelMultipartClass *class)
{
	GObjectClass *object_class;
	CamelDataWrapperClass *data_wrapper_class;

	g_type_class_add_private (class, sizeof (CamelMultipartPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = multipart_dispose;
	object_class->finalize = multipart_finalize;

	data_wrapper_class = CAMEL_DATA_WRAPPER_CLASS (class);
	data_wrapper_class->is_offline = multipart_is_offline;
	data_wrapper_class->write_to_stream_sync = multipart_write_to_stream_sync;
	data_wrapper_class->decode_to_stream_sync = multipart_write_to_stream_sync;
	data_wrapper_class->write_to_output_stream_sync = multipart_write_to_output_stream_sync;
	data_wrapper_class->decode_to_output_stream_sync = multipart_write_to_output_stream_sync;

	class->add_part = multipart_add_part;
	class->get_part = multipart_get_part;
	class->get_number = multipart_get_number;
	class->set_boundary = multipart_set_boundary;
	class->get_boundary = multipart_get_boundary;
	class->construct_from_parser = multipart_construct_from_parser;
}

static void
camel_multipart_init (CamelMultipart *multipart)
{
	multipart->priv = CAMEL_MULTIPART_GET_PRIVATE (multipart);

	multipart->priv->parts =
		g_ptr_array_new_with_free_func (g_object_unref);

	camel_data_wrapper_set_mime_type (
		CAMEL_DATA_WRAPPER (multipart), "multipart/mixed");
}

/**
 * camel_multipart_new:
 *
 * Create a new #CamelMultipart object.
 *
 * Returns: a new #CamelMultipart object
 **/
CamelMultipart *
camel_multipart_new (void)
{
	return g_object_new (CAMEL_TYPE_MULTIPART, NULL);
}

/**
 * camel_multipart_add_part:
 * @multipart: a #CamelMultipart object
 * @part: a #CamelMimePart to add
 *
 * Appends the part to the multipart object.
 **/
void
camel_multipart_add_part (CamelMultipart *multipart,
                          CamelMimePart *part)
{
	CamelMultipartClass *class;

	g_return_if_fail (CAMEL_IS_MULTIPART (multipart));
	g_return_if_fail (CAMEL_IS_MIME_PART (part));

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->add_part != NULL);

	class->add_part (multipart, part);
}

/**
 * camel_multipart_get_part:
 * @multipart: a #CamelMultipart object
 * @index: a zero-based index indicating the part to get
 *
 * Returns: (transfer none): the indicated subpart, or %NULL
 **/
CamelMimePart *
camel_multipart_get_part (CamelMultipart *multipart,
                          guint index)
{
	CamelMultipartClass *class;

	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), NULL);

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_part != NULL, NULL);

	return class->get_part (multipart, index);
}

/**
 * camel_multipart_get_number:
 * @multipart: a #CamelMultipart object
 *
 * Returns: the number of subparts in @multipart
 **/
guint
camel_multipart_get_number (CamelMultipart *multipart)
{
	CamelMultipartClass *class;

	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), 0);

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_val_if_fail (class != NULL, 0);
	g_return_val_if_fail (class->get_number != NULL, 0);

	return class->get_number (multipart);
}

/**
 * camel_multipart_get_boundary:
 * @multipart: a #CamelMultipart object
 *
 * Returns: the boundary
 **/
const gchar *
camel_multipart_get_boundary (CamelMultipart *multipart)
{
	CamelMultipartClass *class;

	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), NULL);

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_boundary != NULL, NULL);

	return class->get_boundary (multipart);
}

/**
 * camel_multipart_set_boundary:
 * @multipart: a #CamelMultipart object
 * @boundary: the message boundary, or %NULL
 *
 * Sets the message boundary for @multipart to @boundary. This should
 * be a string which does not occur anywhere in any of @multipart's
 * subparts. If @boundary is %NULL, a randomly-generated boundary will
 * be used.
 **/
void
camel_multipart_set_boundary (CamelMultipart *multipart,
                              const gchar *boundary)
{
	CamelMultipartClass *class;

	g_return_if_fail (CAMEL_IS_MULTIPART (multipart));

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->set_boundary != NULL);

	class->set_boundary (multipart, boundary);
}

/**
 * camel_multipart_get_preface:
 * @multipart: a #CamelMultipart
 *
 * Returns the preface text for @multipart.
 *
 * Returns: the preface text
 *
 * Since: 3.12
 **/
const gchar *
camel_multipart_get_preface (CamelMultipart *multipart)
{
	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), NULL);

	return multipart->priv->preface;
}

/**
 * camel_multipart_set_preface:
 * @multipart: a #CamelMultipart object
 * @preface: the multipart preface
 *
 * Set the preface text for this multipart.  Will be written out infront
 * of the multipart.  This text should only include US-ASCII strings, and
 * be relatively short, and will be ignored by any MIME mail client.
 **/
void
camel_multipart_set_preface (CamelMultipart *multipart,
                             const gchar *preface)
{
	g_return_if_fail (CAMEL_IS_MULTIPART (multipart));

	if (multipart->priv->preface == preface)
		return;

	g_free (multipart->priv->preface);
	multipart->priv->preface = g_strdup (preface);
}

/**
 * camel_multipart_get_postface:
 * @multipart: a #CamelMultipart
 *
 * Returns the postface text for @multipart.
 *
 * Returns: the postface text
 *
 * Since: 3.12
 **/
const gchar *
camel_multipart_get_postface (CamelMultipart *multipart)
{
	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), NULL);

	return multipart->priv->postface;
}

/**
 * camel_multipart_set_postface:
 * @multipart: a #CamelMultipart object
 * @postface: multipat postface
 *
 * Set the postface text for this multipart.  Will be written out after
 * the last boundary of the multipart, and ignored by any MIME mail
 * client.
 *
 * Generally postface texts should not be sent with multipart messages.
 **/
void
camel_multipart_set_postface (CamelMultipart *multipart,
                              const gchar *postface)
{
	g_return_if_fail (CAMEL_IS_MULTIPART (multipart));

	if (multipart->priv->postface == postface)
		return;

	g_free (multipart->priv->postface);
	multipart->priv->postface = g_strdup (postface);
}

/**
 * camel_multipart_construct_from_parser:
 * @multipart: a #CamelMultipart object
 * @parser: a #CamelMimeParser object
 *
 * Construct a multipart from a parser.
 *
 * Returns: 0 on success or -1 on fail
 **/
gint
camel_multipart_construct_from_parser (CamelMultipart *multipart,
                                       CamelMimeParser *mp)
{
	CamelMultipartClass *class;

	g_return_val_if_fail (CAMEL_IS_MULTIPART (multipart), -1);
	g_return_val_if_fail (CAMEL_IS_MIME_PARSER (mp), -1);

	class = CAMEL_MULTIPART_GET_CLASS (multipart);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->construct_from_parser != NULL, -1);

	return class->construct_from_parser (multipart, mp);
}
