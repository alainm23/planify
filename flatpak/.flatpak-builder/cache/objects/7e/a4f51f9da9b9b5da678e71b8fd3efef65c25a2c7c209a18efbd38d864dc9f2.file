/* Helper to hold Telepathy handles.
 *
 * Copyright (C) 2008 Collabora Ltd. <http://www.collabora.co.uk/>
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

#include "config.h"

#include "telepathy-glib/connection-internal.h"

#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>

#define DEBUG_FLAG TP_DEBUG_HANDLES
#include "telepathy-glib/debug-internal.h"

/**
 * tp_connection_unref_handles:
 * @self: a connection
 * @handle_type: a handle type
 * @n_handles: the number of handles in @handles
 * @handles: (array length=n_handles): an array of @n_handles handles
 *
 * Do nothing. In versions of telepathy-glib prior to 0.13.8,
 * this released a reference to the handles in @handles.
 *
 * Deprecated: This is no-op so can be safely removed.
 */
void
tp_connection_unref_handles (TpConnection *self G_GNUC_UNUSED,
                             TpHandleType handle_type G_GNUC_UNUSED,
                             guint n_handles G_GNUC_UNUSED,
                             const TpHandle *handles G_GNUC_UNUSED)
{
}


typedef struct {
    TpHandleType handle_type;
    GArray *handles;
    gpointer user_data;
    GDestroyNotify destroy;
    TpConnectionHoldHandlesCb callback;
} HoldHandlesContext;


static void
hold_handles_context_free (gpointer p)
{
  HoldHandlesContext *context = p;

  if (context->destroy != NULL)
    context->destroy (context->user_data);

  g_array_unref (context->handles);

  g_slice_free (HoldHandlesContext, context);
}

/**
 * TpConnectionHoldHandlesCb:
 * @connection: the connection
 * @handle_type: the handle type that was passed to
 *  tp_connection_hold_handles()
 * @n_handles: the number of handles that were passed to
 *  tp_connection_hold_handles() on success, or 0 on failure
 * @handles: a copy of the array of @n_handles handles that was passed to
 *  tp_connection_hold_handles() on success, or %NULL on failure
 * @error: %NULL on success, or an error on failure
 * @user_data: the same arbitrary pointer that was passed to
 *  tp_connection_hold_handles()
 * @weak_object: the same object that was passed to
 *  tp_connection_hold_handles()
 *
 * Signature of the callback called when tp_connection_hold_handles() succeeds
 * or fails.
 *
 * On success, the caller has a reference to each handle in @handles.
 *
 * Since telepathy-glib version 0.13.8,
 * the handles will remain valid until @connection becomes invalid
 * (signalled by #TpProxy::invalidated). In earlier versions, they could be
 * released with tp_connection_unref_handles().
 *
 * For convenience, the handle type and handles requested by the caller are
 * passed through to this callback on success, so the caller does not have to
 * include them in @user_data.
 *
 * Deprecated: See tp_connection_hold_handles().
 */

static void
connection_held_handles (TpConnection *self,
                         const GError *error,
                         gpointer user_data,
                         GObject *weak_object)
{
  HoldHandlesContext *context = user_data;

  g_object_ref (self);

  if (error == NULL)
    {
      DEBUG ("%u handles of type %u", context->handles->len,
          context->handle_type);
      /* On the Telepathy side, we have held these handles (at least once).
       * That's all we need. */

      context->callback (self, context->handle_type, context->handles->len,
          (const TpHandle *) context->handles->data, NULL,
          context->user_data, weak_object);
    }
  else
    {
      DEBUG ("%u handles of type %u failed: %s %u: %s",
          context->handles->len, context->handle_type,
          g_quark_to_string (error->domain), error->code, error->message);
      context->callback (self, context->handle_type, 0, NULL, error,
          context->user_data, weak_object);
    }

  g_object_unref (self);
}


