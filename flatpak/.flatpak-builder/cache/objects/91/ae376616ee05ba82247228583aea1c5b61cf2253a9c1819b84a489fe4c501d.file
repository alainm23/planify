/*
 * channel-manager.c - factory and manager for channels relating to a
 *  particular protocol feature
 *
 * Copyright (C) 2008 Collabora Ltd.
 * Copyright (C) 2008 Nokia Corporation
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
 * SECTION:channel-manager
 * @title: TpChannelManager
 * @short_description: interface for creating and tracking channels
 * @see_also: #TpSvcConnection
 *
 * A channel manager is attached to a connection. It carries out channel
 * requests from the connection, and responds to channel-related events on the
 * underlying network connection, for particular classes of channel (for
 * example, incoming and outgoing calls, respectively). It also tracks
 * currently-open channels of the relevant kinds.
 *
 * The connection has an array of channel managers. In response to a call to
 * CreateChannel or RequestChannel, the channel request is offered to each
 * channel manager in turn, until one accepts the request. In a trivial
 * implementation there might be a single channel manager which handles all
 * requests and all incoming events, but in general, there will be multiple
 * channel managers handling different types of channel.
 *
 * For example, at the time of writing, Gabble has a roster channel manager
 * which handles contact lists and groups, an IM channel manager which
 * handles one-to-one messaging, a MUC channel manager which handles
 * multi-user chat rooms, the index of chat rooms and MUC tubes, a media
 * channel manager which handles VoIP calls, and a 1-1 tubes channel manager.
 *
 * Since: 0.7.15
 */

/**
 * TpChannelManager:
 *
 * Opaque typedef representing any channel manager implementation.
 */

/**
 * TpChannelManagerForeachChannelFunc:
 * @manager: an object implementing #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the second argument of @func
 *
 * Signature of an implementation of foreach_channel, which must call
 * func(channel, user_data) for each channel managed by this channel manager.
 */

/**
 * TpChannelManagerChannelClassFunc:
 * @manager: An object implementing #TpChannelManager
 * @fixed_properties: A table mapping (const gchar *) property names to
 *  GValues, representing the values those properties must take to request
 *  channels of a particular class.
 * @allowed_properties: A %NULL-terminated array of property names which may
 *  appear in requests for a particular channel class.
 * @user_data: Arbitrary user-supplied data.
 *
 * Signature of callbacks which act on each channel class supported by @manager.
 */

/**
 * TpChannelManagerForeachChannelClassFunc:
 * @manager: An object implementing #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the final argument of @func
 *
 * Signature of an implementation of foreach_channel_class, which must call
 * func(manager, fixed, allowed, user_data) for each channel class understood
 * by @manager.
 */

/**
 * TpChannelManagerTypeChannelClassFunc:
 * @type: A type whose instances implement #TpChannelManager
 * @fixed_properties: A table mapping (const gchar *) property names to
 *  GValues, representing the values those properties must take to request
 *  channels of a particular class.
 * @allowed_properties: A %NULL-terminated array of property names which may
 *  appear in requests for a particular channel class.
 * @user_data: Arbitrary user-supplied data.
 *
 * Signature of callbacks which act on each channel class potentially supported
 * by instances of @type.
 */

/**
 * TpChannelManagerTypeForeachChannelClassFunc:
 * @type: A type whose instances implement #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the final argument of @func
 *
 * Signature of an implementation of type_foreach_channel_class, which must
 * call func(type, fixed, allowed, user_data) for each channel class
 * potentially understood by instances of @type.
 */

