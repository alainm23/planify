/*
 * debug.c - Common debug support
 * Copyright (C) 2007 Collabora Ltd.
 * Copyright (C) 2007 Nokia Corporation
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
 * SECTION:debug
 * @title: Common debug support
 * @short_description: API to activate debugging messages from telepathy-glib
 *
 * telepathy-glib has an internal mechanism for debug messages and filtering.
 * Connection managers written with telepathy-glib are expected to connect
 * this to their own debugging mechanisms: when the CM's debugging mechanism
 * is activated, it should call tp_debug_set_flags() and/or
 * tp_debug_set_persistent().
 *
 * The supported debug-mode keywords and the debug messages that they enable
 * are subject to change, but currently include:
 *
 * <itemizedlist>
 * <listitem><literal>misc</literal> - low-level utility code</listitem>
 * <listitem><literal>manager</literal> -
 *    #TpConnectionManager (client)</listitem>
 * <listitem><literal>connection</literal> - #TpBaseConnection (service)
 *    and #TpConnection (client)</listitem>
 * <listitem><literal>contacts</literal> - #TpContact objects
 *    (client)</listitem>
 * <listitem><literal>channel</literal> - #TpChannel (client)</listitem>
 * <listitem><literal>im</literal> - (text) instant messaging
 *    (service)</listitem>
 * <listitem><literal>properties</literal> -
 *    <link linkend="telepathy-glib-dbus-properties-mixin">TpDBusPropertiesMixin</link> and #TpPropertiesMixin (service)</listitem>
 * <listitem><literal>params</literal> - connection manager parameters
 *    (service)</listitem>
 * <listitem><literal>handles</literal> - handle reference tracking tracking
 *    in #TpBaseConnection (service) and #TpConnection (client)</listitem>
 * <listitem><literal>accounts</literal> - the #TpAccountManager and
 *     #TpAccount objects (client)</listitem>
 * <listitem><literal>contact-lists</literal> - the #TpBaseContactList
 *    (service)</listitem>
 * <listitem><literal>debugger</literal> - #TpDebugClient objects</listitem>
 * <listitem><literal>tls</literal> - #TpTLSCertificate objects
 *     (client)</listitem>
 * <listitem><literal>all</literal> - all of the above</listitem>
 * </itemizedlist>
 */
#include "config.h"

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <sys/stat.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <glib.h>
#include <glib/gstdio.h>

#include <telepathy-glib/debug.h>

#define DEBUG_FLAG TP_DEBUG_MISC
#include "debug-internal.h"

static TpDebugFlags flags = 0;

static gboolean tp_debug_persistent = FALSE;

/**
 * tp_debug_set_all_flags: (skip)
 *
 * Activate all possible debug modes. This also activates persistent mode,
 * which should have been orthogonal.
 *
 * Deprecated: since 0.6.1. Use tp_debug_set_flags ("all") and
 * tp_debug_set_persistent() instead.
 */
void
tp_debug_set_all_flags (void)
{
  flags = 0xffff;
  tp_debug_persistent = TRUE;
}

static GDebugKey keys[] = {
  { "misc",          TP_DEBUG_MISC },
  { "groups",        TP_DEBUG_GROUPS },
  { "properties",    TP_DEBUG_PROPERTIES },
  { "connection",    TP_DEBUG_CONNECTION },
  { "im",            TP_DEBUG_IM },
  { "params",        TP_DEBUG_PARAMS },
  { "presence",      TP_DEBUG_PRESENCE },
  { "manager",       TP_DEBUG_MANAGER },
  { "channel",       TP_DEBUG_CHANNEL },
  { "proxy",         TP_DEBUG_PROXY },
  { "handles",       TP_DEBUG_HANDLES },
  { "contacts",      TP_DEBUG_CONTACTS },
  { "accounts",      TP_DEBUG_ACCOUNTS },
  { "dispatcher",    TP_DEBUG_DISPATCHER },
  { "client",        TP_DEBUG_CLIENT },
  { "contact-lists", TP_DEBUG_CONTACT_LISTS },
  { "sasl",          TP_DEBUG_SASL },
  { "room-config",   TP_DEBUG_ROOM_CONFIG },
  { "call",          TP_DEBUG_CALL },
  { "debugger",      TP_DEBUG_DEBUGGER },
  { "tls",           TP_DEBUG_TLS },
  { 0, }
};

