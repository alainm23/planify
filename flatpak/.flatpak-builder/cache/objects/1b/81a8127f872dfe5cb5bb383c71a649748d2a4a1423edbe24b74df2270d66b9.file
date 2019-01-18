/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-mbox-store.h : class for an mbox store
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
 */

#ifndef CAMEL_LOCAL_STORE_H
#define CAMEL_LOCAL_STORE_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_LOCAL_STORE \
	(camel_local_store_get_type ())
#define CAMEL_LOCAL_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_LOCAL_STORE, CamelLocalStore))
#define CAMEL_LOCAL_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_LOCAL_STORE, CamelLocalStoreClass))
#define CAMEL_IS_LOCAL_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_LOCAL_STORE))
#define CAMEL_IS_LOCAL_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_LOCAL_STORE))
#define CAMEL_LOCAL_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_LOCAL_STORE, CamelLocalStoreClass))

G_BEGIN_DECLS

typedef struct _CamelLocalStore CamelLocalStore;
typedef struct _CamelLocalStoreClass CamelLocalStoreClass;
typedef struct _CamelLocalStorePrivate CamelLocalStorePrivate;

struct _CamelLocalStore {
	CamelStore parent;
	CamelLocalStorePrivate *priv;

	gboolean is_main_store;
};

struct _CamelLocalStoreClass {
	CamelStoreClass parent_class;

	gchar *		(*get_full_path)	(CamelLocalStore *ls,
						 const gchar *full_name);
	gchar *		(*get_meta_path)	(CamelLocalStore *ls,
						 const gchar *full_name,
						 const gchar *ext);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_local_store_get_type	(void);
gboolean	camel_local_store_is_main_store	(CamelLocalStore *store);
gchar *		camel_local_store_get_full_path	(CamelLocalStore *store,
						 const gchar *full_name);
gchar *		camel_local_store_get_meta_path	(CamelLocalStore *store,
						 const gchar *full_name,
						 const gchar *ext);
guint32		camel_local_store_get_folder_type_by_full_name
						(CamelLocalStore *store,
						 const gchar *full_name);
gboolean	camel_local_store_get_need_summary_check
						(CamelLocalStore *store);
void		camel_local_store_set_need_summary_check
						(CamelLocalStore *store,
						 gboolean need_summary_check);

G_END_DECLS

#endif /* CAMEL_LOCAL_STORE_H */

