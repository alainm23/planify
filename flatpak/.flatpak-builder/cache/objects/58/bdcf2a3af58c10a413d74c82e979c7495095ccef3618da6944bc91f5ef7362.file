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
 *	    Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-db.h"
#include "camel-mime-message.h"
#include "camel-store.h"
#include "camel-vee-store.h"
#include "camel-vtrash-folder.h"
#include "camel-string-utils.h"

struct _CamelVTrashFolderPrivate {
	CamelVTrashFolderType type;
	guint32 bit;
};

static struct {
	const gchar *full_name;
	const gchar *name;
	const gchar *expr;
	guint32 bit;
	guint32 flags;
	const gchar *error_copy;
	const gchar *db_col;
} vdata[] = {
	{ CAMEL_VTRASH_NAME, N_("Trash"), "(match-all (system-flag \"Deleted\"))", CAMEL_MESSAGE_DELETED, CAMEL_FOLDER_IS_TRASH,
	  N_("Cannot copy messages to the Trash folder"), "deleted" },
	{ CAMEL_VJUNK_NAME, N_("Junk"), "(match-all (system-flag \"Junk\"))", CAMEL_MESSAGE_JUNK, CAMEL_FOLDER_IS_JUNK,
	  N_("Cannot copy messages to the Junk folder"), "junk" },
};

struct _transfer_data {
	GCancellable *cancellable;
	CamelFolder *folder;
	CamelFolder *dest;
	GPtrArray *uids;
	gboolean delete;

	CamelFolder *source_folder;
	GPtrArray *source_uids;
	guint32 sbit;
};

G_DEFINE_TYPE (CamelVTrashFolder, camel_vtrash_folder, CAMEL_TYPE_VEE_FOLDER)

static void
transfer_messages (CamelFolder *folder,
                   struct _transfer_data *md,
                   GError **error)
{
	gint i;

	camel_folder_transfer_messages_to_sync (
		md->folder, md->uids, md->dest,
		md->delete, NULL, md->cancellable, error);

	if (md->cancellable != NULL)
		g_object_unref (md->cancellable);

	/* set the bit back */
	for (i = 0; i < md->source_uids->len; i++) {
		CamelMessageInfo *mi = camel_folder_get_message_info (md->source_folder, md->source_uids->pdata[i]);
		if (mi) {
			camel_message_info_set_flags (mi, md->sbit, md->sbit);
			g_clear_object (&mi);
		}
	}

	camel_folder_thaw (md->folder);

	for (i = 0; i < md->uids->len; i++)
		g_free (md->uids->pdata[i]);

	g_ptr_array_free (md->uids, TRUE);
	g_ptr_array_free (md->source_uids, TRUE);
	g_object_unref (md->folder);
	g_free (md);
}

static gboolean
vtrash_folder_append_message_sync (CamelFolder *folder,
                                   CamelMimeMessage *message,
                                   CamelMessageInfo *info,
                                   gchar **appended_uid,
                                   GCancellable *cancellable,
                                   GError **error)
{
	g_set_error (
		error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
		_(vdata[((CamelVTrashFolder *) folder)->priv->type].error_copy));

	return FALSE;
}

