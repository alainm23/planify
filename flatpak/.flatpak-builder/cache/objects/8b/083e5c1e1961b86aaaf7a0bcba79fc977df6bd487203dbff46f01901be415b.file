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
 * Authors: Chris Toshok <toshok@ximian.com>
 */

/**
 * SECTION: e-book-backend-summary
 * @include: libedata-book/libedata-book.h
 * @short_description: A utility for storing contact data and searching for contacts
 *
 * The #EBookBackendSummary is deprecated, use #EBookSqlite instead.
 */
#include "evolution-data-server-config.h"

#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <utime.h>
#include <errno.h>

#include <glib/gstdio.h>

#include "e-book-backend-summary.h"

#define E_BOOK_BACKEND_SUMMARY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_BACKEND_SUMMARY, EBookBackendSummaryPrivate))

G_DEFINE_TYPE (EBookBackendSummary, e_book_backend_summary, G_TYPE_OBJECT)

struct _EBookBackendSummaryPrivate {
	gchar *summary_path;
	FILE *fp;
	guint32 file_version;
	time_t mtime;
	gboolean upgraded;
	gboolean dirty;
	gint flush_timeout_millis;
	gint flush_timeout;
	GPtrArray *items;
	GHashTable *id_to_item;
	guint32 num_items; /* used only for loading */
#ifdef SUMMARY_STATS
	gint size;
#endif
};

typedef struct {
	gchar *id;
	gchar *nickname;
	gchar *full_name;
	gchar *given_name;
	gchar *surname;
	gchar *file_as;
	gchar *email_1;
	gchar *email_2;
	gchar *email_3;
	gchar *email_4;
	gboolean wants_html;
	gboolean wants_html_set;
	gboolean list;
	gboolean list_show_addresses;
} EBookBackendSummaryItem;

typedef struct {
	/* these lengths do *not* including the terminating \0, as
	 * it's not stored on disk. */
	guint16 id_len;
	guint16 nickname_len;
	guint16 full_name_len; /* version 3.0 field */
	guint16 given_name_len;
	guint16 surname_len;
	guint16 file_as_len;
	guint16 email_1_len;
	guint16 email_2_len;
	guint16 email_3_len;
	guint16 email_4_len;
	guint8  wants_html;
	guint8  wants_html_set;
	guint8  list;
	guint8  list_show_addresses;
} EBookBackendSummaryDiskItem;

typedef struct {
	guint32 file_version;
	guint32 num_items;
	guint32 summary_mtime; /* version 2.0 field */
} EBookBackendSummaryHeader;

#define PAS_SUMMARY_MAGIC "PAS-SUMMARY"
#define PAS_SUMMARY_MAGIC_LEN 11

#define PAS_SUMMARY_FILE_VERSION_1_0 1000
#define PAS_SUMMARY_FILE_VERSION_2_0 2000
#define PAS_SUMMARY_FILE_VERSION_3_0 3000
#define PAS_SUMMARY_FILE_VERSION_4_0 4000
#define PAS_SUMMARY_FILE_VERSION_5_0 5000

#define PAS_SUMMARY_FILE_VERSION PAS_SUMMARY_FILE_VERSION_5_0

static void
free_summary_item (EBookBackendSummaryItem *item)
{
	g_free (item->id);
	g_free (item->nickname);
	g_free (item->full_name);
	g_free (item->given_name);
	g_free (item->surname);
	g_free (item->file_as);
	g_free (item->email_1);
	g_free (item->email_2);
	g_free (item->email_3);
	g_free (item->email_4);
	g_free (item);
}

static void
clear_items (EBookBackendSummary *summary)
{
	gint i;
	gint num = summary->priv->items->len;
	for (i = 0; i < num; i++) {
		EBookBackendSummaryItem *item = g_ptr_array_remove_index_fast (summary->priv->items, 0);
		if (item) {
			g_hash_table_remove (summary->priv->id_to_item, item->id);
			free_summary_item (item);
		}
	}
}

