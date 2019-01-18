/*
 * file-transfer-channel.h - high level API for Chan.I.FileTransfer
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

/**
 * SECTION:file-transfer-channel
 * @title: TpFileTransferChannel
 * @short_description: proxy object for a file transfer channel
 *
 * #TpFileTransferChannel is a sub-class of #TpChannel providing convenient
 * API to send and receive files.
 *
 * The channel properties are available in
 * #TpFileTransferChannel:date, #TpFileTransferChannel:description,
 * #TpFileTransferChannel:filename,
 * #TpFileTransferChannel:initial-offset,
 * #TpFileTransferChannel:mime-type, #TpFileTransferChannel:size,
 * #TpFileTransferChannel:state, and
 * #TpFileTransferChannel:transferred-bytes GObject properties, with
 * accessor functions too.
 *
 * To send a file to a contact, one should create a File Transfer
 * channel with the appropriate D-Bus properties set by specifying
 * their values in the channel creation method call. The file transfer
 * invitation will be sent to the remote contact when the channel is
 * created. For example:
 *
 * |[
 * GHashTable *request = tp_asv_new (
 *     TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER,
 *     TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
 *     TP_PROP_CHANNEL_TARGET_ID, G_TYPE_STRING, "foo@bar.com",
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_TYPE, G_TYPE_STRING, "text/plain",
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DATE, G_TYPE_INT64, 1320925992,
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DESCRIPTION, G_TYPE_STRING, "",
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_FILENAME, G_TYPE_STRING, "test.pdf",
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_INITIAL_OFFSET, G_TYPE_UINT64, 0,
 *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_SIZE, G_TYPE_UINT64, 165710,
 *     NULL);
 *
 * TpAccountChannelRequest *channel_request = tp_account_channel_request_new (
 *     account, request,
 *     TP_USER_ACTION_TIME_CURRENT_TIME);
 *
 * tp_account_channel_request_create_and_handle_channel_async (channel_request, NULL,
 *     create_and_handle_cb, NULL);
 *
 * g_hash_table_unref (request);
 * ]|
 *
 * Once a #TpFileTransferChannel is created as a proxy to the channel
 * on D-Bus. The "notify::state" GObject signals on the resulting
 * channel should be monitored; when the channel moves to state
 * %TP_FILE_TRANSFER_STATE_ACCEPTED,
 * tp_file_transfer_channel_provide_file_async() should be called.
 *
 * When an incoming File Transfer channel appears, one should call
 * tp_file_transfer_channel_accept_file_async().
 *
 * To cancel or reject a pending or ongoing file transfer, one should
 * close the channel using tp_channel_close_async().
 */

/**
 * TpFileTransferChannel:
 *
 * Data structure representing a #TpFileTransferChannel.
 *
 * Since: 0.15.5
 */

/**
 * TpFileTransferChannelClass:
 *
 * The class of a #TpFileTransferChannel.
 *
 * Since: 0.15.5
 */

#include "config.h"

#include "telepathy-glib/file-transfer-channel.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gnio-util.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/proxy-internal.h>
#include <telepathy-glib/util-internal.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CHANNEL
#include "telepathy-glib/automatic-client-factory-internal.h"
#include "telepathy-glib/channel-internal.h"
#include "telepathy-glib/debug-internal.h"

#include <stdio.h>
#include <glib.h>
#include <glib/gstdio.h>

#ifdef HAVE_GIO_UNIX
#include <gio/gunixsocketaddress.h>
#include <gio/gunixconnection.h>
#endif /* HAVE_GIO_UNIX */

G_DEFINE_TYPE (TpFileTransferChannel, tp_file_transfer_channel, TP_TYPE_CHANNEL)

struct _TpFileTransferChannelPrivate
{
    /* Exposed properties */
    const gchar *mime_type;
    GDateTime *date;
    const gchar *description;
    const gchar *filename;
    guint64 size;
    guint64 transferred_bytes;
    TpFileTransferState state;
    TpFileTransferStateChangeReason state_reason;
    GFile *file;

    /* Hidden properties */
    /* borrowed from the immutable properties GHashTable */
    GHashTable *available_socket_types;
    const gchar *content_hash;
    TpFileHashType content_hash_type;
    goffset initial_offset;
    /* Metadata */
    const gchar *service_name;
    GHashTable *metadata; /* const gchar* => const gchar* const* */

    /* Streams and sockets for sending and receiving the actual file */
    GSocket *client_socket;
    GIOStream *stream;
    GInputStream *in_stream;
    GOutputStream *out_stream;
    GSocketAddress *remote_address;
    /* The value passed to Accept; this shouldn't be stored in
     * initial_offset as they can easily be different. */
    guint requested_offset;

    TpSocketAddressType socket_type;
    TpSocketAccessControl access_control;
    GValue *access_control_param;

    GSimpleAsyncResult *result;
    GCancellable *cancellable;
};

enum /* properties */
{
  PROP_MIME_TYPE = 1,
  PROP_DATE,
  PROP_DESCRIPTION,
  PROP_FILENAME,
  PROP_SIZE,
  PROP_STATE,
  PROP_TRANSFERRED_BYTES,
  PROP_FILE,
  PROP_INITIAL_OFFSET,
  PROP_SERVICE_NAME,
  PROP_METADATA,
  N_PROPS
};

