/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_REGISTRY_WATCHER_H
#define E_SOURCE_REGISTRY_WATCHER_H

#include <libedataserver/e-source-registry.h>
#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_REGISTRY_WATCHER \
	(e_source_registry_watcher_get_type ())
#define E_SOURCE_REGISTRY_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_REGISTRY_WATCHER, ESourceRegistryWatcher))
#define E_SOURCE_REGISTRY_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_REGISTRY_WATCHER, ESourceRegistryWatcherClass))
#define E_IS_SOURCE_REGISTRY_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_REGISTRY_WATCHER))
#define E_IS_SOURCE_REGISTRY_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_REGISTRY_WATCHER))
#define E_SOURCE_REGISTRY_WATCHER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_REGISTRY_WATCHER, ESourceRegistryWatcherClass))

G_BEGIN_DECLS

typedef struct _ESourceRegistryWatcher ESourceRegistryWatcher;
typedef struct _ESourceRegistryWatcherClass ESourceRegistryWatcherClass;
typedef struct _ESourceRegistryWatcherPrivate ESourceRegistryWatcherPrivate;

/**
 * ESourceRegistryWatcher:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 **/
struct _ESourceRegistryWatcher {
	/*< private >*/
	GObject parent;
	ESourceRegistryWatcherPrivate *priv;
};

struct _ESourceRegistryWatcherClass {
	GObjectClass parent_class;

	/* Signals */
	gboolean	(* filter)	(ESourceRegistryWatcher *watcher,
					 ESource *source);
	void		(* appeared)	(ESourceRegistryWatcher *watcher,
					 ESource *source);
	void		(* disappeared)	(ESourceRegistryWatcher *watcher,
					 ESource *source);
};

GType		e_source_registry_watcher_get_type	(void) G_GNUC_CONST;
ESourceRegistryWatcher *
		e_source_registry_watcher_new		(ESourceRegistry *registry,
							 const gchar *extension_name);
ESourceRegistry *
		e_source_registry_watcher_get_registry	(ESourceRegistryWatcher *watcher);
const gchar *	e_source_registry_watcher_get_extension_name
							(ESourceRegistryWatcher *watcher);
void		e_source_registry_watcher_reclaim	(ESourceRegistryWatcher *watcher);

G_END_DECLS

#endif /* E_SOURCE_REGISTRY_WATCHER_H */
