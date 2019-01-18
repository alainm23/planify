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

#ifndef CAMEL_NNTP_ADDRESS_H
#define CAMEL_NNTP_ADDRESS_H

#include <camel/camel-address.h>

/* Standard GObject macros */
#define CAMEL_TYPE_NNTP_ADDRESS \
	(camel_nntp_address_get_type ())
#define CAMEL_NNTP_ADDRESS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NNTP_ADDRESS, CamelNNTPAddress))
#define CAMEL_NNTP_ADDRESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NNTP_ADDRESS, CamelNNTPAddressClass))
#define CAMEL_IS_NNTP_ADDRESS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NNTP_ADDRESS))
#define CAMEL_IS_NNTP_ADDRESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NNTP_ADDRESS))
#define CAMEL_NNTP_ADDRESS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_NTTP_ADDRESS, CamelNNTPAddressClass))

G_BEGIN_DECLS

typedef struct _CamelNNTPAddress CamelNNTPAddress;
typedef struct _CamelNNTPAddressClass CamelNNTPAddressClass;
typedef struct _CamelNNTPAddressPrivate CamelNNTPAddressPrivate;

struct _CamelNNTPAddress {
	CamelAddress parent;
	CamelNNTPAddressPrivate *priv;
};

struct _CamelNNTPAddressClass {
	CamelAddressClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_nntp_address_get_type	(void);
CamelNNTPAddress *
		camel_nntp_address_new		(void);
gint		camel_nntp_address_add		(CamelNNTPAddress *addr,
						 const gchar *name);
gboolean	camel_nntp_address_get		(CamelNNTPAddress *addr,
						 gint index,
						 const gchar **namep);

G_END_DECLS

#endif /* CAMEL_NNTP_ADDRESS_H */
