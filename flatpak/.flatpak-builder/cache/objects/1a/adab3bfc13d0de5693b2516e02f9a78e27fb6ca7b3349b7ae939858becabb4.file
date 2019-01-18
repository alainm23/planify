/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_PARSER_H
#define CAMEL_MIME_PARSER_H

#include <camel/camel-mime-utils.h>
#include <camel/camel-mime-filter.h>
#include <camel/camel-stream.h>
#include <camel/camel-name-value-array.h>

/* Stardard GObject macros */
#define CAMEL_TYPE_MIME_PARSER \
	(camel_mime_parser_get_type ())
#define CAMEL_MIME_PARSER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MIME_PARSER, CamelMimeParser))
#define CAMEL_MIME_PARSER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_PARSER, CamelMimeParserClass))
#define CAMEL_IS_MIME_PARSER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_PARSER))
#define CAMEL_IS_MIME_PARSER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_PARSER))
#define CAMEL_MIME_PARSER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_PARSER, CamelMimeParserClass))

G_BEGIN_DECLS

typedef struct _CamelMimeParser CamelMimeParser;
typedef struct _CamelMimeParserClass CamelMimeParserClass;
typedef struct _CamelMimeParserPrivate CamelMimeParserPrivate;

/* NOTE: if you add more states, you may need to bump the
 * start of the END tags to 16 or 32, etc - so they are
 * the same as the matching start tag, with a bit difference */
typedef enum _camel_mime_parser_state_t {
	CAMEL_MIME_PARSER_STATE_INITIAL,
	CAMEL_MIME_PARSER_STATE_PRE_FROM,       /* data before a 'From' line */
	CAMEL_MIME_PARSER_STATE_FROM,           /* got 'From' line */
	CAMEL_MIME_PARSER_STATE_HEADER,         /* toplevel header */
	CAMEL_MIME_PARSER_STATE_BODY,           /* scanning body of message */
	CAMEL_MIME_PARSER_STATE_MULTIPART,      /* got multipart header */
	CAMEL_MIME_PARSER_STATE_MESSAGE,        /* rfc822 message */

	CAMEL_MIME_PARSER_STATE_PART,           /* part of a multipart */

	CAMEL_MIME_PARSER_STATE_END = 8,        /* bit mask for 'end' flags */

	CAMEL_MIME_PARSER_STATE_EOF = 8,        /* end of file */
	CAMEL_MIME_PARSER_STATE_PRE_FROM_END,   /* pre from end */
	CAMEL_MIME_PARSER_STATE_FROM_END,       /* end of whole from bracket */
	CAMEL_MIME_PARSER_STATE_HEADER_END,     /* dummy value */
	CAMEL_MIME_PARSER_STATE_BODY_END,       /* end of message */
	CAMEL_MIME_PARSER_STATE_MULTIPART_END,  /* end of multipart  */
	CAMEL_MIME_PARSER_STATE_MESSAGE_END     /* end of message */
} CamelMimeParserState;

struct _CamelMimeParser {
	GObject parent;
	CamelMimeParserPrivate *priv;
};

struct _CamelMimeParserClass {
	GObjectClass parent_class;

	void (*message) (CamelMimeParser *parser, gpointer headers);
	void (*part) (CamelMimeParser *parser);
	void (*content) (CamelMimeParser *parser);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_mime_parser_get_type (void);
CamelMimeParser *camel_mime_parser_new (void);

/* quick-fix for parser not erroring, we can find out if it had an error afterwards */
gint		camel_mime_parser_errno (CamelMimeParser *parser);

gint		camel_mime_parser_init_with_fd (CamelMimeParser *m, gint fd);
gint		camel_mime_parser_init_with_stream (CamelMimeParser *m, CamelStream *stream, GError **error);
void		camel_mime_parser_init_with_input_stream (CamelMimeParser *parser, GInputStream *input_stream);
void		camel_mime_parser_init_with_bytes (CamelMimeParser *parser, GBytes *bytes);

CamelStream    *camel_mime_parser_stream (CamelMimeParser *parser);

/* scan 'From' separators? */
void camel_mime_parser_scan_from (CamelMimeParser *parser, gboolean scan_from);
/* Do we want to know about the pre-from data? */
void camel_mime_parser_scan_pre_from (CamelMimeParser *parser, gboolean scan_pre_from);

/* what headers to save, MUST include ^Content-Type: */
gint camel_mime_parser_set_header_regex (CamelMimeParser *parser, gchar *matchstr);

/* normal interface */
CamelMimeParserState camel_mime_parser_step (CamelMimeParser *parser, gchar **databuffer, gsize *datalength);
void camel_mime_parser_unstep (CamelMimeParser *parser);
void camel_mime_parser_drop_step (CamelMimeParser *parser);
CamelMimeParserState camel_mime_parser_state (CamelMimeParser *parser);
void camel_mime_parser_push_state (CamelMimeParser *mp, CamelMimeParserState newstate, const gchar *boundary);

/* read through the parser */
gssize camel_mime_parser_read (CamelMimeParser *parser, const gchar **databuffer, gssize len, GError **error);

/* get content type for the current part/header */
CamelContentType *camel_mime_parser_content_type (CamelMimeParser *parser);

/* get/change raw header by name */
const gchar *camel_mime_parser_header (CamelMimeParser *m, const gchar *name, gint *offset);

/* get all raw headers */
CamelNameValueArray *camel_mime_parser_dup_headers (CamelMimeParser *m);

/* get multipart pre/postface */
const gchar *camel_mime_parser_preface (CamelMimeParser *m);
const gchar *camel_mime_parser_postface (CamelMimeParser *m);

/* return the from line content */
const gchar *camel_mime_parser_from_line (CamelMimeParser *m);

/* add a processing filter for body contents */
gint camel_mime_parser_filter_add (CamelMimeParser *m, CamelMimeFilter *mf);
void camel_mime_parser_filter_remove (CamelMimeParser *m, gint id);

/* these should be used with caution, because the state will not
 * track the seeked position */
/* FIXME: something to bootstrap the state? */
goffset camel_mime_parser_tell (CamelMimeParser *parser);
goffset camel_mime_parser_seek (CamelMimeParser *parser, goffset offset, gint whence);

goffset camel_mime_parser_tell_start_headers (CamelMimeParser *parser);
goffset camel_mime_parser_tell_start_from (CamelMimeParser *parser);
goffset camel_mime_parser_tell_start_boundary (CamelMimeParser *parser);

G_END_DECLS

#endif /* CAMEL_MIME_PARSER_H */
