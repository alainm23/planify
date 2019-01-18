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

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-db.h"
#include "camel-debug.h"
#include "camel-file-utils.h"
#include "camel-folder-summary.h"
#include "camel-folder.h"
#include "camel-iconv.h"
#include "camel-message-info.h"
#include "camel-message-info-base.h"
#include "camel-mime-filter-basic.h"
#include "camel-mime-filter-charset.h"
#include "camel-mime-filter-html.h"
#include "camel-mime-filter-index.h"
#include "camel-mime-filter.h"
#include "camel-mime-message.h"
#include "camel-multipart.h"
#include "camel-session.h"
#include "camel-stream-filter.h"
#include "camel-stream-mem.h"
#include "camel-stream-null.h"
#include "camel-string-utils.h"
#include "camel-store.h"
#include "camel-vee-folder.h"
#include "camel-vtrash-folder.h"
#include "camel-mime-part-utils.h"

/* Make 5 minutes as default cache drop */
#define SUMMARY_CACHE_DROP 300
#define dd(x) if (camel_debug("sync")) x

struct _CamelFolderSummaryPrivate {
	/* header info */
	guint32 version;	/* version of file loaded/loading */
	gint64 timestamp;	/* timestamp for this summary (for implementors to use) */
	CamelFolderSummaryFlags flags;

	GHashTable *filter_charset;	/* CamelMimeFilterCharset's indexed by source charset */

	struct _CamelMimeFilter *filter_index;
	struct _CamelMimeFilter *filter_64;
	struct _CamelMimeFilter *filter_qp;
	struct _CamelMimeFilter *filter_uu;
	struct _CamelMimeFilter *filter_save;
	struct _CamelMimeFilter *filter_html;

	struct _CamelStream *filter_stream;

	struct _CamelIndex *index;

	GRecMutex summary_lock;	/* for the summary hashtable/array */
	GRecMutex filter_lock;	/* for accessing any of the filtering/indexing stuff, since we share them */

	guint32 nextuid;	/* next uid? */
	guint32 saved_count;	/* how many were saved/loaded */
	guint32 unread_count;	/* handy totals */
	guint32 deleted_count;
	guint32 junk_count;
	guint32 junk_not_deleted_count;
	guint32 visible_count;

	GHashTable *uids; /* uids of all known message infos; the 'value' are used flags for the message info */
	GHashTable *loaded_infos; /* uid->CamelMessageInfo *, those currently in memory */

	struct _CamelFolder *folder; /* parent folder, for events */
	time_t cache_load_time;
	guint timeout_handle;
};

/* this should probably be conditional on it existing */
#define USE_BSEARCH

#define d(x)
#define io(x)			/* io debug */
#define w(x)

#define CAMEL_FOLDER_SUMMARY_VERSION (14)

/* trivial lists, just because ... */
struct _node {
	struct _node *next;
};

static void cfs_schedule_info_release_timer (CamelFolderSummary *summary);

static void summary_traverse_content_with_parser (CamelFolderSummary *summary, CamelMessageInfo *msginfo, CamelMimeParser *mp);
static void summary_traverse_content_with_part (CamelFolderSummary *summary, CamelMessageInfo *msginfo, CamelMimePart *object);

static CamelMessageInfo * message_info_new_from_headers (CamelFolderSummary *, const CamelNameValueArray *);
static CamelMessageInfo * message_info_new_from_parser (CamelFolderSummary *, CamelMimeParser *);
static CamelMessageInfo * message_info_new_from_message (CamelFolderSummary *summary, CamelMimeMessage *msg);

static gint save_message_infos_to_db (CamelFolderSummary *summary, GError **error);
static gint camel_read_mir_callback (gpointer  ref, gint ncol, gchar ** cols, gchar ** name);

static gchar *next_uid_string (CamelFolderSummary *summary);

static CamelMessageInfo * message_info_from_uid (CamelFolderSummary *summary, const gchar *uid);

enum {
	PROP_0,
	PROP_FOLDER,
	PROP_SAVED_COUNT,
	PROP_UNREAD_COUNT,
	PROP_DELETED_COUNT,
	PROP_JUNK_COUNT,
	PROP_JUNK_NOT_DELETED_COUNT,
	PROP_VISIBLE_COUNT
};

