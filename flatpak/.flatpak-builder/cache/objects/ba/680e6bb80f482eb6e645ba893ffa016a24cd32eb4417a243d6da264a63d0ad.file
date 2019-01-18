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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_VTRASH_FOLDER_H
#define CAMEL_VTRASH_FOLDER_H

#include <camel/camel-folder.h>
#include <camel/camel-vee-folder.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VTRASH_FOLDER \
	(camel_vtrash_folder_get_type ())
#define CAMEL_VTRASH_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VTRASH_FOLDER, CamelVTrashFolder))
#define CAMEL_VTRASH_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VTRASH_FOLDER, CamelVTrashFolderClass))
#define CAMEL_IS_VTRASH_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VTRASH_FOLDER))
#define CAMEL_IS_VTRASH_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VTRASH_FOLDER))
#define CAMEL_VTRASH_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VTRASH_FOLDER, CamelVTrashFolderClass))

#define CAMEL_VTRASH_NAME	".#evolution/Trash"
#define CAMEL_VJUNK_NAME	".#evolution/Junk"

G_BEGIN_DECLS

typedef struct _CamelVTrashFolder CamelVTrashFolder;
typedef struct _CamelVTrashFolderClass CamelVTrashFolderClass;
typedef struct _CamelVTrashFolderPrivate CamelVTrashFolderPrivate;

typedef enum {
	CAMEL_VTRASH_FOLDER_TRASH,
	CAMEL_VTRASH_FOLDER_JUNK,
	CAMEL_VTRASH_FOLDER_LAST
} CamelVTrashFolderType;

struct _CamelVTrashFolder {
	CamelVeeFolder parent;
	CamelVTrashFolderPrivate *priv;
};

struct _CamelVTrashFolderClass {
	CamelVeeFolderClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vtrash_folder_get_type	(void);
CamelFolder *	camel_vtrash_folder_new		(CamelStore *parent_store,
						 CamelVTrashFolderType type);
CamelVTrashFolderType
		camel_vtrash_folder_get_folder_type
						(CamelVTrashFolder *vtrash_folder);

G_END_DECLS

#endif /* CAMEL_VTRASH_FOLDER_H */
