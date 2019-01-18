/*
 * camel-imapx-search.c
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

#include "camel-imapx-search.h"

#include <string.h>
#include <camel/camel.h>
#include <camel/camel-search-private.h>

#include "camel-imapx-folder.h"

#define CAMEL_IMAPX_SEARCH_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_SEARCH, CamelIMAPXSearchPrivate))

struct _CamelIMAPXSearchPrivate {
	GWeakRef imapx_store;
	gint *local_data_search; /* not NULL, if testing whether all used headers are all locally available */

	GCancellable *cancellable; /* not referenced */
	GError **error; /* not referenced */
};

enum {
	PROP_0,
	PROP_STORE
};

G_DEFINE_TYPE (
	CamelIMAPXSearch,
	camel_imapx_search,
	CAMEL_TYPE_FOLDER_SEARCH)

static void
imapx_search_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			camel_imapx_search_set_store (
				CAMEL_IMAPX_SEARCH (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_search_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STORE:
			g_value_take_object (
				value,
				camel_imapx_search_ref_store (
				CAMEL_IMAPX_SEARCH (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_search_dispose (GObject *object)
{
	CamelIMAPXSearchPrivate *priv;

	priv = CAMEL_IMAPX_SEARCH_GET_PRIVATE (object);

	g_weak_ref_set (&priv->imapx_store, NULL);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_search_parent_class)->dispose (object);
}

static void
imapx_search_finalize (GObject *object)
{
	CamelIMAPXSearchPrivate *priv;

	priv = CAMEL_IMAPX_SEARCH_GET_PRIVATE (object);

	g_weak_ref_clear (&priv->imapx_store);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_search_parent_class)->finalize (object);
}

static CamelSExpResult *
imapx_search_result_match_all (CamelSExp *sexp,
                               CamelFolderSearch *search)
{
	CamelSExpResult *result;

	g_return_val_if_fail (search != NULL, NULL);

	if (camel_folder_search_get_current_message_info (search)) {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);
		result->value.boolean = TRUE;
	} else {
		GPtrArray *summary;
		gint ii;

		summary = camel_folder_search_get_summary (search);

		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_ARRAY_PTR);
		result->value.ptrarray = g_ptr_array_new ();

		for (ii = 0; summary && ii < summary->len; ii++) {
			g_ptr_array_add (
				result->value.ptrarray,
				(gpointer) summary->pdata[ii]);
		}
	}

	return result;
}

static CamelSExpResult *
imapx_search_result_match_none (CamelSExp *sexp,
                                CamelFolderSearch *search)
{
	CamelSExpResult *result;

	g_return_val_if_fail (search != NULL, NULL);

	if (camel_folder_search_get_current_message_info (search)) {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);
		result->value.boolean = FALSE;
	} else {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_ARRAY_PTR);
		result->value.ptrarray = g_ptr_array_new ();
	}

	return result;
}

static CamelSExpResult *
imapx_search_process_criteria (CamelSExp *sexp,
                               CamelFolderSearch *search,
                               CamelIMAPXStore *imapx_store,
                               const GString *criteria_prefix,
			       const gchar *search_key,
			       const GPtrArray *words,
                               const gchar *from_function)
{
	CamelSExpResult *result;
	CamelIMAPXSearch *imapx_search = CAMEL_IMAPX_SEARCH (search);
	CamelIMAPXMailbox *mailbox;
	GPtrArray *uids = NULL;
	GError *local_error = NULL;

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (camel_folder_search_get_folder (search)), imapx_search->priv->cancellable, &local_error);

	/* Sanity check. */
	g_return_val_if_fail (
		((mailbox != NULL) && (local_error == NULL)) ||
		((mailbox == NULL) && (local_error != NULL)), NULL);

	if (mailbox != NULL) {
		CamelIMAPXConnManager *conn_man;

		conn_man = camel_imapx_store_get_conn_manager (imapx_store);
		uids = camel_imapx_conn_manager_uid_search_sync (conn_man, mailbox, criteria_prefix->str, search_key,
			words ? (const gchar * const *) words->pdata : NULL, imapx_search->priv->cancellable, &local_error);

		g_object_unref (mailbox);
	}

	/* Sanity check. */
	g_return_val_if_fail (
		((uids != NULL) && (local_error == NULL)) ||
		((uids == NULL) && (local_error != NULL)), NULL);

	if (local_error != NULL) {
		g_propagate_error (imapx_search->priv->error, local_error);

		/* Make like we've got an empty result */
		uids = g_ptr_array_new ();
	}

	if (camel_folder_search_get_current_message_info (search)) {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_BOOL);
		result->value.boolean = (uids && uids->len > 0);
	} else {
		result = camel_sexp_result_new (sexp, CAMEL_SEXP_RES_ARRAY_PTR);
		result->value.ptrarray = g_ptr_array_ref (uids);
	}

	g_ptr_array_unref (uids);

	return result;
}

