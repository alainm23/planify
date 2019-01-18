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

#ifndef CAMEL_URL_SCANNER_H
#define CAMEL_URL_SCANNER_H

#include <glib.h>
#include <sys/types.h>

G_BEGIN_DECLS

typedef struct {
	const gchar *pattern;
	const gchar *prefix;
	goffset um_so;
	goffset um_eo;
} CamelUrlMatch;

typedef gboolean (*CamelUrlScanFunc) (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);

/* some default CamelUrlScanFunc's */
gboolean camel_url_file_start (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);
gboolean camel_url_file_end (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);
gboolean camel_url_web_start (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);
gboolean camel_url_web_end (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);
gboolean camel_url_addrspec_start (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);
gboolean camel_url_addrspec_end (const gchar *in, const gchar *pos, const gchar *inend, CamelUrlMatch *match);

typedef struct {
	const gchar *pattern;
	const gchar *prefix;
	CamelUrlScanFunc start;
	CamelUrlScanFunc end;
} CamelUrlPattern;

typedef struct _CamelUrlScanner CamelUrlScanner;

CamelUrlScanner *camel_url_scanner_new (void);
void camel_url_scanner_free (CamelUrlScanner *scanner);

void camel_url_scanner_add (CamelUrlScanner *scanner, CamelUrlPattern *pattern);

gboolean camel_url_scanner_scan (CamelUrlScanner *scanner, const gchar *in, gsize inlen, CamelUrlMatch *match);

G_END_DECLS

#endif /* CAMEL_URL_SCANNER_H */
