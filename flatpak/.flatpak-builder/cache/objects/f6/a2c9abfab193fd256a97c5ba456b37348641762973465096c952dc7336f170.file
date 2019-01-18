/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourceencoding-private.h
 * This file is part of GtkSourceView
 *
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

#ifndef GTK_SOURCE_ENCODING_PRIVATE_H
#define GTK_SOURCE_ENCODING_PRIVATE_H

#include <glib.h>
#include "gtksourcetypes-private.h"

G_BEGIN_DECLS

/*
 * GtkSourceEncodingDuplicates:
 * @GTK_SOURCE_ENCODING_DUPLICATES_KEEP_FIRST: Keep the first occurrence.
 * @GTK_SOURCE_ENCODING_DUPLICATES_KEEP_LAST: Keep the last occurrence.
 *
 * Specifies which encoding occurrence to keep when removing duplicated
 * encodings in a list with gtk_source_encoding_remove_duplicates().
 *
 * Since: 3.14
 */
typedef enum _GtkSourceEncodingDuplicates
{
	GTK_SOURCE_ENCODING_DUPLICATES_KEEP_FIRST,
	GTK_SOURCE_ENCODING_DUPLICATES_KEEP_LAST
} GtkSourceEncodingDuplicates;

GTK_SOURCE_INTERNAL
GSList *		_gtk_source_encoding_remove_duplicates		(GSList                      *encodings,
									 GtkSourceEncodingDuplicates  removal_type);

G_END_DECLS

#endif  /* GTK_SOURCE_ENCODING_PRIVATE_H */
