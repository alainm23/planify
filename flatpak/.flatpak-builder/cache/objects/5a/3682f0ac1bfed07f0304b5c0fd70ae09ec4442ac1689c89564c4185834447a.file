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

#include <ctype.h>
#include <errno.h>
#include <string.h>

#include "camel-imapx-command.h"
#include "camel-imapx-folder.h"
#include "camel-imapx-message-info.h"
#include "camel-imapx-settings.h"
#include "camel-imapx-summary.h"
#include "camel-imapx-store.h"
#include "camel-imapx-store-summary.h"
#include "camel-imapx-utils.h"

/* high-level parser state */
#define p(...) camel_imapx_debug(parse, __VA_ARGS__)
/* debug */
#define d(...) camel_imapx_debug(debug, __VA_ARGS__)

gint camel_imapx_debug_flags;
extern gint camel_verbose_debug;

#define debug_set_flag(flag) do { \
	if ((CAMEL_IMAPX_DEBUG_ALL & CAMEL_IMAPX_DEBUG_ ## flag) && \
	    camel_debug ("imapx:" #flag)) \
		camel_imapx_debug_flags |= CAMEL_IMAPX_DEBUG_ ## flag; \
	} while (0)

static void camel_imapx_set_debug_flags (void)
{
	if (camel_verbose_debug || camel_debug ("imapx")) {
		camel_imapx_debug_flags = CAMEL_IMAPX_DEBUG_ALL;
		return;
	}

	debug_set_flag (command);
	debug_set_flag (debug);
	debug_set_flag (extra);
	debug_set_flag (io);
	debug_set_flag (token);
	debug_set_flag (parse);
	debug_set_flag (conman);
}

#include "camel-imapx-tokenise.h"
#define SUBFOLDER_DIR_NAME     "subfolders"

#ifdef __GNUC__
__inline
#endif
camel_imapx_id_t
imapx_tokenise (register const gchar *str,
                register guint len)
{
	struct _imapx_keyword *k = imapx_tokenise_struct (str, len);

	if (k)
		return k->id;
	return 0;
}

static const gchar * rename_label_flag (const gchar *flag, gint len, gboolean server_to_evo);

/* flag table */
static struct {
	const gchar *name;
	guint32 flag;
} flag_table[] = {
	{ "\\ANSWERED", CAMEL_MESSAGE_ANSWERED },
	{ "\\DELETED", CAMEL_MESSAGE_DELETED },
	{ "\\DRAFT", CAMEL_MESSAGE_DRAFT },
	{ "\\FLAGGED", CAMEL_MESSAGE_FLAGGED },
	{ "\\SEEN", CAMEL_MESSAGE_SEEN },
	{ "\\RECENT", CAMEL_IMAPX_MESSAGE_RECENT },
	{ "JUNK", CAMEL_MESSAGE_JUNK },
	{ "NOTJUNK", CAMEL_MESSAGE_NOTJUNK },
	{ "\\*", CAMEL_MESSAGE_USER }
};

/* utility functions
 * should this be part of imapx-driver? */
/* maybe this should be a stream op? */
gboolean
imapx_parse_flags (CamelIMAPXInputStream *stream,
                   guint32 *flagsp,
                   CamelNamedFlags *user_flags,
                   GCancellable *cancellable,
                   GError **error)
{
	camel_imapx_token_t tok;
	guint len;
	guchar *token;
	guint32 flags = 0;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), FALSE);

	*flagsp = flags;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return FALSE;

	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"expecting flag list");
		return FALSE;
	}

	do {
		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, error);

		if (tok == IMAPX_TOK_ERROR)
			return FALSE;

		if (tok == IMAPX_TOK_TOKEN || tok == IMAPX_TOK_INT) {
			gboolean match_found = FALSE;
			gchar *upper;
			gint ii;

			upper = g_ascii_strup ((gchar *) token, len);

			for (ii = 0; ii < G_N_ELEMENTS (flag_table); ii++) {
				if (!strcmp (upper, flag_table[ii].name)) {
					flags |= flag_table[ii].flag;
					match_found = TRUE;
					break;
				}
			}

			if (!match_found && user_flags) {
				const gchar *flag_name;
				gchar *utf8;

				flag_name = rename_label_flag (
					(gchar *) token,
					strlen ((gchar *) token), TRUE);

				utf8 = camel_utf7_utf8 (flag_name);
				if (utf8 && !g_utf8_validate (utf8, -1, NULL)) {
					g_free (utf8);
					utf8 = NULL;
				}

				camel_named_flags_insert (user_flags, utf8 ? utf8 : flag_name);

				g_free (utf8);
			}

			g_free (upper);

		} else if (tok != ')') {
			gboolean success;

			success = camel_imapx_input_stream_skip_until (
				stream, ")", cancellable, error);
			if (!success)
				return FALSE;
		}
	} while (tok != ')');

	*flagsp = flags;

	return TRUE;
}

/*
 * rename_flag
 * Converts label flag name on server to name used in Evolution or back.
 * if the flags does not match returns the original one as it is.
 * It will never return NULL, it will return empty string, instead.
 *
 * @flag: Flag to rename.
 * @len: Length of the flag name.
 * @server_to_evo: if TRUE, then converting server names to evo's names, if FALSE then opposite.
 */
static const gchar *
rename_label_flag (const gchar *flag,
                   gint len,
                   gboolean server_to_evo)
{
	gint i;
	const gchar *labels[] = {
		"$Label1", "$Labelimportant",
		"$Label2", "$Labelwork",
		"$Label3", "$Labelpersonal",
		"$Label4", "$Labeltodo",
		"$Label5", "$Labellater",
		NULL,      NULL };

	/* It really can pass zero-length flags inside, in that case it was able
	 * to always add first label, which is definitely wrong. */
	if (!len || !flag || !*flag)
		return "";

	for (i = 0 + (server_to_evo ? 0 : 1); labels[i]; i = i + 2) {
		if (!g_ascii_strncasecmp (flag, labels[i], len))
			return labels[i + (server_to_evo ? 1 : -1)];
	}

	return flag;
}

void
imapx_write_flags (GString *string,
                   guint32 flags,
                   const CamelNamedFlags *user_flags)
{
	guint ii;
	gboolean first = TRUE;

	g_string_append_c (string, '(');

	for (ii = 0; flags != 0 && ii < G_N_ELEMENTS (flag_table); ii++) {
		if (flag_table[ii].flag & flags) {
			if (flag_table[ii].flag & CAMEL_IMAPX_MESSAGE_RECENT)
				continue;
			if (!first)
				g_string_append_c (string, ' ');
			first = FALSE;
			g_string_append (string, flag_table[ii].name);

			flags &= ~flag_table[ii].flag;
		}
	}

	if (user_flags) {
		guint len = camel_named_flags_get_length (user_flags);

		for (ii = 0; ii < len; ii++) {
			const gchar *name = camel_named_flags_get (user_flags, ii);
			const gchar *flag_name;
			gchar *utf7;

			if (!name || !*name)
				continue;


			flag_name = rename_label_flag (name, strlen (name), FALSE);

			if (!first)
				g_string_append_c (string, ' ');
			first = FALSE;

			utf7 = camel_utf8_utf7 (flag_name);

			g_string_append (string, utf7 ? utf7 : flag_name);

			g_free (utf7);
		}
	}

	g_string_append_c (string, ')');
}

static gboolean
imapx_update_user_flags (CamelMessageInfo *info,
			 const CamelNamedFlags *server_user_flags)
{
	gboolean changed = FALSE;
	const CamelNamedFlags *mi_user_flags;
	gboolean set_cal = FALSE, set_note = FALSE;

	mi_user_flags = camel_message_info_get_user_flags (info);
	if (camel_named_flags_equal (mi_user_flags, server_user_flags)) {
		mi_user_flags = camel_imapx_message_info_get_server_user_flags (CAMEL_IMAPX_MESSAGE_INFO (info));

		if (!camel_named_flags_equal (mi_user_flags, server_user_flags)) {
			camel_imapx_message_info_take_server_user_flags (CAMEL_IMAPX_MESSAGE_INFO (info),
				camel_named_flags_copy (server_user_flags));
		}

		return FALSE;
	}

	if (mi_user_flags && camel_named_flags_contains (mi_user_flags, "$has_cal"))
		set_cal = TRUE;
	if (mi_user_flags && camel_named_flags_contains (mi_user_flags, "$has_note"))
		set_note = TRUE;

	changed = camel_message_info_take_user_flags (info, camel_named_flags_copy (server_user_flags));
	camel_imapx_message_info_take_server_user_flags (CAMEL_IMAPX_MESSAGE_INFO (info),
		camel_named_flags_copy (server_user_flags));

	/* reset the flags as they were set in messageinfo before */
	if (set_cal)
		camel_message_info_set_user_flag (info, "$has_cal", TRUE);
	if (set_note)
		camel_message_info_set_user_flag (info, "$has_note", TRUE);

	return changed;
}

gboolean
imapx_update_message_info_flags (CamelMessageInfo *info,
                                 guint32 server_flags,
                                 const CamelNamedFlags *server_user_flags,
                                 guint32 permanent_flags,
                                 CamelFolder *folder,
                                 gboolean unsolicited)
{
	gboolean changed = FALSE;
	CamelIMAPXMessageInfo *xinfo = CAMEL_IMAPX_MESSAGE_INFO (info);

	/* Locally made changes should not be overwritten, it'll be (re)saved later */
	if (camel_message_info_get_folder_flagged (info)) {
		d ('?', "Skipping update of locally changed uid:'%s'\n", camel_message_info_get_uid (info));
		return FALSE;
	}

	/* This makes sure that server flags has precedence from locally stored flags,
	 * thus a user actually sees what is stored on the server */
	if ((camel_message_info_get_flags (info) & CAMEL_IMAPX_SERVER_FLAGS) != (server_flags & CAMEL_IMAPX_SERVER_FLAGS)) {
		guint32 old_server_flags;

		old_server_flags = camel_imapx_message_info_get_server_flags (xinfo);

		camel_imapx_message_info_set_server_flags (xinfo,
			(old_server_flags & ~CAMEL_IMAPX_SERVER_FLAGS) |
			(camel_message_info_get_flags (info) & CAMEL_IMAPX_SERVER_FLAGS));
	}

	if (server_flags != camel_imapx_message_info_get_server_flags (xinfo)) {
		guint32 server_set, server_cleared, old_server_flags;

		old_server_flags = camel_imapx_message_info_get_server_flags (xinfo);
		server_set = server_flags & ~old_server_flags;
		server_cleared = old_server_flags & ~server_flags;

		/* Don't clear non-permanent server-side flags.
		 * This avoids overwriting local flags that we
		 * do store permanently, such as junk flags. */
		if (permanent_flags > 0)
			server_cleared &= permanent_flags;

		changed = camel_message_info_set_flags (info,
			server_set | server_cleared,
			(camel_message_info_get_flags (info) | server_set) & ~server_cleared);

		camel_imapx_message_info_set_server_flags (xinfo, server_flags);
	}

	if ((permanent_flags & CAMEL_MESSAGE_USER) != 0 && imapx_update_user_flags (info, server_user_flags))
		changed = TRUE;

	return changed;
}

void
imapx_set_message_info_flags_for_new_message (CamelMessageInfo *info,
                                              guint32 server_flags,
                                              const CamelNamedFlags *server_user_flags,
					      gboolean force_user_flags,
					      const CamelNameValueArray *user_tags,
					      guint32 permanent_flags)
{
	CamelIMAPXMessageInfo *xinfo = CAMEL_IMAPX_MESSAGE_INFO (info);

	camel_message_info_set_flags (info, server_flags, camel_message_info_get_flags (info) | server_flags);
	camel_imapx_message_info_set_server_flags (xinfo, server_flags);

	if (force_user_flags || (permanent_flags & CAMEL_MESSAGE_USER) != 0)
		imapx_update_user_flags (info, server_user_flags);

	camel_message_info_take_user_tags (info, camel_name_value_array_copy (user_tags));

	camel_message_info_set_folder_flagged (info, FALSE);
}

