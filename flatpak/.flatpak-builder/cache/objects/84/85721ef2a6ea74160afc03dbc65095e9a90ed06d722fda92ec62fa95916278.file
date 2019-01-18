/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcebufferinternal.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2016 - Sébastien Wilmet <swilmet@gnome.org>
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

#include "gtksourcebufferinternal.h"
#include "gtksourcebuffer.h"
#include "gtksourcesearchcontext.h"

/* A private extension of GtkSourceBuffer, to add private signals and
 * properties.
 */

struct _GtkSourceBufferInternal
{
	GObject parent_instance;
};

enum
{
	SIGNAL_SEARCH_START,
	N_SIGNALS
};

#define GTK_SOURCE_BUFFER_INTERNAL_KEY "gtk-source-buffer-internal-key"

static guint signals[N_SIGNALS];

G_DEFINE_TYPE (GtkSourceBufferInternal, _gtk_source_buffer_internal, G_TYPE_OBJECT)

static void
_gtk_source_buffer_internal_class_init (GtkSourceBufferInternalClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	/*
	 * GtkSourceBufferInternal::search-start:
	 * @buffer_internal: the object that received the signal.
	 * @search_context: the #GtkSourceSearchContext.
	 *
	 * The ::search-start signal is emitted when a search is starting.
	 */
	signals[SIGNAL_SEARCH_START] =
		g_signal_new ("search-start",
			      G_OBJECT_CLASS_TYPE (object_class),
			      G_SIGNAL_RUN_LAST,
			      0,
			      NULL, NULL, NULL,
			      G_TYPE_NONE,
			      1, GTK_SOURCE_TYPE_SEARCH_CONTEXT);
}

static void
_gtk_source_buffer_internal_init (GtkSourceBufferInternal *buffer_internal)
{
}

/*
 * _gtk_source_buffer_internal_get_from_buffer:
 * @buffer: a #GtkSourceBuffer.
 *
 * Returns the #GtkSourceBufferInternal object of @buffer. The returned object
 * is guaranteed to be the same for the lifetime of @buffer.
 *
 * Returns: (transfer none): the #GtkSourceBufferInternal object of @buffer.
 */
GtkSourceBufferInternal *
_gtk_source_buffer_internal_get_from_buffer (GtkSourceBuffer *buffer)
{
	GtkSourceBufferInternal *buffer_internal;

	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER (buffer), NULL);

	buffer_internal = g_object_get_data (G_OBJECT (buffer), GTK_SOURCE_BUFFER_INTERNAL_KEY);

	if (buffer_internal == NULL)
	{
		buffer_internal = g_object_new (GTK_SOURCE_TYPE_BUFFER_INTERNAL, NULL);

		g_object_set_data_full (G_OBJECT (buffer),
					GTK_SOURCE_BUFFER_INTERNAL_KEY,
					buffer_internal,
					g_object_unref);
	}

	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER_INTERNAL (buffer_internal), NULL);
	return buffer_internal;
}

void
_gtk_source_buffer_internal_emit_search_start (GtkSourceBufferInternal *buffer_internal,
					       GtkSourceSearchContext  *search_context)
{
	g_return_if_fail (GTK_SOURCE_IS_BUFFER_INTERNAL (buffer_internal));
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search_context));

	g_signal_emit (buffer_internal,
		       signals[SIGNAL_SEARCH_START],
		       0,
		       search_context);
}
