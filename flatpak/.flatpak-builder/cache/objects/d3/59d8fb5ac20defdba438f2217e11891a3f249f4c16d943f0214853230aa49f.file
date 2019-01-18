/*
 * dbus-daemon.c - Source for TpDBusDaemon
 *
 * Copyright (C) 2005-2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2005-2009 Nokia Corporation
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

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-internal.h>

#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>

#include <telepathy-glib/errors.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#include "telepathy-glib/_gen/tp-cli-dbus-daemon-body.h"

#define DEBUG_FLAG TP_DEBUG_PROXY
#include "debug-internal.h"

/**
 * TpDBusDaemonClass:
 *
 * The class of #TpDBusDaemon.
 *
 * Since: 0.7.1
 */
struct _TpDBusDaemonClass
{
  /*<private>*/
  TpProxyClass parent_class;
  gpointer priv;
};

/**
 * TpDBusDaemon:
 *
 * A subclass of #TpProxy that represents the D-Bus daemon. It mainly provides
 * functionality to manage well-known names on the bus.
 *
 * Since: 0.7.1
 */
struct _TpDBusDaemon
{
  /*<private>*/
  TpProxy parent;

  TpDBusDaemonPrivate *priv;
};

struct _TpDBusDaemonPrivate
{
  /* dup'd name => _NameOwnerWatch */
  GHashTable *name_owner_watches;
  /* reffed */
  DBusConnection *libdbus;
};

G_DEFINE_TYPE (TpDBusDaemon, tp_dbus_daemon, TP_TYPE_PROXY)

static gpointer starter_bus_daemon = NULL;

/**
 * tp_dbus_daemon_dup:
 * @error: Used to indicate error if %NULL is returned
 *
 * Returns a proxy for signals and method calls on the D-Bus daemon on which
 * this process was activated (if it was launched by D-Bus service
 * activation), or the session bus (otherwise).
 *
 * If it is not possible to connect to the appropriate bus, raise an error
 * and return %NULL.
 *
 * The returned #TpDBusDaemon is cached; the same #TpDBusDaemon object will
 * be returned by this function repeatedly, as long as at least one reference
 * exists.
 *
 * Returns: (transfer full): a reference to a proxy for signals and method
 *  calls on the bus daemon, or %NULL
 *
 * Since: 0.7.26
 */
TpDBusDaemon *
tp_dbus_daemon_dup (GError **error)
{
  DBusGConnection *conn;

  if (starter_bus_daemon != NULL)
    return g_object_ref (starter_bus_daemon);

  conn = _tp_dbus_starter_bus_conn (error);

  if (conn == NULL)
    return NULL;

  starter_bus_daemon = tp_dbus_daemon_new (conn);
  g_assert (starter_bus_daemon != NULL);
  g_object_add_weak_pointer (starter_bus_daemon, &starter_bus_daemon);

  return starter_bus_daemon;
}

/**
 * tp_dbus_daemon_new: (skip)
 * @connection: a connection to D-Bus
 *
 * Returns a proxy for signals and method calls on a particular bus
 * connection.
 *
 * Use tp_dbus_daemon_dup() instead if you just want a connection to the
 * starter or session bus (which is almost always the right thing for
 * Telepathy).
 *
 * Returns: a new proxy for signals and method calls on the bus daemon
 *  to which @connection is connected
 *
 * Since: 0.7.1
 */
TpDBusDaemon *
tp_dbus_daemon_new (DBusGConnection *connection)
{
  g_return_val_if_fail (connection != NULL, NULL);

  return TP_DBUS_DAEMON (g_object_new (TP_TYPE_DBUS_DAEMON,
        "dbus-connection", connection,
        "bus-name", DBUS_SERVICE_DBUS,
        "object-path", DBUS_PATH_DBUS,
        NULL));
}

typedef struct
{
  gchar *last_owner;
  GArray *callbacks;
  gsize invoking;
} _NameOwnerWatch;

typedef struct
{
  TpDBusDaemonNameOwnerChangedCb callback;
  gpointer user_data;
  GDestroyNotify destroy;
} _NameOwnerSubWatch;

static void _tp_dbus_daemon_stop_watching (TpDBusDaemon *self,
    const gchar *name, _NameOwnerWatch *watch);

static void
tp_dbus_daemon_maybe_free_name_owner_watch (TpDBusDaemon *self,
    const gchar *name,
    _NameOwnerWatch *watch)
{
  /* Check to see whether this (callback, user_data) pair is in the watch's
   * array of callbacks. */
  GArray *array = watch->callbacks;
  /* 1 greater than an index into @array, to avoid it going negative: we
   * iterate in reverse so we can delete elements without needing to adjust
   * @i to compensate */
  guint i;

  if (watch->invoking > 0)
    return;

  for (i = array->len; i > 0; i--)
    {
      _NameOwnerSubWatch *entry = &g_array_index (array,
          _NameOwnerSubWatch, i - 1);

      if (entry->callback != NULL)
        continue;

      if (entry->destroy != NULL)
        entry->destroy (entry->user_data);

      g_array_remove_index (array, i - 1);
    }

  if (array->len == 0)
    {
      _tp_dbus_daemon_stop_watching (self, name, watch);
      g_hash_table_remove (self->priv->name_owner_watches, name);
    }
}

