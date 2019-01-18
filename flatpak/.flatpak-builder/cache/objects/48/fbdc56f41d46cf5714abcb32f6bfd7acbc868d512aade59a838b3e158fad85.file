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
 * Authors: Not Zed <notzed@lostzed.mmc.com.au>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#ifndef _WIN32
#include <sys/uio.h>
#else
#include <winsock2.h>
#endif

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-maildir-message-info.h"
#include "camel-maildir-summary.h"

#define CAMEL_MAILDIR_SUMMARY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MAILDIR_SUMMARY, CamelMaildirSummaryPrivate))

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#define CAMEL_MAILDIR_SUMMARY_VERSION (0x2000)

static CamelMessageInfo *
		message_info_new_from_headers	(CamelFolderSummary *,
						 const CamelNameValueArray *);
static gint	maildir_summary_load		(CamelLocalSummary *cls,
						 gint forceindex,
						 GError **error);
static gint	maildir_summary_check		(CamelLocalSummary *cls,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static gint	maildir_summary_sync		(CamelLocalSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static CamelMessageInfo *
		maildir_summary_add		(CamelLocalSummary *cls,
						 CamelMimeMessage *msg,
						 const CamelMessageInfo *info,
						 CamelFolderChangeInfo *,
						 GError **error);

static gchar *	maildir_summary_next_uid_string	(CamelFolderSummary *s);
static gint	maildir_summary_decode_x_evolution
						(CamelLocalSummary *cls,
						 const gchar *xev,
						 CamelMessageInfo *mi);
static gchar *	maildir_summary_encode_x_evolution
						(CamelLocalSummary *cls,
						 const CamelMessageInfo *mi);

typedef struct _CamelMaildirMessageContentInfo CamelMaildirMessageContentInfo;

struct _CamelMaildirSummaryPrivate {
	gchar *current_file;
	gchar *hostname;

	GHashTable *load_map;
	GMutex summary_lock;
};

struct _CamelMaildirMessageContentInfo {
	CamelMessageContentInfo info;
};

G_DEFINE_TYPE (
	CamelMaildirSummary,
	camel_maildir_summary,
	CAMEL_TYPE_LOCAL_SUMMARY)

static void
maildir_summary_finalize (GObject *object)
{
	CamelMaildirSummaryPrivate *priv;

	priv = CAMEL_MAILDIR_SUMMARY_GET_PRIVATE (object);

	g_free (priv->hostname);
	g_mutex_clear (&priv->summary_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_maildir_summary_parent_class)->finalize (object);
}

static void
camel_maildir_summary_class_init (CamelMaildirSummaryClass *class)
{
	GObjectClass *object_class;
	CamelFolderSummaryClass *folder_summary_class;
	CamelLocalSummaryClass *local_summary_class;

	g_type_class_add_private (class, sizeof (CamelMaildirSummaryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = maildir_summary_finalize;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->message_info_type = CAMEL_TYPE_MAILDIR_MESSAGE_INFO;
	folder_summary_class->sort_by = "dreceived";
	folder_summary_class->collate = NULL;
	folder_summary_class->message_info_new_from_headers = message_info_new_from_headers;
	folder_summary_class->next_uid_string = maildir_summary_next_uid_string;

	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (class);
	local_summary_class->load = maildir_summary_load;
	local_summary_class->check = maildir_summary_check;
	local_summary_class->sync = maildir_summary_sync;
	local_summary_class->add = maildir_summary_add;
	local_summary_class->encode_x_evolution = maildir_summary_encode_x_evolution;
	local_summary_class->decode_x_evolution = maildir_summary_decode_x_evolution;
}

static void
camel_maildir_summary_init (CamelMaildirSummary *maildir_summary)
{
	CamelFolderSummary *folder_summary;
	gchar hostname[256];

	folder_summary = CAMEL_FOLDER_SUMMARY (maildir_summary);

	maildir_summary->priv =
		CAMEL_MAILDIR_SUMMARY_GET_PRIVATE (maildir_summary);

	/* set unique file version */
	camel_folder_summary_set_version (folder_summary, camel_folder_summary_get_version (folder_summary) + CAMEL_MAILDIR_SUMMARY_VERSION);

	if (gethostname (hostname, 256) == 0) {
		maildir_summary->priv->hostname = g_strdup (hostname);
	} else {
		maildir_summary->priv->hostname = g_strdup ("localhost");
	}
	g_mutex_init (&maildir_summary->priv->summary_lock);
}

/**
 * camel_maildir_summary_new:
 * @folder: parent folder.
 * @maildirdir: a maildir directory for the new summary
 * @index: (nullable): an optional #CamelIndex to use, or %NULL
 *
 * Create a new CamelMaildirSummary object.
 *
 * Returns: (transfer full): A new #CamelMaildirSummary object
 **/
CamelMaildirSummary *
camel_maildir_summary_new (struct _CamelFolder *folder,
			   const gchar *maildirdir,
			   CamelIndex *index)
{
	CamelMaildirSummary *o;

	o = g_object_new (CAMEL_TYPE_MAILDIR_SUMMARY, "folder", folder, NULL);
	if (folder) {
		CamelStore *parent_store;

		parent_store = camel_folder_get_parent_store (folder);
		camel_db_set_collate (camel_store_get_db (parent_store), "dreceived", NULL, NULL);
	}
	camel_local_summary_construct ((CamelLocalSummary *) o, maildirdir, index);
	return o;
}

/* the 'standard' maildir flags.  should be defined in sorted order. */
static struct {
	gchar flag;
	guint32 flagbit;
} flagbits[] = {
	{ 'D', CAMEL_MESSAGE_DRAFT },
	{ 'F', CAMEL_MESSAGE_FLAGGED },
	/*{ 'P', CAMEL_MESSAGE_FORWARDED },*/
	{ 'R', CAMEL_MESSAGE_ANSWERED },
	{ 'S', CAMEL_MESSAGE_SEEN },
	{ 'T', CAMEL_MESSAGE_DELETED },
};

/* convert the uid + flags into a unique:info maildir format */
gchar *
camel_maildir_summary_uid_and_flags_to_name (const gchar *uid,
					     guint32 flags)
{
	gchar *p, *buf;
	gint i;

	g_return_val_if_fail (uid != NULL, NULL);

	buf = g_alloca (strlen (uid) + strlen (CAMEL_MAILDIR_FLAG_SEP_S "2,") + G_N_ELEMENTS (flagbits) + 1);
	p = buf + sprintf (buf, "%s" CAMEL_MAILDIR_FLAG_SEP_S "2,", uid);
	for (i = 0; i < G_N_ELEMENTS (flagbits); i++) {
		if ((flags & flagbits[i].flagbit) != 0)
			*p++ = flagbits[i].flag;
	}

	*p = 0;

	return g_strdup (buf);
}

gchar *
camel_maildir_summary_info_to_name (const CamelMessageInfo *info)
{
	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (info), NULL);

	return camel_maildir_summary_uid_and_flags_to_name (
		camel_message_info_get_uid (info),
		camel_message_info_get_flags (info));
}

/* returns whether the @info changed */
gboolean
camel_maildir_summary_name_to_info (CamelMessageInfo *info,
				    const gchar *name)
{
	gchar *p, c;
	guint32 set = 0;	/* what we set */
	gint i;

	p = strstr (name, CAMEL_MAILDIR_FLAG_SEP_S "2,");

	if (p) {
		guint32 flags;

		flags = camel_message_info_get_flags (info);

		p += 3;
		while ((c = *p++)) {
			/* we could assume that the flags are in order, but its just as easy not to require */
			for (i = 0; i < G_N_ELEMENTS (flagbits); i++) {
				if (flagbits[i].flag == c && (flags & flagbits[i].flagbit) == 0) {
					set |= flagbits[i].flagbit;
				}
			}
		}

		/* changed? */
		if ((flags & set) != set) {
			return camel_message_info_set_flags (info, set, set);
		}
	}

	return FALSE;
}

/* for maildir, x-evolution isn't used, so dont try and get anything out of it */
static gint maildir_summary_decode_x_evolution (CamelLocalSummary *cls, const gchar *xev, CamelMessageInfo *mi)
{
	return -1;
}

static gchar *maildir_summary_encode_x_evolution (CamelLocalSummary *cls, const CamelMessageInfo *mi)
{
	return NULL;
}

/* FIXME:
 * both 'new' and 'add' will try and set the filename, this is not ideal ...
*/
static CamelMessageInfo *
maildir_summary_add (CamelLocalSummary *cls,
                     CamelMimeMessage *msg,
                     const CamelMessageInfo *info,
                     CamelFolderChangeInfo *changes,
                     GError **error)
{
	CamelLocalSummaryClass *local_summary_class;
	CamelMessageInfo *mi;

	/* Chain up to parent's add() method. */
	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (camel_maildir_summary_parent_class);
	mi = local_summary_class->add (cls, msg, info, changes, error);
	if (mi) {
		if (info) {
			CamelMaildirMessageInfo *mdi = CAMEL_MAILDIR_MESSAGE_INFO (mi);

			camel_maildir_message_info_take_filename (mdi, camel_maildir_summary_info_to_name (mi));
			d (printf ("Setting filename to %s\n", camel_maildir_message_info_get_filename (mdi)));

			/* Inherit the Received date from the passed-in info only if it is set and
			   the new message info doesn't have it set or it's set to the default
			   value, derived from the message UID. */
			if (camel_message_info_get_date_received (info) > 0 &&
			    (camel_message_info_get_date_received (mi) <= 0 ||
			    (camel_message_info_get_uid (mi) &&
			     camel_message_info_get_date_received (mi) == strtoul (camel_message_info_get_uid (mi), NULL, 10))))
				camel_message_info_set_date_received (mi, camel_message_info_get_date_received (info));
		}
	}

	return mi;
}

static CamelMessageInfo *
message_info_new_from_headers (CamelFolderSummary *summary,
			       const CamelNameValueArray *headers)
{
	CamelMessageInfo *mi, *info;
	CamelMaildirSummary *mds = (CamelMaildirSummary *) summary;
	const gchar *uid;

	mi = ((CamelFolderSummaryClass *) camel_maildir_summary_parent_class)->message_info_new_from_headers (summary, headers);
	/* assign the uid and new filename */
	if (mi) {
		uid = camel_message_info_get_uid (mi);
		if (uid == NULL || uid[0] == 0) {
			gchar *new_uid = camel_folder_summary_next_uid_string (summary);

			camel_message_info_set_uid (mi, new_uid);
			g_free (new_uid);
		}

		/* handle 'duplicates' */
		info = (uid && *uid) ? camel_folder_summary_peek_loaded (summary, uid) : NULL;
		if (info) {
			d (printf ("already seen uid '%s', just summarising instead\n", uid));
			g_clear_object (&mi);
			mi = info;
		}

		if (camel_message_info_get_date_received (mi) <= 0) {
			/* with maildir we know the real received date, from the filename */
			camel_message_info_set_date_received (mi, strtoul (camel_message_info_get_uid (mi), NULL, 10));
		}

		if (mds->priv->current_file) {
#if 0
			gchar *p1, *p2, *p3;
			gulong uid;
#endif
			/* if setting from a file, grab the flags from it */
			camel_maildir_message_info_take_filename (CAMEL_MAILDIR_MESSAGE_INFO (mi), g_strdup (mds->priv->current_file));
			camel_maildir_summary_name_to_info (mi, mds->priv->current_file);

#if 0
			/* Actually, I dont think all this effort is worth it at all ... */

			/* also, see if we can extract the next-id from tne name, and safe-if-fy ourselves against collisions */
			/* we check for something.something_number.something */
			p1 = strchr (mdi->filename, '.');
			if (p1) {
				p2 = strchr (p1 + 1, '.');
				p3 = strchr (p1 + 1, '_');
				if (p2 && p3 && p3 < p2) {
					uid = strtoul (p3 + 1, &p1, 10);
					if (p1 == p2 && uid > 0)
						camel_folder_summary_set_uid (s, uid);
				}
			}
#endif
		} else {
			/* if creating a file, set its name from the flags we have */
			camel_maildir_message_info_take_filename (CAMEL_MAILDIR_MESSAGE_INFO (mi), camel_maildir_summary_info_to_name (mi));
			d (printf ("Setting filename to %s\n", camel_maildir_message_info_get_filename (CAMEL_MAILDIR_MESSAGE_INFO (mi))));
		}
	}

	return mi;
}

static gchar *
maildir_summary_next_uid_string (CamelFolderSummary *s)
{
	CamelMaildirSummary *mds = (CamelMaildirSummary *) s;

	d (printf ("next uid string called?\n"));

	/* if we have a current file, then use that to get the uid */
	if (mds->priv->current_file) {
		gchar *cln;

		cln = strchr (mds->priv->current_file, CAMEL_MAILDIR_FLAG_SEP);
		if (cln)
			return g_strndup (mds->priv->current_file, cln - mds->priv->current_file);
		else
			return g_strdup (mds->priv->current_file);
	} else {
		/* the first would probably work, but just to be safe, check for collisions */
#if 0
		return g_strdup_printf ("%ld.%d_%u.%s", time (0), getpid (), camel_folder_summary_next_uid (s), mds->priv->hostname);
#else
		CamelLocalSummary *cls = (CamelLocalSummary *) s;
		gchar *name = NULL, *uid = NULL;
		struct stat st;
		gint retry = 0;
		guint32 nextuid = camel_folder_summary_next_uid (s);

		/* we use time.pid_count.hostname */
		do {
			if (retry > 0) {
				g_free (name);
				g_free (uid);
				g_usleep (2 * G_USEC_PER_SEC);
			}
			uid = g_strdup_printf ("%" G_GINT64_FORMAT ".%d_%u.%s", (gint64) time (NULL), getpid (), nextuid, mds->priv->hostname);
			name = g_strdup_printf ("%s/tmp/%s", cls->folder_path, uid);
			retry++;
		} while (g_stat (name, &st) == 0 && retry < 3);

		/* I dont know what we're supposed to do if it fails to find a unique name?? */

		g_free (name);
		return uid;
#endif
	}
}

static gint
maildir_summary_load (CamelLocalSummary *cls,
                      gint forceindex,
                      GError **error)
{
	CamelLocalSummaryClass *local_summary_class;
	gchar *cur;
	DIR *dir;
	struct dirent *d;
	CamelMaildirSummary *mds = (CamelMaildirSummary *) cls;
	gchar *uid;
	CamelMemPool *pool;
	gint ret;

	cur = g_strdup_printf ("%s/cur", cls->folder_path);

	d (printf ("pre-loading uid <> filename map\n"));

	dir = opendir (cur);
	if (dir == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot open maildir directory path: %s: %s"),
			cls->folder_path, g_strerror (errno));
		g_free (cur);
		return -1;
	}

	mds->priv->load_map = g_hash_table_new (g_str_hash, g_str_equal);
	pool = camel_mempool_new (1024, 512, CAMEL_MEMPOOL_ALIGN_BYTE);

	while ((d = readdir (dir))) {
		if (d->d_name[0] == '.')
			continue;

		/* map the filename -> uid */
		uid = strchr (d->d_name, CAMEL_MAILDIR_FLAG_SEP);
		if (uid) {
			gint len = uid - d->d_name;
			uid = camel_mempool_alloc (pool, len + 1);
			memcpy (uid, d->d_name, len);
			uid[len] = 0;
			g_hash_table_insert (mds->priv->load_map, uid, camel_mempool_strdup (pool, d->d_name));
		} else {
			uid = camel_mempool_strdup (pool, d->d_name);
			g_hash_table_insert (mds->priv->load_map, uid, uid);
		}
	}
	closedir (dir);
	g_free (cur);

	/* Chain up to parent's load() method. */
	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (camel_maildir_summary_parent_class);
	ret = local_summary_class->load (cls, forceindex, error);

	g_hash_table_destroy (mds->priv->load_map);
	mds->priv->load_map = NULL;
	camel_mempool_destroy (pool);

	return ret;
}

static gint
camel_maildir_summary_add (CamelLocalSummary *cls,
                           const gchar *name,
                           gint forceindex,
                           GCancellable *cancellable)
{
	CamelMessageInfo *info;
	CamelFolderSummary *summary;
	CamelMaildirSummary *maildirs = (CamelMaildirSummary *) cls;
	gchar *filename = g_strdup_printf ("%s/cur/%s", cls->folder_path, name);
	gint fd;
	CamelMimeParser *mp;

	d (printf ("summarising: %s\n", name));

	summary = CAMEL_FOLDER_SUMMARY (cls);

	fd = open (filename, O_RDONLY | O_LARGEFILE);
	if (fd == -1) {
		g_warning ("Cannot summarise/index: %s: %s", filename, g_strerror (errno));
		g_free (filename);
		return -1;
	}
	mp = camel_mime_parser_new ();
	camel_mime_parser_scan_from (mp, FALSE);
	camel_mime_parser_init_with_fd (mp, fd);
	if (cls->index && (forceindex || !camel_index_has_name (cls->index, name))) {
		d (printf ("forcing indexing of message content\n"));
		camel_folder_summary_set_index (summary, cls->index);
	} else {
		camel_folder_summary_set_index (summary, NULL);
	}
	maildirs->priv->current_file = (gchar *) name;

	info = camel_folder_summary_info_new_from_parser (summary, mp);
	camel_folder_summary_add (summary, info, FALSE);
	g_clear_object (&info);

	g_object_unref (mp);
	maildirs->priv->current_file = NULL;
	camel_folder_summary_set_index (summary, NULL);
	g_free (filename);
	return 0;
}

struct _remove_data {
	CamelLocalSummary *cls;
	CamelFolderChangeInfo *changes;
	GList *removed_uids;
};

static void
remove_summary (const gchar *uid,
                gpointer value,
                struct _remove_data *rd)
{
	d (printf ("removing message %s from summary\n", uid));
	if (rd->cls->index)
		camel_index_delete_name (rd->cls->index, uid);
	if (rd->changes)
		camel_folder_change_info_remove_uid (rd->changes, uid);
	rd->removed_uids = g_list_prepend (rd->removed_uids, (gpointer) uid);
}

static gint
maildir_summary_check (CamelLocalSummary *cls,
                       CamelFolderChangeInfo *changes,
                       GCancellable *cancellable,
                       GError **error)
{
	DIR *dir;
	struct dirent *d;
	gchar *p;
	CamelFolderSummary *s = (CamelFolderSummary *) cls;
	GHashTable *left;
	gint i, count, total;
	gint forceindex;
	gchar *new, *cur;
	gchar *uid;
	struct _remove_data rd = { cls, changes, NULL };
	GPtrArray *known_uids;

	g_mutex_lock (&((CamelMaildirSummary *) cls)->priv->summary_lock);

	new = g_strdup_printf ("%s/new", cls->folder_path);
	cur = g_strdup_printf ("%s/cur", cls->folder_path);

	d (printf ("checking summary ...\n"));

	camel_operation_push_message (
		cancellable, _("Checking folder consistency"));

	/* scan the directory, check for mail files not in the index, or index entries that
	 * no longer exist */
	dir = opendir (cur);
	if (dir == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot open maildir directory path: %s: %s"),
			cls->folder_path, g_strerror (errno));
		g_free (cur);
		g_free (new);
		camel_operation_pop_message (cancellable);
		g_mutex_unlock (&((CamelMaildirSummary *) cls)->priv->summary_lock);
		return -1;
	}

	/* keeps track of all uid's that have not been processed */
	left = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, NULL);
	known_uids = camel_folder_summary_get_array (s);
	forceindex = !known_uids || known_uids->len == 0;
	for (i = 0; known_uids && i < known_uids->len; i++) {
		const gchar *uid = g_ptr_array_index (known_uids, i);
		guint32 flags;

		flags = camel_folder_summary_get_info_flags ((CamelFolderSummary *) cls, uid);
		if (flags != (~0)) {
			g_hash_table_insert (left, (gchar *) camel_pstring_strdup (uid), GUINT_TO_POINTER (flags));
		}
	}

	/* joy, use this to pre-count the total, so we can report progress meaningfully */
	total = 0;
	count = 0;
	while (readdir (dir))
		total++;
	rewinddir (dir);

	while ((d = readdir (dir))) {
		guint32 stored_flags = 0;
		gint pc;

		/* Avoid a potential division by zero if the first loop
		 * (to calculate total) is executed on an empty
		 * directory, then the directory is populated before
		 * this loop is executed. */
		total = MAX (total, count + 1);
		pc = (total > 0) ? count * 100 / total : 0;

		camel_operation_progress (cancellable, pc);
		count++;

		/* FIXME: also run stat to check for regular file */
		p = d->d_name;
		if (p[0] == '.')
			continue;

		/* map the filename -> uid */
		uid = strchr (d->d_name, CAMEL_MAILDIR_FLAG_SEP);
		if (uid)
			uid = g_strndup (d->d_name, uid - d->d_name);
		else
			uid = g_strdup (d->d_name);

		if (g_hash_table_contains (left, uid)) {
			stored_flags = GPOINTER_TO_UINT (g_hash_table_lookup (left, uid));
			g_hash_table_remove (left, uid);
		}

		if (!camel_folder_summary_check_uid ((CamelFolderSummary *) cls, uid)) {
			/* must be a message incorporated by another client, this is not a 'recent' uid */
			if (camel_maildir_summary_add (cls, d->d_name, forceindex, cancellable) == 0)
				if (changes)
					camel_folder_change_info_add_uid (changes, uid);
		} else {
			CamelMaildirMessageInfo *mdi;
			CamelMessageInfo *info;
			gchar *expected_filename;

			if (cls->index && (!camel_index_has_name (cls->index, uid))) {
				/* message_info_new will handle duplicates */
				camel_maildir_summary_add (cls, d->d_name, forceindex, cancellable);
			}

			info = camel_folder_summary_peek_loaded ((CamelFolderSummary *) cls, uid);
			mdi = info ? CAMEL_MAILDIR_MESSAGE_INFO (info) : NULL;

			expected_filename = camel_maildir_summary_uid_and_flags_to_name (uid, stored_flags);
			if ((mdi && !camel_maildir_message_info_get_filename (mdi)) ||
			    !expected_filename ||
			    strcmp (expected_filename, d->d_name) != 0) {
				if (!mdi) {
					g_clear_object (&info);
					info = camel_folder_summary_get ((CamelFolderSummary *) cls, uid);
					mdi = info ? CAMEL_MAILDIR_MESSAGE_INFO (info) : NULL;
				}

				g_warn_if_fail (mdi != NULL);

				if (mdi)
					camel_maildir_message_info_set_filename (mdi, d->d_name);
			}

			g_free (expected_filename);
			g_clear_object (&info);
		}
		g_free (uid);
	}
	closedir (dir);
	g_hash_table_foreach (left, (GHFunc) remove_summary, &rd);

	if (rd.removed_uids)
		camel_folder_summary_remove_uids ((CamelFolderSummary *) cls, rd.removed_uids);
	g_list_free (rd.removed_uids);

	/* Destroy the hash table only after the removed_uids GList is freed, because it has borrowed the UIDs */
	g_hash_table_destroy (left);

	camel_operation_pop_message (cancellable);

	camel_operation_push_message (
		cancellable, _("Checking for new messages"));

	/* now, scan new for new messages, and copy them to cur, and so forth */
	dir = opendir (new);
	if (dir != NULL) {
		total = 0;
		count = 0;
		while (readdir (dir))
			total++;
		rewinddir (dir);

		while ((d = readdir (dir))) {
			gchar *name, *newname, *destname, *destfilename;
			gchar *src, *dest;
			gint pc;

			/* Avoid a potential division by zero if the first loop
			 * (to calculate total) is executed on an empty
			 * directory, then the directory is populated before
			 * this loop is executed. */
			total = MAX (total, count + 1);
			pc = (total > 0) ? count * 100 / total : 0;

			camel_operation_progress (cancellable, pc);
			count++;

			name = d->d_name;
			if (name[0] == '.')
				continue;

			/* already in summary?  shouldn't happen, but just incase ... */
			if (camel_folder_summary_check_uid ((CamelFolderSummary *) cls, name)) {
				newname = destname = camel_folder_summary_next_uid_string (s);
			} else {
				gchar *nm;
				newname = g_strdup (name);
				nm =strrchr (newname, CAMEL_MAILDIR_FLAG_SEP);
				if (nm)
					*nm = '\0';
				destname = newname;
			}

			/* copy this to the destination folder, use 'standard' semantics for maildir info field */
			src = g_strdup_printf ("%s/%s", new, name);
			destfilename = g_strdup_printf ("%s" CAMEL_MAILDIR_FLAG_SEP_S "2,", destname);
			dest = g_strdup_printf ("%s/%s", cur, destfilename);

			/* FIXME: This should probably use link/unlink */

			if (g_rename (src, dest) == 0) {
				camel_maildir_summary_add (cls, destfilename, forceindex, cancellable);
				if (changes) {
					camel_folder_change_info_add_uid (changes, destname);
					camel_folder_change_info_recent_uid (changes, destname);
				}
			} else {
				/* else?  we should probably care about failures, but wont */
				g_warning ("Failed to move new maildir message %s to cur %s", src, dest);
			}

			/* c strings are painful to work with ... */
			g_free (destfilename);
			g_free (newname);
			g_free (src);
			g_free (dest);
		}

		camel_operation_pop_message (cancellable);
		closedir (dir);
	}

	g_free (new);
	g_free (cur);

	camel_folder_summary_free_array (known_uids);
	g_mutex_unlock (&((CamelMaildirSummary *) cls)->priv->summary_lock);

	return 0;
}

