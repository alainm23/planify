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

#ifndef CAMEL_MAILDIR_FOLDER_H
#define CAMEL_MAILDIR_FOLDER_H

#include "camel-local-folder.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MAILDIR_FOLDER \
	(camel_maildir_folder_get_type ())
#define CAMEL_MAILDIR_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MAILDIR_FOLDER, CamelMaildirFolder))
#define CAMEL_MAILDIR_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MAILDIR_FOLDER, CamelMaildirFolderClass))
#define CAMEL_IS_MAILDIR_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MAILDIR_FOLDER))
#define CAMEL_IS_MAILDIR_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MAILDIR_FOLDER))
#define CAMEL_MAILDIR_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MAILDIR_FOLDER, CamelMaildirFolderClass))

G_BEGIN_DECLS

typedef struct _CamelMaildirFolder CamelMaildirFolder;
typedef struct _CamelMaildirFolderClass CamelMaildirFolderClass;

struct _CamelMaildirFolder {
	CamelLocalFolder parent;
};

struct _CamelMaildirFolderClass {
	CamelLocalFolderClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_maildir_folder_get_type	(void);
CamelFolder *	camel_maildir_folder_new	(CamelStore *parent_store,
						 const gchar *full_name,
						 guint32 flags,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_MAILDIR_FOLDER_H */