typedef struct {
  guint key;
  const gchar *domain;
} DebugKeyToDomain;

/* This is an array of debug key flags to log domains. The point of this is so
 * that once getting the index of the bit set, _tp_log() can simply index
 * this array. Aditionally, having the domain already in $domain/$category
 * format means we don't have to call g_strdup_printf() to get the desired
 * domain for each debug message logged, and then g_free() to free the newly
 * created string... */
static DebugKeyToDomain key_to_domain[] = {
  { TP_DEBUG_MISC,       G_LOG_DOMAIN "/misc" },
  { TP_DEBUG_GROUPS,     G_LOG_DOMAIN "/groups" },
  { TP_DEBUG_PROPERTIES, G_LOG_DOMAIN "/properties" },
  { TP_DEBUG_IM,         G_LOG_DOMAIN "/im" },
  { TP_DEBUG_CONNECTION, G_LOG_DOMAIN "/connection" },
  { TP_DEBUG_PARAMS,     G_LOG_DOMAIN "/params" },
  { TP_DEBUG_PRESENCE,   G_LOG_DOMAIN "/presence" },
  { TP_DEBUG_MANAGER,    G_LOG_DOMAIN "/manager" },
  { TP_DEBUG_CHANNEL,    G_LOG_DOMAIN "/channel" },
  { TP_DEBUG_PROXY,      G_LOG_DOMAIN "/proxy" },
  { TP_DEBUG_HANDLES,    G_LOG_DOMAIN "/handles" },
  { TP_DEBUG_CONTACTS,   G_LOG_DOMAIN "/contacts" },
  { TP_DEBUG_ACCOUNTS,   G_LOG_DOMAIN "/accounts" },
  { TP_DEBUG_DISPATCHER, G_LOG_DOMAIN "/dispatcher" },
  { TP_DEBUG_CLIENT,     G_LOG_DOMAIN "/client" },
  { TP_DEBUG_CONTACT_LISTS, G_LOG_DOMAIN "/contact-lists" },
  { TP_DEBUG_SASL,       G_LOG_DOMAIN "/sasl" },
  { TP_DEBUG_ROOM_CONFIG, G_LOG_DOMAIN "/room-config" },
  { TP_DEBUG_DEBUGGER,   G_LOG_DOMAIN "/debugger" },
  { TP_DEBUG_TLS,        G_LOG_DOMAIN "/tls" },
  { 0, NULL }
};

static GDebugKey persist_keys[] = {
  { "persist",       1 },
  { 0, },
};

/**
 * tp_debug_set_flags:
 * @flags_string: The flags to set, comma-separated. If %NULL or empty,
 *  no additional flags are set.
 *
 * Set the debug flags indicated by @flags_string, in addition to any already
 * set.
 *
 * The parsing matches that of g_parse_debug_string().
 *
 * If telepathy-glib was compiled with --disable-debug (not recommended),
 * this function has no practical effect, since the debug messages it would
 * enable were removed at compile time.
 *
 * Since: 0.6.1
 */
void
tp_debug_set_flags (const gchar *flags_string)
{
  guint nkeys;

  for (nkeys = 0; keys[nkeys].value; nkeys++);

  if (flags_string != NULL)
    _tp_debug_set_flags (g_parse_debug_string (flags_string, keys, nkeys));
}

