/*
 * base-call-content.c - Source for TpBaseCallContent
 * Copyright © 2009–2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
 * @author Will Thompson <will.thompson@collabora.co.uk>
 * @author Xavier Claessens <xavier.claessens@collabora.co.uk>
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
 * SECTION:base-call-content
 * @title: TpBaseCallContent
 * @short_description: base class for #TpSvcCallContent implementations
 * @see_also: #TpSvcCallContent, #TpBaseCallChannel and #TpBaseCallStream
 *
 * This base class makes it easier to write #TpSvcCallContent
 * implementations by implementing its properties, and some of its methods.
 *
 * Subclasses should fill in #TpBaseCallContentClass.get_interfaces,
 * and #TpBaseCallContentClass.deinit virtual function.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallContent:
 *
 * A base class for call content implementations
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentClass:
 * @get_interfaces: extra interfaces provided by this content (this SHOULD NOT
 *  include %TP_IFACE_CALL_CONTENT itself). Implementation must first chainup on
 *  parent class implementation then add extra interfaces into the #GPtrArray.
 * @deinit: optional; virtual method called by #TpBaseCallChannel when removing
 *  the content
 * @start_tone: optional; virtual method called when user requested to send
 *  a DTMF tone. Note that this method is already implemented by
 *  #TpBaseMediaCallContent and so does not have to be overriden when using that
 *  subclass
 * @stop_tone: optional; virtual method called when user requested to stop
 *  sending currently being played DTMF tones. Note that this method is already
 *  implemented by #TpBaseMediaCallContent and so does not have to be overriden
 *  when using that subclass
 * @multiple_tones: optional; virtual method called when user requested to send
 *  multiple DTMF tones. Note that this method is already implemented by
 *  #TpBaseMediaCallContent and so does not have to be overriden when using that
 *  subclass
 *
 * The class structure for #TpBaseCallContent
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentGetInterfacesFunc:
 * @self: a #TpBaseCallContent
 *
 * Signature of an implementation of #TpBaseCallContentClass.get_interfaces.
 *
 * Returns: a #GPtrArray containing static strings.
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentDeinitFunc:
 * @self: a #TpBaseCallContent
 *
 * Signature of an implementation of #TpBaseCallContentClass.deinit.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentStartToneFunc:
 * @self: a #TpBaseCallContent
 * @event: a #TpDTMFEvent
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallContentClass.start_tone.
 *
 * Returns: %TRUE on success, otherwise %FALSE and set @error
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentStopToneFunc:
 * @self: a #TpBaseCallContent
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallContentClass.stop_tone.
 *
 * Returns: %TRUE on success, otherwise %FALSE and set @error
 * Since: 0.17.5
 */

/**
 * TpBaseCallContentMultipleTonesFunc:
 * @self: a #TpBaseCallContent
 * @tones: a string representation of one or more DTMF events
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallContentClass.multiple_tones.
 *
 * Returns: %TRUE on success, otherwise %FALSE and set @error
 * Since: 0.17.5
 */

#include "config.h"

#include "telepathy-glib/base-call-content.h"

#define DEBUG_FLAG TP_DEBUG_CALL

#include "telepathy-glib/base-call-channel.h"
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-connection.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/dbus-properties-mixin.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-generic.h"
#include "telepathy-glib/util.h"
#include "telepathy-glib/util-internal.h"

static void call_content_iface_init (gpointer g_iface, gpointer iface_data);
static void call_content_dtmf_iface_init (gpointer g_iface,
    gpointer iface_data);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseCallContent, tp_base_call_content,
    G_TYPE_OBJECT,

    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
        tp_dbus_properties_mixin_iface_init)
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT,
        call_content_iface_init)
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF,
        call_content_dtmf_iface_init)
    )

struct _TpBaseCallContentPrivate
{
  TpBaseConnection *conn;

  gchar *object_path;

  gchar *name;
  TpMediaStreamType media_type;
  TpHandle creator;
  TpCallContentDisposition disposition;

  /* GList or reffed TpBaseCallStream */
  GList *streams;

  /* Borrowed */
  TpBaseCallChannel *channel;

  gboolean deinit_has_run;
};

enum
{
  PROP_OBJECT_PATH = 1,
  PROP_CONNECTION,

  /* Call.Content Properties */
  PROP_INTERFACES,
  PROP_NAME,
  PROP_MEDIA_TYPE,
  PROP_CREATOR,
  PROP_DISPOSITION,
  PROP_STREAMS,