/**
 * e_book_backend_summary_new:
 * @summary_path: a local file system path
 * @flush_timeout_millis: a flush interval, in milliseconds
 *
 * Creates an #EBookBackendSummary object without loading it
 * or otherwise affecting the file. @flush_timeout_millis
 * specifies how much time should elapse, at a minimum, from
 * the summary is changed until it is flushed to disk.
 *
 * Returns: A new #EBookBackendSummary.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
EBookBackendSummary *
e_book_backend_summary_new (const gchar *summary_path,
                            gint flush_timeout_millis)
{
	EBookBackendSummary *summary = g_object_new (E_TYPE_BOOK_BACKEND_SUMMARY, NULL);

	summary->priv->summary_path = g_strdup (summary_path);
	summary->priv->flush_timeout_millis = flush_timeout_millis;
	summary->priv->file_version = PAS_SUMMARY_FILE_VERSION_4_0;

	return summary;
}

static void
e_book_backend_summary_finalize (GObject *object)
{
	EBookBackendSummaryPrivate *priv;

	priv = E_BOOK_BACKEND_SUMMARY_GET_PRIVATE (object);

	if (priv->fp)
		fclose (priv->fp);
	if (priv->dirty)
		e_book_backend_summary_save (E_BOOK_BACKEND_SUMMARY (object));
	else
		utime (priv->summary_path, NULL);

	if (priv->flush_timeout)
		g_source_remove (priv->flush_timeout);

	g_free (priv->summary_path);
	clear_items (E_BOOK_BACKEND_SUMMARY (object));
	g_ptr_array_free (priv->items, TRUE);

	g_hash_table_destroy (priv->id_to_item);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_backend_summary_parent_class)->finalize (object);
}

static void
e_book_backend_summary_class_init (EBookBackendSummaryClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBookBackendSummaryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = e_book_backend_summary_finalize;
}

static void
e_book_backend_summary_init (EBookBackendSummary *summary)
{
	summary->priv = E_BOOK_BACKEND_SUMMARY_GET_PRIVATE (summary);

	summary->priv->items = g_ptr_array_new ();
	summary->priv->id_to_item = g_hash_table_new (g_str_hash, g_str_equal);
}


static gboolean
e_book_backend_summary_check_magic (EBookBackendSummary *summary,
                                    FILE *fp)
{
	gchar buf[PAS_SUMMARY_MAGIC_LEN + 1];
	gint rv;

	memset (buf, 0, sizeof (buf));

	rv = fread (buf, PAS_SUMMARY_MAGIC_LEN, 1, fp);
	if (rv != 1)
		return FALSE;
	if (strcmp (buf, PAS_SUMMARY_MAGIC))
		return FALSE;

	return TRUE;
}

static gboolean
e_book_backend_summary_load_header (EBookBackendSummary *summary,
                                    FILE *fp,
                                    EBookBackendSummaryHeader *header)
{
	gint rv;

	rv = fread (&header->file_version, sizeof (header->file_version), 1, fp);
	if (rv != 1)
		return FALSE;

	header->file_version = g_ntohl (header->file_version);

	if (header->file_version < PAS_SUMMARY_FILE_VERSION) {
		return FALSE; /* this will cause the entire summary to be rebuilt */
	}

	rv = fread (&header->num_items, sizeof (header->num_items), 1, fp);
	if (rv != 1)
		return FALSE;

	header->num_items = g_ntohl (header->num_items);

	rv = fread (&header->summary_mtime, sizeof (header->summary_mtime), 1, fp);
	if (rv != 1)
		return FALSE;
	header->summary_mtime = g_ntohl (header->summary_mtime);

	return TRUE;
}

static gchar *
read_string (FILE *fp,
             gsize len)
{
	gchar *buf;
	size_t rv;

	/* Avoid overflow for the nul byte. */
	if (len == G_MAXSIZE)
		return NULL;

	buf = g_new0 (char, len + 1);

	rv = fread (buf, sizeof (gchar), len, fp);
	if (rv != len) {
		g_free (buf);
		return NULL;
	}

	/* Validate the string as UTF-8. */
	if (!g_utf8_validate (buf, rv, NULL)) {
		g_free (buf);
		return NULL;
	}

	return buf;
}