/**
 * tp_connection_hold_handles:
 * @self: a connection
 * @timeout_ms: the timeout in milliseconds, or -1 to use the default
 * @handle_type: the handle type
 * @n_handles: the number of handles in @handles (must be at least 1)
 * @handles: (array length=n_handles): an array of handles
 * @callback: called on success or failure (unless @weak_object has become
 *  unreferenced)
 * @user_data: arbitrary user-supplied data
 * @destroy: called to destroy @user_data after calling @callback, or when
 *  @weak_object becomes unreferenced (whichever occurs sooner)
 * @weak_object: if not %NULL, an object to be weakly referenced: if it is
 *  destroyed, @callback will not be called
 *
 * Hold (ensure a reference to) the given handles, if they are valid.
 *
 * If they are valid, the callback will later be called with the given
 * handles; if not all of them are valid, the callback will be called with
 * an error.
 *
 * This function, along with tp_connection_unref_handles(),
 * tp_connection_get_contact_attributes() and #TpContact, keeps a client-side
 * reference count of handles; you should not use the RequestHandles,
 * HoldHandles and GetContactAttributes D-Bus methods directly as well as these
 * functions.
 *
 * Deprecated: Holding handles is not needed with Connection Managers having
 *  immortal handles (any Connection Manager using telepathy-glib >= 0.13.8).
 *  Other Connection Managers are considered deprecated, clients wanting to
 *  still support them should continue using this deprecated function.
 */
void
tp_connection_hold_handles (TpConnection *self,
                            gint timeout_ms,
                            TpHandleType handle_type,
                            guint n_handles,
                            const TpHandle *handles,
                            TpConnectionHoldHandlesCb callback,
                            gpointer user_data,
                            GDestroyNotify destroy,
                            GObject *weak_object)
{
  HoldHandlesContext *context;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (handle_type > TP_HANDLE_TYPE_NONE);
  g_return_if_fail (handle_type < TP_NUM_HANDLE_TYPES);
  g_return_if_fail (n_handles >= 1);
  g_return_if_fail (callback != NULL);

  context = g_slice_new0 (HoldHandlesContext);
  context->handle_type = handle_type;
  context->user_data = user_data;
  context->destroy = destroy;
  context->handles = g_array_sized_new (FALSE, FALSE, sizeof (guint),
      n_handles);
  g_array_append_vals (context->handles, handles, n_handles);
  context->callback = callback;

  tp_cli_connection_call_hold_handles (self, timeout_ms, handle_type,
      context->handles, connection_held_handles,
      context, hold_handles_context_free, weak_object);
}


typedef struct {
    TpHandleType handle_type;
    guint n_ids;
    gchar **ids;
    gpointer user_data;
    GDestroyNotify destroy;
    TpConnectionRequestHandlesCb callback;
} RequestHandlesContext;


static void
request_handles_context_free (gpointer p)
{
  RequestHandlesContext *context = p;

  g_strfreev (context->ids);

  if (context->destroy != NULL)
    context->destroy (context->user_data);

  g_slice_free (RequestHandlesContext, context);
}


/**
 * TpConnectionRequestHandlesCb:
 * @connection: the connection
 * @handle_type: the handle type that was passed to
 *  tp_connection_request_handles()
 * @n_handles: the number of IDs that were passed to
 *  tp_connection_request_handles() on success, or 0 on failure
 * @handles: (element-type uint) (array length=n_handles): the @n_handles
 *  handles corresponding to @ids, in the same order, or %NULL on failure
 * @ids: (element-type utf8) (array length=n_handles): a copy of the array of
 *  @n_handles IDs that was passed to tp_connection_request_handles() on
 *  success, or %NULL on failure
 * @error: %NULL on success, or an error on failure
 * @user_data: the same arbitrary pointer that was passed to
 *  tp_connection_request_handles()
 * @weak_object: the same object that was passed to
 *  tp_connection_request_handles()
 *
 * Signature of the callback called when tp_connection_request_handles()
 * succeeds or fails.
 *
 * On success, the caller has a reference to each handle in @handles.
 *
 * Since telepathy-glib version 0.13.8,
 * the handles will remain valid until @connection becomes invalid
 * (signalled by #TpProxy::invalidated). In earlier versions, they could be
 * released with tp_connection_unref_handles().
 *
 * For convenience, the handle type and IDs requested by the caller are
 * passed through to this callback, so the caller does not have to include
 * them in @user_data.
 *
 * Deprecated: See tp_connection_request_handles().
 */


