/*
 * base-media-call-stream.c - Source for TpBaseMediaCallStream
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
 * @author Jonny Lamb <jonny.lamb@collabora.co.uk>
 * @author David Laban <david.laban@collabora.co.uk>
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
 * SECTION:base-media-call-stream
 * @title: TpBaseMediaCallStream
 * @short_description: base class for #TpSvcCallStreamInterfaceMedia
 *  implementations
 * @see_also: #TpSvcCallStreamInterfaceMedia, #TpBaseCallChannel,
 *  #TpBaseCallStream and #TpBaseCallContent
 *
 * This base class makes it easier to write #TpSvcCallStreamInterfaceMedia
 * implementations by implementing some of its properties and methods.
 *
 * Subclasses must still implement #TpBaseCallStream's virtual methods plus
 * #TpBaseMediaCallStreamClass.add_local_candidates and
 * #TpBaseMediaCallStreamClass.finish_initial_candidates.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStream:
 *
 * A base class for media call stream implementations
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamClass:
 * @report_sending_failure: optional; called to indicate a failure in the
 *  outgoing portion of the stream
 * @report_receiving_failure: optional; called to indicate a failure in the
 *  incoming portion of the stream
 * @add_local_candidates: mandatory; called when new candidates are added
 * @finish_initial_candidates: optional; called when the initial batch of
 *  candidates has been added, and should now be processed/sent to the remote
 *  side
 * @request_receiving: optional (see #TpBaseCallStream:can-request-receiving);
 *  virtual method called when user requested receiving from the given remote
 *  contact. This virtual method should be implemented instead of
 *  #TpBaseCallStreamClass.request_receiving
 * @set_sending: mandatory; virtual method called when user requested to
 *  start/stop sending to remote contacts. This virtual method should be
 *  implemented instead of #TpBaseCallStreamClass.set_sending
 *
 * The class structure for #TpBaseMediaCallStream
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamFinishInitialCandidatesFunc:
 * @self: a #TpBaseMediaCallStream
 * @error: a #GError to fill
 *
 * Signature of an implementation of
 * #TpBaseMediaCallStreamClass.finish_initial_candidates.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamAddCandidatesFunc:
 * @self: a #TpBaseMediaCallStream
 * @candidates: a #GPtrArray of #GValueArray containing candidates info
 * @error: a #GError to fill
 *
 * Signature of an implementation of
 * #TpBaseMediaCallStreamClass.add_local_candidates.
 *
 * Implementation should validate the added @candidates and return a subset
 * (or all) of them that are accepted. Implementation should return a new
 * #GPtrArray build in a way that g_ptr_array_unref() is enough to free all its
 * memory. It is fine to just add element pointers from @candidates to the
 * returned #GPtrArray without deep-copy them.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamReportFailureFunc:
 * @self: a #TpBaseMediaCallStream
 * @old_state: the previous #TpStreamFlowState
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Signature of an implementation of
 * #TpBaseMediaCallStreamClass.report_sending_failure and
 * #TpBaseMediaCallStreamClass.report_receiving_failure.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamSetSendingFunc:
 * @self: a #TpBaseMediaCallStream
 * @sending: whether or not user would like to be sending
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseMediaCallStreamClass.set_sending.
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallStreamRequestReceivingFunc:
 * @self: a #TpBaseMediaCallStream
 * @contact: the contact from who user wants to start or stop receiving
 * @receive: wheter or not user would like to be receiving
 *
 * Signature of an implementation of
 * #TpBaseMediaCallStreamClass.request_receiving.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "base-media-call-stream.h"

#include <string.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/base-call-content.h"
#include "telepathy-glib/base-call-channel.h"
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-channel.h"
#include "telepathy-glib/base-connection.h"
#include "telepathy-glib/base-media-call-channel.h"
#include "telepathy-glib/call-stream-endpoint.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/enums.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/util.h"
#include "telepathy-glib/util-internal.h"

static void call_stream_media_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseMediaCallStream,
    tp_base_media_call_stream, TP_TYPE_BASE_CALL_STREAM,

    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA,
      call_stream_media_iface_init)
    )

/* properties */
enum
{
  PROP_SENDING_STATE = 1,
  PROP_RECEIVING_STATE,
  PROP_TRANSPORT,
  PROP_LOCAL_CANDIDATES,
  PROP_LOCAL_CREDENTIALS,
  PROP_STUN_SERVERS,
  PROP_RELAY_INFO,
  PROP_HAS_SERVER_INFO,
  PROP_ENDPOINTS,
  PROP_ICE_RESTART_PENDING
};

/* private structure */
struct _TpBaseMediaCallStreamPrivate
{
  TpStreamFlowState sending_state;
  TpStreamFlowState receiving_state;
  TpStreamTransportType transport;
  /* GPtrArray of owned GValueArray (dbus struct) */
  GPtrArray *local_candidates;
  gchar *username;
  gchar *password;
  /* GPtrArray of owned GValueArray (dbus struct) */
  GPtrArray *stun_servers;
  /* GPtrArray of reffed GHashTable (asv) */
  GPtrArray *relay_info;
  gboolean has_server_info;
  /* GList of reffed TpCallStreamEndpoint */
  GList *endpoints;
  gboolean ice_restart_pending;
  /* Intset of TpHandle that have requested to receive */
  TpIntset *receiving_requests;

