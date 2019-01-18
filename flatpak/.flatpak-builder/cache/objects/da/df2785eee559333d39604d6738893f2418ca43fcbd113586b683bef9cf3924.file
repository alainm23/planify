/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-pop3-store.h : class for an pop3 store
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Michael Zucchi <notzed@ximian.com>
 */

#ifndef CAMEL_POP3_STORE_H
#define CAMEL_POP3_STORE_H

#include <camel/camel.h>

#include "camel-pop3-engine.h"

/* Standard GObject macros */
#define CAMEL_TYPE_POP3_STORE \
	(camel_pop3_store_get_type ())
#define CAMEL_POP3_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_POP3_STORE, CamelPOP3Store))
#define CAMEL_POP3_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_POP3_STORE, CamelPOP3StoreClass))
#define CAMEL_IS_POP3_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_POP3_STORE))
#define CAMEL_IS_POP3_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_POP3_STORE))
#define CAMEL_POP3_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_POP3_STORE, CamelPOP3StoreClass))

G_BEGIN_DECLS

typedef struct _CamelPOP3Store CamelPOP3Store;
typedef struct _CamelPOP3StoreClass CamelPOP3StoreClass;
typedef struct _CamelPOP3StorePrivate CamelPOP3StorePrivate;

struct _CamelPOP3Store {
	CamelStore parent;
	CamelPOP3StorePrivate *priv;
};

struct _CamelPOP3StoreClass {
	CamelStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_pop3_store_get_type	(void);
CamelDataCache *
		camel_pop3_store_ref_cache	(CamelPOP3Store *store);
CamelPOP3Engine *
		camel_pop3_store_ref_engine	(CamelPOP3Store *store);
gboolean	camel_pop3_store_expunge	(CamelPOP3Store *store,
						 GCancellable *cancellable,
						 GError **error);
CamelStream *	camel_pop3_store_cache_add	(CamelPOP3Store *store,
						 const gchar *uid,
						 GError **error);
CamelStream *	camel_pop3_store_cache_get	(CamelPOP3Store *store,
						 const gchar *uid,
						 GError **error);
gboolean	camel_pop3_store_cache_has	(CamelPOP3Store *store,
						 const gchar *uid);

G_END_DECLS

#endif /* CAMEL_POP3_STORE_H */