void
imapx_update_store_summary (CamelFolder *folder)
{
	CamelStoreInfo *si;
	CamelStore *parent_store;
	CamelIMAPXStore *imapx_store;
	const gchar *full_name;
	guint32 total;
	guint32 unread;

	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));

	full_name = camel_folder_get_full_name (folder);
	parent_store = camel_folder_get_parent_store (folder);

	if (!parent_store)
		return;

	imapx_store = CAMEL_IMAPX_STORE (parent_store);

	si = camel_store_summary_path (imapx_store->summary, full_name);
	if (si == NULL)
		return;

	total = camel_folder_summary_count (camel_folder_get_folder_summary (folder));
	unread = camel_folder_summary_get_unread_count (camel_folder_get_folder_summary (folder));

	if (si->unread != unread || si->total != total) {
		si->unread = unread;
		si->total = total;

		camel_store_summary_touch (imapx_store->summary);
		camel_store_summary_save (imapx_store->summary);
	}
}

gchar *
camel_imapx_dup_uid_from_summary_index (CamelFolder *folder,
                                        guint summary_index)
{
	CamelFolderSummary *summary;
	GPtrArray *array;
	gchar *uid = NULL;

	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), NULL);

	summary = camel_folder_get_folder_summary (folder);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

	array = camel_folder_summary_get_array (summary);
	g_return_val_if_fail (array != NULL, NULL);

	if (summary_index < array->len) {
		folder = camel_folder_summary_get_folder (summary);
		camel_folder_sort_uids (folder, array);
		uid = g_strdup (g_ptr_array_index (array, summary_index));
	}

	camel_folder_summary_free_array (array);

	return uid;
}

/*
 * capability_data ::= "CAPABILITY" SPACE [1#capability SPACE] "IMAP4rev1"
 *                     [SPACE 1#capability]
 *                 ;; IMAP4rev1 servers which offer RFC 1730
 *                 ;; compatibility MUST list "IMAP4" as the first
 *                 ;; capability.
 */

struct {
	const gchar *name;
	guint32 flag;
} capa_table[] = { /* used to create capa_htable only */
	{ "IMAP4", IMAPX_CAPABILITY_IMAP4 },
	{ "IMAP4REV1", IMAPX_CAPABILITY_IMAP4REV1 },
	{ "STATUS",  IMAPX_CAPABILITY_STATUS } ,
	{ "NAMESPACE", IMAPX_CAPABILITY_NAMESPACE },
	{ "UIDPLUS",  IMAPX_CAPABILITY_UIDPLUS },
	{ "LITERAL+", IMAPX_CAPABILITY_LITERALPLUS },
	{ "STARTTLS", IMAPX_CAPABILITY_STARTTLS },
	{ "IDLE", IMAPX_CAPABILITY_IDLE },
	{ "CONDSTORE", IMAPX_CAPABILITY_CONDSTORE },
	{ "QRESYNC", IMAPX_CAPABILITY_QRESYNC },
	{ "LIST-EXTENDED", IMAPX_CAPABILITY_LIST_EXTENDED },
	{ "LIST-STATUS", IMAPX_CAPABILITY_LIST_STATUS },
	{ "QUOTA", IMAPX_CAPABILITY_QUOTA },
	{ "MOVE", IMAPX_CAPABILITY_MOVE },
	{ "NOTIFY", IMAPX_CAPABILITY_NOTIFY },
	{ "SPECIAL-USE", IMAPX_CAPABILITY_SPECIAL_USE },
	{ "X-GM-EXT-1", IMAPX_CAPABILITY_X_GM_EXT_1 },
	{ "UTF8=ACCEPT", IMAPX_CAPABILITY_UTF8_ACCEPT },
	{ "UTF8=ONLY", IMAPX_CAPABILITY_UTF8_ONLY }
};

static GMutex capa_htable_lock;         /* capabilities lookup table lock */
static GHashTable *capa_htable = NULL;  /* capabilities lookup table (extensible) */

static void
create_initial_capabilities_table (void)
{
	gint i = 0;

	/* call within g_init_once() only,
	 * or require table lock
	 */

	/* TODO add imapx_utils_uninit()
	 *      to free hash table
	 */
	capa_htable = g_hash_table_new_full (
		camel_strcase_hash,
		camel_strcase_equal,
		g_free,
		NULL);

	for (i = 0; i < G_N_ELEMENTS (capa_table); i++) {
		g_hash_table_insert (
			capa_htable,
			g_strdup (capa_table[i].name),
			GUINT_TO_POINTER (capa_table[i].flag));
	}
}

struct _capability_info *
imapx_parse_capability (CamelIMAPXInputStream *stream,
                        GCancellable *cancellable,
                        GError **error)
{
	gint tok;
	guint len;
	guchar *token, *p, c;
	gboolean free_token = FALSE;
	struct _capability_info * cinfo;
	GError *local_error = NULL;

	cinfo = g_malloc0 (sizeof (*cinfo));

	cinfo->auth_types = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, NULL);

	/* FIXME: handle auth types */
	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);

	while (tok != '\n' && local_error == NULL) {
		switch (tok) {
			case ']':
				/* Put it back so that imapx_untagged() isn't unhappy */
				camel_imapx_input_stream_ungettoken (
					stream, tok, token, len);
				break;
			case 43:
				/* the CAPABILITY shouldn't start with a '+', ignore it then */
				if (!token)
					break;
				token = (guchar *) g_strconcat ((gchar *) token, "+", NULL);
				free_token = TRUE;
				/* coverity[fallthrough] */
				/* falls through */
			case IMAPX_TOK_TOKEN:
			case IMAPX_TOK_STRING:
				p = token;
				while ((c = *p))
					*p++ = toupper(c);
				if (!strncmp ((gchar *) token, "AUTH=", 5)) {
					g_hash_table_insert (
						cinfo->auth_types,
						g_strdup ((gchar *) token + 5),
						GINT_TO_POINTER (1));
					break;
				}
				/* falls through */
			case IMAPX_TOK_INT:
				cinfo->capa |= imapx_lookup_capability ((gchar *) token);
				if (free_token) {
					g_free (token);
					token = NULL;
				}
				free_token = FALSE;
				break;
			default:
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"capability: expecting name");
				break;
		}

		if (tok == ']')
			break;

		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, &local_error);
	}

	/* Some capabilities are extensions of other capabilities.
	 * Make sure all prerequisite capability flags are present. */

	/* LIST-STATUS is an extension of LIST-EXTENDED. */
	if (CAMEL_IMAPX_HAVE_CAPABILITY (cinfo, LIST_STATUS))
		cinfo->capa |= imapx_lookup_capability ("LIST-EXTENDED");

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		imapx_free_capability (cinfo);
		cinfo = NULL;
	}

	return cinfo;
}

void imapx_free_capability (struct _capability_info *cinfo)
{
	g_hash_table_destroy (cinfo->auth_types);
	g_free (cinfo);
}

guint32
imapx_register_capability (const gchar *capability)
{
	guint32 capa_id = 0;
	guint64 check_id = 0;
	GList *vals = NULL;
	GList *tmp_vals = NULL;

	g_return_val_if_fail (capability != NULL, 0);

	g_mutex_lock (&capa_htable_lock);

	/* we rely on IMAP being the first flag, non-zero value
	 * (1 << 0), so we can use GPOINTER_TO_UINT (NULL) as
	 * invalid value
	 */
	capa_id = GPOINTER_TO_UINT (
		g_hash_table_lookup (capa_htable, capability));
	if (capa_id > 0)
		goto exit;

	/* not yet there, find biggest flag so far */
	vals = g_hash_table_get_values (capa_htable);
	tmp_vals = vals;
	while (tmp_vals != NULL) {
		guint32 tmp_id = GPOINTER_TO_UINT (tmp_vals->data);
		if (capa_id < tmp_id)
			capa_id = tmp_id;
		tmp_vals = g_list_next (tmp_vals);
	}
	g_list_free (vals);

	/* shift-left biggest-so-far, sanity-check */
	check_id = (capa_id << 1);
	g_return_val_if_fail (check_id <= (guint64) G_MAXUINT32, 0);
	capa_id = (guint32) check_id;

	/* insert */
	g_hash_table_insert (
		capa_htable,
		g_strdup (capability),
		GUINT_TO_POINTER (capa_id));

 exit:
	g_mutex_unlock (&capa_htable_lock);

	return capa_id;
}

guint32
imapx_lookup_capability (const gchar *capability)
{
	gpointer data;

	g_return_val_if_fail (capability != NULL, 0);

	g_mutex_lock (&capa_htable_lock);

	data = g_hash_table_lookup (capa_htable, capability);

	g_mutex_unlock (&capa_htable_lock);

	return GPOINTER_TO_UINT (data);
}

/*
 * body            ::= "(" body_type_1part / body_type_mpart ")"
 *
 * body_extension  ::= nstring / number / "(" 1#body_extension ")"
 *                     ;; Future expansion.  Client implementations
 *                     ;; MUST accept body_extension fields.  Server
 *                     ;; implementations MUST NOT generate
 *                     ;; body_extension fields except as defined by
 *                     ;; future standard or standards-track
 *                     ;; revisions of this specification.
 *
 * body_ext_1part  ::= body_fld_md5[SPACE body_fld_dsp
 *                 [SPACE body_fld_lang
 *                 [SPACE 1#body_extension]]]
 *                     ;; MUST NOT be returned on non-extensible
 *                     ;; "BODY" fetch
 *
 * body_ext_mpart  ::= body_fld_param
 *                 [SPACE body_fld_dsp SPACE body_fld_lang
 *                 [SPACE 1#body_extension]]
 *                     ;; MUST NOT be returned on non-extensible
 *                     ;; "BODY" fetch
 *
 * body_fields     ::= body_fld_param SPACE body_fld_id SPACE
 *                     body_fld_desc SPACE body_fld_enc SPACE
 *                     body_fld_octets
 *
 * body_fld_desc   ::= nstring
 *
 * body_fld_dsp    ::= "(" string SPACE body_fld_param ")" / nil
 *
 * body_fld_enc    ::= (<"> ("7BIT" / "8BIT" / "BINARY" / "BASE64"/
 *                     "QUOTED-PRINTABLE") <">) / string
 *
 * body_fld_id     ::= nstring
 *
 * body_fld_lang   ::= nstring / "(" 1#string ")"
 *
 * body_fld_lines  ::= number
 *
 * body_fld_md5    ::= nstring
 *
 * body_fld_octets ::= number
 *
 * body_fld_param  ::= "(" 1#(string SPACE string) ")" / nil
 *
 * body_type_1part ::= (body_type_basic / body_type_msg / body_type_text)
 *                 [SPACE body_ext_1part]
 *
 * body_type_basic ::= media_basic SPACE body_fields
 *                     ;; MESSAGE subtype MUST NOT be "RFC822"
 *
 * body_type_mpart ::= 1*body SPACE media_subtype
 *                 [SPACE body_ext_mpart]
 *
 * body_type_msg   ::= media_message SPACE body_fields SPACE envelope
 *                     SPACE body SPACE body_fld_lines
 *
 * body_type_text  ::= media_text SPACE body_fields SPACE body_fld_lines
 *
 * envelope        ::= "(" env_date SPACE env_subject SPACE env_from
 *                     SPACE env_sender SPACE env_reply_to SPACE env_to
 *                     SPACE env_cc SPACE env_bcc SPACE env_in_reply_to
 *                     SPACE env_message_id ")"
 *
 * env_bcc         ::= "(" 1*address ")" / nil
 *
 * env_cc          ::= "(" 1*address ")" / nil
 *
 * env_date        ::= nstring
 *
 * env_from        ::= "(" 1*address ")" / nil
 *
 * env_in_reply_to ::= nstring
 *
 * env_message_id  ::= nstring
 *
 * env_reply_to    ::= "(" 1*address ")" / nil
 *
 * env_sender      ::= "(" 1*address ")" / nil
 *
 * env_subject     ::= nstring
 *
 * env_to          ::= "(" 1*address ")" / nil
 *
 * media_basic     ::= (<"> ("APPLICATION" / "AUDIO" / "IMAGE" /
 *                     "MESSAGE" / "VIDEO") <">) / string)
 *                     SPACE media_subtype
 *                     ;; Defined in[MIME-IMT]
 *
 * media_message   ::= <"> "MESSAGE" <"> SPACE <"> "RFC822" <">
 *                     ;; Defined in[MIME-IMT]
 *
 * media_subtype   ::= string
 *                     ;; Defined in[MIME-IMT]
 *
 * media_text      ::= <"> "TEXT" <"> SPACE media_subtype
 *                     ;; Defined in[MIME-IMT]
 *
 *  ( "type" "subtype"  body_fields [envelope body body_fld_lines]
 *                              [body_fld_lines]
 *
 *  (("TEXT" "PLAIN" ("CHARSET"
 *                      "US-ASCII") NIL NIL "7BIT" 1152 23)("TEXT" "PLAIN"
 *                      ("CHARSET" "US-ASCII" "NAME" "cc.diff")
 *                      "<960723163407.20117h@cac.washington.edu>"
 *                      "Compiler diff" "BASE64" 4554 73) "MIXED"))
 *
 */

