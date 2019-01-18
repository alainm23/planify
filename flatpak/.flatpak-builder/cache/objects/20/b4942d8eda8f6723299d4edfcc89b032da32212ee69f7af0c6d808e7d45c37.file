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

#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/types.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>
#include <gio/gnetworking.h>

#include <libical/ical.h>

#ifndef G_OS_WIN32
#include <glib-unix.h>
#endif /* G_OS_WIN32 */

#include <camel/camel.h>

#include "camel-imapx-server.h"

#include "camel-imapx-folder.h"
#include "camel-imapx-input-stream.h"
#include "camel-imapx-job.h"
#include "camel-imapx-logger.h"
#include "camel-imapx-message-info.h"
#include "camel-imapx-settings.h"
#include "camel-imapx-store.h"
#include "camel-imapx-summary.h"
#include "camel-imapx-utils.h"

#define CAMEL_IMAPX_SERVER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_SERVER, CamelIMAPXServerPrivate))

#define c(...) camel_imapx_debug(command, __VA_ARGS__)
#define e(...) camel_imapx_debug(extra, __VA_ARGS__)

#define COMMAND_LOCK(x) g_rec_mutex_lock (&(x)->priv->command_lock)
#define COMMAND_UNLOCK(x) g_rec_mutex_unlock (&(x)->priv->command_lock)

/* Try pipelining fetch requests, 'in bits' */
#define MULTI_SIZE (32768 * 8)

#define MAX_COMMAND_LEN 1000

/* Ping the server after a period of inactivity to avoid being logged off.
 * Using a 29 minute inactivity timeout as recommended in RFC 2177 (IDLE). */
#define INACTIVITY_TIMEOUT_SECONDS (29 * 60)

/* Number of seconds to remain in PENDING state waiting for other commands
   to be queued, before actually sending IDLE */
#define IMAPX_IDLE_WAIT_SECONDS 2

#ifdef G_OS_WIN32
#ifdef gmtime_r
#undef gmtime_r
#endif

/* The gmtime() in Microsoft's C library is MT-safe */
#define gmtime_r(tp,tmp) (gmtime(tp)?(*(tmp)=*gmtime(tp),(tmp)):0)
#endif

G_DEFINE_QUARK (camel-imapx-server-error-quark, camel_imapx_server_error)

/* untagged response handling */

/* May need to turn this into separate,
 * subclassable GObject with proper getter/setter
 * functions so derived implementations can
 * supply their own context information.
 * The context supplied here, however, should
 * not be exposed outside CamelIMAPXServer.
 * An instance is created in imapx_untagged()
 * with a lifetime of one run of this function.
 * In order to supply a derived context instance,
 * we would need to register a derived _new()
 * function for it which will be called inside
 * imapx_untagged().
 *
 * TODO: rethink this construct.
 */
typedef struct _CamelIMAPXServerUntaggedContext CamelIMAPXServerUntaggedContext;

struct _CamelIMAPXServerUntaggedContext {
	CamelSortType fetch_order;
	gulong id;
	guint len;
	guchar *token;
	gint tok;
	gboolean lsub;
	struct _status_info *sinfo;
};

/* internal untagged handler prototypes */
static gboolean	imapx_untagged_bye		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_capability	(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_exists		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_expunge		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_fetch		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_flags		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_list		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_lsub		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_namespace	(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_ok_no_bad	(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_preauth		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_quota		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_quotaroot	(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_recent		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_search		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_status		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean	imapx_untagged_vanished		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GCancellable *cancellable,
						 GError **error);

enum {
	IMAPX_UNTAGGED_ID_BAD = 0,
	IMAPX_UNTAGGED_ID_BYE,
	IMAPX_UNTAGGED_ID_CAPABILITY,
	IMAPX_UNTAGGED_ID_EXISTS,
	IMAPX_UNTAGGED_ID_EXPUNGE,
	IMAPX_UNTAGGED_ID_FETCH,
	IMAPX_UNTAGGED_ID_FLAGS,
	IMAPX_UNTAGGED_ID_LIST,
	IMAPX_UNTAGGED_ID_LSUB,
	IMAPX_UNTAGGED_ID_NAMESPACE,
	IMAPX_UNTAGGED_ID_NO,
	IMAPX_UNTAGGED_ID_OK,
	IMAPX_UNTAGGED_ID_PREAUTH,
	IMAPX_UNTAGGED_ID_QUOTA,
	IMAPX_UNTAGGED_ID_QUOTAROOT,
	IMAPX_UNTAGGED_ID_RECENT,
	IMAPX_UNTAGGED_ID_SEARCH,
	IMAPX_UNTAGGED_ID_STATUS,
	IMAPX_UNTAGGED_ID_VANISHED,
	IMAPX_UNTAGGED_LAST_ID
};

static const CamelIMAPXUntaggedRespHandlerDesc _untagged_descr[] = {
	{CAMEL_IMAPX_UNTAGGED_BAD, imapx_untagged_ok_no_bad, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_BYE, imapx_untagged_bye, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_CAPABILITY, imapx_untagged_capability, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_EXISTS, imapx_untagged_exists, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_EXPUNGE, imapx_untagged_expunge, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_FETCH, imapx_untagged_fetch, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_FLAGS, imapx_untagged_flags, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_LIST, imapx_untagged_list, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_LSUB, imapx_untagged_lsub, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_NAMESPACE, imapx_untagged_namespace, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_NO, imapx_untagged_ok_no_bad, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_OK, imapx_untagged_ok_no_bad, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_PREAUTH, imapx_untagged_preauth, CAMEL_IMAPX_UNTAGGED_OK, TRUE /*overridden */ },
	{CAMEL_IMAPX_UNTAGGED_QUOTA, imapx_untagged_quota, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_QUOTAROOT, imapx_untagged_quotaroot, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_RECENT, imapx_untagged_recent, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_SEARCH, imapx_untagged_search, NULL, FALSE},
	{CAMEL_IMAPX_UNTAGGED_STATUS, imapx_untagged_status, NULL, TRUE},
	{CAMEL_IMAPX_UNTAGGED_VANISHED, imapx_untagged_vanished, NULL, TRUE},
};

typedef enum {
	IMAPX_IDLE_STATE_OFF,       /* no IDLE running at all */
	IMAPX_IDLE_STATE_SCHEDULED, /* IDLE scheduled, but still waiting */
	IMAPX_IDLE_STATE_PREPARING, /* IDLE command going to be processed */
	IMAPX_IDLE_STATE_RUNNING,   /* IDLE command had been processed, server responded */
	IMAPX_IDLE_STATE_STOPPING   /* DONE had been issued, waiting for completion */
} IMAPXIdleState;

struct _CamelIMAPXServerPrivate {
	GWeakRef store;
	GCancellable *cancellable; /* the main connection cancellable, it's cancelled on disconnect */

	CamelIMAPXServerUntaggedContext *context;
	GHashTable *untagged_handlers;

	/* The 'stream_lock' also guards the GSubprocess. */
	GInputStream *input_stream;
	GOutputStream *output_stream;
	GIOStream *connection;
	GSubprocess *subprocess;
	GMutex stream_lock;

	GSource *inactivity_timeout;
	GMutex inactivity_timeout_lock;

	/* Info on currently selected folder. */
	GMutex select_lock;
	GWeakRef select_mailbox;
	GWeakRef select_pending;
	gint last_selected_mailbox_change_stamp;

	GMutex changes_lock;
	CamelFolderChangeInfo *changes;

	/* Data items to request in STATUS commands:
	 * STATUS $mailbox_name ($status_data_items) */
	gchar *status_data_items;

	/* Return options for extended LIST commands:
	 * LIST "" $pattern RETURN ($list_return_opts) */
	gchar *list_return_opts;

	/* Untagged SEARCH data gets deposited here.
	 * The search command should claim the results
	 * when finished and reset the pointer to NULL. */
	GArray *search_results;
	GMutex search_results_lock;

	GHashTable *known_alerts;
	GMutex known_alerts_lock;

	/* INBOX separator character, so we can correctly normalize
	 * INBOX and descendants of INBOX in IMAP responses that do
	 * not include a separator character with the mailbox name,
	 * such as STATUS.  Used for camel_imapx_parse_mailbox(). */
	gchar inbox_separator;

	/* IDLE support */
	GMutex idle_lock;
	GCond idle_cond;
	IMAPXIdleState idle_state;
	GSource *idle_pending;
	CamelIMAPXMailbox *idle_mailbox;
	GCancellable *idle_cancellable;
	guint idle_stamp;

	gboolean is_cyrus;
	gboolean is_broken_cyrus;

	/* Info about the current connection; guarded by priv->stream_lock */
	struct _capability_info *cinfo;

	GRecMutex command_lock;

	gchar tagprefix;
	guint32 state;

	gboolean use_qresync;

	CamelIMAPXCommand *current_command;
	CamelIMAPXCommand *continuation_command;

	/* operation data */
	GIOStream *get_message_stream;

	CamelIMAPXMailbox *fetch_changes_mailbox; /* not referenced */
	CamelFolder *fetch_changes_folder; /* not referenced */
	GHashTable *fetch_changes_infos; /* gchar *uid ~> FetchChangesInfo-s */
	gint64 fetch_changes_last_progress; /* when was called last progress */

	struct _status_info *copyuid_status;

	GHashTable *list_responses_hash; /* ghar *mailbox-name ~> CamelIMAPXListResponse *, both owned by list_responses */
	GSList *list_responses;
	GSList *lsub_responses;

	gboolean utf8_accept; /* RFC 6855 */
};

enum {
	PROP_0,
	PROP_STORE
};

enum {
	REFRESH_MAILBOX,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static gboolean	imapx_continuation		(CamelIMAPXServer *is,
						 GInputStream *input_stream,
						 GOutputStream *output_stream,
						 gboolean litplus,
						 GCancellable *cancellable,
						 GError **error);
static void	imapx_disconnect		(CamelIMAPXServer *is);

/* states for the connection? */
enum {
	IMAPX_DISCONNECTED,
	IMAPX_SHUTDOWN,
	IMAPX_CONNECTED,
	IMAPX_AUTHENTICATED,
	IMAPX_INITIALISED,
	IMAPX_SELECTED
};

struct _imapx_flag_change {
	GPtrArray *infos;
	gchar *name;
};

static gint	imapx_refresh_info_uid_cmp	(gconstpointer ap,
						 gconstpointer bp,
						 gboolean ascending);
static gint	imapx_uids_array_cmp		(gconstpointer ap,
						 gconstpointer bp);
static void	imapx_sync_free_user		(GArray *user_set);

G_DEFINE_TYPE (CamelIMAPXServer, camel_imapx_server, G_TYPE_OBJECT)

typedef struct _FetchChangesInfo {
	guint32 server_flags;
	CamelNamedFlags *server_user_flags;
} FetchChangesInfo;

static void
fetch_changes_info_free (gpointer ptr)
{
	FetchChangesInfo *nfo = ptr;

	if (nfo) {
		camel_named_flags_free (nfo->server_user_flags);
		g_free (nfo);
	}
}

static GWeakRef *
imapx_weak_ref_new (gpointer object)
{
	GWeakRef *weak_ref;

	/* XXX Might want to expose this in Camel's public API if it
	 *     proves useful elsewhere.  Based on e_weak_ref_new(). */

	weak_ref = g_slice_new0 (GWeakRef);
	g_weak_ref_init (weak_ref, object);

	return weak_ref;
}

static void
imapx_weak_ref_free (GWeakRef *weak_ref)
{
	g_return_if_fail (weak_ref != NULL);

	/* XXX Might want to expose this in Camel's public API if it
	 *     proves useful elsewhere.  Based on e_weak_ref_free(). */

	g_weak_ref_clear (weak_ref);
	g_slice_free (GWeakRef, weak_ref);
}

static const CamelIMAPXUntaggedRespHandlerDesc *
replace_untagged_descriptor (GHashTable *untagged_handlers,
                             const gchar *key,
                             const CamelIMAPXUntaggedRespHandlerDesc *descr)
{
	const CamelIMAPXUntaggedRespHandlerDesc *prev = NULL;

	g_return_val_if_fail (untagged_handlers != NULL, NULL);
	g_return_val_if_fail (key != NULL, NULL);
	/* descr may be NULL (to delete a handler) */

	prev = g_hash_table_lookup (untagged_handlers, key);
	g_hash_table_replace (
		untagged_handlers,
		g_strdup (key),
		(gpointer) descr);
	return prev;
}

static void
add_initial_untagged_descriptor (GHashTable *untagged_handlers,
                                 guint untagged_id)
{
	const CamelIMAPXUntaggedRespHandlerDesc *prev = NULL;
	const CamelIMAPXUntaggedRespHandlerDesc *cur = NULL;

	g_return_if_fail (untagged_handlers != NULL);
	g_return_if_fail (untagged_id < IMAPX_UNTAGGED_LAST_ID);

	cur = &(_untagged_descr[untagged_id]);
	prev = replace_untagged_descriptor (
		untagged_handlers,
		cur->untagged_response,
		cur);
	/* there must not be any previous handler here */
	g_return_if_fail (prev == NULL);
}

static GHashTable *
create_initial_untagged_handler_table (void)
{
	GHashTable *uh = g_hash_table_new_full (
		camel_strcase_hash,
		camel_strcase_equal,
		g_free,
		NULL);
	guint32 ii = 0;

	/* CamelIMAPXServer predefined handlers*/
	for (ii = 0; ii < IMAPX_UNTAGGED_LAST_ID; ii++)
		add_initial_untagged_descriptor (uh, ii);

	g_return_val_if_fail (g_hash_table_size (uh) == IMAPX_UNTAGGED_LAST_ID, NULL);

	return uh;
}

struct _uidset_state {
	gint entries, uids;
	gint total, limit;
	guint32 start;
	guint32 last;
};

/*
  this creates a uid (or sequence number) set directly into a command,
  if total is set, then we break it up into total uids. (i.e. command time)
  if limit is set, then we break it up into limit entries (i.e. command length)
*/
static void
imapx_uidset_init (struct _uidset_state *ss,
                   gint total,
                   gint limit)
{
	ss->uids = 0;
	ss->entries = 0;
	ss->start = 0;
	ss->last = 0;
	ss->total = total;
	ss->limit = limit;
}

static gboolean
imapx_uidset_done (struct _uidset_state *ss,
                   CamelIMAPXCommand *ic)
{
	gint ret = FALSE;

	if (ss->last != 0) {
		if (ss->entries > 0)
			camel_imapx_command_add (ic, ",");
		if (ss->last == ss->start)
			camel_imapx_command_add (ic, "%u", ss->last);
		else
			camel_imapx_command_add (ic, "%u:%u", ss->start, ss->last);
	}

	ret = ss->last != 0;

	ss->start = 0;
	ss->last = 0;
	ss->uids = 0;
	ss->entries = 0;

	return ret;
}

static gint
imapx_uidset_add (struct _uidset_state *ss,
                  CamelIMAPXCommand *ic,
                  const gchar *uid)
{
	guint32 uidn;

	uidn = strtoul (uid, NULL, 10);
	if (uidn == 0)
		return -1;

	ss->uids++;

	e (ic->is->priv->tagprefix, "uidset add '%s'\n", uid);

	if (ss->last == 0) {
		e (ic->is->priv->tagprefix, " start\n");
		ss->start = uidn;
		ss->last = uidn;
	} else {
		if (ss->start - 1 == uidn) {
			ss->start = uidn;
		} else {
			if (ss->last != uidn - 1) {
				if (ss->last == ss->start) {
					e (ic->is->priv->tagprefix, " ,next\n");
					if (ss->entries > 0)
						camel_imapx_command_add (ic, ",");
					camel_imapx_command_add (ic, "%u", ss->start);
					ss->entries++;
				} else {
					e (ic->is->priv->tagprefix, " :range\n");
					if (ss->entries > 0)
						camel_imapx_command_add (ic, ",");
					camel_imapx_command_add (ic, "%u:%u", ss->start, ss->last);
					ss->entries += 2;
				}
				ss->start = uidn;
			}

			ss->last = uidn;
		}
	}

	if ((ss->limit && ss->entries >= ss->limit)
	    || (ss->limit && ss->uids >= ss->limit)
	    || (ss->total && ss->uids >= ss->total)) {
		e (ic->is->priv->tagprefix, " done, %d entries, %d uids\n", ss->entries, ss->uids);
		if (!imapx_uidset_done (ss, ic))
			return -1;
		return 1;
	}

	return 0;
}

static CamelFolder *
imapx_server_ref_folder (CamelIMAPXServer *is,
                         CamelIMAPXMailbox *mailbox)
{
	CamelFolder *folder;
	CamelIMAPXStore *store;
	gchar *folder_path;
	GError *local_error = NULL;

	store = camel_imapx_server_ref_store (is);

	folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);

	folder = camel_store_get_folder_sync (
		CAMEL_STORE (store), folder_path, 0, NULL, &local_error);

	g_free (folder_path);

	g_object_unref (store);

	/* Sanity check. */
	g_warn_if_fail (
		((folder != NULL) && (local_error == NULL)) ||
		((folder == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_warning (
			"%s: Failed to get folder for '%s': %s",
			G_STRFUNC, camel_imapx_mailbox_get_name (mailbox), local_error->message);
		g_error_free (local_error);
	}

	return folder;
}

static void
imapx_server_stash_command_arguments (CamelIMAPXServer *is)
{
	GString *buffer;

	/* Stash some reusable capability-based command arguments. */

	buffer = g_string_new ("MESSAGES UNSEEN UIDVALIDITY UIDNEXT");
	if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, CONDSTORE))
		g_string_append (buffer, " HIGHESTMODSEQ");
	g_free (is->priv->status_data_items);
	is->priv->status_data_items = g_string_free (buffer, FALSE);

	g_free (is->priv->list_return_opts);
	if (!is->priv->is_broken_cyrus && CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, LIST_EXTENDED)) {
		buffer = g_string_new ("CHILDREN SUBSCRIBED");
		if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, LIST_STATUS))
			g_string_append_printf (
				buffer, " STATUS (%s)",
				is->priv->status_data_items);
		if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, SPECIAL_USE) || CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, X_GM_EXT_1))
			g_string_append_printf (buffer, " SPECIAL-USE");
		is->priv->list_return_opts = g_string_free (buffer, FALSE);
	} else {
		is->priv->list_return_opts = NULL;
	}
}

