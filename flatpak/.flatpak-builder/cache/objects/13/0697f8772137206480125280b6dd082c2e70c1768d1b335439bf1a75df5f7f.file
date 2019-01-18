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

#include <string.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-db.h"
#include "camel-session.h"
#include "camel-string-utils.h"
#include "camel-vee-folder.h"
#include "camel-vee-store.h"

#define CAMEL_VEE_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_VEE_STORE, CamelVeeStorePrivate))

/* Translators: 'Unmatched' is a folder name under Search folders where are shown
 * all messages not belonging into any other configured search folder */
#define PRETTY_UNMATCHED_FOLDER_NAME _("Unmatched")

#define d(x)

/* flags
 * 1 = delete (0 = add)
 * 2 = noselect
*/
#define CHANGE_ADD (0)
#define CHANGE_DELETE (1)
#define CHANGE_NOSELECT (2)

extern gint camel_application_is_exiting;

/* The custom property ID is a CamelArg artifact.
 * It still identifies the property in state files. */
enum {
	PROP_0,
	PROP_UNMATCHED_ENABLED = 0x2400
};

G_DEFINE_TYPE (CamelVeeStore, camel_vee_store, CAMEL_TYPE_STORE)

struct _CamelVeeStorePrivate {
	CamelVeeDataCache *vee_data_cache;
	CamelVeeFolder *unmatched_folder;
	gboolean unmatched_enabled;

	GMutex sf_counts_mutex;
	GHashTable *subfolder_usage_counts; /* CamelFolder * (subfolder) => gint of usages, for unmatched_folder */

	GMutex vu_counts_mutex;
	GHashTable *vuid_usage_counts; /* gchar * (vuid) => gint of usages, those with 0 comes to unmatched_folder */
};

static gint
vee_folder_cmp (gconstpointer ap,
                gconstpointer bp)
{
	const gchar *full_name_a;
	const gchar *full_name_b;

	full_name_a = camel_folder_get_full_name (((CamelFolder **) ap)[0]);
	full_name_b = camel_folder_get_full_name (((CamelFolder **) bp)[0]);

	return g_strcmp0 (full_name_a, full_name_b);
}

static void
change_folder (CamelStore *store,
               const gchar *name,
               guint32 flags,
               gint count)
{
	CamelFolderInfo *fi;
	const gchar *tmp;

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (name);
	tmp = strrchr (name, '/');
	if (tmp == NULL)
		tmp = name;
	else
		tmp++;
	fi->display_name = g_strdup (tmp);
	fi->unread = count;
	fi->flags = CAMEL_FOLDER_VIRTUAL;
	if (!(flags & CHANGE_DELETE))
		fi->flags |= CAMEL_FOLDER_NOCHILDREN;
	if (flags & CHANGE_NOSELECT)
		fi->flags |= CAMEL_FOLDER_NOSELECT;
	if (flags & CHANGE_DELETE)
		camel_store_folder_deleted (store, fi);
	else
		camel_store_folder_created (store, fi);
	camel_folder_info_free (fi);
}

