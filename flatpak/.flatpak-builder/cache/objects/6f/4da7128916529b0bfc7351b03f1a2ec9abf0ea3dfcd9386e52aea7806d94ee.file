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

#ifndef CAMEL_ICONV_H
#define CAMEL_ICONV_H

#include <sys/types.h>
#include <glib.h>

G_BEGIN_DECLS

const gchar *	camel_iconv_locale_charset	(void);
const gchar *	camel_iconv_locale_language	(void);

const gchar *	camel_iconv_charset_name	(const gchar *charset);
const gchar *	camel_iconv_charset_language	(const gchar *charset);

GIConv		camel_iconv_open		(const gchar *to,
						 const gchar *from);
gsize		camel_iconv			(GIConv cd,
						 const gchar **inbuf,
						 gsize *inleft,
						 gchar **outbuf,
						 gsize *outleft);
void		camel_iconv_close		(GIConv cd);

G_END_DECLS

#endif /* CAMEL_ICONV_H */