static void
_tp_dbus_daemon_name_owner_changed (TpDBusDaemon *self,
                                    const gchar *name,
                                    const gchar *new_owner)
{
  _NameOwnerWatch *watch = g_hash_table_lookup (self->priv->name_owner_watches,
      name);
  GArray *array;
  guint i;

  if (watch == NULL)
    return;

  /* This is partly to handle the case where an owner change happens
   * while GetNameOwner is in flight, partly to be able to optimize by only
   * calling GetNameOwner if we didn't already know, and partly because of a
   * dbus-glib bug that means we get every signal twice
   * (it thinks org.freedesktop.DBus is both a well-known name and a unique
   * name). */
  if (!tp_strdiff (watch->last_owner, new_owner))
    return;

  g_free (watch->last_owner);
  watch->last_owner = g_strdup (new_owner);

  /* We're calling out to user code which might end up removing its watch;
   * tell it to be less destructive. Also hold a ref on self, to avoid it
   * getting removed that way. */
  array = watch->callbacks;
  g_object_ref (self);
  watch->invoking++;

  for (i = 0; i < array->len; i++)
    {
      _NameOwnerSubWatch *subwatch = &g_array_index (array,
          _NameOwnerSubWatch, i);

      if (subwatch->callback != NULL)
        subwatch->callback (self, name, new_owner, subwatch->user_data);
    }

  watch->invoking--;

  tp_dbus_daemon_maybe_free_name_owner_watch (self, name, watch);
  g_object_unref (self);
}

static dbus_int32_t daemons_slot = -1;

typedef struct {
    DBusConnection *libdbus;
    DBusMessage *message;
} NOCIdleContext;

static NOCIdleContext *
noc_idle_context_new (DBusConnection *libdbus,
                      DBusMessage *message)
{
  NOCIdleContext *context = g_slice_new (NOCIdleContext);

  context->libdbus = dbus_connection_ref (libdbus);
  context->message = dbus_message_ref (message);
  return context;
}

static void
noc_idle_context_free (gpointer data)
{
  NOCIdleContext *context = data;

  dbus_connection_unref (context->libdbus);
  dbus_message_unref (context->message);
  g_slice_free (NOCIdleContext, context);
}

static gboolean
noc_idle_context_invoke (gpointer data)
{
  NOCIdleContext *context = data;
  const gchar *name;
  const gchar *old_owner;
  const gchar *new_owner;
  DBusError dbus_error = DBUS_ERROR_INIT;
  GSList **daemons;

  if (daemons_slot == -1)
    return FALSE;

  if (!dbus_message_get_args (context->message, &dbus_error,
        DBUS_TYPE_STRING, &name,
        DBUS_TYPE_STRING, &old_owner,
        DBUS_TYPE_STRING, &new_owner,
        DBUS_TYPE_INVALID))
    {
      DEBUG ("Couldn't unpack NameOwnerChanged(s, s, s): %s: %s",
          dbus_error.name, dbus_error.message);
      dbus_error_free (&dbus_error);
      return FALSE;
    }

  daemons = dbus_connection_get_data (context->libdbus, daemons_slot);

  DEBUG ("NameOwnerChanged(%s, %s -> %s)", name, old_owner, new_owner);

  /* should always be non-NULL, barring bugs */
  if (G_LIKELY (daemons != NULL))
    {
      GSList *iter;

      for (iter = *daemons; iter != NULL; iter = iter->next)
        {
          _tp_dbus_daemon_name_owner_changed (iter->data, name, new_owner);
        }
    }

  return FALSE;
}

static DBusHandlerResult
_tp_dbus_daemon_name_owner_changed_filter (DBusConnection *libdbus,
                                           DBusMessage *message,
                                           void *unused G_GNUC_UNUSED)
{
  /* We have to do the real work in an idle, so we don't break re-entrant
   * calls (the dbus-glib event source isn't re-entrant) */
  if (dbus_message_is_signal (message, DBUS_INTERFACE_DBUS,
        "NameOwnerChanged") &&
      dbus_message_has_sender (message, DBUS_SERVICE_DBUS))
    g_idle_add_full (G_PRIORITY_HIGH, noc_idle_context_invoke,
        noc_idle_context_new (libdbus, message),
        noc_idle_context_free);

  return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}

typedef struct {
    TpDBusDaemon *self;
    gchar *name;
    DBusMessage *reply;
    gsize refs;
} GetNameOwnerContext;

static GetNameOwnerContext *
get_name_owner_context_new (TpDBusDaemon *self,
                            const gchar *name)
{
  GetNameOwnerContext *context = g_slice_new (GetNameOwnerContext);

  context->self = g_object_ref (self);
  context->name = g_strdup (name);
  context->reply = NULL;
  context->refs = 1;
  return context;
}

static void
get_name_owner_context_unref (gpointer data)
{
  GetNameOwnerContext *context = data;

  if (--context->refs == 0)
    {
      g_object_unref (context->self);
      g_free (context->name);

      if (context->reply != NULL)
        dbus_message_unref (context->reply);

      g_slice_free (GetNameOwnerContext, context);
    }
}

