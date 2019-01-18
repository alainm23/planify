/*
 * camel-imapx-job.c
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

#include <string.h>

#include "camel-imapx-job.h"

G_LOCK_DEFINE_STATIC (get_kind_name_funcs);
static GSList *get_kind_name_funcs = NULL;

const gchar *
camel_imapx_job_get_kind_name (guint32 job_kind)
{
	GSList *link;

	switch ((CamelIMAPXJobKind) job_kind) {
	case CAMEL_IMAPX_JOB_UNKNOWN:
		return "UNKNOWN";
	case CAMEL_IMAPX_JOB_CAPABILITY:
		return "CAPABILITY";
	case CAMEL_IMAPX_JOB_STARTTLS:
		return "STARTTLS";
	case CAMEL_IMAPX_JOB_AUTHENTICATE:
		return "AUTHENTICATE";
	case CAMEL_IMAPX_JOB_LOGIN:
		return "LOGIN";
	case CAMEL_IMAPX_JOB_NAMESPACE:
		return "NAMESPACE";
	case CAMEL_IMAPX_JOB_SELECT:
		return "SELECT";
	case CAMEL_IMAPX_JOB_STATUS:
		return "STATUS";
	case CAMEL_IMAPX_JOB_ENABLE:
		return "ENABLE";
	case CAMEL_IMAPX_JOB_NOTIFY:
		return "NOTIFY";
	case CAMEL_IMAPX_JOB_GET_MESSAGE:
		return "GET_MESSAGE";
	case CAMEL_IMAPX_JOB_SYNC_MESSAGE:
		return "SYNC_MESSAGE";
	case CAMEL_IMAPX_JOB_APPEND_MESSAGE:
		return "APPEND_MESSAGE";
	case CAMEL_IMAPX_JOB_COPY_MESSAGE:
		return "COPY_MESSAGE";
	case CAMEL_IMAPX_JOB_MOVE_MESSAGE:
		return "MOVE_MESSAGE";
	case CAMEL_IMAPX_JOB_FETCH_NEW_MESSAGES:
		return "FETCH_NEW_MESSAGES";
	case CAMEL_IMAPX_JOB_REFRESH_INFO:
		return "REFRESH_INFO";
	case CAMEL_IMAPX_JOB_SYNC_CHANGES:
		return "SYNC_CHANGES";
	case CAMEL_IMAPX_JOB_EXPUNGE:
		return "EXPUNGE";
	case CAMEL_IMAPX_JOB_NOOP:
		return "NOOP";
	case CAMEL_IMAPX_JOB_IDLE:
		return "IDLE";
	case CAMEL_IMAPX_JOB_DONE:
		return "DONE";
	case CAMEL_IMAPX_JOB_LIST:
		return "LIST";
	case CAMEL_IMAPX_JOB_LSUB:
		return "LSUB";
	case CAMEL_IMAPX_JOB_CREATE_MAILBOX:
		return "CREATE_MAILBOX";
	case CAMEL_IMAPX_JOB_DELETE_MAILBOX:
		return "DELETE_MAILBOX";
	case CAMEL_IMAPX_JOB_RENAME_MAILBOX:
		return "RENAME_MAILBOX";
	case CAMEL_IMAPX_JOB_SUBSCRIBE_MAILBOX:
		return "SUBSCRIBE_MAILBOX";
	case CAMEL_IMAPX_JOB_UNSUBSCRIBE_MAILBOX:
		return "UNSUBSCRIBE_MAILBOX";
	case CAMEL_IMAPX_JOB_UPDATE_QUOTA_INFO:
		return "UPDATE_QUOTA_INFO";
	case CAMEL_IMAPX_JOB_UID_SEARCH:
		return "UID_SEARCH";
	case CAMEL_IMAPX_JOB_LAST:
		break;
	}

	G_LOCK (get_kind_name_funcs);

	for (link = get_kind_name_funcs; link; link = g_slist_next (link)) {
		CamelIMAPXJobGetKindNameFunc get_kind_name = link->data;

		if (get_kind_name) {
			const gchar *name = get_kind_name (job_kind);

			if (name) {
				G_UNLOCK (get_kind_name_funcs);
				return name;
			}
		}
	}

	G_UNLOCK (get_kind_name_funcs);

	if (job_kind == CAMEL_IMAPX_JOB_LAST)
		return "LAST";

	return "???";
}

void
camel_imapx_job_register_get_kind_name_func (CamelIMAPXJobGetKindNameFunc get_kind_name)
{
	g_return_if_fail (get_kind_name != NULL);

	G_LOCK (get_kind_name_funcs);

	if (!g_slist_find (get_kind_name_funcs, get_kind_name))
		get_kind_name_funcs = g_slist_prepend (get_kind_name_funcs, get_kind_name);

	G_UNLOCK (get_kind_name_funcs);
}

void
camel_imapx_job_unregister_get_kind_name_func (CamelIMAPXJobGetKindNameFunc get_kind_name)
{
	g_return_if_fail (get_kind_name != NULL);

	G_LOCK (get_kind_name_funcs);

	g_warn_if_fail (g_slist_find (get_kind_name_funcs, get_kind_name));
	get_kind_name_funcs = g_slist_remove (get_kind_name_funcs, get_kind_name);

	G_UNLOCK (get_kind_name_funcs);
}

struct _CamelIMAPXJob {
	volatile gint ref_count;

	guint32 job_kind;
	CamelIMAPXMailbox *mailbox;

	CamelIMAPXJobRunSyncFunc run_sync;
	CamelIMAPXJobMatchesFunc matches;
	CamelIMAPXJobCopyResultFunc copy_result;

	/* Extra job-specific data. */
	gpointer user_data;
	GDestroyNotify destroy_user_data;

	gboolean result_is_set;
	gboolean result_success;
	gpointer result_data;
	GError *result_error;
	GDestroyNotify destroy_result_data;

	GCond done_cond;
	GMutex done_mutex;
	gboolean is_done;

	GCancellable *abort_cancellable;
};