static void
vee_store_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_UNMATCHED_ENABLED:
			camel_vee_store_set_unmatched_enabled (
				CAMEL_VEE_STORE (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
vee_store_get_property (GObject *object,
                        guint property_id,
                        GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_UNMATCHED_ENABLED:
			g_value_set_boolean (
				value,
				camel_vee_store_get_unmatched_enabled (
				CAMEL_VEE_STORE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
vee_store_dispose (GObject *object)
{
	CamelVeeStorePrivate *priv;

	priv = CAMEL_VEE_STORE_GET_PRIVATE (object);

	g_clear_object (&priv->vee_data_cache);
	g_clear_object (&priv->unmatched_folder);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_vee_store_parent_class)->dispose (object);
}

static void
vee_store_finalize (GObject *object)
{
	CamelVeeStorePrivate *priv;

	priv = CAMEL_VEE_STORE_GET_PRIVATE (object);

	g_hash_table_destroy (priv->subfolder_usage_counts);
	g_hash_table_destroy (priv->vuid_usage_counts);
	g_mutex_clear (&priv->sf_counts_mutex);
	g_mutex_clear (&priv->vu_counts_mutex);

	/* Chain up to parent's finalize () method. */
	G_OBJECT_CLASS (camel_vee_store_parent_class)->finalize (object);
}

static void
vee_store_constructed (GObject *object)
{
	CamelVeeStore *vee_store;

	vee_store = CAMEL_VEE_STORE (object);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (camel_vee_store_parent_class)->constructed (object);

	/* Set up unmatched folder */
	vee_store->priv->unmatched_folder = g_object_new (
		CAMEL_TYPE_VEE_FOLDER,
		"full-name", CAMEL_UNMATCHED_NAME,
		"display-name", PRETTY_UNMATCHED_FOLDER_NAME,
		"parent-store", vee_store, NULL);
	camel_vee_folder_construct (
		vee_store->priv->unmatched_folder, CAMEL_STORE_FOLDER_PRIVATE);
	vee_store->priv->subfolder_usage_counts = g_hash_table_new (g_direct_hash, g_direct_equal);
	vee_store->priv->vuid_usage_counts = g_hash_table_new_full (g_direct_hash, g_direct_equal, (GDestroyNotify) camel_pstring_free, NULL);
	g_mutex_init (&vee_store->priv->sf_counts_mutex);
	g_mutex_init (&vee_store->priv->vu_counts_mutex);
}

static gchar *
vee_store_get_name (CamelService *service,
                    gboolean brief)
{
	return g_strdup ("Virtual Folder Store");
}

static CamelFolder *
vee_store_get_folder_sync (CamelStore *store,
                           const gchar *folder_name,
                           CamelStoreGetFolderFlags flags,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelVeeFolder *vf;
	CamelFolder *folder;
	gchar *name, *p;
	gsize name_len;

	vf = (CamelVeeFolder *) camel_vee_folder_new (store, folder_name, flags);
	if (vf && ((camel_vee_folder_get_flags (vf) & CAMEL_STORE_FOLDER_PRIVATE) == 0)) {
		const gchar *full_name;

		full_name = camel_folder_get_full_name (CAMEL_FOLDER (vf));

		/* Check that parents exist, if not, create dummy ones */
		name_len = strlen (full_name) + 1;
		name = alloca (name_len);
		g_strlcpy (name, full_name, name_len);
		p = name;
		while ( (p = strchr (p, '/'))) {
			*p = 0;

			folder = camel_object_bag_reserve (camel_store_get_folders_bag (store), name);
			if (folder == NULL) {
				/* create a dummy vFolder for this, makes get_folder_info simpler */
				folder = camel_vee_folder_new (store, name, flags);
				camel_object_bag_add (camel_store_get_folders_bag (store), name, folder);
				change_folder (store, name, CHANGE_ADD | CHANGE_NOSELECT, 0);
				/* FIXME: this sort of leaks folder, nobody owns a ref to it but us */
			} else {
				g_object_unref (folder);
			}
			*p++='/';
		}

		change_folder (store, full_name, CHANGE_ADD, camel_folder_get_message_count ((CamelFolder *) vf));
	}

	return (CamelFolder *) vf;
}

static CamelFolderInfo *
vee_store_create_unmatched_fi (void)
{
	CamelFolderInfo *info;

	info = camel_folder_info_new ();
	info->full_name = g_strdup (CAMEL_UNMATCHED_NAME);
	info->display_name = g_strdup (PRETTY_UNMATCHED_FOLDER_NAME);
	info->unread = -1;
	info->flags =
		CAMEL_FOLDER_NOCHILDREN |
		CAMEL_FOLDER_NOINFERIORS |
		CAMEL_FOLDER_SYSTEM |
		CAMEL_FOLDER_VIRTUAL;

	return info;
}

static CamelFolderInfo *
vee_store_get_folder_info_sync (CamelStore *store,
                                const gchar *top,
                                CamelStoreGetFolderInfoFlags flags,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelFolderInfo *info, *res = NULL, *tail;
	GPtrArray *folders;
	GHashTable *infos_hash;
	gint i;

	d (printf ("Get folder info '%s'\n", top ? top:"<null>"));

	folders = camel_store_dup_opened_folders (store);
	if (!folders || !folders->pdata || !folders->len) {
		if (folders)
			g_ptr_array_free (folders, TRUE);

		return NULL;
	}

	qsort (folders->pdata, folders->len, sizeof (folders->pdata[0]), vee_folder_cmp);

	infos_hash = g_hash_table_new (g_str_hash, g_str_equal);
	for (i = 0; i < folders->len; i++) {
		CamelVeeFolder *folder = folders->pdata[i];
		const gchar *full_name;
		const gchar *display_name;
		gint add = FALSE;
		gchar *pname, *tmp;
		CamelFolderInfo *pinfo;

		full_name = camel_folder_get_full_name (CAMEL_FOLDER (folder));
		display_name = camel_folder_get_display_name (CAMEL_FOLDER (folder));

		/* check we have to include this one */
		if (top) {
			gint namelen = strlen (full_name);
			gint toplen = strlen (top);

			add = ((namelen == toplen
				&& strcmp (full_name, top) == 0)
			       || ((namelen > toplen)
				   && strncmp (full_name, top, toplen) == 0
				   && full_name[toplen] == '/'
				   && ((flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE)
				       || strchr (full_name + toplen + 1, '/') == NULL)));
		} else {
			add = (flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE)
				|| strchr (full_name, '/') == NULL;
		}

		if (add) {
			gint32 unread;

			unread = camel_folder_get_unread_message_count (
				CAMEL_FOLDER (folder));

			info = camel_folder_info_new ();
			info->full_name = g_strdup (full_name);
			info->display_name = g_strdup (display_name);
			info->unread = unread;
			info->flags =
				CAMEL_FOLDER_NOCHILDREN |
				CAMEL_FOLDER_VIRTUAL;
			g_hash_table_insert (infos_hash, info->full_name, info);

			if (res == NULL)
				res = info;
		} else {
			info = NULL;
		}

		/* check for parent, if present, update flags and if adding, update parent linkage */
		pname = g_strdup (full_name);
		d (printf ("looking up parent of '%s'\n", pname));
		tmp = strrchr (pname, '/');
		if (tmp) {
			*tmp = 0;
			pinfo = g_hash_table_lookup (infos_hash, pname);
		} else
			pinfo = NULL;

		if (pinfo) {
			pinfo->flags = (pinfo->flags & ~(CAMEL_FOLDER_CHILDREN | CAMEL_FOLDER_NOCHILDREN)) | CAMEL_FOLDER_CHILDREN;
			d (printf ("updating parent flags for children '%s' %08x\n", pinfo->full_name, pinfo->flags));
			tail = pinfo->child;
			if (tail == NULL)
				pinfo->child = info;
		} else if (info != res) {
			tail = res;
		} else {
			tail = NULL;
		}

		if (info && tail) {
			while (tail->next)
				tail = tail->next;
			tail->next = info;
			info->parent = pinfo;
		}

		g_free (pname);
	}
	g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
	g_ptr_array_free (folders, TRUE);
	g_hash_table_destroy (infos_hash);

	/* and add UNMATCHED, if scanning from top/etc and it's enabled */
	if (camel_vee_store_get_unmatched_enabled (CAMEL_VEE_STORE (store)) &&
	    (top == NULL || top[0] == 0 || strncmp (top, CAMEL_UNMATCHED_NAME, strlen (CAMEL_UNMATCHED_NAME)) == 0)) {
		info = vee_store_create_unmatched_fi ();

		if (res == NULL)
			res = info;
		else {
			tail = res;
			while (tail->next)
				tail = tail->next;
			tail->next = info;
		}
	}

	return res;
}

static CamelFolder *
vee_store_get_junk_folder_sync (CamelStore *store,
                                GCancellable *cancellable,
                                GError **error)
{
	return NULL;
}

static CamelFolder *
vee_store_get_trash_folder_sync (CamelStore *store,
                                 GCancellable *cancellable,
                                 GError **error)
{
	return NULL;
}

static gboolean
vee_store_delete_folder_sync (CamelStore *store,
                              const gchar *folder_name,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelFolder *folder;

	if (strcmp (folder_name, CAMEL_UNMATCHED_NAME) == 0) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot delete folder: %s: Invalid operation"),
			folder_name);
		return FALSE;
	}

	folder = camel_object_bag_get (camel_store_get_folders_bag (store), folder_name);
	if (folder) {
		CamelObject *object = CAMEL_OBJECT (folder);
		const gchar *state_filename;

		state_filename = camel_object_get_state_filename (object);
		if (state_filename != NULL) {
			g_unlink (state_filename);
			camel_object_set_state_filename (object, NULL);
		}

		if ((camel_vee_folder_get_flags (CAMEL_VEE_FOLDER (folder)) & CAMEL_STORE_FOLDER_PRIVATE) == 0) {
			/* what about now-empty parents?  ignore? */
			change_folder (store, folder_name, CHANGE_DELETE, -1);
		}

		g_object_unref (folder);
	} else {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot delete folder: %s: No such folder"),
			folder_name);
		return FALSE;
	}

	return TRUE;
}

static gboolean
vee_store_rename_folder_sync (CamelStore *store,
                              const gchar *old,
                              const gchar *new,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelFolder *folder, *oldfolder;
	gchar *p, *name;
	gsize name_len;

	d (printf ("vee rename folder '%s' '%s'\n", old, new));

	if (strcmp (old, CAMEL_UNMATCHED_NAME) == 0) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot rename folder: %s: Invalid operation"), old);
		return FALSE;
	}

	/* See if it exists, for vfolders, all folders are in the folders hash */
	oldfolder = camel_object_bag_get (camel_store_get_folders_bag (store), old);
	if (oldfolder == NULL) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot rename folder: %s: No such folder"), old);
		return FALSE;
	}

	/* Check that new parents exist, if not, create dummy ones */
	name_len = strlen (new) + 1;
	name = alloca (name_len);
	g_strlcpy (name, new, name_len);
	p = name;
	while ( (p = strchr (p, '/'))) {
		*p = 0;

		folder = camel_object_bag_reserve (camel_store_get_folders_bag (store), name);
		if (folder == NULL) {
			/* create a dummy vFolder for this, makes get_folder_info simpler */
			folder = camel_vee_folder_new (store, name, camel_vee_folder_get_flags (CAMEL_VEE_FOLDER (oldfolder)));
			camel_object_bag_add (camel_store_get_folders_bag (store), name, folder);
			change_folder (store, name, CHANGE_ADD | CHANGE_NOSELECT, 0);
			/* FIXME: this sort of leaks folder, nobody owns a ref to it but us */
		} else {
			g_object_unref (folder);
		}
		*p++='/';
	}

	g_object_unref (oldfolder);

	return TRUE;
}

