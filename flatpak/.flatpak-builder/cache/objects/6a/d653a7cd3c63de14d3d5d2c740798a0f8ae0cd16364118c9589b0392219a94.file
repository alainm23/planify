/*
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

#define DEBUG_FLAG TP_DEBUG_PROXY
#include "telepathy-glib/debug-internal.h"
#include <telepathy-glib/util.h>

#if 0
#define MORE_DEBUG DEBUG
#else
#define MORE_DEBUG(...) G_STMT_START {} G_STMT_END
#endif

/**
 * TpProxySignalConnection:
 *
 * Opaque structure representing a D-Bus signal connection.
 *
 * Since: 0.7.1
 */

typedef struct _TpProxySignalInvocation TpProxySignalInvocation;

struct _TpProxySignalInvocation {
    TpProxySignalConnection *sc;
    TpProxy *proxy;
    GValueArray *args;
    guint idle_source;
};

struct _TpProxySignalConnection {
    /* 1 if D-Bus has us
     * 1 per member of @invocations
     * 1 per callback being invoked right now */
    gsize refcount;

    /* borrowed ref (discarded when we see invalidated signal)
     * + 1 per member of @invocations
     * + 1 per callback being invoked (possibly nested!) right now */
    TpProxy *proxy;

    DBusGProxy *iface_proxy;
    gchar *member;
    GCallback collect_args;
    TpProxyInvokeFunc invoke_callback;
    GCallback callback;
    gpointer user_data;
    GDestroyNotify destroy;
    GObject *weak_object;
    /* queue of _TpProxySignalInvocation, not including any that are
     * being invoked right now */
    GQueue invocations;
};

static void _tp_proxy_signal_connection_dgproxy_destroy (DBusGProxy *,
    TpProxySignalConnection *);

static void
tp_proxy_signal_connection_disconnect_dbus_glib (TpProxySignalConnection *sc)
{
  DBusGProxy *iface_proxy = sc->iface_proxy;

  /* ignore if already done */
  if (iface_proxy == NULL)
    return;

  sc->iface_proxy = NULL;
  g_signal_handlers_disconnect_by_func (iface_proxy,
      _tp_proxy_signal_connection_dgproxy_destroy, sc);
  dbus_g_proxy_disconnect_signal (iface_proxy, sc->member,
      sc->collect_args, (gpointer) sc);

  g_object_unref (iface_proxy);
}

static void
tp_proxy_signal_connection_proxy_invalidated (TpProxy *proxy,
                                              guint domain,
                                              gint code,
                                              const gchar *message,
                                              TpProxySignalConnection *sc)
{
  g_assert (sc != NULL);
  g_assert (domain != 0);
  g_assert (message != NULL);

  DEBUG ("%p: TpProxy %p invalidated (I have %p): %s", sc, proxy,
      sc->proxy, message);
  g_assert (proxy == sc->proxy);

  g_signal_handlers_disconnect_by_func (sc->proxy,
      tp_proxy_signal_connection_proxy_invalidated, sc);
  sc->proxy = NULL;

  tp_proxy_signal_connection_disconnect_dbus_glib (sc);
}

static void
tp_proxy_signal_connection_lost_weak_ref (gpointer data,
                                          GObject *dead)
{
  TpProxySignalConnection *sc = data;

  DEBUG ("%p: lost weak ref to %p", sc, dead);

  g_assert (dead == sc->weak_object);

  sc->weak_object = NULL;

  tp_proxy_signal_connection_disconnect (sc);
}

static gboolean
_tp_proxy_signal_connection_finish_free (gpointer p)
{
  TpProxySignalConnection *sc = p;

  if (sc->weak_object != NULL)
    {
      g_object_weak_unref (sc->weak_object,
          tp_proxy_signal_connection_lost_weak_ref, sc);
      sc->weak_object = NULL;
    }

  g_slice_free (TpProxySignalConnection, sc);

  return FALSE;
}

/* Return TRUE if it dies. */
static gboolean
tp_proxy_signal_connection_unref (TpProxySignalConnection *sc)
{
  if (--(sc->refcount) > 0)
    {
      MORE_DEBUG ("%p: %" G_GSIZE_FORMAT " refs left", sc, sc->refcount);
      return FALSE;
    }

  MORE_DEBUG ("removed last ref to %p", sc);

  if (sc->proxy != NULL)
    {
      g_signal_handlers_disconnect_by_func (sc->proxy,
          tp_proxy_signal_connection_proxy_invalidated, sc);
      sc->proxy = NULL;
    }

  g_assert (sc->invocations.length == 0);

  if (sc->destroy != NULL)
    sc->destroy (sc->user_data);

  sc->destroy = NULL;
  sc->user_data = NULL;

  g_free (sc->member);

  /* We can't inline this here, because of fd.o #14750. If our signal
   * connection gets destroyed by side-effects of something else losing a
   * weak reference to the same object (e.g. a pending call whose weak
   * object is the same as ours has the last ref to the TpProxy, causing
   * invalidation when the weak object goes away) then we need to avoid dying
   * til *our* weak-reference callback has run. So, don't actually free the
   * signal connection until we've re-entered the main loop. */
  g_idle_add_full (G_PRIORITY_HIGH, _tp_proxy_signal_connection_finish_free,
      sc, NULL);

  return TRUE;
}

