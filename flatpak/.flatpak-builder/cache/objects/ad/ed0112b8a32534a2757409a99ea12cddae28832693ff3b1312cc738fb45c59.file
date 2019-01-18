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

#ifndef CAMEL_MBOX_STORE_H
#define CAMEL_MBOX_STORE_H

#include "camel-local-store.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MBOX_STORE \
	(camel_mbox_store_get_type ())
#define CAMEL_MBOX_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MBOX_STORE, CamelMboxStore))
#define CAMEL_MBOX_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MBOX_STORE, CamelMboxStoreClass))
#define CAMEL_IS_MBOX_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MBOX_STORE))
#define CAMEL_IS_MBOX_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MBOX_STORE))
#define CAMEL_MBOX_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MBOX_STORE, CamelMboxStoreClass))

G_BEGIN_DECLS

typedef struct _CamelMboxStore CamelMboxStore;
typedef struct _CamelMboxStoreClass CamelMboxStoreClass;

struct _CamelMboxStore {
	CamelLocalStore parent;
};

struct _CamelMboxStoreClass {
	CamelLocalStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_mbox_store_get_type (void);

G_END_DECLS

#endif /* CAMEL_MBOX_STORE_H */