  gboolean local_sending;
  gboolean remotely_held;
  gboolean sending_stop_requested;
  gboolean sending_failure;
  gboolean receiving_failure;
};

static GPtrArray *tp_base_media_call_stream_get_interfaces (
    TpBaseCallStream *bcs);
static gboolean tp_base_media_call_stream_request_receiving (
    TpBaseCallStream *bcs,
    TpHandle contact,
    gboolean receive,
    GError **error);
static gboolean tp_base_media_call_stream_set_sending (TpBaseCallStream *self,
    gboolean sending,
    GError **error);

static void
tp_base_media_call_stream_init (TpBaseMediaCallStream *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_MEDIA_CALL_STREAM, TpBaseMediaCallStreamPrivate);

  self->priv->local_candidates = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);
  self->priv->username = g_strdup ("");
  self->priv->password = g_strdup ("");
  self->priv->receiving_requests = tp_intset_new ();
  self->priv->sending_state = TP_STREAM_FLOW_STATE_STOPPED;
  self->priv->receiving_state = TP_STREAM_FLOW_STATE_STOPPED;

  g_signal_connect (self, "notify::remote-members",
      G_CALLBACK (tp_base_media_call_stream_update_receiving_state), NULL);
  g_signal_connect (self, "notify::channel",
      G_CALLBACK (tp_base_media_call_stream_update_receiving_state), NULL);
  g_signal_connect (self, "notify::channel",
      G_CALLBACK (tp_base_media_call_stream_update_sending_state), NULL);
}

static void
tp_base_media_call_stream_dispose (GObject *object)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (object);

  tp_clear_pointer (&self->priv->endpoints, _tp_object_list_free);

  if (G_OBJECT_CLASS (tp_base_media_call_stream_parent_class)->dispose)
    G_OBJECT_CLASS (tp_base_media_call_stream_parent_class)->dispose (object);
}

static void
tp_base_media_call_stream_finalize (GObject *object)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (object);

  tp_clear_pointer (&self->priv->local_candidates, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->stun_servers, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->relay_info, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->username, g_free);
  tp_clear_pointer (&self->priv->password, g_free);
  tp_clear_pointer (&self->priv->receiving_requests, tp_intset_destroy);

  G_OBJECT_CLASS (tp_base_media_call_stream_parent_class)->finalize (object);
}