static void
operation_failed (TpFileTransferChannel *self,
    GError *error)
{
  g_assert (self->priv->result != NULL);
  g_simple_async_result_take_error (self->priv->result, error);
  g_simple_async_result_complete_in_idle (self->priv->result);
  tp_clear_object (&self->priv->result);
}

static void
stream_close_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  GIOStream *stream = G_IO_STREAM (source);
  TpFileTransferChannel *self = user_data;
  GError *error = NULL;

  if (!g_io_stream_close_finish (stream, result, &error))
    {
      DEBUG ("Failed to close stream: %s\n", error->message);
      g_clear_error (&error);
    }

  /* Now that this is closed in both ways, let's just remove it. */
  g_clear_object (&self->priv->stream);
  g_object_unref (self);
}

static void
splice_stream_ready_cb (GObject *output,
    GAsyncResult *result,
    gpointer user_data)
{
  TpFileTransferChannel *self = user_data;
  GError *error = NULL;

  g_output_stream_splice_finish (G_OUTPUT_STREAM (output), result,
      &error);

  if (error != NULL && !g_cancellable_is_cancelled (self->priv->cancellable))
    DEBUG ("splice operation failed: %s", error->message);
  g_clear_error (&error);

  g_io_stream_close_async (self->priv->stream, G_PRIORITY_DEFAULT,
      NULL, stream_close_cb, g_object_ref (self));

  g_object_unref (self);
}

static void
client_socket_connected (TpFileTransferChannel *self)
{
  GSocketConnection *conn;
  GError *error = NULL;

  conn = g_socket_connection_factory_create_connection (
      self->priv->client_socket);
  if (conn == NULL)
    {
      DEBUG ("Failed to create client connection");
      return;
    }

  DEBUG ("File transfer socket connected");

#ifdef HAVE_GIO_UNIX
  if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_CREDENTIALS)
    {
      guchar byte;

      byte = g_value_get_uchar (self->priv->access_control_param);

      /* FIXME: we should an async version of this API (bgo #629503) */
      if (!tp_unix_connection_send_credentials_with_byte (
              conn, byte, NULL, &error))
        {
          DEBUG ("Failed to send credentials: %s", error->message);
          g_object_unref (conn);
          g_clear_error (&error);
          return;
        }
    }
#endif

  self->priv->stream = G_IO_STREAM (conn);

  if (tp_channel_get_requested (TP_CHANNEL (self)))
    {
      GOutputStream *stream;

      stream = g_io_stream_get_output_stream (G_IO_STREAM (conn));

      g_output_stream_splice_async (stream, self->priv->in_stream,
          G_OUTPUT_STREAM_SPLICE_CLOSE_SOURCE |
          G_OUTPUT_STREAM_SPLICE_CLOSE_TARGET,
          G_PRIORITY_DEFAULT, self->priv->cancellable,
          splice_stream_ready_cb, g_object_ref (self));
    }
  else
    {
      GInputStream *stream;

      stream = g_io_stream_get_input_stream (G_IO_STREAM (conn));

      g_output_stream_splice_async (self->priv->out_stream, stream,
          G_OUTPUT_STREAM_SPLICE_CLOSE_SOURCE |
          G_OUTPUT_STREAM_SPLICE_CLOSE_TARGET,
          G_PRIORITY_DEFAULT, self->priv->cancellable,
          splice_stream_ready_cb, g_object_ref (self));
    }
}

static gboolean
client_socket_cb (GSocket *socket,
    GIOCondition condition,
    TpFileTransferChannel *self)
{
  GError *error = NULL;

  if (!g_socket_check_connect_result (socket, &error))
    {
      DEBUG ("Failed to connect to socket: %s", error->message);
      g_clear_error (&error);
      return FALSE;
    }

  DEBUG ("Client socket connected after pending");
  client_socket_connected (self);

  return FALSE;
}

/* Callbacks */

static void start_transfer (TpFileTransferChannel *self);

static void
tp_file_transfer_channel_state_changed_cb (TpChannel *proxy,
    guint state,
    guint reason,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;

  if (state == self->priv->state)
    return;

  DEBUG ("File transfer state changed: "
      "old state = %u, state = %u, reason = %u, "
      "requested = %s, in_stream = %s, out_stream = %s",
      self->priv->state, state, reason,
      tp_channel_get_requested (proxy) ? "yes" : "no",
      self->priv->in_stream ? "present" : "not present",
      self->priv->out_stream ? "present" : "not present");

  self->priv->state = state;
  self->priv->state_reason = reason;

  /* If the channel is open AND we have the socket path, we can start the
   * transfer. The socket path could be NULL if we are not doing the actual
   * data transfer but are just an observer for the channel. */
  if (state == TP_FILE_TRANSFER_STATE_OPEN
      && self->priv->remote_address != NULL)
    {
      start_transfer (self);
    }

  g_object_notify (G_OBJECT (self), "state");
}

static void
tp_file_transfer_channel_initial_offset_defined_cb (TpChannel *proxy,
    guint64 initial_offset,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;

  self->priv->initial_offset = initial_offset;
  g_object_notify (G_OBJECT (self), "initial-offset");
}

static void
tp_file_transfer_channel_transferred_bytes_changed_cb (TpChannel *proxy,
    guint64 count,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;

  self->priv->transferred_bytes = count;
  g_object_notify (G_OBJECT (self), "transferred-bytes");
}

