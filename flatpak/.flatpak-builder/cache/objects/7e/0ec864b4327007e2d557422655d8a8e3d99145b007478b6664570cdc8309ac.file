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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_STRING_UTILS_H
#define CAMEL_STRING_UTILS_H

#include <glib.h>

G_BEGIN_DECLS

gint   camel_strcase_equal (gconstpointer a, gconstpointer b);
guint camel_strcase_hash  (gconstpointer v);

gchar *camel_strstrcase (const gchar *haystack, const gchar *needle);

const gchar *camel_strdown (gchar *str);

const gchar *camel_pstring_add (gchar *string, gboolean own);
const gchar *camel_pstring_strdup (const gchar *string);
void camel_pstring_free (const gchar *string);
const gchar * camel_pstring_peek (const gchar *string);
gboolean camel_pstring_contains (const gchar *string);
void camel_pstring_dump_stat (void);

G_END_DECLS

#endif /* CAMEL_STRING_UTILS_H */
