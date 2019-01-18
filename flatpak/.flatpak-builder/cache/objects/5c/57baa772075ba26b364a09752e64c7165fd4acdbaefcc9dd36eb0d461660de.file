/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/* e-book-query.c - A wrapper object for serializing and deserializing addressbook queries.
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
 */

/**
 * SECTION: e-book-query
 * @include: libebook-contacts/libebook-contacts.h
 * @short_description: Querying and filtering contacts in an addressbook
 *
 * This utility can be used to conveniently create search expressions
 * which can later be used to query and filter results in the #EBookClient,
 * #EBookClientView and #EBookClientCursor interfaces.
 **/

#include "evolution-data-server-config.h"

#include <locale.h>
#include <stdarg.h>
#include <string.h>

#include <libedataserver/libedataserver.h>

#include "e-book-query.h"

#ifdef G_OS_WIN32
#ifndef LC_MESSAGES
#define LC_MESSAGES LC_CTYPE
#endif
#endif

typedef enum {
	E_BOOK_QUERY_TYPE_AND,
	E_BOOK_QUERY_TYPE_OR,
	E_BOOK_QUERY_TYPE_NOT,
	E_BOOK_QUERY_TYPE_FIELD_EXISTS,
	E_BOOK_QUERY_TYPE_FIELD_TEST,
	E_BOOK_QUERY_TYPE_ANY_FIELD_CONTAINS
} EBookQueryType;

struct _EBookQuery {
	EBookQueryType type;
	gint ref_count;

	union {
		struct {
			guint          nqs;
			EBookQuery   **qs;
		} andor;

		struct {
			EBookQuery    *q;
		} not;

		struct {
			EBookQueryTest test;
			gchar          *field_name;
			gchar          *value;
			gchar          *locale;
		} field_test;

		struct {
			EContactField  field;
			gchar          *vcard_field;
		} exist;

		struct {
			gchar          *value;
		} any_field_contains;
	} query;
};

static EBookQuery *
conjoin (EBookQueryType type,
         gint nqs,
         EBookQuery **qs,
         gboolean unref)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);
	gint i;

	ret->type = type;
	ret->query.andor.nqs = nqs;
	ret->query.andor.qs = g_new (EBookQuery *, nqs);
	for (i = 0; i < nqs; i++) {
		ret->query.andor.qs[i] = qs[i];
		if (!unref)
			e_book_query_ref (qs[i]);
	}

	return ret;
}

/**
 * e_book_query_and:
 * @nqs: the number of queries to AND
 * @qs: pointer to an array of #EBookQuery items
 * @unref: if %TRUE, the new query takes ownership of the existing queries
 *
 * Create a new #EBookQuery which is the logical AND of the queries in #qs.
 *
 * Returns: A new #EBookQuery
 **/
EBookQuery *
e_book_query_and (gint nqs,
                  EBookQuery **qs,
                  gboolean unref)
{
	return conjoin (E_BOOK_QUERY_TYPE_AND, nqs, qs, unref);
}

/**
 * e_book_query_or:
 * @nqs: the number of queries to OR
 * @qs: pointer to an array of #EBookQuery items
 * @unref: if %TRUE, the new query takes ownership of the existing queries
 *
 * Creates a new #EBookQuery which is the logical OR of the queries in #qs.
 *
 * Returns: A new #EBookQuery
 **/
EBookQuery *
e_book_query_or (gint nqs,
                 EBookQuery **qs,
                 gboolean unref)
{
	return conjoin (E_BOOK_QUERY_TYPE_OR, nqs, qs, unref);
}

static EBookQuery *
conjoinv (EBookQueryType type,
          EBookQuery *q,
          va_list ap)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);
	GPtrArray *qs;

	qs = g_ptr_array_new ();
	while (q) {
		g_ptr_array_add (qs, q);
		q = va_arg (ap, EBookQuery *);
	}

	ret->type = type;
	ret->query.andor.nqs = qs->len;
	ret->query.andor.qs = (EBookQuery **) qs->pdata;
	g_ptr_array_free (qs, FALSE);

	return ret;
}

/**
 * e_book_query_andv:
 * @q: first #EBookQuery
 * @...: %NULL terminated list of #EBookQuery pointers
 *
 * Creates a new #EBookQuery which is the logical AND of the queries specified.
 *
 * Returns: A new #EBookQuery
 **/