static void
tp_file_transfer_channel_uri_defined_cb (TpChannel *proxy,
    const gchar *uri,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;

  g_clear_object (&self->priv->file);
  self->priv->file = g_file_new_for_uri (uri);
  g_object_notify (G_OBJECT (self), "file");
}

static void
tp_file_transfer_channel_prepare_core_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;
  GSimpleAsyncResult *result = user_data;
  gboolean valid;
  const gchar *uri;

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (result, error);
      goto out;
    }

  self->priv->state = tp_asv_get_uint32 (properties, "State", &valid);
  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.State property",
          tp_proxy_get_object_path (self));
    }

  self->priv->transferred_bytes = tp_asv_get_uint64 (properties,
      "TransferredBytes", &valid);
  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.TransferredBytes property",
          tp_proxy_get_object_path (self));
    }

  self->priv->initial_offset = tp_asv_get_uint64 (properties, "InitialOffset",
      &valid);
  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.InitialOffset property",
          tp_proxy_get_object_path (self));
    }

  /* URI might already be set from immutable properties */
  uri = tp_asv_get_string (properties, "URI");
  if (self->priv->file == NULL && uri != NULL)
    self->priv->file = g_file_new_for_uri (uri);

out:
  g_simple_async_result_complete_in_idle (result);
}

static void
invalidated_cb (TpFileTransferChannel *self,
    guint domain,
    gint code,
    gchar *message,
    gpointer user_data)
{
  /* stop splicing */
  if (self->priv->cancellable != NULL)
    g_cancellable_cancel (self->priv->cancellable);
}

/* Private methods */

static void
tp_file_transfer_channel_prepare_core_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) proxy;
  TpChannel *channel = (TpChannel *) proxy;
  GSimpleAsyncResult *result;
  GError *error = NULL;

  tp_cli_channel_type_file_transfer_connect_to_file_transfer_state_changed (
      channel, tp_file_transfer_channel_state_changed_cb,
      NULL, NULL, NULL, &error);
  if (error != NULL)
    {
      WARNING ("Failed to connect to StateChanged on %s: %s",
          tp_proxy_get_object_path (self), error->message);
      g_error_free (error);
    }

  tp_cli_channel_type_file_transfer_connect_to_initial_offset_defined (
      channel, tp_file_transfer_channel_initial_offset_defined_cb,
      NULL, NULL, NULL, &error);
  if (error != NULL)
    {
      WARNING ("Failed to connect to InitialOffsetDefined on %s: %s",
          tp_proxy_get_object_path (self), error->message);
      g_error_free (error);
    }

  tp_cli_channel_type_file_transfer_connect_to_transferred_bytes_changed (
      channel, tp_file_transfer_channel_transferred_bytes_changed_cb,
      NULL, NULL, NULL, &error);
  if (error != NULL)
    {
      WARNING ("Failed to connect to TransferredBytesChanged on %s: %s",
          tp_proxy_get_object_path (self), error->message);
      g_error_free (error);
    }

  tp_cli_channel_type_file_transfer_connect_to_uri_defined (
      channel, tp_file_transfer_channel_uri_defined_cb,
      NULL, NULL, NULL, &error);
  if (error != NULL)
    {
      WARNING ("Failed to connect to UriDefined on %s: %s",
          tp_proxy_get_object_path (self), error->message);
      g_error_free (error);
    }

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_file_transfer_channel_prepare_core_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER,
      tp_file_transfer_channel_prepare_core_cb,
      result, g_object_unref,
      NULL);
}

static void
tp_file_transfer_channel_constructed (GObject *obj)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) obj;
  GHashTable *properties;
  gboolean valid;
  gint64 date;
  const gchar *uri;

  G_OBJECT_CLASS (tp_file_transfer_channel_parent_class)->constructed (obj);

  properties = _tp_channel_get_immutable_properties (TP_CHANNEL (self));

  self->priv->mime_type = tp_asv_get_string (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_TYPE);
  if (self->priv->mime_type == NULL)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.ContentType in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  self->priv->filename = tp_asv_get_string (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_FILENAME);
  if (self->priv->filename == NULL)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.Filename in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  self->priv->size = tp_asv_get_uint64 (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_SIZE, &valid);
  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.Size in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  self->priv->content_hash_type = tp_asv_get_uint32 (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_HASH_TYPE, &valid);
  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.ContentHashType in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  self->priv->content_hash = tp_asv_get_string (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_HASH);
  if (self->priv->content_hash == NULL)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.ContentHash in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  self->priv->description = tp_asv_get_string (properties,
    TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DESCRIPTION);
  if (self->priv->description == NULL)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.Description in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  date = tp_asv_get_int64 (properties, TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DATE,
      &valid);

  if (!valid)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.Date in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }
  else
    {
      self->priv->date = g_date_time_new_from_unix_utc (date);
    }

  self->priv->available_socket_types = tp_asv_get_boxed (properties,
     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_AVAILABLE_SOCKET_TYPES,
     TP_HASH_TYPE_SUPPORTED_SOCKET_MAP);
  if (self->priv->available_socket_types == NULL)
    {
      DEBUG ("Channel %s doesn't have FileTransfer.AvailableSocketTypes in its "
          "immutable properties", tp_proxy_get_object_path (self));
    }

  /* URI might be immutable */
  uri = tp_asv_get_string (properties, TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_URI);
  if (uri != NULL)
    self->priv->file = g_file_new_for_uri (uri);

  self->priv->service_name = tp_asv_get_string (properties,
      TP_PROP_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA_SERVICE_NAME);

  self->priv->metadata = tp_asv_get_boxed (properties,
     TP_PROP_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA_METADATA,
     TP_HASH_TYPE_METADATA);

  if (self->priv->metadata == NULL)
    self->priv->metadata = g_hash_table_new (g_str_hash, g_str_equal);
  else
    g_hash_table_ref (self->priv->metadata);

  self->priv->cancellable = g_cancellable_new ();
  g_signal_connect (self, "invalidated",
      G_CALLBACK (invalidated_cb), NULL);
}

