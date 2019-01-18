/*
 * call-stream-endpoint.c - Source for TpCallStreamEndpoint
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
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
 * SECTION:call-stream-endpoint
 * @title: TpCallStreamEndpoint
 * @short_description: class for #TpSvcCallStreamEndpoint implementations
 * @see_also: #TpBaseMediaCallStream
 *
 * This class makes it easier to write #TpSvcCallStreamEndpoint
 * implementations by implementing its properties and methods.
 *
 * Since: 0.17.5
 */

/**
 * TpCallStreamEndpoint:
 *
 * A class for call stream endpoint implementations
 *
 * Since: 0.17.5
 */

/**
 * TpCallStreamEndpointClass:
 *
 * The class structure for #TpCallStreamEndpoint
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "call-stream-endpoint.h"

#include <string.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-media-call-channel.h"
#include "telepathy-glib/base-media-call-stream.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/dbus-properties-mixin.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/enums.h"
#include "telepathy-glib/errors.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/util.h"
#include "telepathy-glib/util-internal.h"

static void call_stream_endpoint_iface_init (gpointer, gpointer);

G_DEFINE_TYPE_WITH_CODE(TpCallStreamEndpoint,
  tp_call_stream_endpoint,
  G_TYPE_OBJECT,
  G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_STREAM_ENDPOINT,
      call_stream_endpoint_iface_init);
   G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
      tp_dbus_properties_mixin_iface_init);
);

/* properties */
enum
{
  PROP_OBJECT_PATH = 1,
  PROP_DBUS_DAEMON,

  PROP_REMOTE_CREDENTIALS,
  PROP_REMOTE_CANDIDATES,
  PROP_SELECTED_CANDIDATE_PAIRS,
  PROP_ENDPOINT_STATE,
  PROP_TRANSPORT,
  PROP_CONTROLLING,
  PROP_IS_ICE_LITE
};

enum /* signals */
{
  CANDIDATE_SELECTED,
  CANDIDATE_ACCEPTED,
  CANDIDATE_REJECTED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

struct _TpCallStreamEndpointPrivate
{
  TpDBusDaemon *dbus_daemon;
  gchar *object_path;

  gchar *username;
  gchar *password;
  /* GPtrArray of owned #GValueArray (dbus struct) */
  GPtrArray *remote_candidates;
  /* GPtrArray of owned #GValueArray (dbus struct) */
  GPtrArray *selected_candidate_pairs;
  /* TpStreamComponent -> TpStreamEndpointState map */
  GHashTable *endpoint_state;
  TpStreamTransportType transport;
  gboolean controlling;
  gboolean is_ice_lite;

  /* borrowed */
  TpBaseMediaCallStream *stream;
};

static void
tp_call_stream_endpoint_init (TpCallStreamEndpoint *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_CALL_STREAM_ENDPOINT, TpCallStreamEndpointPrivate);

  self->priv->username = g_strdup ("");
  self->priv->password = g_strdup ("");
  self->priv->remote_candidates = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);
  self->priv->selected_candidate_pairs = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);
  self->priv->endpoint_state = g_hash_table_new (NULL, NULL);
}

static void
tp_call_stream_endpoint_constructed (GObject *obj)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (obj);

  /* register object on the bus */
  DEBUG ("Registering %s", self->priv->object_path);
  tp_dbus_daemon_register_object (self->priv->dbus_daemon,
      self->priv->object_path, obj);

  if (G_OBJECT_CLASS (tp_call_stream_endpoint_parent_class)->constructed != NULL)
    G_OBJECT_CLASS (tp_call_stream_endpoint_parent_class)->constructed (obj);
}

static void
tp_call_stream_endpoint_dispose (GObject *object)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (object);

  tp_dbus_daemon_unregister_object (self->priv->dbus_daemon, G_OBJECT (self));

  g_clear_object (&self->priv->dbus_daemon);

  if (G_OBJECT_CLASS (tp_call_stream_endpoint_parent_class)->dispose)
    G_OBJECT_CLASS (tp_call_stream_endpoint_parent_class)->dispose (object);
}

static void
tp_call_stream_endpoint_finalize (GObject *object)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (object);

  tp_clear_pointer (&self->priv->object_path, g_free);
  tp_clear_pointer (&self->priv->username, g_free);
  tp_clear_pointer (&self->priv->password, g_free);
  tp_clear_pointer (&self->priv->remote_candidates, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->selected_candidate_pairs, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->endpoint_state, g_hash_table_unref);

  G_OBJECT_CLASS (tp_call_stream_endpoint_parent_class)->finalize (object);
}