  /* Call.Content.Interface.DTMF properties */

  PROP_CURRENTLY_SENDING_TONES,
  PROP_DEFERRED_TONES,
};

static void
tp_base_call_content_init (TpBaseCallContent *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_CALL_CONTENT, TpBaseCallContentPrivate);
}

static void
tp_base_call_content_constructed (GObject *obj)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (obj);
  TpDBusDaemon *bus = tp_base_connection_get_dbus_daemon (
      (TpBaseConnection *) self->priv->conn);

  if (G_OBJECT_CLASS (tp_base_call_content_parent_class)->constructed != NULL)
    G_OBJECT_CLASS (tp_base_call_content_parent_class)->constructed (obj);

  DEBUG ("Registering %s", self->priv->object_path);
  tp_dbus_daemon_register_object (bus, self->priv->object_path, obj);
}

static void
tp_base_call_content_deinit_real (TpBaseCallContent *self)
{
  TpDBusDaemon *bus = tp_base_connection_get_dbus_daemon (
      (TpBaseConnection *) self->priv->conn);

  tp_dbus_daemon_unregister_object (bus, G_OBJECT (self));

  tp_clear_pointer (&self->priv->streams, _tp_object_list_free);
}

static GPtrArray *
tp_base_call_content_get_interfaces (TpBaseCallContent *self)
{
  return g_ptr_array_new ();
}

static void
tp_base_call_content_dispose (GObject *object)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (object);

  if (!self->priv->deinit_has_run)
    _tp_base_call_content_deinit (self);

  g_assert (self->priv->deinit_has_run);

  tp_clear_pointer (&self->priv->streams, _tp_object_list_free);
  g_object_notify (G_OBJECT (self), "streams");
  tp_clear_object (&self->priv->conn);

  if (G_OBJECT_CLASS (tp_base_call_content_parent_class)->dispose != NULL)
    G_OBJECT_CLASS (tp_base_call_content_parent_class)->dispose (object);
}

static void
tp_base_call_content_finalize (GObject *object)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (object);

  /* free any data held directly by the object here */
  g_free (self->priv->object_path);
  g_free (self->priv->name);

  G_OBJECT_CLASS (tp_base_call_content_parent_class)->finalize (object);
}

