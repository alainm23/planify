/*
 * camel-imapx-store-summary.c
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
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <camel/camel.h>

#include "camel-imapx-utils.h"
#include "camel-imapx-store-summary.h"

#define d(...) camel_imapx_debug(debug, '?', __VA_ARGS__)

/* Version 0: Original IMAPX file format. */
#define CAMEL_IMAPX_STORE_SUMMARY_VERSION_0 (0)

/* Version 1: (3.10) Store the hierarchy separator. */
#define CAMEL_IMAPX_STORE_SUMMARY_VERSION_1 (1);

#define CAMEL_IMAPX_STORE_SUMMARY_VERSION (1)

G_DEFINE_TYPE (
	CamelIMAPXStoreSummary,
	camel_imapx_store_summary,
	CAMEL_TYPE_STORE_SUMMARY)

static gboolean
namespace_load (FILE *in)
{
	gchar *unused = NULL;
	gboolean success = FALSE;
	guint32 j;

	/* XXX This eats through the old namespace data for backward
	 *     compatibility.  Next time we bump the summary version,
	 *     delete all this cruft. */

	for (j = 0; j < 3; j++) {
		gint32 i, n = 0;

		if (camel_file_util_decode_fixed_int32 (in, &n) == -1)
			goto exit;

		for (i = 0; i < n; i++) {
			guint32 sep;

			if (camel_file_util_decode_string (in, &unused) == -1)
				goto exit;

			g_free (unused);
			unused = NULL;

			if (camel_file_util_decode_string (in, &unused) == -1)
				goto exit;

			g_free (unused);
			unused = NULL;

			if (camel_file_util_decode_uint32 (in, &sep) == -1)
				goto exit;
		}
	}

	success = TRUE;

exit:
	g_free (unused);

	return success;
}

static gint
imapx_store_summary_summary_header_load (CamelStoreSummary *summary,
                                         FILE *in)
{
	CamelStoreSummaryClass *store_summary_class;
	gint32 version, unused;

	store_summary_class =
		CAMEL_STORE_SUMMARY_CLASS (
		camel_imapx_store_summary_parent_class);

	/* Chain up to parent's summary_header_load() method. */
	if (store_summary_class->summary_header_load (summary, in) == -1)
		return -1;

	if (camel_file_util_decode_fixed_int32 (in, &version) == -1)
		return -1;

	if (version < CAMEL_IMAPX_STORE_SUMMARY_VERSION) {
		g_warning ("IMAPx: Unable to load store summary: Expected version (%d), got (%d)",
			CAMEL_IMAPX_STORE_SUMMARY_VERSION, version);
		return -1;
	}

	if (camel_file_util_decode_fixed_int32 (in, &unused) == -1)
		return -1;

	/* XXX This just eats old data that we no longer use. */
	if (!namespace_load (in))
		return -1;

	return 0;
}

static gint
imapx_store_summary_summary_header_save (CamelStoreSummary *summary,
                                         FILE *out)
{
	CamelStoreSummaryClass *store_summary_class;

	store_summary_class =
		CAMEL_STORE_SUMMARY_CLASS (
		camel_imapx_store_summary_parent_class);

	/* Chain up to parent's summary_header_save() method. */
	if (store_summary_class->summary_header_save (summary, out) == -1)
		return -1;

	/* always write as latest version */
	if (camel_file_util_encode_fixed_int32 (
		out, CAMEL_IMAPX_STORE_SUMMARY_VERSION) == -1)
		return -1;

	if (camel_file_util_encode_fixed_int32 (out, 0) == -1)
		return -1;

	/* XXX This just saves zero-count namespace placeholders for
	 *     backward compatibility.  Next time we bump the summary
	 *     version, delete all this cruft. */

	if (camel_file_util_encode_fixed_int32 (out, 0) == -1)
		return -1;

	if (camel_file_util_encode_fixed_int32 (out, 0) == -1)
		return -1;

	if (camel_file_util_encode_fixed_int32 (out, 0) == -1)
		return -1;

	return 0;
}

static CamelStoreInfo *
imapx_store_summary_store_info_load (CamelStoreSummary *summary,
                                     FILE *in)
{
	CamelStoreSummaryClass *store_summary_class;
	CamelStoreInfo *si;
	gchar *mailbox_name = NULL;
	gchar *separator = NULL;

	store_summary_class =
		CAMEL_STORE_SUMMARY_CLASS (
		camel_imapx_store_summary_parent_class);

	/* Chain up to parent's store_info_load() method. */
	si = store_summary_class->store_info_load (summary, in);
	if (si == NULL)
		return NULL;

	if (camel_file_util_decode_string (in, &separator) == -1) {
		camel_store_summary_info_unref (summary, si);
		return NULL;
	}

	if (camel_file_util_decode_string (in, &mailbox_name) == -1) {
		camel_store_summary_info_unref (summary, si);
		g_free (separator);
		return NULL;
	}

	camel_imapx_normalize_mailbox (mailbox_name, *separator);

	/* NB: this is done again for compatability */
	if (camel_imapx_mailbox_is_inbox (mailbox_name))
		si->flags |=
			CAMEL_FOLDER_SYSTEM |
			CAMEL_FOLDER_TYPE_INBOX;

	((CamelIMAPXStoreInfo *) si)->mailbox_name = mailbox_name;
	((CamelIMAPXStoreInfo *) si)->separator = *separator;

	g_free (separator);

	return si;
}

