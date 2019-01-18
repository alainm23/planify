/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcebufferinputstream.h
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

#ifndef GTK_SOURCE_BUFFER_INPUT_STREAM_H
#define GTK_SOURCE_BUFFER_INPUT_STREAM_H

#include <gio/gio.h>
#include <gtk/gtk.h>
#include "gtksourcetypes-private.h"
#include "gtksourcebuffer.h"
#include "gtksourcefile.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM		(_gtk_source_buffer_input_stream_get_type ())
#define GTK_SOURCE_BUFFER_INPUT_STREAM(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM, GtkSourceBufferInputStream))
#define GTK_SOURCE_BUFFER_INPUT_STREAM_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM, GtkSourceBufferInputStreamClass))
#define GTK_SOURCE_IS_BUFFER_INPUT_STREAM(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM))
#define GTK_SOURCE_IS_BUFFER_INPUT_STREAM_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM))
#define GTK_SOURCE_BUFFER_INPUT_STREAM_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM, GtkSourceBufferInputStreamClass))

typedef struct _GtkSourceBufferInputStreamClass		GtkSourceBufferInputStreamClass;
typedef struct _GtkSourceBufferInputStreamPrivate	GtkSourceBufferInputStreamPrivate;

struct _GtkSourceBufferInputStream
{
	GInputStream parent;

	GtkSourceBufferInputStreamPrivate *priv;
};

struct _GtkSourceBufferInputStreamClass
{
	GInputStreamClass parent_class;
};

GTK_SOURCE_INTERNAL
GType		 _gtk_source_buffer_input_stream_get_type		(void) G_GNUC_CONST;

GTK_SOURCE_INTERNAL
GtkSourceBufferInputStream
		*_gtk_source_buffer_input_stream_new			(GtkTextBuffer              *buffer,
									 GtkSourceNewlineType        type,
									 gboolean                    add_trailing_newline);

GTK_SOURCE_INTERNAL
gsize		 _gtk_source_buffer_input_stream_get_total_size		(GtkSourceBufferInputStream *stream);

GTK_SOURCE_INTERNAL
gsize		 _gtk_source_buffer_input_stream_tell			(GtkSourceBufferInputStream *stream);

G_END_DECLS

#endif /* GTK_SOURCE_BUFFER_INPUT_STREAM_H */