EBookQuery *
e_book_query_andv (EBookQuery *q, ...)
{
	EBookQuery *res;
	va_list ap;

	va_start (ap, q);
	res = conjoinv (E_BOOK_QUERY_TYPE_AND, q, ap);
	va_end (ap);

	return res;
}

/**
 * e_book_query_orv:
 * @q: first #EBookQuery
 * @...: %NULL terminated list of #EBookQuery pointers
 *
 * Creates a new #EBookQuery which is the logical OR of the queries specified.
 *
 * Returns: A new #EBookQuery
 **/
EBookQuery *
e_book_query_orv (EBookQuery *q, ...)
{
	EBookQuery *res;
	va_list ap;

	va_start (ap, q);
	res = conjoinv (E_BOOK_QUERY_TYPE_OR, q, ap);
	va_end (ap);

	return res;
}

/**
 * e_book_query_not:
 * @q: an #EBookQuery
 * @unref: if %TRUE, the new query takes ownership of the existing queries
 *
 * Creates a new #EBookQuery which is the opposite of #q.
 *
 * Returns: the new #EBookQuery
 **/
EBookQuery *
e_book_query_not (EBookQuery *q,
                  gboolean unref)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_NOT;
	ret->query.not.q = q;
	if (!unref)
		e_book_query_ref (q);

	return ret;
}

static const gchar *
address_locale (void)
{
	const gchar *locale;

#if defined (LC_ADDRESS)
	/* LC_ADDRESS is a GNU extension. */
	locale = setlocale (LC_ADDRESS, NULL);
#else
	locale = NULL;
#endif

	if (locale == NULL || strcmp (locale, "C") == 0)
		locale = setlocale (LC_MESSAGES, NULL);

	return locale;
}

static EBookQuery *
e_book_query_field_test_with_locale (EContactField field,
                                     EBookQueryTest test,
                                     const gchar *value,
                                     const gchar *locale)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_FIELD_TEST;
	ret->query.field_test.field_name = g_strdup (e_contact_field_name (field));
	ret->query.field_test.test = test;
	ret->query.field_test.value = g_strdup (value);
	ret->query.field_test.locale = g_strdup (locale ? locale : address_locale ());

	return ret;
}

/**
 * e_book_query_field_test:
 * @field: an #EContactField to test
 * @test: the test to apply
 * @value: the value to test for
 *
 * Creates a new #EBookQuery which tests @field for @value using the test @test.
 *
 * Returns: the new #EBookQuery
 **/
EBookQuery *
e_book_query_field_test (EContactField field,
                         EBookQueryTest test,
                         const gchar *value)
{
	return e_book_query_field_test_with_locale (field, test, value, NULL);
}

static EBookQuery *
e_book_query_vcard_field_test_with_locale (const gchar *field,
                                           EBookQueryTest test,
                                           const gchar *value,
                                           const gchar *locale)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_FIELD_TEST;
	ret->query.field_test.field_name = g_strdup (field);
	ret->query.field_test.test = test;
	ret->query.field_test.value = g_strdup (value);
	ret->query.field_test.locale = g_strdup (locale);

	return ret;
}

/**
 * e_book_query_vcard_field_test:
 * @field: a EVCard field name to test
 * @test: the test to apply
 * @value: the value to test for
 *
 * Creates a new #EBookQuery which tests @field for @value using the test @test.
 *
 * Returns: the new #EBookQuery
 *
 * Since: 2.22
 **/
EBookQuery *
e_book_query_vcard_field_test (const gchar *field,
                               EBookQueryTest test,
                               const gchar *value)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_FIELD_TEST;
	ret->query.field_test.field_name = g_strdup (field);
	ret->query.field_test.test = test;
	ret->query.field_test.value = g_strdup (value);

	return ret;
}

/**
 * e_book_query_field_exists:
 * @field: a #EContactField
 *
 * Creates a new #EBookQuery which tests if the field @field exists.
 * Returns: the new #EBookQuery
 **/
EBookQuery *
e_book_query_field_exists (EContactField field)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_FIELD_EXISTS;
	ret->query.exist.field = field;
	ret->query.exist.vcard_field = NULL;

	return ret;
}