static gpointer
imapx_server_inactivity_thread (gpointer user_data)
{
	CamelIMAPXServer *is = user_data;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	if (camel_imapx_server_is_in_idle (is)) {
		/* Stop and restart the IDLE command. */
		if (!camel_imapx_server_schedule_idle_sync (is, NULL, is->priv->cancellable, &local_error) &&
		    !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
			camel_imapx_debug (io, camel_imapx_server_get_tagprefix (is),
				"%s: Failed to restart IDLE: %s\n", G_STRFUNC, local_error ? local_error->message : "Unknown error");
	} else {
		if (!camel_imapx_server_noop_sync (is, NULL, is->priv->cancellable, &local_error) &&
		    !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
			camel_imapx_debug (io, camel_imapx_server_get_tagprefix (is),
				"%s: Failed to issue NOOP: %s\n", G_STRFUNC, local_error ? local_error->message : "Unknown error");
	}

	g_clear_error (&local_error);
	g_object_unref (is);

	return NULL;
}

static gboolean
imapx_server_inactivity_timeout_cb (gpointer data)
{
	CamelIMAPXServer *is;
	GThread *thread;
	GError *local_error = NULL;

	is = g_weak_ref_get (data);

	if (is == NULL)
		return G_SOURCE_REMOVE;

	thread = g_thread_try_new (NULL, imapx_server_inactivity_thread, g_object_ref (is), &local_error);
	if (!thread) {
		g_warning ("%s: Failed to start inactivity thread: %s", G_STRFUNC, local_error ? local_error->message : "Unknown error");
		g_object_unref (is);
	} else {
		g_thread_unref (thread);
	}

	g_clear_error (&local_error);
	g_object_unref (is);

	return G_SOURCE_REMOVE;
}

static void
imapx_server_reset_inactivity_timer (CamelIMAPXServer *is)
{
	g_mutex_lock (&is->priv->inactivity_timeout_lock);

	if (is->priv->inactivity_timeout != NULL) {
		g_source_destroy (is->priv->inactivity_timeout);
		g_source_unref (is->priv->inactivity_timeout);
	}

	is->priv->inactivity_timeout =
		g_timeout_source_new_seconds (INACTIVITY_TIMEOUT_SECONDS);
	g_source_set_callback (
		is->priv->inactivity_timeout,
		imapx_server_inactivity_timeout_cb,
		imapx_weak_ref_new (is),
		(GDestroyNotify) imapx_weak_ref_free);
	g_source_attach (is->priv->inactivity_timeout, NULL);

	g_mutex_unlock (&is->priv->inactivity_timeout_lock);
}

static gint
imapx_server_set_connection_timeout (GIOStream *connection,
				     gint timeout_seconds)
{
	GSocket *socket;
	gint previous_timeout = -1;

	if (G_IS_TLS_CONNECTION (connection)) {
		GIOStream *base_io_stream = NULL;

		g_object_get (G_OBJECT (connection), "base-io-stream", &base_io_stream, NULL);

		connection = base_io_stream;
	} else if (connection) {
		/* Connection can be NULL, when a custom command (GSubProcess) is used instead */
		g_object_ref (connection);
	}

	if (!G_IS_SOCKET_CONNECTION (connection)) {
		g_clear_object (&connection);
		return previous_timeout;
	}

	socket = g_socket_connection_get_socket (G_SOCKET_CONNECTION (connection));
	if (socket) {
		previous_timeout = g_socket_get_timeout (socket);
		g_socket_set_timeout (socket, timeout_seconds);
	}

	g_clear_object (&connection);

	return previous_timeout;
}

/* untagged response handler functions */

static gboolean
imapx_untagged_capability (CamelIMAPXServer *is,
                           GInputStream *input_stream,
                           GCancellable *cancellable,
                           GError **error)
{
	struct _capability_info *cinfo;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->stream_lock);

	if (is->priv->cinfo != NULL) {
		imapx_free_capability (is->priv->cinfo);
		is->priv->cinfo = NULL;
	}

	g_mutex_unlock (&is->priv->stream_lock);

	cinfo = imapx_parse_capability (CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);

	if (!cinfo)
		return FALSE;

	g_mutex_lock (&is->priv->stream_lock);

	if (is->priv->cinfo != NULL)
		imapx_free_capability (is->priv->cinfo);
	is->priv->cinfo = cinfo;

	c (is->priv->tagprefix, "got capability flags %08x\n", is->priv->cinfo->capa);

	imapx_server_stash_command_arguments (is);

	g_mutex_unlock (&is->priv->stream_lock);

	return TRUE;
}

static gboolean
imapx_untagged_expunge (CamelIMAPXServer *is,
                        GInputStream *input_stream,
                        GCancellable *cancellable,
                        GError **error)
{
	gulong expunged_idx;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	expunged_idx = is->priv->context->id;

	COMMAND_LOCK (is);

	/* Ignore EXPUNGE responses when not running a COPY(MOVE)_MESSAGE job */
	if (!is->priv->current_command || (is->priv->current_command->job_kind != CAMEL_IMAPX_JOB_COPY_MESSAGE &&
	    is->priv->current_command->job_kind != CAMEL_IMAPX_JOB_MOVE_MESSAGE)) {
		gboolean ignored = TRUE;
		gboolean is_idle_command = is->priv->current_command && is->priv->current_command->job_kind == CAMEL_IMAPX_JOB_IDLE;

		COMMAND_UNLOCK (is);

		/* Process only untagged EXPUNGE responses within ongoing IDLE command */
		if (is_idle_command) {
			CamelIMAPXMailbox *mailbox;

			mailbox = camel_imapx_server_ref_selected (is);
			if (mailbox) {
				guint32 messages;

				messages = camel_imapx_mailbox_get_messages (mailbox);
				if (messages > 0) {
					camel_imapx_mailbox_set_messages (mailbox, messages - 1);

					ignored = FALSE;
					c (is->priv->tagprefix, "going to refresh mailbox '%s' due to untagged expunge: %lu\n", camel_imapx_mailbox_get_name (mailbox), expunged_idx);

					g_signal_emit (is, signals[REFRESH_MAILBOX], 0, mailbox);
				}

				g_object_unref (mailbox);
			}
		}

		if (ignored)
			c (is->priv->tagprefix, "ignoring untagged expunge: %lu\n", expunged_idx);

		return TRUE;
	}

	c (is->priv->tagprefix, "expunged: %lu\n", expunged_idx);

	is->priv->current_command->copy_move_expunged = g_slist_prepend (
		is->priv->current_command->copy_move_expunged, GUINT_TO_POINTER (expunged_idx));

	COMMAND_UNLOCK (is);

	return TRUE;
}

typedef struct _GatherExistingUidsData {
	CamelIMAPXServer *is;
	CamelFolderSummary *summary;
	GList *uid_list;
	guint32 n_uids;
} GatherExistingUidsData;

static gboolean
imapx_gather_existing_uids_cb (guint32 uid,
			       gpointer user_data)
{
	GatherExistingUidsData *geud = user_data;
	gchar *uid_str;

	g_return_val_if_fail (geud != NULL, FALSE);
	g_return_val_if_fail (geud->is != NULL, FALSE);
	g_return_val_if_fail (geud->summary != NULL, FALSE);

	geud->n_uids++;

	uid_str = g_strdup_printf ("%u", uid);

	if (camel_folder_summary_check_uid (geud->summary, uid_str)) {
		e (geud->is->priv->tagprefix, "vanished known UID: %u\n", uid);
		if (!geud->uid_list)
			g_mutex_lock (&geud->is->priv->changes_lock);

		geud->uid_list = g_list_prepend (geud->uid_list, uid_str);
		camel_folder_change_info_remove_uid (geud->is->priv->changes, uid_str);
	} else {
		e (geud->is->priv->tagprefix, "vanished unknown UID: %u\n", uid);
		g_free (uid_str);
	}

	return TRUE;
}

static gboolean
imapx_untagged_vanished (CamelIMAPXServer *is,
                         GInputStream *input_stream,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelFolder *folder;
	CamelIMAPXMailbox *mailbox;
	GatherExistingUidsData geud;
	gboolean unsolicited = TRUE;
	guint len = 0;
	guchar *token = NULL;
	gint tok = 0;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	tok = camel_imapx_input_stream_token (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		&token, &len, cancellable, error);
	if (tok < 0)
		return FALSE;
	if (tok == '(') {
		unsolicited = FALSE;
		while (tok != ')') {
			/* We expect this to be 'EARLIER' */
			tok = camel_imapx_input_stream_token (
				CAMEL_IMAPX_INPUT_STREAM (input_stream),
				&token, &len, cancellable, error);
			if (tok < 0)
				return FALSE;
		}
	} else {
		camel_imapx_input_stream_ungettoken (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			tok, token, len);
	}

	g_return_val_if_fail (is->priv->changes != NULL, FALSE);

	mailbox = camel_imapx_server_ref_pending_or_selected (is);
	g_return_val_if_fail (mailbox != NULL, FALSE);

	folder = imapx_server_ref_folder (is, mailbox);
	g_return_val_if_fail (folder != NULL, FALSE);

	geud.is = is;
	geud.summary = camel_folder_get_folder_summary (folder);
	geud.uid_list = NULL;
	geud.n_uids = 0;

	if (!imapx_parse_uids_with_callback (CAMEL_IMAPX_INPUT_STREAM (input_stream), imapx_gather_existing_uids_cb, &geud, cancellable, error)) {
		g_object_unref (folder);
		g_object_unref (mailbox);
		return FALSE;
	}

	/* It's locked by imapx_gather_existing_uids_cb() when the first known UID is found */
	if (geud.uid_list)
		g_mutex_unlock (&is->priv->changes_lock);

	if (unsolicited) {
		guint32 messages;

		messages = camel_imapx_mailbox_get_messages (mailbox);

		if (messages < geud.n_uids) {
			c (
				is->priv->tagprefix,
				"Error: mailbox messages (%u) is "
				"fewer than vanished %u\n",
				messages, geud.n_uids);
			messages = 0;
		} else {
			messages -= geud.n_uids;
		}

		camel_imapx_mailbox_set_messages (mailbox, messages);
	}

	if (geud.uid_list) {
		geud.uid_list = g_list_reverse (geud.uid_list);
		camel_folder_summary_remove_uids (geud.summary, geud.uid_list);
	}

	/* If the response is truly unsolicited (e.g. via NOTIFY)
	 * then go ahead and emit the change notification now. */
	COMMAND_LOCK (is);
	if (!is->priv->current_command) {
		COMMAND_UNLOCK (is);

		g_mutex_lock (&is->priv->changes_lock);
		if (is->priv->changes->uid_removed &&
		    is->priv->changes->uid_removed->len >= 100) {
			CamelFolderChangeInfo *changes;

			changes = is->priv->changes;
			is->priv->changes = camel_folder_change_info_new ();

			g_mutex_unlock (&is->priv->changes_lock);

			camel_folder_summary_save (geud.summary, NULL);
			imapx_update_store_summary (folder);

			camel_folder_changed (folder, changes);
			camel_folder_change_info_free (changes);
		} else {
			g_mutex_unlock (&is->priv->changes_lock);
		}
	} else {
		COMMAND_UNLOCK (is);
	}

	g_list_free_full (geud.uid_list, g_free);
	g_object_unref (folder);
	g_object_unref (mailbox);

	return TRUE;
}

static gboolean
imapx_untagged_namespace (CamelIMAPXServer *is,
                          GInputStream *input_stream,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelIMAPXNamespaceResponse *response;
	CamelIMAPXStore *imapx_store;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	response = camel_imapx_namespace_response_new (
		CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);

	if (response == NULL)
		return FALSE;

	imapx_store = camel_imapx_server_ref_store (is);
	camel_imapx_store_set_namespaces (imapx_store, response);

	g_clear_object (&imapx_store);
	g_object_unref (response);

	return TRUE;
}

static gboolean
imapx_untagged_exists (CamelIMAPXServer *is,
                       GInputStream *input_stream,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelIMAPXMailbox *mailbox;
	guint32 exists;
	gboolean success = TRUE, changed;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	mailbox = camel_imapx_server_ref_pending_or_selected (is);

	if (mailbox == NULL) {
		g_warning ("%s: No mailbox available", G_STRFUNC);
		return TRUE;
	}

	exists = (guint32) is->priv->context->id;

	c (is->priv->tagprefix, "%s: updating mailbox '%s' messages: %d ~> %d\n", G_STRFUNC,
		camel_imapx_mailbox_get_name (mailbox),
		camel_imapx_mailbox_get_messages (mailbox),
		exists);

	changed = camel_imapx_mailbox_get_messages (mailbox) != exists;
	camel_imapx_mailbox_set_messages (mailbox, exists);

	if (changed && camel_imapx_server_is_in_idle (is))
		g_signal_emit (is, signals[REFRESH_MAILBOX], 0, mailbox);

	g_object_unref (mailbox);

	return success;
}

static gboolean
imapx_untagged_flags (CamelIMAPXServer *is,
                      GInputStream *input_stream,
                      GCancellable *cancellable,
                      GError **error)
{
	guint32 flags = 0;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	success = imapx_parse_flags (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		&flags, NULL, cancellable, error);

	c (is->priv->tagprefix, "flags: %08x\n", flags);

	return success;
}

static gboolean
imapx_server_cinfo_has_attachment_cb (CamelMessageContentInfo *ci,
				      gint depth,
				      gpointer user_data)
{
	gboolean *pbool = user_data;

	g_return_val_if_fail (pbool != NULL, FALSE);

	*pbool = camel_content_disposition_is_attachment_ex (ci->disposition, ci->type, ci->parent ? ci->parent->type : NULL);

	return !*pbool;
}

static gboolean
imapx_untagged_fetch (CamelIMAPXServer *is,
                      GInputStream *input_stream,
                      GCancellable *cancellable,
                      GError **error)
{
	struct _fetch_info *finfo;
	gboolean got_body_header;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	finfo = imapx_parse_fetch (
		CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);
	if (finfo == NULL) {
		imapx_free_fetch (finfo);
		return FALSE;
	}

	/* Some IMAP servers respond with BODY[HEADER] when
	 * asked for RFC822.HEADER.  Treat them equivalently. */
	got_body_header =
		((finfo->got & FETCH_HEADER) == 0) &&
		(finfo->header == NULL) &&
		((finfo->got & FETCH_BODY) != 0) &&
		(g_strcmp0 (finfo->section, "HEADER") == 0);

	if (got_body_header) {
		finfo->got |= FETCH_HEADER;
		finfo->got &= ~FETCH_BODY;
		finfo->header = finfo->body;
		finfo->body = NULL;
	}

	if ((finfo->got & (FETCH_BODY | FETCH_UID)) == (FETCH_BODY | FETCH_UID)) {
		GOutputStream *output_stream;
		gconstpointer body_data;
		gsize body_size;

		if (!is->priv->get_message_stream) {
			g_warn_if_fail (is->priv->get_message_stream != NULL);
			imapx_free_fetch (finfo);
			return FALSE;
		}

		/* Fill out the body stream, in the right spot. */

		g_seekable_seek (
			G_SEEKABLE (is->priv->get_message_stream),
			finfo->offset, G_SEEK_SET,
			NULL, NULL);

		output_stream = g_io_stream_get_output_stream (is->priv->get_message_stream);

		body_data = g_bytes_get_data (finfo->body, &body_size);

		/* Sometimes the server, like Microsoft Exchange, reports larger message
		   size than it actually is, which results in no data being read from
		   the server for that particular offset. */
		if (body_size) {
			g_mutex_lock (&is->priv->stream_lock);
			if (!g_output_stream_write_all (
				output_stream, body_data, body_size,
				NULL, cancellable, error)) {
				g_mutex_unlock (&is->priv->stream_lock);
				g_prefix_error (
					error, "%s: ",
					_("Error writing to cache stream"));
				imapx_free_fetch (finfo);
				return FALSE;
			}
			g_mutex_unlock (&is->priv->stream_lock);
		}
	}

	if ((finfo->got & FETCH_FLAGS) && !(finfo->got & FETCH_HEADER)) {
		CamelIMAPXMailbox *select_mailbox;
		CamelIMAPXMailbox *select_pending;

		if (is->priv->fetch_changes_mailbox) {
			if (!is->priv->fetch_changes_mailbox ||
			    !is->priv->fetch_changes_folder ||
			    !is->priv->fetch_changes_infos) {
				g_warn_if_fail (is->priv->fetch_changes_mailbox != NULL);
				g_warn_if_fail (is->priv->fetch_changes_folder != NULL);
				g_warn_if_fail (is->priv->fetch_changes_infos != NULL);
				imapx_free_fetch (finfo);
				return FALSE;
			}
		}

		g_mutex_lock (&is->priv->select_lock);
		select_mailbox = g_weak_ref_get (&is->priv->select_mailbox);
		select_pending = g_weak_ref_get (&is->priv->select_pending);
		g_mutex_unlock (&is->priv->select_lock);

		/* This is either a refresh_info job, check to see if it is
		 * and update if so, otherwise it must've been an unsolicited
		 * response, so update the summary to match. */
		if ((finfo->got & FETCH_UID) != 0 && is->priv->fetch_changes_folder && is->priv->fetch_changes_infos) {
			FetchChangesInfo *nfo;
			gint64 monotonic_time;
			gint n_messages;

			nfo = g_hash_table_lookup (is->priv->fetch_changes_infos, finfo->uid);
			if (!nfo) {
				nfo = g_new0 (FetchChangesInfo, 1);

				g_hash_table_insert (is->priv->fetch_changes_infos, (gpointer) camel_pstring_strdup (finfo->uid), nfo);
			}

			nfo->server_flags = finfo->flags;
			nfo->server_user_flags = finfo->user_flags;
			finfo->user_flags = NULL;

			monotonic_time = g_get_monotonic_time ();
			n_messages = camel_imapx_mailbox_get_messages (is->priv->fetch_changes_mailbox);

			if (n_messages > 0 && is->priv->fetch_changes_last_progress + G_USEC_PER_SEC / 2 < monotonic_time &&
			    is->priv->context && is->priv->context->id <= n_messages) {
				COMMAND_LOCK (is);

				if (is->priv->current_command) {
					guint32 n_messages;

					COMMAND_UNLOCK (is);

					is->priv->fetch_changes_last_progress = monotonic_time;

					n_messages = camel_imapx_mailbox_get_messages (is->priv->fetch_changes_mailbox);
					if (n_messages > 0)
						camel_operation_progress (cancellable, 100 * is->priv->context->id / n_messages);
				} else {
					COMMAND_UNLOCK (is);
				}
			}
		} else if (select_mailbox != NULL) {
			CamelFolder *select_folder;
			CamelMessageInfo *mi = NULL;
			gboolean changed = FALSE;
			gchar *uid = NULL;

			c (is->priv->tagprefix, "flag changed: %lu\n", is->priv->context->id);

			if (select_pending)
				select_folder = imapx_server_ref_folder (is, select_pending);
			else
				select_folder = imapx_server_ref_folder (is, select_mailbox);
			if (!select_folder) {
				g_warn_if_fail (select_folder != NULL);

				g_clear_object (&select_mailbox);
				g_clear_object (&select_pending);
				imapx_free_fetch (finfo);

				return FALSE;
			}

			if (finfo->got & FETCH_UID) {
				uid = finfo->uid;
				finfo->uid = NULL;
			} else {
				uid = camel_imapx_dup_uid_from_summary_index (
					select_folder,
					is->priv->context->id - 1);
			}

			if (uid) {
				mi = camel_folder_summary_get (camel_folder_get_folder_summary (select_folder), uid);
				if (mi) {
					/* It's unsolicited _unless_ select_pending (i.e. during
					 * a QRESYNC SELECT */
					changed = imapx_update_message_info_flags (
						mi, finfo->flags,
						finfo->user_flags,
						camel_imapx_mailbox_get_permanentflags (select_mailbox),
						select_folder,
						(select_pending == NULL));
					c (is->priv->tagprefix, "found uid %s in '%s', changed:%d\n", uid,
						camel_folder_get_full_name (select_folder), changed);
				} else {
					/* This (UID + FLAGS for previously unknown message) might
					 * happen during a SELECT (QRESYNC). We should use it. */
					c (is->priv->tagprefix, "flags changed for unknown uid %s in '%s'\n", uid,
						camel_folder_get_full_name (select_folder));
				}
			}

			if (changed) {
				CamelIMAPXSummary *imapx_summary;

				imapx_summary = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (select_folder));

				if (imapx_summary && (finfo->got & FETCH_MODSEQ) != 0 &&
				    imapx_summary->modseq < finfo->modseq) {
					c (is->priv->tagprefix, "updating summary modseq %" G_GUINT64_FORMAT "~>%" G_GUINT64_FORMAT " in '%s'\n",
						imapx_summary->modseq, finfo->modseq, camel_folder_get_full_name (select_folder));
					imapx_summary->modseq = finfo->modseq;

					camel_folder_summary_touch (CAMEL_FOLDER_SUMMARY (imapx_summary));
				}

				g_mutex_lock (&is->priv->changes_lock);
				if (is->priv->changes)
					camel_folder_change_info_change_uid (is->priv->changes, uid);
				else
					g_warn_if_fail (is->priv->changes != NULL);
				g_mutex_unlock (&is->priv->changes_lock);
			}
			g_free (uid);

			if (changed && camel_imapx_server_is_in_idle (is)) {
				camel_folder_summary_save (camel_folder_get_folder_summary (select_folder), NULL);
				imapx_update_store_summary (select_folder);

				g_mutex_lock (&is->priv->changes_lock);

				camel_folder_changed (select_folder, is->priv->changes);
				camel_folder_change_info_clear (is->priv->changes);

				g_mutex_unlock (&is->priv->changes_lock);
			}

			g_clear_object (&mi);

			g_object_unref (select_folder);
		}

		g_clear_object (&select_mailbox);
		g_clear_object (&select_pending);
	}

	if ((finfo->got & (FETCH_HEADER | FETCH_UID)) == (FETCH_HEADER | FETCH_UID)) {
		CamelIMAPXMailbox *mailbox;
		CamelFolder *folder;
		CamelMimeParser *mp;
		CamelMessageInfo *mi;
		guint32 messages;
		guint32 unseen;
		guint32 uidnext;

		/* This must be a refresh info job as well, but it has
		 * asked for new messages to be added to the index. */

		if (is->priv->fetch_changes_mailbox) {
			if (!is->priv->fetch_changes_mailbox ||
			    !is->priv->fetch_changes_folder ||
			    !is->priv->fetch_changes_infos) {
				g_warn_if_fail (is->priv->fetch_changes_mailbox != NULL);
				g_warn_if_fail (is->priv->fetch_changes_folder != NULL);
				g_warn_if_fail (is->priv->fetch_changes_infos != NULL);
				imapx_free_fetch (finfo);
				return FALSE;
			}

			folder = g_object_ref (is->priv->fetch_changes_folder);
			mailbox = g_object_ref (is->priv->fetch_changes_mailbox);
		} else {
			mailbox = camel_imapx_server_ref_selected (is);
			folder = mailbox ? imapx_server_ref_folder (is, mailbox) : NULL;
		}

		if (!mailbox || !folder || (!(finfo->got & FETCH_FLAGS) && !is->priv->fetch_changes_infos)) {
			g_clear_object (&mailbox);
			g_clear_object (&folder);
			imapx_free_fetch (finfo);

			return TRUE;
		}

		messages = camel_imapx_mailbox_get_messages (mailbox);
		unseen = camel_imapx_mailbox_get_unseen (mailbox);
		uidnext = camel_imapx_mailbox_get_uidnext (mailbox);

		/* Do we want to save these headers for later too?  Do we care? */

		mp = camel_mime_parser_new ();
		camel_mime_parser_init_with_bytes (mp, finfo->header);
		mi = camel_folder_summary_info_new_from_parser (camel_folder_get_folder_summary (folder), mp);
		g_object_unref (mp);

		if (mi != NULL) {
			guint32 server_flags;
			CamelNamedFlags *server_user_flags;
			gboolean free_user_flags = FALSE;

			camel_message_info_set_abort_notifications (mi, TRUE);

			camel_message_info_set_uid (mi, finfo->uid);

			if ((finfo->got & FETCH_CINFO) && finfo->cinfo) {
				gboolean has_attachment = FALSE;

				camel_message_content_info_traverse (finfo->cinfo, imapx_server_cinfo_has_attachment_cb, &has_attachment);

				camel_message_info_set_flags (mi, CAMEL_MESSAGE_ATTACHMENTS, has_attachment ? CAMEL_MESSAGE_ATTACHMENTS : 0);
			}

			if (!(finfo->got & FETCH_FLAGS) && is->priv->fetch_changes_infos) {
				FetchChangesInfo *nfo;

				nfo = g_hash_table_lookup (is->priv->fetch_changes_infos, finfo->uid);
				if (!nfo) {
					g_warn_if_fail (nfo != NULL);

					camel_message_info_set_abort_notifications (mi, FALSE);
					g_clear_object (&mi);
					g_clear_object (&mailbox);
					g_clear_object (&folder);
					imapx_free_fetch (finfo);

					return FALSE;
				}

				server_flags = nfo->server_flags;
				server_user_flags = nfo->server_user_flags;
			} else {
				server_flags = finfo->flags;
				server_user_flags = finfo->user_flags;
				/* free user_flags ? */
				finfo->user_flags = NULL;
				free_user_flags = TRUE;
			}

			/* If the message is a really new one -- equal or higher than what
			 * we know as UIDNEXT for the folder, then it came in since we last
			 * fetched UIDNEXT and UNREAD count. We'll update UIDNEXT in the
			 * command completion, but update UNREAD count now according to the
			 * message SEEN flag */
			if (!(server_flags & CAMEL_MESSAGE_SEEN)) {
				guint64 uidl;

				uidl = strtoull (finfo->uid, NULL, 10);

				if (uidl >= uidnext) {
					c (is->priv->tagprefix, "Updating unseen count for new message %s\n", finfo->uid);
					camel_imapx_mailbox_set_unseen (mailbox, unseen + 1);
				} else {
					c (is->priv->tagprefix, "Not updating unseen count for new message %s\n", finfo->uid);
				}
			}

			camel_message_info_set_size (mi, finfo->size);
			camel_message_info_set_abort_notifications (mi, FALSE);

			camel_folder_summary_lock (camel_folder_get_folder_summary (folder));

			if (!camel_folder_summary_check_uid (camel_folder_get_folder_summary (folder), finfo->uid)) {
				imapx_set_message_info_flags_for_new_message (mi, server_flags, server_user_flags, FALSE, NULL, camel_imapx_mailbox_get_permanentflags (mailbox));
				camel_folder_summary_add (camel_folder_get_folder_summary (folder), mi, TRUE);

				g_mutex_lock (&is->priv->changes_lock);

				camel_folder_change_info_add_uid (is->priv->changes, finfo->uid);
				camel_folder_change_info_recent_uid (is->priv->changes, finfo->uid);

				g_mutex_unlock (&is->priv->changes_lock);

				if (messages > 0) {
					gint cnt = (camel_folder_summary_count (camel_folder_get_folder_summary (folder)) * 100) / messages;

					camel_operation_progress (cancellable, cnt ? cnt : 1);
				}

				if (camel_imapx_server_is_in_idle (is) && !camel_folder_is_frozen (folder))
					camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);
			}

			g_clear_object (&mi);
			camel_folder_summary_unlock (camel_folder_get_folder_summary (folder));

			if (free_user_flags)
				camel_named_flags_free (server_user_flags);

			if (camel_imapx_server_is_in_idle (is) && !camel_folder_is_frozen (folder)) {
				CamelFolderChangeInfo *changes = NULL;

				g_mutex_lock (&is->priv->changes_lock);

				if (camel_folder_change_info_changed (is->priv->changes)) {
					changes = is->priv->changes;
					is->priv->changes = camel_folder_change_info_new ();
				}

				g_mutex_unlock (&is->priv->changes_lock);

				if (changes) {
					imapx_update_store_summary (folder);
					camel_folder_changed (folder, changes);

					camel_folder_change_info_free (changes);
				}
			}
		}

		g_clear_object (&mailbox);
		g_clear_object (&folder);
	}

	imapx_free_fetch (finfo);

	return TRUE;
}

static gboolean
imapx_untagged_lsub (CamelIMAPXServer *is,
                     GInputStream *input_stream,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelIMAPXListResponse *response;
	const gchar *mailbox_name;
	gchar separator;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	/* LSUB response is syntactically compatible with LIST response. */
	response = camel_imapx_list_response_new (
		CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);
	if (response == NULL)
		return FALSE;

	camel_imapx_list_response_add_attribute (
		response, CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED);

	mailbox_name = camel_imapx_list_response_get_mailbox_name (response);
	separator = camel_imapx_list_response_get_separator (response);

	/* Record the INBOX separator character once we know it. */
	if (camel_imapx_mailbox_is_inbox (mailbox_name))
		is->priv->inbox_separator = separator;

	if (is->priv->list_responses_hash) {
		CamelIMAPXListResponse *list_response;

		is->priv->lsub_responses = g_slist_prepend (is->priv->lsub_responses, response);

		list_response = g_hash_table_lookup (is->priv->list_responses_hash, camel_imapx_list_response_get_mailbox_name (response));
		if (list_response)
			camel_imapx_list_response_add_attribute (list_response, CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED);
	} else {
		CamelIMAPXStore *imapx_store;

		imapx_store = camel_imapx_server_ref_store (is);
		camel_imapx_store_handle_lsub_response (imapx_store, is, response);

		g_clear_object (&imapx_store);
		g_clear_object (&response);
	}

	return TRUE;
}

static gboolean
imapx_untagged_list (CamelIMAPXServer *is,
                     GInputStream *input_stream,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelIMAPXListResponse *response;
	const gchar *mailbox_name;
	gchar separator;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	response = camel_imapx_list_response_new (
		CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);
	if (response == NULL)
		return FALSE;

	mailbox_name = camel_imapx_list_response_get_mailbox_name (response);
	separator = camel_imapx_list_response_get_separator (response);

	/* Record the INBOX separator character once we know it. */
	if (camel_imapx_mailbox_is_inbox (mailbox_name))
		is->priv->inbox_separator = separator;

	if (is->priv->list_responses_hash) {
		is->priv->list_responses = g_slist_prepend (is->priv->list_responses, response);
		g_hash_table_insert (is->priv->list_responses_hash, (gpointer) camel_imapx_list_response_get_mailbox_name (response), response);
	} else {
		CamelIMAPXStore *imapx_store;

		imapx_store = camel_imapx_server_ref_store (is);
		camel_imapx_store_handle_list_response (imapx_store, is, response);

		g_clear_object (&imapx_store);
		g_clear_object (&response);
	}

	return TRUE;
}

static gboolean
imapx_untagged_quota (CamelIMAPXServer *is,
                      GInputStream *input_stream,
                      GCancellable *cancellable,
                      GError **error)
{
	gchar *quota_root_name = NULL;
	CamelFolderQuotaInfo *quota_info = NULL;
	gboolean success;

	success = camel_imapx_parse_quota (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		cancellable, &quota_root_name, &quota_info, error);

	/* Sanity check */
	g_return_val_if_fail (
		(success && (quota_root_name != NULL)) ||
		(!success && (quota_root_name == NULL)), FALSE);

	if (success) {
		CamelIMAPXStore *store;

		store = camel_imapx_server_ref_store (is);
		camel_imapx_store_set_quota_info (
			store, quota_root_name, quota_info);
		g_object_unref (store);

		g_free (quota_root_name);
		camel_folder_quota_info_free (quota_info);
	}

	return success;
}

static gboolean
imapx_untagged_quotaroot (CamelIMAPXServer *is,
                          GInputStream *input_stream,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelIMAPXStore *imapx_store;
	CamelIMAPXMailbox *mailbox;
	gchar *mailbox_name = NULL;
	gchar **quota_roots = NULL;
	gboolean success;

	success = camel_imapx_parse_quotaroot (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		cancellable, &mailbox_name, &quota_roots, error);

	/* Sanity check */
	g_return_val_if_fail (
		(success && (mailbox_name != NULL)) ||
		(!success && (mailbox_name == NULL)), FALSE);

	if (!success)
		return FALSE;

	imapx_store = camel_imapx_server_ref_store (is);
	mailbox = camel_imapx_store_ref_mailbox (imapx_store, mailbox_name);
	g_clear_object (&imapx_store);

	if (mailbox != NULL) {
		camel_imapx_mailbox_set_quota_roots (
			mailbox, (const gchar **) quota_roots);
		g_object_unref (mailbox);
	} else {
		g_warning (
			"%s: Unknown mailbox '%s'",
			G_STRFUNC, mailbox_name);
	}

	g_free (mailbox_name);
	g_strfreev (quota_roots);

	return TRUE;
}

static gboolean
imapx_untagged_recent (CamelIMAPXServer *is,
                       GInputStream *input_stream,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelIMAPXMailbox *mailbox;
	guint32 recent;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	mailbox = camel_imapx_server_ref_pending_or_selected (is);

	if (mailbox == NULL) {
		g_warning ("%s: No mailbox available", G_STRFUNC);
		return TRUE;
	}

	recent = (guint32) is->priv->context->id;

	c (is->priv->tagprefix, "%s: updating mailbox '%s' recent: %d ~> %d\n", G_STRFUNC,
		camel_imapx_mailbox_get_name (mailbox),
		camel_imapx_mailbox_get_recent (mailbox),
		recent);

	camel_imapx_mailbox_set_recent (mailbox, recent);

	g_object_unref (mailbox);

	return TRUE;
}

static gboolean
imapx_untagged_search (CamelIMAPXServer *is,
                       GInputStream *input_stream,
                       GCancellable *cancellable,
                       GError **error)
{
	GArray *search_results;
	gint tok;
	guint len;
	guchar *token;
	guint64 number;
	gboolean success = FALSE;

	search_results = g_array_new (FALSE, FALSE, sizeof (guint64));

	while (TRUE) {
		gboolean success;

		/* Peek at the next token, and break
		 * out of the loop if we get a newline. */
		tok = camel_imapx_input_stream_token (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			&token, &len, cancellable, error);
		if (tok == '\n')
			break;
		if (tok == IMAPX_TOK_ERROR)
			goto exit;
		camel_imapx_input_stream_ungettoken (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			tok, token, len);

		success = camel_imapx_input_stream_number (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			&number, cancellable, error);

		if (!success)
			goto exit;

		g_array_append_val (search_results, number);
	}

	g_mutex_lock (&is->priv->search_results_lock);

	if (is->priv->search_results == NULL)
		is->priv->search_results = g_array_ref (search_results);
	else
		g_warning ("%s: Conflicting search results", G_STRFUNC);

	g_mutex_unlock (&is->priv->search_results_lock);

	success = TRUE;

exit:
	g_array_unref (search_results);

	return success;
}

static gboolean
imapx_can_refresh_mailbox_in_idle (CamelIMAPXServer *imapx_server,
				   CamelIMAPXStore *imapx_store,
				   CamelIMAPXMailbox *mailbox)
{
	CamelIMAPXSettings *imapx_settings;
	gboolean can_refresh = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (imapx_server), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	if (camel_imapx_mailbox_is_inbox (camel_imapx_mailbox_get_name (mailbox)))
		return TRUE;

	imapx_settings = camel_imapx_server_ref_settings (imapx_server);

	if (camel_imapx_settings_get_use_subscriptions (imapx_settings)) {
		can_refresh = camel_imapx_mailbox_has_attribute (mailbox, CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED);
	} else if (camel_imapx_settings_get_check_all (imapx_settings)) {
		can_refresh = TRUE;
	} else if (camel_imapx_settings_get_check_subscribed (imapx_settings)) {
		can_refresh = camel_imapx_mailbox_has_attribute (mailbox, CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED);
	}

	if (!can_refresh &&
	    !camel_imapx_settings_get_use_subscriptions (imapx_settings)) {
		/* Refresh opened folders when viewing both subscribed and unsubscribed,
		   even if they would not be refreshed otherwise. */
		gchar *folder_path;

		can_refresh = FALSE;

		folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);
		if (folder_path) {
			GPtrArray *opened_folders = camel_store_dup_opened_folders (CAMEL_STORE (imapx_store));

			if (opened_folders) {
				gint ii;

				for (ii = 0; !can_refresh && ii < opened_folders->len; ii++) {
					CamelFolder *folder = g_ptr_array_index (opened_folders, ii);

					can_refresh = g_strcmp0 (camel_folder_get_full_name (folder), folder_path) == 0;
				}

				g_ptr_array_foreach (opened_folders, (GFunc) g_object_unref, NULL);
				g_ptr_array_free (opened_folders, TRUE);
			}
		}

		g_free (folder_path);
	}

	g_clear_object (&imapx_settings);

	return can_refresh;
}

