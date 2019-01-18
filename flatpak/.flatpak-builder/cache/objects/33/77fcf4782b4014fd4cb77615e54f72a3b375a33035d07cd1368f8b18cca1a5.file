/*
 * proxy.c - Base class for Telepathy client proxies
 *
 * Copyright (C) 2007-2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007-2008 Nokia Corporation
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

#include "telepathy-glib/proxy-subclass.h"
#include "telepathy-glib/proxy-internal.h"

#include <string.h>

#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/automatic-client-factory.h>
#include <telepathy-glib/util.h>

#include "dbus-internal.h"
#define DEBUG_FLAG TP_DEBUG_PROXY
#include "debug-internal.h"
#include "simple-client-factory-internal.h"
#include "util-internal.h"

#include "_gen/tp-cli-generic-body.h"

#if 0
#define MORE_DEBUG DEBUG
#else
#define MORE_DEBUG(...) G_STMT_START {} G_STMT_END
#endif

/**
 * TP_DBUS_ERRORS:
 *
 * #GError domain representing D-Bus errors not directly related to
 * Telepathy, for use by #TpProxy. The @code in a #GError with this
 * domain must be a member of #TpDBusError.
 *
 * This macro expands to a function call returning a #GQuark.
 *
 * Since: 0.7.1
 */
GQuark
tp_dbus_errors_quark (void)
{
  static GQuark q = 0;

  if (q == 0)
    q = g_quark_from_static_string ("tp_dbus_errors_quark");

  return q;
}

/**
 * TpDBusError:
 * @TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR: Raised if the error raised by
 *  a remote D-Bus object is not recognised
 * @TP_DBUS_ERROR_PROXY_UNREFERENCED: Emitted in #TpProxy::invalidated
 *  when the #TpProxy has lost its last reference
 * @TP_DBUS_ERROR_NO_INTERFACE: Raised by #TpProxy methods if the remote
 *  object does not appear to have the required interface
 * @TP_DBUS_ERROR_NAME_OWNER_LOST: Emitted in #TpProxy::invalidated if the
 *  remote process loses ownership of its bus name, and raised by
 *  any #TpProxy methods that have not had a reply at that time or are called
 *  after the proxy becomes invalid in this way (usually meaning it crashed)
 * @TP_DBUS_ERROR_INVALID_BUS_NAME: Raised if a D-Bus bus name given is not
 *  valid, or is of an unacceptable type (e.g. well-known vs. unique)
 * @TP_DBUS_ERROR_INVALID_INTERFACE_NAME: Raised if a D-Bus interface or
 *  error name given is not valid
 * @TP_DBUS_ERROR_INVALID_OBJECT_PATH: Raised if a D-Bus object path
 *  given is not valid
 * @TP_DBUS_ERROR_INVALID_MEMBER_NAME: Raised if a D-Bus method or signal
 *  name given is not valid
 * @TP_DBUS_ERROR_OBJECT_REMOVED: A generic error which can be used with
 *  #TpProxy::invalidated to indicate an application-specific indication
 *  that the remote object no longer exists, if no more specific error
 *  is available.
 * @TP_DBUS_ERROR_CANCELLED: Raised from calls that re-enter the main
 *  loop (*_run_*) if they are cancelled
 * @TP_DBUS_ERROR_INCONSISTENT: Raised if information received from a remote
 *  object is inconsistent or otherwise obviously wrong (added in 0.7.17).
 *  See also %TP_ERROR_CONFUSED.
 *
 * #GError codes for use with the %TP_DBUS_ERRORS domain.
 *
 * Since 0.11.5, there is a corresponding #GEnumClass type,
 * %TP_TYPE_DBUS_ERROR.
 *
 * Since: 0.7.1
 */

/**
 * NUM_TP_DBUS_ERRORS: (skip)
 *
 * 1 more than the highest valid #TpDBusError at the time of compilation.
 * In new code, use %TP_NUM_DBUS_ERRORS instead.
 *
 * Since: 0.7.1
 */

/**
 * TP_NUM_DBUS_ERRORS:
 *
 * 1 more than the highest valid #TpDBusError at the time of compilation
 *
 * Since: 0.19.0
 */

/**
 * TP_TYPE_DBUS_ERROR:
 *
 * The #GEnumClass type of a #TpDBusError.
 *
 * Since: 0.11.5
 */

/**
 * SECTION:proxy
 * @title: TpProxy
 * @short_description: base class for Telepathy client proxy objects
 * @see_also: #TpChannel, #TpConnection, #TpConnectionManager
 *
 * #TpProxy is a base class for Telepathy client-side proxies, which represent
 * an object accessed via D-Bus and provide access to its methods and signals.
 *
 * Since: 0.7.1
 */

/**
 * SECTION:proxy-dbus-core
 * @title: TpProxy D-Bus core methods
 * @short_description: The D-Bus Introspectable, Peer and Properties interfaces
 * @see_also: #TpProxy
 *
 * All D-Bus objects support the Peer interface, and many support the
 * Introspectable and Properties interfaces.
 *
 * Since: 0.7.2
 */

/**
 * SECTION:proxy-tp-properties
 * @title: TpProxy Telepathy Properties
 * @short_description: The Telepathy Properties interface
 * @see_also: #TpProxy
 *
 * As well as #TpProxy, proxy.h includes auto-generated client wrappers for the
 * Telepathy Properties interface, which can be implemented by any type of
 * object.
 *
 * The Telepathy Properties interface should not be confused with the D-Bus
 * core Properties interface.
 *
 * Since: 0.7.1
 */

/**
 * SECTION:proxy-subclass
 * @title: TpProxy subclasses and mixins
 * @short_description: Providing extra functionality for a #TpProxy or
 *  subclass, or subclassing it
 * @see_also: #TpProxy
 *
 * The implementations of #TpProxy subclasses and "mixin" functions need
 * access to the underlying dbus-glib objects used to implement the
 * #TpProxy API.
 *
 * Mixin functions to implement particular D-Bus interfaces should usually
 * be auto-generated, by copying tools/glib-client-gen.py from telepathy-glib.
 *
 * Since: 0.7.1
 */

/**
 * TpProxy:
 *
 * Structure representing a Telepathy client-side proxy.
 *
 * Since: 0.7.1
 */

/**
 * TpProxyInterfaceAddedCb:
 * @self: the proxy
 * @quark: a quark whose string value is the interface being added
 * @proxy: the #DBusGProxy for the added interface
 * @unused: unused
 *
 * The signature of a #TpProxy::interface-added signal callback.
 *
 * Since: 0.7.1
 */

/**
 * TpProxyClass:
 * @parent_class: The parent class structure
 * @interface: If set non-zero by a subclass, #TpProxy will
 *    automatically add this interface in its constructor
 * @must_have_unique_name: If set %TRUE by a subclass, the #TpProxy
 *    constructor will fail if a well-known bus name is given
 *
 * The class of a #TpProxy. The struct fields not documented here are reserved.
 *
 * Since: 0.7.1
 */

/**
 * TpProxyPrepareAsync:
 * @proxy: the object on which @feature has to be prepared
 * @feature: a #GQuark representing the feature to prepare
 * @callback: called when the feature has been prepared, or the preparation
 * failed
 * @user_data: data to pass to @callback
 *
 * Function called when @feature has to be prepared for @proxy.
 */

/**
 * TpProxyFeature:
 * @name: a #GQuark representing the name of the feature
 * @core: if %TRUE, every non-core feature of the class depends on this one,
 * and every feature (core or not) in subclasses depends on this one
 * @prepare_async: called when the feature has to be prepared
 * @prepare_before_signalling_connected_async: only relevant for
 * TpConnection sub-classes; same as @prepare_async but for
 * features wanting to have a chance to prepare themself before the
 * TpConnection object announce its %TP_CONNECTION_STATUS_CONNECTED status
 * @interfaces_needed: an array of #GQuark representing interfaces which have
 * to be implemented on the object in order to be able to prepare the feature
 * @depends_on: an array of #GQuark representing other features which have to
 * be prepared before trying to prepare this feature
 * @can_retry: If %TRUE, allow retrying preparation of this feature even if it
 * failed once already; if %FALSE any attempt of preparing the feature after
 * the preparation already failed once will immediately fail with re-calling
 * @prepare_async
 *
 * Structure representing a feature.
 *
 * Since: 0.11.3
 */

/**
 * TpProxyClassFeatureListFunc:
 * @cls: a subclass of #TpProxyClass
 *
 * A function called to list the features supported by
 * tp_proxy_prepare_async(). Currently, only code inside telepathy-glib can
 * implement this.
 *
 * Returns: an array of feature descriptions
 *
 * Since: 0.11.3
 */

typedef struct _TpProxyErrorMappingLink TpProxyErrorMappingLink;

struct _TpProxyErrorMappingLink {
    const gchar *prefix;
    GQuark domain;
    GEnumClass *code_enum_class;
    TpProxyErrorMappingLink *next;
};

typedef struct _TpProxyInterfaceAddLink TpProxyInterfaceAddLink;

struct _TpProxyInterfaceAddLink {
    TpProxyInterfaceAddedCb callback;
    TpProxyInterfaceAddLink *next;
};

