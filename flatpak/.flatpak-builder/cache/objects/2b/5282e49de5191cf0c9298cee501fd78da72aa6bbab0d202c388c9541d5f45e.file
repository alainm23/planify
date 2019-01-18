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
 *	    Michael Zucchi <NotZed@Ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_FILTER_SEARCH_H
#define CAMEL_FILTER_SEARCH_H

#include <stdio.h>

#include <camel/camel-mime-message.h>
#include <camel/camel-folder-summary.h>

G_BEGIN_DECLS

struct _CamelSession;

enum {
	CAMEL_SEARCH_ERROR = -1,
	CAMEL_SEARCH_NOMATCH = 0,
	CAMEL_SEARCH_MATCHED = 1
};

typedef CamelMimeMessage * (*CamelFilterSearchGetMessageFunc) (gpointer data, GCancellable *cancellable, GError **error);

gint camel_filter_search_match (struct _CamelSession *session,
				CamelFilterSearchGetMessageFunc get_message,
				gpointer user_data,
				CamelMessageInfo *info,
				const gchar *source,
				struct _CamelFolder *folder,
				const gchar *expression,
				GCancellable *cancellable,
				GError **error);
gint camel_filter_search_match_with_log
				(struct _CamelSession *session,
				 CamelFilterSearchGetMessageFunc get_message,
				 gpointer user_data,
				 CamelMessageInfo *info,
				 const gchar *source,
				 struct _CamelFolder *folder,
				 const gchar *expression,
				 FILE *logfile,
				 GCancellable *cancellable,
				 GError **error);

G_END_DECLS

#endif /* CAMEL_FILTER_SEARCH_H */
