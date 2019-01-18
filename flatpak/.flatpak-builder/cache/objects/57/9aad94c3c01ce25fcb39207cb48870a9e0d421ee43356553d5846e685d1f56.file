/*
   Copyright 2011 Bastien Nocera

   The Gnome Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The Gnome Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the Gnome Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301  USA.

   Authors: Bastien Nocera <hadess@hadess.net>

 */

#include "config.h"

#include <string.h>
#include <errno.h>
#include <locale.h>
#include <gio/gio.h>
#include <libsoup/soup.h>
#include <langinfo.h>
#include <geocode-glib/geocode-glib-private.h>

/**
 * SECTION:geocode-glib
 * @short_description: Geocode glib main functions
 * @include: geocode-glib/geocode-glib.h
 *
 * Contains functions for geocoding and reverse geocoding using the
 * <ulink url="http://wiki.openstreetmap.org/wiki/Nominatim">OSM Nominatim APIs</ulink>
 **/

SoupSession *
_geocode_glib_build_soup_session (const gchar *user_agent_override)
{
	const char *user_agent;
	g_autofree gchar *user_agent_allocated = NULL;

	if (user_agent_override != NULL) {
		user_agent = user_agent_override;
	} else if (g_application_get_default () != NULL) {
		GApplication *application = g_application_get_default ();
		const char *id = g_application_get_application_id (application);
		user_agent_allocated = g_strdup_printf ("geocode-glib/%s (%s)",
				                        PACKAGE_VERSION, id);
		user_agent = user_agent_allocated;
	} else if (g_get_application_name () != NULL) {
		user_agent_allocated = g_strdup_printf ("geocode-glib/%s (%s)",
		                                        PACKAGE_VERSION,
		                                        g_get_application_name ());
		user_agent = user_agent_allocated;
	} else {
		user_agent_allocated = g_strdup_printf ("geocode-glib/%s",
				                        PACKAGE_VERSION);
		user_agent = user_agent_allocated;
	}

	g_debug ("%s: user_agent = %s", G_STRFUNC, user_agent);

	return soup_session_new_with_options (SOUP_SESSION_USER_AGENT,
	                                      user_agent, NULL);
}

char *
_geocode_glib_cache_path_for_query (SoupMessage *query)
{
	const char *filename;
	char *path;
        SoupURI *soup_uri;
	char *uri;
	GChecksum *sum;

	/* Create cache directory */
	path = g_build_filename (g_get_user_cache_dir (),
				 "geocode-glib",
				 NULL);
	if (g_mkdir_with_parents (path, 0700) < 0) {
		g_warning ("Failed to mkdir path '%s': %s", path, g_strerror (errno));
		g_free (path);
		return NULL;
	}
	g_free (path);

	/* Create path for query */
	soup_uri = soup_message_get_uri (query);
	uri = soup_uri_to_string (soup_uri, FALSE);

	sum = g_checksum_new (G_CHECKSUM_SHA256);
	g_checksum_update (sum, (const guchar *) uri, strlen (uri));

	filename = g_checksum_get_string (sum);

	path = g_build_filename (g_get_user_cache_dir (),
				 "geocode-glib",
				 filename,
				 NULL);

	g_checksum_free (sum);
	g_free (uri);

	return path;
}

gboolean
_geocode_glib_cache_save (SoupMessage *query,
			  const char  *contents)
{
	char *path;
	gboolean ret;

	path = _geocode_glib_cache_path_for_query (query);
	g_debug ("Saving cache file '%s'", path);
	ret = g_file_set_contents (path, contents, -1, NULL);

	g_free (path);
	return ret;
}

gboolean
_geocode_glib_cache_load (SoupMessage *query,
			  char  **contents)
{
	char *path;
	gboolean ret;

	path = _geocode_glib_cache_path_for_query (query);
	g_debug ("Loading cache file '%s'", path);
	ret = g_file_get_contents (path, contents, NULL, NULL);

	g_free (path);
	return ret;
}

static gboolean
parse_lang (const char *locale,
	    char      **language_codep,
	    char      **territory_codep)
{
	GRegex     *re;
	GMatchInfo *match_info;
	gboolean    res;
	GError     *error;
	gboolean    retval;

	match_info = NULL;
	retval = FALSE;

	error = NULL;
	re = g_regex_new ("^(?P<language>[^_.@[:space:]]+)"
			  "(_(?P<territory>[[:upper:]]+))?"
			  "(\\.(?P<codeset>[-_0-9a-zA-Z]+))?"
			  "(@(?P<modifier>[[:ascii:]]+))?$",
			  0, 0, &error);
	if (re == NULL) {
		g_warning ("%s", error->message);
		goto out;
	}

	if (!g_regex_match (re, locale, 0, &match_info) ||
	    g_match_info_is_partial_match (match_info)) {
		g_warning ("locale '%s' isn't valid\n", locale);
		goto out;
	}

	res = g_match_info_matches (match_info);
	if (! res) {
		g_warning ("Unable to parse locale: %s", locale);
		goto out;
	}

	retval = TRUE;

	*language_codep = g_match_info_fetch_named (match_info, "language");

	*territory_codep = g_match_info_fetch_named (match_info, "territory");

	if (*territory_codep != NULL &&
	    *territory_codep[0] == '\0') {
		g_free (*territory_codep);
		*territory_codep = NULL;
	}

out:
	g_match_info_free (match_info);
	g_regex_unref (re);

	return retval;
}

static char *
geocode_object_get_lang_for_locale (const char *locale)
{
	char *lang;
	char *territory;
	char *ret;

	if (parse_lang (locale, &lang, &territory) == FALSE)
		return NULL;

	ret =  g_strdup_printf ("%s%s%s",
				lang,
				territory ? "-" : "",
				territory ? territory : "");

	g_free (lang);
	g_free (territory);

	return ret;
}

char *
_geocode_object_get_lang (void)
{
	return geocode_object_get_lang_for_locale (setlocale (LC_MESSAGES, NULL));
}

#if defined(__GLIBC__) && !defined(__UCLIBC__)
static gpointer
is_number_after_street (gpointer data)
{
	gboolean retval;
	gchar *addr_format;
	gchar *s;
	gchar *h;

	addr_format = nl_langinfo (_NL_ADDRESS_POSTAL_FMT);
	if (addr_format == NULL) {
		retval = FALSE;
		goto out;
	}

	/* %s denotes street or block and %h denotes house number.
	 * See: http://lh.2xlibre.net/values/postal_fmt */
	s = g_strstr_len (addr_format, -1, "%s");
	h = g_strstr_len (addr_format, -1, "%h");

	if (s != NULL && h != NULL)
		retval = (h > s);
	else
		retval = FALSE;

 out:
	return GINT_TO_POINTER (retval);
}
#endif

gboolean
_geocode_object_is_number_after_street (void)
{
#if !defined(__GLIBC__) || defined(__UCLIBC__)
	return FALSE;
#else
	static GOnce once = G_ONCE_INIT;

	g_once (&once, is_number_after_street, NULL);
	return GPOINTER_TO_INT (once.retval);
#endif
}