/**
 * TpChannelManagerRequestFunc:
 * @manager: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing this pending request.
 * @request_properties: A table mapping (const gchar *) property names to
 *  GValue, representing the desired properties of a channel requested by a
 *  Telepathy client. The hash table will be freed after the function returns;
 *  if the channel manager wants to keep it around, it must copy it.
 *
 * Signature of an implementation of #TpChannelManagerIface.create_channel and
 * #TpChannelManagerIface.request_channel.
 *
 * Implementations should inspect the contents of @request_properties to see if
 * it matches a channel class handled by this manager.  If so, they should
 * return %TRUE to accept responsibility for the request, and ultimately emit
 * exactly one of the #TpChannelManager::new-channels,
 * #TpChannelManager::request-already-satisfied and
 * #TpChannelManager::request-failed signals (including @request_token in
 * the appropriate argument).
 *
 * If the implementation does not want to handle the request, it should return
 * %FALSE to allow the request to be offered to another channel manager.
 *
 * Implementations may assume the following of @request_properties:
 *
 * <itemizedlist>
 *   <listitem>
 *      the ChannelType property is present, and is a (const gchar *)
 *   </listitem>
 *   <listitem>
 *     the TargetHandleType property is a valid #TpHandleType, if present
 *   </listitem>
 *   <listitem>
 *     if TargetHandleType is None, TargetHandle is omitted
 *   </listitem>
 *   <listitem>
 *     if TargetHandleType is not None, TargetHandle is a valid #TpHandle of
 *     that #TpHandleType
 *   </listitem>
 * </itemizedlist>
 *
 * Changed in version 0.15.5: Previously the TargetID
 * property was guaranteed to be missing from @request_properties. Now
 * it is always present, whether it was in the original channel
 * request or not.
 *
 * Returns: %TRUE if @manager will handle this request, else %FALSE.
 */

/**
 * TpChannelManagerIface:
 * @parent: Fields shared with GTypeInterface.
 * @foreach_channel: Call func(channel, user_data) for each channel managed by
 *  this manager. If not implemented, the manager is assumed to manage no
 *  channels.
 * @foreach_channel_class: Call func(manager, fixed, allowed, user_data) for
 *  each class of channel that this instance can create (a subset of the
 *  channel classes produced by @type_foreach_channel_class). If not
 *  implemented, @type_foreach_channel_class is used.
 * @create_channel: Respond to a request for a new channel made with the
 *  Connection.Interface.Requests.CreateChannel method. See
 *  #TpChannelManagerRequestFunc for details.
 * @request_channel: Respond to a request for a (new or existing) channel made
 *  with the Connection.RequestChannel method. See #TpChannelManagerRequestFunc
 *  for details.
 * @ensure_channel: Respond to a request for a (new or existing) channel made
 *  with the Connection.Interface.Requests.EnsureChannel method. See
 *  #TpChannelManagerRequestFunc for details.
 *  Since: 0.7.16
 * @type_foreach_channel_class: Call func(cls, fixed, allowed, user_data)
 *  for each class of channel that instances of this class might be able to
 *  create.
 *  Since: 0.11.11
 *
 * The vtable for a channel manager implementation.
 *
 * In addition to the fields documented here there are several GCallback
 * fields which must currently be %NULL.
 *
 * Since: 0.7.15
 */


#include "config.h"
#include "channel-manager.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/exportable-channel.h>
#include <telepathy-glib/util.h>

enum {
    S_NEW_CHANNELS,
    S_REQUEST_ALREADY_SATISFIED,
    S_REQUEST_FAILED,
    S_CHANNEL_CLOSED,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};


