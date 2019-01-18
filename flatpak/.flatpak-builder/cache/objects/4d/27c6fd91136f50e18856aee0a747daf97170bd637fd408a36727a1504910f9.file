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

#ifndef __CHAMPLAIN_RENDERER_H__
#define __CHAMPLAIN_RENDERER_H__

#include <champlain/champlain-tile.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_RENDERER champlain_renderer_get_type ()

#define CHAMPLAIN_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_RENDERER, ChamplainRenderer))

#define CHAMPLAIN_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_RENDERER, ChamplainRendererClass))

#define CHAMPLAIN_IS_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_RENDERER))

#define CHAMPLAIN_IS_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_RENDERER))

#define CHAMPLAIN_RENDERER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_RENDERER, ChamplainRendererClass))

typedef struct _ChamplainRenderer ChamplainRenderer;
typedef struct _ChamplainRendererClass ChamplainRendererClass;


/**
 * ChamplainRenderer:
 *
 * The #ChamplainRenderer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
struct _ChamplainRenderer
{
  GInitiallyUnowned parent;
};

struct _ChamplainRendererClass
{
  GInitiallyUnownedClass parent_class;

  void (*set_data)(ChamplainRenderer *renderer,
      const gchar *data,
      guint size);
  void (*render)(ChamplainRenderer *renderer,
      ChamplainTile *tile);
};

GType champlain_renderer_get_type (void);

void champlain_renderer_set_data (ChamplainRenderer *renderer,
    const gchar *data,
    guint size);
void champlain_renderer_render (ChamplainRenderer *renderer,
    ChamplainTile *tile);

G_END_DECLS

#endif /* __CHAMPLAIN_RENDERER_H__ */
