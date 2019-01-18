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

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include "camel-db.h"
#include "camel-debug.h"
#include "camel-folder.h"
#include "camel-store.h"
#include "camel-vee-folder.h"
#include "camel-vee-message-info.h"
#include "camel-vee-store.h"
#include "camel-vtrash-folder.h"
#include "camel-string-utils.h"

#include "camel-vee-summary.h"

#define d(x)

#define CAMEL_VEE_SUMMARY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_VEE_SUMMARY, CamelVeeSummaryPrivate))

struct _CamelVeeSummaryPrivate {
	/* CamelFolder * => GHashTable * of gchar *vuid */
	GHashTable *vuids_by_subfolder;
};

G_DEFINE_TYPE (CamelVeeSummary, camel_vee_summary, CAMEL_TYPE_FOLDER_SUMMARY)

static CamelMessageInfo *
message_info_from_uid (CamelFolderSummary *s,
                       const gchar *uid)
{
	CamelMessageInfo *info;

	info = camel_folder_summary_peek_loaded (s, uid);
	if (!info) {
		CamelFolder *orig_folder;

		/* This function isn't really nice. But no great way
		 * But in vfolder case, this may not be so bad, as vuid has the hash in first 8 bytes.
		 * So this just compares the entire string only if it belongs to the same folder.
		 * Otherwise, the first byte itself would return in strcmp, saving the CPU.
		 */
		if (!camel_folder_summary_check_uid (s, uid)) {
			d (
				g_message ("Unable to find %s in the summary of %s", uid,
				camel_folder_get_full_name (camel_folder_summary_get_folder (s->folder))));
			return NULL;
		}

		orig_folder = camel_vee_folder_get_vee_uid_folder (
			(CamelVeeFolder *) camel_folder_summary_get_folder (s), uid);
		g_return_val_if_fail (orig_folder != NULL, NULL);

		/* Create the info and load it, its so easy. */
		info = camel_vee_message_info_new (s, camel_folder_get_folder_summary (orig_folder), uid);

		camel_message_info_set_dirty (info, FALSE);

		camel_folder_summary_add (s, info, TRUE);
	}

	return info;
}

static void
vee_summary_prepare_fetch_all (CamelFolderSummary *summary)
{
	GHashTableIter iter;
	gpointer key, value;
	CamelVeeSummary *vee_summary;

	g_return_if_fail (CAMEL_IS_VEE_SUMMARY (summary));

	camel_folder_summary_lock (summary);

	vee_summary = CAMEL_VEE_SUMMARY (summary);

	g_hash_table_iter_init (&iter, vee_summary->priv->vuids_by_subfolder);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		CamelFolder *subfolder = key;
		GHashTable *vuids = value;

		if (subfolder && vuids && g_hash_table_size (vuids) > 50) {
			CamelFolderSummary *subsummary;

			subsummary = camel_folder_get_folder_summary (subfolder);
			if (subsummary)
				camel_folder_summary_prepare_fetch_all (subsummary, NULL);
		}
	}

	camel_folder_summary_unlock (summary);
}

static void
vee_summary_finalize (GObject *object)
{
	CamelVeeSummaryPrivate *priv;

	priv = CAMEL_VEE_SUMMARY_GET_PRIVATE (object);

	g_hash_table_destroy (priv->vuids_by_subfolder);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_vee_summary_parent_class)->finalize (object);
}