static void
tp_call_stream_endpoint_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (object);

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        g_value_set_string (value, self->priv->object_path);
        break;
      case PROP_DBUS_DAEMON:
        g_value_set_object (value, self->priv->dbus_daemon);
        break;
      case PROP_REMOTE_CREDENTIALS:
        {
          GValueArray *remote_credentials;

          remote_credentials = tp_value_array_build (2,
              G_TYPE_STRING, self->priv->username,
              G_TYPE_STRING, self->priv->password,
              G_TYPE_INVALID);
          g_value_take_boxed (value, remote_credentials);
          break;
        }
      case PROP_REMOTE_CANDIDATES:
        g_value_set_boxed (value, self->priv->remote_candidates);
        break;
      case PROP_SELECTED_CANDIDATE_PAIRS:
        g_value_set_boxed (value, self->priv->selected_candidate_pairs);
        break;
      case PROP_ENDPOINT_STATE:
        g_value_set_boxed (value, self->priv->endpoint_state);
        break;
      case PROP_TRANSPORT:
        g_value_set_uint (value, self->priv->transport);
        break;
      case PROP_CONTROLLING:
        g_value_set_boolean (value, self->priv->controlling);
        break;
      case PROP_IS_ICE_LITE:
        g_value_set_boolean (value, self->priv->is_ice_lite);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_stream_endpoint_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (object);

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        g_assert (self->priv->object_path == NULL);   /* construct-only */
        self->priv->object_path = g_value_dup_string (value);
        break;
      case PROP_DBUS_DAEMON:
        g_assert (self->priv->dbus_daemon == NULL);   /* construct-only */
        self->priv->dbus_daemon = g_value_dup_object (value);
        break;
      case PROP_TRANSPORT:
        self->priv->transport = g_value_get_uint (value);
        break;
      case PROP_IS_ICE_LITE:
        self->priv->is_ice_lite = g_value_get_boolean (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_stream_endpoint_class_init (TpCallStreamEndpointClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl endpoint_props[] = {
    { "RemoteCredentials", "remote-credentials", NULL },
    { "RemoteCandidates", "remote-candidates", NULL },
    { "SelectedCandidatePairs", "selected-candidate-pairs", NULL },
    { "EndpointState", "endpoint-state", NULL },
    { "Transport", "transport", NULL },
    { "Controlling", "controlling", NULL },
    { "IsICELite", "is-ice-lite", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_interfaces[] = {
      { TP_IFACE_CALL_STREAM_ENDPOINT,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        endpoint_props,
      },
      { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpCallStreamEndpointPrivate));

  object_class->dispose = tp_call_stream_endpoint_dispose;
  object_class->finalize = tp_call_stream_endpoint_finalize;
  object_class->constructed = tp_call_stream_endpoint_constructed;
  object_class->set_property = tp_call_stream_endpoint_set_property;
  object_class->get_property = tp_call_stream_endpoint_get_property;

  /**
   * TpCallStreamEndpoint:object-path:
   *
   * The D-Bus object path used for this object on the bus.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("object-path", "D-Bus object path",
      "The D-Bus object path used for this "
      "object on the bus.",
      NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_OBJECT_PATH, param_spec);

  /**
   * TpCallStreamEndpoint:dbus-daemon:
   *
   * The connection to the DBus daemon owning the CM.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("dbus-daemon",
      "The DBus daemon connection",
      "The connection to the DBus daemon owning the CM",
      TP_TYPE_DBUS_DAEMON,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON, param_spec);

  /**
   * TpCallStreamEndpoint:remote-credentials:
   *
   * #GValueArray{username string, password string}
   * The remote credentials of this endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("remote-credentials",
      "RemoteCredentials",
      "The remote credentials of this endpoint",
      TP_STRUCT_TYPE_STREAM_CREDENTIALS,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_CREDENTIALS,
      param_spec);

  /**
   * TpCallStreamEndpoint:remote-candidates:
   *
   * #GPtrArray{candidate #GValueArray}
   * The remote candidates of this endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("remote-candidates",
      "RemoteCandidates",
      "The remote candidates of this endpoint",
      TP_ARRAY_TYPE_CANDIDATE_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_CANDIDATES,
      param_spec);

  /**
   * TpCallStreamEndpoint:selected-candidate-pairs:
   *
   * #GPtrArray{local-candidate #GValueArray, remote-candidate #GValueArray}
   * The candidate pairs selected for this endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("selected-candidate-pairs",
      "SelectedCandidatePairs",
      "The candidate pairs selected for this endpoint",
      TP_ARRAY_TYPE_CANDIDATE_PAIR_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SELECTED_CANDIDATE_PAIRS,
      param_spec);

  /**
   * TpCallStreamEndpoint:endpoint-state:
   *
   * #GHashTable{#TpStreamComponent -> #TpStreamEndpointState}
   * The state of this endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("endpoint-state", "EndpointState",
      "The state of this endpoint.",
      TP_HASH_TYPE_COMPONENT_STATE_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ENDPOINT_STATE,
      param_spec);

  /**
   * TpCallStreamEndpoint:transport:
   *
   * The #TpStreamTransportType for the content of this endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("transport",
      "Transport",
      "The transport type for the content of this endpoint.",
      0, G_MAXUINT, TP_STREAM_TRANSPORT_TYPE_UNKNOWN,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_TRANSPORT, param_spec);

  /**
   * TpCallStreamEndpoint:controlling:
   *
   * Whether or not the local side is taking the controlling role.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("controlling",
      "Controlling",
      "The local side is taking the controlling role.",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTROLLING, param_spec);

  /**
   * TpCallStreamEndpoint:is-ice-lite:
   *
   * Whether or not the Remote side is an ICE Lite endpoint.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("is-ice-lite",
      "IsICELite",
      "The Remote side is an ICE Lite endpoint.",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_IS_ICE_LITE, param_spec);

  klass->dbus_props_class.interfaces = prop_interfaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpCallStreamEndpointClass, dbus_props_class));

  /**
   * TpCallStreamEndpoint::candidate-selected:
   * @self: the #TpCallStreamEndpoint
   * @local_candidate: the local candidate
   * @remote_candidate: the remote candidate
   *
   * The ::candidate-selected signal is emitted whenever
   * SetSelectedCandidatePair DBus method has been called on this object.
   *
   * Since: 0.17.5
   */
  _signals[CANDIDATE_SELECTED] = g_signal_new ("candidate-selected",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, TP_STRUCT_TYPE_CANDIDATE, TP_STRUCT_TYPE_CANDIDATE);

  /**
   * TpCallStreamEndpoint::candidate-accepted:
   * @self: the #TpCallStreamEndpoint
   * @local_candidate: the local candidate
   * @remote_candidate: the remote candidate
   *
   * The ::candidate-accepted signal is emitted whenever
   * AcceptSelectedCandidatePair DBus method has been called on this object.
   *
   * Since: 0.17.5
   */
  _signals[CANDIDATE_ACCEPTED] = g_signal_new ("candidate-accepted",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, TP_STRUCT_TYPE_CANDIDATE, TP_STRUCT_TYPE_CANDIDATE);

  /**
   * TpCallStreamEndpoint::candidate-rejected:
   * @self: the #TpCallStreamEndpoint
   * @local_candidate: the local candidate
   * @remote_candidate: the remote candidate
   *
   * The ::candidate-rejected signal is emitted whenever
   * RejectSelectedCandidatePair DBus method has been called on this object.
   *
   * Since: 0.17.5
   */
  _signals[CANDIDATE_REJECTED] = g_signal_new ("candidate-rejected",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, TP_STRUCT_TYPE_CANDIDATE, TP_STRUCT_TYPE_CANDIDATE);
}

/**
 * tp_call_stream_endpoint_new:
 * @dbus_daemon: value of #TpCallStreamEndpoint:dbus-daemon property
 * @object_path: value of #TpCallStreamEndpoint:object-path property
 * @transport: value of #TpCallStreamEndpoint:transport property
 * @is_ice_lite: value of #TpCallStreamEndpoint:is_ice_lite property
 *
 * Create a new #TpCallStreamEndpoint object. It is registered on the bus
 * at construction, and is unregistered at dispose.
 *
 * Returns: a new #TpCallStreamEndpoint.
 * Since: 0.17.5
 */
TpCallStreamEndpoint *
tp_call_stream_endpoint_new (TpDBusDaemon *dbus_daemon,
    const gchar *object_path,
    TpStreamTransportType transport,
    gboolean is_ice_lite)
{
  g_return_val_if_fail (TP_IS_DBUS_DAEMON (dbus_daemon), NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  return g_object_new (TP_TYPE_CALL_STREAM_ENDPOINT,
      "dbus-daemon", dbus_daemon,
      "object-path", object_path,
      "transport", transport,
      "is-ice-lite", is_ice_lite,
      NULL);
}

/**
 * tp_call_stream_endpoint_get_object_path:
 * @self: a #TpCallStreamEndpoint
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallStreamEndpoint:object-path
 * Since: 0.17.5
 */
const gchar *
tp_call_stream_endpoint_get_object_path (TpCallStreamEndpoint *self)
{
  g_return_val_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self), NULL);

  return self->priv->object_path;
}

/**
 * tp_call_stream_endpoint_get_state:
 * @self: a #TpCallStreamEndpoint
 * @component: a #TpStreamComponent
 *
 * <!-- -->
 *
 * Returns: the state of @self's @component
 * Since: 0.17.5
 */
TpStreamEndpointState
tp_call_stream_endpoint_get_state (TpCallStreamEndpoint *self,
    TpStreamComponent component)
{
  g_return_val_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self),
      TP_STREAM_ENDPOINT_STATE_FAILED);

  return GPOINTER_TO_UINT (g_hash_table_lookup (self->priv->endpoint_state,
      GUINT_TO_POINTER (component)));
}