struct _TpProxyFeaturePrivate
{
  gpointer unused;
};

/**
 * TpProxyInvokeFunc:
 * @self: the #TpProxy on which the D-Bus method was invoked
 * @error: %NULL if the method call succeeded, or a non-%NULL error if the
 *  method call failed
 * @args: array of "out" arguments (return values) for the D-Bus method,
 *  or %NULL if an error occurred or if there were no "out" arguments
 * @callback: the callback that should be invoked, as passed to
 *  tp_proxy_pending_call_v0_new()
 * @user_data: user-supplied data to pass to the callback, as passed to
 *  tp_proxy_pending_call_v0_new()
 * @weak_object: user-supplied object to pass to the callback, as passed to
 *  tp_proxy_pending_call_v0_new()
 *
 * Signature of a callback invoked by the #TpProxy machinery after a D-Bus
 * method call has succeeded or failed. It is responsible for calling the
 * user-supplied callback.
 *
 * Because parts of dbus-glib aren't reentrant, this callback may be called
 * from an idle handler shortly after the method call reply is received,
 * rather than from the callback for the reply.
 *
 * At most one of @args and @error can be non-%NULL (implementations may
 * assert this). @args and @error may both be %NULL if a method with no
 * "out" arguments (i.e. a method that returns nothing) was called
 * successfully.
 *
 * The #TpProxyInvokeFunc must call callback with @user_data, @weak_object,
 * and appropriate arguments derived from @error and @args. It is responsible
 * for freeing @error and @args, if their ownership has not been transferred.
 *
 * Since: 0.7.1
 */

typedef enum {
    /* Not a feature */
    FEATURE_STATE_INVALID = GPOINTER_TO_INT (NULL),
    /* Nobody cares */
    FEATURE_STATE_UNWANTED,
    /* Want to prepare, waiting for dependencies to be satisfied (or maybe
     * just poll_features being called) */
    FEATURE_STATE_WANTED,
    /* Want to prepare, have called prepare_async */
    FEATURE_STATE_TRYING,
    /* Couldn't prepare because a required interface on the connection
     * was missing and the connection wasn't connected yet. We'll retry to
     * prepare once the connection is connected.
     * This state is only used when preparing Connection features */
    FEATURE_STATE_MISSING_IFACE,
    /* Couldn't prepare, gave up */
    FEATURE_STATE_FAILED,
    /* Prepared */
    FEATURE_STATE_READY
} FeatureState;

typedef struct {
    GSimpleAsyncResult *result;
    GArray *features;
    gboolean core;
} TpProxyPrepareRequest;

static TpProxyPrepareRequest *
tp_proxy_prepare_request_new (GSimpleAsyncResult *result,
    const GQuark *features)
{
  TpProxyPrepareRequest *req = g_slice_new0 (TpProxyPrepareRequest);

  if (result != NULL)
    req->result = g_object_ref (result);

  req->features = _tp_quark_array_copy (features);
  g_assert (req->features != NULL);
  return req;
}

static void
tp_proxy_prepare_request_finish (TpProxyPrepareRequest *req,
    const GError *error)
{
  DEBUG ("%p", req);

  if (req->result != NULL)
    {
      if (error != NULL)
        g_simple_async_result_set_from_error (req->result, error);

      g_simple_async_result_complete_in_idle (req->result);
      g_object_unref (req->result);
    }

  g_array_unref (req->features);
  g_slice_free (TpProxyPrepareRequest, req);
}

struct _TpProxyPrivate {
    /* GQuark for interface => either a ref'd DBusGProxy *,
     * or the TpProxy itself used as a dummy value to indicate that
     * the DBusGProxy has not been needed yet */
    GData *interfaces;

    /* feature => FeatureState */
    GData *features;

    /* Queue of TpProxyPrepareRequest. The first requests are the core one,
     * sorted from the most upper super class to the subclass core features.
     * This is needed to guarantee than subclass features are not prepared
     * until the super class features have been prepared. */
    GQueue *prepare_requests;

    GSimpleAsyncResult *will_announce_connected_result;
    /* Number of pending calls blocking will_announce_connected_result to be
     * completed */
    guint pending_will_announce_calls;

    gboolean dispose_has_run;

    TpSimpleClientFactory *factory;
};

G_DEFINE_TYPE (TpProxy, tp_proxy, G_TYPE_OBJECT)

enum
{
  PROP_DBUS_DAEMON = 1,
  PROP_DBUS_CONNECTION,
  PROP_BUS_NAME,
  PROP_OBJECT_PATH,
  PROP_INTERFACES,
  PROP_FACTORY,
  N_PROPS
};

enum {
    SIGNAL_INTERFACE_ADDED,
    SIGNAL_INVALIDATED,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};

static void tp_proxy_iface_destroyed_cb (DBusGProxy *dgproxy, TpProxy *self);

/**
 * tp_proxy_borrow_interface_by_id: (skip)
 * @self: the TpProxy
 * @iface: quark representing the interface required
 * @error: used to raise an error in the #TP_DBUS_ERRORS domain if @iface
 *         is invalid, @self has been invalidated or @self does not implement
 *         @iface
 *
 * <!-- -->
 *
 * Returns: a borrowed reference to a #DBusGProxy
 * for which the bus name and object path are the same as for @self, but the
 * interface is as given (or %NULL if an @error is raised).
 * The reference is only valid as long as @self is.
 *
 * Since: 0.7.1
 * Deprecated: Since 0.19.9. New code should use
 *  tp_proxy_get_interface_by_id() instead.
 */
DBusGProxy *
tp_proxy_borrow_interface_by_id (TpProxy *self,
                                 GQuark iface,
                                 GError **error)
{
  return tp_proxy_get_interface_by_id (self, iface, error);
}

/**
 * tp_proxy_get_interface_by_id: (skip)
 * @self: the TpProxy
 * @iface: quark representing the interface required
 * @error: used to raise an error in the #TP_DBUS_ERRORS domain if @iface
 *         is invalid, @self has been invalidated or @self does not implement
 *         @iface
 *
 * <!-- -->
 *
 * Returns: a borrowed reference to a #DBusGProxy
 * for which the bus name and object path are the same as for @self, but the
 * interface is as given (or %NULL if an @error is raised).
 * The reference is only valid as long as @self is.
 *
 * Since: 0.19.9
 */
DBusGProxy *
tp_proxy_get_interface_by_id (TpProxy *self,
                              GQuark iface,
                              GError **error)
{
  gpointer dgproxy;

  if (self->invalidated != NULL)
    {
      g_set_error (error, self->invalidated->domain, self->invalidated->code,
          "%s", self->invalidated->message);
      return NULL;
    }

  if (!tp_dbus_check_valid_interface_name (g_quark_to_string (iface),
        error))
      return NULL;

  dgproxy = g_datalist_id_get_data (&self->priv->interfaces, iface);

  if (dgproxy == self)
    {
      /* dummy value - we've never actually needed the interface, so we
       * didn't create it, to avoid binding to all the signals */

      dgproxy = dbus_g_proxy_new_for_name (self->dbus_connection,
          self->bus_name, self->object_path, g_quark_to_string (iface));
      DEBUG ("%p: %s DBusGProxy is %p", self, g_quark_to_string (iface),
          dgproxy);

      g_signal_connect (dgproxy, "destroy",
          G_CALLBACK (tp_proxy_iface_destroyed_cb), self);

      g_datalist_id_set_data_full (&self->priv->interfaces, iface,
          dgproxy, g_object_unref);

      g_signal_emit (self, signals[SIGNAL_INTERFACE_ADDED], 0,
          (guint) iface, dgproxy);
    }

  if (dgproxy != NULL)
    {
      return dgproxy;
    }

  g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_NO_INTERFACE,
      "Object %s does not have interface %s",
      self->object_path, g_quark_to_string (iface));

  return NULL;
}

/**
 * tp_proxy_has_interface_by_id:
 * @self: the #TpProxy (or subclass)
 * @iface: quark representing the D-Bus interface required
 *
 * Return whether this proxy is known to have a particular interface, by its
 * quark ID. This is equivalent to using g_quark_to_string() followed by
 * tp_proxy_has_interface(), but more efficient.
 *
 * Returns: %TRUE if this proxy implements the given interface.
 *
 * Since: 0.7.1
 */
gboolean
tp_proxy_has_interface_by_id (gpointer self,
                              GQuark iface)
{
  TpProxy *proxy = self;

  g_return_val_if_fail (TP_IS_PROXY (self), FALSE);

  return (g_datalist_id_get_data (&proxy->priv->interfaces, iface)
      != NULL);
}

/**
 * tp_proxy_has_interface:
 * @self: the #TpProxy (or subclass)
 * @iface: the D-Bus interface required, as a string
 *
 * Return whether this proxy is known to have a particular interface. In
 * versions older than 0.11.11, this was a macro wrapper around
 * tp_proxy_has_interface_by_id().
 *
 * For objects that discover their interfaces at runtime, this method will
 * indicate that interfaces are missing until they are known to be present.
 * In subclasses that define features for use with tp_proxy_prepare_async(),
 * successfully preparing the "core" feature for that subclass (such as
 * %TP_CHANNEL_FEATURE_CORE or %TP_CONNECTION_FEATURE_CORE) implies that the
 * interfaces are known.
 *
 * Returns: %TRUE if this proxy implements the given interface.
 * Since: 0.7.1
 */
