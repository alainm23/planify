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

#ifndef CAMEL_INTERNET_ADDRESS_H
#define CAMEL_INTERNET_ADDRESS_H

#include <camel/camel-address.h>

/* Standard GObject macros */
#define CAMEL_TYPE_INTERNET_ADDRESS \
	(camel_internet_address_get_type ())
#define CAMEL_INTERNET_ADDRESS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_INTERNET_ADDRESS, CamelInternetAddress))
#define CAMEL_INTERNET_ADDRESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_INTERNET_ADDRESS, CamelInternetAddressClass))
#define CAMEL_IS_INTERNET_ADDRESS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_INTERNET_ADDRESS))
#define CAMEL_IS_INTERNET_ADDRESS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_INTERNET_ADDRESS))
#define CAMEL_INTERNET_ADDRESS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_INTERNET_ADDRESS, CamelInternetAddressClass))

G_BEGIN_DECLS

typedef struct _CamelInternetAddress CamelInternetAddress;
typedef struct _CamelInternetAddressClass CamelInternetAddressClass;
typedef struct _CamelInternetAddressPrivate CamelInternetAddressPrivate;

struct _CamelInternetAddress {
	CamelAddress parent;
	CamelInternetAddressPrivate *priv;
};

struct _CamelInternetAddressClass {
	CamelAddressClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_internet_address_get_type	(void);
CamelInternetAddress *
		camel_internet_address_new	(void);
gint		camel_internet_address_add	(CamelInternetAddress *addr,
						 const gchar *name,
						 const gchar *address);
gboolean	camel_internet_address_get	(CamelInternetAddress *addr,
						 gint index,
						 const gchar **namep,
						 const gchar **addressp);
gint		camel_internet_address_find_name (CamelInternetAddress *addr,
						 const gchar *name,
						 const gchar **addressp);
gint		camel_internet_address_find_address
						(CamelInternetAddress *addr,
						 const gchar *address,
						 const gchar **namep);
void		camel_internet_address_ensure_ascii_domains
						(CamelInternetAddress *addr);

/* utility functions, for network/display formatting */
gchar *		camel_internet_address_encode_address
						(gint *len,
						 const gchar *name,
						 const gchar *addr);
gchar *		camel_internet_address_format_address
						(const gchar *name,
						 const gchar *addr);

G_END_DECLS

#endif /* CAMEL_INTERNET_ADDRESS_H */