/**
 * tp_call_stream_endpoint_add_new_candidates:
 * @self: a #TpCallStreamEndpoint
 * @candidates: #GPtrArray of #GValueArray defining the candidates to add
 *
 * Add @candidates to the #TpCallStreamEndpoint:remote-candidates property.
 * See Also: tp_call_stream_endpoint_add_new_candidate().
 *
 * Since: 0.17.5
 */
void
tp_call_stream_endpoint_add_new_candidates (TpCallStreamEndpoint *self,
    const GPtrArray *candidates)
{
  guint i;

  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self));

  if (candidates == NULL || candidates->len == 0)
    return;

  DEBUG ("Add %d candidates to endpoint %s",
      candidates->len, self->priv->object_path);

  for (i = 0; i < candidates->len; i++)
    {
      GValueArray *c = g_ptr_array_index (candidates, i);

      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      g_ptr_array_add (self->priv->remote_candidates,
          g_value_array_copy (c));
      G_GNUC_END_IGNORE_DEPRECATIONS
    }

  tp_svc_call_stream_endpoint_emit_remote_candidates_added (self,
      candidates);
}

/**
 * tp_call_stream_endpoint_add_new_candidate:
 * @self: a #TpCallStreamEndpoint
 * @component: a #TpStreamComponent
 * @address: an IP address
 * @port: a port number
 * @info_hash: string -> #GValue mapping for extra info
 *
 * Add a candidate to the #TpCallStreamEndpoint:remote-candidates property.
 * See Also: tp_call_stream_endpoint_add_new_candidates().
 *
 * Since: 0.17.5
 */
