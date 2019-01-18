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

/**
 * SECTION: e-offline-listener
 * @short_description: Tracks Evolution's online/offline state
 *
 * An #EOfflineListener basically just tracks Evolution's online/offline
 * state and emits a #EOfflineListener:changed signal when a state change
 * is detected.
 *
 * This class is highly Evolution-centric and for that reason has been
 * deprecated.  Use #GNetworkMonitor instead.
 **/

#include "evolution-data-server-config.h"

#include "e-offline-listener.h"

G_DEFINE_TYPE (EOfflineListener, e_offline_listener, G_TYPE_OBJECT)

enum {
	CHANGED,
	NUM_SIGNALS
};

static guint signals[NUM_SIGNALS] = { 0 };

static void
e_offline_listener_class_init (EOfflineListenerClass *class)
{
	GObjectClass *object_class;

	object_class = G_OBJECT_CLASS (class);

	/**
	 * EOfflineListener::changed:
	 * @listener: the #EOfflineListener that received the signal
	 *
	 * Emitted when Evolution's online/offline state changes.
	 **/
	signals[CHANGED] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EOfflineListenerClass, changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_offline_listener_init (EOfflineListener *eol)
{
}

/**
 * e_offline_listener_new:
 *
 * Returns a new #EOfflineListener.
 *
 * Returns: a new #EOfflineListener
 *
 * Since: 2.30
 **/
EOfflineListener *
e_offline_listener_new (void)
{
	return g_object_new (E_TYPE_OFFLINE_LISTENER, NULL);
}

/**
 * e_offline_listener_get_state:
 * @eol: an #EOfflineListener
 *
 * This function now simply returns #EOL_STATE_ONLINE always.
 *
 * Returns: #EOL_STATE_OFFLINE or #EOL_STATE_ONLINE
 *
 * Since: 2.30
 **/
EOfflineListenerState
e_offline_listener_get_state (EOfflineListener *eol)
{
	g_return_val_if_fail (E_IS_OFFLINE_LISTENER (eol), EOL_STATE_OFFLINE);

	return EOL_STATE_ONLINE;
}
