/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
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
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-local-summary.h"

#define w(x)
#define io(x)
#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#define CAMEL_LOCAL_SUMMARY_VERSION (1)

static CamelFIRecord *
		summary_header_save		(CamelFolderSummary *,
						 GError **error);
static gboolean	summary_header_load		(CamelFolderSummary *,
						 CamelFIRecord *);

static CamelMessageInfo *
		message_info_new_from_headers	(CamelFolderSummary *,
						 const CamelNameValueArray *);

static gint	local_summary_decode_x_evolution
						(CamelLocalSummary *cls,
						 const gchar *xev,
						 CamelMessageInfo *mi);
static gchar *	local_summary_encode_x_evolution
						(CamelLocalSummary *cls,
						 const CamelMessageInfo *mi);

static gint	local_summary_load		(CamelLocalSummary *cls,
						 gint forceindex,
						 GError **error);
static gint	local_summary_check		(CamelLocalSummary *cls,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static gint	local_summary_sync		(CamelLocalSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static CamelMessageInfo *
		local_summary_add		(CamelLocalSummary *cls,
						 CamelMimeMessage *msg,
						 const CamelMessageInfo *info,
						 CamelFolderChangeInfo *,
						 GError **error);
static gint	local_summary_need_index	(void);

G_DEFINE_TYPE (CamelLocalSummary, camel_local_summary, CAMEL_TYPE_FOLDER_SUMMARY)

static void
local_summary_dispose (GObject *object)
{
	CamelLocalSummary *local_summary;

	local_summary = CAMEL_LOCAL_SUMMARY (object);

	if (local_summary->index != NULL) {
		g_object_unref (local_summary->index);
		local_summary->index = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_local_summary_parent_class)->dispose (object);
}

static void
local_summary_finalize (GObject *object)
{
	CamelLocalSummary *local_summary;

	local_summary = CAMEL_LOCAL_SUMMARY (object);

	g_free (local_summary->folder_path);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_local_summary_parent_class)->finalize (object);
}

static void
camel_local_summary_class_init (CamelLocalSummaryClass *class)
{
	GObjectClass *object_class;
	CamelFolderSummaryClass *folder_summary_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = local_summary_dispose;
	object_class->finalize = local_summary_finalize;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->summary_header_load = summary_header_load;
	folder_summary_class->summary_header_save = summary_header_save;
	folder_summary_class->message_info_new_from_headers = message_info_new_from_headers;

	class->load = local_summary_load;
	class->check = local_summary_check;
	class->sync = local_summary_sync;
	class->add = local_summary_add;
	class->encode_x_evolution = local_summary_encode_x_evolution;
	class->decode_x_evolution = local_summary_decode_x_evolution;
	class->need_index = local_summary_need_index;
}

static void
camel_local_summary_init (CamelLocalSummary *local_summary)
{
	CamelFolderSummary *folder_summary;

	folder_summary = CAMEL_FOLDER_SUMMARY (local_summary);

	/* and a unique file version */
	camel_folder_summary_set_version (folder_summary, camel_folder_summary_get_version (folder_summary) + CAMEL_LOCAL_SUMMARY_VERSION);
}

void
camel_local_summary_construct (CamelLocalSummary *new,
                               const gchar *local_name,
                               CamelIndex *index)
{
	new->folder_path = g_strdup (local_name);
	new->index = index;
	if (index)
		g_object_ref (index);
}

static gboolean
local_summary_load (CamelLocalSummary *cls,
                    gint forceindex,
                    GError **error)
{
	d (g_print ("\nlocal_summary_load called \n"));
	return camel_folder_summary_load ((CamelFolderSummary *) cls, error);
}

/* load/check the summary */
gboolean
camel_local_summary_load (CamelLocalSummary *cls,
                          gint forceindex,
                          GError **error)
{
	CamelLocalSummaryClass *class;

	d (printf ("Loading summary ...\n"));

	class = CAMEL_LOCAL_SUMMARY_GET_CLASS (cls);

	if ((forceindex && class->need_index ())
	    || !class->load (cls, forceindex, error)) {
		w (g_warning ("Could not load summary: flags may be reset"));
		camel_folder_summary_clear ((CamelFolderSummary *) cls, NULL);
		return FALSE;
	}

	return TRUE;
}

void camel_local_summary_check_force (CamelLocalSummary *cls)
{
	cls->check_force = 1;
}

gchar *
camel_local_summary_encode_x_evolution (CamelLocalSummary *cls,
                                        const CamelMessageInfo *info)
{
	return CAMEL_LOCAL_SUMMARY_GET_CLASS (cls)->encode_x_evolution (cls, info);
}

gint
camel_local_summary_decode_x_evolution (CamelLocalSummary *cls,
                                        const gchar *xev,
                                        CamelMessageInfo *info)
{
	return CAMEL_LOCAL_SUMMARY_GET_CLASS (cls)->decode_x_evolution (cls, xev, info);
}

/*#define DOSTATS*/
#ifdef DOSTATS
struct _stat_info {
	gint mitotal;
	gint micount;
	gint citotal;
	gint cicount;
	gint msgid;
	gint msgcount;
};

static void
do_stat_ci (CamelLocalSummary *cls,
            struct _stat_info *info,
            CamelMessageContentInfo *ci)
{
	info->cicount++;
	info->citotal += ((CamelFolderSummary *) cls)->content_info_size /*+ 4 memchunks are 1/4 byte overhead per mi */;
	if (ci->id)
		info->citotal += strlen (ci->id) + 4;
	if (ci->description)
		info->citotal += strlen (ci->description) + 4;
	if (ci->encoding)
		info->citotal += strlen (ci->encoding) + 4;
	if (ci->type) {
		CamelContentType *ct = ci->type;
		struct _camel_header_param *param;

		info->citotal += sizeof (*ct) + 4;
		if (ct->type)
			info->citotal += strlen (ct->type) + 4;
		if (ct->subtype)
			info->citotal += strlen (ct->subtype) + 4;
		param = ct->params;
		while (param) {
			info->citotal += sizeof (*param) + 4;
			if (param->name)
				info->citotal += strlen (param->name) + 4;
			if (param->value)
				info->citotal += strlen (param->value) + 4;
			param = param->next;
		}
	}
	ci = ci->childs;
	while (ci) {
		do_stat_ci (cls, info, ci);
		ci = ci->next;
	}
}

static void
do_stat_mi (CamelLocalSummary *cls,
            struct _stat_info *info,
            CamelMessageInfo *mi)
{
	info->micount++;
	info->mitotal += ((CamelFolderSummary *) cls)->content_info_size /*+ 4 */;

	if (mi->subject)
		info->mitotal += strlen (mi->subject) + 4;
	if (mi->to)
		info->mitotal += strlen (mi->to) + 4;
	if (mi->from)
		info->mitotal += strlen (mi->from) + 4;
	if (mi->cc)
		info->mitotal += strlen (mi->cc) + 4;
	if (mi->uid)
		info->mitotal += strlen (mi->uid) + 4;

	if (mi->references) {
		info->mitotal += (mi->references->size - 1) * sizeof (CamelSummaryMessageID) + sizeof (CamelSummaryReferences) + 4;
		info->msgid += (mi->references->size) * sizeof (CamelSummaryMessageID);
		info->msgcount += mi->references->size;
	}

	/* dont have any user flags yet */

	if (mi->content) {
		do_stat_ci (cls, info, mi->content);
	}
}

#endif

gint
camel_local_summary_check (CamelLocalSummary *cls,
                           CamelFolderChangeInfo *changeinfo,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelLocalSummaryClass *local_summary_class;
	gint ret;

	local_summary_class = CAMEL_LOCAL_SUMMARY_GET_CLASS (cls);
	ret = local_summary_class->check (cls, changeinfo, cancellable, error);

#ifdef DOSTATS
	if (ret != -1) {
		gint i;
		CamelFolderSummary *s = (CamelFolderSummary *) cls;
		GPtrArray *known_uids;
		struct _stat_info stats = { 0 };

		known_uids = camel_folder_summary_get_array (s);
		for (i = 0; i < camel_folder_summary_count (s); i++) {
			CamelMessageInfo *info = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));
			do_stat_mi (cls, &stats, info);
			g_clear_object (&info);
		}
		camel_folder_summary_free_array (known_uids);

		printf ("\nMemory used by summary:\n\n");
		printf (
			"Total of %d messages\n",
			camel_folder_summary_count (s));
		printf (
			"Total: %d bytes (ave %f)\n",
			stats.citotal + stats.mitotal,
			(gdouble) (stats.citotal + stats.mitotal) /
			(gdouble) camel_folder_summary_count (s));
		printf (
			"Message Info: %d (ave %f)\n",
			stats.mitotal,
			(gdouble) stats.mitotal / (gdouble) stats.micount);
		printf (
			"Content Info; %d (ave %f) count %d\n",
			stats.citotal,
			(gdouble) stats.citotal / (gdouble) stats.cicount,
			stats.cicount);
		printf (
			"message id's: %d (ave %f) count %d\n",
			stats.msgid,
			(gdouble) stats.msgid / (gdouble) stats.msgcount,
			stats.msgcount);
	}