void
tp_call_stream_endpoint_add_new_candidate (TpCallStreamEndpoint *self,
    TpStreamComponent component,
    const gchar *address,
    guint port,
    const GHashTable *info_hash)
{
  GPtrArray *candidates;
  GValueArray *c;

  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self));
  g_return_if_fail (address != NULL);
  g_return_if_fail (port < 65536);
  g_return_if_fail (info_hash != NULL);

  DEBUG ("Add one candidates to endpoint %s", self->priv->object_path);

  c = tp_value_array_build (4,
      G_TYPE_UINT, component,
      G_TYPE_STRING, address,
      G_TYPE_UINT, port,
      TP_HASH_TYPE_CANDIDATE_INFO, info_hash,
      G_TYPE_INVALID);

  g_ptr_array_add (self->priv->remote_candidates, c);

  candidates = g_ptr_array_new ();
  g_ptr_array_add (candidates, c);
  tp_svc_call_stream_endpoint_emit_remote_candidates_added (self,
      candidates);
  g_ptr_array_unref (candidates);
}

/**
 * tp_call_stream_endpoint_set_remote_credentials:
 * @self: a #TpCallStreamEndpoint
 * @username: the username
 * @password: the password
 *
 * Set the username and password to use for @self's crendentials.
 *
 * Since: 0.17.5
 */