static void
channel_manager_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;

      /**
       * TpChannelManager::new-channels:
       * @self: the channel manager
       * @channels: a #GHashTable where the keys are
       *  #TpExportableChannel instances (hashed and compared
       *  by g_direct_hash() and g_direct_equal()) and the values are
       *  linked lists (#GSList) of request tokens (opaque pointers) satisfied
       *  by these channels
       *
       * Emitted when new channels have been created. The Connection should
       * generally emit NewChannels (and NewChannel) in response to this
       * signal, and then return from pending CreateChannel, EnsureChannel
       * and/or RequestChannel calls if appropriate.
       *
       * Since 0.19.1, clients should not emit more than one
       *  channel in this signal at one time as the creation of
       *  multiple channels together in a single signal is strongly
       *  recommended against: it's very complicated, hard to get
       *  right in clients, and not nearly as useful as it originally
       *  sounded.
       */
      signals[S_NEW_CHANNELS] = g_signal_new ("new-channels",
          G_OBJECT_CLASS_TYPE (klass),
          G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
          0,
          NULL, NULL, NULL,
          G_TYPE_NONE, 1, G_TYPE_POINTER);

      /**
       * TpChannelManager::request-already-satisfied:
       * @self: the channel manager
       * @request_token: opaque pointer supplied by the requester,
       *  representing a request
       * @channel: the existing #TpExportableChannel that satisfies the
       *  request
       *
       * Emitted when a channel request is satisfied by an existing channel.
       * The Connection should generally respond to this signal by returning
       * success from EnsureChannel or RequestChannel.
       */
      signals[S_REQUEST_ALREADY_SATISFIED] = g_signal_new (
          "request-already-satisfied",
          G_OBJECT_CLASS_TYPE (klass),
          G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
          0,
          NULL, NULL, NULL,
          G_TYPE_NONE, 2, G_TYPE_POINTER, G_TYPE_OBJECT);

      /**
       * TpChannelManager::request-failed:
       * @self: the channel manager
       * @request_token: opaque pointer supplied by the requester,
       *  representing a request
       * @domain: the domain of a #GError indicating why the request
       *  failed
       * @code: the error code of a #GError indicating why the request
       *  failed
       * @message: the string part of a #GError indicating why the request
       *  failed
       *
       * Emitted when a channel request has failed. The Connection should
       * generally respond to this signal by returning failure from
       * CreateChannel, EnsureChannel or RequestChannel.
       */
      signals[S_REQUEST_FAILED] = g_signal_new ("request-failed",
          G_OBJECT_CLASS_TYPE (klass),
          G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
          0,
          NULL, NULL, NULL,
          G_TYPE_NONE, 4, G_TYPE_POINTER, G_TYPE_UINT, G_TYPE_INT,
          G_TYPE_STRING);

      /**
       * TpChannelManager::channel-closed:
       * @self: the channel manager
       * @path: the channel's object-path
       *
       * Emitted when a channel has been closed. The Connection should
       * generally respond to this signal by emitting ChannelClosed.
       */
      signals[S_CHANNEL_CLOSED] = g_signal_new ("channel-closed",
          G_OBJECT_CLASS_TYPE (klass),
          G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
          0,
          NULL, NULL, NULL,
          G_TYPE_NONE, 1, G_TYPE_STRING);

    }
}

GType
tp_channel_manager_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpChannelManagerIface),
        channel_manager_base_init,   /* base_init */
        NULL,   /* base_finalize */
        NULL,   /* class_init */
        NULL,   /* class_finalize */
        NULL,   /* class_data */
        0,
        0,      /* n_preallocs */
        NULL    /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpChannelManager", &info, 0);
    }

  return type;
}


/* Signal emission wrappers */


