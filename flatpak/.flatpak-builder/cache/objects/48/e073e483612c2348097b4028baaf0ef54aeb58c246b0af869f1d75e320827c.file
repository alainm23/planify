/*
 * call-content.h - high level API for Call contents
 *
 * Copyright (C) 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * SECTION:call-content
 * @title: TpCallContent
 * @short_description: proxy object for a call content
 *
 * #TpCallContent is a sub-class of #TpProxy providing convenient API
 * to represent #TpCallChannel's content.
 */

/**
 * TpCallContent:
 *
 * Data structure representing a #TpCallContent.
 *
 * Since: 0.17.5
 */

/**
 * TpCallContentClass:
 *
 * The class of a #TpCallContent.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "telepathy-glib/call-content.h"

#include <telepathy-glib/call-channel.h>
#include <telepathy-glib/call-misc.h>
#include <telepathy-glib/call-stream.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dtmf.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/call-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/util-internal.h"

#include "_gen/tp-cli-call-content-body.h"

G_DEFINE_TYPE (TpCallContent, tp_call_content, TP_TYPE_PROXY)

typedef struct _SendTonesData SendTonesData;

struct _TpCallContentPrivate
{
  TpConnection *connection;
  TpCallChannel *channel;

  gchar *name;
  TpMediaStreamType media_type;
  TpCallContentDisposition disposition;
  GPtrArray *streams;

  gboolean properties_retrieved;

  GQueue *tones_queue;
  SendTonesData *current_tones;
};

enum
{
  PROP_CONNECTION = 1,
  PROP_NAME,
  PROP_MEDIA_TYPE,
  PROP_DISPOSITION,
  PROP_STREAMS,
  PROP_CHANNEL
};

enum
{
  REMOVED,
  STREAMS_ADDED,
  STREAMS_REMOVED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

static TpCallStream *
_tp_call_stream_new (TpCallContent *self,
    const gchar *object_path)
{
  return g_object_new (TP_TYPE_CALL_STREAM,
      "bus-name", tp_proxy_get_bus_name (self),
      "dbus-daemon", tp_proxy_get_dbus_daemon (self),
      "dbus-connection", tp_proxy_get_dbus_connection (self),
      "object-path", object_path,
      "connection", self->priv->connection,
      "content", self,
      "factory", tp_proxy_get_factory (self),
      NULL);
}

static void
streams_added_cb (TpCallContent *self,
    const GPtrArray *streams,
    gpointer user_data,
    GObject *weak_object)
{
  guint i;
  GPtrArray *added_streams;

  if (!self->priv->properties_retrieved)
    return;

  added_streams = g_ptr_array_sized_new (streams->len);

  for (i = 0; i < streams->len; i++)
    {
      const gchar *object_path = g_ptr_array_index (streams, i);
      TpCallStream *stream ;

      DEBUG ("Stream added: %s", object_path);

      stream = _tp_call_stream_new (self, object_path);
      g_ptr_array_add (self->priv->streams, stream);
      g_ptr_array_add (added_streams, stream);
    }

  g_signal_emit (self, _signals[STREAMS_ADDED], 0, added_streams);
  g_ptr_array_unref (added_streams);
}

static void
streams_removed_cb (TpCallContent *self,
    const GPtrArray *streams,
    const GValueArray *reason,
    gpointer user_data,
    GObject *weak_object)
{
  GPtrArray *removed_streams;
  guint i;

  if (!self->priv->properties_retrieved)
    return;

  removed_streams = g_ptr_array_new_full (streams->len, g_object_unref);

  for (i = 0; i < streams->len; i++)
    {
      const gchar *object_path = g_ptr_array_index (streams, i);
      gboolean found = FALSE;
      guint j;

      for (j = 0; j < self->priv->streams->len; j++)
        {
          TpCallStream *stream = g_ptr_array_index (self->priv->streams, j);

          if (!tp_strdiff (tp_proxy_get_object_path (stream), object_path))
            {
              DEBUG ("Stream removed: %s", object_path);

              found = TRUE;
              g_ptr_array_add (removed_streams, g_object_ref (stream));
              g_ptr_array_remove_index_fast (self->priv->streams, j);
              break;
            }
        }

      if (!found)
        DEBUG ("Stream '%s' removed but not found", object_path);
    }

  if (removed_streams->len > 0)
    {
      TpCallStateReason *r;

      r = _tp_call_state_reason_new (reason);
      g_signal_emit (self, _signals[STREAMS_REMOVED], 0, removed_streams, r);
      _tp_call_state_reason_unref (r);
    }

  g_ptr_array_unref (removed_streams);
}

static void tones_stopped_cb (TpCallContent *self,
    gboolean cancelled,
    gpointer user_data,
    GObject *weak_object);

static void
got_all_properties_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallContent *self = (TpCallContent *) proxy;
  const gchar * const *interfaces;
  GPtrArray *streams;
  guint i;

  if (error != NULL)
    {
      DEBUG ("Could not get the call content properties: %s", error->message);
      _tp_proxy_set_feature_prepared (proxy,
          TP_CALL_CONTENT_FEATURE_CORE, FALSE);
      return;
    }

  self->priv->properties_retrieved = TRUE;

  interfaces = tp_asv_get_boxed (properties,
      "Interfaces", G_TYPE_STRV);
  self->priv->name = g_strdup (tp_asv_get_string (properties,
      "Name"));
  self->priv->media_type = tp_asv_get_uint32 (properties,
      "Type", NULL);
  self->priv->disposition = tp_asv_get_uint32 (properties,
      "Disposition", NULL);
  streams = tp_asv_get_boxed (properties,
      "Streams", TP_ARRAY_TYPE_OBJECT_PATH_LIST);

  tp_proxy_add_interfaces ((TpProxy *) self, interfaces);

  for (i = 0; i < streams->len; i++)
    {
      const gchar *object_path = g_ptr_array_index (streams, i);

      DEBUG ("Initial stream added: %s", object_path);

      g_ptr_array_add (self->priv->streams,
          _tp_call_stream_new (self, object_path));
    }

  if (tp_proxy_has_interface_by_id (self,
          TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF))
    {
      tp_cli_call_content_interface_dtmf_connect_to_stopped_tones (self,
          tones_stopped_cb, NULL, NULL, NULL, NULL);
    }

  _tp_proxy_set_feature_prepared (proxy, TP_CALL_CONTENT_FEATURE_CORE, TRUE);
}

struct _SendTonesData
{
  TpCallContent *content;
  gchar *tones;
  GSimpleAsyncResult *result;
  GCancellable *cancellable;
  guint cancel_id;
};

static void maybe_send_tones (TpCallContent *self);
static void send_tones_cancelled_cb (GCancellable *cancellable,
    SendTonesData *data);

static SendTonesData *
send_tones_data_new (TpCallContent *self,
    const gchar *tones,
    GSimpleAsyncResult *result,
    GCancellable *cancellable)
{
  SendTonesData *data;

  data = g_slice_new0 (SendTonesData);
  data->content = g_object_ref (self);
  data->tones = g_strdup (tones);
  data->result = g_object_ref (result);

  if (cancellable != NULL)
    {
      data->cancellable = g_object_ref (cancellable);
      data->cancel_id = g_cancellable_connect (cancellable,
          G_CALLBACK (send_tones_cancelled_cb), data, NULL);
    }

  return data;
}

static void
send_tones_data_free (SendTonesData *data)
{
  g_free (data->tones);
  g_object_unref (data->result);
  g_object_unref (data->content);

  if (data->cancellable != NULL)
    {
      if (data->cancel_id != 0)
        g_cancellable_disconnect (data->cancellable, data->cancel_id);

      g_object_unref (data->cancellable);
    }

  g_slice_free (SendTonesData, data);
}

static gboolean
send_tones_cancelled_idle_cb (gpointer user_data)
{
  SendTonesData *data = user_data;
  TpCallContent *self = data->content;

  /* If it is the tone currently being played, stop it. Otherwise wait for its
   * turn in the queue to preserve order. */
  if (self->priv->current_tones == data)
    {
      tp_cli_call_content_interface_dtmf_call_stop_tone (self, -1,
          NULL, NULL, NULL, NULL);
    }

  return FALSE;
}