static void
tp_base_media_call_stream_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (object);

  switch (property_id)
    {
      case PROP_SENDING_STATE:
        g_value_set_uint (value, self->priv->sending_state);
        break;
      case PROP_RECEIVING_STATE:
        g_value_set_uint (value, self->priv->receiving_state);
        break;
      case PROP_TRANSPORT:
        g_value_set_uint (value, self->priv->transport);
        break;
      case PROP_LOCAL_CANDIDATES:
        g_value_set_boxed (value, self->priv->local_candidates);
        break;
      case PROP_LOCAL_CREDENTIALS:
        {
          g_value_take_boxed (value, tp_value_array_build (2,
              G_TYPE_STRING, self->priv->username,
              G_TYPE_STRING, self->priv->password,
              G_TYPE_INVALID));
          break;
        }
      case PROP_STUN_SERVERS:
        {
          if (self->priv->stun_servers != NULL)
            g_value_set_boxed (value, self->priv->stun_servers);
          else
            g_value_take_boxed (value, g_ptr_array_new ());
          break;
        }
      case PROP_RELAY_INFO:
        {
          if (self->priv->relay_info != NULL)
            g_value_set_boxed (value, self->priv->relay_info);
          else
            g_value_take_boxed (value, g_ptr_array_new ());
          break;
        }
      case PROP_HAS_SERVER_INFO:
        g_value_set_boolean (value, self->priv->has_server_info);
        break;
      case PROP_ENDPOINTS:
        {
          GPtrArray *arr = g_ptr_array_sized_new (1);
          GList *l;

          for (l = self->priv->endpoints; l != NULL; l = g_list_next (l))
            {
              TpCallStreamEndpoint *e = l->data;

              g_ptr_array_add (arr,
                  g_strdup (tp_call_stream_endpoint_get_object_path (e)));
            }

          g_value_take_boxed (value, arr);
          break;
        }
      case PROP_ICE_RESTART_PENDING:
        g_value_set_boolean (value, self->priv->ice_restart_pending);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_media_call_stream_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (object);

  switch (property_id)
    {
      case PROP_TRANSPORT:
        self->priv->transport = g_value_get_uint (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_media_call_stream_class_init (TpBaseMediaCallStreamClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;
  TpBaseCallStreamClass *bcs_class = TP_BASE_CALL_STREAM_CLASS (klass);

  static TpDBusPropertiesMixinPropImpl stream_media_props[] = {
    { "SendingState", "sending-state", NULL },
    { "ReceivingState", "receiving-state", NULL },
    { "Transport", "transport", NULL },
    { "LocalCandidates", "local-candidates", NULL },
    { "LocalCredentials", "local-credentials", NULL },
    { "STUNServers", "stun-servers", NULL },
    { "RelayInfo", "relay-info", NULL },
    { "HasServerInfo", "has-server-info", NULL },
    { "Endpoints", "endpoints", NULL },
    { "ICERestartPending", "ice-restart-pending", NULL },
    { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpBaseMediaCallStreamPrivate));

  object_class->set_property = tp_base_media_call_stream_set_property;
  object_class->get_property = tp_base_media_call_stream_get_property;
  object_class->dispose = tp_base_media_call_stream_dispose;
  object_class->finalize = tp_base_media_call_stream_finalize;

  bcs_class->get_interfaces = tp_base_media_call_stream_get_interfaces;
  bcs_class->request_receiving = tp_base_media_call_stream_request_receiving;
  bcs_class->set_sending = tp_base_media_call_stream_set_sending;

  /**
   * TpBaseMediaCallStream:sending-state:
   *
   * The sending #TpStreamFlowState.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("sending-state", "SendingState",
      "The sending state",
      0, G_MAXUINT, TP_STREAM_FLOW_STATE_STOPPED,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SENDING_STATE,
      param_spec);

  /**
   * TpBaseMediaCallStream:receiving-state:
   *
   * The receiving #TpStreamFlowState.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("receiving-state", "ReceivingState",
      "The receiving state",
      0, G_MAXUINT, TP_STREAM_FLOW_STATE_STOPPED,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_RECEIVING_STATE,
      param_spec);

  /**
   * TpBaseMediaCallStream:transport:
   *
   * The #TpStreamTransportType of this stream.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("transport", "Transport",
      "The transport type of this stream",
      0, G_MAXUINT, TP_STREAM_TRANSPORT_TYPE_UNKNOWN,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_TRANSPORT,
      param_spec);

  /**
   * TpBaseMediaCallStream:local-candidates:
   *
   * #GPtrArray{candidate #GValueArray}
   * List of local candidates.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("local-candidates", "LocalCandidates",
      "List of local candidates",
      TP_ARRAY_TYPE_CANDIDATE_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCAL_CANDIDATES,
      param_spec);

  /**
   * TpBaseMediaCallStream:local-credentials:
   *
   * #GValueArray{username string, password string}
   * ufrag and pwd as defined by ICE.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("local-credentials", "LocalCredentials",
      "ufrag and pwd as defined by ICE",
      TP_STRUCT_TYPE_STREAM_CREDENTIALS,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCAL_CREDENTIALS,
      param_spec);

  /**
   * TpBaseMediaCallStream:stun-servers:
   *
   * #GPtrArray{stun-server #GValueArray}
   * List of STUN servers.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("stun-servers", "STUNServers",
      "List of STUN servers",
      TP_ARRAY_TYPE_SOCKET_ADDRESS_IP_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STUN_SERVERS,
      param_spec);

  /**
   * TpBaseMediaCallStream:relay-info:
   *
   * #GPtrArray{relay-info asv}
   * List of relay information.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("relay-info", "RelayInfo",
      "List of relay information",
      TP_ARRAY_TYPE_STRING_VARIANT_MAP_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_RELAY_INFO,
      param_spec);

  /**
   * TpBaseMediaCallStream:has-server-info:
   *
   * %TRUE if #TpBaseMediaCallStream:relay-info and
   * #TpBaseMediaCallStream:stun-servers have been set.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("has-server-info", "HasServerInfo",
      "True if the server information about STUN and "
      "relay servers has been retrieved",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HAS_SERVER_INFO,
      param_spec);

  /**
   * TpBaseMediaCallStream:endpoints:
   *
   * #GPtrArray{object-path string}
   * The endpoints of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("endpoints", "Endpoints",
      "The endpoints of this content",
      TP_ARRAY_TYPE_OBJECT_PATH_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ENDPOINTS,
      param_spec);

  /**
   * TpBaseMediaCallStream:ice-restart-pending:
   *
   * %TRUE when ICERestartRequested signal is emitted, and %FALSE when
   * SetCredentials is called. Useful for debugging.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("ice-restart-pending", "ICERestartPending",
      "True when ICERestartRequested signal is emitted, and False when "
      "SetCredentials is called. Useful for debugging",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ICE_RESTART_PENDING,
      param_spec);

  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA,
      tp_dbus_properties_mixin_getter_gobject_properties,
      NULL,
      stream_media_props);
}

/**
 * tp_base_media_call_stream_get_username:
 * @self: a #TpBaseMediaCallStream
 *
 * <!-- -->
 *
 * Returns: the username part of #TpBaseMediaCallStream:local-credentials
 * Since: 0.17.5
 */
const gchar *
tp_base_media_call_stream_get_username (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self), NULL);

  return self->priv->username;
}

/**
 * tp_base_media_call_stream_get_password:
 * @self: a #TpBaseMediaCallStream
 *
 * <!-- -->
 *
 * Returns: the password part of #TpBaseMediaCallStream:local-credentials
 * Since: 0.17.5
 */
const gchar *
tp_base_media_call_stream_get_password (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self), NULL);

  return self->priv->password;
}

