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

/**
 * SECTION: e-book-cache
 * @include: libedata-book/libedata-book.h
 * @short_description: An #ECache descendant for addressbooks
 *
 * The #EBookCache is an API for storing and looking up #EContact(s)
 * in an #ECache. It also supports cursors.
 *
 * The API is thread safe, in the similar way as the #ECache is.
 *
 * Any operations which can take a lot of time to complete (depending
 * on the size of your addressbook) can be cancelled using a #GCancellable.
 *
 * Depending on your summary configuration, your mileage will vary. Refer
 * to the #ESourceBackendSummarySetup for configuring your addressbook
 * for the type of usage you mean to make of it.
 **/

#include "evolution-data-server-config.h"

#include <locale.h>
#include <string.h>
#include <errno.h>
#include <sqlite3.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "e-book-backend-sexp.h"

#include "e-book-cache.h"

#define E_BOOK_CACHE_VERSION		2
#define INSERT_MULTI_STMT_BYTES		128
#define COLUMN_DEFINITION_BYTES		32
#define GENERATED_QUERY_BYTES		1024

/* We use a 64 bitmask to track which auxiliary tables
 * are needed to satisfy a query, it's doubtful that
 * anyone will need an addressbook with 64 fields configured
 * in the summary.
 */
#define EBC_MAX_SUMMARY_FIELDS      64

/* The number of SQLite virtual machine instructions that are
 * evaluated at a time, the user passed GCancellable is
 * checked between each batch of evaluated instructions.
 */
#define EBC_CANCEL_BATCH_SIZE       200

#define EBC_ESCAPE_SEQUENCE        "ESCAPE '^'"

/* Names for custom functions */
#define EBC_FUNC_COMPARE_VCARD     "compare_vcard"
#define EBC_FUNC_EQPHONE_EXACT     "eqphone_exact"
#define EBC_FUNC_EQPHONE_NATIONAL  "eqphone_national"
#define EBC_FUNC_EQPHONE_SHORT     "eqphone_short"

/* Fallback collations are generated as with a prefix and an EContactField name */
#define EBC_COLLATE_PREFIX         "book_cache_"

/* A special vcard attribute that we use only for private vcards */
#define EBC_VCARD_SORT_KEY         "X-EVOLUTION-SORT-KEY"

/* Key names for e_cache_dup/set_key{_int} functions */
#define EBC_KEY_MULTIVALUES	"multivalues"
#define EBC_KEY_LC_COLLATE	"lc_collate"
#define EBC_KEY_COUNTRYCODE	"countrycode"

/* Suffixes for column names used to store specialized data */
#define EBC_SUFFIX_REVERSE         "reverse"
#define EBC_SUFFIX_SORT_KEY        "localized"
#define EBC_SUFFIX_PHONE           "phone"
#define EBC_SUFFIX_COUNTRY         "country"

/* Track EBookIndexType's in a bit mask  */
#define INDEX_FLAG(type)  (1 << E_BOOK_INDEX_##type)

#define EBC_COLUMN_EXTRA	"bdata"

typedef struct {
	EContactField field_id;		/* The EContact field */
	GType type;			/* The GType (only support string or gboolean) */
	const gchar *dbname;		/* The key for this field in the sqlite3 table */
	gint index;			/* Types of searches this field should support (see EBookIndexType) */
	gchar *dbname_idx_suffix;	/* dbnames for various indexes; can be NULL */
	gchar *dbname_idx_phone;
	gchar *dbname_idx_country;
	gchar *dbname_idx_sort_key;
	gchar *aux_table;		/* Name of auxiliary table for this field, for multivalued fields only */
	gchar *aux_table_symbolic;	/* Symbolic name of auxiliary table used in queries */
} SummaryField;

struct _EBookCachePrivate {
	ESource *source;		/* Optional, can be %NULL */

	/* Parameters and settings */
	gchar *locale;			/* The current locale */
	gchar *region_code;		/* Region code (for phone number parsing) */

	/* Summary configuration */
	SummaryField *summary_fields;
	gint n_summary_fields;

	ECollator *collator;		/* The ECollator to create sort keys for any sortable fields */
};

enum {
	PROP_0,
	PROP_LOCALE
};

enum {
	E164_CHANGED,
	DUP_CONTACT_REVISION,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (EBookCache, e_book_cache, E_TYPE_CACHE,
			 G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

G_DEFINE_BOXED_TYPE (EBookCacheSearchData, e_book_cache_search_data, e_book_cache_search_data_copy, e_book_cache_search_data_free)

/**
 * e_book_cache_search_data_new:
 * @uid: a contact UID; cannot be %NULL
 * @vcard: the contact as a vCard string; cannot be %NULL
 * @extra: (nullable): any extra data stored with the contact, or %NULL
 *
 * Creates a new EBookCacheSearchData prefilled with the given values.
 *
 * Returns: (transfer full): A new #EBookCacheSearchData. Free it with
 *    e_book_cache_search_data_free() when no longer needed.
 *
 * Since: 3.26
 **/
EBookCacheSearchData *
e_book_cache_search_data_new (const gchar *uid,
			      const gchar *vcard,
			      const gchar *extra)
{
	EBookCacheSearchData *data;

	g_return_val_if_fail (uid != NULL, NULL);
	g_return_val_if_fail (vcard != NULL, NULL);

	data = g_new0 (EBookCacheSearchData, 1);
	data->uid = g_strdup (uid);
	data->vcard = g_strdup (vcard);
	data->extra = g_strdup (extra);

	return data;
}

/**
 * e_book_cache_search_data_copy:
 * @data: (nullable): a source #EBookCacheSearchData to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @data. Free it with
 *    e_book_cache_search_data_free() when no longer needed.
 *    If the @data is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
EBookCacheSearchData *
e_book_cache_search_data_copy (const EBookCacheSearchData *data)
{
	if (!data)
		return NULL;

	return e_book_cache_search_data_new (data->uid, data->vcard, data->extra);
}

/**
 * e_book_cache_search_data_free:
 * @data: (nullable): an #EBookCacheSearchData
 *
 * Frees the @data structure, previously allocated with e_book_cache_search_data_new()
 * or e_book_cache_search_data_copy().
 *
 * Since: 3.26
 **/
void
e_book_cache_search_data_free (gpointer ptr)
{
	EBookCacheSearchData *data = ptr;

	if (data) {
		g_free (data->uid);
		g_free (data->vcard);
		g_free (data->extra);
		g_free (data);
	}
}

/* Default summary configuration */
static EContactField default_summary_fields[] = {
	E_CONTACT_UID,
	E_CONTACT_REV,
	E_CONTACT_FILE_AS,
	E_CONTACT_NICKNAME,
	E_CONTACT_FULL_NAME,
	E_CONTACT_GIVEN_NAME,
	E_CONTACT_FAMILY_NAME,
	E_CONTACT_EMAIL,
	E_CONTACT_TEL,
	E_CONTACT_IS_LIST,
	E_CONTACT_LIST_SHOW_ADDRESSES,
	E_CONTACT_WANTS_HTML,
	E_CONTACT_X509_CERT,
	E_CONTACT_PGP_CERT
};

/* Create indexes on full_name and email fields as autocompletion
 * queries would mainly rely on this.
 *
 * Add sort keys for name fields as those are likely targets for
 * cursor usage.
 */
static EContactField default_indexed_fields[] = {
	E_CONTACT_FULL_NAME,
	E_CONTACT_NICKNAME,
	E_CONTACT_FILE_AS,
	E_CONTACT_GIVEN_NAME,
	E_CONTACT_FAMILY_NAME,
	E_CONTACT_EMAIL,
	E_CONTACT_FILE_AS,
	E_CONTACT_FAMILY_NAME,
	E_CONTACT_GIVEN_NAME
};

static EBookIndexType default_index_types[] = {
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_PREFIX,
	E_BOOK_INDEX_SORT_KEY,
	E_BOOK_INDEX_SORT_KEY,
	E_BOOK_INDEX_SORT_KEY
};

/******************************************************
 *                  Summary Fields                    *
 ******************************************************/

static ECacheColumnInfo *
column_info_new (SummaryField *field,
                 const gchar *column_name,
                 const gchar *column_type,
                 const gchar *idx_prefix)
{
	ECacheColumnInfo *info;
	gchar *index = NULL;

	g_return_val_if_fail (column_name != NULL, NULL);

	if (field->type == E_TYPE_CONTACT_ATTR_LIST)
		column_name = "value";

	if (!column_type) {
		if (field->type == G_TYPE_STRING)
			column_type = "TEXT";
		else if (field->type == G_TYPE_BOOLEAN || field->type == E_TYPE_CONTACT_CERT)
			column_type = "INTEGER";
		else if (field->type == E_TYPE_CONTACT_ATTR_LIST)
			column_type = "TEXT";
		else
			g_warn_if_reached ();
	}

	if (idx_prefix)
		index = g_strconcat (idx_prefix, "_", field->dbname, NULL);

	info = e_cache_column_info_new (column_name, column_type, index);

	g_free (index);

	return info;
}

static gint
summary_field_array_index (GArray *array,
                           EContactField field)
{
	gint ii;

	for (ii = 0; ii < array->len; ii++) {
		SummaryField *iter = &g_array_index (array, SummaryField, ii);
		if (field == iter->field_id)
			return ii;
	}

	return -1;
}

static SummaryField *
summary_field_append (GArray *array,
		      EContactField field_id,
		      GError **error)
{
	const gchar *dbname = NULL;
	GType type = G_TYPE_INVALID;
	gint idx;
	SummaryField new_field = { 0, };

	if (field_id < 1 || field_id >= E_CONTACT_FIELD_LAST) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_UNSUPPORTED_FIELD,
			_("Unsupported contact field “%d” specified in summary"),
			field_id);

		return NULL;
	}

	/* Avoid including the same field twice in the summary */
	idx = summary_field_array_index (array, field_id);
	if (idx >= 0)
		return &g_array_index (array, SummaryField, idx);

	/* Resolve some exceptions, we store these
	 * specific contact fields with different names
	 * than those found in the EContactField table
	 */
	switch (field_id) {
	case E_CONTACT_UID:
	case E_CONTACT_REV:
		/* Skip these, it's already in the ECache */
		return NULL;
	case E_CONTACT_IS_LIST:
		dbname = "is_list";
		break;
	default:
		dbname = e_contact_field_name (field_id);
		break;
	}

	type = e_contact_field_type (field_id);

	if (type != G_TYPE_STRING &&
	    type != G_TYPE_BOOLEAN &&
	    type != E_TYPE_CONTACT_CERT &&
	    type != E_TYPE_CONTACT_ATTR_LIST) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_UNSUPPORTED_FIELD,
			_("Contact field “%s” of type “%s” specified in summary, "
			"but only boolean, string and string list field types are supported"),
			e_contact_pretty_name (field_id), g_type_name (type));

		return NULL;
	}

	if (type == E_TYPE_CONTACT_ATTR_LIST) {
		new_field.aux_table = g_strconcat ("attrlist", "_", dbname, "_list", NULL);
		new_field.aux_table_symbolic = g_strconcat (dbname, "_list", NULL);
	}

	new_field.field_id = field_id;
	new_field.dbname = dbname;
	new_field.type = type;
	new_field.index = 0;

	g_array_append_val (array, new_field);

	return &g_array_index (array, SummaryField, array->len - 1);
}

static void
summary_fields_add_indexes (GArray *array,
                            EContactField *indexes,
                            EBookIndexType *index_types,
                            gint n_indexes)
{
	gint ii, jj;

	for (ii = 0; ii < array->len; ii++) {
		SummaryField *sfield = &g_array_index (array, SummaryField, ii);

		for (jj = 0; jj < n_indexes; jj++) {
			if (sfield->field_id == indexes[jj])
				sfield->index |= (1 << index_types[jj]);

		}
	}
}

static inline gint
summary_field_get_index (EBookCache *book_cache,
                         EContactField field_id)
{
	gint ii;

	for (ii = 0; ii < book_cache->priv->n_summary_fields; ii++) {
		if (book_cache->priv->summary_fields[ii].field_id == field_id)
			return ii;
	}

	return -1;
}

static inline SummaryField *
summary_field_get (EBookCache *book_cache,
                   EContactField field_id)
{
	gint index;

	index = summary_field_get_index (book_cache, field_id);
	if (index >= 0)
		return &(book_cache->priv->summary_fields[index]);

	return NULL;
}

static void
summary_field_init_dbnames (SummaryField *field)
{
	if (field->type == G_TYPE_STRING && (field->index & INDEX_FLAG (SORT_KEY))) {
		field->dbname_idx_sort_key = g_strconcat (field->dbname, "_", EBC_SUFFIX_SORT_KEY, NULL);
	}

	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (SUFFIX)) != 0) {
		field->dbname_idx_suffix = g_strconcat (field->dbname, "_", EBC_SUFFIX_REVERSE, NULL);
	}

	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (PHONE)) != 0) {
		field->dbname_idx_phone = g_strconcat (field->dbname, "_", EBC_SUFFIX_PHONE, NULL);
		field->dbname_idx_country = g_strconcat (field->dbname, "_", EBC_SUFFIX_COUNTRY, NULL);
	}
}

static void
summary_field_prepend_columns (SummaryField *field,
			       GSList **out_columns)
{
	ECacheColumnInfo *info;

	/* Doesn't hurt to verify a bit more here, this shouldn't happen though */
	g_return_if_fail (
		field->type == G_TYPE_STRING ||
		field->type == G_TYPE_BOOLEAN ||
		field->type == E_TYPE_CONTACT_CERT ||
		field->type == E_TYPE_CONTACT_ATTR_LIST);

	/* Normal / default column */
	info = column_info_new (field, field->dbname, NULL,
		(field->index & INDEX_FLAG (PREFIX)) != 0 ? "INDEX" : NULL);
	*out_columns = g_slist_prepend (*out_columns, info);

	/* Localized column, for storing sort keys */
	if (field->type == G_TYPE_STRING && (field->index & INDEX_FLAG (SORT_KEY))) {
		info = column_info_new (field, field->dbname_idx_sort_key, "TEXT", "SINDEX");
		*out_columns = g_slist_prepend (*out_columns, info);
	}

	/* Suffix match column */
	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (SUFFIX)) != 0) {
		info = column_info_new (field, field->dbname_idx_suffix, "TEXT", "RINDEX");
		*out_columns = g_slist_prepend (*out_columns, info);
	}

	/* Phone match columns */
	if (field->type != G_TYPE_BOOLEAN && field->type != E_TYPE_CONTACT_CERT &&
	    (field->index & INDEX_FLAG (PHONE)) != 0) {

		/* One indexed column for storing the national number */
		info = column_info_new (field, field->dbname_idx_phone, "TEXT", "PINDEX");
		*out_columns = g_slist_prepend (*out_columns, info);

		/* One integer column for storing the country code */
		info = column_info_new (field, field->dbname_idx_country, "INTEGER DEFAULT 0", NULL);
		*out_columns = g_slist_prepend (*out_columns, info);
	}
}

static void
summary_fields_array_free (SummaryField *fields,
                           gint n_fields)
{
	gint ii;

	for (ii = 0; ii < n_fields; ii++) {
		g_free (fields[ii].dbname_idx_suffix);
		g_free (fields[ii].dbname_idx_phone);
		g_free (fields[ii].dbname_idx_country);
		g_free (fields[ii].dbname_idx_sort_key);
		g_free (fields[ii].aux_table);
		g_free (fields[ii].aux_table_symbolic);
	}

	g_free (fields);
}

/******************************************************
 *       Functions installed into the SQLite          *
 ******************************************************/

/* Implementation for REGEXP keyword */
static void
ebc_regexp (sqlite3_context *context,
	    gint argc,
	    sqlite3_value **argv)
{
	GRegex *regex;
	const gchar *expression;
	const gchar *text;

	/* Reuse the same GRegex for all REGEXP queries with the same expression */
	regex = sqlite3_get_auxdata (context, 0);
	if (!regex) {
		GError *error = NULL;

		expression = (const gchar *) sqlite3_value_text (argv[0]);

		regex = g_regex_new (expression, 0, 0, &error);

		if (!regex) {
			sqlite3_result_error (
				context,
				error ? error->message :
				_("Error parsing regular expression"),
				-1);
			g_clear_error (&error);
			return;
		}

		/* SQLite will take care of freeing the GRegex when we're done with the query */
		sqlite3_set_auxdata (context, 0, regex, (GDestroyNotify) g_regex_unref);
	}

	/* Now perform the comparison */
	text = (const gchar *) sqlite3_value_text (argv[1]);
	if (text != NULL) {
		gboolean match;

		match = g_regex_match (regex, text, 0, NULL);
		sqlite3_result_int (context, match ? 1 : 0);
	}
}

/* Implementation of EBC_FUNC_COMPARE_VCARD (fallback for non-summary queries) */
static void
ebc_compare_vcard (sqlite3_context *context,
		   gint argc,
		   sqlite3_value **argv)
{
	EBookBackendSExp *sexp = NULL;
	const gchar *text;
	const gchar *vcard;

	/* Reuse the same sexp for all queries with the same search expression */
	sexp = sqlite3_get_auxdata (context, 0);
	if (!sexp) {

		/* The first argument will be reused for many rows */
		text = (const gchar *) sqlite3_value_text (argv[0]);
		if (text) {
			sexp = e_book_backend_sexp_new (text);
			sqlite3_set_auxdata (
				context, 0,
				sexp,
				g_object_unref);
		}

		/* This shouldn't happen, catch invalid sexp in preflight */
		if (!sexp) {
			sqlite3_result_int (context, 0);
			return;
		}

	}

	/* Reuse the same vcard as much as possible (it can be referred to more than
	 * once in the query, so it can be reused for multiple comparisons on the same row)
	 */
	vcard = sqlite3_get_auxdata (context, 1);
	if (!vcard) {
		vcard = (const gchar *) sqlite3_value_text (argv[1]);

		if (vcard)
			sqlite3_set_auxdata (context, 1, g_strdup (vcard), g_free);
	}

	/* A NULL vcard can never match */
	if (!vcard || !*vcard) {
		sqlite3_result_int (context, 0);
		return;
	}

	/* Compare this vcard */
	if (e_book_backend_sexp_match_vcard (sexp, vcard))
		sqlite3_result_int (context, 1);
	else
		sqlite3_result_int (context, 0);
}

static void
ebc_eqphone (sqlite3_context *context,
	     gint argc,
	     sqlite3_value **argv,
	     EPhoneNumberMatch requested_match)
{
	EBookCache *ebc = sqlite3_user_data (context);
	EPhoneNumber *input_phone = NULL, *row_phone = NULL;
	EPhoneNumberMatch match = E_PHONE_NUMBER_MATCH_NONE;
	const gchar *text;

	/* Reuse the same phone number for all queries with the same phone number argument */
	input_phone = sqlite3_get_auxdata (context, 0);
	if (!input_phone) {

		/* The first argument will be reused for many rows */
		text = (const gchar *) sqlite3_value_text (argv[0]);
		if (text) {

			/* Ignore errors, they are fine for phone numbers */
			input_phone = e_phone_number_from_string (text, ebc->priv->region_code, NULL);

			/* SQLite will take care of freeing the EPhoneNumber when we're done with the expression */
			if (input_phone)
				sqlite3_set_auxdata (
					context, 0,
					input_phone,
					(GDestroyNotify) e_phone_number_free);
		}
	}

	/* This shouldn't happen, as we catch invalid phone number queries in preflight
	 */
	if (!input_phone) {
		sqlite3_result_int (context, 0);
		return;
	}

	/* Parse the phone number for this row */
	text = (const gchar *) sqlite3_value_text (argv[1]);
	if (text != NULL) {
		row_phone = e_phone_number_from_string (text, ebc->priv->region_code, NULL);

		/* And perform the comparison */
		if (row_phone) {
			match = e_phone_number_compare (input_phone, row_phone);

			e_phone_number_free (row_phone);
		}
	}

	/* Now report the result */
	if (match != E_PHONE_NUMBER_MATCH_NONE &&
	    match <= requested_match)
		sqlite3_result_int (context, 1);
	else
		sqlite3_result_int (context, 0);
}

/* Exact phone number match function: EBC_FUNC_EQPHONE_EXACT */
static void
ebc_eqphone_exact (sqlite3_context *context,
		   gint argc,
		   sqlite3_value **argv)
{
	ebc_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_EXACT);
}

/* National phone number match function: EBC_FUNC_EQPHONE_NATIONAL */
static void
ebc_eqphone_national (sqlite3_context *context,
		      gint argc,
		      sqlite3_value **argv)
{
	ebc_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_NATIONAL);
}

/* Short phone number match function: EBC_FUNC_EQPHONE_SHORT */
static void
ebc_eqphone_short (sqlite3_context *context,
		   gint argc,
		   sqlite3_value **argv)
{
	ebc_eqphone (context, argc, argv, E_PHONE_NUMBER_MATCH_SHORT);
}

typedef void	(*EBCCustomFunc)	(sqlite3_context *context,
					 gint argc,
					 sqlite3_value **argv);

typedef struct {
	const gchar *name;
	EBCCustomFunc func;
	gint arguments;
} EBCCustomFuncTab;

static EBCCustomFuncTab ebc_custom_functions[] = {
	{ "regexp",                  ebc_regexp,           2 }, /* regexp (expression, column_data) */
	{ EBC_FUNC_COMPARE_VCARD,    ebc_compare_vcard,    2 }, /* compare_vcard (sexp, vcard) */
	{ EBC_FUNC_EQPHONE_EXACT,    ebc_eqphone_exact,    2 }, /* eqphone_exact (search_input, column_data) */
	{ EBC_FUNC_EQPHONE_NATIONAL, ebc_eqphone_national, 2 }, /* eqphone_national (search_input, column_data) */
	{ EBC_FUNC_EQPHONE_SHORT,    ebc_eqphone_short,    2 }, /* eqphone_national (search_input, column_data) */
};

/******************************************************
 *            Fallback Collation Sequences            *
 ******************************************************
 *
 * The fallback simply compares vcards, vcards which have been
 * stored on the cursor will have a preencoded key (these
 * utilities encode & decode that key).
 */
static gchar *
ebc_encode_vcard_sort_key (const gchar *sort_key)
{
	EVCard *vcard = e_vcard_new ();
	gchar *base64;
	gchar *encoded;

	/* Encode this otherwise e-vcard messes it up */
	base64 = g_base64_encode ((const guchar *) sort_key, strlen (sort_key));
	e_vcard_append_attribute_with_value (
		vcard,
		e_vcard_attribute_new (NULL, EBC_VCARD_SORT_KEY),
		base64);
	encoded = e_vcard_to_string (vcard, EVC_FORMAT_VCARD_30);

	g_free (base64);
	g_object_unref (vcard);

	return encoded;
}