/* sync the summary with the ondisk files. */
static gint
maildir_summary_sync (CamelLocalSummary *cls,
                      gboolean expunge,
                      CamelFolderChangeInfo *changes,
                      GCancellable *cancellable,
                      GError **error)
{
	CamelLocalSummaryClass *local_summary_class;
	gint i;
	CamelMessageInfo *info;
	CamelMaildirMessageInfo *mdi;
	GList *removed_uids = NULL;
	gchar *name;
	struct stat st;
	GPtrArray *known_uids;

	d (printf ("summary_sync(expunge=%s)\n", expunge?"true":"false"));

	/* Check consistency on save only if not exiting the application */
	if (!camel_application_is_exiting &&
	    camel_local_summary_check (cls, changes, cancellable, error) == -1)
		return -1;

	camel_operation_push_message (cancellable, _("Storing folder"));

	known_uids = camel_folder_summary_get_array ((CamelFolderSummary *) cls);
	for (i = (known_uids ? known_uids->len : 0) - 1; i >= 0; i--) {
		const gchar *uid = g_ptr_array_index (known_uids, i);
		guint32 flags = 0;

		camel_operation_progress (cancellable, (known_uids->len - i) * 100 / known_uids->len);

		/* Message infos with folder-flagged flags are not removed from memory */
		info = camel_folder_summary_peek_loaded ((CamelFolderSummary *) cls, uid);
		mdi = info ? CAMEL_MAILDIR_MESSAGE_INFO (info) : NULL;
		if (!mdi) {
			flags = camel_folder_summary_get_info_flags ((CamelFolderSummary *) cls, uid);
			if (flags == (~0))
				flags = 0;
		}

		if (expunge && (
		    (mdi && (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED) != 0) ||
		    (!mdi && (flags & CAMEL_MESSAGE_DELETED) != 0))) {
			const gchar *mdi_filename;
			gchar *tmp = NULL;

			if (mdi) {
				mdi_filename = camel_maildir_message_info_get_filename (mdi);
			} else {
				tmp = camel_maildir_summary_uid_and_flags_to_name (uid, flags);
				mdi_filename = tmp;
			}

			name = g_strdup_printf ("%s/cur/%s", cls->folder_path, mdi_filename);

			g_free (tmp);

			d (printf ("deleting %s\n", name));
			if (unlink (name) == 0 || errno == ENOENT) {

				/* FIXME: put this in folder_summary::remove()? */
				if (cls->index)
					camel_index_delete_name (cls->index, uid);

				camel_folder_change_info_remove_uid (changes, uid);
				removed_uids = g_list_prepend (removed_uids, (gpointer) camel_pstring_strdup (uid));
			}
			g_free (name);
		} else if (mdi && camel_message_info_get_folder_flagged (info)) {
			gchar *newname = camel_maildir_summary_info_to_name (info);
			gchar *dest;

			/* do we care about additional metainfo stored inside the message? */
			/* probably should all go in the filename? */

			/* have our flags/ i.e. name changed? */
			if (strcmp (newname, camel_maildir_message_info_get_filename (mdi))) {
				name = g_strdup_printf ("%s/cur/%s", cls->folder_path, camel_maildir_message_info_get_filename (mdi));
				dest = g_strdup_printf ("%s/cur/%s", cls->folder_path, newname);
				if (g_rename (name, dest) == -1) {
					g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, name, dest, g_strerror (errno));
				}
				if (g_stat (dest, &st) == -1) {
					/* we'll assume it didn't work, but dont change anything else */
				} else {
					/* TODO: If this is made mt-safe, then this code could be a problem, since
					 * the estrv is being modified.
					 * Sigh, this may mean the maildir name has to be cached another way */
					camel_maildir_message_info_set_filename (mdi, newname);
				}
				g_free (name);
				g_free (dest);
			}

			g_free (newname);

			/* strip FOLDER_MESSAGE_FLAGED, etc */
			camel_message_info_set_flags (info, 0xffff, camel_message_info_get_flags (info));
		}
		g_clear_object (&info);
	}

	if (removed_uids) {
		camel_folder_summary_remove_uids (CAMEL_FOLDER_SUMMARY (cls), removed_uids);
		g_list_free_full (removed_uids, (GDestroyNotify) camel_pstring_free);
	}

	camel_folder_summary_free_array (known_uids);
	camel_operation_pop_message (cancellable);

	/* Chain up to parent's sync() method. */
	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (camel_maildir_summary_parent_class);
	return local_summary_class->sync (cls, expunge, changes, cancellable, error);
}