/**
 * tp_debug_set_flags_from_string: (skip)
 * @flags_string: The flags to set, comma-separated. If %NULL or empty,
 *  no additional flags are set.
 *
 * Set the debug flags indicated by @flags_string, in addition to any already
 * set. Unlike tp_debug_set_flags(), this enables persistence like
 * tp_debug_set_persistent() if the "persist" flag is present or the string
 * is "all" - this turns out to be unhelpful, as persistence should be
 * orthogonal.
 *
 * The parsing matches that of g_parse_debug_string().
 *
 * Deprecated: since 0.6.1. Use tp_debug_set_flags() and
 * tp_debug_set_persistent() instead
 */
void
tp_debug_set_flags_from_string (const gchar *flags_string)
{
  tp_debug_set_flags (flags_string);

  if (flags_string != NULL &&
      g_parse_debug_string (flags_string, persist_keys, 1) != 0)
    tp_debug_set_persistent (TRUE);
}

/**
 * tp_debug_set_flags_from_env: (skip)
 * @var: The name of the environment variable to parse
 *
 * Equivalent to
 * <literal>tp_debug_set_flags_from_string (g_getenv (var))</literal>,
 * and has the same problem with persistence being included in "all".
 *
 * Deprecated: since 0.6.1. Use tp_debug_set_flags(g_getenv(...)) and
 * tp_debug_set_persistent() instead
 */
void
tp_debug_set_flags_from_env (const gchar *var)
{
  const gchar *val = g_getenv (var);

  tp_debug_set_flags (val);
  if (val != NULL && g_parse_debug_string (val, persist_keys, 1) != 0)
    tp_debug_set_persistent (TRUE);
}

/**
 * tp_debug_set_persistent:
 * @persistent: TRUE prevents the connection manager mainloop from exiting,
 *              FALSE enables exiting if there are no connections
 *              (the default behavior).
 *
 * Used to enable persistent operation of the connection manager process for
 * debugging purposes.
 */
void
tp_debug_set_persistent (gboolean persistent)
{
  tp_debug_persistent = persistent;
}

/*
 * _tp_debug_set_flags:
 * @new_flags More flags to set
 *
 * Set extra flags. For internal use only
 */
void
_tp_debug_set_flags (TpDebugFlags new_flags)
{
  flags |= new_flags;
}

/*
 * _tp_debug_set_flags:
 * @flag: Flag to test
 *
 * Returns: %TRUE if the flag is set. For use via DEBUGGING() only.
 */
gboolean
_tp_debug_flag_is_set (TpDebugFlags flag)
{
  return (flag & flags) != 0;
}

static const gchar *
debug_flag_to_domain (TpDebugFlags flag)
{
  gint index, max;

  /* First bit set of @flag. This to make sure we only have one bit (in the
   * unlikely scenario that multiple debug flags were set). This enables us to
   * index the #key_to_domain array, instead of having to iterate it looking
   * for the right key. */
  index = g_bit_nth_lsf (flag, -1);

  /* The maximum valid index of the #key_to_domain array. Decrement it by one
   * because there is the blank { 0, NULL } item on the end which we want to
   * ignore. */
  max = G_N_ELEMENTS (key_to_domain) - 1;

  /* If the index we got isn't valid, just return "misc". */
  if (index < 0 || index >= max)
    return G_LOG_DOMAIN "/misc";
  else
    return key_to_domain[index].domain;
}

/*
 * _tp_log:
 * @level: Log level
 * @flag: Debug flag
 * @format: Format string for g_logv
 *
 * Emit a debug message with the given format and arguments, but only
 * if the given debug flag is set. For use via
 * ERROR()/CRITICAL()/.../DEBUG() only.
 */
void _tp_log (GLogLevelFlags level,
              TpDebugFlags flag,
              const gchar *format,
              ...)
{
  if ((flag & flags) || level > G_LOG_LEVEL_DEBUG)
    {
      va_list args;
      va_start (args, format);
      g_logv (debug_flag_to_domain (flag), level, format, args);
      va_end (args);
    }
}