#endif
	return ret;
}

gint
camel_local_summary_sync (CamelLocalSummary *cls,
                          gboolean expunge,
                          CamelFolderChangeInfo *changeinfo,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelLocalSummaryClass *local_summary_class;

	local_summary_class = CAMEL_LOCAL_SUMMARY_GET_CLASS (cls);

	return local_summary_class->sync (cls, expunge, changeinfo, cancellable, error);
}

CamelMessageInfo *
camel_local_summary_add (CamelLocalSummary *cls,
                         CamelMimeMessage *msg,
                         const CamelMessageInfo *info,
                         CamelFolderChangeInfo *ci,
                         GError **error)
{
	CamelLocalSummaryClass *local_summary_class;

	local_summary_class = CAMEL_LOCAL_SUMMARY_GET_CLASS (cls);

	return local_summary_class->add (cls, msg, info, ci, error);
}

/**
 * camel_local_summary_write_headers:
 * @fd: a file descriptor to write to
 * @headers: a #CamelNameValueArray with headers to write
 * @xevline: (nullable): an optional value of X-Evolution header to add
 * @status: (nullable): an optional value of Status header to add
 * @xstatus: (nullable): an optional value of X-Status header to add
 *
 * Write a bunch of headers to the file @fd.  If xevline is non NULL, then
 * an X-Evolution header line is created at the end of all of the headers.
 * If @status is non NULL, then a Status header line is also written.
 * The headers written are termianted with a blank line.
 *
 * Returns: -1 on error, otherwise the number of bytes written.
 **/
