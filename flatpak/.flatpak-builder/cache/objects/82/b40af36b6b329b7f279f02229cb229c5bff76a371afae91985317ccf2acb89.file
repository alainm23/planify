/*
 * Copyright (C) 2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 * Copyright (C) 2010-2013 Jiri Techet <techet@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef _CHAMPLAIN_FILE_CACHE_H_
#define _CHAMPLAIN_FILE_CACHE_H_

#include <glib-object.h>
#include <champlain/champlain-tile-cache.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_FILE_CACHE champlain_file_cache_get_type ()

#define CHAMPLAIN_FILE_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_FILE_CACHE, ChamplainFileCache))

#define CHAMPLAIN_FILE_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_FILE_CACHE, ChamplainFileCacheClass))

#define CHAMPLAIN_IS_FILE_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_FILE_CACHE))

#define CHAMPLAIN_IS_FILE_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_FILE_CACHE))

#define CHAMPLAIN_FILE_CACHE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_FILE_CACHE, ChamplainFileCacheClass))

typedef struct _ChamplainFileCachePrivate ChamplainFileCachePrivate;

typedef struct _ChamplainFileCache ChamplainFileCache;
typedef struct _ChamplainFileCacheClass ChamplainFileCacheClass;

/**
 * ChamplainFileCache:
 *
 * The #ChamplainFileCache structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.6
 */
struct _ChamplainFileCache
{
  ChamplainTileCache parent_instance;

  ChamplainFileCachePrivate *priv;
};

struct _ChamplainFileCacheClass
{
  ChamplainTileCacheClass parent_class;
};

GType champlain_file_cache_get_type (void);

ChamplainFileCache *champlain_file_cache_new_full (guint size_limit,
    const gchar *cache_dir,
    ChamplainRenderer *renderer);

guint champlain_file_cache_get_size_limit (ChamplainFileCache *file_cache);
void champlain_file_cache_set_size_limit (ChamplainFileCache *file_cache,
    guint size_limit);

const gchar *champlain_file_cache_get_cache_dir (ChamplainFileCache *file_cache);

void champlain_file_cache_purge (ChamplainFileCache *file_cache);
void champlain_file_cache_purge_on_idle (ChamplainFileCache *file_cache);

G_END_DECLS

#endif /* _CHAMPLAIN_FILE_CACHE_H_ */