static gboolean
vtrash_folder_transfer_messages_to_sync (CamelFolder *source,
                                         GPtrArray *uids,
                                         CamelFolder *dest,
                                         gboolean delete_originals,
                                         GPtrArray **transferred_uids,
                                         GCancellable *cancellable,
                                         GError **error)
{
	CamelVeeMessageInfo *mi;
	gint i;
	GHashTable *batch = NULL;
	const gchar *tuid;
	struct _transfer_data *md;
	guint32 sbit = ((CamelVTrashFolder *) source)->priv->bit;

	/* This is a special case of transfer_messages_to: Either the
	 * source or the destination is a vtrash folder (but not both
	 * since a store should never have more than one).
	 */

	if (transferred_uids)
		*transferred_uids = NULL;

	if (CAMEL_IS_VTRASH_FOLDER (dest)) {
		/* Copy to trash is meaningless. */
		if (!delete_originals) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
				_(vdata[((CamelVTrashFolder *) dest)->priv->type].error_copy));
			return FALSE;
		}

		/* Move to trash is the same as setting the message flag */
		for (i = 0; i < uids->len; i++)
			camel_folder_set_message_flags (
				source, uids->pdata[i],
				((CamelVTrashFolder *) dest)->priv->bit, ~0);
		return TRUE;
	}

	/* Moving/Copying from the trash to the original folder = undelete.
	 * Moving/Copying from the trash to a different folder = move/copy.
	 *
	 * Need to check this uid by uid, but we batch up the copies.
	 */

	camel_folder_freeze (source);
	camel_folder_freeze (dest);

	for (i = 0; i < uids->len; i++) {
		mi = (CamelVeeMessageInfo *) camel_folder_get_message_info (source, uids->pdata[i]);
		if (mi == NULL) {
			g_warning ("Cannot find uid %s in source folder during transfer", (gchar *) uids->pdata[i]);
			continue;
		}

		if (dest == camel_vee_message_info_get_original_folder (mi)) {
			/* Just unset the flag on the original message */
			camel_folder_set_message_flags (
				source, uids->pdata[i], sbit, 0);
		} else {
			if (batch == NULL)
				batch = g_hash_table_new (NULL, NULL);
			md = g_hash_table_lookup (batch, camel_vee_message_info_get_original_folder (mi));
			if (md == NULL) {
				md = g_malloc0 (sizeof (*md));
				md->cancellable = cancellable;
				md->folder = g_object_ref (camel_vee_message_info_get_original_folder (mi));
				md->uids = g_ptr_array_new ();
				md->dest = dest;
				md->delete = delete_originals;
				md->source_folder = source;
				md->source_uids = g_ptr_array_new ();
				md->sbit = sbit;
				if (cancellable != NULL)
					g_object_ref (cancellable);
				camel_folder_freeze (md->folder);
				g_hash_table_insert (batch, camel_vee_message_info_get_original_folder (mi), md);
			}

			/* unset the bit temporarily */
			camel_message_info_set_flags ((CamelMessageInfo *) mi, sbit, 0);

			tuid = uids->pdata[i];
			if (strlen (tuid) > 8)
				tuid += 8;
			g_ptr_array_add (md->uids, g_strdup (tuid));
			g_ptr_array_add (md->source_uids, uids->pdata[i]);
		}
		g_clear_object (&mi);
	}

	if (batch) {
		g_hash_table_foreach (batch, (GHFunc) transfer_messages, error);
		g_hash_table_destroy (batch);
	}

	camel_folder_thaw (dest);
	camel_folder_thaw (source);

	return TRUE;
}

static void
camel_vtrash_folder_class_init (CamelVTrashFolderClass *class)
{
	CamelFolderClass *folder_class;

	g_type_class_add_private (class, sizeof (CamelVTrashFolderPrivate));

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->append_message_sync = vtrash_folder_append_message_sync;
	folder_class->transfer_messages_to_sync = vtrash_folder_transfer_messages_to_sync;
}

static void
camel_vtrash_folder_init (CamelVTrashFolder *vtrash_folder)
{
	vtrash_folder->priv = G_TYPE_INSTANCE_GET_PRIVATE (vtrash_folder, CAMEL_TYPE_VTRASH_FOLDER, CamelVTrashFolderPrivate);
}

/**
 * camel_vtrash_folder_new:
 * @parent_store: the parent #CamelVeeStore object
 * @type: type of vfolder, #CAMEL_VTRASH_FOLDER_TRASH or
 * #CAMEL_VTRASH_FOLDER_JUNK currently.
 *
 * Create a new CamelVTrashFolder object.
 *
 * Returns: a new #CamelVTrashFolder object
 **/
CamelFolder *
camel_vtrash_folder_new (CamelStore *parent_store,
                         CamelVTrashFolderType type)
{
	CamelVTrashFolder *vtrash;

	g_return_val_if_fail (type < CAMEL_VTRASH_FOLDER_LAST, NULL);

	vtrash = g_object_new (
		CAMEL_TYPE_VTRASH_FOLDER,
		"full-name", vdata[type].full_name,
		"display-name", gettext (vdata[type].name),
		"parent-store", parent_store, NULL);

	camel_vee_folder_construct (
		CAMEL_VEE_FOLDER (vtrash),
		CAMEL_STORE_FOLDER_PRIVATE |
		CAMEL_STORE_FOLDER_CREATE);

	camel_folder_set_flags (CAMEL_FOLDER (vtrash), camel_folder_get_flags (CAMEL_FOLDER (vtrash)) | vdata[type].flags);
	camel_vee_folder_set_expression ((CamelVeeFolder *) vtrash, vdata[type].expr);
	vtrash->priv->bit = vdata[type].bit;
	vtrash->priv->type = type;

	return (CamelFolder *) vtrash;
}

/**
 * camel_vtrash_folder_get_folder_type:
 * @vtrash_folder: a #CamelVTrashFolder
 *
 * Returns: a @vtrash_folder folder type (#CamelVTrashFolderType)
 *
 * Since: 3.24
 **/
CamelVTrashFolderType
camel_vtrash_folder_get_folder_type (CamelVTrashFolder *vtrash_folder)
{
	g_return_val_if_fail (CAMEL_IS_VTRASH_FOLDER (vtrash_folder), CAMEL_VTRASH_FOLDER_LAST);

	return vtrash_folder->priv->type;
}