static gchar *
ebc_decode_vcard_sort_key_from_vcard (EVCard *vcard)
{
	EVCardAttribute *attr;
	GList *values = NULL;
	gchar *sort_key = NULL;
	gchar *base64 = NULL;

	attr = e_vcard_get_attribute (vcard, EBC_VCARD_SORT_KEY);
	if (attr)
		values = e_vcard_attribute_get_values (attr);

	if (values && values->data) {
		gsize len;

		base64 = g_strdup (values->data);

		sort_key = (gchar *) g_base64_decode (base64, &len);
		g_free (base64);
	}

	return sort_key;
}

static gchar *
ebc_decode_vcard_sort_key (const gchar *encoded)
{
	EVCard *vcard;
	gchar *sort_key;

	vcard = e_vcard_new_from_string (encoded);
	sort_key = ebc_decode_vcard_sort_key_from_vcard (vcard);
	g_object_unref (vcard);

	return sort_key;
}

static gchar *
convert_phone (const gchar *normal,
               const gchar *region_code,
               gint *out_country_code)
{
	EPhoneNumber *number = NULL;
	gchar *national_number = NULL;
	gint country_code = 0;

	/* Don't warn about erronous phone number strings, it's a perfectly normal
	 * use case for users to enter notes instead of phone numbers in the phone
	 * number contact fields, such as "Ask Jenny for Lisa's phone number"
	 */
	if (normal && e_phone_number_is_supported ())
		number = e_phone_number_from_string (normal, region_code, NULL);

	if (number) {
		EPhoneNumberCountrySource source;

		national_number = e_phone_number_get_national_number (number);
		country_code = e_phone_number_get_country_code (number, &source);
		e_phone_number_free (number);

		if (source == E_PHONE_NUMBER_COUNTRY_FROM_DEFAULT)
			country_code = 0;
	}

	if (out_country_code)
		*out_country_code = country_code;

	return national_number;
}

static gchar *
remove_leading_zeros (gchar *number)
{
	gchar *trimmed = NULL;
	gchar *tmp = number;

	g_return_val_if_fail (NULL != number, NULL);

	while ('0' == *tmp)
		tmp++;
	trimmed = g_strdup (tmp);
	g_free (number);

	return trimmed;
}

static void
ebc_fill_other_columns (EBookCache *book_cache,
			EContact *contact,
			ECacheColumnValues *other_columns)
{
	gint ii;

	g_return_if_fail (E_IS_BOOK_CACHE (book_cache));
	g_return_if_fail (E_IS_CONTACT (contact));
	g_return_if_fail (other_columns != NULL);

	for (ii = 0; ii < book_cache->priv->n_summary_fields; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);

		if (field->field_id == E_CONTACT_UID ||
		    field->field_id == E_CONTACT_REV) {
			continue;
		}

		if (field->type == G_TYPE_STRING) {
			gchar *val;
			gchar *normal;
			gchar *str;

			val = e_contact_get (contact, field->field_id);
			normal = e_util_utf8_normalize (val);

			e_cache_column_values_take_value (other_columns, field->dbname, normal);

			if ((field->index & INDEX_FLAG (SORT_KEY)) != 0) {
				if (val)
					str = e_collator_generate_key (book_cache->priv->collator, val, NULL);
				else
					str = g_strdup ("");

				e_cache_column_values_take_value (other_columns, field->dbname_idx_sort_key, str);
			}

			if ((field->index & INDEX_FLAG (SUFFIX)) != 0) {
				if (normal)
					str = g_utf8_strreverse (normal, -1);
				else
					str = NULL;

				e_cache_column_values_take_value (other_columns, field->dbname_idx_suffix, str);
			}

			if ((field->index & INDEX_FLAG (PHONE)) != 0) {
				gint country_code;

				str = convert_phone (normal, book_cache->priv->region_code, &country_code);
				str = remove_leading_zeros (str);

				e_cache_column_values_take_value (other_columns, field->dbname_idx_phone, str);

				str = g_strdup_printf ("%d", country_code);

				e_cache_column_values_take_value (other_columns, field->dbname_idx_country, str);
			}

			g_free (val);
		} else if (field->type == G_TYPE_BOOLEAN) {
			gboolean val;

			val = e_contact_get (contact, field->field_id) ? TRUE : FALSE;

			e_cache_column_values_take_value (other_columns, field->dbname, g_strdup_printf ("%d", val ? 1 : 0));
		} else if (field->type == E_TYPE_CONTACT_CERT) {
			EContactCert *cert = NULL;

			cert = e_contact_get (contact, field->field_id);

			/* We don't actually store the cert; only a boolean to indicate
			 * that is *has* a cert. */
			e_cache_column_values_take_value (other_columns, field->dbname, g_strdup_printf ("%d", cert ? 1 : 0));
			e_contact_cert_free (cert);
		} else if (field->type != E_TYPE_CONTACT_ATTR_LIST) {
			g_warn_if_reached ();
		}
	}
}

static inline void
format_column_declaration (GString *string,
			   ECacheColumnInfo *info)
{
	g_string_append (string, info->name);
	g_string_append_c (string, ' ');

	g_string_append (string, info->type);

}

static gboolean
ebc_init_aux_tables (EBookCache *book_cache,
		     GCancellable *cancellable,
		     GError **error)
{
	GString *string;
	gboolean success = TRUE;
	gchar *tmp;
	gint ii;

	for (ii = 0; success && ii < book_cache->priv->n_summary_fields; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);
		GSList *aux_columns = NULL, *link;

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		summary_field_prepend_columns (field, &aux_columns);
		if (!aux_columns)
			continue;

		/* Create the auxiliary table for this multi valued field */
		string = g_string_sized_new (
			COLUMN_DEFINITION_BYTES * 3 +
			COLUMN_DEFINITION_BYTES * g_slist_length (aux_columns));

		e_cache_sqlite_stmt_append_printf (string, "CREATE TABLE IF NOT EXISTS %Q (uid TEXT NOT NULL REFERENCES " E_CACHE_TABLE_OBJECTS
						  " (" E_CACHE_COLUMN_UID ")",
						  field->aux_table);
		for (link = aux_columns; link; link = g_slist_next (link)) {
			ECacheColumnInfo *info = link->data;

			g_string_append (string, ", ");
			format_column_declaration (string, info);
		}
		g_string_append_c (string, ')');

		success = e_cache_sqlite_exec (E_CACHE (book_cache), string->str, cancellable, error);
		g_string_free (string, TRUE);

		if (success) {
			/* Create an index on the implied 'uid' column, this is important
			 * when replacing (modifying) contacts, since we need to remove
			 * all rows in an auxiliary table which matches a given UID.
			 *
			 * This index speeds up the constraint in a statement such as:
			 *
			 *   DELETE from email_list WHERE email_list.uid = 'contact uid'
			 */
			tmp = e_cache_sqlite_stmt_printf ("CREATE INDEX IF NOT EXISTS UID_INDEX_%s_%s ON %Q (uid)",
				field->dbname, field->aux_table, field->aux_table);
			success = e_cache_sqlite_exec (E_CACHE (book_cache), tmp, cancellable, error);
			e_cache_sqlite_stmt_free (tmp);
		}

		/* Add indexes to columns in this auxiliary table
		 */
		for (link = aux_columns; success && link; link = g_slist_next (link)) {
			ECacheColumnInfo *info = link->data;

			if (info->index_name) {
				tmp = e_cache_sqlite_stmt_printf ("CREATE INDEX IF NOT EXISTS %Q ON %Q (%s)",
					info->index_name, field->aux_table, info->name);
				success = e_cache_sqlite_exec (E_CACHE (book_cache), tmp, cancellable, error);
				e_cache_sqlite_stmt_free (tmp);
			}
		}

		g_slist_free_full (aux_columns, e_cache_column_info_free);
	}

	return success;
}

static gboolean
ebc_run_multi_insert_one (ECache *cache,
                          SummaryField *field,
                          const gchar *uid,
                          const gchar *value,
			  GCancellable *cancellable,
                          GError **error)
{
	GString *stmt, *values;
	gchar *normal;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (field != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	stmt = g_string_sized_new (INSERT_MULTI_STMT_BYTES);
	values = g_string_sized_new (INSERT_MULTI_STMT_BYTES);

	normal = e_util_utf8_normalize (value);

	e_cache_sqlite_stmt_append_printf (stmt, "INSERT INTO %Q (uid, value", field->aux_table);

	if ((field->index & INDEX_FLAG (SUFFIX)) != 0) {
		g_string_append (stmt, ", value_" EBC_SUFFIX_REVERSE);

		if (normal) {
			gchar *str;

			str = g_utf8_strreverse (normal, -1);

			e_cache_sqlite_stmt_append_printf (values, ", %Q", str);

			g_free (str);
		} else {
			g_string_append (values, ", NULL");
		}
	}

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {
		EBookCache *book_cache;
		gint country_code = 0;
		gchar *str;

		g_string_append (stmt, ", value_" EBC_SUFFIX_PHONE);
		g_string_append (stmt, ", value_" EBC_SUFFIX_COUNTRY);

		book_cache = E_BOOK_CACHE (cache);
		str = convert_phone (normal, book_cache->priv->region_code, &country_code);
		str = remove_leading_zeros (str);

		if (str) {
			e_cache_sqlite_stmt_append_printf (values, ", %Q", str);
		} else {
			g_string_append (values, ",NULL");
		}

		g_string_append_printf (values, ",%d", country_code);
	}

	e_cache_sqlite_stmt_append_printf (stmt, ") VALUES (%Q, %Q", uid, normal);
	g_free (normal);

	g_string_append (stmt, values->str);
	g_string_append_c (stmt, ')');

	success = e_cache_sqlite_exec (cache, stmt->str, cancellable, error);

	g_string_free (stmt, TRUE);
	g_string_free (values, TRUE);

	return success;
}

static gboolean
ebc_run_multi_insert (ECache *cache,
		      SummaryField *field,
		      const gchar *uid,
		      EContact *contact,
		      GCancellable *cancellable,
		      GError **error)
{
	GList *values, *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (field != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	values = e_contact_get (contact, field->field_id);

	for (link = values; success && link; link = g_list_next (link)) {
		const gchar *value = link->data;

		success = ebc_run_multi_insert_one (cache, field, uid, value, cancellable, error);
	}

	/* Free the list of allocated strings */
	e_contact_attr_list_free (values);

	return success;
}

static gboolean
ebc_run_multi_delete (ECache *cache,
		      SummaryField *field,
		      const gchar *uid,
		      GCancellable *cancellable,
		      GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (field != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	stmt = e_cache_sqlite_stmt_printf ("DELETE FROM %Q WHERE uid=%Q", field->aux_table, uid);
	success = e_cache_sqlite_exec (cache, stmt, cancellable, error);
	e_cache_sqlite_stmt_free (stmt);

	return success;
}

static gboolean
ebc_update_aux_tables (ECache *cache,
		       const gchar *uid,
		       const gchar *revision,
		       const gchar *object,
		       GCancellable *cancellable,
		       GError **error)
{
	EBookCache *book_cache;
	EContact *contact = NULL;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);

	book_cache = E_BOOK_CACHE (cache);

	for (ii = 0; ii < book_cache->priv->n_summary_fields && success; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		if (!contact) {
			contact = e_contact_new_from_vcard_with_uid (object, uid);
			success = contact != NULL;
		}

		success = success && ebc_run_multi_delete (cache, field, uid, cancellable, error);
		success = success && ebc_run_multi_insert (cache, field, uid, contact, cancellable, error);
	}

	g_clear_object (&contact);

	return success;
}

static gboolean
ebc_delete_from_aux_tables (ECache *cache,
			    const gchar *uid,
			    GCancellable *cancellable,
			    GError **error)
{
	EBookCache *book_cache;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	book_cache = E_BOOK_CACHE (cache);

	for (ii = 0; ii < book_cache->priv->n_summary_fields && success; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		success = success && ebc_run_multi_delete (cache, field, uid, cancellable, error);
	}

	return success;
}

static gboolean
ebc_delete_from_aux_tables_offline_deleted (ECache *cache,
					    GCancellable *cancellable,
					    GError **error)
{
	EBookCache *book_cache;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);

	book_cache = E_BOOK_CACHE (cache);

	for (ii = 0; ii < book_cache->priv->n_summary_fields && success; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);
		gchar *stmt;

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		stmt = e_cache_sqlite_stmt_printf ("DELETE FROM %Q WHERE uid IN ("
			"SELECT " E_CACHE_COLUMN_UID " FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_STATE "=%d)",
			field->aux_table, E_OFFLINE_STATE_LOCALLY_DELETED);

		success = e_cache_sqlite_exec (cache, stmt, cancellable, error);

		e_cache_sqlite_stmt_free (stmt);
	}

	return success;
}

static gboolean
ebc_empty_aux_tables (ECache *cache,
		      GCancellable *cancellable,
		      GError **error)
{
	EBookCache *book_cache;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);

	book_cache = E_BOOK_CACHE (cache);

	for (ii = 0; ii < book_cache->priv->n_summary_fields && success; ii++) {
		SummaryField *field = &(book_cache->priv->summary_fields[ii]);
		gchar *stmt;

		if (field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		stmt = e_cache_sqlite_stmt_printf ("DELETE FROM %Q", field->aux_table);
		success = e_cache_sqlite_exec (cache, stmt, cancellable, error);
		e_cache_sqlite_stmt_free (stmt);
	}

	return success;
}

static gboolean
ebc_upgrade_cb (ECache *cache,
		const gchar *uid,
		const gchar *revision,
		const gchar *object,
		EOfflineState offline_state,
		gint ncols,
		const gchar *column_names[],
		const gchar *column_values[],
		gchar **out_revision,
		gchar **out_object,
		EOfflineState *out_offline_state,
		ECacheColumnValues **out_other_columns,
		gpointer user_data)
{
	EContact *contact;
	ECacheColumnValues *other_columns;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);

	contact = e_contact_new_from_vcard_with_uid (object, uid);

	/* Ignore broken rows? */
	if (!contact)
		return TRUE;

	other_columns = e_cache_column_values_new ();

	ebc_fill_other_columns (E_BOOK_CACHE (cache), contact, other_columns);

	g_clear_object (&contact);

	/* This will cause rewrite even when no values changed, but it's
	   necessary, because the locale changed, which can influence
	   other tables, not only the other columns. */
	*out_other_columns = other_columns;

	return TRUE;
}

/* Called with the lock held and inside a transaction */
static gboolean
ebc_upgrade (EBookCache *book_cache,
	     GCancellable *cancellable,
	     GError **error)
{
	gboolean success;

	success = e_cache_foreach_update (E_CACHE (book_cache), E_CACHE_EXCLUDE_DELETED, NULL,
		ebc_upgrade_cb, NULL, cancellable, error);

	/* Store the new locale & country code */
	success = success && e_cache_set_key (E_CACHE (book_cache), EBC_KEY_LC_COLLATE, book_cache->priv->locale, error);
	success = success && e_cache_set_key (E_CACHE (book_cache), EBC_KEY_COUNTRYCODE, book_cache->priv->region_code, error);

	return success;
}

static gboolean
ebc_set_locale_internal (EBookCache *book_cache,
			 const gchar *locale,
			 GError **error)
{
	ECollator *collator;

	g_return_val_if_fail (locale && locale[0], FALSE);

	if (g_strcmp0 (book_cache->priv->locale, locale) != 0) {
		gchar *country_code = NULL;

		collator = e_collator_new_interpret_country (locale, &country_code, error);
		if (collator == NULL)
			return FALSE;

		/* Assign region code parsed from the locale by ICU */
		g_free (book_cache->priv->region_code);
		book_cache->priv->region_code = country_code;

		/* Assign locale */
		g_free (book_cache->priv->locale);
		book_cache->priv->locale = g_strdup (locale);

		/* Assign collator */
		if (book_cache->priv->collator)
			e_collator_unref (book_cache->priv->collator);
		book_cache->priv->collator = collator;
	}

	return TRUE;
}

static gboolean
ebc_init_locale (EBookCache *book_cache,
		 GCancellable *cancellable,
		 GError **error)
{
	gchar *stored_lc_collate;
	gchar *stored_region_code;
	const gchar *lc_collate;
	gboolean success = TRUE;
	gboolean relocalize_needed = FALSE;

	/* Get the locale setting for this addressbook */
	stored_lc_collate = e_cache_dup_key (E_CACHE (book_cache), EBC_KEY_LC_COLLATE, NULL);
	stored_region_code = e_cache_dup_key (E_CACHE (book_cache), EBC_KEY_COUNTRYCODE, NULL);

	lc_collate = stored_lc_collate;

	/* When creating a new addressbook, or upgrading from a version
	 * where we did not have any locale setting; default to system locale,
	 * we must absolutely always have a locale set.
	 */
	if (!lc_collate || !lc_collate[0])
		lc_collate = setlocale (LC_COLLATE, NULL);
	if (!lc_collate || !lc_collate[0])
		lc_collate = setlocale (LC_ALL, NULL);
	if (!lc_collate || !lc_collate[0])
		lc_collate = "en_US.utf8";

	/* Before touching any data, make sure we have a valid ECollator,
	 * this will also resolve our region code
	 */
	if (success)
		success = ebc_set_locale_internal (book_cache, lc_collate, error);

	/* Check if we need to relocalize */
	if (success) {
		/* We may need to relocalize for a country code change */
		if (g_strcmp0 (book_cache->priv->region_code, stored_region_code) != 0)
			relocalize_needed = TRUE;
	}

	/* Reinsert all contacts with new locale & country code */
	if (success && relocalize_needed)
		success = ebc_upgrade (book_cache, cancellable, error);

	g_free (stored_region_code);
	g_free (stored_lc_collate);

	return success;
}

typedef struct {
	EBookCache *book_cache;
	EContactField field;
} EBCCollData;

static gint
ebc_fallback_collator (gpointer ref,
		       gint len1,
		       gconstpointer data1,
		       gint len2,
		       gconstpointer data2)
{
	EBCCollData *data = ref;
	EBookCache *book_cache;
	EContact *contact1, *contact2;
	const gchar *str1, *str2;
	gchar *key1, *key2;
	gchar *tmp;
	gint result = 0;

	book_cache = data->book_cache;

	str1 = (const gchar *) data1;
	str2 = (const gchar *) data2;

	/* Construct 2 contacts (we're comparing vcards) */
	contact1 = e_contact_new ();
	contact2 = e_contact_new ();
	e_vcard_construct_full (E_VCARD (contact1), str1, len1, NULL);
	e_vcard_construct_full (E_VCARD (contact2), str2, len2, NULL);

	/* Extract first key */
	key1 = ebc_decode_vcard_sort_key_from_vcard (E_VCARD (contact1));
	if (!key1) {
		tmp = e_contact_get (contact1, data->field);
		if (tmp)
			key1 = e_collator_generate_key (book_cache->priv->collator, tmp, NULL);
		g_free (tmp);
	}
	if (!key1)
		key1 = g_strdup ("");

	/* Extract second key */
	key2 = ebc_decode_vcard_sort_key_from_vcard (E_VCARD (contact2));
	if (!key2) {
		tmp = e_contact_get (contact2, data->field);
		if (tmp)
			key2 = e_collator_generate_key (book_cache->priv->collator, tmp, NULL);
		g_free (tmp);
	}
	if (!key2)
		key2 = g_strdup ("");

	result = strcmp (key1, key2);

	g_free (key1);
	g_free (key2);
	g_object_unref (contact1);
	g_object_unref (contact2);

	return result;
}

static EBCCollData *
ebc_coll_data_new (EBookCache *book_cache,
		   EContactField field)
{
	EBCCollData *data = g_slice_new (EBCCollData);

	data->book_cache = book_cache;
	data->field = field;

	return data;
}

static void
ebc_coll_data_free (EBCCollData *data)
{
	if (data)
		g_slice_free (EBCCollData, data);
}

/* COLLATE functions are generated on demand only */
static void
ebc_generate_collator (gpointer ref,
		       sqlite3 *db,
		       gint eTextRep,
		       const gchar *coll_name)
{
	EBookCache *book_cache = ref;
	EBCCollData *data;
	EContactField field;
	const gchar *field_name;

	field_name = coll_name + strlen (EBC_COLLATE_PREFIX);
	field = e_contact_field_id (field_name);

	/* This should be caught before reaching here, just an extra check */
	if (field == 0 || field >= E_CONTACT_FIELD_LAST ||
	    e_contact_field_type (field) != G_TYPE_STRING) {
		g_warning ("Specified collation on invalid contact field");
		return;
	}

	data = ebc_coll_data_new (book_cache, field);
	sqlite3_create_collation_v2 (
		db, coll_name, SQLITE_UTF8,
		data, ebc_fallback_collator,
		(GDestroyNotify) ebc_coll_data_free);
}

/***************************************************************
 * Structures and utilities for preflight and query generation *
 ***************************************************************/

/* This enumeration is ordered by severity, higher values
 * of PreflightStatus take precedence in error reporting.
 */
typedef enum {
	PREFLIGHT_OK = 0,
	PREFLIGHT_LIST_ALL,
	PREFLIGHT_NOT_SUMMARIZED,
	PREFLIGHT_INVALID,
	PREFLIGHT_UNSUPPORTED,
} PreflightStatus;

/* Whether we can satisfy the constraints or whether we
 * need to do a fallback, we still need to call
 * ebc_generate_constraints()
 */
#define EBC_STATUS_GEN_CONSTRAINTS(status) \
	((status) == PREFLIGHT_OK || \
	 (status) == PREFLIGHT_NOT_SUMMARIZED)

/* Internal extension of the EBookQueryTest enumeration */
enum {
	/* 'exists' is a supported query on a field, but not part of EBookQueryTest */
	BOOK_QUERY_EXISTS = E_BOOK_QUERY_LAST,
	BOOK_QUERY_EXISTS_VCARD,

	/* From here the compound types start */
	BOOK_QUERY_SUB_AND,
	BOOK_QUERY_SUB_OR,
	BOOK_QUERY_SUB_NOT,
	BOOK_QUERY_SUB_END,

	BOOK_QUERY_SUB_FIRST = BOOK_QUERY_SUB_AND,
};

#define EBC_QUERY_TYPE_STR(query) \
	((query) == BOOK_QUERY_EXISTS ? "exists" : \
	 (query) == BOOK_QUERY_EXISTS_VCARD ? "exists_vcard" : \
	 (query) == BOOK_QUERY_SUB_AND ? "AND" : \
	 (query) == BOOK_QUERY_SUB_OR ? "OR" : \
	 (query) == BOOK_QUERY_SUB_NOT ? "NOT" : \
	 (query) == BOOK_QUERY_SUB_END ? "END" : \
	 (query) == E_BOOK_QUERY_IS ? "is" : \
	 (query) == E_BOOK_QUERY_CONTAINS ? "contains" : \
	 (query) == E_BOOK_QUERY_BEGINS_WITH ? "begins-with" : \
	 (query) == E_BOOK_QUERY_ENDS_WITH ? "ends-with" : \
	 (query) == E_BOOK_QUERY_EQUALS_PHONE_NUMBER ? "eqphone" : \
	 (query) == E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER ? "eqphone-national" : \
	 (query) == E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER ? "eqphone-short" : \
	 (query) == E_BOOK_QUERY_REGEX_NORMAL ? "regex-normal" : \
	 (query) == E_BOOK_QUERY_REGEX_NORMAL ? "regex-raw" : "(unknown)")

