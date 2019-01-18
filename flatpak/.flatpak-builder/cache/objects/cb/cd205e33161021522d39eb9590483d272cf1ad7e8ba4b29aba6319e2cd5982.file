/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-imap-conn-manager.h
 *
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
 * Authors: Chenthill Palanisamy <pchenthill@novell.com>
 */

#include "evolution-data-server-config.h"

#include <glib.h>
#include <glib/gi18n-lib.h>

#include "camel-imapx-conn-manager.h"
#include "camel-imapx-folder.h"
#include "camel-imapx-job.h"
#include "camel-imapx-settings.h"
#include "camel-imapx-store.h"
#include "camel-imapx-utils.h"

#define c(...) camel_imapx_debug(conman, __VA_ARGS__)

#define CON_READ_LOCK(x) \
	(g_rw_lock_reader_lock (&(x)->priv->rw_lock))
#define CON_READ_UNLOCK(x) \
	(g_rw_lock_reader_unlock (&(x)->priv->rw_lock))
#define CON_WRITE_LOCK(x) \
	(g_rw_lock_writer_lock (&(x)->priv->rw_lock))
#define CON_WRITE_UNLOCK(x) \
	(g_rw_lock_writer_unlock (&(x)->priv->rw_lock))

#define JOB_QUEUE_LOCK(x) g_rec_mutex_lock (&(x)->priv->job_queue_lock)
#define JOB_QUEUE_UNLOCK(x) g_rec_mutex_unlock (&(x)->priv->job_queue_lock)

#define CAMEL_IMAPX_CONN_MANAGER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_CONN_MANAGER, CamelIMAPXConnManagerPrivate))

typedef struct _ConnectionInfo ConnectionInfo;

struct _CamelIMAPXConnManagerPrivate {
	GList *connections; /* ConnectionInfo * */
	GWeakRef store;
	GRWLock rw_lock;
	guint limit_max_connections;

	GMutex pending_connections_lock;
	GSList *pending_connections; /* GCancellable * */

	gchar last_tagprefix;

	GRecMutex job_queue_lock;
	GSList *job_queue; /* CamelIMAPXJob * */

	GMutex busy_connections_lock;
	GCond busy_connections_cond;

	GMutex busy_mailboxes_lock; /* used for both busy_mailboxes and idle_mailboxes */
	GHashTable *busy_mailboxes; /* CamelIMAPXMailbox ~> gint */
	GHashTable *idle_mailboxes; /* CamelIMAPXMailbox ~> gint */

	GMutex idle_refresh_lock;
	GHashTable *idle_refresh_mailboxes; /* not-referenced CamelIMAPXMailbox, just to use for pointer comparison ~> NULL */
};

struct _ConnectionInfo {
	GMutex lock;
	CamelIMAPXServer *is;
	gboolean busy;
	gulong refresh_mailbox_handler_id;
	volatile gint ref_count;
};

enum {
	PROP_0,
	PROP_STORE
};

enum {
	CONNECTION_CREATED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (
	CamelIMAPXConnManager,
	camel_imapx_conn_manager,
	G_TYPE_OBJECT)

static gboolean
imapx_conn_manager_copy_message_sync (CamelIMAPXConnManager *conn_man,
				      CamelIMAPXMailbox *mailbox,
				      CamelIMAPXMailbox *destination,
				      GPtrArray *uids,
				      gboolean delete_originals,
				      gboolean remove_deleted_flags,
				      gboolean skip_sync_changes,
				      GCancellable *cancellable,
				      GError **error);

typedef struct _MailboxRefreshData {
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox;
} MailboxRefreshData;

static void
mailbox_refresh_data_free (MailboxRefreshData *data)
{
	if (data) {
		g_clear_object (&data->conn_man);
		g_clear_object (&data->mailbox);
		g_free (data);
	}
}

static gpointer
imapx_conn_manager_idle_mailbox_refresh_thread (gpointer user_data)
{
	MailboxRefreshData *data = user_data;
	GError *local_error = NULL;

	g_return_val_if_fail (data != NULL, NULL);

	/* passing NULL cancellable means to use only the job's abort cancellable */
	if (!camel_imapx_conn_manager_refresh_info_sync (data->conn_man, data->mailbox, NULL, &local_error)) {
		c ('*', "%s: Failed to refresh mailbox '%s': %s\n", G_STRFUNC,
			camel_imapx_mailbox_get_name (data->mailbox),
			local_error ? local_error->message : "Unknown error");
	}

	g_mutex_lock (&data->conn_man->priv->idle_refresh_lock);
	g_hash_table_remove (data->conn_man->priv->idle_refresh_mailboxes, data->mailbox);
	g_mutex_unlock (&data->conn_man->priv->idle_refresh_lock);

	mailbox_refresh_data_free (data);
	g_clear_error (&local_error);

	return NULL;
}

static void
imapx_conn_manager_refresh_mailbox_cb (CamelIMAPXServer *is,
				       CamelIMAPXMailbox *mailbox,
				       CamelIMAPXConnManager *conn_man)
{
	MailboxRefreshData *data;
	GThread *thread;
	GError *local_error = NULL;

	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (is));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	g_mutex_lock (&conn_man->priv->idle_refresh_lock);
	if (!g_hash_table_insert (conn_man->priv->idle_refresh_mailboxes, mailbox, NULL)) {
		g_mutex_unlock (&conn_man->priv->idle_refresh_lock);
		return;
	}
	g_mutex_unlock (&conn_man->priv->idle_refresh_lock);

	data = g_new0 (MailboxRefreshData, 1);
	data->conn_man = g_object_ref (conn_man);
	data->mailbox = g_object_ref (mailbox);

	thread = g_thread_try_new (NULL, imapx_conn_manager_idle_mailbox_refresh_thread, data, &local_error);
	if (!thread) {
		g_warning ("%s: Failed to create IDLE mailbox refresh thread: %s", G_STRFUNC, local_error ? local_error->message : "Unknown error");
		mailbox_refresh_data_free (data);
	} else {
		g_thread_unref (thread);
	}

	g_clear_error (&local_error);
}

static ConnectionInfo *
connection_info_new (CamelIMAPXServer *is)
{
	ConnectionInfo *cinfo;

	cinfo = g_slice_new0 (ConnectionInfo);
	g_mutex_init (&cinfo->lock);
	cinfo->is = g_object_ref (is);
	cinfo->ref_count = 1;

	return cinfo;
}

static ConnectionInfo *
connection_info_ref (ConnectionInfo *cinfo)
{
	g_return_val_if_fail (cinfo != NULL, NULL);
	g_return_val_if_fail (cinfo->ref_count > 0, NULL);

	g_atomic_int_inc (&cinfo->ref_count);

	return cinfo;
}

static void
connection_info_unref (ConnectionInfo *cinfo)
{
	g_return_if_fail (cinfo != NULL);
	g_return_if_fail (cinfo->ref_count > 0);

	if (g_atomic_int_dec_and_test (&cinfo->ref_count)) {
		if (cinfo->refresh_mailbox_handler_id)
			g_signal_handler_disconnect (cinfo->is, cinfo->refresh_mailbox_handler_id);

		g_mutex_clear (&cinfo->lock);
		g_object_unref (cinfo->is);

		g_slice_free (ConnectionInfo, cinfo);
	}
}

static gboolean
connection_info_try_reserve (ConnectionInfo *cinfo)
{
	gboolean reserved = FALSE;

	g_return_val_if_fail (cinfo != NULL, FALSE);

	g_mutex_lock (&cinfo->lock);

	if (!cinfo->busy) {
		cinfo->busy = TRUE;
		reserved = TRUE;
	}

	g_mutex_unlock (&cinfo->lock);

	return reserved;
}

static gboolean
connection_info_get_busy (ConnectionInfo *cinfo)
{
	gboolean busy;

	g_return_val_if_fail (cinfo != NULL, FALSE);

	g_mutex_lock (&cinfo->lock);

	busy = cinfo->busy;

	g_mutex_unlock (&cinfo->lock);

	return busy;
}

static void
connection_info_set_busy (ConnectionInfo *cinfo,
			  gboolean busy)
{
	g_return_if_fail (cinfo != NULL);

	g_mutex_lock (&cinfo->lock);

	cinfo->busy = busy;

	g_mutex_unlock (&cinfo->lock);
}

static void
imapx_conn_manager_signal_busy_connections (CamelIMAPXConnManager *conn_man)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	g_mutex_lock (&conn_man->priv->busy_connections_lock);
	g_cond_broadcast (&conn_man->priv->busy_connections_cond);
	g_mutex_unlock (&conn_man->priv->busy_connections_lock);
}

static void
imapx_conn_manager_unmark_busy (CamelIMAPXConnManager *conn_man,
				ConnectionInfo *cinfo)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (cinfo != NULL);
	g_return_if_fail (connection_info_get_busy (cinfo));

	connection_info_set_busy (cinfo, FALSE);

	imapx_conn_manager_signal_busy_connections (conn_man);
}

static gboolean
imapx_conn_manager_remove_info (CamelIMAPXConnManager *conn_man,
                                ConnectionInfo *cinfo)
{
	GList *list, *link;
	gboolean removed = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (cinfo != NULL, FALSE);

	CON_WRITE_LOCK (conn_man);

	list = conn_man->priv->connections;
	link = g_list_find (list, cinfo);

	if (link != NULL) {
		list = g_list_delete_link (list, link);
		connection_info_unref (cinfo);
		removed = TRUE;
	}

	conn_man->priv->connections = list;

	CON_WRITE_UNLOCK (conn_man);

	if (removed)
		imapx_conn_manager_signal_busy_connections (conn_man);

	return removed;
}

static void
imapx_conn_manager_cancel_pending_connections (CamelIMAPXConnManager *conn_man)
{
	GSList *link;

	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	g_mutex_lock (&conn_man->priv->pending_connections_lock);
	for (link = conn_man->priv->pending_connections; link; link = g_slist_next (link)) {
		GCancellable *cancellable = link->data;

		if (cancellable)
			g_cancellable_cancel (cancellable);
	}
	g_mutex_unlock (&conn_man->priv->pending_connections_lock);
}

