/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*  camel-nntp-private.h: Private info for nntp.
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#ifndef CAMEL_NNTP_PRIVATE_H
#define CAMEL_NNTP_PRIVATE_H

/* need a way to configure and save this data, if this header is to
 * be installed.  For now, dont install it */

#include "evolution-data-server-config.h"

G_BEGIN_DECLS

struct _CamelNNTPFolderPrivate {
	GMutex search_lock;	/* for locking the search object */
	GMutex cache_lock;     /* for locking the cache object */

	gboolean apply_filters;		/* persistent property */
};

#define CAMEL_NNTP_FOLDER_LOCK(f, l) \
	(g_mutex_lock (&((CamelNNTPFolder *) f)->priv->l))
#define CAMEL_NNTP_FOLDER_UNLOCK(f, l) \
	(g_mutex_unlock (&((CamelNNTPFolder *) f)->priv->l))

G_END_DECLS

#endif /* CAMEL_NNTP_PRIVATE_H */