#define EBC_FIELD_ID_STR(field_id) \
	((field_id) == E_CONTACT_FIELD_LAST ? "x-evolution-any-field" : \
	 (field_id) == 0 ? "(not an EContactField)" : \
	 e_contact_field_name (field_id))

#define IS_QUERY_PHONE(query) \
	((query) == E_BOOK_QUERY_EQUALS_PHONE_NUMBER || \
	 (query) == E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER || \
	 (query) == E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER)

typedef struct {
	guint          query; /* EBookQueryTest (extended) */
} QueryElement;

typedef struct {
	guint          query; /* EBookQueryTest (extended) */
} QueryDelimiter;

typedef struct {
	guint          query;          /* EBookQueryTest (extended) */

	EContactField  field_id;       /* The EContactField to compare */
	SummaryField  *field;          /* The summary field for 'field' */
	gchar         *value;          /* The value to compare with */

} QueryFieldTest;

typedef struct {
	guint          query;          /* EBookQueryTest (extended) */

	/* Common fields from QueryFieldTest */
	EContactField  field_id;       /* The EContactField to compare */
	SummaryField  *field;          /* The summary field for 'field' */
	gchar         *value;          /* The value to compare with */

	/* Extension */
	gchar         *region;   /* Region code from the query input */
	gchar         *national; /* Parsed national number */
	gint           country;  /* Parsed country code */
} QueryPhoneTest;

/* Stack initializer for the PreflightContext struct below */
#define PREFLIGHT_CONTEXT_INIT { PREFLIGHT_OK, NULL, 0, FALSE }

typedef struct {
	PreflightStatus  status;         /* result status */
	GPtrArray       *constraints;    /* main query; may be NULL */
	guint64          aux_mask;       /* Bitmask of which auxiliary tables are needed in the query */
	guint64          left_join_mask; /* Do we need to use a LEFT JOIN */
} PreflightContext;

static QueryElement *
query_delimiter_new (guint query)
{
	QueryDelimiter *delim;

	g_return_val_if_fail (query >= BOOK_QUERY_SUB_FIRST, NULL);

	delim = g_slice_new (QueryDelimiter);
	delim->query = query;

	return (QueryElement *) delim;
}

static QueryFieldTest *
query_field_test_new (guint query,
		      EContactField field)
{
	QueryFieldTest *test;

	g_return_val_if_fail (query < BOOK_QUERY_SUB_FIRST, NULL);
	g_return_val_if_fail (IS_QUERY_PHONE (query) == FALSE, NULL);

	test = g_slice_new (QueryFieldTest);
	test->query = query;
	test->field_id = field;

	/* Instead of g_slice_new0, NULL them out manually */
	test->field = NULL;
	test->value = NULL;

	return test;
}

static QueryPhoneTest *
query_phone_test_new (guint query,
		      EContactField field)
{
	QueryPhoneTest *test;

	g_return_val_if_fail (IS_QUERY_PHONE (query), NULL);

	test = g_slice_new (QueryPhoneTest);
	test->query = query;
	test->field_id = field;

	/* Instead of g_slice_new0, NULL them out manually */
	test->field = NULL;
	test->value = NULL;

	/* Extra QueryPhoneTest fields */
	test->region = NULL;
	test->national = NULL;
	test->country = 0;

	return test;
}

static void
query_element_free (QueryElement *element)
{
	if (element) {

		if (element->query >= BOOK_QUERY_SUB_FIRST) {
			QueryDelimiter *delim = (QueryDelimiter *) element;

			g_slice_free (QueryDelimiter, delim);
		} else if (IS_QUERY_PHONE (element->query)) {
			QueryPhoneTest *test = (QueryPhoneTest *) element;

			g_free (test->value);
			g_free (test->region);
			g_free (test->national);
			g_slice_free (QueryPhoneTest, test);
		} else {
			QueryFieldTest *test = (QueryFieldTest *) element;

			g_free (test->value);
			g_slice_free (QueryFieldTest, test);
		}
	}
}

/* We use ptr arrays for the QueryElement vectors */
static inline void
constraints_insert (GPtrArray *array,
		    gint idx,
		    gpointer data)
{
	g_return_if_fail ((idx >= -1) && (idx < (gint) array->len + 1));

	if (idx < 0)
		idx = array->len;

	g_ptr_array_add (array, NULL);

	if (idx != (array->len - 1))
		memmove (
			&(array->pdata[idx + 1]),
			&(array->pdata[idx]),
			((array->len - 1) - idx) * sizeof (gpointer));

	array->pdata[idx] = data;
}

static inline void
constraints_insert_delimiter (GPtrArray *array,
			      gint idx,
			      guint query)
{
	QueryElement *delim;

	delim = query_delimiter_new (query);
	constraints_insert (array, idx, delim);
}

static inline void
constraints_insert_field_test (GPtrArray *array,
			       gint idx,
			       SummaryField *field,
			       guint query,
			       const gchar *value)
{
	QueryFieldTest *test;

	test = query_field_test_new (query, field->field_id);
	test->field = field;
	test->value = g_strdup (value);

	constraints_insert (array, idx, test);
}

static void
preflight_context_clear (PreflightContext *context)
{
	if (context) {
		/* Free any allocated data, but leave the context values in place */
		if (context->constraints)
			g_ptr_array_free (context->constraints, TRUE);
		context->constraints = NULL;
	}
}

/* A small API to track the current sub-query context.
 *
 * I.e. sub contexts can be OR, AND, or NOT, in which
 * field tests or other sub contexts are nested.
 *
 * The 'count' field is a simple counter of how deep the contexts are nested.
 *
 * The 'cond_count' field is to be used by the caller for its own purposes;
 * it is incremented in sub_query_context_push() only if the inc_cond_count
 * parameter is TRUE. This is used by query_preflight_check() in a complex
 * fashion which is described there.
 */
typedef GQueue SubQueryContext;

typedef struct {
	guint sub_type; /* The type of this sub context */
	guint count;    /* The number of field tests so far in this context */
	guint cond_count; /* User-specific conditional counter */
} SubQueryData;

#define sub_query_context_new g_queue_new
#define sub_query_context_free(ctx) g_queue_free (ctx)

static inline void
sub_query_context_push (SubQueryContext *ctx,
			guint sub_type,
			gboolean inc_cond_count)
{
	SubQueryData *data, *prev;

	prev = g_queue_peek_tail (ctx);

	data = g_slice_new (SubQueryData);
	data->sub_type = sub_type;
	data->count = 0;
	data->cond_count = prev ? prev->cond_count : 0;
	if (inc_cond_count)
		data->cond_count++;

	g_queue_push_tail (ctx, data);
}

static inline void
sub_query_context_pop (SubQueryContext *ctx)
{
	SubQueryData *data;

	data = g_queue_pop_tail (ctx);
	g_slice_free (SubQueryData, data);
}

static inline guint
sub_query_context_peek_type (SubQueryContext *ctx)
{
	SubQueryData *data;

	data = g_queue_peek_tail (ctx);

	return data->sub_type;
}

static inline guint
sub_query_context_peek_cond_counter (SubQueryContext *ctx)
{
	SubQueryData *data;

	data = g_queue_peek_tail (ctx);

	if (data)
		return data->cond_count;
	else
		return 0;
}

/* Returns the context field test count before incrementing */
static inline guint
sub_query_context_increment (SubQueryContext *ctx)
{
	SubQueryData *data;

	data = g_queue_peek_tail (ctx);

	if (data) {
		data->count++;

		return (data->count - 1);
	}

	/* If we're not in a sub context, just return 0 */
	return 0;
}

/**********************************************************
 *                  Querying preflighting                 *
 **********************************************************
 *
 * The preflight checks are performed before a query might
 * take place in order to evaluate whether the given query
 * can be performed with the current summary configuration.
 *
 * After preflighting, all relevant data has been extracted
 * from the search expression and the search expression need
 * not be parsed again.
 */

/* The PreflightSubCallback is expected to return TRUE
 * to keep iterating and FALSE to abort iteration.
 *
 * The sub_level is the counter of how deep the 'element'
 * is nested in sub elements, the offset is the real offset
 * of 'element' in the array passed to query_preflight_foreach_sub().
 */
typedef gboolean (* PreflightSubCallback) (QueryElement *element,
					   gint          sub_level,
					   gint          offset,
					   gpointer      user_data);

static void
query_preflight_foreach_sub (QueryElement **elements,
			     gint n_elements,
			     gint offset,
			     gboolean include_delim,
			     PreflightSubCallback callback,
			     gpointer user_data)
{
	gint sub_counter = 1, ii;

	g_return_if_fail (offset >= 0 && offset < n_elements);
	g_return_if_fail (elements[offset]->query >= BOOK_QUERY_SUB_FIRST);
	g_return_if_fail (callback != NULL);

	if (include_delim && !callback (elements[offset], 0, offset, user_data))
		return;

	for (ii = (offset + 1); sub_counter > 0 && ii < n_elements; ii++) {

		if (elements[ii]->query >= BOOK_QUERY_SUB_FIRST) {

			if (elements[ii]->query == BOOK_QUERY_SUB_END)
				sub_counter--;
			else
				sub_counter++;

			if (include_delim &&
			    !callback (elements[ii], sub_counter, ii, user_data))
				break;
		} else {

			if (!callback (elements[ii], sub_counter, ii, user_data))
				break;
		}
	}
}

/* Table used in ESExp parsing below */
static const struct {
	const gchar *name;    /* Name of the symbol to match for this parse phase */
	gboolean     subset;  /* TRUE for the subset ESExpIFunc, otherwise the field check ESExpFunc */
	guint        test;    /* Extended EBookQueryTest value */
} check_symbols[] = {
	{ "and",              TRUE, BOOK_QUERY_SUB_AND },
	{ "or",               TRUE, BOOK_QUERY_SUB_OR },
	{ "not",              TRUE, BOOK_QUERY_SUB_NOT },

	{ "contains",         FALSE, E_BOOK_QUERY_CONTAINS },
	{ "is",               FALSE, E_BOOK_QUERY_IS },
	{ "beginswith",       FALSE, E_BOOK_QUERY_BEGINS_WITH },
	{ "endswith",         FALSE, E_BOOK_QUERY_ENDS_WITH },
	{ "eqphone",          FALSE, E_BOOK_QUERY_EQUALS_PHONE_NUMBER },
	{ "eqphone_national", FALSE, E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER },
	{ "eqphone_short",    FALSE, E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER },
	{ "regex_normal",     FALSE, E_BOOK_QUERY_REGEX_NORMAL },
	{ "regex_raw",        FALSE, E_BOOK_QUERY_REGEX_RAW },
	{ "exists",           FALSE, BOOK_QUERY_EXISTS },
	{ "exists_vcard",     FALSE, BOOK_QUERY_EXISTS_VCARD }
};

/* Cheat our way into passing mode data to these funcs */
static ESExpResult *
func_check_subset (ESExp *f,
		   gint argc,
		   struct _ESExpTerm **argv,
		   gpointer data)
{
	ESExpResult *result, *sub_result;
	GPtrArray *result_array;
	QueryElement *element, **sub_elements;
	gint ii, jj, len;
	guint query_type;

	query_type = GPOINTER_TO_UINT (data);

	/* The compound query delimiter is the first element in this return array */
	result_array = g_ptr_array_new_with_free_func ((GDestroyNotify) query_element_free);
	element = query_delimiter_new (query_type);
	g_ptr_array_add (result_array, element);

	for (ii = 0; ii < argc; ii++) {
		sub_result = e_sexp_term_eval (f, argv[ii]);

		if (sub_result->type == ESEXP_RES_ARRAY_PTR) {
			/* Steal the elements directly from the sub result */
			sub_elements = (QueryElement **) sub_result->value.ptrarray->pdata;
			len = sub_result->value.ptrarray->len;

			for (jj = 0; jj < len; jj++) {
				element = sub_elements[jj];
				sub_elements[jj] = NULL;

				g_ptr_array_add (result_array, element);
			}
		}
		e_sexp_result_free (f, sub_result);
	}

	/* The last element in this return array is the sub end delimiter */
	element = query_delimiter_new (BOOK_QUERY_SUB_END);
	g_ptr_array_add (result_array, element);

	result = e_sexp_result_new (f, ESEXP_RES_ARRAY_PTR);
	result->value.ptrarray = result_array;

	return result;
}

static ESExpResult *
func_check (struct _ESExp *f,
	    gint argc,
	    struct _ESExpResult **argv,
	    gpointer data)
{
	ESExpResult *result;
	GPtrArray *result_array;
	QueryElement *element = NULL;
	EContactField field_id = 0;
	const gchar *query_name = NULL;
	const gchar *query_value = NULL;
	const gchar *query_extra = NULL;
	guint query_type;

	query_type = GPOINTER_TO_UINT (data);

	if (argc == 1 && query_type == BOOK_QUERY_EXISTS &&
	    argv[0]->type == ESEXP_RES_STRING) {
		query_name = argv[0]->value.string;

		field_id = e_contact_field_id (query_name);
	} else if (argc == 2 &&
	    argv[0]->type == ESEXP_RES_STRING &&
	    argv[1]->type == ESEXP_RES_STRING) {
		query_name = argv[0]->value.string;
		query_value = argv[1]->value.string;

		/* We use E_CONTACT_FIELD_LAST to hold the special case of "x-evolution-any-field" */
		if (g_strcmp0 (query_name, "x-evolution-any-field") == 0)
			field_id = E_CONTACT_FIELD_LAST;
		else
			field_id = e_contact_field_id (query_name);

	} else if (argc == 3 &&
		   argv[0]->type == ESEXP_RES_STRING &&
		   argv[1]->type == ESEXP_RES_STRING &&
		   argv[2]->type == ESEXP_RES_STRING) {
		query_name = argv[0]->value.string;
		query_value = argv[1]->value.string;
		query_extra = argv[2]->value.string;

		field_id = e_contact_field_id (query_name);
	}

	if (IS_QUERY_PHONE (query_type)) {
		QueryPhoneTest *test;

		/* Collect data from this field test */
		test = query_phone_test_new (query_type, field_id);
		test->value = g_strdup (query_value);
		test->region = g_strdup (query_extra);

		element = (QueryElement *) test;
	} else {
		QueryFieldTest *test;

		/* Collect data from this field test */
		test = query_field_test_new (query_type, field_id);
		test->value = g_strdup (query_value);

		element = (QueryElement *) test;
	}

	/* Return an array with only one element, for lack of a pointer type ESExpResult */
	result_array = g_ptr_array_new_with_free_func ((GDestroyNotify) query_element_free);
	g_ptr_array_add (result_array, element);

	result = e_sexp_result_new (f, ESEXP_RES_ARRAY_PTR);
	result->value.ptrarray = result_array;

	return result;
}

/* Initial stage of preflighting:
 *
 *  o Parse the search expression and generate our array of QueryElements
 *  o Collect lengths of query terms
 */
static void
query_preflight_initialize (PreflightContext *context,
			    const gchar *sexp)
{
	ESExp *sexp_parser;
	ESExpResult *result;
	gint esexp_error, ii;

	if (!sexp || !*sexp || g_strcmp0 (sexp, "#t") == 0) {
		context->status = PREFLIGHT_LIST_ALL;
		return;
	}

	sexp_parser = e_sexp_new ();

	for (ii = 0; ii < G_N_ELEMENTS (check_symbols); ii++) {
		if (check_symbols[ii].subset) {
			e_sexp_add_ifunction (
				sexp_parser, 0, check_symbols[ii].name,
				func_check_subset,
				GUINT_TO_POINTER (check_symbols[ii].test));
		} else {
			e_sexp_add_function (
				sexp_parser, 0, check_symbols[ii].name,
				func_check,
				GUINT_TO_POINTER (check_symbols[ii].test));
		}
	}

	e_sexp_input_text (sexp_parser, sexp, strlen (sexp));
	esexp_error = e_sexp_parse (sexp_parser);

	if (esexp_error == -1) {
		context->status = PREFLIGHT_INVALID;
	} else {
		result = e_sexp_eval (sexp_parser);
		if (result) {
			if (result->type == ESEXP_RES_ARRAY_PTR) {
				/* Just steal the array away from the ESexpResult */
				context->constraints = result->value.ptrarray;
				result->value.ptrarray = NULL;
			} else {
				context->status = PREFLIGHT_INVALID;
			}
		}

		e_sexp_result_free (sexp_parser, result);
	}

	g_object_unref (sexp_parser);
}

typedef struct {
	EBookCache *book_cache;
	SummaryField *field;
	gboolean condition;
} AttrListCheckData;

static gboolean
check_has_attr_list_cb (QueryElement *element,
			gint sub_level,
			gint offset,
			gpointer user_data)
{
	QueryFieldTest *test = (QueryFieldTest *) element;
	AttrListCheckData *data = (AttrListCheckData *) user_data;

	/* We havent resolved all the fields at this stage yet */
	if (!test->field)
		test->field = summary_field_get (data->book_cache, test->field_id);

	if (test->field && test->field->type == E_TYPE_CONTACT_ATTR_LIST)
		data->condition = TRUE;

	/* Keep looping until we find one */
	return !data->condition;
}

static gboolean
check_different_fields_cb (QueryElement *element,
			   gint sub_level,
			   gint offset,
			   gpointer user_data)
{
	QueryFieldTest *test = (QueryFieldTest *) element;
	AttrListCheckData *data = (AttrListCheckData *) user_data;

	/* We havent resolved all the fields at this stage yet */
	if (!test->field)
		test->field = summary_field_get (data->book_cache, test->field_id);

	if (test->field && data->field && test->field != data->field)
		data->condition = TRUE;
	else
		data->field = test->field;

	/* Keep looping until we find one */
	return !data->condition;
}

/* What is done in this pass:
 *  o Viability of the query is analyzed, i.e. can it be done with the summary columns.
 *  o Phone numbers are parsed and loaded onto QueryPhoneTests
 *  o Bitmask of auxiliary tables is collected
 */
static void
query_preflight_check (PreflightContext *context,
		       EBookCache *book_cache)
{
	gint ii, n_elements;
	QueryElement **elements;
	SubQueryContext *ctx;

	context->status = PREFLIGHT_OK;

	if (context->constraints != NULL) {
		elements = (QueryElement **) context->constraints->pdata;
		n_elements = context->constraints->len;
	} else {
		elements = NULL;
		n_elements = 0;
	}

	ctx = sub_query_context_new ();

	for (ii = 0; ii < n_elements; ii++) {
		QueryFieldTest *test;
		guint field_test;

		if (elements[ii]->query >= BOOK_QUERY_SUB_FIRST) {
			AttrListCheckData data = { book_cache, NULL, FALSE };

			switch (elements[ii]->query) {
			case BOOK_QUERY_SUB_OR:
				/* An OR doesn't have to force us to use a LEFT JOIN, as long
				   as all its sub-conditions are on the same field. */
				query_preflight_foreach_sub (elements,
							     n_elements,
							     ii, FALSE,
							     check_different_fields_cb,
							     &data);
				/* falls through */
			case BOOK_QUERY_SUB_AND:
				sub_query_context_push (ctx, elements[ii]->query, data.condition);
				break;
			case BOOK_QUERY_SUB_END:
				sub_query_context_pop (ctx);
				break;

			/* It's too complicated to properly perform
			 * the unary NOT operator on a constraint which
			 * accesses attribute lists.
			 *
			 * Hint, if the contact has a "%.com" email address
			 * and a "%.org" email address, what do we return
			 * for (not (endswith "email" ".com") ?
			 *
			 * Currently we rely on DISTINCT to sort out
			 * muliple results from the attribute list tables,
			 * this breaks down with NOT.
			 */
			case BOOK_QUERY_SUB_NOT:
				query_preflight_foreach_sub (elements,
							     n_elements,
							     ii, FALSE,
							     check_has_attr_list_cb,
							     &data);

				if (data.condition) {
					context->status = MAX (
						context->status,
						PREFLIGHT_NOT_SUMMARIZED);
				}
				break;

			default:
				g_warn_if_reached ();
			}

			continue;
		}

		test = (QueryFieldTest *) elements[ii];
		field_test = (EBookQueryTest) test->query;

		if (!test->field)
			test->field = summary_field_get (book_cache, test->field_id);

		/* Even if the field is not in the summary, we need to
		 * retport unsupported errors if phone number queries are
		 * issued while libphonenumber is unavailable
		 */
		if (!test->field) {
			/* Special case for e_book_query_any_field_contains().
			 *
			 * We interpret 'x-evolution-any-field' as E_CONTACT_FIELD_LAST
			 */
			if (test->field_id == E_CONTACT_FIELD_LAST) {
				/* If we search for a NULL or zero length string, it
				 * means 'get all contacts', that is considered a summary
				 * query but is handled differently (i.e. we just drop the
				 * field tests and run a regular query).
				 *
				 * This is only true if the 'any field contains' query is
				 * the only test in the constraints, however.
				 */
				if (n_elements == 1 && (!test->value || !test->value[0])) {

					context->status = MAX (context->status, PREFLIGHT_LIST_ALL);
				} else {

					/* Searching for a value with 'x-evolution-any-field' is
					 * not a summary query.
					 */
					context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
				}
			} else {
				/* Couldnt resolve the field, it's not a summary query */
				context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			}
		}

		if (test->field && test->field->type == E_TYPE_CONTACT_CERT) {
			/* For certificates, and later potentially other fields,
			 * the only information in the summary is the fact that
			 * they exist, or not. So the only check we can do from
			 * the summary is BOOK_QUERY_EXISTS. */
			if (field_test != BOOK_QUERY_EXISTS) {
				context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			}
			/* Bypass the other checks below which are not appropriate. */
			continue;
		}

		switch (field_test) {
		case E_BOOK_QUERY_IS:
			break;

		case BOOK_QUERY_EXISTS:
		case E_BOOK_QUERY_CONTAINS:
		case E_BOOK_QUERY_BEGINS_WITH:
		case E_BOOK_QUERY_ENDS_WITH:
		case E_BOOK_QUERY_REGEX_NORMAL:
			/* All of these queries can only apply to string fields,
			 * or fields which hold multiple strings
			 */
			if (test->field) {
				if (test->field->type == G_TYPE_BOOLEAN &&
				    field_test == BOOK_QUERY_EXISTS) {
					context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
				} else if (test->field->type != G_TYPE_STRING &&
					   test->field->type != E_TYPE_CONTACT_ATTR_LIST) {
					context->status = MAX (context->status, PREFLIGHT_INVALID);
				}
			}

			break;

		case BOOK_QUERY_EXISTS_VCARD:
			/* Exists vCard queries only supported in the fallback */
			context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			break;

		case E_BOOK_QUERY_REGEX_RAW:
			/* Raw regex queries only supported in the fallback */
			context->status = MAX (context->status, PREFLIGHT_NOT_SUMMARIZED);
			break;

		case E_BOOK_QUERY_EQUALS_PHONE_NUMBER:
		case E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER:
		case E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER:
			/* Phone number queries are supported so long as they are in the summary,
			 * libphonenumber is available, and the phone number string is a valid one
			 */
			if (!e_phone_number_is_supported ()) {
				context->status = MAX (context->status, PREFLIGHT_UNSUPPORTED);
			} else {
				QueryPhoneTest *phone_test = (QueryPhoneTest *) test;
				EPhoneNumberCountrySource source;
				EPhoneNumber *number;
				const gchar *region_code;

				if (phone_test->region)
					region_code = phone_test->region;
				else
					region_code = book_cache->priv->region_code;

				number = e_phone_number_from_string (
					phone_test->value,
					region_code, NULL);

				if (number == NULL) {
					context->status = MAX (context->status, PREFLIGHT_INVALID);
				} else {
					/* Collect values we'll need later while generating field
					 * tests, no need to parse the phone number more than once
					 */
					phone_test->national = e_phone_number_get_national_number (number);
					phone_test->country = e_phone_number_get_country_code (number, &source);
					phone_test->national = remove_leading_zeros (phone_test->national);

					if (source == E_PHONE_NUMBER_COUNTRY_FROM_DEFAULT)
						phone_test->country = 0;

					e_phone_number_free (number);
				}
			}
			break;
		}

		if (test->field &&
		    test->field->type == E_TYPE_CONTACT_ATTR_LIST) {
			gint aux_index = summary_field_get_index (book_cache, test->field_id);

			/* It's really improbable that we ever get 64 fields in the summary
			 * In any case we warn about this.
			 */
			g_warn_if_fail (aux_index >= 0 && aux_index < EBC_MAX_SUMMARY_FIELDS);

			/* Just to mute a compiler warning when aux_index == -1 */
			aux_index = ABS (aux_index);

			context->aux_mask |= (1 << aux_index);

			/* If this condition is a *requirement* for the overall query to
			   match a given record (i.e. there's no surrounding 'OR' but
			   only 'AND'), then we can use an inner join for the query and
			   it will be a lot more efficient. If records without this
			   condition can also match the overall condition, then we must
			   use LEFT JOIN. */
			if (sub_query_context_peek_cond_counter (ctx)) {
				context->left_join_mask |= (1 << aux_index);
			}
		}
	}

	sub_query_context_free (ctx);
}