/*
struct _body_fields {
	CamelContentType *ct;
	gchar *msgid, *desc;
	CamelTransferEncoding encoding;
	guint32 size;
	};*/

gboolean
imapx_parse_param_list (CamelIMAPXInputStream *stream,
                        struct _camel_header_param **plist,
                        GCancellable *cancellable,
                        GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	gchar *param;
	gsize param_len;

	/* body_fld_param  ::= "(" 1#(string SPACE string) ")" / nil */
	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, NULL);
	if (tok == '(') {
		while (1) {
			tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, error);

			if (tok == ')' || tok == IMAPX_TOK_ERROR)
				break;

			camel_imapx_input_stream_ungettoken (
				stream, tok, token, len);

			if (!camel_imapx_input_stream_astring (stream, &token, cancellable, error))
				break;

			param_len = strlen ((gchar *) token) + 1;
			param = alloca (param_len);
			g_strlcpy (param, (gchar *) token, param_len);

			if (!camel_imapx_input_stream_astring (stream, &token, cancellable, error))
				break;

			camel_header_set_param (plist, param, (gchar *) token);
		}
	} /* else check nil?  no need */

	return TRUE;
}

struct _CamelContentDisposition *
imapx_parse_ext_optional (CamelIMAPXInputStream *stream,
                          GCancellable *cancellable,
                          GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	struct _CamelContentDisposition *dinfo = NULL;
	GError *local_error = NULL;

	/* this parses both extension types, from the body_fld_dsp onwards */
	/* although the grammars are different, they can be parsed the same way */

	/* body_ext_1part  ::= body_fld_md5 [SPACE body_fld_dsp
	 * [SPACE body_fld_lang
	 * [SPACE 1#body_extension]]]
	 *    ;; MUST NOT be returned on non-extensible
	 *    ;; "BODY" fetch */

	/* body_ext_mpart  ::= body_fld_param
	 * [SPACE body_fld_dsp SPACE body_fld_lang
	 * [SPACE 1#body_extension]]
	 *    ;; MUST NOT be returned on non-extensible
	 *    ;; "BODY" fetch */

	/* body_fld_dsp    ::= "(" string SPACE body_fld_param ")" / nil */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, NULL);
	switch (tok) {
		case '(':
			dinfo = camel_content_disposition_new ();

			/* should be string */
			if (!camel_imapx_input_stream_astring (stream, &token, cancellable, &local_error)) {
				if (!local_error)
					g_set_error (
						&local_error,
						CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
						"expecting string");
				goto done;
			}

			dinfo->disposition = g_strdup ((gchar *) token);
			imapx_parse_param_list (
				stream, &dinfo->params, cancellable,
				&local_error);

			if (local_error != NULL)
				goto done;

			break;
		case IMAPX_TOK_TOKEN:
			break;
		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"body_fld_disp: expecting nil or list");
			return NULL;
	}

	/* body_fld_lang   ::= nstring / "(" 1#string ")" */

	/* we just drop the lang string/list, save it somewhere? */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);

	switch (tok) {
		case '(':
			while (1) {
				tok = camel_imapx_input_stream_token (
					stream, &token, &len,
					cancellable, &local_error);

				if (tok == ')') {
					break;
				} else if (tok != IMAPX_TOK_STRING) {
					g_clear_error (&local_error);
					g_set_error (
						&local_error,
						CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
						"expecting string");
					break;
				}
			}
			break;
		case IMAPX_TOK_TOKEN:
			/* treat as 'nil' */
			break;
		case IMAPX_TOK_STRING:
			/* we have a string */
			break;
		case IMAPX_TOK_LITERAL:
			/* we have a literal string */
			camel_imapx_input_stream_set_literal (stream, len);
			while (camel_imapx_input_stream_getl (stream, &token, &len, cancellable, NULL) > 0) {
				/* Skip over it. */
			}
			break;

	}

 done:
	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		if (dinfo)
			camel_content_disposition_unref (dinfo);
		dinfo = NULL;
	}

	return dinfo;
}

static gboolean
imapx_is_budystructure_response_end (CamelIMAPXInputStream *stream,
				     gboolean *out_is_response_end,
				     GCancellable *cancellable,
				     GError **error)
{
	gint tok;
	guint len;
	guchar *token;

	g_return_val_if_fail (out_is_response_end != NULL, FALSE);

	tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return FALSE;

	camel_imapx_input_stream_ungettoken (stream, tok, token, len);

	*out_is_response_end = tok == ')';

	return TRUE;
}

struct _CamelMessageContentInfo *
imapx_parse_body_fields (CamelIMAPXInputStream *stream,
                         GCancellable *cancellable,
                         GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	gchar  *type;
	gsize type_len;
	guint64 number;
	struct _CamelMessageContentInfo *cinfo;
	gboolean success, is_broken_response = FALSE, is_end = FALSE;

	/* body_fields     ::= body_fld_param SPACE body_fld_id SPACE
	 * body_fld_desc SPACE body_fld_enc SPACE
	 * body_fld_octets */

	cinfo = camel_message_content_info_new ();

	/* this should be string not astring */
	success = camel_imapx_input_stream_astring (
		stream, &token, cancellable, error);

	if (!success)
		goto error;

	type_len = strlen ((gchar *) token) + 1;
	type = alloca (type_len);
	g_strlcpy (type, (gchar *) token, type_len);

	/* Peek what follows, as Gmail can return invalid multipart/mixed response
	   when it contains another multipart/mixed with the same boundary. */
	tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		goto error;

	camel_imapx_input_stream_ungettoken (stream, tok, token, len);

	if (tok == '(') {
		/* Broken response, has missing 'type', contains only 'subtype' */
		is_broken_response = TRUE;
		token = (guchar *) type;
		type = (gchar *) "multipart";
	} else {
		success = camel_imapx_input_stream_astring (stream, &token, cancellable, error);

		if (!success)
			goto error;
	}

	cinfo->type = camel_content_type_new (type, (gchar *) token);

	success = imapx_parse_param_list (
		stream, &cinfo->type->params, cancellable, error);

	if (!success)
		goto error;

	if (is_broken_response) {
		gint nested_level = 0;

		/* Ignore everything until the last ')' */
		do {
			tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, error);

			if (tok == IMAPX_TOK_ERROR)
				goto error;

			if (tok == '(') {
				nested_level++;
			} else if (tok == ')' && nested_level > 0) {
				tok = 0; /* To not be used as the stop condition */
				nested_level--;
			} else if (tok == IMAPX_TOK_LITERAL) {
				camel_imapx_input_stream_set_literal (stream, len);

				do {
					tok = camel_imapx_input_stream_getl (stream, &token, &len, cancellable, error);
				} while (tok > 0);
			}
		} while ((nested_level > 0 || tok != ')') && tok != IMAPX_TOK_ERROR);

		if (tok == ')')
			camel_imapx_input_stream_ungettoken (stream, tok, token, len);

		return cinfo;
	}

	success = imapx_is_budystructure_response_end (stream, &is_end, cancellable, error);

	if (!success)
		goto error;

	if (!is_end) {
		/* body_fld_id     ::= nstring */
		success = camel_imapx_input_stream_nstring (stream, &token, cancellable, error);
		if (!success)
			goto error;

		cinfo->id = g_strdup ((gchar *) token);

		success = imapx_is_budystructure_response_end (stream, &is_end, cancellable, error);
		if (!success)
			goto error;
	}

	if (!is_end) {
		/* body_fld_desc   ::= nstring */
		success = camel_imapx_input_stream_nstring (stream, &token, cancellable, error);
		if (!success)
			goto error;

		cinfo->description = g_strdup ((gchar *) token);

		success = imapx_is_budystructure_response_end (stream, &is_end, cancellable, error);
		if (!success)
			goto error;
	}

	if (!is_end) {
		/* body_fld_enc    ::= (<"> ("7BIT" / "8BIT" / "BINARY" / "BASE64"/
		 * "QUOTED-PRINTABLE") <">) / string */
		success = camel_imapx_input_stream_astring (stream, &token, cancellable, error);
		if (!success)
			goto error;

		cinfo->encoding = g_strdup ((gchar *) token);

		success = imapx_is_budystructure_response_end (stream, &is_end, cancellable, error);
		if (!success)
			goto error;
	}

	if (!is_end) {
		/* body_fld_octets ::= number */
		success = camel_imapx_input_stream_number (
			stream, &number, cancellable, error);

		if (!success)
			goto error;

		cinfo->size = number;
	}

	return cinfo;

error:
	camel_message_content_info_free (cinfo);

	return NULL;
}

CamelHeaderAddress *
imapx_parse_address_list (CamelIMAPXInputStream *stream,
                          GCancellable *cancellable,
                          GError **error)
{
	gint tok;
	guint len;
	guchar *token, *host;
	gchar *mbox;
	CamelHeaderAddress *list = NULL;
	GError *local_error = NULL;

	/* "(" 1*address ")" / nil */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);
	if (local_error) {
		g_propagate_error (error, local_error);
		return NULL;
	}

	if (tok == '(') {
		CamelHeaderAddress *addr, *group = NULL;
		while (1) {
			/* address         ::= "(" addr_name SPACE addr_adl SPACE addr_mailbox
			 * SPACE addr_host ")" */
			tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, &local_error);

			if (tok == ')')
				break;
			if (tok != '(') {
				g_clear_error (&local_error);
				camel_header_address_list_clear (&list);
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"missing '(' for address");
				return NULL;
			}

			addr = camel_header_address_new ();
			addr->type = CAMEL_HEADER_ADDRESS_NAME;
			camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
			if (local_error) {
				camel_header_address_unref (addr);
				goto error;
			}

			addr->name = g_strdup ((gchar *) token);
			/* we ignore the route, nobody uses it in the real world */
			camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
			if (local_error) {
				camel_header_address_unref (addr);
				goto error;
			}

			mbox = NULL;

			/* [RFC-822] group syntax is indicated by a special
			 * form of address structure in which the host name
			 * field is NIL.  If the mailbox name field is also
			 * NIL, this is an end of group marker (semi-colon in
			 * RFC 822 syntax).  If the mailbox name field is
			 * non-NIL, this is a start of group marker, and the
			 * mailbox name field holds the group name phrase. */

			camel_imapx_input_stream_nstring (stream, (guchar **) &mbox, cancellable, &local_error);
			if (local_error) {
				camel_header_address_unref (addr);
				goto error;
			}

			mbox = g_strdup (mbox);

			camel_imapx_input_stream_nstring (stream, &host, cancellable, &local_error);
			if (local_error) {
				camel_header_address_unref (addr);
				goto error;
			}

			if (host == NULL) {
				if (mbox == NULL) {
					group = NULL;
					camel_header_address_unref (addr);
				} else {
					g_free (addr->name);
					addr->name = mbox;
					addr->type = CAMEL_HEADER_ADDRESS_GROUP;
					camel_header_address_list_append (&list, addr);
					group = addr;
				}
			} else {
				addr->v.addr = g_strdup_printf (
					"%s@%s", mbox ? mbox : "",
					(const gchar *) host);
				g_free (mbox);
				if (group != NULL)
					camel_header_address_add_member (group, addr);
				else
					camel_header_address_list_append (&list, addr);
			}
			do {
				tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, &local_error);
				if (local_error)
					goto error;
			} while (tok != ')' && tok != IMAPX_TOK_ERROR);
		}
	}

 error:
	/* CHEN TODO handle exception at required places */
	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		if (list)
			camel_header_address_list_clear (&list);
		return NULL;
	}

	return list;
}