gint
camel_local_summary_write_headers (gint fd,
                                   CamelNameValueArray *headers,
                                   const gchar *xevline,
                                   const gchar *status,
                                   const gchar *xstatus)
{
	gint outlen = 0, len;
	gint newfd;
	guint ii;
	const gchar *header_name = NULL, *header_value = NULL;
	FILE *out;

	/* dum de dum, maybe the whole sync function should just use stdio for output */
	newfd = dup (fd);
	if (newfd == -1)
		return -1;

	out = fdopen (newfd, "w");
	if (out == NULL) {
		close (newfd);
		errno = EINVAL;
		return -1;
	}

	for (ii = 0; camel_name_value_array_get (headers, ii, &header_name, &header_value); ii++) {
		if (strcmp (header_name, "X-Evolution") != 0
		    && (status == NULL || strcmp (header_name, "Status") != 0)
		    && (xstatus == NULL || strcmp (header_name, "X-Status") != 0)) {
			len = fprintf (out, "%s:%s\n", header_name, header_value);
			if (len == -1) {
				fclose (out);
				return -1;
			}
			outlen += len;
		}
	}

	if (status) {
		len = fprintf (out, "Status: %s\n", status);
		if (len == -1) {
			fclose (out);
			return -1;
		}
		outlen += len;
	}

	if (xstatus) {
		len = fprintf (out, "X-Status: %s\n", xstatus);
		if (len == -1) {
			fclose (out);
			return -1;
		}
		outlen += len;
	}

	if (xevline) {
		len = fprintf (out, "X-Evolution: %s\n", xevline);
		if (len == -1) {
			fclose (out);
			return -1;
		}
		outlen += len;
	}

	len = fprintf (out, "\n");
	if (len == -1) {
		fclose (out);
		return -1;
	}
	outlen += len;

	if (fclose (out) == -1)
		return -1;

	return outlen;
}

static gint
local_summary_check (CamelLocalSummary *cls,
                     CamelFolderChangeInfo *changeinfo,
                     GCancellable *cancellable,
                     GError **error)
{
	/* FIXME: sync index here ? */
	return 0;
}

static gint
local_summary_sync (CamelLocalSummary *cls,
                    gboolean expunge,
                    CamelFolderChangeInfo *changeinfo,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelFolderSummary *folder_summary;

	folder_summary = CAMEL_FOLDER_SUMMARY (cls);

	if (!camel_folder_summary_save (folder_summary, error)) {
		g_warning ("Could not save summary for local providers");
		return -1;
	}

	if (cls->index && camel_index_sync (cls->index) == -1) {
		g_warning ("Could not sync index for %s: %s", cls->folder_path, g_strerror (errno));
		return -1;
	}

	return 0;
}

