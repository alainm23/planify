/*
 * camel-async-closure.c
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

/**
 * SECTION: camel-async-closure
 * @short_description: Run asynchronous functions synchronously
 * @include: camel/camel.h
 *
 * #CamelAsyncClosure provides a simple way to run an asynchronous function
 * synchronously without blocking the current thread.
 *
 * 1) Create a #CamelAsyncClosure with camel_async_closure_new().
 *
 * 2) Call the asynchronous function passing camel_async_closure_callback()
 *    as the #GAsyncReadyCallback argument and the #CamelAsyncClosure as the
 *    data argument.
 *
 * 3) Call camel_async_closure_wait() and collect the #GAsyncResult.
 *
 * 4) Call the corresponding asynchronous "finish" function, passing the
 *    #GAsyncResult returned by camel_async_closure_wait().
 *
 * 5) If needed, repeat steps 2-4 for additional asynchronous functions
 *    using the same #CamelAsyncClosure.
 *
 * 6) Finally, free the #CamelAsyncClosure with camel_async_closure_free().
 **/

#include "camel-async-closure.h"

/**
 * CamelAsyncClosure:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _CamelAsyncClosure {
	GMainLoop *loop;
	GMainContext *context;
	GAsyncResult *result;
	gboolean finished;
	GMutex lock;
};

/**
 * camel_async_closure_new: (skip)
 *
 * Creates a new #CamelAsyncClosure for use with asynchronous functions.
 *
 * Returns: a new #CamelAsyncClosure
 *
 * Since: 3.12
 **/
CamelAsyncClosure *
camel_async_closure_new (void)
{
	CamelAsyncClosure *closure;

	closure = g_slice_new0 (CamelAsyncClosure);
	closure->context = g_main_context_new ();
	closure->loop = g_main_loop_new (closure->context, FALSE);
	closure->finished = FALSE;
	g_mutex_init (&closure->lock);

	g_main_context_push_thread_default (closure->context);

	return closure;
}

static gboolean
camel_async_closure_unlock_mutex_cb (gpointer user_data)
{
	CamelAsyncClosure *closure = user_data;

	g_return_val_if_fail (closure != NULL, FALSE);

	g_mutex_unlock (&closure->lock);

	return FALSE;
}

/**
 * camel_async_closure_wait: (skip)
 * @closure: a #CamelAsyncClosure
 *
 * Call this function immediately after starting an asynchronous operation.
 * The function waits for the asynchronous operation to complete and returns
 * its #GAsyncResult to be passed to the operation's "finish" function.
 *
 * This function can be called repeatedly on the same #CamelAsyncClosure to
 * easily string together multiple asynchronous operations.
 *
 * Returns: (transfer none): a #GAsyncResult which is owned by the closure
 *
 * Since: 3.12
 **/
GAsyncResult *
camel_async_closure_wait (CamelAsyncClosure *closure)
{
	g_return_val_if_fail (closure != NULL, NULL);

	g_mutex_lock (&closure->lock);
	if (closure->finished) {
		g_mutex_unlock (&closure->lock);
	} else {
		GSource *idle_source;

		/* Unlock the closure->lock in the main loop, to ensure thread safety.
		   It should be processed before anything else, otherwise deadlock happens. */
		idle_source = g_idle_source_new ();
		g_source_set_callback (idle_source, camel_async_closure_unlock_mutex_cb, closure, NULL);
		g_source_set_priority (idle_source, G_PRIORITY_HIGH * 2);
		g_source_attach (idle_source, closure->context);
		g_source_unref (idle_source);

		g_main_loop_run (closure->loop);
	}

	return closure->result;
}

/**
 * camel_async_closure_free: (skip)
 * @closure: a #CamelAsyncClosure
 *
 * Frees the @closure and the resources it holds.
 *
 * Since: 3.12
 **/
void
camel_async_closure_free (CamelAsyncClosure *closure)
{
	g_return_if_fail (closure != NULL);

	g_main_context_pop_thread_default (closure->context);

	g_main_loop_unref (closure->loop);
	g_main_context_unref (closure->context);

	g_mutex_lock (&closure->lock);
	g_clear_object (&closure->result);
	g_mutex_unlock (&closure->lock);
	g_mutex_clear (&closure->lock);

	g_slice_free (CamelAsyncClosure, closure);
}

/**
 * camel_async_closure_callback: (skip)
 * @source_object: a #GObject or %NULL
 * @result: a #GAsyncResult
 * @closure: a #CamelAsyncClosure
 *
 * Pass this function as the #GAsyncReadyCallback argument of an asynchronous
 * function, and the #CamelAsyncClosure as the data argument.
 *
 * This causes camel_async_closure_wait() to terminate and return @result.
 *
 * Since: 3.12
 **/
void
camel_async_closure_callback (GObject *source_object,
                              GAsyncResult *result,
                              gpointer closure)
{
	CamelAsyncClosure *real_closure;

	g_return_if_fail (G_IS_ASYNC_RESULT (result));
	g_return_if_fail (closure != NULL);

	real_closure = closure;

	g_mutex_lock (&real_closure->lock);

	/* Replace any previous result. */
	if (real_closure->result != NULL)
		g_object_unref (real_closure->result);
	real_closure->result = g_object_ref (result);
	real_closure->finished = TRUE;

	g_mutex_unlock (&real_closure->lock);

	g_main_loop_quit (real_closure->loop);
}

