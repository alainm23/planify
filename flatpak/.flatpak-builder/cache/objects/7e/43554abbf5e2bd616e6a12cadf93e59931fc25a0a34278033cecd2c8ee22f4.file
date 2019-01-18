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

#ifndef CAMEL_CHARSET_MAP_H
#define CAMEL_CHARSET_MAP_H

#include <glib.h>

G_BEGIN_DECLS

typedef struct _CamelCharset CamelCharset;

struct _CamelCharset {
	guint mask;
	gint level;
};

void camel_charset_init (CamelCharset *c);
void camel_charset_step (CamelCharset *cc, const gchar *in, gint len);

const gchar *camel_charset_best_name (CamelCharset *charset);

/* helper function */
const gchar *camel_charset_best (const gchar *in, gint len);

const gchar *camel_charset_iso_to_windows (const gchar *isocharset);

G_END_DECLS

#endif /* CAMEL_CHARSET_MAP_H */