static gboolean
e_book_backend_summary_load_item (EBookBackendSummary *summary,
                                  EBookBackendSummaryItem **new_item)
{
	EBookBackendSummaryItem *item;
	gchar *buf;
	FILE *fp = summary->priv->fp;

	if (summary->priv->file_version >= PAS_SUMMARY_FILE_VERSION_4_0) {
		EBookBackendSummaryDiskItem disk_item;
		gint rv = fread (&disk_item, sizeof (disk_item), 1, fp);
		if (rv != 1)
			return FALSE;

		disk_item.id_len = g_ntohs (disk_item.id_len);
		disk_item.nickname_len = g_ntohs (disk_item.nickname_len);
		disk_item.full_name_len = g_ntohs (disk_item.full_name_len);
		disk_item.given_name_len = g_ntohs (disk_item.given_name_len);
		disk_item.surname_len = g_ntohs (disk_item.surname_len);
		disk_item.file_as_len = g_ntohs (disk_item.file_as_len);
		disk_item.email_1_len = g_ntohs (disk_item.email_1_len);
		disk_item.email_2_len = g_ntohs (disk_item.email_2_len);
		disk_item.email_3_len = g_ntohs (disk_item.email_3_len);
		disk_item.email_4_len = g_ntohs (disk_item.email_4_len);

		item = g_new0 (EBookBackendSummaryItem, 1);

		item->wants_html = disk_item.wants_html;
		item->wants_html_set = disk_item.wants_html_set;
		item->list = disk_item.list;
		item->list_show_addresses = disk_item.list_show_addresses;

		if (disk_item.id_len) {
			buf = read_string (fp, disk_item.id_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->id = buf;
		}

		if (disk_item.nickname_len) {
			buf = read_string (fp, disk_item.nickname_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->nickname = buf;
		}

		if (disk_item.full_name_len) {
			buf = read_string (fp, disk_item.full_name_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->full_name = buf;
		}

		if (disk_item.given_name_len) {
			buf = read_string (fp, disk_item.given_name_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->given_name = buf;
		}

		if (disk_item.surname_len) {
			buf = read_string (fp, disk_item.surname_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->surname = buf;
		}

		if (disk_item.file_as_len) {
			buf = read_string (fp, disk_item.file_as_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->file_as = buf;
		}

		if (disk_item.email_1_len) {
			buf = read_string (fp, disk_item.email_1_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->email_1 = buf;
		}

		if (disk_item.email_2_len) {
			buf = read_string (fp, disk_item.email_2_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->email_2 = buf;
		}

		if (disk_item.email_3_len) {
			buf = read_string (fp, disk_item.email_3_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->email_3 = buf;
		}

		if (disk_item.email_4_len) {
			buf = read_string (fp, disk_item.email_4_len);
			if (!buf) {
				free_summary_item (item);
				return FALSE;
			}
			item->email_4 = buf;
		}

		/* the only field that has to be there is the id */
		if (!item->id) {
			free_summary_item (item);
			return FALSE;
		}
	}
	else {
		/* unhandled file version */
		return FALSE;
	}

	*new_item = item;
	return TRUE;
}

/* opens the file and loads the header */
static gboolean
e_book_backend_summary_open (EBookBackendSummary *summary)
{
	FILE *fp;
	EBookBackendSummaryHeader header;
	struct stat sb;

	if (summary->priv->fp)
		return TRUE;

	/* Try opening the summary file. */
	fp = g_fopen (summary->priv->summary_path, "rb");
	if (!fp) {
		/* if there's no summary present, look for the .new
		 * file and rename it if it's there, and attempt to
		 * load that */
		gchar *new_filename = g_strconcat (summary->priv->summary_path, ".new", NULL);

		if (g_rename (new_filename, summary->priv->summary_path) == -1 &&
		    errno != ENOENT) {
			g_warning (
				"%s: Failed to rename '%s' to '%s': %s", G_STRFUNC,
				new_filename, summary->priv->summary_path, g_strerror (errno));
		} else {
			fp = g_fopen (summary->priv->summary_path, "rb");
		}

		g_free (new_filename);
	}

	if (!fp) {
		g_warning ("failed to open summary file");
		return FALSE;
	}

	if (fstat (fileno (fp), &sb) == -1) {
		g_warning ("failed to get summary file size");
		fclose (fp);
		return FALSE;
	}

	if (!e_book_backend_summary_check_magic (summary, fp)) {
		g_warning ("file is not a valid summary file");
		fclose (fp);
		return FALSE;
	}

	if (!e_book_backend_summary_load_header (summary, fp, &header)) {
		g_warning ("failed to read summary header");
		fclose (fp);
		return FALSE;
	}

	summary->priv->num_items = header.num_items;
	summary->priv->file_version = header.file_version;
	summary->priv->mtime = sb.st_mtime;
	summary->priv->fp = fp;

	return TRUE;
}

/**
 * e_book_backend_summary_load:
 * @summary: an #EBookBackendSummary
 *
 * Attempts to load @summary from disk. The load is successful if
 * the file was located, it was in the correct format, and it was
 * not out of date.
 *
 * Returns: %TRUE if the load succeeded, %FALSE if it failed.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gboolean
e_book_backend_summary_load (EBookBackendSummary *summary)
{
	EBookBackendSummaryItem *new_item;
	gint i;

	g_return_val_if_fail (summary != NULL, FALSE);

	clear_items (summary);

	if (!e_book_backend_summary_open (summary))
		return FALSE;

	for (i = 0; i < summary->priv->num_items; i++) {
		if (!e_book_backend_summary_load_item (summary, &new_item)) {
			g_warning ("error while reading summary item");
			clear_items (summary);
			fclose (summary->priv->fp);
			summary->priv->fp = NULL;
			summary->priv->dirty = FALSE;
			return FALSE;
		}

		g_ptr_array_add (summary->priv->items, new_item);
		g_hash_table_insert (summary->priv->id_to_item, new_item->id, new_item);
	}

	if (summary->priv->upgraded) {
		e_book_backend_summary_save (summary);
	}
	summary->priv->dirty = FALSE;

	return TRUE;
}

static gboolean
e_book_backend_summary_save_magic (FILE *fp)
{
	gint rv;
	rv = fwrite (PAS_SUMMARY_MAGIC, sizeof (gchar), PAS_SUMMARY_MAGIC_LEN, fp);
	if (rv != PAS_SUMMARY_MAGIC_LEN)
		return FALSE;

	return TRUE;
}

static gboolean
e_book_backend_summary_save_header (EBookBackendSummary *summary,
                                    FILE *fp)
{
	EBookBackendSummaryHeader header;
	gint rv;

	header.file_version = g_htonl (PAS_SUMMARY_FILE_VERSION);
	header.num_items = g_htonl (summary->priv->items->len);
	header.summary_mtime = g_htonl (time (NULL));

	rv = fwrite (&header, sizeof (header), 1, fp);
	if (rv != 1)
		return FALSE;

	return TRUE;
}

static gboolean
save_string (const gchar *str,
             FILE *fp)
{
	size_t rv, len;

	if (!str || !*str)
		return TRUE;

	len = strlen (str);
	rv = fwrite (str, sizeof (gchar), len, fp);
	return (rv == len);
}

static gboolean
e_book_backend_summary_save_item (EBookBackendSummary *summary,
                                  FILE *fp,
                                  EBookBackendSummaryItem *item)
{
	EBookBackendSummaryDiskItem disk_item;
	gint len;
	gint rv;

	len = item->id ? strlen (item->id) : 0;
	disk_item.id_len = g_htons (len);

	len = item->nickname ? strlen (item->nickname) : 0;
	disk_item.nickname_len = g_htons (len);

	len = item->given_name ? strlen (item->given_name) : 0;
	disk_item.given_name_len = g_htons (len);

	len = item->full_name ? strlen (item->full_name) : 0;
	disk_item.full_name_len = g_htons (len);

	len = item->surname ? strlen (item->surname) : 0;
	disk_item.surname_len = g_htons (len);

	len = item->file_as ? strlen (item->file_as) : 0;
	disk_item.file_as_len = g_htons (len);

	len = item->email_1 ? strlen (item->email_1) : 0;
	disk_item.email_1_len = g_htons (len);

	len = item->email_2 ? strlen (item->email_2) : 0;
	disk_item.email_2_len = g_htons (len);

	len = item->email_3 ? strlen (item->email_3) : 0;
	disk_item.email_3_len = g_htons (len);

	len = item->email_4 ? strlen (item->email_4) : 0;
	disk_item.email_4_len = g_htons (len);

	disk_item.wants_html = item->wants_html;
	disk_item.wants_html_set = item->wants_html_set;
	disk_item.list = item->list;
	disk_item.list_show_addresses = item->list_show_addresses;

	rv = fwrite (&disk_item, sizeof (disk_item), 1, fp);
	if (rv != 1)
		return FALSE;

	if (!save_string (item->id, fp))
		return FALSE;
	if (!save_string (item->nickname, fp))
		return FALSE;
	if (!save_string (item->full_name, fp))
		return FALSE;
	if (!save_string (item->given_name, fp))
		return FALSE;
	if (!save_string (item->surname, fp))
		return FALSE;
	if (!save_string (item->file_as, fp))
		return FALSE;
	if (!save_string (item->email_1, fp))
		return FALSE;
	if (!save_string (item->email_2, fp))
		return FALSE;
	if (!save_string (item->email_3, fp))
		return FALSE;
	if (!save_string (item->email_4, fp))
		return FALSE;

	return TRUE;
}

/**
 * e_book_backend_summary_save:
 * @summary: an #EBookBackendSummary
 *
 * Attempts to save @summary to disk.
 *
 * Returns: %TRUE if the save succeeded, %FALSE otherwise.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gboolean
e_book_backend_summary_save (EBookBackendSummary *summary)
{
	struct stat sb;
	FILE *fp = NULL;
	gchar *new_filename = NULL;
	gint i;

	g_return_val_if_fail (summary != NULL, FALSE);

	if (!summary->priv->dirty)
		return TRUE;

	new_filename = g_strconcat (summary->priv->summary_path, ".new", NULL);

	fp = g_fopen (new_filename, "wb");
	if (!fp) {
		g_warning ("could not create new summary file");
		goto lose;
	}

	if (!e_book_backend_summary_save_magic (fp)) {
		g_warning ("could not write magic to new summary file");
		goto lose;
	}

	if (!e_book_backend_summary_save_header (summary, fp)) {
		g_warning ("could not write header to new summary file");
		goto lose;
	}

	for (i = 0; i < summary->priv->items->len; i++) {
		EBookBackendSummaryItem *item = g_ptr_array_index (summary->priv->items, i);
		if (!e_book_backend_summary_save_item (summary, fp, item)) {
			g_warning ("failed to write an item to new summary file, errno = %d", errno);
			goto lose;
		}
	}

	fclose (fp);

	/* if we have a queued flush, clear it (since we just flushed) */
	if (summary->priv->flush_timeout) {
		g_source_remove (summary->priv->flush_timeout);
		summary->priv->flush_timeout = 0;
	}

	/* unlink the old summary and rename the new one */
	g_unlink (summary->priv->summary_path);
	if (g_rename (new_filename, summary->priv->summary_path) == -1) {
		g_warning (
			"%s: Failed to rename '%s' to '%s': %s", G_STRFUNC,
			new_filename, summary->priv->summary_path, g_strerror (errno));
	}

	g_free (new_filename);

	/* lastly, update the in memory mtime to that of the file */
	if (g_stat (summary->priv->summary_path, &sb) == -1) {
		g_warning ("error stat'ing saved summary");
	}
	else {
		summary->priv->mtime = sb.st_mtime;
	}

	summary->priv->dirty = FALSE;
	return TRUE;

 lose:
	if (fp)
		fclose (fp);
	g_unlink (new_filename);
	g_free (new_filename);
	return FALSE;
}

/**
 * e_book_backend_summary_add_contact:
 * @summary: an #EBookBackendSummary
 * @contact: an #EContact to add
 *
 * Adds a summary of @contact to @summary. Does not check if
 * the contact already has a summary.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
void
e_book_backend_summary_add_contact (EBookBackendSummary *summary,
                                    EContact *contact)
{
	EBookBackendSummaryItem *new_item;
	gchar *id = NULL;

	g_return_if_fail (summary != NULL);

	/* ID normally should not be NULL for a contact. */
	/* Added this check as groupwise server sometimes returns
	 * contacts with NULL id
	 */
	id = e_contact_get (contact, E_CONTACT_UID);
	if (!id) {
		g_warning ("found a contact with NULL uid");
		return;
	}

	/* Ensure the duplicate contacts are not added */
	if (e_book_backend_summary_check_contact (summary, id))
		e_book_backend_summary_remove_contact (summary, id);

	new_item = g_new0 (EBookBackendSummaryItem, 1);

	new_item->id = id;
	new_item->nickname = e_contact_get (contact, E_CONTACT_NICKNAME);
	new_item->full_name = e_contact_get (contact, E_CONTACT_FULL_NAME);
	new_item->given_name = e_contact_get (contact, E_CONTACT_GIVEN_NAME);
	new_item->surname = e_contact_get (contact, E_CONTACT_FAMILY_NAME);
	new_item->file_as = e_contact_get (contact, E_CONTACT_FILE_AS);
	new_item->email_1 = e_contact_get (contact, E_CONTACT_EMAIL_1);
	new_item->email_2 = e_contact_get (contact, E_CONTACT_EMAIL_2);
	new_item->email_3 = e_contact_get (contact, E_CONTACT_EMAIL_3);
	new_item->email_4 = e_contact_get (contact, E_CONTACT_EMAIL_4);
	new_item->list = GPOINTER_TO_INT (e_contact_get (contact, E_CONTACT_IS_LIST));
	new_item->list_show_addresses = GPOINTER_TO_INT (e_contact_get (contact, E_CONTACT_LIST_SHOW_ADDRESSES));
	new_item->wants_html = GPOINTER_TO_INT (e_contact_get (contact, E_CONTACT_WANTS_HTML));

	g_ptr_array_add (summary->priv->items, new_item);
	g_hash_table_insert (summary->priv->id_to_item, new_item->id, new_item);

#ifdef SUMMARY_STATS
	summary->priv->size += sizeof (EBookBackendSummaryItem);
	summary->priv->size += new_item->id ? strlen (new_item->id) : 0;
	summary->priv->size += new_item->nickname ? strlen (new_item->nickname) : 0;
	summary->priv->size += new_item->full_name ? strlen (new_item->full_name) : 0;
	summary->priv->size += new_item->given_name ? strlen (new_item->given_name) : 0;
	summary->priv->size += new_item->surname ? strlen (new_item->surname) : 0;
	summary->priv->size += new_item->file_as ? strlen (new_item->file_as) : 0;
	summary->priv->size += new_item->email_1 ? strlen (new_item->email_1) : 0;
	summary->priv->size += new_item->email_2 ? strlen (new_item->email_2) : 0;
	summary->priv->size += new_item->email_3 ? strlen (new_item->email_3) : 0;
	summary->priv->size += new_item->email_4 ? strlen (new_item->email_4) : 0;
#endif
	e_book_backend_summary_touch (summary);
}

/**
 * e_book_backend_summary_remove_contact:
 * @summary: an #EBookBackendSummary
 * @id: a unique contact ID string
 *
 * Removes the summary of the contact identified by @id from @summary.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
void
e_book_backend_summary_remove_contact (EBookBackendSummary *summary,
                                       const gchar *id)
{
	EBookBackendSummaryItem *item;

	g_return_if_fail (summary != NULL);

	item = g_hash_table_lookup (summary->priv->id_to_item, id);

	if (item) {
		g_ptr_array_remove (summary->priv->items, item);
		g_hash_table_remove (summary->priv->id_to_item, id);
		free_summary_item (item);
		e_book_backend_summary_touch (summary);
		return;
	}

	g_warning ("e_book_backend_summary_remove_contact: unable to locate id `%s'", id);
}

/**
 * e_book_backend_summary_check_contact:
 * @summary: an #EBookBackendSummary
 * @id: a unique contact ID string
 *
 * Checks if a summary of the contact identified by @id
 * exists in @summary.
 *
 * Returns: %TRUE if the summary exists, %FALSE otherwise.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gboolean
e_book_backend_summary_check_contact (EBookBackendSummary *summary,
                                      const gchar *id)
{
	g_return_val_if_fail (summary != NULL, FALSE);

	return g_hash_table_lookup (summary->priv->id_to_item, id) != NULL;
}

static gboolean
summary_flush_func (gpointer data)
{
	EBookBackendSummary *summary = E_BOOK_BACKEND_SUMMARY (data);

	if (!summary->priv->dirty) {
		summary->priv->flush_timeout = 0;
		return FALSE;
	}

	if (!e_book_backend_summary_save (summary)) {
		/* this isn't fatal, as we can just either 1) flush
		 * out with the next change, or 2) regen the summary
		 * when we next load the uri */
		g_warning ("failed to flush summary file to disk");
		return TRUE; /* try again after the next timeout */
	}

	g_message ("Flushed summary to disk");

	/* we only want this to execute once, so return FALSE and set
	 * summary->flush_timeout to 0 */
	summary->priv->flush_timeout = 0;
	return FALSE;
}

/**
 * e_book_backend_summary_touch:
 * @summary: an #EBookBackendSummary
 *
 * Indicates that @summary has changed and should be flushed to disk.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
void
e_book_backend_summary_touch (EBookBackendSummary *summary)
{
	g_return_if_fail (summary != NULL);

	summary->priv->dirty = TRUE;
	if (!summary->priv->flush_timeout
	    && summary->priv->flush_timeout_millis) {
		summary->priv->flush_timeout = e_named_timeout_add (
			summary->priv->flush_timeout_millis,
			summary_flush_func, summary);
	}
}

/**
 * e_book_backend_summary_is_up_to_date:
 * @summary: an #EBookBackendSummary
 * @t: the time to compare with
 *
 * Checks if @summary is more recent than @t.
 *
 * Returns: %TRUE if the summary is up to date, %FALSE otherwise.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gboolean
e_book_backend_summary_is_up_to_date (EBookBackendSummary *summary,
                                      time_t t)
{
	g_return_val_if_fail (summary != NULL, FALSE);

	if (!e_book_backend_summary_open (summary))
		return FALSE;
	else
		return summary->priv->mtime >= t;
}


/* we only want to do summary queries if the query is over the set fields in the summary */

static ESExpResult *
func_check (struct _ESExp *f,
            gint argc,
            struct _ESExpResult **argv,
            gpointer data)
{
	ESExpResult *r;
	gint truth = FALSE;
	gboolean *pretval = data;

	if (argc == 2
	    && argv[0]->type == ESEXP_RES_STRING
	    && argv[1]->type == ESEXP_RES_STRING) {
		gchar *query_name = argv[0]->value.string;

		if (!strcmp (query_name, "nickname") ||
		    !strcmp (query_name, "full_name") ||
		    !strcmp (query_name, "file_as") ||
		    !strcmp (query_name, "email")) {
			truth = TRUE;
		}
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = truth;

	if (pretval)
		*pretval = (*pretval) && truth;

	return r;
}

/* 'builtin' functions */
static const struct {
	const gchar *name;
	ESExpFunc *func;
	gint type;		/* set to 1 if a function can perform shortcut evaluation, or
				   doesn't execute everything, 0 otherwise */
} check_symbols[] = {
	{ "contains", func_check, 0 },
	{ "is", func_check, 0 },
	{ "beginswith", func_check, 0 },
	{ "endswith", func_check, 0 },
	{ "exists", func_check, 0 },
	{ "exists_vcard", func_check, 0 }
};

/**
 * e_book_backend_summary_is_summary_query:
 * @summary: an #EBookBackendSummary
 * @query: an s-expression to check
 *
 * Checks if @query can be satisfied by searching only the fields
 * stored by @summary.
 *
 * Returns: %TRUE if the query can be satisfied, %FALSE otherwise.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gboolean
e_book_backend_summary_is_summary_query (EBookBackendSummary *summary,
                                         const gchar *query)
{
	ESExp *sexp;
	ESExpResult *r;
	gboolean retval = TRUE;
	gint i;
	gint esexp_error;

	g_return_val_if_fail (summary != NULL, FALSE);

	sexp = e_sexp_new ();

	for (i = 0; i < G_N_ELEMENTS (check_symbols); i++) {
		if (check_symbols[i].type == 1) {
			e_sexp_add_ifunction (sexp, 0, check_symbols[i].name,
					     (ESExpIFunc *) check_symbols[i].func, &retval);
		} else {
			e_sexp_add_function (
				sexp, 0, check_symbols[i].name,
				check_symbols[i].func, &retval);
		}
	}

	e_sexp_input_text (sexp, query, strlen (query));
	esexp_error = e_sexp_parse (sexp);

	if (esexp_error == -1) {
		g_object_unref (sexp);
		return FALSE;
	}

	r = e_sexp_eval (sexp);

	retval = retval && (r && r->type == ESEXP_RES_BOOL && r->value.boolean);

	e_sexp_result_free (sexp, r);

	g_object_unref (sexp);

	return retval;
}



/* the actual query mechanics */
static ESExpResult *
do_compare (EBookBackendSummary *summary,
            struct _ESExp *f,
            gint argc,
            struct _ESExpResult **argv,
            gchar *(*compare)(const gchar *, const gchar *))
{
	GPtrArray *result = g_ptr_array_new ();
	ESExpResult *r;
	gint i;

	if (argc == 2
	    && argv[0]->type == ESEXP_RES_STRING
	    && argv[1]->type == ESEXP_RES_STRING) {

		for (i = 0; i < summary->priv->items->len; i++) {
			EBookBackendSummaryItem *item = g_ptr_array_index (summary->priv->items, i);
			if (!strcmp (argv[0]->value.string, "full_name")) {
				gchar *given = item->given_name;
				gchar *surname = item->surname;
				gchar *full_name = item->full_name;

				if ((given && compare (given, argv[1]->value.string))
				    || (surname && compare (surname, argv[1]->value.string))
				    || (full_name && compare (full_name, argv[1]->value.string)))
					g_ptr_array_add (result, item->id);
			}
			else if (!strcmp (argv[0]->value.string, "email")) {
				gchar *email_1 = item->email_1;
				gchar *email_2 = item->email_2;
				gchar *email_3 = item->email_3;
				gchar *email_4 = item->email_4;
				if ((email_1 && compare (email_1, argv[1]->value.string))
				    || (email_2 && compare (email_2, argv[1]->value.string))
				    || (email_3 && compare (email_3, argv[1]->value.string))
				    || (email_4 && compare (email_4, argv[1]->value.string)))
					g_ptr_array_add (result, item->id);
			}
			else if (!strcmp (argv[0]->value.string, "file_as")) {
				gchar *file_as = item->file_as;
				if (file_as && compare (file_as, argv[1]->value.string))
					g_ptr_array_add (result, item->id);
			}
			else if (!strcmp (argv[0]->value.string, "nickname")) {
				gchar *nickname = item->nickname;
				if (nickname && compare (nickname, argv[1]->value.string))
					g_ptr_array_add (result, item->id);
			}
		}
	}

	r = e_sexp_result_new (f, ESEXP_RES_ARRAY_PTR);
	r->value.ptrarray = result;

	return r;
}

static gchar *
contains_helper (const gchar *ps1,
                 const gchar *ps2)
{
	gchar *s1 = e_util_utf8_remove_accents (ps1);
	gchar *s2 = e_util_utf8_remove_accents (ps2);
	gchar *res;

	res = (gchar *) e_util_utf8_strstrcase (s1, s2);

	g_free (s1);
	g_free (s2);

	return res;
}

static ESExpResult *
func_contains (struct _ESExp *f,
               gint argc,
               struct _ESExpResult **argv,
               gpointer data)
{
	EBookBackendSummary *summary = data;

	return do_compare (summary, f, argc, argv, contains_helper);
}

static gchar *
is_helper (const gchar *ps1,
           const gchar *ps2)
{
	gchar *s1 = e_util_utf8_remove_accents (ps1);
	gchar *s2 = e_util_utf8_remove_accents (ps2);
	gchar *res;

	if (!e_util_utf8_strcasecmp (s1, s2))
		res = (gchar *) ps1;
	else
		res = NULL;

	g_free (s1);
	g_free (s2);

	return res;
}

static ESExpResult *
func_is (struct _ESExp *f,
         gint argc,
         struct _ESExpResult **argv,
         gpointer data)
{
	EBookBackendSummary *summary = data;

	return do_compare (summary, f, argc, argv, is_helper);
}

static gchar *
endswith_helper (const gchar *ps1,
                 const gchar *ps2)
{
	gchar *s1 = e_util_utf8_remove_accents (ps1);
	gchar *s2 = e_util_utf8_remove_accents (ps2);
	gchar *res;
	glong s1len = g_utf8_strlen (s1, -1);
	glong s2len = g_utf8_strlen (s2, -1);

	if (s1len < s2len)
		res = NULL;
	else
		res = (gchar *) e_util_utf8_strstrcase (g_utf8_offset_to_pointer (s1, s1len - s2len), s2);

	g_free (s1);
	g_free (s2);

	return res;
}

static ESExpResult *
func_endswith (struct _ESExp *f,
               gint argc,
               struct _ESExpResult **argv,
               gpointer data)
{
	EBookBackendSummary *summary = data;

	return do_compare (summary, f, argc, argv, endswith_helper);
}

static gchar *
beginswith_helper (const gchar *ps1,
                   const gchar *ps2)
{
	gchar *p, *res;
	gchar *s1 = e_util_utf8_remove_accents (ps1);
	gchar *s2 = e_util_utf8_remove_accents (ps2);

	if ((p = (gchar *) e_util_utf8_strstrcase (s1, s2))
	    && (p == s1))
		res = (gchar *) ps1;
	else
		res = NULL;

	g_free (s1);
	g_free (s2);

	return res;
}

static ESExpResult *
func_beginswith (struct _ESExp *f,
                 gint argc,
                 struct _ESExpResult **argv,
                 gpointer data)
{
	EBookBackendSummary *summary = data;

	return do_compare (summary, f, argc, argv, beginswith_helper);
}

/* 'builtin' functions */
static const struct {
	const gchar *name;
	ESExpFunc *func;
	gint type;		/* set to 1 if a function can perform shortcut evaluation, or
				   doesn't execute everything, 0 otherwise */
} symbols[] = {
	{ "contains", func_contains, 0 },
	{ "is", func_is, 0 },
	{ "beginswith", func_beginswith, 0 },
	{ "endswith", func_endswith, 0 },
};

/**
 * e_book_backend_summary_search:
 * @summary: an #EBookBackendSummary
 * @query: an s-expression
 *
 * Searches @summary for contacts matching @query.
 *
 * Returns: A #GPtrArray of pointers to contact ID strings.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
GPtrArray *
e_book_backend_summary_search (EBookBackendSummary *summary,
                               const gchar *query)
{
	ESExp *sexp;
	ESExpResult *r;
	GPtrArray *retval;
	gint i;
	gint esexp_error;

	g_return_val_if_fail (summary != NULL, NULL);

	sexp = e_sexp_new ();

	for (i = 0; i < G_N_ELEMENTS (symbols); i++) {
		if (symbols[i].type == 1) {
			e_sexp_add_ifunction (sexp, 0, symbols[i].name,
					     (ESExpIFunc *) symbols[i].func, summary);
		} else {
			e_sexp_add_function (
				sexp, 0, symbols[i].name,
				symbols[i].func, summary);
		}
	}

	e_sexp_input_text (sexp, query, strlen (query));
	esexp_error = e_sexp_parse (sexp);

	if (esexp_error == -1) {
		g_object_unref (sexp);
		return NULL;
	}

	retval = g_ptr_array_new ();
	r = e_sexp_eval (sexp);

	if (r && r->type == ESEXP_RES_ARRAY_PTR && r->value.ptrarray) {
		GPtrArray *ptrarray = r->value.ptrarray;
		gint i;

		for (i = 0; i < ptrarray->len; i++)
			g_ptr_array_add (retval, g_ptr_array_index (ptrarray, i));
	}

	e_sexp_result_free (sexp, r);

	g_object_unref (sexp);

	return retval;
}

/**
 * e_book_backend_summary_get_summary_vcard:
 * @summary: an #EBookBackendSummary
 * @id: a unique contact ID
 *
 * Constructs and returns a VCard from the contact summary specified
 * by @id.
 *
 * Returns: A new VCard, or %NULL if the contact summary didn't exist.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
gchar *
e_book_backend_summary_get_summary_vcard (EBookBackendSummary *summary,
                                          const gchar *id)
{
	EBookBackendSummaryItem *item;

	g_return_val_if_fail (summary != NULL, NULL);

	item = g_hash_table_lookup (summary->priv->id_to_item, id);

	if (item) {
		EContact *contact = e_contact_new ();
		gchar *vcard;

		e_contact_set (contact, E_CONTACT_UID, item->id);
		e_contact_set (contact, E_CONTACT_FILE_AS, item->file_as);
		e_contact_set (contact, E_CONTACT_GIVEN_NAME, item->given_name);
		e_contact_set (contact, E_CONTACT_FAMILY_NAME, item->surname);
		e_contact_set (contact, E_CONTACT_NICKNAME, item->nickname);
		e_contact_set (contact, E_CONTACT_FULL_NAME, item->full_name);
		e_contact_set (contact, E_CONTACT_EMAIL_1, item->email_1);
		e_contact_set (contact, E_CONTACT_EMAIL_2, item->email_2);
		e_contact_set (contact, E_CONTACT_EMAIL_3, item->email_3);
		e_contact_set (contact, E_CONTACT_EMAIL_4, item->email_4);

		e_contact_set (contact, E_CONTACT_IS_LIST, GINT_TO_POINTER (item->list));
		e_contact_set (contact, E_CONTACT_LIST_SHOW_ADDRESSES, GINT_TO_POINTER (item->list_show_addresses));
		e_contact_set (contact, E_CONTACT_WANTS_HTML, GINT_TO_POINTER (item->wants_html));

		vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

		g_object_unref (contact);

		return vcard;
	}
	else {
		g_warning ("in unable to locate card `%s' in summary", id);
		return NULL;
	}
}