static gboolean
_tp_dbus_daemon_get_name_owner_idle (gpointer data)
{
  GetNameOwnerContext *context = data;
  const gchar *owner = "";

  if (context->reply == NULL)
    {
      DEBUG ("Connection disconnected or no reply to GetNameOwner(%s)",
          context->name);
    }
  else if (dbus_message_get_type (context->reply) ==
      DBUS_MESSAGE_TYPE_METHOD_RETURN)
    {
      if (dbus_message_get_args (context->reply, NULL,
            DBUS_TYPE_STRING, &owner,
            DBUS_TYPE_INVALID))
        {
          DEBUG ("GetNameOwner(%s) -> %s", context->name, owner);
        }
      else
        {
          DEBUG ("Malformed reply from GetNameOwner(%s), assuming no owner",
              context->name);
        }
    }
  else
    {
      if (DEBUGGING)
        {
          DBusError error = DBUS_ERROR_INIT;

          if (dbus_set_error_from_message (&error, context->reply))
            {
              DEBUG ("GetNameOwner(%s) raised %s: %s", context->name,
                  error.name, error.message);
              dbus_error_free (&error);
            }
          else
            {
              DEBUG ("Unexpected message type from GetNameOwner(%s)",
                  context->name);
            }
        }
    }

  _tp_dbus_daemon_name_owner_changed (context->self, context->name, owner);

  return FALSE;
}

/**
 * TpDBusDaemonNameOwnerChangedCb:
 * @bus_daemon: The D-Bus daemon
 * @name: The name whose ownership has changed or been discovered
 * @new_owner: The unique name that now owns @name
 * @user_data: Arbitrary user-supplied data as passed to
 *  tp_dbus_daemon_watch_name_owner()
 *
 * The signature of the callback called by tp_dbus_daemon_watch_name_owner().
 *
 * Since: 0.7.1
 */

static inline gchar *
_tp_dbus_daemon_get_noc_rule (const gchar *name)
{
  return g_strdup_printf ("type='signal',"
      "sender='" DBUS_SERVICE_DBUS "',"
      "path='" DBUS_PATH_DBUS "',"
      "interface='"DBUS_INTERFACE_DBUS "',"
      "member='NameOwnerChanged',"
      "arg0='%s'", name);
}

static void
_tp_dbus_daemon_get_name_owner_notify (DBusPendingCall *pc,
                                       gpointer data)
{
  GetNameOwnerContext *context = data;

  /* we recycle this function for the case where the connection is already
   * disconnected: in that case we use pc = NULL */
  if (pc != NULL)
    context->reply = dbus_pending_call_steal_reply (pc);

  /* We have to do the real work in an idle, so we don't break re-entrant
   * calls (the dbus-glib event source isn't re-entrant) */
  context->refs++;
  g_idle_add_full (G_PRIORITY_HIGH, _tp_dbus_daemon_get_name_owner_idle,
      context, get_name_owner_context_unref);

  if (pc != NULL)
    dbus_pending_call_unref (pc);
}

/**
 * tp_dbus_daemon_watch_name_owner:
 * @self: The D-Bus daemon
 * @name: The name whose ownership is to be watched
 * @callback: Callback to call when the ownership is discovered or changes
 * @user_data: Arbitrary data to pass to @callback
 * @destroy: Called to destroy @user_data when the name owner watch is
 *  cancelled due to tp_dbus_daemon_cancel_name_owner_watch()
 *
 * Arrange for @callback to be called with the owner of @name as soon as
 * possible (which might even be before this function returns!), then
 * again every time the ownership of @name changes.
 *
 * If multiple watches are registered for the same @name, they will be called
 * in the order they were registered.
 *
 * Since: 0.7.1
 */
void
tp_dbus_daemon_watch_name_owner (TpDBusDaemon *self,
                                 const gchar *name,
                                 TpDBusDaemonNameOwnerChangedCb callback,
                                 gpointer user_data,
                                 GDestroyNotify destroy)
{
  _NameOwnerWatch *watch = g_hash_table_lookup (self->priv->name_owner_watches,
      name);
  _NameOwnerSubWatch tmp = { callback, user_data, destroy };

  g_return_if_fail (TP_IS_DBUS_DAEMON (self));
  g_return_if_fail (tp_dbus_check_valid_bus_name (name,
        TP_DBUS_NAME_TYPE_ANY, NULL));
  g_return_if_fail (callback != NULL);

  if (watch == NULL)
    {
      gchar *match_rule;
      DBusMessage *message;
      DBusPendingCall *pc = NULL;
      GetNameOwnerContext *context = get_name_owner_context_new (self, name);

      /* Allocate a new watch */
      watch = g_slice_new0 (_NameOwnerWatch);
      watch->last_owner = NULL;
      watch->callbacks = g_array_new (FALSE, FALSE,
          sizeof (_NameOwnerSubWatch));

      g_hash_table_insert (self->priv->name_owner_watches, g_strdup (name),
          watch);

      /* We want to be notified about name owner changes for this one.
       * Assume the match addition will succeed; there's no good way to cope
       * with failure here... */
      match_rule = _tp_dbus_daemon_get_noc_rule (name);
      DEBUG ("Adding match rule %s", match_rule);
      dbus_bus_add_match (self->priv->libdbus, match_rule, NULL);
      g_free (match_rule);

      message = dbus_message_new_method_call (DBUS_SERVICE_DBUS,
          DBUS_PATH_DBUS, DBUS_INTERFACE_DBUS, "GetNameOwner");

      if (message == NULL)
        ERROR ("Out of memory");

      /* We already checked that @name was in (a small subset of) UTF-8,
       * so OOM is the only thing that can go wrong. The use of &name here
       * is because libdbus is strange. */
      if (!dbus_message_append_args (message,
            DBUS_TYPE_STRING, &name,
            DBUS_TYPE_INVALID))
        ERROR ("Out of memory");

      if (!dbus_connection_send_with_reply (self->priv->libdbus,
          message, &pc, -1))
        ERROR ("Out of memory");
      /* pc is unreffed by _tp_dbus_daemon_get_name_owner_notify */
      dbus_message_unref (message);

      if (pc == NULL || dbus_pending_call_get_completed (pc))
        {
          /* pc can be NULL when the connection is already disconnected */
          _tp_dbus_daemon_get_name_owner_notify (pc, context);
          get_name_owner_context_unref (context);
        }
      else if (!dbus_pending_call_set_notify (pc,
            _tp_dbus_daemon_get_name_owner_notify,
            context, get_name_owner_context_unref))
        {
          ERROR ("Out of memory");
        }
    }

  g_array_append_val (watch->callbacks, tmp);

  if (watch->last_owner != NULL)
    {
      /* FIXME: should avoid reentrancy? */
      callback (self, name, watch->last_owner, user_data);
    }
}