static void
camel_vee_summary_class_init (CamelVeeSummaryClass *class)
{
	GObjectClass *object_class;
	CamelFolderSummaryClass *folder_summary_class;

	g_type_class_add_private (class, sizeof (CamelVeeSummaryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = vee_summary_finalize;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->message_info_type = CAMEL_TYPE_VEE_MESSAGE_INFO;
	folder_summary_class->message_info_from_uid = message_info_from_uid;
	folder_summary_class->prepare_fetch_all = vee_summary_prepare_fetch_all;
}

static void
camel_vee_summary_init (CamelVeeSummary *vee_summary)
{
	vee_summary->priv = CAMEL_VEE_SUMMARY_GET_PRIVATE (vee_summary);

	vee_summary->priv->vuids_by_subfolder = g_hash_table_new_full (
		(GHashFunc) g_direct_hash,
		(GEqualFunc) g_direct_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) g_hash_table_destroy);
}

/**
 * camel_vee_summary_new:
 * @parent: Folder its attached to.
 *
 * This will create a new CamelVeeSummary object and read in the
 * summary data from disk, if it exists.
 *
 * Returns: A new CamelVeeSummary object.
 **/
CamelFolderSummary *
camel_vee_summary_new (CamelFolder *parent)
{
	CamelFolderSummary *summary;
	CamelStore *parent_store;
	const gchar *full_name;

	summary = g_object_new (CAMEL_TYPE_VEE_SUMMARY, "folder", parent, NULL);
	camel_folder_summary_set_flags (summary, camel_folder_summary_get_flags (summary) | CAMEL_FOLDER_SUMMARY_IN_MEMORY_ONLY);

	/* not using DB for vee folder summaries, drop the table */
	full_name = camel_folder_get_full_name (parent);
	parent_store = camel_folder_get_parent_store (parent);
	camel_db_delete_folder (camel_store_get_db (parent_store), full_name, NULL);

	return summary;
}

static void
get_uids_for_subfolder (gpointer key,
                        gpointer value,
                        gpointer user_data)
{
	g_hash_table_insert (user_data, (gpointer) camel_pstring_strdup (key), GINT_TO_POINTER (1));
}

/**
 * camel_vee_summary_get_uids_for_subfolder:
 * @summary: a #CamelVeeSummary
 * @subfolder: a #CamelFolder
 *
 * Returns a hash table of all virtual message info UID-s known to the @summary.
 * The key of the hash table is the virtual message info UID, the value is
 * only the number 1.
 *
 * Returns: (element-type utf8 gint) (transfer container): a #GHashTable with
 *    all the virtual mesasge info UID-s knwn to the @summary.
 *
 * Since: 3.6
 **/
GHashTable *
camel_vee_summary_get_uids_for_subfolder (CamelVeeSummary *summary,
                                          CamelFolder *subfolder)
{
	GHashTable *vuids, *known_uids;

	g_return_val_if_fail (CAMEL_IS_VEE_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_FOLDER (subfolder), NULL);

	camel_folder_summary_lock (CAMEL_FOLDER_SUMMARY (summary));

	/* uses direct hash, because strings are supposed to be from the string pool */
	known_uids = g_hash_table_new_full (g_direct_hash, g_direct_equal, (GDestroyNotify) camel_pstring_free, NULL);

	vuids = g_hash_table_lookup (summary->priv->vuids_by_subfolder, subfolder);
	if (vuids) {
		g_hash_table_foreach (vuids, get_uids_for_subfolder, known_uids);
	}

	camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));

	return known_uids;
}

/**
 * camel_vee_summary_add:
 * @summary: the CamelVeeSummary
 * @mi_data: (type CamelVeeMessageInfoData): the #CamelVeeMessageInfoData to add
 *
 * Unref returned pointer with g_object_unref()
 *
 * Returns: (transfer full): A new #CamelVeeMessageInfo object.
 **/
