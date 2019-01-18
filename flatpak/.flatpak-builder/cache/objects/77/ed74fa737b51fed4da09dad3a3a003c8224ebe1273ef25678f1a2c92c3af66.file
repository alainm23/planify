/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "evolution-data-server-config.h"

#include <locale.h>

#include <glib.h>
#include <glib/gi18n.h>

#include <libedataserver/libedataserver.h>

#define INDENT_LEVEL_SIZE 3

static void
print_with_indent (gint indent_level,
		   const gchar *format,
		   ...)
{
	va_list va;
	gchar *str;

	g_return_if_fail (format != NULL);

	va_start (va, format);
	str = g_strdup_vprintf (format, va);
	va_end (va);

	g_print ("%*s%s\n", indent_level * INDENT_LEVEL_SIZE, "", str);

	g_free (str);
}

static gint
compare_strings_safe (const gchar *str1,
		      const gchar *str2)
{
	if (str1 && str2)
		return g_utf8_collate (str1, str2);

	return g_strcmp0 (str1, str2);
}

static gint
sort_sources_cb (gconstpointer aa,
		 gconstpointer bb)
{
	ESource *a_source = (ESource *) aa;
	ESource *b_source = (ESource *) bb;
	gint res;

	res = compare_strings_safe (e_source_get_display_name (a_source), e_source_get_display_name (b_source));
	if (!res)
		res = compare_strings_safe (e_source_get_uid (a_source), e_source_get_uid (b_source));

	return res;
}

/* Command-Line Options */
static gboolean opt_only_enabled = FALSE;
static gboolean opt_show_uid = FALSE;
static gboolean opt_show_authentication = FALSE;
static gboolean opt_machine_readable = FALSE;
static gchar *opt_extension_name = NULL;

static GOptionEntry entries[] = {
	{ "only-enabled", 'e', 0,
	  G_OPTION_ARG_NONE, &opt_only_enabled,
	  N_("Show only enabled sources") },
	{ "show-uid", 'u', 0,
	  G_OPTION_ARG_NONE, &opt_show_uid,
	  N_("Show source’s UID") },
	{ "show-authentication", 'a', 0,
	  G_OPTION_ARG_NONE, &opt_show_authentication,
	  N_("Show source’s authentication information") },
	{ "machine-readable", 'm', 0,
	  G_OPTION_ARG_NONE, &opt_machine_readable,
	  N_("Write in machine readable format (one source per line, without localized property names and tab as separator)") },
	{ "extension-name", 'x', 0,
	  G_OPTION_ARG_STRING, &opt_extension_name,
	  N_("Limit only to sources with given extension name"),
	  NULL },
	{ NULL }
};

static const gchar *
boolean_to_string (gboolean value)
{
	if (opt_machine_readable)
		return value ? "1" : "0";

	return value ? _("yes") : _("no");
}

static void
examine_source (ESource *source,
		const gchar **out_type,
		const gchar **out_backend_name)
{
	gpointer extension = NULL;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (out_type != NULL);
	g_return_if_fail (out_backend_name != NULL);

	*out_type = "";

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
		if (opt_machine_readable)
			*out_type = "Collection";
		else
			*out_type = _("Collection");

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_GOA)) {
			if (opt_machine_readable)
				*out_type = "Collection/GOA";
			else
				*out_type = _("Collection/GNOME Online Accounts");
		} else if (e_source_has_extension (source, E_SOURCE_EXTENSION_UOA)) {
			if (opt_machine_readable)
				*out_type = "Collection/UOA";
			else
				*out_type = _("Collection/Ubuntu Online Accounts");
		}

		extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);
	} else {
		struct _extensions {
			const gchar *extension_name;
			const gchar *machine_description;
			const gchar *localized_description;
		} check_extensions[] = {
			{ E_SOURCE_EXTENSION_ADDRESS_BOOK, "AddressBook", N_("Address Book") },
			{ E_SOURCE_EXTENSION_CALENDAR, "Calendar", N_("Calendar") },
			{ E_SOURCE_EXTENSION_MEMO_LIST, "MemoList", N_("Memo List") },
			{ E_SOURCE_EXTENSION_TASK_LIST, "TaskList", N_("Task List") },
			{ E_SOURCE_EXTENSION_MAIL_ACCOUNT, "MailAccount", N_("Mail Account") },
			{ E_SOURCE_EXTENSION_MAIL_TRANSPORT, "MailTransport", N_("Mail Transport") },
			{ E_SOURCE_EXTENSION_MAIL_IDENTITY, "MailIdentity", N_("Mail Identity") },
			{ E_SOURCE_EXTENSION_MAIL_SUBMISSION, "MailSubmission", N_("Mail Submission") },
			{ E_SOURCE_EXTENSION_MAIL_SIGNATURE, "MailSignature", N_("Mail Signature") },
			{ E_SOURCE_EXTENSION_PROXY, "Proxy", N_("Proxy") }
		};
		gint ii;

		for (ii = 0; ii < G_N_ELEMENTS (check_extensions); ii++) {
			if (e_source_has_extension (source, check_extensions[ii].extension_name)) {
				if (opt_machine_readable)
					*out_type = check_extensions[ii].machine_description;
				else
					*out_type = _(check_extensions[ii].localized_description);

				extension = e_source_get_extension (source, check_extensions[ii].extension_name);
				break;
			}
		}
	}

	if (extension && E_IS_SOURCE_BACKEND (extension))
		*out_backend_name = e_source_backend_get_backend_name (extension);
	else
		*out_backend_name = NULL;
}