static void
_tp_dbus_daemon_stop_watching (TpDBusDaemon *self,
                               const gchar *name,
                               _NameOwnerWatch *watch)
{
  gchar *match_rule;

  /* Clean up any leftöver callbacks. */
  if (watch->callbacks->len > 0)
    {
      guint i;

      for (i = 0; i < watch->callbacks->len; i++)
        {
          _NameOwnerSubWatch *entry = &g_array_index (watch->callbacks,
              _NameOwnerSubWatch, i);

          if (entry->destroy != NULL)
            entry->destroy (entry->user_data);
        }
    }

  g_array_unref (watch->callbacks);
  g_free (watch->last_owner);
  g_slice_free (_NameOwnerWatch, watch);

  match_rule = _tp_dbus_daemon_get_noc_rule (name);
  DEBUG ("Removing match rule %s", match_rule);
  dbus_bus_remove_match (self->priv->libdbus, match_rule, NULL);
  g_free (match_rule);
}

/**
 * tp_dbus_daemon_cancel_name_owner_watch: (skip)
 * @self: the D-Bus daemon
 * @name: the name that was being watched
 * @callback: the callback that was called
 * @user_data: the user data that was provided
 *
 * If there was a previous call to tp_dbus_daemon_watch_name_owner()
 * with exactly the given @name, @callback and @user_data, remove it.
 *
 * If more than one watch matching the details provided was active, remove
 * only the most recently added one.
 *
 * Returns: %TRUE if there was such a watch, %FALSE otherwise
 *
 * Since: 0.7.1
 */
gboolean
tp_dbus_daemon_cancel_name_owner_watch (TpDBusDaemon *self,
                                        const gchar *name,
                                        TpDBusDaemonNameOwnerChangedCb callback,
                                        gconstpointer user_data)
{
  _NameOwnerWatch *watch = g_hash_table_lookup (self->priv->name_owner_watches,
      name);

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (self), FALSE);
  g_return_val_if_fail (name != NULL, FALSE);
  g_return_val_if_fail (callback != NULL, FALSE);

  if (watch != NULL)
    {
      /* Check to see whether this (callback, user_data) pair is in the watch's
       * array of callbacks. */
      GArray *array = watch->callbacks;
      /* 1 greater than an index into @array, to avoid it going negative;
       * we iterate in reverse to have "last in = first out" as documented. */
      guint i;

      for (i = array->len; i > 0; i--)
        {
          _NameOwnerSubWatch *entry = &g_array_index (array,
              _NameOwnerSubWatch, i - 1);

          if (entry->callback == callback && entry->user_data == user_data)
            {
              entry->callback = NULL;
              tp_dbus_daemon_maybe_free_name_owner_watch (self, name, watch);
              return TRUE;
            }
        }
    }

  /* We haven't found it */
  return FALSE;
}

/* for internal use (TpChannel, TpConnection _new convenience functions) */
gboolean
_tp_dbus_daemon_get_name_owner (TpDBusDaemon *self,
                                gint timeout_ms,
                                const gchar *well_known_name,
                                gchar **unique_name,
                                GError **error)
{
  DBusGConnection *gconn;
  DBusConnection *dbc;
  DBusMessage *message;
  DBusMessage *reply;
  DBusError dbus_error;
  const char *name_in_reply;
  const GError *invalidated;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (self), FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  invalidated = tp_proxy_get_invalidated (self);

  if (invalidated != NULL)
    {
      if (error != NULL)
        *error = g_error_copy (invalidated);

      return FALSE;
    }

  gconn = tp_proxy_get_dbus_connection (self);
  dbc = dbus_g_connection_get_connection (gconn);

  message = dbus_message_new_method_call (DBUS_SERVICE_DBUS, DBUS_PATH_DBUS,
      DBUS_INTERFACE_DBUS, "GetNameOwner");

  if (message == NULL)
    ERROR ("Out of memory");

  if (!dbus_message_append_args (message,
        DBUS_TYPE_STRING, &well_known_name,
        DBUS_TYPE_INVALID))
    ERROR ("Out of memory");

  dbus_error_init (&dbus_error);
  reply = dbus_connection_send_with_reply_and_block (dbc, message,
      timeout_ms, &dbus_error);

  dbus_message_unref (message);

  if (reply == NULL)
    {
      if (!tp_strdiff (dbus_error.name, DBUS_ERROR_NO_MEMORY))
        ERROR ("Out of memory");

      /* FIXME: ideally we'd use dbus-glib's error mapping for this */
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_NAME_OWNER_LOST,
          "%s: %s", dbus_error.name, dbus_error.message);

      dbus_error_free (&dbus_error);
      return FALSE;
    }

  if (!dbus_message_get_args (reply, &dbus_error,
        DBUS_TYPE_STRING, &name_in_reply,
        DBUS_TYPE_INVALID))
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_NAME_OWNER_LOST,
          "%s: %s", dbus_error.name, dbus_error.message);

      dbus_error_free (&dbus_error);
      dbus_message_unref (reply);
      return FALSE;
    }

  if (unique_name != NULL)
    *unique_name = g_strdup (name_in_reply);

  dbus_message_unref (reply);

  return TRUE;
}

