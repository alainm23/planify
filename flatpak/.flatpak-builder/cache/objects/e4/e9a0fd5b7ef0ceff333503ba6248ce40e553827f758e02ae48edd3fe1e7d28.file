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

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_BOOK_BACKEND_SUMMARY_H
#define E_BOOK_BACKEND_SUMMARY_H

#ifndef EDS_DISABLE_DEPRECATED

#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_BACKEND_SUMMARY \
	(e_book_backend_summary_get_type ())
#define E_BOOK_BACKEND_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_BACKEND_SUMMARY, EBookBackendSummary))
#define E_BOOK_BACKEND_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_BACKEND_SUMMARY, EBookBackendSummaryClass))
#define E_IS_BOOK_BACKEND_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_BACKEND_SUMMARY))
#define E_IS_BOOK_BACKEND_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_BACKEND_SUMMARY))
#define E_BOOK_BACKEND_SUMMARY_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_BACKEND_SUMMARY, EBookBackendSummaryClass))

G_BEGIN_DECLS

typedef struct _EBookBackendSummary EBookBackendSummary;
typedef struct _EBookBackendSummaryClass EBookBackendSummaryClass;
typedef struct _EBookBackendSummaryPrivate EBookBackendSummaryPrivate;

/**
 * EBookBackendSummary:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Deprecated: 3.12: Use #EBookSqlite instead 
 */
struct _EBookBackendSummary {
	/*< private >*/
	GObject parent_object;
	EBookBackendSummaryPrivate *priv;
};

/**
 * EBookBackendSummaryClass:
 *
 * Class structure for the deprecated API for accessing the addressbook
 *
 * Deprecated: 3.12: Use #EBookSqlite instead 
 */
struct _EBookBackendSummaryClass{
	/*< private >*/
	GObjectClass parent_class;
};

GType		e_book_backend_summary_get_type	(void) G_GNUC_CONST;
EBookBackendSummary *
		e_book_backend_summary_new	(const gchar *summary_path,
						 gint flush_timeout_millis);

/* returns FALSE if the load fails for any reason (including that the
 * summary is out of date), TRUE if it succeeds */
gboolean	e_book_backend_summary_load	(EBookBackendSummary *summary);
/* returns FALSE if the save fails, TRUE if it succeeds (or isn't required due to no changes) */
gboolean	e_book_backend_summary_save	(EBookBackendSummary *summary);

void		e_book_backend_summary_add_contact
						(EBookBackendSummary *summary,
						 EContact *contact);
void		e_book_backend_summary_remove_contact
						(EBookBackendSummary *summary,
						 const gchar *id);
gboolean	e_book_backend_summary_check_contact
						(EBookBackendSummary *summary,
						 const gchar *id);

void		e_book_backend_summary_touch	(EBookBackendSummary *summary);

/* returns TRUE if the summary's mtime is >= @t. */
gboolean	e_book_backend_summary_is_up_to_date
						(EBookBackendSummary *summary,
						 time_t t);

gboolean	e_book_backend_summary_is_summary_query
						(EBookBackendSummary *summary,
						 const gchar *query);
GPtrArray *	e_book_backend_summary_search	(EBookBackendSummary *summary,
						 const gchar *query);
gchar *		e_book_backend_summary_get_summary_vcard
						(EBookBackendSummary *summary,
						 const gchar *id);

G_END_DECLS

#endif /* EDS_DISABLE_DEPRECATED */

#endif /* E_BOOK_BACKEND_SUMMARY_H */