static void
camel_vee_store_class_init (CamelVeeStoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;

	g_type_class_add_private (class, sizeof (CamelVeeStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = vee_store_set_property;
	object_class->get_property = vee_store_get_property;
	object_class->dispose = vee_store_dispose;
	object_class->finalize = vee_store_finalize;
	object_class->constructed = vee_store_constructed;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->get_name = vee_store_get_name;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->get_folder_sync = vee_store_get_folder_sync;
	store_class->get_folder_info_sync = vee_store_get_folder_info_sync;
	store_class->get_junk_folder_sync = vee_store_get_junk_folder_sync;
	store_class->get_trash_folder_sync = vee_store_get_trash_folder_sync;
	store_class->delete_folder_sync = vee_store_delete_folder_sync;
	store_class->rename_folder_sync = vee_store_rename_folder_sync;

	g_object_class_install_property (
		object_class,
		PROP_UNMATCHED_ENABLED,
		g_param_spec_boolean (
			"unmatched-enabled",
			"Unmatched Enabled",
			_("Enable _Unmatched folder"),
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_vee_store_init (CamelVeeStore *vee_store)
{
	CamelStore *store = CAMEL_STORE (vee_store);

	vee_store->priv = CAMEL_VEE_STORE_GET_PRIVATE (vee_store);
	vee_store->priv->vee_data_cache = camel_vee_data_cache_new ();
	vee_store->priv->unmatched_enabled = TRUE;

	/* we dont want a vtrash/vjunk on this one */
	camel_store_set_flags (store, camel_store_get_flags (store) & ~(CAMEL_STORE_VTRASH | CAMEL_STORE_VJUNK));
}

/**
 * camel_vee_store_new:
 *
 * Create a new #CamelVeeStore object.
 *
 * Returns: (transfer full): new #CamelVeeStore object
 **/
CamelVeeStore *
camel_vee_store_new (void)
{
	return g_object_new (CAMEL_TYPE_VEE_STORE, NULL);
}

/**
 * camel_vee_store_get_vee_data_cache:
 * @vstore: a #CamelVeeStore
 *
 * Returns: (type CamelVeeFolder) (transfer none): the associated #CamelVeeDataCache
 *
 * Since: 3.6
 **/
CamelVeeDataCache *
camel_vee_store_get_vee_data_cache (CamelVeeStore *vstore)
{
	g_return_val_if_fail (CAMEL_IS_VEE_STORE (vstore), NULL);

	return vstore->priv->vee_data_cache;
}

/**
 * camel_vee_store_get_unmatched_folder:
 * @vstore: a #CamelVeeStore
 *
 * Returns: (transfer none): the Unmatched folder instance, or %NULL,
 *    when it's disabled.
 *
 * Since: 3.6
 **/
CamelVeeFolder *
camel_vee_store_get_unmatched_folder (CamelVeeStore *vstore)
{
	g_return_val_if_fail (CAMEL_IS_VEE_STORE (vstore), NULL);

	if (!camel_vee_store_get_unmatched_enabled (vstore))
		return NULL;

	return vstore->priv->unmatched_folder;
}

/**
 * camel_vee_store_get_unmatched_enabled:
 * @vstore: a #CamelVeeStore
 *
 * Returns: whether Unmatched folder processing is enabled
 *
 * Since: 3.6
 **/
gboolean
camel_vee_store_get_unmatched_enabled (CamelVeeStore *vstore)
{
	g_return_val_if_fail (CAMEL_IS_VEE_STORE (vstore), FALSE);

	return vstore->priv->unmatched_enabled;
}

/**
 * camel_vee_store_set_unmatched_enabled:
 * @vstore: a #CamelVeeStore
 * @is_enabled: value to set
 *
 * Sets whether the Unmatched folder processing is enabled.
 *
 * Since: 3.6
 **/
void
camel_vee_store_set_unmatched_enabled (CamelVeeStore *vstore,
                                       gboolean is_enabled)
{
	CamelFolderInfo *fi_unmatched;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));

	if (vstore->priv->unmatched_enabled == is_enabled)
		return;

	vstore->priv->unmatched_enabled = is_enabled;
	g_object_notify (G_OBJECT (vstore), "unmatched-enabled");

	fi_unmatched = vee_store_create_unmatched_fi ();

	if (is_enabled) {
		camel_store_folder_created (CAMEL_STORE (vstore), fi_unmatched);
		camel_vee_store_rebuild_unmatched_folder (vstore, NULL, NULL);
	} else {
		camel_store_folder_deleted (CAMEL_STORE (vstore), fi_unmatched);
	}

	camel_folder_info_free (fi_unmatched);
}

struct AddToUnmatchedData {
	CamelVeeFolder *unmatched_folder;
	CamelFolderChangeInfo *changes;
	gboolean unmatched_enabled;
	GHashTable *vuid_usage_counts;
};

static void
add_to_unmatched_folder_cb (CamelVeeMessageInfoData *mi_data,
                            CamelFolder *subfolder,
                            gpointer user_data)
{
	struct AddToUnmatchedData *atud = user_data;
	const gchar *vuid;

	g_return_if_fail (atud != NULL);

	vuid = camel_vee_message_info_data_get_vee_message_uid (mi_data);
	g_hash_table_insert (
		atud->vuid_usage_counts,
		(gpointer) camel_pstring_strdup (vuid),
		GINT_TO_POINTER (0));

	if (atud->unmatched_enabled)
		camel_vee_folder_add_vuid (atud->unmatched_folder, mi_data, atud->changes);
}

/**
 * camel_vee_store_note_subfolder_used:
 * @vstore: a #CamelVeeStore
 * @subfolder: a #CamelFolder
 * @used_by: (type CamelVeeFolder): a #CamelVeeFolder
 *
 * Notes that the @subfolder is used by @used_by folder, which
 * is used to determine what folders will be included in
 * the Unmatched folders.
 *
 * Since: 3.6
 **/
void
camel_vee_store_note_subfolder_used (CamelVeeStore *vstore,
                                     CamelFolder *subfolder,
                                     CamelVeeFolder *used_by)
{
	gint counts;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));
	g_return_if_fail (CAMEL_IS_FOLDER (subfolder));
	g_return_if_fail (CAMEL_IS_VEE_FOLDER (used_by));

	/* only real folders can be part of the unmatched folder */
	if (CAMEL_IS_VEE_FOLDER (subfolder) ||
	    used_by == vstore->priv->unmatched_folder ||
	    camel_application_is_exiting)
		return;

	g_mutex_lock (&vstore->priv->sf_counts_mutex);

	counts = GPOINTER_TO_INT (g_hash_table_lookup (vstore->priv->subfolder_usage_counts, subfolder));
	counts++;
	g_hash_table_insert (
		vstore->priv->subfolder_usage_counts,
		subfolder, GINT_TO_POINTER (counts));

	if (counts == 1) {
		struct AddToUnmatchedData atud;
		CamelFolder *unmatched_folder;

		camel_vee_data_cache_add_subfolder (vstore->priv->vee_data_cache, subfolder);

		g_mutex_lock (&vstore->priv->vu_counts_mutex);

		/* all messages from the folder are unmatched at the beginning */
		atud.unmatched_folder = vstore->priv->unmatched_folder;
		atud.changes = camel_folder_change_info_new ();
		atud.unmatched_enabled = camel_vee_store_get_unmatched_enabled (vstore);
		atud.vuid_usage_counts = vstore->priv->vuid_usage_counts;

		if (atud.unmatched_enabled)
			camel_vee_folder_add_folder (vstore->priv->unmatched_folder, subfolder, NULL);

		unmatched_folder = CAMEL_FOLDER (atud.unmatched_folder);

		camel_folder_freeze (unmatched_folder);

		camel_vee_data_cache_foreach_message_info_data (vstore->priv->vee_data_cache, subfolder,
			add_to_unmatched_folder_cb, &atud);

		camel_folder_thaw (unmatched_folder);
		g_mutex_unlock (&vstore->priv->vu_counts_mutex);

		if (camel_folder_change_info_changed (atud.changes))
			camel_folder_changed (unmatched_folder, atud.changes);
		camel_folder_change_info_free (atud.changes);
	}

	g_mutex_unlock (&vstore->priv->sf_counts_mutex);
}

static void
remove_vuid_count_record_cb (CamelVeeMessageInfoData *mi_data,
                             CamelFolder *subfolder,
                             gpointer user_data)
{
	GHashTable *vuid_usage_counts = user_data;

	g_return_if_fail (mi_data != NULL);
	g_return_if_fail (user_data != NULL);

	g_hash_table_remove (vuid_usage_counts, camel_vee_message_info_data_get_vee_message_uid (mi_data));
}

/**
 * camel_vee_store_note_subfolder_unused:
 * @vstore: a #CamelVeeStore
 * @subfolder: a #CamelFolder
 * @unused_by: (type CamelVeeFolder): a #CamelVeeFolder
 *
 * This is a counter part of camel_vee_store_note_subfolder_used(). Once
 * the @subfolder is claimed to be not used by all folders its message infos
 * are removed from the Unmatched folder.
 *
 * Since: 3.6
 **/
void
camel_vee_store_note_subfolder_unused (CamelVeeStore *vstore,
                                       CamelFolder *subfolder,
                                       CamelVeeFolder *unused_by)
{
	gint counts;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));
	g_return_if_fail (CAMEL_IS_FOLDER (subfolder));
	g_return_if_fail (CAMEL_IS_VEE_FOLDER (unused_by));

	/* only real folders can be part of the unmatched folder */
	if (CAMEL_IS_VEE_FOLDER (subfolder) ||
	    unused_by == vstore->priv->unmatched_folder ||
	    camel_application_is_exiting)
		return;

	g_mutex_lock (&vstore->priv->sf_counts_mutex);

	counts = GPOINTER_TO_INT (g_hash_table_lookup (vstore->priv->subfolder_usage_counts, subfolder));
	g_return_if_fail (counts > 0);

	counts--;
	if (counts == 0) {
		g_hash_table_remove (vstore->priv->subfolder_usage_counts, subfolder);
		if (camel_vee_store_get_unmatched_enabled (vstore))
			camel_vee_folder_remove_folder (vstore->priv->unmatched_folder, subfolder, NULL);

		g_mutex_lock (&vstore->priv->vu_counts_mutex);
		camel_vee_data_cache_foreach_message_info_data (vstore->priv->vee_data_cache, subfolder,
			remove_vuid_count_record_cb, vstore->priv->vuid_usage_counts);
		g_mutex_unlock (&vstore->priv->vu_counts_mutex);

		camel_vee_data_cache_remove_subfolder (vstore->priv->vee_data_cache, subfolder);
	} else {
		g_hash_table_insert (
			vstore->priv->subfolder_usage_counts,
			subfolder, GINT_TO_POINTER (counts));
	}

	g_mutex_unlock (&vstore->priv->sf_counts_mutex);
}