static gint
local_summary_need_index (void)
{
	return 1;
}

static CamelMessageInfo *
local_summary_add (CamelLocalSummary *cls,
                   CamelMimeMessage *msg,
                   const CamelMessageInfo *info,
                   CamelFolderChangeInfo *ci,
                   GError **error)
{
	CamelFolderSummary *summary;
	CamelMessageInfo *mi;
	gchar *xev;

	d (printf ("Adding message to summary\n"));

	summary = CAMEL_FOLDER_SUMMARY (cls);

	mi = camel_folder_summary_info_new_from_message (summary, msg);
	camel_message_info_set_abort_notifications (mi, TRUE);

	if (info) {
		camel_message_info_take_user_flags (mi, camel_message_info_dup_user_flags (info));
		camel_message_info_take_user_tags (mi, camel_message_info_dup_user_tags (info));
		camel_message_info_set_flags (mi, ~0, camel_message_info_get_flags (info));
		camel_message_info_set_size (mi, camel_message_info_get_size (info));
	}

	/* we need to calculate the size ourselves */
	if (camel_message_info_get_size (mi) == 0) {
		camel_message_info_set_size (mi, camel_data_wrapper_calculate_size_sync (CAMEL_DATA_WRAPPER (msg), NULL, NULL));
	}

	camel_message_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_NOXEV, 0);
	xev = camel_local_summary_encode_x_evolution (cls, mi);
	camel_medium_set_header ((CamelMedium *) msg, "X-Evolution", xev);
	g_free (xev);

	camel_message_info_set_abort_notifications (mi, FALSE);
	camel_folder_summary_add (summary, mi, FALSE);
	camel_folder_change_info_add_uid (ci, camel_message_info_get_uid (mi));

	return mi;
}

static gchar *
local_summary_encode_x_evolution (CamelLocalSummary *cls,
                                  const CamelMessageInfo *mi)
{
	GString *out = g_string_new ("");
	struct _camel_header_param *params = NULL;
	guint32 flags;
	const CamelNamedFlags *user_flags;
	const CamelNameValueArray *user_tags;
	gchar *ret;
	const gchar *p, *uidstr;
	guint32 uid;

	camel_message_info_property_lock (mi);

	/* FIXME: work out what to do with uid's that aren't stored here? */
	/* FIXME: perhaps make that a mbox folder only issue?? */
	p = uidstr = camel_message_info_get_uid (mi);
	flags = camel_message_info_get_flags (mi);
	while (*p && isdigit (*p))
		p++;
	if (*p == 0 && sscanf (uidstr, "%u", &uid) == 1) {
		g_string_printf (out, "%08x-%04x", uid, flags & 0xffff);
	} else {
		g_string_printf (out, "%s-%04x", uidstr, flags & 0xffff);
	}

	user_flags = camel_message_info_get_user_flags (mi);
	user_tags = camel_message_info_get_user_tags (mi);

	if (user_flags || user_tags) {
		GString *val = g_string_new ("");
		const gchar *name, *value;
		guint ii, len;

		len = camel_named_flags_get_length (user_flags);
		if (len) {
			for (ii = 0; ii < len; ii++) {
				name = camel_named_flags_get (user_flags, ii);
				if (!name)
					continue;

				if (val->len)
					g_string_append_c (val, ',');
				g_string_append (val, name);
			}
			camel_header_set_param (&params, "flags", val->str);
			g_string_truncate (val, 0);
		}

		len = camel_name_value_array_get_length (user_tags);
		if (len) {
			for (ii = 0; ii < len; ii++) {
				if (!camel_name_value_array_get (user_tags, ii, &name, &value))
					continue;

				if (val->len)
					g_string_append_c (val, ',');

				g_string_append (val, name);
				g_string_append_c (val, '=');
				g_string_append (val, value);
			}
			camel_header_set_param (&params, "tags", val->str);
		}
		g_string_free (val, TRUE);

		camel_header_param_list_format_append (out, params);
		camel_header_param_list_free (params);
	}
	ret = out->str;
	g_string_free (out, FALSE);

	camel_message_info_property_unlock (mi);

	return ret;
}