static void
tp_base_call_content_get_property (
    GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (object);
  TpBaseCallContentClass *klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        g_value_set_string (value, self->priv->object_path);
        break;
      case PROP_CONNECTION:
        g_value_set_object (value, self->priv->conn);
        break;
      case PROP_INTERFACES:
        {
          GPtrArray *interfaces = klass->get_interfaces (self);

          g_ptr_array_add (interfaces, NULL);
          g_value_set_boxed (value, interfaces->pdata);
          g_ptr_array_unref (interfaces);
          break;
        }
      case PROP_NAME:
        g_value_set_string (value, self->priv->name);
        break;
      case PROP_MEDIA_TYPE:
        g_value_set_uint (value, self->priv->media_type);
        break;
      case PROP_CREATOR:
        g_value_set_uint (value, self->priv->creator);
        break;
      case PROP_DISPOSITION:
        g_value_set_uint (value, self->priv->disposition);
        break;
      case PROP_STREAMS:
        {
          GPtrArray *arr = g_ptr_array_sized_new (2);
          GList *l;

          for (l = self->priv->streams; l != NULL; l = g_list_next (l))
            {
              TpBaseCallStream *s = TP_BASE_CALL_STREAM (l->data);
              g_ptr_array_add (arr,
                  g_strdup (tp_base_call_stream_get_object_path (s)));
            }

          g_value_take_boxed (value, arr);
          break;
        }
      case PROP_CURRENTLY_SENDING_TONES:
        g_value_set_boolean (value, FALSE);
        break;
      case PROP_DEFERRED_TONES:
        g_value_set_static_string (value, "");
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_call_content_set_property (
    GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (object);

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        self->priv->object_path = g_value_dup_string (value);
        g_assert (self->priv->object_path != NULL);
        break;
      case PROP_CONNECTION:
        self->priv->conn = g_value_dup_object (value);
        break;
      case PROP_NAME:
        self->priv->name = g_value_dup_string (value);
        break;
      case PROP_MEDIA_TYPE:
        self->priv->media_type = g_value_get_uint (value);
        break;
      case PROP_CREATOR:
        self->priv->creator = g_value_get_uint (value);
        break;
      case PROP_DISPOSITION:
        self->priv->disposition = g_value_get_uint (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_call_content_class_init (TpBaseCallContentClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl content_props[] = {
    { "Interfaces", "interfaces", NULL },
    { "Name", "name", NULL },
    { "Type", "media-type", NULL },
    { "Disposition", "disposition", NULL },
    { "Streams", "streams", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinPropImpl content_dtmf_props[] = {
    { "CurrentlySendingTones", "currently-sending-tones", NULL },
    { "DeferredTones", "deferred-tones", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_interfaces[] = {
      { TP_IFACE_CALL_CONTENT,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        content_props,
      },
      { TP_IFACE_CALL_CONTENT_INTERFACE_DTMF,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        content_dtmf_props,
      },
      { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpBaseCallContentPrivate));

  object_class->constructed = tp_base_call_content_constructed;
  object_class->dispose = tp_base_call_content_dispose;
  object_class->finalize = tp_base_call_content_finalize;
  object_class->get_property = tp_base_call_content_get_property;
  object_class->set_property = tp_base_call_content_set_property;

  klass->deinit = tp_base_call_content_deinit_real;
  klass->get_interfaces = tp_base_call_content_get_interfaces;

  /**
   * TpBaseCallContent:object-path:
   *
   * The D-Bus object path used for this object on the bus.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("object-path", "D-Bus object path",
      "The D-Bus object path used for this object on the bus.",
      NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_OBJECT_PATH, param_spec);

  /**
   * TpBaseCallContent:connection:
   *
   * #TpBaseConnection object that owns this call content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("connection", "TpBaseConnection object",
      "Tp base connection object that owns this call content",
      TP_TYPE_BASE_CONNECTION,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION, param_spec);

  /**
   * TpBaseCallContent:interfaces:
   *
   * Additional interfaces implemented by this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("interfaces", "Extra D-Bus interfaces",
      "Additional interfaces implemented by this content",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INTERFACES, param_spec);

  /**
   * TpBaseCallContent:name:
   *
   * The name of this content, if any.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("name", "Name",
      "The name of this content, if any",
      "",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_NAME, param_spec);

  /**
   * TpBaseCallContent:media-type:
   *
   * The #TpMediaStreamType of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("media-type", "Media Type",
      "The media type of this content",
      0, G_MAXUINT, 0,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MEDIA_TYPE, param_spec);

  /**
   * TpBaseCallContent:creator:
   *
   * The contact #TpHandle of the creator of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("creator", "Creator",
      "The creator of this content",
      0, G_MAXUINT, 0,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CREATOR, param_spec);

  /**
   * TpBaseCallContent:disposition:
   *
   * The #TpCallContentDisposition of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("disposition", "Disposition",
      "The disposition of this content",
      0, G_MAXUINT, 0,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DISPOSITION, param_spec);

  /**
   * TpBaseCallContent:streams:
   *
   * A #GPtrArray of this content streams' #TpBaseCallStream:object-path.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("streams", "Stream",
      "The streams of this content",
      TP_ARRAY_TYPE_OBJECT_PATH_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STREAMS,
      param_spec);

  /**
   * TpBaseCallContent:currently-sending-tones:
   *
   * If this content is currently sending tones or not
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("currently-sending-tones",
      "CurrentlySendingTones",
      "If the Content is currently sending tones or not",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CURRENTLY_SENDING_TONES,
      param_spec);

  /**
   * TpBaseCallContent:deferred-tones:
   *
   * Tones that are waiting for the user action to play.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("deferred-tones",
      "DeferredTones",
      "The tones requested in the initial channel request",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DEFERRED_TONES,
      param_spec);

  klass->dbus_props_class.interfaces = prop_interfaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpBaseCallContentClass, dbus_props_class));
}

/**
 * tp_base_call_content_get_connection:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallContent:connection
 * Since: 0.17.5
 */
TpBaseConnection *
tp_base_call_content_get_connection (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self), NULL);

  return self->priv->conn;
}

/**
 * tp_base_call_content_get_object_path:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallContent:object-path
 * Since: 0.17.5
 */
const gchar *
tp_base_call_content_get_object_path (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self), NULL);

  return self->priv->object_path;
}

/**
 * tp_base_call_content_get_name:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallContent:name
 * Since: 0.17.5
 */
const gchar *
tp_base_call_content_get_name (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self), NULL);

  return self->priv->name;
}

/**
 * tp_base_call_content_get_media_type:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallContent:media-type
 * Since: 0.17.5
 */
TpMediaStreamType
tp_base_call_content_get_media_type (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self),
      TP_MEDIA_STREAM_TYPE_AUDIO);

  return self->priv->media_type;
}