enum {
	PREPARE_FETCH_ALL,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (CamelFolderSummary, camel_folder_summary, G_TYPE_OBJECT)

/* Private function */
void _camel_message_info_unset_summary (CamelMessageInfo *mi);

static gboolean
remove_each_item (gpointer uid,
                  gpointer mi,
                  gpointer user_data)
{
	GSList **to_remove_infos = user_data;

	*to_remove_infos = g_slist_prepend (*to_remove_infos, mi);

	return TRUE;
}

static void
remove_all_loaded (CamelFolderSummary *summary)
{
	GSList *to_remove_infos = NULL, *link;

	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	camel_folder_summary_lock (summary);

	g_hash_table_foreach_remove (summary->priv->loaded_infos, remove_each_item, &to_remove_infos);

	for (link = to_remove_infos; link; link = g_slist_next (link)) {
		CamelMessageInfo *mi = link->data;

		/* Dirty hack, to have CamelWeakRefGroup properly cleared,
		   when the message info leaks due to ref/unref imbalance. */
		_camel_message_info_unset_summary (mi);
	}

	g_slist_free_full (to_remove_infos, g_object_unref);

	camel_folder_summary_unlock (summary);
}

static void
free_o_name (gpointer key,
             gpointer value,
             gpointer data)
{
	g_object_unref (value);
	g_free (key);
}

static void
folder_summary_dispose (GObject *object)
{
	CamelFolderSummary *summary = CAMEL_FOLDER_SUMMARY (object);

	if (summary->priv->timeout_handle) {
		/* this should not happen, because the release timer
		 * holds a reference on object */
		g_source_remove (summary->priv->timeout_handle);
		summary->priv->timeout_handle = 0;
	}

	g_clear_object (&summary->priv->filter_index);
	g_clear_object (&summary->priv->filter_64);
	g_clear_object (&summary->priv->filter_qp);
	g_clear_object (&summary->priv->filter_uu);
	g_clear_object (&summary->priv->filter_save);
	g_clear_object (&summary->priv->filter_html);
	g_clear_object (&summary->priv->filter_stream);
	g_clear_object (&summary->priv->filter_index);

	if (summary->priv->folder) {
		g_object_weak_unref (G_OBJECT (summary->priv->folder), (GWeakNotify) g_nullify_pointer, &summary->priv->folder);
		summary->priv->folder = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_folder_summary_parent_class)->dispose (object);
}

static void
folder_summary_finalize (GObject *object)
{
	CamelFolderSummary *summary = CAMEL_FOLDER_SUMMARY (object);

	g_hash_table_destroy (summary->priv->uids);
	remove_all_loaded (summary);
	g_hash_table_destroy (summary->priv->loaded_infos);

	g_hash_table_foreach (summary->priv->filter_charset, free_o_name, NULL);
	g_hash_table_destroy (summary->priv->filter_charset);

	g_rec_mutex_clear (&summary->priv->summary_lock);
	g_rec_mutex_clear (&summary->priv->filter_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_folder_summary_parent_class)->finalize (object);
}

static void
folder_summary_set_folder (CamelFolderSummary *summary,
                           CamelFolder *folder)
{
	g_return_if_fail (summary->priv->folder == NULL);
	/* folder can be NULL in certain cases, see maildir-store */

	summary->priv->folder = folder;
	if (folder)
		g_object_weak_ref (G_OBJECT (folder), (GWeakNotify) g_nullify_pointer, &summary->priv->folder);
}

static void
folder_summary_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FOLDER:
			folder_summary_set_folder (
				CAMEL_FOLDER_SUMMARY (object),
				CAMEL_FOLDER (g_value_get_object (value)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
folder_summary_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FOLDER:
			g_value_set_object (
				value,
				camel_folder_summary_get_folder (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_SAVED_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_saved_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_UNREAD_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_unread_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_DELETED_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_deleted_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_JUNK_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_junk_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_JUNK_NOT_DELETED_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_junk_not_deleted_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;

		case PROP_VISIBLE_COUNT:
			g_value_set_uint (
				value,
				camel_folder_summary_get_visible_count (
				CAMEL_FOLDER_SUMMARY (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static gboolean
is_in_memory_summary (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	return (summary->priv->flags & CAMEL_FOLDER_SUMMARY_IN_MEMORY_ONLY) != 0;
}

#define UPDATE_COUNTS_ADD		(1)
#define UPDATE_COUNTS_SUB		(2)
#define UPDATE_COUNTS_ADD_WITHOUT_TOTAL (3)
#define UPDATE_COUNTS_SUB_WITHOUT_TOTAL (4)

static gboolean
folder_summary_update_counts_by_flags (CamelFolderSummary *summary,
                                       guint32 flags,
                                       gint op_type)
{
	gint unread = 0, deleted = 0, junk = 0;
	gboolean is_junk_folder = FALSE, is_trash_folder = FALSE;
	gboolean subtract = op_type == UPDATE_COUNTS_SUB || op_type == UPDATE_COUNTS_SUB_WITHOUT_TOTAL;
	gboolean without_total = op_type == UPDATE_COUNTS_ADD_WITHOUT_TOTAL || op_type == UPDATE_COUNTS_SUB_WITHOUT_TOTAL;
	gboolean changed = FALSE;
	GObject *summary_object;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	summary_object = G_OBJECT (summary);

	if (summary->priv->folder && CAMEL_IS_VTRASH_FOLDER (summary->priv->folder)) {
		CamelVTrashFolder *vtrash = CAMEL_VTRASH_FOLDER (summary->priv->folder);

		is_junk_folder = vtrash && camel_vtrash_folder_get_folder_type (vtrash) == CAMEL_VTRASH_FOLDER_JUNK;
		is_trash_folder = vtrash && camel_vtrash_folder_get_folder_type (vtrash) == CAMEL_VTRASH_FOLDER_TRASH;
	} else if (summary->priv->folder) {
		guint32 folder_flags;

		folder_flags = camel_folder_get_flags (summary->priv->folder);

		is_junk_folder = (folder_flags & CAMEL_FOLDER_IS_JUNK) != 0;
		is_trash_folder = (folder_flags & CAMEL_FOLDER_IS_TRASH) != 0;
	}

	if (!(flags & CAMEL_MESSAGE_SEEN))
		unread = subtract ? -1 : 1;

	if (flags & CAMEL_MESSAGE_DELETED)
		deleted = subtract ? -1 : 1;

	if (flags & CAMEL_MESSAGE_JUNK)
		junk = subtract ? -1 : 1;

	dd (printf ("%p: %d %d %d | %d %d %d \n", (gpointer) summary, unread, deleted, junk, summary->priv->unread_count, summary->priv->visible_count, summary->priv->saved_count));

	g_object_freeze_notify (summary_object);

	if (deleted) {
		summary->priv->deleted_count += deleted;
		g_object_notify (summary_object, "deleted-count");
		changed = TRUE;
	}

	if (junk) {
		summary->priv->junk_count += junk;
		g_object_notify (summary_object, "junk-count");
		changed = TRUE;
	}

	if (junk && !deleted) {
		summary->priv->junk_not_deleted_count += junk;
		g_object_notify (summary_object, "junk-not-deleted-count");
		changed = TRUE;
	}

	if (!junk && !deleted) {
		summary->priv->visible_count += subtract ? -1 : 1;
		g_object_notify (summary_object, "visible-count");
		changed = TRUE;
	}

	if (junk && !is_junk_folder)
		unread = 0;
	if (deleted && !is_trash_folder)
		unread = 0;

	if (unread) {
		if (unread > 0 || summary->priv->unread_count)
			summary->priv->unread_count += unread;

		g_object_notify (summary_object, "unread-count");
		changed = TRUE;
	}

	if (!without_total) {
		summary->priv->saved_count += subtract ? -1 : 1;
		g_object_notify (summary_object, "saved-count");
		changed = TRUE;
	}

	if (changed)
		camel_folder_summary_touch (summary);

	g_object_thaw_notify (summary_object);

	dd (printf ("%p: %d %d %d | %d %d %d\n", (gpointer) summary, unread, deleted, junk, summary->priv->unread_count, summary->priv->visible_count, summary->priv->saved_count));

	return changed;
}

static gboolean
summary_header_load (CamelFolderSummary *summary,
		     CamelFIRecord *record)
{
	io (printf ("Loading header from db \n"));

	summary->priv->version = record->version;

	/* We may not worry, as we are setting a new standard here */
#if 0
	/* Legacy version check, before version 12 we have no upgrade knowledge */
	if ((summary->priv->version > 0xff) && (summary->priv->version & 0xff) < 12) {
		io (printf ("Summary header version mismatch"));
		errno = EINVAL;
		return FALSE;
	}

	if (!(summary->priv->version < 0x100 && summary->priv->version >= 13))
		io (printf ("Loading legacy summary\n"));
	else
		io (printf ("loading new-format summary\n"));
#endif

	summary->priv->flags = record->flags;
	summary->priv->nextuid = record->nextuid;
	summary->priv->timestamp = record->timestamp;
	summary->priv->saved_count = record->saved_count;

	summary->priv->unread_count = record->unread_count;
	summary->priv->deleted_count = record->deleted_count;
	summary->priv->junk_count = record->junk_count;
	summary->priv->visible_count = record->visible_count;
	summary->priv->junk_not_deleted_count = record->jnd_count;

	return TRUE;
}

static CamelFIRecord *
summary_header_save (CamelFolderSummary *summary,
		     GError **error)
{
	CamelFIRecord *record = g_new0 (CamelFIRecord, 1);
	CamelStore *parent_store;
	CamelDB *cdb;
	const gchar *table_name;

	/* Though we are going to read, we do this during write,
	 * so lets use it that way. */
	table_name = camel_folder_get_full_name (summary->priv->folder);
	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	cdb = parent_store ? camel_store_get_db (parent_store) : NULL;

	io (printf ("Savining header to db\n"));

	record->folder_name = g_strdup (table_name);

	/* we always write out the current version */
	record->version = CAMEL_FOLDER_SUMMARY_VERSION;
	record->flags = summary->priv->flags;
	record->nextuid = summary->priv->nextuid;
	record->timestamp = summary->priv->timestamp;

	if (cdb && !is_in_memory_summary (summary)) {
		/* FIXME: Ever heard of Constructors and initializing ? */
		if (camel_db_count_total_message_info (cdb, table_name, &(record->saved_count), NULL))
			record->saved_count = 0;
		if (camel_db_count_junk_message_info (cdb, table_name, &(record->junk_count), NULL))
			record->junk_count = 0;
		if (camel_db_count_deleted_message_info (cdb, table_name, &(record->deleted_count), NULL))
			record->deleted_count = 0;
		if (camel_db_count_unread_message_info (cdb, table_name, &(record->unread_count), NULL))
			record->unread_count = 0;
		if (camel_db_count_visible_message_info (cdb, table_name, &(record->visible_count), NULL))
			record->visible_count = 0;
		if (camel_db_count_junk_not_deleted_message_info (cdb, table_name, &(record->jnd_count), NULL))
			record->jnd_count = 0;
	}

	summary->priv->unread_count = record->unread_count;
	summary->priv->deleted_count = record->deleted_count;
	summary->priv->junk_count = record->junk_count;
	summary->priv->visible_count = record->visible_count;
	summary->priv->junk_not_deleted_count = record->jnd_count;

	return record;
}

/**
 * camel_folder_summary_replace_flags:
 * @summary: a #CamelFolderSummary
 * @info: a #CamelMessageInfo
 *
 * Updates internal counts based on the flags in @info.
 *
 * Returns: Whether any count changed
 *
 * Since: 3.6
 **/
gboolean
camel_folder_summary_replace_flags (CamelFolderSummary *summary,
                                    CamelMessageInfo *info)
{
	guint32 old_flags, new_flags, added_flags, removed_flags;
	gboolean is_junk_folder = FALSE, is_trash_folder = FALSE;
	GObject *summary_object;
	gboolean changed = FALSE;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (info != NULL, FALSE);

	if (!camel_message_info_get_uid (info) ||
	    !camel_folder_summary_check_uid (summary, camel_message_info_get_uid (info)))
		return FALSE;

	summary_object = G_OBJECT (summary);

	camel_folder_summary_lock (summary);
	g_object_freeze_notify (summary_object);

	old_flags = GPOINTER_TO_UINT (g_hash_table_lookup (summary->priv->uids, camel_message_info_get_uid (info)));
	new_flags = camel_message_info_get_flags (info);

	if ((old_flags & ~CAMEL_MESSAGE_FOLDER_FLAGGED) == (new_flags & ~CAMEL_MESSAGE_FOLDER_FLAGGED)) {
		g_object_thaw_notify (summary_object);
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	if (summary->priv->folder && CAMEL_IS_VTRASH_FOLDER (summary->priv->folder)) {
		CamelVTrashFolder *vtrash = CAMEL_VTRASH_FOLDER (summary->priv->folder);

		is_junk_folder = vtrash && camel_vtrash_folder_get_folder_type (vtrash) == CAMEL_VTRASH_FOLDER_JUNK;
		is_trash_folder = vtrash && camel_vtrash_folder_get_folder_type (vtrash) == CAMEL_VTRASH_FOLDER_TRASH;
	} else if (summary->priv->folder) {
		guint32 folder_flags;

		folder_flags = camel_folder_get_flags (summary->priv->folder);

		is_junk_folder = (folder_flags & CAMEL_FOLDER_IS_JUNK) != 0;
		is_trash_folder = (folder_flags & CAMEL_FOLDER_IS_TRASH) != 0;
	}

	added_flags = new_flags & (~(old_flags & new_flags));
	removed_flags = old_flags & (~(old_flags & new_flags));

	if ((old_flags & CAMEL_MESSAGE_SEEN) == (new_flags & CAMEL_MESSAGE_SEEN)) {
		/* unread count is different from others, it asks for nonexistence
		 * of the flag, thus if it wasn't changed, then simply set it
		 * in added/removed, thus there are no false notifications
		 * on unread counts */
		added_flags |= CAMEL_MESSAGE_SEEN;
		removed_flags |= CAMEL_MESSAGE_SEEN;
	} else if ((!is_junk_folder && (new_flags & CAMEL_MESSAGE_JUNK) != 0 &&
		   (old_flags & CAMEL_MESSAGE_JUNK) == (new_flags & CAMEL_MESSAGE_JUNK)) ||
		   (!is_trash_folder && (new_flags & CAMEL_MESSAGE_DELETED) != 0 &&
		   (old_flags & CAMEL_MESSAGE_DELETED) == (new_flags & CAMEL_MESSAGE_DELETED))) {
		/* The message was set read or unread, but it is a junk or deleted message,
		 * in a non-Junk/non-Trash folder, thus it doesn't influence an unread count
		 * there, thus pretend unread didn't change */
		added_flags |= CAMEL_MESSAGE_SEEN;
		removed_flags |= CAMEL_MESSAGE_SEEN;
	}

	/* decrement counts with removed flags */
	changed = folder_summary_update_counts_by_flags (summary, removed_flags, UPDATE_COUNTS_SUB_WITHOUT_TOTAL) || changed;
	/* increment counts with added flags */
	changed = folder_summary_update_counts_by_flags (summary, added_flags, UPDATE_COUNTS_ADD_WITHOUT_TOTAL) || changed;

	/* update current flags on the summary */
	g_hash_table_insert (
		summary->priv->uids,
		(gpointer) camel_pstring_strdup (camel_message_info_get_uid (info)),
		GUINT_TO_POINTER (new_flags));

	g_object_thaw_notify (summary_object);
	camel_folder_summary_unlock (summary);

	return changed;
}

static void
camel_folder_summary_class_init (CamelFolderSummaryClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelFolderSummaryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = folder_summary_set_property;
	object_class->get_property = folder_summary_get_property;
	object_class->dispose = folder_summary_dispose;
	object_class->finalize = folder_summary_finalize;

	class->message_info_type = CAMEL_TYPE_MESSAGE_INFO_BASE;

	class->summary_header_load = summary_header_load;
	class->summary_header_save = summary_header_save;

	class->message_info_new_from_headers = message_info_new_from_headers;
	class->message_info_new_from_parser = message_info_new_from_parser;
	class->message_info_new_from_message = message_info_new_from_message;
	class->message_info_from_uid = message_info_from_uid;

	class->next_uid_string = next_uid_string;

	/**
	 * CamelFolderSummary:folder
	 *
	 * The #CamelFolder to which the folder summary belongs.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FOLDER,
		g_param_spec_object (
			"folder",
			"Folder",
			"The folder to which the folder summary belongs",
			CAMEL_TYPE_FOLDER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * CamelFolderSummary:saved-count
	 *
	 * How many infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_SAVED_COUNT,
		g_param_spec_uint (
			"saved-count",
			"Saved count",
			"How many infos is savef in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary:unread-count
	 *
	 * How many unread infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_UNREAD_COUNT,
		g_param_spec_uint (
			"unread-count",
			"Unread count",
			"How many unread infos is saved in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary:deleted-count
	 *
	 * How many deleted infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_DELETED_COUNT,
		g_param_spec_uint (
			"deleted-count",
			"Deleted count",
			"How many deleted infos is saved in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary:junk-count
	 *
	 * How many junk infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_JUNK_COUNT,
		g_param_spec_uint (
			"junk-count",
			"Junk count",
			"How many junk infos is saved in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary:junk-not-deleted-count
	 *
	 * How many junk and not deleted infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_JUNK_NOT_DELETED_COUNT,
		g_param_spec_uint (
			"junk-not-deleted-count",
			"Junk not deleted count",
			"How many junk and not deleted infos is saved in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary:visible-count
	 *
	 * How many visible (not deleted and not junk) infos is saved in a summary.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_VISIBLE_COUNT,
		g_param_spec_uint (
			"visible-count",
			"Visible count",
			"How many visible (not deleted and not junk) infos is saved in a summary",
			0,  G_MAXUINT32,
			0, G_PARAM_READABLE));

	/**
	 * CamelFolderSummary::prepare-fetch-all
	 * @summary: the #CamelFolderSummary which emitted the signal
	 *
	 * Emitted on call to camel_folder_summary_prepare_fetch_all().
	 *
	 * Since: 3.26
	 **/
	signals[PREPARE_FETCH_ALL] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelFolderSummaryClass, prepare_fetch_all),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0,
		G_TYPE_NONE);
}

static void
camel_folder_summary_init (CamelFolderSummary *summary)
{
	summary->priv = G_TYPE_INSTANCE_GET_PRIVATE (summary, CAMEL_TYPE_FOLDER_SUMMARY, CamelFolderSummaryPrivate);

	summary->priv->version = CAMEL_FOLDER_SUMMARY_VERSION;
	summary->priv->flags = 0;
	summary->priv->timestamp = 0;

	summary->priv->filter_charset = g_hash_table_new (
		camel_strcase_hash, camel_strcase_equal);

	summary->priv->nextuid = 1;
	summary->priv->uids = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, NULL);
	summary->priv->loaded_infos = g_hash_table_new (g_str_hash, g_str_equal);

	g_rec_mutex_init (&summary->priv->summary_lock);
	g_rec_mutex_init (&summary->priv->filter_lock);

	summary->priv->cache_load_time = 0;
	summary->priv->timeout_handle = 0;
}

/**
 * camel_folder_summary_new:
 * @folder: (type CamelFolder): parent #CamelFolder object
 *
 * Create a new #CamelFolderSummary object.
 *
 * Returns: a new #CamelFolderSummary object
 **/
CamelFolderSummary *
camel_folder_summary_new (CamelFolder *folder)
{
	return g_object_new (CAMEL_TYPE_FOLDER_SUMMARY, "folder", folder, NULL);
}

/**
 * camel_folder_summary_get_folder:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: (transfer none): a #CamelFolder to which the summary if associated.
 *
 * Since: 3.4
 **/
CamelFolder *
camel_folder_summary_get_folder (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	return summary->priv->folder;
}

/**
 * camel_folder_summary_get_flags:
 * @summary: a #CamelFolderSummary
 *
 * Returns: flags of the @summary, a bit-or of #CamelFolderSummaryFlags
 *
 * Since: 3.24
 **/
guint32
camel_folder_summary_get_flags (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->flags;
}

/**
 * camel_folder_summary_set_flags:
 * @summary: a #CamelFolderSummary
 * @flags: flags to set
 *
 * Sets flags of the @summary, a bit-or of #CamelFolderSummaryFlags.
 *
 * Since: 3.24
 **/
void
camel_folder_summary_set_flags (CamelFolderSummary *summary,
				guint32 flags)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	summary->priv->flags = flags;
}

/**
 * camel_folder_summary_get_timestamp:
 * @summary: a #CamelFolderSummary
 *
 * Returns: timestamp of the @summary, as set by the descendants
 *
 * Since: 3.24
 **/
gint64
camel_folder_summary_get_timestamp (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->timestamp;
}

/**
 * camel_folder_summary_set_timestamp:
 * @summary: a #CamelFolderSummary
 * @timestamp: a timestamp to set
 *
 * Sets timestamp of the @summary, provided by the descendants. This doesn't
 * change the 'dirty' flag of the @summary.
 *
 * Since: 3.24
 **/
void
camel_folder_summary_set_timestamp (CamelFolderSummary *summary,
				    gint64 timestamp)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	summary->priv->timestamp = timestamp;
}

/**
 * camel_folder_summary_get_version:
 * @summary: a #CamelFolderSummary
 *
 * Returns: version of the @summary
 *
 * Since: 3.24
 **/
guint32
camel_folder_summary_get_version (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->version;
}

/**
 * camel_folder_summary_set_version:
 * @summary: a #CamelFolderSummary
 * @version: version to set
 *
 * Sets version of the @summary.
 *
 * Since: 3.24
 **/
void
camel_folder_summary_set_version (CamelFolderSummary *summary,
				  guint32 version)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	summary->priv->version = version;
}

/**
 * camel_folder_summary_get_saved_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of saved infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_saved_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->saved_count;
}

/**
 * camel_folder_summary_get_unread_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of unread infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_unread_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->unread_count;
}

/**
 * camel_folder_summary_get_deleted_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of deleted infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_deleted_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->deleted_count;
}

/**
 * camel_folder_summary_get_junk_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of junk infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_junk_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->junk_count;
}

/**
 * camel_folder_summary_get_junk_not_deleted_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of junk and not deleted infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_junk_not_deleted_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->junk_not_deleted_count;
}

/**
 * camel_folder_summary_get_visible_count:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Count of visible (not junk and not deleted) infos.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_visible_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return summary->priv->visible_count;
}

/**
 * camel_folder_summary_set_index:
 * @summary: a #CamelFolderSummary object
 * @index: a #CamelIndex
 *
 * Set the index used to index body content.  If the index is %NULL, or
 * not set (the default), no indexing of body content will take place.
 **/
void
camel_folder_summary_set_index (CamelFolderSummary *summary,
                                CamelIndex *index)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	if (index != NULL)
		g_object_ref (index);

	if (summary->priv->index != NULL)
		g_object_unref (summary->priv->index);

	summary->priv->index = index;
}

/**
 * camel_folder_summary_get_index:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: (transfer none): a #CamelIndex used to index body content.
 *
 * Since: 3.4
 **/
CamelIndex *
camel_folder_summary_get_index (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	return summary->priv->index;
}

/**
 * camel_folder_summary_next_uid:
 * @summary: a #CamelFolderSummary object
 *
 * Generate a new unique uid value as an integer.  This
 * may be used to create a unique sequence of numbers.
 *
 * Returns: the next unique uid value
 **/
guint32
camel_folder_summary_next_uid (CamelFolderSummary *summary)
{
	guint32 uid;

	camel_folder_summary_lock (summary);

	uid = summary->priv->nextuid++;
	camel_folder_summary_touch (summary);

	camel_folder_summary_unlock (summary);

	return uid;
}

/**
 * camel_folder_summary_set_next_uid:
 * @summary: a #CamelFolderSummary object
 * @uid: The next minimum uid to assign.  To avoid clashing
 * uid's, set this to the uid of a given messages + 1.
 *
 * Set the next minimum uid available.  This can be used to
 * ensure new uid's do not clash with existing uid's.
 **/
void
camel_folder_summary_set_next_uid (CamelFolderSummary *summary,
                                   guint32 uid)
{
	camel_folder_summary_lock (summary);

	summary->priv->nextuid = MAX (summary->priv->nextuid, uid);
	camel_folder_summary_touch (summary);

	camel_folder_summary_unlock (summary);
}

/**
 * camel_folder_summary_get_next_uid:
 * @summary: a #CamelFolderSummary object
 *
 * Returns: Next uid currently awaiting for assignment. The difference from
 *    camel_folder_summary_next_uid() is that this function returns actual
 *    value and doesn't increment it before returning.
 *
 * Since: 3.4
 **/
guint32
camel_folder_summary_get_next_uid (CamelFolderSummary *summary)
{
	guint32 res;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	camel_folder_summary_lock (summary);

	res = summary->priv->nextuid;

	camel_folder_summary_unlock (summary);

	return res;
}

/**
 * camel_folder_summary_next_uid_string:
 * @summary: a #CamelFolderSummary object
 *
 * Retrieve the next uid, but as a formatted string.
 *
 * Returns: the next uid as an unsigned integer string.
 * This string must be freed by the caller.
 **/
gchar *
camel_folder_summary_next_uid_string (CamelFolderSummary *summary)
{
	CamelFolderSummaryClass *class;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	class = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->next_uid_string != NULL, NULL);

	return class->next_uid_string (summary);
}

/**
 * camel_folder_summary_count:
 * @summary: a #CamelFolderSummary object
 *
 * Get the number of summary items stored in this summary.
 *
 * Returns: the number of items in the summary
 **/
guint
camel_folder_summary_count (CamelFolderSummary *summary)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), 0);

	return g_hash_table_size (summary->priv->uids);
}