static gboolean
imapx_untagged_status (CamelIMAPXServer *is,
                       GInputStream *input_stream,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelIMAPXStatusResponse *response;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXMailbox *mailbox;
	const gchar *mailbox_name;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	response = camel_imapx_status_response_new (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		is->priv->inbox_separator, cancellable, error);
	if (response == NULL)
		return FALSE;

	mailbox_name = camel_imapx_status_response_get_mailbox_name (response);

	imapx_store = camel_imapx_server_ref_store (is);
	mailbox = camel_imapx_store_ref_mailbox (imapx_store, mailbox_name);

	if (mailbox != NULL) {
		camel_imapx_mailbox_handle_status_response (mailbox, response);
		camel_imapx_store_emit_mailbox_updated (imapx_store, mailbox);

		if (camel_imapx_server_is_in_idle (is) &&
		    imapx_can_refresh_mailbox_in_idle (is, imapx_store, mailbox))
			g_signal_emit (is, signals[REFRESH_MAILBOX], 0, mailbox);

		g_object_unref (mailbox);
	}

	g_clear_object (&imapx_store);
	g_object_unref (response);

	return TRUE;
}

static gboolean
imapx_untagged_bye (CamelIMAPXServer *is,
                    GInputStream *input_stream,
                    GCancellable *cancellable,
                    GError **error)
{
	guchar *token = NULL;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	success = camel_imapx_input_stream_text (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		&token, cancellable, error);

	/* XXX It's weird to be setting an error on success,
	 *     but it's to indicate the server hung up on us. */
	if (success) {
		g_strstrip ((gchar *) token);

		c (is->priv->tagprefix, "BYE: %s\n", token);
		g_set_error (
			error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
			"IMAP server said BYE: %s", token);
	}

	g_free (token);

	is->priv->state = IMAPX_SHUTDOWN;

	return FALSE;
}

static gboolean
imapx_untagged_preauth (CamelIMAPXServer *is,
                        GInputStream *input_stream,
                        GCancellable *cancellable,
                        GError **error)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	c (is->priv->tagprefix, "preauthenticated\n");
	if (is->priv->state < IMAPX_AUTHENTICATED)
		is->priv->state = IMAPX_AUTHENTICATED;

	return TRUE;
}

static gboolean
imapx_server_check_is_broken_cyrus (const gchar *response_text,
				    gboolean *inout_is_cyrus)
{
	const gchar *pp, *from;
	gint vermajor = 0, verminor = 0, vermicro = 0;

	g_return_val_if_fail (inout_is_cyrus != NULL, FALSE);

	/* If already known that this is cyrus server, then it had been
	   identified as a good server, thus just return here. */
	if (*inout_is_cyrus)
		return FALSE;

	if (!response_text || !*response_text)
		return FALSE;

	/* Expects "Cyrus IMAP v1.2.3", eventually "Cyrus IMAP 4.5.6" (with or without 'v' prefix) */
	pp = response_text;
	while (pp = camel_strstrcase (pp, "cyrus"), pp) {
		/* It's a whole word */
		if ((pp == response_text || g_ascii_isspace (pp[-1])) && g_ascii_isspace (pp[5]))
			break;
		pp++;
	}

	if (!pp)
		return FALSE;

	from = pp;

	/* In case there is the 'cyrus' word multiple times */
	while (pp = from, pp && *pp) {
		#define skip_word() \
			while (*pp && *pp != ' ') {	\
				pp++;			\
			}				\
							\
			if (!*pp)			\
				return TRUE;		\
							\
			pp++;

		/* Skip the 'Cyrus' word */
		skip_word ();

		/* Skip the 'IMAP' word */
		skip_word ();

		#undef skip_word

		/* Now is at version with or without 'v' prefix */
		if (*pp == 'v')
			pp++;

		if (sscanf (pp, "%d.%d.%d", &vermajor, &verminor, &vermicro) == 3) {
			*inout_is_cyrus = TRUE;
			break;
		}

		vermajor = 0;

		pp = from + 1;
		from = NULL;

		while (pp = camel_strstrcase (pp, "cyrus"), pp) {
			/* It's a whole word */
			if (g_ascii_isspace (pp[-1]) && g_ascii_isspace (pp[5])) {
				from = pp;
				break;
			}

			pp++;
		}
	}

	/* The 2.5.11, inclusive, has the issue fixed, thus check for that version. */
	return !(vermajor > 2 || (vermajor == 2 && (verminor > 5 || (verminor == 5 && vermicro >= 11))));
}

static gboolean
imapx_untagged_ok_no_bad (CamelIMAPXServer *is,
                          GInputStream *input_stream,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelIMAPXMailbox *mailbox;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	/* TODO: validate which ones of these can happen as unsolicited responses */
	/* TODO: handle bye/preauth differently */
	camel_imapx_input_stream_ungettoken (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		is->priv->context->tok,
		is->priv->context->token,
		is->priv->context->len);

	/* These untagged responses can belong to ongoing SELECT command, thus
	   to the pending select mailbox, not to the currently selected or closing
	   mailbox, thus prefer the select pending mailbox, from the other two.
	   This makes sure that for example UIDVALIDITY is not incorrectly
	   overwritten with a value from a different mailbox, thus the offline
	   cache will persist, instead of being vanished.
	*/
	mailbox = camel_imapx_server_ref_pending_or_selected (is);

	is->priv->context->sinfo = imapx_parse_status (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		mailbox, TRUE, cancellable, error);

	g_clear_object (&mailbox);

	if (is->priv->context->sinfo == NULL)
		return FALSE;

	switch (is->priv->context->sinfo->condition) {
	case IMAPX_CLOSED:
		c (
			is->priv->tagprefix,
			"previously selected mailbox is now closed\n");
		{
			CamelIMAPXMailbox *select_mailbox;
			CamelIMAPXMailbox *select_pending;

			g_mutex_lock (&is->priv->select_lock);

			select_mailbox = g_weak_ref_get (&is->priv->select_mailbox);
			select_pending = g_weak_ref_get (&is->priv->select_pending);

			if (select_mailbox == NULL) {
				g_weak_ref_set (&is->priv->select_mailbox, select_pending);

				if (select_pending)
					is->priv->last_selected_mailbox_change_stamp = camel_imapx_mailbox_get_change_stamp (select_pending);
				else
					is->priv->last_selected_mailbox_change_stamp = 0;
			}

			g_mutex_unlock (&is->priv->select_lock);

			g_clear_object (&select_mailbox);
			g_clear_object (&select_pending);
		}
		break;
	case IMAPX_ALERT:
		c (is->priv->tagprefix, "ALERT!: %s\n", is->priv->context->sinfo->text);
		{
			const gchar *alert_message;
			gboolean emit_alert = FALSE;

			g_mutex_lock (&is->priv->known_alerts_lock);

			alert_message = is->priv->context->sinfo->text;

			if (alert_message != NULL) {
				emit_alert = !g_hash_table_contains (
					is->priv->known_alerts,
					alert_message);
			}

			if (emit_alert) {
				CamelIMAPXStore *store;
				CamelService *service;
				CamelSession *session;

				store = camel_imapx_server_ref_store (is);

				g_hash_table_add (
					is->priv->known_alerts,
					g_strdup (alert_message));

				service = CAMEL_SERVICE (store);
				session = camel_service_ref_session (service);

				if (session) {
					camel_session_user_alert (
						session, service,
						CAMEL_SESSION_ALERT_WARNING,
						alert_message);

					g_object_unref (session);
				}

				g_object_unref (store);
			}

			g_mutex_unlock (&is->priv->known_alerts_lock);
		}
		break;
	case IMAPX_PARSE:
		c (is->priv->tagprefix, "PARSE: %s\n", is->priv->context->sinfo->text);
		break;
	case IMAPX_CAPABILITY:
		if (is->priv->context->sinfo->u.cinfo) {
			struct _capability_info *cinfo;

			g_mutex_lock (&is->priv->stream_lock);

			cinfo = is->priv->cinfo;
			is->priv->cinfo = is->priv->context->sinfo->u.cinfo;
			is->priv->context->sinfo->u.cinfo = NULL;
			if (cinfo)
				imapx_free_capability (cinfo);
			c (is->priv->tagprefix, "got capability flags %08x\n", is->priv->cinfo ? is->priv->cinfo->capa : 0xFFFFFFFF);

			if (is->priv->context->sinfo->text) {
				guint32 list_extended = imapx_lookup_capability ("LIST-EXTENDED");

				is->priv->is_broken_cyrus = is->priv->is_broken_cyrus || imapx_server_check_is_broken_cyrus (is->priv->context->sinfo->text, &is->priv->is_cyrus);
				if (is->priv->is_broken_cyrus && is->priv->cinfo && (is->priv->cinfo->capa & list_extended) != 0) {
					/* Disable LIST-EXTENDED for cyrus servers */
					c (is->priv->tagprefix, "Disabling LIST-EXTENDED extension for a Cyrus server\n");
					is->priv->cinfo->capa &= ~list_extended;
				}
			}

			imapx_server_stash_command_arguments (is);

			g_mutex_unlock (&is->priv->stream_lock);
		}
		break;
	case IMAPX_COPYUID:
		imapx_free_status (is->priv->copyuid_status);
		is->priv->copyuid_status = is->priv->context->sinfo;
		is->priv->context->sinfo = NULL;
		break;
	default:
		break;
	}

	imapx_free_status (is->priv->context->sinfo);
	is->priv->context->sinfo = NULL;

	return TRUE;
}

/* handle any untagged responses */
static gboolean
imapx_untagged (CamelIMAPXServer *is,
                GInputStream *input_stream,
                GCancellable *cancellable,
                GError **error)
{
	CamelIMAPXSettings *settings;
	CamelSortType fetch_order;
	guchar *p = NULL, c;
	const gchar *token = NULL;
	gboolean success = FALSE;

	/* If is->priv->context is not NULL here, it basically means
	 * that imapx_untagged() got called concurrently for the same
	 * CamelIMAPXServer instance. Should this ever happen, then
	 * we will need to protect this data structure with locks
	 */
	g_return_val_if_fail (is->priv->context == NULL, FALSE);
	is->priv->context = g_new0 (CamelIMAPXServerUntaggedContext, 1);

	settings = camel_imapx_server_ref_settings (is);
	fetch_order = camel_imapx_settings_get_fetch_order (settings);
	g_object_unref (settings);

	is->priv->context->lsub = FALSE;
	is->priv->context->fetch_order = fetch_order;

	e (is->priv->tagprefix, "got untagged response\n");
	is->priv->context->id = 0;
	is->priv->context->tok = camel_imapx_input_stream_token (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		&(is->priv->context->token),
		&(is->priv->context->len),
		cancellable, error);
	if (is->priv->context->tok < 0)
		goto exit;

	if (is->priv->context->tok == IMAPX_TOK_INT) {
		is->priv->context->id = strtoul (
			(gchar *) is->priv->context->token, NULL, 10);
		is->priv->context->tok = camel_imapx_input_stream_token (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			&(is->priv->context->token),
			&(is->priv->context->len),
			cancellable, error);
		if (is->priv->context->tok < 0)
			goto exit;
	}

	if (is->priv->context->tok == '\n') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"truncated server response");
		goto exit;
	}

	e (is->priv->tagprefix, "Have token '%s' id %lu\n", is->priv->context->token, is->priv->context->id);
	p = is->priv->context->token;
	while (p && *p) {
		c = *p;
		*p++ = g_ascii_toupper ((gchar) c);
	}

	token = (const gchar *) is->priv->context->token; /* FIXME need 'guchar *token' here */
	while (token != NULL) {
		CamelIMAPXUntaggedRespHandlerDesc *desc = NULL;

		desc = g_hash_table_lookup (is->priv->untagged_handlers, token);
		if (desc == NULL) {
			/* unknown response, just ignore it */
			c (is->priv->tagprefix, "unknown token: %s\n", is->priv->context->token);
			break;
		}
		if (desc->handler == NULL) {
			/* no handler function, ignore token */
			c (is->priv->tagprefix, "no handler for token: %s\n", is->priv->context->token);
			break;
		}

		/* call the handler function */
		success = desc->handler (is, input_stream, cancellable, error);
		if (!success)
			goto exit;

		/* is there another handler next-in-line? */
		token = desc->next_response;
		if (token != NULL) {
			/* TODO do we need to update 'priv->context->token'
			 *      to the value of 'token' here, before
			 *      calling the handler next-in-line for this
			 *      specific run of imapx_untagged()?
			 *      It has not been done in the original code
			 *      in the "fall through" situation in the
			 *      token switch statement, which is what
			 *      we're mimicking here
			 */
			continue;
		}

		if (!desc->skip_stream_when_done)
			goto exit;
	}

	success = camel_imapx_input_stream_skip (
		CAMEL_IMAPX_INPUT_STREAM (input_stream), cancellable, error);

exit:
	g_free (is->priv->context);
	is->priv->context = NULL;

	return success;
}

/* handle any continuation requests
 * either data continuations, or auth continuation */
static gboolean
imapx_continuation (CamelIMAPXServer *is,
                    GInputStream *input_stream,
                    GOutputStream *output_stream,
                    gboolean litplus,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelIMAPXCommand *ic, *newic = NULL;
	CamelIMAPXCommandPart *cp;
	GList *link;
	gssize n_bytes_written;
	gboolean success;

	/* The 'literal' pointer is like a write-lock, nothing else
	 * can write while we have it ... so we dont need any
	 * ohter lock here.  All other writes go through
	 * queue-lock */
	if (camel_imapx_server_is_in_idle (is)) {
		success = camel_imapx_input_stream_skip (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			cancellable, error);

		if (!success)
			return FALSE;

		c (is->priv->tagprefix, "Got continuation response for IDLE \n");

		g_mutex_lock (&is->priv->idle_lock);
		is->priv->idle_state = IMAPX_IDLE_STATE_RUNNING;
		g_cond_broadcast (&is->priv->idle_cond);
		g_mutex_unlock (&is->priv->idle_lock);

		return TRUE;
	}

	ic = is->priv->continuation_command;
	if (!litplus) {
		if (ic == NULL) {
			c (is->priv->tagprefix, "got continuation response with no outstanding continuation requests?\n");
			return camel_imapx_input_stream_skip (
				CAMEL_IMAPX_INPUT_STREAM (input_stream),
				cancellable, error);
		}
		c (is->priv->tagprefix, "got continuation response for data\n");
	} else {
		c (is->priv->tagprefix, "sending LITERAL+ continuation\n");
		g_return_val_if_fail (ic != NULL, FALSE);
	}

	/* coverity[deadcode] */
	link = ic ? ic->current_part : NULL;
	if (!link) {
		g_warn_if_fail (link != NULL);
		return FALSE;
	}

	cp = (CamelIMAPXCommandPart *) link->data;

	switch (cp->type & CAMEL_IMAPX_COMMAND_MASK) {
	case CAMEL_IMAPX_COMMAND_DATAWRAPPER:
		c (is->priv->tagprefix, "writing data wrapper to literal\n");
		n_bytes_written =
			camel_data_wrapper_write_to_output_stream_sync (
				CAMEL_DATA_WRAPPER (cp->ob),
				output_stream, cancellable, error);
		if (n_bytes_written < 0)
			return FALSE;
		break;
	case CAMEL_IMAPX_COMMAND_AUTH: {
		gchar *resp;
		guchar *token;

		success = camel_imapx_input_stream_text (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			&token, cancellable, error);

		if (!success)
			return FALSE;

		resp = camel_sasl_challenge_base64_sync (
			(CamelSasl *) cp->ob, (const gchar *) token,
			cancellable, error);
		g_free (token);
		if (resp == NULL)
			return FALSE;
		c (is->priv->tagprefix, "got auth continuation, feeding token '%s' back to auth mech\n", resp);

		g_mutex_lock (&is->priv->stream_lock);
		n_bytes_written = g_output_stream_write_all (
			output_stream, resp, strlen (resp),
			NULL, cancellable, error);
		g_mutex_unlock (&is->priv->stream_lock);
		g_free (resp);

		if (n_bytes_written < 0)
			return FALSE;

		/* we want to keep getting called until we get a status reponse from the server
		 * ignore what sasl tells us */
		newic = ic;
		/* We already ate the end of the input stream line */
		goto noskip;
		break; }
	case CAMEL_IMAPX_COMMAND_FILE: {
		GFile *file;
		GFileInfo *file_info;
		GFileInputStream *file_input_stream;
		goffset file_size = 0;

		c (is->priv->tagprefix, "writing file '%s' to literal\n", (gchar *) cp->ob);

		file = g_file_new_for_path (cp->ob);
		file_input_stream = g_file_read (file, cancellable, error);
		g_object_unref (file);

		if (file_input_stream == NULL)
			return FALSE;

		file_info = g_file_input_stream_query_info (file_input_stream,
			G_FILE_ATTRIBUTE_STANDARD_SIZE, cancellable, NULL);
		if (file_info) {
			file_size = g_file_info_get_size (file_info);
			g_object_unref (file_info);
		}

		g_mutex_lock (&is->priv->stream_lock);

		n_bytes_written = imapx_splice_with_progress (
			output_stream, G_INPUT_STREAM (file_input_stream),
			file_size, cancellable, error);

		g_mutex_unlock (&is->priv->stream_lock);

		g_input_stream_close (G_INPUT_STREAM (file_input_stream), cancellable, NULL);
		g_object_unref (file_input_stream);

		if (n_bytes_written < 0)
			return FALSE;

		break; }
	case CAMEL_IMAPX_COMMAND_STRING:
		g_mutex_lock (&is->priv->stream_lock);
		n_bytes_written = g_output_stream_write_all (
			output_stream, cp->ob, cp->ob_size,
			NULL, cancellable, error);
		g_mutex_unlock (&is->priv->stream_lock);
		if (n_bytes_written < 0)
			return FALSE;
		break;
	default:
		/* should we just ignore? */
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"continuation response for non-continuation request");
		return FALSE;
	}

	if (ic->job_kind == CAMEL_IMAPX_JOB_APPEND_MESSAGE && !cp->ends_with_crlf) {
		g_mutex_lock (&is->priv->stream_lock);
		n_bytes_written = g_output_stream_write_all (
			output_stream, "\r\n", 2, NULL, cancellable, error);
		g_mutex_unlock (&is->priv->stream_lock);
		if (n_bytes_written < 0)
			return FALSE;
	}

	if (!litplus) {
		success = camel_imapx_input_stream_skip (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			cancellable, error);

		if (!success)
			return FALSE;
	}

noskip:
	link = g_list_next (link);
	if (link != NULL) {
		ic->current_part = link;
		cp = (CamelIMAPXCommandPart *) link->data;

		c (is->priv->tagprefix, "next part of command \"%c%05u: %s\"\n", is->priv->tagprefix, ic->tag, cp->data);

		g_mutex_lock (&is->priv->stream_lock);
		n_bytes_written = g_output_stream_write_all (
			output_stream, cp->data, strlen (cp->data),
			NULL, cancellable, error);
		g_mutex_unlock (&is->priv->stream_lock);
		if (n_bytes_written < 0)
			return FALSE;

		if (cp->type & (CAMEL_IMAPX_COMMAND_CONTINUATION | CAMEL_IMAPX_COMMAND_LITERAL_PLUS)) {
			newic = ic;
		} else {
			g_warn_if_fail (g_list_next (link) == NULL);
		}
	} else {
		c (is->priv->tagprefix, "%p: queueing continuation\n", ic);
	}

	g_mutex_lock (&is->priv->stream_lock);
	n_bytes_written = g_output_stream_write_all (
		output_stream, "\r\n", 2, NULL, cancellable, error);
	g_mutex_unlock (&is->priv->stream_lock);
	if (n_bytes_written < 0)
		return FALSE;

	is->priv->continuation_command = newic;

	return TRUE;
}

/* handle a completion line */
static gboolean
imapx_completion (CamelIMAPXServer *is,
                  GInputStream *input_stream,
                  guchar *token,
                  gint len,
                  GCancellable *cancellable,
                  GError **error)
{
	CamelIMAPXCommand *ic;
	CamelIMAPXMailbox *mailbox;
	gboolean success = FALSE;
	guint tag;

	/* Given "A0001 ...", 'A' = tag prefix, '0001' = tag. */

	if (token[0] != is->priv->tagprefix) {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"Server sent unexpected response: %s", token);
		return FALSE;
	}

	tag = strtoul ((gchar *) token + 1, NULL, 10);

	COMMAND_LOCK (is);

	if (is->priv->current_command != NULL && is->priv->current_command->tag == tag)
		ic = camel_imapx_command_ref (is->priv->current_command);
	else
		ic = NULL;

	COMMAND_UNLOCK (is);

	if (ic == NULL) {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"got response tag unexpectedly: %s", token);
		return FALSE;
	}

	c (is->priv->tagprefix, "Got completion response for command %05u '%s'\n", ic->tag, camel_imapx_job_get_kind_name (ic->job_kind));

	/* The camel_imapx_server_refresh_info_sync() gets any piled change
	   notifications and will emit the signal with all of them at once.
	   Similarly message COPY/MOVE command. */
	if (!is->priv->fetch_changes_mailbox && !is->priv->fetch_changes_folder && !is->priv->fetch_changes_infos &&
	    ic->job_kind != CAMEL_IMAPX_JOB_COPY_MESSAGE && ic->job_kind != CAMEL_IMAPX_JOB_MOVE_MESSAGE) {
		g_mutex_lock (&is->priv->changes_lock);

		if (camel_folder_change_info_changed (is->priv->changes)) {
			CamelFolder *folder = NULL;
			CamelIMAPXMailbox *mailbox;
			CamelFolderChangeInfo *changes;

			changes = is->priv->changes;
			is->priv->changes = camel_folder_change_info_new ();

			g_mutex_unlock (&is->priv->changes_lock);

			mailbox = camel_imapx_server_ref_pending_or_selected (is);

			g_warn_if_fail (mailbox != NULL);

			if (mailbox) {
				folder = imapx_server_ref_folder (is, mailbox);
				g_return_val_if_fail (folder != NULL, FALSE);

				camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);

				imapx_update_store_summary (folder);
				camel_folder_changed (folder, changes);
			}

			camel_folder_change_info_free (changes);

			g_clear_object (&folder);
			g_clear_object (&mailbox);
		} else {
			g_mutex_unlock (&is->priv->changes_lock);
		}
	}

	if (g_list_next (ic->current_part) != NULL) {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"command still has unsent parts? %s", camel_imapx_job_get_kind_name (ic->job_kind));
		goto exit;
	}

	mailbox = camel_imapx_server_ref_selected (is);

	ic->status = imapx_parse_status (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		mailbox, FALSE, cancellable, error);

	g_clear_object (&mailbox);

	if (ic->status == NULL)
		goto exit;

	if (ic->status->condition == IMAPX_CAPABILITY) {
		guint32 list_extended = imapx_lookup_capability ("LIST-EXTENDED");

		is->priv->is_broken_cyrus = is->priv->is_broken_cyrus || (ic->status->text && imapx_server_check_is_broken_cyrus (ic->status->text, &is->priv->is_cyrus));
		if (is->priv->is_broken_cyrus && ic->status->u.cinfo && (ic->status->u.cinfo->capa & list_extended) != 0) {
			/* Disable LIST-EXTENDED for cyrus servers */
			c (is->priv->tagprefix, "Disabling LIST-EXTENDED extension for a Cyrus server\n");
			ic->status->u.cinfo->capa &= ~list_extended;
		}
	}

	success = TRUE;

exit:

	ic->completed = TRUE;
	camel_imapx_command_unref (ic);

	return success;
}

static gboolean
imapx_step (CamelIMAPXServer *is,
            GInputStream *input_stream,
	    GOutputStream *output_stream,
            GCancellable *cancellable,
            GError **error)
{
	guint len;
	guchar *token;
	gint tok;
	gboolean success = FALSE;

	tok = camel_imapx_input_stream_token (
		CAMEL_IMAPX_INPUT_STREAM (input_stream),
		&token, &len, cancellable, error);

	switch (tok) {
		case IMAPX_TOK_ERROR:
			/* GError is already set. */
			break;
		case '*':
			success = imapx_untagged (
				is, input_stream, cancellable, error);
			break;
		case IMAPX_TOK_TOKEN:
			success = imapx_completion (
				is, input_stream,
				token, len, cancellable, error);
			break;
		case '+':
			success = imapx_continuation (
				is, input_stream, output_stream,
				FALSE, cancellable, error);
			break;
		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"unexpected server response:");
			break;
	}

	return success;
}

static void
imapx_server_set_streams (CamelIMAPXServer *is,
                          GInputStream *input_stream,
                          GOutputStream *output_stream)
{
	GConverter *logger;

	if (input_stream != NULL) {
		GInputStream *temp_stream;

		/* The logger produces debugging output. */
		logger = camel_imapx_logger_new (is->priv->tagprefix);
		input_stream = g_converter_input_stream_new (
			input_stream, logger);
		g_clear_object (&logger);

		/* Buffer the input stream for parsing. */
		temp_stream = camel_imapx_input_stream_new (input_stream);
		camel_binding_bind_property (
			temp_stream, "close-base-stream",
			input_stream, "close-base-stream",
			G_BINDING_SYNC_CREATE);
		g_object_unref (input_stream);
		input_stream = temp_stream;
	}

	if (output_stream != NULL) {
		/* The logger produces debugging output. */
		logger = camel_imapx_logger_new (is->priv->tagprefix);
		output_stream = g_converter_output_stream_new (
			output_stream, logger);
		g_clear_object (&logger);
	}

	g_mutex_lock (&is->priv->stream_lock);

	/* Don't close the base streams so STARTTLS works correctly. */

	if (G_IS_FILTER_INPUT_STREAM (is->priv->input_stream)) {
		g_filter_input_stream_set_close_base_stream (
			G_FILTER_INPUT_STREAM (is->priv->input_stream),
			FALSE);
	}

	if (G_IS_FILTER_OUTPUT_STREAM (is->priv->output_stream)) {
		g_filter_output_stream_set_close_base_stream (
			G_FILTER_OUTPUT_STREAM (is->priv->output_stream),
			FALSE);
	}

	g_clear_object (&is->priv->input_stream);
	is->priv->input_stream = input_stream;

	g_clear_object (&is->priv->output_stream);
	is->priv->output_stream = output_stream;

	g_mutex_unlock (&is->priv->stream_lock);
}

#ifdef G_OS_UNIX
static void
imapx_server_child_process_setup (gpointer user_data)
{
#ifdef TIOCNOTTY
	gint fd;
#endif

	setsid ();

#ifdef TIOCNOTTY
	/* Detach from the controlling tty if we have one.  Otherwise,
	 * SSH might do something stupid like trying to use it instead
	 * of running $SSH_ASKPASS. */
	if ((fd = open ("/dev/tty", O_RDONLY)) != -1) {
		ioctl (fd, TIOCNOTTY, NULL);
		close (fd);
	}
#endif /* TIOCNOTTY */
}
#endif /* G_OS_UNIX */