static void
imapx_conn_manager_abort_jobs (CamelIMAPXConnManager *conn_man)
{
	GSList *link;

	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	JOB_QUEUE_LOCK (conn_man);

	for (link = conn_man->priv->job_queue; link; link = g_slist_next (link)) {
		CamelIMAPXJob *job = link->data;

		if (job)
			camel_imapx_job_abort (job);
	}

	JOB_QUEUE_UNLOCK (conn_man);
}

static CamelFolder *
imapx_conn_manager_ref_folder_sync (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXMailbox *mailbox,
				    GCancellable *cancellable,
				    GError **error)
{
	CamelIMAPXStore *store;
	CamelFolder *folder;
	gchar *folder_path;

	store = camel_imapx_conn_manager_ref_store (conn_man);
	folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);

	folder = camel_store_get_folder_sync (CAMEL_STORE (store), folder_path, 0, cancellable, NULL);
	if (folder)
		camel_imapx_folder_set_mailbox (CAMEL_IMAPX_FOLDER (folder), mailbox);

	g_free (folder_path);
	g_clear_object (&store);

	return folder;
}

static void
imapx_conn_manager_inc_mailbox_hash (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox,
				     GHashTable *mailboxes_hash)
{
	gint count;

	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (mailboxes_hash != NULL);

	g_mutex_lock (&conn_man->priv->busy_mailboxes_lock);

	count = GPOINTER_TO_INT (g_hash_table_lookup (mailboxes_hash, mailbox));
	count++;

	g_hash_table_insert (mailboxes_hash, g_object_ref (mailbox), GINT_TO_POINTER (count));

	g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);
}

static void
imapx_conn_manager_dec_mailbox_hash (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox,
				     GHashTable *mailboxes_hash)
{
	gint count;

	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (mailboxes_hash != NULL);

	g_mutex_lock (&conn_man->priv->busy_mailboxes_lock);

	count = GPOINTER_TO_INT (g_hash_table_lookup (mailboxes_hash, mailbox));
	if (!count) {
		g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);
		return;
	}

	count--;

	if (count)
		g_hash_table_insert (mailboxes_hash, g_object_ref (mailbox), GINT_TO_POINTER (count));
	else
		g_hash_table_remove (mailboxes_hash, mailbox);

	g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);
}

static gboolean
imapx_conn_manager_is_mailbox_hash (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXMailbox *mailbox,
				    GHashTable *mailboxes_hash)
{
	gint count;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (mailboxes_hash != NULL, FALSE);

	g_mutex_lock (&conn_man->priv->busy_mailboxes_lock);

	count = GPOINTER_TO_INT (g_hash_table_lookup (mailboxes_hash, mailbox));

	g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);

	return count > 0;
}

static void
imapx_conn_manager_clear_mailboxes_hashes (CamelIMAPXConnManager *conn_man)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	g_mutex_lock (&conn_man->priv->busy_mailboxes_lock);

	g_hash_table_remove_all (conn_man->priv->busy_mailboxes);
	g_hash_table_remove_all (conn_man->priv->idle_mailboxes);

	g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);
}

static void
imapx_conn_manager_inc_mailbox_busy (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	imapx_conn_manager_inc_mailbox_hash (conn_man, mailbox, conn_man->priv->busy_mailboxes);
}

static void
imapx_conn_manager_dec_mailbox_busy (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	imapx_conn_manager_dec_mailbox_hash (conn_man, mailbox, conn_man->priv->busy_mailboxes);
}

static gboolean
imapx_conn_manager_is_mailbox_busy (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	return imapx_conn_manager_is_mailbox_hash (conn_man, mailbox, conn_man->priv->busy_mailboxes);
}

static void
imapx_conn_manager_inc_mailbox_idle (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	imapx_conn_manager_inc_mailbox_hash (conn_man, mailbox, conn_man->priv->idle_mailboxes);
}

static void
imapx_conn_manager_dec_mailbox_idle (CamelIMAPXConnManager *conn_man,
				     CamelIMAPXMailbox *mailbox)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	imapx_conn_manager_dec_mailbox_hash (conn_man, mailbox, conn_man->priv->idle_mailboxes);
}

static gboolean
imapx_conn_manager_is_mailbox_idle (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	return imapx_conn_manager_is_mailbox_hash (conn_man, mailbox, conn_man->priv->idle_mailboxes);
}

static gboolean
imapx_conn_manager_has_inbox_idle (CamelIMAPXConnManager *conn_man)
{
	CamelIMAPXStore *imapx_store;
	CamelIMAPXMailbox *inbox_mailbox;
	gboolean is_idle;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);
	inbox_mailbox = imapx_store ? camel_imapx_store_ref_mailbox (imapx_store, "INBOX") : NULL;

	g_clear_object (&imapx_store);

	is_idle = inbox_mailbox && imapx_conn_manager_is_mailbox_idle (conn_man, inbox_mailbox);

	g_clear_object (&inbox_mailbox);

	return is_idle;
}

static void
imapx_conn_manager_set_store (CamelIMAPXConnManager *conn_man,
                              CamelStore *store)
{
	g_return_if_fail (CAMEL_IS_STORE (store));

	g_weak_ref_set (&conn_man->priv->store, store);
}

static void
imapx_conn_manager_set_property (GObject *object,
                                 guint property_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			imapx_conn_manager_set_store (
				CAMEL_IMAPX_CONN_MANAGER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_conn_manager_get_property (GObject *object,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			g_value_take_object (
				value,
				camel_imapx_conn_manager_ref_store (
				CAMEL_IMAPX_CONN_MANAGER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_conn_manager_dispose (GObject *object)
{
	CamelIMAPXConnManager *conn_man;

	conn_man = CAMEL_IMAPX_CONN_MANAGER (object);

	imapx_conn_manager_cancel_pending_connections (conn_man);
	imapx_conn_manager_abort_jobs (conn_man);

	g_list_free_full (
		conn_man->priv->connections,
		(GDestroyNotify) connection_info_unref);
	conn_man->priv->connections = NULL;

	g_weak_ref_set (&conn_man->priv->store, NULL);

	g_mutex_lock (&conn_man->priv->busy_mailboxes_lock);
	g_hash_table_remove_all (conn_man->priv->busy_mailboxes);
	g_hash_table_remove_all (conn_man->priv->idle_mailboxes);
	g_mutex_unlock (&conn_man->priv->busy_mailboxes_lock);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_conn_manager_parent_class)->dispose (object);
}

static void
imapx_conn_manager_finalize (GObject *object)
{
	CamelIMAPXConnManagerPrivate *priv;

	priv = CAMEL_IMAPX_CONN_MANAGER_GET_PRIVATE (object);

	g_warn_if_fail (priv->pending_connections == NULL);
	g_warn_if_fail (priv->job_queue == NULL);

	g_rw_lock_clear (&priv->rw_lock);
	g_rec_mutex_clear (&priv->job_queue_lock);
	g_mutex_clear (&priv->pending_connections_lock);
	g_mutex_clear (&priv->busy_connections_lock);
	g_cond_clear (&priv->busy_connections_cond);
	g_weak_ref_clear (&priv->store);
	g_mutex_clear (&priv->busy_mailboxes_lock);
	g_hash_table_destroy (priv->busy_mailboxes);
	g_hash_table_destroy (priv->idle_mailboxes);
	g_mutex_clear (&priv->idle_refresh_lock);
	g_hash_table_destroy (priv->idle_refresh_mailboxes);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_conn_manager_parent_class)->finalize (object);
}

static void
camel_imapx_conn_manager_class_init (CamelIMAPXConnManagerClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXConnManagerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_conn_manager_set_property;
	object_class->get_property = imapx_conn_manager_get_property;
	object_class->dispose = imapx_conn_manager_dispose;
	object_class->finalize = imapx_conn_manager_finalize;

	g_object_class_install_property (
		object_class,
		PROP_STORE,
		g_param_spec_object (
			"store",
			"Store",
			"The CamelIMAPXStore to which we belong",
			CAMEL_TYPE_IMAPX_STORE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	signals[CONNECTION_CREATED] = g_signal_new (
		"connection-created",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelIMAPXConnManagerClass, connection_created),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_IMAPX_SERVER);
}

static void
camel_imapx_conn_manager_init (CamelIMAPXConnManager *conn_man)
{
	conn_man->priv = CAMEL_IMAPX_CONN_MANAGER_GET_PRIVATE (conn_man);

	g_rw_lock_init (&conn_man->priv->rw_lock);
	g_rec_mutex_init (&conn_man->priv->job_queue_lock);
	g_mutex_init (&conn_man->priv->pending_connections_lock);
	g_mutex_init (&conn_man->priv->busy_connections_lock);
	g_cond_init (&conn_man->priv->busy_connections_cond);
	g_weak_ref_init (&conn_man->priv->store, NULL);
	g_mutex_init (&conn_man->priv->busy_mailboxes_lock);
	g_mutex_init (&conn_man->priv->idle_refresh_lock);

	conn_man->priv->last_tagprefix = 'A' - 1;
	conn_man->priv->busy_mailboxes = g_hash_table_new_full (g_direct_hash, g_direct_equal, g_object_unref, NULL);
	conn_man->priv->idle_mailboxes = g_hash_table_new_full (g_direct_hash, g_direct_equal, g_object_unref, NULL);
	conn_man->priv->idle_refresh_mailboxes = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, NULL);
}

static gchar
imapx_conn_manager_get_next_free_tagprefix_unlocked (CamelIMAPXConnManager *conn_man)
{
	gchar adept;
	gint ii;
	GList *iter;

	adept = conn_man->priv->last_tagprefix + 1;

	/* the 'Z' is dedicated to auth types query */
	if (adept >= 'Z')
		adept = 'A';
	else if (adept < 'A')
		adept = 'A';

	for (ii = 0; ii < 26; ii++) {
		for (iter = conn_man->priv->connections; iter; iter = g_list_next (iter)) {
			ConnectionInfo *cinfo = iter->data;

			if (!cinfo || !cinfo->is)
				continue;

			if (camel_imapx_server_get_tagprefix (cinfo->is) == adept)
				break;
		}

		/* Read all current active connections and none has the same tag prefix */
		if (!iter)
			break;

		adept++;
		if (adept >= 'Z')
			adept = 'A';
	}

	g_return_val_if_fail (adept >= 'A' && adept < 'Z', 'Z');

	conn_man->priv->last_tagprefix = adept;

	return adept;
}

static ConnectionInfo *
imapx_create_new_connection_unlocked (CamelIMAPXConnManager *conn_man,
                                      CamelIMAPXMailbox *mailbox,
                                      GCancellable *cancellable,
                                      GError **error)
{
	CamelIMAPXServer *is = NULL;
	CamelIMAPXStore *imapx_store;
	ConnectionInfo *cinfo = NULL;
	gboolean success;

	/* Caller must be holding CON_WRITE_LOCK. */

	/* Check if we got cancelled while we were waiting. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return NULL;

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);
	g_return_val_if_fail (imapx_store != NULL, NULL);

	is = camel_imapx_server_new (imapx_store);
	camel_imapx_server_set_tagprefix (is, imapx_conn_manager_get_next_free_tagprefix_unlocked (conn_man));

	g_signal_emit (conn_man, signals[CONNECTION_CREATED], 0, is);

	/* XXX As part of the connect operation the CamelIMAPXServer will
	 *     have to call camel_session_authenticate_sync(), but it has
	 *     no way to pass itself through in that call so the service
	 *     knows which CamelIMAPXServer is trying to authenticate.
	 *
	 *     IMAPX is the only provider that does multiple connections
	 *     like this, so I didn't want to pollute the CamelSession and
	 *     CamelService authentication APIs with an extra argument.
	 *     Instead we do this little hack so the service knows which
	 *     CamelIMAPXServer to act on in its authenticate_sync() method.
	 *
	 *     Because we're holding the CAMEL_SERVICE_REC_CONNECT_LOCK
	 *     we should not have multiple IMAPX connections trying to
	 *     authenticate at once, so this should be thread-safe.
	 */
	camel_imapx_store_set_connecting_server (imapx_store, is, conn_man->priv->connections != NULL);
	success = camel_imapx_server_connect_sync (is, cancellable, error);
	camel_imapx_store_set_connecting_server (imapx_store, NULL, FALSE);

	if (!success)
		goto exit;

	cinfo = connection_info_new (is);

	cinfo->refresh_mailbox_handler_id = g_signal_connect (
		is, "refresh-mailbox", G_CALLBACK (imapx_conn_manager_refresh_mailbox_cb), conn_man);

	/* Takes ownership of the ConnectionInfo. */
	conn_man->priv->connections = g_list_append (conn_man->priv->connections, cinfo);

	c (camel_imapx_server_get_tagprefix (is), "Created new connection %p (server:%p) for %s; total connections %d\n",
		cinfo, cinfo->is,
		mailbox ? camel_imapx_mailbox_get_name (mailbox) : "[null]",
		g_list_length (conn_man->priv->connections));

exit:
	g_object_unref (imapx_store);
	g_clear_object (&is);

	return cinfo;
}

static gint
imapx_conn_manager_get_max_connections (CamelIMAPXConnManager *conn_man)
{
	CamelIMAPXStore *imapx_store;
	CamelSettings *settings;
	gint max_connections;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), -1);

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);
	if (!imapx_store)
		return -1;

	settings = camel_service_ref_settings (CAMEL_SERVICE (imapx_store));

	max_connections = camel_imapx_settings_get_concurrent_connections (CAMEL_IMAPX_SETTINGS (settings));

	if (conn_man->priv->limit_max_connections > 0 &&
	    conn_man->priv->limit_max_connections < max_connections)
		max_connections = conn_man->priv->limit_max_connections;

	g_object_unref (settings);
	g_object_unref (imapx_store);

	return max_connections > 0 ? max_connections : 1;
}

