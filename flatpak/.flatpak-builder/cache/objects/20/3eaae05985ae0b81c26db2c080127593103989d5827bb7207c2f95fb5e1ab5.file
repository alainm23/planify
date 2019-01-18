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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_LOCK_H
#define CAMEL_LOCK_H

#include <glib.h>

/* for .lock locking, retry, delay and stale counts */
#define CAMEL_LOCK_DOT_RETRY (5) /* number of times to retry lock */
#define CAMEL_LOCK_DOT_DELAY (2) /* delay between locking retries */
#define CAMEL_LOCK_DOT_STALE (60) /* seconds before a lock becomes stale */

/* for locking folders, retry/interretry delay */
#define CAMEL_LOCK_RETRY (5) /* number of times to retry lock */
#define CAMEL_LOCK_DELAY (2) /* delay between locking retries */

G_BEGIN_DECLS

typedef enum {
	CAMEL_LOCK_READ,
	CAMEL_LOCK_WRITE
} CamelLockType;

/* specific locking strategies */
gint camel_lock_dot (const gchar *path, GError **error);
gint camel_lock_fcntl (gint fd, CamelLockType type, GError **error);
gint camel_lock_flock (gint fd, CamelLockType type, GError **error);

void camel_unlock_dot (const gchar *path);
void camel_unlock_fcntl (gint fd);
void camel_unlock_flock (gint fd);

/* lock a folder in a standard way */
gint camel_lock_folder (const gchar *path, gint fd, CamelLockType type, GError **error);
void camel_unlock_folder (const gchar *path, gint fd);

G_END_DECLS

#endif /* CAMEL_LOCK_H */
