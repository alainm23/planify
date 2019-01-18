/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourceengine.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Gustavo Giráldez
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

#ifndef GTK_SOURCE_ENGINE_H
#define GTK_SOURCE_ENGINE_H

#include <gtk/gtk.h>
#include "gtksourcetypes.h"
#include "gtksourcetypes-private.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_ENGINE               (_gtk_source_engine_get_type ())
#define GTK_SOURCE_ENGINE(obj)               (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_ENGINE, GtkSourceEngine))
#define GTK_SOURCE_IS_ENGINE(obj)            (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_ENGINE))
#define GTK_SOURCE_ENGINE_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), GTK_SOURCE_TYPE_ENGINE, GtkSourceEngineInterface))

typedef struct _GtkSourceEngineInterface GtkSourceEngineInterface;

struct _GtkSourceEngineInterface
{
	GTypeInterface parent_interface;

	void     (* attach_buffer)    (GtkSourceEngine      *engine,
				       GtkTextBuffer        *buffer);

	void     (* text_inserted)    (GtkSourceEngine      *engine,
				       gint                  start_offset,
				       gint                  end_offset);
	void     (* text_deleted)     (GtkSourceEngine      *engine,
				       gint                  offset,
				       gint                  length);

	void     (* update_highlight) (GtkSourceEngine      *engine,
				       const GtkTextIter    *start,
				       const GtkTextIter    *end,
				       gboolean              synchronous);

	void     (* set_style_scheme) (GtkSourceEngine      *engine,
				       GtkSourceStyleScheme *scheme);
};

G_GNUC_INTERNAL
GType       _gtk_source_engine_get_type		(void) G_GNUC_CONST;

G_GNUC_INTERNAL
void        _gtk_source_engine_attach_buffer	(GtkSourceEngine      *engine,
						 GtkTextBuffer        *buffer);

G_GNUC_INTERNAL
void        _gtk_source_engine_text_inserted	(GtkSourceEngine      *engine,
						 gint                  start_offset,
						 gint                  end_offset);

G_GNUC_INTERNAL
void        _gtk_source_engine_text_deleted	(GtkSourceEngine      *engine,
						 gint                  offset,
						 gint                  length);

G_GNUC_INTERNAL
void        _gtk_source_engine_update_highlight	(GtkSourceEngine      *engine,
						 const GtkTextIter    *start,
						 const GtkTextIter    *end,
						 gboolean              synchronous);

G_GNUC_INTERNAL
void        _gtk_source_engine_set_style_scheme	(GtkSourceEngine      *engine,
						 GtkSourceStyleScheme *scheme);

G_END_DECLS

#endif /* GTK_SOURCE_ENGINE_H */