static gboolean
connect_to_server_process (CamelIMAPXServer *is,
                           const gchar *cmd,
                           GError **error)
{
	GSubprocessLauncher *launcher;
	GSubprocess *subprocess = NULL;
	CamelNetworkSettings *network_settings;
	CamelProvider *provider;
	CamelSettings *settings;
	CamelIMAPXStore *store;
	CamelURL url;
	gchar **argv = NULL;
	gchar *buf;
	gchar *cmd_copy;
	gchar *full_cmd;
	const gchar *password;
	gchar *host;
	gchar *user;
	guint16 port;

	memset (&url, 0, sizeof (CamelURL));

	launcher = g_subprocess_launcher_new (
		G_SUBPROCESS_FLAGS_STDIN_PIPE |
		G_SUBPROCESS_FLAGS_STDOUT_PIPE |
		G_SUBPROCESS_FLAGS_STDERR_SILENCE);

#ifdef G_OS_UNIX
	g_subprocess_launcher_set_child_setup (
		launcher, imapx_server_child_process_setup,
		NULL, (GDestroyNotify) NULL);
#endif

	store = camel_imapx_server_ref_store (is);

	password = camel_service_get_password (CAMEL_SERVICE (store));
	provider = camel_service_get_provider (CAMEL_SERVICE (store));
	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	port = camel_network_settings_get_port (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	/* Put full details in the environment, in case the connection
	 * program needs them */
	camel_url_set_protocol (&url, provider->protocol);
	camel_url_set_host (&url, host);
	camel_url_set_port (&url, port);
	camel_url_set_user (&url, user);
	buf = camel_url_to_string (&url, 0);

	g_subprocess_launcher_setenv (launcher, "URL", buf, TRUE);
	g_subprocess_launcher_setenv (launcher, "URLHOST", host, TRUE);

	if (port > 0) {
		gchar *port_string;

		port_string = g_strdup_printf ("%u", port);
		g_subprocess_launcher_setenv (
			launcher, "URLPORT", port_string, TRUE);
		g_free (port_string);
	}

	if (user != NULL) {
		g_subprocess_launcher_setenv (
			launcher, "URLPORT", user, TRUE);
	}

	if (password != NULL) {
		g_subprocess_launcher_setenv (
			launcher, "URLPASSWD", password, TRUE);
	}

	g_free (buf);

	g_object_unref (settings);
	g_object_unref (store);

	/* Now do %h, %u, etc. substitution in cmd */
	buf = cmd_copy = g_strdup (cmd);

	full_cmd = g_strdup ("");

	for (;;) {
		gchar *pc;
		gchar *tmp;
		const gchar *var;
		gint len;

		pc = strchr (buf, '%');
	ignore:
		if (!pc) {
			tmp = g_strdup_printf ("%s%s", full_cmd, buf);
			g_free (full_cmd);
			full_cmd = tmp;
			break;
		}

		len = pc - buf;

		var = NULL;

		switch (pc[1]) {
		case 'h':
			var = host;
			break;
		case 'u':
			var = user;
			break;
		}
		if (!var) {
			/* If there wasn't a valid %-code, with an actual
			 * variable to insert, pretend we didn't see the % */
			pc = strchr (pc + 1, '%');
			goto ignore;
		}
		tmp = g_strdup_printf ("%s%.*s%s", full_cmd, len, buf, var);
		g_free (full_cmd);
		full_cmd = tmp;
		buf = pc + 2;
	}

	g_free (cmd_copy);

	g_free (host);
	g_free (user);

	if (g_shell_parse_argv (full_cmd, NULL, &argv, error)) {
		subprocess = g_subprocess_launcher_spawnv (
			launcher, (const gchar * const *) argv, error);
		g_strfreev (argv);
	}

	g_free (full_cmd);
	g_object_unref (launcher);

	if (subprocess != NULL) {
		GInputStream *input_stream;
		GOutputStream *output_stream;

		g_mutex_lock (&is->priv->stream_lock);
		g_warn_if_fail (is->priv->subprocess == NULL);
		is->priv->subprocess = g_object_ref (subprocess);
		g_mutex_unlock (&is->priv->stream_lock);

		input_stream = g_subprocess_get_stdout_pipe (subprocess);
		output_stream = g_subprocess_get_stdin_pipe (subprocess);

		imapx_server_set_streams (is, input_stream, output_stream);

		g_object_unref (subprocess);
	}

	return TRUE;
}

static gboolean
imapx_connect_to_server (CamelIMAPXServer *is,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelNetworkSettings *network_settings;
	CamelNetworkSecurityMethod method;
	CamelIMAPXStore *store;
	CamelSettings *settings;
	GIOStream *connection = NULL;
	GIOStream *tls_stream;
	GSocket *socket;
	guint len;
	guchar *token;
	gint tok;
	CamelIMAPXCommand *ic;
	gchar *shell_command = NULL;
	gboolean use_shell_command;
	gboolean success = TRUE;
	gchar *host;

	store = camel_imapx_server_ref_store (is);

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	method = camel_network_settings_get_security_method (network_settings);

	use_shell_command = camel_imapx_settings_get_use_shell_command (
		CAMEL_IMAPX_SETTINGS (settings));

	if (use_shell_command)
		shell_command = camel_imapx_settings_dup_shell_command (
			CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	if (shell_command != NULL) {
		success = connect_to_server_process (is, shell_command, error);

		g_free (shell_command);

		if (success)
			goto connected;
		else
			goto exit;
	}

	connection = camel_network_service_connect_sync (
		CAMEL_NETWORK_SERVICE (store), cancellable, error);

	if (connection != NULL) {
		GInputStream *input_stream;
		GOutputStream *output_stream;
		GError *local_error = NULL;

		/* Disable the Nagle algorithm with TCP_NODELAY, since IMAP
		 * commands should be issued immediately even we've not yet
		 * received a response to a previous command. */
		socket = g_socket_connection_get_socket (
			G_SOCKET_CONNECTION (connection));
		g_socket_set_option (
			socket, IPPROTO_TCP, TCP_NODELAY, 1, &local_error);
		if (local_error != NULL) {
			/* Failure to set the socket option is non-fatal. */
			g_warning ("%s: %s", G_STRFUNC, local_error->message);
			g_clear_error (&local_error);
		}

		g_mutex_lock (&is->priv->stream_lock);
		g_warn_if_fail (is->priv->connection == NULL);
		is->priv->connection = g_object_ref (connection);
		g_mutex_unlock (&is->priv->stream_lock);

		input_stream = g_io_stream_get_input_stream (connection);
		output_stream = g_io_stream_get_output_stream (connection);

		imapx_server_set_streams (is, input_stream, output_stream);

		/* Hang on to the connection reference in case we need to
		 * issue STARTTLS below. */
	} else {
		success = FALSE;
		goto exit;
	}

connected:
	while (1) {
		GInputStream *input_stream;

		input_stream = camel_imapx_server_ref_input_stream (is);

		token = NULL;
		tok = camel_imapx_input_stream_token (
			CAMEL_IMAPX_INPUT_STREAM (input_stream),
			&token, &len, cancellable, error);

		if (tok < 0) {
			success = FALSE;

		} else if (tok == '*') {
			success = imapx_untagged (
				is, input_stream, cancellable, error);

			if (success) {
				g_object_unref (input_stream);
				break;
			}

		} else {
			camel_imapx_input_stream_ungettoken (
				CAMEL_IMAPX_INPUT_STREAM (input_stream),
				tok, token, len);

			success = camel_imapx_input_stream_text (
				CAMEL_IMAPX_INPUT_STREAM (input_stream),
				&token, cancellable, error);

			g_free (token);
		}

		g_object_unref (input_stream);

		if (!success)
			goto exit;
	}

	g_mutex_lock (&is->priv->stream_lock);

	if (!is->priv->cinfo) {
		g_mutex_unlock (&is->priv->stream_lock);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_CAPABILITY, "CAPABILITY");

		success = camel_imapx_server_process_command_sync (is, ic, _("Failed to get capabilities"), cancellable, error);

		camel_imapx_command_unref (ic);

		if (!success)
			goto exit;
	} else {
		g_mutex_unlock (&is->priv->stream_lock);
	}

	if (method == CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT) {

		g_mutex_lock (&is->priv->stream_lock);

		if (CAMEL_IMAPX_LACK_CAPABILITY (is->priv->cinfo, STARTTLS)) {
			g_mutex_unlock (&is->priv->stream_lock);
			g_set_error (
				error, CAMEL_ERROR,
				CAMEL_ERROR_GENERIC,
				_("Failed to connect to IMAP server %s in secure mode: %s"),
				host, _("STARTTLS not supported"));
			success = FALSE;
			goto exit;
		} else {
			g_mutex_unlock (&is->priv->stream_lock);
		}

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_STARTTLS, "STARTTLS");

		success = camel_imapx_server_process_command_sync (is, ic, _("Failed to issue STARTTLS"), cancellable, error);

		if (success) {
			g_mutex_lock (&is->priv->stream_lock);

			/* See if we got new capabilities
			 * in the STARTTLS response. */
			imapx_free_capability (is->priv->cinfo);
			is->priv->cinfo = NULL;
			if (ic->status->condition == IMAPX_CAPABILITY) {
				is->priv->cinfo = ic->status->u.cinfo;
				ic->status->u.cinfo = NULL;
				c (is->priv->tagprefix, "got capability flags %08x\n", is->priv->cinfo ? is->priv->cinfo->capa : 0xFFFFFFFF);
				imapx_server_stash_command_arguments (is);
			}

			g_mutex_unlock (&is->priv->stream_lock);
		}

		camel_imapx_command_unref (ic);

		if (!success)
			goto exit;

		tls_stream = camel_network_service_starttls (
			CAMEL_NETWORK_SERVICE (store), connection, error);

		if (tls_stream != NULL) {
			GInputStream *input_stream;
			GOutputStream *output_stream;

			g_mutex_lock (&is->priv->stream_lock);
			g_object_unref (is->priv->connection);
			is->priv->connection = g_object_ref (tls_stream);
			g_mutex_unlock (&is->priv->stream_lock);

			input_stream =
				g_io_stream_get_input_stream (tls_stream);
			output_stream =
				g_io_stream_get_output_stream (tls_stream);

			imapx_server_set_streams (
				is, input_stream, output_stream);

			g_object_unref (tls_stream);
		} else {
			g_prefix_error (
				error,
				_("Failed to connect to IMAP server %s in secure mode: "),
				host);
			success = FALSE;
			goto exit;
		}

		/* Get new capabilities if they weren't already given */
		g_mutex_lock (&is->priv->stream_lock);
		if (is->priv->cinfo == NULL) {
			g_mutex_unlock (&is->priv->stream_lock);
			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_CAPABILITY, "CAPABILITY");
			success = camel_imapx_server_process_command_sync (is, ic, _("Failed to get capabilities"), cancellable, error);
			camel_imapx_command_unref (ic);

			if (!success)
				goto exit;
		} else {
			g_mutex_unlock (&is->priv->stream_lock);
		}
	}

exit:
	if (!success) {
		g_mutex_lock (&is->priv->stream_lock);

		g_clear_object (&is->priv->input_stream);
		g_clear_object (&is->priv->output_stream);
		g_clear_object (&is->priv->connection);
		g_clear_object (&is->priv->subprocess);

		if (is->priv->cinfo != NULL) {
			imapx_free_capability (is->priv->cinfo);
			is->priv->cinfo = NULL;
		}

		g_mutex_unlock (&is->priv->stream_lock);
	}

	g_free (host);

	g_clear_object (&connection);
	g_clear_object (&store);

	return success;
}

gboolean
camel_imapx_server_is_connected (CamelIMAPXServer *imapx_server)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (imapx_server), FALSE);

	return imapx_server->priv->state >= IMAPX_CONNECTED;
}

CamelAuthenticationResult
camel_imapx_server_authenticate_sync (CamelIMAPXServer *is,
				      const gchar *mechanism,
				      GCancellable *cancellable,
				      GError **error)
{
	CamelNetworkSettings *network_settings;
	CamelIMAPXStore *store;
	CamelService *service;
	CamelSettings *settings;
	CamelAuthenticationResult result;
	CamelIMAPXCommand *ic;
	CamelSasl *sasl = NULL;
	gchar *host;
	gchar *user;

	g_return_val_if_fail (
		CAMEL_IS_IMAPX_SERVER (is),
		CAMEL_AUTHENTICATION_ERROR);

	store = camel_imapx_server_ref_store (is);

	service = CAMEL_SERVICE (store);
	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	if (mechanism != NULL) {
		g_mutex_lock (&is->priv->stream_lock);

		if (is->priv->cinfo && !g_hash_table_lookup (is->priv->cinfo->auth_types, mechanism) && (
		    !camel_sasl_is_xoauth2_alias (mechanism) ||
		    !g_hash_table_lookup (is->priv->cinfo->auth_types, "XOAUTH2"))) {
			g_mutex_unlock (&is->priv->stream_lock);
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("IMAP server %s does not support %s "
				"authentication"), host, mechanism);
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		} else {
			g_mutex_unlock (&is->priv->stream_lock);
		}

		sasl = camel_sasl_new ("imap", mechanism, service);
		if (sasl == NULL) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("No support for %s authentication"),
				mechanism);
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}
	}

	if (sasl != NULL) {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_AUTHENTICATE, "AUTHENTICATE %A", sasl);
	} else {
		const gchar *password;

		password = camel_service_get_password (service);

		if (user == NULL) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Cannot authenticate without a username"));
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		if (password == NULL) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Authentication password not available"));
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_LOGIN, "LOGIN %s %s", user, password);
	}

	if (!camel_imapx_server_process_command_sync (is, ic, _("Failed to authenticate"), cancellable, error) && (
	    !ic->status || ic->status->result != IMAPX_NO))
		result = CAMEL_AUTHENTICATION_ERROR;
	else if (ic->status->result == IMAPX_OK)
		result = CAMEL_AUTHENTICATION_ACCEPTED;
	else if (ic->status->result == IMAPX_NO) {
		g_clear_error (error);

		if (camel_imapx_store_is_connecting_concurrent_connection (store)) {
			/* At least one connection succeeded, probably max connection limit
			   set on the server had been reached, thus use special error code
			   for it, to instruct the connection manager to decrease the limit
			   and use already created connection. */
			g_set_error_literal (
				error, CAMEL_IMAPX_SERVER_ERROR,
				CAMEL_IMAPX_SERVER_ERROR_CONCURRENT_CONNECT_FAILED,
				ic->status->text ? ic->status->text : _("Unknown error"));
			result = CAMEL_AUTHENTICATION_ERROR;
		} else if (ic->status->condition != IMAPX_UNKNOWN && ic->status->condition != IMAPX_AUTHENTICATIONFAILED) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_UNAVAILABLE,
				ic->status->text ? ic->status->text : _("Unknown error"));
			result = CAMEL_AUTHENTICATION_ERROR;
		} else if (sasl) {
			CamelSaslClass *sasl_class;

			sasl_class = CAMEL_SASL_GET_CLASS (sasl);
			if (sasl_class && sasl_class->auth_type && !sasl_class->auth_type->need_password) {
				g_set_error_literal (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
					ic->status->text ? ic->status->text : _("Unknown error"));
				result = CAMEL_AUTHENTICATION_ERROR;
			} else {
				result = CAMEL_AUTHENTICATION_REJECTED;
			}
		} else {
			result = CAMEL_AUTHENTICATION_REJECTED;
		}
	} else {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			ic->status->text ? ic->status->text : _("Unknown error"));
		result = CAMEL_AUTHENTICATION_ERROR;
	}

	/* Forget old capabilities after login. */
	if (result == CAMEL_AUTHENTICATION_ACCEPTED) {
		g_mutex_lock (&is->priv->stream_lock);

		if (is->priv->cinfo) {
			imapx_free_capability (is->priv->cinfo);
			is->priv->cinfo = NULL;
		}

		if (ic->status->condition == IMAPX_CAPABILITY) {
			is->priv->cinfo = ic->status->u.cinfo;
			ic->status->u.cinfo = NULL;
			c (is->priv->tagprefix, "got capability flags %08x\n", is->priv->cinfo ? is->priv->cinfo->capa : 0xFFFFFFFF);
			imapx_server_stash_command_arguments (is);
		}

		g_mutex_unlock (&is->priv->stream_lock);
	}

	camel_imapx_command_unref (ic);

	if (sasl != NULL)
		g_object_unref (sasl);

exit:
	g_free (host);
	g_free (user);

	g_object_unref (store);

	return result;
}

static gboolean
imapx_reconnect (CamelIMAPXServer *is,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelIMAPXCommand *ic;
	CamelService *service;
	CamelSession *session;
	CamelIMAPXStore *store;
	CamelSettings *settings;
	gchar *mechanism;
	gboolean use_qresync;
	gboolean use_idle;
	gboolean success = FALSE;

	store = camel_imapx_server_ref_store (is);

	service = CAMEL_SERVICE (store);
	session = camel_service_ref_session (service);
	if (!session) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		g_object_unref (store);
		return FALSE;
	}

	settings = camel_service_ref_settings (service);

	mechanism = camel_network_settings_dup_auth_mechanism (
		CAMEL_NETWORK_SETTINGS (settings));

	use_qresync = camel_imapx_settings_get_use_qresync (CAMEL_IMAPX_SETTINGS (settings));
	use_idle = camel_imapx_settings_get_use_idle (CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	if (!imapx_connect_to_server (is, cancellable, error))
		goto exception;

	if (is->priv->state == IMAPX_AUTHENTICATED)
		goto preauthed;

	if (!camel_session_authenticate_sync (
		session, service, mechanism, cancellable, error))
		goto exception;

	/* After login we re-capa unless the server already told us. */
	g_mutex_lock (&is->priv->stream_lock);
	if (is->priv->cinfo == NULL) {
		GError *local_error = NULL;

		g_mutex_unlock (&is->priv->stream_lock);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_CAPABILITY, "CAPABILITY");
		camel_imapx_server_process_command_sync (is, ic, _("Failed to get capabilities"), cancellable, &local_error);
		camel_imapx_command_unref (ic);

		if (local_error != NULL) {
			g_propagate_error (error, local_error);
			goto exception;
		}
	} else {
		g_mutex_unlock (&is->priv->stream_lock);
	}

	is->priv->state = IMAPX_AUTHENTICATED;

preauthed:
	/* Fetch namespaces (if supported). */
	g_mutex_lock (&is->priv->stream_lock);

	is->priv->utf8_accept = FALSE;

	/* RFC 6855 */
	if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, UTF8_ACCEPT) ||
	    CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, UTF8_ONLY)) {
		GError *local_error = NULL;

		g_mutex_unlock (&is->priv->stream_lock);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NAMESPACE, "ENABLE UTF8=ACCEPT");
		camel_imapx_server_process_command_sync (is, ic, _("Failed to issue ENABLE UTF8=ACCEPT"), cancellable, &local_error);
		camel_imapx_command_unref (ic);

		if (local_error != NULL) {
			g_propagate_error (error, local_error);
			goto exception;
		}

		g_mutex_lock (&is->priv->stream_lock);

		is->priv->utf8_accept = TRUE;
	}

	if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, NAMESPACE)) {
		GError *local_error = NULL;

		g_mutex_unlock (&is->priv->stream_lock);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NAMESPACE, "NAMESPACE");
		camel_imapx_server_process_command_sync (is, ic, _("Failed to issue NAMESPACE"), cancellable, &local_error);
		camel_imapx_command_unref (ic);

		if (local_error != NULL) {
			g_propagate_error (error, local_error);
			goto exception;
		}

		g_mutex_lock (&is->priv->stream_lock);
	}

	/* Enable quick mailbox resynchronization (if supported). */
	if (use_qresync && CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, QRESYNC)) {
		GError *local_error = NULL;

		g_mutex_unlock (&is->priv->stream_lock);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_ENABLE, "ENABLE CONDSTORE QRESYNC");
		camel_imapx_server_process_command_sync (is, ic, _("Failed to enable QResync"), cancellable, &local_error);
		camel_imapx_command_unref (ic);

		if (local_error != NULL) {
			g_propagate_error (error, local_error);
			goto exception;
		}

		g_mutex_lock (&is->priv->stream_lock);

		is->priv->use_qresync = TRUE;
	} else {
		is->priv->use_qresync = FALSE;
	}

	/* Set NOTIFY options after enabling QRESYNC (if supported). */
	if (use_idle && CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, NOTIFY)) {
		GError *local_error = NULL;

		g_mutex_unlock (&is->priv->stream_lock);

		#define NOTIFY_CMD(x) "NOTIFY SET " \
			"(selected " \
			"(MessageNew (UID RFC822.SIZE RFC822.HEADER FLAGS" x ")" \
			" MessageExpunge" \
			" FlagChange)) " \
			"(personal " \
			"(MessageNew" \
			" MessageExpunge" \
			" MailboxName" \
			" SubscriptionChange))"

		/* XXX The list of FETCH attributes is negotiable. */
		if (camel_imapx_store_get_bodystructure_enabled (store))
			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NOTIFY, NOTIFY_CMD (" BODYSTRUCTURE"));
		else
			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NOTIFY, NOTIFY_CMD (""));
		camel_imapx_server_process_command_sync (is, ic, _("Failed to issue NOTIFY"), cancellable, &local_error);
		camel_imapx_command_unref (ic);

		#undef NOTIFY_CMD

		if (local_error != NULL) {
			g_propagate_error (error, local_error);
			goto exception;
		}

		g_mutex_lock (&is->priv->stream_lock);
	}

	g_mutex_unlock (&is->priv->stream_lock);

	is->priv->state = IMAPX_INITIALISED;

	success = TRUE;

	goto exit;

exception:
	imapx_disconnect (is);

exit:
	g_free (mechanism);

	g_object_unref (session);
	g_object_unref (store);

	return success;
}

/* ********************************************************************** */

/* FIXME: this is basically a copy of the same in camel-imapx-utils.c */
static struct {
	const gchar *name;
	guint32 flag;
} flags_table[] = {
	{ "\\ANSWERED", CAMEL_MESSAGE_ANSWERED },
	{ "\\DELETED", CAMEL_MESSAGE_DELETED },
	{ "\\DRAFT", CAMEL_MESSAGE_DRAFT },
	{ "\\FLAGGED", CAMEL_MESSAGE_FLAGGED },
	{ "\\SEEN", CAMEL_MESSAGE_SEEN },
	{ "\\RECENT", CAMEL_IMAPX_MESSAGE_RECENT },
	{ "JUNK", CAMEL_MESSAGE_JUNK },
	{ "NOTJUNK", CAMEL_MESSAGE_NOTJUNK }
};

static void
imapx_server_set_store (CamelIMAPXServer *server,
                        CamelIMAPXStore *store)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));

	g_weak_ref_set (&server->priv->store, store);
}

static void
imapx_server_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			imapx_server_set_store (
				CAMEL_IMAPX_SERVER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_server_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			g_value_take_object (
				value,
				camel_imapx_server_ref_store (
				CAMEL_IMAPX_SERVER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_server_dispose (GObject *object)
{
	CamelIMAPXServer *server = CAMEL_IMAPX_SERVER (object);

	g_cancellable_cancel (server->priv->cancellable);

	imapx_disconnect (server);

	g_weak_ref_set (&server->priv->store, NULL);

	g_clear_object (&server->priv->subprocess);

	g_mutex_lock (&server->priv->idle_lock);
	g_clear_object (&server->priv->idle_cancellable);
	g_clear_object (&server->priv->idle_mailbox);
	if (server->priv->idle_pending) {
		g_source_destroy (server->priv->idle_pending);
		g_source_unref (server->priv->idle_pending);
		server->priv->idle_pending = NULL;
	}
	g_mutex_unlock (&server->priv->idle_lock);

	g_clear_object (&server->priv->subprocess);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_server_parent_class)->dispose (object);
}

static void
imapx_server_finalize (GObject *object)
{
	CamelIMAPXServer *is = CAMEL_IMAPX_SERVER (object);

	g_mutex_clear (&is->priv->stream_lock);
	g_mutex_clear (&is->priv->select_lock);
	g_mutex_clear (&is->priv->changes_lock);

	camel_folder_change_info_free (is->priv->changes);
	imapx_free_status (is->priv->copyuid_status);

	g_free (is->priv->context);
	g_hash_table_destroy (is->priv->untagged_handlers);

	if (is->priv->inactivity_timeout != NULL)
		g_source_unref (is->priv->inactivity_timeout);
	g_mutex_clear (&is->priv->inactivity_timeout_lock);

	g_free (is->priv->status_data_items);
	g_free (is->priv->list_return_opts);

	if (is->priv->search_results != NULL)
		g_array_unref (is->priv->search_results);
	g_mutex_clear (&is->priv->search_results_lock);

	g_hash_table_destroy (is->priv->known_alerts);
	g_mutex_clear (&is->priv->known_alerts_lock);

	g_mutex_clear (&is->priv->idle_lock);
	g_cond_clear (&is->priv->idle_cond);

	g_rec_mutex_clear (&is->priv->command_lock);

	g_weak_ref_clear (&is->priv->store);
	g_weak_ref_clear (&is->priv->select_mailbox);
	g_weak_ref_clear (&is->priv->select_pending);
	g_clear_object (&is->priv->cancellable);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_server_parent_class)->finalize (object);
}

static void
imapx_server_constructed (GObject *object)
{
	CamelIMAPXServer *server;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_imapx_server_parent_class)->constructed (object);

	server = CAMEL_IMAPX_SERVER (object);
	server->priv->tagprefix = 'Z';
}

static void
camel_imapx_server_class_init (CamelIMAPXServerClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXServerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_server_set_property;
	object_class->get_property = imapx_server_get_property;
	object_class->finalize = imapx_server_finalize;
	object_class->dispose = imapx_server_dispose;
	object_class->constructed = imapx_server_constructed;

	g_object_class_install_property (
		object_class,
		PROP_STORE,
		g_param_spec_object (
			"store",
			"Store",
			"IMAPX store for this server",
			CAMEL_TYPE_IMAPX_STORE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	signals[REFRESH_MAILBOX] = g_signal_new (
		"refresh-mailbox",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (CamelIMAPXServerClass, refresh_mailbox),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_IMAPX_MAILBOX);
}

static void
camel_imapx_server_init (CamelIMAPXServer *is)
{
	is->priv = CAMEL_IMAPX_SERVER_GET_PRIVATE (is);

	is->priv->untagged_handlers = create_initial_untagged_handler_table ();

	g_mutex_init (&is->priv->stream_lock);
	g_mutex_init (&is->priv->inactivity_timeout_lock);
	g_mutex_init (&is->priv->select_lock);
	g_mutex_init (&is->priv->changes_lock);
	g_mutex_init (&is->priv->search_results_lock);
	g_mutex_init (&is->priv->known_alerts_lock);

	g_weak_ref_init (&is->priv->store, NULL);
	g_weak_ref_init (&is->priv->select_mailbox, NULL);
	g_weak_ref_init (&is->priv->select_pending, NULL);

	is->priv->cancellable = g_cancellable_new ();

	is->priv->state = IMAPX_DISCONNECTED;
	is->priv->is_cyrus = FALSE;
	is->priv->is_broken_cyrus = FALSE;
	is->priv->copyuid_status = NULL;

	is->priv->changes = camel_folder_change_info_new ();

	is->priv->known_alerts = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) NULL);

	/* Initialize IDLE members. */
	g_mutex_init (&is->priv->idle_lock);
	g_cond_init (&is->priv->idle_cond);
	is->priv->idle_state = IMAPX_IDLE_STATE_OFF;
	is->priv->idle_stamp = 0;

	g_rec_mutex_init (&is->priv->command_lock);
}

CamelIMAPXServer *
camel_imapx_server_new (CamelIMAPXStore *store)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (store), NULL);

	return g_object_new (
		CAMEL_TYPE_IMAPX_SERVER,
		"store", store, NULL);
}

CamelIMAPXStore *
camel_imapx_server_ref_store (CamelIMAPXServer *server)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), NULL);

	return g_weak_ref_get (&server->priv->store);
}

CamelIMAPXSettings *
camel_imapx_server_ref_settings (CamelIMAPXServer *server)
{
	CamelIMAPXStore *store;
	CamelSettings *settings;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (server), NULL);

	store = camel_imapx_server_ref_store (server);
	settings = camel_service_ref_settings (CAMEL_SERVICE (store));
	g_object_unref (store);

	return CAMEL_IMAPX_SETTINGS (settings);
}

/**
 * camel_imapx_server_ref_input_stream:
 * @is: a #CamelIMAPXServer
 *
 * Returns the #GInputStream for @is, which is owned by either a
 * #GTcpConnection or a #GSubprocess.  If the #CamelIMAPXServer is not
 * yet connected or has lost its connection, the function returns %NULL.
 *
 * The returned #GInputStream is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #GInputStream, or %NULL
 *
 * Since: 3.12
 **/
