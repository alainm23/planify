/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcelanguage-private.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Paolo Maggi <paolo.maggi@polito.it>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_LANGUAGE_PRIVATE_H
#define GTK_SOURCE_LANGUAGE_PRIVATE_H

#include <glib.h>
#include "gtksourcecontextengine.h"
#include "gtksourcelanguagemanager.h"

G_BEGIN_DECLS

#define GTK_SOURCE_LANGUAGE_VERSION_1_0  100
#define GTK_SOURCE_LANGUAGE_VERSION_2_0  200

typedef struct _GtkSourceStyleInfo GtkSourceStyleInfo;

struct _GtkSourceStyleInfo
{
	gchar *name;
	gchar *map_to;
};

struct _GtkSourceLanguagePrivate
{
	gchar                    *lang_file_name;
	gchar                    *translation_domain;

	gchar                    *id;
	gchar                    *name;
	gchar                    *section;

	/* Maps ids to GtkSourceStyleInfo objects */
	/* Names of styles defined in other lang files are not stored */
	GHashTable               *styles;
	gboolean		  styles_loaded;

	gint                      version;
	gboolean                  hidden;

	GHashTable               *properties;

	GtkSourceLanguageManager *language_manager;

	GtkSourceContextData     *ctx_data;
};

G_GNUC_INTERNAL
GtkSourceLanguage 	 *_gtk_source_language_new_from_file 		(const gchar		   *filename,
									 GtkSourceLanguageManager  *lm);

G_GNUC_INTERNAL
GtkSourceLanguageManager *_gtk_source_language_get_language_manager 	(GtkSourceLanguage        *language);

G_GNUC_INTERNAL
const gchar		 *_gtk_source_language_manager_get_rng_file	(GtkSourceLanguageManager *lm);

G_GNUC_INTERNAL
gchar       		 *_gtk_source_language_translate_string 	(GtkSourceLanguage        *language,
									 const gchar              *string);

G_GNUC_INTERNAL
void 			  _gtk_source_language_define_language_styles	(GtkSourceLanguage        *language);

G_GNUC_INTERNAL
gboolean 		  _gtk_source_language_file_parse_version1 	(GtkSourceLanguage        *language,
									 GtkSourceContextData     *ctx_data);

G_GNUC_INTERNAL
gboolean 		  _gtk_source_language_file_parse_version2	(GtkSourceLanguage        *language,
									 GtkSourceContextData     *ctx_data);

G_GNUC_INTERNAL
GtkSourceEngine 	 *_gtk_source_language_create_engine		(GtkSourceLanguage	  *language);

/* Utility functions for GtkSourceStyleInfo */
G_GNUC_INTERNAL
GtkSourceStyleInfo 	 *_gtk_source_style_info_new 			(const gchar		  *name,
									 const gchar              *map_to);

G_GNUC_INTERNAL
GtkSourceStyleInfo 	 *_gtk_source_style_info_copy			(GtkSourceStyleInfo       *info);

G_GNUC_INTERNAL
void			  _gtk_source_style_info_free			(GtkSourceStyleInfo       *info);

G_END_DECLS

#endif  /* GTK_SOURCE_LANGUAGE_PRIVATE_H */

