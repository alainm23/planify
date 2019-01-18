/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-book-backend-sqlitedb.h
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Chenthill Palanisamy <pchenthill@novell.com>
 *          Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_BOOK_BACKEND_SQLITEDB_H
#define E_BOOK_BACKEND_SQLITEDB_H

#ifndef EDS_DISABLE_DEPRECATED

#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_BACKEND_SQLITEDB \
	(e_book_backend_sqlitedb_get_type ())
#define E_BOOK_BACKEND_SQLITEDB(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_BACKEND_SQLITEDB, EBookBackendSqliteDB))
#define E_BOOK_BACKEND_SQLITEDB_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_BACKEND_SQLITEDB, EBookBackendSqliteDBClass))
#define E_IS_BOOK_BACKEND_SQLITEDB(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_BACKEND_SQLITEDB))
#define E_IS_BOOK_BACKEND_SQLITEDB_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_BACKEND_SQLITEDB))
#define E_BOOK_BACKEND_SQLITEDB_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_BACKEND_SQLITEDB, EBookBackendSqliteDBClass))

/**
 * E_BOOK_SDB_ERROR:
 *
 * Error domain for #EBookBackendSqliteDB operations.
 *
 * Since: 3.8
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
#define E_BOOK_SDB_ERROR (e_book_backend_sqlitedb_error_quark ())

G_BEGIN_DECLS

typedef struct _EBookBackendSqliteDB EBookBackendSqliteDB;
typedef struct _EBookBackendSqliteDBClass EBookBackendSqliteDBClass;
typedef struct _EBookBackendSqliteDBPrivate EBookBackendSqliteDBPrivate;

/**
 * EBookSDBError:
 * @E_BOOK_SDB_ERROR_CONSTRAINT: The error occurred due to an explicit constraint
 * @E_BOOK_SDB_ERROR_CONTACT_NOT_FOUND: A contact was not found by UID (this is different
 *                                      from a query that returns no results, which is not an error).
 * @E_BOOK_SDB_ERROR_OTHER: Another error occurred
 * @E_BOOK_SDB_ERROR_NOT_SUPPORTED: A query was not supported
 * @E_BOOK_SDB_ERROR_INVALID_QUERY: A query was invalid. This can happen if the sexp could not be parsed
 *                                  or if a phone number query contained non-phonenumber input.
 * @E_BOOK_SDB_ERROR_END_OF_LIST: An attempt was made to fetch results past the end of a contact list
 *
 * Defines the types of possible errors reported by the #EBookBackendSqliteDB
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 */
typedef enum {
	E_BOOK_SDB_ERROR_CONSTRAINT,
	E_BOOK_SDB_ERROR_CONTACT_NOT_FOUND,
	E_BOOK_SDB_ERROR_OTHER,
	E_BOOK_SDB_ERROR_NOT_SUPPORTED,
	E_BOOK_SDB_ERROR_INVALID_QUERY,
	E_BOOK_SDB_ERROR_END_OF_LIST
} EBookSDBError;

/**
 * EBookBackendSqliteDB:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
struct _EBookBackendSqliteDB {
	/*< private >*/
	GObject parent;
	EBookBackendSqliteDBPrivate *priv;
};

/**
 * EBookBackendSqliteDBClass:
 *
 * Class structure for the #EBookBackendSqliteDB class.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 */
struct _EBookBackendSqliteDBClass {
	/*< private >*/
	GObjectClass parent_class;
};

/**
 * EbSdbSearchData:
 * @vcard: The the vcard string
 * @uid: The %E_CONTACT_UID field of this contact
 * @bdata: Extra data set for this contact.
 *
 * This structure is used to represent contacts returned
 * by the EBookBackendSqliteDB from various functions
 * such as e_book_backend_sqlitedb_search().
 *
 * The @bdata parameter will contain any data previously
 * set for the given contact with e_book_backend_sqlitedb_set_contact_bdata().
 *
 * These should be freed with e_book_backend_sqlitedb_search_data_free().
 *
 * Since: 3.2
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 **/
typedef struct {
	gchar *vcard;
	gchar *uid;
	gchar *bdata;
} EbSdbSearchData;

