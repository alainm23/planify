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

#include "evolution-data-server-config.h"

#include "e-cancellable-locks.h"

/**
 * SECTION:e-cancellable-locks
 * @title: Cancellable Locks
 * @short_description: locks, which can listen for a #GCancellable during lock call
 *
 * An #ECancellableMutex and an #ECancellableRecMutex are similar to
 * GLib's #GMutex and #GRecMutex, with one exception, their <i>lock</i>
 * function takes also a @GCancellable instance, thus the waiting for a lock
 * can be cancelled any time.
 **/

static void
cancellable_locks_cancelled_cb (GCancellable *cancellable,
                                struct _ECancellableLocksBase *base)
{
	g_return_if_fail (base != NULL);

	/* wake-up any waiting threads */
	g_mutex_lock (&base->cond_mutex);
	g_cond_broadcast (&base->cond);
	g_mutex_unlock (&base->cond_mutex);
}

/**
 * e_cancellable_mutex_init:
 * @mutex: an #ECancellableMutex instance
 *
 * Initializes @mutex structure.
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_mutex_init (ECancellableMutex *mutex)
{
	g_return_if_fail (mutex != NULL);

	g_mutex_init (&mutex->mutex);
	g_mutex_init (&mutex->base.cond_mutex);
	g_cond_init (&mutex->base.cond);
}

/**
 * e_cancellable_mutex_clear:
 * @mutex: an #ECancellableMutex instance
 *
 * Frees memory allocated by e_cancellable_mutex_init().
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_mutex_clear (ECancellableMutex *mutex)
{
	g_return_if_fail (mutex != NULL);

	g_mutex_clear (&mutex->mutex);
	g_mutex_clear (&mutex->base.cond_mutex);
	g_cond_clear (&mutex->base.cond);
}

/**
 * e_cancellable_mutex_lock:
 * @mutex: an #ECancellableMutex instance
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 *
 * Acquires lock on @mutex. The returned value indicates whether
 * the lock was acquired, while %FALSE is returned only either or
 * invalid arguments or the passed in @cancellable had been cancelled.
 * In case of %NULL @cancellable the function blocks like g_mutex_lock().
 *
 * Returns: %TRUE, if lock had been acquired, %FALSE otherwise
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
gboolean
e_cancellable_mutex_lock (ECancellableMutex *mutex,
                          GCancellable *cancellable)
{
	gulong handler_id;
	gboolean res = TRUE;

	g_return_val_if_fail (mutex != NULL, FALSE);

	g_mutex_lock (&mutex->base.cond_mutex);
	if (!cancellable) {
		g_mutex_unlock (&mutex->base.cond_mutex);
		g_mutex_lock (&mutex->mutex);
		return TRUE;
	}

	if (g_cancellable_is_cancelled (cancellable)) {
		g_mutex_unlock (&mutex->base.cond_mutex);
		return FALSE;
	}

	handler_id = g_signal_connect (
		cancellable, "cancelled",
		G_CALLBACK (cancellable_locks_cancelled_cb), &mutex->base);

	while (!g_mutex_trylock (&mutex->mutex)) {
		/* recheck once per 10 seconds, just in case */
		g_cond_wait_until (
			&mutex->base.cond, &mutex->base.cond_mutex,
			g_get_monotonic_time () + (10 * G_TIME_SPAN_SECOND));

		if (g_cancellable_is_cancelled (cancellable)) {
			res = FALSE;
			break;
		}
	}

	g_signal_handler_disconnect (cancellable, handler_id);

	g_mutex_unlock (&mutex->base.cond_mutex);

	return res;
}

/**
 * e_cancellable_mutex_unlock:
 * @mutex: an #ECancellableMutex instance
 *
 * Releases lock previously acquired by e_cancellable_mutex_lock().
 * Behaviour is undefined if this is called on a @mutex which returned
 * %FALSE in e_cancellable_mutex_lock().
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_mutex_unlock (ECancellableMutex *mutex)
{
	g_return_if_fail (mutex != NULL);

	g_mutex_unlock (&mutex->mutex);

	g_mutex_lock (&mutex->base.cond_mutex);
	/* also wake-up any waiting threads */
	g_cond_broadcast (&mutex->base.cond);
	g_mutex_unlock (&mutex->base.cond_mutex);
}

