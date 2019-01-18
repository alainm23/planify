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

#ifndef CAMEL_MH_STORE_H
#define CAMEL_MH_STORE_H

#include "camel-local-store.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MH_STORE \
	(camel_mh_store_get_type ())
#define CAMEL_MH_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MH_STORE, CamelMhStore))
#define CAMEL_MH_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MH_STORE, CamelMhStoreClass))
#define CAMEL_IS_MH_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MH_STORE))
#define CAMEL_IS_MH_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MH_STORE))
#define CAMEL_MH_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MH_STORE, CamelMhStoreClass))

G_BEGIN_DECLS

typedef struct _CamelMhStore CamelMhStore;
typedef struct _CamelMhStoreClass CamelMhStoreClass;
typedef struct _CamelMhStorePrivate CamelMhStorePrivate;

struct _CamelMhStore {
	CamelLocalStore parent;
	CamelMhStorePrivate *priv;
};

struct _CamelMhStoreClass {
	CamelLocalStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mh_store_get_type		(void);

G_END_DECLS

#endif /* CAMEL_MH_STORE_H */