/* Handle special case of E_CONTACT_FULL_NAME
 *
 * For any query which accesses the full name field,
 * we need to also OR it with any of the related name
 * fields, IF those are found in the summary as well.
 */
static void
query_preflight_substitute_full_name (PreflightContext *context,
				      EBookCache *book_cache)
{
	gint ii, jj;

	for (ii = 0; context->constraints != NULL && ii < context->constraints->len; ii++) {
		SummaryField *family_name, *given_name, *nickname;
		QueryElement *element;
		QueryFieldTest *test;

		element = g_ptr_array_index (context->constraints, ii);

		if (element->query >= BOOK_QUERY_SUB_FIRST)
			continue;

		test = (QueryFieldTest *) element;
		if (test->field_id != E_CONTACT_FULL_NAME)
			continue;

		family_name = summary_field_get (book_cache, E_CONTACT_FAMILY_NAME);
		given_name = summary_field_get (book_cache, E_CONTACT_GIVEN_NAME);
		nickname = summary_field_get (book_cache, E_CONTACT_NICKNAME);

		/* If any of these are in the summary, then we'll construct
		 * a grouped OR statment for this E_CONTACT_FULL_NAME test */
		if (family_name || given_name || nickname) {
			/* Add the OR directly before the E_CONTACT_FULL_NAME test */
			constraints_insert_delimiter (context->constraints, ii, BOOK_QUERY_SUB_OR);

			jj = ii + 2;

			if (family_name)
				constraints_insert_field_test (
					context->constraints, jj++,
					family_name, test->query,
					test->value);

			if (given_name)
				constraints_insert_field_test (
					context->constraints, jj++,
					given_name, test->query,
					test->value);

			if (nickname)
				constraints_insert_field_test (
					context->constraints, jj++,
					nickname, test->query,
					test->value);

			constraints_insert_delimiter (context->constraints, jj, BOOK_QUERY_SUB_END);

			ii = jj;
		}
	}
}

static void
query_preflight (PreflightContext *context,
		 EBookCache *book_cache,
		 const gchar *sexp)
{
	query_preflight_initialize (context, sexp);

	if (context->status == PREFLIGHT_OK) {
		query_preflight_check (context, book_cache);

		/* No need to change the constraints if we're not
		 * going to generate statements with it
		 */
		if (context->status == PREFLIGHT_OK) {
			/* Handle E_CONTACT_FULL_NAME substitutions */
			query_preflight_substitute_full_name (context, book_cache);
		} else {
			/* We might use this context to perform a fallback query,
			 * so let's clear out all the constraints now
			 */
			preflight_context_clear (context);
		}
	}
}

/**********************************************************
 *                 Field Test Generators                  *
 **********************************************************
 *
 * This section contains the field test generators for
 * various EBookQueryTest types. When implementing new
 * query types, a new GenerateFieldTest needs to be created
 * and added to the table below.
 */

typedef void (* GenerateFieldTest) (EBookCache *book_cache,
				    GString *string,
				    QueryFieldTest *test);

/* Appends an identifier suitable to identify the
 * column to test in the context of a query.
 *
 * The suffix is for special indexed columns (such as
 * reverse values, sort keys, phone numbers, etc).
 */
static void
ebc_string_append_column (GString *string,
			  SummaryField *field,
			  const gchar *suffix)
{
	if (field->aux_table) {
		g_string_append (string, field->aux_table_symbolic);
		g_string_append (string, ".value");
	} else {
		g_string_append (string, "summary.");
		g_string_append (string, field->dbname);
	}

	if (suffix) {
		g_string_append_c (string, '_');
		g_string_append (string, suffix);
	}
}

/* This function escapes characters which need escaping
 * for LIKE statements as well as the single quotes.
 *
 * The return value is not suitable to be formatted
 * with %Q or %q
 */
static gchar *
ebc_normalize_for_like (QueryFieldTest *test,
			gboolean reverse_string,
			gboolean *escape_needed)
{
	GString *str;
	size_t len;
	gchar cc;
	gboolean escape_modifier_needed = FALSE;
	const gchar *normal = NULL;
	const gchar *ptr;
	const gchar *str_to_escape;
	gchar *reverse = NULL;
	gchar *freeme = NULL;

	if (test->field_id == E_CONTACT_UID ||
	    test->field_id == E_CONTACT_REV) {
		normal = test->value;
	} else {
		freeme = e_util_utf8_normalize (test->value);
		normal = freeme;
	}

	if (reverse_string) {
		reverse = g_utf8_strreverse (normal, -1);
		str_to_escape = reverse;
	} else
		str_to_escape = normal;

	/* Just assume each character must be escaped. The result of this function
	 * is discarded shortly after calling this function. Therefore it's
	 * acceptable to possibly allocate twice the memory needed.
	 */
	len = strlen (str_to_escape);
	str = g_string_sized_new (2 * len + 4 + strlen (EBC_ESCAPE_SEQUENCE) - 1);

	ptr = str_to_escape;
	while ((cc = *ptr++)) {
		if (cc == '\'') {
			g_string_append_c (str, '\'');
		} else if (cc == '%' || cc == '_' || cc == '^') {
			g_string_append_c (str, '^');
			escape_modifier_needed = TRUE;
		}

		g_string_append_c (str, cc);
	}

	if (escape_needed)
		*escape_needed = escape_modifier_needed;

	g_free (freeme);
	g_free (reverse);

	return g_string_free (str, FALSE);
}

static void
field_test_query_is (EBookCache *book_cache,
		     GString *string,
		     QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gchar *normal;

	ebc_string_append_column (string, field, NULL);

	if (test->field_id == E_CONTACT_UID ||
	    test->field_id == E_CONTACT_REV) {
		/* UID & REV fields are not normalized in the summary */
		e_cache_sqlite_stmt_append_printf (string, " = %Q", test->value);
	} else {
		normal = e_util_utf8_normalize (test->value);
		e_cache_sqlite_stmt_append_printf (string, " = %Q", normal);
		g_free (normal);
	}
}

static void
field_test_query_contains (EBookCache *book_cache,
			   GString *string,
			   QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	escaped = ebc_normalize_for_like (test, FALSE, &need_escape);

	g_string_append_c (string, '(');

	ebc_string_append_column (string, field, NULL);
	g_string_append (string, " IS NOT NULL AND ");
	ebc_string_append_column (string, field, NULL);
	g_string_append (string, " LIKE '%");
	g_string_append (string, escaped);
	g_string_append (string, "%'");

	if (need_escape)
		g_string_append (string, EBC_ESCAPE_SEQUENCE);

	g_string_append_c (string, ')');

	g_free (escaped);
}

static void
field_test_query_begins_with (EBookCache *book_cache,
			      GString *string,
			      QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	escaped = ebc_normalize_for_like (test, FALSE, &need_escape);

	g_string_append_c (string, '(');
	ebc_string_append_column (string, field, NULL);
	g_string_append (string, " IS NOT NULL AND ");

	ebc_string_append_column (string, field, NULL);
	g_string_append (string, " LIKE \'");
	g_string_append (string, escaped);
	g_string_append (string, "%\'");

	if (need_escape)
		g_string_append (string, EBC_ESCAPE_SEQUENCE);
	g_string_append_c (string, ')');

	g_free (escaped);
}

static void
field_test_query_ends_with (EBookCache *book_cache,
			    GString *string,
			    QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gboolean need_escape;
	gchar *escaped;

	if ((field->index & INDEX_FLAG (SUFFIX)) != 0) {
		escaped = ebc_normalize_for_like (test, TRUE, &need_escape);

		g_string_append_c (string, '(');
		ebc_string_append_column (string, field, EBC_SUFFIX_REVERSE);
		g_string_append (string, " IS NOT NULL AND ");

		ebc_string_append_column (string, field, EBC_SUFFIX_REVERSE);
		g_string_append (string, " LIKE \'");
		g_string_append (string, escaped);
		g_string_append (string, "%\'");
	} else {
		escaped = ebc_normalize_for_like (test, FALSE, &need_escape);
		g_string_append_c (string, '(');

		ebc_string_append_column (string, field, NULL);
		g_string_append (string, " IS NOT NULL AND ");

		ebc_string_append_column (string, field, NULL);
		g_string_append (string, " LIKE \'%");
		g_string_append (string, escaped);
		g_string_append (string, "\'");
	}

	if (need_escape)
		g_string_append (string, EBC_ESCAPE_SEQUENCE);

	g_string_append_c (string, ')');
	g_free (escaped);
}

static void
field_test_query_eqphone (EBookCache *book_cache,
			  GString *string,
			  QueryFieldTest *test)
{
	SummaryField *field = test->field;
	QueryPhoneTest *phone_test = (QueryPhoneTest *) test;

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {
		g_string_append_c (string, '(');
		ebc_string_append_column (string, field, EBC_SUFFIX_PHONE);
		e_cache_sqlite_stmt_append_printf (string, " = %Q AND ", phone_test->national);

		/* For exact matches, a country code qualifier is required by both
		 * query input and row input
		 */
		ebc_string_append_column (string, field, EBC_SUFFIX_COUNTRY);
		g_string_append (string, " != 0 AND ");

		ebc_string_append_column (string, field, EBC_SUFFIX_COUNTRY);
		e_cache_sqlite_stmt_append_printf (string, " = %d", phone_test->country);
		g_string_append_c (string, ')');
	} else {
		/* No indexed columns available, perform the fallback */
		g_string_append (string, EBC_FUNC_EQPHONE_EXACT " (");
		ebc_string_append_column (string, field, NULL);
		e_cache_sqlite_stmt_append_printf (string, ", %Q)", test->value);
	}
}

static void
field_test_query_eqphone_national (EBookCache *book_cache,
				   GString *string,
				   QueryFieldTest *test)
{

	SummaryField *field = test->field;
	QueryPhoneTest *phone_test = (QueryPhoneTest *) test;

	if ((field->index & INDEX_FLAG (PHONE)) != 0) {
		/* Only a compound expression if there is a country code */
		if (phone_test->country)
			g_string_append_c (string, '(');

		/* Generate: phone = %Q */
		ebc_string_append_column (string, field, EBC_SUFFIX_PHONE);
		e_cache_sqlite_stmt_append_printf (string, " = %Q", phone_test->national);

		/* When doing a national search, no need to check country
		 * code unless the query number also has a country code
		 */
		if (phone_test->country) {
			/* Generate: (phone = %Q AND (country = 0 OR country = %d)) */
			g_string_append (string, " AND (");
			ebc_string_append_column (string, field, EBC_SUFFIX_COUNTRY);
			g_string_append (string, " = 0 OR ");
			ebc_string_append_column (string, field, EBC_SUFFIX_COUNTRY);
			e_cache_sqlite_stmt_append_printf (string, " = %d))", phone_test->country);
		}
	} else {
		/* No indexed columns available, perform the fallback */
		g_string_append (string, EBC_FUNC_EQPHONE_NATIONAL " (");
		ebc_string_append_column (string, field, NULL);
		e_cache_sqlite_stmt_append_printf (string, ", %Q)", test->value);
	}
}

static void
field_test_query_eqphone_short (EBookCache *book_cache,
				GString *string,
				QueryFieldTest *test)
{
	SummaryField *field = test->field;

	/* No quick way to do the short match */
	g_string_append (string, EBC_FUNC_EQPHONE_SHORT " (");
	ebc_string_append_column (string, field, NULL);
	e_cache_sqlite_stmt_append_printf (string, ", %Q)", test->value);
}

static void
field_test_query_regex_normal (EBookCache *book_cache,
			       GString *string,
			       QueryFieldTest *test)
{
	SummaryField *field = test->field;
	gchar *normal;

	normal = e_util_utf8_normalize (test->value);

	if (field->aux_table) {
		e_cache_sqlite_stmt_append_printf (
			string, "%s.value REGEXP %Q",
			field->aux_table_symbolic,
			normal);
	} else {
		e_cache_sqlite_stmt_append_printf (
			string, "summary.%s REGEXP %Q",
			field->dbname,
			normal);
	}

	g_free (normal);
}

static void
field_test_query_exists (EBookCache *book_cache,
			 GString *string,
			 QueryFieldTest *test)
{
	SummaryField *field = test->field;

	ebc_string_append_column (string, field, NULL);

	if (test->field->type == E_TYPE_CONTACT_CERT)
		e_cache_sqlite_stmt_append_printf (string, " IS NOT '0'");
	else
		e_cache_sqlite_stmt_append_printf (string, " IS NOT NULL");
}

/* Lookup table for field test generators per EBookQueryTest,
 *
 * WARNING: This must stay in line with the EBookQueryTest definition.
 */
static const GenerateFieldTest field_test_func_table[] = {
	field_test_query_is,               /* E_BOOK_QUERY_IS */
	field_test_query_contains,         /* E_BOOK_QUERY_CONTAINS */
	field_test_query_begins_with,      /* E_BOOK_QUERY_BEGINS_WITH */
	field_test_query_ends_with,        /* E_BOOK_QUERY_ENDS_WITH */
	field_test_query_eqphone,          /* E_BOOK_QUERY_EQUALS_PHONE_NUMBER */
	field_test_query_eqphone_national, /* E_BOOK_QUERY_EQUALS_NATIONAL_PHONE_NUMBER */
	field_test_query_eqphone_short,    /* E_BOOK_QUERY_EQUALS_SHORT_PHONE_NUMBER */
	field_test_query_regex_normal,     /* E_BOOK_QUERY_REGEX_NORMAL */
	NULL /* Requires fallback */,      /* E_BOOK_QUERY_REGEX_RAW  */
	field_test_query_exists,           /* BOOK_QUERY_EXISTS */
	NULL /* Requires fallback */       /* BOOK_QUERY_EXISTS_VCARD */
};

/**********************************************************
 *                   Querying Contacts                    *
 **********************************************************/

/* The various search types indicate what should be fetched
 */
typedef enum {
	SEARCH_FULL,          /* Get a list of EBookCacheSearchData*/
	SEARCH_UID_AND_REV,   /* Get a list of EBookCacheSearchData, with shallow vcards only containing UID & REV */
	SEARCH_UID,           /* Get a list of UID strings */
	SEARCH_COUNT,         /* Get the number of matching rows */
} SearchType;

static void
ebc_generate_constraints (EBookCache *book_cache,
			  GString *string,
			  GPtrArray *constraints,
			  const gchar *sexp)
{
	SubQueryContext *ctx;
	QueryDelimiter *delim;
	QueryFieldTest *test;
	QueryElement **elements;
	gint n_elements, ii;

	/* If there are no constraints, we generate the fallback constraint for 'sexp' */
	if (constraints == NULL) {
		e_cache_sqlite_stmt_append_printf (
			string,
			EBC_FUNC_COMPARE_VCARD " (%Q,summary." E_CACHE_COLUMN_OBJECT ")",
			sexp);
		return;
	}

	elements = (QueryElement **) constraints->pdata;
	n_elements = constraints->len;

	ctx = sub_query_context_new ();

	for (ii = 0; ii < n_elements; ii++) {
		GenerateFieldTest generate_test_func = NULL;

		/* Seperate field tests with the appropriate grouping */
		if (elements[ii]->query != BOOK_QUERY_SUB_END &&
		    sub_query_context_increment (ctx) > 0) {
			guint delim_type = sub_query_context_peek_type (ctx);

			switch (delim_type) {
			case BOOK_QUERY_SUB_AND:
				g_string_append (string, " AND ");
				break;

			case BOOK_QUERY_SUB_OR:
				g_string_append (string, " OR ");
				break;

			case BOOK_QUERY_SUB_NOT:
				/* Nothing to do between children of NOT,
				 * there should only ever be one child of NOT anyway
				 */
				break;

			case BOOK_QUERY_SUB_END:
			default:
				g_warn_if_reached ();
			}
		}

		if (elements[ii]->query >= BOOK_QUERY_SUB_FIRST) {
			delim = (QueryDelimiter *) elements[ii];

			switch (delim->query) {
			case BOOK_QUERY_SUB_NOT:
				/* NOT is a unary operator and as such
				 * comes before the opening parenthesis
				 */
				g_string_append (string, "NOT ");

				/* Fall through */

			case BOOK_QUERY_SUB_AND:
			case BOOK_QUERY_SUB_OR:
				/* Open a grouped statement and push the context */
				sub_query_context_push (ctx, delim->query, FALSE);
				g_string_append_c (string, '(');
				break;

			case BOOK_QUERY_SUB_END:
				/* Close a grouped statement and pop the context */
				g_string_append_c (string, ')');
				sub_query_context_pop (ctx);
				break;
			default:
				g_warn_if_reached ();
			}

			continue;
		}

		/* Find the appropriate field test generator */
		test = (QueryFieldTest *) elements[ii];
		if (test->query < G_N_ELEMENTS (field_test_func_table))
			generate_test_func = field_test_func_table[test->query];

		/* These should never happen, if it does it should be
		 * fixed in the preflight checks
		 */
		g_warn_if_fail (generate_test_func != NULL);
		g_warn_if_fail (test->field != NULL);

		/* Generate the field test */
		/* coverity[var_deref_op] */
		generate_test_func (book_cache, string, test);
	}

	sub_query_context_free (ctx);
}

static void
ebc_search_meta_contacts_cb (ECache *cache,
			     const gchar *uid,
			     const gchar *revision,
			     const gchar *object,
			     const gchar *extra,
			     gpointer out_value)
{
	GSList **out_list = out_value;
	EBookCacheSearchData *sd;
	EContact *contact;
	gchar *vcard;

	g_return_if_fail (out_list != NULL);

	contact = e_contact_new ();

	e_contact_set (contact, E_CONTACT_UID, uid);
	if (revision)
		e_contact_set (contact, E_CONTACT_REV, revision);

	vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

	g_object_unref (contact);

	sd = e_book_cache_search_data_new (uid, vcard, extra);

	*out_list = g_slist_prepend (*out_list, sd);

	g_free (vcard);
}

static void
ebc_search_full_contacts_cb (ECache *cache,
			     const gchar *uid,
			     const gchar *revision,
			     const gchar *object,
			     const gchar *extra,
			     gpointer out_value)
{
	GSList **out_list = out_value;
	EBookCacheSearchData *sd;

	g_return_if_fail (out_list != NULL);

	sd = e_book_cache_search_data_new (uid, object, extra);

	*out_list = g_slist_prepend (*out_list, sd);
}

static void
ebc_search_uids_cb (ECache *cache,
		    const gchar *uid,
		    const gchar *revision,
		    const gchar *object,
		    const gchar *extra,
		    gpointer out_value)
{
	GSList **out_list = out_value;

	g_return_if_fail (out_list != NULL);

	*out_list = g_slist_prepend (*out_list, g_strdup (uid));
}

typedef void (* EBookCacheInternalSearchFunc)	(ECache *cache,
						 const gchar *uid,
						 const gchar *revision,
						 const gchar *object,
						 const gchar *extra,
						 gpointer out_value);

/* Generates the SELECT portion of the query, this will take care of
 * preparing the context of the query, and add the needed JOIN statements
 * based on which fields are referenced in the query expression.
 *
 * This also handles getting the correct callback and asking for the
 * right data depending on the 'search_type'
 */
