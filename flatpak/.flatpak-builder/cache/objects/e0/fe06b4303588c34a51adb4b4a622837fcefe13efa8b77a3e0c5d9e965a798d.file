/*
 * Copyright (C) 2011 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#include <stdlib.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <dee.h>

static gchar    *resource_name = NULL;
static gchar    *model_name = NULL;
static gchar    *peer_name = NULL;
static gboolean  linger;
static gboolean  private;
static gboolean  server;
static gboolean  watch_changes;

static GOptionEntry option_entries[] = {
    { "resource", 'r', 0, G_OPTION_ARG_STRING, &resource_name,
      "Dump a resource given by name" },
    { "model", 'm', 0, G_OPTION_ARG_STRING, &model_name,
      "Dump a model given by name" },
    { "peer", 'p', 0, G_OPTION_ARG_STRING, &peer_name,
      "List peers and leader of a swarm" },
    { "linger", '\0', 0, G_OPTION_ARG_NONE, &linger,
      "Don't exit, but keep the process running the mainloop" },
    { "private", '\0', 0, G_OPTION_ARG_NONE, &private,
      "Use a private (aka peer-2-peer) DBus connection" },
    { "server", '\0', 0, G_OPTION_ARG_NONE, &server,
      "Set up a private DBus server. Implies --private and --linger" },
    { "watch-changes", '\0', 0, G_OPTION_ARG_NONE, &watch_changes,
      "Watch for changes to the given resource. Implies --linger" },
    { NULL }
};

static void
dump_resource (const gchar *name)
{
  DeeResourceManager *rs;
  GObject            *r;
  GError             *error;
  GVariant           *v;
  gchar              *dump;

  rs = dee_resource_manager_get_default ();

  error = NULL;
  r = dee_resource_manager_load (rs, name, &error);

  if (error)
    {
      g_printerr ("Failed loading resource '%s': %s\n", name, error->message);
      exit (4);
    }

  if (!r)
    {
      g_printerr ("No parser registered for resource '%s'\n", name);
      exit (5);
    }

  v = dee_serializable_serialize (DEE_SERIALIZABLE (r));
  dump = g_variant_print (v, FALSE);

  g_printf ("%s\n", dump);

  g_free (dump);
  g_variant_unref (v);
  g_object_unref (r);

}

static guint num_rows_added = 0;
static guint num_rows_changed = 0;
static guint num_rows_deleted = 0;

static void
on_model_trasaction_begin (DeeSharedModel *model, guint64 bsq, guint64 esq,
                           gpointer user_data)
{
  guint     n_rows;
  gchar    *time_str;
  GTimeVal  time_val;

  n_rows = dee_model_get_n_rows (DEE_MODEL (model));
  g_get_current_time (&time_val);
  time_str = g_time_val_to_iso8601 (&time_val);
  g_print ("%s:\n  Transaction begin - %u rows (seqnums: "
           "%" G_GUINT64_FORMAT " - %" G_GUINT64_FORMAT ")\n",
           time_str + 11, n_rows, bsq, esq);

  num_rows_added = 0;
  num_rows_changed = 0;
  num_rows_deleted = 0;

  g_free (time_str);
}

static void
increment_callback (DeeModel *model, DeeModelIter *iter, gpointer user_data)
{
  guint *int_ptr = (guint*) user_data;
  *int_ptr = *int_ptr + 1;
}

static void
on_model_trasaction_end (DeeSharedModel *model, guint64 bsq, guint64 esq,
                         gpointer user_data)
{
  guint     n_rows;

  n_rows = dee_model_get_n_rows (DEE_MODEL (model));
  g_print ("              end - %u rows (%u added, %u changed, %u deleted)\n",
           n_rows, num_rows_added, num_rows_changed, num_rows_deleted);
}

static void
dump_model (const gchar *name)
{
  DeeSharedModel *m;
  GMainContext   *ctx;
  GVariant       *v;
  gchar          *dump;

  if (server)
    {
      m = DEE_SHARED_MODEL (dee_shared_model_new_for_peer (
                                             DEE_PEER (dee_server_new (name))));
      dee_model_set_schema (DEE_MODEL (m), "s", "i", NULL);
    }
  else if (private)
    {
      m = DEE_SHARED_MODEL (dee_shared_model_new_for_peer (
                                             DEE_PEER (dee_client_new (name))));
    }
  else
    m = DEE_SHARED_MODEL (dee_shared_model_new (name));
    
  ctx = g_main_context_default ();

  while (!dee_shared_model_is_synchronized (m))
    {
      g_main_context_iteration (ctx, TRUE);
    }

  v = dee_serializable_serialize (DEE_SERIALIZABLE (m));
  dump = g_variant_print (v, FALSE);

  g_printf ("%s\n", dump);

  if (watch_changes)
    {
      g_signal_connect (m, "begin-transaction", 
                        G_CALLBACK (on_model_trasaction_begin), NULL);
      g_signal_connect (m, "end-transaction", 
                        G_CALLBACK (on_model_trasaction_end), NULL);
      g_signal_connect (m, "row-added", 
                        G_CALLBACK (increment_callback), &num_rows_added);
      g_signal_connect (m, "row-changed", 
                        G_CALLBACK (increment_callback), &num_rows_changed);
      g_signal_connect (m, "row-removed",
                        G_CALLBACK (increment_callback), &num_rows_deleted);
    }

  if (linger)
    {
      while (TRUE)
        {
          g_main_context_iteration (ctx, TRUE);
        }
    }

  g_free (dump);
  g_variant_unref (v);
  g_object_unref (m);
}

static void
_peer_found_cb (DeePeer *p, const gchar *name)
{
  g_printf ("+ %s\n", name);
}

static void
_peer_lost_cb (DeePeer *p, const gchar *name)
{
  g_printf ("- %s\n", name);
}

static gboolean timed_out = FALSE;
static gboolean
_timeout_cb ()
{
  timed_out = TRUE;
  return FALSE;
}

static void
dump_peer (const gchar *name)
{
  DeePeer        *p;
  GMainContext   *ctx;
  
  if (server)
    p = DEE_PEER (dee_server_new (name));
  else if (private)
    p = DEE_PEER (dee_client_new (name));
  else
    p = dee_peer_new (name);
  
  ctx = g_main_context_default ();

  g_signal_connect (p, "peer-found", G_CALLBACK (_peer_found_cb), NULL);
  g_signal_connect (p, "peer-lost", G_CALLBACK (_peer_lost_cb), NULL);

  /* Wait untli we have the leader */
  while (!dee_peer_get_swarm_leader (p))
    {
      g_main_context_iteration (ctx, TRUE);
    }

  g_printf ("LEADER %s\n", dee_peer_get_swarm_leader (p));

  /* If we're serving a private conn stick around indefinitely,
   * otherwise quit after 1s */
  if (!linger)
    g_timeout_add_seconds (1, _timeout_cb, NULL);
  
  while (!timed_out)
    {
      g_main_context_iteration (ctx, TRUE);
    }
}