/**
 * e_book_query_vcard_field_exists:
 * @field: a field name
 *
 * Creates a new #EBookQuery which tests if the field @field exists. @field
 * should be a vCard field name, such as #EVC_FN or #EVC_X_MSN.
 * Returns: the new #EBookQuery
 **/
EBookQuery *
e_book_query_vcard_field_exists (const gchar *field)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_FIELD_EXISTS;
	ret->query.exist.field = 0;
	ret->query.exist.vcard_field = g_strdup (field);

	return ret;
}

/**
 * e_book_query_any_field_contains:
 * @value: a value
 *
 * Creates a new #EBookQuery which tests if any field contains @value.
 *
 * Returns: the new #EBookQuery
 **/
EBookQuery *
e_book_query_any_field_contains (const gchar *value)
{
	EBookQuery *ret = g_new0 (EBookQuery, 1);

	ret->type = E_BOOK_QUERY_TYPE_ANY_FIELD_CONTAINS;
	ret->query.any_field_contains.value = g_strdup (value);

	return ret;
}

/**
 * e_book_query_unref:
 * @q: an #EBookQuery
 *
 * Decrement the reference count on @q. When the reference count reaches 0, @q
 * will be freed and any child queries will have e_book_query_unref() called.
 **/
void
e_book_query_unref (EBookQuery *q)
{
	gint i;

	if (q->ref_count--)
		return;

	switch (q->type) {
	case E_BOOK_QUERY_TYPE_AND:
	case E_BOOK_QUERY_TYPE_OR:
		for (i = 0; i < q->query.andor.nqs; i++)
			e_book_query_unref (q->query.andor.qs[i]);
		g_free (q->query.andor.qs);
		break;

	case E_BOOK_QUERY_TYPE_NOT:
		e_book_query_unref (q->query.not.q);
		break;

	case E_BOOK_QUERY_TYPE_FIELD_TEST:
		g_free (q->query.field_test.field_name);
		g_free (q->query.field_test.value);
		g_free (q->query.field_test.locale);
		break;

	case E_BOOK_QUERY_TYPE_FIELD_EXISTS:
		g_free (q->query.exist.vcard_field);
		break;

	case E_BOOK_QUERY_TYPE_ANY_FIELD_CONTAINS:
		g_free (q->query.any_field_contains.value);
		break;

	default:
		break;
	}

	g_free (q);
}

/**
 * e_book_query_ref:
 * @q: a #EBookQuery
 *
 * Increment the reference count on @q.
 * Returns: @q
 **/
EBookQuery *
e_book_query_ref (EBookQuery *q)
{
	q->ref_count++;
	return q;
}

typedef EBookQuery * (* EBookQueryNAry) (gint nqs,
                                         EBookQuery **qs,
                                         gboolean unref);

