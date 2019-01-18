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

#ifndef __CHAMPLAIN_IMAGE_RENDERER_H__
#define __CHAMPLAIN_IMAGE_RENDERER_H__

#include <champlain/champlain-tile.h>
#include <champlain/champlain-renderer.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_IMAGE_RENDERER champlain_image_renderer_get_type ()

#define CHAMPLAIN_IMAGE_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_IMAGE_RENDERER, ChamplainImageRenderer))

#define CHAMPLAIN_IMAGE_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_IMAGE_RENDERER, ChamplainImageRendererClass))

#define CHAMPLAIN_IS_IMAGE_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_IMAGE_RENDERER))

#define CHAMPLAIN_IS_IMAGE_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_IMAGE_RENDERER))

#define CHAMPLAIN_IMAGE_RENDERER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_IMAGE_RENDERER, ChamplainImageRendererClass))

typedef struct _ChamplainImageRendererPrivate ChamplainImageRendererPrivate;

typedef struct _ChamplainImageRenderer ChamplainImageRenderer;
typedef struct _ChamplainImageRendererClass ChamplainImageRendererClass;

/**
 * ChamplainImageRenderer:
 *
 * The #ChamplainImageRenderer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
struct _ChamplainImageRenderer
{
  ChamplainRenderer parent;

  ChamplainImageRendererPrivate *priv;
};

struct _ChamplainImageRendererClass
{
  ChamplainRendererClass parent_class;
};

GType champlain_image_renderer_get_type (void);

ChamplainImageRenderer *champlain_image_renderer_new (void);

G_END_DECLS

#endif /* __CHAMPLAIN_IMAGE_RENDERER_H__ */