static CamelSExpResult *
imapx_search_match_all (CamelSExp *sexp,
                        gint argc,
                        CamelSExpTerm **argv,
                        CamelFolderSearch *search)
{
	CamelIMAPXSearch *imapx_search = CAMEL_IMAPX_SEARCH (search);
	CamelIMAPXStore *imapx_store;
	CamelSExpResult *result;
	GPtrArray *summary;
	gint local_data_search = 0, *prev_local_data_search, ii;

	if (argc != 1)
		return imapx_search_result_match_none (sexp, search);

	imapx_store = camel_imapx_search_ref_store (CAMEL_IMAPX_SEARCH (search));
	if (!imapx_store || camel_folder_search_get_current_message_info (search) || !camel_folder_search_get_summary (search)) {
		g_clear_object (&imapx_store);

		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			match_all (sexp, argc, argv, search);
	}

	/* First try to see whether all used headers are available locally - if
	 * they are, then do not use server-side filtering at all. */
	prev_local_data_search = imapx_search->priv->local_data_search;
	imapx_search->priv->local_data_search = &local_data_search;

	summary = camel_folder_search_get_current_summary (search);

	if (!CAMEL_IS_VEE_FOLDER (camel_folder_search_get_folder (search))) {
		camel_folder_summary_prepare_fetch_all (camel_folder_get_folder_summary (camel_folder_search_get_folder (search)), NULL);
	}

	for (ii = 0; ii < summary->len; ii++) {
		camel_folder_search_take_current_message_info (search, camel_folder_summary_get (camel_folder_get_folder_summary (camel_folder_search_get_folder (search)), summary->pdata[ii]));
		if (camel_folder_search_get_current_message_info (search)) {
			result = camel_sexp_term_eval (sexp, argv[0]);
			camel_sexp_result_free (sexp, result);
			camel_folder_search_set_current_message_info (search, NULL);
			break;
		}
	}
	imapx_search->priv->local_data_search = prev_local_data_search;

	if (local_data_search >= 0) {
		g_clear_object (&imapx_store);

		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			match_all (sexp, argc, argv, search);
	}

	/* let's change the requirements a bit, the parent class expects as a result boolean,
	 * but here is expected GPtrArray of matched UIDs */
	result = camel_sexp_term_eval (sexp, argv[0]);

	g_object_unref (imapx_store);

	g_return_val_if_fail (result != NULL, result);
	g_return_val_if_fail (result->type == CAMEL_SEXP_RES_ARRAY_PTR, result);

	return result;
}