static void
send_tones_cancelled_cb (GCancellable *cancellable,
    SendTonesData *data)
{
  /* Cancel in idle for thread-safeness */
  g_idle_add (send_tones_cancelled_idle_cb, data);
}

static void
complete_sending_tones (TpCallContent *self,
    const GError *error)
{
  if (self->priv->current_tones == NULL)
    return;

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (self->priv->current_tones->result,
          error);
    }

  g_simple_async_result_complete (self->priv->current_tones->result);

  send_tones_data_free (self->priv->current_tones);
  self->priv->current_tones = NULL;

  maybe_send_tones (self);
}

static void
tones_stopped_cb (TpCallContent *self,
    gboolean cancelled,
    gpointer user_data,
    GObject *weak_object)
{
  if (cancelled)
    {
      GError e = { TP_ERROR, TP_ERROR_CANCELLED,
          "The DTMF tones were actively cancelled via StopTones" };
      complete_sending_tones (self, &e);
      return;
    }

  complete_sending_tones (self, NULL);
}

static void
multiple_tones_cb (TpCallContent *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  if (error != NULL)
    complete_sending_tones (self, error);
}

static void
maybe_send_tones (TpCallContent *self)
{
  if (self->priv->current_tones != NULL)
    return;

  if (g_queue_is_empty (self->priv->tones_queue))
    return;

  self->priv->current_tones = g_queue_pop_head (self->priv->tones_queue);

  /* Yes this is safe if cancellable is NULL! */
  if (g_cancellable_is_cancelled (self->priv->current_tones->cancellable))
    {
      GError e = { TP_ERROR, TP_ERROR_CANCELLED,
          "The DTMF tones were cancelled before it has started" };
      complete_sending_tones (self, &e);
      return;
    }

  DEBUG ("Emitting multiple tones: %s", self->priv->current_tones->tones);
  tp_cli_call_content_interface_dtmf_call_multiple_tones (self, -1,
      self->priv->current_tones->tones, multiple_tones_cb, NULL, NULL, NULL);
}