CamelMessageInfo *
imapx_parse_envelope (CamelIMAPXInputStream *stream,
                      GCancellable *cancellable,
                      GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	CamelHeaderAddress *addr, *addr_from;
	gchar *addrstr;
	CamelMessageInfo *info;
	GError *local_error = NULL;

	/* envelope        ::= "(" env_date SPACE env_subject SPACE env_from
	 * SPACE env_sender SPACE env_reply_to SPACE env_to
	 * SPACE env_cc SPACE env_bcc SPACE env_in_reply_to
	 * SPACE env_message_id ")" */

	info = camel_message_info_new (NULL);

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);

	if (local_error)
		goto error;

	if (tok != '(') {
		g_clear_error (&local_error);
		g_clear_object (&info);
		g_set_error (error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED, "envelope: expecting '('");
		return NULL;
	}

	/* env_date        ::= nstring */
	camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
	if (local_error)
		goto error;

	camel_message_info_set_date_sent (info, camel_header_decode_date ((gchar *) token, NULL));

	/* env_subject     ::= nstring */
	camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
	if (local_error)
		goto error;

	camel_message_info_set_subject (info, (const gchar *) token);

	/* we merge from/sender into from, append should probably merge more smartly? */

	/* env_from        ::= "(" 1*address ")" / nil */
	addr_from = imapx_parse_address_list (stream, cancellable, &local_error);
	if (local_error)
		goto error;

	/* env_sender      ::= "(" 1*address ")" / nil */
	addr = imapx_parse_address_list (stream, cancellable, &local_error);
	if (local_error)
		goto error;

	if (addr_from) {
		camel_header_address_list_clear (&addr);
	} else {
		if (addr)
			addr_from = addr;
	}

	if (addr_from) {
		addrstr = camel_header_address_list_format (addr_from);
		camel_message_info_set_from (info, addrstr);
		g_free (addrstr);
		camel_header_address_list_clear (&addr_from);
	}

	/* we dont keep reply_to */

	/* env_reply_to    ::= "(" 1*address ")" / nil */
	addr = imapx_parse_address_list (stream, cancellable, &local_error);
	camel_header_address_list_clear (&addr);

	if (local_error)
		goto error;

	/* env_to          ::= "(" 1*address ")" / nil */
	addr = imapx_parse_address_list (stream, cancellable, &local_error);
	if (addr) {
		addrstr = camel_header_address_list_format (addr);
		camel_message_info_set_to (info, addrstr);
		g_free (addrstr);
		camel_header_address_list_clear (&addr);
	}

	if (local_error)
		goto error;

	/* env_cc          ::= "(" 1*address ")" / nil */
	addr = imapx_parse_address_list (stream, cancellable, &local_error);
	if (addr) {
		addrstr = camel_header_address_list_format (addr);
		camel_message_info_set_cc (info, addrstr);
		g_free (addrstr);
		camel_header_address_list_clear (&addr);
	}

	if (local_error)
		goto error;

	/* we dont keep bcc either */

	/* env_bcc         ::= "(" 1*address ")" / nil */
	addr = imapx_parse_address_list (stream, cancellable, &local_error);
	camel_header_address_list_clear (&addr);

	if (local_error)
		goto error;

	/* FIXME: need to put in-reply-to into references hash list */

	/* env_in_reply_to ::= nstring */
	camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
	if (local_error)
		goto error;

	/* FIXME: need to put message-id into message-id hash */

	/* env_message_id  ::= nstring */
	camel_imapx_input_stream_nstring (stream, &token, cancellable, &local_error);
	if (local_error)
		goto error;

	tok = camel_imapx_input_stream_token (stream, &token, &len, cancellable, &local_error);
	if (local_error)
		goto error;

	if (tok != ')') {
		g_clear_error (&local_error);
		g_clear_object (&info);
		g_set_error (error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED, "expecting ')'");
		return NULL;
	}

 error:
	/* CHEN TODO handle exceptions better */
	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		g_clear_object (&info);
		return NULL;
	}

	return info;
}

CamelMessageContentInfo *
imapx_parse_body (CamelIMAPXInputStream *stream,
                  GCancellable *cancellable,
                  GError **error)
{
	gint tok, nested_extension = 0;
	guint len;
	guchar *token;
	struct _CamelMessageContentInfo * cinfo = NULL;
	struct _CamelMessageContentInfo *subinfo, *last;
	struct _CamelContentDisposition * dinfo = NULL;
	GError *local_error = NULL;

	/* body            ::= "(" body_type_1part / body_type_mpart ")" */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);
	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"body: expecting '('");
		return NULL;
	}

	if (local_error)
		goto error;

	/* 1*body (optional for multiparts) */
	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, &local_error);

	if (local_error)
		goto error;

	camel_imapx_input_stream_ungettoken (stream, tok, token, len);

	if (tok == '(') {
		/* body_type_mpart ::= 1*body SPACE media_subtype
		[SPACE body_ext_mpart] */

		cinfo = camel_message_content_info_new ();
		last = (struct _CamelMessageContentInfo *) &cinfo->childs;
		do {
			subinfo = imapx_parse_body (stream, cancellable, &local_error);
			if (local_error)
				goto error;

			last->next = subinfo;
			last = subinfo;
			subinfo->parent = cinfo;
			tok = camel_imapx_input_stream_token (
				stream, &token, &len,
				cancellable, &local_error);

			if (local_error)
				goto error;

			camel_imapx_input_stream_ungettoken (
				stream, tok, token, len);
		} while (tok == '(');

		if (!camel_imapx_input_stream_astring (stream, &token, cancellable, &local_error) || local_error)
			goto error;

		cinfo->type = camel_content_type_new (
			"multipart", (gchar *) token);

		/* body_ext_mpart  ::= body_fld_param
		 * [SPACE body_fld_dsp SPACE body_fld_lang
		 * [SPACE 1#body_extension]]
		 *    ;; MUST NOT be returned on non-extensible
		 *    ;; "BODY" fetch */

		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, &local_error);

		if (local_error)
			goto error;

		camel_imapx_input_stream_ungettoken (stream, tok, token, len);

		if (tok == '(') {
			imapx_parse_param_list (
				stream, &cinfo->type->params,
				cancellable, &local_error);

			if (local_error)
				goto error;

			/* body_fld_dsp    ::= "(" string SPACE body_fld_param ")" / nil */

			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, &local_error);

			if (local_error)
				goto error;

			camel_imapx_input_stream_ungettoken (
				stream, tok, token, len);

			if (tok == '(' || tok == IMAPX_TOK_TOKEN) {
				if (tok == '(')
					dinfo = imapx_parse_ext_optional (stream, cancellable, &local_error);

				if (local_error)
					goto error;
				/* other extension fields?, soaked up below */
			}
		}
	} else {
		/* body_type_1part ::= (body_type_basic / body_type_msg / body_type_text)
		 * [SPACE body_ext_1part]
		 *
		 * body_type_basic ::= media_basic SPACE body_fields
		 * body_type_text  ::= media_text SPACE body_fields SPACE body_fld_lines
		 * body_type_msg   ::= media_message SPACE body_fields SPACE envelope
		 * SPACE body SPACE body_fld_lines */

		cinfo = imapx_parse_body_fields (
			stream, cancellable, &local_error);

		if (local_error)
			goto error;

		/* do we have an envelope following */
		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, &local_error);

		if (local_error)
			goto error;

		camel_imapx_input_stream_ungettoken (stream, tok, token, len);
		if (tok == '(') {
			CamelMessageInfo *minfo;

			/* Read and ignore the envelope */
			minfo = imapx_parse_envelope (stream, cancellable, &local_error);
			g_clear_object (&minfo);

			if (local_error)
				goto error;

			/* Read the message content info */
			subinfo = imapx_parse_body (stream, cancellable, &local_error);

			if (subinfo) {
				CamelMessageContentInfo **plast;

				plast = &(cinfo->childs);
				while (*plast) {
					plast = &((*plast)->next);
				}

				*plast = subinfo;
				subinfo->parent = cinfo;
			}

			if (local_error)
				goto error;
		}

		/* do we have fld_lines following? */
		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, &local_error);

		if (local_error)
			goto error;

		if (tok == IMAPX_TOK_INT) {
			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, &local_error);

			if (local_error)
				goto error;
		}
		camel_imapx_input_stream_ungettoken (stream, tok, token, len);

		/* body_ext_1part  ::= body_fld_md5 [SPACE body_fld_dsp
		[SPACE body_fld_lang
		[SPACE 1#body_extension]]]
		 * ;; MUST NOT be returned on non - extensible
		 * ;; "BODY" fetch */

		if (tok != ')') {
			camel_imapx_input_stream_nstring (
				stream, &token, cancellable, &local_error);

			if (local_error)
				goto error;

			/* body_fld_dsp    ::= "(" string SPACE body_fld_param ")" / nil */

			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, &local_error);

			if (local_error)
				goto error;

			camel_imapx_input_stream_ungettoken (
				stream, tok, token, len);
			if (tok == '(' || tok == IMAPX_TOK_TOKEN) {
				if (tok == '(')
					dinfo = imapx_parse_ext_optional (stream, cancellable, &local_error);

				if (local_error)
					goto error;
				/* then other extension fields, soaked up below */
			}
		}
	}

	/* soak up any other extension fields that may be present */
	do {
		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, &local_error);

		if (local_error)
			goto error;

		if (tok == '(') {
			nested_extension++;
		} else if (tok == ')' && nested_extension > 0) {
			tok = 0; /* To not be used as the stop condition */
			nested_extension--;
		} else if (tok == IMAPX_TOK_LITERAL) {
			camel_imapx_input_stream_set_literal (stream, len);

			do {
				tok = camel_imapx_input_stream_getl (stream, &token, &len, cancellable, error);
			} while (tok > 0);
		}
	} while ((nested_extension > 0 || tok != ')') && tok != IMAPX_TOK_ERROR);

 error:
	/* CHEN TODO handle exceptions better */
	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		if (cinfo)
			camel_message_content_info_free (cinfo);
		if (dinfo)
			camel_content_disposition_unref (dinfo);
		return NULL;
	}

	if (cinfo)
		cinfo->disposition = dinfo;
	else if (dinfo)
		camel_content_disposition_unref (dinfo);

	return cinfo;
}

gchar *
imapx_parse_section (CamelIMAPXInputStream *stream,
                     GCancellable *cancellable,
                     GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	gchar * section = NULL;

	/* currently we only return the part within the [section] specifier
	 * any header fields are parsed, but dropped */

	/*
	 * section         ::= "[" [section_text /
	 * (nz_number *["." nz_number] ["." (section_text / "MIME")])] "]"
	 *
	 * section_text    ::= "HEADER" / "HEADER.FIELDS" [".NOT"]
	 * SPACE header_list / "TEXT"
	 */

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, NULL);

	if (tok != '[') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"section: expecting '['");
		return NULL;
	}

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, NULL);

	if (tok == IMAPX_TOK_INT || tok == IMAPX_TOK_TOKEN)
		section = g_strdup ((gchar *) token);
	else if (tok == ']') {
		section = g_strdup ("");
		camel_imapx_input_stream_ungettoken (stream, tok, token, len);
	} else {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"section: expecting token");
		return NULL;
	}

	/* header_list     ::= "(" 1#header_fld_name ")"
	 * header_fld_name ::= astring */

	/* we dont need the header specifiers */
	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, NULL);

	if (tok == '(') {
		do {
			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, NULL);

			if (tok == IMAPX_TOK_STRING || tok == IMAPX_TOK_TOKEN || tok == IMAPX_TOK_INT) {
				/* ?do something? */
			} else if (tok != ')') {
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"section: header fields: expecting string");
				g_free (section);
				return NULL;
			}
		} while (tok != ')');

		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, NULL);
	}

	if (tok != ']') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"section: expecting ']'");
		g_free (section);
		return NULL;
	}

	return section;
}