/**
 * camel_vee_store_note_vuid_used:
 * @vstore: a #CamelVeeStore
 * @mi_data: a #CamelVeeMessageInfoData
 * @used_by: (type CamelVeeFolder): a #CamelVeeFolder
 *
 * Notes the @mi_data is used by the @used_by virtual folder, which
 * removes it from the Unmatched folder, if not used anywhere else.
 *
 * Since: 3.6
 **/
void
camel_vee_store_note_vuid_used (CamelVeeStore *vstore,
                                CamelVeeMessageInfoData *mi_data,
                                CamelVeeFolder *used_by)
{
	gint counts;
	const gchar *vuid;
	CamelFolder *subfolder;
	CamelVeeSubfolderData *sf_data;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));
	g_return_if_fail (used_by != NULL);
	g_return_if_fail (mi_data != NULL);

	/* these notifications are ignored from Unmatched folder */
	if (used_by == vstore->priv->unmatched_folder ||
	    camel_application_is_exiting)
		return;

	/* unmatched folder holds only real folders */
	sf_data = camel_vee_message_info_data_get_subfolder_data (mi_data);
	subfolder = camel_vee_subfolder_data_get_folder (sf_data);
	if (CAMEL_IS_VEE_FOLDER (subfolder))
		return;

	g_mutex_lock (&vstore->priv->vu_counts_mutex);

	vuid = camel_vee_message_info_data_get_vee_message_uid (mi_data);

	counts = GPOINTER_TO_INT (g_hash_table_lookup (vstore->priv->vuid_usage_counts, vuid));
	counts++;
	g_hash_table_insert (
		vstore->priv->vuid_usage_counts,
		(gpointer) camel_pstring_strdup (vuid),
		GINT_TO_POINTER (counts));

	if (counts == 1 && camel_vee_store_get_unmatched_enabled (vstore)) {
		CamelFolderChangeInfo *changes;

		changes = camel_folder_change_info_new ();

		camel_vee_folder_remove_vuid (vstore->priv->unmatched_folder, mi_data, changes);

		if (camel_folder_change_info_changed (changes))
			camel_folder_changed (CAMEL_FOLDER (vstore->priv->unmatched_folder), changes);
		camel_folder_change_info_free (changes);
	}

	g_mutex_unlock (&vstore->priv->vu_counts_mutex);
}

