/* champlain-viewport.h: Viewport actor
 *
 * Copyright (C) 2008 OpenedHand
 * Copyright (C) 2011-2013 Jiri Techet <techet@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Written by: Chris Lord <chris@openedhand.com>
 */

#ifndef __CHAMPLAIN_VIEWPORT_H__
#define __CHAMPLAIN_VIEWPORT_H__

#include <glib-object.h>
#include <clutter/clutter.h>
#include "champlain-adjustment.h"

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_VIEWPORT champlain_viewport_get_type ()
  
#define CHAMPLAIN_VIEWPORT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_VIEWPORT, ChamplainViewport))
  
#define CHAMPLAIN_IS_VIEWPORT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_VIEWPORT))
  
#define CHAMPLAIN_VIEWPORT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_VIEWPORT, ChamplainViewportClass))
  
#define CHAMPLAIN_IS_VIEWPORT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_VIEWPORT))
  
#define CHAMPLAIN_VIEWPORT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_VIEWPORT, ChamplainViewportClass))

typedef struct _ChamplainViewport ChamplainViewport;
typedef struct _ChamplainViewportPrivate ChamplainViewportPrivate;
typedef struct _ChamplainViewportClass ChamplainViewportClass;

struct _ChamplainViewport
{
  ClutterActor parent;

  ChamplainViewportPrivate *priv;
};

struct _ChamplainViewportClass
{
  ClutterActorClass parent_class;
};

GType champlain_viewport_get_type (void) G_GNUC_CONST;

ClutterActor *champlain_viewport_new (void);

void champlain_viewport_set_origin (ChamplainViewport *viewport,
    gdouble x,
    gdouble y);

void champlain_viewport_get_origin (ChamplainViewport *viewport,
    gdouble *x,
    gdouble *y);
void champlain_viewport_stop (ChamplainViewport *viewport);

void champlain_viewport_get_adjustments (ChamplainViewport *viewport,
    ChamplainAdjustment **hadjustment,
    ChamplainAdjustment **vadjustment);

void champlain_viewport_set_adjustments (ChamplainViewport *viewport,
    ChamplainAdjustment *hadjustment,
    ChamplainAdjustment *vadjustment);

void champlain_viewport_set_child (ChamplainViewport *viewport,
    ClutterActor *child);

void champlain_viewport_get_anchor (ChamplainViewport *viewport,
    gint *x,
    gint *y);

void champlain_viewport_set_actor_position (ChamplainViewport *viewport,
    ClutterActor *actor,
    gdouble x,
    gdouble y);

G_END_DECLS

#endif /* __CHAMPLAIN_VIEWPORT_H__ */