/**
 * EbSdbCursor:
 *
 * An opaque cursor pointer
 *
 * Since: 3.12
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 */
typedef struct _EbSdbCursor EbSdbCursor;

/**
 * EbSdbCursorOrigin:
 * @EBSDB_CURSOR_ORIGIN_CURRENT:  The current cursor position
 * @EBSDB_CURSOR_ORIGIN_BEGIN:    The beginning of the cursor results.
 * @EBSDB_CURSOR_ORIGIN_END:      The ending of the cursor results.
 *
 * Specifies the start position to in the list of traversed contacts
 * in calls to e_book_backend_sqlitedb_cursor_step().
 *
 * When an #EbSdbCursor is created, the current position implied by %EBSDB_CURSOR_ORIGIN_CURRENT
 * is the same as %EBSDB_CURSOR_ORIGIN_BEGIN.
 *
 * Since: 3.12
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 */
typedef enum {
	EBSDB_CURSOR_ORIGIN_CURRENT = 0,
	EBSDB_CURSOR_ORIGIN_BEGIN,
	EBSDB_CURSOR_ORIGIN_END
} EbSdbCursorOrigin;

/**
 * EbSdbCursorStepFlags:
 * @EBSDB_CURSOR_STEP_MOVE:  The cursor position should be modified while stepping
 * @EBSDB_CURSOR_STEP_FETCH: Traversed contacts should be listed and returned while stepping.
 *
 * Defines the behaviour of e_book_backend_sqlitedb_cursor_step().
 *
 * Since: 3.12
 *
 * Deprecated: 3.12: Use #EBookSqlite instead
 */
typedef enum {
	EBSDB_CURSOR_STEP_MOVE = (1 << 0),
	EBSDB_CURSOR_STEP_FETCH = (1 << 1)
} EbSdbCursorStepFlags;

GType		e_book_backend_sqlitedb_get_type
						(void) G_GNUC_CONST;
GQuark          e_book_backend_sqlitedb_error_quark
                                                (void);
EBookBackendSqliteDB *
		e_book_backend_sqlitedb_new	(const gchar *path,
						 const gchar *emailid,
						 const gchar *folderid,
						 const gchar *folder_name,
						 gboolean store_vcard,
						 GError **error);
EBookBackendSqliteDB *
		e_book_backend_sqlitedb_new_full
                                                (const gchar *path,
						 const gchar *emailid,
						 const gchar *folderid,
						 const gchar *folder_name,
						 gboolean store_vcard,
						 ESourceBackendSummarySetup *setup,
						 GError **error);
gboolean	e_book_backend_sqlitedb_lock_updates
						(EBookBackendSqliteDB *ebsdb,
						 GError **error);
gboolean	e_book_backend_sqlitedb_unlock_updates
						(EBookBackendSqliteDB *ebsdb,
						 gboolean do_commit,
						 GError **error);
ECollator      *e_book_backend_sqlitedb_ref_collator
                                                 (EBookBackendSqliteDB *ebsdb);
gboolean	e_book_backend_sqlitedb_new_contact
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 EContact *contact,
						 gboolean replace_existing,
						 GError **error);
gboolean	e_book_backend_sqlitedb_new_contacts
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GSList *contacts,
						 gboolean replace_existing,
						 GError **error);
gboolean	e_book_backend_sqlitedb_remove_contact
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_remove_contacts
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GSList *uids,
						 GError **error);
gboolean	e_book_backend_sqlitedb_has_contact
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 gboolean *partial_content,
						 GError **error);
EContact *	e_book_backend_sqlitedb_get_contact
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 GHashTable *fields_of_interest,
						 gboolean *with_all_required_fields,
						 GError **error);
gchar *		e_book_backend_sqlitedb_get_vcard_string
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 GHashTable *fields_of_interest,
						 gboolean *with_all_required_fields,
						 GError **error);
