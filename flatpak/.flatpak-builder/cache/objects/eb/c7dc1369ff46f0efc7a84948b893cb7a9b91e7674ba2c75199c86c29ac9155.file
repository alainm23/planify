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

#ifndef CAMEL_FOLDER_SUMMARY_H
#define CAMEL_FOLDER_SUMMARY_H

#include <stdio.h>
#include <time.h>

#include <camel/camel-index.h>
#include <camel/camel-message-info.h>
#include <camel/camel-mime-message.h>
#include <camel/camel-mime-parser.h>

/* Standard GObject macros */
#define CAMEL_TYPE_FOLDER_SUMMARY \
	(camel_folder_summary_get_type ())
#define CAMEL_FOLDER_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_FOLDER_SUMMARY, CamelFolderSummary))
#define CAMEL_FOLDER_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_FOLDER_SUMMARY, CamelFolderSummaryClass))
#define CAMEL_IS_FOLDER_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_FOLDER_SUMMARY))
#define CAMEL_IS_FOLDER_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_FOLDER_SUMMARY))
#define CAMEL_FOLDER_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_FOLDER_SUMMARY, CamelFolderSummaryClass))

G_BEGIN_DECLS

struct _CamelFolder;
struct _CamelStore;

typedef struct _CamelFolderSummary CamelFolderSummary;
typedef struct _CamelFolderSummaryClass CamelFolderSummaryClass;
typedef struct _CamelFolderSummaryPrivate CamelFolderSummaryPrivate;

/**
 * CamelFolderSummaryFlags:
 * @CAMEL_FOLDER_SUMMARY_DIRTY:
 *    There are changes in summary, which should be saved.
 * @CAMEL_FOLDER_SUMMARY_IN_MEMORY_ONLY:
 *    Summary with this flag doesn't use DB for storing its content,
 *    it is always created on the fly.
 **/
typedef enum {
	CAMEL_FOLDER_SUMMARY_DIRTY = 1 << 0,
	CAMEL_FOLDER_SUMMARY_IN_MEMORY_ONLY = 1 << 1
} CamelFolderSummaryFlags;

struct _CamelFolderSummary {
	GObject parent;
	CamelFolderSummaryPrivate *priv;
};

struct _CamelMIRecord;
struct _CamelFIRecord;

struct _CamelFolderSummaryClass {
	GObjectClass parent_class;

	GType message_info_type;
	const gchar *collate;
	const gchar *sort_by;

	/* Load/Save folder summary*/
	gboolean	(*summary_header_load)
					(CamelFolderSummary *summary,
					 struct _CamelFIRecord *fir);
	struct _CamelFIRecord *
			(*summary_header_save)
					(CamelFolderSummary *summary,
					 GError **error);

	/* create an individual message info */
	CamelMessageInfo *
			(*message_info_new_from_headers)
					(CamelFolderSummary *summary,
					 const CamelNameValueArray *headers);
	CamelMessageInfo *
			(*message_info_new_from_parser)
					(CamelFolderSummary *summary,
					 CamelMimeParser *parser);
	CamelMessageInfo *
			(*message_info_new_from_message)
					(CamelFolderSummary *summary,
					 CamelMimeMessage *message);

	CamelMessageInfo *
			(*message_info_from_uid)
					(CamelFolderSummary *summary,
					 const gchar *uid);

	/* get the next uid */
	gchar *		(*next_uid_string)
					(CamelFolderSummary *summary);

	void		(* prepare_fetch_all)
					(CamelFolderSummary *summary);

	/* Padding for future expansion */
	gpointer reserved[19];
};

GType		camel_folder_summary_get_type	(void);
CamelFolderSummary *
		camel_folder_summary_new	(struct _CamelFolder *folder);