static void
tp_call_content_constructed (GObject *obj)
{
  TpCallContent *self = (TpCallContent *) obj;

  ((GObjectClass *) tp_call_content_parent_class)->constructed (obj);

  /* Connect signals for mutable properties */
  tp_cli_call_content_connect_to_streams_added (self,
      streams_added_cb, NULL, NULL, G_OBJECT (self), NULL);
  tp_cli_call_content_connect_to_streams_removed (self,
      streams_removed_cb, NULL, NULL, G_OBJECT (self), NULL);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CALL_CONTENT,
      got_all_properties_cb, NULL, NULL, G_OBJECT (self));
}

static void
tp_call_content_dispose (GObject *object)
{
  TpCallContent *self = (TpCallContent *) object;

  g_clear_object (&self->priv->connection);
  tp_clear_pointer (&self->priv->name, g_free);
  tp_clear_pointer (&self->priv->streams, g_ptr_array_unref);

  G_OBJECT_CLASS (tp_call_content_parent_class)->dispose (object);
}

static void
tp_call_content_finalize (GObject *object)
{
  TpCallContent *self = (TpCallContent *) object;

  /* Results hold a ref on self, finalize can't happen if queue isn't empty */
  g_assert (self->priv->current_tones == NULL);
  g_assert (g_queue_is_empty (self->priv->tones_queue));
  g_queue_free (self->priv->tones_queue);

  G_OBJECT_CLASS (tp_call_content_parent_class)->finalize (object);
}