static void
tp_file_transfer_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) object;

  switch (property_id)
    {
      case PROP_MIME_TYPE:
        g_value_set_string (value, self->priv->mime_type);
        break;

      case PROP_DATE:
        g_value_set_boxed (value, self->priv->date);
        break;

      case PROP_DESCRIPTION:
        g_value_set_string (value, self->priv->description);
        break;

      case PROP_FILENAME:
        g_value_set_string (value, self->priv->filename);
        break;

      case PROP_SIZE:
        g_value_set_uint64 (value, self->priv->size);
        break;

      case PROP_STATE:
        g_value_set_uint (value, self->priv->state);
        break;

      case PROP_TRANSFERRED_BYTES:
        g_value_set_uint64 (value, self->priv->transferred_bytes);
        break;

      case PROP_FILE:
        g_value_set_object (value, self->priv->file);
        break;

      case PROP_INITIAL_OFFSET:
        g_value_set_uint64 (value, self->priv->initial_offset);
        break;

      case PROP_SERVICE_NAME:
        g_value_set_string (value, self->priv->service_name);
        break;

      case PROP_METADATA:
        g_value_set_boxed (value, self->priv->metadata);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

enum /* features */
{
  FEAT_CORE,
  N_FEAT
};

static const TpProxyFeature *
tp_file_transfer_channel_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
      return features;

  features[FEAT_CORE].name = TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE;
  features[FEAT_CORE].core = TRUE;
  features[FEAT_CORE].prepare_async =
    tp_file_transfer_channel_prepare_core_async;

  /* Assert that the terminator at the end is present */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_file_transfer_channel_dispose (GObject *obj)
{
  TpFileTransferChannel *self = (TpFileTransferChannel *) obj;

  tp_clear_pointer (&self->priv->date, g_date_time_unref);
  g_clear_object (&self->priv->file);
  tp_clear_pointer (&self->priv->metadata, g_hash_table_unref);
  g_clear_object (&self->priv->stream);

  if (self->priv->cancellable != NULL)
    g_cancellable_cancel (self->priv->cancellable);
  g_clear_object (&self->priv->cancellable);

  if (self->priv->remote_address != NULL)
    {
#ifdef HAVE_GIO_UNIX
      /* Check if we need to remove our temp file */
      if (G_IS_UNIX_SOCKET_ADDRESS (self->priv->remote_address))
        {
          const gchar *path;

          path = g_unix_socket_address_get_path (
              G_UNIX_SOCKET_ADDRESS (self->priv->remote_address));
          g_unlink (path);
        }
#endif /* HAVE_GIO_UNIX */
      g_object_unref (self->priv->remote_address);
      self->priv->remote_address = NULL;
    }

  tp_clear_pointer (&self->priv->access_control_param, tp_g_value_slice_free);
  tp_clear_object (&self->priv->client_socket);

  G_OBJECT_CLASS (tp_file_transfer_channel_parent_class)->dispose (obj);
}

static void
tp_file_transfer_channel_class_init (TpFileTransferChannelClass *klass)
{
  GParamSpec *param_spec;
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;

  object_class->constructed = tp_file_transfer_channel_constructed;
  object_class->get_property = tp_file_transfer_channel_get_property;
  object_class->dispose = tp_file_transfer_channel_dispose;

  proxy_class->list_features = tp_file_transfer_channel_list_features;

  /* Properties */

  /**
   * TpFileTransferChannel:mime-type:
   *
   * The MIME type of the file to be transferred.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_string ("mime-type",
      "ContentType",
      "The ContentType property of this channel",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MIME_TYPE,
      param_spec);

  /**
   * TpFileTransferChannel:date:
   *
   * A #GDateTime representing the last modification time of the file to be
   * transferred.
   *
   * Since 0.15.5
   */
  param_spec = g_param_spec_boxed ("date",
      "Date",
      "The Date property of this channel",
      G_TYPE_DATE_TIME,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DATE,
      param_spec);

  /**
   * TpFileTransferChannel:description:
   *
   * The description of the file transfer, defined by the sender when
   * sending the file transfer offer.
   *
   * Since 0.15.5
   */
  param_spec = g_param_spec_string ("description",
      "Description",
      "The Description property of this channel",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DESCRIPTION,
      param_spec);

  /**
    * TpFileTransferChannel:file:
    *
    * For incoming file transfers, this property will be set to a
    * #GFile for the location where the file will be saved (given by
    * tp_file_transfer_channel_accept_file_async()) when the transfer
    * starts. The feature %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE must
    * already be prepared for this property to have a meaningful
    * value, and to receive change notification.  Once the initial
    * value is set, this property will not be changed.
    *
    * For outgoing file transfers, this property is a #GFile for the
    * location of the file being sent (given by
    * tp_file_transfer_channel_provide_file_async()). The feature
    * %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE does not have to be
    * prepared and there is no change notification.
    *
    * Since: 0.17.1
    */
  param_spec = g_param_spec_object ("file",
      "File",
      "A GFile corresponding to the URI property of this channel",
      G_TYPE_FILE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_FILE,
      param_spec);

  /**
   * TpFileTransferChannel:filename:
   *
   * The name of the file on the sender's side. This is therefore given as a
   * suggested filename for the receiver.
   *
   * Since 0.15.5
   */
  param_spec = g_param_spec_string ("filename",
      "Filename",
      "The Filename property of this channel",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_FILENAME,
      param_spec);

  /**
   * TpFileTransferChannel:size:
   *
   * The size of the file to be transferred,
   * or %G_MAXUINT64 if not known.
   *
   * Since 0.15.5
   */
  param_spec = g_param_spec_uint64 ("size",
      "Size",
      "The Size property of this channel",
      0, G_MAXUINT64, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SIZE,
      param_spec);

  /**
   * TpFileTransferChannel:state:
   *
   * A TpFileTransferState holding the state of the file transfer.
   *
   * The %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE feature has to be
   * prepared for this property to be meaningful and kept up to date.
   *
   * Since 0.17.1
   */
  param_spec = g_param_spec_uint ("state",
      "State",
      "The TpFileTransferState of the channel",
      0, TP_NUM_FILE_TRANSFER_STATES, TP_FILE_TRANSFER_STATE_NONE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STATE,
      param_spec);

  /**
   * TpFileTransferChannel:transferred-bytes:
   *
   * The number of bytes transferred so far in this
   * file transfer.
   *
   * The %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE feature has to be
   * prepared for this property to be meaningful and kept up to date.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_uint64 ("transferred-bytes",
      "TransferredBytes",
      "The TransferredBytes property of this channel",
      0, G_MAXUINT64, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_TRANSFERRED_BYTES,
      param_spec);

  /**
   * TpFileTransferChannel:initial-offset:
   *
   * The offset in bytes from where the file should be sent.
   *
   * The %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE feature has to be
   * prepared for this property to be meaningful and kept up to date.
   *
   * Since: 0.17.1
   */
  param_spec = g_param_spec_uint64 ("initial-offset",
      "InitialOffset",
      "The InitialOffset property of this channel",
      0, G_MAXUINT64, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_OFFSET,
      param_spec);

  /**
   * TpFileTransferChannel:service-name:
   *
   * A string representing the name of the service suggested to handle
   * this file transfer channel, or %NULL if the initiator did not
   * provide one.
   *
   * This is a useful way of requesting file transfer channels with a
   * hint of what handler they should be handled by on the remote
   * side. If a channel request is made with this property set (to a
   * contact who also supports the metadata extension; see the
   * requestable channel classes for said contact), this property will
   * be set to the same value on the remote incoming channel and
   * handlers can match on this in their handler filter. For example,
   * a remote handler could call the following:
   *
   * |[
   * tp_base_client_take_handler_filter (handler, tp_asv_new (
   *               TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER,
   *               TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
   *               TP_PROP_CHANNEL_REQUESTED, G_TYPE_BOOLEAN, FALSE,
   *               TP_PROP_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA_SERVICE_NAME, G_TYPE_STRING, "service.name",
   *               NULL));
   * ]|
   *
   * The %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE feature has to be
   * prepared for this property to be meaningful.
   *
   * Since: 0.17.1
   */
  param_spec = g_param_spec_string ("service-name",
      "ServiceName",
      "The Metadata.ServiceName property of this channel",
      "",
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SERVICE_NAME,
      param_spec);

  /**
   * TpFileTransferChannel:metadata:
   *
   * Additional information about the file transfer set by the channel
   * initiator, or an empty #GHashTable if the initiator did not
   * provide any additional information.
   *
   * To provide metadata along with a file offer, include
   * %TP_PROP_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA_METADATA in the
   * channel request. For example:
   *
   * |[
   * GHashTable *request;
   * GHashTable *metadata = g_hash_table_new (g_str_hash, g_str_equal);
   * const gchar * const values[] = { "Jason Derulo", "Tinie Tempah", NULL };
   *
   * g_hash_table_insert (metadata, "best buds", values);
   *
   * request = tp_asv_new (
   *     TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER,
   *     TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
   *     TP_PROP_CHANNEL_TARGET_ID, G_TYPE_STRING, "foo@bar.com",
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_TYPE, G_TYPE_STRING, "text/plain",
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DATE, G_TYPE_INT64, 1320925992,
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DESCRIPTION, G_TYPE_STRING, "",
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_FILENAME, G_TYPE_STRING, "test.pdf",
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_INITIAL_OFFSET, G_TYPE_UINT64, 0,
   *     TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_SIZE, G_TYPE_UINT64, 165710,
   *     TP_PROP_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA_METADATA, TP_TYPE_METADATA, metadata,
   *     NULL);
   *
   * ...
   * ]|
   *
   * The %TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE feature has to be
   * prepared for this property to be meaningful.
   *
   * Since: 0.17.1
   */
  param_spec = g_param_spec_boxed ("metadata",
      "Metadata",
      "The Metadata.Metadata property of this channel",
      TP_HASH_TYPE_METADATA,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_METADATA,
      param_spec);

  g_type_class_add_private (object_class, sizeof
      (TpFileTransferChannelPrivate));
}

static void
tp_file_transfer_channel_init (TpFileTransferChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self),
      TP_TYPE_FILE_TRANSFER_CHANNEL, TpFileTransferChannelPrivate);
}