static ESExpResult *
func_n_ary (EBookQueryNAry make_query,
            struct _ESExp *f,
            gint argc,
            struct _ESExpResult **argv,
            gpointer data)
{
	GList **list = data;
	ESExpResult *r;
	EBookQuery **qs;

	if (argc > 0) {
		gint i;

		qs = g_new0 (EBookQuery *, argc);

		for (i = argc - 1; i >= 0; --i) {
			GList *list_head = *list;

			if (!list_head) {
				g_free (qs);

				r = e_sexp_result_new (f, ESEXP_RES_BOOL);
				r->value.boolean = TRUE;

				return r;
			}

			qs[i] = list_head->data;
			*list = g_list_delete_link(*list, list_head);
		}

		*list = g_list_prepend(*list, make_query (argc, qs, TRUE));
		g_free (qs);
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = FALSE;

	return r;
}

static ESExpResult *
func_and (struct _ESExp *f,
          gint argc,
          struct _ESExpResult **argv,
          gpointer data)
{
	return func_n_ary (e_book_query_and, f, argc, argv, data);
}

static ESExpResult *
func_or (struct _ESExp *f,
         gint argc,
         struct _ESExpResult **argv,
         gpointer data)
{
	return func_n_ary (e_book_query_or, f, argc, argv, data);
}

static ESExpResult *
func_not (struct _ESExp *f,
          gint argc,
          struct _ESExpResult **argv,
          gpointer data)
{
	GList **list = data;
	ESExpResult *r;

	/* just replace the head of the list with the NOT of it. */
	if (argc > 0) {
		EBookQuery *term = (*list)->data;
		(*list)->data = e_book_query_not (term, TRUE);
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = FALSE;

	return r;
}

static EBookQuery *
field_test_query (EBookQueryTest op,
                  const gchar *propname,
                  const gchar *value,
                  const gchar *locale)
{
	const EContactField field = e_contact_field_id (propname);

	if (field)
		return e_book_query_field_test_with_locale (field, op, value, locale);

	return e_book_query_vcard_field_test_with_locale (propname, op, value, locale);
}

static ESExpResult *
func_field_test (EBookQueryTest op,
                 struct _ESExp *f,
                 gint argc,
                 struct _ESExpResult **argv,
                 gpointer data)
{
	GList **list = data;
	ESExpResult *r;

	if (argc == 2
	    && argv[0]->type == ESEXP_RES_STRING
	    && argv[1]->type == ESEXP_RES_STRING) {
		const gchar *const propname = argv[0]->value.string;
		const gchar *const value = argv[1]->value.string;
		EBookQuery *q;

		if (op == E_BOOK_QUERY_CONTAINS
		    && strcmp (propname, "x-evolution-any-field") == 0) {
			q = e_book_query_any_field_contains (value);
		} else {
			q = field_test_query (op, propname, value, NULL);
		}

		*list = g_list_prepend (*list, q);
	} else if (argc == 3
	    && argv[0]->type == ESEXP_RES_STRING
	    && argv[1]->type == ESEXP_RES_STRING
	    && argv[2]->type == ESEXP_RES_STRING) {
		const gchar *const propname = argv[0]->value.string;
		const gchar *const value = argv[1]->value.string;
		const gchar *const locale = argv[2]->value.string;

		EBookQuery *q = field_test_query (op, propname, value, locale);
		*list = g_list_prepend (*list, q);
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = FALSE;

	return r;
}

static ESExpResult *
func_contains (struct _ESExp *f,
               gint argc,
               struct _ESExpResult **argv,
               gpointer data)
{
	return func_field_test (E_BOOK_QUERY_CONTAINS, f, argc, argv, data);
}

static ESExpResult *
func_is (struct _ESExp *f,
         gint argc,
         struct _ESExpResult **argv,
         gpointer data)
{
	return func_field_test (E_BOOK_QUERY_IS, f, argc, argv, data);
}

static ESExpResult *
func_beginswith (struct _ESExp *f,
                 gint argc,
                 struct _ESExpResult **argv,
                 gpointer data)
{
	return func_field_test (E_BOOK_QUERY_BEGINS_WITH, f, argc, argv, data);
}

static ESExpResult *
func_endswith (struct _ESExp *f,
               gint argc,
               struct _ESExpResult **argv,
               gpointer data)
{
	return func_field_test (E_BOOK_QUERY_ENDS_WITH, f, argc, argv, data);
}

static ESExpResult *
func_eqphone (struct _ESExp *f,
              gint argc,
              struct _ESExpResult **argv,
              gpointer data)
{
	return func_field_test (E_BOOK_QUERY_EQUALS_PHONE_NUMBER, f, argc, argv, data);
}

static ESExpResult *
func_eqphone_national (struct _ESExp *f,
                       gint argc,
                       struct _ESExpResult **argv,
                       gpointer data)
{
	return func_field_test (E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER, f, argc, argv, data);
}

static ESExpResult *
func_eqphone_short (struct _ESExp *f,
                    gint argc,
                    struct _ESExpResult **argv,
                    gpointer data)
{
	return func_field_test (E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER, f, argc, argv, data);
}

static ESExpResult *
func_regex_normal (struct _ESExp *f,
                   gint argc,
                   struct _ESExpResult **argv,
                   gpointer data)
{
	return func_field_test (E_BOOK_QUERY_REGEX_NORMAL, f, argc, argv, data);
}

static ESExpResult *
func_regex_raw (struct _ESExp *f,
                gint argc,
                struct _ESExpResult **argv,
                gpointer data)
{
	return func_field_test (E_BOOK_QUERY_REGEX_RAW, f, argc, argv, data);
}

static ESExpResult *
func_exists (struct _ESExp *f,
             gint argc,
             struct _ESExpResult **argv,
             gpointer data)
{
	GList **list = data;
	ESExpResult *r;

	if (argc == 1
	    && argv[0]->type == ESEXP_RES_STRING) {
		gchar *propname = argv[0]->value.string;
		EContactField field = e_contact_field_id (propname);

		if (field)
			*list = g_list_prepend (*list, e_book_query_field_exists (field));
		else
			*list = g_list_prepend (*list, e_book_query_vcard_field_exists (propname));
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = FALSE;

	return r;
}

static ESExpResult *
func_exists_vcard (struct _ESExp *f,
                   gint argc,
                   struct _ESExpResult **argv,
                   gpointer data)
{
	GList **list = data;
	ESExpResult *r;

	if (argc == 1
	    && argv[0]->type == ESEXP_RES_STRING) {
		*list = g_list_prepend (*list, e_book_query_vcard_field_exists (argv[0]->value.string));
	}

	r = e_sexp_result_new (f, ESEXP_RES_BOOL);
	r->value.boolean = FALSE;

	return r;
}

/* 'builtin' functions */
static const struct {
	const gchar *name;
	ESExpFunc *func;
	gint type;		/* set to 1 if a function can perform shortcut evaluation, or
				   doesn't execute everything, 0 otherwise */
} symbols[] = {
	{ "and", func_and, 0 },
	{ "or", func_or, 0 },
	{ "not", func_not, 0 },
	{ "contains", func_contains, 0 },
	{ "is", func_is, 0 },
	{ "beginswith", func_beginswith, 0 },
	{ "endswith", func_endswith, 0 },
	{ "eqphone", func_eqphone, 0 },
	{ "eqphone_national", func_eqphone_national, 0 },
	{ "eqphone_short", func_eqphone_short, 0 },
	{ "regex_normal", func_regex_normal, 0 },
	{ "regex_raw", func_regex_raw, 0 },
	{ "exists", func_exists, 0 },
	{ "exists_vcard", func_exists_vcard, 0 }
};

/**
 * e_book_query_from_string:
 * @query_string: the query
 *
 * Parse @query_string and return a new #EBookQuery representing it.
 *
 * Returns: the new #EBookQuery.
 **/
EBookQuery *
e_book_query_from_string (const gchar *query_string)
{
	ESExp *sexp;
	ESExpResult *r;
	EBookQuery *retval;
	GList *list = NULL;
	gint i;

	sexp = e_sexp_new ();

	for (i = 0; i < G_N_ELEMENTS (symbols); i++) {
		if (symbols[i].type == 1) {
			e_sexp_add_ifunction (sexp, 0, symbols[i].name,
					     (ESExpIFunc *) symbols[i].func, &list);
		} else {
			e_sexp_add_function (
				sexp, 0, symbols[i].name,
				symbols[i].func, &list);
		}
	}

	e_sexp_input_text (sexp, query_string, strlen (query_string));

	if (e_sexp_parse (sexp) == -1) {
		g_warning ("%s: Error in parsing: %s", G_STRFUNC, e_sexp_get_error (sexp));
		g_object_unref (sexp);
		return NULL;
	}

	r = e_sexp_eval (sexp);

	e_sexp_result_free (sexp, r);
	g_object_unref (sexp);

	if (list && list->next == NULL) {
		retval = list->data;
	} else {
		g_list_foreach (list, (GFunc) e_book_query_unref, NULL);
		g_warning ("conversion to EBookQuery failed");
		retval = NULL;
	}

	g_list_free (list);
	return retval;
}

static const gchar *
field_test_name (EBookQueryTest field_test)
{
	switch (field_test) {
	case E_BOOK_QUERY_IS:
		return "is";
	case E_BOOK_QUERY_CONTAINS:
		return "contains";
	case E_BOOK_QUERY_BEGINS_WITH:
		return "beginswith";
	case E_BOOK_QUERY_ENDS_WITH:
		return "endswith";
	case E_BOOK_QUERY_EQUALS_PHONE_NUMBER:
		return "eqphone";
	case E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER:
		return "eqphone_national";
	case E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER:
		return "eqphone_short";
	case E_BOOK_QUERY_REGEX_NORMAL:
		return "regex_normal";
	case E_BOOK_QUERY_REGEX_RAW:
		return "regex_raw";
	case E_BOOK_QUERY_LAST:
		g_return_val_if_reached (NULL);
	}

	return NULL;
}

static gboolean
is_phone_test (EBookQueryTest field_test)
{
	switch (field_test) {
	case E_BOOK_QUERY_EQUALS_PHONE_NUMBER:
	case E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER:
	case E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER:
		return TRUE;

	case E_BOOK_QUERY_IS:
	case E_BOOK_QUERY_CONTAINS:
	case E_BOOK_QUERY_BEGINS_WITH:
	case E_BOOK_QUERY_ENDS_WITH:
	case E_BOOK_QUERY_REGEX_NORMAL:
	case E_BOOK_QUERY_REGEX_RAW:
	case E_BOOK_QUERY_LAST:
		break;
	}

	return FALSE;
}

/**
 * e_book_query_to_string:
 * @q: an #EBookQuery
 *
 * Return the string representation of @q.
 *
 * Returns: The string form of the query. This string should be freed when
 * finished with.
 **/
gchar *
e_book_query_to_string (EBookQuery *q)
{
	GString *str = g_string_new ("(");
	GString *encoded = g_string_new ("");
	gint i;
	gchar *s = NULL;
	const gchar *fn;

	switch (q->type) {
	case E_BOOK_QUERY_TYPE_AND:
		g_string_append (str, "and ");
		for (i = 0; i < q->query.andor.nqs; i++) {
			s = e_book_query_to_string (q->query.andor.qs[i]);
			g_string_append (str, s);
			g_free (s);
			g_string_append_c (str, ' ');
		}
		break;
	case E_BOOK_QUERY_TYPE_OR:
		g_string_append (str, "or ");
		for (i = 0; i < q->query.andor.nqs; i++) {
			s = e_book_query_to_string (q->query.andor.qs[i]);
			g_string_append (str, s);
			g_free (s);
			g_string_append_c (str, ' ');
		}
		break;
	case E_BOOK_QUERY_TYPE_NOT:
		s = e_book_query_to_string (q->query.not.q);
		g_string_append_printf (str, "not %s", s);
		g_free (s);
		break;
	case E_BOOK_QUERY_TYPE_FIELD_EXISTS:
		if (q->query.exist.vcard_field) {
			g_string_append_printf (str, "exists_vcard \"%s\"", q->query.exist.vcard_field);
		} else {
			g_string_append_printf (str, "exists \"%s\"", e_contact_field_name (q->query.exist.field));
		}
		break;
	case E_BOOK_QUERY_TYPE_FIELD_TEST:
		fn = field_test_name (q->query.field_test.test);

		if (fn == NULL) {
			g_string_free (str, TRUE);
			g_warn_if_reached ();
			return NULL;
		}

		e_sexp_encode_string (encoded, q->query.field_test.value);

		g_string_append_printf (
			str, "%s \"%s\" %s", fn,
			q->query.field_test.field_name,
			encoded->str);

		if (is_phone_test (q->query.field_test.test))
			g_string_append_printf (str, " \"%s\"", address_locale ());

		break;
	case E_BOOK_QUERY_TYPE_ANY_FIELD_CONTAINS:
		g_string_append_printf (str, "contains \"x-evolution-any-field\"");
		e_sexp_encode_string (str, q->query.any_field_contains.value);
		break;
	}

	g_string_append (str, ")");

	g_string_free (encoded, TRUE);

	return g_string_free (str, FALSE);
}

GType
e_book_query_get_type (void)
{
	static volatile gsize type_id__volatile = 0;

	if (g_once_init_enter (&type_id__volatile)) {
		GType type_id;

		type_id = g_boxed_type_register_static (
			"EBookQuery",
			(GBoxedCopyFunc) e_book_query_copy,
			(GBoxedFreeFunc) e_book_query_unref);

		g_once_init_leave (&type_id__volatile, type_id);
	}

	return type_id__volatile;
}

/**
 * e_book_query_copy:
 * @q: an #EBookQuery
 *
 * Creates a copy of @q.
 *
 * Returns: A new #EBookQuery identical to @q.
 **/
EBookQuery *
e_book_query_copy (EBookQuery *q)
{
	gchar *str = e_book_query_to_string (q);
	EBookQuery *nq = e_book_query_from_string (str);

	g_free (str);
	return nq;
}