/**
 * tp_base_call_content_get_disposition:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallContent:disposition
 * Since: 0.17.5
 */
TpCallContentDisposition
tp_base_call_content_get_disposition (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self),
      TP_CALL_CONTENT_DISPOSITION_NONE);

  return self->priv->disposition;
}

/**
 * tp_base_call_content_get_streams:
 * @self: a #TpBaseCallContent
 *
 * <!-- -->
 *
 * Returns: a #GList of #TpBaseCallStream of this content.
 * Since: 0.17.5
 */
GList *
tp_base_call_content_get_streams (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self), NULL);

  return self->priv->streams;
}

/**
 * tp_base_call_content_add_stream:
 * @self: a #TpBaseCallContent
 * @stream: a #TpBaseCallStream
 *
 * Add @stream to @self's #TpBaseCallContent:streams. Emitting StreamsAdded
 * DBus signal.
 *
 * Since: 0.17.5
 */
void
tp_base_call_content_add_stream (TpBaseCallContent *self,
    TpBaseCallStream *stream)
{
  GPtrArray *paths;

  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (self));
  g_return_if_fail (TP_IS_BASE_CALL_STREAM (stream));
  g_return_if_fail (tp_base_call_stream_get_connection (stream) ==
      self->priv->conn);
  g_return_if_fail (self->priv->channel != NULL);
  g_return_if_fail (g_list_find (self->priv->streams, stream) == NULL);

  _tp_base_call_stream_set_content (stream, self);

  self->priv->streams = g_list_prepend (self->priv->streams,
      g_object_ref (stream));
  g_object_notify (G_OBJECT (self), "streams");

  paths = g_ptr_array_new_with_free_func ((GDestroyNotify) g_free);

  g_ptr_array_add (paths, g_strdup (
     tp_base_call_stream_get_object_path (
         TP_BASE_CALL_STREAM (stream))));
  tp_svc_call_content_emit_streams_added (self, paths);
  g_ptr_array_unref (paths);
}

void
_tp_base_call_content_remove_stream_internal (TpBaseCallContent *self,
    TpBaseCallStream *stream,
    const GValueArray *reason_array)
{
  GList *l;
  GPtrArray *paths;

  l = g_list_find (self->priv->streams, stream);
  g_return_if_fail (l != NULL);

  self->priv->streams = g_list_delete_link (self->priv->streams, l);
  g_object_notify (G_OBJECT (self), "streams");

  paths = g_ptr_array_new ();
  g_ptr_array_add (paths, (gpointer)
      tp_base_call_stream_get_object_path (stream));

  tp_svc_call_content_emit_streams_removed (self, paths, reason_array);

  g_ptr_array_unref (paths);
  g_object_unref (stream);
}

/**
 * tp_base_call_content_remove_stream:
 * @self: a #TpBaseCallContent
 * @stream: a #TpBaseCallStream
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Remove @stream from @self's #TpBaseCallContent:streams. Emitting
 * StreamsRemoved DBus signal.
 *
 * Since: 0.17.5
 */
void
tp_base_call_content_remove_stream (TpBaseCallContent *self,
    TpBaseCallStream *stream,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  GValueArray *reason_array;

  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (self));
  g_return_if_fail (TP_IS_BASE_CALL_STREAM (stream));

  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  _tp_base_call_content_remove_stream_internal (self, stream, reason_array);

  tp_value_array_free (reason_array);
}

static void
tp_call_content_remove (TpSvcCallContent *content,
    DBusGMethodInvocation *context)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (content);

  if (!tp_base_call_channel_has_mutable_contents (self->priv->channel))
    {
      GError error = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Contents are not mutable" };
      dbus_g_method_return_error (context, &error);
      return;
    }

  tp_base_call_channel_remove_content (self->priv->channel, self,
      tp_base_channel_get_self_handle ((TpBaseChannel *) self->priv->channel),
      TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
      "User has removed the content");

  tp_svc_call_content_return_from_remove (context);
}

static void
call_content_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcCallContentClass *klass =
    (TpSvcCallContentClass *) g_iface;