GSList *	e_book_backend_sqlitedb_search	(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *sexp,
						 GHashTable *fields_of_interest,
						 gboolean *searched,
						 gboolean *with_all_required_fields,
						 GError **error);
GSList *	e_book_backend_sqlitedb_search_uids
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *sexp,
						 gboolean *searched,
						 GError **error);
GHashTable *	e_book_backend_sqlitedb_get_uids_and_rev
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_get_is_populated
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_is_populated
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 gboolean populated,
						 GError **error);
gboolean	e_book_backend_sqlitedb_get_revision
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 gchar **revision_out,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_revision
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *revision,
						 GError **error);
gchar *		e_book_backend_sqlitedb_get_sync_data
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_sync_data
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *sync_data,
						 GError **error);
gchar *		e_book_backend_sqlitedb_get_key_value
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *key,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_key_value
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *key,
						 const gchar *value,
						 GError **error);
gchar *		e_book_backend_sqlitedb_get_contact_bdata
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_contact_bdata
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 const gchar *uid,
						 const gchar *value,
						 GError **error);
gboolean	e_book_backend_sqlitedb_get_has_partial_content
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_set_has_partial_content
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 gboolean partial_content,
						 GError **error);
GSList *	e_book_backend_sqlitedb_get_partially_cached_ids
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_delete_addressbook
						(EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GError **error);
gboolean	e_book_backend_sqlitedb_remove	(EBookBackendSqliteDB *ebsdb,
						 GError **error);
void		e_book_backend_sqlitedb_search_data_free
						(EbSdbSearchData *s_data);
gboolean        e_book_backend_sqlitedb_check_summary_query
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar *query,
						 gboolean *with_list_attrs);
gboolean        e_book_backend_sqlitedb_check_summary_fields
                                                (EBookBackendSqliteDB *ebsdb,
						 GHashTable *fields_of_interest);
gboolean        e_book_backend_sqlitedb_set_locale
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar          *folderid,
						 const gchar          *lc_collate,
						 GError              **error);
gboolean        e_book_backend_sqlitedb_get_locale
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar          *folderid,
						 gchar               **locale_out,
						 GError              **error);

/* Cursor API */
EbSdbCursor    *e_book_backend_sqlitedb_cursor_new
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar          *folderid,
						 const gchar          *sexp,
						 EContactField        *sort_fields,
						 EBookCursorSortType  *sort_types,
						 guint                 n_sort_fields,
						 GError              **error);
void            e_book_backend_sqlitedb_cursor_free
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor);
gint            e_book_backend_sqlitedb_cursor_step
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor,
						 EbSdbCursorStepFlags  flags,
						 EbSdbCursorOrigin     origin,
						 gint                  count,
						 GSList              **results,
						 GError              **error);
void            e_book_backend_sqlitedb_cursor_set_target_alphabetic_index
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor,
						 gint                  index);
gboolean        e_book_backend_sqlitedb_cursor_set_sexp
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor,
						 const gchar          *sexp,
						 GError              **error);
gboolean        e_book_backend_sqlitedb_cursor_calculate
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor,
						 gint                 *total,
						 gint                 *position,
						 GError              **error);
gint            e_book_backend_sqlitedb_cursor_compare_contact
                                                (EBookBackendSqliteDB *ebsdb,
						 EbSdbCursor          *cursor,
						 EContact             *contact,
						 gboolean             *matches_sexp);

gboolean	e_book_backend_sqlitedb_is_summary_query
						(const gchar *query);
gboolean	e_book_backend_sqlitedb_is_summary_fields
						(GHashTable *fields_of_interest);
gboolean	e_book_backend_sqlitedb_add_contact
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 EContact *contact,
						 gboolean partial_content,
						 GError **error);
gboolean	e_book_backend_sqlitedb_add_contacts
                                                (EBookBackendSqliteDB *ebsdb,
						 const gchar *folderid,
						 GSList *contacts,
						 gboolean partial_content,
						 GError **error);

G_END_DECLS

#endif /* EDS_DISABLE_DEPRECATED */

#endif /* E_BOOK_BACKEND_SQLITEDB_H */
