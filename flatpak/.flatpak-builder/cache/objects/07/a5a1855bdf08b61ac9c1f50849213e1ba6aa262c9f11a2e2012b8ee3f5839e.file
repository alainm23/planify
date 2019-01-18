/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#ifndef CAMEL_LOCAL_PRIVATE_H
#define CAMEL_LOCAL_PRIVATE_H

/* need a way to configure and save this data, if this header is to
 * be installed.  For now, dont install it */

#include "evolution-data-server-config.h"

#include <glib.h>

G_BEGIN_DECLS

struct _CamelLocalFolderPrivate {
	GMutex search_lock;	/* for locking the search object */
	GRecMutex changes_lock; /* for locking changes member */
};

#define CAMEL_LOCAL_FOLDER_LOCK(f, l) \
	(g_mutex_lock (&((CamelLocalFolder *) f)->priv->l))
#define CAMEL_LOCAL_FOLDER_UNLOCK(f, l) \
	(g_mutex_unlock (&((CamelLocalFolder *) f)->priv->l))

gint		camel_local_frompos_sort	(gpointer enc,
						 gint len1,
						 gpointer data1,
						 gint len2,
						 gpointer data2);

G_END_DECLS

#endif /* CAMEL_LOCAL_PRIVATE_H */