gboolean
tp_proxy_has_interface (gpointer self,
    const gchar *iface)
{
  TpProxy *proxy = self;
  GQuark q = g_quark_try_string (iface);

  g_return_val_if_fail (TP_IS_PROXY (self), FALSE);

  return (q != 0 &&
    g_datalist_id_get_data (&proxy->priv->interfaces, q) != NULL);
}

static void
tp_proxy_lose_interface (GQuark unused,
                         gpointer dgproxy_or_self,
                         gpointer self)
{
  if (dgproxy_or_self != self)
    g_signal_handlers_disconnect_by_func (dgproxy_or_self,
        G_CALLBACK (tp_proxy_iface_destroyed_cb), self);
}

static void
tp_proxy_lose_interfaces (TpProxy *self)
{
  g_datalist_foreach (&self->priv->interfaces,
      tp_proxy_lose_interface, self);

  g_datalist_clear (&self->priv->interfaces);
}

static void tp_proxy_poll_features (TpProxy *self, const GError *error);

/* This signature is chosen to match GSourceFunc */
static gboolean
tp_proxy_emit_invalidated (gpointer p)
{
  TpProxy *self = TP_PROXY (p);

  g_signal_emit (self, signals[SIGNAL_INVALIDATED], 0,
      self->invalidated->domain, self->invalidated->code,
      self->invalidated->message);

  /* make all pending tp_proxy_prepare_async calls fail */
  tp_proxy_poll_features (self, NULL);
  g_assert_cmpuint (g_queue_get_length (self->priv->prepare_requests), ==, 0);

  /* Don't clear the datalist until after we've emitted the signal, so
   * the pending call and signal connection friend classes can still get
   * to the proxies */
  tp_proxy_lose_interfaces (self);

  if (self->dbus_connection != NULL)
    {
      dbus_g_connection_unref (self->dbus_connection);
      self->dbus_connection = NULL;
    }

  return FALSE;
}

/**
 * tp_proxy_invalidate:
 * @self: a proxy
 * @error: an error causing the invalidation
 *
 * Mark @self as having been invalidated - no further calls will work, and
 * if not already invalidated, the #TpProxy::invalidated signal will be emitted
 * with the given error.
 *
 * Since: 0.7.1
 */
void
tp_proxy_invalidate (TpProxy *self, const GError *error)
{
  g_return_if_fail (self != NULL);
  g_return_if_fail (error != NULL);

  if (self->invalidated == NULL)
    {
      DEBUG ("%p: %s", self, error->message);
      self->invalidated = g_error_copy (error);

      tp_proxy_emit_invalidated (self);
    }
}

static void
tp_proxy_iface_destroyed_cb (DBusGProxy *dgproxy,
                             TpProxy *self)
{
  /* We can't call any API on the proxy now. Because the proxies are all
   * for the same bus name, we can assume that all of them are equally
   * useless now */
  tp_proxy_lose_interfaces (self);

  /* We need to be able to delay emitting the invalidated signal, so that
   * any queued-up method calls and signal handlers will run first, and so
   * it doesn't try to reenter libdbus.
   */
  if (self->invalidated == NULL)
    {
      DEBUG ("%p", self);
      self->invalidated = g_error_new_literal (TP_DBUS_ERRORS,
          TP_DBUS_ERROR_NAME_OWNER_LOST, "Name owner lost (service crashed?)");

      g_idle_add_full (G_PRIORITY_HIGH, tp_proxy_emit_invalidated,
          g_object_ref (self), g_object_unref);
    }
}

/**
 * tp_proxy_add_interface_by_id: (skip)
 * @self: the TpProxy, which must not have become #TpProxy::invalidated.
 * @iface: quark representing the interface to be added
 *
 * Declare that this proxy supports a given interface.
 *
 * To use methods and signals of that interface, either call
 * tp_proxy_get_interface_by_id() to get the #DBusGProxy, or use the
 * tp_cli_* wrapper functions (strongly recommended).
 *
 * If the interface is the proxy's "main interface", or has already been
 * added, then do nothing.
 *
 * Returns: either %NULL or a borrowed #DBusGProxy corresponding to @iface,
 * depending on implementation details. To reliably borrow the #DBusGProxy, use
 * tp_proxy_get_interface_by_id(). (This method should probably have
 * returned void; sorry.)
 *
 * Since: 0.7.1
 */
DBusGProxy *
tp_proxy_add_interface_by_id (TpProxy *self,
                              GQuark iface)
{
  DBusGProxy *iface_proxy = g_datalist_id_get_data (&self->priv->interfaces,
      iface);

  g_return_val_if_fail
      (tp_dbus_check_valid_interface_name (g_quark_to_string (iface),
          NULL),
       NULL);

  g_return_val_if_fail (tp_proxy_get_invalidated (self) == NULL, NULL);

  if (iface_proxy == NULL)
    {
      /* we don't want to actually create it just yet - dbus-glib will
       * helpfully wake us up on every signal, if we do. So we set a
       * dummy value (self), and replace it with the real value in
       * tp_proxy_get_interface_by_id */
      g_datalist_id_set_data_full (&self->priv->interfaces, iface,
          self, NULL);
    }

  return iface_proxy;
}

/**
 * tp_proxy_add_interfaces: (skip)
 * @self: the TpProxy, which must not have become #TpProxy::invalidated.
 * @interfaces: the names of the interfaces to be added
 *
 * Declare that this proxy supports the given interfaces. Equivalent to calling
 * g_quark_from_string () followed by tp_proxy_add_interface_by_id () for each
 * of the interface names.
 *
 * Since: 0.14.4
 */
void
tp_proxy_add_interfaces (TpProxy *self,
    const gchar * const *interfaces)
{
  const gchar * const *iter;

  if (G_UNLIKELY (interfaces == NULL))
    return;

  for (iter = interfaces; *iter != NULL; iter++)
    {
      if (tp_dbus_check_valid_interface_name (*iter, NULL))
        {
          GQuark q = g_quark_from_string (*iter);

          tp_proxy_add_interface_by_id (self, q);
        }
      else
        {
          DEBUG ("Ignoring invalid interface on %s: %s",
              tp_proxy_get_object_path (self), *iter);
        }
    }
}

static GQuark
error_mapping_quark (void)
{
  static GQuark q = 0;

  if (G_UNLIKELY (q == 0))
    {
      q = g_quark_from_static_string ("TpProxyErrorMappingCb_0.7.1");
    }

  return q;
}

/**
 * tp_proxy_dbus_error_to_gerror:
 * @self: a #TpProxy or subclass
 * @dbus_error: a D-Bus error name, for instance from the callback for
 *              tp_cli_connection_connect_to_connection_error()
 * @debug_message: a debug message that accompanied the error name, or %NULL
 * @error: used to return the corresponding #GError
 *
 * Convert a D-Bus error name into a GError as if it was returned by a method
 * on this proxy. This method is useful when D-Bus error names are emitted in
 * signals, such as Connection.ConnectionError and
 * Group.MembersChangedDetailed.
 *
 * Since: 0.7.24
 */
void
tp_proxy_dbus_error_to_gerror (gpointer self,
                               const char *dbus_error,
                               const char *debug_message,
                               GError **error)
{
  GType proxy_type = TP_TYPE_PROXY;
  GType type;

  g_return_if_fail (TP_IS_PROXY (self));

  if (error == NULL)
    return;

  g_return_if_fail (*error == NULL);

  if (!tp_dbus_check_valid_interface_name (dbus_error, error))
    {
      return;
    }

  if (debug_message == NULL)
    debug_message = "";

  for (type = G_TYPE_FROM_INSTANCE (self);
       type != proxy_type;
       type = g_type_parent (type))
    {
      TpProxyErrorMappingLink *iter;

      for (iter = g_type_get_qdata (type, error_mapping_quark ());
           iter != NULL;
           iter = iter->next)
        {
          size_t prefix_len = strlen (iter->prefix);

          if (!strncmp (dbus_error, iter->prefix, prefix_len)
              && dbus_error[prefix_len] == '.')
            {
              GEnumValue *code =
                g_enum_get_value_by_nick (iter->code_enum_class,
                    dbus_error + prefix_len + 1);

              if (code != NULL)
                {
                  g_set_error (error, iter->domain, code->value,
                      "%s", debug_message);
                  return;
                }
            }
        }
    }

  /* we don't have an error mapping - so let's just paste the
   * error name and message into TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR */
  g_set_error (error, TP_DBUS_ERRORS,
      TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR, "%s: %s", dbus_error, debug_message);
}

GError *
_tp_proxy_take_and_remap_error (TpProxy *self,
                                GError *error)
{
  if (error == NULL ||
      error->domain != DBUS_GERROR ||
      error->code != DBUS_GERROR_REMOTE_EXCEPTION)
    {
      return error;
    }
  else
    {
      GError *replacement = NULL;
      const gchar *dbus = dbus_g_error_get_name (error);

      tp_proxy_dbus_error_to_gerror (self, dbus, error->message, &replacement);
      g_error_free (error);
      return replacement;
    }
}

