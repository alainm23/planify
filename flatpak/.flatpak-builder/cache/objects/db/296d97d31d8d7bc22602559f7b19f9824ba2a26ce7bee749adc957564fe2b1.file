/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-smtp-transport.h : class for an smtp transfer
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
 * Authors: Jeffrey Stedfast <fejj@stampede.org>
 */

#ifndef CAMEL_SMTP_TRANSPORT_H
#define CAMEL_SMTP_TRANSPORT_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SMTP_TRANSPORT \
	(camel_smtp_transport_get_type ())
#define CAMEL_SMTP_TRANSPORT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SMTP_TRANSPORT, CamelSmtpTransport))
#define CAMEL_SMTP_TRANSPORT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SMTP_TRANSPORT, CamelSmtpTransportClass))
#define CAMEL_IS_SMTP_TRANSPORT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SMTP_TRANSPORT))
#define CAMEL_IS_SMTP_TRANSPORT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SMTP_TRANSPORT))
#define CAMEL_SMTP_TRANSPORT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SMTP_TRANSPORT, CamelSmtpTransportClass))

G_BEGIN_DECLS

typedef struct _CamelSmtpTransport CamelSmtpTransport;
typedef struct _CamelSmtpTransportClass CamelSmtpTransportClass;

struct _CamelSmtpTransport {
	CamelTransport parent;

	GMutex stream_lock;
	CamelStreamBuffer *istream;
	CamelStream *ostream;
	GSocketAddress *local_address;

	guint32 flags;

	gboolean need_rset;
	gboolean connected;

	GHashTable *authtypes;
};

struct _CamelSmtpTransportClass {
	CamelTransportClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_smtp_transport_get_type (void);

G_END_DECLS

#endif /* CAMEL_SMTP_TRANSPORT_H */