static guint64
imapx_parse_modseq (CamelIMAPXInputStream *stream,
                    GCancellable *cancellable,
                    GError **error)
{
	guint64 modseq = 0;
	gint tok;
	guint len;
	guchar *token;
	gboolean success;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return 0;

	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"fetch: expecting '('");
		return 0;
	}

	success = camel_imapx_input_stream_number (
		stream, &modseq, cancellable, error);

	if (!success)
		return 0;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return 0;

	if (tok != ')') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"fetch: expecting '('");
		return 0;
	}

	return modseq;
}

void
imapx_free_fetch (struct _fetch_info *finfo)
{
	if (finfo == NULL)
		return;

	if (finfo->body)
		g_bytes_unref (finfo->body);
	if (finfo->text)
		g_bytes_unref (finfo->text);
	if (finfo->header)
		g_bytes_unref (finfo->header);
	if (finfo->cinfo)
		camel_message_content_info_free (finfo->cinfo);
	camel_named_flags_free (finfo->user_flags);
	g_clear_object (&finfo->minfo);
	g_free (finfo->date);
	g_free (finfo->section);
	g_free (finfo->uid);
	g_free (finfo);
}

/* debug, dump one out */
void
imapx_dump_fetch (struct _fetch_info *finfo)
{
	gconstpointer data;
	gsize size;

	d ('?', "Fetch info:\n");
	if (finfo == NULL) {
		d ('?', "Empty\n");
		return;
	}

	/* XXX g_output_stream_write_bytes_all() would be awfully
	 *     handy here.  g_output_stream_write_bytes() may not
	 *     write the entire GBytes. */

	if (finfo->body != NULL) {
		g_print ("Body content:\n");
		data = g_bytes_get_data (finfo->body, &size);
		fwrite (data, sizeof (gchar), size, stdout);
	}

	if (finfo->text != NULL) {
		g_print ("Text content:\n");
		data = g_bytes_get_data (finfo->text, &size);
		fwrite (data, sizeof (gchar), size, stdout);
	}

	if (finfo->header != NULL) {
		g_print ("Header content:\n");
		data = g_bytes_get_data (finfo->header, &size);
		fwrite (data, sizeof (gchar), size, stdout);
	}

	if (finfo->minfo != NULL) {
		g_print ("Message Info:\n");
		camel_message_info_dump (finfo->minfo);
	}

	if (finfo->got & FETCH_SIZE)
		g_print ("Size: %d\n", (gint) finfo->size);

	if (finfo->got & FETCH_BODY)
		g_print ("Offset: %d\n", (gint) finfo->offset);

	if (finfo->got & FETCH_FLAGS)
		g_print ("Flags: %08x\n", (gint) finfo->flags);

	if (finfo->date != NULL)
		g_print ("Date: '%s'\n", finfo->date);

	if (finfo->section != NULL)
		g_print ("Section: '%s'\n", finfo->section);

	if (finfo->uid != NULL)
		g_print ("UID: '%s'\n", finfo->uid);
}

static gboolean
imapx_parse_fetch_body (CamelIMAPXInputStream *stream,
                        struct _fetch_info *finfo,
                        GCancellable *cancellable,
                        GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return FALSE;

	camel_imapx_input_stream_ungettoken (stream, tok, token, len);

	if (tok == '(') {
		finfo->cinfo = imapx_parse_body (stream, cancellable, error);

		if (finfo->cinfo != NULL)
			finfo->got |= FETCH_CINFO;

		return (finfo->cinfo != NULL);
	}

	if (tok == '[') {
		gboolean success;

		finfo->section = imapx_parse_section (
			stream, cancellable, error);

		if (finfo->section == NULL)
			return FALSE;

		finfo->got |= FETCH_SECTION;

		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, error);

		if (tok == IMAPX_TOK_ERROR)
			return FALSE;

		if (token[0] == '<') {
			finfo->offset = g_ascii_strtoull (
				(gchar *) token + 1, NULL, 10);
		} else {
			camel_imapx_input_stream_ungettoken (
				stream, tok, token, len);
		}

		success = camel_imapx_input_stream_nstring_bytes (
			stream, &finfo->body, TRUE, cancellable, error);

		/* Sanity check. */
		g_return_val_if_fail (
			(success && (finfo->body != NULL)) ||
			(!success && (finfo->body == NULL)), FALSE);

		if (success)
			finfo->got |= FETCH_BODY;

		return success;
	}

	g_set_error (
		error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
		"unknown body response");

	return FALSE;
}

static gboolean
imapx_parse_fetch_bodystructure (CamelIMAPXInputStream *stream,
                                 struct _fetch_info *finfo,
                                 GCancellable *cancellable,
                                 GError **error)
{
	finfo->cinfo = imapx_parse_body (stream, cancellable, error);

	if (finfo->cinfo != NULL)
		finfo->got |= FETCH_CINFO;

	return (finfo->cinfo != NULL);
}

static gboolean
imapx_parse_fetch_envelope (CamelIMAPXInputStream *stream,
                            struct _fetch_info *finfo,
                            GCancellable *cancellable,
                            GError **error)
{
	finfo->minfo = imapx_parse_envelope (stream, cancellable, error);

	if (finfo->minfo != NULL)
		finfo->got |= FETCH_MINFO;

	return (finfo->minfo != NULL);
}

static gboolean
imapx_parse_fetch_flags (CamelIMAPXInputStream *stream,
                         struct _fetch_info *finfo,
                         GCancellable *cancellable,
                         GError **error)
{
	gboolean success;

	success = imapx_parse_flags (
		stream, &finfo->flags, finfo->user_flags,
		cancellable, error);

	if (success)
		finfo->got |= FETCH_FLAGS;

	return success;
}

static gboolean
imapx_parse_fetch_internaldate (CamelIMAPXInputStream *stream,
                                struct _fetch_info *finfo,
                                GCancellable *cancellable,
                                GError **error)
{
	guchar *token;
	gboolean success;

	success = camel_imapx_input_stream_nstring (
		stream, &token, cancellable, error);

	if (!success)
		return FALSE;

	/* XXX Convert to Camel format? */
	finfo->date = g_strdup ((gchar *) token);
	finfo->got |= FETCH_DATE;

	return TRUE;
}

static gboolean
imapx_parse_fetch_modseq (CamelIMAPXInputStream *stream,
                          struct _fetch_info *finfo,
                          GCancellable *cancellable,
                          GError **error)
{
	finfo->modseq = imapx_parse_modseq (stream, cancellable, error);

	if (finfo->modseq > 0)
		finfo->got |= FETCH_MODSEQ;

	return (finfo->modseq > 0);
}

static gboolean
imapx_parse_fetch_rfc822_header (CamelIMAPXInputStream *stream,
                                 struct _fetch_info *finfo,
                                 GCancellable *cancellable,
                                 GError **error)
{
	gboolean success;

	success = camel_imapx_input_stream_nstring_bytes (
		stream, &finfo->header, FALSE, cancellable, error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (finfo->header != NULL)) ||
		(!success && (finfo->header == NULL)), FALSE);

	if (success)
		finfo->got |= FETCH_HEADER;

	return success;
}

static gboolean
imapx_parse_fetch_rfc822_size (CamelIMAPXInputStream *stream,
                               struct _fetch_info *finfo,
                               GCancellable *cancellable,
                               GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	finfo->size = (guint32) number;
	finfo->got |= FETCH_SIZE;

	return TRUE;
}

static gboolean
imapx_parse_fetch_rfc822_text (CamelIMAPXInputStream *stream,
                               struct _fetch_info *finfo,
                               GCancellable *cancellable,
                               GError **error)
{
	gboolean success;

	success = camel_imapx_input_stream_nstring_bytes (
		stream, &finfo->text, FALSE, cancellable, error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (finfo->text != NULL)) ||
		(!success && (finfo->text == NULL)), FALSE);

	if (success)
		finfo->got |= FETCH_TEXT;

	return success;
}

static gboolean
imapx_parse_fetch_uid (CamelIMAPXInputStream *stream,
                       struct _fetch_info *finfo,
                       GCancellable *cancellable,
                       GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		return FALSE;

	if (tok != IMAPX_TOK_INT) {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"uid not integer");
		return FALSE;
	}

	finfo->uid = g_strdup ((gchar *) token);
	finfo->got |= FETCH_UID;

	return TRUE;
}

struct _fetch_info *
imapx_parse_fetch (CamelIMAPXInputStream *stream,
                   GCancellable *cancellable,
                   GError **error)
{
	gint tok;
	guint len;
	guchar *token, *p, c;
	struct _fetch_info *finfo;

	finfo = g_malloc0 (sizeof (*finfo));
	finfo->user_flags = camel_named_flags_new ();

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		goto fail;

	if (tok != '(') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"fetch: expecting '('");
		goto fail;
	}

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	while (tok == IMAPX_TOK_TOKEN) {
		gboolean success = FALSE;

		p = token;
		while ((c=*p))
			*p++ = toupper(c);

		switch (imapx_tokenise ((gchar *) token, len)) {
			case IMAPX_BODY:
				success = imapx_parse_fetch_body (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_BODYSTRUCTURE:
				success = imapx_parse_fetch_bodystructure (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_ENVELOPE:
				success = imapx_parse_fetch_envelope (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_FLAGS:
				success = imapx_parse_fetch_flags (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_INTERNALDATE:
				success = imapx_parse_fetch_internaldate (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_MODSEQ:
				success = imapx_parse_fetch_modseq (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_RFC822_HEADER:
				success = imapx_parse_fetch_rfc822_header (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_RFC822_SIZE:
				success = imapx_parse_fetch_rfc822_size (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_RFC822_TEXT:
				success = imapx_parse_fetch_rfc822_text (
					stream, finfo, cancellable, error);
				break;

			case IMAPX_UID:
				success = imapx_parse_fetch_uid (
					stream, finfo, cancellable, error);
				break;

			default:
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"unknown body response");
				break;
		}

		if (!success)
			goto fail;

		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, error);
		if (tok == '\n') {
			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, error);
		}
	}

	if (tok == IMAPX_TOK_ERROR)
		goto fail;

	if (tok != ')') {
		g_set_error (
			error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
			"missing closing ')' on fetch response (got 0x%x)", tok);
		goto fail;
	}

	goto exit;

fail:
	imapx_free_fetch (finfo);
	finfo = NULL;

exit:
	return finfo;
}

static gboolean
imapx_fill_uids_array_cb (guint32 uid,
			  gpointer user_data)
{
	GArray *array = user_data;

	g_return_val_if_fail (array != NULL, FALSE);

	g_array_append_val (array, uid);

	return TRUE;
}

gboolean
imapx_parse_uids_with_callback (CamelIMAPXInputStream *stream,
				gboolean (* func) (guint32 uid, gpointer user_data),
				gpointer user_data,
				GCancellable *cancellable,
				GError **error)
{
	gboolean can_continue = TRUE;
	guchar *token = NULL;
	gchar **splits;
	guint len;
	gint tok, ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), FALSE);
	g_return_val_if_fail (func != NULL, FALSE);

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	if (tok < 0)
		return FALSE;

	if (!token) {
		g_set_error (error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_IGNORE, "server response truncated");

		camel_imapx_input_stream_ungettoken (stream, tok, token, len);

		return FALSE;
	}

	splits = g_strsplit ((gchar *) token, ",", -1);

	for (ii = 0; can_continue && splits[ii]; ii++) {
		guint32 uid;

		if (g_strstr_len (splits[ii], -1, ":")) {
			gchar **seq = g_strsplit (splits[ii], ":", -1);
			guint32 first = strtoul (seq[0], NULL, 10);
			guint32 last = strtoul (seq[1], NULL, 10);

			for (uid = first; uid <= last && can_continue; uid++) {
				can_continue = func (uid, user_data);
			}

			g_strfreev (seq);
		} else {
			uid = strtoul (splits[ii], NULL, 10);
			can_continue = func (uid, user_data);
		}
	}

	g_strfreev (splits);

	return TRUE;
}

GArray *
imapx_parse_uids (CamelIMAPXInputStream *stream,
                  GCancellable *cancellable,
                  GError **error)
{
	GArray *array;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), NULL);

	array = g_array_new (FALSE, FALSE, sizeof (guint32));

	if (!imapx_parse_uids_with_callback (stream, imapx_fill_uids_array_cb, array, cancellable, error)) {
		g_array_free (array, TRUE);
		array = NULL;
	}

	return array;
}

