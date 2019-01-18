/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-file-cache.h
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 *
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 */

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_FILE_CACHE_H
#define E_FILE_CACHE_H

#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_FILE_CACHE \
	(e_file_cache_get_type ())
#define E_FILE_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_FILE_CACHE, EFileCache))
#define E_FILE_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_FILE_CACHE, EFileCacheClass))
#define E_IS_FILE_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_FILE_CACHE))
#define E_IS_FILE_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_FILE_CACHE))
#define E_FILE_CACHE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_FILE_CACHE, EFileCacheClass))

G_BEGIN_DECLS

typedef struct _EFileCache EFileCache;
typedef struct _EFileCacheClass EFileCacheClass;
typedef struct _EFileCachePrivate EFileCachePrivate;

/**
 * EFileCache:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 **/
struct _EFileCache {
	/*< private >*/
	GObject parent;
	EFileCachePrivate *priv;
};

struct _EFileCacheClass {
	GObjectClass parent_class;
};

GType		e_file_cache_get_type		(void) G_GNUC_CONST;
EFileCache *	e_file_cache_new		(const gchar *filename);
gboolean	e_file_cache_remove		(EFileCache *cache);
gboolean	e_file_cache_clean		(EFileCache *cache);
const gchar *	e_file_cache_get_object		(EFileCache *cache,
						 const gchar *key);
GSList *	e_file_cache_get_objects	(EFileCache *cache);
GSList *	e_file_cache_get_keys		(EFileCache *cache);
gboolean	e_file_cache_add_object		(EFileCache *cache,
						 const gchar *key,
						 const gchar *value);
gboolean	e_file_cache_replace_object	(EFileCache *cache,
						 const gchar *key,
						 const gchar *new_value);
gboolean	e_file_cache_remove_object	(EFileCache *cache,
						 const gchar *key);
void		e_file_cache_freeze_changes	(EFileCache *cache);
void		e_file_cache_thaw_changes	(EFileCache *cache);
const gchar *	e_file_cache_get_filename	(EFileCache *cache);

G_END_DECLS

#endif
