/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-pop3-folder.h : Class for a POP3 folder
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

#ifndef CAMEL_POP3_FOLDER_H
#define CAMEL_POP3_FOLDER_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_POP3_FOLDER \
	(camel_pop3_folder_get_type ())
#define CAMEL_POP3_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_POP3_FOLDER, CamelPOP3Folder))
#define CAMEL_POP3_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_POP3_FOLDER, CamelPOP3FolderClass))
#define CAMEL_IS_POP3_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_POP3_FOLDER))
#define CAMEL_IS_POP3_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_POP3_FOLDER))
#define CAMEL_POP3_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_POP3_FOLDER, CamelPOP3FolderClass))

G_BEGIN_DECLS

typedef struct _CamelPOP3Folder CamelPOP3Folder;
typedef struct _CamelPOP3FolderClass CamelPOP3FolderClass;

struct _CamelPOP3Folder {
	CamelFolder parent;

	GPtrArray *uids;

	/* messageinfo uid to CamelPOP3FolderInfo *,
	 * which is stored in uids array */
	GHashTable *uids_fi;

	/* messageinfo by id */
	GHashTable *uids_id;

	GKeyFile *key_file;
	gint fetch_more;
	CamelFetchType fetch_type;
	gint first_id;
	gint latest_id;
};

struct _CamelPOP3FolderClass {
	CamelFolderClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_pop3_folder_get_type	(void);
CamelFolder *	camel_pop3_folder_new		(CamelStore *parent,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_pop3_folder_delete_old	(CamelFolder *folder,
						 gint days_to_delete,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_POP3_FOLDER_H */
