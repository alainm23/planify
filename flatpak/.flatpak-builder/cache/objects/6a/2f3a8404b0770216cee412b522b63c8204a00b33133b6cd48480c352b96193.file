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
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#ifndef G_OS_WIN32
#include <sys/wait.h>
#endif

#include "camel-debug.h"
#include "camel-file-utils.h"
#include "camel-filter-driver.h"
#include "camel-filter-search.h"
#include "camel-mime-message.h"
#include "camel-service.h"
#include "camel-session.h"
#include "camel-sexp.h"
#include "camel-store.h"
#include "camel-stream-fs.h"
#include "camel-stream-mem.h"
#include "camel-string-utils.h"

#define d(x)

/* an invalid pointer */
#define FOLDER_INVALID ((gpointer)~0)

#define CAMEL_FILTER_DRIVER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_FILTER_DRIVER, CamelFilterDriverPrivate))

/* type of status for a log report */
enum filter_log_t {
	FILTER_LOG_NONE,
	FILTER_LOG_START,       /* start of new log entry */
	FILTER_LOG_ACTION,      /* an action performed */
	FILTER_LOG_INFO,        /* a generic information log */
	FILTER_LOG_END          /* end of log */
};

/* list of rule nodes */
struct _filter_rule {
	gchar *match;
	gchar *action;
	gchar *name;
};

struct _CamelFilterDriverPrivate {
	GHashTable *globals;       /* global variables */

	CamelSession *session;

	CamelFolder *defaultfolder;        /* defualt folder */

	CamelFilterStatusFunc statusfunc; /* status callback */
	gpointer statusdata;                  /* status callback data */

	CamelFilterShellFunc shellfunc;    /* execute shell command callback */
	gpointer shelldata;                    /* execute shell command callback data */

	CamelFilterPlaySoundFunc playfunc; /* play-sound command callback */
	gpointer playdata;                     /* play-sound command callback data */

	CamelFilterSystemBeepFunc beep;    /* system beep callback */
	gpointer beepdata;                     /* system beep callback data */

	/* for callback */
	CamelFilterGetFolderFunc get_folder;
	gpointer data;

	/* run-time data */
	GHashTable *folders;       /* folders that message has been copied to */
	gint closed;		   /* close count */
	GHashTable *only_once;     /* actions to run only-once */

	gboolean terminated;       /* message processing was terminated */
	gboolean deleted;          /* message was marked for deletion */
	gboolean copied;           /* message was copied to some folder or another */
	gboolean moved;		   /* message was moved to some folder or another */

	CamelMimeMessage *message; /* input message */
	CamelMessageInfo *info;    /* message summary info */
	const gchar *uid;           /* message uid */
	CamelFolder *source;       /* message source folder */
	gboolean modified;         /* has the input message been modified? */

	FILE *logfile;             /* log file */

	GQueue rules;		   /* queue of _filter_rule structs */

	GError *error;

	GHashTable *transfers;     /* CamelFolder * ~> MessageTransferData * */
	GSList *delete_after_transfer; /* CamelMessageInfo * to delete after transfers are done */

	/* evaluator */
	CamelSExp *eval;
};

static void camel_filter_driver_log (CamelFilterDriver *driver, enum filter_log_t status, const gchar *desc, ...);

static CamelFolder *open_folder (CamelFilterDriver *d, const gchar *folder_url);
static gint close_folders (CamelFilterDriver *d, gboolean can_call_refresh, GCancellable *cancellable);

