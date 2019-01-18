/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
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
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_BOOK_CACHE_H
#define E_BOOK_CACHE_H

#include <libebackend/libebackend.h>
#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_CACHE \
	(e_book_cache_get_type ())
#define E_BOOK_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_CACHE, EBookCache))
#define E_BOOK_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_CACHE, EBookCacheClass))
#define E_IS_BOOK_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_CACHE))
#define E_IS_BOOK_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_CACHE))
#define E_BOOK_CACHE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_CACHE, EBookCacheClass))

G_BEGIN_DECLS

typedef struct _EBookCache EBookCache;
typedef struct _EBookCacheClass EBookCacheClass;
typedef struct _EBookCachePrivate EBookCachePrivate;

/**
 * EBookCacheSearchData:
 * @uid: The %E_CONTACT_UID field of this contact
 * @vcard: The vcard string
 * @extra: Any extra data associated with the vcard
 *
 * This structure is used to represent contacts returned
 * by the #EBookCache from various functions
 * such as e_book_cache_search().
 *
 * The @extra parameter will contain any data which was
 * previously passed for this contact in e_book_cache_put_contact()
 * or set with e_book_cache_set_contact_extra().
 *
 * These should be freed with e_book_cache_search_data_free().
 *
 * Since: 3.26
 **/
typedef struct {
	gchar *uid;
	gchar *vcard;
	gchar *extra;
} EBookCacheSearchData;

#define E_TYPE_BOOK_CACHE_SEARCH_DATA (e_book_cache_search_data_get_type ())

GType		e_book_cache_search_data_get_type
						(void) G_GNUC_CONST;
EBookCacheSearchData *
		e_book_cache_search_data_new	(const gchar *uid,
						 const gchar *vcard,
						 const gchar *extra);
EBookCacheSearchData *
		e_book_cache_search_data_copy	(const EBookCacheSearchData *data);
void		e_book_cache_search_data_free	(/* EBookCacheSearchData * */ gpointer data);

/**
 * EBookCacheSearchFunc:
 * @book_cache: an #EBookCache
 * @uid: a unique object identifier
 * @revision: the object revision
 * @object: the object itself
 * @extra: extra data stored with the object
 * @offline_state: objects offline state, one of #EOfflineState
 * @user_data: user data, as used in e_book_cache_search_with_callback()
 *
 * A callback called for each object row when using
 * e_book_cache_search_with_callback() function.
 *
 * Returns: %TRUE to continue, %FALSE to stop walk through.
 *
 * Since: 3.26
 **/
typedef gboolean (* EBookCacheSearchFunc)	(EBookCache *book_cache,
						 const gchar *uid,
						 const gchar *revision,
						 const gchar *object,
						 const gchar *extra,
						 EOfflineState offline_state,
						 gpointer user_data);

/**
 * EBookCache:
 *
 * Contains only private data that should be read and manipulated using
 * the functions below.
 *
 * Since: 3.26
 **/
struct _EBookCache {
	/*< private >*/
	ECache parent;
	EBookCachePrivate *priv;
};

/**
 * EBookCacheClass:
 *
 * Class structure for the #EBookCache class.
 *
 * Since: 3.26
 */
struct _EBookCacheClass {
	/*< private >*/
	ECacheClass parent_class;

	/* Signals */
	void		(* e164_changed)	(EBookCache *book_cache,
						 EContact *contact,
						 gboolean is_replace);

	gchar *		(* dup_contact_revision)
						(EBookCache *book_cache,
						 EContact *contact);

	/* Padding for future expansion */
	gpointer reserved[10];
};

/**
 * EBookCacheCursor:
 *
 * An opaque cursor pointer
 *
 * Since: 3.26
 */
typedef struct _EBookCacheCursor EBookCacheCursor;

/**
 * EBookCacheCursorOrigin:
 * @E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT: The current cursor position.
 * @E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN: The beginning of the cursor results.
 * @E_BOOK_CACHE_CURSOR_ORIGIN_END: The end of the cursor results.
 *
 * Specifies the start position to in the list of traversed contacts
 * in calls to e_book_cache_cursor_step().
 *
 * When an #EBookCacheCursor is created, the current position implied by %E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT
 * is the same as %E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN.
 *
 * Since: 3.26
 */
