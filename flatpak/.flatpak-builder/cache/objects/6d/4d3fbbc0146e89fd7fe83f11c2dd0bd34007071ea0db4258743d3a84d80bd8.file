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
 */

#ifndef CAMEL_IMAPX_SERVER_H
#define CAMEL_IMAPX_SERVER_H

#include <camel/camel.h>

#include "camel-imapx-command.h"
#include "camel-imapx-mailbox.h"
#include "camel-imapx-namespace-response.h"
#include "camel-imapx-store-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_SERVER \
	(camel_imapx_server_get_type ())
#define CAMEL_IMAPX_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_SERVER, CamelIMAPXServer))
#define CAMEL_IMAPX_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_SERVER, CamelIMAPXServerClass))
#define CAMEL_IS_IMAPX_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_SERVER))
#define CAMEL_IS_IMAPX_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_SERVER))
#define CAMEL_IMAPX_SERVER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_SERVER, CamelIMAPXServerClass))

#define CAMEL_IMAPX_SERVER_ERROR (camel_imapx_server_error_quark ())

G_BEGIN_DECLS

typedef enum {
	CAMEL_IMAPX_SERVER_ERROR_CONCURRENT_CONNECT_FAILED,
	CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT
} CamelIMAPXServerError;

GQuark		camel_imapx_server_error_quark		(void) G_GNUC_CONST;

/* Avoid a circular reference. */
struct _CamelIMAPXStore;
struct _CamelIMAPXSettings;
struct _CamelIMAPXJob;

typedef struct _CamelIMAPXServer CamelIMAPXServer;
typedef struct _CamelIMAPXServerClass CamelIMAPXServerClass;
typedef struct _CamelIMAPXServerPrivate CamelIMAPXServerPrivate;

/* untagged response handling */
typedef gboolean (* CamelIMAPXUntaggedRespHandler) (CamelIMAPXServer *server,
						    GInputStream *input_stream,
						    GCancellable *cancellable,
						    GError **error);

/**
 * CamelIMAPXUntaggedRespHandlerDesc:
 * @untagged_response: a string representation of the IMAP
 *                     untagged response code. Must be
 *                     all-uppercase with underscores allowed
 *                     (see RFC 3501)
 * @handler: an untagged response handler function for #CamelIMAPXServer
 * @next_response: the IMAP untagged code to call a registered
 *                 handler for directly after successfully
 *                 running @handler. If not NULL, @skip_stream_when_done
 *                 for the current handler has no effect
 * @skip_stream_when_done: whether or not to skip the current IMAP
 *                         untagged response in the #GInputStream.
 *                         Set to TRUE if your handler does not eat
 *                         the stream up to the next response token
 *
 * IMAP untagged response handler function descriptor. Use in conjunction
 * with camel_imapx_server_register_untagged_handler() to register a new
 * handler function for a given untagged response code
 *
 * Since: 3.6
 */
typedef struct _CamelIMAPXUntaggedRespHandlerDesc CamelIMAPXUntaggedRespHandlerDesc;
struct _CamelIMAPXUntaggedRespHandlerDesc {
	const gchar *untagged_response;
	const CamelIMAPXUntaggedRespHandler handler;
	const gchar *next_response;
	gboolean skip_stream_when_done;
};

struct _CamelIMAPXServer {
	GObject parent;
	CamelIMAPXServerPrivate *priv;
};

struct _CamelIMAPXServerClass {
	GObjectClass parent_class;

