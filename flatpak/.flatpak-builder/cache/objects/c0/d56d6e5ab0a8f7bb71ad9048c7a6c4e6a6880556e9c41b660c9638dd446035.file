/*
 * Copyright (C) 2012 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Milan Crha <mcrha@redhat.com>
 */

#include "evolution-data-server-config.h"

#include "camel-string-utils.h"
#include "camel-store.h"

#include "camel-vee-data-cache.h"

#define CAMEL_VEE_SUBFOLDER_DATA_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_VEE_SUBFOLDER_DATA, CamelVeeSubfolderDataPrivate))

struct _CamelVeeSubfolderDataPrivate {
	CamelFolder *folder;
	const gchar *folder_id; /* stored in string pool */
};

G_DEFINE_TYPE (
	CamelVeeSubfolderData,
	camel_vee_subfolder_data,
	G_TYPE_OBJECT)

static void
vee_subfolder_data_dispose (GObject *object)
{
	CamelVeeSubfolderDataPrivate *priv;

	priv = CAMEL_VEE_SUBFOLDER_DATA_GET_PRIVATE (object);

	g_clear_object (&priv->folder);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_vee_subfolder_data_parent_class)->
		dispose (object);
}

static void
vee_subfolder_data_finalize (GObject *object)
{
	CamelVeeSubfolderDataPrivate *priv;

	priv = CAMEL_VEE_SUBFOLDER_DATA_GET_PRIVATE (object);

	if (priv->folder_id != NULL)
		camel_pstring_free (priv->folder_id);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_vee_subfolder_data_parent_class)->
		finalize (object);
}

static void
camel_vee_subfolder_data_class_init (CamelVeeSubfolderDataClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelVeeSubfolderDataPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = vee_subfolder_data_dispose;
	object_class->finalize = vee_subfolder_data_finalize;
}

static void
camel_vee_subfolder_data_init (CamelVeeSubfolderData *data)
{
	data->priv = CAMEL_VEE_SUBFOLDER_DATA_GET_PRIVATE (data);
}

static void
vee_subfolder_data_hash_folder (CamelFolder *folder,
                                gchar buffer[8])
{
	CamelStore *parent_store;
	GChecksum *checksum;
	guint8 *digest;
	gsize length;
	gint state = 0, save = 0;
	gchar *ptr_string;
	const gchar *uid;
	gint i;

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	parent_store = camel_folder_get_parent_store (folder);
	uid = camel_service_get_uid (CAMEL_SERVICE (parent_store));
	g_checksum_update (checksum, (guchar *) uid, -1);

	ptr_string = g_strdup_printf ("%p", folder);
	g_checksum_update (checksum, (guchar *) ptr_string, -1);
	g_free (ptr_string);

	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);

	g_base64_encode_step (digest, 6, FALSE, buffer, &state, &save);
	g_base64_encode_close (FALSE, buffer, &state, &save);

	for (i = 0; i < 8; i++) {
		if (buffer[i] == '+')
			buffer[i] = '.';
		if (buffer[i] == '/')
			buffer[i] = '_';
	}
}

/**
 * camel_vee_subfolder_data_new:
 * @folder: a #CamelFolder for which create the object
 *
 * Creates a new #CamelVeeSubfolderData object for the given @folder.
 * The @folder is referenced for later use.
 *
 * Returns: (transfer full): a new #CamelVeeSubfolderData. Use g_object_unref()
 *    to unref it, when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeSubfolderData *
camel_vee_subfolder_data_new (CamelFolder *folder)
{
	CamelVeeSubfolderData *data;
	gchar buffer[8], *folder_id;

	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), NULL);

	data = g_object_new (CAMEL_TYPE_VEE_SUBFOLDER_DATA, NULL);
	data->priv->folder = g_object_ref (folder);

	vee_subfolder_data_hash_folder (folder, buffer);
	folder_id = g_strndup (buffer, 8);

	data->priv->folder_id = camel_pstring_add (folder_id, TRUE);

	return data;
}

/**
 * camel_vee_subfolder_data_get_folder:
 * @data: a CamelVeeSubfolderData
 *
 * Returns: (transfer none): a #CamelFolder to which this @data was created
 *
 * Since: 3.6
 **/