void
tp_call_stream_endpoint_set_remote_credentials (TpCallStreamEndpoint *self,
    const gchar *username,
    const gchar *password)
{
  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self));

  if (!tp_strdiff (self->priv->username, username) &&
      !tp_strdiff (self->priv->password, password))
    return;

  g_free (self->priv->username);
  g_free (self->priv->password);

  self->priv->username = g_strdup (username);
  self->priv->password = g_strdup (password);

  tp_svc_call_stream_endpoint_emit_remote_credentials_set (self, username,
      password);
}

static gboolean
validate_candidate (const GValueArray *candidate,
    GError **error)
{
  const GValue *value;

  if (candidate->n_values != 4)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "A candidate should have 4 values, got %d", candidate->n_values);
      return FALSE;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  value = g_value_array_get_nth ((GValueArray *) candidate, 0);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (g_value_get_uint (value) >= TP_NUM_STREAM_COMPONENTS)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid component id: %d", g_value_get_uint (value));
      return FALSE;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  value = g_value_array_get_nth ((GValueArray *) candidate, 1);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (tp_str_empty (g_value_get_string (value)))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid address: %s", g_value_get_string (value));
      return FALSE;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  value = g_value_array_get_nth ((GValueArray *) candidate, 2);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (g_value_get_uint (value) > 65535)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid port: %d", g_value_get_uint (value));
      return FALSE;
    }

  return TRUE;
}

static TpStreamComponent
get_candidate_component (const GValueArray *candidate)
{
  GValue *component_value;

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  component_value = g_value_array_get_nth ((GValueArray *) candidate, 0);
  G_GNUC_END_IGNORE_DEPRECATIONS

  return g_value_get_uint (component_value);
}

