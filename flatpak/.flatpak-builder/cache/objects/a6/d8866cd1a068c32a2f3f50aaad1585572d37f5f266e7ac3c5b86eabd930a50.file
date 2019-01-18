/*
A small subclass of the menuitem for using clients.

Copyright 2010 Canonical Ltd.

Authors:
    Ted Gould <ted@canonical.com>

This program is free software: you can redistribute it and/or modify it 
under the terms of either or both of the following licenses:

1) the GNU Lesser General Public License version 3, as published by the 
Free Software Foundation; and/or
2) the GNU Lesser General Public License version 2.1, as published by 
the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR 
PURPOSE.  See the applicable version of the GNU Lesser General Public 
License for more details.

You should have received a copy of both the GNU Lesser General Public 
License version 3 and version 2.1 along with this program.  If not, see 
<http://www.gnu.org/licenses/>
*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "client-menuitem.h"
#include "client-private.h"

typedef struct _DbusmenuClientMenuitemPrivate DbusmenuClientMenuitemPrivate;

struct _DbusmenuClientMenuitemPrivate
{
	DbusmenuClient * client;
};

#define DBUSMENU_CLIENT_MENUITEM_GET_PRIVATE(o) \
(G_TYPE_INSTANCE_GET_PRIVATE ((o), DBUSMENU_TYPE_CLIENT_MENUITEM, DbusmenuClientMenuitemPrivate))

static void dbusmenu_client_menuitem_class_init (DbusmenuClientMenuitemClass *klass);
static void dbusmenu_client_menuitem_init       (DbusmenuClientMenuitem *self);
static void dbusmenu_client_menuitem_dispose    (GObject *object);
static void dbusmenu_client_menuitem_finalize   (GObject *object);
static void handle_event (DbusmenuMenuitem * mi, const gchar * name, GVariant * value, guint timestamp);
static void send_about_to_show (DbusmenuMenuitem * mi, void (*cb) (DbusmenuMenuitem * mi, gpointer user_data), gpointer cb_data);

G_DEFINE_TYPE (DbusmenuClientMenuitem, dbusmenu_client_menuitem, DBUSMENU_TYPE_MENUITEM);

static void
dbusmenu_client_menuitem_class_init (DbusmenuClientMenuitemClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (DbusmenuClientMenuitemPrivate));

	object_class->dispose = dbusmenu_client_menuitem_dispose;
	object_class->finalize = dbusmenu_client_menuitem_finalize;

	DbusmenuMenuitemClass * mclass = DBUSMENU_MENUITEM_CLASS(klass);
	mclass->handle_event = handle_event;
	mclass->send_about_to_show = send_about_to_show;

	return;
}

static void
dbusmenu_client_menuitem_init (DbusmenuClientMenuitem *self)
{

	return;
}

static void
dbusmenu_client_menuitem_dispose (GObject *object)
{

	G_OBJECT_CLASS (dbusmenu_client_menuitem_parent_class)->dispose (object);
	return;
}

static void
dbusmenu_client_menuitem_finalize (GObject *object)
{

	G_OBJECT_CLASS (dbusmenu_client_menuitem_parent_class)->finalize (object);
	return;
}

/* Creates the item and associates the client */
DbusmenuClientMenuitem *
dbusmenu_client_menuitem_new (gint id, DbusmenuClient * client)
{
	DbusmenuClientMenuitem * mi = g_object_new(DBUSMENU_TYPE_CLIENT_MENUITEM, "id", id, NULL);
	DbusmenuClientMenuitemPrivate * priv = DBUSMENU_CLIENT_MENUITEM_GET_PRIVATE(mi);
	priv->client = client;
	return mi;
}

/* Passes the event signal on through the client. */
static void
handle_event (DbusmenuMenuitem * mi, const gchar * name, GVariant * variant, guint timestamp)
{
	DbusmenuClientMenuitemPrivate * priv = DBUSMENU_CLIENT_MENUITEM_GET_PRIVATE(mi);
	dbusmenu_client_send_event(priv->client, dbusmenu_menuitem_get_id(mi), name, variant, timestamp, mi);
	return;
}

typedef struct _about_to_show_t about_to_show_t;
struct _about_to_show_t {
	DbusmenuMenuitem * mi;
	void (*cb) (DbusmenuMenuitem * mi, gpointer user_data);
	gpointer cb_data;
};

/* Handles calling the callback that we were called with */
static void
about_to_show_cb (gpointer user_data)
{
	about_to_show_t * data = (about_to_show_t *)user_data;

	data->cb(data->mi, data->cb_data);

	g_object_unref(data->mi);
	g_free(user_data);
	return;
}

/* Passes the about to show signal on through the client. */
static void
send_about_to_show (DbusmenuMenuitem * mi, void (*cb) (DbusmenuMenuitem * mi, gpointer user_data), gpointer cb_data)
{
	DbusmenuClientMenuitemPrivate * priv = DBUSMENU_CLIENT_MENUITEM_GET_PRIVATE(mi);
	if (cb == NULL) {
		/* Common enough that we don't want to bother
		   with the allocation */
		dbusmenu_client_send_about_to_show(priv->client, dbusmenu_menuitem_get_id(mi), NULL, NULL);
	} else {
		about_to_show_t * data = g_new0(about_to_show_t, 1);
		data->mi = mi;
		data->cb = cb;
		data->cb_data = cb_data;
		g_object_ref(mi);

		dbusmenu_client_send_about_to_show(priv->client, dbusmenu_menuitem_get_id(mi), about_to_show_cb, data);
	}
	return;
}
