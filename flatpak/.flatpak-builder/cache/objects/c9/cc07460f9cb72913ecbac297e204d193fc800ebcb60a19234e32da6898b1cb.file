/*
 * camel-imapx-job.h
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

#ifndef CAMEL_IMAPX_JOB_H
#define CAMEL_IMAPX_JOB_H

#include "camel-imapx-server.h"

G_BEGIN_DECLS

typedef struct _CamelIMAPXJob CamelIMAPXJob;

struct _CamelIMAPXJob;

typedef enum {
	CAMEL_IMAPX_JOB_UNKNOWN = 0,
	CAMEL_IMAPX_JOB_CAPABILITY,
	CAMEL_IMAPX_JOB_STARTTLS,
	CAMEL_IMAPX_JOB_AUTHENTICATE,
	CAMEL_IMAPX_JOB_LOGIN,
	CAMEL_IMAPX_JOB_NAMESPACE,
	CAMEL_IMAPX_JOB_SELECT,
	CAMEL_IMAPX_JOB_STATUS,
	CAMEL_IMAPX_JOB_ENABLE,
	CAMEL_IMAPX_JOB_NOTIFY,
	CAMEL_IMAPX_JOB_GET_MESSAGE,
	CAMEL_IMAPX_JOB_SYNC_MESSAGE,
	CAMEL_IMAPX_JOB_APPEND_MESSAGE,
	CAMEL_IMAPX_JOB_COPY_MESSAGE,
	CAMEL_IMAPX_JOB_MOVE_MESSAGE,
	CAMEL_IMAPX_JOB_FETCH_NEW_MESSAGES,
	CAMEL_IMAPX_JOB_REFRESH_INFO,
	CAMEL_IMAPX_JOB_SYNC_CHANGES,
	CAMEL_IMAPX_JOB_EXPUNGE,
	CAMEL_IMAPX_JOB_NOOP,
	CAMEL_IMAPX_JOB_IDLE,
	CAMEL_IMAPX_JOB_DONE,
	CAMEL_IMAPX_JOB_LIST,
	CAMEL_IMAPX_JOB_LSUB,
	CAMEL_IMAPX_JOB_CREATE_MAILBOX,
	CAMEL_IMAPX_JOB_DELETE_MAILBOX,
	CAMEL_IMAPX_JOB_RENAME_MAILBOX,
	CAMEL_IMAPX_JOB_SUBSCRIBE_MAILBOX,
	CAMEL_IMAPX_JOB_UNSUBSCRIBE_MAILBOX,
	CAMEL_IMAPX_JOB_UPDATE_QUOTA_INFO,
	CAMEL_IMAPX_JOB_UID_SEARCH,
	CAMEL_IMAPX_JOB_LAST
} CamelIMAPXJobKind;

typedef const gchar *	(* CamelIMAPXJobGetKindNameFunc)(guint32 job_kind);

const gchar *	camel_imapx_job_get_kind_name	(guint32 job_kind);
void		camel_imapx_job_register_get_kind_name_func
						(CamelIMAPXJobGetKindNameFunc get_kind_name);
void		camel_imapx_job_unregister_get_kind_name_func
						(CamelIMAPXJobGetKindNameFunc get_kind_name);

typedef gboolean	(* CamelIMAPXJobRunSyncFunc)	(CamelIMAPXJob *job,
							 CamelIMAPXServer *server,
							 GCancellable *cancellable,
							 GError **error);
typedef gboolean	(* CamelIMAPXJobMatchesFunc)	(CamelIMAPXJob *job,
							 CamelIMAPXJob *other_job);
typedef void		(* CamelIMAPXJobCopyResultFunc)	(CamelIMAPXJob *job,
							 gconstpointer set_result,
							 gpointer *out_result);

CamelIMAPXJob *	camel_imapx_job_new		(guint32 job_kind,
						 CamelIMAPXMailbox *mailbox,
						 CamelIMAPXJobRunSyncFunc run_sync,
						 CamelIMAPXJobMatchesFunc matches,
						 CamelIMAPXJobCopyResultFunc copy_result);
CamelIMAPXJob *	camel_imapx_job_ref		(CamelIMAPXJob *job);
void		camel_imapx_job_unref		(CamelIMAPXJob *job);
guint32		camel_imapx_job_get_kind	(CamelIMAPXJob *job);
CamelIMAPXMailbox *
		camel_imapx_job_get_mailbox	(CamelIMAPXJob *job);
gpointer	camel_imapx_job_get_user_data	(CamelIMAPXJob *job);
void		camel_imapx_job_set_user_data	(CamelIMAPXJob *job,
						 gpointer user_data,
						 GDestroyNotify destroy_user_data);
gboolean	camel_imapx_job_was_cancelled	(CamelIMAPXJob *job);
void		camel_imapx_job_set_result	(CamelIMAPXJob *job,
						 gboolean success,
						 gpointer result,
						 const GError *error,
						 GDestroyNotify destroy_result);
gboolean	camel_imapx_job_copy_result	(CamelIMAPXJob *job,
						 gboolean *out_success,
						 gpointer *out_result,
						 GError **out_error,
						 GDestroyNotify *out_destroy_result);
gboolean	camel_imapx_job_take_result_data
						(CamelIMAPXJob *job,
						 gpointer *out_result);
gboolean	camel_imapx_job_matches		(CamelIMAPXJob *job,
						 CamelIMAPXJob *other_job);
gboolean	camel_imapx_job_run_sync	(CamelIMAPXJob *job,
						 CamelIMAPXServer *server,
						 GCancellable *cancellable,
						 GError **error);
void		camel_imapx_job_done		(CamelIMAPXJob *job);
void		camel_imapx_job_abort		(CamelIMAPXJob *job);
void		camel_imapx_job_wait_sync	(CamelIMAPXJob *job,
						 GCancellable *cancellable);

G_END_DECLS

#endif /* CAMEL_IMAPX_JOB_H */