static gint
imapx_store_summary_store_info_save (CamelStoreSummary *summary,
                                     FILE *out,
                                     CamelStoreInfo *si)
{
	CamelStoreSummaryClass *store_summary_class;
	gchar separator[] = { '\0', '\0' };
	const gchar *mailbox_name;

	store_summary_class =
		CAMEL_STORE_SUMMARY_CLASS (
		camel_imapx_store_summary_parent_class);

	mailbox_name = ((CamelIMAPXStoreInfo *) si)->mailbox_name;
	separator[0] = ((CamelIMAPXStoreInfo *) si)->separator;

	/* Chain up to parent's store_info_save() method. */
	if (store_summary_class->store_info_save (summary, out, si) == -1)
		return -1;

	if (camel_file_util_encode_string (out, separator) == -1)
		return -1;

	if (camel_file_util_encode_string (out, mailbox_name) == -1)
		return -1;

	return 0;
}

static void
imapx_store_summary_store_info_free (CamelStoreSummary *summary,
                                     CamelStoreInfo *si)
{
	CamelStoreSummaryClass *store_summary_class;

	store_summary_class =
		CAMEL_STORE_SUMMARY_CLASS (
		camel_imapx_store_summary_parent_class);

	g_free (((CamelIMAPXStoreInfo *) si)->mailbox_name);

	/* Chain up to parent's store_info_free() method. */
	store_summary_class->store_info_free (summary, si);
}

static void
camel_imapx_store_summary_class_init (CamelIMAPXStoreSummaryClass *class)
{
	CamelStoreSummaryClass *store_summary_class;

	store_summary_class = CAMEL_STORE_SUMMARY_CLASS (class);
	store_summary_class->store_info_size = sizeof (CamelIMAPXStoreInfo);
	store_summary_class->summary_header_load =imapx_store_summary_summary_header_load;
	store_summary_class->summary_header_save = imapx_store_summary_summary_header_save;
	store_summary_class->store_info_load = imapx_store_summary_store_info_load;
	store_summary_class->store_info_save = imapx_store_summary_store_info_save;
	store_summary_class->store_info_free = imapx_store_summary_store_info_free;
}

static void
camel_imapx_store_summary_init (CamelIMAPXStoreSummary *summary)
{
}

/**
 * camel_imapx_store_summary_mailbox:
 * @summary: a #CamelStoreSummary
 * @mailbox_name: a mailbox name
 *
 * Retrieve a summary item by mailbox name.
 *
 * The returned #CamelIMAPXStoreInfo is referenced for thread-safety
 * and should be unreferenced with camel_store_summary_info_unref()
 * when finished with it.
 *
 * Returns: a #CamelIMAPXStoreInfo, or %NULL
 **/
CamelIMAPXStoreInfo *
camel_imapx_store_summary_mailbox (CamelStoreSummary *summary,
                                   const gchar *mailbox_name)
{
	CamelStoreInfo *match = NULL;
	GPtrArray *array;
	gboolean find_inbox;
	guint ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE_SUMMARY (summary), NULL);
	g_return_val_if_fail (mailbox_name != NULL, NULL);

	find_inbox = camel_imapx_mailbox_is_inbox (mailbox_name);

	array = camel_store_summary_array (summary);

	for (ii = 0; ii < array->len; ii++) {
		CamelIMAPXStoreInfo *info;
		gboolean is_inbox;

		info = g_ptr_array_index (array, ii);
		is_inbox = camel_imapx_mailbox_is_inbox (info->mailbox_name);

		if (find_inbox && is_inbox) {
			match = camel_store_summary_info_ref (
				summary, (CamelStoreInfo *) info);
			break;
		}

		if (g_str_equal (info->mailbox_name, mailbox_name)) {
			match = camel_store_summary_info_ref (
				summary, (CamelStoreInfo *) info);
			break;
		}
	}

	camel_store_summary_array_free (summary, array);

	return (CamelIMAPXStoreInfo *) match;
}

/* The returned CamelIMAPXStoreInfo is referenced, unref it with
   camel_store_summary_info_unref() when no longer needed */
CamelIMAPXStoreInfo *
camel_imapx_store_summary_add_from_mailbox (CamelStoreSummary *summary,
                                            CamelIMAPXMailbox *mailbox)
{
	CamelIMAPXStoreInfo *info;
	const gchar *mailbox_name;
	gchar *folder_path;
	gchar separator;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	mailbox_name = camel_imapx_mailbox_get_name (mailbox);
	separator = camel_imapx_mailbox_get_separator (mailbox);

	info = camel_imapx_store_summary_mailbox (summary, mailbox_name);
	if (info != NULL)
		return info;

	folder_path = camel_imapx_mailbox_to_folder_path (
		mailbox_name, separator);

	info = (CamelIMAPXStoreInfo *)
		camel_store_summary_add_from_path (summary, folder_path);

	g_free (folder_path);

	g_return_val_if_fail (info != NULL, NULL);

	camel_store_summary_info_ref (summary, (CamelStoreInfo *) info);

	info->mailbox_name = g_strdup (mailbox_name);
	info->separator = separator;

	if (camel_imapx_mailbox_is_inbox (mailbox_name))
		info->info.flags |=
			CAMEL_FOLDER_SYSTEM |
			CAMEL_FOLDER_TYPE_INBOX;

	return info;
}