static void
tp_call_content_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpCallContent *self = (TpCallContent *) object;

  switch (property_id)
    {
      case PROP_CONNECTION:
        g_value_set_object (value, self->priv->connection);
        break;
      case PROP_NAME:
        g_value_set_string (value, self->priv->name);
        break;
      case PROP_MEDIA_TYPE:
        g_value_set_uint (value, self->priv->media_type);
        break;
      case PROP_DISPOSITION:
        g_value_set_uint (value, self->priv->disposition);
        break;
      case PROP_STREAMS:
        g_value_set_boxed (value, self->priv->streams);
        break;
      case PROP_CHANNEL:
        g_value_set_object (value, self->priv->channel);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_content_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpCallContent *self = (TpCallContent *) object;

  switch (property_id)
    {
      case PROP_CONNECTION:
        g_assert (self->priv->connection == NULL); /* construct-only */
        self->priv->connection = g_value_dup_object (value);
        break;
      case PROP_CHANNEL:
        g_assert (self->priv->channel == NULL); /* construct-only */
        self->priv->channel = g_value_dup_object (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

enum {
    FEAT_CORE,
    N_FEAT
};

static const TpProxyFeature *
tp_call_content_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
    return features;

  /* started from constructed */
  features[FEAT_CORE].name = TP_CALL_CONTENT_FEATURE_CORE;
  features[FEAT_CORE].core = TRUE;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_call_content_class_init (TpCallContentClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GParamSpec *param_spec;

  gobject_class->constructed = tp_call_content_constructed;
  gobject_class->get_property = tp_call_content_get_property;
  gobject_class->set_property = tp_call_content_set_property;
  gobject_class->dispose = tp_call_content_dispose;
  gobject_class->finalize = tp_call_content_finalize;

  proxy_class->list_features = tp_call_content_list_features;
  proxy_class->interface = TP_IFACE_QUARK_CALL_CONTENT;

  g_type_class_add_private (gobject_class, sizeof (TpCallContentPrivate));
  tp_call_content_init_known_interfaces ();

  /**
   * TpCallContent:connection:
   *
   * The #TpConnection of the call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("connection", "Connection",
      "The connection of this content",
      TP_TYPE_CONNECTION,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CONNECTION,
      param_spec);

  /**
   * TpCallContent:name:
   *
   * The name of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("name", "Name",
      "The name of this content, if any",
      "",
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_NAME, param_spec);

  /**
   * TpCallContent:media-type:
   *
   * The media type of this content, from #TpMediaStreamType.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("media-type", "Media type",
      "The media type of this content",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_MEDIA_TYPE, param_spec);

  /**
   * TpCallContent:disposition:
   *
   * The disposition of this content, from #TpCallContentDisposition.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("disposition", "Disposition",
      "The disposition of this content",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_DISPOSITION, param_spec);

  /* FIXME: Should be annoted with
   *
   * Type: GLib.PtrArray<TelepathyGLib.CallStream>
   * Transfer: container
   *
   * But it does not work (bgo#663846) and makes gtkdoc fail myserably.
   */

  /**
   * TpCallContent:streams:
   *
   * #GPtrArray of #TpCallStream objects. The list of stream objects that are
   * part of this content.
   *
   * It is NOT guaranteed that %TP_CALL_STREAM_FEATURE_CORE is prepared on
   * those objects.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("streams", "Stream",
      "The streams of this content",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_STREAMS,
      param_spec);

  /**
   * TpCallContent:channel:
   *
   * The parent #TpCallChannel of the content.
   *
   * Since: 0.17.6
   */
  param_spec = g_param_spec_object ("channel", "Channel",
      "The channel of this content",
      TP_TYPE_CALL_CHANNEL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CHANNEL,
      param_spec);


  /**
   * TpCallContent::removed:
   * @self: the #TpCallContent
   *
   * The ::removed signal is emitted when @self is removed from
   * a #TpCallChannel.
   *
   * Since: 0.17.5
   */
  _signals[REMOVED] = g_signal_new ("removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      0);

  /**
   * TpCallContent::streams-added:
   * @self: the #TpCallContent
   * @streams: (type GLib.PtrArray) (element-type TelepathyGLib.CallStream):
   *  a #GPtrArray of newly added #TpCallStream
   *
   * The ::streams-added signal is emitted whenever
   * #TpCallStream are added to @self.
   *
   * It is NOT guaranteed that %TP_CALL_STREAM_FEATURE_CORE is prepared on
   * stream objects.
   *
   * Since: 0.17.5
   */
  _signals[STREAMS_ADDED] = g_signal_new ("streams-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      1, G_TYPE_PTR_ARRAY);

  /**
   * TpCallContent::streams-removed:
   * @self: the #TpCallContent
   * @streams: (type GLib.PtrArray) (element-type TelepathyGLib.CallStream):
   *  a #GPtrArray of newly removed #TpCallStream
   * @reason: a #TpCallStateReason
   *
   * The ::streams-removed signal is emitted whenever
   * #TpCallStreams are removed from @self.
   *
   * It is NOT guaranteed that %TP_CALL_STREAM_FEATURE_CORE is prepared on
   * stream objects.
   *
   * Since: 0.17.5
   */
  _signals[STREAMS_REMOVED] = g_signal_new ("streams-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, G_TYPE_PTR_ARRAY, TP_TYPE_CALL_STATE_REASON);

}

static void
tp_call_content_init (TpCallContent *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_CALL_CONTENT,
      TpCallContentPrivate);

  self->priv->streams = g_ptr_array_new_with_free_func (g_object_unref);
  self->priv->tones_queue = g_queue_new ();
}

/**
 * tp_call_content_init_known_interfaces:
 *
 * Ensure that the known interfaces for #TpCallContent have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_CALL_CONTENT.
 *
 * Since: 0.17.5
 */
void
tp_call_content_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_CALL_CONTENT;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_call_content_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * TP_CALL_CONTENT_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core"
 * feature on a #TpCallContent.
 *
 * One can ask for a feature to be prepared using the tp_proxy_prepare_async()
 * function, and waiting for it to trigger the callback.
 */
GQuark
tp_call_content_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-call-content-feature-core");
}

/**
 * tp_call_content_get_name:
 * @self: a #TpCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallContent:name
 * Since: 0.17.5
 */
const gchar *
tp_call_content_get_name (TpCallContent *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT (self), NULL);

  return self->priv->name;
}

/**
 * tp_call_content_get_media_type:
 * @self: a #TpCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallContent:name
 * Since: 0.17.5
 */
TpMediaStreamType
tp_call_content_get_media_type (TpCallContent *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT (self), 0);

  return self->priv->media_type;
}

/**
 * tp_call_content_get_disposition:
 * @self: a #TpCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallContent:disposition
 * Since: 0.17.5
 */
TpCallContentDisposition
tp_call_content_get_disposition (TpCallContent *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT (self), 0);

  return self->priv->disposition;
}

/**
 * tp_call_content_get_streams:
 * @self: a #TpCallContent
 *
 * <!-- -->
 *
 * Returns: (transfer none) (type GLib.PtrArray) (element-type TelepathyGLib.CallStream):
 *  the value of #TpCallContent:streams
 * Since: 0.17.5
 */
GPtrArray *
tp_call_content_get_streams (TpCallContent *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT (self), NULL);

  return self->priv->streams;
}

