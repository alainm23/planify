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

#ifndef CAMEL_VEE_STORE_H
#define CAMEL_VEE_STORE_H

#include <camel/camel-store.h>
#include <camel/camel-vee-data-cache.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VEE_STORE \
	(camel_vee_store_get_type ())
#define CAMEL_VEE_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_STORE, CamelVeeStore))
#define CAMEL_VEE_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_STORE, CamelVeeStoreClass))
#define CAMEL_IS_VEE_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_STORE))
#define CAMEL_IS_VEE_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_STORE))
#define CAMEL_VEE_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_STORE, CamelVeeStoreClass))

G_BEGIN_DECLS

typedef struct _CamelVeeStore CamelVeeStore;
typedef struct _CamelVeeStorePrivate CamelVeeStorePrivate;
typedef struct _CamelVeeStoreClass CamelVeeStoreClass;

struct _CamelVeeStore {
	CamelStore parent;

	CamelVeeStorePrivate *priv;
};

struct _CamelVeeStoreClass {
	CamelStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType			camel_vee_store_get_type			(void);
CamelVeeStore *		camel_vee_store_new				(void);
CamelVeeDataCache *	camel_vee_store_get_vee_data_cache		(CamelVeeStore *vstore);
struct _CamelVeeFolder *camel_vee_store_get_unmatched_folder		(CamelVeeStore *vstore);
gboolean		camel_vee_store_get_unmatched_enabled		(CamelVeeStore *vstore);
void			camel_vee_store_set_unmatched_enabled		(CamelVeeStore *vstore,
									 gboolean is_enabled);
void			camel_vee_store_note_subfolder_used		(CamelVeeStore *vstore,
									 CamelFolder *subfolder,
									 struct _CamelVeeFolder *used_by);
void			camel_vee_store_note_subfolder_unused		(CamelVeeStore *vstore,
									 CamelFolder *subfolder,
									 struct _CamelVeeFolder *unused_by);
void			camel_vee_store_note_vuid_used			(CamelVeeStore *vstore,
									 CamelVeeMessageInfoData *mi_data,
									 struct _CamelVeeFolder *used_by);
void			camel_vee_store_note_vuid_unused		(CamelVeeStore *vstore,
									 CamelVeeMessageInfoData *mi_data,
									 struct _CamelVeeFolder *unused_by);
void			camel_vee_store_rebuild_unmatched_folder	(CamelVeeStore *vstore,
									 GCancellable *cancellable,
									 GError **error);

G_END_DECLS

#endif /* CAMEL_VEE_STORE_H */
