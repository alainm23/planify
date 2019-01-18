/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include "evolution-data-server-config.h"

#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gio.h>
#include <stdio.h>

static gchar *state_filename = NULL;
static gchar *photo_filename = NULL;
static gchar *keyid = NULL;
static gchar *img_type = NULL;

static GOptionEntry entries[] = {
	{ "state", 's', 0, G_OPTION_ARG_STRING, &state_filename,
	  "State file, where to write info about the photo.", NULL },
	{ "photo", 'p', 0, G_OPTION_ARG_STRING, &photo_filename,
	  "Photo file name.", NULL },
	{ "keyid", 'k', 0, G_OPTION_ARG_STRING, &keyid,
	  "Key ID for the photo.", NULL },
	{ "type", 't', 0, G_OPTION_ARG_STRING, &img_type,
	  "Extension of the image type (e.g. \"jpg\").", NULL },
	{ NULL }
};

gint
main (gint argc, gchar *argv[])
{
	GOptionContext *context;
	GError *error = NULL;
	gint res = 0;

	context = g_option_context_new ("Camel GPG Photo Saver");
	g_option_context_add_main_entries (context, entries, NULL);
	if (!g_option_context_parse (context, &argc, &argv, &error)) {
		g_option_context_free (context);
		g_warning ("Failed to parse options: %s", error ? error->message : "Unknown error");
		g_clear_error (&error);

		return 1;
	}

	if (!state_filename || !*state_filename || !photo_filename || !*photo_filename || !keyid || !*keyid || !img_type || !*img_type) {
		g_warning ("Expects all four parameters");
		g_option_context_free (context);

		return 2;
	}

	if (g_file_test (photo_filename, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_REGULAR)) {
		GFile *source, *destination;
		gchar *tmp_filename = NULL;
		gchar *tmp_template;
		gint tmp_file;

		tmp_template = g_strconcat ("camel-gpg-photo-XXXXXX.", img_type, NULL);
		tmp_file = g_file_open_tmp (tmp_template, &tmp_filename, &error);
		g_free (tmp_template);

		if (tmp_file == -1) {
			g_warning ("Failed to open temporary file: %s", error ? error->message : "Unknown error");
			g_option_context_free (context);
			g_clear_error (&error);

			return 3;
		}

		close (tmp_file);

		source = g_file_new_for_path (photo_filename);
		destination = g_file_new_for_path (tmp_filename);

		if (!g_file_copy (source, destination, G_FILE_COPY_OVERWRITE, NULL, NULL, NULL, &error)) {
			g_warning ("Failed to copy file '%s' to '%s': %s", photo_filename, tmp_filename, error ? error->message : "Unknown error");
			res = 4;
		} else {
			FILE *state = fopen (state_filename, "ab");
			if (state) {
				fprintf (state, "%s\t%s\n", keyid, tmp_filename);
				fclose (state);
			} else {
				g_unlink (tmp_filename);

				g_warning ("Failed to open state file '%s' for append", state_filename);
				res = 5;
			}
		}

		g_free (tmp_filename);
		g_clear_object (&source);
		g_clear_object (&destination);
		g_clear_error (&error);
	} else {
		g_warning ("Photo file '%s' does not exist", photo_filename);
		res = 6;
	}

	g_option_context_free (context);

	return res;
}