static gboolean
common_checks (TpCallStreamEndpoint *self,
    const GValueArray *local_candidate,
    const GValueArray *remote_candidate,
    GError **error)
{
  if (!validate_candidate (local_candidate, error))
    return FALSE;
  if (!validate_candidate (remote_candidate, error))
    return FALSE;

  if (get_candidate_component (local_candidate) !=
      get_candidate_component (remote_candidate))
    {
      g_set_error_literal (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Component must be the same in local and remote candidate");
      return FALSE;
    }

  if (!self->priv->controlling)
    {
      g_set_error_literal (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Only controlling side can call SetSelectedCandidatePair");
      return FALSE;
    }

  return TRUE;
}

static void
call_stream_endpoint_set_selected_candidate_pair (TpSvcCallStreamEndpoint *iface,
    const GValueArray *local_candidate,
    const GValueArray *remote_candidate,
    DBusGMethodInvocation *context)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (iface);
  TpStreamComponent component;
  GValueArray *pair;
  guint i;
  GError *error = NULL;

  if (!common_checks (self, local_candidate, remote_candidate, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  component = get_candidate_component (local_candidate);

  DEBUG ("Candidate selected for component %d for endpoint %s", component,
      self->priv->object_path);

  /* Remove the pair for that component if we already had one */
  for (i = 0; i < self->priv->selected_candidate_pairs->len; i++)
    {
      GValueArray *this_pair;
      TpStreamComponent this_component;

      this_pair = g_ptr_array_index (self->priv->selected_candidate_pairs, i);
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      this_component = get_candidate_component (
          g_value_get_boxed (g_value_array_get_nth (this_pair, 0)));
      G_GNUC_END_IGNORE_DEPRECATIONS

      if (this_component == component)
        {
          g_ptr_array_remove_index (self->priv->selected_candidate_pairs, i);
          break;
        }
    }

  pair = tp_value_array_build (2,
      TP_STRUCT_TYPE_CANDIDATE, local_candidate,
      TP_STRUCT_TYPE_CANDIDATE, remote_candidate,
      G_TYPE_INVALID);
  g_ptr_array_add (self->priv->selected_candidate_pairs, pair);

  tp_svc_call_stream_endpoint_emit_candidate_pair_selected (self,
      local_candidate, remote_candidate);

  g_signal_emit (self, _signals[CANDIDATE_SELECTED], 0,
      local_candidate, remote_candidate);

  tp_svc_call_stream_endpoint_return_from_set_selected_candidate_pair (context);
}

static void
call_stream_endpoint_set_endpoint_state (TpSvcCallStreamEndpoint *iface,
    TpStreamComponent component,
    TpStreamEndpointState state,
    DBusGMethodInvocation *context)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (iface);

  if (component >= TP_NUM_STREAM_COMPONENTS)
    {
      GError *error = g_error_new (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Stream component %d is out of the valid range.", state);
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  if (state >= TP_NUM_STREAM_ENDPOINT_STATES)
    {
      GError *error = g_error_new (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Stream state %d is out of the valid range.", state);
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  DEBUG ("State changed to %d for component %d for endpoint %s",
      state, component, self->priv->object_path);

  g_hash_table_insert (self->priv->endpoint_state,
      GUINT_TO_POINTER (component),
      GUINT_TO_POINTER (state));
  g_object_notify (G_OBJECT (self), "endpoint-state");

  tp_svc_call_stream_endpoint_emit_endpoint_state_changed (self,
      component, state);

  if (component == TP_STREAM_COMPONENT_DATA)
    {
      TpBaseCallChannel *chan = _tp_base_call_stream_get_channel (
          TP_BASE_CALL_STREAM (self->priv->stream));

      if (chan && TP_IS_BASE_MEDIA_CALL_CHANNEL (chan))
        _tp_base_media_call_channel_endpoint_state_changed (
            TP_BASE_MEDIA_CALL_CHANNEL (chan));
    }

  tp_svc_call_stream_endpoint_return_from_set_endpoint_state (context);
}

static void
call_stream_endpoint_accept_selected_candidate_pair (
    TpSvcCallStreamEndpoint *iface,
    const GValueArray *local_candidate,
    const GValueArray *remote_candidate,
    DBusGMethodInvocation *context)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (iface);
  GError *error = NULL;

  if (!common_checks (self, local_candidate, remote_candidate, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  DEBUG ("Selected candidate accepted for endpoint %s",
      self->priv->object_path);

  g_signal_emit (self, _signals[CANDIDATE_ACCEPTED], 0,
      local_candidate, remote_candidate);

  tp_svc_call_stream_endpoint_return_from_accept_selected_candidate_pair (
      context);
}

static void
call_stream_endpoint_reject_selected_candidate_pair (
    TpSvcCallStreamEndpoint *iface,
    const GValueArray *local_candidate,
    const GValueArray *remote_candidate,
    DBusGMethodInvocation *context)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (iface);
  GError *error = NULL;

  if (!common_checks (self, local_candidate, remote_candidate, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  DEBUG ("Selected candidate rejected for endpoint %s",
      self->priv->object_path);

  g_signal_emit (self, _signals[CANDIDATE_REJECTED], 0,
      local_candidate, remote_candidate);

  tp_svc_call_stream_endpoint_return_from_reject_selected_candidate_pair (
      context);
}

static void
call_stream_endpoint_set_controlling (TpSvcCallStreamEndpoint *iface,
    gboolean controlling,
    DBusGMethodInvocation *context)
{
  TpCallStreamEndpoint *self = TP_CALL_STREAM_ENDPOINT (iface);

  self->priv->controlling = controlling;

  tp_svc_call_stream_endpoint_emit_controlling_changed (self, controlling);
  tp_svc_call_stream_endpoint_return_from_set_controlling (context);
}

static void
call_stream_endpoint_iface_init (gpointer iface, gpointer data)
{
  TpSvcCallStreamEndpointClass *klass =
    (TpSvcCallStreamEndpointClass *) iface;

#define IMPLEMENT(x) tp_svc_call_stream_endpoint_implement_##x (\
    klass, call_stream_endpoint_##x)
  IMPLEMENT(set_selected_candidate_pair);
  IMPLEMENT(set_endpoint_state);
  IMPLEMENT(accept_selected_candidate_pair);
  IMPLEMENT(reject_selected_candidate_pair);
  IMPLEMENT(set_controlling);
#undef IMPLEMENT
}

/* Internal functions */

void
_tp_call_stream_endpoint_set_stream (TpCallStreamEndpoint *self,
    TpBaseMediaCallStream *stream)
{
  g_return_if_fail (TP_IS_CALL_STREAM_ENDPOINT (self));
  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_STREAM (stream));
  g_return_if_fail (self->priv->stream == NULL);

  self->priv->stream = stream;
}
