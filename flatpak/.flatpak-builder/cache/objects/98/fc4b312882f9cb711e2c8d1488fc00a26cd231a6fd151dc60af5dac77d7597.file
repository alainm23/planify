/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourceengine.c
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

/* Interface for syntax highlighting engines. */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourceengine.h"
#include "gtksourcestylescheme.h"

G_DEFINE_INTERFACE (GtkSourceEngine, _gtk_source_engine, G_TYPE_OBJECT)

static void
_gtk_source_engine_default_init (GtkSourceEngineInterface *interface)
{
}

void
_gtk_source_engine_attach_buffer (GtkSourceEngine *engine,
				  GtkTextBuffer   *buffer)
{
	g_return_if_fail (GTK_SOURCE_IS_ENGINE (engine));
	g_return_if_fail (GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->attach_buffer != NULL);

	GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->attach_buffer (engine, buffer);
}

void
_gtk_source_engine_text_inserted (GtkSourceEngine *engine,
				  gint             start_offset,
				  gint             end_offset)
{
	g_return_if_fail (GTK_SOURCE_IS_ENGINE (engine));
	g_return_if_fail (GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->text_inserted != NULL);

	GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->text_inserted (engine,
								 start_offset,
								 end_offset);
}

void
_gtk_source_engine_text_deleted (GtkSourceEngine *engine,
				 gint             offset,
				 gint             length)
{
	g_return_if_fail (GTK_SOURCE_IS_ENGINE (engine));
	g_return_if_fail (GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->text_deleted != NULL);

	GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->text_deleted (engine,
								offset,
								length);
}

void
_gtk_source_engine_update_highlight (GtkSourceEngine   *engine,
				     const GtkTextIter *start,
				     const GtkTextIter *end,
				     gboolean           synchronous)
{
	g_return_if_fail (GTK_SOURCE_IS_ENGINE (engine));
	g_return_if_fail (start != NULL && end != NULL);
	g_return_if_fail (GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->update_highlight != NULL);

	GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->update_highlight (engine,
								    start,
								    end,
								    synchronous);
}

void
_gtk_source_engine_set_style_scheme (GtkSourceEngine      *engine,
				     GtkSourceStyleScheme *scheme)
{
	g_return_if_fail (GTK_SOURCE_IS_ENGINE (engine));
	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME (scheme) || scheme == NULL);
	g_return_if_fail (GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->set_style_scheme != NULL);

	GTK_SOURCE_ENGINE_GET_INTERFACE (engine)->set_style_scheme (engine, scheme);
}