static gboolean
imapx_parse_status_appenduid (CamelIMAPXInputStream *stream,
                              struct _status_info *sinfo,
                              GCancellable *cancellable,
                              GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	sinfo->u.appenduid.uidvalidity = number;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	sinfo->u.appenduid.uid = (guint32) number;

	return TRUE;
}

static gboolean
imapx_parse_status_capability (CamelIMAPXInputStream *stream,
                               struct _status_info *sinfo,
                               GCancellable *cancellable,
                               GError **error)
{
	sinfo->u.cinfo = imapx_parse_capability (stream, cancellable, error);

	return (sinfo->u.cinfo != NULL);
}

static gboolean
imapx_parse_status_copyuid (CamelIMAPXInputStream *stream,
                            struct _status_info *sinfo,
                            GCancellable *cancellable,
                            GError **error)
{
	GArray *uids;
	guint64 number;
	gboolean success;
	GError *local_error = NULL;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	sinfo->u.copyuid.uidvalidity = number;

	uids = imapx_parse_uids (stream, cancellable, &local_error);
	if (uids == NULL) {
		/* Sometimes the server can return truncated response, like:
		   B00083 OK [COPYUID 4154  ] COPY completed.
		   It's for example when moving/copying messages which are not
		   available on the serer any more.
		   Just ignore such server error.
		*/
		if (g_error_matches (local_error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_IGNORE)) {
			g_clear_error (&local_error);
			return TRUE;
		}

		if (local_error)
			g_propagate_error (error, local_error);

		return FALSE;
	}

	sinfo->u.copyuid.uids = uids;

	uids = imapx_parse_uids (stream, cancellable, error);
	if (uids == NULL) {
		if (g_error_matches (local_error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_IGNORE)) {
			g_clear_error (&local_error);
			return TRUE;
		}

		if (local_error)
			g_propagate_error (error, local_error);

		return FALSE;
	}

	sinfo->u.copyuid.copied_uids = uids;

	return TRUE;
}

static gboolean
imapx_parse_status_highestmodseq (CamelIMAPXInputStream *stream,
                                  CamelIMAPXMailbox *mailbox,
                                  GCancellable *cancellable,
                                  GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	camel_imapx_mailbox_set_highestmodseq (mailbox, number);

	return TRUE;
}

static gboolean
imapx_parse_status_newname (CamelIMAPXInputStream *stream,
                            struct _status_info *sinfo,
                            GCancellable *cancellable,
                            GError **error)
{
	guchar *token;
	gboolean success;

	/* XXX The RFC doesn't specify the BNF grammer for this. */

	success = camel_imapx_input_stream_astring (
		stream, &token, cancellable, error);

	if (!success)
		return FALSE;

	sinfo->u.newname.oldname = g_strdup ((gchar *) token);

	success = camel_imapx_input_stream_astring (
		stream, &token, cancellable, error);

	if (!success)
		return FALSE;

	sinfo->u.newname.newname = g_strdup ((gchar *) token);

	return TRUE;
}

static gboolean
imapx_parse_status_permanentflags (CamelIMAPXInputStream *stream,
				   CamelIMAPXMailbox *mailbox,
                                   GCancellable *cancellable,
                                   GError **error)
{
	guint32 flags;

	/* We only care about \* for permanent flags, not user flags. */
	if (!imapx_parse_flags (stream, &flags, NULL, cancellable, error))
		return FALSE;

	camel_imapx_mailbox_set_permanentflags (mailbox, flags);

	return TRUE;
}

static gboolean
imapx_parse_status_uidnext (CamelIMAPXInputStream *stream,
                            CamelIMAPXMailbox *mailbox,
                            GCancellable *cancellable,
                            GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	camel_imapx_mailbox_set_uidnext (mailbox, (guint32) number);

	return TRUE;
}

static gboolean
imapx_parse_status_uidvalidity (CamelIMAPXInputStream *stream,
                                CamelIMAPXMailbox *mailbox,
                                GCancellable *cancellable,
                                GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	camel_imapx_mailbox_set_uidvalidity (mailbox, (guint32) number);

	return TRUE;
}

static gboolean
imapx_parse_status_unseen (CamelIMAPXInputStream *stream,
                           CamelIMAPXMailbox *mailbox,
                           GCancellable *cancellable,
                           GError **error)
{
	guint64 number;
	gboolean success;

	success = camel_imapx_input_stream_number (
		stream, &number, cancellable, error);

	if (!success)
		return FALSE;

	camel_imapx_mailbox_set_unseen (mailbox, (guint32) number);

	return TRUE;
}

/* rfc 2060 section 7.1 Status Responses */
/* should this start after [ or before the [? token_unget anyone? */
struct _status_info *
imapx_parse_status (CamelIMAPXInputStream *stream,
                    CamelIMAPXMailbox *mailbox,
		    gboolean is_ok_no_bad,
                    GCancellable *cancellable,
                    GError **error)
{
	gint tok;
	guint len;
	guchar *token;
	struct _status_info *sinfo;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), NULL);

	success = camel_imapx_input_stream_atom (
		stream, &token, &len, cancellable, error);

	if (!success)
		return NULL;

	sinfo = g_malloc0 (sizeof (*sinfo));

	/*
	 * resp_cond_auth  ::= ("OK" / "PREAUTH") SPACE resp_text
	 * ;; Authentication condition
	 *
	 * resp_cond_bye   ::= "BYE" SPACE resp_text
	 *
	 * resp_cond_state ::= ("OK" / "NO" / "BAD") SPACE resp_text
	 * ;; Status condition
	 */

	sinfo->result = imapx_tokenise ((gchar *) token, len);
	switch (sinfo->result) {
		case IMAPX_OK:
		case IMAPX_NO:
		case IMAPX_BAD:
		case IMAPX_PREAUTH:
		case IMAPX_BYE:
			break;
		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"expecting OK/NO/BAD");
			goto fail;
	}

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);

	if (tok == IMAPX_TOK_ERROR)
		goto fail;

	if (tok == '[') {
		gboolean success;

		success = camel_imapx_input_stream_atom (
			stream, &token, &len, cancellable, error);

		if (!success)
			goto fail;

		sinfo->condition = imapx_tokenise ((gchar *) token, len);

		/* parse any details */
		switch (sinfo->condition) {
			case IMAPX_READ_ONLY:
			case IMAPX_READ_WRITE:
			case IMAPX_ALERT:
			case IMAPX_PARSE:
			case IMAPX_TRYCREATE:
			case IMAPX_CLOSED:
				break;

			case IMAPX_APPENDUID:
				success = imapx_parse_status_appenduid (
					stream, sinfo, cancellable, error);
				break;

			case IMAPX_CAPABILITY:
				success = imapx_parse_status_capability (
					stream, sinfo, cancellable, error);
				break;

			case IMAPX_COPYUID:
				success = imapx_parse_status_copyuid (
					stream, sinfo, cancellable, error);
				break;

			case IMAPX_HIGHESTMODSEQ:
				success = imapx_parse_status_highestmodseq (
					stream, mailbox, cancellable, error);
				break;

			case IMAPX_NEWNAME:
				success = imapx_parse_status_newname (
					stream, sinfo, cancellable, error);
				break;

			case IMAPX_PERMANENTFLAGS:
				success = imapx_parse_status_permanentflags (
					stream, mailbox, cancellable, error);
				break;

			case IMAPX_UIDNEXT:
				success = imapx_parse_status_uidnext (
					stream, mailbox, cancellable, error);
				break;

			case IMAPX_UIDVALIDITY:
				success = imapx_parse_status_uidvalidity (
					stream, mailbox, cancellable, error);
				break;

			case IMAPX_UNSEEN:
				/* Ignore UNSEEN in OK/NO/BAD, because it's not count of unseen
				   messages, but the sequence number of the first unseen message. */
				success = is_ok_no_bad || imapx_parse_status_unseen (
					stream, mailbox, cancellable, error);
				break;

			/* RFC 5530 Response Codes */
			case IMAPX_ALREADYEXISTS:
			case IMAPX_AUTHENTICATIONFAILED:
			case IMAPX_AUTHORIZATIONFAILED:
			case IMAPX_CANNOT:
			case IMAPX_CLIENTBUG:
			case IMAPX_CONTACTADMIN:
			case IMAPX_CORRUPTION:
			case IMAPX_EXPIRED:
			case IMAPX_EXPUNGEISSUED:
			case IMAPX_INUSE:
			case IMAPX_LIMIT:
			case IMAPX_NONEXISTENT:
			case IMAPX_NOPERM:
			case IMAPX_OVERQUOTA:
			case IMAPX_PRIVACYREQUIRED:
			case IMAPX_SERVERBUG:
			case IMAPX_UNAVAILABLE:
				break;

			default:
				sinfo->condition = IMAPX_UNKNOWN;
		}

		if (!success)
			goto fail;

		/* ignore anything we dont know about */
		do {
			tok = camel_imapx_input_stream_token (
				stream, &token, &len, cancellable, NULL);
			if (tok == '\n' || tok < 0) {
				g_set_error (
					error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
					"server response truncated");
				goto fail;
			}
		} while (tok != ']');
	} else {
		camel_imapx_input_stream_ungettoken (stream, tok, token, len);
	}

	/* and take the human readable response */
	success = camel_imapx_input_stream_text (
		stream, (guchar **) &sinfo->text, cancellable, error);

	if (!success)
		goto fail;

	if (sinfo->text) {
		g_strstrip (sinfo->text);
	}

	goto exit;

fail:
	imapx_free_status (sinfo);
	sinfo = NULL;

exit:
	return sinfo;
}

struct _status_info *
imapx_copy_status (struct _status_info *sinfo)
{
	struct _status_info *out;

	out = g_malloc (sizeof (*out));
	memcpy (out, sinfo, sizeof (*out));
	out->text = g_strdup (out->text);
	if (out->condition == IMAPX_NEWNAME) {
		out->u.newname.oldname = g_strdup (out->u.newname.oldname);
		out->u.newname.newname = g_strdup (out->u.newname.newname);
	}

	return out;
}

void
imapx_free_status (struct _status_info *sinfo)
{
	if (sinfo == NULL)
		return;

	switch (sinfo->condition) {
	case IMAPX_NEWNAME:
		g_free (sinfo->u.newname.oldname);
		g_free (sinfo->u.newname.newname);
		break;
	case IMAPX_COPYUID:
		if (sinfo->u.copyuid.uids)
			g_array_free (sinfo->u.copyuid.uids, TRUE);
		if (sinfo->u.copyuid.copied_uids)
			g_array_free (sinfo->u.copyuid.copied_uids, TRUE);
		break;
	case IMAPX_CAPABILITY:
		if (sinfo->u.cinfo)
			imapx_free_capability (sinfo->u.cinfo);
		break;
	default:
		break;
	}

	g_free (sinfo->text);
	g_free (sinfo);
}