/**
 * camel_folder_summary_check_uid
 * @summary: a #CamelFolderSummary object
 * @uid: a uid
 *
 * Check if the uid is valid. This isn't very efficient, so it shouldn't be called iteratively.
 *
 *
 * Returns: if the uid is present in the summary or not  (%TRUE or %FALSE)
 *
 * Since: 2.24
 **/
gboolean
camel_folder_summary_check_uid (CamelFolderSummary *summary,
                                const gchar *uid)
{
	gboolean ret;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	camel_folder_summary_lock (summary);

	ret = g_hash_table_contains (summary->priv->uids, uid);

	camel_folder_summary_unlock (summary);

	return ret;
}

static void
folder_summary_dupe_uids_to_array (gpointer key_uid,
                                   gpointer value_flags,
                                   gpointer user_data)
{
	g_ptr_array_add (user_data, (gpointer) camel_pstring_strdup (key_uid));
}

/**
 * camel_folder_summary_get_array:
 * @summary: a #CamelFolderSummary object
 *
 * Obtain a copy of the summary array.  This is done atomically,
 * so cannot contain empty entries.
 *
 * Free with camel_folder_summary_free_array()
 *
 * Returns: (element-type utf8) (transfer full): a #GPtrArray of uids
 *
 * Since: 3.4
 **/
GPtrArray *
camel_folder_summary_get_array (CamelFolderSummary *summary)
{
	GPtrArray *res;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	camel_folder_summary_lock (summary);

	/* Do not set free_func on the array, it would break IMAPx code */
	res = g_ptr_array_sized_new (g_hash_table_size (summary->priv->uids));
	g_hash_table_foreach (summary->priv->uids, folder_summary_dupe_uids_to_array, res);

	camel_folder_summary_unlock (summary);

	return res;
}

/**
 * camel_folder_summary_free_array:
 * @array: (element-type utf8): a #GPtrArray returned from camel_folder_summary_get_array()
 *
 * Free's array and its elements returned from camel_folder_summary_get_array().
 *
 * Since: 3.4
 **/
void
camel_folder_summary_free_array (GPtrArray *array)
{
	if (!array)
		return;

	g_ptr_array_foreach (array, (GFunc) camel_pstring_free, NULL);
	g_ptr_array_free (array, TRUE);
}

static void
cfs_copy_uids_cb (gpointer key,
                  gpointer value,
                  gpointer user_data)
{
	const gchar *uid = key;
	GHashTable *copy_hash = user_data;

	g_hash_table_insert (copy_hash, (gpointer) camel_pstring_strdup (uid), GINT_TO_POINTER (1));
}

/**
 * camel_folder_summary_get_hash:
 * @summary: a #CamelFolderSummary object
 *
 * Returns hash of current stored 'uids' in summary, where key is 'uid'
 * from the string pool, and value is 1. The returned pointer should
 * be freed with g_hash_table_destroy().
 *
 * Note: When searching for values always use uids from the string pool.
 *
 * Returns: (element-type utf8 gint) (transfer container):
 *
 * Since: 3.6
 **/
GHashTable *
camel_folder_summary_get_hash (CamelFolderSummary *summary)
{
	GHashTable *uids;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	camel_folder_summary_lock (summary);

	/* using direct hash because of strings being from the string pool */
	uids = g_hash_table_new_full (g_direct_hash, g_direct_equal, (GDestroyNotify) camel_pstring_free, NULL);
	g_hash_table_foreach (summary->priv->uids, cfs_copy_uids_cb, uids);

	camel_folder_summary_unlock (summary);

	return uids;
}

/**
 * camel_folder_summary_peek_loaded:
 * @summary: a #CamelFolderSummary
 * @uid: a message UID to look for
 *
 * Returns: (nullable) (transfer full): a #CamelMessageInfo for the given @uid,
 *    if it's currently loaded in memory, or %NULL otherwise. Unref the non-NULL
 *    info with g_object_unref() when done with it.
 *
 * Since: 2.26
 **/
CamelMessageInfo *
camel_folder_summary_peek_loaded (CamelFolderSummary *summary,
                                  const gchar *uid)
{
	CamelMessageInfo *info;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	camel_folder_summary_lock (summary);

	info = g_hash_table_lookup (summary->priv->loaded_infos, uid);

	if (info)
		g_object_ref (info);

	camel_folder_summary_unlock (summary);

	return info;
}

struct _db_pass_data {
	GHashTable *columns_hash;
	CamelFolderSummary *summary;
	gboolean add; /* or just insert to hashtable */
};

static CamelMessageInfo *
message_info_from_uid (CamelFolderSummary *summary,
                       const gchar *uid)
{
	CamelMessageInfo *info;
	gint ret;

	camel_folder_summary_lock (summary);

	info = g_hash_table_lookup (summary->priv->loaded_infos, uid);

	if (!info) {
		CamelDB *cdb;
		CamelStore *parent_store;
		const gchar *folder_name;
		struct _db_pass_data data;

		folder_name = camel_folder_get_full_name (summary->priv->folder);

		if (is_in_memory_summary (summary)) {
			camel_folder_summary_unlock (summary);
			g_warning (
				"%s: Tried to load uid '%s' "
				"from DB on in-memory summary of '%s'",
				G_STRFUNC, uid, folder_name);
			return NULL;
		}

		parent_store = camel_folder_get_parent_store (summary->priv->folder);
		if (!parent_store) {
			camel_folder_summary_unlock (summary);
			return NULL;
		}

		cdb = camel_store_get_db (parent_store);

		data.columns_hash = NULL;
		data.summary = summary;
		data.add = FALSE;

		ret = camel_db_read_message_info_record_with_uid (
			cdb, folder_name, uid, &data,
			camel_read_mir_callback, NULL);
		if (data.columns_hash)
			g_hash_table_destroy (data.columns_hash);

		if (ret != 0) {
			camel_folder_summary_unlock (summary);
			return NULL;
		}

		/* We would have double reffed at camel_read_mir_callback */
		info = g_hash_table_lookup (summary->priv->loaded_infos, uid);

		cfs_schedule_info_release_timer (summary);
	}

	if (info)
		g_object_ref (info);

	camel_folder_summary_unlock (summary);

	return info;
}

/**
 * camel_folder_summary_get:
 * @summary: a #CamelFolderSummary object
 * @uid: a uid
 *
 * Retrieve a summary item by uid.
 *
 * A referenced to the summary item is returned, which may be
 * ref'd or free'd as appropriate.
 *
 * Returns: (nullable) (transfer full): the summary item, or %NULL if the uid @uid is not available
 *
 * See camel_folder_summary_get_info_flags().
 *
 * Since: 3.4
 **/
CamelMessageInfo *
camel_folder_summary_get (CamelFolderSummary *summary,
                          const gchar *uid)
{
	CamelFolderSummaryClass *class;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	class = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->message_info_from_uid != NULL, NULL);

	return class->message_info_from_uid (summary, uid);
}

/**
 * camel_folder_summary_get_info_flags:
 * @summary: a #CamelFolderSummary object
 * @uid: a uid
 *
 * Retrieve CamelMessageInfo::flags for a message info with UID @uid.
 * This is much quicker than camel_folder_summary_get(), because it
 * doesn't require reading the message info from a disk.
 *
 * Returns: the flags currently stored for message info with UID @uid,
 *          or (~0) on error
 *
 * Since: 3.12
 **/