/**
 * tp_proxy_signal_connection_disconnect:
 * @sc: a signal connection
 *
 * Disconnect the given signal connection. After this function returns, you
 * must not assume that the signal connection remains valid, but you must not
 * explicitly free it either.
 *
 * It is not safe to call this function if @sc has been disconnected already,
 * which happens in each of these situations:
 *
 * <itemizedlist>
 * <listitem>the @weak_object used when @sc was created has been
 *  destroyed</listitem>
 * <listitem>tp_proxy_signal_connection_disconnect has already been
 *  used</listitem>
 * <listitem>the proxy has been invalidated</listitem>
 * </itemizedlist>
 *
 * Since: 0.7.1
 */
void
tp_proxy_signal_connection_disconnect (TpProxySignalConnection *sc)
{
  TpProxySignalInvocation *invocation;

  while ((invocation = g_queue_pop_head (&sc->invocations)) != NULL)
    {
      g_assert (invocation->sc == sc);
      g_object_unref (invocation->proxy);
      invocation->proxy = NULL;
      invocation->sc = NULL;
      g_source_remove (invocation->idle_source);

      if (tp_proxy_signal_connection_unref (sc))
        return;
    }

  tp_proxy_signal_connection_disconnect_dbus_glib (sc);
}

static void
tp_proxy_signal_invocation_free (gpointer p)
{
  TpProxySignalInvocation *invocation = p;

  if (invocation->sc != NULL)
    {
      /* this shouldn't really happen - it'll get run if the idle source
       * is removed by something other than t_p_s_c_disconnect or
       * t_p_s_i_run */
      WARNING ("idle source removed by someone else");

      g_queue_remove (&invocation->sc->invocations, invocation);
      g_object_unref (invocation->proxy);
      tp_proxy_signal_connection_unref (invocation->sc);
    }

  g_assert (invocation->proxy == NULL);

  if (invocation->args != NULL)
    tp_value_array_free (invocation->args);

  g_slice_free (TpProxySignalInvocation, invocation);
}

static gboolean
tp_proxy_signal_invocation_run (gpointer p)
{
  TpProxySignalInvocation *invocation = p;
  TpProxySignalInvocation *popped = g_queue_pop_head
      (&invocation->sc->invocations);

  /* if GLib is running idle handlers in the wrong order, then we've lost */
  MORE_DEBUG ("%p: popped %p", invocation->sc, popped);
  g_assert (popped == invocation);

  invocation->sc->invoke_callback (invocation->proxy, NULL,
      invocation->args, invocation->sc->callback, invocation->sc->user_data,
      invocation->sc->weak_object);

  /* the invoke callback steals args */
  invocation->args = NULL;

  /* there's one ref to the proxy per queued invocation, to keep it
   * alive */
  MORE_DEBUG ("%p refcount-- due to %p run, sc=%p", invocation->proxy,
      invocation, invocation->sc);
  g_object_unref (invocation->proxy);
  invocation->proxy = NULL;
  tp_proxy_signal_connection_unref (invocation->sc);
  invocation->sc = NULL;

  return FALSE;
}

static void
tp_proxy_signal_connection_dropped (gpointer p,
                                    GClosure *unused)
{
  TpProxySignalConnection *sc = p;

  MORE_DEBUG ("%p (%u invocations queued)", sc, sc->invocations.length);

  tp_proxy_signal_connection_unref (sc);
}

static void
_tp_proxy_signal_connection_dgproxy_destroy (DBusGProxy *iface_proxy,
                                             TpProxySignalConnection *sc)
{
  g_assert (iface_proxy != NULL);
  g_assert (sc != NULL);
  g_assert (sc->iface_proxy == iface_proxy);

  DEBUG ("%p: DBusGProxy %p invalidated", sc, iface_proxy);

  sc->iface_proxy = NULL;
  g_signal_handlers_disconnect_by_func (iface_proxy,
      _tp_proxy_signal_connection_dgproxy_destroy, sc);
  g_object_unref (iface_proxy);
}

static void
collect_none (DBusGProxy *dgproxy, TpProxySignalConnection *sc)
{
  tp_proxy_signal_connection_v0_take_results (sc, NULL);
}