static EBookCacheInternalSearchFunc
ebc_generate_select (EBookCache *book_cache,
		     GString *string,
		     SearchType search_type,
		     PreflightContext *context,
		     GError **error)
{
	EBookCacheInternalSearchFunc callback = NULL;
	gboolean add_auxiliary_tables = FALSE;
	gint ii;

	if (context->status == PREFLIGHT_OK &&
	    context->aux_mask != 0)
		add_auxiliary_tables = TRUE;

	g_string_append (string, "SELECT ");
	if (add_auxiliary_tables)
		g_string_append (string, "DISTINCT ");

	switch (search_type) {
	case SEARCH_FULL:
		callback = ebc_search_full_contacts_cb;
		g_string_append (string, "summary." E_CACHE_COLUMN_UID ",");
		g_string_append (string, "summary." E_CACHE_COLUMN_REVISION ",");
		g_string_append (string, "summary." E_CACHE_COLUMN_OBJECT ",");
		g_string_append (string, "summary." E_CACHE_COLUMN_STATE ",");
		g_string_append (string, "summary." EBC_COLUMN_EXTRA " ");
		break;
	case SEARCH_UID_AND_REV:
		callback = ebc_search_meta_contacts_cb;
		g_string_append (string, "summary." E_CACHE_COLUMN_UID ", summary." E_CACHE_COLUMN_REVISION ", summary." EBC_COLUMN_EXTRA " ");
		break;
	case SEARCH_UID:
		callback = ebc_search_uids_cb;
		g_string_append (string, "summary." E_CACHE_COLUMN_UID ",");
		g_string_append (string, "summary." E_CACHE_COLUMN_REVISION " ");
		break;
	case SEARCH_COUNT:
		if (context->aux_mask != 0)
			g_string_append (string, "count (DISTINCT summary." E_CACHE_COLUMN_UID ") ");
		else
			g_string_append (string, "count (*) ");
		break;
	}

	e_cache_sqlite_stmt_append_printf (string, "FROM %Q AS summary", E_CACHE_TABLE_OBJECTS);

	/* Add any required auxiliary tables into the query context */
	if (add_auxiliary_tables) {
		for (ii = 0; ii < book_cache->priv->n_summary_fields; ii++) {

			/* We cap this at EBC_MAX_SUMMARY_FIELDS (64 bits) at creation time */
			if ((context->aux_mask & (1 << ii)) != 0) {
				SummaryField *field = &(book_cache->priv->summary_fields[ii]);
				gboolean left_join = (context->left_join_mask >> ii) & 1;

				/* Note the '+' in the JOIN statement.
				 *
				 * This plus makes the uid's index ineligable to participate
				 * in any indexing.
				 *
				 * Without this, the indexes which we prefer for prefix or
				 * suffix matching in the auxiliary tables are ignored and
				 * only considered on exact matches.
				 *
				 * This is crucial to ensure that the uid index does not
				 * compete with the value index in constraints such as:
				 *
				 *     WHERE email_list.value LIKE "boogieman%"
				 */
				e_cache_sqlite_stmt_append_printf (
					string, " %sJOIN %Q AS %s ON %s%s.uid = summary." E_CACHE_COLUMN_UID,
					left_join ? "LEFT " : "",
					field->aux_table,
					field->aux_table_symbolic,
					left_join ? "" : "+",
					field->aux_table_symbolic);
			}
		}
	}

	return callback;
}

static gboolean
ebc_is_autocomplete_query (PreflightContext *context)
{
	QueryFieldTest *test;
	QueryElement **elements;
	gint n_elements, ii;
	int non_aux_fields = 0;

	if (context->status != PREFLIGHT_OK || context->aux_mask == 0)
		return FALSE;

	elements = (QueryElement **) context->constraints->pdata;
	n_elements = context->constraints->len;

	for (ii = 0; ii < n_elements; ii++) {
		test = (QueryFieldTest *) elements[ii];

		/* For these, check if the field being operated on is
		   an auxiliary field or not. */
		if (elements[ii]->query == E_BOOK_QUERY_BEGINS_WITH ||
		    elements[ii]->query == E_BOOK_QUERY_ENDS_WITH ||
		    elements[ii]->query == E_BOOK_QUERY_IS ||
		    elements[ii]->query == BOOK_QUERY_EXISTS ||
		    elements[ii]->query == E_BOOK_QUERY_CONTAINS) {
			if (test->field->type != E_TYPE_CONTACT_ATTR_LIST)
				non_aux_fields++;
			continue;
		}

		/* Nothing else is allowed other than "(or" ... ")" */
		if (elements[ii]->query != BOOK_QUERY_SUB_OR &&
		    elements[ii]->query != BOOK_QUERY_SUB_END)
			return FALSE;
	}

	/* If there were no non-aux fields being queried, don't bother */
	return non_aux_fields != 0;
}

static EBookCacheInternalSearchFunc
ebc_generate_autocomplete_query (EBookCache *book_cache,
				 GString *string,
				 SearchType search_type,
				 PreflightContext *context,
				 GError **error)
{
	QueryElement **elements;
	gint n_elements, ii;
	guint64 aux_mask = context->aux_mask;
	guint64 left_join_mask = context->left_join_mask;
	EBookCacheInternalSearchFunc callback;
	gboolean first = TRUE;

	elements = (QueryElement **) context->constraints->pdata;
	n_elements = context->constraints->len;

	/* First the queries which use aux tables. */
	for (ii = 0; ii < n_elements; ii++) {
		GenerateFieldTest generate_test_func = NULL;
		QueryFieldTest *test;
		gint aux_index;

		if (elements[ii]->query == BOOK_QUERY_SUB_OR ||
		    elements[ii]->query == BOOK_QUERY_SUB_END)
			continue;

		test = (QueryFieldTest *) elements[ii];
		if (test->field->type != E_TYPE_CONTACT_ATTR_LIST)
			continue;

		aux_index = summary_field_get_index (book_cache, test->field_id);
		g_warn_if_fail (aux_index >= 0 && aux_index < EBC_MAX_SUMMARY_FIELDS);

		/* Just to mute a compiler warning when aux_index == -1 */
		aux_index = ABS (aux_index);
		context->aux_mask = (1 << aux_index);
		context->left_join_mask = 0;

		callback = ebc_generate_select (book_cache, string, search_type, context, error);
		e_cache_sqlite_stmt_append_printf (string, " WHERE summary." E_CACHE_COLUMN_STATE "!=%d AND (", E_OFFLINE_STATE_LOCALLY_DELETED);
		context->aux_mask = aux_mask;
		context->left_join_mask = left_join_mask;
		if (!callback)
			return NULL;

		generate_test_func = field_test_func_table[test->query];
		generate_test_func (book_cache, string, test);

		g_string_append (string, ") UNION ");
	}

	/* Finally, generate the SELECT for the primary fields. */
	context->aux_mask = 0;
	callback = ebc_generate_select (book_cache, string, search_type, context, error);
	context->aux_mask = aux_mask;
	if (!callback)
		return NULL;

	e_cache_sqlite_stmt_append_printf (string, " WHERE summary." E_CACHE_COLUMN_STATE "!=%d AND (", E_OFFLINE_STATE_LOCALLY_DELETED);

	for (ii = 0; ii < n_elements; ii++) {
		GenerateFieldTest generate_test_func = NULL;
		QueryFieldTest *test;

		if (elements[ii]->query == BOOK_QUERY_SUB_OR ||
		    elements[ii]->query == BOOK_QUERY_SUB_END)
			continue;

		test = (QueryFieldTest *) elements[ii];
		if (test->field->type == E_TYPE_CONTACT_ATTR_LIST)
			continue;

		if (!first)
			g_string_append (string, " OR ");
		else
			first = FALSE;

		generate_test_func = field_test_func_table[test->query];
		generate_test_func (book_cache, string, test);
	}

	g_string_append (string, ")");

	return callback;
}

struct EBCSearchData {
	gint uid_index;
	gint revision_index;
	gint object_index;
	gint extra_index;
	gint state_index;

	EBookCacheInternalSearchFunc func;
	gpointer out_value;

	EBookCacheSearchFunc user_func;
	gpointer user_func_user_data;
};

static gboolean
ebc_search_select_cb (ECache *cache,
		      gint ncols,
		      const gchar *column_names[],
		      const gchar *column_values[],
		      gpointer user_data)
{
	struct EBCSearchData *sd = user_data;
	const gchar *object = NULL, *extra = NULL;
	EOfflineState offline_state = E_OFFLINE_STATE_UNKNOWN;

	g_return_val_if_fail (sd != NULL, FALSE);
	g_return_val_if_fail (sd->func != NULL || sd->user_func != NULL, FALSE);
	g_return_val_if_fail (sd->out_value != NULL || sd->user_func != NULL, FALSE);

	if (sd->uid_index == -1 ||
	    sd->revision_index == -1 ||
	    sd->object_index == -1 ||
	    sd->extra_index == -1 ||
	    sd->state_index == -1) {
		gint ii;

		for (ii = 0; ii < ncols && (sd->uid_index == -1 ||
		     sd->revision_index == -1 ||
		     sd->object_index == -1 ||
		     sd->extra_index == -1 ||
		     sd->state_index == -1); ii++) {
			const gchar *cname = column_names[ii];

			if (!cname)
				continue;

			if (g_str_has_prefix (cname, "summary."))
				cname += 8;

			if (sd->uid_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_UID) == 0) {
				sd->uid_index = ii;
			} else if (sd->revision_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_REVISION) == 0) {
				sd->revision_index = ii;
			} else if (sd->object_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_OBJECT) == 0) {
				sd->object_index = ii;
			} else if (sd->extra_index == -1 && g_ascii_strcasecmp (cname, EBC_COLUMN_EXTRA) == 0) {
				sd->extra_index = ii;
			} else if (sd->state_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_STATE) == 0) {
				sd->state_index = ii;
			}
		}
	}

	g_return_val_if_fail (sd->uid_index >= 0 && sd->uid_index < ncols, FALSE);
	g_return_val_if_fail (sd->revision_index >= 0 && sd->revision_index < ncols, FALSE);

	if (sd->object_index != -2) {
		g_return_val_if_fail (sd->object_index >= 0 && sd->object_index < ncols, FALSE);
		object = column_values[sd->object_index];
	}

	if (sd->extra_index != -2) {
		g_return_val_if_fail (sd->extra_index >= 0 && sd->extra_index < ncols, FALSE);
		extra = column_values[sd->extra_index];
	}

	if (sd->state_index != -2) {
		g_return_val_if_fail (sd->extra_index >= 0 && sd->extra_index < ncols, FALSE);

		if (!column_values[sd->state_index])
			offline_state = E_OFFLINE_STATE_UNKNOWN;
		else
			offline_state = g_ascii_strtoull (column_values[sd->state_index], NULL, 10);
	}

	if (sd->user_func) {
		return sd->user_func (E_BOOK_CACHE (cache), column_values[sd->uid_index], column_values[sd->revision_index],
			object, extra, offline_state, sd->user_func_user_data);
	}

	sd->func (cache, column_values[sd->uid_index], column_values[sd->revision_index], object, extra, sd->out_value);

	return TRUE;
}

static gboolean
ebc_do_search_query (EBookCache *book_cache,
		     PreflightContext *context,
		     const gchar *sexp,
		     SearchType search_type,
		     gpointer out_value,
		     EBookCacheSearchFunc func,
		     gpointer func_user_data,
		     GCancellable *cancellable,
		     GError **error)
{
	struct EBCSearchData sd;
	GString *stmt;
	gboolean success = FALSE;

	/* We might calculate a reasonable estimation of bytes
	 * during the preflight checks */
	stmt = g_string_sized_new (GENERATED_QUERY_BYTES);

	/* Extra special case. For the common case of the email composer's
	   addressbook autocompletion, we really want the most optimal query.
	   So check for it and use a basically hand-crafted one. */
        if (ebc_is_autocomplete_query (context)) {
		sd.func = ebc_generate_autocomplete_query (book_cache, stmt, search_type, context, error);
	} else {
		/* Generate the leading SELECT statement */
		sd.func = ebc_generate_select (book_cache, stmt, search_type, context, error);

		if (sd.func) {
			e_cache_sqlite_stmt_append_printf (stmt,
				" WHERE summary." E_CACHE_COLUMN_STATE "!=%d",
				E_OFFLINE_STATE_LOCALLY_DELETED);

			if (EBC_STATUS_GEN_CONSTRAINTS (context->status)) {
				GString *where_clause = g_string_new ("");

				/*
				 * Now generate the search expression on the main contacts table
				 */
				ebc_generate_constraints (book_cache, where_clause, context->constraints, sexp);
				if (where_clause->len)
					e_cache_sqlite_stmt_append_printf (stmt, " AND (%s)", where_clause->str);
				g_string_free (where_clause, TRUE);
			}
		}
	}

	if (sd.func) {
		sd.uid_index = -1;
		sd.revision_index = -1;
		sd.object_index = search_type == SEARCH_FULL ? -1 : -2;
		sd.extra_index = search_type == SEARCH_UID ? -2 : -1;
		sd.state_index = search_type == SEARCH_FULL ? -1 : -2;
		sd.out_value = out_value;
		sd.user_func = func;
		sd.user_func_user_data = func_user_data;

		success = e_cache_sqlite_select (E_CACHE (book_cache), stmt->str,
			ebc_search_select_cb, &sd, cancellable, error);
	}

	g_string_free (stmt, TRUE);

	return success;
}

static gboolean
ebc_search_internal (EBookCache *book_cache,
		     const gchar *sexp,
		     SearchType search_type,
		     gpointer out_value,
		     EBookCacheSearchFunc func,
		     gpointer func_user_data,
		     GCancellable *cancellable,
		     GError **error)
{
	PreflightContext context = PREFLIGHT_CONTEXT_INIT;
	gboolean success = FALSE;

	/* Now start with the query preflighting */
	query_preflight (&context, book_cache, sexp);

	switch (context.status) {
	case PREFLIGHT_OK:
	case PREFLIGHT_LIST_ALL:
	case PREFLIGHT_NOT_SUMMARIZED:
		/* No errors, let's really search */
		success = ebc_do_search_query (
			book_cache, &context, sexp,
			search_type, out_value, func, func_user_data,
			cancellable, error);
		break;

	case PREFLIGHT_INVALID:
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
			_("Invalid query: %s"), sexp);
		break;

	case PREFLIGHT_UNSUPPORTED:
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_UNSUPPORTED_QUERY,
			_("Query contained unsupported elements"));
		break;
	}

	preflight_context_clear (&context);

	return success;
}

/******************************************************************
 *                    EBookCacheCursor Implementation                  *
 ******************************************************************/
typedef struct _CursorState CursorState;

struct _CursorState {
	gchar **values;			/* The current cursor position, results will be returned after this position */
	gchar *last_uid; 		/* The current cursor contact UID position, used as a tie breaker */
	EBookCacheCursorOrigin position;/* The position is updated with the cursor state and is used to distinguish
					 * between the beginning and the ending of the cursor's contact list.
					 * While the cursor is in a non-null state, the position will be
					 * E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT.
					 */
};

struct _EBookCacheCursor {
	EBookBackendSExp *sexp;       /* An EBookBackendSExp based on the query, used by e_book_sqlite_cursor_compare () */
	gchar         *select_vcards; /* The first fragment when querying results */
	gchar         *select_count;  /* The first fragment when querying contact counts */
	gchar         *query;         /* The SQL query expression derived from the passed search expression */
	gchar         *order;         /* The normal order SQL query fragment to append at the end, containing ORDER BY etc */
	gchar         *reverse_order; /* The reverse order SQL query fragment to append at the end, containing ORDER BY etc */

	EContactField       *sort_fields;   /* The fields to sort in a query in the order or sort priority */
	EBookCursorSortType *sort_types;    /* The sort method to use for each field */
	gint                 n_sort_fields; /* The amound of sort fields */

	CursorState          state;
};

static CursorState *cursor_state_copy             (EBookCacheCursor     *cursor,
						   CursorState          *state);
static void         cursor_state_free             (EBookCacheCursor     *cursor,
						   CursorState          *state);
static void         cursor_state_clear            (EBookCacheCursor     *cursor,
						   CursorState          *state,
						   EBookCacheCursorOrigin position);
static void         cursor_state_set_from_contact (EBookCache           *book_cache,
						   EBookCacheCursor     *cursor,
						   CursorState          *state,
						   EContact             *contact);
static void         cursor_state_set_from_vcard   (EBookCache           *book_cache,
						   EBookCacheCursor     *cursor,
						   CursorState          *state,
						   const gchar          *vcard);

static CursorState *
cursor_state_copy (EBookCacheCursor *cursor,
		   CursorState *state)
{
	CursorState *copy;
	gint ii;

	copy = g_slice_new0 (CursorState);
	copy->values = g_new0 (gchar *, cursor->n_sort_fields);

	for (ii = 0; ii < cursor->n_sort_fields; ii++) {
		copy->values[ii] = g_strdup (state->values[ii]);
	}

	copy->last_uid = g_strdup (state->last_uid);
	copy->position = state->position;

	return copy;
}

static void
cursor_state_free (EBookCacheCursor *cursor,
		   CursorState *state)
{
	if (state) {
		cursor_state_clear (cursor, state, E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN);
		g_free (state->values);
		g_slice_free (CursorState, state);
	}
}

static void
cursor_state_clear (EBookCacheCursor *cursor,
		    CursorState *state,
		    EBookCacheCursorOrigin position)
{
	gint ii;

	for (ii = 0; ii < cursor->n_sort_fields; ii++) {
		g_free (state->values[ii]);
		state->values[ii] = NULL;
	}

	g_free (state->last_uid);
	state->last_uid = NULL;
	state->position = position;
}

static void
cursor_state_set_from_contact (EBookCache *book_cache,
			       EBookCacheCursor *cursor,
			       CursorState *state,
			       EContact *contact)
{
	gint ii;

	cursor_state_clear (cursor, state, E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN);

	for (ii = 0; ii < cursor->n_sort_fields; ii++) {
		const gchar *string = e_contact_get_const (contact, cursor->sort_fields[ii]);
		SummaryField *field;
		gchar *sort_key;

		if (string)
			sort_key = e_collator_generate_key (book_cache->priv->collator, string, NULL);
		else
			sort_key = g_strdup ("");

		field = summary_field_get (book_cache, cursor->sort_fields[ii]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			state->values[ii] = sort_key;
		} else {
			state->values[ii] = ebc_encode_vcard_sort_key (sort_key);
			g_free (sort_key);
		}
	}

	state->last_uid = e_contact_get (contact, E_CONTACT_UID);
	state->position = E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT;
}

static void
cursor_state_set_from_vcard (EBookCache *book_cache,
			     EBookCacheCursor *cursor,
			     CursorState *state,
			     const gchar *vcard)
{
	EContact *contact;

	contact = e_contact_new_from_vcard (vcard);
	cursor_state_set_from_contact (book_cache, cursor, state, contact);
	g_object_unref (contact);
}

static gboolean
ebc_cursor_setup_query (EBookCache *book_cache,
			EBookCacheCursor *cursor,
			const gchar *sexp,
			GError **error)
{
	PreflightContext context = PREFLIGHT_CONTEXT_INIT;
	GString *string, *where_clause;

	/* Preflighting and error checking */
	if (sexp) {
		query_preflight (&context, book_cache, sexp);

		if (context.status > PREFLIGHT_NOT_SUMMARIZED) {
			g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
				_("Invalid query for a book cursor"));

			preflight_context_clear (&context);
			return FALSE;
		}
	}

	/* Now we caught the errors, let's generate our queries and get out of here ... */
	g_free (cursor->select_vcards);
	g_free (cursor->select_count);
	g_free (cursor->query);
	g_clear_object (&(cursor->sexp));

	/* Generate the leading SELECT portions that we need */
	string = g_string_new ("");
	ebc_generate_select (book_cache, string, SEARCH_FULL, &context, NULL);
	cursor->select_vcards = g_string_free (string, FALSE);

	string = g_string_new ("");
	ebc_generate_select (book_cache, string, SEARCH_COUNT, &context, NULL);
	cursor->select_count = g_string_free (string, FALSE);

	where_clause = g_string_new ("");

	e_cache_sqlite_stmt_append_printf (where_clause, "summary." E_CACHE_COLUMN_STATE "!=%d",
		E_OFFLINE_STATE_LOCALLY_DELETED);

	if (!sexp || context.status == PREFLIGHT_LIST_ALL) {
		cursor->sexp = NULL;
	} else {
		cursor->sexp = e_book_backend_sexp_new (sexp);

		string = g_string_new (NULL);
		ebc_generate_constraints (book_cache, string, context.constraints, sexp);
		if (string->len)
			e_cache_sqlite_stmt_append_printf (where_clause, " AND (%s)", string->str);
		g_string_free (string, TRUE);
	}

	cursor->query = g_string_free (where_clause, FALSE);

	preflight_context_clear (&context);

	return TRUE;
}

