/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcebufferoutputstream.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2010 - Ignacio Casal Quinteiro
 * Copyright (C) 2014 - Sébastien Wilmet <swilmet@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_BUFFER_OUTPUT_STREAM_H
#define GTK_SOURCE_BUFFER_OUTPUT_STREAM_H

#include <gtk/gtk.h>
#include "gtksourcetypes.h"
#include "gtksourcetypes-private.h"
#include "gtksourcebuffer.h"
#include "gtksourcefile.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM		(gtk_source_buffer_output_stream_get_type ())
#define GTK_SOURCE_BUFFER_OUTPUT_STREAM(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM, GtkSourceBufferOutputStream))
#define GTK_SOURCE_BUFFER_OUTPUT_STREAM_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM, GtkSourceBufferOutputStreamClass))
#define GTK_SOURCE_IS_BUFFER_OUTPUT_STREAM(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM))
#define GTK_SOURCE_IS_BUFFER_OUTPUT_STREAM_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM))
#define GTK_SOURCE_BUFFER_OUTPUT_STREAM_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_BUFFER_OUTPUT_STREAM, GtkSourceBufferOutputStreamClass))

typedef struct _GtkSourceBufferOutputStreamClass	GtkSourceBufferOutputStreamClass;
typedef struct _GtkSourceBufferOutputStreamPrivate	GtkSourceBufferOutputStreamPrivate;

struct _GtkSourceBufferOutputStream
{
	GOutputStream parent;

	GtkSourceBufferOutputStreamPrivate *priv;
};

struct _GtkSourceBufferOutputStreamClass
{
	GOutputStreamClass parent_class;
};

GTK_SOURCE_INTERNAL
GType			 gtk_source_buffer_output_stream_get_type	(void) G_GNUC_CONST;

GTK_SOURCE_INTERNAL
GtkSourceBufferOutputStream
			*gtk_source_buffer_output_stream_new		(GtkSourceBuffer             *buffer,
									 GSList                      *candidate_encodings,
									 gboolean                     remove_trailing_newline);

GTK_SOURCE_INTERNAL
GtkSourceNewlineType	 gtk_source_buffer_output_stream_detect_newline_type
									(GtkSourceBufferOutputStream *stream);

GTK_SOURCE_INTERNAL
const GtkSourceEncoding	*gtk_source_buffer_output_stream_get_guessed	(GtkSourceBufferOutputStream *stream);

GTK_SOURCE_INTERNAL
guint			 gtk_source_buffer_output_stream_get_num_fallbacks
									(GtkSourceBufferOutputStream *stream);

G_END_DECLS

#endif /* GTK_SOURCE_BUFFER_OUTPUT_STREAM_H */