static void
dup_quark_into_ptr_array (GQuark q,
                          gpointer unused,
                          gpointer user_data)
{
  GPtrArray *strings = user_data;

  g_ptr_array_add (strings, g_strdup (g_quark_to_string (q)));
}

static void
tp_proxy_get_property (GObject *object,
                       guint property_id,
                       GValue *value,
                       GParamSpec *pspec)
{
  TpProxy *self = TP_PROXY (object);

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
      if (TP_IS_DBUS_DAEMON (self))
        {
          g_value_set_object (value, self);
        }
      else
        {
          g_value_set_object (value, self->dbus_daemon);
        }
      break;
    case PROP_DBUS_CONNECTION:
      g_value_set_boxed (value, self->dbus_connection);
      break;
    case PROP_BUS_NAME:
      g_value_set_string (value, self->bus_name);
      break;
    case PROP_OBJECT_PATH:
      g_value_set_string (value, self->object_path);
      break;
    case PROP_INTERFACES:
        {
          GPtrArray *strings = g_ptr_array_new ();

          g_datalist_foreach (&self->priv->interfaces,
              dup_quark_into_ptr_array, strings);
          g_ptr_array_add (strings, NULL);
          g_value_take_boxed (value, g_ptr_array_free (strings, FALSE));
        }
      break;
    case PROP_FACTORY:
      g_value_set_object (value, self->priv->factory);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_proxy_set_property (GObject *object,
                       guint property_id,
                       const GValue *value,
                       GParamSpec *pspec)
{
  TpProxy *self = TP_PROXY (object);

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
      if (TP_IS_DBUS_DAEMON (self))
        {
          g_assert (g_value_get_object (value) == NULL);
        }
      else
        {
          TpProxy *daemon_as_proxy = TP_PROXY (g_value_get_object (value));

          g_assert (self->dbus_daemon == NULL);

          if (daemon_as_proxy != NULL)
            self->dbus_daemon = TP_DBUS_DAEMON (g_object_ref
                (daemon_as_proxy));

          if (daemon_as_proxy != NULL)
            {
              g_assert (self->dbus_connection == NULL ||
                  self->dbus_connection == daemon_as_proxy->dbus_connection);

              if (self->dbus_connection == NULL)
                self->dbus_connection =
                    dbus_g_connection_ref (daemon_as_proxy->dbus_connection);
            }
        }
      break;
    case PROP_DBUS_CONNECTION:
        {
          DBusGConnection *conn = g_value_get_boxed (value);

          /* if we're given a NULL dbus-connection, but we've got a
           * DBusGConnection from the dbus-daemon, we want to keep it */
          if (conn == NULL)
            return;

          if (self->dbus_connection == NULL)
            self->dbus_connection = g_value_dup_boxed (value);

          g_assert (self->dbus_connection == g_value_get_boxed (value));
        }
      break;
    case PROP_BUS_NAME:
      g_assert (self->bus_name == NULL);
      self->bus_name = g_value_dup_string (value);
      break;
    case PROP_OBJECT_PATH:
      g_assert (self->object_path == NULL);
      self->object_path = g_value_dup_string (value);
      break;
    case PROP_FACTORY:
      g_assert (self->priv->factory == NULL);
      self->priv->factory = g_value_dup_object (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_proxy_init (TpProxy *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_PROXY,
      TpProxyPrivate);

  self->priv->prepare_requests = g_queue_new ();
}

static GQuark
interface_added_cb_quark (void)
{
  static GQuark q = 0;

  if (G_UNLIKELY (q == 0))
    {
      q = g_quark_from_static_string ("TpProxyInterfaceAddedCb_0.7.1");
    }

  return q;
}

static FeatureState
tp_proxy_get_feature_state (TpProxy *self,
    GQuark feature)
{
  return GPOINTER_TO_INT (g_datalist_id_get_data (&self->priv->features,
        feature));
}

static void
tp_proxy_set_feature_state (TpProxy *self,
    GQuark feature,
    FeatureState state)
{
  g_datalist_id_set_data (&self->priv->features, feature,
      GINT_TO_POINTER (state));
}

static void
assert_feature_validity (TpProxy *self,
    const TpProxyFeature *feature)
{
  g_assert (feature != NULL);

  /* Core features can't have depends, their depends are implicit */
  if (feature->core)
    g_assert (feature->depends_on == NULL || feature->depends_on[0] == 0);

  /* prepare_before_signalling_connected_async only make sense for
   * TpConnection subclasses */
  if (feature->prepare_before_signalling_connected_async != NULL)
    g_assert (TP_IS_CONNECTION (self));
}

static GObject *
tp_proxy_constructor (GType type,
                      guint n_params,
                      GObjectConstructParam *params)
{
  GObjectClass *object_class = (GObjectClass *) tp_proxy_parent_class;
  TpProxy *self = TP_PROXY (object_class->constructor (type,
        n_params, params));
  TpProxyClass *klass = TP_PROXY_GET_CLASS (self);
  TpProxyInterfaceAddLink *iter;
  GType proxy_parent_type = G_TYPE_FROM_CLASS (tp_proxy_parent_class);
  GType ancestor_type;

  _tp_register_dbus_glib_marshallers ();

  for (ancestor_type = type;
       ancestor_type != proxy_parent_type && ancestor_type != 0;
       ancestor_type = g_type_parent (ancestor_type))
    {
      TpProxyClass *ancestor = g_type_class_peek (ancestor_type);
      const TpProxyFeature *features;
      guint i;
      GArray *core_features;

      for (iter = g_type_get_qdata (ancestor_type,
              interface_added_cb_quark ());
           iter != NULL;
           iter = iter->next)
        g_signal_connect (self, "interface-added", G_CALLBACK (iter->callback),
            NULL);

      if (ancestor == NULL || ancestor->list_features == NULL)
        continue;

      features = ancestor->list_features (ancestor);

      if (features == NULL)
        continue;

      core_features = g_array_new (TRUE, FALSE, sizeof (GQuark));

      for (i = 0; features[i].name != 0; i++)
        {
          assert_feature_validity (self, &features[i]);

          tp_proxy_set_feature_state (self, features[i].name,
              FEATURE_STATE_UNWANTED);

          if (features[i].core)
            {
              g_array_append_val (core_features, features[i].name);
            }
        }

      if (core_features->len > 0)
        {
          TpProxyPrepareRequest *req;

          req = tp_proxy_prepare_request_new (NULL,
              (const GQuark *) core_features->data);
          req->core = TRUE;

          g_queue_push_head (self->priv->prepare_requests, req);

          DEBUG ("%p: request %p represents core features on %s", self, req,
              g_type_name (ancestor_type));
        }

      g_array_unref (core_features);
    }

  g_return_val_if_fail (self->dbus_connection != NULL, NULL);
  g_return_val_if_fail (self->object_path != NULL, NULL);
  g_return_val_if_fail (self->bus_name != NULL, NULL);

  g_return_val_if_fail (tp_dbus_check_valid_object_path (self->object_path,
        NULL), NULL);
  g_return_val_if_fail (tp_dbus_check_valid_bus_name (self->bus_name,
        TP_DBUS_NAME_TYPE_ANY, NULL), NULL);

  tp_proxy_add_interface_by_id (self, TP_IFACE_QUARK_DBUS_INTROSPECTABLE);
  tp_proxy_add_interface_by_id (self, TP_IFACE_QUARK_DBUS_PEER);
  tp_proxy_add_interface_by_id (self, TP_IFACE_QUARK_DBUS_PROPERTIES);

  if (klass->interface != 0)
    {
      tp_proxy_add_interface_by_id (self, klass->interface);
    }

  /* Some interfaces are stateful, so we only allow binding to a unique
   * name, like in dbus_g_proxy_new_for_name_owner() */
  if (klass->must_have_unique_name)
    {
      g_return_val_if_fail (self->bus_name[0] == ':', NULL);
    }

  return (GObject *) self;
}

static GQuark const no_quarks[] = { 0 };

static void
tp_proxy_dispose (GObject *object)
{
  TpProxy *self = TP_PROXY (object);
  GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_PROXY_UNREFERENCED,
      "Proxy unreferenced" };

  if (self->priv->dispose_has_run)
    return;
  self->priv->dispose_has_run = TRUE;

  DEBUG ("%p", self);

  tp_proxy_invalidate (self, &e);

  tp_clear_object (&self->dbus_daemon);
  tp_clear_object (&self->priv->factory);

  G_OBJECT_CLASS (tp_proxy_parent_class)->dispose (object);
}

static void
tp_proxy_finalize (GObject *object)
{
  TpProxy *self = TP_PROXY (object);

  DEBUG ("%p", self);

  if (self->priv->features != NULL)
    g_datalist_clear (&self->priv->features);

  g_assert (self->invalidated != NULL);
  g_error_free (self->invalidated);

  /* invalidation ensures that these have gone away */
  g_assert_cmpuint (g_queue_get_length (self->priv->prepare_requests), ==, 0);
  tp_clear_pointer (&self->priv->prepare_requests, g_queue_free);

  g_free (self->bus_name);
  g_free (self->object_path);

  G_OBJECT_CLASS (tp_proxy_parent_class)->finalize (object);
}

/**
 * tp_proxy_or_subclass_hook_on_interface_add:
 * @proxy_or_subclass: The #GType of #TpProxy or a subclass
 * @callback: A signal handler for #TpProxy::interface-added
 *
 * Arrange for @callback to be connected to #TpProxy::interface-added
 * during the #TpProxy constructor. This is done sufficiently early that
 * it will see the signal for the default interface (@interface member of
 * #TpProxyClass), if any, being added. The intended use is for the callback
 * to call dbus_g_proxy_add_signal() on the new #DBusGProxy.
 *
 * Since 0.7.6, to ensure correct overriding of interfaces that might be
 * added to telepathy-glib, before calling this function you should
 * call tp_proxy_init_known_interfaces, tp_connection_init_known_interfaces,
 * tp_channel_init_known_interfaces etc. as appropriate for the subclass.
 *
 * Since: 0.7.1
 */
void
tp_proxy_or_subclass_hook_on_interface_add (GType proxy_or_subclass,
    TpProxyInterfaceAddedCb callback)
{
  GQuark q = interface_added_cb_quark ();
  TpProxyInterfaceAddLink *old_link = g_type_get_qdata (proxy_or_subclass, q);
  TpProxyInterfaceAddLink *new_link;

  g_return_if_fail (g_type_is_a (proxy_or_subclass, TP_TYPE_PROXY));
  g_return_if_fail (callback != NULL);

  /* never freed, suppressed in telepathy-glib.supp */
  new_link = g_slice_new0 (TpProxyInterfaceAddLink);
  new_link->callback = callback;
  new_link->next = old_link;    /* may be NULL */
  g_type_set_qdata (proxy_or_subclass, q, new_link);
}

/**
 * tp_proxy_subclass_add_error_mapping:
 * @proxy_subclass: The #GType of a subclass of #TpProxy (which must not be
 *  #TpProxy itself)
 * @static_prefix: A prefix for D-Bus error names, not including the trailing
 *  dot (which must remain valid forever, and should usually be in static
 *  storage)
 * @domain: A quark representing the corresponding #GError domain
 * @code_enum_type: The type of a subclass of #GEnumClass
 *
 * Register a mapping from D-Bus errors received from the given proxy
 * subclass to #GError instances.
 *
 * When a D-Bus error is received, the #TpProxy code checks for error
 * mappings registered for the class of the proxy receiving the error,
 * then for all of its parent classes.
 *
 * If there is an error mapping for which the D-Bus error name
 * starts with the mapping's @static_prefix, the proxy will check the
 * corresponding @code_enum_type for a value whose @value_nick is
 * the rest of the D-Bus error name (with the leading dot removed). If there
 * isn't such a value, it will continue to try other error mappings.
 *
 * If a suitable error mapping and code are found, the #GError that is raised
 * will have its error domain set to the @domain from the error mapping,
 * and its error code taken from the enum represented by the @code_enum_type.
 *
 * If no suitable error mapping or code is found, the #GError will have
 * error domain %TP_DBUS_ERRORS and error code
 * %TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR.
 *
 * Since: 0.7.1
 */
void
tp_proxy_subclass_add_error_mapping (GType proxy_subclass,
                                     const gchar *static_prefix,
                                     GQuark domain,
                                     GType code_enum_type)
{
  GQuark q = error_mapping_quark ();
  TpProxyErrorMappingLink *old_link = g_type_get_qdata (proxy_subclass, q);
  TpProxyErrorMappingLink *new_link;
  GType tp_type_proxy = TP_TYPE_PROXY;

  g_return_if_fail (proxy_subclass != tp_type_proxy);
  g_return_if_fail (g_type_is_a (proxy_subclass, tp_type_proxy));
  g_return_if_fail (static_prefix != NULL);
  g_return_if_fail (domain != 0);
  g_return_if_fail (code_enum_type != G_TYPE_INVALID);

  new_link = g_slice_new0 (TpProxyErrorMappingLink);
  new_link->prefix = static_prefix;
  new_link->domain = domain;
  /* We never unref the enum type - intentional one-per-process leak.
   * See "tp_proxy_subclass_add_error_mapping refs the enum" in our valgrind
   * suppressions file */
  new_link->code_enum_class = g_type_class_ref (code_enum_type);
  new_link->next = old_link;    /* may be NULL */
  g_type_set_qdata (proxy_subclass, q, new_link);
}

static void
tp_proxy_class_init (TpProxyClass *klass)
{
  GParamSpec *param_spec;
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  tp_proxy_init_known_interfaces ();

  g_type_class_add_private (klass, sizeof (TpProxyPrivate));

  object_class->constructor = tp_proxy_constructor;
  object_class->get_property = tp_proxy_get_property;
  object_class->set_property = tp_proxy_set_property;
  object_class->dispose = tp_proxy_dispose;
  object_class->finalize = tp_proxy_finalize;

  /**
   * TpProxy:dbus-daemon:
   *
   * The D-Bus daemon for this object (this object itself, if it is a
   * TpDBusDaemon). Read-only except during construction.
   */
  param_spec = g_param_spec_object ("dbus-daemon", "D-Bus daemon",
      "The D-Bus daemon used by this object, or this object itself if it's "
      "a TpDBusDaemon", TP_TYPE_DBUS_DAEMON,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON,
      param_spec);

  /**
   * TpProxy:dbus-connection: (skip)
   *
   * The D-Bus connection for this object. Read-only except during
   * construction.
   */
  param_spec = g_param_spec_boxed ("dbus-connection", "D-Bus connection",
      "The D-Bus connection used by this object", DBUS_TYPE_G_CONNECTION,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_CONNECTION,
      param_spec);

  /**
   * TpProxy:bus-name:
   *
   * The D-Bus bus name for this object. Read-only except during construction.
   */
  param_spec = g_param_spec_string ("bus-name", "D-Bus bus name",
      "The D-Bus bus name for this object", NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BUS_NAME,
      param_spec);

  /**
   * TpProxy:object-path:
   *
   * The D-Bus object path for this object. Read-only except during
   * construction.
   */
  param_spec = g_param_spec_string ("object-path", "D-Bus object path",
      "The D-Bus object path for this object", NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_OBJECT_PATH,
      param_spec);

  /**
   * TpProxy:interfaces:
   *
   * Known D-Bus interface names for this object.
   */
  param_spec = g_param_spec_boxed ("interfaces", "D-Bus interfaces",
      "Known D-Bus interface names for this object", G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INTERFACES,
      param_spec);

  /**
   * TpProxy:factory:
   *
   * The #TpSimpleClientFactory used to create this proxy,
   * or %NULL if this proxy was not created through a factory.
   */
  param_spec = g_param_spec_object ("factory", "Simple Client Factory",
      "The TpSimpleClientFactory used to create this proxy",
      TP_TYPE_SIMPLE_CLIENT_FACTORY,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_FACTORY,
      param_spec);

  /**
   * TpProxy::interface-added: (skip)
   * @self: the proxy object
   * @id: the GQuark representing the interface
   * @proxy: the dbus-glib proxy representing the interface
   *
   * Emitted when this proxy has gained an interface. It is not guaranteed
   * to be emitted immediately, but will be emitted before the interface is
   * first used (at the latest: before it's returned from
   * tp_proxy_get_interface_by_id(), any signal is connected, or any
   * method is called).
   *
   * The intended use is to call dbus_g_proxy_add_signals(). This signal
   * should only be used by TpProy implementations
   */
  signals[SIGNAL_INTERFACE_ADDED] = g_signal_new ("interface-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, G_TYPE_UINT, DBUS_TYPE_G_PROXY);

  /**
   * TpProxy::invalidated:
   * @self: the proxy object
   * @domain: domain of a GError indicating why this proxy was invalidated
   * @code: error code of a GError indicating why this proxy was invalidated
   * @message: a message associated with the error
   *
   * Emitted when this proxy has been become invalid for
   * whatever reason. Any more specific signal should be emitted first.
   *
   * An invalidated proxy is one which can make no more method calls and will
   * emit no more D-Bus signals. This is typically because the D-Bus object
   * represented by the proxy ceased to exist, or there was some error
   * obtaining the initial state.
   *
   * Any pending or future method calls made on this proxy will fail gracefully
   * with the same error as returned by tp_proxy_get_invalidated().
   */
  signals[SIGNAL_INVALIDATED] = g_signal_new ("invalidated",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3, G_TYPE_UINT, G_TYPE_INT, G_TYPE_STRING);
}

/**
 * tp_proxy_get_factory:
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: (transfer none): the same value as #TpProxy:factory property
 *
 * Since: 0.15.5
 */
TpSimpleClientFactory *
tp_proxy_get_factory (gpointer self)
{
  TpProxy *proxy = self;

  g_return_val_if_fail (TP_IS_PROXY (self), NULL);

  return proxy->priv->factory;
}

void
_tp_proxy_ensure_factory (gpointer proxy,
    TpSimpleClientFactory *factory)
{
  TpProxy *self = TP_PROXY (proxy);

  if (self->priv->factory != NULL)
    return;

  if (factory != NULL)
    {
      self->priv->factory = g_object_ref (factory);
    }
  else
    {
      self->priv->factory = (TpSimpleClientFactory *)
          tp_automatic_client_factory_new (self->dbus_daemon);
    }

  _tp_simple_client_factory_insert_proxy (self->priv->factory, self);
}

/**
 * tp_proxy_get_dbus_daemon:
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: (transfer none): a borrowed reference to the #TpDBusDaemon for
 *  this object, if any; always %NULL if this object is itself a
 *  #TpDBusDaemon. The caller must reference the returned object with
 *  g_object_ref() if it will be kept.
 *
 * Since: 0.7.17
 */
TpDBusDaemon *
tp_proxy_get_dbus_daemon (gpointer self)
{
  TpProxy *proxy = TP_PROXY (self);

  return proxy->dbus_daemon;
}

/**
 * tp_proxy_get_dbus_connection: (skip)
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: a borrowed reference to the D-Bus connection used by this object.
 *  The caller must reference the returned pointer with
 *  dbus_g_connection_ref() if it will be kept.
 *
 * Since: 0.7.17
 */
DBusGConnection *
tp_proxy_get_dbus_connection (gpointer self)
{
  TpProxy *proxy = TP_PROXY (self);

  return proxy->dbus_connection;
}

/**
 * tp_proxy_get_bus_name:
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: the bus name of the application exporting the object. The caller
 *  must copy the string with g_strdup() if it will be kept.
 *
 * Since: 0.7.17
 */
const gchar *
tp_proxy_get_bus_name (gpointer self)
{
  TpProxy *proxy = TP_PROXY (self);

  return proxy->bus_name;
}

/**
 * tp_proxy_get_object_path:
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: the object path of the remote object. The caller must copy the
 *  string with g_strdup() if it will be kept.
 *
 * Since: 0.7.17
 */
const gchar *
tp_proxy_get_object_path (gpointer self)
{
  TpProxy *proxy = TP_PROXY (self);

  return proxy->object_path;
}

/**
 * tp_proxy_get_invalidated:
 * @self: a #TpProxy or subclass
 *
 * <!-- -->
 *
 * Returns: the reason this proxy was invalidated, or %NULL if has not been
 *  invalidated. The caller must copy the error, for instance with
 *  g_error_copy(), if it will be kept.
 *
 * Since: 0.7.17
 */
const GError *
tp_proxy_get_invalidated (gpointer self)
{
  TpProxy *proxy = TP_PROXY (self);

  return proxy->invalidated;
}

/**
 * tp_proxy_dbus_g_proxy_claim_for_signal_adding:
 * @proxy: a #DBusGProxy
 *
 * Attempt to "claim" a #DBusGProxy for addition of signal signatures.
 * If this function has not been called on @proxy before, %TRUE is
 * returned, and the caller may safely call dbus_g_proxy_add_signal()
 * on @proxy. If this function has already been caled, %FALSE is
 * returned, and the caller may not safely call dbus_g_proxy_add_signal().
 *
 * This is intended for use by auto-generated signal-adding functions,
 * to allow interfaces provided as local extensions to override those in
 * telepathy-glib without causing assertion failures.
 *
 * Returns: %TRUE if it is safe to call dbus_g_proxy_add_signal()
 * Since: 0.7.6
 */
gboolean
tp_proxy_dbus_g_proxy_claim_for_signal_adding (DBusGProxy *proxy)
{
  static GQuark q = 0;

  g_return_val_if_fail (proxy != NULL, FALSE);

  if (G_UNLIKELY (q == 0))
    {
      q = g_quark_from_static_string (
          "tp_proxy_dbus_g_proxy_claim_for_signal_adding@0.7.6");
    }

  if (g_object_get_qdata ((GObject *) proxy, q) != NULL)
    {
      /* Someone else has already added signal signatures for this interface.
       * We can't do it again or it'll cause an assertion */
      return FALSE;
    }

  /* the proxy is just used as qdata here because it's a convenient
   * non-NULL pointer */
  g_object_set_qdata ((GObject *) proxy, q, proxy);
  return TRUE;
}

static gpointer
tp_proxy_once (gpointer data G_GNUC_UNUSED)
{
  GType type = TP_TYPE_PROXY;

  tp_proxy_or_subclass_hook_on_interface_add (type,
      tp_cli_generic_add_signals);

  return NULL;
}

/**
 * tp_proxy_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpProxy have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add().
 *
 * Functions like tp_connection_init_known_interfaces and
 * tp_channel_init_known_interfaces do this automatically.
 *
 * Since: 0.7.6
 */
void
tp_proxy_init_known_interfaces (void)
{
  static GOnce once = G_ONCE_INIT;

  g_once (&once, tp_proxy_once, NULL);
}

static const TpProxyFeature *
tp_proxy_subclass_get_feature (GType type,
    GQuark feature)
{
  GType proxy_type = TP_TYPE_PROXY;

  g_return_val_if_fail (g_type_is_a (type, proxy_type), NULL);

  /* we stop at proxy_type since we know that TpProxy has no features */
  for ( ; type != proxy_type; type = g_type_parent (type))
    {
      guint i;
      TpProxyClass *cls = g_type_class_ref (type);
      const TpProxyFeature *features;

      if (cls->list_features == NULL)
        goto cont;

      features = cls->list_features (cls);

      if (features == NULL)
        goto cont;

      for (i = 0; features[i].name != 0; i++)
        {
          if (features[i].name == feature)
            {
              g_type_class_unref (cls);
              return features + i;
            }
        }

cont:
      g_type_class_unref (cls);
    }

  return FALSE;
}

/**
 * tp_proxy_is_prepared:
 * @self: an instance of a #TpProxy subclass
 * @feature: a feature that is supported by @self's class
 *
 * Return %TRUE if @feature has been prepared successfully, or %FALSE if
 * @feature has not been requested, has not been prepared yet, or is not
 * available on this object at all.
 *
 * (For instance, if @feature is %TP_CHANNEL_FEATURE_CHAT_STATES and @self
 * is a #TpChannel in a protocol that doesn't actually implement chat states,
 * or is not a #TpChannel at all, then this method will return %FALSE.)
 *
 * To prepare features, call tp_proxy_prepare_async().
 *
 * Returns: %TRUE if @feature has been prepared successfully
 *
 * Since: 0.11.3
 */
gboolean
tp_proxy_is_prepared (gpointer self,
    GQuark feature)
{
  FeatureState state;

  g_return_val_if_fail (TP_IS_PROXY (self), FALSE);

  if (tp_proxy_get_invalidated (self) != NULL)
    return FALSE;

  state = tp_proxy_get_feature_state (self, feature);

  return (state == FEATURE_STATE_READY);
}

/*
 * _tp_proxy_is_preparing:
 * @self: an instance of a #TpProxy subclass
 * @feature: a feature that is supported by @self's class
 *
 * Return %TRUE if @feature has been requested, but has not been prepared
 * successfully or unsuccessfully yet.
 *
 * It is an error to use a @feature not specifically supported by @self - for
 * instance, it is an error to use %TP_CHANNEL_FEATURE_CHAT_STATES on any
 * #TpProxy that is not also a #TpChannel.
 *
 * Subclasses of #TpProxy should use this method to check whether to take
 * action for a particular feature. For instance, #TpChannel could call this
 * method for %TP_CHANNEL_CHAT_STATES when it discovers that the ChatStates
 * interface is supported, to decide whether to fetch the state of that
 * interface.
 *
 * Returns: %TRUE if @feature has been requested, but preparing it has neither
 *  succeeded nor failed yet
 */
gboolean
_tp_proxy_is_preparing (gpointer self,
    GQuark feature)
{
  FeatureState state;

  g_return_val_if_fail (TP_IS_PROXY (self), FALSE);

  if (tp_proxy_get_invalidated (self) != NULL)
    return FALSE;

  state = tp_proxy_get_feature_state (self, feature);
  g_return_val_if_fail (state != FEATURE_STATE_INVALID, FALSE);
  return (state == FEATURE_STATE_WANTED || state == FEATURE_STATE_TRYING);
}

static gboolean
check_feature_interfaces (TpProxy *self,
    GQuark name)
{
  const TpProxyFeature *feature = tp_proxy_subclass_get_feature (
      G_OBJECT_TYPE (self), name);
  guint i;

  if (feature->interfaces_needed == NULL)
    return TRUE;

  for (i = 0; feature->interfaces_needed[i] != 0; i++)
    {
      if (!tp_proxy_has_interface_by_id (self, feature->interfaces_needed[i]))
        {
          DEBUG ("Proxy doesn't implement %s, can't prepare feature %s",
              g_quark_to_string (feature->interfaces_needed[i]),
              g_quark_to_string (name));

          return FALSE;
        }
    }

  return TRUE;
}

/* Returns %TRUE if all the deps of @name are ready
 * @can_retry: if %TRUE dependencies which have failed but have
 * TpProxyFeature.can_retry won't be considered as having failed so we'll
 * still have a change to retry preparing those.
 * @failed: (out): %TRUE if one of @name's dep can't be prepared and so
 * @name can't be either
 */
static gboolean
check_depends_ready (TpProxy *self,
    GQuark name,
    gboolean can_retry,
    gboolean *failed)
{
  const TpProxyFeature *feature = tp_proxy_subclass_get_feature (
      G_OBJECT_TYPE (self), name);
  guint i;
  gboolean ready = TRUE;

  g_assert (failed != NULL);
  *failed = FALSE;

  if (feature->depends_on == NULL)
    return TRUE;

  for (i = 0; feature->depends_on[i] != 0; i++)
    {
      GQuark dep = feature->depends_on[i];
      const TpProxyFeature *dep_feature = tp_proxy_subclass_get_feature (
          G_OBJECT_TYPE (self), dep);
      FeatureState dep_state;

      dep_state = tp_proxy_get_feature_state (self, dep);
      switch (dep_state)
        {
          case FEATURE_STATE_INVALID:
            DEBUG ("Can't prepare %s, because %s (a dependency) is "
                "invalid", g_quark_to_string (name), g_quark_to_string (dep));

            *failed = TRUE;
            return FALSE;

          case FEATURE_STATE_FAILED:
          case FEATURE_STATE_MISSING_IFACE:
            if (!can_retry || !dep_feature->can_retry)
              {
                DEBUG ("Can't prepare %s, because %s (a dependency) is "
                    "failed to prepare",
                    g_quark_to_string (name), g_quark_to_string (dep));

                *failed = TRUE;
                return FALSE;
              }

            DEBUG ("retry preparing dep: %s", g_quark_to_string (dep));
            tp_proxy_set_feature_state (self, dep, FEATURE_STATE_WANTED);
            ready = FALSE;
            break;

          case FEATURE_STATE_UNWANTED:
          case FEATURE_STATE_WANTED:
          case FEATURE_STATE_TRYING:
            ready = FALSE;
            break;

          case FEATURE_STATE_READY:
            break;
        }
    }

  return ready;
}

static void
depends_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpProxy *self = TP_PROXY (source);

  tp_proxy_poll_features (self, NULL);
}

static void
prepare_depends (TpProxy *self,
    GQuark name)
{
  const TpProxyFeature *feature;

  feature = tp_proxy_subclass_get_feature (G_OBJECT_TYPE (self), name);
  g_assert (feature->depends_on != NULL);

  tp_proxy_prepare_async (self, feature->depends_on, depends_prepare_cb, NULL);
}

/**
 * tp_proxy_prepare_async:
 * @self: an instance of a #TpProxy subclass
 * @features: (transfer none) (array zero-terminated=1) (allow-none): an array
 *  of desired features, ending with 0; %NULL is equivalent to an array
 *  containing only 0
 * @callback: if not %NULL, called exactly once, when the features have all
 *  been prepared or failed to prepare, or after the proxy is invalidated
 * @user_data: user data for @callback
 *
 * #TpProxy itself does not support any features, but subclasses like
 * #TpChannel can support features, which can either be core functionality like
 * %TP_CHANNEL_FEATURE_CORE, or extended functionality like
 * %TP_CHANNEL_FEATURE_CHAT_STATES.
 *
 * Proxy instances start with no features prepared. When features are
 * requested via tp_proxy_prepare_async(), the proxy starts to do the
 * necessary setup to use those features.
 *
 * tp_proxy_prepare_async() always waits for core functionality of the proxy's
 * class to be prepared, even if it is not specifically requested: for
 * instance, because %TP_CHANNEL_FEATURE_CORE is core functionality of a
 * #TpChannel,
 *
 * |[
 * TpChannel *channel = ...;
 *
 * tp_proxy_prepare_async (channel, NULL, callback, user_data);
 * ]|
 *
 * is equivalent to
 *
 * |[
 * TpChannel *channel = ...;
 * GQuark features[] = { TP_CHANNEL_FEATURE_CORE, 0 };
 *
 * tp_proxy_prepare_async (channel, features, callback, user_data);
 * ]|
 *
 * If a feature represents core functionality (like %TP_CHANNEL_FEATURE_CORE),
 * failure to prepare it will result in tp_proxy_prepare_async() finishing
 * unsuccessfully: if failure to prepare the feature indicates that the proxy
 * is no longer useful, it will also emit #TpProxy::invalidated.
 *
 * If a feature represents non-essential functionality
 * (like %TP_CHANNEL_FEATURE_CHAT_STATES), or is not supported by the object
 * at all, then failure to prepare it is not fatal:
 * tp_proxy_prepare_async() will complete successfully, but
 * tp_proxy_is_prepared() will still return %FALSE for the feature, and
 * accessor methods for the feature will typically return a dummy value.
 *
 * Some #TpProxy subclasses automatically start to prepare their core
 * features when instantiated, and features will sometimes become prepared as
 * a side-effect of other actions, but to ensure that a feature is present you
 * must generally call tp_proxy_prepare_async() and wait for the result.
 *
 * Since: 0.11.3
 */
void
tp_proxy_prepare_async (gpointer self,
    const GQuark *features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpProxy *proxy = self;
  GSimpleAsyncResult *result = NULL;
  guint i;

  g_return_if_fail (TP_IS_PROXY (self));

  if (features == NULL)
    features = no_quarks;

  for (i = 0; features[i] != 0; i++)
    {
      FeatureState state = tp_proxy_get_feature_state (self, features[i]);
      const TpProxyFeature *feature = tp_proxy_subclass_get_feature (
          G_OBJECT_TYPE (self), features[i]);

      /* We just skip unknown features, which have state FEATURE_STATE_INVALID
       * (this doesn't seem ideal, but is
       * consistent with TpAccountManager's existing behaviour) */
      if (state == FEATURE_STATE_INVALID)
        {
          continue;
        }
      else if (state == FEATURE_STATE_UNWANTED ||
          (state == FEATURE_STATE_FAILED && feature->can_retry))
        {
          gboolean failed;

          /* Check deps. We only offer there the chance to retry a previously
           * failed dependency. Doing it in tp_proxy_poll_features() could
           * result in an infinite loop if we'd depends on 2 features which
           * are constantly failing. */
          if (!check_depends_ready (self, features[i], TRUE, &failed))
            {
              if (failed)
                {
                  /* We can't prepare the feature because of its deps */
                  tp_proxy_set_feature_state (self, features[i],
                      FEATURE_STATE_FAILED);
                  continue;
                }

              prepare_depends (self, features[i]);
            }

          tp_proxy_set_feature_state (self, features[i], FEATURE_STATE_WANTED);
        }
    }

  if (callback != NULL)
    result = g_simple_async_result_new (self, callback, user_data,
        tp_proxy_prepare_async);

  if (proxy->invalidated != NULL)
    {
      if (result != NULL)
        {
          g_simple_async_result_set_from_error (result, proxy->invalidated);
          g_simple_async_result_complete_in_idle (result);
        }

      goto finally;
    }

  g_queue_push_tail (proxy->priv->prepare_requests,
      tp_proxy_prepare_request_new (result, features));
  tp_proxy_poll_features (proxy, NULL);

finally:
  if (result != NULL)
    g_object_unref (result);
}

/**
 * tp_proxy_prepare_finish:
 * @self: an instance of a #TpProxy subclass
 * @result: the result passed to the callback of tp_proxy_prepare_async()
 * @error: used to return an error if %FALSE is returned
 *
 * Check for error in a call to tp_proxy_prepare_async(). An error here
 * generally indicates that either the asynchronous call was cancelled,
 * or @self has emitted #TpProxy::invalidated.
 *
 * Returns: %FALSE (setting @error) if tp_proxy_prepare_async() failed
 *  or was cancelled
 *
 * Since: 0.11.3
 */
gboolean
tp_proxy_prepare_finish (gpointer self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_proxy_prepare_async);
}