/**
 * TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core"
 * feature on a #TpFileTransferChannel.
 *
 * When this feature is prepared, the #TpFileTransferChannel:transferred-bytes
 * property has been retrieved and will be updated.
 *
 * One can ask for a feature to be prepared using the tp_proxy_prepare_async()
 * function, and waiting for it to trigger the callback.
 *
 * Since: 0.15.5
 */

GQuark
tp_file_transfer_channel_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-file-transfer-channel-feature-core");
}


/* Public methods */

/**
 * tp_file_transfer_channel_new:
 * @conn: a #TpConnection; may not be %NULL
 * @object_path: the object path of the channel; may not be %NULL
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the channel,
 *  as signalled by the NewChannel D-Bus signal or returned by the
 *  CreateChannel and EnsureChannel D-Bus methods: a mapping from
 *  strings (D-Bus interface name + "." + property name) to #GValue instances
 * @error: used to indicate the error if %NULL is returned
 *
 * Convenient function to create a new #TpFileTransferChannel
 *
 * Returns: (transfer full): a newly created #TpFileTransferChannel
 *
 * Since: 0.15.5
 * Deprecated: Use tp_simple_client_factory_ensure_channel() instead.
 */
TpFileTransferChannel *
tp_file_transfer_channel_new (TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  return _tp_file_transfer_channel_new_with_factory (NULL, conn, object_path,
      immutable_properties, error);
}