GInputStream *
camel_imapx_server_ref_input_stream (CamelIMAPXServer *is)
{
	GInputStream *input_stream = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	g_mutex_lock (&is->priv->stream_lock);

	if (is->priv->input_stream != NULL)
		input_stream = g_object_ref (is->priv->input_stream);

	g_mutex_unlock (&is->priv->stream_lock);

	return input_stream;
}

/**
 * camel_imapx_server_ref_output_stream:
 * @is: a #CamelIMAPXServer
 *
 * Returns the #GOutputStream for @is, which is owned by either a
 * #GTcpConnection or a #GSubprocess.  If the #CamelIMAPXServer is not
 * yet connected or has lost its connection, the function returns %NULL.
 *
 * The returned #GOutputStream is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #GOutputStream, or %NULL
 *
 * Since: 3.12
 **/
GOutputStream *
camel_imapx_server_ref_output_stream (CamelIMAPXServer *is)
{
	GOutputStream *output_stream = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	g_mutex_lock (&is->priv->stream_lock);

	if (is->priv->output_stream != NULL)
		output_stream = g_object_ref (is->priv->output_stream);

	g_mutex_unlock (&is->priv->stream_lock);

	return output_stream;
}

/**
 * camel_imapx_server_ref_selected:
 * @is: a #CamelIMAPXServer
 *
 * Returns the #CamelIMAPXMailbox representing the currently selected
 * mailbox (or mailbox <emphasis>being</emphasis> selected if a SELECT
 * command is in progress) on the IMAP server, or %NULL if no mailbox
 * is currently selected or being selected on the server.
 *
 * The returned #CamelIMAPXMailbox is reference for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXMailbox, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXMailbox *
camel_imapx_server_ref_selected (CamelIMAPXServer *is)
{
	CamelIMAPXMailbox *mailbox;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	g_mutex_lock (&is->priv->select_lock);

	mailbox = g_weak_ref_get (&is->priv->select_mailbox);
	if (mailbox == NULL)
		mailbox = g_weak_ref_get (&is->priv->select_pending);

	g_mutex_unlock (&is->priv->select_lock);

	return mailbox;
}

/* Some untagged responses updated pending SELECT mailbox, not the currently
   selected or closing one, thus use this function instead. */
CamelIMAPXMailbox *
camel_imapx_server_ref_pending_or_selected (CamelIMAPXServer *is)
{
	CamelIMAPXMailbox *mailbox;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	g_mutex_lock (&is->priv->select_lock);

	mailbox = g_weak_ref_get (&is->priv->select_pending);
	if (mailbox == NULL)
		mailbox = g_weak_ref_get (&is->priv->select_mailbox);

	g_mutex_unlock (&is->priv->select_lock);

	return mailbox;
}

gboolean
camel_imapx_server_mailbox_selected (CamelIMAPXServer *is,
				     CamelIMAPXMailbox *mailbox)
{
	CamelIMAPXMailbox *selected_mailbox;
	gboolean res;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	g_mutex_lock (&is->priv->select_lock);
	selected_mailbox = g_weak_ref_get (&is->priv->select_mailbox);
	res = selected_mailbox == mailbox;
	g_clear_object (&selected_mailbox);
	g_mutex_unlock (&is->priv->select_lock);

	return res;
}

gboolean
camel_imapx_server_ensure_selected_sync (CamelIMAPXServer *is,
					 CamelIMAPXMailbox *mailbox,
					 GCancellable *cancellable,
					 GError **error)
{
	CamelIMAPXCommand *ic;
	CamelIMAPXMailbox *selected_mailbox;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	g_mutex_lock (&is->priv->select_lock);
	selected_mailbox = g_weak_ref_get (&is->priv->select_mailbox);
	if (selected_mailbox == mailbox) {
		gboolean request_noop;
		gint change_stamp;

		change_stamp = selected_mailbox ? camel_imapx_mailbox_get_change_stamp (selected_mailbox) : 0;
		request_noop = selected_mailbox && is->priv->last_selected_mailbox_change_stamp != change_stamp;

		if (request_noop)
			is->priv->last_selected_mailbox_change_stamp = change_stamp;

		g_mutex_unlock (&is->priv->select_lock);
		g_clear_object (&selected_mailbox);

		if (request_noop) {
			c (is->priv->tagprefix, "%s: Selected mailbox '%s' changed, do NOOP instead\n", G_STRFUNC, camel_imapx_mailbox_get_name (mailbox));

			return camel_imapx_server_noop_sync (is, mailbox, cancellable, error);
		}

		return TRUE;
	}

	g_clear_object (&selected_mailbox);

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_SELECT, "SELECT %M", mailbox);

	if (is->priv->use_qresync) {
		CamelFolder *folder;

		folder = imapx_server_ref_folder (is, mailbox);
		camel_imapx_command_add_qresync_parameter (ic, folder);
		g_clear_object (&folder);
	}

	g_weak_ref_set (&is->priv->select_pending, mailbox);
	g_mutex_unlock (&is->priv->select_lock);

	success = camel_imapx_server_process_command_sync (is, ic, _("Failed to select mailbox"), cancellable, error);

	camel_imapx_command_unref (ic);

	g_mutex_lock (&is->priv->select_lock);

	g_weak_ref_set (&is->priv->select_pending, NULL);

	if (success) {
		is->priv->state = IMAPX_SELECTED;
		is->priv->last_selected_mailbox_change_stamp = camel_imapx_mailbox_get_change_stamp (mailbox);
		g_weak_ref_set (&is->priv->select_mailbox, mailbox);
	} else {
		is->priv->state = IMAPX_INITIALISED;
		is->priv->last_selected_mailbox_change_stamp = 0;
		g_weak_ref_set (&is->priv->select_mailbox, NULL);
	}

	g_mutex_unlock (&is->priv->select_lock);

	return success;
}

gboolean
camel_imapx_server_process_command_sync (CamelIMAPXServer *is,
					 CamelIMAPXCommand *ic,
					 const gchar *error_prefix,
					 GCancellable *cancellable,
					 GError **error)
{
	CamelIMAPXCommandPart *cp;
	GInputStream *input_stream = NULL;
	GOutputStream *output_stream = NULL;
	gboolean cp_literal_plus;
	GList *head;
	gchar *string;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_COMMAND (ic), FALSE);

	camel_imapx_command_close (ic);
	if (ic->status) {
		imapx_free_status (ic->status);
		ic->status = NULL;
	}
	ic->completed = FALSE;

	head = g_queue_peek_head_link (&ic->parts);
	g_return_val_if_fail (head != NULL, FALSE);
	cp = (CamelIMAPXCommandPart *) head->data;
	ic->current_part = head;

	if (g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
		if (error_prefix && local_error)
			g_prefix_error (&local_error, "%s: ", error_prefix);

		if (local_error)
			g_propagate_error (error, local_error);

		return FALSE;
	}

	cp_literal_plus = ((cp->type & CAMEL_IMAPX_COMMAND_LITERAL_PLUS) != 0);

	COMMAND_LOCK (is);

	if (is->priv->current_command != NULL) {
		g_warning ("%s: [%c] %p: Starting command %p (%s) while still processing %p (%s)", G_STRFUNC,
			is->priv->tagprefix, is, ic, camel_imapx_job_get_kind_name (ic->job_kind),
			is->priv->current_command, camel_imapx_job_get_kind_name (is->priv->current_command->job_kind));
	}

	if (g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
		c (is->priv->tagprefix, "%s: command %p (%s) cancelled\n", G_STRFUNC, ic, camel_imapx_job_get_kind_name (ic->job_kind));

		COMMAND_UNLOCK (is);

		if (error_prefix && local_error)
			g_prefix_error (&local_error, "%s: ", error_prefix);

		if (local_error)
			g_propagate_error (error, local_error);

		return FALSE;
	}

	c (is->priv->tagprefix, "%s: %p (%s) ~> %p (%s)\n", G_STRFUNC, is->priv->current_command,
		is->priv->current_command ? camel_imapx_job_get_kind_name (is->priv->current_command->job_kind) : "",
		ic, camel_imapx_job_get_kind_name (ic->job_kind));

	is->priv->current_command = ic;
	is->priv->continuation_command = ic;

	COMMAND_UNLOCK (is);

	input_stream = camel_imapx_server_ref_input_stream (is);
	output_stream = camel_imapx_server_ref_output_stream (is);

	if (output_stream == NULL) {
		local_error = g_error_new_literal (
			CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
			_("Cannot issue command, no stream available"));
		goto exit;
	}

	c (
		is->priv->tagprefix,
		"Starting command (%s) %c%05u %s\r\n",
		is->priv->current_command ? " literal" : "",
		is->priv->tagprefix,
		ic->tag,
		cp->data && g_str_has_prefix (cp->data, "LOGIN") ?
			"LOGIN..." : cp->data);

	if (ic->job_kind == CAMEL_IMAPX_JOB_DONE)
		string = g_strdup_printf ("%s\r\n", cp->data);
	else
		string = g_strdup_printf ("%c%05u %s\r\n", is->priv->tagprefix, ic->tag, cp->data);
	g_mutex_lock (&is->priv->stream_lock);
	success = g_output_stream_write_all (
		output_stream, string, strlen (string),
		NULL, cancellable, &local_error);
	g_mutex_unlock (&is->priv->stream_lock);
	g_free (string);

	if (local_error != NULL || !success)
		goto exit;

	while (is->priv->continuation_command == ic && cp_literal_plus) {
		/* Sent LITERAL+ continuation immediately */
		imapx_continuation (
			is, input_stream, output_stream,
			TRUE, cancellable, &local_error);
		if (local_error != NULL)
			goto exit;
	}

	while (success && !ic->completed)
		success = imapx_step (is, input_stream, output_stream, cancellable, &local_error);

	imapx_server_reset_inactivity_timer (is);

 exit:

	COMMAND_LOCK (is);

	if (is->priv->current_command == ic) {
		c (is->priv->tagprefix, "%s: %p ~> %p; success:%d local-error:%s result:%s status-text:'%s'\n", G_STRFUNC,
			is->priv->current_command, NULL, success, local_error ? local_error->message : "[null]",
			ic->status ? (
				ic->status->result == IMAPX_OK ? "OK" :
				ic->status->result == IMAPX_NO ? "NO" :
				ic->status->result == IMAPX_BAD ? "BAD" :
				ic->status->result == IMAPX_PREAUTH ? "PREAUTH" :
				ic->status->result == IMAPX_BYE ? "BYE" : "???") : "[null]",
			ic->status ? ic->status->text : "[null]");

		is->priv->current_command = NULL;
		is->priv->continuation_command = NULL;
	} else {
		c (is->priv->tagprefix, "%s: current command:%p doesn't match passed-in command:%p success:%d local-error:%s result:%s status-text:'%s'\n", G_STRFUNC,
			is->priv->current_command, ic, success, local_error ? local_error->message : "[null]",
			ic->status ? (
				ic->status->result == IMAPX_OK ? "OK" :
				ic->status->result == IMAPX_NO ? "NO" :
				ic->status->result == IMAPX_BAD ? "BAD" :
				ic->status->result == IMAPX_PREAUTH ? "PREAUTH" :
				ic->status->result == IMAPX_BYE ? "BYE" : "???") : "[null]",
			ic->status ? ic->status->text : "[null]");
	}

	COMMAND_UNLOCK (is);

	/* Server reported error. */
	if (success && ic->status && ic->status->result != IMAPX_OK) {
		g_set_error (
			&local_error, CAMEL_ERROR,
			CAMEL_ERROR_GENERIC,
			"%s", ic->status->text);
	}

	if (local_error) {
		/* Sadly, G_IO_ERROR_FAILED is also used for 'Connection reset by peer' error;
		   since GLib 2.44 is used G_IO_ERROR_CONNECTION_CLOSED, which is the same as G_IO_ERROR_BROKEN_PIPE */
		if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_FAILED) ||
		    g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_BROKEN_PIPE) ||
		    g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_TIMED_OUT)) {
			local_error->domain = CAMEL_IMAPX_SERVER_ERROR;
			local_error->code = CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT;
		}

		if (error_prefix && local_error)
			g_prefix_error (&local_error, "%s: ", error_prefix);

		g_propagate_error (error, local_error);

		success = FALSE;
	}

	g_clear_object (&input_stream);
	g_clear_object (&output_stream);

	return success;
}

static void
imapx_disconnect (CamelIMAPXServer *is)
{
	g_cancellable_cancel (is->priv->cancellable);

	g_mutex_lock (&is->priv->stream_lock);

	if (is->priv->connection) {
		/* No need to wait for close for too long */
		imapx_server_set_connection_timeout (is->priv->connection, 3);
	}

	g_clear_object (&is->priv->input_stream);
	g_clear_object (&is->priv->output_stream);
	g_clear_object (&is->priv->connection);
	g_clear_object (&is->priv->subprocess);

	if (is->priv->cinfo) {
		imapx_free_capability (is->priv->cinfo);
		is->priv->cinfo = NULL;
	}

	g_mutex_unlock (&is->priv->stream_lock);

	g_mutex_lock (&is->priv->select_lock);
	is->priv->last_selected_mailbox_change_stamp = 0;
	g_weak_ref_set (&is->priv->select_mailbox, NULL);
	g_weak_ref_set (&is->priv->select_pending, NULL);
	g_mutex_unlock (&is->priv->select_lock);

	is->priv->is_cyrus = FALSE;
	is->priv->is_broken_cyrus = FALSE;
	is->priv->state = IMAPX_DISCONNECTED;

	g_mutex_lock (&is->priv->idle_lock);
	is->priv->idle_state = IMAPX_IDLE_STATE_OFF;
	g_cond_broadcast (&is->priv->idle_cond);
	g_mutex_unlock (&is->priv->idle_lock);
}

/* Client commands */
gboolean
camel_imapx_server_connect_sync (CamelIMAPXServer *is,
				 GCancellable *cancellable,
				 GError **error)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	if (is->priv->state == IMAPX_SHUTDOWN) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			"Shutting down");
		return FALSE;
	}

	if (is->priv->state >= IMAPX_INITIALISED)
		return TRUE;

	is->priv->is_cyrus = FALSE;
	is->priv->is_broken_cyrus = FALSE;

	if (!imapx_reconnect (is, cancellable, error))
		return FALSE;

	g_mutex_lock (&is->priv->stream_lock);

	if (CAMEL_IMAPX_LACK_CAPABILITY (is->priv->cinfo, NAMESPACE)) {
		g_mutex_unlock (&is->priv->stream_lock);

		/* This also creates a needed faux NAMESPACE */
		if (!camel_imapx_server_list_sync (is, "INBOX", 0, cancellable, error))
			return FALSE;
	} else {
		g_mutex_unlock (&is->priv->stream_lock);
	}

	return TRUE;
}

gboolean
camel_imapx_server_disconnect_sync (CamelIMAPXServer *is,
				    GCancellable *cancellable,
				    GError **error)
{
	GCancellable *idle_cancellable;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->idle_lock);
	idle_cancellable = is->priv->idle_cancellable;
	if (idle_cancellable)
		g_object_ref (idle_cancellable);
	g_mutex_unlock (&is->priv->idle_lock);

	if (idle_cancellable)
		g_cancellable_cancel (idle_cancellable);
	g_clear_object (&idle_cancellable);

	g_mutex_lock (&is->priv->stream_lock);
	if (is->priv->connection) {
		/* No need to wait for close for too long */
		imapx_server_set_connection_timeout (is->priv->connection, 3);
	}
	g_mutex_unlock (&is->priv->stream_lock);

	/* Ignore errors here. */
	camel_imapx_server_stop_idle_sync (is, cancellable, NULL);

	g_mutex_lock (&is->priv->stream_lock);
	if (is->priv->connection)
		success = g_io_stream_close (is->priv->connection, cancellable, error);
	g_mutex_unlock (&is->priv->stream_lock);

	imapx_disconnect (is);

	return success;
}

gboolean
camel_imapx_server_query_auth_types_sync (CamelIMAPXServer *is,
					  GCancellable *cancellable,
					  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	return imapx_connect_to_server (is, cancellable, error);
}

CamelStream *
camel_imapx_server_get_message_sync (CamelIMAPXServer *is,
				     CamelIMAPXMailbox *mailbox,
				     CamelFolderSummary *summary,
				     CamelDataCache *message_cache,
				     const gchar *message_uid,
				     GCancellable *cancellable,
				     GError **error)
{
	CamelMessageInfo *mi;
	CamelStream *result_stream = NULL;
	CamelIMAPXSettings *settings;
	GIOStream *cache_stream;
	gsize data_size;
	gboolean use_multi_fetch;
	gboolean success, retrying = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (message_cache), NULL);
	g_return_val_if_fail (message_uid != NULL, NULL);

	if (!camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error))
		return NULL;

	mi = camel_folder_summary_get (summary, message_uid);
	if (mi == NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_UID,
			_("Cannot get message with message ID %s: %s"),
			message_uid, _("No such message available."));
		return NULL;
	}

	/* This makes sure that if any file is left on the disk, it is not reused.
	   That can happen when the previous message download had been cancelled
	   or finished with an error. */
	camel_data_cache_remove (message_cache, "tmp", message_uid, NULL);

	/* Check whether the message is already downloaded by another job */
	cache_stream = camel_data_cache_get (message_cache, "cur", message_uid, NULL);
	if (cache_stream) {
		result_stream = camel_stream_new (cache_stream);

		g_clear_object (&cache_stream);
		g_clear_object (&mi);

		return result_stream;
	}

	cache_stream = camel_data_cache_add (message_cache, "tmp", message_uid, error);
	if (cache_stream == NULL) {
		g_clear_object (&mi);
		return NULL;
	}

	settings = camel_imapx_server_ref_settings (is);
	data_size = camel_message_info_get_size (mi);
	use_multi_fetch = data_size > MULTI_SIZE && camel_imapx_settings_get_use_multi_fetch (settings);
	g_object_unref (settings);

	g_warn_if_fail (is->priv->get_message_stream == NULL);

	is->priv->get_message_stream = cache_stream;

 try_again:
	if (use_multi_fetch) {
		CamelIMAPXCommand *ic;
		gsize fetch_offset = 0;

		do {
			camel_operation_progress (cancellable, fetch_offset * 100 / data_size);

			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_GET_MESSAGE, "UID FETCH %t (BODY.PEEK[]", message_uid);
			camel_imapx_command_add (ic, "<%u.%u>", fetch_offset, MULTI_SIZE);
			camel_imapx_command_add (ic, ")");
			fetch_offset += MULTI_SIZE;

			success = camel_imapx_server_process_command_sync (is, ic, _("Error fetching message"), cancellable, &local_error);

			camel_imapx_command_unref (ic);
			ic = NULL;

			if (success) {
				gsize really_fetched = g_seekable_tell (G_SEEKABLE (is->priv->get_message_stream));

				/* Don't automatically stop when we reach the reported message
				 * size -- some crappy servers (like Microsoft Exchange) have
				 * a tendency to lie about it. Keep going (one request at a
				 * time) until the data actually stop coming. */
				if (fetch_offset < data_size ||
				    fetch_offset == really_fetched) {
					/* just continue */
				} else {
					break;
				}
			}
		} while (success);
	} else {
		CamelIMAPXCommand *ic;

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_GET_MESSAGE, "UID FETCH %t (BODY.PEEK[])", message_uid);

		success = camel_imapx_server_process_command_sync (is, ic, _("Error fetching message"), cancellable, &local_error);

		camel_imapx_command_unref (ic);
	}

	if (success && !retrying && !g_seekable_tell (G_SEEKABLE (is->priv->get_message_stream))) {
		/* Nothing had been read from the server. Maybe this connection
		   doesn't know about the message on the server side yet, thus
		   invoke NOOP and retry. */
		CamelIMAPXCommand *ic;

		retrying = TRUE;

		c (is->priv->tagprefix, "%s: Returned no message data, retrying after NOOP\n", G_STRFUNC);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NOOP, "NOOP");

		success = camel_imapx_server_process_command_sync (is, ic, _("Error performing NOOP"), cancellable, &local_error);

		camel_imapx_command_unref (ic);

		if (success)
			goto try_again;
	}

	is->priv->get_message_stream = NULL;

	if (success) {
		if (local_error == NULL) {
			g_io_stream_close (cache_stream, cancellable, &local_error);
			g_prefix_error (
				&local_error, "%s: ",
				_("Failed to close the tmp stream"));
		}

		if (local_error == NULL &&
		    g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
			g_prefix_error (
				&local_error, "%s: ",
				_("Error fetching message"));
		}

		if (local_error == NULL) {
			gchar *cur_filename;
			gchar *tmp_filename;
			gchar *dirname;

			cur_filename = camel_data_cache_get_filename (message_cache, "cur", message_uid);
			tmp_filename = camel_data_cache_get_filename (message_cache, "tmp", message_uid);

			dirname = g_path_get_dirname (cur_filename);
			g_mkdir_with_parents (dirname, 0700);
			g_free (dirname);

			if (g_rename (tmp_filename, cur_filename) == 0) {
				/* Exchange the "tmp" stream for the "cur" stream. */
				g_clear_object (&cache_stream);
				cache_stream = camel_data_cache_get (message_cache, "cur", message_uid, &local_error);
			} else {
				g_set_error (
					&local_error, G_FILE_ERROR,
					g_file_error_from_errno (errno),
					"%s: %s",
					_("Failed to copy the tmp file"),
					g_strerror (errno));
			}

			g_free (cur_filename);
			g_free (tmp_filename);
		}

		/* Delete the 'tmp' file only if the operation succeeded. It's because
		   cancelled operations end before they are properly finished (IMAP-protocol speaking),
		   thus if any other GET_MESSAGE operation was waiting for this job, then it
		   realized that the message was not downloaded and opened its own "tmp" file, but
		   of the same name, thus this remove would drop file which could be used
		   by a different GET_MESSAGE job. */
		if (!local_error && !g_cancellable_is_cancelled (cancellable))
			camel_data_cache_remove (message_cache, "tmp", message_uid, NULL);
	}

	if (!local_error) {
		result_stream = camel_stream_new (cache_stream);
	} else {
		g_propagate_error (error, local_error);
	}

	g_clear_object (&cache_stream);

	return result_stream;
}

gboolean
camel_imapx_server_sync_message_sync (CamelIMAPXServer *is,
				      CamelIMAPXMailbox *mailbox,
				      CamelFolderSummary *summary,
				      CamelDataCache *message_cache,
				      const gchar *message_uid,
				      GCancellable *cancellable,
				      GError **error)
{
	gchar *cache_file = NULL;
	gboolean is_cached;
	struct stat st;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (message_cache), FALSE);
	g_return_val_if_fail (message_uid != NULL, FALSE);

	/* Check if the cache file already exists and is non-empty. */
	cache_file = camel_data_cache_get_filename (message_cache, "cur", message_uid);
	is_cached = (g_stat (cache_file, &st) == 0 && st.st_size > 0);
	g_free (cache_file);

	if (!is_cached) {
		CamelStream *stream;

		stream = camel_imapx_server_get_message_sync (
			is, mailbox, summary,
			message_cache, message_uid,
			cancellable, error);

		success = (stream != NULL);

		g_clear_object (&stream);
	}

	return success;
}

static void
imapx_copy_move_message_cache (CamelFolder *source_folder,
			       CamelFolder *destination_folder,
			       gboolean delete_originals,
			       const gchar *source_uid,
			       const gchar *destination_uid,
			       GCancellable *cancellable)
{
	CamelIMAPXFolder *imapx_source_folder, *imapx_destination_folder;
	gchar *source_filename, *destination_filename;

	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (source_folder));
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (destination_folder));
	g_return_if_fail (source_uid != NULL);
	g_return_if_fail (destination_uid != NULL);

	imapx_source_folder = CAMEL_IMAPX_FOLDER (source_folder);
	imapx_destination_folder = CAMEL_IMAPX_FOLDER (destination_folder);

	source_filename = camel_data_cache_get_filename  (imapx_source_folder->cache, "cur", source_uid);
	if (!g_file_test (source_filename, G_FILE_TEST_EXISTS)) {
		g_free (source_filename);
		return;
	}

	destination_filename = camel_data_cache_get_filename  (imapx_destination_folder->cache, "cur", destination_uid);
	if (!g_file_test (destination_filename, G_FILE_TEST_EXISTS)) {
		GIOStream *stream;

		/* To create the cache folder structure for the message file */
		stream = camel_data_cache_add (imapx_destination_folder->cache, "cur", destination_uid, NULL);
		if (stream) {
			g_clear_object (&stream);

			/* Remove the empty file, it's gonna be replaced with actual message */
			g_unlink (destination_filename);

			if (delete_originals) {
				if (g_rename (source_filename, destination_filename) == -1 && errno != ENOENT) {
					g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, source_filename, destination_filename, g_strerror (errno));
				}
			} else {
				GFile *source, *destination;
				GError *local_error = NULL;

				source = g_file_new_for_path (source_filename);
				destination = g_file_new_for_path (destination_filename);

				if (source && destination &&
				    !g_file_copy (source, destination, G_FILE_COPY_NONE, cancellable, NULL, NULL, &local_error)) {
					if (local_error) {
						g_warning ("%s: Failed to copy '%s' to '%s': %s", G_STRFUNC, source_filename, destination_filename, local_error->message);
					}
				}

				g_clear_object (&source);
				g_clear_object (&destination);
				g_clear_error (&local_error);
			}
		}
	}

	g_free (source_filename);
	g_free (destination_filename);
}