static void
dump_one_source (ESource *source,
		 gint indent_level)
{
	const gchar *type = NULL, *backend_name = NULL;

	g_return_if_fail (E_IS_SOURCE (source));

	examine_source (source, &type, &backend_name);

	if (opt_machine_readable) {
		g_print ("%*s%s\t%s", indent_level, "", type, e_source_get_display_name (source));
		if (opt_show_uid) {
			const gchar *parent_uid;

			g_print ("\tUID:%s", e_source_get_uid (source));

			parent_uid = e_source_get_parent (source);
			if (parent_uid && *parent_uid)
				g_print ("\tParentUID:%s", parent_uid);
		}
		if (!opt_only_enabled)
			g_print ("\tEnabled:%s", boolean_to_string (e_source_get_enabled (source)));
		if (backend_name)
			g_print ("\tBackend:%s", backend_name);

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
			ESourceCollection *collection = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

			g_print ("\tCalendarEnabled:%s", boolean_to_string (e_source_collection_get_calendar_enabled (collection)));
			g_print ("\tContactsEnabled:%s", boolean_to_string (e_source_collection_get_contacts_enabled (collection)));
			g_print ("\tMailEnabled:%s", boolean_to_string (e_source_collection_get_mail_enabled (collection)));
		}

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE)) {
			const gchar *mime_type = e_source_mail_signature_get_mime_type (e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE));

			if (mime_type && *mime_type)
				g_print ("\tMimeType:%s", mime_type);
		}
	} else {
		print_with_indent (indent_level, "%s '%s'", type, e_source_get_display_name (source));
		if (opt_show_uid) {
			const gchar *parent_uid;

			print_with_indent (indent_level + 1, _("UID: %s"), e_source_get_uid (source));

			parent_uid = e_source_get_parent (source);
			if (parent_uid && *parent_uid)
				print_with_indent (indent_level + 1, _("Parent UID: %s"), e_source_get_uid (source));
		}
		if (!opt_only_enabled)
			print_with_indent (indent_level + 1, _("Enabled: %s"), boolean_to_string (e_source_get_enabled (source)));
		if (backend_name)
			print_with_indent (indent_level + 1, _("Backend: %s"), backend_name);

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
			ESourceCollection *collection = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

			print_with_indent (indent_level + 1, _("Calendar enabled: %s"), boolean_to_string (e_source_collection_get_calendar_enabled (collection)));
			print_with_indent (indent_level + 1, _("Contacts enabled: %s"), boolean_to_string (e_source_collection_get_contacts_enabled (collection)));
			print_with_indent (indent_level + 1, _("Mail enabled: %s"), boolean_to_string (e_source_collection_get_mail_enabled (collection)));
		}

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE)) {
			const gchar *mime_type = e_source_mail_signature_get_mime_type (e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE));

			if (mime_type && *mime_type)
				print_with_indent (indent_level + 1, _("MIME Type: %s"), mime_type);
		}
	}

	if (opt_show_authentication &&
	    e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension;
		const gchar *host, *user, *method, *proxy_uid;
		guint16 port;

		auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
		host = e_source_authentication_get_host (auth_extension);
		port = e_source_authentication_get_port (auth_extension);
		user = e_source_authentication_get_user (auth_extension);
		method = e_source_authentication_get_method (auth_extension);
		proxy_uid = e_source_authentication_get_proxy_uid (auth_extension);

		if (host && *host) {
			if (port) {
				if (opt_machine_readable) {
					g_print ("\tAuthHost:%s:%d", host, port);
				} else {
					print_with_indent (indent_level + 1, _("Auth Host: %s:%d"), host, port);
				}
			} else {
				if (opt_machine_readable) {
					g_print ("\tAuthHost:%s", host);
				} else {
					print_with_indent (indent_level + 1, _("Auth Host: %s"), host);
				}
			}

			if (user && *user) {
				if (opt_machine_readable) {
					g_print ("\tAuthUser:%s", user);
				} else {
					print_with_indent (indent_level + 1, _("Auth User: %s"), user);
				}
			}

			if (method && *method) {
				if (opt_machine_readable) {
					g_print ("\tAuthMethod:%s", method);
				} else {
					print_with_indent (indent_level + 1, _("Auth Method: %s"), method);
				}
			}

			if (proxy_uid && *proxy_uid) {
				if (opt_machine_readable) {
					g_print ("\tAuthProxyUID:%s", proxy_uid);
				} else {
					print_with_indent (indent_level + 1, _("Auth Proxy UID: %s"), proxy_uid);
				}
			}
		}
	}

	if (opt_machine_readable)
		g_print ("\n");
}