static gchar *
ebc_cursor_order_by_fragment (EBookCache *book_cache,
			      const EContactField *sort_fields,
			      const EBookCursorSortType *sort_types,
			      guint n_sort_fields,
			      gboolean reverse)
{
	GString *string;
	gint ii;

	string = g_string_new ("ORDER BY ");

	for (ii = 0; ii < n_sort_fields; ii++) {
		SummaryField *field = summary_field_get (book_cache, sort_fields[ii]);

		if (ii > 0)
			g_string_append (string, ", ");

		if (field &&
		    (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			g_string_append (string, "summary.");
			g_string_append (string, field->dbname);
			g_string_append (string, "_" EBC_SUFFIX_SORT_KEY " ");
		} else {
			g_string_append (string, "summary." E_CACHE_COLUMN_OBJECT);
			g_string_append (string, " COLLATE ");
			g_string_append (string, EBC_COLLATE_PREFIX);
			g_string_append (string, e_contact_field_name (sort_fields[ii]));
			g_string_append_c (string, ' ');
		}

		if (reverse)
			g_string_append (string, (sort_types[ii] == E_BOOK_CURSOR_SORT_ASCENDING ? "DESC" : "ASC"));
		else
			g_string_append (string, (sort_types[ii] == E_BOOK_CURSOR_SORT_ASCENDING ? "ASC" : "DESC"));
	}

	/* Also order the UID, since it's our tie breaker */
	if (n_sort_fields > 0)
		g_string_append (string, ", ");

	g_string_append (string, "summary." E_CACHE_COLUMN_UID " ");
	g_string_append (string, reverse ? "DESC" : "ASC");

	return g_string_free (string, FALSE);
}

static EBookCacheCursor *
ebc_cursor_new (EBookCache *book_cache,
		const gchar *sexp,
		const EContactField *sort_fields,
		const EBookCursorSortType *sort_types,
		guint n_sort_fields)
{
	EBookCacheCursor *cursor = g_slice_new0 (EBookCacheCursor);

	cursor->order = ebc_cursor_order_by_fragment (book_cache, sort_fields, sort_types, n_sort_fields, FALSE);
	cursor->reverse_order = ebc_cursor_order_by_fragment (book_cache, sort_fields, sort_types, n_sort_fields, TRUE);

	/* Sort parameters */
	cursor->n_sort_fields = n_sort_fields;
	cursor->sort_fields = g_memdup (sort_fields, sizeof (EContactField) * n_sort_fields);
	cursor->sort_types = g_memdup (sort_types,  sizeof (EBookCursorSortType) * n_sort_fields);

	/* Cursor state */
	cursor->state.values = g_new0 (gchar *, n_sort_fields);
	cursor->state.last_uid = NULL;
	cursor->state.position = E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN;

	return cursor;
}

static void
ebc_cursor_free (EBookCacheCursor *cursor)
{
	if (cursor) {
		cursor_state_clear (cursor, &(cursor->state), E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN);
		g_free (cursor->state.values);

		g_clear_object (&(cursor->sexp));
		g_free (cursor->select_vcards);
		g_free (cursor->select_count);
		g_free (cursor->query);
		g_free (cursor->order);
		g_free (cursor->reverse_order);
		g_free (cursor->sort_fields);
		g_free (cursor->sort_types);

		g_slice_free (EBookCacheCursor, cursor);
	}
}

#define GREATER_OR_LESS(cursor, idx, reverse) \
	(reverse ? \
	 (((EBookCacheCursor *) cursor)->sort_types[idx] == E_BOOK_CURSOR_SORT_ASCENDING ? '<' : '>') : \
	 (((EBookCacheCursor *) cursor)->sort_types[idx] == E_BOOK_CURSOR_SORT_ASCENDING ? '>' : '<'))

static inline void
ebc_cursor_format_equality (EBookCache *book_cache,
			    GString *string,
			    EContactField field_id,
			    const gchar *value,
			    gchar equality)
{
	SummaryField *field = summary_field_get (book_cache, field_id);

	if (field &&
	    (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
		g_string_append (string, "summary.");
		g_string_append (string, field->dbname);
		g_string_append (string, "_" EBC_SUFFIX_SORT_KEY " ");

		e_cache_sqlite_stmt_append_printf (string, "%c %Q", equality, value);
	} else {
		e_cache_sqlite_stmt_append_printf (string, "(summary." E_CACHE_COLUMN_OBJECT " %c %Q ", equality, value);

		g_string_append (string, "COLLATE " EBC_COLLATE_PREFIX);
		g_string_append (string, e_contact_field_name (field_id));
		g_string_append_c (string, ')');
	}
}

static gchar *
ebc_cursor_constraints (EBookCache *book_cache,
			EBookCacheCursor *cursor,
			CursorState *state,
			gboolean reverse,
			gboolean include_current_uid)
{
	GString *string;
	gint ii, jj;

	/* Example for:
	 *    ORDER BY family_name ASC, given_name DESC
	 *
	 * Where current cursor values are:
	 *    family_name = Jackson
	 *    given_name  = Micheal
	 *
	 * With reverse = FALSE
	 *
	 *    (summary.family_name > 'Jackson') OR
	 *    (summary.family_name = 'Jackson' AND summary.given_name < 'Micheal') OR
	 *    (summary.family_name = 'Jackson' AND summary.given_name = 'Micheal' AND summary.uid > 'last-uid')
	 *
	 * With reverse = TRUE (needed for moving the cursor backwards through results)
	 *
	 *    (summary.family_name < 'Jackson') OR
	 *    (summary.family_name = 'Jackson' AND summary.given_name > 'Micheal') OR
	 *    (summary.family_name = 'Jackson' AND summary.given_name = 'Micheal' AND summary.uid < 'last-uid')
	 *
	 */
	string = g_string_new (NULL);

	for (ii = 0; ii <= cursor->n_sort_fields; ii++) {
		/* Break once we hit a NULL value */
		if ((ii < cursor->n_sort_fields && state->values[ii] == NULL) ||
		    (ii == cursor->n_sort_fields && state->last_uid == NULL))
			break;

		/* Between each qualifier, add an 'OR' */
		if (ii > 0)
			g_string_append (string, " OR ");

		/* Begin qualifier */
		g_string_append_c (string, '(');

		/* Create the '=' statements leading up to the current tie breaker */
		for (jj = 0; jj < ii; jj++) {
			ebc_cursor_format_equality (book_cache, string,
						    cursor->sort_fields[jj],
						    state->values[jj], '=');
			g_string_append (string, " AND ");
		}

		if (ii == cursor->n_sort_fields) {
			/* The 'include_current_uid' clause is used for calculating
			 * the current position of the cursor, inclusive of the
			 * current position.
			 */
			if (include_current_uid)
				g_string_append_c (string, '(');

			/* Append the UID tie breaker */
			e_cache_sqlite_stmt_append_printf (
				string,
				"summary." E_CACHE_COLUMN_UID " %c %Q",
				reverse ? '<' : '>',
				state->last_uid);

			if (include_current_uid)
				e_cache_sqlite_stmt_append_printf (
					string,
					" OR summary." E_CACHE_COLUMN_UID " = %Q)",
					state->last_uid);
		} else {
			/* SPECIAL CASE: If we have a parially set cursor state, then we must
			 * report next results that are inclusive of the final qualifier.
			 *
			 * This allows one to set the cursor with the family name set to 'J'
			 * and include the results for contact's Mr & Miss 'J'.
			 */
			gboolean include_exact_match =
				(reverse == FALSE &&
				 ((ii + 1 < cursor->n_sort_fields && state->values[ii + 1] == NULL) ||
				  (ii + 1 == cursor->n_sort_fields && state->last_uid == NULL)));

			if (include_exact_match)
				g_string_append_c (string, '(');

			/* Append the final qualifier for this field */
			ebc_cursor_format_equality (book_cache, string,
						    cursor->sort_fields[ii],
						    state->values[ii],
						    GREATER_OR_LESS (cursor, ii, reverse));

			if (include_exact_match) {
				g_string_append (string, " OR ");
				ebc_cursor_format_equality (book_cache, string,
							    cursor->sort_fields[ii],
							    state->values[ii], '=');
				g_string_append_c (string, ')');
			}
		}

		/* End qualifier */
		g_string_append_c (string, ')');
	}

	return g_string_free (string, FALSE);
}

static gboolean
ebc_get_int_cb (ECache *cache,
		gint ncols,
		const gchar **column_names,
		const gchar **column_values,
		gpointer user_data)
{
	gint *pint = user_data;

	g_return_val_if_fail (pint != NULL, FALSE);

	if (ncols == 1) {
		*pint = column_values[0] ? g_ascii_strtoll (column_values[0], NULL, 10) : 0;
	} else {
		*pint = 0;
	}

	return TRUE;
}

static gboolean
cursor_count_total_locked (EBookCache *book_cache,
			   EBookCacheCursor *cursor,
			   gint *out_total,
			   GCancellable *cancellable,
			   GError **error)
{
	GString *query;
	gboolean success;

	query = g_string_new (cursor->select_count);

	/* Add the filter constraints (if any) */
	if (cursor->query) {
		g_string_append (query, " WHERE ");

		g_string_append_c (query, '(');
		g_string_append (query, cursor->query);
		g_string_append_c (query, ')');
	}

	/* Execute the query */
	success = e_cache_sqlite_select (E_CACHE (book_cache), query->str, ebc_get_int_cb, out_total, cancellable, error);

	g_string_free (query, TRUE);

	return success;
}

static gboolean
cursor_count_position_locked (EBookCache *book_cache,
			      EBookCacheCursor *cursor,
			      gint *out_position,
			      GCancellable *cancellable,
			      GError **error)
{
	GString *query;
	gboolean success;

	query = g_string_new (cursor->select_count);

	/* Add the filter constraints (if any) */
	if (cursor->query) {
		g_string_append (query, " WHERE ");

		g_string_append_c (query, '(');
		g_string_append (query, cursor->query);
		g_string_append_c (query, ')');
	}

	/* Add the cursor constraints (if any) */
	if (cursor->state.values[0] != NULL) {
		gchar *constraints = NULL;

		if (!cursor->query)
			g_string_append (query, " WHERE ");
		else
			g_string_append (query, " AND ");

		/* Here we do a reverse query, we're looking for all the
		 * results leading up to the current cursor value, including
		 * the cursor value
		 */
		constraints = ebc_cursor_constraints (book_cache, cursor, &(cursor->state), TRUE, TRUE);

		g_string_append_c (query, '(');
		g_string_append (query, constraints);
		g_string_append_c (query, ')');

		g_free (constraints);
	}

	/* Execute the query */
	success = e_cache_sqlite_select (E_CACHE (book_cache), query->str, ebc_get_int_cb, out_position, cancellable, error);

	g_string_free (query, TRUE);

	return success;
}

typedef struct {
	gint country_code;
	gchar *national;
} E164Number;

static E164Number *
ebc_e164_number_new (gint country_code,
		     const gchar *national)
{
	E164Number *number = g_slice_new (E164Number);

	number->country_code = country_code;
	number->national = g_strdup (national);

	return number;
}

static void
ebc_e164_number_free (E164Number *number)
{
	if (number) {
		g_free (number->national);
		g_slice_free (E164Number, number);
	}
}

static gint
ebc_e164_number_find (E164Number *number_a,
		      E164Number *number_b)
{
	gint ret;

	ret = number_a->country_code - number_b->country_code;

	if (ret == 0) {
		ret = g_strcmp0 (
			number_a->national,
			number_b->national);
	}

	return ret;
}

static GList *
extract_e164_attribute_params (EContact *contact)
{
	EVCard *vcard = E_VCARD (contact);
	GList *extracted = NULL;
	GList *attr_list;

	for (attr_list = e_vcard_get_attributes (vcard); attr_list; attr_list = attr_list->next) {
		EVCardAttribute *const attr = attr_list->data;
		EVCardAttributeParam *param = NULL;
		GList *param_list, *values, *l;
		gchar *this_national = NULL;
		gint this_country = 0;

		/* We only attach E164 parameters to TEL attributes. */
		if (strcmp (e_vcard_attribute_get_name (attr), EVC_TEL) != 0)
			continue;

		/* Find already exisiting parameter, so that we can reuse it. */
		for (param_list = e_vcard_attribute_get_params (attr); param_list; param_list = param_list->next) {
			if (strcmp (e_vcard_attribute_param_get_name (param_list->data), EVC_X_E164) == 0) {
				param = param_list->data;
				break;
			}
		}

		if (!param)
			continue;

		values = e_vcard_attribute_param_get_values (param);
		for (l = values; l; l = l->next) {
			const gchar *value = l->data;

			if (value[0] == '+')
				this_country = g_ascii_strtoll (&value[1], NULL, 10);
			else if (this_national == NULL)
				this_national = g_strdup (value);
		}

		if (this_national) {
			E164Number *number;

			number = ebc_e164_number_new (this_country, this_national);
			extracted = g_list_prepend (extracted, number);
		}

		g_free (this_national);

		/* Clear the values, we'll insert new ones */
		e_vcard_attribute_param_remove_values (param);
		e_vcard_attribute_remove_param (attr, EVC_X_E164);
	}

	return extracted;
}

static gboolean
update_e164_attribute_params (EBookCache *book_cache,
			      EContact *contact,
			      const gchar *default_region)
{
	GList *original_numbers = NULL;
	GList *attr_list;
	gboolean changed = FALSE;
	gint n_numbers = 0;
	EVCard *vcard = E_VCARD (contact);

	original_numbers = extract_e164_attribute_params (contact);

	for (attr_list = e_vcard_get_attributes (vcard); attr_list; attr_list = attr_list->next) {
		EVCardAttribute *const attr = attr_list->data;
		EVCardAttributeParam *param = NULL;
		const gchar *original_number = NULL;
		gchar *country_string;
		GList *values;
		E164Number number = { 0, NULL };

		/* We only attach E164 parameters to TEL attributes. */
		if (strcmp (e_vcard_attribute_get_name (attr), EVC_TEL) != 0)
			continue;

		/* Fetch the TEL value */
		values = e_vcard_attribute_get_values (attr);

		/* Compute E164 number based on the TEL value */
		if (values && values->data) {
			original_number = (const gchar *) values->data;
			number.national = convert_phone (original_number, book_cache->priv->region_code, &(number.country_code));
		}

		if (number.national == NULL)
			continue;

		/* Count how many we successfully parsed in this region code */
		n_numbers++;

		/* Check if we have a differing e164 number, if there is no match
		 * in the old existing values then the vcard changed
		 */
		if (!g_list_find_custom (original_numbers, &number, (GCompareFunc) ebc_e164_number_find))
			changed = TRUE;

		if (number.country_code != 0)
			country_string = g_strdup_printf ("+%d", number.country_code);
		else
			country_string = g_strdup ("");

		param = e_vcard_attribute_param_new (EVC_X_E164);
		e_vcard_attribute_add_param (attr, param);

		/* Assign the parameter values. It seems odd that we revert
		 * the order of NN and CC, but at least EVCard's parser doesn't
		 * permit an empty first param value. Which of course could be
		 * fixed - in order to create a nice potential IOP problem with
		 ** other vCard parsers. */
		e_vcard_attribute_param_add_values (param, number.national, country_string, NULL);

		g_free (number.national);
		g_free (country_string);
	}

	if (!changed && n_numbers != g_list_length (original_numbers))
		changed = TRUE;

	g_list_free_full (original_numbers, (GDestroyNotify) ebc_e164_number_free);

	return changed;
}

static gboolean
e_book_cache_get_string (ECache *cache,
			 gint ncols,
			 const gchar **column_names,
			 const gchar **column_values,
			 gpointer user_data)
{
	gchar **pvalue = user_data;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (pvalue != NULL, FALSE);

	if (!*pvalue)
		*pvalue = g_strdup (column_values[0]);

	return TRUE;
}

static gboolean
e_book_cache_get_strings (ECache *cache,
			  gint ncols,
			  const gchar **column_names,
			  const gchar **column_values,
			  gpointer user_data)
{
	GSList **pvalues = user_data;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (pvalues != NULL, FALSE);

	*pvalues = g_slist_prepend (*pvalues, g_strdup (column_values[0]));

	return TRUE;
}

static gboolean
e_book_cache_get_old_contacts_cb (ECache *cache,
				  gint ncols,
				  const gchar *column_names[],
				  const gchar *column_values[],
				  gpointer user_data)
{
	GSList **pold_contacts = user_data;

	g_return_val_if_fail (pold_contacts != NULL, FALSE);
	g_return_val_if_fail (ncols == 3, FALSE);

	if (column_values[0] && column_values[1]) {
		*pold_contacts = g_slist_prepend (*pold_contacts,
			e_book_cache_search_data_new (column_values[0], column_values[1], column_values[2]));
	}

	return TRUE;
}

static gboolean
e_book_cache_gather_table_names_cb (ECache *cache,
				    gint ncols,
				    const gchar *column_names[],
				    const gchar *column_values[],
				    gpointer user_data)
{
	GSList **ptables = user_data;

	g_return_val_if_fail (ptables != NULL, FALSE);
	g_return_val_if_fail (ncols == 1, FALSE);

	*ptables = g_slist_prepend (*ptables, g_strdup (column_values[0]));

	return TRUE;
}

static gboolean
e_book_cache_fill_pgp_cert_column (ECache *cache,
				   const gchar *uid,
				   const gchar *revision,
				   const gchar *object,
				   EOfflineState offline_state,
				   gint ncols,
				   const gchar *column_names[],
				   const gchar *column_values[],
				   gchar **out_revision,
				   gchar **out_object,
				   EOfflineState *out_offline_state,
				   ECacheColumnValues **out_other_columns,
				   gpointer user_data)
{
	EContact *contact;
	EContactCert *cert;

	g_return_val_if_fail (object != NULL, FALSE);
	g_return_val_if_fail (out_other_columns != NULL, FALSE);

	contact = e_contact_new_from_vcard (object);
	if (!contact)
		return TRUE;

	*out_other_columns = e_cache_column_values_new ();
	cert = e_contact_get (contact, E_CONTACT_PGP_CERT);

	e_cache_column_values_take_value (*out_other_columns, e_contact_field_name (E_CONTACT_PGP_CERT), g_strdup_printf ("%d", cert ? 1 : 0));

	e_contact_cert_free (cert);
	g_object_unref (contact);

	return TRUE;
}

static gboolean
e_book_cache_migrate (ECache *cache,
		      gint from_version,
		      GCancellable *cancellable,
		      GError **error)
{
	EBookCache *book_cache = E_BOOK_CACHE (cache);
	gboolean success = TRUE;

	/* Migration from EBookSqlite database */
	if (from_version <= 0) {
		GSList *tables = NULL, *old_contacts = NULL, *link;

		if (e_cache_sqlite_select (cache, "SELECT uid,vcard,bdata FROM folder_id ORDER BY uid",
			e_book_cache_get_old_contacts_cb, &old_contacts, cancellable, NULL)) {

			old_contacts = g_slist_reverse (old_contacts);

			for (link = old_contacts; link && success; link = g_slist_next (link)) {
				EBookCacheSearchData *data = link->data;
				EContact *contact;

				if (!data)
					continue;

				contact = e_contact_new_from_vcard_with_uid (data->vcard, data->uid);
				if (!contact)
					continue;

				success = e_book_cache_put_contact (book_cache, contact, data->extra, E_CACHE_IS_ONLINE, cancellable, error);
			}
		}

		/* Delete obsolete tables */
		success = success && e_cache_sqlite_select (cache,
			"SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'folder_id%'",
			e_book_cache_gather_table_names_cb, &tables, cancellable, error);

		for (link = tables; link && success; link = g_slist_next (link)) {
			const gchar *name = link->data;
			gchar *stmt;

			if (!name)
				continue;

			stmt = e_cache_sqlite_stmt_printf ("DROP TABLE IF EXISTS %Q", name);
			success = e_cache_sqlite_exec (cache, stmt, cancellable, error);
			e_cache_sqlite_stmt_free (stmt);
		}

		g_slist_free_full (tables, g_free);

		success = success && e_cache_sqlite_exec (cache, "DROP TABLE IF EXISTS keys", cancellable, error);
		success = success && e_cache_sqlite_exec (cache, "DROP TABLE IF EXISTS folders", cancellable, error);
		success = success && e_cache_sqlite_exec (cache, "DROP TABLE IF EXISTS folder_id", cancellable, error);

		if (success) {
			/* Save the changes by finishing the transaction */
			e_cache_unlock (cache, E_CACHE_UNLOCK_COMMIT);
			e_cache_lock (cache, E_CACHE_LOCK_WRITE);

			/* Try to vacuum, but do not claim any error if failed */
			e_cache_sqlite_maybe_vacuum (cache, cancellable, NULL);
		}

		g_slist_free_full (old_contacts, e_book_cache_search_data_free);
	}

	/* Add any version-related changes here */
	if (success && from_version > 0 && from_version < E_BOOK_CACHE_VERSION) {
		if (from_version == 1) {
			/* Version 2 added E_CONTACT_PGP_CERT existence into the summary */
			success = e_cache_foreach_update (cache, E_CACHE_INCLUDE_DELETED, NULL, e_book_cache_fill_pgp_cert_column, NULL, cancellable, error);
		}
	}

	return success;
}

static gboolean
e_book_cache_populate_other_columns (EBookCache *book_cache,
				     ESourceBackendSummarySetup *setup,
				     GSList **out_columns, /* ECacheColumnInfo * */
				     GError **error)
{
	GSList *columns = NULL;
	gboolean use_default;
	gboolean success = TRUE;
	gint ii;

	g_return_val_if_fail (out_columns != NULL, FALSE);

	#define add_column(_name, _type, _index_name) G_STMT_START { \
		columns = g_slist_prepend (columns, e_cache_column_info_new (_name, _type, _index_name)); \
		} G_STMT_END

	add_column (EBC_COLUMN_EXTRA, "TEXT", NULL);

	use_default = !setup;

	if (setup) {
		EContactField *fields;
		EContactField *indexed_fields;
		EBookIndexType *index_types = NULL;
		gint n_fields = 0, n_indexed_fields = 0, ii;

		fields = e_source_backend_summary_setup_get_summary_fields (setup, &n_fields);
		indexed_fields = e_source_backend_summary_setup_get_indexed_fields (setup, &index_types, &n_indexed_fields);

		if (n_fields <= 0 || n_fields >= EBC_MAX_SUMMARY_FIELDS) {
			if (n_fields)
				g_warning ("EBookCache refused to create cache with more than %d summary fields", EBC_MAX_SUMMARY_FIELDS);
			use_default = TRUE;
		} else {
			GArray *summary_fields;

			summary_fields = g_array_new (FALSE, FALSE, sizeof (SummaryField));

			/* Ensure the non-optional fields first */
			summary_field_append (summary_fields, E_CONTACT_UID, error);
			summary_field_append (summary_fields, E_CONTACT_REV, error);

			for (ii = 0; ii < n_fields; ii++) {
				if (!summary_field_append (summary_fields, fields[ii], error)) {
					success = FALSE;
					break;
				}
			}

			if (!success) {
				gint n_sfields;
				SummaryField *sfields;

				/* Properly free the array */
				n_sfields = summary_fields->len;
				sfields = (SummaryField *) g_array_free (summary_fields, FALSE);
				summary_fields_array_free (sfields, n_sfields);

				g_free (fields);
				g_free (index_types);
				g_free (indexed_fields);

				g_slist_free_full (columns, e_cache_column_info_free);

				return FALSE;
			}

			/* Add the 'indexed' flag to the SummaryField structs */
			summary_fields_add_indexes (summary_fields, indexed_fields, index_types, n_indexed_fields);

			book_cache->priv->n_summary_fields = summary_fields->len;
			book_cache->priv->summary_fields = (SummaryField *) g_array_free (summary_fields, FALSE);
		}

		g_free (fields);
		g_free (index_types);
		g_free (indexed_fields);
	}

	if (use_default) {
		GArray *summary_fields;

		g_warn_if_fail (book_cache->priv->n_summary_fields == 0);

		/* Create the default summary structs */
		summary_fields = g_array_new (FALSE, FALSE, sizeof (SummaryField));
		for (ii = 0; ii < G_N_ELEMENTS (default_summary_fields); ii++) {
			summary_field_append (summary_fields, default_summary_fields[ii], NULL);
		}

		/* Add the default index flags */
		summary_fields_add_indexes (
			summary_fields,
			default_indexed_fields,
			default_index_types,
			G_N_ELEMENTS (default_indexed_fields));

		book_cache->priv->n_summary_fields = summary_fields->len;
		book_cache->priv->summary_fields = (SummaryField *) g_array_free (summary_fields, FALSE);
	}

	#undef add_column

	if (success) {
		for (ii = 0; ii < book_cache->priv->n_summary_fields; ii++) {
			SummaryField *fld = &(book_cache->priv->summary_fields[ii]);

			summary_field_init_dbnames (fld);

			if (fld->type != E_TYPE_CONTACT_ATTR_LIST)
				summary_field_prepend_columns (fld, &columns);
		}
	}

	*out_columns = columns;

	return success;
}

static gboolean
e_book_cache_initialize (EBookCache *book_cache,
			 const gchar *filename,
			 ESource *source,
			 ESourceBackendSummarySetup *setup,
			 GCancellable *cancellable,
			 GError **error)
{
	ECache *cache;
	GSList *other_columns = NULL;
	sqlite3 *db;
	gint ii, sqret;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (filename != NULL, FALSE);
	if (source)
		g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	if (setup)
		g_return_val_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (setup), FALSE);

	if (source)
		book_cache->priv->source = g_object_ref (source);

	cache = E_CACHE (book_cache);

	success = e_book_cache_populate_other_columns (book_cache, setup, &other_columns, error);
	if (!success)
		goto exit;

	success = e_cache_initialize_sync (cache, filename, other_columns, cancellable, error);
	if (!success)
		goto exit;

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	db = e_cache_get_sqlitedb (cache);
	sqret = SQLITE_OK;

	/* Install our custom functions */
	for (ii = 0; sqret == SQLITE_OK && ii < G_N_ELEMENTS (ebc_custom_functions); ii++) {
		sqret = sqlite3_create_function (
			db,
			ebc_custom_functions[ii].name,
			ebc_custom_functions[ii].arguments,
			SQLITE_UTF8, book_cache,
			ebc_custom_functions[ii].func,
			NULL, NULL);
	}

	/* Fallback COLLATE implementations generated on demand */
	if (sqret == SQLITE_OK)
		sqret = sqlite3_collation_needed (db, book_cache, ebc_generate_collator);

	if (sqret != SQLITE_OK) {
		if (!db) {
			g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_LOAD, _("Insufficient memory"));
		} else {
			const gchar *errmsg = sqlite3_errmsg (db);

			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_ENGINE, _("Can’t open database %s: %s"), filename, errmsg);
		}

		success = FALSE;
	}

	success = success && ebc_init_locale (book_cache, cancellable, error);

	success = success && ebc_init_aux_tables (book_cache, cancellable, error);

	/* Check for data migration */
	success = success && e_book_cache_migrate (cache, e_cache_get_version (cache), cancellable, error);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	if (!success)
		goto exit;

	if (e_cache_get_version (cache) != E_BOOK_CACHE_VERSION)
		e_cache_set_version (cache, E_BOOK_CACHE_VERSION);

 exit:
	g_slist_free_full (other_columns, e_cache_column_info_free);

	return success;
}