CamelFolder *
camel_vee_subfolder_data_get_folder (CamelVeeSubfolderData *data)
{
	g_return_val_if_fail (CAMEL_IS_VEE_SUBFOLDER_DATA (data), NULL);

	return data->priv->folder;
}

/**
 * camel_vee_subfolder_data_get_folder_id:
 * @data: a CamelVeeSubfolderData
 *
 * Returns: (transfer none): a folder ID for this subfolder @data
 *
 * Since: 3.6
 **/
const gchar *
camel_vee_subfolder_data_get_folder_id (CamelVeeSubfolderData *data)
{
	g_return_val_if_fail (CAMEL_IS_VEE_SUBFOLDER_DATA (data), NULL);

	return data->priv->folder_id;
}

/* ----------------------------------------------------------------------- */

#define CAMEL_VEE_MESSAGE_INFO_DATA_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA, CamelVeeMessageInfoDataPrivate))

struct _CamelVeeMessageInfoDataPrivate {
	CamelVeeSubfolderData *subfolder_data;
	const gchar *orig_message_uid; /* stored in string pool */
	const gchar *vee_message_uid; /* stored in string pool */
};

G_DEFINE_TYPE (
	CamelVeeMessageInfoData,
	camel_vee_message_info_data,
	G_TYPE_OBJECT)

static void
vee_message_info_data_dispose (GObject *object)
{
	CamelVeeMessageInfoDataPrivate *priv;

	priv = CAMEL_VEE_MESSAGE_INFO_DATA_GET_PRIVATE (object);

	g_clear_object (&priv->subfolder_data);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_vee_message_info_data_parent_class)->
		dispose (object);
}

static void
vee_message_info_data_finalize (GObject *object)
{
	CamelVeeMessageInfoDataPrivate *priv;

	priv = CAMEL_VEE_MESSAGE_INFO_DATA_GET_PRIVATE (object);

	if (priv->orig_message_uid != NULL)
		camel_pstring_free (priv->orig_message_uid);

	if (priv->vee_message_uid != NULL)
		camel_pstring_free (priv->vee_message_uid);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_vee_message_info_data_parent_class)->
		finalize (object);
}

static void
camel_vee_message_info_data_class_init (CamelVeeMessageInfoDataClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (
		class, sizeof (CamelVeeMessageInfoDataPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = vee_message_info_data_dispose;
	object_class->finalize = vee_message_info_data_finalize;
}

static void
camel_vee_message_info_data_init (CamelVeeMessageInfoData *data)
{
	data->priv = CAMEL_VEE_MESSAGE_INFO_DATA_GET_PRIVATE (data);
}

/**
 * camel_vee_message_info_data_new:
 * @subfolder_data: a #CamelVeeSubfolderData
 * @orig_message_uid: original message info's UID
 *
 * Returns: (transfer full): a new #CamelVeeMessageInfoData which references
 *    message info with UID @orig_message_uid froma folder managed by @subfolder_data.
 *    Unref the returned object with g_object_unref(), when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeMessageInfoData *
camel_vee_message_info_data_new (CamelVeeSubfolderData *subfolder_data,
                                 const gchar *orig_message_uid)
{
	CamelVeeMessageInfoData *data;
	gchar *vee_message_uid;

	g_return_val_if_fail (CAMEL_IS_VEE_SUBFOLDER_DATA (subfolder_data), NULL);
	g_return_val_if_fail (orig_message_uid != NULL, NULL);

	data = g_object_new (CAMEL_TYPE_VEE_MESSAGE_INFO_DATA, NULL);
	data->priv->subfolder_data = g_object_ref (subfolder_data);

	vee_message_uid = g_strconcat (camel_vee_subfolder_data_get_folder_id (subfolder_data), orig_message_uid, NULL);

	data->priv->orig_message_uid = camel_pstring_strdup (orig_message_uid);
	data->priv->vee_message_uid = camel_pstring_add (vee_message_uid, TRUE);

	return data;
}

/**
 * camel_vee_message_info_data_get_subfolder_data:
 * @data: a CamelVeeMessageInfoData
 *
 * Returns: (transfer none): A #CamelVeeSubfolderData for which
 *    the @data had been created.
 *
 * Since: 3.6
 **/
CamelVeeSubfolderData *
camel_vee_message_info_data_get_subfolder_data (CamelVeeMessageInfoData *data)
{
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO_DATA (data), NULL);

	return data->priv->subfolder_data;
}

/**
 * camel_vee_message_info_data_get_orig_message_uid:
 * @data: a CamelVeeMessageInfoData
 *
 * Returns: (transfer none): The original message info's UID, for which
 *    the @data had been created.
 *
 * Since: 3.6
 **/
const gchar *
camel_vee_message_info_data_get_orig_message_uid (CamelVeeMessageInfoData *data)
{
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO_DATA (data), NULL);

	return data->priv->orig_message_uid;
}