guint32
camel_folder_summary_get_info_flags (CamelFolderSummary *summary,
				     const gchar *uid)
{
	gpointer ptr_uid = NULL, ptr_flags = NULL;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), (~0));
	g_return_val_if_fail (uid != NULL, (~0));

	camel_folder_summary_lock (summary);
	if (!g_hash_table_lookup_extended (summary->priv->uids, uid, &ptr_uid, &ptr_flags)) {
		camel_folder_summary_unlock (summary);
		return (~0);
	}

	camel_folder_summary_unlock (summary);

	return GPOINTER_TO_UINT (ptr_flags);
}

static void
gather_dirty_or_flagged_uids (gpointer key,
			      gpointer value,
			      gpointer user_data)
{
	const gchar *uid = key;
	CamelMessageInfo *info = value;
	GHashTable *hash = user_data;

	if (camel_message_info_get_dirty (info) || (camel_message_info_get_flags (info) & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0)
		g_hash_table_insert (hash, (gpointer) camel_pstring_strdup (uid), GINT_TO_POINTER (1));
}

static void
gather_changed_uids (gpointer key,
                     gpointer value,
                     gpointer user_data)
{
	const gchar *uid = key;
	guint32 flags = GPOINTER_TO_UINT (value);
	GHashTable *hash = user_data;

	if ((flags & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0)
		g_hash_table_insert (hash, (gpointer) camel_pstring_strdup (uid), GINT_TO_POINTER (1));
}

/**
 * camel_folder_summary_get_changed:
 * @summary: a #CamelFolderSummary
 *
 * Returns an array of changed UID-s. A UID is considered changed
 * when its corresponding CamelMesageInfo is 'dirty' or when it has
 * set the #CAMEL_MESSAGE_FOLDER_FLAGGED flag.
 *
 * Returns: (element-type utf8) (transfer full): a #GPtrArray with changed UID-s.
 *    Free it with camel_folder_summary_free_array() when no longer needed.
 *
 * Since: 2.24
 **/
GPtrArray *
camel_folder_summary_get_changed (CamelFolderSummary *summary)
{
	GPtrArray *res;
	GHashTable *hash;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	hash = g_hash_table_new_full (g_direct_hash, g_direct_equal, (GDestroyNotify) camel_pstring_free, NULL);

	camel_folder_summary_lock (summary);

	g_hash_table_foreach (summary->priv->loaded_infos, gather_dirty_or_flagged_uids, hash);
	g_hash_table_foreach (summary->priv->uids, gather_changed_uids, hash);

	res = g_ptr_array_sized_new (g_hash_table_size (hash));
	g_hash_table_foreach (hash, folder_summary_dupe_uids_to_array, res);

	camel_folder_summary_unlock (summary);

	g_hash_table_destroy (hash);

	return res;
}

static void
count_changed_uids (gchar *key,
                    CamelMessageInfo *info,
                    gint *count)
{
	if (camel_message_info_get_dirty (info))
		(*count)++;
}

static gint
cfs_count_dirty (CamelFolderSummary *summary)
{
	gint count = 0;

	camel_folder_summary_lock (summary);
	g_hash_table_foreach (summary->priv->loaded_infos, (GHFunc) count_changed_uids, &count);
	camel_folder_summary_unlock (summary);

	return count;
}

static gboolean
remove_item (gchar *uid,
             CamelMessageInfo *info,
             GSList **to_remove_infos)
{
	if (G_OBJECT (info)->ref_count == 1 && !camel_message_info_get_dirty (info) && (camel_message_info_get_flags (info) & CAMEL_MESSAGE_FOLDER_FLAGGED) == 0) {
		*to_remove_infos = g_slist_prepend (*to_remove_infos, info);
		return TRUE;
	}

	return FALSE;
}

static void
remove_cache (CamelSession *session,
              GCancellable *cancellable,
              CamelFolderSummary *summary,
              GError **error)
{
	GSList *to_remove_infos = NULL;

	camel_db_release_cache_memory ();

	if (time (NULL) - summary->priv->cache_load_time < SUMMARY_CACHE_DROP)
		return;

	camel_folder_summary_lock (summary);

	g_hash_table_foreach_remove (summary->priv->loaded_infos, (GHRFunc) remove_item, &to_remove_infos);

	g_slist_free_full (to_remove_infos, g_object_unref);

	camel_folder_summary_unlock (summary);

	summary->priv->cache_load_time = time (NULL);
}

static void
cfs_free_weakref (gpointer ptr)
{
	GWeakRef *weakref = ptr;

	if (weakref) {
		g_weak_ref_set (weakref, NULL);
		g_weak_ref_clear (weakref);
		g_free (weakref);
	}
}

static gboolean
cfs_try_release_memory (gpointer user_data)
{
	GWeakRef *weakref = user_data;
	CamelFolderSummary *summary;
	CamelStore *parent_store;
	CamelSession *session;
	gchar *description;

	g_return_val_if_fail (weakref != NULL, FALSE);

	summary = g_weak_ref_get (weakref);

	if (!summary)
		return FALSE;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	/* If folder is freed or if the cache is nil then clean up */
	if (!summary->priv->folder ||
	    !g_hash_table_size (summary->priv->loaded_infos) ||
	    is_in_memory_summary (summary)) {
		summary->priv->cache_load_time = 0;
		summary->priv->timeout_handle = 0;
		g_object_unref (summary);

		return FALSE;
	}

	if (time (NULL) - summary->priv->cache_load_time < SUMMARY_CACHE_DROP) {
		g_object_unref (summary);
		return TRUE;
	}

	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store) {
		summary->priv->cache_load_time = 0;
		summary->priv->timeout_handle = 0;
		g_object_unref (summary);

		return FALSE;
	}

	session = camel_service_ref_session (CAMEL_SERVICE (parent_store));
	if (!session) {
		summary->priv->cache_load_time = 0;
		summary->priv->timeout_handle = 0;
		g_object_unref (summary);

		return FALSE;
	}

	/* Translators: The first “%s” is replaced with an account name and the second “%s”
	   is replaced with a full path name. The spaces around “:” are intentional, as
	   the whole “%s : %s” is meant as an absolute identification of the folder. */
	description = g_strdup_printf (_("Release unused memory for folder “%s : %s”"),
		camel_service_get_display_name (CAMEL_SERVICE (parent_store)),
		camel_folder_get_full_name (summary->priv->folder));

	camel_session_submit_job (
		session, description,
		(CamelSessionCallback) remove_cache,
		/* Consumes the reference of the 'summary'. */
		summary, g_object_unref);

	g_object_unref (session);
	g_free (description);

	return TRUE;
}

static void
cfs_schedule_info_release_timer (CamelFolderSummary *summary)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	if (is_in_memory_summary (summary))
		return;

	if (!summary->priv->timeout_handle) {
		static gboolean know_can_do = FALSE, can_do = TRUE;

		if (!know_can_do) {
			can_do = !g_getenv ("CAMEL_FREE_INFOS");
			know_can_do = TRUE;
		}

		/* FIXME[disk-summary] LRU please and not timeouts */
		if (can_do) {
			GWeakRef *weakref;

			weakref = g_new0 (GWeakRef, 1);
			g_weak_ref_init (weakref, summary);

			summary->priv->timeout_handle = g_timeout_add_seconds_full (
				G_PRIORITY_DEFAULT, SUMMARY_CACHE_DROP,
				cfs_try_release_memory,
				weakref, cfs_free_weakref);
			g_source_set_name_by_id (
				summary->priv->timeout_handle,
				"[camel] cfs_try_release_memory");
		}
	}

	/* update also cache load time to the actual, to not release something just loaded */
	summary->priv->cache_load_time = time (NULL);
}

static gint
cfs_cache_size (CamelFolderSummary *summary)
{
	/* FIXME[disk-summary] this is a timely hack. fix it well */
	if (!CAMEL_IS_VEE_FOLDER (summary->priv->folder))
		return g_hash_table_size (summary->priv->loaded_infos);
	else
		return g_hash_table_size (summary->priv->uids);
}

static void
cfs_reload_from_db (CamelFolderSummary *summary,
                    GError **error)
{
	CamelDB *cdb;
	CamelStore *parent_store;
	const gchar *folder_name;
	struct _db_pass_data data;

	/* FIXME[disk-summary] baseclass this, and vfolders we may have to
	 * load better. */
	d (printf ("\ncamel_folder_summary_reload_from_db called \n"));

	if (is_in_memory_summary (summary))
		return;

	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store)
		return;

	folder_name = camel_folder_get_full_name (summary->priv->folder);
	cdb = camel_store_get_db (parent_store);

	data.columns_hash = NULL;
	data.summary = summary;
	data.add = FALSE;

	camel_db_read_message_info_records (
		cdb, folder_name, (gpointer) &data,
		camel_read_mir_callback, NULL);

	if (data.columns_hash)
		g_hash_table_destroy (data.columns_hash);

	cfs_schedule_info_release_timer (summary);
}

/**
 * camel_folder_summary_prepare_fetch_all:
 * @summary: #CamelFolderSummary object
 * @error: return location for a #GError, or %NULL
 *
 * Loads all infos into memory, if they are not yet and ensures
 * they will not be freed in next couple minutes. Call this function
 * before any mass operation or when all message infos will be needed,
 * for better performance.
 *
 * Since: 2.32
 **/
void
camel_folder_summary_prepare_fetch_all (CamelFolderSummary *summary,
                                        GError **error)
{
	guint loaded, known;

	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	loaded = cfs_cache_size (summary);
	known = camel_folder_summary_count (summary);

	g_signal_emit (summary, signals[PREPARE_FETCH_ALL], 0);

	if (known - loaded > 50) {
		camel_folder_summary_lock (summary);
		cfs_reload_from_db (summary, error);
		camel_folder_summary_unlock (summary);
	}

	/* update also cache load time, even when not loaded anything */
	summary->priv->cache_load_time = time (NULL);
}

/**
 * camel_folder_summary_load:
 * @summary: a #CamelFolderSummary
 * @error: return location for a #GError, or %NULL
 *
 * Loads the summary from the disk. It also saves any pending
 * changes first.
 *
 * Returns: whether succeeded
 *
 * Since: 3.24
 **/
