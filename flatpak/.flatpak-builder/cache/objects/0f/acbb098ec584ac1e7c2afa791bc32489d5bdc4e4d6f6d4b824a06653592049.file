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

#ifndef CAMEL_SPOOL_STORE_H
#define CAMEL_SPOOL_STORE_H

#include "camel-mbox-store.h"

/* Standard GObject macros */
#define CAMEL_TYPE_SPOOL_STORE \
	(camel_spool_store_get_type ())
#define CAMEL_SPOOL_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SPOOL_STORE, CamelSpoolStore))
#define CAMEL_SPOOL_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SPOOL_STORE, CamelSpoolStoreClass))
#define CAMEL_IS_SPOOL_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SPOOL_STORE))
#define CAMEL_IS_SPOOL_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SPOOL_STORE))
#define CAMEL_SPOOL_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SPOOL_STORE, CamelSpoolStoreClass))

G_BEGIN_DECLS

typedef struct _CamelSpoolStore CamelSpoolStore;
typedef struct _CamelSpoolStoreClass CamelSpoolStoreClass;
typedef struct _CamelSpoolStorePrivate CamelSpoolStorePrivate;

struct _CamelSpoolStore {
	CamelMboxStore parent;
	CamelSpoolStorePrivate *priv;
};

struct _CamelSpoolStoreClass {
	CamelMboxStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_spool_store_get_type	(void);

G_END_DECLS

#endif /* CAMEL_SPOOL_STORE_H */

