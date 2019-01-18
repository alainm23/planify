/*
 * e-operation-pool.c
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

#include "e-operation-pool.h"

struct _EOperationPool {
	GThreadPool *pool;

	GMutex ops_lock;
	GHashTable *ops;
	guint32 last_opid;
};

/**
 * e_operation_pool_new: (skip)
 * @max_threads: Maximum number of threads for this pool
 * @thread_func: Function to run for a given thread
 * @user_data: The user data to pass to @thread_func
 *
 * Returns: (transfer full): a new #EOperationPool with the given settings.
 *   Free it with e_operation_pool_free(), when no longer needed.
 *
 * Since: 3.2
 **/
EOperationPool *
e_operation_pool_new (guint max_threads,
                      GFunc thread_func,
                      gpointer user_data)
{
	EOperationPool *pool;
	GThreadPool *thread_pool;
	GError *error = NULL;

	g_return_val_if_fail (thread_func != NULL, NULL);

	thread_pool = g_thread_pool_new (thread_func, user_data, max_threads, FALSE, &error);
	if (error) {
		g_warning ("%s: Failed to create thread pool: %s", G_STRFUNC, error->message);
		g_error_free (error);
		return NULL;
	}

	pool = g_new0 (EOperationPool, 1);
	pool->pool = thread_pool;
	g_mutex_init (&pool->ops_lock);
	pool->ops = g_hash_table_new (g_direct_hash, g_direct_equal);
	pool->last_opid = 0;

	/* Kill threads which don't do anything for 10 seconds */
	g_thread_pool_set_max_idle_time (10 * 1000);

	return pool;
}

/**
 * e_operation_pool_free:
 * @pool: an #EOperationPool
 *
 * Frees previously created @pool.
 *
 * Since: 3.2
 **/
void
e_operation_pool_free (EOperationPool *pool)
{
	g_return_if_fail (pool != NULL);

	g_thread_pool_free (pool->pool, FALSE, FALSE);
	g_mutex_clear (&pool->ops_lock);
	g_hash_table_destroy (pool->ops);
	g_free (pool);
}

/**
 * e_operation_pool_reserve_opid:
 * @pool: an #EOperationPool
 *
 * Reserves new operation ID, which is returned. This operation ID may
 * be released by e_operation_pool_release_opid() when the operation
 * is finished.
 *
 * Returns: a new operation ID
 *
 * Since: 3.2
 **/
guint32
e_operation_pool_reserve_opid (EOperationPool *pool)
{
	guint32 opid;

	g_return_val_if_fail (pool != NULL, 0);
	g_return_val_if_fail (pool->ops != NULL, 0);

	g_mutex_lock (&pool->ops_lock);

	pool->last_opid++;
	if (!pool->last_opid)
		pool->last_opid = 1;

	while (pool->last_opid && g_hash_table_lookup (pool->ops, GUINT_TO_POINTER (pool->last_opid)))
		pool->last_opid++;

	opid = pool->last_opid;
	if (opid)
		g_hash_table_insert (pool->ops, GUINT_TO_POINTER (opid), GUINT_TO_POINTER (1));

	g_mutex_unlock (&pool->ops_lock);

	g_return_val_if_fail (opid != 0, 0);

	return opid;
}

/**
 * e_operation_pool_release_opid:
 * @pool: an #EOperationPool
 * @opid: an operation ID
 *
 * Releases @opid previously reserved by e_operation_pool_reserve_opid().
 *
 * Since: 3.2
 **/
void
e_operation_pool_release_opid (EOperationPool *pool,
                               guint32 opid)
{
	g_return_if_fail (pool != NULL);
	g_return_if_fail (pool->ops != NULL);

	g_mutex_lock (&pool->ops_lock);
	g_hash_table_remove (pool->ops, GUINT_TO_POINTER (opid));
	g_mutex_unlock (&pool->ops_lock);
}

/**
 * e_operation_pool_push:
 * @pool: an #EOperationPool
 * @opdata: user data for the operation
 *
 * Pushes an operation to be processed.  @opdata is passed to the function
 * provided in e_operation_pool_new().
 *
 * Since: 3.2
 **/
void
e_operation_pool_push (EOperationPool *pool,
                       gpointer opdata)
{
	GError *error = NULL;

	g_return_if_fail (pool != NULL);
	g_return_if_fail (pool->pool != NULL);

	g_thread_pool_push (pool->pool, opdata, &error);

	if (error) {
		g_warning ("%s: Failed to push to thread pool: %s", G_STRFUNC, error->message);
		g_error_free (error);
	}
}