/**
 * camel_vee_message_info_data_get_vee_message_uid:
 * @data: a CamelVeeMessageInfoData
 *
 * Returns: (transfer none): Message UID corresponding to this virtual
 *    message info @data.
 *
 * Since: 3.6
 **/
const gchar *
camel_vee_message_info_data_get_vee_message_uid (CamelVeeMessageInfoData *data)
{
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO_DATA (data), NULL);

	return data->priv->vee_message_uid;
}

/* ----------------------------------------------------------------------- */

#define CAMEL_VEE_DATA_CACHE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_VEE_DATA_CACHE, CamelVeeDataCachePrivate))

struct _CamelVeeDataCachePrivate {
	GMutex sf_mutex; /* guards subfolder_hash */
	GHashTable *subfolder_hash; /* CamelFolder * => CamelVeeSubfolderData * */

	GMutex mi_mutex; /* guards message_info_hash */
	GHashTable *orig_message_uid_hash; /* VeeData * => CamelVeeMessageInfoData * */
	GHashTable *vee_message_uid_hash; /* const gchar *vee_uid => CamelVeeMessageInfoData * */
};

G_DEFINE_TYPE (CamelVeeDataCache, camel_vee_data_cache, G_TYPE_OBJECT)

typedef struct _VeeData {
	CamelFolder *folder;
	const gchar *orig_message_uid;
} VeeData;

static guint
vee_data_hash (gconstpointer ptr)
{
	const VeeData *vee_data = ptr;

	if (!vee_data)
		return 0;

	return g_direct_hash (vee_data->folder)
		+ g_str_hash (vee_data->orig_message_uid);
}

static gboolean
vee_data_equal (gconstpointer v1,
                gconstpointer v2)
{
	const VeeData *vee_data1 = v1, *vee_data2 = v2;

	if (!v1 || !v2)
		return v1 == v2;

	/* can contain ponters directly, strings are always from the string pool */
	return v1 == v2 ||
		(vee_data1->folder == vee_data2->folder &&
		 vee_data1->orig_message_uid == vee_data2->orig_message_uid);
}

static void
vee_data_cache_dispose (GObject *object)
{
	CamelVeeDataCachePrivate *priv;

	priv = CAMEL_VEE_DATA_CACHE_GET_PRIVATE (object);

	if (priv->subfolder_hash != NULL) {
		g_hash_table_destroy (priv->subfolder_hash);
		priv->subfolder_hash = NULL;
	}

	if (priv->orig_message_uid_hash != NULL) {
		g_hash_table_destroy (priv->orig_message_uid_hash);
		priv->orig_message_uid_hash = NULL;
	}

	if (priv->vee_message_uid_hash != NULL) {
		g_hash_table_destroy (priv->vee_message_uid_hash);
		priv->vee_message_uid_hash = NULL;
	}

	/* Chain up to parent's dispose () method. */
	G_OBJECT_CLASS (camel_vee_data_cache_parent_class)->dispose (object);
}

