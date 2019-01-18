/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-mime-part-utils : Utility for mime parsing and so on
 *
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_PART_UTILS_H
#define CAMEL_MIME_PART_UTILS_H

#include <camel/camel-mime-part.h>
#include <camel/camel-folder-summary.h>

G_BEGIN_DECLS

gboolean	camel_mime_part_construct_content_from_parser
						(CamelMimePart *mime_part,
						 CamelMimeParser *mp,
						 GCancellable *cancellable,
						 GError **error);

typedef struct _CamelMessageContentInfo CamelMessageContentInfo;

/* A tree of message content info structures
 * describe the content structure of the message (if it has any) */
struct _CamelMessageContentInfo {
	CamelMessageContentInfo *next;

	CamelMessageContentInfo *childs;
	CamelMessageContentInfo *parent;

	CamelContentType *type;
	CamelContentDisposition *disposition;
	gchar *id;
	gchar *description;
	gchar *encoding;
	guint32 size;
};

GType		camel_message_content_info_get_type
						(void) G_GNUC_CONST;
CamelMessageContentInfo *
		camel_message_content_info_new	(void);
CamelMessageContentInfo *
		camel_message_content_info_copy	(const CamelMessageContentInfo *src);
void		camel_message_content_info_free	(CamelMessageContentInfo *ci);
CamelMessageContentInfo *
		camel_message_content_info_new_from_headers
						(const CamelNameValueArray *headers);
CamelMessageContentInfo *
		camel_message_content_info_new_from_parser
						(CamelMimeParser *parser);
CamelMessageContentInfo *
		camel_message_content_info_new_from_message
						(CamelMimePart *mime_part);
gboolean	camel_message_content_info_traverse
						(CamelMessageContentInfo *ci,
						 gboolean (* func) (CamelMessageContentInfo *ci,
								    gint depth,
								    gpointer user_data),
						 gpointer user_data);
/* debugging functions */
void		camel_message_content_info_dump	(CamelMessageContentInfo *ci,
						 gint depth);

G_END_DECLS

#endif /*  CAMEL_MIME_PART_UTILS_H  */
