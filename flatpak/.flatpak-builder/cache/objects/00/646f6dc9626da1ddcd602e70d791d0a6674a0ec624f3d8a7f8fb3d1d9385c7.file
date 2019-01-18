/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionwordsbuffer.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
 *
 * gtksourceview is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * gtksourceview is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_COMPLETION_WORDS_BUFFER_H
#define GTK_SOURCE_COMPLETION_WORDS_BUFFER_H

#include <gtk/gtk.h>

#include "gtksourcecompletionwordslibrary.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER			(gtk_source_completion_words_buffer_get_type ())
#define GTK_SOURCE_COMPLETION_WORDS_BUFFER(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER, GtkSourceCompletionWordsBuffer))
#define GTK_SOURCE_COMPLETION_WORDS_BUFFER_CONST(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER, GtkSourceCompletionWordsBuffer const))
#define GTK_SOURCE_COMPLETION_WORDS_BUFFER_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER, GtkSourceCompletionWordsBufferClass))
#define GTK_SOURCE_IS_COMPLETION_WORDS_BUFFER(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER))
#define GTK_SOURCE_IS_COMPLETION_WORDS_BUFFER_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER))
#define GTK_SOURCE_COMPLETION_WORDS_BUFFER_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_BUFFER, GtkSourceCompletionWordsBufferClass))

typedef struct _GtkSourceCompletionWordsBuffer			GtkSourceCompletionWordsBuffer;
typedef struct _GtkSourceCompletionWordsBufferClass		GtkSourceCompletionWordsBufferClass;
typedef struct _GtkSourceCompletionWordsBufferPrivate		GtkSourceCompletionWordsBufferPrivate;

struct _GtkSourceCompletionWordsBuffer {
	GObject parent;

	GtkSourceCompletionWordsBufferPrivate *priv;
};

struct _GtkSourceCompletionWordsBufferClass {
	GObjectClass parent_class;
};

G_GNUC_INTERNAL
GType		 gtk_source_completion_words_buffer_get_type			(void) G_GNUC_CONST;

G_GNUC_INTERNAL
GtkSourceCompletionWordsBuffer *
		 gtk_source_completion_words_buffer_new				(GtkSourceCompletionWordsLibrary *library,
										 GtkTextBuffer                   *buffer);

G_GNUC_INTERNAL
GtkTextBuffer 	*gtk_source_completion_words_buffer_get_buffer			(GtkSourceCompletionWordsBuffer  *buffer);

G_GNUC_INTERNAL
void		 gtk_source_completion_words_buffer_set_scan_batch_size		(GtkSourceCompletionWordsBuffer  *buffer,
										 guint                            size);

G_GNUC_INTERNAL
void		 gtk_source_completion_words_buffer_set_minimum_word_size	(GtkSourceCompletionWordsBuffer  *buffer,
										 guint                            size);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_WORDS_BUFFER_H */