#define IMPLEMENT(x) tp_svc_call_content_implement_##x (\
    klass, tp_call_content_##x)
  IMPLEMENT(remove);
#undef IMPLEMENT
}

/* These functions are used only internally */

void
_tp_base_call_content_set_channel (TpBaseCallContent *self,
    TpBaseCallChannel *channel)
{
  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (self));
  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (channel));
  g_return_if_fail (self->priv->channel == NULL);

  self->priv->channel = channel;

  if (self->priv->disposition == TP_CALL_CONTENT_DISPOSITION_INITIAL)
    {
      TpBaseCallContentClass *klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);
      const gchar *tones;

      tones =_tp_base_call_channel_get_initial_tones (channel);
      if (tones && tones[0] && klass->multiple_tones != NULL)
        {
          klass->multiple_tones (self, tones, NULL);
        }
    }

}

TpBaseCallChannel *
_tp_base_call_content_get_channel (TpBaseCallContent *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CONTENT (self), NULL);
  g_return_val_if_fail (self->priv->channel != NULL, NULL);

  return self->priv->channel;
}

void
_tp_base_call_content_deinit (TpBaseCallContent *self)
{
  TpBaseCallContentClass *klass;

  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (self));

  g_assert (!self->priv->deinit_has_run);
  self->priv->deinit_has_run = TRUE;

  klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);
  klass->deinit (self);
}

void
_tp_base_call_content_accepted (TpBaseCallContent *self,
    TpHandle actor_handle)
{
  GList *l;

  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (self));

  if (self->priv->disposition != TP_CALL_CONTENT_DISPOSITION_INITIAL)
    return;

  for (l = self->priv->streams ; l != NULL; l = g_list_next (l))
    {
      TpBaseCallStream *s = TP_BASE_CALL_STREAM (l->data);

      if (tp_base_call_stream_get_local_sending_state (s) ==
          TP_SENDING_STATE_PENDING_SEND)
        tp_base_call_stream_update_local_sending_state (s,
            TP_SENDING_STATE_SENDING, actor_handle,
            TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
            "User accepted the Call");
    }
}

static void
tp_call_content_start_tone (TpSvcCallContentInterfaceDTMF *dtmf,
    guchar event,
    DBusGMethodInvocation *context)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (dtmf);
  TpBaseCallContentClass *klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);
  GError *error = NULL;

  if (klass->start_tone == NULL)
    {
      GError err = {G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
                    "Method does not exist"};
      dbus_g_method_return_error (context, &err);
      return;
    }

  if (!klass->start_tone (self, event, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  tp_svc_call_content_interface_dtmf_return_from_start_tone (context);
}

static void
tp_call_content_stop_tone (TpSvcCallContentInterfaceDTMF *dtmf,
   DBusGMethodInvocation *context)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (dtmf);
  TpBaseCallContentClass *klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);
  GError *error = NULL;

  if (klass->stop_tone == NULL)
    {
      GError err = {G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
                    "Method does not exist"};
      dbus_g_method_return_error (context, &err);
      return;
    }

  if (!klass->stop_tone (self, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  tp_svc_call_content_interface_dtmf_return_from_stop_tone (context);
}

static void
tp_call_content_multiple_tones (TpSvcCallContentInterfaceDTMF *dtmf,
    const gchar *tones,
    DBusGMethodInvocation *context)
{
  TpBaseCallContent *self = TP_BASE_CALL_CONTENT (dtmf);
  TpBaseCallContentClass *klass = TP_BASE_CALL_CONTENT_GET_CLASS (self);
  GError *error = NULL;

  if (klass->multiple_tones == NULL)
    {
      GError err = {G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
                    "Method does not exist"};
      dbus_g_method_return_error (context, &err);
      return;
    }

  if (!klass->multiple_tones (self, tones, &error))
    {
      dbus_g_method_return_error (context, error);
      g_clear_error (&error);
      return;
    }

  tp_svc_call_content_interface_dtmf_return_from_multiple_tones (context);
}

static void
call_content_dtmf_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcCallContentInterfaceDTMFClass *klass =
      (TpSvcCallContentInterfaceDTMFClass *) g_iface;

#define IMPLEMENT(x) tp_svc_call_content_interface_dtmf_implement_##x (\
    klass, tp_call_content_##x)
  IMPLEMENT(start_tone);
  IMPLEMENT(stop_tone);
  IMPLEMENT(multiple_tones);
#undef IMPLEMENT
}