CamelVeeMessageInfo *
camel_vee_summary_add (CamelVeeSummary *summary,
                       CamelVeeMessageInfoData *mi_data)
{
	CamelVeeMessageInfo *vmi;
	const gchar *vuid;
	CamelVeeSubfolderData *sf_data;
	CamelFolder *orig_folder;
	GHashTable *vuids;

	g_return_val_if_fail (CAMEL_IS_VEE_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO_DATA (mi_data), NULL);

	camel_folder_summary_lock (CAMEL_FOLDER_SUMMARY (summary));

	sf_data = camel_vee_message_info_data_get_subfolder_data (mi_data);
	vuid = camel_vee_message_info_data_get_vee_message_uid (mi_data);
	orig_folder = camel_vee_subfolder_data_get_folder (sf_data);

	vmi = (CamelVeeMessageInfo *) camel_folder_summary_peek_loaded (CAMEL_FOLDER_SUMMARY (summary), vuid);
	if (vmi) {
		/* Possible that the entry is loaded, see if it has the summary */
		d (g_message ("%s - already there\n", vuid));
		g_warn_if_fail (camel_vee_message_info_get_original_summary (vmi) != NULL);

		camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));

		return vmi;
	}

	vmi = (CamelVeeMessageInfo *) camel_vee_message_info_new (CAMEL_FOLDER_SUMMARY (summary), camel_folder_get_folder_summary (orig_folder), vuid);

	vuids = g_hash_table_lookup (summary->priv->vuids_by_subfolder, orig_folder);
	if (vuids) {
		g_hash_table_insert (vuids, (gpointer) camel_pstring_strdup (vuid), GINT_TO_POINTER (1));
	} else {
		vuids = g_hash_table_new_full (g_direct_hash, g_direct_equal, (GDestroyNotify) camel_pstring_free, NULL);
		g_hash_table_insert (vuids, (gpointer) camel_pstring_strdup (vuid), GINT_TO_POINTER (1));
		g_hash_table_insert (summary->priv->vuids_by_subfolder, orig_folder, vuids);
	}

	camel_folder_summary_add (CAMEL_FOLDER_SUMMARY (summary), (CamelMessageInfo *) vmi, TRUE);
	camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));

	return vmi;
}

/**
 * camel_vee_summary_remove:
 * @summary: a #CamelVeeSummary
 * @vuid: a virtual message info UID to remove
 * @subfolder: a #CamelFolder to which @vuid belongs
 *
 * Removes the given @vuid of the @subfolder from the @summary.
 *
 * Since: 3.6
 **/
void
camel_vee_summary_remove (CamelVeeSummary *summary,
                          const gchar *vuid,
                          CamelFolder *subfolder)
{
	GHashTable *vuids;

	g_return_if_fail (CAMEL_IS_VEE_SUMMARY (summary));
	g_return_if_fail (vuid != NULL);
	g_return_if_fail (subfolder != NULL);

	camel_folder_summary_lock (CAMEL_FOLDER_SUMMARY (summary));

	vuids = g_hash_table_lookup (summary->priv->vuids_by_subfolder, subfolder);
	if (vuids) {
		g_hash_table_remove (vuids, vuid);
		if (!g_hash_table_size (vuids))
			g_hash_table_remove (summary->priv->vuids_by_subfolder, subfolder);
	}

	camel_folder_summary_remove_uid (CAMEL_FOLDER_SUMMARY (summary), vuid);

	camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));
}

/**
 * camel_vee_summary_replace_flags:
 * @summary: a #CamelVeeSummary
 * @uid: a message UID to update flags for
 *
 * Makes sure @summary flags on @uid corresponds to those 
 * in the subfolder of vee-folder, and updates internal counts
 * on @summary as well.
 *
 * Since: 3.6
 **/
void
camel_vee_summary_replace_flags (CamelVeeSummary *summary,
                                 const gchar *uid)
{
	CamelMessageInfo *mi;

	g_return_if_fail (CAMEL_IS_VEE_SUMMARY (summary));
	g_return_if_fail (uid != NULL);

	camel_folder_summary_lock (CAMEL_FOLDER_SUMMARY (summary));

	mi = camel_folder_summary_get (CAMEL_FOLDER_SUMMARY (summary), uid);
	if (!mi) {
		camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));
		return;
	}

	camel_folder_summary_replace_flags (CAMEL_FOLDER_SUMMARY (summary), mi);
	g_clear_object (&mi);

	camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (summary));
}
