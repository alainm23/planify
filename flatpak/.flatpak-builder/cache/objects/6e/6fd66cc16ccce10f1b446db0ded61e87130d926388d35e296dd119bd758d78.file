/*
   Copyright 2012 Bastien Nocera

   The Gnome Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The Gnome Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the Gnome Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301  USA.

   Authors: Bastien Nocera <hadess@hadess.net>

 */

#ifndef GEOCODE_FORWARD_H
#define GEOCODE_FORWARD_H

#include <glib.h>
#include <gio/gio.h>
#include <geocode-glib/geocode-glib.h>
#include <geocode-glib/geocode-backend.h>
#include <geocode-glib/geocode-bounding-box.h>

G_BEGIN_DECLS

GType geocode_forward_get_type (void) G_GNUC_CONST;

#define GEOCODE_TYPE_FORWARD                  (geocode_forward_get_type ())
#define GEOCODE_FORWARD(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GEOCODE_TYPE_FORWARD, GeocodeForward))
#define GEOCODE_IS_FORWARD(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GEOCODE_TYPE_FORWARD))
#define GEOCODE_FORWARD_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), GEOCODE_TYPE_FORWARD, GeocodeForwardClass))
#define GEOCODE_IS_FORWARD_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), GEOCODE_TYPE_FORWARD))
#define GEOCODE_FORWARD_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), GEOCODE_TYPE_FORWARD, GeocodeForwardClass))

/**
 * GeocodeForward:
 *
 * All the fields in the #GeocodeForward structure are private and should never be accessed directly.
**/
typedef struct _GeocodeForward        GeocodeForward;
typedef struct _GeocodeForwardClass   GeocodeForwardClass;
typedef struct _GeocodeForwardPrivate GeocodeForwardPrivate;

struct _GeocodeForward {
	/* <private> */
	GObject parent_instance;
	GeocodeForwardPrivate *priv;
};

/**
 * GeocodeForwardClass:
 *
 * All the fields in the #GeocodeForwardClass structure are private and should never be accessed directly.
**/
struct _GeocodeForwardClass {
	/* <private> */
	GObjectClass parent_class;
};

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodeForward, g_object_unref)

GeocodeForward *geocode_forward_new_for_string       (const char *str);
GeocodeForward *geocode_forward_new_for_params       (GHashTable *params);
guint geocode_forward_get_answer_count               (GeocodeForward *forward);
void geocode_forward_set_answer_count                (GeocodeForward *forward,
						      guint           count);
GeocodeBoundingBox * geocode_forward_get_search_area (GeocodeForward     *forward);
void geocode_forward_set_search_area                 (GeocodeForward     *forward,
						      GeocodeBoundingBox *box);
gboolean geocode_forward_get_bounded                 (GeocodeForward *forward);
void geocode_forward_set_bounded                     (GeocodeForward *forward,
						      gboolean        bounded);

void geocode_forward_search_async  (GeocodeForward       *forward,
				    GCancellable        *cancellable,
				    GAsyncReadyCallback  callback,
				    gpointer             user_data);

GList *geocode_forward_search_finish (GeocodeForward  *forward,
				      GAsyncResult    *res,
				      GError         **error);

GList *geocode_forward_search (GeocodeForward  *forward,
			       GError         **error);

void geocode_forward_set_backend (GeocodeForward *forward,
                                  GeocodeBackend *backend);

G_END_DECLS

#endif /* GEOCODE_FORWARD_H */
