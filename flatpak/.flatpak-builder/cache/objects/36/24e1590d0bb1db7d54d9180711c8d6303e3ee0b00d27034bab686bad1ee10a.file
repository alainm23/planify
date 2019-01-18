/*
   Copyright 2011 Bastien Nocera

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

#ifndef GEOCODE_REVERSE_H
#define GEOCODE_REVERSE_H

#include <glib.h>
#include <gio/gio.h>
#include "geocode-place.h"
#include "geocode-backend.h"

G_BEGIN_DECLS

GType geocode_reverse_get_type (void) G_GNUC_CONST;

#define GEOCODE_TYPE_REVERSE                 (geocode_reverse_get_type ())
#define GEOCODE_REVERSE(obj)                 (G_TYPE_CHECK_INSTANCE_CAST ((obj), GEOCODE_TYPE_REVERSE, GeocodeReverse))
#define GEOCODE_IS_REVERSE(obj)              (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GEOCODE_TYPE_REVERSE))
#define GEOCODE_REVERSE_CLASS(klass)         (G_TYPE_CHECK_CLASS_CAST ((klass), GEOCODE_TYPE_REVERSE, GeocodeReverseClass))
#define GEOCODE_IS_REVERSE_CLASS(klass)      (G_TYPE_CHECK_CLASS_TYPE ((klass), GEOCODE_TYPE_REVERSE))
#define GEOCODE_REVERSE_GET_CLASS(obj)       (G_TYPE_INSTANCE_GET_CLASS ((obj), GEOCODE_TYPE_REVERSE, GeocodeReverseClass))

/**
 * GeocodeReverse:
 *
 * All the fields in the #GeocodeReverse structure are private and should never be accessed directly.
**/
typedef struct _GeocodeReverse        GeocodeReverse;
typedef struct _GeocodeReverseClass   GeocodeReverseClass;
typedef struct _GeocodeReversePrivate GeocodeReversePrivate;

struct _GeocodeReverse {
	/* <private> */
	GObject parent_instance;
	GeocodeReversePrivate *priv;
};

/**
 * GeocodeReverseClass:
 *
 * All the fields in the #GeocodeReverseClass structure are private and should never be accessed directly.
**/
struct _GeocodeReverseClass {
	/* <private> */
	GObjectClass parent_class;
};

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodeReverse, g_object_unref)

GeocodeReverse *geocode_reverse_new_for_location (GeocodeLocation *location);

void geocode_reverse_set_backend (GeocodeReverse *object,
                                  GeocodeBackend *backend);

void geocode_reverse_resolve_async (GeocodeReverse      *object,
				    GCancellable        *cancellable,
				    GAsyncReadyCallback  callback,
				    gpointer             user_data);

GeocodePlace *geocode_reverse_resolve_finish (GeocodeReverse  *object,
                                              GAsyncResult   *res,
                                              GError        **error);

GeocodePlace *geocode_reverse_resolve (GeocodeReverse *object,
                                       GError        **error);

G_END_DECLS

#endif /* GEOCODE_REVERSE_H */