gboolean
camel_folder_summary_load (CamelFolderSummary *summary,
			   GError **error)
{
	CamelFolderSummaryClass *klass;
	CamelDB *cdb;
	CamelStore *parent_store;
	const gchar *full_name;
	gint ret = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (is_in_memory_summary (summary))
		return TRUE;

	camel_folder_summary_lock (summary);
	camel_folder_summary_save (summary, NULL);

	/* struct _db_pass_data data; */
	d (printf ("\ncamel_folder_summary_load called \n"));

	full_name = camel_folder_get_full_name (summary->priv->folder);
	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!camel_folder_summary_header_load (summary, parent_store, full_name, error)) {
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	if (!parent_store) {
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	cdb = camel_store_get_db (parent_store);

	ret = camel_db_get_folder_uids (
		cdb, full_name, klass->sort_by, klass->collate,
		summary->priv->uids, &local_error);

	if (local_error != NULL && local_error->message != NULL &&
	    strstr (local_error->message, "no such table") != NULL) {
		g_clear_error (&local_error);

		/* create table the first time it is accessed and missing */
		ret = camel_db_prepare_message_info_table (cdb, full_name, error);
	} else if (local_error != NULL)
		g_propagate_error (error, local_error);

	camel_folder_summary_unlock (summary);

	return ret == 0;
}

/* Beware, it only borrows pointers from 'cols' here */
static void
mir_from_cols (CamelMIRecord *mir,
               CamelFolderSummary *summary,
               GHashTable **columns_hash,
               gint ncol,
               gchar **cols,
               gchar **name)
{
	gint i;

	for (i = 0; i < ncol; ++i) {
		if (!name[i] || !cols[i])
			continue;

		switch (camel_db_get_column_ident (columns_hash, i, ncol, name)) {
			case CAMEL_DB_COLUMN_UID:
				mir->uid = cols[i];
				break;
			case CAMEL_DB_COLUMN_FLAGS:
				mir->flags = cols[i] ? g_ascii_strtoull (cols[i], NULL, 10) : 0;
				break;
			case CAMEL_DB_COLUMN_READ:
				mir->read = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_DELETED:
				mir->deleted = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_REPLIED:
				mir->replied = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_IMPORTANT:
				mir->important = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_JUNK:
				mir->junk = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_ATTACHMENT:
				mir->attachment = (cols[i]) ? ( ((g_ascii_strtoull (cols[i], NULL, 10)) ? TRUE : FALSE)) : FALSE;
				break;
			case CAMEL_DB_COLUMN_SIZE:
				mir->size = cols[i] ? g_ascii_strtoull (cols[i], NULL, 10) : 0;
				break;
			case CAMEL_DB_COLUMN_DSENT:
				mir->dsent = cols[i] ? g_ascii_strtoll (cols[i], NULL, 10) : 0;
				break;
			case CAMEL_DB_COLUMN_DRECEIVED:
				mir->dreceived = cols[i] ? g_ascii_strtoll (cols[i], NULL, 10) : 0;
				break;
			case CAMEL_DB_COLUMN_SUBJECT:
				mir->subject = cols[i];
				break;
			case CAMEL_DB_COLUMN_MAIL_FROM:
				mir->from = cols[i];
				break;
			case CAMEL_DB_COLUMN_MAIL_TO:
				mir->to = cols[i];
				break;
			case CAMEL_DB_COLUMN_MAIL_CC:
				mir->cc = cols[i];
				break;
			case CAMEL_DB_COLUMN_MLIST:
				mir->mlist = cols[i];
				break;
			case CAMEL_DB_COLUMN_FOLLOWUP_FLAG:
				mir->followup_flag = cols[i];
				break;
			case CAMEL_DB_COLUMN_FOLLOWUP_COMPLETED_ON:
				mir->followup_completed_on = cols[i];
				break;
			case CAMEL_DB_COLUMN_FOLLOWUP_DUE_BY:
				mir->followup_due_by = cols[i];
				break;
			case CAMEL_DB_COLUMN_PART:
				mir->part = cols[i];
				break;
			case CAMEL_DB_COLUMN_LABELS:
				mir->labels = cols[i];
				break;
			case CAMEL_DB_COLUMN_USERTAGS:
				mir->usertags = cols[i];
				break;
			case CAMEL_DB_COLUMN_CINFO:
				mir->cinfo = cols[i];
				break;
			case CAMEL_DB_COLUMN_BDATA:
				mir->bdata = cols[i];
				break;
			default:
				g_warn_if_reached ();
				break;
		}
	}
}

static gint
camel_read_mir_callback (gpointer ref,
                         gint ncol,
                         gchar **cols,
                         gchar **name)
{
	struct _db_pass_data *data = (struct _db_pass_data *) ref;
	CamelFolderSummary *summary = data->summary;
	CamelMIRecord mir;
	CamelMessageInfo *info;
	gchar *bdata_ptr;
	gint ret = 0;

	memset (&mir, 0, sizeof (CamelMIRecord));

	/* As mir_from_cols() only borrows data from cols, no need to free mir */
	mir_from_cols (&mir, summary, &data->columns_hash, ncol, cols, name);

	camel_folder_summary_lock (summary);
	if (!mir.uid || g_hash_table_lookup (summary->priv->loaded_infos, mir.uid)) {
		/* Unlock and better return */
		camel_folder_summary_unlock (summary);
		return ret;
	}
	camel_folder_summary_unlock (summary);

	info = camel_message_info_new (summary);
	bdata_ptr = mir.bdata;
	if (camel_message_info_load (info, &mir, &bdata_ptr)) {
		/* Just now we are reading from the DB, it can't be dirty. */
		camel_message_info_set_dirty (info, FALSE);
		if (data->add) {
			camel_folder_summary_add (summary, info, TRUE);
			g_clear_object (&info);
		} else {
			camel_folder_summary_lock (summary);
			/* Summary always holds a ref for the loaded infos; this consumes it */
			g_hash_table_insert (summary->priv->loaded_infos, (gchar *) camel_message_info_get_uid (info), info);
			camel_folder_summary_unlock (summary);
		}
	} else {
		g_clear_object (&info);
		g_warning ("Loading messageinfo from db failed");
		ret = -1;
	}

	return ret;
}

typedef struct _SaveData {
	CamelFolderSummary *summary;
	const gchar *full_name;
	CamelDB *cdb;
	GError **out_error;
} SaveData;

static void
save_to_db_cb (gpointer key,
               gpointer value,
               gpointer user_data)
{
	CamelMessageInfo *mi = value;
	CamelMIRecord *mir;
	GString *bdata_str;
	SaveData *dt = user_data;

	g_return_if_fail (dt != NULL);

	if (!camel_message_info_get_dirty (mi))
		return;

	mir = g_new0 (CamelMIRecord, 1);
	bdata_str = g_string_new (NULL);

	if (!camel_message_info_save (mi, mir, bdata_str)) {
		g_warning ("Failed to save message info: %s\n", camel_message_info_get_uid (mi));
		g_string_free (bdata_str, TRUE);
		camel_db_camel_mir_free (mir);
		return;
	}

	g_warn_if_fail (mir->bdata == NULL);
	mir->bdata = g_string_free (bdata_str, FALSE);
	bdata_str = NULL;

	if (camel_db_write_message_info_record (dt->cdb, dt->full_name, mir, dt->out_error) != 0) {
		camel_db_camel_mir_free (mir);
		return;
	}

	/* Reset the dirty flag which decides if the changes are synced to the DB or not.
	The FOLDER_FLAGGED should be used to check if the changes are synced to the server.
	So, dont unset the FOLDER_FLAGGED flag */
	camel_message_info_set_dirty (mi, FALSE);

	camel_db_camel_mir_free (mir);
}

static gint
save_message_infos_to_db (CamelFolderSummary *summary,
                          GError **error)
{
	CamelStore *parent_store;
	CamelDB *cdb;
	const gchar *full_name;
	SaveData dt;

	if (is_in_memory_summary (summary))
		return 0;

	full_name = camel_folder_get_full_name (summary->priv->folder);
	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store)
		return 0;

	cdb = camel_store_get_db (parent_store);

	if (camel_db_prepare_message_info_table (cdb, full_name, error) != 0)
		return -1;

	camel_folder_summary_lock (summary);

	dt.summary = summary;
	dt.full_name = full_name;
	dt.cdb = cdb;
	dt.out_error = error;

	/* Push MessageInfo-es */
	camel_db_begin_transaction (cdb, NULL);
	g_hash_table_foreach (summary->priv->loaded_infos, save_to_db_cb, &dt);
	camel_db_end_transaction (cdb, NULL);

	camel_folder_summary_unlock (summary);
	cfs_schedule_info_release_timer (summary);

	return 0;
}

/**
 * camel_folder_summary_save:
 * @summary: a #CamelFolderSummary
 * @error: return location for a #GError, or %NULL
 *
 * Saves the content of the @summary to disk. It does nothing,
 * when the summary is not changed or when it doesn't support
 * permanent save.
 *
 * Returns: whether succeeded
 *
 * Since: 3.24
 **/
gboolean
camel_folder_summary_save (CamelFolderSummary *summary,
			   GError **error)
{
	CamelFolderSummaryClass *klass;
	CamelStore *parent_store;
	CamelDB *cdb;
	CamelFIRecord *record;
	gint ret, count;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->summary_header_save != NULL, FALSE);

	if (!(summary->priv->flags & CAMEL_FOLDER_SUMMARY_DIRTY) ||
	    is_in_memory_summary (summary))
		return TRUE;

	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store)
		return FALSE;

	cdb = camel_store_get_db (parent_store);

	camel_folder_summary_lock (summary);

	d (printf ("\ncamel_folder_summary_save called \n"));

	summary->priv->flags &= ~CAMEL_FOLDER_SUMMARY_DIRTY;

	count = cfs_count_dirty (summary);
	if (!count) {
		gboolean res = camel_folder_summary_header_save (summary, error);
		camel_folder_summary_unlock (summary);
		return res;
	}

	ret = save_message_infos_to_db (summary, error);
	if (ret != 0) {
		/* Failed, so lets reset the flag */
		summary->priv->flags |= CAMEL_FOLDER_SUMMARY_DIRTY;
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	/* XXX So... if an error is set, how do we even reach this point
	 *     given the above error check?  Oye vey this logic is nasty. */
	if (error != NULL && *error != NULL &&
		strstr ((*error)->message, "26 columns but 28 values") != NULL) {
		const gchar *full_name;

		full_name = camel_folder_get_full_name (summary->priv->folder);
		g_warning ("Fixing up a broken summary migration on '%s : %s'\n",
			camel_service_get_display_name (CAMEL_SERVICE (parent_store)), full_name);

		/* Begin everything again. */
		camel_db_begin_transaction (cdb, NULL);
		camel_db_reset_folder_version (cdb, full_name, 0, NULL);
		camel_db_end_transaction (cdb, NULL);

		ret = save_message_infos_to_db (summary, error);
		if (ret != 0) {
			summary->priv->flags |= CAMEL_FOLDER_SUMMARY_DIRTY;
			camel_folder_summary_unlock (summary);
			return FALSE;
		}
	}

	record = klass->summary_header_save (summary, error);
	if (!record) {
		summary->priv->flags |= CAMEL_FOLDER_SUMMARY_DIRTY;
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	camel_db_begin_transaction (cdb, NULL);
	ret = camel_db_write_folder_info_record (cdb, record, error);
	g_free (record->folder_name);
	g_free (record->bdata);
	g_free (record);

	if (ret != 0) {
		camel_db_abort_transaction (cdb, NULL);
		summary->priv->flags |= CAMEL_FOLDER_SUMMARY_DIRTY;
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	camel_db_end_transaction (cdb, NULL);
	camel_folder_summary_unlock (summary);

	return ret == 0;
}

/**
 * camel_folder_summary_header_save:
 * @summary: a #CamelFolderSummary
 * @error: return location for a #GError, or %NULL
 *
 * Saves summary header information into the disk. The function does
 * nothing, if the summary doesn't support save to disk.
 *
 * Returns: whether succeeded
 *
 * Since: 3.24
 **/
gboolean
camel_folder_summary_header_save (CamelFolderSummary *summary,
				  GError **error)
{
	CamelFolderSummaryClass *klass;
	CamelStore *parent_store;
	CamelFIRecord *record;
	CamelDB *cdb;
	gint ret;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->summary_header_save != NULL, FALSE);

	if (is_in_memory_summary (summary))
		return TRUE;

	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store)
		return FALSE;

	cdb = camel_store_get_db (parent_store);
	camel_folder_summary_lock (summary);

	d (printf ("\ncamel_folder_summary_header_save called \n"));

	record = klass->summary_header_save (summary, error);
	if (!record) {
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	camel_db_begin_transaction (cdb, NULL);
	ret = camel_db_write_folder_info_record (cdb, record, error);
	g_free (record->folder_name);
	g_free (record->bdata);
	g_free (record);

	if (ret != 0) {
		camel_db_abort_transaction (cdb, NULL);
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	camel_db_end_transaction (cdb, NULL);
	camel_folder_summary_unlock (summary);

	return ret == 0;
}

/**
 * camel_folder_summary_header_load:
 * @summary: a #CamelFolderSummary
 * @store: a #CamelStore
 * @folder_name: a folder name corresponding to @summary
 * @error: return location for a #GError, or %NULL
 *
 * Loads a summary header for the @summary, which corresponds to @folder_name
 * provided by @store.
 *
 * Returns: whether succeeded
 *
 * Since: 3.24
 **/
gboolean
camel_folder_summary_header_load (CamelFolderSummary *summary,
				  CamelStore *store,
				  const gchar *folder_name,
				  GError **error)
{
	CamelFolderSummaryClass *klass;
	CamelDB *cdb;
	CamelFIRecord *record;
	gboolean ret = FALSE;

	d (printf ("\ncamel_folder_summary_header_load called \n"));

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->summary_header_load != NULL, FALSE);

	if (is_in_memory_summary (summary))
		return TRUE;

	camel_folder_summary_lock (summary);
	camel_folder_summary_save (summary, NULL);

	cdb = camel_store_get_db (store);

	record = g_new0 (CamelFIRecord, 1);
	camel_db_read_folder_info_record (cdb, folder_name, record, error);

	ret = klass->summary_header_load (summary, record);

	camel_folder_summary_unlock (summary);

	g_free (record->folder_name);
	g_free (record->bdata);
	g_free (record);

	return ret;
}

static gboolean
summary_assign_uid (CamelFolderSummary *summary,
                    CamelMessageInfo *info)
{
	const gchar *info_uid;
	gchar *new_uid;
	CamelMessageInfo *mi;

	camel_message_info_set_abort_notifications (info, TRUE);
	camel_message_info_property_lock (info);

	info_uid = camel_message_info_get_uid (info);

	if (!info_uid || !*info_uid) {
		new_uid = camel_folder_summary_next_uid_string (summary);

		camel_message_info_set_uid (info, new_uid);
	} else {
		new_uid = g_strdup (info_uid);
	}

	camel_folder_summary_lock (summary);

	while ((mi = g_hash_table_lookup (summary->priv->loaded_infos, new_uid))) {
		camel_folder_summary_unlock (summary);

		g_free (new_uid);

		if (mi == info) {
			camel_message_info_property_unlock (info);
			return FALSE;
		}

		d (printf ("Trying to insert message with clashing uid (%s).  new uid re-assigned", camel_message_info_get_uid (info)));

		new_uid = camel_folder_summary_next_uid_string (summary);
		camel_message_info_set_uid (info, new_uid);
		camel_message_info_set_folder_flagged (info, TRUE);

		camel_folder_summary_lock (summary);
	}

	g_free (new_uid);

	camel_folder_summary_unlock (summary);

	camel_message_info_property_unlock (info);
	camel_message_info_set_abort_notifications (info, FALSE);

	return TRUE;
}

/**
 * camel_folder_summary_add:
 * @summary: a #CamelFolderSummary object
 * @info: a #CamelMessageInfo
 * @force_keep_uid: whether to keep set UID of the @info
 *
 * Adds a new @info record to the summary. If the @force_keep_uid is %FALSE,
 * then a new uid is automatically re-assigned by calling
 * camel_folder_summary_next_uid_string(). It's an error to use
 * @force_keep_uid when the @info has none set.
 *
 * The @summary adds its own reference to @info, if needed, and any
 * previously loaded info is replaced with the new one.
 **/
void
camel_folder_summary_add (CamelFolderSummary *summary,
                          CamelMessageInfo *info,
			  gboolean force_keep_uid)
{
	CamelMessageInfo *loaded_info;

	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	if (!info)
		return;

	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (info));

	camel_folder_summary_lock (summary);
	if (!force_keep_uid && !summary_assign_uid (summary, info)) {
		camel_folder_summary_unlock (summary);
		return;
	}

	if (force_keep_uid) {
		const gchar *uid;

		uid = camel_message_info_get_uid (info);
		if (!uid || !*uid) {
			g_warning ("%s: Cannot add message info without UID, when disabled to assign new UID; skipping it", G_STRFUNC);
			camel_folder_summary_unlock (summary);
			return;
		}
	}

	folder_summary_update_counts_by_flags (summary, camel_message_info_get_flags (info), UPDATE_COUNTS_ADD);
	camel_message_info_set_folder_flagged (info, TRUE);
	camel_message_info_set_dirty (info, TRUE);

	g_hash_table_insert (
		summary->priv->uids,
		(gpointer) camel_pstring_strdup (camel_message_info_get_uid (info)),
		GUINT_TO_POINTER (camel_message_info_get_flags (info)));

	/* Summary always holds a ref for the loaded infos */
	g_object_ref (info);

	loaded_info = g_hash_table_lookup (summary->priv->loaded_infos, camel_message_info_get_uid (info));
	if (loaded_info) {
		/* Dirty hack, to have CamelWeakRefGroup properly cleared,
		   when the message info leaks due to ref/unref imbalance. */
		_camel_message_info_unset_summary (loaded_info);

		g_clear_object (&loaded_info);
	}

	g_hash_table_insert (summary->priv->loaded_infos, (gpointer) camel_message_info_get_uid (info), info);

	camel_folder_summary_touch (summary);

	camel_folder_summary_unlock (summary);
}