typedef enum {
	E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT = 0,
	E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN,
	E_BOOK_CACHE_CURSOR_ORIGIN_END
} EBookCacheCursorOrigin;

/**
 * EBookCacheCursorStepFlags:
 * @E_BOOK_CACHE_CURSOR_STEP_MOVE: The cursor position should be modified while stepping.
 * @E_BOOK_CACHE_CURSOR_STEP_FETCH: Traversed contacts should be listed and returned while stepping.
 *
 * Defines the behaviour of e_book_cache_cursor_step().
 *
 * Since: 3.26
 */
typedef enum {
	E_BOOK_CACHE_CURSOR_STEP_MOVE = (1 << 0),
	E_BOOK_CACHE_CURSOR_STEP_FETCH = (1 << 1)
} EBookCacheCursorStepFlags;

GType		e_book_cache_get_type		(void) G_GNUC_CONST;

EBookCache *	e_book_cache_new		(const gchar *filename,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
EBookCache *	e_book_cache_new_full		(const gchar *filename,
						 ESource *source,
						 ESourceBackendSummarySetup *setup,
						 GCancellable *cancellable,
						 GError **error);
ESource *	e_book_cache_ref_source		(EBookCache *book_cache);
gchar *		e_book_cache_dup_contact_revision
						(EBookCache *book_cache,
						 EContact *contact);
gboolean	e_book_cache_set_locale		(EBookCache *book_cache,
						 const gchar *lc_collate,
						 GCancellable *cancellable,
						 GError **error);
gchar *		e_book_cache_dup_locale		(EBookCache *book_cache);

ECollator *	e_book_cache_ref_collator	(EBookCache *book_cache);

/* Adding / Removing / Searching contacts */
gboolean	e_book_cache_put_contact	(EBookCache *book_cache,
						 EContact *contact,
						 const gchar *extra,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_put_contacts	(EBookCache *book_cache,
						 const GSList *contacts,
						 const GSList *extras,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_remove_contact	(EBookCache *book_cache,
						 const gchar *uid,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_remove_contacts	(EBookCache *book_cache,
						 const GSList *uids,
						 ECacheOfflineFlag offline_flag,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_get_contact	(EBookCache *book_cache,
						 const gchar *uid,
						 gboolean meta_contact,
						 EContact **out_contact,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_get_vcard		(EBookCache *book_cache,
						 const gchar *uid,
						 gboolean meta_contact,
						 gchar **out_vcard,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_set_contact_extra	(EBookCache *book_cache,
						 const gchar *uid,
						 const gchar *extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_get_contact_extra	(EBookCache *book_cache,
						 const gchar *uid,
						 gchar **out_extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_get_uids_with_extra
						(EBookCache *book_cache,
						 const gchar *extra,
						 GSList **out_uids, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_search		(EBookCache *book_cache,
						 const gchar *sexp,
						 gboolean meta_contacts,
						 GSList **out_list, /* EBookCacheSearchData * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_search_uids	(EBookCache *book_cache,
						 const gchar *sexp,
						 GSList **out_list, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_cache_search_with_callback
						(EBookCache *book_cache,
						 const gchar *sexp,
						 EBookCacheSearchFunc func,
						 gpointer user_data,
						 GCancellable *cancellable,
						 GError **error);
/* Cursor API */
EBookCacheCursor *
		e_book_cache_cursor_new		(EBookCache *book_cache,
						 const gchar *sexp,
						 const EContactField *sort_fields,
						 const EBookCursorSortType *sort_types,
						 guint n_sort_fields,
						 GError **error);
void		e_book_cache_cursor_free	(EBookCache *book_cache,
						 EBookCacheCursor *cursor);
gint		e_book_cache_cursor_step	(EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 EBookCacheCursorStepFlags flags,
						 EBookCacheCursorOrigin origin,
						 gint count,
						 GSList **out_results,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_cache_cursor_set_target_alphabetic_index
						(EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 gint idx);
gboolean	e_book_cache_cursor_set_sexp	(EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 const gchar *sexp,
						 GError **error);
gboolean	e_book_cache_cursor_calculate	(EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 gint *out_total,
						 gint *out_position,
						 GCancellable *cancellable,
						 GError **error);
gint		e_book_cache_cursor_compare_contact
						(EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 EContact *contact,
						 gboolean *out_matches_sexp);

G_END_DECLS

#endif /* E_BOOK_CACHE_H */