/**
 * tp_dbus_daemon_request_name:
 * @self: a TpDBusDaemon
 * @well_known_name: a well-known name to acquire
 * @idempotent: whether to consider it to be a success if this process
 *              already owns the name
 * @error: used to raise an error if %FALSE is returned
 *
 * Claim the given well-known name without queueing, allowing replacement
 * or replacing an existing name-owner. This makes a synchronous call to the
 * bus daemon.
 *
 * Returns: %TRUE if @well_known_name was claimed, or %FALSE and sets @error if
 *          an error occurred.
 *
 * Since: 0.7.30
 */
gboolean
tp_dbus_daemon_request_name (TpDBusDaemon *self,
                             const gchar *well_known_name,
                             gboolean idempotent,
                             GError **error)
{
  TpProxy *as_proxy = (TpProxy *) self;
  DBusGConnection *gconn;
  DBusConnection *dbc;
  DBusError dbus_error;
  int result;
  const GError *invalidated;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (self), FALSE);
  g_return_val_if_fail (tp_dbus_check_valid_bus_name (well_known_name,
        TP_DBUS_NAME_TYPE_WELL_KNOWN, error), FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  invalidated = tp_proxy_get_invalidated (self);

  if (invalidated != NULL)
    {
      if (error != NULL)
        *error = g_error_copy (invalidated);

      return FALSE;
    }

  gconn = as_proxy->dbus_connection;
  dbc = dbus_g_connection_get_connection (gconn);

  dbus_error_init (&dbus_error);
  result = dbus_bus_request_name (dbc, well_known_name,
      DBUS_NAME_FLAG_DO_NOT_QUEUE, &dbus_error);

  switch (result)
    {
    case DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER:
      return TRUE;

    case DBUS_REQUEST_NAME_REPLY_ALREADY_OWNER:
      if (idempotent)
        {
          return TRUE;
        }
      else
        {
          g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
              "Name '%s' already in use by this process", well_known_name);
          return FALSE;
        }

    case DBUS_REQUEST_NAME_REPLY_EXISTS:
    case DBUS_REQUEST_NAME_REPLY_IN_QUEUE:
      /* the latter shouldn't actually happen since we said DO_NOT_QUEUE */
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Name '%s' already in use by another process", well_known_name);
      return FALSE;

    case -1:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "%s: %s", dbus_error.name, dbus_error.message);
      dbus_error_free (&dbus_error);
      return FALSE;

    default:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "RequestName('%s') returned %d and I don't know what that means",
          well_known_name, result);
      return FALSE;
    }
}

/**
 * tp_dbus_daemon_release_name:
 * @self: a TpDBusDaemon
 * @well_known_name: a well-known name owned by this process to release
 * @error: used to raise an error if %FALSE is returned
 *
 * Release the given well-known name. This makes a synchronous call to the bus
 * daemon.
 *
 * Returns: %TRUE if @well_known_name was released, or %FALSE and sets @error
 *          if an error occurred.
 *
 * Since: 0.7.30
 */
gboolean
tp_dbus_daemon_release_name (TpDBusDaemon *self,
                             const gchar *well_known_name,
                             GError **error)
{
  TpProxy *as_proxy = (TpProxy *) self;
  DBusGConnection *gconn;
  DBusConnection *dbc;
  DBusError dbus_error;
  int result;
  const GError *invalidated;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (self), FALSE);
  g_return_val_if_fail (tp_dbus_check_valid_bus_name (well_known_name,
        TP_DBUS_NAME_TYPE_WELL_KNOWN, error), FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  invalidated = tp_proxy_get_invalidated (self);

  if (invalidated != NULL)
    {
      if (error != NULL)
        *error = g_error_copy (invalidated);

      return FALSE;
    }

  gconn = as_proxy->dbus_connection;
  dbc = dbus_g_connection_get_connection (gconn);
  dbus_error_init (&dbus_error);
  result = dbus_bus_release_name (dbc, well_known_name, &dbus_error);

  switch (result)
    {
    case DBUS_RELEASE_NAME_REPLY_RELEASED:
      return TRUE;

    case DBUS_RELEASE_NAME_REPLY_NOT_OWNER:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_YOURS,
          "Name '%s' owned by another process", well_known_name);
      return FALSE;

    case DBUS_RELEASE_NAME_REPLY_NON_EXISTENT:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Name '%s' not owned", well_known_name);
      return FALSE;

    case -1:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "%s: %s", dbus_error.name, dbus_error.message);
      dbus_error_free (&dbus_error);
      return FALSE;

    default:
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "ReleaseName('%s') returned %d and I don't know what that means",
          well_known_name, result);
      return FALSE;
    }
}