static void
imapx_conn_manager_connection_wait_cancelled_cb (GCancellable *cancellable,
						 CamelIMAPXConnManager *conn_man)
{
	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	imapx_conn_manager_signal_busy_connections (conn_man);
}

static ConnectionInfo *
camel_imapx_conn_manager_ref_connection (CamelIMAPXConnManager *conn_man,
					 CamelIMAPXMailbox *mailbox,
					 gboolean *out_is_new_connection,
					 GCancellable *cancellable,
					 GError **error)
{
	ConnectionInfo *cinfo = NULL;
	CamelIMAPXStore *imapx_store;
	CamelSession *session;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), NULL);

	if (out_is_new_connection)
		*out_is_new_connection = FALSE;

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);
	if (!imapx_store)
		return NULL;

	session = camel_service_ref_session (CAMEL_SERVICE (imapx_store));

	if (camel_offline_store_get_online (CAMEL_OFFLINE_STORE (imapx_store)) &&
	    session && camel_session_get_online (session)) {

		g_mutex_lock (&conn_man->priv->pending_connections_lock);
		cancellable = camel_operation_new_proxy (cancellable);
		conn_man->priv->pending_connections = g_slist_prepend (conn_man->priv->pending_connections, cancellable);
		g_mutex_unlock (&conn_man->priv->pending_connections_lock);

		/* Hold the writer lock while we requisition a CamelIMAPXServer
		 * to prevent other threads from adding or removing connections. */
		CON_READ_LOCK (conn_man);

		/* Check if we've got cancelled while waiting for the lock. */
		while (!cinfo && !g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
			gint opened_connections, max_connections;
			GList *link;

			for (link = conn_man->priv->connections; link; link = g_list_next (link)) {
				ConnectionInfo *candidate = link->data;

				if (candidate && connection_info_try_reserve (candidate)) {
					cinfo = connection_info_ref (candidate);
					break;
				}
			}

			if (cinfo)
				break;

			opened_connections = g_list_length (conn_man->priv->connections);
			max_connections = imapx_conn_manager_get_max_connections (conn_man);

			if (max_connections <= 0)
				break;

			if (!cinfo && opened_connections < max_connections) {
				GError *local_error_2 = NULL;

				CON_READ_UNLOCK (conn_man);
				CON_WRITE_LOCK (conn_man);
				cinfo = imapx_create_new_connection_unlocked (conn_man, mailbox, cancellable, &local_error_2);
				if (cinfo)
					connection_info_set_busy (cinfo, TRUE);
				CON_WRITE_UNLOCK (conn_man);
				CON_READ_LOCK (conn_man);

				if (!cinfo) {
					gboolean limit_connections =
						g_error_matches (local_error_2, CAMEL_IMAPX_SERVER_ERROR,
						CAMEL_IMAPX_SERVER_ERROR_CONCURRENT_CONNECT_FAILED) &&
						conn_man->priv->connections;

					c ('*', "Failed to open a new connection, while having %d opened, with error: %s; will limit connections: %s\n",
						g_list_length (conn_man->priv->connections),
						local_error_2 ? local_error_2->message : "Unknown error",
						limit_connections ? "yes" : "no");

					if (limit_connections) {
						/* limit to one-less than current connection count - be nice to the server */
						conn_man->priv->limit_max_connections = g_list_length (conn_man->priv->connections) - 1;
						if (!conn_man->priv->limit_max_connections)
							conn_man->priv->limit_max_connections = 1;

						g_clear_error (&local_error_2);
					} else {
						if (local_error_2)
							g_propagate_error (&local_error, local_error_2);
						break;
					}
				} else {
					connection_info_ref (cinfo);

					if (out_is_new_connection)
						*out_is_new_connection = TRUE;
				}
			}

			if (!cinfo) {
				gulong handler_id;

				CON_READ_UNLOCK (conn_man);

				handler_id = g_cancellable_connect (cancellable, G_CALLBACK (imapx_conn_manager_connection_wait_cancelled_cb), conn_man, NULL);

				g_mutex_lock (&conn_man->priv->busy_connections_lock);
				g_cond_wait (&conn_man->priv->busy_connections_cond, &conn_man->priv->busy_connections_lock);
				g_mutex_unlock (&conn_man->priv->busy_connections_lock);

				if (handler_id)
					g_cancellable_disconnect (cancellable, handler_id);

				CON_READ_LOCK (conn_man);
			}
		}

		CON_READ_UNLOCK (conn_man);

		g_mutex_lock (&conn_man->priv->pending_connections_lock);
		conn_man->priv->pending_connections = g_slist_remove (conn_man->priv->pending_connections, cancellable);
		g_object_unref (cancellable);
		g_mutex_unlock (&conn_man->priv->pending_connections_lock);
	}

	g_clear_object (&imapx_store);
	g_clear_object (&session);

	if (!cinfo && (!local_error || local_error->domain == G_RESOLVER_ERROR)) {
		if (local_error) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_UNAVAILABLE,
				_("You must be working online to complete this operation (%s)"),
				local_error->message);

			g_clear_error (&local_error);
		} else {
			g_set_error_literal (
				&local_error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_UNAVAILABLE,
				_("You must be working online to complete this operation"));
		}
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return cinfo;
}

/****************************/

CamelIMAPXConnManager *
camel_imapx_conn_manager_new (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	return g_object_new (
		CAMEL_TYPE_IMAPX_CONN_MANAGER, "store", store, NULL);
}

CamelIMAPXStore *
camel_imapx_conn_manager_ref_store (CamelIMAPXConnManager *conn_man)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), NULL);

	return g_weak_ref_get (&conn_man->priv->store);
}

