/*
 * object used to request a channel from a TpAccount
 *
 * Copyright © 2010 Collabora Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_ACCOUNT_CHANNEL_REQUEST_H__
#define __TP_ACCOUNT_CHANNEL_REQUEST_H__

#include <gio/gio.h>
#include <glib-object.h>
#include <glib.h>

#include <telepathy-glib/account.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/channel-request.h>
#include <telepathy-glib/client-channel-factory.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/handle-channels-context.h>

G_BEGIN_DECLS

typedef struct _TpAccountChannelRequest TpAccountChannelRequest;
typedef struct _TpAccountChannelRequestClass \
          TpAccountChannelRequestClass;
typedef struct _TpAccountChannelRequestPrivate \
          TpAccountChannelRequestPrivate;

GType tp_account_channel_request_get_type (void);

#define TP_TYPE_ACCOUNT_CHANNEL_REQUEST \
  (tp_account_channel_request_get_type ())
#define TP_ACCOUNT_CHANNEL_REQUEST(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_ACCOUNT_CHANNEL_REQUEST, \
                               TpAccountChannelRequest))
#define TP_ACCOUNT_CHANNEL_REQUEST_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_ACCOUNT_CHANNEL_REQUEST, \
                            TpAccountChannelRequestClass))
#define TP_IS_ACCOUNT_CHANNEL_REQUEST(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_ACCOUNT_CHANNEL_REQUEST))
#define TP_IS_ACCOUNT_CHANNEL_REQUEST_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_ACCOUNT_CHANNEL_REQUEST))
#define TP_ACCOUNT_CHANNEL_REQUEST_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_ACCOUNT_CHANNEL_REQUEST, \
                              TpAccountChannelRequestClass))

TpAccountChannelRequest * tp_account_channel_request_new (
    TpAccount *account,
    GHashTable *request,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;
_TP_AVAILABLE_IN_0_20
TpAccountChannelRequest * tp_account_channel_request_new_vardict (
    TpAccount *account,
    GVariant *request,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

TpAccount * tp_account_channel_request_get_account (
    TpAccountChannelRequest *self);

GHashTable * tp_account_channel_request_get_request (
    TpAccountChannelRequest *self);
_TP_AVAILABLE_IN_0_20
GVariant *tp_account_channel_request_dup_request (
    TpAccountChannelRequest *self);

gint64 tp_account_channel_request_get_user_action_time (
    TpAccountChannelRequest *self);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_16
void tp_account_channel_request_set_channel_factory (
    TpAccountChannelRequest *self,
    TpClientChannelFactory *factory);
#endif

TpChannelRequest * tp_account_channel_request_get_channel_request (
    TpAccountChannelRequest *self);

_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_hint (TpAccountChannelRequest *self,
    const gchar *key,
    GVariant *value);

void tp_account_channel_request_set_hints (TpAccountChannelRequest *self,
    GHashTable *hints);

_TP_AVAILABLE_IN_0_16
void tp_account_channel_request_set_delegate_to_preferred_handler (
    TpAccountChannelRequest *self,
    gboolean delegate);

/* Text */

_TP_AVAILABLE_IN_0_20
TpAccountChannelRequest *tp_account_channel_request_new_text (
    TpAccount *account,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_24
void tp_account_channel_request_set_sms_channel (TpAccountChannelRequest *self,
    gboolean is_sms_channel);

/* Calls */

_TP_AVAILABLE_IN_0_20
TpAccountChannelRequest *tp_account_channel_request_new_audio_call (
    TpAccount *account,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;
_TP_AVAILABLE_IN_0_20
TpAccountChannelRequest *tp_account_channel_request_new_audio_video_call (
    TpAccount *account,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

/* File transfer */

_TP_AVAILABLE_IN_0_20
TpAccountChannelRequest *tp_account_channel_request_new_file_transfer (
    TpAccount *account,
    const gchar *filename,
    const gchar *mime_type,
    guint64 size,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_file_transfer_description (
    TpAccountChannelRequest *self,
    const gchar *description);
_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_file_transfer_uri (
    TpAccountChannelRequest *self,
    const gchar *uri);
_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_file_transfer_timestamp (
    TpAccountChannelRequest *self,
    guint64 timestamp);
_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_file_transfer_initial_offset (
    TpAccountChannelRequest *self,
    guint64 offset);

_TP_AVAILABLE_IN_0_24
void tp_account_channel_request_set_file_transfer_hash (
    TpAccountChannelRequest *self,
    TpFileHashType hash_type,
    const gchar *hash);

/* Tube */

_TP_AVAILABLE_IN_0_24
TpAccountChannelRequest *tp_account_channel_request_new_stream_tube (
    TpAccount *account,
    const gchar *service,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_24
TpAccountChannelRequest *tp_account_channel_request_new_dbus_tube (
    TpAccount *account,
    const gchar *service_name,
    gint64 user_action_time) G_GNUC_WARN_UNUSED_RESULT;

/* Conference */

_TP_AVAILABLE_IN_0_24
void tp_account_channel_request_set_conference_initial_channels (
    TpAccountChannelRequest *self,
    const gchar * const * channels);

_TP_AVAILABLE_IN_0_24
void tp_account_channel_request_set_initial_invitee_ids (
    TpAccountChannelRequest *self,
    const gchar * const * ids);

_TP_AVAILABLE_IN_0_24
void tp_account_channel_request_set_initial_invitees (
    TpAccountChannelRequest *self,
    GPtrArray *contacts);

/* Channel target (shared between all channel types) */

_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_target_contact (
    TpAccountChannelRequest *self,
    TpContact *contact);
_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_target_id (TpAccountChannelRequest *self,
    TpHandleType handle_type,
    const gchar *identifier);

/* Generic low-level */

_TP_AVAILABLE_IN_0_20
void tp_account_channel_request_set_request_property (
    TpAccountChannelRequest *self,
    const gchar *name,
    GVariant *value);

/* Request and handle API */

void tp_account_channel_request_create_and_handle_channel_async (
    TpAccountChannelRequest *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpChannel * tp_account_channel_request_create_and_handle_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    TpHandleChannelsContext **context,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

void tp_account_channel_request_ensure_and_handle_channel_async (
    TpAccountChannelRequest *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpChannel * tp_account_channel_request_ensure_and_handle_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    TpHandleChannelsContext **context,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

typedef void (*TpAccountChannelRequestDelegatedChannelCb) (
    TpAccountChannelRequest *request,
    TpChannel *channel,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
void tp_account_channel_request_set_delegated_channel_callback (
    TpAccountChannelRequest *self,
    TpAccountChannelRequestDelegatedChannelCb callback,
    gpointer user_data,
    GDestroyNotify destroy);

/* Request and forget API */

void tp_account_channel_request_create_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_account_channel_request_create_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error);

void tp_account_channel_request_ensure_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_account_channel_request_ensure_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error);

/* Request and observe API */

void tp_account_channel_request_create_and_observe_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpChannel * tp_account_channel_request_create_and_observe_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

void tp_account_channel_request_ensure_and_observe_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpChannel * tp_account_channel_request_ensure_and_observe_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

G_END_DECLS

#endif