TpFileTransferChannel *
_tp_file_transfer_channel_new_with_factory (
    TpSimpleClientFactory *factory,
    TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpProxy *conn_proxy = (TpProxy *) conn;

  g_return_val_if_fail (TP_IS_CONNECTION (conn), NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (immutable_properties != NULL, NULL);

  if (!tp_dbus_check_valid_object_path (object_path, error))
      return NULL;

  return g_object_new (TP_TYPE_FILE_TRANSFER_CHANNEL,
      "connection", conn,
      "dbus-daemon", conn_proxy->dbus_daemon,
      "bus-name", conn_proxy->bus_name,
      "object-path", object_path,
      "handle-type", (guint) TP_UNKNOWN_HANDLE_TYPE,
      "channel-properties", immutable_properties,
      "factory", factory,
      NULL);
}

static void
start_transfer (TpFileTransferChannel *self)
{
  GError *error = NULL;

  g_socket_set_blocking (self->priv->client_socket, FALSE);

  /* g_socket_connect returns true on successful connection */
  if (g_socket_connect (self->priv->client_socket,
          self->priv->remote_address, NULL, &error))
    {
      DEBUG ("Client socket connected immediately");
      client_socket_connected (self);
    }
  else if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_PENDING))
    {
      /* The connection is pending */
      GSource *source;

      source = g_socket_create_source (self->priv->client_socket, G_IO_OUT,
          NULL);

      g_source_attach (source, g_main_context_get_thread_default ());
      g_source_set_callback (source, (GSourceFunc) client_socket_cb,
          g_object_ref (self), g_object_unref);

      g_error_free (error);
      g_source_unref (source);
    }
  else
    {
      DEBUG ("Failed to connect to socket: %s:", error->message);
      g_clear_error (&error);
    }
}

static void
accept_or_provide_file_cb (TpChannel *proxy,
    const GValue *address,
    const GError *dbus_error,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = TP_FILE_TRANSFER_CHANNEL (weak_object);
  GError *error = NULL;

  if (dbus_error != NULL)
    {
      DEBUG ("Error: %s", dbus_error->message);
      operation_failed (self, g_error_copy (dbus_error));
      return;
    }

  self->priv->remote_address = tp_g_socket_address_from_variant (self->priv->socket_type,
      address, &error);
  if (self->priv->remote_address == NULL)
    {
      DEBUG ("Failed to convert address: %s", error->message);
      operation_failed (self, error);
      return;
    }

  /* If the channel state is already Open, start the transfer
   * now. Otherwise, wait for the state change signal. */
  if (tp_file_transfer_channel_get_state (self, NULL)
      == TP_FILE_TRANSFER_STATE_OPEN)
    {
      start_transfer (self);
    }

  g_simple_async_result_complete_in_idle (self->priv->result);
  g_clear_object (&self->priv->result);
}

static gboolean
set_address_and_access_control (TpFileTransferChannel *self)
{
  GError *error = NULL;

  if (!_tp_set_socket_address_type_and_access_control_type (
          self->priv->available_socket_types,
          &self->priv->socket_type, &self->priv->access_control, &error))
    {
      operation_failed (self, error);
      return FALSE;
    }

  DEBUG ("Using socket type %u with access control %u",
      self->priv->socket_type, self->priv->access_control);

  self->priv->client_socket =
    _tp_create_client_socket (self->priv->socket_type, &error);
  if (self->priv->client_socket == NULL)
    {
      DEBUG ("Failed to create socket: %s", error->message);
      operation_failed (self, error);
      return FALSE;
    }

  switch (self->priv->access_control)
    {
      case TP_SOCKET_ACCESS_CONTROL_LOCALHOST:
      case TP_SOCKET_ACCESS_CONTROL_CREDENTIALS:
        /* Dummy value */
        self->priv->access_control_param = tp_g_value_slice_new_uint (0);
        break;

      case TP_SOCKET_ACCESS_CONTROL_PORT:
        {
          GSocketAddress *addr;

          addr = g_socket_get_local_address (self->priv->client_socket,
              &error);
          if (addr == NULL)
            {
              DEBUG ("Failed to get address of local socket: %s",
                  error->message);

              operation_failed (self, error);
              return FALSE;
            }

          self->priv->access_control_param =
            tp_address_variant_from_g_socket_address (addr, NULL, NULL);

          g_object_unref (addr);
        }
        break;

      default:
        g_assert_not_reached ();
    }

  return TRUE;
}