gboolean
camel_imapx_server_copy_message_sync (CamelIMAPXServer *is,
				      CamelIMAPXMailbox *mailbox,
				      CamelIMAPXMailbox *destination,
				      GPtrArray *uids,
				      gboolean delete_originals,
				      gboolean remove_deleted_flags,
				      GCancellable *cancellable,
				      GError **error)
{
	GPtrArray *data_uids;
	gint ii;
	gboolean use_move_command = FALSE;
	CamelIMAPXCommand *ic;
	CamelFolder *folder;
	CamelFolderChangeInfo *changes = NULL;
	GHashTable *source_infos;
	gboolean remove_junk_flags;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (destination), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	if (camel_imapx_mailbox_get_permanentflags (destination) == ~0) {
		/* To get permanent flags. That's okay if the "SELECT" fails here, as it can be
		   due to the folder being write-only; just ignore the error and continue. */
		if (!camel_imapx_server_ensure_selected_sync (is, destination, cancellable, NULL)) {
			;
		}
	}

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	if (!camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error))
		return FALSE;

	folder = imapx_server_ref_folder (is, mailbox);
	g_return_val_if_fail (folder != NULL, FALSE);

	remove_deleted_flags = remove_deleted_flags || (camel_folder_get_flags (folder) & CAMEL_FOLDER_IS_TRASH) != 0;
	remove_junk_flags = (camel_folder_get_flags (folder) & CAMEL_FOLDER_IS_JUNK) != 0;

	/* If we're moving messages, prefer "UID MOVE" if supported. */
	if (delete_originals) {
		g_mutex_lock (&is->priv->stream_lock);

		if (CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, MOVE)) {
			delete_originals = FALSE;
			use_move_command = TRUE;
		}

		g_mutex_unlock (&is->priv->stream_lock);
	}

	source_infos = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, g_object_unref);
	data_uids = g_ptr_array_new ();

	for (ii = 0; ii < uids->len; ii++) {
		CamelMessageInfo *source_info;
		gchar *uid = (gchar *) camel_pstring_strdup (uids->pdata[ii]);

		g_ptr_array_add (data_uids, uid);

		source_info = camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid);
		if (source_info)
			g_hash_table_insert (source_infos, uid, source_info);
	}

	g_ptr_array_sort (data_uids, (GCompareFunc) imapx_uids_array_cmp);

	ii = 0;
	while (ii < data_uids->len && success) {
		struct _uidset_state uidset;
		gint last_index = ii;

		imapx_uidset_init (&uidset, 0, MAX_COMMAND_LEN);

		if (use_move_command)
			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_MOVE_MESSAGE, "UID MOVE ");
		else
			ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_COPY_MESSAGE, "UID COPY ");

		while (ii < data_uids->len) {
			const gchar *uid = (gchar *) g_ptr_array_index (data_uids, ii);

			ii++;

			if (imapx_uidset_add (&uidset, ic, uid) == 1)
				break;
		}

		g_warn_if_fail (imapx_uidset_done (&uidset, ic));

		camel_imapx_command_add (ic, " %M", destination);

		imapx_free_status (is->priv->copyuid_status);
		is->priv->copyuid_status = NULL;

		success = camel_imapx_server_process_command_sync (is, ic,
			use_move_command ? _("Error moving messages") : _("Error copying messages"),
			cancellable, error);

		g_mutex_lock (&is->priv->changes_lock);
		if (camel_folder_change_info_changed (is->priv->changes)) {
			if (!changes) {
				changes = is->priv->changes;
			} else {
				camel_folder_change_info_cat (changes, is->priv->changes);
				camel_folder_change_info_free (is->priv->changes);
			}

			is->priv->changes = camel_folder_change_info_new ();
		}
		g_mutex_unlock (&is->priv->changes_lock);

		if (ic->copy_move_expunged) {
			CamelFolderSummary *summary;

			ic->copy_move_expunged = g_slist_reverse (ic->copy_move_expunged);

			summary = camel_folder_get_folder_summary (folder);
			if (summary) {
				GPtrArray *array;

				array = camel_folder_summary_get_array (summary);
				if (array) {
					GSList *slink;
					GList *removed_uids = NULL, *llink;

					camel_folder_sort_uids (folder, array);

					for (slink = ic->copy_move_expunged; slink; slink = g_slist_next (slink)) {
						guint expunged_idx = GPOINTER_TO_UINT (slink->data) - 1;

						if (expunged_idx < array->len) {
							const gchar *uid = g_ptr_array_index (array, expunged_idx);

							if (uid) {
								removed_uids = g_list_prepend (removed_uids, (gpointer) uid);
								g_ptr_array_remove_index (array, expunged_idx);
							}
						}
					}

					if (removed_uids) {
						CamelFolderSummary *summary;

						summary = camel_folder_get_folder_summary (folder);

						camel_folder_summary_remove_uids (summary, removed_uids);

						for (llink = removed_uids; llink; llink = g_list_next (llink)) {
							const gchar *uid = llink->data;

							if (!changes)
								changes = camel_folder_change_info_new ();

							camel_folder_change_info_remove_uid (changes, uid);

							g_ptr_array_add (array, (gpointer) uid);
						}

						g_list_free (removed_uids);
					}

					camel_folder_summary_free_array (array);
				}
			}
		}

		if (success) {
			struct _status_info *copyuid_status = is->priv->copyuid_status;

			if (ic->status && ic->status->condition == IMAPX_COPYUID)
				copyuid_status = ic->status;

			if (copyuid_status && copyuid_status->u.copyuid.uids &&
			    copyuid_status->u.copyuid.copied_uids &&
			    copyuid_status->u.copyuid.uids->len == copyuid_status->u.copyuid.copied_uids->len) {
				CamelFolder *destination_folder;

				destination_folder = imapx_server_ref_folder (is, destination);
				if (destination_folder) {
					CamelFolderSummary *destination_summary;
					CamelMessageInfo *source_info, *destination_info;
					CamelFolderChangeInfo *dest_changes;
					gint ii;

					destination_summary = camel_folder_get_folder_summary (destination_folder);
					camel_folder_summary_lock (destination_summary);

					dest_changes = camel_folder_change_info_new ();

					for (ii = 0; ii < copyuid_status->u.copyuid.uids->len; ii++) {
						gchar *uid;
						gboolean is_new = FALSE;
						guint32 source_flags;
						CamelNamedFlags *source_user_flags;
						CamelNameValueArray *source_user_tags;

						uid = g_strdup_printf ("%u", g_array_index (copyuid_status->u.copyuid.uids, guint32, ii));
						source_info = g_hash_table_lookup (source_infos, uid);
						g_free (uid);

						if (!source_info)
							continue;

						uid = g_strdup_printf ("%u", g_array_index (copyuid_status->u.copyuid.copied_uids, guint32, ii));
						destination_info = camel_folder_summary_get (destination_summary, uid);

						if (!destination_info) {
							is_new = TRUE;
							destination_info = camel_message_info_clone (source_info, destination_summary);
							camel_message_info_set_uid (destination_info, uid);
						}

						g_free (uid);

						source_flags = camel_message_info_get_flags (source_info);
						source_user_flags = camel_message_info_dup_user_flags (source_info);
						source_user_tags = camel_message_info_dup_user_tags (source_info);

						imapx_set_message_info_flags_for_new_message (
							destination_info,
							source_flags,
							source_user_flags,
							TRUE,
							source_user_tags,
							camel_imapx_mailbox_get_permanentflags (destination));

						camel_named_flags_free (source_user_flags);
						camel_name_value_array_free (source_user_tags);

						if (remove_deleted_flags)
							camel_message_info_set_flags (destination_info, CAMEL_MESSAGE_DELETED, 0);
						if (remove_junk_flags)
							camel_message_info_set_flags (destination_info, CAMEL_MESSAGE_JUNK, 0);
						imapx_copy_move_message_cache (folder, destination_folder, delete_originals || use_move_command,
							camel_message_info_get_uid (source_info),
							camel_message_info_get_uid (destination_info),
							cancellable);
						if (is_new)
							camel_folder_summary_add (destination_summary, destination_info, FALSE);
						camel_folder_change_info_add_uid (dest_changes, camel_message_info_get_uid (destination_info));

						g_clear_object (&destination_info);
					}

					if (camel_folder_change_info_changed (dest_changes)) {
						camel_folder_summary_touch (destination_summary);
						camel_folder_summary_save (destination_summary, NULL);
						camel_folder_changed (destination_folder, dest_changes);
					}

					camel_folder_summary_unlock (destination_summary);
					camel_folder_change_info_free (dest_changes);
					g_object_unref (destination_folder);
				}
			}

			if (delete_originals || use_move_command) {
				gint jj;

				for (jj = last_index; jj < ii; jj++) {
					const gchar *uid = uids->pdata[jj];

					if (delete_originals) {
						camel_folder_delete_message (folder, uid);
					} else {
						if (camel_folder_summary_remove_uid (camel_folder_get_folder_summary (folder), uid)) {
							if (!changes)
								changes = camel_folder_change_info_new ();

							camel_folder_change_info_remove_uid (changes, uid);
						}
					}
				}
			}
		}

		imapx_free_status (is->priv->copyuid_status);
		is->priv->copyuid_status = NULL;

		camel_imapx_command_unref (ic);

		camel_operation_progress (cancellable, ii * 100 / data_uids->len);
	}

	if (changes) {
		if (camel_folder_change_info_changed (changes)) {
			camel_folder_summary_touch (camel_folder_get_folder_summary (folder));
			camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);

			imapx_update_store_summary (folder);

			camel_folder_changed (folder, changes);
		}

		camel_folder_change_info_free (changes);
	}

	g_hash_table_destroy (source_infos);
	g_ptr_array_foreach (data_uids, (GFunc) camel_pstring_free, NULL);
	g_ptr_array_free (data_uids, TRUE);
	g_object_unref (folder);

	return success;
}

static const gchar *
get_month_str (gint month)
{
	static const gchar tm_months[][4] = {
		"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	};

	if (month < 1 || month > 12)
		return NULL;

	return tm_months[month - 1];
}

gboolean
camel_imapx_server_append_message_sync (CamelIMAPXServer *is,
					CamelIMAPXMailbox *mailbox,
					CamelFolderSummary *summary,
					CamelDataCache *message_cache,
					CamelMimeMessage *message,
					const CamelMessageInfo *mi,
					gchar **appended_uid,
					GCancellable *cancellable,
					GError **error)
{
	gchar *uid = NULL, *path = NULL;
	CamelMimeFilter *filter;
	CamelIMAPXCommand *ic;
	CamelMessageInfo *info;
	GIOStream *base_stream;
	GOutputStream *output_stream;
	GOutputStream *filter_stream;
	gint res;
	time_t date_time;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), FALSE);
	g_return_val_if_fail (CAMEL_IS_DATA_CACHE (message_cache), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (message), FALSE);
	/* CamelMessageInfo can be NULL. */

	/* That's okay if the "SELECT" fails here, as it can be due to
	   the folder being write-only; just ignore the error and continue. */
	if (!camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, NULL)) {
		;
	}

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	/* Append just assumes we have no/a dodgy connection.  We dump
	 * stuff into the 'new' directory, and let the summary know it's
	 * there.  Then we fire off a no-reply job which will asynchronously
	 * upload the message at some point in the future, and fix up the
	 * summary to match */

	/* chen cleanup this later */
	uid = imapx_get_temp_uid ();
	base_stream = camel_data_cache_add (message_cache, "new", uid, error);
	if (base_stream == NULL) {
		g_prefix_error (error, _("Cannot create spool file: "));
		g_free (uid);
		return FALSE;
	}

	output_stream = g_io_stream_get_output_stream (base_stream);
	filter = camel_mime_filter_canon_new (CAMEL_MIME_FILTER_CANON_CRLF);
	filter_stream = camel_filter_output_stream_new (output_stream, filter);

	g_filter_output_stream_set_close_base_stream (
		G_FILTER_OUTPUT_STREAM (filter_stream), FALSE);

	res = camel_data_wrapper_write_to_output_stream_sync (
		CAMEL_DATA_WRAPPER (message),
		filter_stream, cancellable, error);

	g_object_unref (base_stream);
	g_object_unref (filter_stream);
	g_object_unref (filter);

	if (res == -1) {
		g_prefix_error (error, _("Cannot create spool file: "));
		camel_data_cache_remove (message_cache, "new", uid, NULL);
		g_free (uid);
		return FALSE;
	}

	date_time = camel_mime_message_get_date (message, NULL);
	path = camel_data_cache_get_filename (message_cache, "new", uid);
	info = camel_folder_summary_info_new_from_message (summary, message);

	camel_message_info_set_abort_notifications (info, TRUE);
	camel_message_info_set_uid (info, uid);

	if (mi != NULL) {
		struct icaltimetype icaltime;

		camel_message_info_property_lock (mi);

		camel_message_info_set_flags (info, ~0, camel_message_info_get_flags (mi));
		camel_message_info_set_size (info, camel_message_info_get_size (mi));
		camel_message_info_take_user_flags (info,
			camel_named_flags_copy (camel_message_info_get_user_flags (mi)));
		camel_message_info_take_user_tags (info,
			camel_name_value_array_copy (camel_message_info_get_user_tags (mi)));

		if (date_time > 0) {
			icaltime = icaltime_from_timet_with_zone (date_time, FALSE, NULL);
			if (!icaltime_is_valid_time (icaltime))
				date_time = -1;
		}

		if (date_time <= 0)
			date_time = camel_message_info_get_date_received (mi);

		if (date_time > 0) {
			icaltime = icaltime_from_timet_with_zone (date_time, FALSE, NULL);
			if (!icaltime_is_valid_time (icaltime))
				date_time = -1;
		}

		camel_message_info_property_unlock (mi);
	}

	if (!camel_message_info_get_size (info)) {
		camel_message_info_set_size (info, camel_data_wrapper_calculate_size_sync (CAMEL_DATA_WRAPPER (message), NULL, NULL));
	}

	g_free (uid);

	if (camel_mime_message_has_attachment (message))
		camel_message_info_set_flags (info, CAMEL_MESSAGE_ATTACHMENTS, CAMEL_MESSAGE_ATTACHMENTS);

	if (date_time > 0) {
		gchar *date_time_str;
		struct tm stm;

		gmtime_r (&date_time, &stm);

		/* Store always in UTC */
		date_time_str = g_strdup_printf (
			"\"%02d-%s-%04d %02d:%02d:%02d +0000\"",
			stm.tm_mday,
			get_month_str (stm.tm_mon + 1),
			stm.tm_year + 1900,
			stm.tm_hour,
			stm.tm_min,
			stm.tm_sec);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_APPEND_MESSAGE, "APPEND %M %F %t %P",
			mailbox,
			camel_message_info_get_flags (info),
			camel_message_info_get_user_flags (info),
			date_time_str,
			path);

		g_free (date_time_str);
	} else {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_APPEND_MESSAGE, "APPEND %M %F %P",
			mailbox,
			camel_message_info_get_flags (info),
			camel_message_info_get_user_flags (info),
			path);
	}

	camel_message_info_set_abort_notifications (info, FALSE);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error appending message"), cancellable, error);

	if (success) {
		CamelIMAPXFolder *imapx_folder;
		CamelFolder *folder;
		CamelMessageInfo *clone;
		gchar *cur, *old_uid;
		guint32 uidvalidity;

		folder = imapx_server_ref_folder (is, mailbox);
		g_return_val_if_fail (folder != NULL, FALSE);

		uidvalidity = camel_imapx_mailbox_get_uidvalidity (mailbox);

		imapx_folder = CAMEL_IMAPX_FOLDER (folder);

		/* Append done.  If we the server supports UIDPLUS we will get
		 * an APPENDUID response with the new uid.  This lets us move the
		 * message we have directly to the cache and also create a correctly
		 * numbered MessageInfo, without losing any information.  Otherwise
		 * we have to wait for the server to let us know it was appended. */

		clone = camel_message_info_clone (info, camel_folder_get_folder_summary (folder));
		old_uid = g_strdup (camel_message_info_get_uid (info));

		if (ic->status && ic->status->condition == IMAPX_APPENDUID) {
			c (is->priv->tagprefix, "Got appenduid %u %u\n", (guint32) ic->status->u.appenduid.uidvalidity, ic->status->u.appenduid.uid);
			if (ic->status->u.appenduid.uidvalidity == uidvalidity) {
				gchar *uid;

				uid = g_strdup_printf ("%u", ic->status->u.appenduid.uid);
				camel_message_info_set_uid (clone, uid);

				cur = camel_data_cache_get_filename  (imapx_folder->cache, "cur", uid);
				if (g_rename (path, cur) == -1 && errno != ENOENT) {
					g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, path, cur, g_strerror (errno));
				}

				imapx_set_message_info_flags_for_new_message (
					clone,
					camel_message_info_get_flags (info),
					camel_message_info_get_user_flags (info),
					TRUE,
					camel_message_info_get_user_tags (info),
					camel_imapx_mailbox_get_permanentflags (mailbox));

				camel_folder_summary_add (camel_folder_get_folder_summary (folder), clone, TRUE);

				g_mutex_lock (&is->priv->changes_lock);
				camel_folder_change_info_add_uid (is->priv->changes, camel_message_info_get_uid (clone));
				g_mutex_unlock (&is->priv->changes_lock);

				camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);

				if (appended_uid)
					*appended_uid = uid;
				else
					g_free (uid);

				g_clear_object (&clone);

				g_free (cur);
			} else {
				c (is->priv->tagprefix, "but uidvalidity changed \n");
			}
		}

		camel_data_cache_remove (imapx_folder->cache, "new", old_uid, NULL);
		g_free (old_uid);

		camel_imapx_command_unref (ic);
		g_clear_object (&clone);
		g_object_unref (folder);
	}

	g_clear_object (&info);
	g_free (path);

	return success;
}

gboolean
camel_imapx_server_noop_sync (CamelIMAPXServer *is,
			      CamelIMAPXMailbox *mailbox,
			      GCancellable *cancellable,
			      GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	/* Mailbox may be NULL. */

	if (mailbox)
		success = camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error);

	if (success) {
		CamelIMAPXCommand *ic;

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_NOOP, "NOOP");

		success = camel_imapx_server_process_command_sync (is, ic, _("Error performing NOOP"), cancellable, error);

		camel_imapx_command_unref (ic);
	}

	return success;
}

/* ********************************************************************** */

static gint
imapx_refresh_info_uid_cmp (gconstpointer ap,
                            gconstpointer bp,
                            gboolean ascending)
{
	guint av, bv;

	av = g_ascii_strtoull ((const gchar *) ap, NULL, 10);
	bv = g_ascii_strtoull ((const gchar *) bp, NULL, 10);

	if (av < bv)
		return ascending ? -1 : 1;
	else if (av > bv)
		return ascending ? 1 : -1;
	else
		return 0;
}

static gint
imapx_uids_array_cmp (gconstpointer ap,
                      gconstpointer bp)
{
	const gchar **a = (const gchar **) ap;
	const gchar **b = (const gchar **) bp;

	return imapx_refresh_info_uid_cmp (*a, *b, TRUE);
}

static gint
imapx_uids_desc_cmp (gconstpointer ap,
		     gconstpointer bp)
{
	const gchar *a = (const gchar *) ap;
	const gchar *b = (const gchar *) bp;

	return imapx_refresh_info_uid_cmp (a, b, FALSE);
}

static void
imapx_server_process_fetch_changes_infos (CamelIMAPXServer *is,
					  CamelIMAPXMailbox *mailbox,
					  CamelFolder *folder,
					  GHashTable *infos,
					  GHashTable *known_uids,
					  GSList **out_fetch_summary_uids,
					  guint64 from_uidl,
					  guint64 to_uidl)
{
	GHashTableIter iter;
	gpointer key, value;
	CamelFolderSummary *summary;

	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (is));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (CAMEL_IS_FOLDER (folder));
	g_return_if_fail (infos != NULL);

	if (out_fetch_summary_uids)
		g_return_if_fail (*out_fetch_summary_uids == NULL);

	summary = camel_folder_get_folder_summary (folder);

	g_hash_table_iter_init (&iter, infos);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		const gchar *uid = key;
		FetchChangesInfo *nfo = value;
		CamelMessageInfo *minfo;

		if (!uid || !nfo)
			continue;

		if (known_uids)
			g_hash_table_insert (known_uids, (gpointer) camel_pstring_strdup (uid), GINT_TO_POINTER (1));

		if (!camel_folder_summary_check_uid (summary, uid) ||
		    !(minfo = camel_folder_summary_get (summary, uid))) {
			if (out_fetch_summary_uids) {
				*out_fetch_summary_uids = g_slist_prepend (*out_fetch_summary_uids,
					(gpointer) camel_pstring_strdup (uid));
			}

			continue;
		}

		if (imapx_update_message_info_flags (
			minfo,
			nfo->server_flags,
			nfo->server_user_flags,
			camel_imapx_mailbox_get_permanentflags (mailbox),
			folder, FALSE)) {
			g_mutex_lock (&is->priv->changes_lock);
			camel_folder_change_info_change_uid (is->priv->changes, camel_message_info_get_uid (minfo));
			g_mutex_unlock (&is->priv->changes_lock);
		}

		g_clear_object (&minfo);
	}
}

static gboolean
imapx_server_fetch_changes (CamelIMAPXServer *is,
			    CamelIMAPXMailbox *mailbox,
			    CamelFolder *folder,
			    GHashTable *known_uids,
			    guint64 from_uidl,
			    guint64 to_uidl,
			    GCancellable *cancellable,
			    GError **error)
{
	GSList *fetch_summary_uids = NULL;
	GHashTable *infos; /* uid ~> FetchChangesInfo */
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	if (!from_uidl)
		from_uidl = 1;

	if (to_uidl > 0) {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_REFRESH_INFO, "UID FETCH %lld:%lld (UID FLAGS)", from_uidl, to_uidl);
	} else {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_REFRESH_INFO, "UID FETCH %lld:* (UID FLAGS)", from_uidl);
	}

	g_return_val_if_fail (is->priv->fetch_changes_mailbox == NULL, FALSE);
	g_return_val_if_fail (is->priv->fetch_changes_folder == NULL, FALSE);
	g_return_val_if_fail (is->priv->fetch_changes_infos == NULL, FALSE);

	infos = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, fetch_changes_info_free);

	is->priv->fetch_changes_mailbox = mailbox;
	is->priv->fetch_changes_folder = folder;
	is->priv->fetch_changes_infos = infos;
	is->priv->fetch_changes_last_progress = 0;

	camel_operation_push_message (cancellable,
		/* Translators: The first “%s” is replaced with an account name and the second “%s”
		   is replaced with a full path name. The spaces around “:” are intentional, as
		   the whole “%s : %s” is meant as an absolute identification of the folder. */
		_("Scanning for changed messages in “%s : %s”"),
		camel_service_get_display_name (CAMEL_SERVICE (camel_folder_get_parent_store (folder))),
		camel_folder_get_full_name (folder));

	success = camel_imapx_server_process_command_sync (is, ic, _("Error scanning changes"), cancellable, error);

	camel_operation_pop_message (cancellable);
	camel_imapx_command_unref (ic);

	/* It can partly succeed. */
	imapx_server_process_fetch_changes_infos (is, mailbox, folder, infos, known_uids, &fetch_summary_uids, from_uidl, to_uidl);

	g_hash_table_remove_all (infos);

	if (success && fetch_summary_uids) {
		struct _uidset_state uidset;
		GSList *link;

		ic = NULL;
		imapx_uidset_init (&uidset, 0, 100);

		camel_operation_push_message (cancellable,
			/* Translators: The first “%s” is replaced with an account name and the second “%s”
			   is replaced with a full path name. The spaces around “:” are intentional, as
			   the whole “%s : %s” is meant as an absolute identification of the folder. */
			_("Fetching summary information for new messages in “%s : %s”"),
			camel_service_get_display_name (CAMEL_SERVICE (camel_folder_get_parent_store (folder))),
			camel_folder_get_full_name (folder));

		fetch_summary_uids = g_slist_sort (fetch_summary_uids, imapx_uids_desc_cmp);

		for (link = fetch_summary_uids; link; link = g_slist_next (link)) {
			const gchar *uid = link->data;

			if (!uid)
				continue;

			if (!ic)
				ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_REFRESH_INFO, "UID FETCH ");

			if (imapx_uidset_add (&uidset, ic, uid) == 1 || (!link->next && ic && imapx_uidset_done (&uidset, ic))) {
				GError *local_error = NULL;
				gboolean bodystructure_enabled;
				CamelIMAPXStore *imapx_store;

				imapx_store = camel_imapx_server_ref_store (is);
				bodystructure_enabled = imapx_store && camel_imapx_store_get_bodystructure_enabled (imapx_store);

				if (bodystructure_enabled)
					camel_imapx_command_add (ic, " (RFC822.SIZE RFC822.HEADER BODYSTRUCTURE FLAGS)");
				else
					camel_imapx_command_add (ic, " (RFC822.SIZE RFC822.HEADER FLAGS)");

				success = camel_imapx_server_process_command_sync (is, ic, _("Error fetching message info"), cancellable, &local_error);

				camel_imapx_command_unref (ic);
				ic = NULL;

				/* Some servers can return broken BODYSTRUCTURE response, thus disable it
				   even when it's not 100% sure the BODYSTRUCTURE response was the broken one. */
				if (bodystructure_enabled && !success &&
				    g_error_matches (local_error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED)) {
					camel_imapx_store_set_bodystructure_enabled (imapx_store, FALSE);
					local_error->domain = CAMEL_IMAPX_SERVER_ERROR;
					local_error->code = CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT;
				}

				g_clear_object (&imapx_store);

				if (local_error)
					g_propagate_error (error, local_error);

				if (!success)
					break;

				imapx_server_process_fetch_changes_infos (is, mailbox, folder, infos, NULL, NULL, 0, 0);
				g_hash_table_remove_all (infos);
			}
		}

		camel_operation_pop_message (cancellable);

		imapx_server_process_fetch_changes_infos (is, mailbox, folder, infos, NULL, NULL, 0, 0);
	}

	g_return_val_if_fail (is->priv->fetch_changes_mailbox == mailbox, FALSE);
	g_return_val_if_fail (is->priv->fetch_changes_folder == folder, FALSE);
	g_return_val_if_fail (is->priv->fetch_changes_infos == infos, FALSE);

	is->priv->fetch_changes_mailbox = NULL;
	is->priv->fetch_changes_folder = NULL;
	is->priv->fetch_changes_infos = NULL;

	g_slist_free_full (fetch_summary_uids, (GDestroyNotify) camel_pstring_free);
	g_hash_table_destroy (infos);

	g_mutex_lock (&is->priv->changes_lock);

	/* Notify about new messages, thus they are shown in the UI early. */
	if (camel_folder_change_info_changed (is->priv->changes)) {
		CamelFolderChangeInfo *changes;

		changes = is->priv->changes;
		is->priv->changes = camel_folder_change_info_new ();

		g_mutex_unlock (&is->priv->changes_lock);

		camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);
		imapx_update_store_summary (folder);
		camel_folder_changed (folder, changes);
		camel_folder_change_info_free (changes);
	} else {
		g_mutex_unlock (&is->priv->changes_lock);
	}

	return success;
}

static gboolean
camel_imapx_server_skip_old_flags_update (CamelStore *store)
{
	CamelSession *session;
	GNetworkMonitor *network_monitor;
	gboolean skip_old_flags_update = FALSE;

	if (!CAMEL_IS_STORE (store))
		return FALSE;

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return skip_old_flags_update;

	network_monitor = camel_session_ref_network_monitor (session);

	skip_old_flags_update = network_monitor && g_network_monitor_get_network_metered (network_monitor);

	g_clear_object (&network_monitor);
	g_clear_object (&session);

	return skip_old_flags_update;
}