static void
connection_requested_handles (TpConnection *self,
                              const GArray *handles,
                              const GError *error,
                              gpointer user_data,
                              GObject *weak_object)
{
  RequestHandlesContext *context = user_data;

  g_object_ref (self);

  if (error == NULL)
    {
      if (G_UNLIKELY (g_strv_length (context->ids) != handles->len))
        {
          const gchar *cm = tp_proxy_get_bus_name ((TpProxy *) self);
          GError *e = g_error_new (TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
              "Connection manager %s is broken: we asked for %u "
              "handles but RequestHandles returned %u",
              cm, g_strv_length (context->ids), handles->len);

          /* This CM is bad and wrong. We can't trust it to get anything
           * right. */
          WARNING ("%s", e->message);

          context->callback (self, context->handle_type, 0, NULL, NULL,
              e, context->user_data, weak_object);
          g_error_free (e);
          return;
        }

      DEBUG ("%u handles of type %u", handles->len,
          context->handle_type);
      /* On the Telepathy side, we have held these handles (at least once).
       * That's all we need. */

      context->callback (self, context->handle_type, handles->len,
          (const TpHandle *) handles->data,
          (const gchar * const *) context->ids,
          NULL, context->user_data, weak_object);
    }
  else
    {
      DEBUG ("%u handles of type %u failed: %s %u: %s",
          g_strv_length (context->ids), context->handle_type,
          g_quark_to_string (error->domain), error->code, error->message);
      context->callback (self, context->handle_type, 0, NULL, NULL, error,
          context->user_data, weak_object);
    }

  g_object_unref (self);
}


/**
 * tp_connection_request_handles:
 * @self: a connection
 * @timeout_ms: the timeout in milliseconds, or -1 to use the default
 * @handle_type: the handle type
 * @ids: (array zero-terminated=1): an array of string identifiers for which
 *  handles are required, terminated by %NULL (must not be %NULL or empty)
 * @callback: called on success or failure (unless @weak_object has become
 *  unreferenced)
 * @user_data: arbitrary user-supplied data
 * @destroy: called to destroy @user_data after calling @callback, or when
 *  @weak_object becomes unreferenced (whichever occurs sooner)
 * @weak_object: if not %NULL, an object to be weakly referenced: if it is
 *  destroyed, @callback will not be called
 *
 * Request the handles corresponding to the given identifiers, and if they
 * are valid, hold (ensure a reference to) the corresponding handles.
 *
 * If they are valid, the callback will later be called with the given
 * handles; if not all of them are valid, the callback will be called with
 * an error.
 *
 * Deprecated: If @handle_type is TP_HANDLE_TYPE_CONTACT, use
 *  tp_connection_dup_contact_by_id_async() instead. For channel requests,
 *  use tp_account_channel_request_set_target_id() instead.
 */
void
tp_connection_request_handles (TpConnection *self,
                               gint timeout_ms,
                               TpHandleType handle_type,
                               const gchar * const *ids,
                               TpConnectionRequestHandlesCb callback,
                               gpointer user_data,
                               GDestroyNotify destroy,
                               GObject *weak_object)
{
  RequestHandlesContext *context;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (handle_type > TP_HANDLE_TYPE_NONE);
  g_return_if_fail (handle_type < TP_NUM_HANDLE_TYPES);
  g_return_if_fail (ids != NULL);
  g_return_if_fail (ids[0] != NULL);
  g_return_if_fail (callback != NULL);

  context = g_slice_new0 (RequestHandlesContext);
  context->handle_type = handle_type;
  context->ids = g_strdupv ((GStrv) ids);
  context->user_data = user_data;
  context->destroy = destroy;
  context->callback = callback;

  tp_cli_connection_call_request_handles (self, timeout_ms, handle_type,
      (const gchar **) context->ids, connection_requested_handles,
      context, request_handles_context_free, weak_object);
}