CamelIMAPXJob *
camel_imapx_job_new (guint32 job_kind,
		     CamelIMAPXMailbox *mailbox,
		     CamelIMAPXJobRunSyncFunc run_sync,
		     CamelIMAPXJobMatchesFunc matches,
		     CamelIMAPXJobCopyResultFunc copy_result)
{
	CamelIMAPXJob *job;

	g_return_val_if_fail (run_sync != NULL, NULL);

	job = g_new0 (CamelIMAPXJob, 1);
	job->ref_count = 1;
	job->job_kind = job_kind;
	job->mailbox = mailbox ? g_object_ref (mailbox) : NULL;
	job->run_sync = run_sync;
	job->matches = matches;
	job->copy_result = copy_result;
	job->abort_cancellable = camel_operation_new ();
	job->is_done = FALSE;

	g_cond_init (&job->done_cond);
	g_mutex_init (&job->done_mutex);

	return job;
}

CamelIMAPXJob *
camel_imapx_job_ref (CamelIMAPXJob *job)
{
	g_return_val_if_fail (job != NULL, NULL);

	g_atomic_int_inc (&job->ref_count);

	return job;
}

void
camel_imapx_job_unref (CamelIMAPXJob *job)
{
	g_return_if_fail (job != NULL);

	if (g_atomic_int_dec_and_test (&job->ref_count)) {
		if (job->destroy_user_data)
			job->destroy_user_data (job->user_data);

		if (job->result_is_set && job->destroy_result_data)
			job->destroy_result_data (job->result_data);

		g_clear_object (&job->mailbox);
		g_clear_object (&job->abort_cancellable);
		g_clear_error (&job->result_error);

		g_cond_clear (&job->done_cond);
		g_mutex_clear (&job->done_mutex);

		job->ref_count = 0xdeadbeef;

		g_free (job);
	}
}

guint32
camel_imapx_job_get_kind (CamelIMAPXJob *job)
{
	g_return_val_if_fail (job != NULL, CAMEL_IMAPX_JOB_UNKNOWN);

	return job->job_kind;
}

CamelIMAPXMailbox *
camel_imapx_job_get_mailbox (CamelIMAPXJob *job)
{
	g_return_val_if_fail (job != NULL, NULL);

	return job->mailbox;
}

