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
#include "telepathy-glib/proxy-internal.h"

#define DEBUG_FLAG TP_DEBUG_PROXY
#include "telepathy-glib/debug-internal.h"
#include <telepathy-glib/util.h>

#if 0
#define MORE_DEBUG DEBUG
#else
#define MORE_DEBUG(...) G_STMT_START {} G_STMT_END
#endif

/**
 * TpProxyPendingCall:
 *
 * Opaque structure representing a pending D-Bus call.
 *
 * Since: 0.7.1
 */

struct _TpProxyPendingCall {
    /* This structure's "reference count" is implicit:
     * - 1 if D-Bus has us (from creation until _completed)
     * - 1 if results have come in but we haven't run the callback yet
     *   (idle_source is nonzero)
     *
     * In normal use, its life cycle should go like this:
     * - Created by tp_proxy_pending_call_v0_new
     * - Given to dbus-glib by generated code (actual call starts here)
     * - tp_proxy_pending_call_v0_take_pending_call
     * - (Phase 1)
     * - tp_proxy_pending_call_v0_take_results
     * - Idle handler queued
     * - (Phase 2)
     * - tp_proxy_pending_call_v0_completed
     * - (Phase 3)
     * - tp_proxy_pending_call_idle_invoke
     * - tp_proxy_pending_call_free
     *
     * although we can't guarantee that idle_invoke won't go off before
     * completed does, if the dbus-glib implementation changes.
     *
     * Exceptional conditions that can occur:
     * - Weak object dies
     *   - Reference cleared, otherwise equivalent to explicit cancellation
     * - Explicitly cancelled
     *   - All phases: callback invoked if cancel_must_raise, otherwise
     *     not
     * - DBusGProxy destroy signal (or _completed before _take_results)
     *   - Phase 1: error callback queued
     *   - Phase 2: ignored, we use the results we've already got
     *   - Phase 3: ignored, we use the results we've already got
     */

    /* Always non-NULL */
    TpProxy *proxy;

    /* Set to NULL after it's been invoked once, or if cancellation means
     * it should never be called. Supplied by the generated code */
    TpProxyInvokeFunc invoke_callback;

    /* arguments for invoke_callback supplied by _take_results, by
     * cancellation or by the destroy signal */
    GError *error /* implicitly initialized */;
    GValueArray *args;

    /* user-supplied arguments for invoke_callback */
    GCallback callback;
    gpointer user_data;
    GDestroyNotify destroy;
    GObject *weak_object;

    /* Non-NULL until either _completed or destroy, whichever comes first */
    DBusGProxy *iface_proxy;
    DBusGProxyCall *pending_call;

    /* Nonzero if _idle_invoke has been queued (even if it has already
     * happened), i.e. if results have been taken or the DBusGProxy
     * was destroyed */
    guint idle_source;

    /* If TRUE, invoke the callback even on cancellation */
    unsigned cancel_must_raise:1;

    /* If TRUE, the idle_invoke callback has either run or been cancelled */
    unsigned idle_completed:1;
    /* If TRUE, dbus-glib no longer holds a reference to us */
    unsigned dbus_completed:1;

    /* Marker to indicate that this is, in fact, a valid TpProxyPendingCall */
    gconstpointer priv;
};

static const gchar * const pending_call_magic = "TpProxyPendingCall";

static void
tp_proxy_pending_call_lost_weak_ref (gpointer data,
                                     GObject *dead)
{
  TpProxyPendingCall *pc = data;

  DEBUG ("%p lost weak ref to %p", pc, dead);

  g_assert (pc->priv == pending_call_magic);
  g_assert (dead == pc->weak_object);

  pc->weak_object = NULL;

  if (!pc->idle_completed)
    tp_proxy_pending_call_cancel (pc);
}

static gboolean
tp_proxy_pending_call_idle_invoke (gpointer p)
{
  TpProxyPendingCall *pc = p;
  TpProxyInvokeFunc invoke = pc->invoke_callback;

  MORE_DEBUG ("%p", pc);

  if (invoke == NULL)
    {
      /* either already invoked (bug?), or cancelled */
      return FALSE;
    }

  MORE_DEBUG ("%p: invoking user callback", pc);

  g_assert (pc->proxy != NULL);
  g_assert (pc->error == NULL || pc->args == NULL);
  g_assert (!pc->idle_completed);

  pc->invoke_callback = NULL;
  invoke (pc->proxy, pc->error, pc->args, pc->callback,
      pc->user_data, pc->weak_object);
  pc->error = NULL;
  pc->args = NULL;

  /* don't clear pc->idle_source here! tp_proxy_pending_call_v0_completed
   * compares it to 0 to determine whether to free the object */

  return FALSE;
}