static void
file_transfer_set_uri_cb (TpProxy *proxy,
    const GError *uri_error,
    gpointer user_data,
    GObject *weak_object)
{
  TpFileTransferChannel *self = TP_FILE_TRANSFER_CHANNEL (weak_object);

  if (uri_error != NULL)
    {
      DEBUG ("Failed to set FileTransfer.URI: %s", uri_error->message);
      /* oh well */
    }

  if (!set_address_and_access_control (self))
    return;

  /* Call accept */
  tp_cli_channel_type_file_transfer_call_accept_file (TP_CHANNEL (self), -1,
      self->priv->socket_type,
      self->priv->access_control,
      self->priv->access_control_param,
      self->priv->requested_offset,
      accept_or_provide_file_cb,
      NULL,
      NULL,
      G_OBJECT (self));
}

static void
file_replace_async_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpFileTransferChannel *self = user_data;
  GFile *file = G_FILE (source);
  GFileOutputStream *out_stream;
  gchar *uri;
  GError *error = NULL;
  GValue *value;

  out_stream = g_file_replace_finish (file, result, &error);

  if (error != NULL)
    {
      DEBUG ("Failed to replace file: %s", error->message);
      operation_failed (self, error);
      return;
    }

  self->priv->out_stream = G_OUTPUT_STREAM (out_stream);

  g_clear_object (&self->priv->file);
  self->priv->file = g_object_ref (file);

  /* Try setting FileTransfer.URI before accepting the file */
  uri = g_file_get_uri (file);
  value = tp_g_value_slice_new_take_string (uri);

  tp_cli_dbus_properties_call_set (self, -1,
      TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER, "URI", value,
      file_transfer_set_uri_cb, NULL, NULL, G_OBJECT (self));

  tp_g_value_slice_free (value);
}

/**
 * tp_file_transfer_channel_accept_file_async:
 * @self: a #TpFileTransferChannel
 * @file: a #GFile where the file should be saved
 * @offset: Offset from the start of @file where transfer begins
 * @callback: a callback to call when the transfer has been accepted
 * @user_data: data to pass to @callback
 *
 * Accept an incoming file transfer in the
 * %TP_FILE_TRANSFER_STATE_PENDING state. Once the accept has been
 * processed, @callback will be called. You can then call
 * tp_file_transfer_channel_accept_file_finish() to get the result of
 * the operation.
 *
 * Since: 0.17.1
 */
void
tp_file_transfer_channel_accept_file_async (TpFileTransferChannel *self,
    GFile *file,
    guint64 offset,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self));
  g_return_if_fail (G_IS_FILE (file));

  if (self->priv->access_control_param != NULL)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't accept already accepted transfer");

      return;
    }

  if (self->priv->state != TP_FILE_TRANSFER_STATE_PENDING)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't accept a transfer that isn't pending");

      return;
    }

  if (tp_channel_get_requested (TP_CHANNEL (self)))
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't accept outgoing transfer");

      return;
    }

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_file_transfer_channel_accept_file_async);

  self->priv->requested_offset = offset;

  g_file_replace_async (file, NULL, FALSE, G_FILE_CREATE_NONE,
      G_PRIORITY_DEFAULT, NULL, file_replace_async_cb, self);
}

/**
 * tp_file_transfer_channel_accept_file_finish:
 * @self: a #TpFileTransferChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes a call to tp_file_transfer_channel_accept_file_async().
 *
 * Returns: %TRUE if the accept operation was a success, or %FALSE
 *
 * Since: 0.17.1
 */
gboolean
tp_file_transfer_channel_accept_file_finish (TpFileTransferChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_file_transfer_channel_accept_file_async)
}

static void
file_read_async_cb (GObject *source,
    GAsyncResult *res,
    gpointer user_data)
{
  TpFileTransferChannel *self = user_data;
  GFileInputStream *in_stream;
  GError *error = NULL;
  GFile *file = G_FILE (source);

  in_stream = g_file_read_finish (file, res, &error);

  if (error != NULL)
    {
      operation_failed (self, error);
      return;
    }

  self->priv->in_stream = G_INPUT_STREAM (in_stream);

  g_clear_object (&self->priv->file);
  self->priv->file = g_object_ref (file);

  if (!set_address_and_access_control (self))
    return;

  /* Call Provide */
  tp_cli_channel_type_file_transfer_call_provide_file (TP_CHANNEL (self), -1,
      self->priv->socket_type,
      self->priv->access_control,
      self->priv->access_control_param,
      accept_or_provide_file_cb,
      NULL, NULL, G_OBJECT (self));
}