gboolean
camel_imapx_server_refresh_info_sync (CamelIMAPXServer *is,
				      CamelIMAPXMailbox *mailbox,
				      GCancellable *cancellable,
				      GError **error)
{
	CamelIMAPXCommand *ic;
	CamelIMAPXMailbox *selected_mailbox;
	CamelIMAPXSummary *imapx_summary;
	CamelFolder *folder;
	CamelFolderChangeInfo *changes;
	GHashTable *known_uids;
	guint32 messages;
	guint32 unseen;
	guint32 uidnext;
	guint32 uidvalidity;
	guint64 highestmodseq;
	guint32 total;
	guint64 uidl;
	gboolean need_rescan, skip_old_flags_update;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	selected_mailbox = camel_imapx_server_ref_pending_or_selected (is);
	if (selected_mailbox == mailbox) {
		success = camel_imapx_server_noop_sync (is, mailbox, cancellable, error);
	} else {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_STATUS, "STATUS %M (%t)", mailbox, is->priv->status_data_items);

		success = camel_imapx_server_process_command_sync (is, ic, _("Error running STATUS"), cancellable, error);

		camel_imapx_command_unref (ic);
	}
	g_clear_object (&selected_mailbox);

	if (!success)
		return FALSE;

	folder = imapx_server_ref_folder (is, mailbox);
	g_return_val_if_fail (folder != NULL, FALSE);

	imapx_summary = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (folder));

	messages = camel_imapx_mailbox_get_messages (mailbox);
	unseen = camel_imapx_mailbox_get_unseen (mailbox);
	uidnext = camel_imapx_mailbox_get_uidnext (mailbox);
	uidvalidity = camel_imapx_mailbox_get_uidvalidity (mailbox);
	highestmodseq = camel_imapx_mailbox_get_highestmodseq (mailbox);
	total = camel_folder_summary_count (CAMEL_FOLDER_SUMMARY (imapx_summary));

	need_rescan =
		(uidvalidity > 0 && uidvalidity != imapx_summary->validity) ||
		total != messages ||
		imapx_summary->uidnext != uidnext ||
		camel_folder_summary_get_unread_count (CAMEL_FOLDER_SUMMARY (imapx_summary)) != unseen ||
		imapx_summary->modseq != highestmodseq;

	if (!need_rescan) {
		g_object_unref (folder);
		return TRUE;
	}

	if (!camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error)) {
		g_object_unref (folder);
		return FALSE;
	}

	if (is->priv->use_qresync && imapx_summary->modseq > 0 && uidvalidity > 0) {
		if (total != messages ||
		    camel_folder_summary_get_unread_count (CAMEL_FOLDER_SUMMARY (imapx_summary)) != unseen ||
		    imapx_summary->modseq != highestmodseq) {
			c (
				is->priv->tagprefix,
				"Eep, after QRESYNC we're out of sync. "
				"total %u / %u, unread %u / %u, modseq %"
				G_GUINT64_FORMAT " / %" G_GUINT64_FORMAT " in folder:'%s'\n",
				total, messages,
				camel_folder_summary_get_unread_count (CAMEL_FOLDER_SUMMARY (imapx_summary)),
				unseen,
				imapx_summary->modseq,
				highestmodseq,
				camel_folder_get_full_name (folder));
		} else {
			imapx_summary->uidnext = uidnext;

			camel_folder_summary_touch (CAMEL_FOLDER_SUMMARY (imapx_summary));
			camel_folder_summary_save (CAMEL_FOLDER_SUMMARY (imapx_summary), NULL);
			imapx_update_store_summary (folder);

			c (
				is->priv->tagprefix,
				"OK, after QRESYNC we're still in sync. "
				"total %u / %u, unread %u / %u, modseq %"
				G_GUINT64_FORMAT " / %" G_GUINT64_FORMAT " in folder:'%s'\n",
				total, messages,
				camel_folder_summary_get_unread_count (CAMEL_FOLDER_SUMMARY (imapx_summary)),
				unseen,
				imapx_summary->modseq,
				highestmodseq,
				camel_folder_get_full_name (folder));
			g_object_unref (folder);
			return TRUE;
		}
	}

	if (total > 0) {
		gchar *uid = camel_imapx_dup_uid_from_summary_index (folder, total - 1);
		if (uid) {
			uidl = g_ascii_strtoull (uid, NULL, 10);
			g_free (uid);
			uidl++;
		} else {
			uidl = 1;
		}
	} else {
		uidl = 1;
	}

	camel_folder_summary_prepare_fetch_all (CAMEL_FOLDER_SUMMARY (imapx_summary), NULL);

	known_uids = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, NULL);

	skip_old_flags_update = camel_imapx_server_skip_old_flags_update (camel_folder_get_parent_store (folder));

	success = imapx_server_fetch_changes (is, mailbox, folder, known_uids, uidl, 0, cancellable, error);
	if (success && uidl != 1 && !skip_old_flags_update)
		success = imapx_server_fetch_changes (is, mailbox, folder, known_uids, 0, uidl, cancellable, error);

	if (success) {
		imapx_summary->modseq = highestmodseq;
		imapx_summary->uidnext = uidnext;

		camel_folder_summary_touch (CAMEL_FOLDER_SUMMARY (imapx_summary));
	}

	g_mutex_lock (&is->priv->changes_lock);

	changes = is->priv->changes;
	is->priv->changes = camel_folder_change_info_new ();

	g_mutex_unlock (&is->priv->changes_lock);

	if (success && !skip_old_flags_update) {
		GList *removed = NULL;
		GPtrArray *array;
		gint ii;

		camel_folder_summary_lock (CAMEL_FOLDER_SUMMARY (imapx_summary));

		array = camel_folder_summary_get_array (CAMEL_FOLDER_SUMMARY (imapx_summary));
		for (ii = 0; array && ii < array->len; ii++) {
			const gchar *uid = array->pdata[ii];

			if (!uid)
				continue;

			if (!g_hash_table_contains (known_uids, uid)) {
				removed = g_list_prepend (removed, (gpointer) uid);
				camel_folder_change_info_remove_uid (changes, uid);
			}
		}

		camel_folder_summary_unlock (CAMEL_FOLDER_SUMMARY (imapx_summary));

		if (removed != NULL) {
			camel_folder_summary_remove_uids (CAMEL_FOLDER_SUMMARY (imapx_summary), removed);
			camel_folder_summary_touch (CAMEL_FOLDER_SUMMARY (imapx_summary));

			/* Shares UIDs with the 'array'. */
			g_list_free (removed);
		}

		camel_folder_summary_free_array (array);
	}

	camel_folder_summary_save (CAMEL_FOLDER_SUMMARY (imapx_summary), NULL);
	imapx_update_store_summary (folder);

	if (camel_folder_change_info_changed (changes))
		camel_folder_changed (folder, changes);

	camel_folder_change_info_free (changes);

	g_hash_table_destroy (known_uids);
	g_object_unref (folder);

	return success;
}

static void
imapx_sync_free_user (GArray *user_set)
{
	gint i;

	if (user_set == NULL)
		return;

	for (i = 0; i < user_set->len; i++) {
		struct _imapx_flag_change *flag_change = &g_array_index (user_set, struct _imapx_flag_change, i);
		GPtrArray *infos = flag_change->infos;
		gint j;

		for (j = 0; j < infos->len; j++) {
			CamelMessageInfo *info = g_ptr_array_index (infos, j);
			g_clear_object (&info);
		}

		g_ptr_array_free (infos, TRUE);
		g_free (flag_change->name);
	}
	g_array_free (user_set, TRUE);
}

static void
imapx_unset_folder_flagged_flag (CamelFolderSummary *summary,
				 GPtrArray *changed_uids,
				 gboolean except_deleted_messages)
{
	CamelMessageInfo *info;
	gboolean changed = FALSE;
	gint ii;

	g_return_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary));
	g_return_if_fail (changed_uids != NULL);

	for (ii = 0; ii < changed_uids->len; ii++) {
		info = camel_folder_summary_get (summary, changed_uids->pdata[ii]);

		if (info) {
			/* some infos could be only 'dirty' (needed to save into summary) */
			if (camel_message_info_get_folder_flagged (info) &&
			   (!except_deleted_messages || (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED) == 0)) {
				camel_message_info_set_folder_flagged (info, FALSE);
				changed = TRUE;
			}

			g_clear_object (&info);
		}
	}

	if (changed) {
		camel_folder_summary_touch (summary);
		camel_folder_summary_save (summary, NULL);
	}
}

gboolean
camel_imapx_server_sync_changes_sync (CamelIMAPXServer *is,
				      CamelIMAPXMailbox *mailbox,
				      gboolean can_influence_flags,
				      GCancellable *cancellable,
				      GError **error)
{
	guint i, jj, on, on_orset, off_orset;
	GPtrArray *changed_uids;
	GArray *on_user = NULL, *off_user = NULL;
	CamelFolder *folder;
	CamelMessageInfo *info;
	GHashTable *stamps;
	guint32 permanentflags;
	struct _uidset_state uidset;
	gint unread_change = 0;
	gboolean use_real_junk_path = FALSE;
	gboolean use_real_trash_path = FALSE;
	gboolean remove_deleted_flags = FALSE;
	gboolean is_real_junk_folder = FALSE;
	gboolean nothing_to_do;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	folder = imapx_server_ref_folder (is, mailbox);
	g_return_val_if_fail (folder != NULL, FALSE);

	/* We calculate two masks, a mask of all flags which have been
	 * turned off and a mask of all flags which have been turned
	 * on. If either of these aren't 0, then we have work to do,
	 * and we fire off a job to do it.
	 *
	 * User flags are a bit more tricky, we rely on the user
	 * flags being sorted, and then we create a bunch of lists;
	 * one for each flag being turned off, including each
	 * info being turned off, and one for each flag being turned on.
	 */
	changed_uids = camel_folder_summary_get_changed (camel_folder_get_folder_summary (folder));

	if (changed_uids->len == 0) {
		camel_folder_free_uids (folder, changed_uids);
		g_object_unref (folder);
		return TRUE;
	}

	camel_folder_sort_uids (folder, changed_uids);
	stamps = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, NULL);

	if (can_influence_flags) {
		CamelIMAPXSettings *settings;

		settings = camel_imapx_server_ref_settings (is);

		use_real_junk_path = camel_imapx_settings_get_use_real_junk_path (settings);
		if (use_real_junk_path) {
			CamelFolder *junk_folder = NULL;
			gchar *real_junk_path;

			real_junk_path = camel_imapx_settings_dup_real_junk_path (settings);
			if (real_junk_path) {
				junk_folder = camel_store_get_folder_sync (
					camel_folder_get_parent_store (folder),
					real_junk_path, 0, cancellable, NULL);
			}

			is_real_junk_folder = junk_folder == folder;

			use_real_junk_path = junk_folder != NULL;

			g_clear_object (&junk_folder);
			g_free (real_junk_path);
		}

		use_real_trash_path = camel_imapx_settings_get_use_real_trash_path (settings);
		if (use_real_trash_path) {
			CamelFolder *trash_folder = NULL;
			gchar *real_trash_path;

			real_trash_path = camel_imapx_settings_dup_real_trash_path (settings);
			if (real_trash_path)
				trash_folder = camel_store_get_folder_sync (
					camel_folder_get_parent_store (folder),
					real_trash_path, 0, cancellable, NULL);

			/* Remove deleted flags in all but the trash folder itself */
			remove_deleted_flags = !trash_folder || trash_folder != folder;

			use_real_trash_path = trash_folder != NULL;

			g_clear_object (&trash_folder);
			g_free (real_trash_path);
		}

		g_object_unref (settings);
	}

	if (changed_uids->len > 20)
		camel_folder_summary_prepare_fetch_all (camel_folder_get_folder_summary (folder), NULL);

	camel_folder_summary_lock (camel_folder_get_folder_summary (folder));

	off_orset = on_orset = 0;
	for (i = 0; i < changed_uids->len; i++) {
		CamelIMAPXMessageInfo *xinfo;
		guint32 flags, sflags;
		const CamelNamedFlags *local_uflags, *server_uflags;
		const gchar *uid;
		guint j = 0;

		uid = g_ptr_array_index (changed_uids, i);

		info = camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid);
		xinfo = info ? CAMEL_IMAPX_MESSAGE_INFO (info) : NULL;

		if (!info || !xinfo) {
			g_clear_object (&info);
			continue;
		}

		if (!camel_message_info_get_folder_flagged (info)) {
			g_clear_object (&info);
			continue;
		}

		camel_message_info_property_lock (info);

		g_hash_table_insert (stamps, (gpointer) camel_message_info_pooldup_uid (info),
			GUINT_TO_POINTER (camel_message_info_get_folder_flagged_stamp (info)));

		flags = camel_message_info_get_flags (info) & CAMEL_IMAPX_SERVER_FLAGS;
		sflags = camel_imapx_message_info_get_server_flags (xinfo) & CAMEL_IMAPX_SERVER_FLAGS;

		if (can_influence_flags) {
			gboolean move_to_real_junk;
			gboolean move_to_real_trash;
			gboolean move_to_inbox;

			move_to_real_junk =
				use_real_junk_path &&
				(flags & CAMEL_MESSAGE_JUNK);

			move_to_real_trash =
				use_real_trash_path && remove_deleted_flags &&
				(flags & CAMEL_MESSAGE_DELETED);

			move_to_inbox = is_real_junk_folder &&
				!move_to_real_junk &&
				!move_to_real_trash &&
				(camel_message_info_get_flags (info) & CAMEL_MESSAGE_NOTJUNK) != 0;

			if (move_to_real_junk)
				camel_imapx_folder_add_move_to_real_junk (
					CAMEL_IMAPX_FOLDER (folder), uid);

			if (move_to_real_trash)
				camel_imapx_folder_add_move_to_real_trash (
					CAMEL_IMAPX_FOLDER (folder), uid);

			if (move_to_inbox)
				camel_imapx_folder_add_move_to_inbox (
					CAMEL_IMAPX_FOLDER (folder), uid);
		}

		if (flags != sflags) {
			off_orset |= (flags ^ sflags) & ~flags;
			on_orset |= (flags ^ sflags) & flags;
		}

		local_uflags = camel_message_info_get_user_flags (info);
		server_uflags = camel_imapx_message_info_get_server_user_flags (xinfo);

		if (!camel_named_flags_equal (local_uflags, server_uflags)) {
			guint ii, jj, llen, slen;

			llen = local_uflags ? camel_named_flags_get_length (local_uflags) : 0;
			slen = server_uflags ? camel_named_flags_get_length (server_uflags) : 0;
			for (ii = 0, jj = 0; ii < llen || jj < slen;) {
				gint res;

				if (ii < llen) {
					const gchar *local_name = camel_named_flags_get (local_uflags, ii);

					if (jj < slen) {
						const gchar *server_name = camel_named_flags_get (server_uflags, jj);

						res = g_strcmp0 (local_name, server_name);
					} else if (local_name && *local_name)
						res = -1;
					else {
						ii++;
						continue;
					}
				} else {
					res = 1;
				}

				if (res == 0) {
					ii++;
					jj++;
				} else {
					GArray *user_set;
					const gchar *user_flag_name;
					struct _imapx_flag_change *change = NULL, add = { 0 };

					if (res < 0) {
						if (on_user == NULL)
							on_user = g_array_new (FALSE, FALSE, sizeof (struct _imapx_flag_change));
						user_set = on_user;
						user_flag_name = camel_named_flags_get (local_uflags, ii);
						ii++;
					} else {
						if (off_user == NULL)
							off_user = g_array_new (FALSE, FALSE, sizeof (struct _imapx_flag_change));
						user_set = off_user;
						user_flag_name = camel_named_flags_get (server_uflags, jj);
						jj++;
					}

					/* Could sort this and binary search */
					for (j = 0; j < user_set->len; j++) {
						change = &g_array_index (user_set, struct _imapx_flag_change, j);
						if (g_strcmp0 (change->name, user_flag_name) == 0)
							goto found;
					}
					add.name = g_strdup (user_flag_name);
					add.infos = g_ptr_array_new ();
					g_array_append_val (user_set, add);
					change = &add;
				found:
					g_object_ref (info);
					g_ptr_array_add (change->infos, info);
				}
			}
		}

		camel_message_info_property_unlock (info);

		g_clear_object (&info);
	}

	camel_folder_summary_unlock (camel_folder_get_folder_summary (folder));

	nothing_to_do =
		(on_orset == 0) &&
		(off_orset == 0) &&
		(on_user == NULL) &&
		(off_user == NULL);

	if (nothing_to_do) {
		imapx_sync_free_user (on_user);
		imapx_sync_free_user (off_user);
		imapx_unset_folder_flagged_flag (camel_folder_get_folder_summary (folder), changed_uids, remove_deleted_flags);
		camel_folder_free_uids (folder, changed_uids);
		g_hash_table_destroy (stamps);
		g_object_unref (folder);
		return TRUE;
	}

	if (!camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error)) {
		imapx_sync_free_user (on_user);
		imapx_sync_free_user (off_user);
		camel_folder_free_uids (folder, changed_uids);
		g_hash_table_destroy (stamps);
		g_object_unref (folder);
		return FALSE;
	}

	permanentflags = camel_imapx_mailbox_get_permanentflags (mailbox);

	success = TRUE;
	for (on = 0; on < 2 && success; on++) {
		guint32 orset = on ? on_orset : off_orset;
		GArray *user_set = on ? on_user : off_user;

		for (jj = 0; jj < G_N_ELEMENTS (flags_table) && success; jj++) {
			guint32 flag = flags_table[jj].flag;
			CamelIMAPXCommand *ic = NULL;

			if ((orset & flag) == 0)
				continue;

			c (is->priv->tagprefix, "checking/storing %s flags '%s'\n", on ? "on" : "off", flags_table[jj].name);
			imapx_uidset_init (&uidset, 0, 100);
			for (i = 0; i < changed_uids->len && success; i++) {
				CamelMessageInfo *info;
				CamelIMAPXMessageInfo *xinfo;
				gboolean remove_deleted_flag;
				guint32 flags;
				guint32 sflags;
				gint send;

				/* the 'stamps' hash table contains only those uid-s,
				   which were also flagged, not only 'dirty' */
				if (!g_hash_table_contains (stamps, changed_uids->pdata[i]))
					continue;

				info = camel_folder_summary_get (camel_folder_get_folder_summary (folder), changed_uids->pdata[i]);
				xinfo = info ? CAMEL_IMAPX_MESSAGE_INFO (info) : NULL;

				if (!info || !xinfo) {
					g_clear_object (&info);
					continue;
				}

				flags = (camel_message_info_get_flags (info) & CAMEL_IMAPX_SERVER_FLAGS) & permanentflags;
				sflags = (camel_imapx_message_info_get_server_flags (xinfo) & CAMEL_IMAPX_SERVER_FLAGS) & permanentflags;
				send = 0;

				remove_deleted_flag =
					remove_deleted_flags &&
					(flags & CAMEL_MESSAGE_DELETED);

				if (remove_deleted_flag) {
					/* Remove the DELETED flag so the
					 * message appears normally in the
					 * real Trash folder when copied. */
					flags &= ~CAMEL_MESSAGE_DELETED;
				}

				if ( (on && (((flags ^ sflags) & flags) & flag))
				     || (!on && (((flags ^ sflags) & ~flags) & flag))) {
					if (ic == NULL) {
						ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_SYNC_CHANGES, "UID STORE ");
					}
					send = imapx_uidset_add (&uidset, ic, camel_message_info_get_uid (info));
				}
				if (send == 1 || (i == changed_uids->len - 1 && ic && imapx_uidset_done (&uidset, ic))) {
					camel_imapx_command_add (ic, " %tFLAGS.SILENT (%t)", on ? "+" : "-", flags_table[jj].name);

					success = camel_imapx_server_process_command_sync (is, ic, _("Error syncing changes"), cancellable, error);

					camel_imapx_command_unref (ic);
					ic = NULL;

					if (!success)
						break;
				}
				if (flag == CAMEL_MESSAGE_SEEN) {
					/* Remember how the server's unread count will change if this
					 * command succeeds */
					if (on)
						unread_change--;
					else
						unread_change++;
				}

				/* The second round and the server doesn't support saving user flags,
				   thus store them at least locally */
				if (on && (permanentflags & CAMEL_MESSAGE_USER) == 0) {
					camel_imapx_message_info_take_server_user_flags (xinfo,
						camel_message_info_dup_user_flags (info));
				}

				g_clear_object (&info);
			}

			if (ic && imapx_uidset_done (&uidset, ic)) {
				camel_imapx_command_add (ic, " %tFLAGS.SILENT (%t)", on ? "+" : "-", flags_table[jj].name);

				success = camel_imapx_server_process_command_sync (is, ic, _("Error syncing changes"), cancellable, error);

				camel_imapx_command_unref (ic);
				ic = NULL;

				if (!success)
					break;
			}

			g_warn_if_fail (ic == NULL);
		}

		if (user_set && (permanentflags & CAMEL_MESSAGE_USER) != 0 && success) {
			CamelIMAPXCommand *ic = NULL;

			for (jj = 0; jj < user_set->len && success; jj++) {
				struct _imapx_flag_change *c = &g_array_index (user_set, struct _imapx_flag_change, jj);

				imapx_uidset_init (&uidset, 0, 100);
				for (i = 0; i < c->infos->len; i++) {
					CamelMessageInfo *info = c->infos->pdata[i];

					if (ic == NULL)
						ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_SYNC_CHANGES, "UID STORE ");

					if (imapx_uidset_add (&uidset, ic, camel_message_info_get_uid (info)) == 1
					    || (i == c->infos->len - 1 && imapx_uidset_done (&uidset, ic))) {
						gchar *utf7;

						utf7 = camel_utf8_utf7 (c->name);

						camel_imapx_command_add (ic, " %tFLAGS.SILENT (%t)", on ? "+" : "-", utf7 ? utf7 : c->name);

						g_free (utf7);

						success = camel_imapx_server_process_command_sync (is, ic, _("Error syncing changes"), cancellable, error);

						camel_imapx_command_unref (ic);
						ic = NULL;

						if (!success)
							break;
					}
				}
			}
		}
	}

	if (success) {
		CamelFolderSummary *folder_summary;
		CamelStore *parent_store;
		guint32 unseen;

		parent_store = camel_folder_get_parent_store (folder);
		folder_summary = camel_folder_get_folder_summary (folder);

		camel_folder_summary_lock (folder_summary);

		for (i = 0; i < changed_uids->len; i++) {
			CamelMessageInfo *info;
			CamelIMAPXMessageInfo *xinfo;
			gboolean set_folder_flagged;
			guint32 has_flags, set_server_flags;
			gboolean changed_meanwhile;
			const gchar *uid;

			uid = g_ptr_array_index (changed_uids, i);

			/* the 'stamps' hash table contains only those uid-s,
			   which were also flagged, not only 'dirty' */
			if (!g_hash_table_contains (stamps, uid))
				continue;

			info = camel_folder_summary_get (folder_summary, uid);
			xinfo = info ? CAMEL_IMAPX_MESSAGE_INFO (info) : NULL;

			if (!info || !xinfo) {
				g_clear_object (&info);
				continue;
			}

			camel_message_info_property_lock (info);

			changed_meanwhile = camel_message_info_get_folder_flagged_stamp (info) !=
				GPOINTER_TO_UINT (g_hash_table_lookup (stamps, uid));

			has_flags = camel_message_info_get_flags (info);
			set_server_flags = has_flags & CAMEL_IMAPX_SERVER_FLAGS;
			if (!remove_deleted_flags ||
			    !(has_flags & CAMEL_MESSAGE_DELETED)) {
				set_folder_flagged = FALSE;
			} else {
				/* to stare back the \Deleted flag */
				set_server_flags &= ~CAMEL_MESSAGE_DELETED;
				set_folder_flagged = TRUE;
			}

			if ((permanentflags & CAMEL_MESSAGE_USER) != 0 ||
			    !camel_named_flags_get_length (camel_imapx_message_info_get_server_user_flags (xinfo))) {
				camel_imapx_message_info_take_server_user_flags (xinfo, camel_message_info_dup_user_flags (info));
			}

			if (changed_meanwhile)
				set_folder_flagged = TRUE;

			camel_imapx_message_info_set_server_flags (xinfo, set_server_flags);
			camel_message_info_set_folder_flagged (info, set_folder_flagged);

			camel_message_info_property_unlock (info);
			camel_folder_summary_touch (folder_summary);
			g_clear_object (&info);
		}

		camel_folder_summary_unlock (folder_summary);

		/* Apply the changes to server-side unread count; it won't tell
		 * us of these changes, of course. */
		unseen = camel_imapx_mailbox_get_unseen (mailbox);
		unseen += unread_change;
		camel_imapx_mailbox_set_unseen (mailbox, unseen);

		if ((camel_folder_summary_get_flags (folder_summary) & CAMEL_FOLDER_SUMMARY_DIRTY) != 0) {
			CamelStoreInfo *si;

			/* ... and store's summary when folder's summary is dirty */
			si = camel_store_summary_path (CAMEL_IMAPX_STORE (parent_store)->summary, camel_folder_get_full_name (folder));
			if (si) {
				if (si->total != camel_folder_summary_get_saved_count (folder_summary) ||
				    si->unread != camel_folder_summary_get_unread_count (folder_summary)) {
					si->total = camel_folder_summary_get_saved_count (folder_summary);
					si->unread = camel_folder_summary_get_unread_count (folder_summary);
					camel_store_summary_touch (CAMEL_IMAPX_STORE (parent_store)->summary);
				}

				camel_store_summary_info_unref (CAMEL_IMAPX_STORE (parent_store)->summary, si);
			}
		}
	}

	camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);
	camel_store_summary_save (CAMEL_IMAPX_STORE (camel_folder_get_parent_store (folder))->summary);

	imapx_sync_free_user (on_user);
	imapx_sync_free_user (off_user);
	camel_folder_free_uids (folder, changed_uids);
	g_hash_table_destroy (stamps);
	g_object_unref (folder);

	return success;
}

gboolean
camel_imapx_server_expunge_sync (CamelIMAPXServer *is,
				 CamelIMAPXMailbox *mailbox,
				 GCancellable *cancellable,
				 GError **error)
{
	CamelFolder *folder;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	folder = imapx_server_ref_folder (is, mailbox);
	g_return_val_if_fail (folder != NULL, FALSE);

	success = camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error);

	if (success) {
		CamelIMAPXCommand *ic;

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_EXPUNGE, "EXPUNGE");

		success = camel_imapx_server_process_command_sync (is, ic, _("Error expunging message"), cancellable, error);
		if (success) {
			GPtrArray *uids;
			CamelStore *parent_store;
			CamelFolderSummary *folder_summary;
			const gchar *full_name;

			full_name = camel_folder_get_full_name (folder);
			parent_store = camel_folder_get_parent_store (folder);
			folder_summary = camel_folder_get_folder_summary (folder);

			camel_folder_summary_lock (folder_summary);

			camel_folder_summary_save (folder_summary, NULL);
			uids = camel_db_get_folder_deleted_uids (camel_store_get_db (parent_store), full_name, NULL);

			if (uids && uids->len) {
				CamelFolderChangeInfo *changes;
				GList *removed = NULL;
				gint i;

				changes = camel_folder_change_info_new ();
				for (i = 0; i < uids->len; i++) {
					camel_folder_change_info_remove_uid (changes, uids->pdata[i]);
					removed = g_list_prepend (removed, (gpointer) uids->pdata[i]);
				}

				camel_folder_summary_remove_uids (folder_summary, removed);
				camel_folder_summary_save (folder_summary, NULL);

				camel_folder_changed (folder, changes);
				camel_folder_change_info_free (changes);

				g_list_free (removed);
				g_ptr_array_foreach (uids, (GFunc) camel_pstring_free, NULL);
			}

			if (uids)
				g_ptr_array_free (uids, TRUE);

			camel_folder_summary_unlock (folder_summary);
		}

		camel_imapx_command_unref (ic);
	}

	g_clear_object (&folder);

	return success;
}

gboolean
camel_imapx_server_list_sync (CamelIMAPXServer *is,
			      const gchar *pattern,
			      CamelStoreGetFolderInfoFlags flags,
			      GCancellable *cancellable,
			      GError **error)
{
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (pattern != NULL, FALSE);

	g_warn_if_fail (is->priv->list_responses_hash == NULL);
	g_warn_if_fail (is->priv->list_responses == NULL);
	g_warn_if_fail (is->priv->lsub_responses == NULL);

	if (is->priv->list_return_opts != NULL) {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_LIST, "LIST \"\" %s RETURN (%t)",
			pattern, is->priv->list_return_opts);
	} else {
		is->priv->list_responses_hash = g_hash_table_new (camel_strcase_hash, camel_strcase_equal);

		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_LIST, "LIST \"\" %s",
			pattern);
	}

	success = camel_imapx_server_process_command_sync (is, ic, _("Error fetching folders"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success && !is->priv->list_return_opts) {
		ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_LSUB, "LSUB \"\" %s",
			pattern);

		success = camel_imapx_server_process_command_sync (is, ic, _("Error fetching subscribed folders"), cancellable, error);

		camel_imapx_command_unref (ic);
	}

	if (is->priv->list_responses_hash) {
		CamelIMAPXStore *imapx_store;
		GSList *link;

		imapx_store = camel_imapx_server_ref_store (is);
		if (imapx_store) {
			/* Preserve order in which these had been received from the server */
			is->priv->list_responses = g_slist_reverse (is->priv->list_responses);
			is->priv->lsub_responses = g_slist_reverse (is->priv->lsub_responses);

			for (link = is->priv->list_responses; link; link = g_slist_next (link)) {
				CamelIMAPXListResponse *response = link->data;

				camel_imapx_store_handle_list_response (imapx_store, is, response);
			}

			for (link = is->priv->lsub_responses; link; link = g_slist_next (link)) {
				CamelIMAPXListResponse *response = link->data;

				camel_imapx_store_handle_lsub_response (imapx_store, is, response);
			}

			g_clear_object (&imapx_store);
		}

		g_hash_table_destroy (is->priv->list_responses_hash);
		is->priv->list_responses_hash = NULL;
		g_slist_free_full (is->priv->list_responses, g_object_unref);
		is->priv->list_responses = NULL;
		g_slist_free_full (is->priv->lsub_responses, g_object_unref);
		is->priv->lsub_responses = NULL;
	}

	return success;
}

