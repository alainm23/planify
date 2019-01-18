/* champlain-kinetic-scroll-view.h: Finger scrolling container actor
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

#ifndef __CHAMPLAIN_KINETIC_SCROLL_VIEW_H__
#define __CHAMPLAIN_KINETIC_SCROLL_VIEW_H__

#include <glib-object.h>
#include <clutter/clutter.h>
#include <champlain/champlain-viewport.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW champlain_kinetic_scroll_view_get_type ()

#define CHAMPLAIN_KINETIC_SCROLL_VIEW(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW, ChamplainKineticScrollView))

#define CHAMPLAIN_IS_KINETIC_SCROLL_VIEW(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW))

#define CHAMPLAIN_KINETIC_SCROLL_VIEW_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW, ChamplainKineticScrollViewClass))

#define CHAMPLAIN_IS_KINETIC_SCROLL_VIEW_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW))

#define CHAMPLAIN_KINETIC_SCROLL_VIEW_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW, ChamplainKineticScrollViewClass))

typedef struct _ChamplainKineticScrollView ChamplainKineticScrollView;
typedef struct _ChamplainKineticScrollViewPrivate ChamplainKineticScrollViewPrivate;
typedef struct _ChamplainKineticScrollViewClass ChamplainKineticScrollViewClass;

struct _ChamplainKineticScrollView
{
  /*< private >*/
  ClutterActor parent_instance;

  ChamplainKineticScrollViewPrivate *priv;
};

struct _ChamplainKineticScrollViewClass
{
  ClutterActorClass parent_class;
};

GType champlain_kinetic_scroll_view_get_type (void) G_GNUC_CONST;

ClutterActor *champlain_kinetic_scroll_view_new (gboolean kinetic,
    ChamplainViewport *viewport);

void champlain_kinetic_scroll_view_stop (ChamplainKineticScrollView *self);

G_END_DECLS

#endif /* __CHAMPLAIN_KINETIC_SCROLL_VIEW_H__ */