/**
 * tp_file_transfer_channel_provide_file_async:
 * @self: a #TpFileTransferChannel
 * @file: a #GFile to send to the remote contact
 * @callback: a callback to call when the transfer has been accepted
 * @user_data: data to pass to @callback
 *
 * Provide a file transfer. This should be called when the file
 * transfer state changes (tp_file_transfer_channel_get_state() and
 * the "notify::state" signal) to
 * %TP_FILE_TRANSFER_STATE_ACCEPTED or
 * %TP_FILE_TRANSFER_STATE_PENDING. Once the file has been provided,
 * the channel #TpFileTransferChannel:state will change to
 * %TP_FILE_TRANSFER_STATE_OPEN.
 *
 * Once the file has been provided, @callback will be called. You
 * should then call tp_file_transfer_channel_provide_file_finish() to
 * get the result of the operation.
 *
 * Since: 0.17.1
 */
void
tp_file_transfer_channel_provide_file_async (TpFileTransferChannel *self,
    GFile *file,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self));
  g_return_if_fail (G_IS_FILE (file));

  if (self->priv->access_control_param != NULL)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't provide already provided transfer");

      return;
    }

  if (self->priv->state != TP_FILE_TRANSFER_STATE_ACCEPTED
      && self->priv->state != TP_FILE_TRANSFER_STATE_PENDING)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't provide a transfer that isn't pending or accepted");

      return;
    }

  if (!tp_channel_get_requested (TP_CHANNEL (self)))
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Can't provide incoming transfer");

      return;
    }

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_file_transfer_channel_provide_file_async);

  g_file_read_async (file, G_PRIORITY_DEFAULT, NULL,
      file_read_async_cb, self);
}

/**
 * tp_file_transfer_channel_provide_file_finish:
 * @self: a #TpFileTransferChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes a call to tp_file_transfer_channel_provide_file_async().
 *
 *
 * Successful return from this function does not mean that the file
 * transfer has completed or has even started at all. The state of the
 * file transfer should be monitored with the "notify::state" signal.
 *
 * Returns: %TRUE if the file has been successfully provided, or
 * %FALSE.
 *
 * Since: 0.17.1
 */
gboolean
tp_file_transfer_channel_provide_file_finish (TpFileTransferChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_file_transfer_channel_provide_file_async)
}


/* Property accessors */

/**
 * tp_file_transfer_channel_get_mime_type:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:mime-type property
 *
 * Returns: (transfer none): the value of the
 *   #TpFileTransferChannel:mime-type property
 *
 * Since: 0.15.5
 */
const char *
tp_file_transfer_channel_get_mime_type (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->mime_type;
}

/**
 * tp_file_transfer_channel_get_date:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:date property
 *
 * Returns: (transfer none): the value of the #TpFileTransferChannel:date
 *   property
 *
 * Since: 0.15.5
 */
GDateTime *
tp_file_transfer_channel_get_date (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->date;
}

/**
 * tp_file_transfer_channel_get_description:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:description property
 *
 * Returns: (transfer none): the value of the
 *   #TpFileTransferChannel:description property
 *
 * Since: 0.15.5
 */
const gchar *
tp_file_transfer_channel_get_description (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->description;
}

/**
 * tp_file_transfer_channel_get_filename:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:filename property
 *
 * Returns: (transfer none): the value of the
 *   #TpFileTransferChannel:filename property
 *
 * Since: 0.15.5
 */
const gchar *
tp_file_transfer_channel_get_filename (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->filename;
}

/**
 * tp_file_transfer_channel_get_size:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:size property
 *
 * Returns: the value of the #TpFileTransferChannel:size property
 *
 * Since: 0.15.5
 */
guint64
tp_file_transfer_channel_get_size (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), 0);

  return self->priv->size;
}

/**
 * tp_file_transfer_channel_get_state:
 * @self: a #TpFileTransferChannel
 * @reason: (out): a #TpFileTransferStateChangeReason, or %NULL
 *
 * Returns the #TpFileTransferChannel:state property.
 *
 * If @reason is not %NULL it is set to the reason why
 * #TpFileTransferChannel:state changed to its current value.
 *
 * Returns: the value of the #TpFileTransferChannel:state property
 *
 * Since: 0.17.1
 */
TpFileTransferState
tp_file_transfer_channel_get_state (TpFileTransferChannel *self,
    TpFileTransferStateChangeReason *reason)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self),
      TP_FILE_TRANSFER_STATE_NONE);

  if (reason != NULL)
    *reason = self->priv->state_reason;

  return self->priv->state;
}

/**
 * tp_file_transfer_channel_get_transferred_bytes:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:transferred-bytes property
 *
 * Returns: the value of the #TpFileTransferChannel:transferred-bytes property
 *
 * Since: 0.15.5
 */
guint64
tp_file_transfer_channel_get_transferred_bytes (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), 0);

  return self->priv->transferred_bytes;
}

/**
 * tp_file_transfer_channel_get_service_name:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:service-name property
 *
 * Returns: the value of the #TpFileTransferChannel:service-name property
 *
 * Since: 0.17.1
 */
const gchar *
tp_file_transfer_channel_get_service_name (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->service_name;
}

/**
 * tp_file_transfer_channel_get_metadata:
 * @self: a #TpFileTransferChannel
 *
 * Return the #TpFileTransferChannel:metadata property
 *
 * Returns: (transfer none) (element-type utf8 GStrv): the
 *   value of the #TpFileTransferChannel:metadata property
 *
 * Since: 0.17.1
 */
const GHashTable *
tp_file_transfer_channel_get_metadata (TpFileTransferChannel *self)
{
  g_return_val_if_fail (TP_IS_FILE_TRANSFER_CHANNEL (self), NULL);

  return self->priv->metadata;
}