static gboolean
prepare_finish (TpProxy *self,
    GAsyncResult *result,
    gpointer source,
    GError **error)
{
  _tp_implement_finish_void (self, source);
}

static void
feature_prepared_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpProxy *self = TP_PROXY (source);
  TpProxyFeature *feature = user_data;
  GError *error = NULL;
  gboolean prepared = TRUE;

  if (!prepare_finish (self, result, feature->prepare_async, &error))
    {
      DEBUG ("Failed to prepare %s: %s", g_quark_to_string (feature->name),
          error->message);

      prepared = FALSE;
      g_error_free (error);
    }

  _tp_proxy_set_feature_prepared (self, feature->name, prepared);
}

static void
prepare_feature (TpProxy *self,
    const TpProxyFeature *feature)
{
  /* If no function is set, then subclass is supposed to call
   * _tp_proxy_set_feature_prepared() itself. This is used by features prepared
   * from constructed. */
  if (feature->prepare_async == NULL)
    return;

  feature->prepare_async (self, feature, feature_prepared_cb,
      (gpointer) feature);
}

static gboolean
core_prepared (TpProxy *self)
{
  /* All the core features have been prepared if the head of the
   * prepare_requests queue is NOT a core feature */
  TpProxyPrepareRequest *req = g_queue_peek_head (self->priv->prepare_requests);

  if (req == NULL)
    return TRUE;

  return !req->core;
}