/**
 * tp_channel_manager_emit_new_channels:
 * @instance: An object implementing #TpChannelManager
 * @channels: a #GHashTable where the keys are
 *  #TpExportableChannel instances (hashed and compared
 *  by g_direct_hash() and g_direct_equal()) and the values are
 *  linked lists (#GSList) of request tokens (opaque pointers) satisfied by
 *  these channels
 *
 * If @channels is non-empty, emit the #TpChannelManager::new-channels
 * signal indicating that those channels have been created.
 *
 * Deprecated: in 0.19.1 this function should not be
 *  used. Signalling the creation of multiple channels together in a
 *  single signal is strongly recommended against as it's very
 *  complicated, hard to get right in clients, and not nearly as
 *  useful as it originally sounded. Use
 *  tp_channel_manager_emit_new_channel() instead.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_new_channels (gpointer instance,
                                      GHashTable *channels)
{
  g_return_if_fail (TP_IS_CHANNEL_MANAGER (instance));

  if (g_hash_table_size (channels) == 0)
    return;

  g_signal_emit (instance, signals[S_NEW_CHANNELS], 0, channels);
}


/**
 * tp_channel_manager_emit_new_channel:
 * @instance: An object implementing #TpChannelManager
 * @channel: A #TpExportableChannel
 * @request_tokens: the request tokens (opaque pointers) satisfied by this
 *                  channel
 *
 * Emit the #TpChannelManager::new-channels signal indicating that the
 * channel has been created.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_new_channel (gpointer instance,
                                     TpExportableChannel *channel,
                                     GSList *request_tokens)
{
  GHashTable *channels;

  g_return_if_fail (TP_IS_CHANNEL_MANAGER (instance));
  g_return_if_fail (TP_IS_EXPORTABLE_CHANNEL (channel));

  channels = g_hash_table_new_full (g_direct_hash, g_direct_equal,
      NULL, NULL);
  g_hash_table_insert (channels, channel, request_tokens);
  g_signal_emit (instance, signals[S_NEW_CHANNELS], 0, channels);
  g_hash_table_unref (channels);
}


/**
 * tp_channel_manager_emit_channel_closed:
 * @instance: An object implementing #TpChannelManager
 * @path: A channel's object-path
 *
 * Emit the #TpChannelManager::channel-closed signal indicating that
 * the channel at the given object path has been closed.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_channel_closed (gpointer instance,
                                        const gchar *path)
{
  g_return_if_fail (TP_IS_CHANNEL_MANAGER (instance));
  g_return_if_fail (tp_dbus_check_valid_object_path (path, NULL));

  g_signal_emit (instance, signals[S_CHANNEL_CLOSED], 0, path);
}


/**
 * tp_channel_manager_emit_channel_closed_for_object:
 * @instance: An object implementing #TpChannelManager
 * @channel: A #TpExportableChannel
 *
 * Emit the #TpChannelManager::channel-closed signal indicating that
 * the given channel has been closed. (This is a convenient shortcut for
 * calling tp_channel_manager_emit_channel_closed() with the
 * #TpExportableChannel:object-path property of @channel.)
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_channel_closed_for_object (gpointer instance,
    TpExportableChannel *channel)
{
  gchar *path;

  g_return_if_fail (TP_IS_EXPORTABLE_CHANNEL (channel));
  g_object_get (channel,
      "object-path", &path,
      NULL);
  tp_channel_manager_emit_channel_closed (instance, path);
  g_free (path);
}


/**
 * tp_channel_manager_emit_request_already_satisfied:
 * @instance: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing the request that
 *  succeeded
 * @channel: The channel that satisfies the request
 *
 * Emit the #TpChannelManager::request-already-satisfied signal indicating
 * that the pre-existing channel @channel satisfies @request_token.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_request_already_satisfied (gpointer instance,
    gpointer request_token,
    TpExportableChannel *channel)
{
  g_return_if_fail (TP_IS_EXPORTABLE_CHANNEL (channel));
  g_return_if_fail (TP_IS_CHANNEL_MANAGER (instance));

  g_signal_emit (instance, signals[S_REQUEST_ALREADY_SATISFIED], 0,
      request_token, channel);
}


/**
 * tp_channel_manager_emit_request_failed:
 * @instance: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing the request that failed
 * @domain: a #GError domain
 * @code: a #GError code appropriate for @domain
 * @message: the error message
 *
 * Emit the #TpChannelManager::request-failed signal indicating that
 * the request @request_token failed for the given reason.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_request_failed (gpointer instance,
                                        gpointer request_token,
                                        GQuark domain,
                                        gint code,
                                        const gchar *message)
{
  g_return_if_fail (TP_IS_CHANNEL_MANAGER (instance));

  g_signal_emit (instance, signals[S_REQUEST_FAILED], 0, request_token,
      domain, code, message);
}


/**
 * tp_channel_manager_emit_request_failed_printf:
 * @instance: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing the request that failed
 * @domain: a #GError domain
 * @code: a #GError code appropriate for @domain
 * @format: a printf-style format string for the error message
 * @...: arguments for the format string
 *
 * Emit the #TpChannelManager::request-failed signal indicating that
 * the request @request_token failed for the given reason.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_emit_request_failed_printf (gpointer instance,
                                               gpointer request_token,
                                               GQuark domain,
                                               gint code,
                                               const gchar *format,
                                               ...)
{
  va_list ap;
  gchar *message;

  va_start (ap, format);
  message = g_strdup_vprintf (format, ap);
  va_end (ap);

  tp_channel_manager_emit_request_failed (instance, request_token,
      domain, code, message);

  g_free (message);
}


/* Virtual-method wrappers */