/*
 * _tp_debug_is_persistent:
 *
 * Returns: %TRUE if persistent mainloop behavior has been enabled with
 * tp_debug_set_persistent().
 */
gboolean
_tp_debug_is_persistent (void)
{
  return tp_debug_persistent;
}

/**
 * tp_debug_divert_messages:
 * @filename: A file to which to divert stdout and stderr, or %NULL to
 *  do nothing
 *
 * Open the given file for writing and duplicate its file descriptor to
 * be used for stdout and stderr. This has the effect of closing the previous
 * stdout and stderr, and sending all messages that would have gone there
 * to the given file instead.
 *
 * By default the file is truncated and hence overwritten each time the
 * process is executed.
 * Since version 0.7.14, if the filename is prefixed with '+' then the
 * file is not truncated and output is added at the end of the file.
 *
 * Passing %NULL to this function is guaranteed to have no effect. This is
 * so you can call it with the recommended usage
 * <literal>tp_debug_divert_messages (g_getenv ("MYAPP_LOGFILE"))</literal>
 * and it won't do anything if the environment variable is not set.
 *
 * This function still works if telepathy-glib was compiled without debug
 * support.
 *
 * Since: 0.7.1
 */
void
tp_debug_divert_messages (const gchar *filename)
{
  int fd;

  if (filename == NULL)
    return;

  if (filename[0] == '+')
    {
      /* open in append mode */
      fd = g_open (filename + 1, O_WRONLY | O_CREAT | O_APPEND, 0644);
    }
  else
    {
      /* open in trunc mode */
      fd = g_open (filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    }

  if (fd == -1)
    {
      WARNING ("Can't open logfile '%s': %s", filename,
          g_strerror (errno));
      return;
    }

  if (dup2 (fd, 1) == -1)     /* STDOUT_FILENO is less universal */
    {
      WARNING ("Error duplicating stdout file descriptor: %s",
          g_strerror (errno));
      return;
    }

  if (dup2 (fd, 2) == -1)     /* STDERR_FILENO is less universal */
    {
      WARNING ("Error duplicating stderr file descriptor: %s",
          g_strerror (errno));
    }

  /* avoid leaking the fd */
  if (close (fd) != 0)
    {
      WARNING ("Error closing temporary logfile fd: %s", g_strerror (errno));
    }
}

/**
 * tp_debug_timestamped_log_handler:
 * @log_domain: the message's log domain
 * @log_level: the log level of the message
 * @message: the message to process
 * @ignored: not used
 *
 * A #GLogFunc that prepends the UTC time (currently in ISO 8601 format,
 * with microsecond resolution) to the message, then calls
 * g_log_default_handler.
 *
 * Intended usage is:
 *
 * <informalexample><programlisting>if (g_getenv ("MYPROG_TIMING") != NULL)
 *   g_log_set_default_handler (tp_debug_timestamped_log_handler, NULL);
 * </programlisting></informalexample>
 *
 * If telepathy-glib was compiled with --disable-debug (not recommended),
 * this function is equivalent to g_log_default_handler().
 *
 * Changed in 0.9.0: timestamps are now printed in UTC, in
 * RFC-3339 format. Previously, they were printed in local time, in a
 * format similar to RFC-3339.
 *
 * Since: 0.7.1
 */
void
tp_debug_timestamped_log_handler (const gchar *log_domain,
                                  GLogLevelFlags log_level,
                                  const gchar *message,
                                  gpointer ignored)
{
#ifdef ENABLE_DEBUG
  GTimeVal now;
  gchar *tmp, *now_str;

  g_get_current_time (&now);
  now_str = g_time_val_to_iso8601 (&now);
  tmp = g_strdup_printf ("%s: %s", now_str, message);
  g_free (now_str);
  message = tmp;
#endif

  g_log_default_handler (log_domain, log_level, message, NULL);

#ifdef ENABLE_DEBUG
  g_free (tmp);
#endif
}
