/*
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

#ifndef _CHAMPLAIN_MEMORY_CACHE_H_
#define _CHAMPLAIN_MEMORY_CACHE_H_

#include <glib-object.h>
#include <champlain/champlain-tile-cache.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MEMORY_CACHE champlain_memory_cache_get_type ()

#define CHAMPLAIN_MEMORY_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MEMORY_CACHE, ChamplainMemoryCache))

#define CHAMPLAIN_MEMORY_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MEMORY_CACHE, ChamplainMemoryCacheClass))

#define CHAMPLAIN_IS_MEMORY_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MEMORY_CACHE))

#define CHAMPLAIN_IS_MEMORY_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MEMORY_CACHE))

#define CHAMPLAIN_MEMORY_CACHE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MEMORY_CACHE, ChamplainMemoryCacheClass))

typedef struct _ChamplainMemoryCachePrivate ChamplainMemoryCachePrivate;

typedef struct _ChamplainMemoryCache ChamplainMemoryCache;
typedef struct _ChamplainMemoryCacheClass ChamplainMemoryCacheClass;

/**
 * ChamplainMemoryCache:
 *
 * The #ChamplainMemoryCache structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
struct _ChamplainMemoryCache
{
  ChamplainTileCache parent_instance;

  ChamplainMemoryCachePrivate *priv;
};

struct _ChamplainMemoryCacheClass
{
  ChamplainTileCacheClass parent_class;
};

GType champlain_memory_cache_get_type (void);

ChamplainMemoryCache *champlain_memory_cache_new_full (guint size_limit,
    ChamplainRenderer *renderer);

guint champlain_memory_cache_get_size_limit (ChamplainMemoryCache *memory_cache);
void champlain_memory_cache_set_size_limit (ChamplainMemoryCache *memory_cache,
    guint size_limit);

void champlain_memory_cache_clean (ChamplainMemoryCache *memory_cache);

G_END_DECLS

#endif /* _CHAMPLAIN_MEMORY_CACHE_H_ */
