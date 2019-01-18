/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-nntp-folder.h : NNTP group (folder) support.
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
 * Authors: Chris Toshok <toshok@ximian.com>
 */

#ifndef CAMEL_NNTP_FOLDER_H
#define CAMEL_NNTP_FOLDER_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_NNTP_FOLDER \
	(camel_nntp_folder_get_type ())
#define CAMEL_NNTP_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NNTP_FOLDER, CamelNNTPFolder))
#define CAMEL_NNTP_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NNTP_FOLDER, CamelNNTPFolderClass))
#define CAMEL_IS_NNTP_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NNTP_FOLDER))
#define CAMEL_IS_NNTP_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NNTP_FOLDER))
#define CAMEL_NNTP_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_NNTP_FOLDER, CamelNNTPFolderClass))

G_BEGIN_DECLS

typedef struct _CamelNNTPFolder CamelNNTPFolder;
typedef struct _CamelNNTPFolderClass CamelNNTPFolderClass;
typedef struct _CamelNNTPFolderPrivate CamelNNTPFolderPrivate;

struct _CamelNNTPFolder {
	CamelOfflineFolder parent;
	CamelNNTPFolderPrivate *priv;

	struct _CamelFolderChangeInfo *changes;
	CamelFolderSearch *search;
};

struct _CamelNNTPFolderClass {
	CamelOfflineFolderClass parent;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_nntp_folder_get_type	(void);
CamelFolder *	camel_nntp_folder_new		(CamelStore *parent,
						 const gchar *folder_name,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_nntp_folder_selected	(CamelNNTPFolder *folder,
						 gchar *line,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_NNTP_FOLDER_H */
