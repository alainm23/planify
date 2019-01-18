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

#ifndef _CHAMPLAIN_MAP_SOURCE_CHAIN_H_
#define _CHAMPLAIN_MAP_SOURCE_CHAIN_H_

#include <glib-object.h>

#include "champlain-map-source.h"

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN champlain_map_source_chain_get_type ()

#define CHAMPLAIN_MAP_SOURCE_CHAIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN, ChamplainMapSourceChain))

#define CHAMPLAIN_MAP_SOURCE_CHAIN_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN, ChamplainMapSourceChainClass))

#define CHAMPLAIN_IS_MAP_SOURCE_CHAIN(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN))

#define CHAMPLAIN_IS_MAP_SOURCE_CHAIN_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN))

#define CHAMPLAIN_MAP_SOURCE_CHAIN_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN, ChamplainMapSourceChainClass))

typedef struct _ChamplainMapSourceChainPrivate ChamplainMapSourceChainPrivate;

typedef struct _ChamplainMapSourceChain ChamplainMapSourceChain;
typedef struct _ChamplainMapSourceChainClass ChamplainMapSourceChainClass;

/**
 * ChamplainMapSourceChain:
 *
 * The #ChamplainMapSourceChain structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.6
 */
struct _ChamplainMapSourceChain
{
  ChamplainMapSource parent_instance;

  ChamplainMapSourceChainPrivate *priv;
};

struct _ChamplainMapSourceChainClass
{
  ChamplainMapSourceClass parent_class;
};

GType champlain_map_source_chain_get_type (void);

ChamplainMapSourceChain *champlain_map_source_chain_new (void);

void champlain_map_source_chain_push (ChamplainMapSourceChain *source_chain,
    ChamplainMapSource *map_source);
void champlain_map_source_chain_pop (ChamplainMapSourceChain *source_chain);

G_END_DECLS

#endif /* _CHAMPLAIN_MAP_SOURCE_CHAIN_H_ */