gboolean
camel_imapx_command_add_qresync_parameter (CamelIMAPXCommand *ic,
                                           CamelFolder *folder)
{
	/* See RFC 5162 Section 3.1 */

	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXSummary *imapx_summary;
	CamelIMAPXMailbox *mailbox;
	GPtrArray *summary_array;
	guint64 last_known_uidvalidity;
	guint64 last_known_modsequence;
	guint32 last_known_message_cnt;
	guint32 sequence_limit;
	gchar *known_uid_set = NULL;
	gint summary_total;
	gboolean parameter_added = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_COMMAND (ic), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), FALSE);

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	imapx_summary = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (folder));

	summary_array = camel_folder_summary_get_array (CAMEL_FOLDER_SUMMARY (imapx_summary));
	g_return_val_if_fail (summary_array != NULL, FALSE);

	camel_folder_sort_uids (folder, summary_array);

	mailbox = camel_imapx_folder_ref_mailbox (imapx_folder);
	if (!mailbox) {
		camel_folder_summary_free_array (summary_array);
		return FALSE;
	}

	last_known_uidvalidity = camel_imapx_mailbox_get_uidvalidity (mailbox);
	last_known_modsequence = imapx_summary->modseq;
	last_known_message_cnt = camel_imapx_mailbox_get_messages (mailbox);

	/* XXX This should return an unsigned integer to
	 *     avoid the possibility of a negative count. */
	summary_total = camel_folder_summary_count (camel_folder_get_folder_summary (folder));
	g_return_val_if_fail (summary_total >= 0, FALSE);

	if (summary_total > 0) {
		guint last = summary_total - 1;

		if (0 < summary_array->len && last < summary_array->len) {
			const gchar *begin, *end;

			begin = g_ptr_array_index (summary_array, 0);
			end = g_ptr_array_index (summary_array, last);

			if (begin && end)
				known_uid_set = g_strconcat (begin, ":", end, NULL);
		}
	}

	/* Make sure we have valid QRESYNC arguments. */

	if (last_known_uidvalidity == 0)
		goto exit;

	if (last_known_modsequence == 0)
		goto exit;

	if (known_uid_set == NULL)
		goto exit;

	camel_imapx_command_add (
		ic, " (QRESYNC (%"
		G_GUINT64_FORMAT " %"
		G_GUINT64_FORMAT " %s",
		last_known_uidvalidity,
		last_known_modsequence,
		known_uid_set);

	/* Add message sequence match data if we have enough messages. */

	/* XXX Some IMAP servers like Zimbra can't handle invalid sequence
	 *     numbers in the optional seq/uid list.  So limit the list to
	 *     the lesser of the last known message count according to the
	 *     server and our own summary count. */
	sequence_limit = MIN (last_known_message_cnt, summary_total);

	if (sequence_limit > 10) {
		GString *seqs;
		GString *uids;
		guint32 ii = 3;

		seqs = g_string_sized_new (256);
		uids = g_string_sized_new (256);

		/* Include some seq/uid pairs to avoid a huge VANISHED list.
		 * Work backwards exponentially from the end of the mailbox,
		 * starting with message 9 from the end, then 27 from the
		 * end, then 81 from the end, etc. */
		do {
			guint32 summary_index;
			gchar buf[10];
			const gchar *uid;

			ii = MIN (ii * 3, sequence_limit);
			summary_index = sequence_limit - ii;

			if (seqs->len > 0)
				g_string_prepend_c (seqs, ',');

			if (uids->len > 0)
				g_string_prepend_c (uids, ',');

			/* IMAP sequence numbers are 1-based,
			 * but our folder summary is 0-based. */
			g_snprintf (
				buf, sizeof (buf),
				"%" G_GUINT32_FORMAT,
				summary_index + 1);

			uid = NULL;
			if (summary_index < summary_array->len)
				uid = g_ptr_array_index (summary_array, summary_index);
			if (uid != NULL) {
				g_string_prepend (seqs, buf);
				g_string_prepend (uids, uid);
			}
		} while (ii < sequence_limit);

		camel_imapx_command_add (
			ic, " (%s %s)", seqs->str, uids->str);

		g_string_free (seqs, TRUE);
		g_string_free (uids, TRUE);
	}

	camel_imapx_command_add (ic, "))");

	parameter_added = TRUE;

exit:
	g_free (known_uid_set);
	camel_folder_summary_free_array (summary_array);
	g_object_unref (mailbox);

	return parameter_added;
}

/**
 * camel_imapx_parse_mailbox:
 * @stream: a #CamelIMAPXInputStream
 * @separator: the mailbox separator character
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Parses a "mailbox" token from @stream, with the special case for INBOX as
 * described in <ulink url="http://tools.ietf.org/html/rfc3501#section-5.1">
 * RFC 3501 section 5.1</ulink>.
 *
 * The @separator character is used to identify INBOX and convert its name
 * to all caps, both for INBOX itself and its descendants.  If a separator
 * character was provided in the server response being parsed (such as for
 * LIST or LSUB), pass that for @separator.  If no separator character was
 * provided in the server response being parsed (such as for STATUS), then
 * pass the separator character specifically for INBOX.
 *
 * If an error occurs, the function sets @error and returns %NULL.
 *
 * Returns: a newly-allocated mailbox name, or %NULL
 *
 * Since: 3.10
 **/
gchar *
camel_imapx_parse_mailbox (CamelIMAPXInputStream *stream,
                           gchar separator,
                           GCancellable *cancellable,
                           GError **error)
{
	guchar *token;
	gchar *mailbox_name;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), NULL);

	success = camel_imapx_input_stream_astring (
		stream, &token, cancellable, error);

	if (!success)
		return NULL;

	mailbox_name = camel_utf7_utf8 ((gchar *) token);

	camel_imapx_normalize_mailbox (mailbox_name, separator);

	return mailbox_name;
}

/**
 * camel_imapx_normalize_mailbox:
 * @mailbox_name: a mailbox name
 * @separator: a mailbox separator character
 *
 * Converts the special INBOX mailbox to all caps, if it appears at the
 * beginning of @mailbox_name.  The @mailbox_name string is modified in
 * place.  The @separator character helps reliably identify descendants
 * of INBOX.
 *
 * Since: 3.10
 **/
void
camel_imapx_normalize_mailbox (gchar *mailbox_name,
                               gchar separator)
{
	gboolean normalize_inbox;

	g_return_if_fail (mailbox_name != NULL);

	/* mailbox ::= "INBOX" / astring
	 *             INBOX is case-insensitive.  All case variants of
	 *             INBOX (e.g., "iNbOx") MUST be interpreted as INBOX
	 *             not as an astring.  An astring which consists of
	 *             the case-insensitive sequence "I" "N" "B" "O" "X"
	 *             is considered to be INBOX and not an astring.
	 */

	normalize_inbox =
		(g_ascii_strncasecmp (mailbox_name, "INBOX", 5) == 0) &&
		(mailbox_name[5] == separator || mailbox_name[5] == '\0');

	if (normalize_inbox) {
		mailbox_name[0] = 'I';
		mailbox_name[1] = 'N';
		mailbox_name[2] = 'B';
		mailbox_name[3] = 'O';
		mailbox_name[4] = 'X';
	}
}

/**
 * camel_imapx_mailbox_is_inbox:
 * @mailbox_name: a mailbox name
 *
 * Returns whether @mailbox_name is the special mailbox INBOX.
 *
 * The function just performs a case-insensitive string comparsion; it's
 * more for readability.
 *
 * Returns: %TRUE if @mailbox_name is INBOX, %FALSE if not
 *
 * Since: 3.10
 **/
gboolean
camel_imapx_mailbox_is_inbox (const gchar *mailbox_name)
{
	g_return_val_if_fail (mailbox_name != NULL, FALSE);

	return (g_ascii_strcasecmp (mailbox_name, "INBOX") == 0);
}

/**
 * camel_imapx_mailbox_to_folder_path:
 * @mailbox_name: a mailbox name
 * @separator: mailbox separator character
 *
 * Converts @mailbox_name to a Camel folder path, which just replaces all
 * @separator characters with '/'.  If '/' appears in @mailbox_name, it is
 * replaced with @separator.  Free the returned string with g_free().
 *
 * Returns: a newly-allocated Camel folder path
 *
 * Since: 3.10
 **/
gchar *
camel_imapx_mailbox_to_folder_path (const gchar *mailbox_name,
                                    gchar separator)
{
	gchar *folder_path;

	g_return_val_if_fail (mailbox_name != NULL, NULL);

	folder_path = g_strdup (mailbox_name);

	if (separator != '\0' && separator != '/') {
		gchar *cp = folder_path;

		while (*cp != '\0') {
			if (*cp == '/')
				*cp = separator;
			else if (*cp == separator)
				*cp = '/';
			cp++;
		}
	}

	return folder_path;
}

/**
 * camel_imapx_folder_path_to_mailbox:
 * @folder_path: a Camel folder path
 * @separator: mailbox separator character
 *
 * Converts @folder_path to an IMAP mailbox name, which just replaces
 * all slash ('/') characters with @separator.  If @separator appears
 * in @folder_path, it is replaced with '/'.  Free the returned string
 * with g_free().
 *
 * Returns: a newly-allocated IMAP mailbox name
 *
 * Since: 3.10
 **/
gchar *
camel_imapx_folder_path_to_mailbox (const gchar *folder_path,
                                    gchar separator)
{
	g_return_val_if_fail (folder_path != NULL, NULL);

	/* XXX For now, all we're really doing in these conversions is
	 *     flip-flopping separator characters.  So we can just call
	 *     camel_imapx_mailbox_to_folder_path() on a folder path to
	 *     get the mailbox name.  But it is better to have separate
	 *     functions: 1) for readability, and 2) so we don't become
	 *     too dependent on this flip-flopping behavior. */
	return camel_imapx_mailbox_to_folder_path (folder_path, separator);
}

gboolean
camel_imapx_parse_quota (CamelIMAPXInputStream *stream,
                         GCancellable *cancellable,
                         gchar **out_quota_root_name,
                         CamelFolderQuotaInfo **out_quota_info,
                         GError **error)
{
	GQueue queue = G_QUEUE_INIT;
	CamelFolderQuotaInfo *info;
	CamelFolderQuotaInfo *next;
	gint tok;
	guint len;
	guchar *token;
	gchar *quota_root_name = NULL;
	gchar *resource_name = NULL;
	guint64 resource_usage;
	guint64 resource_limit;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), FALSE);
	g_return_val_if_fail (out_quota_root_name != NULL, FALSE);
	g_return_val_if_fail (out_quota_info != NULL, FALSE);

	/* quota_response  ::= "QUOTA" SP astring SP quota_list
	 * quota_list      ::= "(" *quota_resource ")"
	 * quota_resource  ::= atom SP number SP number */

	success = camel_imapx_input_stream_astring (
		stream, &token, cancellable, error);

	if (!success)
		goto fail;

	quota_root_name = g_strdup ((gchar *) token);

	tok = camel_imapx_input_stream_token (
		stream, &token, &len, cancellable, error);
	switch (tok) {
		case IMAPX_TOK_ERROR:
			goto fail;
		case '(':
			break;
		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"quota_response: expecting '('");
			goto fail;
	}

	while (TRUE) {
		/* Peek at the next token, and break
		 * out of the loop if we get a close-paren. */
		tok = camel_imapx_input_stream_token (
			stream, &token, &len, cancellable, error);
		if (tok == ')')
			break;
		if (tok == IMAPX_TOK_ERROR)
			goto fail;
		camel_imapx_input_stream_ungettoken (
			stream, tok, token, len);

		success = camel_imapx_input_stream_atom (
			stream, &token, &len, cancellable, error);

		if (!success)
			goto fail;

		resource_name = g_strdup ((gchar *) token);

		success = camel_imapx_input_stream_number (
			stream, &resource_usage, cancellable, error);

		if (!success)
			goto fail;

		success = camel_imapx_input_stream_number (
			stream, &resource_limit, cancellable, error);

		if (!success)
			goto fail;

		info = camel_folder_quota_info_new (
			resource_name, resource_usage, resource_limit);
		g_queue_push_tail (&queue, info);

		g_free (resource_name);
		resource_name = NULL;
	}

	/* Eat the newline. */
	success = camel_imapx_input_stream_skip (
		stream, cancellable, error);

	if (!success)
		goto fail;

	/* String together all the CamelFolderQuotaInfo structs. */

	info = next = NULL;

	while (!g_queue_is_empty (&queue)) {
		info = g_queue_pop_tail (&queue);
		info->next = next;
		next = info;
	}

	*out_quota_root_name = quota_root_name;
	*out_quota_info = info;

	return TRUE;

fail:
	g_free (quota_root_name);
	g_free (resource_name);

	while (!g_queue_is_empty (&queue)) {
		info = g_queue_pop_head (&queue);
		camel_folder_quota_info_free (info);
	}

	return FALSE;
}