/* Returns %TRUE if all the features requested in @req have complete their
 * preparation */
static gboolean
request_is_complete (TpProxy *self,
    TpProxyPrepareRequest *req)
{
  guint i;
  gboolean complete = TRUE;

  for (i = 0; i < req->features->len; i++)
    {
      GQuark feature = g_array_index (req->features, GQuark, i);
      FeatureState state = tp_proxy_get_feature_state (self, feature);
      const TpProxyFeature *feat_struct = tp_proxy_subclass_get_feature (
          G_OBJECT_TYPE (self), feature);

      switch (state)
        {
          case FEATURE_STATE_UNWANTED:
            /* this can only happen in the special pseudo-request for the
             * core features, which blocks everything */
            g_assert (req->core);
            complete = FALSE;

            /* fall through to treat it as WANTED */
          case FEATURE_STATE_WANTED:
            if (core_prepared (self) ||
                req->core)
              {
                gboolean failed;

                /* Check if we have the required interfaces. We can't do that
                 * in tp_proxy_prepare_async() as CORE have to be prepared */
                if (!check_feature_interfaces (self, feature))
                  {
                    if (TP_IS_CONNECTION (self) &&
                        tp_connection_get_status ((TpConnection *) self, NULL)
                        != TP_CONNECTION_STATUS_CONNECTED)
                      {
                        /* Give a chance to retry preparing the feature once
                         * the Connection is connected as it may still gain
                         * the interface. */
                        tp_proxy_set_feature_state (self, feature,
                            FEATURE_STATE_MISSING_IFACE);
                      }
                    else
                      {
                        tp_proxy_set_feature_state (self, feature,
                            FEATURE_STATE_FAILED);
                      }
                    continue;
                  }

                if (check_depends_ready (self, feature, FALSE, &failed))
                  {
                    /* We can prepare it now */
                    DEBUG ("%p: calling callback for %s", self,
                        g_quark_to_string (feature));

                    tp_proxy_set_feature_state (self, feature,
                        FEATURE_STATE_TRYING);

                    prepare_feature (self, feat_struct);
                    complete = FALSE;
                  }
                else if (failed)
                  {
                    tp_proxy_set_feature_state (self, feature,
                        FEATURE_STATE_FAILED);
                  }
                else
                  {
                    /* We have to wait until the deps finish their
                     * preparation. */
                    complete = FALSE;
                  }
              }
            break;

          case FEATURE_STATE_TRYING:
            complete = FALSE;
            break;

          case FEATURE_STATE_INVALID:
          case FEATURE_STATE_FAILED:
          case FEATURE_STATE_MISSING_IFACE:
          case FEATURE_STATE_READY:
            /* nothing more to do */
            break;
        }
    }

  return complete;
}