static CamelSExpResult *do_delete (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_forward_to (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_copy (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_move (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_stop (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_label (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_color (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_score (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_adjust_score (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *set_flag (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *unset_flag (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_shell (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_beep (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *play_sound (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *do_only_once (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);
static CamelSExpResult *pipe_message (struct _CamelSExp *f, gint argc, struct _CamelSExpResult **argv, CamelFilterDriver *);

static gint
filter_driver_filter_message_internal (CamelFilterDriver *driver,
				       gboolean can_process_transfers,
				       CamelMimeMessage *message,
				       CamelMessageInfo *info,
				       const gchar *uid,
				       CamelFolder *source,
				       const gchar *store_uid,
				       const gchar *original_store_uid,
				       GCancellable *cancellable,
				       GError **error);

/* these are our filter actions - each must have a callback */
static struct {
	const gchar *name;
	CamelSExpFunc func;
	gint type;		/* set to 1 if a function can perform shortcut evaluation, or
				   doesn't execute everything, 0 otherwise */
} symbols[] = {
	{ "delete",            (CamelSExpFunc) do_delete,    0 },
	{ "forward-to",        (CamelSExpFunc) do_forward_to, 0 },
	{ "copy-to",           (CamelSExpFunc) do_copy,      0 },
	{ "move-to",           (CamelSExpFunc) do_move,      0 },
	{ "stop",              (CamelSExpFunc) do_stop,      0 },
	{ "set-label",         (CamelSExpFunc) do_label,     0 },
	{ "set-color",         (CamelSExpFunc) do_color,    0 },
	{ "set-score",         (CamelSExpFunc) do_score,     0 },
	{ "adjust-score",      (CamelSExpFunc) do_adjust_score, 0 },
	{ "set-system-flag",   (CamelSExpFunc) set_flag,     0 },
	{ "unset-system-flag", (CamelSExpFunc) unset_flag,   0 },
	{ "pipe-message",      (CamelSExpFunc) pipe_message, 0 },
	{ "shell",             (CamelSExpFunc) do_shell,     0 },
	{ "beep",              (CamelSExpFunc) do_beep,      0 },
	{ "play-sound",        (CamelSExpFunc) play_sound,   0 },
	{ "only-once",         (CamelSExpFunc) do_only_once, 0 }
};

G_DEFINE_TYPE (CamelFilterDriver, camel_filter_driver, G_TYPE_OBJECT)

typedef struct _MessageTransferData {
	GPtrArray *copy_uids;
	GPtrArray *move_uids;
} MessageTransferData;

static void
message_transfer_data_free (gpointer ptr)
{
	MessageTransferData *mtd = ptr;

	if (mtd) {
		if (mtd->copy_uids)
			g_ptr_array_free (mtd->copy_uids, TRUE);
		if (mtd->move_uids)
			g_ptr_array_free (mtd->move_uids, TRUE);
		g_free (mtd);
	}
}

static void
filter_driver_add_to_transfers (CamelFilterDriver *driver,
				CamelFolder *destination,
				const gchar *uid,
				gboolean is_move)
{
	MessageTransferData *mtd;
	GPtrArray **parray;

	g_return_if_fail (CAMEL_IS_FILTER_DRIVER (driver));
	g_return_if_fail (CAMEL_IS_FOLDER (destination));
	g_return_if_fail (uid);

	if (!driver->priv->transfers)
		driver->priv->transfers = g_hash_table_new_full (g_direct_hash, g_direct_equal, g_object_unref, message_transfer_data_free);

	mtd = g_hash_table_lookup (driver->priv->transfers, destination);

	if (!mtd) {
		mtd = g_new0 (MessageTransferData, 1);
		g_hash_table_insert (driver->priv->transfers, g_object_ref (destination), mtd);
	}

	if (is_move)
		parray = &(mtd->move_uids);
	else
		parray = &(mtd->copy_uids);

	if (!*parray)
		*parray = g_ptr_array_new_with_free_func ((GDestroyNotify) camel_pstring_free);

	g_ptr_array_add (*parray, (gpointer) camel_pstring_strdup (uid));
}

static gboolean
filter_driver_process_transfers (CamelFilterDriver *driver,
				 GCancellable *cancellable,
				 GError **error)
{
	gboolean success = TRUE;
	GSList *link;

	g_return_val_if_fail (CAMEL_IS_FILTER_DRIVER (driver), FALSE);

	if (driver->priv->transfers) {
		CamelStore *parent_store;
		GHashTableIter iter;
		gpointer key, value;
		guint ii, sz;

		parent_store = camel_folder_get_parent_store (driver->priv->source);

		/* Translators: The first “%s” is replaced with an account name and the second “%s”
		   is replaced with a full path name. The spaces around “:” are intentional, as
		   the whole “%s : %s” is meant as an absolute identification of the folder. */
		camel_operation_push_message (cancellable, _("Transferring filtered messages in “%s : %s”"),
			camel_service_get_display_name (CAMEL_SERVICE (parent_store)),
			camel_folder_get_full_name (driver->priv->source));

		ii = 0;
		sz = g_hash_table_size (driver->priv->transfers);

		if (!sz)
			sz = 1;

		camel_operation_progress (cancellable, ii * 100 / sz);

		g_hash_table_iter_init (&iter, driver->priv->transfers);
		while (success && g_hash_table_iter_next (&iter, &key, &value)) {
			CamelFolder *destination = key;
			MessageTransferData *mtd = value;

			g_warn_if_fail (CAMEL_IS_FOLDER (destination));
			g_warn_if_fail (mtd != NULL);

			if (mtd->copy_uids) {
				success = camel_folder_transfer_messages_to_sync (driver->priv->source,
					mtd->copy_uids, destination, FALSE, NULL, cancellable, error);
			}

			if (success && mtd->move_uids) {
				success = camel_folder_transfer_messages_to_sync (driver->priv->source,
					mtd->move_uids, destination, TRUE, NULL, cancellable, error);
			}

			ii++;
			camel_operation_progress (cancellable, ii * 100 / sz);
		}

		camel_operation_pop_message (cancellable);

		g_hash_table_destroy (driver->priv->transfers);
		driver->priv->transfers = NULL;
	}

	for (link = driver->priv->delete_after_transfer; link && success; link = g_slist_next (link)) {
		CamelMessageInfo *nfo = link->data;

		camel_message_info_set_flags (
			nfo,
			CAMEL_MESSAGE_DELETED |
			CAMEL_MESSAGE_SEEN |
			CAMEL_MESSAGE_FOLDER_FLAGGED,
			~0);
	}

	g_slist_free_full (driver->priv->delete_after_transfer, g_object_unref);
	driver->priv->delete_after_transfer = NULL;

	return success;
}

static void
free_hash_strings (gpointer key,
                   gpointer value,
                   gpointer data)
{
	g_free (key);
	g_free (value);
}

static gint
filter_rule_compare_by_name (struct _filter_rule *rule,
                             const gchar *name)
{
	return g_strcmp0 (rule->name, name);
}

static void
filter_driver_dispose (GObject *object)
{
	CamelFilterDriverPrivate *priv;

	priv = CAMEL_FILTER_DRIVER_GET_PRIVATE (object);

	if (priv->transfers) {
		g_hash_table_destroy (priv->transfers);
		priv->transfers = NULL;
	}

	g_slist_free_full (priv->delete_after_transfer, g_object_unref);
	priv->delete_after_transfer = NULL;

	if (priv->defaultfolder != NULL) {
		camel_folder_thaw (priv->defaultfolder);
		g_object_unref (priv->defaultfolder);
		priv->defaultfolder = NULL;
	}

	if (priv->session != NULL) {
		g_object_unref (priv->session);
		priv->session = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_filter_driver_parent_class)->dispose (object);
}

static void
filter_driver_finalize (GObject *object)
{
	CamelFilterDriverPrivate *priv;
	struct _filter_rule *node;

	priv = CAMEL_FILTER_DRIVER_GET_PRIVATE (object);

	/* close all folders that were opened for appending */
	close_folders (CAMEL_FILTER_DRIVER (object), FALSE, NULL);
	g_hash_table_destroy (priv->folders);

	g_hash_table_foreach (priv->globals, free_hash_strings, object);
	g_hash_table_destroy (priv->globals);

	g_hash_table_foreach (priv->only_once, free_hash_strings, object);
	g_hash_table_destroy (priv->only_once);

	g_object_unref (priv->eval);

	while ((node = g_queue_pop_head (&priv->rules)) != NULL) {
		g_free (node->match);
		g_free (node->action);
		g_free (node->name);
		g_free (node);
	}

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_filter_driver_parent_class)->finalize (object);
}

static void
camel_filter_driver_class_init (CamelFilterDriverClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelFilterDriverPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = filter_driver_dispose;
	object_class->finalize = filter_driver_finalize;
}

static void
camel_filter_driver_init (CamelFilterDriver *filter_driver)
{
	gint ii;

	filter_driver->priv = CAMEL_FILTER_DRIVER_GET_PRIVATE (filter_driver);

	g_queue_init (&filter_driver->priv->rules);

	filter_driver->priv->eval = camel_sexp_new ();

	/* Load in builtin symbols */
	for (ii = 0; ii < G_N_ELEMENTS (symbols); ii++) {
		if (symbols[ii].type == 1) {
			camel_sexp_add_ifunction (
				filter_driver->priv->eval, 0,
				symbols[ii].name, (CamelSExpIFunc)
				symbols[ii].func, filter_driver);
		} else {
			camel_sexp_add_function (
				filter_driver->priv->eval, 0,
				symbols[ii].name, symbols[ii].func,
				filter_driver);
		}
	}

	filter_driver->priv->globals =
		g_hash_table_new (g_str_hash, g_str_equal);

	filter_driver->priv->folders =
		g_hash_table_new (g_str_hash, g_str_equal);

	filter_driver->priv->only_once =
		g_hash_table_new (g_str_hash, g_str_equal);
}

/**
 * camel_filter_driver_new:
 * @session: (type CamelSession):
 *
 * Returns: A new CamelFilterDriver object
 **/
CamelFilterDriver *
camel_filter_driver_new (CamelSession *session)
{
	CamelFilterDriver *d;

	d = g_object_new (CAMEL_TYPE_FILTER_DRIVER, NULL);
	d->priv->session = g_object_ref (session);

	return d;
}

/**
 * camel_filter_driver_set_folder_func:
 * @d: a #CamelFilterDriver
 * @get_folder: (scope call) (closure user_data): a callback to get a folder
 * @user_data: user data to pass to @get_folder
 *
 * Sets a callback (of type #CamelFilterGetFolderFunc) to get a folder.
 **/
void
camel_filter_driver_set_folder_func (CamelFilterDriver *d,
                                     CamelFilterGetFolderFunc get_folder,
                                     gpointer user_data)
{
	d->priv->get_folder = get_folder;
	d->priv->data = user_data;
}

/**
 * camel_filter_driver_set_logfile:
 * @d: a #CamelFilterDriver
 * @logfile: (nullable): a FILE handle where to write logging
 *
* Sets a log file to use for logging.
 **/
void
camel_filter_driver_set_logfile (CamelFilterDriver *d,
                                 FILE *logfile)
{
	d->priv->logfile = logfile;
}

/**
 * camel_filter_driver_set_status_func:
 * @d: a #CamelFilterDriver
 * @func: (scope call) (closure user_data): a callback to report progress
 * @user_data: user data to pass to @func
 *
 * Sets a status callback, which is used to report progress/status.
 **/
void
camel_filter_driver_set_status_func (CamelFilterDriver *d,
                                     CamelFilterStatusFunc func,
                                     gpointer user_data)
{
	d->priv->statusfunc = func;
	d->priv->statusdata = user_data;
}

/**
 * camel_filter_driver_set_shell_func:
 * @d: a #CamelFilterDriver
 * @func: (scope call) (closure user_data): a shell command callback
 * @user_data: user data to pass to @func
 *
 * Sets a shell command callback, which is called when a shell command
 * execution is requested.
 **/
void
camel_filter_driver_set_shell_func (CamelFilterDriver *d,
                                    CamelFilterShellFunc func,
                                    gpointer user_data)
{
	d->priv->shellfunc = func;
	d->priv->shelldata = user_data;
}

/**
 * camel_filter_driver_set_play_sound_func:
 * @d: a #CamelFilterDriver
 * @func: (scope call) (closure user_data): a callback to play a sound
 * @user_data: user data to pass to @func
 *
 * Sets a callback to call when a play of a sound is requested.
 **/
void
camel_filter_driver_set_play_sound_func (CamelFilterDriver *d,
                                         CamelFilterPlaySoundFunc func,
                                         gpointer user_data)
{
	d->priv->playfunc = func;
	d->priv->playdata = user_data;
}

/**
 * camel_filter_driver_set_system_beep_func:
 * @d: a #CamelFilterDriver
 * @func: (scope call) (closure user_data): a system beep callback
 * @user_data: user data to pass to @func
 *
 * Sets a callback to use for system beep.
 **/
void
camel_filter_driver_set_system_beep_func (CamelFilterDriver *d,
                                          CamelFilterSystemBeepFunc func,
                                          gpointer user_data)
{
	d->priv->beep = func;
	d->priv->beepdata = user_data;
}

/**
 * camel_filter_driver_set_default_folder:
 * @d: a #CamelFilterDriver
 * @def: (nullable): a default #CamelFolder
 *
 * Sets a default folder for the driver. The function adds
 * its own reference for the folder.
 **/
void
camel_filter_driver_set_default_folder (CamelFilterDriver *d,
                                        CamelFolder *def)
{
	if (d->priv->defaultfolder == def)
		return;

	if (d->priv->defaultfolder) {
		camel_folder_thaw (d->priv->defaultfolder);
		g_object_unref (d->priv->defaultfolder);
	}

	d->priv->defaultfolder = def;

	if (d->priv->defaultfolder) {
		camel_folder_freeze (d->priv->defaultfolder);
		g_object_ref (d->priv->defaultfolder);
	}
}

/**
 * camel_filter_driver_add_rule:
 * @d: a #CamelFilterDriver
 * @name: name of the rule
 * @match: a code (#CamelSExp) to execute to check whether the rule can be applied
 * @action: an action code (#CamelSExp) to execute, when the @match evaluates to %TRUE
 *
 * Adds a new rule to set of rules to process by the filter driver.
 **/
void
camel_filter_driver_add_rule (CamelFilterDriver *d,
                              const gchar *name,
                              const gchar *match,
                              const gchar *action)
{
	struct _filter_rule *node;

	node = g_malloc (sizeof (*node));
	node->match = g_strdup (match);
	node->action = g_strdup (action);
	node->name = g_strdup (name);

	g_queue_push_tail (&d->priv->rules, node);
}

/**
 * camel_filter_driver_remove_rule_by_name:
 * @d: a #CamelFilterDriver
 * @name: rule name
 *
 * Removes a rule by name, added by camel_filter_driver_add_rule().
 *
 * Returns: Whether the rule had been found and removed.
 **/
gboolean
camel_filter_driver_remove_rule_by_name (CamelFilterDriver *d,
                                         const gchar *name)
{
	GList *link;

	link = g_queue_find_custom (
		&d->priv->rules, name,
		(GCompareFunc) filter_rule_compare_by_name);

	if (link != NULL) {
		struct _filter_rule *rule = link->data;

		g_queue_delete_link (&d->priv->rules, link);

		g_free (rule->match);
		g_free (rule->action);
		g_free (rule->name);
		g_free (rule);

		return TRUE;
	}

	return FALSE;
}

static void
report_status (CamelFilterDriver *driver,
               enum camel_filter_status_t status,
               gint pc,
               const gchar *desc,
               ...)
{
	/* call user-defined status report function */
	va_list ap;
	gchar *str;

	if (driver->priv->statusfunc) {
		va_start (ap, desc);
		str = g_strdup_vprintf (desc, ap);
		va_end (ap);
		driver->priv->statusfunc (driver, status, pc, str, driver->priv->statusdata);
		g_free (str);
	}
}

#if 0
void
camel_filter_driver_set_global (CamelFilterDriver *d,
                                const gchar *name,
                                const gchar *value)
{
	gchar *oldkey, *oldvalue;

	if (g_hash_table_lookup_extended (d->priv->globals, name, (gpointer) &oldkey, (gpointer) &oldvalue)) {
		g_free (oldvalue);
		g_hash_table_insert (d->priv->globals, oldkey, g_strdup (value));
	} else {
		g_hash_table_insert (d->priv->globals, g_strdup (name), g_strdup (value));
	}
}
#endif

static CamelSExpResult *
do_delete (struct _CamelSExp *f,
           gint argc,
           struct _CamelSExpResult **argv,
           CamelFilterDriver *driver)
{
	d (fprintf (stderr, "doing delete\n"));
	driver->priv->deleted = TRUE;
	camel_filter_driver_log (driver, FILTER_LOG_ACTION, "Delete");

	return NULL;
}

static CamelSExpResult *
do_forward_to (struct _CamelSExp *f,
               gint argc,
               struct _CamelSExpResult **argv,
               CamelFilterDriver *driver)
{
	d (fprintf (stderr, "marking message for forwarding\n"));

	/* requires one parameter, string with a destination address */
	if (argc < 1 || argv[0]->type != CAMEL_SEXP_RES_STRING)
		return NULL;

	/* make sure we have the message... */
	if (driver->priv->message == NULL) {
		/* FIXME Pass a GCancellable */
		driver->priv->message = camel_folder_get_message_sync (
			driver->priv->source,
			driver->priv->uid, NULL,
			&driver->priv->error);
		if (driver->priv->message == NULL)
			return NULL;
	}

	camel_filter_driver_log (
		driver, FILTER_LOG_ACTION,
		"Forward message to '%s'",
		argv[0]->value.string);

	/* XXX Not cancellable. */
	camel_session_forward_to_sync (
		driver->priv->session,
		driver->priv->source,
		driver->priv->message,
		argv[0]->value.string,
		NULL,
		&driver->priv->error);

	return NULL;
}

static CamelSExpResult *
do_copy (struct _CamelSExp *f,
         gint argc,
         struct _CamelSExpResult **argv,
         CamelFilterDriver *driver)
{
	gint i;

	d (fprintf (stderr, "copying message...\n"));

	for (i = 0; i < argc; i++) {
		if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
			/* open folders we intent to copy to */
			gchar *folder = argv[i]->value.string;
			CamelFolder *outbox;

			outbox = open_folder (driver, folder);
			if (!outbox)
				break;

			if (outbox == driver->priv->source)
				break;

			if (driver->priv->message == NULL)
				/* FIXME Pass a GCancellable */
				driver->priv->message = camel_folder_get_message_sync (
					driver->priv->source,
					driver->priv->uid, NULL,
					&driver->priv->error);

			if (!driver->priv->message)
				continue;

			/* FIXME Pass a GCancellable */
			camel_folder_append_message_sync (
				outbox, driver->priv->message,
				driver->priv->info, NULL, NULL,
				&driver->priv->error);

			if (driver->priv->error == NULL)
				driver->priv->copied = TRUE;

			camel_filter_driver_log (
				driver, FILTER_LOG_ACTION,
				"Copy to folder %s", folder);
		}
	}

	return NULL;
}

static CamelSExpResult *
do_move (struct _CamelSExp *f,
         gint argc,
         struct _CamelSExpResult **argv,
         CamelFilterDriver *driver)
{
	gint i;

	d (fprintf (stderr, "moving message...\n"));

	for (i = 0; i < argc; i++) {
		if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
			/* open folders we intent to move to */
			gchar *folder = argv[i]->value.string;
			CamelFolder *outbox;
			gint last;

			outbox = open_folder (driver, folder);
			if (!outbox)
				break;

			if (outbox == driver->priv->source)
				break;

			/* only delete on last folder (only 1 can ever be supplied by ui currently) */
			last = (i == argc - 1);

			if (!driver->priv->modified && driver->priv->uid && driver->priv->source && camel_folder_has_summary_capability (driver->priv->source)) {
				filter_driver_add_to_transfers (driver, outbox, driver->priv->uid, last);
			} else {
				if (driver->priv->message == NULL)
					/* FIXME Pass a GCancellable */
					driver->priv->message = camel_folder_get_message_sync (
						driver->priv->source, driver->priv->uid, NULL, &driver->priv->error);

				if (!driver->priv->message)
					continue;

				/* FIXME Pass a GCancellable */
				camel_folder_append_message_sync (
					outbox, driver->priv->message, driver->priv->info,
					NULL, NULL, &driver->priv->error);

				if (driver->priv->error == NULL && last) {
					if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
						camel_folder_set_message_flags (
							driver->priv->source, driver->priv->uid,
							CAMEL_MESSAGE_DELETED |
							CAMEL_MESSAGE_SEEN, ~0);
					else
						camel_message_info_set_flags (
							driver->priv->info,
							CAMEL_MESSAGE_DELETED |
							CAMEL_MESSAGE_SEEN |
							CAMEL_MESSAGE_FOLDER_FLAGGED,
							~0);
				}
			}

			if (driver->priv->error == NULL) {
				driver->priv->moved = TRUE;
				camel_filter_driver_log (
					driver, FILTER_LOG_ACTION,
					"Move to folder %s", folder);
			}
		}
	}

	/* implicit 'stop' with 'move' */
	camel_filter_driver_log (
		driver, FILTER_LOG_ACTION,
		"Stopped processing");
	driver->priv->terminated = TRUE;

	return NULL;
}

static CamelSExpResult *
do_stop (struct _CamelSExp *f,
         gint argc,
         struct _CamelSExpResult **argv,
         CamelFilterDriver *driver)
{
	camel_filter_driver_log (
		driver, FILTER_LOG_ACTION,
		"Stopped processing");
	d (fprintf (stderr, "terminating message processing\n"));
	driver->priv->terminated = TRUE;

	return NULL;
}

static CamelSExpResult *
do_label (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          CamelFilterDriver *driver)
{
	d (fprintf (stderr, "setting label tag\n"));
	if (argc > 0 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		/* This is a list of new labels, we should used these in case of passing in old names.
		 * This all is required only because backward compatibility. */
		const gchar *new_labels[] = { "$Labelimportant", "$Labelwork", "$Labelpersonal", "$Labeltodo", "$Labellater", NULL};
		const gchar *label;
		gint i;

		label = argv[0]->value.string;

		for (i = 0; new_labels[i]; i++) {
			if (label && strcmp (new_labels[i] + 6, label) == 0) {
				label = new_labels[i];
				break;
			}
		}

		if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
			camel_folder_set_message_user_flag (driver->priv->source, driver->priv->uid, label, TRUE);
		else
			camel_message_info_set_user_flag (driver->priv->info, label, TRUE);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Set label to %s", label);
	}

	return NULL;
}

static CamelSExpResult *
do_color (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          CamelFilterDriver *driver)
{
	d (fprintf (stderr, "setting color tag\n"));
	if (argc > 0 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		const gchar *color = argv[0]->value.string;

		if (color && !*color)
			color = NULL;

		if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
			camel_folder_set_message_user_tag (driver->priv->source, driver->priv->uid, "color", color);
		else
			camel_message_info_set_user_tag (driver->priv->info, "color", color);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Set color to %s", color ? color : "None");
	}

	return NULL;
}

static CamelSExpResult *
do_score (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          CamelFilterDriver *driver)
{
	d (fprintf (stderr, "setting score tag\n"));
	if (argc > 0 && argv[0]->type == CAMEL_SEXP_RES_INT) {
		gchar *value;

		value = g_strdup_printf ("%d", argv[0]->value.number);
		camel_message_info_set_user_tag (driver->priv->info, "score", value);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Set score to %d", argv[0]->value.number);
		g_free (value);
	}

	return NULL;
}

static CamelSExpResult *
do_adjust_score (struct _CamelSExp *f,
                 gint argc,
                 struct _CamelSExpResult **argv,
                 CamelFilterDriver *driver)
{
	d (fprintf (stderr, "adjusting score tag\n"));
	if (argc > 0 && argv[0]->type == CAMEL_SEXP_RES_INT) {
		gchar *value;
		gint old;

		value = (gchar *) camel_message_info_get_user_tag (driver->priv->info, "score");
		old = value ? atoi (value) : 0;
		value = g_strdup_printf ("%d", old + argv[0]->value.number);
		camel_message_info_set_user_tag (driver->priv->info, "score", value);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Adjust score (%d) to %s",
			argv[0]->value.number, value);
		g_free (value);
	}

	return NULL;
}

static CamelSExpResult *
set_flag (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          CamelFilterDriver *driver)
{
	guint32 flags;

	d (fprintf (stderr, "setting flag\n"));
	if (argc == 1 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		flags = camel_system_flag (argv[0]->value.string);
		if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
			camel_folder_set_message_flags (
				driver->priv->source, driver->priv->uid, flags, ~0);
		else
			camel_message_info_set_flags (
				driver->priv->info, flags |
				CAMEL_MESSAGE_FOLDER_FLAGGED, ~0);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Set %s flag", argv[0]->value.string);
	}

	return NULL;
}

static CamelSExpResult *
unset_flag (struct _CamelSExp *f,
            gint argc,
            struct _CamelSExpResult **argv,
            CamelFilterDriver *driver)
{
	guint32 flags;

	d (fprintf (stderr, "unsetting flag\n"));
	if (argc == 1 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		flags = camel_system_flag (argv[0]->value.string);
		if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
			camel_folder_set_message_flags (
				driver->priv->source, driver->priv->uid, flags, 0);
		else
			camel_message_info_set_flags (
				driver->priv->info, flags |
				CAMEL_MESSAGE_FOLDER_FLAGGED, 0);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Unset %s flag", argv[0]->value.string);
	}

	return NULL;
}

#ifndef G_OS_WIN32
static void
child_setup_func (gpointer user_data)
{
	setsid ();
}
#else
#define child_setup_func NULL
#endif

typedef struct {
	gint child_status;
	GMainLoop *loop;
} child_watch_data_t;

static void
child_watch (GPid pid,
             gint status,
             gpointer user_data)
{
	child_watch_data_t *child_watch_data = user_data;

	g_spawn_close_pid (pid);

	child_watch_data->child_status = status;

	g_main_loop_quit (child_watch_data->loop);
}

static gint
pipe_to_system (struct _CamelSExp *f,
                gint argc,
                struct _CamelSExpResult **argv,
                CamelFilterDriver *driver)
{
	gint i, pipe_to_child, pipe_from_child;
	CamelMimeMessage *message = NULL;
	CamelMimeParser *parser;
	CamelStream *stream, *mem;
	GPid child_pid;
	GError *error = NULL;
	GPtrArray *args;
	child_watch_data_t child_watch_data;
	GSource *source;
	GMainContext *context;

	if (argc < 1 || argv[0]->value.string[0] == '\0')
		return 0;

	/* make sure we have the message... */
	if (driver->priv->message == NULL) {
		/* FIXME Pass a GCancellable */
		driver->priv->message = camel_folder_get_message_sync (
			driver->priv->source, driver->priv->uid, NULL, &driver->priv->error);
		if (driver->priv->message == NULL)
			return -1;
	}

	args = g_ptr_array_new ();
	for (i = 0; i < argc; i++)
		g_ptr_array_add (args, argv[i]->value.string);
	g_ptr_array_add (args, NULL);

	if (!g_spawn_async_with_pipes (NULL,
				       (gchar **) args->pdata,
				       NULL,
				       G_SPAWN_DO_NOT_REAP_CHILD |
				       G_SPAWN_SEARCH_PATH |
				       G_SPAWN_STDERR_TO_DEV_NULL,
				       child_setup_func,
				       NULL,
				       &child_pid,
				       &pipe_to_child,
				       &pipe_from_child,
				       NULL,
				       &error)) {
		g_ptr_array_free (args, TRUE);

		g_set_error (
			&driver->priv->error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to create child process “%s”: %s"),
			argv[0]->value.string, error->message);
		g_error_free (error);
		return -1;
	}

	g_ptr_array_free (args, TRUE);

	stream = camel_stream_fs_new_with_fd (pipe_to_child);
	if (camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (driver->priv->message), stream, NULL, NULL) == -1) {
		g_object_unref (stream);
		close (pipe_from_child);
		goto wait;
	}

	if (camel_stream_flush (stream, NULL, NULL) == -1) {
		g_object_unref (stream);
		close (pipe_from_child);
		goto wait;
	}

	g_object_unref (stream);

	stream = camel_stream_fs_new_with_fd (pipe_from_child);
	mem = camel_stream_mem_new ();
	if (camel_stream_write_to_stream (stream, mem, NULL, NULL) == -1) {
		g_object_unref (stream);
		g_object_unref (mem);
		goto wait;
	}

	g_object_unref (stream);

	g_seekable_seek (G_SEEKABLE (mem), 0, G_SEEK_SET, NULL, NULL);

	parser = camel_mime_parser_new ();
	camel_mime_parser_init_with_stream (parser, mem, NULL);
	camel_mime_parser_scan_from (parser, FALSE);
	g_object_unref (mem);

	message = camel_mime_message_new ();
	if (!camel_mime_part_construct_from_parser_sync (
		(CamelMimePart *) message, parser, NULL, NULL)) {
		gint err = camel_mime_parser_errno (parser);
		g_set_error (
			&driver->priv->error, G_IO_ERROR,
			g_io_error_from_errno (err),
			_("Invalid message stream received from %s: %s"),
			argv[0]->value.string, g_strerror (err));
		g_object_unref (message);
		message = NULL;
	} else {
		g_object_unref (driver->priv->message);
		driver->priv->message = message;
		driver->priv->modified = TRUE;
	}

	g_object_unref (parser);

 wait:
	context = g_main_context_new ();
	child_watch_data.loop = g_main_loop_new (context, FALSE);
	g_main_context_unref (context);

	source = g_child_watch_source_new (child_pid);
	g_source_set_callback (source, (GSourceFunc) child_watch, &child_watch_data, NULL);
	g_source_attach (source, g_main_loop_get_context (child_watch_data.loop));
	g_source_unref (source);

	g_main_loop_run (child_watch_data.loop);
	g_main_loop_unref (child_watch_data.loop);

#ifndef G_OS_WIN32
	if (message && WIFEXITED (child_watch_data.child_status))
		return WEXITSTATUS (child_watch_data.child_status);
	else
		return -1;
#else
	return child_watch_data.child_status;
#endif
}

static CamelSExpResult *
pipe_message (struct _CamelSExp *f,
              gint argc,
              struct _CamelSExpResult **argv,
              CamelFilterDriver *driver)
{
	gint i;

	/* make sure all args are strings */
	for (i = 0; i < argc; i++) {
		if (argv[i]->type != CAMEL_SEXP_RES_STRING)
			return NULL;
	}

	camel_filter_driver_log (
		driver, FILTER_LOG_ACTION,
		"Piping message to %s", argv[0]->value.string);
	pipe_to_system (f, argc, argv, driver);

	return NULL;
}

static CamelSExpResult *
do_shell (struct _CamelSExp *f,
          gint argc,
          struct _CamelSExpResult **argv,
          CamelFilterDriver *driver)
{
	GString *command;
	GPtrArray *args;
	gint i;

	d (fprintf (stderr, "executing shell command\n"));

	command = g_string_new ("");

	args = g_ptr_array_new ();

	/* make sure all args are strings */
	for (i = 0; i < argc; i++) {
		if (argv[i]->type != CAMEL_SEXP_RES_STRING)
			goto done;

		g_ptr_array_add (args, argv[i]->value.string);

		g_string_append (command, argv[i]->value.string);
		g_string_append_c (command, ' ');
	}

	g_string_truncate (command, command->len - 1);

	if (driver->priv->shellfunc && argc >= 1) {
		driver->priv->shellfunc (driver, argc, (gchar **) args->pdata, driver->priv->shelldata);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Executing shell command: [%s]", command->str);
	}

 done:

	g_ptr_array_free (args, TRUE);
	g_string_free (command, TRUE);

	return NULL;
}

static CamelSExpResult *
do_beep (struct _CamelSExp *f,
         gint argc,
         struct _CamelSExpResult **argv,
         CamelFilterDriver *driver)
{
	d (fprintf (stderr, "beep\n"));

	if (driver->priv->beep) {
		driver->priv->beep (driver, driver->priv->beepdata);
		camel_filter_driver_log (driver, FILTER_LOG_ACTION, "Beep");
	}

	return NULL;
}

static CamelSExpResult *
play_sound (struct _CamelSExp *f,
            gint argc,
            struct _CamelSExpResult **argv,
            CamelFilterDriver *driver)
{
	d (fprintf (stderr, "play sound\n"));

	if (driver->priv->playfunc && argc == 1 && argv[0]->type == CAMEL_SEXP_RES_STRING) {
		driver->priv->playfunc (driver, argv[0]->value.string, driver->priv->playdata);
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION, "Play sound");
	}

	return NULL;
}

static CamelSExpResult *
do_only_once (struct _CamelSExp *f,
              gint argc,
              struct _CamelSExpResult **argv,
              CamelFilterDriver *driver)
{
	d (fprintf (stderr, "only once\n"));

	if (argc == 2 && !g_hash_table_lookup (driver->priv->only_once, argv[0]->value.string))
		g_hash_table_insert (
			driver->priv->only_once,
			g_strdup (argv[0]->value.string),
			g_strdup (argv[1]->value.string));

	return NULL;
}

static CamelFolder *
open_folder (CamelFilterDriver *driver,
             const gchar *folder_url)
{
	CamelFolder *camelfolder;

	/* we have a lookup table of currently open folders */
	camelfolder = g_hash_table_lookup (driver->priv->folders, folder_url);
	if (camelfolder)
		return camelfolder == FOLDER_INVALID ? NULL : camelfolder;

	/* if we have a default folder, ignore exceptions.  This is so
	 * a bad filter rule on pop or local delivery doesn't result
	 * in duplicate mails, just mail going to inbox.  Otherwise,
	 * we want to know about exceptions and abort processing */
	if (driver->priv->defaultfolder) {
		camelfolder = driver->priv->get_folder (driver, folder_url, driver->priv->data, NULL);
	} else {
		camelfolder = driver->priv->get_folder (driver, folder_url, driver->priv->data, &driver->priv->error);
	}

	if (camelfolder) {
		g_hash_table_insert (driver->priv->folders, g_strdup (folder_url), camelfolder);
		camel_folder_freeze (camelfolder);
	} else {
		g_hash_table_insert (driver->priv->folders, g_strdup (folder_url), FOLDER_INVALID);
	}

	return camelfolder;
}

typedef struct _CloseFolderData {
	CamelFilterDriver *driver;
	gboolean can_call_refresh;
	GCancellable *cancellable;
} CloseFolderData;

static void
close_folder (gpointer key,
              gpointer value,
              gpointer user_data)
{
	CamelFolder *folder = value;
	CamelFilterDriver *driver;
	CloseFolderData *cfd = user_data;

	g_return_if_fail (cfd != NULL);

	driver = cfd->driver;

	driver->priv->closed++;
	g_free (key);

	if (folder != FOLDER_INVALID) {
		if (camel_folder_synchronize_sync (folder, FALSE, cfd->cancellable,
			(driver->priv->error != NULL) ? NULL : &driver->priv->error)) {
			if (cfd->can_call_refresh && cfd->cancellable) {
				camel_folder_refresh_info_sync (
					folder, cfd->cancellable,
					(driver->priv->error != NULL) ? NULL : &driver->priv->error);
			}
		}

		camel_folder_thaw (folder);
		g_object_unref (folder);
	}

	report_status (
		driver, CAMEL_FILTER_STATUS_PROGRESS,
		g_hash_table_size (driver->priv->folders) * 100 /
		driver->priv->closed, _("Syncing folders"));
}

/* flush/close all folders */
static gint
close_folders (CamelFilterDriver *driver,
	       gboolean can_call_refresh,
	       GCancellable *cancellable)
{
	CloseFolderData cfd;

	report_status (
		driver, CAMEL_FILTER_STATUS_PROGRESS,
		0, _("Syncing folders"));

	driver->priv->closed = 0;

	cfd.driver = driver;
	cfd.can_call_refresh = can_call_refresh;
	cfd.cancellable = cancellable;

	g_hash_table_foreach (driver->priv->folders, close_folder, &cfd);
	g_hash_table_destroy (driver->priv->folders);
	driver->priv->folders = g_hash_table_new (g_str_hash, g_str_equal);

	/* FIXME: status from driver */
	return 0;
}

#if 0
static void
free_key (gpointer key,
          gpointer value,
          gpointer user_data)
{
	g_free (key);
}
#endif

static void
camel_filter_driver_log (CamelFilterDriver *driver,
                         enum filter_log_t status,
                         const gchar *desc,
                         ...)
{
	if (driver->priv->logfile) {
		gchar *str = NULL;

		if (desc) {
			va_list ap;

			va_start (ap, desc);
			str = g_strdup_vprintf (desc, ap);
			va_end (ap);
		}

		switch (status) {
		case FILTER_LOG_START: {
			/* write log header */
			const gchar *subject = NULL;
			const gchar *from = NULL;
			gchar date[50];
			time_t t;

			/* FIXME: does this need locking?  Probably */

			from = camel_message_info_get_from (driver->priv->info);
			subject = camel_message_info_get_subject (driver->priv->info);

			time (&t);
			strftime (date, 49, "%Y-%m-%d %H:%M:%S", localtime (&t));
			fprintf (
				driver->priv->logfile,
				"%s - Applied filter \"%s\" to "
				"message from %s - \"%s\"\n",
				date, str, from ? from : "unknown",
				subject ? subject : "");

			break;
		}
		case FILTER_LOG_ACTION:
			fprintf (driver->priv->logfile, "Action: %s\n", str);
			break;
		case FILTER_LOG_INFO:
			fprintf (driver->priv->logfile, "%s\n", str);
			break;
		case FILTER_LOG_END:
			fprintf (driver->priv->logfile, "\n");
			break;
		default:
			/* nothing else is loggable */
			break;
		}

		g_free (str);

		fflush (driver->priv->logfile);
	}
}

struct _run_only_once {
	CamelFilterDriver *driver;
	GError *error;
};

static gboolean
run_only_once (gpointer key,
               gchar *action,
               struct _run_only_once *user_data)
{
	CamelFilterDriver *driver = user_data->driver;
	CamelSExpResult *r;

	d (printf ("evaluating: %s\n\n", action));

	camel_sexp_input_text (driver->priv->eval, action, strlen (action));
	if (camel_sexp_parse (driver->priv->eval) == -1) {
		if (user_data->error == NULL)
			g_set_error (
				&user_data->error,
				CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Error parsing filter: %s: %s"),
				camel_sexp_error (driver->priv->eval), action);
		goto done;
	}

	r = camel_sexp_eval (driver->priv->eval);
	if (r == NULL) {
		if (user_data->error == NULL)
			g_set_error (
				&user_data->error,
				CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Error executing filter: %s: %s"),
				camel_sexp_error (driver->priv->eval), action);
		goto done;
	}

	camel_sexp_result_free (driver->priv->eval, r);

 done:

	g_free (key);
	g_free (action);

	return TRUE;
}

/**
 * camel_filter_driver_flush:
 * @driver: a #CamelFilterDriver
 * @error: return location for a #GError, or %NULL
 *
 * Flush all of the only-once filter actions.
 **/
void
camel_filter_driver_flush (CamelFilterDriver *driver,
                           GError **error)
{
	struct _run_only_once data;

	if (!driver->priv->only_once)
		return;

	data.driver = driver;
	data.error = NULL;

	g_hash_table_foreach_remove (driver->priv->only_once, (GHRFunc) run_only_once, &data);

	if (data.error != NULL)
		g_propagate_error (error, data.error);
}

static gint
decode_flags_from_xev (const gchar *xev,
                       CamelMessageInfo *mi)
{
	guint32 uid, flags = 0;
	gchar *header;

	/* check for uid/flags */
	header = camel_header_token_decode (xev);
	if (!(header && strlen (header) == strlen ("00000000-0000")
	    && sscanf (header, "%08x-%04x", &uid, &flags) == 2)) {
		g_free (header);
		return 0;
	}
	g_free (header);

	camel_message_info_set_flags (mi, ~0, flags);

	return 0;
}

/**
 * camel_filter_driver_filter_mbox:
 * @driver: CamelFilterDriver
 * @mbox: mbox filename to be filtered
 * @original_source_url: (nullable): URI of the @mbox, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Filters an mbox file based on rules defined in the FilterDriver
 * object. Is more efficient as it doesn't need to open the folder
 * through Camel directly.
 *
 * Returns: -1 if errors were encountered during filtering,
 * otherwise returns 0.
 *
 **/
gint
camel_filter_driver_filter_mbox (CamelFilterDriver *driver,
                                 const gchar *mbox,
                                 const gchar *original_source_url,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelMimeParser *mp = NULL;
	gchar *source_url = NULL;
	gint fd = -1;
	gint i = 0;
	struct stat st;
	gint status;
	goffset last = 0;
	gint ret = -1;
	GError *local_error = NULL;

	fd = g_open (mbox, O_RDONLY | O_BINARY, 0);
	if (fd == -1) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Unable to open spool folder"));
		goto fail;
	}
	/* to get the filesize */
	if (fstat (fd, &st) != 0)
		st.st_size = 0;

	mp = camel_mime_parser_new ();
	camel_mime_parser_scan_from (mp, TRUE);
	if (camel_mime_parser_init_with_fd (mp, fd) == -1) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Unable to process spool folder"));
		goto fail;
	}
	fd = -1;

	if (driver->priv->transfers) {
		g_hash_table_destroy (driver->priv->transfers);
		driver->priv->transfers = NULL;
	}

	g_slist_free_full (driver->priv->delete_after_transfer, g_object_unref);
	driver->priv->delete_after_transfer = NULL;

	source_url = g_filename_to_uri (mbox, NULL, NULL);

	while (camel_mime_parser_step (mp, NULL, NULL) == CAMEL_MIME_PARSER_STATE_FROM) {
		CamelMessageInfo *info;
		CamelMimeMessage *message;
		const CamelNameValueArray *headers;
		CamelMimePart *mime_part;
		gint pc = 0;
		const gchar *xev;

		if (st.st_size > 0)
			pc = (gint)(100.0 * ((double) camel_mime_parser_tell (mp) / (double) st.st_size));

		if (pc > 0)
			camel_operation_progress (cancellable, pc);

		report_status (
			driver, CAMEL_FILTER_STATUS_START,
			pc, _("Getting message %d (%d%%)"), i, pc);

		message = camel_mime_message_new ();
		mime_part = CAMEL_MIME_PART (message);

		if (!camel_mime_part_construct_from_parser_sync (
			mime_part, mp, cancellable, error)) {
			report_status (
				driver, CAMEL_FILTER_STATUS_END,
				100, _("Failed on message %d"), i);
			g_object_unref (message);
			goto fail;
		}

		headers = camel_medium_get_headers (CAMEL_MEDIUM (mime_part));
		info = camel_message_info_new_from_headers (NULL, headers);
		/* Try and see if it has X-Evolution headers */
		xev = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Evolution");
		if (xev)
			decode_flags_from_xev (xev, info);

		camel_message_info_set_size (info, camel_mime_parser_tell (mp) - last);

		last = camel_mime_parser_tell (mp);
		status = filter_driver_filter_message_internal (
			driver, FALSE, message, info, NULL, NULL, source_url,
			original_source_url ? original_source_url :
			source_url, cancellable, &local_error);
		g_object_unref (message);
		if (local_error != NULL || status == -1) {
			report_status (
				driver, CAMEL_FILTER_STATUS_END,
				100, _("Failed on message %d"), i);
			g_clear_object (&info);
			g_propagate_error (error, local_error);
			local_error = NULL;
			goto fail;
		}

		i++;

		/* skip over the FROM_END state */
		camel_mime_parser_step (mp, NULL, NULL);

		g_clear_object (&info);
	}

	if (!filter_driver_process_transfers (driver, cancellable, &local_error)) {
		report_status (
			driver, CAMEL_FILTER_STATUS_END,
			100, _("Failed to transfer messages: %s"), local_error ? local_error->message : _("Unknown error"));
		g_propagate_error (error, local_error);
		goto fail;
	}

	camel_operation_progress (cancellable, 100);

	if (driver->priv->defaultfolder) {
		report_status (
			driver, CAMEL_FILTER_STATUS_PROGRESS,
			100, _("Syncing folder"));
		camel_folder_synchronize_sync (
			driver->priv->defaultfolder, FALSE, cancellable, NULL);
	}

	report_status (driver, CAMEL_FILTER_STATUS_END, 100, _("Complete"));

	ret = 0;
fail:
	g_free (source_url);
	if (fd != -1)
		close (fd);
	if (mp)
		g_object_unref (mp);

	return ret;
}

/**
 * camel_filter_driver_filter_folder:
 * @driver: CamelFilterDriver
 * @folder: CamelFolder to be filtered
 * @cache: UID cache (needed for POP folders)
 * @uids: (element-type utf8): message uids to be filtered or NULL (as a
 *        shortcut to filter all messages)
 * @remove: TRUE to mark filtered messages as deleted
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Filters a folder based on rules defined in the FilterDriver
 * object.
 *
 * Returns: -1 if errors were encountered during filtering,
 * otherwise returns 0.
 *
 **/
gint
camel_filter_driver_filter_folder (CamelFilterDriver *driver,
                                   CamelFolder *folder,
                                   CamelUIDCache *cache,
                                   GPtrArray *uids,
                                   gboolean remove,
                                   GCancellable *cancellable,
                                   GError **error)
{
	gboolean freeuids = FALSE;
	CamelMessageInfo *info;
	CamelStore *parent_store;
	const gchar *store_uid;
	gint status = 0;
	gint i;
	GError *local_error = NULL;

	parent_store = camel_folder_get_parent_store (folder);
	store_uid = camel_service_get_uid (CAMEL_SERVICE (parent_store));

	if (uids == NULL) {
		uids = camel_folder_get_uids (folder);
		freeuids = TRUE;
	}

	if (driver->priv->transfers) {
		g_hash_table_destroy (driver->priv->transfers);
		driver->priv->transfers = NULL;
	}

	g_slist_free_full (driver->priv->delete_after_transfer, g_object_unref);
	driver->priv->delete_after_transfer = NULL;

	for (i = 0; i < uids->len; i++) {
		gint pc = (100 * i) / uids->len;

		camel_operation_progress (cancellable, pc);

		report_status (
			driver, CAMEL_FILTER_STATUS_START,
			pc, _("Getting message %d of %d"),
			i + 1, uids->len);

		if (camel_folder_has_summary_capability (folder))
			info = camel_folder_get_message_info (folder, uids->pdata[i]);
		else
			info = NULL;

		status = filter_driver_filter_message_internal (
			driver, FALSE, NULL, info, uids->pdata[i], folder,
			store_uid, store_uid, cancellable, &local_error);

		if (camel_folder_has_summary_capability (folder))
			g_clear_object (&info);

		if (local_error != NULL || status == -1) {
			report_status (
				driver, CAMEL_FILTER_STATUS_END, 100,
				_("Failed at message %d of %d"),
				i + 1, uids->len);
			g_propagate_error (error, local_error);
			local_error = NULL;
			status = -1;
			break;
		}

		if (remove && !driver->priv->copied && !driver->priv->moved) {
			camel_folder_set_message_flags (
				folder, uids->pdata[i],
				CAMEL_MESSAGE_DELETED |
				CAMEL_MESSAGE_SEEN, ~0);
		} else if (remove) {
			info = camel_folder_get_message_info (folder, uids->pdata[i]);
			if (info)
				driver->priv->delete_after_transfer = g_slist_prepend (driver->priv->delete_after_transfer, info);
		}

		if (cache)
			camel_uid_cache_save_uid (cache, uids->pdata[i]);
		if (cache && (i % 10) == 0)
			camel_uid_cache_save (cache);
	}

	if (!filter_driver_process_transfers (driver, cancellable, &local_error)) {
		report_status (
			driver, CAMEL_FILTER_STATUS_END,
			100, _("Failed to transfer messages: %s"), local_error ? local_error->message : _("Unknown error"));
		g_propagate_error (error, local_error);
		status = -1;
	}

	camel_operation_progress (cancellable, 100);

	/* Save the cache of any pending mails. */
	if (cache)
		camel_uid_cache_save (cache);

	if (driver->priv->defaultfolder) {
		report_status (
			driver, CAMEL_FILTER_STATUS_PROGRESS,
			100, _("Syncing folder"));
		camel_folder_synchronize_sync (
			driver->priv->defaultfolder, FALSE, cancellable, NULL);
	}

	if (i == uids->len && status != -1)
		report_status (
			driver, CAMEL_FILTER_STATUS_END,
			100, _("Complete"));

	if (freeuids)
		camel_folder_free_uids (folder, uids);

	close_folders (driver, remove, cancellable);

	return status;
}

struct _get_message {
	struct _CamelFilterDriverPrivate *priv;
	const gchar *store_uid;
};

static CamelMimeMessage *
get_message_cb (gpointer data,
		GCancellable *cancellable,
                GError **error)
{
	struct _get_message *msgdata = data;
	CamelMimeMessage *message;

	if (msgdata->priv->message) {
		message = g_object_ref (msgdata->priv->message);
	} else {
		const gchar *uid;

		if (msgdata->priv->uid != NULL)
			uid = msgdata->priv->uid;
		else
			uid = camel_message_info_get_uid (msgdata->priv->info);

		message = camel_folder_get_message_sync (
			msgdata->priv->source, uid, cancellable, error);
	}

	if (message != NULL && camel_mime_message_get_source (message) == NULL)
		camel_mime_message_set_source (message, msgdata->store_uid);

	return message;
}

static gint
filter_driver_filter_message_internal (CamelFilterDriver *driver,
				       gboolean can_process_transfers,
				       CamelMimeMessage *message,
				       CamelMessageInfo *info,
				       const gchar *uid,
				       CamelFolder *source,
				       const gchar *store_uid,
				       const gchar *original_store_uid,
				       GCancellable *cancellable,
				       GError **error)
{
	CamelFilterDriverPrivate *p = driver->priv;
	gboolean freeinfo = FALSE;
	gboolean filtered = FALSE;
	CamelSExpResult *r;
	GList *list, *link;
	gint result;

	g_return_val_if_fail (message != NULL || (source != NULL && uid != NULL), -1);

	if (info == NULL) {
		const CamelNameValueArray *headers;

		if (message) {
			g_object_ref (message);
		} else {
			message = camel_folder_get_message_sync (
				source, uid, cancellable, error);
			if (!message)
				return -1;
		}

		headers = camel_medium_get_headers (CAMEL_MEDIUM (message));
		info = camel_message_info_new_from_headers (NULL, headers);
		freeinfo = TRUE;
	} else {
		if (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED)
			return 0;

		uid = camel_message_info_get_uid (info);

		if (message)
			g_object_ref (message);
	}

	if (can_process_transfers) {
		if (driver->priv->transfers) {
			g_hash_table_destroy (driver->priv->transfers);
			driver->priv->transfers = NULL;
		}

		g_slist_free_full (driver->priv->delete_after_transfer, g_object_unref);
		driver->priv->delete_after_transfer = NULL;
	}

	driver->priv->terminated = FALSE;
	driver->priv->deleted = FALSE;
	driver->priv->copied = FALSE;
	driver->priv->moved = FALSE;
	driver->priv->message = message;
	driver->priv->info = info;
	driver->priv->uid = uid;
	driver->priv->source = source;

	if (message != NULL && camel_mime_message_get_source (message) == NULL)
		camel_mime_message_set_source (message, original_store_uid);

	if (g_strcmp0 (store_uid, "local") == 0 ||
	    g_strcmp0 (store_uid, "vfolder") == 0) {
		store_uid = NULL;
	}

	if (g_strcmp0 (original_store_uid, "local") == 0 ||
	    g_strcmp0 (original_store_uid, "vfolder") == 0) {
		original_store_uid = NULL;
	}

	list = g_queue_peek_head_link (&driver->priv->rules);
	result = CAMEL_SEARCH_NOMATCH;
	filtered = list != NULL;

	for (link = list; link != NULL; link = g_list_next (link)) {
		struct _filter_rule *rule = link->data;
		struct _get_message data;

		if (driver->priv->terminated) {
			camel_filter_driver_log (driver, FILTER_LOG_INFO, "Stopped processing per request");
			break;
		}

		if (g_cancellable_set_error_if_cancelled (cancellable, &driver->priv->error)) {
			camel_filter_driver_log (driver, FILTER_LOG_INFO, "Stopped processing on cancel");
			goto error;
		}

		d (printf ("applying rule %s\naction %s\n", rule->match, rule->action));

		data.priv = p;
		data.store_uid = original_store_uid;

		if (original_store_uid == NULL)
			original_store_uid = store_uid;

		camel_filter_driver_log (driver, FILTER_LOG_START, "%s", rule->name);

		result = camel_filter_search_match_with_log (
			driver->priv->session, get_message_cb, &data, driver->priv->info,
			original_store_uid, source, rule->match, driver->priv->logfile, cancellable, &driver->priv->error);

		switch (result) {
		case CAMEL_SEARCH_ERROR:
			camel_filter_driver_log (driver, FILTER_LOG_INFO, "   Execution of filter '%s' failed: %s\n",
				rule->name, driver->priv->error ? driver->priv->error->message : "Unknown error");

			g_prefix_error (
				&driver->priv->error,
				_("Execution of filter “%s” failed: "),
				rule->name);
			goto error;
		case CAMEL_SEARCH_MATCHED:
			camel_filter_driver_log (driver, FILTER_LOG_INFO, "   Filter '%s' matched\n", rule->name);

			/* perform necessary filtering actions */
			camel_sexp_input_text (
				driver->priv->eval,
				rule->action, strlen (rule->action));
			if (camel_sexp_parse (driver->priv->eval) == -1) {
				g_set_error (
					error, CAMEL_ERROR,
					CAMEL_ERROR_GENERIC,
					_("Error parsing filter “%s”: %s: %s"),
					rule->name,
					camel_sexp_error (driver->priv->eval),
					rule->action);
				goto error;
			}
			r = camel_sexp_eval (driver->priv->eval);
			if (driver->priv->error != NULL) {
				g_prefix_error (
					&driver->priv->error,
					_("Execution of filter “%s” failed: "),
					rule->name);
				goto error;
			}

			if (r == NULL) {
				g_set_error (
					error, CAMEL_ERROR,
					CAMEL_ERROR_GENERIC,
					_("Error executing filter “%s”: %s: %s"),
					rule->name,
					camel_sexp_error (driver->priv->eval),
					rule->action);
				goto error;
			}
			camel_sexp_result_free (driver->priv->eval, r);
			break;
		case CAMEL_SEARCH_NOMATCH:
			camel_filter_driver_log (driver, FILTER_LOG_INFO, "   Filter '%s' did not match\n", rule->name);
			break;
		default:
			break;
		}
	}

	if (can_process_transfers) {
		if (!filter_driver_process_transfers (driver, cancellable, &driver->priv->error))
			goto error;
	}

	/* *Now* we can set the DELETED flag... */
	if (driver->priv->deleted) {
		if (can_process_transfers || (!driver->priv->moved && !driver->priv->copied)) {
			if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
				camel_folder_set_message_flags (
					driver->priv->source, driver->priv->uid,
					CAMEL_MESSAGE_DELETED |
					CAMEL_MESSAGE_SEEN, ~0);
			else
				camel_message_info_set_flags (
					info, CAMEL_MESSAGE_DELETED |
					CAMEL_MESSAGE_SEEN |
					CAMEL_MESSAGE_FOLDER_FLAGGED, ~0);
		} else {
			/* Set the DELETED flag only after the messages are really transferred */
			CamelMessageInfo *nfo;

			if (driver->priv->source && driver->priv->uid && camel_folder_has_summary_capability (driver->priv->source))
				nfo = camel_folder_get_message_info (driver->priv->source, driver->priv->uid);
			else
				nfo = g_object_ref (info);

			if (nfo)
				driver->priv->delete_after_transfer = g_slist_prepend (driver->priv->delete_after_transfer, nfo);
		}
	}

	/* Logic: if !Moved and there exists a default folder... */
	if (!(driver->priv->copied && driver->priv->deleted) && !driver->priv->moved && driver->priv->defaultfolder) {
		/* copy it to the default inbox */
		filtered = TRUE;
		camel_filter_driver_log (
			driver, FILTER_LOG_ACTION,
			"Copy to default folder");

		if (!driver->priv->modified && driver->priv->uid && driver->priv->source && camel_folder_has_summary_capability (driver->priv->source)) {
			GPtrArray *uids;

			uids = g_ptr_array_new ();
			g_ptr_array_add (uids, (gchar *) driver->priv->uid);
			camel_folder_transfer_messages_to_sync (
				driver->priv->source, uids, driver->priv->defaultfolder,
				FALSE, NULL, cancellable, &driver->priv->error);
			g_ptr_array_free (uids, TRUE);
		} else {
			if (driver->priv->message == NULL) {
				driver->priv->message = camel_folder_get_message_sync (
					source, uid, cancellable, error);
				if (!driver->priv->message)
					goto error;
			}

			camel_folder_append_message_sync (
				driver->priv->defaultfolder,
				driver->priv->message,
				driver->priv->info, NULL,
				cancellable,
				&driver->priv->error);
		}
	}

	if (driver->priv->message)
		g_object_unref (driver->priv->message);

	if (freeinfo)
		g_clear_object (&info);

	return 0;

 error:
	if (filtered)
		camel_filter_driver_log (driver, FILTER_LOG_END, NULL);

	if (driver->priv->message)
		g_object_unref (driver->priv->message);

	if (freeinfo)
		g_clear_object (&info);

	g_propagate_error (error, driver->priv->error);
	driver->priv->error = NULL;

	return -1;
}

/**
 * camel_filter_driver_filter_message:
 * @driver: CamelFilterDriver
 * @message: message to filter or NULL
 * @info: message info or NULL
 * @uid: message uid or NULL
 * @source: source folder or NULL
 * @store_uid: UID of source store, or %NULL
 * @original_store_uid: UID of source store (pre-movemail), or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Filters a message based on rules defined in the FilterDriver
 * object. If the source folder (@source) and the uid (@uid) are
 * provided, the filter will operate on the CamelFolder (which in
 * certain cases is more efficient than using the default
 * camel_folder_append_message() function).
 *
 * Returns: -1 if errors were encountered during filtering,
 * otherwise returns 0.
 *
 **/
gint
camel_filter_driver_filter_message (CamelFilterDriver *driver,
                                    CamelMimeMessage *message,
                                    CamelMessageInfo *info,
                                    const gchar *uid,
                                    CamelFolder *source,
                                    const gchar *store_uid,
                                    const gchar *original_store_uid,
                                    GCancellable *cancellable,
                                    GError **error)
{
	return filter_driver_filter_message_internal (driver, TRUE, message,
		info, uid, source, store_uid, original_store_uid, cancellable, error);
}

/**
 * camel_filter_driver_log_info:
 * @driver: (nullable): a #CamelFilterDriver, or %NULL
 * @format: a printf-like format to use for the informational log entry
 * @...: arguments for @format
 *
 * Logs an informational message to a filter log. The function does
 * nothing when @driver is %NULL or when there is no log file being
 * set in @driver.
 *
 * Since: 3.24
 **/
void
camel_filter_driver_log_info (CamelFilterDriver *driver,
			      const gchar *format,
			      ...)
{
	gchar *str;
	va_list ap;

	if (!driver || !driver->priv->logfile)
		return;

	g_return_if_fail (format != NULL);

	va_start (ap, format);
	str = g_strdup_vprintf (format, ap);
	va_end (ap);

	camel_filter_driver_log (driver, FILTER_LOG_INFO, "%s", str);

	g_free (str);
}