struct _CamelFolder *
		camel_folder_summary_get_folder	(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_flags	(CamelFolderSummary *summary);
void		camel_folder_summary_set_flags	(CamelFolderSummary *summary,
						 guint32 flags);
gint64		camel_folder_summary_get_timestamp
						(CamelFolderSummary *summary);
void		camel_folder_summary_set_timestamp
						(CamelFolderSummary *summary,
						 gint64 timestamp);
guint32		camel_folder_summary_get_version
						(CamelFolderSummary *summary);
void		camel_folder_summary_set_version
						(CamelFolderSummary *summary,
						 guint32 version);
guint32		camel_folder_summary_get_saved_count
						(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_unread_count
						(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_deleted_count
						(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_junk_count
						(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_junk_not_deleted_count
						(CamelFolderSummary *summary);
guint32		camel_folder_summary_get_visible_count
						(CamelFolderSummary *summary);

void		camel_folder_summary_set_index	(CamelFolderSummary *summary,
						 CamelIndex *index);
CamelIndex *	camel_folder_summary_get_index	(CamelFolderSummary *summary);
guint32		camel_folder_summary_next_uid	(CamelFolderSummary *summary);
void		camel_folder_summary_set_next_uid
						(CamelFolderSummary *summary,
						 guint32 uid);
guint32		camel_folder_summary_get_next_uid
						(CamelFolderSummary *summary);
gchar *		camel_folder_summary_next_uid_string
						(CamelFolderSummary *summary);

/* load/save the full summary */
gboolean	camel_folder_summary_save	(CamelFolderSummary *summary,
						 GError **error);
gboolean	camel_folder_summary_load	(CamelFolderSummary *summary,
						 GError **error);

/* only load the header */
gboolean	camel_folder_summary_header_load
						(CamelFolderSummary *summary,
						 struct _CamelStore *store,
						 const gchar *folder_name,
						 GError **error);
gboolean	camel_folder_summary_header_save
						(CamelFolderSummary *summary,
						 GError **error);

/* set the dirty bit on the summary */
void		camel_folder_summary_touch	(CamelFolderSummary *summary);

/* Just build raw summary items */
CamelMessageInfo *
		camel_folder_summary_info_new_from_headers
						(CamelFolderSummary *summary,
						 const CamelNameValueArray *headers);
CamelMessageInfo *
		camel_folder_summary_info_new_from_parser
						(CamelFolderSummary *summary,
						 CamelMimeParser *parser);
CamelMessageInfo *
		camel_folder_summary_info_new_from_message
						(CamelFolderSummary *summary,
						 CamelMimeMessage *message);

/* add a new raw summary item */
void		camel_folder_summary_add	(CamelFolderSummary *summary,
						 CamelMessageInfo *info,
						 gboolean force_keep_uid);

gboolean	camel_folder_summary_remove	(CamelFolderSummary *summary,
						 CamelMessageInfo *info);

gboolean	camel_folder_summary_remove_uid	(CamelFolderSummary *summary,
						 const gchar *uid);
gboolean	camel_folder_summary_remove_uids
						(CamelFolderSummary *summary,
						 GList *uids);

/* remove all items */
gboolean	camel_folder_summary_clear	(CamelFolderSummary *summary,
						 GError **error);

/* lookup functions */
guint		camel_folder_summary_count	(CamelFolderSummary *summary);

gboolean	camel_folder_summary_check_uid	(CamelFolderSummary *summary,
						 const gchar *uid);
CamelMessageInfo *
		camel_folder_summary_get	(CamelFolderSummary *summary,
						 const gchar *uid);
guint32		camel_folder_summary_get_info_flags
						(CamelFolderSummary *summary,
						 const gchar *uid);
GPtrArray *	camel_folder_summary_get_array	(CamelFolderSummary *summary);
void		camel_folder_summary_free_array	(GPtrArray *array);

GHashTable *	camel_folder_summary_get_hash	(CamelFolderSummary *summary);

gboolean	camel_folder_summary_replace_flags
						(CamelFolderSummary *summary,
						 CamelMessageInfo *info);

/* Peek from mem only */
CamelMessageInfo *
		camel_folder_summary_peek_loaded
						(CamelFolderSummary *summary,
						 const gchar *uid);

/* Get only the uids of dirty/changed things to sync to server/db */
GPtrArray *	camel_folder_summary_get_changed
						(CamelFolderSummary *summary);

/* reload the summary at any required point if required */
void		camel_folder_summary_prepare_fetch_all
						(CamelFolderSummary *summary,
						 GError **error);

/* summary locking */
void		camel_folder_summary_lock	(CamelFolderSummary *summary);
void		camel_folder_summary_unlock	(CamelFolderSummary *summary);

CamelMessageFlags
		camel_system_flag		(const gchar *name);
gboolean	camel_system_flag_get		(CamelMessageFlags flags,
						 const gchar *name);

CamelMessageInfo *
		camel_message_info_new_from_headers
						(CamelFolderSummary *summary,
						 const CamelNameValueArray *headers);
G_END_DECLS

#endif /* CAMEL_FOLDER_SUMMARY_H */