static gboolean
vee_store_folder_contains_uid (CamelFolder *folder,
			       const gchar *message_uid)
{
	CamelFolderSummary *summary;
	gboolean contains;

	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), FALSE);
	g_return_val_if_fail (message_uid != NULL, FALSE);

	summary = camel_folder_get_folder_summary (folder);
	if (!summary) {
		CamelMessageInfo *nfo;

		nfo = camel_folder_get_message_info (folder, message_uid);
		contains = nfo != NULL;

		g_clear_object (&nfo);
	} else {
		contains = camel_folder_summary_check_uid (summary, message_uid);
	}

	return contains;
}

/**
 * camel_vee_store_note_vuid_unused:
 * @vstore: a #CamelVeeStore
 * @mi_data: a #CamelVeeMessageInfoData
 * @unused_by: (type CamelVeeFolder): a #CamelVeeFolder
 *
 * A counter part of camel_vee_store_note_vuid_used(). Once the @unused_by
 * claims the @mi_data is not used by it anymore, and neither any other
 * virtual folder is using it, then the Unmatched folder will have it added.
 *
 * Since: 3.6
 **/
void
camel_vee_store_note_vuid_unused (CamelVeeStore *vstore,
                                  CamelVeeMessageInfoData *mi_data,
                                  CamelVeeFolder *unused_by)
{
	gint counts;
	const gchar *vuid;
	CamelFolder *subfolder;
	CamelVeeSubfolderData *sf_data;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));
	g_return_if_fail (unused_by != NULL);
	g_return_if_fail (mi_data != NULL);

	/* these notifications are ignored from Unmatched folder */
	if (unused_by == vstore->priv->unmatched_folder ||
	    camel_application_is_exiting)
		return;

	/* unmatched folder holds only real folders */
	sf_data = camel_vee_message_info_data_get_subfolder_data (mi_data);
	subfolder = camel_vee_subfolder_data_get_folder (sf_data);
	if (CAMEL_IS_VEE_FOLDER (subfolder))
		return;

	g_mutex_lock (&vstore->priv->vu_counts_mutex);

	vuid = camel_vee_message_info_data_get_vee_message_uid (mi_data);

	counts = GPOINTER_TO_INT (g_hash_table_lookup (vstore->priv->vuid_usage_counts, vuid));
	counts--;
	if (counts < 0) {
		g_mutex_unlock (&vstore->priv->vu_counts_mutex);
		g_return_if_fail (counts >= 0);
		return;
	}

	g_hash_table_insert (
		vstore->priv->vuid_usage_counts,
		(gpointer) camel_pstring_strdup (vuid),
		GINT_TO_POINTER (counts));

	if (counts == 0 &&
	    camel_vee_store_get_unmatched_enabled (vstore) &&
	    vee_store_folder_contains_uid (subfolder, camel_vee_message_info_data_get_orig_message_uid (mi_data))) {
		CamelFolderChangeInfo *changes;

		changes = camel_folder_change_info_new ();

		camel_vee_folder_add_vuid (vstore->priv->unmatched_folder, mi_data, changes);

		if (camel_folder_change_info_changed (changes))
			camel_folder_changed (CAMEL_FOLDER (vstore->priv->unmatched_folder), changes);
		camel_folder_change_info_free (changes);
	}

	g_mutex_unlock (&vstore->priv->vu_counts_mutex);
}