	/* Signals */
	void		(*refresh_mailbox)	(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_server_get_type	(void);
CamelIMAPXServer *
		camel_imapx_server_new		(struct _CamelIMAPXStore *store);
struct _CamelIMAPXStore *
		camel_imapx_server_ref_store	(CamelIMAPXServer *is);
struct _CamelIMAPXSettings *
		camel_imapx_server_ref_settings	(CamelIMAPXServer *is);
GInputStream *	camel_imapx_server_ref_input_stream
						(CamelIMAPXServer *is);
GOutputStream *	camel_imapx_server_ref_output_stream
						(CamelIMAPXServer *is);
CamelIMAPXMailbox *
		camel_imapx_server_ref_selected	(CamelIMAPXServer *is);
CamelIMAPXMailbox *
		camel_imapx_server_ref_pending_or_selected
						(CamelIMAPXServer *is);
const struct _capability_info *
		camel_imapx_server_get_capability_info
						(CamelIMAPXServer *is);
gboolean	camel_imapx_server_have_capability
						(CamelIMAPXServer *is,
						 guint32 capability);
gboolean	camel_imapx_server_lack_capability
						(CamelIMAPXServer *is,
						 guint32 capability);
gchar		camel_imapx_server_get_tagprefix
						(CamelIMAPXServer *is);
void		camel_imapx_server_set_tagprefix
						(CamelIMAPXServer *is,
						 gchar tagprefix);
gboolean	camel_imapx_server_get_utf8_accept
						(CamelIMAPXServer *is);
CamelIMAPXCommand *
		camel_imapx_server_ref_current_command
						(CamelIMAPXServer *is);
gboolean	camel_imapx_server_connect_sync	(CamelIMAPXServer *is,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_disconnect_sync
						(CamelIMAPXServer *is,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_is_connected	(CamelIMAPXServer *imapx_server);
CamelAuthenticationResult
		camel_imapx_server_authenticate_sync
						(CamelIMAPXServer *is,
						 const gchar *mechanism,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_query_auth_types_sync
						(CamelIMAPXServer *is,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_mailbox_selected
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox);
gboolean	camel_imapx_server_ensure_selected_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_process_command_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXCommand *ic,
						 const gchar *error_prefix,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_list_sync	(CamelIMAPXServer *is,
						 const gchar *pattern,
						 CamelStoreGetFolderInfoFlags flags,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_refresh_info_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_sync_changes_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 gboolean can_influence_flags,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_expunge_sync	(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_noop_sync	(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
CamelStream *	camel_imapx_server_get_message_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 const gchar *message_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_copy_message_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 CamelIMAPXMailbox *destination,
						 GPtrArray *uids,
						 gboolean delete_originals,
						 gboolean remove_deleted_flags,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_append_message_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 CamelMimeMessage *message,
						 const CamelMessageInfo *mi,
						 gchar **append_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_sync_message_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 CamelFolderSummary *summary,
						 CamelDataCache *message_cache,
						 const gchar *message_uid,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_create_mailbox_sync
						(CamelIMAPXServer *is,
						 const gchar *mailbox_name,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_delete_mailbox_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_rename_mailbox_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 const gchar *new_mailbox_name,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_subscribe_mailbox_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_unsubscribe_mailbox_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_update_quota_info_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
GPtrArray *	camel_imapx_server_uid_search_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 const gchar *criteria_prefix,
						 const gchar *search_key,
						 const gchar * const *words,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_can_use_idle	(CamelIMAPXServer *is);
gboolean	camel_imapx_server_is_in_idle	(CamelIMAPXServer *is);
CamelIMAPXMailbox *
		camel_imapx_server_ref_idle_mailbox
						(CamelIMAPXServer *is);
gboolean	camel_imapx_server_schedule_idle_sync
						(CamelIMAPXServer *is,
						 CamelIMAPXMailbox *mailbox,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_imapx_server_stop_idle_sync
						(CamelIMAPXServer *is,
						 GCancellable *cancellable,
						 GError **error);

const CamelIMAPXUntaggedRespHandlerDesc *
		camel_imapx_server_register_untagged_handler
						(CamelIMAPXServer *is,
						 const gchar *untagged_response,
						 const CamelIMAPXUntaggedRespHandlerDesc *desc);
G_END_DECLS

#endif /* CAMEL_IMAPX_SERVER_H */
