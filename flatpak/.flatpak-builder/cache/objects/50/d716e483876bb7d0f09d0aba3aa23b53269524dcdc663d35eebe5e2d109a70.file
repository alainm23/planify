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

#ifndef CAMEL_VEE_FOLDER_H
#define CAMEL_VEE_FOLDER_H

#include <camel/camel-folder.h>
#include <camel/camel-folder-search.h>
#include <camel/camel-store.h>
#include <camel/camel-vee-summary.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VEE_FOLDER \
	(camel_vee_folder_get_type ())
#define CAMEL_VEE_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_FOLDER, CamelVeeFolder))
#define CAMEL_VEE_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_FOLDER, CamelVeeFolderClass))
#define CAMEL_IS_VEE_FOLDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_FOLDER))
#define CAMEL_IS_VEE_FOLDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_FOLDER))
#define CAMEL_VEE_FOLDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_FOLDER, CamelVeeFolderClass))

G_BEGIN_DECLS

typedef struct _CamelVeeFolder CamelVeeFolder;
typedef struct _CamelVeeFolderClass CamelVeeFolderClass;
typedef struct _CamelVeeFolderPrivate CamelVeeFolderPrivate;

struct _CamelVeeFolder {
	CamelFolder parent;
	CamelVeeFolderPrivate *priv;
};

struct _CamelVeeFolderClass {
	CamelFolderClass parent_class;

	/* TODO: Some of this may need some additional work/thinking through, it works for now*/

	void		(*add_folder)		(CamelVeeFolder *vfolder,
						 CamelFolder *subfolder,
						 GCancellable *cancellable);
	void		(*remove_folder)	(CamelVeeFolder *vfolder,
						 CamelFolder *subfolder,
						 GCancellable *cancellable);
	void		(*rebuild_folder)	(CamelVeeFolder *vfolder,
						 CamelFolder *subfolder,
						 GCancellable *cancellable);

	void		(*set_expression)	(CamelVeeFolder *vfolder,
						 const gchar *expression);

	/* Called for a folder-changed event on a source folder */
	void		(*folder_changed)	(CamelVeeFolder *vfolder,
						 CamelFolder *subfolder,
						 CamelFolderChangeInfo *changes);

	/* Padding for future expansion */
	gpointer reserved[20];
};

#define CAMEL_UNMATCHED_NAME "UNMATCHED"

GType		camel_vee_folder_get_type		(void);
CamelFolder *	camel_vee_folder_new			(CamelStore *parent_store,
							 const gchar *full,
							 guint32 flags);
void		camel_vee_folder_construct		(CamelVeeFolder *vf,
							 guint32 flags);
guint32		camel_vee_folder_get_flags		(CamelVeeFolder *vf);
CamelFolder *	camel_vee_folder_get_location		(CamelVeeFolder *vf,
							 const CamelVeeMessageInfo *vinfo,
							 gchar **realuid);
CamelFolder *	camel_vee_folder_get_vee_uid_folder	(CamelVeeFolder *vfolder,
							 const gchar *vee_message_uid);
void		camel_vee_folder_set_auto_update	(CamelVeeFolder *vfolder,
							 gboolean auto_update);
gboolean	camel_vee_folder_get_auto_update	(CamelVeeFolder *vfolder);
void		camel_vee_folder_add_folder		(CamelVeeFolder *vfolder,
							 CamelFolder *subfolder,
							 GCancellable *cancellable);
void		camel_vee_folder_remove_folder		(CamelVeeFolder *vfolder,
							 CamelFolder *subfolder,
							 GCancellable *cancellable);
void		camel_vee_folder_set_folders		(CamelVeeFolder *vfolder,
							 GList *folders,
							 GCancellable *cancellable);
GList *		camel_vee_folder_ref_folders		(CamelVeeFolder *vfolder);
void		camel_vee_folder_add_vuid		(CamelVeeFolder *vfolder,
							 struct _CamelVeeMessageInfoData *mi_data,
							 CamelFolderChangeInfo *changes);
void		camel_vee_folder_remove_vuid		(CamelVeeFolder *vfolder,
							 struct _CamelVeeMessageInfoData *mi_data,
							 CamelFolderChangeInfo *changes);

void		camel_vee_folder_rebuild_folder		(CamelVeeFolder *vfolder,
							 CamelFolder *subfolder,
							 GCancellable *cancellable);
void		camel_vee_folder_set_expression		(CamelVeeFolder *vfolder,
							 const gchar *expression);
const gchar *	camel_vee_folder_get_expression		(CamelVeeFolder *vfolder);

void		camel_vee_folder_ignore_next_changed_event
							(CamelVeeFolder *vfolder,
							 CamelFolder *subfolder);
void		camel_vee_folder_remove_from_ignore_changed_event
							(CamelVeeFolder *vfolder,
							 CamelFolder *subfolder);

G_END_DECLS

#endif /* CAMEL_VEE_FOLDER_H */