static void
vee_data_cache_finalize (GObject *object)
{
	CamelVeeDataCachePrivate *priv;

	priv = CAMEL_VEE_DATA_CACHE_GET_PRIVATE (object);

	g_mutex_clear (&priv->sf_mutex);
	g_mutex_clear (&priv->mi_mutex);

	/* Chain up to parent's finalize () method. */
	G_OBJECT_CLASS (camel_vee_data_cache_parent_class)->finalize (object);
}

static void
camel_vee_data_cache_class_init (CamelVeeDataCacheClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelVeeDataCachePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = vee_data_cache_dispose;
	object_class->finalize = vee_data_cache_finalize;
}

static void
camel_vee_data_cache_init (CamelVeeDataCache *data_cache)
{
	data_cache->priv = CAMEL_VEE_DATA_CACHE_GET_PRIVATE (data_cache);

	g_mutex_init (&data_cache->priv->sf_mutex);
	data_cache->priv->subfolder_hash = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, g_object_unref);

	g_mutex_init (&data_cache->priv->mi_mutex);
	data_cache->priv->orig_message_uid_hash = g_hash_table_new_full (vee_data_hash, vee_data_equal, g_free, g_object_unref);
	data_cache->priv->vee_message_uid_hash = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, NULL);
}

/**
 * camel_vee_data_cache_new:
 *
 * Returns: (transfer full): a new #CamelVeeDataCache; unref it
 *    with g_object_unref(), when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeDataCache *
camel_vee_data_cache_new (void)
{
	return g_object_new (CAMEL_TYPE_VEE_DATA_CACHE, NULL);
}

/**
 * camel_vee_data_cache_add_subfolder:
 * @data_cache: a #CamelVeeDataCache
 * @subfolder: a #CamelFolder
 *
 * Adds the @subfolder to the @data_cache to be tracked by it. The @subfolder
 * is referenced for later use. The function does nothing when the @subfolder
 * is already in the @data_cache. The subfolders can be removed with
 * camel_vee_data_cache_remove_subfolder().
 *
 * Since: 3.6
 **/
void
camel_vee_data_cache_add_subfolder (CamelVeeDataCache *data_cache,
                                    CamelFolder *subfolder)
{
	CamelVeeSubfolderData *sf_data;

	g_return_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache));
	g_return_if_fail (CAMEL_IS_FOLDER (subfolder));

	g_mutex_lock (&data_cache->priv->mi_mutex);
	g_mutex_lock (&data_cache->priv->sf_mutex);

	sf_data = g_hash_table_lookup (data_cache->priv->subfolder_hash, subfolder);
	if (!sf_data) {
		GPtrArray *uids;
		gint ii;

		sf_data = camel_vee_subfolder_data_new (subfolder);
		g_hash_table_insert (data_cache->priv->subfolder_hash, subfolder, sf_data);

		/* camel_vee_data_cache_get_message_info_data() caches uids on demand,
		 * while here are cached all known uids in once - it is better when
		 * the folder is used in Unmatched folder, where the uid/vuid will
		 * be used in the vfolder or Unmatched folder anyway */
		uids = camel_folder_get_uids (subfolder);
		if (uids) {
			for (ii = 0; ii < uids->len; ii++) {
				VeeData vdata;
				CamelVeeMessageInfoData *mi_data;

				/* make sure the orig_message_uid comes from the string pool */
				vdata.folder = subfolder;
				vdata.orig_message_uid = camel_pstring_strdup (uids->pdata[ii]);

				mi_data = g_hash_table_lookup (data_cache->priv->orig_message_uid_hash, &vdata);
				if (!mi_data) {
					VeeData *hash_data;

					mi_data = camel_vee_message_info_data_new (sf_data, vdata.orig_message_uid);

					hash_data = g_new0 (VeeData, 1);
					hash_data->folder = subfolder;
					hash_data->orig_message_uid = camel_vee_message_info_data_get_orig_message_uid (mi_data);

					g_hash_table_insert (data_cache->priv->orig_message_uid_hash, hash_data, mi_data);
					g_hash_table_insert (
						data_cache->priv->vee_message_uid_hash,
						(gpointer) camel_vee_message_info_data_get_vee_message_uid (mi_data),
						mi_data);
				}

				camel_pstring_free (vdata.orig_message_uid);
			}

			camel_folder_free_uids (subfolder, uids);
		}
	}

	g_mutex_unlock (&data_cache->priv->sf_mutex);
	g_mutex_unlock (&data_cache->priv->mi_mutex);
}

