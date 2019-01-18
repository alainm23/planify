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
 * Authors: Jeffrey Stedfast <fejj@novell.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_OFFLINE_FOLDER_H
#define CAMEL_OFFLINE_FOLDER_H

#include <camel/camel-enums.h>
#include <camel/camel-folder.h>

/* Standard GObject macros */
#define CAMEL_TYPE_OFFLINE_FOLDER \
	(camel_offline_folder_get_type ())
#define CAMEL_OFFLINE_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_OFFLINE_FOLDER, CamelOfflineFolder))
#define CAMEL_OFFLINE_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_OFFLINE_FOLDER, CamelOfflineFolderClass))
#define CAMEL_IS_OFFLINE_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_OFFLINE_FOLDER))
#define CAMEL_IS_OFFLINE_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_OFFLINE_FOLDER))
#define CAMEL_OFFLINE_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_OFFLINE_FOLDER, CamelOfflineFolderClass))

G_BEGIN_DECLS

typedef struct _CamelOfflineFolder CamelOfflineFolder;
typedef struct _CamelOfflineFolderClass CamelOfflineFolderClass;
typedef struct _CamelOfflineFolderPrivate CamelOfflineFolderPrivate;

struct _CamelOfflineFolder {
	CamelFolder parent;
	CamelOfflineFolderPrivate *priv;
};

struct _CamelOfflineFolderClass {
	CamelFolderClass parent_class;

	/* Synchronous I/O Methods */
	gboolean	(*downsync_sync)	(CamelOfflineFolder *folder,
						 const gchar *expression,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_offline_folder_get_type	(void);
CamelThreeState	camel_offline_folder_get_offline_sync
						(CamelOfflineFolder *folder);
void		camel_offline_folder_set_offline_sync
						(CamelOfflineFolder *folder,
						 CamelThreeState offline_sync);
gboolean	camel_offline_folder_can_downsync
						(CamelOfflineFolder *folder);
gboolean	camel_offline_folder_downsync_sync
						(CamelOfflineFolder *folder,
						 const gchar *expression,
						 GCancellable *cancellable,
						 GError **error);
void		camel_offline_folder_downsync	(CamelOfflineFolder *folder,
						 const gchar *expression,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_offline_folder_downsync_finish
						(CamelOfflineFolder *folder,
						 GAsyncResult *result,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_OFFLINE_FOLDER_H */