/**
 * tp_channel_manager_foreach_channel:
 * @manager: an object implementing #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the second argument of @func
 *
 * Calls func(channel, user_data) for each channel managed by @manager.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_foreach_channel (TpChannelManager *manager,
                                    TpExportableChannelFunc func,
                                    gpointer user_data)
{
  TpChannelManagerIface *iface = TP_CHANNEL_MANAGER_GET_INTERFACE (
      manager);
  TpChannelManagerForeachChannelFunc method = iface->foreach_channel;

  if (method != NULL)
    {
      method (manager, func, user_data);
    }
  /* ... else assume it has no channels, and do nothing */
}

typedef struct
{
  TpChannelManager *self;
  TpChannelManagerChannelClassFunc func;
  gpointer user_data;
} ForeachAdaptor;

static void
foreach_adaptor (GType type G_GNUC_UNUSED,
    GHashTable *fixed,
    const gchar * const *allowed,
    gpointer user_data)
{
  ForeachAdaptor *adaptor = user_data;

  adaptor->func (adaptor->self, fixed, allowed, adaptor->user_data);
}

/**
 * tp_channel_manager_foreach_channel_class:
 * @manager: An object implementing #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the final argument of @func
 *
 * Calls func(manager, fixed, allowed, user_data) for each channel class
 * understood by @manager.
 *
 * Since: 0.7.15
 */
void
tp_channel_manager_foreach_channel_class (TpChannelManager *manager,
    TpChannelManagerChannelClassFunc func,
    gpointer user_data)
{
  TpChannelManagerIface *iface = TP_CHANNEL_MANAGER_GET_INTERFACE (
      manager);
  TpChannelManagerForeachChannelClassFunc method =
      iface->foreach_channel_class;

  if (method != NULL)
    {
      method (manager, func, user_data);
    }
  else
    {
      ForeachAdaptor adaptor = { manager, func, user_data };

      tp_channel_manager_type_foreach_channel_class (
          G_TYPE_FROM_INSTANCE (manager), foreach_adaptor, &adaptor);
    }
}


/**
 * tp_channel_manager_type_foreach_channel_class:
 * @type: A type whose instances implement #TpChannelManager
 * @func: A function
 * @user_data: Arbitrary data to be passed as the final argument of @func
 *
 * Calls func(type, fixed, allowed, user_data) for each channel class
 * potentially understood by instances of @type.
 *
 * Since: 0.11.11
 */
void
tp_channel_manager_type_foreach_channel_class (GType type,
    TpChannelManagerTypeChannelClassFunc func,
    gpointer user_data)
{
  GTypeClass *cls;
  TpChannelManagerIface *iface;
  TpChannelManagerTypeForeachChannelClassFunc method;

  g_return_if_fail (g_type_is_a (type, TP_TYPE_CHANNEL_MANAGER));

  cls = g_type_class_ref (type);
  iface = g_type_interface_peek (cls, TP_TYPE_CHANNEL_MANAGER);
  method = iface->type_foreach_channel_class;

  if (method != NULL)
    {
      method (type, func, user_data);
    }
  /* ... else assume it has no classes of requestable channel */

  g_type_class_unref (cls);
}


/**
 * tp_channel_manager_create_channel:
 * @manager: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing this pending request.
 * @request_properties: A table mapping (const gchar *) property names to
 *  GValue, representing the desired properties of a channel requested by a
 *  Telepathy client.
 *
 * Offers an incoming CreateChannel call to @manager.
 *
 * Returns: %TRUE if this request will be handled by @manager; else %FALSE.
 *
 * Since: 0.7.15
 */