gpointer
camel_imapx_job_get_user_data (CamelIMAPXJob *job)
{
	g_return_val_if_fail (job != NULL, NULL);

	return job->user_data;
}

void
camel_imapx_job_set_user_data (CamelIMAPXJob *job,
			       gpointer user_data,
			       GDestroyNotify destroy_user_data)
{
	g_return_if_fail (job != NULL);

	if (job->destroy_user_data)
		job->destroy_user_data (job->user_data);

	job->user_data = user_data;
	job->destroy_user_data = destroy_user_data;
}

gboolean
camel_imapx_job_was_cancelled (CamelIMAPXJob *job)
{
	g_return_val_if_fail (job != NULL, FALSE);

	if (!job->result_is_set)
		return FALSE;

	return g_error_matches (job->result_error, G_IO_ERROR, G_IO_ERROR_CANCELLED);
}

void
camel_imapx_job_set_result (CamelIMAPXJob *job,
			    gboolean success,
			    gpointer result,
			    const GError *error,
			    GDestroyNotify destroy_result)
{
	g_return_if_fail (job != NULL);

	if (job->result_is_set) {
		if (job->destroy_result_data)
			job->destroy_result_data (job->result_data);
		g_clear_error (&job->result_error);
	}

	job->result_is_set = TRUE;
	job->result_success = success;
	job->result_data = result;
	job->destroy_result_data = destroy_result;

	if (error)
		job->result_error = g_error_copy (error);
}

/* This doesn't return whether the job succeeded, but whether the result
   was set for the job, thus some result copied. All out-arguments are optional. */
gboolean
camel_imapx_job_copy_result (CamelIMAPXJob *job,
			     gboolean *out_success,
			     gpointer *out_result,
			     GError **out_error,
			     GDestroyNotify *out_destroy_result)
{
	g_return_val_if_fail (job != NULL, FALSE);

	if (!job->result_is_set)
		return FALSE;

	if (out_success)
		*out_success = job->result_success;

	if (out_result) {
		*out_result = NULL;

		if (job->copy_result) {
			job->copy_result (job, job->result_data, out_result);
		} else if (job->result_data) {
			g_warn_if_reached ();
		}
	}

	if (out_error) {
		g_warn_if_fail (*out_error == NULL);

		if (job->result_error)
			*out_error = g_error_copy (job->result_error);
	}

	if (out_destroy_result)
		*out_destroy_result = job->destroy_result_data;

	return TRUE;
}

/* Similar to camel_imapx_job_copy_result() except it gives result data
   to the caller and unsets (not frees) the data in the job. */
gboolean
camel_imapx_job_take_result_data (CamelIMAPXJob *job,
				  gpointer *out_result)
{
	g_return_val_if_fail (job != NULL, FALSE);

	if (!job->result_is_set)
		return FALSE;

	if (out_result) {
		*out_result = job->result_data;
	} else if (job->destroy_result_data) {
		job->destroy_result_data (job->result_data);
	}

	job->result_data = NULL;
	g_clear_error (&job->result_error);

	job->result_is_set = FALSE;

	return TRUE;
}

gboolean
camel_imapx_job_matches (CamelIMAPXJob *job,
			 CamelIMAPXJob *other_job)
{
	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (other_job != NULL, FALSE);

	if (job->job_kind != other_job->job_kind)
		return FALSE;

	if (job->mailbox != other_job->mailbox)
		return FALSE;

	if (job->matches)
		return job->matches (job, other_job);

	return TRUE;
}

static void
imapx_job_cancelled_cb (GCancellable *cancellable,
			CamelIMAPXJob *job)
{
	camel_imapx_job_abort (job);
}

static void
imapx_job_push_message_cb (CamelOperation *operation,
			   const gchar *message,
			   GCancellable *job_cancellable)
{
	g_return_if_fail (CAMEL_IS_OPERATION (operation));
	g_return_if_fail (CAMEL_IS_OPERATION (job_cancellable));

	camel_operation_push_message (job_cancellable, "%s", message);
}

static void
imapx_job_pop_message_cb (CamelOperation *operation,
			  GCancellable *job_cancellable)
{
	g_return_if_fail (CAMEL_IS_OPERATION (operation));
	g_return_if_fail (CAMEL_IS_OPERATION (job_cancellable));

	camel_operation_pop_message (job_cancellable);
}