static void _tp_proxy_pending_call_idle_completed (gpointer p);

static void
_tp_proxy_pending_call_dgproxy_destroy (DBusGProxy *iface_proxy,
                                       TpProxyPendingCall *pc)
{
  g_assert (iface_proxy != NULL);
  g_assert (pc != NULL);
  g_assert (pc->iface_proxy == iface_proxy);
  g_assert (pc->proxy != NULL);

  DEBUG ("%p: DBusGProxy %p invalidated", pc, iface_proxy);

  if (pc->idle_source == 0)
    {
      /* we haven't already received and queued a reply, so synthesize
       * one */
      g_assert (pc->args == NULL);
      g_assert (pc->error == NULL);

      pc->error = g_error_new_literal (TP_DBUS_ERRORS,
          TP_DBUS_ERROR_NAME_OWNER_LOST, "Name owner lost (service crashed?)");

      pc->idle_source = g_idle_add_full (G_PRIORITY_HIGH,
          tp_proxy_pending_call_idle_invoke, pc,
          _tp_proxy_pending_call_idle_completed);
    }

  g_signal_handlers_disconnect_by_func (pc->iface_proxy,
      _tp_proxy_pending_call_dgproxy_destroy, pc);
  g_object_unref (pc->iface_proxy);
  pc->iface_proxy = NULL;
}

/**
 * tp_proxy_pending_call_v0_new:
 * @self: a proxy
 * @iface: a quark whose string value is the D-Bus interface
 * @member: the name of the method being called
 * @iface_proxy: the interface-specific #DBusGProxy for @iface
 * @invoke_callback: an implementation of #TpProxyInvokeFunc which will
 *  invoke @callback with appropriate arguments
 * @callback: a callback to be called when the call completes
 * @user_data: user-supplied data for the callback
 * @destroy: user-supplied destructor for the data
 * @weak_object: if not %NULL, a #GObject which will be weakly referenced by
 *   the signal connection - if it is destroyed, the pending call will
 *   automatically be cancelled
 * @cancel_must_raise: if %TRUE, the @invoke_callback will be run with
 *  error %TP_DBUS_ERROR_CANCELLED if the call is cancelled by a call to
 *  tp_proxy_pending_call_cancel() or by destruction of the @weak_object;
 *  if %FALSE, the @invoke_callback will not be run at all in these cases
 *
 * Allocate a new pending call structure. After calling this function, the
 * caller must start an asynchronous D-Bus call and give the resulting
 * DBusGProxyCall to the pending call object using
 * tp_proxy_pending_call_v0_take_pending_call().
 *
 * If dbus-glib gets a reply to the call before it's cancelled, the caller
 * must arrange for tp_proxy_pending_call_v0_take_results() to be called
 * with the results (the intention is for this to be done immediately
 * after dbus_g_proxy_end_call in the callback supplied to dbus-glib).
 *
 * When dbus-glib discards its reference to the user_data supplied in the
 * asynchronous D-Bus call (i.e. after the call is cancelled or a reply
 * arrives), tp_proxy_pending_call_v0_completed must be called (the intention
 * is for the #TpProxyPendingCall to be the @user_data in the async call,
 * and for tp_proxy_pending_call_v0_completed to be the #GDestroyNotify
 * passed to the same async call).
 *
 * This function is for use by #TpProxy subclass implementations only, and
 * should usually only be called from code generated by
 * tools/glib-client-gen.py.
 *
 * Returns: a new pending call structure
 *
 * Since: 0.7.1
 */