static void
maybe_got_server_info (TpBaseMediaCallStream *self)
{
  if (self->priv->has_server_info ||
      self->priv->stun_servers == NULL ||
      self->priv->relay_info == NULL)
    return;

  DEBUG ("Got server info for stream %s",
      tp_base_call_stream_get_object_path ((TpBaseCallStream *) self));

  self->priv->has_server_info = TRUE;
  tp_svc_call_stream_interface_media_emit_server_info_retrieved (self);
}

/**
 * tp_base_media_call_stream_set_stun_servers:
 * @self: a #TpBaseMediaCallStream
 * @stun_servers: the new stun servers
 *
 * Set the STUN servers. The #GPtrArray should have a free_func defined such as
 * g_ptr_array_ref() is enough to keep the data and g_ptr_array_unref() is
 * enough to release it later.
 *
 * Note that this replaces the previously set STUN servers, it is not an
 * addition.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_set_stun_servers (TpBaseMediaCallStream *self,
    GPtrArray *stun_servers)
{
  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));
  g_return_if_fail (stun_servers != NULL);

  if (self->priv->stun_servers != NULL)
    {
      if (stun_servers->len == self->priv->stun_servers->len)
        {
          guint i;
          gboolean equal = TRUE;

          for (i = 0; i < stun_servers->len; i++)
            {
              GValueArray *gva1 = g_ptr_array_index (stun_servers, i);
              GValueArray *gva2 = g_ptr_array_index (self->priv->stun_servers,
                  i);
              gchar *ip1, *ip2;
              guint port1, port2;

              tp_value_array_unpack (gva1, 2, &ip1, &port1);
              tp_value_array_unpack (gva2, 2, &ip2, &port2);

              if (port1 != port2 || strcmp (ip1, ip2))
                {
                  equal = FALSE;
                  break;
                }
            }

          if (equal)
            {
              g_ptr_array_unref (stun_servers);
              return;
            }
        }

      g_ptr_array_unref (self->priv->stun_servers);
    }

  self->priv->stun_servers = g_ptr_array_ref (stun_servers);

  tp_svc_call_stream_interface_media_emit_stun_servers_changed (self,
      self->priv->stun_servers);

  maybe_got_server_info (self);
}

/**
 * tp_base_media_call_stream_set_relay_info:
 * @self: a #TpBaseMediaCallStream
 * @relays: the new relays info
 *
 * Set the relays info. The #GPtrArray should have a free_func defined such as
 * g_ptr_array_ref() is enough to keep the data and g_ptr_array_unref() is
 * enough to release it later.
 *
 * Note that this replaces the previously set relays, it is not an addition.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_set_relay_info (TpBaseMediaCallStream *self,
    GPtrArray *relays)
{
  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));
  g_return_if_fail (relays != NULL);

  tp_clear_pointer (&self->priv->relay_info, g_ptr_array_unref);
  self->priv->relay_info = g_ptr_array_ref (relays);

  tp_svc_call_stream_interface_media_emit_relay_info_changed (self,
      self->priv->relay_info);

  maybe_got_server_info (self);
}

/**
 * tp_base_media_call_stream_add_endpoint:
 * @self: a #TpBaseMediaCallStream
 * @endpoint: a #TpCallStreamEndpoint
 *
 * Add @endpoint to #TpBaseMediaCallStream:endpoints list, and emits
 * EndpointsChanged DBus signal.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_add_endpoint (TpBaseMediaCallStream *self,
    TpCallStreamEndpoint *endpoint)
{
  const gchar *object_path;
  GPtrArray *added;
  GPtrArray *removed;

  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));
  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (endpoint));

  _tp_call_stream_endpoint_set_stream (endpoint, self);

  object_path = tp_call_stream_endpoint_get_object_path (endpoint);
  DEBUG ("Add endpoint %s to stream %s", object_path,
      tp_base_call_stream_get_object_path ((TpBaseCallStream *) self));

  self->priv->endpoints = g_list_append (self->priv->endpoints,
      g_object_ref (endpoint));

  added = g_ptr_array_new ();
  removed = g_ptr_array_new ();
  g_ptr_array_add (added, (gpointer) object_path);

  tp_svc_call_stream_interface_media_emit_endpoints_changed (self,
      added, removed);

  g_ptr_array_unref (added);
  g_ptr_array_unref (removed);
}


/**
 * tp_base_media_call_stream_remove_endpoint:
 * @self: a #TpBaseMediaCallStream
 * @endpoint: a #TpCallStreamEndpoint
 *
 * Remove @endpoint from #TpBaseMediaCallStream:endpoints list, and emits
 * EndpointsChanged DBus signal.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_remove_endpoint (TpBaseMediaCallStream *self,
    TpCallStreamEndpoint *endpoint)
{
  const gchar *object_path;
  GPtrArray *added;
  GPtrArray *removed;

  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));
  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (endpoint));
  g_return_if_fail (g_list_find (self->priv->endpoints, endpoint) != NULL);

  object_path = tp_call_stream_endpoint_get_object_path (endpoint);
  DEBUG ("Remove endpoint %s from stream %s", object_path,
      tp_base_call_stream_get_object_path ((TpBaseCallStream *) self));

  self->priv->endpoints = g_list_remove (self->priv->endpoints,
      endpoint);

  added = g_ptr_array_new ();
  removed = g_ptr_array_new ();
  g_ptr_array_add (removed, (gpointer) object_path);

  tp_svc_call_stream_interface_media_emit_endpoints_changed (self,
      added, removed);

  g_ptr_array_unref (added);
  g_ptr_array_unref (removed);
  g_object_unref (endpoint);
}

/**
 * tp_base_media_call_stream_get_endpoints:
 * @self: a #TpBaseMediaCallStream
 *
 * Same as #TpBaseMediaCallStream:endpoints but as a #GList of
 * #TpCallStreamEndpoint.
 *
 * Returns: Borrowed #GList of #TpCallStreamEndpoint.
 * Since: 0.17.5
 */