static void
finish_all_requests (TpProxy *self,
    const GError *error)
{
  GList *iter;
  GQueue *tmp = g_queue_copy (self->priv->prepare_requests);

  g_queue_clear (self->priv->prepare_requests);

  for (iter = tmp->head; iter != NULL; iter = g_list_next (iter))
    {
      tp_proxy_prepare_request_finish (iter->data, error);
    }

  g_queue_free (tmp);
}

/*
 * tp_proxy_poll_features:
 * @self: a proxy
 * @error: if not %NULL, fail all feature requests with this error
 *
 * For each feature in state WANTED, if its dependencies have been satisfied,
 * call the callback and advance it to state TRYING.
 *
 * For each feature request, see if it's finished yet.
 *
 * Called every time the set of prepared/failed features changes,
 * when a temporary error causes introspection to fail, and when
 * #TpProxy.invalidated changes.
 *
 * If @error is %NULL, #TpProxy.invalidated is also checked.
 */
static void
tp_proxy_poll_features (TpProxy *self,
    const GError *error)
{
  const gchar *error_source = "temporarily failed";
  GList *iter;
  GList *next;

  if (g_queue_get_length (self->priv->prepare_requests) == 0)
    return;

  g_object_ref (self);

  for (iter = self->priv->prepare_requests->head; iter != NULL; iter = next)
    {
      TpProxyPrepareRequest *req = iter->data;
      TpProxyPrepareRequest *head = g_queue_peek_head (
          self->priv->prepare_requests);

      if (error == NULL)
        {
          error_source = "invalidated";
          error = self->invalidated;
        }

      if (error != NULL)
        {
          DEBUG ("%p: %s, ending all requests", self, error_source);

          finish_all_requests (self, error);
          break;
        }

      next = iter->next;

      /* Core features have to be prepared first, in superclass-to-subclass
       * order. The next core feature to be prepared, if any, is always at the
       * head of prepare_requests. */
      if (!core_prepared (self) &&
          req != head)
        {
          DEBUG ("%p: core features not ready yet, nothing prepared", self);
          continue;
        }

      if (request_is_complete (self, req))
        {
          DEBUG ("%p: request %p prepared", self, req);
          g_queue_delete_link (self->priv->prepare_requests, iter);

          tp_proxy_prepare_request_finish (req, NULL);
        }
    }

  g_object_unref (self);
}

