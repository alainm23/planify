/*
 * Copyright (C) 2011-2013 Jiri Techet <techet@gmail.com>
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

#ifndef CHAMPLAIN_LICENSE_H
#define CHAMPLAIN_LICENSE_H

#include <champlain/champlain-defines.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_LICENSE champlain_license_get_type ()

#define CHAMPLAIN_LICENSE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_LICENSE, ChamplainLicense))

#define CHAMPLAIN_LICENSE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_LICENSE, ChamplainLicenseClass))

#define CHAMPLAIN_IS_LICENSE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_LICENSE))

#define CHAMPLAIN_IS_LICENSE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_LICENSE))

#define CHAMPLAIN_LICENSE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_LICENSE, ChamplainLicenseClass))

typedef struct _ChamplainLicensePrivate ChamplainLicensePrivate;

typedef struct _ChamplainLicense ChamplainLicense;
typedef struct _ChamplainLicenseClass ChamplainLicenseClass;


/**
 * ChamplainLicense:
 *
 * The #ChamplainLicense structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainLicense
{
  ClutterActor parent;

  ChamplainLicensePrivate *priv;
};

struct _ChamplainLicenseClass
{
  ClutterActorClass parent_class;
};

GType champlain_license_get_type (void);

ClutterActor *champlain_license_new (void);

void champlain_license_set_extra_text (ChamplainLicense *license,
    const gchar *text);
const gchar *champlain_license_get_extra_text (ChamplainLicense *license);

void champlain_license_set_alignment (ChamplainLicense *license,
    PangoAlignment alignment);
PangoAlignment champlain_license_get_alignment (ChamplainLicense *license);

void champlain_license_connect_view (ChamplainLicense *license,
    ChamplainView *view);
void champlain_license_disconnect_view (ChamplainLicense *license);

G_END_DECLS

#endif