GList *
tp_base_media_call_stream_get_endpoints (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self), NULL);

  return self->priv->endpoints;
}

static const char *
stream_flow_state_to_string (TpStreamFlowState state)
{
  const char *str = "INVALID";

  switch (state)
    {
    case TP_STREAM_FLOW_STATE_STOPPED:
      str = "STOPPED";
      break;
    case TP_STREAM_FLOW_STATE_PENDING_START:
      str = "PENDING_START";
      break;
    case TP_STREAM_FLOW_STATE_PENDING_STOP:
      str = "PENDING_STOP";
      break;
    case TP_STREAM_FLOW_STATE_STARTED:
      str = "STARTED";
      break;
    }

  return str;
}

static gboolean
ignore_state_change (TpStreamFlowState old_state,
    TpStreamFlowState new_state)
{
  if ((old_state == new_state) ||
      (new_state == TP_STREAM_FLOW_STATE_PENDING_START &&
          old_state == TP_STREAM_FLOW_STATE_STARTED) ||
      (new_state == TP_STREAM_FLOW_STATE_PENDING_STOP &&
          old_state == TP_STREAM_FLOW_STATE_STOPPED))
    return TRUE;

  return FALSE;
}

static void
set_sending_state (TpBaseMediaCallStream *self,
    TpStreamFlowState state)
{
  if (ignore_state_change (self->priv->sending_state, state))
    return;

  DEBUG ("%s => %s (path: %s)",
      stream_flow_state_to_string (self->priv->sending_state),
      stream_flow_state_to_string (state),
      tp_base_call_stream_get_object_path (TP_BASE_CALL_STREAM (self)));

  self->priv->sending_state = state;
  g_object_notify (G_OBJECT (self), "sending-state");

  tp_svc_call_stream_interface_media_emit_sending_state_changed (self, state);
}

/**
 * tp_base_media_call_stream_update_sending_state:
 * @self: a #TpBaseMediaCallStream
 *
 * Update the sending state.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_update_sending_state (TpBaseMediaCallStream *self)
{
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (
      TP_BASE_CALL_STREAM (self));
  gboolean sending = FALSE;

  if (channel == NULL)
    goto done;

  if (TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    {
      TpBaseMediaCallChannel *mediachan = TP_BASE_MEDIA_CALL_CHANNEL (channel);

      if (_tp_base_media_channel_is_held (mediachan))
        goto done;
    }

  if (!tp_base_call_channel_is_accepted (TP_BASE_CALL_CHANNEL (channel)))
    goto done;

  if (self->priv->remotely_held)
    goto done;

  if (self->priv->sending_failure)
    goto done;

  sending = self->priv->local_sending;

done:

  if (sending)
    set_sending_state (self, TP_STREAM_FLOW_STATE_PENDING_START);
  else
    set_sending_state (self, TP_STREAM_FLOW_STATE_PENDING_STOP);
}

/**
 * tp_base_media_call_stream_get_sending_state:
 * @self: a #TpBaseMediaCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseMediaCallStream:sending-state.
 * Since: 0.17.5
 */
TpStreamFlowState
tp_base_media_call_stream_get_sending_state (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self),
      TP_STREAM_FLOW_STATE_STOPPED);

  return self->priv->sending_state;
}

/**
 * tp_base_media_call_stream_set_local_sending:
 * @self: a #TpBaseMediaCallStream
 * @sending: whether or not we are sending
 *
 * Set local sending state.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_set_local_sending (TpBaseMediaCallStream *self,
    gboolean sending)
{
  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));

  if (sending == self->priv->local_sending)
    return;

  self->priv->local_sending = sending;

  tp_base_media_call_stream_update_sending_state (self);
}

/**
 * tp_base_media_call_stream_get_local_sending:
 * @self: a #TpBaseMediaCallStream
 *
 * Gets the local sending state
 *
 * Returns: The local sending state
 * Since: 0.17.7
 */
gboolean
tp_base_media_call_stream_get_local_sending (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self), FALSE);

  return self->priv->local_sending;
}

void
_tp_base_media_call_stream_set_remotely_held (TpBaseMediaCallStream *self,
    gboolean remotely_held)
{
  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self));

  if (remotely_held == self->priv->remotely_held)
    return;

  self->priv->remotely_held = remotely_held;

  tp_base_media_call_stream_update_sending_state (self);
}