/**
 * camel_folder_summary_info_new_from_headers:
 * @summary: a #CamelFolderSummary object
 * @headers: rfc822 headers as #CamelNameValueArray
 *
 * Create a new info record from a header.
 *
 * Returns: (transfer full): a newly created #CamelMessageInfo. Unref it
 *   with g_object_unref(), when done with it.
 *
 * Since: 3.24
 **/
CamelMessageInfo *
camel_folder_summary_info_new_from_headers (CamelFolderSummary *summary,
					    const CamelNameValueArray *headers)
{
	CamelFolderSummaryClass *class;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	class = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->message_info_new_from_headers != NULL, NULL);

	return class->message_info_new_from_headers (summary, headers);
}

/**
 * camel_folder_summary_info_new_from_parser:
 * @summary: a #CamelFolderSummary object
 * @parser: a #CamelMimeParser object
 *
 * Create a new info record from a parser.  If the parser cannot
 * determine a uid, then none will be assigned.
 *
 * If indexing is enabled, and the parser cannot determine a new uid, then
 * one is automatically assigned.
 *
 * If indexing is enabled, then the content will be indexed based
 * on this new uid.  In this case, the message info MUST be
 * added using :add().
 *
 * Once complete, the parser will be positioned at the end of
 * the message.
 *
 * Returns: (transfer full): a newly created #CamelMessageInfo. Unref it
 *   with g_object_unref(), when done with it.
 **/
CamelMessageInfo *
camel_folder_summary_info_new_from_parser (CamelFolderSummary *summary,
                                           CamelMimeParser *mp)
{
	CamelFolderSummaryClass *klass;
	CamelMessageInfo *info = NULL;
	gchar *buffer;
	gsize len;
	goffset start;
	CamelIndexName *name = NULL;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_PARSER (mp), NULL);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->message_info_new_from_parser, NULL);

	/* should this check the parser is in the right state, or assume it is?? */

	start = camel_mime_parser_tell (mp);
	if (camel_mime_parser_step (mp, &buffer, &len) != CAMEL_MIME_PARSER_STATE_EOF) {
		info = klass->message_info_new_from_parser (summary, mp);

		camel_mime_parser_unstep (mp);

		/* assign a unique uid, this is slightly 'wrong' as we do not really
		 * know if we are going to store this in the summary, but no matter */
		if (summary->priv->index)
			summary_assign_uid (summary, info);

		g_rec_mutex_lock (&summary->priv->filter_lock);

		if (summary->priv->index) {
			if (!summary->priv->filter_index)
				summary->priv->filter_index = camel_mime_filter_index_new (summary->priv->index);
			camel_index_delete_name (summary->priv->index, camel_message_info_get_uid (info));
			name = camel_index_add_name (summary->priv->index, camel_message_info_get_uid (info));
			camel_mime_filter_index_set_name (CAMEL_MIME_FILTER_INDEX (summary->priv->filter_index), name);
		}

		/* always scan the content info, even if we dont save it */
		summary_traverse_content_with_parser (summary, info, mp);

		if (name && summary->priv->index) {
			camel_index_write_name (summary->priv->index, name);
			g_object_unref (name);
			camel_mime_filter_index_set_name (CAMEL_MIME_FILTER_INDEX (summary->priv->filter_index), NULL);
		}

		g_rec_mutex_unlock (&summary->priv->filter_lock);

		camel_message_info_set_size (info, camel_mime_parser_tell (mp) - start);
	}

	return info;
}

/**
 * camel_folder_summary_info_new_from_message:
 * @summary: a #CamelFolderSummary object
 * @message: a #CamelMimeMessage object
 *
 * Create a summary item from a message.
 *
 * Returns: (transfer full): a newly created #CamelMessageInfo. Unref it
 *   with g_object_unref(), when done with it.
 **/
CamelMessageInfo *
camel_folder_summary_info_new_from_message (CamelFolderSummary *summary,
                                            CamelMimeMessage *msg)
{
	CamelFolderSummaryClass *klass;
	CamelMessageInfo *info;
	CamelIndexName *name = NULL;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (msg), NULL);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->message_info_new_from_message != NULL, NULL);

	info = klass->message_info_new_from_message (summary, msg);

	/* assign a unique uid, this is slightly 'wrong' as we do not really
	 * know if we are going to store this in the summary, but we need it set for indexing */
	if (summary->priv->index)
		summary_assign_uid (summary, info);

	g_rec_mutex_lock (&summary->priv->filter_lock);

	if (summary->priv->index) {
		if (summary->priv->filter_index == NULL)
			summary->priv->filter_index = camel_mime_filter_index_new (summary->priv->index);
		camel_index_delete_name (summary->priv->index, camel_message_info_get_uid (info));
		name = camel_index_add_name (summary->priv->index, camel_message_info_get_uid (info));
		camel_mime_filter_index_set_name (CAMEL_MIME_FILTER_INDEX (summary->priv->filter_index), name);

		if (!summary->priv->filter_stream) {
			CamelStream *null = camel_stream_null_new ();

			summary->priv->filter_stream = camel_stream_filter_new (null);
			g_object_unref (null);
		}
	}

	summary_traverse_content_with_part (summary, info, (CamelMimePart *) msg);

	if (name) {
		camel_index_write_name (summary->priv->index, name);
		g_object_unref (name);
		camel_mime_filter_index_set_name (CAMEL_MIME_FILTER_INDEX (summary->priv->filter_index), NULL);
	}

	g_rec_mutex_unlock (&summary->priv->filter_lock);

	return info;
}

/**
 * camel_folder_summary_touch:
 * @summary: a #CamelFolderSummary object
 *
 * Mark the summary as changed, so that a save will force it to be
 * written back to disk.
 **/
void
camel_folder_summary_touch (CamelFolderSummary *summary)
{
	camel_folder_summary_lock (summary);
	summary->priv->flags |= CAMEL_FOLDER_SUMMARY_DIRTY;
	camel_folder_summary_unlock (summary);
}

/**
 * camel_folder_summary_clear:
 * @summary: a #CamelFolderSummary object
 * @error: return location for a #GError, or %NULL
 *
 * Empty the summary contents.
 *
 * Returns: whether succeeded
 **/
gboolean
camel_folder_summary_clear (CamelFolderSummary *summary,
                            GError **error)
{
	GObject *summary_object;
	CamelStore *parent_store;
	CamelDB *cdb;
	const gchar *folder_name;
	gboolean res;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);

	camel_folder_summary_lock (summary);
	if (camel_folder_summary_count (summary) == 0) {
		camel_folder_summary_unlock (summary);
		return TRUE;
	}

	g_hash_table_remove_all (summary->priv->uids);
	remove_all_loaded (summary);
	g_hash_table_remove_all (summary->priv->loaded_infos);

	summary->priv->saved_count = 0;
	summary->priv->unread_count = 0;
	summary->priv->deleted_count = 0;
	summary->priv->junk_count = 0;
	summary->priv->junk_not_deleted_count = 0;
	summary->priv->visible_count = 0;

	camel_folder_summary_touch (summary);

	folder_name = camel_folder_get_full_name (summary->priv->folder);
	parent_store = camel_folder_get_parent_store (summary->priv->folder);
	if (!parent_store) {
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	cdb = camel_store_get_db (parent_store);

	if (!is_in_memory_summary (summary))
		res = camel_db_clear_folder_summary (cdb, folder_name, error) == 0;
	else
		res = TRUE;

	summary_object = G_OBJECT (summary);
	g_object_freeze_notify (summary_object);
	g_object_notify (summary_object, "saved-count");
	g_object_notify (summary_object, "unread-count");
	g_object_notify (summary_object, "deleted-count");
	g_object_notify (summary_object, "junk-count");
	g_object_notify (summary_object, "junk-not-deleted-count");
	g_object_notify (summary_object, "visible-count");
	g_object_thaw_notify (summary_object);

	camel_folder_summary_unlock (summary);

	return res;
}

/**
 * camel_folder_summary_remove:
 * @summary: a #CamelFolderSummary object
 * @info: a #CamelMessageInfo
 *
 * Remove a specific @info record from the summary.
 *
 * Returns: Whether the @info was found and removed from the @summary.
 **/
gboolean
camel_folder_summary_remove (CamelFolderSummary *summary,
                             CamelMessageInfo *info)
{
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (info != NULL, FALSE);

	return camel_folder_summary_remove_uid (summary, camel_message_info_get_uid (info));
}

/**
 * camel_folder_summary_remove_uid:
 * @summary: a #CamelFolderSummary object
 * @uid: a uid
 *
 * Remove a specific info record from the summary, by @uid.
 *
 * Returns: Whether the @uid was found and removed from the @summary.
 **/
