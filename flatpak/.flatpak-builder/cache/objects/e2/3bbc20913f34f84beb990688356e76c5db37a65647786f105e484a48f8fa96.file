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

/* defines protocol for lock helper process ipc */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_LOCK_HELPER_H
#define CAMEL_LOCK_HELPER_H

#include <glib.h>

G_BEGIN_DECLS

struct _CamelLockHelperMsg {
	guint32 magic;
	guint32 seq;
	guint32 id;
	guint32 data;
};

/* magic values */
enum {
	CAMEL_LOCK_HELPER_MAGIC = 0xABADF00D,
	CAMEL_LOCK_HELPER_RETURN_MAGIC = 0xDEADBEEF
};

/* return status */
enum {
	CAMEL_LOCK_HELPER_STATUS_OK = 0,
	CAMEL_LOCK_HELPER_STATUS_PROTOCOL,
	CAMEL_LOCK_HELPER_STATUS_NOMEM,
	CAMEL_LOCK_HELPER_STATUS_SYSTEM,
	CAMEL_LOCK_HELPER_STATUS_INVALID /* not allowed to lock/doesn't exist etc */
};

/* commands */
enum {
	CAMEL_LOCK_HELPER_LOCK = 0xf0f,
	CAMEL_LOCK_HELPER_UNLOCK = 0xf0f0
};

/* seconds between lock refreshes */
#define CAMEL_DOT_LOCK_REFRESH (30)

G_END_DECLS

#endif /* CAMEL_LOCK_HELPER_H */