/**
 * tp_connection_get_contact_attributes:
 * @self: a connection
 * @timeout_ms: the timeout in milliseconds, or -1 to use the default
 * @n_handles: the number of handles in @handles (must be at least 1)
 * @handles: (array length=n_handles): an array of handles
 * @interfaces: a #GStrv of interfaces
 * @hold: if %TRUE, the callback will hold one reference to each valid handle
 * @callback: (type GObject.Callback): called on success or
 *  failure (unless @weak_object has become unreferenced)
 * @user_data: arbitrary user-supplied data
 * @destroy: called to destroy @user_data after calling @callback, or when
 *  @weak_object becomes unreferenced (whichever occurs sooner)
 * @weak_object: if not %NULL, an object to be weakly referenced: if it is
 *  destroyed, @callback will not be called
 *
 * Return (via a callback) any number of attributes of the given handles.
 *
 * Since telepathy-glib version 0.13.8,
 * the handles will remain valid until @connection becomes invalid
 * (signalled by #TpProxy::invalidated). In earlier versions, if @hold
 * was %TRUE, the callback would hold a reference to them which could be
 * released with tp_connection_unref_handles().
 *
 * This is a thin wrapper around the GetContactAttributes D-Bus method, and
 * should be used in preference to
 * tp_cli_connection_interface_contacts_call_get_contact_attributes(); mixing this
 * function, tp_connection_hold_handles(), tp_connection_unref_handles(), and
 * #TpContact with direct use of the RequestHandles, HoldHandles and
 * GetContactAttributes D-Bus methods is unwise, as #TpConnection and
 * #TpContact perform client-side reference counting of handles.
 * The #TpContact API provides a higher-level abstraction which should
 * usually be used instead.
 *
 * @callback will later be called with the attributes of those of the given
 * handles that were valid. Invalid handles are simply omitted from the
 * parameter to the callback.
 *
 * If @hold is %TRUE, the @callback is given one reference to each handle
 * that appears as a key in the callback's @attributes parameter.
 *
 * Deprecated: Use tp_simple_client_factory_ensure_contact() instead.
 */
void
tp_connection_get_contact_attributes (TpConnection *self,
    gint timeout_ms,
    guint n_handles,
    const TpHandle *handles,
    const gchar * const *interfaces,
    gboolean hold,
    tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GArray *a;
  guint i;

  DEBUG ("%u handles", n_handles);

  for (i = 0; i < n_handles; i++)
    DEBUG ("- %u", handles[i]);

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (n_handles >= 1);
  g_return_if_fail (handles != NULL);
  g_return_if_fail (callback != NULL);

  a = g_array_sized_new (FALSE, FALSE, sizeof (guint), n_handles);

  g_array_append_vals (a, handles, n_handles);

  /* We ignore @hold, and always hold the handles anyway */
  tp_cli_connection_interface_contacts_call_get_contact_attributes (self, -1,
      a, (const gchar **) interfaces, TRUE, callback,
      user_data, destroy, weak_object);
  g_array_unref (a);
}

/**
 * tp_connection_get_contact_list_attributes:
 * @self: a connection
 * @timeout_ms: the timeout in milliseconds (using a large timeout is
 *  recommended)
 * @interfaces: a #GStrv of interfaces
 * @hold: if %TRUE, the callback will hold one reference to each handle it
 *  receives
 * @callback: (type GObject.Callback): called on success or
 *  failure (unless @weak_object has become unreferenced)
 * @user_data: arbitrary user-supplied data
 * @destroy: called to destroy @user_data after calling @callback, or when
 *  @weak_object becomes unreferenced (whichever occurs sooner)
 * @weak_object: if not %NULL, an object to be weakly referenced: if it is
 *  destroyed, @callback will not be called
 *
 * Return (via a callback) the contacts on the contact list and any number of
 * their attributes.
 *
 * Since telepathy-glib version 0.13.8,
 * the handles will remain valid until @connection becomes invalid
 * (signalled by #TpProxy::invalidated). In earlier versions, if @hold
 * was %TRUE, the callback would hold a reference to them which could be
 * released with tp_connection_unref_handles().
 *
 * This is a thin wrapper around the RequestContactList D-Bus method,
 * and should be used in preference to lower-level functions; it is similar
 * to tp_connection_get_contact_attributes().
 *
 * The #TpContact API provides a higher-level abstraction which should
 * usually be used instead.
 *
 * If @hold is %TRUE, the @callback is given a reference to each handle
 * that appears as a key in the callback's @attributes parameter.
 *
 * Deprecated: Use tp_connection_dup_contact_list() instead.
 */
void
tp_connection_get_contact_list_attributes (TpConnection *self,
    gint timeout_ms,
    const gchar * const *interfaces,
    gboolean hold,
    tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (callback != NULL);

  /* We ignore @hold, and always hold the handles anyway */
  tp_cli_connection_interface_contact_list_call_get_contact_list_attributes (
      self, -1, (const gchar **) interfaces, TRUE,
      callback, user_data, destroy, weak_object);
}
