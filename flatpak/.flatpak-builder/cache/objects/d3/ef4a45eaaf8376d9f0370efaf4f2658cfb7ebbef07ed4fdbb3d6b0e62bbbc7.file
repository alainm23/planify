/*
 * file-transfer-channel.h - high level API for File Transfer channels
 *
 * Copyright (C) 2010-2011 Morten Mjelva <morten.mjelva@gmail.com>
 * Copyright (C) 2010-2011 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_FILE_TRANSFER_CHANNEL_H__
#define __TP_FILE_TRANSFER_CHANNEL_H__

#include <telepathy-glib/channel.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS


#define TP_TYPE_FILE_TRANSFER_CHANNEL (tp_file_transfer_channel_get_type ())
#define TP_FILE_TRANSFER_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_FILE_TRANSFER_CHANNEL, TpFileTransferChannel))
#define TP_FILE_TRANSFER_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_FILE_TRANSFER_CHANNEL, TpFileTransferChannelClass))
#define TP_IS_FILE_TRANSFER_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_FILE_TRANSFER_CHANNEL))
#define TP_IS_FILE_TRANSFER_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_FILE_TRANSFER_CHANNEL))
#define TP_FILE_TRANSFER_CHANNEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_FILE_TRANSFER_CHANNEL, TpFileTransferChannelClass))

typedef struct _TpFileTransferChannel TpFileTransferChannel;
typedef struct _TpFileTransferChannelClass TpFileTransferChannelClass;
typedef struct _TpFileTransferChannelPrivate TpFileTransferChannelPrivate;

struct _TpFileTransferChannel
{
  /*<private>*/
  TpChannel parent;
  TpFileTransferChannelPrivate *priv;
};

struct _TpFileTransferChannelClass
{
  /*<private>*/
  TpChannelClass parent_class;
  GCallback _padding[8];
};

#define TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE \
  tp_file_transfer_channel_get_feature_quark_core ()
_TP_AVAILABLE_IN_0_16
GQuark tp_file_transfer_channel_get_feature_quark_core (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_16
GType tp_file_transfer_channel_get_type (void);

/* Methods */

_TP_AVAILABLE_IN_0_16
_TP_DEPRECATED_IN_0_20_FOR(tp_simple_client_factory_ensure_channel)
TpFileTransferChannel * tp_file_transfer_channel_new (TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_file_transfer_channel_accept_file_async (TpFileTransferChannel *self,
    GFile *file,
    guint64 offset,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_18
gboolean tp_file_transfer_channel_accept_file_finish (
    TpFileTransferChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_file_transfer_channel_provide_file_async (TpFileTransferChannel *self,
    GFile *file,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_18
gboolean tp_file_transfer_channel_provide_file_finish (
    TpFileTransferChannel *self,
    GAsyncResult *result,
    GError **error);

/* Property accessors */

_TP_AVAILABLE_IN_0_16
const char * tp_file_transfer_channel_get_mime_type (
    TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_16
GDateTime * tp_file_transfer_channel_get_date (TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_18
TpFileTransferState tp_file_transfer_channel_get_state (
    TpFileTransferChannel *self,
    TpFileTransferStateChangeReason *reason);

_TP_AVAILABLE_IN_0_16
const gchar * tp_file_transfer_channel_get_description (
    TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_16
const gchar * tp_file_transfer_channel_get_filename (
    TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_16
guint64 tp_file_transfer_channel_get_size (TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_16
guint64 tp_file_transfer_channel_get_transferred_bytes (
    TpFileTransferChannel *self);

/* Metadata */

_TP_AVAILABLE_IN_0_18
const gchar * tp_file_transfer_channel_get_service_name (
    TpFileTransferChannel *self);

_TP_AVAILABLE_IN_0_18
const GHashTable * tp_file_transfer_channel_get_metadata (
    TpFileTransferChannel *self);

G_END_DECLS

#endif