TpProxyPendingCall *
tp_proxy_pending_call_v0_new (TpProxy *self,
                              GQuark iface,
                              const gchar *member,
                              DBusGProxy *iface_proxy,
                              TpProxyInvokeFunc invoke_callback,
                              GCallback callback,
                              gpointer user_data,
                              GDestroyNotify destroy,
                              GObject *weak_object,
                              gboolean cancel_must_raise)
{
  TpProxyPendingCall *pc;

  g_return_val_if_fail (invoke_callback != NULL, NULL);
  g_return_val_if_fail ((gpointer) iface_proxy != (gpointer) self, NULL);

  pc = g_slice_new0 (TpProxyPendingCall);

  MORE_DEBUG ("(proxy=%p, if=%s, meth=%s, ic=%p; cb=%p, ud=%p, dn=%p, wo=%p)"
      " -> %p", self, g_quark_to_string (iface), member, invoke_callback,
      callback, user_data, destroy, weak_object, pc);

  pc->proxy = g_object_ref (self);
  pc->invoke_callback = invoke_callback;
  pc->callback = callback;
  pc->user_data = user_data;
  pc->destroy = destroy;
  pc->weak_object = weak_object;
  pc->iface_proxy = g_object_ref (iface_proxy);
  pc->pending_call = NULL;
  pc->priv = pending_call_magic;
  pc->cancel_must_raise = cancel_must_raise;

  if (weak_object != NULL)
    g_object_weak_ref (weak_object, tp_proxy_pending_call_lost_weak_ref, pc);

  g_signal_connect (iface_proxy, "destroy",
      G_CALLBACK (_tp_proxy_pending_call_dgproxy_destroy), pc);

  return pc;
}

/**
 * tp_proxy_pending_call_cancel:
 * @pc: a pending call
 *
 * Cancel the given pending call. After this function returns, you
 * must not assume that the pending call remains valid, but you must not
 * explicitly free it either.
 *
 * Since: 0.7.1
 */
void
tp_proxy_pending_call_cancel (TpProxyPendingCall *pc)
{
  DEBUG ("%p", pc);

  g_return_if_fail (pc->priv == pending_call_magic);
  g_return_if_fail (pc->proxy != NULL);
  /* If the callback has already run, it's too late to cancel */
  g_return_if_fail (!pc->idle_completed);

  if (pc->cancel_must_raise)
    {
      if (pc->error != NULL)
        g_error_free (pc->error);

      pc->error = g_error_new_literal (TP_DBUS_ERRORS,
          TP_DBUS_ERROR_CANCELLED, "Re-entrant D-Bus call cancelled");

      if (pc->args != NULL)
        {
          tp_value_array_free (pc->args);
          pc->args = NULL;
        }
    }
  else
    {
      pc->invoke_callback = NULL;
    }

  /* If we're calling the callback due to cancellation, we must free the
   * pending call object afterwards. Otherwise, we must free the pending
   * call object later anyway, in case this function was called due to
   * weak refs (like fd.o #14750). */
  if (pc->idle_source == 0)
    {
      pc->idle_source = g_idle_add_full (G_PRIORITY_HIGH,
          tp_proxy_pending_call_idle_invoke, pc,
          _tp_proxy_pending_call_idle_completed);
    }

  if (!pc->dbus_completed && pc->pending_call != NULL)
    {
      /* Implicitly asserts that iface_proxy is non-NULL */
      DBusGProxy *iface_proxy = g_object_ref (pc->iface_proxy);

      dbus_g_proxy_cancel_call (iface_proxy, pc->pending_call);
      g_object_unref (iface_proxy);
    }
}

static void
tp_proxy_pending_call_free (TpProxyPendingCall *pc)
{
  MORE_DEBUG ("%p", pc);

  g_assert (pc->priv == pending_call_magic);

  if (pc->destroy != NULL)
    pc->destroy (pc->user_data);

  pc->destroy = NULL;
  pc->user_data = NULL;

  if (pc->error != NULL)
    g_error_free (pc->error);

  pc->error = NULL;

  if (pc->args != NULL)
    tp_value_array_free (pc->args);

  pc->args = NULL;

  if (pc->weak_object != NULL)
    g_object_weak_unref (pc->weak_object,
        tp_proxy_pending_call_lost_weak_ref, pc);

  if (pc->iface_proxy != NULL)
    {
      g_signal_handlers_disconnect_by_func (pc->iface_proxy,
          _tp_proxy_pending_call_dgproxy_destroy, pc);
      g_object_unref (pc->iface_proxy);
      pc->iface_proxy = NULL;
    }

  g_assert (pc->proxy != NULL);
  g_object_unref (pc->proxy);
  pc->proxy = NULL;

  g_slice_free (TpProxyPendingCall, pc);
}

