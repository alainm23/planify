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

#ifndef CAMEL_STORE_SUMMARY_H
#define CAMEL_STORE_SUMMARY_H

#include <stdio.h>

#include <camel/camel-enums.h>
#include <camel/camel-mime-parser.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STORE_SUMMARY \
	(camel_store_summary_get_type ())
#define CAMEL_STORE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STORE_SUMMARY, CamelStoreSummary))
#define CAMEL_STORE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STORE_SUMMARY, CamelStoreSummaryClass))
#define CAMEL_IS_STORE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STORE_SUMMARY))
#define CAMEL_IS_STORE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STORE_SUMMARY))
#define CAMEL_STORE_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STORE_SUMMARY, CamelStoreSummaryClass))

G_BEGIN_DECLS

struct _CamelFolderSummary;

typedef struct _CamelStoreSummary CamelStoreSummary;
typedef struct _CamelStoreSummaryClass CamelStoreSummaryClass;
typedef struct _CamelStoreSummaryPrivate CamelStoreSummaryPrivate;

typedef struct _CamelStoreInfo CamelStoreInfo;

#define CAMEL_STORE_INFO_FOLDER_UNKNOWN (~0)

enum {
	CAMEL_STORE_INFO_PATH = 0,
	CAMEL_STORE_INFO_LAST
};

struct _CamelStoreInfo {
	volatile gint refcount;
	gchar *path;
	guint32 flags;
	guint32 unread;
	guint32 total;
};

struct _CamelStoreSummary {
	GObject parent;
	CamelStoreSummaryPrivate *priv;
};

struct _CamelStoreSummaryClass {
	GObjectClass parent_class;

	/* size of memory objects */
	gsize store_info_size;

	/* load/save the global info */
	gint		(*summary_header_load)	(CamelStoreSummary *summary,
						 FILE *file);
	gint		(*summary_header_save)	(CamelStoreSummary *summary,
						 FILE *file);

	/* create/save/load an individual message info */
	CamelStoreInfo *
			(*store_info_new)	(CamelStoreSummary *summary,
						 const gchar *path);
	CamelStoreInfo *
			(*store_info_load)	(CamelStoreSummary *summary,
						 FILE *file);
	gint		(*store_info_save)	(CamelStoreSummary *summary,
						 FILE *file,
						 CamelStoreInfo *info);
	void		(*store_info_free)	(CamelStoreSummary *summary,
						 CamelStoreInfo *info);

	/* virtualise access methods */
	void		(*store_info_set_string)
						(CamelStoreSummary *summary,
						 CamelStoreInfo *info,
						 gint type,
						 const gchar *value);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_store_summary_get_type	(void) G_GNUC_CONST;
CamelStoreSummary *
		camel_store_summary_new		(void);
void		camel_store_summary_set_filename
						(CamelStoreSummary *summary,
						 const gchar *filename);

/* load/save the summary in its entirety */
gint		camel_store_summary_load	(CamelStoreSummary *summary);
gint		camel_store_summary_save	(CamelStoreSummary *summary);

/* set the dirty bit on the summary */
void		camel_store_summary_touch	(CamelStoreSummary *summary);

/* add a new raw summary item */
void		camel_store_summary_add		(CamelStoreSummary *summary,
						 CamelStoreInfo *info);

/* build/add raw summary items */
CamelStoreInfo *
		camel_store_summary_add_from_path
						(CamelStoreSummary *summary,
						 const gchar *path);

/* Just build raw summary items */
CamelStoreInfo *
		camel_store_summary_info_new	(CamelStoreSummary *summary);
CamelStoreInfo *
		camel_store_summary_info_ref	(CamelStoreSummary *summary,
						 CamelStoreInfo *info);
void		camel_store_summary_info_unref	(CamelStoreSummary *summary,
						 CamelStoreInfo *info);

/* removes a summary item */
void		camel_store_summary_remove	(CamelStoreSummary *summary,
						 CamelStoreInfo *info);
void		camel_store_summary_remove_path	(CamelStoreSummary *summary,
						 const gchar *path);

/* lookup functions */
gint		camel_store_summary_count	(CamelStoreSummary *summary);
CamelStoreInfo *
		camel_store_summary_path	(CamelStoreSummary *summary,
						 const gchar *path);
GPtrArray *	camel_store_summary_array	(CamelStoreSummary *summary);
void		camel_store_summary_array_free	(CamelStoreSummary *summary,
						 GPtrArray *array);

void		camel_store_info_set_string	(CamelStoreSummary *summary,
						 CamelStoreInfo *info,
						 gint type,
						 const gchar *value);

const gchar *	camel_store_info_path		(CamelStoreSummary *summary,
						 CamelStoreInfo *info);
const gchar *	camel_store_info_name		(CamelStoreSummary *summary,
						 CamelStoreInfo *info);
void		camel_store_summary_sort	(CamelStoreSummary *summary,
						 GCompareDataFunc compare_func,
						 gpointer user_data);

gboolean	camel_store_summary_connect_folder_summary
						(CamelStoreSummary *summary,
						 const gchar *path,
						 CamelFolderSummary *folder_summary);
gboolean	camel_store_summary_disconnect_folder_summary
						(CamelStoreSummary *summary,
						 CamelFolderSummary *folder_summary);

G_END_DECLS

#endif /* CAMEL_STORE_SUMMARY_H */