gboolean
camel_imapx_conn_manager_connect_sync (CamelIMAPXConnManager *conn_man,
				       GCancellable *cancellable,
				       GError **error)
{
	ConnectionInfo *cinfo;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	CON_READ_LOCK (conn_man);
	if (conn_man->priv->connections) {
		CON_READ_UNLOCK (conn_man);
		return TRUE;
	}
	CON_READ_UNLOCK (conn_man);

	imapx_conn_manager_clear_mailboxes_hashes (conn_man);

	cinfo = camel_imapx_conn_manager_ref_connection (conn_man, NULL, NULL, cancellable, error);
	if (cinfo) {
		imapx_conn_manager_unmark_busy (conn_man, cinfo);
		connection_info_unref (cinfo);
	}

	return cinfo != NULL;
}

gboolean
camel_imapx_conn_manager_disconnect_sync (CamelIMAPXConnManager *conn_man,
					  GCancellable *cancellable,
					  GError **error)
{
	GList *link, *connections;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	/* Do this before acquiring the write lock, because any pending
	   connection holds the write lock, thus makes this request starve. */
	imapx_conn_manager_cancel_pending_connections (conn_man);
	imapx_conn_manager_abort_jobs (conn_man);

	CON_WRITE_LOCK (conn_man);

	c ('*', "Disconnecting all %d connections\n", g_list_length (conn_man->priv->connections));

	connections = conn_man->priv->connections;
	conn_man->priv->connections = NULL;

	CON_WRITE_UNLOCK (conn_man);

	for (link = connections; link; link = g_list_next (link)) {
		ConnectionInfo *cinfo = link->data;
		GError *local_error = NULL;

		if (!cinfo)
			continue;

		if (!camel_imapx_server_disconnect_sync (cinfo->is, cancellable, &local_error)) {
			c (camel_imapx_server_get_tagprefix (cinfo->is), "   Failed to disconnect from the server: %s\n",
				local_error ? local_error->message : "Unknown error");
		}

		connection_info_unref (cinfo);
		g_clear_error (&local_error);
	}

	g_list_free (connections);

	imapx_conn_manager_clear_mailboxes_hashes (conn_man);

	return TRUE;
}

static gboolean
imapx_conn_manager_should_wait_for (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXJob *new_job,
				    CamelIMAPXJob *queued_job)
{
	guint32 job_kind;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (queued_job != NULL, FALSE);

	if (camel_imapx_job_get_kind (new_job) == CAMEL_IMAPX_JOB_GET_MESSAGE)
		return FALSE;

	job_kind = camel_imapx_job_get_kind (queued_job);

	/* List jobs with high priority. */
	return job_kind == CAMEL_IMAPX_JOB_GET_MESSAGE ||
	       job_kind == CAMEL_IMAPX_JOB_COPY_MESSAGE ||
	       job_kind == CAMEL_IMAPX_JOB_MOVE_MESSAGE ||
	       job_kind == CAMEL_IMAPX_JOB_EXPUNGE;
}

gboolean
camel_imapx_conn_manager_run_job_sync (CamelIMAPXConnManager *conn_man,
				       CamelIMAPXJob *job,
				       CamelIMAPXJobMatchesFunc finish_before_job,
				       GCancellable *cancellable,
				       GError **error)
{
	GSList *link;
	ConnectionInfo *cinfo;
	gboolean success = FALSE, is_new_connection = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);
	g_return_val_if_fail (job != NULL, FALSE);

	JOB_QUEUE_LOCK (conn_man);

	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		JOB_QUEUE_UNLOCK (conn_man);
		return FALSE;
	}

	link = conn_man->priv->job_queue;
	while (link) {
		CamelIMAPXJob *queued_job = link->data;
		gboolean matches;

		g_warn_if_fail (queued_job != NULL);
		g_warn_if_fail (queued_job != job);

		if (!queued_job) {
			link = g_slist_next (link);
			continue;
		}

		matches = camel_imapx_job_matches (job, queued_job);
		if (matches || (finish_before_job && finish_before_job (job, queued_job)) ||
		    imapx_conn_manager_should_wait_for (conn_man, job, queued_job)) {
			camel_imapx_job_ref (queued_job);

			JOB_QUEUE_UNLOCK (conn_man);

			camel_imapx_job_wait_sync (queued_job, cancellable);

			if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
				camel_imapx_job_unref (queued_job);
				return FALSE;
			}

			if (matches) {
				gpointer result = NULL;
				GDestroyNotify destroy_result = NULL;

				/* Do not inherit cancelled errors, just try again */
				if (!camel_imapx_job_was_cancelled (queued_job) &&
				    camel_imapx_job_copy_result (queued_job, &success, &result, &local_error, &destroy_result)) {
					camel_imapx_job_set_result (job, success, result, local_error, destroy_result);
					camel_imapx_job_unref (queued_job);

					if (local_error)
						g_propagate_error (error, local_error);

					return success;
				}
			}

			JOB_QUEUE_LOCK (conn_man);

			camel_imapx_job_unref (queued_job);

			/* The queue could change, start from the beginning. */
			link = conn_man->priv->job_queue;
		} else {
			link = g_slist_next (link);
		}
	}

	conn_man->priv->job_queue = g_slist_prepend (conn_man->priv->job_queue, job);

	JOB_QUEUE_UNLOCK (conn_man);

	do {
		g_clear_error (&local_error);

		cinfo = camel_imapx_conn_manager_ref_connection (conn_man, camel_imapx_job_get_mailbox (job), &is_new_connection, cancellable, error);
		if (cinfo) {
			CamelIMAPXMailbox *job_mailbox;

			job_mailbox = camel_imapx_job_get_mailbox (job);

			if (job_mailbox)
				imapx_conn_manager_inc_mailbox_busy (conn_man, job_mailbox);

			if (camel_imapx_server_is_in_idle (cinfo->is)) {
				CamelIMAPXMailbox *idle_mailbox;

				idle_mailbox = camel_imapx_server_ref_idle_mailbox (cinfo->is);
				if (idle_mailbox)
					imapx_conn_manager_dec_mailbox_idle (conn_man, idle_mailbox);
				g_clear_object (&idle_mailbox);
			}

			success = camel_imapx_server_stop_idle_sync (cinfo->is, cancellable, &local_error);

			if (success && camel_imapx_server_can_use_idle (cinfo->is)) {
				GList *link, *connection_infos, *disconnected_infos = NULL;

				CON_READ_LOCK (conn_man);
				connection_infos = g_list_copy (conn_man->priv->connections);
				g_list_foreach (connection_infos, (GFunc) connection_info_ref, NULL);
				CON_READ_UNLOCK (conn_man);

				/* Stop IDLE on all connections serving the same mailbox,
				   to avoid notifications for changes done by itself */
				for (link = connection_infos; link && !g_cancellable_is_cancelled (cancellable); link = g_list_next (link)) {
					ConnectionInfo *other_cinfo = link->data;
					CamelIMAPXMailbox *other_mailbox;

					if (!other_cinfo || other_cinfo == cinfo || connection_info_get_busy (other_cinfo) ||
					    !camel_imapx_server_is_in_idle (other_cinfo->is))
						continue;

					other_mailbox = camel_imapx_server_ref_idle_mailbox (other_cinfo->is);
					if (job_mailbox == other_mailbox) {
						if (!camel_imapx_server_stop_idle_sync (other_cinfo->is, cancellable, &local_error)) {
							c (camel_imapx_server_get_tagprefix (other_cinfo->is),
								"Failed to stop IDLE call (will be removed) on connection %p (server:%p) due to error: %s\n",
								other_cinfo, other_cinfo->is, local_error ? local_error->message : "Unknown error");

							camel_imapx_server_disconnect_sync (other_cinfo->is, cancellable, NULL);

							disconnected_infos = g_list_prepend (disconnected_infos, connection_info_ref (other_cinfo));
						} else {
							imapx_conn_manager_dec_mailbox_idle (conn_man, other_mailbox);
						}

						g_clear_error (&local_error);
					}

					g_clear_object (&other_mailbox);
				}

				for (link = disconnected_infos; link; link = g_list_next (link)) {
					ConnectionInfo *other_cinfo = link->data;

					imapx_conn_manager_remove_info (conn_man, other_cinfo);
				}

				g_list_free_full (disconnected_infos, (GDestroyNotify) connection_info_unref);
				g_list_free_full (connection_infos, (GDestroyNotify) connection_info_unref);
			}

			if (success)
				success = camel_imapx_job_run_sync (job, cinfo->is, cancellable, &local_error);

			if (job_mailbox)
				imapx_conn_manager_dec_mailbox_busy (conn_man, job_mailbox);

			if (success) {
				CamelIMAPXMailbox *idle_mailbox = NULL;

				if (!imapx_conn_manager_has_inbox_idle (conn_man)) {
					CamelIMAPXStore *imapx_store;

					imapx_store = camel_imapx_conn_manager_ref_store (conn_man);
					idle_mailbox = imapx_store ? camel_imapx_store_ref_mailbox (imapx_store, "INBOX") : NULL;

					g_clear_object (&imapx_store);
				}

				if (!idle_mailbox)
					idle_mailbox = camel_imapx_server_ref_selected (cinfo->is);

				/* Can start IDLE on the connection only if the IDLE folder is not busy
				   and not in IDLE already, to avoid multiple IDLE notifications on the same mailbox */
				if (idle_mailbox && camel_imapx_server_can_use_idle (cinfo->is) &&
				    !imapx_conn_manager_is_mailbox_busy (conn_man, idle_mailbox) &&
				    !imapx_conn_manager_is_mailbox_idle (conn_man, idle_mailbox)) {
					camel_imapx_server_schedule_idle_sync (cinfo->is, idle_mailbox, cancellable, NULL);

					if (camel_imapx_server_is_in_idle (cinfo->is)) {
						g_clear_object (&idle_mailbox);

						idle_mailbox = camel_imapx_server_ref_idle_mailbox (cinfo->is);
						if (idle_mailbox)
							imapx_conn_manager_inc_mailbox_idle (conn_man, idle_mailbox);
					}
				}

				g_clear_object (&idle_mailbox);

				imapx_conn_manager_unmark_busy (conn_man, cinfo);
			} else if (!local_error || ((local_error->domain == G_IO_ERROR || local_error->domain == G_TLS_ERROR || local_error->domain == CAMEL_IMAPX_ERROR ||
				   g_error_matches (local_error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT)) &&
				   !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED))) {
				c (camel_imapx_server_get_tagprefix (cinfo->is), "Removed connection %p (server:%p) due to error: %s\n",
					cinfo, cinfo->is, local_error ? local_error->message : "Unknown error");

				camel_imapx_server_disconnect_sync (cinfo->is, cancellable, NULL);
				imapx_conn_manager_remove_info (conn_man, cinfo);

				if (!local_error ||
				    g_error_matches (local_error, G_TLS_ERROR, G_TLS_ERROR_MISC) ||
				    g_error_matches (local_error, G_TLS_ERROR, G_TLS_ERROR_EOF) ||
				    g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CLOSED)) {
					GError *tmp = local_error;

					local_error = NULL;

					/* This message won't get into UI. */
					g_set_error (&local_error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
						"Reconnect after failure: %s", tmp ? tmp->message : "Unknown error");

					g_clear_error (&tmp);
				}
			} else {
				c (camel_imapx_server_get_tagprefix (cinfo->is), "Unmark connection %p (server:%p) busy after failure, error: %s\n",
					cinfo, cinfo->is, local_error ? local_error->message : "Unknown error");

				imapx_conn_manager_unmark_busy (conn_man, cinfo);
			}

			connection_info_unref (cinfo);
		}

		/* If there's a reconnect required for a new connection, then there happened
		   something really wrong, thus rather give up. */
	} while (!success && !is_new_connection && g_error_matches (local_error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT));

	if (local_error)
		g_propagate_error (error, local_error);

	JOB_QUEUE_LOCK (conn_man);
	conn_man->priv->job_queue = g_slist_remove (conn_man->priv->job_queue, job);
	JOB_QUEUE_UNLOCK (conn_man);

	camel_imapx_job_done (job);

	return success;
}

