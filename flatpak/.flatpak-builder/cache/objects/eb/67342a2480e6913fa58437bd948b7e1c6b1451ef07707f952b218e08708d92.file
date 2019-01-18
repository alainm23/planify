/* champlain-adjustment.h: Adjustment object
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
 * Written by: Chris Lord <chris@openedhand.com>, inspired by GtkAdjustment
 */

#ifndef __CHAMPLAIN_ADJUSTMENT_H__
#define __CHAMPLAIN_ADJUSTMENT_H__

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_ADJUSTMENT champlain_adjustment_get_type ()

#define CHAMPLAIN_ADJUSTMENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_ADJUSTMENT, ChamplainAdjustment))
  
#define CHAMPLAIN_IS_ADJUSTMENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_ADJUSTMENT))
  
#define CHAMPLAIN_ADJUSTMENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_ADJUSTMENT, ChamplainAdjustmentClass))
  
#define CHAMPLAIN_IS_ADJUSTMENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_ADJUSTMENT))
  
#define CHAMPLAIN_ADJUSTMENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_ADJUSTMENT, ChamplainAdjustmentClass))

typedef struct _ChamplainAdjustment ChamplainAdjustment;
typedef struct _ChamplainAdjustmentPrivate ChamplainAdjustmentPrivate;
typedef struct _ChamplainAdjustmentClass ChamplainAdjustmentClass;

/**
 * ChamplainAdjustment:
 *
 * Class for handling an interval between to values. The contents of
 * the #ChamplainAdjustment are private and should be accessed using the
 * public API.
 */
struct _ChamplainAdjustment
{
  /*< private >*/
  GObject parent_instance;

  ChamplainAdjustmentPrivate *priv;
};

/**
 * ChamplainAdjustmentClass:
 * @changed: Class handler for the ::changed signal.
 *
 * Base class for #ChamplainAdjustment.
 */
struct _ChamplainAdjustmentClass
{
  /*< private >*/
  GObjectClass parent_class;

  /*< public >*/
  void (*changed)(ChamplainAdjustment *adjustment);
};

GType champlain_adjustment_get_type (void) G_GNUC_CONST;

ChamplainAdjustment *champlain_adjustment_new (gdouble value,
    gdouble lower,
    gdouble upper,
    gdouble step_increment);
gdouble champlain_adjustment_get_value (ChamplainAdjustment *adjustment);
void champlain_adjustment_set_value (ChamplainAdjustment *adjustment,
    gdouble value);
void champlain_adjustment_set_values (ChamplainAdjustment *adjustment,
    gdouble value,
    gdouble lower,
    gdouble upper,
    gdouble step_increment);
void champlain_adjustment_get_values (ChamplainAdjustment *adjustment,
    gdouble *value,
    gdouble *lower,
    gdouble *upper,
    gdouble *step_increment);

void champlain_adjustment_interpolate (ChamplainAdjustment *adjustment,
    gdouble value,
    guint n_frames,
    guint fps);

gboolean champlain_adjustment_clamp (ChamplainAdjustment *adjustment,
    gboolean interpolate,
    guint n_frames,
    guint fps);
void champlain_adjustment_interpolate_stop (ChamplainAdjustment *adjustment);

G_END_DECLS

#endif /* __CHAMPLAIN_ADJUSTMENT_H__ */
