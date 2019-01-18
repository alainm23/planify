/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_SYSTEM_LOCALE_WATCHER_H
#define E_SYSTEM_LOCALE_WATCHER_H

#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_SYSTEM_LOCALE_WATCHER \
	(e_system_locale_watcher_get_type ())
#define E_SYSTEM_LOCALE_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SYSTEM_LOCALE_WATCHER, ESystemLocaleWatcher))
#define E_SYSTEM_LOCALE_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SYSTEM_LOCALE_WATCHER, ESystemLocaleWatcherClass))
#define E_IS_SYSTEM_LOCALE_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SYSTEM_LOCALE_WATCHER))
#define E_IS_SYSTEM_LOCALE_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SYSTEM_LOCALE_WATCHER))
#define E_SYSTEM_LOCALE_WATCHER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SYSTEM_LOCALE_WATCHER, ESystemLocaleWatcherClass))

G_BEGIN_DECLS

typedef struct _ESystemLocaleWatcher ESystemLocaleWatcher;
typedef struct _ESystemLocaleWatcherClass ESystemLocaleWatcherClass;
typedef struct _ESystemLocaleWatcherPrivate ESystemLocaleWatcherPrivate;

/**
 * ESystemLocaleWatcher:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 **/
struct _ESystemLocaleWatcher {
	/*< private >*/
	GObject parent;
	ESystemLocaleWatcherPrivate *priv;
};

struct _ESystemLocaleWatcherClass {
	GObjectClass parent_class;
};

GType		e_system_locale_watcher_get_type	(void) G_GNUC_CONST;
ESystemLocaleWatcher *
		e_system_locale_watcher_new		(void);
gchar *		e_system_locale_watcher_dup_locale	(ESystemLocaleWatcher *watcher);

G_END_DECLS

#endif /* E_SYSTEM_LOCALE_WATCHER_H */
