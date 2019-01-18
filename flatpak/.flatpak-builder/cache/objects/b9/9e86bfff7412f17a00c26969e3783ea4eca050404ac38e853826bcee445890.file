/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_UTILS_PRIVATE_H
#define __AS_UTILS_PRIVATE_H

#include <glib-object.h>
#include "as-settings-private.h"
#include "as-component.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

gchar			*as_get_current_locale (void);

gboolean		as_str_empty (const gchar* str);
GDateTime		*as_iso8601_to_datetime (const gchar *iso_date);

gboolean		as_utils_delete_dir_recursive (const gchar* dirname);

AS_INTERNAL_VISIBLE
GPtrArray		*as_utils_find_files_matching (const gchar *dir,
							const gchar *pattern,
							gboolean recursive,
							GError **error);
AS_INTERNAL_VISIBLE
GPtrArray		*as_utils_find_files (const gchar *dir,
						gboolean recursive,
						GError **error);

gboolean		as_utils_is_root (void);

AS_INTERNAL_VISIBLE
gboolean		as_utils_is_writable (const gchar *path);

guint			as_gstring_replace (GString *string,
					    const gchar *search,
					    const gchar *replace);
gchar			*as_str_replace (const gchar *str,
					 const gchar *old_str,
					 const gchar *new_str);

gchar			**as_ptr_array_to_strv (GPtrArray *array);
const gchar		*as_ptr_array_find_string (GPtrArray *array,
						   const gchar *value);
void			as_hash_table_string_keys_to_array (GHashTable *table,
							    GPtrArray *array);

gboolean		as_touch_location (const gchar *fname);
void			as_reset_umask (void);

AS_INTERNAL_VISIBLE
gboolean		as_copy_file (const gchar *source, const gchar *destination, GError **error);

gboolean		as_is_cruft_locale (const gchar *locale);
gchar			*as_locale_strip_encoding (gchar *locale);
gchar			*as_utils_locale_to_language (const gchar *locale);

gchar			*as_get_current_arch (void);
gboolean		as_arch_compatible (const gchar *arch1,
					    const gchar *arch2);

gboolean		as_utils_search_token_valid (const gchar *token);

gchar			*as_utils_build_data_id (AsComponentScope scope,
						 const gchar *origin,
						 AsBundleKind bundle_kind,
						 const gchar *cid);
gchar			*as_utils_data_id_get_cid (const gchar *data_id);
AsBundleKind		as_utils_get_component_bundle_kind (AsComponent *cpt);
gchar			*as_utils_build_data_id_for_cpt (AsComponent *cpt);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_UTILS_PRIVATE_H */