static gboolean
remove_vee_by_folder_cb (gpointer key,
                         gpointer value,
                         gpointer user_data)
{
	CamelVeeMessageInfoData *mi_data = value;
	CamelVeeSubfolderData *sf_data;
	CamelFolder *folder = user_data;

	if (!mi_data)
		return FALSE;

	sf_data = camel_vee_message_info_data_get_subfolder_data (mi_data);
	return sf_data && camel_vee_subfolder_data_get_folder (sf_data) == folder;
}

static gboolean
remove_orig_by_folder_cb (gpointer key,
                          gpointer value,
                          gpointer user_data)
{
	VeeData *vee_data = key;
	CamelFolder *folder = user_data;

	return vee_data && vee_data->folder == folder;
}

/**
 * camel_vee_data_cache_remove_subfolder:
 * @data_cache: a #CamelVeeDataCache
 * @subfolder: a #CamelFolder to remove
 *
 * Removes given @subfolder from the @data_cache, which had been
 * previously added with camel_vee_data_cache_add_subfolder().
 * The function does nothing, when the @subfolder is not part
 * of the @data_cache.
 *
 * Since: 3.6
 **/
void
camel_vee_data_cache_remove_subfolder (CamelVeeDataCache *data_cache,
                                       CamelFolder *subfolder)
{
	g_return_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache));
	g_return_if_fail (CAMEL_IS_FOLDER (subfolder));

	g_mutex_lock (&data_cache->priv->mi_mutex);
	g_mutex_lock (&data_cache->priv->sf_mutex);

	g_hash_table_foreach_remove (data_cache->priv->vee_message_uid_hash, remove_vee_by_folder_cb, subfolder);
	g_hash_table_foreach_remove (data_cache->priv->orig_message_uid_hash, remove_orig_by_folder_cb, subfolder);
	g_hash_table_remove (data_cache->priv->subfolder_hash, subfolder);

	g_mutex_unlock (&data_cache->priv->sf_mutex);
	g_mutex_unlock (&data_cache->priv->mi_mutex);
}

/**
 * camel_vee_data_cache_get_subfolder_data:
 * @data_cache: a #CamelVeeDataCache
 * @folder: a #CamelFolder for which to return subfolder data
 *
 * Returns a #CamelVeeSubfolderData for the given @folder.
 *
 * Returns: (transfer full): a referenced #CamelVeeSubfolderData; unref it
 *    with g_object_unref(), when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeSubfolderData *
camel_vee_data_cache_get_subfolder_data (CamelVeeDataCache *data_cache,
                                         CamelFolder *folder)
{
	CamelVeeSubfolderData *res;

	g_return_val_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache), NULL);
	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), NULL);

	g_mutex_lock (&data_cache->priv->sf_mutex);

	res = g_hash_table_lookup (data_cache->priv->subfolder_hash, folder);
	if (!res) {
		res = camel_vee_subfolder_data_new (folder);
		g_hash_table_insert (data_cache->priv->subfolder_hash, folder, res);
	}

	g_object_ref (res);

	g_mutex_unlock (&data_cache->priv->sf_mutex);

	return res;
}

/**
 * camel_vee_data_cache_contains_message_info_data:
 * @data_cache: a #CamelVeeDataCache
 * @folder: a #CamelFolder to which the @orig_message_uid belongs
 * @orig_message_uid: a message UID from the @folder to check
 *
 * Returns whether data_cache contains given @orig_message_uid for the given @folder.
 * Unlike camel_vee_data_cache_get_message_info_data(), this only
 * returns %FALSE if not, while camel_vee_data_cache_get_message_info_data()
 * auto-adds it to data_cache.
 *
 * Since: 3.6
 */