static GPtrArray *
imapx_search_gather_words (CamelSExpResult **argv,
			   gint from_index,
			   gint argc)
{
	GPtrArray *ptrs;
	GHashTable *words_hash;
	GHashTableIter iter;
	gpointer key, value;
	gint ii, jj;

	g_return_val_if_fail (argv != 0, NULL);

	words_hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

	for (ii = from_index; ii < argc; ii++) {
		struct _camel_search_words *words;

		if (argv[ii]->type != CAMEL_SEXP_RES_STRING)
			continue;

		/* Handle multiple search words within a single term. */
		words = camel_search_words_split ((const guchar *) argv[ii]->value.string);

		for (jj = 0; jj < words->len; jj++) {
			const gchar *word = words->words[jj]->word;

			g_hash_table_insert (words_hash, g_strdup (word), NULL);
		}

		camel_search_words_free (words);
	}

	ptrs = g_ptr_array_new_full (g_hash_table_size (words_hash), g_free);

	g_hash_table_iter_init (&iter, words_hash);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		g_ptr_array_add (ptrs, g_strdup (key));
	}

	if (ptrs->len == 0) {
		g_ptr_array_free (ptrs, TRUE);
		ptrs = NULL;
	} else {
		g_ptr_array_add (ptrs, NULL);
	}

	g_hash_table_destroy (words_hash);

	return ptrs;
}

static CamelSExpResult *
imapx_search_body_contains (CamelSExp *sexp,
                            gint argc,
                            CamelSExpResult **argv,
                            CamelFolderSearch *search)
{
	CamelIMAPXSearch *imapx_search = CAMEL_IMAPX_SEARCH (search);
	CamelIMAPXStore *imapx_store;
	CamelSExpResult *result;
	GString *criteria;
	GPtrArray *words;
	gboolean is_gmail;

	/* Always do body-search server-side */
	if (imapx_search->priv->local_data_search) {
		*imapx_search->priv->local_data_search = -1;
		return imapx_search_result_match_none (sexp, search);
	}

	/* Match everything if argv = [""] */
	if (argc == 1 && argv[0]->value.string[0] == '\0')
		return imapx_search_result_match_all (sexp, search);

	/* Match nothing if empty argv or empty summary. */
	if (argc == 0 || camel_folder_search_get_summary_empty (search))
		return imapx_search_result_match_none (sexp, search);

	imapx_store = camel_imapx_search_ref_store (CAMEL_IMAPX_SEARCH (search));

	/* This will be NULL if we're offline. Search from cache. */
	if (imapx_store == NULL) {
		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			body_contains (sexp, argc, argv, search);
	}

	/* Build the IMAP search criteria. */

	criteria = g_string_sized_new (128);

	if (camel_folder_search_get_current_message_info (search)) {
		const gchar *uid;

		/* Limit the search to a single UID. */
		uid = camel_message_info_get_uid (camel_folder_search_get_current_message_info (search));
		g_string_append_printf (criteria, "UID %s", uid);
	}

	words = imapx_search_gather_words (argv, 0, argc);

	result = imapx_search_process_criteria (sexp, search, imapx_store, criteria, "BODY", words, G_STRFUNC);

	is_gmail = camel_imapx_store_is_gmail_server (imapx_store);

	g_string_free (criteria, TRUE);
	g_ptr_array_free (words, TRUE);
	g_object_unref (imapx_store);

	if (is_gmail && result && (result->type == CAMEL_SEXP_RES_ARRAY_PTR || (result->type == CAMEL_SEXP_RES_BOOL && !result->value.boolean))) {
		/* Gmail returns BODY matches on whole words only, which is not it should be,
		   thus try also locally cached messages to provide any better results. */
		gboolean was_only_cached_messages;
		CamelSExpResult *cached_result;

		was_only_cached_messages = camel_folder_search_get_only_cached_messages (search);
		camel_folder_search_set_only_cached_messages (search, TRUE);

		cached_result = CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->body_contains (sexp, argc, argv, search);

		camel_folder_search_set_only_cached_messages (search, was_only_cached_messages);

		if (cached_result && cached_result->type == result->type) {
			if (result->type == CAMEL_SEXP_RES_BOOL) {
				result->value.boolean = cached_result->value.boolean;
			} else {
				/* Merge the two UID arrays */
				GHashTable *merge;
				GHashTableIter iter;
				GPtrArray *array;
				gpointer key;
				guint ii;

				/* UID-s are strings from the string pool, thus can be compared directly */
				merge = g_hash_table_new (g_direct_hash, g_direct_equal);

				array = result->value.ptrarray;
				for (ii = 0; array && ii < array->len; ii++) {
					gpointer uid = g_ptr_array_index (array, ii);

					if (uid)
						g_hash_table_insert (merge, uid, NULL);
				}

				array = cached_result->value.ptrarray;
				for (ii = 0; array && ii < array->len; ii++) {
					gpointer uid = g_ptr_array_index (array, ii);

					if (uid)
						g_hash_table_insert (merge, uid, NULL);
				}

				array = g_ptr_array_new_full (g_hash_table_size (merge), (GDestroyNotify) camel_pstring_free);

				g_hash_table_iter_init (&iter, merge);
				while (g_hash_table_iter_next (&iter, &key, NULL)) {
					g_ptr_array_add (array, (gpointer) camel_pstring_strdup (key));
				}

				g_hash_table_destroy (merge);

				g_ptr_array_unref (result->value.ptrarray);

				result->value.ptrarray = array;
			}
		}

		camel_sexp_result_free (sexp, cached_result);
	}

	return result;
}

