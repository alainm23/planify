/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/* e-book-query.h - A wrapper object for serializing and deserializing addressbook queries.
 *
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
 * Authors: Chris Toshok  <toshok@ximian.com>
 *          Mathias Hasselmann <mathias@openismus.com>
 *          Tristan Van Berkom <tristanvb@openismus.com>
 *    
 */

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef __E_BOOK_QUERY_H__
#define __E_BOOK_QUERY_H__

#include <libebook-contacts/e-contact.h>

G_BEGIN_DECLS

#define E_TYPE_BOOK_QUERY (e_book_query_get_type ())

typedef struct _EBookQuery EBookQuery;

/**
 * EBookQueryTest:
 * @E_BOOK_QUERY_IS: look for exact match of the supplied test value
 * @E_BOOK_QUERY_CONTAINS: check if a field contains the test value
 * @E_BOOK_QUERY_BEGINS_WITH: check if a field starts with the test value
 * @E_BOOK_QUERY_ENDS_WITH: check if a field ends with the test value
 * @E_BOOK_QUERY_EQUALS_PHONE_NUMBER: check if a field matches with a value tested
 * using e_phone_number_compare_strings(), the match must be of strenth %E_PHONE_NUMBER_MATCH_EXACT
 * for this query to return any matches.
 * @E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER: check if a field matches with a value tested
 * using e_phone_number_compare_strings(), the match must be at least of strength %E_PHONE_NUMBER_MATCH_NATIONAL
 * for this query to return any matches.
 * @E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER: check if a field matches with a value tested
 * using e_phone_number_compare_strings(), the match must be at least of strength %E_PHONE_NUMBER_MATCH_SHORT
 * for this query to return any matches.
 * @E_BOOK_QUERY_REGEX_NORMAL: A regular expression query against contact data normalized with e_util_utf8_normalize(),
 * the normalized data is lower case with any accents removed.
 * @E_BOOK_QUERY_REGEX_RAW: A regular expression query against raw contact data, this is usually slower than
 * a %E_BOOK_QUERY_REGEX_NORMAL as it implies that #EVCard(s) must be parsed in order to get the raw data
 * for comparison.
 * @E_BOOK_QUERY_LAST: End marker for the #EBookQueryTest enumeration, not a valid query test.
 *
 * The kind of test a query created by e_book_query_field_test() shall perform.
 *
 * See also: e_phone_number_compare_strings().
 **/
typedef enum {
  E_BOOK_QUERY_IS = 0,
  E_BOOK_QUERY_CONTAINS,
  E_BOOK_QUERY_BEGINS_WITH,
  E_BOOK_QUERY_ENDS_WITH,

  E_BOOK_QUERY_EQUALS_PHONE_NUMBER,
  E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER,
  E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER,

  E_BOOK_QUERY_REGEX_NORMAL,
  E_BOOK_QUERY_REGEX_RAW,

  /*
    Consider these "coming soon".

    E_BOOK_QUERY_LT,
    E_BOOK_QUERY_LE,
    E_BOOK_QUERY_GT,
    E_BOOK_QUERY_GE,
    E_BOOK_QUERY_EQ,
  */

  E_BOOK_QUERY_LAST
} EBookQueryTest;

EBookQuery * e_book_query_from_string  (const gchar *query_string);
gchar *       e_book_query_to_string    (EBookQuery *q);

EBookQuery * e_book_query_ref          (EBookQuery *q);
void        e_book_query_unref        (EBookQuery *q);

EBookQuery * e_book_query_and          (gint nqs, EBookQuery **qs, gboolean unref);
EBookQuery * e_book_query_andv         (EBookQuery *q, ...) G_GNUC_NULL_TERMINATED;
EBookQuery * e_book_query_or           (gint nqs, EBookQuery **qs, gboolean unref);
EBookQuery * e_book_query_orv          (EBookQuery *q, ...) G_GNUC_NULL_TERMINATED;

EBookQuery * e_book_query_not          (EBookQuery *q, gboolean unref);

EBookQuery * e_book_query_field_exists (EContactField   field);
EBookQuery * e_book_query_vcard_field_exists (const gchar *field);
EBookQuery * e_book_query_field_test   (EContactField   field,
				       EBookQueryTest     test,
				       const gchar        *value);
EBookQuery * e_book_query_vcard_field_test (const gchar    *field,
				       EBookQueryTest     test,
				       const gchar        *value);

/* a special any field contains query */
EBookQuery * e_book_query_any_field_contains (const gchar  *value);

GType       e_book_query_get_type (void);
EBookQuery * e_book_query_copy     (EBookQuery *q);

G_END_DECLS

#endif /* __E_BOOK_QUERY_H__ */