static void
imapx_job_progress_cb (CamelOperation *operation,
		       gint percent,
		       GCancellable *job_cancellable)
{
	g_return_if_fail (CAMEL_IS_OPERATION (operation));
	g_return_if_fail (CAMEL_IS_OPERATION (job_cancellable));

	camel_operation_progress (job_cancellable, percent);
}

gboolean
camel_imapx_job_run_sync (CamelIMAPXJob *job,
			  CamelIMAPXServer *server,
			  GCancellable *cancellable,
			  GError **error)
{
	GError *local_error = NULL;
	gboolean success = FALSE;

	g_return_val_if_fail (job != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), FALSE);
	g_return_val_if_fail (job->run_sync != NULL, FALSE);

	g_mutex_lock (&job->done_mutex);
	job->is_done = FALSE;
	g_mutex_unlock (&job->done_mutex);

	g_cancellable_reset (job->abort_cancellable);

	if (!g_cancellable_set_error_if_cancelled (cancellable, error)) {
		gulong cancelled_handler_id = 0;
		gulong push_message_handler_id = 0;
		gulong pop_message_handler_id = 0;
		gulong progress_handler_id = 0;

		/* Proxy signals between job's cancellable and the abort_cancellable */
		if (cancellable)
			cancelled_handler_id = g_cancellable_connect (cancellable,
				G_CALLBACK (imapx_job_cancelled_cb), job, NULL);

		if (CAMEL_IS_OPERATION (cancellable)) {
			push_message_handler_id = g_signal_connect (job->abort_cancellable, "push-message",
				G_CALLBACK (imapx_job_push_message_cb), cancellable);
			pop_message_handler_id = g_signal_connect (job->abort_cancellable, "pop-message",
				G_CALLBACK (imapx_job_pop_message_cb), cancellable);
			progress_handler_id = g_signal_connect (job->abort_cancellable, "progress",
				G_CALLBACK (imapx_job_progress_cb), cancellable);
		}

		success = job->run_sync (job, server, job->abort_cancellable, &local_error);

		if (push_message_handler_id)
			g_signal_handler_disconnect (job->abort_cancellable, push_message_handler_id);
		if (pop_message_handler_id)
			g_signal_handler_disconnect (job->abort_cancellable, pop_message_handler_id);
		if (progress_handler_id)
			g_signal_handler_disconnect (job->abort_cancellable, progress_handler_id);
		if (cancelled_handler_id)
			g_cancellable_disconnect (cancellable, cancelled_handler_id);
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

void
camel_imapx_job_done (CamelIMAPXJob *job)
{
	g_return_if_fail (job != NULL);

	g_mutex_lock (&job->done_mutex);
	job->is_done = TRUE;
	g_cond_broadcast (&job->done_cond);
	g_mutex_unlock (&job->done_mutex);
}

void
camel_imapx_job_abort (CamelIMAPXJob *job)
{
	g_return_if_fail (job != NULL);

	g_cancellable_cancel (job->abort_cancellable);
}

static void
camel_imapx_job_wait_cancelled_cb (GCancellable *cancellable,
				   gpointer user_data)
{
	CamelIMAPXJob *job = user_data;

	g_return_if_fail (job != NULL);

	g_mutex_lock (&job->done_mutex);
	g_cond_broadcast (&job->done_cond);
	g_mutex_unlock (&job->done_mutex);
}

void
camel_imapx_job_wait_sync (CamelIMAPXJob *job,
			   GCancellable *cancellable)
{
	gulong handler_id = 0;

	g_return_if_fail (job != NULL);

	if (g_cancellable_is_cancelled (cancellable))
		return;

	if (cancellable)
		handler_id = g_cancellable_connect (cancellable, G_CALLBACK (camel_imapx_job_wait_cancelled_cb), job, NULL);

	g_mutex_lock (&job->done_mutex);
	while (!job->is_done && !g_cancellable_is_cancelled (cancellable)) {
		g_cond_wait (&job->done_cond, &job->done_mutex);
	}
	g_mutex_unlock (&job->done_mutex);

	if (handler_id)
		g_cancellable_disconnect (cancellable, handler_id);
}