/**
 * e_cancellable_mutex_get_internal_mutex:
 * @mutex: an #ECancellableMutex instance
 *
 * To get internal #GMutex. This is meant for cases when a lock is already
 * acquired, and the caller needs to wait for a #GCond, in which case
 * the returned #GMutex can be used to g_cond_wait() or g_cond_wait_until().
 *
 * Returns: Internal #GMutex, used in @mutex
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
GMutex *
e_cancellable_mutex_get_internal_mutex (ECancellableMutex *mutex)
{
	g_return_val_if_fail (mutex != NULL, NULL);

	return &mutex->mutex;
}

/**
 * e_cancellable_rec_mutex_init:
 * @rec_mutex: an #ECancellableRecMutex instance
 *
 * Initializes @rec_mutex structure.
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_rec_mutex_init (ECancellableRecMutex *rec_mutex)
{
	g_return_if_fail (rec_mutex != NULL);

	g_rec_mutex_init (&rec_mutex->rec_mutex);
	g_mutex_init (&rec_mutex->base.cond_mutex);
	g_cond_init (&rec_mutex->base.cond);
}

/**
 * e_cancellable_rec_mutex_clear:
 * @rec_mutex: an #ECancellableRecMutex instance
 *
 * Frees memory allocated by e_cancellable_rec_mutex_init().
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_rec_mutex_clear (ECancellableRecMutex *rec_mutex)
{
	g_return_if_fail (rec_mutex != NULL);

	g_rec_mutex_clear (&rec_mutex->rec_mutex);
	g_mutex_clear (&rec_mutex->base.cond_mutex);
	g_cond_clear (&rec_mutex->base.cond);
}

/**
 * e_cancellable_rec_mutex_lock:
 * @rec_mutex: an #ECancellableRecMutex instance
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 *
 * Acquires lock on @rec_mutex. The returned value indicates whether
 * the lock was acquired, while %FALSE is returned only either or
 * invalid arguments or the passed in @cancellable had been cancelled.
 * In case of %NULL @cancellable the function blocks like g_rec_mutex_lock().
 *
 * Returns: %TRUE, if lock had been acquired, %FALSE otherwise
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
gboolean
e_cancellable_rec_mutex_lock (ECancellableRecMutex *rec_mutex,
                              GCancellable *cancellable)
{
	gulong handler_id;
	gboolean res = TRUE;

	g_return_val_if_fail (rec_mutex != NULL, FALSE);

	g_mutex_lock (&rec_mutex->base.cond_mutex);
	if (!cancellable) {
		g_mutex_unlock (&rec_mutex->base.cond_mutex);
		g_rec_mutex_lock (&rec_mutex->rec_mutex);
		return TRUE;
	}

	if (g_cancellable_is_cancelled (cancellable)) {
		g_mutex_unlock (&rec_mutex->base.cond_mutex);
		return FALSE;
	}

	handler_id = g_signal_connect (
		cancellable, "cancelled",
		G_CALLBACK (cancellable_locks_cancelled_cb), &rec_mutex->base);

	while (!g_rec_mutex_trylock (&rec_mutex->rec_mutex)) {
		/* recheck once per 10 seconds, just in case */
		g_cond_wait_until (
			&rec_mutex->base.cond, &rec_mutex->base.cond_mutex,
			g_get_monotonic_time () + (10 * G_TIME_SPAN_SECOND));

		if (g_cancellable_is_cancelled (cancellable)) {
			res = FALSE;
			break;
		}
	}

	g_signal_handler_disconnect (cancellable, handler_id);

	g_mutex_unlock (&rec_mutex->base.cond_mutex);

	return res;
}

/**
 * e_cancellable_rec_mutex_unlock:
 * @rec_mutex: an #ECancellableRecMutex instance
 *
 * Releases lock previously acquired by e_cancellable_rec_mutex_lock().
 * Behaviour is undefined if this is called on a @rec_mutex which returned
 * %FALSE in e_cancellable_rec_mutex_lock().
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: If you think you need this, you're using mutexes wrong.
 **/
void
e_cancellable_rec_mutex_unlock (ECancellableRecMutex *rec_mutex)
{
	g_return_if_fail (rec_mutex != NULL);

	g_rec_mutex_unlock (&rec_mutex->rec_mutex);

	g_mutex_lock (&rec_mutex->base.cond_mutex);
	/* also wake-up any waiting threads */
	g_cond_broadcast (&rec_mutex->base.cond);
	g_mutex_unlock (&rec_mutex->base.cond_mutex);
}
