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

#ifndef CAMEL_MBOX_FOLDER_H
#define CAMEL_MBOX_FOLDER_H

#include "camel-local-folder.h"
#include "camel-mbox-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MBOX_FOLDER \
	(camel_mbox_folder_get_type ())
#define CAMEL_MBOX_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MBOX_FOLDER, CamelMboxFolder))
#define CAMEL_MBOX_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MBOX_FOLDER, CamelMboxFolderClass))
#define CAMEL_IS_MBOX_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MBOX_FOLDER))
#define CAMEL_IS_MBOX_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MBOX_FOLDER))
#define CAMEL_MBOX_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MBOX_FOLDER, CamelMboxFolderClass))

G_BEGIN_DECLS

typedef struct _CamelMboxFolder CamelMboxFolder;
typedef struct _CamelMboxFolderClass CamelMboxFolderClass;

struct _CamelMboxFolder {
	CamelLocalFolder parent;

	gint lockfd;		/* for when we have a lock on the folder */
};

struct _CamelMboxFolderClass {
	CamelLocalFolderClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mbox_folder_get_type	(void);
CamelFolder *	camel_mbox_folder_new		(CamelStore *parent_store,
						 const gchar *full_name,
						 guint32 flags,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_MBOX_FOLDER_H */