static void
set_receiving_state (TpBaseMediaCallStream *self,
    TpStreamFlowState state)
{
  if (ignore_state_change (self->priv->receiving_state, state))
    return;

  DEBUG ("%s => %s (path: %s)",
      stream_flow_state_to_string (self->priv->receiving_state),
      stream_flow_state_to_string (state),
      tp_base_call_stream_get_object_path (TP_BASE_CALL_STREAM (self)));

  self->priv->receiving_state = state;
  g_object_notify (G_OBJECT (self), "receiving-state");

  tp_svc_call_stream_interface_media_emit_receiving_state_changed (self, state);
}

/**
 * tp_base_media_call_stream_update_receiving_state:
 * @self: a #TpBaseMediaCallStream
 *
 * Update the receiving state.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_stream_update_receiving_state (TpBaseMediaCallStream *self)
{
  TpBaseCallStream *bcs = TP_BASE_CALL_STREAM (self);
  GHashTable *remote_members = _tp_base_call_stream_get_remote_members (bcs);
  GHashTableIter iter;
  gpointer key, value;
  gboolean remote_sending = FALSE;
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (bcs);

  if (channel == NULL || !_tp_base_call_channel_is_locally_accepted (channel))
    goto done;

  if (self->priv->receiving_failure)
    goto done;

  if (TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    {
      TpBaseMediaCallChannel *mediachan = TP_BASE_MEDIA_CALL_CHANNEL (channel);

      if (_tp_base_media_channel_is_held (mediachan))
        goto done;
    }

  g_hash_table_iter_init (&iter, remote_members);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpSendingState state = GPOINTER_TO_UINT (value);

      switch (state)
        {
        case TP_SENDING_STATE_SENDING:
        case TP_SENDING_STATE_PENDING_SEND:
          remote_sending = TRUE;
          break;
        case TP_SENDING_STATE_PENDING_STOP_SENDING:
        case TP_SENDING_STATE_NONE:
          break;
        default:
          g_assert_not_reached ();
        }
      if (remote_sending)
        break;
    }

done:

  if (remote_sending)
    set_receiving_state (self, TP_STREAM_FLOW_STATE_PENDING_START);
  else
    set_receiving_state (self, TP_STREAM_FLOW_STATE_PENDING_STOP);
}

/**
 * tp_base_media_call_stream_get_receiving_state:
 * @self: a #TpBaseMediaCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseMediaCallStream:receiving-state.
 * Since: 0.17.5
 */
TpStreamFlowState
tp_base_media_call_stream_get_receiving_state (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self),
      TP_STREAM_FLOW_STATE_STOPPED);

  return self->priv->receiving_state;
}

/**
 * tp_base_media_call_stream_get_local_candidates:
 * @self: a #TpBaseMediaCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseMediaCallStream:local-candidates as a #GtrArray
 * Since: 0.17.5
 */
GPtrArray *
tp_base_media_call_stream_get_local_candidates (TpBaseMediaCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (self), NULL);

  return self->priv->local_candidates;
}


/* TpBaseCallStreamClass virtual methods implementation */

static gboolean
tp_base_media_call_stream_set_sending (TpBaseCallStream *bcs,
    gboolean sending,
    GError **error)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (bcs);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);

  if (sending)
    {
      if (klass->set_sending != NULL &&
          !klass->set_sending (self, sending, error))
        return FALSE;
    }
  else
   {
     tp_base_media_call_stream_set_local_sending (self, FALSE);

     /* Already stopped, lets call the callback directly */
     if (self->priv->sending_state == TP_STREAM_FLOW_STATE_STOPPED &&
         klass->set_sending != NULL)
       return klass->set_sending (self, sending, error);
     else
       self->priv->sending_stop_requested = TRUE;
   }

  return TRUE;
}

static GPtrArray *
tp_base_media_call_stream_get_interfaces (TpBaseCallStream *bcs)
{
  GPtrArray *interfaces;

  interfaces = TP_BASE_CALL_STREAM_CLASS (
      tp_base_media_call_stream_parent_class)->get_interfaces (bcs);

  g_ptr_array_add (interfaces, TP_IFACE_CALL_STREAM_INTERFACE_MEDIA);

  return interfaces;
}

static gboolean
tp_base_media_call_stream_request_receiving (TpBaseCallStream *bcs,
    TpHandle contact,
    gboolean receive,
    GError **error)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (bcs);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (bcs);

  if (receive)
    {
      tp_base_call_stream_update_remote_sending_state (bcs, contact,
          TP_SENDING_STATE_PENDING_SEND,
          tp_base_channel_get_self_handle (TP_BASE_CHANNEL (channel)),
          TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
          "User asked the remote side to start sending");

      if (self->priv->receiving_state == TP_STREAM_FLOW_STATE_STARTED)
        {
          if (klass->request_receiving != NULL)
            {
              klass->request_receiving (self, contact, TRUE);
              return TRUE;
            }
        }

      tp_intset_add (self->priv->receiving_requests, contact);

      tp_base_media_call_stream_update_receiving_state (self);
    }
  else
    {
      tp_base_call_stream_update_remote_sending_state (bcs, contact,
          TP_SENDING_STATE_PENDING_STOP_SENDING,
          tp_base_channel_get_self_handle (TP_BASE_CHANNEL (channel)),
          TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
          "User asked the remote side to stop sending");

      tp_intset_remove (self->priv->receiving_requests, contact);

      if (klass->request_receiving != NULL)
        klass->request_receiving (self, contact, FALSE);
    }

  return TRUE;
}