gboolean
camel_folder_summary_remove_uid (CamelFolderSummary *summary,
                                 const gchar *uid)
{
	gpointer ptr_uid = NULL, ptr_flags = NULL;
	CamelMessageInfo *mi;
	CamelStore *parent_store;
	const gchar *full_name;
	const gchar *uid_copy;
	gboolean res = TRUE;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	camel_folder_summary_lock (summary);
	if (!g_hash_table_lookup_extended (summary->priv->uids, uid, &ptr_uid, &ptr_flags)) {
		camel_folder_summary_unlock (summary);
		return FALSE;
	}

	folder_summary_update_counts_by_flags (summary, GPOINTER_TO_UINT (ptr_flags), UPDATE_COUNTS_SUB);

	uid_copy = camel_pstring_strdup (uid);
	g_hash_table_remove (summary->priv->uids, uid_copy);

	mi = g_hash_table_lookup (summary->priv->loaded_infos, uid_copy);
	g_hash_table_remove (summary->priv->loaded_infos, uid_copy);

	if (mi) {
		/* Dirty hack, to have CamelWeakRefGroup properly cleared,
		   when the message info leaks due to ref/unref imbalance. */
		_camel_message_info_unset_summary (mi);

		g_clear_object (&mi);
	}

	if (!is_in_memory_summary (summary)) {
		full_name = camel_folder_get_full_name (summary->priv->folder);
		parent_store = camel_folder_get_parent_store (summary->priv->folder);
		if (!parent_store || camel_db_delete_uid (camel_store_get_db (parent_store), full_name, uid_copy, NULL) != 0)
			res = FALSE;
	}

	camel_pstring_free (uid_copy);

	camel_folder_summary_touch (summary);
	camel_folder_summary_unlock (summary);

	return res;
}

/**
 * camel_folder_summary_remove_uids:
 * @summary: a #CamelFolderSummary object
 * @uids: (element-type utf8): a GList of uids
 *
 * Remove a specific info record from the summary, by @uid.
 *
 * Returns: Whether the @uid was found and removed from the @summary.
 *
 * Since: 3.6
 **/
gboolean
camel_folder_summary_remove_uids (CamelFolderSummary *summary,
                                  GList *uids)
{
	CamelStore *parent_store;
	const gchar *full_name;
	GList *l;
	gboolean res = TRUE;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	g_object_freeze_notify (G_OBJECT (summary));
	camel_folder_summary_lock (summary);

	for (l = g_list_first (uids); l; l = g_list_next (l)) {
		gpointer ptr_uid = NULL, ptr_flags = NULL;
		if (g_hash_table_lookup_extended (summary->priv->uids, l->data, &ptr_uid, &ptr_flags)) {
			const gchar *uid_copy = camel_pstring_strdup (l->data);
			CamelMessageInfo *mi;

			folder_summary_update_counts_by_flags (summary, GPOINTER_TO_UINT (ptr_flags), UPDATE_COUNTS_SUB);
			g_hash_table_remove (summary->priv->uids, uid_copy);

			mi = g_hash_table_lookup (summary->priv->loaded_infos, uid_copy);
			g_hash_table_remove (summary->priv->loaded_infos, uid_copy);

			if (mi) {
				/* Dirty hack, to have CamelWeakRefGroup properly cleared,
				   when the message info leaks due to ref/unref imbalance. */
				_camel_message_info_unset_summary (mi);
				g_clear_object (&mi);
			}

			camel_pstring_free (uid_copy);
		}
	}

	if (!is_in_memory_summary (summary)) {
		full_name = camel_folder_get_full_name (summary->priv->folder);
		parent_store = camel_folder_get_parent_store (summary->priv->folder);
		if (!parent_store || camel_db_delete_uids (camel_store_get_db (parent_store), full_name, uids, NULL) != 0)
			res = FALSE;
	}

	camel_folder_summary_touch (summary);
	camel_folder_summary_unlock (summary);
	g_object_thaw_notify (G_OBJECT (summary));

	return res;
}

/* are these even useful for anything??? */
static CamelMessageInfo *
message_info_new_from_parser (CamelFolderSummary *summary,
                              CamelMimeParser *mp)
{
	CamelFolderSummaryClass *klass;
	CamelMessageInfo *mi = NULL;
	CamelNameValueArray *headers;
	gint state;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->message_info_new_from_headers != NULL, NULL);

	state = camel_mime_parser_state (mp);
	switch (state) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		headers = camel_mime_parser_dup_headers (mp);
		mi = klass->message_info_new_from_headers (summary, headers);
		camel_name_value_array_free (headers);
		break;
	default:
		g_error ("Invalid parser state");
	}

	return mi;
}

static CamelMessageInfo *
message_info_new_from_message (CamelFolderSummary *summary,
                               CamelMimeMessage *msg)
{
	CamelFolderSummaryClass *klass;

	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->message_info_new_from_headers != NULL, NULL);

	return klass->message_info_new_from_headers (summary, camel_medium_get_headers (CAMEL_MEDIUM (msg)));
}

static gchar *
summary_format_address (const CamelNameValueArray *headers,
                        const gchar *name,
                        const gchar *charset)
{
	CamelHeaderAddress *addr = NULL;
	gchar *text = NULL, *str = NULL;
	const gchar *value;

	value = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, name);
	if (!value)
		return NULL;

	while (*value && g_ascii_isspace (*value))
		value++;

	text = camel_header_unfold (value);

	if ((addr = camel_header_address_decode (text, charset))) {
		str = camel_header_address_list_format (addr);
		camel_header_address_list_clear (&addr);
		g_free (text);
	} else {
		str = text;
	}

	return str;
}

static gchar *
summary_format_string (const CamelNameValueArray *headers,
                       const gchar *name,
                       const gchar *charset)
{
	gchar *text, *str;
	const gchar *value;

	value = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, name);
	if (!value)
		return NULL;

	while (*value && g_ascii_isspace (*value))
		value++;

	text = camel_header_unfold (value);
	str = camel_header_decode_string (text, charset);
	g_free (text);

	return str;
}

static CamelMessageInfo *
message_info_new_from_headers (CamelFolderSummary *summary,
			       const CamelNameValueArray *headers)
{
	const gchar *received, *date, *content, *charset = NULL;
	GSList *refs, *irt, *scan;
	gchar *subject, *from, *to, *cc, *mlist;
	CamelContentType *ct = NULL;
	CamelMessageInfo *mi;
	guint8 *digest;
	gsize length;
	gchar *msgid;
	guint count;

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	mi = camel_message_info_new (summary);

	camel_message_info_set_abort_notifications (mi, TRUE);

	if ((content = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Type"))
	     && (ct = camel_content_type_decode (content))
	     && (charset = camel_content_type_param (ct, "charset"))
	     && (g_ascii_strcasecmp (charset, "us-ascii") == 0))
		charset = NULL;

	charset = charset ? camel_iconv_charset_name (charset) : NULL;

	subject = summary_format_string (headers, "subject", charset);
	from = summary_format_address (headers, "from", charset);
	to = summary_format_address (headers, "to", charset);
	cc = summary_format_address (headers, "cc", charset);
	mlist = camel_headers_dup_mailing_list (headers);

	camel_message_info_set_subject (mi, subject);
	camel_message_info_set_from (mi, from);
	camel_message_info_set_to (mi, to);
	camel_message_info_set_cc (mi, cc);
	camel_message_info_set_mlist (mi, mlist);

	g_free (subject);
	g_free (from);
	g_free (to);
	g_free (cc);
	g_free (mlist);

	if ((date = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Date")))
		camel_message_info_set_date_sent (mi, camel_header_decode_date (date, NULL));
	else
		camel_message_info_set_date_sent (mi, 0);

	received = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Received");
	if (received)
		received = strrchr (received, ';');
	if (received)
		camel_message_info_set_date_received (mi, camel_header_decode_date (received + 1, NULL));
	else
		camel_message_info_set_date_received (mi, 0);

	/* Fallback to Received date, when the Date header is missing */
	if (!camel_message_info_get_date_sent (mi))
		camel_message_info_set_date_sent (mi, camel_message_info_get_date_received (mi));

	/* If neither Received is available, then use the current time. */
	if (!camel_message_info_get_date_sent (mi))
		camel_message_info_set_date_sent (mi, (gint64) time (NULL));

	msgid = camel_header_msgid_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Message-ID"));
	if (msgid) {
		GChecksum *checksum;
		CamelSummaryMessageID message_id;

		checksum = g_checksum_new (G_CHECKSUM_MD5);
		g_checksum_update (checksum, (guchar *) msgid, -1);
		g_checksum_get_digest (checksum, digest, &length);
		g_checksum_free (checksum);

		memcpy (message_id.id.hash, digest, sizeof (message_id.id.hash));
		g_free (msgid);

		camel_message_info_set_message_id (mi, message_id.id.id);
	}

	/* decode our references and in-reply-to headers */
	refs = camel_header_references_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "References"));
	irt = camel_header_references_decode (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "In-Reply-To"));
	if (refs || irt) {
		GArray *references;
		CamelSummaryMessageID message_id;

		if (irt) {
			/* The References field is populated from the "References" and/or "In-Reply-To"
			 * headers. If both headers exist, take the first thing in the In-Reply-To header
			 * that looks like a Message-ID, and append it to the References header. */

			if (refs)
				irt->next = refs;

			refs = irt;
		}

		count = g_slist_length (refs);
		references = g_array_sized_new (FALSE, FALSE, sizeof (guint64), count);

		for (scan = refs; scan != NULL; scan = g_slist_next (scan)) {
			GChecksum *checksum;

			checksum = g_checksum_new (G_CHECKSUM_MD5);
			g_checksum_update (checksum, (guchar *) scan->data, -1);
			g_checksum_get_digest (checksum, digest, &length);
			g_checksum_free (checksum);

			memcpy (message_id.id.hash, digest, sizeof (message_id.id.hash));

			g_array_append_val (references, message_id.id.id);
		}
		g_slist_free_full (refs, g_free);

		camel_message_info_take_references (mi, references);
	}

	content = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-class");

	if ((content && g_ascii_strcasecmp (content, "urn:content-classes:calendarmessage") == 0) ||
	    (ct && camel_content_type_is (ct, "text", "calendar")) ||
	    camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Calendar-Attachment"))
		camel_message_info_set_user_flag (mi, "$has_cal", TRUE);

	if (camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Evolution-Note"))
		camel_message_info_set_user_flag (mi, "$has_note", TRUE);

	if (ct)
		camel_content_type_unref (ct);

	camel_message_info_take_headers (mi, camel_name_value_array_copy (headers));

	camel_message_info_set_abort_notifications (mi, FALSE);

	return mi;
}

static gchar *
next_uid_string (CamelFolderSummary *summary)
{
	return g_strdup_printf ("%u", camel_folder_summary_next_uid (summary));
}

/*
  OK
  Now this is where all the "smarts" happen, where the content info is built,
  and any indexing and what not is performed
*/

/* must have filter_lock before calling this function */
static void
summary_traverse_content_with_parser (CamelFolderSummary *summary,
				      CamelMessageInfo *msginfo,
				      CamelMimeParser *mp)
{
	gint state;
	gsize len;
	gchar *buffer;
	CamelContentType *ct;
	gint enc_id = -1, chr_id = -1, html_id = -1, idx_id = -1;
	CamelMimeFilter *mfc;
	const gchar *calendar_header;

	d (printf ("traversing content\n"));

	/* start of this part */
	state = camel_mime_parser_step (mp, &buffer, &len);

	switch (state) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
		/* check content type for indexing, then read body */
		ct = camel_mime_parser_content_type (mp);
		/* update attachments flag as we go */
		if (camel_content_type_is (ct, "application", "pgp-signature")
#ifdef ENABLE_SMIME
		    || camel_content_type_is (ct, "application", "x-pkcs7-signature")
		    || camel_content_type_is (ct, "application", "pkcs7-signature")
#endif
			)
			camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_SECURE, CAMEL_MESSAGE_SECURE);

		calendar_header = camel_mime_parser_header (mp, "Content-class", NULL);
		if (calendar_header && g_ascii_strcasecmp (calendar_header, "urn:content-classes:calendarmessage") != 0)
			calendar_header = NULL;

		if (!calendar_header)
			calendar_header = camel_mime_parser_header (mp, "X-Calendar-Attachment", NULL);

		if (calendar_header || camel_content_type_is (ct, "text", "calendar"))
			camel_message_info_set_user_flag (msginfo, "$has_cal", TRUE);

		if (camel_mime_parser_header (mp, "X-Evolution-Note", NULL))
			camel_message_info_set_user_flag (msginfo, "$has_note", TRUE);

		if (summary->priv->index && camel_content_type_is (ct, "text", "*")) {
			gchar *encoding;
			const gchar *charset;

			d (printf ("generating index:\n"));

			encoding = camel_content_transfer_encoding_decode (camel_mime_parser_header (mp, "content-transfer-encoding", NULL));
			if (encoding) {
				if (!g_ascii_strcasecmp (encoding, "base64")) {
					d (printf (" decoding base64\n"));
					if (summary->priv->filter_64 == NULL)
						summary->priv->filter_64 = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_BASE64_DEC);
					else
						camel_mime_filter_reset (summary->priv->filter_64);
					enc_id = camel_mime_parser_filter_add (mp, summary->priv->filter_64);
				} else if (!g_ascii_strcasecmp (encoding, "quoted-printable")) {
					d (printf (" decoding quoted-printable\n"));
					if (summary->priv->filter_qp == NULL)
						summary->priv->filter_qp = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_QP_DEC);
					else
						camel_mime_filter_reset (summary->priv->filter_qp);
					enc_id = camel_mime_parser_filter_add (mp, summary->priv->filter_qp);
				} else if (!g_ascii_strcasecmp (encoding, "x-uuencode")) {
					d (printf (" decoding x-uuencode\n"));
					if (summary->priv->filter_uu == NULL)
						summary->priv->filter_uu = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_UU_DEC);
					else
						camel_mime_filter_reset (summary->priv->filter_uu);
					enc_id = camel_mime_parser_filter_add (mp, summary->priv->filter_uu);
				} else {
					d (printf (" ignoring encoding %s\n", encoding));
				}
				g_free (encoding);
			}

			charset = camel_content_type_param (ct, "charset");
			if (charset != NULL
			    && !(g_ascii_strcasecmp (charset, "us-ascii") == 0
				 || g_ascii_strcasecmp (charset, "utf-8") == 0)) {
				d (printf (" Adding conversion filter from %s to UTF-8\n", charset));
				mfc = g_hash_table_lookup (summary->priv->filter_charset, charset);
				if (mfc == NULL) {
					mfc = camel_mime_filter_charset_new (charset, "UTF-8");
					if (mfc)
						g_hash_table_insert (summary->priv->filter_charset, g_strdup (charset), mfc);
				} else {
					camel_mime_filter_reset ((CamelMimeFilter *) mfc);
				}
				if (mfc) {
					chr_id = camel_mime_parser_filter_add (mp, mfc);
				} else {
					w (g_warning ("Cannot convert '%s' to 'UTF-8', message index may be corrupt", charset));
				}
			}

			/* we do charset conversions before this filter, which isn't strictly correct,
			 * but works in most cases */
			if (camel_content_type_is (ct, "text", "html")) {
				if (summary->priv->filter_html == NULL)
					summary->priv->filter_html = camel_mime_filter_html_new ();
				else
					camel_mime_filter_reset ((CamelMimeFilter *) summary->priv->filter_html);
				html_id = camel_mime_parser_filter_add (mp, (CamelMimeFilter *) summary->priv->filter_html);
			}

			/* and this filter actually does the indexing */
			idx_id = camel_mime_parser_filter_add (mp, summary->priv->filter_index);
		}
		/* and scan/index everything */
		while (camel_mime_parser_step (mp, &buffer, &len) != CAMEL_MIME_PARSER_STATE_BODY_END)
			;
		/* and remove the filters */
		camel_mime_parser_filter_remove (mp, enc_id);
		camel_mime_parser_filter_remove (mp, chr_id);
		camel_mime_parser_filter_remove (mp, html_id);
		camel_mime_parser_filter_remove (mp, idx_id);
		break;
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		d (printf ("Summarising multipart\n"));
		/* update attachments flag as we go */
		ct = camel_mime_parser_content_type (mp);
		if (camel_content_type_is (ct, "multipart", "mixed"))
			camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_ATTACHMENTS, CAMEL_MESSAGE_ATTACHMENTS);
		if (camel_content_type_is (ct, "multipart", "signed")
		    || camel_content_type_is (ct, "multipart", "encrypted"))
			camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_SECURE, CAMEL_MESSAGE_SECURE);

		while (camel_mime_parser_step (mp, &buffer, &len) != CAMEL_MIME_PARSER_STATE_MULTIPART_END) {
			camel_mime_parser_unstep (mp);
			summary_traverse_content_with_parser (summary, msginfo, mp);
		}
		break;
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
		d (printf ("Summarising message\n"));
		/* update attachments flag as we go */
		camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_ATTACHMENTS, CAMEL_MESSAGE_ATTACHMENTS);

		summary_traverse_content_with_parser (summary, msginfo, mp);
		state = camel_mime_parser_step (mp, &buffer, &len);
		if (state != CAMEL_MIME_PARSER_STATE_MESSAGE_END) {
			g_error ("Bad parser state: Expecing MESSAGE_END or MESSAGE_EOF, got: %d", state);
			camel_mime_parser_unstep (mp);
		}
		break;
	}

	d (printf ("finished traversion content info\n"));
}