/**
 * tp_proxy_signal_connection_v0_new:
 * @self: a proxy
 * @iface: a quark whose string value is the D-Bus interface
 * @member: the name of the signal to which we're connecting
 * @expected_types: an array of expected GTypes for the arguments, terminated
 *  by %G_TYPE_INVALID
 * @collect_args: a callback to be given to dbus_g_proxy_connect_signal(),
 *  which must marshal the arguments into a #GValueArray and use them to call
 *  tp_proxy_signal_connection_v0_take_results(); this callback is not
 *  guaranteed to be called by future versions of telepathy-glib, which might
 *  be able to implement its functionality internally. If no arguments are
 *  expected at all (expected_types = { G_TYPE_INVALID }) then this callback
 *  should instead be %NULL
 * @invoke_callback: a function which will be called with @error = %NULL,
 *  which should invoke @callback with @user_data, @weak_object and other
 *  appropriate arguments taken from @args
 * @callback: user callback to be invoked by @invoke_callback
 * @user_data: user-supplied data for the callback
 * @destroy: user-supplied destructor for the data, which will be called
 *   when the signal connection is disconnected for any reason,
 *   or will be called before this function returns if an error occurs
 * @weak_object: if not %NULL, a #GObject which will be weakly referenced by
 *   the signal connection - if it is destroyed, the signal connection will
 *   automatically be disconnected
 * @error: If not %NULL, used to raise an error if %NULL is returned
 *
 * Allocate a new structure representing a signal connection, and connect to
 * the signal, arranging for @invoke_callback to be called when it arrives.
 *
 * This function is for use by #TpProxy subclass implementations only, and
 * should usually only be called from code generated by
 * tools/glib-client-gen.py.
 *
 * Returns: a signal connection structure, or %NULL if the proxy does not
 *  have the desired interface or has become invalid
 *
 * Since: 0.7.1
 */
TpProxySignalConnection *
tp_proxy_signal_connection_v0_new (TpProxy *self,
                                   GQuark iface,
                                   const gchar *member,
                                   const GType *expected_types,
                                   GCallback collect_args,
                                   TpProxyInvokeFunc invoke_callback,
                                   GCallback callback,
                                   gpointer user_data,
                                   GDestroyNotify destroy,
                                   GObject *weak_object,
                                   GError **error)
{
  TpProxySignalConnection *sc;
  DBusGProxy *iface_proxy = tp_proxy_get_interface_by_id (self,
      iface, error);

  if (iface_proxy == NULL)
    {
      if (destroy != NULL)
        destroy (user_data);

      return NULL;
    }

  if (expected_types[0] == G_TYPE_INVALID)
    {
      collect_args = G_CALLBACK (collect_none);
    }
  else
    {
      g_return_val_if_fail (collect_args != NULL, NULL);
    }

  sc = g_slice_new0 (TpProxySignalConnection);

  MORE_DEBUG ("(proxy=%p, if=%s, sig=%s, collect=%p, invoke=%p, "
      "cb=%p, ud=%p, dn=%p, wo=%p) -> %p",
      self, g_quark_to_string (iface), member, collect_args,
      invoke_callback, callback, user_data, destroy, weak_object, sc);

  sc->refcount = 1;
  sc->proxy = self;
  sc->iface_proxy = g_object_ref (iface_proxy);
  sc->member = g_strdup (member);
  sc->collect_args = collect_args;
  sc->invoke_callback = invoke_callback;
  sc->callback = callback;
  sc->user_data = user_data;
  sc->destroy = destroy;
  sc->weak_object = weak_object;

  if (weak_object != NULL)
    g_object_weak_ref (weak_object, tp_proxy_signal_connection_lost_weak_ref,
        sc);

  g_signal_connect (self, "invalidated",
      G_CALLBACK (tp_proxy_signal_connection_proxy_invalidated), sc);

  g_signal_connect (iface_proxy, "destroy",
      G_CALLBACK (_tp_proxy_signal_connection_dgproxy_destroy), sc);

  dbus_g_proxy_connect_signal (iface_proxy, member, collect_args, sc,
      tp_proxy_signal_connection_dropped);

  return sc;
}

/**
 * tp_proxy_signal_connection_v0_take_results:
 * @sc: The signal connection
 * @args: The arguments of the signal
 *
 * Feed the results of a signal invocation back into the signal connection
 * machinery.
 *
 * This method should only be called from #TpProxy subclass implementations,
 * in the callback that implements @collect_args.
 *
 * Since: 0.7.1
 */
void
tp_proxy_signal_connection_v0_take_results (TpProxySignalConnection *sc,
                                            GValueArray *args)
{
  TpProxySignalInvocation *invocation = g_slice_new0 (TpProxySignalInvocation);
  /* FIXME: assert that the GValueArray is the right length, or
   * even that it contains the right types? */

  /* as long as there are queued invocations, we keep one ref to the TpProxy
   * and one ref to the TpProxySignalConnection per invocation */
  MORE_DEBUG ("%p refcount++ due to %p, sc=%p", sc->proxy, invocation, sc);
  invocation->proxy = g_object_ref (sc->proxy);
  sc->refcount++;

  invocation->sc = sc;
  invocation->args = args;

  g_queue_push_tail (&sc->invocations, invocation);

  MORE_DEBUG ("invocations: head=%p tail=%p count=%u",
      sc->invocations.head, sc->invocations.tail,
      sc->invocations.length);

  invocation->idle_source = g_idle_add_full (G_PRIORITY_HIGH,
      tp_proxy_signal_invocation_run, invocation,
      tp_proxy_signal_invocation_free);
}