static gboolean
imapx_search_is_header_from_summary (const gchar *header_name)
{
	return  g_ascii_strcasecmp (header_name, "From") == 0 ||
		g_ascii_strcasecmp (header_name, "To") == 0 ||
		g_ascii_strcasecmp (header_name, "CC") == 0 ||
		g_ascii_strcasecmp (header_name, "Subject") == 0;
}

static CamelSExpResult *
imapx_search_header_contains (CamelSExp *sexp,
                              gint argc,
                              CamelSExpResult **argv,
                              CamelFolderSearch *search)
{
	CamelIMAPXSearch *imapx_search = CAMEL_IMAPX_SEARCH (search);
	CamelIMAPXStore *imapx_store;
	CamelSExpResult *result;
	const gchar *headername, *command = NULL;
	GString *criteria;
	gchar *search_key = NULL;
	GPtrArray *words;

	/* Match nothing if empty argv or empty summary. */
	if (argc <= 1 ||
	    argv[0]->type != CAMEL_SEXP_RES_STRING ||
	    camel_folder_search_get_summary_empty (search))
		return imapx_search_result_match_none (sexp, search);

	headername = argv[0]->value.string;

	if (imapx_search_is_header_from_summary (headername)) {
		if (imapx_search->priv->local_data_search) {
			if (*imapx_search->priv->local_data_search >= 0)
				*imapx_search->priv->local_data_search = (*imapx_search->priv->local_data_search) + 1;
			return imapx_search_result_match_all (sexp, search);
		}

		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			header_contains (sexp, argc, argv, search);
	} else if (imapx_search->priv->local_data_search) {
		*imapx_search->priv->local_data_search = -1;
		return imapx_search_result_match_none (sexp, search);
	}

	imapx_store = camel_imapx_search_ref_store (CAMEL_IMAPX_SEARCH (search));

	/* This will be NULL if we're offline. Search from cache. */
	if (imapx_store == NULL) {
		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			header_contains (sexp, argc, argv, search);
	}

	/* Build the IMAP search criteria. */

	criteria = g_string_sized_new (128);

	if (camel_folder_search_get_current_message_info (search)) {
		const gchar *uid;

		/* Limit the search to a single UID. */
		uid = camel_message_info_get_uid (camel_folder_search_get_current_message_info (search));
		g_string_append_printf (criteria, "UID %s", uid);
	}

	if (g_ascii_strcasecmp (headername, "From") == 0)
		command = "FROM";
	else if (g_ascii_strcasecmp (headername, "To") == 0)
		command = "TO";
	else if (g_ascii_strcasecmp (headername, "CC") == 0)
		command = "CC";
	else if (g_ascii_strcasecmp (headername, "Bcc") == 0)
		command = "BCC";
	else if (g_ascii_strcasecmp (headername, "Subject") == 0)
		command = "SUBJECT";

	words = imapx_search_gather_words (argv, 1, argc);

	if (!command)
		search_key = g_strdup_printf ("HEADER \"%s\"", headername);

	result = imapx_search_process_criteria (sexp, search, imapx_store, criteria, command ? command : search_key, words, G_STRFUNC);

	g_string_free (criteria, TRUE);
	g_ptr_array_free (words, TRUE);
	g_object_unref (imapx_store);
	g_free (search_key);

	return result;
}