static gboolean
imapx_conn_manager_noop_run_sync (CamelIMAPXJob *job,
				  CamelIMAPXServer *server,
				  GCancellable *cancellable,
				  GError **error)
{
	CamelIMAPXMailbox *mailbox;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_noop_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_noop_sync (CamelIMAPXConnManager *conn_man,
				    CamelIMAPXMailbox *mailbox,
				    GCancellable *cancellable,
				    GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_NOOP, mailbox,
		imapx_conn_manager_noop_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_nothing_matches (CamelIMAPXJob *job,
				    CamelIMAPXJob *other_job)
{
	/* For jobs where none can match. */
	return FALSE;
}

static gboolean
imapx_conn_manager_matches_sync_changes_or_refresh_info (CamelIMAPXJob *job,
							 CamelIMAPXJob *other_job)
{
	CamelIMAPXJobKind other_job_kind;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);
	g_return_val_if_fail (job != other_job, FALSE);

	if (camel_imapx_job_get_mailbox (job) != camel_imapx_job_get_mailbox (other_job))
		return FALSE;

	other_job_kind = camel_imapx_job_get_kind (other_job);

	return other_job_kind == CAMEL_IMAPX_JOB_SYNC_CHANGES ||
	       other_job_kind == CAMEL_IMAPX_JOB_REFRESH_INFO;
}

struct ListJobData {
	gchar *pattern;
	CamelStoreGetFolderInfoFlags flags;
};

static void
list_job_data_free (gpointer ptr)
{
	struct ListJobData *job_data = ptr;

	if (job_data) {
		g_free (job_data->pattern);
		g_free (job_data);
	}
}

static gboolean
imapx_conn_manager_list_run_sync (CamelIMAPXJob *job,
				  CamelIMAPXServer *server,
				  GCancellable *cancellable,
				  GError **error)
{
	struct ListJobData *job_data;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);

	return camel_imapx_server_list_sync (server, job_data->pattern, job_data->flags, cancellable, error);
}

static gboolean
imapx_conn_manager_list_matches (CamelIMAPXJob *job,
				 CamelIMAPXJob *other_job)
{
	struct ListJobData *job_data, *other_job_data;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);

	if (camel_imapx_job_get_kind (job) != CAMEL_IMAPX_JOB_LIST ||
	    camel_imapx_job_get_kind (job) != camel_imapx_job_get_kind (other_job))
		return FALSE;

	job_data = camel_imapx_job_get_user_data (job);
	other_job_data = camel_imapx_job_get_user_data (other_job);

	if (!job_data || !other_job_data)
		return FALSE;

	return job_data->flags == other_job_data->flags &&
	       g_strcmp0 (job_data->pattern, other_job_data->pattern) == 0;
}

