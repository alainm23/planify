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

#include "e-flag.h"

struct _EFlag {
	GCond cond;
	GMutex mutex;
	gboolean is_set;
};

/* This is to keep e_flag_timed_wait() building, since
 * it relies on g_cond_timed_wait() which is deprecated. */
#ifdef G_DISABLE_DEPRECATED
gboolean	g_cond_timed_wait		(GCond *cond,
						 GMutex *mutex,
						 GTimeVal *timeval);
#endif /* G_DISABLE_DEPRECATED */

/**
 * e_flag_new: (skip)
 *
 * Creates a new #EFlag object.  It is initially unset.
 *
 * Returns: a new #EFlag
 *
 * Since: 1.12
 **/
EFlag *
e_flag_new (void)
{
	EFlag *flag;

	flag = g_slice_new (EFlag);
	g_cond_init (&flag->cond);
	g_mutex_init (&flag->mutex);
	flag->is_set = FALSE;

	return flag;
}

/**
 * e_flag_is_set: (skip)
 * @flag: an #EFlag
 *
 * Returns the state of @flag.
 *
 * Returns: %TRUE if @flag is set
 *
 * Since: 1.12
 **/
gboolean
e_flag_is_set (EFlag *flag)
{
	gboolean is_set;

	g_return_val_if_fail (flag != NULL, FALSE);

	g_mutex_lock (&flag->mutex);
	is_set = flag->is_set;
	g_mutex_unlock (&flag->mutex);

	return is_set;
}

/**
 * e_flag_set: (skip)
 * @flag: an #EFlag
 *
 * Sets @flag.  All threads waiting on @flag are woken up.  Threads that
 * call e_flag_wait() or e_flag_wait_until() once @flag is set will not
 * block at all.
 *
 * Since: 1.12
 **/
void
e_flag_set (EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	g_mutex_lock (&flag->mutex);
	flag->is_set = TRUE;
	g_cond_broadcast (&flag->cond);
	g_mutex_unlock (&flag->mutex);
}

/**
 * e_flag_clear: (skip)
 * @flag: an #EFlag
 *
 * Unsets @flag.  Subsequent calls to e_flag_wait() or e_flag_wait_until()
 * will block until @flag is set.
 *
 * Since: 1.12
 **/
void
e_flag_clear (EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	g_mutex_lock (&flag->mutex);
	flag->is_set = FALSE;
	g_mutex_unlock (&flag->mutex);
}

/**
 * e_flag_wait: (skip)
 * @flag: an #EFlag
 *
 * Blocks until @flag is set.  If @flag is already set, the function returns
 * immediately.
 *
 * Since: 1.12
 **/
void
e_flag_wait (EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	g_mutex_lock (&flag->mutex);
	while (!flag->is_set)
		g_cond_wait (&flag->cond, &flag->mutex);
	g_mutex_unlock (&flag->mutex);
}

/**
 * e_flag_timed_wait: (skip)
 * @flag: an #EFlag
 * @abs_time: a #GTimeVal, determining the final time
 *
 * Blocks until @flag is set, or until the time specified by @abs_time.
 * If @flag is already set, the function returns immediately.  The return
 * value indicates the state of @flag after waiting.
 *
 * If @abs_time is %NULL, e_flag_timed_wait() acts like e_flag_wait().
 *
 * To easily calculate @abs_time, a combination of g_get_current_time() and
 * g_time_val_add() can be used.
 *
 * Returns: %TRUE if @flag is now set
 *
 * Since: 1.12
 *
 * Deprecated: 3.8: Use e_flag_wait_until() instead.
 **/
G_GNUC_BEGIN_IGNORE_DEPRECATIONS
gboolean
e_flag_timed_wait (EFlag *flag,
                   GTimeVal *abs_time)
{
	gboolean is_set;

	g_return_val_if_fail (flag != NULL, FALSE);

	g_mutex_lock (&flag->mutex);
	while (!flag->is_set)
		if (!g_cond_timed_wait (&flag->cond, &flag->mutex, abs_time))
			break;
	is_set = flag->is_set;
	g_mutex_unlock (&flag->mutex);

	return is_set;
}
G_GNUC_END_IGNORE_DEPRECATIONS

/**
 * e_flag_wait_until: (skip)
 * @flag: an #EFlag
 * @end_time: the monotonic time to wait until
 *
 * Blocks until @flag is set, or until the time specified by @end_time.
 * If @flag is already set, the function returns immediately.  The return
 * value indicates the state of @flag after waiting.
 *
 * To easily calculate @end_time, a combination of g_get_monotonic_time() and
 * G_TIME_SPAN_SECOND macro.
 *
 * Returns: %TRUE if @flag is now set
 *
 * Since: 3.8
 **/
gboolean
e_flag_wait_until (EFlag *flag,
                   gint64 end_time)
{
	gboolean is_set;

	g_return_val_if_fail (flag != NULL, FALSE);

	g_mutex_lock (&flag->mutex);
	while (!flag->is_set)
		if (!g_cond_wait_until (&flag->cond, &flag->mutex, end_time))
			break;
	is_set = flag->is_set;
	g_mutex_unlock (&flag->mutex);

	return is_set;
}

/**
 * e_flag_free: (skip)
 * @flag: an #EFlag
 *
 * Destroys @flag.
 *
 * Since: 1.12
 **/
void
e_flag_free (EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	/* Just to make sure that other threads are not holding the lock. */
	g_mutex_lock (&flag->mutex);
	g_cond_clear (&flag->cond);
	g_mutex_unlock (&flag->mutex);
	g_mutex_clear (&flag->mutex);
	g_slice_free (EFlag, flag);
}
