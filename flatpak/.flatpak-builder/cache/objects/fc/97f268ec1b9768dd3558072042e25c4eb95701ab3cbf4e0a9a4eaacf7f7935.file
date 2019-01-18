/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-data-cache.h: Class for a Camel filesystem cache
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_DATA_CACHE_H
#define CAMEL_DATA_CACHE_H

#include <camel/camel-stream.h>

/* Standard GObject macros */
#define CAMEL_TYPE_DATA_CACHE \
	(camel_data_cache_get_type ())
#define CAMEL_DATA_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_DATA_CACHE, CamelDataCache))
#define CAMEL_DATA_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_DATA_CACHE, CamelDataCacheClass))
#define CAMEL_IS_DATA_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_DATA_CACHE))
#define CAMEL_IS_DATA_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_DATA_CACHE))
#define CAMEL_DATA_CACHE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_DATA_CACHE, CamelDataCacheClass))

G_BEGIN_DECLS

typedef struct _CamelDataCache CamelDataCache;
typedef struct _CamelDataCacheClass CamelDataCacheClass;
typedef struct _CamelDataCachePrivate CamelDataCachePrivate;

/**
 * CamelDataCacheRemoveFunc:
 * @cdc: a #CamelDataCache
 * @filename: a file name found in the cache
 * @user_data: user data passed to camel_data_cache_foreach_remove()
 *
 * A callback called for each found file in the cache, used
 * by camel_data_cache_foreach_remove(). The @filename corresponds
 * to the result of camel_data_cache_get_filename().
 *
 * Returns: %TRUE, to delete the file, %FALSE to keep in in the cache
 *
 * Since: 3.26
 **/
typedef gboolean (* CamelDataCacheRemoveFunc)	(CamelDataCache *cdc,
						 const gchar *filename,
						 gpointer user_data);

struct _CamelDataCache {
	GObject parent;
	CamelDataCachePrivate *priv;
};

struct _CamelDataCacheClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_data_cache_get_type	(void);
CamelDataCache *camel_data_cache_new		(const gchar *path,
						 GError **error);
const gchar *	camel_data_cache_get_path	(CamelDataCache *cdc);
void		camel_data_cache_set_path	(CamelDataCache *cdc,
						 const gchar *path);
gboolean	camel_data_cache_get_expire_enabled
						(CamelDataCache *cdc);
void		camel_data_cache_set_expire_enabled
						(CamelDataCache *cdc,
						 gboolean expire_enabled);
void		camel_data_cache_set_expire_age	(CamelDataCache *cdc,
						 time_t when);
void		camel_data_cache_set_expire_access
						(CamelDataCache *cdc,
						 time_t when);
GIOStream *	camel_data_cache_add		(CamelDataCache *cdc,
						 const gchar *path,
						 const gchar *key,
						 GError **error);
GIOStream *	camel_data_cache_get		(CamelDataCache *cdc,
						 const gchar *path,
						 const gchar *key,
						 GError **error);
gint		camel_data_cache_remove		(CamelDataCache *cdc,
						 const gchar *path,
						 const gchar *key,
						 GError **error);
gchar *		camel_data_cache_get_filename	(CamelDataCache *cdc,
						 const gchar *path,
						 const gchar *key);
void		camel_data_cache_clear		(CamelDataCache *cdc,
						 const gchar *path);
void		camel_data_cache_foreach_remove	(CamelDataCache *cdc,
						 const gchar *path,
						 CamelDataCacheRemoveFunc func,
						 gpointer user_data);

G_END_DECLS

#endif /* CAMEL_DATA_CACHE_H */