gboolean
camel_vee_data_cache_contains_message_info_data (CamelVeeDataCache *data_cache,
                                                 CamelFolder *folder,
                                                 const gchar *orig_message_uid)
{
	gboolean res;
	VeeData vdata;

	g_return_val_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache), FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), FALSE);
	g_return_val_if_fail (orig_message_uid != NULL, FALSE);

	g_mutex_lock (&data_cache->priv->mi_mutex);

	/* make sure the orig_message_uid comes from the string pool */
	vdata.folder = folder;
	vdata.orig_message_uid = camel_pstring_strdup (orig_message_uid);

	res = g_hash_table_lookup (data_cache->priv->orig_message_uid_hash, &vdata) != NULL;

	camel_pstring_free (vdata.orig_message_uid);

	g_mutex_unlock (&data_cache->priv->mi_mutex);

	return res;
}

/**
 * camel_vee_data_cache_get_message_info_data:
 * @data_cache: a #CamelVeeDataCache
 * @folder: a #CamelFolder to which the @orig_message_uid belongs
 * @orig_message_uid: a message UID from the @folder to return
 *
 * Returns a referenced #CamelVeeMessageInfoData referencing the given @folder
 * and @orig_message_uid. If it's not part of the @data_cache, then it is
 * created and auto-added. Use camel_vee_data_cache_contains_message_info_data()
 * when you only want to check the existence, without adding it to the @data_cache.
 *
 * Returns: (transfer full): a referenced #CamelVeeMessageInfoData; unref it
 *    with g_object_unref(), when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeMessageInfoData *
camel_vee_data_cache_get_message_info_data (CamelVeeDataCache *data_cache,
                                            CamelFolder *folder,
                                            const gchar *orig_message_uid)
{
	CamelVeeMessageInfoData *res;
	VeeData vdata;

	g_return_val_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache), NULL);
	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), NULL);
	g_return_val_if_fail (orig_message_uid != NULL, NULL);

	g_mutex_lock (&data_cache->priv->mi_mutex);

	/* make sure the orig_message_uid comes from the string pool */
	vdata.folder = folder;
	vdata.orig_message_uid = camel_pstring_strdup (orig_message_uid);

	res = g_hash_table_lookup (data_cache->priv->orig_message_uid_hash, &vdata);
	if (!res) {
		VeeData *hash_data;
		CamelVeeSubfolderData *sf_data;

		/* this locks also priv->sf_mutex */
		sf_data = camel_vee_data_cache_get_subfolder_data (data_cache, folder);
		if (!sf_data) {
			camel_pstring_free (vdata.orig_message_uid);
			g_mutex_unlock (&data_cache->priv->mi_mutex);
			g_return_val_if_fail (sf_data != NULL, NULL);
		}

		res = camel_vee_message_info_data_new (sf_data, orig_message_uid);

		/* res holds the reference now */
		g_object_unref (sf_data);

		hash_data = g_new0 (VeeData, 1);
		hash_data->folder = folder;
		hash_data->orig_message_uid = camel_vee_message_info_data_get_orig_message_uid (res);

		g_hash_table_insert (data_cache->priv->orig_message_uid_hash, hash_data, res);
		g_hash_table_insert (
			data_cache->priv->vee_message_uid_hash,
			(gpointer) camel_vee_message_info_data_get_vee_message_uid (res),
			res);
	}

	camel_pstring_free (vdata.orig_message_uid);
	g_object_ref (res);

	g_mutex_unlock (&data_cache->priv->mi_mutex);

	return res;
}

/**
 * camel_vee_data_cache_get_message_info_data_by_vuid:
 * @data_cache: a #CamelVeeDataCache
 * @vee_message_uid: a message UID in the virtual folder
 *
 * Returns: (transfer full) (nullable): a referenced #CamelVeeMessageInfoData,
 *    which corresponds to the given @vee_message_uid, or %NULL, when no such
 *    message info with that virtual UID exists. Unref it with g_object_unref(),
 *    when no longer needed.
 *
 * Since: 3.6
 **/