/**
 * tp_dbus_daemon_register_object:
 * @self: object representing a connection to a bus
 * @object_path: an object path
 * @object: (type GObject.Object) (transfer none): an object to export
 *
 * Export @object at @object_path. This is a convenience wrapper around
 * dbus_g_connection_register_g_object(), and behaves similarly.
 *
 * Since: 0.11.3
 */
void
tp_dbus_daemon_register_object (TpDBusDaemon *self,
    const gchar *object_path,
    gpointer object)
{
  TpProxy *as_proxy = (TpProxy *) self;

  g_return_if_fail (TP_IS_DBUS_DAEMON (self));
  g_return_if_fail (tp_dbus_check_valid_object_path (object_path, NULL));
  g_return_if_fail (G_IS_OBJECT (object));

  dbus_g_connection_register_g_object (as_proxy->dbus_connection,
      object_path, object);
}

/**
 * tp_dbus_daemon_unregister_object:
 * @self: object representing a connection to a bus
 * @object: (type GObject.Object) (transfer none): an object previously exported
 * with tp_dbus_daemon_register_object()
 *
 * Stop exporting @object on D-Bus. This is a convenience wrapper around
 * dbus_g_connection_unregister_g_object(), and behaves similarly.
 *
 * Since: 0.11.3
 */
void
tp_dbus_daemon_unregister_object (TpDBusDaemon *self,
    gpointer object)
{
  TpProxy *as_proxy = (TpProxy *) self;

  g_return_if_fail (TP_IS_DBUS_DAEMON (self));
  g_return_if_fail (G_IS_OBJECT (object));

  dbus_g_connection_unregister_g_object (as_proxy->dbus_connection, object);
}

/**
 * tp_dbus_daemon_get_unique_name:
 * @self: object representing a connection to a bus
 *
 * <!-- Returns: is enough -->
 *
 * Returns: the unique name of this connection to the bus, which is valid for
 *  as long as this #TpDBusDaemon is
 * Since: 0.7.35
 */
const gchar *
tp_dbus_daemon_get_unique_name (TpDBusDaemon *self)
{
  g_return_val_if_fail (TP_IS_DBUS_DAEMON (self), NULL);

  return dbus_bus_get_unique_name (self->priv->libdbus);
}

typedef struct {
    TpDBusDaemon *self;
    DBusMessage *reply;
    TpDBusDaemonListNamesCb callback;
    gpointer user_data;
    GDestroyNotify destroy;
    gpointer weak_object;
    gsize refs;
} ListNamesContext;

static ListNamesContext *
list_names_context_new (TpDBusDaemon *self,
    TpDBusDaemonListNamesCb callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  ListNamesContext *context = g_slice_new (ListNamesContext);

  context->self = g_object_ref (self);
  context->reply = NULL;
  context->callback = callback;
  context->user_data = user_data;
  context->destroy = destroy;
  context->weak_object = weak_object;

  if (context->weak_object != NULL)
    g_object_add_weak_pointer (weak_object, &context->weak_object);

  context->refs = 1;
  return context;
}

static void
list_names_context_unref (gpointer data)
{
  ListNamesContext *context = data;

  if (--context->refs == 0)
    {
      g_object_unref (context->self);

      if (context->reply != NULL)
        dbus_message_unref (context->reply);

      if (context->destroy != NULL)
        context->destroy (context->user_data);

      context->destroy = NULL;

      if (context->weak_object != NULL)
        g_object_remove_weak_pointer (context->weak_object,
            &context->weak_object);

      g_slice_free (ListNamesContext, context);
    }
}

static gboolean
_tp_dbus_daemon_list_names_idle (gpointer data)
{
  ListNamesContext *context = data;
  char **array = NULL;
  const gchar * const *result = NULL;
  GError *error = NULL;

  if (context->callback == NULL)
    {
      DEBUG ("Caller no longer cares (weak object vanished), ignoring");
      return FALSE;
    }

  if (context->reply == NULL)
    {
      g_set_error_literal (&error, DBUS_GERROR, DBUS_GERROR_DISCONNECTED,
          "DBusConnection disconnected");
    }
  else if (dbus_message_get_type (context->reply) ==
      DBUS_MESSAGE_TYPE_METHOD_RETURN)
    {
      int n_elements;

      if (dbus_message_get_args (context->reply, NULL,
            DBUS_TYPE_ARRAY, DBUS_TYPE_STRING, &array, &n_elements,
            DBUS_TYPE_INVALID))
        {
          result = (const gchar * const *) array;
          g_assert (result[n_elements] == NULL);
        }
      else
        {
          g_set_error_literal (&error, DBUS_GERROR, DBUS_GERROR_INVALID_ARGS,
              "Malformed reply from List*Names()");
        }
    }
  else
    {
      DBusError dbus_error = DBUS_ERROR_INIT;

      if (dbus_set_error_from_message (&dbus_error, context->reply))
        {
          /* FIXME: ideally we'd use dbus-glib's error mapping here, but we
           * don't have access to it */
          g_set_error (&error, DBUS_GERROR, DBUS_GERROR_FAILED,
              "List*Names() raised %s: %s", dbus_error.name,
              dbus_error.message);
          dbus_error_free (&dbus_error);
        }
      else
        {
          g_set_error_literal (&error, DBUS_GERROR, DBUS_GERROR_INVALID_ARGS,
              "Unexpected message type from List*Names()");
        }
    }

  if (error != NULL)
    DEBUG ("%s", error->message);

  context->callback (context->self, result, error, context->user_data,
      context->weak_object);
  dbus_free_string_array (array);   /* NULL-safe */
  return FALSE;
}