gboolean
camel_imapx_server_create_mailbox_sync (CamelIMAPXServer *is,
					const gchar *mailbox_name,
					GCancellable *cancellable,
					GError **error)
{
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (mailbox_name != NULL, FALSE);

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_CREATE_MAILBOX, "CREATE %m", mailbox_name);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error creating folder"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success) {
		gchar *utf7_pattern;

		utf7_pattern = camel_utf8_utf7 (mailbox_name);

		/* List the new mailbox so we trigger our untagged
		 * LIST handler.  This simulates being notified of
		 * a newly-created mailbox, so we can just let the
		 * callback functions handle the bookkeeping. */
		success = camel_imapx_server_list_sync (is, utf7_pattern, 0, cancellable, error);

		g_free (utf7_pattern);
	}

	return success;
}

gboolean
camel_imapx_server_delete_mailbox_sync (CamelIMAPXServer *is,
					CamelIMAPXMailbox *mailbox,
					GCancellable *cancellable,
					GError **error)
{
	CamelIMAPXCommand *ic;
	CamelIMAPXMailbox *inbox;
	CamelIMAPXStore *imapx_store;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	/* Avoid camel_imapx_job_set_mailbox() here.  We
	 * don't want to select the mailbox to be deleted. */

	imapx_store = camel_imapx_server_ref_store (is);
	/* Keep going, even if this returns NULL. */
	inbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");

	/* Make sure the to-be-deleted folder is not
	 * selected by selecting INBOX for this operation. */
	success = camel_imapx_server_ensure_selected_sync (is, inbox, cancellable, error);
	if (!success) {
		g_clear_object (&inbox);
		g_clear_object (&imapx_store);
		return FALSE;
	}

	/* Just to make sure it'll not disappeare before the end of this function */
	g_object_ref (mailbox);

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_DELETE_MAILBOX, "DELETE %M", mailbox);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error deleting folder"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success) {
		camel_imapx_mailbox_deleted (mailbox);
		camel_imapx_store_emit_mailbox_updated (imapx_store, mailbox);
	}

	g_clear_object (&inbox);
	g_clear_object (&imapx_store);
	g_clear_object (&mailbox);

	return success;
}

gboolean
camel_imapx_server_rename_mailbox_sync (CamelIMAPXServer *is,
					CamelIMAPXMailbox *mailbox,
					const gchar *new_mailbox_name,
					GCancellable *cancellable,
					GError **error)
{
	CamelIMAPXCommand *ic;
	CamelIMAPXMailbox *inbox;
	CamelIMAPXStore *imapx_store;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (new_mailbox_name != NULL, FALSE);

	imapx_store = camel_imapx_server_ref_store (is);
	inbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");
	g_return_val_if_fail (inbox != NULL, FALSE);

	/* We don't want to select the mailbox to be renamed. */
	success = camel_imapx_server_ensure_selected_sync (is, inbox, cancellable, error);
	if (!success) {
		g_clear_object (&inbox);
		g_clear_object (&imapx_store);
		return FALSE;
	}

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_RENAME_MAILBOX, "RENAME %M %m", mailbox, new_mailbox_name);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error renaming folder"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success) {
		/* Perform the same processing as imapx_untagged_list()
		 * would if the server notified us of a renamed mailbox. */

		camel_imapx_store_handle_mailbox_rename (imapx_store, mailbox, new_mailbox_name);
	}

	g_clear_object (&inbox);
	g_clear_object (&imapx_store);

	return success;
}

gboolean
camel_imapx_server_subscribe_mailbox_sync (CamelIMAPXServer *is,
					   CamelIMAPXMailbox *mailbox,
					   GCancellable *cancellable,
					   GError **error)
{
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	/* We don't want to select the mailbox to be subscribed. */
	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_SUBSCRIBE_MAILBOX, "SUBSCRIBE %M", mailbox);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error subscribing to folder"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success) {
		CamelIMAPXStore *imapx_store;

		/* Perform the same processing as imapx_untagged_list()
		 * would if the server notified us of a subscription. */

		imapx_store = camel_imapx_server_ref_store (is);

		camel_imapx_mailbox_subscribed (mailbox);
		camel_imapx_store_emit_mailbox_updated (imapx_store, mailbox);

		g_clear_object (&imapx_store);
	}

	return success;
}

gboolean
camel_imapx_server_unsubscribe_mailbox_sync (CamelIMAPXServer *is,
					     CamelIMAPXMailbox *mailbox,
					     GCancellable *cancellable,
					     GError **error)
{
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	/* We don't want to select the mailbox to be unsubscribed. */
	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_UNSUBSCRIBE_MAILBOX, "UNSUBSCRIBE %M", mailbox);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error unsubscribing from folder"), cancellable, error);

	camel_imapx_command_unref (ic);

	if (success) {
		CamelIMAPXStore *imapx_store;

		/* Perform the same processing as imapx_untagged_list()
		 * would if the server notified us of an unsubscription. */

		imapx_store = camel_imapx_server_ref_store (is);

		camel_imapx_mailbox_unsubscribed (mailbox);
		camel_imapx_store_emit_mailbox_updated (imapx_store, mailbox);

		g_clear_object (&imapx_store);
	}

	return success;
}

gboolean
camel_imapx_server_update_quota_info_sync (CamelIMAPXServer *is,
					   CamelIMAPXMailbox *mailbox,
					   GCancellable *cancellable,
					   GError **error)
{
	CamelIMAPXCommand *ic;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	g_mutex_lock (&is->priv->stream_lock);

	if (CAMEL_IMAPX_LACK_CAPABILITY (is->priv->cinfo, QUOTA)) {
		g_mutex_unlock (&is->priv->stream_lock);

		g_set_error_literal (
			error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
			_("IMAP server does not support quotas"));
		return FALSE;
	} else {
		g_mutex_unlock (&is->priv->stream_lock);
	}

	success = camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error);
	if (!success)
		return FALSE;

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_UPDATE_QUOTA_INFO, "GETQUOTAROOT %M", mailbox);

	success = camel_imapx_server_process_command_sync (is, ic, _("Error retrieving quota information"), cancellable, error);

	camel_imapx_command_unref (ic);

	return success;
}

GPtrArray *
camel_imapx_server_uid_search_sync (CamelIMAPXServer *is,
				    CamelIMAPXMailbox *mailbox,
				    const gchar *criteria_prefix,
				    const gchar *search_key,
				    const gchar * const *words,
				    GCancellable *cancellable,
				    GError **error)
{
	CamelIMAPXCommand *ic;
	GArray *uid_search_results;
	GPtrArray *results = NULL;
	gint ii;
	gboolean need_charset = FALSE;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);
	g_return_val_if_fail (criteria_prefix != NULL, NULL);

	success = camel_imapx_server_ensure_selected_sync (is, mailbox, cancellable, error);
	if (!success)
		return FALSE;

	if (!camel_imapx_server_get_utf8_accept (is)) {
		for (ii = 0; !need_charset && words && words[ii]; ii++) {
			need_charset = !imapx_util_all_is_ascii (words[ii]);
		}
	}

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_UID_SEARCH, "UID SEARCH");
	if (need_charset)
		camel_imapx_command_add (ic, " CHARSET UTF-8");
	if (criteria_prefix && *criteria_prefix)
		camel_imapx_command_add (ic, " %t", criteria_prefix);

	if (search_key && words) {
		gboolean is_gmail_server = FALSE;

		if (g_strcasecmp (search_key, "BODY") == 0) {
			CamelIMAPXStore *imapx_store;

			imapx_store = camel_imapx_server_ref_store (is);
			if (imapx_store) {
				is_gmail_server = camel_imapx_store_is_gmail_server (imapx_store);
				g_object_unref (imapx_store);
			}
		}

		for (ii = 0; words[ii]; ii++) {
			guchar mask = is_gmail_server ? imapx_is_mask (words[ii]) : 0;
			if (is_gmail_server && !(mask & IMAPX_TYPE_ATOM_CHAR) && (mask & IMAPX_TYPE_TEXT_CHAR) != 0)
				camel_imapx_command_add (ic, " X-GM-RAW %s", words[ii]);
			else
				camel_imapx_command_add (ic, " %t %s", search_key, words[ii]);
		}
	}

	success = camel_imapx_server_process_command_sync (is, ic, _("Search failed"), cancellable, error);

	camel_imapx_command_unref (ic);

	g_mutex_lock (&is->priv->search_results_lock);
	uid_search_results = is->priv->search_results;
	is->priv->search_results = NULL;
	g_mutex_unlock (&is->priv->search_results_lock);

	if (success) {
		guint ii;

		/* Convert the numeric UIDs to strings. */

		g_return_val_if_fail (uid_search_results != NULL, NULL);

		results = g_ptr_array_new_full (uid_search_results->len, (GDestroyNotify) camel_pstring_free);

		for (ii = 0; ii < uid_search_results->len; ii++) {
			const gchar *pooled_uid;
			guint64 numeric_uid;
			gchar *alloced_uid;

			numeric_uid = g_array_index (uid_search_results, guint64, ii);
			alloced_uid = g_strdup_printf ("%" G_GUINT64_FORMAT, numeric_uid);
			pooled_uid = camel_pstring_add (alloced_uid, TRUE);
			g_ptr_array_add (results, (gpointer) pooled_uid);
		}
	}

	if (uid_search_results)
		g_array_unref (uid_search_results);

	return results;
}

typedef struct _IdleThreadData {
	CamelIMAPXServer *is;
	GCancellable *idle_cancellable;
	gint idle_stamp;
} IdleThreadData;

static gpointer
imapx_server_idle_thread (gpointer user_data)
{
	IdleThreadData *itd = user_data;
	CamelIMAPXServer *is;
	CamelIMAPXMailbox *mailbox;
	CamelIMAPXCommand *ic;
	CamelIMAPXCommandPart *cp;
	GCancellable *idle_cancellable;
	GError *local_error = NULL;
	gint previous_timeout = -1;
	gboolean success = FALSE;
	gboolean rather_disconnect = FALSE;

	g_return_val_if_fail (itd != NULL, NULL);

	is = itd->is;
	idle_cancellable = itd->idle_cancellable;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);
	g_return_val_if_fail (G_IS_CANCELLABLE (idle_cancellable), NULL);

	g_mutex_lock (&is->priv->idle_lock);

	if (g_cancellable_is_cancelled (idle_cancellable) ||
	    is->priv->idle_stamp != itd->idle_stamp ||
	    is->priv->idle_state != IMAPX_IDLE_STATE_SCHEDULED) {
		g_cond_broadcast (&is->priv->idle_cond);
		g_mutex_unlock (&is->priv->idle_lock);

		g_clear_object (&itd->is);
		g_clear_object (&itd->idle_cancellable);
		g_free (itd);

		return NULL;
	}

	is->priv->idle_state = IMAPX_IDLE_STATE_PREPARING;
	g_cond_broadcast (&is->priv->idle_cond);

	mailbox = is->priv->idle_mailbox;
	if (mailbox)
		g_object_ref (mailbox);

	g_mutex_unlock (&is->priv->idle_lock);

	if (!mailbox)
		mailbox = camel_imapx_server_ref_selected (is);

	if (!mailbox)
		goto exit;

	success = camel_imapx_server_ensure_selected_sync (is, mailbox, idle_cancellable, &local_error);
	if (!success) {
		rather_disconnect = TRUE;
		goto exit;
	}

	ic = camel_imapx_command_new (is, CAMEL_IMAPX_JOB_IDLE, "IDLE");
	camel_imapx_command_close (ic);

	cp = g_queue_peek_head (&ic->parts);
	cp->type |= CAMEL_IMAPX_COMMAND_CONTINUATION;

	g_mutex_lock (&is->priv->stream_lock);
	/* Set the connection timeout to one minute more than the inactivity timeout */
	if (is->priv->connection)
		previous_timeout = imapx_server_set_connection_timeout (is->priv->connection, INACTIVITY_TIMEOUT_SECONDS + 60);
	g_mutex_unlock (&is->priv->stream_lock);

	g_mutex_lock (&is->priv->idle_lock);
	if (is->priv->idle_stamp == itd->idle_stamp &&
	    is->priv->idle_state == IMAPX_IDLE_STATE_PREPARING) {
		g_mutex_unlock (&is->priv->idle_lock);

		/* Blocks, until the DONE is issued or on inactivity timeout, error, ... */
		success = camel_imapx_server_process_command_sync (is, ic, _("Error running IDLE"), idle_cancellable, &local_error);

		rather_disconnect = rather_disconnect || !success || g_cancellable_is_cancelled (idle_cancellable);
	} else {
		g_mutex_unlock (&is->priv->idle_lock);
	}

	if (previous_timeout >= 0) {
		g_mutex_lock (&is->priv->stream_lock);
		if (is->priv->connection)
			imapx_server_set_connection_timeout (is->priv->connection, previous_timeout);
		g_mutex_unlock (&is->priv->stream_lock);
	}

	camel_imapx_command_unref (ic);

 exit:
	g_mutex_lock (&is->priv->idle_lock);
	g_clear_object (&is->priv->idle_cancellable);
	is->priv->idle_state = IMAPX_IDLE_STATE_OFF;
	g_cond_broadcast (&is->priv->idle_cond);
	g_mutex_unlock (&is->priv->idle_lock);

	if (success)
		c (camel_imapx_server_get_tagprefix (is), "IDLE finished successfully\n");
	else if (local_error)
		c (camel_imapx_server_get_tagprefix (is), "IDLE finished with error: %s%s\n", local_error->message, rather_disconnect ? "; rather disconnect" : "");
	else
		c (camel_imapx_server_get_tagprefix (is), "IDLE finished without error%s\n", rather_disconnect ? "; rather disconnect" : "");

	if (rather_disconnect) {
		imapx_disconnect (is);
	}

	g_clear_object (&mailbox);
	g_clear_error (&local_error);

	g_clear_object (&itd->is);
	g_clear_object (&itd->idle_cancellable);
	g_free (itd);

	return NULL;
}

static gboolean
imapx_server_run_idle_thread_cb (gpointer user_data)
{
	GWeakRef *is_weakref = user_data;
	CamelIMAPXServer *is;

	g_return_val_if_fail (is_weakref != NULL, FALSE);

	is = g_weak_ref_get (is_weakref);
	if (!is)
		return FALSE;

	g_mutex_lock (&is->priv->idle_lock);

	if (g_main_current_source () == is->priv->idle_pending) {
		if (!g_source_is_destroyed (g_main_current_source ()) &&
		    is->priv->idle_state == IMAPX_IDLE_STATE_SCHEDULED) {
			IdleThreadData *itd;
			GThread *thread;
			GError *local_error = NULL;

			itd = g_new0 (IdleThreadData, 1);
			itd->is = g_object_ref (is);
			itd->idle_cancellable = g_object_ref (is->priv->idle_cancellable);
			itd->idle_stamp = is->priv->idle_stamp;

			thread = g_thread_try_new (NULL, imapx_server_idle_thread, itd, &local_error);
			if (thread) {
				g_thread_unref (thread);
			} else {
				g_warning ("%s: Failed to create IDLE thread: %s", G_STRFUNC, local_error ? local_error->message : "Unknown error");

				g_clear_object (&itd->is);
				g_clear_object (&itd->idle_cancellable);
				g_free (itd);
			}

			g_clear_error (&local_error);
		}

		g_source_unref (is->priv->idle_pending);
		is->priv->idle_pending = NULL;
	}

	g_mutex_unlock (&is->priv->idle_lock);
	g_object_unref (is);

	return FALSE;
}

gboolean
camel_imapx_server_can_use_idle (CamelIMAPXServer *is)
{
	gboolean use_idle;
	CamelIMAPXSettings *settings;

	g_mutex_lock (&is->priv->stream_lock);

	settings = camel_imapx_server_ref_settings (is);
	use_idle = camel_imapx_settings_get_use_idle (settings);
	g_object_unref (settings);

	/* Run IDLE if the server supports NOTIFY, to have
	   a constant read on the stream, thus to be notified. */
	if (!CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, NOTIFY) &&
	    !CAMEL_IMAPX_HAVE_CAPABILITY (is->priv->cinfo, IDLE)) {
		use_idle = FALSE;
	}

	g_mutex_unlock (&is->priv->stream_lock);

	return use_idle;
}

gboolean
camel_imapx_server_is_in_idle (CamelIMAPXServer *is)
{
	gboolean in_idle;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->idle_lock);
	in_idle = is->priv->idle_state != IMAPX_IDLE_STATE_OFF;
	g_mutex_unlock (&is->priv->idle_lock);

	return in_idle;
}

CamelIMAPXMailbox *
camel_imapx_server_ref_idle_mailbox (CamelIMAPXServer *is)
{
	CamelIMAPXMailbox *mailbox = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	g_mutex_lock (&is->priv->idle_lock);

	if (is->priv->idle_state != IMAPX_IDLE_STATE_OFF) {
		if (is->priv->idle_mailbox)
			mailbox = g_object_ref (is->priv->idle_mailbox);
		else
			mailbox = camel_imapx_server_ref_selected (is);
	}

	g_mutex_unlock (&is->priv->idle_lock);

	return mailbox;
}

gboolean
camel_imapx_server_schedule_idle_sync (CamelIMAPXServer *is,
				       CamelIMAPXMailbox *mailbox,
				       GCancellable *cancellable,
				       GError **error)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);
	if (mailbox)
		g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	if (!camel_imapx_server_stop_idle_sync (is, cancellable, error))
		return FALSE;

	if (!camel_imapx_server_can_use_idle (is))
		return TRUE;

	g_mutex_lock (&is->priv->idle_lock);

	if (is->priv->idle_state != IMAPX_IDLE_STATE_OFF) {
		g_warn_if_fail (is->priv->idle_state == IMAPX_IDLE_STATE_OFF);

		g_mutex_unlock (&is->priv->idle_lock);

		return FALSE;
	}

	g_warn_if_fail (is->priv->idle_cancellable == NULL);

	is->priv->idle_cancellable = g_cancellable_new ();
	is->priv->idle_stamp++;

	if (is->priv->idle_pending) {
		g_source_destroy (is->priv->idle_pending);
		g_source_unref (is->priv->idle_pending);
	}

	g_clear_object (&is->priv->idle_mailbox);
	if (mailbox)
		is->priv->idle_mailbox = g_object_ref (mailbox);

	is->priv->idle_state = IMAPX_IDLE_STATE_SCHEDULED;
	is->priv->idle_pending = g_timeout_source_new_seconds (IMAPX_IDLE_WAIT_SECONDS);
	g_source_set_callback (
		is->priv->idle_pending, imapx_server_run_idle_thread_cb,
		imapx_weak_ref_new (is), (GDestroyNotify) imapx_weak_ref_free);
	g_source_attach (is->priv->idle_pending, NULL);

	g_mutex_unlock (&is->priv->idle_lock);

	return TRUE;
}

static void
imapx_server_wait_idle_stop_cancelled_cb (GCancellable *cancellable,
					  gpointer user_data)
{
	CamelIMAPXServer *is = user_data;

	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (is));

	g_mutex_lock (&is->priv->idle_lock);
	g_cond_broadcast (&is->priv->idle_cond);
	g_mutex_unlock (&is->priv->idle_lock);
}

gboolean
camel_imapx_server_stop_idle_sync (CamelIMAPXServer *is,
				   GCancellable *cancellable,
				   GError **error)
{
	GCancellable *idle_cancellable;
	gulong handler_id = 0;
	gint64 wait_end_time;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->idle_lock);

	if (is->priv->idle_state == IMAPX_IDLE_STATE_OFF) {
		g_mutex_unlock (&is->priv->idle_lock);
		return TRUE;
	} else if (is->priv->idle_state == IMAPX_IDLE_STATE_SCHEDULED) {
		if (is->priv->idle_pending) {
			g_source_destroy (is->priv->idle_pending);
			g_source_unref (is->priv->idle_pending);
			is->priv->idle_pending = NULL;
		}

		is->priv->idle_state = IMAPX_IDLE_STATE_OFF;
		g_cond_broadcast (&is->priv->idle_cond);
	}

	idle_cancellable = is->priv->idle_cancellable ? g_object_ref (is->priv->idle_cancellable) : NULL;

	g_clear_object (&is->priv->idle_cancellable);
	g_clear_object (&is->priv->idle_mailbox);
	is->priv->idle_stamp++;

	if (cancellable) {
		g_mutex_unlock (&is->priv->idle_lock);

		/* Do not hold the idle_lock here, because the callback can be called
		   immediately, which leads to a deadlock inside it. */
		handler_id = g_cancellable_connect (cancellable, G_CALLBACK (imapx_server_wait_idle_stop_cancelled_cb), is, NULL);

		g_mutex_lock (&is->priv->idle_lock);
	}

	while (is->priv->idle_state == IMAPX_IDLE_STATE_PREPARING &&
	       !g_cancellable_is_cancelled (cancellable)) {
		g_cond_wait (&is->priv->idle_cond, &is->priv->idle_lock);
	}

	if (is->priv->idle_state == IMAPX_IDLE_STATE_RUNNING &&
	    !g_cancellable_is_cancelled (cancellable)) {
		is->priv->idle_state = IMAPX_IDLE_STATE_STOPPING;
		g_cond_broadcast (&is->priv->idle_cond);
		g_mutex_unlock (&is->priv->idle_lock);

		g_mutex_lock (&is->priv->stream_lock);
		if (is->priv->output_stream) {
			gint previous_timeout = -1;

			/* Set the connection timeout to some short time, no need to wait for it for too long */
			if (is->priv->connection)
				previous_timeout = imapx_server_set_connection_timeout (is->priv->connection, 5);

			success = g_output_stream_flush (is->priv->output_stream, cancellable, error);
			success = success && g_output_stream_write_all (is->priv->output_stream, "DONE\r\n", 6, NULL, cancellable, error);
			success = success && g_output_stream_flush (is->priv->output_stream, cancellable, error);

			if (previous_timeout >= 0 && is->priv->connection)
				imapx_server_set_connection_timeout (is->priv->connection, previous_timeout);
		} else {
			success = FALSE;

			/* This message won't get into UI. */
			g_set_error_literal (error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
				"Reconnect after couldn't issue DONE command");
		}
		g_mutex_unlock (&is->priv->stream_lock);
		g_mutex_lock (&is->priv->idle_lock);
	}

	/* Give server 10 seconds to process the DONE command, if it fails, then give up and reconnect */
	wait_end_time = g_get_monotonic_time () + 10 * G_TIME_SPAN_SECOND;

	while (success && is->priv->idle_state != IMAPX_IDLE_STATE_OFF &&
	       !g_cancellable_is_cancelled (cancellable)) {
		success = g_cond_wait_until (&is->priv->idle_cond, &is->priv->idle_lock, wait_end_time);
	}

	g_mutex_unlock (&is->priv->idle_lock);

	if (cancellable && handler_id)
		g_cancellable_disconnect (cancellable, handler_id);

	if (success && g_cancellable_is_cancelled (cancellable)) {
		g_clear_error (error);

		success = FALSE;

		/* This message won't get into UI. */
		g_set_error_literal (error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
			"Reconnect after cancelled IDLE stop command");
	}

	if (!success) {
		if (idle_cancellable)
			g_cancellable_cancel (idle_cancellable);

		g_mutex_lock (&is->priv->idle_lock);
		is->priv->idle_state = IMAPX_IDLE_STATE_OFF;
		g_mutex_unlock (&is->priv->idle_lock);

		imapx_disconnect (is);
	}

	g_clear_object (&idle_cancellable);

	return success;
}

/**
 * camel_imapx_server_register_untagged_handler:
 * @is: a #CamelIMAPXServer instance
 * @untagged_response: a string representation of the IMAP
 *                     untagged response code. Must be
 *                     all-uppercase with underscores allowed
 *                     (see RFC 3501)
 * @desc: a #CamelIMAPXUntaggedRespHandlerDesc handler description
 *        structure. The descriptor structure is expected to
 *        remain stable over the lifetime of the #CamelIMAPXServer
 *        instance it was registered with. It is the responsibility
 *        of the caller to ensure this
 *
 * Register a new handler function for IMAP untagged responses.
 * Pass in a NULL descriptor to delete an existing handler (the
 * untagged response will remain known, but will no longer be acted
 * upon if the handler is deleted). The return value is intended
 * to be used in cases where e.g. an extension to existing handler
 * code is implemented with just some new code to be run before
 * or after the original handler code
 *
 * Returns: the #CamelIMAPXUntaggedRespHandlerDesc previously
 *          registered for this untagged response, if any,
 *          NULL otherwise.
 *
 * Since: 3.6
 */
const CamelIMAPXUntaggedRespHandlerDesc *
camel_imapx_server_register_untagged_handler (CamelIMAPXServer *is,
                                              const gchar *untagged_response,
                                              const CamelIMAPXUntaggedRespHandlerDesc *desc)
{
	const CamelIMAPXUntaggedRespHandlerDesc *previous = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);
	g_return_val_if_fail (untagged_response != NULL, NULL);
	/* desc may be NULL */

	previous = replace_untagged_descriptor (
		is->priv->untagged_handlers,
		untagged_response, desc);

	return previous;
}

/* This function is not thread-safe. */
const struct _capability_info *
camel_imapx_server_get_capability_info (CamelIMAPXServer *is)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	return is->priv->cinfo;
}

gboolean
camel_imapx_server_have_capability (CamelIMAPXServer *is,
				    guint32 capability)
{
	gboolean have;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->stream_lock);
	have = is->priv->cinfo != NULL && (is->priv->cinfo->capa & capability) != 0;
	g_mutex_unlock (&is->priv->stream_lock);

	return have;
}

gboolean
camel_imapx_server_lack_capability (CamelIMAPXServer *is,
				    guint32 capability)
{
	gboolean lack;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	g_mutex_lock (&is->priv->stream_lock);
	lack = is->priv->cinfo != NULL && (is->priv->cinfo->capa & capability) == 0;
	g_mutex_unlock (&is->priv->stream_lock);

	return lack;
}

gchar
camel_imapx_server_get_tagprefix (CamelIMAPXServer *is)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), 0);

	return is->priv->tagprefix;
}

void
camel_imapx_server_set_tagprefix (CamelIMAPXServer *is,
				  gchar tagprefix)
{
	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (is));
	g_return_if_fail ((tagprefix >= 'A' && tagprefix <= 'Z') || (tagprefix >= 'a' && tagprefix <= 'z'));

	is->priv->tagprefix = tagprefix;
}

gboolean
camel_imapx_server_get_utf8_accept (CamelIMAPXServer *is)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), FALSE);

	return is->priv->utf8_accept;
}

CamelIMAPXCommand *
camel_imapx_server_ref_current_command (CamelIMAPXServer *is)
{
	CamelIMAPXCommand *command;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SERVER (is), NULL);

	COMMAND_LOCK (is);

	command = is->priv->current_command;
	if (command)
		camel_imapx_command_ref (command);

	COMMAND_UNLOCK (is);

	return command;
}