CamelVeeMessageInfoData *
camel_vee_data_cache_get_message_info_data_by_vuid (CamelVeeDataCache *data_cache,
                                                    const gchar *vee_message_uid)
{
	CamelVeeMessageInfoData *res;
	const gchar *vuid;

	g_return_val_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache), NULL);
	g_return_val_if_fail (vee_message_uid != NULL, NULL);

	g_mutex_lock (&data_cache->priv->mi_mutex);

	/* make sure vee_message_uid comes from the string pool */
	vuid = camel_pstring_strdup (vee_message_uid);

	res = g_hash_table_lookup (data_cache->priv->vee_message_uid_hash, vuid);
	if (res)
		g_object_ref (res);

	g_mutex_unlock (&data_cache->priv->mi_mutex);

	camel_pstring_free (vuid);

	return res;
}

struct ForeachMiData {
	CamelFolder *fromfolder;
	CamelForeachInfoData func;
	gpointer user_data;
};

static void
cvdc_foreach_mi_data_cb (gpointer key,
                         gpointer value,
                         gpointer user_data)
{
	VeeData *vdata = key;
	CamelVeeMessageInfoData *mi_data = value;
	struct ForeachMiData *fmd = user_data;

	g_return_if_fail (key != NULL);
	g_return_if_fail (value != NULL);
	g_return_if_fail (user_data != NULL);

	if (!fmd->fromfolder || fmd->fromfolder == vdata->folder)
		fmd->func (mi_data, vdata->folder, fmd->user_data);
}

/**
 * camel_vee_data_cache_foreach_message_info_data:
 * @data_cache: a #CamelVeeDataCache
 * @fromfolder: a #CamelFolder
 * @func: (scope call) (closure user_data): a #CamelForeachInfoData function to call
 * @user_data: user data to pass to the @func
 *
 * Calls the @func for each message info data from the given @fromfolder
 *
 * Since: 3.6
 **/
void
camel_vee_data_cache_foreach_message_info_data (CamelVeeDataCache *data_cache,
                                                CamelFolder *fromfolder,
                                                CamelForeachInfoData func,
                                                gpointer user_data)
{
	struct ForeachMiData fmd;

	g_return_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache));
	g_return_if_fail (func != NULL);

	g_mutex_lock (&data_cache->priv->mi_mutex);

	fmd.fromfolder = fromfolder;
	fmd.func = func;
	fmd.user_data = user_data;

	g_hash_table_foreach (data_cache->priv->orig_message_uid_hash, cvdc_foreach_mi_data_cb, &fmd);

	g_mutex_unlock (&data_cache->priv->mi_mutex);
}

/**
 * camel_vee_data_cache_remove_message_info_data:
 * @data_cache: a #CamelVeeDataCache
 * @mi_data: a #CamelVeeMessageInfoData to remove
 *
 * Removes given @mi_data from the @data_cache.
 *
 * Since: 3.6
 **/
void
camel_vee_data_cache_remove_message_info_data (CamelVeeDataCache *data_cache,
                                               CamelVeeMessageInfoData *mi_data)
{
	VeeData vdata;
	CamelVeeSubfolderData *sf_data;
	const gchar *vuid;

	g_return_if_fail (CAMEL_IS_VEE_DATA_CACHE (data_cache));
	g_return_if_fail (CAMEL_IS_VEE_MESSAGE_INFO_DATA (mi_data));

	g_mutex_lock (&data_cache->priv->mi_mutex);

	g_object_ref (mi_data);

	sf_data = camel_vee_message_info_data_get_subfolder_data (mi_data);

	vdata.folder = camel_vee_subfolder_data_get_folder (sf_data);
	vdata.orig_message_uid = camel_vee_message_info_data_get_orig_message_uid (mi_data);
	vuid = camel_vee_message_info_data_get_vee_message_uid (mi_data);

	g_hash_table_remove (data_cache->priv->vee_message_uid_hash, vuid);
	g_hash_table_remove (data_cache->priv->orig_message_uid_hash, &vdata);

	g_object_unref (mi_data);

	g_mutex_unlock (&data_cache->priv->mi_mutex);
}