/**
 * tp_proxy_pending_call_v0_completed:
 * @p: a #TpProxyPendingCall allocated with tp_proxy_pending_call_v0_new()
 *
 * Indicate that dbus-glib has finished with this pending call, and therefore
 * either tp_proxy_pending_call_v0_take_results() has already been called,
 * or it will never be called. See tp_proxy_pending_call_v0_new().
 *
 * The signature is chosen to match #GDestroyNotify.
 *
 * This function is for use by #TpProxy subclass implementations only, and
 * should usually only be called from code generated by
 * tools/glib-client-gen.py.
 *
 * Since: 0.7.1
 */
void
tp_proxy_pending_call_v0_completed (gpointer p)
{
  TpProxyPendingCall *pc = p;

  MORE_DEBUG ("%p", pc);

  g_return_if_fail (pc->priv == pending_call_magic);
  g_return_if_fail (!pc->dbus_completed);
  g_return_if_fail (pc->proxy != NULL);

  /* dbus-glib frees its user_data *before* it emits destroy; if we
   * haven't yet queued the callback, assume that's what's going on. */
  if (pc->idle_source == 0 && pc->iface_proxy != NULL)
    {
      MORE_DEBUG ("Looks like this pending call hasn't finished, assuming "
          "the DBusGProxy is about to die");
      /* this causes the pending call to be freed */
      _tp_proxy_pending_call_dgproxy_destroy (pc->iface_proxy, pc);

      g_assert (pc->iface_proxy == NULL);
    }

  pc->dbus_completed = TRUE;

  /* If the idle callback has been run already, we can go away */
  if (pc->idle_completed)
    tp_proxy_pending_call_free (pc);
}

/**
 * tp_proxy_pending_call_v0_take_pending_call:
 * @pc: A pending call on which this function has not yet been called
 * @pending_call: The underlying dbus-glib pending call
 *
 * Set the underlying pending call to be used by this object.
 * See also tp_proxy_pending_call_v0_new().
 *
 * This function is for use by #TpProxy subclass implementations only, and
 * should usually only be called from code generated by
 * tools/glib-client-gen.py.
 *
 * Since: 0.7.1
 */
void
tp_proxy_pending_call_v0_take_pending_call (TpProxyPendingCall *pc,
                                            DBusGProxyCall *pending_call)
{
  g_return_if_fail (pc->priv == pending_call_magic);
  g_return_if_fail (pc->pending_call == NULL);
  g_return_if_fail (pc->proxy != NULL);

  pc->pending_call = pending_call;
}

static void
_tp_proxy_pending_call_idle_completed (gpointer p)
{
  TpProxyPendingCall *pc = p;

  MORE_DEBUG ("%p", pc);

  pc->idle_completed = TRUE;

  if (pc->dbus_completed)
    tp_proxy_pending_call_free (pc);
}

/**
 * tp_proxy_pending_call_v0_take_results:
 * @pc: A pending call on which this function has not yet been called
 * @error: %NULL if the call was successful, or an error (whose ownership
 *  is taken over by the pending call object). Because of dbus-glib
 *  idiosyncrasies, this must be the error produced by dbus-glib, not a copy.
 * @args: %NULL if the call failed or had no "out" arguments, or an array
 *  of "out" arguments (whose ownership is taken over by the pending call
 *  object)
 *
 * Set the "out" arguments (return values) from this pending call.
 * See also tp_proxy_pending_call_v0_new().
 *
 * This function is for use by #TpProxy subclass implementations only, and
 * should usually only be called from code generated by
 * tools/glib-client-gen.py.
 *
 * Since: 0.7.1
 */
void
tp_proxy_pending_call_v0_take_results (TpProxyPendingCall *pc,
                                       GError *error,
                                       GValueArray *args)
{
  g_return_if_fail (pc->proxy != NULL);
  g_return_if_fail (pc->priv == pending_call_magic);
  g_return_if_fail (pc->args == NULL);
  g_return_if_fail (pc->error == NULL);
  g_return_if_fail (pc->idle_source == 0);
  g_return_if_fail (error == NULL || args == NULL);

  MORE_DEBUG ("%p (error: %s)", pc,
      error == NULL ? "(none)" : error->message);

  pc->args = args;
  pc->error = _tp_proxy_take_and_remap_error (pc->proxy, error);

  /* queue up the actual callback to run after we go back to the event loop */
  pc->idle_source = g_idle_add_full (G_PRIORITY_HIGH,
      tp_proxy_pending_call_idle_invoke, pc,
      _tp_proxy_pending_call_idle_completed);
}