/*
 * _tp_proxy_set_feature_prepared:
 * @self: a proxy
 * @feature: a feature made available by @self's class
 * @succeeded: %TRUE if the feature was prepared successfully
 *
 * Record that @self has attempted to prepare @feature. No further
 * attempts will be made to prepare it. If @succeeded is %TRUE,
 * tp_proxy_is_prepared() will return %TRUE for @self and @feature.
 * Whether @succeeded is %TRUE or %FALSE, any calls to
 * tp_proxy_prepare_async() that were only waiting for @feature will
 * finish successfully.
 *
 * If @feature represents core functionality of the class that should
 * always have worked (such as the GetAll method call for a #TpAccount's
 * properties), the subclass should instead call either
 * _tp_proxy_set_features_failed() (if it might still be possible to use @self
 * later, as for a #TpConnectionManager) or tp_proxy_invalidate() (if not)
 * instead; either of these will cause all calls to tp_proxy_prepare_async()
 * to finish with an error.
 */
void
_tp_proxy_set_feature_prepared (TpProxy *self,
    GQuark feature,
    gboolean succeeded)
{
  g_return_if_fail (TP_IS_PROXY (self));
  g_return_if_fail (tp_proxy_get_feature_state (self, feature) !=
      FEATURE_STATE_INVALID);
  tp_proxy_set_feature_state (self, feature,
      succeeded ? FEATURE_STATE_READY : FEATURE_STATE_FAILED);
  tp_proxy_poll_features (self, NULL);
}

/*
 * _tp_proxy_set_features_failed:
 * @self: a proxy
 * @error: an error
 *
 * Record that @self has been unable to prepare any features, but is still
 * potentially usable. Any pending calls to tp_proxy_prepare_async() will
 * finish unsuccessfully with @error, but @self will *not* be invalidated.
 */

void
_tp_proxy_set_features_failed (TpProxy *self,
    const GError *error)
{
  g_return_if_fail (TP_IS_PROXY (self));
  g_return_if_fail (error != NULL);
  tp_proxy_poll_features (self, error);
}

static void
check_announce_connected (TpProxy *self,
    gboolean in_idle)
{
  if (self->priv->pending_will_announce_calls != 0)
    return;

  if (in_idle)
    {
      g_simple_async_result_complete_in_idle (
          self->priv->will_announce_connected_result);
    }
  else
    {
      g_simple_async_result_complete (
          self->priv->will_announce_connected_result);
    }

  tp_clear_object (&self->priv->will_announce_connected_result);
}

static void
prepare_before_signalling_connected_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpProxy *self = TP_PROXY (user_data);

  /* We don't care if the call succeeded or not as it was already prepared */
  self->priv->pending_will_announce_calls--;

  check_announce_connected (self, FALSE);
}

static void foreach_feature (GQuark name,
    gpointer data,
    gpointer user_data)
{
  FeatureState state = GPOINTER_TO_INT (data);
  TpProxy *self = user_data;

  if (state == FEATURE_STATE_MISSING_IFACE)
    {
      GQuark features[] = { 0, 0};

      tp_proxy_set_feature_state (self, name, FEATURE_STATE_UNWANTED);

      self->priv->pending_will_announce_calls++;

      features[0] = name;

      tp_proxy_prepare_async (self, features,
          prepare_before_signalling_connected_cb, self);
    }
  else if (state == FEATURE_STATE_READY)
    {
      const TpProxyFeature *feature;

      feature = tp_proxy_subclass_get_feature (G_OBJECT_TYPE (self), name);

      if (feature->prepare_before_signalling_connected_async == NULL)
        return;

      self->priv->pending_will_announce_calls++;

      feature->prepare_before_signalling_connected_async (self, feature,
          prepare_before_signalling_connected_cb, self);
    }
}

/*
 * _tp_proxy_will_announce_connected_async:
 *
 * Called by connection.c when the connection became connected and we're about
 * to announce it. But before we have to wait for all the prepared features to
 * process their prepare_before_signalling_connected_async, if any.
 */
void
_tp_proxy_will_announce_connected_async (TpProxy *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_assert (TP_IS_CONNECTION (self));
  g_assert (self->priv->will_announce_connected_result == NULL);

  self->priv->will_announce_connected_result = g_simple_async_result_new (
      (GObject *) self, callback, user_data,
      _tp_proxy_will_announce_connected_async);

  g_datalist_foreach (&self->priv->features, foreach_feature, self);

  check_announce_connected (self, TRUE);
}

gboolean
_tp_proxy_will_announce_connected_finish (TpProxy *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, _tp_proxy_will_announce_connected_async)
}