/* build the content-info, from a message */
/* this needs the filter lock since it uses filters to perform indexing */
static void
summary_traverse_content_with_part (CamelFolderSummary *summary,
                                    CamelMessageInfo *msginfo,
                                    CamelMimePart *object)
{
	CamelDataWrapper *containee;
	gint parts, i;
	CamelContentType *ct;
	const CamelNameValueArray *headers;
	gboolean is_calendar = FALSE, is_note = FALSE;
	const gchar *header_name, *header_value;

	containee = camel_medium_get_content (CAMEL_MEDIUM (object));

	if (containee == NULL)
		return;

	/* TODO: I find it odd that get_part and get_content do not
	 * add a reference, probably need fixing for multithreading */

	/* check for attachments */
	ct = camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (containee));
	if (camel_content_type_is (ct, "multipart", "*")) {
		if (camel_content_type_is (ct, "multipart", "mixed"))
			camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_ATTACHMENTS, CAMEL_MESSAGE_ATTACHMENTS);
		if (camel_content_type_is (ct, "multipart", "signed")
		    || camel_content_type_is (ct, "multipart", "encrypted"))
			camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_SECURE, CAMEL_MESSAGE_SECURE);
	} else if (camel_content_type_is (ct, "application", "pgp-signature")
#ifdef ENABLE_SMIME
		    || camel_content_type_is (ct, "application", "x-pkcs7-signature")
		    || camel_content_type_is (ct, "application", "pkcs7-signature")
#endif
		) {
		camel_message_info_set_flags (msginfo, CAMEL_MESSAGE_SECURE, CAMEL_MESSAGE_SECURE);
	}

	headers = camel_medium_get_headers (CAMEL_MEDIUM (object));
	for (i = 0; camel_name_value_array_get (headers, i, &header_name, &header_value); i++) {
		const gchar *value = header_value;

		while (value && *value && g_ascii_isspace (*value))
			value++;

		if (header_name && value && (
		    (g_ascii_strcasecmp (header_name, "Content-class") == 0 && g_ascii_strcasecmp (value, "urn:content-classes:calendarmessage") == 0) ||
		    (g_ascii_strcasecmp (header_name, "X-Calendar-Attachment") == 0))) {
			is_calendar = TRUE;
			if (is_note)
				break;
		}

		if (header_name && value && g_ascii_strcasecmp (header_name, "X-Evolution-Note") == 0) {
			is_note = TRUE;
			if (is_calendar)
				break;
		}
	}

	if (is_calendar || camel_content_type_is (ct, "text", "calendar"))
		camel_message_info_set_user_flag (msginfo, "$has_cal", TRUE);

	if (is_note)
		camel_message_info_set_user_flag (msginfo, "$has_note", TRUE);

	/* using the object types is more accurate than using the mime/types */
	if (CAMEL_IS_MULTIPART (containee)) {
		parts = camel_multipart_get_number (CAMEL_MULTIPART (containee));

		for (i = 0; i < parts; i++) {
			CamelMimePart *part = camel_multipart_get_part (CAMEL_MULTIPART (containee), i);
			g_return_if_fail (part);
			summary_traverse_content_with_part (summary, msginfo, part);
		}
	} else if (CAMEL_IS_MIME_MESSAGE (containee)) {
		/* for messages we only look at its contents */
		summary_traverse_content_with_part (summary, msginfo, (CamelMimePart *) containee);
	} else if (summary->priv->filter_stream
		   && camel_content_type_is (ct, "text", "*")) {
		gint html_id = -1, idx_id = -1;

		/* pre-attach html filter if required, otherwise just index filter */
		if (camel_content_type_is (ct, "text", "html")) {
			if (summary->priv->filter_html == NULL)
				summary->priv->filter_html = camel_mime_filter_html_new ();
			else
				camel_mime_filter_reset ((CamelMimeFilter *) summary->priv->filter_html);
			html_id = camel_stream_filter_add (
				CAMEL_STREAM_FILTER (summary->priv->filter_stream),
				(CamelMimeFilter *) summary->priv->filter_html);
		}
		idx_id = camel_stream_filter_add (
			CAMEL_STREAM_FILTER (summary->priv->filter_stream),
			summary->priv->filter_index);

		/* FIXME Pass a GCancellable and GError here. */
		camel_data_wrapper_decode_to_stream_sync (
			containee, summary->priv->filter_stream, NULL, NULL);
		camel_stream_flush (summary->priv->filter_stream, NULL, NULL);

		camel_stream_filter_remove (
			CAMEL_STREAM_FILTER (summary->priv->filter_stream), idx_id);
		camel_stream_filter_remove (
			CAMEL_STREAM_FILTER (summary->priv->filter_stream), html_id);
	}
}

static struct flag_names_t {
	const gchar *name;
	guint32 value;
} flag_names[] = {
	{ "answered", CAMEL_MESSAGE_ANSWERED },
	{ "deleted", CAMEL_MESSAGE_DELETED },
	{ "draft", CAMEL_MESSAGE_DRAFT },
	{ "flagged", CAMEL_MESSAGE_FLAGGED },
	{ "seen", CAMEL_MESSAGE_SEEN },
	{ "attachments", CAMEL_MESSAGE_ATTACHMENTS },
	{ "junk", CAMEL_MESSAGE_JUNK },
	{ "notjunk", CAMEL_MESSAGE_NOTJUNK },
	{ "secure", CAMEL_MESSAGE_SECURE },
	{ NULL, 0 }
};

/**
 * camel_system_flag:
 * @name: name of a system flag
 *
 * Returns: the integer value of the system flag string
 **/
CamelMessageFlags
camel_system_flag (const gchar *name)
{
	struct flag_names_t *flag;

	g_return_val_if_fail (name != NULL, 0);

	for (flag = flag_names; flag->name; flag++)
		if (!g_ascii_strcasecmp (name, flag->name))
			return flag->value;

	return 0;
}

/**
 * camel_system_flag_get:
 * @flags: bitwise system flags
 * @name: name of the flag to check for
 *
 * Find the state of the flag @name in @flags.
 *
 * Returns: %TRUE if the named flag is set or %FALSE otherwise
 **/
gboolean
camel_system_flag_get (CamelMessageFlags flags,
                       const gchar *name)
{
	g_return_val_if_fail (name != NULL, FALSE);

	return flags & camel_system_flag (name);
}

/**
 * camel_message_info_new_from_headers:
 * @summary: a #CamelFolderSummary object or %NULL
 * @headers: a #CamelNameValueArray
 *
 * Create a new #CamelMessageInfo pre-populated with info from
 * @headers.
 *
 * Returns: (transfer full): a new #CamelMessageInfo
 *
 * Since: 3.24
 **/
CamelMessageInfo *
camel_message_info_new_from_headers (CamelFolderSummary *summary,
				     const CamelNameValueArray *headers)
{
	if (summary != NULL) {
		CamelFolderSummaryClass *klass;

		g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

		klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
		g_return_val_if_fail (klass != NULL, NULL);
		g_return_val_if_fail (klass->message_info_new_from_headers != NULL, NULL);

		return klass->message_info_new_from_headers (summary, headers);
	} else {
		return message_info_new_from_headers (NULL, headers);
	}
}

/**
 * camel_folder_summary_lock:
 * @summary: a #CamelFolderSummary
 *
 * Locks @summary. Unlock it with camel_folder_summary_unlock().
 *
 * Since: 2.32
 **/
void
camel_folder_summary_lock (CamelFolderSummary *summary)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	g_rec_mutex_lock (&summary->priv->summary_lock);
}

/**
 * camel_folder_summary_unlock:
 * @summary: a #CamelFolderSummary
 *
 * Unlocks @summary, previously locked with camel_folder_summary_lock().
 *
 * Since: 2.32
 **/
void
camel_folder_summary_unlock (CamelFolderSummary *summary)
{
	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));

	g_rec_mutex_unlock (&summary->priv->summary_lock);
}