/**
 * e_book_cache_new:
 * @filename: file name to load or create the new cache
 * @source: (nullable): an optional #ESource, associated with the #EBookCache, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EBookCache with the default summary configuration.
 *
 * Aside from the mandatory fields %E_CONTACT_UID, %E_CONTACT_REV,
 * the default configuration stores the following fields for quick
 * performance of searches: %E_CONTACT_FILE_AS, %E_CONTACT_NICKNAME,
 * %E_CONTACT_FULL_NAME, %E_CONTACT_GIVEN_NAME, %E_CONTACT_FAMILY_NAME,
 * %E_CONTACT_EMAIL, %E_CONTACT_TEL, %E_CONTACT_IS_LIST, %E_CONTACT_LIST_SHOW_ADDRESSES,
 * and %E_CONTACT_WANTS_HTML.
 *
 * The fields %E_CONTACT_FULL_NAME and %E_CONTACT_EMAIL are configured
 * to respond extra quickly with the %E_BOOK_INDEX_PREFIX index flag.
 *
 * The fields %E_CONTACT_FILE_AS, %E_CONTACT_FAMILY_NAME and
 * %E_CONTACT_GIVEN_NAME are configured to perform well with
 * the #EBookCacheCursor, using the %E_BOOK_INDEX_SORT_KEY
 * index flag.
 *
 * Returns: (transfer full) (nullable): A new #EBookCache or %NULL on error
 *
 * Since: 3.26
 **/
EBookCache *
e_book_cache_new (const gchar *filename,
		  ESource *source,
		  GCancellable *cancellable,
		  GError **error)
{
	g_return_val_if_fail (filename != NULL, NULL);

	return e_book_cache_new_full (filename, source, NULL, cancellable, error);
}

/**
 * e_book_cache_new_full:
 * @filename: file name to load or create the new cache
 * @source: (nullable): an optional #ESource, associated with the #EBookCache, or %NULL
 * @setup: (nullable): an #ESourceBackendSummarySetup describing how the summary should be setup, or %NULL to use the default
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EBookCache with the given or the default summary configuration.
 *
 * Like e_book_sqlite_new(), but allows configuration of which contact fields
 * will be stored for quick reference in the summary. The configuration indicated by
 * @setup will only be taken into account when initially creating the underlying table,
 * further configurations will be ignored.
 *
 * The fields %E_CONTACT_UID and %E_CONTACT_REV are not optional,
 * they will be stored in the summary regardless of this function's parameters.
 * Only #EContactFields with the type %G_TYPE_STRING, %G_TYPE_BOOLEAN or
 * %E_TYPE_CONTACT_ATTR_LIST are currently supported.
 *
 * Returns: (transfer full) (nullable): A new #EBookCache or %NULL on error
 *
 * Since: 3.26
 **/
EBookCache *
e_book_cache_new_full (const gchar *filename,
		       ESource *source,
		       ESourceBackendSummarySetup *setup,
		       GCancellable *cancellable,
		       GError **error)
{
	EBookCache *book_cache;

	g_return_val_if_fail (filename != NULL, NULL);

	book_cache = g_object_new (E_TYPE_BOOK_CACHE, NULL);

	if (!e_book_cache_initialize (book_cache, filename, source, setup, cancellable, error)) {
		g_object_unref (book_cache);
		book_cache = NULL;
	}

	return book_cache;
}

/**
 * e_book_cache_ref_source:
 * @book_cache: An #EBookCache
 *
 * References the #ESource to which @book_cache is paired,
 * use g_object_unref() when no longer needed.
 * It can be %NULL in some cases, like when running tests.
 *
 * Returns: (transfer full): A reference to the #ESource to which @book_cache
 *    is paired, or %NULL.
 *
 * Since: 3.26
 **/
ESource *
e_book_cache_ref_source (EBookCache *book_cache)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);

	if (book_cache->priv->source)
		return g_object_ref (book_cache->priv->source);

	return NULL;
}

/**
 * e_book_cache_dup_contact_revision:
 * @book_cache: an #EBookCache
 * @contact: an #EContact
 *
 * Returns the @contact revision, used to detect changes.
 * The returned string should be freed with g_free(), when
 * no longer needed.
 *
 * Returns: (transfer full): A newly allocated string containing
 *    revision of the @contact.
 *
 * Since: 3.26
 **/
gchar *
e_book_cache_dup_contact_revision (EBookCache *book_cache,
				   EContact *contact)
{
	gchar *revision = NULL;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);
	g_return_val_if_fail (E_IS_CONTACT (contact), NULL);

	g_signal_emit (book_cache, signals[DUP_CONTACT_REVISION], 0, contact, &revision);

	return revision;
}

/**
 * e_book_cache_set_locale:
 * @book_cache: An #EBookCache
 * @lc_collate: The new locale for the cache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Relocalizes any locale specific data in the specified
 * new @lc_collate locale.
 *
 * The @lc_collate locale setting is stored and remembered on
 * subsequent accesses of the cache, changing the locale will
 * store the new locale and will modify sort keys and any
 * locale specific data in the cache.
 *
 * As a side effect, it's possible that changing the locale
 * will cause stored vCard-s to change.
 *
 * Returns: Whether the new locale was successfully set.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_set_locale (EBookCache *book_cache,
			 const gchar *lc_collate,
			 GCancellable *cancellable,
			 GError **error)
{
	ECache *cache;
	gboolean success, changed = FALSE;
	gchar *stored_lc_collate = NULL;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);

	cache = E_CACHE (book_cache);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	success = ebc_set_locale_internal (book_cache, lc_collate, error);

	if (success)
		stored_lc_collate = e_cache_dup_key (cache, EBC_KEY_LC_COLLATE, NULL);

	if (success && g_strcmp0 (stored_lc_collate, lc_collate) != 0)
		success = ebc_upgrade (book_cache, cancellable, error);

	/* If for some reason we failed, then reset the collator to use the old locale */
	if (!success && stored_lc_collate && stored_lc_collate[0]) {
		ebc_set_locale_internal (book_cache, stored_lc_collate, NULL);
		changed = TRUE;
	}

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	g_free (stored_lc_collate);

	if (success || changed)
		g_object_notify (G_OBJECT (book_cache), "locale");

	return success;
}

/**
 * e_book_cache_dup_locale:
 * @book_cache: An #EBookCache
 *
 * Returns: (transfer full): A new string containing the current local
 *    being used by the @book_cache. Free it with g_free(), when no
 *    longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_book_cache_dup_locale (EBookCache *book_cache)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);

	return g_strdup (book_cache->priv->locale);
}

/**
 * e_book_cache_ref_collator:
 * @book_cache: An #EBookCache
 *
 * References the currently active #ECollator for @book_cache,
 * use e_collator_unref() when finished using the returned collator.
 *
 * Note that the active collator will change with the active locale setting.
 *
 * Returns: (transfer full): A reference to the active collator.
 *
 * Since: 3.26
 **/
ECollator *
e_book_cache_ref_collator (EBookCache *book_cache)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);

	return e_collator_ref (book_cache->priv->collator);
}

/**
 * e_book_cache_put_contact:
 * @book_cache: An #EBookCache
 * @contact: an #EContact to be added
 * @extra: extra data to store in association with this contact
 * @offline_flag: one of #ECacheOfflineFlag, whether putting this contact in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * This is a convenience wrapper for e_book_cache_put_contacts(),
 * which is the preferred way to add or modify multiple contacts when possible.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_put_contact (EBookCache *book_cache,
			  EContact *contact,
			  const gchar *extra,
			  ECacheOfflineFlag offline_flag,
			  GCancellable *cancellable,
			  GError **error)
{
	GSList *contacts, *extras;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	contacts = g_slist_append (NULL, contact);
	extras = g_slist_append (NULL, (gpointer) extra);

	success = e_book_cache_put_contacts (book_cache, contacts, extras, offline_flag, cancellable, error);

	g_slist_free (contacts);
	g_slist_free (extras);

	return success;
}

/**
 * e_book_cache_put_contacts:
 * @book_cache: An #EBookCache
 * @contacts: (element-type EContact): A list of contacts to add to @book_cache
 * @extras: (nullable) (element-type utf8): A list of extra data to store in association with the @contacts
 * @offline_flag: one of #ECacheOfflineFlag, whether putting these contacts in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Adds or replaces contacts in @book_cache.
 *
 * If @extras is specified, it must have an equal length as the @contacts list. Each element
 * from the @extras list will be stored in association with its corresponding contact
 * in the @contacts list.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_put_contacts (EBookCache *book_cache,
			   const GSList *contacts,
			   const GSList *extras,
			   ECacheOfflineFlag offline_flag,
			   GCancellable *cancellable,
			   GError **error)
{
	const GSList *clink, *elink;
	ECache *cache;
	ECacheColumnValues *other_columns;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (contacts != NULL, FALSE);
	g_return_val_if_fail (extras == NULL || g_slist_length ((GSList *) extras) == g_slist_length ((GSList *) contacts), FALSE);

	cache = E_CACHE (book_cache);
	other_columns = e_cache_column_values_new ();

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);
	e_cache_freeze_revision_change (cache);

	for (clink = contacts, elink = extras; clink; clink = g_slist_next (clink), elink = g_slist_next (elink)) {
		EContact *contact = clink->data;
		const gchar *extra = elink ? elink->data : NULL;
		gchar *uid, *rev, *vcard;

		g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

		vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);
		g_return_val_if_fail (vcard != NULL, FALSE);

		e_cache_column_values_remove_all (other_columns);

		if (extra)
			e_cache_column_values_take_value (other_columns, EBC_COLUMN_EXTRA, g_strdup (extra));

		uid = e_contact_get (contact, E_CONTACT_UID);
		rev = e_book_cache_dup_contact_revision (book_cache, contact);

		ebc_fill_other_columns (book_cache, contact, other_columns);

		success = e_cache_put (cache, uid, rev, vcard, other_columns, offline_flag, cancellable, error);

		g_free (vcard);
		g_free (rev);
		g_free (uid);

		if (!success)
			break;
	}

	e_cache_thaw_revision_change (cache);
	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	e_cache_column_values_free (other_columns);

	return success;
}

/**
 * e_book_cache_remove_contact:
 * @book_cache: An #EBookCache
 * @uid: the uid of the contact to remove
 * @offline_flag: one of #ECacheOfflineFlag, whether removing this contact in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes the contact identified by @uid from @book_cache.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_remove_contact (EBookCache *book_cache,
			     const gchar *uid,
			     ECacheOfflineFlag offline_flag,
			     GCancellable *cancellable,
			     GError **error)
{
	GSList *uids;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	uids = g_slist_append (NULL, (gpointer) uid);

	success = e_book_cache_remove_contacts (book_cache, uids, offline_flag, cancellable, error);

	g_slist_free (uids);

	return success;
}

/**
 * e_book_cache_remove_contacts:
 * @book_cache: An #EBookCache
 * @uids: (element-type utf8): a #GSList of uids indicating which contacts to remove
 * @offline_flag: one of #ECacheOfflineFlag, whether removing these contacts in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes the contacts indicated by @uids from @book_cache.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_remove_contacts (EBookCache *book_cache,
			      const GSList *uids,
			      ECacheOfflineFlag offline_flag,
			      GCancellable *cancellable,
			      GError **error)
{
	ECache *cache;
	const GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	cache = E_CACHE (book_cache);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);
	e_cache_freeze_revision_change (cache);

	for (link = uids; success && link; link = g_slist_next (link)) {
		const gchar *uid = link->data;

		success = e_cache_remove (cache, uid, offline_flag, cancellable, error);
	}

	e_cache_thaw_revision_change (cache);
	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_book_cache_get_contact:
 * @book_cache: An #EBookCache
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @out_contact: (out) (transfer full): Return location to store the fetched contact
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Fetch the #EContact specified by @uid in @book_cache.
 *
 * If @meta_contact is specified, then a shallow #EContact will be created
 * holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_get_contact (EBookCache *book_cache,
			  const gchar *uid,
			  gboolean meta_contact,
			  EContact **out_contact,
			  GCancellable *cancellable,
			  GError **error)
{
	gchar *vcard = NULL;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_contact != NULL, FALSE);

	*out_contact = NULL;

	if (!e_book_cache_get_vcard (book_cache, uid, meta_contact, &vcard, cancellable, error) ||
	    !vcard) {
		return FALSE;
	}

	*out_contact = e_contact_new_from_vcard_with_uid (vcard, uid);

	g_free (vcard);

	return TRUE;
}

/**
 * e_book_cache_get_vcard:
 * @book_cache: An #EBookCache
 * @uid: The uid of the contact to fetch
 * @meta_contact: Whether an entire contact is desired, or only the metadata
 * @out_vcard: (out) (transfer full): Return location to store the fetched vCard string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Fetch a vCard string for @uid in @book_cache.
 *
 * If @meta_contact is specified, then a shallow vCard representation will be
 * created holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_get_vcard (EBookCache *book_cache,
			const gchar *uid,
			gboolean meta_contact,
			gchar **out_vcard,
			GCancellable *cancellable,
			GError **error)
{
	gchar *full_vcard, *revision = NULL;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_vcard != NULL, FALSE);

	*out_vcard = NULL;

	full_vcard = e_cache_get (E_CACHE (book_cache), uid,
		meta_contact ? &revision : NULL,
		NULL, cancellable, error);

	if (!full_vcard) {
		g_warn_if_fail (revision == NULL);
		return FALSE;
	}

	if (meta_contact) {
		EContact *contact = e_contact_new ();

		e_contact_set (contact, E_CONTACT_UID, uid);
		if (revision)
			e_contact_set (contact, E_CONTACT_REV, revision);

		*out_vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

		g_object_unref (contact);
		g_free (full_vcard);
	} else {
		*out_vcard = full_vcard;
	}

	g_free (revision);

	return TRUE;
}

/**
 * e_book_cache_set_contact_extra:
 * @book_cache: An #EBookCache
 * @uid: The uid of the contact to set the extra data for
 * @extra: (nullable): The extra data to set
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Sets or replaces the extra data associated with @uid.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_set_contact_extra (EBookCache *book_cache,
				const gchar *uid,
				const gchar *extra,
				GCancellable *cancellable,
				GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_cache_contains (E_CACHE (book_cache), uid, E_CACHE_INCLUDE_DELETED)) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
		return FALSE;
	}

	if (extra) {
		stmt = e_cache_sqlite_stmt_printf (
			"UPDATE " E_CACHE_TABLE_OBJECTS " SET " EBC_COLUMN_EXTRA "=%Q"
			" WHERE " E_CACHE_COLUMN_UID "=%Q",
			extra, uid);
	} else {
		stmt = e_cache_sqlite_stmt_printf (
			"UPDATE " E_CACHE_TABLE_OBJECTS " SET " EBC_COLUMN_EXTRA "=NULL"
			" WHERE " E_CACHE_COLUMN_UID "=%Q",
			uid);
	}

	success = e_cache_sqlite_exec (E_CACHE (book_cache), stmt, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	return success;
}

/**
 * e_book_cache_get_contact_extra:
 * @book_cache: An #EBookCache
 * @uid: The uid of the contact to fetch the extra data for
 * @out_extra: (out) (transfer full): Return location to store the extra data
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Fetches the extra data previously set for @uid, either with
 * e_book_cache_set_contact_extra() or when adding contacts.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_get_contact_extra (EBookCache *book_cache,
				const gchar *uid,
				gchar **out_extra,
				GCancellable *cancellable,
				GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_cache_contains (E_CACHE (book_cache), uid, E_CACHE_INCLUDE_DELETED)) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
		return FALSE;
	}

	stmt = e_cache_sqlite_stmt_printf (
		"SELECT " EBC_COLUMN_EXTRA " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " E_CACHE_COLUMN_UID "=%Q",
		uid);

	success = e_cache_sqlite_select (E_CACHE (book_cache), stmt, e_book_cache_get_string, out_extra, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	return success;
}

/**
 * e_book_cache_get_uids_with_extra:
 * @book_cache: an #EBookCache
 * @extra: an extra column value to search for
 * @out_uids: (out) (transfer full) (element-type utf8): return location to store the UIDs to
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets all the UID-s the @extra data is set for.
 *
 * The @out_uids should be freed with
 * g_slist_free_full (uids, g_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_get_uids_with_extra (EBookCache *book_cache,
				  const gchar *extra,
				  GSList **out_uids,
				  GCancellable *cancellable,
				  GError **error)
{
	gchar *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (extra != NULL, FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	*out_uids = NULL;

	stmt = e_cache_sqlite_stmt_printf (
		"SELECT " E_CACHE_COLUMN_UID " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " EBC_COLUMN_EXTRA "=%Q",
		extra);

	success = e_cache_sqlite_select (E_CACHE (book_cache), stmt, e_book_cache_get_strings, out_uids, cancellable, error);

	e_cache_sqlite_stmt_free (stmt);

	if (success && !*out_uids) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object with extra “%s” not found"), extra);
		success = FALSE;
	} else {
		*out_uids = g_slist_reverse (*out_uids);
	}

	return success;
}

/**
 * e_book_cache_search:
 * @book_cache: An #EBookCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to list all stored contacts
 * @meta_contacts: Whether entire contacts are desired, or only the metadata
 * @out_list: (out) (transfer full) (element-type EBookCacheSearchData): Return location
 *    to store a #GSList of #EBookCacheSearchData structures
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches @book_cache for contacts matching the search expression @sexp.
 *
 * When @sexp refers only to #EContactFields configured in the summary of @book_cache,
 * the search should always be quick, when searching for other #EContactFields
 * a fallback will be used.
 *
 * The returned @out_list list should be freed with g_slist_free_full (list, e_book_cache_search_data_free)
 * when no longer needed.
 *
 * If @meta_contact is specified, then shallow vCard representations will be
 * created holding only the %E_CONTACT_UID and %E_CONTACT_REV fields.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_search (EBookCache *book_cache,
		     const gchar *sexp,
		     gboolean meta_contacts,
		     GSList **out_list,
		     GCancellable *cancellable,
		     GError **error)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (out_list != NULL, FALSE);

	*out_list = NULL;

	return ebc_search_internal (book_cache, sexp,
		meta_contacts ? SEARCH_UID_AND_REV : SEARCH_FULL,
		out_list, NULL, NULL, cancellable, error);
}

/**
 * e_book_cache_search_uids:
 * @book_cache: An #EBookCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to get all stored contacts
 * @out_list: (out) (transfer full) (element-type utf8): Return location to store a #GSList of contact uids
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Similar to e_book_cache_search(), but fetches only a list of contact UIDs.
 *
 * The returned @out_list list should be freed with g_slist_free_full(list, g_free)
 * when no longer needed.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_search_uids (EBookCache *book_cache,
			  const gchar *sexp,
			  GSList **out_list,
			  GCancellable *cancellable,
			  GError **error)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (out_list != NULL, FALSE);

	*out_list = NULL;

	return ebc_search_internal (book_cache, sexp, SEARCH_UID, out_list, NULL, NULL, cancellable, error);
}

/**
 * e_book_cache_search_with_callback:
 * @book_cache: An #EBookCache
 * @sexp: (nullable): search expression; use %NULL or an empty string to get all stored contacts
 * @func: an #EBookCacheSearchFunc callback to call for each found row
 * @user_data: user data for @func
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Similar to e_book_cache_search(), but calls the @func for each found contact.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set appropriately.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_search_with_callback (EBookCache *book_cache,
				   const gchar *sexp,
				   EBookCacheSearchFunc func,
				   gpointer user_data,
				   GCancellable *cancellable,
				   GError **error)
{
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (func != NULL, FALSE);

	return ebc_search_internal (book_cache, sexp, SEARCH_FULL, NULL, func, user_data, cancellable, error);
}

/**
 * e_book_cache_cursor_new:
 * @book_cache: An #EBookCache
 * @sexp: search expression; use %NULL or an empty string to get all stored contacts
 * @sort_fields: (array length=n_sort_fields): An array of #EContactField(s) as sort keys in order of priority
 * @sort_types: (array length=n_sort_fields): An array of #EBookCursorSortTypes, one for each field in @sort_fields
 * @n_sort_fields: The number of fields to sort results by
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EBookCacheCursor.
 *
 * The cursor should be freed with e_book_cache_cursor_free() when
 * no longer needed.
 *
 * Returns: (transfer full): A newly created #EBookCacheCursor
 *
 * Since: 3.26
 **/
EBookCacheCursor *
e_book_cache_cursor_new (EBookCache *book_cache,
			 const gchar *sexp,
			 const EContactField *sort_fields,
			 const EBookCursorSortType *sort_types,
			 guint n_sort_fields,
			 GError **error)
{
	EBookCacheCursor *cursor;
	gint ii;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);

	/* We don't like '\0' sexps, prefer NULL */
	if (sexp && !*sexp)
		sexp = NULL;

	e_cache_lock (E_CACHE (book_cache), E_CACHE_LOCK_READ);

	/* Need one sort key ... */
	if (n_sort_fields == 0) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
			_("At least one sort field must be specified to use a cursor"));
		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return NULL;
	}

	/* We only support string fields to sort the cursor */
	for (ii = 0; ii < n_sort_fields; ii++) {
		if (e_contact_field_type (sort_fields[ii]) != G_TYPE_STRING) {
			g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY,
				_("Cannot sort by a field that is not a string type"));

			e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
			return NULL;
		}
	}

	/* Now we need to create the cursor instance before setting up the query
	 * (not really true, but more convenient that way).
	 */
	cursor = ebc_cursor_new (book_cache, sexp, sort_fields, sort_types, n_sort_fields);

	/* Setup the cursor's query expression which might fail */
	if (!ebc_cursor_setup_query (book_cache, cursor, sexp, error)) {
		ebc_cursor_free (cursor);
		cursor = NULL;
	}

	e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);

	return cursor;
}

/**
 * e_book_cache_cursor_free:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor to free
 *
 * Frees the @cursor, previously allocated with e_book_cache_cursor_new().
 *
 * Since: 3.26
 **/