static CamelSExpResult *
imapx_search_header_exists (CamelSExp *sexp,
                            gint argc,
                            CamelSExpResult **argv,
                            CamelFolderSearch *search)
{
	CamelIMAPXSearch *imapx_search = CAMEL_IMAPX_SEARCH (search);
	CamelIMAPXStore *imapx_store;
	CamelSExpResult *result;
	GString *criteria;
	gint ii;

	/* Match nothing if empty argv or empty summary. */
	if (argc == 0 || camel_folder_search_get_summary_empty (search))
		return imapx_search_result_match_none (sexp, search);

	/* Check if asking for locally stored headers only */
	for (ii = 0; ii < argc; ii++) {
		if (argv[ii]->type != CAMEL_SEXP_RES_STRING)
			continue;

		if (!imapx_search_is_header_from_summary (argv[ii]->value.string))
			break;
	}

	/* All headers are from summary */
	if (ii == argc) {
		if (imapx_search->priv->local_data_search) {
			if (*imapx_search->priv->local_data_search >= 0)
				*imapx_search->priv->local_data_search = (*imapx_search->priv->local_data_search) + 1;

			return imapx_search_result_match_all (sexp, search);
		}

		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			header_exists (sexp, argc, argv, search);
	} else if (imapx_search->priv->local_data_search) {
		*imapx_search->priv->local_data_search = -1;
		return imapx_search_result_match_none (sexp, search);
	}

	imapx_store = camel_imapx_search_ref_store (CAMEL_IMAPX_SEARCH (search));

	/* This will be NULL if we're offline. Search from cache. */
	if (imapx_store == NULL) {
		/* Chain up to parent's method. */
		return CAMEL_FOLDER_SEARCH_CLASS (camel_imapx_search_parent_class)->
			header_exists (sexp, argc, argv, search);
	}

	/* Build the IMAP search criteria. */

	criteria = g_string_sized_new (128);

	if (camel_folder_search_get_current_message_info (search)) {
		const gchar *uid;

		/* Limit the search to a single UID. */
		uid = camel_message_info_get_uid (camel_folder_search_get_current_message_info (search));
		g_string_append_printf (criteria, "UID %s", uid);
	}

	for (ii = 0; ii < argc; ii++) {
		const gchar *headername;

		if (argv[ii]->type != CAMEL_SEXP_RES_STRING)
			continue;

		headername = argv[ii]->value.string;

		if (criteria->len > 0)
			g_string_append_c (criteria, ' ');

		g_string_append_printf (criteria, "HEADER \"%s\" \"\"", headername);
	}

	result = imapx_search_process_criteria (sexp, search, imapx_store, criteria, NULL, NULL, G_STRFUNC);

	g_string_free (criteria, TRUE);
	g_object_unref (imapx_store);

	return result;
}

