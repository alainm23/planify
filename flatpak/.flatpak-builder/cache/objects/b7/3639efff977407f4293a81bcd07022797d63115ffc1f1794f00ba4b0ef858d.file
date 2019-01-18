/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "as-stemmer.h"

#include <config.h>
#include <glib.h>
#include <string.h>
#ifdef HAVE_STEMMING
#include <libstemmer.h>
#endif

#include "as-utils.h"
#include "as-utils-private.h"

/**
 * SECTION:as-stemmer
 * @short_description: Stemming helper singleton for AppStream searches.
 */

struct _AsStemmer
{
	GObject parent_instance;

	struct sb_stemmer *sb;
	GMutex mutex;
};

G_DEFINE_TYPE (AsStemmer, as_stemmer, G_TYPE_OBJECT)

static gpointer as_stemmer_object = NULL;

/**
 * as_stemmer_finalize:
 **/
static void
as_stemmer_finalize (GObject *object)
{
#ifdef HAVE_STEMMING
	AsStemmer *stemmer = AS_STEMMER (object);

	sb_stemmer_delete (stemmer->sb);
	g_mutex_clear (&stemmer->mutex);
#endif

	G_OBJECT_CLASS (as_stemmer_parent_class)->finalize (object);
}

/**
 * as_stemmer_init:
 **/
static void
as_stemmer_init (AsStemmer *stemmer)
{
#ifdef HAVE_STEMMING
	g_autofree gchar *locale = NULL;
	g_autofree gchar *lang = NULL;

	g_mutex_init (&stemmer->mutex);

	locale = as_get_current_locale ();
	lang = as_utils_locale_to_language (locale);

	as_stemmer_reload (stemmer, lang);
#endif
}

/**
 * as_stemmer_reload:
 * @stemmer: A #AsStemmer
 * @lang: The stemming language.
 *
 * Allows realoading the #AsStemmer with a different language.
 */
void
as_stemmer_reload (AsStemmer *stemmer, const gchar *lang)
{
#ifdef HAVE_STEMMING
	GMutexLocker *locker = g_mutex_locker_new (&stemmer->mutex);

	sb_stemmer_delete (stemmer->sb);
	stemmer->sb = sb_stemmer_new (lang, NULL);
	if (stemmer->sb == NULL)
		g_debug ("Language %s can not be stemmed.", lang);
	else
		g_debug ("Stemming language is: %s", lang);

	g_mutex_locker_free (locker);
#endif
}

/**
 * as_stemmer_stem:
 * @stemmer: A #AsStemmer
 * @term: The input term to stem.
 *
 * Stems a string using Snowball.
 *
 * Returns: A stemmed string.
 **/
gchar*
as_stemmer_stem (AsStemmer *stemmer, const gchar *term)
{
#ifdef HAVE_STEMMING
	gchar *result;
	GMutexLocker *locker = g_mutex_locker_new (&stemmer->mutex);
	if (stemmer->sb == NULL) {
		g_mutex_locker_free (locker);
		return g_strdup (term);
	}

	result = g_strdup ((gchar*) sb_stemmer_stem (stemmer->sb,
						     (unsigned char*) term,
						     strlen (term)));

	g_mutex_locker_free (locker);
	return result;
#else
	return g_strdup (term);
#endif
}

/**
 * as_stemmer_class_init:
 **/
static void
as_stemmer_class_init (AsStemmerClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_stemmer_finalize;
}

/**
 * as_stemmer_get:
 *
 * Gets the global #AsStemmer instance.
 *
 * Returns: (transfer none): an #AsStemmer
 **/
AsStemmer*
as_stemmer_get (void)
{
	if (as_stemmer_object == NULL) {
		as_stemmer_object = g_object_new (AS_TYPE_STEMMER, NULL);
		g_object_add_weak_pointer (as_stemmer_object, &as_stemmer_object);
	}

	return AS_STEMMER (as_stemmer_object);
}