void
e_book_cache_cursor_free (EBookCache *book_cache,
			  EBookCacheCursor *cursor)
{
	g_return_if_fail (E_IS_BOOK_CACHE (book_cache));
	g_return_if_fail (cursor != NULL);

	ebc_cursor_free (cursor);
}

typedef struct {
	gint uid_index;
	gint object_index;
	gint extra_index;

	GSList *results;
	gchar *alloc_vcard;
	const gchar *last_vcard;

	gboolean collect_results;
	gint n_results;
} CursorCollectData;

static gboolean
ebc_collect_results_for_cursor_cb (ECache *cache,
				   gint ncols,
				   const gchar *column_names[],
				   const gchar *column_values[],
				   gpointer user_data)
{
	CursorCollectData *data = user_data;
	const gchar *object = NULL, *extra = NULL;

	if (data->uid_index == -1 ||
	    data->object_index == -1 ||
	    data->extra_index == -1) {
		gint ii;

		for (ii = 0; ii < ncols && (data->uid_index == -1 ||
		     data->object_index == -1 ||
		     data->extra_index == -1); ii++) {
			const gchar *cname = column_names[ii];

			if (!cname)
				continue;

			if (g_str_has_prefix (cname, "summary."))
				cname += 8;

			if (data->uid_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_UID) == 0) {
				data->uid_index = ii;
			} else if (data->object_index == -1 && g_ascii_strcasecmp (cname, E_CACHE_COLUMN_OBJECT) == 0) {
				data->object_index = ii;
			} else if (data->extra_index == -1 && g_ascii_strcasecmp (cname, EBC_COLUMN_EXTRA) == 0) {
				data->extra_index = ii;
			}
		}

		if (data->object_index == -1)
			data->object_index = -2;

		if (data->extra_index == -1)
			data->extra_index = -2;
	}

	g_return_val_if_fail (data->uid_index >= 0 && data->uid_index < ncols, FALSE);

	if (data->object_index != -2) {
		g_return_val_if_fail (data->object_index >= 0 && data->object_index < ncols, FALSE);
		object = column_values[data->object_index];
	}

	if (data->extra_index != -2) {
		g_return_val_if_fail (data->extra_index >= 0 && data->extra_index < ncols, FALSE);
		extra = column_values[data->extra_index];
	}

	if (data->collect_results) {
		EBookCacheSearchData *search_data;

		search_data = e_book_cache_search_data_new (column_values[data->uid_index], object, extra);

		data->results = g_slist_prepend (data->results, search_data);

		data->last_vcard = search_data->vcard;
	} else {
		g_free (data->alloc_vcard);
		data->alloc_vcard = g_strdup (object);

		data->last_vcard = data->alloc_vcard;
	}

	data->n_results++;

	return TRUE;
}

/**
 * e_book_cache_cursor_step:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor to use
 * @flags: The #EBookCacheCursorStepFlags for this step
 * @origin: The #EBookCacheCursorOrigin from whence to step
 * @count: A positive or negative amount of contacts to try and fetch
 * @out_results: (out) (nullable) (element-type EBookCacheSearchData) (transfer full):
 *   A return location to store the results, or %NULL if %E_BOOK_CACHE_CURSOR_STEP_FETCH is not specified in @flags.
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Steps @cursor through its sorted query by a maximum of @count contacts
 * starting from @origin.
 *
 * If @count is negative, then the cursor will move through the list in reverse.
 *
 * If @cursor reaches the beginning or end of the query results, then the
 * returned list might not contain the amount of desired contacts, or might
 * return no results if the cursor currently points to the last contact.
 * Reaching the end of the list is not considered an error condition. Attempts
 * to step beyond the end of the list after having reached the end of the list
 * will however trigger an %E_CACHE_ERROR_END_OF_LIST error.
 *
 * If %E_BOOK_CACHE_CURSOR_STEP_FETCH is specified in @flags, a pointer to
 * a %NULL #GSList pointer should be provided for the @out_results parameter.
 *
 * The result list will be stored to @out_results and should be freed
 * with g_slist_free_full (results, e_book_cache_search_data_free);
 * when no longer needed.
 *
 * Returns: The number of contacts traversed if successful, otherwise -1 is
 *    returned and the @error is set.
 *
 * Since: 3.26
 **/
gint
e_book_cache_cursor_step (EBookCache *book_cache,
			  EBookCacheCursor *cursor,
			  EBookCacheCursorStepFlags flags,
			  EBookCacheCursorOrigin origin,
			  gint count,
			  GSList **out_results,
			  GCancellable *cancellable,
			  GError **error)
{
	CursorCollectData data = { -1, -1, -1, NULL, NULL, NULL, FALSE, 0 };
	CursorState *state;
	GString *query;
	gboolean success;
	EBookCacheCursorOrigin try_position;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), -1);
	g_return_val_if_fail (cursor != NULL, -1);
	g_return_val_if_fail ((flags & E_BOOK_CACHE_CURSOR_STEP_FETCH) == 0 ||
			      (out_results != NULL), -1);

	if (out_results)
		*out_results = NULL;

	e_cache_lock (E_CACHE (book_cache), E_CACHE_LOCK_READ);

	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return -1;
	}

	/* Check if this step should result in an end of list error first */
	try_position = cursor->state.position;
	if (origin != E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT)
		try_position = origin;

	/* Report errors for requests to run off the end of the list */
	if (try_position == E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN && count < 0) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_END_OF_LIST,
			_("Tried to step a cursor in reverse, "
			"but cursor is already at the beginning of the contact list"));

		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return -1;
	} else if (try_position == E_BOOK_CACHE_CURSOR_ORIGIN_END && count > 0) {
		g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_END_OF_LIST,
			_("Tried to step a cursor forwards, "
			"but cursor is already at the end of the contact list"));

		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return -1;
	}

	/* Nothing to do, silently return */
	if (count == 0 && try_position == E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT) {
		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return 0;
	}

	/* If we're not going to modify the position, just use
	 * a copy of the current cursor state.
	 */
	if ((flags & E_BOOK_CACHE_CURSOR_STEP_MOVE) != 0)
		state = &(cursor->state);
	else
		state = cursor_state_copy (cursor, &(cursor->state));

	/* Every query starts with the STATE_CURRENT position, first
	 * fix up the cursor state according to 'origin'
	 */
	switch (origin) {
	case E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT:
		/* Do nothing, normal operation */
		break;

	case E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN:
	case E_BOOK_CACHE_CURSOR_ORIGIN_END:

		/* Prepare the state before executing the query */
		cursor_state_clear (cursor, state, origin);
		break;
	}

	/* If count is 0 then there is no need to run any
	 * query, however it can be useful if you just want
	 * to move the cursor to the beginning or ending of
	 * the list.
	 */
	if (count == 0) {
		/* Free the state copy if need be */
		if ((flags & E_BOOK_CACHE_CURSOR_STEP_MOVE) == 0)
			cursor_state_free (cursor, state);

		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return 0;
	}

	query = g_string_new (cursor->select_vcards);

	/* Add the filter constraints (if any) */
	if (cursor->query) {
		g_string_append (query, " WHERE ");

		g_string_append_c (query, '(');
		g_string_append (query, cursor->query);
		g_string_append_c (query, ')');
	}

	/* Add the cursor constraints (if any) */
	if (state->values[0] != NULL) {
		gchar *constraints = NULL;

		if (!cursor->query)
			g_string_append (query, " WHERE ");
		else
			g_string_append (query, " AND ");

		constraints = ebc_cursor_constraints (book_cache, cursor, state, count < 0, FALSE);

		g_string_append_c (query, '(');
		g_string_append (query, constraints);
		g_string_append_c (query, ')');

		g_free (constraints);
	}

	/* Add the sort order */
	g_string_append_c (query, ' ');
	if (count > 0)
		g_string_append (query, cursor->order);
	else
		g_string_append (query, cursor->reverse_order);

	/* Add the limit */
	g_string_append_printf (query, " LIMIT %d", ABS (count));

	/* Specify whether we really want results or not */
	data.collect_results = (flags & E_BOOK_CACHE_CURSOR_STEP_FETCH) != 0;

	/* Execute the query */
	success = e_cache_sqlite_select (E_CACHE (book_cache), query->str,
		ebc_collect_results_for_cursor_cb, &data,
		cancellable, error);

	/* Lock was obtained above */
	e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);

	g_string_free (query, TRUE);

	/* If there was no error, update the internal cursor state */
	if (success) {
		if (data.n_results < ABS (count)) {
			/* We've reached the end, clear the current state */
			if (count < 0)
				cursor_state_clear (cursor, state, E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN);
			else
				cursor_state_clear (cursor, state, E_BOOK_CACHE_CURSOR_ORIGIN_END);

		} else if (data.last_vcard) {
			/* Set the cursor state to the last result */
			cursor_state_set_from_vcard (book_cache, cursor, state, data.last_vcard);
		} else {
			/* Should never get here */
			g_warn_if_reached ();
		}

		/* Assign the results to return (if any) */
		if (out_results) {
			/* Correct the order of results at the last minute */
			*out_results = g_slist_reverse (data.results);
			data.results = NULL;
		}
	}

	/* Cleanup what was allocated by collect_results_for_cursor_cb() */
	if (data.results)
		g_slist_free_full (data.results, e_book_cache_search_data_free);
	g_free (data.alloc_vcard);

	/* Free the copy state if we were working with a copy */
	if ((flags & E_BOOK_CACHE_CURSOR_STEP_MOVE) == 0)
		cursor_state_free (cursor, state);

	if (success)
		return data.n_results;

	return -1;
}

/**
 * e_book_cache_cursor_set_target_alphabetic_index:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor to modify
 * @idx: The alphabetic index
 *
 * Sets the @cursor position to an
 * <link linkend="cursor-alphabet">Alphabetic Index</link>
 * into the alphabet active in @book_cache's locale.
 *
 * After setting the target to an alphabetic index, for example the
 * index for letter 'E', then further calls to e_book_cache_cursor_step()
 * will return results starting with the letter 'E' (or results starting
 * with the last result in 'D', if moving in a negative direction).
 *
 * The passed index must be a valid index in the active locale, knowledge
 * on the currently active alphabet index must be obtained using #ECollator
 * APIs.
 *
 * Use e_book_cache_ref_collator() to obtain the active collator for @book_cache.
 *
 * Since: 3.26
 **/
void
e_book_cache_cursor_set_target_alphabetic_index (EBookCache *book_cache,
						 EBookCacheCursor *cursor,
						 gint idx)
{
	gint n_labels = 0;

	g_return_if_fail (E_IS_BOOK_CACHE (book_cache));
	g_return_if_fail (cursor != NULL);
	g_return_if_fail (idx >= 0);

	e_collator_get_index_labels (book_cache->priv->collator, &n_labels, NULL, NULL, NULL);
	g_return_if_fail (idx < n_labels);

	cursor_state_clear (cursor, &(cursor->state), E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT);
	if (cursor->n_sort_fields > 0) {
		SummaryField *field;
		gchar *index_key;

		index_key = e_collator_generate_key_for_index (book_cache->priv->collator, idx);
		field = summary_field_get (book_cache, cursor->sort_fields[0]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			cursor->state.values[0] = index_key;
		} else {
			cursor->state.values[0] = ebc_encode_vcard_sort_key (index_key);
			g_free (index_key);
		}
	}
}

/**
 * e_book_cache_cursor_set_sexp:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor to modify
 * @sexp: The new query expression for @cursor
 * @error: return location for a #GError, or %NULL
 *
 * Modifies the current query expression for @cursor. This will not
 * modify @cursor's state, but will change the outcome of any further
 * calls to e_book_cache_cursor_step() or e_book_cache_cursor_calculate().
 *
 * Returns: %TRUE if the expression was valid and accepted by @cursor
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_cursor_set_sexp (EBookCache *book_cache,
			      EBookCacheCursor *cursor,
			      const gchar *sexp,
			      GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (cursor != NULL, FALSE);

	/* We don't like '\0' sexps, prefer NULL */
	if (sexp && !*sexp)
		sexp = NULL;

	e_cache_lock (E_CACHE (book_cache), E_CACHE_LOCK_READ);

	success = ebc_cursor_setup_query (book_cache, cursor, sexp, error);

	e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);

	return success;
}

/**
 * e_book_cache_cursor_calculate:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor
 * @out_total: (out) (nullable): A return location to store the total result set for this cursor
 * @out_position: (out) (nullable): A return location to store the cursor position
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Calculates the @out_total amount of results for the @cursor's query expression,
 * as well as the current @out_position of @cursor in the results. The @out_position is
 * represented as the amount of results which lead up to the current value
 * of @cursor, if @cursor currently points to an exact contact, the position
 * also includes the cursor contact.
 *
 * Returns: Whether @out_total and @out_position were successfully calculated.
 *
 * Since: 3.26
 **/
gboolean
e_book_cache_cursor_calculate (EBookCache *book_cache,
			       EBookCacheCursor *cursor,
			       gint *out_total,
			       gint *out_position,
			       GCancellable *cancellable,
			       GError **error)
{
	gboolean success = TRUE;
	gint local_total = 0;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);
	g_return_val_if_fail (cursor != NULL, FALSE);

	/* If we're in a clear cursor state, then the position is 0 */
	if (out_position && cursor->state.values[0] == NULL) {
		if (cursor->state.position == E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN) {
			/* Mark the local pointer NULL, no need to calculate this anymore */
			*out_position = 0;
			out_position = NULL;
		} else if (cursor->state.position == E_BOOK_CACHE_CURSOR_ORIGIN_END) {
			/* Make sure that we look up the total so we can
			 * set the position to 'total + 1'
			 */
			if (!out_total)
				out_total = &local_total;
		}
	}

	/* Early return if there is nothing to do */
	if (!out_total && !out_position)
		return TRUE;

	e_cache_lock (E_CACHE (book_cache), E_CACHE_LOCK_READ);

	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);
		return FALSE;
	}

	if (out_total)
		success = cursor_count_total_locked (book_cache, cursor, out_total, cancellable, error);

	if (success && out_position)
		success = cursor_count_position_locked (book_cache, cursor, out_position, cancellable, error);

	e_cache_unlock (E_CACHE (book_cache), E_CACHE_UNLOCK_NONE);

	/* In the case we're at the end, we just set the position
	 * to be the total + 1
	 */
	if (success && out_position && out_total &&
	    cursor->state.position == E_BOOK_CACHE_CURSOR_ORIGIN_END)
		*out_position = *out_total + 1;

	return success;
}

/**
 * e_book_cache_cursor_compare_contact:
 * @book_cache: An #EBookCache
 * @cursor: The #EBookCacheCursor
 * @contact: The #EContact to compare
 * @out_matches_sexp: (out) (nullable): Whether the contact matches the cursor's search expression
 *
 * Compares @contact with @cursor and returns whether @contact is less than, equal to, or greater
 * than @cursor.
 *
 * Returns: A value that is less than, equal to, or greater than zero if @contact is found,
 *    respectively, to be less than, to match, or be greater than the current value of @cursor.
 *
 * Since: 3.26
 **/
gint
e_book_cache_cursor_compare_contact (EBookCache *book_cache,
				     EBookCacheCursor *cursor,
				     EContact *contact,
				     gboolean *out_matches_sexp)
{
	gint ii;
	gint comparison = 0;

	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), -1);
	g_return_val_if_fail (cursor != NULL, -1);
	g_return_val_if_fail (E_IS_CONTACT (contact), -1);

	if (out_matches_sexp) {
		if (!cursor->sexp)
			*out_matches_sexp = TRUE;
		else
			*out_matches_sexp = e_book_backend_sexp_match_contact (cursor->sexp, contact);
	}

	for (ii = 0; ii < cursor->n_sort_fields && comparison == 0; ii++) {
		SummaryField *field;
		gchar *contact_key = NULL;
		const gchar *cursor_key = NULL;
		const gchar *field_value;
		gchar *freeme = NULL;

		field_value = e_contact_get_const (contact, cursor->sort_fields[ii]);
		if (field_value)
			contact_key = e_collator_generate_key (book_cache->priv->collator, field_value, NULL);

		field = summary_field_get (book_cache, cursor->sort_fields[ii]);

		if (field && (field->index & INDEX_FLAG (SORT_KEY)) != 0) {
			cursor_key = cursor->state.values[ii];
		} else {

			if (cursor->state.values[ii])
				freeme = ebc_decode_vcard_sort_key (cursor->state.values[ii]);

			cursor_key = freeme;
		}

		/* Empty state sorts below any contact value, which means the contact sorts above cursor */
		if (cursor_key == NULL)
			comparison = 1;
		else
			/* Check if contact sorts below, equal to, or above the cursor */
			comparison = g_strcmp0 (contact_key, cursor_key);

		g_free (contact_key);
		g_free (freeme);
	}

	/* UID tie-breaker */
	if (comparison == 0) {
		const gchar *uid;

		uid = e_contact_get_const (contact, E_CONTACT_UID);

		if (cursor->state.last_uid == NULL)
			comparison = 1;
		else if (uid == NULL)
			comparison = -1;
		else
			comparison = strcmp (uid, cursor->state.last_uid);
	}

	return comparison;
}

static gchar *
ebc_dup_contact_revision (EBookCache *book_cache,
			  EContact *contact)
{
	g_return_val_if_fail (E_IS_CONTACT (contact), NULL);

	return e_contact_get (contact, E_CONTACT_REV);
}

static gboolean
e_book_cache_put_locked (ECache *cache,
			 const gchar *uid,
			 const gchar *revision,
			 const gchar *object,
			 ECacheColumnValues *other_columns,
			 EOfflineState offline_state,
			 gboolean is_replace,
			 GCancellable *cancellable,
			 GError **error)
{
	EBookCache *book_cache;
	EContact *contact;
	gchar *updated_vcard = NULL;
	gboolean e164_changed;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_book_cache_parent_class)->put_locked != NULL, FALSE);

	book_cache = E_BOOK_CACHE (cache);

	contact = e_contact_new_from_vcard_with_uid (object, uid);

	/* Update E.164 parameters in vcard if needed */
	e164_changed = update_e164_attribute_params (book_cache, contact, book_cache->priv->region_code);

	if (e164_changed) {
		updated_vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);
		object = updated_vcard;
	}

	success = E_CACHE_CLASS (e_book_cache_parent_class)->put_locked (cache, uid, revision, object, other_columns, offline_state,
		is_replace, cancellable, error);

	success = success && ebc_update_aux_tables (cache, uid, revision, object, cancellable, error);

	if (success && e164_changed)
		g_signal_emit (book_cache, signals[E164_CHANGED], 0, contact, is_replace);

	g_clear_object (&contact);
	g_free (updated_vcard);

	return success;
}

static gboolean
e_book_cache_remove_locked (ECache *cache,
			    const gchar *uid,
			    GCancellable *cancellable,
			    GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_book_cache_parent_class)->remove_locked != NULL, FALSE);

	success = ebc_delete_from_aux_tables (cache, uid, cancellable, error);

	success = success && E_CACHE_CLASS (e_book_cache_parent_class)->remove_locked (cache, uid, cancellable, error);

	return success;
}

static gboolean
e_book_cache_remove_all_locked (ECache *cache,
				const GSList *uids,
				GCancellable *cancellable,
				GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_book_cache_parent_class)->remove_all_locked != NULL, FALSE);

	success = ebc_empty_aux_tables (cache, cancellable, error);

	success = success && E_CACHE_CLASS (e_book_cache_parent_class)->remove_all_locked (cache, uids, cancellable, error);

	return success;
}

static gboolean
e_book_cache_clear_offline_changes_locked (ECache *cache,
					   GCancellable *cancellable,
					   GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CACHE (cache), FALSE);
	g_return_val_if_fail (E_CACHE_CLASS (e_book_cache_parent_class)->clear_offline_changes_locked != NULL, FALSE);

	/* First check whether there are any locally deleted objects at all */
	if (e_cache_get_count (cache, E_CACHE_INCLUDE_DELETED, cancellable, error) >
	    e_cache_get_count (cache, E_CACHE_EXCLUDE_DELETED, cancellable, error))
		success = ebc_delete_from_aux_tables_offline_deleted (cache, cancellable, error);
	else
		success = TRUE;

	success = success && E_CACHE_CLASS (e_book_cache_parent_class)->clear_offline_changes_locked (cache, cancellable, error);

	return success;
}

static void
e_book_cache_get_property (GObject *object,
			   guint property_id,
			   GValue *value,
			   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_LOCALE:
			g_value_take_string (
				value,
				e_book_cache_dup_locale (E_BOOK_CACHE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_book_cache_finalize (GObject *object)
{
	EBookCache *book_cache = E_BOOK_CACHE (object);

	g_clear_object (&book_cache->priv->source);

	if (book_cache->priv->collator) {
		e_collator_unref (book_cache->priv->collator);
		book_cache->priv->collator = NULL;
	}

	g_free (book_cache->priv->locale);
	g_free (book_cache->priv->region_code);

	if (book_cache->priv->summary_fields) {
		summary_fields_array_free (book_cache->priv->summary_fields, book_cache->priv->n_summary_fields);
		book_cache->priv->summary_fields = NULL;
	}

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_cache_parent_class)->finalize (object);
}

static void
e_book_cache_class_init (EBookCacheClass *klass)
{
	GObjectClass *object_class;
	ECacheClass *cache_class;

	g_type_class_add_private (klass, sizeof (EBookCachePrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->get_property = e_book_cache_get_property;
	object_class->finalize = e_book_cache_finalize;

	cache_class = E_CACHE_CLASS (klass);
	cache_class->put_locked = e_book_cache_put_locked;
	cache_class->remove_locked = e_book_cache_remove_locked;
	cache_class->remove_all_locked = e_book_cache_remove_all_locked;
	cache_class->clear_offline_changes_locked = e_book_cache_clear_offline_changes_locked;

	klass->dup_contact_revision = ebc_dup_contact_revision;

	g_object_class_install_property (
		object_class,
		PROP_LOCALE,
		g_param_spec_string (
			"locale",
			"Locate",
			"The locale currently being used",
			NULL,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	signals[E164_CHANGED] = g_signal_new (
		"e164-changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookCacheClass, e164_changed),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 2,
		E_TYPE_CONTACT,
		G_TYPE_BOOLEAN);

	/**
	 * EBookCache:dup-contact-revision:
	 * A signal being called to get revision of an #EContact.
	 * The default implementation returns E_CONTACT_REV field value.
	 **/
	signals[DUP_CONTACT_REVISION] = g_signal_new (
		"dup-contact-revision",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (EBookCacheClass, dup_contact_revision),
		g_signal_accumulator_first_wins,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_STRING, 1,
		E_TYPE_CONTACT);
}

static void
e_book_cache_init (EBookCache *book_cache)
{
	book_cache->priv = G_TYPE_INSTANCE_GET_PRIVATE (book_cache, E_TYPE_BOOK_CACHE, EBookCachePrivate);
}
