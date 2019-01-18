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

#ifndef _CAMEL_IMAPX_CONN_MANAGER_H
#define _CAMEL_IMAPX_CONN_MANAGER_H

#include "camel-imapx-job.h"
#include "camel-imapx-mailbox.h"
#include "camel-imapx-server.h"

G_BEGIN_DECLS

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_CONN_MANAGER \
	(camel_imapx_conn_manager_get_type ())
#define CAMEL_IMAPX_CONN_MANAGER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_CONN_MANAGER, CamelIMAPXConnManager))
#define CAMEL_IMAPX_CONN_MANAGER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_CONN_MANAGER, CamelIMAPXConnManagerClass))
#define CAMEL_IS_IMAPX_CONN_MANAGER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_CONN_MANAGER))
#define CAMEL_IS_IMAPX_CONN_MANAGER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_CONN_MANAGER))
#define CAMEL_IMAPX_CONN_MANAGER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_CONN_MANAGER, CamelIMAPXConnManagerClass))

struct _CamelIMAPXStore;

typedef struct _CamelIMAPXConnManager CamelIMAPXConnManager;
typedef struct _CamelIMAPXConnManagerClass CamelIMAPXConnManagerClass;
typedef struct _CamelIMAPXConnManagerPrivate CamelIMAPXConnManagerPrivate;

struct _CamelIMAPXConnManager {
	GObject parent;

	CamelIMAPXConnManagerPrivate *priv;
};

struct _CamelIMAPXConnManagerClass {
	GObjectClass parent_class;

	/* Signals */
	void	(* connection_created) (CamelIMAPXConnManager *conn_man,
					CamelIMAPXServer *server);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_conn_manager_get_type (void);
CamelIMAPXConnManager *
		camel_imapx_conn_manager_new	(CamelStore *store);
struct _CamelIMAPXStore *
		camel_imapx_conn_manager_ref_store
						(CamelIMAPXConnManager *conn_man);
gboolean	camel_imapx_conn_manager_connect_sync
						(CamelIMAPXConnManager *conn_man,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_disconnect_sync
						(CamelIMAPXConnManager *conn_man,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_run_job_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXJob *job,
						 CamelIMAPXJobMatchesFunc finish_before_job,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_noop_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_list_sync
						(CamelIMAPXConnManager *conn_man,
						 const gchar *pattern,
						 CamelStoreGetFolderInfoFlags flags,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_refresh_info_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_sync_changes_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_expunge_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
CamelStream *	camel_imapx_conn_manager_get_message_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 const gchar *message_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_copy_message_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 CamelIMAPXMailbox *destination,
						 GPtrArray *uids,
						 gboolean delete_originals,
						 gboolean remove_deleted_flags,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_append_message_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 CamelMimeMessage *message,
						 const CamelMessageInfo *mi,
						 gchar **append_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_sync_message_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 const gchar *message_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_create_mailbox_sync
						(CamelIMAPXConnManager *conn_man,
						 const gchar *mailbox_name,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_delete_mailbox_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_rename_mailbox_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 const gchar *new_mailbox_name,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_subscribe_mailbox_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_unsubscribe_mailbox_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_conn_manager_update_quota_info_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
GPtrArray *	camel_imapx_conn_manager_uid_search_sync
						(CamelIMAPXConnManager *conn_man,
						 CamelIMAPXMailbox *mailbox,
						 const gchar *criteria_prefix,
						 const gchar *search_key,
						 const gchar * const *words,
						 GCancellable *cancellable,
						 GError **error);

/* for debugging purposes only */
void		camel_imapx_conn_manager_dump_queue_status
						(CamelIMAPXConnManager *conn_man);
G_END_DECLS

#endif /* _CAMEL_IMAPX_SERVER_H */