struct RebuildUnmatchedData {
	CamelVeeDataCache *data_cache;
	CamelVeeFolder *unmatched_folder;
	CamelFolderChangeInfo *changes;
	GCancellable *cancellable;
};

static void
rebuild_unmatched_folder_cb (gpointer key,
                             gpointer value,
                             gpointer user_data)
{
	const gchar *vuid = key;
	gint counts = GPOINTER_TO_INT (value);
	struct RebuildUnmatchedData *rud = user_data;
	CamelVeeSubfolderData *si_data;
	CamelVeeMessageInfoData *mi_data;

	g_return_if_fail (vuid != NULL);
	g_return_if_fail (rud != NULL);

	if (counts != 0 || g_cancellable_is_cancelled (rud->cancellable))
		return;

	mi_data = camel_vee_data_cache_get_message_info_data_by_vuid (rud->data_cache, vuid);
	if (!mi_data)
		return;

	si_data = camel_vee_message_info_data_get_subfolder_data (mi_data);

	camel_vee_folder_add_folder (rud->unmatched_folder, camel_vee_subfolder_data_get_folder (si_data), NULL);
	camel_vee_folder_add_vuid (rud->unmatched_folder, mi_data, rud->changes);

	g_object_unref (mi_data);
}

static void
vee_store_rebuild_unmatched_folder (CamelSession *session,
                                    GCancellable *cancellable,
                                    CamelVeeStore *vstore,
                                    GError **error)
{
	struct RebuildUnmatchedData rud;
	CamelVeeFolder *vunmatched;
	CamelFolder *unmatched_folder;
	CamelFolderChangeInfo *changes;

	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));

	vunmatched = camel_vee_store_get_unmatched_folder (vstore);
	/* someone could disable it meanwhile */
	if (!vunmatched)
		return;

	unmatched_folder = CAMEL_FOLDER (vunmatched);
	g_return_if_fail (unmatched_folder != NULL);

	camel_folder_freeze (unmatched_folder);

	/* start from scratch, with empty folder */
	camel_vee_folder_set_folders (vunmatched, NULL, cancellable);

	changes = camel_folder_change_info_new ();

	rud.data_cache = vstore->priv->vee_data_cache;
	rud.unmatched_folder = vunmatched;
	rud.changes = changes;
	rud.cancellable = cancellable;

	g_hash_table_foreach (vstore->priv->vuid_usage_counts, rebuild_unmatched_folder_cb, &rud);

	camel_folder_thaw (unmatched_folder);

	if (camel_folder_change_info_changed (changes))
		camel_folder_changed (unmatched_folder, changes);
	camel_folder_change_info_free (changes);

	/* Just to mute CHECKED_RETURN warning */
	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;
}

/**
 * camel_vee_store_rebuild_unmatched_folder:
 * @vstore: a #CamelVeeStore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Let's the @vstore know to rebuild the Unmatched folder. This is done
 * as a separate job, when the @cancellable is %NULL, otherwise it's run
 * synchronously.
 *
 * Since: 3.6
 **/
void
camel_vee_store_rebuild_unmatched_folder (CamelVeeStore *vstore,
                                          GCancellable *cancellable,
                                          GError **error)
{
	g_return_if_fail (CAMEL_IS_VEE_STORE (vstore));

	/* this operation requires cancellable, thus if called
	 * without it then run in a dedicated thread */
	if (!cancellable) {
		CamelService *service;
		CamelSession *session;

		service = CAMEL_SERVICE (vstore);
		session = camel_service_ref_session (service);

		if (session) {
			camel_session_submit_job (
				session, _("Updating Unmatched search folder"), (CamelSessionCallback)
				vee_store_rebuild_unmatched_folder,
				g_object_ref (vstore),
				g_object_unref);

			g_object_unref (session);
		}
	} else {
		vee_store_rebuild_unmatched_folder (NULL, cancellable, vstore, error);
	}
}