/* DBus method implementation */

static gboolean
correct_state_transition (TpStreamFlowState old_state,
    TpStreamFlowState new_state)
{
  switch (new_state)
    {
      case TP_STREAM_FLOW_STATE_STARTED:
        return (old_state == TP_STREAM_FLOW_STATE_PENDING_START);
      case TP_STREAM_FLOW_STATE_STOPPED:
        return (old_state == TP_STREAM_FLOW_STATE_PENDING_STOP);
      default:
        return FALSE;
    }
}

static void
tp_base_media_call_stream_complete_sending_state_change (
    TpSvcCallStreamInterfaceMedia *iface,
    TpStreamFlowState state,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (
      TP_BASE_CALL_STREAM (self));

  if (!correct_state_transition (self->priv->sending_state, state))
    {
      GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid sending state transition" };
      dbus_g_method_return_error (context, &e);
      return;
    }

  self->priv->sending_state = state;

  if (channel != NULL && TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    _tp_base_media_call_channel_streams_sending_state_changed (
        TP_BASE_MEDIA_CALL_CHANNEL (channel), TRUE);

  if (state == TP_STREAM_FLOW_STATE_STOPPED &&
      klass->set_sending != NULL &&
      self->priv->sending_stop_requested)
    klass->set_sending (self, FALSE, NULL);

  self->priv->sending_stop_requested = FALSE;

  tp_svc_call_stream_interface_media_emit_sending_state_changed (self, state);
  tp_svc_call_stream_interface_media_return_from_complete_sending_state_change
      (context);
}

static void
tp_base_media_call_stream_report_sending_failure (
    TpSvcCallStreamInterfaceMedia *iface,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  TpStreamFlowState old_state = self->priv->sending_state;
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (
      TP_BASE_CALL_STREAM (self));
  gboolean was_held = FALSE;

  if (self->priv->sending_state == TP_STREAM_FLOW_STATE_STOPPED)
    goto done;

  self->priv->sending_failure = TRUE;
  self->priv->sending_stop_requested = FALSE;
  self->priv->sending_state = TP_STREAM_FLOW_STATE_STOPPED;

  if (channel != NULL && TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    {
      was_held = _tp_base_media_call_channel_streams_sending_state_changed (
          TP_BASE_MEDIA_CALL_CHANNEL (channel), FALSE);
    }

  if (!was_held)
    {
      self->priv->local_sending = FALSE;
      if (klass->report_sending_failure != NULL)
        klass->report_sending_failure (self, old_state, reason, dbus_reason,
            message);
    }

  g_object_notify (G_OBJECT (self), "sending-state");
  tp_svc_call_stream_interface_media_emit_sending_state_changed (self,
      self->priv->sending_state);

  self->priv->sending_failure = FALSE;

done:
  tp_svc_call_stream_interface_media_return_from_report_sending_failure (
      context);
}

static void
tp_base_media_call_stream_complete_receiving_state_change (
    TpSvcCallStreamInterfaceMedia *iface,
    TpStreamFlowState state,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (
      TP_BASE_CALL_STREAM (self));

  if (!correct_state_transition (self->priv->receiving_state, state))
    {
      GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid receiving state transition" };
      dbus_g_method_return_error (context, &e);
      return;
    }

  self->priv->receiving_state = state;
  g_object_notify (G_OBJECT (self), "receiving-state");

  if (channel != NULL && TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    _tp_base_media_call_channel_streams_receiving_state_changed (
        TP_BASE_MEDIA_CALL_CHANNEL (channel), TRUE);

  if (state == TP_STREAM_FLOW_STATE_STARTED)
    {
      TpIntsetFastIter iter;
      TpHandle contact;

      tp_intset_fast_iter_init (&iter, self->priv->receiving_requests);
      while (tp_intset_fast_iter_next (&iter, &contact))
        {
          if (klass->request_receiving != NULL)
            klass->request_receiving (self, contact, TRUE);
        }

      tp_intset_clear (self->priv->receiving_requests);
    }

  tp_svc_call_stream_interface_media_emit_receiving_state_changed (self, state);
  tp_svc_call_stream_interface_media_return_from_complete_receiving_state_change
      (context);
}

static void
tp_base_media_call_stream_report_receiving_failure (
    TpSvcCallStreamInterfaceMedia *iface,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  TpStreamFlowState old_state = self->priv->receiving_state;
  TpBaseCallChannel *channel = _tp_base_call_stream_get_channel (
      TP_BASE_CALL_STREAM (self));
  gboolean was_held = FALSE;

  /* Clear all receving requests, we can't receive */
  tp_intset_clear (self->priv->receiving_requests);

  if (self->priv->receiving_state == TP_STREAM_FLOW_STATE_STOPPED)
    goto done;

  self->priv->receiving_state = TP_STREAM_FLOW_STATE_STOPPED;
  self->priv->receiving_failure = TRUE;
  g_object_notify (G_OBJECT (self), "receiving-state");

  if (channel != NULL && TP_IS_BASE_MEDIA_CALL_CHANNEL (channel))
    was_held =
        _tp_base_media_call_channel_streams_receiving_state_changed (
            TP_BASE_MEDIA_CALL_CHANNEL (channel), FALSE);

  if (klass->report_receiving_failure != NULL && !was_held)
    klass->report_receiving_failure (self, old_state,
        reason, dbus_reason, message);

  tp_svc_call_stream_interface_media_emit_receiving_state_changed (self,
      self->priv->receiving_state);

  self->priv->receiving_failure = FALSE;

done:
  tp_svc_call_stream_interface_media_return_from_report_receiving_failure (
      context);
}

static void
tp_base_media_call_stream_set_credentials (TpSvcCallStreamInterfaceMedia *iface,
    const gchar *username,
    const gchar *password,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);

  g_free (self->priv->username);
  g_free (self->priv->password);
  self->priv->username = g_strdup (username);
  self->priv->password = g_strdup (password);

  tp_clear_pointer (&self->priv->local_candidates, g_ptr_array_unref);
  self->priv->local_candidates = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);

  g_object_notify (G_OBJECT (self), "local-candidates");
  g_object_notify (G_OBJECT (self), "local-credentials");

  tp_svc_call_stream_interface_media_emit_local_credentials_changed (self,
      username, password);

  tp_svc_call_stream_interface_media_return_from_set_credentials (context);
}

static void
tp_base_media_call_stream_add_candidates (TpSvcCallStreamInterfaceMedia *iface,
    const GPtrArray *candidates,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  GPtrArray *accepted_candidates = NULL;
  guint i;
  GError *error = NULL;

  if (klass->add_local_candidates == NULL)
    {
      GError e = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Connection Manager did not implement "
          "TpBaseMediaCallStream::add_local_candidates vmethod" };
      dbus_g_method_return_error (context, &e);
      return;
    }

  DEBUG ("Adding %d candidates to stream %s", candidates->len,
      tp_base_call_stream_get_object_path ((TpBaseCallStream *) self));

  accepted_candidates = klass->add_local_candidates (self, candidates, &error);
  if (accepted_candidates == NULL)
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  for (i = 0; i < accepted_candidates->len; i++)
    {
      GValueArray *c = g_ptr_array_index (accepted_candidates, i);

      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      g_ptr_array_add (self->priv->local_candidates,
          g_value_array_copy (c));
      G_GNUC_END_IGNORE_DEPRECATIONS
    }

  tp_svc_call_stream_interface_media_emit_local_candidates_added (self,
      accepted_candidates);
  tp_svc_call_stream_interface_media_return_from_add_candidates (context);

  g_ptr_array_unref (accepted_candidates);
}

