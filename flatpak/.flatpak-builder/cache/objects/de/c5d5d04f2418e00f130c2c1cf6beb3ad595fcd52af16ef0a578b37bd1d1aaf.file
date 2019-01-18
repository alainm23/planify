/*
   Copyright 2010 Bastien Nocera

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

#ifndef GEOCODE_GLIB_PRIVATE_H
#define GEOCODE_GLIB_PRIVATE_H

#include <glib.h>
#include <libsoup/soup.h>
#include <json-glib/json-glib.h>
#include <geocode-glib/geocode-location.h>
#include <geocode-glib/geocode-place.h>

G_BEGIN_DECLS

#define DEFAULT_ANSWER_COUNT 10

typedef enum {
	GEOCODE_GLIB_RESOLVE_FORWARD,
	GEOCODE_GLIB_RESOLVE_REVERSE
} GeocodeLookupType;

GList      *_geocode_parse_search_json  (const char *contents,
					 GError    **error);

char       *_geocode_object_get_lang (void);

char *_geocode_glib_cache_path_for_query (SoupMessage *query);
gboolean _geocode_glib_cache_save (SoupMessage *query,
                                   const char  *contents);
gboolean _geocode_glib_cache_load (SoupMessage *query,
                                   char       **contents);
GHashTable *_geocode_glib_dup_hash_table (GHashTable *ht);
gboolean _geocode_object_is_number_after_street (void);
SoupSession *_geocode_glib_build_soup_session (const gchar *user_agent_override);

G_END_DECLS

#endif /* GEOCODE_GLIB_PRIVATE_H */
