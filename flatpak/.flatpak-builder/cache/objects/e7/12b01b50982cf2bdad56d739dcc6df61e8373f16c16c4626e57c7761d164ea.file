/*
 * e-operation-pool.h
 *
 * Copyright (C) 2011 Novell, Inc. (www.novell.com)
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

#ifndef E_OPERATION_POOL_H
#define E_OPERATION_POOL_H

#include <gio/gio.h>

/**
 * EOperationPool:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
typedef struct _EOperationPool EOperationPool;

EOperationPool *e_operation_pool_new (guint max_threads, GFunc thread_func, gpointer user_data);
void		e_operation_pool_free (EOperationPool *pool);
guint32		e_operation_pool_reserve_opid (EOperationPool *pool);
void		e_operation_pool_release_opid (EOperationPool *pool, guint32 opid);
void		e_operation_pool_push (EOperationPool *pool, gpointer opdata);

#endif /* E_OPERATION_POOL_H */