static void
_tp_dbus_daemon_list_names_notify (DBusPendingCall *pc,
                                   gpointer data)
{
  ListNamesContext *context = data;

  /* we recycle this function for the case where the connection is already
   * disconnected: in that case we use pc = NULL */
  if (pc != NULL)
    context->reply = dbus_pending_call_steal_reply (pc);

  /* We have to do the real work in an idle, so we don't break re-entrant
   * calls (the dbus-glib event source isn't re-entrant) */
  context->refs++;
  g_idle_add_full (G_PRIORITY_HIGH, _tp_dbus_daemon_list_names_idle,
      context, list_names_context_unref);

  if (pc != NULL)
    dbus_pending_call_unref (pc);
}

/**
 * TpDBusDaemonListNamesCb:
 * @bus_daemon: object representing a connection to a bus
 * @names: constant %NULL-terminated array of constant strings representing
 *  bus names, or %NULL on error
 * @error: the error that occurred, or %NULL on success
 * @user_data: the same user data that was passed to
 *  tp_dbus_daemon_list_names or tp_dbus_daemon_list_activatable_names
 * @weak_object: the same object that was passed to
 *  tp_dbus_daemon_list_names or tp_dbus_daemon_list_activatable_names
 *
 * Signature of a callback for functions that list bus names.
 *
 * Since: 0.7.35
 */

static void
_tp_dbus_daemon_list_names_common (TpDBusDaemon *self,
    const gchar *method,
    gint timeout_ms,
    TpDBusDaemonListNamesCb callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  DBusMessage *message;
  DBusPendingCall *pc = NULL;
  ListNamesContext *context;

  g_return_if_fail (TP_IS_DBUS_DAEMON (self));
  g_return_if_fail (callback != NULL);
  g_return_if_fail (weak_object == NULL || G_IS_OBJECT (weak_object));

  message = dbus_message_new_method_call (DBUS_SERVICE_DBUS,
      DBUS_PATH_DBUS, DBUS_INTERFACE_DBUS, method);

  if (message == NULL)
    ERROR ("Out of memory");

  if (!dbus_connection_send_with_reply (self->priv->libdbus,
      message, &pc, timeout_ms))
    ERROR ("Out of memory");
  /* pc is unreffed by _tp_dbus_daemon_list_names_notify */
  dbus_message_unref (message);

  context = list_names_context_new (self, callback, user_data, destroy,
    weak_object);

  if (pc == NULL || dbus_pending_call_get_completed (pc))
    {
      /* pc can be NULL when the connection is already disconnected */
      _tp_dbus_daemon_list_names_notify (pc, context);
      list_names_context_unref (context);
    }
  else if (!dbus_pending_call_set_notify (pc,
        _tp_dbus_daemon_list_names_notify, context,
        list_names_context_unref))
    {
      ERROR ("Out of memory");
    }
}

/**
 * tp_dbus_daemon_list_names:
 * @self: object representing a connection to a bus
 * @timeout_ms: timeout for the call
 * @callback: callback to be called on success or failure; must not be %NULL
 * @user_data: opaque user-supplied data to pass to the callback
 * @destroy: if not %NULL, called with @user_data as argument after the call
 *  has succeeded or failed, or after @weak_object has been destroyed
 * @weak_object: if not %NULL, a GObject which will be weakly referenced; if
 *  it is destroyed, @callback will not be called at all
 *
 * Call the ListNames method on the bus daemon, asynchronously. The @callback
 * will be called from the main loop with a list of all the names (either
 * unique or well-known) that exist on the bus.
 *
 * In versions of telepathy-glib that have it, this should be preferred
 * instead of calling tp_cli_dbus_daemon_call_list_names(), since that
 * function will result in wakeups for every NameOwnerChanged signal.
 *
 * Since: 0.7.35
 */
void
tp_dbus_daemon_list_names (TpDBusDaemon *self,
    gint timeout_ms,
    TpDBusDaemonListNamesCb callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  _tp_dbus_daemon_list_names_common (self, "ListNames", timeout_ms,
      callback, user_data, destroy, weak_object);
}

/**
 * tp_dbus_daemon_list_activatable_names:
 * @self: object representing a connection to a bus daemon
 * @timeout_ms: timeout for the call
 * @callback: callback to be called on success or failure; must not be %NULL
 * @user_data: opaque user-supplied data to pass to the callback
 * @destroy: if not %NULL, called with @user_data as argument after the call
 *  has succeeded or failed, or after @weak_object has been destroyed
 * @weak_object: if not %NULL, a GObject which will be weakly referenced; if
 *  it is destroyed, @callback will not be called at all
 *
 * Call the ListActivatableNames method on the bus daemon, asynchronously.
 * The @callback will be called from the main loop with a list of all the
 * well-known names that are available for service-activation on the bus.
 *
 * In versions of telepathy-glib that have it, this should be preferred
 * instead of calling tp_cli_dbus_daemon_call_list_activatable_names(), since
 * that function will result in wakeups for every NameOwnerChanged signal.
 *
 * Since: 0.7.35
 */
void
tp_dbus_daemon_list_activatable_names (TpDBusDaemon *self,
    gint timeout_ms,
    TpDBusDaemonListNamesCb callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  _tp_dbus_daemon_list_names_common (self, "ListActivatableNames", timeout_ms,
      callback, user_data, destroy, weak_object);
}

static void
free_daemon_list (gpointer p)
{
  GSList **slistp = p;

  g_slist_free (*slistp);
  g_slice_free (GSList *, slistp);
}

/* If you add more slice-allocation in this function, make the suppression
 * "tp_dbus_daemon_constructor @daemons once per DBusConnection" in
 * telepathy-glib.supp more specific. */
static GObject *
tp_dbus_daemon_constructor (GType type,
                            guint n_params,
                            GObjectConstructParam *params)
{
  GObjectClass *object_class =
      (GObjectClass *) tp_dbus_daemon_parent_class;
  TpDBusDaemon *self = TP_DBUS_DAEMON (object_class->constructor (type,
        n_params, params));
  TpProxy *as_proxy = (TpProxy *) self;
  GSList **daemons;

  g_assert (!tp_strdiff (as_proxy->bus_name, DBUS_SERVICE_DBUS));
  g_assert (!tp_strdiff (as_proxy->object_path, DBUS_PATH_DBUS));

  self->priv->libdbus = dbus_connection_ref (
      dbus_g_connection_get_connection (
        tp_proxy_get_dbus_connection (self)));

  /* one ref per TpDBusDaemon, released in finalize */
  if (!dbus_connection_allocate_data_slot (&daemons_slot))
    ERROR ("Out of memory");

  daemons = dbus_connection_get_data (self->priv->libdbus, daemons_slot);

  if (daemons == NULL)
    {
      /* This slice is never freed; it's a one-per-DBusConnection leak. */
      daemons = g_slice_new (GSList *);

      *daemons = NULL;
      dbus_connection_set_data (self->priv->libdbus, daemons_slot, daemons,
          free_daemon_list);

      /* we add this filter at most once per DBusConnection */
      if (!dbus_connection_add_filter (self->priv->libdbus,
            _tp_dbus_daemon_name_owner_changed_filter, NULL, NULL))
        ERROR ("Out of memory");
    }

  *daemons = g_slist_prepend (*daemons, self);

  return (GObject *) self;
}

static void
tp_dbus_daemon_init (TpDBusDaemon *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_DBUS_DAEMON,
      TpDBusDaemonPrivate);

  self->priv->name_owner_watches = g_hash_table_new_full (g_str_hash,
      g_str_equal, g_free, NULL);
}

static void
tp_dbus_daemon_dispose (GObject *object)
{
  TpDBusDaemon *self = TP_DBUS_DAEMON (object);
  GSList **daemons;

  if (self->priv->name_owner_watches != NULL)
    {
      GHashTable *tmp = self->priv->name_owner_watches;
      GHashTableIter iter;
      gpointer k, v;

      self->priv->name_owner_watches = NULL;
      g_hash_table_iter_init (&iter, tmp);

      while (g_hash_table_iter_next (&iter, &k, &v))
        {
          _NameOwnerWatch *watch = v;

          /* it refs us while invoking stuff */
          g_assert (watch->invoking == 0);
          _tp_dbus_daemon_stop_watching (self, k, watch);
          g_hash_table_iter_remove (&iter);
        }

      g_hash_table_unref (tmp);
    }

  if (self->priv->libdbus != NULL)
    {
      /* remove myself from the list to be notified on NoC */
      daemons = dbus_connection_get_data (self->priv->libdbus, daemons_slot);

      /* should always be non-NULL, barring bugs */
      if (G_LIKELY (daemons != NULL))
        {
          *daemons = g_slist_remove (*daemons, self);

          if (*daemons == NULL)
            {
              /* this results in a call to free_daemon_list (daemons) */
              dbus_connection_set_data (self->priv->libdbus, daemons_slot,
                  NULL, NULL);
            }
        }

      dbus_connection_unref (self->priv->libdbus);
      self->priv->libdbus = NULL;
    }

  G_OBJECT_CLASS (tp_dbus_daemon_parent_class)->dispose (object);
}

static void
tp_dbus_daemon_finalize (GObject *object)
{
  GObjectFinalizeFunc chain_up = G_OBJECT_CLASS (tp_dbus_daemon_parent_class)->finalize;

  /* one ref per TpDBusDaemon, from constructor */
  dbus_connection_free_data_slot (&daemons_slot);

  if (chain_up != NULL)
    chain_up (object);
}

/**
 * tp_dbus_daemon_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpDBusDaemon have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_DBUS_DAEMON.
 *
 * Since: 0.7.32
 */
void
tp_dbus_daemon_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (TP_TYPE_DBUS_DAEMON,
          tp_cli_dbus_daemon_add_signals);

      g_once_init_leave (&once, 1);
    }
}

static void
tp_dbus_daemon_class_init (TpDBusDaemonClass *klass)
{
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;

  tp_dbus_daemon_init_known_interfaces ();

  g_type_class_add_private (klass, sizeof (TpDBusDaemonPrivate));

  object_class->constructor = tp_dbus_daemon_constructor;
  object_class->dispose = tp_dbus_daemon_dispose;
  object_class->finalize = tp_dbus_daemon_finalize;

  proxy_class->interface = TP_IFACE_QUARK_DBUS_DAEMON;
}

gboolean
_tp_dbus_daemon_is_the_shared_one (TpDBusDaemon *self)
{
  return (self != NULL && self == starter_bus_daemon);
}

/* Auto-generated implementation of _tp_register_dbus_glib_marshallers */
#include "_gen/register-dbus-glib-marshallers-body.h"
