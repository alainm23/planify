/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 8; tab-width: 8 -*- */
/* server-interface-check.h
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Sivaiah Nallagatla <snallagatla@novell.com>
 */

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

#ifndef E_OFFLINE_LISTENER_H
#define E_OFFLINE_LISTENER_H

#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_OFFLINE_LISTENER \
	(e_offline_listener_get_type ())
#define E_OFFLINE_LISTENER(obj) \
	((G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_OFFLINE_LISTENER, EOfflineListener)))
#define E_OFFLINE_LISTENER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_OFFLINE_LISTENER, EOfflineListenerClass))
#define E_IS_OFFLINE_LISTENER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_OFFLINE_LISTENER))
#define E_IS_OFFLINE_LISTENER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_OFFLINE_LISTENER))
#define E_OFFLINE_LISTENER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_OFFLINE_LISTENER, EOfflineListenerClass))

G_BEGIN_DECLS

typedef struct _EOfflineListener EOfflineListener;
typedef struct _EOfflineListenerClass EOfflineListenerClass;
typedef struct _EOfflineListenerPrivate EOfflineListenerPrivate;

/**
 * EOfflineListenerState:
 * @EOL_STATE_OFFLINE:
 *   Evolution is in offline mode.
 * @EOL_STATE_ONLINE:
 *   Evolution is in online mode.
 *
 * Indicates the online/offline state of the listener.
 *
 * Since: 2.30
 **/
typedef enum {
	EOL_STATE_OFFLINE = 0,
	EOL_STATE_ONLINE = 1
} EOfflineListenerState;

/**
 * EOfflineListener:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 2.30
 **/
struct _EOfflineListener {
	/*< private >*/
	GObject parent;
	EOfflineListenerPrivate *priv;
};

struct _EOfflineListenerClass {
	GObjectClass parent_class;

	void (*changed) (EOfflineListener *eol, EOfflineListenerState state);
};

GType		e_offline_listener_get_type	(void);
EOfflineListener *
		e_offline_listener_new		(void);
EOfflineListenerState
		e_offline_listener_get_state	(EOfflineListener *eol);

G_END_DECLS

#endif /* E_OFFLINE_LISTENER_H */

#endif /* EDS_DISABLE_DEPRECATED */