gboolean
camel_imapx_conn_manager_list_sync (CamelIMAPXConnManager *conn_man,
				    const gchar *pattern,
				    CamelStoreGetFolderInfoFlags flags,
				    GCancellable *cancellable,
				    GError **error)
{
	CamelIMAPXJob *job;
	struct ListJobData *job_data;
	gboolean success = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_LIST, NULL,
		imapx_conn_manager_list_run_sync,
		imapx_conn_manager_list_matches,
		NULL);

	job_data = g_new0 (struct ListJobData, 1);
	job_data->pattern = g_strdup (pattern);
	job_data->flags = flags;

	camel_imapx_job_set_user_data (job, job_data, list_job_data_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);
	if (success)
		camel_imapx_job_copy_result (job, &success, NULL, error, NULL);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_refresh_info_run_sync (CamelIMAPXJob *job,
					  CamelIMAPXServer *server,
					  GCancellable *cancellable,
					  GError **error)
{
	CamelIMAPXMailbox *mailbox;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_refresh_info_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_refresh_info_sync (CamelIMAPXConnManager *conn_man,
					    CamelIMAPXMailbox *mailbox,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	if (!camel_imapx_conn_manager_sync_changes_sync (conn_man, mailbox, cancellable, error))
		return FALSE;

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_REFRESH_INFO, mailbox,
		imapx_conn_manager_refresh_info_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job,
		imapx_conn_manager_matches_sync_changes_or_refresh_info,
		cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_move_to_real_junk_sync (CamelIMAPXConnManager *conn_man,
					   CamelFolder *folder,
					   GCancellable *cancellable,
					   gboolean *out_need_to_expunge,
					   GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXMailbox *mailbox;
	CamelIMAPXSettings *settings;
	GPtrArray *uids_to_copy;
	gchar *real_junk_path = NULL;
	gboolean success = TRUE;

	*out_need_to_expunge = FALSE;

	/* Caller already obtained the mailbox from the folder,
	 * so the folder should still have it readily available. */
	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	mailbox = camel_imapx_folder_ref_mailbox (imapx_folder);
	g_return_val_if_fail (mailbox != NULL, FALSE);

	uids_to_copy = g_ptr_array_new_with_free_func (
		(GDestroyNotify) camel_pstring_free);

	settings = CAMEL_IMAPX_SETTINGS (camel_service_ref_settings (CAMEL_SERVICE (camel_folder_get_parent_store (folder))));
	if (camel_imapx_settings_get_use_real_junk_path (settings)) {
		real_junk_path = camel_imapx_settings_dup_real_junk_path (settings);
		camel_imapx_folder_claim_move_to_real_junk_uids (imapx_folder, uids_to_copy);
	}
	g_object_unref (settings);

	if (uids_to_copy->len > 0) {
		CamelIMAPXStore *imapx_store;
		CamelIMAPXMailbox *destination = NULL;

		imapx_store = camel_imapx_conn_manager_ref_store (conn_man);

		if (real_junk_path != NULL) {
			folder = camel_store_get_folder_sync (
				CAMEL_STORE (imapx_store),
				real_junk_path, 0,
				cancellable, error);
		} else {
			g_set_error (
				error, CAMEL_FOLDER_ERROR,
				CAMEL_FOLDER_ERROR_INVALID_PATH,
				_("No destination folder specified"));
			folder = NULL;
		}

		if (folder != NULL) {
			destination = camel_imapx_folder_list_mailbox (
				CAMEL_IMAPX_FOLDER (folder),
				cancellable, error);
			g_object_unref (folder);
		}

		/* Avoid duplicating messages in the Junk folder. */
		if (destination == mailbox) {
			success = TRUE;
		} else if (destination != NULL) {
			success = imapx_conn_manager_copy_message_sync (
				conn_man, mailbox, destination,
				uids_to_copy, TRUE, FALSE, TRUE,
				cancellable, error);
			*out_need_to_expunge = success;
		} else {
			success = FALSE;
		}

		if (!success) {
			g_prefix_error (
				error, "%s: ",
				_("Unable to move junk messages"));
		}

		g_clear_object (&destination);
		g_clear_object (&imapx_store);
	}

	g_ptr_array_unref (uids_to_copy);
	g_free (real_junk_path);

	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_conn_manager_move_to_real_trash_sync (CamelIMAPXConnManager *conn_man,
					    CamelFolder *folder,
					    GCancellable *cancellable,
					    gboolean *out_need_to_expunge,
					    GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXMailbox *mailbox, *destination = NULL;
	CamelIMAPXSettings *settings;
	CamelIMAPXStore *imapx_store;
	GPtrArray *uids_to_copy;
	gchar *real_trash_path = NULL;
	guint32 folder_deleted_count = 0;
	gboolean success = TRUE;

	*out_need_to_expunge = FALSE;

	/* Caller already obtained the mailbox from the folder,
	 * so the folder should still have it readily available. */
	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	mailbox = camel_imapx_folder_ref_mailbox (imapx_folder);
	g_return_val_if_fail (mailbox != NULL, FALSE);

	uids_to_copy = g_ptr_array_new_with_free_func (
		(GDestroyNotify) camel_pstring_free);

	settings = CAMEL_IMAPX_SETTINGS (camel_service_ref_settings (CAMEL_SERVICE (camel_folder_get_parent_store (folder))));
	if (camel_imapx_settings_get_use_real_trash_path (settings)) {
		real_trash_path = camel_imapx_settings_dup_real_trash_path (settings);
		camel_imapx_folder_claim_move_to_real_trash_uids (CAMEL_IMAPX_FOLDER (folder), uids_to_copy);
	}
	g_object_unref (settings);

	if (!uids_to_copy->len) {
		g_ptr_array_unref (uids_to_copy);
		g_clear_object (&mailbox);
		g_free (real_trash_path);

		return TRUE;
	}

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);

	if (real_trash_path != NULL) {
		folder = camel_store_get_folder_sync (
			CAMEL_STORE (imapx_store),
			real_trash_path, 0,
			cancellable, error);
	} else {
		if (uids_to_copy->len > 0) {
			g_set_error (
				error, CAMEL_FOLDER_ERROR,
				CAMEL_FOLDER_ERROR_INVALID_PATH,
				_("No destination folder specified"));
		}

		folder = NULL;
	}

	if (folder != NULL) {
		destination = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder),
			cancellable, error);
		folder_deleted_count = camel_folder_summary_get_deleted_count (camel_folder_get_folder_summary (folder));
		g_object_unref (folder);
	}

	/* Avoid duplicating messages in the Trash folder. */
	if (destination == mailbox) {
		success = TRUE;
		/* Deleted messages in the real Trash folder will be permanently deleted immediately. */
		*out_need_to_expunge = folder_deleted_count > 0 || uids_to_copy->len > 0;
	} else if (destination != NULL) {
		if (uids_to_copy->len > 0) {
			success = imapx_conn_manager_copy_message_sync (
				conn_man, mailbox, destination,
				uids_to_copy, TRUE, TRUE, TRUE,
				cancellable, error);
			*out_need_to_expunge = success;
		}
	} else if (uids_to_copy->len > 0) {
		success = FALSE;
	}

	if (!success) {
		g_prefix_error (
			error, "%s: ",
			_("Unable to move deleted messages"));
	}

	g_ptr_array_unref (uids_to_copy);
	g_free (real_trash_path);

	g_clear_object (&imapx_store);
	g_clear_object (&destination);
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_conn_manager_move_to_inbox_sync (CamelIMAPXConnManager *conn_man,
				       CamelFolder *folder,
				       GCancellable *cancellable,
				       gboolean *out_need_to_expunge,
				       GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXMailbox *mailbox;
	GPtrArray *uids_to_copy;
	gboolean success = TRUE;

	*out_need_to_expunge = FALSE;

	/* Caller already obtained the mailbox from the folder,
	 * so the folder should still have it readily available. */
	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	mailbox = camel_imapx_folder_ref_mailbox (imapx_folder);
	g_return_val_if_fail (mailbox != NULL, FALSE);

	uids_to_copy = g_ptr_array_new_with_free_func ((GDestroyNotify) camel_pstring_free);

	camel_imapx_folder_claim_move_to_inbox_uids (CAMEL_IMAPX_FOLDER (folder), uids_to_copy);

	if (uids_to_copy->len > 0) {
		CamelIMAPXStore *imapx_store;
		CamelIMAPXMailbox *destination = NULL;

		imapx_store = camel_imapx_conn_manager_ref_store (conn_man);

		folder = camel_store_get_inbox_folder_sync (CAMEL_STORE (imapx_store), cancellable, error);

		if (folder != NULL) {
			destination = camel_imapx_folder_list_mailbox (CAMEL_IMAPX_FOLDER (folder), cancellable, error);
			g_object_unref (folder);
		}

		/* Avoid duplicating messages in the Inbox folder. */
		if (destination == mailbox) {
			success = TRUE;
		} else if (destination != NULL) {
			if (uids_to_copy->len > 0) {
				success = imapx_conn_manager_copy_message_sync (
					conn_man, mailbox, destination,
					uids_to_copy, TRUE, TRUE, TRUE,
					cancellable, error);
				*out_need_to_expunge = success;
			}
		} else if (uids_to_copy->len > 0) {
			success = FALSE;
		}

		if (!success) {
			g_prefix_error (
				error, "%s: ",
				_("Unable to move messages to Inbox"));
		}

		g_clear_object (&imapx_store);
		g_clear_object (&destination);
	}

	g_ptr_array_unref (uids_to_copy);
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_conn_manager_expunge_sync (CamelIMAPXConnManager *conn_man,
				 CamelIMAPXMailbox *mailbox,
				 gboolean skip_sync_changes,
				 GCancellable *cancellable,
				 GError **error);

static gboolean
imapx_conn_manager_sync_changes_run_sync (CamelIMAPXJob *job,
					  CamelIMAPXServer *server,
					  GCancellable *cancellable,
					  GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean can_influence_flags, success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	can_influence_flags = GPOINTER_TO_INT (camel_imapx_job_get_user_data (job)) == 1;

	success = camel_imapx_server_sync_changes_sync (server, mailbox, can_influence_flags, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

static gboolean
imapx_conn_manager_sync_changes_matches (CamelIMAPXJob *job,
					 CamelIMAPXJob *other_job)
{
	gboolean job_can_influence_flags, other_job_can_influence_flags;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);

	if (camel_imapx_job_get_kind (job) != CAMEL_IMAPX_JOB_SYNC_CHANGES ||
	    camel_imapx_job_get_kind (job) != camel_imapx_job_get_kind (other_job))
		return FALSE;

	job_can_influence_flags = GPOINTER_TO_INT (camel_imapx_job_get_user_data (job)) == 1;
	other_job_can_influence_flags = GPOINTER_TO_INT (camel_imapx_job_get_user_data (other_job)) == 1;

	return job_can_influence_flags == other_job_can_influence_flags;
}

gboolean
camel_imapx_conn_manager_sync_changes_sync (CamelIMAPXConnManager *conn_man,
					    CamelIMAPXMailbox *mailbox,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelIMAPXJob *job;
	CamelFolder *folder = NULL;
	gboolean need_to_expunge = FALSE, expunge = FALSE;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_SYNC_CHANGES, mailbox,
		imapx_conn_manager_sync_changes_run_sync,
		imapx_conn_manager_sync_changes_matches, NULL);

	/* Skip store of the \Deleted flag */
	camel_imapx_job_set_user_data (job, GINT_TO_POINTER (1), NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job,
		imapx_conn_manager_matches_sync_changes_or_refresh_info,
		cancellable, error);

	camel_imapx_job_unref (job);

	if (success) {
		folder = imapx_conn_manager_ref_folder_sync (conn_man, mailbox, cancellable, error);
		if (!folder)
			success = FALSE;
	}

	if (success) {
		success = imapx_conn_manager_move_to_real_junk_sync (
			conn_man, folder, cancellable,
			&need_to_expunge, error);
		expunge |= need_to_expunge;
	}

	if (success) {
		success = imapx_conn_manager_move_to_real_trash_sync (
			conn_man, folder, cancellable,
			&need_to_expunge, error);
		expunge |= need_to_expunge;
	}

	if (success) {
		success = imapx_conn_manager_move_to_inbox_sync (
			conn_man, folder, cancellable,
			&need_to_expunge, error);
		expunge |= need_to_expunge;
	}

	if (success && expunge) {
		job = camel_imapx_job_new (CAMEL_IMAPX_JOB_SYNC_CHANGES, mailbox,
			imapx_conn_manager_sync_changes_run_sync,
			imapx_conn_manager_sync_changes_matches, NULL);

		/* Store also the \Deleted flag */
		camel_imapx_job_set_user_data (job, GINT_TO_POINTER (0), NULL);

		success = camel_imapx_conn_manager_run_job_sync (conn_man, job,
			imapx_conn_manager_matches_sync_changes_or_refresh_info,
			cancellable, error);

		camel_imapx_job_unref (job);

		if (success)
			success = imapx_conn_manager_expunge_sync (conn_man, mailbox, TRUE, cancellable, error);
	}

	g_clear_object (&folder);

	return success;
}

static gboolean
imapx_conn_manager_expunge_run_sync (CamelIMAPXJob *job,
				     CamelIMAPXServer *server,
				     GCancellable *cancellable,
				     GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_expunge_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

static gboolean
imapx_conn_manager_expunge_sync (CamelIMAPXConnManager *conn_man,
				 CamelIMAPXMailbox *mailbox,
				 gboolean skip_sync_changes,
				 GCancellable *cancellable,
				 GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	if (!skip_sync_changes && !camel_imapx_conn_manager_sync_changes_sync (conn_man, mailbox, cancellable, error))
		return FALSE;

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_EXPUNGE, mailbox,
		imapx_conn_manager_expunge_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

gboolean
camel_imapx_conn_manager_expunge_sync (CamelIMAPXConnManager *conn_man,
				       CamelIMAPXMailbox *mailbox,
				       GCancellable *cancellable,
				       GError **error)
{
	return imapx_conn_manager_expunge_sync (conn_man, mailbox, FALSE, cancellable, error);
}

struct GetMessageJobData {
	CamelFolderSummary *summary;
	CamelDataCache *message_cache;
	gchar *message_uid;
};

static void
get_message_job_data_free (gpointer ptr)
{
	struct GetMessageJobData *job_data = ptr;

	if (job_data) {
		g_clear_object (&job_data->summary);
		g_clear_object (&job_data->message_cache);
		g_free (job_data->message_uid);
		g_free (job_data);
	}
}

static gboolean
imapx_conn_manager_get_message_run_sync (CamelIMAPXJob *job,
					 CamelIMAPXServer *server,
					 GCancellable *cancellable,
					 GError **error)
{
	struct GetMessageJobData *job_data;
	CamelIMAPXMailbox *mailbox;
	CamelStream *result;
	GError *local_error = NULL;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (job_data->summary), FALSE);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (job_data->message_cache), FALSE);
	g_return_val_if_fail (job_data->message_uid != NULL, FALSE);

	result = camel_imapx_server_get_message_sync (
		server, mailbox, job_data->summary, job_data->message_cache, job_data->message_uid,
		cancellable, &local_error);

	camel_imapx_job_set_result (job, result != NULL, result, local_error, result ? g_object_unref : NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return result != NULL;
}

static gboolean
imapx_conn_manager_get_message_matches (CamelIMAPXJob *job,
					CamelIMAPXJob *other_job)
{
	struct GetMessageJobData *job_data, *other_job_data;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);

	if ((camel_imapx_job_get_kind (job) != CAMEL_IMAPX_JOB_GET_MESSAGE &&
	    camel_imapx_job_get_kind (job) != CAMEL_IMAPX_JOB_SYNC_MESSAGE) ||
	    (camel_imapx_job_get_kind (other_job) != CAMEL_IMAPX_JOB_GET_MESSAGE &&
	    camel_imapx_job_get_kind (other_job) != CAMEL_IMAPX_JOB_SYNC_MESSAGE)) {
		return FALSE;
	}

	job_data = camel_imapx_job_get_user_data (job);
	other_job_data = camel_imapx_job_get_user_data (other_job);

	if (!job_data || !other_job_data)
		return FALSE;

	return job_data->summary == other_job_data->summary && g_strcmp0 (job_data->message_uid, other_job_data->message_uid) == 0;
}

static void
imapx_conn_manager_get_message_copy_result (CamelIMAPXJob *job,
					    gconstpointer set_result,
					    gpointer *out_result)
{
	if (!set_result || !*out_result)
		return;

	*out_result = g_object_ref ((gpointer) set_result);
}

CamelStream *
camel_imapx_conn_manager_get_message_sync (CamelIMAPXConnManager *conn_man,
					   CamelIMAPXMailbox *mailbox,
					   CamelFolderSummary *summary,
					   CamelDataCache *message_cache,
					   const gchar *message_uid,
					   GCancellable *cancellable,
					   GError **error)
{
	CamelIMAPXJob *job;
	struct GetMessageJobData *job_data;
	CamelStream *result;
	gpointer result_data = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), NULL);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_GET_MESSAGE, mailbox,
		imapx_conn_manager_get_message_run_sync,
		imapx_conn_manager_get_message_matches,
		imapx_conn_manager_get_message_copy_result);

	job_data = g_new0 (struct GetMessageJobData, 1);
	job_data->summary = g_object_ref (summary);
	job_data->message_cache = g_object_ref (message_cache);
	job_data->message_uid = g_strdup (message_uid);

	camel_imapx_job_set_user_data (job, job_data, get_message_job_data_free);

	if (camel_imapx_conn_manager_run_job_sync (conn_man, job, imapx_conn_manager_get_message_matches, cancellable, error) &&
	    camel_imapx_job_take_result_data (job, &result_data)) {
		result = result_data;
	} else {
		result = NULL;
	}

	camel_imapx_job_unref (job);

	return result;
}