gboolean
tp_channel_manager_create_channel (TpChannelManager *manager,
                                   gpointer request_token,
                                   GHashTable *request_properties)
{
  TpChannelManagerIface *iface = TP_CHANNEL_MANAGER_GET_INTERFACE (
      manager);
  TpChannelManagerRequestFunc method = iface->create_channel;

  /* A missing implementation is equivalent to one that always returns FALSE,
   * meaning "can't do that, ask someone else" */
  if (method != NULL)
    return method (manager, request_token, request_properties);
  else
    return FALSE;
}


/**
 * tp_channel_manager_request_channel:
 * @manager: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing this pending request.
 * @request_properties: A table mapping (const gchar *) property names to
 *  GValue, representing the desired properties of a channel requested by a
 *  Telepathy client.
 *
 * Offers an incoming RequestChannel call to @manager.
 *
 * Returns: %TRUE if this request will be handled by @manager; else %FALSE.
 *
 * Since: 0.7.15
 */
gboolean
tp_channel_manager_request_channel (TpChannelManager *manager,
                                    gpointer request_token,
                                    GHashTable *request_properties)
{
  TpChannelManagerIface *iface = TP_CHANNEL_MANAGER_GET_INTERFACE (
      manager);
  TpChannelManagerRequestFunc method = iface->request_channel;

  /* A missing implementation is equivalent to one that always returns FALSE,
   * meaning "can't do that, ask someone else" */
  if (method != NULL)
    return method (manager, request_token, request_properties);
  else
    return FALSE;
}


/**
 * tp_channel_manager_ensure_channel:
 * @manager: An object implementing #TpChannelManager
 * @request_token: An opaque pointer representing this pending request.
 * @request_properties: A table mapping (const gchar *) property names to
 *  GValue, representing the desired properties of a channel requested by a
 *  Telepathy client.
 *
 * Offers an incoming EnsureChannel call to @manager.
 *
 * Returns: %TRUE if this request will be handled by @manager; else %FALSE.
 *
 * Since: 0.7.16
 */
gboolean
tp_channel_manager_ensure_channel (TpChannelManager *manager,
                                   gpointer request_token,
                                   GHashTable *request_properties)
{
  TpChannelManagerIface *iface = TP_CHANNEL_MANAGER_GET_INTERFACE (
      manager);
  TpChannelManagerRequestFunc method = iface->ensure_channel;

  /* A missing implementation is equivalent to one that always returns FALSE,
   * meaning "can't do that, ask someone else" */
  if (method != NULL)
    return method (manager, request_token, request_properties);
  else
    return FALSE;
}


/**
 * tp_channel_manager_asv_has_unknown_properties:
 * @properties: a table mapping (const gchar *) property names to GValues,
 *              as passed to methods of #TpChannelManager
 * @fixed: a %NULL-terminated array of property names
 * @allowed: a %NULL-terminated array of property names
 * @error: an address at which to store an error suitable for returning from
 *         the D-Bus method when @properties contains unknown properties
 *
 * Checks whether the keys of @properties are elements of one of @fixed and
 * @allowed.  This is intended to be used by implementations of
 * #TpChannelManagerIface.create_channel which have decided to accept a request,
 * to conform with the specification's requirement that unknown requested
 * properties must cause a request to fail, not be silently ignored.
 *
 * On encountering unknown properties, this function will return %TRUE, and
 * set @error to a #GError that could be used as a D-Bus method error.
 *
 * Returns: %TRUE if @properties contains keys not in either @fixed or
 *          @allowed; else %FALSE.
 *
 * Since: 0.7.15
 */
gboolean
tp_channel_manager_asv_has_unknown_properties (GHashTable *properties,
                                               const gchar * const *fixed,
                                               const gchar * const *allowed,
                                               GError **error)
{
  GHashTableIter iter;
  gpointer key;
  const gchar *property_name;

  g_hash_table_iter_init (&iter, properties);
  while (g_hash_table_iter_next (&iter, &key, NULL))
    {
      property_name = key;
      if (!tp_strv_contains (fixed, property_name) &&
          !tp_strv_contains (allowed, property_name))
        {
          g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
              "Request contained unknown property '%s'", property_name);
          return TRUE;
        }
    }
  return FALSE;
}