int
main (int argc, char *argv[])
{
  GError          *error;
  GOptionContext  *options;

#if !GLIB_CHECK_VERSION(2, 35, 1)
  g_type_init ();
#endif

  options = g_option_context_new (NULL);
  g_option_context_add_main_entries (options, option_entries, NULL);

  error = NULL;
  if (!g_option_context_parse (options, &argc, &argv, &error))
    {
      g_printerr ("Invalid command line: %s\n", error->message);
      g_error_free (error);
      return 1;
    }
  
  if (server)
    {
      private = TRUE;
      linger = TRUE;
    }

  if (watch_changes)
    {
      linger = TRUE;
    }

  if (resource_name)
    {
      if (model_name || peer_name)
        {
          g_printerr ("Invalid command line: You must specify precisely one of "
              "--resource, --model, or --peer\n");
          return 2;
        }

      dump_resource (resource_name);
    }
  else if (model_name)
    {
      if (resource_name || peer_name)
        {
          g_printerr ("Invalid command line: You must specify precisely one of "
              "--resource, --model, or --peer\n");
          return 2;
        }

      dump_model (model_name);
    }
  else if (peer_name)
    {
      if (resource_name || model_name)
        {
          g_printerr ("Invalid command line: You must specify precisely one of "
              "--resource, --model, or --peer\n");
          return 2;
        }

      dump_peer (peer_name);
    }
  else
    {
      g_printerr ("Invalid command line: Unexpected arguments\n");
      return 3;
    }

  return 0;
}
