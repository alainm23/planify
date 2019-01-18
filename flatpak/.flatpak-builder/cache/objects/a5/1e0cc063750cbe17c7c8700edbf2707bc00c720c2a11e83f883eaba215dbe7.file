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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_CANCELLABLE_LOCKS_H
#define E_CANCELLABLE_LOCKS_H

#include <glib.h>
#include <gio/gio.h>

G_BEGIN_DECLS

typedef struct _ECancellableMutex ECancellableMutex;
typedef struct _ECancellableRecMutex ECancellableRecMutex;

void		e_cancellable_mutex_init	(ECancellableMutex *mutex);
void		e_cancellable_mutex_clear	(ECancellableMutex *mutex);
gboolean	e_cancellable_mutex_lock	(ECancellableMutex *mutex,
						 GCancellable *cancellable);
void		e_cancellable_mutex_unlock	(ECancellableMutex *mutex);
GMutex *	e_cancellable_mutex_get_internal_mutex
						(ECancellableMutex *mutex);

void		e_cancellable_rec_mutex_init	(ECancellableRecMutex *rec_mutex);
void		e_cancellable_rec_mutex_clear	(ECancellableRecMutex *rec_mutex);
gboolean	e_cancellable_rec_mutex_lock	(ECancellableRecMutex *rec_mutex,
						 GCancellable *cancellable);
void		e_cancellable_rec_mutex_unlock	(ECancellableRecMutex *rec_mutex);

/* private structures, members should not be accessed
 * otherwise than with above functions */

struct _ECancellableLocksBase {
	GMutex cond_mutex;
	GCond cond;
};

struct _ECancellableMutex {
	struct _ECancellableLocksBase base;
	GMutex mutex;
};

struct _ECancellableRecMutex {
	struct _ECancellableLocksBase base;
	GRecMutex rec_mutex;
};

G_END_DECLS

#endif /* E_CANCELLABLE_LOCKS_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */
