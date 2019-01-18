/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-uid-cache.h: UID caching code
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_UID_CACHE_H
#define CAMEL_UID_CACHE_H

#include <glib.h>

#include <stdio.h>
#include <sys/types.h>

G_BEGIN_DECLS

typedef struct {
	gchar *filename;
	GHashTable *uids;
	guint level;
	gsize expired;
	gsize size;
	gint fd;
} CamelUIDCache;

CamelUIDCache *camel_uid_cache_new (const gchar *filename);
gboolean camel_uid_cache_save (CamelUIDCache *cache);
void camel_uid_cache_destroy (CamelUIDCache *cache);

GPtrArray *camel_uid_cache_get_new_uids (CamelUIDCache *cache, GPtrArray *uids);

void camel_uid_cache_save_uid (CamelUIDCache *cache, const gchar *uid);
void camel_uid_cache_free_uids (GPtrArray *uids);

G_END_DECLS

#endif /* CAMEL_UID_CACHE_H */
