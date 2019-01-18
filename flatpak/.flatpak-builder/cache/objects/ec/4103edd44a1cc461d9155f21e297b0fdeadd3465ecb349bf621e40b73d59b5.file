/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
/* camelMimeMessage.h : class for a mime message
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
 *	    Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_MESSAGE_H
#define CAMEL_MIME_MESSAGE_H

#include <camel/camel-mime-part.h>
#include <camel/camel-mime-utils.h>
#include <camel/camel-internet-address.h>
#include <camel/camel-mime-filter-bestenc.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MIME_MESSAGE \
	(camel_mime_message_get_type ())
#define CAMEL_MIME_MESSAGE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MIME_MESSAGE, CamelMimeMessage))
#define CAMEL_MIME_MESSAGE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_MESSAGE, CamelMimeMessageClass))
#define CAMEL_IS_MIME_MESSAGE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_MESSAGE))
#define CAMEL_IS_MIME_MESSAGE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_MESSAGE))
#define CAMEL_MIME_MESSAGE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_MESSAGE, CamelMimeMessageClass))

#define CAMEL_RECIPIENT_TYPE_TO "To"
#define CAMEL_RECIPIENT_TYPE_CC "Cc"
#define CAMEL_RECIPIENT_TYPE_BCC "Bcc"

#define CAMEL_RECIPIENT_TYPE_RESENT_TO "Resent-To"
#define CAMEL_RECIPIENT_TYPE_RESENT_CC "Resent-Cc"
#define CAMEL_RECIPIENT_TYPE_RESENT_BCC "Resent-Bcc"

/* specify local time */
#define CAMEL_MESSAGE_DATE_CURRENT (~0)

G_BEGIN_DECLS

typedef struct _CamelMimeMessage CamelMimeMessage;
typedef struct _CamelMimeMessageClass CamelMimeMessageClass;
typedef struct _CamelMimeMessagePrivate CamelMimeMessagePrivate;

struct _CamelMimeMessage {
	CamelMimePart parent;
	CamelMimeMessagePrivate *priv;
};

struct _CamelMimeMessageClass {
	CamelMimePartClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mime_message_get_type	(void);
CamelMimeMessage *
		camel_mime_message_new		(void);
void		camel_mime_message_set_date	(CamelMimeMessage *message,
						 time_t date,
						 gint offset);
time_t		camel_mime_message_get_date	(CamelMimeMessage *message,
						 gint *offset);
time_t		camel_mime_message_get_date_received
						(CamelMimeMessage *message,
						 gint *offset);
void		camel_mime_message_set_message_id
						(CamelMimeMessage *message,
						 const gchar *message_id);
const gchar *	camel_mime_message_get_message_id
						 (CamelMimeMessage *message);
void		camel_mime_message_set_reply_to	(CamelMimeMessage *message,
						 CamelInternetAddress *reply_to);
CamelInternetAddress *
		camel_mime_message_get_reply_to	(CamelMimeMessage *message);
void		camel_mime_message_set_subject	(CamelMimeMessage *message,
						 const gchar *subject);
const gchar *	camel_mime_message_get_subject	(CamelMimeMessage *message);
void		camel_mime_message_set_from	(CamelMimeMessage *message,
						 CamelInternetAddress *from);
CamelInternetAddress *
		camel_mime_message_get_from	(CamelMimeMessage *message);
CamelInternetAddress *
		camel_mime_message_get_recipients
						(CamelMimeMessage *message,
						 const gchar *type);
void		camel_mime_message_set_recipients
						(CamelMimeMessage *message,
						 const gchar *type,
						 CamelInternetAddress *recipients);
void		camel_mime_message_set_source	(CamelMimeMessage *message,
						 const gchar *source_uid);
const gchar *	camel_mime_message_get_source	(CamelMimeMessage *message);

/* utility functions */
gboolean	camel_mime_message_has_8bit_parts
						(CamelMimeMessage *message);
void		camel_mime_message_set_best_encoding
						(CamelMimeMessage *message,
						 CamelBestencRequired required,
						 CamelBestencEncoding enctype);
void		camel_mime_message_encode_8bit_parts
						(CamelMimeMessage *message);
CamelMimePart *	camel_mime_message_get_part_by_content_id
						(CamelMimeMessage *message,
						 const gchar *content_id);
gchar *		camel_mime_message_build_mbox_from
						(CamelMimeMessage *message);
gboolean	camel_mime_message_has_attachment
						(CamelMimeMessage *message);
void		camel_mime_message_dump		(CamelMimeMessage *message,
						 gint body);

G_END_DECLS

#endif /* CAMEL_MIME_MESSAGE_H */