static void
camel_imapx_search_class_init (CamelIMAPXSearchClass *class)
{
	GObjectClass *object_class;
	CamelFolderSearchClass *search_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXSearchPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_search_set_property;
	object_class->get_property = imapx_search_get_property;
	object_class->dispose = imapx_search_dispose;
	object_class->finalize = imapx_search_finalize;

	search_class = CAMEL_FOLDER_SEARCH_CLASS (class);
	search_class->match_all = imapx_search_match_all;
	search_class->body_contains = imapx_search_body_contains;
	search_class->header_contains = imapx_search_header_contains;
	search_class->header_exists = imapx_search_header_exists;

	g_object_class_install_property (
		object_class,
		PROP_STORE,
		g_param_spec_object (
			"store",
			"IMAPX Store",
			"IMAPX Store for server-side searches",
			CAMEL_TYPE_IMAPX_STORE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_imapx_search_init (CamelIMAPXSearch *search)
{
	search->priv = CAMEL_IMAPX_SEARCH_GET_PRIVATE (search);
	search->priv->local_data_search = NULL;

	g_weak_ref_init (&search->priv->imapx_store, NULL);
}

/**
 * camel_imapx_search_new:
 * @imapx_store: a #CamelIMAPXStore to which the search belongs
 *
 * Returns a new #CamelIMAPXSearch instance.
 *
 * Returns: a new #CamelIMAPXSearch
 *
 * Since: 3.8
 **/
CamelFolderSearch *
camel_imapx_search_new (CamelIMAPXStore *imapx_store)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), NULL);

	return g_object_new (
		CAMEL_TYPE_IMAPX_SEARCH,
		"store", imapx_store,
		NULL);
}

/**
 * camel_imapx_search_ref_store:
 * @search: a #CamelIMAPXSearch
 *
 * Returns a #CamelIMAPXStore to use for server-side searches,
 * or %NULL when the store is offline.
 *
 * The returned #CamelIMAPXStore is referenced for thread-safety and
 * must be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXStore, or %NULL
 *
 * Since: 3.8
 **/
CamelIMAPXStore *
camel_imapx_search_ref_store (CamelIMAPXSearch *search)
{
	CamelIMAPXStore *imapx_store;

	g_return_val_if_fail (CAMEL_IS_IMAPX_SEARCH (search), NULL);

	imapx_store = g_weak_ref_get (&search->priv->imapx_store);

	if (imapx_store && !camel_offline_store_get_online (CAMEL_OFFLINE_STORE (imapx_store)))
		g_clear_object (&imapx_store);

	return imapx_store;
}

/**
 * camel_imapx_search_set_store:
 * @search: a #CamelIMAPXSearch
 * @imapx_store: a #CamelIMAPXStore, or %NULL
 *
 * Sets a #CamelIMAPXStore to use for server-side searches. Generally
 * this is set for the duration of a single search when online, and then
 * reset to %NULL.
 *
 * Since: 3.8
 **/
void
camel_imapx_search_set_store (CamelIMAPXSearch *search,
			      CamelIMAPXStore *imapx_store)
{
	g_return_if_fail (CAMEL_IS_IMAPX_SEARCH (search));

	if (imapx_store != NULL)
		g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));

	g_weak_ref_set (&search->priv->imapx_store, imapx_store);

	g_object_notify (G_OBJECT (search), "store");
}

/**
 * camel_imapx_search_set_cancellable_and_error:
 * @search: a #CamelIMAPXSearch
 * @cancellable: a #GCancellable, or %NULL
 * @error: a #GError, or %NULL
 *
 * Sets @cancellable and @error to use for server-side searches. This way
 * the search can return accurate errors and be eventually cancelled by
 * a user.
 *
 * Note: The caller is responsible to keep alive both @cancellable and @error
 * for the whole run of the search and reset them both to NULL after
 * the search is finished.
 *
 * Since: 3.16
 **/
void
camel_imapx_search_set_cancellable_and_error (CamelIMAPXSearch *search,
					      GCancellable *cancellable,
					      GError **error)
{
	g_return_if_fail (CAMEL_IS_IMAPX_SEARCH (search));

	if (cancellable)
		g_return_if_fail (G_IS_CANCELLABLE (cancellable));

	search->priv->cancellable = cancellable;
	search->priv->error = error;
}