static void
dump_children (const GSList *in_child_sources,
	       GHashTable *children,
	       gint indent_level)
{
	GSList *child_sources, *link;

	if (!in_child_sources)
		return;

	child_sources = g_slist_sort (g_slist_copy ((GSList *) in_child_sources), sort_sources_cb);

	for (link = child_sources; link; link = g_slist_next (link)) {
		ESource *source = link->data;

		if (link != child_sources && !opt_machine_readable && !indent_level)
			g_print ("\n");

		dump_one_source (source, indent_level);
		dump_children (g_hash_table_lookup (children, e_source_get_uid (source)), children, indent_level + 2);

		g_hash_table_remove (children, e_source_get_uid (source));
	}

	g_slist_free (child_sources);
}

static void
dump_sources (GList *sources)
{
	GHashTable *children; /* gchar * (parent-uid) ~> GSList { ESource * } */
	GList *llink;
	GSList *top_sources = NULL, *slink;

	children = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, (GDestroyNotify) g_slist_free);

	for (llink = sources; llink; llink = g_list_next (llink)) {
		ESource *source = llink->data;
		const gchar *parent_uid;

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE) &&
		    g_strcmp0 (opt_extension_name, E_SOURCE_EXTENSION_MAIL_SIGNATURE) != 0)
			continue;

		parent_uid = e_source_get_parent (source);
		if (!parent_uid || !*parent_uid) {
			top_sources = g_slist_prepend (top_sources, source);
		} else {
			g_hash_table_insert (children, g_strdup (parent_uid), g_slist_prepend (
				g_slist_copy (g_hash_table_lookup (children, parent_uid)), source));
		}
	}

	top_sources = g_slist_sort (top_sources, sort_sources_cb);

	for (slink = top_sources; slink; slink = g_slist_next (slink)) {
		ESource *source = slink->data;

		if (slink != top_sources && !opt_machine_readable)
			g_print ("\n");

		dump_one_source (source, 0);
		dump_children (g_hash_table_lookup (children, e_source_get_uid (source)), children, 2);

		g_hash_table_remove (children, e_source_get_uid (source));
	}

	g_slist_free (top_sources);
	top_sources = NULL;

	if (g_hash_table_size (children)) {
		GHashTableIter iter;
		gpointer value;

		g_hash_table_iter_init (&iter, children);
		while (g_hash_table_iter_next (&iter, NULL, &value)) {
			top_sources = g_slist_concat (top_sources, g_slist_copy (value));
		}

		g_hash_table_remove_all (children);

		dump_children (top_sources, children, 0);

		g_slist_free (top_sources);
	}

	g_hash_table_destroy (children);
}

gint
main (gint argc,
      gchar **argv)
{
	GOptionContext *context;
	ESourceRegistry *registry;
	GList *sources;
	GError *error = NULL;

#ifdef G_OS_WIN32
	e_util_win32_initialize ();
#endif

	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);

	context = g_option_context_new (NULL);
	g_option_context_add_main_entries (context, entries, GETTEXT_PACKAGE);
	if (!g_option_context_parse (context, &argc, &argv, &error)) {
		g_option_context_free (context);
		g_printerr ("%s\n", error ? error->message : _("Failed to parse arguments: Unknown error"));
		g_clear_error (&error);
		return 1;
	}

	g_option_context_free (context);

	registry = e_source_registry_new_sync (NULL, &error);
	if (error || !registry) {
		g_printerr (_("Failed to connect to source registry: %s\n"), error ? error->message : _("Unknown error"));
		g_clear_error (&error);
		return 2;
	}

	if (opt_extension_name && !*opt_extension_name)
		opt_extension_name = NULL;

	if (opt_only_enabled)
		sources = e_source_registry_list_enabled (registry, opt_extension_name);
	else
		sources = e_source_registry_list_sources (registry, opt_extension_name);

	if (sources)
		dump_sources (sources);
	else if (!opt_machine_readable)
		g_print (_("No sources had been found\n"));

	g_list_free_full (sources, g_object_unref);
	g_object_unref (registry);

	return 0;
}