struct CopyMessageJobData {
	CamelIMAPXMailbox *destination;
	GPtrArray *uids;
	gboolean delete_originals;
	gboolean remove_deleted_flags;
};

static void
copy_message_job_data_free (gpointer ptr)
{
	struct CopyMessageJobData *job_data = ptr;

	if (job_data) {
		g_clear_object (&job_data->destination);
		g_ptr_array_free (job_data->uids, TRUE);
		g_free (job_data);
	}
}

static gboolean
imapx_conn_manager_copy_message_run_sync (CamelIMAPXJob *job,
					  CamelIMAPXServer *server,
					  GCancellable *cancellable,
					  GError **error)
{
	struct CopyMessageJobData *job_data;
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (job_data->destination), FALSE);
	g_return_val_if_fail (job_data->uids != NULL, FALSE);

	success = camel_imapx_server_copy_message_sync (
		server, mailbox, job_data->destination, job_data->uids, job_data->delete_originals,
		job_data->remove_deleted_flags, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

static gboolean
imapx_conn_manager_copy_message_sync (CamelIMAPXConnManager *conn_man,
				      CamelIMAPXMailbox *mailbox,
				      CamelIMAPXMailbox *destination,
				      GPtrArray *uids,
				      gboolean delete_originals,
				      gboolean remove_deleted_flags,
				      gboolean skip_sync_changes,
				      GCancellable *cancellable,
				      GError **error)
{
	CamelIMAPXJob *job;
	struct CopyMessageJobData *job_data;
	gboolean success;
	gint ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	if (!skip_sync_changes && !camel_imapx_conn_manager_sync_changes_sync (conn_man, mailbox, cancellable, error))
		return FALSE;

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_COPY_MESSAGE, mailbox,
		imapx_conn_manager_copy_message_run_sync,
		imapx_conn_manager_nothing_matches,
		NULL);

	job_data = g_new0 (struct CopyMessageJobData, 1);
	job_data->destination = g_object_ref (destination);
	job_data->uids = g_ptr_array_new_full (uids->len, (GDestroyNotify) camel_pstring_free);
	job_data->delete_originals = delete_originals;
	job_data->remove_deleted_flags = remove_deleted_flags;

	for (ii = 0; ii < uids->len; ii++) {
		g_ptr_array_add (job_data->uids, (gpointer) camel_pstring_strdup (uids->pdata[ii]));
	}

	camel_imapx_job_set_user_data (job, job_data, copy_message_job_data_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	if (success) {
		CamelFolder *dest;

		dest = imapx_conn_manager_ref_folder_sync (conn_man, destination, cancellable, NULL);

		/* Update destination folder only if it's not frozen,
		 * to avoid updating for each "move" action on a single
		 * message while filtering. */
		if (dest && !camel_folder_is_frozen (dest)) {
			/* Ignore errors here */
			camel_imapx_conn_manager_refresh_info_sync (conn_man, destination, cancellable, NULL);
		}

		g_clear_object (&dest);
	}

	return success;
}

gboolean
camel_imapx_conn_manager_copy_message_sync (CamelIMAPXConnManager *conn_man,
					    CamelIMAPXMailbox *mailbox,
					    CamelIMAPXMailbox *destination,
					    GPtrArray *uids,
					    gboolean delete_originals,
					    gboolean remove_deleted_flags,
					    GCancellable *cancellable,
					    GError **error)
{
	return imapx_conn_manager_copy_message_sync (conn_man, mailbox, destination, uids,
		delete_originals, remove_deleted_flags, FALSE, cancellable, error);
}

struct AppendMessageJobData {
	CamelFolderSummary *summary;
	CamelDataCache *message_cache;
	CamelMimeMessage *message;
	const CamelMessageInfo *mi;
};

static void
append_message_job_data_free (gpointer ptr)
{
	struct AppendMessageJobData *job_data = ptr;

	if (job_data) {
		g_clear_object (&job_data->summary);
		g_clear_object (&job_data->message_cache);
		g_clear_object (&job_data->message);
		g_free (job_data);
	}
}

static gboolean
imapx_conn_manager_append_message_run_sync (CamelIMAPXJob *job,
					    CamelIMAPXServer *server,
					    GCancellable *cancellable,
					    GError **error)
{
	struct AppendMessageJobData *job_data;
	CamelIMAPXMailbox *mailbox;
	gchar *appended_uid = NULL;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (job_data->summary), FALSE);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (job_data->message_cache), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (job_data->message), FALSE);

	success = camel_imapx_server_append_message_sync (server, mailbox, job_data->summary, job_data->message_cache,
		job_data->message, job_data->mi, &appended_uid, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, appended_uid, local_error, appended_uid ? g_free : NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_append_message_sync (CamelIMAPXConnManager *conn_man,
					      CamelIMAPXMailbox *mailbox,
					      CamelFolderSummary *summary,
					      CamelDataCache *message_cache,
					      CamelMimeMessage *message,
					      const CamelMessageInfo *mi,
					      gchar **append_uid,
					      GCancellable *cancellable,
					      GError **error)
{
	CamelIMAPXJob *job;
	struct AppendMessageJobData *job_data;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_APPEND_MESSAGE, mailbox,
		imapx_conn_manager_append_message_run_sync,
		imapx_conn_manager_nothing_matches,
		NULL);

	job_data = g_new0 (struct AppendMessageJobData, 1);
	job_data->summary = g_object_ref (summary);
	job_data->message_cache = g_object_ref (message_cache);
	job_data->message = g_object_ref (message);
	job_data->mi = mi;

	camel_imapx_job_set_user_data (job, job_data, append_message_job_data_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);
	if (success) {
		gpointer result_data = NULL;

		success = camel_imapx_job_take_result_data (job, &result_data);
		if (success && append_uid)
			*append_uid = result_data;
		else
			g_free (result_data);
	}

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_sync_message_run_sync (CamelIMAPXJob *job,
					  CamelIMAPXServer *server,
					  GCancellable *cancellable,
					  GError **error)
{
	struct GetMessageJobData *job_data;
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (job_data->summary), FALSE);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (job_data->message_cache), FALSE);
	g_return_val_if_fail (job_data->message_uid != NULL, FALSE);

	success = camel_imapx_server_sync_message_sync (
		server, mailbox, job_data->summary, job_data->message_cache, job_data->message_uid,
		cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_sync_message_sync (CamelIMAPXConnManager *conn_man,
					    CamelIMAPXMailbox *mailbox,
					    CamelFolderSummary *summary,
					    CamelDataCache *message_cache,
					    const gchar *message_uid,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelIMAPXJob *job;
	struct GetMessageJobData *job_data;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_SYNC_MESSAGE, mailbox,
		imapx_conn_manager_sync_message_run_sync,
		imapx_conn_manager_get_message_matches,
		NULL);

	job_data = g_new0 (struct GetMessageJobData, 1);
	job_data->summary = g_object_ref (summary);
	job_data->message_cache = g_object_ref (message_cache);
	job_data->message_uid = g_strdup (message_uid);

	camel_imapx_job_set_user_data (job, job_data, get_message_job_data_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, imapx_conn_manager_get_message_matches, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_create_mailbox_run_sync (CamelIMAPXJob *job,
					    CamelIMAPXServer *server,
					    GCancellable *cancellable,
					    GError **error)
{
	const gchar *mailbox_name;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox_name = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (mailbox_name != NULL, FALSE);

	success = camel_imapx_server_create_mailbox_sync (server, mailbox_name, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_create_mailbox_sync (CamelIMAPXConnManager *conn_man,
					      const gchar *mailbox_name,
					      GCancellable *cancellable,
					      GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_CREATE_MAILBOX, NULL,
		imapx_conn_manager_create_mailbox_run_sync,
		imapx_conn_manager_nothing_matches,
		NULL);

	camel_imapx_job_set_user_data (job, g_strdup (mailbox_name), g_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_delete_mailbox_run_sync (CamelIMAPXJob *job,
					    CamelIMAPXServer *server,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_delete_mailbox_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_delete_mailbox_sync (CamelIMAPXConnManager *conn_man,
					      CamelIMAPXMailbox *mailbox,
					      GCancellable *cancellable,
					      GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_DELETE_MAILBOX, mailbox,
		imapx_conn_manager_delete_mailbox_run_sync,
		imapx_conn_manager_nothing_matches,
		NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_rename_mailbox_run_sync (CamelIMAPXJob *job,
					    CamelIMAPXServer *server,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelIMAPXMailbox *mailbox;
	const gchar *new_mailbox_name;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	new_mailbox_name = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (new_mailbox_name != NULL, FALSE);

	success = camel_imapx_server_rename_mailbox_sync (server, mailbox, new_mailbox_name, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_rename_mailbox_sync (CamelIMAPXConnManager *conn_man,
					      CamelIMAPXMailbox *mailbox,
					      const gchar *new_mailbox_name,
					      GCancellable *cancellable,
					      GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_RENAME_MAILBOX, mailbox,
		imapx_conn_manager_rename_mailbox_run_sync,
		imapx_conn_manager_nothing_matches,
		NULL);

	camel_imapx_job_set_user_data (job, g_strdup (new_mailbox_name), g_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_subscribe_mailbox_run_sync (CamelIMAPXJob *job,
					       CamelIMAPXServer *server,
					       GCancellable *cancellable,
					       GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_subscribe_mailbox_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_subscribe_mailbox_sync (CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_SUBSCRIBE_MAILBOX, mailbox,
		imapx_conn_manager_subscribe_mailbox_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_unsubscribe_mailbox_run_sync (CamelIMAPXJob *job,
						 CamelIMAPXServer *server,
						 GCancellable *cancellable,
						 GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_unsubscribe_mailbox_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_unsubscribe_mailbox_sync (CamelIMAPXConnManager *conn_man,
						   CamelIMAPXMailbox *mailbox,
						   GCancellable *cancellable,
						   GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_UNSUBSCRIBE_MAILBOX, mailbox,
		imapx_conn_manager_unsubscribe_mailbox_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gboolean
imapx_conn_manager_update_quota_info_run_sync (CamelIMAPXJob *job,
					       CamelIMAPXServer *server,
					       GCancellable *cancellable,
					       GError **error)
{
	CamelIMAPXMailbox *mailbox;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	success = camel_imapx_server_update_quota_info_sync (server, mailbox, cancellable, &local_error);

	camel_imapx_job_set_result (job, success, NULL, local_error, NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

gboolean
camel_imapx_conn_manager_update_quota_info_sync (CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error)
{
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), FALSE);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_UPDATE_QUOTA_INFO, mailbox,
		imapx_conn_manager_update_quota_info_run_sync, NULL, NULL);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);

	camel_imapx_job_unref (job);

	return success;
}

static gchar **
imapx_copy_strv (const gchar * const *words)
{
	gchar **copy;
	gint ii;

	if (!words || !*words)
		return NULL;

	copy = g_new0 (gchar *, g_strv_length ((gchar **) words) + 1);

	for (ii = 0; words[ii]; ii++) {
		copy[ii] = g_strdup (words[ii]);
	}

	copy[ii] = NULL;

	return copy;
}

static gboolean
imapx_equal_strv (const gchar * const *words1,
		  const gchar * const *words2)
{
	gint ii;

	if (words1 == words2)
		return TRUE;

	if (!words1 || !words2)
		return FALSE;

	for (ii = 0; words1[ii] && words2[ii]; ii++) {
		if (g_strcmp0 (words1[ii], words2[ii]) != 0)
			return FALSE;
	}

	return !words1[ii] && !words2[ii];
}

struct UidSearchJobData {
	gchar *criteria_prefix;
	gchar *search_key;
	gchar **words;
};

static void
uid_search_job_data_free (gpointer ptr)
{
	struct UidSearchJobData *job_data = ptr;

	if (ptr) {
		g_free (job_data->criteria_prefix);
		g_free (job_data->search_key);
		g_strfreev (job_data->words);
		g_free (job_data);
	}
}

static gboolean
imapx_conn_manager_uid_search_run_sync (CamelIMAPXJob *job,
					CamelIMAPXServer *server,
					GCancellable *cancellable,
					GError **error)
{
	struct UidSearchJobData *job_data;
	CamelIMAPXMailbox *mailbox;
	GPtrArray *uids = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);

	mailbox = camel_imapx_job_get_mailbox (job);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	job_data = camel_imapx_job_get_user_data (job);
	g_return_val_if_fail (job_data != NULL, FALSE);

	uids = camel_imapx_server_uid_search_sync (server, mailbox, job_data->criteria_prefix,
		job_data->search_key, (const gchar * const *) job_data->words, cancellable, &local_error);

	camel_imapx_job_set_result (job, uids != NULL, uids, local_error, uids ? (GDestroyNotify) g_ptr_array_free : NULL);

	if (local_error)
		g_propagate_error (error, local_error);

	return uids != NULL;
}

static gboolean
imapx_conn_manager_uid_search_matches (CamelIMAPXJob *job,
				       CamelIMAPXJob *other_job)
{
	struct UidSearchJobData *job_data, *other_job_data;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);

	if (camel_imapx_job_get_kind (job) != CAMEL_IMAPX_JOB_UID_SEARCH ||
	    camel_imapx_job_get_kind (job) != camel_imapx_job_get_kind (other_job))
		return FALSE;

	job_data = camel_imapx_job_get_user_data (job);
	other_job_data = camel_imapx_job_get_user_data (other_job);

	if (!job_data || !other_job_data)
		return job_data == other_job_data;

	return g_strcmp0 (job_data->criteria_prefix, other_job_data->criteria_prefix) == 0 &&
	       g_strcmp0 (job_data->search_key, other_job_data->search_key) == 0 &&
	       imapx_equal_strv ((const gchar * const  *) job_data->words, (const gchar * const  *) other_job_data->words);
}

GPtrArray *
camel_imapx_conn_manager_uid_search_sync (CamelIMAPXConnManager *conn_man,
					  CamelIMAPXMailbox *mailbox,
					  const gchar *criteria_prefix,
					  const gchar *search_key,
					  const gchar * const *words,
					  GCancellable *cancellable,
					  GError **error)
{
	struct UidSearchJobData *job_data;
	GPtrArray *uids = NULL;
	CamelIMAPXJob *job;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man), NULL);

	job_data = g_new0 (struct UidSearchJobData, 1);
	job_data->criteria_prefix = g_strdup (criteria_prefix);
	job_data->search_key = g_strdup (search_key);
	job_data->words = imapx_copy_strv (words);

	job = camel_imapx_job_new (CAMEL_IMAPX_JOB_UID_SEARCH, mailbox,
		imapx_conn_manager_uid_search_run_sync,
		imapx_conn_manager_uid_search_matches,
		NULL);

	camel_imapx_job_set_user_data (job, job_data, uid_search_job_data_free);

	success = camel_imapx_conn_manager_run_job_sync (conn_man, job, NULL, cancellable, error);
	if (success) {
		gpointer result_data = NULL;

		success = camel_imapx_job_take_result_data (job, &result_data);
		if (success)
			uids = result_data;
	}

	camel_imapx_job_unref (job);

	return uids;
}

/* for debugging purposes only */
void
camel_imapx_conn_manager_dump_queue_status (CamelIMAPXConnManager *conn_man)
{
	GList *llink;
	GSList *slink;

	g_return_if_fail (CAMEL_IS_IMAPX_CONN_MANAGER (conn_man));

	CON_READ_LOCK (conn_man);

	printf ("%s: opened connections:%d\n", G_STRFUNC, g_list_length (conn_man->priv->connections));

	for (llink = conn_man->priv->connections; llink != NULL; llink = g_list_next (llink)) {
		ConnectionInfo *cinfo = llink->data;
		CamelIMAPXCommand *cmd = NULL;

		if (cinfo)
			cmd = cinfo->is ? camel_imapx_server_ref_current_command (cinfo->is) : NULL;

		printf ("   connection:%p server:[%c] %p busy:%d command:%s\n", cinfo,
			cinfo && cinfo->is ? camel_imapx_server_get_tagprefix (cinfo->is) : '?',
			cinfo ? cinfo->is : NULL, cinfo ? cinfo->busy : FALSE,
			cmd ? camel_imapx_job_get_kind_name (cmd->job_kind) : "[null]");

		if (cmd)
			camel_imapx_command_unref (cmd);
	}

	CON_READ_UNLOCK (conn_man);

	JOB_QUEUE_LOCK (conn_man);

	printf ("Queued jobs:%d\n", g_slist_length (conn_man->priv->job_queue));
	for (slink = conn_man->priv->job_queue; slink; slink = g_slist_next (slink)) {
		CamelIMAPXJob *job = slink->data;

		printf ("   job:%p kind:%s mailbox:%s\n", job,
			job ? camel_imapx_job_get_kind_name (camel_imapx_job_get_kind (job)) : "[null]",
			job && camel_imapx_job_get_mailbox (job) ? camel_imapx_mailbox_get_name (camel_imapx_job_get_mailbox (job)) : "[null]");
	}

	JOB_QUEUE_UNLOCK (conn_man);
}
