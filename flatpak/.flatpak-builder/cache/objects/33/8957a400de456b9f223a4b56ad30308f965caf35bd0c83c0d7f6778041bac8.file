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

#ifndef CAMEL_UTF8_H
#define CAMEL_UTF8_H

#include <glib.h>

G_BEGIN_DECLS

void camel_utf8_putc (guchar **ptr, guint32 c);
guint32 camel_utf8_getc (const guchar **ptr);
guint32 camel_utf8_getc_limit (const guchar **ptr, const guchar *end);

/* convert utf7 to/from utf8, actually this is modified IMAP utf7 */
gchar *camel_utf7_utf8 (const gchar *ptr);
gchar *camel_utf8_utf7 (const gchar *ptr);

/* convert ucs2 to/from utf8 */
gchar *camel_utf8_ucs2 (const gchar *ptr);
gchar *camel_ucs2_utf8 (const gchar *ptr);

/* make valid utf8 string */
gchar *camel_utf8_make_valid (const gchar *text);

G_END_DECLS

#endif /* CAMEL_UTF8_H */