static void
generic_async_cb (TpCallContent *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Error: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete (result);
}

/**
 * tp_call_content_remove_async:
 * @self: a #TpCallContent
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Remove the content from the call. This will cause #TpCallContent::removed
 * to be emitted.
 *
 * Since: 0.17.5
 */
void
tp_call_content_remove_async (TpCallContent *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CONTENT (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_content_remove_async);

  tp_cli_call_content_call_remove (self, -1,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_content_remove_finish:
 * @self: a #TpCallContent
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_content_remove_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_content_remove_finish (TpCallContent *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_content_remove_async);
}

/**
 * tp_call_content_send_tones_async:
 * @self: a #TpCallContent
 * @tones: a string representation of one or more DTMF events.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Send @tones DTMF code on @self content. @self must have the
 * %TP_IFACE_CALL_CONTENT_INTERFACE_DTMF interface.
 *
 * If DTMF tones are already being played, this request is queued.
 *
 * Since: 0.17.5
 */
void
tp_call_content_send_tones_async (TpCallContent *self,
    const gchar *tones,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  SendTonesData *data;

  g_return_if_fail (TP_IS_CALL_CONTENT (self));

  if (!tp_proxy_has_interface_by_id (self,
          TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF))
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self),
          callback, user_data, TP_ERROR, TP_ERROR_NOT_CAPABLE,
          "Content does not support DTMF");
      return;
    }

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_call_content_send_tones_async);

  data = send_tones_data_new (self, tones, result, cancellable);
  g_queue_push_tail (self->priv->tones_queue, data);

  maybe_send_tones (self);

  g_object_unref (result);
}

/**
 * tp_call_content_send_tones_finish:
 * @self: a #TpCallContent
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_content_send_tones_async().
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.17.5
 */
gboolean
tp_call_content_send_tones_finish (TpCallContent *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_content_send_tones_async);
}