static void
tp_base_media_call_stream_finish_initial_candidates (
    TpSvcCallStreamInterfaceMedia *iface,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseMediaCallStreamClass *klass =
      TP_BASE_MEDIA_CALL_STREAM_GET_CLASS (self);
  GError *error = NULL;

  if (klass->finish_initial_candidates != NULL)
    if (!klass->finish_initial_candidates (self, &error))
      {
        dbus_g_method_return_error (context, error);
        g_clear_error (&error);
        return;
      }

  tp_svc_call_stream_interface_media_return_from_finish_initial_candidates (
      context);
}

static void
tp_base_media_call_stream_fail (TpSvcCallStreamInterfaceMedia *iface,
    const GValueArray *reason_array,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallStream *self = TP_BASE_MEDIA_CALL_STREAM (iface);
  TpBaseCallStream *base = TP_BASE_CALL_STREAM (self);
  TpBaseCallChannel *channel;
  TpBaseCallContent *content;

  channel = _tp_base_call_stream_get_channel (base);
  content = _tp_base_call_stream_get_content (base);

  _tp_base_call_content_remove_stream_internal (content, base, reason_array);

  /* If it was the last stream, remove the content */
  if (tp_base_call_content_get_streams (content) == NULL)
    {
      _tp_base_call_channel_remove_content_internal (channel, content,
          reason_array);
    }

  tp_svc_call_stream_interface_media_return_from_fail (context);
}

static void
call_stream_media_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcCallStreamInterfaceMediaClass *klass =
      (TpSvcCallStreamInterfaceMediaClass *) g_iface;

#define IMPLEMENT(x) tp_svc_call_stream_interface_media_implement_##x (\
    klass, tp_base_media_call_stream_##x)
  IMPLEMENT(complete_sending_state_change);
  IMPLEMENT(report_sending_failure);
  IMPLEMENT(complete_receiving_state_change);
  IMPLEMENT(report_receiving_failure);
  IMPLEMENT(set_credentials);
  IMPLEMENT(add_candidates);
  IMPLEMENT(finish_initial_candidates);
  IMPLEMENT(fail);
#undef IMPLEMENT
}