gboolean
camel_imapx_parse_quotaroot (CamelIMAPXInputStream *stream,
                             GCancellable *cancellable,
                             gchar **out_mailbox_name,
                             gchar ***out_quota_roots,
                             GError **error)
{
	GQueue queue = G_QUEUE_INIT;
	gint tok;
	guint len;
	guchar *token;
	gchar *mailbox_name = NULL;
	gchar **quota_roots = NULL;
	gboolean success;
	gint ii = 0;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (stream), FALSE);
	g_return_val_if_fail (out_mailbox_name != NULL, FALSE);
	g_return_val_if_fail (out_quota_roots != NULL, FALSE);

	/* quotaroot_response ::= "QUOTAROOT" SP astring *(SP astring) */

	success = camel_imapx_input_stream_astring (
		CAMEL_IMAPX_INPUT_STREAM (stream),
		&token, cancellable, error);

	if (!success)
		goto fail;

	mailbox_name = camel_utf7_utf8 ((gchar *) token);

	while (TRUE) {
		/* Peek at the next token, and break
		 * out of the loop if we get a newline. */
		tok = camel_imapx_input_stream_token (
			CAMEL_IMAPX_INPUT_STREAM (stream),
			&token, &len, cancellable, error);
		if (tok == '\n')
			break;
		if (tok == IMAPX_TOK_ERROR)
			goto fail;
		camel_imapx_input_stream_ungettoken (
			CAMEL_IMAPX_INPUT_STREAM (stream),
			tok, token, len);

		success = camel_imapx_input_stream_astring (
			CAMEL_IMAPX_INPUT_STREAM (stream),
			&token, cancellable, error);

		if (!success)
			goto fail;

		g_queue_push_tail (&queue, g_strdup ((gchar *) token));
	}

	quota_roots = g_new0 (gchar *, queue.length + 1);
	while (!g_queue_is_empty (&queue))
		quota_roots[ii++] = g_queue_pop_head (&queue);

	*out_mailbox_name = mailbox_name;
	*out_quota_roots = quota_roots;

	return TRUE;

fail:
	g_free (mailbox_name);

	while (!g_queue_is_empty (&queue))
		g_free (g_queue_pop_head (&queue));

	return FALSE;
}

/* ********************************************************************** */

#ifdef ENABLE_MAINTAINER_MODE

static void
imapx_verify_tokens_tab (void)
{
	#define item(x) { x, #x }
	struct _values {
		camel_imapx_id_t id;
		const gchar *str;
	} values[] = {
		item (IMAPX_ALERT),
		item (IMAPX_APPENDUID),
		item (IMAPX_BAD),
		item (IMAPX_BODY),
		item (IMAPX_BODYSTRUCTURE),
		item (IMAPX_BYE),
		item (IMAPX_CAPABILITY),
		item (IMAPX_CLOSED),
		item (IMAPX_COPYUID),
		item (IMAPX_ENVELOPE),
		item (IMAPX_EXISTS),
		item (IMAPX_EXPUNGE),
		item (IMAPX_FETCH),
		item (IMAPX_FLAGS),
		item (IMAPX_HIGHESTMODSEQ),
		item (IMAPX_INTERNALDATE),
		item (IMAPX_LIST),
		item (IMAPX_LSUB),
		item (IMAPX_MESSAGES),
		item (IMAPX_MODSEQ),
		item (IMAPX_NAMESPACE),
		item (IMAPX_NEWNAME),
		item (IMAPX_NO),
		item (IMAPX_NOMODSEQ),
		item (IMAPX_OK),
		item (IMAPX_PARSE),
		item (IMAPX_PERMANENTFLAGS),
		item (IMAPX_PREAUTH),
		{ IMAPX_READ_ONLY, "READ-ONLY" },
		{ IMAPX_READ_WRITE, "READ-WRITE" },
		item (IMAPX_RECENT),
		{ IMAPX_RFC822_HEADER, "RFC822.HEADER" },
		{ IMAPX_RFC822_SIZE, "RFC822.SIZE" },
		{ IMAPX_RFC822_TEXT, "RFC822.TEXT" },
		item (IMAPX_STATUS),
		item (IMAPX_TRYCREATE),
		item (IMAPX_UID),
		item (IMAPX_UIDVALIDITY),
		item (IMAPX_UNSEEN),
		item (IMAPX_UIDNEXT),
		item (IMAPX_VANISHED),
		item (IMAPX_ALREADYEXISTS),
		item (IMAPX_AUTHENTICATIONFAILED),
		item (IMAPX_AUTHORIZATIONFAILED),
		item (IMAPX_CANNOT),
		item (IMAPX_CLIENTBUG),
		item (IMAPX_CONTACTADMIN),
		item (IMAPX_CORRUPTION),
		item (IMAPX_EXPIRED),
		item (IMAPX_EXPUNGEISSUED),
		item (IMAPX_INUSE),
		item (IMAPX_LIMIT),
		item (IMAPX_NONEXISTENT),
		item (IMAPX_NOPERM),
		item (IMAPX_OVERQUOTA),
		item (IMAPX_PRIVACYREQUIRED),
		item (IMAPX_SERVERBUG),
		item (IMAPX_UNAVAILABLE)
	};
	#undef item
	gint ii;

	g_warn_if_fail (G_N_ELEMENTS (values) == IMAPX_LAST_ID_VALUE - 1);

	for (ii = 0; ii < G_N_ELEMENTS (values); ii++) {
		const gchar *token;
		camel_imapx_id_t found_id;

		token = strchr (values[ii].str, '_');
		if (token)
			token++;
		else
			token = values[ii].str;

		found_id = imapx_tokenise (token, strlen (token));
		if (found_id == IMAPX_UNKNOWN)
			g_warning ("%s: Unknown token %d (%s) in enum, add it to camel-imapx-tokens.txt", G_STRFUNC, values[ii].id, values[ii].str);
		else if (found_id != values[ii].id)
			g_warning ("%s: Token '%s' expected id %d, but got %d", G_STRFUNC, values[ii].str, values[ii].id, found_id);
	}
}

#endif

/*
 * From rfc2060
 *
 * ATOM_CHAR       ::= <any CHAR except atom_specials>
 *
 * atom_specials   ::= "(" / ")" / "{" / SPACE / CTL / list_wildcards /
 *                     quoted_specials
 *
 * CHAR            ::= <any 7 - bit US - ASCII character except NUL,
 *                      0x01 - 0x7f>
 *
 * CTL             ::= <any ASCII control character and DEL,
 *                         0x00 - 0x1f, 0x7f>
 *
 * SPACE           ::= <ASCII SP, space, 0x20>
 *
 * list_wildcards  ::= "%" / "*"
 *
 * quoted_specials ::= <"> / "\"
 *
 * string          ::= quoted / literal
 *
 * literal         ::= "{" number "}" CRLF *CHAR8
 *                     ;; Number represents the number of CHAR8 octets
 *
 * quoted          ::= <"> *QUOTED_CHAR <">
 *
 * QUOTED_CHAR     ::= <any TEXT_CHAR except quoted_specials> /
 *                     "\" quoted_specials
 *
 * TEXT_CHAR       ::= <any CHAR except CR and LF>
 */

/*
 * ATOM = 1
 * SIMPLE? = 2
 * NOTID? = 4
 *
 * QSPECIAL = 8
 */

guchar imapx_specials[256] = {
/* 00 */0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 4, 0, 0,
/* 10 */0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
/* 20 */4, 1, 0, 1, 1, 0, 1, 1, 0, 0, 2, 7, 1, 1, 1, 1,
/* 30 */1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
/* 40 */7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
/* 50 */1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 0, 7, 1, 1,
/* 60 */1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
/* 70 */1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

#define list_wildcards "*%"
#define quoted_specials "\\\""
#define atom_specials "(){" list_wildcards quoted_specials /* + CTL */

/* special types for the tokeniser, come out as raw tokens */
#define token_specials "\n*()[]+"
#define notid_specials "\x20\r\n()[]"

void
imapx_utils_init (void)
{
	static gsize imapx_utils_initialized = 0;

	if (g_once_init_enter (&imapx_utils_initialized)) {
		gint i;
		guchar v;

		for (i = 0; i < 128; i++) {
			v = 0;
			if (i >= 1 && i <= 0x7f) {
				v |= IMAPX_TYPE_CHAR;
				if (i != 0x0a && i != 0x0d) {
					v |= IMAPX_TYPE_TEXT_CHAR;
					if (i != '"' && i != '\\')
						v |= IMAPX_TYPE_QUOTED_CHAR;
				}
				if (i> 0x20 && i <0x7f && strchr (atom_specials, i) == NULL)
					v |= IMAPX_TYPE_ATOM_CHAR;
				if (strchr (token_specials, i) != NULL)
					v |= IMAPX_TYPE_TOKEN_CHAR;
				if (strchr (notid_specials, i) != NULL)
					v |= IMAPX_TYPE_NOTID_CHAR;
			}

			imapx_specials[i] = v;
		}

		create_initial_capabilities_table ();
		camel_imapx_set_debug_flags ();

		#ifdef ENABLE_MAINTAINER_MODE
		imapx_verify_tokens_tab ();
		#endif

		g_once_init_leave (&imapx_utils_initialized, 1);
	}
}

guchar
imapx_is_mask (const gchar *p)
{
	guchar v = 0xff;

	while (*p) {
		v &= imapx_specials[((guchar) * p) & 0xff];
		p++;
	}

	return v;
}

gchar *
imapx_path_to_physical (const gchar *prefix,
                        const gchar *vpath)
{
	GString *out = g_string_new (prefix);
	const gchar *p = vpath;
	gchar c, *res;

	g_string_append_c (out, '/');
	p = vpath;
	while ((c = *p++)) {
		if (c == '/') {
			g_string_append (out, "/" SUBFOLDER_DIR_NAME "/");
			while (*p == '/')
				p++;
		} else
			g_string_append_c (out, c);
	}

	res = out->str;
	g_string_free (out, FALSE);

	return res;
}

gchar *
imapx_get_temp_uid (void)
{
	gchar *res;

	static gint counter = 0;
	G_LOCK_DEFINE_STATIC (lock);

	G_LOCK (lock);
	res = g_strdup_printf (
		"tempuid-%lx-%d",
		(gulong) time (NULL),
		counter++);
	G_UNLOCK (lock);

	return res;
}

gboolean
imapx_util_all_is_ascii (const gchar *str)
{
	gint ii;
	gboolean all_ascii = TRUE;

	g_return_val_if_fail (str != NULL, FALSE);

	for (ii = 0; str[ii] && all_ascii; ii++) {
		all_ascii = str[ii] > 0;
	}

	return all_ascii;
}

gssize
imapx_splice_with_progress (GOutputStream *output_stream,
			    GInputStream *input_stream,
			    goffset file_size,
			    GCancellable *cancellable,
			    GError **error)
{
	gssize n_read;
	gsize bytes_copied, n_written;
	gchar buffer[8192];
	goffset file_offset;
	gboolean res;

	g_return_val_if_fail (G_IS_OUTPUT_STREAM (output_stream), -1);
	g_return_val_if_fail (G_IS_INPUT_STREAM (input_stream), -1);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	file_offset = 0;
	bytes_copied = 0;
	res = TRUE;
	do {
		n_read = g_input_stream_read (input_stream, buffer, sizeof (buffer), cancellable, error);
		if (n_read == -1) {
			res = FALSE;
			break;
		}

		if (n_read == 0)
			break;

		if (!g_output_stream_write_all (output_stream, buffer, n_read, &n_written, cancellable, error) || n_written == -1) {
			res = FALSE;
			break;
		}

		file_offset += n_read;

		if (file_size > 0) {
			gdouble divd = (gdouble) file_offset / (gdouble) file_size;
			if (divd > 1.0)
				divd = 1.0;
			camel_operation_progress (cancellable, (gint) (100 * divd));
		}

		bytes_copied += n_written;
		if (bytes_copied > G_MAXSSIZE)
			bytes_copied = G_MAXSSIZE;
	} while (res);

	if (file_size > 0)
		camel_operation_progress (cancellable, -1);

	if (res)
		return bytes_copied;

	return -1;
}