static gint
local_summary_decode_x_evolution (CamelLocalSummary *cls,
                                  const gchar *xev,
                                  CamelMessageInfo *mi)
{
	struct _camel_header_param *params, *scan;
	guint32 uid, flags;
	gchar *header;
	gint i;
	gchar uidstr[20];

	uidstr[0] = 0;

	/* check for uid/flags */
	header = camel_header_token_decode (xev);
	if (header && strlen (header) == strlen ("00000000-0000")
	    && sscanf (header, "%08x-%04x", &uid, &flags) == 2) {
		if (mi)
			g_snprintf (uidstr, sizeof (uidstr), "%u", uid);
	} else {
		g_free (header);
		return -1;
	}
	g_free (header);

	if (mi == NULL)
		return 0;

	/* check for additional data */
	header = strchr (xev, ';');
	if (header) {
		params = camel_header_param_list_decode (header + 1);
		scan = params;
		while (scan) {
			if (!g_ascii_strcasecmp (scan->name, "flags")) {
				gchar **flagv = g_strsplit (scan->value, ",", 1000);

				for (i = 0; flagv[i]; i++)
					camel_message_info_set_user_flag (mi, flagv[i], TRUE);
				g_strfreev (flagv);
			} else if (!g_ascii_strcasecmp (scan->name, "tags")) {
				gchar **tagv = g_strsplit (scan->value, ",", 10000);
				gchar *val;

				for (i = 0; tagv[i]; i++) {
					val = strchr (tagv[i], '=');
					if (val) {
						*val++ = 0;
						camel_message_info_set_user_tag (mi, tagv[i], val);
						val[-1]='=';
					}
				}
				g_strfreev (tagv);
			}
			scan = scan->next;
		}
		camel_header_param_list_free (params);
	}

	camel_message_info_set_uid (mi, uidstr);
	camel_message_info_set_flags (mi, ~0, flags);

	return 0;
}

static gboolean
summary_header_load (CamelFolderSummary *s,
		     CamelFIRecord *fir)
{
	CamelLocalSummary *cls = (CamelLocalSummary *) s;
	gchar *part, *tmp;

	/* We dont actually add our own headers, but version that we don't anyway */

	if (!CAMEL_FOLDER_SUMMARY_CLASS (camel_local_summary_parent_class)->summary_header_load (s, fir))
		return FALSE;

	part = fir->bdata;
	if (part) {
		cls->version = camel_util_bdata_get_number (&part, 0);
	}

	/* keep only the rest of the bdata there (strip our version digit) */
	tmp = g_strdup (part);
	g_free (fir->bdata);
	fir->bdata = tmp;

	return TRUE;
}

static struct _CamelFIRecord *
summary_header_save (CamelFolderSummary *s,
		     GError **error)
{
	CamelFolderSummaryClass *folder_summary_class;
	struct _CamelFIRecord *fir;

	/* Chain up to parent's summary_header_save() method. */
	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (camel_local_summary_parent_class);
	fir = folder_summary_class->summary_header_save (s, NULL);
	if (fir)
		fir->bdata = g_strdup_printf ("%d", CAMEL_LOCAL_SUMMARY_VERSION);

	return fir;
}

static CamelMessageInfo *
message_info_new_from_headers (CamelFolderSummary *summary,
			       const CamelNameValueArray *headers)
{
	CamelMessageInfo *mi;
	CamelLocalSummary *cls = (CamelLocalSummary *) summary;

	mi = CAMEL_FOLDER_SUMMARY_CLASS (camel_local_summary_parent_class)->message_info_new_from_headers (summary, headers);
	if (mi) {
		const gchar *xev;
		gint doindex = FALSE;

		xev = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Evolution");
		if (xev == NULL || camel_local_summary_decode_x_evolution (cls, xev, mi) == -1) {
			gchar *uid;

			uid = camel_folder_summary_next_uid_string (summary);

			/* to indicate it has no xev header */
			camel_message_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_FLAGGED | CAMEL_MESSAGE_FOLDER_NOXEV, CAMEL_MESSAGE_FOLDER_FLAGGED | CAMEL_MESSAGE_FOLDER_NOXEV);
			camel_message_info_set_uid (mi, uid);

			g_free (uid);

			/* shortcut, no need to look it up in the index library */
			doindex = TRUE;
		}

		if (cls->index
		    && (doindex
			|| cls->index_force
			|| !camel_index_has_name (cls->index, camel_message_info_get_uid (mi)))) {
			d (printf ("Am indexing message %s\n", camel_message_info_get_uid (mi)));
			camel_folder_summary_set_index (summary, cls->index);
		} else {
			d (printf ("Not indexing message %s\n", camel_message_info_get_uid (mi)));
			camel_folder_summary_set_index (summary, NULL);
		}
	}

	return mi;
}
